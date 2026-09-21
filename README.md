# Push-Up Bird

An offline Android arcade game built with Flutter, Flame, CameraX and MediaPipe.
Push-Up Flight maps a calibrated push-up range to continuous bird height.
**Squat & Fly** keeps your feet planted: squat to descend, stand to rise.
Stand still, hold a comfortable squat briefly, then stand back up to learn your range.
**Jump & Fly** uses full-body tracking: each small jump gives one big boost.
Stand still briefly to calibrate, keep both feet visible, and land to rearm.
Its boost reaches roughly three times the old smile flap height, followed by
**3 seconds of gentle gliding**. Each collected star adds **0.75 seconds** to an
active charge, capped at **5 seconds**. The glide meter shows when to jump again;
a new jump refreshes the base charge without losing time earned from stars. **Tap & Fly** lets you
tap the screen to flap, with no camera or microphone needed. Records, settings and
cosmetic unlocks stay in SQLite on the phone. After a flight, Save session keeps
an input journal and any camera footage for replay in Records → Saved sessions.
Replay **Flight highlights** lets you jump to discoveries, deliveries, streaks,
power-ups and the final approach, with a short lead-in before each moment.

**Endless flights:** Star Trail keeps going with three hearts, a shield and
streak multipliers. Every control has a gradual time-based speed increase,
with no finish timer. Garden gates give way to rising **Wind Lifts**, opening
and closing **Petal Shutters**, and two-column **Switchbacks**. Longer flights
introduce swaying **Lantern Drift**, orbiting **Sun Wheels**, and three-column
**Crystal Steps**. Floating obstacles use round collision shapes and leave open
sky around them. Turbines, blossoms, faceted towers and regional color variations
give each pattern a distinct look. Cloud Cruise gets matching decorative rings.
Patterns mix throughout the flight; calibrated push-up and squat pacing stays reachable.
The HUD shows elapsed time and current pace. The 60-second flight wing, daily
goal and passport stamp are endurance milestones, so you can earn them and
keep flying. Existing replay journals retain their original timing and physics,
including the four-pattern version-12 flights.

The saved **Classic**, **Sky Courier** (letter delivery), and **Cloud Cruise**
(open sky, cloud friends, no crashes) courses also run endlessly in Flight School.
Every course supports push-ups, squats, jumps and touch. Three changing
sky regions with leafy stone, festival flags and lantern-lit gates,
perfect-pass celebrations, bird trails and an eight-stamp
**Sky Passport** give flights more character and goals. Each scored course keeps
separate records for each control; Cloud Cruise is always practice. See the
[arcade update notes](docs/arcade-expansion.md) for rules, design links and checks.

**Home** opens on a game title scene with your equipped bird and a prominent
**Play** button for Push-Up Flight on Star Trail. **Practice** is directly below;
**Other ways to play** opens Tap & Fly, Jump & Fly and Squat & Fly. The five collectible
shortcuts lead to daily adventures, birds, the passport, records and flight goals.

**Tap & Fly**, under **Other ways to play**, starts a full touch flight on Star Trail. Tap
anywhere in the sky to rise, then release and tap again. Touch flights have a
stronger flap, narrower openings and closer buildings. Tap **Shoot** to spit a
rock straight from the bird's beak at bats ahead; aim by changing your height.
One hit clears a bat (+3 points on Star Trail), buildings block rocks, and each
shot has a short cooldown. Bats use the same shield/heart collision rules as
buildings. Cloud Cruise stays free of enemies. Scored flights contribute
to unlocks, daily adventures and flight goals, with separate touch bests in
Records. Practice and Cloud Cruise can pause and resume; scored flights end
when interrupted. Save session keeps a gameplay replay without camera video,
including shots and enemies. Existing replays keep their original flight rules.

**Flight school** on Home lets you explore every course with touch controls:
drag to steer or tap to flap. Learn the actual stars, gates, letters and cloud
friends without a camera. Lessons can pause or restart freely and never change
records, unlocks, daily adventures or saved sessions. When ready, jump directly
into push-up or jump practice for the selected course.

