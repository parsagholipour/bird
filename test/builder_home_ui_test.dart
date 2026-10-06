import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart'
    show builderUnlockFlights;
import 'package:push_up_bird/domain/built_code.dart';
import 'package:push_up_bird/domain/built_level.dart';
import 'package:push_up_bird/domain/built_templates.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/main.dart';

import 'builder_ui_harness.dart';

/// The Level Builder's shelf (`/builder`): the way in from Home, the
/// starter levels, a new level, remixes, sharing and pasting codes, and
/// deleting a level.
void main() {
  setUpAll(loadBuilderFonts);

  testWidgets('Home’s Level Builder key opens the builder, which lists the '
      'starter levels and invites a first level', (tester) async {
    // Home's key opens once the first flights are flown.
    final app = await pumpBuilderApp(
      tester,
      at: '/',
      flown: builderUnlockFlights,
    );
    final key = find.byKey(const ValueKey('level-builder'));
    expect(key, findsOneWidget);
    expect(find.text('LEVEL BUILDER'), findsOneWidget);
    // Mini games keeps its own half of the row.
    expect(find.byKey(const ValueKey('mini-games')), findsOneWidget);
    await tester.tap(key);
    await settle(tester);
    expect(app.uri.path, '/builder');
    expect(find.text('Level Builder'), findsOneWidget);
    for (final template in BuiltTemplates.all) {
      expect(
        find.byKey(ValueKey('starter-${template.id}')),
        findsOneWidget,
        reason: template.id,
      );
      expect(find.text(template.plan.name), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('empty-shelf')), findsOneWidget);
    expect(find.text('Build your first level'), findsOneWidget);
    await snap(tester, 'shelf-empty');
    // Back goes Home.
    await tester.tap(find.byTooltip('Back home'));
    await settle(tester);
    expect(app.uri.path, '/');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new level is a mode, then a region, and opens in the editor', (
    tester,
  ) async {
    final app = await pumpBuilderApp(tester);
    await tester.tap(find.byKey(const ValueKey('new-level')));
    await settle(tester);
    expect(find.text('What will it be?'), findsOneWidget);
    for (final mode in PlayMode.values) {
      expect(find.byKey(ValueKey('new-mode-${mode.name}')), findsOneWidget);
    }
    await snap(tester, 'new-mode');
    await tester.tap(find.byKey(const ValueKey('new-mode-pushUp')));
    await settle(tester);
    expect(find.text('Where does it fly?'), findsOneWidget);
    for (final region in WorldRegion.values) {
      expect(find.byKey(ValueKey('region-${region.name}')), findsOneWidget);
    }
    // The push-up starter's region is suggested.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('region-china')),
        matching: find.byKey(const ValueKey('region-suggested')),
      ),
      findsOneWidget,
    );
    await snap(tester, 'new-region');
    // Back to the modes and on again.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.text('What will it be?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('new-mode-pushUp')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('region-paris')));
    await settle(tester);
    final levels = await app.store.levels();
    expect(levels, hasLength(1));
    final level = levels.single;
    expect(level.plan.mode, PlayMode.pushUp);
    expect(level.plan.region, WorldRegion.paris);
    expect(level.plan.name, 'My push-up level');
    expect(level.origin, BuiltOrigin.created);
    expect(app.uri.path, '/builder/edit/${level.id}');
    expect(find.text('My push-up level'), findsOneWidget);
    // A second one gets a name of its own.
    appRouter.go('/builder');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('new-level')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('new-mode-pushUp')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('region-jungle')));
    await settle(tester);
    expect(
      (await app.store.levels()).map((l) => l.plan.name),
      containsAll(['My push-up level', 'My push-up level 2']),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the new level picker makes nothing', (tester) async {
    final app = await pumpBuilderApp(tester);
    await tester.tap(find.byKey(const ValueKey('empty-new-level')));
    await settle(tester);
    await tester.tap(find.byTooltip('Close new level'));
    await settle(tester);
    expect(await app.store.levels(), isEmpty);
    expect(app.uri.path, '/builder');
  });

  testWidgets('a starter level flies, opens read-only, and remixes into a '
      'level of one’s own', (tester) async {
    final app = await pumpBuilderApp(tester);
    await tester.tap(find.byKey(const ValueKey('remix-t-push-1')));
    await settle(tester);
    final level = (await app.store.levels()).single;
    expect(level.origin, BuiltOrigin.remixed);
    expect(level.from, 't-push-1');
    expect(level.plan.name, 'Ten Push-Ups remix');
    expect(
      level.plan.contentJson(),
      BuiltTemplates.byId('t-push-1')!.plan.contentJson(),
    );
    expect(app.uri.path, '/builder/edit/${level.id}');
    // Flying a starter level is a real flight of it.
    appRouter.go('/builder');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('fly-t-tap-1')));
    await tester.pump();
    expect(app.uri.path, '/play/touch');
    expect(app.uri.queryParameters, {'built': 't-tap-1'});
    appRouter.go('/builder');
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('my levels: fly, edit, share, duplicate and delete, with a '
      'level that needs work held back', (tester) async {
    final clipboard = FakeClipboard()..install(tester);
    final ready = builtLevel(PlayMode.touch, id: 'u-readylevel', name: 'Ready');
    final broken = builtLevel(
      PlayMode.squat,
      id: 'u-brokenlevl',
      name: 'Half built',
      gates: 0,
    );
    final app = await pumpBuilderApp(tester, levels: [ready, broken]);
    expect(find.byKey(const ValueKey('level-u-readylevel')), findsOneWidget);
    expect(find.byKey(const ValueKey('level-u-brokenlevl')), findsOneWidget);
    expect(find.text('Needs work'), findsOneWidget);
    await snap(tester, 'shelf');

    // A level that needs work neither flies nor shares: it says how much is
    // left to fix, and Fix it opens the editor in Fly's place.
    expect(find.byKey(const ValueKey('fly-u-brokenlevl')), findsNothing);
    expect(find.textContaining('to fix in the editor'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('share-u-brokenlevl')));
    await tester.pump();
    expect(clipboard.text, isNull);
    expect(find.byKey(const ValueKey('builder-toast')), findsOneWidget);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('fix-u-brokenlevl')));
    await settle(tester);
    expect(app.uri.path, '/builder/edit/u-brokenlevl');
    appRouter.go('/builder');
    await settle(tester);

    // Share copies a code that reads back as the level; one its maker has
    // not flown to the end comes with a tip.
    await tester.tap(find.byKey(const ValueKey('share-u-readylevel')));
    await settle(tester);
    expect(clipboard.text, contains('BEAK1.'));
    expect(clipboard.text, contains('Ready'));
    expect(find.textContaining('Fly it to the finish too'), findsOneWidget);
    final shared = BuiltCode.decode(clipboard.text!, id: 'u-checkcode1');
    expect(shared.plan.contentJson(), ready.contentJson());
    expect(shared.cleared, isFalse);

    // Edit opens the editor; Fly flies it for real.
    await tester.tap(find.byKey(const ValueKey('edit-u-readylevel')));
    await settle(tester);
    expect(app.uri.path, '/builder/edit/u-readylevel');
    appRouter.go('/builder');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('fly-u-readylevel')));
    await tester.pump();
    expect(app.uri.path, '/play/touch');
    expect(app.uri.queryParameters, {'built': 'u-readylevel'});
    appRouter.go('/builder');
    await settle(tester);

    // More: duplicate makes a copy and opens it.
    await tester.tap(find.byKey(const ValueKey('more-u-readylevel')));
    await settle(tester);
    expect(find.byKey(const ValueKey('action-share')), findsOneWidget);
    await snap(tester, 'level-actions');
    await tester.tap(find.byKey(const ValueKey('action-duplicate')));
    await settle(tester);
    final copies = (await app.store.levels())
        .where((l) => l.plan.name == 'Ready copy')
        .toList();
    expect(copies, hasLength(1));
    expect(copies.single.plan.contentJson(), ready.contentJson());
    expect(app.uri.path, '/builder/edit/${copies.single.id}');
    appRouter.go('/builder');
    await settle(tester);

    // Delete asks first; keeping it keeps it.
    await tester.tap(find.byKey(const ValueKey('more-u-brokenlevl')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('action-delete')));
    await settle(tester);
    expect(find.text('Delete “Half built”?'), findsOneWidget);
    await snap(tester, 'delete-confirm');
    await tester.tap(find.byKey(const ValueKey('confirm-no')));
    await settle(tester);
    expect(await app.store.level('u-brokenlevl'), isNotNull);
    await tester.tap(find.byKey(const ValueKey('more-u-brokenlevl')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('action-delete')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-yes')));
    await settle(tester);
    expect(await app.store.level('u-brokenlevl'), isNull);
    expect(find.byKey(const ValueKey('level-u-brokenlevl')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pasted code shows its level before importing it', (
    tester,
  ) async {
    final clipboard = FakeClipboard()..install(tester);
    final app = await pumpBuilderApp(tester);
    final friend = builtLevel(
      PlayMode.jump,
      id: 'u-friendslvl',
      name: 'Friend’s bounce',
      region: WorldRegion.sea,
    );
    clipboard.text =
        'look at this!! ${BuiltCode.message(friend, cleared: true)}';
    await tester.tap(find.byKey(const ValueKey('paste-code')));
    await settle(tester);
    expect(find.byKey(const ValueKey('import-preview')), findsOneWidget);
    expect(find.text('Friend’s bounce'), findsOneWidget);
    expect(find.text('Cleared by its maker'), findsOneWidget);
    expect(find.textContaining('stars to collect'), findsOneWidget);
    await snap(tester, 'paste-preview');
    // Cancel keeps nothing.
    await tester.tap(find.byKey(const ValueKey('import-cancel')));
    await settle(tester);
    expect(await app.store.levels(), isEmpty);
    // Import keeps it under a fresh id, cleared by its maker.
    await tester.tap(find.byKey(const ValueKey('paste-code')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('import-keep')));
    await settle(tester);
    final level = (await app.store.levels()).single;
    expect(level.id, isNot('u-friendslvl'));
    expect(BuiltPlan.isBuiltId(level.id), isTrue);
    expect(level.origin, BuiltOrigin.imported);
    expect(level.cleared, isTrue);
    expect(level.plan.contentJson(), friend.contentJson());
    expect(find.byKey(ValueKey('level-${level.id}')), findsOneWidget);
    expect(find.text('From a friend'), findsOneWidget);
    expect(app.uri.path, '/builder');

    // The same route again offers the level already kept.
    await tester.tap(find.byKey(const ValueKey('paste-code')));
    await settle(tester);
    expect(find.textContaining('You already have this level'), findsOneWidget);
    expect(find.byKey(const ValueKey('import-copy')), findsOneWidget);
    await snap(tester, 'paste-duplicate');
    await tester.tap(find.byKey(const ValueKey('import-open')));
    await settle(tester);
    expect(app.uri.path, '/builder/edit/${level.id}');
    expect(await app.store.levels(), hasLength(1));
    // Or a copy of it, on request.
    appRouter.go('/builder');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('paste-code')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('import-copy')));
    await settle(tester);
    expect(await app.store.levels(), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pasting without a code, a newer one or a damaged one says so', (
    tester,
  ) async {
    final clipboard = FakeClipboard()..install(tester);
    final app = await pumpBuilderApp(tester);
    final code = BuiltCode.encode(
      builtLevel(PlayMode.touch, id: 'u-codelevel1'),
    );
    for (final (text, title) in [
      (null, 'No level code to paste'),
      ('hello there', 'No level code to paste'),
      (code.replaceFirst('BEAK1.', 'BEAK9.'), 'A level from a newer Beakbound'),
      (code.substring(0, code.length ~/ 2), 'That code got scrambled'),
    ]) {
      clipboard.text = text;
      await tester.tap(find.byKey(const ValueKey('paste-code')));
      await settle(tester);
      expect(find.text(title), findsOneWidget, reason: text);
      if (text == null) await snap(tester, 'paste-missing');
      await tester.tap(find.byKey(const ValueKey('notice-ok')));
      await settle(tester);
    }
    expect(await app.store.levels(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the shelf and its sheets on the reference phones', (
    tester,
  ) async {
    for (final (name, size, dpr, insets) in [
      ('792', const Size(792, 360), 1.0, null),
      (
        '915',
        const Size(915, 412),
        2.625,
        const EdgeInsets.only(left: 52, right: 24, bottom: 21),
      ),
    ]) {
      final app = await pumpBuilderApp(
        tester,
        size: size,
        dpr: dpr,
        insets: insets,
      );
      await _seedShelf(app);
      appRouter.go('/');
      await settle(tester);
      if (name == '792') await _shot(tester, 'home-$name');
      appRouter.go('/builder');
      await settle(tester);
      expect(tester.takeException(), isNull);
      // Who cleared what, at a glance.
      expect(find.text('Cleared by you'), findsOneWidget);
      expect(find.text('From a friend'), findsOneWidget);
      expect(find.byKey(const ValueKey('fix-u-polishsqt1')), findsOneWidget);
      await _shot(tester, 'shelf-$name');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('the shelf with large system text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = await pumpBuilderApp(tester, size: const Size(792, 360));
    await _seedShelf(app);
    appRouter.go('/');
    await settle(tester);
    appRouter.go('/builder');
    await settle(tester);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'shelf-large-text');
  });

  testWidgets('the shelf’s flows, captured', (tester) async {
    final clipboard = FakeClipboard()..install(tester);
    final app = await pumpBuilderApp(tester, size: const Size(792, 360));
    await _shot(tester, 'shelf-empty');
    await tester.tap(find.byKey(const ValueKey('new-level')));
    await settle(tester);
    await _shot(tester, 'new-mode');
    await tester.tap(find.byKey(const ValueKey('new-mode-squat')));
    await settle(tester);
    await _shot(tester, 'new-region');
    await tester.tap(find.byTooltip('Close new level'));
    await settle(tester);

    await _seedShelf(app);
    appRouter.go('/');
    await settle(tester);
    appRouter.go('/builder');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('more-u-polishsqt1')));
    await settle(tester);
    await _shot(tester, 'level-actions-needs-work');
    await tester.tap(find.byTooltip('Close'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('share-u-polishtap1')));
    await tester.pump();
    await _shot(tester, 'shared-toast');
    await settle(tester);

    final friend = builtLevel(
      PlayMode.touch,
      id: 'u-friendslvl',
      name: 'Friend’s gauntlet',
      region: WorldRegion.newYork,
      boss: BossKind.baronBat,
    );
    clipboard.text = BuiltCode.message(friend, cleared: false);
    await tester.tap(find.byKey(const ValueKey('paste-code')));
    await settle(tester);
    await _shot(tester, 'paste-preview');
    await tester.tap(find.byKey(const ValueKey('import-keep')));
    await tester.pump();
    await _shot(tester, 'imported-toast');
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}

/// Keeps a shelf a player might have after a week: a level they cleared
/// with three stars, one flown to two, one that needs work, and a friend's.
Future<void> _seedShelf(BuilderApp app) async {
  final store = app.store;
  Future<void> fly(BuiltPlan plan, int stars, String id) => store.saveFlight((
    plan: plan,
    revision: 1,
    run: RunResult(
      id: id,
      mode: plan.mode,
      practice: false,
      score: stars * 2,
      stars: stars,
      repetitions: 0,
      flaps: 0,
      durationSeconds: 60,
      reason: EndReason.completed,
      finishedAt: DateTime(2026, 10, 6, 9),
      course: FlightCourse.starTrail,
      levelId: plan.id,
      levelName: plan.name,
    ),
  ));
  final friend = builtLevel(
    PlayMode.jump,
    id: 'u-polishjmp1',
    name: 'Friend’s bounce',
    region: WorldRegion.sea,
  );
  await store.create(
    friend,
    origin: BuiltOrigin.imported,
    importedCleared: true,
  );
  final broken = builtLevel(
    PlayMode.squat,
    id: 'u-polishsqt1',
    name: 'Half built',
    gates: 0,
    region: WorldRegion.egypt,
  );
  await store.create(broken);
  final push = builtLevel(
    PlayMode.pushUp,
    id: 'u-polishpsh1',
    name: 'A rather long level name',
    region: WorldRegion.paris,
  );
  await store.create(push);
  await fly(push, push.marks.two, 'run-push');
  final tap = builtLevel(
    PlayMode.touch,
    id: 'u-polishtap1',
    name: 'Canopy Dash',
  );
  await store.create(tap);
  await store.markCleared(tap.id, 1);
  await fly(tap, tap.totalStars, 'run-tap');
  final starter = BuiltTemplates.byId('t-push-1')!.plan;
  await fly(starter, starter.marks.two, 'run-starter');
}

/// Saves the screen to `build/visual-review/builder-polish/shelf/` when run
/// with `--dart-define=CAPTURE_VISUALS=true` (and `SHOT_TAG` as a prefix).
Future<void> _shot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  const tag = String.fromEnvironment('SHOT_TAG');
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/visual-review/builder-polish/shelf')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/${tag.isEmpty ? '' : '$tag-'}$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
