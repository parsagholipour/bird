# Validation ledger

## 2026-09-16 touch Flight School

- Home opens a touch sandbox for all four courses, with drag-to-steer or
  tap-to-flap controls, actual rewards, contextual hints, pause/restart and
  explicit camera-practice handoff. Lessons never create tracking or recording
  sessions and never write progress. Backgrounding and stalled frames pause;
  resume clears pending taps and starts another countdown.
- All 219 Flutter tests pass and analysis is clean. Domain checks cover course
  rewards/endings, inputs, bounds and pause timing. Integration checks at 640×360
  and 800×360 cover navigation, touch gestures, lifecycle, audio, camera creation
  only after handoff and unchanged records/session storage. Home, intro, flight,
  pause, ending and Figma renders were reviewed. A completion-time rebuild error
  was fixed by scheduling HUD updates after Flame's layout and stopping its loop.
- The 64.3 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `c7bd8747b67fbcce159ad2dab519479565f078c62d8c504384c85c7197e19154`.
- No Android device is connected. Physical touch/camera, comfort, listening and
  rendering-performance checks remain pending; this APK was not installed.

## 2026-09-16 bird reactions

- Birds now show pleased eyes for rewards, startled eyes for bumps and short
  staggered blinks between events. Reactions are brief, pause with simulation
  time and reconstruct during replay seeks. Reduced Motion preserves neutral
  faces. Completed and collision replays hold the corresponding final expression.
- All 212 Flutter tests pass and analysis is clean. Pixel checks cover all four
  palettes and ensure bodies, beaks and wings stay unchanged. Behavior checks
  cover priorities, duration, future events, preflight, pause, endings and both
  replay controls. The expression sheet, rendered arrival and Figma study were
  visually reviewed. Cached body variants share each bird's original wing.
- The 64.2 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `0c4122e6ab42adb57c6542ee16fe8462e00f9d4d1ef860fd7c8ec9ce75f7d845`.
- No Android device is connected. Physical camera, comfort, listening and
  rendering-performance checks remain pending; this APK was not installed.

## 2026-09-16 timed-route arrivals

- Star Trail and Courier now approach gold FINISH or coral HOME pennants in
  their final six seconds. The decoration meets the bird when time expires and
  allows arrival at any height. Completed portraits receive matching ribbon
  medals, with course-specific greetings when other rewards do not take priority.
  No collision, timer, recording, scoring or replay-version changes were needed.
- All 205 Flutter tests pass and analysis is clean. Checks cover visibility
  boundaries, early exits, untimed exclusions, pause/resume, final-frame position,
  backwards replay seeks, Reduced Motion and finite portrait celebrations.
  Live Courier results verify the medal in both controls. Gameplay with full
  HUDs, completed frames, results and the new Figma study were visually reviewed.
- The 64.2 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `69393812ec2ba631a0f8d7da5e6061e8724c45de04d9d667a83a32a96a5afe2a`.
- No Android device is connected. Physical camera, comfort, listening and
  rendering-performance checks remain pending; this APK was not installed.

## 2026-09-16 star trios

- Each three-star approach in Star Trail and Cruise is connected visually.
  Collecting the set earns a flat +5 and unfolds a brief constellation. Missed
  sets fade; bonus points do not alter star counts, multipliers, shields,
  movement, collisions or unlock progress. Replay version 6 adds trios while
  older journals keep their exact scoring. The first trio has a replay highlight.
- All 194 Flutter tests pass and analysis is clean. Checks cover misses,
  separate sets, once-only rewards, magnet catches, shield/multiplier boundaries,
  practice pauses, both replay controls and calibrated 1-, 4- and 9-second
  routes. Historical fixtures retain scores of 151 (v4 Cruise) and 131 (v3 Trail).
  Reduced Motion, finite effects, silent seeking and reward audio were checked.
- Actual game and replay renders and the Figma three-state study were reviewed.
  The 64.1 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `4c1225a9aa465a784f4c5a4993ab98876bf0e22187b99cd25246599e96310676`.
- The phone briefly appeared in ADB, then disconnected before device testing.
  This APK was not installed. Physical camera, comfort, listening and rendering
  performance checks remain pending.

## 2026-09-16 Courier handoffs

- Pickups fly into the pouch; deliveries arc into their postbox, raise its flag
  and release hearts. Animation follows simulation time and scrolling gates,
  cancels dropped pickups and respects Reduced Motion. Rules are unchanged.
- All 184 Flutter tests pass and analysis is clean. Checks cover action anchors,
  failed stops, finite and deterministic animation, cancellation, paused time,
  backwards replay seeks in both controls and completed-station artwork.
  Rendered handoffs, saved replays and the new Figma study were reviewed.
- The 64.1 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `c3cb1db07adec90d76d98162244aec911c6b907dad98b935bcbfad6f09c6b168`.
- Physical camera, comfort, listening and rendering-performance checks remain
  pending without an Android device.

## 2026-09-16 responsive bird wings

