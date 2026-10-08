# Flight school (the first-time tutorial)

A new player's first launch is a short, guided adventure, not a manual: they
pick their language, meet Postmaster Bill, fly one lesson in which each new
thing is taught the moment it matters, beat a rookie Pirate Captain and are
handed their **courier licence**. Then the campaign opens with its prologue.
It teaches the main game only (Tap & Fly, the campaign); the mini games are
left to discover.

The owner's brief (2026-10-08): "a perfect first time tutorial, super
interesting even if that means we design dedicated elements. For the boss we
can have the nerfed version of Pirate boss. The player should absolutely love
the experience. Not the mini games, only the main game and campaign. Reserve
audios for the tutorial. First he should choose the language."

## The flow

| Step | Route | What happens |
| --- | --- | --- |
| 1 | `/welcome` | **Choose your language.** Home's sky, the flying bird and the title behind a card of the 12 languages, each in its own name and fonts. The phone's language is chosen to begin with and badged "Your phone's language". A tap switches the whole screen (and the game) to that language at once. The title asks "Choose your language" in every language in turn. **Let's fly!** saves the choice and goes on. |
| 2 | `/tutorial` | **Bill's word before the lesson** (`school-intro`, a story scene in the post at dawn). Skip lesson (top left) asks once ("Skip flight school?") and goes to the map. |
| 3 | `/tutorial/fly` | **The lesson.** A Tap & Fly flight over the Sky Club's bay, coached by Bill (below). |
| 4 | (same) | **The finale.** The rookie captain's retreat and Bill's verdict (`school-outro`), then the courier licence. |
| 5 | `/campaign` | **Start my first route** opens the map, where the prologue plays as always. |

A player goes through it when the save says they have never flown and never
finished or skipped flight school (`firstLaunchRoute`,
`lib/ui/tutorial_screen.dart`): Home sends them to `/welcome`. Finishing the
lesson (reaching the licence), Skip lesson or the pause card's Skip marks it
done (`SettingKey.tutorialDone`, a device setting like the others). Settings
→ **Flight school** flies the lesson again, and so does the licence's **Fly
it again** and the pause card's **Start over**; none of them repeats the
language screen or the intro.

Widget tests boot a fresh save into Home as they always have: the first
launch is switched off under `flutter test` (`firstLaunchTutorialProvider`),
and `test/tutorial_flow_test.dart` switches it on.

## The lesson

The route is a hand-placed built level (`TutorialPlan`,
`lib/domain/tutorial.dart`, a `BuiltPlan` at rules version 64) in the Open
Sea region, the Pirate Captain's water, which the campaign only reaches in
chapter 4. It is flown at the relaxed pace and lasts about a minute and a
half before the boss.

| Lesson | Route (thousandths) | Bill says | Held until | Goal chip |
| --- | --- | --- | --- | --- |
| Flap | open sky | "Tap anywhere to flap your wings!", then "Keep tapping to stay up…" | a tap | Flap ×3 |
| Stars | 2700–5900, trios in a wave | "Stars! Fly right through them." | – | Collect stars ×6 |
| Gates | 7100, 8400, 9700: wide garden gates, a trio before each | "Here come the gates. Fly through the gaps!" | a tap | Fly through gates ×3 |
| Shoot | bats at 12000, 13300, 14600, each led by a trio on its line | "A bat! Tap Shoot to throw a pebble." then "Got him! Knock out the others." | Shoot | Knock out bats ×3 |
| Power shot | a stone door at 17200 | "A stone door! Hold Shoot to charge, then let go." then "Smashed!…" | Shoot pressed | Smash the door |
| Sprint | four bats in a row from 20300 | "Now tap Sprint to zoom ahead…" | Sprint | Sprint |
| Together | gates, two bats and a heart (26450) | "Now put it all together!", "A heart! Catch it…" | – | Fly through gates ×3 |
| Boss | the captain's mark at 29400 | "Pirates! Dodge the cannonballs and shoot the Captain!", then "He's getting angry. Grab that heart!" and "The tide is rising! Fly high!" | – | Beat the Captain |
| Victory | the victory glide and the finish line | "You did it! Now that's a courier!" | – | – |

