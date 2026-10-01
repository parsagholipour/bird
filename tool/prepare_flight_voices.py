#!/usr/bin/env python3
"""Build and master the in-flight voice-over. Requires FFmpeg; no network.

The lines were first written per speaker in
build/flight-voices/script/<key>.json; docs/flight-voices-sources.json is
the script after that, edited in place when build/ has no script. They are
recorded with ElevenLabs Eleven v4, one take each, into
build/flight-voices/source/<name>.mp3 (both ignored). Recording runs log
each take's generation in build/flight-voices/generations/*.json.

    python3 tool/prepare_flight_voices.py script   # check the lines, write
                                                   # docs/flight-voices-sources.json
    python3 tool/prepare_flight_voices.py pending  # lines with no take yet
    python3 tool/prepare_flight_voices.py          # master takes not yet mastered
    python3 tool/prepare_flight_voices.py --all    # master every take again
    python3 tool/prepare_flight_voices.py --only pip-hit-01 dragon-mad-02

Mastering matches the story's voices (tool/prepare_story_voices.py): the
take is trimmed to its speech, brought to one loudness in one linear gain
and saved as mono Ogg Vorbis in assets/audio/flight/. In-flight lines sit
2 dB hotter than the story's, over the flight's music and effects, and at
24 kHz: short calls under music lose nothing, and the bundle a third. The clip
lengths go to lib/game/flight_voice_clips.dart, which the game reads to
know when a line ends, and how each line looks as it is said (its mood
and how far the speaker's mouth opens every 50 ms) to
lib/game/flight_voice_faces.dart.
"""
import argparse
from array import array
import hashlib
import math
import json
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_story_voices as story  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build' / 'flight-voices'
SCRIPT_DIR = BUILD / 'script'
SOURCE_DIR = BUILD / 'source'
GENERATIONS = BUILD / 'generations'
VERIFY = BUILD / 'verification.json'
SOURCES = ROOT / 'docs' / 'flight-voices-sources.json'
OUT_DIR = ROOT / 'assets' / 'audio' / 'flight'
CLIPS_DART = ROOT / 'lib' / 'game' / 'flight_voice_clips.dart'
FACES_DART = ROOT / 'lib' / 'game' / 'flight_voice_faces.dart'
FACES_CACHE = BUILD / 'faces.json'
STORY_SOURCES = ROOT / 'docs' / 'story-voices-sources.json'
STORY_DIR = ROOT / 'assets' / 'audio' / 'story'
FLIGHT_VOICES = ROOT / 'lib' / 'game' / 'flight_voices.dart'
# A flow holds at most 1000 nodes, so the takes span two.
FLOWS = [
    'https://elevenlabs.io/app/flows/hEMhHloboMc0KYrmkkGy',
    'https://elevenlabs.io/app/flows/V0O0EGPsIhNEZChR9aFV',
]

LOUDNESS = -16.0
# Speech needs no more than 12 kHz of bandwidth: a third off the bundle.
RATE = 24000

VOICES = {
    'pip': ('EaX6rnyDKjJx35tchi80', 'Nelson – Awkward Nerd Character'),
    'peaches': ('XJ2fW4ybq7HouelYYGcL',
                'Cherry Twinkle – Adorable Cartoon Girl'),
    'minty': ('XjGYkUkzth8BPs29fmcV', 'Teddy Twinkle - Cute Cartoon Boy'),
    'orbit': ('f9imtLc2jfOLXtqe3Ihb', 'Lola - Soft, Innocent and Calming'),
    'baron': ('NXaTw4ifg0LAguvKuIwZ', 'Posh Josh'),
    'spitter': ('yjJ45q8TVCrtMhEKurxY', 'Dr. Von Fusion - VF'),
    'empress': ('sssn4wp3AspuK2kvy3Ym',
                'Enchantress - mysterious, witchy, villain character'),
    'captain': ('4Vl3K2x290GidNvuaLm7',
                'Matthew Schmitz - Old Pirate Captain'),
    'dragon': ('xsiB5fGhEtknnqzudCO6', 'Smoke - The Dragon'),
}
BIRDS = ['pip', 'peaches', 'minty', 'orbit']
BOSSES = ['baron', 'spitter', 'empress', 'captain', 'dragon']
REGIONS = ['jungle', 'antarctica', 'aztec', 'paris', 'egypt', 'cyberpunk',
           'china', 'brazil', 'new-york', 'arabia', 'rome', 'mexico', 'sea']
LEVELS = [f'{c}-{n}' for c in range(1, 6) for n in range(1, 9)]
RUSHES = ['wildfire', 'skyfall', 'swarm', 'eruption']