- Bird wings now follow calibrated push-up height or make a finite smile-flap
  stroke, with a short air wake. The existing Figma geometry is compiled to
  cached body/wing paths; Reduced Motion stays neutral. Physics, collision size,
  records and replay rules are unchanged.
- All 181 Flutter tests pass and analysis is clean. Pixel comparisons cover all
  four original designs and unchanged faces as wings move. Behavior checks cover
  stable endpoints, finite strokes, pause timing, Reduced Motion and replay
  seeking with both controls. Rendered poses and the Figma study were reviewed.
- The 64.1 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `ceee5c74042cb792588a5b7fa1b144b248ffe2c59388a08f677445e3650bc504`.
- Physical camera, comfort, listening and rendering-performance checks remain
  pending without an Android device.

## 2026-09-16 replay highlights

- Saved flights now offer up to twelve moments: discoveries, deliveries,
  multipliers, magnets, shield saves, Classic milestones and the ending.
  Selecting one plays from a short lead-in; opening or dismissing the list
  pauses playback. Indexing preserves original journals and includes break and
  countdown time. Cruise's HUD avoids all four camera inset positions.
- All 175 Flutter tests pass and analysis is clean. Checks cover real event
  times, both controls, old/empty journals, bounded long-flight lists, source
  immutability, camera geometry and actual highlight selection/audio behavior.
  Phone layouts and the new Figma highlights sheet were visually reviewed.
- The 64.1 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `6e570bd963e5ae518f0fdd91ccad0131fbbb5be88616cebccb51b038f122121e`.
- No Android device was connected. Physical camera, comfort, listening and
  performance checks remain pending.

## 2026-09-16 Home course previews

- Home now previews the selected activity around the equipped bird: stars and a
  shield, letters and a postbox, or all three cloud friends. The daily postcard
  sits beside the preview. Art reuses the game renderers, has descriptive
  semantics and disables its short crossfade in Reduced Motion.
- The 15 Home, daily-navigation and course-flow checks pass; analysis is clean.
  Phone renders at 800×360 and 1000×450 and the three corresponding Figma Home
  views were inspected. The original Figma Home remains preserved.
- The 64.0 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `9d2b160fad19ec056cb3a31b96fcaccc60dbe97ae6cbb1678f216fa546fe0a20`.
- Physical camera, comfort, listening and performance checks remain pending.

## 2026-09-16 cloud friends

- Cloud Cruise now has a whale, bunny and turtle to discover, a live collection,
  a result album and a soft greeting. Encounters share the ring's movement
  endpoint, repeat missed friends and add no scoring or progression requirement.
  Replay version 5 reconstructs discoveries while older journals keep their rules.
- All 166 Flutter tests pass and static analysis is clean. Coverage includes
  duplicates, misses, pause/resume, calibrated 1-, 4- and 9-second push-up
  movements, both controls, old replay behavior, backwards seeking, Reduced
  Motion and once-per-discovery audio in actual saved-replay screens.
- Setup, flight, pause, results and replay layouts were rendered and reviewed at
  800×360. The existing Figma file includes new Cruise and flight-album views.
- The 64.0 MB ARM64 release APK builds; both offline models, all 15 native ELF
  checks and 16KB ZIP alignment pass. APK SHA-256:
  `e49f854e21c297a48015c8c9cc3211c2f1e2160fac64755547445df88cd3fe76`.
- No Android device was connected. Physical camera, comfort, listening and
  performance checks remain pending.

## 2026-09-16 flight wings

- Each scored course now has three visible flight goals, live wing rewards,
  a home guide, result progress and saved-flight details in Records and replay.
  Goal progress derives from existing statistics and keeps practice separate.
  Save Session and Watch Replay now stay visible beside the result actions.
- All 155 Flutter tests pass and static analysis is clean. Additional replay
  checks pass for both controls: wing sounds play once during playback and
  scrubbing stays silent. Tests cover exact thresholds, completion boundaries,
  result saving, replay navigation, finite animation and Reduced Motion.
- Phone layouts and the updated Figma goal dialog and gameplay HUD were
  rendered and visually reviewed. The 64.0 MB ARM64 release APK builds; both
  offline models, all 15 native ELF checks and 16KB ZIP alignment pass.
  APK SHA-256:
  `5a03bd0f70b299fc62d56b13bf01e75f5f8c5227766e9ac34b8af85a5614d021`.
- No Android device was connected. Physical camera, comfort, listening and
  performance checks remain pending.

## 2026-09-16 Sky Courier

- Added a fourth course: a 75-second pickup-and-delivery route for both controls.
  Collisions drop cargo without ending the route. Courier has separate records,
  live best targets, practice, progression through clean gates, original sounds,
  and version-4 replay support. Existing replay versions retain their rules.
- All 147 Flutter tests pass and static analysis is clean. Full ideal-input
  routes work at 1-, 4- and 9-second calibrated push-up cycles. Tests cover
  cargo capacity, drops, recovery, timer boundaries, practice exclusions,
  record separation, duplicate saves and backwards seeking with both controls.
  Actual saved-replay screens restore cargo and deliveries during scrubbing.
