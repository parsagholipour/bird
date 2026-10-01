import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart';
import 'gargoyle_pilot.dart';
import 'gargoyle_viability.dart';

/// The Searchlight Gargoyle's fix round (reviews 21 and 22): the lamp is
/// judged as a rock leaves the bird, so the fire window is the vent the player
/// sees at every screen width; `previousHitAt`; and the hazards that can meet
/// in his fight (feathers during a sweep, a fury that begins in the perch, the
/// run-up's steam and pigeons at his arrival). The slit's wider corridor and
/// its lag sweep are in `searchlight_gargoyle_fairness_test.dart`.

const _period = SearchlightGargoyle.period;
const _widths = [1.5, 1.6, 1.78, 2.2, 2.4];

/// A rock fired from the bird at [width], [at] seconds into the fight (cycle
/// 0), with the bird held level with the lamp. Returns what it did: the damage
/// it dealt, whether it clinked off the shutters, and the combat time at which
/// it landed.
({int damage, bool glanced, double landedAt}) fireAt(
  double width,
  double at, {
  int hp = 160,
}) {
  final sim = arena(width: width);
  ghost(sim);
  final boss = sim.boss!..hp = hp;
  boss
    ..sweepsAimed = 1
    ..featherCycle = 0
    ..featherSlot = 9;
  jumpTo(boss, at);
  hold(sim, .5, width: width);
  sim
    ..ammo = 1
    ..lastShotAt = double.negativeInfinity;
  expect(sim.shoot(), isTrue, reason: 'the bird fires at $at on $width');
  final rock = sim.rocks.last;
  final glance = boss.lastGlanceAt;
  var guard = 0;
  while (sim.rocks.contains(rock) && guard++ < 600) {
    hold(sim, .5, dt: 1 / 120, width: width);
  }
  expect(sim.rocks.contains(rock), isFalse, reason: 'the rock landed');
  return (
    damage: hp - boss.hp,
    glanced: boss.lastGlanceAt > glance,
    landedAt: boss.combatTime,
  );
}

/// Ghosts the bird (see [ghost] in the pilot file) for a test of the lamp.
void ghost(FlightSimulation sim) => sim.invulnerableUntil = 1e9;

/// A frame of [dt] with the bird held at [y].
void hold(
  FlightSimulation sim,
  double y, {
  double dt = 1 / 120,
  double width = 2.2,
}) {
  sim
    ..birdY = y
    ..velocity = 0;
  frame(sim, dt: dt, width: width);
}

/// Advances the clock to [t] seconds into the fight, a step short.
void jumpTo(SkyBoss boss, double t, {int cycle = 0}) =>
    fightAt(boss, cycle * _period + t - 1 / 120);

