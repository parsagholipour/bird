import 'game_rules.dart';

export 'campaign_ids.dart';

// l10n-english-twin: the campaign's words below (route names, postcards,
// level names, cargo, senders, hints) are the English twins of the ARB keys
// `chapter_*` and `level_*` that the screens show through CampaignText
// (lib/l10n/text/campaign_text.dart); the thank-you notes and boss lines are
// the English captions of their voice clips (StoryCaptions). Keep them
// word-for-word equal to the ARB (test/l10n_campaign_test.dart).

/// One of the five mail routes, in boss order. Its levels fly its regions
/// in turn, and the last level is the boss's lair.
class CampaignChapter {
  const CampaignChapter({
    required this.number,
    required this.route,
    required this.boss,
    required this.regions,
    required this.bossLine,
    required this.postcard,
    required this.postscript,
    required this.levels,
    this.playable = true,
    this.opened = const {},
  });
  final int number;

  /// The route's name, such as "The Canopy Route".
  final String route;
  final BossKind boss;

  /// The chapter's stops on the map, in flight order.
  final List<WorldRegion> regions;

  /// The boss's one line on its entrance name card, without quotes.
  final String bossLine;

  /// The postcard after the chapter's boss falls: its message, and the
  /// postscript that hints at the next route.
  final String postcard, postscript;
  final List<CampaignLevel> levels;

  /// Chapters 3–5 sit on the map, locked, as "Coming soon".
  final bool playable;

  /// The stops of a chapter that is not [playable] whose levels can be
  /// flown while the build opens them ([Campaign.openingEnabled], on by
  /// default): New York opens ahead of Paris and the Dusk Empress. Ask [Campaign.playable]
  /// about a level rather than reading this.
  final Set<WorldRegion> opened;

  /// The chapter's boss level: its last, the lair of [boss]. Only this level
  /// ends the chapter: it unlocks the next chapter, earns the flame seal and
  /// brings the postcard. A guardian earlier in the chapter
  /// ([CampaignLevel.isGuardian]) does none of these.
  CampaignLevel get bossLevel => levels.last;
}

/// What a level's flight carries, and the thank-you that comes back once it
/// lands. A boss level carries the letter that tells its boss to go.
class Delivery {
  const Delivery(this.cargo, {required this.from, required this.thanks});

  /// The parcel and who it is for, such as "A birthday card for the toucan
  /// twins", on the level's card.
  final String cargo;

  /// Who signs the thank-you on the level's result, and what it says.
  final String from, thanks;
}

/// A level of the campaign: its name and intro card, and the [plan] the
/// rules fly.
class CampaignLevel {
  const CampaignLevel({
    required this.name,
    required this.delivery,
    required this.plan,
    this.hint,
    this.hintIsNew = true,
    this.bossLine,
  });
  final String name;
  final Delivery delivery;

  /// The line on a guardian's entrance name card, without quotes, when this
  /// level's boss is not its chapter's (see [Campaign.bossLine]).
  final String? bossLine;

  /// The one-line hint on the intro card; the card marks it NEW when
  /// [hintIsNew].
  final String? hint;
  final bool hintIsNew;
  final LevelPlan plan;

  /// "1-1" to "5-8".
  String get id => plan.id;
  int get chapter => int.parse(id.split('-').first);
  int get number => int.parse(id.split('-').last);
  WorldRegion get region => plan.region;
  StarMarks get marks => plan.marks;
  BossKind? get boss => plan.boss;

  /// Whether the level ends in any boss: a chapter's boss or a guardian.
  bool get isBoss => plan.boss != null;

  /// Whether this is its chapter's boss level: the lair that ends the
  /// chapter ([CampaignChapter.bossLevel]).
  bool get isChapterBoss =>
      isBoss && id == Campaign.chapterOf(this).bossLevel.id;

  /// Whether the level ends in a campaign-only mini-boss before its chapter's
  /// boss: King Coo on 3-2, the Searchlight Gargoyle on 3-4. A guardian
  /// unlocks the next level only: no chapter unlock, flame seal or postcard.
  bool get isGuardian => isBoss && !isChapterBoss;

  /// The rules' word for [isGuardian].
  bool get isMiniBoss => isGuardian;

  /// Cruising seconds to the finish line, or the run-up before the boss.
  double get length => plan.length;

  /// The endless-clock second its difficulty starts from.
  double get start => plan.start;
}

/// The campaign: one trip around the world, one region at a time. See
/// docs/campaign.md.
abstract final class Campaign {
  static final List<CampaignLevel> levels = [
    for (final chapter in chapters) ...chapter.levels,
  ];

  /// Every region once, in the order the courier flies them.
  static final List<WorldRegion> journey = [
    for (final chapter in chapters) ...chapter.regions,
  ];

  static CampaignLevel? level(String id) {
    for (final level in levels) {
      if (level.id == id) return level;
    }
    return null;
  }

  static CampaignChapter chapterOf(CampaignLevel level) =>
      chapters[level.chapter - 1];

