# Sound effects

The game bundles 61 short PCM effects and variations. All playback works offline
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
| Boss death | Breaking body, debris burst and victory flourish, timed to the animation |
| Player damage / recovery | Padded impact, shield break/recharge and dedicated heart pickup |
| Rewards | Bell and wood tones for stars, trios, perfect gates, combos, magnet, letters, deliveries and discoveries |
| Milestones | Wing, record, unlock, final stretch, completion and flight end |
| Interface | Soft major-key plucks for buttons, back, toggles, pause and resume; ascending confirmation notes with rounded attacks and gentle tails |

Generated Foley was made with ElevenLabs `eleven_text_to_sound_v2`. Prompts,
generation IDs and downloaded source hashes are in
[sound-effects-sources.json](sound-effects-sources.json). The other cues are
original deterministic compositions in `tool/prepare_sound_effects.py`.

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

| New asset | Duration | RMS before playback gain |
| --- | ---: | ---: |
| Sprint | 550 ms | -18.55 dBFS |
| Sprint ready | 450 ms | -15.16 dBFS |

Both keep -3.10 dBFS peaks. SHA-256 checks against the 22 September release APK
confirm that all 57 earlier effects are byte-identical.