- Home, setup, flight, results, records and replay states were visually reviewed
  at 800×360. Figma now contains the four-course selector and Courier gameplay.
- The 64.0 MB ARM64 release APK builds. Both offline tracking models, all 15
  native ELF checks and 16KB ZIP alignment pass. APK SHA-256:
  `442a4365ab04e219329561f402e185e3f08a4acd83574ef7799d8462412954c9`.
- No Android device was connected. Physical camera, comfort, listening and
  performance checks remain pending.

## 2026-09-16 signature bird trails

- Added bubbles, hearts, leaves and stardust for the four birds, with matching
  crew previews. Trails follow simulation time, retain their shape when a
  multiplier turns them gold, and freeze decorative motion in Reduced Motion.
  The new Figma crew composition reuses the existing bird and button components.
- All 130 tests pass and analysis is clean. Pixel checks cover deterministic
  trails and Reduced Motion. All bird trails and crew states were visually
  inspected; equipping an unlocked bird persists correctly at 800×360.
- The 64.0 MB ARM64 release APK builds. Both offline models, all 15 native ELF
  alignment checks and 16KB ZIP alignment pass. Latest APK SHA-256:
  `95057580ab686da2b0fc93a73482d398c5bedb40fee5ecc2442012961dc4e323`.
- Physical camera, listening and performance checks remain pending without a
  connected Android device.

## 2026-09-16 live record chase and blooming gates

- Added course/control-specific personal-best targets during scored flights,
  tie recognition, a single record sound and finite pop, and refreshed targets
  on retry. Practice and first flights omit the target. Cleared and perfect gates
  gain flowers and pass seals; Cruise rings turn mint. Hit gates stay faded.
- All 128 Flutter tests pass; static analysis is clean. Four record integration
  scenarios cover score jumps, ties, retry, record separation and exclusions.
  Eleven UI/rendering tests were rerun with visual capture; small-phone HUDs,
  gate states and the updated Figma compositions were visually reviewed.
- The 63.9 MB ARM64 release APK builds. Both offline models and all 15 native
  ELF alignment checks pass, as does 16KB ZIP alignment. APK SHA-256:
  `12b236a284872a837218cc95f06b7cf85d57f7f256596a6aef33c921a04e6620`.
- No Android device was connected; camera feel, listening and physical
  performance checks remain pending.

## 2026-09-16 living skies and reward presentation

- Added windmill islands, striped balloons, paper lanterns and fireflies, with
  region crossfades and deterministic motion. Added a visible hit-recovery arc
  and timer, finite confetti portraits for scored rewards and completed trails,
  and a distinct completion sound in play and replay.
- All 124 Flutter tests pass and static analysis is clean. Pixel comparisons
  cover static Reduced Motion landmarks, replay determinism, continuous region
  transitions and finite portrait animations. Actual region, recovery and result
  screens were rendered and visually inspected. Figma gameplay designs include
  the editable balloon landmarks.
- The 63.9 MB ARM64 release APK builds. Both offline tracking models are present;
  all 15 native libraries pass ELF checks and 16KB ZIP alignment passes. APK
  SHA-256: `f19c051dc7bceebbbe1d0c7683f248cc4268edd394099d1ecf2e6e8f611c034b`.
- No Android device was connected. Device playtesting, frame-rate/thermal and
  audio listening checks remain pending.

## 2026-09-16 daily adventures

- Added an offline daily postcard with three rotating goals, seven days of
  recent cards, direct launch for either control, and a completion celebration.
  Progress derives from saved scored flights and survives reopening. No streak
  penalty or extra schema is introduced.
- All 118 Flutter tests pass and static analysis is clean. Five daily domain/
  persistence checks also pass under `TZ=America/New_York`. Coverage includes
  exclusions, duplicate saves, single-flight streaks, local date boundaries,
  reset, histories longer than ten runs, midnight and foreground refresh.
- Fresh, partial, stamped and next-day cards, home entry, and result celebration
  were rendered and inspected at 800×360. The Figma home entry reuses the existing
  button component and shared palette.
- ARM64 release build, both offline models, all 15 native ELF checks and 16KB
  ZIP alignment pass. Latest APK SHA-256:
  `e889ee515f49d2be46025eb2914e4e5229738968440df8ec0cb08a46fb1bd299`.
- No Android device was connected; physical camera, comfort, audio and
  performance validation remain pending.

## 2026-09-16 Star Magnet follow-up

- Added an eight-second star magnet earned by three perfect gates/rings in the
  star courses. Verified charging, non-stacking duration, pickup reach,
  collisions, practice pause/resume, and deterministic playback/seek behavior.
- New push-up aiming marks and stars follow the calibrated 0.15/0.85 height
  endpoints. Full 60-second trails at 1-, 4- and 9-second calibrated cycles
  finish with all gates perfect, an earned magnet, no missed star streak and
  intact health. Collision geometry stays unchanged. Replay versions 1 and 2
  retain their old targets and pickup rules after loading and serialization.
