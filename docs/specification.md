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
Rings never use the Sprint button or its cooldown. When both sprints overlap,
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

### Pause and resume (rules version 35)

Scored flights can pause. The pause button (shown for every flight) opens the
“Take a breather.” panel with **Finish flight** and **Keep flying**. Taking a
break or backgrounding the app pauses a scored flight instead of ending it, and
a flight already paused stays paused through a background. Keep flying starts a
three-second resume countdown: tracking must be fresh, the
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
bats sent two at a time. His health, position, hover, fireballs and fury
threshold are unchanged. He adds no random draws: every choice follows from
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
(16 levels, 48 level stars) are playable. Chapters 3–5 are level data, shown
on the map and locked as "Coming soon". Endless Star Trail does not change.

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
1 at the goal, and `distanceToGo` gives the course left. The line reuses the
arrival pennants and FINISH label. Its checker ribbon is drawn bolder than a
timed route's (0.55 against 0.22), and the line stays in the world after a
knockout.

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
  most 100 characters and a mood (plain, happy, surprised, angry or sad).
- `CampaignStory.before(level)` is the scene ahead of a level: the prologue
  before 1-1, a route's opening before its first level, an arrival at the
  first level of each later region, and the scene at a boss's lair.
  `CampaignStory.after(chapter)` is the boss's last word. That makes 18
  scenes before levels and 5 after bosses.
- Each scene plays by itself once. `CampaignProgress.prologueDue` holds
  until the prologue is watched or 1-1 is cleared. `sceneBefore(level)` is
  due while the scene is unwatched and the level is not yet cleared.
  `sceneAfter(chapter)` is due while the chapter's postcard is due and the
  scene is unwatched.
- Watched scene ids are saved in the `preferences` table under
  `storyWatched`, joined by commas, so the schema stays at 5. Marking a scene
  twice changes nothing. Reset clears it with the other preferences.
- Every level has a `Delivery`: a cargo line of at most 42 characters for
  its card, and a thank-you of at most 48 characters with a signer of at
  most 24 for its result. A boss level's delivery is signed by its boss.

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
- **Home:** a mint Campaign key beside Play shows the level stars earned
  ("12 / 48"). Play keeps its pre-campaign place, filling the row it once
  shared with the retired Practice key.
  While the save loads or can't be read, the map's back key still leads
  Home.
- **Map:** one stop per region, with level nodes showing their stars. Tapping
  an open node opens the level card. Tapping a locked one wiggles it, and a
  note shows for 2.4 s: "Finish 1-2 to unlock" or "Beat Baron Bat to
  unlock". On a stop marked "Coming soon", the ribbon flutters instead (still
  under Reduced Motion). The map's keys, star total and stop titles hide
  while a scene, level card or postcard is open, and the map holds its frame
  under them.
- **Story scene:** the map shows what is due in this order: the prologue, a
  fallen boss's last word, that chapter's postcard, the scene before the
  open level, then the level's card. A scene shows its region behind (the
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
- **Finish:** crossing the line plays the `complete` fanfare, and the level
  result stages over the frozen finish, which leaves the flight's bird out
  (`BirdGame.hideBird`) for the result's own courier. A flight that ends any
  other way without a knockout, such as a stall, shows the result with 0
  stars.
- **Result:** the title reads "Delivered!", "Victory!" after a boss, or "Try
  again!". Three stars land at 34%, 46% and 58% of a 1.9 s entrance, each
  earned one with a chime, and the keys arm at 55%. Next shows when the next
  level is playable and opens `/campaign?level=<next>`. Retry flies the same
  level again straight into the countdown. A finished level shows its
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
still. The level readouts don't pulse. The result fades in over
0.5 s with every star in place.

### Fly Together co-op (rules version 42)

Two players fly one endless Tap & Fly Star Trail on one phone, their birds
roped together (**Roped**) or each on its own (**No rope**). Play's mode
picker offers **Fly Together** below the four solo modes, and a two-player
button in its header. Each player picks one of the four birds (both may pick
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
Solo flights under rules version 42 fly exactly as under version 41.

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
at height 0.38 and player 2 at 0.62. They bump at 0.09 as without the rope,
and a sprint surges only the sprinter ahead.

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
passed hearts and clear any remaining pickup when a boss arrives.

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
- Results with score, best score, mode-specific statistics, and retry. A fatal collision first plays a short cartoon knockout, then shows the same results on a game-over stage over the frozen flight (see Knockout and game-over stage).
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

- Working title: **Push-Up Bird**.
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
