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
your chosen bird stay in SQLite on the phone. After a flight, Save session keeps
an input journal and any camera footage for replay in Records → Saved sessions.
Replay **Flight highlights** lets you jump to streaks, power-ups and the final
approach, with a short lead-in before each moment.

**Endless flights:** Star Trail keeps going with three hearts, a shield and
streak multipliers. Every control has a gradual time-based speed increase,
with no finish timer. Garden gates give way to rising **Wind Lifts**, opening
and closing **Petal Shutters**, and two-column **Switchbacks**. Longer flights
introduce swaying **Lantern Drift**, orbiting **Sun Wheels**, and three-column
**Crystal Steps**. Floating obstacles use round collision shapes and leave open
sky around them. Turbines, blossoms, faceted towers and regional color variations
give each pattern a distinct look. Version 14 redraws all seven families,
including garden gates, with authored detail variations. It changes presentation only: version 13
physics stay the same, and saved version 13 replays keep the previous artwork.
Version 16 adds conservatory, terracotta blossom and bamboo garden structures,
plus moon bat, armored beetle and dusk moth enemies. The first
three garden obstacles show appearances 0, 1, and 2 immediately. That opening
change is decoration only: the same random draws still decide later geometry,
which matches version 15. Saved version 14 and 15 replays keep the earlier
garden and enemy artwork.
Patterns mix throughout the flight; calibrated push-up and squat pacing stays reachable.
The match HUD keeps score, hearts and shield status visible, with compact
magnet/glide meters when relevant and a round Shoot control with ammo and charge rings.
Custom illustrated icons, brief state-change pops and press feedback keep the
sky clear; Reduced Motion disables the decorative movement. Endless flights
omit the clock, pace, flap count and persistent instruction/goal cards. The
60-second flight wing, daily goal and passport stamp remain endurance milestones,
so you can earn them and keep flying. Existing replay journals retain their original timing and physics,
including the four-pattern version-12 flights.

**Classic** and **Star Trail** both run endlessly in Flight School. Sky Courier
and Cloud Cruise are retired; a saved journal that names either one opens as
Star Trail. Every course supports push-ups, squats, jumps and touch. Three changing
sky regions with leafy stone, festival flags and lantern-lit gates,
perfect-pass celebrations, bird trails and an eight-stamp
**Sky Passport** give flights more character and goals. Each scored course keeps
separate records for each control. See the
[arcade update notes](docs/arcade-expansion.md) for rules, design links and checks.

**Home** opens on a sunny title scene: your equipped bird hops on its island
under turning sun rays, and a dotted star trail leads from the **Play** button to
it. **Play** opens a mode picker for Push-Up Flight, Tap & Fly, Jump & Fly and
Squat & Fly on Star Trail. The mint **Campaign** key beside it opens the
campaign map and shows the level stars earned. A row of pictograms shows the four ways to fly (push-ups,
squats, jumps, taps). The bird greets you by name, a pill shows your best flight
(or welcomes a first-time player), and a dock of five shortcuts leads to today's
adventure, birds, the passport, records and flight goals. The adventure tile
glows with its 0/3 count and turns gold when all three goals are done. Clouds
drift, stars twinkle and the screen assembles itself on launch; with Reduced
Motion the whole scene is still.

**Tap & Fly**, in the **Play** mode picker, starts a full touch flight on Star Trail. Tap
anywhere in the sky to rise, then release and tap again. Touch flights have a
stronger flap, narrower openings and closer buildings. Tap **Shoot** to spit a
rock straight from the bird's beak at bats ahead, or hold it to charge a bigger
rock; aim by changing your height. Defeating an enemy earns +3 points on Star
Trail; buildings block rocks, and each shot has a short cooldown and spends
ammo. Bats use the same shield/heart collision rules as
buildings. Scored flights contribute
to the passport, daily adventures and flight goals, with separate touch bests in
Records. Any flight can pause and resume after a short countdown; scored flights
still end on a collision or lost tracking. Save session keeps a gameplay replay without camera video,
including shots and enemies. Existing replays keep their original flight rules.