- All 109 Flutter tests pass; static analysis has no issues. Rendered setup,
  magnet charge/active HUD, and both motion preferences were visually inspected.
  The matching editable Figma state is linked in the arcade expansion notes.
- The 63.8 MB ARM64 release APK builds. Both offline models are present, all 15
  native ELF alignment checks pass, and 16KB ZIP alignment passes. Latest APK
  SHA-256: `603c121c0469d2c8d1a3684599be83d2356ed5dd0dc02741e7f28d04d7607629`.
- No Android device was connected. Physical camera control, sound listening,
  performance and comfort validation remain pending.

## 2026-09-16 arcade expansion

Classic, Star Trail and Cloud Cruise are implemented with separate scored
records, deterministic replay, new scenery and effects, and an eight-stamp
passport. Full details and Figma links are in [arcade expansion](arcade-expansion.md).

- All 100 Flutter tests passed. Static analysis reported no issues.
- Seven rendering/UI tests were rerun after the final scenery changes. Actual
  renders in `build/visual-review` were inspected for all courses, three regions,
  both motion preferences, small-phone layouts, results, next-stamp suggestions,
  bird unlocks, records and passport.
- Full simulated trails at calibrated 1-, 4- and 9-second push-up cycles finished
  with intact hearts/shield and no missed stars. This verifies course spacing
  against ideal calibrated input; it does not establish real camera comfort.
- SQLite versions 1 and 2 migrate to 3 while preserving Classic scores, settings
  and unlocks. Replay format 1 and legacy session summaries remain readable.
- The 63.7 MB ARM64 release APK builds. Both offline tracking models are present;
  all 15 packaged native libraries pass ELF alignment checks, and
  `zipalign -c -P 16 4` succeeds. APK SHA-256:
  `a36ca21599a09ee0c3d8871ddc53fe19c537046addf93609fc1451b85514177f`.
- No Android device was connected during this update. Physical push-up/smile
  play, saved camera playback, audio listening and frame-rate/thermal checks
  remain pending. The earlier tracking validation requirements still apply.

## Earlier device validation

Device: OnePlus CPH2585, Android API 36, connected by USB. Device page size: 4096 bytes.

## Physical milestone gate — pending

The first calibration build was installed and tested by the user. The initial screen did not clearly communicate that full-body calibration must finish before the bird moves. The user then reported that the full body was visible but the confidence gate still rejected it. The revised implementation lowers the per-joint visibility threshold from 0.60 to 0.30, allows a small edge tolerance, relaxes perspective-sensitive alignment and elbow thresholds, and identifies missing joints individually. Standing/crouching checks remain.

Usable continuous control while looking down, viewing comfort and approaching-obstacle readability have **not yet been demonstrated**. This is a physical validation gate, not a software unit-test result. Do not report the polished offline milestone as device-validated until it passes.

## Tracking observations

- 2026-09-11 "bird jumps from 100% to 50% when I bend a little": the reported
  match ran in the `make run` debug build (SQLite run `1789133892972553-pushUp`,
  score 1, 11.7 s, no trace), so that game itself is not captured. The backed-up
  16:08 front-view session reproduces the fault with the shipped code: its
  calibration had learned lift 1.181–1.451 with endpoint angles 175.5°/166.7°,
  i.e. two shoulder wobbles rather than push-ups, because the primary height
  signal (wrist distance from the shoulder–hip line over arm length) does not
  track depth in that placement. The extended-arm switch (≥172° for 120 ms)
  masked this by pinning the output to 1; releasing it below 166° on a slight
  bend handed control back to the garbage range, which read ~0.5 at a genuine
  top. The side-view path was worse: `height = extended ? 1 : target`, a hard
  switch with no continuity.
- Cue analysis over every real recording (Fisher d′ between hand-labelled top
  and bottom windows): 2D elbow angle 13–18 in this player's front view and
  6–8 in the side game; front shoulder drop 10–14; MediaPipe z and 3D angles
  3–7 (rejected); shoulder-width and elbow-flare cues change sign between
  sessions (rejected). Depth is now a d′²-weighted fusion of robust linear cue
  models learned during calibration (see README), segmented on the arm angle
  with a steady-hold requirement, 15° descent, 30° minimum excursion, 0.7 s
  minimum cycle and a shallow-return reset; smoothing is median-3 plus a One
  Euro filter. A Python prototype of the same algorithm was validated first
  (outside the repo); the Dart port reproduces it frame for frame on the
  16:08 session (calibration completes at 362.16 s on the two real push-ups,
  elbow model 175.8°→144.5°, drop 1.32→0.91) and on the side game (the one
  deep push-up is cycle 1 at 27.8 s; the 17–24 s and 28–32 s straight-arm
  holds preview 1.00; the settling wobbles at 6–13 s produce no cycle).
