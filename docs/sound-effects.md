# Sound effects

The game bundles short PCM effects and variations. All playback works offline
and uses the existing **Sound effects** setting independently of music.

## Sound palette

| Action | Design |
| --- | --- |
| Flap / shooting | Three soft feather swishes / one consistent punchy projectile crack with a short falling body |
| Power shots | Deeper 420 ms launch from the same take, a bright E6–A6 ping at full charge, and a soft falling D4–A3 click when the reserve is empty |
| Sprint | A 550 ms rising air rush with a soft impact, and a bright F5–C6–F6 bell when the cooldown ends |
| Enemy combat | Quiet charge, projectile launch, crunchy death puff (three takes) |
| Projectile collisions | Stone impact and bright interception ping |
| Boss arrival | Ominous wind warning, reveal impact, creature roar |
| Boss combat | Charge, heavy volley, hit, shield activation/block, summon and enrage |
| Pirate Captain | Crackling fuse, black-powder cannon boom with a wooden deck knock (two takes), a ship's bell over swelling water for the tide warning, a roaring surge, and a plunging splash (two takes) |
| Ember Dragon | A 1.45 s inhale that swells from near silence: air rushing in over a growl climbing 42–74 Hz, with embers crackling in the throat toward the end. A 1.6 s flame: a heavy ignition whump, then a turbulent roaring jet that holds and gutters out, with snapping embers. A 0.45 s ember split: a sharp pop and three hissing tongues. Charge and volley reuse the shared boss cues |
| Alley Pigeon | A rolling "coo-ROO-oo" as it marks its star (two takes, a whole tone apart), four dry wing claps on its dive, a clap, beak tick and falling pair of bells when it snatches, a squeaking feather-puff defeat (two takes), and three rising bells when a star is won back |
| Steam Geysers | A 1.4 s hiss that swells and spits faster over ever-quicker iron knocks, a crack and roaring jet that darkens (two takes) with an iron clang (two takes) as the vent bursts, and a rising updraft with an E5-B5 sparkle |
| Searchlight Gargoyle | Lightning on the rod and the stone waking in place of the reveal and roar, a shutter slam and winding hum with quickening relay ticks for the beam warning, a 2.9 s arc-lamp buzz for the sweep, a pop and G6 bell when the bird is caught, ratcheting louvres and steam when the lamp opens, a steel clink when a rock glances off it (two takes), a rustle and stone tick for each feather (two takes), a grinding, searing fury in the mids a phone plays, and limestone, glass and wings for the burst that ends him |
| King Coo | A 0.85 s "COO!" cut to his beak's swell for the arrival and the long "COO-ROO-COOOO" for fury, a two-blast pea whistle with a flock taking off, a swish-thwup and a crinkle of crumbs for each bomb, an inflating squeak under the hit-stop, a pop, and a deflating defeat with two sad coos |
| Neferhoo | ElevenLabs takes: a giant hoopoe's three hollow hoots, re-timed to his beak, with a small temple gong ringing out for his arrival and each stage-up (and a gritty sand-devil swirl under the arrival), a satchel thump, rustle and rising chimes for each mail call, a paper snap for each letter, a stamp thunk that bends up into a boing when a rock sends one back, a double rubber-stamp "ka-chunk" with a ringing bell when it lands, a short cloth slap for a rock on his wraps, a hum under rising chimes as the ankh rises, a chopped whir in flight, a gold clink over a thump when it is caught, three rough cries and a short one over the gong for fury, a brass clang and a burst of paper for the mask, and four soft bell notes rising (C-E-G-C) for the lost letter |
| Boss death | Breaking body, debris burst and victory flourish, timed to the animation |
| Player damage / recovery | Padded impact, shield break/recharge and dedicated heart pickup |
| Rewards | Three rotating bell tones for stars, plus bell and wood tones for perfect gates, combos, magnet, letters, deliveries and discoveries |
| Milestones | Wing, record, unlock, final stretch, completion and flight end |
| Finish line | A harp glissando up to a shimmering high D over a swelling shaker as the gate's lights chase in; a ribbon tape snap with a twang, two party poppers 50 ms apart and a shower of confetti; a little flock chirping, with two whistled "wheet-whoo"s, while the music ducks; an airy swoop onto the result cloud ending in a soft fwump. The `complete` fanfare plays between them |
| Interface | Soft major-key plucks for buttons, back, toggles, pause and resume; ascending confirmation notes with rounded attacks and gentle tails |

Generated Foley was made with ElevenLabs `eleven_text_to_sound_v2`. Prompts,
generation IDs and downloaded source hashes are in
[sound-effects-sources.json](sound-effects-sources.json). The other cues are
original deterministic compositions in `tool/prepare_sound_effects.py`.
The Ember Dragon's `dragon_inhale`, `dragon_breath` and `ember_split` are
among them. They use no external source and no network, and are built from
seeded noise with the script's `flame`, `crackle` and `growl` helpers. To
render only those three:

```sh
python3 tool/prepare_sound_effects.py --only dragon_inhale dragon_breath ember_split
```

The upgraded Baron Bat's `screech_warning` (1.45 s: falling sonar chirps
that quicken from about 3 to 18 a second and climb in pitch, over a thin
whistle drawing tight) and `sonic_screech` (1.2 s: a soft pressure thump,
then a shrill, wavering two-voice shriek gliding down from 2.6 kHz over a
descending rush of air) are synthesised the same way, with the script's
`chirp` and `whistle` helpers:

```sh
python3 tool/prepare_sound_effects.py --only screech_warning sonic_screech
```

