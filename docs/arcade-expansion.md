# Sky Club arcade update

## Courses and controls

The camera activity and the arcade course are independent. Choose Push-Up Flight
or Grin & Glide in any of these courses:

| Course | Objective | Collisions | Records |
| --- | --- | --- | --- |
| Classic | Clear as many gates as possible | One ends the flight | Separate best for each control |
| Star Trail | Collect star points during a 60-second flight | Shield, then three hearts | Separate best for each control |
| Sky Courier | Deliver letters during a 75-second route | Drop carried letter; keep flying | Separate delivery best for each control |
| Cloud Cruise | Discover cloud friends and follow stars at your own pace | None; screen edges gently return the bird | Always practice |

Classic retains its original speed, score units, seeded obstacle generation and
collision behavior. A perfect pass means staying within 0.075 viewport heights
of the aiming mark throughout the crossing. For new push-up flights, the mark
and stars follow the calibrated top and bottom endpoints (0.15 and 0.85 viewport
heights). Smile flights aim at the gap center. Perfect passes and every five gates
have visual celebrations without inflating the Classic obstacle score.

Star Trail starts with three hearts and a shield. Collecting six consecutive stars
raises the multiplier to 2×; twelve raises it to 3×. The threshold pickup earns the
new multiplier. A missed star or a collision resets the current streak, but keeps
the best streak. Every ninth collected star restores an absent shield. A shield
save or lost heart grants 1.5 seconds of protection, and a struck gate can only
hit once. Struck gates do not earn cosmetic unlock progress. Star Trail's wider
gaps, 10% slower scroll and extra 1.3 seconds between passages accommodate the
leading constellation without requiring faster calibrated movement.

Cloud Cruise has open rings, gentler smile gravity, 25% slower scroll, longer
spacing and no end timer. The simulation, controller, results and replay journal
all enforce practice status for this course. Tracking loss pauses; Resume counts
you in again. Pause → Finish flight opens results, where a local replay can be
saved. Cruise stars and gates cannot earn records, stamps or bird unlocks.

## Feedback and progression

- Sunrise Isles, Peach Horizon and Twilight Garden blend in a repeating cycle.
  The scene uses procedural layers, clouds, distant birds, a sun/moon, stars,
  floating islands and mossy stone gates; it needs no network or new image model.
- Star pickups glow. Shields surround the bird. Precision, milestones, shield
  saves and hits produce local bursts and text; each bird has a colored trail.
  Streak upgrades announce 2× and 3× star power, and the maximum multiplier adds
  three orbiting stars. A single visual and musical cue marks ten seconds left.
- Reduced Motion disables decorative drifting, burst particles, bird tilt/squash
  and pickup pulsing, and freezes signature trail movement. Collision and
  collection positions are identical.
- Original synthesized star, perfect-pass, shield and impact sounds are included
  in `tool/generate_audio.py`. Effects and music still obey Settings. Music resumes
  when a paused flight resumes; replay uses the same new effect cues.
- Sky Passport contains eight durable goals derived from saved scored flights.
  Progress combines both controls where appropriate. A Classic-only captain
  badge never reads Star Trail points. Duplicate saves cannot award extra progress.
- Retry snapshots the latest record and earned stamps, so a later attempt does
  not repeat the previous flight's personal-best or stamp announcement.
- A newly unlocked bird appears on the results screen with a link to the flock.
  Flights without a new reward suggest the nearest unfinished passport stamp.
  Course selection survives visits to results, records, settings and the flock
  within the same app session.
- Secondary text uses the darker shared `color/muted` token in Flutter and Figma
  to remain readable on the blue sky as well as the cream panels.

## Storage and replay compatibility

SQLite schema 3 adds course, cleared gates, stars, longest combo and perfect passes.
Migration copies existing scores into cleared gates, preserves existing settings
and unlocks, and labels legacy records Classic. Bird unlocks use cleared gates
across scored courses, not multiplied star points.

Replay formats 2 through 5 record the course. Format 4 adds Sky Courier and
format 5 adds cloud friends. Formats 1 through 4 retain their recorded rules.
Format 1 uses Classic and
its original input journal and random seed. Star Trail and Cloud Cruise use the
same deterministic simulation during playback and seeking. Session summaries
persist course and the new metrics; missing fields retain legacy defaults.

