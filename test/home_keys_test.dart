import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/ui/home_keys.dart';
import 'package:push_up_bird/ui/theme.dart';

Widget _app(
  VoidCallback onPressed, {
  bool reducedMotion = false,
  Widget Function(VoidCallback onPressed)? key,
  Size size = const Size(250, 108),
}) => MaterialApp(
  theme: skyTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox.fromSize(size: size, child: (key ?? _endless)(onPressed)),
    ),
  ),
);

Widget _endless(VoidCallback onPressed) =>
    HomeEndlessKey(best: 42, onPressed: onPressed);

void main() {
  testWidgets(
    'press has depth without moving the target; cancel never launches',
    (tester) async {
      var starts = 0;
      await tester.pumpWidget(_app(() => starts++));
      final button = find.byType(HomeEndlessKey);
      final target = tester.getRect(button);
      final labelPosition = tester.getTopLeft(find.text('ENDLESS'));
      var gesture = await tester.startGesture(target.center);
      await tester.pumpAndSettle();
      expect(tester.getRect(button), target);
      expect(
        tester.getTopLeft(find.text('ENDLESS')),
        labelPosition + const Offset(0, 6),
      );
      expect(starts, 0);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(starts, 0);
      expect(tester.getTopLeft(find.text('ENDLESS')), labelPosition);
      gesture = await tester.startGesture(target.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(tester.getTopLeft(find.text('ENDLESS')), labelPosition);
    },
  );

  testWidgets(
    'reduced motion keeps the face stationary but still shows a press',
    (tester) async {
      var starts = 0;
      await tester.pumpWidget(_app(() => starts++, reducedMotion: true));
      final button = find.byType(HomeEndlessKey);
      final labelPosition = tester.getTopLeft(find.text('ENDLESS'));
      final face = find.descendant(
        of: button,
        matching: find.byType(AnimatedContainer),
      );
      final restingDecoration = tester
          .widget<AnimatedContainer>(face)
          .decoration;
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('ENDLESS')), labelPosition);
      expect(
        tester.widget<AnimatedContainer>(face).decoration,
        isNot(restingDecoration),
      );
      expect(tester.widget<AnimatedContainer>(face).duration, Duration.zero);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(starts, 1);
    },
  );

  testWidgets('endless announces its best and works with keyboard activation', (
    tester,
  ) async {
    var starts = 0;
    await tester.pumpWidget(_app(() => starts++));
    expect(
      find.semantics.byLabel('Endless. Fly as far as you can. Best: 42 stars.'),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(starts, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(starts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the campaign key says where the journey continues', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      _app(
        () => opens++,
        key: (onPressed) => HomeCampaignKey(
          stars: 4,
          of: 63,
          next: '1-3 · Canopy Run',
          onPressed: onPressed,
        ),
      ),
    );
    expect(find.text('1-3 · Canopy Run'), findsOneWidget);
    expect(find.text('4 / 63'), findsOneWidget);
    expect(
      find.semantics.byLabel(
        'Campaign. Next: 1-3 · Canopy Run. 4 of 63 stars.',
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opens, 1);
    // Once every level is cleared, the key says so instead.
    await tester.pumpWidget(
      _app(
        () {},
        key: (onPressed) => HomeCampaignKey(
          stars: 63,
          of: 63,
          next: null,
          onPressed: onPressed,
        ),
      ),
    );
    expect(find.text('Every letter delivered'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the mini games key is a full button', (tester) async {
    var opens = 0;
    await tester.pumpWidget(
      _app(
        () => opens++,
        key: (onPressed) => HomeMiniGamesKey(onPressed: onPressed),
        size: const Size(510, 76),
      ),
    );
    expect(find.text('MINI GAMES'), findsOneWidget);
    await tester.tap(find.byType(HomeMiniGamesKey));
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(tester.takeException(), isNull);
  });
}