**Enemy health and weapon damage (version 26):** each shot carries 10 damage by
default. Both bat types start at 10 HP, beetles at 20 HP, and moths at 30 HP.
Small enemies gain 5 HP per defeated boss, capped at 20 extra HP; summoned
helpers use the same rule. Wounded enemies show a small health bar, and points
are awarded only on defeat. Hits add a brief cream flash, a small squash and
recoil, and warm impact sparks; defeats pop into a larger ring and puff burst.
Reduced Motion uses a stationary fading spark. Effects follow simulation time
through pause and replay without changing collision or attack timing.
Bosses start at 120 / 180 / 240 HP and retain their
previous progression and base-weapon fight lengths. Higher weapon damage
reduces the shots needed without changing enemy health. For future upgrades,
pass `weaponDamage` to `PlayController` for the starting loadout or call
`FlightRecorder.setWeaponDamage()` during a flight. Starting damage and changes
are saved in replays; ammo already in flight retains its original damage.

**Small enemies (version 18):** a natural cave bat, spitter beetle and dusk moth
face the bird with distinct profiles and articulated wings. Bats are simple
contact enemies; beetles charge a mint throat before firing one aimed seed;
moths light three amber glands before a slower three-shot fan. Shots lock their
direction on release, buildings block them, and your rocks can intercept them.
Shooters wind up visibly before firing and stop attacking when too close or
behind the bird. The same abilities apply to boss helpers. Pause and replay
preserve their attack clocks; older journals keep their previous enemy art and
behavior. Reduced Motion freezes decorative wing motion while keeping charge
and recoil cues readable.

Version 19 adds a **simple purple bat** sharing the boss's basic body, ears,
face and membrane wings, with no crown, cape, armor, gem or gold decoration.
It takes the primary bat slot and appears among boss summons. The **cave bat**
remains a separate fourth character in normal flight. Both are simple contact
enemies; beetle and moth attacks are unchanged. Version-18 replays retain the
original three-character lineup.

Version 20 adds subtle flight arcs, light banking and individual wingbeat
timing. Bats bob gently, beetles hover more tightly, and moths drift more
slowly. Shooters steady through charging and recoil. The body, collision area
and ammo origin move together; Reduced Motion removes decorative banking and
wing motion while retaining the visible gameplay path. Earlier replays keep
their straight flight.

The spitter beetle has raised sculpted wing cases, separate translucent flight
wings, a compact head and segmented abdomen. Independent wing strokes turn
edge-on, antennae and legs follow through, and its mint cheek fills before the
aimed spit. A short recoil settles through the shell and feet while the mouth
stays aligned with the projectile origin. Attack timing and flight paths stay
on the existing rules.

For a design and motion preview, run
`flutter test --no-pub --dart-define=CAPTURE_ENEMY_MOVIE=true test/small_enemies_art_test.dart`.
The lineup, game scene and animation frames appear in
`build/visual-review/small-enemies/`.
Add `--dart-define=CAPTURE_SPITTER_MOVIE=true` to render dedicated beetle
close-up and gameplay-size frames (`spitter-*.png`) in the same folder.

**Touch boss fights:** after 45 seconds, the gates clear for **Baron Bat**.
Dodge his aimed fireballs, spread volleys and small bat helpers while using
Shoot to drain his visible health bar. He attacks faster below half health.
Winning earns 30 Star Trail points and restores your shield, then normal flight
resumes. Another boss arrives after 45 more seconds of normal flight. Baron
Bat starts with 12 HP and reaches a maximum of 24 HP. Movement controls stay
free of bosses. Version 15
replays preserve the whole fight, including pauses, shots and victories.
Version 16 gives summoned enemies the new enemy artwork. Boss timing and damage
stay on the version 15 rules.

**Breakable wall openings (version 27):** after boss 2, random normal walls
have a sealed stone plug blocking the gap between their upper and lower sections:
granite blocks, iron straps, a gold sun-and-bird medallion and four health
gems, set in a reinforced collar. Keep flying and shoot the panel four times with
the base weapon to drain its 40 HP. Every hit sparks, chips and dusts, bites a
crater out of the stone at the height you hit and grows cracks from it (visible
damage at 30, 20 and 10 HP). The last blow clears the opening immediately and
the plug shatters along those cracks over one second: flash and shock rings, a
spray of stone shards, snapping straps, the medallion coin-flipping off in a
shower of twinkles and billows of dust, leaving the wall's sockets chewed. A
charged shot or a sprint ram breaks it harder. These walls keep the normal
scrolling and collision rules. They never appear back-to-back, carry an extra
enemy, or block a reward-heart gate. Earlier replays keep their original route.
Reduced Motion keeps the static damage stages, without sparks, dust or debris.