## Design source

The existing Figma file was extended without replacing the original screen:

- [Adventure Home](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=35-78)
- [Star Trail gameplay direction](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=36-154)

Both reuse Sky Club typography, color variables, bird artwork and button
components. `design/star-trail-world.svg` is the editable scenery source for the
Figma gameplay direction. The running Flutter scene uses the richer procedural
renderer, and its HUD is adapted to overlay full-screen gameplay.

## Verification

The September 16 update passed all 100 Flutter tests and static analysis. The
seven scene/UI tests were rerun after the last scenery adjustment, with rendered
screenshots checked at 1000×450 and 800×360. Coverage includes a complete Star
Trail at 1-, 4- and 9-second calibrated push-up cycles, legacy SQLite migrations,
old and new saved sessions, replay seeking, reward thresholds, bird unlock
announcements and relaxed pause/finish behavior.

Run the full test suite and analyzer:

```sh
flutter analyze
flutter test
```

Generate actual rendered UI review images (not mock screenshots):

```sh
flutter test --dart-define=CAPTURE_VISUALS=true test/experience_ui_test.dart
```

Images are written to `build/visual-review/`: course menus, Star Trail setup,
flight and results, next goals, bird unlocks, both motion settings in three
regions, star power, Cruise flight/pause/results, records and passport.
The UI tests cover 1000×450 and 800×360 landscape surfaces.

Tests cover streak thresholds and misses, shield absorption/recharge, repeated
hits, the timed finish, calibrated transition windows, pause/resume, Cruise
boundary recovery and practice enforcement, deterministic replay and backward
seeking, old replay compatibility, SQLite migration and separate records,
passport progress and native session saving. Existing tracking regression replays
remain part of the full suite.

A release ARM64 APK is built locally. Physical camera playtesting and device frame
rate/thermal testing remain pending: no Android device was connected during this
update. Follow the existing device checks in `docs/validation.md`, including both
control methods, a full Star Trail, Cruise pause/resume and saved camera replay.

## Star Magnet follow-up

Three perfect gates in Star Trail, or three perfect rings in Cloud Cruise,
activate an eight-second magnet. Charge survives ordinary passes and bumps.
The magnet expands the star pickup radius from 0.085 to 0.20 viewport heights;
each star still scores once and follows the existing streak/shield rules.
Perfect passes during the active window do not stack or extend it. The magnet
does not absorb collisions. Practice pauses and resume countdowns preserve its
remaining time because the effect uses the simulation clock.

The renderer shows a translucent lavender field, curved lines to nearby stars,
an activation burst and sound, plus a countdown in the HUD. Reduced Motion keeps
the field static. An editable [Star Magnet design state](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=45-176)
uses the existing Figma components and palette; its field source is
`design/star-magnet-field.svg`.

Replay format 3 enables magnets and the calibrated push-up aiming marks. Formats
1 and 2 retain their recorded version when loaded and serialized, so playback
and backward seeking continue to use their old targets and pickup behavior.

This follow-up passes all 109 Flutter tests and static analysis. Tests cover
magnet charge and expiry, non-stacking effects, pickup reach, collisions, practice
pause/resume, legacy geometry, and deterministic replay. Complete push-up trails
at 1-, 4- and 9-second calibrated cycles finish with all cleared gates perfect,
an earned magnet, intact health, and no missed star streak.

## Daily adventure postcards

The home screen's Today badge opens three rotating goals and a themed postcard.
Complete all three to stamp it. Goals cover scored flights or cleared gates,
collected stars or a single-flight star streak, and perfect passes or a full
Star Trail. Every combination can be completed with either push-ups or smiles;
the screen launches Star Trail directly using the chosen control. Classic
flights contribute to the goals they support. Practice and Cloud Cruise do not.

Cards are calculated from persisted scored flights, using local calendar dates.
They do not rely on the ten-entry recent-flights list. Duplicate IDs cannot
inflate progress. The previous six days and today appear together; there is no
consecutive-day penalty. Resetting progress clears the cards. No network,
notifications, account, currency or extra database schema is needed.