void main() {
  group('the lamp is judged as a rock leaves, so the fire window is the '
      'visible vent at every width', () {
    test('a rock fired while the lamp is open counts, however late it lands; '
        'one fired while it is shut glances, however late it lands', () {
      for (final width in _widths) {
        final landings = <double, double>{};
        for (final (at, counts) in [
          (5.0, false),
          (6.2, false), // lands in the vent at any width: still shut as it left
          (6.39, false),
          (6.41, true),
          (7.5, true),
          (8.5, true),
          (8.99, true), // lands in the next perch, after the lamp has shut
          (9.01, false),
          (9.5, false),
        ]) {
          final shot = fireAt(width, at);
          landings[at] = shot.landedAt;
          expect(
            shot.damage,
            counts ? 10 : 0,
            reason: 'fired at $at on a $width wide sky, landed at '
                '${shot.landedAt.toStringAsFixed(2)}',
          );
          expect(shot.glanced, !counts, reason: 'the clink at $at on $width');
        }
        // The rock that left in the last instant of the vent landed after it:
        // 0.35 s later on a narrow sky, 0.76 s on the widest.
        final late = landings[8.99]! - 8.99;
        expect(late, inInclusiveRange(.3, .8), reason: '$width');
        expect(landings[8.99]!, greaterThan(_period));
        // And the one fired before the vent opened landed inside it.
        expect(landings[6.2]!, greaterThan(SearchlightGargoyle.ventAt));
      }
    });

    test('a rock with no release time is still judged where it lands', () {
      // (Scenes built by hand: the unit tests' rocks put on the circle.)
      for (final (age, counts) in [(5.0, false), (6.39, false), (6.41, true)]) {
        final sim = arena();
        ghost(sim);
        final boss = sim.boss!;
        jumpTo(boss, age);
        hold(sim, .5);
        sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y));
        hold(sim, .5);
        expect(160 - boss.hp, counts ? 10 : 0, reason: '$age');
      }
    });

    test('the same trigger finger deals the same damage on every phone', () {
      // Fire every .3 s from the moment the lamp is visibly open to the moment
      // it shuts: nine rocks, 90 damage, at 1.5, 1.6, 1.78, 2.2 and 2.4.
      final landedInside = <double, int>{};
      for (final width in _widths) {
        final sim = arena(width: width);
        ghost(sim);
        final boss = sim.boss!;
        boss
          ..sweepsAimed = 1
          ..featherCycle = 0
          ..featherSlot = 9;
        jumpTo(boss, 6.41);
        var shots = 0;
        var inside = 0;
        final flying = <BirdRock>[];
        var nextShot = 6.41;
        while (boss.combatTime < _period + 1.2) {
          hold(sim, .5, dt: 1 / 120, width: width);
          if (boss.combatTime >= nextShot && nextShot < _period) {
            sim
              ..ammo = 1
              ..lastShotAt = double.negativeInfinity;
            if (sim.shoot()) {
              shots++;
              flying.add(sim.rocks.last);
            }
            nextShot += .3;
          }
          for (final rock in [...flying]) {
            if (!sim.rocks.contains(rock)) {
              flying.remove(rock);
              if (boss.combatTime < _period) inside++;
            }
          }
        }
        expect(shots, 9, reason: '$width');
        expect(160 - boss.hp, 90, reason: 'every rock counts on $width');
        landedInside[width] = inside;
      }
      // Judged where they land (the rule before this fix) the same nine rocks
      // would have counted 8 on the narrowest sky and 7 on the widest: the
      // fight depended on the phone.
      expect(landedInside[1.6], greaterThan(landedInside[2.4]!));
      expect(landedInside[2.4], lessThan(9));
    });

    test('a shatter blast is judged at the release of the rock that made it',
        () {
      // A charged rock meets a pellet short of him; the blast reaches his
      // circle. What counts is whether the lamp was open as the rock left.
      for (final (released, lands, damage) in [
        (6.2, 6.8, 0),
        (6.41, 7.0, 15),
        (8.99, 9.4, 15),
        (9.02, 9.5, 0),
      ]) {
        final sim = arena();
        ghost(sim);
        final boss = sim.boss!;
        boss
          ..sweepsAimed = 1
          ..featherCycle = 0
          ..featherSlot = 9;
        jumpTo(boss, lands);
        hold(sim, .5);
        final pellet = EnemyAmmo(
          x: boss.x - .30,
          y: boss.y,
          vx: 0,
          vy: 0,
          attack: EnemyAttack.aimed,
          bornAt: sim.elapsed,
        );
        sim.enemyAmmo.add(pellet);
        sim.rocks.add(
          BirdRock(
            x: boss.x - .30,
            y: boss.y,
            damage: 30,
            charge: 1,
            releasedAt: boss.arrivalDuration + released,
          ),
        );
        hold(sim, .5);
        expect(sim.ammoShattered, 1, reason: 'released at $released');
        expect(160 - boss.hp, damage, reason: 'released at $released');
        expect(
          boss.lastGlanceAt > double.negativeInfinity,
          damage == 0,
          reason: 'the clink: released at $released',
        );
      }
    });
  });

  group('previousHitAt: the hit before the last', () {
    SkyBoss gargoyle() => SkyBoss(
      number: 7,
      x: 1.7,
      kind: BossKind.searchlightGargoyle,
      cinematic: true,
    );

    test('every landed hit moves the last one back, whoever the boss is', () {
      for (final kind in BossKind.values) {
        final boss = SkyBoss(number: 7, x: 1.7, kind: kind, cinematic: true);
        expect(boss.previousHitAt, double.negativeInfinity);
        expect(boss.hitGap, double.infinity);
        boss.age = 20;
        boss.takeDamage(10);
        expect(boss.lastHitAt, 20, reason: kind.name);
        expect(boss.previousHitAt, double.negativeInfinity);
        boss.age = 20.3;
        boss.takeDamage(10);
        expect((boss.previousHitAt, boss.lastHitAt), (20, 20.3));
        expect(boss.hitGap, closeTo(.3, 1e-12));
        boss.age = 20.58;
        boss.takeDamage(10);
        expect((boss.previousHitAt, boss.lastHitAt), (20.3, 20.58));
      }
    });

    test('a hit that takes nothing, a glance and a shielded hit leave it alone',
        () {
      final boss = gargoyle();
      // Shuttered: the rock clinks off.
      boss.age = boss.arrivalDuration + 1;
      expect(boss.strike(10), 0);
      expect(boss.lastHitAt, double.negativeInfinity);
      expect(boss.previousHitAt, double.negativeInfinity);
      expect(boss.lastGlanceAt, boss.age);
      // Open: a hit lands.
      boss.age = boss.arrivalDuration + 7;
      expect(boss.strike(10), 10);
      final first = boss.lastHitAt;
      boss.age += .3;
      expect(boss.strike(10), 10);
      expect((boss.previousHitAt, boss.lastHitAt), (first, boss.age));
      // Shuttered again (next perch): nothing moves.
      final before = (boss.previousHitAt, boss.lastHitAt);
      boss.age = boss.arrivalDuration + _period + 1;
      expect(boss.strike(10), 0);
      expect((boss.previousHitAt, boss.lastHitAt), before);
      // A dead boss takes nothing and keeps the last two.
      boss.hp = 0;
      boss.age += 1;
      expect(boss.takeDamage(5), 0);
      expect((boss.previousHitAt, boss.lastHitAt), before);
    });

    test('through a fight the weapon lands hits about .28 s apart (never under '
        '.22 s: a rock grazing his circle lands later than one fired level), '
        'and the two latched times are always consecutive hits', () {
      final sim = arena();
      final boss = sim.boss!;
      final pilot = Pilot(cadence: .1); // as fast as the cooldown allows
      final hits = <double>[];
      var last = boss.lastHitAt;
      var frames = 0;
      while (boss.phase == BossPhase.attacking && frames++ < 60 * 200) {
        pilot.fly(sim);
        if (boss.lastHitAt != last) {
          expect(boss.previousHitAt, last, reason: 'consecutive hits');
          last = boss.lastHitAt;
          hits.add(boss.lastHitAt);
          if (hits.length > 1) {
            expect(
              boss.hitGap,
              greaterThanOrEqualTo(.22),
              reason: 'hits ${hits.length - 1} and ${hits.length}',
            );
          }
        }
      }
      expect(hits.length, greaterThan(12));
      // Rapid fire in the vent: hits land .28 s apart, the case the fan blades
      // (a lag of up to .27 s each) need the latch for.
      final gaps = [
        for (var i = 1; i < hits.length; i++) hits[i] - hits[i - 1],
      ];
      expect(gaps.where((g) => g < .31).length, greaterThan(8));
    });
  });

  group('hazards that can meet in his fight', () {
    test('fury that begins as the last rocks of a vent land in the perch: a '
        'calm feather, then a fury sweep from the next warning', () {
      final sim = arena();
      ghost(sim);
      final boss = sim.boss!..hp = 90;
      boss
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      jumpTo(boss, 8.6);
      hold(sim, .5);
      sim
        ..ammo = 1
        ..lastShotAt = double.negativeInfinity;
      expect(sim.shoot(), isTrue);
      final rock = sim.rocks.last;
      // The rock leaves in the vent and lands in the next cycle's perch.
      while (sim.rocks.contains(rock)) {
        hold(sim, .5, dt: 1 / 120);
      }
      expect(boss.gargoyleCycleNumber, 1);
      expect(boss.gargoyleCycle, inInclusiveRange(.2, .5));
      expect(boss.hp, 80);
      expect(boss.enraged, isTrue, reason: 'fury began in the perch');
      // The perch feather left at .2 s, before the rock landed: a calm one.
      expect(
        sim.bossAmmo.where((a) => a.feather).single.vx,
        SearchlightGargoyle.featherSpeed * -1,
      );
      while (boss.sweepsAimed < 2) {
        hold(sim, .8, dt: 1 / 60);
      }
      expect(boss.slitSweep, isFalse, reason: 'fury\'s first sweep is a zone');
      expect(boss.furySweeps, 1);
      expect(boss.beamHalf, .095);
    });

    for (final sweep in const [Sweep.furyZone, Sweep.furySlit]) {
      test('${sweep.name} after a calm perch feather: still a safe path from '
          'every start (the mixed case)', () {
        final bad = <Start>[];
        for (final start in survivableStarts()) {
          final search = Search(
            sweep,
            withPerch: true,
            perchFury: false,
            tail: .5,
          );
          if (!search.fromPerch(start).safe) bad.add(start);
        }
        expect(bad, isEmpty, reason: '$bad');
      });
    }

    test('the real 3-4: nothing of the run-up (steam, pigeons, stars carried) '
        'is in the sky when he fights, and he is beaten unscratched', () {
      final level = Campaign.level('3-4')!;
      expect(level.plan.steam.isEmpty, isFalse);
      expect(level.plan.flocks, isNotEmpty);
      for (final width in [1.78, 2.2]) {
        final sim = levelFlight(level);
        var pigeonsSeen = 0, steamSeen = 0;
        void clearSky() {
          expect(sim.enemies, isEmpty);
          expect(sim.steamVents, isEmpty);
          expect(sim.enemyAmmo, isEmpty);
          expect(sim.swarm, isEmpty);
          expect(sim.meteors, isEmpty);
          expect(sim.lavaVents, isEmpty);
          expect(sim.galeDebris, isEmpty);
          expect(sim.boss!.lobs, isEmpty, reason: 'no crumb bombs: not Coo');
        }

        // The run-up, to the first frame of his arrival.
        flyLevel(
          sim,
          viewportWidth: width,
          sprintWhen: (sim, frame) => false,
          watch: (sim) {
            if (sim.boss != null) return;
            if (sim.enemies.any((e) => e.kind == EnemyKind.alleyPigeon)) {
              pigeonsSeen++;
            }
            if (sim.steamVents.isNotEmpty) steamSeen++;
          },
          until: (sim) => sim.boss != null,
        );
        // The run-up did have pigeons and steam; the arrival swept them away.
        expect(pigeonsSeen, greaterThan(0), reason: 'pigeons in the run-up');
        expect(steamSeen, greaterThan(0), reason: 'steam in the run-up');
        final boss = sim.boss!;
        expect(boss.phase, BossPhase.arriving);
        clearSky();
        // The cutscene cannot hurt, and nothing returns to the sky.
        sim
          ..hearts = 3
          ..shield = true;
        var arrivalFrames = 0;
        flyLevel(
          sim,
          viewportWidth: width,
          keepAlive: false,
          sprintWhen: (sim, frame) => false,
          watch: (sim) {
            arrivalFrames++;
            clearSky();
            expect((sim.hearts, sim.shield), (3, true));
          },
          until: (sim) => sim.boss?.phase == BossPhase.attacking,
        );
        expect(arrivalFrames, greaterThan(200), reason: '$width');
        // The fight: the same sky, and the planner pilot is never touched.
        final pilot = Pilot();
        var frames = 0;
        while (boss.phase == BossPhase.attacking && frames++ < 60 * 300) {
          pilot.fly(sim, width: width);
          clearSky();
        }
        expect(boss.phase, BossPhase.defeated, reason: '$width');
        expect(boss.spots, 0);
        expect((sim.hearts, sim.shield), (3, true), reason: '$width');
      }
    });

    test('feathers during a sweep and fury, with a late thumb: a planner that '
        'knows its lag (50 and 100 ms) beats him without a scratch', () {
      // Every sweep, slit and feather of a whole fight (the average pilot's is
      // six cycles long, two of them slits) with the beam and the feathers in
      // the air together, the taps arriving 3 and 6 frames late.
      for (final lag in [0, 3, 6]) {
        for (final (name, pilot) in [
          (
            'average',
            Pilot(
              lagFrames: lag,
              cadence: .45,
              fireFrom: .6,
              window: .3,
              offTarget: .3,
            ),
          ),
          ('sharp', Pilot(lagFrames: lag)),
        ]) {
          final sim = arena();
          final boss = sim.boss!;
          var frames = 0;
          while (boss.phase == BossPhase.attacking && frames++ < 60 * 400) {
            pilot.fly(sim);
          }
          final reason = '$name pilot, $lag frames of lag';
          expect(boss.phase, BossPhase.defeated, reason: reason);
          expect((boss.spots, sim.hearts, sim.shield), (0, 3, true),
              reason: reason);
          expect(boss.sweepsAimed, greaterThanOrEqualTo(3), reason: reason);
          expect(boss.feathersLaunched, greaterThanOrEqualTo(6), reason: reason);
        }
      }
    });
  });
}
