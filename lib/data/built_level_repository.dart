import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/built_level.dart';
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import 'progress_repository.dart';

/// The preference listing the ids of deleted built levels.
const builtDeletedKey = 'builtDeleted';

/// The levels players build, and their flights' bests. Starter templates
/// live in code (`BuiltTemplates`); only their flights are kept here.
abstract interface class BuiltLevelStore {
  /// Every saved level, the latest edited first. A row that can no longer
  /// be read is left out rather than failing the list.
  Future<List<BuiltLevel>> levels();
  Future<BuiltLevel?> level(String id);

  /// Keeps a new level. Its id must be a fresh player id (`u-…`).
  Future<BuiltLevel> create(
    BuiltPlan plan, {
    BuiltOrigin origin = BuiltOrigin.created,
    String? remixOf,
    bool importedCleared = false,
  });

  /// Saves an edit of a kept level. A changed route (its
  /// [BuiltPlan.fingerprint]) is a new revision, whose bests start afresh;
  /// a new name or id alone is not.
  Future<BuiltLevel> save(BuiltPlan plan);
  Future<void> delete(String id);

  /// A kept level with the same route as [plan], if any.
  Future<BuiltLevel?> sameRoute(BuiltPlan plan);

  /// Remembers that the creator flew [id]'s [revision] to the finish.
  Future<void> markCleared(String id, int revision);

  /// Every level's bests at every revision flown.
  Future<List<BuiltBest>> bests();

  /// Saves a built level's scored flight once per run id.
  Future<void> saveFlight(BuiltFlightRecord flight);

  /// Repetitions (push-ups, squats) and jumps done on built levels, by
  /// mode.
  Future<Map<PlayMode, int>> workouts();
}

