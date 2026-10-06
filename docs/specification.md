# Beakbound — a bird courier adventure

## Summary

Build a colorful, competitive, offline arcade game. The main game is flown
with taps: the **Campaign** (a trip around the world, level by level) and the
**Endless** flight (Tap & Fly on Star Trail). The camera workouts and Fly
Together (two players, one phone) are the **mini games**. Four controls:

- **Push-Up Flight:** body position controls bird height continuously. Pushing up raises the bird; lowering yourself brings it down. The face does not need to be visible.
- **Squat & Fly:** squat to descend and stand to rise, with both feet planted. Calibrate a comfortable range before flying.
- **Tap & Fly:** tap to flap and shoot bats without a camera.
- **Jump & Fly:** a standing body-camera mode where each small jump triggers a stronger bird boost. Landing prepares the next boost.

Deliver Android first, with shared game logic and interfaces designed for a later iOS release and additional exercise games.

### Endless progression

New flights have no time limit. Collision, tracking and voluntary-ending rules
still apply. Replay rules version 12 starts at the familiar course speed, then
smoothly approaches 1.65× over several minutes.
Points do not change the pace. During a match, the HUD shows score (and an
active multiplier), hearts and shield status. Magnet charge/duration and jump
glide use compact icon meters. Endless
flights omit elapsed time, pace, repetition counts, record targets, wing goals
and standing instructions. Tracking feedback appears only when tracking is lost.
Pause/stop and Shoot use illustrated circular controls; Shoot's rings show the
ammo reserve and held charge without losing its icon. State changes use finite pulses, and controls
compress on press. App and system Reduced Motion disable decorative animation.
Passive readouts pass touches to the sky; control touches never flap, including
during cooldown. Countdown teaching and post-flight statistics remain available.

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
and sun-wheel blades stay inside their circular bodies. Decorative motion honors Reduced Motion.

Version 14 keeps the version 13 movement, spawning, collision and cadence, and
changes presentation only. All seven families, including garden gates, use
the new authored detail variations. Saved version 13
replays keep the previous obstacle artwork. Reduced Motion still freezes
optional decoration while gameplay geometry moves as before.

Version 16 redraws garden structures as a brass conservatory, terracotta blossom
column and bamboo grove. The first three garden obstacles use appearances
0, 1, and 2 in that order so those structures
show up immediately. That choice still consumes the same random draw, in the
same place in the sequence, so later obstacle geometry matches version 15.
Enemy appearance is decoration only and cycles through a moon bat, armored
beetle and dusk moth, including helpers summoned in a boss fight. Saved version 14 and 15 replays keep
the previous garden and enemy artwork. Boss encounters still begin at version 15.

Push-up and squat targets stay at the calibrated endpoints; moving walls always
leave clearance there. Passage spacing accounts for the widest obstacle, the
leading star trio, the measured half-cycle and a reaction allowance. For flap
controls, stars follow moving openings. Pauses freeze obstacle motion, and
Reduced Motion removes decorative spin while keeping gameplay motion visible.

The 60-second Star Trail wing is a survival milestone;
daily goals and Trailblazer count saved flights lasting at least 60 seconds.
Pre-version-12 journals retain static gates, score-based speed and their timed
finishes, including arrival art. Version-12 journals retain their four-pattern
shuffle, random sequence, original spacing and artwork.

### Enemy health and weapon damage (rules version 26)

Touch combat uses integer HP and per-projectile damage. The base weapon deals
10 damage per shot. Both bat kinds start at 10 HP, spitter beetles at 20 HP and
dusk moths at 30 HP. At spawn, add 5 HP for every defeated boss, capped at 20
extra HP. Apply the same calculation to ordinary enemies and boss helpers;
never change an existing enemy's health when the weapon or encounter changes.
Enemy and boss constructors also accept a positive `maxHp` override.

Multiply the existing boss HP formulas by ten: Baron Bat starts at 120 HP,
Spitter King at 180 HP (210 HP from rules version 37) and Dusk Empress at
240 HP, with 30-HP progression steps and caps of 240 / 300 / 360 (330 for the
Spitter King from rules version 37). This retains the earlier boss fight
lengths with the base weapon while supporting upgrades smaller than one old
hit point.

Each accepted shot captures the current positive weapon damage. A hit consumes
the shot, subtracts its damage and clamps health to zero. Partial hits leave
enemies alive, play an impact cue and show a proportional health bar. Award
kill points, death cues and victory cleanup exactly once on reaching zero.
Boss fury starts when damage crosses half health, including hits that skip the
exact midpoint. Shields and arrival invulnerability still block damage.
The boss bar's damage trail follows the actual HP lost, with a bounded number
of segments so large health pools stay readable.

`PlayController.weaponDamage` supplies the starting loadout; live changes go
through `FlightRecorder.setWeaponDamage`. Record both the initial damage and
change events for deterministic playback and backward seeks. An upgrade does
not change airborne ammo or reset the firing cooldown. Rules 1–25 keep one-hit
small enemies, their original boss HP, and one damage per boss shot.

### Breakable wall openings (rules version 27)

After defeating boss 2, each eligible touch-combat passage has a seeded 25%
chance of being an ordinary garden wall with a breakable stone panel filling
its opening. Keep the upper and lower wall sections intact. Do not place panels
in consecutive passages, on the pending reward-heart gate, or alongside a new
enemy on the same approach. Scrolling, gravity, flapping, boss timing, pickups
and ordinary wall collision rules continue normally. No separate encounter,
hover, timer reset, or waiting at the panel.

The panel has 40 HP: four base shots break it, and weapon upgrades may need
fewer. Hits outside the gap strike the permanent wall without damaging the
panel. Damage, health and collision are unchanged by the artwork described
below, which is a pure function of the panel's own clock and the blows it has
taken (each blow's height, damage and whether it was a sprint ram), so pause,
replay seeks and a second panel with the same seed paint identical frames.

*Appearance.* A sealed stone gate plug: bevelled lilac-grey granite blocks,
a raised keystone holding a gold sun-and-bird medallion, two dark iron straps
with gold inlay (the upper one carries the four health gems, one per quarter of
health), moss and weathering. It sits in a reinforced collar drawn over the
wall ends (a stone band with gold trim, teeth and rivets, at most 0.046 of the
view high, inside the wall bodies and never wider than the wall). All other
panel artwork stays inside the opening. The sheen crossing the gold and the sun's
slow glow are idle motion and are skipped in Reduced Motion.

*Every blow.* A starburst, a shock ring and gold sparks fly back toward the rock,
stone chips and a small puff of dust are thrown out (bigger for a charged shot),
the slab shudders inside the opening, a crater is bitten out of the left face at
the height of the hit and the cracks grow outward from it. At 75%, 50% and 25%
health the panel therefore has one, two and three craters, back-face chips and a
wider web of cracks, with the health gem for that quarter darkened. The
reaction lasts about half a second; no solid artwork leaves the opening.

*The killing blow* clears the opening's collision on the very step it lands and
plays a 1.0 s animation from that instant (`SkyDoor.crumbleDuration`):

- 0-50 ms: white-gold flash, a starburst and shock rings at the strike, the slab
  strains and every crack races across it (hit-stop).
- 50-120 ms: the slab lets go along its cracks into about 15 to 25 shards, from
  chunky slabs to gravel; the two iron straps snap, rivets pop, the medallion
  pops off and coin-flips out, dust blooms at the strike, both seats and the
  far face, grit and pebbles spray.
- 0.12-0.5 s: shards tumble under drag and gravity, closest pieces fastest;
  the medallion twinkles as it falls; dust billows and rises.
- 0.5-0.95 s: every piece shrinks away (no fading layers) and the last dust
  thins out; the medallion bursts into sparkles.
- Afterwards only the wall's chewed sockets remain, inside the wall bodies: a
  jagged lip, fresh pale breaks, cracks, dust stains and the stubs of the
  gold brackets. Nothing stays in the opening.

A charged rock throws more and finer debris than a base rock, and a sprint ram
throws bigger pieces further and higher. The shards are the cells of the same
fracture pattern whose seams were drawn as cracks on the damaged panel, so the
break continues the cracks already seen. The aiming mark returns once the debris
has cleared (0.45 s). Destruction gives no extra score, a single break/unlock
cue plays and the surrounding walls remain solid; an intact panel uses normal
wall collision damage. Reduced Motion keeps the static damage stages (craters,
cracks, gems) without shudder, sparks, dust, debris or sheen, and a destroyed
panel disappears at once. Rules 1–26 retain the previous route with no
breakable panels.

### Wall rebounds (rules version 31)

A rock hitting a solid wall or breakable panel stays visible. The wall absorbs
energy, sending the shell back at 45% of its incoming speed relative to the
scrolling wall. A small upward kick gives way to a gravity-driven fall. Remove
it only after it leaves the left or bottom of the view. Panel damage and the
impact sound occur once; returning shells cannot damage targets or cancel
enemy ammo. Shots through a clear opening continue straight.

Briefly squash the stone at impact, then tumble it without the forward flight
trail. Reduced Motion keeps the rebound and fall while omitting squash and
spin. Pause freezes the trajectory, and replay seeks reconstruct it exactly.
Rules 1–30 retain their original consumed-on-impact behavior.

### Power shots and ammo reserve (rules version 28)

Pressing Shoot starts a charge; releasing fires. Charge is continuous: the
held simulation time divided by one second, clamped to 0–1. A released charge
`c` scales rock radius by `1 + 1.4c` and damage by `1 + 3c` (rounded), so a
full charge is 2.4× as wide and deals 4× the current weapon damage. The rock
keeps its captured damage and radius through every hit test, including walls,
panels, enemies, enemy ammo and bosses.

Every shot spends from one reserve that starts full (1.0). Cost is
`0.10 + 0.35c`. The reserve refills at 0.40 per second only after 0.45 seconds
without a fired shot, so repeated taps at the 280 ms cooldown receive no refill.
Charge cannot exceed what the reserve can pay. Below one tap's cost, a release
fires nothing, counts a dry fire and plays the empty cue; a held press keeps
charging as the reserve refills. The cooldown still applies to releases.
While the reserve cannot pay for a tap, hide the held rock at the beak and
show “Reloading…” on Shoot with a muted icon and no charge ring. Keep that
feedback while the button is held, returning to the charge preview as soon
as enough ammo has refilled for a shot.

A press may start during a cooldown or refill, and a control touch never flaps.
Pause, background, flight end and a boss entrance cancel a held charge, and a
resumed flight starts without one. The charging rock grows forward from the
beak with a yellow glow. At full charge a white rim counts down the 500 ms
that charge can stay held; when the window ends, the simulation fires
the rock during the tick. A release after that does not fire again. A charge
the reserve has not yet let reach full can be held until it does, and the
500 ms start then. Shoot's outer ring shows the reserve, with the pending
cost in yellow, and its inner ring shows the charge, then that same countdown.
Semantics report ammo, charge, the remaining full-charge time, or refill
state. Record `charge` on press and `shoot` on release, deriving charge from
simulation time for deterministic seeks. An unreleased full charge needs no
shoot event. Rules 1–27 reject `charge` events and keep unlimited
cooldown-limited taps.

### Pellet shatter (rules version 36)

A rock with charge `c ≥ 0.35` that meets a small-enemy pellet shatters it
instead of just cancelling it. 0.35 is also the point where the fire cue
changes to `power_shot`. The rock is spent as on any cancel, and the
interception still counts as a deflection. The blast is centered on the pellet
and has reach `0.12 + 0.12 × (c − 0.35) / 0.65` height units, so 0.12 at the
threshold and 0.24 at full charge. Every small enemy whose 0.045-unit hit
circle touches it takes `max(1, round(damage × 0.5))` of the rock's captured
damage. That is 20 for a full charge with the base weapon, enough for bats and
beetles; moths survive. Defeats award the usual reward and defeat event. An
attacking boss inside the blast (its body, or the veil while shielded) takes
the same damage, and a raised veil absorbs it instead. Blasts resolve after
the tick's pellet sweep, so a blast that defeats the boss clears the remaining
ammo as a normal victory does. Weaker rocks keep the plain cancel.

From rules version 59, the blast also destroys every small-enemy pellet whose
0.016-unit hit circle touches its radius. Each destroyed pellet counts as a
deflection and plays the existing deflect splash, without creating another
blast. Boss ammo is unaffected. Rules 36–58 keep their original blasts that
damage enemies but leave nearby pellets in flight.

### Upgrades (rules version 60)

Stars collected on scored flights (non-practice `runs.stars`, endless and
campaign) form a wallet; buying an upgrade level adds its cost to the
`starsSpent` preference, and each level is stored as `upgrade.<name>`.
Purchases run in one transaction and are refused at the top level or when
`earned − spent` is below the cost. Reset clears both. Levels run 0–4 and
cost 50, 120, 250 and 450 stars. A new flight takes the saved levels
(`PowerUps`) and its replay records them as `upgrades`; journals before 60
always fly `PowerUps.legacy` (shot 4, sprint 4, shield 4, magnet 3), which is
exactly the earlier behavior.

- Shot power caps the charge at 0.40, 0.55, 0.70, 0.85, 1, so even level 0
  reaches the 0.35 shatter charge. The charge grows at
  the usual rate; the 500 ms full-hold window starts at the cap, and the
  inner ring beyond the cap stays dark.
- Sprint lasts 0.9, 0.95, 1.0, 1.1, 1.2 s with cooldowns of 25, 22, 19, 17,
  15 s. The surge and ease keep their lengths inside the shorter burst.
- Shield is restored every 15, 13, 11, 10, 9 stars, and the recovery after it
  absorbs a hit lasts 0.6, 0.8, 1.0, 1.25, 1.5 s. A lost heart keeps 1.5 s.
- Magnet needs 5, 4, 4, 3, 3 perfect gates, lasts 5, 6, 7, 8, 10 s and has a
  pickup radius of 0.16, 0.17, 0.185, 0.20, 0.22.

Draw a burst that shows the blast reach, anchored in the world, in place of
the deflect splash. Play `lava_burst` under the `deflect` cue. The record is
render-only and pruned after one second. Boss arrival clears it. Reduced
Motion shows a still mark. Blasts are part of the seeded simulation, so
replays and seeks reproduce them with no extra events. Rules 1–35 keep the
plain cancel.

### Sprint (rules version 29)

Touch combat adds an 80 dp Sprint button to the left of Shoot. A press starts
a 1.2-second burst and a 15-second cooldown measured from the press. The bird
keeps its screen position while the course scrolls faster: the multiplier is
`1 + 1.5e`, where `e` rises with a smoothstep over the first 0.15 seconds and
falls with one over the last 0.40 seconds. Speed peaks at 2.5× and is back to
normal when the burst ends. Spawning follows distance, so a sprint reaches the
next passages sooner without shortening the spacing between them. Enemy and
boss projectiles also move left by the extra scroll, so they reach the bird
sooner in normal flight and boss fights. A boss holds its place on screen.
Gravity and flapping are unchanged, and a Sprint press never flaps.

During the burst, an enemy touching the bird is defeated regardless of its
remaining HP. It counts as a normal defeat with the same score, uses a
separate `enemyRammed` event and shows “SMASH”. A stone panel touching the bird
loses all its HP and breaks with the usual debris and cue. The upper and lower
wall sections, the course edges and enemy and boss projectiles still cause
their normal damage. Countdowns, pauses, flight end and boss cutscenes block a
sprint. Pausing freezes both the burst and the cooldown.

When ready, the button is teal with a full ring and pulses. While sprinting,
it turns gold and the ring drains with the burst. While recharging, it shows a
muted icon, the whole seconds left and a teal ring that refills. Semantics
report “Ready”, “Sprinting” or “Recharging, N seconds”. Light streaks cross the
sky with the speed boost (omitted in Reduced Motion). Trailing wind lines and a
bow wave in front of the bird last the whole burst; Reduced Motion keeps them
without the pulse. A whoosh plays on each sprint and a chime plays when a used
sprint recharges. Record `sprint` for accepted presses only. Rules 1–28 reject
`sprint` events and have no Sprint button, and camera controls never show one.

### Rush paths (rules version 32)

Touch Star Trail flights hand the course over to a short rush path between
bosses. The first is laid 22 seconds into the flight; each later one 18
seconds after a boss leaves, or from rules version 33, 8 seconds after the
gale that follows a Dusk Empress. A run needs at least 18 seconds before the next
boss is due, otherwise it waits for the victory. A boss waits for a run in
progress and arrives no sooner than 8 seconds after its escape.

Each run brings danger from one side: Wildfire from behind, Skyfall from
above, Eruption from below and Swarm from ahead. Runs draw their kind from a
bag holding all four in a seeded shuffle, so every four runs meet each kind
once, in an order that differs between flights. When the bag refills, a kind
that would repeat the last run moves to the back of the new round.

Ordinary passages stop while a run is laid. It starts 0.45 after the last
passage, and never before it is off screen. Six beats, 1.15 apart, each hold
three stars in a trio leading into a gold sprint ring at the same height.
Every other beat has a bat just after the ring. The beat ends with a rubble
barrier 0.16 wide whose 0.36 opening sits at the next beat's height, so the
rings and openings trace one route. The first height continues from the last
passage, clamped to 0.3–0.7. Each beat moves 0.16–0.32 up or down, reflected to
stay within 0.24–0.76. 1.6 before the bird reaches the first beat, a large
banner naming the kind (“WILDFIRE!”, “SKYFALL!”, “ERUPTION!” or “SWARM!”) and
an alarm give warning.

**Ring sprints.** Flying within 0.08 of a ring starts a 2-second ring sprint.
The course scrolls at `1 + 2e`, where `e` rises with a smoothstep over 0.15
seconds and falls with one over the last 0.50, so speed peaks at 3×. A ring
collected during a sprint restarts the 2 seconds from the current speed, so a
chain holds top speed with no dip, and the chain count rises (“RUSH ×N!”).
From rules version 51, collecting all six rings of a run adds 2 seconds to the
last ring sprint, so it holds 3× for 3.5 seconds before its 0.50 ease
(“ALL RINGS! +2s BOOST”). That callout outranks the smashes that follow it.
Missing any ring of the run earns no bonus, and such a flight flies exactly as
at 50. Rings never use the Sprint button or its cooldown. When both sprints overlap,
the course takes the faster boost.

Either sprint rams: it defeats bats and other small enemies it touches, and
it breaks rubble. A ring sprint also breaks ordinary walls and their stone
panels. A barrier breaks whole as the bird passes through its width, with a
bow wave reaching 0.04 beyond the bird, whether the bird is in the opening or
not. Each break scores 2 points and has no collision afterwards. A broken
ordinary wall still counts as a passed gate. Rubble never counts as one.
Consecutive breaks, rams, meteor smashes and swarm smashes during one sprint
build a chain (“SMASH ×N!”). Without a sprint, rubble is a wall. Course edges,
lava, and enemy and boss projectiles hurt as usual during either sprint.

**Wildfire.** When the bird reaches the first beat, a wall of flame appears
0.40 behind it and advances at 1.25× course speed, whatever the bird's own
speed. A ring sprint drags the fire along no more than 0.46 behind, with its
flames licking the left edge. When the flames reach the bird, the bird takes
damage unless it is invulnerable, the label reads “SCORCHED!”, and the fire is
knocked back to 0.75 behind, off screen. Ignoring every ring costs two or
three hits in a run; missing one or two in a row costs none.

**Skyfall.** The first meteor falls 0.5 seconds after the run starts and
another every 0.8 seconds. Meteors start 0.35 above the view and drift 0.40
left over a 1.25-second fall. They alternate between aimed and scattered:
- An aimed meteor crosses the ring route's height where the bird would be
  after 1.25 seconds at its current speed. A cruising bird on the route has to
  dodge it, and a sprinting bird meets it.
- A scattered meteor lands at a random height from 0.12 to 0.88, where a
  cruising bird would be.

A marker at the top edge shows each meteor while it is above the view. A meteor
touching the bird hurts it, unless the bird is ramming: a ram smashes the
meteor for 1 point, and the bow wave reaches 0.04 further. A rock that is not
rebounding also smashes a meteor.

**Eruption.** Every beat after the first has a lava vent 0.10 wide among its
stars, 0.30 into the beat. Its plume stands 0.08 above that beat's route
height, but its top never rises above 0.30, so a bird can always hop over it.
A vent starts rumbling when the bird is 1 second away at course speed and
erupts 1 second later, just as a cruising bird arrives. A bird that passes
0.15 beyond a rumbling vent sets it off at once, so a ring sprinter sees the
blast go up just behind it. The plume shoots up in 0.10 seconds and sinks over
the last 0.25 of its 0.8 seconds. Touching the plume, from its top down to the
ground, hurts unless the bird is invulnerable, and the label reads
“SCORCHED!”. Lava cannot be smashed, and a sprint gives no protection from it.
Missing a ring leaves the bird cruising into the next vent; flying over the
plume's reach also avoids it.

**Swarm.** From 0.3 seconds after the run starts, a flock of three bats
arrives every 1.4 seconds. The bats enter 0.1 beyond the right edge, 0.11
apart, and fly left 0.50 faster than the course scrolls. Flocks alternate
between the ring route itself and 0.11 above or below it, on a random side.
Each bat follows its lane through the barrier openings with a 0.012 bob. No bat
spawns past the final barrier. A swarm bat touching the bird hurts it unless
the bird is ramming: a ram smashes it for 1 point and extends the smash chain.
From the route, the bow wave reaches the side lanes as well. A rock that is not
rebounding also downs a swarm bat. A slower bird meets more flocks.

**Escape.** Passing the final barrier escapes the run for 10 points, plus 10
more if nothing hurt the bird after the run started (“ESCAPED! +10” or
“FLAWLESS! +20”). The fire burns out over 1.6 seconds. Ordinary passages resume
behind the final barrier, with their first opening continuing from its height.
Replay highlights and the escape banner name each escape: “Outran the
wildfire”, “Survived the skyfall”, “Beat the eruption” or “Plowed through the
swarm”.

**Presentation.** Each run has its own look:
- Wildfire: a warm smoke band, sandstone barriers with ember seams, and flame
  layers with embers.
- Skyfall: a violet sky with falling streaks, violet stone barriers with teal
  cracks, and meteors with fiery tails and magma seams.
- Eruption: a red glow rising from the ground with ash and sparks, basalt
  barriers with lava seams, and basalt vent mounds. Before a vent erupts, a
  faint column with a red dashed cap marks the plume's reach. It brightens and
  blinks while the vent rumbles and bubbles. The plume is a layered, wobbling
  lava column with a rounded head, a glow and flung droplets.
- Swarm: a dusk-indigo haze from the right with distant bats streaming left,
  and mossy slate barriers with gold cracks. Flocks on the route are small
  purple bats and flocks beside it are cave bats. All of them trail speed
  streaks, and each smash bursts like a defeated bat.

Barrier seams glow while the bird is ramming. Breaks burst into tumbling chunks
and dust, and each break, ram, meteor smash, swarm smash or eruption shakes
the camera, the fire or lava catching the bird the hardest. Rings slide
chevrons and set off sonic-boom rings when collected. A ring sprint adds gold
overdrive streaks, a bow wave and three gold afterimages.

Reduced Motion omits the streaks, afterimages, debris, embers, ash, lava
droplets, vent bubbles and camera shake. The flames, plumes and rings stay
still, a rumbling vent brightens without blinking, and banners appear without
a pop.

**Audio and replay.** Audio cues:
- A ring chime climbs a whole tone per chained ring, up to the third.
- The first ring of a chain also plays the sprint whoosh and voice.
- Breaks and meteor smashes crunch.
- Each eruption plays a lava burst.
- Swarm smashes play the enemy defeat sound.
- The warning plays an alarm and an escape a fanfare.

Rush paths are part of the seeded simulation, so replays and seeks reproduce
them exactly with no extra events. Rules 1–31, camera modes and Classic have
no rush paths.

### Gales (rules version 33)

Touch Star Trail flights add a gale after each Dusk Empress victory and after
no other boss. Ordinary walls return first. The gale is laid 12 seconds after the Dusk Empress leaves and replaces
nothing: that interval's rush path waits for it.

When the gale is laid, ordinary passages stop. The wind rises where the bird
is 0.45 past the last passage, and never less than 1.2 ahead of the bird. A
large “GALE!” banner and the rush alarm give warning 1.2 before that point.

**Tailwind.** The course scrolls at `1 + 0.6w`, where the wind `w` rises with
a smoothstep over 1.2 seconds, so speed peaks at 1.6×. The gale blows for 13
seconds, then `w` falls with a smoothstep over 1.5 seconds. When both a sprint
and the gale are active, the course takes the faster boost.

**Debris.** The first gust comes 0.5 seconds after the wind rises. Gusts then
follow every 1.2 seconds, shortening steadily to 0.85 seconds by the end. None
start in the last 1.6 seconds, so the last pieces clear as the wind drops.
- Every gust sends one piece at the bird's height at that moment, clamped to
  0.12–0.88.
- Odd gusts add a second piece 0.30–0.44 above or below it, reflected to stay
  within 0.12–0.88, and 0.15 further back. The bird has to pick the open side.

Each piece starts off screen and appears at the right edge 0.9 seconds later.
Meanwhile a warning lane runs in from the right edge at its height. An
exclamation mark stands at the lane's inner end, 0.6 in from the edge, clear
of the pause, Shoot and Sprint controls, and a gust whistle plays. A piece flies level at 0.9 plus course speed, so it crosses a
phone screen in about a second. Its hit circle has radius 0.05.
Over Brazil (Carnival Skies, 1-4, or an endless leg there) the pieces are
footballs in four kits, and a strike tears up turf instead of splinters
(`lib/game/gale_football_art.dart`). A piece keeps the region it was
launched in. This is art only: the rules are the same everywhere.

Debris hurts on contact like a wall, sprinting or not. A shot rock glances off
it without breaking it. Each piece that passes the bird untouched scores 1
point. When the wind drops, the gale is weathered for +10 points, or +20 if
nothing hurt the bird while it blew. A banner (“WEATHERED! +10” or
“FLAWLESS! +20”) and the rush fanfare mark it. Ordinary passages resume at
once, clear of the last debris.

**Afterwards.** The rush path follows 8 seconds after the gale, and the next
boss waits at least 27 seconds after it, so the rush path keeps its full lead.
A boss never arrives during a gale.

**Audio and replay.** The warning banner plays `rush_alarm`, each gust
`gust_warning`, and the weathered banner `rush_clear`. A weathered gale is a
replay highlight (“Weathered the gale”). Gales are part of the seeded
simulation, so replays and seeks reproduce them exactly with no extra events.
Rules 1–32, camera modes and Classic have no gales.

### Rising gales (rules version 65)

Each endless gale after the first blows one step fiercer than the one before
(its fury), up to three steps: the fourth gale and every later one blow at
full fury. The first gale of a flight is unchanged. Each step adds:

| Fury | Blows | Peak speed | Gusts every | Paired gusts | Debris speed |
| ---- | ----- | ---------- | ----------- | ------------ | ------------ |
| 0 (first) | 13 s | 1.6× | 1.20 → 0.85 s | odd ones | 0.90 |
| 1 | 15 s | 1.7× | 1.12 → 0.77 s | two in three | 1.05 |
| 2 | 17 s | 1.8× | 1.04 → 0.69 s | all but the first | 1.20 |
| 3 (cap) | 19 s | 1.9× | 0.96 → 0.61 s | all but the first | 1.35 |

Debris speed is added to the course speed. The warning still leads every
piece by 0.9 seconds, the calm still comes 1.6 seconds before the end, and
the bonuses are unchanged. A full-fury gale sends about 22 gusts and 43
pieces where the first sends 11 and 16. The cap is set so that a pilot
flying real taps, reacting 0.3 seconds after each warning at the course's
top pace, still weathers a full-fury gale without a hit (`test/gale_test.dart`).
Campaign gales and flights recorded below 65 blow as at 64.

### Pause and resume (rules version 35)

From rules version 57, new flights count down 2–1. Retry skips the countdown
and starts on the first valid game frame, reusing camera calibration when
available. Saved replays from earlier versions retain their original timing.

Scored flights can pause. The pause button (shown for every flight) opens the
“Take a breather.” panel with **Finish flight** and **Keep flying**. Taking a
break or backgrounding the app pauses a scored flight instead of ending it, and
a flight already paused stays paused through a background. Keep flying starts a
two-second resume countdown (2–1, from rules version 57): tracking must be fresh, the
camera restarts if the app left it, and a held charge is cancelled. Pauses freeze
every clock, so they never change collision, attack or score timing. A collision,
long tracking or posture loss and a simulation stall still end a scored flight,
and Finish flight ends it with the break reason. Rules versions 1–34 keep ending
scored flights on a break or background, so older replays reproduce exactly.

### Knockout and game-over stage (presentation only)

A flight that ends with `EndReason.collision` (the last heart, or any Classic
collision) enters `PlayStage.fallen` before `PlayStage.results`, in every
control mode. `_finish` still builds the
`RunResult`, plays `game_over`, stops the camera and saves the run at the moment
of the bump, so an app killed mid-animation keeps its run. The rules, journal,
`RunResult` and replays do not change: the knockout has its own clock
(`PlayController.knockout`), advanced by the game loop's frame time and passed
to `BirdGame`. Every frame of `KnockoutArt` is a pure function of that time and
the ended simulation. Replays pass no clock and keep the plain ended frame.

- **0–0.1 s:** hit-stop. The frozen flight gets a white flash, a camera kick and
  a starburst at the contact point. The bird squashes, wide-eyed and blown out
  to white.
- **0.1–0.5 s:** the bird pops up and back, grows slightly so it reads at
  gameplay size, and switches to the `dazed` expression (dizzy spirals). Eight
  feathers burst out in its colours, with Peaches' hearts and Orbit's
  sparkles. Three stars circle its head.
- **0.5–1.3 s:** it tumbles backwards and falls off the bottom of the screen.
  During the Pirate Captain's encounter it plunges into the sea, making a crown
  splash with sheets, drops, rings and bubbles, and plays `sea_splash`.
- **To 1.9 s:** the feathers flutter down and fade. The world, dimmed and
  desaturated under a lavender tint since the bump, settles into a still, and
  the camera eases in 3.5%.

The HUD hides for the whole sequence, and floating callouts and rush banners
are not drawn. Taps before 0.6 s do nothing, including flaps. After that, a tap
anywhere skips to the stage. Backgrounding jumps to the stage. Back or Home
leaves after the in-progress save completes. If frames stop, a fallback timer
shows the stage 1 s after the knockout should have ended. Reduced Motion swaps
in the dazed face under three still stars and fades the bird out in place over
1.2 s, with no spin, shake, flash, zoom or particles.

The game-over stage (`GameOverStage`) sits over the frozen, dimmed world under
a deeper vignette, and the flight's game loop pauses once its last frame is
painted. It reads left to right. On the left, a **Bonk!** title (**Splash!**
at sea) drops in letter by letter over a friendly caption on a cream plate. The
dazed bird rides up on a cloud in a soft spotlight, with stars circling on a
faint ring. It shakes it off and looks ready to go at about 4.2 s. On the
right, an ink-framed scoreboard counts the score up beside a personal-best
plaque. A new best keeps the old record on the plaque until the count lands.
Then the plaque turns gold under a **NEW PERSONAL BEST!** ribbon. Below that
come this flight's stats as tiles (reps or flaps, flight time, perfect passes,
then streak or rank). A progress row follows, with flight wings (goal details
on tap) and the postcard, stamp-earned or next-stamp link (with a progress
bar). Last come save status with tap-to-retry, and session and camera messages.

