import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/ui/home_parts.dart';
import 'package:push_up_bird/ui/home_screen.dart';
import 'package:push_up_bird/ui/play_button.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'daily_adventure_test.dart' show dailyRun;

/// Renders the title screen for the states and phones that matter and, with
/// `--dart-define=CAPTURE_VISUALS=true`, saves them to build/visual-review.
enum Profile { fresh, progressed, complete }

/// A phone in landscape. [insets] are cutout and gesture insets in logical dp.
class Screen {
  const Screen(this.name, this.width, this.height, {this.dpr = 1, this.insets});
  final String name;
  final double width, height, dpr;
  final EdgeInsets? insets;
}

const screens = [
  Screen('800', 800, 360),
  Screen('640', 640, 300),
  Screen('1000', 1000, 450),
  // Older 16:9 phones and tablets letterbox the canvas top and bottom.
  Screen('16x9', 1920 / 2.625, 1080 / 2.625, dpr: 2.625),
  Screen('tablet', 1280, 800),
  // A modern 20:9 phone with a cutout on one side and a gesture bar.
  Screen(
    'wide',
    2400 / 2.625,
    1080 / 2.625,
    dpr: 2.625,
    insets: EdgeInsets.only(left: 52, right: 24, bottom: 21),
  ),
];

final today = DateTime(2026, 9, 16, 12);

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/visual-review')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<Uint8List> pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

Future<(ProviderContainer, ProgressRepository)> makeContainer(
  Profile profile, {
  required bool reduced,
}) async {
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
    clock: () => today,
  );
  await repo.setSetting(SettingKey.reducedMotion, reduced);
  if (profile != Profile.fresh) {
    await repo.equipBird(2);
    // A flight from yesterday counts toward records but not today's card.
    await repo.saveRun(
      dailyRun(
        'earlier',
        today.subtract(const Duration(days: 1)),
        mode: PlayMode.touch,
        stars: 18,
      ),
    );
    await repo.saveRun(dailyRun('one', today, stars: 42, gates: 7));
  }
  if (profile == Profile.complete) {
    await repo.saveRun(dailyRun('two', today, stars: 60, gates: 12));
  }
  final container = ProviderContainer(
    overrides: [
      appClockProvider.overrideWithValue(() => today),
      progressRepositoryProvider.overrideWithValue(repo),
    ],
  );
  await container.read(progressProvider.future);
  return (container, repo);
}

