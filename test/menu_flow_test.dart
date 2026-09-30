import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
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
      expect(find.byKey(const ValueKey('play')), findsOneWidget);
      expect(find.text('Jump & Fly'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('play')));
      await tester.pumpAndSettle();
      expect(find.text('Jump & Fly'), findsOneWidget);
      await capture(tester, 'mode-picker');
      await tester.tap(find.byTooltip('Close mode picker'));
      await tester.pumpAndSettle();
      await capture(tester, 'home-play-menu');
      for (final (label, mode, practice) in [
        ('Push-Up Flight', 'push-up', false),
        ('Tap & Fly', 'touch', false),
        ('Jump & Fly', 'jump', false),
        ('Squat & Fly', 'squat', false),
        ('Push-Up Flight', 'push-up', true),
        ('Tap & Fly', 'touch', true),
        ('Jump & Fly', 'jump', true),
        ('Squat & Fly', 'squat', true),
      ]) {
        await tester.tap(
          practice ? find.text('Practice') : find.byKey(const ValueKey('play')),
        );
        await tester.pumpAndSettle();
        expect(appRouter.routeInformationProvider.value.uri.path, '/');
        expect(
          find.text(practice ? 'Choose your practice' : 'Choose your mode'),
          findsOneWidget,
        );
        for (final title in [
          'Push-Up Flight',
          'Tap & Fly',
          'Jump & Fly',
          'Squat & Fly',
        ]) {
          expect(find.text(title).hitTestable(), findsOneWidget);
        }
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        final route = appRouter.routeInformationProvider.value.uri;
        expect(route.path, '/play/$mode');
        if (mode == 'jump') {
          expect(find.text('Show your whole body.'), findsOneWidget);
          expect(find.text('Stand tall and still'), findsOneWidget);
          await capture(
            tester,
            practice ? 'jump-practice-setup' : 'jump-mode-setup',
          );
        }
        if (mode == 'squat') {
          expect(find.text('Find your comfortable squat'), findsOneWidget);
          expect(find.textContaining('Squat to descend.'), findsOneWidget);
          await capture(
            tester,
            practice ? 'squat-practice-setup' : 'squat-mode-setup',
          );
        }
        expect(route.queryParameters['course'], 'starTrail');
        expect(route.queryParameters['practice'] == 'true', practice);
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
