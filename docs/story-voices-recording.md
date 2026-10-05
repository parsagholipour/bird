# Recording the guardians: from zero to recorded

Six scenes have 78 story clips: New York's four
(`before-3-2`, `last-3-2`: King Coo; `before-3-4`, `last-3-4`: the Searchlight
Gargoyle) and Egypt's two (`before-2-6`, `last-2-6`: Neferhoo, the Mummy Courier,
rules 50), with the pyramid caretaker's thank-you on 2-6 (`thanks-2-6`).
As of 2026-10-05, 64 are recorded; King Coo's 8 and the Gargoyle's 6 await
casting. Neferhoo and the birds also have 32 recorded in-flight lines (section 7).
This is the working
document for recording them: a walkthrough a stranger can follow, the settings, the
auditions (Neferhoo's five takes are already made: section 2), the audio-tag risks,
the clip list and what to do after each batch. The reasons, the cast and the recipe
for any other voice are in [story-voices.md](story-voices.md).

Every one of these clips can be missing: a pending line is written out at the pace
of voices off and a pending in-flight line is simply not said, so the game looks and
paces right before a single take is in.

Only section 4 is generated. `python3 tool/prepare_story_voices.py --checklist`
rewrites the text between the two `checklist` comments from
`docs/story-voices-sources.json` and touches nothing else (`--checklist -` prints
it instead). Run it after every batch and after any change to a line, a prompt or a
voice; `campaign_voices_test` fails if the section is out of date.

## Start here: from zero to one recorded clip

You do not need to understand the game. This takes one line of Bill's, which has
a ready voice and no risky tag, from nothing to playing in the game. Every other
clip is the same steps.

1. **What you need.** The repository (the folder with `pubspec.yaml`), Flutter
   (`flutter --version`), Python 3 (`python3 --version`), FFmpeg with `ffprobe`
   (`ffmpeg -version`), an ElevenLabs account that can use **Eleven v4**, and
   headphones. Run everything below from the repository root.
2. **See what is left.**

   ```sh
   python3 tool/prepare_story_voices.py --status
   ```

   It lists every pending clip (78 at the time of writing) and ends with "No
   problems." If it says `! 308 recorded takes are missing`, you are on a clone
   without the old takes: fine for recording new clips, but restore the backup
   (section 0) before you re-master anything old.
3. **Pick the clip.** `before-3-2-5`, Bill: "No flame seal on this guardian. Just
   a hungry pigeon and his star-grabbing gang." Its voice is Postmaster Bill's,
   GERALD - Exciting Older Voice (NEW), id `fGIZlgPQ75MMlvQ6WxgY`. Its prompt, from
   section 4, exactly:

   ```
   [chuckles] No flame seal on this guardian. [amused] Just a hungry pigeon and his star-grabbing gang.
   ```
4. **Generate it.** In the Flow linked at the top of section 4 (or the Text to
   Speech page), choose the voice above and the model **Eleven v4**, set the voice
   settings as in section 1, paste the prompt (audio tags and all) and generate
   **one** take. Listen with headphones: it must say exactly the printed words and
   no tag may be spoken aloud (`[chuckles]` is a direction, not a word). If a tag is
   read out or a word is wrong, generate again and keep the take you use.
5. **Download and save it.** Export **MP3, 44.1 kHz, 128 kbps** (`mp3_44100_128`)
   and save it as `build/story-voices/source/before-3-2-5.mp3`:

   ```sh
   mkdir -p build/story-voices/source
   ffprobe -v error -show_entries stream=codec_name,sample_rate,channels,bit_rate -of csv=p=0 build/story-voices/source/before-3-2-5.mp3
   ```

   The second command should print `mp3,44100,1,128000` (every one of the 308
   existing takes does). Note the take's **generation id** from ElevenLabs.
6. **Hash it.**

   ```sh
   sha256sum build/story-voices/source/before-3-2-5.mp3
   ```
7. **Fill in the entry.** In `docs/story-voices-sources.json` find
   `"name": "before-3-2-5"`. Before:

   ```json
   "voice_id": null,
   "voice": "GERALD - Exciting Older Voice (NEW)",
   "generation_id": null,
   "source_sha256": null,
   "status": "pending recording",
   "planned_voice_id": "fGIZlgPQ75MMlvQ6WxgY",
   "plays": "Scene before-3-2, line 5. Map, at the lair: ..."
   ```

   After (`voice_id` is the voice that actually spoke the take; the pending-only
   fields `status`, `planned_voice_id`, `fallback_voice_id`, `fallback_voice` and
   `plays` are deleted):

   ```json
   "voice_id": "fGIZlgPQ75MMlvQ6WxgY",
   "voice": "GERALD - Exciting Older Voice (NEW)",
   "generation_id": "<the take's generation id>",
   "source_sha256": "<the sha256sum output>"
   ```
8. **Master it** (FFmpeg trims it to the speech, sets the loudness and writes the
   game's Ogg file):

   ```sh
   python3 tool/prepare_story_voices.py --only before-3-2-5
   ```

   It prints something like `309 clips, ... s, ... MB` and `77 clips pending
   recording, skipped`. Now `assets/audio/story/before-3-2-5.ogg` exists and
   `lib/game/campaign_voice_clips.dart` (generated: never edit it) has a new line.
9. **Run the tests.**

   ```sh
   flutter test test/campaign_voices_test.dart test/campaign_story_test.dart
   ```

   "All tests passed!" is the goal. A failure says what is missing: "recorded, but
   not in the clip table" means step 8 was skipped; "is in the clip table but still
   says pending recording" means `status` was not deleted; "text differs from the
   printed line" or "the prompt speaks other words" means a text or prompt was
   edited and the game's line (`lib/domain/campaign_story.dart`) was not.
10. **Hear it in the game.** `flutter run` (add `--dart-define=NEW_YORK_OPEN=true`
    if New York is still closed in your build). Settings, **Character voices** on.
    Home, **Campaign**, swipe to New York, tap 3-2 (it opens once 3-1 is finished).
    The scene plays before the level card the first time; later, the card's **Story**
    key plays it again. Line 5 is Bill's: you hear your clip. Every other line is
    still silent and written out at the pace of voices off. (Egypt's scenes: swipe to
    Egypt and tap 2-6, open once 2-5 is finished.)
11. **Refresh and keep.** `python3 tool/prepare_story_voices.py --checklist` drops the
    clip from section 4. Commit the sources file, the clip table and the new `.ogg`.
    Back up `build/story-voices/` (section 0).

## 0. Back up first

The 308 takes already recorded live **only** in
`/run/media/parsa/projects/ravanix-other/push-up-bird-game/build/story-voices/source/`
(308 files, 23 MB), with `pip-auditions/` beside it. `build/` is git-ignored
(`/build/`) and `flutter clean` deletes it. Back it up before you add more, and
again after every session:

```sh
tar czf story-voice-takes-$(date +%F).tgz -C build story-voices
```

Copy the archive off this machine. `python3 tool/prepare_story_voices.py --status`
checks every take's hash after a restore. Library voices can also be withdrawn by
their authors; the voice backup is in [story-voices.md](story-voices.md), "Backing
up the takes".

## 1. Settings and export

- **Model** Eleven v4 (`eleven_v4`), **one generation** per clip, English.
- **Export** MP3, mono, 44.1 kHz, 128 kbps (`mp3_44100_128`). All 308 recorded takes
  were checked with `ffprobe` and are identical in format. The mastering script
  converts whatever it gets, but keep the format so a new take sits beside an old one.
- **Voice settings** (stability preset, similarity, style, speed, speaker boost): **not
  recorded** for the existing takes. Assume each voice's defaults on 2026-09-30. To
  close the gap, open one history item (for example `before-1-1-1`, generation id
  `UysfLzHl68MIorRDjpAY`), copy its settings into the `"voice_settings"` key of
  `docs/story-voices-sources.json` (it is `null` now) and use the same for every new
  take. **Never change a setting for one clip only**: it would no longer match its
  neighbours. If you change one for a voice, record it in the same key.
- **Take** the first generation unless it is wrong (a tag read aloud, a missing or
  changed word).

## 2. Audition the three new voices

Neferhoo's five auditions are already recorded: skip to "Neferhoo" below. For New
York's two, create 3 to 5 candidate voices for each part (ElevenLabs Voice Design from the
description, or the Voice Library with the search words), have every candidate say the
same three lines with their exact prompts, and compare them next to the voices they
share scenes with (Bill and the birds). The briefs and the reasons are in
[story-voices.md](story-voices.md).

**King Coo**: a plump, pompous, raspy old New York police commissioner; thick Brooklyn
accent, mid-low gravelly baritone, a little wheezy, blustering and easily offended,
like a cartoon precinct chief who missed his lunch. Comic, never menacing; wide
dynamic range, from a bellow to a wounded mumble. Library search: Brooklyn, New York,
cop, police chief, gruff, raspy, cartoon, old man, boisterous. Reject: villainous, posh
British (Bill and the Baron are), merely tired. Audition lines (`before-3-2-0`,
`before-3-2-4`, `last-3-2-6`):

```
[shouting] HALT! [pompously] By order of the Commissioner, nothing with wheels or wings passes!
[wistfully] Every night, same corner, same crumbs. [sniffs] Tonight: not a crumb, only wheel tracks.
[delighted] A bagel a day? [clears throat] …The Commissioner accepts.
```

**Searchlight Gargoyle**: a theatrical old stage actor, a ham in a limestone coat;
transatlantic (mid-Atlantic) accent, warm gravel, mid-low pitch, generous vibrato, calls
everyone "darling", lonely and tender underneath; must crack quietly on "You looked."
and puff up again on "I was born for this." Library search: theatrical, Shakespearean,
old actor, stage, transatlantic, mid-Atlantic, vintage, classic Hollywood. Reject: a
second Dragon (deep and weary) or a second Bill (old and British). Audition lines
(`before-3-4-1`, `before-3-4-3`, `last-3-4-2`):

```
[delighted gasp] A visitor! [warmly] Step into the light, darling, let me look at you!
[wistfully] Ninety-odd years on this ledge. [sighs] Everyone admires the skyline. [quietly] Nobody looks up.
[softly, voice cracking] You looked. [sniffs] [happily] That’s all I ever wanted.
```

Write down the winner's exact voice name and voice id. Then, from the repository root,
put it on every clip of the part in one go (the same for the Gargoyle with
`'Searchlight Gargoyle (audition)'`):

```sh
python3 - <<'EOF'
import json
path = 'docs/story-voices-sources.json'
data = json.load(open(path))
for clip in data['clips']:
    if clip['voice'] == 'King Coo (audition)':
        clip['voice'] = 'Chosen Voice Name'
        clip['planned_voice_id'] = 'THE_VOICE_ID'
open(path, 'w').write(json.dumps(data, indent=1, ensure_ascii=False) + '\n')
EOF
```

To use a fallback instead, run the same edit with the clip's `fallback_voice` name and
`fallback_voice_id`: **Rusty Malone - Deep & Raspy** (`507tTFX0IPtqFzGd1CAL`) for King
Coo, then Countdown Casey - Radio DJ (`mKoqwDP2laxTdq1gEgU6`); **Eldrin - Wise Epic
Fantasy Narration Storyteller** (`LvmvHEBEmMJBJw9UuhwO`) for the Gargoyle. Casey is
the stage manager at the marquee where the bread cart hides (`thanks-3-1`), so he is
the second choice; Scruffy Duck and Mister Gruff thank the courier in the same stop
and stay out. Audition any fallback before relying on it, then regenerate section 4.

### Neferhoo (Egypt's guardian): Herbie chosen

The owner chose **Herbie (Old Man with a Lisp and whistle S sounds)**,
`Kz0DA4tCctbPjLay2QT1`, from five new auditions on 2026-10-05. Those samples
and their generation ids are in
`build/story-voices/neferhoo-auditions-2026-10-05/manifest.json`.
The five older auditions below are retained as history.

**The part**: an elderly royal courier, a 4,000-year-old hoopoe in linen wraps and a
gold mask; fussy, precise, reedy, a little creaky, very proper, quick to take offence,
warm and silly underneath. Comic, never scary. Distinct from Bill (raspy eccentric
British), the Sphinx (ancient sage, `thanks-2-4`), the Dragon (grand, weary), the
Gargoyle (theatrical ham) and King Coo (Brooklyn). He speaks 8 recorded story clips and 16 recorded in-flight lines (section 7).

**The takes** (Eleven v4, one generation each, 2026-10-03; ids, generations and
transcripts in `manifest.json` beside them, notes in its `README.md`):
`/run/media/parsa/projects/ravanix-other/egypt-int/auditions/`. Every candidate says the
same line:

```
[haughtily] Neferhoo, Royal Courier. [clears throat] Four thousand years on this route. [shouting] Return to sender!
```

| # | Take | Voice | Voice id |
| --- | --- | --- | --- |
| 1 | `neferhoo-1-beezle.mp3` | Beezle Wheezelby (the design's first choice) | `BBfN7Spa3cqLPH1xAS22` |
| 2 | `neferhoo-2-ak.mp3` | AK - British Posh Well-Spoken Old Man | `y0SYydk17lMbUIUvSf3N` |
| 3 | `neferhoo-3-grampa-werthers.mp3` | Grampa Werthers - Old & Cranky (the fallback; already the 3-4 tower keeper) | `MKlLqCItoCkvdhrxgtLv` |
| 4 | `neferhoo-4-daniel.mp3` | Daniel - The Gruff Old British Wizard | `htZQqY7WtacRNV7s62Iy` |
| 5 | `neferhoo-5-cornelius.mp3` | Cornelius - Wise Sage | `6sFKzaJr574YWVu4UuJF` |

Listen for the name: it is NEF-er-hoo. If the chosen voice blurs it in the full
recording, write it `/ˈnɛfərhuː/` in that story clip's prompt (an IPA word between
slashes counts as the printed word; `campaign_voices_test` checks it). The in-flight
script takes no IPA (its prompt must say the text word for word): there, regenerate.

**Once the owner has picked**, from the repository root:

1. The story clips: the snippet above with `'Neferhoo (audition)'`, the chosen voice's
   exact name and its id. It fills `voice` and `planned_voice_id` on his 8 clips (the
   other voices in his scenes are already cast).
2. The in-flight lines: in `tool/prepare_flight_voices.py`, replace
   `'neferhoo': (None, 'Neferhoo (audition)')` in `VOICES` with
   `'neferhoo': ('THE_VOICE_ID', 'Chosen Voice Name')`, then run
   `python3 tool/prepare_flight_voices.py script`. It checks the whole script and
   writes the voice onto his 16 lines in `docs/flight-voices-sources.json` (nothing
   else changes; it refuses a take logged for him while he has no voice).
3. `python3 tool/prepare_story_voices.py --checklist` (his clips move from "to
   audition" to the voice's id in section 4), then
   `flutter test test/campaign_voices_test.dart test/flight_voice_script_test.dart`.

Record his story clips first: `before-2-6-7` is also his name-card line in the fight
(the `neferhoo-card` pool fills by itself once it is mastered).

## 3. Audio tags no recorded take has used

The 308 recorded takes use 64 different audio tags. Fourteen tags in New York's new
prompts appear in no recorded take, so none is proven **not to be read aloud**.
(Egypt's 31 story clips and Neferhoo's 32 in-flight lines use only proven tags.) Record the
clips that use them first, transcribe the takes (ElevenLabs Scribe) and check that no
tag is spoken. `python3 tool/prepare_story_voices.py --tags` lists them and the
clips, always up to date; section 4 marks the clips and lists them under "Record these
first".

If a take speaks its tag, change the clip's `prompt` (never its `text`), generate again
and note the swap in the clip's entry. Proven stand-ins:

| Tag | Swap for |
| --- | --- |
| `[pompously]` | `[dramatically]` or `[haughtily]` |
| `[wistfully]` | `[sadly]` |
| `[nervously]` | `[nervous]` |
| `[quietly]` | `[softly]` |
| `[sniffs]` | `[sighs]` |
| `[deadpan]` | `[dryly]` |
| `[theatrically]` | `[dramatically]` |
| `[happily]` | `[happy]` |
| `[ecstatic]` | `[overjoyed]` |
| `[fuming]` | `[angry]` |
| `[suspiciously]` | `[knowingly]` |
| `[pleading]` | `[worried]` |
| `[delighted gasp]` | `[gasps] [delighted]` |
| `[softly, voice cracking]` | `[softly] [trembling voice]` |

A tag that is spoken aloud once may be fine in another clip; the test is the transcript
of the take you actually keep.

## 4. The clips, in scene order

Tick each when its take is saved. Generated; do not edit between the markers.

<!-- checklist:begin (generated by tool/prepare_story_voices.py --checklist; do not edit) -->

Model `eleven_v4`, 1 generation per clip, export `mp3_44100_128`. Flow: https://elevenlabs.io/app/flows/aO9NKhIYwMqvPrxxU2tH

**What waits** (a voice with an id can be recorded now; a voice still to audition waits for section 2):

| Voice | Id | Clips |
| --- | --- | --- |
| King Coo (audition) | to audition | 8 |
| Searchlight Gargoyle (audition) | to audition | 6 |

**Record these first** (they use tags no recorded take has used; transcribe them to check no tag is read aloud, section 3):

- `before-3-2-0`: [pompously]
- `before-3-2-2`: [suspiciously], [fuming]
- `before-3-2-4`: [wistfully], [sniffs]
- `before-3-2-6`: [pompously]
- `last-3-2-0`: [quietly]
- `last-3-2-2`: [deadpan]
- `before-3-4-1`: [delighted gasp]
- `before-3-4-3`: [wistfully], [quietly]
- `before-3-4-4`: [theatrically], [pleading]
- `last-3-4-2`: [softly, voice cracking], [sniffs], [happily]
- `last-3-4-4`: [ecstatic], [theatrically]

### before-3-2 (4 clips)

- [ ] **1/14 `before-3-2-0`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [pompously] -> [dramatically] or [haughtily]
  - Prompt, exactly:

    ```
    [shouting] HALT! [pompously] By order of the Commissioner, nothing with wheels or wings passes!
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/before-3-2-0.mp3`; it becomes `assets/audio/story/before-3-2-0.ogg`.
  - Scene before-3-2, line 0. Map, at the lair: plays before 3-2's level card opens the first time; the card's story key replays it.

- [ ] **2/14 `before-3-2-2`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [suspiciously] -> [knowingly]; [fuming] -> [angry]
  - Prompt, exactly:

    ```
    [suspiciously] Umbrellas? A likely story! [fuming] You’re the one who moved my bread cart!
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/before-3-2-2.mp3`; it becomes `assets/audio/story/before-3-2-2.ogg`.
  - Scene before-3-2, line 2. Map, at the lair: plays before 3-2's level card opens the first time; the card's story key replays it.

- [ ] **3/14 `before-3-2-4`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [wistfully] -> [sadly]; [sniffs] -> [sighs]
  - Prompt, exactly:

    ```
    [wistfully] Every night, same corner, same crumbs. [sniffs] Tonight: not a crumb, only wheel tracks.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/before-3-2-4.mp3`; it becomes `assets/audio/story/before-3-2-4.ogg`.
  - Scene before-3-2, line 4. Map, at the lair: plays before 3-2's level card opens the first time; the card's story key replays it.

- [ ] **4/14 `before-3-2-6`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [pompously] -> [dramatically] or [haughtily]
  - Prompt, exactly:

    ```
    [shouting] [pompously] Nobody flies till the bread cart is found!
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/before-3-2-6.mp3`; it becomes `assets/audio/story/before-3-2-6.ogg`.
  - Scene before-3-2, line 6. Map, at the lair: plays before 3-2's level card opens the first time; the card's story key replays it. The same words are on the boss's name card in the flight.

### last-3-2 (4 clips)

- [ ] **5/14 `last-3-2-0`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [quietly] -> [softly]
  - Prompt, exactly:

    ```
    [sighs] My cap! [quietly] …It was the only thing that made them listen.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/last-3-2-0.mp3`; it becomes `assets/audio/story/last-3-2-0.ogg`.
  - Scene last-3-2, line 0. Map, at the lair: plays after 3-2 is first beaten; the card's story key replays it.

- [ ] **6/14 `last-3-2-2`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [deadpan] -> [dryly]
  - Prompt, exactly:

    ```
    [gasps] The marquee? [deadpan] It was under the marquee. [sighs] Out of the rain. All night.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/last-3-2-2.mp3`; it becomes `assets/audio/story/last-3-2-2.ogg`.
  - Scene last-3-2, line 2. Map, at the lair: plays after 3-2 is first beaten; the card's story key replays it.

- [ ] **7/14 `last-3-2-4`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Prompt, exactly:

    ```
    [sheepishly] And I closed the whole sky. [sighs] …I may have overreacted.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/last-3-2-4.mp3`; it becomes `assets/audio/story/last-3-2-4.ogg`.
  - Scene last-3-2, line 4. Map, at the lair: plays after 3-2 is first beaten; the card's story key replays it.

- [ ] **8/14 `last-3-2-6`**: King Coo (audition)
  - Fallback: Rusty Malone - Deep & Raspy (`507tTFX0IPtqFzGd1CAL`)
  - Prompt, exactly:

    ```
    [delighted] A bagel a day? [clears throat] …The Commissioner accepts.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/last-3-2-6.mp3`; it becomes `assets/audio/story/last-3-2-6.ogg`.
  - Scene last-3-2, line 6. Map, at the lair: plays after 3-2 is first beaten; the card's story key replays it.

### before-3-4 (3 clips)

- [ ] **9/14 `before-3-4-1`**: Searchlight Gargoyle (audition)
  - Fallback: Eldrin - Wise Epic Fantasy Narration Storyteller (`LvmvHEBEmMJBJw9UuhwO`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [delighted gasp] -> [gasps] [delighted]
  - Prompt, exactly:

    ```
    [delighted gasp] A visitor! [warmly] Step into the light, darling, let me look at you!
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/before-3-4-1.mp3`; it becomes `assets/audio/story/before-3-4-1.ogg`.
  - Scene before-3-4, line 1. Map, at the lair: plays before 3-4's level card opens the first time; the card's story key replays it.

- [ ] **10/14 `before-3-4-3`**: Searchlight Gargoyle (audition)
  - Fallback: Eldrin - Wise Epic Fantasy Narration Storyteller (`LvmvHEBEmMJBJw9UuhwO`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [wistfully] -> [sadly]; [quietly] -> [softly]
  - Prompt, exactly:

    ```
    [wistfully] Ninety-odd years on this ledge. [sighs] Everyone admires the skyline. [quietly] Nobody looks up.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/before-3-4-3.mp3`; it becomes `assets/audio/story/before-3-4-3.ogg`.
  - Scene before-3-4, line 3. Map, at the lair: plays before 3-4's level card opens the first time; the card's story key replays it.

- [ ] **11/14 `before-3-4-4`**: Searchlight Gargoyle (audition)
  - Fallback: Eldrin - Wise Epic Fantasy Narration Storyteller (`LvmvHEBEmMJBJw9UuhwO`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [theatrically] -> [dramatically]; [pleading] -> [worried]
  - Prompt, exactly:

    ```
    [theatrically] Hold still! [pleading] Nobody ever stays in the light.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/before-3-4-4.mp3`; it becomes `assets/audio/story/before-3-4-4.ogg`.
  - Scene before-3-4, line 4. Map, at the lair: plays before 3-4's level card opens the first time; the card's story key replays it. The same words are on the boss's name card in the flight.

### last-3-4 (3 clips)

- [ ] **12/14 `last-3-4-0`**: Searchlight Gargoyle (audition)
  - Fallback: Eldrin - Wise Epic Fantasy Narration Storyteller (`LvmvHEBEmMJBJw9UuhwO`)
  - Prompt, exactly:

    ```
    [sighs] Ah, the curtain falls. [sadly] …You chipped my beak. It was my best feature.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/last-3-4-0.mp3`; it becomes `assets/audio/story/last-3-4-0.ogg`.
  - Scene last-3-4, line 0. Map, at the lair: plays after 3-4 is first beaten; the card's story key replays it.

- [ ] **13/14 `last-3-4-2`**: Searchlight Gargoyle (audition)
  - Fallback: Eldrin - Wise Epic Fantasy Narration Storyteller (`LvmvHEBEmMJBJw9UuhwO`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [softly, voice cracking] -> [softly] [trembling voice]; [sniffs] -> [sighs]; [happily] -> [happy]
  - Prompt, exactly:

    ```
    [softly, voice cracking] You looked. [sniffs] [happily] That’s all I ever wanted.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/last-3-4-2.mp3`; it becomes `assets/audio/story/last-3-4-2.ogg`.
  - Scene last-3-4, line 2. Map, at the lair: plays after 3-4 is first beaten; the card's story key replays it.

- [ ] **14/14 `last-3-4-4`**: Searchlight Gargoyle (audition)
  - Fallback: Eldrin - Wise Epic Fantasy Narration Storyteller (`LvmvHEBEmMJBJw9UuhwO`)
  - Unproven tags, check by transcription (stand-ins if read aloud): [ecstatic] -> [overjoyed]; [theatrically] -> [dramatically]
  - Prompt, exactly:

    ```
    [ecstatic] A nightly audience! [theatrically] …Darling, I was born for this. The Gargoyle accepts.
    ```

  - Model `eleven_v4`, 1 generation.
  - Save the take as `build/story-voices/source/last-3-4-4.mp3`; it becomes `assets/audio/story/last-3-4-4.ogg`.
  - Scene last-3-4, line 4. Map, at the lair: plays after 3-4 is first beaten; the card's story key replays it.

<!-- checklist:end -->

## 5. After each batch

1. Fill in each clip's entry as in step 7 of the walkthrough. The hashes of a batch:

   ```sh
   cd build/story-voices/source
   for f in before-3-2-*.mp3 last-3-2-*.mp3 before-3-4-*.mp3 last-3-4-*.mp3 before-2-6-*.mp3 last-2-6-*.mp3 thanks-2-6.mp3; do echo "${f%.mp3} $(sha256sum "$f" | cut -d' ' -f1)"; done
   ```
2. Master the batch (FFmpeg needed), naming the clips:

   ```sh
   python3 tool/prepare_story_voices.py --only before-3-2-5 before-3-2-7
   ```
3. `python3 tool/prepare_story_voices.py --status` lists what is still pending and flags
   a take whose hash no longer matches.
4. `flutter test test/campaign_voices_test.dart test/campaign_story_test.dart` and
   `flutter analyze`, then play the scene in the game with Character voices on and off.
5. `python3 tool/prepare_story_voices.py --checklist` to refresh section 4.
6. Back up `build/story-voices/` again (section 0), then commit the sources file, the
   clip table, this file and the new `.ogg` files.

## 6. Not in this list

- **Fight bark** (`coo-pop`, "Ooof! My lunch!"): the one unused bark kept, under
  `optional_clips`. Nothing in the game plays it yet. Record it only when the
  in-flight voice system has a place for it.
- **The Alley Pigeon** has no voice: pigeons coo and flap (sound effects, not speech).
- **The "To be continued…" clip** (`last-3-4-6`, the narrator) goes unused when Paris
  opens and the caption is removed.
- **Neferhoo's in-flight lines** are not story clips: they are in
  `docs/flight-voices-sources.json`, listed in section 7.

## 7. Neferhoo's in-flight lines (32, recorded)

They live in `docs/flight-voices-sources.json` (the flight script's format: a line
with no `generation_id` has no take yet). `python3 tool/prepare_flight_voices.py
pending` lists them; this table is for reading and ticking, the sources file is the
record (`flight_voice_script_test` checks every prompt below is the file's). His 16
are recorded in Herbie's voice (section 2); the birds' 16 use their existing
voices. Each of his moments, and each bird's greeting, keeps two lines.
Farewells and the cargo lines stay at one, and the only unused fight bark left is
`coo-pop` (section 6).

Recording one: Eleven v4, one generation, the speaker's voice, the prompt exactly as
written. Save the take as `build/flight-voices/source/<name>.mp3`, log it in any
JSON file under `build/flight-voices/generations/` as
`{"<name>": {"generation_id": "...", "prompt": "<the prompt>"}}`, then
`python3 tool/prepare_flight_voices.py script` (it fills `generation_id` and
`source_sha256`) and `python3 tool/prepare_flight_voices.py --only <names>` (masters
the takes and regenerates `lib/game/flight_voice_clips.dart` and
`flight_voice_faces.dart`). When all 28 of his and his birds' answers are in, move
`BossKind.neferhoo` from `FlightVoices.pendingBosses` to `voicedBosses` in
`lib/game/flight_voices.dart` (`flight_voice_script_test` insists); the four cargo
lines play by themselves once mastered.

**Neferhoo: arrival**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-arrive-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [haughtily] Who disturbs the Pharaoh's post? |
| `neferhoo-arrive-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [surprised] A courier? [angry] On MY route? [shouting] Return to sender! |

**Neferhoo: taunt (quiet moments)**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-taunt-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [proudly] I have outflown sandstorms, fledgling. [dryly] You are a breeze. |
| `neferhoo-taunt-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [mischievously] My satchel is full of letters nobody wanted. Take one! |

**Neferhoo: attack = the MAIL CALL, as the lane locks**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-attack-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [shouting] Mail call! |
| `neferhoo-attack-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [excited] Special delivery! |

**Neferhoo: summon = the ankh, thrown**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-summon-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [chuckles] Catch, fledgling! It always comes back. |
| `neferhoo-summon-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [excited] Round and round it goes! |

**Neferhoo: hurt = one of his own letters lands home (never a rock on his wraps)**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-hurt-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [gasps] Oof! [surprised] Return to... me? |
| `neferhoo-hurt-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [surprised] My own letter?! [grumpy] How rude. |

**Neferhoo: gloat (he hits the bird)**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-gloat-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [laughs] Signed, sealed, delivered! |
| `neferhoo-gloat-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [proudly] Delivered! No signature needed. |

**Neferhoo: mad = the fury stage (a third of his health left)**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-mad-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [angry] Enough! [shouting] EXPRESS POST! |
| `neferhoo-mad-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [disgusted] You have crumpled my wrappings! |

**Neferhoo: defeated**

| Line | Voice | Prompt |
| --- | --- | --- |
| `neferhoo-defeated-01` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [gasps] My mask! Where is my... [surprised] oh. [delighted] I can see! |
| `neferhoo-defeated-02` | Herbie (Old Man with a Lisp and whistle S sounds) (`Kz0DA4tCctbPjLay2QT1`) | [sighs] Return... to... sender... |

**Each bird meets him (2) and sees him off (1)**

| Line | Voice | Prompt |
| --- | --- | --- |
| `pip-boss-neferhoo-01` | Nelson – Awkward Nerd Character (`EaX6rnyDKjJx35tchi80`) | [excited] A mummy with a mailbag! [determined] Shoot the letters back, Pip! |
| `pip-boss-neferhoo-02` | Nelson – Awkward Nerd Character (`EaX6rnyDKjJx35tchi80`) | [nervous] Royal Courier? [thoughtfully] I'm just Courier. Courier Pip. |
| `pip-boss-down-neferhoo-01` | Nelson – Awkward Nerd Character (`EaX6rnyDKjJx35tchi80`) | [cheerfully] Delivered! Even four thousand years late. |
| `peaches-boss-neferhoo-01` | Cherry Twinkle – Adorable Cartoon Girl (`XJ2fW4ybq7HouelYYGcL`) | [excited] Ooh, a pharaoh bird! [curious] His letters smell like old books. |
| `peaches-boss-neferhoo-02` | Cherry Twinkle – Adorable Cartoon Girl (`XJ2fW4ybq7HouelYYGcL`) | [mischievously] Return to sender, mister! [giggles] With love! |
| `peaches-boss-down-neferhoo-01` | Cherry Twinkle – Adorable Cartoon Girl (`XJ2fW4ybq7HouelYYGcL`) | [warmly] Go deliver your letter, Mister Neferhoo! |
| `minty-boss-neferhoo-01` | Teddy Twinkle - Cute Cartoon Boy (`XjGYkUkzth8BPs29fmcV`) | [excited] Letters incoming! Bonk them back, bonk them back! |
| `minty-boss-neferhoo-02` | Teddy Twinkle - Cute Cartoon Boy (`XjGYkUkzth8BPs29fmcV`) | [laughs] A mummy? He's even slower than the sloth! |
| `minty-boss-down-neferhoo-01` | Teddy Twinkle - Cute Cartoon Boy (`XjGYkUkzth8BPs29fmcV`) | [excited] Every letter lands! Woo-hoo! |
| `orbit-boss-neferhoo-01` | Lola - Soft, Innocent and Calming (`f9imtLc2jfOLXtqe3Ihb`) | [softly] Wrapped up like a sleepy bedtime story. |
| `orbit-boss-neferhoo-02` | Lola - Soft, Innocent and Calming (`f9imtLc2jfOLXtqe3Ihb`) | [whispers] Shh... his letters only want to go home. |
| `orbit-boss-down-neferhoo-01` | Lola - Soft, Innocent and Calming (`f9imtLc2jfOLXtqe3Ihb`) | [gently] Sleep well, old courier. Your letter landed. |

**Each bird on 2-6's first try (cargo)**

| Line | Voice | Prompt |
| --- | --- | --- |
| `pip-cargo-2-6-01` | Nelson – Awkward Nerd Character (`EaX6rnyDKjJx35tchi80`) | [nervous] A feather duster. [thoughtfully] I'm choosing not to ask whose feathers. |
| `peaches-cargo-2-6-01` | Cherry Twinkle – Adorable Cartoon Girl (`XJ2fW4ybq7HouelYYGcL`) | [cheerfully] A feather duster for the pyramid! [excited] Dust bunnies, beware! |
| `minty-cargo-2-6-01` | Teddy Twinkle - Cute Cartoon Boy (`XjGYkUkzth8BPs29fmcV`) | [excited] Duster delivery! Zip in, swish swish, zip out! |
| `orbit-cargo-2-6-01` | Lola - Soft, Innocent and Calming (`f9imtLc2jfOLXtqe3Ihb`) | [softly] A feather duster... for very old, very sleepy dust. |