The app refreshes the card at the next minute after a local day change, or when
returning to the foreground. Flight results and the repository share the same
clock. Completing a card shows a results-screen link and reward sound; retrying
does not announce an already-stamped card again. Bird unlocks still have first
priority when several rewards arrive together.

All 118 tests pass and static analysis is clean. Daily tests cover goal rotation,
both controls, duplicate saves, practice exclusion, single-flight streaks, local
date boundaries, persistence, more than ten saved flights, reset, midnight and
foreground rollover. Domain checks also pass under `TZ=America/New_York`.
The fresh, partial, complete and next-day screens and the completion announcement
were rendered and inspected at 800×360. Generate these with:

```sh
flutter test --dart-define=CAPTURE_VISUALS=true test/daily_adventure_ui_test.dart
```

## Living skies and celebratory finishes

Sunrise Isles now has small windmill islands. Peach Horizon has drifting striped
balloons, and Twilight Garden has paper lanterns and mint-colored fireflies.
Landmarks blend with the existing five-second palette transitions, including the
wrap from twilight to sunrise. They sit behind gameplay objects, have no collision
or reward behavior, and use simulation time and distance so pauses and replays
stay consistent. Reduced Motion freezes all landmark movement.

Star Trail's brief hit protection has a shrinking ring around the bird and a
remaining-time readout. The bird remains fully visible throughout; there is no
flashing. A completed trail has its own rising completion sound. Results show a
finite confetti portrait when a scored flight earns a record, reward, or complete
trail. Reduced Motion presents the finished decoration immediately. The buttons
remain usable during the animation.

All 124 tests pass and analysis is clean. Pixel-level rendering checks verify
deterministic landmarks, static Reduced Motion frames, continuous region fades,
and finite portrait animation. The actual region scenes, recovery HUD and result
portraits were visually reviewed. The Figma gameplay compositions include the
Peach Horizon balloon source at `design/peach-balloons.svg`.

## Chase your record and leave a little garden

Scored Classic and Star Trail flights now show a compact personal-best target
beside the score. It counts down to **beating** the existing best, recognizes a
tie, and turns gold with a short sound and a finite pop when the record is passed.
The baseline is specific to the current course and control and remains fixed for
the flight. Retry picks up the newly saved best. Practice and Cloud Cruise omit
the target; the first scored flight establishes a record without a zero target.
Reduced Motion keeps the celebration static. The cue is live presentation, so it
does not change scoring or the input journal used by replays.

Successfully cleared towers grow a cream flower and display a check seal. A
perfect gate grows three gold flowers and a gold star seal. Cloud Cruise rings
turn mint and show the same pass seal. Hit gates stay faded without these rewards.
The decorations occupy the existing solid rims and cleared passage, and do not
change collision geometry. They derive directly from gate state, including in
saved replays, with no additional animation or persistence.

All 128 tests pass; static analysis is clean. Record integration checks cover
course/control separation, ties, multi-point jumps, a single cue per flight,
updated targets after retry, and practice/Cruise exclusion. HUDs were checked at
800×360; clean, perfect and hit gate renders were visually inspected. The existing
Figma gameplay compositions contain editable record states and the blooming gate
source at `design/cleared-gate.svg`.

## Signature bird trails

Pip leaves sunshine bubbles, Peaches leaves hearts, Minty leaves small leaves,
and Orbit leaves stardust. These cosmetic marks use simulation time and have no
effect on difficulty, collision or score. Multipliers still turn trails gold;
each bird keeps its own shape. Reduced Motion freezes the decorative movement
while keeping the bird's signature visible.

The crew screen previews every trail and names it. Locked birds remain faded;
unlocking and equipping still use the existing saved progression. Labels now
consistently say gates. The Figma crew composition reuses existing bird and
button components: [Signature trails](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=55-196).

All 130 tests pass and analysis is clean. Pixel comparisons check all four
trails for frozen Reduced Motion and deterministic animation. The crew screen,
equipping an unlocked bird, and all four flight trails were rendered and reviewed
at landscape phone sizes.