**Power shots (version 28):** hold **Shoot** (or Space/Enter) to charge the
next rock, then release to fire. The charge builds smoothly over one second, so
any hold gives an in-between shot. A full charge makes the rock 2.4× as wide
and deals 4× the weapon damage (40 with the base weapon); upgrades scale the
same way. A full charge fires on its own after 500 ms. The inner ring and
the rim around the rock count that window down, and letting go afterwards
does not shoot again. Every shot draws on one ammo reserve: a tap spends 10%,
a full charge 45%, and the cost rises smoothly in between. The reserve refills
at 40% per second after 0.45 seconds without firing, longer than the shot
cooldown, so rapid fire empties it after about ten taps. A low reserve limits
how far a charge can grow. With too little for a tap, releasing plays an empty
click; keep holding to charge while it refills. The button's outer ring shows
the reserve with the pending cost in yellow, and its inner ring shows the
charge, then the countdown. The held rock grows and glows at the beak. Pauses
and boss entrances cancel a charge. Replays record each press and release;
a full charge that fires itself is part of the tick. Earlier replays keep
unlimited taps.

**Shattering pellets (version 36):** any rock cancels an enemy pellet it
meets. Hold Shoot for at least 0.35 seconds (long enough for the heavier
shot sound) and the rock shatters the pellet instead. The pellet bursts into a
blast that deals half the rock's damage to every enemy it reaches. A full
charge's blast reaches twice as far and deals 20 damage with the base weapon,
enough for bats and beetles. The boss takes blast damage too, unless the Dusk
Empress's veil is up. The rock is spent either way. Earlier replays keep the
plain cancel.

**Sprint (version 29):** tap **Sprint**, left of Shoot, to rush forward for
1.2 seconds. The course surges to 2.5× speed and eases back before the burst
ends. While sprinting, the bird smashes any bat it touches, whatever its
health, for the usual reward, and breaks stone panels by flying into them.
Walls, the course edges and projectiles still hurt. In a boss fight, the boss
stays put while its shots and helpers rush at you faster. Sprint then
recharges for 15 seconds from the press; the button counts down the seconds
and chimes when ready. Pauses freeze the burst and the cooldown. Tapping
Sprint never flaps. Earlier replays have no sprint.

**Rush paths (version 32):** 22 seconds into a Star Trail flight, and between
later bosses, the course turns into a rush path. A banner warns which kind is
coming, and each brings danger from a different side:
- “WILDFIRE!”: a wall of flame chases you from behind.
- “SKYFALL!”: meteors rain onto your route from above.
- “ERUPTION!”: lava vents below the route blast plumes up as you arrive.
- “SWARM!”: flocks of bats stream at you from ahead, on and beside the route.

Every four runs cover all four kinds in a shuffled order, so no two flights
play the same. Fly through the gold sprint rings to rocket forward at 3×
speed. Each ring caught in time keeps the speed going with no slowdown. At
that speed you outrun the fire and the lava, and smash straight through stone
barriers, walls, bats, meteors and the swarm, scoring for each one. Miss the
rings and the rubble is solid, the fire catches up, the lava goes up under you
and the meteors and bats hit you. Pass the last barrier to escape for +10
points, or +20 if nothing touched you. Earlier replays have no rush paths.

**Gales (version 33):** some time after you beat the Dusk Empress, a
“GALE!” banner warns of a windstorm. The walls stop and a tailwind sweeps you
along at up to 1.6× speed while debris flies straight at you. A flashing **!**
and a warning lane from the right edge mark the height of each piece a moment
before it appears.
Every gust aims at where you are, and every other gust sends a second piece
above or below, so pick the open side. Debris hurts even while sprinting, and
rocks bounce off it. Each dodged piece scores +1. Riding out the 13-second gale
scores +10, or +20 if nothing hit you. The usual rush path follows the gale
before the next boss. Earlier replays have no gales.

**Pirate Captain (version 34):** the fourth boss sails in on a ship and
brings the sea with him. Don't touch the water. He lobs cannonballs at you in
arcs: single shots, pairs that bracket you, and in fury three-ball broadsides.
Every ten seconds a ship's bell rings and the tide surges up to just past the
middle of the screen, lifting his ship with it, so fly high until it falls
back. His hull is armored: aim for the captain on deck. Earlier replays keep
the three-boss cycle.

