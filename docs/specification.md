# Push-Up Bird — polished Android game with room to grow

## Summary

Build a colorful, competitive, offline arcade game with four controls:

- **Push-Up Flight:** body position controls bird height continuously. Pushing up raises the bird; lowering yourself brings it down. The face does not need to be visible.
- **Squat & Fly:** squat to descend and stand to rise, with both feet planted. Calibrate a comfortable range before flying.
- **Tap & Fly:** tap to flap and shoot bats without a camera.
- **Jump & Fly:** a standing body-camera mode where each small jump triggers a stronger bird boost. Landing prepares the next boost.

Deliver Android first, with shared game logic and interfaces designed for a later iOS release and additional exercise games.

### Endless progression

New flights have no time limit. Collision, tracking and voluntary-ending rules
still apply. Replay rules version 12 starts at the familiar course speed, then
smoothly approaches 1.65× over several minutes (1.25× in relaxed Cruise).
Points do not change the pace. The HUD shows elapsed time and the pace multiplier.

Start with garden gates, then introduce Wind Lifts after 18 seconds, Petal
Shutters after 36 seconds, and split Switchbacks after 54 seconds, after at least
three introductory gates. Version 13 adds Lantern Drift after 72 seconds,
Sun Wheels after 90 seconds, and Crystal Steps after 108 seconds. Shuffle bags
mix the unlocked patterns without immediate repeats. Lifts move vertically,
shutters breathe open and closed, and switchbacks have two openings moving in
opposite directions. Lantern pairs sway, sun wheels orbit around the open lane,
and crystals form three contiguous, staggered columns. Floating bodies have
circle collisions, with no invisible walls extending to the screen edges.
Render and collide against the same animated geometry. Retire objects after
they leave the screen.

Version 13 gives each non-garden family three seeded color/detail variations.
Wind lifts have brass rails and broad turbines; petal shutters have leaf layers
and blossoms; switchbacks and crystal steps use faceted surfaces. Lantern ribs
and sun-wheel blades stay inside their circular bodies. Cloud Cruise uses
matching beaded, star and crystal rings. Decorative motion honors Reduced Motion.

Push-up and squat targets stay at the calibrated endpoints; moving walls always
leave clearance there. Passage spacing accounts for the widest obstacle, the
leading star trio, the measured half-cycle and a reaction allowance. For flap
controls, stars follow moving openings. Pauses freeze obstacle motion, and
Reduced Motion removes decorative spin while keeping gameplay motion visible.

The 60-second Star Trail and 75-second Courier wings are survival milestones;
daily goals and Trailblazer count saved flights lasting at least 60 seconds.
Pre-version-12 journals retain static gates, score-based speed and their timed
finishes, including arrival art. Version-12 journals retain their four-pattern
shuffle, random sequence, original spacing and artwork.

## Technology and architecture

| Area | Choice |
|---|---|
| Menus and application UI | **Flutter**, with custom animated components |
| Game rendering and mechanics | **Flame**, integrated with Flutter menus and overlays |
| Camera tracking | **MediaPipe Pose Landmarker** for push-ups, squats and jumps |
| Application state and navigation | **Riverpod** and **go_router** |
| Offline records and progression | **Drift/SQLite**, with versioned migrations |

