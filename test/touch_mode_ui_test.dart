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
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/replay_screen.dart';
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

  for (final width in [640.0, 800.0]) {
    testWidgets('touch flight, results and replay at $width without a camera', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 360);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(left: width == 800 ? 40 : 0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      await repo.setSetting(SettingKey.recordAudio, true);
      final folder = Directory.systemTemp.createTempSync('touch-ui');
      final sessions = SessionRepository(folder);
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(sessions),
          audioFactoryProvider.overrideWithValue(() => SilentAudio()),
          trackingSourceFactoryProvider.overrideWithValue(
            () => throw StateError('Touch must not create a camera'),
          ),
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
      await tester.runAsync(() async {
        final context = tester.element(find.byType(PushUpBirdApp));
        for (final asset in ['pip', 'peaches', 'island']) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pumpAndSettle();
      await capture(tester, 'touch-home-${width.toInt()}');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('play')));
      await tester.pumpAndSettle();
      await capture(tester, 'mode-picker-${width.toInt()}');
      await tester.tap(find.text('Tap & Fly'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PlayScreen>(find.byType(PlayScreen)).mode,
        PlayMode.touch,
      );
      expect(
        tester.widget<PlayScreen>(find.byType(PlayScreen)).course,
        FlightCourse.starTrail,
      );
      expect(find.byType(AndroidView), findsNothing);
      expect(find.text('Start camera'), findsNothing);
      expect(find.text(FlightCourse.starTrail.subtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'touch-setup-${width.toInt()}');
      await tester.tap(find.text('Start touch flight'));
      await tester.pump();
      final game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(game.simulation.phase, RunPhase.playing);
      final shoot = find.byKey(const ValueKey('touch-shoot'));
      expect(shoot, findsOneWidget);
      expect(tester.getSize(shoot).height, greaterThanOrEqualTo(44));
      await tester.tap(shoot);
      await tester.pump();
      expect(game.simulation.shots, 1);
      expect(game.simulation.rocks, hasLength(1));
      expect(game.simulation.flaps, 0);
      await tester.tap(shoot); // Disabled cooldown must not leak to the sky.
      game.update(.02);
      await tester.pump();
      expect(game.simulation.shots, 1);
      expect(game.simulation.flaps, 0);
      final flight = find.byKey(const ValueKey('touch-flight'));
      final bounds = tester.getRect(flight);
      final tapPosition = Offset(
        bounds.left + bounds.width * .7,
        bounds.top + bounds.height * .5,
      );
      final gesture = await tester.startGesture(tapPosition);
      await tester.pump(const Duration(milliseconds: 1));
      game.update(.02);
      expect(game.simulation.flaps, 1);
      for (var i = 0; i < 10; i++) {
        game.update(.02);
      }
      expect(game.simulation.flaps, 1);
      await gesture.up();
      await tester.pump();
      expect(find.text('1 flap'), findsNothing);
      await tester.tapAt(tapPosition);
      game.update(.06); // Include the HUD's 50 ms refresh interval.
      await tester.pump();
      expect(game.simulation.flaps, 2);
      expect(find.text('2 flaps'), findsNothing);
      expect(find.text('Tap the sky to flap'), findsNothing);
      expect(find.text('Tracking you'), findsNothing);
      for (final badge in [
        find.byKey(const ValueKey('match-health')),
        find.text('${game.simulation.score}'),
        find.byKey(const ValueKey('match-shield')),
      ]) {
        expect(badge, findsOneWidget);
        final flapsBefore = game.simulation.flaps;
        // Passive readouts intentionally pass hit tests to the flight below.
        await tester.tap(badge, warnIfMissed: false);
        game.update(.02);
        await tester.pump();
        expect(game.simulation.flaps, flapsBefore + 1);
        game.update(.02);
        await tester.pump();
        expect(game.simulation.flaps, flapsBefore + 1);
      }
      final skyTouch = await tester.startGesture(tapPosition, pointer: 1);
      await tester.tap(shoot, pointer: 2);
      game.update(.02);
      await skyTouch.up();
      await tester.pump();
      expect(game.simulation.flaps, 6);
      expect(game.simulation.shots, 2);
      // Check the first enemy before it can leave the narrower flight canvas.
      expect(
        game.simulation.enemies.length + game.simulation.enemiesDefeated,
        greaterThan(0),
      );
      // Fly into the first approach so visual review includes buildings.
      for (var i = 0; i < 60; i++) {
        final sim = game.simulation;
        final target = sim.obstacles.first.target;
        if (sim.birdY > target + .06 && sim.velocity > 0) {
          await tester.tapAt(tapPosition);
        }
        game.update(.04);
      }
      await tester.pump();
      await tester.tap(shoot);
      expect(game.simulation.rocks, isNotEmpty);
      game.update(.04);
      await tester.pump();
      expect(game.simulation.shots, 3);
      game.resumeEngine();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      game.pauseEngine();
      await capture(tester, 'touch-flight-${width.toInt()}');
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(GameWidget<BirdGame>)),
        Offset.zero & Size(width, 360),
        reason:
            'The flight canvas must reach every screen edge, including '
            'outside the safe area used by the HUD.',
      );
      for (final edge in [
        const Offset(1, 180),
        Offset(width - 1, 180),
        Offset(width / 2, 1),
        Offset(width / 2, 359),
      ]) {
        final flapsBefore = game.simulation.flaps;
        await tester.tapAt(edge);
        game.update(.02);
        await tester.pump();
        expect(game.simulation.flaps, flapsBefore + 1);
      }
      final flapsBeforeStop = game.simulation.flaps;
      await tester.tap(find.byTooltip('End scored flight'));
      await tester.pumpAndSettle();
      expect(
        game.simulation.flaps,
        flapsBeforeStop,
      ); // HUD actions must not flap.
      expect(find.text('Save session'), findsOneWidget);
      await capture(tester, 'touch-results-${width.toInt()}');
      await tester.runAsync(() async {
        await tester.tap(find.text('Save session'));
        for (
          var i = 0;
          i < 50 && find.text('Watch replay').evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      expect(find.text('Watch replay'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Watch replay'));
        for (
          var i = 0;
          i < 50 && find.byType(ReplayScreen).evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      expect(find.byType(ReplayScreen), findsOneWidget);
      expect(find.text('Corner camera'), findsNothing);
      expect(tester.takeException(), isNull);
      appRouter.go('/records');
      await tester.pumpAndSettle();
      expect(find.text('Tap & Fly'), findsNWidgets(2));
      await capture(tester, 'touch-records-${width.toInt()}');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
      folder.deleteSync(recursive: true);
    });
  }
}