The actions sit under the scoreboard, in the same place after every flight.
**Home** and **Save session / Watch replay** are cream keys. **Fly again** is
the large coral key, in the home screen's physical key style. It pops in last.
The actions arm once the entrance settles (about 0.9 s, or 0.3 s with Reduced
Motion). Fly again hops with a glint when the bird looks ready. Reduced Motion
fades the stage in with no drops, count-up, shake, hop or glint, and the bird
stays dazed under three still stars. The award chime waits for the stage.
Other endings still open the regular results panel.

### Finish-line celebration (presentation only)

A campaign level whose bird crosses its finish line enters
`PlayStage.celebrating` before `PlayStage.results`. Like the knockout, `_finish`
still builds the `RunResult`, stops the camera and saves the run at the
crossing, and the rules, journal, `RunResult`, stars and replays do not
change: the celebration has its own clock (`PlayController.celebration`),
advanced by the game loop's frame time and passed to `BirdGame` (`finish`).
Every frame of `FinishCelebrationArt`, and the gate's part in
`FinishGateArt`, is a pure function of that time and the ended simulation.
Endless, co-op, duel and timed-route endings never celebrate.

- **The approach (last 3 s).** `FinishGateArt.approach` rises from 0 to 1 as
  the line nears at the flight's speed. Sixteen marquee bulbs round the
  FINISH sign flick on one by one from 2.6 s out (`finish_near`, an "almost
  there" sting, plays as they start), then chase round it. The glow column
  swells a little, the tape firms up, the flags and bunting quicken (their
  phase gains the integral of the approach, so it never jumps), and the
  HUD's route flag (`MatchRoute`) glows, twinkles and waves.
- **0–0.075 s:** hit-stop. The tape is drawn taut into a point at the bird's
  chest (the bird's height, or just under the beam when it crosses higher
  than the tape), a warm flash and a starburst mark the contact, the bird
  presses into the tape and beams, and `finish_snap` plays.
- **0.075 s:** the tape snaps. Its halves spring back to the beam and the
  foot like cut elastic, whipping past their roots and fluttering, until
  only a stub hangs under the beam. A ring spreads from the contact, the
  finial balls fire as confetti cannons (84 pieces and 8 curly streamers,
  laid by a fixed hash, under drag and gravity, flipping and swaying), the
  camera kicks and punches in 5.5%, the crest star spins two turns, swells
  and shines in a slow sunburst, the sign swings on its ropes, the marquee
  flashes together three times, and one medium haptic fires. A shield bubble
  still round the bird pops.
- **0.075–0.94 s:** the bird dashes on, clear of the gate, and flies a
  loop-de-loop (under itself when it crossed too high to loop over), shedding
  sparkles, in a soft halo that lifts it off the confetti. `finish_cheer`
  (0.12 s; the music ducks under it) and the `complete` fanfare (0.4 s) play.
  The world warms and brightens, the opposite of the knockout's dusk, and the
  flight HUD fades out (0.25–0.65 s).
- **0.94–1.7 s:** it swoops up over the crest and down towards the camera,
  growing about threefold, into the result's courier seat
  (`LevelResultStage.courierSeat`, worked out from the stage's own layout and
  safe area), landing in the courier's pose. `finish_swoop` (1.15 s) lands its
  cushioned "fwump" at 1.7 s.
- **1.7 s:** the result takes over (`handedOff`): its courier is already in
  the seat, beaming, and its cloud puffs in under it, while the title drops,
  the scoreboard enters and the confetti keeps falling behind the stage.
  The keys arm 55% into the 1.9 s entrance, 2.75 s after the crossing.
- **To 4.2 s:** the confetti falls out of the screen and the flight's loop
  pauses on the settled frame: the warm world, the lit gate and the sunburst.

Taps before 0.5 s do nothing; after that, a tap anywhere skips to the result,
whose courier then rises in on its cloud as before while the confetti keeps
falling (a skipped fanfare still plays). Backgrounding, pause and the back key
go straight to the result over the settled finish, and nothing reaches the
journal. If frames stop, a fallback timer shows the result 1 s after the
celebration should have handed over. Reduced Motion lights the gate, lets the
tape fade, fades in the still burst and the sunburst, keeps the bird in place
with its pleased face, and hands over after 0.8 s; the bird then fades out as
the calm stage fades in (0.5 s), with no flash, shake, zoom, spin or flying
confetti. A replay that reaches a level's crossing plays the same celebration
past the end of its tape, with the bird ending in a hover beyond the gate
since there is no result to land in; a seek to the end shows that settled
frame. At its busiest the celebration and the gate make about 430 draw calls
(at most 500, two layers and no blur, `test/finish_celebration_test.dart`).

### Pirate Captain (rules version 34)

The Pirate Captain joins the touch boss cycle as its fourth encounter:
Baron Bat, Spitter King, Dusk Empress, Pirate Captain, then the cycle repeats
(bosses 4, 8, 12…). He starts at 300 HP with 30-HP steps, capped at 420, and
summons no helpers. Rules 22–33 keep the three-boss cycle.

**The sea.** His encounter fills the bottom of the screen with water. It
rolls in during the first 55% of the arrival, from below the screen (1.12) to
a surface at 0.9, and drains away over 80% of the departure. The bird is hurt
when its bottom edge reaches the surface, like a course edge: Classic ends the
flight; Star Trail takes a shield or heart, and the bird splashes back out
with at least 80% of a flap's lift. The water never hurts during cutscenes.

**The tide.** Combat time runs a fixed 10-second cycle: calm until 3.0 s, a
1.3-second warning (the water does not move), a 0.9-second smoothstep rise to
a surface at 0.56, a hold until 7.4 s, and a 1.1-second fall back to 0.9 by
8.5 s. Fury never changes the cycle, and pause and seek restore it exactly.

**The ship.** The ship anchors at `max(birdX + 0.72, width − 0.5)`. The
captain's hit circle (the usual 0.115 radius) rides 0.2 above the water with
a ±0.008 bob, so the ship rises with every surge. Shots whose leading edge
reaches the hull (from 0.3 left to 0.34 right of the captain, below 0.1 under
his center) glance off like walls without damage.

**The cannon.** The cannon pivots 0.14 left of and 0.085 below the captain,
with a 0.075 barrel. Each cannonball (radius 0.027) is lobbed at a horizontal
0.5 per second (0.6 in fury) and falls at 0.8 per second², on the arc that
passes the bird's column at the aimed height. The first shot comes 1.4 s into
combat, then every 2.1 s (1.5 s in fury). Volleys alternate a single ball at
the bird with a pair at ±0.16. In fury, every third volley is a broadside at
0, ±0.26, which becomes the pair while the tide is up. Balls that climb above
the screen come back down; balls that fall into the sea splash.

**Audio and replay.** The fuse plays `cannon_fuse`, each volley
`cannon_fire`, each warning `tide_warning` (a ship's bell over swelling
water), each rise `tide_surge`, and cannonball or bird splashes
`sea_splash`. Splashes are render-only; the rules never read them.

### Ember Dragon (rules version 38)

The Ember Dragon, **Sovereign of the Burning Sky**, joins the touch boss
cycle as its fifth encounter: Baron Bat, Spitter King, Dusk Empress, Pirate
Captain, Ember Dragon, then the cycle repeats (bosses 5, 10, 15…). Every
other kind now returns every fifth boss (the Dusk Empress at 3, 8, 13…).
Rules 34–37 keep the four-boss cycle, and every older version keeps its own.
The dragon starts at 360 HP with 30-HP steps, capped at 480, so it has 360 HP
at encounter 5 and 480 from encounter 10. It summons no helpers and adds no
random draws: every choice it makes, its swarm flocks included, follows from
the clock and the bird's recorded height.

**The dragon.** It anchors at `max(birdX + 0.76, width − 0.5)` and hovers at
`0.5 + 0.07 sin(0.8 t)` in combat time. During the cinematic arrival it
swoops in low (`0.5 + 0.08 sin(πe)` over the entrance), so its raised head
and the roar stay in view. Its hit circle (the usual 0.115 radius) is its
heart, a molten core set in its chest. Wings, neck, head and tail are
scenery: shots pass through them.

**Fireballs.** Fireballs (radius 0.025) leave the jaws, 0.293 left of and
0.215 above the heart. The first comes 1.3 s into combat, then every 2.0 s
(1.55 s in fury), at 0.52 per second (0.62 in fury), aimed at the bird.
Volleys alternate a single fireball at the bird and a pair at ±0.22 rad that
brackets it. In fury, except on the debut, each single fireball splits 0.45 s
after launch, well short of the bird, into three embers (radius 0.016). One
keeps the fireball's heading and two fan out ±0.5 rad from it, all at its
speed. A splitting fireball shows three swelling embers inside and a
closing heat ring before it bursts.

**The breath.** Combat time runs a fixed 11-second cycle:

- calm until 4.0 s;
- a 1.5-second inhale (the warning) until 5.5 s;
- a 1.6-second blast until 7.1 s;
- calm again.

As the inhale begins, the dragon aims at the bird's height and picks one
band of sky to burn. Below 0.36 it burns the high band (0–0.5), leaving the
lower half safe. Above 0.64 it burns the low band (0.5–1), leaving the upper
half safe. Otherwise it burns the middle (0.32–0.68), leaving strips above
and below. The band is fixed until the next inhale. During the blast, a bird
whose circle overlaps the band is hurt like a course edge: Classic ends the
flight, and Star Trail takes a shield or a heart with the usual 1.5-second
recovery. There are no fireball launches from 1.0 s before the inhale to the
end of the blast, and the next one waits at least 0.9 s after it, so the
last fireballs have passed when the warning asks the bird to move. Fury
never changes the cycle, and pause and seek restore it exactly. Cutscenes
never burn. From anywhere in the band at the start of the inhale, a bird
tapping at most five times a second reaches the safe side before the blast
and can hover there through it.

**The open heart.** From the start of the inhale to the end of the flame
the heart's guard parts. Every hit on it, whether a rock or a shatter blast,
counts double. A bird hugging the flame's edge on the high and low breaths
can still reach the heart, and that is the risk the reward pays for.

**Swarm flocks (rules version 39).** 7.6 s into each breath cycle, half a
second after the flame gutters out, the dragon calls a flock of three swarm
bats, the same bats as the Swarm rush path's. They stream in from behind it,
spawning at `width + 0.1 + 0.11k`, level at the bird's height as the call
comes (clamped to 0.15–0.85). They fly left at course speed plus 0.5 with the
usual small bob. In fury, except on the debut, a second flock follows 1.4 s
later at the bird's height then. A flock bat behaves as it does on a rush
path: touching one hurts the bird (Classic ends the flight, and Star Trail
takes a shield or a heart). A sprint rams through it and a rock smashes it,
for 1 point in Star Trail. Both flocks have flown past the bird before the
next inhale, and the defeat clears any bats still flying. The flocks fly on
Classic too, which has no rush paths. Rules 38 dragons call none.

**Debut.** The first dragon of a flight (encounter 5) only ever burns one
half of the sky: the high band for a bird above 0.5 and the low band
otherwise, so the safe band is always a wide half. Its fury fireballs never
split, and no second flock follows in fury. From encounter 10 it brings the
whole fight. Replay derives the debut
from the recorded rules version and the bosses already defeated.

**Presentation.** The dragon faces the bird and fills the right of the
screen:

- obsidian-plum scales seamed with molten light and a banded amber belly,
  all one skin under one ink outline, so the neck, head, tail and legs grow
  out of the body with no seams;
- a swan-S neck under a big horned head: a burning slit eye, a great horn
  swept back and a gold circlet set with a ruby;
- a breastplate of plum plates around a faceted heart-gem, which part when
  the heart opens;
- two crimson wings on tapered bony arms with backlit membranes and a real
  wingbeat, where the wrist and fingers trail the elbow and the far wing
  rides higher and dimmer;
- clawed legs trailing in flight and a tail ending in a bone-and-membrane
  blade.

Every pose fits inside the screen at 640×360 and 800×360, and the dragon
sets itself apart from dark and violet skies with a rim of light rather than
relying on its ink alone.

Its poses:

- **Charging:** the jaws open over a forming fireball, and the idle sway
  settles so the fireball leaves exactly from the rules' mouth point.
- **Inhale:** it rears back, the heart blazes, fire climbs the throat
  plates and embers spiral into the jaws. It holds a quarter second at the
  top, then snaps forward as the flame ignites.
- **Blast:** the head drives at the band.
- **Call:** a winding-up and then a smaller roar, the head thrown back, as
  each flock takes wing. A cool violet summoning cue (rings, a bat sigil
  and bat motes) hangs ahead of the snout and never covers the face.
- **Hit:** the fills blow toward near-white.
- **Fury:** the body turns oxblood, the seams glow gold, the membranes run
  hot, flames lick along the wing hems and a ring of fire rolls out at the
  onset.

The warning washes the band in ember red with hazard stripes, marches a
dashed fire line along each edge the bird can cross, lights the safe side
cool and points chevrons toward it. A tag at the left edge spells the dodge
out (FLY LOW, FLY HIGH or CLIMB OR DIVE). It is sized to stay clear of the
bird's column, and its gauge fills through the inhale. The flame pours from
the jaws, widens to exactly the band and races across the sky. It reaches
the bird's column as the rules start to burn, never after. Its visible fire
covers the burn band to within a few pixels and never reaches past it, and
it lights the scenery along its path. When the breath ends it tears free of
the jaws and blows away. The health plate is obsidian with a lava gauge, a
gold fang at the fury mark and a crown medallion. It reads HEART ×2 while
the heart is open. The arrival warns THE SKY CATCHES FIRE, reveals a dark
silhouette with a burning eye and heart, unfolds the wings and roars a plume
of fire, and the name card slams in on the roar. The defeat whites out the
body, bursts it into burning scales and embers under ash smoke, tumbles the
circlet loose, and lets the heart-gem pop free and rise into a warm
victory sun.
Under Reduced Motion the wingbeat, sways and drifting particles hold still,
and the body fades before the burst instead of flaring through it. The
charge, inhale, flame, heart, hit and fury states stay visible.

**Audio and replay.** The inhale plays `dragon_inhale` (a vast breath drawn
in over a climbing growl), the blast `dragon_breath` (an ignition and a
roaring jet), and a split `ember_split`. The charge and volley share
`boss_charge` and `boss_volley`, each flock call plays `boss_summon`, and a
downed flock bat plays the enemy defeat sound. For 2.5 s after a call the
live semantics hint reads SWARM. Seeks replay silently. The burn and split
counters are presentation only, and the rules never read them.

### Baron Bat returns upgraded (rules version 40)

The first Baron Bat of a flight (encounter 1) keeps his original fight.
Every later one (encounters 6, 11, 16…) comes back upgraded, titled **THE
STORM RETURNS**, with one special ability, the sonic screech, and his small
bats sent two at a time. His position, hover, fireballs and fury threshold
are unchanged; his health is too until rules version 48, which doubles it,
and from rules version 53 it grows again at every return after that
(see below). He adds no random draws: every choice follows from
the clock and the bird's recorded height. Replay derives the upgrade from
the recorded rules version and the bosses already defeated. Rules 39 and
older keep the original Baron at every encounter.

**The screech.** Combat time runs a fixed 10-second cycle:

- calm until 5.0 s;
- a 1.5-second warning until 6.5 s;
- a 1.5-second sweep until 8.0 s;
- calm again.

As the warning begins, the Baron picks where the one gap in his wall of
sound will open, from where the bird is. The sky has three gap places,
centered at 0.27 (high), 0.5 (middle) and 0.73 (low), each 0.36 tall (0.30
in fury). Like the dragon's aim, a bird below 0.385 counts as high, one
above 0.615 as low, and one between them as middle. The gap never opens at the bird's own place: the
first, third, fifth… screech sends a high bird to the low gap, a middle or
low bird to the high gap; the others send a high or low bird to the middle
gap and a middle bird to the low gap. The gap is fixed until the next
warning.

At 6.5 s the wall leaves the Baron's mouth (his fireball muzzle) and
sweeps left at 1.2 per second, reaching 0.08 behind its leading edge. A
bird whose circle overlaps that band and sticks out of the gap is hurt like
a course edge: Classic ends the flight, and Star Trail takes a shield or a
heart with the usual 1.5-second recovery. At the widest phone the wall has
crossed the bird's column a second after it leaves. There are no fireballs
from 1.5 s before the warning to the end of the sweep, and the next waits
at least 0.6 s after it. Fury narrows the gap but never changes the cycle,
and pause and seek restore it exactly. Cutscenes never screech. From
anywhere in the sky at the start of the warning, calm or furious, at 1.78
and 2.4 widths, a bird tapping at most five times a second reaches the gap
before the wall arrives and holds it as the wall goes by.

**Bat pairs.** The upgraded Baron no longer summons one helper at a time
from the mixed lineup. As each screech fades (7.8 s into the cycle) he
sends two simple purple bats together, one at 0.3 and one at 0.7, entering
from the right like his ordinary helpers with the usual helper health. In
fury a second pair follows at 8.8 s. Even at the slowest pace (0.36 per
second) on the widest phone (2.4), a bat needs 6.0 s to fly past the bird,
so both pairs are gone before the next warning.

**Presentation.** The upgraded Baron keeps his character and adds a sonic
pink accent for everything the screech touches. He wears a taller crown with
a lightning spike and a pink gem, and his large ribbed ears reach past it
and glow. A speaker-like resonator disc sits on his chest, gold lightning
hems his darker wings, and his cape is torn into lightning points. In fury
the pink runs hot. The warning pose flares the ears, swells the chest, lifts
the wings and drops the jaw while pink rings gather into the mouth. The
release lunges at the bird with a flash and a small camera jolt, and the
jaw trembles through the sweep. His fireball charge stays hidden while his
fire is held for the screech.

The warning darkens the sky outside the gap with pink sound ripples rolling
left. It lights the gap cool white between dashed edges, points chevrons
into it, and pulses a ghost of the wall at his mouth. A tag at the left edge,
inside the gap and clear of the bird, reads FLY TO THE GAP (HOLD THE GAP
during the sweep), with a three-slot wall icon and a gauge that fills
through the warning. The wall is a full-height magenta band with a white
leading edge and a running waveform, bright edges at the gap and fading
echoes behind it. It is drawn under the Baron and the bird. Its leading edge
stays within 0.01 of the rules' front wherever it can meet the bird, and
the drawn gap matches the rules' opening. A pink jolt ring marks a bird the
wall catches. The arrival warns THE BARON RETURNS, roars in pink and
captions WHEN HE SCREECHES · FLY TO THE GAP, and the defeat knocks loose the
storm crown. Under Reduced Motion the ripples, chevrons, waveform, sways and
jolt hold still, and the warning, wall and gap stay fully visible. The debut
Baron's art is unchanged.

**Audio and hint.** The warning plays `screech_warning` (sonar chirps that
quicken and climb over a tightening whistle), and the sweep `sonic_screech`
(a shrill, wavering shriek over a rush of air). Each pair plays
`boss_summon` once. The live semantics hint names the gap (SONIC SCREECH ·
Fly to the high gap!, then SCREECH · Hold the high gap), and otherwise
reads Dodge the fireballs and bats · Watch for the screech, or FURY ·
Faster fireballs, more bats. The screech-hit counter is presentation only,
and the rules never read it.

### Campaign (rules version 41)

A Tap & Fly campaign of 40 levels in five chapters of eight, one chapter per
boss in boss order, flies every region once (design, level tables and text:
`docs/campaign.md`; level data: `lib/domain/campaign.dart`). Chapters 1 and 2
(16 levels, 48 level stars) are playable, and so is New York, the first stop
of chapter 3 (3-1 to 3-4, rules version 43, see "New York's levels" below):
20 levels, 60 level stars. Paris and chapters 4–5 are level data, shown on
the map and locked as "Coming soon". New York is open by default, decided in
one place (`Campaign.openingEnabled`); `--dart-define=NEW_YORK_OPEN=false`
closes it again (16 levels, 48 level stars). Endless Star Trail does not
change.

**Flight plans.** `FlightSimulation` takes a `FlightPlan` (default
`FlightPlan.endless`) and asks it for every schedule knob instead of checking
what kind of flight it is:
- the pace and schedule clocks;
- the obstacle families and the stone-panel chance;
- which passages carry an enemy, which enemy, and its toughness;
- boss timing and the encounter;
- heart pickups, rush paths and gales;
- where passages resume after a boss or gale;
- the course and set-piece randoms, the route and the level rating.

`EndlessPlan` returns exactly what the rules hard-coded before plans existed.
44 seeded endless flights and replays across rules 5–40 are pinned to digests
(`test/fixtures/endless_plan_baseline.json`). Endless flights at rules 41 match
rules 40 at every checkpoint. A `LevelPlan` flies only on a touch Star Trail at
rules 41 or later; anything else throws `ArgumentError`.

**Level data.** A `LevelPlan` holds:
- an id ("1-1" to "5-8") and one region;
- a length: cruising seconds to the finish, or the run-up before the boss;
- a start: the endless-clock second its pace and openings start from;
- a seed;
- the obstacle families after the three opening garden gates;
- the enemy lineup and cadence, and a toughness;
- whether Shoot and Sprint exist, and the stone-panel chance;
- the set pieces, the boss and the two star marks.

`LevelPlan.problem` rejects a plan unless:
- the id has 1–16 characters;
- the length is 10–600 and the start 0–3600;
- the families are non-empty with no repeats;
- the cadence is 1–8, the toughness 0–4 and the panel chance 0–1;
- every set piece lies within the length;
- a boss level has a lineup and no set pieces;
- 1 ≤ ★★ mark ≤ ★★★ mark.

Level lengths are 60–90 s, or 30 s before a boss. Starts run from 0:00 (1-1)
to 4:30 (5-7).

**Route clock.** `routeSeconds` advances by each step times the course
boost. It equals elapsed time while cruising and runs ahead during a sprint,
a ring sprint or a gale, and pauses freeze it. A level's boss and set pieces
follow the route clock, and its pace and openings follow `start +
routeSeconds`.

**The route.** Before the flight, `LevelRoute.lay` fixes the world position of
every ordinary passage, set piece and the goal from the plan alone:
- Passages are 1.95 cruising seconds apart. The first sits 3.1 ahead, past
  the widest 2.4 screen with room for its enemy.
- A set piece `at` seconds sits where a cruising bird is at that route
  second. With `after`, it counts from where the previous piece ends. A rush
  path ends where a cruising bird escapes its final barrier, 6.87 of course
  after its start. A gale ends 20.44 route seconds after its start (13
  seconds at up to 1.6×).
- Passages stop 0.45 before a set piece. They resume 0.9 past a rush path's
  end, and past a gale's end with 0.8 of room for a sprint in the tailwind.
- The last passage ends at least `FinishLine.clearance` (0.45) before the
  goal.

A passage's opening and motion phase follow the route second at which it is
3.1 from the screen's left edge, not the moment a screen lays it. Passages
draw from the level's own `Random(seed)` in route order. The boss and each set
piece draw from their own randoms, derived from the seed and the piece number.
Passages after a rush path pick up from its exit, and after a gale or boss
they resume centred at 0.5, not at the bird. So every attempt lays the same
passages, whether or not the player sprints, at every screen width.

**Hazards.**
- **Families:** the first three passages are garden gates, then a shuffle bag
  of the plan's families.
- **Enemies:** cadence 2 (as endless) puts an enemy on passages 1, 3, 5…, and
  cadence 4 (1-3 only) on passages 3, 7, 11…. The n-th enemy is `lineup[n mod
  length]`, and boss helpers draw from the same lineup.
- **Toughness:** chapter − 1. Small enemies gain 5 HP per point, so bats have
  10–30 HP across chapters 1–5.
- **Stone panels:** each eligible wall carries one with the plan's chance: 0
  through 2-1, 0.35 in 2-2 and 0.25 from 2-3. Never on two walls in a row.
- **No extras:** no heart pickups, and no rush paths or gales except the
  plan's set pieces. A `shuffled` piece draws its kind from the endless
  shuffle bag with its own random.
- **Controls:** `offersShoot` is false in 1-1 and 1-2, and `offersSprint` in
  1-1 to 1-4. Their buttons are hidden, and `canShoot`, `canCharge` and
  `canSprint` refuse.

**Finish line.** A `FinishLine` is laid at the route's goal once the goal is
within the passage entry reach, the screen width plus an enemy's lead. It has
no collision. When `distance + birdX` reaches its world x, `crossedAt` is set
and the flight ends with `EndReason.completed`. `routeProgress` runs from 0 to
1 at the goal, and `distanceToGo` gives the course left. The line is drawn as
the finish gate (`FinishGateArt`), which gets excited over the last 3 s and
plays its part in the crossing's celebration (see "Finish-line celebration");
it stays in the world after a knockout.

**Boss levels.** The boss arrives when the route clock reaches the length
(30 s), as encounter number `kind.index + 1` in its debut version:
- Baron Bat, 120 HP, not upgraded;
- the Spitter King, 210 HP;
- the Dusk Empress, 240 HP, with no veil and slow helpers;
- the Pirate Captain, 300 HP;
- the Ember Dragon, 360 HP, burning only half the sky, with no split
  fireballs or second swarm flock.

No other boss follows. Once the defeated boss has gone, the finish line is
laid 0.2 past the right edge. From the boss's defeat until the line,
`victoryGlide` holds the bird as the cinematic does (it eases to 0.52 with no
velocity): flaps, shots and sprints are refused and nothing can hurt it, so a
beaten boss always completes the level. On a boss level, `routeProgress`
fills `FinishLine.bossMark` (0.85) over the run-up and the rest over the
glide. After a gale, the boss waits only for a rush that is actually
scheduled; a level plan never schedules one there.

**Rating.** `levelStars` is 0 unless the flight ended `completed`. Otherwise
it is 3 when the stars collected reach the ★★★ mark, 2 when they reach the ★★
mark, and 1 below that. `LevelRoute.stars` counts three stars per passage and
18 per rush path; a gale lays none. The marks are 45% and 75% of it in chapter
1, and 50% and 80% from chapter 2, rounded to the nearest five. A boss level
counts its run-up only. For example, 1-1 lays 81 stars (marks 35 and 60), and
every boss run-up lays 36 (15/25 in chapter 1, then 20/30). A test pins all 40
levels to this rule and checks ★★★ < route stars.

**Progress.** A `LevelRecord` keeps a level's best stars, best stars
collected, best score, plays, first-cleared and last-played times, and
whether its postcard was seen. Only a finished flight sets the best stars
collected and best score; every flight counts as a play and updates the
last-played time. A level is cleared at 1 star or more:
- 1-1 is open from the start. Any other level is open once the level before
  it is cleared and its chapter is playable.
- A chapter is complete once its boss level is cleared. Its postcard is due
  until it is marked seen.
- The current level is the first open level not yet cleared. Once every open
  level is cleared, it is the one last played.

**Saving (schema 5).** Drift schema 5 adds a nullable `runs.level` and the
`level_progress` table, keyed by level: `best_stars` (0–3, checked),
`best_collected`, `best_score`, `plays`, `first_cleared_at`, `last_played_at`
and `postcard_seen`. Upgrading from any version below 5 adds both, and
existing runs keep `level` null. `saveRun` with a `levelId` stores the run and
merges its level row in one transaction, rating it with the level's marks at
save time, so retuned marks never take stars away. A duplicate run id changes
nothing. An unknown level id, a practice flight or anything but a touch Star
Trail throws `ArgumentError`. Reset deletes `level_progress`.

**Story.** The campaign's story is told on the map, between flights (the
arc, cast and scene list: `docs/campaign.md`; the lines:
`lib/domain/campaign_story.dart`). Nothing in it touches the rules, a flight
or a replay tape.
- A `StoryScene` has an id, a region (none for the Sky Club post), the boss
  who speaks in it, if any, and three to nine `StoryLine`s. A line has a
  speaker (the courier, Postmaster Bill, the boss, or a caption), text of at
  most 100 characters and a mood (plain, happy, surprised, angry or sad). A
  caption that closes a stop whose chapter is unfinished is a
  `StoryLine.endOfStop` ("To be continued…"; `StoryScene.endsStop`).
