import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/built_level.dart';
import '../domain/campaign.dart';
import '../domain/campaign_progress.dart';
import '../domain/campaign_story.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import '../domain/daily_adventure.dart';
import '../l10n/app_language.dart';
import 'built_level_repository.dart';
import 'cloud_logbook.dart';

part 'progress_repository.g.dart';

class Runs extends Table {
  TextColumn get id => text()();
  IntColumn get mode => integer()();
  TextColumn get course => text().withDefault(const Constant('classic'))();
  IntColumn get gates => integer().withDefault(const Constant(0))();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  IntColumn get bestCombo => integer().withDefault(const Constant(0))();
  IntColumn get perfectPasses => integer().withDefault(const Constant(0))();
  BoolColumn get practice => boolean()();
  // Drift's generator resolves this column reference in the SQL CHECK clause.
  // ignore: recursive_getters
  IntColumn get score => integer().check(score.isBiggerOrEqualValue(0))();
  IntColumn get repetitions => integer()();
  IntColumn get flaps => integer()();
  RealColumn get duration => real()();
  TextColumn get reason => text()();
  DateTimeColumn get finishedAt => dateTime()();
  IntColumn get bird => integer().withDefault(const Constant(0))();

  /// The campaign level flown, such as "1-3". Null for endless flights and
  /// every flight saved before the campaign; only those make records.
  TextColumn get level => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

/// A campaign level's bests (a [LevelRecord]). Stored rather than derived
/// from [Runs]: each flight is rated as it is saved, so retuning a level's
/// marks later never takes stars away.
@DataClassName('LevelProgressRow')
class LevelProgress extends Table {
  TextColumn get level => text()();
  IntColumn get bestStars => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters
      .check(bestStars.isBetweenValues(0, 3))();
  IntColumn get bestCollected => integer().withDefault(const Constant(0))();
  IntColumn get bestScore => integer().withDefault(const Constant(0))();
  IntColumn get plays => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstClearedAt => dateTime().nullable()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  BoolColumn get postcardSeen => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {level};
}

/// The levels players built by hand ([BuiltLevel]), in the canonical JSON
/// of their [BuiltPlan]. Starter templates are not stored: they are code.
@DataClassName('BuiltLevelRow')
class BuiltLevels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get mode => integer()();
  TextColumn get json => text()();
  TextColumn get fingerprint => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();

  /// 'created', 'remixed' or 'imported' ([BuiltOrigin]).
  TextColumn get origin => text().withDefault(const Constant('created'))();