## Sky Courier

A fourth course adds a 75-second delivery route for either control. Gates alternate
between pickup and postbox stops. Clearing a pickup gate while empty loads one
letter; clearing a postbox while carrying it earns one delivery and empties the
satchel. Cargo cannot stack. A postbox without a letter earns no delivery. The
score counts deliveries; clean gates and perfect passes retain their usual
progression meaning.

A collision marks that gate as hit and drops any carried letter. The route keeps
running, with 1.5 seconds of recovery protection. Hit gates never award cargo,
deliveries or unlock progress. The next clean pickup offers another chance.
This course has no stars, multipliers, magnets or heart limit. Its wider gaps,
10% slower scroll and extra spacing leave room for the calibrated movement.

The HUD displays cargo status, remaining time and an existing personal-best
target. Pickup and postbox signs differ in shape and color; a letter hangs below
the bird while aboard. Pickup and delivery have distinct sounds in play and
replay. The final ten-second cue starts at 65 seconds. Practice pauses and
preserves cargo and clock; scored breaks or tracking interruptions end the run.

Courier records are separate for each control and from all other courses.
Clean gates contribute to bird unlocks, and scored flights and perfect passes
contribute to applicable daily/passport goals. Courier completions do not count
as completed Star Trails. Practice remains excluded. Existing schema 3 stores
this new course by its stable name; no database migration is needed.

All 147 tests pass and static analysis is clean. New checks cover alternating
stops, cargo capacity, misses, collisions, recovery, timer boundaries, practice,
both controls, separate records, duplicate saves, and backward replay seeking.
Full simulated routes finish with no cargo loss at 1-, 4- and 9-second calibrated
push-up cycles. This validates ideal input pacing; physical camera comfort still
needs a device playtest. Existing version-3 Star Trails keep their score and
physics under the new reader.

Home, both setup screens, empty/carrying/dropped cargo, results, records and actual
saved replays were rendered and reviewed at 800×360. The existing Figma home now
has four course buttons, and the new [Courier gameplay composition](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=58-277)
reuses the existing bird and scenery with editable pickup/postbox artwork from
`design/courier-world.svg`.

## Three wings for a flight

Every scored course now has three goals that belong to a single flight:

| Course | Wing one | Wing two | Wing three |
| --- | --- | --- | --- |
| Classic | Clear 5 gates | Clear 10 gates | Clear 25 gates |
| Star Trail | Collect 12 stars | Reach a 6-star streak | Finish the 60-second trail |
| Sky Courier | Deliver 1 letter | Deliver 3 letters | Finish the 75-second route |

Goals earn independently; a Star Trail can earn its streak wing before the
12-star wing. Losing a current streak does not remove a wing already earned by
the best streak. Timed completion requires both the full duration and a completed
run. Stopping early cannot earn the finish wing. Practice and Cloud Cruise omit
the goals and their celebrations.

The Home footer opens the course's goals. A compact live counter sits clear of
the bird, with one short sound and finite pop when a goal is reached. Reduced
Motion keeps the counter static. Results and recent flights open goal details,
including the next target to try or an all-three celebration. Saved replays
reconstruct the wing count while seeking, and play the cue when crossing a goal
during playback; scrubbing remains silent. Wings derive from existing saved
statistics, so they need no schema migration, extra counters or replay version.
They do not affect course scores, unlock thresholds or daily goals.

The results screen now keeps Home, Save session and Fly again in a fixed row.
Saving changes the middle action to Watch replay, which opens that saved flight
directly. Longer statistics and error details can scroll without hiding actions.

All 155 tests pass and analysis is clean. Coverage includes exact thresholds,
independent goals, actual completion, practice exclusions, live/saved agreement,
retry reset, one cue per crossing, finite/reduced animation, silent seeking and
replay cues, and tapping Save session → Watch replay on an 800×360 screen.
Goal guides, the live HUD, earned details and updated result actions were rendered
and reviewed. [Figma goal details](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=60-296)
reuse the existing palette, typography and button library with the editable wing
source at `design/flight-wing.svg`.

## Friends in the clouds

