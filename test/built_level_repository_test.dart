import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/built_level.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';

final _at = DateTime(2026, 10, 6, 9);

RunResult builtRun(
  BuiltPlan plan, {
  String id = 'run-1',
  int stars = 20,
  int repetitions = 0,
  int flaps = 0,
  EndReason reason = EndReason.completed,
  bool practice = false,
}) => RunResult(
  id: id,
  mode: plan.mode,
  course: FlightCourse.starTrail,
  practice: practice,
  score: stars * 2,
  stars: stars,
  repetitions: repetitions,
  flaps: flaps,
  durationSeconds: 60,
  reason: reason,
  finishedAt: _at,
  levelId: plan.id,
  levelName: plan.name,
);

void main() {
  late SqliteProgressRepository repo;
  setUp(() {
    repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
      clock: () => _at,
    );
  });
  tearDown(() => repo.close());

  test('a level is kept, read back, edited and deleted', () async {
    final store = repo.builtLevels;
    final plan = sampleLevel(PlayMode.squat, id: 'u-squatlevel');
    expect(await store.levels(), isEmpty);
    final made = await store.create(plan);
    expect(made.revision, 1);
    expect(made.origin, BuiltOrigin.created);
    expect(made.cleared, isFalse);
    expect((await store.level(plan.id))!.plan.toJson(), plan.toJson());

    // A new name is the same revision; a moved gate is a new one.
    final renamed = await store.save(plan.copyWith(name: 'Leg Day'));
    expect(renamed.revision, 1);
    expect(renamed.plan.name, 'Leg Day');
    final moved = await store.save(
      renamed.plan.copyWith(
        items: [
          for (final item in renamed.plan.items)
            item is BuiltGate ? item.movedTo(x: item.x + 50) : item,
        ],
      ),
    );
    expect(moved.revision, 2);

    // A half-built draft is kept too.
    final draft = await store.save(
      moved.plan.copyWith(marks: const StarMarks(500, 600)),
    );
    expect(draft.plan.problem, 'marks');
    expect((await store.levels()).single.plan.problem, 'marks');

    await store.delete(plan.id);
    expect(await store.level(plan.id), isNull);
    expect(await store.levels(), isEmpty);
  });

  test('only fresh player ids are created', () async {
    final store = repo.builtLevels;
    final plan = sampleLevel(PlayMode.touch, id: 'u-firstlevel');
    await store.create(plan);
    expect(() => store.create(plan), throwsStateError);
    expect(
      () => store.create(plan.copyWith(id: 't-push-1')),
      throwsArgumentError,
    );
  });

  test('the creator clears a revision, and an edit asks again', () async {
    final store = repo.builtLevels;
    final plan = sampleLevel(PlayMode.jump, id: 'u-jumplevel1');
    await store.create(plan);
    await store.markCleared(plan.id, 1);
    expect((await store.level(plan.id))!.cleared, isTrue);
    final edited = await store.save(plan.copyWith(region: WorldRegion.paris));
    expect(edited.revision, 2);
    expect(edited.cleared, isFalse);
    // A clear of an older revision never marks the new one.
    await store.markCleared(plan.id, 1);
    expect((await store.level(plan.id))!.cleared, isFalse);
  });

  test('bests fold per revision and saves are idempotent', () async {
    final store = repo.builtLevels;
    final plan = sampleLevel(PlayMode.pushUp, id: 'u-pushlevel1');
    await store.create(plan);
    final marks = plan.marks;
    await store.saveFlight((
      plan: plan,
      revision: 1,
      run: builtRun(plan, stars: marks.two, repetitions: 8),
    ));
    // A retried save counts once.
    await store.saveFlight((
      plan: plan,
      revision: 1,
      run: builtRun(plan, stars: marks.two, repetitions: 8),
    ));
    await store.saveFlight((
      plan: plan,
      revision: 1,
      run: builtRun(
        plan,
        id: 'run-2',
        stars: marks.three,
        repetitions: 3,
        reason: EndReason.collision,
      ),
    ));
    await store.saveFlight((
      plan: plan,
      revision: 2,
      run: builtRun(plan, id: 'run-3', stars: 1, repetitions: 10),
    ));
    final bests = {for (final best in await store.bests()) best.revision: best};
    expect(bests[1]!.plays, 2);
    // A failed flight earns no stars, however many it collected.
    expect(bests[1]!.stars, 2);
    expect(bests[1]!.collected, marks.three);
    expect(bests[1]!.firstClearedAt, _at);
    expect(bests[2]!.stars, 1);
    expect(await store.workouts(), {PlayMode.pushUp: 21});
    expect(
      () => store.saveFlight((
        plan: plan,
        revision: 1,
        run: builtRun(plan, id: 'run-4', practice: true),
      )),
      throwsArgumentError,
    );
  });

  test('built flights count towards workouts and nothing else', () async {
    final push = sampleLevel(PlayMode.pushUp, id: 'u-pushlevel2');
    final squat = sampleLevel(PlayMode.squat, id: 'u-squatlevel');
    final tap = sampleLevel(PlayMode.touch, id: 'u-taplevel01');
    final store = repo.builtLevels;
    for (final plan in [push, squat, tap]) {
      await store.create(plan);
    }
    await store.saveFlight((
      plan: push,
      revision: 1,
      run: builtRun(push, repetitions: 12, stars: 24),
    ));
    await store.saveFlight((
      plan: squat,
      revision: 1,
      run: builtRun(squat, id: 'run-2', repetitions: 9, stars: 24),
    ));
    await store.saveFlight((
      plan: tap,
      revision: 1,
      run: builtRun(tap, id: 'run-3', flaps: 40, stars: 24),
    ));
    final p = await repo.load();
    expect(p.totalRepetitions, 12);
    expect(p.totalSquats, 9);
    expect(p.starsEarned, 0);
    expect(p.starWallet, 0);
    expect(p.totalRuns, 0);
    expect(p.flightsFlown, 0);
    expect(p.campaignFlights.runs, 0);
    expect(p.today?.completedGoals ?? 0, 0);
    expect(p.recent, isEmpty);
    // A deleted level's workouts still count.
    await store.delete(push.id);
    expect((await repo.load()).totalRepetitions, 12);
    // The campaign's saves never take a built level's flight.
    expect(
      () => repo.saveRun(builtRun(push, id: 'run-9')),
      throwsArgumentError,
    );
  });

  test('a duplicate route is found whatever its name', () async {
    final store = repo.builtLevels;
    final plan = sampleLevel(PlayMode.touch, id: 'u-original01');
    await store.create(plan);
    final copy = plan.copyWith(id: 'u-copyoforig', name: 'Copy');
    expect((await store.sameRoute(copy))?.id, plan.id);
    expect(
      await store.sameRoute(copy.copyWith(region: WorldRegion.mexico)),
      isNull,
    );
  });

  test('a reset forgets every built level and flight', () async {
    final store = repo.builtLevels;
    final plan = sampleLevel(PlayMode.squat, id: 'u-squatlevel');
    await store.create(plan);
    await store.saveFlight((
      plan: plan,
      revision: 1,
      run: builtRun(plan, repetitions: 4),
    ));
    await repo.reset();
    expect(await store.levels(), isEmpty);
    expect(await store.bests(), isEmpty);
    expect((await repo.load()).totalSquats, 0);
  });
}
