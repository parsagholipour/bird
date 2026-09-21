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
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/record_chase.dart';
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SessionSource, SilentAudio, startFlight;

class RecordAudio extends SilentAudio {
  final effects = <String>[];
  @override
  void effect(String name) => effects.add(name);
  int get records => effects.where((name) => name == 'record').length;
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

  for (final scenario in [
    (course: FlightCourse.classic, mode: PlayMode.pushUp, practice: false),
    (course: FlightCourse.starTrail, mode: PlayMode.jump, practice: false),
    (course: FlightCourse.skyCourier, mode: PlayMode.pushUp, practice: false),
    (course: FlightCourse.starTrail, mode: PlayMode.pushUp, practice: true),
    (course: FlightCourse.cloudCruise, mode: PlayMode.pushUp, practice: false),
  ]) {
    final scored = !scenario.practice && !scenario.course.relaxed;
    testWidgets('record chase: ${scenario.course} ${scenario.mode} $scored', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime(2026, 9, 16, 12);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
        clock: () => now,
      );
      // Deliberately different records prove the target uses this control and course.
      for (final course in FlightCourse.values.where((c) => !c.relaxed)) {
        for (final mode in PlayMode.values) {
          await repo.saveRun(
            RunResult(
              id: '${course.name}-${mode.name}',
              mode: mode,
              course: course,
              practice: false,
              score: course == scenario.course && mode == scenario.mode
                  ? 14
                  : 99,
              repetitions: 1,
              flaps: 1,
              durationSeconds: 20,
              reason: EndReason.quit,
              finishedAt: now.subtract(const Duration(days: 1)),
            ),
          );
        }
      }
      await repo.setSetting(SettingKey.reducedMotion, true);
      final source = SessionSource();
      final audio = RecordAudio();
      final folder = Directory.systemTemp.createTempSync('record-chase');
      final container = ProviderContainer(
        overrides: [
          appClockProvider.overrideWithValue(() => now),
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(folder),
          ),
          trackingSourceFactoryProvider.overrideWithValue(() => source),
          audioFactoryProvider.overrideWithValue(() => audio),
        ],
      );
      await container.read(progressProvider.future);
      appRouter.go(
        '/play/${scenario.mode.name}?course=${scenario.course.name}&practice=${scenario.practice}',
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
      final dynamic state = tester.state(find.byType(PlayScreen));
      final controller = state.controller as PlayController;

      Future<void> fly() async {
        await tester.runAsync(() => startFlight(controller, source));
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
        await tester.pump();
      }

      await fly();
      if (scored) {
        expect(find.text('0/3 flight wings'), findsOneWidget);
        expect(find.text('Best 14'), findsOneWidget);
        expect(find.text('15 to a new record'), findsOneWidget);
      } else {
        expect(find.byType(RecordChase), findsNothing);
        expect(find.text('0/3 flight wings'), findsNothing);
      }
      final sim = controller.simulation!;
      sim.elapsed = 24;
      sim.birdY = .45;
      for (final score in [13, 14, 16, 21]) {
        sim.score = score;
        controller.notify();
        final game = state.game as BirdGame;
        game.resumeEngine();
        await tester.pump(const Duration(milliseconds: 16));
        game.pauseEngine();
        await tester.pumpAndSettle();
        if (scored) {
          expect(audio.records, score > 14 ? 1 : 0);
          expect(
            find.text(
              score > 14
                  ? '+${score - 14} beyond your best'
                  : score == 14
                  ? 'One more for a record'
                  : '2 to a new record',
            ),
            findsOneWidget,
          );
          final target = tester.getRect(find.byType(RecordChase));
          final scoreRect = tester.getRect(find.text('$score'));
          expect(target.overlaps(scoreRect), isFalse);
          expect(target.left, greaterThan(350));
          expect(target.right, lessThan(650));
          await capture(tester, 'record-${scenario.course.name}-$score');
        } else {
          expect(find.byType(RecordChase), findsNothing);
          expect(audio.records, 0);
        }
        expect(tester.takeException(), isNull);
      }
      controller.notify();
      controller.notify();
      expect(audio.records, scored ? 1 : 0);

      if (scored) {
        await tester.runAsync(controller.finish);
        await tester.pumpAndSettle();
        expect(
          container
              .read(progressProvider)
              .requireValue
              .record(scenario.mode, scenario.course)
              .best,
          21,
        );
        await tester.runAsync(controller.retry);
        await tester.pump();
        await fly();
        expect(find.text('0/3 flight wings'), findsOneWidget);
        expect(find.text('Best 21'), findsOneWidget);
        expect(find.text('22 to a new record'), findsOneWidget);
        controller.simulation!.score = 22;
        controller.notify();
        await tester.pumpAndSettle();
        expect(find.text('New best!'), findsOneWidget);
        expect(audio.records, 2);
      }
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.runAsync(() async {
        await repo.close();
        await folder.delete(recursive: true);
      });
    });
  }
}
