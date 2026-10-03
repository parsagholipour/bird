# Validation ledger

## 2026-10-03 The faster Neferhoo (rules 55)

Owner's ask, after beating the tougher Neferhoo (rules 52) on a phone in
about 49 s of fight: "It is still stall for too long. It should call the
bats more and from the beginning. It needs 100 more HP. It needs to shoot
more." From rules version 55 (`fasterNeferhooRulesVersion`,
`SkyBoss.fasterNeferhoo`, `NeferhooBeats.faster`), 2-6 only:

- 700 HP (600 at 52 to 54; rules 53's growth is endless only).
- A 10.5 s cycle (12 before): first mail call at 0.6 with its bats from the
  warm-up on (pair, trio, fury's four); the ankh at 5.4/6.8 as before; a
  second call (3 letters, express 5, no bats) on the bird at 9.6, after the
  ankh's return pass; in a warm-up cycle a wave of two bats at 5.9 instead.
- A returned letter deals 18 (25 before), so twice the letters a cycle make
  a practised fight longer, not shorter.
- Longest open sky at 2.2 (nothing crossing the bird): warm-up 11.2 -> 4.4 s,
  full 6.1 -> 3.1 s, fury 5.7 -> 2.7 s. Hazards a minute 15/35/60 -> 41/66/108.
- Fairness (`neferhoo_faster_fairness_test`): every faster scenario (each
  call with its bats by stage, the warm-up cycle with its wave on any lane,
  the full/fury cycle with the second call on any lane, the join of the
  second call and the next call) 100% viable at 5 taps/s at 640 and 792; at
  1.5 taps/s 100% at 792, the .84 lane at 640 99.4% (fury 98.6%, as at 52).
  Bats are past the bird >= 2.0 s before an ankh can reach it and >= 0.88 s
  before the next lock.
- Pilots (32 seeds, 2.2, median fight / KO, rules 54 -> 55): expert 62 s ->
  75 s, 0% both (hits .56 -> 1.59); careful family 111 -> 158 s, 0% -> 0%;
  careful kid 219 -> 347 s, 0% -> 0% (30/32 won inside 8 min); model family
  111 -> 139 s, 0% -> 41%; model kid 228 s/13% -> 100% KO; slow dodge-only
  .27 -> .67 hits/min, 0% -> 6%. The model policy's two holes (crossing a
  band about to be swept, bobbing into an edge) are what the busier sky
  punishes.
- Built as 55 in `egypt-int/v3` from main at rules 54; `frozen_rules54`
  recorded first (2-6 at 54 replays byte for byte). Report:
  `egypt-int/reports/32-v3-landing.md`.

## 2026-10-03 King Coo's quick fury restart (rules 54)

Owner's ask: "The last time King coo breaks down and waits, it takes to long
for him to start shooting. He should restart faster." Read as his last
stage-up, into fury: most damage lands in his puff window (x2), so the fury
usually comes there, often with a pop (he sags, dizzy: the "break down"),
and nothing else of his fixed 14 s cycle was left after it. His first fury
crumb ring locked only at the next cycle's 0.6 s. From rules version 54
(`cooRestartRulesVersion`, `supportsCooRestart`, `SkyBoss.quickRestart`)
the campaign King Coo ends that cycle at the first step when nothing of it
is left (roar over; chest settled at 10.4, or `KingCoo.popRecovery` 2.6 s
after a pop; crumbs gone; every squadron pigeon a pigeon's reach past the
bird), and his first fury cycle begins there. Once a fight; later fury
cycles keep 14 s.

- Built as 54 on a copy of the rules 53 tree (`../growth-ws`, itself the
  tougher Neferhoo's rehearsed 52 plus growing endless bosses) in
  `../coo-restart-ws`, because those two were about to land on main.
- His cycle clock goes through `SkyBoss.cooClockAt` / `cooCycleStart`
  (rules, stragglers, `KingCooPose`, the test bots' danger maps). The jump
  lands on a cycle boundary from inside the quiet tail, so no counter
  (puffs, whistles, rings, straggler returns) moves, and the pose is at rest
  on both sides (every cycle-driven channel ends by 10.4 s or 2.6 s after a
  pop).
- Measured (`flyNewYork('3-2')`, width 2.2, phases 0, 13, 26 and 39, at 53
  and 54; first fury ring after the stage-up):
  - fury with a pop at cycle 8.87 (sharp): 5.73 s at 53, 3.19 s at 54;
  - fury at the puff without a pop, squadron out (cycle 7.67, casual):
    6.93 s, now 4.56 s (the squadron crosses until about 11.5 s; the ring
    locks 0.6 s after it has passed);
  - fury early in a cycle (0.07 to 1.13 s): its first ring was 0.5 to 2 s
    away anyway; now that cycle's tail is cut instead (restart 10.1 to 11.2
    s after the fury);
  - fury at 13.27 s, after the tail: no restart (the next cycle is due).
  - Fight lengths barely move (sharp 92.6 to 93.6 s; average 168.1 to
    169.5 s; casual 224.7 to 224.7, 233.0 to 240.1, 246.8 to 245.4 s) and
    the pilots' fight hits stay in the same range (1 to 4).
- `test/king_coo_restart_test.dart`: 53 against 54 for a pop that brings his
  fury (ring 3.2 s after the pop at 54, the next cycle's 0.6 s at 53), the
  squadron case (restart on the first step after the last pigeon has passed
  the bird, no ring before it), counters and the pose's cycle across the
  restart, a fury early in a cycle, once a fight, determinism, and
  `KingCoo.popRecovery` = the art's `popDizzy + popRecover`.
- Version pins moved from 53 to 54 in `rules43_version_test`,
  `rules50_version_test`, `fiercer_gargoyle_test`, `level_feathers_test`,
  `boss_stages_test`, `all_rings_bonus_test`, `neferhoo_tougher_rules_test`
  and `boss_growth_test`.
- Frozen fixtures were not re-recorded. `frozen_rules49_test` now also runs
  at 53, and from 54 it skips a flight in which King Coo restarted
  (`FrozenResult.cooRestarts`, from the new `FlightSimulation.cooRestarts`
  counter), as it skips all-rings flights from 51: the 3-2 bot and pilot
  flights and the 3-2 tape that reach his fury. Every other frozen flight
  matches at 54.
- Open: never phone-played; no new audio or voice line.

## 2026-10-03 Growing endless bosses (rules 53)

Owner's ask: "For the boss's second encounter we increase the HP currently
but for the 3rd+ encounters it's the same HP, we wanna have a rate of
increase for the next encounters, that works for nth encounter and increases
the HP of the boss by that rate." `SkyBoss.healthFor` climbs 30 per encounter
number, capped after four, so every endless kind peaked at its second
meeting. From rules version 53 (`bossGrowthRulesVersion`,
`supportsBossGrowth`) each meeting after the second has
`SkyBoss.growthPercent` = 25 % more health than the one before, rounded to
10 with integer math (replays match on every platform). The rate was not
given; 25 % is a default, one constant to tune. Endless and co-op only;
campaign bosses are staged and never read `healthFor`, and duels meet no
boss.

- It took 53 because the tougher Neferhoo, rehearsed as 52 in
  `egypt-int/rehearsal2`, was about to land; this change was built on a copy
  of that tree (`../growth-ws`) and applied on top after it landed.
- `test/boss_growth_test.dart`: the health table for meetings 1 to 6 of
  every endless kind (pre-53 values held at the second meeting), encounters
  1 to 20 met through the simulation at 52 and 53, and a scripted endless
  flight at widths 1.6 and 2.2 that matches 52 state for state every second
  until encounter 11, whose upgraded Baron has 600 health instead of 480.
- Version pins moved from 52 to 53 in `rules43_version_test`,
  `rules50_version_test`, `fiercer_gargoyle_test`, `level_feathers_test`,
  `boss_stages_test`, `all_rings_bonus_test` and
  `neferhoo_tougher_rules_test`; `endless_plan_baseline_test`'s 48 test now
  asks for at least 52. No fixture was re-recorded: the frozen endless flights
  end at 8 bosses, before any third meeting.

## 2026-10-03 The tougher Neferhoo landed on the main tree (rules 52)

The tougher Neferhoo (next entry) was built as rules 51 against main's 50. The
all-rings bonus took 51 in the main tree first, so it landed as 52: the
constant `tougherNeferhooRulesVersion`, the version pins and the docs moved,
and nothing else (every rule reads the constant).

- **Frozen first**: `test/frozen_rules51_test.dart` (fixture and four tapes)
  was recorded on an untouched copy of the main tree at 51 before anything
  was merged. It flies `frozen_rules50`'s flights at 51: 2-6 lays no rush
  path, so 51 flies it exactly as 50 did, and saved 51 tapes reload, replay
  and re-record byte for byte under the 52 code. At 52, 2-6's data and every
  run-up are unchanged. `endless_plan_baseline` flies 52 against 51.
- **The real app** (`PushUpBirdApp`, a fresh save at 2-6's door, the real
  `BirdGame` and Flame loop, R1's family pilot on the play controller's keys,
  nothing topped up): 2-6 at 52 on the 792 × 360 reference phone, seed 1,
  fight 113.0 s (the same pilot fought the 300-health rules 51 fight in 50.6
  s), 10 mail calls, 21 mummy bats flown in, 2 shot down, 1 hurt, level
  completed with all 36 stars; seed 3, fight 121.2 s. A 640 × 360 screen
  shows the same reference sky, letterboxed by `ScreenFrame` at 0.81 scale,
  so it flies exactly the same flight; the bats stay legible at that scale.
  (The 640 px rows of the fairness search and the pilots below are a sky
  1.78 heights wide, which the app does not show while `ScreenFrame` frames
  every screen as the reference phone; at 2.2 every lane stays fully viable
  for a slow tapper too.)
- **Hazards in the real flights**: at every mail call's lock no mummy bat was
  left in the sky; while an ankh flew within .5 of the bird's column no bat
  was within .25 of it (1025 and 1178 such frames); no bat flew among its
  call's letters (closest .145 screen heights). On the 2.2 sky a fury trio's
  last bat passes the bird just as the ankh's lanes lock (5.4 s into the
  cycle); the ankh reaches the bird about 2.3 s after it has gone.
- **Stall check**: Neferhoo's caches and `MummyBatArt.prewarm` build in the
  frame that mounts the game, during the countdown (300 to 440 ms on the
  test host, 300 ms without the bats; a countdown frame cannot end a
  flight). Over every playing frame of three cold-cache flights (fresh
  isolates), the worst was 43 to 116 ms, always in the run-up; his arrival,
  his first mail call, the first bat flying in, the first bat downed, the
  stage-ups and his defeat each took under 70 ms (mostly under 25). One run
  had a burst of up to 301 ms at a moment when other work loaded the host;
  the same frames took 3.5 to 12.6 ms in the other two runs of that flight.
  Untouched main's worst playing frame on the same flight was 36.5 ms.

## 2026-10-03 A tougher Neferhoo (rules 52): 600 health, faster letters, mummy bats

The owner played 2-6 on a phone: "It's so easy. Double the health. Give it
some helpers, small flying enemies. The letter particles move faster." He
picked mummy bats for the helpers. Rules version 52
(`tougherNeferhooRulesVersion`, see the specification) makes 2-6's guardian
tougher and leaves everything else alone. (It was built and measured as 51;
the all-rings bonus took 51 in the main tree first, so it landed as 52. The
numbers below are the same rules under either number.)

- **Frozen first**: `test/frozen_rules50_test.dart` (+ `frozen_rules50_flights`,
  fixture and four tapes) was recorded from an untouched copy of the landed
  tree (`egypt-int/base2`, rules 50) before any change: 2-6's data, the shared
  bot through the whole level at 640, 800, 864 px and 2.2 (both weapons,
  mortal and sloppy), R1's pilots (family, first-timer, expert, learner, the
  slow dodge-only player), and tapes of the bot, a family pilot at 640 and a
  first-timer at 2.2. After the change all of it flies at 50 exactly as
  recorded, the 50 tapes replay and re-record byte for byte under the 52
  code, and at 52 2-6's data, every run-up and the tapes' inputs up to his
  arrival are unchanged. `test/frozen_rules51_test.dart` (fixture and four
  tapes) pins the same flights at 51 (the all-rings bonus), recorded from an
  untouched copy of the main tree at 51 before the merge: they fly at 51
  exactly as at 50 and as recorded. `frozen_rules49` (endless, co-op, duel
  and chapters 1 to 3 at 49 and the current version), `frozen_rules45`,
  `frozen_rules41`, `frozen_ny43` and `frozen_egypt50` stay as they were;
  `endless_plan_baseline` flies 52 against 51 through the returning Baron.
- **Gating** (`neferhoo_tougher_rules_test`): only a 2-6 boss at 52 is tougher;
  no endless or duel plan names a mummy bat for 200 boss numbers at any
  version from 19 to 52, long endless, roped, free and duel flights at 52 meet
  none, no level's lineup holds one and a plan naming one is refused; a 2-6
  fight at 50 (or 51) meets no bat, deals letters at .45 / .52 and has 300
  health.
- **Rules** (same file, real simulation): letters .63 / .728 and returns 1.4
  times sooner (landing once for 25); the warm-up sends no bats, the full
  fight a pair, fury a trio, latched at the lock with exact launch times, in
  from the right edge at their pace, level in the lane by the bird; behind
  every letter of their call and never near the bird's column while an ankh
  in flight is within .5 of it (640, 792, 864 px, four cycles each); touch
  hurts, one rock downs one (+3, `enemyHit` of its kind), a sprint rams one;
  the "MUMMY BATS" hint; his defeat clears them and none flies in after it;
  a replay with bats in flight seeks backward and forward to the same fight
  as a fresh replay.
- **Fairness** (`neferhoo_tougher_fairness_test`, the design's viability
  search, dodging only; `--dart-define=NEFERHOO_FAIR_ALL=true` for every lane,
  198 scenarios): at five taps a second every state the edges let live has a
  way through the faster warm-up stream, the stream with its pair and the
  express post with its trio at lanes .16 to .84, and the whole cycle (call,
  bats, then the ankh or two ankhs on .25, .5 or .75), at 640, 792 and 864
  px. Reaction budgets (the stream alone gives the same: the bats take none
  of it): 640 px 1.8 s (1.0 at the ceiling lane), express 1.5-1.6 (1.0); 792
  2.3-2.4 (1.7), 2.1 (1.4); 864 2.8 (1.9), 2.4-2.5 (1.9). Rules 50 gave 2.0
  (1.3) and 1.9 (1.1) at 640. The last bat leaves the bird's reach at least
  2.31 s before an ankh can reach it, the first enters it after the call's
  last letter has left (by at least .03 s), and a bat is seen for at least
  1.81 s. A slow tapper (1.5 taps a second): the bats change no verdict; the
  faster letters leave every lane fully viable at 792 and 864 px and in the
  upper half at 640, where a lane in the lower third (.78) leaves 96.4% of
  the starts near the lock a way out by flying alone (express post 93.0%;
  .84: 99.4% / 98.6%; rules 50: 99.8% to 100%). Sending the letters back is
  open from anywhere they can hurt (catch band = hurt band).
- **Pilots** (`neferhoo_tougher_pilot_test`, R1's design-model bots, now
  aware of the bats; 100 mortal fights each, combat seconds median (p10-p90);
  `--dart-define=NEFERHOO_PILOT_SEEDS=100`):

  | | 640 px, rules 50 | 640 px, rules 52 | 792 (2.2), rules 50 | 792 (2.2), rules 52 |
  | --- | --- | --- | --- | --- |
  | expert | 27 (27-38), 0.18 hits | 73 (62-84), 1.02 hits | 27 (27-29), 0.14 | 62 (59-70), 0.56 |
  | family | 59 (39-75), KO 0%, 0.68 | 134 (113-161), KO 2%, 1.85 | 48 (29-57), 0%, 0.40 | 110 (86-132), 1%, 1.55 |
  | first-timer | 119 (86-146), KO 0%, 1.03 | 251 (195-307), KO 2%, 1.79 | 103 (75-138), 0%, 1.36 | 219 (181-265), 9%, 2.76 |
  | slow shooter (1.5 taps) | 110 (85-136), 0%, 0.59 | 231 (199-277), 0%, 1.18 | 96 (63-121), 0%, 0.81 | 206 (170-266), 2%, 2.09 |
  | slow, dodge-only (hits a min, KO in 2 min of the full fight) | 0.86, 2% | 0.92, 3% | 0.43, 0% | 0.24, 0% |

  Every fight is 2.1 to 2.7 times as long and takes more hits; a first-timer
  now loses one fight in eleven on main's 2.2 sky (one in fifty at 640). The
  tuning that got there: bats leaving his hand gave first-timers too little
  warning at 640 (68% knocked out); bats from the right edge at the scroll
  speed crossed the bird during the ankh's telegraph on wide screens (28-42%);
  the shipped train (in from the edge, timed to trail the last letter, at a
  set pace a little under the letters') keeps the call one hazard and is
  gone before the ankh.
- **Art hooks**: every exhaustive `EnemyKind` switch has a `mummyBat` arm;
  the live and defeat arms call `MummyBatArt.paint`, prewarmed with his art
  during 2-6's countdown. The mail lane's telegraph now ends at the letters'
  real speed and stays for the call's bats (`neferhoo_fight_art_test`, rules
  50 and 52).
- **The mummy bat's art** (`lib/game/enemy_designs/mummy_bat.dart`,
  `MummyBatArt`, the simple bat's painter signature): a tiny bat in the simple
  bat's family (body, ears, wing key poses, flap rhythm, look, Reduced Motion
  glide) wound in Neferhoo's moon-linen with plum-grey seams, bound ears,
  wrapped wrist cuffs, glowing turquoise eyes under linen lids, a lapis
  postage stamp with a red postmark on the belly, dusty-plum wings and one
  loose bandage end trailing to a glowing turquoise tip. Envelope over 150
  frames x -1.78..1.78, y -1.15..1.16 r (limits 1.9 / 1.2); 37 draw calls a
  bat (simple bat 39), no clip, layer or blur; `MummyBatArt.prewarm` records
  its poses during the countdown (`mummy_bat_art_test`; review sheets
  `mummy_bat_review_test`).

## 2026-10-03 All-rings bonus (rules 51)

Owner's request: "In the rings part, when we get all the rings, we get +2
seconds plus boost." Collecting every ring of a rush path now adds
`Rush.allRingsBonus` (2 s) to the last ring sprint, at full 3× boost
(`FlightSimulation.allRingsRulesVersion` = 51, `supportsAllRingsBonus`,
`FlightEventKind.allRings`, `allRingsBonuses` counter). It applies to every
touch Star Trail flight with rush paths: endless, co-op, duel and campaign.

- `test/all_rings_bonus_test.dart`: the bonus comes with the sixth ring and
  holds peak boost until the last half second of the longer sprint, a missed
  ring (first, middle or last) earns nothing, and rules 50 flies a perfect run
  frame for frame as before until the bonus.
- Frozen fixtures were not re-recorded. `frozen_rules41` and `frozen_rules49`
  now also run at 50, where every flight matches. At 51, the flights that earn
  the bonus are skipped: 7 of 108 (2-3 in both fixtures, endless at all three
  widths, and co-op roped and free). The other 101 still match.
- Version pins moved from 50 to 51 in `rules43_version_test`,
  `rules50_version_test`, `endless_plan_baseline_test`,
  `fiercer_gargoyle_test`, `level_feathers_test` and `boss_stages_test`.
- Full suite (machine heavily loaded by other sessions): 3618 passed and 5
  failed. Three were those pins. The other two were timing tests
  (`world_regions_test` crossings, `king_coo_head_test` frame cost), and both
  passed when rerun alone. All six files pass after the pin fix.

## 2026-10-03 Neferhoo landed on the main tree (rules 50, schema 6)

The Egypt program (Neferhoo and level 2-6, built and reviewed as rules 46 in
its own trees) was rehearsed on a copy of the main tree as it stood (rules 49:
the fiercer Gargoyle 46, fair hearts 47, the tougher endless Baron 48, level
feathers 49; the finish-line celebration and ScreenFrame; the Steam Geysers
art, which landed during the rehearsal, was merged in and its tests rerun)
and then landed.

- **Numbers**: Neferhoo is **rules version 50** (`neferhooRulesVersion`, now
  current); the save migration (Arabia 2-6..2-8 to 2-7..2-9) is **database
  schema 6** (main was still at 5).
- **Frozen first**: `test/frozen_rules49_test.dart` was recorded from the
  untouched copy BEFORE the program was applied (the 20 levels of chapters 1
  to 3 with their staged bosses and guardians, the fierce Gargoyle and fair
  hearts included, at three widths, both weapons, mortal and sloppy bots, New
  York's pilots, endless at three widths, co-op roped and free, a duel, six
  tapes). After the landing every one of them flies at 50 exactly as at 49.
  `frozen_rules45_test` keeps pinning 45 (at 45 only: the current version
  moved on by design). `frozen_egypt50` (was `frozen_egypt46`) was re-recorded
  once at 50: the same flights and summaries, only the digests moved (fair
  hearts change the hearts he floats in) and the tape's version.
- **Conflicts resolved by hand** (both sides kept): the rules version block,
  `campaignHealthFor` (the fiercer Gargoyle's parameter and Neferhoo's 300),
  `stageHint` (the fierce Gargoyle's line and his), the story stage's switch,
  the result stage's two new parameters (`handoff`, `nextWasOpen`), the sound
  bank, `prepare_sound_effects.py` and the sound docs (the finish line's cues
  and Egypt's side by side; both took seeds from 501, see "Egypt cues"), and
  the version expectations in `boss_stages`, `rules43_version`,
  `endless_plan_baseline` (now also flies endless at 50 against 49 through the
  returning Baron), `fiercer_gargoyle` and `level_feathers`.
- **Tests**: `flutter analyze` clean; the full suite on the rehearsal: 3603
  passed, 238 skipped, 2 failed (the two literal `currentRulesVersion, 49`
  above, then fixed and rerun green). A real 2-6 flight through the app at
  792 x 360 (`neferhoo_real_flight_test`, `M1_REVIEW`) as a smoke check.

## 2026-10-03 Neferhoo fix round (after the W4 reviews)

- The hint lines are drawn (`neferhoo_fix_round_test`): after eight rocks on
  his wraps without a return the rules' adaptive line ("Rocks only scuff his
  wraps. Shoot his LETTERS back!") hangs under his health strip, where the
  shipped guardians hang their tags, fades in, gives way to the ankh's
  telegraph and comes back once the ankh is home; a return swaps it for
  RETURN TO SENDER! −25 for 1.5 s; it yields to the STRONGER! card; it is in
  the frame `BirdGame` renders, under the letters, and clear of the hearts
  plate, the pause key and the lane tags at 640/792/800/864 px with and
  without 44 px notch insets (the HUD's plate and the tags now follow the
  safe-area insets the game reads from its `MediaQuery`).
- The ankh never hides under the hearts plate: whenever its loop passes under
  the plate (a lock at .22 or .6; not at .46), the play screen fades the plate
  to .25 from the lock until the last ankh is home, and back; checked frame by
  frame at 640/792/864 px with and without insets, and in the real app (the
  plate's `Opacity` equals the fight art's value in every captured frame).
- The result's "2-7 Lantern Bazaar is open!" shows for a fresh player and not
  for a returning one who had 2-7 open (`neferhoo_real_flight_test`, both
  saves in the suite).
- Audio (`neferhoo_audio_test`, `neferhoo_merge_audio_test`): his hits never
  ring `boss_hit`; a landing in the frame of his roar or fury's cry is
  `postage_due_duck` (−8 dB); fury never roars a second time a step later (a
  one-line guard in the shared chain); `lost_letter` rings at 3.2 s, after
  `boss_victory`; the stage-up beak opens on the cue's syllables.
- Reduced Motion: he is drawn at his bob's centre (the rules' circle still
  bobs, within a third of its radius); the landing burst drops its flash,
  rings and confetti. The catch: the drawn ankh glides into his hand over its
  last .3 s, at least .5 screen heights right of the bird. The story stage
  draws him at 40 px a unit, 24 px lower, streamers tucked: the Skip key
  covers 74 px² of a feather tip at 640 (745 before), 8 at 792, none at
  800/864.
- `frozen_egypt50` (new): 2-6's data, the shared bot through the whole level
  at 640/800/864 px and 2.2, R1's pilots and a recorded tape (replays, seeks
  and re-records byte for byte), at his rules version.

## 2026-10-03 Neferhoo integrated (rules 50): 2-6 played for real

- The whole level through the real app (`test/neferhoo_real_flight_test.dart`;
  `PushUpBirdApp` and its router, a real save, the play controller's own
  keys, 60 frames a second, no heart top-ups): the map opens 2-6's card behind
  `before-2-6`, Fly flies the 30 s run-up (36 / 36 stars), the arrival, the
  warm-up, both stage-ups, mail calls, returns, the ankh, fury, the defeat and
  the coast to the line; the result gives 3 stars and Next; the map plays
  `last-2-6` once and opens 2-7. At 640 x 360 on an old schema-5 save
  (migrated at open: Arabia's 2 / 1 / 3 stars on 2-7..2-9, 2-6 open and not
  cleared), and with `--dart-define=M1_REVIEW=<dir>` also at 800 and 864 on a
  fresh save (2-7 locked until 2-6 is won) and at 640 under Reduced Motion,
  with frame strips and an MP4 per width (`M1_VIDEO=<frames>`). The design's
  family pilot (careful, seed 1) beats him in 65 s at 640 (7 letters landed,
  42 scuffs, 7 ankhs, untouched in the fight), 39 s at 800, 51 s at 864; every
  one of his 12 cues plays.
