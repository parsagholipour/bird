# Validation ledger

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
  draw order in one place beside it. Baron Bat's
  rig has no worried brow, so his sad face is heavy-lidded with a sweat bead.

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
