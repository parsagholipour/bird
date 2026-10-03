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

  test('each co-op mode keeps its own record, apart from solo', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    await repo.equipBird(2);
    var progress = await repo.load();
    expect(progress.coop.birds, (2, 3));
    expect(progress.coop.mode, CoopMode.roped);
    expect(progress.coop.record(CoopMode.roped).best, 0);
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
    await repo.saveCoop(CoopMode.roped, run('a-coop-roped', 12));
    // A retried save counts once.
    await repo.saveCoop(CoopMode.roped, run('a-coop-roped', 12));
    await repo.saveCoop(CoopMode.roped, run('b-coop-roped', 7));
    await repo.saveCoop(CoopMode.free, run('c-coop-free', 30));
    await repo.chooseCoop(1, 1, CoopMode.free);
    progress = await repo.load();
    expect(progress.coop.record(CoopMode.roped).best, 12);
    expect(progress.coop.record(CoopMode.roped).flights, 2);
    expect(progress.coop.record(CoopMode.free).best, 30);
    expect(progress.coop.record(CoopMode.free).flights, 1);
    expect(progress.coop.flights, 3);
    expect(progress.coop.birds, (1, 1));
    expect(progress.coop.mode, CoopMode.free);
    expect(progress.flightsFlown, 0);
    expect(progress.record(PlayMode.touch, FlightCourse.starTrail).best, 0);
    expect(() => repo.chooseCoop(0, 4, CoopMode.roped), throwsArgumentError);
  });

  for (final (width, mode) in [
    (640.0, CoopMode.roped),
    (800.0, CoopMode.roped),
    (800.0, CoopMode.free),
  ]) {
    final name = '${mode == CoopMode.free ? 'free-' : ''}${width.toInt()}';
    testWidgets('two players pick birds and fly ${mode.title} at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      final folder = Directory.systemTemp.createTempSync('coop-ui');
      addTearDown(() => folder.deleteSync(recursive: true));
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(folder),
          ),
          audioFactoryProvider.overrideWithValue(() => SilentAudio()),
          trackingSourceFactoryProvider.overrideWithValue(
            () => throw StateError('Co-op must not create a camera'),
          ),
        ],
      );
      addTearDown(container.dispose);
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
      await tester.runAsync(() async {
        final context = tester.element(find.byType(PushUpBirdApp));
        for (final asset in ['pip', 'peaches', 'minty', 'orbit', 'island']) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mini-games')));
      await tester.pumpAndSettle();
      await capture(tester, 'coop-mini-games-${width.toInt()}');
      await tester.ensureVisible(find.byKey(const ValueKey('mode-coop')));
      await tester.tap(find.byKey(const ValueKey('mode-coop')));
      await tester.pumpAndSettle();
      expect(find.byType(CoopScreen), findsOneWidget);
      expect(find.text('Fly Together'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Player 1 takes Minty, player 2 Orbit.
      await tester.tap(find.byKey(const ValueKey('coop-pick-0-2')));
      await tester.tap(find.byKey(const ValueKey('coop-pick-1-3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('coop-bird-0-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('coop-bird-1-3')), findsOneWidget);
      if (mode == CoopMode.free) {
        await tester.tap(find.byKey(const ValueKey('coop-mode-free')));
        await tester.pumpAndSettle();
        expect(find.text('NO ROPE: NO BEST YET'), findsOneWidget);
      }
      await capture(tester, 'coop-setup-$name');

      await tester.tap(find.byKey(const ValueKey('coop-start')));
      await tester.pump();
      final game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      expect(game.bird, 2);
      expect(game.partnerBird, 3);
      final sim = game.simulation;
      expect(sim.paired, isTrue);
      expect(sim.coop, mode);
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(sim.phase, RunPhase.playing);

      // Each half of the sky flaps its own player's bird.
      final sky = tester.getRect(find.byKey(const ValueKey('coop-flight')));
      final left = Offset(sky.left + sky.width * .25, sky.center.dy);
      final right = Offset(sky.left + sky.width * .75, sky.center.dy);
      await tester.tapAt(left);
      game.update(.02);
      await tester.pump();
      expect((sim.lead.flaps, sim.partner!.flaps), (1, 0));
      await tester.tapAt(right);
      game.update(.02);
      await tester.pump();
      expect((sim.lead.flaps, sim.partner!.flaps), (1, 1));

      // Each player has their own Shoot and Sprint.
      for (final player in [0, 1]) {
        for (final control in ['shoot', 'sprint']) {
          final button = find.byKey(ValueKey('coop-$control-$player'));
          expect(button, findsOneWidget);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        }
      }
      expect(
        tester.getCenter(find.byKey(const ValueKey('coop-shoot-0'))).dx,
        lessThan(sky.center.dx),
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('coop-shoot-1'))).dx,
        greaterThan(sky.center.dx),
      );
      await tester.tap(find.byKey(const ValueKey('coop-sprint-1')));
      await tester.pump();
      expect(sim.sprints, 1);
      expect(sim.partner!.sprints, 1);
      expect(sim.lead.sprints, 0);
      await tester.tap(find.byKey(const ValueKey('coop-shoot-0')));
      await tester.pump();
      expect(sim.lead.shots, 1);
      expect(sim.partner!.shots, 0);
      // Buttons never flap the bird behind them.
      expect(sim.flaps, 2);

      for (var i = 0; i < 40; i++) {
        for (final (player, bird) in sim.flock.indexed) {
          if (bird.y > .55 && bird.velocity > 0) {
            await tester.tapAt(player == 0 ? left : right);
          }
        }
        game.update(.03);
      }
      await tester.pump();
      await capture(tester, 'coop-flight-$name');
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Pause flight'));
      await tester.pump();
      expect(find.text('Take a breather.'), findsOneWidget);
      await tester.tap(find.text('Finish flight'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('coop-retry')), findsOneWidget);
      expect(find.text('P1 flaps'), findsOneWidget);
      await capture(tester, 'coop-results-$name');
      final progress = container.read(progressProvider).requireValue;
      expect(progress.coop.record(mode).flights, 1);
      expect(progress.coop.flights, 1);
      expect(progress.coop.mode, mode);
      expect(progress.coop.birds, (2, 3));
      expect(progress.flightsFlown, 0);

      await tester.tap(find.byKey(const ValueKey('coop-change')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('coop-start')), findsOneWidget);
      expect(find.byKey(const ValueKey('coop-bird-0-2')), findsOneWidget);
      // The mode is remembered with the birds.
      expect(find.textContaining(mode.title.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Records shows a team best for each team mode; a duel has none.
      appRouter.go('/records');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('coop-record-duel')), findsNothing);
      for (final shown in CoopMode.values.where((m) => m.team)) {
        final tile = find.byKey(ValueKey('coop-record-${shown.name}'));
        expect(tile, findsOneWidget);
        expect(
          find.descendant(
            of: tile,
            matching: find.text('${progress.coop.record(shown).best}'),
          ),
          findsOneWidget,
        );
      }
      expect(find.text('Fly Together · No rope'), findsOneWidget);
      await capture(tester, 'coop-records-$name');
      expect(tester.takeException(), isNull);
    });
  }
}
