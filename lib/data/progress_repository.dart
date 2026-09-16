import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';

part 'progress_repository.g.dart';

class Runs extends Table {
  TextColumn get id => text()();
  IntColumn get mode => integer()();
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
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _backfillUnlocks();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(birdUnlocks);
        await _backfillUnlocks();
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
  Future<void> _backfillUnlocks() async {
    final total = await customSelect(
      'SELECT COALESCE(SUM(score), 0) AS total FROM runs WHERE practice = 0',
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
  });
  final int best, runs, obstacles, repetitions;
}

class ProgressSnapshot {
  const ProgressSnapshot({
    this.settings = const GameSettings(),
    this.pushUp = const ModeRecord(),
    this.smile = const ModeRecord(),
    this.unlocked = const {0},
    this.recent = const [],
  });
  final GameSettings settings;
  final ModeRecord pushUp, smile;
  final Set<int> unlocked;
  final List<RunResult> recent;
  int get totalObstacles => pushUp.obstacles + smile.obstacles;
  int get totalRuns => pushUp.runs + smile.runs;
  ModeRecord record(PlayMode mode) => mode == PlayMode.pushUp ? pushUp : smile;
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
  SqliteProgressRepository(this.db);
  final ProgressDatabase db;
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
    Future<ModeRecord> record(PlayMode mode) async {
      final r = await db
          .customSelect(
            'SELECT COALESCE(MAX(score),0) AS best, COUNT(*) AS runs, '
            'COALESCE(SUM(score),0) AS obstacles, COALESCE(SUM(repetitions),0) AS repetitions '
            'FROM runs WHERE practice = 0 AND mode = ?',
            variables: [Variable.withInt(mode.index)],
          )
          .getSingle();
      return ModeRecord(
        best: r.read<int>('best'),
        runs: r.read<int>('runs'),
        obstacles: r.read<int>('obstacles'),
        repetitions: r.read<int>('repetitions'),
      );
    }

    final selected = int.tryParse(prefs['bird'] ?? '0') ?? 0;
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
      pushUp: await record(PlayMode.pushUp),
      smile: await record(PlayMode.smile),
      unlocked: unlocked,
      recent: rows
          .map(
            (r) => RunResult(
              id: r.id,
              mode: PlayMode.values[r.mode],
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
            ),
          )
          .toList(),
    );
  });
  @override
  Future<void> saveRun(RunResult result) async {
    if (result.score < 0 ||
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
              practice: result.practice,
              score: result.score,
              repetitions: result.mode == PlayMode.pushUp
                  ? result.repetitions
                  : 0,
              flaps: result.mode == PlayMode.smile ? result.flaps : 0,
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
