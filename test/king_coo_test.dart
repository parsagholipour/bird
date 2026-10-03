import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'campaign_flight.dart';
import 'king_coo_helpers.dart';
import 'ny_plans.dart';
import 'recorded_flight.dart';

/// King Coo's rules (R2, rules version 43, campaign only; spec
/// `reports/05-king-coo.md` §2): the 14 s cycle, crumb bombs and their
/// clouds, the puff and the pop, the whistle squadron, damage to the bird,
/// replay and seek, the level path, and the length of the fight. The
/// fairness proof is `king_coo_fair_test`.

const tickSeconds = 1 / 120;

/// A rock of [damage] on the chest, [rocks] of them in one tick: the health
/// they cost. Squadron pigeons are cleared first unless [pigeons], since one
/// in front of the chest would take the rock.
int hit(
  FlightSimulation sim,
  int damage, {
  int rocks = 1,
  bool pigeons = false,
}) {
  final boss = sim.boss!;
  if (!pigeons) sim.enemies.removeWhere((e) => e.squad);
  final before = boss.hp;
  for (var i = 0; i < rocks; i++) {
    sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: damage));
  }
  tick(sim);
  return before - boss.hp;
}

/// Combat times at which each counter of the boss first rose while the bird
/// holds [hold] under protection until combat time [until].
Map<String, List<double>> edgesUntil(
  FlightSimulation sim,
  double until, {
  double hold = .5,
}) {
  final boss = sim.boss!;
  final log = <String, List<double>>{
    for (final name in [
      'locked',
      'launched',
      'burst',
      'puff',
      'whistle',
      'pop',
      'open',
      'close',
    ])
      name: [],
  };
  var last = <int>[];
  List<int> counters() => [
    boss.lobsLocked,
    boss.lobsLaunched,
    boss.lobBursts,
    boss.puffs,
    boss.whistles,
    boss.pops,
  ];
  const names = ['locked', 'launched', 'burst', 'puff', 'whistle', 'pop'];
  last = counters();
  var open = boss.puffWindow;
  runTo(
    sim,
    until,
    hold: hold,
    protect: true,
    each: (sim) {
      final now = counters();
      for (var i = 0; i < now.length; i++) {
        for (var n = last[i]; n < now[i]; n++) {
          log[names[i]]!.add(boss.combatTime);
        }
      }
      last = now;
      if (boss.puffWindow != open) {
        log[boss.puffWindow ? 'open' : 'close']!.add(boss.combatTime);
        open = boss.puffWindow;
      }
    },
  );
  return log;
}

/// Every edge logged under [name] is the first tick at or after its time.
void expectEdges(Map<String, List<double>> log, String name, List<double> at) {
  final seen = log[name]!;
  expect(seen, hasLength(at.length), reason: '$name: $seen vs $at');
  for (var i = 0; i < at.length; i++) {
    expect(seen[i], greaterThanOrEqualTo(at[i] - 1e-9), reason: '$name $i');
    expect(seen[i], lessThan(at[i] + tickSeconds + 1e-9), reason: '$name $i');
  }
}

