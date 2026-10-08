# Localization

Beakbound speaks English plus 11 languages. Every player-facing string comes
from an ARB file, the story captions are translated in full, and each
language has a voice pack that Google Play delivers on demand. English stays
the source and the fallback for anything missing.

The design records of the localization program live outside the repo, in
`../l10n-ws/` (`BRIEF.md`, `MASTER-PLAN.md`, `VOICE-PLAN.md`, the
translators' and integrators' reports, and the owner questions). Code
comments that cite `l10n-ws/…` point there.

## Languages

| Language | Tag | Slug | Voice rank | Story voices | Flight lines voiced |
|---|---|---|---|---|---|
| English | `en` | `en` | 0 (built in) | 372 | 1,273 |
| Spanish (Latin America) | `es-419` | `es_419` | 1 | 372 | 637 (50 %) |
| Portuguese (Brazil) | `pt-BR` | `pt_br` | 1 | 372 | 637 |
| Indonesian | `id` | `id` | 1 | 372 | 637 |
| French | `fr` | `fr` | 1 | 372 | 637 |
| German | `de` | `de` | 1 | 372 | 637 |
| Japanese | `ja` | `ja` | 2 | 372 | 382 (30 %) |
| Korean | `ko` | `ko` | 2 | 372 | 382 |
| Turkish | `tr` | `tr` | 2 | 372 | 382 |
| Traditional Chinese (Mandarin voices) | `zh-Hant` | `zh_hant` | 2 | 372 | 382 |
| Russian | `ru` | `ru` | 2 | 372 | 382 |
| Arabic (right to left) | `ar` | `ar` | 3 | 372 | 255 (20 %) |

`AppLanguage` (`lib/l10n/app_language.dart`) is the single list; tools and
tests hold their own lists to it (`test/l10n_language_test.dart`,
`test/voice_pack_wiring_test.dart`). The 14 story clips still pending in
English stay text-only in every language.

How the language is chosen (`lib/l10n/language_providers.dart`):
`--dart-define=L10N_LOCALE=<tag>` for a dev run, else the Settings choice
(globe key in the Settings header, `lib/ui/language_picker.dart`), else the
first device language we speak, else English. `es-*` maps to es-419,
`pt-*` to pt-BR, `zh-TW/HK/MO` and `zh-Hant*` to zh-Hant; `zh-Hans/CN/SG`
fall through to the next device language. The choice is a device setting
(preferences key `language`), never synced, kept across a progress reset.

## Strings (ARB)

- Template: `lib/l10n/arb/app_en.arb` (1,611 keys). Translations:
  `app_<locale>.arb`. `app_es.arb`, `app_pt.arb` and `app_zh.arb` are empty
  stubs gen-l10n needs next to the regional files; never translate them.
  `app_en_XA.arb` is the generated pseudo-locale (accents, +40 % length,
  `[…]` brackets) for fit tests.
- Generated code: `lib/l10n/generated/` (committed). `flutter gen-l10n`
  regenerates it; `flutter pub get`, `run` and `build` do too.
- In widgets: `context.l10n.someKey`. In Flame/canvas code: `L10n.strings`,
  with `textDirection: L10n.textDirection` on painters that set words and
  `heading()`/`bodyText()` styles for the font fallbacks
  (`lib/l10n/l10n.dart`).
- Domain code keeps its English text as the "English twin" (tests, logs,
  fallback). Presentation maps ids to keys in `lib/l10n/text/*_text.dart`;
  parity tests keep the English ARB equal to the twins.
- A missing translation falls back to English, key by key, so a partial
  language is always safe.

### Adding or changing a key

1. Add it to `app_en.arb` with an `@key` entry. `description` is required:
   where it shows, what it is, tone, any game term. Add `x-maxChars` (display
   width; CJK counts 2) to every single-line label, button, name or HUD
   shout. Placeholders are named and typed; counts use ICU `plural` with
   `other`; no string concatenation.
2. `python3 tool/l10n/merge_arb.py` (validates the template, rewrites the
   pseudo ARB and the stubs), then `flutter gen-l10n`.
3. Translate it into the 11 ARBs (see the glossary below), or leave it
   English for now: `check_arb.py` lists it as untranslated.
4. `python3 tool/l10n/check_arb.py --require-complete` must exit 0. It
   checks ICU syntax, placeholders, select cases, budgets, empty values,
   layout switches (`x-choices`) and glyph coverage.
5. If a translation adds a character the bundled fonts lack, re-cut the
   fonts (below) and run `check_arb.py` again.
6. `python3 tool/l10n/find_strings.py` finds hardcoded English left in
   `lib/` (mark a false positive with `// l10n-ignore`).

Run the `test/l10n_*` tests that cover the screen you touched. They render
screens under the pseudo-locale and Arabic and fail on cut or overflowing
text.

### Translators' glossary