Flutter and Flame suit this combination of animated menus and 2D gameplay. MediaPipe provides native Android and iOS tracking integrations. [Flutter games](https://flutter.dev/games), [Flame integration](https://docs.flame-engine.org/latest/flame/game_widget.html), [MediaPipe body tracking](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker/android), [iOS tracking](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker/ios)

Keep camera capture and inference native: Kotlin/CameraX on Android, with a Swift/AVFoundation implementation in the later iOS milestone. Pass timestamped tracking results into Dart instead of copying camera frames through it. Use Pigeon for typed platform communication. [Flutter platform integration](https://docs.flutter.dev/platform-integration/platform-channels)

Create four clear extension points:

- `TrackingSource`: starts/stops the selected detector and emits body samples, tracking status, and errors.
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

### 2. Build the playable controls

**Push-Up Flight**

- Automatically scroll obstacles horizontally; map calibrated body height directly to bird altitude.
- Alternate high and low passages so holding one position cannot clear the course.
- Increase difficulty through tighter gaps and faster scrolling, while keeping transitions within the movement range and cadence established during calibration.
- Award one point per cleared obstacle; count completed down/up cycles separately.
- A collision ends the run. Hold the last input through tracking glitches of up to 0.5 seconds while simulation continues; longer tracking/posture loss ends the run.
- Backgrounding or taking a break ends a scored run. Practice mode permits pausing and resumes after a countdown.

**Jump & Fly**

- Jump launches use the regular Star Trail course with buildings, stars and hearts, without enemies or shooting. Old Cloud Cruise diagnostic links also open Star Trail; saved replays preserve their recorded course.
- Calibrate from one second of stable shoulder/hip observations, using a rolling median window that tolerates foot jitter and brief missing frames. Shoulders, hips, knees and a usable ankle or toe on each side establish full-body framing; the face does not need to be visible.
- Detect a coordinated upward movement of hips and shoulders. Normalize the threshold to body size and measured standing noise, require upward speed and two confirming samples, then wait for the torso to settle before another boost. Feet establish framing, but their estimated motion cannot veto a jump.
- Small hops and deliberate body bounces count; perfect airborne-foot verification is not required. Crouching, shoulder-only movements, isolated pose spikes and stale samples do not trigger boosts. A brief rejected frame preserves a previously confirmed landing but never triggers a boost itself; sustained tracking loss requires landing again.
- Use a stronger boost and gentler gravity: impulse −0.55 and gravity 0.55 give about three times the previous smile flap height and twice its airtime. Space passages farther apart and scroll more slowly to allow recovery between physical jumps.
- After the upward boost, bank three seconds of gliding. Descent starts at 0.06 viewport heights per second and eases toward 0.20 over the final 1.25 seconds of charge; after expiry it stays capped at 0.20. Rate-limit speed changes so collecting a star also slows the bird gently. Each star adds 0.75 seconds to an existing charge, capped at five seconds. Stars cannot initiate or revive a glide. Another jump boosts immediately and refreshes at least three seconds without removing earned time.
- Glide time freezes during pauses and countdowns, and collision/tracking-loss rules still apply. Show remaining time, star-extension feedback and a low-charge cue when the descent begins easing out; open the bird’s wings while gliding. Replay version 11 enables smooth descent; versions 9–10 retain their original charged glides and earlier jump journals retain version 8 physics.
- Count jumps separately from push-ups. Replace the old smile mode in its persisted record slot, accept old `smile` journal names, and retain the original physics for replay versions before 8. Touch physics remain unchanged.

**Squat & Fly**

- Use body pose tracking, with both shoulders, hips, knees and ankles visible. Ignore facial and hand landmarks. Stand still for 0.8 seconds, hold a comfortable squat for 0.4 seconds, then return to standing for 0.3 seconds.
- Learn hip height above the ankles at each endpoint. Require a visible hip drop of at least 10% of standing body height; map the learned comfortable range continuously to bird height. Squatting lowers the bird and standing raises it without gravity or jump boosts.
- Use a three-frame median, 65 ms smoothing and 6% endpoint margins. Count one full standing–squat–standing cycle; jitter, a held position and interrupted cycles cannot add repetitions.
- Reject missing/stale joints, changes in camera distance and lifted feet. Tracking interruptions restart calibration; during flight they use the existing hold, pause and end rules.
- Use alternating high/low passages and spacing based on the calibrated cadence across every course. Save squat statistics separately from push-ups, jumps and touch; scored squats contribute to unlocks, daily goals and passport progress. Practice remains unscored.
- Append the persisted mode at index 3, preserving existing records. Replay version 10 adds squat journals with height and repetition inputs; previous journals retain their rules.
- Expose scored and practice starts under Other ways to play, with grounded squat artwork, calibration feedback, a squat counter and a separate personal best.

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

- Test calibration, height mapping, posture rejection, looking down, partial visibility, jitter, stale samples, and jump takeoff/landing hysteresis and replay compatibility.
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