void main() {
  tearDown(() => Campaign.openedForTest = false);

  group('campaign only', () {
    test('no endless flight meets him: 200 encounters at every version', () {
      for (final version in [15, 20, 34, 37, 38, 39, 40, 41, 42, 43]) {
        for (var n = 0; n < 200; n++) {
          final encounter = FlightPlan.endless.bossEncounter(n, version);
          expect(
            encounter.kind.campaignOnly,
            isFalse,
            reason: 'encounter $n at rules $version',
          );
        }
      }
    });

    test('only a level plan that names him builds him, and only at 43', () {
      final plan = cooPlan();
      expect(plan.boss, BossKind.kingCoo);
      expect(plan.hasMiniBoss, isTrue);
      expect(plan.minRulesVersion, FlightSimulation.newYorkRulesVersion);
      expect(plan.problem, isNull);
      for (final older in [41, 42]) {
        expect(
          () => nyFlight(plan, version: older),
          throwsA(isA<ArgumentError>()),
          reason: 'rules $older do not know him and refuse the plan',
        );
      }
      final sim = cooFight();
      expect(sim.boss!.kind, BossKind.kingCoo);
      expect(sim.supportsMiniBosses, isTrue);
      expect(sim.rulesVersion, FlightSimulation.newYorkRulesVersion);
    });

    test('health 140 and fury at 70, at any weapon', () {
      for (final damage in [BirdRock.baseDamage, 30]) {
        final boss = cooFight(weaponDamage: damage).boss!;
        expect(boss.maxHp, 140);
        expect(boss.hp, 140);
        expect(boss.enraged, isFalse);
        boss.hp = 71;
        expect(boss.enraged, isFalse);
        boss.hp = 70;
        expect(boss.enraged, isTrue);
      }
    });
  });

  group('the 14 s cycle', () {
    test('two bombs, the puff at 7.6, the whistle at 9.2, closed by 10.0', () {
      final sim = cooFight();
      final log = edgesUntil(sim, 14 + 10.5);
      expectEdges(log, 'locked', [.6, 3.0, 14.6, 17.0]);
      expectEdges(log, 'launched', [1.4, 3.8, 15.4, 17.8]);
      expectEdges(log, 'burst', [2.8, 5.2, 16.8, 19.2]);
      expectEdges(log, 'puff', [7.6, 21.6]);
      expectEdges(log, 'whistle', [9.2, 23.2]);
      expectEdges(log, 'open', [7.6, 21.6]);
      expectEdges(log, 'close', [10.0, 24.0]);
      expect(log['pop'], isEmpty);
      // The rings' own clock is exact cycle time, whatever the tick.
      final boss = sim.boss!;
      expect(
        [for (final lob in boss.lobs) lob.lockedAt - boss.arrivalDuration],
        [
          for (final t in [.6, 3.0, 14.6, 17.0]) closeTo(t, 1e-9),
        ],
      );
      for (final lob in boss.lobs) {
        expect(lob.launchAt - lob.lockedAt, closeTo(.8, 1e-9));
        expect(lob.burstAt - lob.lockedAt, closeTo(2.2, 1e-9));
        expect(lob.cloudEndsAt - lob.burstAt, closeTo(1.0, 1e-9));
        expect(lob.lockX, FlightSimulation.birdX);
        expect(lob.fury, isFalse);
      }
    });

    test('the window is 7.6 to 10.0 and a tick either side is not', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 7.6 - 2 * tickSeconds, hold: .5, protect: true);
      expect(boss.puffWindow, isFalse);
      expect(boss.puffAmount, 0);
      runTo(sim, 7.6 + tickSeconds, hold: .5, protect: true);
      expect(boss.puffWindow, isTrue);
      runTo(sim, 9.2, hold: .5, protect: true);
      expect(boss.puffAmount, closeTo(1, .01));
      runTo(sim, 10 - 2 * tickSeconds, hold: .5, protect: true);
      expect(boss.puffWindow, isTrue);
      runTo(sim, 10 + tickSeconds, hold: .5, protect: true);
      expect(boss.puffWindow, isFalse);
      expect(boss.puffAmount, greaterThan(0), reason: 'the chest settles');
      runTo(sim, 10.5, hold: .5, protect: true);
      expect(boss.puffAmount, 0);
    });

    test('fury is latched at a cycle\'s first ring: three bracketed bombs', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 12, hold: .5, protect: true);
      expect(boss.lobs.every((lob) => !lob.fury), isTrue);
      boss.hp = KingCoo.furyHp;
      final log = edgesUntil(sim, 28 + 10.5);
      expectEdges(log, 'locked', [14.6, 16.4, 18.2, 28.6, 30.4, 32.2]);
      expectEdges(log, 'launched', [15.4, 17.2, 19.0, 29.4, 31.2, 33.0]);
      expectEdges(log, 'burst', [16.8, 18.6, 20.4, 30.8, 32.6, 34.4]);
      final furyLobs = boss.lobs.skip(2).toList();
      expect(furyLobs, hasLength(6));
      expect(furyLobs.every((lob) => lob.fury), isTrue);
      // The puff and the whistle stay where they were.
      expectEdges(log, 'puff', [21.6, 35.6]);
      expectEdges(log, 'whistle', [23.2, 37.2]);
    });

    test('fury begun mid-cycle waits for the next cycle\'s first ring', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 1.0, hold: .5, protect: true);
      expect(boss.lobs, hasLength(1));
      boss.hp = KingCoo.furyHp;
      runTo(sim, 14 + 5.5, hold: .5, protect: true);
      // Cycle 0 stays calm (two single clouds), cycle 1 is fury.
      expect(
        [for (final lob in boss.lobs) lob.fury],
        [false, false, true, true, true],
      );
      expect(boss.lobs[1].lockedAt - boss.arrivalDuration, closeTo(3.0, 1e-9));
    });

    test('the clock drives everything: a coarse tick gives the same cycle', () {
      final fine = cooFight(), coarse = cooFight();
      run(fine, 16, hold: .5, protect: true);
      for (var i = 0; i < 16 * 30; i++) {
        coarse
          ..birdY = .5
          ..velocity = 0
          ..invulnerableUntil = double.infinity;
        tick(coarse, dt: 1 / 30);
      }
      List<double> times(SkyBoss boss) => [
        for (final lob in boss.lobs) lob.lockedAt - boss.arrivalDuration,
      ];
      expect(times(coarse.boss!), [
        closeTo(.6, 1e-9),
        closeTo(3.0, 1e-9),
        closeTo(14.6, 1e-9),
      ]);
      expect(times(fine.boss!), [
        for (final t in times(coarse.boss!)) closeTo(t, 1e-9),
      ]);
      expect(coarse.boss!.puffs, fine.boss!.puffs);
      expect(coarse.boss!.whistles, fine.boss!.whistles);
    });
  });

  group('crumb bombs', () {
    test('the ring locks on the bird\'s height, clamped to .14-.86', () {
      for (final (held, locked) in [
        (.05, .14),
        (.14, .14),
        (.3, .3),
        (.5, .5),
        (.86, .86),
        (.95, .86),
      ]) {
        final sim = cooFight();
        runTo(sim, .7, hold: held, protect: true);
        final lob = sim.boss!.lobs.single;
        expect(lob.lockY, closeTo(locked, 1e-9), reason: 'bird at $held');
        expect(lob.cloudHeights, [closeTo(locked, 1e-9)]);
      }
    });

    test('the cloud stays where the ring locked, not where the bird went', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, .7, hold: .3, protect: true);
      final lob = boss.lobs.single;
      // The bird leaves, and is on the other side of the sky at the burst.
      runTo(
        sim,
        lob.burstAt - boss.arrivalDuration + .5,
        hold: .7,
        protect: true,
      );
      expect(boss.lobs.first.lockY, closeTo(.3, 1e-9));
      expect(boss.lobs.first.hurts(boss.age), isTrue);
      sim.invulnerableUntil = 0;
      sim.birdY = .7;
      sim.velocity = 0;
      tick(sim);
      expect(sim.shield, isTrue, reason: 'away from the cloud: safe');
      sim.birdY = .3;
      sim.velocity = 0;
      tick(sim);
      expect(sim.shield, isFalse, reason: 'on the old height: hurt');
    });

    test(
      'fury: two clouds bracket the bird, a centre outside .12-.88 drops',
      () {
        for (final (held, heights) in [
          (.5, [.2, .8]),
          (.3, [.6]),
          (.7, [.4]),
          (.14, [.44]),
          (.86, [.56]),
          (.4, [.7]),
          (.6, [.3]),
        ]) {
          final sim = cooFight();
          sim.boss!.hp = KingCoo.furyHp;
          runTo(sim, .7, hold: held, protect: true);
          final lob = sim.boss!.lobs.single;
          expect(lob.fury, isTrue);
          expect(lob.cloudHeights, [
            for (final y in heights) closeTo(y, 1e-9),
          ], reason: 'bird at $held');
        }
        // Nothing empties the bracket.
        for (var y = .14; y <= .86; y += .02) {
          expect(KingCoo.cloudHeights(y, fury: true), isNotEmpty);
        }
      },
    );

    test(
      'fury\'s corridor is safe at the bird\'s own height, not at a cloud',
      () {
        for (final (held, hurt) in [
          (.5, false),
          (.52, false),
          (.2, true),
          (.8, true),
        ]) {
          final sim = cooFight();
          final boss = sim.boss!..hp = KingCoo.furyHp;
          runTo(sim, .7, hold: .5, protect: true);
          final lob = boss.lobs.single;
          runTo(
            sim,
            lob.burstAt - boss.arrivalDuration + .5,
            hold: held,
            protect: true,
          );
          sim.invulnerableUntil = 0;
          sim.birdY = held;
          sim.velocity = 0;
          tick(sim);
          expect(sim.shield, !hurt, reason: 'bird at $held');
        }
      },
    );

    test(
      'the hurt radius is the drawn radius, at every moment of the cloud',
      () {
        // A bird 2 mm outside (radius + bird) is never hurt, 2 mm inside always.
        for (final s in [.02, .06, .1, .3, .5, .8, .9, .95]) {
          for (final (gap, hurt) in [(.002, false), (-.002, true)]) {
            final sim = cooFight(plan: cooPlan(length: 10));
            final boss = sim.boss!;
            runTo(sim, .7, hold: .5, protect: true);
            final lob = boss.lobs.single;
            runTo(
              sim,
              lob.burstAt - boss.arrivalDuration + s - tickSeconds,
              hold: .5,
              protect: true,
            );
            sim.invulnerableUntil = 0;
            // The tick ahead advances the boss one step first.
            final radius = lob.cloudRadius(boss.age + tickSeconds);
            expect(radius, greaterThan(0));
            sim
              ..birdY = .5 + radius + birdRadius + gap
              ..velocity = 0;
            tick(sim);
            expect(sim.shield, !hurt, reason: 's=$s gap=$gap radius=$radius');
          }
        }
      },
    );

    test(
      'a cloud hurts like a course edge: shield, a heart, 1.5 s recovery',
      () {
        final sim = cooFight();
        final boss = sim.boss!;
        expect([sim.shield, sim.hearts], [true, 3]);
        sim.invulnerableUntil = 0;
        run(sim, 3, hold: .5, until: (sim) => boss.combatTime >= 2.7);
        expect(sim.shield, isTrue);
        run(sim, 1, hold: .5, until: (sim) => !sim.shield);
        expect(
          [sim.shield, sim.hearts],
          [false, 3],
          reason: 'the shield first',
        );
        expect(boss.crumbHits, 1);
        expect(sim.recoveryRemaining, closeTo(1.5, .02));
        // The cloud lives 1 s and recovery 1.5 s: one hit per cloud.
        runTo(sim, 4.0, hold: .5);
        expect([sim.shield, sim.hearts, boss.crumbHits], [false, 3, 1]);
        // The second bomb locked on the bird at .5: a heart.
        runTo(sim, 6.5, hold: .5);
        expect([sim.shield, sim.hearts, boss.crumbHits], [false, 2, 2]);
      },
    );

    test('hearts run out like any hurt: the flight ends', () {
      final sim = cooFight();
      final boss = sim.boss!;
      sim
        ..shield = false
        ..hearts = 1;
      run(sim, 6, hold: .5, until: (sim) => sim.phase != RunPhase.playing);
      expect(sim.phase, RunPhase.ended);
      expect(sim.endReason, EndReason.collision);
      expect(boss.crumbHits, 1);
    });

    test('a sprint cannot move a cloud, shorten it, or shield the bird', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, .7, hold: .5, protect: true);
      final lockedAt = boss.lobs.single.lockedAt;
      runTo(sim, 2.4, hold: .5, protect: true);
      expect(sim.canSprint, isTrue);
      expect(sim.sprint(), isTrue);
      runTo(sim, 2.85, hold: .5, protect: true);
      expect(sim.ramming, isTrue);
      expect(boss.lobs.single.lockX, FlightSimulation.birdX);
      expect(boss.lobs.single.lockedAt, lockedAt);
      expect(boss.lobs.single.cloudHeights, [closeTo(.5, 1e-9)]);
      sim
        ..invulnerableUntil = 0
        ..birdY = .5
        ..velocity = 0;
      tick(sim);
      expect(sim.ramming, isTrue);
      expect(sim.shield, isFalse, reason: 'ramming protects from nothing');
    });

    test('a cloud never blocks a rock', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 2.85, hold: .5, protect: true);
      expect(boss.lobs.first.hurts(boss.age), isTrue);
      // A rock fired from inside the standing cloud still reaches him.
      sim.rocks.add(BirdRock(x: FlightSimulation.birdX + .03, y: boss.y));
      final before = boss.hp;
      runTo(sim, 4.0, hold: .5, protect: true);
      expect(boss.hp, lessThan(before));
      expect(sim.rocks, isEmpty);
    });

    test('the bomb is art: nothing ballistic is in the rules', () {
      final sim = cooFight();
      run(
        sim,
        16,
        hold: .5,
        protect: true,
        each: (sim) => expect(sim.bossAmmo, isEmpty),
      );
      expect(sim.boss!.lobsLaunched, greaterThan(2));
      expect(sim.boss!.summons, 0);
      expect(sim.boss!.volleys, 0);
    });
  });

  group('the chest', () {
    test('fluffed it takes half (at least one)', () {
      final sim = cooFight();
      runTo(sim, 1, hold: .5, protect: true);
      expect(hit(sim, 10), 5);
      expect(hit(sim, 1), 1);
      expect(hit(sim, 30), 15);
      expect(hit(sim, 11), 5);
      expect(sim.boss!.puffDamage, 0, reason: 'fluffed hits never count');
    });

    test('puffed, from 7.6 to 10.0, it takes double', () {
      final sim = cooFight();
      runTo(sim, 7.6 - 3 * tickSeconds, hold: .5, protect: true);
      expect(hit(sim, 10), 5, reason: 'a tick before the puff');
      runTo(sim, 7.6 + 2 * tickSeconds, hold: .5, protect: true);
      expect(hit(sim, 10), 20, reason: 'in the puff');
      runTo(sim, 9.5, hold: .5, protect: true);
      expect(hit(sim, 10), 20, reason: 'after the whistle too');
      expect(sim.boss!.puffDamage, 40);
      expect(sim.boss!.popped, isFalse);
    });

    test(
      'after 10.0 it is fluffed again and the next window counts afresh',
      () {
        final sim = cooFight();
        runTo(sim, 8, hold: .5, protect: true);
        expect(hit(sim, 10, rocks: 2), 40);
        runTo(sim, 10 + 2 * tickSeconds, hold: .5, protect: true);
        expect(hit(sim, 10), 5);
        runTo(sim, 14 + 7.6 + 2 * tickSeconds, hold: .5, protect: true);
        expect(sim.boss!.puffDamage, 0);
        expect(hit(sim, 10, rocks: 2), 40);
        expect(sim.boss!.popped, isFalse, reason: '40 < 60: no carry-over');
      },
    );

    test('three puffed hits (60) pop him: the window closes in that step', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 8, hold: .5, protect: true);
      expect(hit(sim, 10, rocks: 2), 40);
      expect(boss.popped, isFalse);
      // Two more rocks in the same step: the first completes the pop, the
      // second finds the window already closed and is fluffed.
      expect(hit(sim, 10, rocks: 2), 20 + 5);
      expect(boss.popped, isTrue);
      expect(boss.pops, 1);
      expect(boss.puffDamage, 60);
      expect(boss.puffWindow, isFalse);
      expect(boss.puffAmount, 0, reason: 'the chest deflates');
      expect(boss.lastPuffHitAt, boss.poppedAt);
      // Afterwards every hit is fluffed, until the next cycle.
      expect(hit(sim, 10), 5);
      expect(boss.puffDamage, 60);
      expect(boss.pops, 1);
    });

    test('a charged hit may overshoot, and pops at once', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 8, hold: .5, protect: true);
      expect(hit(sim, 25), 50);
      expect(boss.popped, isFalse, reason: '50 < 60');
      expect(hit(sim, 5), 10);
      expect(boss.popped, isTrue);
      final other = cooFight();
      runTo(other, 8, hold: .5, protect: true);
      expect(hit(other, 40), 80);
      expect(other.boss!.popped, isTrue);
      expect(other.boss!.pops, 1);
    });

    test('a pop before the whistle cancels the squadron', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 8, hold: .5, protect: true);
      expect(boss.squad, isNotEmpty, reason: 'lanes are shown at the puff');
      hit(sim, 10, rocks: 3);
      expect(boss.popped, isTrue);
      runTo(sim, 8.1, hold: .5, protect: true);
      expect(boss.squad, isEmpty, reason: 'the lanes go');
      expect(boss.cooHint, 'POP! · No squadron');
      runTo(sim, 14, hold: .5, protect: true);
      expect(boss.whistles, 0, reason: 'the whistle never blew');
      expect(boss.whistlesLatched, 1);
      expect(sim.enemies, isEmpty);
      expect(boss.pops, 1);
      // The next cycle calls as usual.
      runTo(sim, 14 + 9.3, hold: .5, protect: true);
      expect(boss.whistles, 1);
      expect(squadOf(sim), isNotEmpty);
    });

    test('a pop after the whistle keeps the squadron that is out', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 9.3, hold: .5, protect: true);
      expect(boss.whistles, 1);
      final out = squadOf(sim).length;
      expect(out, greaterThan(0));
      // The pigeons in front would take a rock; strike him directly.
      for (var i = 0; i < 3; i++) {
        boss.strike(10);
      }
      tick(sim);
      expect(boss.popped, isTrue);
      expect(boss.puffWindow, isFalse, reason: 'the window still closes');
      expect(boss.squad, isNotEmpty);
      expect(squadOf(sim), hasLength(out));
      expect(boss.whistles, 1);
      expect(boss.cooHint, 'SQUADRON · Follow the open lane!');
    });

    test('a pop in one cycle does not stop the next cycle\'s squadron', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 8, hold: .5, protect: true);
      hit(sim, 10, rocks: 3);
      runTo(sim, 14 + 9.3, hold: .5, protect: true);
      expect(boss.popped, isFalse);
      expect(boss.whistles, 1);
      expect(squadOf(sim), isNotEmpty);
    });

    test('shatter blasts strike the chest like rocks do', () {
      for (final (at, expected) in [(3.0, 10), (8.0, 40)]) {
        final sim = cooFight();
        final boss = sim.boss!;
        runTo(sim, at, hold: .5, protect: true);
        // A charged rock meets a pellet beside him: the blast reaches him.
        sim.enemyAmmo.add(
          EnemyAmmo(
            x: boss.x - .2,
            y: boss.y,
            vx: 0,
            vy: 0,
            attack: EnemyAttack.aimed,
          ),
        );
        sim.rocks.add(
          BirdRock(x: boss.x - .2, y: boss.y, damage: 40, charge: .5),
        );
        final before = boss.hp;
        tick(sim);
        expect(sim.ammoShattered, greaterThan(0));
        // The blast is half the rock's damage (20): fluffed 10, puffed 40.
        expect(before - boss.hp, expected, reason: 'at $at s');
      }
    });

    test('every hit pays health once, and the kill pays once', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 1, hold: .5, protect: true);
      final score = sim.score;
      var total = 0;
      while (boss.phase == BossPhase.attacking) {
        total += hit(sim, 10, rocks: 3);
      }
      expect(boss.hp, 0);
      expect(total, 140);
      expect(sim.bossesDefeated, 1);
      expect(sim.score - score, FlightSimulation.bossBonus);
      expect(sim.victoryGlide, isTrue);
    });
  });

  group('the squadron', () {
    /// The bird holds [held] at the puff (7.6 s of cycle [cycle]); once the
    /// lanes are planned it moves to the height farthest from all of them
    /// and the fight runs to [after] seconds after the whistle. Each pigeon's
    /// track (combat time in the cycle, x, y) is logged in release order.
    ({
      FlightSimulation sim,
      List<List<({double t, double x, double y})>> tracks,
    })
    squadFight({
      required int cycle,
      required double held,
      double width = 2.2,
      bool fury = false,
      double after = 6,
    }) {
      final sim = cooFight(width: width);
      final boss = sim.boss!;
      if (fury) boss.hp = KingCoo.furyHp;
      final tracks = <List<({double t, double x, double y})>>[];
      final byPigeon = <SkyEnemy, List<({double t, double x, double y})>>{};
      final start = cycle * KingCoo.period;
      runTo(sim, start + 7.5, width: width, hold: .5, protect: true);
      run(
        sim,
        1,
        width: width,
        hold: held,
        protect: true,
        until: (sim) => boss.puffsLatched > cycle,
      );
      // Out of the way of every lane: the pigeons then fly past untouched.
      final lanes = [
        for (final plan in boss.squad)
          for (final slot in plan.slots) slot.y,
      ];
      var safe = .5, room = -1.0;
      for (var y = .06; y <= .94; y += .01) {
        final nearest = lanes.map((l) => (l - y).abs()).reduce(math.min);
        if (nearest > room) {
          room = nearest;
          safe = y;
        }
      }
      expect(room, greaterThan(.1), reason: 'a height clear of every lane');
      run(
        sim,
        after + (KingCoo.whistleAt - 7.6),
        width: width,
        hold: safe,
        protect: true,
        each: (sim) {
          for (final e in squadOf(sim)) {
            byPigeon
                .putIfAbsent(e, () {
                  final log = <({double t, double x, double y})>[];
                  tracks.add(log);
                  return log;
                })
                .add((t: boss.combatTime - start, x: e.x, y: e.y));
          }
        },
      );
      return (sim: sim, tracks: tracks);
    }

    for (final width in [1.6, 640 / 360, 800 / 360, 2.4]) {
      test('a V on an even cycle, at width ${width.toStringAsFixed(2)}', () {
        final (:sim, :tracks) = squadFight(cycle: 0, held: .4, width: width);
        final boss = sim.boss!;
        final bossX = bossColumn(width);
        expect(boss.x, closeTo(bossX, 1e-9));
        expect(tracks, hasLength(5));
        final plan = boss.squad.single;
        expect(plan.shape, SquadShape.v);
        // The lanes: the tip at the bird's height, wings .12 and .24 behind.
        final slots = [for (final s in plan.slots) (s.behind, s.y)];
        final expected = [
          (0.0, .4),
          (.12, .4 - .075),
          (.12, .4 + .075),
          (.24, .4 - .15),
          (.24, .4 + .15),
        ];
        for (final (i, (behind, y)) in expected.indexed) {
          expect(slots[i].$1, closeTo(behind, 1e-9));
          expect(slots[i].$2, closeTo(y, 1e-9));
        }
        // Born at the boss at the whistle (9.2 s), flying left at .62.
        for (final (i, slot) in plan.slots.indexed) {
          final log = tracks[i];
          expect(log.first.t, closeTo(KingCoo.whistleAt, tickSeconds + 1e-6));
          expect(
            log.first.x,
            closeTo(bossX + slot.behind, .62 * tickSeconds * 2),
          );
          // The lane is reached and held exactly from 0.6 s after the whistle.
          final settled = log.where(
            (p) => p.t >= KingCoo.whistleAt + KingCoo.squadEase + .01,
          );
          expect(settled, isNotEmpty);
          for (final p in settled) {
            expect(p.y, closeTo(slot.y, 1e-9));
          }
          // Constant speed on the screen, whatever the course does.
          for (var k = 1; k < log.length; k++) {
            expect(
              log[k - 1].x - log[k].x,
              closeTo(KingCoo.squadSpeed * (log[k].t - log[k - 1].t), 1e-9),
            );
          }
        }
        // The tip crosses the bird's column (bossX - birdX) / .62 s after the
        // whistle: 1.22 s at 640, 1.94 s at 800, 2.23 s at 864.
        final crossing = (bossX - birdX) / KingCoo.squadSpeed;
        final at = tracks[0].firstWhere((p) => p.x <= birdX).t;
        expect(
          at - KingCoo.whistleAt,
          closeTo(crossing, tickSeconds + 1e-6),
          reason: 'width $width',
        );
        // The boss's own helpers say the same, for the art's lanes.
        expect(
          boss.squadReleaseAt(plan) - boss.arrivalDuration,
          closeTo(KingCoo.whistleAt, 1e-9),
        );
        expect(
          boss.squadCrossesAt(plan, plan.slots.first, birdX) -
              boss.arrivalDuration,
          closeTo(KingCoo.whistleAt + crossing, 1e-9),
        );
        if (width == 640 / 360) expect(crossing, closeTo(1.22, .01));
        if (width == 800 / 360) expect(crossing, closeTo(1.94, .01));
        if (width == 2.4) expect(crossing, closeTo(2.23, .01));
      });
    }

    test('a squad track is a pure function of the clock', () {
      const track = SquadTrack(x0: 1.65, fromY: .5, lane: .3, bornAt: 10);
      expect(track.x(10), 1.65);
      expect(track.x(9), 1.65, reason: 'never before its release');
      expect(track.x(11), closeTo(1.65 - .62, 1e-12));
      expect(track.y(10), .5);
      expect(track.y(10.3), closeTo(.4, 1e-9), reason: 'eased halfway');
      expect(track.y(10.6), closeTo(.3, 1e-12));
      expect(track.y(14), .3);
      expect(track.x(track.crossesAt(birdX)), closeTo(birdX, 1e-12));
      var last = track.y(10);
      for (var t = 10.0; t <= 10.6; t += .01) {
        expect(track.y(t), lessThanOrEqualTo(last + 1e-12), reason: 'eases');
        last = track.y(t);
      }
    });

    test('a picket closes every height but its gap, at any bird height', () {
      for (final (cycle, bird, gap, count) in [
        (1, .1, .5, 4),
        (1, .5, .3, 5),
        (3, .5, .7, 5),
        (1, .8, .5, 4),
      ]) {
        final plan = KingCoo.squad(
          cycle: cycle,
          birdY: bird,
          fury: false,
        ).single;
        expect(plan.gap, gap);
        expect(plan.slots, hasLength(count));
        // A bird centre anywhere in the legal sky is touched by a blocker
        // unless it is in the gap's corridor (.30 tall: gap +- .15).
        for (var y = birdRadius; y <= 1 - birdRadius; y += .001) {
          final touched = plan.slots.any(
            (s) => (s.y - y).abs() < KingCoo.pigeonReach,
          );
          final inGap =
              (y - gap).abs() < KingCoo.picketFirst - KingCoo.pigeonReach;
          expect(touched, !inGap, reason: 'gap $gap at y=$y');
        }
      }
    });

    test(
      'lanes are fixed at the puff: a bird that moves away finds them put',
      () {
        final sim = cooFight();
        final boss = sim.boss!;
        runTo(sim, 7.5, hold: .3, protect: true);
        runTo(sim, 7.7, hold: .3, protect: true);
        final tip = boss.squad.single.slots[0].y;
        expect(tip, closeTo(.3, 1e-9));
        runTo(sim, 11, hold: .7, protect: true);
        expect(boss.squad.single.slots[0].y, tip);
        final pigeon = squadOf(sim).firstWhere((e) => (e.y - tip).abs() < 1e-9);
        expect(pigeon.track!.lane, closeTo(tip, 1e-9));
      },
    );

    test(
      'a picket on an odd cycle: one .30 gap, none in it, none to slip by',
      () {
        for (final (cycle, held, gap, count) in [
          (1, .2, .5, 4),
          (1, .8, .5, 4),
          (1, .5, .3, 5),
          (3, .5, .7, 5),
        ]) {
          final (:sim, :tracks) = squadFight(
            cycle: cycle,
            held: held,
            after: 2.4,
          );
          final plan = sim.boss!.squad.single;
          expect(plan.shape, SquadShape.picket, reason: 'cycle $cycle');
          expect(plan.gap, gap, reason: 'cycle $cycle bird $held');
          expect(tracks, hasLength(count), reason: 'cycle $cycle bird $held');
          final ys = plan.slots.map((s) => s.y).toList()..sort();
          for (final y in ys) {
            expect((y - gap).abs(), greaterThanOrEqualTo(.233 - 1e-9));
          }
          for (var i = 1; i < ys.length; i++) {
            expect(
              ys[i] - ys[i - 1],
              anyOf(closeTo(.16, 1e-9), closeTo(2 * .233, 1e-9)),
              reason: 'neighbours a spacing apart, but across the gap',
            );
          }
          // The bird cannot slip between two: a pigeon's reach leaves less
          // than a bird's width between neighbours.
          expect(.16 - 2 * .045, lessThan(2 * birdRadius));
          // The blockers go on until one's reach covers the last of the sky
          // the bird may fly in.
          expect(ys.first - KingCoo.pigeonReach, lessThanOrEqualTo(birdRadius));
          expect(
            ys.last + KingCoo.pigeonReach,
            greaterThanOrEqualTo(1 - birdRadius),
          );
          // They all cross together, at the tip's time.
          final times = {
            for (final log in tracks)
              log.firstWhere((p) => p.x <= birdX).t.toStringAsFixed(2),
          };
          expect(times, hasLength(1));
        }
      },
    );

    test('fury calls a V, and a centred picket 1.4 s behind it', () {
      final (:sim, :tracks) = squadFight(
        cycle: 0,
        held: .35,
        fury: true,
        after: 4.2,
      );
      final plans = sim.boss!.squad;
      expect(plans.map((p) => p.shape), [SquadShape.v, SquadShape.picket]);
      expect(tracks, hasLength(5 + 4));
      final released = [for (final log in tracks) log.first.t]..sort();
      expect(released.take(5), everyElement(closeTo(9.2, tickSeconds * 2)));
      expect(
        released.skip(5),
        everyElement(closeTo(9.2 + KingCoo.furyPicketDelay, tickSeconds * 2)),
      );
      expect(plans[1].gap, .5);
    });

    test('they are Alley Pigeon gliders: no prey, no snatch, 20 health', () {
      final sim = cooFight();
      // The run-up's own pigeons (rules 43's raiders, R1) may have raided
      // before the fight; the squadron adds nothing to those books.
      final raids = [sim.starsSnatched, sim.pigeonWarnings, sim.pigeonDives];
      runTo(sim, 9.5, hold: .5, protect: true);
      final birds = squadOf(sim);
      expect(birds, isNotEmpty);
      for (final e in birds) {
        expect(e.kind, EnemyKind.alleyPigeon);
        expect(e.squad, isTrue);
        expect(e.pigeon, isNull);
        expect(e.snatches, isFalse);
        expect(e.drift, 0);
        expect(e.maxHp, 20);
        expect(e.attack, EnemyAttack.none);
        expect(e.track, isNotNull);
        // Their place is a pure function of the boss's clock.
        expect(e.x, closeTo(e.track!.x(sim.boss!.age), 1e-9));
        expect(e.y, closeTo(e.track!.y(sim.boss!.age), 1e-9));
      }
      expect([sim.starsSnatched, sim.pigeonWarnings, sim.pigeonDives], raids);
    });

    test('touching one hurts, and it is gone after', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 7.7, hold: .5, protect: true);
      final tip = boss.squad.single.slots[0].y;
      run(
        sim,
        6,
        hold: tip,
        protect: true,
        until: (s) => squadOf(s).isNotEmpty,
      );
      final before = squadOf(sim).length;
      sim.invulnerableUntil = 0;
      run(sim, 4, hold: tip, until: (sim) => !sim.shield || sim.hearts < 3);
      expect(sim.shield, isFalse, reason: 'the tip flew into the bird');
      expect(squadOf(sim).length, lessThan(before));
      expect(boss.crumbHits, 0, reason: 'a pigeon, not a cloud');
    });

    test('a rock kills one (+3), and a pigeon takes a rock meant for him', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 9.9, hold: .5, protect: true);
      final victim = squadOf(sim).first;
      final score = sim.score, defeated = sim.enemiesDefeated;
      // Two base taps kill one of 20 health; the first leaves it alive.
      sim.rocks.add(BirdRock(x: victim.x - .05, y: victim.y, damage: 10));
      tick(sim);
      expect(victim.hp, 10);
      expect(sim.enemies, contains(victim));
      sim.rocks.add(BirdRock(x: victim.x - .05, y: victim.y, damage: 10));
      tick(sim);
      expect(sim.enemies, isNot(contains(victim)));
      expect(sim.enemiesDefeated, defeated + 1);
      expect(sim.score - score, 3);
      // A rock that meets the next pigeon stops there: the chest takes nothing.
      final hp = boss.hp;
      final blocker = squadOf(sim).first;
      sim.rocks.add(BirdRock(x: blocker.x - .05, y: blocker.y, damage: 10));
      tick(sim);
      expect(boss.hp, hp);
      expect(sim.rocks, isEmpty);
    });

    test('a sprint smashes one without a hurt', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 7.7, hold: .5, protect: true);
      final tip = boss.squad.single.slots[0].y;
      run(
        sim,
        6,
        hold: tip,
        protect: true,
        until: (s) => squadOf(s).isNotEmpty,
      );
      run(
        sim,
        4,
        hold: tip,
        protect: true,
        until: (sim) => squadOf(sim).any((e) => e.x < birdX + .3),
      );
      expect(sim.sprint(), isTrue);
      sim.invulnerableUntil = 0;
      final defeated = sim.enemiesDefeated;
      run(sim, 3, hold: tip, until: (sim) => sim.enemiesDefeated > defeated);
      expect(sim.enemiesDefeated, greaterThan(defeated));
      expect(sim.shield, isTrue);
      expect(sim.hearts, 3);
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.enemyRammed),
        isNotEmpty,
      );
    });

    test('they fly off the far edge and are gone', () {
      final sim = cooFight();
      runTo(sim, 9.5, hold: .5, protect: true);
      expect(squadOf(sim), isNotEmpty);
      runTo(sim, 13.6, hold: .5, protect: true);
      expect(squadOf(sim), isEmpty);
    });

    test('defeat clears every pigeon and every cloud', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 9.6, hold: .5, protect: true);
      expect(squadOf(sim), isNotEmpty);
      expect(boss.liveLobs, isEmpty, reason: 'no cloud stands in the window');
      runTo(sim, 14 + 3.0, hold: .5, protect: true);
      expect(boss.liveLobs, isNotEmpty, reason: 'a cloud stands at 17.0');
      boss.hp = 1;
      hit(sim, 10, rocks: 2);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.enemies, isEmpty);
      expect(boss.liveLobs, isEmpty, reason: 'a defeat leaves no cloud');
      // Latched and never pruned, and none is laid after the defeat.
      final locked = boss.lobs.length;
      expect(locked, greaterThanOrEqualTo(3));
      run(sim, 3, hold: .5, protect: true);
      expect(boss.lobs, hasLength(locked));
      expect(boss.liveLobs, isEmpty);
      // The bird sits in the victory glide, which nothing can hurt.
      sim.invulnerableUntil = 0;
      final crumbs = boss.crumbHits;
      run(sim, 4, hold: .5);
      expect(sim.shield, isTrue);
      expect(boss.crumbHits, crumbs);
    });
  });

  group('no hurt outside the fight', () {
    test('the arrival hurts nothing and brings no bomb, ring or pigeon', () {
      final sim = nyFlight(cooPlan(), weaponDamage: 10);
      var seen = 0;
      ({bool shield, int hearts})? atArrival;
      flyLevel(
        sim,
        until: (sim) => sim.boss?.phase == BossPhase.attacking,
        watch: (sim) {
          final b = sim.boss;
          if (b == null || b.phase != BossPhase.arriving) return;
          seen++;
          atArrival ??= (shield: sim.shield, hearts: sim.hearts);
          expect(b.lobs, isEmpty);
          expect(b.liveLobs, isEmpty);
          expect(b.squad, isEmpty);
          expect(squadOf(sim), isEmpty);
          expect(b.cooCycleNumber, -1);
        },
      );
      expect(seen, greaterThan(100), reason: 'the arrival is 4.6 s long');
      expect([sim.shield, sim.hearts], [atArrival!.shield, atArrival!.hearts]);
    });

    test('nothing of his hurts in the victory glide', () {
      final sim = cooFight();
      final boss = sim.boss!;
      runTo(sim, 14 + 2.8, hold: .5, protect: true);
      boss.hp = 1;
      hit(sim, 10, rocks: 2);
      expect(boss.phase, BossPhase.defeated);
      sim.invulnerableUntil = 0;
      run(sim, 6, hold: .5);
      expect([sim.shield, sim.hearts], [true, 3]);
    });
  });

  group('determinism, replay and seek', () {
    test('no shared random is drawn: the flight\'s random is untouched', () {
      final a = cooFight(), b = cooFight();
      fightBot(b, CooBot(), protect: true);
      expect(b.boss!.lobs, isNotEmpty);
      expect(
        List.generate(5, (_) => b.random.nextInt(1 << 30)),
        List.generate(5, (_) => a.random.nextInt(1 << 30)),
      );
    });

    test('two identical fights are identical, tick for tick', () {
      List<Object> fight() {
        final sim = cooFight(weaponDamage: 10);
        final states = <Object>[];
        var n = 0;
        fightBot(
          sim,
          CooBot(react: .3),
          each: (sim) {
            if (n++ % 60 == 0) states.add(cooSnapshot(sim));
          },
        );
        states.add(cooSnapshot(sim));
        return states;
      }

      final first = fight();
      expect(first.length, greaterThan(10));
      expect(fight(), first);
    });

    test('pause and resume freeze the fight', () {
      final sim = cooFight();
      runTo(sim, 8.4, hold: .5, protect: true);
      sim.takeBreak();
      final before = cooSnapshot(sim);
      tick(sim, dt: .5);
      tick(sim, dt: .5);
      expect(cooSnapshot(sim), before);
    });

    test('a recorded fight survives backward and forward seeks', () {
      // From 5 s to 13 s of the fight the bot flies low, off his line of
      // fire, so the recorded fight holds bombs, a puff, a whistle and a
      // squadron before the bot returns to land its hits.
      final bot = CooBot(
        react: .2,
        line: (sim) {
          final t = sim.boss!.combatTime;
          return t >= 5 && t < 13 ? sim.boss!.y + .25 : sim.boss!.y;
        },
      );
      final recording = recordLevel(
        cooLevel(),
        weaponDamage: BirdRock.baseDamage,
        // New York's fight: rules 44's warm-up calls no squadron this early.
        version: FlightSimulation.newYorkRulesVersion,
        tapWhen: (sim) {
          // The shared run-up bot until he fights, then the dodging bot.
          final boss = sim.boss;
          return boss != null && boss.phase == BossPhase.attacking
              ? bot.flap(sim)
              : rideTheSky(sim);
        },
      );
      final live = recording.simulation;
      expect(live.bossesDefeated, 1);
      final tape = ReplayTape.fromJson(recording.tape.toJson());
      expect(tape.plan!.boss, BossKind.kingCoo);
      expect(tape.recordedVersion, FlightSimulation.newYorkRulesVersion);
      final player = ReplayPlayer(tape);
      final end = tape.durationMs;
      final first = math.max(0.0, end - 34000);
      final times = [for (var ms = first; ms < end; ms += 1700) ms, end];
      final forward = <double, Object>{};
      final seen = <String>{};
      for (final ms in times) {
        player.seek(ms);
        forward[ms] = cooSnapshot(player.simulation);
        final boss = player.simulation.boss;
        if (boss == null || boss.phase != BossPhase.attacking) continue;
        if (boss.puffWindow) seen.add('puff window');
        if (boss.liveLobs.isNotEmpty) seen.add('bomb');
        if (squadOf(player.simulation).isNotEmpty) seen.add('squadron');
        if (boss.lobs.any((lob) => lob.fury)) seen.add('fury');
        if (boss.whistles >= 1) seen.add('whistle');
      }
      expect(
        seen,
        containsAll(['puff window', 'bomb', 'squadron', 'whistle']),
        reason: 'the checkpoints must cover the fight: $seen',
      );
      // Backward, forward, in a scrambled order: the same states.
      final scrambled = [...times]..shuffle(math.Random(9));
      for (final ms in [...times.reversed, ...scrambled]) {
        player.seek(ms);
        expect(cooSnapshot(player.simulation), forward[ms], reason: 'at $ms');
      }
      // And the replay ends where the live flight ended.
      player.seek(end);
      expect(player.simulation.hearts, live.hearts);
      expect(player.simulation.score, live.score);
      expect(player.simulation.bossesDefeated, live.bossesDefeated);
    });

    test('counters only rise', () {
      final sim = cooFight(weaponDamage: 10);
      final boss = sim.boss!;
      List<int> counters() => [
        boss.lobsLocked,
        boss.lobsLaunched,
        boss.lobBursts,
        boss.puffs,
        boss.whistles,
        boss.pops,
        boss.crumbHits,
      ];
      var last = counters();
      fightBot(
        sim,
        CooBot(react: .2),
        each: (sim) {
          // The clock-driven counters (puffs) stop with the fight, so a
          // defeat ends them; everything latched only ever rises.
          if (boss.phase != BossPhase.attacking) return;
          final now = counters();
          for (var i = 0; i < now.length; i++) {
            expect(now[i], greaterThanOrEqualTo(last[i]), reason: 'counter $i');
          }
          last = now;
        },
      );
      expect(last[0], greaterThanOrEqualTo(2));
    });
  });

  group('the level path', () {
    test('the test-only 3-2 is a guardian whose plan round-trips', () {
      final level = cooLevel();
      expect(level.id, '3-2');
      expect(level.isBoss, isTrue);
      expect(level.isGuardian, isTrue);
      expect(level.isMiniBoss, isTrue);
      expect(level.isChapterBoss, isFalse);
      expect(level.boss, BossKind.kingCoo);
      expect(
        Campaign.bossLine(level),
        'Nobody flies till the bread cart is found!',
      );
      expect(Campaign.chapterOf(level).bossLevel.id, '3-8');
      final plan = level.plan;
      expect(plan.problem, isNull);
      final back = LevelPlan.fromJson(
        jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>,
      );
      expect(back.toJson(), plan.toJson());
      expect(back.boss, BossKind.kingCoo);
      expect(back.minRulesVersion, 43);
      // A boss level lays its run-up only: no set pieces.
      expect(
        nyPlan(
          boss: BossKind.kingCoo,
          pieces: const [SetPiece(SetPieceKind.gale, at: 10)],
        ).problem,
        'boss',
      );
    });

    test('a bot beats him and the level completes: a guardian, one boss', () {
      final sim = levelFlight(cooLevel(), weaponDamage: BirdRock.baseDamage);
      flyLevel(sim, until: (sim) => sim.boss?.phase == BossPhase.attacking);
      expect(sim.boss!.isKingCoo, isTrue);
      // Unhurt: rules 45's King Coo (840 health, his stragglers back) fells
      // many pilots, and this is the level's path, not their survival
      // (`ny_levels_spread_test`).
      fightBot(sim, CooBot(react: .2), protect: true, seconds: 400);
      expect(sim.boss!.phase, BossPhase.defeated);
      flyLevel(sim);
      expect(sim.endReason, EndReason.completed);
      expect(sim.bossesDefeated, 1);
      expect(sim.finishLine, isNotNull);
      expect(sim.levelStars, inInclusiveRange(1, 3));
      expect(sim.victoryGlide, isTrue);
    });

    test('beating him opens the next level and nothing chapter-wide', () {
      Campaign.openedForTest = true;
      LevelRecord cleared(String id) => LevelRecord(
        levelId: id,
        bestStars: 3,
        plays: 1,
        firstClearedAt: DateTime(2026, 9, 20),
        lastPlayedAt: DateTime(2026, 9, 20),
      );
      List<LevelRecord> upTo(String last) => [
        for (final chapter in Campaign.chapters.take(2))
          for (final level in chapter.levels) cleared(level.id),
        for (final id in ['3-1', '3-2'])
          if (id.compareTo(last) <= 0) cleared(id),
      ];
      final three = Campaign.level('3-3')!, two = Campaign.level('3-2')!;
      final before = CampaignProgress(upTo('3-1'));
      expect(before.unlocked(two), isTrue);
      expect(before.unlocked(three), isFalse);
      // The guardian falls: 3-3 opens, nothing else.
      final after = CampaignProgress(upTo('3-2'));
      expect(after.unlocked(three), isTrue);
      final chapter = Campaign.chapters[2];
      expect(after.chapterComplete(chapter), isFalse);
      expect(after.postcardDue(chapter), isFalse);
      expect(after.sceneAfter(chapter), isNull);
      expect(after.chapterUnlocked(Campaign.chapters[3]), isFalse);
      expect(after.unlocked(chapter.bossLevel), isFalse);
      expect(chapter.bossLevel.isChapterBoss, isTrue);
    });
  });

  group('the length of the fight', () {
    // Bots that read every telegraph and never miss, at four tempos (how
    // soon they react, how often they shoot), at the base weapon on the two
    // test phones. The report's model, whose players also miss, says a
    // practised player needs 35-50 s and a first-timer 60-90 s: a perfect
    // bot is the floor, and a slow one sits between it and a human.
    final bots = <(String, CooBot Function(), double, double)>[
      ('perfect', () => CooBot(), 7, 25),
      (
        'practised',
        () => CooBot(react: .3, margin: .07, gap: .5, aim: .08),
        8,
        40,
      ),
      (
        'family',
        () => CooBot(
          react: .55,
          margin: .07,
          gap: .8,
          aim: .07,
          tapsPerSecond: 3.5,
        ),
        12,
        70,
      ),
      (
        'novice',
        () => CooBot(
          react: .8,
          margin: .07,
          gap: 1.3,
          aim: .06,
          tapsPerSecond: 2.5,
        ),
        20,
        120,
      ),
    ];
    for (final width in [640 / 360, 800 / 360]) {
      for (final (name, bot, least, most) in bots) {
        test('a $name bot at width ${width.toStringAsFixed(2)}: '
            '$least to $most s', () {
          final sim = cooFight(width: width, weaponDamage: BirdRock.baseDamage);
          final boss = sim.boss!;
          final seconds = fightBot(sim, bot(), width: width);
          expect(boss.phase, BossPhase.defeated);
          expect(sim.phase, RunPhase.playing, reason: 'it survived');
          expect(seconds, inInclusiveRange(least, most));
        });
      }
    }

    test('slower players take longer, at the same health', () {
      final times = <double>[];
      for (final (_, bot, _, _) in bots) {
        final sim = cooFight(weaponDamage: BirdRock.baseDamage);
        expect(sim.boss!.maxHp, 140);
        times.add(fightBot(sim, bot()));
      }
      for (var i = 1; i < times.length; i++) {
        expect(times[i], greaterThan(times[i - 1]), reason: '$times');
      }
    });

    test('an upgraded weapon shortens it, and health never changes', () {
      final base = cooFight(weaponDamage: BirdRock.baseDamage);
      final upgraded = cooFight(weaponDamage: 30);
      final slow = fightBot(base, CooBot());
      final fast = fightBot(upgraded, CooBot());
      expect(base.boss!.maxHp, upgraded.boss!.maxHp);
      expect(fast, lessThan(slow));
    });
  });
}