`l10n/glossary/`: `terms.en.json` (every name, place, boss, game term and
fixed phrase, by id), one `<slug>.json` per language (`{"terms": {id: {en,
target, note}}}`), and `CHARACTERS.md` (the character bible: tone, who is
who, genders, running jokes, the motto). Give a translator `app_en.arb`, the
language's glossary and `CHARACTERS.md`. Some glossaries still note older
short forms that later layout work replaced (tr «Akşam İmparatoriçesi», de
«Wasserspeier», fr/pt short boss names): the ARBs are authoritative; update
the glossary before the next translation round.

## Story captions

Story lines and thank-you notes are captions keyed by voice clip, so a
caption and its recording always match. They ship in the base bundle,
localized even when only English voices are installed.

- `assets/l10n/story/<slug>.json` (flat `{"<clip>": "<caption>"}`) and
  `index.json`, read by `StoryCaptions` (`lib/l10n/story_captions.dart`).
- Source: the translators' voice scripts
  `../l10n-ws/voice/<slug>/story.json` (`{"<clip>": {"text", "prompt"}}`).
  After changing one, rebuild that language:
  `python3 tool/l10n/build_captions.py <slug> ../l10n-ws/voice/<slug>/story.json`,
  then `check_arb.py` (and the font re-cut if it reports a missing glyph).
  A caption change that is also spoken needs a re-recorded clip.

## Fonts

Fredoka (headings) and Nunito (body) cover the Latin languages. Script fonts
fill only the glyphs those lack, per glyph (`fontFamilyFallback`), from
`lib/l10n/language_fonts.dart` (mirrored in `tool/l10n/fonts.json`):

| Font (`assets/fonts/l10n/`) | Used for |
|---|---|
| Baloo Bhaijaan 2 | Arabic, Turkish headings, arrow glyphs on the co-op key hints |
| M PLUS Rounded 1c Bold | Japanese; Cyrillic headings (Russian) |
| Jua | Korean |
| Huninn | Traditional Chinese |

They are subsets cut to the characters the ARBs, captions and native names
use (1.47 MB of a 3 MB budget). After any translation or caption change:

    python3 tool/l10n/subset_fonts.py --fetch   # pinned sources into build/l10n-fonts, sha256 checked
    python3 tool/l10n/check_arb.py --require-complete

`subset_fonts.py` re-stamps each font's modified date, so the files change
on every run even when the glyphs do not. All four are SIL OFL 1.1; their
licenses sit next to them and are registered in `main.dart`. Player-typed
text (built level names) falls back to system fonts.

## Right to left (Arabic)

Menus, sheets, results and the builder chrome mirror through
`Directionality`. The flight does not: `FlightDirection` keeps the game
widget, the HUD, co-op/duel sides, replay controls and the campaign map's
route left to right; a sentence inside such a layer restores its direction
with `LanguageDirection`. Painted directional glyphs (back keys) flip under
RTL. Digits stay Western everywhere. Known gap: the push-up calibration
screen keeps the camera preview on the left in Arabic.

## Visual QA

`tool/l10n/visual_qa_test.dart` (in `tool/`, so the suite never runs it)
renders 63 shots per locale at 792×360 and writes a fit report:

    flutter test tool/l10n/visual_qa_test.dart \
      --dart-define=L10N_QA_LOCALES=en-XA,ar,de \
      --dart-define=L10N_QA_OUT=/abs/path/out

`L10N_QA_SHOTS=settings,campaign-map` narrows it. About 170 KB per PNG:
delete them after looking.

## Voice packs

### Layout and runtime

    assets/voice/index.json                 base bundle: each pack's counts and bytes
    assets/voice/<slug>/manifest.json       in the pack: length, mouth table, mood per clip
    assets/voice/<slug>/story/<clip>.ogg    story clips, English clip names
    assets/voice/<slug>/flight/<line>.ogg   in-flight lines, English line names

Each pack is a Flutter deferred component `voice_<slug>` (pubspec.yaml,
generated block) and an asset-only, on-demand Android feature module
`android/voice_<slug>/`. `VoicePackDelivery.kt` installs modules through
Play Feature Delivery 2.x (Flutter's own Play manager is built on Play Core
1.x, which current Android refuses). `lib/game/voice_packs.dart` probes,
installs and reads packs; Settings shows a badge per language (available,
downloading with progress, installed, English voices, failed: tap to
retry).

Rules: the active language's pack installs when that language becomes
active. Until then, and for any story clip a pack lacks, the English clip
plays under the localized caption. In flight, a language with its own lines
draws only from them; with none, it follows `FlightVoicePolicy` (default
English). English assets, tables and faces are unchanged.

Where packs end up:

| Build | Packs |
|---|---|
| `flutter run`, `flutter build apk` (sideload) | inside the APK, every listed pack |
| `flutter build appbundle` (Play) | one on-demand module each |
| iOS, desktop, tests | bundled in the app |

All 11 packs are 228.8 MB (rank 1 about 24–26 MB each, rank 2 about
15.5–18 MB, Arabic 15.6 MB).

### Dev builds: choosing packs

