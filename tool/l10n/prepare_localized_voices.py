#!/usr/bin/env python3
"""Master a language's voice pack, and wire the packs into the build.

A language's takes are recorded with ElevenLabs Eleven v4 (one take each, the
English line's voice, l10n-ws/voice/RECORDING-L10N.md) into

    <voice>/<slug>/takes/story/<clip>.mp3      story clips (English clip names)
    <voice>/<slug>/takes/flight/<line>.mp3     in-flight lines
    <voice>/<slug>/generations/<batch>.json    {name: {generation_id, prompt, ...}}
    <voice>/<slug>/story.json, flight.json     {name: {text, prompt}} (the script)

where <voice> is l10n-ws/voice (--voice-dir, or $L10N_VOICE_DIR). This tool
masters them with the English chain (tool/prepare_story_voices.py: trimmed
to the speech, one linear loudness gain, mono Ogg Vorbis quality 2; story
at -18 LUFS, flight at -16 LUFS, both 24 kHz by default), measures each
take's mouth frames and mood with the English faces' algorithm
(tool/prepare_flight_voices.py), and writes the pack:

    assets/voice/<slug>/story/<clip>.ogg
    assets/voice/<slug>/flight/<line>.ogg
    assets/voice/<slug>/manifest.json   every clip: length, mouth, mood
    assets/voice/index.json             (base bundle) every pack's counts and size

It reports every clip's length against the English take's and flags a
ratio under 0.6 or over 1.8, a near-silent take, a clipped take, a take
whose prompt is no longer the script's, and a download that is shorter than
its generation. Any subset of takes makes a valid pack; the game falls back
to English clip by clip for the story (lib/game/voice_packs.dart).

    python3 tool/l10n/prepare_localized_voices.py --lang es_419           # master new takes
    python3 tool/l10n/prepare_localized_voices.py --lang es_419 --all     # master every take again
    python3 tool/l10n/prepare_localized_voices.py --lang es_419 --only pip-hit-01 before-1-1-1
    python3 tool/l10n/prepare_localized_voices.py --lang es_419 --status  # no FFmpeg
    python3 tool/l10n/prepare_localized_voices.py --wire                  # pubspec + Android modules

--wire (also run after every mastering into assets/voice) keeps the build in
step with the packs: one Flutter deferred component `voice_<slug>` per
language in pubspec.yaml (only the pack folders that exist), the Android
dynamic feature modules android/voice_<slug>/, their settings.gradle.kts
includes and their titles in res/values/strings.xml, and an empty manifest
for a language with nothing recorded yet.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

TOOL = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL.parent))
import prepare_story_voices as story  # noqa: E402
import prepare_flight_voices as flight  # noqa: E402

ROOT = TOOL.parents[1]
PACKS = ROOT / 'assets' / 'voice'
PUBSPEC = ROOT / 'pubspec.yaml'
ANDROID = ROOT / 'android'
SETTINGS = ANDROID / 'settings.gradle.kts'
STRINGS = ANDROID / 'app' / 'src' / 'main' / 'res' / 'values' / 'strings.xml'
STORY_SOURCES = ROOT / 'docs' / 'story-voices-sources.json'
FLIGHT_SOURCES = ROOT / 'docs' / 'flight-voices-sources.json'
STORY_TABLE = ROOT / 'lib' / 'game' / 'campaign_voice_clips.dart'
FLIGHT_TABLE = ROOT / 'lib' / 'game' / 'flight_voice_clips.dart'
PACKAGE = 'com.ravanix.push_up_bird'

# slug: (BCP-47 tag, ElevenLabs language_code, voice rank). The same languages
# as AppLanguage (lib/l10n/app_language.dart); test/voice_pack_wiring_test.dart
# holds them together.
LANGUAGES = {
    'es_419': ('es-419', 'es', 1),
    'pt_br': ('pt-BR', 'pt', 1),
    'id': ('id', 'id', 1),
    'fr': ('fr', 'fr', 1),
    'de': ('de', 'de', 1),
    'ja': ('ja', 'ja', 2),
    'ko': ('ko', 'ko', 2),
    'tr': ('tr', 'tr', 2),
    'zh_hant': ('zh-Hant', 'zh', 2),
    'ru': ('ru', 'ru', 2),
    'ar': ('ar', 'ar', 3),
}
KINDS = ('story', 'flight')
LOUDNESS = {'story': story.LOUDNESS, 'flight': flight.LOUDNESS}
FORMAT = 1

# What the report flags.
SHORT, LONG = .6, 1.8
SILENT_RMS_DB, SILENT_SECONDS = -45.0, .3
CLIP_PEAK_DB, CLIP_PEAK_COUNT = -.1, 3
FLIGHT_LONG_SECONDS = 6.0


def voice_dir(given):
    if given:
        return Path(given).resolve()
    if os.environ.get('L10N_VOICE_DIR'):
        return Path(os.environ['L10N_VOICE_DIR']).resolve()
    # The main tree sits beside l10n-ws; an l10n-ws workspace sits inside it.
    for candidate in (ROOT.parent / 'l10n-ws' / 'voice', ROOT.parent / 'voice'):
        if candidate.is_dir():
            return candidate
    return ROOT.parent / 'l10n-ws' / 'voice'


def read_json(path, default):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as error:
        print(f'{path}: unreadable ({error}), ignored', file=sys.stderr)
        return default


def table(path):
    return {m[0]: int(m[1]) for m in re.findall(
        r"'([\w-]+)': (\d+),", path.read_text())}


def english():
    """The English clips a language may record, with their mastered lengths
    and prompts: recorded story clips (a pending English clip stays pending
    everywhere) and every in-flight line."""
    story_ms, flight_ms = table(STORY_TABLE), table(FLIGHT_TABLE)
    prompts = {'story': {}, 'flight': {}}
    for clip in json.loads(STORY_SOURCES.read_text())['clips']:
        if clip.get('status') != story.PENDING and clip['name'] in story_ms:
            prompts['story'][clip['name']] = clip['prompt']
    for clip in json.loads(FLIGHT_SOURCES.read_text())['clips']:
        if clip['name'] in flight_ms:
            prompts['flight'][clip['name']] = clip['prompt']
    return {'story': story_ms, 'flight': flight_ms}, prompts


def generations(lang_dir):
    taken = {}
    for path in sorted((lang_dir / 'generations').glob('*.json')):
        taken.update(read_json(path, {}))
    return taken


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def levels(path):
    """The raw take's peak and RMS level (dBFS) and how often it hit its
    peak, from FFmpeg's astats."""
    out = subprocess.run(
        ['ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-af',
         'astats=measure_perchannel=none', '-f', 'null', '-'],
        capture_output=True, text=True, check=True).stderr

    def value(label):
        found = re.findall(rf'{label}:\s*(-?[\d.]+|-inf)', out)
        if not found:
            return None
        return float('-inf') if found[-1] == '-inf' else float(found[-1])
    return {'peak_db': value('Peak level dB'), 'rms_db': value('RMS level dB'),
            'peak_count': value('Peak count')}


