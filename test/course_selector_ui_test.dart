import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/ui/home_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1100, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repo.setSetting(SettingKey.reducedMotion, true);
  final container = ProviderContainer(
    overrides: [progressRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
  });
  await container.read(progressProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: skyTheme(), home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });
  testWidgets('Play reveals every mode and dismisses back to the menu', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('STAR TRAIL'), findsNothing);
    expect(find.byKey(const ValueKey('play')), findsOneWidget);
    expect(find.text('60s · 3 hearts'), findsNothing);
    expect(find.text('Practice'), findsNothing);
    expect(find.text('Tap & Fly'), findsNothing);
    expect(find.text('Jump & Fly'), findsNothing);
    expect(find.text('Other ways to play'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('play')));
    await tester.pumpAndSettle();
    expect(find.text('Tap to flap.\nAim & shoot.'), findsOneWidget);
    expect(find.text('Tap & Fly').hitTestable(), findsOneWidget);
    expect(find.text('Jump & Fly').hitTestable(), findsOneWidget);
    expect(find.text('Push-Up Flight').hitTestable(), findsOneWidget);
    expect(find.text('Squat & Fly').hitTestable(), findsOneWidget);
    expect(find.text('No camera'), findsOneWidget);
    await tester.tap(find.byTooltip('Close mode picker'));
    await tester.pumpAndSettle();
    expect(find.text('Tap & Fly'), findsNothing);
    expect(find.byKey(const ValueKey('play')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('course-classic')), findsNothing);
    expect(find.byKey(const ValueKey('course-starTrail')), findsNothing);
    expect(find.byKey(const ValueKey('course-skyCourier')), findsNothing);
    expect(find.byKey(const ValueKey('course-cloudCruise')), findsNothing);
    expect(find.text('Just drift'), findsNothing);
    expect(find.text('Deliver some joy'), findsNothing);
    expect(find.text('Let’s fly'), findsNothing);
    expect(find.text('Classic'), findsNothing);
    expect(find.text('Courier'), findsNothing);
    expect(find.text('Cloud Cruise'), findsNothing);
  });
}
