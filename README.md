# Push-Up Bird

An offline Android arcade game built with Flutter, Flame, CameraX and MediaPipe.
Push-Up Flight maps a calibrated push-up range to continuous bird height. Grin &
Glide maps each neutral-to-smile transition to one flap. Records, settings and
cosmetic unlocks stay in SQLite on the phone.

**Status:** tracking has regression replays from the OnePlus CPH2585's actual
landmarks, including the latest scored game's missed top, false calibration
cycles during a held top, calibration asking to push back up while both arms
were already straight, and the bird dropping to mid-screen on a slight bend.
The depth estimator was rebuilt around calibrated, reliability-weighted cues
(see below); it is installed as a diagnostics build (`make diag`) and needs a
physical retry.
The complete game UI and both modes are implemented, but finished-game device
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
builds record nothing):

```sh
flutter build apk --profile --target-platform android-arm64 --dart-define=TRACKING_DIAGNOSTICS=true --dart-define=TRACKING_CAPTURE_IMAGES=true
adb install -r build/app/outputs/flutter-apk/app-profile.apk
adb logcat -v epoch -s flutter:I PushUpBird:I > /tmp/push-up-bird.log
dart run tool/replay_tracking.dart /tmp/push-up-bird.log
# Recover the latest camera session even after Android's logcat buffer clears
# (`make logs` does this and lists the sessions it found):
adb exec-out run-as com.ravanix.push_up_bird cat files/tracking_diagnostics/latest.log > /tmp/push-up-bird-last.log
dart run tool/replay_tracking.dart /tmp/push-up-bird-last.log
```

The trace contains full-precision body landmarks, sensor timestamps, calibration
measurements, control/preview output, and flight-reset events. Keep diagnostic
captures local. Opt-in development builds keep `latest.log` and `previous.log` in private
app storage, each capped at 4 MiB. A new camera session or a full log rotates
these files so the newest measurements are retained. Replay requires the
calibration frames; for a rotated trace, also retrieve `previous.log` if it still
contains those frames. Control records remain useful without calibration replay;
normal builds omit the trace. Release mode disables diagnostics and image
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
