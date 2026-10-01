// M1 integration: King Coo's squadron (R2) are Alley Pigeons (R1) in their
// glider variant. R2 built the squadron against the scaffold's inert pigeon;
// R1 built the raids with squadron pigeons as a named exception. These tests
// fly the two together in real level flights: the run-up's pigeons raid for
// real, the squadron never snatches, follows its track, and is shot or
// smashed like any pigeon, raising BOTH defeat counters (enemiesDefeated and
// pigeonsDefeated) so the audio plays the pigeon's defeat, not a bat's.
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart' show flyLevel;
import 'king_coo_helpers.dart' as coo;
import 'ny_arena.dart' as arena;
import 'ny_plans.dart';

const birdX = FlightSimulation.birdX;

/// A fight flown to the whistle, with the books at the start of it.
({FlightSimulation sim, List<SkyEnemy> squad}) released({
  int weaponDamage = BirdRock.baseDamage,
  double width = 2.2,
}) {
  final sim = coo.cooFight(weaponDamage: weaponDamage, width: width);
  coo.runTo(sim, 9.5, width: width, hold: .5, protect: true);
  return (sim: sim, squad: coo.squadOf(sim));
}

/// Holds the bird at [y] (out of harm's way) and steps [frames] frames.
void settle(FlightSimulation sim, double y, {int frames = 1}) {
  for (var i = 0; i < frames; i++) {
    coo.tick(sim);
    sim
      ..birdY = y
      ..velocity = 0;
  }
}

