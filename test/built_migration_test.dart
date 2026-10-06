import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';

void main() {
  late Directory folder;
  late File file;
  setUp(() {
    folder = Directory.systemTemp.createTempSync('built-migration');
    file = File('${folder.path}/save.sqlite');
  });
  tearDown(() => folder.deleteSync(recursive: true));

  test('a schema-6 save opens at schema 7 with everything kept', () async {
    // A save as schema 6 left it: no builder tables.
    var db = ProgressDatabase(NativeDatabase(file));
    await db
        .into(db.runs)
        .insert(
          RunsCompanion.insert(
            id: 'endless',
            mode: PlayMode.squat.index,
            course: Value(FlightCourse.starTrail.name),
            practice: false,
            score: 40,
            stars: const Value(30),
            repetitions: 14,
            flaps: 0,
            duration: 90,
            reason: EndReason.collision.name,
            finishedAt: DateTime(2026, 10, 1),
          ),
        );
    await db
        .into(db.preferences)
        .insert(PreferencesCompanion.insert(key: 'music', value: 'false'));
    await db.customStatement('DROP TABLE built_levels');
    await db.customStatement('DROP TABLE built_flights');
    await db.customStatement('PRAGMA user_version = 6');
    await db.close();

    db = ProgressDatabase(NativeDatabase(file));
    final repo = SqliteProgressRepository(db);
    addTearDown(repo.close);
    final p = await repo.load();
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      7,
    );
    expect(p.totalSquats, 14);
    expect(p.trailSquat.stars, 30);
    expect(p.settings.music, isFalse);
    // The builder's tables are there, empty, and work.
    expect(await repo.builtLevels.levels(), isEmpty);
    final plan = sampleLevel(PlayMode.squat, id: 'u-aftermove1');
    await repo.builtLevels.create(plan);
    expect((await repo.builtLevels.levels()).single.id, plan.id);
  });
}
