import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/built_draft.dart';
import 'package:push_up_bird/domain/built_level.dart';
import 'package:push_up_bird/domain/built_reach.dart';
import 'package:push_up_bird/domain/built_templates.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/ui/builder/builder_controller.dart';

import 'built_pilot.dart';

void main() {
  group('BuiltDraft', () {
    test('places, moves, duplicates and removes under stable keys', () {
      var draft = BuiltDraft.blank(
        id: 'u-draftlevel',
        name: 'Draft',
        mode: PlayMode.touch,
        region: WorldRegion.brazil,
      );
      expect(draft.plan.items, isEmpty);
      expect(draft.plan.finish, BuiltDraft.blankFinish);
      final (withGate, gate) = draft.place(
        BuiltDraft.gateAt(PlayMode.touch, 4.013, .512),
      );
      draft = withGate;
      expect(draft[gate], isA<BuiltGate>());
      expect(draft[gate]!.x, 4000);
      expect(draft[gate]!.y, 500);
      final (withStar, star) = draft.place(const BuiltStar(x: 3600, y: 500));
      draft = withStar;
      // Keys hold while items are replaced and re-sorted.
      draft = draft.update(star, draft.moved(draft[star]!, 5.24, .31));
      expect(draft[star]!.x, 5250);
      expect(draft[star]!.y, 300);
      expect(draft.plan.items.map((i) => i.tag), ['g', 's']);
      final (copied, copy) = draft.duplicate(gate)!;
      expect(copied[copy]!.x, 4000 + 140 + 400);
      draft = copied.remove(gate);
      expect(draft[gate], isNull);
      expect(draft.plan.gates.single.x, 4540);
    });

    test('push-up gates snap to lanes, free gates to the sky', () {
      expect(BuiltDraft.gateAt(PlayMode.pushUp, 3, .1).y, BuiltPlan.highLane);
      expect(BuiltDraft.gateAt(PlayMode.squat, 3, .6).y, BuiltPlan.lowLane);
      expect(BuiltDraft.gateAt(PlayMode.jump, 3, .02).y, BuiltPlan.minGateY);
      expect(BuiltDraft.gateAt(PlayMode.touch, 3, .99).y, BuiltPlan.maxGateY);
      expect(BuiltDraft.snapY(-1), 50);
      expect(BuiltDraft.snapY(2), 950);
    });

    test('marks follow the stars until they are set by hand', () {
      final plan = sampleLevel(PlayMode.touch);
      var draft = BuiltDraft.of(plan);
      expect(draft.autoMarks, isTrue);
      final (more, _) = draft.place(const BuiltTrio(x: 9500, y: 500));
      expect(more.plan.marks.three, BuiltPlan.suggestMarks(27).three);
      draft = more.withSettings(marks: const StarMarks(5, 6));
      expect(draft.autoMarks, isFalse);
      expect(draft.plan.marks.two, 5);
      draft = draft.withSettings(autoMarks: true);
      expect(draft.plan.marks.two, BuiltPlan.suggestMarks(27).two);
    });

    test('turning Shoot off takes the stone doors away', () {
      final plan = sampleLevel(PlayMode.touch).copyWith(
        items: [
          ...sampleLevel(PlayMode.touch).items,
          const BuiltGate(x: 3500, y: 500, gap: 400, door: true),
        ],
      );
      final draft = BuiltDraft.of(plan).withSettings(shoot: false);
      expect(draft.plan.gates.any((g) => g.door), isFalse);
      expect(draft.plan.problem, isNull);
    });

    test('hits gates by their column and the rest by distance', () {
      var draft = BuiltDraft.of(sampleLevel(PlayMode.touch, gates: 2));
      final (withStar, star) = draft.place(const BuiltStar(x: 5000, y: 200));
      draft = withStar;
      final gate = draft.items.firstWhere((e) => e.item is BuiltGate).key;
      expect(draft.hit(3.07, .05), gate);
      expect(draft.hit(5.03, .22), star);
      expect(draft.hit(5.5, .9), isNull);
    });
  });

  group('BuiltReach', () {
    test('blocking issues are exactly what stops a plan', () {
      final random = math.Random(7);
      var blocked = 0;
      for (var round = 0; round < 400; round++) {
        final mode = PlayMode.values[random.nextInt(4)];
        var draft = BuiltDraft.blank(
          id: 'u-fuzzlevel1',
          name: 'Fuzz',
          mode: mode,
          region: WorldRegion.egypt,
        );
        for (var i = 0; i < random.nextInt(12); i++) {
          final x = 1.5 + random.nextDouble() * 12, y = random.nextDouble();
          final BuiltItem item = switch (random.nextInt(6)) {
            0 || 1 => BuiltDraft.gateAt(mode, x, y),
            2 => BuiltStar(x: BuiltDraft.snapX(x), y: BuiltDraft.snapY(y)),
            3 => BuiltTrio(x: BuiltDraft.snapX(x), y: BuiltDraft.snapY(y)),
            4 => BuiltHeart(x: BuiltDraft.snapX(x), y: BuiltDraft.snapY(y)),
            _ => BuiltEnemy(
              x: BuiltDraft.snapX(x),
              y: BuiltDraft.snapY(y),
              kind: EnemyKind.caveBat,
            ),
          };
          draft = draft.place(item).$1;
        }
        final plan = draft.plan;
        final issues = BuiltReach.check(plan);
        final blocking = issues.where((i) => i.blocking).toList();
        expect(blocking.isEmpty, plan.problem == null, reason: '$issues');
        // The fallback never has to speak for the plan's own check.
        expect(
          issues.any((i) => i.message.startsWith('This level cannot fly')),
          isFalse,
          reason: '${plan.problem} $issues',
        );
        if (blocking.isNotEmpty) blocked++;
      }
      expect(blocked, greaterThan(50));
    });

    test('every template is clean and counts its workout', () {
      for (final level in BuiltTemplates.all) {
        final issues = BuiltReach.check(level.plan);
        expect(issues.where((i) => i.blocking), isEmpty, reason: level.id);
      }
      expect(BuiltReach.reps(BuiltTemplates.byId('t-push-1')!.plan), 10);
      expect(BuiltReach.reps(BuiltTemplates.byId('t-squat-1')!.plan), 5);
      expect(BuiltReach.reps(BuiltTemplates.byId('t-tap-1')!.plan), isNull);
      final push = BuiltTemplates.byId('t-push-1')!.plan;
      expect(BuiltReach.cruise(push), closeTo(.27, 1e-12));
      expect(
        BuiltReach.seconds(push),
        closeTo((push.finishX - FlightSimulation.birdX) / .27, 1e-9),
      );
    });

    test('advice names a tight lane switch and a star in a wall', () {
      final tight = BuiltPlan(
        id: 'u-tightlevel',
        name: 'Tight',
        mode: PlayMode.pushUp,
        region: WorldRegion.china,
        finish: 8000,
        marks: const StarMarks(1, 1),
        items: const [
          BuiltGate(x: 3000, y: 250, gap: 440),
          BuiltGate(x: 3400, y: 750, gap: 440),
          BuiltStar(x: 3050, y: 800),
        ],
      );
      expect(tight.problem, isNull);
      final advice = BuiltReach.check(tight).map((i) => i.message).join('|');
      expect(advice, contains('Tight switch'));
      expect(advice, contains('Inside a wall'));
    });
  });

  group('BuilderController', () {
    late SqliteProgressRepository repo;
    setUp(
      () => repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      ),
    );
    tearDown(() => repo.close());

    test('edits are undone and redone, and saved', () async {
      final plan = BuiltDraft.blank(
        id: 'u-editlevel1',
        name: 'Edit',
        mode: PlayMode.squat,
        region: WorldRegion.rome,
      ).plan;
      final level = await repo.builtLevels.create(plan);
      final c = BuilderController(
        level: level,
        store: repo.builtLevels,
        autosave: Duration.zero,
      );
      addTearDown(c.dispose);
      expect(c.tools, isNot(contains(BuilderTool.enemy)));
      c.pick(BuilderTool.gate);
      final gate = c.tapAt(3.5, .8)!;
      expect(c.selection, isA<BuiltGate>());
      expect(c.selection!.y, BuiltPlan.lowLane);
      c.pick(BuilderTool.trio);
      c.tapAt(3.2, .85);
      expect(c.plan.totalStars, 3);
      // A drag is a single step.
      c.beginDrag(gate);
      c.dragTo(3.7, .2);
      c.dragTo(3.9, .2);
      c.endDrag();
      expect(c.draft[gate]!.x, 3900);
      expect(c.draft[gate]!.y, BuiltPlan.highLane);
      c.undo();
      expect(c.draft[gate]!.x, 3500);
      c.redo();
      expect(c.draft[gate]!.x, 3900);
      c.undo();
      c.undo();
      expect(c.plan.totalStars, 0);
      await c.flush();
      final saved = await repo.builtLevels.level(level.id);
      expect(saved!.plan.toJson(), c.plan.toJson());
      expect(saved.revision, 2);
      // Select finds what is under the finger.
      c.pick(BuilderTool.select);
      expect(c.tapAt(3.55, .1), gate);
      c.deleteSelected();
      expect(c.plan.items, isEmpty);
      expect(c.flyable, isFalse);
      c.pick(BuilderTool.finish);
      c.tapAt(1, .5);
      expect(c.plan.finish, BuiltPlan.firstX + BuiltPlan.unit);
    });

    test('a template is read-only', () async {
      final c = BuilderController(
        level: BuiltTemplates.byId('t-tap-1')!,
        store: repo.builtLevels,
      );
      addTearDown(c.dispose);
      expect(c.readOnly, isTrue);
      final before = c.plan.toJson();
      c.pick(BuilderTool.star);
      c.tapAt(5, .5);
      c.settings(name: 'Mine');
      expect(c.plan.toJson(), before);
      expect(c.canUndo, isFalse);
      expect(c.flyable, isTrue);
      expect(await repo.builtLevels.levels(), isEmpty);
    });

    test(
      'a level the creator flew is cleared until its route changes',
      () async {
        final plan = sampleLevel(PlayMode.jump, id: 'u-clearlevel');
        final level = await repo.builtLevels.create(plan);
        await repo.builtLevels.markCleared(level.id, level.revision);
        final c = BuilderController(
          level: (await repo.builtLevels.level(level.id))!,
          store: repo.builtLevels,
          autosave: Duration.zero,
        );
        addTearDown(c.dispose);
        expect(c.level.cleared, isTrue);
        c.settings(name: 'Renamed');
        await c.flush();
        expect(c.level.cleared, isTrue);
        c.pick(BuilderTool.heart);
        c.tapAt(4.4, .5);
        await c.flush();
        expect(c.level.cleared, isFalse);
        expect(c.level.revision, 2);
        expect(c.level, isA<BuiltLevel>());
      },
    );
  });
}