**Baron Bat returns (version 40):** the first Baron Bat of a flight fights as
before, but every later one comes back upgraded (THE STORM RETURNS). Every
ten seconds his ears flare and a tag marks the one gap he'll leave, then he
screeches a wall of sound across the whole sky. Fly into the gap and hold it
as the wall goes by, like flying through a gate. The gap never opens where
you already are, and it narrows in fury. His small bats now come two at a
time, one high and one low, as each screech fades, and a second pair joins
them in fury. Earlier replays keep the original Baron.

**Campaign (version 41):** the **Campaign** key on Home opens a world map of
Tap & Fly levels. The campaign is one trip around the world in five chapters,
one per boss, in boss order:
- The Canopy Route: Jungle, Brazil and Aztec, ending with Baron Bat.
- The Ancient Road: Ancient Rome, Egypt and Ancient Arabia, ending with the
  Spitter King.
- The Lamplight Line: New York and Paris, ending with the Dusk Empress.
- The Tide Route: Mexico and the Open Sea, ending with the Pirate Captain.
- The Edge of the Map: Antarctica, Cyberpunk City and China, ending with the
  Ember Dragon.

Each region is a stop on the map, painted with its own scenery, and each
level flies that one region from start to finish. Chapters 1 and 2 (16
levels) and New York (3-1 to 3-4, rules version 43: the Alley Pigeon, steam
geysers, King Coo and the Searchlight Gargoyle) are playable, 20 levels and
60 stars. Paris and chapters 4 and 5 sit on the map, locked, as "Coming
soon". New York is open by default (`Campaign.openingEnabled`); a build made
with `--dart-define=NEW_YORK_OPEN=false` (`make build
DEFINES=--dart-define=NEW_YORK_OPEN=false`) closes it again. Endless Star
Trail stays the high-score mode, unchanged. See the
[campaign design](docs/campaign.md).

Levels are generated from data, not built by hand. Each has a fixed seed,
its region, 60–90 seconds of flight to a gold FINISH line, the hazards it
allows and the endless pace it starts from. Every attempt lays the same route
on every phone, however you fly it. Mechanics arrive gently. Chapter 1 brings
flying, stars, Shoot and bats (from 1-3) and Sprint (from 1-5). Chapter 2
brings spitter beetles, stone panels and rush paths. A level that brings
something new says so on its card. The last level of a chapter is 30 seconds
of flight and then the boss's debut fight. The boss says one line of story on
its name card, and the finish line follows its defeat.

The campaign tells a story between flights. You are the Sky Club post's
newest courier, and on your first morning all five mail routes go quiet.
**Postmaster Bill**, the old pelican who runs the post, sends you out, and
short scenes play on the map as the trip goes on: the prologue on your first
visit, a few lines when you reach a new region, a word with each boss at its
lair and another once it is beaten. Every beaten boss admits that a letter
with a flame seal told it to take its route, and the trail leads to the edge
of the map. Tap to move a scene on, or press **Skip**; each scene plays by
itself once, and the story key on a level's card plays it again. Every level
is also a delivery: its card says what you are carrying and for whom, and
the result of a finished level brings back a signed thank-you.

Every character speaks. The scenes, the thank-you notes and each bird's
sprint calls are recorded voice-over made with ElevenLabs Eleven v4: Bill,
the five bosses, a voice for each of the four birds and some thirty voices
for the people you deliver to. The music ducks under a spoken line, and
**Settings → Character voices** turns them off. See
[story voices](docs/story-voices.md).

They talk in flight too, in every mode. The equipped bird reacts in its own
words: a hit, the last heart, a wildfire on its tail, the Dragon drawing
breath, a new record, ten more push-ups. Each boss taunts, gloats and
grumbles in its own fight, and the bird answers back. A campaign level
opens on its cargo, and the bird talks about the region, the star marks
and the delivery. No line comes back until many others have been said,
even across launches, and lines stay rarer in endless flights. See
[flight voices](docs/flight-voices.md).

Reaching the finish earns ★. Collecting the level's first and second marks
earns ★★ and ★★★. The marks are 45% and 75% of the stars on the route in
chapter 1, and 50% and 80% after that, rounded to fives. In
flight, the stars you have collected fill a track toward the two marks, and a
route line shows how far it is to the finish. Losing your last heart fails
the level with the Bonk! stage, and Retry goes straight back to the
countdown. Finishing a level unlocks the next one. Beating a boss opens the
next chapter, and a postcard from the route arrives on the map. Each level
keeps its best stars, star count and score, and the level stars are saved
for a future upgrade shop.

