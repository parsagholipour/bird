import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/ui/play_button.dart';
import 'package:push_up_bird/ui/theme.dart';

Widget _app(VoidCallback onPressed, {bool reducedMotion = false}) =>
    MaterialApp(
      theme: skyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 348, child: PlayButton(onPressed: onPressed)),
        ),
      ),
    );

void main() {
  testWidgets(
    'press has depth without moving the target; cancel never launches',
    (tester) async {
      var starts = 0;
      await tester.pumpWidget(_app(() => starts++));
      final button = find.byType(PlayButton);
      final target = tester.getRect(button);
      final labelPosition = tester.getTopLeft(find.text('PLAY'));
      var gesture = await tester.startGesture(target.center);
      await tester.pumpAndSettle();
      expect(tester.getRect(button), target);
      expect(
        tester.getTopLeft(find.text('PLAY')),
        labelPosition + const Offset(0, 6),
      );
      expect(starts, 0);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(starts, 0);
      expect(tester.getTopLeft(find.text('PLAY')), labelPosition);
      gesture = await tester.startGesture(target.center);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(tester.getTopLeft(find.text('PLAY')), labelPosition);
    },
  );

  testWidgets(
    'reduced motion keeps the face stationary but still shows a press',
    (tester) async {
      var starts = 0;
      await tester.pumpWidget(_app(() => starts++, reducedMotion: true));
      final button = find.byType(PlayButton);
      final labelPosition = tester.getTopLeft(find.text('PLAY'));
      final face = find.descendant(
        of: button,
        matching: find.byType(AnimatedContainer),
      );
      final restingDecoration = tester
          .widget<AnimatedContainer>(face)
          .decoration;
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('PLAY')), labelPosition);
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

  testWidgets('play announces push-ups and works with keyboard activation', (
    tester,
  ) async {
    var starts = 0;
    await tester.pumpWidget(_app(() => starts++));
    expect(find.semantics.byLabel('Start push-up flight'), findsOneWidget);
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
}
