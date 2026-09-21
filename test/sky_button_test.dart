import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/theme.dart';

Widget buttonApp({
  required VoidCallback? onPressed,
  bool busy = false,
  bool compact = false,
  IconData? icon = Icons.arrow_forward_rounded,
}) => MaterialApp(
  theme: skyTheme(),
  home: Scaffold(
    body: Center(
      child: SkyButton(
        label: 'Launch',
        onPressed: onPressed,
        busy: busy,
        compact: compact,
        icon: icon,
      ),
    ),
  ),
);

void main() {
  for (final input in ['pointer', 'Enter', 'Space', 'semantics']) {
    testWidgets('busy blocks $input activation with a supplied callback', (
      tester,
    ) async {
      var activations = 0;
      void activate() => activations++;
      final keyboard = input == 'Enter' || input == 'Space';

      Future<void> trigger() async {
        switch (input) {
          case 'pointer':
            await tester.tap(find.text('Launch'));
          case 'Enter':
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          case 'Space':
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
          case 'semantics':
            tester.semantics.performAction(
              find.semantics.byLabel('Launch'),
              SemanticsAction.tap,
              checkForAction: false,
            );
        }
        await tester.pump();
      }

      await tester.pumpWidget(buttonApp(onPressed: activate));
      if (keyboard) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await trigger();
      expect(activations, 1);

      await tester.pumpWidget(buttonApp(onPressed: activate, busy: true));
      await trigger();
      expect(activations, 1);

      await tester.pumpWidget(buttonApp(onPressed: activate));
      if (keyboard) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await trigger();
      expect(activations, 2);
    });
  }

  testWidgets('busy has one button label and an accessible busy state', (
    tester,
  ) async {
    await tester.pumpWidget(buttonApp(onPressed: () {}));
    expect(
      tester.getSemantics(find.byType(SkyButton)),
      isSemantics(
        label: 'Launch',
        value: '',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(buttonApp(onPressed: () {}, busy: true));
    expect(find.semantics.byLabel(RegExp('Launch')).evaluate(), hasLength(1));
    expect(
      tester.getSemantics(find.byType(SkyButton)),
      isSemantics(
        label: 'Launch',
        value: 'Busy',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        isLiveRegion: true,
        hasTapAction: false,
      ),
    );

    await tester.pumpWidget(buttonApp(onPressed: () {}));
    expect(
      tester.getSemantics(find.byType(SkyButton)),
      isSemantics(
        label: 'Launch',
        value: '',
        isEnabled: true,
        isLiveRegion: false,
        hasTapAction: true,
      ),
    );
  });

  for (final busy in [false, true]) {
    testWidgets('${busy ? 'busy' : 'disabled'} releases a held press', (
      tester,
    ) async {
      var activations = 0;
      void activate() => activations++;
      await tester.pumpWidget(buttonApp(onPressed: activate));
      final label = find.text('Launch');
      final releasedPosition = tester.getTopLeft(label);
      final gesture = await tester.startGesture(tester.getCenter(label));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(label), releasedPosition + const Offset(0, 3));

      await tester.pumpWidget(
        buttonApp(onPressed: busy ? activate : null, busy: busy),
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(label), releasedPosition);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(activations, 0);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(buttonApp(onPressed: activate));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(label), releasedPosition);
      await tester.tap(label);
      expect(activations, 1);
    });
  }

  for (final compact in [false, true]) {
    testWidgets('busy replaces the icon without resizing (compact: $compact)', (
      tester,
    ) async {
      await tester.pumpWidget(buttonApp(onPressed: () {}, compact: compact));
      final button = find.byType(SkyButton);
      final readySize = tester.getSize(button);
      final labelPosition = tester.getTopLeft(find.text('Launch'));

      await tester.pumpWidget(
        buttonApp(onPressed: () {}, compact: compact, busy: true),
      );
      expect(tester.getSize(button), readySize);
      expect(tester.getTopLeft(find.text('Launch')), labelPosition);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'iconless busy buttons keep the label and a stable spinner slot',
    (tester) async {
      await tester.pumpWidget(
        buttonApp(onPressed: () {}, icon: null, busy: true),
      );
      final label = find.text('Launch');
      final spinner = find.byType(CircularProgressIndicator);
      final buttonSize = tester.getSize(find.byType(SkyButton));
      final labelBounds = tester.getRect(label);
      final spinnerBounds = tester.getRect(spinner);
      expect(spinnerBounds.left, greaterThan(labelBounds.right));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSize(find.byType(SkyButton)), buttonSize);
      expect(tester.getRect(label), labelBounds);
      expect(tester.getRect(spinner), spinnerBounds);
      expect(tester.takeException(), isNull);
    },
  );
}
