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

  Future<(SqliteProgressRepository, ProviderContainer)> open(
    WidgetTester tester,
    double width, {
    required int stars,
    int score = 0,
  }) async {
    tester.view.physicalSize = Size(width, 360);
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
        score: score,
        stars: stars,
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
    return (repo, container);
  }

  Future<void> show(WidgetTester tester, ProviderContainer container) async {
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
    await tester.tap(find.byKey(const ValueKey('upgrades')));
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/upgrades');
    expect(tester.takeException(), isNull);
  }

  Finder wallet(String stars) => find.descendant(
    of: find.byKey(const ValueKey('star-wallet')),
    matching: find.text(stars),
  );

  for (final width in [640.0, 800.0]) {
    testWidgets('the hangar spends picked-up stars at $width', (tester) async {
      // Points run far ahead of the stars picked up; only stars count.
      final (repo, container) = await open(
        tester,
        width,
        stars: 80,
        score: 500,
      );
      await show(tester, container);
      expect(wallet('80'), findsOneWidget);
      final callout = find.byKey(const ValueKey('upgrade-callout'));
      final screen = Offset.zero & tester.view.physicalSize;
      for (final p in PowerUp.values) {
        final socket = find.byKey(ValueKey('upgrade-card-${p.name}'));
        expect(screen.contains(tester.getRect(socket).center), isTrue);
        // Every socket opens its callout, which reads whole without
        // scrolling.
        await tester.tap(socket);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: callout, matching: find.text(p.blurb)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: callout, matching: find.byType(Scrollable)),
          findsNothing,
        );
        final box = tester.getRect(callout);
        for (final (label, value) in p.stats(0)) {
          final row = find.bySemanticsLabel(
            '$label $value, next level ${p.stats(1).firstWhere((s) => s.$1 == label).$2}',
          );
          expect(row, findsOneWidget, reason: '${p.name} $label');
          expect(box.contains(tester.getCenter(row)), isTrue);
        }
      }
      await tester.tap(find.byKey(const ValueKey('upgrade-card-shot')));
      await tester.pumpAndSettle();
      expect(find.text('You will have 30 stars left.'), findsOneWidget);
      await capture(tester, 'upgrades-${width.toInt()}');

      await tester.tap(find.byKey(const ValueKey('buy-shot')));
      await tester.runAsync(() async {
        while ((await repo.load()).upgrades.shot == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.runAsync(() => container.read(progressProvider.future));
      await tester.pumpAndSettle();
      expect(wallet('30'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Max charge 55%, next level 70%'),
        findsOneWidget,
      );
      final p = await tester.runAsync(repo.load);
      expect(p!.upgrades.shot, 1);
      expect(p.starWallet, 30);
      // 30 stars cannot pay for the magnet's next level: its key is locked.
      await tester.tap(find.byKey(const ValueKey('upgrade-card-magnet')));
      await tester.pumpAndSettle();
      expect(find.text('20 more to go'), findsOneWidget);
      await capture(tester, 'upgrades-magnet-locked-${width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('buy-magnet')));
      await tester.pumpAndSettle();
      expect((await tester.runAsync(repo.load))!.upgrades.magnet, 0);
    });

    testWidgets('a maxed upgrade and a locked one read clearly at $width', (
      tester,
    ) async {
      // Shot 1, shield 2 and a maxed magnet cost 1090; 180 are left.
      final (repo, container) = await open(tester, width, stars: 1270);
      for (final p in [
        PowerUp.shot,
        PowerUp.shield,
        PowerUp.shield,
        for (var i = 0; i < PowerUp.maxLevel; i++) PowerUp.magnet,
      ]) {
        await repo.buyUpgrade(p);
      }
      await show(tester, container);
      expect(wallet('180'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('upgrade-card-shield')));
      await tester.pumpAndSettle();
      expect(find.text('70 more to go'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'upgrades-shield-${width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('upgrade-card-magnet')));
      await tester.pumpAndSettle();
      expect(find.text('Maxed out'), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-magnet')), findsNothing);
      expect(tester.takeException(), isNull);
      await capture(tester, 'upgrades-magnet-${width.toInt()}');
    });
  }
}
