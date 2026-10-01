import 'dart:io';

import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/knockout_art.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/game_over_stage.dart';
import 'package:push_up_bird/ui/play_screen.dart';

import 'boss_fight_test.dart' show arena, step;
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SilentAudio;
import 'recorded_flight.dart' show rideTheSky;

/// Saves can be made to fail, to show the stage's tap-to-retry state.
class _FlakyRepository extends SqliteProgressRepository {
  _FlakyRepository(super.db);
  bool fail = false;
  @override
  Future<void> saveRun(RunResult result) async {
    if (fail) throw const FileSystemException('Disk full');
    return super.saveRun(result);
  }
}

class _App {
  _App(this.container, this.repository);
  final ProviderContainer container;
  final _FlakyRepository repository;
}

Future<_App> _open(
  WidgetTester tester,
  Size size, {
  bool practice = false,
  bool reduced = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _FlakyRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repository.setSetting(SettingKey.reducedMotion, reduced);
  final folder = Directory.systemTemp.createTempSync('game-over');
  addTearDown(() => folder.deleteSync(recursive: true));
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repository),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(() => SilentAudio()),
      trackingSourceFactoryProvider.overrideWithValue(
        () => throw StateError('Touch must not create a camera'),
      ),
    ],
  );
  await container.read(progressProvider.future);
  appRouter.go('/play/touch${practice ? '?practice=true' : ''}');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('visual-capture'),
        child: PushUpBirdApp(),
      ),
    ),
  );
  // The setup bird bobs forever with motion on, so pump rather than settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return _App(container, repository);
}

PlayController _controller(WidgetTester tester) =>
    (tester.state(find.byType(PlayScreen)) as dynamic).controller
        as PlayController;

BirdGame _game(WidgetTester tester) => tester
    .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
    .game!;

/// Starts a touch flight and runs it through the countdown by hand.
Future<BirdGame> _takeOff(WidgetTester tester) async {
  await tester.tap(find.text('Start touch flight'));
  await tester.pump();
  final game = _game(tester);
  await tester.runAsync(() => game.loaded);
  await tester.pump();
  game.pauseEngine();
  for (var i = 0; i < 151; i++) {
    game.update(.02);
  }
  await tester.pump();
  expect(game.simulation.phase, RunPhase.playing);
  return game;
}

/// Flies the autopilot for [seconds], then steers into the next wall on
/// the last heart, through the real game loop.
Future<void> _flyAndCrash(
  WidgetTester tester,
  BirdGame game, {
  double seconds = 6,
  int? score,
}) async {
  final controller = _controller(tester);
  final sim = game.simulation;
  for (var t = 0.0; t < seconds; t += .02) {
    sim.hearts = 3;
    if (rideTheSky(sim)) controller.flap();
    game.update(.02);
  }
  sim
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  if (score != null) sim.score = score;
  for (var i = 0; i < 2000 && sim.phase != RunPhase.ended; i++) {
    final next = sim.obstacles
        .where((o) => o.x + o.width > FlightSimulation.birdX - .05)
        .firstOrNull;
    final aim = next == null
        ? .45
        : next.top > .2
        ? next.top - .05
        : next.bottom + .05;
    if (sim.birdY > aim + .02 && sim.velocity >= 0) controller.flap();
    game.update(.02);
  }
  expect(sim.endReason, EndReason.collision);
  await tester.pump();
}

