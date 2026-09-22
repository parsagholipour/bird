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
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/flight_portrait.dart';
import 'package:push_up_bird/ui/replay_screen.dart';
import 'experience_ui_test.dart' show capture, WingAudio;
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
  for (final mode in PlayMode.values) {
    testWidgets(
      'saved Courier $mode replay shows letters and deliveries after seeking',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        double now = 0;
        double? aboard, delivered;
        final tape = ReplayTape(
          mode: mode,
          practice: false,
          seed: 18,
          cycleSeconds: 3,
          bird: 1,
          reducedMotion: true,
          originMs: 0,
          course: FlightCourse.skyCourier,
        );
        final recorder = FlightRecorder(tape, () => now);
        for (var i = 0; i < 2000; i++) {
          now += 20;
          final sim = recorder.simulation;
          final ahead = sim.obstacles.where((o) => !o.scored);
          final target = ahead.isEmpty ? .5 : ahead.first.target;
          // Start the larger jump below the passage, then glide through it.
          final flapAt = (target + (mode == PlayMode.jump ? .13 : 0)).clamp(
            .15,
            .88,
          );
          recorder.apply(
            MovementInput(
              valid: true,
              height: (.85 - target) / .7,
              flap:
                  !mode.controlsHeight &&
                  sim.birdY > flapAt &&
                  sim.velocity >= 0,
            ),
            TrackingSample(
              mode: mode,
              timestampMs: now,
              receivedMs: now,
              joints: const [],
            ),
            now,
          );
          recorder.tick(.02, now, 2.2);
          if (sim.carryingLetter) aboard ??= now;
          if (sim.score == 1) delivered ??= now;
        }
        expect(aboard, isNotNull);
        expect(delivered, isNotNull);
        recorder.command('end', EndReason.quit);
        final sim = recorder.simulation;
        final folder = Directory.systemTemp.createTempSync('courier-replay-ui');
        final sessions = SessionRepository(folder);
        await tester.runAsync(
          () => sessions.save(
            SavedSession(
              result: RunResult(
                id: 'courier-replay',
                mode: mode,
                practice: false,
                course: FlightCourse.skyCourier,
                score: sim.score,
                gates: sim.gates,
                repetitions: 0,
                flaps: sim.flaps,
                durationSeconds: sim.elapsed,
                reason: EndReason.quit,
                finishedAt: DateTime.now(),
              ),
              tape: tape,
              clips: [],
            ),
          ),
        );
        final repo = SqliteProgressRepository(
          ProgressDatabase(NativeDatabase.memory()),
        );
        final audio = WingAudio();
        final container = ProviderContainer(
          overrides: [
            progressRepositoryProvider.overrideWithValue(repo),
            sessionRepositoryProvider.overrideWithValue(sessions),
            audioFactoryProvider.overrideWithValue(() => audio),
          ],
        );
        await container.read(progressProvider.future);
        appRouter.go('/replay/courier-replay');
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
          for (
            var i = 0;
            i < 20 && find.byType(Slider).evaluate().isEmpty;
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            await tester.pump();
          }
          final game = tester
              .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
              .game!;
          await game.loaded.timeout(const Duration(seconds: 5));
        });
        await tester.pump();
        expect(find.byType(ReplayScreen), findsOneWidget);
        expect(find.text('DELIVERIES'), findsOneWidget);
        for (final (position, cargo, score) in [
          (aboard!, true, 0),
          (delivered!, false, 1),
          (aboard, true, 0),
        ]) {
          tester.widget<Slider>(find.byType(Slider)).onChanged!(position);
          await tester.pump(const Duration(milliseconds: 16));
          final game = tester
              .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
              .game!;
          expect(game.simulation.carryingLetter, cargo);
          expect(game.simulation.score, score);
          expect(
            find.textContaining(cargo ? 'Letter aboard' : 'Find a pickup'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          if (!cargo) await capture(tester, 'courier-delivered-${mode.name}');
        }
        await capture(tester, 'courier-replay-${mode.name}');
        expect(audio.wings, 0, reason: 'Scrubbing is silent');
        tester.widget<Slider>(find.byType(Slider)).onChanged!(delivered - 40);
        await tester.pump();
        await tester.tap(find.byTooltip('Play replay'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(audio.wings, 1);
        await tester.pump(const Duration(milliseconds: 100));
        expect(audio.wings, 1);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.runAsync(() async {
          await repo.close();
          await folder.delete(recursive: true);
        });
      },
    );
    testWidgets(
      'Courier $mode flows through setup, cargo, results and records',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final folder = Directory.systemTemp.createTempSync('courier-ui');
        final repo = SqliteProgressRepository(
          ProgressDatabase(NativeDatabase.memory()),
        );
        await repo.setSetting(SettingKey.reducedMotion, true);
        final source = SessionSource();
        final container = ProviderContainer(
          overrides: [
            progressRepositoryProvider.overrideWithValue(repo),
            sessionRepositoryProvider.overrideWithValue(
              SessionRepository(folder),
            ),
            audioFactoryProvider.overrideWithValue(SilentAudio.new),
            trackingSourceFactoryProvider.overrideWithValue(() => source),
          ],
        );
        await container.read(progressProvider.future);
        appRouter.go(
          '/play/${switch (mode) {
            PlayMode.pushUp => 'push-up',
            PlayMode.jump => 'jump',
            PlayMode.touch => 'touch',
            PlayMode.squat => 'squat',
          }}?course=skyCourier',
        );
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
        expect(
          find.textContaining(
            mode == PlayMode.touch
                ? 'Tap the sky to flap. Tap Shoot'
                : 'Clear a pickup gate',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await capture(tester, 'courier-setup-${mode.name}');
        final dynamic state = tester.state(find.byType(PlayScreen));
        final controller = state.controller as PlayController;
        expect(controller.mode, mode);
        expect(controller.course, FlightCourse.skyCourier);
        if (mode == PlayMode.touch) {
          await controller.fly();
          for (var i = 0; i < 150; i++) {
            controller.advance(.02, controller.nowMs, 2.2);
          }
          await source.dispose();
        } else {
          await tester.runAsync(() => startFlight(controller, source));
        }
        await tester.runAsync(() async {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        final game = tester
            .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
            .game!;
        await tester.runAsync(
          () => game.loaded.timeout(const Duration(seconds: 5)),
        );
        game.pauseEngine();
        final sim = controller.simulation!;
        sim.elapsed = 25;
        sim.birdY = mode == PlayMode.pushUp ? .15 : .45;
        sim.obstacles.clear();
        sim.obstacles.addAll([
          Obstacle(
            x: 1.3,
            center: mode == PlayMode.pushUp ? .25 : .45,
            gap: .48,
            target: sim.birdY,
            courierStop: CourierStop.pickup,
          ),
          Obstacle(
            x: 2.05,
            center: mode == PlayMode.pushUp ? .75 : .55,
            gap: .48,
            target: mode == PlayMode.pushUp ? .85 : .55,
            courierStop: CourierStop.postbox,
          ),
        ]);
        Future<void> redraw() async {
          controller.notify();
          game.resumeEngine();
          await tester.pump(const Duration(milliseconds: 16));
          game.pauseEngine();
          await tester.pump();
        }

        await redraw();
        expect(find.byKey(const ValueKey('flight-clock')), findsNothing);
        expect(find.text('1.06× pace'), findsNothing);
        expect(find.text('Pick up'), findsOneWidget);
        expect(find.text('Shield ready'), findsNothing);
        expect(tester.takeException(), isNull);
        await capture(tester, 'courier-empty-${mode.name}');
        sim.carryingLetter = true;
        sim.lettersCollected = 4;
        sim.score = 3;
        sim.gates = 7;
        sim.perfectPasses = 2;
        await redraw();
        expect(find.text('Deliver'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(tester, 'courier-carrying-${mode.name}');
        sim.carryingLetter = false;
        sim.courierBumps = 1;
        sim.lettersDropped = 1;
        sim.invulnerableUntil = sim.elapsed + 1;
        sim.events.add(
          FlightEvent(FlightEventKind.letterLost, sim.elapsed, sim.birdY),
        );
        await redraw();
        expect(tester.takeException(), isNull);
        await capture(tester, 'courier-drop-${mode.name}');
        sim.elapsed = 73;
        await redraw();
        await capture(tester, 'courier-arrival-hud-${mode.name}');
        await tester.runAsync(() async {
          sim.elapsed = 75;
          controller.recorder!.command('end', EndReason.completed);
          await controller.finish();
        });
        await tester.pumpAndSettle();
        expect(find.text('DELIVERIES'), findsOneWidget);
        expect(find.text('7 gates cleared'), findsOneWidget);
        expect(find.text('75s'), findsOneWidget);
        expect(
          tester
              .widget<FlightPortrait>(find.byType(FlightPortrait))
              .arrivedCourse,
          FlightCourse.skyCourier,
        );
        expect(tester.takeException(), isNull);
        await capture(tester, 'courier-results-${mode.name}');
        final p = container.read(progressProvider).requireValue;
        expect(p.record(mode, FlightCourse.skyCourier).best, 3);
        expect(p.record(mode).best, 0);
        appRouter.go('/records');
        await tester.pumpAndSettle();
        expect(find.text('Your star points to beat'), findsOneWidget);
        expect(find.text('Courier'), findsNothing);
        expect(tester.takeException(), isNull);
        await capture(tester, 'courier-records-${mode.name}');
        appRouter.go('/');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('play')), findsOneWidget);
        expect(find.text('Deliver some joy'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.runAsync(() async {
          await repo.close();
          await folder.delete(recursive: true);
        });
      },
    );
  }
}
