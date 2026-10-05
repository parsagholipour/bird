import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart';
import 'king_coo_helpers.dart';

/// Rules version 62: two pigeons of each squadron King Coo whistles in (the
/// V's outer wing tips, or the blockers flanking a picket's gap) throw one
/// crust each at the bird as the squadron is about to pass it.

const _throwers = FlightSimulation.squadThrowersRulesVersion;

/// The real 3-2 at [version], flown by the shared bot until King Coo fights
/// his full fight (stage 1), then two whistles (a V and a picket) with a
/// protected bird at mid-height. Returns each whistle-squadron thrower and
/// its x as it threw.
Map<SkyEnemy, List<double>> _throws(int version) {
  final sim = levelFlight(Campaign.level('3-2')!, version: version);
  flyLevel(sim, until: (sim) => sim.boss?.phase == BossPhase.attacking);
  expectFighting(sim);
  final boss = sim.boss!;
  boss.hp = 300;
  tick(sim);
  expect(boss.stageReached, 1);
  final thrown = <SkyEnemy, List<double>>{};
  final volleys = <SkyEnemy, int>{};
  run(
    sim,
    60,
    hold: .5,
    protect: true,
    until: (sim) => sim.boss!.whistles >= 2 && sim.boss!.cooCycle >= 13,
    each: (sim) {
      for (final e in sim.enemies) {
        if (e.track == null) continue;
        final before = volleys[e] ?? 0;
        if (e.volleys > before) thrown.putIfAbsent(e, () => []).add(e.x);
        volleys[e] = e.volleys;
      }
    },
  );
  expect(boss.whistles, 2);
  return thrown;
}

void main() {
  test('62 throws crusts and is in force', () {
    expect(_throwers, 62);
    expect(
      FlightSimulation.currentRulesVersion,
      greaterThanOrEqualTo(_throwers),
    );
  });

  test('before 62 the whistle squadron throws nothing', () {
    expect(_throws(_throwers - 1), isEmpty);
  });

  test('two pigeons of each call throw once, just before passing', () {
    final thrown = _throws(_throwers);
    expect(thrown, hasLength(2 * KingCoo.squadThrowers));
    for (final xs in thrown.values) {
      expect(xs, hasLength(1), reason: 'one crust each');
      expect(xs.single, greaterThan(FlightSimulation.birdX + .40));
      expect(
        xs.single,
        lessThanOrEqualTo(FlightSimulation.birdX + KingCoo.throwAhead + .01),
      );
    }
  });

  test('the throwers are the V\'s wing tips and the gap\'s flanks', () {
    final v = KingCoo.squad(cycle: 0, birdY: .5, fury: false).single;
    expect(KingCoo.throwers(v).map((i) => v.slots[i].y), [.35, .65]);
    final picket = KingCoo.squad(cycle: 1, birdY: .2, fury: false).single;
    final gap = picket.gap!;
    expect(KingCoo.throwers(picket).map((i) => picket.slots[i].y), [
      gap - KingCoo.picketFirst,
      gap + KingCoo.picketFirst,
    ]);
  });
}
