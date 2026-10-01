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
| Boss death | Breaking body, debris burst and victory flourish, timed to the animation |
| Player damage / recovery | Padded impact, shield break/recharge and dedicated heart pickup |
| Rewards | Three rotating bell tones for stars, plus bell and wood tones for perfect gates, combos, magnet, letters, deliveries and discoveries |
| Milestones | Wing, record, unlock, final stretch, completion and flight end |
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
focus and therefore do not silence music.

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