Cloud Cruise now has three optional discoveries: Cloud Whale, Daydream Bunny
and Sky Turtle. A cloud visits every third ring and cycles through the three
shapes. Flying within a generous 0.20-height radius reveals it in the current
flight's collection. Clouds sit at the same movement endpoint as their ring;
push-up encounters are nudged inward so their artwork stays in view. Missed
friends return on later circuits. Repeat encounters never add duplicate rewards
or replay their greeting, and discoveries do not change stars, multipliers,
magnet charge, movement, records or unlocks.

The live strip shows three silhouettes, which reveal their faces as you meet
them. Results show the flight's collection, including friends still drifting.
The original soft greeting sound plays once per discovery. Saved replays
reconstruct the collection, including backwards seeks; scrubbing is silent.
The Cruise replay HUD sits to the right to keep the approach to the bird clear.
Pause freezes encounters. Reduced Motion removes decorative bobbing and pulses.

Replay version 5 gates the feature. Older Cruise journals retain their stars,
physics and seeded routes without new discoveries. Collections belong to their
flight and are retained through its saved replay, so no database migration or
new persistent progression counter is needed.

All 166 tests pass and analysis is clean. Checks cover optional/missed/repeated
encounters, pause/resume, calibrated 1-, 4- and 9-second push-up movements,
both controls, version-4 compatibility, backwards seeking, distinct artwork,
Reduced Motion, and greeting sounds in actual saved-replay screens. Setup,
flight, pause, results and both replay controls were reviewed at 800×360.

The existing Figma file now includes [Cloud Cruise gameplay](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=63-378)
and the [flight collection](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=65-397).
They reuse the bird/button components and semantic palette. The editable cloud
silhouettes in `design/cloud-whale.svg`, `cloud-bunny.svg` and `cloud-turtle.svg`
match the shared Canvas art used by the game and its UI.

## Course previews on Home

Selecting a course now changes the Home illustration. Star Trail surrounds the
equipped bird with stars and a shield; Courier adds a letter, delivery trail and
postbox; Cruise introduces all three cloud friends. Classic retains its original
island. The artwork reuses the game renderers and switches with a short crossfade
that is disabled by Reduced Motion. The daily postcard sits beside the scene,
clear of the preview. Course descriptions also have accessible semantic labels.

The Home, daily navigation and course flow checks pass (15 tests), analysis is
clean, and the new layouts were rendered at 800×360 and 1000×450. The existing
[Star Trail Home](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=35-78)
is updated, with new [Courier](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=68-419)
and [Cruise](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=68-456)
Home views built from its existing bird, island and button components.

## Replay highlights

Saved sessions now have a Flight highlights control beside the playback speed.
It opens a list of moments reconstructed from the original input journal:
takeoff, cloud discoveries, deliveries, star multipliers and magnets, shield
saves, Classic perfect passes and gate milestones, dropped letters and the final
approach. Selecting a moment starts playback 1.5 seconds before it; opening or
dismissing the list leaves the replay paused. Seeking remains silent and normal
game sound resumes as the selected event plays.

Indexing runs away from the UI, does not mutate the journal and keeps at most
twelve moments. Important first events and the ending take priority over repeated
milestones or deliveries. Coincident events share one highlight. Timestamps use
the journal clock, preserving countdowns and practice breaks. Unsupported new
mechanics are absent from old replay versions; the replay itself remains usable
if optional indexing fails. No database or journal migration is required.

All 175 tests pass and analysis is clean. Checks cover actual delivery and shield
events, both controls, silent opening/dismissal, selected-moment playback and
audio, exact discovery timestamps, pause offsets, old/empty journals, bounded
long-flight lists and unchanged source data. Cruise's HUD also moves out of the
camera inset's way; all four camera corners are checked. The sheet and controls were reviewed
at 800×360. The existing Figma file contains the new
[Replay highlights view](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=70-581).

## Wings that respond to movement

The four birds now have independently moving wings during flight. Push-up
height maps to a stable pose at each calibrated endpoint: raising presses the
wing down and lowering opens it for the next movement. Smile flaps produce a
short 0.38-second wing stroke and a small fading air wake, alongside the existing
tilt and spring. Reduced Motion keeps a neutral wing with no wake, tilt or spring.
No movement, collision, scoring or journal rules change.

