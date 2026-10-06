import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/built_draft.dart';
import 'package:push_up_bird/domain/built_level.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/builder/builder_controller.dart';

import 'builder_ui_harness.dart';

/// The level editor (`/builder/edit/<id>`): placing and moving things on
/// the sky, the inspector, undo and redo, the finish line, the list of
/// problems, renaming, test flights, and a starter level that is only to
/// look at, fly and remix.
/// Where this file's captures go.
const _out = 'builder-polish/editor';

void main() {
  setUpAll(loadBuilderFonts);

  BuiltPlan blank(PlayMode mode, {String id = 'u-editlevel1'}) =>
      BuiltDraft.blank(
        id: id,
        name: 'Edit me',
        mode: mode,
        region: WorldRegion.jungle,
      ).plan;

  List<BuiltItem> items(WidgetTester tester) => editorOf(tester).plan.items;

  testWidgets('tapping the sky places a gate and a trio; dragging moves '
      'them; the inspector, undo and redo change them', (tester) async {
    final app = await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-editlevel1',
      levels: [blank(PlayMode.touch)],
    );
    final c = editorOf(tester);
    expect(c.plan.items, isEmpty);
    expect(find.text('This level'), findsOneWidget);
    expect(c.tools, contains(BuilderTool.enemy));

    // A gate where the finger lands, snapped, and selected.
    await tester.tap(find.byKey(const ValueKey('tool-gate')));
    await tester.pump();
    expect(c.tool, BuilderTool.gate);
    await tester.tapAt(skyPoint(tester, 3.0, .5));
    await settle(tester);
    final gate = items(tester).single as BuiltGate;
    expect(gate.x, 3000);
    expect(gate.y, 500);
    expect(c.selection, gate);
    expect(find.text('Gate'), findsWidgets);
    expect(find.text('Garden gate'), findsWidgets);
    // Tapping the gate with the gate tool picks it rather than piling a
    // second one on it.
    await tester.tapAt(skyPoint(tester, 3.05, .2));
    await settle(tester);
    expect(items(tester), hasLength(1));

    // A trio further on.
    await tester.tap(find.byKey(const ValueKey('tool-trio')));
    await tester.pump();
    await tester.tapAt(skyPoint(tester, 3.6, .5));
    await settle(tester);
    expect(items(tester).whereType<BuiltTrio>().single.x, 3600);
    expect(find.text('Star trio'), findsOneWidget);
    expect(c.plan.totalStars, 3);

    // Dragging the selected trio moves it, snapped, as one undo step.
    final h = tester
        .getRect(find.byKey(const ValueKey('builder-canvas')))
        .height;
    await tester.dragFrom(skyPoint(tester, 3.6, .5), Offset(-.4 * h, -.2 * h));
    await settle(tester);
    final trio = items(tester).whereType<BuiltTrio>().single;
    expect(trio.x, 3200);
    expect(trio.y, 300);
    c.undo();
    await tester.pump();
    expect(items(tester).whereType<BuiltTrio>().single.x, 3600);
    c.redo();
    await tester.pump();
    expect(items(tester).whereType<BuiltTrio>().single.x, 3200);

    // Dragging empty sky pans along the route.
    final before = c.scroll;
    await tester.dragFrom(skyPoint(tester, 2.5, .9), Offset(-.5 * h, 0));
    await settle(tester);
    expect(c.scroll, closeTo(before + .5, .02));
    c.scrollTo(before);
    await tester.pump();

    // Select picks the gate; the inspector opens it wider and moves it.
    await tester.tap(find.byKey(const ValueKey('tool-select')));
    await tester.tapAt(skyPoint(tester, 3.07, .2));
    await settle(tester);
    expect(c.selection, isA<BuiltGate>());
    await snap(tester, 'editor-gate-selected', folder: _out);
    await tester.tap(find.byKey(const ValueKey('opening-more')));
    await tester.pump();
    expect((c.selection! as BuiltGate).gap, 420);
    await tester.tap(find.byKey(const ValueKey('height-more')));
    await tester.pump();
    expect((c.selection! as BuiltGate).y, 475);
    // A garden gate stands still: the moving choices only explain.
    await tester.ensureVisible(find.text('Lively'));
    await settle(tester);
    await tester.tap(find.text('Lively'));
    await tester.pump();
    expect((c.selection! as BuiltGate).amp, 0);
    expect(find.byKey(const ValueKey('builder-toast')), findsOneWidget);
    // Another family moves; its opening grows to what the bird needs.
    await tester.ensureVisible(find.byKey(const ValueKey('gate-family')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('gate-family')));
    await settle(tester);
    await snap(tester, 'family-sheet', folder: _out);
    await tester.tap(find.byKey(const ValueKey('family-windLift')));
    await settle(tester);
    var picked = c.selection! as BuiltGate;
    expect(picked.kind, ObstacleKind.windLift);
    expect(picked.amp, greaterThan(0));
    expect(
      picked.gap,
      greaterThanOrEqualTo(
        BuiltPlan.safeGap(PlayMode.touch, picked.y, picked.amp),
      ),
    );
    await tester.ensureVisible(find.text('Lively'));
    await settle(tester);
    await tester.tap(find.text('Lively'));
    await tester.pump();
    picked = c.selection! as BuiltGate;
    expect(picked.amp, BuiltPlan.maxAmp(PlayMode.touch));
    expect(
      picked.gap,
      greaterThanOrEqualTo(BuiltPlan.safeGap(PlayMode.touch, picked.y, 100)),
    );
    expect(c.plan.problem, isNull);

    // Delete, undo and redo.
    await tester.tap(find.byKey(const ValueKey('inspector-delete')));
    await settle(tester);
    expect(items(tester).whereType<BuiltGate>(), isEmpty);
    expect(c.selection, isNull);
    await tester.tap(find.byKey(const ValueKey('editor-undo')));
    await settle(tester);
    expect(items(tester).whereType<BuiltGate>(), hasLength(1));
    await tester.tap(find.byKey(const ValueKey('editor-redo')));
    await settle(tester);
    expect(items(tester).whereType<BuiltGate>(), isEmpty);
    await tester.tap(find.byKey(const ValueKey('editor-undo')));
    await settle(tester);

    // Leaving saves.
    await tester.tap(find.byTooltip('Back to the builder'));
    await settle(tester);
    expect(app.uri.path, '/builder');
    final saved = (await app.store.level('u-editlevel1'))!.plan;
    expect(saved.gates, hasLength(1));
    expect(saved.items.whereType<BuiltTrio>().single.x, 3200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the finish tool moves the line; problems are listed and lead '
      'to their place; renaming keeps a name', (tester) async {
    final app = await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-editlevel1',
      levels: [blank(PlayMode.touch)],
    );
    final c = editorOf(tester);
    await snap(tester, 'editor-blank', folder: _out);
    // A blank level cannot fly: it has no stars.
    expect(c.flyable, isFalse);
    final issuesKey = find.byKey(const ValueKey('editor-issues'));
    expect(
      find.descendant(of: issuesKey, matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tool-finish')));
    await tester.tapAt(skyPoint(tester, 3.5, .5));
    await settle(tester);
    expect(c.plan.finish, 3500);
    // The line never goes into the start zone.
    await tester.tapAt(skyPoint(tester, 2.0, .5));
    await settle(tester);
    expect(c.plan.finish, BuiltPlan.firstX + BuiltPlan.unit);
    c.setFinish(8.0);
    await tester.pump();

    // A star past the line is a problem, flagged where it is.
    await tester.tap(find.byKey(const ValueKey('tool-star')));
    await tester.tapAt(skyPoint(tester, 3.0, .5));
    c.scrollTo(7.5);
    await tester.pump();
    await tester.tapAt(skyPoint(tester, 8.5, .5));
    await settle(tester);
    expect(c.plan.totalStars, 2);
    final blocking = c.issues.where((i) => i.blocking).toList();
    expect(blocking.single.message, 'Place it before the finish line.');
    c.scrollTo(2);
    c.select(null);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editor-issues')));
    await settle(tester);
    expect(find.text('To fix before it flies'), findsOneWidget);
    expect(find.text('Place it before the finish line.'), findsOneWidget);
    await snap(tester, 'editor-issues', folder: _out);
    await tester.tap(find.text('Place it before the finish line.'));
    await settle(tester);
    expect(c.tool, BuilderTool.select);
    expect(c.selection, isA<BuiltStar>());
    expect(c.selection!.x, 8500);
    expect(c.scroll, lessThan(8.5));
    expect(c.scroll + 2.1, greaterThan(8.5));
    // Sharing waits until it can fly.
    await tester.tap(find.byKey(const ValueKey('editor-share')));
    await tester.pump();
    expect(find.byKey(const ValueKey('builder-toast')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('inspector-delete')));
    await settle(tester);
    // Only advice is left (no gates yet): it flies.
    expect(c.flyable, isTrue);
    expect(c.issues.single.message, 'Add gates for the bird to fly through.');
    expect(
      find.descendant(of: issuesKey, matching: find.text('1')),
      findsOneWidget,
    );

    // Rename: a compact field over the top of the screen.
    await tester.tap(find.byKey(const ValueKey('editor-name')));
    await settle(tester);
    expect(find.byKey(const ValueKey('name-field')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('name-field')), '   ');
    await tester.pump();
    expect(find.text('A name needs a letter or two'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('name-field')),
      '  Sky Hop  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('name-save')));
    await settle(tester);
    expect(c.plan.name, 'Sky Hop');
    expect(find.text('Sky Hop'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to the builder'));
    await settle(tester);
    expect((await app.store.level('u-editlevel1'))!.plan.name, 'Sky Hop');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test fly saves and flies the creator’s test, from the start '
      'or from the view', (tester) async {
    final level = builtLevel(PlayMode.touch, id: 'u-testflight');
    final app = await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-testflight',
      levels: [level],
    );
    final c = editorOf(tester);
    // An edit not yet saved is saved before the flight.
    c.pick(BuilderTool.heart);
    await tester.tapAt(skyPoint(tester, 3.4, .5));
    await tester.pump();
    expect(c.unsaved, isTrue);
    await tester.tap(find.byKey(const ValueKey('editor-fly')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(app.uri.path, '/play/touch');
    expect(app.uri.queryParameters, {'built': 'u-testflight', 'test': '1'});
    final saved = (await app.store.level('u-testflight'))!.plan;
    expect(saved.items.whereType<BuiltHeart>(), hasLength(2));
    appRouter.go('/builder/edit/u-testflight?at=5000');
    await settle(tester);
    // A test flight comes back to where it got to.
    final back = editorOf(tester);
    expect(back.scroll, lessThan(5));
    expect(back.scroll + 2.1, greaterThan(5));
    back.scrollTo(6);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editor-from-here')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(app.uri.path, '/play/touch');
    expect(app.uri.queryParameters, {
      'built': 'u-testflight',
      'test': '1',
      'from': '6000',
    });
    appRouter.go('/builder');
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a push-up level places gates on its two lanes and has no '
      'enemies', (tester) async {
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-pushlevel1',
      levels: [blank(PlayMode.pushUp, id: 'u-pushlevel1')],
    );
    final c = editorOf(tester);
    expect(c.tools, isNot(contains(BuilderTool.enemy)));
    expect(find.byKey(const ValueKey('tool-enemy')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tool-gate')));
    await tester.tapAt(skyPoint(tester, 3.0, .4));
    await settle(tester);
    expect((c.selection! as BuiltGate).y, BuiltPlan.highLane);
    expect(find.text('Lane'.toUpperCase()), findsOneWidget);
    await tester.tap(find.text('Bottom'));
    await tester.pump();
    expect((c.selection! as BuiltGate).y, BuiltPlan.lowLane);
    // Dragging the gate up moves it to the other lane.
    final h = tester
        .getRect(find.byKey(const ValueKey('builder-canvas')))
        .height;
    await tester.dragFrom(skyPoint(tester, 3.07, .5), Offset(0, -.35 * h));
    await settle(tester);
    expect((c.selection! as BuiltGate).y, BuiltPlan.highLane);
    await snap(tester, 'editor-push', folder: _out);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a starter level is only to look at, fly and remix', (
    tester,
  ) async {
    final app = await pumpBuilderApp(tester, at: '/builder/edit/t-tap-1');
    final c = editorOf(tester);
    expect(c.readOnly, isTrue);
    expect(find.byKey(const ValueKey('starter-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-undo')), findsNothing);
    final before = c.plan.items.length;
    await tester.tap(find.byKey(const ValueKey('tool-gate')));
    await tester.tapAt(skyPoint(tester, c.scroll + 1, .5));
    await settle(tester);
    expect(c.plan.items, hasLength(before));
    await snap(tester, 'editor-template', folder: _out);
    // Fly is a real flight of the starter level.
    await tester.tap(find.byKey(const ValueKey('editor-fly')));
    await tester.pump();
    await tester.pump();
    expect(app.uri.path, '/play/touch');
    expect(app.uri.queryParameters, {'built': 't-tap-1'});
    appRouter.go('/builder/edit/t-tap-1');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('banner-remix')));
    await settle(tester);
    final remix = (await app.store.levels()).single;
    expect(remix.origin, BuiltOrigin.remixed);
    expect(remix.from, 't-tap-1');
    expect(app.uri.path, '/builder/edit/${remix.id}');
    expect(editorOf(tester).readOnly, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level that cannot be found goes back to the builder', (
    tester,
  ) async {
    final app = await pumpBuilderApp(tester, at: '/builder/edit/u-nosuchlevl');
    expect(app.uri.path, '/builder');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the settings sheet changes the level as it goes, and a boss '
      'finale replaces the line', (tester) async {
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-settings01',
      levels: [builtLevel(PlayMode.touch, id: 'u-settings01')],
    );
    final c = editorOf(tester);
    await tester.tap(find.byTooltip('Level settings'));
    await settle(tester);
    expect(find.byKey(const ValueKey('settings-sheet')), findsOneWidget);
    await snap(tester, 'editor-settings', folder: _out);
    await tester.tap(find.text('Brisk'));
    await tester.pump();
    expect(c.plan.pace, BuiltPace.brisk);
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-region-egypt')),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('settings-region-egypt')));
    await tester.pump();
    expect(c.plan.region, WorldRegion.egypt);
    // Marks by hand, then back to following the stars.
    expect(c.draft.autoMarks, isTrue);
    await tester.tap(find.byKey(const ValueKey('three-star mark-less')));
    await tester.pump();
    expect(c.draft.autoMarks, isFalse);
    expect(c.plan.marks.three, BuiltPlan.suggestMarks(18).three - 1);
    await tester.tap(find.text('Auto: follow the stars'));
    await tester.pump();
    expect(c.draft.autoMarks, isTrue);
    await tester.tap(find.byKey(const ValueKey('settings-shoot')));
    await tester.pump();
    expect(c.plan.shoot, isFalse);
    await tester.tap(find.byKey(const ValueKey('settings-boss-dragon')));
    await tester.pump();
    expect(c.plan.boss, BossKind.dragon);
    expect(c.plan.problem, isNull);
    await tester.tap(find.byTooltip('Close settings'));
    await settle(tester);
    // The finish tool is the boss's mark now.
    expect(find.text('Boss'), findsWidgets);
    c.scrollTo(c.plan.finishX - 1.4);
    await tester.pump();
    await snap(tester, 'editor-boss', folder: _out);
    c.undo();
    await tester.pump();
    expect(c.plan.boss, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty level opens with the gate in hand and first steps; '
      'a press shows what lands; the start zone refuses; a drag shows its '
      'ghost and snap lines', (tester) async {
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-firstrun01',
      size: const Size(792, 360),
      reduced: false,
      levels: [blank(PlayMode.touch, id: 'u-firstrun01')],
    );
    final c = editorOf(tester);
    expect(c.tool, BuilderTool.gate);
    expect(find.byKey(const ValueKey('editor-coach')), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-tip')), findsNothing);
    await snap(tester, 'first-run-coach', folder: _out);

    // A held press shows the gate where it will land, snapped.
    final press = await tester.startGesture(skyPoint(tester, 3.0, .42));
    await tester.pump(const Duration(milliseconds: 160));
    await snap(tester, 'press-preview', folder: _out);
    await press.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    await snap(tester, 'place-pop', folder: _out);
    await settle(tester);
    final gate = c.plan.items.single as BuiltGate;
    expect(gate.x, 3000);
    expect(c.selection, gate);
    expect(find.byKey(const ValueKey('editor-coach')), findsNothing);
    expect(find.byKey(const ValueKey('editor-tip')), findsOneWidget);

    // Nothing lands in the start zone: it says why.
    await tester.tap(find.byKey(const ValueKey('tool-star')));
    await tester.pump();
    final early = await tester.startGesture(skyPoint(tester, 2.0, .5));
    await tester.pump(const Duration(milliseconds: 160));
    await snap(tester, 'press-blocked', folder: _out);
    await early.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(c.plan.items, hasLength(1));
    expect(find.byKey(const ValueKey('builder-toast')), findsOneWidget);
    await snap(tester, 'start-refused', folder: _out);
    await settle(tester);
    // A trio tapped just past the line is set down clear of it.
    await tester.tap(find.byKey(const ValueKey('tool-trio')));
    await tester.pump();
    await tester.tapAt(skyPoint(tester, 2.45, .5));
    await settle(tester);
    final trio = c.plan.items.whereType<BuiltTrio>().single;
    expect(trio.left, greaterThanOrEqualTo(BuiltPlan.firstX));
    expect(c.issues.where((i) => i.blocking), isEmpty);

    // Dragging the selected trio: a ghost where it was, lines it snaps to.
    final h = tester
        .getRect(find.byKey(const ValueKey('builder-canvas')))
        .height;
    final drag = await tester.startGesture(skyPoint(tester, 2.6, .5));
    await drag.moveBy(Offset(.12 * h, 0));
    await tester.pump();
    await drag.moveBy(Offset(.2 * h, -.18 * h));
    await tester.pump();
    await snap(tester, 'drag-guides', folder: _out);
    await drag.up();
    await settle(tester);
    expect(c.plan.items.whereType<BuiltTrio>().single.x, greaterThan(2600));

    // With a third thing placed the tip goes; the strip and the sky go on
    // along the route.
    await tester.tap(find.byKey(const ValueKey('tool-heart')));
    await tester.pump();
    await tester.tapAt(skyPoint(tester, 3.6, .7));
    await settle(tester);
    expect(c.plan.items, hasLength(3));
    expect(find.byKey(const ValueKey('editor-tip')), findsNothing);
    expect(find.byKey(const ValueKey('builder-scenery')), findsOneWidget);
    c.scrollTo(6);
    await tester.pump();
    await snap(tester, 'scrolled', folder: _out);
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in const [
    ('792', Size(792, 360)),
    ('915', Size(915, 412)),
  ]) {
    testWidgets('a level with things on it, as a $name phone shows it', (
      tester,
    ) async {
      await pumpBuilderApp(
        tester,
        at: '/builder/edit/u-phonelvl01?at=3600',
        size: size,
        reduced: false,
        levels: [builtLevel(PlayMode.touch, id: 'u-phonelvl01')],
      );
      final c = editorOf(tester);
      expect(c.tool, BuilderTool.select);
      expect(find.byKey(const ValueKey('editor-coach')), findsNothing);
      await tester.tapAt(skyPoint(tester, 3.05, .2));
      await settle(tester);
      expect(c.selection, isA<BuiltGate>());
      await snap(tester, 'editor-$name', folder: _out);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large system text still fits the editor', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-bigtext001',
      size: const Size(792, 360),
      levels: [blank(PlayMode.squat, id: 'u-bigtext001')],
    );
    expect(find.byKey(const ValueKey('editor-coach')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await snap(tester, 'editor-large-text-coach', folder: _out);
    await tester.tapAt(skyPoint(tester, 3.0, .7));
    await settle(tester);
    expect(editorOf(tester).selection, isA<BuiltGate>());
    expect(tester.takeException(), isNull);
    await snap(tester, 'editor-large-text', folder: _out);
  });
}