  /// Whether the build opens the stops that chapters list in
  /// [CampaignChapter.opened]: New York (3-1 to 3-4) is OPEN by default, so a
  /// plain `flutter run`, `make build` and `make install` all ship it. This
  /// is the one place the decision is made. Roll it back with
  /// `--dart-define=NEW_YORK_OPEN=false` (`make build DEFINES=--dart-define=
  /// NEW_YORK_OPEN=false`): the map shows New York "Coming soon" again, the
  /// star total is 48, and saves, schema and recorded flights are untouched
  /// (a New York tape still opens in a build that knows rules 43). Paris
  /// deletes the flag later.
  static const bool openingEnabled = bool.fromEnvironment(
    'NEW_YORK_OPEN',
    defaultValue: true,
  );

  static bool _openedForTest = false, _closedForTest = false;

  /// TEST ONLY: forces the stops in [CampaignChapter.opened] open for the
  /// rest of a test whatever the build says; `false` hands the decision back
  /// to the build. A test that sets it must reset it in a tearDown.
  static set openedForTest(bool open) => _openedForTest = open;

  /// TEST ONLY: forces them closed, the state of a build made with
  /// `NEW_YORK_OPEN=false` (it wins over [openedForTest]); `false` hands the
  /// decision back to the build. A test that sets it must reset it in a
  /// tearDown, so no other test meets a closed New York.
  static set closedForTest(bool closed) => _closedForTest = closed;

  /// Whether the opened stops can be flown right now: the build's choice,
  /// or a test's override.
  static bool get stopsOpen =>
      !_closedForTest && (openingEnabled || _openedForTest);

  /// Whether [level] can be flown in this build: any level of a playable
  /// chapter, and the levels of an opened stop of a chapter that is not.
  /// The one place that knows; every screen and the progress rules ask it.
  static bool playable(CampaignLevel level) {
    final chapter = chapterOf(level);
    return chapter.playable ||
        (stopsOpen && chapter.opened.contains(level.region));
  }

  /// The levels that can be flown in this build, in order.
  static List<CampaignLevel> get playableLevels => [
    for (final level in levels)
      if (playable(level)) level,
  ];

  /// Whether the map's stop for [region] has nothing to fly yet: it keeps
  /// its "Coming soon" ribbon.
  static bool comingSoon(WorldRegion region) =>
      !levels.any((level) => level.region == region && playable(level));

  /// The line on [level]'s boss's entrance name card, without quotes: a
  /// guardian's own, else its chapter's boss line on the chapter's boss
  /// level, else null (a level without a boss).
  static String? bossLine(CampaignLevel level) =>
      level.bossLine ??
      (level.isChapterBoss ? chapterOf(level).bossLine : null);

  /// The level after [level], across chapters, or null after the last.
  static CampaignLevel? after(CampaignLevel level) {
    final i = levels.indexOf(level);
    return i < 0 || i + 1 >= levels.length ? null : levels[i + 1];
  }

  static CampaignLevel? before(CampaignLevel level) {
    final i = levels.indexOf(level);
    return i <= 0 ? null : levels[i - 1];
  }

  static const _jungle = WorldRegion.jungle, _brazil = WorldRegion.brazil;
  static const _aztec = WorldRegion.aztec, _rome = WorldRegion.rome;
  static const _egypt = WorldRegion.egypt, _arabia = WorldRegion.arabia;
  static const _newYork = WorldRegion.newYork, _paris = WorldRegion.paris;
  static const _mexico = WorldRegion.mexico, _sea = WorldRegion.sea;
  static const _antarctica = WorldRegion.antarctica;
  static const _cyberpunk = WorldRegion.cyberpunk, _china = WorldRegion.china;

  static const _garden = ObstacleKind.garden, _lift = ObstacleKind.windLift;
  static const _petal = ObstacleKind.petalGate;
  static const _switchback = ObstacleKind.switchback;
  static const _lantern = ObstacleKind.lanternDrift;
  static const _wheels = ObstacleKind.sunWheels;
  static const _canopy = [_garden, _lift, _petal];
  static const _road = [..._canopy, _switchback, _lantern];
  static const _every = ObstacleKind.values;

  static const _bat = EnemyKind.simpleBat, _caveBat = EnemyKind.caveBat;
  static const _beetle = EnemyKind.spitterBeetle, _moth = EnemyKind.duskMoth;
  static const _pigeon = EnemyKind.alleyPigeon;
  static const _bats = [_bat, _caveBat];

  /// Bats and beetles; the intro level shows a beetle every fourth passage.
  static const _beetleIntro = [_bat, _beetle, _caveBat, _beetle];
  static const _beetles = [_bat, _beetle, _caveBat];

  /// Moth Light's lineup: a moth leads the second enemy passage and every
  /// fourth enemy after it, between bats, a cave bat and a beetle. (Moths used
  /// to be half the enemies, which made 3-1 the hardest ordinary level for a
  /// casual player; see docs/validation.md, "New York fix round".)
  static const _mothIntro = [_bat, _moth, _caveBat, _beetle];