def flags_of(kind, seconds, english_ms, measured, take, prompt):
    flags = []
    ratio = seconds * 1000 / english_ms if english_ms else None
    if ratio is not None and ratio < SHORT:
        flags.append(f'short ({ratio:.2f} of English)')
    if ratio is not None and ratio > LONG:
        flags.append(f'long ({ratio:.2f} of English)')
    rms = measured.get('rms_db')
    if seconds < SILENT_SECONDS or (rms is not None and rms < SILENT_RMS_DB):
        flags.append('near-silent')
    peak, count = measured.get('peak_db'), measured.get('peak_count') or 0
    if peak is not None and peak >= CLIP_PEAK_DB and count >= CLIP_PEAK_COUNT:
        flags.append(f'clipped ({peak:.2f} dBFS x{count:.0f})')
    if kind == 'flight' and seconds > FLIGHT_LONG_SECONDS:
        flags.append(f'over {FLIGHT_LONG_SECONDS:.0f} s')
    if take:
        if prompt is not None and take.get('prompt') not in (None, prompt):
            flags.append('stale: the script prompt changed after recording')
        expected = take.get('duration_secs')
        if expected and measured.get('source_seconds') is not None and \
                abs(measured['source_seconds'] - expected) > .3:
            flags.append('download shorter or longer than its generation')
    return ratio, flags


def face(prompt, english_prompt, path):
    mood = flight.mood(prompt) if prompt else 'plain'
    if mood == 'plain' and english_prompt:
        # The translators keep the English tags; if one was lost, the
        # English line's mood still fits the scene.
        mood = flight.mood(english_prompt)
    return mood, flight.mouth_curve(path)


