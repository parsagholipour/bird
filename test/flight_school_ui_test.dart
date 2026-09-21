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
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/flight_school_screen.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SilentAudio, SessionSource;

class SchoolAudio extends SilentAudio {
  final cues = <String>[];
  @override
  void effect(String name) => cues.add(name);
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

  for (final width in [640.0, 800.0]) {
    testWidgets(
      'touch school at $width works without camera or saved progress',
      (tester) async {
        tester.view.physicalSize = Size(width, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = SqliteProgressRepository(
          ProgressDatabase(NativeDatabase.memory()),
        );
        await repo.setSetting(SettingKey.reducedMotion, true);
        final folder = Directory.systemTemp.createTempSync('flight-school');
        final sessions = SessionRepository(folder);
        final audio = SchoolAudio();
        var cameras = 0;
        final container = ProviderContainer(
          overrides: [
            progressRepositoryProvider.overrideWithValue(repo),
            sessionRepositoryProvider.overrideWithValue(sessions),
            audioFactoryProvider.overrideWithValue(() => audio),
            trackingSourceFactoryProvider.overrideWithValue(() {
              cameras++;
              return SessionSource();
            }),
          ],
        );
        final before = await container.read(progressProvider.future);
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
        await capture(tester, 'school-home-${width.toInt()}');
        await tester.tap(find.text('Flight school'));
        Future<BirdGame> loaded() async {
          await tester.runAsync(() async {
            await tester.pump();
            await Future<void>.delayed(const Duration(milliseconds: 30));
          });
          final game = tester
              .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
              .game!;
          await tester.runAsync(() => game.loaded);
          await tester.pump();
          return game;
        }

        var game = await loaded();
        expect(find.byType(FlightSchoolScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('school-course')), findsNothing);
        expect(cameras, 0);
        expect(tester.takeException(), isNull);
        await capture(tester, 'school-intro-${width.toInt()}');
        await tester.tap(find.text('Start lesson'));
        for (var i = 0; i < 34; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(game.simulation.phase, RunPhase.playing);
        await tester.dragFrom(Offset(width * .6, 200), const Offset(0, -120));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.simulation.birdY, lessThan(.3));
        await capture(tester, 'school-flight-${width.toInt()}');
      await tester.tap(find.byTooltip('Pause lesson').first);
        await tester.pump();
        final time = game.simulation.elapsed;
        await tester.pump(const Duration(milliseconds: 300));
        expect(game.simulation.elapsed, time);
        await capture(tester, 'school-paused-${width.toInt()}');
        expect(find.text('Try with jumps'), findsOneWidget);
        await tester.tap(find.text('Continue lesson'));
        for (var i = 0; i < 32; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expect(game.simulation.phase, RunPhase.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(game.simulation.phase, RunPhase.paused);
      await tester.tap(find.byTooltip('Restart lesson').first);
        game = await loaded();
        expect(game.simulation.score, 0);
        expect(find.text('Start lesson'), findsOneWidget);
        await tester.tap(find.text('Tap to flap'));
        game = await loaded();
        await tester.tap(find.text('Start lesson'));
        for (var i = 0; i < 34; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tapAt(Offset(width * .65, 180));
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.simulation.flaps, 1);
        expect(audio.cues, contains('flap'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(game.simulation.flaps, 1);
        game.simulation.end(EndReason.completed);
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('Lesson complete!'), findsOneWidget);
        await capture(tester, 'school-complete-${width.toInt()}');
        expect(
          cameras,
          0,
          reason: 'No tracking source is created anywhere in the lesson',
        );
        final after = await container.read(progressRepositoryProvider).load();
        expect(after.totalObstacles, before.totalObstacles);
      expect(after.recent, before.recent);
        expect(await tester.runAsync(() => sessions.list()), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Try with jumps'));
        await tester.pump();
        expect(find.byType(PlayScreen), findsOneWidget);
        final play = tester.widget<PlayScreen>(find.byType(PlayScreen));
        expect(play.practice, isTrue);
        expect(play.course, FlightCourse.starTrail);
        expect(
          cameras,
          1,
          reason: 'Only the explicit camera-practice handoff creates tracking',
        );
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
