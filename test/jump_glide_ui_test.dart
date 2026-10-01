import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/jump_glide_hud.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/match_hud.dart';
import 'package:push_up_bird/ui/flight_score.dart';
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SessionSource, SilentAudio, startFlight;

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
    testWidgets('compact jump meter stays clear of gameplay at at $width', (
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
      final source = SessionSource();
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          audioFactoryProvider.overrideWithValue(SilentAudio.new),
          trackingSourceFactoryProvider.overrideWithValue(() => source),
        ],
      );
      await container.read(progressProvider.future);
      appRouter.go('/play/jump');
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
      expect(find.textContaining('3s glide'), findsOneWidget);
      expect(find.textContaining('Stars add 0.75s'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'charged-jump-setup-${width.toInt()}');
      final dynamic state = tester.state(find.byType(PlayScreen));
      final controller = state.controller as PlayController;
      await tester.runAsync(() => startFlight(controller, source));
      await tester.pump();
      final game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(() => game.loaded);
      game.pauseEngine();
      await tester.pump();
      expect(find.byType(JumpGlideHud), findsOneWidget);
      expect(find.text('Jump'), findsOneWidget);
      final sim = controller.simulation!;
      Future<void> redraw() async {
        game.resumeEngine();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        game.pauseEngine();
        await tester.pump();
      }

      source.time += 1;
      sim.apply(
        const MovementInput(valid: true, flap: true),
        TrackingSample(
          mode: PlayMode.jump,
          timestampMs: source.time,
          receivedMs: source.time,
          joints: [],
        ),
        source.time,
      );
      controller.notify();
      await tester.pump();
      expect(find.text('Stars extend your glide'), findsNothing);
      expect(find.text('3.0s'), findsOneWidget);
      void advance(double seconds) {
        for (var i = 0; i < (seconds * 50).round(); i++) {
          source.time += 20;
          source.sampleStream.add(
            TrackingSample(
              mode: PlayMode.jump,
              timestampMs: source.time,
              receivedMs: source.time,
              joints: [],
            ),
          );
          controller.advance(.02, source.time, 2.2);
        }
        controller.notify();
      }

      advance(1.5);
      await redraw();
      expect(
        tester
            .widget<MatchMeter>(
              find.descendant(
                of: find.byType(JumpGlideHud),
                matching: find.byType(MatchMeter),
              ),
            )
            .label,
        startsWith('Glide,'),
      );
      expect(tester.takeException(), isNull);
      final meter = tester.getRect(
        find.byKey(const ValueKey('jump-glide-meter')),
      );
      for (final other in [
        find.byKey(const ValueKey('match-health')),
        find.byType(FlightScore),
        find.byTooltip('Pause flight'),
      ]) {
        expect(meter.overlaps(tester.getRect(other)), isFalse);
      }
      await capture(tester, 'charged-jump-gliding-${width.toInt()}');
      sim.stars.add(SkyStar(x: FlightSimulation.birdX, y: sim.birdY));
      final before = sim.glideRemaining;
      advance(.02);
      await redraw();
      expect(sim.glideRemaining, greaterThan(before));
      expect(
        find.text('${sim.glideRemaining.toStringAsFixed(1)}s'),
        findsOneWidget,
      );
      await capture(tester, 'charged-jump-star-${width.toInt()}');
      advance(3);
      await redraw();
      expect(
        tester
            .widget<MatchMeter>(
              find.descendant(
                of: find.byType(JumpGlideHud),
                matching: find.byType(MatchMeter),
              ),
            )
            .label,
        startsWith('Glide ending,'),
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'charged-jump-ending-${width.toInt()}');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
    });
  }
}