Perfect gates now charge a **Star Magnet** in the star courses: three perfect
passes grant eight seconds of extra pickup reach. Push-up aiming marks and stars
follow the full calibrated top and bottom positions. Older saved replays retain
their original targets and scoring rules.

**Star trios:** collect every star in a connected set to form a constellation
and earn five bonus points in Star Trail or Cruise. Missed sets leave the next
trio available. Bonus points do not accelerate multipliers or shield charge.

**Daily adventures** rotate three small goals each local day. Complete them to
stamp a Sky Club postcard; the last seven days stay visible. All four controls
work, progress is saved offline, and there is no streak penalty.

Scored flights show a live **personal-best target** for that course and control,
with a one-time celebration when you pass it. Cleared gates bloom with flowers;
perfect passes earn a gold seal, and Cloud Cruise rings turn mint after a pass.
Each bird has a signature trail: Pip's bubbles, Peaches' hearts, Minty's leaves,
and Orbit's stardust. Preview them in the crew screen; Reduced Motion freezes
their decorative movement.
In flight, each bird's wing follows your push-up range or makes a short stroke
after a jump boost, with a small air wake. Reduced Motion keeps the pose neutral.
The crew also reacts with pleased eyes after rewards, a brief startled look for
bumps, and occasional blinks. These expressions follow replay time and stay
neutral under Reduced Motion.

**Cloud friends:** meet Cloud Whale, Daydream Bunny and Sky Turtle during a
Cruise. Fly close to discover each one in that flight's collection; missed
friends drift back later. Results show who you met, and saved replays preserve
the discoveries. They add no score requirement or timer.

**Sky Courier:** clear a pickup gate to carry a letter, then a postbox gate to
deliver it. Bumps drop your cargo without ending the route. Clean gates count
toward bird unlocks; practice leaves records untouched. Saved replays preserve
the cargo and delivery state when seeking backward.
Letters now fly into the bird's pouch and arc into a postbox on delivery. A
completed postbox raises its flag and releases hearts; Reduced Motion shows the
finished state immediately.

Timed routes now approach a visible destination in their last six seconds:
gold finish pennants for Star Trail and coral home pennants for Courier.
Completed routes add a matching ribbon medal to the result portrait.

**Flight goals:** earn three wings in one scored flight. Classic rewards 5, 10
and 25 gates; Star Trail rewards 12 stars, a six-star streak and a full trail;
Courier rewards one delivery, three deliveries and a full route. Open Flight
goals from Home to see the targets, or tap a result's wings for progress. Results
keep Save session visible, then offer Watch replay directly after saving.

**Status:** tracking has regression replays from the OnePlus CPH2585's actual
landmarks, including the latest scored game's missed top, false calibration
cycles during a held top, calibration asking to push back up while both arms
were already straight, and the bird dropping to mid-screen on a slight bend.
The depth estimator was rebuilt around calibrated, reliability-weighted cues
(see below); it is installed as a diagnostics build (`make diag`) and needs a
physical retry.
The complete game UI and all four control modes are implemented, but finished-game device
acceptance and performance targets are pending. See [validation](docs/validation.md).

## Build and run

Tested toolchain: Flutter 3.44.8, Dart 3.12.2, Android SDK and Java from Android
Studio. Android minimum SDK is 24. Dependencies are pinned in `pubspec.lock`.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

The APK is signed with the development key for sideload testing. Configure your
own signing key before store distribution. No network or model download is
needed at runtime. For direct access to the diagnostic camera lab:

```sh
flutter build apk --profile --target-platform android-arm64 --dart-define=CAMERA_LAB=true --dart-define=TRACKING_DIAGNOSTICS=true
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

The same lab is available through Settings. After opening the lab, run
`python3 tool/camera_start_smoke.py` to start the camera and check actual tracking
packet delivery. The lab logs compact posture measurements once per second;
`adb logcat -s flutter PushUpBird` displays them. No camera images are logged.

Regenerate typed native bindings and database code after schema changes:

```sh
dart run pigeon --input pigeons/tracking_api.dart
dart run build_runner build
```

Check packaged models and 16KB native ELF alignment:

```sh
python3 tool/check_android_apk.py build/app/outputs/flutter-apk/app-release.apk
```

Also run the Android SDK's `zipalign -c -P 16 -v 4` on the APK. ELF/ZIP alignment
checks do not replace runtime testing on a device with a 16KB page size.

## Structure

- `lib/domain`: camera-independent tracking observations, calibration, movement
  interpreters, game modes, collisions, scoring and interruption rules.
- `lib/tracking`, `pigeons`: timestamped native result bridge and timing metrics.
- `android/app/src/main/kotlin`: CameraX capture and background MediaPipe
  inference. Only the selected body or face detector runs.
- `lib/game`: Flame rendering, audio and play-session coordination.
- `lib/data`: Riverpod state and Drift/SQLite repository with migrations.
- `lib/ui`: landscape home, setup, calibration, play, results, birds and settings.
- `ios`: shared Flutter project and generated Swift Pigeon contract. Native
  AVFoundation/MediaPipe camera implementation is a later macOS/Xcode milestone.

## Design and assets

[Original Figma design library](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7)
contains color and spacing variables, typography, buttons, four bird components,
floating-island artwork and the home composition. Bird and island PNGs in
`assets/images` were exported directly from those designs; SVG sources are in
`design`. Fredoka and Nunito are bundled under their included OFL licenses.
Original synthesized audio is reproducible with `python3 tool/generate_audio.py`.

The body controller deliberately ignores facial landmarks. Side views need one
tracked shoulder, elbow, wrist and hip. Front views need both shoulders plus one
arm and hip. The view is fixed during calibration so occlusion cannot change the
measurement system mid-flight. All measurements tolerate camera roll. Uncertain
knees and ankles do not block calibration. This is a gameplay check, not a form
assessment.

Push-up depth is not read from one hand-picked projection. Each frame yields
a small set of depth cues: the projected elbow angle of each visible arm and,
in front view, shoulder height above the hands in shoulder widths. An elbow
folded below 55° is a misplaced landmark and contributes nothing; when the two
arms disagree by more than 25°, the straighter one segments movement. On the
phone's own recordings the 2D elbow angle separates this player's top from
their bottom by more than ten noise standard deviations in both views, while
MediaPipe's z estimates are several times noisier and are not used.

Calibration segments movement on that arm angle alone. It waits for a steady
top (0.8 s within 12°), counts a descent only after a sustained bend of 15°
below it, requires at least 30° of excursion and a return into the top fifth of
it, and treats anything faster than 0.7 s, or the second excursion covering
less than 55% of the first, as a wobble or bounce to forget rather than learn.
The frames at each end of the two accepted push-ups label every cue. Each cue
gets a robust linear model (median endpoints, MAD spread) weighted by its
squared discriminability d′², the Fisher-optimal weight for fusing independent
linear cues; cues with d′ below 2 are dropped unless nothing better exists, and
a model learned from one arm serves the other when it becomes the visible one.

During play every visible cue votes with its own depth; with three or more
votes the one far from the weighted median is discarded as a landmark glitch.
A three-frame median and a One Euro filter (Casiez et al., CHI 2012: a low-pass
whose cutoff rises with speed, so a hold is smoothed hard while a real push-up
passes with little lag) shape the fused depth, and a 6% margin at each end lets
a naturally noisy top or bottom reach exactly 1 or 0. There is no separate
"arms extended" switch: a straight-armed hold reads 1.0 because every cue says
so, and a slight bend costs a few percent, not half the screen. The bird
previews movement while the range is learned. Tracking can recover onto the
other visible side and checks both arm and torso scale before requesting
recalibration after a camera-distance change.

For opt-in landmark and control diagnostics in the real play screen
(`make diag` builds and installs this; `make run` debug builds and release
builds omit diagnostic traces):

```sh
flutter build apk --profile --target-platform android-arm64 --dart-define=TRACKING_DIAGNOSTICS=true --dart-define=TRACKING_CAPTURE_IMAGES=true
adb install -r build/app/outputs/flutter-apk/app-profile.apk
adb logcat -v epoch -s flutter:I PushUpBird:I > /tmp/push-up-bird.log
dart run tool/replay_tracking.dart /tmp/push-up-bird.log
# Recover the latest camera session even after Android's logcat buffer clears
# (`make logs` does this and lists the sessions it found):
adb exec-out run-as com.ravanix.push_up_bird cat files/tracking_diagnostics/latest.log > /tmp/push-up-bird-last.log
dart run tool/replay_tracking.dart /tmp/push-up-bird-last.log
# Jump sessions use the jump calibrator/interpreter. An optional final integer
# asserts an exact jump count when the physical retry's count is known.
dart run tool/replay_jump_tracking.dart /tmp/push-up-bird-last.log
# Exercise the actual controller, countdown and bird physics with a private
# capture. Optional assertions: CALIBRATE_BY_MS, STOP_AT_MS,
# NO_JUMPS_BEFORE_MS, MIN_JUMPS (times relative to the first captured frame).
flutter test tool/replay_jump_session_test.dart --dart-define=TRACKING_LOG=/tmp/push-up-bird-last.log
```

The trace contains full-precision body landmarks, sensor timestamps, calibration
measurements, control/preview output, and flight-reset events. Keep diagnostic
captures local. Opt-in development builds keep `latest.log` and `previous.log` in private
app storage, each capped at 4 MiB. A new camera session or a full log rotates
these files so the newest measurements are retained. Replay requires the
calibration frames; for a rotated trace, also retrieve `previous.log` if it still
contains those frames. Control records remain useful without calibration replay;
normal builds omit this diagnostic trace. User-saved session replays are separate. Release mode disables diagnostics and image
capture even if either define is passed.

`TRACKING_CAPTURE_IMAGES=true` additionally retains up to 120 camera JPEGs per
session at one image/second and 320 pixels on the longest side. The latest two
sessions live in private `files/tracking_captures/latest` and `previous` folders;
slots wrap during longer sessions. Each image has a JSON sidecar whose `nativeT`
and `session` match the landmark trace. These are camera images, without the game
UI overlay. Compression/writes use a separate worker and skip captures if busy.
Omit this define for landmark-only diagnostics. Retrieve both logs and images:

```sh
adb exec-out run-as com.ravanix.push_up_bird tar -cf - files/tracking_diagnostics files/tracking_captures > /tmp/push-up-bird-diagnostics.tar
```

Full requirements: [specification](docs/specification.md).


## Saved session replay

Results offer an explicit **Save session** action. Camera MP4 clips, optionally including microphone audio,
are stored separately from a versioned gameplay input journal; gameplay is
re-simulated, never screen-recorded. Unsaved camera drafts are removed on leaving
results or retrying, and drafts left by a killed process are cleaned up when the
camera subsystem next starts. Saved sessions live in app-private storage with
Android backup disabled.

Open **Records → Saved sessions** for corner-camera, camera-background and
gameplay-only views. Tap the replay to hide or show controls over the video
without resizing it. Controls include play/pause, scrub, restart, ±5 seconds,
0.5×–2× speed, camera-corner placement, recorded-audio mute and game sound on/off. Practice sessions
are also saveable. Delete removes replay files; Reset local progress removes all
saved sessions as well as scores/settings. Camera capture may be unavailable on
hardware that cannot run three CameraX streams; its gameplay journal still works.

Implementation references: [CameraX video capture](https://developer.android.com/media/camera/camerax/video-capture)
and [Flutter video_player](https://pub.dev/packages/video_player). Physical-device
synchronization and performance checks are listed in [validation](docs/validation.md).


Microphone audio is optional and off by default. Enable **Record microphone** on
setup to add voice and room sound to the camera clip. Its inline explanation
appears before Android's separate microphone prompt; there is no additional
confirmation dialog. Successful opt-in is remembered. Declining leaves video and
input recording available; starting, retrying and resuming do not request access.
If Android blocks further prompts, setup offers a user-initiated Settings link.
Revoked access turns microphone recording off without interrupting the flight.

Replay keeps recorded audio synchronized with the clip in every visual mode,
including gameplay only, with independent recorded-audio and game-sound controls.
Old silent sessions still work. Audio stays inside the local MP4 and follows the
same save/discard/delete lifecycle as camera video. See Android's
[runtime permission guidance](https://developer.android.com/training/permissions/requesting)
and [CameraX audio opt-in](https://developer.android.com/reference/androidx/camera/video/PendingRecording).
