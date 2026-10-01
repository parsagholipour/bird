import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'gargoyle_pilot.dart';

/// How long the Searchlight Gargoyle's fight takes (report 04 §1): his lamp is
/// open 29% of the time, so the length comes from the gating, not the health.
/// Three pilots that dodge everything (see `gargoyle_pilot.dart`) and differ
/// only in how they shoot stand in for a sharp, an average and a casual
/// player. The report's model (base weapon, 160 health): sharp 35 s (27-44),
/// average 62 s (52-80), casual 133 s (98-170); the fight in these tests is
/// from the moment control returns to the killing blow, without his 4.6 s
/// arrival and 3.8 s defeat. The lamp is judged as a rock leaves the bird (fix
/// round), so the usable window is the vent the player sees, 2.1 s after a
/// half-second reaction, at every width: the model's own assumption.

typedef Result = ({double seconds, FlightSimulation sim});

Result fight(
  Pilot pilot, {
  double width = 2.2,
  int weaponDamage = BirdRock.baseDamage,
}) {
  final sim = arena(width: width, weaponDamage: weaponDamage);
  final boss = sim.boss!;
  final start = boss.age;
  var frames = 0;
  while (boss.phase == BossPhase.attacking && frames < 60 * 600) {
    pilot.fly(sim, width: width);
    frames++;
  }
  expect(boss.phase, BossPhase.defeated, reason: 'he was beaten');
  return (seconds: boss.age - start, sim: sim);
}

Pilot sharp([int seed = 1]) =>
    Pilot(cadence: .3, fireFrom: 0, window: .09, seed: seed);
Pilot average([int seed = 1]) =>
    Pilot(cadence: .45, fireFrom: .6, window: .3, offTarget: .3, seed: seed);
Pilot casual([int seed = 1]) =>
    Pilot(cadence: .8, fireFrom: 1.0, window: .35, offTarget: .3, seed: seed);

void main() {
  test('the lamp is open 2.6 s of his 9: hittable 29% of the time', () {
    final sim = arena();
    final boss = sim.boss!;
    var open = 0, frames = 0;
    while (boss.combatTime < 5 * 9.0) {
      frame(sim, dt: 1 / 60);
      sim.invulnerableUntil = 1e9;
      sim.birdY = .5;
      sim.velocity = 0;
      frames++;
      if (boss.lampOpen) open++;
    }
    expect(open / frames, closeTo(2.6 / 9, .006));
  });

  for (final width in [1.78, 2.2]) {
    group('at $width screen widths', () {
      test('a sharp player wins in about 26 s and is never touched', () {
        // Perfect aim, firing the moment the lamp opens: the report's sharp
        // player (85% in the lane, 85% hits) takes 35 s. Before the lamp was
        // judged as a rock leaves, the same pilot needed 33 s: its last 0.7 s
        // of vent glanced.
        final (:seconds, :sim) = fight(sharp(), width: width);
        expect(seconds, inInclusiveRange(20, 50));
        final boss = sim.boss!;
        expect((boss.spots, sim.hearts, sim.shield), (0, 3, true));
        expect(boss.sweepsAimed, inInclusiveRange(2, 7));
      });

      test('an average player wins in 45 to 100 s', () {
        for (final seed in [1, 2, 3]) {
          final (:seconds, :sim) = fight(average(seed), width: width);
          expect(seconds, inInclusiveRange(45, 100), reason: 'seed $seed');
          expect(sim.boss!.spots, 0);
          expect((sim.hearts, sim.shield), (3, true));
          // A fight long enough for fury's zone sweep and the slit.
          expect(sim.boss!.sweepSlit, greaterThan(0), reason: 'seed $seed');
        }
      });

      test('a casual player wins in under 3 minutes', () {
        for (final seed in [1, 2]) {
          final (:seconds, :sim) = fight(casual(seed), width: width);
          expect(seconds, inInclusiveRange(60, 180), reason: 'seed $seed');
          expect(sim.boss!.spots, 0);
        }
      });
    });
  }

  test('a weapon three times as strong ends it in the first vent or two', () {
    // No upgrade shop exists yet (every flight fires 10-damage rocks), but if
    // one arrives: 30 damage takes six hits, the first vent's worth, so health
    // is the knob to turn (report 04: 130 to 180).
    final (:seconds, :sim) = fight(sharp(), weaponDamage: 30);
    expect(seconds, inInclusiveRange(7, 30));
    expect(sim.boss!.spots, 0);
  });

  test('the whole encounter is about a minute and a half for an average '
      'player, arrival and defeat included', () {
    final (:seconds, :sim) = fight(average());
    final boss = sim.boss!;
    final encounter = boss.arrivalDuration + seconds + boss.departureDuration;
    expect(encounter, inInclusiveRange(55, 110));
  });
}
