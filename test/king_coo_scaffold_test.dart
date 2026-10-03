import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'ny_plans.dart';

/// King Coo's scaffold (R0): the enum value, health, the pure cycle
/// functions (`KingCoo`), and the boss getters art, audio and UI read. His
/// hurt, strike and squadron rules landed with R2: `king_coo_test` holds them
/// and `king_coo_fair_test` the fairness proof.

SkyBoss coo({double combat = 0, bool enraged = false}) {
  final boss = SkyBoss(
    number: 6,
    x: 1.6,
    kind: BossKind.kingCoo,
    cinematic: true,
  );
  boss.age = boss.arrivalDuration + combat;
  if (enraged) {
    boss
      ..hp = KingCoo.furyHp
      ..enragedAt = 0;
  }
  return boss;
}

void main() {
  test('King Coo is appended and campaign-only', () {
    expect(BossKind.values.map((k) => k.name), [
      'baronBat',
      'spitterBeetle',
      'duskMoth',
      'pirate',
      'dragon',
      'kingCoo',
      'searchlightGargoyle',
      // Egypt's guardian, rules 50, appended after New York's.
      'neferhoo',
    ]);
    expect(BossKind.kingCoo.index, 5);
    expect(BossKind.kingCoo.campaignOnly, isTrue);
    expect(BossKind.searchlightGargoyle.campaignOnly, isTrue);
    expect(BossKind.endlessCycle, 5);
    for (final kind in BossKind.values.take(5)) {
      expect(kind.campaignOnly, isFalse, reason: kind.name);
    }
  });

  test('health 140 at every encounter number, fury at half', () {
    for (final number in [1, 3, 6, 9, 40]) {
      expect(SkyBoss.healthFor(BossKind.kingCoo, number), 140);
    }
    final boss = coo();
    expect(boss.maxHp, 140);
    expect(boss.enraged, isFalse);
    boss.hp = 71;
    expect(boss.enraged, isFalse);
    boss.hp = 70;
    expect(boss.enraged, isTrue);
    expect(KingCoo.maxHp ~/ 2, KingCoo.furyHp);
    expect(boss.isKingCoo, isTrue);
    expect(boss.isMiniBoss, isTrue);
    expect(boss.isGargoyle, isFalse);
    expect(boss.name, 'King Coo');
    expect(boss.title, 'COMMISSIONER OF THE CURB');
  });

  test('he fires nothing and calls no lineup helpers', () {
    final boss = coo();
    expect(boss.fireIn, double.infinity);
    expect(boss.summonIn, double.infinity);
    expect(boss.volleyInterval, double.infinity);
    expect(boss.summonInterval, double.infinity);
    expect(boss.volleyOffsets, isEmpty);
    expect(boss.projectileSpeed, 0);
  });

  test('a mini-boss is only ever cinematic', () {
    expect(
      () => SkyBoss(number: 6, x: 1, kind: BossKind.kingCoo),
      throwsA(isA<AssertionError>()),
    );
  });

  test('the cycle is 14 s with lobs at 1.4 and 3.8 (fury 1.4, 3.2, 5.0)', () {
    expect(KingCoo.period, 14);
    expect(KingCoo.launches(fury: false), [1.4, 3.8]);
    expect(KingCoo.launches(fury: true), [1.4, 3.2, 5.0]);
    expect(KingCoo.locks(fury: false).map((t) => t.toStringAsFixed(2)), [
      '0.60',
      '3.00',
    ]);
    expect(KingCoo.locks(fury: true).map((t) => t.toStringAsFixed(2)), [
      '0.60',
      '2.40',
      '4.20',
    ]);
    expect(KingCoo.telegraph, closeTo(2.2, 1e-12));
    expect(KingCoo.cycleTime(-1), 0);
    expect(KingCoo.cycleNumber(-1), -1);
    expect(KingCoo.cycleTime(15), closeTo(1, 1e-12));
    expect(KingCoo.cycleNumber(15), 1);
    expect(KingCoo.count(6, 7.6), 0);
    expect(KingCoo.count(7.6, 7.6), 1);
    expect(KingCoo.count(22, 7.6), 2);
  });

  test('a crumb bomb: ring, toss, burst, a 1 s cloud, then crumbs', () {
    const lob = CrumbLob(lockedAt: 10, lockX: .22, lockY: .5);
    expect(lob.launchAt, closeTo(10.8, 1e-9));
    expect(lob.burstAt, closeTo(12.2, 1e-9));
    expect(lob.cloudEndsAt, closeTo(13.2, 1e-9));
    expect(lob.crumbsEndAt, closeTo(13.6, 1e-9));
    const eps = 1e-6;
    expect(lob.phase(10), LobPhase.windup);
    expect(lob.phase(lob.launchAt - eps), LobPhase.windup);
    expect(lob.phase(lob.launchAt), LobPhase.flying);
    expect(lob.phase(lob.burstAt - eps), LobPhase.flying);
    expect(lob.phase(lob.burstAt), LobPhase.cloud);
    expect(lob.phase(lob.cloudEndsAt - eps), LobPhase.cloud);
    expect(lob.phase(lob.cloudEndsAt), LobPhase.crumbs);
    expect(lob.phase(lob.crumbsEndAt), LobPhase.gone);
    expect(lob.flight(lob.launchAt), 0);
    expect(lob.flight(lob.launchAt + .7), closeTo(.5, 1e-9));
    expect(lob.flight(lob.burstAt), 1);
    // The cloud grows, holds at .11, shrinks, and only a live one hurts.
    final burst = lob.burstAt;
    expect(lob.cloudRadius(burst - .1), 0);
    expect(lob.hurts(burst - .1), isFalse);
    expect(lob.cloudRadius(burst), 0, reason: 'grows from nothing');
    expect(lob.cloudRadius(burst + .06), inExclusiveRange(0, .11));
    expect(lob.cloudRadius(burst + .5), closeTo(.11, 1e-12));
    expect(lob.hurts(burst + .5), isTrue);
    expect(lob.cloudRadius(burst + 1 - .075), inExclusiveRange(0, .11));
    expect(lob.cloudRadius(burst + 1 + eps), 0);
    expect(lob.hurts(burst + 1.1), isFalse);
    expect(lob.crumbs(lob.cloudEndsAt), 1);
    expect(lob.crumbs(lob.cloudEndsAt + .2), closeTo(.5, 1e-9));
    expect(lob.crumbs(burst + .5), 0);
  });

  test('cloud heights: one in calm, a bracket around the bird in fury', () {
    expect(KingCoo.cloudHeights(.5, fury: false), [.5]);
    expect(KingCoo.cloudHeights(.04, fury: false), [KingCoo.lockMin]);
    final bracket = KingCoo.cloudHeights(.5, fury: true);
    expect(bracket, hasLength(2));
    expect(bracket[0], closeTo(.2, 1e-12));
    expect(bracket[1], closeTo(.8, 1e-12));
    // The bird's own height is a .30 corridor between the two clouds.
    expect(bracket[1] - bracket[0], closeTo(.6, 1e-12));
    // A centre outside .12 to .88 is dropped.
    expect(KingCoo.cloudHeights(.3, fury: true), [closeTo(.6, 1e-12)]);
    expect(KingCoo.cloudHeights(.7, fury: true), [closeTo(.4, 1e-12)]);
    expect(KingCoo.cloudHeights(.14, fury: true), [closeTo(.44, 1e-12)]);
    for (var y = .14; y <= .86; y += .01) {
      expect(KingCoo.cloudHeights(y, fury: true), isNotEmpty, reason: '$y');
    }
    const lob = CrumbLob(lockedAt: 0, lockX: .22, lockY: .5, fury: true);
    expect(lob.cloudHeights, hasLength(2));
  });

  test(
    'the chest: fluffed, puffed from 7.6 s, whistle at 9.2, closes at 10',
    () {
      expect(KingCoo.windowOpen(7.59), isFalse);
      expect(KingCoo.windowOpen(7.6), isTrue);
      expect(KingCoo.windowOpen(9.99), isTrue);
      expect(KingCoo.windowOpen(10.0), isFalse);
      expect(KingCoo.puffAmount(7.0), 0);
      expect(KingCoo.puffAmount(7.6), 0);
      expect(KingCoo.puffAmount(8.4), closeTo(.5, 1e-9));
      expect(KingCoo.puffAmount(9.2), 1);
      expect(KingCoo.puffAmount(9.99), 1);
      expect(KingCoo.puffAmount(10.2), closeTo(.5, 1e-9));
      expect(KingCoo.puffAmount(10.4), 0);
      expect(KingCoo.puffAmount(13), 0);
      // Half damage (at least one) while fluffed, double while puffed.
      expect(KingCoo.strikeDamage(10, puffed: false), 5);
      expect(KingCoo.strikeDamage(1, puffed: false), 1);
      expect(KingCoo.strikeDamage(30, puffed: false), 15);
      expect(KingCoo.strikeDamage(10, puffed: true), 20);
      expect(KingCoo.strikeDamage(60, puffed: true), 120);
      expect(KingCoo.popDamage, 60);
    },
  );

  test('the squadron: a V on even cycles, a picket on odd, both in fury', () {
    final v = KingCoo.squad(cycle: 0, birdY: .4, fury: false);
    expect(v, hasLength(1));
    expect(v.single.shape, SquadShape.v);
    expect(v.single.slots, hasLength(5));
    expect(v.single.slots.first.y, closeTo(.4, 1e-12));
    expect(v.single.slots.first.behind, 0);
    final ys = v.single.slots.map((s) => s.y).toList()..sort();
    expect(ys.first, closeTo(.4 - .15, 1e-12));
    expect(ys.last, closeTo(.4 + .15, 1e-12));
    // The V's tip follows the bird within .25 to .75.
    expect(
      KingCoo.squad(cycle: 2, birdY: .1, fury: false).single.slots.first.y,
      .25,
    );
    expect(
      KingCoo.squad(cycle: 2, birdY: .9, fury: false).single.slots.first.y,
      .75,
    );
    // A picket leaves one .30 gap, centred unless the bird is in the middle.
    for (final (cycle, bird, gap) in [
      (1, .2, .5),
      (3, .8, .5),
      (1, .5, .30),
      (5, .5, .30),
      (3, .5, .70),
      (7, .4, .70),
    ]) {
      final plan = KingCoo.squad(cycle: cycle, birdY: bird, fury: false).single;
      expect(plan.shape, SquadShape.picket, reason: '$cycle');
      expect(plan.gap, gap, reason: 'cycle $cycle bird $bird');
      // No pigeon inside the gap, and none so close that the bird fits past.
      for (final slot in plan.slots) {
        expect(
          (slot.y - gap).abs(),
          greaterThanOrEqualTo(KingCoo.picketFirst - 1e-9),
          reason: 'cycle $cycle',
        );
      }
      final sorted = plan.slots.map((s) => s.y).toList()..sort();
      for (var i = 1; i < sorted.length; i++) {
        final apart = sorted[i] - sorted[i - 1];
        // Across the gap the distance is the gap plus the margins; elsewhere
        // neighbours are a picket spacing apart.
        expect(
          apart,
          anyOf(closeTo(KingCoo.picketSpacing, 1e-9), greaterThan(.4)),
          reason: 'cycle $cycle slot $i',
        );
      }
    }
    // Fury calls both: a V, then a centred picket 1.4 s later.
    final both = KingCoo.squad(cycle: 4, birdY: .3, fury: true);
    expect(both.map((p) => p.shape), [SquadShape.v, SquadShape.picket]);
    expect(both[0].delay, 0);
    expect(both[1].delay, 1.4);
    expect(both[1].gap, .5);
  });

  test('the clock drives his getters; before combat nothing is on', () {
    final arriving = coo(combat: -1);
    expect(arriving.phase, BossPhase.arriving);
    expect(arriving.cooCycle, 0);
    expect(arriving.cooCycleNumber, -1);
    expect(arriving.puffWindow, isFalse);
    expect(arriving.puffAmount, 0);
    expect(arriving.puffs, 0);
    expect(arriving.whistlesDue, 0);
    expect(arriving.combatTime, closeTo(-1, 1e-12));

    final fluffed = coo(combat: 5);
    expect(fluffed.cooCycle, closeTo(5, 1e-12));
    expect(fluffed.puffWindow, isFalse);
    expect(fluffed.puffAmount, 0);
    expect(fluffed.puffs, 0);

    final inhaling = coo(combat: 8.4);
    expect(inhaling.puffWindow, isTrue);
    expect(inhaling.puffAmount, closeTo(.5, 1e-9));
    expect(inhaling.puffs, 1);
    expect(inhaling.whistlesDue, 0);

    final whistled = coo(combat: 9.5);
    expect(whistled.puffWindow, isTrue);
    expect(whistled.whistlesDue, 1);

    final second = coo(combat: 14 + 8.4);
    expect(second.cooCycleNumber, 1);
    expect(second.puffs, 2);
    expect(second.puffWindow, isTrue);
  });

  test('a pop closes the window and deflates the chest', () {
    final boss = coo(combat: 8.6);
    final arrival = boss.arrivalDuration;
    boss.poppedAt = arrival + 8.5;
    expect(boss.popped, isTrue);
    expect(boss.puffWindow, isFalse);
    expect(boss.puffAmount, 0);
    expect(boss.cooHint, 'POP! · No squadron');
    // A pop in the previous cycle's window does not count in this one.
    final later = coo(combat: 14 + 3)..poppedAt = arrival + 8.5;
    expect(later.popped, isFalse);
    // Not fighting: nothing is popped.
    expect((coo(combat: -1)..poppedAt = 0).popped, isFalse);
  });

  test('lobs latch, and their counters follow the boss clock', () {
    final boss = coo(combat: 3);
    expect(boss.lobs, isEmpty);
    expect(boss.lobsLocked, 0);
    final at = boss.arrivalDuration;
    boss.lobs.addAll([
      CrumbLob(lockedAt: at + .6, lockX: .22, lockY: .4),
      CrumbLob(lockedAt: at + 3.0, lockX: .22, lockY: .6),
    ]);
    boss.age = at + 1.5;
    expect([boss.lobsLocked, boss.lobsLaunched, boss.lobBursts], [2, 1, 0]);
    expect(boss.cooHint, 'CRUMB BOMB · Leave the ring!');
    boss.age = at + 2.9;
    expect([boss.lobsLocked, boss.lobsLaunched, boss.lobBursts], [2, 1, 1]);
    boss.age = at + 6;
    expect([boss.lobsLocked, boss.lobsLaunched, boss.lobBursts], [2, 2, 2]);
  });

  test('hints name the moment', () {
    expect(coo(combat: 5).cooHint, contains('crumb bombs'));
    expect(coo(combat: 8.4).cooHint, 'PUFFED · Shoot his chest (x2)!');
    expect(coo(combat: 9.5).cooHint, 'SQUADRON · Follow the open lane!');
    expect(
      coo(combat: 5, enraged: true).cooHint,
      'FURY · Stay between the rings',
    );
  });

  test('a level with King Coo is fought and won by the shared bot', () {
    final plan = nyPlan(
      lineup: const [EnemyKind.simpleBat, EnemyKind.alleyPigeon],
      boss: BossKind.kingCoo,
    );
    expect(plan.problem, isNull);
    SkyBoss? seen;
    var fights = 0;
    final sim = flyNy(
      plan,
      watch: (sim) {
        final boss = sim.boss;
        if (boss == null) return;
        seen ??= boss;
        if (boss.phase == BossPhase.attacking) {
          fights++;
          expect(
            boss.x,
            closeTo(math.max(FlightSimulation.birdX + .70, 2.2 - .55), 1e-9),
          );
          expect(
            boss.y,
            closeTo(.5 + .06 * math.sin(.9 * boss.combatTime), 1e-9),
          );
        }
        // He shoots nothing and calls no helpers.
        expect(sim.bossAmmo, isEmpty);
      },
    );
    expect(seen, isNotNull);
    expect(seen!.kind, BossKind.kingCoo);
    expect(seen!.maxHp, 140);
    expect(seen!.cinematic, isTrue);
    expect(fights, greaterThan(0));
    expect(sim.endReason, EndReason.completed);
    expect(sim.bossesDefeated, 1);
    expect(sim.victoryGlide, isTrue);
    expect(sim.supportsMiniBosses, isTrue);
  });
}
