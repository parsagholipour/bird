import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/main.dart';
import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'experience_ui_test.dart' show capture;

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
  testWidgets(
    'home, collection, records and settings fit a small landscape phone',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          audioFactoryProvider.overrideWithValue(SilentAudio.new),
          trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('mini-games')), findsOneWidget);
      expect(find.text('Jump & Fly'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mini-games')));
      await tester.pumpAndSettle();
      expect(find.text('Jump & Fly'), findsOneWidget);
      await capture(tester, 'mini-games');
      await tester.tap(find.byTooltip('Close mini games'));
      await tester.pumpAndSettle();
      await capture(tester, 'home-play-menu');
      // Endless is the main game's quick flight, straight from Home.
      await tester.tap(find.byKey(const ValueKey('endless')));
      await tester.pump();
      await tester.pump();
      var route = appRouter.routeInformationProvider.value.uri;
      expect(route.path, '/play/touch');
      expect(route.queryParameters, {'course': 'starTrail'});
      expect(find.text('Endless flight'), findsNothing);
      expect(find.text('Start touch flight'), findsNothing);
      final game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      expect(game.simulation.phase, RunPhase.countdown);
      await capture(tester, 'endless-countdown');
      appRouter.go('/');
      await tester.pumpAndSettle();
      for (final (label, mode) in [
        ('Push-Up Flight', 'push-up'),
        ('Squat & Fly', 'squat'),
        ('Jump & Fly', 'jump'),
      ]) {
        await tester.tap(find.byKey(const ValueKey('mini-games')));
        await tester.pumpAndSettle();
        expect(appRouter.routeInformationProvider.value.uri.path, '/');
        expect(find.text('Mini games'), findsOneWidget);
        for (final title in ['Push-Up Flight', 'Squat & Fly', 'Jump & Fly']) {
          expect(find.text(title).hitTestable(), findsOneWidget);
        }
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        route = appRouter.routeInformationProvider.value.uri;
        expect(route.path, '/play/$mode');
        if (mode == 'jump') {
          expect(find.text('Show your whole body.'), findsOneWidget);
          expect(find.text('Stand tall and still'), findsOneWidget);
          await capture(tester, 'jump-mode-setup');
        }
        if (mode == 'squat') {
          expect(find.text('Find your comfortable squat'), findsOneWidget);
          expect(find.textContaining('Squat to descend.'), findsOneWidget);
          await capture(tester, 'squat-mode-setup');
        }
        expect(route.queryParameters, {'course': 'starTrail'});
        expect(tester.takeException(), isNull);
        appRouter.go('/');
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Birds'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Peaches'), findsOneWidget);
      expect(find.text('Fly with me'), findsNWidgets(3));
      appRouter.go('/records');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Recent flights'), findsOneWidget);
      expect(find.text('Squat & Fly'), findsOneWidget);
      await capture(tester, 'squat-records');
      appRouter.go('/settings');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Switch), findsNWidgets(4));
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
    },
  );
}
