import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
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
        overrides: [progressRepositoryProvider.overrideWithValue(repo)],
      );
      await container.read(progressProvider.future);
      appRouter.go('/');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PushUpBirdApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Push-Up Flight'), findsOneWidget);
      expect(find.text('Grin & Glide'), findsOneWidget);
      await tester.tap(find.text('Birds'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Peaches'), findsOneWidget);
      expect(find.text('25 to unlock'), findsOneWidget);
      appRouter.go('/records');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Recent flights'), findsOneWidget);
      appRouter.go('/settings');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Switch), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
    },
  );
}