/// Mounts [GameOverStage] by itself over [world]'s knocked-out frame, for
/// a crash staged outside the app.
Future<(PlayController, BirdGame)> _standalone(
  WidgetTester tester,
  FlightSimulation world, {
  required int bird,
  bool splash = false,
  FlightCourse course = FlightCourse.starTrail,
  int? score,
}) async {
  final controller = PlayController(
    mode: PlayMode.touch,
    course: course,
    source: null,
    audio: SilentAudio(),
    bird: bird,
    saveRun: (_) async {},
    saveSession: (_) async {},
  );
  await tester.runAsync(() async {
    await controller.fly();
    controller.simulation!
      ..started = true
      ..score = score ?? world.score;
    controller.simulation!.end(EndReason.collision);
    await controller.finish();
  });
  final game = BirdGame(
    simulation: world,
    nowMs: () => 0,
    bird: bird,
    reducedMotion: false,
    playback: true,
    onChanged: () {},
    knockout: () => KnockoutArt.seconds,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey('visual-capture'),
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              GameWidget(game: game),
              GameOverStage(
                controller: controller,
                progress: const ProgressSnapshot(),
                mode: PlayMode.touch,
                course: course,
                initialBest: 999,
                initialStamps: const {},
                initialDailyKey: null,
                initialDailyComplete: false,
                onLeave: ([_ = '/']) async {},
                splash: splash,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() => game.loaded);
  return (controller, game);
}

/// Paints one frame of the (otherwise paused) flight.
Future<void> _paint(WidgetTester tester, BirdGame game) async {
  game.resumeEngine();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  game.pauseEngine();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    Directory('build/visual-review/death').createSync(recursive: true);
  });

  for (final size in [const Size(640, 360), const Size(915, 412)]) {
    final w = size.width.toInt();
    testWidgets('a fatal bump plays the knockout, then the game-over stage '
        '($w)', (tester) async {
      final app = await _open(tester, size);
      final game = await _takeOff(tester);
      final controller = _controller(tester);
      await _flyAndCrash(tester, game, score: 31);

      // The knockout: the frozen flight stays, the HUD goes, and saving
      // has already begun.
      expect(controller.stage, PlayStage.fallen);
      expect(find.byType(GameWidget<BirdGame>), findsOneWidget);
      expect(find.byKey(const ValueKey('touch-shoot')), findsNothing);
      expect(find.byKey(const ValueKey('match-health')), findsNothing);
      expect(find.byType(GameOverStage), findsNothing);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(controller.saved, isTrue);
      expect(
        app.container
            .read(progressProvider)
            .requireValue
            .record(PlayMode.touch, FlightCourse.starTrail)
            .best,
        controller.result!.score,
      );
      for (final t in [.1, .35, .8]) {
        while (controller.knockout! < t) {
          game.update(1 / 60);
        }
        await _paint(tester, game);
        await capture(tester, 'death/flow-$w-knockout-${(t * 1000).round()}ms');
      }

      // Mashing before the guard does nothing; after it, a tap skips.
      final skip = find.byKey(const ValueKey('knockout-skip'));
      controller.knockout = .2;
      await tester.tap(skip);
      await tester.pump();
      expect(controller.stage, PlayStage.fallen);
      controller.knockout = KnockoutArt.skipAfter + .01;
      await tester.tap(skip);
      await tester.pump();
      expect(controller.stage, PlayStage.results);
      expect(find.byType(GameOverStage), findsOneWidget);
      await _paint(tester, game);

      // A tap as the stage arrives cannot start another flight.
      await tester.tap(find.text('Fly again'), warnIfMissed: false);
      await tester.pump();
      expect(controller.stage, PlayStage.results);
      await tester.pump(const Duration(milliseconds: 500));
      await capture(tester, 'death/stage-$w-entrance');
      await tester.pump(const Duration(milliseconds: 1100));
      await capture(tester, 'death/stage-$w-best');
      expect(find.text('NEW PERSONAL BEST!'), findsOneWidget);
      expect(find.text('Bonk!'), findsNothing, reason: 'Letters drop in');
      expect(find.bySemanticsLabel('Bonk!'), findsOneWidget);
      expect(find.text('${controller.result!.score}'), findsWidgets);
      expect(find.byKey(const ValueKey('result-flight-goals')), findsOne);
      expect(find.byKey(const ValueKey('save-or-watch-session')), findsOne);
      expect(find.text('Home'), findsOneWidget);
      // The bird shakes it off, and Fly again hops with a glint.
      await tester.pump(const Duration(milliseconds: 2900));
      await capture(tester, 'death/stage-$w-ready');
      await tester.pumpAndSettle();
      await capture(tester, 'death/stage-$w-best-settled');

      // Flight wings open their goals.
      await tester.tap(find.byKey(const ValueKey('result-flight-goals')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      // Save session, then Watch replay.
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('save-or-watch-session')));
        for (var i = 0; i < 50 && !controller.sessionSaved; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      expect(find.text('Watch replay'), findsOneWidget);
      expect(find.text('Session saved · Watch in Records'), findsOneWidget);
      await capture(tester, 'death/stage-$w-watch-replay');

      // Fly again: a normal game over follows the new best.
      await tester.tap(find.text('Fly again'));
      await tester.pump();
      await tester.pump();
      expect(controller.stage, PlayStage.flying);
      expect(controller.knockout, isNull);
      final second = _game(tester);
      expect(second, isNot(same(game)));
      await tester.runAsync(() => second.loaded);
      second.pauseEngine();
      for (var i = 0; i < 151; i++) {
        second.update(.02);
      }
      await _flyAndCrash(tester, second, seconds: 12, score: 12);
      while (controller.stage == PlayStage.fallen) {
        second.update(1 / 60);
      }
      await _paint(tester, second);
      await tester.pumpAndSettle();
      expect(find.text('NEW PERSONAL BEST!'), findsNothing);
      expect(find.textContaining('A little bump in the clouds.'), findsOne);
      await capture(tester, 'death/stage-$w-normal');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      app.container.dispose();
    });

    testWidgets('practice and save-error stages ($w)', (tester) async {
      final app = await _open(tester, size, practice: true);
      var game = await _takeOff(tester);
      final controller = _controller(tester);
      await _flyAndCrash(tester, game, seconds: 20);
      while (controller.stage == PlayStage.fallen) {
        game.update(1 / 60);
      }
      await _paint(tester, game);
      await tester.pumpAndSettle();
      expect(find.text('PRACTICE'), findsOneWidget);
      expect(
        find.text('Practice flights leave your records untouched.'),
        findsOneWidget,
      );
      await capture(tester, 'death/stage-$w-practice');
      await tester.pumpWidget(const SizedBox());
      app.container.dispose();

      final scored = await _open(tester, size);
      game = await _takeOff(tester);
      final scoredController = _controller(tester);
      scored.repository.fail = true;
      await _flyAndCrash(tester, game, seconds: 35, score: 18);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      while (scoredController.stage == PlayStage.fallen) {
        game.update(1 / 60);
      }
      await _paint(tester, game);
      await tester.pumpAndSettle();
      final retry = find.text('Could not save your flight. Tap to retry.');
      expect(retry, findsOneWidget);
      await capture(tester, 'death/stage-$w-save-error');
      scored.repository.fail = false;
      await tester.runAsync(() async {
        await tester.tap(retry);
        for (var i = 0; i < 50 && !scoredController.saved; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      expect(retry, findsNothing);
      expect(find.textContaining('Saved on this phone'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      scored.container.dispose();
    });
  }

  testWidgets('Reduced Motion: a calm knockout and a still stage', (
    tester,
  ) async {
    final app = await _open(tester, const Size(800, 360), reduced: true);
    final game = await _takeOff(tester);
    final controller = _controller(tester);
    await _flyAndCrash(tester, game, seconds: 8, score: 9);
    expect(controller.stage, PlayStage.fallen);
    while (controller.knockout! < .5) {
      game.update(1 / 60);
    }
    await _paint(tester, game);
    await capture(tester, 'death/flow-800-reduced-knockout-500ms');
    while (controller.stage == PlayStage.fallen) {
      game.update(1 / 60);
    }
    expect(controller.knockout, KnockoutArt.calmSeconds);
    await _paint(tester, game);
    await tester.pumpAndSettle();
    await capture(tester, 'death/stage-800-reduced');
    expect(find.text('Fly again'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.container.dispose();
  });

  testWidgets('a plunge into the pirate sea gets a Splash! stage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The Pirate Captain's fight, ended in the sea on the last heart.
    final sea = arena(version: FlightSimulation.currentRulesVersion)
      ..elapsed = FlightSimulation.bossInterval - .001
      ..bossesDefeated = 3;
    for (var i = 0; i < 300; i++) {
      sea
        ..birdY = .5
        ..velocity = 0
        ..hearts = 3;
      step(sea, .02, 800 / 360);
    }
    sea
      ..hearts = 1
      ..shield = false
      ..invulnerableUntil = 0;
    for (var i = 0; i < 400 && sea.phase != RunPhase.ended; i++) {
      step(sea, .02, 800 / 360);
    }
    expect(sea.endReason, EndReason.collision);
    expect(KnockoutArt.atSea(sea), isTrue);
    final (controller, game) = await _standalone(
      tester,
      sea,
      bird: 2,
      splash: true,
    );
    await tester.pump(const Duration(milliseconds: 1600));
    game.pauseEngine();
    expect(find.bySemanticsLabel('Splash!'), findsOneWidget);
    expect(find.text('A little splash in the sea.'), findsOneWidget);
    await capture(tester, 'death/stage-800-splash');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('every bird sits dazed on the stage, then looks ready', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (var bird = 0; bird < 4; bird++) {
      // A fall into the next wall on the last heart, away from any boss.
      final world = arena(version: FlightSimulation.currentRulesVersion)
        ..elapsed = 8;
      for (var i = 0; i < 150; i++) {
        world
          ..birdY = .5
          ..velocity = 0
          ..hearts = 3;
        step(world, .02, 800 / 360);
      }
      world
        ..hearts = 1
        ..shield = false
        ..invulnerableUntil = 0;
      for (var i = 0; i < 2000 && world.phase != RunPhase.ended; i++) {
        step(world, .02, 800 / 360);
      }
      expect(world.endReason, EndReason.collision);
      // Orbit flies Classic, whose stats end on a rank instead of a streak.
      final (controller, game) = await _standalone(
        tester,
        world,
        bird: bird,
        course: bird == 3 ? FlightCourse.classic : FlightCourse.starTrail,
        score: bird == 3 ? 12 : null,
      );
      if (bird == 0) {
        // A filmstrip of the entrance, for reviewing its choreography.
        var at = 0;
        for (final ms in [120, 280, 440, 600, 800, 1000]) {
          await tester.pump(Duration(milliseconds: ms - at));
          at = ms;
          await capture(tester, 'death/stage-800-entrance-${ms}ms');
        }
        await tester.pump(Duration(milliseconds: 1600 - at));
      } else {
        await tester.pump(const Duration(milliseconds: 1600));
      }
      game.pauseEngine();
      await capture(tester, 'death/stage-800-bird-$bird-dazed');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bonk!'), findsOneWidget);
      if (bird == 3) expect(find.text('Cloud explorer'), findsOneWidget);
      await capture(tester, 'death/stage-800-bird-$bird-ready');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });

  testWidgets('Home during the knockout leaves cleanly', (tester) async {
    final app = await _open(tester, const Size(800, 360));
    final game = await _takeOff(tester);
    final controller = _controller(tester);
    await _flyAndCrash(tester, game);
    expect(controller.stage, PlayStage.fallen);
    await tester.runAsync(() async {
      await tester.binding.handlePopRoute();
      for (
        var i = 0;
        i < 50 && find.byType(PlayScreen).evaluate().isNotEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PlayScreen), findsNothing);
    expect(
      app.container
          .read(progressProvider)
          .requireValue
          .record(PlayMode.touch, FlightCourse.starTrail)
          .runs,
      1,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.container.dispose();
  });
}
