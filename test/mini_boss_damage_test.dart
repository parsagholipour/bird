import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'boss_fight_test.dart' show hover, step;
import 'campaign_flight.dart' show flyLevel;
import 'ny_plans.dart';

/// The mini-bosses (rules 43, campaign only) through a level plan, the way
/// combat_damage_test runs the endless five: any damage is accepted, half
/// health begins fury, the kill pays once. King Coo's chest takes half of a
/// hit while he is fluffed (R2: `king_coo_test` has the puff window and the
/// pop), so these hits are sized to land [dealt]. The Gargoyle's shuttered
/// lamp (R3, `searchlight_gargoyle_test`) only takes damage in the vent, so
/// [fighting] holds his lamp open here.

/// The rock damage that costs [kind] [dealt] health on a fluffed, idle hit.
int rockFor(BossKind kind, int dealt) =>
    kind == BossKind.kingCoo ? dealt * 2 : dealt;

/// A real level flight, run-up flown by the shared bot, stopped as the
/// mini-boss [kind] begins to fight, with the score it had by then.
({FlightSimulation sim, int score}) fighting(BossKind kind) {
  final plan = nyPlan(
    id: kind == BossKind.kingCoo ? '3-2' : '3-4',
    lineup: const [EnemyKind.simpleBat],
    boss: kind,
  );
  final sim = nyFlight(plan);
  flyLevel(sim, until: (sim) => sim.boss?.phase == BossPhase.attacking);
  expect(sim.boss, isNotNull);
  expect(sim.phase, RunPhase.playing);
  hover(sim, .1);
  // The Gargoyle's lamp is open in the vent, 6.4 s into his 9 s cycle.
  if (kind == BossKind.searchlightGargoyle) {
    sim.boss!.age = sim.boss!.arrivalDuration + 6.6;
  }
  return (sim: sim, score: sim.score);
}

void main() {
  for (final kind in BossKind.values.where((kind) => kind.campaignOnly)) {
    test(
      '$kind accepts arbitrary damage, crosses half health, and pays once',
      () {
        final (:sim, :score) = fighting(kind);
        final boss = sim.boss!;
        expect(boss.kind, kind);
        expect(boss.phase, BossPhase.attacking);
        expect(boss.maxHp, kind == BossKind.kingCoo ? 140 : 160);
        final damage = boss.maxHp ~/ 2 + 3;
        sim.rocks.add(
          BirdRock(x: boss.x - .07, y: boss.y, damage: rockFor(kind, damage)),
        );
        step(sim);
        expect(boss.hp, boss.maxHp - damage);
        expect(boss.lastDamage, damage);
        expect(boss.enraged, isTrue);
        expect(boss.enragedAt, boss.lastHitAt);
        final enragedAt = boss.enragedAt;
        sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: 2));
        step(sim);
        expect(boss.enragedAt, enragedAt);
        final beforeKill = boss.hp;
        for (var i = 0; i < 3; i++) {
          sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: 1000));
        }
        step(sim);
        expect(boss.hp, 0);
        expect(boss.lastDamage, beforeKill);
        expect(boss.phase, BossPhase.defeated);
        expect(sim.bossesDefeated, 1);
        expect(sim.score - score, FlightSimulation.bossBonus);
        expect(
          sim.events.where((e) => e.kind == FlightEventKind.bossDefeated),
          hasLength(1),
        );
        // The level then glides to its finish line.
        expect(sim.victoryGlide, isTrue);
      },
    );
  }

  test('a mini-boss\'s hit circle is the usual boss circle', () {
    for (final kind in BossKind.values.where((kind) => kind.campaignOnly)) {
      final sim = fighting(kind).sim;
      final boss = sim.boss!;
      // A rock just outside the circle passes; one touching it lands.
      sim.rocks.add(
        BirdRock(x: boss.x - SkyBoss.radius - .05, y: boss.y, damage: 10),
      );
      step(sim, .001);
      expect(boss.hp, boss.maxHp, reason: '${kind.name} outside');
      sim.rocks.clear();
      sim.rocks.add(
        BirdRock(x: boss.x - SkyBoss.radius, y: boss.y, damage: 10),
      );
      step(sim, .001);
      expect(
        boss.hp,
        boss.maxHp - (kind == BossKind.kingCoo ? 5 : 10),
        reason: '${kind.name} touching',
      );
    }
  });

  test('a mini-boss level clears the level\'s passages, enemies and steam', () {
    for (final kind in BossKind.values.where((kind) => kind.campaignOnly)) {
      final sim = fighting(kind).sim;
      expect(sim.obstacles, isEmpty);
      expect(sim.enemies, isEmpty);
      expect(sim.steamVents, isEmpty);
      expect(sim.bossAmmo, isEmpty);
      expect(sim.stars, isEmpty);
    }
  });
}