The renderer uses the existing Figma geometry and each bird's palette. Body and
wing display lists are recorded once per bird. `tool/generate_bird_paths.py`
compiles `design/pip.svg` into cached native paths, avoiding runtime SVG parsing
or new bitmap assets. Replay poses derive entirely from simulation height,
velocity, elapsed time and the last flap, so backwards seeking reproduces them.

All 181 tests pass and analysis is clean. Pixel checks compare every neutral
bird to its original asset and ensure wing movement leaves faces unchanged.
Behavior checks cover held endpoints, finite flap strokes, pause timing, Reduced
Motion and both controls after backwards replay seeks. Pose sheets and gameplay
renders were visually reviewed. The [Figma wing study](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=74-600)
reuses the bird components with editable wing vectors in the two moving poses.

## Letters in motion

Courier pickups now arc into the bird's pouch, and deliveries fly back into
their postbox. A completed pickup leaves a check; a delivered postbox raises its
coral flag and releases three hearts. The gate remains in view after passing,
making the handoff readable as it scrolls away. Empty postboxes and pickups
passed with a full pouch never show a successful handoff.

Animations follow simulation time and each gate's world position. A dropped
letter cancels its pickup animation. Pause and backwards replay seeks reproduce
the same state, while Reduced Motion shows completed stations immediately.
Scoring and replay rules remain unchanged; no journal migration is required.

All 184 tests pass and analysis is clean. Checks cover actual successful and
unsuccessful actions, world anchors, deterministic finite animation, cancelled
pickups, Reduced Motion and replay seeking with both controls. The handoff sheet,
saved-replay renders and the [Figma Courier study](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=75-828)
were visually reviewed. Its three editable SVG stages live in `design`.

## Collect a constellation

The three stars on each Star Trail or Cruise approach now form a connected set.
Collect all three to earn a flat five-point bonus and unfold a small triangular
constellation. Collected stars leave small marks on the approach; missed sets
fade, and the next set is a fresh chance. The original targets, calibrated pace,
collision rules and magnet reach stay the same. Bonus points never add stars,
advance a multiplier, charge a shield, heal a heart or count toward bird unlocks.
Cruise remains practice. Scored Star Trail records include the bonus.

The first completed trio appears in replay highlights. A short original chord
plays once when a trio completes, unless a higher-priority reward shares that
frame. Scrubbing is silent. The constellation follows simulation time and world
position, freezes on pause, expires after 1.15 seconds and renders as a static
triangle in Reduced Motion. Replay version 6 enables the bonus and connected
sets; version 1–5 journals preserve their original scoring and movement.

Domain checks cover partial/missed/separate sets, once-only rewards, magnet
catches, multiplier boundaries, shield counts, practice pauses, backwards seeks
with both controls and bounded state. Ideal calibrated routes at 1-, 4- and
9-second cycles collect complete trios. Pixel checks cover distinct states,
finite animation and Reduced Motion; live and saved-replay screens verify sound
and small-phone layout. The existing Figma file includes the editable
[star-trio study](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=78-885).
The complete suite passes all 194 tests, with clean static analysis and a
validated ARM64 release package. Device playtesting remains pending.

## A place to arrive

The final six seconds of a timed route now reveal a destination: gold FINISH
pennants in Star Trail and coral HOME pennants in Courier. A light checker ribbon
marks the approach, with the name positioned below the score and reward HUDs.
Players can arrive at any height; the artwork has no collision or scoring rules.
It tracks remaining time and current scroll speed, meeting the bird at zero.

Completed results gain a matching star or letter ribbon medal. When a new bird
or record does not take priority, their greeting becomes “Trail complete!” or
“Welcome home!” Save session and retry remain immediately available. No ending
delay, camera recording extension or new progression requirement is introduced.

Pause freezes the approach and its flags, and Reduced Motion disables flag
flutter. Saved replays reproduce the approach and keep a check on their final
completed frame. Older timed journals also gain the decoration without any rule
change. Early exits and untimed flights omit the destination and arrival medal.

