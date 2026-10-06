import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/built_reach.dart';
import 'package:push_up_bird/domain/built_templates.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';
import 'campaign_flight.dart';

void main() {
  test('the starter levels are valid, read-only and cover every mode', () {
    final all = BuiltTemplates.all;
    expect({for (final level in all) level.id}, hasLength(all.length));
    expect({for (final level in all) level.plan.mode}, PlayMode.values.toSet());
    for (final level in all) {
      expect(level.id, startsWith('t-'), reason: level.id);
      expect(BuiltPlan.isBuiltId(level.id), isTrue, reason: level.id);
      expect(level.template, isTrue);
      expect(level.plan.problem, isNull, reason: level.id);
      expect(
        BuiltReach.check(level.plan).where((i) => i.blocking),
        isEmpty,
        reason: level.id,
      );
      expect(BuiltTemplates.byId(level.id), same(level));
    }
    expect(BuiltTemplates.byId('u-notatempl'), isNull);
    expect(BuiltReach.reps(BuiltTemplates.byId('t-push-1')!.plan), 10);
  });

  test('every starter level is cleared by a pilot, at any tempo', () {
    for (final level in BuiltTemplates.all) {
      final plan = level.plan;
      final cycles = plan.mode.controlsHeight ? [2.0, 3.0, 6.0, 10.0] : [3.0];
      for (final cycle in cycles) {
        final sim = builtFlight(plan, cycle: cycle, weaponDamage: 30);
        var hits = 0, hearts = sim.hearts;
        var shield = sim.shield;
        void watch(FlightSimulation s) {
          if (s.hearts < hearts || (shield && !s.shield)) hits++;
          hearts = s.hearts;
          shield = s.shield;
        }

        if (plan.boss != null) {
          flyLevel(sim, watch: watch);
        } else {
          flyBuilt(sim, cycle: cycle, keepAlive: true, watch: watch);
        }
        final why = '${level.id} at $cycle s';
        expect(sim.endReason, EndReason.completed, reason: why);
        expect(sim.gates, plan.gates.length, reason: why);
        expect(sim.levelStars, greaterThanOrEqualTo(2), reason: why);
        if (plan.mode.controlsHeight) {
          // A push-up or squat level is a workout anyone can finish clean.
          expect(hits, 0, reason: why);
          expect(sim.levelStars, 3, reason: why);
          expect(sim.repetitions, BuiltReach.reps(plan), reason: why);
        }
      }
    }
  });
}
