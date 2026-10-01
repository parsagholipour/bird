import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart';
import 'ny_plans.dart';

/// The steam geyser scaffold (R0): the plan layer (`LevelPlan.steam`), the
/// vents the route lays (`LevelRoute.geysers`), the cycle's pure functions
/// and the plan validation. The simulation's vents, hit, lift and scald rules
/// are tested in `steam_test` (R1 replaced the scaffold's inert-steam test
/// there).

LevelPlan alley({SteamPlan steam = SteamPlan.steady, double length = 80}) =>
    nyPlan(
      id: '3-3',
      length: length,
      seed: 3103,
      start: 100,
      lineup: const [EnemyKind.simpleBat, EnemyKind.alleyPigeon],
      steam: steam,
      marks: const StarMarks(55, 90),
    );

LevelRoute routeOf(LevelPlan plan) => nyFlight(plan).route!;

void main() {
  test('the default plan has no steam and lays no vents', () {
    final plan = nyPlan();
    expect(plan.steam.isEmpty, isTrue);
    expect(identical(plan.steam, SteamPlan.none), isTrue);
    expect(routeOf(plan).geysers, isEmpty);
    expect(routeOf(nyPlan(boss: BossKind.kingCoo)).geysers, isEmpty);
  });

  test('the steady and sparse presets are the designer\'s levels', () {
    expect(SteamPlan.steady.slots(40), [4, 8, 12, 16, 20, 24, 28, 32]);
    expect(SteamPlan.sparse.slots(40), [4, 8, 12]);
    expect(
      [for (var i = 0; i < 8; i++) SteamPlan.steady.kindAt(i)],
      [for (var i = 0; i < 8; i++) i.isEven ? SteamKind.hop : SteamKind.ride],
    );
    expect(SteamPlan.sparse.kindAt(0), SteamKind.ride);
    expect(SteamPlan.sparse.kindAt(1), SteamKind.hop);
    // Slots stop at the passages the route has.
    expect(SteamPlan.steady.slots(10), [4, 8]);
    expect(SteamPlan.none.slots(40), isEmpty);
    expect(alley().problem, isNull);
    expect(alley(steam: SteamPlan.sparse, length: 30).problem, isNull);
  });

  test('plan validation: spacing, pattern and enemy passages', () {
    String? problem(SteamPlan steam) => alley(steam: steam).problem;
    expect(problem(const SteamPlan(first: 3, every: 4, pattern: 'H')), 'steam');
    expect(problem(const SteamPlan(first: 4, every: 2, pattern: 'H')), 'steam');
    expect(
      problem(const SteamPlan(first: 8, every: 4, last: 4, pattern: 'H')),
      'steam',
    );
    expect(
      problem(const SteamPlan(first: 4, every: 4, pattern: 'HX')),
      'steam',
    );
    // A lineup at cadence 2 leads the odd passages: a slot may not sit on one.
    expect(
      problem(const SteamPlan(first: 5, every: 4, last: 33, pattern: 'H')),
      'steam',
    );
    expect(
      problem(const SteamPlan(first: 4, every: 4, last: 12, pattern: 'RH')),
      isNull,
    );
  });

  test('the route lays one vent per slot, on the passage it replaces', () {
    final plan = alley();
    final route = routeOf(plan);
    expect(route.geysers, hasLength(8));
    for (final (i, g) in route.geysers.indexed) {
      expect(g.slot, 4 + 4 * i);
      expect(g.kind, i.isEven ? SteamKind.hop : SteamKind.ride);
      expect(g.x, closeTo(route.passages[g.slot - 1] + .15, 1e-12));
    }
    // Slots come in route order, about one every four passages.
    for (var i = 1; i < route.geysers.length; i++) {
      expect(route.geysers[i].x, greaterThan(route.geysers[i - 1].x));
      expect(
        route.geysers[i].burstAt,
        greaterThan(route.geysers[i - 1].burstAt),
      );
    }
  });

  test('steam changes neither the passages nor the stars of a level', () {
    final with_ = routeOf(alley());
    final without = routeOf(alley(steam: SteamPlan.none));
    expect(with_.passages, without.passages);
    expect(with_.due, without.due);
    expect(with_.stars, without.stars);
    expect(with_.goal, without.goal);
    expect(with_.pieces, hasLength(without.pieces.length));
    expect(without.geysers, isEmpty);
  });

  test('a cruising bird reaches each vent burstAt + arrival seconds in', () {
    // The vent's burst is timed so a hop vent's plume stands as the bird
    // arrives and a ride vent's billow is under way.
    final plan = alley();
    final sim = nyFlight(plan);
    final route = sim.route!;
    final reached = <int, double>{};
    flyLevel(
      sim,
      keepAlive: true,
      sprintWhen: (sim, frame) => false,
      watch: (sim) {
        for (final (i, g) in route.geysers.indexed) {
          if (!reached.containsKey(i) &&
              sim.distance + FlightSimulation.birdX >= g.x) {
            reached[i] = sim.routeSeconds;
          }
        }
      },
    );
    expect(reached, hasLength(route.geysers.length));
    for (final (i, g) in route.geysers.indexed) {
      expect(
        reached[i],
        closeTo(g.burstAt + SteamCycle.arrival(g.kind), .05),
        reason: 'slot ${g.slot}',
      );
    }
  });

  test('the cycle: hiss, burst, billow, sleep, repeating every 4.2 s', () {
    const burstAt = 10.0;
    SteamPhase at(double t) => SteamCycle.phase(t, burstAt);
    expect(SteamCycle.period, closeTo(1.5 + .5 + 1.25 + .95, 1e-12));
    expect(at(burstAt - 1.5), SteamPhase.hiss);
    expect(at(burstAt - .001), SteamPhase.hiss);
    expect(at(burstAt), SteamPhase.burst);
    expect(at(burstAt + .49), SteamPhase.burst);
    expect(at(burstAt + .5), SteamPhase.billow);
    expect(at(burstAt + 1.74), SteamPhase.billow);
    expect(at(burstAt + 1.75), SteamPhase.sleep);
    expect(at(burstAt + 2.69), SteamPhase.sleep);
    expect(at(burstAt + 2.71), SteamPhase.hiss, reason: 'the next cycle');
    // It repeats in both directions, exactly a period apart.
    for (final t in [0.3, 4.1, 9.9, 10.2, 11.4, 12.6, 50.0]) {
      expect(at(t + SteamCycle.period), at(t), reason: '$t');
      expect(at(t - SteamCycle.period), at(t), reason: '$t');
    }
    // The plume and the lift are zero outside their phases.
    expect(SteamCycle.plume(burstAt - .1, burstAt), 0);
    expect(SteamCycle.plume(burstAt, burstAt), 0, reason: 'rises from nothing');
    expect(SteamCycle.plume(burstAt + .25, burstAt), 1);
    expect(SteamCycle.plume(burstAt + .5, burstAt), 0);
    expect(SteamCycle.lift(burstAt + .2, burstAt), 0);
    expect(SteamCycle.lift(burstAt + .5, burstAt), 0, reason: 'fades in');
    expect(SteamCycle.lift(burstAt + 1.0, burstAt), 1);
    expect(SteamCycle.lift(burstAt + 1.75, burstAt), 0);
    expect(SteamCycle.warning(burstAt - 1.5, burstAt), 0);
    expect(SteamCycle.warning(burstAt - .75, burstAt), closeTo(.5, 1e-12));
    expect(SteamCycle.warning(burstAt + .1, burstAt), 0);
    for (var t = 0.0; t < 20; t += .01) {
      final plume = SteamCycle.plume(t, burstAt);
      final lift = SteamCycle.lift(t, burstAt);
      expect(plume, inInclusiveRange(0, 1));
      expect(lift, inInclusiveRange(0, 1));
      // Hot steam and cool steam never overlap.
      expect(plume > 0 && lift > 0, isFalse, reason: '$t');
    }
  });

  test('a geyser\'s phase times follow its burst', () {
    const g = SteamGeyser(slot: 4, x: 5, kind: SteamKind.hop, burstAt: 20);
    expect(g.hissAt, 18.5);
    expect(g.burstEndAt, 20.5);
    expect(g.billowEndAt, 21.75);
    expect(g.phaseAt(18.4), SteamPhase.sleep);
    expect(g.phaseAt(19), SteamPhase.hiss);
    expect(g.phaseAt(20.2), SteamPhase.burst);
    expect(g.phaseAt(21), SteamPhase.billow);
    expect(SteamCycle.arrival(SteamKind.hop), .15);
    expect(SteamCycle.arrival(SteamKind.ride), 1.05);
  });

  test('a vent\'s plume top and mouth', () {
    final short = SteamVent(
      geyser: const SteamGeyser(
        slot: 4,
        x: 5,
        kind: SteamKind.hop,
        burstAt: 20,
      ),
      x: 1.5,
      top: .45,
    );
    final tall = SteamVent(geyser: short.geyser, x: 1.5, top: .6);
    expect(short.mouth, SteamCycle.stackMouth);
    expect(tall.mouth, SteamCycle.coverMouth);
    expect(short.plumeTop(10), 1, reason: 'nothing stands between bursts');
    expect(short.plumeTop(20.25), closeTo(.45, 1e-12));
    expect(tall.kind, SteamKind.hop);
  });

  test('plan JSON round-trips and the old format has no steam key', () {
    final json =
        jsonDecode(jsonEncode(alley().toJson())) as Map<String, dynamic>;
    final back = LevelPlan.fromJson(json);
    expect(back.steam.first, 4);
    expect(back.steam.every, 4);
    expect(back.steam.last, 34);
    expect(back.steam.pattern, 'HR');
    final open = SteamPlan.fromJson({
      'first': 4,
      'every': 4,
      'last': null,
      'pattern': 'H',
    });
    expect(open.last, isNull);
    expect(open.slots(14), [4, 8, 12]);
    expect(() => SteamPlan.fromJson(null), throwsFormatException);
    expect(
      () => SteamPlan.fromJson({'first': 4, 'every': 4, 'pattern': 'H'}),
      returnsNormally,
      reason: 'a missing last reads as no limit',
    );
  });
}