# Lines per moment, as briefed (build/flight-voices/BRIEF.md). Urgent
# moments are held to 6 words, cargo to 14, the rest to 12.
BIRD_MOMENTS = {
    'takeoff': 6, 'retry': 5, 'hit': 6, 'hit-fire': 3, 'hit-water': 3,
    'shield-pop': 4, 'last-heart': 5, 'shield-back': 3, 'streak': 5,
    'magnet': 3, 'heart-pickup': 3, 'knockout': 5, 'record': 4, 'idle': 8,
    'reps-pushup': 4, 'reps-squat': 4, 'reps-jump': 4, 'spot-bat': 2,
    'spot-beetle': 2, 'spot-moth': 2, 'enemy-down': 6, 'incoming': 4,
    'deflect': 3, 'no-ammo': 3, 'panel-break': 3,
    **{f'rush-{r}': 3 for r in RUSHES},
    **{f'rush-first-{r}': 1 for r in RUSHES},
    'rush-escaped': 5, 'gale': 4, 'gale-over': 3, 'sprint': 4,
    **{f'boss-{b}': 2 for b in BOSSES},
    'boss-again': 3, 'dragon-fire': 3, 'tide-bell': 3, 'cannon': 2,
    'screech': 3, 'moth-shield': 2, 'boss-mad': 3, 'boss-down': 3,
    **{f'boss-down-{b}': 1 for b in BOSSES},
    'retort': 5,
    **{f'region-{r}': 3 for r in REGIONS},
    **{f'cargo-{level}': 1 for level in LEVELS},
    'final-stretch': 4, 'stars-two': 2, 'stars-three': 2, 'delivered': 6,
}
BOSS_MOMENTS = {
    'arrive': 3, 'taunt': 8, 'attack': 4, 'summon': 3, 'hurt': 5,
    'gloat': 5, 'mad': 3, 'defeated': 3,
}
URGENT = {'hit', 'hit-fire', 'hit-water', 'shield-pop', 'incoming', 'gale',
          'dragon-fire', 'tide-bell', 'cannon', 'screech', 'attack', 'tide',
          *[f'rush-{r}' for r in RUSHES]}
TAG = re.compile(r'\[[^\]]*\]')


# The face each direction tag puts on its speaker (StoryMood's names). A
# line takes the mood of its first tag that is not plain.
MOODS = {
    'happy': '''airily amused bravely cheekily cheerfully chuckles cocky
        confidently contentedly delighted eagerly enthusiastically excited
        giddy giggles gleefully happily happy impressed laughs mischievously
        mockingly playfully pleased proudly relieved smugly sweetly teasing
        tenderly triumphant warmly''',
    'surprised': '''alarmed amazed awed breathless cautiously flustered
        frantically gasps nervous panicked shivering shouting spluttering
        sputtering squeaky stammering startled surprised urgently worried
        yelps''',
    'angry': '''angry annoyed coldly determined disgusted dismissively firmly
        furious growls gruffly grumbling grumpy haughtily impatiently
        imperiously indignant menacing outraged seriously''',
    'sad': '''dazed disappointed groans pained sadly sheepishly sighs sleepily
        sleepy tired wearily yawns''',
}
MOOD_OF = {tag: mood for mood, tags in MOODS.items() for tag in tags.split()}
MOOD_OF.update({'laughs nervously': 'surprised',
                'trembling voice': 'surprised'})

# Mouth frames: 50 ms each, 0 shut to 3 wide.
FRAME = .05
MOUTHS = 3


def mood(prompt):
    for tag in TAG.findall(prompt):
        found = MOOD_OF.get(tag.lower().strip('[]'))
        if found:
            return found
    return 'plain'


