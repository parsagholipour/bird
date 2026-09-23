import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class BirdUnlocks extends Table {
  IntColumn get bird => integer()();
  DateTimeColumn get unlockedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {bird};
}

@DriftDatabase(tables: [Runs, Preferences, BirdUnlocks])
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
  int get schemaVersion => 3;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _backfillUnlocks();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(birdUnlocks);
      }
      if (from < 3) {
        await m.addColumn(runs, runs.course);
        await m.addColumn(runs, runs.gates);
        await m.addColumn(runs, runs.stars);
        await m.addColumn(runs, runs.bestCombo);
        await m.addColumn(runs, runs.perfectPasses);
        await customStatement('UPDATE runs SET gates = score');
      }
      await _backfillUnlocks();
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
  Future<void> _backfillUnlocks() async {
    final total = await customSelect(
      'SELECT COALESCE(SUM(gates), 0) AS total FROM runs WHERE practice = 0',
    ).getSingle();
    final count = total.read<int>('total');
    for (var i = 0; i < unlockThresholds.length; i++) {
      if (count >= unlockThresholds[i]) {
        await into(birdUnlocks).insert(
          BirdUnlocksCompanion.insert(
            bird: Value(i),
            unlockedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }
}

const unlockThresholds = [0, 25, 100, 250];
const birdNames = ['Pip', 'Peaches', 'Minty', 'Orbit'];
const birdDescriptions = [
  'Small bird. Big sky.',
  'A little peach with a lot of pep.',
  'Fresh wings. Cool company.',
  'Dreams beyond the clouds.',
];

enum SettingKey { music, effects, reducedMotion, recordAudio }

class GameSettings {
  const GameSettings({
    this.music = true,
    this.effects = true,
    this.reducedMotion = false,
    this.recordAudio = false,
    this.bird = 0,
  });
  final bool music, effects, reducedMotion, recordAudio;
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
    this.unlocked = const {0},
    this.recent = const [],
    this.adventures = const [],
  });
  final GameSettings settings;
  final ModeRecord pushUp,
      jump,
      touch,
      squat,
      trailPushUp,
      trailJump,
      trailTouch,
      trailSquat;
  final Set<int> unlocked;
  final List<RunResult> recent;

  /// Oldest first, ending with today. Derived from saved flights, not counters.
  final List<DailyAdventure> adventures;
  DailyAdventure? get today => adventures.isEmpty ? null : adventures.last;
  int get totalObstacles => allRecords.fold(0, (n, r) => n + r.obstacles);
  int get totalRuns => allRecords.fold(0, (n, r) => n + r.runs);
  int get totalRepetitions =>
      pushUp.repetitions + trailPushUp.repetitions;
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
  int? get nextBird {
    for (var i = 1; i < 4; i++) {
      if (!unlocked.contains(i)) return i;
    }
    return null;
  }
}

abstract interface class ProgressRepository {
  Future<ProgressSnapshot> load();
  Future<void> saveRun(RunResult result);
  Future<void> setSetting(SettingKey key, bool value);
  Future<void> equipBird(int bird);
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
    final unlocked = {
      0,
      ...((await db.select(db.birdUnlocks).get()).map((e) => e.bird)),
    };
    Future<ModeRecord> record(PlayMode mode, FlightCourse course) async {
      final r = await db
          .customSelect(
            'SELECT COALESCE(MAX(score),0) AS best, COUNT(*) AS runs, '
            'COALESCE(SUM(gates),0) AS obstacles, COALESCE(SUM(repetitions),0) AS repetitions '
            ', COALESCE(SUM(stars),0) AS stars, COALESCE(SUM(perfect_passes),0) AS perfects '
            ', COALESCE(MAX(best_combo),0) AS combo, '
            'COALESCE(SUM(reason = \'completed\' OR (course = \'starTrail\' AND duration >= 60)),0) AS completions '
            'FROM runs WHERE practice = 0 AND mode = ? AND course = ?',
            variables: [
              Variable.withInt(mode.index),
              Variable.withString(course.name),
            ],
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
              ..where((r) => r.practice.equals(false))
              ..orderBy([(r) => OrderingTerm.desc(r.finishedAt)])
              ..limit(10))
            .get();
    return ProgressSnapshot(
      settings: GameSettings(
        music: prefs['music'] != 'false',
        effects: prefs['effects'] != 'false',
        reducedMotion: prefs['reducedMotion'] == 'true',
        recordAudio: prefs['recordAudio'] == 'true',
        bird: unlocked.contains(selected) && selected >= 0 && selected < 4
            ? selected
            : 0,
      ),
      pushUp: await record(PlayMode.pushUp, FlightCourse.classic),
      jump: await record(PlayMode.jump, FlightCourse.classic),
      touch: await record(PlayMode.touch, FlightCourse.classic),
      squat: await record(PlayMode.squat, FlightCourse.classic),
      trailPushUp: await record(PlayMode.pushUp, FlightCourse.starTrail),
      trailJump: await record(PlayMode.jump, FlightCourse.starTrail),
      trailTouch: await record(PlayMode.touch, FlightCourse.starTrail),
      trailSquat: await record(PlayMode.squat, FlightCourse.starTrail),
      unlocked: unlocked,
      recent: rows.map(_runResult).toList(),
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
        result.durationSeconds < 0) {
      throw ArgumentError('Invalid run statistics');
    }
    await db.transaction(() async {
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
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await db._backfillUnlocks();
    });
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
    if (bird < 0 || bird >= 4) throw ArgumentError.value(bird, 'bird');
    await db.transaction(() async {
      final unlock = await (db.select(
        db.birdUnlocks,
      )..where((b) => b.bird.equals(bird))).getSingleOrNull();
      if (bird != 0 && unlock == null) {
        throw StateError('This bird is still locked');
      }
      await db
          .into(db.preferences)
          .insertOnConflictUpdate(
            PreferencesCompanion.insert(key: 'bird', value: '$bird'),
          );
    });
  }

  @override
  Future<void> reset() => db.transaction(() async {
    await db.delete(db.runs).go();
    await db.delete(db.preferences).go();
    await db.delete(db.birdUnlocks).go();
    await db._backfillUnlocks();
  });
  @override
  Future<void> close() => db.close();
}