def master_language(slug, voice, out_root, only, every, story_rate):
    if slug not in LANGUAGES:
        raise SystemExit(f'Unknown language {slug}: one of {", ".join(LANGUAGES)}')
    lang_dir = voice / slug
    takes_dir = lang_dir / 'takes'
    pack_dir = out_root / slug
    lengths, english_prompts = english()
    scripts = {kind: read_json(lang_dir / f'{kind}.json', {}) for kind in KINDS}
    taken = generations(lang_dir)
    verify_path = lang_dir / 'verification.json'
    verify = read_json(verify_path, {})
    rates = {'story': story_rate, 'flight': flight.RATE}
    manifest = {'story': {}, 'flight': {}}
    report, skipped = {}, []
    for kind in KINDS:
        out_dir = pack_dir / kind
        sources = sorted((takes_dir / kind).glob('*.mp3'))
        for source in sources:
            name = source.stem
            key = f'{kind}/{name}'
            if name not in lengths[kind]:
                why = ('its English clip is pending recording or unknown'
                       if kind == 'story' else 'not a line of the English script')
                skipped.append(f'{key}: {why}')
                continue
            target = out_dir / f'{name}.ogg'
            digest = sha256(source)
            was = verify.get(key)
            if only:
                redo = name in only
            else:
                redo = (every or not target.exists() or not was
                        or was.get('source_sha256') != digest)
            if not redo and (not was or not target.exists()):
                continue  # not mastered yet: a run without --only does it
            script = scripts[kind].get(name, {})
            prompt = script.get('prompt') or taken.get(name, {}).get('prompt')
            if redo:
                out_dir.mkdir(parents=True, exist_ok=True)
                story.LOUDNESS = LOUDNESS[kind]
                measured = levels(source)
                measured['source_seconds'] = story.probe(source)
                seconds = story.master(source, target, rate=rates[kind])
                mood, mouth = face(prompt, english_prompts[kind].get(name), target)
                ratio, flags = flags_of(kind, seconds, lengths[kind][name],
                                        measured, taken.get(name), script.get('prompt'))
                if not prompt:
                    flags.append('no prompt in the script or a generation manifest')
                was = {
                    'source_sha256': digest,
                    'sha256': sha256(target),
                    'bytes': target.stat().st_size,
                    'ms': round(seconds * 1000),
                    'english_ms': lengths[kind][name],
                    'ratio': None if ratio is None else round(ratio, 3),
                    'mood': mood,
                    'mouth': mouth,
                    'levels': measured,
                    'generation_id': taken.get(name, {}).get('generation_id'),
                    'flags': flags,
                }
                verify[key] = was
            entry = {'ms': was['ms'], 'mouth': was['mouth']}
            if was['mood'] != 'plain':
                entry['mood'] = was['mood']
            manifest[kind][name] = entry
            report[key] = was
        # A mastered clip whose take is gone leaves the pack.
        if out_dir.exists():
            for stale in out_dir.glob('*.ogg'):
                if stale.stem not in manifest[kind]:
                    stale.unlink()
    verify = {k: v for k, v in sorted(verify.items()) if k in report}
    lang_dir.mkdir(parents=True, exist_ok=True)
    verify_path.write_text(json.dumps(verify, indent=1, ensure_ascii=False) + '\n')
    write_manifest(pack_dir, slug, manifest)
    summarize(slug, pack_dir, manifest, report, skipped, lengths, lang_dir)


def write_manifest(pack_dir, slug, manifest):
    pack_dir.mkdir(parents=True, exist_ok=True)
    data = {
        'format': FORMAT,
        'slug': slug,
        'language': LANGUAGES[slug][0],
        'generated_by': 'tool/l10n/prepare_localized_voices.py',
        'story': dict(sorted(manifest['story'].items())),
        'flight': dict(sorted(manifest['flight'].items())),
    }
    (pack_dir / 'manifest.json').write_text(
        json.dumps(data, indent=1, ensure_ascii=False) + '\n')


def summarize(slug, pack_dir, manifest, report, skipped, lengths, lang_dir):
    size = sum(p.stat().st_size for p in pack_dir.rglob('*') if p.is_file())
    seconds = sum(v['ms'] for v in report.values()) / 1000
    flagged = {k: v['flags'] for k, v in report.items() if v['flags']}
    ratios = [v['ratio'] for v in report.values() if v.get('ratio')]
    print(f"{slug}: {len(manifest['story'])}/{len(lengths['story'])} story clips, "
          f"{len(manifest['flight'])}/{len(lengths['flight'])} flight lines, "
          f'{seconds:.1f} s, {size / 1e6:.2f} MB -> {pack_dir}')
    if ratios:
        ratios.sort()
        print(f'  length against English: median {ratios[len(ratios) // 2]:.2f}, '
              f'{ratios[0]:.2f} to {ratios[-1]:.2f}')
    for key, flags in sorted(flagged.items()):
        print(f"  ! {key}: {'; '.join(flags)}")
    for line in skipped:
        print(f'  - skipped {line}', file=sys.stderr)
    (lang_dir / 'report.json').write_text(json.dumps({
        'slug': slug,
        'story': len(manifest['story']),
        'flight': len(manifest['flight']),
        'seconds': round(seconds, 1),
        'bytes': size,
        'flagged': dict(sorted(flagged.items())),
        'skipped': skipped,
    }, indent=1, ensure_ascii=False) + '\n')