New York's 29 cues (the Alley Pigeon, Steam Geysers, King Coo and the
Searchlight Gargoyle, 36 files) are synthesised the same way; see
[New York cues](#new-york-cues-rules-version-43) below for the command per
family, every parameter, the seeds and the measurements.

Egypt's 13 cues (Neferhoo, the Mummy Courier, rules version 50) were
synthesised the same way and are made from ElevenLabs takes since 2026-10-04
(the syntheses still render with `--egypt-synth`); see
[Egypt cues](#egypt-cues-rules-version-50).

The source takes are kept in ignored `build/sound-effects/source/`. To reproduce
the assets after restoring those source files:

```sh
python3 tool/prepare_sound_effects.py
```

The tool extracts a single attack from repeating takes, fits long gestures to
animation timing, removes DC offset, fades boundaries and masters peaks to
-3.10 dBFS, with gentler menu cues at -6.94 dBFS. Output is mono 44.1 kHz,
signed 16-bit PCM. Every file is smaller than Android SoundPool's decoded-buffer
limit. The complete bank is 3.00 MB.
It writes durations, RMS levels and output SHA-256 hashes to
`build/sound-effects/verification.json`.

`tool/generate_audio.py` and `tool/generate_boss_audio.py` are the earlier
prototype generators; running them overwrites parts of this mastered bank.
Use `prepare_sound_effects.py` for the current assets.

## Playback and event routing

`sound_bank.dart` defines volume, duration, cooldown, priority and variation
count. `SkyAudio` keeps at most eight effect voices, uses Android's low-latency
SoundPool mode and preloads asset files. Repeated cues coalesce; subsequent
flaps and kills rotate takes; shots do not. Releases below 35% charge play
`shoot`, and stronger ones play `power_shot`. A full mixer admits a new cue only if a
lower-priority voice can be replaced, so shots cannot interrupt a boss roar or
death. Per-voice queues and cancellation revisions prevent stale native loads
from playing after mute, stop or disposal. Effects never request Android audio
focus and therefore do not silence music. A cue whose `SoundSpec` sets `duck`
lowers the music while it plays; see [Finish line cues](#finish-line-cues).

`CombatAudioCues` observes actual simulation outcomes, including monotonic
counters for projectile impacts, interceptions and enemy volleys. Counters do
not alter physics, randomness or replay data. Enemy disappearance at a screen
edge is silent. `BossAudioCues` follows encounter animation thresholds. Both
live play and replay use these observers; replay seeks update their snapshots
silently. Pickups and achievements retain their existing priority ordering.

`UiSounds` uses the app-owned audio instance so navigation does not cut off a
button's short tail. It respects the effects preference and app visibility.
Flight School now lets its completion cue finish while pausing music.

## Verification

Focused regression tests cover actual shots, kills, warnings, volleys,
interceptions, all three boss death sequences, seek suppression, sound
variation, priority under simultaneous combat, Android audio focus, queued
load cancellation and packaged PCM assets. Existing music transition tests
continue to run against the native-channel fake.

Validation on 2026-09-22: all 488 tests passed. After distinguishing star
pickups from combat score bonuses, all 24 affected UI/replay regression tests
also passed, and `flutter analyze --no-pub` reported no issues. The release APK
was built successfully; byte/hash checks confirmed all 58 effects and all three
music tracks match the prepared assets.

The release was installed on the connected Android phone. Native logs confirmed
SoundPool decoding and effect playback at the configured mix volumes during
menus and active touch gameplay, with no app audio errors. Native music checks
confirmed exactly one active looping track before and after the flight handoff.

The menu refinement replaces only `ui_tap`, `ui_back`, `ui_toggle`, `pause`
and `resume`: tuned harmonics, major-key confirmation intervals, softer attacks
and 270–430 ms tails. Hash checks confirmed that combat effects and music were
unchanged. All 17 affected audio/menu/button/settings tests passed.

### Shop screens

The Upgrades and crew screens reuse existing cues (`ShopCues` in
`lib/ui/ui_sounds.dart`); no new audio files. Pressing any key still clicks
`ui_tap`. On top of that:

| Moment | Cue |
| --- | --- |
| Looking at another socket or bird | `ui_toggle` |
| An upgrade level bought | `streak` |
| An upgrade's last level bought | `wing` |
| A bird unlocked with stars | `unlock` |
| Flying with another bird | `sprint_ready` |
| A greyed key pressed (not enough stars yet) | `ammo_empty` |

A cue plays once the purchase or choice has gone through, never when it fails.

The subsequent combat mix refinement lowers star playback from 0.28 to 0.10
(about 9 dB), and also reduces trio, perfect-gate and combo chimes. Shooting uses
one new ElevenLabs take with a deterministic midrange crack, a 240 ms tail,
priority 3 and playback volume 0.32. The unused second and third shot assets
were removed. Boss warning, reveal and roar use volumes 1.0, 0.90 and 0.88.
Their 350–2400 Hz presence and controlled peaks improve audibility on phone
speakers. All three still have -3.10 dBFS peak headroom before playback gain.

| Revised asset | RMS before playback gain | RMS after playback gain |
| --- | ---: | ---: |
| Shot | -13.50 dBFS | -23.40 dBFS |
| Boss warning | -11.78 dBFS | -11.78 dBFS |
| Boss reveal | -14.29 dBFS | -15.21 dBFS |
| Boss roar | -14.00 dBFS | -15.11 dBFS |

Asset hash checks confirm that only the shot and three boss entrance sounds
changed; the quieter pickup mix uses the existing assets at lower playback
volume. Other effects and all music assets are unchanged.

The mix revision passed all 18 affected audio/combat/cinematic tests and
`flutter analyze --no-pub`. The preparation report confirms every active effect
retains at least 3 dB of peak headroom, and only `shoot.wav` remains in the
packaged shooting family.

The revised APK was installed and launched successfully on Android. The phone
disconnected before the follow-up native volume check, so the revised levels
were verified from the mastered assets, playback configuration and automated
tests rather than new device telemetry.

Star pickups retain the original three rotating bell variants, now played at
volume 0.08 instead of 0.10. Live play, replay and Flight School treat the last
star in a trio as a normal pickup; trio completion plays no separate cue.

The follow-up balance adjustment reduces the fixed shot by 6.55 dB and raises
only the initial warning by 5.39 dB relative to that installed revision. The
warning's soft-knee mastering target is now -12 dBFS RMS; its peak remains
-3.10 dBFS. Hash checks confirm the warning is the only changed asset. All 18
affected audio/combat/cinematic tests and static analysis pass.

Power shots add three assets without changing existing ones. `power_shot`
replays the ElevenLabs shot take at 0.75× speed for a lower crack, adds a
deterministic 190 Hz falling body and plays at volume 0.38 with priority 3.
`shot_charged` (volume 0.22) and `ammo_empty` (volume 0.30) are original
syntheses; `CombatAudioCues` plays them once when a held charge reaches full
and on each dry fire.

| New asset | Duration | RMS before playback gain |
| --- | ---: | ---: |
| Power shot | 420 ms | -13.75 dBFS |
| Shot charged | 380 ms | -16.19 dBFS |
| Ammo empty | 200 ms | -17.20 dBFS |

All three keep -3.10 dBFS peaks. Hash checks against the previous release APK
confirm every earlier effect is byte-identical. The packaged-asset and combat
cue tests pass.

Sprint adds two original syntheses. `sprint` (volume 0.40, priority 3) layers
a rising noise rush over a soft impact. `sprint_ready` (volume 0.24) is a short
F5–C6–F6 bell. `CombatAudioCues` plays the rush once per accepted sprint and the bell
once when a used sprint recharges, never at flight start.

Each accepted sprint also starts one of four bundled bird voice clips. Selection
is random among the three clips other than the last one played. A dedicated
player prevents voice overlap, and pause, mute and replay seeking stop or
suppress the voice with the other effects.

Rush paths add four original syntheses:

| Cue | Volume | Priority | Length | Sound |
| --- | --- | --- | --- | --- |
| `sprint_ring` | 0.34 | 3 | 0.42 s | E6–B6–E7 ping over a light whoosh; three takes |
| `rubble_smash` | 0.46 | 3 | 0.40 s | Heavy impact, falling whoosh, debris clatter; three takes |
| `rush_alarm` | 0.60 | 4 | 1.3 s | Three A5–E5 stabs over a rumble |
| `rush_clear` | 0.48 | 4 | 1.1 s | C5–G6 run resolving on a warm C major chord |

`sprint_ring` takes 2 and 3 are one and two whole tones higher. The rubble takes
vary their seeded clatter. `CombatAudioCues` plays them as follows:
- `sprint_ring` for every ring. `SkyAudio.syncCombat` picks the take from the
  ring chain, so a chain climbs and holds at the third. The first ring of a
  chain also plays `sprint` and its voice.
- `rubble_smash` once per step in which any barrier breaks or a meteor is
  smashed.
- `rush_alarm` with each run's warning banner.
- `rush_clear` on each escape.

Regenerating the bank reproduced every earlier effect byte for byte. The
script used to overwrite `game_over.wav` with a plain synthesis. It now skips
that cue, which `tool/prepare_game_over.py` builds.

Eruption runs add `lava_burst` (volume 0.40, priority 2, 0.70 s, 150 ms
cooldown). It layers a heavy low impact, a high-passed hiss and a seven-grain
rock crumble. The two takes vary the seeds of all three layers.

Gales add `gust_warning` (volume 0.30, priority 3, 0.45 s, 120 ms cooldown): a
whistle gliding from C6 up a fifth, with a touch of its octave, over a falling
whoosh. `CombatAudioCues` plays it once per step in which a gust's warning goes
up. A gale reuses `rush_alarm` for its warning banner and `rush_clear` when it
is weathered.
`CombatAudioCues` plays it once per step in which any vent erupts. Swarm smashes
reuse `enemy_death`, which now plays when the enemies defeated plus the swarm
bats smashed rises. Regenerating the bank added `lava_burst.wav` and
`lava_burst_2.wav` and left every other asset unchanged.

| New asset | Duration | RMS before playback gain |
| --- | ---: | ---: |
| Sprint | 550 ms | -18.55 dBFS |
| Sprint ready | 450 ms | -15.16 dBFS |

Both keep -3.10 dBFS peaks. SHA-256 checks against the 22 September release APK
confirm that all 57 earlier effects are byte-identical.

The 2.98-second `game_over.wav` combines a comic "Oh no!" in the Scruffy
Duck voice with three varied low-piano hits about 0.58 seconds apart. Their
pitches descend, their tone darkens, and their decays overlap. Nine alternate
timbres are in `assets/audio/game_over_examples/`. It plays for
collision, tracking/posture loss, and stalled runs; the flight music pauses so
the cue is clear. Completing a run keeps the existing celebration cue.
The source generations are in the [ElevenLabs game-over flow](https://elevenlabs.io/app/flows/ReHuFoj4FSMRZVkcQtG6).
The active cue is rebuilt with `python3 tool/prepare_game_over.py`; its piano
section is boosted and soft limited without changing the voice level.

## New York cues (rules version 43)

Twenty-nine original syntheses (36 files, 2.76 MB of mono 44.1 kHz 16-bit PCM,
which takes the WAV bank from 5.67 MB to 8.42 MB) for the four New York
specials. They use no source take and no network, are built by new branches of
`synth()` in `tool/prepare_sound_effects.py` from the script's own helpers
plus the new ones below, and are reproducible byte for byte (two renders, with
different `PYTHONHASHSEED`, have identical SHA-256s; regenerating the 68
earlier effects that need no source take left all 85 earlier WAVs
byte-identical to the previous bank; the audio fix round re-rendered four of
the first delivery's 32 files and added four, see its own section at the end,
and left the other 28 and all 85 earlier WAVs byte-identical). The
designers' cue lists are `reports/02` to `reports/05` §4 of the New York
program; this is the finished, measured version.

**Nobody has listened to them.** They were checked only by measurement
(below) and by spectrogram. Audition the ones listed under "Audition first"
before shipping; every cue is one `synth()` branch and one `SoundSpec`, so
changing one is a local edit.

### Rendering

```sh
# one family
python3 tool/prepare_sound_effects.py --only pigeon_coo pigeon_flap pigeon_snatch pigeon_defeat star_rescue
python3 tool/prepare_sound_effects.py --only steam_hiss steam_burst pipe_clang steam_ride
python3 tool/prepare_sound_effects.py --only gargoyle_strike gargoyle_awaken beam_warning beam_sweep beam_spot lamp_vent lamp_glance feather_drop
python3 tool/prepare_sound_effects.py --only coo_roar coo_whistle crumb_throw crumb_splat squad_flutter coo_puff coo_pop coo_defeat
python3 tool/prepare_sound_effects.py --only coo_shout gargoyle_fury gargoyle_shatter coo_inflate   # the audio fix round

# measure: a table, eight-slice envelope and centroid per cue, f0 track for voices
python3 tool/check_sound_effects.py --family new_york --pitch
python3 tool/check_sound_effects.py --names dragon_inhale dragon_breath      # the references
python3 tool/check_sound_effects.py --family gargoyle --spectrograms build/sound-effects/spectrograms

# refresh or verify the SHA-256s in docs/sound-effects-sources.json after a re-render
python3 tool/check_sound_effects.py --update-sources
python3 tool/check_sound_effects.py --verify-sources
```

`--only` reads each cue's `seconds` and take count from `sound_bank.dart`, so
change the length there first; it writes `assets/audio/<name>.wav` (and
`<name>_2.wav` for a second take) and leaves the verification report alone.
The script's `NEW_YORK_CUES` list names the 29 cues (the three level aliases below have no WAV of their own and are skipped). `--only` needs no source
takes: none of these uses one. Because `synth()` falls back to a generic
whoosh for an unknown name, a misspelt cue renders silently wrong; the
asset test (`test/new_york_sound_assets_test.dart`) catches that.

### Seeds

Every random layer has its own `random.Random(seed)`; the seed ranges are
disjoint so no two cues share a noise stream. `+take` means the seed is
offset by the take number, so take 2 is a different noise from take 1.

| Family | Seeds | Used by |
| --- | --- | --- |
| Existing bank | up to 191 | unchanged |
| Steam Geysers | 201-249 | hiss 201, 210-214 (the five knocks); burst 221-230 (+take); clang 231-236 (+take); ride 241, 243 |
| Alley Pigeon | 251-299 | coo 251-256 (+take); flap 261-272 (+take); snatch 273, 277; defeat 281-286 (+take); rescue 291 |
| King Coo | 301-399 | roar 301-309; whistle 311, 313; throw 321-326; splat 331-338; flutter 341-349; puff 351, 353; pop 361-367; defeat 371-379; shout 381-387; inflate 391 |
| Searchlight Gargoyle | 401-499 | strike 401-407; awaken 411-415; warning 421-425; sweep 431-435; spot 441; vent 453, 455; glance 461-462 (+take); feather 471-474 (+take); fury 481-489; shatter 491-499 |

The Gargoyle report asked for seeds 201+; that range was already taken by
the steam and pigeon prototypes, so his are 401+.

### Cues, what fires them, and how they are mixed

`SoundSpec` is (volume, priority, seconds, cooldown ms, takes). Volumes were
set from the measurements below, not copied from the reports. Next to the
dragon the designers' figures were 2 to 5 dB too quiet for the pigeon's snatch
and flap, the Gargoyle's warning and sweep, King Coo's roar and defeat and the
steam hiss, and 2 to 4 dB too loud for the pea whistle (a pure 3 kHz tone) and
the pigeon's defeat.

| Cue | Spec | Fired by |
| --- | --- | --- |
| `pigeon_coo` | .30, 1, .55, 180, 2 | `FlightSimulation.pigeonWarnings` rises (each pigeon's 0.80 s warning) |
| `pigeon_flap` | .42, 1, .34, 80, 2 | `pigeonDives` rises |
| `pigeon_snatch` | .60, 3, .42, 120, 1 | `starsSnatched` rises (as `pigeon_snatch_lift` when a burst sounded within the last 0.3 s) |
| `pigeon_defeat` | .34, 2, .50, 65, 2 | `pigeonsDefeated` rises; `enemy_death` now counts `enemiesDefeated - pigeonsDefeated + swarmSmashed`, so a pigeon plays only this |
| `star_rescue` | .34, 3, .45, 100, 1 | `starsFreed` rises |
| `steam_hiss` | .40, 3, 1.50, 500, 1 | `steamHisses` rises: the 1.5 s warning (it ran 1.4 s, 0.1 s short of the burst) |
| `steam_burst` | .52, 3, .80, 250, 2 | `steamBursts` rises (as `steam_burst_duck` when a snatch is within 0.3 s, below) |
| `pipe_clang` | .26, 1, .45, 250, 2 | with every `steam_burst` (as `pipe_clang_duck` likewise) |
| `steam_ride` | .40, 2, .60, 400, 1 | `steamRides` rises |
| `gargoyle_strike` | .85, 4, 1.10, 1000, 1 | the reveal edge (boss age 1.65 s) of the Gargoyle, instead of `boss_reveal` |
| `gargoyle_awaken` | .85, 4, 2.00, 1000, 1 | the roar edge (2.65 s), instead of `boss_roar` |
| `beam_warning` | .65, 4, 1.50, 1000, 1 | `SkyBoss.sweepWarnings` rises (cycle second 2.0) |
| `beam_sweep` | .42, 3, 2.90, 1000, 1 | `sweepIgnitions` rises (3.5; it runs to the vent at 6.4) |
| `beam_spot` | .55, 3, .40, 400, 1 | `spots` rises (the bird is caught); the hurt itself is the usual `bump` or `shield_pop` |
| `lamp_vent` | .40, 3, 1.30, 1000, 1 | `lampOpens` rises (6.4) |
| `lamp_glance` | .30, 2, .25, 75, 2 | `lastGlanceAt` advances within 0.2 s (a rock off the shuttered lamp) |
| `feather_drop` | .28, 2, .55, 150, 2 | `feathersLaunched` rises |
| `coo_roar` | .95, 4, 1.60, 600, 1 | King Coo's fury edge, instead of `boss_enrage` (his arrival now has the shorter `coo_shout`) |
| `coo_whistle` | .30, 4, .85, 500, 1 | `SkyBoss.whistles` rises (the rules blow it at cycle second 9.2; a pop first cancels it) |
| `crumb_throw` | .40, 3, .36, 150, 1 | `lobsLaunched` rises |
| `crumb_splat` | .45, 3, .60, 150, 1 | `lobBursts` rises |
| `squad_flutter` | .42, 3, .95, 500, 1 | with every `coo_whistle` (its first 0.10 s is silence, so the flock lifts a beat after the blast), and again for a fury picket that follows its V by `SquadPlan.delay` |
| `coo_puff` | .42, 4, 1.50, 800, 1 | `puffs` rises (7.6) |
| `coo_pop` | .55, 4, .75, 400, 1 | `pops` rises |
| `coo_defeat` | .85, 4, 1.60, 1000, 1 | the defeat burst edge (0.85 s after the defeat), instead of `boss_burst` |
| `coo_shout` | .95, 4, .85, 600, 1 | King Coo's roar edge (2.65 s), instead of `boss_roar`: one shout cut to the 0.8 s his beak is open |
| `coo_inflate` | .45, 3, .75, 1000, 1 | King Coo's defeat at +0.12 s, the end of the hit-stop: the chest inflating until the pop at +0.85 s |
| `gargoyle_fury` | .45, 4, 1.20, 800, 1 | the Gargoyle's fury edge (hp <= 80), instead of `boss_enrage` |
| `gargoyle_shatter` | .45, 4, 1.20, 1000, 1 | the Gargoyle's burst edge (0.85 s after the defeat), instead of `boss_burst` |
| `steam_burst_duck`, `pipe_clang_duck`, `pigeon_snatch_lift` | .29 / .10 / .85 | other levels of `steam_burst` (-5 dB), `pipe_clang` (-8 dB) and `pigeon_snatch` (+3 dB): `SoundSpec.file` names the WAV they share |

Also new in the wiring:
- A King Coo ring lock (`lobsLocked` rises) plays the existing `boss_charge`
  as the wind-up before the toss.
- The generic boss cues still fire for the two new bosses: `boss_warning` at
  the start, `boss_hit`, `boss_break` at the defeat and `boss_victory`.
  `boss_reveal` is the Gargoyle's alone to replace (Coo keeps it, at 1.87 s:
  see the fix round); his fury is `gargoyle_fury` and his burst
  `gargoyle_shatter`; Coo's fury is `coo_roar`, his arrival `coo_shout`.
  The mini-bosses' `boss_victory` rings at 1.55 s, with their victory card.
- `enemy_charge` skips Alley Pigeons (their telegraph is the coo).
- A steam counter only sounds while a vent listed in `steamVents` is between
  `birdX - 0.1` and `birdX + 1.8` (report 03 §4); with no vent listed the
  counter is taken at its word.
- `steamScalds`, `steamClears` and `starsLost` have no cue: a scald is a hurt
  (`bump`/`shield_pop` from the hearts), a clear and a lost star are silent.
- Every counter and clock edge is silent on a seek, a rewind or a new run
  (the existing `silent` snapshots), muted effects play nothing, and pausing
  stops the cue that is playing (`stopEffects`).
- **Priority.** No new cue outranks a boss roar (`boss_roar` is priority 4):
  the mixer only steals a voice of strictly lower priority, so a full mixer
  of any New York cues never cuts a roar. The mini-bosses' own roars and
  telegraphs are priority 4, their sustained and incidental cues 1 to 3.

The rules counters named above were stubs in the scaffold when the cues were
wired, so the wiring is proved by `test/new_york_audio_cues_test.dart`,
which drives the counters and the boss clock directly, through
`CombatAudioCues`, `BossAudioCues` and a real `SkyAudio` on the Android host
fake (the rules have since landed, and `test/ny_merge_audio_test.dart` runs
the same cue classes against real flights). The rules must raise `pigeonsDefeated` for a King Coo squadron pigeon
too, and `enemiesDefeated` for every pigeon, or the squadron pigeons play the
bat's `enemy_death`.

### New helpers

All in `tool/prepare_sound_effects.py`, after `whistle`. The first four are
the prototypes' (moved from the designers' scripts, reseeded and tidied).

| Helper | What it makes |
| --- | --- |
| `coo_voice(data, at, length, hz_from, hz_to, gain, vibrato=6, roll=24, seed, bright=0)` | A pigeon's hooty voice: a fundamental, a .42 second and .12 third harmonic, exponential glide, slow vibrato (Hz), a throat roll that roughens the amplitude (Hz), a little breath. `bright` adds harmonics 4-10 through a vowel formant near 750 Hz so a deep voice still plays on a phone |
| `clap(data, at, gain, seed)` | A wing clap: noise band-limited to about 280 Hz - 1.7 kHz, a 20 ms decay and a 260 Hz thump |
| `tick(data, at, hz, gain)` | A beak tick: 6 ms of decaying sine |
| `puff(data, seed, start, seconds, gain)` | Feathers: swelling, thinning low-passed noise |
| `steam_noise(data, seed, start, seconds, gain, lp_from, lp_to, hp, attack, release, spit, spit_to)` | A steam hiss: noise between a high-pass knee and a sweeping low-pass (one-pole coefficients, larger is brighter), optionally gated at `spit` Hz rising to `spit_to` |
| `band_noise(data, seed, start, seconds, gain, hz, q, attack, release)` | Noise through two cascaded band-passes (12 dB/octave): a rustle with a colour |
| `clang(data, at, hz, gain, seed)` | An iron pipe struck: partials at 1, 2.32, 3.90 and 5.60 times `hz`, decays 9, 14, 22 and 34 a second, over a 2.5 ms noise tick |
| `updraft(data, seed, seconds, gain, f_from, f_to)` | A rising column of air: noise through a resonant band-pass sweeping `f_from` to `f_to` under a sine swell |
| `pea_whistle(data, at, length, hz, trill, depth, gain, seed)` | A police whistle: two reeds 130 Hz apart, AM trill, breath; steady pitch |
| `wing_claps(data, at, length, rate_from, rate_to, gain, seed)` | A flock taking off: claps whose rate rises then thins, each with its own centre frequency |
| `squeak(data, at, length, hz_from, hz_to, gain, tremor)` | Rubber under strain: a glide with tremor and a pinched third harmonic |
| `arc_buzz(data, seed, start, seconds, hz_from, hz_to, glide, gain, tremor, release, swell)` | A carbon-arc buzz: a saw whose harmonics fall as 1/k^.55 (up to 3.2 kHz), a smoothstep glide over `glide` seconds, a level flutter of `tremor` Hz, arc hiss |
| `stone_grind(data, seed, start, seconds, gain, lo, hi, rate, swell)` | Stone on stone: noise band-passed `lo`-`hi` Hz in irregular stick-slip gasps, `rate` a second |
| `crinkle(data, seed, start, seconds, count, gain, lo, hi)` | Crumbs, foil or chips: `count` grains of band-passed noise (12 ms each, a resonance in `lo`-`hi` Hz), louder early; mids a phone plays, unlike `crumble` |

`master()` gained an optional `dc_block` (on for every New York cue): the
soft knee and the fades leave a little offset, which it takes out and then
re-fades the edges. `main()` also gives `coo_roar`, `coo_shout`,
`gargoyle_awaken` and `gargoyle_fury` the boss roar's soft-knee target of
-14 dBFS RMS, `gargoyle_shatter` -15, `gargoyle_strike` -16 and the crumb
bombs -17. No earlier cue's code path changed, and `main()` skips a
`SoundSpec` that names a `file:` (an alias).

### Parameters, cue by cue

`lift` is a whole tone (x1.1225) for take 2. A time is `start s`; `(a->b)` is
an exponential glide in Hz. All the listed gains are before `master()`.

**Alley Pigeon**
- `pigeon_coo` (.55 s): three `coo_voice` (roll 26): 0 s .13 s (360->430)
  gain .22; .15 s .21 s (430->400) .30; .38 s .17 s (400->290) .24; all
  times `lift`.
- `pigeon_flap` (.34 s): four `clap` at 0, .075, .145, .21 s (+4 ms for take
  2) with gains .55, .47, .39, .28; `whoosh` .31 s gain .10.
- `pigeon_snatch` (.42 s): `clap` 0 s .55; `tick` .022 s 3400 Hz .30;
  `bell` 1318.51 Hz at .05 s .20 and 987.77 Hz at .14 s .18 (E6 then B5, the
  star chime backwards); `whistle` .04 s .22 s (1900->950) .05.
- `pigeon_defeat` (.50 s): `chirp` 0 s .09 s (1700->620) .30 and .10 s .07 s
  (1300->520) .18; `puff` .03 s .20 s .22; `impact` .14 s .22; `coo_voice`
  .22 s .22 s (330->240) .16; all pitches times `lift`.
- `star_rescue` (.45 s): `bell` 1567.98, 2093.0, 2637.02 Hz at 0, .06, .12 s
  gains .18, .15, .12; `whoosh` .27 s .07; `tick` .02 s 4200 Hz .12.

**Steam Geysers**
- `steam_hiss` (1.50 s): `steam_noise` 1.15, lp .22->.40, hp .10, attack
  .25, release .05, spit 6->15 Hz; six `clang` at .06, .50, .86, 1.12, 1.29,
  1.40 s (232, 246, 260, 274, 288, 302 Hz) gains .22, .28, .34, .40, .46, .52;
  the whole cue then scaled by `(t/1.5)^.7 * .8 + .2`.
- `steam_burst` (.80 s): `impact` .16 s .55 heavy; `steam_noise` 1.55, lp
  .48->.09, hp .10, attack .006, release .45; a second `steam_noise` at .03 s
  .44 s .55, lp .38->.20, hp .04, spit 23->9 Hz; `clang` .012 s 301 Hz .22
  (x1.07 for take 2).
- `pipe_clang` (.45 s): `clang` 0 s 392 Hz .55 and .11 s 329 Hz .32 (both x1.09
  for take 2); `impact` .08 s .18.
- `steam_ride` (.60 s): `updraft` 3.4 (420->2600 Hz); `whoosh` .48 s .05;
  `bell` 659.25 Hz at .05 s .60 and 987.77 Hz at .15 s .95 (both `warm`). The
  bells were raised from the report's .13/.11 because the E5 sat 6 dB above
  the updraft and the B5 2 dB below it (inaudible as a sparkle); now 18 and
  12 dB above it.

**Searchlight Gargoyle**
- `gargoyle_strike` (1.10 s): `boom` .75 at 70 Hz; `band_noise` 0 s .28 s
  1.4 at 2400 Hz (q .9) for the crack a phone can play; `crackle` 30 snaps
  over .66 s gain .30; `clang` .004 s 1046.5 Hz .10 (the rod).
- `gargoyle_awaken` (2.00 s): a layer of `growl` 38->55 Hz .30 (swell .3)
  and `stone_grind` .30 at 4.3 slips a second, shaped by a .12 s attack, full
  to .7 s, then falling at 1.9 e-folds a second; `crumble` 12 grains; three
  `bell` (466.16, 1286.6 and 2517.2 Hz, gains .15, .10, .06) at .30, .35,
  .40 s. The report put the bell partials "at 2.0 s"; the cue plays from the
  roar, so they are placed 0.3 s in.
- `beam_warning` (1.50 s): `impact` .12 s .40; `whistle` (120->360 Hz) .22
  with 6 Hz tremor and swell .9; `arc_buzz` (120->360, glide 1.5 s) .05,
  tremor 9, swell .85; `crackle` 34 snaps .12; `chirp` ticks from .20 s, the
  gap starting at .26 s and shrinking x.82 to a floor of .05 s, each .022 s
  (1500+900u -> 1000+500u Hz, gain .16+.14u, u the position in the cue).
- `beam_sweep` (2.90 s): `arc_buzz` 100->128 Hz, glide 1.8 s, gain .12,
  tremor 7 Hz, release .25 s; `crackle` 22 snaps .05 from .3 s; `whoosh`
  .7 s .10 (the ignition).
- `beam_spot` (.40 s): `impact` .12 s .30; `bell` 1567.98 Hz (G6) .40.
- `lamp_vent` (1.30 s): eleven `chirp` ticks .016 s at .02 + .028k s, falling
  (900-36k -> 820-32k-20 Hz) gain .30; `sea_noise` .10 s 1.10 s .40 (bright
  .03->.28); `whistle` .25 s .9 s (240->130) .05.
- `lamp_glance` (.25 s): `bell` 1320 Hz (x1.09 take 2) .28 and its 1.5
  multiple at .012 s .10; `impact` .05 s .25.
- `feather_drop` (.55 s): `band_noise` 0 s .385 s .9 at 3000 Hz (x1.1 take
  2), q 1.6; `tick` .004 s 950 Hz (x1.12) .35; `whoosh` descending .05.

**King Coo**
- `coo_roar` (1.60 s, now his fury's): `impact` .22 s .42 heavy; three `coo_voice` with
  `bright` 1.0: .06 s .36 s (150->196) .32, .46 s .34 s (198->168) .30, .86 s
  .70 s (168->104, vibrato 5) .34; `growl` 52->66 Hz .07 (swell .3).
- `coo_whistle` (.85 s): `pea_whistle` 0 s .11 s 2900 Hz trill 26; .12 s .66 s
  3000 Hz trill 30.
- `crumb_throw` (.36 s): `band_noise` 0 s .26 s .9 at 1700 Hz (q 1.0, attack .09,
  release .15); `impact` .08 s .22; `crinkle` 8 grains .11 s .23 s .30 (1.1-3.0 kHz).
- `crumb_splat` (.60 s): `impact` .12 s .30; `band_noise` 0 s .30 s 1.0 at
  1400 Hz (q .9, attack .004, release .25); `crinkle` 18 grains .05 s .50 s
  .28 (1.0-3.5 kHz).
- `squad_flutter` (.95 s): `wing_claps` .10 s .80 s rate 10->26 a second
  .26; three `coo_voice` at .12, .20, .28 s (260, 300, 340 Hz falling 20%)
  .07; `whoosh` descending .07.
- `coo_puff` (1.50 s): `whoosh` 1.38 s .24; `squeak` .10 s 1.15 s
  (240->560) .15; `impact` .09 s .22; `bell` 740 Hz at 1.28 s .10 (the creak).
- `coo_pop` (.75 s): `impact` .12 s .62; `whoosh` descending .36 s .22;
  `squeak` .06 s .45 s (1150->240, tremor 9) .22; `crumble` 6; `coo_voice`
  .49 s .22 s (320->250) .16.
- `coo_defeat` (1.60 s): `impact` .30 s .50 heavy; `whoosh` descending .5 s
  .18; a .9 s flutter of low-passed noise from .06 s; two `coo_voice` with
  `bright` .9: .55 s .42 s (210->150) .22 and 1.02 s .55 s (168->92, vibrato
  4.5) .22.

**Audio fix round**
- `coo_shout` (.85 s): `coo_voice` (`bright` 1.0) .03 s .36 s (168->205) .34 and
  .30 s .46 s (205->112, vibrato 5) .34, `growl` 54->62 Hz .07 (swell .2), all
  in a layer multiplied by the beak's own shape `sin(pi t / .8)^.6` and silent
  from .8 s; `impact` .22 s .40 heavy at 0 (the shock ring).
- `gargoyle_fury` (1.20 s): `impact` .22 s .50 heavy; `band_noise` 0 s .35 s
  1.3 at 2200 Hz; a layer of `stone_grind` (300-2000 Hz, 9 slips a second) .50
  and `arc_buzz` (140->230 Hz, glide .5 s, tremor 11) .14 at full to .4 s then
  falling 3.2 e-folds a second; `crackle` 26 snaps .22; three `bell` (466.16,
  1286.6, 2517.2 Hz) .22, .17, .11 at .10, .14, .18 s.
- `gargoyle_shatter` (1.20 s): `impact` .30 s .55 heavy; `band_noise` 0 s .30 s
  1.3 at 1800 Hz; `crackle` 44 snaps over .5 s .28; `crinkle` 26 grains .05 s
  .90 s .25 (1.2-4.2 kHz); three short `bell` (3136, 4186, 5274 Hz, .35 s) .10,
  .08, .06; `crumble` 14; `wing_claps` .45 s .65 s rate 10->22 .14.
- `coo_inflate` (.75 s): `updraft` 1.6 (500->2200 Hz); `squeak` (300->900,
  tremor 16) .20 and (450->1350, tremor 22) .10 from .15 s; four `tick` at .42,
  .54, .62, .68 s (1800, 1950, 2100, 2250 Hz) .16.

### Objective checks

`tool/check_sound_effects.py` (standard library only) measures what an ear
would notice. "Loudest 100 ms as played" is the loudest 100 ms RMS of the file
plus the `SoundSpec` volume, the figure to compare across cues (the dragon's
`dragon_inhale` and `dragon_breath` are the reference). The A-weighted column
is the same after IEC A-weighting: a phone speaker plays almost nothing under
250 Hz, so a cue heavy in the bass (the old `boss_roar`, `lava_burst`) is
quieter on a phone than its plain figure. The last column is the share of the
energy between 250 Hz and 8 kHz.

All 36 files are 1 channel, 16-bit, 44.1 kHz, exactly the length the sound
bank reserves, peak -3.10 dBFS (headroom 3.10 dB), **0 clipped samples**, and a
DC offset below 0.0002 of full scale; every one fades in over 2 ms and out
over 35 ms, so the first and last samples are below 0.02 and 0.005. Existing
cues for comparison:

| Asset | s | Peak | RMS | Loudest 100 ms as played | A-weighted loudest as played | 250 Hz - 8 kHz |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dragon_inhale` | 1.45 | -3.10 | -18.7 | -18.1 | -24.5 | 18% |
| `dragon_breath` | 1.60 | -3.10 | -18.7 | -17.9 | -23.8 | 55% |
| `boss_roar` | 1.35 | -3.10 | -14.0 | -10.4 | -24.4 | 1% |
| `boss_reveal` | 0.85 | -3.10 | -14.3 | -9.4 | -14.0 | 58% |
| `boss_warning` | 1.60 | -3.10 | -11.8 | -4.3 | -11.6 | 33% |
| `screech_warning` | 1.45 | -3.10 | -19.2 | -19.4 | -17.2 | 100% |
| `tide_warning` | 1.30 | -3.10 | -13.4 | -15.8 | -17.3 | 35% |
| `cannon_fire` | 0.90 | -3.10 | -19.4 | -16.4 | -26.8 | 14% |
| `lava_burst` | 0.70 | -3.10 | -22.8 | -22.8 | -32.8 | 7% |
| `rubble_smash` | 0.40 | -3.10 | -19.8 | -20.7 | -30.9 | 8% |
| `enemy_death` | 0.55 | -3.10 | -21.4 | -21.4 | -30.5 | 8% |
| `letter_lost` | 0.45 | -3.10 | -16.0 | -20.4 | -24.2 | 76% |
| `heart` | 0.75 | -3.10 | -15.9 | -18.9 | -18.0 | 100% |
| `shoot` | 0.24 | -3.10 | -13.5 | -22.5 | -22.2 | 83% |
| `rock_hit` | 0.20 | -3.10 | -17.6 | -27.6 | -35.1 | 16% |
| `boss_hit` | 0.22 | -3.10 | -18.4 | -24.4 | -26.8 | 63% |
| `boss_charge` | 0.60 | -3.10 | -18.4 | -24.6 | -26.7 | 37% |
| `boss_enrage` | 1.20 | -3.10 | -16.1 | -16.0 | -31.1 | 0% |
| `boss_break` | 0.85 | -3.10 | -21.6 | -19.1 | -29.8 | 12% |
| `boss_burst` | 1.20 | -3.10 | -18.1 | -14.2 | -22.7 | 6% |

New York's cues:

| Asset | s | Peak | RMS | Loudest 100 ms as played | A-weighted loudest as played | 250 Hz - 8 kHz |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `pigeon_coo` | 0.55 | -3.10 | -14.3 | -20.9 | -23.4 | 100% |
| `pigeon_coo_2` | 0.55 | -3.10 | -14.3 | -21.0 | -22.7 | 100% |
| `pigeon_flap` | 0.34 | -3.10 | -21.5 | -25.9 | -27.4 | 82% |
| `pigeon_flap_2` | 0.34 | -3.10 | -22.4 | -26.4 | -28.8 | 83% |
| `pigeon_snatch` | 0.42 | -3.10 | -20.7 | -21.2 | -20.7 | 98% |
| `pigeon_defeat` | 0.50 | -3.10 | -17.0 | -21.9 | -20.4 | 82% |
| `pigeon_defeat_2` | 0.50 | -3.10 | -18.4 | -23.4 | -21.6 | 82% |
| `star_rescue` | 0.45 | -3.10 | -16.0 | -21.0 | -19.7 | 100% |
| `steam_hiss` | 1.50 | -3.10 | -20.5 | -22.9 | -23.9 | 85% |
| `steam_burst` | 0.80 | -3.10 | -18.0 | -19.4 | -20.4 | 71% |
| `steam_burst_2` | 0.80 | -3.10 | -17.4 | -18.8 | -19.6 | 71% |
| `pipe_clang` | 0.45 | -3.10 | -18.7 | -25.7 | -28.3 | 98% |
| `pipe_clang_2` | 0.45 | -3.10 | -17.8 | -24.9 | -26.9 | 98% |
| `steam_ride` | 0.60 | -3.10 | -17.1 | -21.4 | -20.2 | 97% |
| `gargoyle_strike` | 1.10 | -3.10 | -15.9 | -9.1 | -14.4 | 30% |
| `gargoyle_awaken` | 2.00 | -3.10 | -13.9 | -10.9 | -12.2 | 35% |
| `beam_warning` | 1.50 | -3.10 | -20.0 | -18.7 | -20.6 | 66% |
| `beam_sweep` | 2.90 | -3.10 | -16.9 | -23.3 | -25.2 | 62% |
| `beam_spot` | 0.40 | -3.10 | -20.2 | -19.8 | -18.9 | 81% |
| `lamp_vent` | 1.30 | -3.10 | -18.9 | -21.4 | -21.4 | 87% |
| `lamp_glance` | 0.25 | -3.10 | -19.0 | -25.6 | -25.2 | 72% |
| `lamp_glance_2` | 0.25 | -3.10 | -18.8 | -25.4 | -24.8 | 72% |
| `feather_drop` | 0.55 | -3.10 | -19.3 | -25.9 | -24.7 | 98% |
| `feather_drop_2` | 0.55 | -3.10 | -19.7 | -26.4 | -25.2 | 98% |
| `coo_roar` | 1.60 | -3.10 | -13.8 | -12.1 | -14.4 | 70% |
| `coo_whistle` | 0.85 | -3.10 | -12.6 | -22.0 | -20.1 | 100% |
| `crumb_throw` | 0.36 | -3.10 | -15.9 | -20.7 | -18.9 | 84% |
| `crumb_splat` | 0.60 | -3.10 | -16.8 | -17.4 | -18.5 | 75% |
| `squad_flutter` | 0.95 | -3.10 | -18.2 | -21.0 | -26.0 | 74% |
| `coo_puff` | 1.50 | -3.10 | -13.9 | -18.1 | -20.6 | 95% |
| `coo_pop` | 0.75 | -3.10 | -18.1 | -18.5 | -22.6 | 71% |
| `coo_defeat` | 1.60 | -3.10 | -19.3 | -17.0 | -19.8 | 65% |
| `coo_shout` | 0.85 | -3.10 | -14.0 | -12.1 | -14.3 | 65% |
| `gargoyle_fury` | 1.20 | -3.10 | -13.3 | -16.3 | -15.7 | 78% |
| `gargoyle_shatter` | 1.20 | -3.10 | -14.5 | -13.0 | -15.4 | 60% |
| `coo_inflate` | 0.75 | -3.10 | -17.6 | -20.7 | -20.2 | 98% |
| `steam_burst_duck` | 0.80 | -3.10 | -18.0 | -24.4 | -25.4 | 71% |
| `steam_burst_duck_2` | 0.80 | -3.10 | -17.4 | -23.9 | -24.7 | 71% |
| `pipe_clang_duck` | 0.45 | -3.10 | -18.7 | -34.0 | -36.6 | 98% |
| `pipe_clang_duck_2` | 0.45 | -3.10 | -17.8 | -33.2 | -35.2 | 98% |
| `pigeon_snatch_lift` | 0.42 | -3.10 | -20.7 | -18.2 | -17.7 | 98% |

What the figures say:
- **Cinematic.** `gargoyle_strike` (-9.1), `gargoyle_awaken` (-10.9) and
  `coo_roar` (-12.1) stand with `boss_reveal` (-9.4) and `boss_roar` (-10.4);
  none is louder than `boss_reveal`. Their A-weighted figures (-14, -12, -14)
  beat the roar's (-24), because the roar is almost all bass.
- **Telegraphs and boss attacks** (`beam_warning` -18.7, `coo_puff` -18.1,
  `coo_pop` -18.5, `coo_defeat` -17.0, `steam_burst` -19.4, `lamp_vent` -21.4,
  `steam_hiss` -22.2, `coo_whistle` -21.9) lie within 6 dB of
  `dragon_breath` (-17.9) and `dragon_inhale` (-18.1). The whistle's pure 3 kHz
  tone is perceptually louder than its figure; it is at .30 for that reason.
- **Incidental** (`pigeon_coo` -20.9, `pigeon_flap` -25.9, `pipe_clang` -25.7,
  `lamp_glance` -25.6, `feather_drop` -25.9, `beam_sweep` -23.3) stay at or
  below the shot (-22.5) and the dragon.
- **Phone audibility.** The bass-heavy cues were given a mid-range voice:
  `coo_roar` 70% and `coo_defeat` 65% of their energy above 250 Hz (the
  report's versions: 12% and 13%), `gargoyle_awaken` 35% and
  `gargoyle_strike` 30% (their crack and bells; the thump is the rest).
  The crumb bombs were the thin ones (26% and 31%, the quietest cues on a
  phone, A-weighted -28.2 and -29.6 as played); the fix round rebuilt them in
  the mids (75% and 84%, -18.5 and -18.9). The generic boss cues keep their
  bass: `lava_burst` (7%), `enemy_death` (8%), `boss_break` (12%).

Envelope and colour, in eight equal slices of each cue (RMS in dBFS, spectral
centroid in Hz; a centroid computed on a linear frequency axis sits well above
a one-pole filter's cutoff, so compare rows, not cutoffs):

| Asset | RMS per eighth (dBFS) | Centroid per eighth (Hz) |
| --- | --- | --- |
| `pigeon_coo` | -15 -22 -13 -10 -15 -22 -12 -20 | 456 473 508 493 476 463 423 374 |
| `pigeon_flap` | -17 -20 -22 -19 -25 -23 -40 -65 | 3232 3342 3302 2644 2734 2986 2641 2095 |
| `pigeon_snatch` | -17 -17 -19 -20 -26 -33 -40 -48 | 2822 1460 1287 1115 1072 1091 1116 1142 |
| `pigeon_defeat` | -11 -16 -14 -29 -20 -21 -28 -68 | 1082 1182 1230 662 359 320 303 284 |
| `star_rescue` | -12 -12 -13 -18 -24 -30 -35 -43 | 1739 2078 2358 2278 2207 2129 2067 2004 |
| `steam_hiss` | -34 -29 -25 -24 -21 -21 -17 -16 | 1447 4934 3347 4791 3545 4821 2955 2317 |
| `steam_burst` | -14 -15 -16 -18 -21 -25 -31 -41 | 5430 6202 6000 5612 5183 4482 4300 3685 |
| `pipe_clang` | -13 -17 -17 -21 -26 -30 -35 -41 | 522 465 470 396 374 362 356 353 |
| `steam_ride` | -26 -22 -16 -14 -13 -15 -20 -33 | 720 904 1222 1507 1931 2243 2618 3157 |
| `gargoyle_strike` | -8 -14 -19 -25 -27 -33 -37 -41 | 951 1188 807 1273 2955 785 783 587 |
| `gargoyle_awaken` | -14 -10 -10 -13 -17 -19 -24 -26 | 1069 1109 1261 1008 718 1512 628 3040 |
| `beam_warning` | -18 -27 -24 -21 -22 -18 -18 -20 | 391 1293 859 786 1006 967 1031 1526 |
| `beam_sweep` | -17 -17 -16 -17 -16 -17 -17 -19 | 596 627 662 708 735 741 742 744 |
| `beam_spot` | -13 -18 -23 -28 -33 -38 -42 -50 | 1357 1374 1503 1568 1566 1564 1553 1526 |
| `lamp_vent` | -15 -14 -24 -22 -20 -25 -29 -45 | 822 621 867 1004 1067 1849 1557 2344 |
| `lamp_glance` | -12 -16 -23 -28 -32 -37 -42 -54 | 1123 1098 1444 1418 1411 1405 1399 0 |
| `feather_drop` | -16 -15 -16 -20 -25 -37 -54 -65 | 3656 3758 3742 3694 3751 3538 1025 1076 |
| `coo_roar` | -13 -14 -16 -15 -14 -12 -12 -15 | 538 600 608 601 617 611 619 625 |
| `coo_whistle` | -14 -12 -12 -12 -12 -12 -12 -25 | 2973 3076 3083 3083 3083 3083 3083 3084 |
| `crumb_throw` | -13 -13 -12 -16 -19 -24 -36 -27 | 692 1711 2306 2504 2626 2244 1510 3637 |
| `crumb_splat` | -10 -14 -18 -27 -26 -27 -37 -67 | 1279 1842 2014 2021 2738 4152 1560 5 |
| `squad_flutter` | -30 -18 -14 -14 -18 -24 -29 -33 | 6622 693 543 508 1053 3994 3595 7510 |
| `coo_puff` | -17 -15 -12 -11 -11 -14 -21 -30 | 393 482 591 677 743 756 844 764 |
| `coo_pop` | -13 -19 -16 -17 -19 -26 -25 -35 | 459 1032 857 800 613 356 513 1312 |
| `coo_defeat` | -18 -30 -28 -18 -21 -18 -16 -19 | 505 1938 815 611 610 613 614 597 |
| `coo_shout` | -14 -14 -14 -12 -12 -13 -17 -42 | 391 613 613 612 617 623 628 21 |
| `gargoyle_fury` | -10 -10 -11 -13 -17 -23 -36 -46 | 2640 2674 2868 3230 2958 2678 1029 1024 |
| `gargoyle_shatter` | -7 -13 -19 -21 -26 -21 -30 -50 | 2045 4531 6386 7365 4048 5386 4098 7966 |
| `coo_inflate` | -32 -22 -18 -14 -14 -15 -21 -34 | 612 927 1299 1498 1845 1980 2533 2880 |

The shapes are the ones the designers described: `steam_hiss` rises by 18 dB
from near silence; `steam_burst` peaks in its first 10 ms, falls 27 dB and
darkens from 6.2 to 3.7 kHz; `steam_ride` swells to the middle and its colour
rises from 0.7 to 3.2 kHz; `beam_warning` builds (from -27 to -18 dB after the
slam) with ticks closing from .26 s to .05 s apart; `beam_sweep` holds within
1 dB for 2.5 s; `gargoyle_strike` peaks at 0 s and falls 33 dB; `squad_flutter`
is silent for its first 0.1 s; `coo_whistle` is a short tweet and a long steady
3 kHz trill from 0.12 s; `coo_roar` has three voiced glides with breaths near
.42 and .82 s; `coo_shout` is one swell peaking at 0.3-0.5 s and shut by 0.8 s.

`test/new_york_sound_assets_test.dart` (78 tests) asserts all of this on
the packaged files: format, length, headroom, clipping, DC, edges, loudness
bands against the dragon, the boss roar and the boss reveal, the phone band,
and each cue's shape (pitches by FFT, onsets by RMS, slice trends). A re-render
that moves a cue out of its band fails it, which is the point: change the
band here and the table above together.

Findings the measurements caused (changes from the designers' prototypes):
- `clap` was a hiss (centroid 8.6 kHz, 23% in the phone band): band-limited
  to 280 Hz - 1.7 kHz (centroid 3 kHz, 82%).
- The steam hiss's iron knocks were 1-6 dB above the hiss in their band
  (inaudible as knocks): raised to 8-17 dB. The ride's bells were likewise
  masked by the updraft and were raised (see its parameters).
- `feather_drop` was white hiss (centroid 10 kHz): a true 3 kHz band-pass
  (3.7 kHz, 98% in the phone band).
- `coo_roar` and `coo_defeat` had 87-88% of their energy under 250 Hz: given
  the formant harmonics, then the roar's RMS target.
- `gargoyle_awaken` was a flat 2 s block: it now peaks, holds to .7 s and
  fades, with its grind slowed and made irregular.
- `beam_sweep`'s harmonics fell as 1/k (centroid 290 Hz, thin on a phone):
  1/k^.55 (700 Hz).
- `coo_roar` was 5 dB quieter than the boss roar at the designer's .55; now .95.

### Audition first

In this order; each line says what it should sound like, so a bad one is easy
to spot.
1. `coo_shout` (his arrival) and `coo_roar` (his fury): the shout is one fat,
   deep "COO-ROOO!" that swells and shuts with his beak in 0.85 s; the roar is
   the long three-step "COO... ROO... COOOOO" with breaths between, the last
   the longest and lowest. A giant pigeon, comic not scary. Bad: a goose, a
   brass honk, or a wail.
2. `pigeon_coo`: a soft, round "coo-ROO-oo" (a rise, a fuller hold, a fall).
   It plays every time a pigeon marks a star, so it must be charming after a
   hundred repeats. Bad: a ghost, an owl, a wobbling siren (the 6 Hz vibrato
   and the roll are the knobs).
3. `coo_whistle`: a short tweet and a long steady trilled pea-whistle blast
   that starts 0.12 s in. Bad: piercing or a screech; lower `volume` or `hz`.
4. `beam_sweep`: a steady electric buzz that warbles at 7 Hz and creeps up in
   pitch over 1.8 s, with a soft whoosh at the start and a few arc snaps. It
   runs 2.9 s in every 9 s of the fight. Bad: a bee, a razor, a fax machine.
5. `gargoyle_awaken` and `gargoyle_strike`: lightning (a bright crack, then
   thunder and arc snaps fading over a second) and a stone groan with grinding
   and falling rubble over ringing steel. They replace the reveal and roar;
   bad if they are louder or harsher than `boss_reveal`. Then his new
   `gargoyle_fury` (a stone crack, grinding roar and searing arc surge, steel
   ringing out; bad: a noise burst with no body, or louder than the awakening)
   and `gargoyle_shatter` (a crack, glass, chips, rubble, then wings).
6. The steam sequence together: `steam_hiss` (a thin hiss swelling over quickening
   iron knocks) into `steam_burst` with `pipe_clang` (a crack, a roaring jet that
   darkens, a bright iron clang) and `steam_ride` (a soft updraft with a two-note
   sparkle).
7. `beam_warning`: a shutter slam, then a hum that climbs with crackle and
   relay ticks closing up. It must read as "something is about to fire".
8. The rest: `pigeon_snatch` (clap, tick, two falling bells), `pigeon_defeat`,
   `star_rescue` (three rising bells), `squad_flutter` (a beat of quiet, then
   a flock taking off), `coo_puff`, `coo_inflate` (a squeak climbing and
   tightening to the pop), `coo_pop`, `coo_defeat`, `crumb_*` (a cloth swish,
   a thwup and a scatter of crumbs; a soft pop and patter: the bomb is the
   Commissioner's main attack, so these must now be easy to hear and still
   funny), `lamp_*`, `beam_spot`, `feather_drop`.

### Open points for the owner

- King Coo's fury plays `coo_roar` and his defeat `coo_defeat` (the cue table
  of report 05), although its reuse list also names `boss_enrage` and
  `boss_burst`. Both are one line each in `BossAudioCues` (`_fury`, the burst
  branch).
- Speech-free barks: the reports' barks (`gargoyle-spotted-*`, `coo-pop`,
  `gargoyle-fury`, `coo-fury`) are voice lines, so no extra SFX was made.
  `BossAudioCues` already has the edges a voice hook would use (`spots`,
  `pops`, fury).
- The rules must raise the counters named above as described; see the notes
  under the cue table.

### Audio fix round (reports/22-review-motion-audio.md)

An independent review measured every cue against its picture (120/60 Hz
pose dumps, the real cue classes in real flights) and scored audio sync 7/10.
What it found, what changed, and what did not.

**Cue time against picture** (boss age, seconds; the offsets the real rules
produce, printed by `king_coo_staging_test` and pinned by it and by
`gargoyle_staging_test`):

| Beat | Picture | Cue before | Cue now |
| --- | --- | --- | --- |
| King Coo's reveal | flash at 1.9 s (colour 1.92-1.99) | `boss_reveal` at 1.65 s: 0.25 s early | 1.87 s (measured 1.878): rings 0.02-0.03 s ahead of the flash |
| The dragon's reveal | flash at 1.9 s (`dragon_encounter_ui` pulses `age - 1.9`) | `boss_reveal` at 1.65 s: 0.25 s early | 1.87 s. One line, `BossAudioCues._revealAt`, shared by both; the other bosses keep 1.65 s, where their reveal ramp begins |
| King Coo's arrival COO! | beak opens 2.65, widest 3.05, shut 3.45 (`sin` over 0.8 s); shock ring at 2.65 | `coo_roar`: three notes over 1.6 s, the longest and loudest (3.53-4.23 s) with the beak shut; correlation of its loudness with the beak -0.1 | `coo_shout`, 0.85 s: one swell peaking at 0.3-0.5 s, shut by 0.8 s, thump with the shock ring; correlation with the beak 0.95 (from 0.1 s). `coo_roar` is kept for his fury, where the beak is held open for 1.6 s |
| The Gargoyle's fury | roar throws +0.12 to +0.30 s, holds to +0.60 | generic `boss_enrage`: peaks +0.20-0.32 s but 0.2% of its energy in the phone band | `gargoyle_fury`: loud from +0.1 s, peak at +0.28 s, held to 0.4 s |
| Mini-bosses' victory card | begins at 1.55 s after the last blow | `boss_victory` at 1.8 s: 0.25 s after | 1.55 s for the two mini-bosses; the five chapter bosses keep 1.8 s |
| `squad_flutter` | pigeons come out from behind King Coo about 0.10 s after the blast | on the whistle's tick | unchanged: the file is silent for its first 0.10 s, the claps start at 0.10 s and peak at +0.37 s, so the +0.10 s that the K8 hand-off recommends is already in the audio (adding it again would put the flock 0.22 s behind) |
| `coo_whistle` | blast pose lasts 0.4 s from the whistle | the long trill started at 0.30 s, after the blast peaked, and ran to 0.94 s | tweet 0-0.11 s, long trill from 0.12 s to 0.78 s; the cue is 0.85 s (was 1.0 s) |
| `steam_hiss` | the hiss phase is 1.5 s, to the burst | 1.4 s: 0.1 s of silence before the burst | 1.5 s |
| `crumb_throw` | the bomb leaves the wing tip within 0.12 s of the cue | on the launch tick | unchanged (K8's optional "0.14 s earlier" would only help if the file opened with its swish; it now opens with the swish at 0 s and the thwup at 0.08 s) |

**Beats a phone used to lose.** A phone speaker plays almost nothing under
250 Hz, so the A-weighted level as played is what a player hears. The review's
figures (and the fixes), against a rock hit (`boss_hit` -26.8) and a shot
(`shoot` -22.2):

| Beat | Before (A-weighted as played, share of energy in 250 Hz-8 kHz) | Now |
| --- | --- | --- |
| Gargoyle fury | `boss_enrage` -31.1, 0.2% (at +0.12 s: -35.8) | `gargoyle_fury` -15.7, 78% (at +0.12-0.22 s: -16.6) |
| Gargoyle death | `boss_burst` -22.7, 6% (no louder than a shot) | `gargoyle_shatter` -15.4, 60% |
| King Coo's inflate (death +0.12 s to the pop) | near silence | `coo_inflate` -20.2, 98% |
| `crumb_throw` | -29.6, 31% | -18.9, 84% |
| `crumb_splat` | -28.2, 26% | -18.5, 75% |

The review asked for the crumb volumes to go up to .75-.80 on the old files.
The new files carry far more mid-band energy (and a soft-knee RMS target of
-17), so at .80 and .75 they would have measured -12.9 and -14.1 A-weighted, as
loud as the Gargoyle's awakening; their volumes went to .40 and .45 instead,
where they sit with `coo_whistle` (-20.1) and `coo_puff` (-20.6). `boss_break` (-29.8, 12%) and `boss_charge` (-26.7,
the wind-up of every bomb) are the shared generic cues and are unchanged; the
kill beats are now carried by `coo_inflate`, `coo_defeat` and
`gargoyle_shatter`, and `boss_victory` (-18.5) was already audible. The
tests that pin all of this are in the "beats a phone used to lose" group of
`new_york_sound_assets_test.dart`.

**A steam burst and a snatch together.** At 18.900 s the review heard a vent's
burst and clang and, 33 ms later, a pigeon's snatch, both about -20.5 dB
A-weighted: the burst's 5-6 kHz hiss hides the snatch's 2.8 kHz onset. The cue
layer (`CombatAudioCues`, no change to `SkyAudio`) now ducks the burst and its
clang by 5 and 8 dB when a snatch or a rescued star lands at the same step or
within 0.3 s before it, and lifts a snatch by 3 dB when a burst sounded within
0.3 s before it. The ducked and lifted levels are `SoundSpec`s that name the
same WAVs (`steam_burst_duck`, `pipe_clang_duck`, `pigeon_snatch_lift`;
`SoundSpec.file`), so no audio is duplicated; a seek, a rewind or a new
flight forgets the last snatch and burst. Level data should still keep a dive
more than 0.5 s away from a burst (the review's note for the level owner).

**Changed files, deliberately.** New: `coo_shout.wav`, `gargoyle_fury.wav`,
`gargoyle_shatter.wav`, `coo_inflate.wav`. Re-rendered: `crumb_throw.wav`,
`crumb_splat.wav`, `coo_whistle.wav`, `steam_hiss.wav`. Every other WAV is
byte-identical to the first delivery. Evidence: spectrogram sheets of all
eight in the delivery's `evidence/`.

**Not changed, for the owner.** The `coo_roar` fury cue keeps its beak-shut
risk if the art later closes the beak during fury; the Gargoyle's `boss_break`
at the hit-stop is still the generic bass thump; the stress player's 8/8
voices (only `flap`, priority 0, is dropped) and Coo's whistle plus five
squadron kills (flap dropped twice) are left to the mixer's existing priority
rule; the K8/G8 "optional" sounds with no cue (his desertion pigeons at
death +1.07 s, the cap landing at +1.45 s, the Gargoyle's tower sliding in,
the pigeon flush, the rubble settling) were not made.

## Finish line cues

Four cues for the campaign finish line, 0.48 MB of mono 44.1 kHz 16-bit PCM
(the WAV bank goes from 8.42 MB to 8.90 MB). Times are from the moment the
bird crosses the line (t = 0); the flight's controller plays them.

| Cue | Beat | Spec (volume, priority, s, cooldown ms) | How it was made |
| --- | --- | --- | --- |
| `finish_near` | t = -2.6 s, the gate's lights flick on and chase | .30, 3, 1.45, 1000 | Synthesis: a harp glissando (`pluck`) up the G major pentatonic, G4 to D6 in 0.52 s, glockenspiel (`bell`) on its last three notes and a D6 struck again at .70 and .86 s, over a shaker (`shaker`, 2.5-9 kHz grains quickening 14 to 22 a second) that swells from silence to 1.2 s and is let go. G is the dominant of the C major `complete` fanfare, so it ends open and the crossing resolves it |
| `finish_snap` | t = 0 (the picture's tape snaps and cannons fire at 0.075 s, after the hit-stop) | .45, 4, .90, 1000 | ElevenLabs take `finish_snap_tape.mp3`: its snap peaks 13 ms in, high-passed at 180 Hz, its long ribbon ring let go from .20 to .50 s. Added: a 398 Hz `twang` that springs down 12% and wobbles at 13 Hz; two `popper`s (cap crack, paper-tube pop near 1.5 and 1.25 kHz, small thump) at 40 and 90 ms; confetti (`crinkle` 90 grains at 1.8-6 kHz plus a 3.5 kHz `band_noise`) from 0.09 s, thinning out with a 0.3 s decay. Soft-knee RMS target -19 dB, so the one sharp crack does not set the level of the rest |
| `finish_cheer` | t = 0.12 s | .28, 4, 2.30, 1000, **duck .45** | ElevenLabs take `finish_cheer.mp3`: a few birds chirping in waves (bursts at 0, .38-.66, .88-1.08, 1.56-1.84 s) over a 2.4-4.5 kHz whistle line. Added: a whistled "wheet-whoo" (`tweet`, 1.9 to 2.8 kHz then 2.6 to 1.7 kHz) in the gap at .11-.41 s and another bird's, higher, at .70-.99 s. Full for 0.9 s, then a cosine fade to silence at 2.3 s (6 dB down at 1.6 s, where the bird lands) |
| `finish_swoop` | t = 1.15 s, the bird swoops to the result cloud (lands at 1.70 s) | .45, 3, .75, 1000 | Synthesis: air rushing closer (`swoop_air`, a resonant band-pass climbing 380 Hz to 2.2 kHz, swelling to .52 s), then the landing (`fwump` at .55 s: a 6 ms rounded attack, an 85 Hz cushion and a 500 Hz "poof" a phone can play) and a little cloud `puff` |

The prompts, generation IDs, settings and source hashes of the takes, and of
the four rejected ones, are in
[sound-effects-sources.json](sound-effects-sources.json) (`sources`, and the
`finish_line` group under `synthesised` for the specs and the mastered files).
Six generations were made: the tape snap (used); a party-popper take (dull and
truncated, so the poppers and confetti are synthesised); two cheers that were
one continuous warbling whistle each; and two of a second prompt, of which the
one that is loudest at the start and leaves gaps for a spoken line is used.
`finish_snap` and `finish_cheer` need the takes in
`build/sound-effects/source/` (`finish_snap_tape.mp3`, `finish_cheer.mp3`);
without them the script stops rather than synthesise a stand-in. Seeds are
501-549.

```sh
python3 tool/prepare_sound_effects.py --only finish_near finish_snap finish_cheer finish_swoop
python3 tool/check_sound_effects.py --family finish        # the first five rows below
python3 tool/check_sound_effects.py --verify-sources       # the hashes
```

Two renders (with different `PYTHONHASHSEED`) are byte-identical, and
re-rendering every other cue that needs no source take left all 104 earlier
WAVs byte-identical.

**`complete` is unchanged.** Its first note (C5) reaches -20 dB of the file's
peak within 1.2 ms and full level by 5 ms, with no leading silence, so it
speaks on the beat at t = 0.40 s. Its C major arpeggio is what `finish_near`
leaves open, and the cheer's chirps and whistles sit at 1.7-4.5 kHz, above its
523-1319 Hz notes.

**Ducking.** `SoundSpec.duck` is the music's level, as a multiple of its usual
level, while the cue plays (null leaves the music alone). `SkyAudio` lowers the
music when such a cue is accepted. When the cue's `seconds` have passed (at
the playback rate) the music swells back in five equal steps in decibels over
0.6 s, about 1.4 dB a step for .45, rather than jumping. A later ducking cue
extends the duck, at the deeper of the two levels, or cuts a swell short. It
multiplies with the speech duck and the boss cinematic level in `_syncMusic`,
and `stopEffects`, `stop`, turning effects off and `dispose` cancel it (the
music returns to full at once). Only `finish_cheer` uses it (.45: the flight
music from .70 to .315, and to .19 if the bird's line at the crossing is said
with `SkyAudio.flightDuck`). The swell runs from t = 2.42 s to 3.02 s, under
the result card's star chimes.

| Asset | s | Peak | RMS | Loudest 100 ms as played | A-weighted loudest as played | 250 Hz - 8 kHz |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `finish_near` | 1.45 | -3.10 | -18.0 | -23.1 | -22.6 | 99% |
| `finish_snap` | 0.90 | -3.10 | -18.7 | -17.8 | -17.3 | 71% |
| `finish_cheer` | 2.30 | -3.10 | -20.5 | -24.5 | -21.1 | 100% |
| `complete` | 1.20 | -3.10 | -16.5 | -19.8 | -19.2 | 100% |
| `finish_swoop` | 0.75 | -3.10 | -22.2 | -21.9 | -22.4 | 77% |
| `wing` | 0.80 | -3.10 | -16.6 | -20.5 | -18.9 | 100% |
| `final_stretch` | 0.65 | -3.10 | -16.5 | -19.8 | -19.2 | 100% |
| `unlock` | 1.20 | -3.10 | -16.0 | -19.1 | -19.0 | 99% |
| `star` | 0.28 | -3.10 | -16.3 | -34.7 | -33.8 | 100% |

| Asset | RMS per eighth (dBFS) | Centroid per eighth (Hz) |
| --- | --- | --- |
| `finish_near` | -19 -16 -14 -14 -21 -25 -28 -36 | 525 656 1003 1131 1228 2618 4690 1086 |
| `finish_snap` | -11 -18 -22 -26 -31 -35 -37 -64 | 3260 4350 5770 5528 5345 5079 6275 4500 |
| `finish_cheer` | -19 -21 -18 -17 -24 -24 -25 -48 | 3573 2786 2568 3209 4085 2555 2585 5607 |
| `finish_swoop` | -65 -48 -38 -30 -24 -19 -16 -26 | 848 1516 1821 2200 3003 2183 1313 1535 |

What the figures say: the sting is the quietest, 3 dB under the milestone
chimes, so it sits under the region music rather than over it. The snap is the
loudest beat of the sequence, 2 dB over the fanfare; the cheer is 2 dB under
the fanfare and in a higher band. Mixed on the timeline at their volumes (no
music), the cheer is 11 dB under the swoop's fwump when the bird lands at
1.70 s, more than 25 dB down by 2.0 s and silent by 2.2 s, before the first
star chime at 2.35 s.

**Nobody has listened to them.** Audition in this order: the snap (a crisp
ribbon snap, pop-pop, then paper; bad: a gunshot or a hiss), the cheer under a
crossing line (bright small birds, not a crowd and not a siren; if it masks
the line, lower its volume or `duck`), the sting over a region song (bad: an
alarm), then the swoop.

## Egypt cues (rules version 50)

Thirteen cues (13 files, 1.22 MB of mono 44.1 kHz 16-bit PCM) for Neferhoo,
the Mummy Courier who ends level 2-6 "Return to Sender", and one alias level
(`wrap_scuff_duck`, no file of its own). **Since 2026-10-04 they are made from
ElevenLabs takes**: the owner asked for his sounds from ElevenLabs.
`eleven_text_to_sound_v2` recorded four takes of each cue (flow
https://elevenlabs.io/app/flows/fxNpEkVOAm49dMvjGLj0, 52 takes), then four
takes each of four single-sound layers (a mask clang, a paper flurry, a temple
gong and one bell note, 16 takes) for the cues no take got right. About 825
credits in all. `egypt_take()` in `tool/prepare_sound_effects.py` cuts each
picked take to the bank's length and, where the picture needs it, re-times or
layers it (table below). Prompts, generation ids, hashes, what each pick is
used for and why each other take lost are under `sources.<cue>` in
[sound-effects-sources.json](sound-effects-sources.json).

They replaced thirteen original syntheses (designed in
`egypt-ws/reports/01-egypt-guardian.md` section 6, prototyped by
`proof/mummy_cues_prototype.py`). Those still render byte for byte with
`--egypt-synth`, so any cue can go back to its synthesis. Seeds, helpers and
parameters are kept below.

**Nobody has listened to them.** The takes were picked by measurement:
envelope, onsets, f0, spectrogram and phone band (the scripts are in
`egypt-int/sfx-el/`, outside the repo). The ones to audition first are under
"Audition first".

### Rendering

```sh
python3 tool/prepare_sound_effects.py --only hoopoe_roar sand_devil mail_call letter_flick letter_return postage_due wrap_scuff ankh_raise ankh_whir ankh_catch mummy_fury mask_pop lost_letter

# the original syntheses instead (all 13, or name just the cues to revert)
python3 tool/prepare_sound_effects.py --egypt-synth --only hoopoe_roar sand_devil mail_call letter_flick letter_return postage_due wrap_scuff ankh_raise ankh_whir ankh_catch mummy_fury mask_pop lost_letter

# measure: a table, eight-slice envelope and centroid per cue, f0 track for the voices
python3 tool/check_sound_effects.py --family egypt --pitch
python3 tool/check_sound_effects.py --family egypt --spectrograms build/sound-effects/spectrograms

# refresh or verify the SHA-256s in docs/sound-effects-sources.json after a re-render
python3 tool/check_sound_effects.py --update-sources
python3 tool/check_sound_effects.py --verify-sources
```

The picked takes are read from ignored `build/sound-effects/source/egypt/`,
under the names in `EGYPT_TAKES` and `EGYPT_LAYERS`. A missing take stops the
render rather than falling back to the synthesis. All 68 takes, both
manifests, the measurements and the spectrograms are also kept in
`egypt-int/sfx-el/` (`takes/`, `manifest.json`, `manifest-layers.json`). To
try another take, copy it into the source folder, change its name in
`EGYPT_TAKES` and re-render. `--only` reads each cue's length from
`sound_bank.dart` (change it there first). `EGYPT_CUES` in the script names
the 13 (`master(dc_block=True)` for each). `test/neferhoo_audio_test.dart`
checks that every cue names a take and still has its synthesis branch.

### The takes

| Cue | Take | What it is | What `egypt_take()` does |
| --- | --- | --- | --- |
| `hoopoe_roar` | `hoopoe_roar-1` | three hollow hoots near 390 Hz, .28 s apart | cuts each to .15 s and starts them at .02, .17 and .32 s (`ROAR_HOOTS` onto `ROAR_NOTES`: the beak's pulses), the last with its tail; `temple_gong-1` from .32 s at .35 of the call's peak; soft-knee -15 |
| `sand_devil` | `sand_devil-4` | a gritty swirl swelling to .32 s, fading by 1.5 s | the first 1.6 s |
| `mail_call` | `mail_call-2` | a satchel thump, a rustle, then a rising ladder of chimes from .3 s | the first 1.0 s, high-pass 150 Hz, soft-knee -19 |
| `letter_flick` | `letter_flick-3` | a swish into a paper snap | the snap with .03 s before it (`excerpt()`'s transient mode) |
| `letter_return` | `letter_return-2` | a stamp thunk whose pitch bends up (the boing) | as it is |
| `postage_due` | `postage_due-3` | a double stamp hit ("ka-chunk") with bell partials ringing to .4 s | soft-knee -15 |
| `wrap_scuff` | `wrap_scuff-3` | one short cloth slap | the first .16 s, soft-knee -18 |
| `ankh_raise` | `ankh_raise-1` | a hum under a rising ladder of chimes | high-pass 200 Hz |
| `ankh_whir` | `ankh_whir-4` | a chopped whir, about four turns a second, level to 2.3 s | high-pass 220 Hz (its sub-bass left 10 % in the phone band) |
| `ankh_catch` | `ankh_catch-4` | a gold clink over a low thump | soft-knee -18 |
| `mummy_fury` | `mummy_fury-4` | three rough cries, a gap, a short cry | moves the second phrase from .745 s to .60 s (`FURY_JOIN`), where the beak opens again; `temple_gong-1` from .60 s at .3 of the peak |
| `mask_pop` | `mask_clang-3` | a bright brass clang | `paper_flurry-4` from .06 s at .5 of the clang's peak; soft-knee -19 |
| `lost_letter` | `bell_note-1` | one near-pure 831.7 Hz tone (`BELL_HZ`) | plays it at C5, E5, G5 and C6, .16 s apart (`LOST_LETTER_NOTES`), each dying away over about .4 s |

Every one ends in a cosine fade over its last fifth (at most .25 s). The
`mask_pop` and `lost_letter` nodes' own takes are unused. No take of the
first had both a clang and paper; the second's were a hiss, a sparkle and one
pulsing note. So both were re-recorded as layers.

### Seeds (the syntheses)

Seeds 501-619 (New York used up to 499). One `random.Random(seed)` per random
layer, never shared between Egypt's cues. The finish line's cues (above),
built at the same time, also took 501-549; a seed only seeds one layer's
noise, so a number both use repeats a noise texture and nothing else (the
WAVs were made and measured separately and stay byte-identical):

| Cue | Seeds |
| --- | --- |
| `hoopoe_roar` | 501 thump; 503-505 the three hoots; 507 sand |
| `sand_devil` | 511 updraft; 513 crackle; 515 papers |
| `mail_call` | 521 thump; 523 papyrus |
| `letter_flick` | 531, 533 |
| `letter_return` | 541 thunk; 543 paper tick |
| `postage_due` | 551, 553 thumps; 554 slap; 555 paper burst |
| `wrap_scuff` | 561 |
| `ankh_raise` | 571 hum |
| `ankh_whir` | 581, 583 (out and back) |
| `ankh_catch` | 591 |
| `mummy_fury` | 601 linen; 603, 604 the two calls |
| `mask_pop` | 611 clang; 613 thump; 615 unravelling; 617 paper; 619 hoot |
| `lost_letter` | none (four bells) |

### Cues, what fires them, and how they are mixed

`SoundSpec` is (volume, priority, seconds, cooldown ms); all one take. The
volumes are the design's except `hoopoe_roar` (below).

| Cue | Spec | Fired by |
| --- | --- | --- |
| `hoopoe_roar` | .65, 4, 1.40, 600 | the arrival's roar edge (boss age 2.65 s) in place of `boss_roar`, and the full fight's stage-up (a 1.4 s roar), through `BossAudioCues` |
| `sand_devil` | .40, 3, 1.60, 1000 | boss age 0.1 s of the arrival (a first frame up to 0.6 s still rings it once) |
| `mail_call` | .40, 3, 1.00, 500 | `NeferhooFight.mailLockedAt` rises (cycle second 0.6; it rings out as the first letter leaves) |
| `letter_flick` | .30, 2, .25, 120 | each letter whose `releaseAt` has come while he attacks (1.6 s, then .40 s apart; fury .32 s) |
| `letter_return` | .45, 3, .40, 100 | `lettersReturned` rises (a rock catches a letter; a bulk return of several is one cue) |
| `postage_due` | .70, 4, .70, 150 | `returnsLanded` rises (a returned letter lands for 25): the payoff, the loudest thing he does |
| `postage_due_duck` | .28, 4, .70, 150 | the same file, 8 dB lower, when the landing falls in the frame of his `hoopoe_roar` or `mummy_fury` (a landing is what usually crosses a third), so the cry reads over the jackpot (M1's fix round) |
| `wrap_scuff` | .22, 1, .16, 80 | `wrapScuffs` rises (a rock on the wraps) |
| `wrap_scuff_duck` | .11, 1, .16, 80 | the same file, 6 dB lower, when the scuff is in the same frame as a postage due or within 0.25 s after it (`SoundSpec.file`, as the steam burst ducks under a snatch) |
| `ankh_raise` | .40, 3, 1.40, 1000 | `ankhLockedAt` rises (cycle second 5.4; 1.4 s long, the wait to the throw) |
| `ankh_whir` | .35, 2, 2.60, 2000 | each ankh whose `thrownAt` has come while he attacks (6.8 s). Fury's second ankh is thrown 0.5 s later: the 2 s cooldown makes the pair share one whir |
| `ankh_catch` | .40, 3, .35, 300 | `ankhCatches` rises (an ankh home; fury sounds two) |
| `mummy_fury` | .55, 4, 1.30, 1000 | the fury edge (`hp * 3 <= maxHp`) in place of `boss_enrage`. The rules raise the stage a step after the blow that crossed it; the shared chain no longer roars at that stage-up when the boss is already furious (it rang `hoopoe_roar` 20 ms after the cry at 864 px; M1's fix round) |
| `mask_pop` | .60, 4, 1.30, 1000 | the burst edge (0.85 s after the defeat) in place of `boss_burst` |
| `lost_letter` | .45, 3, 1.40, 1000 | 3.2 s after the defeat, once `boss_victory` (1.55 s + 1.65 s) has rung out; the lost letter flares then (M1's fix round: the two stingers started .05 s apart and overlapped 1.4 s) |

The generic cues that still ring for him: `boss_warning` as he starts,
`boss_reveal` at 1.65 s (the picture's flash), `boss_break` at the defeat and
`boss_victory` at 1.55 s with his victory card. Never `boss_hit` (the owner's
call, taken by the orchestrator in M1's fix round: a rock on his padded wraps
is only the small `wrap_scuff`, deliberately small; a letter home only the
loud `postage_due`).

**What a cue reads.** `NeferhooAudioCues` (`lib/game/neferhoo_audio_cues.dart`,
advanced by `BossAudioCues` once a frame) follows the boss's latches and sounds
only a rise, exactly once. The two locks are the latches `mailLockedAt` and
`ankhLockedAt`, which the rules set only when a lock really happens: in the
warm-up the ankh's cycle goes by with no lock and no sound (a cue never keys
on "a hazard exists"). Letters and throws are counted from the lists the rules
fill, by the time each leaves his hand (the instant the picture draws it), and
only while he attacks, so a defeat that leaves a letter or an ankh unreleased
never plays it. The returned, landed, scuffed and caught counters are the
rules' own (`lettersReturned`, `returnsLanded`, `wrapScuffs`, `ankhCatches`).
A seek, a rewind (the shared age going backwards) and a new boss only follow
the state, so a replay's scrubbing is silent and an edge passed again after a
rewind is heard again; with Sound effects off nothing loads and no edge waits.
**Character voices** is a different setting (the recorded voices): his sound
effects do not depend on it.

**The open-sky gag** (the wing buffing his pad, 10-12 s of the cycle) is art
only and silent: it is not among the design's 13 cues. A squeak and a
shine would be one more `synth()` branch (`squeak`, `bell`) and one edge on
`gagStart`.

**The roar against the picture.** The picture pulses his beak at 2.65, 2.80
and 2.95 s of the arrival, .15 s each (`syllables` in the design's
`mummy_present_cine.dart`), and the cue starts at 2.65 s. The ElevenLabs
take's three hoots are .28 s apart (at 0, .26 and .555 s), nearly twice as
slow as the beak. `egypt_take()` cuts each to .15 s (`ROAR_HOOTS`) and starts
them at .02, .17 and .32 s (`ROAR_NOTES`), so each hoot peaks with its pulse
(.06-.10, .22-.26 and .36-.40 s); the last keeps its tail, and the gong rings
out from .32 s. If the art retimes the syllables, `ROAR_NOTES` is the only
edit. (The synthesis, `--egypt-synth`, sings its own hoots at the same
`ROAR_NOTES` times; the design's prototype had them .34 s apart.) Its volume
is .65, not the design's .55: next to the boss roar and the other guardians'
roars (below), .55 played about 4 dB under King Coo's and the Gargoyle's.

**Cue time against picture** (boss age for the arrival and defeat, cycle
seconds in the fight):

| Beat | Picture | Cue |
| --- | --- | --- |
| Sand devil | rises .38-1.2 s, full by .85, fades 1.7-2.45 | `sand_devil` from 0.1 s (1.6 s) |
| Reveal | the flash at 1.65 s | `boss_reveal` at 1.65 s (shared) |
| Roar | beak pulses at 2.65, 2.80, 2.95 s | `hoopoe_roar` at 2.65 s, hoots at +.02, +.17, +.32 |
| Stage-up (full fight) | beak pulses at +0, +.15, +.30 s (.15 s each, the arrival's; were .12-.48/.46-.80/.78-1.12) | `hoopoe_roar` at the stage-up, hoots at +.02, +.17, +.32 |
| Stage-up (fury) | beak open 0-.52 s and .6-.88 s | `mummy_fury`'s two phrases (0-.52, .6-.88 s) |
| Mail call | the satchel opens at 0.6 s; letters from 1.6 s | `mail_call` at 0.6 s (1.0 s long), `letter_flick` at each release |
| Ankh | locks at 5.4 s, rises .5 s, spins up the last .6 s, thrown 6.8 s | `ankh_raise` at 5.4 s (1.4 s), `ankh_whir` at 6.8 s (2.6 s) |
| Defeat | the mask pops at .85 s; the letter glows from 1.1 s and flares at 3.12-3.62 s; the card at 1.55 s | `mask_pop` at .85 s (its clang is the file's first sample), `boss_victory` 1.55 s, `lost_letter` 3.2 s |

### Synthesis helpers

All in `tool/prepare_sound_effects.py`, after `crinkle` (the first two are the
prototype's).

| Helper | What it makes |
| --- | --- |
| `hoot(data, at, length, hz_from, hz_to, gain, seed)` | One giant hoopoe "hoo": `coo_voice` with a 4.5 Hz vibrato, an 11 Hz roll and `bright=1.1` (the formant that keeps a deep voice playable on a phone) |
| `gong(data, at, hz, length, gain)` | A small temple gong: five inharmonic partials (1, 1.47, 2.09, 2.56, 3.42 times `hz`), each decaying faster the higher it is, a 20 ms bloom |
| `whir(data, seed, start, seconds, rate_from, rate_to, hz, gain)` | A thrown boomerang: noise band-passed around `hz`, chopped by a spin whose rate (turns a second) glides from `rate_from` to `rate_to` |

`main()` gives `hoopoe_roar`, `postage_due` and `mask_pop` a soft-knee RMS
target of -15 dBFS and `dc_block` to all 13; no earlier cue's path changed.

### Synthesis parameters, cue by cue

All the listed gains are before `master()`.
- `hoopoe_roar` (1.4 s): thump .35 (heavy, .2 s); three `hoot` at .34; `gong`
  196 Hz, 1.3 s, .16; a descending `whoosh` .07 for 1.2 s.
- `sand_devil` (1.6 s): `updraft` 1.5 s, .5, 300 to 1400 Hz; `crackle` 40
  snaps over 1.4 s from .1 s; `crinkle` 16 grains, .22, 1.2-3.4 kHz.
- `mail_call` (1.0 s): thump .3; `crinkle` 22 grains .3 (1.3-3.6 kHz) from .08
  s; `bell` (warm) E5, G#5, B5 at .25, .39 and .53 s.
- `letter_flick` (.25 s): `band_noise` 2.6 kHz, q 1.4, 1.0 (the snap, 3 ms
  attack); 1.5 kHz, q .8, .45 from .03 s (the swish).
- `letter_return` (.40 s): thump .45; `band_noise` 2.2 kHz .6 (tick); `chirp`
  420 to 980 Hz, .22, from .08 s (the boing).
- `postage_due` (.70 s): heavy thump .45 and a second thump .4; `band_noise`
  1.1 kHz .7 (slap); `crinkle` 24 grains .4; `bell` G6 at .12 s (.34) and C7
  at .2 s (.16): the counter bell.
- `wrap_scuff` (.16 s): `band_noise` 700 Hz, q .9, .8: a dull thud.
- `ankh_raise` (1.4 s): `whistle` 220 to 330 Hz, .14, 6 Hz tremor, swell .8;
  `bell` (warm) C5, E5, G5, C6 at .30, .52, .74 and .96 s.
- `ankh_whir` (2.6 s): `whir` 9 to 6 turns/s over 1.2 s, then 6 to 10 over
  1.5 s from 1.1 s (it slows at the turn and quickens home), noise around 900
  and 980 Hz.
- `ankh_catch` (.35 s): thump .25; `bell` E6 (.26) and B6 (.1): a gold clink.
- `mummy_fury` (1.3 s): `band_noise` 1.8 kHz, .9, .5 s (linen tearing); two
  `hoot`s 380 to 360 and 380 to 330 Hz at .3 and .6 s; `gong` 233 Hz, 1.0 s.
- `mask_pop` (1.3 s): `clang` 880 Hz at 0; a .14 s thump .45; `wing_claps`
  30 to 12 a second from .1 s; `crinkle` 34 grains over 1 s; a `hoot` 300 to
  250 Hz at .9 s.
- `lost_letter` (1.4 s): four warm `bell`s C5, E5, G5, C6, .16 s apart.

### Objective checks

All 13 are mono, 16-bit, 44.1 kHz, exactly the length the bank reserves, peak
-3.10 dBFS, 0 clipped samples, DC below 0.0003, first and last samples below
.02 and .005. **The phone band** (the design's rule, every cue keeps 40 % or
more of its energy in 250 Hz-8 kHz, measured with two 12 dB/octave filters on
each side, `proof/mummy_cues_prototype.py`'s `band_share`):

| Cue | `hoopoe_roar` | `sand_devil` | `mail_call` | `letter_flick` | `letter_return` | `postage_due` | `wrap_scuff` | `ankh_raise` | `ankh_whir` | `ankh_catch` | `mummy_fury` | `mask_pop` | `lost_letter` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Share | 72% | 52% | 43% | 71% | 64% | 43% | 98% | 41% | 71% | 55% | 73% | 92% | 96% |

The closest to the floor are the ankh raise (its chimes' sparkle runs above
8 kHz), the mail call and the postage due (a satchel thump and a stamp's thud
below 250 Hz). That is why the mail call, the ankh raise and the whir are
high-passed. Levels as played, the figures `check_sound_effects.py --family
egypt` prints, against the references (the dragon's `dragon_breath` is -17.9;
see the table above):

| Asset | s | RMS | Loudest 100 ms as played | A-weighted loudest as played | 250 Hz - 8 kHz (FFT) |
| --- | ---: | ---: | ---: | ---: | ---: |
| `hoopoe_roar` | 1.40 | -14.7 | -12.0 | -15.2 | 99% |
| `sand_devil` | 1.60 | -21.2 | -24.3 | -23.8 | 65% |
| `mail_call` | 1.00 | -18.8 | -22.0 | -20.3 | 52% |
| `letter_flick` | .25 | -22.7 | -29.3 | -26.4 | 80% |
| `letter_return` | .40 | -21.2 | -22.5 | -23.6 | 84% |
| `postage_due` | .70 | -14.8 | -9.6 | -11.3 | 53% |
| `wrap_scuff` | .16 | -18.2 | -29.7 | -26.8 | 99% |
| `ankh_raise` | 1.40 | -17.9 | -21.7 | -20.5 | 48% |
| `ankh_whir` | 2.60 | -21.5 | -24.9 | -26.3 | 99% |
| `ankh_catch` | .35 | -17.3 | -20.1 | -19.2 | 70% |
| `mummy_fury` | 1.30 | -18.1 | -17.1 | -19.5 | 99% |
| `mask_pop` | 1.30 | -18.7 | -13.8 | -12.0 | 96% |
| `lost_letter` | 1.40 | -15.8 | -18.7 | -18.2 | 100% |

Next to the other guardians' (A-weighted as played): `coo_shout` -14.3,
`coo_roar` -14.4, `gargoyle_awaken` -12.2, `gargoyle_fury` -15.7,
`gargoyle_shatter` -15.4, `coo_defeat` -19.8, `boss_victory` -18.5, `boss_hit`
-26.8. So the roar stands with the other guardians' (plain figure within the
window the New York roars are held to: boss roar less 4 dB to the reveal plus
1 dB), `postage_due` is the loudest hit and stays under the reveal plus
1.5 dB, `mask_pop` is a little above `gargoyle_shatter`, `wrap_scuff` is as
quiet as `boss_hit` and its ducked level 6 dB under that. Two picks were made
for these levels. The scuff's take 4, a dull thud, played -34.0 A-weighted:
too low for a phone to carry. At the synthesis's soft-knee -15, the mask
played -9.3, 6 dB over the shatter, so it is mastered at -19.
The tests that pin all of this are in `test/neferhoo_audio_test.dart`; the
edges are driven through `BossAudioCues` and a real `SkyAudio` on the Android
host fake, with the counters and latches set the way the rules set them.
`test/neferhoo_merge_audio_test.dart` then flies level 2-6 on the real rules
(the shared bot, two widths) and demands, after every step, that each cue plays
on the step its edge happens and on no other, and that the totals agree with
the rules' counters (it skips itself while the rules are only the scaffold).

### Audition first

In this order; each line says what it should sound like. To compare any cue
with its synthesis, render it with `--egypt-synth --only <cue>` (and back
without the flag).
1. `hoopoe_roar`: "HOO-POO-POO", three quick hollow hoots near 390 Hz, one
   with each pulse of his beak, then a small temple gong ringing out; a giant
   bird, comic, not scary. It rings at his arrival and at the first stage-up.
   Bad: a click at a splice (the cuts are at .17 and .32 s), the three running
   into one, or an owl or a ghost.
2. `postage_due`: a heavy double "ka-chunk" of a rubber stamp and a bell
   ringing on. It must feel like a jackpot: it is the payoff of the whole rule
   and plays after every successful return. Bad: a thud with no reward, or
   harsh after twenty repeats.
3. `lost_letter`: four soft bell notes rising, C-E-G-C, from one ElevenLabs
   bell tone. Bad: a plain electronic beep (the tone is nearly pure). The
   alternatives are its synthesis or another try at the bell (`BELL_HZ` is
   the take's pitch).
4. `ankh_whir`: a chopped whup-whup, about four turns a second, level for
   2.3 s. Bad: a drone, a helicopter, a fan.
5. `mummy_fury`: three rough cries, a breath, one short cry at .60 s (his
   beak's second opening), over the gong. Bad: a seam where the take was
   joined (`FURY_JOIN`).
6. The defeat together: `boss_break` at the defeat, `mask_pop` (clang and
   paper) at .85 s, `boss_victory` at 1.55 s and `lost_letter` at 3.2 s, once
   the victory has rung out.

### Open points for the owner

- The ElevenLabs takes were picked by measurement, not by ear. Every other
  take is kept (`egypt-int/sfx-el/takes/`, why each lost is in
  `sources.<cue>.rejected`), so a different pick is a copy and a one-word
  change in `EGYPT_TAKES`.
- `hoopoe_roar` was re-timed (hoots .15 s apart, the beak's rhythm) and its
  volume raised to .65. If the art would rather keep the take's own .28 s
  rhythm, set `ROAR_HOOTS` to (0, .26), (.26, .295), (.555, None),
  `ROAR_NOTES`' starts to 0, .26 and .555, and the art's `syllables` to match.
- The names `lost_letter` (his glow) and the older `letter_lost` (a letter
  the bird drops) are one transposition apart; the design chose them.
- A rock on his wraps sounds the shared `boss_hit` and the cloth thud
  together; if that is too much for "deliberately small", drop `boss_hit`
  for Neferhoo in `NeferhooAudioCues` (one line) and the thud stands alone.
- The open-sky gag has no sound (see above).
- One cue per frame: a bulk return of several letters, or two letters
  released in one frame, is one cue; the bank's cooldowns stop a fast stream
  from stacking.