Campaign flights never count as endless records, bests or flight wings. They
do count toward daily adventures (except "The whole journey") and toward the
First wings, On the dot, Star chaser, Constellation and Flock together
stamps. A saved session keeps the level's whole plan, so it replays exactly
even after the level is retuned. The library names it after the level, such
as "1-3 · Bat Patrol". Progress lives in database schema 5, whose migration
keeps every existing flight. Reduced Motion stills the map, the finish
pennants and the result's stars.

To render the campaign for review, run these tests with their capture flags:
- `flutter test --no-pub --dart-define=CAPTURE_CAMPAIGN_ART=true test/campaign_art_test.dart`
  writes the map stops and postcards to `build/visual-review/campaign/map/`
  and `postcards/`.
- `CAPTURE_CAMPAIGN_FLIGHT=true` with `test/campaign_flight_art_test.dart`
  writes the level HUD, the finish line and the boss name cards to
  `build/visual-review/campaign/flight/`.
- `CAPTURE_CAMPAIGN_REGIONS=true` with `test/campaign_regions_art_test.dart`
  writes long single-region flights to `build/visual-review/campaign/regions/`.
- `CAPTURE_CAMPAIGN_SCREENS=true` with `test/campaign_screens_test.dart`
  writes Home, the map, story scenes, level cards, results, the game-over
  and pause stages and the postcard to
  `build/visual-review/campaign/screens/`.
- `CAPTURE_POLISH=true` with `test/polish_story_scene_test.dart` writes the
  story's cast sheets (Postmaster Bill, the four birds and the five bosses in
  every mood) and every scene to
  `build/visual-review/campaign/polish/story/`.

**Fly Together (version 42):** two players share one phone. Open **Play**
and choose **Fly Together** under the four modes (or the two-player button at
the top of the picker), and each player picks a bird. Choose **Roped** to tie
the birds together, or **No rope** to fly side by side. Player 1 taps the left
half of the sky and has Shoot and Sprint in the bottom-left corner; player 2
has the right half and the bottom-right corner. On a keyboard, player 1 flaps
with W, sprints with A and holds D to shoot; player 2 uses Up, Left and Right.
Roped, the two birds are tied together. The rope hangs slack while they stay
close and stops them 0.30 screen heights apart. When it snaps taut, the two
birds share the pull like two equal weights: a bird flapping alone lifts both
at half its speed, so the pair climbs only a quarter as high, while flapping
together climbs as high as a solo bird. A sprint surges that bird ahead and
drags its partner along on the rope (or nudges it, sprinting from behind). The
course speeds up by the pair's average boost: 1.75× for one sprinter and
2.5× for both. Only the sprinting bird smashes things; a sprint ring carries
both. Hearts, shield, score, stars and the magnet are shared. Either bird can
collect a pickup or get hurt, gates count once both birds are past, and aimed
attacks take turns between them. Each bird has its own ammo, charge and sprint
cooldown. With **No rope**, each bird flies on its own: a lone flap lifts only
that bird, nothing drags, and the birds only bump when they meet; hearts,
shield and score are still shared. Each mode keeps its own team best and
flight count, shown in **Records** next to the solo bests and kept apart from
the solo records, the passport and the daily adventures. Save session replays
both birds and their rope. Solo flights under rules 42 fly exactly as under 41.

**Fly Together 1 v 1 (version 42):** choose **1 v 1** on the Fly Together
screen to fight instead of teaming up, with the same controls. Each bird has
its own hearts and shield, and the last bird flying wins. Every other gate
brings a **mystery box** floating above or below it: fly into it, or shoot
it, to open it. Half the time it sends an attack after your rival (a bat
swarm, a spitter beetle or a meteor shower, glowing in your colour, which
flies straight through you); otherwise it helps you with a heart, a shield or
five seconds of star power (nothing hurts you, you smash what you touch, and
touching your rival hurts them). Your rocks hurt your rival too, once one of
you has surged ahead. There are no bosses or ordinary enemies in a duel.
Results name the winner and keep a series score until you leave; Records
counts your duels.