- Replaying the 16:08 session after its calibration: every second of the
  369–370 s and 374–376 s straight-arm holds outputs 1.00 (min 1.00), the
  372 s bottom outputs 0.00, and the partial 377–380 s bends read 0.4–0.6
  with elbows at 155–170°, which is what the player was doing. Fixture
  regressions: `front_pushups` held top 1.000 / held bottom 0.000 (three cue
  models, d′ 12/9.9/9.8); `front_top_hold` controlled by the models learned
  from `front_pushups` gives top median 1.000, p10 > 0.95, bottom < 0.1, and
  its wobble stays at zero cycles until the real push-up (cycle 1 at 124.9 s);
  `front_extended_top` keeps zero cycles and preview 1.00 for the whole
  straight-arm hold; `front_calibration_hold` preview 1.00 throughout;
  `last_game_top` with learned-style elbow models gives held-top median 1.000,
  p10 > 0.95, minimum > 0.85 over 27 s of holds, bottom median < 0.1, one rep.
  Synthetic coverage adds a quick bounce, a 20° dip, a folded-landmark arm,
  disagreeing arms and a lean with 171° elbows. All 50 tests and analysis pass.
  The diagnostics profile APK (`app-profile.apk`, 83 MB) built, but the phone
  had dropped off USB/ADB before it could be installed; install it with
  `adb install -r build/app/outputs/flutter-apk/app-profile.apk` (or `make
  diag`) once reconnected. Physical acceptance of this rewrite is pending; the
  next match must run that build so its trace can be replayed.
- 2026-09-11 16:46 "push back up with stretched arms": the reported retry ran
  in the `make run` debug build, which records no trace, and the phone's two
  retained logs were smile-mode sessions, so that attempt itself is not
  captured. The backed-up 16:08 front-view calibration session (8569 frames)
  reproduces the report with the then-current code: after a 15 s straight-arm
  hold (elbow 173–180°, lift 1.29–1.37), one noisy dip at 310.8 s satisfied
  the descent gate against the running-max peak (1.372) and peak elbow (179.9°);
  the calibrator then sat in `raise` showing "Push back up · 1 of 2" with
  preview 0.00 for 2.3 s while both arms stayed at 172–178°. Its return
  threshold (peak − 18 % of range) was above the noisy height of a real
  straight-arm top, so the return after the actual push-up at 318.0 s was only
  confirmed at 318.9 s and the second cycle never completed in that stretch.
- The straight-arm rule (172° for 120 ms, release below 166°) now lives in one
  detector shared by calibration and control. During calibration, stretched
  arms block descent detection, complete the return, and pin the preview to
  the top. Replaying the same session: zero stretches ≥ 0.4 s of `raise` with
  elbow ≥ 172° (previously three), the 310.9–313.1 s hold stays `lower` at
  preview 1.00, cycle 1 confirms at 318.3 s, and calibration completes at
  324.3 s (range 1.095–1.422, endpoint angles 155.3°/175.6°).
  `test/fixtures/front_extended_top.json` preserves 295.0–325.5 s of that
  session body-only; its regression and a synthetic leaning straight-arm
  regression both fail on the previous calibrator and pass now. All 47 tests
  and static analysis pass. The diagnostics profile build was installed at
  device time 16:46:45; `make diag` and `make logs` wrap that build and log
  retrieval. Physical acceptance of this correction is pending.
- 2026-09-11 16:15 scored-game follow-up: the on-phone `latest.log` retained
  all 654 body frames, calibration/control records, and a collision after 6.05 s.
  The controller had locked to **side** view and learned height 0.409–0.614 with
  nearly identical endpoint angles (165.7° top, 160.8° bottom). In the last 3.5 s,
  both tracked arms remained extended (median angles 177.0° and 175.7°), while
  live output stayed around 0–0.52. There is no matching image of this newest
  game; the images at `/tmp/push-up-bird-diagnostics/inverted-top` belong to the
  preceding camera session. The complete original logs are backed up locally
  under `/tmp/push-up-bird-diagnostics/top-investigation-1618`.
- `test/fixtures/last_game_top.json` preserves that game's body-only landmarks.
  Replaying its gameplay frames with the logged, rounded endpoint calibration
  reproduced a held-top median of **0.247**. Sustained near-straight-arm top
  recognition now works in either view and overrides contradictory projected
  height; the same regression reaches **1.000**. The two scale references were
  unavailable in the old control log and are approximated in this test; it is
  a regression against captured poses, not an exact reproduction of every
  controller event in the original run.
- The preceding session and existing `front_calibration_hold` fixture also
  reproduced a held top becoming `raise` with preview 0.000. Calibration now
  requires relative arm bending before accepting descent and keeps its preview
  at the top while waiting. The older `front_top_hold` recording had counted
  initial top wobble as its first repetition; it now correctly has one cycle
  by 121 s. Its original control regression is retained using the old calibration
  explicitly, rather than continuing to demand premature calibration success.
- Development tracing now preserves full precision and exact sample receipt
  times, native timestamps, complete calibration records and flight-reset events.
  Optional native image capture keeps 120 small images per session, one/second,
  for the latest two sessions, with matching sensor timestamps. Both mechanisms
  are disabled in release mode, including camera-lab posture logging.
