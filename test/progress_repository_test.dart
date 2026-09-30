import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

RunResult run(
  String id,
  int score, {
  PlayMode mode = PlayMode.pushUp,
  bool practice = false,
  int bird = 0,
}) => RunResult(
  id: id,
  mode: mode,
  practice: practice,
  score: score,
  repetitions: 4,
  flaps: 8,
  durationSeconds: 10,
  reason: EndReason.collision,
  finishedAt: DateTime(2026, 9, 11),
  bird: bird,
);
void main() {
  test('Star Trail records stay separate from classic records', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    await repo.saveRun(run('classic', 12));
    final trail = RunResult(
      id: 'trail',
      mode: PlayMode.pushUp,
      practice: false,
      course: FlightCourse.starTrail,
      score: 200,
      gates: 6,
      stars: 75,
      bestCombo: 18,
      perfectPasses: 3,
      repetitions: 8,
      flaps: 0,
      durationSeconds: 60,
      reason: EndReason.completed,
      finishedAt: DateTime(2026, 9, 16),
    );
    await repo.saveRun(trail);
    await repo.saveRun(trail);
    final p = await repo.load();
    expect(p.pushUp.best, 12);
    expect(p.trailPushUp.best, 200);
    expect(p.record(PlayMode.pushUp, FlightCourse.starTrail).best, 200);
    expect(p.totalObstacles, 18);
    expect(p.totalRuns, 2);
    expect(p.totalRepetitions, 12);
    expect(p.recent.first.course, FlightCourse.starTrail);
    expect(p.recent.first.stars, 75);
    expect(p.recent.first.bestCombo, 18);
    expect(p.recent.first.perfectPasses, 3);
    expect(p.recent.first.reason, EndReason.completed);
  });
  test(
    'mode records, idempotency, practice exclusion and birds flown',
    () async {
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      addTearDown(repo.close);
      await repo.saveRun(run('a', 24));
      await repo.saveRun(run('a', 24));
      await repo.saveRun(run('practice', 300, practice: true, bird: 3));
      var p = await repo.load();
      expect(p.totalObstacles, 24);
      expect(p.birdsFlown, {0}, reason: 'Practice flights do not count');
      expect(p.totalRuns, 1);
      await repo.saveRun(run('b', 1, mode: PlayMode.jump, bird: 2));
      p = await repo.load();
      expect(p.birdsFlown, {0, 2});
      expect(p.recent.singleWhere((r) => r.id == 'b').bird, 2);
      expect(p.pushUp.best, 24);
      expect(p.jump.best, 1);
      expect(p.jump.repetitions, 0);
      await repo.saveRun(run('c', 75, mode: PlayMode.jump, bird: 1));
      await repo.saveRun(run('d', 150, bird: 3));
      expect((await repo.load()).birdsFlown, {0, 1, 2, 3});
      await expectLater(
        repo.saveRun(run('e', 1, bird: 4)),
        throwsArgumentError,
      );
    },
  );
  test(
    'every bird can be equipped from the start and reset is complete',
    () async {
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      addTearDown(repo.close);
      for (var bird = 0; bird < birdNames.length; bird++) {
        await repo.equipBird(bird);
        expect((await repo.load()).settings.bird, bird);
      }
      await expectLater(repo.equipBird(birdNames.length), throwsArgumentError);
      await repo.setSetting(SettingKey.music, false);
      await repo.setSetting(SettingKey.recordAudio, true);
      await repo.saveRun(run('a', 30, bird: 3));
      await repo.equipBird(1);
      await repo.reset();
      final p = await repo.load();
      expect(p.totalObstacles, 0);
      expect(p.birdsFlown, isEmpty);
      expect(p.settings.bird, 0);
      expect(p.settings.music, true);
      expect(p.settings.recordAudio, false);
      expect(p.recent, isEmpty);
    },
  );
  test(
    'records, settings and cosmetics survive closing and reopening SQLite',
    () async {
      final folder = await Directory.systemTemp.createTemp('bird-db-test');
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}/test.sqlite');
      var repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase(file)),
      );
      expect((await repo.load()).settings.recordAudio, isFalse);
      await repo.setSetting(SettingKey.recordAudio, true);
      await repo.saveRun(run('a', 100));
      await repo.setSetting(SettingKey.reducedMotion, true);
      await repo.equipBird(2);
      await repo.close();
      repo = SqliteProgressRepository(ProgressDatabase(NativeDatabase(file)));
      addTearDown(repo.close);
      final p = await repo.load();
      expect(p.totalObstacles, 100);
      expect(p.settings.reducedMotion, true);
      expect(p.settings.recordAudio, true);
      expect(p.settings.bird, 2);
    },
  );
  test('v1 to v5 migration keeps runs and settings', () async {
    final db = ProgressDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE runs (id TEXT PRIMARY KEY NOT NULL, mode INTEGER NOT NULL, practice INTEGER NOT NULL, score INTEGER NOT NULL, repetitions INTEGER NOT NULL, flaps INTEGER NOT NULL, duration REAL NOT NULL, reason TEXT NOT NULL, finished_at INTEGER NOT NULL)',
          );
          raw.execute(
            'CREATE TABLE preferences (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL)',
          );
          raw.execute(
            "INSERT INTO runs VALUES ('old-run',0,0,110,5,0,20.0,'collision',1700000000)",
          );
          raw.execute("INSERT INTO preferences VALUES ('music','false')");
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    final repo = SqliteProgressRepository(db);
    addTearDown(repo.close);
    final p = await repo.load();
    expect(p.totalObstacles, 110);
    expect(p.birdsFlown, {0}, reason: 'Unrecorded legacy flights count as Pip');
    expect(p.settings.music, false);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      5,
    );
    expect(p.recent.single.levelId, isNull);
    expect(p.campaign.records, isEmpty);
  });

  test(
    'v2 migration keeps the equipped bird, drops unlocks and maps only legacy gate scores',
    () async {
      final db = ProgressDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              'CREATE TABLE runs (id TEXT PRIMARY KEY NOT NULL, mode INTEGER NOT NULL, practice INTEGER NOT NULL, score INTEGER NOT NULL, repetitions INTEGER NOT NULL, flaps INTEGER NOT NULL, duration REAL NOT NULL, reason TEXT NOT NULL, finished_at INTEGER NOT NULL)',
            );
            raw.execute(
              'CREATE TABLE preferences (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL)',
            );
            raw.execute(
              'CREATE TABLE bird_unlocks (bird INTEGER PRIMARY KEY NOT NULL, unlocked_at INTEGER NOT NULL)',
            );
            raw.execute(
              "INSERT INTO runs VALUES ('classic',0,0,5,2,0,20.0,'collision',1700000000)",
            );
            raw.execute(
              "INSERT INTO runs VALUES ('practice',1,1,999,0,99,90.0,'quit',1700000001)",
            );
            raw.execute("INSERT INTO preferences VALUES ('bird','2')");
            raw.execute(
              'INSERT INTO bird_unlocks VALUES (0,1700000000),(1,1700000000),(2,1700000000)',
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );
      final repo = SqliteProgressRepository(db);
      addTearDown(repo.close);
      final p = await repo.load();
      expect(p.settings.bird, 2);
      expect(
        await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE name = 'bird_unlocks'",
            )
            .get(),
        isEmpty,
      );
      expect(p.pushUp.best, 5);
      expect(p.totalObstacles, 5);
      expect(p.totalRuns, 1);
      expect(p.totalStars, 0);
      expect(p.totalPerfects, 0);
      expect(p.trailPushUp.runs, 0);
      expect(p.recent.single.course, FlightCourse.classic);
      expect(p.recent.single.gates, 5);
      expect(p.recent.single.stars, 0);
    },
  );
}