**Extra lives (version 24):** after each boss victory, one heart appears in a
random safe opening before the next boss. Fly into it to gain one additional
life, up to a maximum of five hearts. Missed hearts disappear; the HUD
shows the full life count. Older replays retain their original rules.

**Spitter King (version 21):** the second boss is an alchemist-monarch beetle
with 18 HP, a crown of three glowing flasks, a monocled amber eye, thorned wing
cases and a glass still for a belly, with a brass trumpet mouth, a feed hose
and articulated claws. He lifts his crown on arrival, pumps acid up through
his still, crown and jowl, sloshes on recoil, beckons to summon helpers and
turns amber-hot, steaming and cracked in fury. Defeat releases a spray of
droplets and bubbles and sends his crown tumbling. Dodge faster
acid fans alternating between three and four shots, plus summoned beetles.
Version 23 widens the spacing to 0.30 radians and removes the center shot from
full fans to leave a clear dodge lane. At half health, every volley has four
shots and both attacks and summons speed up. Versions 21–22 replays retain
the original three/five-shot fans. He shares the bat's cinematic entrance,
defeat, sound cues and rewards.
Later beetle fights scale up to 30 HP. Version 21 replays alternate Baron Bat
and Spitter King; version 20 and earlier keep their original all-bat sequence.

**Dusk Empress (version 22):** a crowned Dusk Moth arrives as the third boss,
then encounters cycle Bat → Beetle → Moth. She starts with 24 HP, fires faster
five- and seven-shot pollen fans, and summons smaller dusk moths. At half
health every fan has seven shots, with faster attacks and summons. Her silk
shield warns for 0.8 seconds before blocking shots for 1.6 seconds, starting
five seconds into combat and repeating every eight seconds. Watch the pale
blue veil and HP-bar hint, dodge while it is up, then fire when it drops.
Later moth encounters reach 36 HP. Her crescent diadem, plumed antennae, hooked
velvet wings with pearl-lace hems, moon eyespots and luna tails, ermine ruff and
glowing throat glands give her a distinct silhouette; in fury her wing veins and
eyespots ignite to ember.
The shield has a woven silk edge, lunar clasps and ripples where shots are blocked.
Her animation and shield reactions follow simulation time in play and replay;
Reduced Motion keeps charge and shield cues visible without decorative motion.

**Cinematic boss encounters (version 17):** a storm warning, glowing silhouette,
unfolding wings and a title reveal introduce Baron Bat. His layered armor,
independent crown, wing beats, charged magic, recoil and hit reactions follow
the fight. Defeat brings a stagger, a burst of light and smoke, expanding
shockwaves, debris, a tumbling crown and a victory card. Original sound cues
follow each beat, and music quiets during the cinematics. The bird coasts safely
through the 4.6-second entrance and 3.8-second defeat; combat controls return
automatically. Reduced Motion removes camera shake, flashes and decorative
travel. Older journals retain their earlier boss timing and presentation.

To render a short motion preview with synchronized sound, run
`flutter test --no-pub --dart-define=CAPTURE_BOSS_MOVIE=true test/boss_choreography_art_test.dart`,
then `python3 tool/render_boss_preview.py`. The movie is written to
`build/visual-review/boss-cinematic-preview.mp4`; its final hits are staged to
show the entire defeat in a short preview.

For the Spitter boss movie, use `CAPTURE_SPITTER_BOSS_MOVIE=true` in the same
test command, then `python3 tool/render_boss_preview.py --boss spitter`.
This writes `build/visual-review/spitter-boss-cinematic-preview.mp4`.

**Flight school** on Home lets you explore every course with touch controls:
drag to steer or tap to flap. Learn the actual stars, gates, letters and cloud
friends without a camera. Lessons can pause or restart freely and never change
records, the passport, daily adventures or saved sessions. When ready, jump directly
into a push-up, jump or squat flight on the selected course.

Perfect gates now charge a **Star Magnet** in the star courses: three perfect
passes grant eight seconds of extra pickup reach. Push-up aiming marks and stars
follow the full calibrated top and bottom positions. Older saved replays retain
their original targets and scoring rules.

**Star groups (version 30):** collect all three stars in one group for +5
points in Star Trail. Each pickup moves into the bird and shrinks
away over 220 ms. A small gold aura fades at the last star's position when the
group is complete. Groups have no connecting lines, charge slots or bird bursts.
Missing a star forfeits that group's bonus; the next group starts fresh. Bonus points do not
accelerate multipliers or shield charge. Older replays retain their artwork.