def mouth_curve(path):
    """How far the mouth opens in each frame of [path], from its loudness
    against the line's own loud frames."""
    rate = 8000
    pcm = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(path), '-f', 's16le', '-ac', '1',
         '-ar', str(rate), '-'],
        capture_output=True, check=True).stdout
    samples = array('h')
    samples.frombytes(pcm[:len(pcm) // 2 * 2])
    step = round(rate * FRAME)
    levels = []
    for start in range(0, len(samples), step):
        frame = samples[start:start + step]
        power = sum(v * v for v in frame) / max(1, len(frame))
        levels.append(10 * math.log10(power + 1))
    loud = sorted(levels)[int(len(levels) * .9)] if levels else 0
    # Wide on the loudest syllables, shut in the gaps between words.
    steps = (loud - 3, loud - 8, loud - 16)
    return ''.join(
        str(next((MOUTHS - i for i, edge in enumerate(steps) if db >= edge), 0))
        for db in levels)


def story_extras():
    """The story clips the flight also plays, as lib/game/flight_voices.dart
    names them: the sprint calls, the chapter bosses' name-card lines and
    any card it names outright (New York's guardians). A clip still pending
    its recording is left out until it has one."""
    named = set(re.findall(r"_story\('([\w-]+)'\)", FLIGHT_VOICES.read_text()))
    extras = {}
    for clip in json.loads(STORY_SOURCES.read_text())['clips']:
        name = clip['name']
        path = STORY_DIR / f'{name}.ogg'
        if not path.exists():
            continue
        if (name.startswith('sprint-') or name in named
                or re.fullmatch(r'before-\d-8-4', name)):
            extras[name] = (clip['prompt'], path)
    return extras


def write_faces(clips):
    """Writes every played line's mood and mouth frames, re-measuring only
    takes whose mastered file changed."""
    cache = json.loads(FACES_CACHE.read_text()) if FACES_CACHE.exists() else {}
    lines = {c['name']: (c['prompt'], OUT_DIR / f"{c['name']}.ogg")
             for c in clips if (OUT_DIR / f"{c['name']}.ogg").exists()}
    lines.update(story_extras())
    faces = {}
    for name, (prompt, path) in sorted(lines.items()):
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        hit = cache.get(name)
        curve = hit['mouth'] if hit and hit['sha256'] == digest \
            else mouth_curve(path)
        cache[name] = {'sha256': digest, 'mouth': curve}
        faces[name] = (mood(prompt), curve)
    FACES_CACHE.write_text(json.dumps(
        {k: v for k, v in sorted(cache.items()) if k in faces}))
    out = [
        '// Generated by tool/prepare_flight_voices.py. Do not edit.',
        '',
        '/// The mood each in-flight line is said in (a StoryMood name), from',
        '/// its first direction tag.',
        'const flightVoiceMoods = <String, String>{',
        *[f"  '{name}': '{m}'," for name, (m, _) in faces.items()
          if m != 'plain'],
        '};',
        '',
        '/// How far the speaker\'s mouth opens every 50 ms of each line, '
        f'0 shut to {MOUTHS}',
        '/// wide, from the take\'s loudness.',
        'const flightVoiceMouths = <String, String>{',
        *[f"  '{name}': '{curve}'," for name, (_, curve) in faces.items()],
        '};',
        '',
    ]
    FACES_DART.write_text('\n'.join(out))
    print(f'{len(faces)} faces -> {FACES_DART.name}')


def moments(speaker):
    if speaker in BIRDS:
        return BIRD_MOMENTS
    extra = {'tide': 3} if speaker == 'captain' else {}
    return {**BOSS_MOMENTS, **extra}


def limit(moment):
    if moment in URGENT:
        return 6
    return 14 if moment.startswith('cargo-') else 12


def spoken(prompt):
    return ' '.join(TAG.sub(' ', prompt).split())


def check(lines):
    """Every problem with the written lines, as messages."""
    problems = []
    seen = {}
    by_pool = {}
    for line in lines:
        name, speaker, moment = line['name'], line['speaker'], line['moment']
        text, prompt = line['text'], line['prompt']
        if speaker not in VOICES:
            problems.append(f'{name}: unknown speaker {speaker}')
            continue
        if moment not in moments(speaker):
            problems.append(f'{name}: unknown moment {moment}')
        if not re.fullmatch(rf'{speaker}-{re.escape(moment)}-\d\d', name):
            problems.append(f'{name}: name does not match its moment')
        if spoken(prompt) != ' '.join(text.split()):
            problems.append(f'{name}: prompt says "{spoken(prompt)}"')
        if len(text.split()) > limit(moment):
            problems.append(f'{name}: {len(text.split())} words')
        if re.search('[\u2018\u2019\u201c\u201d\U0001F300-\U0001FAFF]', text):
            problems.append(f'{name}: curly quotes or emoji')
        key = text.lower().strip(' .!?')
        if key in seen:
            problems.append(f'{name}: same line as {seen[key]}')
        seen[key] = name
        by_pool.setdefault((speaker, moment), []).append(line)
    for speaker in {line['speaker'] for line in lines}:
        for moment, count in moments(speaker).items():
            pool = by_pool.get((speaker, moment), [])
            if len(pool) != count:
                problems.append(
                    f'{speaker}-{moment}: {len(pool)} lines, not {count}')
            firsts = [line['text'].split()[0].lower().strip(',.!?')
                      for line in pool]
            if len(set(firsts)) != len(firsts):
                problems.append(f'{speaker}-{moment}: repeated first word')
    return problems


def generations():
    taken = {}
    for path in sorted(GENERATIONS.glob('*.json')):
        try:
            taken.update(json.loads(path.read_text()))
        except json.JSONDecodeError:
            print(f'{path.name}: unreadable, skipped', file=sys.stderr)
    return taken


def build_sources():
    old = {}
    if SOURCES.exists():
        old = {c['name']: c for c in json.loads(SOURCES.read_text())['clips']}
    # The writers' files seed the script; after that the sources file is
    # the script, edited in place.
    lines = []
    for path in sorted(SCRIPT_DIR.glob('*.json')):
        data = json.loads(path.read_text())
        for line in data['lines']:
            lines.append({**line, 'speaker': data['speaker']})
    if not lines:
        lines = list(old.values())
    problems = check(lines)
    if problems:
        raise SystemExit('\n'.join(problems))
    taken = generations()
    clips = []
    for line in lines:
        name = line['name']
        voice_id, voice = VOICES[line['speaker']]
        clip = {
            'name': name,
            'speaker': line['speaker'],
            'moment': line['moment'],
            'text': line['text'],
            'prompt': line['prompt'],
            'voice_id': voice_id,
            'voice': voice,
        }
        take = taken.get(name)
        was = old.get(name)
        source = SOURCE_DIR / f'{name}.mp3'
        if take and take.get('prompt', line['prompt']) == line['prompt']:
            clip['generation_id'] = take['generation_id']
        elif was and was['prompt'] == line['prompt'] and 'generation_id' in was:
            clip['generation_id'] = was['generation_id']
        if 'generation_id' in clip and source.exists():
            clip['source_sha256'] = hashlib.sha256(
                source.read_bytes()).hexdigest()
        clips.append(clip)
    SOURCES.write_text(json.dumps({
        'model': 'eleven_v4',
        'generations': 1,
        'flows': FLOWS,
        'date': '2026-10-01',
        'clips': clips,
    }, indent=1, ensure_ascii=False) + '\n')
    recorded = sum('generation_id' in c for c in clips)
    print(f'{len(clips)} lines, {recorded} recorded -> {SOURCES}')


def write_clips(lengths):
    lines = [
        '// Generated by tool/prepare_flight_voices.py. Do not edit.',
        '',
        '/// Every recorded in-flight line in assets/audio/flight/, by name, '
        'with',
        '/// how long it plays in milliseconds.',
        'const flightVoiceClips = <String, int>{',
    ]
    lines += [f"  '{name}': {ms}," for name, ms in sorted(lengths.items())]
    lines += ['};', '']
    CLIPS_DART.write_text('\n'.join(lines))


def master_all(only, every):
    story.LOUDNESS = LOUDNESS
    clips = json.loads(SOURCES.read_text())['clips']
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    old = {}
    if CLIPS_DART.exists():
        old = {m[0]: int(m[1]) for m in re.findall(
            r"'([\w-]+)': (\d+),", CLIPS_DART.read_text())}
    report = json.loads(VERIFY.read_text()) if VERIFY.exists() else {}
    lengths, missing = {}, []
    for clip in clips:
        name = clip['name']
        target = OUT_DIR / f'{name}.ogg'
        redo = every or name in only or not (only or target.exists())
        if not redo and name in old and target.exists():
            lengths[name] = old[name]
            continue
        source = SOURCE_DIR / f'{name}.mp3'
        if not source.exists() or 'generation_id' not in clip:
            missing.append(name)
            continue
        seconds = story.master(source, target, rate=RATE)
        lengths[name] = round(seconds * 1000)
        report[name] = {
            'seconds': round(seconds, 3),
            'bytes': target.stat().st_size,
            'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        }
    names = {c['name'] for c in clips}
    for stale in OUT_DIR.glob('*.ogg'):
        if stale.stem not in names:
            stale.unlink()
    write_clips(lengths)
    write_faces([c for c in clips if c['name'] in lengths])
    VERIFY.parent.mkdir(parents=True, exist_ok=True)
    VERIFY.write_text(json.dumps(
        {k: v for k, v in sorted(report.items()) if k in lengths}, indent=1))
    total = sum(p.stat().st_size for p in OUT_DIR.glob('*.ogg'))
    print(f'{len(lengths)} clips, {sum(lengths.values()) / 1000:.1f} s, '
          f'{total / 1e6:.2f} MB')
    if missing:
        print(f'{len(missing)} lines have no take yet', file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('step', nargs='?', default='master',
                        choices=['script', 'pending', 'master'])
    parser.add_argument('--only', nargs='*', help='clip names to redo')
    parser.add_argument('--all', action='store_true',
                        help='master every take again')
    args = parser.parse_args()
    if args.step == 'script':
        build_sources()
    elif args.step == 'pending':
        taken = generations()
        for clip in json.loads(SOURCES.read_text())['clips']:
            if clip['name'] not in taken and 'generation_id' not in clip:
                print(clip['name'])
    else:
        master_all(set(args.only or []), args.all)


if __name__ == '__main__':
    main()