void main() {
  group('the squadron is the pigeon\'s glider variant', () {
    test('the run-up\'s pigeons raid, the squadron never does', () {
      final sim = nyFlight(
        coo.cooPlan(lineup: const [EnemyKind.alleyPigeon]),
        weaponDamage: BirdRock.baseDamage,
      );
      var sawRaider = false;
      flyLevel(
        sim,
        shootWhen: (s) => false,
        until: (s) => s.boss?.phase == BossPhase.attacking,
        watch: (s) => sawRaider |= s.enemies.any((e) => e.snatches),
      );
      expect(sawRaider, isTrue, reason: 'real raiders in the run-up');
      expect(sim.pigeonWarnings, greaterThan(0));
      expect(sim.starsSnatched, greaterThan(0));
      // The boss's arrival swept the raiders and the stars off the stage.
      expect(sim.enemies.where((e) => e.pigeon != null), isEmpty);
      List<int> books() => [
        sim.starsSnatched,
        sim.starsFreed,
        sim.starsLost,
        sim.pigeonWarnings,
        sim.pigeonDives,
      ];
      final before = books();
      final seen = <SkyEnemy>{};
      coo.runTo(
        sim,
        13.5,
        hold: .5,
        protect: true,
        each: (s) => seen.addAll(s.enemies.where((e) => e.squad)),
      );
      expect(sim.boss!.whistles, greaterThan(0));
      expect(seen, isNotEmpty, reason: 'the squadron flew');
      // No raid: the raid books did not move through the whole squadron.
      expect(books(), before);
    });

    test('every squadron pigeon is a pigeon with no raid state, on its '
        'track', () {
      final (:sim, :squad) = released();
      expect(squad, hasLength(5));
      for (final e in squad) {
        expect(e.kind, EnemyKind.alleyPigeon);
        expect(e.squad, isTrue);
        expect(e.pigeon, isNull);
        expect(e.snatches, isFalse);
        expect(e.charge, 0, reason: 'nothing for enemy_charge to ring');
        expect(e.track, isNotNull);
        expect(e.x, closeTo(e.track!.x(sim.boss!.age), 1e-9));
        expect(e.y, closeTo(e.track!.y(sim.boss!.age), 1e-9));
      }
      // They keep their tracks as time passes (no bob, no drift off it).
      for (var i = 0; i < 30; i++) {
        settle(sim, .5);
        for (final e in squad.where(sim.enemies.contains)) {
          expect(e.y, closeTo(e.track!.y(sim.boss!.age), 1e-9));
          expect(e.x, closeTo(e.track!.x(sim.boss!.age), 1e-9));
        }
      }
    });

    test('a star on its lane is never taken: no prey, no warning, no dive', () {
      final (:sim, :squad) = released();
      final lane = squad.first.y;
      // A star right where the pigeons will fly, in front of each of them.
      final stars = [
        for (final e in squad) SkyStar(x: e.x - .25, y: e.y)..missed = false,
      ];
      sim.stars.addAll(stars);
      final books = [sim.starsSnatched, sim.pigeonWarnings, sim.pigeonDives];
      for (var i = 0; i < 160; i++) {
        settle(sim, lane < .5 ? .85 : .15);
        sim.invulnerableUntil = double.infinity;
        for (final star in stars) {
          expect(star.carried, isFalse);
          expect(star.thief, isNull);
        }
      }
      expect([sim.starsSnatched, sim.pigeonWarnings, sim.pigeonDives], books);
      expect(sim.starsLost, 0);
    });

    test('a squadron pigeon parked beside a raider changes nothing for it', () {
      // The raid plays out the same with and without a glider standing in
      // the trio's airspace (each in its own flight of the same level).
      LevelPlan plan() => arena.rulesPlan();
      String run(bool glider) {
        final sim = arena.arenaOf(plan());
        arena.runUntil(
          sim,
          (s) => arena.raiders(s).isNotEmpty,
          holdY: .9,
          immortal: true,
        );
        final raider = arena.raiders(sim).first;
        if (glider) {
          sim.enemies.add(
            SkyEnemy(
              x: raider.x + .05,
              y: raider.y,
              appearance: EnemyKind.alleyPigeon.index,
              maxHp: 20,
              drift: 0,
              squad: true,
            ),
          );
        }
        final prey = raider.pigeon!.prey!;
        arena.runUntil(
          sim,
          (s) => s.starsSnatched > 0 || prey.missed || prey.collected,
          holdY: .9,
          immortal: true,
          allowEnd: true,
          seconds: 30,
        );
        return '${raider.pigeon!.phase.name} ${sim.starsSnatched} '
            '${raider.pigeon!.prey == null ? 'noprey' : 'prey'} '
            '${prey.thief == null || identical(prey.thief, raider)}';
      }

      expect(run(true), run(false));
    });
  });

  group('shot and smashed like any pigeon', () {
    test('two base rocks (20 health): the first does not spook it, the '
        'second defeats it and raises both counters', () {
      final (:sim, :squad) = released();
      final target = squad.first;
      final enemies = sim.enemiesDefeated, pigeons = sim.pigeonsDefeated;
      final score = sim.score;
      sim.rocks.add(BirdRock(x: target.x - .03, y: target.y, damage: 10));
      settle(sim, .9, frames: 3);
      expect(target.hp, 10);
      expect(sim.enemies, contains(target), reason: 'one rock is not enough');
      expect(target.pigeon, isNull, reason: 'a hit never wakes a raid state');
      expect(target.track, isNotNull);
      expect(sim.enemiesDefeated, enemies);
      expect(sim.pigeonsDefeated, pigeons);
      sim.rocks.add(BirdRock(x: target.x - .03, y: target.y, damage: 10));
      settle(sim, .9, frames: 3);
      expect(sim.enemies, isNot(contains(target)));
      expect(sim.enemiesDefeated, enemies + 1);
      expect(sim.pigeonsDefeated, pigeons + 1, reason: 'the audio\'s cue');
      expect(sim.score, score + 3, reason: 'the defeat bonus');
      final event = sim.events.lastWhere(
        (e) => e.kind == FlightEventKind.enemyHit,
      );
      expect(event.enemyKind, EnemyKind.alleyPigeon);
      // The others fly on.
      expect(sim.enemies.where((e) => e.squad), hasLength(squad.length - 1));
    });

    test('a strong rock (upgraded weapon) defeats it in one', () {
      final (:sim, :squad) = released(weaponDamage: 30);
      final target = squad.last;
      final pigeons = sim.pigeonsDefeated, enemies = sim.enemiesDefeated;
      sim.rocks.add(BirdRock(x: target.x - .03, y: target.y, damage: 30));
      settle(sim, .9, frames: 3);
      expect(sim.enemies, isNot(contains(target)));
      expect(
        [sim.pigeonsDefeated, sim.enemiesDefeated],
        [pigeons + 1, enemies + 1],
      );
    });

    test('a sprint ram smashes one: both counters, and the bird is safe', () {
      final (:sim, :squad) = released();
      final boss = sim.boss!;
      final tip = boss.squad.single.slots[0].y;
      // Wait for the tip to come close, then sprint into it.
      coo.run(
        sim,
        4,
        hold: tip,
        protect: true,
        until: (s) => s.enemies.any((e) => e.squad && e.x < birdX + .35),
      );
      expect(sim.sprint(), isTrue);
      sim.invulnerableUntil = 0;
      final pigeons = sim.pigeonsDefeated, enemies = sim.enemiesDefeated;
      coo.run(sim, 3, hold: tip, until: (s) => s.pigeonsDefeated > pigeons);
      expect(sim.pigeonsDefeated, greaterThan(pigeons));
      expect(sim.enemiesDefeated - enemies, sim.pigeonsDefeated - pigeons);
      expect(sim.shield, isTrue, reason: 'a ram is not a touch');
      expect(sim.hearts, 3);
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.enemyRammed),
        isNotEmpty,
      );
    });

    test('touching one hurts but is no defeat: neither counter moves', () {
      final (:sim, :squad) = released();
      final boss = sim.boss!;
      final tip = boss.squad.single.slots[0].y;
      sim.invulnerableUntil = 0;
      final pigeons = sim.pigeonsDefeated, enemies = sim.enemiesDefeated;
      coo.run(sim, 4, hold: tip, until: (s) => !s.shield);
      expect(sim.shield, isFalse, reason: 'the touch cost the shield');
      expect(sim.pigeonsDefeated, pigeons);
      expect(sim.enemiesDefeated, enemies);
    });

    test('the boss\'s defeat clears the squadron with no defeat counted', () {
      final (:sim, :squad) = released();
      // The squadron is half way across the screen, clear of his chest.
      coo.runTo(sim, 10.6, hold: .5, protect: true);
      final boss = sim.boss!;
      final pigeons = sim.pigeonsDefeated;
      expect(coo.squadOf(sim), isNotEmpty);
      boss.hp = 1;
      sim.rocks.add(BirdRock(x: boss.x - .05, y: boss.y, damage: 40));
      coo.run(sim, 1, hold: .5, protect: true);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.enemies, isEmpty);
      expect(sim.pigeonsDefeated, pigeons);
    });
  });
}