- The fight art on the real rules (`neferhoo_fight_art_test`,
  `neferhoo_merge_art_test`; the art tests' rules stand-in is gone): every
  letter's body is the rules' rectangle within a pixel, also inside the frame
  `BirdGame` itself renders; returned letters fly on the rules' clock and curve
  (`homeAt`, `returnAt`), letters sent back together land at least
  `landingGap` apart; a fight frame records no picture after the arrival
  (fury's second ankh was missing from the prewarm); the MAIL CALL / THE ANKH
  tags never sit under the play screen's hearts plate or his health strip at
  any lane height from 576 to 960 px (a high lane used to put them under the
  plate).
- Audio and voices on the real counters (`neferhoo_merge_audio_test`, no
  longer skipping): in real flights at 1.78 and 2.22 each cue plays on the step
  of its edge, `mail_call`, `ankh_raise`, `postage_due`, `letter_flick`,
  `ankh_whir`, `ankh_catch` exactly as often as the rules count them; his
  flight-voice moments (attack, summon, hurt) each follow a rise of
  `mailLocks`, `ankhThrows`, `returnsLanded`.
- The story stage acts his card line: "Return to sender!" (`before-2-6` line
  7) shows the stamp and a fan of letters, his HALT! (line 1, also angry) the
  raised wing; only Neferhoo reads the line (`StoryBossArt.actsLine`).

## 2026-10-03 Neferhoo's rules (rules 50)

- His rules on the real simulation (`test/neferhoo_rules_test.dart`, 25
  tests at 640 px, the shared bot also at 800 and 864): the mail call locks on
  the bird at .6 s and deals three letters at 1.6/2.0/2.4 s (exact cycle
  times; the lane clamped to .16-.84); a letter hurts like a course edge and
  is spent, the next ones meet a recovering bird harmlessly; the catch band
  equals the hurt band for every tilt, flap stretch and Reduced Motion (the
  beak's −.0078 to +.0276 is inside the band's .008/.028 allowance); shots
  from −.065, 0 and +.065 off the lane send the letter back, +.11 does not; a
  returned letter is unstrikable, harmless where it would have flown, and
  lands once for 25 (`lastHitAt == lastLandAt`); charged rocks (≥ .35) send
  back a whole stream and carry on, tapped ones (and .34) are spent on the
  first; landings at least .1 s apart; a sprint ram returns; the wraps deal
  10 → 3, 40 → 13, 28 → 9, 1 → 1, and eight scuffs bring the hint until a
  return; the ankh's lanes, throw, 2.66 s round trip at 640 px, both passes
  hurt, the room between the lanes is safe, fury's mirror (+.5 s, .95), rocks
  pass it; the warm-up throws no ankh for three cycles; a stage-up arms the
  first lock at least 1.6 s away (at 2, 4, 15 and 16 s: cycles 0, 1, 1, 2);
  fury is latched at each lock (a calm stream stays calm, the next lock is
  the express post and two ankhs); every hint in order; a landing that beats
  him clears everything and nothing hurts the bird to the line; recorded
  flights replay, a backward seek and a fresh player reach the same fight
  state, and `mailLocks`, `ankhThrows`, `returnsLanded`, `lettersDealt`,
  `ankhLocks`, `ankhCatches` rise at most once a frame and equal their
  events.
- Fairness (`test/neferhoo_fairness_test.dart`,
  `neferhoo_fairness_coarse_test.dart`; the design's backward viability
  search over the shipped pure rules, Tap & Fly physics): at five taps a
  second every scenario of every stage (mail call locked at .16/.3/.5/.7/.84,
  ankh at .25-.75, express post, two ankhs) is viable from every state the
  edges alone let live, at 640, 800 and 864 px; reaction budgets at 640 px
  1.3 s (ceiling lane) / 2.0 s / ankh 1.9 / express 1.1-1.9 / two ankhs 1.8
  (800: 2.3-3.0; 864: 2.4-3.0), the design's figures exactly. At 1.5 taps a
  second all letter scenarios are viable; a lock at the bottom clamp (.75)
  leaves 99.7% (ankh) and 98.3% (two ankhs) viable at 640, 99.98% at 800,
  100% / 99.99% at 864. The streams never overlap the ankh (≥ 2.5 s apart,
  1.6 to 2.4 screen heights wide).
- Pilots (`test/neferhoo_pilot_test.dart`, the design's `ttk.dart` bot ported
  onto the real simulation; 100 fights per row from varied starts and shot
  phases; tables in `egypt-int/deliveries/r1/HANDOFF.md`): with 300 HP the
  family bot wins in a median 59 s at 640 px (41 at 800, 39 at 864, 62 at
  576), the first-timer in about 2 minutes (119 s at 640), the practised one
  in 27 s; the family is never knocked out. 270 HP (the plan's estimate) gave
  the family 51 s. The shared bot (`boss_stages_test`, 2-6 added) wins in
  about 26 s: it returns every letter and ends the warm-up with the first
  ones, so its warm-up gate is 2 s for 2-6 (the full fight and fury still
  last over 8 s each).
- 2-6's marks (`test/neferhoo_marks_test.dart`): the run-up lays 36 stars on
  12 passages; 20 / 30 (50% / 80%, to fives) are no longer provisional; every
  sharp, average and casual pilot collected all 36 at 640, 800 and 864 px and
  six shot phases.

## 2026-10-03 Egypt's guardian scaffold (rules 50)

- Rules version 50 (`neferhooRulesVersion`) and Neferhoo's interfaces
  landed before his rules and art (`egypt-int/MASTER-PLAN.md` in the program
  tree). Everything that flew before is guarded by fixtures recorded from the
  untouched rules 45 game: `test/frozen_rules45_test.dart` pins the 20 levels
  of chapters 1 to 3 that 45 could fly (plan JSON with their old ids, routes,
  vents, marks, card data), 46 bot flights including the staged bosses, King
  Coo's vanguard and stragglers and the Gargoyle, New York's pilots against
  both staged guardians at 640 and 800 px, endless at three widths, roped and
  free co-op and a duel, and six saved rules 45 tapes; every flight runs at 45
  and at 46 and must match, every tape must reload, re-encode, replay, be
  recorded again byte for byte at 45 and to the same digests at 46.
  `frozen_rules41_test` and `frozen_ny43_test` still pass (the rules 41 one
  looks Ancient Arabia up by its old ids).
- Level 2-6 "Return to Sender" (Egypt, 30 s run-up, Neferhoo, seed 2116 with
  one stone door on its fifth passage, 36 route stars, marks 20/30
  provisional) and Ancient Arabia renumbered 2-7..2-9: `rules50_version_test`
  (the gate, the tape guard, no new plan key, endless never meets him over 200
  boss numbers at versions 34 to 46, the run-up flies into a staged, 270 HP,
  vanguard-free Neferhoo who stays at his anchor), `egypt_migration_test` (a
  real schema 5 save opened at schema 6: records and flights renamed highest
  id first, watched scenes and the voices' memory renamed, run once, a fresh
  save untouched; a returning player keeps Arabia and New York with 2-6 the
  current level; a finished level stays open; three Egypt stops on the map;
  63 / 51 stars; legacy replay titles), `neferhoo_scaffold_test` (his own
  entry point at every shared dispatch, 640/800/864, arrival to defeat,
  Reduced Motion). His rules are stubs (a punching bag) until the rules step.
- The 37 Arabian clips were renamed, not recorded again; the clip tables were
  regenerated with `prepare_story_voices.py` and `prepare_flight_voices.py`
  (identical but for the names). The design's cargo line did not fit a
  guardian's tag: "A feather duster for the caretaker" fits it at 640, 800
  and 1000 px.

## 2026-10-03 Steam Geysers art refinement (art only)

What was asked: "In NY we have a special thing that smoke comes out of it. I
want to refine and improve the design. Don't integrate, first show me the
result." Designed in `../steam-ws/` (report
`reports/01-steam-iteration.md`, two rounds with an independent review in
between), shown as before/after renders and clips, then "Apply it". The
designer's defaults for the four open choices landed (tall billow, fully cool
ride burst, amber hop rims, no rail on the ride warning).

What was built (spec: "Steam Geysers", **Look**). Only
`lib/game/steam_geyser_{art,kit,emitter_art,plume_art}.dart` changed; rules,
timings, hit and lift boxes, plume tops, phases, scoring and sound triggers
did not, so no rules version.

- **Hiss.** Hop: a hazard-taped column (black-and-amber bar on the hit top,
  solid walls, a warm fill climbing from the lid, heat shimmer, wisps, wedge
  spurts) with one brightness ramp into the burst (the 7.3 Hz flicker is
  gone). Ride: no box, a dotted teal dome on the reach top, a teal funnel,
  growing chevrons and a lit grate.
- **Burst.** Hop: a slim jet with an amber core, amber rims and a rolling
  head. Ride: a soft cool upwelling at cloud ink weight; spray, flash and glow
  now follow `hot`, so a ride vent (which never scalds) shows no amber.
- **Billow.** Tall (h/w 1.30), leaning, inked on the shade side and base only,
  teal updraft streaks; cool by billow 0.2; no dip at the burst handover.
- **Emitters.** A hazard-striped curb round the manhole, a grate slot field
  that brightens with the hiss, a contact band, a drain on the block.

Tests:

- `test/steam_geyser_art_test.dart`: worst 76 draw calls a vent (limit 80),
  141 for the heaviest two-vent frame (limit 160). The old frame of three
  vents 0.8 heights apart, which no route lays, became two route-spaced
  two-vent checks and a 5.6:1 three-vent regression guard (at most 190,
  measured 187).
- New `test/steam_geyser_design_test.dart` (8 tests): hot brighter than cool,
  a ride vent cool in every pixel of its burst and billow, ride and hop bursts
  with different silhouettes, a sudden first frame, a warning whole from the
  first tenth of the hiss, the hazard bar against the dotted dome, the billow's
  shape and ink.
- Rehearsed on a fresh copy of the tree: steam tests 114 passed (8 skipped),
  full suite 3336 passed (223 skipped), nothing failed. Old files:
  `../steam-ws/backup-main-before-landing/`.

Open: never timed on a phone (a burst or billow records about 2x slower,
about 0.13 ms a vent on a desktop). The Con Ed stack only appears for tall plumes
(top under 0.47), which the shipped 3-3 and 3-4 routes never lay.

## 2026-10-03 A celebrated finish line (presentation only)

What was asked: "In campaign, we have a finish line, but we want a perfect,
super satisfying, rewarding finish line. Refine and improve". Before this,
the world froze on the frame the bird reached the line, the bird vanished, a
chime played and the result slid in with a different bird on a cloud.

What was built (spec: "Finish-line celebration"):

- **The approach.** In the last 3 s the gate's 16 marquee bulbs flick on and
  chase (`finish_near` plays as they start), its flags quicken, its glow
  swells and the HUD's route flag glows and waves.
- **The crossing.** `PlayStage.celebrating` and `FinishCelebrationArt`,
  built like the knockout: a pure function of the seconds since the crossing
  (`PlayController.celebration`), with a fallback timer, a 0.5 s tap guard
  and a skip overlay. A 75 ms hit-stop, then the tape snaps at the bird's
  height and whips back. Confetti cannons fire from the post tops (84 pieces
  and 8 streamers, by a fixed hash), the crest spins in a sunburst, the sign
  swings, the camera punches in, one haptic fires, and `finish_snap`,
  `finish_cheer` (the music ducks under it, `SoundSpec.duck`) and the
  `complete` fanfare play.
- **The payoff.** The bird loops, the world warms, and it swoops into the
  result's courier seat (`LevelResultStage.courierSeat`). The result takes
  over at 1.7 s with that bird in place and its cloud puffing in
  (`handoff`), the confetti still falling until 4.2 s. The keys arm at
  2.75 s.
- **Reduced Motion** gets a calm 0.8 s version. Replays play the celebration
  past the end of their tape, ending in a hover.
- **No rules change.** The flight still ends at the crossing with
  `EndReason.completed`, the save still starts there, and the rules version
  stays 47. Endless, co-op, duel and timed-route endings are untouched.

Tests:

- `test/finish_celebration_test.dart` (28 tests):
  - the seekable timeline: every beat renders, the same moment paints the
    same, the handover and still times, and crossings high, middle and low
    land in the seat in its pose;
  - the stage flow: the cue order, the skip guard, background, pause and
    back, Reduced Motion and the fallback timer;
  - that the same flight's result, stars, journal and replay are identical
    whether the celebration plays, is skipped or is interrupted;
  - a draw budget of 500 for the busiest frames (measured 394–432, gate
    included), with no blur and at most two layers;
  - the cues in the bank, and the play screen's handoff, skip and back key.
- Updated because the flow changed: `campaign_play_test` (celebrating before
  results; snap before fanfare), and the `_fly` helpers of
  `campaign_screens_test`, `polish_s4_result_test` and `ny_ui_flow_test`,
  which now play the celebration out as the game loop does. `sky_audio_test` covers the duck.
- Review captures (gated by dart-defines):
  `finish_celebration_capture_test` (staged, every bird, six regions,
  three heights, calm, replay) and `finish_celebration_sequence_test` (real
  flights of 1-1, 3-3, 1-8, a staged 3-2, and 1-4 calm, frame by frame for
  MP4s).
- `flutter analyze` is clean. The full `flutter test` run: 3296 passed, 223
  skipped by design, 9 failed, all in `ny_ui_flow_test`'s result flow (the
  same helper pattern). With its helper updated, that file passes, 16 of 16.

What is not covered:

- The cues are judged by measurement, not yet by ear on the phone.
- The haptic is untested on a device.
- The guardian review sequence lays its line ahead of the bird instead of
  flying the King Coo fight.

## 2026-10-03 The Gargoyle's level feathers (rules 49)

What was asked: "The gargoyl boss shots cover more when they shoot at the
bottom half of the screen and it is unfair. If the bird is on top, it's
easier to dodge. we should reduce the covering point in the bottom half".
Asked which attack, the owner chose the falling stone feathers (not the
beam).

What was found. His beam's rules are mirror images (the same band above and
below). His feathers are not. Each leaves the top edge .62 ahead of the
bird and crosses its column where the bird was, so one aimed low falls much
steeper. A still bird is touched over a band (bird and feather radii times
√(1 + slope²)) that nearly doubles toward the bottom. Low down the bird
can only climb into the feather, so it has to start its dodge sooner.
"Lead" below is the latest a bird hovering at that height can start its
dodge, with any tap plan of at most five taps a second (a search over Tap &
Fly's physics, `_lead` in the test):

| aimed at | slope 48 | band 48 | lead 48 | slope 49 | band 49 | lead 49 |
| --- | --- | --- | --- | --- | --- | --- |
| .1 (calm) | .98 | .18 | .36 s | .98 | .18 | .36 s |
| .3 | 1.30 | .22 | .36 s | 1.30 | .22 | .36 s |
| .5 | 1.62 | .25 | .37 s | 1.30 | .22 | .36 s |
| .7 | 1.94 | .29 | .39 s | 1.30 | .22 | .37 s |
| .9 | 2.27 | .33 | .57 s | 1.30 | .22 | .36 s |
| .9 (fury) | 2.03 | .30 | .49 s | 1.30 | .22 | .34 s |

What was built (spec: "Rules version 49" under the staged campaign bosses):

- `FlightSimulation.levelFeathersRulesVersion` (49, now current),
  `supportsLevelFeathers`, `SkyBoss.levelFeathers` (campaign Gargoyle).
- `SearchlightGargoyle.maxFeatherSlope` (1.3) and `featherShot(…, level:)`.
  It returns `ahead`, where the feather leaves. A feather that would cross
  steeper leaves further ahead and flies faster, in the same flight time,
  aimed at the same height. Schedules and crossing times are unchanged. At
  most it leaves 1.13 ahead (still in front of his perch) and flies .66 a
  second (fury .72, like the Dusk Empress's fury shot). A feather that isn't
  levelled is bit for bit as before.
- Art: the rules give each feather a render-only `BossAmmo.launchX`.
  `GargoyleFeatherArt.age` counts from it, so the tumble and wake stay exact.
  The dust telegraph uses `entryX(…, fury: furyPace, level:)` (it read
  `enraged`, a little off in the fiercer full fight).

Tests:

- `test/level_feathers_test.dart`: the gate (48 / 49 / endless); every
  height and pace crosses at the aimed height in the same time, never above
  1.3, and high shots are unchanged; the bottom half's band is no taller
  than .3's; launches stay in front of him; in the real 3-4 fight every
  feather obeys this at 49 and leaves .62 ahead at 48; the dodge lead at
  .6–.9 is now within a frame and a half of .1–.4 (it was .08 s or more
  later); the fairness proof through all four of his cycles with level
  feathers (every start, .3 / .45 s idle, a .012 margin, the whole cycle from
  the perch feather); the art's age and dust follow `launchX` and `ahead`.
- `test/gargoyle_viability.dart` (`Search(level:)`) and
  `test/gargoyle_pilot.dart` (reads `launchX`) learned level feathers.
- `test/endless_plan_baseline_test.dart`: endless at 49 equals 48 second by
  second, through the returning Baron; version pins moved to 49.

Measured with the reacting pilots of `fiercer_gargoyle_test` (3-4, 2.2 wide,
8 phases, hearts topped up; feathers that touched the bird, by where they
were aimed):

| pilot | rules | fight (s) | beam hits | <.4 | .4–.6 | ≥.6 |
| --- | --- | --- | --- | --- | --- | --- |
| average | 48 | 135–152 | 0 | 0/93 | 2/255 | 0/37 |
| average | 49 | 134–144 | 0 | 0/88 | 0/247 | 0/35 |
| casual | 48 | 306–341 | 39 | 9/184 | 74/637 | 2/46 |
| casual | 49 | 297–341 | 46 | 15/164 | 65/667 | 0/33 |

These pilots plan a perfect dodge and rarely fly low (they line up on the
lamp), so they show the fight is no shorter or easier overall, not the
bottom's gain. That gain is the lead table above. Scripts and logs are in
`../gargoyle-ws/level-feathers/`.

Not covered: nobody has played it on a phone. The beam's look is
unchanged: his lenses sit high, so a beam aimed low still cuts across the
sky ahead of the bird.

## 2026-10-03 The returning Baron's health doubled (rules 48)

What was asked: "Double HP for the second occurence of Baron bat in the
infinite run". The endless cycle is Baron, Spitter, Empress, Pirate, Dragon,
so his second visit is encounter 6, where he already returns upgraded (rules
40: the screech and bat pairs) with 240 HP.

What was built (spec: "Rules version 48" under the staged campaign bosses,
and "Baron Bat returns upgraded"):

- `FlightSimulation.tougherBaronRulesVersion` (48, now current) and
  `supportsTougherBaron`. The upgraded Baron spawns with
  `SkyBoss.healthFor(…, tougherBaron: true)`: 480 HP instead of 240.
- Every return is doubled (encounters 6, 11, 16…), not only the second, so a
  later Baron is never weaker than the one before. Solo and co-op endless
  both get it. His debut, the other bosses, campaign bosses (always a debut)
  and duels (no bosses) are unchanged. Rules 47 tapes keep 240.

Tests:

- `test/baron_bat_upgrade_test.dart`: 120 / 240 / 240 at 47 and 120 / 480 /
  480 at 48 for Barons 1, 2 and 3, solo, roped and free; the other endless
  bosses keep `healthFor`.
- `test/endless_plan_baseline_test.dart`: a rules 48 endless flight equals a
  47 one second by second, at 1.6, 2.2 and 2.4, until the returning Baron
  arrives on the same frame with 480 against 240. 44–47 still equal 43.
- Version pins moved to 48 (`rules43_version_test`, `boss_stages_test`,
  `fiercer_gargoyle_test`), and `dusk_moth_boss_test`'s cycle expects 480.

Measured with the sharp pilot of the beatability test (fight seconds from
the boss timer, hearts left):

| width | rules 47 | rules 48 |
| --- | --- | --- |
| 2.2 (play) | 33.7 s, 3 | 68.6 s, 2 |
| 2.22 | 37.9 s, 2 | 60.9 s, 3 |
| 1.78 | 28.6 s, 2 | lost with 80 HP left |

Play is always 2.2 wide now (`ScreenFrame`), so the beatability test flies
2.2 and 2.22 instead of 1.78 and 2.22.

Full suite: 3262 passed, 224 skipped, 1 failed: `dusk_moth_boss_test`'s
endless cycle still expected 240 for Barons 6 and 11. That pin is now 480 and
the file passes. Analysis is clean.

Not covered: nobody has played the longer fight on a phone.

## 2026-10-03 One picture on every screen (presentation only)

What was asked: "Check the game in different screens. Does it differ? I think
it shouldn't right? I like how it is in the connected phone." The connected
phone is a OnePlus CPH2585: landscape, 792 × 360 dp, 2.2:1.

What was found. Before this change no device was pinned to a design size,
and each layer adapted on its own.

- **Play.** The rules measure in screen heights, and the screen's aspect went
  straight into `viewportWidth`, unclamped. A 16:9 phone saw 1.31 heights
  ahead of the bird instead of 1.73, about a second less to react at tap
  speed.
  - The Baron and the Spitter parked at x 1.06 instead of 1.48.
  - Enemies' fire window was .79 heights instead of 1.21.
  - At 4:3 that window was .34, pigeons never snatched, and the Gargoyle,
    Dragon and King Coo were cut at the right edge.
- **Menus and HUD.** The 1000 × 450 canvas letterboxed inside a full-bleed
  sky, so on a tablet the HUD floated about 150 dp in from the edges.
- **Map and story** recomposed: `k` clamped to 1 to 1.25, scenery fitted to
  height, chrome unscaled.

This closes "the 1.6 to 2.4 letterbox" left open in the New York fix round
(R5), and goes further: nothing changes with the screen any more. The owner
chose to lock the whole app, not just play, with navy bars.

What was built (spec: "One picture on every screen" under "Technology and
architecture"):

- **`ScreenFrame`** (`lib/ui/screen_frame.dart`), wrapped around the router in
  `lib/main.dart`.
  - The app is laid out at 792 × 360 and scaled uniformly to fit, centred,
    with `SkyColors.night` bars around it.
  - Inside it, `MediaQuery` reports 792 × 360, a scaled pixel ratio, and only
    the insets that reach past a bar.
  - A tap on a bar lands on the nearest edge of the picture.
  - The reference phone itself is passed through with no transform.
- **Landscape on every device.**
  - Android: `android:appCategory="game"`, so Android 16 tablets keep the
    landscape lock.
  - iOS: landscape only, and `UIRequiresFullScreen` on iPad.
- **No rules change.** The simulation is untouched; it is now always fed 2.2,
  the rules' default. Replays keep their recorded width.

Tests:

- `test/screen_frame_test.dart`.
  - At 792 × 360 the frame passes through.
  - At 640 × 360, 864 × 360, 1000 × 450, 1024 × 768, 1280 × 800 and a portrait
    800 × 1280, the picture is 792 × 360 inside, scaled and centred, with the
    pixel ratio scaled.
  - A notch only pokes in past a bar, and the bars swallow gesture strips.
  - Taps on the bars reach the picture.
  - Home, map and a touch flight on 792 × 360, 640 × 360, 864 × 360 and
    1024 × 768 run without exceptions and fly a `GameWidget` of exactly
    792 × 360 (sim width 2.2), and a tap on the sky flaps. With
    `--dart-define=CAPTURE_VISUALS=true` it writes the side-by-side to
    `build/visual-review/screens`.
- Updated to measure inside the frame:
  - `touch_mode_ui_test` (the canvas fills the picture; taps at the display's
    very edges still flap, now through the bars).
  - `campaign_screens_test` (Play's place, 70, 218, 420 × 76 on the canvas,
    seen through the frame).
- `game_over_stage_test` passes unchanged once bar taps are forwarded: it
  dismisses a dialog by tapping the display's corner.
- `flutter analyze` is clean. The full `flutter test` run passed: 3258 tests,
  224 skipped by design, 0 failures.

What is not covered:

- On a 16:9 phone everything is 0.81× the reference phone's size. That
  includes the map's keys, 48 → 39 dp. The menus there are the same size as
  before (the canvas already showed at .64).
- The camera preview, a platform view, now sits under a scale transform on
  any display that is not 792 × 360. This is untested on such a device; the
  reference phone has no transform.

## 2026-10-03 A fiercer Searchlight Gargoyle (rules 46)

What was asked, after a playtest of rules 45: "I like how hard King Coo is.
I want Gargoyle to be the same hard and same length, now you can kill fast".
Offered three ways (King Coo's recipe: a vanguard whose escapees come back;
his own attacks fiercer, no minions; more health only), the owner chose his
own attacks fiercer, no minions.

What was built (spec: the rules 46 bullet under "Campaign boss stages and
vanguards"). 640 health (200 at 44 and 45). His warm-up drops the calm
cycle's two feathers (none before). Once he grows stronger his beam glides
and his feathers fly at fury's pace (`SkyBoss.furyPace`: a 1.5 s glide, the
.095 band, feathers at .44), and a feather falls in the vent at 7.0 s, aimed
at the bird lining up on the open lamp; in fury two, at 6.5 and 7.4 s, in
zone and slit cycles alike. No new art: his feather flick, the feather and
the beam are the rules 43 parts (a review sheet of real frames is in
`../gargoyle-ws/review/`).

Measured with New York's pilots over 4 widths x 2 shoot phases (3-4). The
fight, with hearts topped up, flown by the pilot that knows his cycle by
heart (the one the level tests fly):

| Pilot | Fight at 45 | Fight at 46 | King Coo's (45) |
| --- | --- | --- | --- |
| sharp | 26–27 s | 107–108 s | about 100 s |
| average | 62–63 s | 134–144 s | about 155 s |
| casual | about 130 s | 323–350 s | about 210 s |

That pilot is never touched at 46, at any width or phase: the new feathers
are as fair in the real flight as in the proof. The casual fight is long
because his lamp is open 29% of the time and that pilot shoots every 0.8 s,
a second late. Pilots that react as King Coo's bots do (they see a feather
.3, .55 or .8 s after it leaves and a sweep's side as late into its warning,
plan only for what they have seen, and tap at most 5, 3.5 or 2.5 times a
second), mortal, the whole level:

| Pilot | 3-4 at 45 | 3-4 at 46 |
| --- | --- | --- |
| sharp | 4 of 4, never hit | 8 of 8, never hit |
| average | 4 of 4, never hit | 8 of 8, .5 hits a flight (feathers) |
| casual | 3 of 4, 3 hits a flight | 0 of 8, 5 hits a flight (beam and feathers, most in fury) |

3-2 for comparison: 44 / 31 / 9% finished, about 2.5 hits a fight. The
reacting pilot searches every tap sequence over what it has seen, which no
player does, so its sharp and average are untouched by either Gargoyle and
only the slowest tells them apart; hit counts of different bots against
different bosses do not compare. A playtest decides "as hard".

What the evidence changed.
- A fury vent feather at 7.6 s crossed the bird's column after the cycle
  ended, past the pilot's plan, and caught even the pilot that knows the
  cycle (1 to 6 hits a fight). The pair is 6.5 and 7.4 s; every vent
  feather now crosses before 8.85 s (`fiercer_gargoyle_test`).
- Tried first: fury's two sweep feathers in the full fight. The sharp and
  average reacting pilots stayed untouched; only the casual pilot's fight
  grew (414 s). Fury's pace for the full fight (faster sweeps and feathers,
  as the option offered said) replaced it.
- 720 health: sharp 117–125 s, average 151–161 s; 640 matches King Coo's
  sharp fight best and keeps the average inside his band.
- The test search (`gargoyle_viability.dart`) packed every feather lane of
  its memo key into one 64-bit int: with four lanes or more (a fury cycle
  with its vent feathers) it overflowed, unrelated states collided and the
  search lost paths. The key is now a record, and a tap gap over 15 frames (a
  casual pace) has its own count in it. Neither changes a rules 43 to 45
  proof (at most three lanes, a gap of 12).

Tests: `fiercer_gargoyle_test.dart` (new: the rules, the schedules, his
fight, rules 45's fight unchanged, the fairness proof through the vent for
the three new cycles, the reacting pilots); `ny_levels_flight_test` (his
fight bands 85–135 / 110–185 / 270–420 s); `boss_stages_test` (the warm-up
without feathers is rules 44 and 45's); version pins in
`rules43_version_test` and `endless_plan_baseline_test` (46 flies endless as
43). `flyNewYork` flies for up to 600 s; `gargoyle.Pilot` plans through a
fiercer Gargoyle's vent and takes `react` and `tapGap`.

Open. Never phone-played. Knobs: `SkyBoss.fiercerGargoyleHp` (640),
`SearchlightGargoyle.ventFeathers` and `furyVentFeathers`, fury's pace in the
full fight (`SkyBoss.furyPace`), the warm-up's feathers
(`SearchlightGargoyle.fierceFeathers`). As at 44, his STRONGER card hides
while his lamp is open and his stage-ups land in the vent, so "Feathers fall
on the open lamp!" shows only once the lamp shuts, for the last second or so
of its 3 s.

## 2026-10-03 Baron Bat detail redesign (art only)

- Art only: rules, timings, the hit oval (x ±.91, y -.81..89), the eye,
  mouth and fireball positions and every pose channel are unchanged. The
  shared `BossRig` colours and `fill/line/gradient` keep their values and
  signatures (the other rigs use them).
- The Baron is now drawn as a bat:
  - wings with a forearm, a thumb claw, four tapered fingers with knuckles,
    and a scalloped membrane that lightens toward the hem;
  - big ears with a pink inner ear and fur tufts that flick when idle, prick
    up on a charge, pin back in fury and droop in defeat;
  - cheek fur, a pug nose with a nose-leaf, gold-ringed pupils, a cocked
    brow and a smug mouth crease;
  - clawed feet, a bat-wing collar, a lined cape with folds and gold clasps,
    and a gilt breastplate with a winged crest around the gem;
  - an heirloom crown with the same outline, so the keepsake and the
    falling crown still fit.
- The storm Baron is rebuilt on the new body. In story scenes the Baron's
  face now follows the line's mood (`_Pose.storyMood`, Baron only), so his
  sad face is no longer only heavy lids and a sweat bead.
- A one-frame blink of the mouth and gem at each fireball release is fixed
  with a 0.2 s art-only release hold.
- Files: new `lib/game/baron_bat_art.dart` (every Baron part);
  `lib/game/boss_rig.dart`, `lib/game/baron_storm_art.dart` and
  `lib/ui/story_boss_art.dart` changed.
- Cost: debut 78/84 → 127/129 draw ops (calm/busiest), storm 106 → 142. No
  new layers, clips or blurs, and paths that don't move are built once.
  `test/baron_budget_test.dart` (new, 15 states) caps the debut at 160 ops,
  the storm Baron at 180, clips at 3 and layers at 1, and allows no blur.
- `test/fixtures/debut_baron_baseline.json` was re-recorded with
  `--dart-define=RECORD_BARON_BASELINE=true`.
- Values at real size: eye whites are still the brightest read, then the
  crown, then the lilac hit body. On mid-tone dusk and night fight skies the
  lighter outer wing sits close to the sky, and its ink outline carries the
  edge.
- Results: `flutter analyze` on the changed files is clean. A rehearsal on a
  fresh copy of this tree passed the full suite (3204 passed, 223 skipped,
  0 failed); after landing, the Baron, story, encounter, HUD and budget tests
  pass here (162 passed).
- Renders, the design report and the before/after review are in
  `../baron-ws/reports/01-baron-iteration/`. Nothing was run on a phone.

## 2026-10-02 A tougher King Coo (rules 45)

What was asked, after a playtest of rules 44: "The pigeon boss small enemies
is so bad and easy. They should throw something or threat. Otherwise it's
too easy. Also the boss itself is too easy to kill still. We need double
health".

What was built (spec: the rules 45 bullet under "Campaign boss stages and
vanguards"). King Coo's vanguard pigeons coo, wind up and throw stale crusts
(`EnemyAttack.crumb`, aimed, 0.40 a second, every 2.2 s, a V's members 0.5 s
apart, flying at 0.8 of the scroll); King Coo has 840 health (420 at 44).
Rules 44 tapes replay the 44 fight. Art: the crust, its impact and shatter,
the pigeon's wind-up and throw (designer agent).

Measured with New York's pilots over 4 widths and 8 shoot phases (3-2):

| Pilot | Finished at 44 | At 45, before the stragglers | King Coo's fight then |
| --- | --- | --- | --- |
| sharp | 100% | 91% | about 80 s |
| average | 100% | 84% | about 123 s |
| casual | 100% | 66% (1 in 8 at 2.4 wide) | about 197 s |

Where it costs: the vanguard (0.4–0.8 crust hits a flight, and as many
pigeon bodies: rocks spent cancelling crusts leave more pigeons alive), and
a fury of a minute or more, which catches the pilots about once a minute
(crumb clouds, now and then the squadron). At 2.4 wide every pilot already
hits two walls in 3-2's run-up and reaches the vanguard with two hearts. The
crusts are about as many as the Spitter King's beetles spit in his vanguard
(the same bots take more seed hits there). A slower crust (0.36) made it
worse (crusts linger), so it stays 0.40.

Tests changed to say so: 3-2's completion gates in `ny_levels_spread_test`
(pooled 85% / 80% / 60%), King Coo's fight bands and hit allowances in
`ny_levels_flight_test` (his pilots fly with hearts topped up there), the
star marks judged on 3-2's run-up harvest. New: `boss_stages_test` checks the throws, the stagger and 840 against
420 at 44.

Then the stragglers. Asked next: "Those small enemies before the boss, for
this specific level, those who you didn't kill will come back during the
boss time until you kill them all". Built for King Coo only: one owed pigeon
back at 0.3 s and 4.3 s of each 14 s cycle, above or below him, winded (one
shot), throwing, until all are downed.

How it was tuned, with New York's pilots (16 flights each, sharp / average /
casual):
- A V of three once a cycle, full health: 1 / 0 / 0 wins. The pilots'
  fight bot only ever shot at him, and the run-up bot let 8 to 11 of the 14
  pigeons go. The bots were taught what a player does: hunt the vanguard,
  save shots for a straggler unless his chest is puffed, keep off close
  pigeons and crusts, and not fly through one (`king_coo_helpers.dart`,
  `ny_pilots.dart`).
- Singles twice a cycle: some returned level with his body, which takes
  the rocks meant for them; the heights now avoid it.
- His crumb rings, which lock on the bird, kept chasing the bot off a
  straggler's line before its two hits: stragglers come back winded (one
  hit).
- Then: throwing stragglers 7 / 4 / 1 of 16; stragglers that do not throw
  9 / 8 / 6. The owner chose the throwing ones.

Final (32 flights each over four widths): 3-2 finished 44% / 31% / 9%.
Every hit in his fight is a crumb cloud, the squadron, a straggler or its
crust (about 2.5 a fight). Tests record these as 3-2's floors
(`ny_levels_spread_test`), King Coo's fight bands with hearts topped up
(about 100 / 155 / 210 s), and the rule itself (`boss_stages_test`).

Open. The bots hunt pigeons less well than a person; a playtest decides.
If 3-2 is too punishing, the knobs are `BossVanguard.returnTimes`,
`returnSize`, `stragglerHp` and whether stragglers throw;
`SkyEnemy.crumbSpeed` / `crumbInterval`; `BossVanguard.throwerDrift` and
`wavesOf`; King Coo's 840 in `SkyBoss.campaignHealthFor`.

## 2026-10-02 Long, staged campaign boss fights and vanguards (rules 44)

What was asked. "In the campaign the bosses are too fast to kill. It's not
about how hard it is, it should be easy first but long, the player should
take some time. Then after a certain health bar, they get stronger, after
another point they get a bit more stronger. Some of them include smaller
enemies also so before we deal with them they send some small enemies and
then themselves show up."

What was built (spec: "Campaign boss stages and vanguards (rules version
44)"; player's guide: docs/campaign.md, "Boss fights"). Rules version 44,
campaign levels only: more health (`SkyBoss.campaignHealthFor`), three
stages on the thirds of the bar (an easier warm-up with no helpers and no
signature attack; the full fight; fury), a roar, a heart and a STRONGER! tag
each time the boss steps up, and a vanguard of small enemies before Baron
Bat, the Spitter King, the Dusk Empress and King Coo. Art by a designer
agent (`BossStageHudArt`, `BossPowerUpArt`, `BossVanguardArt`; review sheets
in `../stages-ws/art/build/visual-review/boss-stages/`).

Measured (the shared bot, which fires about as fast as the weapon allows,
hearts topped up; and the same bot tapping only every 0.6 s):

| Boss | Health 43 → 44 | Fight at 43 | Fight at 44 (busy / lazy) |
| --- | --- | --- | --- |
| Baron Bat | 120 → 600 | 9–11 s | 41–47 / 56–63 s |
| Spitter King | 210 → 600 | 15 s | 40–52 / 66–81 s |
| King Coo | 140 → 420 | 11–17 s | 46–51 / 51–59 s |
| Searchlight Gargoyle | 160 → 200 | 35 s | 44–45 / 54 s |
| Dusk Empress | 240 → 620 | 20–22 s | 65–74 / 82–90 s |
| Pirate Captain | 300 → 780 | 21–27 s | 56–67 / 85 s |
| Ember Dragon | 360 → 1,080 | 17–20 s | 58–59 / 77–82 s |

Every fight reaches each stage at least 8 s apart (`boss_stages_test`). New
York's mortal pilots (sharp, average, casual; 2 widths x 4 shoot phases) win
both guardians in every flight at 44 and end with the same hearts as at 43;
King Coo takes them about 40 / 62 / 95 s, the Gargoyle 27 / 68 / 130 s.

What the evidence changed.
- The Gargoyle pilot stopped dodging in the warm-up: it began each plan when
  the cycle's first feather left, and a warm-up drops none. It now plans
  from the feather's time either way and plans for no feathers when the
  cycle drops none (`test/gargoyle_pilot.dart`, `gargoyle_viability.dart`).
  At 240 health the casual pilot took about 2 min 45 s; he is 200.
- In a long fury, King Coo's fury squadron (a V and a picket behind it)
  hit the sharp and average pilots about once a cycle, at rules 43 as at 44
  (fury at 43 ended within about one cycle, which hid it). A staged King
  Coo's fury keeps three crumb rings but plans the single V: the pilots'
  fight hits went from 16, 41 and 28 in 32 fights to 0, 4 and 0.
- Two test hazards: the Gargoyle tests' "fly until boss age" loops never end
  if the flight cannot reach that age, which hung a full suite; and a
  campaign plan at the current version is now a staged fight. The New York
  mechanic tests' helpers (`nyFlight`, `flyNy`, `arenaOf`, the Gargoyle
  `arena`) default to rules 43, the fight they prove; rules 44 is covered
  by `boss_stages_test.dart` and the pilot files at the current version.

