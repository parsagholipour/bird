import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/main.dart';
import 'play_session_test.dart' show SessionSource, SilentAudio;

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

  testWidgets('home opens the upgrades, which spend collected stars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    await repo.setSetting(SettingKey.reducedMotion, true);
    await repo.saveRun(
      RunResult(
        id: 'trail',
        mode: PlayMode.touch,
        practice: false,
        course: FlightCourse.starTrail,
        score: 80,
        stars: 80,
        repetitions: 0,
        flaps: 10,
        durationSeconds: 30,
        reason: EndReason.collision,
        finishedAt: DateTime(2026, 10, 4),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        audioFactoryProvider.overrideWithValue(SilentAudio.new),
        trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
      ],
    );
    addTearDown(container.dispose);
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
    await tester.tap(find.byKey(const ValueKey('upgrades')));
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/upgrades');
    expect(tester.takeException(), isNull);
    expect(find.text('80 STARS'), findsOneWidget);
    for (final p in PowerUp.values) {
      expect(find.byKey(ValueKey('upgrade-card-${p.name}')), findsOneWidget);
    }
    expect(find.text('Charge up to 25%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-shot')));
    await tester.runAsync(() async {
      while ((await repo.load()).upgrades.shot == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.runAsync(() => container.read(progressProvider.future));
    await tester.pumpAndSettle();
    expect(find.text('30 STARS'), findsOneWidget);
    expect(find.text('Charge up to 45%'), findsOneWidget);
    final p = await tester.runAsync(repo.load);
    expect(p!.upgrades.shot, 1);
    expect(p.starWallet, 30);
    // 30 stars cannot pay for the next level of anything.
    await tester.tap(find.byKey(const ValueKey('buy-magnet')));
    await tester.pumpAndSettle();
    expect((await tester.runAsync(repo.load))!.upgrades.magnet, 0);
  });
}
