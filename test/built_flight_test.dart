import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';
import 'campaign_flight.dart';

/// World positions of what a flight has laid, as first seen.
class Laid {
  final gates = <double>[], stars = <double>[], hearts = <double>[];
  final enemies = <double>[];
  final _seen = <Object>{};

  void watch(FlightSimulation sim) {
    void see(Object thing, double x, List<double> into) {
      if (_seen.add(thing)) into.add(sim.distance + x);
    }

    for (final o in sim.obstacles) {
      see(o, o.x, gates);
    }
    for (final star in sim.stars) {
      see(star, star.x, stars);
    }
    for (final heart in sim.heartPickups) {
      see(heart, heart.x, hearts);
    }
    for (final enemy in sim.enemies) {
      see(enemy, enemy.x, enemies);
    }
  }
}

void main() {
  test('every mode flies a built level to its finish line', () {
    for (final mode in PlayMode.values) {
      final plan = sampleLevel(mode);
      final sim = builtFlight(plan)..hearts = 2;
      var hearts = 0;
      flyBuilt(
        sim,
        watch: (s) {
          if (s.events.any((e) => e.kind == FlightEventKind.heart)) hearts = 1;
        },
      );
      expect(sim.endReason, EndReason.completed, reason: mode.name);
      expect(sim.finishLine, isNotNull, reason: mode.name);
      expect(sim.starsLaid, plan.totalStars, reason: mode.name);
      expect(
        sim.levelStars,
        plan.rate(finished: true, stars: sim.collectedStars),
      );
      expect(sim.levelStars, greaterThanOrEqualTo(2), reason: mode.name);
      // A placed heart is caught in every mode, camera modes too.
      expect(hearts, 1, reason: mode.name);
      expect(sim.hearts, 3, reason: mode.name);
      expect(sim.region, WorldRegion.jungle);
      if (mode != PlayMode.jump) {
        expect(sim.collectedStars, plan.totalStars, reason: mode.name);
        expect(sim.gates, plan.gates.length, reason: mode.name);
      }
    }
  });

  test('every item is laid at its own place on the route', () {
    for (final mode in [PlayMode.touch, PlayMode.squat]) {
      final plan = sampleLevel(
        mode,
        extra: [
          if (mode == PlayMode.touch)
            const BuiltEnemy(x: 5500, y: 300, kind: EnemyKind.duskMoth),
          const BuiltStar(x: 4500, y: 500),
        ],
      ).copyWith(marks: const StarMarks(1, 1));
      final laid = Laid();
      final sim = builtFlight(plan);
      flyBuilt(sim, keepAlive: true, shoot: false, watch: laid.watch);
      expect(sim.endReason, EndReason.completed, reason: mode.name);
      void same(List<double> flown, Iterable<double> placed) {
        final sorted = placed.toList()..sort();
        expect(flown.length, sorted.length, reason: mode.name);
        for (var i = 0; i < flown.length; i++) {
          expect(flown[i], closeTo(sorted[i], 1e-9), reason: mode.name);
        }
      }

      same(laid.gates, [for (final gate in plan.gates) gate.worldX]);
      same(laid.hearts, [
        for (final heart in plan.items.whereType<BuiltHeart>()) heart.worldX,
      ]);
      same(laid.stars, [
        for (final item in plan.items)
          ...switch (item) {
            BuiltStar() => [item.worldX],
            BuiltTrio() => [
              for (final i in [-1, 0, 1])
                item.worldX + i * BuiltTrio.spacing / BuiltPlan.unit,
            ],
            _ => const <double>[],
          },
      ]);
      if (mode == PlayMode.touch) {
        expect(laid.enemies, [closeTo(5.5, 1e-9)]);
      }
    }
  });

  test('a moving gate meets the bird at its placed phase', () {
    for (final (pace, phase) in [
      (BuiltPace.relaxed, 90),
      (BuiltPace.brisk, 270),
      (BuiltPace.steady, 45),
    ]) {
      final base = sampleLevel(PlayMode.touch, gates: 4, pace: pace);
      final plan = base.copyWith(
        items: [
          for (final item in base.items)
            if (item is BuiltGate)
              item.copyWith(
                kind: ObstacleKind.windLift,
                amp: 65,
                phase: phase,
                cycle: 2000,
              )
            else
              item,
        ],
      );
      expect(plan.problem, isNull);
      final sim = builtFlight(plan);
      final met = <double>[];
      final passed = <Obstacle>{};
      flyBuilt(
        sim,
        keepAlive: true,
        watch: (s) {
          for (final o in s.obstacles) {
            if (o.x + o.width / 2 <= FlightSimulation.birdX && passed.add(o)) {
              met.add(o.angle % (math.pi * 2));
            }
          }
        },
      );
      expect(met, hasLength(4));
      // One 20 ms frame of swing is the tolerance.
      final perFrame = .02 * sim.speed / 2.0 * math.pi * 2;
      for (final angle in met) {
        expect(angle, closeTo(phase * math.pi / 180, perFrame + 1e-6));
      }
    }
  });

  test('a Tap & Fly level carries enemies, doors and a boss finale', () {
    final plan = BuiltPlan(
      id: 'u-bossfinale',
      name: 'Boss Finale',
      mode: PlayMode.touch,
      region: WorldRegion.aztec,
      finish: 9000,
      marks: const StarMarks(3, 6),
      boss: BossKind.baronBat,
      items: const [
        BuiltTrio(x: 2800, y: 500),
        BuiltGate(x: 3200, y: 500, gap: 420, door: true),
        BuiltEnemy(x: 4400, y: 450, kind: EnemyKind.caveBat),
        BuiltTrio(x: 5200, y: 450),
        BuiltGate(x: 5500, y: 450, gap: 420),
      ],
    );
    expect(plan.problem, isNull);
    final sim = builtFlight(plan, weaponDamage: 40);
    expect(sim.offersShoot, isTrue);
    double? bossAt, lineAt;
    var doors = 0;
    flyLevel(
      sim,
      watch: (s) {
        if (s.obstacles.any((o) => o.door != null)) doors = 1;
        if (bossAt == null && (s.vanguard != null || s.boss != null)) {
          bossAt = s.distance + FlightSimulation.birdX;
        }
        if (lineAt == null && s.finishLine != null) {
          lineAt = s.finishLine!.worldX;
        }
      },
    );
    expect(sim.endReason, EndReason.completed);
    expect(doors, 1);
    expect(sim.bossesDefeated, 1);
    // The fight starts when the bird reaches the mark, and the line is laid
    // after the boss, as on a campaign boss level.
    expect(bossAt, closeTo(plan.finishX, .03));
    expect(lineAt, greaterThan(plan.finishX + 1));
    expect(sim.levelStars, greaterThan(0));
  });

  test('push-ups slow down for a slow player and keep the workout', () {
    final speeds = {
      for (final cycle in [2.0, 3.0, 6.0, 12.0])
        cycle: BuiltPlan.tempo(PushUpFlightMode(cycleSeconds: cycle)),
    };
    expect(speeds[2.0], 1);
    expect(speeds[3.0], 1);
    expect(speeds[6.0], closeTo(2.15 / 3.65, 1e-12));
    expect(speeds[12.0], BuiltPlan.slowestTempo);
    expect(BuiltPlan.tempo(SquatFlyMode(cycleSeconds: 6)), speeds[6.0]);
    expect(BuiltPlan.tempo(JumpFlyMode()), 1);
    expect(BuiltPlan.tempo(TapFlyMode()), 1);
    final plan = sampleLevel(PlayMode.pushUp, pace: BuiltPace.steady);
    for (final cycle in [2.0, 3.0, 6.0, 12.0]) {
      final sim = builtFlight(plan, cycle: cycle);
      expect(
        sim.speed,
        closeTo(.30 * .9 * 1.15 * BuiltPlan.tempo(sim.rules), 1e-12),
      );
      var hits = 0, last = sim.hearts;
      var shield = sim.shield;
      flyBuilt(
        sim,
        cycle: cycle,
        watch: (s) {
          if (s.hearts < last || (shield && !s.shield)) hits++;
          last = s.hearts;
          shield = s.shield;
        },
      );
      expect(sim.endReason, EndReason.completed, reason: '$cycle');
      expect(hits, 0, reason: 'cycle $cycle');
      expect(sim.gates, plan.gates.length, reason: '$cycle');
      expect(sim.levelStars, greaterThanOrEqualTo(2), reason: '$cycle');
    }
  });

  test('built plans fly only their own mode, solo, at rules 64', () {
    final push = sampleLevel(PlayMode.pushUp);
    expect(
      () => FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
        plan: push,
      ),
      throwsArgumentError,
    );
    expect(
      () => builtFlight(
        push,
        version: FlightSimulation.passingRivalsRulesVersion,
      ),
      throwsArgumentError,
    );
    expect(
      () => FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
        plan: sampleLevel(PlayMode.touch),
        coop: CoopMode.roped,
      ),
      throwsArgumentError,
    );
    expect(
      () => FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: false,
        course: FlightCourse.classic,
        plan: push,
      ),
      throwsArgumentError,
    );
    // A campaign level stays Tap & Fly only.
    expect(
      () => FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: false,
        course: FlightCourse.starTrail,
        plan: Campaign.level('1-1')!.plan,
      ),
      throwsArgumentError,
    );
    expect(builtFlight(push).route!.boss, isFalse);
  });
}