- Static analysis and all 45 Flutter tests pass. Profile and release APKs build;
  the release build with both diagnostic defines supplied still sets native
  image capture to false and disables the Dart diagnostic sink. Both offline
  models, all 15 native ELF alignments, and 16KB ZIP alignment pass.
  The phone disconnected during the investigation;
  installation, physical top/bottom control, and device image-capture validation
  remain pending for this revision.

- 2026-09-11 subsequent live top retry **reproduced the remaining defect** in the
  installed 15:56:33 build. Screenshot frame-22 shows extended arms with the
  control-check bird near the middle. Calibration learned only an 11.4° angle
  difference (165.2°–176.6°), disabling the correction's former 25° gate. Output
  during the three-second top hold had median 0.601 and 10th percentile 0.514.
  The complete relevant recording is preserved as 522 body-only frames in
  `test/fixtures/front_top_hold.json`; its test failed at 0.602 before the fix.
- Top confirmation now needs only an 8° learned difference; the continuous angle
  blend still needs 25°. A filtered elbow angle, 3°–6° personal top tolerance,
  120 ms confirmation and separate release thresholds stabilize the endpoint.
  Replaying that exact live recording now yields top median 1.000 and 10th
  percentile 0.999, while the following held bottom remains 0.000. No synthetic
  coordinate transformation is used for this regression. These are replay
  results; physical acceptance of the final correction remains pending.
- Long diagnostic sessions now rotate at the size limit instead of dropping
  every subsequent frame. The latest and preceding chunks remain bounded at
  4 MiB each, with a regression checking that the newest data survives rotation.
- The final correction passes static analysis and all 42 Flutter tests.
- The final profile build was installed successfully at device time 16:07:40.
  Camera startup, persisted raw/control logs, and the absence of Flutter/native
  startup errors were checked. Its matching release APK passes bundled-model,
  native ELF and 16KB ZIP-alignment checks. The requested physical retry remains
  the acceptance check for the final correction.
- 2026-09-11 full-top follow-up: the saved latest scored push-up run ended in a
  collision after 6.047 seconds, but its detailed Android trace had already
  rolled out of logcat. The requested fresh retry captured calibration only
  (one complete cycle, then tracking loss), so it cannot establish the exact
  cause of that scored run. Screenshots show shoulders clipping the camera
  frame during parts of the fresh attempt.
- A deterministic regression widened the earlier recorded extended-arm top
  pose's horizontal projection by 15%. The former interpreter mapped that hold
  to 0.480, reproducing the reported mid-height symptom. The revised interpreter
  learns arm extension at both calibration endpoints, blends it with frontal
  height when the learned angles are clearly separated, and confirms the top
  for 120 ms. The same test now exceeds 0.95; the unmodified recorded top exceeds
  0.95 and the recorded bottom remains below 0.25. This synthetic perspective
  perturbation is a regression, not a measurement of the lost latest-game trace.
- The recorded calibration also demonstrated a partial second movement being
  accepted prematurely. Requiring the second excursion to span at least 55% of
  the first delays completion until the next full movement. That recording now
  learns a height range of 0.603–1.506 and elbow endpoints of 101.2°–171.3°.
- Opt-in diagnostic builds retain the latest and preceding log chunks in private
  app storage, capped at 4 MiB each, including calibration range, learned elbow
  endpoints, control height and end reason. Images are still captured separately
  through ADB. Starting calibration also clears the previous run's movement
  output so diagnostics cannot present a stale height as the new calibration.
- The full-top revision passes static analysis and all 40 Flutter tests,
  including both new captured-pose regressions and session-log persistence,
  rotation and size bounds. The profile build was installed on CPH2585 at device
  time 15:56:33. Camera startup and persistent trace/control records in
  `files/tracking_diagnostics/latest.log` were verified on the phone. Physical
  movement verification of this revision is pending.
- The matching full-top release APK builds without diagnostic logging. Both
  bundled models, all 15 native ELF load alignments, and 16KB ZIP alignment pass.
- 2026-09-11 live perspective/countdown investigation: ADB camera screenshots
  confirmed a frontal push-up view with visible arm landmarks. The previous
  torso-line distance was not a reliable altitude signal from that perspective:
  the held top could read low despite strong joint confidence. A 424-frame
  capture is preserved as body-only landmarks in `test/fixtures/front_pushups.json`.
  The original Android log truncated after the hips, so missing leg observations
  are explicitly unavailable in this fixture. Face landmarks and images are not
  included. The front-view measurement uses shoulder height above the hands,
  normalized by shoulder width, with perspective fixed during calibration.
  The replay's median held-top output changed from 0.525 to 0.889; held-bottom
  output changed from 0.054 to 0.000. The actual live retry remains the physical
  acceptance check, beyond this captured-data regression.
- A second regression reproduced endless countdown resets at 20 Hz with 160 ms
  sensor-to-Dart delay. The prior 200 ms freshness check expired in the gap
  between valid packets. Samples still must be fresh when consumed, but stream
  availability now uses receipt time. Short invalid periods pause the countdown;
  a gap over 500 ms resets it. A live smile-mode trace reached `phase=playing`
  after this change, but push-up gameplay acceptance is still pending.