Tips that come when they happen, once each: the first bump ("Ouch! A bump
breaks your shield first, then costs a heart."), the first fall flight
school catches ("Don't worry, nobody falls in flight school.") and the
first star streak.

**Held moments.** When a lesson needs a new action, the world eases to a
stop over 0.35 s (a slow-motion freeze), the screen darkens at the edges
and a pulsing shout says what to do: TAP! with a tapping finger over the
sky, or TAP SHOOT / HOLD SHOOT / TAP SPRINT beside the key, which sits in a
lit spotlight with a gold ring. Only that action lets time run again (a tap
cannot release a Shoot lesson, nor Shoot a tap lesson). Time that is held
reaches neither the simulation nor its journal: `PlayController.advance`
asks the coach for its time scale, so the route, the boss and every rule
are exactly a built level's.

**Keys arrive as they are taught.** Shoot pops onto the HUD at the shoot
lesson and Sprint at the sprint lesson; before that the screen shows only
hearts, stars, the route and Pause.

**Nobody falls.** The plan is `forgiving`: the last heart is never lost
(`FlightSimulation.fallsCaught` counts the saves), so a bump still teaches
hearts and the shield but never ends the lesson.

**Praise.** Each goal met pops "Nice!", "Great!" or "Brilliant!" with a
chime.

**Nothing is saved.** No run, record, star, passport stamp, daily goal or
session: the play screen's save callbacks drop the flight. Only
`tutorialDone` is written.

## The rookie Pirate Captain

The plan's `rookieBoss` makes the captain's staged fight (warm-up, stronger,
fury; `SkyBoss.rookie`) gentle:

| | Campaign 4-8 | Rookie |
| --- | --- | --- |
| Health | 780 | 240 (`SkyBoss.rookieHp`, about two dozen pebbles) |
| Cannonball speed (warm-up / full / fury) | .46 / .50 / .60 | .38 / .42 / .46 |
| Between volleys | 2.6 / 2.1 / 1.5 s | 3.2 / 2.8 / 2.3 s |
| Volleys | single, then pairs, broadsides in fury | single shots; a pair every other volley in fury; never a broadside |
| Tide | from the full fight | the same, so the lesson is the real one |

A bot that flies the lesson as a new player would beats him in about 27
seconds (`test/tutorial_test.dart`). He arrives with his usual cinematic and
name card, knocks the two stage hearts loose, and sails off defeated: "Keep
yer little letters. The open sea be mine, and we'll meet again!", the
promise chapter 4 keeps.

No recorded flight changes: `forgiving` and `rookieBoss` are false for every
plan but flight school's, and flight school is never saved or replayed.

## The courier licence

An airmail-edged card: the Sky Club post's band with **Courier licence** and
the stars collected, the bird's picture in a photo frame, its name and rank
(Rookie courier), the seven skills of the lesson ticking in one by one,
"Signed: Postmaster Bill", and Bill's red **CERTIFIED** stamp slamming down.
Confetti falls behind it. Under Reduced Motion it appears whole and still.

## Reserved audio

Everything flight school says is a story voice clip, written, translated
and **pending recording** in `docs/story-voices-sources.json` (33 clips:
`school-intro-*`, `coach-*-0`, `school-outro-*`; courier lines once per
bird). The voices are the existing cast: Bill (GERALD), the Pirate Captain
(Matthew Schmitz), the narrator (Twinkle) and each bird's own. Record them
as any pending clip ([story-voices-recording.md](story-voices-recording.md),
`python3 tool/prepare_story_voices.py`): once a take is mastered into
`assets/audio/story/` and the clip table is regenerated, the game plays it
with no code change. Until then the words show alone, paced by the text.
In flight, Bill's lines duck the music (`SkyAudio.speak`) and the birds'
own in-flight chatter is off, so he is never talked over.

Four sound effects are reserved. Each plays its own recording once it is in
the sound bank, and an existing cue until then
(`_PlayScreenState._cue`, `CourierLicence`):

| Cue | When | Plays until recorded |
| --- | --- | --- |
| `tutorial_hold` | a lesson freezes the moment (a soft "whoosh-ding" as time slows) | `ready` |
| `tutorial_goal` | a lesson's goal is met | `perfect` |
| `tutorial_victory` | the rookie captain is beaten | `unlock` |
| `tutorial_stamp` | Bill's stamp hits the licence (a rubber-stamp thump) | `unlock` |

To add one: put `assets/audio/<cue>.wav` in place (mastered as
[sound-effects.md](sound-effects.md) describes) and add its `SoundSpec` to
`soundBank` (`lib/game/sound_bank.dart`). Flight school keeps the region's
music (the Open Sea's song, then the boss track).

## Code map

| Concern | Files |
| --- | --- |
| Route, lessons, coach | `lib/domain/tutorial.dart` |
| Lines (captions and clips) | `lib/domain/tutorial_story.dart`, `assets/l10n/story/<slug>.json` |
| Rules hooks | `FlightPlan.forgiving`, `FlightPlan.rookieBoss` (`flight_plan.dart`), `game_rules.dart` (`_damage`, `_advanceBoss`), `SkyBoss.rookie` |
| Time hold and gestures | `lib/game/play_controller.dart` (`coach`, `_coached`, `advance`) |
| Coach over the flight | `lib/ui/tutorial_coach.dart` |
| Finale and licence | `lib/ui/tutorial_finale.dart` |
| Intro, skip, first-launch rule | `lib/ui/tutorial_screen.dart` |
| Language screen | `lib/ui/welcome_screen.dart` |
| Play screen hooks | `lib/ui/play_screen.dart` (`tutorial`) |
| Routes | `lib/main.dart` (`/welcome`, `/tutorial`, `/tutorial/fly`) |
| Tests | `test/tutorial_test.dart`, `test/tutorial_flow_test.dart` |

Renders for a look by eye: `TUTORIAL_CAPTURE=1 flutter test
test/tutorial_flow_test.dart` writes `build/visual-review/tutorial/`.
