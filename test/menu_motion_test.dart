import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });
  testWidgets('platform motion flag stops and restarts shared menu motion', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Floating(child: SizedBox(width: 30, height: 30)),
              SkyButton(label: 'Play', onPressed: () {}),
              SkyButton(label: 'Loading', onPressed: () {}, busy: true),
            ],
          ),
        ),
      ),
    );
    final floating = find.descendant(
      of: find.byType(Floating),
      matching: find.byType(Transform),
    );
    final button = find.descendant(
      of: find.widgetWithText(SkyButton, 'Play'),
      matching: find.byType(AnimatedContainer),
    );
    double floatingY() =>
        tester.widget<Transform>(floating).transform.storage[13];
    double buttonY() =>
        tester.widget<AnimatedContainer>(button).transform!.storage[13];
    double renderedButtonY() => tester
        .widget<Transform>(
          find.descendant(of: button, matching: find.byType(Transform)).first,
        )
        .transform
        .storage[13];

    await tester.pumpAndSettle();
    expect(floatingY(), 0);
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      .75,
    );
    var gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 150));
    expect(buttonY(), 0);
    expect(renderedButtonY(), 0);
    expect(tester.widget<AnimatedContainer>(button).duration, Duration.zero);
    await gesture.up();
    await tester.pumpAndSettle();

    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(floatingY(), isNot(0));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNull,
    );
    gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 100));
    expect(buttonY(), 3);
    expect(renderedButtonY(), 3);

    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(floatingY(), 0);
    expect(buttonY(), 0);
    expect(renderedButtonY(), 0);
    expect(tester.binding.transientCallbackCount, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('app preference combines with system flag for descendants', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    final container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
      appRouter.go('/');
    });
    await container.read(progressProvider.future);
    appRouter.go('/settings');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await tester.pumpAndSettle();
    MediaQueryData descendantData() =>
        MediaQuery.of(tester.element(find.byType(SettingsScreen)));
    final baseline = descendantData();
    expect(baseline.disableAnimations, isFalse);
    final progress = container.read(progressProvider.notifier);
    await progress.setting(SettingKey.reducedMotion, true);
    await tester.pumpAndSettle();
    expect(descendantData(), baseline.copyWith(disableAnimations: true));
    await progress.setting(SettingKey.reducedMotion, false);
    await tester.pumpAndSettle();
    expect(descendantData(), baseline);

    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    await tester.pumpAndSettle();
    expect(descendantData().disableAnimations, isTrue);
    await progress.setting(SettingKey.reducedMotion, true);
    await tester.pumpAndSettle();
    await progress.setting(SettingKey.reducedMotion, false);
    await tester.pumpAndSettle();
    expect(descendantData().disableAnimations, isTrue);
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: false,
    );
    await tester.pumpAndSettle();
    expect(descendantData().disableAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
