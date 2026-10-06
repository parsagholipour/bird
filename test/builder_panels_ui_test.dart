import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/built_draft.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/builder/builder_chrome.dart';
import 'package:push_up_bird/ui/builder/builder_inspector.dart';

import 'builder_ui_harness.dart';

/// Saves the screen to `build/visual-review/builder-polish/panels/` when
/// run with `--dart-define=CAPTURE_VISUALS=true`.
Future<void> shot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/builder-polish/panels/$name.png')
      ..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// The inspector's scrolling body.
Finder inspectorScroll() => find
    .descendant(
      of: find.byType(BuilderInspector),
      matching: find.byType(Scrollable),
    )
    .first;

/// Selects the first item [where] holds and scrolls the view to it.
DraftItem selectWhere(WidgetTester tester, bool Function(BuiltItem) where) {
  final c = editorOf(tester);
  final entry = c.draft.items.firstWhere((e) => where(e.item));
  c.scrollTo(entry.item.x / BuiltPlan.unit - .8);
  c.select(entry.key);
  return entry;
}

/// Whether the panel's "More below" tag shows.
bool moreBelow(WidgetTester tester) =>
    tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(const ValueKey('inspector-more')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity ==
    1;

/// Every key in the inspector is at least 48 units each way.
void expectBigKeys(WidgetTester tester) {
  final keys = find.descendant(
    of: find.byType(BuilderInspector),
    matching: find.byType(BuilderKey),
  );
  expect(keys, findsWidgets);
  for (final element in keys.evaluate()) {
    final size = (element.renderObject! as RenderBox).size;
    expect(size.width, greaterThanOrEqualTo(48), reason: '${element.widget}');
    expect(size.height, greaterThanOrEqualTo(48), reason: '${element.widget}');
  }
}

void main() {
  setUpAll(loadBuilderFonts);

  testWidgets('a moving gate\'s panel names its family at the top, steps '
      'each value in plain units and shows when there is more below', (
    tester,
  ) async {
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-panelslvl1',
      size: const Size(792, 360),
      levels: [
        builtLevel(PlayMode.touch, id: 'u-panelslvl1', name: 'Canopy Dash'),
      ],
    );
    await shot(tester, 'summary-792');
    final c = editorOf(tester);
    final entry = selectWhere(tester, (i) => i is BuiltGate && i.moving);
    await settle(tester);
    BuiltGate gate() => c.draft[entry.key]! as BuiltGate;
    expect(find.text('Wind lift'), findsWidgets);
    expect(find.text('Change family'), findsOneWidget);
    expect(find.text('of the sky'), findsOneWidget);
    expect(find.textContaining('at least '), findsOneWidget);
    expect(moreBelow(tester), isTrue);
    expectBigKeys(tester);
    await shot(tester, 'gate-moving-792');

    // The family changes from the header.
    await tester.tap(find.byKey(const ValueKey('gate-family')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('family-petalGate')));
    await settle(tester);
    expect(gate().kind, ObstacleKind.petalGate);
    expect(find.text(ObstacleKind.petalGate.title), findsWidgets);

    // The rest is a scroll away; at the end the tag goes.
    await tester.drag(inspectorScroll(), const Offset(0, -600));
    await settle(tester);
    expect(moreBelow(tester), isFalse);
    await shot(tester, 'gate-moving-792-end');
    expect(find.textContaining('one sway: '), findsOneWidget);
    await tester.ensureVisible(find.text('Slow'));
    await settle(tester);
    await tester.tap(find.text('Slow'));
    await tester.pump();
    expect(gate().cycle, 4000);
    final phase = gate().phase;
    await tester.ensureVisible(find.byKey(const ValueKey('phase-more')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('phase-more')));
    await tester.pump();
    expect(gate().phase, (phase + 45) % 360);
    await tester.ensureVisible(find.byKey(const ValueKey('gate-look-2')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('gate-look-2')));
    await tester.pump();
    expect(gate().look, 2);
    final x = gate().x;
    await tester.ensureVisible(find.byKey(const ValueKey('place-more')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('place-more')));
    await tester.pump();
    expect(gate().x, x + 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a garden gate, an enemy and a push-up gate', (tester) async {
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-panelslvl1',
      size: const Size(792, 360),
      levels: [
        builtLevel(PlayMode.touch, id: 'u-panelslvl1', name: 'Canopy Dash'),
        builtLevel(PlayMode.pushUp, id: 'u-panelslvl2', name: 'Ten Dips'),
      ],
    );
    selectWhere(tester, (i) => i is BuiltGate && !i.moving);
    await settle(tester);
    expect(find.text('garden gates stand still'), findsOneWidget);
    await shot(tester, 'gate-garden-792');
    await tester.drag(inspectorScroll(), const Offset(0, -600));
    await settle(tester);
    expect(find.text('Stone door'), findsWidgets);
    expect(find.text('No door'), findsOneWidget);
    expectBigKeys(tester);

    final enemy = selectWhere(tester, (i) => i is BuiltEnemy);
    await settle(tester);
    expect(moreBelow(tester), isFalse);
    expectBigKeys(tester);
    await shot(tester, 'enemy-792');
    await tester.tap(find.byKey(const ValueKey('enemy-duskMoth')));
    await tester.pump();
    expect(
      (editorOf(tester).draft[enemy.key]! as BuiltEnemy).kind,
      EnemyKind.duskMoth,
    );

    selectWhere(tester, (i) => i is BuiltTrio);
    await settle(tester);
    expect(find.text('Star trio'), findsOneWidget);
    await shot(tester, 'trio-792');

    appRouter.go('/builder/edit/u-panelslvl2');
    await settle(tester);
    selectWhere(tester, (i) => i is BuiltGate);
    await settle(tester);
    expect(find.text('top or bottom of the push-up'), findsOneWidget);
    expect(find.text('HEIGHT'), findsNothing);
    expectBigKeys(tester);
    await shot(tester, 'gate-push-792');
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings open with the level\'s region in view and show '
      'there are more places', (tester) async {
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-panelslvl2',
      size: const Size(792, 360),
      levels: [
        builtLevel(
          PlayMode.pushUp,
          id: 'u-panelslvl2',
          name: 'Ten Dips',
          region: WorldRegion.rome,
        ),
      ],
    );
    await tester.tap(find.byTooltip('Level settings'));
    await settle(tester);
    expect(
      find.text('${WorldRegion.values.length} places · swipe for more'),
      findsOneWidget,
    );
    final strip = tester.getRect(
      find
          .ancestor(
            of: find.byKey(const ValueKey('settings-region-rome')),
            matching: find.byType(ListView),
          )
          .first,
    );
    final rome = tester.getRect(
      find.byKey(const ValueKey('settings-region-rome')),
    );
    expect(rome.left, greaterThanOrEqualTo(strip.left));
    expect(rome.right, lessThanOrEqualTo(strip.right));
    await shot(tester, 'settings-push-792');
    await tester.tap(find.byKey(const ValueKey('settings-rename')));
    await settle(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 360 * .58);
    await settle(tester);
    await shot(tester, 'rename-792');
    tester.view.resetViewInsets();
    await tester.tap(find.byKey(const ValueKey('name-cancel')));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the panels fit a 20:9 phone with a cutout', (tester) async {
    await pumpBuilderApp(
      tester,
      at: '/builder/edit/u-panelslvl1',
      size: const Size(915, 412),
      dpr: 2.625,
      insets: const EdgeInsets.only(left: 52, right: 24, bottom: 21),
      levels: [
        builtLevel(
          PlayMode.touch,
          id: 'u-panelslvl1',
          name: 'Canopy Dash',
          region: WorldRegion.egypt,
        ),
      ],
    );
    selectWhere(tester, (i) => i is BuiltGate && i.moving);
    await settle(tester);
    expectBigKeys(tester);
    await shot(tester, 'gate-moving-915');
    editorOf(tester).select(null);
    await tester.tap(find.byTooltip('Level settings'));
    await settle(tester);
    await shot(tester, 'settings-touch-915');
    expect(tester.takeException(), isNull);
  });
}
