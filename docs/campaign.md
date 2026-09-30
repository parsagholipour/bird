# Campaign

A Tap & Fly campaign that puts every region and every boss on a map, in
order. Endless Star Trail stays the high-score mode and does not change.

## Premise

The Sky Club post runs five mail routes around the world. It is the same post
that sends you out on a Sunrise delivery or a Moonlit mail run. One by one, the
routes have been taken over: Baron Bat roosts over the jungle, the Spitter King
brews on the ancient roads, the Dusk Empress has put the city lamps to sleep,
the Pirate Captain raids the harbours and the Ember Dragon has set the far sky
alight.

Your bird (whichever one is equipped) is the Club's newest courier, on its
first day. Fly each route leg by leg and beat its boss to get the mail moving
again.

The story is told between flights, never during one:

- **scenes** on the map, where the courier, Postmaster Bill and the bosses
  talk (see [Story](#story));
- a **delivery** on every level: what the courier carries on the level's
  card, and a thank-you on its result (see [Deliveries](#deliveries));
- one line from each boss on its entrance name card, under the epithet;
- one illustrated postcard after each chapter.

Every scene can be skipped, and a player who skips them all still sees the
progress: the map fills with stars, routes unlock and each chapter ends with
a postcard.

## The journey

The campaign is one trip around the world, one region at a time. The courier
starts in the Jungle, flies every level there, then travels on to the next
region:

Jungle → Brazil → Aztec → Ancient Rome → Egypt → Ancient Arabia → New York →
Paris → Mexico → Open Sea → Antarctica → Cyberpunk City → China

Every level flies a single region from start to finish: its sky, landmarks,
weather and obstacle materials. No level crosses into another region, and the
endless world tour is never used in the campaign.

Five chapters, one per boss in the existing boss order, group consecutive
regions. A chapter ends at its boss's lair, the last level of its last region.

| # | Route | Boss | Regions (levels) | New in this chapter |
| --- | --- | --- | --- | --- |
| 1 | The Canopy Route | Baron Bat | Jungle (3), Brazil (2), Aztec (3) | Flying, stars and streaks, Shoot, bats, Sprint; wind lifts, petal shutters |
| 2 | The Ancient Road | Spitter King | Ancient Rome (3), Egypt (2), Ancient Arabia (3) | Spitter beetles, stone panels (charged shots), rush paths (Wildfire, Skyfall); switchbacks, lantern drift |
| 3 | The Lamplight Line | Dusk Empress | New York (4), Paris (4) | Dusk moths, gales, Swarm rush; sun wheels, crystal steps |
| 4 | The Tide Route | Pirate Captain | Mexico (3), Open Sea (5) | Eruption rush, the sea, the tide |
| 5 | The Edge of the Map | Ember Dragon | Antarctica (2), Cyberpunk City (3), China (3) | Nothing new: shuffled rush paths, gales before rushes, the fastest starts |

Why these regions:

- Bats roost in the jungle and at the Aztec temple.
- The alchemist beetle brews where scarabs and alchemy come from.
- Moths are drawn to the lights of New York and Paris.
- The pirate sails the Mexican coast and the Open Sea.
- The dragon's lair is China under its red sun, at the far end of the map.

## The map

The map follows the same trip, one region at a time:

- **One stop per region.** Each of the 13 regions is its own stop, painted with
  that region's real scenery. It uses the same procedural renderer as the
  flight, as a still frame. The region's levels are numbered nodes along a
  dotted mail route across it, and each node shows the stars it has earned.
- **Moving on.** The route leaves the right edge of a region's last level and
  enters the next region. The map moves one stop at a time, by swipe or by the
  arrow keys at its edges, and opens on the region of the current level. A
  back key and the campaign's star total ("12 / 48") sit in the top corners.
- **Chapters and bosses.** A small banner over each region names its chapter
  route. The last node of a chapter is the boss's lair: a larger node with the
  boss's name. Beaten chapters show their postcard on the route.
- **The current level** is the first unlocked level not yet finished, or the
  last one played once everything is finished. The equipped bird perches on it
  with a gentle bob and a glow. Under Reduced Motion the bob and glow are still,
  and scrolling jumps instead of gliding.
- **Locked stops** show their scenery dimmed under cloud with a padlock. In
  this build, the regions of chapters 3–5 carry a "Coming soon" ribbon.
- **Tapping a level.** An open level opens its card over the map. A locked
  one wiggles, and a note says what opens it: "Finish 1-2 to unlock", "Beat
  Baron Bat to unlock" or "Coming soon".

## Levels

### How a level works

- A level is data. It has a fixed seed, its region, its length, the hazards
  it allows, its starting difficulty, where its set pieces go, its star marks,
  and whether it ends in a boss. There are no hand-placed obstacles.
- It starts like a Star Trail: three hearts, a shield, stars, streak
  multipliers and the star magnet. There are no heart pickups.
- **Length** is the number of seconds to the finish line for a bird that never
  sprints. The finish line is a fixed point on the route, so Sprint and ring
  sprints get you there sooner. Set pieces also sit at fixed points on the
  route ("Wildfire at 25 s" means 25 cruising seconds in).
- **"8 s after it"** counts from where the previous set piece ends: where a
  cruising bird escapes a rush path, or where a gale's wind drops. A gale's
  tailwind carries the bird about 20.4 route seconds in its 13 seconds, so
  "Wildfire 8 s after it" starts about 28 route seconds after the gale does.
- **The finish line** reuses the gold pennants and checker ribbon from
  `lib/game/arrival_art.dart`, with a FINISH label. Ordinary passages stop so
  the line is laid at least 0.45 past the last one, the same way a gale is
  laid. Crossing it completes the level.
- **Boss levels** fly a 30-second run-up with the chapter's hazards. Then the
  boss arrives with its normal cinematic. Once the defeated boss has flown
  off, the finish line is laid just past the right edge, for a short victory
  glide. From the boss's defeat to the line the bird coasts, as it does in
  the cinematic: taps, Shoot and Sprint rest (their buttons hide) and
  nothing can hurt it, so beating the boss always delivers.
- **Failing:** losing the last heart fails the level with the existing knockout
  and Bonk! stage (Splash! at sea). Retry goes straight back to the countdown.
- **Pausing** offers Map, Retry and Keep flying. Map and Retry save the
  attempt with no stars.
- **Same route every attempt:** retries lay the same passages, on every phone.
  Rush paths and gales draw from their own seeded random, so the course after
  them doesn't change with how the player flew them.

### Stars

A finished level earns 1 to 3 stars, depending on how many stars the bird
collected:

- ★ reach the finish line (for a boss level, beat the boss);
- ★★ collect at least the level's first mark;
- ★★★ collect at least the level's second mark.

A failed level earns nothing. The marks are 45% and 75% of the stars laid on
the route in chapter 1, and 50% and 80% from chapter 2, rounded to the nearest
five. A boss level counts the stars of its run-up.

The route counts below are the stars each route actually lays. Passages
arrive every 1.95 cruising seconds with three stars each, and a rush path lays
three on each of its six beats. A rush path costs 6–12 stars against the
passages it replaces, less at a faster pace. A gale lays none while it blows,
which costs 42–45 stars (about 14 passages). The marks are pinned in the level
data, and a test checks every level's marks against its route.

In flight, the score's place shows the stars collected on a short track, with
the two marks as notches. Each notch lights, with a chime, when the count
reaches it. A thin route line beside Pause shows how far the bird has flown
toward the finish flag. On a boss level the boss's crown marks its lair near
the end of the line: the run-up fills the line up to it, and the victory
glide flies the rest. The Bonk! stage's "route flown" reads the same line.
Both hide during a boss fight.

Each level keeps its best star rating, its best star count and its best score.
Only a finished flight can set a best, so a failed flight never shows its
stars as the level's best; every attempt still counts as a play. A flight is
rated when it is saved, so retuning a level's marks later never takes stars
away. The total number of level stars is stored so a future
upgrade shop can use it.

### Starting difficulty

A level's difficulty is written as the endless clock it starts from. From
there it ramps along the route exactly as endless ramps with time. For touch
flights on Star Trail:

| Start | Pace | Opening |
| --- | --- | --- |
| 0:00 | ×1.00 | 0.380 |
| 0:30 | ×1.08 | 0.377 |
| 1:00 | ×1.14 | 0.371 |
| 1:30 | ×1.20 | 0.368 |
| 2:00 | ×1.26 | 0.362 |
| 3:00 | ×1.34 | 0.353 |
| 4:00 | ×1.41 | 0.344 |

For comparison, an endless flight meets the Ember Dragon at around six or seven
minutes.

Enemy toughness follows the chapter, not bosses beaten in the flight. Small
enemies gain +5 HP per earlier chapter: bats have 10, 15, 20, 25 and 30 HP in
chapters 1–5. Each boss has the HP of its first endless encounter (120, 210,
240, 300 and 360) and fights its debut version:

- the Dusk Empress without her veil and with slow helpers;
- the Ember Dragon burning only half the sky, with no splitting fireballs.

### Hazards

- **Obstacle families** unlock by chapter. A level's first three passages are
  garden gates, as in endless.
- **Enemies** lead every other passage, as in endless, taking the level's
  lineup in turn. 1-3 shows its bats on every fourth passage only. 2-1 and 3-1
  alternate the new enemy with the others, so it leads every fourth passage.
  Boss helpers come from the same lineup.
- **Controls:** Shoot appears from 1-3 and Sprint from 1-5. Before that the
  buttons are hidden and the rules ignore the inputs.
- **Stone panels:** none in 2-1, 35% of eligible walls in 2-2 so the player
  meets several, and 25% from 2-3 on. Two never come in a row.

Intro levels show a one-line hint on their intro card, marked **NEW**.

### Chapter 1: The Canopy Route (Baron Bat)

Enemies: simple purple bat and cave bat. Toughness 0.

| Level | Name | Region | Length | Hazards | Start | Route ★ | ★★ / ★★★ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1-1 | First Delivery | Jungle | 60 s | Garden gates only, no enemies. *NEW: Tap to flap. Fly through the stars.* | 0:00 | 81 | 35 / 60 |
| 1-2 | Star Streak | Jungle | 60 s | Garden, wind lifts. *NEW: Chain stars for 3×; three perfect gates earn a magnet.* | 0:00 | 81 | 35 / 60 |
| 1-3 | Bat Patrol | Jungle | 65 s | + bats (every 4th passage). *NEW: Shoot. Tap Shoot to knock out bats.* | 0:10 | 87 | 40 / 65 |
| 1-4 | Carnival Skies | Brazil | 70 s | + petal shutters; bats every other passage | 0:20 | 96 | 45 / 70 |
| 1-5 | Express Post | Brazil | 70 s | Sprint. *NEW: Sprint smashes bats and surges ahead.* | 0:30 | 96 | 45 / 70 |
| 1-6 | Temple Steps | Aztec | 75 s | All of chapter 1 | 0:40 | 105 | 45 / 80 |
| 1-7 | Sunrise Roost | Aztec | 80 s | All of chapter 1 | 0:50 | 114 | 50 / 85 |
| 1-8 | **Baron Bat** | Aztec | 30 s + boss | All of chapter 1, then Baron Bat (120 HP) | 0:40 | 36 | 15 / 25 |

### Chapter 2: The Ancient Road (Spitter King)

Enemies: bats and spitter beetles (2-1: bat, beetle, cave bat, beetle; then
bat, beetle, cave bat). Toughness 1.

| Level | Name | Region | Length | Hazards | Start | Route ★ | ★★ / ★★★ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2-1 | Beetle Road | Ancient Rome | 65 s | Chapter 1 families, no stone panels; beetles every 4th passage. *NEW: Beetles spit seeds. Shoot the seeds down.* | 0:40 | 90 | 45 / 70 |
| 2-2 | Sealed Gates | Ancient Rome | 70 s | + stone panels (35%). *NEW: Hold Shoot for a big rock that breaks stone.* | 0:50 | 96 | 50 / 75 |
| 2-3 | Wildfire Run | Ancient Rome | 75 s | Rush path: Wildfire at 25 s. *NEW: Fly through the gold rings to outrun the fire!* | 0:45 | 93 | 45 / 75 |
| 2-4 | Nile Switchbacks | Egypt | 75 s | + switchbacks; panels, beetles | 1:00 | 105 | 55 / 85 |
| 2-5 | Skyfall | Egypt | 80 s | Rush path: Skyfall at 30 s. *NEW: Ring sprints smash meteors.* | 1:05 | 102 | 50 / 80 |
| 2-6 | Lantern Bazaar | Ancient Arabia | 80 s | + lantern drift | 1:15 | 114 | 55 / 90 |
| 2-7 | The Long Caravan | Ancient Arabia | 90 s | Wildfire at 25 s, Skyfall at 60 s | 1:30 | 111 | 55 / 90 |
| 2-8 | **Spitter King** | Ancient Arabia | 30 s + boss | All of chapter 2, then the Spitter King (210 HP) | 1:15 | 36 | 20 / 30 |

### Chapter 3: The Lamplight Line (Dusk Empress)

Enemies: bats, beetles and dusk moths (3-1: bat, moth, beetle, moth; then the
endless lineup). Toughness 2.

| Level | Name | Region | Length | Hazards | Start | Route ★ | ★★ / ★★★ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3-1 | Moth Light | New York | 70 s | Chapter 2 hazards, no rush; moths every 4th passage. *NEW: Moths fire fans of three. Slip between them.* | 1:15 | 96 | 50 / 75 |
| 3-2 | Wheels in the Rain | New York | 75 s | + sun wheels | 1:30 | 105 | 55 / 85 |
| 3-3 | Swarm Alley | New York | 80 s | Rush path: Swarm at 25 s. *NEW: Sprint through the flocks.* | 1:40 | 102 | 50 / 80 |
| 3-4 | Storm Warning | New York | 75 s | Gale at 20 s. *NEW: Gale! Watch the ! and take the open side.* | 1:30 | 63 | 30 / 50 |
| 3-5 | Crystal Rooftops | Paris | 80 s | + crystal steps | 1:50 | 114 | 55 / 90 |
| 3-6 | After the Gale | Paris | 85 s | Gale at 20 s, then Wildfire 8 s after it (the endless order) | 2:00 | 69 | 35 / 55 |
| 3-7 | Midnight Express | Paris | 90 s | Swarm at 20 s, gale at 55 s | 2:15 | 78 | 40 / 60 |
| 3-8 | **Dusk Empress** | Paris | 30 s + boss | All of chapter 3, then the Dusk Empress (240 HP, no veil) | 2:00 | 36 | 20 / 30 |

### Chapter 4: The Tide Route (Pirate Captain)

Every enemy. Toughness 3.

**The sea** is the Pirate Captain's water, laid across the bottom of the screen
for the whole level. It hurts like the course edge, and the bird splashes back
out as it does in his fight.

**The tide** uses his 10-second cycle: a bell, then a surge to 0.56. Passages
the bird reaches during a surge keep their openings above the high-water mark.

These need new rules that don't exist yet. They will be built with chapter 4.
Until then, the level data of 4-4 to 4-8 lays their routes without the sea.

| Level | Name | Region | Length | Hazards | Start | Route ★ | ★★ / ★★★ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4-1 | Harbour Lights | Mexico | 75 s | All families; Skyfall at 25 s | 2:15 | 99 | 50 / 80 |
| 4-2 | Volcano Pass | Mexico | 80 s | Rush path: Eruption at 25 s. *NEW: Hop over the lava plumes.* | 2:30 | 108 | 55 / 85 |
| 4-3 | Down the Coast | Mexico | 80 s | Gale at 30 s | 2:30 | 69 | 35 / 55 |
| 4-4 | Low Water | Open Sea | 75 s | The sea, calm. *NEW: Don't touch the water.* | 2:15 | 105 | 55 / 85 |
| 4-5 | Spring Tide | Open Sea | 80 s | The tide. *NEW: When the bell rings, fly high.* | 2:30 | 114 | 55 / 90 |
| 4-6 | Broadside Bay | Open Sea | 85 s | Tide; Swarm at 30 s | 2:45 | 114 | 55 / 90 |
| 4-7 | Stormy Crossing | Open Sea | 90 s | Tide; gale at 20 s, Eruption 8 s after it | 3:00 | 78 | 40 / 60 |
| 4-8 | **Pirate Captain** | Open Sea | 30 s + boss | Calm sea, then the Pirate Captain (300 HP) | 2:45 | 36 | 20 / 30 |

### Chapter 5: The Edge of the Map (Ember Dragon)

Every enemy. Toughness 4. From here, a rush path's kind is drawn from the
endless shuffled bag, so only the banner says which one is coming.

| Level | Name | Region | Length | Hazards | Start | Route ★ | ★★ / ★★★ |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 5-1 | Aurora Post | Antarctica | 80 s | Shuffled rush at 30 s. *Any rush can come now. Read the banner!* | 3:00 | 105 | 55 / 85 |
| 5-2 | Polar Night | Antarctica | 85 s | Gale at 20 s, shuffled rush 8 s after it | 3:15 | 72 | 35 / 60 |
| 5-3 | Neon Express | Cyberpunk City | 80 s | Two shuffled rushes (20 s, 50 s) | 3:30 | 99 | 50 / 80 |
| 5-4 | Data Storm | Cyberpunk City | 85 s | Gale at 25 s, shuffled rush 8 s after it | 3:45 | 72 | 35 / 60 |
| 5-5 | Skyline Sprint | Cyberpunk City | 90 s | Shuffled rush at 15 s, gale at 45 s, rush 8 s after it | 4:00 | 78 | 40 / 60 |
| 5-6 | Lantern Festival | China | 85 s | Two shuffled rushes (20 s, 55 s) | 4:00 | 111 | 55 / 90 |
| 5-7 | The Last Leg | China | 90 s | Gale at 15 s, rush 8 s after it, rush at 65 s | 4:30 | 78 | 40 / 60 |
| 5-8 | **Ember Dragon** | China | 30 s + boss | All of chapter 5, then the Ember Dragon (360 HP, half-sky breath, swarm flocks) | 4:00 | 36 | 20 / 30 |

## Story

### The cast

- **The courier** is the equipped bird, a rookie on day one. It speaks under
  its own name (Pip, Peaches, Minty or Orbit); the lines are the same for
  every bird.
- **Postmaster Bill** is the old pelican who runs the Sky Club post. His bill
  pouch was the club's first mailbag. He briefs the courier, explains what is
  new on a route and makes the jokes. The club rule is his: *every letter
  lands*.
- **The five bosses** each took a route for a small, silly reason of their
  own, and each ends the story with a job at the club.

### The arc

Five routes fall quiet on the courier's first morning. Each boss, once
beaten, admits the same thing: a warm letter with a flame seal told it the
route was its to take. The trail of seals leads to the edge of the map, where
the Ember Dragon lives past the end of every route. He wrote those four
letters to feel part of the mail, because nobody has ever sent him one. The
last delivery is the first letter ever addressed to him, signed by everyone,
the beaten bosses included.

| Boss | Why it took the route | How it ends |
| --- | --- | --- |
| Baron Bat | The morning post wakes him at sunrise | The canopy is delivered at dusk |
| Spitter King | He boils letters to brew an ink that never fades | He becomes the club's ink-maker (the brew turned to mint tea) |
| Dusk Empress | Her moths kept bumping into the lamps, so she put the lamps to bed | The lamps get shades, and she lights them each dusk |
| Pirate Captain | He wants the stamps, not the mail | The club sends him a stamp from every route |
| Ember Dragon | No route ever reached him, so no mail should reach anyone | Route six: he keeps the beacon at the edge of the map |

### Scenes

A scene is a short conversation over the map: three to nine lines, each at
most 100 characters. A tap anywhere finishes the line being written, and the
next tap moves on; **Skip** ends the scene.

- **The place** is behind: the scene's region, or the Sky Club's mail room
  at sunrise for the prologue (a round window onto the clouds, the five
  routes pinned on a map, pigeonholes of letters).
- **The cast** stands along the speech panel. The courier is on the left and
  Bill faces it. At a lair the boss looms on the right and Bill backs the
  courier up. Whoever is talking steps up onto its name tag in a pool of
  light; the others drop back, smaller and in shade.
- **Faces** follow each line's mood: plain, happy, surprised, angry or sad.
  Bill and the birds have a face for each. A boss is drawn by its own rig,
  in its fury look when angry. After its fall it has lost its headwear and
  looks sheepish: the Baron wears a plaster, the Empress's diadem has
  slipped, and the Captain, his ship gone, stands in a barrel.
- **The line** is written out in a cream speech panel with an airmail
  stripe, under a name tag in the speaker's colour. A row of pips shows how
  far the scene has come, and a cue appears when a tap will move on.
- **Captions** are nobody's voice. A place line sits on a dark title plate;
  a letter read aloud sits on a sheet of airmail paper with a wax seal.
- **Voices:** every line is spoken by its character, recorded with
  ElevenLabs Eleven v4, and the text writes itself out at the pace of the
  voice. The courier speaks in the equipped bird's own voice. The music ducks
  under a spoken line. The cast and how the lines were made are in
  [story-voices.md](story-voices.md); Settings → Character voices turns them
  off.

There are 23 scenes, and each plays by itself once:

| When | Scene | What happens |
| --- | --- | --- |
| The map's first visit | Prologue (before 1-1) | Bill welcomes the rookie: five routes went quiet overnight; start with one birthday card. It plays until it has been watched or 1-1 is finished. |
| A chapter's first level (2-1, 3-1, 4-1, 5-1) | The route's opening | Bill names the route's boss and the new trouble; the flame seals add up. |
| The first level of each later region (1-4, 1-6, 2-4, 2-6, 3-5, 4-4, 5-3, 5-6) | An arrival | Three to five lines on the new place and what to watch for. |
| A boss level (x-8) | At the lair | The courier hands over its letter, the boss says why it took the route and ends on its name-card line; Bill gives the fight's tip. |
| After a boss first falls | The boss's last word | The boss gives in, the flame seal comes up, and Bill offers it a way to stay. It plays on the map before the chapter's postcard. |

A level's scene plays before its card the first time the card opens, and
only before the level's first finish. After that, the card's **story key**
plays it again; on a beaten boss level the key plays the scene at the lair
and then the boss's last word. Watched scenes are saved, so a scene never
interrupts twice.

The lines are in `lib/domain/campaign_story.dart`. Text the game prints uses
curly quotes and a real ellipsis; `campaign_story_test.dart` checks that,
the line lengths and that every scene is a conversation.

### Deliveries

Every level carries something for somebody. A boss level carries the letter
that tells its boss to go.

- **On the level card**, a parcel tag is tied over the region picture: a
  SPECIAL DELIVERY heading and the cargo in handwriting. A boss's tag is
  printed in the boss's colour.
- **On the result of a finished level**, an air-mail note drops in beside
  the courier as the last star lands: the thank-you in quotes, signed, with a
  heart seal. A beaten boss grumbles its thanks on paper framed in its stamp
  colour and sealed with its lost headwear. The thank-you is read out in
  the sender's voice as the note lands. A flight that fell short delivers
  nothing, so it shows no note.

| Level | Cargo | Thank-you |
| --- | --- | --- |
| 1-1 First Delivery | A birthday card for the toucan twins | “Best birthday ever! We squawked for an hour.” — The toucan twins |
| 1-2 Star Streak | Star charts for the sloth stargazer | “No rush, I said. You rushed. Thank you.” — The sloth stargazer |
| 1-3 Bat Patrol | Night-lights for the firefly nursery | “Now even the shy ones are glowing.” — The firefly nursery |
| 1-4 Carnival Skies | Feather boas for the carnival parade | “The parade starts now. You made it!” — The samba macaws |
| 1-5 Express Post | A rush invitation for the drum captain | “So fast my hat blew off. Marvellous!” — The drum captain |
| 1-6 Temple Steps | Cocoa beans for the temple cooks | “Hot chocolate for the whole temple!” — The temple cooks |
| 1-7 Sunrise Roost | A sundial for the dawn keeper | “Sunrise is back on schedule.” — The dawn keeper |
| 1-8 Baron Bat | A final notice for Baron Bat | “Fine. FINE. Take your noisy route.” — Baron Bat |
| 2-1 Beetle Road | Laurel wreaths for the chariot racers | “We shall wear them at every race!” — The chariot racers |
| 2-2 Sealed Gates | A new chisel for the statue carver | “At last I can finish his nose.” — The statue carver |
| 2-3 Wildfire Run | Water buckets for the fire brigade | “Just in time. Truly, JUST in time.” — The fire brigade |
| 2-4 Nile Switchbacks | A book of new riddles for the Sphinx | “Finally, some fresh material.” — The Sphinx |
| 2-5 Skyfall | A telescope for the pyramid astronomer | “Now I can see the meteors coming!” — The pyramid astronomer |
| 2-6 Lantern Bazaar | Lamp oil for the lantern sellers | “The bazaar glows again. A thousand thanks!” — The lantern sellers |
| 2-7 The Long Caravan | Water flasks for the long caravan | “Forty camels. Forty thank-yous.” — The caravan leader |
| 2-8 Spitter King | A stop-brewing order for the Spitter King | “Bah. It was very nearly ink.” — Spitter King |
| 3-1 Moth Light | Light bulbs for the theatre marquee | “The show goes on! Front row for you.” — The stage manager |
| 3-2 Wheels in the Rain | Umbrellas for the newsstand pigeons | “Dry feathers at last. You’re a hero.” — The newsstand pigeons |
| 3-3 Swarm Alley | Hot pretzels for the night-shift cabbies | “Still warm! How fast do you fly?” — The night cabbies |
| 3-4 Storm Warning | A weather vane for the tallest tower | “It spins! It points! It’s perfect.” — The tower keeper |
| 3-5 Crystal Rooftops | Croissants for the rooftop painters | “Magnifique. Not one crumb lost.” — The rooftop painters |
| 3-6 After the Gale | Sheet music for the accordion player | “The pages blew in right on the beat.” — The accordion player |
| 3-7 Midnight Express | A midnight love letter for the baker | “I said yes! I mean… thank you.” — The baker |
| 3-8 Dusk Empress | A wake-up call for the Dusk Empress | “Very well. Let them have their lamps.” — Dusk Empress |
| 4-1 Harbour Lights | A new lens for the lighthouse keeper | “Now the ships can find us again.” — The lighthouse keeper |
| 4-2 Volcano Pass | Oven mitts for the volcano baker | “My lava cakes thank you.” — The volcano baker |
| 4-3 Down the Coast | Kite string for the beach festival | “Best wind we’ve had all year!” — The kite flyers |
| 4-4 Low Water | A reply for the island hermit | “Forty years I waited for a reply!” — The island hermit |
| 4-5 Spring Tide | A tide table for the ferry crew | “High water at noon. Good to know!” — The ferry crew |
| 4-6 Broadside Bay | Fish biscuits for the gull colony | “Dinner for nine hundred. Thanks!” — The gull colony |
| 4-7 Stormy Crossing | Dry socks for the storm-watch sailors | “Warm toes at last. Bless the post.” — The storm watch |
| 4-8 Pirate Captain | A return-the-mail order for the Captain | “Arr. Ye fly well, for a postie.” — Pirate Captain |
| 5-1 Aurora Post | Woolly hats for the penguin choir | “Warm heads, high notes. Thank you!” — The penguin choir |
| 5-2 Polar Night | Hot cocoa for the polar station | “First warm drink since winter began.” — The polar station |
| 5-3 Neon Express | Spare fuses for the noodle bar sign | “OPEN again. Noodles on the house!” — The noodle chef |
| 5-4 Data Storm | A paper letter for a curious robot | “PAPER. MARVELLOUS. I SHALL FRAME IT.” — Unit 7 |
| 5-5 Skyline Sprint | Race tickets for the rooftop runners | “You beat our lap record delivering them.” — The rooftop runners |
| 5-6 Lantern Festival | Paper lanterns for the festival | “A thousand lights, thanks to you.” — The lantern makers |
| 5-7 The Last Leg | Mountain tea for the monastery | “Sit. Rest. The last climb is steep.” — The mountain monks |
| 5-8 Ember Dragon | The first letter ever sent to the Dragon | “I have read it nine times already.” — Ember Dragon |

## Boss lines

Each line appears on the boss's entrance name card, in quotes under the
epithet, and fades with the card. It is also the boss's last word in the
scene at its lair, so the flight picks up where the scene left off. The Pirate Captain's sits on his parchment
scroll, under his title ribbon. The Ember Dragon has no card of his own, so
his line goes on the same card as the first three bosses. It shows in
campaign levels only, so endless looks exactly as before.

| Boss | Line |
| --- | --- |
| Baron Bat | “This route is my roost now, little courier!” |
| Spitter King | “Every letter on my road goes in the brew!” |
| Dusk Empress | “Hush now. The night mail is sleeping.” |
| Pirate Captain | “Arr! Every mailbag on these waves be mine!” |
| Ember Dragon | “The sky is mine. Your letters are kindling.” |

## Postcards

After a chapter's boss is beaten for the first time, the level result says a
postcard is waiting. The map then plays the boss's last scene and shows the
postcard over everything else until Continue, which marks it seen. It shows the boss's home region, the equipped
bird and a postage stamp of the headwear the boss lost when it was defeated.
The postcard stays on the route beside the beaten boss's lair; tap it to see
it again. The words come from the level data (`lib/domain/campaign.dart`).

**1. The Canopy Route**
> Dear courier, letters are landing in the treetops again! The toucans say
> thank you (very loudly). Baron Bat's crown is on our mantelpiece.
> P.S. The ancient road smells like something is bubbling.

**2. The Ancient Road**
> Dear courier, the caravans are rolling and the only thing brewing is mint
> tea. We kept the King's flask crown as a vase.
> P.S. The city lamps went dark last night. Bring a light.

**3. The Lamplight Line**
> Dear courier, the lamps are lit and the night mail is wide awake! Paris sends
> a croissant. New York sends a pretzel.
> P.S. The harbour bells have stopped ringing.

**4. The Tide Route**
> Dear courier, the harbour bells ring for letters again, not cannons. The
> parrot stayed. He says hello.
> P.S. They say the sky at the edge of the map is on fire.

**5. The Edge of the Map**
> Dear courier, the sky is clear from pole to pole and every route is running.
> The whole Sky Club is proud of you.
> P.S. The endless sky is still out there, whenever you are.

## Progression and saving

- **Unlocking:** the first level is open from the start. Finishing a level (1
  star or more) unlocks the next one. Beating a boss unlocks the next chapter.
  Any unlocked level can be replayed.
- **In this build**, chapters 1 and 2 (six regions, 16 levels, 48 stars) are
  playable. The seven regions of chapters 3–5 sit on the map, locked, as
  "Coming soon".
- **Save data:** schema 5 adds a `level_progress` table (level id, best stars
  0–3, best stars collected, best score, plays, first cleared at, last played
  at, postcard seen) and a nullable `runs.level` column. Existing rows keep
  `level` empty, so existing progress survives. Saving a campaign flight
  stores the run and folds it into its level's row in one transaction. Reset
  local progress also clears the campaign.
- **Watched scenes** are saved as one preference (`storyWatched`, the scene
  ids joined by commas), so the story needs no schema change. Reset local
  progress clears it with the other preferences, and the story starts over.

### How campaign flights count

Campaign flights are scored Tap & Fly flights saved with their level id.

| Where | Counts? |
| --- | --- |
| Endless records, the Home best pill, the personal-best target, Records and its recent flights | Never |
| Star Trail flight wings | No; the level's stars take their place |
| Home's first-time greeting | Yes; a level counts as a first flight |
| Daily adventure: flights, gates, stars, streak, perfect passes | Yes |
| Daily adventure: "The whole journey" (60 s in one Star Trail) | No |
| Passport: First wings, On the dot, Star chaser, Constellation, Flock together | Yes |
| Passport: Sky captain, Trailblazer, Both wings | No |
| Saved sessions and replay highlights | Yes, named after the level |

Wording changes:

- The daily star goal says "across today's flights" instead of "Star Trails".
- Star chaser drops "in Star Trail".

## How it is built

- **`FlightPlan` (lib/domain):** holds every schedule knob that lives in
  `FlightSimulation` today: boss timing, the first rush and rushes after
  bosses, the gale after the Dusk Empress, the difficulty clock and pace,
  stone panels after boss 2, enemy toughness, obstacle families and the enemy
  lineup. The default endless plan reproduces those values exactly. A campaign
  level supplies its own plan, which also adds controls, rush kinds, the finish
  line and the level's region. The rules ask the plan instead of checking for
  a campaign.
- **`LevelPlan` and `LevelRoute` (lib/domain/level_plan.dart):** a level's
  data, and the route laid from it before the flight starts: every passage,
  set piece and the goal at a fixed place. Schedules follow a route clock
  that runs with the course, so a sprint reaches the same passages sooner.
  The levels themselves are in `lib/domain/campaign.dart`, and saved progress
  in `lib/domain/campaign_progress.dart`.
- **Regions:** a campaign flight holds its one region for the whole level. The
  backdrop, gates, gales and `bird_game` pass the flight's region to
  `WorldTour.at(seconds, held:)`, which then never crosses. Endless keeps the
  tour. For long holds, the skyline bands repeat and landmarks come back every
  few minutes. The map paints each stop with the same region renderer, as a
  still.
- **Rules version 41** adds campaign plans; endless under 41 behaves exactly as
  40 does. The replay tape saves the level id and the level's full plan, after
  `weaponDamage`, so a retuned level still replays the way it was flown.
- **Story scenes** (`lib/ui/story_scene.dart` and the `story_*.dart`
  files beside it): the player, the stage and its cast, the speech panel,
  the mail room, Postmaster Bill and the bosses' story poses. Every
  character is drawn in code, like the rest of the game; the bosses reuse
  their flight rigs. `lib/ui/delivery_art.dart` holds the parcel tag and the
  thank-you note.
- **Screens:**
  - Home: a mint **Campaign** key beside Play, with a map and the level stars
    earned ("12 / 48"). Play and Practice keep their size and place;
  - the map (`/campaign`);
  - the level card, over the map (whose chapter ribbon captions it): region
    picture, level number and name (a boss band with the boss's crown on boss
    levels), length, the delivery's cargo, the NEW or TIP hint (or the
    controls it offers), the three goals ticked where earned, the best star
    count, Fly, and the story key on a level that has a scene;
  - a story scene, over the map (`lib/ui/story_scene.dart`);
  - the flight (`/play/touch?level=1-3`), which counts straight in;
  - the result: "Delivered!" ("Victory!" after a boss), three stars popping
    in, the delivery's thank-you, stars collected and score, a NEW BEST
    ribbon, the goals met, what the save unlocked, and Map / Retry / Save
    session / Next. Next opens the map
    on the next level's card, and is hidden when that level isn't playable;
  - the postcard, over the map.

  A knockout plays the existing knockout and Bonk! stage, with the stars
  against the next mark, how far along the route the bird got (or the boss's
  health left), and Map / Save session / Retry. A flight that stops short
  without a knockout shows the result with no stars. Retry goes straight to
  the countdown; the card only opens from the map. The map and postcard art
  had their own design pass, and so did the story scenes, the parcel tag and
  the thank-you note. Renders go to `build/visual-review/campaign/`.
- **Reduced Motion:** the map holds still and jumps between stops, cards
  appear without sliding, a scene's lines appear whole and its speakers hold
  still, the finish pennants don't flutter, and the result shows its stars
  and thank-you already in place.