def status(slug, voice, out_root):
    lang_dir = voice / slug
    lengths, _ = english()
    scripts = {kind: read_json(lang_dir / f'{kind}.json', {}) for kind in KINDS}
    taken = generations(lang_dir)
    manifest = read_json(out_root / slug / 'manifest.json', {})
    print(f'{slug} ({LANGUAGES[slug][0]}), takes in {lang_dir / "takes"}:')
    for kind in KINDS:
        takes = {p.stem for p in (lang_dir / 'takes' / kind).glob('*.mp3')}
        mastered = set(manifest.get(kind, {}))
        print(f'  {kind}: {len(scripts[kind])} scripted, {len(takes)} takes, '
              f'{len(mastered)} in the pack, of {len(lengths[kind])} English')
        unplayable = sorted(t for t in takes if t not in lengths[kind])
        if unplayable:
            print(f'    never played (English pending, or not a line): '
                  f'{", ".join(unplayable)}')
        waiting = sorted(takes - mastered - set(unplayable))
        if waiting:
            print(f'    to master: {len(waiting)} ({", ".join(waiting[:8])}'
                  f'{"..." if len(waiting) > 8 else ""})')
        unlogged = sorted(t for t in takes if t not in taken)
        if unlogged:
            print(f'    takes missing from generations/*.json: {len(unlogged)}')
    report = read_json(lang_dir / 'report.json', {})
    if report.get('flagged'):
        print(f"  flagged at the last mastering: {len(report['flagged'])}")


# Wiring the packs into the build.

BEGIN, END = 'voice-packs:begin', 'voice-packs:end'


def replace_block(text, begin_line, end_line, body, path):
    a, b = text.find(begin_line), text.find(end_line)
    if a < 0 or b < a:
        raise SystemExit(f'{path}: the {BEGIN} ... {END} markers are missing')
    a = text.index('\n', a) + 1
    return text[:a] + body + text[b:]


def pack_assets(slug, packs=PACKS):
    folder = packs / slug
    entries = [f'assets/voice/{slug}/']
    for kind in KINDS:
        if any((folder / kind).glob('*.ogg')):
            entries.append(f'assets/voice/{slug}/{kind}/')
    return entries


def pubspec_components(slugs, packs=PACKS):
    """pubspec.yaml's generated block: one deferred component per pack.
    tool/l10n/dev_voice_packs.py writes a subset of it for dev builds."""
    if not slugs:
        return ''
    body = ['  deferred-components:\n']
    for slug in slugs:
        body.append(f'    - name: voice_{slug}\n      assets:\n')
        body += [f'        - {entry}\n' for entry in pack_assets(slug, packs)]
    return ''.join(body)


def settings_includes(slugs):
    """settings.gradle.kts's generated block: one feature module per pack."""
    return ''.join(f'include(":voice_{slug}")\n' for slug in slugs)


def wire():
    changed = []
    for slug in LANGUAGES:
        manifest = PACKS / slug / 'manifest.json'
        if not manifest.exists():
            write_manifest(PACKS / slug, slug, {'story': {}, 'flight': {}})
            changed.append(str(manifest.relative_to(ROOT)))
    write_if_changed(PACKS / 'index.json', index(), changed)
    # Every pack: also undoes a dev subset (tool/l10n/dev_voice_packs.py).
    write_if_changed(PUBSPEC, replace_block(
        PUBSPEC.read_text(), f'# {BEGIN}', f'  # {END}',
        pubspec_components(list(LANGUAGES)), PUBSPEC), changed)
    write_if_changed(SETTINGS, replace_block(
        SETTINGS.read_text(), f'// {BEGIN}', f'// {END}',
        settings_includes(list(LANGUAGES)), SETTINGS), changed)
    names = ''.join(f'    <string name="voice_{slug}Name">voice_{slug}</string>\n'
                    for slug in LANGUAGES)
    write_if_changed(STRINGS, replace_block(
        STRINGS.read_text(), f'<!-- {BEGIN}', f'    <!-- {END}', names, STRINGS),
        changed)
    for slug in LANGUAGES:
        module = ANDROID / f'voice_{slug}'
        write_if_changed(module / 'build.gradle.kts', module_gradle(slug), changed)
        write_if_changed(module / 'src' / 'main' / 'AndroidManifest.xml',
                         module_manifest(slug), changed)
    print(f'wired {len(LANGUAGES)} voice packs'
          + (f'; changed {", ".join(changed)}' if changed else ', nothing changed'))


