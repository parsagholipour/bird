import 'package:flutter_test/flutter_test.dart';

import 'neferhoo_viability.dart';

/// Neferhoo for a slow, coarse player (a tap at most every 40 frames: 1.5 a
/// second), all three stages at 640, 800 and 864 px: the design's search
/// (`neferhoo_viability.dart`). The design measured every letter scenario
/// fully viable, the ankh 99.7% and two ankhs 98.3% for a lock at the bottom
/// clamp (.75: states near the floor falling fast); these hold as floors.
double floorFor(Scenario s) => switch (s.kind) {
  ScenarioKind.stream || ScenarioKind.express => 1,
  ScenarioKind.ankh => .995,
  ScenarioKind.twoAnkhs => .98,
};

void main() {
  final viability = Viability(gap: 40);
  for (final px in [640, 800, 864]) {
    test('$px px, 1.5 taps a second: every scenario has a way through from '
        'nearly every state', () {
      for (final scenario in scenarios(few: true)) {
        final (hazards, end) = scenario.at(px / 360);
        final verdict = viability.judge(hazards, end, scenario.y);
        // ignore: avoid_print
        print(
          '$px coarse stage ${scenario.stage} ${scenario.label.padRight(15)} '
          'near ${(verdict.near * 100).toStringAsFixed(1)}% '
          'anywhere ${(verdict.anywhere * 100).toStringAsFixed(2)}% '
          'budget ${verdict.budget.toStringAsFixed(1)} s',
        );
        expect(
          verdict.near,
          greaterThanOrEqualTo(floorFor(scenario)),
          reason: '$px ${scenario.label}',
        );
        // Where every start is viable, a slow player still has a second
        // or more to notice (the few doomed starts of a lock at the bottom
        // clamp leave no budget to measure).
        if (verdict.near == 1) {
          expect(verdict.budget, greaterThanOrEqualTo(1.0));
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