- Live screenshots also showed a blank playfield and repeated Flutter render
  exceptions. `test/bird_game_test.dart` reproduced the actual renderer failure:
  `Gradient.linear` had three colors without explicit stops. Adding `[0, .5, 1]`
  fixes the failure. Native logs also showed bitmap dimensions being read after
  `MPImage.close()`; dimensions are now captured before releasing the image.
- This revision passes static analysis and all 37 tests, including the actual
  front-view replay, rotation/mirroring/occlusion, delayed and missing camera
  packets, stale-packet rejection, and a mounted game-rendering regression.
  Profile builds use `TRACKING_DIAGNOSTICS=true` for compact body landmarks plus
  calibration, control, countdown, and end-reason logs. Normal builds omit those
  traces. Screenshots were captured locally through ADB with the user's request.
- The profile build containing the perspective, countdown, gradient and bitmap
  lifetime fixes was installed successfully on CPH2585 at device time 15:35:34.
  The app was opened for another physical retry; its final push-up result has
  not yet been reported. All acceptance claims above distinguish replay/tests
  from live physical gameplay.
- The matching release APK (without landmark logging) builds successfully; both
  bundled models, all 15 native ELF load alignments, and 16KB ZIP alignment pass.
- 2026-09-11 movement-detection fix: three deterministic regressions reproduced
  ignored continuous motion with a comfortable top position (projected elbow
  about 126 degrees), frozen control when the initially selected side became
  occluded, and false camera-movement rejection from torso foreshortening.
  Calibration now learns two measured height excursions with relative return
  thresholds, rather than fixed elbow angles and endpoint holds. Side selection
  falls back to another usable side; camera-distance rejection requires agreeing
  arm and torso scale changes sustained for 300 ms. A three-frame median and
  time-based smoothing suppress isolated spikes. Brief missing frames preserve
  calibration progress; gaps over 500 ms discard incomplete movements. The bird
  previews detected height during calibration in both setup and the camera lab.
- This revision passes `flutter analyze --no-pub` and all 31 Flutter tests.
  Tracking coverage includes 12/20/30 Hz synthetic streams, mirrored landscape
  frames, ±45-degree roll, smaller movement ranges, jitter, brief frame loss,
  side recovery, duplicate timestamps, long gaps, actual scale changes, and
  calibration-to-game bird movement. A deterministic input step reaches 90% of
  the new control height within 160 ms; this excludes camera/inference latency
  and is not a physical device performance measurement.
- The updated arm64 release APK builds successfully. Both offline models are
  packaged; all 15 native libraries pass the ELF alignment check, and Android
  `zipalign -c -P 16 4` passes. The phone disconnected from ADB before installation,
  so this APK has not been installed or visually checked on the device.
- The available phone log included a post-calibration pose rejected at an
  arm-to-torso angle of 174 degrees. It does not contain a complete movement
  trace, so the synthetic regressions do not establish every cause of this
  user's physical tracking failure. Camera-lab diagnostics now include measured
  lift, output height, cycle count, and the current calibration/control rejection
  reason. Physical validation of the revised controller remains pending.
- Earlier positioning fix: a deterministic 45-degree rotated push-up fixture
  reproduced the exact "Get into a side-on push-up position" rejection. The
  screen-horizontal torso and wrist/ankle-height gates were replaced by a broad
  arm-to-torso angle check. Wrist height is now measured perpendicular to the
  torso, preserving control under camera roll. Reliable leg checks reject only
  pronounced folds; missing or uncertain knees/ankles are optional.
- The previous app did not log posture measurements; its logs could not explain
  the user's individual rejection. The camera lab now displays and logs selected
  side, shoulder/elbow/wrist/hip confidence, arm-to-torso angle, elbow angle,
  sample age, rejection reason and calibration step once per second. It does not
  log images. The revised build was installed successfully; another physical
  attempt is pending. The startup smoke check was inconclusive because the lab
  was not the foreground screen when it ran.

- Initial debug preview: approximately 20.8 updates/s, sensor-to-Dart p95 160 ms with only upper body in view.
- Initial optimized preview with obscured/no complete body: approximately 18 updates/s, p95 161 ms.
- These are exploratory UI readings, not a sustained valid-pose performance acceptance test. The targets (20+ Hz, p95 camera-to-control <150 ms and 60 FPS) remain to be measured over sustained gameplay.
- Native CameraX sensor timestamps are mapped from elapsedRealtime into the Dart monotonic clock using five round trips and the lowest-RTT midpoint. If a camera reports an unknown sensor clock, timing is explicitly labeled analyzer-to-Dart; it must not be represented as camera-to-control latency.

## Release-only camera regression

`python3 tool/camera_start_smoke.py` reproduced the actual model startup failures on the phone:
1. R8 removed Protobuf Lite reflective fields (`SystemInfo.platform_`).
2. R8 renamed MediaPipe JNI classes (`com.google.mediapipe.framework.Graph`).
3. R8 inlined/renamed Flogger caller frames, breaking Graph's static logger initialization.