- `CampaignStory.before(level)` is the scene ahead of a level: the prologue
  before 1-1, a route's opening before its first level, an arrival at the
  first level of each later region, and the scene at a boss's or a
  guardian's lair. `CampaignStory.after(chapter)` is the chapter boss's last
  word and `CampaignStory.lastWord(level)` a guardian's (3-2 and 3-4). That
  makes 20 scenes before levels, 2 guardians' last words and 5 after bosses:
  27.
- Each scene plays by itself once. `CampaignProgress.prologueDue` holds
  until the prologue is watched or 1-1 is cleared. `sceneBefore(level)` is
  due while the scene is unwatched and the level is not yet cleared.
  `sceneAfter(chapter)` is due while the chapter's postcard is due and the
  scene is unwatched. `sceneLast(level)` is due once a guardian's level is
  cleared and its last word is unwatched; a guardian brings no postcard.
- Watched scene ids are saved in the `preferences` table under
  `storyWatched`, joined by commas, so the schema stays at 5. Marking a scene
  twice changes nothing. Reset clears it with the other preferences.
- Every level has a `Delivery`: a cargo line of at most 42 characters for
  its card, and a thank-you of at most 48 characters with a signer of at
  most 24 for its result. A chapter boss's delivery is signed by the boss; a
  guardian's level carries an ordinary one.
