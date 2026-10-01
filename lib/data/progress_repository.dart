import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/campaign.dart';
import '../domain/campaign_progress.dart';
import '../domain/campaign_story.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import '../domain/daily_adventure.dart';

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

@DriftDatabase(tables: [Runs, Preferences, LevelProgress])
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
  int get schemaVersion => 5;
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
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

const birdNames = ['Pip', 'Peaches', 'Minty', 'Orbit'];
const birdDescriptions = [
  'Small bird. Big sky.',
  'Rosy cheeks, curly crest, all heart.',
  'Tiny hummer. Fresh sprig. Full speed.',
  'A dreamy owl who flies by starlight.',
];

enum SettingKey { music, effects, voices, reducedMotion, recordAudio }

class GameSettings {
  const GameSettings({
    this.music = true,
    this.effects = true,
    this.reducedMotion = false,
    this.recordAudio = false,
    this.voices = true,
    this.bird = 0,
  });
  final bool music, effects, reducedMotion, recordAudio;

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
    this.birds = (0, 1),
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
    this.recent = const [],
    this.adventures = const [],
    this.coop = const CoopProgress(),
    this._campaign,
  });
  final GameSettings settings;

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

  /// The latest endless flights.
  final List<RunResult> recent;

  /// Oldest first, ending with today. Derived from saved flights, not counters.
  final List<DailyAdventure> adventures;
  DailyAdventure? get today => adventures.isEmpty ? null : adventures.last;
  int get totalObstacles => allRecords.fold(0, (n, r) => n + r.obstacles);
  int get totalRuns => allRecords.fold(0, (n, r) => n + r.runs);

  /// Every scored flight, campaign levels included.
  int get flightsFlown => totalRuns + campaignFlights.runs;
  int get totalRepetitions => pushUp.repetitions + trailPushUp.repetitions;
  int get totalSquats => squat.repetitions + trailSquat.repetitions;
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
  Future<void> equipBird(int bird);

  /// Saves a co-op flight in [mode] once per id: its mode's best and flight
  /// count. It never touches the solo records.
  Future<void> saveCoop(CoopMode mode, RunResult result);

  /// Remembers the birds players 1 and 2 chose for co-op, and the mode.
  Future<void> chooseCoop(int first, int second, CoopMode mode);
  Future<void> reset();
  Future<void> close();
}

class SqliteProgressRepository implements ProgressRepository {
  SqliteProgressRepository(this.db, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final ProgressDatabase db;
  final DateTime Function() clock;
  @override
  Future<ProgressSnapshot> load() => db.transaction(() async {
    final prefs = {
      for (final row in await db.select(db.preferences).get())
        row.key: row.value,
    };
    final birdsFlown = {
      for (final row
          in await db
              .customSelect('SELECT DISTINCT bird FROM runs WHERE practice = 0')
              .get())
        row.read<int>('bird'),
    };
    Future<ModeRecord> tally(
      String where, [
      List<Variable> variables = const [],
    ]) async {
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

    // Campaign levels are never endless records.
    Future<ModeRecord> record(PlayMode mode, FlightCourse course) => tally(
      'level IS NULL AND mode = ? AND course = ?',
      [Variable.withInt(mode.index), Variable.withString(course.name)],
    );

    final selected = int.tryParse(prefs['bird'] ?? '0') ?? 0;
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
    return ProgressSnapshot(
      settings: GameSettings(
        music: prefs['music'] != 'false',
        effects: prefs['effects'] != 'false',
        reducedMotion: prefs['reducedMotion'] == 'true',
        recordAudio: prefs['recordAudio'] == 'true',
        voices: prefs['voices'] != 'false',
        bird: selected >= 0 && selected < birdNames.length ? selected : 0,
      ),
      pushUp: await record(PlayMode.pushUp, FlightCourse.classic),
      jump: await record(PlayMode.jump, FlightCourse.classic),
      touch: await record(PlayMode.touch, FlightCourse.classic),
      squat: await record(PlayMode.squat, FlightCourse.classic),
      trailPushUp: await record(PlayMode.pushUp, FlightCourse.starTrail),
      trailJump: await record(PlayMode.jump, FlightCourse.starTrail),
      trailTouch: await record(PlayMode.touch, FlightCourse.starTrail),
      trailSquat: await record(PlayMode.squat, FlightCourse.starTrail),
      campaignFlights: await tally('level IS NOT NULL'),
      campaign: CampaignProgress(
        levels.map(_levelRecord),
        storyWatched: _storyWatched(prefs[_storyKey]),
      ),
      birdsFlown: birdsFlown,
      recent: rows.map(_runResult).toList(),
      coop: CoopProgress(
        records: {
          for (final mode in CoopMode.values)
            mode: CoopRecord(
              best: int.tryParse(prefs[_coopKey('Best', mode)] ?? '') ?? 0,
              flights:
                  int.tryParse(prefs[_coopKey('Flights', mode)] ?? '') ?? 0,
            ),
        },
        birds: _coopBirds(prefs[_coopBirdsKey], selected),
        mode:
            CoopMode.values.asNameMap()[prefs[_coopModeKey]] ?? CoopMode.roped,
      ),
      adventures: [
        for (var i = 6; i >= 0; i--)
          DailyAdventure.forDate(
            DateTime(today.year, today.month, today.day - i),
            weekRuns,
          ),
      ],
    );
  });

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
    });
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

  static Set<String> _storyWatched(String? saved) => {
    for (final id in (saved ?? '').split(','))
      if (id.isNotEmpty) id,
  };

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
  static (int, int) _coopBirds(String? saved, int equipped) {
    final first = equipped >= 0 && equipped < birdNames.length ? equipped : 0;
    final fallback = (first, (first + 1) % birdNames.length);
    final parts = saved?.split(',').map(int.tryParse).toList();
    if (parts == null || parts.length != 2) return fallback;
    final [a, b] = parts;
    bool valid(int? bird) =>
        bird != null && bird >= 0 && bird < birdNames.length;
    return valid(a) && valid(b) ? (a!, b!) : fallback;
  }

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

  @override
  Future<void> reset() => db.transaction(() async {
    await db.delete(db.runs).go();
    await db.delete(db.preferences).go();
    await db.delete(db.levelProgress).go();
  });
  @override
  Future<void> close() => db.close();
}