class SqliteBuiltLevelStore implements BuiltLevelStore {
  SqliteBuiltLevelStore(this.db, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final ProgressDatabase db;
  final DateTime Function() clock;

  static BuiltLevel? _read(BuiltLevelRow row) {
    try {
      final plan = BuiltPlan.fromJson(
        jsonDecode(row.json) as Map<String, dynamic>,
        checked: false,
      );
      if (plan.id != row.id) return null;
      return BuiltLevel(
        plan: plan,
        revision: row.revision,
        origin:
            BuiltOrigin.values.asNameMap()[row.origin] ?? BuiltOrigin.created,
        from: row.remixOf,
        clearedRevision: row.clearedRevision,
        importedCleared: row.importedCleared,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<BuiltLevelRow?> _row(String id) => (db.select(
    db.builtLevels,
  )..where((l) => l.id.equals(id))).getSingleOrNull();

  @override
  Future<List<BuiltLevel>> levels() async => [
    for (final row
        in await (db.select(db.builtLevels)..orderBy([
              (l) => OrderingTerm.desc(l.updatedAt),
              (l) => OrderingTerm.asc(l.id),
            ]))
            .get())
      ?_read(row),
  ];

  @override
  Future<BuiltLevel?> level(String id) async {
    final row = await _row(id);
    return row == null ? null : _read(row);
  }

  @override
  Future<BuiltLevel> create(
    BuiltPlan plan, {
    BuiltOrigin origin = BuiltOrigin.created,
    String? remixOf,
    bool importedCleared = false,
  }) => db.transaction(() async {
    if (!plan.id.startsWith('u-') || !BuiltPlan.isBuiltId(plan.id)) {
      throw ArgumentError.value(plan.id, 'id', 'Not a player level');
    }
    if (await _row(plan.id) != null) {
      throw StateError('Level ${plan.id} exists');
    }
    final now = clock();
    await db
        .into(db.builtLevels)
        .insert(
          BuiltLevelsCompanion.insert(
            id: plan.id,
            name: plan.name,
            mode: plan.mode.index,
            json: jsonEncode(plan.toJson()),
            fingerprint: plan.fingerprint,
            origin: Value(origin.name),
            remixOf: Value(remixOf),
            importedCleared: Value(importedCleared),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await level(plan.id))!;
  });

  @override
  Future<BuiltLevel> save(BuiltPlan plan) => db.transaction(() async {
    final row = await _row(plan.id);
    if (row == null) throw StateError('No level ${plan.id}');
    final moved = row.fingerprint != plan.fingerprint;
    await (db.update(db.builtLevels)..where((l) => l.id.equals(plan.id))).write(
      BuiltLevelsCompanion(
        name: Value(plan.name),
        mode: Value(plan.mode.index),
        json: Value(jsonEncode(plan.toJson())),
        fingerprint: Value(plan.fingerprint),
        revision: Value(moved ? row.revision + 1 : row.revision),
        // A shared level's creator cleared that route, not this one.
        importedCleared: Value(row.importedCleared && !moved),
        updatedAt: Value(clock()),
      ),
    );
    return (await level(plan.id))!;
  });

  @override
  Future<void> delete(String id) => db.transaction(() async {
    await (db.delete(db.builtLevels)..where((l) => l.id.equals(id))).go();
    // Remembered so a Play Games merge never brings the level back.
    final row = await (db.select(
      db.preferences,
    )..where((p) => p.key.equals(builtDeletedKey))).getSingleOrNull();
    final deleted = {...?row?.value.split(',').where((id) => id.isNotEmpty)};
    if (!deleted.add(id)) return;
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(
            key: builtDeletedKey,
            value: (deleted.toList()..sort()).join(','),
          ),
        );
  });

  @override
  Future<BuiltLevel?> sameRoute(BuiltPlan plan) async {
    final rows = await (db.select(
      db.builtLevels,
    )..where((l) => l.fingerprint.equals(plan.fingerprint))).get();
    for (final row in rows) {
      final level = _read(row);
      if (level != null &&
          jsonEncode(level.plan.contentJson()) ==
              jsonEncode(plan.contentJson())) {
        return level;
      }
    }
    return null;
  }

  @override
  Future<void> markCleared(String id, int revision) async {
    await (db.update(db.builtLevels)
          ..where((l) => l.id.equals(id) & l.revision.equals(revision)))
        .write(BuiltLevelsCompanion(clearedRevision: Value(revision)));
  }

  @override
  Future<List<BuiltBest>> bests() async => [
    for (final row
        in await db
            .customSelect(
              'SELECT level, revision, MAX(rating) AS rating, '
              'MAX(stars) AS stars, MAX(score) AS score, COUNT(*) AS plays, '
              'MIN(CASE WHEN rating > 0 THEN finished_at END) AS cleared, '
              'MAX(finished_at) AS played '
              'FROM built_flights GROUP BY level, revision',
              readsFrom: {db.builtFlights},
            )
            .get())
      BuiltBest(
        level: row.read<String>('level'),
        revision: row.read<int>('revision'),
        stars: row.read<int>('rating'),
        collected: row.read<int>('stars'),
        score: row.read<int>('score'),
        plays: row.read<int>('plays'),
        firstClearedAt: row.readNullable<DateTime>('cleared'),
        lastPlayedAt: row.readNullable<DateTime>('played'),
      ),
  ];

  @override
  Future<void> saveFlight(BuiltFlightRecord flight) async {
    final (:plan, :revision, :run) = flight;
    if (run.practice ||
        run.levelId != plan.id ||
        run.mode != plan.mode ||
        revision < 1 ||
        run.score < 0 ||
        run.stars < 0 ||
        run.repetitions < 0 ||
        run.flaps < 0 ||
        !run.durationSeconds.isFinite ||
        run.durationSeconds < 0) {
      throw ArgumentError('Not a scored flight of ${plan.id}');
    }
    await db
        .into(db.builtFlights)
        .insert(
          BuiltFlightsCompanion.insert(
            id: run.id,
            level: plan.id,
            revision: revision,
            mode: run.mode.index,
            rating: Value(
              plan.rate(
                finished: run.reason == EndReason.completed,
                stars: run.stars,
              ),
            ),
            stars: Value(run.stars),
            score: Value(run.score),
            repetitions: Value(run.mode.controlsHeight ? run.repetitions : 0),
            flaps: Value(run.mode.controlsHeight ? 0 : run.flaps),
            duration: run.durationSeconds,
            reason: run.reason.name,
            finishedAt: run.finishedAt,
          ),
          // A retried save must not count the flight twice.
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<Map<PlayMode, int>> workouts() async => {
    for (final row
        in await db
            .customSelect(
              'SELECT mode, COALESCE(SUM(repetitions),0) AS reps, '
              'COALESCE(SUM(flaps),0) AS flaps '
              'FROM built_flights GROUP BY mode',
              readsFrom: {db.builtFlights},
            )
            .get())
      if (row.read<int>('mode') case final mode
          when mode >= 0 && mode < PlayMode.values.length)
        PlayMode.values[mode]: PlayMode.values[mode].controlsHeight
            ? row.read<int>('reps')
            : row.read<int>('flaps'),
  };
}
