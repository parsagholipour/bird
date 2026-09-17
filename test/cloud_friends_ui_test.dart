import 'dart:io';
import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/domain/replay_highlights.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/replay_screen.dart';
import 'cloud_friends_test.dart' show recordCloudCruise;
import 'experience_ui_test.dart' show capture, WingAudio;
import 'fake_video_platform.dart';

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

  testWidgets('Cruise counter leaves all camera corners visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    VideoPlayerPlatform.instance = FakeVideoPlatform();
    final folder = Directory.systemTemp.createTempSync('cloud-camera-ui');
    final camera = File('${folder.path}/source.mp4')..writeAsBytesSync([0]);
    final sessions = SessionRepository(folder);
    await tester.runAsync(
      () => sessions.save(
        SavedSession(
          result: RunResult(
            id: 'cloud-camera',
            mode: PlayMode.pushUp,
            practice: true,
            course: FlightCourse.cloudCruise,
            score: 0,
            repetitions: 0,
            flaps: 0,
            durationSeconds: 10,
            reason: EndReason.quit,
            finishedAt: DateTime.now(),
          ),
          tape: ReplayTape(
            mode: PlayMode.pushUp,
            practice: true,
            seed: 1,
            cycleSeconds: 3,
            bird: 0,
            reducedMotion: true,
            originMs: 0,
            course: FlightCourse.cloudCruise,
            events: [
              [10000, 'end', 'quit'],
            ],
          ),
          clips: [
            SessionClip(path: camera.path, startMs: 0, durationMs: 10000),
          ],
        ),
      ),
    );
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(sessions),
        audioFactoryProvider.overrideWithValue(WingAudio.new),
      ],
    );
    await container.read(progressProvider.future);
    appRouter.go('/replay/cloud-camera');
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
        i < 30 &&
            find
                .byKey(const ValueKey('replay-camera-inset'))
                .evaluate()
                .isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
      await tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!
          .loaded;
    });
    await tester.pump();
    final score = find.byKey(const ValueKey('replay-score'));
    final inset = find.byKey(const ValueKey('replay-camera-inset'));
    for (var corner = 0; corner < 4; corner++) {
      expect(
        tester.getRect(score).overlaps(tester.getRect(inset)),
        isFalse,
        reason: 'Corner $corner must not be covered by the counter',
      );
      if (corner == 0) await capture(tester, 'cloud-replay-camera');
      await tester.tap(find.byTooltip('Move camera corner'));
      await tester.pump();
    }
    tester
        .widget<DropdownButton<ReplayView>>(
          find.byType(DropdownButton<ReplayView>),
        )
        .onChanged!(ReplayView.gameplay);
    await tester.pump();
    expect(inset, findsNothing);
    expect(tester.getRect(score).left, greaterThan(600));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(() async {
      await repo.close();
      await folder.delete(recursive: true);
    });
  });

  for (final mode in PlayMode.values) {
    testWidgets('saved $mode cruise replays its cloud friends and greeting', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final trip = recordCloudCruise(mode);
      final folder = Directory.systemTemp.createTempSync('cloud-replay-ui');
      final sessions = SessionRepository(folder);
      await tester.runAsync(
        () => sessions.save(
          SavedSession(
            result: RunResult(
              id: 'cloud-replay',
              mode: mode,
              practice: true,
              course: FlightCourse.cloudCruise,
              score: 0,
              repetitions: 0,
              flaps: 0,
              durationSeconds: trip.tape.durationMs / 1000,
              reason: EndReason.quit,
              finishedAt: DateTime.now(),
            ),
            tape: trip.tape,
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
      appRouter.go('/replay/cloud-replay');
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
        for (var i = 0; i < 30 && find.byType(Slider).evaluate().isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
        await tester
            .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
            .game!
            .loaded
            .timeout(const Duration(seconds: 5));
      });
      await tester.pump();
      expect(find.byType(ReplayScreen), findsOneWidget);
      for (final count in [0, 2, 1, 3]) {
        tester.widget<Slider>(find.byType(Slider)).onChanged!(
          trip.discoveredAt[count]!,
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('$count/3 cloud friends'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(audio.clouds, 0, reason: 'Seeking is silent');
      tester.widget<Slider>(find.byType(Slider)).onChanged!(
        trip.discoveredAt[1]! - 1200,
      );
      await tester.pump();
      await capture(tester, 'cloud-friends-replay-${mode.name}');
      tester.widget<Slider>(find.byType(Slider)).onChanged!(
        trip.discoveredAt[1]! - 40,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Play replay'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(audio.clouds, 1);
      expect(find.text('1/3 cloud friends'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(audio.clouds, 1);
      await tester.runAsync(() async {
        for (
          var i = 0;
          i < 40 && find.byTooltip('Flight highlights').evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      await tester.tap(find.byTooltip('Flight highlights'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Flight highlights'), findsOneWidget);
      expect(find.byTooltip('Play replay'), findsOneWidget);
      expect(audio.clouds, 1, reason: 'Opening highlights pauses silently');
      await capture(tester, 'cloud-highlights-${mode.name}');
      await tester.tap(find.byTooltip('Close highlights'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byTooltip('Play replay'), findsOneWidget);
      await tester.tap(find.byTooltip('Flight highlights'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Cloud Whale'));
      await tester.pump();
      expect(find.byTooltip('Pause replay'), findsOneWidget);
      expect(
        tester.widget<Slider>(find.byType(Slider)).value,
        closeTo(trip.discoveredAt[1]! - 1500, 100),
      );
      for (var i = 0; i < 18; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        audio.clouds,
        2,
        reason: 'The selected moment plays from its lead-in',
      );
      await tester.tap(find.byTooltip('Pause replay'));
      await tester.pump();
      final firstTrio = buildReplayHighlights(
        trip.tape,
      ).firstWhere((m) => m.kind == ReplayMomentKind.starTrio);
      final trioSounds = audio.trios;
      tester.widget<Slider>(find.byType(Slider)).onChanged!(firstTrio.atMs);
      await tester.pump();
      expect(
        audio.trios,
        trioSounds,
        reason: 'Seeking across a trio stays silent',
      );
      tester.widget<Slider>(find.byType(Slider)).onChanged!(
        firstTrio.atMs - 40,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Play replay'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(audio.trios, trioSounds + 1);
      await capture(tester, 'star-trio-replay-${mode.name}');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        audio.trios,
        trioSounds + 1,
        reason: 'Trio celebration never repeats on the next frame',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.runAsync(() async {
        await repo.close();
        await folder.delete(recursive: true);
      });
    });
  }
}