A sideloaded or `flutter run` build carries every listed pack, ~229 MB more
on the phone. List only the ones you need:

    python3 tool/l10n/dev_voice_packs.py --only es_419,de   # just these
    python3 tool/l10n/dev_voice_packs.py --none             # none
    python3 tool/l10n/dev_voice_packs.py --all              # every pack: the release state
    python3 tool/l10n/dev_voice_packs.py --status           # what is listed now
    python3 tool/l10n/dev_voice_packs.py --check            # exit 1 unless all are listed

It rewrites only the generated blocks of `pubspec.yaml` and
`android/settings.gradle.kts` and marks a subset with a
`voice-packs:dev-subset` comment in both, so `git status` shows it. A
language whose pack is left out acts like a phone that has not downloaded
it: the badge shows "failed" (Play is not there to install it) and English
voices play under the localized captions.

Never commit a subset. Two guards stop one from shipping:
`flutter build appbundle` fails in `android/app/build.gradle.kts` unless
every `android/voice_<slug>` module is listed, and
`test/voice_pack_wiring_test.dart` fails while a subset is listed. Run
`--all` before a release build. `prepare_localized_voices.py --wire` also
restores all packs.

### Recording

Voices are ElevenLabs Eleven v4, recorded through the ElevenLabs MCP (no API
key in the repo), one take per line, in the English character's voice id
(`docs/story-voices-sources.json`, `docs/flight-voices-sources.json`), with
`language_code` set and the English audio tags (`[excited]`, …) kept inside
the translated prompt. The procedure, batch lists, flow ids and the
recorder prompt are in `../l10n-ws/voice/` (`RECORDING-L10N.md`,
`RECORDER-PROMPT.md`, `<slug>/batches/`, `flows.json`); the flight-line
subsets per rank are `../l10n-ws/voice/subsets.json`. Takes land in
`../l10n-ws/voice/<slug>/takes/{story,flight}/<name>.mp3` with their
generation ids in `<slug>/generations/`. A backup of every take, manifest
and script is `~/beakbound-backups/l10n-voice-takes-20261007T1225Z-final.tar`.

### Mastering

    python3 tool/l10n/prepare_localized_voices.py --lang <slug>            # master new takes
    python3 tool/l10n/prepare_localized_voices.py --lang <slug> --all      # master every take again
    python3 tool/l10n/prepare_localized_voices.py --lang <slug> --only <clip> ...
    python3 tool/l10n/prepare_localized_voices.py --lang <slug> --status   # no FFmpeg
    python3 tool/l10n/prepare_localized_voices.py --wire                   # pubspec + Android modules

It uses the English chain (trim, one loudness gain: story −18 LUFS, flight
−16 LUFS, mono Ogg Vorbis q2 at 24 kHz), measures each take's mouth table
and mood the way the English faces do, writes the pack and its manifest,
refreshes `assets/voice/index.json`, and flags takes much shorter or longer
than English, near-silent or clipped takes, and stale prompts. It reads the
takes from `../l10n-ws/voice` (`--voice-dir` or `$L10N_VOICE_DIR` to
change). Then run `test/voice_pack_wiring_test.dart` and
`test/voice_packs_test.dart`.

## Store listing and Play Games (owner, in Play Console)

Nothing below ships in the app; the texts are in `l10n/store/<slug>.json`
(`listing`, `playGames`, `achievements`), checked by
`python3 tool/l10n/check_store.py`. The English listing in
`l10n/store/en.json` is a draft awaiting your approval.

1. **Store listing**: Grow users › Store presence › Main store listing ›
   Manage translations › add each language (es-419, pt-BR, id, fr-FR, de-DE,
   ja-JP, ko-KR, tr-TR, zh-TW, ru-RU, ar) and paste `listing.title`,
   `shortDescription`, `fullDescription` from its file; `releaseNotes` go
   with the release. Localized screenshots are optional (the visual QA
   shots are a starting point).
2. **Play Games Services** (its Configuration page): add translations of
   the game's display name and description (`playGames`); then under
   Achievements open each one and add its translations (`achievements`,
   keyed by `PlayAchievement`, in Console order). Achievement names 1–24 match
   the in-game passport words.
3. **On-demand voice packs** (needs a device): upload the app bundle to the
   internal testing track, install from Play on a phone, switch the
   language in Settings, and check the badge goes download → installed, the
   voices play in that session (otherwise after a restart), and the game
   still plays offline afterwards. Without Play:
   `bundletool build-apks --local-testing --bundle app-release.aab --output app.apks`
   then `bundletool install-apks --apks app.apks`.

## Open questions

`../l10n-ws/reports/OWNER-QUESTIONS.md` collects the owner decisions still
open (names, terms, register, Arabic bidi, voices, budgets), with what the
integrators settled and the defaults taken.

## Tests

`test/l10n_*` (strings, tables, fit, RTL, captions, back keys),
`test/voice_packs_test.dart`, `test/voice_pack_wiring_test.dart`,
`test/voice_pack_badge_test.dart`, `test/voice_pack_dev_switch_test.dart`,
and the voice tests (`campaign_voices_test`, `flight_voice*_test`) cover
this area. Localization changes no rules, replay or simulation value.
