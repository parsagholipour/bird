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
Spitter King at 180 HP and Dusk Empress at 240 HP, with 30-HP progression steps
and caps of 240 / 300 / 360. This retains the earlier boss fight lengths with
the base weapon while supporting upgrades smaller than one old hit point.

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
panel. At 75%, 50% and 25% health, add cracks, missing edge chunks and deeper
fractures. Four health pips remain attached to the panel. On a lethal hit,
clear the opening's collision immediately and play a short debris animation
with one break/unlock cue. The surrounding walls remain solid; an intact panel
uses normal wall collision damage. Destruction gives no extra score. Pause and
replay preserve seeded placement, HP and debris timing. Reduced Motion retains
the static damage stages without sparks or debris. Rules 1–26 retain the
previous route with no breakable panels.

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
seconds after a boss leaves. A run needs at least 18 seconds before the next
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
Versions 1–14 retain their previous rules. Practice includes bosses; Cloud
Cruise and non-touch control modes do not. Reduced Motion removes decorative
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

Give the beetle boss a bespoke acid-brewer silhouette: a bulky copper shell,
glass reservoir, feed hose, goggles, claw arms, four fan wings and a battered
expedition hat. Do not use a crown or enlarge the small-enemy rig. Tip the
hat and unfold the wings during the 4.6-second entrance. Pump the reservoir
and swell the cheeks during charge, slosh the liquid on recoil, raise a claw
to summon helpers and open the shell vents in fury. Keep the mouth origin
fixed at local (-1.05r, 0). Tint the storm and projectiles green and introduce
the boss as the Brewer of the Swarm, with its name in HP and semantics.
The 3.8-second defeat loosens the body, throws its hat and releases an acid
pressure burst with arcing droplets and popping bubbles.
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

Use a bespoke coral moth with four velvet rose wings, pearl scalloped hems,
moon eyespots, a layered fur mantle, feathered antennae, three amber throat
glands and a crescent diadem. Tint pollen gold, the storm coral and the shield
pale blue. Give the shield a continuous collision-edge rim, woven silk loops,
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
- Use alternating high/low passages and spacing based on the calibrated cadence across every course. Save squat statistics separately from push-ups, jumps and touch; scored squats contribute to unlocks, daily goals and passport progress. Practice remains unscored.
- Append the persisted mode at index 3, preserving existing records. Replay version 10 adds squat journals with height and repetition inputs; previous journals retain their rules.
- Expose scored starts in the Play mode picker and unscored starts in the Practice mode picker, with grounded squat artwork, calibration feedback, a squat counter and a separate personal best.

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