- A story line may be written before it is recorded: its clip is then
  *pending recording* in `docs/story-voices-sources.json`, and the scene
  prints the line and plays nothing for it, paced as with Character voices
  off (`CampaignVoices` gives no asset for a clip that is not in
  `campaignVoiceClips`).

**Counting.**
- Endless records, totals, bests and the recent-flights list read only runs
  with `level IS NULL`. Campaign flights have their own tally
  (`campaignFlights`, whose completions are finished levels).
- Daily adventures count campaign flights for flights, gates, stars, streak
  and perfect passes, but not for "The whole journey".
- The First wings (`flightsFlown`), On the dot, Star chaser, Constellation and
  Flock together stamps count them. Sky captain, Trailblazer and Both wings do
  not.
- Star chaser reads "Collect 50 stars.", and the daily star goal reads
  "Collect 18 stars across today’s flights."
- Home's first-time greeting also uses `flightsFlown`.
- A campaign flight earns no flight wings or record chime. Its marks take
  the wings' place, with the same chime.

**Replay.** From rules 41, a campaign `ReplayTape` writes `level` (the id)
and `plan` (the whole `LevelPlan.toJson()`) after `weaponDamage`. Endless
tapes and tapes before 41 have neither. Loading rebuilds the plan from the
tape, not the catalog, so a retuned level replays as it was flown. It
rejects a tape with only one of the two, a plan whose id differs from
`level`, a malformed plan, or a plan on another mode or course. The tape's
`seed` is ignored, because the plan's seed lays the route. Saved session
summaries store `level`, and the library lists them as "1-3 · Bat Patrol".

**Screens.** Routes:
- `/campaign` opens the map;
- `/campaign?level=<id>` opens the map on that level's stop with its card
  open;
- `/play/touch?level=<id>` flies the level. An unknown or locked level, or
  another mode, redirects to `/campaign`.

The screens:
- **Home:** the main game leads, with two keys of the same size under the
  title (250 × 108 at 50 and 310, 128 down the 1000 × 450 canvas). The mint
  Campaign key shows the level the journey continues with ("1-3 · Canopy
  Run", the first unlocked level not yet cleared, or "Every letter
  delivered") and the level stars earned ("12 / 63", or "12 / 51" with
  `NEW_YORK_OPEN=false`; the total counts only levels the build can fly). The
  yellow Endless key shows the best Tap & Fly Star Trail flight and starts
  one straight away. A lavender Mini games key (510 × 76) sits under both and
  opens the mini games: Push-Up Flight, Squat & Fly, Jump & Fly and Fly
  Together. Every key stays a full 48 dp on a 640 × 360 phone. While the
  save loads or can't be read, the map's back key still leads Home.
- **Map:** one stop per region, with level nodes showing their stars. Tapping
  an open node opens the level card. Tapping a locked one wiggles it, and a
  note shows for 2.4 s: "Finish 1-2 to unlock", "Beat Baron Bat to unlock"
  (or "Beat King Coo to unlock" on 3-3). On a stop marked "Coming soon", the
  ribbon flutters instead (still under Reduced Motion); with New York open,
  Paris's ribbon reads "Paris — coming soon". A guardian's level is a shield
  node with a GUARDIAN plaque, not a lair. The map's keys, star total and stop titles hide
  while a scene, level card or postcard is open, and the map holds its frame
  under them.
- **Story scene:** the map shows what is due in this order: the prologue, a
  fallen boss's last word, that chapter's postcard, a beaten guardian's last
  word, the scene before the open level, then the level's card. A scene shows its region behind (the
  Sky Club's mail room when it has none), the cast along the speech panel
  and the line in the panel, written out over 26 ms a character
  (0.26–1.7 s). A tap anywhere, Enter or Space finishes the line being
  written, and the next one moves on; the last line ends the scene. Skip and
  the back button end it at once. Ending a scene that played by itself saves
  it as watched.
  - The courier stands on the left with Bill facing it; at a lair the boss
    takes the right and Bill stands behind the courier. The speaker is at
    full size in a pool of light on its name tag, and listeners are 10%
    smaller and shaded. A speaker change cross-fades over 260 ms.
  - A line is set at 18 px on a 360-high screen and steps down to 15 px only
    if it would not fit two rows; a line that wraps splits evenly. The stage
    scales with the screen's height, between 0.85 and 1.25.
  - A caption that names the place is set on a dark plate, and one in
    quotes, a letter read aloud, on airmail paper. One pip per line shows
    progress, and a cue appears once the line is whole.
  - After its fall a boss appears without its headwear.
  - System text scaling does not apply inside a scene, as on the map's
    chrome, because the panel is fitted to the line.
  - **Voices** (`docs/story-voices.md`): with the Character voices setting
    on (the default), each line plays its recording through the menu's
    `SkyAudio.speak` as it starts; a courier's line plays the equipped
    bird's take. The line is then written out over 90% of the recording
    (0.26–8 s) instead of 26 ms a character. Leaving the scene, by its last
    tap, Skip or the back key, calls `hush`. Under Reduced Motion the line
    shows whole and the voice still plays.
- **Level card:** a parcel tag over the region picture shows the delivery's
  cargo. On a level that has a scene, a story key under the close key plays
  the scene again without saving anything. On a
  beaten boss level it plays the scene at the lair and then the boss's last
  word.
- **Flight:** it counts straight in. `MatchLevelStars` replaces the score
  plate with the stars collected and a track notched at both marks, and
  `MatchRoute` (a dotted route, the bird's marker at `routeProgress` and a
  finish flag) takes the clock's slot beside Pause. Both hide while a boss is
  on screen. A boss level's route marks the lair with the boss's headwear,
  and Shoot and Sprint hide during the victory glide. The countdown hint
  names only the controls offered.
- **Pause:** Map, Retry and Keep flying. Map, Retry and the back key save the
  attempt, ended with `EndReason.breakTaken` and 0 stars.
- **Knockout:** the knockout and game-over stage, with the stars against the
  next mark, the share of the route flown (or the boss's health left), and
  Map / Save session / Retry.
- **Finish:** crossing the line snaps the tape and plays the celebration
  (see "Finish-line celebration"): the bird loops and swoops into the
  result's courier seat, the `complete` fanfare plays on its beat, and the
  level result stages over the warmed finish 1.7 s after the crossing, its
  courier taking over from the landed bird. Once the celebration settles,
  or straight away after a skip, the frozen finish leaves the flight's bird
  out (`BirdGame.hideBird`) for the result's own courier. A flight that ends
  any other way without a knockout, such as a stall, shows the result with 0
  stars.
- **Result:** the title reads "Delivered!", "Victory!" after a chapter's boss,
  "Guardian down!" after a guardian, or "Try again!". A guardian's result
  carries an ordinary friend's thank-you and no chapter strip or postcard
  strip; after 3-4 a lavender strip says "Paris is coming soon!" and Next is
  hidden. Three stars land at 34%, 46% and 58% of a 1.9 s entrance, each
  earned one with a chime, and the keys arm at 55%. Next shows when the next
  level is playable and opens `/campaign?level=<next>`. Retry flies the same
  level again immediately, skipping the countdown. A finished level shows its
  delivery's thank-you, signed, on a note that drops in beside the courier
  from 50% to 76% of the entrance, and its sender reads it out as it lands;
  a flight that fell short shows none.
- **Speech:** `SkyAudio.speak` plays one clip on a dedicated player that
  never takes audio focus and ignores the flight's playback rate. A new line
  cuts off the one before; `hush`, `stopEffects` and disposal stop it. The
  music ducks to 35% of its level while a line plays and comes back when it
  ends. Sprints call out in the equipped bird's own voice, one of four calls
  and never the same twice in a row. In a live flight the characters also
  speak on it ([flight-voices.md](flight-voices.md)), with the music ducked
  to 60%; the sprint calls then join the bird's in-flight lines. The
  Character voices setting
  (`SettingKey.voices`, saved as the `voices` preference) silences all of
  it.
- **Postcard:** when a chapter's postcard is due, the map shows it, after
  the boss's last word, over everything else until Continue marks it seen. A beaten chapter's last stop
  keeps it on the route to open again.

**Regions.** A level holds `plan.region` for the whole flight:
`WorldTour.at(seconds, held:)` returns that region and never crosses, and the
backdrop, gates, gales and `bird_game` pass it. For long holds, the skyline
bands repeat and landmarks recur. 235 endless scenery frames are pinned to
pixel digests (`test/fixtures/endless_scenery_baseline.json`). The map and
postcard paint their regions with `WorldBackdrop.still`.

**Reduced Motion.** The map draws no bob, glow, pulse or glide, and changing
stops jumps. The card and postcard appear without sliding, a scene's lines
appear whole and its speakers hold still, and the finish pennants hold
still. The level readouts don't pulse. The finish gate's lights simply come
on, and the crossing plays the calm celebration: the tape fades, a still burst
and the sunburst fade in, and the pleased bird fades out as the result fades in
over 0.5 s with every star in place.

### Fly Together co-op (rules version 42)

Two players fly one endless Tap & Fly Star Trail on one phone, their birds
roped together (**Roped**) or each on its own (**No rope**). Home's Mini
games picker offers **Fly Together** beside the three camera workouts. Each
player picks one of the four birds (both may pick
the same one), and a toggle picks the mode. The picks and the mode are
remembered.

**Controls.** A touch on the left half of the sky flaps player 1's bird and
one on the right half flaps player 2's. Each player has a Shoot and a Sprint
button in their bottom corner, Shoot outermost, tagged P1 (coral) or P2
(teal); the same tags float over the birds. Keyboard: W, A and D (hold) flap,
sprint and shoot for player 1; Up, Left and Right (hold) for player 2.
Pause, hearts, shield and score sit where solo Tap & Fly has them, with the
magnet meter under the hearts. During the
countdown each half of the sky is tinted in its player's colour.

**Formation.** Player 1's bird cruises 0.10 screen heights behind the solo
bird's column and player 2's 0.10 ahead of it. Each bird has its own height,
vertical speed, screen column and horizontal speed. A critically damped
spring (stiffness 30, damping 11) holds each bird to its place. Both birds
use touch gravity and flap impulse; a flap sets that bird's vertical speed.

**Rope.** The birds' centres can be at most 0.30 apart. While the rope is
slack it does nothing. Past its length, each bird moves half the excess back
along the rope and the speed along it that pulls them apart is shared
equally between them (an inelastic pull between equal weights). A bird that
flaps alone from a taut hang therefore lifts the pair at half its speed, and
their middle climbs a quarter as high; two flaps together climb like one
solo flap. The birds bump at 0.09: each moves half the overlap apart and their
closing speed is shared in the same way.

**Sprint.** A sprint behaves as in rules version 29 for its own bird: one
burst, its own 15-second cooldown. The sprinting bird's place moves up to 0.26
ahead with the burst's envelope, so it surges forward and the rope drags its
partner (a sprint from behind nudges the front bird ahead). The course speed
multiplier is one plus the pair's average extra boost: 1.75× at the peak of one
bird's sprint, 2.5× when both sprint. Only a sprinting bird rams enemies,
stone panels, rubble, meteors and swarm bats. A sprint ring sprints both birds
and lets both ram.

**Shared and per bird.** Hearts, shield, recovery, score, combo, stars, the
star magnet and gates are shared. Each bird has its own ammo reserve, charge,
shot cooldown and sprint cooldown, and fires from its own beak. Every hazard
checks both birds: course edges, walls, panels, enemies and their pellets,
boss ammo, the Pirate Captain's sea, the Ember Dragon's breath, Baron Bat's
screech, meteors, lava plumes, swarm bats and gale debris. A hit to either
bird costs the pair's shield or a heart once, with the usual recovery. Either
bird collects a star, heart or sprint ring. Stars count as missed, and gates
and gale debris as passed, only once they are behind the rearmost bird. A gate
is perfect when both birds pass within 0.075 of its mark. The wildfire
catches the rearmost bird. Aimed attacks take turns between the birds: enemy
and boss volleys, the Dragon's breath and flocks, Baron Bat's screech and
gale gusts alternate targets by their own counts. Passages resume at the
pair's middle height after a boss or gale.

**No rope.** Everything above holds except the rope: nothing holds the birds
within its length and nothing drags. A flap lifts only its own bird, as high
as a solo flap, and a sprint surges only the sprinter ahead. The course still
follows the pair's average boost, and the birds still bump at 0.09.

**Records.** Each co-op mode saves its own team best and flight count (once
per flight id). Records shows them as **Fly Together · Roped** and **Fly
Together · No rope** beside the four solo bests, and counts co-op flights
beside the scored flights. They never count toward the solo records, the
passport, daily adventures or flight goals. Results show the mode, the team
score, time, stars, gates and each player's flaps, with Fly again, Change
birds, Save session and Home.

**Journal.** A co-op tape (rules version 42) stores `partner`, player 2's
bird, and `coop`, the mode (`roped` when absent). Its flaps are journaled as `flap` events naming the player, and its
`charge`, `shoot` and `sprint` events name the player too. Solo journals keep
their format and reject these. The replay draws both birds, and the rope
when roped. A co-op flight's id ends with `-coop-roped` or `-coop-free`, so
the session library names its mode.
Solo flights under rules version 42 fly exactly as under version 41, and
under 43 (New York) exactly as under 42.

**Presentation.** The rope hangs in a parabola of its length and sways a
little; it straightens and warms toward coral as it nears its length. A hard
snap (shared speed of at least 0.25) flashes it and sends a ripple along it.
Reduced Motion keeps the sag and tint without the sway or ripple. Player 1's
bird is drawn over player 2's; only player 1's bird speaks in flight. A
knockout tumbles both birds, still roped together.

### Fly Together 1 v 1 duel (rules version 42)

A third Fly Together mode, **1 v 1**, flies the same two birds against each
other on an endless Tap & Fly Star Trail, with the co-op controls, keyboard
keys, side tints and player tags. The last bird flying wins.

**Course.** The endless course without bosses, rush paths, gales, ordinary
enemies or heart pickups (a `DuelPlan`), so every enemy in the sky was sent
by a player. Passages, their families, stars, pace and openings are as in an
endless flight. Both birds cruise in the solo bird's column; player 1 starts
at height 0.38 and player 2 at 0.62. From rules version 63
(`passingRivalsRulesVersion`) they fly through each other, one passing over
the other for a moment; a duel recorded at 42–62 replays with them bumping
at 0.09 as without the rope. A sprint surges only the sprinter ahead.

**Hearts.** Each bird has its own three hearts, shield and 1.5-second hit
recovery; only the bird that is hit loses them. A wall hurts each bird that
touches it once. A bird's own stars charge its own shield (every ninth).
A bird that loses its last heart is down, and the step it went down on ends
the duel: the other bird wins, or two birds down on the same step draw. There
is no star magnet. Score, combo and gates are still kept for the pair but
are not shown.

**Mystery boxes.** From the second passage, every other passage carries a box
(radius 0.042) 0.55 ahead of its left edge, 0.15 to 0.22 above or below its
aiming height (flipped to the other side if that would leave 0.14–0.86). A
bird opens a box by touching it, or by hitting it with one of its rocks. What
it holds is drawn when it opens: an attack or a help at even odds, then one of
three. A heart at five hearts becomes a shield (star power if shielded), and
a shield while shielded becomes a heart (star power at five hearts).

* **Bat swarm:** five swarm bats, 0.09 apart, enter beyond the right edge at
  the rival's height and fly straight at swarm speed.
* **Spitter beetle:** a spitter beetle (20 HP) enters at the rival's height
  (0.2–0.8) and closes in at 0.42 of the course speed, spitting aimed pellets
  at the rival only.
* **Meteor shower:** three meteors, the first 0.3 s after the box opens and
  then 0.6 s apart, each aimed where the rival flies as it falls.
* **Heart:** one more heart, up to five.
* **Shield:** a shield.
* **Star power:** for five seconds nothing hurts the bird, it rams (smashes
  bats, meteors, enemies, panels and rubble like a sprint), and touching its
  rival (centres within 0.10) hurts the rival.

Everything a player sends carries that player as its sender: it flies
straight through its sender, its pellets only hit the rival, and the
sender's own rocks fly through it. The rival can shoot it down or ram it.

**Rocks.** A rock that touches the rival hurts it. Level in the column, the
birds cannot hit each other; a rock can only reach a rival that has surged
ahead, as a sprint does.

**Records and results.** A duel counts toward the Fly Together flights but
keeps no best; Records shows the number of duels. Results name the winner
(or a draw, or a stopped duel), keep a series score for as long as the
screen stays open, and show the time and each player's hearts left, boxes
opened and hits landed (rocks, star power and sent attacks), with Rematch,
Change birds, Save session and Home. The bird that went down tumbles in the
knockout while the winner stays up, bright, by its tag. Neither bird speaks in
flight. A duel's tape stores `coop: duel`; its id ends with `-coop-duel`.

**HUD.** Each player's hearts and shield sit in their own top corner under a
PLAYER 1 or PLAYER 2 tag, with a star-power meter while it lasts and, for
1.8 s after a box opens, a banner in the player's colour naming the prize
(an attack also names the rival it went after). Pause sits between them at
the top. A help sounds the unlock fanfare and an attack the boss summons.

**Art.** A closed box is a violet gift with a gold bow and a cream question
mark in a ring of light; it bobs, and its lid hops every 2.6 s. Opening it
pops it in the opener's colour over the birds: the lid flies off, confetti
scatters and the prize's sticker (round for a help, spiky for an attack)
jumps out, then flies into the opener's bird or off toward where the attack
comes from. A help raises no floating label of its own. Everything a player
sent wears a ring in their colour with a P1 or P2 tag beside it (one ring
around a whole bat swarm; a tag by a meteor's warning arrow before it
enters). Star power is a spinning rainbow burst behind the bird that shrinks
and throbs through its last second. Reduced Motion keeps the box still, shows
an opened box under its prize without the pop or the flight, and holds the
star power still.

### New York (rules version 43), scaffold

Rules version 43 "New York" is one bump for the Alley Pigeon, steam geysers
and two campaign-only mini-bosses (King Coo, the Searchlight Gargoyle). All
four are reachable only through a campaign level plan, so endless flights and
chapters 1 and 2 fly at 43 exactly as they did at 42 (Fly Together, above) and
at 41, and a tape recorded at 41 or 42 replays at its own version (frozen
fixtures: `test/fixtures/frozen_rules41.json` and `test/fixtures/frozen_tapes/`,
flown at 41, 42 and 43). Co-op and duel flights stay at 42
(`FlightSimulation.coopRulesVersion`): they are endless-only and refuse a
level plan, and a New York plan refuses to fly below 43. The design is in `ny-ws/reports/`; the public
names each part of the program builds against are in `SCAFFOLD.md` of the
program tree. This section records what has landed.

- `FlightSimulation.newYorkRulesVersion` is 43 (`coopRulesVersion` stays
  42); `currentRulesVersion` was 43 until staged campaign bosses (44, below).
  `supportsAlleyPigeon`, `supportsSteamGeysers` and `supportsMiniBosses` are
  true from 43.
- `LevelPlan.minRulesVersion` is 43 when the plan has an Alley Pigeon in its
  lineup, `flocks`, a `steam` layer or a campaign-only boss, else 41. The
  `FlightSimulation` constructor throws `ArgumentError` below it, and
  `ReplayTape.fromJson` rejects a plan newer than the tape's version.
- `LevelPlan.toJson` writes `flocks` and `steam` only when a plan uses them,
  and a missing key reads as empty, so a rules 41 plan and tape keep the same
  bytes.
- `EnemyKind.alleyPigeon` (index 4), `BossKind.kingCoo` (5) and
  `BossKind.searchlightGargoyle` (6) are appended. `EnemyKind.campaignOnly`
  and `BossKind.campaignOnly` mark them; the endless boss cycle is the first
  `BossKind.endlessCycle` (5) kinds and the endless enemy lineup names four,
  both guarded by assertions and tests.
- `CampaignChapter.opened` and `Campaign.playable(level)` let a build open
  part of a chapter that is not `playable`. Chapter 3 lists New York;
  `Campaign.openingEnabled` is true by default, so a plain build, `make build`
  and `make install` open 3-1 to 3-4; `--dart-define=NEW_YORK_OPEN=false`
  (`make build DEFINES=--dart-define=NEW_YORK_OPEN=false`) closes them to
  "Coming soon" again, the rollback. Both states are tested (tests force the
  closed one with `Campaign.closedForTest`), and `CampaignProgress.totalStars`
  counts only the levels the build can fly. A
  guardian (`CampaignLevel.isGuardian`, a level that ends in a mini-boss)
  unlocks only the next level: the postcard, the chapter unlock and the flame
  seal belong to the chapter's boss level (`isChapterBoss`).
- The rules of all four have landed, each below, and so has the art: the Alley
  Pigeon (`AlleyPigeonArt`), King Coo (`KingCooBossRig` and `KingCooStaging`),
  the Searchlight Gargoyle (`GargoyleBossRig` and `GargoyleEncounterArt`),
  each below. `NyPlaceholderArt` now only stands in the exhaustive switches'
  arms that neither guardian can reach. The steam has its own art
  (`SteamGeyserArt`, drawn by two calls in `bird_game.dart`: the vents behind
  the stars and the bird, the bird's scald ring and lift streaks over it; at
  most 80 draw calls a vent, no layer, blur or shader, and Reduced Motion
  still shows each phase).
- Every New York rule is a function of the simulation clock and draws no
  number from the flight's shared random, so a level's route, passages and
  enemies are the same with and without them, pause and seeks are exact, and
  a recorded flight replays tick for tick.

### New York's levels (rules version 43)

The catalog's 3-1 to 3-4 (`lib/domain/campaign.dart`; the design is
`docs/campaign.md`):

