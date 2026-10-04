import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';

FlightSimulation _arena({int version = FlightSimulation.currentRulesVersion}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: version),
    practice: true,
    course: FlightCourse.starTrail,
    rulesVersion: version,
    random: math.Random(7),
  );
  _step(sim, 3);
  sim.obstacles.clear();
  sim.enemies.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  return sim;
}

void _step(FlightSimulation sim, double dt) {
  final now = (sim.elapsed + dt) * 1000;
  sim.apply(
    const MovementInput(valid: true),
    TrackingSample(
      mode: sim.rules.mode,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  sim.tick(dt, now, viewportWidth: 2.2);
}

EnemyAmmo _pellet(
  double x,
  double y, {
  EnemyAttack attack = EnemyAttack.aimed,
}) => EnemyAmmo(x: x, y: y, vx: -.44, vy: 0, attack: attack);

/// A rock already touching a pellet at (x, y), so the next step meets it.
BirdRock _rock(double x, double y, double charge) => BirdRock(
  x: x - .02,
  y: y,
  damage: PowerShot.damage(BirdRock.baseDamage, charge),
  charge: charge,
);

/// Enemies that never fire, so only the blast can change them.
SkyEnemy _bat(double x, double y) => SkyEnemy(x: x, y: y, appearance: 0);
SkyEnemy _moth(double x, double y) =>
    SkyEnemy(x: x, y: y, appearance: 2)..fireIn = 99;

void main() {
  test('shatter tuning grows with charge from its threshold', () {
    expect(PowerShot.shatters(0), isFalse);
    expect(PowerShot.shatters(PowerShot.shatterCharge - .01), isFalse);
    expect(PowerShot.shatters(PowerShot.shatterCharge), isTrue);
    expect(PowerShot.shatters(1), isTrue);
    expect(PowerShot.shatterReach(PowerShot.shatterCharge), .12);
    expect(PowerShot.shatterReach(1), closeTo(.24, 1e-12));
    expect(PowerShot.shatterDamage(40), 20);
    expect(PowerShot.shatterDamage(21), 11);
    expect(PowerShot.shatterDamage(1), 1);
  });

  test('a weak rock only cancels the pellet', () {
    for (final charge in [0.0, PowerShot.shatterCharge - .05]) {
      final sim = _arena();
      final near = _bat(1, .42);
      final nearbyAmmo = _pellet(1, .65);
      sim.enemies.add(near);
      sim.enemyAmmo.addAll([_pellet(1, .5), nearbyAmmo]);
      sim.rocks.add(_rock(1, .5, charge));
      _step(sim, .02);
      expect(sim.enemyAmmo, [nearbyAmmo]);
      expect(sim.rocks, isEmpty);
      expect(sim.projectilesDeflected, 1);
      expect(sim.ammoShattered, 0);
      expect(sim.ammoShatters, isEmpty);
      expect(sim.enemyAmmoImpacts.single.stop, AmmoStop.deflected);
      expect(near.hp, near.maxHp);
    }
  });

  test('a charged rock shatters the pellet and damages enemies nearby', () {
    final sim = _arena();
    // Clear of the rock itself, so only the blast can reach them.
    final bat = _bat(1, .40);
    final moth = _moth(1, .62);
    final far = _bat(1, .82);
    sim.enemies.addAll([bat, moth, far]);
    sim.enemyAmmo.add(_pellet(1, .5));
    sim.rocks.add(_rock(1, .5, 1));
    final score = sim.score;
    _step(sim, .02);
    expect(sim.enemyAmmo, isEmpty);
    expect(sim.rocks, isEmpty, reason: 'the rock is spent on the pellet');
    expect(sim.projectilesDeflected, 1);
    expect(sim.ammoShattered, 1);
    expect(sim.enemyAmmoImpacts, isEmpty, reason: 'the blast replaces it');
    final shatter = sim.ammoShatters.single;
    expect(shatter.reach, closeTo(.24, 1e-12));
    expect(shatter.charge, 1);
    expect(shatter.worldX - shatter.x, closeTo(sim.distance, .01));
    expect(shatter.at, closeTo(sim.elapsed, .02));
    // 40 damage at full charge; the blast carries half of it.
    expect(sim.enemies, isNot(contains(bat)));
    expect(sim.enemies, containsAll([moth, far]));
    expect(sim.enemiesDefeated, 1);
    expect(sim.score, score + 3);
    expect(
      sim.events.where((e) => e.kind == FlightEventKind.enemyHit).single,
      isA<FlightEvent>().having((e) => e.enemyKind, 'kind', EnemyKind.caveBat),
    );
    expect(moth.hp, moth.maxHp - 20);
    expect(moth.lastHitAt, closeTo(moth.age, .02));
    expect(far.hp, far.maxHp);
  });

  test('a shatter destroys nearby enemy ammo', () {
    for (final reverse in [false, true]) {
      final sim = _arena();
      final cues = CombatAudioCues()..advance(sim);
      final nearby = [
        _pellet(1, .65),
        _pellet(1, .35, attack: EnemyAttack.fan),
        _pellet(1.15, .5, attack: EnemyAttack.crumb),
      ];
      final pellets = [_pellet(1, .5), ...nearby];
      sim.enemyAmmo.addAll(reverse ? pellets.reversed : pellets);
      sim.rocks.add(_rock(1, .5, 1));
      final score = sim.score;
      _step(sim, .02);
      expect(sim.enemyAmmo, isEmpty, reason: 'reverse order: $reverse');
      expect(sim.rocks, isEmpty);
      expect(sim.ammoShattered, 1);
      expect(sim.ammoShatters, hasLength(1));
      expect(sim.projectilesDeflected, 4);
      expect(sim.score, score);
      expect(sim.enemyAmmoImpacts, hasLength(3));
      expect(
        sim.enemyAmmoImpacts.map((i) => i.attack),
        unorderedEquals(nearby.map((p) => p.attack)),
      );
      expect(
        sim.enemyAmmoImpacts.map((i) => i.stop),
        everyElement(AmmoStop.deflected),
      );
      expect(cues.advance(sim), ['deflect', 'lava_burst']);
      expect(cues.advance(sim), isEmpty);
    }
  });

  test('ammo cleanup follows the circular blast edge at each charge', () {
    for (final charge in [PowerShot.shatterCharge, .7, 1.0]) {
      final sim = _arena();
      final reach = PowerShot.shatterReach(charge) + EnemyAmmo.radius;
      final inside = _pellet(1, .5 + reach - .0001);
      final outside = _pellet(1, .5 + reach + .0001);
      final diagonal = _pellet(1 + reach * .8, .5 + reach * .8);
      sim.enemyAmmo.addAll([_pellet(1, .5), inside, outside, diagonal]);
      sim.rocks.add(_rock(1, .5, charge));
      _step(sim, .02);
      expect(sim.enemyAmmo, [outside, diagonal], reason: 'charge $charge');
      expect(sim.projectilesDeflected, 2);
    }
  });

  test('destroyed pellets do not chain blasts or clear boss ammo', () {
    final sim = _arena();
    final outside = _pellet(1, .84);
    final bossAmmo = BossAmmo(x: 1, y: .65, vx: -.44, vy: 0);
    sim.enemyAmmo.addAll([_pellet(1, .5), _pellet(1, .65), outside]);
    sim.bossAmmo.add(bossAmmo);
    sim.rocks.add(_rock(1, .5, 1));
    _step(sim, .02);
    expect(sim.enemyAmmo, [outside]);
    expect(sim.bossAmmo, [bossAmmo]);
    expect(sim.ammoShattered, 1);
    expect(sim.ammoShatters, hasLength(1));
    expect(sim.projectilesDeflected, 2);
  });

  test('rules 36 through 58 keep nearby ammo when a pellet shatters', () {
    for (final version in [36, 58]) {
      final sim = _arena(version: version);
      final nearby = _pellet(1, .65);
      final moth = _moth(1, .4);
      sim.enemies.add(moth);
      sim.enemyAmmo.addAll([_pellet(1, .5), nearby]);
      sim.rocks.add(_rock(1, .5, 1));
      _step(sim, .02);
      expect(sim.enemyAmmo, [nearby], reason: 'version $version');
      expect(moth.hp, moth.maxHp - 20);
      expect(sim.ammoShattered, 1);
      expect(sim.projectilesDeflected, 1);
      expect(sim.enemyAmmoImpacts, isEmpty);
    }
  });

  test('a fuller charge reaches further', () {
    for (final (charge, reached) in [
      (PowerShot.shatterCharge, false),
      (1.0, true),
    ]) {
      final sim = _arena();
      final moth = _moth(1, .72);
      sim.enemies.add(moth);
      sim.enemyAmmo.add(_pellet(1, .5));
      sim.rocks.add(_rock(1, .5, charge));
      _step(sim, .02);
      expect(sim.ammoShattered, 1);
      expect(moth.hp < moth.maxHp, reached, reason: 'charge $charge');
    }
  });

  test('rules before version 36 keep the plain cancel', () {
    final sim = _arena(version: 35);
    final bat = _bat(1, .42);
    sim.enemies.add(bat);
    sim.enemyAmmo.add(_pellet(1, .5));
    sim.rocks.add(_rock(1, .5, 1));
    _step(sim, .02);
    expect(sim.enemyAmmo, isEmpty);
    expect(sim.ammoShattered, 0);
    expect(sim.ammoShatters, isEmpty);
    expect(bat.hp, bat.maxHp);
  });

  group('boss in the blast', () {
    FlightSimulation fight(BossKind kind, {int? maxHp, double into = .5}) {
      final sim = _arena();
      final boss = SkyBoss(number: 1, x: 1.6, kind: kind, maxHp: maxHp)
        ..fireIn = 99
        ..summonIn = 99;
      boss.age = boss.arrivalDuration + into;
      sim.boss = boss;
      _step(sim, .02);
      sim.bossAmmo.clear();
      return sim;
    }

    test('takes blast damage', () {
      final sim = fight(BossKind.baronBat);
      final boss = sim.boss!;
      sim.enemyAmmo.add(_pellet(boss.x - .22, boss.y));
      sim.rocks.add(_rock(boss.x - .22, boss.y, 1));
      _step(sim, .02);
      expect(sim.ammoShattered, 1);
      expect(boss.hp, boss.maxHp - 20);
    });

    test('a shield absorbs the blast', () {
      final sim = fight(
        BossKind.duskMoth,
        into: SkyBoss.shieldStartsAt + .2,
      );
      final boss = sim.boss!;
      expect(boss.shielded, isTrue);
      sim.enemyAmmo.add(_pellet(boss.x - .33, boss.y));
      sim.rocks.add(_rock(boss.x - .33, boss.y, 1));
      _step(sim, .02);
      expect(sim.ammoShattered, 1);
      expect(boss.hp, boss.maxHp);
      expect(boss.lastShieldHitAt, closeTo(boss.age, .02));
    });

    test('a finishing blast defeats it mid-sweep without upsetting pellets', () {
      final sim = fight(BossKind.baronBat, maxHp: 5);
      final boss = sim.boss!;
      sim.enemyAmmo.addAll([
        _pellet(boss.x - .22, boss.y),
        _pellet(boss.x - .22, boss.y + .15),
        _pellet(.9, .2),
      ]);
      sim.rocks.addAll([
        _rock(boss.x - .22, boss.y, 1),
        _rock(boss.x - .22, boss.y + .15, 1),
      ]);
      _step(sim, .02);
      expect(sim.ammoShattered, 2);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.bossesDefeated, 1);
      expect(sim.enemyAmmo, isEmpty);
      expect(sim.ammoShatters, hasLength(2), reason: 'both blasts still play');
    });
  });

  test('a shatter bursts under the deflect cue', () {
    final cues = CombatAudioCues();
    final sim = _arena();
    cues.advance(sim);
    sim.enemyAmmo.add(_pellet(1, .5));
    sim.rocks.add(_rock(1, .5, 0));
    _step(sim, .02);
    expect(cues.advance(sim), ['deflect']);
    sim.enemyAmmo.add(_pellet(1, .5));
    sim.rocks.add(_rock(1, .5, 1));
    _step(sim, .02);
    expect(cues.advance(sim), ['deflect', 'lava_burst']);
    expect(CombatAudioCues.powerShotCharge, PowerShot.shatterCharge);
  });
}