def index():
    """The packs' index, in the base bundle: each pack's clip counts and
    size, so the game never downloads an empty pack and can show a size."""
    packs = {}
    for slug in LANGUAGES:
        folder = PACKS / slug
        manifest = read_json(folder / 'manifest.json', {})
        packs[slug] = {
            'story': len(manifest.get('story', {})),
            'flight': len(manifest.get('flight', {})),
            'bytes': sum(p.stat().st_size for p in folder.rglob('*') if p.is_file()),
        }
    return json.dumps({'format': FORMAT, 'generated_by':
                       'tool/l10n/prepare_localized_voices.py', 'packs': packs},
                      indent=1) + '\n'


def write_if_changed(path, text, changed):
    if path.exists() and path.read_text() == text:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    changed.append(str(path.relative_to(ROOT)))


def module_gradle(slug):
    tag = LANGUAGES[slug][0]
    return f'''// Generated by tool/l10n/prepare_localized_voices.py --wire. Do not edit.
// The {tag} voice pack: an asset-only Flutter deferred component
// (pubspec.yaml, deferred-components) that Google Play delivers on demand.
plugins {{
    id("com.android.dynamic-feature")
}}

android {{
    namespace = "{PACKAGE}.voice_{slug}"
    compileSdk = 36

    defaultConfig {{
        minSdk = 24
    }}

    compileOptions {{
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }}

    buildTypes {{
        create("profile") {{
            initWith(getByName("debug"))
        }}
    }}

    // `flutter build appbundle` copies the pack's assets here; every other
    // build keeps them in the base module.
    sourceSets {{
        for (mode in listOf("debug", "profile", "release")) {{
            // A File: AGP refuses a Provider in the source set API.
            getByName(mode).assets.srcDir(
                layout.buildDirectory.dir("intermediates/flutter/$mode/deferred_assets")
                    .get().asFile
            )
        }}
    }}
}}

dependencies {{
    implementation(project(":app"))
}}

// The assets are written by :app's Flutter build task; Gradle 9 refuses to
// read another task's output without the dependency said.
tasks.configureEach {{
    val mode = Regex("merge(Debug|Profile|Release)Assets").matchEntire(name)?.groupValues?.get(1)
    if (mode != null) dependsOn(":app:compileFlutterBuild$mode")
}}
'''


def module_manifest(slug):
    return f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by tool/l10n/prepare_localized_voices.py (wire). Do not edit. -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:dist="http://schemas.android.com/apk/distribution">

    <dist:module
        dist:instant="false"
        dist:title="@string/voice_{slug}Name">
        <dist:delivery>
            <dist:on-demand />
        </dist:delivery>
        <dist:fusing dist:include="true" />
    </dist:module>

    <!-- Assets only: bundletool refuses a module without dex that claims code. -->
    <application android:hasCode="false" />
</manifest>
'''


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--lang', help=f'the language slug ({", ".join(LANGUAGES)})')
    parser.add_argument('--only', nargs='*', default=[], help='clip names to master again')
    parser.add_argument('--all', action='store_true', help='master every take again')
    parser.add_argument('--status', action='store_true',
                        help='takes, scripts and pack contents; no FFmpeg')
    parser.add_argument('--wire', action='store_true',
                        help='rewrite pubspec.yaml and the Android modules for every pack')
    parser.add_argument('--voice-dir', help='the folder holding <slug>/takes (default l10n-ws/voice)')
    parser.add_argument('--out', help='where the packs go (default assets/voice; tests use a fixture)')
    parser.add_argument('--story-rate', type=int, default=24000,
                        help='story sample rate (default 24000; the English story is 44100)')
    args = parser.parse_args()
    out_root = Path(args.out).resolve() if args.out else PACKS
    if args.wire and not args.lang:
        wire()
        return
    if not args.lang:
        parser.error('--lang is required (or --wire)')
    voice = voice_dir(args.voice_dir)
    if args.status:
        status(args.lang, voice, out_root)
        return
    master_language(args.lang, voice, out_root, set(args.only), args.all, args.story_rate)
    if out_root == PACKS:
        wire()


if __name__ == '__main__':
    main()