  /// The template a remix was made from.
  TextColumn get remixOf => text().nullable()();
  IntColumn get clearedRevision => integer().nullable()();
  BoolColumn get importedCleared =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Every scored flight of a built level (a player's or a template), rated
/// as it is saved. Kept apart from [Runs]: built flights count towards no
/// record, wallet, daily adventure or passport, only their own level's
/// bests and the lifetime workout totals. A deleted level keeps its
/// flights, so the workouts done in it still count.
@DataClassName('BuiltFlightRow')
class BuiltFlights extends Table {
  TextColumn get id => text()();
  TextColumn get level => text()();
  IntColumn get revision => integer()();
  IntColumn get mode => integer()();
  IntColumn get rating => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters
      .check(rating.isBetweenValues(0, 3))();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  IntColumn get score => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get flaps => integer().withDefault(const Constant(0))();
  RealColumn get duration => real()();
  TextColumn get reason => text()();
  DateTimeColumn get finishedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Runs, Preferences, LevelProgress, BuiltLevels, BuiltFlights],
)
class ProgressDatabase extends _$ProgressDatabase {
  ProgressDatabase(super.executor);
  factory ProgressDatabase.onDevice() => ProgressDatabase(
    LazyDatabase(() async {
      final folder = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(folder.path, 'sky_club.sqlite')),
      );
    }),
  );
  @override
  int get schemaVersion => 7;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.addColumn(runs, runs.course);
        await m.addColumn(runs, runs.gates);
        await m.addColumn(runs, runs.stars);
        await m.addColumn(runs, runs.bestCombo);
        await m.addColumn(runs, runs.perfectPasses);
        await customStatement('UPDATE runs SET gates = score');
      }
      if (from < 4) {
        // Every bird is free now; earlier flights were flown with whichever
        // bird was equipped, which was not recorded, so they count as Pip's.
        await m.addColumn(runs, runs.bird);
        await customStatement('DROP TABLE IF EXISTS bird_unlocks');
      }
      if (from < 5) {
        // The campaign. Every earlier flight was an endless one.
        await m.addColumn(runs, runs.level);
        await m.createTable(levelProgress);
      }
      if (from < 6) {
        // Egypt's guardian took level 2-6: Ancient Arabia moved up by one.
        await renumberLevels();
      }
      if (from < 7) {
        // The level builder.
        await m.createTable(builtLevels);
        await m.createTable(builtFlights);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

extension LevelRenumbering on ProgressDatabase {
  /// The preference that says the save uses [CampaignIds.scheme]'s ids.
  static const schemeKey = 'levelIds';

  /// Renames a save made before Egypt's guardian took level 2-6 (schema 5)
  /// to the ids it has now ([CampaignIds]): the level records and the
  /// flights (`runs.level`), highest id first so no new id exists before its
  /// old owner has left it; the watched story scenes named by those levels;
  /// and the flight voices' memory of the cargo lines said. One transaction,
  /// so a save is renamed whole or not at all. It runs once, as the database
  /// is opened by the first build at schema 6 and before anything is read or
  /// saved, and it marks the save ([schemeKey]), so running it again changes
  /// nothing.
  Future<void> renumberLevels() => transaction(() async {
    final marked = await (select(
      preferences,
    )..where((p) => p.key.equals(schemeKey))).getSingleOrNull();
    if (marked != null) return;
    for (final MapEntry(key: from, value: to)
        in CampaignIds.renumbered.entries) {
      await customUpdate(
        'UPDATE level_progress SET level = ? WHERE level = ?',
        variables: [Variable.withString(to), Variable.withString(from)],
        updates: {levelProgress},
      );
      await customUpdate(
        'UPDATE runs SET level = ? WHERE level = ?',
        variables: [Variable.withString(to), Variable.withString(from)],
        updates: {runs},
      );
    }
    Future<String?> pref(String key) async => (await (select(
      preferences,
    )..where((p) => p.key.equals(key))).getSingleOrNull())?.value;
    Future<void> put(String key, String value) =>
        into(preferences).insertOnConflictUpdate(
          PreferencesCompanion.insert(key: key, value: value),
        );
    final watched = await pref('storyWatched');
    if (watched != null) {
      await put(
        'storyWatched',
        [
          for (final id in watched.split(','))
            if (id.isNotEmpty) CampaignIds.scene(id),
        ].join(','),
      );
    }
    final voices = await pref('flightVoices');
    if (voices != null) {
      try {
        final json = jsonDecode(voices) as Map<String, dynamic>;
        for (final key in ['last', 'lastFlight']) {
          final map = json[key];
          if (map is Map) {
            json[key] = {
              for (final MapEntry(:key, :value) in map.entries)
                CampaignIds.clip(key as String): value,
            };
          }
        }
        await put('flightVoices', jsonEncode(json));
      } on FormatException {
        // An unreadable memory starts afresh anyway (FlightVoiceMemory).
      } on TypeError {
        // Likewise.
      }
    }
    await put(schemeKey, '${CampaignIds.scheme}');
  });
}

// l10n-english-twin: birdNames and birdDescriptions are the twins of the
// bird_N_name and bird_N_description keys; screens show SharedText.birdName
// and BirdsText.birdDescription (lib/l10n/text/).
const birdNames = ['Pip', 'Peaches', 'Minty', 'Orbit'];

/// Minty is the first main character: the bird a new player flies with and
/// the first one the pickers show. The indices above stay as they are, since
/// saved choices, runs and voice clips are keyed by them.
const firstBird = 2;

/// The order the bird pickers show the cast in, [firstBird] first.
const birdOrder = [firstBird, 0, 1, 3];

/// Scored flights (campaign levels, endless and the camera mini games) a
/// player flies before the Level Builder opens, so they know what a level
/// is made of before they make one.
const builderUnlockFlights = 5;

/// Stars each bird costs to unlock, by index: Pip 500 and Orbit 1000;
/// Peaches and Minty fly free from the start.
const birdPrices = [500, 0, 0, 1000];

const birdDescriptions = [
  'Small bird. Big sky.',
  'Rosy cheeks, curly crest, all heart.',
  'Tiny hummer. Fresh sprig. Full speed.',
  'A dreamy owl who flies by starlight.',
];

enum SettingKey {
  music,
  effects,
  voices,
  reducedMotion,
  recordAudio,

  /// Flight school has been flown or skipped (docs/tutorial.md).
  tutorialDone,
}

class GameSettings {
  const GameSettings({
    this.music = true,
    this.effects = true,
    this.reducedMotion = false,
    this.recordAudio = false,
    this.voices = true,
    this.bird = firstBird,
    this.language,
    this.tutorialDone = false,
  });
  final bool music, effects, reducedMotion, recordAudio;

  /// Whether flight school, the first-time lesson, has been flown to its
  /// end or skipped. Until then a new player's first launch opens the
  /// language screen and the lesson (`firstLaunchRoute`). A device
  /// setting, like the others.
  final bool tutorialDone;

  /// The language chosen in Settings, or null to follow the device
  /// (lib/l10n/language_providers.dart). A device setting: it never syncs,
  /// and a reset of this phone or another keeps it.
  final AppLanguage? language;

  /// The characters' recorded voices: the story's lines, the thank-you
  /// notes and what the bird and the bosses say in flight.
  final bool voices;
  final int bird;
}

class ModeRecord {
  const ModeRecord({
    this.best = 0,
    this.runs = 0,
    this.obstacles = 0,
    this.repetitions = 0,
    this.stars = 0,
    this.perfectPasses = 0,
    this.bestCombo = 0,
    this.completions = 0,
  });
  final int best, runs, obstacles, repetitions;
  final int stars, perfectPasses, bestCombo, completions;

  /// Two phones' records together: their counts add up and their bests
  /// stay bests.
  ModeRecord plus(ModeRecord o) => ModeRecord(
    best: math.max(best, o.best),
    runs: runs + o.runs,
    obstacles: obstacles + o.obstacles,
    repetitions: repetitions + o.repetitions,
    stars: stars + o.stars,
    perfectPasses: perfectPasses + o.perfectPasses,
    bestCombo: math.max(bestCombo, o.bestCombo),
    completions: completions + o.completions,
  );

  /// The field-wise max of two copies of one phone's record.
  ModeRecord max(ModeRecord o) => ModeRecord(
    best: math.max(best, o.best),
    runs: math.max(runs, o.runs),
    obstacles: math.max(obstacles, o.obstacles),
    repetitions: math.max(repetitions, o.repetitions),
    stars: math.max(stars, o.stars),
    perfectPasses: math.max(perfectPasses, o.perfectPasses),
    bestCombo: math.max(bestCombo, o.bestCombo),
    completions: math.max(completions, o.completions),
  );
}

/// One co-op mode's team best and how many flights it has had. A duel has
/// no team, so it only counts its flights.
class CoopRecord {
  const CoopRecord({this.best = 0, this.flights = 0});
  final int best, flights;
}

/// Co-op flights: two players on one phone, their birds roped together or
/// not ([CoopMode]). Each mode keeps its own record, apart from the solo
/// records, the passport and the daily adventures.
class CoopProgress {
  const CoopProgress({
    this.records = const {},
    this.birds = (firstBird, 0),
    this.mode = CoopMode.roped,
  });
  final Map<CoopMode, CoopRecord> records;
  CoopRecord record(CoopMode mode) => records[mode] ?? const CoopRecord();

  /// Co-op flights in every mode, duels included.
  int get flights => records.values.fold(0, (n, r) => n + r.flights);

  /// Duels fought.
  int get duels => record(CoopMode.duel).flights;

  /// The birds players 1 and 2 chose last, and the mode.
  final (int, int) birds;
  final CoopMode mode;
}

class ProgressSnapshot {
  const ProgressSnapshot({
    this.settings = const GameSettings(),
    this.pushUp = const ModeRecord(),
    this.jump = const ModeRecord(),
    this.touch = const ModeRecord(),
    this.squat = const ModeRecord(),
    this.trailPushUp = const ModeRecord(),
    this.trailJump = const ModeRecord(),
    this.trailTouch = const ModeRecord(),
    this.trailSquat = const ModeRecord(),
    this.campaignFlights = const ModeRecord(),
    this.birdsFlown = const {},
    this.birdFlights = const {},
    this.unlockedBirds = const {1, 2},
    this.recent = const [],
    this.adventures = const [],
    this.coop = const CoopProgress(),
    this.upgrades = const PowerUps(),
    this.starsSpent = 0,
    this.builtWorkouts = const {},
    this.feats = const {},
    this.builtCleared = false,
    this._campaign,
  });
  final GameSettings settings;

  /// Things a flight did that only Play Games achievements read, such as
  /// `boss:dragon`, `day:2026-10-06`, `night` and `pigeonFreed`.
  final Set<String> feats;

  /// Whether a level built here (not remixed or imported) has been flown
  /// to the finish by its creator.
  final bool builtCleared;

  /// Repetitions (push-ups, squats) and jumps done on built levels, by
  /// mode. They count towards the lifetime workout totals, and to nothing
  /// else: a built level's stars and scores stay in the builder.
  final Map<PlayMode, int> builtWorkouts;

  /// The upgrade levels bought with stars, flown on every new flight.
  final PowerUps upgrades;

  /// Stars spent on [upgrades] so far.
  final int starsSpent;

  /// Every star collected on a scored flight, endless and campaign alike.
  int get starsEarned => totalStars + campaignFlights.stars;

  /// Stars left to spend on upgrades.
  int get starWallet => (starsEarned - starsSpent).clamp(0, starsEarned);

  /// Whether [p]'s next level is for sale and the wallet can pay for it.
  bool canBuy(PowerUp p) {
    final cost = PowerUp.costFrom(upgrades[p]);
    return cost != null && starWallet >= cost;
  }

  /// Co-op flights, kept apart from everything below.
  final CoopProgress coop;

  /// Endless records: campaign levels never count here, nor in anything
  /// summed from them below.
  final ModeRecord pushUp,
      jump,
      touch,
      squat,
      trailPushUp,
      trailJump,
      trailTouch,
      trailSquat;

  /// Scored campaign flights, kept apart from the records so a level never
  /// shows up as a best. Its [ModeRecord.completions] are finished levels.
  final ModeRecord campaignFlights;

  /// Level stars, unlocks, postcards and watched story scenes on the
  /// campaign map.
  CampaignProgress get campaign => _campaign ?? _noCampaign;
  final CampaignProgress? _campaign;
  static final _noCampaign = CampaignProgress(const []);

  /// Birds taken on at least one scored flight, campaign levels included.
  final Set<int> birdsFlown;

  /// Scored flights per bird, campaign levels included. Birds never flown
  /// are missing.
  final Map<int, int> birdFlights;

  /// Birds the player may fly: the free ones and the ones bought with
  /// stars.
  final Set<int> unlockedBirds;
  bool birdUnlocked(int bird) => unlockedBirds.contains(bird);

  /// Whether [bird] is still locked and the wallet can pay for it.
  bool canUnlock(int bird) =>
      !birdUnlocked(bird) && starWallet >= birdPrices[bird];

  /// The latest endless flights.
  final List<RunResult> recent;

  /// Oldest first, ending with today. Derived from saved flights, not counters.
  final List<DailyAdventure> adventures;
  DailyAdventure? get today => adventures.isEmpty ? null : adventures.last;
  int get totalObstacles => allRecords.fold(0, (n, r) => n + r.obstacles);
  int get totalRuns => allRecords.fold(0, (n, r) => n + r.runs);

  /// Every scored flight, campaign levels included.
  int get flightsFlown => totalRuns + campaignFlights.runs;

  /// Flights still to fly before the Level Builder opens; 0 once it has.
  int get flightsToBuilder => math.max(0, builderUnlockFlights - flightsFlown);
  int get totalRepetitions =>
      pushUp.repetitions +
      trailPushUp.repetitions +
      (builtWorkouts[PlayMode.pushUp] ?? 0);
  int get totalSquats =>
      squat.repetitions +
      trailSquat.repetitions +
      (builtWorkouts[PlayMode.squat] ?? 0);
  List<ModeRecord> get allRecords => [
    pushUp,
    jump,
    touch,
    squat,
    trailPushUp,
    trailJump,
    trailTouch,
    trailSquat,
  ];
  int get totalStars => allRecords.fold(0, (n, r) => n + r.stars);
  int get totalPerfects => allRecords.fold(0, (n, r) => n + r.perfectPasses);
  int get longestCombo =>
      allRecords.fold(0, (n, r) => n > r.bestCombo ? n : r.bestCombo);
  int get trailCompletions =>
      trailPushUp.completions +
      trailJump.completions +
      trailTouch.completions +
      trailSquat.completions;
  ModeRecord record(
    PlayMode mode, [
    FlightCourse course = FlightCourse.classic,
  ]) => course == FlightCourse.starTrail
      ? switch (mode) {
          PlayMode.pushUp => trailPushUp,
          PlayMode.jump => trailJump,
          PlayMode.touch => trailTouch,
          PlayMode.squat => trailSquat,
        }
      : switch (mode) {
          PlayMode.pushUp => pushUp,
          PlayMode.jump => jump,
          PlayMode.touch => touch,
          PlayMode.squat => squat,
        };
}

abstract interface class ProgressRepository {
  Future<ProgressSnapshot> load();

  /// The levels players build, kept in the same save.
  BuiltLevelStore get builtLevels;

  /// Saves a scored flight once per id. A campaign flight (with a
  /// [RunResult.levelId]) also folds into its level's record.
  Future<void> saveRun(RunResult result);

  /// Remembers that [chapter]'s postcard was shown, so it arrives once.
  Future<void> markPostcardSeen(CampaignChapter chapter);

  /// Remembers that [scene] was watched, so it plays by itself once.
  Future<void> markStoryWatched(StoryScene scene);

  /// The in-flight voice-over's memory of what was said
  /// (FlightVoiceMemory.encode), or null before the first flight.
  Future<String?> loadFlightVoices();
  Future<void> saveFlightVoices(String memory);
  Future<void> setSetting(SettingKey key, bool value);

  /// Saves the language chosen in Settings; null follows the device.
  Future<void> setLanguage(AppLanguage? language);
  Future<void> equipBird(int bird);

  /// Saves a co-op flight in [mode] once per id: its mode's best and flight
  /// count. It never touches the solo records.
  Future<void> saveCoop(CoopMode mode, RunResult result);

  /// Remembers the birds players 1 and 2 chose for co-op, and the mode.
  Future<void> chooseCoop(int first, int second, CoopMode mode);

  /// Buys [p]'s next level with collected stars. Throws a [StateError] when
  /// it is already at the top or the wallet cannot pay for it.
  Future<void> buyUpgrade(PowerUp p);

  /// Unlocks [bird] for its [birdPrices] stars. Throws a [StateError] when
  /// it is already unlocked or the wallet cannot pay for it.
  Future<void> unlockBird(int bird);

  /// Clears this phone's progress. With [cloud] (a reset on a phone that
  /// has synced, see [cloudSynced]) the cloud logbook goes too: the epoch
  /// rises, so the next sync replaces it instead of merging the old
  /// progress back, and every other phone that synced starts afresh.
  Future<void> reset({bool cloud = false});

  /// Whether this phone has ever synced with the Play Games cloud, in this
  /// session or an earlier one; with [player], whether its last sync was
  /// with that Play player's cloud. A reset keeps it.
  Future<bool> cloudSynced({String? player});

  /// The Play Games logbook of this phone's progress
  /// (lib/data/cloud_logbook.dart).
  Future<Logbook> exportLogbook();

  /// Merges [player]'s cloud logbook into this phone's progress in one
  /// transaction and returns the merged logbook to save back, and whether
  /// anything here changed. A cloud reset on another phone (a higher epoch)
  /// first clears this phone's progress when it last synced with the same
  /// player. Another player's cloud is met as on a phone that never synced:
  /// this phone takes its epoch, and the two merge.
  Future<(Logbook, bool)> importLogbook(Logbook? cloud, {String player = ''});

  /// What the Play Games sync remembers on this phone only (achievements
  /// reported, when the cloud was last saved), or null.
  Future<String?> loadPlayGamesMemory();
  Future<void> savePlayGamesMemory(String memory);
  Future<void> close();
}

class SqliteProgressRepository implements ProgressRepository {
  SqliteProgressRepository(this.db, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final ProgressDatabase db;
  final DateTime Function() clock;
  @override
  late final BuiltLevelStore builtLevels = SqliteBuiltLevelStore(
    db,
    clock: clock,
  );
  @override
  Future<ProgressSnapshot> load() => db.transaction(() async {
    final prefs = {
      for (final row in await db.select(db.preferences).get())
        row.key: row.value,
    };
    // Other phones' totals, restored from Play Games, count with this
    // phone's own flights.
    final carried = DeviceTotals.decodeAll(prefs[_carriedKey]).values;
    final birdFlights = <int, int>{...await _birdFlights()};
    for (final row in carried) {
      for (final MapEntry(key: bird, value: n) in row.birdFlights.entries) {
        if (n > 0) birdFlights[bird] = (birdFlights[bird] ?? 0) + n;
      }
    }
    final birdsFlown = birdFlights.keys.toSet();
    Future<ModeRecord> record(String key) async => carried.fold<ModeRecord>(
      await _localRecord(key),
      (r, row) => r.plus(row.record(key)),
    );
    final workouts = {...await builtLevels.workouts()};
    for (final row in carried) {
      for (final MapEntry(:key, :value) in row.builtWorkouts.entries) {
        if (PlayMode.values.asNameMap()[key] case final mode?) {
          workouts[mode] = (workouts[mode] ?? 0) + value;
        }
      }
    }
    CoopRecord coop(CoopMode mode) => carried.fold(
      CoopRecord(
        best: int.tryParse(prefs[_coopKey('Best', mode)] ?? '') ?? 0,
        flights: int.tryParse(prefs[_coopKey('Flights', mode)] ?? '') ?? 0,
      ),
      (r, row) => switch (row.coop[mode.name]) {
        null => r,
        final o => CoopRecord(
          best: math.max(r.best, o.best),
          flights: r.flights + o.flights,
        ),
      },
    );

    final selected = int.tryParse(prefs['bird'] ?? '$firstBird') ?? firstBird;
    final now = clock().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(now.year, now.month, now.day - 6);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final weekRows =
        await (db.select(db.runs)..where(
              (r) =>
                  r.practice.equals(false) &
                  r.finishedAt.isBiggerOrEqualValue(firstDay) &
                  r.finishedAt.isSmallerThanValue(tomorrow),
            ))
            .get();
    final weekRuns = weekRows.map(_runResult).toList();
    final rows =
        await (db.select(db.runs)
              ..where((r) => r.practice.equals(false) & r.level.isNull())
              ..orderBy([(r) => OrderingTerm.desc(r.finishedAt)])
              ..limit(10))
            .get();
    final levels = await db.select(db.levelProgress).get();
    final unlocked = _unlockedBirds(prefs);
    return ProgressSnapshot(
      settings: GameSettings(
        music: prefs['music'] != 'false',
        effects: prefs['effects'] != 'false',
        reducedMotion: prefs['reducedMotion'] == 'true',
        recordAudio: prefs['recordAudio'] == 'true',
        voices: prefs['voices'] != 'false',
        language: AppLanguage.fromTag(prefs[_languageKey]),
        tutorialDone: prefs[SettingKey.tutorialDone.name] == 'true',
        // A locked bird left equipped (from before birds cost stars) gives
        // way to Minty until it is bought.
        bird: unlocked.contains(selected) ? selected : firstBird,
      ),
      pushUp: await record('pushUp'),
      jump: await record('jump'),
      touch: await record('touch'),
      squat: await record('squat'),
      trailPushUp: await record('trailPushUp'),
      trailJump: await record('trailJump'),
      trailTouch: await record('trailTouch'),
      trailSquat: await record('trailSquat'),
      campaignFlights: await record('campaign'),
      campaign: CampaignProgress(
        levels.map(_levelRecord),
        storyWatched: _storyWatched(prefs[_storyKey]),
      ),
      birdsFlown: birdsFlown,
      birdFlights: birdFlights,
      unlockedBirds: unlocked,
      recent: rows.map(_runResult).toList(),
      coop: CoopProgress(
        records: {for (final mode in CoopMode.values) mode: coop(mode)},
        birds: _coopBirds(prefs[_coopBirdsKey], selected, unlocked),
        mode:
            CoopMode.values.asNameMap()[prefs[_coopModeKey]] ?? CoopMode.roped,
      ),
      upgrades: _upgrades(prefs),
      starsSpent: _starsSpent(prefs),
      builtWorkouts: workouts,
      feats: _names(prefs[_featsKey]),
      builtCleared: await _builtCleared(),
      adventures: [
        for (var i = 6; i >= 0; i--)
          DailyAdventure.forDate(
            DateTime(today.year, today.month, today.day - i),
            weekRuns,
          ),
      ],
    );
  });

  /// This phone's own record under a [DeviceTotals.recordKeys] key,
  /// summed from its scored flights. Campaign levels are never endless
  /// records.
  Future<ModeRecord> _localRecord(String key) async {
    final (where, variables) = switch (_records[key]) {
      (final mode, final course) => (
        'level IS NULL AND mode = ? AND course = ?',
        [Variable.withInt(mode.index), Variable.withString(course.name)],
      ),
      null => ('level IS NOT NULL', const <Variable>[]),
    };
    final r = await db
        .customSelect(
          'SELECT COALESCE(MAX(score),0) AS best, COUNT(*) AS runs, '
          'COALESCE(SUM(gates),0) AS obstacles, COALESCE(SUM(repetitions),0) AS repetitions '
          ', COALESCE(SUM(stars),0) AS stars, COALESCE(SUM(perfect_passes),0) AS perfects '
          ', COALESCE(MAX(best_combo),0) AS combo, '
          'COALESCE(SUM(reason = \'completed\' OR (level IS NULL AND course = \'starTrail\' AND duration >= 60)),0) AS completions '
          'FROM runs WHERE practice = 0 AND $where',
          variables: variables,
        )
        .getSingle();
    return ModeRecord(
      best: r.read<int>('best'),
      runs: r.read<int>('runs'),
      obstacles: r.read<int>('obstacles'),
      repetitions: r.read<int>('repetitions'),
      stars: r.read<int>('stars'),
      perfectPasses: r.read<int>('perfects'),
      bestCombo: r.read<int>('combo'),
      completions: r.read<int>('completions'),
    );
  }

  /// The endless record each [DeviceTotals.recordKeys] key names; the
  /// campaign's is missing.
  static const _records = {
    'pushUp': (PlayMode.pushUp, FlightCourse.classic),
    'jump': (PlayMode.jump, FlightCourse.classic),
    'touch': (PlayMode.touch, FlightCourse.classic),
    'squat': (PlayMode.squat, FlightCourse.classic),
    'trailPushUp': (PlayMode.pushUp, FlightCourse.starTrail),
    'trailJump': (PlayMode.jump, FlightCourse.starTrail),
    'trailTouch': (PlayMode.touch, FlightCourse.starTrail),
    'trailSquat': (PlayMode.squat, FlightCourse.starTrail),
  };

  Future<bool> _builtCleared() async =>
      (await db
              .customSelect(
                'SELECT EXISTS(SELECT 1 FROM built_levels WHERE origin = \'created\' '
                'AND cleared_revision IS NOT NULL) AS cleared',
                readsFrom: {db.builtLevels},
              )
              .getSingle())
          .read<bool>('cleared');

  RunResult _runResult(Run r) => RunResult(
    id: r.id,
    mode: PlayMode.values[r.mode],
    course: FlightCourse.named(r.course),
    gates: r.gates,
    stars: r.stars,
    bestCombo: r.bestCombo,
    perfectPasses: r.perfectPasses,
    practice: r.practice,
    score: r.score,
    repetitions: r.repetitions,
    flaps: r.flaps,
    durationSeconds: r.duration,
    reason: EndReason.values.firstWhere(
      (v) => v.name == r.reason,
      orElse: () => EndReason.quit,
    ),
    finishedAt: r.finishedAt,
    bird: r.bird,
    levelId: r.level,
  );

  LevelRecord _levelRecord(LevelProgressRow r) => LevelRecord(
    levelId: r.level,
    bestStars: r.bestStars,
    bestCollected: r.bestCollected,
    bestScore: r.bestScore,
    plays: r.plays,
    firstClearedAt: r.firstClearedAt,
    lastPlayedAt: r.lastPlayedAt,
    postcardSeen: r.postcardSeen,
  );

  @override
  Future<void> saveRun(RunResult result) async {
    if (result.score < 0 ||
        result.gates < 0 ||
        result.stars < 0 ||
        result.bestCombo < 0 ||
        result.perfectPasses < 0 ||
        result.repetitions < 0 ||
        result.flaps < 0 ||
        !result.durationSeconds.isFinite ||
        result.durationSeconds < 0 ||
        result.bird < 0 ||
        result.bird >= birdNames.length) {
      throw ArgumentError('Invalid run statistics');
    }
    final levelId = result.levelId;
    final level = levelId == null ? null : Campaign.level(levelId);
    if (levelId != null &&
        (level == null ||
            result.practice ||
            result.mode != PlayMode.touch ||
            result.course != FlightCourse.starTrail)) {
      throw ArgumentError.value(levelId, 'levelId', 'Not a campaign flight');
    }
    await db.transaction(() async {
      // A retried save must not count the flight, or its level play, twice.
      final saved = await (db.select(
        db.runs,
      )..where((r) => r.id.equals(result.id))).getSingleOrNull();
      if (saved != null) return;
      await db
          .into(db.runs)
          .insert(
            RunsCompanion.insert(
              id: result.id,
              mode: result.mode.index,
              course: Value(result.course.name),
              gates: Value(result.gates),
              stars: Value(result.stars),
              bestCombo: Value(result.bestCombo),
              perfectPasses: Value(result.perfectPasses),
              practice: result.practice,
              score: result.score,
              repetitions: result.mode.controlsHeight ? result.repetitions : 0,
              flaps: !result.mode.controlsHeight ? result.flaps : 0,
              duration: result.durationSeconds,
              reason: result.reason.name,
              finishedAt: result.finishedAt,
              bird: Value(result.bird),
              level: Value(levelId),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      if (level != null) await _mergeLevel(level, result);
      if (!result.practice) await _rememberFeats(result);
    });
  }

  /// Notes what a newly saved scored flight did for the Play Games
  /// achievements: its own [RunResult.feats], a finish between midnight
  /// and 4 a.m., and the day's adventure card once this flight stamps it.
  Future<void> _rememberFeats(RunResult result) async {
    final at = result.finishedAt.toLocal();
    final day = DateTime(at.year, at.month, at.day);
    final rows =
        await (db.select(db.runs)..where(
              (r) =>
                  r.practice.equals(false) &
                  r.finishedAt.isBiggerOrEqualValue(day) &
                  r.finishedAt.isSmallerThanValue(
                    DateTime(day.year, day.month, day.day + 1),
                  ),
            ))
            .get();
    final card = DailyAdventure.forDate(day, rows.map(_runResult));
    await _addFeats({
      ...result.feats,
      if (at.hour < 4) 'night',
      if (card.complete) 'day:${card.dayKey}',
    });
  }

  Future<void> _addFeats(Set<String> feats) async {
    if (feats.isEmpty) return;
    final row = await (db.select(
      db.preferences,
    )..where((p) => p.key.equals(_featsKey))).getSingleOrNull();
    final saved = _names(row?.value);
    if (saved.containsAll(feats)) return;
    await _remember(
      _featsKey,
      ({...saved, ...feats}.toList()..sort()).join(','),
    );
  }

  /// Folds a campaign flight into its level's bests. It is rated against
  /// the level's marks exactly as the flight rated itself
  /// ([FlightSimulation.levelStars]): only a finished level earns stars.
  Future<void> _mergeLevel(CampaignLevel level, RunResult result) async {
    final row = await (db.select(
      db.levelProgress,
    )..where((p) => p.level.equals(level.id))).getSingleOrNull();
    final record =
        (row == null ? LevelRecord(levelId: level.id) : _levelRecord(row))
            .merge(
              stars: level.plan.rate(
                finished: result.reason == EndReason.completed,
                stars: result.stars,
              ),
              collected: result.stars,
              score: result.score,
              at: result.finishedAt,
            );
    await db
        .into(db.levelProgress)
        .insertOnConflictUpdate(
          LevelProgressCompanion.insert(
            level: record.levelId,
            bestStars: Value(record.bestStars),
            bestCollected: Value(record.bestCollected),
            bestScore: Value(record.bestScore),
            plays: Value(record.plays),
            firstClearedAt: Value(record.firstClearedAt),
            lastPlayedAt: Value(record.lastPlayedAt),
            postcardSeen: Value(record.postcardSeen),
          ),
        );
  }

  @override
  Future<void> markPostcardSeen(CampaignChapter chapter) async {
    // Only a beaten boss's level has a record; before that nothing is due.
    await (db.update(db.levelProgress)
          ..where((p) => p.level.equals(chapter.bossLevel.id)))
        .write(const LevelProgressCompanion(postcardSeen: Value(true)));
  }

  /// The preference that lists the watched story scenes by id.
  static const _storyKey = 'storyWatched';

  static Set<String> _storyWatched(String? saved) => _names(saved);

  /// A comma-separated set of names, as the story and feats preferences
  /// keep them.
  static Set<String> _names(String? saved) => {
    for (final id in (saved ?? '').split(','))
      if (id.isNotEmpty) id,
  };

  /// Play Games: the feats; other phones' totals rows (`carried`); this
  /// phone's random id in the cloud logbook; the logbook's epoch; what
  /// the achievements sync remembers (never synced); and the Play player
  /// this phone last synced with (`cloudSynced`), whose cloud the epoch
  /// belongs to.
  static const _featsKey = 'feats', _carriedKey = 'carried';
  static const _deviceKey = 'deviceId', _epochKey = 'epoch';
  static const _playGamesKey = 'playGames', _syncedKey = 'cloudSynced';

  @override
  Future<void> markStoryWatched(StoryScene scene) => db.transaction(() async {
    final row = await (db.select(
      db.preferences,
    )..where((p) => p.key.equals(_storyKey))).getSingleOrNull();
    final watched = _storyWatched(row?.value);
    if (!watched.add(scene.id)) return;
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(key: _storyKey, value: watched.join(',')),
        );
  });

  static const _flightVoicesKey = 'flightVoices';

  @override
  Future<String?> loadFlightVoices() async => (await (db.select(
    db.preferences,
  )..where((p) => p.key.equals(_flightVoicesKey))).getSingleOrNull())?.value;

  @override
  Future<void> saveFlightVoices(String memory) async {
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(key: _flightVoicesKey, value: memory),
        );
  }

  @override
  Future<void> setSetting(SettingKey key, bool value) async {
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(key: key.name, value: value.toString()),
        );
  }

  static const _languageKey = 'language';

  @override
  Future<void> setLanguage(AppLanguage? language) async {
    if (language == null) {
      await (db.delete(
        db.preferences,
      )..where((p) => p.key.equals(_languageKey))).go();
      return;
    }
    await _remember(_languageKey, language.tag);
  }

  @override
  Future<void> equipBird(int bird) async {
    if (bird < 0 || bird >= birdNames.length) {
      throw ArgumentError.value(bird, 'bird');
    }
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(key: 'bird', value: '$bird'),
        );
  }

  static const _coopBirdsKey = 'coopBirds', _coopModeKey = 'coopMode';

  /// Each co-op mode's own preference, such as `coopBest.free`.
  static String _coopKey(String name, CoopMode mode) =>
      'coop$name.${mode.name}';

  /// The saved co-op birds, or the equipped bird and the next one.
  /// The saved co-op birds, or the equipped bird and the next unlocked one
  /// the pickers show. Locked birds never fly co-op.
  static (int, int) _coopBirds(String? saved, int equipped, Set<int> unlocked) {
    bool valid(int? bird) =>
        bird != null &&
        bird >= 0 &&
        bird < birdNames.length &&
        unlocked.contains(bird);
    final first = valid(equipped) ? equipped : firstBird;
    final fallback = (
      first,
      birdOrder.firstWhere((b) => b != first && valid(b)),
    );
    final parts = saved?.split(',').map(int.tryParse).toList();
    if (parts == null || parts.length != 2) return fallback;
    final [a, b] = parts;
    return valid(a) && valid(b) ? (a!, b!) : fallback;
  }

  Future<Map<int, int>> _birdFlights() async => {
    for (final row
        in await db
            .customSelect(
              'SELECT bird, COUNT(*) AS n FROM runs WHERE practice = 0 '
              'GROUP BY bird',
            )
            .get())
      row.read<int>('bird'): row.read<int>('n'),
  };

  /// The preference listing the unlocked birds, such as `1,2,3`.
  static const _birdUnlocksKey = 'birdUnlocks';

  /// The unlocked birds: the free ones and every one bought with stars.
  /// Flying or equipping a bird never unlocks it, so a save from before
  /// birds cost stars buys Pip and Orbit like everyone else.
  static Set<int> _unlockedBirds(Map<String, String> prefs) => {
    for (var b = 0; b < birdNames.length; b++)
      if (birdPrices[b] == 0) b,
    for (final part in (prefs[_birdUnlocksKey] ?? '').split(','))
      if (int.tryParse(part) case final b? when b >= 0 && b < birdNames.length)
        b,
  };

  @override
  Future<void> unlockBird(int bird) => db.transaction(() async {
    if (bird < 0 || bird >= birdNames.length) {
      throw ArgumentError.value(bird, 'bird');
    }
    final prefs = {
      for (final row in await db.select(db.preferences).get())
        row.key: row.value,
    };
    final unlocked = _unlockedBirds(prefs);
    if (unlocked.contains(bird)) {
      throw StateError('${birdNames[bird]} is already unlocked');
    }
    final price = birdPrices[bird];
    final spent = _starsSpent(prefs);
    if (await _starsEarned(prefs) - spent < price) {
      throw StateError('Not enough stars for ${birdNames[bird]}');
    }
    await _remember(
      _birdUnlocksKey,
      ({...unlocked, bird}.toList()..sort()).join(','),
    );
    await _remember(_starsSpentKey, '${spent + price}');
  });

  Future<void> _remember(String key, String value) => db
      .into(db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(key: key, value: value),
      );

  @override
  Future<void> saveCoop(CoopMode mode, RunResult result) => db.transaction(
    () async {
      if (result.score < 0) throw ArgumentError('Invalid run statistics');
      final prefs = {
        for (final row in await db.select(db.preferences).get())
          row.key: row.value,
      };
      // A retried save must not count the flight twice.
      if (prefs[_coopKey('Last', mode)] == result.id) return;
      final best = int.tryParse(prefs[_coopKey('Best', mode)] ?? '') ?? 0;
      final flights = int.tryParse(prefs[_coopKey('Flights', mode)] ?? '') ?? 0;
      await _remember(_coopKey('Last', mode), result.id);
      await _remember(_coopKey('Flights', mode), '${flights + 1}');
      if (mode.team && result.score > best) {
        await _remember(_coopKey('Best', mode), '${result.score}');
      }
    },
  );

  @override
  Future<void> chooseCoop(int first, int second, CoopMode mode) async {
    for (final bird in [first, second]) {
      if (bird < 0 || bird >= birdNames.length) {
        throw ArgumentError.value(bird, 'bird');
      }
    }
    await _remember(_coopBirdsKey, '$first,$second');
    await _remember(_coopModeKey, mode.name);
  }

  /// Each upgrade's level, such as `upgrade.magnet`, and the stars spent.
  static String _upgradeKey(PowerUp p) => 'upgrade.${p.name}';
  static const _starsSpentKey = 'starsSpent';

  static PowerUps _upgrades(Map<String, String> prefs) {
    var upgrades = const PowerUps();
    for (final p in PowerUp.values) {
      final level = int.tryParse(prefs[_upgradeKey(p)] ?? '') ?? 0;
      upgrades = upgrades.withLevel(p, level.clamp(0, PowerUp.maxLevel));
    }
    return upgrades;
  }

  static int _starsSpent(Map<String, String> prefs) =>
      math.max(0, int.tryParse(prefs[_starsSpentKey] ?? '') ?? 0);

  /// Stars collected on this phone's scored flights and on the other
  /// phones' restored from Play Games.
  Future<int> _starsEarned(Map<String, String> prefs) async {
    final local = await db
        .customSelect(
          'SELECT COALESCE(SUM(stars),0) AS stars FROM runs WHERE practice = 0',
        )
        .getSingle();
    return DeviceTotals.decodeAll(prefs[_carriedKey]).values.fold<int>(
      local.read<int>('stars'),
      (n, row) => row.records.values.fold(n, (n, r) => n + r.stars),
    );
  }

  @override
  Future<void> buyUpgrade(PowerUp p) => db.transaction(() async {
    final prefs = {
      for (final row in await db.select(db.preferences).get())
        row.key: row.value,
    };
    final level = _upgrades(prefs)[p];
    final cost = PowerUp.costFrom(level);
    if (cost == null) throw StateError('${p.title} is already at the top');
    final spent = _starsSpent(prefs);
    if (await _starsEarned(prefs) - spent < cost) {
      throw StateError('Not enough stars for ${p.title}');
    }
    await _remember(_upgradeKey(p), '${level + 1}');
    await _remember(_starsSpentKey, '${spent + cost}');
  });

  @override
  Future<void> reset({bool cloud = false}) => db.transaction(() async {
    final epoch = await _epoch();
    // Having synced stays: the cloud holds the old progress until the next
    // sync replaces it. The language stays too, so the player keeps reading
    // the game the way they just read the reset dialog.
    await _clear(const {_syncedKey, _languageKey});
    // Clearing the cloud copy too: the fresh logbook's higher epoch
    // replaces it rather than merging the old progress back. The time
    // keeps it above a reset on another phone this one has not heard of.
    // A reset that leaves the cloud alone keeps its epoch, so connecting
    // later still restores the cloud's progress.
    final next = cloud
        ? math.max(epoch + 1, clock().millisecondsSinceEpoch)
        : epoch;
    if (next > 0) await _remember(_epochKey, '$next');
  });

  /// Deletes this phone's progress: its flights, levels, built levels and
  /// every preference but the [keep] ones.
  Future<void> _clear(Set<String> keep) async {
    await db.delete(db.runs).go();
    await (db.delete(db.preferences)..where((p) => p.key.isNotIn(keep))).go();
    await db.delete(db.levelProgress).go();
    await db.delete(db.builtLevels).go();
    await db.delete(db.builtFlights).go();
  }

  /// What a reset on another phone leaves here: the device settings, the
  /// voice-over's memory and the Play Games sync's own. Saved sessions are
  /// not in this database and stay too.
  static final _localKeys = {
    for (final key in SettingKey.values) key.name,
    _languageKey,
    _flightVoicesKey,
    _playGamesKey,
    _syncedKey,
  };

  @override
  Future<bool> cloudSynced({String? player}) async {
    final last = await _pref(_syncedKey);
    return last != null && (player == null || last == player);
  }

  Future<int> _epoch() async => int.tryParse(await _pref(_epochKey) ?? '') ?? 0;

  Future<String?> _pref(String key) async => (await (db.select(
    db.preferences,
  )..where((p) => p.key.equals(key))).getSingleOrNull())?.value;

  /// This phone's id in the cloud logbook, made on first use. A reset
  /// forgets it, so a fresh start is a fresh row.
  Future<String> _deviceId() async {
    if (await _pref(_deviceKey) case final id? when id.isNotEmpty) return id;
    final random = math.Random.secure();
    final id = [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    await _remember(_deviceKey, id);
    return id;
  }

  @override
  Future<Logbook> exportLogbook() => db.transaction(_export);

  Future<Logbook> _export() async {
    final prefs = {
      for (final row in await db.select(db.preferences).get())
        row.key: row.value,
    };
    final me = await _deviceId();
    final mine = DeviceTotals(
      records: {
        for (final key in DeviceTotals.recordKeys) key: await _localRecord(key),
      },
      birdFlights: await _birdFlights(),
      builtWorkouts: {
        for (final MapEntry(:key, :value)
            in (await builtLevels.workouts()).entries)
          key.name: value,
      },
      coop: {
        for (final mode in CoopMode.values)
          mode.name: CoopRecord(
            best: int.tryParse(prefs[_coopKey('Best', mode)] ?? '') ?? 0,
            flights: int.tryParse(prefs[_coopKey('Flights', mode)] ?? '') ?? 0,
          ),
      },
    );
    return Logbook(
      epoch: int.tryParse(prefs[_epochKey] ?? '') ?? 0,
      devices: {...DeviceTotals.decodeAll(prefs[_carriedKey]), me: mine},
      levels: {
        for (final row in await db.select(db.levelProgress).get())
          row.level: _levelRecord(row),
      },
      upgrades: _upgrades(prefs),
      birds: {
        for (final b in _unlockedBirds(prefs))
          if (birdPrices[b] > 0) b,
      },
      storyWatched: _names(prefs[_storyKey]),
      feats: _names(prefs[_featsKey]),
      builtLevels: {
        for (final row in await db.select(db.builtLevels).get())
          row.id: {
            'name': row.name,
            'mode': row.mode,
            'json': row.json,
            'fingerprint': row.fingerprint,
            'revision': row.revision,
            'origin': row.origin,
            'remixOf': row.remixOf,
            'clearedRevision': row.clearedRevision,
            'importedCleared': row.importedCleared,
            'createdAt': row.createdAt.millisecondsSinceEpoch,
            'updatedAt': row.updatedAt.millisecondsSinceEpoch,
          },
      },
      builtDeleted: _names(prefs[builtDeletedKey]),
    );
  }

  @override
  Future<(Logbook, bool)> importLogbook(Logbook? cloud, {String player = ''}) =>
      db.transaction(() async {
        var local = await _export();
        // A reset on a phone that synced raised the cloud's epoch. A phone
        // that has synced with this player before may hold that old progress
        // anywhere, so it starts afresh too, once: it takes the new epoch as it
        // clears. A phone that never synced with this player (another
        // account's, or none) is never wiped, and its epoch, another cloud's,
        // must never replace this one: it takes this cloud's and merges.
        final synced = await cloudSynced(player: player);
        final fresh = synced && cloud != null && cloud.epoch > local.epoch;
        if (fresh || !synced) {
          if (fresh) await _clear(_localKeys);
          await _remember(_epochKey, '${cloud?.epoch ?? 0}');
          local = await _export();
        }
        if (!synced) await _remember(_syncedKey, player);
        final me = await _deviceId();
        final merged = Logbook.merge(local, cloud, me: me);
        final changed =
            fresh || jsonEncode(merged.toJson()) != jsonEncode(local.toJson());
        if (!changed) return (merged, false);
        await _remember(
          _carriedKey,
          DeviceTotals.encodeAll({...merged.devices}..remove(me)),
        );
        await _remember(_epochKey, '${merged.epoch}');
        for (final MapEntry(:key, :value) in merged.levels.entries) {
          if (local.levels[key] case final old? when _same(old, value)) {
            continue;
          }
          await db
              .into(db.levelProgress)
              .insertOnConflictUpdate(
                LevelProgressCompanion.insert(
                  level: key,
                  bestStars: Value(value.bestStars),
                  bestCollected: Value(value.bestCollected),
                  bestScore: Value(value.bestScore),
                  plays: Value(value.plays),
                  firstClearedAt: Value(value.firstClearedAt),
                  lastPlayedAt: Value(value.lastPlayedAt),
                  postcardSeen: Value(value.postcardSeen),
                ),
              );
        }
        final bought = merged.birds.toList()..sort();
        final purchases =
            jsonEncode([merged.upgrades.toJson(), bought]) !=
            jsonEncode([local.upgrades.toJson(), local.birds.toList()..sort()]);
        if (purchases) {
          for (final p in PowerUp.values) {
            await _remember(_upgradeKey(p), '${merged.upgrades[p]}');
          }
          await _remember(_birdUnlocksKey, bought.join(','));
          // Purchases from both phones are paid for once, at today's
          // prices; the wallet shows 0 rather than less (see starWallet).
          await _remember(
            _starsSpentKey,
            '${spentOn(merged.upgrades, bought)}',
          );
        }
        await _remember(
          _storyKey,
          (merged.storyWatched.toList()..sort()).join(','),
        );
        await _remember(_featsKey, (merged.feats.toList()..sort()).join(','));
        await _remember(
          builtDeletedKey,
          (merged.builtDeleted.toList()..sort()).join(','),
        );
        for (final id in merged.builtDeleted) {
          await (db.delete(db.builtLevels)..where((l) => l.id.equals(id))).go();
        }
        for (final MapEntry(:key, :value) in merged.builtLevels.entries) {
          final old = local.builtLevels[key];
          if (old != null && jsonEncode(old) == jsonEncode(value)) continue;
          if (_builtRow(key, value) case final row?) {
            await db.into(db.builtLevels).insertOnConflictUpdate(row);
          }
        }
        // Changed means this phone's progress moved, not that the merged blob
        // differs: what this build cannot import (a built level of an unknown
        // mode) stays in the cloud copy but never lands here. A fresh start
        // always counts, so the screens let go of the cleared progress.
        final after = jsonEncode((await _export()).toJson());
        return (merged, fresh || after != jsonEncode(local.toJson()));
      });

  static bool _same(LevelRecord a, LevelRecord b) =>
      a.bestStars == b.bestStars &&
      a.bestCollected == b.bestCollected &&
      a.bestScore == b.bestScore &&
      a.plays == b.plays &&
      a.firstClearedAt == b.firstClearedAt &&
      a.lastPlayedAt == b.lastPlayedAt &&
      a.postcardSeen == b.postcardSeen;

  /// A built level from the logbook as a `built_levels` row, or null when
  /// it is not a player's level or cannot be read.
  static BuiltLevelsCompanion? _builtRow(String id, Map<String, Object?> m) {
    final (name, mode, json, fingerprint, revision, origin) = (
      m['name'],
      m['mode'],
      m['json'],
      m['fingerprint'],
      m['revision'],
      m['origin'],
    );
    final (created, updated) = (m['createdAt'], m['updatedAt']);
    if (!id.startsWith('u-') ||
        name is! String ||
        mode is! int ||
        mode < 0 ||
        mode >= PlayMode.values.length ||
        json is! String ||
        fingerprint is! String ||
        revision is! int ||
        origin is! String ||
        created is! int ||
        updated is! int) {
      return null;
    }
    final remixOf = m['remixOf'], cleared = m['clearedRevision'];
    return BuiltLevelsCompanion.insert(
      id: id,
      name: name,
      mode: mode,
      json: json,
      fingerprint: fingerprint,
      revision: Value(revision),
      origin: Value(origin),
      remixOf: Value(remixOf is String ? remixOf : null),
      clearedRevision: Value(cleared is int ? cleared : null),
      importedCleared: Value(m['importedCleared'] == true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(created),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updated),
    );
  }

  /// Stars [upgrades] and the bought [birds] cost at today's prices.
  static int spentOn(PowerUps upgrades, Iterable<int> birds) =>
      PowerUp.values.fold(
        0,
        (n, p) =>
            n +
            PowerUp.costs
                .take(upgrades[p].clamp(0, PowerUp.maxLevel))
                .fold(0, (a, b) => a + b),
      ) +
      birds.fold(0, (n, b) => n + birdPrices[b]);

  @override
  Future<String?> loadPlayGamesMemory() => _pref(_playGamesKey);

  @override
  Future<void> savePlayGamesMemory(String memory) =>
      _remember(_playGamesKey, memory);
  @override
  Future<void> close() => db.close();
}