/// The title screen inside a router whose other routes are stubs, so the
/// tests see where every shortcut leads.
class Harness extends ConsumerWidget {
  const Harness({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(
      progressProvider.select(
        (p) => p.asData?.value.settings.reducedMotion ?? false,
      ),
    );
    return RepaintBoundary(
      key: const ValueKey('visual-capture'),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: skyTheme(),
        routerConfig: router,
        // The app turns Reduced Motion into the platform flag the same way.
        builder: (context, child) {
          final query = MediaQuery.of(context);
          return MediaQuery(
            data: query.copyWith(
              disableAnimations: reduced || query.disableAnimations,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

GoRouter stubRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    for (final path in [
      '/school',
      '/settings',
      '/daily',
      '/birds',
      '/passport',
      '/records',
    ])
      GoRoute(
        path: path,
        builder: (context, state) => Scaffold(body: Text('stub $path')),
      ),
    GoRoute(
      path: '/play/:mode',
      builder: (context, state) => const Scaffold(body: Text('stub play')),
    ),
  ],
);

/// Opens the title screen on [screen] and lets its images decode.
Future<GoRouter> pumpHome(
  WidgetTester tester,
  Screen screen,
  Profile profile, {
  required bool reduced,
}) async {
  tester.view.physicalSize = Size(
    screen.width * screen.dpr,
    screen.height * screen.dpr,
  );
  tester.view.devicePixelRatio = screen.dpr;
  final insets = screen.insets;
  if (insets != null) {
    final padding = FakeViewPadding(
      left: insets.left * screen.dpr,
      top: insets.top * screen.dpr,
      right: insets.right * screen.dpr,
      bottom: insets.bottom * screen.dpr,
    );
    tester.view.padding = padding;
    tester.view.viewPadding = padding;
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  final (container, repo) = await makeContainer(profile, reduced: reduced);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
  });
  final router = stubRouter();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Harness(router: router),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in ['pip', 'peaches', 'minty', 'orbit', 'island']) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  return router;
}

String location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

Finder pressable(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InkWell));

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

  for (final screen in screens) {
    for (final profile in Profile.values) {
      testWidgets(
        'title screen fits ${screen.name} for ${profile.name} with Reduced '
        'Motion',
        (tester) async {
          await pumpHome(tester, screen, profile, reduced: true);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.binding.transientCallbackCount,
            0,
            reason: 'Reduced Motion must leave nothing animating',
          );
          // Everything the player can press stays inside the safe area.
          final insets = screen.insets ?? EdgeInsets.zero;
          final safe = Rect.fromLTRB(
            insets.left,
            insets.top,
            screen.width - insets.right,
            screen.height - insets.bottom,
          ).inflate(.5);
          for (final finder in [
            find.byKey(const ValueKey('play')),
            find.text('Practice'),
            find.byKey(const ValueKey('daily-adventure')),
            find.text('Birds'),
            find.text('Passport'),
            find.text('Records'),
            find.text('Flight goals'),
            find.text('Flight school'),
            find.byTooltip('Settings'),
          ]) {
            final rect = tester.getRect(finder);
            expect(
              safe.contains(rect.topLeft) && safe.contains(rect.bottomRight),
              isTrue,
              reason: '$finder at $rect leaves the safe area $safe',
            );
          }
          await capture(tester, 'home-${profile.name}-${screen.name}');
        },
      );
    }
  }

  testWidgets('every control is at least 48 dp on a typical modern phone', (
    tester,
  ) async {
    const phone = Screen('pixel', 915, 412, dpr: 2.625);
    await pumpHome(tester, phone, Profile.progressed, reduced: true);
    await tester.pumpAndSettle();
    for (final (name, finder) in [
      ('Play', find.byKey(const ValueKey('play'))),
      ('Practice', find.byType(HomePracticeButton)),
      ('Adventure', find.byKey(const ValueKey('daily-adventure'))),
      ('Birds', pressable('Birds')),
      ('Passport', pressable('Passport')),
      ('Records', pressable('Records')),
      ('Flight goals', pressable('Flight goals')),
      ('Flight school', pressable('Flight school')),
      ('Settings', find.byTooltip('Settings')),
    ]) {
      final size = tester.getSize(finder.first);
      expect(size.width, greaterThanOrEqualTo(48), reason: '$name $size');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$name $size');
    }
  });

