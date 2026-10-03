import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'neferhoo_viability.dart';

/// Neferhoo is fair at the game's five taps a second, in all three stages
/// and at 640, 800 and 864 px wide: the design's exhaustive viability search
/// (`proof/fair.dart`, here `neferhoo_viability.dart`) over the shipped pure
/// rules. Every state the course edges alone let live has a way through
/// every scenario (the warm-up's mail call, the full fight's ankh, fury's
/// express post and two ankhs, each locked at every height), and a bird may
/// keep hovering where the lock found it for its reaction budget before it
/// must move. The coarse player (1.5 taps a second) is
/// `neferhoo_fairness_coarse_test.dart`.

/// The reaction budgets the design measured at 640 px (s): 1.3 at the
/// ceiling lane, 2.0 elsewhere; 1.9 for the ankh; 1.1 / 1.9 for the express
/// post; 1.8 for two ankhs. Wider screens give more.
double floorFor(Scenario s) => switch (s.kind) {
  ScenarioKind.stream => s.y <= .16 ? 1.3 : 2.0,
  ScenarioKind.ankh => 1.9,
  ScenarioKind.express => s.y <= .16 ? 1.1 : 1.9,
  ScenarioKind.twoAnkhs => 1.8,
};

void main() {
  final viability = Viability();
  for (final px in [640, 800, 864]) {
    test('$px px, five taps a second: every scenario of every stage has a '
        'way through from every state, with time to react', () {
      for (final scenario in scenarios()) {
        final (hazards, end) = scenario.at(px / 360);
        final verdict = viability.judge(hazards, end, scenario.y);
        // ignore: avoid_print
        print(
          '$px stage ${scenario.stage} ${scenario.label.padRight(15)} '
          'near ${(verdict.near * 100).toStringAsFixed(1)}% '
          'anywhere ${(verdict.anywhere * 100).toStringAsFixed(2)}% '
          'budget ${verdict.budget.toStringAsFixed(1)} s',
        );
        expect(verdict.near, 1, reason: '$px ${scenario.label}');
        expect(verdict.anywhere, 1, reason: '$px ${scenario.label}');
        expect(
          verdict.budget,
          greaterThanOrEqualTo(floorFor(scenario) - 1e-9),
          reason: '$px ${scenario.label}',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  test(
    'the hazards never overlap: the stream has passed the bird before the '
    'ankh can reach it, and the ankh is home long before the next stream',
    () {
      for (var width = 1.6; width <= 2.4 + 1e-9; width += .05) {
        final hand = handOf(width);
        for (final fury in [false, true]) {
          final letters = stream(.5, fury: fury);
          final flying = ankhs(.5, fury: fury);
          // The last letter leaves the bird's reach (cycle seconds)...
          const reach =
              Neferhoo.letterHalfWidth + FlightSimulation.birdRadius + .01;
          final streamGone =
              Neferhoo.mailLockAt +
              letters.last.releaseAt +
              (hand - birdX + reach) / letters.last.speed;
          // ...long before the first ankh's pass reaches the bird,
          final turnX = Neferhoo.turnX(birdX);
          final firstPass =
              Neferhoo.ankhLockAt +
              flying.first.passes(handX: hand, turnX: turnX, column: birdX).$1 -
              (Neferhoo.ankhRadius + FlightSimulation.birdRadius) /
                  flying.first.speed;
          expect(firstPass - streamGone, greaterThan(2.5), reason: '$width');
          // and the last ankh is home with the open sky's second to spare
          // before the next mail call's first letter.
          final home = Neferhoo.ankhLockAt + ankhEnd(flying, hand);
          expect(
            Neferhoo.period + Neferhoo.mailReleaseAt - home,
            greaterThan(1.5),
            reason: '$width',
          );
        }
      }
    },
  );

  test('the narrowest free band in fury is the room between the two loops, '
      '.154 tall (the Baron\'s screech gap is .224)', () {
    const room =
        Neferhoo.ankhSplit -
        2 * (Neferhoo.ankhRadius + FlightSimulation.birdRadius);
    expect(room, closeTo(.154, 1e-9));
    // A lock at a clamp leaves the far side open too: at least .25 of
    // sky beyond the outer lane's reach.
    for (final y in [Neferhoo.ankhTop, Neferhoo.ankhBottom]) {
      final edge = y < .5 ? y : 1 - y;
      expect(
        edge - (Neferhoo.ankhRadius + FlightSimulation.birdRadius),
        greaterThan(.16),
      );
    }
    expect(Neferhoo.backLane(.25), closeTo(.57, 1e-12));
    expect(Neferhoo.backLane(.75), closeTo(.43, 1e-12));
  });
}
