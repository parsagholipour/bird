import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';

import 'campaign_flight.dart' show levelFlight;
import 'ny_pilots.dart';

/// 2-6's star marks, from its real route and proven reachable by mortal
/// pilots. A guardian's stars are his run-up's (nothing is laid after he
/// arrives), so the pilots fly the run-up and stop as he begins to fight;
/// winning the fight is the first star (`neferhoo_pilot_test.dart`).

const _screens = {'640': 640 / 360, '800': 800 / 360, '864': 864 / 360};

void main() {
  test('2-6: 36 route stars, marks 20 and 30 (50% and 80%, to fives)', () {
    final level = Campaign.level('2-6')!;
    final sim = levelFlight(level);
    final route = sim.route!;
    expect(route.stars, 36);
    expect(route.stars, 3 * route.passages.length);
    int five(double v) => (v / 5).round() * 5;
    expect(
      (level.marks.two, level.marks.three),
      (five(route.stars * .5), five(route.stars * .8)),
    );
    expect((level.marks.two, level.marks.three), (20, 30));
    expect(level.plan.problem, isNull);
    expect(level.isBoss, isTrue);
  });

  test('2-6: the run-up gives every pilot two stars and the sharp and '
      'average ones three, at every phase and phone', () {
    final level = Campaign.level('2-6')!;
    for (final skill in Skill.values) {
      var n = 0, three = 0, two = 0;
      final harvests = <int>[];
      for (final width in _screens.values) {
        for (final phase in spreadPhases(6)) {
          final run = flyNewYork(
            '2-6',
            skill: skill,
            width: width,
            phase: phase,
            stopAtBoss: true,
          );
          n++;
          final stars = run.starsAtBoss;
          expect(stars, isNotNull, reason: '${skill.name}: reached him');
          expect(run.sim.boss!.isNeferhoo, isTrue);
          harvests.add(stars!);
          if (stars >= level.marks.three) three++;
          if (stars >= level.marks.two) two++;
        }
      }
      harvests.sort();
      // ignore: avoid_print
      print(
        '2-6 ${skill.name.padRight(8)} run-up stars ${harvests.first}-'
        '${harvests.last} (median ${harvests[n ~/ 2]} of 36): '
        'two $two/$n, three $three/$n',
      );
      expect(two / n, greaterThanOrEqualTo(.95), reason: skill.name);
      if (skill != Skill.casual) {
        expect(three / n, greaterThanOrEqualTo(.9), reason: skill.name);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