| Level | Plan |
| --- | --- |
| 3-1 Moth Light | 60 s finish line, lineup bat, moth, cave bat, beetle (a rules 41 plan: it uses nothing New York adds) |
| 3-2 Wheels in the Rain | a 30 s run-up (start 1:25, sun wheels, pigeon lineup with flocks of 1, 1, 1; no steam, no set piece), then King Coo (140 HP). Guardian |
| 3-3 Steam Alley | 65 s, start 1:40, seed 3111, the alley's lineup with flocks 1, 2, 2, 2, 2, 2 (five formations, nine pigeons), `SteamPlan.steady` (seven vents, hop and ride alternating from passage 4), no set piece |
| 3-4 Storm Warning | a 30 s run-up (start 1:30, switchbacks and sun wheels, the alley's lineup with flocks 1, 2, `SteamPlan.sparse`: three vents), no Sprint, then the Searchlight Gargoyle (160 HP). Guardian |

- A boss level (a guardian's too) holds no set piece: `LevelPlan.problem` still
  returns `'boss'` for one. The Gale and the Swarm rush that New York's two
  full levels used to hold belong to Paris (3-6 and 3-7 keep them and carry
  the NEW hints).
- Star marks are 50% and 80% of the real route's stars rounded to fives: 81
  (40 / 65), 36 (20 / 30), 90 (45 / 70) and, with one exception, 36 (20 / 27:
  the Gargoyle's ★★★ is 75% because his run-up's steam arcs and pigeons cost a
  casual pilot two stars more than King Coo's). The pigeons' worst case (3, 9
  and 3 stars against caps of 3, 10 and 4) and the vents (which keep their
  passage's stars) leave ★★★ in reach: `ny_star_marks_test`.
- The fix round (R5, `docs/validation.md`) changed three levels after the
  review's hostile play test: 3-1 from 70 s and moths on half the enemies to
  60 s and one in four, 3-3 from 80 s (seed 3103, 114 route stars, eight vents)
  to 65 s (seed 3111, 90 stars, seven vents), 3-4's ★★★ from 30 to 27, and the
  3-3 and 3-4 card hints ("Vents hiss, then burst. Hop the hot ones, ride the
  soft ones." and "... No Sprint here."). A flight saved before keeps its whole
  plan and replays on the old level (a legacy tape is frozen).
- 3-4 turns Sprint off (`LevelPlan.sprint` false): a sprint would close the
  Gargoyle's feathers faster than the lane they were aimed for, which his
  fairness proof assumes away. 3-2 keeps it: King Coo's clouds are fixed to
  the screen and his squadron flies a track of the boss clock, so a sprint
  cannot move or shorten a hazard (`ny_levels_flight_test`).
- The name card of a guardian reads GUARDIAN (`BossEncounterArt.nameCardEyebrow`)
  where a chapter boss's reads ENCOUNTER and its number; the card's line is the
  level's own `bossLine`.
- New York's data is frozen at rules 43 beside the rules 41 fixtures
  (`test/fixtures/frozen_ny43.json`, `test/fixtures/frozen_ny_tapes/`,
  `frozen_ny43_test.dart`): the four plans and routes, bot flights, pilot
  flights of both guardians at 640 and 800 px wide and four saved tapes (one
  of them the 80 s Steam Alley as shipped before the fix round).

### Alley Pigeon (rules version 43)

The Alley Pigeon (`EnemyKind.alleyPigeon`, campaign only) steals stars. It
fires nothing; its health is `10 + 5 * toughness` (20 in chapter 3). A level
lays one when a lineup entry names it: a formation of `plan.flockSizeFor(k)`
pigeons (1 to 3; `LevelPlan.flocks`), each bound at lay time to a star of the
passage's trio (one takes one of the three stars, two take the first and one
of the others, three take all; the only draw is one `nextInt` from the plan's own
`flockRandom`, never the flight's). They glide in from the top right and hover
over their star, above the lane or below it.

- **Raid.** A hunter warns for 0.80 s (it faces the bird, its star ringed) when
  its star is on screen and still at least 1.3 s of course (and .40) ahead of
  the bird (else it is a glider for good), dives for 0.44 s and takes the star
  at its centre. It gloats in the lane for 0.65 s and climbs away; a star it
  carries off the screen is lost, and its trio's bonus with it. Nothing but the
  star is lost: a snatch is not damage and never resets the streak.
- **Hits.** Any damaging hit before the snatch spooks the pigeon (it flees
  from where it is, the star untouched). A hit on a thief, or its defeat (+3),
  frees the star: it hops from the pigeon and floats back to its gate line,
  catchable. A Sprint ram or touching a thief drops the star into the bird's
  beak (a touch still costs the shield or a heart like any enemy).
- **Fairness.** `AlleyPigeon.thiefCap(routeStars, threeStarMark)` is half the
  slack between a level's stars and its three-star mark, and a pigeon begins
  its warning only while `starsLost + thievesCommitted < thiefBudget`, so a
  player who never shoots can always still earn three stars (tested over twelve
  seeds per level).
- **Counters** (audio and UI): `pigeonWarnings`, `pigeonDives`,
  `starsSnatched`, `starsFreed`, `starsLost`, `pigeonsDefeated`.
- **Squadron.** King Coo's squadron pigeons are the same pigeon in its glider
  variant (`SkyEnemy.squad`): no prey, no raid state, never a snatch, placed
  by the boss's squad track. A rock or a ram defeats one exactly as it does a
  raider and raises both `enemiesDefeated` and `pigeonsDefeated`.

### Steam Geysers (rules version 43)

Steam vents are a plan layer (`LevelPlan.steam`, `LevelRoute.geysers`), not an
obstacle family: slots are passages `first, first + every, ...` (3-3: from the
4th, every 4th, to the 34th; `H` hop and `R` ride alternating). A slot draws
exactly what a gate draws and then lays a vent instead of the wall, stars and
enemy, so route digests, passages, stars and the goal are identical with and
without steam.

- **Cycle** (route clock, period 4.2 s): hiss 1.5 s (the warning), burst
  0.5 s (hot), billow 1.25 s (cool), sleep to the next. The state is a pure
  function of the route clock, whatever the speed.
- **Hop vents** scald: during the burst the column from the plume top to the
  mouth (half-width `SteamCycle.hitHalfWidth`) hurts like a course edge
  (`_damage()`: shield, then a heart, 1.5 s recovery). The plume top is
  `clamp(c - .06, max(T_min(k), c_prev - .22), .64)` (`T_min = max(.42,
  .58 - .04 k)` over hop number k, `c` the slot's gate centre, `c_prev` the
  previous gate's), so every vent can be passed from the previous gate.
- **Both kinds lift** in the billow: a bird within `liftHalfWidth` of a vent
  is pushed up at most `SteamCycle.liftSpeed`, never above `top - .03`; a flap
  still wins. A ride vent's soft steam never scalds; a ride that lifted the
  bird pays +2, a hop vent the bird never touched +1. A Sprint ram does not
  smash steam. Boss arrival clears the vents.
- **Counters:** `steamHisses`, `steamBursts` (one of each per vent passed,
  while it is within earshot), `steamRides`, `steamScalds`, `steamClears`.
- **Look** (`SteamGeyserArt`). Hurts and helps differ in shape, ink and
  motion as well as colour. A hop vent warns with a hazard-taped column (a
  black-and-amber bar on the hit top, heat filling it from the lid) and bursts
  as a slim amber-rimmed jet with a rolling head. A ride vent warns with no
  box (a dotted teal dome, a funnel, rising chevrons) and its burst is a soft
  cool upwelling with no warm pixel. Both billows are tall leaning cool
  columns with teal updraft streaks. At most 80 draw calls a vent and 160 a
  two-vent frame.
- **Checks.** `SteamPlan.routeProblem(route, length)` (no slot within a passage
  of a set piece, the last vent passed at least 2 s before the goal or the
  boss) for a level's data; `test/steam_reach_test.dart` ports the
  reachability proof (870 starts in each of 12 rows, none scalded) and flies
  120 real flights of a slow tapper who touches no hop vent.

### King Coo (rules version 43)

The Commissioner of the Curb (`BossKind.kingCoo`, campaign only) guards 3-2.
Health 140, fury at 70; he hovers at `x = max(birdX + .70, width - .55)`,
`y = .5 + .06 sin(.9 t)`. The fight is a fixed 14 s cycle on the combat clock
`t = age - 4.6`, with no random draw.

- **Crumb bombs.** A ring locks on the bird's height at 0.6 s and 3.0 s (fury:
  0.6, 2.4 and 4.2 s, each a pair of clouds .30 above and below the ring, one
  left out if it would lie outside .12 to .88, so the bird's own height is
  clear). The bomb is thrown 0.8 s after the lock and bursts 1.4 s later into a
  cloud that hurts like a course edge for 1 s (its drawn radius is its hurt
  radius). Clouds are fixed on the screen, so a Sprint cannot move them, and
  they never block a rock.
- **The puff.** From 7.6 s to 10.0 s his chest is taut: rocks do double
  damage there, and three puffed hits (60) pop him. Outside the window the
  chest is fluffed and takes half (at least 1). A pop before the whistle
  cancels it and its squadron.
- **The whistle.** At 9.2 s a squadron of Alley Pigeon gliders takes the
  lanes fixed at the puff (a V on even cycles, a picket wall with one 0.30 gap
  on odd cycles, both in fury with the picket 1.4 s behind). They fly left at
  .62 a second on their tracks; touching one hurts, a rock or a ram defeats it.
- **Checks.** `test/king_coo_fair_test.dart` proves that a bird tapping at
  most five times a second has a safe sequence from every state that survives
  the screen edges, for every hazard and both lob-to-lob chains, and flies the
  search's own policy through the real simulation (104 runs, never hurt).
  `CooBot` fights take 9 to 12 s at best and 32 to 37 s for a novice bot; a
  human first-timer is expected to need about a minute, which is the playtest
  gate.

**Presentation.** King Coo faces the bird and fills the right of the
screen, a pouter pigeon in a police cap, drawn by his own rig
(`lib/game/king_coo_*`; one rig unit is 11.5% of the screen height, his chest
sits on the rules' `boss.x, boss.y`, and every motion is a pure function of
the boss clock):

- a taut-chested body: a pale pink-white breast that is a scalloped, fluffed globe
  (radius .84) and, puffed, a smooth lit circle exactly the size of the hit
  circle (radius 1.00) with a brass badge on it, on a slim teardrop body that
  tapers to a narrow four-feather tail;
- one hide under one ink outline: body, chest and ruff share a single fill
  and outline, so no seam shows inside the figure, and the moon's rim and the
  window glow set him off against dark skies;
- an iridescent neck under a scalloped ruff and a round head whose hinged
  beak leads the face (by at least .28 of a radius in every pose, and the
  throat notch stays open), a grumpy half-lidded amber eye, and the cap: navy
  wool with gold piping, a brass badge, a siren dome that blinks red and blue
  and rain that runs off it;
- long coral legs; pigeon wings with two dark bars, one folded along the
  flank and one the throwing arm (it whips through the toss and its tip is at
  the rules' release point at the launch); a crumb sack on a strap and a
  whistle on a chain.

Every pose fits inside the screen at 640x360 and 800x360 and inside the
art's own layer.

Its poses:

- **Hover:** a waddle at 1.6 beats a second (2.1 in fury), the bob and the
  head thrust on each step.
- **Lob:** dips into the sack, winds the bomb back, holds, and swings so that
  the bomb leaves the wing tip at the rules' launch.
- **Puff:** the chest swells from 7.6 s to full at 9.2 s, front-loaded so the
  taut look matches the x2 window; the tail fans.
- **Whistle:** the whistle rises at 8.5 s and is blown at 9.2 s with the siren
  strobing; his own squadron comes out from behind him.
- **Hit:** a white flash, a squint and a flinch, and a star on the chest (gold
  and x2 for a puffed hit).
- **Pop:** he squashes, his eyes turn to Xs, the cap flies off and he
  recovers by 3.6 s.
- **Fury:** the breast flushes hot pink, both wings stomp down, the feet
  stamp, he scowls and the cap is cocked.

The telegraphs sit under the stars, the pigeons and the bird. Each bomb's ring
is dashed, locks where the bird was, grows as it nears and turns red for its
last 0.3 s; the bomb arcs from the wing tip to it, and the cloud's drawn
radius is its hurt radius. Fury's bracket shows both rings and the corridor
between. From 7.6 s the lanes of the whistle show how the squadron will fly (a
V or a picket, with traffic cones at the edges of the gap and the safe lane
green), a red and blue wash pulses on the rain and the scenery, and a queue
of pigeons waits behind him. His plate is a navy police plate under a brass
rim, with a shield medallion whose lamp blinks as his own siren does, a gauge
that is a crusty loaf of crumbs that cracks as health drops, a whistle at the
fury mark (70) and a `PUFFED x2` tag with three POP pips while the chest is
taut. The arrival warns THE CURB IS CLOSED (4.6 s): a shadow slides in (half
the rules' arc, so the cap stays under the letterbox) with one orange eye and
a siren strobing red and blue; at 1.9 s the world blanches and the colour
floods in (0.12 s; 0.25 s and no flash under Reduced Motion); he rears at
2.35 s, COOs at 2.65 s and his own GUARDIAN card slams in at 2.85 s with the
campaign's quote. The defeat (3.8 s): a 0.12 s hit-stop, he inflates, his cap
leaves from exactly where it sat at 0.3 s (it later lands, hops and lies with
its siren still blinking), and at 0.85 s he pops like a pillow in feathers
and crumbs while his squadron deserts him and the badge floats up. His
squadron's pigeons are painted under his figure until they have flown clear
of it. Under Reduced Motion the waddle, the sways, the swell's overshoot, the
flash, the strike, the cap's tumble and the desertion are dropped and every
state (puffed, whistling, popped, fury) stays; the figure fades before the
burst. His story portraits are the same rig in the six moods (five moods and
the beaten king, with a bagel and a pretzel as props); the cap is the
keepsake.

**Audio and replay.** `coo_roar` plays on the COO! (2.65 s) and again on the
fury, `crumb_throw` as the bomb leaves the wing, `crumb_splat` as the cloud
blooms, `coo_puff` at 7.6 s, `coo_whistle` at 9.2 s with `squad_flutter` a
beat behind it, `coo_pop` on a pop and `coo_defeat` at 0.85 s after the blow.
The arrival's reveal cue (1.65 s) leads the flash by 0.25 s and the in-flight
card's voice, when it is recorded, belongs at the slam (2.85 s). The cues read
the rules' counters and never feed back into them, and a seek replays
silently.

Checks:
`test/king_coo_staging_test.dart` (nothing leaves the screen, the bars or his
layer in any state at 640 and 800, with and without Reduced Motion; every phase
of a real-rules fight renders; the cap leaves with no pop; at most two bounded
layers, no blur, no shader built after the first frame; every audio cue lands
on its beat) and `test/king_coo_story_art_test.dart`.

Fix round (after the independent reviews). While his rocks count double (the
rules' `puffWindow`, the pose's `doubleDamage`) the taut chest wears a bold
amber ring just inside the hit circle (still exactly the hit circle: pinned
on an isolated scan), a warm heart, a beating inner ring, an "x2" roundel
pinned to its lower left, a gold halo and two ripples leaving its edge; while
it swells, feathers stand up round it and shake loose. His rocks' state reads
at 120 px and under Reduced Motion. The victory pays off: a shower of crumbs
and feathers over the whole sky, the cap tossed to the middle of the screen
where it lands at 1.4x, spins like a coin and lies lit by its siren with the
brass badge floating beside it, and three pigeons dropping in to peck at the
crumbs. The name card's quote sits on a navy plank in larger type, and the
letters type in at 3.2 s, after the shout. His letterbox is the dragon's and
the Gargoyle's rule exactly. The squadron's gliders are individuals (three
plumages by slot, a little size, wingbeat tempo and bank each). Checks:
`test/king_coo_fix_test.dart`.

### Searchlight Gargoyle (rules version 43)

The Watchman of the Tallest Tower (`BossKind.searchlightGargoyle`) is the
guardian of 3-4. It is campaign only (a level plan names it; the endless
cycle never reaches index 6) and every rule below is gated by
`supportsMiniBosses`. He is perched: no hover and no arrival swoop, at
`x = max(birdX + .74, width - .50)`, `y = .5`; his hit circle is the usual
.115 (the chest lamp). Health is 160 at every encounter number, fury at 80.
Arrival is 4.6 s and defeat 3.8 s, as for the other cinematic bosses; nothing
burns or falls during either, and defeat clears the feathers and the beam.

Everything runs on the combat clock `t = age - 4.6`, `x = t mod 9`:

- 0 to 2.0 s perch (shuttered); 2.0 to 3.5 s warning (1.5 s); 3.5 to 6.4 s
  sweep; 6.4 to 9.0 s vent (lamp open, nothing attacks).
- The sweep is aimed once, as the warning begins, from the bird's height: a
  bird above the middle (height < .5) draws the beam from above. The beam is
  defined where it crosses the bird's column: from above `.16` to `.42`,
  from below `.84` to `.58`, gliding 1.8 s (fury 1.5 s) and then holding. The
  lit band is .09 tall each way (fury .095). Touching it hurts like a course
  edge: Classic ends the run, Star Trail loses the shield, then a heart, with
  the usual 1.5 s recovery.
- The lamp is shuttered except in the vent, and it is judged as a rock
  leaves the bird (`BirdRock.releasedAt`, the boss's age at the release;
  `SkyBoss.lampOpenAtRelease`), not where the rock lands: a rock released
  while the lamp is open takes full damage however long it flies (0.35 s on a
  narrow sky, 0.76 s on the widest), so the shots that count are the ones
  fired in the vent the player sees, 2.6 s at every screen width. A rock or a
  shatter blast released while it is shuttered is spent without damage
  (`lastGlanceAt`, the clink). Health (and fury) therefore changes in the
  vent and in the half second of the next perch that its last rocks are still
  flying, never between a warning and the end of its sweep.
- Stone feathers (`BossAmmo(feather: true)`) leave the top edge at
  `(birdX + .62, -.06)`, aimed to cross the bird's column at the height the
  bird had as they left: 1.72 s of flight (fury 1.41 s), gravity .30, radius
  .028. A calm cycle drops two (at .2 s and 4.6 s), a fury zone cycle three
  (.2, 4.5, 5.2) and a fury slit cycle one (.2). From rules version 49 they
  are level: none crosses steeper than 1.3 (see "Rules version 49" under
  the staged campaign bosses).
- Fury alternates: the first fury sweep is a zone sweep and every second one
  after it a slit of two beams (upper `.12` to `.21`, lower `.88` to `.79`,
  1.5 s, then held), leaving a dark gap .343 to .657 for the bird's centre, a
  corridor .314 tall (it was .214, `.26` and `.74`: a player hovering by
  tapping with a thumb 50 to 100 ms late and 40 ms jittery held it 52 to 70%
  of the time; now 95 to 99%, `test/gargoyle_lag.dart`).
- No random draw is made. The latches (`beamSide`, `slitSweep`,
  `sweepsAimed`, `furySweeps`, `featherSlot`) follow the clock, so pause,
  replay and seeks are exact. `SkyBoss.beamCentres`/`beamLit` and
  `SearchlightGargoyle.centres` are what the art draws and the rules test.
- Fairness is proved exhaustively (`test/searchlight_gargoyle_fairness_test.dart`):
  over every tap sequence at five taps a second, all 351 survivable start
  states (117 each for a calm zone sweep, a fury zone sweep and a slit) have a
  safe path; so do 324 after 0.3 s and 303 after 0.45 s without a tap; the
  whole cycle from the perch feather's launch too. The warning is fair down to
  1.3 s (0.7, 0.9 and 1.1 s leave 31, 14 and 2 unwinnable starts), so 1.5 s
  ships, and `SearchlightGargoyle.minWarnSeconds` guards it. Those paths are
  flown through the real simulation in `searchlight_gargoyle_test.dart`. The
  slit's search tolerates a 0.08 margin of error (0.04 before the corridor was
  widened), and a cycle whose perch feather left calm but whose sweep is fury's
  (fury begun by the last rocks of a vent) has a safe path from every start
  too (`searchlight_gargoyle_fix_test.dart`).
- `SkyBoss.previousHitAt` (render-only) is the time of the hit before
  `lastHitAt`, set by every landed hit of every boss; `hitGap` is the
  difference. The art reads it so nothing snaps when hits land .28 s apart.

**Presentation.** The Gargoyle faces the bird from a ledge on the right of
the screen, drawn by `GargoyleEncounterArt` (the Gargoyle branches of
`BossEncounterArt` only dispatch to it) from the parts in `lib/game/gargoyle_*`
and never by another boss's fall-through. One rig unit is 11.5% of the screen
height and the chest lamp sits on the rules' `boss.x, boss.y`:

- a stepped Art Deco body of violet-grey stone with steel: a crest of three
  low swept blades, a hooked beak, a brow visor and two lens eyes, a ruff, a
  stepped chest, thighs and talons gripping the ledge's lip, and a tail of
  five blades;
- the searchlight lamp is his chest: a brass octagon of eleven louvres round a
  lens, which is also the hit circle; shuttered except in the vent, cracks
  open in the stone from the first hits and run on in fury, and steam
  escapes through the ports at the shoulder;
- two fans of seven steel blades for wings, the far fan dimmer and higher,
  with one loosened blade that is the feather he drops;
- the world he stands on: a stepped tower top (a cornice with a brass band and
  a chevron frieze, three corbels, a shaft with lit and dark windows, a pier
  behind him in three setbacks), the weather-vane mount empty until the
  story's courier fills it, and a twig nest with a dozing pigeon.

Every pose fits inside the screen at 640x360 and 800x360, and the moon's rim
on his upper edges sets him off from the night.

Its poses:

- **Perch:** the lamp shuttered, the lenses pulsing at a third of their glow,
  the brow a little lowered, the talons on the lip and the fans ruffling.
- **Warning:** the lenses climb to full, the brow drops over them and the head
  bows or lifts toward the beam's side while he leans toward the bird.
- **Sweep:** the head follows the beam; in fury the second lens fires too and
  the slit's two beams close.
- **Vent:** the louvres open, the beak is ajar, steam jets from the ports at his
  shoulder and the lenses dim.
- **Hit:** a bleached flash, a wince that lifts the brow and a shiver of the
  whole figure.
- **Glance:** a rock off the shuttered lamp rattles the louvres and throws a
  brass spark.
- **Roar and fury:** the head thrown up, the beak wide and the fans flung open;
  in fury the lenses are white-hot and the seams crack amber.

The warning washes the swept fan in amber hatching, marches hazard tape along
the ray that borders the safe side, veils the safe side in deep blue and runs
a cool dashed line with chevrons toward it, ticking faster toward the end; a
tag at the left spells the dodge out (FLY LOW, FLY HIGH or SLIP BETWEEN THE
BEAMS) with a three-pip gauge. The beam is an amber body with a pale core
added as light (scenery inside it brightens), two hard hairlines and drifting
motes, a flare at the lens; in fury it is orange with a near-white core. It is
placed from the rules' band at the bird's column (never from a constant), and
the beam test reads the rules' own band. Beams and warning sit in the backdrop, under the stars, his feathers
and the bird, so they are never mistaken for New York's own searchlights (cream,
faint, no edge). A stone feather shows a dust telegraph where it will enter; a
feather that touches the plate's strip is drawn again over it. His plate is a
stepped steel plate in a brass rim, with an octagon lens medallion, an amber
gauge cut into brass segments, a brass spool at the fury mark and a `LAMP OPEN`
tag over the vent; `SPOTTED!` flashes over the bird when it is caught. His
own name card slams in on the roar (2.85 s) with GUARDIAN, THE SEARCHLIGHT
GARGOYLE, WATCHMAN OF THE TALLEST TOWER and the campaign's line.

The arrival is "stone to life": a storm (rain, a darkening sky) over the
caption, the tower sliding in from the right at .95 s with nine pigeons dozing
on his shoulders, lightning striking the vane mount's pin at 1.65 s (the instant
of `gargoyle_strike`), the stone cracking and cooling to colour, the lenses
igniting first, the pigeons flushed, the fan unfolding and the roar at 2.65 s
(`gargoyle_awaken`) with three rings, the letterbox timed as the Ember
Dragon's (open for the roar, out 0.2 s early), and a soft presentation-only
sweep that finds the bird and ends in an iris (no beam is ever lit in a
cutscene). In the fight distant lightning flickers every other cycle (9% of the
sky, one a cycle, never in the vent), and a hit, the tipping into fury and the
killing blow shiver him locally. The defeat is a white-out (the one bounded
layer), cracks that run on, the lamp's glass breaking at .6 s, the burst at
.85 s, a heap of limestone and steel, the visor tumbling off the ledge,
pigeons bursting out and two lenses left lit on the rubble; the victory card
says GUARDIAN DOWN!. Reduced Motion keeps every state (lamp, flare, warning,
cracks, fury, the stone fade, a still bolt and roar) and drops the motion
(rain, flicker, flash, sway, flush, rings, sweep, jolts, flight); its letterbox
is thinner and does not open. The story paints him through `GargoyleStoryArt`
(six moods, the delivered vane and a crest pigeon after his fall) and the
keepsake is his brow visor hooded over a lens.

**Audio and replay.** `gargoyle_strike` plays on the bolt (1.65 s) and
`gargoyle_awaken` on the roar (2.65 s), each within one 60 Hz step of its
picture; `beam_warning` at the warning's start, `beam_sweep` at the beam's
ignition, `beam_spot` when the bird is caught, `lamp_vent` as the lamp opens,
`lamp_glance` on a rock off the shuttered lamp, `feather_drop` as a feather
leaves and `boss_enrage`, `boss_break` and `boss_burst` as for the others. The
victory sound plays 0.25 s after its card begins, as the dragon's does.
Counters that drive the cues (`sweepWarnings`, `sweepIgnitions`, `spots`,
`lampOpens`, `lastGlanceAt`, `feathersLaunched`) are presentation only; the
tower's slide, the pigeons' flush, the visor's tumble and the distant
lightning have no sound yet. Seeks replay silently.

Checks: `test/gargoyle_staging_test.dart` (the hooks, the arrival clock, the
letterbox, at most one bounded layer, no blur, the frame's budget of 342
draw ops, no shader built after the prewarm, Reduced Motion, every audio cue's
edge against its picture's), `test/gargoyle_staging_scan_test.dart` (none of his
solid pixels is cut by the layer, the screen or the letterbox in 86 states at
640 and 800, with and without Reduced Motion, and a whole fight flown through
the real game renders every phase) and `test/gargoyle_story_test.dart`.

### Guardians in the encounter (rules version 43)

What King Coo and the Searchlight Gargoyle share in `BossEncounterArt` and the
screens around it (`test/ny_guardians_stage_test.dart` renders one whole
encounter of each through the real game and pins it):

- **Dispatch.** Each is drawn by his own stage (`KingCooStaging`,
  `GargoyleEncounterArt`), dispatched explicitly in the backdrop, the boss
  pass, the foreground and every kind switch (tint, light, ammo style, plate
  skin, story fit, keepsake): never the Baron's fall-through and never one for
  the other. They are campaign-only and never enter the endless cycle.
- **One wording.** The name card's small word is GUARDIAN (the level card's
  ribbon, the map's shield and the result's "Guardian down!" say the same, and
  no player-facing string says mini-boss); the victory card's title is
  GUARDIAN DOWN! for both (`BossEncounterArt.victoryTitle`), SKY RECLAIMED
  stays the chapter bosses', and each card carries the level's own line in
  quotes (`bossLine`).
- **One letterbox.** Both close and lift the bars on the dragon's arrival
  timing; the Gargoyle opens them for his roar as the dragon does, King Coo
  keeps them shut for his COO!, and King Coo's bars come in behind the dying
  figure 0.2 s later than the others.
- **Layering.** King Coo's squadron is painted by the shared enemy pass,
  except the pigeons still at his back, which his stage paints under his
  figure (so they come out from behind him); the Gargoyle's feathers are
  painted by his stage right after his figure and again over the plate's
  strip, and his beams are in the backdrop. Each branch is keyed on its own
  boss, so a pigeon is drawn for the Gargoyle and a feather never reaches
  King Coo's frame.
- **Story.** `StoryBossArt` paints each from his own rig in the six moods
  (`KingCooStoryArt`, `GargoyleStoryArt`) with his own stage fit, and
  `CampaignHeadwear` shows King Coo's cap and the Gargoyle's brow visor on the
  stamp.

### Campaign boss stages and vanguards (rules version 44)

The owner found campaign bosses "too fast to kill": "it should be easy first
but long, the player should take some time. Then after a certain health bar,
they get stronger, after another point they get a bit more stronger. Some of
them include smaller enemies also so before we deal with them they send some
small enemies and then themselves show up." Rules version 44
(`FlightSimulation.bossStagesRulesVersion`, `supportsBossStages`) does that
for a campaign level's boss, guardians included. Endless, co-op and duel
flights fly at 44 exactly as at 43 (`endless_plan_baseline_test.dart`), and
a campaign tape recorded at 41 or 43 replays its short fight at its own
version (`frozen_rules41_test.dart`, `frozen_ny43_test.dart`). The player's
guide is docs/campaign.md, "Boss fights"; the tests are
`test/boss_stages_test.dart`.

- **Health.** A staged boss (`SkyBoss.staged`) takes its health from
  `SkyBoss.campaignHealthFor`: Baron Bat 600, Spitter King 600, Dusk Empress
  620, Pirate Captain 780, Ember Dragon 1,080, King Coo 840 (420 at 44,
  `tougherCoo` below), Searchlight
  Gargoyle 640 (200 at 44 and 45, `fiercerGargoyle` below). Endless keeps
  `SkyBoss.healthFor`.
- **Stages.** `SkyBoss.stage` is 0 (warm-up) above two thirds of its health, 1
  down to a third, 2 (fury, `enraged`) below. An unstaged boss is 1 or 2 with
  fury at half, as before; `stageMarks` gives the bar's notches. In the
  warm-up (`calm`) volleys use `_warmUpOffsets` (one shot, or the smaller fan)
  at a longer `volleyInterval` and a lower `projectileSpeed`, and no helper is
  summoned (`summonIn` is infinite).
- **Growing stronger.** The step after the hit that crossed a third, the
  rules (`_advanceStages`) raise `stageReached` and stamp `stageUpAt`, hold
  fire for `SkyBoss.stageRoar` (1.4 s) and add a `SkyHeart` at the right edge
  at `SkyBoss.heartY` (campaign flights advance heart pickups from 44 for
  this). Leaving the warm-up also schedules the first helper
  `stageHelperDelay` (2.4 s) later and arms the signature attack.
- **Signature attacks** run on fixed combat-time cycles: the Pirate's tide,
  the Dragon's breath and swarm flocks, King Coo's squadron (and whistle), the
  Gargoyle's feathers. `signatureCycle` is the first cycle that runs: 0 for an
  unstaged boss, null through a staged boss's warm-up, then
  (`armSignature`) the first cycle whose onset (the tide's warning, the
  breath's quiet second, the puff, the cycle start) is at least
  `signatureLead` (1.6 s) after the boss grew stronger. The clock getters
  (`tide`, `tideWarning`, `breathWarning`, `breathing`, `breathQuiet`, ...)
  read zero in a cycle that does not run, and their counters (`tideSurges`,
  `breaths`, `swarmCallsDue`, ...) count only cycles that run, so the rules'
  latches and the edge-triggered cues never see a skipped cycle. King Coo's
  rules plan no squadron and blow no whistle in a cycle that does not run;
  the Gargoyle's rules drop no feathers and `featherSchedule` is empty there
  (his pose reads it; from rules 46 his warm-up drops the calm cycle's, see
  below). Everything else (the crumb bombs and puff, the beam
  and lamp) runs from the start. A staged King Coo's fury plans the calm
  squadron (one V, no picket) and keeps fury's three crumb rings: in a long
  fury the V and picket together hit the New York pilots about once per
  cycle, at 43 as at 44 (43's fury was short enough to hide it), and with
  the V alone they are hit about as rarely as in the 43 fight.
- **Vanguard.** `BossVanguard.wavesOf(kind)` lists three fixed waves for
  Baron Bat, the Spitter King, the Dusk Empress and King Coo (none for the
  others). When the boss is due, `_advanceVanguard` begins the vanguard
  instead (clearing the sky as the boss's arrival does, `_clearForBoss`),
  sends each wave from the right edge at its time, and lets the boss arrive
  `BossVanguard.bossDelay` (0.8 s) after the last member has left
  `enemies` (shot, rammed or flown off the left edge). Members are ordinary
  `SkyEnemy`s at the level's toughness; King Coo's are `squad` pigeons, which
  never snatch. `vanguard` stays on the simulation once cleared;
  `vanguardFlying` and `bossFight` tell the HUD and the music (the boss track
  starts with the vanguard; `boss_warning` sounds as it begins). The level's
  star track and route line hide through `bossFight`.
- **Audio.** A staged boss growing stronger plays its roar cue (fury keeps
  its fury cue).
- **Art.** `BossStageHudArt`: a staged bar has its fury mark at a third and a
  gem at two thirds (it glints in the warm-up and snaps as the boss steps
  up), a gold flare, and a STRONGER! tag with the stage hint under it.
  `BossPowerUpArt`: one effect for every boss through the 1.4 s roar (a
  swell in the boss's colour, streaks, two shock rings, chevrons, motes;
  ember on the fury step; still under Reduced Motion; at most about 5% of
  the screen brightens, under the 10% flash rule). `BossVanguardArt`: a card
  naming the vanguard as it begins, then a plate in the health bar's place
  with a pip per member (coming, flying, shot down, flown past) and "N LEFT",
  fading as the boss arrives. Unstaged bosses' plates are unchanged. Rules
  45: `CrustArt` draws the thrown crust (a tumbling stale slice in an orange
  halo), its impact and its shatter; a throwing pigeon pulls a crust from its
  breast feathers and cocks its wing through the wind-up, then throws; King
  Coo's card reads "Duck the crusts! Miss one and it comes back!".
  `StragglerArt`: a "comes back" sign (a gold arrow curling round) on the
  owed tag hanging under his plate ("×N" while `owed` > 0, a pop on each
  catch, "ALL CAUGHT!" when none is left), on each returning straggler (with
  a rumpled tuft and a plaster) and on the escaped pips of his vanguard
  plate. A straggler is drawn in front of him, not with his squadron behind
  him (`KingCooStaging.squadBehind` asks for a track).
- Nothing in rules 44 draws from the flight's random, so routes, replays,
  pause and seeks are exact.
- **Rules version 45** (`tougherCooRulesVersion`, `supportsTougherCoo`), from
  the owner's next playtest ("The pigeon boss small enemies is so bad and
  easy. They should throw something or threat… the boss itself is too easy
  to kill still. We need double health"): King Coo's vanguard pigeons are
  `SkyEnemy.throwsCrumbs`, with `EnemyAttack.crumb` (appended): after the
  usual 0.75 s wind-up (they coo, `pigeon_coo`) each throws one aimed crust
  at `SkyEnemy.crumbSpeed` (.40) every `crumbInterval` (2.2 s), a wave's
  members starting `BossVanguard.throwStagger` (0.5 s) apart; they fly at
  `BossVanguard.throwerDrift` (0.8) of the scroll. A crust hurts, is
  cancelled and shattered like a beetle's seed. `campaignHealthFor(kingCoo,
  tougherCoo: true)` is 840. Then the owner asked: "those who you didn't
  kill will come back during the boss time until you kill them all" (3-2
  only). `BossVanguard.returnsOf(kingCoo)`: in his fight
  (`_advanceStragglers`), at each of `returnTimes` (0.3 and 4.3 s of his
  14 s cycle) one of the pigeons still owed (`owed`: members gone without
  being downed, less `stragglerDownedAt`) and not on screen (`waiting`)
  comes back from the right at the next of `returnHeights` (.28, .72, .24,
  .76: never level with his body, which would take the rocks meant for
  them), with `stragglerHp` (10, one shot) and throwing crusts. One that gets
  away again is owed again; his defeat clears them. A rules 44 tape keeps
  the 44 fight. Asked to choose, the owner kept the stragglers throwing (the
  hardest of three measured options). New York's pilots now complete 3-2 in
  about 44% / 31% / 9% of flights (sharp / average / casual; 100% at 44,
  91 / 84 / 66% before the stragglers), and King Coo's fight takes them
  about 100 / 155 / 210 s with hearts topped up.
- **Rules version 46** (`fiercerGargoyleRulesVersion`,
  `supportsFiercerGargoyle`), from the owner's next playtest ("I like how
  hard King Coo is. I want Gargoyle to be the same hard and same length, now
  you can kill fast"; of three ways offered, the owner chose his own attacks
  fiercer and no minions): the campaign Searchlight Gargoyle is
  `SkyBoss.fierce`. `campaignHealthFor(searchlightGargoyle, fiercerGargoyle:
  true)` is 640 (`SkyBoss.fiercerGargoyleHp`). His warm-up drops the calm
  cycle's feathers (`calmFeathers`, at the calm speed). From the cycle his
  signature joins (`signatureArmed`), `SkyBoss.furyPace` holds: his zone
  beam takes fury's band (`furyLitHalf`) and glide (1.5 s), his feathers fly
  at `furyFeatherSpeed`, and feathers fall in the vent too, aimed at the bird
  as it lines up on the open lamp. `SearchlightGargoyle.fierceFeathers` is
  the calm cycle's schedule plus `ventFeathers` (7.0 s) in the full fight,
  and fury's zone or slit schedule plus `furyVentFeathers` (6.5 and 7.4 s) in
  fury; the rules launch it with `SearchlightGargoyle.due`, with no cut-off
  at the vent. It reads `aimFury` (fury as the sweep was aimed), so a fury
  that begins in the vent waits for the next cycle, and every vent feather
  crosses the bird's column before the cycle ends. Slits still wait for
  fury. `stageHint` reads "STRONGER · Feathers fall on the open lamp!";
  `GargoylePose.events` asks `perchFeatherIn` for the next cycle's wind-up.
  The fairness proof covers the three new cycles through the vent
  (`test/fiercer_gargoyle_test.dart`: every survivable start at the warning,
  after .3 and .45 s without a tap, at a .012 margin, and the whole cycle
  from the perch feather). New York's pilots take about 107 / 134–144 /
  323–350 s against him (27 / 68 / 130 s at 45) and are never touched; with
  pilots that react as King Coo's bots do, see docs/validation.md. A rules 45
  tape keeps the 45 fight.
- **Rules version 47** (`fairHeartsRulesVersion`), from the owner's report
  ("When I reached near the heart, the heart disappeared but I didn't get
  it", on 3-4): a bird whose feet brushed a stage heart's cream disc, about
  0.10 from its centre, missed it, and the heart vanished 0.085 behind the
  bird, still over its tail. On a campaign flight (`supportsBossStages`)
  `heartReach` is `SkyHeart.touchRadius` (0.11: the bird's half height and
  the disc's radius apart) instead of `SkyHeart.pickupRadius` (0.085).
  Endless, co-op and duel flights keep 0.085 and fly at 47 exactly as at 43;
  a rules 46 tape keeps the old reach. At every version a missed heart moves
  to the render-only `missedHearts` and drifts on, at half opacity
  (`HeartPickupArt.missedOpacity`), until it is off the left edge
  (`test/fair_hearts_test.dart`).
- **Rules version 48** (`tougherBaronRulesVersion`), from the owner's ask
  ("Double HP for the second occurrence of Baron bat in the infinite run"):
  on an endless flight, solo or co-op, the Baron who returns upgraded
  (encounters 6, 11, 16…) has twice the health, 480 instead of 240
  (`SkyBoss.healthFor(…, tougherBaron: true)`, `supportsTougherBaron`). It
  applies to every return, not only the second Baron, so a later Baron is
  never weaker than the one before. His debut (120), the other endless bosses
  and every campaign boss (always a debut) keep their health; duels meet no
  boss. A rules 48 endless flight flies exactly as at 47 until the returning
  Baron arrives (`test/endless_plan_baseline_test.dart`), and a rules 47 tape
  keeps the 240 Baron. The sharp pilot of
  `test/baron_bat_upgrade_test.dart` takes about 69 s at 2.2 and 61 s at 2.22
  to beat him (34 / 38 s at 47), ending with 2–3 hearts.
- **Rules version 49** (`levelFeathersRulesVersion`, `supportsLevelFeathers`),
  from the owner's report on 3-4 ("The gargoyl boss shots cover more when
  they shoot at the bottom half of the screen and it is unfair. If the bird
  is on top, it's easier to dodge", confirmed as the stone feathers, not the
  beam): the campaign Searchlight Gargoyle's feathers are level
  (`SkyBoss.levelFeathers`). A feather leaving .62 ahead crossed the bird's
  column at a slope of .98 (drop over run) when aimed at height .1 and 2.27
  at .9 (calm; fury .74 and 2.03), so at the bottom it touched a still bird
  over a band .33 tall instead of .18, and a bird pinned against the bottom
  edge had to climb into it, starting its dodge about 0.55 s before the
  crossing instead of 0.36 (fury 0.49 / 0.36). Now
  `SearchlightGargoyle.featherShot(…, level: true)` never crosses steeper
  than `maxFeatherSlope` (1.3, a calm feather's slope at .3): a feather that
  would leaves further ahead (`ahead`, up to 1.13 at the very bottom, still
  in front of his perch) and flies faster (up to .66, fury .72), in the same
  flight time and aimed at the same height, so every schedule and crossing
  time is unchanged. Calm feathers aimed above .3 and fury ones above .45
  are exactly as before. The rules give each feather a render-only
  `BossAmmo.launchX` (the art's age and wake count from it) and the dust
  telegraph follows `GargoyleFeatherArt.entryX(…, level: true)`. Every
  height from .3 down now lights the same .22 band and leaves the same dodge
  time as the top of the sky; the fairness proof still holds through all
  four of his cycles (`test/level_feathers_test.dart`). Endless, co-op and
  duel flights never meet him and fly at 49 exactly as at 48; a rules 48
  tape keeps the steep feathers.
- **Rules version 50** (`neferhooRulesVersion`, `supportsNeferhoo`): Egypt's
  guardian, `BossKind.neferhoo` (appended, `campaignOnly`), Neferhoo the
  Mummy Courier, on the new level 2-6 "Return to Sender" (30 s run-up, then
  him: staged, `campaignHealthFor` 300, no vanguard). Only a plan whose boss
  he is needs 50 (`LevelPlan.usesNeferhoo` → `minRulesVersion`); endless,
  co-op, duel and every other level fly exactly as at 49
  (`test/frozen_rules49_test.dart`, recorded from the main tree before the
  change; `test/frozen_rules45_test.dart` still pins 45). Ancient
  Arabia moved from 2-6..2-8 to 2-7..2-9; a save is renamed once at database
  schema 6 (`ProgressDatabase.renumberLevels`), and a finished level stays
  open. His rules (`lib/domain/neferhoo.dart` pure, `neferhoo_rules.dart`
  acting), on a 12 s combat-time cycle that fury never retimes:
  - **Anchor**: x `max(bird + .70, width − .55)`, y `.52 + .04 sin(.85 t)`
    (the hit circle bobs at every setting); his hand is .10 left of it.
  - **Mail call** (every cycle, from the warm-up on): at .6 s a lane locks on
    the bird's height (.16-.84; co-op birds take turns) and three letters
    (envelopes .090 × .064) leave his hand at 1.6, 2.0 and 2.4 s, flying
    left at .45 (screen-fixed). Fury is latched at the lock: the express post
    is five letters, .32 s apart, at .52. A letter that touches a bird hurts
    it like a course edge and is spent (also when it meets a recovering
    bird, harmlessly); one that leaves the screen is gone.
  - **Return to sender**: a rock that meets a letter (swept over the step)
    within the letter's half height plus the bird's radius (.070) of its
    lane, judged on the rock's height and reaching .008 above and .028 below
    for the beak's offset (so a shot from anywhere the letter can hit the bird
    catches it), sends it home: harmless and unstrikable, it flies a quadratic
    curve (control point +.25, −.14 from where it was struck) to his chest in
    `clamp(distance / 1.4, .35, .8)` s and lands once for 25 (the wraps do
    not soften it); letters sent back together land at least .1 s apart. A
    rock charged ≥ .35 (the bulk return, on by default) sends back every
    letter it meets and carries on; a tapped rock is spent on the first. A
    sprinting bird that meets a letter sends it back.
  - **The wraps**: a rock or a shatter blast on his hit circle deals a third
    of its damage, at least 1 (a tap 3, a full charge 13).
  - **The ankh** (his signature, `_signatureClock` (12, 5.4); a staged
    warm-up throws none, and the stage-up arms the first lock at least
    1.6 s away): at 5.4 s two lanes lock, the first on the bird (.25-.75),
    the second .32 toward the middle; thrown at 6.8 s at .85, it flies out
    along the first lane to .22 behind the bird's column, a half circle, and
    back along the second to his hand (about 2.7 s at 640 px, 4.1 s at 864).
    Both passes hurt like a course edge, sprint or not; rocks pass it by. In
    fury (latched at the lock) two fly at .95, the second on the mirrored
    loop .5 s later.
  - **Stages**: warm-up (above two thirds) the mail call; full fight the mail
    call and the ankh (`stageHint` "STRONGER · The golden ankh comes back!");
    fury (a third) the express post and two ankhs. His hint
    (`NeferhooBoss.neferhooHint`, the semantics label): a return's
    "RETURN TO SENDER! · −25", the ankh's (or two ankhs') line from its lock
    until it is home, after eight scuffs without a return "Rocks only scuff
    his wraps. Shoot his LETTERS back!", the mail call's (or express post's)
    while its stream is coming, else the stage's open-sky line.
  - **Defeat** (by a landing or a rock) clears everything: nothing is live
    or hurts after it, and letters still flying home never land.
  - Nothing draws a random; latch times are exact cycle times where the
    clock decides them, the step's where a rock or a bird does; the counters
    (`mailLocks`, `lettersDealt`, `ankhThrows`, `ankhCatches`,
    `returnsLanded`, ...) only rise, at most once a step, and seeks
    re-simulate them. The pilots on these rules (family about 60 s at 640
    px, first-timer about 2 minutes, practised 27 s) and the fairness search
    are in `docs/validation.md`.
- **Rules version 52** (`tougherNeferhooRulesVersion`,
  `supportsTougherNeferhoo`, `SkyBoss.tougherNeferhoo`), from the owner's
  playtest of 2-6 on a phone ("It's so easy. Double the health. Give it some
  helpers, small flying enemies. The letter particles move faster."; the
  helpers he picked: mummy bats). In 2-6, the only plan that names him,
  Neferhoo now:
  - has **600 health** (`Neferhoo.tougherHp`,
    `campaignHealthFor(…, tougherNeferhoo: true)`; 300 at 50), so each stage
    is twice as long;
  - deals his letters **1.4 times faster** (`Neferhoo.tougherPace`,
    `letterSpeedOf`: .63, the express post .728), and a returned letter flies
    home 1.4 times sooner on the same curve (`returnSecondsOf`:
    `clamp(distance / 1.4, .35, .8) / 1.4`). Every beat (the lock at .6, the
    releases, the ankh) is where it was;
  - sends **mummy bats** (`EnemyKind.mummyBat`, appended, `campaignOnly`;
    no lineup may name one: `LevelPlan.problem`) with each mail call once he
    grows stronger (`Neferhoo.batsFor`): none in the warm-up, a **pair** in
    the full fight, a **trio** in fury. They are latched with the call at its
    lock (`NeferhooFight.bats`, `NeferhooBat`) and fly in from the pyramid's
    side, the right edge (`batStartX`: the sky's width + .10), down the
    call's lane behind its letters: the first is timed to trail the call's
    last letter by .15 as that letter leaves his hand (`batLaunch`: .8 and
    1.2 s after the lock on a 16:9 screen or wider; fury's 1.40, 1.72 and
    2.04), at .60 a second (fury .68: `batPace`, `furyBatPace`; each bat's
    `SkyEnemy.drift` is set from the scroll speed as it flies in, so the pace
    holds at every width and however long the fight). Slower than the
    letters, they never fly among them; a bat is seen at least 1.8 s before
    it reaches the bird, crosses its column just after the call's last letter
    and leaves its reach at least 2.3 s before an ankh can reach it. A bat
    is a small enemy: 10 health (one rock of any weapon), the simple bat's
    flight arc settling into the lane .22 before the bird, touch hurts like
    any enemy, a sprint's ram downs it, +3 and an `enemyHit` / `enemyRammed`
    event of its kind. His defeat clears them, and none flies in after it.
  - says so: the stage-up card "STRONGER · The ankh, and his mummy bats!"
    (`Neferhoo.tougherStageHint`), the semantics hint "MUMMY BATS · Shoot
    them down!" while a call's bats are still coming after its letters
    (`batsHint`), and the mail lane's telegraph (`NeferhooFightArt.mailLane`)
    stays until the call's last bat is .15 past the bird (or down), timed at
    the letters' real speed. The bats are drawn by `MummyBatArt` (shared
    enemy painter signature), prewarmed during 2-6's countdown.
  2-6 at 50 or 51 (a saved tape) flies exactly as before (51, the all-rings
  bonus, never reaches 2-6, which lays no rush path), its run-up is the same
  at 52, and endless, co-op, duel and every other level fly at 52 exactly as
  at 51 (`test/frozen_rules50_test.dart` and `frozen_rules51_test.dart`,
  recorded before the change; `frozen_rules49_test`, `frozen_egypt50_test`,
  `endless_plan_baseline_test`). It was built as 51 and became 52 when the
  all-rings bonus took 51 first. Pilots and the fairness search on these
  rules are in `docs/validation.md`.
- **Rules version 53** (`bossGrowthRulesVersion`, `supportsBossGrowth`),
  from the owner's ask ("For the boss's second encounter we increase the HP
  currently but for the 3rd+ encounters it's the same HP, we wanna have a
  rate of increase for the next encounters, that works for nth encounter").
  Endless boss health climbs 30 per encounter for four encounters and then
  stops, so a kind's second meeting (encounters 6 to 10) was its toughest
  and every later meeting had the same health. Now, on an endless flight,
  solo or co-op, each meeting of a kind after its second has
  `SkyBoss.growthPercent` (25 %) more health than the one before, rounded to
  10 in integer steps (`SkyBoss.healthFor(…, growing: true)`; the meeting is
  `SkyBoss.meeting(kind, number)`, from the five-kind cycle). The first two
  meetings keep their health:

  | Meeting | 1 | 2 | 3 | 4 | 5 | 6 |
  |---|---|---|---|---|---|---|
  | Baron Bat | 120 | 480 | 600 | 750 | 940 | 1180 |
  | Spitter King | 210 | 330 | 410 | 510 | 640 | 800 |
  | Dusk Empress | 240 | 360 | 450 | 560 | 700 | 880 |
  | Pirate Captain | 300 | 420 | 530 | 660 | 830 | 1040 |
  | Ember Dragon | 360 | 480 | 600 | 750 | 940 | 1180 |

  Campaign bosses (staged, `campaignHealthFor`) and the guardians keep their
  health; duels meet no boss. A rules 53 endless flight flies exactly as at
  52 until encounter 11, the third Baron, and a rules 52 tape keeps the old
  health (`test/boss_growth_test.dart`).
- **Rules version 54** (`cooRestartRulesVersion`, `supportsCooRestart`,
  `SkyBoss.quickRestart`), from the owner's ask ("The last time King coo
  breaks down and waits, it takes to long for him to start shooting. He
  should restart faster."). King Coo's fight runs on a fixed 14 s cycle, and
  most of a player's damage lands in the puff window (7.6 to 10.0 s), so his
  last stage-up, into fury, usually comes there, often with a pop. Nothing
  else of that cycle was left after it, and his first fury ring locked only
  at the next cycle's 0.6 s: 5.7 to 7 s after the break. Now the campaign
  King Coo ends that cycle at the first step when nothing of it is left
  (`_restartCoo` in `king_coo_rules.dart`): his 1.4 s stage roar is over;
  the chest has settled (cycle time 10.4) or, after a pop, he has had his
  `KingCoo.popRecovery` (2.6 s, the art's dizzy spell and recovery); every
  crumb has settled; and every squadron pigeon is a pigeon's reach past the
  rearmost bird. His next cycle begins there (`SkyBoss.restartCoo`), so its
  first ring locks 0.6 s later: 3.2 s after a pop, or 0.6 s after the
  squadron has passed. It happens once a fight, in the cycle he grew
  furious in; his later fury cycles keep 14 s. The tail holds no beat of the
  cycle (its whistle, window, rings and straggler returns are all behind
  it), so the jump skips no edge: his cycle clock (`SkyBoss.cooClockAt`,
  `cooCycleStart`), which every cycle read of the rules, the art and the
  test bots now goes through, simply counts the new cycle from that step.
  Endless, co-op and duel flights meet no King Coo; every other flight
  flies exactly as at 53 (`test/king_coo_restart_test.dart`).
- **Rules version 55** (`fasterNeferhooRulesVersion`,
  `supportsFasterNeferhoo`, `SkyBoss.fasterNeferhoo`, `NeferhooBeats.faster`),
  from the owner's ask after beating the tougher Neferhoo in about 49 s ("It
  is still stall for too long. It should call the bats more and from the
  beginning. It needs 100 more HP. It needs to shoot more."). In 2-6 only:
  700 health (`Neferhoo.fasterHp`; 600 at 52 to 54, which rules 53's endless
  boss growth never touched). His clock runs a 10.5 s cycle instead of 12:
  the first mail call locks at 0.6 s with its mummy bats behind its letters
  from the warm-up on (a pair; a trio in the full fight; four in fury); the
  ankh locks at 5.4 and is thrown at 6.8 as before; once its return pass is
  over, a second mail call (three letters, the express post's five, no bats)
  locks on the bird at 9.6, so its letters reach the bird early in the next
  cycle, a call ahead of that cycle's first. A warm-up cycle (no ankh) sends
  a wave of two bats down a lane locked on the bird at 5.9 instead
  (`Neferhoo.waveBats`, staggered 0.3 and 0.8 s after the lock). The
  longest stretch with nothing crossing the bird on the app's 2.2 sky drops
  from 11.2 to 4.4 s in the warm-up, 6.1 to 3.1 in the full fight and 5.7 to
  2.7 in fury. A returned letter deals 18 (`Neferhoo.fasterReturnDamage`,
  25 before): twice the letters a cycle, each worth less, so a practised
  player's fight grows longer with the extra health (the practised pilot
  62 to 75 s) instead of shorter. Every lane locks on the bird, no bat is
  still coming at a mail call's lock, and every bat is past the bird at
  least 2.0 s before an ankh can reach it; every scenario stays viable at
  five taps a second (`test/neferhoo_faster_fairness_test.dart`). The art
  reads the boss's clock: each call's lane shows until what it sent has
  passed (two at once at the join), the pose acts the second call and, on
  the faster clock only, watches the ankh across the cycle's join and skips
  the catch's wing tuck when a deal swings the wing at the same moment; the
  open-sky gag drops out of the full fight and fury. 2-6 flown at 50 to 54
  flies exactly as before (`test/frozen_rules54_test.dart`); endless, co-op
  and duel flights and every other level fly exactly as at 54.
- **Rules version 56** (`cooPairsRulesVersion`, `supportsCooPairs`): King
  Coo’s escaped vanguard pigeons return two together at each return slot,
  one above and one below him, alternating the pairs (.28, .72) and
  (.24, .76). Both enter at the same horizontal position; their crust
  throws remain staggered by 0.5 s. If only one pigeon is waiting, only
  that one returns. The return times, one-shot health and owed count stay
  the same. Rules 45–55 keep their single returns for saved replays.

### Built levels (rules version 64)

Players build levels by hand for Tap & Fly and the camera mini games; see
[level-builder.md](level-builder.md). A built plan (`BuiltPlan`) is a
`FlightPlan` whose items are laid in route order, each at its own world
position, with nothing drawn from a random: gates, stars, trios, hearts and
(Tap & Fly) enemies, a finish line or a boss finale. The course scrolls at
the mode's cruising speed times the level's pace, without the endless ramp.
On a push-up or squat level it slows for a player whose calibrated movement
is slower than 3 seconds, by the ratio of the endless passage spacing, never
below ×0.35 (`BuiltPlan.speedScale`); the cycle is in every tape already, so
replays need nothing new. A moving gate's swing is timed so a cruising bird
reaches its middle at its placed phase. Placed hearts are caught in every
mode, from as near as a campaign bird catches one. A boss finale is the
campaign's staged fight with its vanguard, called when the bird reaches the
mark. The tape carries the whole plan under `built`. A plan refuses rules
below 64, and every other flight flies exactly as at 63.

### Touch boss encounters (rules version 15)

After 45 seconds of active touch flight in Star Trail or Classic,
clear normal gates, attached pickups, bats and rocks for Baron Bat. Preserve
the star combo. A 2.5-second entrance and warning precede
combat; the boss then hovers on the right with a visible HP bar. Existing Shoot
controls fire straight rocks: one rock deals one HP, and a bat in front can
intercept it. The first boss has 12 HP; later bosses gain three HP up to 24.

Alternate aimed fireballs and three-shot fans, with a charge cue before firing.
Summon small bats every six seconds after the first five seconds of combat.
Below half HP, every volley is a fan, shots accelerate and helpers arrive more
often. Enemy ammo follows each course's normal shield, heart, recovery and
collision rules. Clear ammo and helpers immediately on defeat; Star Trail
awards 30 points and restores the shield. After a two-second celebration,
resume ordinary gates with safe approach distance. Schedule the next encounter
45 seconds after normal flight resumes. No normal gates spawn during the fight.

Boss clocks freeze on pause, resume countdown and run end. Replay reconstructs
all attacks and victories deterministically from the existing input journal.
Versions 1–14 retain their previous rules. Cloud Cruise and non-touch control
modes have no bosses. Reduced Motion removes decorative
wing motion, hit flashes and defeat travel while retaining gameplay movement.

### Post-boss heart pickup (rules version 24)

After each touch Star Trail boss victory celebration, place one heart at the
center of a randomly chosen opening among the next 2–7 gates. Use the seeded
simulation RNG and follow the gate's safe height, including moving openings.
The heart scrolls into reach during the 45-second interval before the next
boss. It grants one additional life on collection, up to a maximum of five.
At five lives, collecting a heart consumes it without extra-life feedback.
Use a fixed 0.085-height pickup radius; the star magnet affects only stars.
Missing the heart grants nothing and does not reset the star combo. Remove
passed hearts and clear any remaining pickup when a boss arrives. (A passed
heart drifts on, faded and out of the rules, off the screen; a campaign
flight's reach is wider from rules 47.)

Render a coral heart with a cream backing and a gentle halo pulse; Reduced
Motion keeps it still. Collection shows '+1 LIFE!', a happy bird reaction and
a reward sound. Above three lives, show a compact heart and numeric count in
the HUD. Pause, countdown and game over freeze pickups. Rules versions 1–23
retain their existing gameplay and RNG sequence.

### Cinematic boss presentation (rules version 17)

The entrance lasts 4.6 seconds: dim the sky and build a storm, reveal a glowing
silhouette, unfold the wings, introduce the boss by name, then cue the return
of control. Use separate wing, body, face, armor and crown layers with windup,
recoil and contact reactions. Animate the charging orb before each volley and
show a brief damage trail in the segmented HP bar.

The 3.8-second defeat begins with a stagger and loose crown. At 0.85 seconds,
release a localized burst, smoke, debris and shockwaves; the detached crown
spins away. Reveal the victory card at 1.55 seconds and fade back to ordinary
flight. Keep the bird safely coasting and suppress flap/shoot inputs during
both cinematics. Pause, interruption and resume countdown retain their normal
meaning, and no cinematic input queues into combat.

All animation and particles derive from the simulation clock for exact pauses
and replay seeks. Sound cues fire on crossed beats, stay silent on seeking,
and honor sound settings; pause stops effects. Lower music during cinematic
beats. Reduced Motion removes shake, flashes, spinning debris and decorative
travel. Version-15/16 journals retain their 2.5-second entrance, 2-second exit,
original control behavior and original boss art.

### Directional small enemies (rules version 18)

Replace the frontal enemy badges with left-facing animal profiles: a natural
cave bat with webbed finger wings, a teal spitter beetle with a luminous throat,
and a coral dusk moth with three amber throat glands. Heads and eyes face the
bird and follow its height; passing the bird flips their facing. Keep their
shared 0.045-height-unit hit radius and the existing one-rock defeat reward.
Use distinct time-based wing motion and firing poses. Reduced Motion freezes
decorative wings but retains attack information.

The bat remains a contact enemy. A beetle releases one aimed pellet at 0.44
height units per second; a moth releases a fan at angles -0.30, 0, +0.30 radians
at 0.34 units per second. Lock aim on release rather than homing. Charge visibly
for the final 0.75 seconds of the initial 1.1-second approach, then use 2.4- and
3.2-second cooldowns respectively. Start the clock only when fully visible and
ahead of the bird; stop attacking within 0.40 height units of it. Summoned
shooters start far enough ahead to complete their warning on small screens.

Pellets have a 0.016-height-unit radius, collide with buildings, and can be
intercepted by player rocks. Use normal course damage, shield and recovery
rules. Limit active small-enemy ammo to 12, remove off-screen ammo, and clear
it on boss arrival and defeat. Freeze attack clocks with the simulation;
reconstruct active warnings, recoil and pellets on replay seeks. Versions
before 18 keep their old enemy behavior and art. Movement
control modes remain free of enemy attacks.

### Screen entry and missed stars (rules version 25)

Uncollected stars remain visible after the bird passes them, scrolling left
until they leave the screen. A miss still resets the streak only once; collected
stars disappear immediately.

Ordinary touch enemies and boss helpers start beyond the right edge, including
room for their wings. Shift the entire ordinary approach far enough right to
preserve the enemy's lead ahead of its building. Attack warnings begin only once
the enemy is fully visible. Versions 1–24 keep their original spawn positions
and timing for saved replays.

### Simple purple bat (rules version 19)

Use the boss's basic purple body, ears, eyes, fangs and membrane wing shapes
at the normal enemy hit radius for the primary bat. Omit its crown, cape,
armor, gem, gold trim and wing stars. Track the bird with its eyes. It is a
one-hit contact enemy with no boss HP, projectiles or cinematic behavior.
Keep the cave bat as its own fourth enemy in the normal rotation: simple bat,
beetle, moth, cave bat. Boss helpers rotate simple bat, beetle and moth. Older
journals retain their original selection, behavior and replay results.

### Natural enemy flight (rules version 20)

Version 20 gives small enemies gentle vertical flight arcs: up to 0.011 height
units for the simple bat, 0.010 for the cave bat, 0.007 for the beetle, and 0.014
for the moth. Two slow waves create a smooth, less uniform path; distinct
spawn phases and a slight wing-clock variation avoid synchronized flapping.
Bank by at most 0.07 radians with the flight arc. Dampen the motion during
charge and recoil, and ease into the original aiming lane near the bird.
Body position, hit testing, aim and ammo origin share the
same vertical position. Reduced Motion removes banking and wing animation,
while preserving gameplay movement. All motion follows simulation time and
replay reconstruction; versions before 20 retain straight flight.

The refined spitter beetle separates a compact left-facing head, thorax,
segmented abdomen, hinged hard wing cases and translucent flight wings.
Near and far membranes have independent phases and turn edge-on through each
stroke. Legs tuck and antennae trail during charge; mint fills the cheek sac.
The release has a damped recoil through the shell, feet and cheek. Keep the
mouth fixed at local (-1.05r, 0) through the shape changes so the projectile
origin remains coherent. Reduced Motion freezes decorative time while
preserving charge and recoil information. This refinement changes artwork
and local animation only; the shared simulation and attack timing stay intact.

### Spitter beetle boss (rules version 21)

Keep Baron Bat as encounter one. Encounter two introduces Spitter King, then
alternate bat and beetle encounters, preserving the 45-second normal-flight
interval after each victory. The beetle begins with 18 HP and gains six HP on
each return, capped at 30; bat health retains its existing progression.
Versions 15–20 keep the original all-bat sequence and attack timings.

The beetle alternates aimed three-shot and five-shot acid fans at 1.8-second
intervals, beginning one second after the entrance. Shots travel at 0.56 screen
heights per second with 0.18-radian spacing. At half health, fire five-shot
fans every 1.3 seconds at speed 0.66. Preserve the 0.65-second charge cue and
fixed trajectories. Summon spitter beetles after four seconds, then every 4.8
seconds (3.8 in fury), with enough approach distance for their visible windup
on narrow screens. Hover through a slightly faster, wider vertical arc.

Give the beetle boss a bespoke alchemist-monarch design rather than an
enlarged small-enemy rig: a jade monarch beetle with a monocled amber slit-pupil
eye, a heavy gilded brow and a gilded cheek guard. Its regalia is brewing
equipment: the crown is a brass band of three corked glass flasks with a rose
jewel (replacing the earlier expedition hat and the earlier ban on crowns, so
the King is unmistakably royal without wearing a generic crown), and its
abdomen is a glass still in a brass cage with a pressure dial, a spring-loaded
relief valve, a steaming tailpipe and a dripping tap. Two raised wing cases
with gold-tipped thorns and a gilded drop crest form its mantle over two
beating membrane wings. The mouth is a brass trumpet whose dark throat stays at
local (-1.05r, 0); a jowl sac beneath the face stores the acid, fed by a hose
from the still. Jade chitin, brass, glass and glowing acid are four distinct
materials, lit from the upper left with a bounce-lit rim on the lower right, so
the shared teal/mint family still reads as the small spitter's grand relative.

The 4.6-second entrance rises from a dark silhouette with the wing cases
folded, unfolds them and lifts the crown with a claw. Pump the still during
charge: the acid level, glow, dial needle, valve, jowl and crown flasks rise
together over the 0.65-second charge, the trumpet swells and its throat lights.
The spit drops the level, kicks the crown and sloshes the vat. Raise a beckoning
claw, flare the still and glint the jewel to summon helpers. In fury the whole
brew, crown flasks and tap drips turn amber-hot, the iris turns red under a
scowl, the valve blows, the tailpipe and crown steam, and hairline cracks glow
through the glass. The boss also blinks, glints its jewel and drips from the
tap when idle (all frozen under Reduced Motion). Keep the mouth origin fixed at
local (-1.05r, 0). Tint the storm green (amber acid shots in fury) and
introduce the boss as the Brewer of the Swarm, with its name in HP and
semantics; its health-bar medallion carries the three-flask crown. The
3.8-second defeat loosens the body, cracks the still, throws the crown and
releases an acid pressure burst with arcing droplets and popping bubbles.
Keep the bird coasting safely in cinematics, shared sound cues, pause behavior,
course damage, victory cleanup and rewards. Reduced Motion freezes decorative
animation; simulation movement and readable charge cues remain. Replay derives
the boss kind from its recorded rules version and encounter number.

Rules version 23 widens acid fan spacing from 0.18 to 0.30 radians. Normal
volleys alternate three shots at offsets [-0.30, 0, 0.30] and four shots at
[-0.60, -0.30, 0.30, 0.60]; fury always uses the four-shot fan. Removing the
full fan's center shot leaves a dodge lane around the original aim point,
including on narrow phones. Keep projectile speeds, attack intervals, charge
cues and summons unchanged. Versions 21–22 replays retain the original fans.

Rules version 37 makes the Spitter King sturdier and its full fan less
predictable. The King starts at 210 HP instead of 180, keeping the 30-HP
progression step and the cap (210 / 240 / 270 / 300 / 330), and stays below the
Dusk Empress's 240 on the first cycle. The full fan is five slots at
[-0.60, -0.30, 0, 0.30, 0.60] radians and leaves one out per volley, drawn
from the flight's seeded random among the inner three, so the open lane sits
on the aim point or one slot to either side. A side lane is skipped when it
would cross the bird's column within 0.088 of the top or bottom of the sky, so
the lane is always on screen; the aimed center lane always qualifies. The draw
happens once per Spitter King volley as it fires, on the same random that
drives the rest of the flight, so replays and seeks reproduce it. Three-shot
volleys, speeds, intervals and summons are unchanged. Rules 23–36 keep the
fixed center gap and 180 HP.

### Dusk moth boss (rules version 22)

Cycle Baron Bat, Spitter King and Dusk Empress, introducing the moth at the
third encounter. Keep the full 45-second normal-flight interval, shared
cinematics, rewards, cleanup and course restrictions. Version 21 retains its
bat/beetle alternation; earlier versions keep their original boss rules.
The moth starts with 24 HP and gains three per encounter-number increase,
capped at 36. Existing bat and beetle health formulas remain unchanged.

Fire aimed five- and seven-shot pollen fans, alternating every 1.65 seconds
at speed 0.62 screen heights per second. Fury begins at half HP: seven shots
every 1.2 seconds at speed 0.72. Space shots 0.24 radians apart; hover farther
right so fans have room to separate on narrow phones. Keep the shared
0.65-second charge warning and fixed trajectories. Summon dusk moth helpers
after 3.8 seconds, then every 4.6 seconds (3.6 in fury), retaining their full
approach and attack warnings.

Every eight seconds of combat time, show a 0.8-second broken-ring warning
before raising a silk shield at second five. The shield lasts 1.6 seconds;
the moth can still attack, but rocks touching the shield are consumed without
HP loss or a reward. Match its drawn radius to the collision radius, 1.85
times the boss radius, and show a block reaction. Warning time remains a
damage window. Fury does not reset or shorten the shield cycle. Cutscenes
disable the shield; pause and resume countdown freeze it along with combat.

Use a bespoke coral moth-queen with four velvet rose wings that deepen to
midnight violet (hooked falcate forewings, luna-tailed hindwings), pearl
scalloped hems, glowing moon eyespots, a layered ermine fur mantle, tall
plumed feather antennae swept back like a headdress, a glaring kohl-eyed face,
three amber throat glands in a gold setting and a crescent diadem. In fury the
wing veins, hems and eyespots ignite to ember and the fur bristles. Tint
pollen gold, the storm coral and the shield pale blue. Give the shield a continuous collision-edge rim, woven silk loops,
lunar clasps and localized block ripples. Keep its center transparent and its
status hint blue even during fury. Seat the diadem over the head's crest with
a lower rim fitted to the skull, sharing the head transform until defeat
releases it; avoid independent lift or tilt that separates it from the head.
Draw the circlet in the moth's left-facing perspective: a narrow front plate,
foreshortened crescent and gem at the left forehead, a curved near side band,
and a visible elliptical opening with partially occluded far prongs.
Unfold wings on arrival, glow the
glands during charge, curl legs on defeat and release the crown during the
shared victory burst. HP hints and live semantics identify the shield state.
Reduced Motion freezes decorative movement while retaining warning, shield,
charge and fury cues. Replay reconstructs all state from the versioned input
journal, including shield blocks and backward seeks.

### Dusk moth debut (rules version 37)

The first Dusk Empress of a flight, encounter 3, is a gentler introduction.
She fights without her silk shield: no warning ring, no shield and no block
reaction, so every rock that touches her counts. Her helpers close in at 60
percent of the course scroll speed, giving the bird more time to line up a
shot; their attack warnings and health are unchanged. The status hint reads
"No veil yet" instead of the shield states. Every later Dusk Empress, encounters
7, 11 and so on, brings the full shield cycle and helpers at the normal pace.
Rules versions 22–36 keep the shield and the normal pace from the first
encounter. Replay derives the debut from the recorded rules version and the
number of bosses already defeated.

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
- `ProgressRepository`: stores settings (including the equipped bird), mode-specific records, run summaries with the bird that flew (and the campaign level, if any), and each campaign level's bests.

Keep movement interpretation and game rules independent of cameras and widgets so they can be tested using synthetic inputs.

### One picture on every screen

Every device shows the same game. The whole app is laid out on the reference
phone, a landscape **792 × 360 dp** screen (2.2:1), and `ScreenFrame`
(`lib/ui/screen_frame.dart`, wrapped around the router in `lib/main.dart`)
scales that picture uniformly to fit the display. Whatever is left becomes deep
navy bars (`SkyColors.night`): above and below on a 16:9 phone or a tablet, at
the sides on a phone wider than 2.2. Inside the frame every screen sees a
792 × 360 `MediaQuery`. The device pixel ratio is scaled, so cached stills stay
sharp, and safe-area insets are kept only where a notch reaches past a bar.

- **Play.** A flight always simulates a 2.2-wide sky (`viewportWidth`, the
  rules' default). That fixes the look-ahead, boss anchors, enemy fire windows,
  pigeon snatches and the art envelopes on every device, so no phone or tablet
  plays easier or harder than another.
- **Menus, map, story, cards and HUD** compose exactly as on the reference
  phone; only their overall size changes.
- **Taps on a bar** land on the nearest edge of the picture, so in Tap & Fly the
  whole display still flaps.
- **Replays** still letterbox an older tape to the width it was recorded at.
- **The landscape lock** holds on large screens too. Android declares
  `android:appCategory="game"`, which Android 16 needs before it honours the
  orientation of an app on a tablet. iOS lists landscape only and requires full
  screen on iPad.

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
- Taking a break or backgrounding pauses the run, and it resumes after a countdown; rules versions before 35 ended a scored run instead. Tracking loss and collisions still end a scored run.

**Jump & Fly**

- Jump launches use the regular Star Trail course with buildings, stars and hearts, without enemies or shooting. Sky Courier and Cloud Cruise are retired. Old journals and diagnostic links that name them open as Star Trail.
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
- Use alternating high/low passages and spacing based on the calibrated cadence across every course. Save squat statistics separately from push-ups, jumps and touch; squats contribute to daily goals and passport progress.
- Append the persisted mode at index 3, preserving existing records. Replay version 10 adds squat journals with height and repetition inputs; previous journals retain their rules.
- Expose squat starts in the Play mode picker, with grounded squat artwork, calibration feedback, a squat counter and a separate personal best.

Run only the detector required by the selected mode.

### 3. Deliver the finished visual experience

Use a playful cartoon direction: expressive chunky birds, layered skies and floating islands, sky-blue backgrounds, coral and yellow accents, rounded typography, and bouncy transitions.

Build:

- Animated home screen: title lockup, a hero Play key with a Campaign key beside it, the four control pictograms, the equipped bird on its island, a best-flight pill and a dock of five shortcuts. It is full-bleed on any phone shape, keeps every target at least 48 dp on typical phones, and is fully still with Reduced Motion.
- Illustrated setup, camera permissions, calibration, and countdown.
- Large gameplay graphics, score, and simple tracking feedback.
- Results with score, best score, mode-specific statistics, and retry. A fatal collision first plays a short cartoon knockout, then shows the same results on a game-over stage over the frozen flight (see Knockout and game-over stage). A campaign level's finish line first plays a short celebration that hands its bird to the level result (see Finish-line celebration).
- Bird collection of four distinct birds, each with its own trail, all choosable from the start.
- The campaign's world map, story scenes, level card, level result and chapter postcards (see Campaign).
- Settings for music, effects, reduced motion, and resetting local progress.

Birds are cosmetic only: they never change the collision circle, movement or scoring. The Flock together stamp is earned by taking all four birds on a scored flight. Use original artwork and audio; bundle all assets and tracking models for offline operation.

## Validation and delivery

- Test calibration, height mapping, posture rejection, looking down, partial visibility, jitter, stale samples, and jump takeoff/landing hysteresis and replay compatibility.
- Test collisions, obstacle reachability, scoring, interruption rules, pause behavior, and separation of mode records.
- Verify camera denial/revocation, background/foreground transitions, mode switching, and camera cleanup.
- Verify saved records and the equipped bird survive restart and database migrations.
- Visually inspect all screens on the connected phone, including readability from the required exercise position.
- Target 60 FPS rendering, at least 20 tracking updates/second, and p95 camera-to-control latency below 150 ms on the test phone. Measure these rather than assume them.
- Run Flutter analysis, automated tests, Android builds, and native-library compatibility checks, including 16 KB page sizes. [Android compatibility guidance](https://developer.android.com/guide/practices/page-sizes)

Deliver an installable Android APK, reproducible build instructions, and the shared iOS project scaffold. iOS camera implementation and device validation are a later milestone requiring macOS/Xcode. [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios)

## Assumptions and boundaries

- Game title: **Beakbound**. The Special Delivery bird artwork is the app icon and opening splash emblem; the menu uses only the name and tagline.
- Initial push-up mode uses standard push-ups; knee and other exercise variants come later.
- Body checks are confidence-based gameplay checks, not a guarantee of correct exercise form.
- Camera processing and saved session videos stay on-device. Record camera footage during flight with optional microphone audio and retain it only when the player chooses Save session. Store timestamped gameplay inputs, timing, seeded randomness and interruptions separately; reconstruct gameplay for replay. No uploads, accounts, ads or cloud services.
- Competition uses local records initially.
- Public Play Store submission, monetization, and iOS publication follow the polished offline milestone and broader device testing.


## Session replay

Results offer **Save session** independently of automatic score records.
Records → Saved sessions lists the full saved library and lets
players replay or delete a session without changing score totals. Reset local
progress also removes saved sessions and camera videos.

There is no Practice mode any more; every flight started from the app is
scored. Practice runs and sessions saved by earlier builds keep their
`practice` flag, so they stay out of records, goals and the passport, and they
still replay.

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
seed, rule parameters and interruption commands, and for a campaign level its
id and whole plan (see Campaign). Replay version 1 uses the current
FlightSimulation rules; future rule changes must preserve that version or provide
an explicit migration. Camera restarts after a pause create additional clips on
the same monotonic timeline. Failed camera capture permits gameplay-only saves.


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
