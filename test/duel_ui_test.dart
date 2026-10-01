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
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/coop_screen.dart';
import 'package:push_up_bird/ui/replay_screen.dart' show sessionTitle;

import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SilentAudio;

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

  test('a duel counts its flights but keeps no team best', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    RunResult run(String id, int score) => RunResult(
      id: id,
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      practice: false,
      score: score,
      repetitions: 0,
      flaps: 40,
      durationSeconds: 30,
      reason: EndReason.collision,
      finishedAt: DateTime(2026, 10, 1),
    );
    await repo.saveCoop(CoopMode.duel, run('a-coop-duel', 40));
    await repo.saveCoop(CoopMode.duel, run('a-coop-duel', 40));
    await repo.saveCoop(CoopMode.roped, run('b-coop-roped', 9));
    final progress = await repo.load();
    expect(progress.coop.duels, 1);
    expect(progress.coop.record(CoopMode.duel).best, 0);
    expect(progress.coop.flights, 2);
    expect(progress.coop.record(CoopMode.roped).best, 9);
    expect(sessionTitle(run('c-coop-duel', 0)), 'Fly Together · 1 v 1');
    expect(sessionTitle(run('d-coop-free', 0)), 'Fly Together · No rope');
    expect(sessionTitle(run('e-coop-roped', 0)), 'Fly Together · Roped');
  });

  for (final width in [640.0, 800.0]) {
    testWidgets('two players fight a duel at $width', (tester) async {
      tester.view.physicalSize = Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      final folder = Directory.systemTemp.createTempSync('duel-ui');
      addTearDown(() => folder.deleteSync(recursive: true));
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(folder),
          ),
          audioFactoryProvider.overrideWithValue(() => SilentAudio()),
          trackingSourceFactoryProvider.overrideWithValue(
            () => throw StateError('A duel must not create a camera'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(progressProvider.future);
      appRouter.go('/coop');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(
            key: ValueKey('visual-capture'),
            child: PushUpBirdApp(),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(PushUpBirdApp));
        for (final asset in ['pip', 'peaches', 'minty', 'orbit', 'island']) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(CoopScreen), findsOneWidget);

      // Player 1 takes Peaches, player 2 Minty, and they choose to fight.
      await tester.tap(find.byKey(const ValueKey('coop-pick-0-1')));
      await tester.tap(find.byKey(const ValueKey('coop-pick-1-2')));
      await tester.tap(find.byKey(const ValueKey('coop-mode-duel')));
      await tester.pumpAndSettle();
      expect(find.text('1 V 1: FIRST DUEL'), findsOneWidget);
      expect(find.byKey(const ValueKey('coop-versus')), findsOneWidget);
      expect(find.text('Fight!'), findsOneWidget);
      await capture(tester, 'duel-setup-${width.toInt()}');
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('coop-start')));
      await tester.pump();
      var game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      var sim = game.simulation;
      expect(sim.duel, isTrue);
      expect((game.bird, game.partnerBird), (1, 2));
      expect(find.text('Ready to duel…'), findsOneWidget);
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(sim.phase, RunPhase.playing);

      // Each rival has its own hearts in its own top corner, and the pause
      // button sits between them.
      final sky = tester.getRect(find.byKey(const ValueKey('coop-flight')));
      final p1 = tester.getCenter(find.byKey(const ValueKey('duel-health-0')));
      final p2 = tester.getCenter(find.byKey(const ValueKey('duel-health-1')));
      expect(p1.dx, lessThan(sky.width * .25));
      expect(p2.dx, greaterThan(sky.width * .75));
      expect(
        tester.getCenter(find.bySemanticsLabel('Pause flight')).dx,
        closeTo(sky.center.dx, 2),
      );
      expect(find.byKey(const ValueKey('coop-health')), findsNothing);

      // Each half of the sky still flaps its own player's bird.
      final left = Offset(sky.left + sky.width * .25, sky.center.dy);
      final right = Offset(sky.left + sky.width * .75, sky.center.dy);
      await tester.tapAt(right);
      game.update(.02);
      await tester.pump();
      expect((sim.lead.flaps, sim.partner!.flaps), (0, 1));
      await tester.tapAt(left);
      game.update(.02);
      await tester.pump();
      expect((sim.lead.flaps, sim.partner!.flaps), (1, 1));

      // Player 1 flies into a box: its prize shows under player 1's hearts.
      sim.boxes.add(MysteryBox(x: sim.lead.x + .01, y: sim.lead.y, phase: 0));
      // The HUD catches up within its 50 ms refresh.
      for (var i = 0; i < 3; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(sim.lead.boxesOpened, 1);
      expect(find.byKey(const ValueKey('duel-prize-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('duel-prize-1')), findsNothing);
      // Star power shows its meter while it lasts.
      sim.partner!.starPowerUntil = sim.elapsed + Duel.starPowerSeconds;
      for (var i = 0; i < 10; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(find.byKey(const ValueKey('duel-star-power-1')), findsOneWidget);
      await capture(tester, 'duel-flight-${width.toInt()}');
      for (var i = 0; i < 100; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(find.byKey(const ValueKey('duel-prize-0')), findsNothing);
      expect(tester.takeException(), isNull);

      // Player 2 loses its last heart: player 1 wins.
      Future<void> knockOut(int player) async {
        final bird = sim.flock[player];
        sim.flock[1 - player].starPowerUntil = double.negativeInfinity;
        bird
          ..starPowerUntil = double.negativeInfinity
          ..invulnerableUntil = 0
          ..hearts = 1
          ..shield = false
          ..y = 1;
        game.update(.02);
        await tester.pump();
        expect(sim.phase, RunPhase.ended);
        for (var i = 0; i < 20; i++) {
          game.update(.1);
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      await knockOut(1);
      expect(sim.duelWinner, 0);
      expect(find.text('Player 1 wins!'), findsOneWidget);
      expect(find.text('SERIES 1–0'), findsOneWidget);
      expect(find.text('Rematch'), findsOneWidget);
      expect(find.text('Peaches beat Minty'), findsOneWidget);
      await capture(tester, 'duel-results-${width.toInt()}');
      expect(tester.takeException(), isNull);
      var progress = container.read(progressProvider).requireValue;
      expect(progress.coop.duels, 1);
      expect(progress.coop.mode, CoopMode.duel);

      // A rematch keeps the series going.
      await tester.tap(find.byKey(const ValueKey('coop-retry')));
      await tester.pump();
      game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      expect(game.simulation, isNot(same(sim)));
      sim = game.simulation;
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(sim.phase, RunPhase.playing);
      expect(find.byKey(const ValueKey('duel-prize-0')), findsNothing);
      await knockOut(0);
      expect(find.text('Player 2 wins!'), findsOneWidget);
      expect(find.text('SERIES 1–1'), findsOneWidget);
      progress = container.read(progressProvider).requireValue;
      expect(progress.coop.duels, 2);
      expect(progress.coop.record(CoopMode.duel).best, 0);
      expect(progress.flightsFlown, 0);

      // Records counts the duels apart from the team flights.
      appRouter.go('/records');
      await tester.pumpAndSettle();
      expect(find.textContaining('2 duels'), findsOneWidget);
      expect(find.textContaining('together'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
