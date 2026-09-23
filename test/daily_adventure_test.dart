import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/daily_adventure.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

RunResult dailyRun(
  String id,
  DateTime date, {
  bool practice = false,
  FlightCourse course = FlightCourse.starTrail,
  PlayMode mode = PlayMode.pushUp,
  int gates = 4,
  int stars = 9,
  int combo = 9,
  int perfects = 2,
  double duration = 60,
  EndReason reason = EndReason.completed,
}) => RunResult(
  id: id,
  mode: mode,
  practice: practice,
  course: course,
  score: stars,
  gates: gates,
  stars: stars,
  bestCombo: combo,
  perfectPasses: perfects,
  repetitions: 3,
  flaps: 4,
  durationSeconds: duration,
  reason: reason,
  finishedAt: date,
);

void main() {
  test(
    'three daily goals rotate reproducibly and work with either movement control',
    () {
      final seen = <DailyTask>{};
      final combinations = <String>{};
      for (var offset = 0; offset < 12; offset++) {
        final day = DateTime(2026, 9, 16 + offset);
        final first = DailyAdventure.forDate(day, []);
        final same = DailyAdventure.forDate(
          day.add(const Duration(hours: 12)),
          [],
        );
        expect(first.goals.map((g) => g.task), same.goals.map((g) => g.task));
        expect(first.goals, hasLength(3));
        expect(first.goals.map((g) => g.task).toSet(), hasLength(3));
        expect(first.complete, isFalse);
        combinations.add(first.goals.map((g) => g.task.name).join(','));
        seen.addAll(first.goals.map((g) => g.task));
        for (final control in PlayMode.values) {
          final finished = DailyAdventure.forDate(day, [
            dailyRun('one', day, mode: control),
            dailyRun('two', day, mode: control),
          ]);
          expect(
            finished.complete,
            isTrue,
            reason: 'Every card must be achievable with $control',
          );
          expect(finished.goals.every((g) => g.displayed <= g.target), isTrue);
        }
      }
      expect(seen, DailyTask.values.toSet());
      expect(combinations.length, greaterThan(3));
    },
  );

  test(
    'practice flights, other dates and duplicate IDs cannot inflate a card',
    () {
      final day = DateTime(2026, 9, 16);
      final one = dailyRun(
        'one',
        day,
        stars: 2,
        gates: 1,
        perfects: 0,
        combo: 2,
        duration: 12,
        reason: EndReason.collision,
      );
      final card = DailyAdventure.forDate(day, [
        one,
        one,
        dailyRun('practice', day, practice: true, stars: 999),
        dailyRun('yesterday', DateTime(2026, 9, 15, 23, 59, 59)),
        dailyRun('tomorrow', DateTime(2026, 9, 17)),
      ]);
      final single = DailyAdventure.forDate(day, [one]);
      expect(
        card.goals.map((g) => g.current),
        single.goals.map((g) => g.current),
      );
      expect(card.complete, isFalse);
    },
  );

  test(
    'streak goals use the best single flight and a trail must really finish',
    () {
      for (var d = 1; d < 20; d++) {
        final date = DateTime(2026, 10, d);
        final card = DailyAdventure.forDate(date, [
          dailyRun('one', date, combo: 5, duration: 10),
          dailyRun('two', date, combo: 4, duration: 10),
        ]);
        for (final goal in card.goals) {
          if (goal.task == DailyTask.streak) expect(goal.current, 5);
          if (goal.task == DailyTask.finishTrail) expect(goal.current, 0);
        }
      }
    },
  );

  test(
    'saved-flight date grouping respects the local day at both boundaries',
    () {
      final day = DateTime(2026, 9, 16);
      expect(localDayKey(day.toUtc()), localDayKey(day));
      final inLocalDay = DailyAdventure.forDate(day, [
        dailyRun('start', day.toUtc()),
        dailyRun('end', DateTime(2026, 9, 16, 23, 59, 59).toUtc()),
      ]);
      expect(inLocalDay.complete, isTrue);
      expect(localDayKey(DateTime(2026, 10, 0)), '2026-09-30');
    },
  );

  test(
    'cards survive reopening, include more than ten recent flights, and roll over by calendar day',
    () async {
      final folder = await Directory.systemTemp.createTemp('daily-db');
      addTearDown(() => folder.delete(recursive: true));
      final file = File('${folder.path}/sky.sqlite');
      var now = DateTime(2026, 9, 16, 23, 59);
      var repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase(file)),
        clock: () => now,
      );
      for (var i = 0; i < 12; i++) {
        final run = dailyRun(
          'flight-$i',
          DateTime(2026, 9, 16, 12, i),
          stars: 2,
          gates: 1,
          combo: 9,
          perfects: 1,
        );
        await repo.saveRun(run);
        await repo.saveRun(run);
      }
      await repo.saveRun(dailyRun('practice', now, practice: true));
      var progress = await repo.load();
      expect(progress.recent, hasLength(10));
      expect(progress.today!.complete, isTrue);
      expect(progress.adventures, hasLength(7));
      final counts = progress.today!.goals.map((g) => g.current).toList();
      await repo.close();
      repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase(file)),
        clock: () => now,
      );
      addTearDown(repo.close);
      progress = await repo.load();
      expect(progress.today!.goals.map((g) => g.current), counts);
      now = DateTime(2026, 9, 17);
      progress = await repo.load();
      expect(progress.today!.dayKey, '2026-09-17');
      expect(progress.today!.completedGoals, 0);
      expect(progress.adventures[5].complete, isTrue);
      await repo.reset();
      progress = await repo.load();
      expect(progress.adventures.every((c) => c.completedGoals == 0), isTrue);
    },
  );
}