Unchanged. Endless, co-op and duel flights at 44 match 43 checkpoint for
checkpoint (`endless_plan_baseline_test`); chapter 1 and 2 frozen flights
match at 41, 42 and 43 and, except the two boss levels, at 44
(`frozen_rules41_test`); New York's frozen pilot flights replay at 43
(`frozen_ny43_test`); unstaged health bars render byte-identical (the
designer's one-off check of 1,008 plates). Staged fights and vanguards
replay and seek exactly (`boss_stages_test`).

Open. Never played on a phone: the numbers are bots'. Knobs:
`SkyBoss.campaignHealthFor`, the warm-up volleys in `sky_boss.dart`,
`BossVanguard.wavesOf`. The boss figures do not open their mouths for the
stage-up roar (the effect plays around them); no new voice lines or sounds
(the stage-up reuses each boss's roar cue, the vanguard the boss warning).

## 2026-10-02 Camera zoom without the pop (optional shared patch, `zoom-pop.patch`)

What was fixed. `BirdGame.render` scaled the whole world by a constant 1.018
whenever the camera's shake offset was not exactly zero, so every hit of every
boss (and every rush knock, gale hit and knockout kick) grew the picture 1.8%
on its first frame and shrank it back on its last, whatever the size of the
shake. Two independent reviews found it, on the Ember Dragon and on New York.
The zoom is now `BirdGame.shakeZoom`: exactly 1 at rest, `1 + 2.2 * max(|dx| /
w, |dy| / h)` while it shakes (a little over the 2.0 that keeps the slid world
covering the screen's edges, which holds up to a shake of 4.5% of the screen;
the game's biggest knock is about 1%). The semantics are unchanged: it zooms
about the centre and slides by the shake. This changes how every boss's hit
feels (a hit used to pop; now it only shakes), so it is its own patch and can
be dropped by deleting `zoom-pop.patch`. Checked by `test/shake_zoom_test.dart`
(7 tests: 1 at rest, the formula, continuity, edge cover, the biggest knock,
the real renderer's transform calls, and a frame on a knock's last instant
equal to the frame after it; the two renderer tests fail on the old constant:
78,689 pixels differ). The comments in `boss_encounter_art.dart` and
`gargoyle_encounter_art.dart` that cited 1.018 now cite the function.

## 2026-10-02 New York fix round merged (M5)

What was built. The thirteen independent fix patches of the New York fix round
(Gargoyle head, body and staging; steam art; King Coo's squadron lanes, payoff
and letterbox; the Alley Pigeon's snatch and gliders; story text and voice
documents; audio; the campaign UI; the Gargoyle's rules; the level data; King
Coo's casual-pilot proof) were merged into one tree on the rebased program
(rules 43, New York open by default, `NEW_YORK_OPEN=false` rolls it back;
co-op and duel stay `coopRulesVersion` 42). Every conflict and its resolution
is listed in the integration handoff. Three merge mistakes the suite found were
fixed in the merge itself: the level card's text growth (`LevelIntroCard._growth`
290 to 310: 3-4's longer hint overflowed the 1.3x card by 5 px), a test that
meant "closed build" with a flag M4 had redefined (`Campaign.closedForTest`),
and a probe bot that re-declared fields `CooBot` gained.

The fixtures were re-recorded ONCE on the merged tree
(`--dart-define=RECORD_FROZEN_NY43=true`), because three fix rounds describe
the same flights: R3's Gargoyle rules (the slit corridor and the lamp judged as
a rock leaves) change the six 3-4 bot flights, the six Gargoyle pilot flights
and the 3-4 tape; R5's level data changes the catalog entries of 3-1, 3-3 and
3-4 and every flight of 3-1 and 3-3; and the casual King Coo pilot of
`ny_pilots.dart` now plans one formation at a time (`CooBot(sequential: true)`,
R2's fix), which changes its two 3-2 pilot flights. 3-2's bot flights, the
sharp and average King Coo pilot flights and the 3-2 tape are byte-identical to
the first recording. The rules 41 fixtures, the 44 endless digests and the 235
scenery hashes are untouched.

King Coo's casual bot, restated. The first fix round measured the casual
`CooBot` (reacts after 0.8 s, 2.5 taps a second) hit by his squadron in 31 of
32 fights. R2's fix round showed that was the bot's policy (it lists every lane
of fury's V and picket at once, which shade the whole sky, and finds no height),
not the rules: a bot that plans one formation at a time, as a player reads the
squadron, is hit in 0 of 32 of the same fights (8 shoot phases at four widths),
and the exhaustive search of R2 finds a safe path from every state. The casual
pilot of `ny_pilots.dart` uses it; the average bot stays as it was (hit in 1 of
32; the same flag at its margin would make it worse, 32 of 32, and at margin
.05 it is 0 of 32), the sharp bot is hit in 0. The single-flight check of the
guardians' fights (`ny_levels_flight_test`) is back to "no hit at all" for both
guardians, and the spread test bounds every pilot at one hit in ten fights. The
paragraph of the level-data entry below that calls the casual hits a thin margin
by design describes the policy of the first recording.

Not covered. Nobody has played any of this on a phone; the 47 guardian clips are
unrecorded and the 29 effects unheard.

## 2026-10-01 New York fix round: level data (R5)

What was built. The independent play review (`reports/21-review-play.md`: 22,000
flights of a model-predictive pilot at four skills, plus R5's own bots with
shifted shoot phases) found three data problems, fixed in
`lib/domain/campaign.dart` only (no rules change):
- **3-1 Moth Light** was the hardest ordinary level (moths were half the
  enemies, so a casual pilot lost 0.66 to 0.90 hearts a minute against 0.25 to
  0.48 on 2-6 and 2-7): now 60 s (81 route stars, marks 40 / 65) and the
  lineup bat, moth, cave bat, beetle (a moth leads the second enemy passage and
  one enemy in four after it; the NEW moth hint stays true).
- **3-3 Steam Alley** wore a casual pilot out (no heart recovery in the level
  times 80 s; steam was only 6% of the hearts lost): now 65 s, seed 3111 (no
  stone door in its first ten passages), 90 route stars, marks 45 / 70, seven
  vents (the steady layer is cut by the shorter route), five pigeon formations
  (nine pigeons, cap 10).
- **3-4 Storm Warning**'s third mark was 30 of 36 run-up stars, out of line
  with the other guardian: now 27 (75%; thief cap 4 over three pigeons).
- **Hints**: 3-3 "Vents hiss, then burst. Hop the hot ones, ride the soft
  ones." (it taught nothing about the soft vents); 3-4 adds "No Sprint here.".

What was checked (before to after; every number is a rate over many flights).
- The review's model-predictive pilot, widths 1.78 and 2.22, 24 seeds each:
  completion % / hearts lost a minute / three stars %.

| level, pilot | before | after |
| --- | --- | --- |
| 3-1 novice | 23 / 3.16 / 23 | 62 / 2.47 / 60 |
| 3-1 casual | 98 / 0.68 / 98 | 100 / 0.32 / 100 |
| 3-1 average | 100 / 0.39 / 100 | 100 / 0.07 / 100 |
| 3-3 novice | 38 / 2.47 / 33 | 69 / 1.92 / 29 |
| 3-3 casual | 98 / 0.56 / 96 | 100 / 0.38 / 98 |
| 3-3 average | 100 / 0.17 / 100 | 100 / 0.04 / 100 |
| 3-4 novice | 96 / 0.39 / 15 | 96 / 0.39 / 81 |
| 3-4 casual | 100 / 0.14 / 46 | 100 / 0.14 / 88 |
| 3-4 average | 100 / 0.00 / 83 | 100 / 0.00 / 100 |

  (Sharp pilots were at 100% before and after.)
- R5's shared bot on 40 re-seeded layouts and shoot phases per cell, completion
  % at 640 / 800 px: 3-1 casual 45 / 72 to 82 / 90, 3-1 sharp 70 / 75 to 90 /
  90, 3-3 casual 62 / 82 to 88 / 95, 3-3 sharp 72 / 75 to 98 / 90. On the
  shipped layouts of 3-3 over 40 shoot phases: casual 72 / 55 to 100 / 100,
  sharp 90 / 57 to 100 / 100.
- The whole-level pilots of the suite (`ny_pilots.dart`, R2's and R3's guardian
  bots), now flown over 8 shoot phases at four widths (1.6, 640, 800, 2.4) and
  on six re-seeded layouts, with every hit attributed to its cause
  (`test/ny_levels_spread_test.dart`): sharp and average pilots complete at
  least 90% and casual pilots at least 75% of every cell (shipped layouts:
  100% everywhere; re-seeded 3-1 96 to 99%, 3-3 90 to 94%). Before, the same
  pilots finished 3-3 in 72% (sharp), 94% (average) and 63% (casual) of the
  shipped-layout phases. The Gargoyle touches no pilot at any phase, width or
  skill (no beam, no feather); King Coo hits at most the squadron's first
  picket and a cloud on a wide screen.
- Marks, with the thief caps: 81 / 36 / 90 / 36 route stars; the pigeons' worst
  case (0, 3, 9, 3) is inside the caps (8, 3, 10, 4); a perfect collector that
  never shoots earns the third mark on six layouts of every level;
  sharp and average pilots earn three stars in 90 to 100% of the phases on 3-1,
  3-2 and 3-4 and in 40 to 100% on 3-3 (those pilots never aim at a ride vent's
  stars and collect about 70 of 90; the review's planners reach 96 to 100%).
- Fixtures re-recorded on purpose (`frozen_ny43.json`, `frozen_ny_tapes/`):
  the catalog entries of 3-1, 3-3 and 3-4; 18 of 27 bot flights (every flight of
  3-1 and 3-3; the five 3-4 flights that finished moved only in their level
  stars, 2 to 3, with identical checkpoints: the mark does not move a flight);
  5 of 17 pilot flights (3-1 and 3-3); the 3-3 and 3-4 tapes. 3-2 is
  byte-identical, tape included. New: a legacy tape of 3-3 as shipped before
  (80 s, seed 3103, cut at 40 s), which proves a retuned level still replays a
  flight saved before. The rules 41 fixtures, the endless digests and the
  scenery hashes are untouched.

King Coo's squadron and the casual bot (for the King Coo rules fixer). The
casual `CooBot` (reacts after 0.8 s, 2.5 taps a second) takes a squadron hit,
on the shield, in 31 of 32 fights (8 shoot phases at four widths), a cloud in
1 of 32; sharp and average bots 0 and 1 of 32. The numbers: his telegraph runs
from the puff (7.6 s of the cycle) to the lane crossing the bird's column, 2.8
s at 1.6 screen heights wide, about 3.0 s at 640 px, 3.5 s at 800 and 3.8 s at
2.4 (R2: the crossing is 1.22, 1.94 and 2.23 s after the whistle at 1.6, 2.2
and 2.4 wide). The exact search at 2.5 taps a second (the
review's port of R2's proof; `reports/21-review-play/coo-viability-by-taps.txt`)
finds a safe path from every state, but only if the player starts steering
within 0.9 s of the puff on a 1.6-wide screen, 1.0 s at 640 px, 1.8 s at 800
(the V 1.3, 1.4, 2.0 s; the bomb 0.7 s; at 2 taps a second the picket has 0.4
to 0.5 s). A casual reaction is 0.7 to 1.0 s, so at the narrow phones the
slack is thin by design. The bot's hit is not that slack alone: the same bot
with its look-ahead (`squadLook`, 1.6 s before the crossing) and tap rate
varied (`test/ny_coo_squadron_probe_test.dart`, run with
`--dart-define=NY_COO_PROBE=true`) is hit in 12 of 12 phases at every width
at 2.5 and at 5 taps a second whatever the look-ahead (1.6 to 2.8 s), and passes
only in scattered cells at 3.5 taps (non-monotone in the look-ahead), so a
heuristic planner cannot separate the data from itself. Verdict: not a data
fault (the search finds paths), but a margin that a 2.5 taps a second player
with a casual reaction and 80 ms of thumb lag does not have (the review's
human-lag fights, casual: 3 to 14 of 20 fights hit by a squadron at 80 ms of
lag). If the owner wants a casual reaction to be safe at 640 px, the picket and
bomb telegraphs need 0.3 to 0.5 s more lead (the whistle earlier, or the
squadron slower at narrow widths); this tree changes none of King Coo's
numbers.

What is not covered. Nobody has played these levels; the pilots are proxies,
the absolute rates are not a human's, and the playtest is still the gate. 3-3's
third mark (70 of 90) sits where crude pilots collect 69 to 72 stars. The
Gargoyle's lamp-window and slit fixes, the 1.6 to 2.4 letterbox (below 1.6 the
pigeons never snatch, so the card hints are false on a 4:3 tablet) and the
retry cost of a guardian (30 s of run-up again) belong to others.

## 2026-10-01 New York rebased onto Fly Together, renumbered to rules 43, opened by default

What was built. The New York program (the Alley Pigeon, steam geysers, King
Coo, the Searchlight Gargoyle, chapter 3's New York stop, story, audio, UI)
was applied onto the main tree as it stood after Fly Together (co-op and the
1 v 1 duel, `coopRulesVersion = 42`) and the in-flight voices were added.
New York is now **rules version 43** (`FlightSimulation.newYorkRulesVersion`,
`currentRulesVersion`, `LevelPlan.minRulesVersion`, the three `supports…`
getters): a New York plan refuses to fly at 41 or 42 and a New York tape is
refused below 43; endless, chapters 1 and 2 and every co-op and duel flight
fly at 43 exactly as at 42 and 41. The stop is **open by default**
(`Campaign.openingEnabled` defaults to true, so `make build` and `make
install` ship it; `--dart-define=NEW_YORK_OPEN=false` closes it, and
`make build DEFINES=--dart-define=NEW_YORK_OPEN=false` is the rollback).
`CampaignProgress.totalStars` (and `starsInChapter`, `starsInRegion`) count
only levels the build can fly, so a closed build never shows more than its
"N / 48".

How the two programs compose. Every new hazard looks at every bird of
`FlightSimulation.flock`, reads `bird.x`, aims with `_target` (the lead
first, then the birds in turn) and hurts the bird it found with
`_hurt(bird)`: steam scald and lift, King Coo's rings and clouds, the
Gargoyle's beam, aim and feathers (boss ammunition now hurts through
`_hurt` too), the pigeon's dive spacing (the foremost bird) and the star a
ram or touch frees (the nearest bird). With one bird every one of them is
the old code to the last digit: the 27 + 17 + 3 frozen flights re-recorded
at 43 differ from the ones recorded at 42 only in the version numbers.
Co-op and duel can never meet New York: they refuse every level plan, and
endless flights of all three modes lay no pigeon, vent or guardian.

What was verified.
- `flutter analyze` is clean. The whole suite passes with the default
  (open) build: 2975 passed, 199 skipped (the opt-in capture and review
  tests), 0 failed; and with `--dart-define=NEW_YORK_OPEN=false`: 2975
  passed, 199 skipped, 0 failed. No timing test failed in any full run
  (load average 3 to 38; one run that hit a full disk was discarded and
  repeated).
- The strict envelopes pass: `DRAGON_ENFORCE=true DRAGON_CYCLES=70`
  (envelope and budget, 20 tests), `KING_COO_ENFORCE=true
  KING_COO_CYCLES=12` (envelope, budget, silhouette, 25) and
  `GARGOYLE_ENFORCE=true GARGOYLE_PHASES=40` (envelope, budget,
  silhouette, 19).
- Fixtures: the R0 rules 41 fixtures (16 levels, 46 flights, 3 tapes), the 44
  endless digests and the 235 scenery hashes are byte-identical, and every
  frozen flight is now also flown at 42 and at 43 (`frozen_rules41_test`).
  `frozen_ny42` became `frozen_ny43` (and its three tapes carry version 43):
  re-recorded from this tree, and equal to the old recording apart from the
  version numbers and the tapes' hashes. Main's own co-op and duel tests
  (`coop_flight_test`, `coop_art_test`, `coop_ui_test`, `duel_flight_test`,
  `duel_art_test`, `duel_ui_test`) pass untouched.
- New tests: `ny_flock_test` (18: no New York in co-op or duel; every hazard
  with a second bird in the flock, each proven to bite by a mutation),
  `ny_flight_voices_test` (guardians silent, pigeon not spotted),
  `ny_hardening_test` (the Gargoyle's name card at no height, the pigeon
  marks on non-finite numbers), 3 new lair-scene flow tests, the 43-against-42
  and 43-against-41 endless digests, the 42-refusal checks and the flag
  hooks' own tests. The 12 tests that asserted the closed default now assert
  the open one and cover the closed state through `Campaign.closedForTest`;
  every flag-sensitive test forces the state it means, so the suite passes
  under either define.

What is not covered. Nobody has played New York on a phone; the 47 guardian
clips are still unrecorded and the 25 effects unheard (see the entries
below); the two guardians have no in-flight voice lines.

## 2026-10-01 King Coo fix round (K8)

What was fixed (the independent art and motion reviews): the victory had no
payoff (a small dark cap in a dark corner): now a shower of crumbs and
feathers, the cap landing at 1.4x in the middle of the screen with a coin spin
and a siren pool, the badge floating beside it and three pigeons pecking at
the crumbs; the puffed chest, the game's one mechanic, was under-sold: a bold
amber ring, a warm heart, an "x2" roundel, a halo with ripples, and feathers
standing up while it swells (the hit circle stays exactly r 1.00); the name
card's quote was 12 px at alpha .4: a plank, larger type, an alpha floor of
.8 and a later type-on; his letterbox now equals the dragon's and the
Gargoyle's at every age (it stayed shut for his COO!); the squadron were
clones: three plumages by slot and a bank each (the art-pigeon fix round
added a size and a wingbeat tempo each: one `PigeonPose.squadLook`). Checked by
`test/king_coo_fix_test.dart` (21 tests) and the existing King Coo suites with
real-art enforcement on; the hide's own op limit went from 70 to 74 (the
window's gold), the rig's 210 and the staging's budget (worst frame 328 draws,
2 layers, no shader after the first frame) hold.

## 2026-10-01 New York: King Coo and the Searchlight Gargoyle (art, staging)

What was built. King Coo's staging (K8) and the Searchlight Gargoyle's (G8) had
each been assembled alone from the same base; they are now one tree. The two
patches overlapped in `boss_encounter_art.dart`, `boss_health_bar_art.dart`,
`story_boss_art.dart`, `campaign_keepsake_art.dart`, `sky_boss.dart` and
`boss_polish_encounter_art_test.dart` (and in the docs); each overlap was
resolved so both bosses keep an explicit arm in every dispatch (no
fall-through to the Baron, no shared arm). What the two builders could not do
alone: the victory card now says GUARDIAN DOWN! for both
(`BossEncounterArt.victoryTitle`; King Coo's still said SKY RECLAIMED), and the
spec has a Presentation paragraph for each guardian and a "Guardians in the
encounter" subsection.

What was verified.
- `flutter analyze` is clean and the whole suite passes: 2824 passed, 199
  skipped (the capture and review tests), 0 failed; the sum of the base (2170),
  K8's 282 new tests and G8's 351, plus 21. No timing test failed. Both
  contract envelopes also hold at their long settings
  (`KING_COO_CYCLES=6`, `GARGOYLE_PHASES=40`), with both enforcement switches
  on by default. R0's fixtures (`frozen_rules41`, the 44 endless digests, the
  235 scenery hashes) and R5's `frozen_ny43` (recorded at 42, re-recorded at 43 by the rebase) pass untouched: endless and
  chapters 1 and 2 fly exactly as at 41, and the only rules-side lines the
  guardians add are two render-only fields (`SkyBoss.cancelledSquad`,
  `SkyBoss.lastSpotAt`).
- `test/ny_guardians_stage_test.dart` (21 tests) flies the catalog's 3-2 and 3-4
  with the real rules and renders a whole encounter of each through the real
  game at 640 and 800 px (arrival, a calm beat, a hit into fury, the puff and
  the whistle with the squadron at his back and in the open, the Gargoyle's
  sweeps and feathers, the vent, the killing blow, the defeat, the victory
  card), and in the same process the other boss's, so shared caches cannot
  differ. Each boss pass equals his own stage byte for byte and is neither the
  Baron's fall-through nor the other guardian's at every beat. It also pins:
  one eyebrow word (GUARDIAN), one victory title equal to the result screen's
  word, no player-facing "mini-boss", both name cards handed the level's line,
  both story adapters and keepsakes in `StoryBossArt` and `CampaignHeadwear`,
  the squadron pigeons held back from the shared pass for King Coo alone and
  drawn for the Gargoyle, his feathers drawn by his stage and never by
  `CombatArt`, and the real game's pass order. Mutation-checked: removing King
  Coo's dispatch, making the victory title the Gargoyle's alone, or dropping
  the line from the Gargoyle's card each fails it.
- A sheet of the merged tree's King Coo frames is pixel-identical to K8's own
  except for the victory title; both victory cards read GUARDIAN DOWN!.

What was NOT verified.
- Nobody has played either fight on a device or watched the arrival on a phone:
  every picture is the test renderer at 640 and 800 px over New York at night.
  The fights' lengths are those of bots that never miss or dither (a
  first-timer is expected to need about a minute against King Coo and
  62 s or more against the Gargoyle): the playtest is the gate.
- The audio was measured against the pictures (envelopes, 60 Hz steps), never
  heard. King Coo's reveal sound leads his flash by 0.25 s; the Gargoyle's
  victory sound follows its card by 0.25 s; the tower's slide, the pigeons'
  flush, the distant thunder and the visor's clatter have no cue.
- The casual-bot loss in Steam Alley (3-3) at 640 px (a bot tapping 2.5 times a
  second with no charged shots loses it with all its hearts; it finishes at
  800 px) is still open: a human playtest should say whether 3-3 wants a
  gentler lineup.
- The voices are unrecorded: the 47 guardian clips (`docs/story-voices-sources.json`
  and the new speakers' proposed voices) and the in-flight card lines have no
  audio, so every scene and card is paced as with Character voices off, which
  is all that was checked. (`flight_voices.dart`'s `bossKey` arms for the two
  guardians, missing from this tree, were added by the rebase onto main.)
- The opening flag (`Campaign.openingEnabled`) was still off when this entry
  was written (it is open by default since the rebase, see the top entry).
- King Coo's letterbox does not open for his COO! and closes in 0.2 s later
  behind his defeat than the Gargoyle's and the dragon's do; kept as built.
- The tree had not been rehearsed on the current main tree, which had moved
  (voices, settings, audio, Fly Together): the rebase entry above does that.

## 2026-10-01 King Coo's staging (K8)

What was built. The finished King Coo parts (K1 contract, K2 head, K3 body and
hide, K4 wings, K5 crumbs, K6 squadron lanes, K7 health bar and effects) were
assembled and staged in the encounter in the Ember Dragon's method: an
explicit king branch of `BossEncounterArt.paint`, backdrop, foreground and
letterbox (never the Baron's fall-through), arrival, hit, fury, pop and
defeat, the cap that falls off, his squadron drawn under him, the six story
portraits (`KingCooStoryArt`) and the keepsake cap. The neck ruff joined the
hide (its outline was the last seam between head and body), the inhale tilt
was eased so the beak leads in every pose, and the contract's real-art
envelope and budget checks now run by default.

What was checked. `test/king_coo_staging_test.dart` and
`test/king_coo_story_art_test.dart` (see the specification); the whole suite;
rendered review sheets at 640 and 800 over New York at night, with Reduced
Motion, and a 30 fps video of a whole encounter. Not covered: nobody has
played the fight; the audio cues are not auditioned; the reveal sound leads
the flash by 0.25 s (as the dragon's does).

## 2026-10-01 New York stop (level data, R5)

What was built. 3-1 to 3-4 carry the owner-approved structure: 3-1 Moth Light
unchanged; 3-2 Wheels in the Rain is a 30 s run-up that introduces the Alley
Pigeon (flocks 1, 1, 1) and King Coo (140 HP); 3-3 is renamed Steam Alley (80
s, eight vents hop and ride alternating, flocks 1, 2, 2, 2, 2, 2, no Swarm
rush); 3-4 Storm Warning is a 30 s run-up (flocks 1, 2, three vents, no
Sprint) and the Searchlight Gargoyle (160 HP). The Swarm rush and the Gale
live in Paris (3-6 and 3-7 keep their set pieces and gain NEW hints; Paris
stays closed). The two guardians' card lines are their levels' `bossLine`s.
The opening is behind `Campaign.openingEnabled` (off when this was written;
open by default since the rebase).
Merged first, in this order: the UI patch (map shields, GUARDIAN ribbon,
"Guardian down!", "To be continued" card), its optional last-word hook, and
the Alley Pigeon's art. The in-flight name card now says GUARDIAN (it said
MINI-BOSS).

What was checked.
- The marks come from the real routes: 96, 36, 114 and 36 route stars, marks
  50/75, 20/30, 55/90 and 20/30 (50% and 80% rounded to fives), and the
  pigeons' worst case (3, 11, 3 stars) sits inside each level's cap (3, 12, 3).
  A perfect collector that never shoots earns ★★★ on all four (and the stars
  of a guardian's run-up reach the third mark); mortal sharp and average
  pilots earn three stars on every level at 640 and 800 px wide; never
  shooting still earns ★★ with a wide margin (`test/ny_star_marks_test.dart`).
- Whole-level pilots (`test/ny_pilots.dart`, `ny_levels_flight_test.dart`)
  complete every New York level and beat both guardians at 640 and 800 px,
  mortal, with the base weapon the campaign gives: King Coo in 11.6 to 36.3 s
  of combat (sharp, average, casual), the Gargoyle in 34.8 to 80.0 s. The
  fight costs a pilot that reads the telegraphs nothing. A pilot hammering
  Sprint through King Coo's whole fight meets the same ring times and is hurt
  no more; 3-4 refuses Sprint whatever is pressed.
- Frozen at 43 in new files (`frozen_ny43_test.dart`): the four plans and
  routes, 27 bot flights, 17 pilot flights (a guardian win for each at both
  widths and three skills) and three saved tapes (King Coo at 640, the
  Gargoyle at 800, a whole Steam Alley). The rules 41 fixtures (16 levels,
  46 flights, 3 tapes), the 44 endless digests and the 235 scenery hashes pass
  untouched.
- Catalog rules (`ny_campaign_data_test.dart`): a boss level holds no set
  pieces (and refuses one), a guardian ends no chapter, and its win opens the
  next level only (no postcard, no seal, no chapter unlock), the open stop's
  progression, the star total (48 closed, 60 open), both states of the flag.
- The nine guardian flow tests the UI step had to skip run against the real
  data, as do the last-word tests; 3-3's lock note names King Coo.
- With the flag off the map, the story scenes and the results render
  byte-identically to the tree before the program (154 of 160 pictures); the
  six that differ are the level cards of 3-2, 3-3 and 3-4, whose data changed.
- `flutter analyze` is clean; the whole suite passes (2170 passed, 129
  skipped capture tests).

What is not covered. Nobody has played the levels: the fight lengths are
those of bots that never miss or dither (the designers' models say a
first-timer needs about 60 to 90 s against King Coo and 62 s or more against
the Gargoyle), so the playtest is the gate. Steam Alley is the stop's
hardest level for crude pilots: a casual bot (2.5 taps a second, no charged
shots, one shot in 0.75 s) loses it at 640 px (it finishes with its hearts
topped up, and mortal at 800 px). All pilots are Tap & Fly; the push-up modes
have no enemies. The two guardians' art is still a placeholder, the voices
(47 clips) are not recorded and the New York sound effects have not been
listened to. Paris is data only. Nothing was run on a device.

## 2026-10-01 New York rules, audio and steam art merged (M1)

- The pigeon and steam rules (R1), King Coo (R2), the Gargoyle (R3), the
  story, the audio and the steam art (hook only) are one tree. The pieces that
  span agents are tested in real flights, not with counters set by hand:
  - `test/ny_merge_squad_test.dart`: King Coo's squadron are Alley Pigeon
    gliders (no prey, no raid state, on their tracks, never snatch a star
    that lies in their way), a rock or a ram defeats one and raises both
    `enemiesDefeated` and `pigeonsDefeated`, a touch or the boss's defeat
    raises neither.
  - `test/ny_merge_audio_test.dart`: the combat and boss cue classes are fed
    after every step of real flights (a flock raiding, a thief shot, a whole
    Steam Alley, King Coo's whole fight with the squadron and the pop, the
    Gargoyle's whole fight, a bird in his beam, a glance off his lamp) and each
    cue must play on the step its counter rises and on no other, for every
    counter the audio reads.
  - `test/ny_merge_guardians_test.dart`: the two test-only guardian plans
    agree with the story on every key, refuse a rules 41 flight, are flown to
    their finish, and the story plays whether or not a voice is recorded.
  - `test/ny_merge_steam_art_test.dart`: every vent of four real routes goes
    through the art's budget and envelope checks with the plume tops the rules
    compute, and real flights are painted at 640 and 800.
- One test assumption was corrected: `king_coo_test` expected no pigeon raids
  in the fight because, when it was written, the run-up's pigeons were inert.
  The squadron must add nothing to the raid counters; it does not.

## 2026-10-01 Steam Geyser art

- `lib/game/steam_geyser_art.dart` (and its emitter, plume and kit files)
  draws the vents in three phases with the bird's feedback, from two calls in
  `bird_game.dart`: 26 to 58 draw calls a vent, at most 148 for three vents
  and the feedback, no layer, blur, shader or clip, Reduced Motion still
  frames per phase. `test/steam_geyser_art_test.dart` (17) pins the budget,
  the determinism, the plume against the hit and lift boxes, and that the
  bird and stars are never covered. The optional New York roof stacks were not
  landed (they change the endless scenery baselines).

## 2026-10-01 New York sound effects

- 25 cues in 32 files, all synthesised (`tool/prepare_sound_effects.py`, no
  network, no source take), mastered and measured with
  `tool/check_sound_effects.py`; every earlier WAV is byte-identical.
  `docs/sound-effects.md`, "New York cues", has each cue's parameters,
  seeds, measurements and audition order. Nobody has listened to them yet.
- `test/new_york_sound_assets_test.dart` (64) checks the packaged files
  (format, length, headroom, clipping, DC, loudness bands, phone band, each
  cue's shape) and `test/new_york_audio_cues_test.dart` (27) the wiring with
  the counters driven by hand.

## 2026-10-01 New York story and voices: review fixes

- Story review (`reports/24`): the four logic slips and the over-long lines of the
  four guardian scenes were fixed before anything was recorded. The Gargoyle's chipped
  beak (he is a stone eagle), the courier's bread-cart reveal ("I remember a bread cart
  under the theatre marquee" instead of "we passed it"), the tower's weather vane (not
  the Gargoyle's) with "I couldn't look away" answering "You looked" (now a happy
  line), King Coo's job as his own title ("Commissioner wanted. Pay: a hot bagel a
  day"), "guardian" said by Bill, "Vents hiss before they burst" (not "pipes"), "night
  mail" (not "night post"), "Step into the light, darling", "Ninety-odd years", the
  pigeons gag paid off ("And yes, the pigeons may stay"). Every line of the four
  scenes is at most 85 characters (the longest recorded line is 82). Bill's tip
  names the squadron's open lane, as the HUD tag `OPEN LANE = GO` and `SkyBoss.cooHint`
  ("Follow the open lane!") now do; the three tests that pinned "green lane" changed
  with it. No recorded clip, no chapter 1 to 3 line and no Dusk Empress line changed.
- Voice documentation: `docs/story-voices-recording.md` lands the recording
  checklist in the tree (a walkthrough from zero to one recorded clip, the backup,
  the export format and settings, the 14 audio tags no recorded take has used with
  proven stand-ins, the audition, the clip list). `--checklist` now rewrites only the
  generated section between two markers (it used to print a list that replaced the
  whole document); `--tags`, `--voices` and a one-line `--status` on a clone without
  the takes are new. The sources file records the export format; the cast table has
  every voice id. King Coo's first fallback is Rusty Malone. `campaign_voices_test`
  (+3) checks the document is as fresh as the sources file, that `--checklist` leaves
  everything outside the markers alone, that `--status` summarises missing takes,
  and that every unproven tag is documented; `campaign_story_test` (+1) pins the
  fixed lines. `sky_audio_test` no longer fails in a checkout under a folder named
  `story` (it checks `audio/story/`).
- `docs/campaign.md` says the campaign is Tap & Fly only.

## 2026-10-01 New York story and voices

- Four guardian scenes (`before-3-2`, `last-3-2`, `before-3-4`, `last-3-4`)
  bring the story to 27 scenes; `CampaignStory.lastWord`,
  `CampaignProgress.sceneLast`, `StoryScene.bossBeaten` and
  `StoryLine.endOfStop` (the "To be continued…" caption that closes the
  stop) are the new interfaces. No scene, line, clip or id that existed
  changed.
- Their 47 clips are in `docs/story-voices-sources.json` as *pending
  recording* (no voice id, generation or hash, no audio): the game prints the
  lines and plays nothing for them, paced like voices off. The cast table and
  the recipe for a new character (`docs/story-voices.md`), the recording
  checklist and the new `--status`, `--checklist` and `--source-dir` options
  of `tool/prepare_story_voices.py` (which skips pending clips) are the
  owner's way to record them. The 308 source takes exist only in
  `build/story-voices/source/`, which is git-ignored: back them up.
- `campaign_story_test.dart` (13): delivery checks keyed on the chapter boss
  and guardians, scenes before each region, chapter boss and guardian (20),
  the order of the 27 scenes, the guardians' last words (no flame seal, Bill
  speaks last), the closing caption, the guardians' card lines, `sceneLast`.
  `campaign_voices_test.dart` (17): every line, thank-you and sprint clip is
  recorded or pending; the sources, the clip table and the printed lines agree;
  the checker fails for a recorded clip that is missing from the table, a
  table clip still pending, a recorded clip without voice, generation or hash,
  and a text or prompt that speaks other words than the printed line (the
  spoken words equal the printed words for every line, IPA pins and audio tags
  aside); pending clips have no audio; `--status`, `--checklist` and the
  script's skipping of pending clips run under Python; scenes with no
  recording play silently at the pace of voices off.
- Rehearsed on a copy: one pending clip recorded by hand (entry filled in,
  script run with `--only`) turns the tests green; before the script runs, the
  test names the clip that is not in the table.

## 2026-10-01 Searchlight Gargoyle art and staging (G8)

What was built. The Gargoyle's parts (head, body, wings, beams, feathers,
plate and card) are assembled and staged in the real encounter
(`gargoyle_encounter_art.dart`, `gargoyle_staging_art.dart`,
`gargoyle_story_art.dart`): the tower, the arrival (storm, lightning, stone to
life, roar, card, letterbox), the fight's hooks (beams under the backdrop, the
feathers after the rig, the plate's feather pass, local jolts), the defeat
(white-out, burst, rubble, pigeons, visor, two lit lenses), Reduced Motion, the
story portraits and the keepsake. `GargoyleLayout.ledgeLip` is -3.0 (the nest),
`visorBounds` and `crackSeeds[1]` follow the real art, `GargoylePose.damage`
(health lost) grows the body's hairline cracks from the first hits.

What was checked.
- `test/gargoyle_staging_scan_test.dart`: in 86 arrival, fight and defeat
  states at 640 and 800 px, with and without Reduced Motion, none of his solid
  pixels is clipped by the layer bounds, the screen or the letterbox; a whole
  fight flown by the pilot through the real game renders every phase (arrival,
  card, perch, warning, both sweeps, the slit, vent, hit, glance, fury, feathers,
  defeat, victory card, rubble); the joins (arrival to fight to blow, the
  fade-in, the flock's lift-off, the nest pigeon) have no pop.
- `test/gargoyle_staging_test.dart`: the hooks, the letterbox (the dragon's
  timing), one bounded layer at most and no blur, the frame's budget, Reduced
  Motion, a broken clock, and every audio cue's edge against its picture's
  (within one 60 Hz step; the victory sound is .25 s after its card, as the
  dragon's).
- `test/gargoyle_story_test.dart`: the six moods, the stage's box, the vane
  and crest pigeon, the keepsake, both lair scenes.
- Found and fixed on the way: the plate's gauge glint threw in the real game
  when his health fell below half a bar height (an inverted clamp); the contract's
  silent `runAsync` tests now report; the body's crack no longer drops to nothing at the
  killing blow.

What was not covered. Nobody has played the arrival on a device; the audio
files were measured against the picture, not heard; the in-fight lightning has no
thunder (there is no cue for it).

## 2026-10-01 Searchlight Gargoyle fix round (rules 43)

- The play review (`reports/21`, D1 and D4) and the motion review (`22`, the
  fan blades) found three defects in his rules; all three are fixed, with the
  numbers before and after in `test/searchlight_gargoyle_fairness_test.dart`
  and `searchlight_gargoyle_fix_test.dart`:
  - **The fury slit** closed to a .214 corridor that a tapping hover (a .13
    bob) held 52 to 70% of the time at 50 to 100 ms of thumb lag with 40 ms
    of jitter. The inner beam ends moved from .26 and .74 to .21 and .79
    (corridor .314): the Monte Carlo of the review (`test/gargoyle_lag.dart`)
    gives 95 to 99% there (lag 0 to 100 ms, jitter 0 and 40 ms; the review's
    pick, .22/.78, gave 89% at 100 ms/40 ms). The exhaustive search finds a
    safe path from all 117 starts at a 0.08 margin of error, 5 and 2.5 taps a
    second (0.04 before); the zone sweeps stay at 97% or more; a planner that
    knows its lag beats a whole fight, beams, feathers and fury together, at
    0, 50 and 100 ms without a scratch.
  - **The lamp** was judged where a rock lands, so the usable fire window sat
    0.35 to 0.76 s earlier than the visible vent, by screen width. It is
    judged as the rock leaves (`BirdRock.releasedAt`): 2.6 s at every width
    (the same trigger finger deals 90 damage at 1.5, 1.6, 1.78, 2.2 and 2.4
    wide; judged on landing it counted 8 rocks of 9 on the narrowest sky and
    7 on the widest). Fights are shorter for it: the sharp pilot 26 s (33),
    the average one 53 to 81 s, the casual one 99 to 170 s.
  - **`SkyBoss.previousHitAt`** (render-only): the hit before the last, so
    the fan blades stop snapping on every re-hit.
- Re-recorded on purpose (`RECORD_FROZEN_NY43=true`), the Gargoyle's
  fixtures only: the six 3-4 bot flights (`3-4`, `3-4@w1.6`, `3-4@w2.4`,
  `3-4@dmg10`, `3-4@mortal`, `3-4@w2.4,dmg10,mortal`), the six Gargoyle pilot
  flights and the tape `campaign-3-4-gargoyle-800`. The catalog, 3-1 to 3-3,
  King Coo and the other two tapes are byte-identical.

## 2026-10-01 Searchlight Gargoyle rules (rules 43)

- The Gargoyle's rules replace his scaffold stubs (`docs/specification.md`,
  "Searchlight Gargoyle"): the beam that hurts like a course edge, the lamp
  that only takes damage in the 2.6 s vent, the stone feathers, the aim latch
  and fury's alternating slit. No random draw; endless and chapters 1 and 2
  still fly as at 41 (the frozen fixtures pass unchanged).
- `test/searchlight_gargoyle_fairness_test.dart` ports the report's
  exhaustive tap-sequence search (`test/gargoyle_viability.dart`, reading the
  shipped rules): at five taps a second every one of the 351 survivable start
  states has a safe path (calm zone, fury zone, slit; 324 after 0.3 s and 303
  after 0.45 s without a tap; the whole cycle from the perch feather too), and
  the 1.5 s warning is fair down to 1.3 s (0.7, 0.9 and 1.1 s leave 31, 14 and
  2 unwinnable starts).
- `test/searchlight_gargoyle_test.dart` flies the rules through real level
  flights: the aim latch, the lit band to the last hair, shield then heart,
  shuttered and open lamp (rocks, charged shots, shatter blasts), fury's zone
  then slit alternation, feathers at every width, cutscenes, the counters the
  audio reads, determinism, pause, a recorded level's replay and backward
  seeks, and the 351 proof starts flown through the simulation with the
  search's own taps. A pilot that re-plans with the search wins without a
  scratch at 640 and 800 px wide.
- `test/searchlight_gargoyle_fight_test.dart` pins the fight's length
  (base weapon, 160 health): a sharp player 33 s, an average one 62 s, a
  casual one 80 to 100 s, without his 4.6 s arrival and 3.8 s defeat.

## 2026-10-01 King Coo rules (rules 43)

- King Coo's fight (`lib/domain/king_coo_rules.dart`) replaces his scaffold
  stub (`docs/specification.md`, "King Coo"). It is a pure function of the
  boss clock: no random draw, exact at any tick size, and a seek re-simulates
  it exactly.
- `test/king_coo_test.dart` pins the cycle to the tick (locks, launches,
  bursts, the puff, the whistle), the clouds' hurt radius to their drawn
  radius, the fluffed, puffed and popped chest, the squadron's lanes at four
  screen widths, what a touch, a rock and a ram do to a squadron pigeon, the
  counters, a recorded fight replayed with scrambled seeks and the test-only
  3-2 guardian. `test/king_coo_fair_test.dart` ports the report's fairness
  proof (a bird tapping at most five times a second has a safe sequence from
  every state that survives the screen edges, for every hazard and both
  chains) and flies the search's own policy through the real simulation: 104
  runs, never a lost shield or heart, against the same runs that ignore the
  telegraph, which are hurt in at least 8 of 10.

## 2026-10-01 Alley Pigeon and Steam Geysers rules (rules 43)

- The Alley Pigeon's raids (`lib/domain/alley_pigeon_rules.dart`) and the
  steam vents (`lib/domain/steam_rules.dart`) replace their scaffold stubs
  (`docs/specification.md`, "Alley Pigeon" and "Steam Geysers"). Neither draws
  from the flight's shared random, so a level's route, passages and enemies
  are the same with and without them (tested), and endless and chapters 1 and
  2 still fly as at 41 (the frozen fixtures pass unchanged).
- `test/alley_pigeon_rules_test.dart` (formations and star binding, the
  telegraph at four screen widths, the dive, the snatch, every way a hit, a
  ram or a touch ends a raid, squadron gliders), `alley_pigeon_replay_test`
  (three recorded flights replayed at every checkpoint, backward seeks, tape
  round trip, re-recording identical, refusal at 41) and
  `alley_pigeon_economy_test` (the worst cases against the three-star marks:
  a collector who never shoots always earns three stars, over twelve seeds per
  level; the run-time thief cap).
- `test/steam_test.dart` (laying, plume tops, scald, lift and ride, what Sprint
  does not do, counters, the boss clearing the vents), `steam_reach_test` (the
  reachability proof ported from the report: 12 rows of 870 starts, none
  scalded, with teeth, plus 120 real flights of a 2.5 to 3 taps a second
  player who touches no hop vent) and `steam_replay_test`.

## 2026-10-01 New York scaffold (rules 43)

- Rules version 43 and the New York interfaces landed before any of the
  specials' rules (`SCAFFOLD.md`, in the program tree). Endless and chapters
  1 and 2 are guarded by fixtures recorded from the untouched rules 41 game:
  - `test/frozen_rules41_test.dart` pins the 16 playable levels' plan JSON
    and laid routes, 46 bot flights (every level, narrow and wide screens,
    both bosses, the base weapon, pilots that lose hearts or the flight) as
    state digests with their outcomes, and three saved rules 41 tapes (one
    endless, two campaign). Every flight is run at 41 and at the current
    version and must match. Each tape must reload, re-encode to the same
    bytes, replay to its digest and be re-recorded identically. Re-record
    only with `RECORD_FROZEN_RULES41=true`, from a tree that flies 41 as
    committed.
  - `test/endless_plan_baseline_test.dart` also checks that 43 flies endless
    exactly like 42 and 41, and that no endless flight at any version meets a
    campaign-only boss or enemy. The 44 endless digests and 235 scenery
    frames pass unchanged.
- `rules43_version_test` checks the version getters, `minRulesVersion`, the
  constructor and tape guards and the plan JSON. The scaffold tests cover the
  pure cycles of each special; `mini_boss_damage_test` runs the endless
  bosses' damage checks through a level; `ny_placeholder_art_test` fails if
  a new kind is drawn like another kind; `campaign_opening_test` and
  `campaign_opening_screens_test` cover the partial opening and guardians.
- The suite passes: 1507 passed, 111 capture tests skipped. The systems
  report's seven breakages were updated with comments, none deleted.

## 2026-09-30 Story voices

- The campaign's characters speak (`docs/story-voices.md`). 308 clips were
  recorded with ElevenLabs Eleven v4, one generation each:
  - every line of the 23 scenes, with the courier's 42 lines recorded once
    per bird;
  - the 40 thank-you notes;
  - four sprint calls per bird.
  The cast is 45 library voices, and every prompt carries audio tags for its
  delivery. `docs/story-voices-sources.json` lists each clip's voice,
  prompt, generation id and source hash. `tool/prepare_story_voices.py`
  trims, levels (−18 LUFS) and encodes them: 1044 s of speech, 9.3 MB of
  mono Ogg Vorbis in `assets/audio/story/`.
- In the game:
  - scene lines play their recording and write out over 90% of it;
  - a finished level's thank-you is read out as its note lands;
  - sprints call out in the equipped bird's own voice;
  - the music ducks to 35% under speech.
  Settings → Character voices (on by default) turns it all off. The
  settings panel was redesigned to fit a fourth switch.
- Tests:
  - `campaign_voices_test.dart` (6):
    - every line, thank-you and sprint call has its clip, and nothing
      extra is recorded;
    - each clip is Ogg of a believable length and pace;
    - the whole set stays under 12 MB;
    - a scene speaks each line in its speaker's voice (the courier as the
      equipped bird) and hushes when it ends or is skipped;
    - it says nothing with voices off;
    - a spoken line is written out just ahead of its voice.
  - `sky_audio_test.dart` adds:
    - Pip's and Orbit's own sprint calls, never repeating the last;
    - no sprint call with voices off;
    - a spoken line ducks the music until it ends or is hushed, and a new
      line cuts off the last.
  - `campaign_screens_test.dart` adds a finished level reading its
    thank-you once and a knockout saying nothing.
  - The settings tests now cover four switches. `settings_ui_test` had
    compared the fourth row against the wrong setting; that is fixed.
- Checked by transcription with ElevenLabs Scribe, on a sample of 24 clips
  with the heaviest direction:
  - no audio tag was read aloud;
  - the penguin choir's line dropped "high notes" and was re-recorded (the
    new take is complete);
  - "lamps" transcribes as "lambs" in all four takes, even with an IPA hint,
    most likely the transcriber's bias. The IPA take is in the game, and it
    has not been listened to.
- Results: `flutter analyze` is clean and the full suite passes 1408 tests,
  with 111 capture tests skipped.
- Recast: Pip was first voiced by Peanut – Tiny & Peppy. Five high-pitched
  voices were auditioned (`build/story-voices/pip-auditions/`); the game
  owner then picked Nelson – Awkward Nerd Character, a sixth voice. Pip's 46 clips (42 lines and 4
  sprint calls) were re-recorded with the same prompts.
- Not covered: nothing was played on a phone, and no clip was listened to by
  a person. Only the 24 transcribed clips were checked for their words; the
  rest were checked for length and pace only.

## 2026-09-30 Ember Dragon redesign

- Art only. The rules, rules version, `lib/domain/*`, audio, the hit circle,
  the mouth point, every timing and the breath bands are untouched, and
  `test/dragon_boss_test.dart` is unmodified and passes. The design came from
  a written design bible and a shared layout contract (`DragonLayout`:
  anchors, envelope, stroke weights, timeline), then eight part builders, a
  seamless-skin pass, two rounds of independent hostile reviews (design,
  colour, motion, QA, style) and a final verification round. The bible,
  reviews and review harnesses live outside the repo in `../dragon-ws`.
- What changed, all under `lib/game/`: `dragon_layout` (new), `dragon_hide_art`
  (new: torso, neck, head, tail and near legs painted as one skin under one
  outline, by a two-pass paint with no per-frame `Path.combine`),
  `dragon_call_art` (new: the swarm-call cue), `dragon_story_art` (new: story
  portraits), and rewrites of `dragon_kit`, `dragon_pose`, `dragon_boss_rig`,
  `dragon_head_art`, `dragon_body_art`, `dragon_wing_art`, `dragon_breath_art`,
  `dragon_fireball_art`, `dragon_encounter_ui` and `dragon_hud_art`. The
  dragon branches of `boss_encounter_art` and `boss_health_bar_art` changed;
  no other boss's branch did. `story_boss_art` now calls `DragonStoryArt`.
- Fit and budgets, enforced by default (`test/dragon_enforce.dart`): every
  pose stays inside the layout's envelope (`dragon_envelope_test`, about fifty
  states across wing phases), no pose crops at 640×360 or 800×360 in fury,
  roar, hold, snap or blast (`dragon_staging_test`), and the rig stays within
  its per-frame budget of drawing ops, clips, shaders and layers
  (`dragon_budget_test`).
- Fairness: the flame's visible edge sits within a few pixels of the rules'
  burn band and never past it, in every lane, in fury and under Reduced
  Motion (`dragon_breath_test`). The jaws land on the rules' mouth point on
  every launch, and the fireball's solid body equals its hit radius.
- Determinism: identical inputs give identical pixels whatever order the
  states are drawn in (`dragon_determinism_test`), and every public brush
  survives NaN and infinite inputs.
- Results: `flutter analyze` is clean. The full suite on a copy of the tree
  with the redesign applied passed 1398 tests with 111 capture tests
  skipped. The dragon, boss-art and campaign tests pass again on this tree.
- Not covered: nothing was run on a phone. On this shared desktop, in
  debug, the rig costs 1.35 to 1.6 times the original art's CPU time, though
  it builds 0 to 2 gradient shaders a frame where the original built about
  sixty-six; a mid-range Android check is still worth doing.
- Left for the game's owner, outside the dragon's files: `bird_game.dart`
  applies a 1.018 world zoom whenever shake is non-zero, which pops on every
  hit, fury onset and roar (a zoom of `1 + 2.2 * max(|dx| / w, |dy| / h)` is
  exactly 1 at rest). In `boss_audio_cues.dart`, `boss_reveal` fires about
  0.25 s before the reveal's visual strike (1.65 s against 1.88 s) and
  `dragon_breath` about 0.22 s after the ignite (5.5 s against 5.26 s; keep a
  quiet sizzle at 5.5 s). A rules change, which would need a new rules
  version, could also push the first fireball after the swarm call
  (`dragonRefire` 0.9 to 1.7).

## 2026-09-30 Campaign story

- The campaign now tells its story between flights (`docs/campaign.md`,
  Story; the specification's Campaign section). Nothing in the rules, a
  flight or a replay tape changed: rules stay at version 41 and the save at
  schema 5.
  - 23 dialog scenes (`lib/domain/campaign_story.dart`) between the courier,
    Postmaster Bill and the five bosses play on the map: the prologue, a
    route's opening, an arrival in each later region, the scene at each
    lair and each boss's last word before its postcard. The 10 scenes of
    chapters 1 and 2 can be reached in this build.
  - Every level has a delivery: a parcel tag on its card and a signed
    thank-you note on a finished result.
  - Watched scenes are saved in the `storyWatched` preference. A level's
    story key plays its scenes again.
- Tests:
  - `campaign_story_test.dart` (8) checks:
    - all 40 deliveries against their length limits, with a boss signing its
      own level's;
    - a scene before exactly the first level of each region and each boss
      level, set in that level's region, and one after each chapter;
    - three to nine lines a scene, at most 100 characters a line, curly
      quotes and a real ellipsis, the courier in every scene and a boss in
      every scene that has one;
    - each boss's name-card line as its last word at the lair;
    - the club rule opening and closing the story, and the flame seal in the
      first four scenes after a fall;
    - what plays by itself: the prologue until it is watched or 1-1 is
      cleared, a level's scene once before its first finish, and a boss's
      last word only while its postcard is due.
  - `campaign_save_test.dart` (13) adds: a watched scene is saved once,
    beside the other preferences and the level records; the progress
    controller saves one; Reset starts the story over.
  - `campaign_screens_test.dart` (21, and 12 capture tests) adds a `story`
    group on the real app over an in-memory database:
    - the first visit plays the prologue line by line, each line and speaker
      in the semantics, and a second visit goes straight to the map;
    - Skip and the back button end a scene and save it;
    - a level's scene plays before its card once, the story key plays it
      again without saving, and a level with no scene has no key;
    - a fallen boss's last word, then its postcard, then the next route's
      opening, then the card; a beaten lair's key plays both of its scenes,
      and two taps as the first ends do not skip the second;
    - with motion, a line writes itself out, a tap finishes it and the next
      moves on, and the map holds its frame underneath.
    Its other tests start with every scene watched, so they meet none.
  - `polish_story_scene_test.dart` (8, and 11 capture tests) checks every
    line of every scene at 640×360, 800×360, 1000×450 and 640×360 with a
    notch: found once, 15 px or larger, within two rows, inside the panel,
    with no exception. It also checks the keys and labels the campaign
    relies on, Enter and Space, no tickers or scheduled frames under Reduced
    Motion or with animations turned off, and that every actor keeps to a
    bounded box.
  - `polish_level_intro_test.dart` (7, and 5 capture tests) adds: the cargo
    on all 40 cards at the three sizes, inside its tag and over no other
    lettering; the story key only with `onStory`, at least 48 px, centred
    under the close key, with the hint clear of it.
  - `polish_s4_result_test.dart` (19, and 16 capture tests) adds: all 40
    notes on their own; on the real stage for 1-1, 2-5 and 1-8 at the three
    sizes, the note overlaps none of the title, the bird, the plate, the
    scoreboard, the stars or the keys; an interrupted flight shows none;
    with motion it lands where Reduced Motion puts it.
- Renders reviewed under `build/visual-review/campaign/`:
  - `polish/story/` (225) from `CAPTURE_POLISH`: the cast sheets (Bill, the
    four birds and the five bosses in every mood, before and after their
    fall), every scene at 800 wide, the prologue, a lair and a last word at
    the three sizes, the longest lines, a notch, each bird as the courier,
    the opening and a change of speaker frame by frame, and Reduced Motion;
  - `polish/level-intro/` and `polish/s4-result/` from `CAPTURE_POLISH`: the
    tag, the story key and the note, with the note arriving frame by frame;
  - `screens/story-*.png` (27) from `CAPTURE_CAMPAIGN_SCREENS`: the prologue,
    a lair, a last word, an arrival and the card it leads to, in the real
    app at the three sizes.
- Review fixes:
  - A caption that wrapped left one word alone on its second row. Every line
    that wraps now splits evenly.
  - Two taps as a replayed scene ended could skip the scene after it
    (`campaign_screens_test`).
- Results: `flutter analyze` is clean and the full suite passes 1035 tests,
  with 110 capture tests skipped.
- Not covered: chapters 3–5 are not playable, so their scenes and notes are
  checked on their own and in the renders, not through a flight. Nothing was
  run on a phone.
- Known couplings: `lib/ui/story_boss_art.dart` builds each boss's story
  poses from its flight rig. It paints the Spitter King's open eye over the
  rig's crossed-out one after his fall, and assembles the Dusk Empress from
  her part painters in the rig's order, so a change to her rig's eye or draw
  order needs the same change there. The Ember Dragon goes through
  `DragonStoryArt` (`lib/game/dragon_story_art.dart`), which keeps the rig's
  draw order in one place beside it. Baron Bat's story face follows the
  line's mood (`_Pose.storyMood`, since 2026-10-03); his sad face adds a
  sweat bead.

## 2026-09-30 Campaign

- Rules version 41 adds the Tap & Fly campaign (`docs/campaign.md`, rules in
  the specification's Campaign section). `FlightSimulation` asks a
  `FlightPlan` for every schedule knob. `FlightPlan.endless` reproduces the
  old rules, and a campaign level supplies a `LevelPlan`. The catalog
  (`lib/domain/campaign.dart`) holds 5 chapters of 8 levels. Chapters 1 and 2
  are playable, and chapters 3–5 are data, locked as "Coming soon".
- Endless is guarded two ways:
  - `test/endless_plan_baseline_test.dart` pins 44 seeded flights and replays
    to digests recorded before plans existed
    (`test/fixtures/endless_plan_baseline.json`). They cover touch Star Trail
    at 28 rules versions from 5 to 40, three widths and Reduced Motion. They
    also cover the base weapon, including a flight that ends, plus Classic,
    practice, the camera modes, and replays at rules 27, 33, 38 and 40. Every checkpoint samples the obstacles, enemies,
    stars, shots, set pieces, events and the count of random draws. It also
    checks that rules 41 fly endless exactly like 40 at 1.6 and 2.4 widths,
    and that the baseline flight meets all five bosses, the upgraded Baron,
    every rush path, a gale, stone panels and heart pickups. Re-record only
    after a deliberate endless change, with
    `--dart-define=RECORD_ENDLESS_BASELINE=true`. Add
    `DUMP_ENDLESS_BASELINE=true` to write each flight as text for diffing.
  - `test/endless_scenery_baseline_test.dart` pins 235 endless scenery frames
    to pixel digests (`test/fixtures/endless_scenery_baseline.json`). They
    cover every region, crossing and lap of the world tour, the older gate
    looks, a gale and real game frames, with and without Reduced Motion.
    Re-record with `RECORD_SCENERY_BASELINE=true`.
- Campaign tests:
  - `campaign_catalog_test.dart` (6) checks:
    - five chapters of eight levels in boss order, with unique ids and seeds;
    - the journey's region order and the levels per region;
    - lengths, starts, and set pieces with passages on both sides;
    - mechanics arriving chapter by chapter;
    - star marks for all 40 levels pinned to the route (see below);
    - plans surviving JSON exactly, and malformed plans rejected.
  - `campaign_flight_test.dart` checks:
    - campaign rules need a touch Star Trail at rules 41;
    - the same seed and inputs fly the same level exactly;
    - every attempt lays the same route whether or not it sprints, at every
      width, with moving passages in the same phase;
    - a level holds its region and ramps from its start;
    - each hazard is absent before its chapter, flying every chapter 1–2
      level;
    - Shoot and Sprint are refused before 1-3 and 1-5;
    - toughness follows the chapter;
    - every chapter 1–2 level flies to its finish and lays exactly its route
      stars;
    - chapter 3–5 gales and shuffled rushes already fly (3-4, 3-6, 5-2, 5-3
      and 5-7, with and without sprints);
    - crossing the line completes the level;
    - 1-8 and 2-8 end with the boss (120 and 210 HP), then the glide to the
      line;
    - a knockout earns no stars, the stars follow the marks, and a pause holds
      the route clock.
  - `campaign_progress_test.dart` checks the unlock rules, bosses opening
    chapters while 3–5 stay locked, the current level, merged bests, star
    totals by level, chapter and region, and when a postcard is due.
  - `campaign_replay_test.dart` checks:
    - 1-5, 2-3 and 2-8 sessions replay exactly from their tapes;
    - a replay flies the plan it was recorded with, not the catalog's;
    - only rules-41 campaign tapes carry `level` and `plan`, and older tapes
      still load and replay;
    - corrupt levels and plans are rejected.
  - `campaign_save_test.dart` (12) checks:
    - the schema 4 → 5 migration keeps every flight and setting and adds an
      empty campaign;
    - level bests, with each flight counted once;
    - no endless records from campaign flights;
    - only a scored touch Star Trail of a real level can carry a level;
    - postcards marked seen, the progress controller, and reset;
    - daily adventure and passport counting;
    - a saved campaign session keeping its level and replaying to the same
      result;
    - endless session summaries saved as before.
  - `campaign_play_test.dart` checks:
    - `PlayController` flies the level's plan and seed and the tape keeps
      them;
    - the finish completes the level with its stars;
    - a knockout fails the level and Retry flies the same one;
    - the last level has no next one;
    - the HUD for 1-1, 1-3 and 2-1 shows the stars, route and offered
      controls, endless keeps its score and both controls, and a boss hides
      the level readouts.
  - `campaign_screens_test.dart` runs the real app on an in-memory database:
    - Home to the map with its star total, and the Campaign key at a full
      48 dp on the smallest phone;
    - a level counting as flown on Home;
    - map → card → flight → finish → result → Next → next card;
    - locked levels only nudging, and chapters 3–5 saying Coming soon;
    - a knockout's stage and Retry;
    - the pause card's Retry and Map both saving;
    - the first boss clear bringing the postcard and then chapter 2;
    - 2-8 leading back to the map, with chapter 3 coming soon;
    - sessions named after their level.
  - `campaign_art_test.dart` checks that the map opens on the current level,
    node states and stars, taps on open and locked nodes, beaten chapters'
    postcards, Reduced Motion's still map and jumps, and every chapter's
    postcard.
  - `campaign_flight_art_test.dart` checks:
    - boss lines only on campaign boss levels, in quotes under the epithet,
      fitting at every width and fading with the card;
    - the finish line scrolling in and meeting the bird as the level
      completes;
    - Reduced Motion's still pennants;
    - the line staying in the world after a knockout.
  - `campaign_regions_art_test.dart` checks that a level holds its one region
    at every moment and opens on the tour's still for that region, that band
    copies come and go without a jump, and that every region renders through
    a long level.
- Chapter 3–5 star marks were re-pinned from the real routes. The design
  doc had estimated a gale at 24 stars, but it costs 42–45 (3-2 lays 105, and
  the same level with a gale, 3-4, lays 63). A rush path costs 6–12. 4-3's
  old ★★★ mark (70) was above its 69 route stars. Every level now sits at 45%
  and 75% of its route stars in chapter 1, and 50% and 80% after, rounded to
  fives:

  | Level | Route ★ | ★★ / ★★★ | Level | Route ★ | ★★ / ★★★ | Level | Route ★ | ★★ / ★★★ |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 3-1 | 96 | 50 / 75 | 4-1 | 99 | 50 / 80 | 5-1 | 105 | 55 / 85 |
  | 3-2 | 105 | 55 / 85 | 4-2 | 108 | 55 / 85 | 5-2 | 72 | 35 / 60 |
  | 3-3 | 102 | 50 / 80 | 4-3 | 69 | 35 / 55 | 5-3 | 99 | 50 / 80 |
  | 3-4 | 63 | 30 / 50 | 4-4 | 105 | 55 / 85 | 5-4 | 72 | 35 / 60 |
  | 3-5 | 114 | 55 / 90 | 4-5 | 114 | 55 / 90 | 5-5 | 78 | 40 / 60 |
  | 3-6 | 69 | 35 / 55 | 4-6 | 114 | 55 / 90 | 5-6 | 111 | 55 / 90 |
  | 3-7 | 78 | 40 / 60 | 4-7 | 78 | 40 / 60 | 5-7 | 78 | 40 / 60 |
  | 3-8 | 36 | 20 / 30 | 4-8 | 36 | 20 / 30 | 5-8 | 36 | 20 / 30 |

  Chapter 4's routes don't include the sea or tide yet. Re-check them when
  those rules are built.
- Renders were reviewed during the build, under
  `build/visual-review/campaign/`:
  - `map/` (47) and `postcards/` (8) from `CAPTURE_CAMPAIGN_ART`;
  - `flight/` (40) from `CAPTURE_CAMPAIGN_FLIGHT`;
  - `regions/` (156) from `CAPTURE_CAMPAIGN_REGIONS`;
  - `screens/` (54) from `CAPTURE_CAMPAIGN_SCREENS`.
- Results: after the screens landed, `flutter analyze` was clean and the full
  suite passed 954 tests. After the marks were re-pinned, the campaign and
  endless-baseline files passed again (95 passed, 18 capture tests skipped).
- Review fixes, each with a test that failed before the fix and passes
  after it:
  - A beaten boss can't fail its level. From the defeat to the line the bird
    coasts (`FlightSimulation.victoryGlide`), taps, shots and sprints do
    nothing, and nothing hurts it. `campaign_flight_test` flies 1-8 and 2-8
    on the last heart with no taps, and with taps, shots and sprints on
    every frame; `campaign_replay_test` replays and seeks into the glide.
  - On a boss level the route line fills 85% over the run-up, marks the lair
    with the boss's headwear, and the glide fills the rest. The Bonk!
    stage's "route flown" reads the same share (`campaign_flight_test`, and
    the `hud-boss-run-up` and `hud-victory-glide` captures).
  - The level result leaves the flight's bird out of the frozen finish
    (`BirdGame.hideBird`). `campaign_flight_art_test` renders the frame both
    ways and finds changes only within the bird's footprint;
    `campaign_screens_test` checks the result hides it and a knockout keeps
    it.
  - Only a finished flight sets a level's best stars collected and best
    score, and the card reads "Not delivered yet" until one does
    (`campaign_progress_test`, `campaign_save_test`,
    `campaign_screens_test`). The result's NEW BEST and score best follow the
    same rule.
  - A replayed level chimes at its plan's marks, not at the endless flight
    goals (`campaign_screens_test` replays a saved session: one chime, not
    two).
  - Home's Play and Practice are back at their pre-campaign rects, measured
    from the baseline Home and pinned at 640×360, 800×360 and 1000×450. The
    Campaign key sits beside Play, a full 48 dp at all three
    (`campaign_screens_test`).
  - The map's back key leads Home while the save loads or can't be read,
    and the error offers Home beside Try again (`campaign_screens_test`).
  - A gale no longer pushes a boss away for good: the rush lead after a gale
    only applies to a rush that is scheduled. The catalog never pairs them
    (`LevelPlan.problem`); `campaign_flight_test` flies such a plan anyway.
  - Map stills keep their own cache budget, apart from the card's and
    postcard's pictures, and the map's tickers are muted under a card or
    postcard (`campaign_art_test`, `campaign_screens_test`). The 47 map and
    8 postcard captures are pixel-identical after the change.
  - After the fixes, `flutter analyze` was clean and the full suite passed
    966 tests (29 capture tests skipped), the endless baselines included.
- Known and open:
  - holding one region draws up to four small offscreen layers per skyline
    band while a band seam is on screen (campaign only), which hasn't been
    measured on a phone;
  - the map paints a region's first still in about 150–250 ms in debug
    builds.

Device playtest, still pending:

- Fly 1-1 to 2-8 in order on the phone. Check each NEW hint matches what its
  level brings, and that difficulty rises without a jump at 2-1, 2-3 or 2-7.
- Retry speed: after a knockout, Retry should reach the countdown at once.
  Retry from the pause card too.
- Check the finish line reads clearly as it approaches at 640 and 800 widths,
  and that the result sits well over it.
- Star marks: ★★ should be reachable on a careful first flight, and ★★★
  should need streaks and the magnet. Check boss run-ups (15/25, 20/30) too.
- Map performance: swipe and arrow-step across all 13 stops. Watch the first
  paint of each region and frame times while the bird bobs.
- Watch frame times in a long level while skyline seams cross the screen.
- Reduced Motion, both the app setting and the system one: the map is still
  and jumps between stops, cards appear without sliding, the pennants hold
  still, and the result shows its stars in place.
- Postcard: beat Baron Bat and see the result's note, the postcard on the
  map, Continue, then 2-1 open. Reopen it from the route. Kill the app
  before Continue; it should arrive again.
- Save a level session, restart the app, and replay it from Records → Saved
  sessions. The flight, stars and finish should match, and it should be
  named after the level.
- Install over an existing schema-4 build with records, saved sessions and
  settings. All of them should survive, and the map should open on 1-1 at
  0 / 48.
- Check the Home Campaign key on the smallest and largest phones, and the
  back key on the map, card and postcard.
- Make sure endless Play still tours the regions and meets every boss.

## 2026-09-30 game-over stage redesign

- Before this change, the stage read as a results panel pasted over the game:
  - the title was centred over the full width, while the card and buttons sat
    right and the bird sat low left with dead space above it;
  - the caption sat on the busy world with only a text shadow;
  - score and best had similar weight, and the stat pills and footnotes were
    crowded;
  - the ribbon straddled the card's edge, and the three buttons had near-equal
    weight.
- Presentation only, in `lib/ui/game_over_stage.dart`. The stage now reads
  left to right:
  - The left half is the story: the Bonk!/Splash! title, the caption on a
    cream plate, and the bird on its cloud (drawn larger) in a soft spotlight.
  - The right half is an ink-framed scoreboard with a big score and a
    personal-best plaque.
  - A new best keeps the old record on the plaque until the count lands, then
    gilds the plaque under a notched ribbon.
  - Below the scores sit stat tiles, a progress row (a flight wings chip and a
    passport/postcard chip with a stamp progress bar) and the save status.
  - Practice tags the score, and its note fills the progress row.
- The keys stay in the same place after every flight. Home and Save session /
  Watch replay are cream keys with the icon over the label. Fly again is a
  taller coral key in the home PLAY key's style. It pops in last, as the stage
  arms, and hops with one glint when the bird recovers. Touch targets grew.
  In design px of cap height, the secondary keys went from 44 to 64, and Fly
  again from 60 to 78.
- Unchanged: every string, key and branch the tests use; the tap guard;
  `entrance` (1.5 s), `calmEntrance` and `armAt` (0.62); and Reduced Motion's
  still stage. Shared components and the results panel were not touched.
- `test/game_over_stage_test.dart` (8 tests) gains:
  - a standalone-stage helper;
  - a gallery of all four birds, dazed and then ready, with Orbit on Classic
    to cover the rank tile;
  - captures of the ready moment, of Watch replay, and an entrance filmstrip.
- Visual review, six rounds, at 640×360, 800×360 and 915×412. Before and
  after renders are in `build/visual-review/game-over-redesign/`. Changes
  made along the way:
  - the card hugs its content above bottom-anchored keys, so practice has no
    hollow card;
  - the ribbon moved off the label clash onto the plaque;
  - the next-stamp title no longer loses its space to the bar;
  - chips put their chevrons at the far edge;
  - the PRACTICE tag moved beside the score;
  - the reveals were retimed so the card never shows a blank middle;
  - rank names wrap instead of shrinking;
  - the session-saved teal was deepened for contrast.
- `flutter analyze` is clean for both files, and the stage tests pass. Device
  playtesting of the key sizes and the ready hop is still pending.

## 2026-09-30 Baron Bat returns upgraded

- Rules version 40 (`supportsUpgradedBaron`) upgrades every Baron Bat
  after his debut: `SkyBoss.upgraded` is passed as `supportsUpgradedBaron &&
  kind == baronBat && !debut`, and `SkyBoss.screeches` reads it. The debut
  Baron, rules 39 and older, and every other kind are unchanged. The
  upgraded Baron adds no random draws, and his branches are gated on
  `screeches`. His `summonIn` is infinite, so the old single-helper summon
  never runs for him.
- The screech timing, gap places, aiming, wall geometry, fireball hold and
  pair timing live in `lib/domain/baron_screech.dart`. `SkyBoss` exposes:
  - `screechWarning`, `screeching`, `screechFront`, `screechOpening`,
    `screechOriginX`;
  - `screechQuiet`, `screechWarnings`, `screechBlasts`;
  - `screechGap`, `screechesAimed`, `screechHits()`;
  - `batPairsDue`, `furyPairsDue`, `batPairs`, `furyPairs` and
    `screechHint`.

  `FlightSimulation` gains the presentation counter `screechHits` and
  `_sendBatPair` (two simple bats, `summons` += 2).
- The gap is aimed once per warning, from the bird's height and the
  screech's index, like the dragon's breath lane. Pairs are edge-triggered
  like the dragon's swarm calls.
- Two cues were synthesised in `tool/prepare_sound_effects.py` with no
  source takes or network: `screech_warning` (1.45 s) and `sonic_screech`
  (1.2 s). Their envelopes were checked. The warning's chirps swell from
  about −40 to −14 dB RMS. The screech holds near −14.5 dB, then falls away.
  `BossAudioCues` plays them on the warning and sweep edges, and the play
  screen's live semantics hint gained a `screechHint` branch.
- The art is split like the dragon's:
  - `baron_storm_pose` (poses from the boss clock, rig wrapper, mouth,
    camera jolt);
  - `baron_storm_art` (regalia);
  - `baron_screech_art` (telegraph, wall, mouth effects, tag, bird jolt,
    and pure helpers the tests check against the rules).

  `BossRig.paint` takes an optional `storm` pose. `BossEncounterArt` and
  `BossArt` gained small `screeches` branches: stage hooks, the rig, the
  held charge, the pink roar, the storm crown, the arrival texts and the
  jolt. The health bar is unchanged.
- `test/baron_bat_upgrade_test.dart` (17 tests) covers:
  - the upgrade gate at rules 39 and 40 for encounters 1, 6 and 11;
  - the debut Baron's unchanged fight;
  - the cycle through fury, and the gap never at the bird's own place and
    alternating;
  - aiming once, and hurting only outside the gap and only as the wall
    crosses, including Classic;
  - no screech in cutscenes;
  - reachability: from every start height, calm and fury, both screech
    parities, at 1.78 and 2.4 widths, a bird tapping at most 5 times a
    second loses nothing;
  - the fireball hold, the pair heights, kinds and timing, and every pair
    past the bird before the next warning (analytically at the slowest pace
    on a 2.4-wide phone, and in a flight);
  - pause, cues, repeat determinism, and a recorded flight to encounter 6
    that survives backward and forward `ReplayPlayer` seeks;
  - bot wins at 640 and 800 widths.

  Shortening the warning to 0.3 s makes the reachability test fail, so it
  guards the timing.
- `test/boss_polish_upgraded_baron_art_test.dart` renders pose sheets and
  640×360 and 800×360 walkthroughs, with Reduced Motion. It checks:
  - that the drawn leading edge stays within 0.01 of `screechFront` at every
    height the bird can meet, for 4:3, 640, 800 and 2.4 widths, all gaps
    and fury, and by pixel sampling;
  - that the drawn gap equals `screechOpening`;
  - determinism and exact seeks, and distinct poses under Reduced Motion;
  - that the debut Baron still matches its pre-change baseline, stored as
    pixel hashes in `test/fixtures/debut_baron_baseline.json`. On another
    Flutter version or machine, re-record it from a known-good tree with
    `--dart-define=RECORD_BARON_BASELINE=true`.

  The new art uses no `saveLayer`. Picture recording measured 0.2–0.5
  ms/frame (warning and sweep included).
- `flutter analyze`: no issues. Full suite: 858 passed, 11 skipped, 0
  failed.
- Reviewed renders are in `build/visual-review/boss-polish/upgraded-baron/`.

## 2026-09-30 Ember Dragon swarm

- Rules version 39 lets the Ember Dragon call flocks of the Swarm rush
  path's bats (`supportsDragonSwarm`, passed to `SkyBoss.callsSwarm`). One
  flock comes as each flame gutters out (`SkyBoss.swarmCallAt`, 7.6 s into
  the breath cycle). In fury, away from the debut, a second follows
  `swarmFollowAfter` (1.4 s) later. Calls are edge-triggered like breath
  aiming: `swarmCalls` and `swarmFollows` catch up with the clock-derived
  `swarmCallsDue` and `swarmFollowsDue`. There are no new random draws.
- `SwarmBat.route` is now optional. A dragon's bat has none and holds the
  `height` it was released at. `_advanceSwarm` also runs without rush paths
  (Classic) whenever bats are flying. There a bat ends the flight and a
  smash scores nothing. Before rules 39 the swarm is always empty outside a
  rush path, so older replays are unchanged. `_defeatBoss` clears the swarm.
- A call reuses `summons` and `lastSummonAt`, so `boss_summon` plays through
  `BossAudioCues`. `DragonPose.roar` takes 0.7 of the summon pulse for the
  call gesture. `breathHint` reads SWARM for `swarmHintSeconds` (2.5 s).
- `test/dragon_boss_test.dart` gained a `swarm flocks` group:
  - the call timing, formation, height clamp, cue and hint;
  - the fury follow-up, and none on the debut;
  - both flocks past the bird before the next inhale at 1.78, 2.22 and 2.6
    widths;
  - hurt, sprint ram and rock smash, and Classic ending the flight;
  - defeat clearing the swarm, and no flocks at rules 38.

  `dragonSnapshot` now includes the swarm, so the determinism and seek
  tests cover it. The beatability bot dodges bats as well as fireballs, and
  each of its four fights now has to meet a flock.
- `flutter analyze` is clean and `flutter test` passes: 829 passed, 11
  skipped.

## 2026-09-30 Ember Dragon

- Rules version 38 adds `BossKind.dragon`, the Ember Dragon ("SOVEREIGN OF
  THE BURNING SKY"), as the fifth boss in the cycle (`supportsDragon`). Rules
  34–37 keep `BossKind.values[bossesDefeated % 4]`, and extending the enum
  leaves indices 0–3 unchanged. The dragon adds no random draws. Every
  dragon-only branch (breath aiming, the fireball hold, the mouth launch,
  splits, the burn check, the arrival swoop) is gated on `isDragon`.
  `SkyBoss.strike` doubles damage only while a dragon's heart is open. For
  every other boss it is `takeDamage`, so older replays are unchanged.
- The breath timing, bands and aiming live in `lib/domain/dragon_breath.dart`.
  `SkyBoss` exposes `breathWarning`, `breathing`, `breathBusy`,
  `breathQuiet`, `coreExposed`, `breaths`, `breathBlasts`, `breathLane`,
  `splitsVolley` and `breathHint`. `BossAmmo` gains `splitAfter`, `ember` and
  `age`. `FlightSimulation` gains the presentation counters `emberSplits` and
  `breathBurns`.
- The art is split like the pirate's and the moth's:
  - `dragon_kit` (palette, tone, paths);
  - `dragon_pose`;
  - `dragon_wing_art`;
  - `dragon_body_art` (torso, belly, heart, legs, tail);
  - `dragon_head_art` (neck, head, horns, circlet, eye, smoke);
  - `dragon_boss_rig`;
  - `dragon_breath_art` (telegraph, flame, inhale embers);
  - `dragon_fireball_art`;
  - `dragon_encounter_ui` (sky, roar, fury ring, hits, defeat);
  - `dragon_hud_art`.

  `BossEncounterArt._paintDragon` stages them. `BossAmmoArt`,
  `BossHealthBarArt` (with a HEART ×2 tag), `BossAudioCues`,
  `CombatAudioCues` and the play screen's live semantics hint gained small
  dragon branches.
- Three cues were synthesised in `tool/prepare_sound_effects.py` with no
  source takes or network: `dragon_inhale` (1.45 s), `dragon_breath` (1.6 s)
  and `ember_split` (0.45 s). Their envelopes were checked: the inhale swells
  from −40 to −14 dB RMS, and the flame holds near −18 dB, then gutters out.
- Existing tests that assumed the four-boss cycle at the current version
  were updated:
  - `dusk_moth_boss_test` (the cycle list now includes the dragon at 5 and
    10; later moths are after 7 and 12 defeats);
  - `combat_damage_test` (the dragon from rules 38, 360 HP);
  - the kind-name switches in `boss_polish_ammo_art_test` and
    `boss_polish_health_bar_art_test`.

  The encounter-art Reduced Motion check found that the huge body flared
  through the burst. Under Reduced Motion it now fades out before the burst,
  as the pirate's wreck does.
- `test/dragon_boss_test.dart` (19 tests) covers:
  - the cycle at 37 and 38, and the HP curve;
  - the debut (halves only, no splits);
  - the breath timing through fury;
  - aiming once at the bird's height;
  - burning only inside the band and during the blast, including Classic;
  - no burns in cutscenes;
  - reachability: from every start in every band, debut or not, a bird
    tapping at most 5 times a second is safe before the blast and loses
    nothing;
  - the mouth launch and the quiet window;
  - double damage on the open heart;
  - the ember split geometry;
  - pause, audio cues and repeat determinism;
  - a recorded flight to the fifth boss that survives backward and forward
    `ReplayPlayer` seeks;
  - bot wins at 640 and 800 widths for the debut and a later dragon.

  A dodging bot beat the debut dragon in 27–34 s and the later one in
  47–54 s without being hit.
- `test/boss_polish_ember_dragon_art_test.dart` renders the pose sheets
  (close-up, phone scale, Reduced Motion), hero and head close-ups,
  fireballs, health bar states and in-game walkthroughs at 640×360 and
  800×360 (the latter also in Reduced Motion). It checks:
  - determinism and exact seeks;
  - that the art's jaws sit on the rules' mouth point within 0.012;
  - that every non-idle pose stays distinct under Reduced Motion.
- A throwaway probe measured the combat stage in the test environment:
  - Ember Dragon: 0.9–1.8 ms/frame paint and 16–20 ms raster;
  - Pirate Captain: 3.8–4.2 ms/frame paint and 32–36 ms raster.

  Combat uses no `saveLayer`, except while the flame fades out and for the
  brief ×2 label.
- `flutter analyze`: no issues. Full suite: 824 passed, 11 skipped, 0
  failed. The baseline taken before this change (on a tree other sessions
  were also editing) had 4 failures, since fixed by those sessions: the
  Dusk diadem seating check and three jump-glide HUD checks.
- Reviewed renders are in `build/visual-review/boss-polish/ember-dragon/`.

## 2026-09-30 Cyberpunk City region

- The world tour gains a thirteenth region, `WorldRegion.cyberpunk`
  ("Cyberpunk City"), between Egypt and China. Egypt's hot noon hands over to
  a neon night, which gives way to China's pastel dusk, so both crossings
  keep the tour's warm and cold, day and night contrast. `WorldTour.loop` is
  now derived from `WorldRegion.values.length` (286 seconds), so the one
  `const` reader in `regions/sea.dart` became `final`. The existing schedule
  assertions still hold: the tour still reaches Aztec lands by 60 seconds and
  Paris still hands over to Egypt.
- `lib/game/regions/cyberpunk.dart` paints a sleek, vertical megacity rather
  than New York's rainy Art Deco night:
  - Sky: an indigo-to-violet gradient with a magenta horizon glow. A violet
    moon with a lit colony sits behind a needle hyper-spire. An orbital ring
    carries drifting stations. The low smog deck is lit from below. Cyan and
    magenta beams sweep the sky, flying traffic crosses in four lanes, and an
    advertising airship scrolls invented glyphs.
  - Far band: ghost and front rows of arcology towers in eight crown styles,
    with light strips, lit windows and masts. Two hyper-spires with platform
    rings stand over them, and aircraft beacons blink.
  - Mid band: the landmark, a space-elevator arcology in two stepped blades
    of dark glass split around a core of light. It has three halo terraces
    with running lights, climbers riding the tether and a holographic koi
    circling it. Around it stand glass towers with LED floor bands, sky
    bridges and giant screens that play glyph rain, wave bands or a hexagon
    and equaliser. A curving maglev guideway carries a five-car train.
  - Low band: a canal. An elevated freeway streams with head and tail lamps
    over neon-signed fronts, some signs with flickering tubes. Shop fronts
    have passers-by, and water taxis leave wakes. The signs, shops and street
    lights are reflected in broken columns, and `reflect` adds the moon's
    path.
  - Near band: glass, ribbon-window, diagrid and louvred rooftops with
    LED-trimmed parapets and setback tiers. Their kit includes fans, dishes,
    holo projectors, masts, steaming vents, a drone pad, a neon glyph frame
    and billboards (a synth sun, a koi, a prism eye). Drones cruise past,
    wet glints shimmer and a glass balustrade frames the foreground.
- Signs use an invented glyph script, so there are no words, brands or
  logos. Static detail is recorded into the cached band pictures and the
  cached water and cloud pictures. Per-frame work reuses unit-space shaders
  (blooms, beams, the sky glow, the hull and the hologram cone) and batches
  lights with `drawPoints`. There is no `MaskFilter` and no `Random`.
- The new weather motes are `Mote.drizzle` (fine neon-tinted rain) and
  `Mote.data` (square pixels rising and blinking in steps). They are used 26
  and 9 times. There is also a glitch pixel-shard burst, a microchip
  `Kit.emblem`, a fibre-optic tether (dark cable with cyan pulses) and
  holo-shard gale debris. Gates borrow the night look.
- `lib/game/obstacle_designs/cyberpunk.dart` skins all seven kinds in pale
  pearl, titanium and lilac alloys, so every solid stands out against the
  dark city:
  - an arcology pylon with a light pipe pulsing toward the rim;
  - a turbine tower with a ducted fan spinning at the rim;
  - a holographic glass panel with glyph rows scrolling;
  - a server-rack pylon with blinking status lights;
  - a stepped glass tower with a chasing light strip;
  - a hover drone with a scanning lens;
  - an energy ring around a plasma core.

  Collision rectangles, the ink edge and the state lip come from
  `Parts.column` and `Kit.bezel` unchanged.
- The region lists in `stone_door_art_test`, `bird_trail_art_test` and
  `enemy_polish_dusk_moth_art_test` include the new region.
  `world_regions_test` asserts `egypt.next == cyberpunk` and
  `cyberpunk.next == china`. Its crossing sweep and the art harness now
  render thirteen regions, so both files declare a library `@Timeout`. The
  sweep took 16 seconds on the unchanged tree and missed the 30-second
  default once the machine was busy.
- In a tree holding only this change, `flutter analyze` reports the same 7
  existing warnings in pirate review tests and none from this change. The
  12 region, obstacle, gate, door, trail, moth, star, motion and endless
  test files pass (77 tests). The full suite passes 810 tests, skips 11 and
  fails 2. The two failures are the `bird_motion_test.dart` puppet-portrait
  checks, which fail the same way on the tree without this change (809
  passed, 11 skipped, 2 failed there).
- Reviewed renders are in `build/visual-review/regions/`: `cyberpunk-*`,
  `cross-egypt-cyberpunk-*`, `cross-cyberpunk-china-*`, the `still-cross-*`
  pair and `overview-regions.png`. They cover 1000 and 800 widths, several
  times in the hold and Reduced Motion.

## 2026-09-30 pellet shatter

- Before this change, any rock that met a small-enemy pellet was removed
  along with it, so a full charge costing 45% of the reserve did no more
  than a tap. Rules version 36 lets a rock with charge 0.35 or more (the
  `power_shot` cue threshold, now shared as `PowerShot.shatterCharge`)
  shatter the pellet. The pellet bursts into a blast with a reach of 0.12 to
  0.24. Every small enemy the blast touches, and an unshielded attacking boss,
  takes half the rock's damage, rounded; a raised Dusk Empress veil absorbs it.
  Weaker rocks, and every rules version before 36, keep the plain cancel.
- Blasts resolve after the tick's pellet sweep. A blast that defeats the boss
  calls `_defeatBoss`, which clears `enemyAmmo`, so resolving it inside the
  sweep's `removeWhere` would modify the list while it is being swept.
- `AmmoShatter` records are render-only. They are pruned after 1 second,
  cleared on boss arrival and kept through boss defeat. `AmmoShatterArt`
  (0.6 seconds) draws an amber flash, a ring in the pellet's colour that stops
  at the reach, shards of the pellet's material and chips of the spent rock.
  It replaces the deflect splash. Reduced Motion draws a still ring that fades.
  A shatter plays `lava_burst` under `deflect`.
- `test/ammo_shatter_test.dart` (9 checks) covers:
  - the tuning;
  - weak rocks cancelling only;
  - a full-charge blast defeating a bat, hurting a moth and missing an enemy
    beyond reach;
  - reach growing with charge;
  - version 35 staying unchanged;
  - boss damage, shield absorption, and a finishing blast among other pellets;
  - the audio cue.
- `test/ammo_shatter_art_test.dart` has 17 checks, some of them capture-only.
  They cover paused and seek determinism, a blank frame outside the effect,
  a Reduced Motion footprint that never grows, the ring's edge sitting on the
  reach, the pellet materials, world scrolling and degenerate inputs. Review
  renders are in `build/visual-review/ammo-shatter/`, including in-game frames
  painted through `BirdGame.render`.
- The full suite passed 752 tests and skipped 7 before the art landed. The
  shatter, art, enemy ammo, small enemy, power shot, combat audio and session
  replay tests pass together (69 passed, 4 skipped). `flutter analyze` is clean
  for these files. Project-wide it currently reports errors in `pirate_*` and
  `regions/cyberpunk.dart`, which another change is editing. Device
  playtesting of the blast size and damage is still pending.

## 2026-09-30 knockout and game-over stage

- Before this change, a fatal collision switched to `PlayStage.results` on the
  frame it happened, so the world disappeared and the plain panel appeared
  with no death beat. Collisions now pass through `PlayStage.fallen`, which
  plays a 1.9-second knockout (1.2 seconds with Reduced Motion), and then a
  game-over stage over the frozen, dimmed flight. Every other ending still
  goes straight to the results panel.
- Presentation only. The rules version, physics, scoring, journal commands and
  `RunResult` are unchanged. `_finish` still builds the result, plays
  `game_over` and starts saving at the bump. Replays construct `BirdGame`
  without a knockout clock and draw the same ended frame as before.
- The knockout clock is fed by the game loop's frame time, with a fallback
  timer one second past the end. Taps are ignored for 0.6 seconds and then
  skip the knockout. Backgrounding jumps to the stage. The stage's buttons arm
  about 0.9 seconds after it appears. Tracking issues during the knockout are
  ignored, and the ended flight journals nothing further.
- Birds gain a `dazed` expression with dizzy spirals in place of the pupils,
  drawn from each rig's own eye shapes. `bird_expression_test` confirms it
  changes only the face on all four birds.
- `test/knockout_art_test.dart` (5 checks plus capture-only reviews):
  - timing bounds;
  - the world settling monotonically into a held still;
  - seek determinism for every bird, in the sky and at sea, with and without
    Reduced Motion;
  - the frame going blank by the time the stage takes over;
  - Reduced Motion never growing beyond its first footprint;
  - the fall leaving the screen and the sea-entry timing.
- `test/knockout_flow_test.dart` (11) drives `PlayController` through:
  - collision, knockout, then stage, with saving at the bump and no further
    journal events;
  - the guarded skip under frantic tapping (no flaps, no rebuild per frame);
  - Reduced Motion and practice;
  - backgrounding, and exit mid-save with calls after dispose;
  - the stalled-frame fallback;
  - Fly again;
  - all seven other end reasons;
  - the `game_over` cue;
  - a camera flight whose camera stops mid-knockout.
- `test/game_over_stage_test.dart` (7) runs the real app at 640×360 and
  915×412:
  - HUD hidden and run saved during the knockout;
  - the mash guard on the knockout and on the stage;
  - new best, then Fly again into a normal game over;
  - flight wings, Save session and Watch replay;
  - practice;
  - save failure and tap-to-retry;
  - Reduced Motion;
  - a pirate-sea **Splash!** stage;
  - back during the knockout (one saved run).
- Visual review, three rounds, in `build/visual-review/death/`. Changes made
  along the way:
  - smaller, slimmer feathers kept behind the bird so the dizzy face stays
    readable;
  - a shorter white impact frame;
  - a slight swell during the pop so the face reads at gameplay size;
  - a crown splash instead of a column that looked like a ghost;
  - a lavender dusk tint instead of a cold grey;
  - rush banners and the boss plate hidden while the knockout plays;
  - a rebuilt cloud with an outlined lip;
  - a ring for the orbiting stars;
  - the ribbon moved off the best label.
- `flutter analyze` is clean. The full suite passed 740 tests and skipped 7,
  most of them capture-only reviews. One test failed: `world_regions_test` hit its
  30-second timeout under a load average of about 46 from concurrent
  sessions. Run alone, it timed out twice (its Reduced Motion check and the
  scenery check). It rasterises `ObstacleArt` and `SkyScenery` only, and
  `regions/brazil.dart` is being edited in another change. Device playtesting
  of the knockout timing, the skip guard and the stage at phone density is
  still pending.

## 2026-09-29 gales

- Rules version 33 adds gales to touch Star Trail flights. A gale follows each
  Dusk Empress victory, 12 seconds after she leaves, and no other boss. Walls
  stop, a tailwind lifts course speed to 1.6×, and debris flies at the bird
  for 13 seconds. Each piece is warned 0.9 seconds before it appears, with a
  "!" at its height. That interval's rush path follows 8 seconds after the
  gale, and the boss waits for both. Version 34 (Pirate Captain, from another
  change) builds on it.
- The `rideTheSky` autopilot now dodges debris. It sees pieces 2 seconds
  ahead, as a player reading the warnings would, and may fly 0.22–0.78 during
  a gale.
- Probes over 8 seeds, recorded with 60-damage rocks so the autopilot reaches
  the third boss:
  - With the old 1.25-second horizon and 0.30–0.72 band, 5 of 8 died in
    the gale, touching 4–7 pieces each.
  - With the warning-length horizon, all 8 weathered it, touching 0–3 of
    about 16 pieces. One was flawless.
  - With base damage, the autopilot usually dies before the third boss, so
    the replay test records a 60-damage flight.
- The first scheduling draft left the rush path exactly its 18-second lead
  before the boss, and a substep's rounding made it skip the run. The boss
  now waits one second more.
- `test/gale_test.dart` has 11 tests covering:
  - support by version and mode;
  - only the moth bringing a gale, and its placement past the last wall;
  - the warning lead and the 1.6× surge;
  - aimed and paired gusts and their 0.9-second warning;
  - no walls while it blows, then their return;
  - hits while sprinting, dodge points and both bonuses;
  - rocks glancing off debris;
  - the rush path and boss afterwards;
  - audio cues;
  - an exact replay with a highlight;
  - renders with and without Reduced Motion.

  `dusk_moth_boss_test.dart` now checks that the boss after the moth waits
  for the gale.
- `python3 tool/prepare_sound_effects.py` added `gust_warning.wav` and
  reproduced every other asset byte for byte.
- Gale art (a separate design pass): warning lanes and "!" badges, four
  debris shapes, region-aware wind, hit bursts, streamlines round the bird,
  and the gale banners. The inspected renders are in
  `build/visual-review/gale-*.png`. The "!" stands 0.6 in from the edge
  because the pause, Shoot and Sprint controls cover the edge itself.
- The full suite passed 632 tests. Two failures, `bird_trail_test` and a
  `world_regions_test` timeout, were in files a concurrent change was
  editing. Device playtesting is still pending, including the gust timing
  and 1.6× tailwind in `Gale`.

## 2026-09-26 eruption and swarm rush paths

- Rules version 32 was not yet committed, so it gains two more rush path kinds
  instead of a new version:
  - Eruption: lava vents under the route blow plumes as a cruising bird
    arrives.
  - Swarm: flocks of bats stream down the route and beside it.

  Runs now draw from a seeded shuffled bag of all four kinds, so every four
  runs meet each kind once. A new round never opens with the kind that just
  ran. Replay highlights and the escape banner name each kind's escape.
- The shared `rideTheSky` autopilot probed six seeds per kind, with every
  ring removed and with rings in place:
  - Chasing the rings, it chained 5–6 per run and was never hurt in any kind.
    It smashed 3–4 meteors in Skyfall and 3–8 bats in Swarm.
  - Without rings, Wildfire cost 2 burns, Skyfall 4–5 meteor hits and Swarm
    3–5 bat hits.
  - Without rings, Eruption cost 0–2 hits from bats and walls. Lava never
    hit, because the autopilot hops plumes. A route-following cruiser that
    doesn't hop is burned at its first vent, as a test shows.
- The probes led to these changes:
  - A bird 0.15 past a rumbling vent sets it off at once. Before, a sprinter
    was far off screen when vents blew, and vents could scroll away unerupted.
  - `flockInterval` rose from 1.2 to 1.4 seconds, with little effect on hits.
  - `rideTheSky` skips smashable hazards it will meet only after its next
    ring, including the run's own bats. It no longer dodges enemies while
    ramming. It aims 0.05 below a ring so its flap arc straddles the ring;
    before, it often hovered above rings and missed them. It keeps under
    the reach of vents that will be erupting as it passes, once the barrier
    before the vent is behind it. It also considers a lane 0.12 either side of
    the route.
- Over 200 seeds, recorded flights opened with each kind 47–51 times. Five
  of 40 recorded 50-second flights died on ordinary walls before their run
  started, which is an existing weakness of the autopilot's gate following.
- `test/rush_path_test.dart` now has 17 tests. The new ones cover:
  - the bag order over 12 seeds;
  - eruptions timed behind a sprinter and under a cruiser;
  - clearing a plume by flying over it, and a button sprint giving no
    protection inside one;
  - swarm lanes, chained smashes and cruising hits;
  - a rock downing a swarm bat.

  The layout and render tests cover all four kinds. The replay test now
  records seeds 8, 5, 3 and 30, which open with Wildfire, Skyfall, Eruption
  and Swarm, and checks that seeks reproduce vents, flocks and the bag. The
  audio test covers `lava_burst` and swarm smashes.
- Inspected the Eruption, Swarm, Eruption-behind and Swarm-warning renders
  in `build/visual-review/rush-*.png` and their `-reduced` variants. The
  pending vent marker was too faint on the pale sky, so it now has a stronger
  column and a deep-red dashed cap.
- `python3 tool/prepare_sound_effects.py` adds `lava_burst` in two takes and
  reproduces all 72 assets byte for byte on a second run.
- `flutter analyze --no-pub lib test tool` reports no issues. The full
  `flutter test --no-pub` suite passes all 526 tests. Device playtesting is
  still pending for all four kinds, including the vent and flock tunables in
  `Rush`.

## 2026-09-26 rush paths

- Rules version 32 adds touch Star Trail rush paths. Each is six beats of
  stars, a sprint ring, bats and a rubble barrier on one route, chased by a
  wildfire or showered by a skyfall. A ring starts a 2-second, 3× ring sprint.
  Chained rings extend it from the current speed with no dip. Either sprint
  breaks rubble as the bird passes. A ring sprint also breaks ordinary walls
  and smashes meteors. Escaping pays +10, or +20 unhurt. Bosses wait for a run
  in progress.
- Scripted autopilots probed the balance over six seeds before the tests were
  written:
  - Following every ring escaped every run unhurt. It chained 4–6 rings, broke
    the barriers, and smashed 3–4 meteors in Skyfall.
  - Ignoring every ring cost about three wildfire catches or meteor hits.
    Taking one ring cost about one hit in Wildfire and two in Skyfall.

  The probes led to four changes:
  - Aimed meteors now target the ring route at the bird's current speed, so a
    ring sprint meets them instead of outrunning them.
  - The fire is clamped close behind only during a ring sprint, keeping its
    flames on screen. A catch knocks it farther back than that.
  - Barriers break across their whole width.
  - Bosses no longer start once ordinary passages resume near a run's end.
- `test/rush_path_test.dart` has 12 tests:
  - gating by version, mode and course;
  - the route layout, with openings at the next ring's height, bats on
    alternate beats and spawns held;
  - the ring envelope, and chaining mid-surge and mid-ease;
  - breaks of walls, rubble, bats and meteors with no damage, and damage
    without a sprint;
  - fire timing, knockback and trailing;
  - a perfect run chaining all six rings at a constant 3×, breaking every
    barrier, escaping flawless and resuming passages behind the last barrier;
  - Skyfall smashing versus cruising hits;
  - the boss waiting for a slow run;
  - exact replay seeks with a replay highlight;
  - audio cues;
  - renders of both kinds in both motion settings.
- Existing tests needed four updates:
  - The shared `rideTheSky` autopilot now follows the ring route. Before that,
    the boss, door, power-shot and damage recordings died to the fire.
  - The sprint test's autopilot chases rings too.
  - The trio bound allows one run's six trios.
  - The audio fakes accept a take index.
- A new `SkyAudio` test checks that chained rings play takes 1, 2, 3 and then
  hold on 3.
- Inspected `build/visual-review/rush-{wildfire,skyfall,warning,escape}.png`
  and their `-reduced` variants, generated with `CAPTURE_VISUALS=true`.
- `python3 tool/prepare_sound_effects.py` adds eight assets and reproduces
  every earlier effect byte for byte. It no longer overwrites `game_over.wav`,
  which `tool/prepare_game_over.py` builds.
- `flutter analyze --no-pub lib test tool` reports no issues. The full
  `flutter test --no-pub` suite passes all 521 tests. Device playtesting is
  still pending, including the tunables in `Rush` and `RingSprint`.

## 2026-09-23 retire Courier and Cloud Cruise

- Sky Courier and Cloud Cruise are no longer playable. Flight School, the
  course picker and new flights offer Classic and Star Trail only. Saved
  journals and launch links that name either retired course open as Star Trail.
  Old score rows remain under their original course name and do not merge into
  Star Trail bests. Lifetime exercise totals and the both-wings stamp no longer
  count Courier-only runs.
- `flutter analyze --no-pub lib test tool` reports no issues. The full
  `flutter test --no-pub` suite passes all 503 tests. Device playtesting is
  still pending.

## 2026-09-23 wall rebound physics

- The wall-hit branch immediately consumed player rocks. Rules version 31
  keeps the spent shell visible, reflects its horizontal speed relative to
  the scrolling wall with energy loss, and lets gravity pull it down after
  a small upward kick. Breakable panels take damage once; returning shells
  cannot damage enemies or cancel their ammo. Shells retire offscreen.
- `test/rock_bounce_test.dart` first reproduced the disappearance, then
  verified the rebound and accelerating fall, every obstacle family, charge
  sizes, slow frames, clear openings, lethal and nonlethal panel hits,
  single impact audio, offscreen cleanup, pause freezing, legacy rules, and
  exact replay seeks in both motion settings. Existing floating-obstacle
  and combat checks now expect a rebound on impact.
- Render checks follow the visible stone through impact, return and fall.
  Inspected `build/visual-review/rock-bounce.png` and its Reduced Motion
  variant, generated with `CAPTURE_ROCK_BOUNCE=true`. Reduced Motion retains
  the trajectory while omitting impact squash and tumble.
- `flutter analyze --no-pub lib test tool` reports no issues; the full
  `flutter test --no-pub` suite passes all 574 tests. Device playtesting is
  still pending.

## 2026-09-23 sprint

- Rules version 29 adds a touch Sprint button with a 1.2-second burst and a
  15-second cooldown. The course scrolls up to 2.5× faster while the bird keeps
  its screen position. During the burst, touching an enemy defeats it
  regardless of HP, and touching a stone panel breaks it. Walls, course edges
  and projectiles still hurt. Enemy and boss projectiles rush left by the
  sprint's extra scroll while a boss holds its place.
- `test/sprint_test.dart` checks the boost envelope, earlier arrival with
  unchanged passage spacing, the cooldown from the press, pause freezing,
  countdown and cutscene blocking, rams of enemies with any HP, panel breaks
  with the walls still solid, and that enemy and boss ammo still hurt. It also
  covers version 28, camera and Cloud Cruise gating, controller journaling,
  and the whoosh and ready chime. In a boss fight, both kinds of ammo shift by
  exactly the extra distance the sprint covers, during and after the burst,
  while the boss matches a calm run. Exact forward/backward replay seeks
  include real rams, sprints into boss fire and projectile positions in both
  motion settings.
  Widget checks cover taps, recharging taps that never flap, semantics and
  keyboard activation.
- The touch flight UI test taps the real Sprint button during play, checks
  the burst, a 14-second countdown after 1.44 seconds and a rejected
  recharging tap, and confirms that neither press flaps.
  `flutter analyze lib test tool` reports no issues; `flutter test --no-pub`
  passes all 555 tests.
- Inspected `build/visual-review/sprint.png`, `sprint-reduced.png`,
  `touch-sprint-{640,800}.png` and `touch-flight-{640,800}.png`
  (`CAPTURE_VISUALS=true`). Captures show sky streaks, the bow wave and wind
  lines, a “SMASH +3!” label, and the gold, recharging and ready button states.
  Device playtesting remains pending.

## 2026-09-23 empty-ammo feedback

- The held-rock renderer previously drew a preview for unaffordable shots.
  It now hides that preview, and Shoot shows “Reloading…” with a muted icon
  until the reserve can pay for a shot, including while held.
- `test/ammo_reload_test.dart` reproduces the original flash with raster checks
  and verifies refill feedback, accessibility, and recovery in both motion
  settings. All 23 reload, power-shot, and touch UI tests pass; analysis of
  the changed Dart files reports no issues.

## 2026-09-23 power shots and ammo reserve

- Rules version 28 lets a held Shoot charge continuously for up to one second.
  Radius, damage and reserve cost rise smoothly with charge (2.4× width,
  4× damage, 10–45% of the reserve), and upgraded weapons scale the same way.
  The reserve refills after 0.45 seconds without firing, so rapid fire drains it.
  A shot at full charge fires itself after 500 ms. The window starts when
  the charge actually reaches full, and lifting afterwards does not fire again.
- `test/power_shot_test.dart` checks the continuous spectrum, the full-charge
  cap, the 500 ms auto-release (including when a low reserve delays full
  charge), drain and refill, reserve-limited charge, holding empty to refill,
  cancellation by pause and boss cutscenes, charged hits that a tap would miss,
  version 27 compatibility, controller journaling, a lift after auto-fire,
  audio cues and exact forward/backward replay seeks in both motion settings.
  Widget checks cover single-finger holds, lift/cancel/slide-off releases,
  keyboard holds, semantic taps and ammo/charge/countdown announcements; Shoot
  never flaps.
- The touch flight UI test holds the real Shoot button during play and checks
  the released rock's charge and damage. `flutter analyze --no-pub lib test`
  reports no issues; `flutter test --no-pub` passes all 555 tests.
- Inspected `build/visual-review/touch-charging-{640,800}.png` and
  `touch-flight-{640,800}.png` (`CAPTURE_VISUALS=true`): the glowing rock grows
  at the beak, the button's rings show reserve, pending cost and charge, and the
  released rock is visibly larger than a tap. Device playtesting remains pending.

## 2026-09-22 random breakable wall openings

- Rules version 27 adds a seeded 25% chance of a stone panel in a normal wall
  opening after boss 2. Panels have 40 HP and distinct damage at 30/20/10 HP;
  four base shots clear the opening immediately. Scrolling, flapping and boss
  timing continue normally. Consecutive panels, extra enemies on their own
  approach and panels on reward-heart gates are excluded.
- Checked wall versus panel hits, health thresholds, cooldowns, upgraded ammo,
  single destruction/audio, immediate collision clearance, intact surrounding
  walls, pauses, legacy rules and exact forward/backward replays in both motion
  settings. Boss 2 retains its heart reward and full interval before boss 3.
- `flutter analyze --no-pub` reports no issues; `flutter test --no-pub` passes
  all 513 tests. Phone-size render captures show the intact insert, progressive
  fractures and clear opening within ordinary walls. Inspected
  `build/visual-review/breakable-walls/{40,10,0}hp.png`, generated with
  `flutter test --no-pub --dart-define=CAPTURE_DOOR_ART=true test/stone_door_art_test.dart`.
  Device playtesting remains pending.

## 2026-09-22 enemy health and weapon damage

- Rules version 26 gives small enemies configurable HP by kind and encounter,
  scales boss HP to ten-point base shots, and captures damage on each projectile.
  Partial hits retain enemies; lethal hits clamp to zero and award a single
  defeat. Large hits correctly cross the boss fury threshold.
- Starting loadouts and recorded mid-flight damage changes reproduce across
  forward/backward replay seeks in both motion settings. Existing shots retain
  their damage, cooldowns remain enforced, and version 25 keeps its original
  one-hit enemies and one-point boss hits. Invalid HP and damage are rejected.
- `flutter analyze --no-pub` reports no issues; `flutter test --no-pub` passes
  all 499 tests. Coverage includes shields, arrivals, overkill, partial-hit audio,
  enemy/helper scaling, boss rewards, replay persistence and legacy rules.
- Rendered and inspected wounded enemy bars in
  `build/visual-review/small-enemies/health-bars.png`. Regenerated boss HUD
  captures with `CAPTURE_VISUALS=true`; three-digit health labels and segmented
  bars fit at 640×360 and 800×360. Physical device playtesting remains pending.

## 2026-09-22 focused match HUD

- Removed persistent mode/region labels, pace/time counters for endless flights,
  repetition counts, record targets, wing cards and instruction strips. Score,
  hearts/shield, relevant ability meters and controls remain; Courier uses
  Pick up / Deliver. Tracking warnings still appear when needed.
- Added illustrated HUD symbols, brief state-change pulses, circular controls
  with press feedback, and a Shoot cooldown ring. Both Reduced Motion settings
  suppress decorative movement. Controls retain tooltips, semantic labels and
  keyboard focus; passive readouts continue to pass touches through to flight.
- Flutter analysis is clean and 33 focused tests pass across touch input,
  scoring, record audio, results, Courier/replay, jump glide and all three bosses.
  Captures at 640×360 and 800×360 verify safe-area layout, cooldown touches,
  simultaneous shooting/flapping and four/five-heart counts. Inspected the
  rendered normal, boss, magnet and glide HUDs under `build/visual-review/`.
  Physical device playtesting remains pending.

## 2026-09-22 post-boss heart pickup

- Rules version 24 places one heart in a seeded random safe opening among the
  next 2–7 gates after each touch Star Trail boss victory. Collecting it adds
  one life up to a five-heart cap; older replay rules keep their RNG flow.
- Focused heart, boss, cinematic, replay and phone HUD checks pass.
  Coverage includes all three bosses, repeated rewards across seeds, collection
  on slow frames, missed hearts, pause/countdown/game-over freezes, later damage,
  legacy rules, deterministic placement, four/five-life HUD counts, and pickups
  at the cap without false extra-life feedback.
- Flutter analysis reports no issues. Inspected the rendered heart and '+1 LIFE!'
  feedback in `build/visual-review/heart-pickup-640.png` and
  `build/visual-review/heart-collected-800.png`; captures cover both 640×360 and
  800×360, including Reduced Motion. Physical device playtesting remains pending.

## 2026-09-22 Spitter King dodge spacing

- Rules version 23 removes the center projectile from full acid fans (five
  shots become four) and widens fan spacing from 0.18 to 0.30 radians. Fury
  uses the same open-center fan; firing cadence, speed and summons stay intact.
  Versions 21–22 keep their original attack patterns for saved replays.
- A trajectory regression failed on the old center shot and now verifies a
  bird-sized lane plus margin at 640×360 and 800×360, at three target heights
  in normal and fury phases. All 39 focused Spitter, boss combat, moth and
  session replay tests pass. Flutter analysis reports no issues.

## 2026-09-22 Dusk Empress crown perspective

- The dedicated crown subagent replaced the front-facing tiara with a
  left-facing circlet. A narrow forehead plate carries the foreshortened
  gem and crescent, while the broad near band, shaded rear bevel, elliptical
  opening and partly hidden far prongs give the crown depth around the skull.
  Its fitted attachment and defeat release remain intact.
- Inspected the actual Flutter head close-up at
  `build/visual-review/dusk-moth-crown-profile.png`, phone pose sheet, and live
  reveal at 800×360. Six focused art tests and both 640×360/800×360 live UI
  checks pass. Full static analysis is clean, and gameplay hashes are unchanged.

## 2026-09-22 Dusk Empress crown seating

- A second dedicated subagent corrected the crown's rearward placement and
  detached angle. Its anchor now follows the head crest, and its lower rim
  follows the skull's upper curve with slight overlap. Independent crown
  lift and tilt are removed while attached; the taller moon remains distinct
  from the antennae. Defeat releases it from the seated position and angle.
- Raster checks verify contact and attachment through hover, charge, recoil,
  hits, arrival and pre-release defeat, plus continuity at release. Inspected
  the updated phone sheet and live reveal/shield captures at both phone sizes.
- Full static analysis is clean and all 451 tests pass. Gameplay hashes still
  match the state before the design refinement.

## 2026-09-22 Dusk Empress and silk-shield refinement

- A dedicated design subagent refined the moth with velvet rose wings,
  pearl scalloped hems, shaded fur, connected antennae and a crescent diadem.
  Wings draw inward as the shield forms. The shield now has a woven border,
  lunar clasps and visible blocked-shot ripples, with a transparent center.
- The HP instruction stays pale blue while the shield forms or is active,
  including during fury. Live UI captures at 640×360 and 800×360 verify the
  warning, active shield and blocked shot; the shot leaves HP unchanged.
- Focused rendering checks cover the fixed pollen port, complete shield rim,
  clear center, charge and impact cues, deterministic seeks and Reduced Motion.
  Full static analysis is clean and the refined-design suite passes 449 tests.
  Gameplay file hashes match the pre-refinement state.
- Inspected `build/visual-review/dusk-moth-phone-sheet.png`, the nine-state
  pose sheet, and live reveal/shield/block captures. Physical playtesting
  remains pending.

## 2026-09-22 Dusk Empress third encounter

- Rules version 22 adds the Dusk Moth boss after Baron Bat and Spitter King,
  then repeats the three-boss sequence. The moth starts at 24 HP, fires faster
  five/seven-shot pollen fans and summons dusk moths. Its silk shield warns
  for 0.8 seconds and blocks shots for 1.6 seconds every eight combat seconds.
- Shield hits consume rocks without damage or score, warning windows remain
  vulnerable, and fury does not reset the shield cycle. Domain checks cover
  repeated encounters, HP caps, cleanup, helper approach, bounded ammo,
  pause/countdown and exact backward replay seeks. Version 21 keeps its old
  alternating sequence; versions 15–20 retain the all-bat fights.
- The third encounter is defeated using cooldown-limited shots and regular
  flap inputs at 640×360 and 800×360, without health or position overrides.
  Wider fan spacing and a farther-right hover leave dodge room on phones.
- Flutter analysis reports no issues and the full suite passes all 447 tests.
  Rig checks cover deterministic animation and Reduced Motion with readable
  charge, warning, shield and fury cues. Live UI checks cover the new name,
  shield semantics, touch controls and cinematic transitions at both widths.
- Inspected the actual Flutter reveal, shield and fury captures under
  `build/visual-review/dusk-moth-boss-*.png` and the moth pose sheet. UI captures
  stage hovering, health and final hits to show the whole encounter; they are
  separate from the legal-input survival tests. Physical playtesting is pending.

## 2026-09-21 opening structures and enemy characters

- Separate Cursor Grok 4.7 Extra High workers authored the opening structures
  and enemies, with additional workers auditing fresh gameplay and integrating
  the versioned artwork. The first three gates now show a conservatory,
  terracotta blossom column and bamboo grove. Enemies cycle through a moon
  bat, armored beetle and dusk moth, including boss helpers.
- The new artwork starts at rules version 16. Versions 14 and 15 retain the
  previous garden and enemy painters. Appearance selection consumes the same
  random draws as before; version 15/16 simulations have matching gameplay
  state, geometry and boss encounters under the same inputs. The concurrent
  boss animation work has since advanced fresh games to version 17.
- All 55 focused tests passed across `opening_designs_test.dart`,
  `opening_obstacles_art_test.dart`, `obstacle_designs_test.dart`,
  `touch_combat_test.dart` and `endless_flight_test.dart`. These cover variant
  cycling, replay seeks, Reduced Motion, opaque collision bodies, clear lanes
  and unchanged physics. The opening audit now runs all 16 course/control
  combinations for 18 seconds without ending; its previous in-progress
  survival and capture issues are resolved.
- Actual `BirdGame` opening captures show the new gate and enemy route at
  1000×450. Reviewed `build/visual-review/opening-*.png` and the character
  sheet `build/visual-review/opening-gates-and-enemies.png` at phone size.
- Static analysis reported no issues. The full workspace test run reached
  401 passing tests and five failures in the concurrently changing boss
  simulation/UI tests, whose expectations still used the earlier entrance
  duration. The opening/enemy tests all passed; this is not a claim that the
  ongoing boss animation iteration has completed validation.
- The Android arm64 release build succeeded (64.6 MB). A copy is saved as
  `build/releases/opening-gates-enemies-arm64.apk`. Physical-device playtesting
  remains pending.

## 2026-09-21 obstacle detail refinement

- Version 14 selects the new painters for all seven obstacle families and
  Cloud Cruise rings. Gameplay uses that art when `rulesVersion >= 14`.
  Saved version 13 replays keep the previous ObstacleArt, and older replays
  keep their original gate path. Physics, spawning, random draws, collision
  and cadence are unchanged.
- `flutter analyze --no-pub` reported no issues.
- `flutter test --no-pub test/obstacle_designs_test.dart` passed. It checks
  that refined and legacy pixels differ for all seven families and rings,
  that fixed-geometry refined art repeats and matches at 5s and 9s under
  Reduced Motion, that every appearance renders, that solids stay opaque
  inside collision rects and clear outside, that thin rectangles still paint,
  and that circles are filled with a drawn edge while rings keep an open center.
- `flutter test --no-pub` on `test/endless_art_test.dart`,
  `test/endless_flight_test.dart`, and `test/obstacle_variety_test.dart`
  passed, including the version-14 replay expectation and the existing
  lane-clearance checks.
- `flutter test --no-pub --dart-define=CAPTURE_VISUALS=true test/endless_art_test.dart`
  regenerated `build/visual-review/obstacle-variety.png` and
  `build/visual-review/variety-*.png`.
- Eight separate Cursor Grok 4.7 Extra High workers authored the seven obstacle
  families and Cruise rings. Each family has three appearance variations.
- The parent review checked every variation and phone-sized gameplay captures
  against bright and twilight backgrounds. The complete comparison is saved at
  `build/visual-review/obstacle-all-variations.png`.
- `flutter test --no-pub --reporter expanded` passed all 387 tests.
- `flutter build apk --release --target-platform android-arm64 --no-pub`
  produced the 64.5 MB release APK. Physical-device playtesting remains pending.

## 2026-09-21 smoother Jump descent

- The final 1.25 seconds of glide now gradually increase falling speed from
  0.06 toward 0.20 viewport heights per second. That cap remains after the
  charge expires, removing the sudden return to full gravity. Star refills
  also slow the bird gradually, and the ending cue starts with the transition.
- The upward boost is preserved. Replay version 11 enables the new descent;
  recordings from versions 9 and 10 retain their original glide physics.
- All 338 Flutter tests pass and static analysis is clean. Regression checks
  cover the transition before and after expiry, smooth star-refill braking,
  and historical replay behavior.
- The Android arm64 release APK builds successfully and passes the offline
  model and 16 KB alignment checks for all 15 packaged native libraries.
  Device installation is pending reconnection of the phone.

## 2026-09-21 regular course for Jump & Fly

- Jump uses the regular Star Trail game with buildings, stars, hearts and no
  enemies. Old Cloud Cruise diagnostic launch links now select Star Trail;
  saved replays keep their original course. The menu describes this behavior.
- Static analysis and 19 targeted menu, jump, glide and combat tests pass.
  The release APK passes offline-model and 16 KB native-library checks.
- Installed the release APK on the connected phone and opened Jump mode;
  the device shows `STAR TRAIL · SCORED` with the charged-jump instructions.

## 2026-09-21 body-motion jump detection after failed device retry

- The next device capture disproved the earlier sensitivity adjustment: the
  player waited 39.007 seconds for calibration, got one accepted jump, and the
  game automatically paused when foot confidence dropped.
- An independent subagent traced the failures to foot jitter resetting standing
  calibration and estimated toe motion disagreeing with clear torso takeoffs.
  Jump calibration now uses a robust one-second torso window, and the jump
  signal uses coordinated hip/shoulder rise with a noise-adjusted threshold.
  Lower landmarks establish framing with ankle/toe fallback. Deliberate body
  bounces count; the mode no longer promises to distinguish every calf raise
  from a small hop.
- `tool/replay_jump_session_test.dart` feeds the original private landmarks
  through the real controller, countdown and simulation. Cloud Cruise keeps
  collisions from ending the replay while checking input. The new capture
  calibrates at 9.843 seconds (about one second after body entry), accepts nine
  distinct takeoffs and remains playing. The stationary portion produces zero
  boosts. The earlier capture also accepts seven boosts and remains playing.
- Opt-in diagnostics now record the learned jump baseline, threshold and each
  jump's actual acceptance by the simulation, including game phase and count.
  Interpreter-only replay totals are explicitly labeled because countdown or
  paused events do not boost the bird. Captures remain outside the repository.
- All 335 automated tests pass and static analysis is clean. New checks include
  foot jitter during standing, brief missing frames, continuous movement during
  calibration, small hops with inverse foot estimates and shoulder-only motion.
- Built and installed the replacement Android arm64 profile APK with landmark
  diagnostics at 19:54 local time. Opened Cloud Cruise practice on the connected
  phone for a collision-free input check. Physical verification is pending.

## 2026-09-21 Squat & Fly

- Added a fourth control after the Jump & Fly task completed: squat to descend,
  stand to rise, with both feet planted. Guided calibration learns a standing
  position and a comfortable squat, then confirms the return to standing.
- Hip height above the ankles drives continuous bird altitude, with a
  three-frame median, 65 ms smoothing and endpoint margins. Full cycles count
  as squats. Missing/stale frames, lifted feet and camera-distance changes
  reject input; a tracking interruption cannot finish a repetition.
- Added scored/practice menu entries, illustrated setup, calibration preview,
  in-flight/result counts, camera-lab support, daily-adventure and Flight School
  launchers, separate personal bests and persistent squat totals. Scored flights
  contribute to unlocks, daily goals and passport progress; practice does not.
- Appended mode index 3 and introduced replay version 10. Existing mode indices
  and historical replay physics remain intact. Squat height, counts, pauses and
  backward replay seeks are covered by automated tests across all courses.
- Static analysis is clean and all 323 Flutter tests pass. Tracking tests cover
  smooth movement at 15/20/30 Hz, different camera scales, jitter, leaning,
  one-frame spikes, lost joints, stale/duplicate frames and interrupted squats.
- Inspected Flutter renders of setup and records at 800×360 and calibration at
  640×360 under `build/visual-review/squat-*.png`, plus the four-control daily
  adventure screen. Layout checks pass without overflow.
- ARM64 release APK builds successfully (64.3 MB). Bundled offline models,
  all 15 native libraries' 16 KB ELF alignment and 16 KB ZIP alignment pass.
  APK SHA-256: `d371514bf9a71c699569f42290f5db08d1127ebd58fa1ce0478a7d4f4ee2adea`.
- No Android device is connected. Physical camera sensitivity, viewing comfort
  and performance remain pending; tests use synthetic body landmarks.

## 2026-09-21 charged jumps

- A physical jump now banks three seconds of gliding after the upward boost.
  Descent is limited to 0.06 viewport heights per second while charged. Stars
  add 0.75 seconds, capped at five; they cannot start or revive an empty charge.
  A new jump boosts immediately and refreshes at least three seconds while
  retaining extra time earned from stars.
- Pauses and countdowns preserve glide time. Existing collisions, tracking loss
  and course endings remain active. Version 9 replay journals reproduce charge,
  star-extension feedback and wing pose; earlier journals retain their physics.
- Setup explains the mechanic. The flight HUD shows the remaining reserve,
  a star-extension message and an ending cue; saved replays show glide time.
  Gliding spreads the bird's wings, with the neutral Reduced Motion pose retained.
- Static analysis is clean and all 301 Flutter tests pass.
- Targeted physics tests cover exhaustion, one reward per star, the cap, refresh,
  pauses/countdowns, invalid input, collisions and old controls. The same Cloud
  Cruise input policy uses at least 25% fewer jumps than version 8 while still
  collecting stars and discovering all three cloud friends.
- Inspected actual Flutter renders of setup, active glide, star rewards and
  low charge at 640×360 and 800×360 under `build/visual-review/charged-jump-*.png`.
  The glide meter sits above the existing course HUD without overlapping it.
- ARM64 release APK builds successfully. Offline-model and 16 KB alignment
  checks pass for all 15 packaged native libraries.
- No Android device is connected; physical camera playtesting remains pending.

## 2026-09-21 Jump & Fly replaces smile mode

- Both movement modes now request MediaPipe pose tracking. Jump mode calibrates
  a stable standing body for one second, then requires torso rise and both feet
  lifting for two frames; a stable landing rearms the next boost. The setup and
  camera lab show a full-body guide and jump instructions.
- Jump boosts use impulse −0.55 and gravity 0.55: approximately 2.9× the previous
  smile flap height and 2.1× its airtime. Wider passages, slower scrolling and
  longer spacing allow time between physical jumps. Jump counts stay separate
  from push-up repetitions; touch physics are unchanged.
- Existing record indices remain valid. Old `smile` routes, session summaries
  and input journals are accepted; replay versions before 8 retain their original
  physics. New sessions save the `jump` name and version 8.
- Static analysis is clean. All 288 Flutter tests pass, including jump calibration, jitter, crouching,
  calf raises, missing feet, stale/future/duplicate frames, tracking loss,
  camera distance changes, landing rearm, 15/20/30 Hz jump trajectories, native
  detector selection, controller flow, physics and legacy replay compatibility.
- Rendered the menu and scored/practice jump setup at 800×360 and inspected
  `build/visual-review/jump-mode-menu.png`, `jump-mode-setup.png` and
  `jump-practice-setup.png`; no layout overflow.
- Release ARM64 APK built successfully; bundled tracking models and 16 KB
  alignment checks pass for all 15 packaged native libraries.
- No Android device is connected. Real camera jump sensitivity and physical
  playability still require a device check.

## 2026-09-21 home menu refinement

- Camera push-ups have the primary card and an explicit start action. Touch has
  a separate card labeled “No camera needed”; smile and both camera-practice
  links remain available. Flight School and Settings sit in the header; daily
  goals, bird unlocks, Passport, Records and Flight goals form the lower menu.
- Static analysis is clean. All 22 targeted menu, course, touch, daily, school,
  experience and courier UI checks pass, including the camera-free touch flow.
  Actual Flutter renders at 640×360, 800×360 and 1000×450 were inspected.
- A new Figma composition reuses the existing fonts, tokens, buttons and bird
  artwork. Its IDs and screenshot locations are recorded in
  `design/home-menu.json`; earlier compositions are preserved.
- No Android device was connected; device interaction was not checked.

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

- 2026-09-30 body-detection review. No phone was attached and the
  `/tmp/push-up-bird-diagnostics` backups are gone, so the five fixtures are
  the only surviving traces; all were replayed. **`last_game_top` is a head-on
  view, not a side view**: from 15.8 s the shoulder span is 1.1–2.4 torso
  lengths, the hands are under the shoulders and the hips sit between. Before
  that the player is upright by the phone (shoulders y≈0.2, hips y≈0.8, hands
  hanging at the hips, elbows 160–180°). The side-view check (arm ≥ 20° from
  the torso) accepted 204 of those 271 frames as a plank. The calibrator found
  a steady "top" at 8.2 s, locked the side view, and `_restart()` kept that lock
  when the real plank began. The plank was then measured without its strongest
  cue (shoulder drop) and 62 of its frames failed side-only checks. That is
  how the original run came to be recorded as a side view; the earlier notes'
  "side game" is this session.
- Upright bodies are now rejected in either view when the arm is within 45° of
  the torso, the torso is at least 0.8 of the arm's length (front-view planks
  reach 0.77 at p99; upright arms 0.84 at p1) and the hand reaches 0.45 torso
  lengths down towards the hip (a deep side-view bottom sits near 0.2–0.35).
  Replayed: 38 of the 271 upright frames remain valid (one arm reaching out
  sideways, which the 0.8 s steady hold filters), and 4 of 2,130 plank frames
  are rejected, all as the player lifts a hand at the end of a recording. The
  steady top's frames now vote on the view; a tracking loss over 0.5 s
  releases it even while frames stay invalid (a moved camera previously left
  calibration waiting forever for "both shoulders"), and a changed view
  discards completed cycles. `last_game_top` now stays in `position` through
  the upright period, locks the front view at 16.6 s with the shoulder-drop cue
  and learns its one deep push-up as cycle 1 at 27.8 s; every plank frame is
  valid. Gameplay heights from the `front_pushups` calibration are unchanged on
  `front_pushups`, `front_extended_top` and `front_calibration_hold`. Three new
  regressions fail on the previous code; all 31 tracking tests and analysis
  pass. In the full suite, `play_button` (2) and `stone_door_art` fail
  identically with and without this change. Physical acceptance is pending.
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
  the explicit camera-paused gap. Pause a scored flight, background and return,
  then Keep flying: it should count in from three, and Finish flight should save
  the break as its ending.
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

### Touch difficulty and rock shooting

Touch now has a stronger flap, narrower gaps and closer buildings. Bats appear
on alternating approaches in Classic, Star Trail and Sky Courier. Shoot fires
a straight rock from the rendered beak, with a 280 ms cooldown; buildings stop
rocks, one hit defeats a bat, and Star Trail awards 3 points. Enemy contact uses
each course's existing collision/recovery rules. Cloud Cruise has no enemies.

`flutter analyze --no-pub` is clean and all 278 Flutter tests pass. New checks
cover the harder cadence, beak alignment with motion enabled/disabled, straight
trajectory, misses, wall blocking, slow-frame hits, shield/heart/courier damage,
cooldown, pause/retry, and deterministic replay including backward seeks. Version
6 touch recordings retain their original physics and reject shoot events.
Widget checks at 640×360 and 800×360 cover shooting without flapping, cooldown
touch isolation, simultaneous flap/shoot touches, and saved gameplay replays.
The setup and gameplay captures in `build/visual-review/touch-*` were visually
checked. Difficulty feel on a physical touchscreen still needs playtesting.
The Android arm64 release APK also builds successfully with
`flutter build apk --release --target-platform android-arm64 --no-pub`.
## 2026-09-21 missed jumps on the connected Android phone

- Replayed the user's opt-in landmark recording through the real jump
  calibrator and interpreter. The original code detected zero jumps despite
  repeated torso rises. A shortened recording containing calibration and the
  first takeoff also reproduced the failure.
- The per-foot lift threshold rejected uneven projected foot motion. Brief
  invalid poses erased a confirmed landing, and requiring feet to return to
  the original calibration position prevented subsequent jumps. The detector
  now combines smaller foot lifts, preserves landing evidence across brief
  rejected frames, and updates its foot reference at confirmed landings.
- The same recording now yields seven detections on distinct takeoffs, with
  no detections while approaching the camera or standing. The user's estimated
  count was four to five, so the exact physical count still needs confirmation.
  The minimized first-takeoff replay detects exactly one jump.
- Regression tests cover small hops, the recorded asymmetric foot motion,
  landing at different image positions, and brief missing/late/distorted
  poses. Existing crouch, calf-raise, one-foot-lift, jitter and sustained-loss
  rejection tests still pass. The controller test also verifies that a small
  hop produces the full bird boost. All 328 tests pass; analysis is clean.
- Installed the updated Android arm64 profile APK with landmark diagnostics
  enabled on the connected phone. A fresh physical retry is pending.

## 2026-09-21 endless flights and moving passages

- Replay rules version 12 removes timed endings and final-stretch cues from new
  flights, smoothly increases speed with elapsed play time, and mixes garden
  gates with Wind Lifts, Petal Shutters and split Switchbacks. Old recordings
  retain their original movement, score, countdown and arrival art.
- All 371 Flutter tests pass; `flutter analyze --no-pub` reports no issues.
  Twenty-four five-minute simulations cover all courses with push-up and squat
  control at 1-, 4- and 9-second calibrated cycles. They verify continuous play,
  obstacle variety, bounded active objects, intact shields/hearts, reachable
  stars and no courier bumps. Speed progression is checked for all four controls.
- Physics checks cover moving openings, both switchback columns, slow frames,
  pause/countdown freezes, following pickups, deterministic backwards replay
  seeks and the legacy timed endings. Saved endurance progress counts collision,
  break and quit results at or beyond 60 seconds, excludes practice and other
  courses, and remains idempotent on duplicate saves.
- Rendered and inspected the four obstacle designs in the game scene and the
  updated elapsed-time/pace HUD. Pixel checks keep decoration out of the moving
  opening. Widget checks keep the new clock clear of the personal-best badge.
  Captures are in `build/visual-review/endless-obstacles-*.png` and
  `build/visual-review/star-trail-flight.png`.
- The Android arm64 release APK builds successfully with
  `flutter build apk --release --target-platform android-arm64 --no-pub`.
  Physical-device playtesting of the new pace and obstacle motion is pending.

## 2026-09-21 obstacle design and variety pass

- Seven obstacle families now mix throughout a flight. Added floating lantern
  pairs, orbiting sun wheels and moving crystal steps, with round collision
  bodies for floating obstacles. Refined lifts into turbines and bellows,
  shutters into blossoms and leaves, and split towers into faceted structures.
  Non-garden families have three seeded color/detail variations. Cruise rings
  share the new colors, beads, stars and crystal details.
- All 381 Flutter tests pass and static analysis is clean. Existing five-minute
  simulations encounter all seven families without rushing calibrated movement.
  New tests check actual round-body collisions, open-sky bypasses, rock blocking,
  scoring-width bounds, pause freezes, staggered crystal columns, mixed patterns
  and visual variations. Pixel tests verify that all designs leave their moving
  passage visibly clear. Version-12 seeded results and obstacle positions match
  the captured baseline; new version-13 replays reproduce appearance and motion.
- Visually inspected the generated eight-panel design sheet and in-game renders
  across the three sky regions. Preview: `build/visual-review/obstacle-variety.png`;
  game captures: `build/visual-review/variety-*.png`.
- Physical-device playtesting of the new obstacle motion remains pending.
- The updated Android arm64 release APK builds successfully (64.4 MB).

## 2026-09-21 touch boss encounters

- Rules version 15 adds Baron Bat after 45 seconds of touch flight, clears
  normal passages for the fight, and returns to ordinary flight after victory.
  Tests cover entrance safety, HP and rock interception, aimed/spread ammo,
  helpers, enraged attacks, shield/recovery/heart damage, course gating,
  one-time rewards, cleanup, rematches, pause/countdown/end freezes, and a
  victory using ordinary flaps and cooldown-limited shots.
- All 12 boss simulation/UI tests pass. Two 170-second input journals reproduce
  multiple victories and exact state on backwards seeks with Reduced Motion
  on and off. Versions before 15 never enter boss encounters.
- Visually inspected arrival, fighting, enraged and defeated scenes at 640×360
  and 800×360. The boss HUD replaces normal top-center readouts while fighting;
  Shoot remains accessible and the score moves to the lower-left readout.
  Captures: `build/visual-review/boss-*.png`.
- Static analysis is clean and the Android arm64 release APK builds (64.5 MB).
  The full workspace run reached 399 passing tests, but the concurrently added
  `opening_obstacles_art_test.dart` failed its Classic/push-up survival check
  and stalled in its rendering check; that run was stopped. Rerunning with
  only that in-progress test file excluded passes all 399 remaining tests.
  Physical touchscreen playtesting of boss difficulty remains pending.

## 2026-09-21 cinematic boss presentation

- Rules version 17 adds a 4.6-second storm warning and staged entrance, a
  layered Baron Bat rig, charge and recoil animation, and a 3.8-second defeat
  with a stagger, impact burst, debris, detached crown and victory card. The
  bird coasts safely during both sequences. Versions 15 and 16 retain their
  original encounter timing and presentation.
- All 410 Flutter tests pass with no exclusions, and `flutter analyze --no-pub`
  reports no issues. Checks cover cutscene input safety and timing, deterministic
  animation, Reduced Motion, one-shot audio cues and silent replay seeking.
  Existing multi-encounter replay, fight completion and small-screen UI checks
  pass. The Android arm64 release APK builds successfully (65.1 MB).
- Rendered and inspected the warning, reveal, combat, fury, stagger, burst and
  victory at 640×360 and 800×360. A 410-frame, 30 fps choreography preview uses
  the actual game renderer and synchronized generated sound effects, with
  staged final hits to demonstrate the full sequence in 13.7 seconds:
  `build/visual-review/boss-cinematic-preview.mp4`.
- Host Flutter test rasterization at 800×360 measured a median 5.82 ms and
  p95 8.32 ms per rendered image. These are host render measurements, not
  device frame-rate results. Physical-device performance, touchscreen
  difficulty and speaker mix still need playtesting; no device was installed
  or changed for this presentation pass.

## 2026-09-21 directional small enemies and ranged attacks

- Three separate art subagents redesigned the cave bat, spitter beetle and
  dusk moth. Their profiles face the bird, eyes track its height, and wings
  articulate independently. The bat remains a simple contact enemy; beetles
  charge one aimed mint pellet, and moths charge a slower three-shot amber fan.
  Rules version 18 gates both the new artwork and attack behavior, preserving
  earlier journals.
- All 421 Flutter tests pass without exclusions; static analysis and
  `git diff --check` are clean. New checks cover visible windups, distinct
  projectile trajectories, fixed aim, no off-screen or posthumous attacks,
  rock interception, building collisions, course damage, pause/countdown,
  boss cleanup, narrow-screen summons, legacy gating and exact replay seeks
  while both projectile types are active.
- Inspected the enlarged lineup, gameplay-size silhouettes, charge/recoil
  poses and an actual 800×360 game render. Art checks verify animated wing
  changes and exact Reduced Motion frames. Preview artifacts are
  `build/visual-review/small-enemies/lineup.png`,
  `build/visual-review/small-enemies/in-game.png`, and the four-second
  `build/visual-review/small-enemies-preview.mp4`. The motion sheet stages
  attack poses; simulation tests separately verify actual firing behavior.
- Android arm64 release APK builds successfully (65.1 MB). Physical-device
  difficulty and visual readability during touch play still need playtesting;
  no device was installed or changed for this pass.

## 2026-09-22 simple bat and preserved cave bat

- Rules version 19 adds a plain purple bat based on the boss's body, face and
  wing shapes, omitting crown, cape, armor, gem, gold trim and wing stars. The
  original cave bat remains a fourth normal-flight character. Boss summons
  use the simple bat alongside beetles and moths. Both bat types are ordinary
  one-hit contact enemies.
- Extended existing rotation, attack and rendering checks to include the
  fourth character. Inspected the updated four-character lineup and actual
  800×360 game render, including both bats together. The shared boss renderer
  defaults to its full decorated appearance; the plain bat selects the
  simplified appearance and continues to track the bird with its eyes.
- Updated preview images and the four-second animation in
  `build/visual-review/small-enemies/` and
  `build/visual-review/small-enemies-preview.mp4`.
- All 421 Flutter tests pass, analysis reports no issues, and the Android
  arm64 release APK builds successfully (65.1 MB). No device installation
  was performed.

## 2026-09-22 natural enemy flight

- Rules version 20 adds small vertical flight arcs, slight banking and
  independently phased wingbeats for all four small enemies. Beetles have a
  tighter hover; moths drift more slowly. Charge and recoil steady the body,
  and the final approach eases back into the original aiming lane.
- The shared moving position drives rendering, collision and ammo emission.
  Checked bounded displacement, an actual hit against a bobbing body, pause
  freezes, old straight-flight behavior and exact replay reconstruction.
  Reduced Motion preserves the gameplay path but freezes decorative bank
  and wing motion. The existing opening-flight survival checks pass after
  smoothing the final approach.
- Regenerated and inspected the design-sheet animation at enlarged and
  gameplay sizes: `build/visual-review/small-enemies-preview.mp4`.
- All 422 Flutter tests pass; analysis and `git diff --check` are clean.
  Android arm64 release APK builds successfully (65.1 MB). No device
  installation was performed.

## 2026-09-22 spitter beetle refinement

- A fresh dedicated subagent refined only the beetle renderer: lifted hard
  wing cases, translucent flight membranes, compact head, distinct thorax
  and segmented abdomen. Wings move independently and turn edge-on; antennae
  and legs follow through. Charge fills the mint cheek, tucks the legs and
  braces the shell; a damped recoil settles after release.
- Parent and subagent reviewed close-up and exact gameplay-size renders of
  cruise, charge and spit. The lip remains at local (-1.05r, 0) through cheek
  squash. Existing Reduced Motion render checks pass. The domain attack
  timing, flight paths, damage and hit radius are unchanged.
- Updated the lineup and actual 800×360 game render. Added a focused
  1000×520, 30 fps, five-second motion sheet at
  `build/visual-review/spitter-beetle-preview.mp4`. Its attack poses are
  staged to show the complete charge and release cycle at both scales.
- All 422 Flutter tests pass, static analysis reports no issues, and
  `git diff --check` is clean. Android arm64 release APK builds successfully
  (65.1 MB). No device installation was performed.

## 2026-09-22 Spitter King second boss

- Rules version 21 alternates Baron Bat and Spitter King, starting with the
  bat. The beetle's first encounter has 18 HP, faster three/five-shot acid
  fans, a wider hover and beetle helpers. At half health, five-shot fans and
  summons accelerate. Older journals retain their original bat encounters.
- Added a horned helm, gilded shell trim and green attack effects to the
  articulated beetle anatomy. Shared entrance, defeat, audio and rewards now
  show the active boss's name, including the accessibility label. The beetle
  sheds its own helm in the defeat burst.
- Verified four successive encounters, the full flight interval between
  bosses, legacy second-boss behavior, aimed trajectories, fury, narrow-screen
  summons, bounded hazards, pause/countdown freezes and normal-input victory.
  Replay snapshots include boss identity, volleys and summons. Pixel checks
  confirm seekable animation and Reduced Motion with visible charge/fury cues.
- Inspected entrance, combat, fury and defeat captures at 640×360 and 800×360,
  including Reduced Motion. Images are in
  `build/visual-review/spitter-boss-*.png`.
- All 431 Flutter tests pass; static analysis and `git diff --check` are clean.
  The Android arm64 release APK builds successfully (65.1 MB). Physical-device
  difficulty remains untested; no device installation was performed.

## 2026-09-22 Spitter boss brewer redesign

- A dedicated subagent replaced the enlarged small-beetle anatomy and crown
  with a bespoke airborne acid brewer: broad copper shell, battered hat,
  goggle, bubbling glass tank, pressure gauge, feed hose and claw arms.
- Added a hat-tip entrance, four independently phased fan wings, pumping
  pressure buildup, cheek inflation, tank slosh and hat recoil, a beckoning
  summon gesture, hot fury vents and curling defeat limbs. The parent
  integrated authored hat/eye anchors, acid charge bubbles, a droplet pressure
  burst and tumbling hat debris into the actual encounter.
- Focused pixel checks verify deterministic seeks, stable Reduced Motion,
  retained charge/fury cues, distinct anatomical attack/defeat states and a
  fixed mouth origin. All 435 Flutter tests pass. Static analysis and
  `git diff --check` are clean.
- Inspected the pose sheet, ordinary-enemy comparison and gameplay at
  640×360 and 800×360. Captured 410 actual game frames with synchronized audio
  at `build/visual-review/spitter-boss-cinematic-preview.mp4`; final hits are
  staged to show the complete defeat. The pose sheet is
  `build/visual-review/spitter-brewer-pose-sheet.png`.
- Android arm64 release APK builds successfully (65.1 MB). Gameplay timing,
  difficulty and encounter order are unchanged by this visual pass. No
  physical-device installation or testing was performed.

## 2026-09-22 bird trails follow the flown path

- In-flight trail marks now sit on the bird's recent path, spaced evenly along
  it, and continue level behind the bird until enough path exists. The
  simulation records the path per substep without affecting physics, RNG or
  the replay format, so replays rebuild it after a seek. Reduced Motion and the
  crew preview keep the straight trail.
- New tests check the recorded path, deterministic backward seeks in every
  control mode, and mark placement along a climb and past the path's end. All
  519 Flutter tests pass and static analysis is clean. A real tap flight was
  rendered at `build/visual-review/bird-trail-path.png`; no device testing was
  performed.

## 2026-09-23 star-group aura

Replaced connected constellations with a small gold halo at the last star of a
fully collected group. It fades over 650 ms at that star's scrolling position;
Reduced Motion keeps its size fixed. Partial/missed groups draw nothing extra.
New flights have no charge slots, collection labels, orbiting
stars or star-triggered bird expressions/trail changes. Group scoring matches
version 29: all three stars in the same group are required for the flat +5.
The original quiet pickup/group sounds remain. Pre-version-30 replays keep
their previous presentation.

Validation: all 562 tests pass; scoped source analysis (`flutter analyze
--no-pub lib test tool pigeons`) reports no issues. Tests cover missed and
separate groups, magnets, pauses, backwards replay seeks, legacy score parity,
no drawing before completion, bounded aura size/lifetime, and pixel-identical
bird appearance across star rewards and multiplier changes. Reviewed the
rendered collection frame and generated a four-second gameplay preview at
`build/visual-review/star-aura/star-aura-preview.mp4`. On-device playtesting
of the revised effect remains pending.


### Shrinking pickup animation restored

Each collected star now moves into the bird and shrinks away over 220 ms.
The small group aura remains at the last star's location, without a second
stationary star underneath it. Charge slots and bird bursts remain removed.
Pickup timestamps and heights are reconstructed by the simulation, so pauses
and backwards replay seeks preserve the same animation. Reduced Motion fades
pickups in place. All 32 focused collection, magnet, replay, art and small-phone
UI checks pass; scoped source analysis is clean. Updated preview:
`build/visual-review/star-aura/star-pickup-preview.mp4`.

## 2026-09-30 breakable wall: new panel, per-hit feedback and shattering break

Redesigned the stone panel and its destruction. Gameplay is untouched: spawn
rules, 40 HP, damage, collision, scoring, rules version and the seeded route
are as before, and destroying the panel still clears collision on the step the
lethal blow lands. `SkyDoor` gained a read-only blow log (`hits`: time, height,
damage, ram or rock) filled inside `takeDamage`, which takes a new optional
`rammed` flag that only the sprint ram sets. Nothing in the rules reads the
log, so replays and older tapes behave identically. `crumbleDuration` grew from
0.45 s to 1.0 s and is only read by the artwork and one test.

- Artwork: `lib/game/door_art.dart` (entry, per-hit reaction), `door_slab.dart`
  (panel face), `door_parts.dart` (medallion, straps, collars, effects),
  `door_break_art.dart` (the break) and `door_fracture.dart` (a cached,
  seed-derived Voronoi fracture pattern: its seams are the cracks drawn on the
  damaged panel and the outlines of the shards that later fly). Painting is a
  pure function of the door's clock and blow log, with no wall-clock, no
  unseeded random and no painter state, so pause and backwards seeks are exact.
- Reviewed by rendering the real `BirdGame` through `GameWidget`
  (`flutter test --dart-define=CAPTURE_DOOR_ART=true test/stone_door_art_test.dart`,
  `DOOR_SET=` selects a subset), then opening the PNGs in
  `build/visual-review/breakable-walls/`: `stages-zoom.png` (five damage
  stages), `hit-sequence.png` (one non-lethal hit, 0-400 ms),
  `film-<region>.png` (12-frame filmstrips at 0-800 ms), `frames-60fps.png`
  (24 consecutive 60 fps frames), `zoom-burst.png`, `zoom-shards.png` (x4),
  `zoom-tail.png`, `zoom-sockets.png`, `zoom-panel.png`, `blows.png` (base rock
  vs full charge vs sprint ram), `regions.png`, `sizes.png` (gaps 0.28-0.52 and
  all three seeds), `reduced-motion.png`, `before-after.png`,
  `before-after-stages.png` and `destruction.mp4` (60 fps). About seven
  critique-and-fix rounds changed: the craters were missing until the ring
  sites stopped rejecting themselves, the flash was washing out the cracks
  (0.78 to 0.5 to 0.28 alpha), shards were too few and too dark, debris was too
  slow, non-lethal hits too small, the flash did not reach the straps and
  medallion (a visible pop at release), the broken sockets were mostly black,
  and the aiming mark drew through the debris (it now returns after 0.45 s).
- Regions checked for readability and the break: jungle, Antarctica, Paris
  (night), Egypt (warm sand), New York (night), Brazil, Rome and Mexico, plus
  the default Star Trail sky. The lilac-grey plug with gold and a dark outline
  stayed distinct from every wall material; debris and dust stay readable on
  the dark night backdrops through their dark outlines.
- Tests added or changed (`test/stone_door_art_test.dart`,
  `test/stone_door_test.dart`): stages differ and stay inside the opening plus
  the wall-end collars (at most 0.046 above and below, never wider than the
  wall), idle motion stays inside the same envelope, blows produce decoration
  that clears within 0.55 s, break frames differ frame to frame, repaint
  identically after seeking backwards and on a twin panel, differ between
  seeds, settle to identical pixels from 1.0 s with an empty opening, Reduced
  Motion draws nothing once destroyed, a ram throws debris further than a rock,
  the fracture is cache-independent, tiles the panel exactly and stays within
  12-30 shards; blow log values, ram flag, no logging after death, and the
  collision check on the exact lethal step.
- Per frame the break paints at most about 25 shards, 4 dust clouds (6 puffs
  each), 14 grit dots, 6-9 pebbles and a handful of gold pieces, with no
  `saveLayer`. Recording one panel took roughly 1.2-5.7 ms in the debug JIT
  test runner (busy machine, so only a rough guide); it was not measured on a
  device.
- Results: `flutter analyze --no-pub` reports no issues. The full `flutter test`
  ran 740 passing, 7 skipped and 1 failing: `world_regions_test.dart` "scenery
  regions look distinct and crossings change without pops" hit its 30 s timeout
  (it paints twelve regions of scenery and never touches the panel). The machine
  was at a load average of about 60; rerun alone with `--timeout 4x` all 12
  tests in that file pass, so it is a slow-machine timeout, not a regression
  from this change. Not verified: real
  device performance, playtesting feel and audio timing. Left out on purpose:
  camera shake (the world camera is shared), audio changes, and any wall-body
  art beyond the collars.

## 2026-09-30 Spitter King redesign: alchemist-monarch

- Replaced the brown witch hat, small tank and generic beetle body with an
  alchemist-monarch: a crown of three corked glass flasks on a brass band with
  a rose jewel, a monocled amber slit-pupil eye under a heavy gilded brow, a
  gilded cheek guard, a brass trumpet mouth, thorned wing cases with a gilded
  crest over two membrane wings, and the whole abdomen as a glass still in a
  brass cage with a pressure dial, relief valve, steaming tailpipe and a
  dripping tap. The earlier "no crown" rule is retired in the specification;
  the flask crown is the brewing-themed regalia. The mouth origin is still
  local (-1.05, 0) in every pose, and name, subtitle and every simulation
  value are untouched.
- Visual-only, deterministic and seekable. `SpitterBossMotion` gained the
  windup rattle, acid level, heat, crack, blink and glint curves. The still's
  acid level, glow, dial, valve, jowl sac, trumpet throat and crown flasks all
  rise together over the 0.65 s charge; fury turns the brew, crown, tap drips,
  shot and halo amber, turns the iris red under a scowl, blows the valve and
  glows cracks through the glass; defeat cracks the still and throws the
  crown. Reduced Motion freezes the blink, glint, steam, drips, bubbles and
  wings while charge, fury, hit and defeat stay visible. Fixed geometry, paths
  and shaders are built once; the only `saveLayer` is still the hit flash.
- Companion art: `SpitterBossRig.crownAnchor`, `crownBounds` and `crown()` replace
  the hat consumers in the encounter's defeat debris
  (`spitter-king-*-crown-fall.png` shows the flask crown tumbling out of the
  smoke); the acid shot, wake, drips and halo
  turn amber in fury like the vat; the health-bar medallion carries a
  three-flask crown instead of the generic one.
- Tests: `boss_polish_spitter_king_art_test.dart` now checks seeks, Reduced
  Motion stillness (including a blink and a glint), amber brew and red iris in
  fury, monotonically rising acid and jowl through the windup with a lit
  throat, a dark fixed spit port in every non-flash pose, the eye anchor, the
  worn and thrown crown, the detached crown's bounds, and that hits flash
  without ghosting. `spitter_boss_art_test.dart` region checks were re-aimed at
  the new anatomy; the ammo and health-bar tests gained fury-colour and crest
  checks. The pose harness writes pose sheet, phone 1x/3x, hero, close-ups,
  silhouette and five motion strips to
  `build/visual-review/boss-polish/spitter-king/` (the earlier design is kept
  in `before-redesign/`, encounter stills in `boss-polish/encounter/`).
- Review: read the pose sheet, close-ups, silhouettes against the small
  spitter, 1x/3x phone renders, a 4x pixel enlargement of the 1x render,
  charge/recoil/arrival/defeat/summon/fury/idle strips, Reduced Motion, the
  ammo and health-bar sheets, real 640x360 and 800x360 encounter frames and a
  411-frame movie contact sheet (`spitter-king/movie-contact-sheet.png`). Fixed along the way: a raised claw covering
  the face (now drawn behind the head), a glass tank that looked opaque, a
  muddy iris and an unreadable trumpet lip.
- Software rasterisation of the rig at 41 px took about 6-7 ms per frame
  against 4.5-5.4 ms for the old rig in the debug test runner (record time
  about equal, 0.3-0.6 ms); not measured on a phone. No physical-device
  testing was performed.
- Results: `flutter analyze --no-pub` on the working tree reports 8 errors,
  all non-exhaustive `BossKind.dragon` switches in `boss_ammo_art.dart`,
  `boss_encounter_art.dart`, `boss_health_bar_art.dart` and two polish tests,
  from the uncommitted dragon domain work; the Spitter files are clean. With
  the dragon enum case stubbed out in a scratch copy, the full suite ran 803
  passing, 11 skipped and 3 failing: the three failures are boss-cycle
  expectations in `dusk_moth_boss_test.dart`, a domain-only test that imports
  none of the art.
