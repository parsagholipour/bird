import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'fake_video_platform.dart';
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
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/replay_screen.dart';
import 'package:push_up_bird/tracking/tracking_api.g.dart';
import 'play_session_test.dart' show SessionSource, SilentAudio, startFlight;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });
  testWidgets('save action and replay controls fit a small landscape phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = Directory.systemTemp.createTempSync('replay-ui');
    final video = FakeVideoPlatform();
    VideoPlayerPlatform.instance = video;
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    await repo.setSetting(SettingKey.reducedMotion, true);
    final sessions = SessionRepository(root);
    final source = SessionSource();
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(sessions),
        audioFactoryProvider.overrideWithValue(SilentAudio.new),
        trackingSourceFactoryProvider.overrideWithValue(() => source),
      ],
    );
    await container.read(progressProvider.future);
    appRouter.go('/play/pushUp');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: ValueKey('capture'),
          child: PushUpBirdApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final dynamic screenState = tester.state(find.byType(PlayScreen));
    final controller = screenState.controller as PlayController;
    expect(source.microphoneRequests, 0);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(
      find.textContaining('Add your voice and room sound'),
      findsOneWidget,
    );
    await capture(tester, '/tmp/push-up-bird-microphone-setup.png');
    source.micAccess = MicrophoneAccess.permanentlyDenied;
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Microphone settings'), findsOneWidget);
    await capture(tester, '/tmp/push-up-bird-microphone-denied.png');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(tester.takeException(), isNull);
    source.micAccess = MicrophoneAccess.granted;
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(source.microphoneRequests, 2);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(
      container.read(progressProvider).requireValue.settings.recordAudio,
      isTrue,
    );
    await tester.runAsync(() async {
      await startFlight(controller, source);
      await controller.finish();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Save session'), findsOneWidget);
    controller.cameraRecordingError =
        'Camera video unavailable. Gameplay can still be saved.';
    controller.notify();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Save session').hitTestable(), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Save session'));
      for (var i = 0; i < 50 && !controller.sessionSaved; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Session saved · Watch in Records'), findsOneWidget);
    expect(find.text('Watch replay').hitTestable(), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Watch replay'));
      for (
        var i = 0;
        i < 20 && find.byType(ReplayScreen).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    expect(find.byType(ReplayScreen), findsOneWidget);
    await tester.runAsync(() => container.read(sessionsProvider.future));
    appRouter.go('/sessions');
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Saved sessions'), findsOneWidget);
    // Add a standalone gameplay replay and open it through the real saved route.
    final tape = ReplayTape(
      mode: PlayMode.pushUp,
      practice: false,
      seed: 1,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: true,
      originMs: 0,
      events: [
        [10000, 'end', 'quit'],
      ],
    );
    final camera = File('${root.path}/source.mp4')..writeAsBytesSync([0]);
    await tester.runAsync(
      () => sessions.save(
        SavedSession(
          result: RunResult(
            id: 'ui-replay',
            mode: PlayMode.pushUp,
            practice: false,
            score: 0,
            repetitions: 0,
            flaps: 0,
            durationSeconds: 10,
            reason: EndReason.quit,
            finishedAt: DateTime.now(),
          ),
          tape: tape,
          clips: [
            SessionClip(
              path: camera.path,
              startMs: 0,
              durationMs: 10000,
              hasAudio: true,
            ),
          ],
        ),
      ),
    );
    appRouter.go('/replay/ui-replay');
    await tester.pump();
    await tester.runAsync(() async {
      for (
        var i = 0;
        i < 10 &&
            find
                .byWidgetPredicate((widget) => widget is GameWidget)
                .evaluate()
                .isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
      final game = tester
          .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget),
          )
          .game!;
      await (game as FlameGame).loaded;
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ReplayScreen), findsOneWidget);
    expect(find.text('Corner camera'), findsOneWidget);
    expect(video.volume, 1);
    expect(video.mixedAudio, isTrue);
    final gameFinder = find.byWidgetPredicate((widget) => widget is GameWidget);
    final tapSurface = find.byKey(const ValueKey('replay-tap-surface'));
    final controls = find.byKey(const ValueKey('replay-controls'));
    final score = find.byKey(const ValueKey('replay-score'));
    expect(score, findsOneWidget);
    expect(
      find.descendant(of: score, matching: find.text('0')),
      findsOneWidget,
    );
    final gameBounds = tester.getRect(gameFinder);
    final semantics = tester.ensureSemantics();
    expect(gameBounds.height, greaterThan(300));
    expect(gameBounds.overlaps(tester.getRect(controls)), isTrue);
    await tester.tap(tapSurface);
    await tester.pump();
    expect(find.byType(Slider), findsNothing);
    expect(find.byTooltip('Back to saved sessions'), findsNothing);
    expect(find.text('REPLAY'), findsNothing);
    expect(score, findsOneWidget);
    expect(find.bySemanticsLabel('Score: 0'), findsOneWidget);
    expect(find.bySemanticsLabel('Show replay controls'), findsOneWidget);
    semantics.dispose();
    expect(tester.getRect(gameFinder), gameBounds);
    await tester.tap(tapSurface);
    await tester.pump();
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.getRect(gameFinder), gameBounds);
    await tester.tap(find.byTooltip('Hide controls / full screen'));
    await tester.pump();
    expect(controls, findsNothing);
    expect(tester.getRect(gameFinder), gameBounds);
    await tester.tap(tapSurface);
    await tester.pump();
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pump();
    expect(controls, findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, greaterThan(0));
    expect(find.byTooltip('Play replay'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart replay'));
    await tester.pump();
    await tester.tap(find.text('1.0x'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('1.5x').last);
    await tester.pump();
    expect(controls, findsOneWidget);
    expect(
      tester
          .widget<DropdownButton<double>>(find.byType(DropdownButton<double>))
          .value,
      1.5,
    );
    await tester.tap(find.text('1.5x'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('1.0x').last);
    await tester.pump();
    await tester.tap(find.text('Corner camera'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Camera background').last);
    await tester.pump();
    expect(controls, findsOneWidget);
    expect(find.byTooltip('Move camera corner'), findsNothing);
    expect(score, findsOneWidget);
    await tester.tap(find.text('Camera background'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Gameplay only').last);
    await tester.pump();
    expect(find.byTooltip('Mute recorded audio'), findsOneWidget);
    expect(score, findsOneWidget);
    await tester.tap(find.byTooltip('Mute recorded audio'));
    await tester.pump();
    expect(video.volume, 0);
    expect(video.playing, isFalse);
    await tester.tap(find.byTooltip('Enable recorded audio'));
    await tester.pump();
    expect(video.volume, 1);
    await tester.tap(find.byTooltip('Play replay'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Pause replay'), findsOneWidget);
    final beforeHiding = tester.widget<Slider>(find.byType(Slider)).value;
    await tester.tap(tapSurface);
    await tester.pump(const Duration(milliseconds: 500));
    expect(controls, findsNothing);
    expect(score, findsOneWidget);
    expect(tester.getRect(gameFinder), gameBounds);
    await tester.tap(tapSurface);
    await tester.pump();
    expect(find.byTooltip('Pause replay'), findsOneWidget);
    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      greaterThan(beforeHiding),
    );
    await tester.tap(find.byTooltip('Mute game sound'));
    await tester.pump();
    expect(find.byTooltip('Enable game sound'), findsOneWidget);
    expect(video.volume, 1);
    expect(video.playing, isTrue);
    await tester.tap(find.byTooltip('Forward 5 seconds'));
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, greaterThan(5000));
    await tester.tap(find.byTooltip('Restart replay'));
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 0);
    expect(controls, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Pause replay'));
    await tester.pump();
    await tester.tap(find.text('Gameplay only'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Corner camera').last);
    await tester.pump();
    expect(video.playing, isFalse);
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '/tmp/push-up-bird-replay.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
    tester.view.physicalSize = const Size(568, 320);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.byTooltip('Hide controls / full screen').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back to saved sessions'));
    await tester.pump();
    expect(find.byType(SessionLibraryScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
    root.deleteSync(recursive: true);
  });
}

Future<void> capture(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}