  testWidgets('every destination stays reachable from the title screen', (
    tester,
  ) async {
    final router = await pumpHome(
      tester,
      screens.first,
      Profile.progressed,
      reduced: true,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('play')), findsOneWidget);
    expect(find.text('Jump & Fly'), findsNothing);
    for (final (finder, path) in [
      (find.text('Flight school'), '/school'),
      (find.byTooltip('Settings'), '/settings'),
      (find.byKey(const ValueKey('daily-adventure')), '/daily'),
      (find.text('Birds'), '/birds'),
      (find.text('Passport'), '/passport'),
      (find.text('Records'), '/records'),
    ]) {
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(location(router), path);
      router.go('/');
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Flight goals'));
    await tester.pumpAndSettle();
    expect(find.text('Star pocket'), findsOneWidget);
    await tester.tap(find.byTooltip('Close flight goals'));
    await tester.pumpAndSettle();
    expect(location(router), '/');
    for (final practice in [false, true]) {
      await tester.tap(
        practice ? find.text('Practice') : find.byKey(const ValueKey('play')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(practice ? 'Choose your practice' : 'Choose your mode'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tap & Fly'));
      await tester.pumpAndSettle();
      final uri = router.routerDelegate.currentConfiguration.uri;
      expect(uri.path, '/play/touch');
      expect(uri.queryParameters['practice'] == 'true', practice);
      expect(uri.queryParameters['course'], 'starTrail');
      router.go('/');
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the screen welcomes a new player', (tester) async {
    await pumpHome(tester, screens.first, Profile.fresh, reduced: true);
    await tester.pumpAndSettle();
    expect(find.text('Your first flight awaits'), findsOneWidget);
    expect(find.text('Hi, I’m Pip! Ready to fly?'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.textContaining('0 stars'), findsNothing);
    for (final label in ['Push-ups', 'Squats', 'Jumps', 'Taps']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.byKey(const ValueKey('daily-adventure'))).label,
      'Today’s adventure. 0 of 3 goals complete.',
    );
  });

  testWidgets('a returning player sees their best flight and a partial card', (
    tester,
  ) async {
    await pumpHome(tester, screens.first, Profile.progressed, reduced: true);
    await tester.pumpAndSettle();
    expect(find.text('BEST · PUSH-UPS'), findsOneWidget);
    expect(find.text('42 stars'), findsOneWidget);
    expect(find.text('Minty is ready. Are you?'), findsOneWidget);
    expect(find.textContaining('/3'), findsOneWidget);
    expect(find.text('3/3'), findsNothing);
  });

  testWidgets('a finished adventure is celebrated', (tester) async {
    await pumpHome(tester, screens.first, Profile.complete, reduced: true);
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('Adventure done! Minty is proud.'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('daily-adventure'))).label,
      'Today’s adventure. 3 of 3 goals complete.',
    );
  });

  testWidgets('switching Reduced Motion on calms a running screen', (
    tester,
  ) async {
    await pumpHome(tester, screens.first, Profile.progressed, reduced: false);
    await tester.pump(const Duration(milliseconds: 3300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await tester.runAsync(
      () => container
          .read(progressProvider.notifier)
          .setting(SettingKey.reducedMotion, true),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
    final calm = await pixels(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(await pixels(tester), calm);
    // The bird is back on its perch, not frozen mid-hop.
    await tester.runAsync(
      () => container.read(progressProvider.notifier).equip(3),
    );
    await tester.pumpAndSettle();
    expect(find.text('Orbit is ready. Are you?'), findsOneWidget);
  });

  testWidgets('very large system text still fits without overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final screen in [screens[0], screens[1]]) {
      for (final profile in [Profile.fresh, Profile.complete]) {
        await pumpHome(tester, screen, profile, reduced: true);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, 'home-large-text-${profile.name}-${screen.name}');
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('Reduced Motion leaves the screen perfectly still', (
    tester,
  ) async {
    await pumpHome(tester, screens.first, Profile.progressed, reduced: true);
    await tester.pumpAndSettle();
    final still = await pixels(tester);
    await tester.pump(const Duration(seconds: 6));
    expect(await pixels(tester), still);
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      tester.widget<PlayButton>(find.byType(PlayButton)).reducedMotion,
      isTrue,
    );
  });

  testWidgets('with motion allowed the world breathes and the bird hops', (
    tester,
  ) async {
    await pumpHome(tester, screens.first, Profile.progressed, reduced: false);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    final frames = <Uint8List>[];
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 700));
      frames.add(await pixels(tester));
    }
    for (var i = 1; i < frames.length; i++) {
      expect(frames[i], isNot(equals(frames[i - 1])));
    }
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
  });

  for (final profile in [Profile.fresh, Profile.progressed]) {
    testWidgets('title screen animates in for ${profile.name}', (tester) async {
      await pumpHome(tester, screens.first, profile, reduced: false);
      var elapsed = 0;
      for (final ms in [60, 500, 1100, 1900, 2150, 3550, 3800]) {
        await tester.pump(Duration(milliseconds: ms - elapsed));
        elapsed = ms;
        expect(tester.takeException(), isNull);
        await capture(tester, 'home-${profile.name}-motion-$ms');
      }
    });
  }
}
