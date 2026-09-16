# Push-Up Bird — polished Android game with room to grow

## Summary

Build a colorful, competitive, offline arcade game with two modes:

- **Push-Up Flight:** body position controls bird height continuously. Pushing up raises the bird; lowering yourself brings it down. The face does not need to be visible.
- **Grin & Glide:** a seated face-camera mode where each smile triggers a flap. Returning to a neutral expression prepares the next flap.

Deliver Android first, with shared game logic and interfaces designed for a later iOS release and additional exercise games.

## Technology and architecture

| Area | Choice |
|---|---|
| Menus and application UI | **Flutter**, with custom animated components |
| Game rendering and mechanics | **Flame**, integrated with Flutter menus and overlays |
| Camera tracking | **MediaPipe Pose Landmarker** for push-ups; **Face Landmarker** for smile controls |
| Application state and navigation | **Riverpod** and **go_router** |
| Offline records and progression | **Drift/SQLite**, with versioned migrations |

Flutter and Flame suit this combination of animated menus and 2D gameplay. MediaPipe provides native Android and iOS tracking integrations. [Flutter games](https://flutter.dev/games), [Flame integration](https://docs.flame-engine.org/latest/flame/game_widget.html), [MediaPipe body tracking](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker/android), [iOS tracking](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker/ios)

Keep camera capture and inference native: Kotlin/CameraX on Android, with a Swift/AVFoundation implementation in the later iOS milestone. Pass timestamped tracking results into Dart instead of copying camera frames through it. Use Pigeon for typed platform communication. [Flutter platform integration](https://docs.flutter.dev/platform-integration/platform-channels)

Create four clear extension points:

- `TrackingSource`: starts/stops the selected detector and emits body or face samples, tracking status, and errors.
- `MovementInterpreter`: converts samples into normalized height, completed repetitions, or individual flap events.
- `GameMode`: defines controls, obstacle generation, scoring, and interruption rules.
- `ProgressRepository`: stores settings, mode-specific records, run summaries, and cosmetic unlocks.

Keep movement interpretation and game rules independent of cameras and widgets so they can be tested using synthetic inputs.

## Implementation

### 1. Prove body tracking and viewing comfort

Build the Android camera/calibration screen first and test it on the connected phone.

- Use one phone propped low in landscape, facing the player or beside and slightly ahead.
- Show a body outline and clear positioning feedback until the necessary joints are visible.
- Guide two down/up movements to calibrate the player’s range.
- Measure shoulder height relative to wrists, normalized to the calibrated range; use elbow extension and shoulder–hip–knee–ankle alignment to check consistency with a standard push-up.
- In front view, use both shoulders as a roll-independent reference and normalize
  their height above the hands by shoulder width. Preserve the calibrated view;
  do not switch to a torso-line measurement when one side becomes occluded.
- Reject a second calibration excursion shallower than 55% of the first. Learn
  median arm extension near both endpoints. Use a small but distinct front-view
  angle difference to confirm a held top for 120 ms; use larger angle differences
  to also contribute to continuous height. Smooth the measurements and use
  separate release thresholds so perspective drift and jitter do not leave a
  held top at mid-height or make it bob.
- Validate sample age on arrival. Measure stream availability from receipt time
  so inference latency cannot expire valid tracking between packets. Brief
  tracking gaps pause the countdown; gaps over 500 ms restart it.
- Ignore facial-landmark visibility when deciding whether posture is valid.
- Smooth movement and reject stale samples, standing/crouching positions, and insufficient tracking confidence.

**Milestone gate:** demonstrate usable controls while the player looks down and can still see approaching obstacles. If that setup fails, document the physical limitation and revisit placement before investing in finished gameplay. Do not silently substitute face tracking.

### 2. Build both playable modes

**Push-Up Flight**

- Automatically scroll obstacles horizontally; map calibrated body height directly to bird altitude.
- Alternate high and low passages so holding one position cannot clear the course.
- Increase difficulty through tighter gaps and faster scrolling, while keeping transitions within the movement range and cadence established during calibration.
- Award one point per cleared obstacle; count completed down/up cycles separately.
- A collision ends the run. Hold the last input through tracking glitches of up to 0.5 seconds while simulation continues; longer tracking/posture loss ends the run.
- Backgrounding or taking a break ends a scored run. Practice mode permits pausing and resumes after a countdown.

**Grin & Glide**

- Calibrate neutral and smiling expressions with the phone facing the seated player.
- Use smile-expression scores with separate activation/reset thresholds and a cooldown: holding a smile must produce only one flap.
- Apply gravity and classic flap impulses.
- Maintain separate high scores; never count facial actions as push-ups. MediaPipe exposes facial-expression scores for this controller. [Face Landmarker](https://developers.google.com/edge/mediapipe/solutions/vision/face_landmarker)

Run only the detector required by the selected mode.

### 3. Deliver the finished visual experience

Use a playful cartoon direction: expressive chunky birds, layered skies and floating islands, sky-blue backgrounds, coral and yellow accents, rounded typography, and bouncy transitions.

Build:

- Animated home screen with both mode cards and personal bests.
- Illustrated setup, camera permissions, calibration, and countdown.
- Large gameplay graphics, score, and simple tracking feedback.
- Results with score, best score, mode-specific statistics, and retry.
- Bird collection with one default bird and three cosmetic unlocks.
- Settings for music, effects, reduced motion, and resetting local progress.

Unlock cosmetics at 25, 100, and 250 cumulative obstacles cleared in scored runs across either mode. Use original artwork and audio; bundle all assets and tracking models for offline operation.

## Validation and delivery

- Test calibration, height mapping, posture rejection, looking down, partial visibility, jitter, stale samples, and repeated smile activation.
- Test collisions, obstacle reachability, scoring, interruption rules, practice behavior, and separation of mode records.
- Verify camera denial/revocation, background/foreground transitions, mode switching, and camera cleanup.
- Verify saved records and unlocks survive restart and database migrations.
- Visually inspect all screens on the connected phone, including readability from the required exercise position.
- Target 60 FPS rendering, at least 20 tracking updates/second, and p95 camera-to-control latency below 150 ms on the test phone. Measure these rather than assume them.
- Run Flutter analysis, automated tests, Android builds, and native-library compatibility checks, including 16 KB page sizes. [Android compatibility guidance](https://developer.android.com/guide/practices/page-sizes)

Deliver an installable Android APK, reproducible build instructions, and the shared iOS project scaffold. iOS camera implementation and device validation are a later milestone requiring macOS/Xcode. [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios)

## Assumptions and boundaries

- Working title: **Push-Up Bird**.
- Initial push-up mode uses standard push-ups; knee and other exercise variants come later.
- Body checks are confidence-based gameplay checks, not a guarantee of correct exercise form.
- Camera processing and saved session videos stay on-device. Record camera footage during flight with optional microphone audio and retain it only when the player chooses Save session. Store timestamped gameplay inputs, timing, seeded randomness and interruptions separately; reconstruct gameplay for replay. No uploads, accounts, ads or cloud services.
- Competition uses local records initially.
- Public Play Store submission, monetization, and iOS publication follow the polished offline milestone and broader device testing.


## Session replay

Results offer **Save session** independently of automatic score records, including
practice flights. Records → Saved sessions lists the full saved library and lets
players replay or delete a session without changing score totals. Reset local
progress also removes saved sessions and camera videos.

The player supports a movable corner camera rectangle over gameplay, camera
video behind transparent bird/obstacles, and gameplay only. All modes have
play/pause, a seek bar, restart, ±5 seconds, 0.5×/1×/1.5×/2× speed and game-sound
mute. Controls overlay the replay instead of shrinking it. Tapping the viewing
area hides the controls; tapping again reveals them. Interacting with buttons,
menus or the seek bar does not toggle the overlay. The replay keeps the same
viewport size and aspect ratio in both states. Camera clips include microphone audio when the player opts in; music
and effects are generated during playback. Recorded audio and game sound have
independent mute controls in all three views, including gameplay only. The equipped bird is retained.

CameraX writes camera-only MP4 files; no screen capture is used. Versioned JSON
stores movement inputs and exact simulation steps, including timestamps, random
seed, rule parameters and interruption commands. Replay version 1 uses the current
FlightSimulation rules; future rule changes must preserve that version or provide
an explicit migration. Practice camera restarts create additional clips on the
same monotonic timeline. Failed camera capture permits gameplay-only saves.


Microphone recording is off by default. The setup switch reads **Record microphone
· Optional**, accompanied by: “Add your voice and room sound to replays. Uses the
microphone during flight only. Saved on this phone.” Enabling the switch is the
only action that may request Android's separate RECORD_AUDIO permission. There
is no extra rationale dialog. Remember successful opt-in in local preferences;
denial, unavailable hardware and revocation keep video/gameplay available. Do
not automatically request microphone access on game start, retry or resume.
Permanently denied access has an optional Settings link, never a forced redirect.
Camera clips record whether they contain an audio track; legacy clips default to
silent. Microphone audio uses the same MP4 timeline and local retention policy.
