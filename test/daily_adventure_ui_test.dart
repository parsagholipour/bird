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
import 'package:push_up_bird/ui/play_screen.dart';
import 'daily_adventure_test.dart' show dailyRun;
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SessionSource, SilentAudio;

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final stage in ['fresh', 'partial', 'complete']) {
    testWidgets(
      'daily postcard $stage fits small phones and launches any control',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var now = DateTime(2026, 9, 16, 12);
        final repo = SqliteProgressRepository(
          ProgressDatabase(NativeDatabase.memory()),
          clock: () => now,
        );
        await repo.setSetting(SettingKey.reducedMotion, true);
        if (stage != 'fresh') await repo.saveRun(dailyRun('first', now));
        if (stage == 'complete') await repo.saveRun(dailyRun('second', now));
        final source = SessionSource();
        final container = ProviderContainer(
          overrides: [
            appClockProvider.overrideWithValue(() => now),
            progressRepositoryProvider.overrideWithValue(repo),
            audioFactoryProvider.overrideWithValue(SilentAudio.new),
            trackingSourceFactoryProvider.overrideWithValue(() => source),
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
        await tester.runAsync(() async {
          final context = tester.element(find.byType(PushUpBirdApp));
          for (final asset in ['pip', 'peaches', 'island']) {
            await precacheImage(
              AssetImage('assets/images/$asset.png'),
              context,
            );
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, 'home-daily-$stage');
        await tester.tap(find.byKey(const ValueKey('daily-adventure')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Today’s little adventure.'), findsOneWidget);
        expect(find.textContaining('No streak to lose.'), findsOneWidget);
        expect(
          find.text(
            'Three goals. Any control. Fly Star Trail to work on all three.',
          ),
          findsOneWidget,
        );
        for (final size in [const Size(640, 360), const Size(800, 360)]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$size');
          // Endless (Tap & Fly) leads; the mini games follow.
          for (final mode in PlayMode.values) {
            expect(find.text(_label(mode)).hitTestable(), findsOneWidget);
          }
        }
        expect(
          find.text('POSTCARD STAMPED!'),
          stage == 'complete' ? findsOneWidget : findsNothing,
        );
        await capture(tester, 'daily-card-$stage');
        if (stage == 'complete') {
          now = DateTime(2026, 9, 17);
          await tester.runAsync(() async {
            await tester.pump(const Duration(minutes: 1));
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('POSTCARD STAMPED!'), findsNothing);
          expect(
            container.read(progressProvider).requireValue.today!.dayKey,
            '2026-09-17',
          );
          expect(
            container
                .read(progressProvider)
                .requireValue
                .adventures[5]
                .complete,
            isTrue,
          );
          await capture(tester, 'daily-card-next-day');
          await tester.runAsync(() async {
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            now = DateTime(2026, 9, 18);
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();
          expect(
            container.read(progressProvider).requireValue.today!.dayKey,
            '2026-09-18',
          );
          expect(
            container
                .read(progressProvider)
                .requireValue
                .adventures[4]
                .complete,
            isTrue,
          );
        }
        final (mode, routeMode) = switch (stage) {
          'partial' => (PlayMode.jump, 'jump'),
          'complete' => (PlayMode.touch, 'touch'),
          _ => (PlayMode.pushUp, 'push-up'),
        };
        await tester.tap(find.text(_label(mode)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final screen = tester.widget<PlayScreen>(find.byType(PlayScreen));
        expect(
          appRouter.routeInformationProvider.value.uri.toString(),
          '/play/$routeMode?course=starTrail',
        );
        expect(screen.mode, mode);
        expect(screen.course, FlightCourse.starTrail);
        expect(container.read(selectedCourseProvider), FlightCourse.starTrail);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.runAsync(repo.close);
      },
    );
  }
}

/// The postcard's launch key for [mode]: Tap & Fly is the main game's
/// Endless.
String _label(PlayMode mode) => mode == PlayMode.touch ? 'Endless' : mode.title;
