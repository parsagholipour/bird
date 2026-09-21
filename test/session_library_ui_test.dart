import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/replay_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  Future<GoRouter> showLibrary(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/sessions',
      routes: [
        GoRoute(
          path: '/sessions',
          builder: (_, _) => const SessionLibraryScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Flight picker')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionsProvider.overrideWith((ref) async => [])],
        child: MaterialApp.router(
          theme: skyTheme(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              padding: const EdgeInsets.only(bottom: 16),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'empty library fits small landscape sizes and opens flight picker',
    (tester) async {
      final router = await showLibrary(tester);
      for (final width in [640.0, 800.0]) {
        tester.view.physicalSize = Size(width, 360);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text('Save a session after a flight to watch it here.'),
          findsOneWidget,
        );
        expect(tester.widget<BirdArt>(find.byType(BirdArt)).bob, isFalse);
        final panel = tester.getRect(find.byType(Panel));
        expect(panel.width, lessThanOrEqualTo(420));
        expect(panel.top, greaterThanOrEqualTo(72));
        expect(panel.bottom, lessThanOrEqualTo(328));
        expect(find.text('Choose a flight').hitTestable(), findsOneWidget);
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .maxScrollExtent,
          0,
        );
      }
      await tester.tap(find.text('Choose a flight'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.text('Flight picker'), findsOneWidget);
    },
  );

  testWidgets('large empty-state text scrolls without overflow', (
    tester,
  ) async {
    await showLibrary(tester, scale: 3);
    expect(tester.takeException(), isNull);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
    await tester.ensureVisible(find.byType(SkyButton));
    await tester.pumpAndSettle();
    expect(find.text('Choose a flight').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Choose a flight'));
    await tester.pumpAndSettle();
    expect(find.text('Flight picker'), findsOneWidget);
  });
}
