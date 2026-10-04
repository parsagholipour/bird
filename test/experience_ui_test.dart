import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/bird_trail.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/record_chase.dart';
import 'package:push_up_bird/ui/campaign_chrome.dart' show MapKey;
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/flight_goals.dart';
import 'package:push_up_bird/ui/match_hud.dart';
import 'play_session_test.dart' show SessionSource, SilentAudio, startFlight;
import 'daily_adventure_test.dart' show dailyRun;

class WingAudio extends SilentAudio {
  int wings = 0;
  int clouds = 0;
  int stars = 0;
  int trios = 0;
  @override
  void effect(String name, {int? variant}) {
    if (name == 'wing') wings++;
    if (name == 'cloud') clouds++;
    if (name == 'star') stars++;
    if (name == 'trio') trios++;
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/visual-review')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
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
  });

  for (final player in ['new', 'returning', 'choosing', 'daily']) {
    final returning = player != 'new';
    testWidgets('Star Trail fits a small phone for a $player player', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final today = DateTime(2026, 9, 16, 12);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
        clock: () => today,
      );
      final folder = Directory.systemTemp.createTempSync('experience-ui');
      final source = SessionSource();
      final audio = WingAudio();
      await repo.setSetting(SettingKey.reducedMotion, true);
      if (player == 'daily') {
        await repo.saveRun(dailyRun('daily-first', today));
      }
      if (returning && player != 'daily') {
        await repo.saveRun(
          RunResult(
            id: 'previous-flight',
            mode: PlayMode.pushUp,
            practice: false,
            score: 1,
            repetitions: 1,
            flaps: 0,
            durationSeconds: 10,
            reason: EndReason.breakTaken,
            finishedAt: DateTime(2026, 9, 15),
          ),
        );
      }
      final container = ProviderContainer(
        overrides: [
          appClockProvider.overrideWithValue(() => today),
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(folder),
          ),
          audioFactoryProvider.overrideWithValue(() => audio),
          trackingSourceFactoryProvider.overrideWithValue(() => source),
        ],
      );
      await container.read(progressProvider.future);
      appRouter.go('/');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(
            key: ValueKey('visual-capture'),
            child: PushUpBirdApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'home-classic');
      expect(find.byKey(const ValueKey('endless')), findsOneWidget);
      await capture(tester, 'home-star-trail');
      if (player == 'new') {
        await tester.tap(find.text('Flight goals'));
        await tester.pumpAndSettle();
        expect(find.text('Star pocket'), findsOneWidget);
        expect(find.text('Fly for 60 seconds in one trail.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(tester, 'flight-goals-guide');
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is MapKey && w.label == 'Close flight goals',
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('mini-games')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push-Up Flight'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Every 9 stars'), findsOneWidget);
      await capture(tester, 'star-trail-setup');
      final dynamic state = tester.state(find.byType(PlayScreen));
      final controller = state.controller as PlayController;
      expect(controller.course, FlightCourse.starTrail);
      await tester.runAsync(() => startFlight(controller, source));
      await tester.runAsync(() async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      final sim = controller.simulation!;
      if (player != 'daily') {
        expect(
          find.byType(RecordChase),
          findsNothing,
          reason: 'A first Star Trail should not chase the Classic record',
        );
      }
      sim.elapsed = 24;
      sim.birdY = .43;
      sim.score = 26;
      sim.combo = 8;
      sim.collectedStars = 17;
      sim.bestCombo = 11;
      sim.gates = 5;
      sim.perfectPasses = 3;
      sim.obstacles.clear();
      sim.obstacles.addAll([
        Obstacle(x: 1.1, center: .43, gap: .44),
        Obstacle(x: 1.85, center: .7, gap: .44),
      ]);
      sim.stars.clear();
      sim.stars.addAll([
        for (var i = 0; i < 3; i++) SkyStar(x: .68 + .17 * i, y: .43),
      ]);
      controller.notify();
      final game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(
        () => game.loaded.timeout(const Duration(seconds: 5)),
      );
      game.pauseEngine();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<MatchMeter>(find.byKey(const ValueKey('match-shield')))
            .label,
        'Shield ready',
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('match-health'))).right,
        lessThan(FlightSimulation.birdX * 1000 - 24),
        reason: 'The HUD must not cover the bird at the top of a push-up',
      );
      expect(find.byKey(const ValueKey('flight-clock')), findsNothing);
      expect(find.text('1.06× pace'), findsNothing);
      await capture(tester, 'star-trail-flight');
      final flightTime = sim.elapsed;
      sim.elapsed = 58;
      controller.notify();
      game.resumeEngine();
      await tester.pump(const Duration(milliseconds: 16));
      game.pauseEngine();
      await tester.pump();
      await capture(tester, 'star-trail-arrival-hud');
      sim.elapsed = flightTime;
      controller.notify();
      game.resumeEngine();
      await tester.pump(const Duration(milliseconds: 16));
      game.pauseEngine();
      await tester.pump();
      expect(find.byType(FlightGoalHud), findsNothing);
      expect(find.text('Wing earned!'), findsNothing);
      if (player == 'new') expect(audio.wings, 1);
      sim.collectedStars++;
      sim.completedTrios++;
      controller.notify();
      await tester.pump();
      final starSounds = audio.stars;
      expect(starSounds, 1);
      expect(audio.trios, 0);
      controller.notify();
      await tester.pump();
      expect(audio.stars, starSounds, reason: 'The final star sounds once');
      expect(audio.trios, 0, reason: 'No special final-star sound plays');
      sim.magnetCharge = 2;
      controller.notify();
      await tester.pump();
      expect(
        tester
            .widget<MatchMeter>(find.byKey(const ValueKey('match-magnet')))
            .value,
        closeTo(2 / 3, .001),
      );
      expect(tester.takeException(), isNull);
      sim.magnetCharge = 0;
      sim.magnetUntil = sim.elapsed + 6;
      sim.magnetActivations = 1;
      controller.notify();
      game.resumeEngine();
      await tester.pump(const Duration(milliseconds: 16));
      game.pauseEngine();
      await tester.pump();
      expect(find.text('6s'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'star-trail-magnet-flight');
      sim.magnetUntil = 0;
      sim.shield = false;
      sim.hearts = 2;
      sim.invulnerableUntil = sim.elapsed + 1.2;
      controller.notify();
      game.resumeEngine();
      await tester.pump(const Duration(milliseconds: 16));
      game.pauseEngine();
      await tester.pump();
      expect(
        tester
            .widget<MatchMeter>(find.byKey(const ValueKey('match-shield')))
            .label,
        'Recovering',
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'star-trail-recovery');
      if (player == 'new') expect(audio.wings, 1);
      sim.phase = RunPhase.paused;
      controller.notify();
      await tester.pump();
      // Rendering at phone sizes must keep all HUD hit targets and counters inside the scene.
      tester.view.physicalSize = const Size(800, 360);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        sim.elapsed = FlightSimulation.trailDuration;
        controller.recorder!.command('end', EndReason.completed);
        await controller.finish();
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('STAR POINTS'), findsOneWidget);
      expect(find.text('3/3 flight wings'), findsOneWidget);
      if (player == 'new') expect(audio.wings, 1);
      expect(find.text('11 best streak'), findsOneWidget);
      expect(
        find.textContaining(
          player == 'daily'
              ? 'Today’s postcard stamped!'
              : returning
              ? 'Next stamp: Constellation'
              : 'Stamp earned: First wings',
        ),
        findsOneWidget,
      );
      await capture(
        tester,
        player == 'daily'
            ? 'daily-card-celebration'
            : returning
            ? 'star-trail-next-goal'
            : 'star-trail-results',
      );
      appRouter.go('/records');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Your star points to beat'), findsOneWidget);
      await capture(tester, 'records-star-trail');
      if (player == 'new') {
        await tester.tap(find.byTooltip('View Star Trail flight goals'));
        await tester.pumpAndSettle();
        expect(find.text('EARNED'), findsNWidgets(3));
        expect(
          find.text('All three wings earned in one flight!'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await capture(tester, 'flight-goals-earned');
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is MapKey && w.label == 'Close flight goals',
          ),
        );
        await tester.pumpAndSettle();
      }
      appRouter.go('/passport');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('First wings'), findsOneWidget);
      expect(find.text('STAMPED'), findsOneWidget);
      await capture(tester, 'sky-passport');
      appRouter.go('/birds');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final bird in birdAssets) {
          await precacheImage(
            AssetImage('assets/images/$bird.png'),
            tester.element(find.byType(Scaffold)),
          );
        }
      });
      await tester.pumpAndSettle();
      for (final name in BirdTrail.names) {
        expect(find.text(name), findsOneWidget);
      }
      if (player == 'choosing') {
        final card = find.ancestor(
          of: find.text('Peaches'),
          matching: find.byType(Panel),
        );
        await tester.tap(
          find.descendant(of: card, matching: find.text('Fly with me')),
        );
        await tester.pumpAndSettle();
        expect(container.read(progressProvider).requireValue.settings.bird, 1);
        expect(
          find.descendant(of: card, matching: find.text('Equipped')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
      await capture(tester, 'crew-trails-$player');
      appRouter.go('/');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('endless')),
        findsOneWidget,
        reason: 'Returning home should preserve the selected course',
      );
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.runAsync(() async {
        await repo.close();
        await folder.delete(recursive: true);
      });
    });
  }

  testWidgets('every bird shows its signature trail in flight', (tester) async {
    tester.view.physicalSize = const Size(1000, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (var bird = 0; bird < 4; bird++) {
      final sim =
          FlightSimulation(
              rules: JumpFlyMode(),
              practice: false,
              course: FlightCourse.starTrail,
            )
            ..phase = RunPhase.playing
            ..elapsed = 5
            ..birdY = .5;
      sim.obstacles.add(Obstacle(x: 1.25, center: .5, gap: .46));
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: bird,
        reducedMotion: false,
        onChanged: () {},
        playback: true,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: const ValueKey('visual-capture'),
              child: GameWidget(game: game),
            ),
          ),
        );
        await game.loaded.timeout(const Duration(seconds: 5));
      });
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await capture(tester, 'signature-trail-${birdAssets[bird]}');
      await tester.pumpWidget(const SizedBox());
    }
  });

  for (final reduced in [true, false]) {
    testWidgets('all sky regions render with reduced motion $reduced', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = FlightSimulation(
        rules: JumpFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
      );
      sim.obstacles.add(Obstacle(x: 1.2, center: .5, gap: .46));
      sim.stars.addAll([
        for (var i = 0; i < 3; i++) SkyStar(x: .65 + i * .17, y: .5),
      ]);
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 3,
        reducedMotion: reduced,
        onChanged: () {},
        playback: true,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: const ValueKey('visual-capture'),
              child: GameWidget(game: game),
            ),
          ),
        );
        await game.loaded.timeout(const Duration(seconds: 5));
      });
      for (final time in [5.0, 25.0, 45.0]) {
        sim.elapsed = time;
        sim.events.clear();
        sim.events.add(
          FlightEvent(FlightEventKind.perfect, time - .3, .5, value: 3),
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
        await capture(
          tester,
          'sky-${time.toInt()}-${reduced ? 'still' : 'motion'}',
        );
      }
      sim.elapsed = 25;
      sim.birdY = .5;
      sim.events.clear();
      sim.events.add(FlightEvent(FlightEventKind.starTrio, 24.8, .5, value: 5));
      final approaching = StarTrio(x: 1.5, y: .7)..collectedMask = 1;
      sim.starTrios.addAll([
        StarTrio(x: .3, y: .5)
          ..collectedMask = 7
          ..completedAt = 24.8
          ..completedY = .5,
        approaching,
      ]);
      sim.stars.clear();
      sim.stars.addAll([
        for (var i = 1; i < 3; i++)
          SkyStar(
            x: 1.5 + (i - 1) * .17,
            y: .7,
            trio: approaching,
            trioSlot: i,
          ),
      ]);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await capture(tester, 'star-group-${reduced ? 'still' : 'motion'}');
      sim.starTrios.clear();
      sim.combo = 12;
      sim.birdY = .25;
      sim.events.clear();
      sim.events.addAll([
        FlightEvent(FlightEventKind.star, sim.elapsed - .25, .25, value: 3),
        FlightEvent(FlightEventKind.streak, sim.elapsed - .25, .25, value: 3),
      ]);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await capture(tester, 'star-power-${reduced ? 'still' : 'motion'}');
      sim.magnetUntil = sim.elapsed + 6;
      sim.magnetActivations = 1;
      sim.events.clear();
      sim.events.add(
        FlightEvent(FlightEventKind.magnet, sim.elapsed - .3, sim.birdY),
      );
      sim.stars.add(SkyStar(x: .7, y: .28));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await capture(tester, 'star-magnet-${reduced ? 'still' : 'motion'}');
      sim.elapsed = 25;
      sim.combo = 0;
      sim.magnetUntil = 0;
      sim.birdY = .5;
      sim.events.clear();
      final passedGate = Obstacle(x: .22, center: .5, gap: .46)..scored = true;
      sim.obstacles.add(passedGate);
      for (final state in ['perfect', 'clear', 'hit']) {
        passedGate.maxDeviation = state == 'perfect' ? 0 : .12;
        passedGate.hit = state == 'hit';
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
        await capture(tester, 'gate-$state-${reduced ? 'still' : 'motion'}');
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