The new [Figma arrival study](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=80-885)
reuses the existing birds, typography, palette and study layout. Editable gate
and medal vectors are in `design/arrival-*.svg`.
All 205 tests pass and static analysis is clean. The phone renders and release
package were checked; physical-device playtesting remains pending.

## Small faces, small reactions

The four birds now react in flight. Deliveries, pickups, discoveries, complete
star trios, magnets, streaks, perfect passes and milestones earn pleased eyes for
0.7 seconds. Bumps, shield saves and dropped letters briefly widen their eyes and
raise their brows for 0.5 seconds, taking priority over simultaneous rewards.
Ordinary star pickups leave their faces alone. Between events, each bird has a
short 0.13-second blink every 4.8 seconds, staggered across the crew.

Expression timing comes entirely from the simulation clock. Pause freezes the
face, backwards replay seeks restore it, and Reduced Motion keeps the original
neutral face. A completed replay holds pleased eyes; a collision ending holds
the startled look. Other endings settle to neutral. No movement, score or
recording rules change, and no independent animation ticker is added.

The existing SVG compiler now identifies eye layers. Each body/expression is
recorded once and cached; wings share their original cache. Only eyes and brows
change, preserving the beak, body, palette and wing geometry. The editable
[Figma expression study](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=82-942)
uses the existing bird components and three small eye overlays in `design`.
All 212 tests pass and static analysis is clean. Pixel comparisons cover all
four palettes, distinct expressions and unchanged artwork outside the eyes and
brows. Timing checks cover priorities, expiry, future events, pauses, endings,
Reduced Motion and backwards replay seeks in both controls. The full expression
sheet, a rendered arrival and the Figma study were visually reviewed.

## Flight school without the camera

Home now opens a touch lesson for the selected course. Drag to steer through the
full movement range or tap once per flap. Lessons use the actual course rules,
rewards, stars, magnets, Courier stops and cloud friends, with contextual hints
and the equipped bird. All are practice; the school owns no tracking source,
recorder, progress repository or saved run. No camera or microphone access is
requested, and lesson results never affect records, birds, daily cards or stamps.

The player starts explicitly, gets the normal countdown, and can switch course
or control, restart and pause freely. App backgrounding or a long frame pauses
the lesson and its music. Resume requires another countdown and clears any
queued flap. Paused or ended lessons offer a direct handoff into the selected
course's push-up or smile practice setup. The full camera flow begins only after
that explicit choice.

All 219 tests pass and static analysis is clean. Domain checks cover both touch
inputs, range limits, one flap per tap, pause timing, stalled frames and real
rewards/endings across all four courses. UI checks at 640×360 and 800×360 cover
Home entry, drag, tap, switching, restart, lifecycle pauses, audio, camera handoff
and unchanged records/session storage. Home, intro, flight, pause and ending
renders were visually reviewed. The existing Figma project has a new
[Flight School view](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=84-1024)
and entry buttons on its three updated Home designs.


## Gates that belong to each region

The solid courses now change their gate materials along with the sky: vines on
sandstone in Sunrise Isles, warm stone with festival flags in Peach Horizon,
and blue stone with inset lanterns in Twilight Garden. Palette and decoration
crossfades use the same regional clock as the scenery. Lanterns glow softly;
Reduced Motion holds them still. Clean and perfect passes retain their one- and
three-flower marks in every region.

Artwork stays clipped to the solid tower, including the shortest endpoint
columns. The flight opening, obstacle positions, collision rules and scoring
are unchanged. Pauses and replay seeks reconstruct the same decoration from
simulation time. Cloud Cruise keeps its open rings.

All 223 tests pass and static analysis is clean. New pixel checks cover short
columns, clear flight openings, continuous regional transitions, deterministic
lanterns, Reduced Motion and distinct completion flowers. All three gameplay
regions and the matching [Figma gate study](https://www.figma.com/design/3l8DyW2mxf917HzgXsQaz7?node-id=87-1045)
were visually reviewed. Editable sources are `design/gates-sunrise.svg`,
`design/gates-peach.svg` and `design/gates-twilight.svg`.
