import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/ui/flight_score.dart';
import 'package:push_up_bird/ui/match_hud.dart';
import 'package:push_up_bird/ui/theme.dart';

Widget badge(int score, {bool reduced = false, bool disabled = false}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disabled),
        child: IgnorePointer(
          child: FlightScore(score: score, reducedMotion: reduced),
        ),
      ),
    );

double scale(WidgetTester tester) => tester
    .widget<ScaleTransition>(
      find.descendant(
        of: find.byType(FlightScore),
        matching: find.byType(ScaleTransition),
      ),
    )
    .scale
    .value;

void main() {
  testWidgets('digits update immediately with one quiet semantic label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(badge(9));
    expect(scale(tester), 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(scale(tester), 1);
    await tester.pumpWidget(badge(10));
    expect(find.text('10'), findsOneWidget);
    expect(find.text('9'), findsNothing);
    expect(scale(tester), 1);
    final text = tester.widget<Text>(find.text('10'));
    expect(text.style!.fontFamily, 'Fredoka');
    expect(text.style!.fontSize, 56);
    expect(text.style!.fontWeight, FontWeight.w700);
    final plate = tester.widget<MatchPlate>(
      find.descendant(
        of: find.byType(FlightScore),
        matching: find.byType(MatchPlate),
      ),
    );
    expect(plate.color, SkyColors.cream);
    expect(find.bySemanticsLabel('Score 10'), findsOneWidget);
    expect(find.bySemanticsLabel('10'), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Score 10'))
          .flagsCollection
          .isLiveRegion,
      isFalse,
    );
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('pulse is bounded, finite, repeatable and cancels on reset', (
    tester,
  ) async {
    await tester.pumpWidget(badge(1));
    await tester.pumpWidget(badge(1));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(badge(2));
    final size = tester.getSize(find.byType(ScaleTransition));
    for (var elapsed = 20; elapsed <= 280; elapsed += 20) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(scale(tester), inInclusiveRange(1, 1.08));
      if (elapsed == 100) expect(scale(tester), greaterThan(1.05));
      expect(tester.getSize(find.byType(ScaleTransition)), size);
      if (elapsed == 120) await tester.pumpWidget(badge(2));
    }
    expect(scale(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(badge(3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scale(tester), greaterThan(1));
    await tester.pumpWidget(badge(4));
    expect(find.text('4'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(scale(tester), greaterThan(1));
    await tester.pump(const Duration(milliseconds: 180));
    expect(scale(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
    for (final value in [2, 0]) {
      await tester.pumpWidget(badge(5));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(badge(value));
      expect(find.text('$value'), findsOneWidget);
      expect(scale(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    }
  });

  testWidgets('either reduced-motion setting immediately stops a pulse', (
    tester,
  ) async {
    for (final system in [false, true]) {
      await tester.pumpWidget(badge(0));
      await tester.pumpWidget(badge(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(tester), greaterThan(1));
      await tester.pumpWidget(badge(1, reduced: !system, disabled: system));
      expect(scale(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(badge(2, reduced: !system, disabled: system));
      expect(find.text('2'), findsOneWidget);
      expect(scale(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(badge(2));
      expect(scale(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(badge(3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(tester), greaterThan(1));
      await tester.pumpAndSettle();
    }
  });
}
