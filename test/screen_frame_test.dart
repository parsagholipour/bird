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
import 'package:push_up_bird/ui/screen_frame.dart';
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SilentAudio;

void main() {
  const probe = ValueKey('probe');

  Future<MediaQueryData> frame(
    WidgetTester tester,
    Size screen, {
    double ratio = 1,
    FakeViewPadding padding = FakeViewPadding.zero,
    FakeViewPadding gestures = FakeViewPadding.zero,
  }) async {
    tester.view.physicalSize = screen * ratio;
    tester.view.devicePixelRatio = ratio;
    tester.view.padding = padding;
    tester.view.systemGestureInsets = gestures;
    addTearDown(tester.view.reset);
    late MediaQueryData inside;
    await tester.pumpWidget(
      ScreenFrame(
        child: Builder(
          builder: (context) {
            inside = MediaQuery.of(context);
            return const SizedBox.expand(key: probe);
          },
        ),
      ),
    );
    return inside;
  }

  testWidgets('the reference phone passes straight through', (tester) async {
    final inside = await frame(tester, const Size(792, 360), ratio: 3);
    expect(inside.size, ScreenFrame.design);
    expect(inside.devicePixelRatio, 3);
    expect(find.byType(FittedBox), findsNothing);
    expect(tester.getRect(find.byKey(probe)), Offset.zero & ScreenFrame.design);
  });

  for (final screen in const [
    Size(640, 360), // 16:9 phone
    Size(864, 360), // 2.4 phone
    Size(1000, 450),
    Size(1024, 768), // 4:3 tablet
    Size(1280, 800),
    Size(800, 1280), // a tablet that ignored the landscape lock
  ]) {
    testWidgets('a ${screen.width.toInt()}×${screen.height.toInt()} display '
        'shows the reference phone, scaled and centred', (tester) async {
      final inside = await frame(tester, screen, ratio: 2);
      final s = ScreenFrame.scaleFor(screen);
      expect(inside.size, ScreenFrame.design);
      expect(inside.devicePixelRatio, closeTo(2 * s, 1e-9));
      final shown = tester.getRect(find.byKey(probe));
      expect(shown.width, closeTo(792 * s, .01));
      expect(shown.height, closeTo(360 * s, .01));
      expect(shown.center.dx, closeTo(screen.width / 2, .01));
      expect(shown.center.dy, closeTo(screen.height / 2, .01));
      // One side always fills the display; the other gets equal bars.
      expect(
        shown.width >= screen.width - .01 ||
            shown.height >= screen.height - .01,
        isTrue,
      );
      expect(inside.padding, EdgeInsets.zero);
    });
  }

  testWidgets('insets the bars already cover vanish inside the frame', (
    tester,
  ) async {
    // 2.4 wide: 36 dp bars each side, so a 40 dp notch pokes in 4 dp.
    var inside = await frame(
      tester,
      const Size(864, 360),
      padding: const FakeViewPadding(left: 40),
      gestures: const FakeViewPadding(bottom: 20),
    );
    expect(inside.padding.left, closeTo(4, 1e-9));
    expect(inside.padding.right, 0);
    expect(inside.systemGestureInsets.bottom, closeTo(20, 1e-9));
    // 16:9: no side bars, so the notch scales up into frame units, while
    // the 34.5 dp top and bottom bars swallow the gesture strip.
    inside = await frame(
      tester,
      const Size(640, 360),
      padding: const FakeViewPadding(left: 40),
      gestures: const FakeViewPadding(bottom: 20),
    );
    final s = ScreenFrame.scaleFor(const Size(640, 360));
    expect(inside.padding.left, closeTo(40 / s, 1e-9));
    expect(inside.systemGestureInsets.bottom, 0);
  });

  testWidgets('a tap on a bar lands on the nearest edge of the picture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final taps = <Offset>[];
    await tester.pumpWidget(
      ScreenFrame(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => taps.add(e.localPosition),
        ),
      ),
    );
    // 1024 × 768 shows the picture 1024 × 465.5, so 151 dp bars sit above
    // and below it.
    for (final at in const [Offset(512, 2), Offset(512, 766), Offset(2, 2)]) {
      await tester.tapAt(at);
    }
    expect(taps, hasLength(3));
  });

  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    Directory('build/visual-review/screens').createSync(recursive: true);
  });

  // Run with `--dart-define=CAPTURE_VISUALS=true` to write home, map and
  // flight at each size to build/visual-review/screens for a side-by-side.
  for (final screen in const [
    Size(792, 360),
    Size(640, 360),
    Size(864, 360),
    Size(1024, 768),
  ]) {
    final name = '${screen.width.toInt()}x${screen.height.toInt()}';
    testWidgets('home, map and a touch flight on $name show the reference '
        "phone's picture and fly its 2.2-wide sky", (tester) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      final folder = Directory.systemTemp.createTempSync('screen-frame');
      addTearDown(() => folder.deleteSync(recursive: true));
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(folder),
          ),
          audioFactoryProvider.overrideWithValue(() => SilentAudio()),
          trackingSourceFactoryProvider.overrideWithValue(
            () => throw StateError('Touch must not create a camera'),
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
        for (final asset in ['pip', 'peaches', 'island']) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'screens/home-$name');
      appRouter.go('/campaign');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'screens/map-$name');
      appRouter.go('/play/touch');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start touch flight'));
      await tester.pump();
      final view = find.byType(GameWidget<BirdGame>);
      final game = tester.widget<GameWidget<BirdGame>>(view).game!;
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(game.simulation.phase, RunPhase.playing);
      await capture(tester, 'screens/flight-$name');
      expect(tester.getSize(view), ScreenFrame.design);
      expect(game.size.x / game.size.y, closeTo(2.2, 1e-9));
      // A tap on the scaled sky still flaps.
      await tester.tapAt(tester.getRect(view).center);
      game.update(.02);
      expect(game.simulation.flaps, 1);
      appRouter.go('/');
      await tester.pumpAndSettle();
    });
  }
}
