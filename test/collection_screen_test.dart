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
import 'experience_ui_test.dart' show capture;
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

  RunResult flight(String id, int stars, {int bird = firstBird}) => RunResult(
    id: id,
    mode: PlayMode.touch,
    practice: false,
    course: FlightCourse.starTrail,
    score: stars * 3,
    stars: stars,
    repetitions: 0,
    flaps: 10,
    durationSeconds: 30,
    reason: EndReason.collision,
    finishedAt: DateTime(2026, 10, 4),
    bird: bird,
  );

  Finder wallet(String stars) => find.descendant(
    of: find.byKey(const ValueKey('star-wallet')),
    matching: find.text(stars),
  );

  for (final width in [640.0, 800.0]) {
    testWidgets('the crew screen views, flies with and unlocks birds '
        'at $width', (tester) async {
      tester.view.physicalSize = Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      await repo.saveRun(flight('a', 600));
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          audioFactoryProvider.overrideWithValue(SilentAudio.new),
          trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
        ],
      );
      addTearDown(container.dispose);
      await container.read(progressProvider.future);
      appRouter.go('/birds');
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
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(wallet('600'), findsOneWidget);
      // Minty flies from the start and is on show.
      expect(find.byKey(const ValueKey('bird-flying')), findsOneWidget);
      for (final bird in birdOrder) {
        expect(find.byKey(ValueKey('bird-card-$bird')), findsOneWidget);
      }

      // Peaches is free: viewing it offers to fly with it.
      await tester.tap(find.byKey(const ValueKey('bird-card-1')));
      await tester.pumpAndSettle();
      expect(find.text('Fly with Peaches'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Fly with Peaches instead of Minty'),
        findsOneWidget,
      );
      await capture(tester, 'birds-peaches-${width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('fly-with-1')));
      await tester.runAsync(() async {
        while ((await repo.load()).settings.bird != 1) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.runAsync(() => container.read(progressProvider.future));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bird-flying')), findsOneWidget);

      // Orbit costs 1000: locked, and its key cannot be pressed.
      await tester.tap(find.byKey(const ValueKey('bird-card-3')));
      await tester.pumpAndSettle();
      expect(find.text('Unlock Orbit'), findsOneWidget);
      expect(find.textContaining('400 more to go'), findsOneWidget);
      await capture(tester, 'birds-orbit-${width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('unlock-3')));
      await tester.pumpAndSettle();
      expect((await tester.runAsync(repo.load))!.birdUnlocked(3), isFalse);

      // Pip costs 500, which the wallet can pay.
      await tester.tap(find.byKey(const ValueKey('bird-card-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('unlock-0')));
      await tester.runAsync(() async {
        while (!(await repo.load()).birdUnlocked(0)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.runAsync(() => container.read(progressProvider.future));
      await tester.pumpAndSettle();
      expect(wallet('100'), findsOneWidget);
      expect(find.text('Fly with Pip'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'birds-pip-${width.toInt()}');
    });
  }

  test('Minty and Peaches are free; Pip and Orbit cost stars', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    var p = await repo.load();
    expect(p.unlockedBirds, {1, 2});
    expect(birdPrices, [500, 0, 0, 1000]);
    await expectLater(repo.unlockBird(0), throwsStateError);
    await expectLater(repo.unlockBird(2), throwsStateError);

    // Stars are shared with the upgrades.
    await repo.saveRun(flight('a', 1550));
    await repo.buyUpgrade(PowerUp.shot);
    await repo.unlockBird(3);
    p = await repo.load();
    expect(p.birdUnlocked(3), isTrue);
    expect(p.starWallet, 1550 - 50 - 1000);
    expect(p.canUnlock(0), isTrue, reason: '500 left pays for Pip');
    await repo.unlockBird(0);
    p = await repo.load();
    expect(p.unlockedBirds, {0, 1, 2, 3});
    expect(p.starWallet, 0);
    await repo.saveRun(flight('b', 1));
    p = await repo.load();
    await expectLater(repo.unlockBird(0), throwsStateError);
    expect(p.birdFlights, {firstBird: 2});

    await repo.reset();
    expect((await repo.load()).unlockedBirds, {1, 2});
  });

  test('a save from before birds cost stars buys Pip and Orbit too', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    // Flew Orbit and had Pip equipped, all before unlocking existed.
    await repo.saveRun(flight('a', 600, bird: 3));
    await repo.equipBird(0);
    var p = await repo.load();
    expect(p.unlockedBirds, {1, 2});
    expect(
      p.settings.bird,
      firstBird,
      reason: 'Minty flies until Pip is bought',
    );
    expect(p.birdsFlown, {3}, reason: 'Flown, but still locked');
    await repo.unlockBird(0);
    p = await repo.load();
    expect(p.settings.bird, 0, reason: 'The equipped Pip is back once bought');
    expect(p.starWallet, 100);
  });

  test('locked birds cannot be equipped or flown co-op', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    final container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final p = await container.read(progressProvider.future);
    expect(p.coop.birds, (firstBird, 1), reason: 'Minty and Peaches');
    await expectLater(
      container.read(progressProvider.notifier).equip(3),
      throwsStateError,
    );
    await container.read(progressProvider.notifier).equip(1);
    expect((await repo.load()).settings.bird, 1);
    // Saved co-op birds that are locked fall back to unlocked ones.
    await repo.chooseCoop(0, 3, CoopMode.roped);
    expect((await repo.load()).coop.birds, (1, firstBird));
  });
}
