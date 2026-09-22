import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'boss_fight_test.dart' show arena, step, hover, hitBoss, snapshot;

FlightSimulation spitterArena({
  double width = 2.2,
  int version = FlightSimulation.currentRulesVersion,
}) {
  final sim = arena(version: version, course: FlightCourse.skyCourier)
    ..bossesDefeated = 1;
  step(sim, .02, width);
  for (var i = 0; i < 231; i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    step(sim, .02, width);
  }
  return sim;
}

void main() {
  test('full acid fans leave a clear dodge lane on narrow phones', () {
    for (final width in [640 / 360, 800 / 360]) {
      for (final hp in [180, 90]) {
        for (final targetY in [.15, .5, .85]) {
          final sim = spitterArena(width: width);
          final boss = sim.boss!
            ..hp = hp
            ..volleys = 1
            ..fireIn = .001;
          sim.birdY = targetY;
          sim.velocity = 0;
          step(sim, 1 / 120, width);

          // Measure each real trajectory's closest approach to the aim point.
          // The open center must fit the bird, ammo, and some dodge margin.
          for (final shot in sim.bossAmmo) {
            final dx = FlightSimulation.birdX - shot.x;
            final dy = targetY - shot.y;
            final speed = math.sqrt(shot.vx * shot.vx + shot.vy * shot.vy);
            final clearance = (dx * shot.vy - dy * shot.vx).abs() / speed;
            expect(
              clearance,
              greaterThan(FlightSimulation.birdRadius + BossAmmo.radius + .02),
              reason: 'Dodge lane at width $width, HP $hp, height $targetY',
            );
          }
          expect(sim.bossAmmo, hasLength(4));
          expect(boss.fireIn, closeTo(hp == 90 ? 1.3 : 1.8, .01));
        }
      }
    }
  });

  test('version 21 keeps alternating bats and spitters at full intervals', () {
    final sim = arena(version: 21);
    step(sim);
    for (final (number, kind, hp) in [
      (1, BossKind.baronBat, 12),
      (2, BossKind.spitterBeetle, 18),
      (3, BossKind.baronBat, 18),
      (4, BossKind.spitterBeetle, 24),
    ]) {
      final boss = sim.boss!;
      expect(boss.number, number);
      expect(boss.kind, kind);
      expect(boss.hp, hp);
      expect(sim.bossCutscene, isTrue);
      expect(sim.shoot(), isFalse);
      hover(sim, boss.arrivalDuration + .1);
      hitBoss(sim, count: hp);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.bossesDefeated, number);
      expect(sim.score, number * FlightSimulation.bossBonus);
      expect(sim.bossAmmo, isEmpty);
      expect(sim.enemies, isEmpty);
      expect(sim.enemyAmmo, isEmpty);
      hover(sim, boss.departureDuration + .1);
      expect(sim.boss, isNull);
      expect(sim.obstacles, isNotEmpty);
      sim.elapsed += FlightSimulation.bossInterval - .3;
      step(sim);
      expect(sim.boss, isNull);
      sim.elapsed += .3;
      step(sim);
      expect(sim.boss!.phase, BossPhase.arriving);
      expect(sim.obstacles, isEmpty);
    }
  });

  test('version 15 through 20 recordings keep the 15 HP second bat', () {
    for (final version in [15, 16, 17, 18, 19, 20]) {
      final sim = arena(version: version)..bossesDefeated = 1;
      step(sim);
      expect(sim.boss!.kind, BossKind.baronBat);
      expect(sim.boss!.hp, 15);
      hover(sim, sim.boss!.arrivalDuration + .1);
      sim.boss!.fireIn = .001;
      step(sim);
      expect(sim.bossAmmo, hasLength(1));
      expect(sim.boss!.volleyInterval, 2.15);
    }
  });

  for (final version in [21, 22, 23]) {
    test(
      'version $version acid volleys aim, widen, and accelerate at half health',
      () {
        final sim = spitterArena(version: version);
        final boss = sim.boss!;
        expect(boss.maxHp, 18);
        boss.fireIn = .001;
        sim.birdY = .3;
        sim.velocity = 0;
        step(sim, 1 / 120);
        expect(sim.bossAmmo, hasLength(3));
        final middle = sim.bossAmmo[1];
        final aim = math.atan2(
          .3 - boss.y,
          FlightSimulation.birdX - boss.muzzleX,
        );
        expect(math.atan2(middle.vy, middle.vx), closeTo(aim, .001));
        final first = sim.bossAmmo.first;
        expect(
          math.acos(
            (first.vx * middle.vx + first.vy * middle.vy) / (.56 * .56),
          ),
          closeTo(version >= 23 ? .30 : .18, 1e-9),
        );
        expect(
          math.sqrt(middle.vx * middle.vx + middle.vy * middle.vy),
          closeTo(.56, 1e-9),
        );
        expect(middle.x, closeTo(boss.muzzleX + middle.vx / 120, 1e-9));
        expect(boss.fireIn, lessThan(1.8));
        expect(boss.fireIn, greaterThan(1.7));
        final normalInterval = boss.fireIn;
        sim.bossAmmo.clear();
        boss.fireIn = .001;
        step(sim);
        expect(sim.bossAmmo, hasLength(version >= 23 ? 4 : 5));
        hitBoss(sim, count: 9);
        expect(boss.hp, 9);
        expect(boss.enraged, isTrue);
        expect(boss.enragedAt.isFinite, isTrue);
        sim.bossAmmo.clear();
        boss.fireIn = .001;
        step(sim);
        expect(sim.bossAmmo, hasLength(version >= 23 ? 4 : 5));
        expect(boss.fireIn, lessThan(normalInterval));
        for (final shot in sim.bossAmmo) {
          expect(
            math.sqrt(shot.vx * shot.vx + shot.vy * shot.vy),
            closeTo(.66, 1e-9),
          );
        }
      },
    );
  }

  test('beetle helpers get a visible approach even on narrow phones', () {
    final sim = spitterArena(width: 640 / 360);
    final boss = sim.boss!;
    boss.summonIn = .001;
    step(sim, .02, 640 / 360);
    final helper = sim.enemies.single;
    expect(helper.kind, EnemyKind.spitterBeetle);
    expect(helper.x, greaterThan(FlightSimulation.birdX + .9));
    expect(helper.volleys, 0);
    expect(helper.fireIn, greaterThan(.70));
    expect(sim.enemyAmmo, isEmpty);
    final interval = boss.summonIn;
    sim.enemies.clear();
    sim.rocks.addAll(
      List.generate(9, (_) => BirdRock(x: boss.x - .07, y: boss.y)),
    );
    step(sim, .02, 640 / 360);
    expect(boss.hp, 90);
    boss.summonIn = .001;
    step(sim, .02, 640 / 360);
    expect(sim.enemies.single.kind, EnemyKind.spitterBeetle);
    expect(boss.summonIn, lessThan(interval));
    var maxAmmo = 0, maxHelpers = 0;
    for (var i = 0; i < 1000; i++) {
      sim.birdY = .5;
      sim.velocity = 0;
      step(sim, .1, 640 / 360);
      maxAmmo = math.max(maxAmmo, sim.bossAmmo.length);
      maxHelpers = math.max(maxHelpers, sim.enemies.length);
    }
    expect(maxAmmo, lessThan(30));
    expect(maxHelpers, lessThan(5));
  });

  test('pausing freezes the spitter, acid and helpers through countdown', () {
    final sim = spitterArena();
    hover(sim, 5);
    final before = snapshot(sim);
    sim.takeBreak();
    step(sim, .5);
    sim.resume();
    step(sim, 2);
    step(sim, 1.1);
    expect(snapshot(sim), before);
  });

  test('second boss can be defeated with normal flaps and legal shots', () {
    final sim = arena(version: FlightSimulation.currentRulesVersion)
      ..bossesDefeated = 1;
    var now = sim.elapsed * 1000;
    for (var i = 0; i < 2500 && sim.bossesDefeated == 1; i++) {
      now += 20;
      sim.apply(
        MovementInput(valid: true, flap: sim.birdY > .56 && sim.velocity > 0),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      if (sim.canShoot) sim.shoot();
      sim.tick(.02, now);
    }
    expect(sim.bossesDefeated, 2);
    expect(sim.phase, RunPhase.playing);
    expect(sim.hearts, greaterThan(0));
    expect(sim.flaps, greaterThan(0));
    expect(sim.shots, greaterThanOrEqualTo(18));
  });
}