`android/app/proguard-rules.pro` preserves these reflection/JNI/stack-inspection boundaries. The optimized camera preview and live sample rate were visually verified after the fixes. UIAutomator's idle heuristic cannot reliably dump a continuously updating Flutter camera UI; use the live preview and sample-count diagnostics as the final startup signal, not a stale hierarchy file.

## Completed automated checks

- Synthetic body and face tracking: looking down, one-side occlusion, missing/low-confidence joints, stale/future frames, calibration, continuous height, repetitions and smile hysteresis.
- Deterministic game rules: alternating gaps, measured cadence, collisions, scoring, stale-input grace, posture loss, backgrounding, practice pause/resume and mode separation.
- Real SQLite: idempotent run writes, separate records, practice exclusion, all three unlock thresholds, locked-bird rejection, reset, close/reopen persistence and v1-to-v2 migration.
- Initial arm64 release APK: all 15 packaged native libraries have ELF LOAD segment alignment >=16KB. Both tracking models are packaged. Repeat against the final APK with `python3 tool/check_android_apk.py` and Android `zipalign -c -P 16 -v 4`.

## Still required before final milestone acceptance

- Physical calibration and viewing gate above.
- Sustained valid-body and face tracking performance with camera-to-consumed-control latency and Flutter frame timings.
- Full camera denial, revocation, camera switch, detector switch and background/resume lifecycle validation.
- All final screens visually inspected on device.
- Runtime test on a 16KB-page Android device/emulator (the connected phone is 4KB).
- iOS camera implementation and build/device validation on macOS/Xcode, explicitly a later milestone.

## Saved session replays

Automated checks cover input-journal round trips in both modes, exact backward
seeks, pauses and interruptions, atomic save/retry, raw video copy and deletion,
explicit saving after camera finalization, and replay controls on an 800×360
landscape viewport. The Android APK compiles with CameraX video capture.

Device acceptance remains required (no device connected during implementation):

- Finish and save both a scored and a practice flight. Reopen Records → Saved
  sessions after restarting the app; compare the bird, passages and score.
- Switch Corner camera → Camera background → Gameplay only while playing and
  paused. Tap the viewing area to hide/show the overlaid controls and verify that
  the video and game do not resize. Buttons, menus and scrubbing must not dismiss
  the controls. Move the camera corner, scrub backward/forward, restart, and check
  0.5×/1×/1.5×/2× plus sound on/off. Check camera/game alignment at the start,
  middle and end; CameraX's recording-start event establishes the clock anchor.
- Pause practice, background/resume, then save. Verify both camera segments and
  the explicit camera-paused gap. Background a scored flight and save its ending.
- Leave results without saving, retry, force-stop during a recording, and reopen.
  Verify unsaved cache footage is removed; saved clips remain available.
- Try low storage, unavailable video capture, missing/damaged clips, and repeated
  taps on Save. Gameplay-only replay remains available if camera capture fails.
- Measure tracking rate, inference latency and rendering FPS with video capture
  enabled on both cameras. Some HALs cannot bind preview, analysis and recording
  together; those devices fall back to gameplay-only replay with a visible notice.


### Optional microphone audio

Automated tests cover default-off capture with permission already granted,
explicit opt-in, remembered preferences, denial/permanent denial, absent
microphones, bridge failure, revocation, duplicate requests, and capture waiting
for the permission response. Storage tests verify audio metadata and old silent
sessions. UI tests cover inline permission rationale and blocked-permission
layout, independent recorded/game audio mute, and recorded audio in gameplay-only
view. Native camera capture builds with RECORD_AUDIO declared and hardware
microphone availability optional.

On an Android device, verify the actual system permission dialog only appears
when the optional switch is enabled. Grant, deny, deny again, and try one-time
permission and revocation in Settings. Confirm normal gameplay and video saving
continue without microphone access, and no request appears on retry/resume.
Record speech in each mode, save/reopen, and listen while seeking, changing speed,
pausing, changing visual modes and muting each sound source independently. Also
check foreground practice breaks, background/resume, another app using the mic,
and Android's global microphone privacy toggle. No device was connected during
implementation, so physical microphone capture/listening checks remain pending.

### Tap & Fly

Touch is a full control mode for all four courses. It starts without creating a
native tracking source, showing calibration or requesting camera/microphone
permissions. Pointer-down flaps respond on the next game frame; holding does not
repeat them. Countdown, pause, resume, background, frame interruption and retry
checks cover pending-input clearing and the existing scored/practice rules.

Automated checks cover separate SQLite records and flap totals, unlock/passport
progress, gameplay-only session saving, deterministic replay and backward
seeking. The existing courier, cloud-friend, star-trio, bird-motion and highlight
replay checks also run with touch. Widget checks exercise Home → touch setup →
flight → results → saved replay → Records at 640×360 and 800×360, with a tracking
factory that fails if called. Screenshots are in `build/visual-review/touch-*`
when tests run with `--dart-define=CAPTURE_VISUALS=true`.

Physical touchscreen feel and interruption handling on an Android device still
need a device check.
