import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/builder/built_result_stage.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/stage_key.dart';

import 'builder_ui_harness.dart';
import 'built_play_flow_test.dart' show flyBuiltController;

/// Saves the screen to `build/visual-review/builder-polish/panels/` when
/// run with `--dart-define=CAPTURE_VISUALS=true`.
Future<void> shot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/builder-polish/panels/$name.png')
      ..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

PlayController flightController(WidgetTester tester) =>
    (tester.state(find.byType(PlayScreen)) as dynamic).controller
        as PlayController;

/// The flight's game, loaded, with its loop stopped so the test steps it.
Future<BirdGame> flightGame(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  await tester.pump();
  return game;
}

/// Paints one frame of the frozen flight under the stage.
Future<void> paintFlight(WidgetTester tester, BirdGame game) async {
  game.resumeEngine();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  game.pauseEngine();
  await tester.pump();
}

/// Plays a finished flight's celebration out and lets its save land.
Future<void> toResult(WidgetTester tester, PlayController controller) async {
  await tester.runAsync(controller.finish);
  for (var i = 0; i < 400 && !controller.celebrationSettled; i++) {
    controller.advance(.02, 0, 2.2);
  }
  await tester.runAsync(() async {
    for (var i = 0; i < 20 && !controller.saved; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Crashes the bird on its last heart.
void crash(PlayController controller) {
  final sim = controller.simulation!;
  sim
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
}

/// The word over the bird, as it is read out.
String word(WidgetTester tester) => tester
    .widget<Semantics>(find.byKey(const ValueKey('built-result-word')))
    .properties
    .label!;

/// No star glyph is set in text: the game's fonts draw them as boxes.
void expectNoStarGlyphs() {
  for (final glyph in ['★', '☆', '✓']) {
    expect(find.textContaining(glyph), findsNothing, reason: glyph);
  }
}

/// Every key on the stage is a full touch target.
void expectBigKeys(WidgetTester tester) {
  for (final element in find.byType(StageKey).evaluate()) {
    final size = (element.renderObject! as RenderBox).size;
    expect(size.height, greaterThanOrEqualTo(48), reason: '${element.widget}');
    expect(size.width, greaterThanOrEqualTo(48), reason: '${element.widget}');
  }
}

void main() {
  setUpAll(loadBuilderFonts);

  Future<(BuilderApp, PlayController, BirdGame)> open(
    WidgetTester tester,
    String at, {
    List<BuiltPlan> levels = const [],
    bool reduced = true,
  }) async {
    final app = await pumpBuilderApp(
      tester,
      at: '/builder',
      size: const Size(792, 360),
      levels: levels,
      reduced: reduced,
    );
    appRouter.go(at);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final game = await flightGame(tester);
    return (app, flightController(tester), game);
  }

  testWidgets('a finish is cleared, its first clear and then a new best', (
    tester,
  ) async {
    final level = builtLevel(
      PlayMode.touch,
      id: 'u-resultlvl1',
      name: 'Canopy Dash',
    );
    var (_, c, game) = await open(
      tester,
      '/play/touch?built=u-resultlvl1',
      levels: [level],
    );
    final sim = c.simulation!;
    flyBuiltController(c, seconds: 20);
    sim.collectedStars = 9;
    flyBuiltController(c);
    await toResult(tester, c);
    await paintFlight(tester, game);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(BuiltResultStage), findsOneWidget);
    expect(word(tester), 'Cleared!');
    expect(find.text('First clear!'), findsOneWidget);
    expect(find.text('Saved on this phone'), findsOneWidget);
    expect(find.byKey(const ValueKey('built-result-test-tab')), findsNothing);
    expect(find.text('Tap & Fly'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expectNoStarGlyphs();
    expectBigKeys(tester);
    expect(find.text('Fly again'), findsOneWidget);
    expect(find.byKey(const ValueKey('built-result-edit')), findsOneWidget);
    // A player's own level keeps its flight as a session to replay too.
    expect(find.byKey(const ValueKey('save-or-watch-session')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await shot(tester, 'result-finished');

    // Flying it again with every star beats the best just saved.
    await tester.runAsync(c.retry);
    game = await flightGame(tester);
    flyBuiltController(c);
    await toResult(tester, c);
    await paintFlight(tester, game);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('NEW BEST!'), findsOneWidget);
    expect(find.text('First clear!'), findsNothing);
    await shot(tester, 'result-new-best');
  });

  testWidgets('a bump says how far the flight got, in large text too', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final level = builtLevel(
      PlayMode.touch,
      id: 'u-resultlvl2',
      name: 'Canopy Dash',
    );
    final (_, c, game) = await open(
      tester,
      '/play/touch?built=u-resultlvl2',
      levels: [level],
    );
    flyBuiltController(c, seconds: 8);
    crash(c);
    await tester.runAsync(c.finish);
    c.knockout = 99;
    c.skipKnockout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await paintFlight(tester, game);
    await tester.pump(const Duration(seconds: 2));
    expect(word(tester), 'Bonk!');
    expect(find.text('GOT TO'), findsOneWidget);
    expect(find.text('Reach the finish to earn stars.'), findsOneWidget);
    expect(find.text('Not yet'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expectNoStarGlyphs();
    expectBigKeys(tester);
    expect(tester.takeException(), isNull);
    await shot(tester, 'result-bonk');
  });

  testWidgets('a whole test flight is plainly a test, and its clear is '
      'celebrated and leads back to the editor where it got to', (
    tester,
  ) async {
    final level = builtLevel(
      PlayMode.touch,
      id: 'u-resultlvl3',
      name: 'Canopy Dash',
    );
    final (app, c, game) = await open(
      tester,
      '/play/touch?built=u-resultlvl3&test=1',
      levels: [level],
    );
    await paintFlight(tester, game);
    // The countdown says it is a test.
    expect(find.byKey(const ValueKey('test-flight-tag')), findsOneWidget);
    expect(find.text('· nothing is saved'), findsOneWidget);
    await shot(tester, 'test-countdown-touch');
    flyBuiltController(c, seconds: 4);
    await tester.pump();
    // So does the HUD, and Tap & Fly has no finger rail.
    expect(find.byKey(const ValueKey('test-flight-tag')), findsOneWidget);
    expect(find.byKey(const ValueKey('test-finger-rail')), findsNothing);
    c.pause();
    await tester.pump();
    await paintFlight(tester, game);
    expect(find.textContaining('Nothing is saved.'), findsOneWidget);
    expect(find.byKey(const ValueKey('pause-builder')), findsOneWidget);
    await shot(tester, 'test-pause-touch');
    await tester.runAsync(c.resume);
    flyBuiltController(c);
    await toResult(tester, c);
    await paintFlight(tester, game);
    await tester.pump(const Duration(seconds: 2));
    expect(word(tester), 'Cleared!');
    expect(find.byKey(const ValueKey('built-result-test-tab')), findsOneWidget);
    expect(find.text('TEST FLIGHT'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('built-result-cleared-by-you')),
      findsOneWidget,
    );
    expect(find.text('CLEARED BY YOU'), findsOneWidget);
    expect(find.text('Not kept'), findsOneWidget);
    expect(find.text('Edit level'), findsOneWidget);
    expectNoStarGlyphs();
    expectBigKeys(tester);
    await shot(tester, 'result-test-cleared');
    // The whole test marked the level cleared, and saved no flight.
    final kept = await tester.runAsync(() => app.store.level('u-resultlvl3'));
    expect(kept!.cleared, isTrue);
    expect(await tester.runAsync(app.store.bests), isEmpty);
    await tester.tap(find.byKey(const ValueKey('built-result-edit')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await settle(tester);
    expect(app.uri.path, '/builder/edit/u-resultlvl3');
    expect(
      int.parse(app.uri.queryParameters['at']!),
      greaterThanOrEqualTo(level.finish - 200),
    );
  });

  testWidgets('a push-up test from a place steers on a rail and shows the '
      'workout the level asks for', (tester) async {
    final level = builtLevel(
      PlayMode.pushUp,
      id: 'u-resultlvl4',
      name: 'Ten Dips',
    );
    final (_, c, game) = await open(
      tester,
      '/play/push-up?built=u-resultlvl4&test=1&from=4000',
      levels: [level],
    );
    await paintFlight(tester, game);
    expect(
      find.text('Test flight: drag up and down to steer.'),
      findsOneWidget,
    );
    await shot(tester, 'test-countdown-push');
    flyBuiltController(c, seconds: 4);
    await paintFlight(tester, game);
    expect(find.byKey(const ValueKey('test-finger-rail')), findsOneWidget);
    await shot(tester, 'test-flying-push');
    flyBuiltController(c);
    await toResult(tester, c);
    await paintFlight(tester, game);
    await tester.pump(const Duration(seconds: 2));
    expect(word(tester), 'Cleared!');
    expect(find.text('ASKS FOR'), findsOneWidget);
    expect(find.text('push-ups on camera'), findsOneWidget);
    expect(find.textContaining('Fly it all to clear it.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('built-result-cleared-by-you')),
      findsNothing,
    );
    expectNoStarGlyphs();
    await shot(tester, 'result-test-push-from');
  });

  testWidgets('pausing a test and editing goes back to where it got to', (
    tester,
  ) async {
    final level = builtLevel(
      PlayMode.pushUp,
      id: 'u-resultlvl5',
      name: 'Ten Dips',
    );
    final (app, c, game) = await open(
      tester,
      '/play/push-up?built=u-resultlvl5&test=1&from=4000',
      levels: [level],
    );
    flyBuiltController(c, seconds: 6);
    c.pause();
    await tester.pump();
    await paintFlight(tester, game);
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pause-builder')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await settle(tester);
    expect(app.uri.path, '/builder/edit/u-resultlvl5');
    expect(
      int.parse(app.uri.queryParameters['at']!),
      greaterThanOrEqualTo(4000),
    );
  });

  testWidgets('a starter level keeps its session instead of editing', (
    tester,
  ) async {
    // With motion on, the stage plays its entrance and settles.
    final (_, c, game) = await open(
      tester,
      '/play/touch?built=t-tap-1',
      reduced: false,
    );
    flyBuiltController(c);
    await toResult(tester, c);
    await paintFlight(tester, game);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(word(tester), 'Cleared!');
    expect(find.byKey(const ValueKey('save-or-watch-session')), findsOneWidget);
    expect(find.byKey(const ValueKey('built-result-edit')), findsNothing);
    expectBigKeys(tester);
    expect(tester.takeException(), isNull);
    await shot(tester, 'result-template');
  });
}