**Daily adventures** rotate three small goals each local day. Complete them to
stamp a Sky Club postcard; the last seven days stay visible. All four controls
work, progress is saved offline, and there is no streak penalty.

Scored flights show a live **personal-best target** for that course and control,
with a one-time celebration when you pass it. Cleared gates bloom with flowers;
perfect passes earn a gold seal.
Each bird has a signature trail: Pip's bubbles, Peaches' hearts, Minty's leaves,
and Orbit's stardust. Preview them in the crew screen; Reduced Motion freezes
their decorative movement.
In flight, each bird's wing follows your push-up range or makes a short stroke
after a jump boost, with a small air wake. Reduced Motion keeps the pose neutral.
The crew also reacts with pleased eyes after rewards, a brief startled look for
bumps, and occasional blinks. These expressions follow replay time and stay
neutral under Reduced Motion.

Pre-endless Star Trail journals approach gold finish pennants in their last six
seconds. Completed routes add a matching ribbon medal to the result portrait.

**Flight goals:** earn three wings in one scored flight. Classic rewards 5, 10
and 25 gates; Star Trail rewards 12 stars, a six-star streak and a full trail.
Open Flight
goals from Home to see the targets, or tap a result's wings for progress. Results
keep Save session visible, then offer Watch replay directly after saving.

**Knockouts:** losing your last heart plays a short cartoon knockout. The flight
freezes for a beat with a flash and a camera kick. The bird's eyes turn to dizzy
spirals, feathers in its own colours burst out and stars circle its head as it
tumbles off the bottom of the screen. In the Pirate Captain's sea it splashes in
instead. The world settles into a dim lavender still. After 1.9 seconds a
**Bonk!** (or **Splash!**) game-over stage drops in over the frozen flight. The
dazed bird rides up on a cloud, the score counts up, a new personal best gets
a ribbon, and **Fly again** leads Home and Save session. Wings, stats, passport
and postcard links and save retries all stay on the stage. Taps in the first
0.6 seconds are ignored; after that a tap skips to the stage, whose buttons
respond once they have landed. Reduced Motion fades the dazed bird out in place
instead. The run is saved the moment it ends, and replays are unchanged. Other
endings, such as Finish flight, still open the regular results. Run
`flutter test --no-pub --dart-define=CAPTURE_VISUALS=true test/knockout_art_test.dart test/game_over_stage_test.dart`
to render review frames into `build/visual-review/death/`.

**Status:** tracking has regression replays from the OnePlus CPH2585's actual
landmarks, including the latest scored game's missed top, false calibration
cycles during a held top, calibration asking to push back up while both arms
were already straight, the bird dropping to mid-screen on a slight bend, and a
calibration top (and side view) taken while the player was still standing.
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

Regenerate typed native bindings and database code after schema changes
(`make generate` runs both; the database is at schema 5):

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
Menus play a cheeky violin-led ElevenLabs instrumental; flights switch to a
punchy orchestral variation of its insistent 3+3+2 hook, and bosses bring in a
separate, darker version. Music returns
to the flight theme after the boss departs. All tracks play offline and follow
the music setting. Effects mix with the soundtrack, and boss cinematics lower
the music volume.
See [music source and preparation](docs/music.md).
The game also bundles 56 mastered sound effects and variations for flight,
combat, boss cinematics, pickups and menus. See
[sound effects and preparation](docs/sound-effects.md).

The body controller deliberately ignores facial landmarks. Side views need one
tracked shoulder, elbow, wrist and hip. Front views need both shoulders plus one
arm and hip. Standing or kneeling upright never counts as being in position,
even with straight arms: then the arm hangs within 45° of a torso seen at full
length, with the hand down towards the hip, while a plank holds the arm across
the torso (side view) or foreshortens the torso well below the arm (front view).
The frames of the first steady top vote on the view, which is then fixed so
occlusion cannot change the measurement system mid-flight; a tracking loss over
0.5 s during calibration releases it, and a changed view relearns both cycles.
All measurements tolerate camera roll. Uncertain knees and ankles do not block
calibration. This is a gameplay check, not a form assessment.

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
0.5×–2× speed, camera-corner placement, recorded-audio mute and game sound on/off.
Delete removes replay files; Reset local progress removes all
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