  /// New York's pigeon lesson: four enemy passages in seven lead with an
  /// Alley Pigeon (3-2's run-up, with flocks of one).
  static const _pigeonIntro = [_pigeon, _bat, _pigeon, _moth];

  /// The alley's mix (3-3 and 3-4): a pigeon on passages 3, 9, 15 ... .
  static const _alley = [_bat, _pigeon, _moth, _beetle, _pigeon, _caveBat];

  /// The endless lineup.
  static const _all = [_bat, _beetle, _moth, _caveBat];

  static const _wildfire = SetPieceKind.wildfire;
  static const _skyfall = SetPieceKind.skyfall;
  static const _eruption = SetPieceKind.eruption;
  static const _swarm = SetPieceKind.swarm;
  static const _shuffled = SetPieceKind.shuffled;
  static const _gale = SetPieceKind.gale;

  static const chapters = [
    CampaignChapter(
      number: 1,
      route: 'The Canopy Route',
      boss: BossKind.baronBat,
      regions: [_jungle, _brazil, _aztec],
      bossLine: 'This route is my roost now, little courier!',
      postcard:
          'Dear courier, letters are landing in the treetops again! The '
          "toucans say thank you (very loudly). Baron Bat's crown is on our "
          'mantelpiece.',
      postscript: 'P.S. The ancient road smells like something is bubbling.',
      levels: [
        CampaignLevel(
          name: 'First Delivery',
          delivery: Delivery(
            'A birthday card for the toucan twins',
            from: 'The toucan twins',
            thanks: 'Best birthday ever! We squawked for an hour.',
          ),
          hint: 'Tap to flap. Fly through the stars.',
          // A short first flight (30 s, was 60), with Shoot from the start.
          plan: LevelPlan(
            id: '1-1',
            region: _jungle,
            length: 30,
            start: 0,
            seed: 1101,
            families: [_garden],
            sprint: false,
            marks: StarMarks(15, 25),
          ),
        ),
        CampaignLevel(
          name: 'Star Streak',
          delivery: Delivery(
            'Star charts for the sloth stargazer',
            from: 'The sloth stargazer',
            thanks: 'No rush, I said. You rushed. Thank you.',
          ),
          hint: 'Chain stars for 3×; three perfect gates earn a magnet.',
          // 45 s (was 60), with the first small bats on every fourth
          // passage; cave bats join in 1-3.
          plan: LevelPlan(
            id: '1-2',
            region: _jungle,
            length: 45,
            start: 0,
            seed: 1102,
            families: [_garden, _lift],
            lineup: [_bat],
            cadence: 4,
            sprint: false,
            marks: StarMarks(25, 45),
          ),
        ),
        CampaignLevel(
          name: 'Bat Patrol',
          delivery: Delivery(
            'Night-lights for the firefly nursery',
            from: 'The firefly nursery',
            thanks: 'Now even the shy ones are glowing.',
          ),
          hint: 'Shoot. Tap Shoot to knock out bats.',
          plan: LevelPlan(
            id: '1-3',
            region: _jungle,
            length: 65,
            start: 10,
            seed: 1103,
            families: [_garden, _lift],
            lineup: _bats,
            cadence: 4,
            sprint: false,
            marks: StarMarks(40, 65),
          ),
        ),
        CampaignLevel(
          name: 'Carnival Skies',
          delivery: Delivery(
            'Feather boas for the carnival parade',
            from: 'The samba macaws',
            thanks: 'The parade starts now. You made it!',
          ),
          // Brazil's gale blows footballs, not junk (the art follows the
          // region). At 80 s it flies about as long as it did at 70 s
          // without the tailwind.
          hint: 'Gale! Watch the ! and dodge the footballs.',
          plan: LevelPlan(
            id: '1-4',
            region: _brazil,
            length: 80,
            start: 20,
            seed: 1104,
            families: _canopy,
            lineup: _bats,
            sprint: false,
            pieces: [SetPiece(_gale, at: 30)],
            marks: StarMarks(30, 50),
          ),
        ),
        CampaignLevel(
          name: 'Express Post',
          delivery: Delivery(
            'A rush invitation for the drum captain',
            from: 'The drum captain',
            thanks: 'So fast my hat blew off. Marvellous!',
          ),
          hint: 'Sprint smashes bats and surges ahead.',
          plan: LevelPlan(
            id: '1-5',
            region: _brazil,
            length: 70,
            start: 30,
            seed: 1105,
            families: _canopy,
            lineup: _bats,
            marks: StarMarks(45, 70),
          ),
        ),
        CampaignLevel(
          name: 'Temple Steps',
          delivery: Delivery(
            'Cocoa beans for the temple cooks',
            from: 'The temple cooks',
            thanks: 'Hot chocolate for the whole temple!',
          ),
          plan: LevelPlan(
            id: '1-6',
            region: _aztec,
            length: 75,
            start: 40,
            seed: 1106,
            families: _canopy,
            lineup: _bats,
            marks: StarMarks(45, 80),
          ),
        ),
        CampaignLevel(
          name: 'Sunrise Roost',
          delivery: Delivery(
            'A sundial for the dawn keeper',
            from: 'The dawn keeper',
            thanks: 'Sunrise is back on schedule.',
          ),
          plan: LevelPlan(
            id: '1-7',
            region: _aztec,
            length: 80,
            start: 50,
            seed: 1107,
            families: _canopy,
            lineup: _bats,
            marks: StarMarks(50, 85),
          ),
        ),
        CampaignLevel(
          name: 'Baron Bat',
          delivery: Delivery(
            'A final notice for Baron Bat',
            from: 'Baron Bat',
            thanks: 'Fine. FINE. Take your noisy route.',
          ),
          plan: LevelPlan(
            id: '1-8',
            region: _aztec,
            length: 30,
            start: 40,
            seed: 1108,
            families: _canopy,
            lineup: _bats,
            boss: BossKind.baronBat,
            marks: StarMarks(15, 25),
          ),
        ),
      ],
    ),
    CampaignChapter(
      number: 2,
      route: 'The Ancient Road',
      boss: BossKind.spitterBeetle,
      regions: [_rome, _egypt, _arabia],
      bossLine: 'Every letter on my road goes in the brew!',
      postcard:
          'Dear courier, the caravans are rolling and the only thing brewing '
          "is mint tea. We kept the King's flask crown as a vase.",
      postscript: 'P.S. The city lamps went dark last night. Bring a light.',
      levels: [
        CampaignLevel(
          name: 'Beetle Road',
          delivery: Delivery(
            'Laurel wreaths for the chariot racers',
            from: 'The chariot racers',
            thanks: 'We shall wear them at every race!',
          ),
          hint: 'Beetles spit seeds. Shoot the seeds down.',
          plan: LevelPlan(
            id: '2-1',
            region: _rome,
            length: 65,
            start: 40,
            seed: 2101,
            families: _canopy,
            lineup: _beetleIntro,
            toughness: 1,
            marks: StarMarks(45, 70),
          ),
        ),
        CampaignLevel(
          name: 'Sealed Gates',
          delivery: Delivery(
            'A new chisel for the statue carver',
            from: 'The statue carver',
            thanks: 'At last I can finish his nose.',
          ),
          hint: 'Hold Shoot for a big rock that breaks stone.',
          plan: LevelPlan(
            id: '2-2',
            region: _rome,
            length: 70,
            start: 50,
            seed: 2102,
            families: _canopy,
            lineup: _beetles,
            toughness: 1,
            panels: .35,
            marks: StarMarks(50, 75),
          ),
        ),
        CampaignLevel(
          name: 'Wildfire Run',
          delivery: Delivery(
            'Water buckets for the fire brigade',
            from: 'The fire brigade',
            thanks: 'Just in time. Truly, JUST in time.',
          ),
          hint: 'Fly through the gold rings to outrun the fire!',
          plan: LevelPlan(
            id: '2-3',
            region: _rome,
            length: 75,
            start: 45,
            seed: 2103,
            families: _canopy,
            lineup: _beetles,
            toughness: 1,
            panels: .25,
            pieces: [SetPiece(_wildfire, at: 25)],
            marks: StarMarks(45, 75),
          ),
        ),
        CampaignLevel(
          name: 'Nile Switchbacks',
          delivery: Delivery(
            'A book of new riddles for the Sphinx',
            from: 'The Sphinx',
            thanks: 'Finally, some fresh material.',
          ),
          plan: LevelPlan(
            id: '2-4',
            region: _egypt,
            length: 75,
            start: 60,
            seed: 2104,
            families: [..._canopy, _switchback],
            lineup: _beetles,
            toughness: 1,
            panels: .25,
            marks: StarMarks(55, 85),
          ),
        ),
        CampaignLevel(
          name: 'Skyfall',
          delivery: Delivery(
            'A telescope for the pyramid astronomer',
            from: 'The pyramid astronomer',
            thanks: 'Now I can see the meteors coming!',
          ),
          hint: 'Ring sprints smash meteors.',
          plan: LevelPlan(
            id: '2-5',
            region: _egypt,
            length: 80,
            start: 65,
            seed: 2105,
            families: [..._canopy, _switchback],
            lineup: _beetles,
            toughness: 1,
            panels: .25,
            pieces: [SetPiece(_skyfall, at: 30)],
            marks: StarMarks(50, 80),
          ),
        ),
        // Egypt's guardian (rules version 50): a 30 s run-up under the
        // level before it, then Neferhoo, the Mummy Courier. A boss level
        // holds no set pieces; the marks count the run-up's 36 route stars
        // (50% and 80%; every pilot collects all 36: neferhoo_marks_test).
        // Seed 2116 lays a single stone door, on the fifth passage.
        // Ancient Arabia's levels moved up by one to make room (see
        // [CampaignIds]): their plans keep their seeds.
        CampaignLevel(
          name: 'Return to Sender',
          // The design's "A feather duster for the pyramid caretaker" (42
          // characters) runs over a guardian's tag at 640 to 1000 px wide;
          // the tag keeps the feather duster every voiced line names (the
          // note is signed by the pyramid caretaker).
          delivery: Delivery(
            'A feather duster for the caretaker',
            from: 'The pyramid caretaker',
            thanks: 'Four thousand years of dust, gone by lunch!',
          ),
          hint: 'Shoot his letters to send them back. Return to sender!',
          bossLine: 'Return to sender! This route has a courier.',
          plan: LevelPlan(
            id: '2-6',
            region: _egypt,
            length: 30,
            start: 60,
            seed: 2116,
            families: [..._canopy, _switchback],
            lineup: _beetles,
            toughness: 1,
            panels: .25,
            boss: BossKind.neferhoo,
            marks: StarMarks(20, 30),
          ),
        ),
        CampaignLevel(
          name: 'Lantern Bazaar',
          delivery: Delivery(
            'Lamp oil for the lantern sellers',
            from: 'The lantern sellers',
            thanks: 'The bazaar glows again. A thousand thanks!',
          ),
          plan: LevelPlan(
            id: '2-7',
            region: _arabia,
            length: 80,
            start: 75,
            seed: 2106,
            families: _road,
            lineup: _beetles,
            toughness: 1,
            panels: .25,
            marks: StarMarks(55, 90),
          ),
        ),
        CampaignLevel(
          name: 'The Long Caravan',
          delivery: Delivery(
            'Water flasks for the long caravan',
            from: 'The caravan leader',
            thanks: 'Forty camels. Forty thank-yous.',
          ),
          plan: LevelPlan(
            id: '2-8',
            region: _arabia,
            length: 90,
            start: 90,
            seed: 2107,
            families: _road,
            lineup: _beetles,
            toughness: 1,
            panels: .25,
            pieces: [SetPiece(_wildfire, at: 25), SetPiece(_skyfall, at: 60)],
            marks: StarMarks(55, 90),
          ),
        ),
        CampaignLevel(
          name: 'Spitter King',
          delivery: Delivery(
            'A stop-brewing order for the Spitter King',
            from: 'Spitter King',
            thanks: 'Bah. It was very nearly ink.',
          ),
          plan: LevelPlan(
            id: '2-9',
            region: _arabia,
            length: 30,
            start: 75,
            seed: 2108,
            families: _road,
            lineup: _beetles,
            toughness: 1,
            panels: .25,
            boss: BossKind.spitterBeetle,
            marks: StarMarks(20, 30),
          ),
        ),
      ],
    ),
    CampaignChapter(
      number: 3,
      route: 'The Lamplight Line',
      boss: BossKind.duskMoth,
      regions: [_newYork, _paris],
      bossLine: 'Hush now. The night mail is sleeping.',
      postcard:
          'Dear courier, the lamps are lit and the night mail is wide awake! '
          'Paris sends a croissant. New York sends a pretzel.',
      postscript: 'P.S. The harbour bells have stopped ringing.',
      playable: false,
      // New York opens ahead of Paris (see [Campaign.openingEnabled]).
      opened: {_newYork},
      levels: [
        CampaignLevel(
          name: 'Moth Light',
          delivery: Delivery(
            'Light bulbs for the theatre marquee',
            from: 'The stage manager',
            thanks: 'The show goes on! Front row for you.',
          ),
          hint: 'Moths fire fans of three. Slip between them.',
          plan: LevelPlan(
            id: '3-1',
            region: _newYork,
            length: 60,
            start: 75,
            seed: 3101,
            families: _road,
            lineup: _mothIntro,
            toughness: 2,
            panels: .25,
            marks: StarMarks(40, 65),
          ),
        ),
        // New York's first guardian: a 30 s run-up that introduces the Alley
        // Pigeon (flocks of one), then King Coo. A boss level holds no set
        // pieces and no steam; the marks count the run-up's 36 route stars.
        CampaignLevel(
          name: 'Wheels in the Rain',
          delivery: Delivery(
            'Umbrellas for the newsstand pigeons',
            from: 'The newsstand pigeons',
            thanks: 'Dry feathers at last. You’re a hero.',
          ),
          hint: 'Alley pigeons swoop in to grab stars. Shoot them first!',
          bossLine: 'Nobody flies till the bread cart is found!',
          plan: LevelPlan(
            id: '3-2',
            region: _newYork,
            length: 30,
            start: 85,
            seed: 3102,
            families: [_garden, _lift, _petal, _wheels],
            lineup: _pigeonIntro,
            flocks: [1, 1, 1],
            toughness: 2,
            panels: .25,
            boss: BossKind.kingCoo,
            marks: StarMarks(20, 30),
          ),
        ),
        // The steam's level: seven vents (the steady layer, hop and ride
        // alternating from the fourth passage, cut short by the 65 s route),
        // between gates that pigeons (one, then pairs) and the alley's
        // enemies lead. Renamed from Swarm Alley; the Swarm rush moved to
        // Paris. 65 s and seed 3111 (no stone door in the first ten passages)
        // since the fix round: at 80 s a casual player had no heart recovery
        // to last it (steam was only 6% of the hearts lost).
        CampaignLevel(
          name: 'Steam Alley',
          delivery: Delivery(
            'Hot pretzels for the night-shift cabbies',
            from: 'The night cabbies',
            thanks: 'Still warm! How fast do you fly?',
          ),
          hint: 'Vents hiss, then burst. Hop the hot ones, ride the soft ones.',
          plan: LevelPlan(
            id: '3-3',
            region: _newYork,
            length: 65,
            start: 100,
            seed: 3111,
            families: [_garden, _lift, _petal, _wheels],
            lineup: _alley,
            flocks: [1, 2, 2, 2, 2, 2],
            steam: SteamPlan.steady,
            toughness: 2,
            panels: .25,
            marks: StarMarks(45, 70),
          ),
        ),
        // New York's second guardian: a run-up with a light steam layer
        // (two rides and a hop) and pigeons, then the Searchlight Gargoyle.
        // No Sprint here: a sprint makes his feathers close faster than the
        // lane they were aimed for (the fairness proof assumes none). The
        // gale moved to Paris.
        CampaignLevel(
          name: 'Storm Warning',
          delivery: Delivery(
            'A weather vane for the tallest tower',
            from: 'The tower keeper',
            thanks: 'It spins! It points! It’s perfect.',
          ),
          hint:
              'Stay out of the light. Shoot the lamp when it opens! '
              'No Sprint here.',
          bossLine: 'Hold still! Nobody ever stays in the light.',
          plan: LevelPlan(
            id: '3-4',
            region: _newYork,
            length: 30,
            start: 90,
            seed: 3104,
            families: [_garden, _lift, _switchback, _wheels],
            lineup: _alley,
            flocks: [1, 2],
            steam: SteamPlan.sparse,
            toughness: 2,
            panels: .25,
            sprint: false,
            boss: BossKind.searchlightGargoyle,
            // ★★★ at 27 of the run-up's 36 stars (75%, not the usual 30): its
            // three vents' stars sit on arcs above the plumes and its pigeons
            // take up to three, which cost a casual player two stars more
            // than 3-2's run-up (★★★ for a casual pilot: 38 to 65% at 30, 85
            // to 100% at 27, as 3-2 is at 30). The thief cap becomes
            // (36 - 27) / 2 = 4, above the three pigeons it lays.
            marks: StarMarks(20, 27),
          ),
        ),
        CampaignLevel(
          name: 'Crystal Rooftops',
          delivery: Delivery(
            'Croissants for the rooftop painters',
            from: 'The rooftop painters',
            thanks: 'Magnifique. Not one crumb lost.',
          ),
          plan: LevelPlan(
            id: '3-5',
            region: _paris,
            length: 80,
            start: 110,
            seed: 3105,
            families: _every,
            lineup: _all,
            toughness: 2,
            panels: .25,
            marks: StarMarks(55, 90),
          ),
        ),
        CampaignLevel(
          name: 'After the Gale',
          delivery: Delivery(
            'Sheet music for the accordion player',
            from: 'The accordion player',
            thanks: 'The pages blew in right on the beat.',
          ),
          // The Gale moved here from New York's 3-4: Paris introduces it.
          hint: 'Gale! Watch the ! and take the open side.',
          plan: LevelPlan(
            id: '3-6',
            region: _paris,
            length: 85,
            start: 120,
            seed: 3106,
            families: _every,
            lineup: _all,
            toughness: 2,
            panels: .25,
            pieces: [
              SetPiece(_gale, at: 20),
              SetPiece(_wildfire, at: 8, after: true),
            ],
            marks: StarMarks(35, 55),
          ),
        ),
        CampaignLevel(
          name: 'Midnight Express',
          delivery: Delivery(
            'A midnight love letter for the baker',
            from: 'The baker',
            thanks: 'I said yes! I mean… thank you.',
          ),
          // The Swarm rush moved here from New York's 3-3: Paris introduces
          // it (the gale is a reprise).
          hint: 'Sprint through the flocks.',
          plan: LevelPlan(
            id: '3-7',
            region: _paris,
            length: 90,
            start: 135,
            seed: 3107,
            families: _every,
            lineup: _all,
            toughness: 2,
            panels: .25,
            pieces: [SetPiece(_swarm, at: 20), SetPiece(_gale, at: 55)],
            marks: StarMarks(40, 60),
          ),
        ),
        CampaignLevel(
          name: 'Dusk Empress',
          delivery: Delivery(
            'A wake-up call for the Dusk Empress',
            from: 'Dusk Empress',
            thanks: 'Very well. Let them have their lamps.',
          ),
          plan: LevelPlan(
            id: '3-8',
            region: _paris,
            length: 30,
            start: 120,
            seed: 3108,
            families: _every,
            lineup: _all,
            toughness: 2,
            panels: .25,
            boss: BossKind.duskMoth,
            marks: StarMarks(20, 30),
          ),
        ),
      ],
    ),
    CampaignChapter(
      number: 4,
      route: 'The Tide Route',
      boss: BossKind.pirate,
      regions: [_mexico, _sea],
      bossLine: 'Arr! Every mailbag on these waves be mine!',
      postcard:
          'Dear courier, the harbour bells ring for letters again, not '
          'cannons. The parrot stayed. He says hello.',
      postscript: 'P.S. They say the sky at the edge of the map is on fire.',
      playable: false,
      levels: [
        CampaignLevel(
          name: 'Harbour Lights',
          delivery: Delivery(
            'A new lens for the lighthouse keeper',
            from: 'The lighthouse keeper',
            thanks: 'Now the ships can find us again.',
          ),
          plan: LevelPlan(
            id: '4-1',
            region: _mexico,
            length: 75,
            start: 135,
            seed: 4101,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            pieces: [SetPiece(_skyfall, at: 25)],
            marks: StarMarks(50, 80),
          ),
        ),
        CampaignLevel(
          name: 'Volcano Pass',
          delivery: Delivery(
            'Oven mitts for the volcano baker',
            from: 'The volcano baker',
            thanks: 'My lava cakes thank you.',
          ),
          hint: 'Hop over the lava plumes.',
          plan: LevelPlan(
            id: '4-2',
            region: _mexico,
            length: 80,
            start: 150,
            seed: 4102,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            pieces: [SetPiece(_eruption, at: 25)],
            marks: StarMarks(55, 85),
          ),
        ),
        CampaignLevel(
          name: 'Down the Coast',
          delivery: Delivery(
            'Kite string for the beach festival',
            from: 'The kite flyers',
            thanks: 'Best wind we’ve had all year!',
          ),
          plan: LevelPlan(
            id: '4-3',
            region: _mexico,
            length: 80,
            start: 150,
            seed: 4103,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            pieces: [SetPiece(_gale, at: 30)],
            marks: StarMarks(35, 55),
          ),
        ),
        CampaignLevel(
          name: 'Low Water',
          delivery: Delivery(
            'A reply for the island hermit',
            from: 'The island hermit',
            thanks: 'Forty years I waited for a reply!',
          ),
          hint: "Don't touch the water.",
          plan: LevelPlan(
            id: '4-4',
            region: _sea,
            length: 75,
            start: 135,
            seed: 4104,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            marks: StarMarks(55, 85),
          ),
        ),
        CampaignLevel(
          name: 'Spring Tide',
          delivery: Delivery(
            'A tide table for the ferry crew',
            from: 'The ferry crew',
            thanks: 'High water at noon. Good to know!',
          ),
          hint: 'When the bell rings, fly high.',
          plan: LevelPlan(
            id: '4-5',
            region: _sea,
            length: 80,
            start: 150,
            seed: 4105,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            marks: StarMarks(55, 90),
          ),
        ),
        CampaignLevel(
          name: 'Broadside Bay',
          delivery: Delivery(
            'Fish biscuits for the gull colony',
            from: 'The gull colony',
            thanks: 'Dinner for nine hundred. Thanks!',
          ),
          plan: LevelPlan(
            id: '4-6',
            region: _sea,
            length: 85,
            start: 165,
            seed: 4106,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            pieces: [SetPiece(_swarm, at: 30)],
            marks: StarMarks(55, 90),
          ),
        ),
        CampaignLevel(
          name: 'Stormy Crossing',
          delivery: Delivery(
            'Dry socks for the storm-watch sailors',
            from: 'The storm watch',
            thanks: 'Warm toes at last. Bless the post.',
          ),
          plan: LevelPlan(
            id: '4-7',
            region: _sea,
            length: 90,
            start: 180,
            seed: 4107,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            pieces: [
              SetPiece(_gale, at: 20),
              SetPiece(_eruption, at: 8, after: true),
            ],
            marks: StarMarks(40, 60),
          ),
        ),
        CampaignLevel(
          name: 'Pirate Captain',
          delivery: Delivery(
            'A return-the-mail order for the Captain',
            from: 'Pirate Captain',
            thanks: 'Arr. Ye fly well, for a postie.',
          ),
          plan: LevelPlan(
            id: '4-8',
            region: _sea,
            length: 30,
            start: 165,
            seed: 4108,
            families: _every,
            lineup: _all,
            toughness: 3,
            panels: .25,
            boss: BossKind.pirate,
            marks: StarMarks(20, 30),
          ),
        ),
      ],
    ),
    CampaignChapter(
      number: 5,
      route: 'The Edge of the Map',
      boss: BossKind.dragon,
      regions: [_antarctica, _cyberpunk, _china],
      bossLine: 'The sky is mine. Your letters are kindling.',
      postcard:
          'Dear courier, the sky is clear from pole to pole and every route '
          'is running. The whole Sky Club is proud of you.',
      postscript: 'P.S. The endless sky is still out there, whenever you are.',
      playable: false,
      levels: [
        CampaignLevel(
          name: 'Aurora Post',
          delivery: Delivery(
            'Woolly hats for the penguin choir',
            from: 'The penguin choir',
            thanks: 'Warm heads, high notes. Thank you!',
          ),
          hint: 'Any rush can come now. Read the banner!',
          hintIsNew: false,
          plan: LevelPlan(
            id: '5-1',
            region: _antarctica,
            length: 80,
            start: 180,
            seed: 5101,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            pieces: [SetPiece(_shuffled, at: 30)],
            marks: StarMarks(55, 85),
          ),
        ),
        CampaignLevel(
          name: 'Polar Night',
          delivery: Delivery(
            'Hot cocoa for the polar station',
            from: 'The polar station',
            thanks: 'First warm drink since winter began.',
          ),
          plan: LevelPlan(
            id: '5-2',
            region: _antarctica,
            length: 85,
            start: 195,
            seed: 5102,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            pieces: [
              SetPiece(_gale, at: 20),
              SetPiece(_shuffled, at: Gale.rushAfter, after: true),
            ],
            marks: StarMarks(35, 60),
          ),
        ),
        CampaignLevel(
          name: 'Neon Express',
          delivery: Delivery(
            'Spare fuses for the noodle bar sign',
            from: 'The noodle chef',
            thanks: 'OPEN again. Noodles on the house!',
          ),
          plan: LevelPlan(
            id: '5-3',
            region: _cyberpunk,
            length: 80,
            start: 210,
            seed: 5103,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            pieces: [SetPiece(_shuffled, at: 20), SetPiece(_shuffled, at: 50)],
            marks: StarMarks(50, 80),
          ),
        ),
        CampaignLevel(
          name: 'Data Storm',
          delivery: Delivery(
            'A paper letter for a curious robot',
            from: 'Unit 7',
            thanks: 'PAPER. MARVELLOUS. I SHALL FRAME IT.',
          ),
          plan: LevelPlan(
            id: '5-4',
            region: _cyberpunk,
            length: 85,
            start: 225,
            seed: 5104,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            pieces: [
              SetPiece(_gale, at: 25),
              SetPiece(_shuffled, at: Gale.rushAfter, after: true),
            ],
            marks: StarMarks(35, 60),
          ),
        ),
        CampaignLevel(
          name: 'Skyline Sprint',
          delivery: Delivery(
            'Race tickets for the rooftop runners',
            from: 'The rooftop runners',
            thanks: 'You beat our lap record delivering them.',
          ),
          plan: LevelPlan(
            id: '5-5',
            region: _cyberpunk,
            length: 90,
            start: 240,
            seed: 5105,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            pieces: [
              SetPiece(_shuffled, at: 15),
              SetPiece(_gale, at: 45),
              SetPiece(_shuffled, at: Gale.rushAfter, after: true),
            ],
            marks: StarMarks(40, 60),
          ),
        ),
        CampaignLevel(
          name: 'Lantern Festival',
          delivery: Delivery(
            'Paper lanterns for the festival',
            from: 'The lantern makers',
            thanks: 'A thousand lights, thanks to you.',
          ),
          plan: LevelPlan(
            id: '5-6',
            region: _china,
            length: 85,
            start: 240,
            seed: 5106,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            pieces: [SetPiece(_shuffled, at: 20), SetPiece(_shuffled, at: 55)],
            marks: StarMarks(55, 90),
          ),
        ),
        CampaignLevel(
          name: 'The Last Leg',
          delivery: Delivery(
            'Mountain tea for the monastery',
            from: 'The mountain monks',
            thanks: 'Sit. Rest. The last climb is steep.',
          ),
          plan: LevelPlan(
            id: '5-7',
            region: _china,
            length: 90,
            start: 270,
            seed: 5107,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            pieces: [
              SetPiece(_gale, at: 15),
              SetPiece(_shuffled, at: Gale.rushAfter, after: true),
              SetPiece(_shuffled, at: 65),
            ],
            marks: StarMarks(40, 60),
          ),
        ),
        CampaignLevel(
          name: 'Ember Dragon',
          delivery: Delivery(
            'The first letter ever sent to the Dragon',
            from: 'Ember Dragon',
            thanks: 'I have read it nine times already.',
          ),
          plan: LevelPlan(
            id: '5-8',
            region: _china,
            length: 30,
            start: 240,
            seed: 5108,
            families: _every,
            lineup: _all,
            toughness: 4,
            panels: .25,
            boss: BossKind.dragon,
            marks: StarMarks(20, 30),
          ),
        ),
      ],
    ),
  ];
}
