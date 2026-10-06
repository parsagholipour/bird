# Level Builder

Players build their own levels and fly them: Tap & Fly levels and levels for
the camera mini games (Push-Up Flight, Squat & Fly, Jump & Fly). Co-op and the
1 v 1 duel have no built levels. A built level tells no story: no scenes, no
delivery card or thank-you, no cargo line and no quote on a boss's name card.

The owner's brief (2026-10-06): "We wanna add a level builder. You can design
levels for normal game (tap to fly) or mini games like push ups, jump,
squat (not 1v1). (conversations not included like normal campaigns)", with
every gate, star, heart, enemy and the finish line placed by hand.

## A built level

A built level is one region's route with everything on it placed by hand
(`BuiltPlan`, `lib/domain/built_plan.dart`). Unlike a campaign level, whose
passages are drawn from a seed, nothing on it is random: every attempt, on
every phone, meets exactly what its creator placed.

- **Positions** are thousandths of the sky's height: the sky is 1000 tall
  (0 at the top) and a phone screen is about 2200 wide. A thing's x is where
  the bird meets it on the route (a gate's x is its leading edge).
- **Start zone.** Nothing sits before x = 2400, the widest landscape screen,
  so nothing is on screen as the flight begins.
- **The finish line** is placed by hand too. No gate may end within 450 of it,
  and nothing may sit on or past it. Crossing it completes the level, with
  the campaign's celebration.
- **Pace.** The course scrolls at its mode's cruising speed times the level's
  pace (Relaxed ×1, Steady ×1.15, Brisk ×1.3) and never ramps, so a place on
  the route is a fixed time from the start, and the editor's seconds are the
  flight's.
- **Length** is 6000 to 300000; a level holds up to 400 things.

### What can be placed

| Item | Modes | Notes |
| --- | --- | --- |
| Gate | all | All seven families, still or moving (a garden gate stays still). Height, opening, swing (amount, cycle, phase on arrival) and look are the creator's. |
| Stone door | Tap & Fly | In a garden gate, with Shoot on. Shoot or ram it open. |
| Star | all | One star. |
| Star trio | all | Three stars 170 apart; all three pay the trio bonus. |
| Heart | all | One heart back, up to five. Camera modes catch hearts too. |
| Enemy | Tap & Fly | Cave bat, spitter beetle, dusk moth or purple bat, at its own place. |
| Boss finale | Tap & Fly | Baron Bat, the Spitter King, the Dusk Empress, the Pirate Captain or the Ember Dragon. The finish line becomes the boss's mark: the fight (vanguard and three stages, as on a campaign boss level) starts when the bird reaches it, and the line is laid after the victory. |

Not in the first version: rush paths, gales, steam vents, Alley Pigeons and
the guardians (King Coo, the Searchlight Gargoyle, Neferhoo), whose staging
belongs to their home levels.

### Push-ups and squats

A height-controlled bird flies one of two lanes. Gates sit centred on the
high lane (250) or the low lane (750), and aim the bird at the calibrated
endpoint beyond (150 or 850), as endless does. Every dip to the low lane and
back up is one push-up or squat, and the editor counts them.

A level is designed for a 3-second movement. A player whose calibrated
movement is slower meets the same route on a slower course, by the ratio of
the passage spacing endless would give them (`BuiltPlan.speedScale`):
×1 at 3 s or faster, ×0.59 at 6 s, down to ×0.35. Every player meets the same
gates in the same order and does the same workout; a slow player just flies
longer. A fast one is never sped up past the design.

### Jumps

A jump level's gates may sit anywhere from 200 to 800. The editor warns about
steep climbs with little room.

## Stars and bests

A finished flight earns ★ for the finish, ★★ and ★★★ for collecting the
level's two marks. The marks follow the level's stars (55 % and 80 %) until
the creator sets them by hand. Each level keeps its best rating, best stars
and best score per revision: editing the route (anything but the name) makes
a new revision, whose bests start afresh. The editor says so.

Built flights count towards nothing outside the builder except the lifetime
workout: push-ups and squats done on built levels join the totals on the
Records screen. They never earn wallet stars, records, daily-adventure goals,
passport stamps or campaign stars, because a creator can place as many stars
as they like.

## The editor

`/builder` lists the starter levels and the player's own; `/builder/edit/<id>`
edits one. A template opens read-only and can be remixed. The editor shows
plain-language problems (which stop the level flying or being shared) and
advice (a lane switch too tight for a steady push-up, a star inside a wall,
a steep climb) at their places on the route (`BuiltReach`).

**Test flight.** The creator flies the level with the touch screen standing
in for the movement: tap to flap (Tap & Fly, jumps), drag up and down for
the movement's height (push-ups, squats), at the 3-second design tempo. A
test flight is practice and saved nowhere; one that flies the whole level to
the finish marks the revision "cleared by its maker". "Test from here" flies
the rest of the route from the editor's view.

## Share codes

A level travels as text, with no network: `BEAK1.` then the level's JSON
(without its id) deflated and in URL-safe base64, inside a friendly line
("Fly my Beakbound level “Ten Push-Ups” (Push-Up Flight): BEAK1.…"). Pasting
finds the code anywhere in the text. A code from a newer Beakbound is refused
politely; a damaged one or one that inflates past 64 KB is refused. An
imported level gets a fresh id; one with the same route as a level already
kept offers to open that one instead.

## Starter levels

Five read-only templates (`lib/domain/built_templates.dart`): Garden Hop (Tap
& Fly), Ten Push-Ups, Stair Squats, Bounce Bay (jumps) and Baron's Bridge (Tap
& Fly with Baron Bat). Each has a revision; retuning one's route bumps it.

## Rules, saves and replays

- **Rules version 64** (`FlightSimulation.builtLevelsRulesVersion`) flies
  built plans. The simulation lays a plan's items in route order as they
  come within reach (`lib/domain/built_rules.dart`), each exactly at its
  place. Endless, campaign, co-op and duel flights fly exactly as at 63.
- **Saves (schema 7):** `built_levels` keeps each level's canonical JSON,
  revision, origin and cleared revision; `built_flights` keeps every scored
  built flight, rated as it was saved. Bests and the workout totals are
  folded from it. A deleted level's flights stay, so its workouts still count.
- **Replays:** a built flight's tape carries the whole plan (`built`), so a
  level edited or deleted later still replays as it was flown. The session
  library names it after the level.

## Code map

| Concern | Files |
| --- | --- |
| Plan, items, validation, JSON | `lib/domain/built_plan.dart` |
| Engine hooks (rules 64) | `lib/domain/built_rules.dart`, `game_rules.dart`, `flight_plan.dart`, `level_plan.dart` (`LevelRoute.built`) |
| Kept level, bests, flight | `lib/domain/built_level.dart` |
| Editing draft, snapping, hits | `lib/domain/built_draft.dart` |
| Problems and advice | `lib/domain/built_reach.dart` |
| Share codes | `lib/domain/built_code.dart` |
| Templates | `lib/domain/built_templates.dart` |
| Store and providers | `lib/data/built_level_repository.dart`, `lib/data/builder_providers.dart` |
| Play flow | `lib/game/play_controller.dart` (`built`, `testFly`, `standIn`), `lib/ui/play_screen.dart`, `lib/ui/builder/built_flight_screen.dart`, `lib/ui/builder/built_result_stage.dart` |
| Editor | `lib/ui/builder/` |
