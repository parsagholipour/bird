import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

FlightSimulation arena({
  FlightCourse course = FlightCourse.starTrail,
  // Keep the original encounter regressions as a version-16 replay contract.
  int version = 16,
  GameMode? rules,
}) =>
    FlightSimulation(
        rules: rules ?? TapFlyMode(rulesVersion: version),
        practice: true,
        course: course,
        rulesVersion: version,
        random: Random(4),
      )
      ..phase = RunPhase.playing
      ..started = true
      ..elapsed = FlightSimulation.bossInterval - .01;

void step(FlightSimulation sim, [double dt = .02, double width = 2.2]) {
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
  sim.tick(dt, now, viewportWidth: width);
}

void hover(FlightSimulation sim, double seconds) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    step(sim);
  }
}

void hitBoss(FlightSimulation sim, {int count = 1}) {
  final boss = sim.boss!;
  for (var i = 0; i < count; i++) {
    sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y));
  }
  step(sim);
}

Object snapshot(FlightSimulation sim) => [
  sim.elapsed,
  sim.phase,
  sim.score,
  sim.shots,
  sim.enemiesDefeated,
  sim.bossesDefeated,
  sim.birdY,
  sim.velocity,
  sim.hearts,
  sim.shield,
  sim.courierBumps,
  sim.gates,
  if (sim.boss case final boss?)
    [
      boss.phase,
      boss.number,
      boss.kind,
      boss.volleys,
      boss.summons,
      boss.hp,
      boss.x,
      boss.y,
      boss.age,
      boss.fireIn,
      boss.summonIn,
      boss.defeatedAt,
      boss.shielded,
      boss.shieldWarning,
      boss.lastShieldHitAt,
    ],
  sim.bossAmmo.map((a) => [a.x, a.y, a.vx, a.vy]).toList(),
  sim.rocks.map((r) => [r.x, r.y]).toList(),
  sim.enemies.map((e) => [e.x, e.y]).toList(),
  sim.obstacles.map((o) => [o.kind, o.x, o.target]).toList(),
];

void main() {
  test('only new touch combat flights get periodic bosses', () {
    for (final version in [7, 12, 13, 14, 15, 16, 17, 20, 21, 22]) {
      for (final course in FlightCourse.values) {
        for (final rules in <GameMode>[
          TapFlyMode(rulesVersion: version),
          JumpFlyMode(),
          PushUpFlightMode(cycleSeconds: 3),
          SquatFlyMode(cycleSeconds: 3),
        ]) {
          final sim = arena(course: course, rules: rules, version: version);
          step(sim);
          expect(
            sim.boss != null,
            version >= 15 && rules.mode == PlayMode.touch && !course.relaxed,
          );
        }
      }
    }
  });

  test(
    'arrival clears the normal world without counting or missing pickups',
    () {
      final sim = arena()
        ..elapsed = FlightSimulation.bossInterval - .001
        ..combo = 7;
      sim.obstacles.add(Obstacle(x: .9, center: .5, gap: .4));
      sim.stars.add(SkyStar(x: .3, y: .5));
      sim.starTrios.add(StarTrio(x: .3, y: .5));
      sim.enemies.add(SkyEnemy(x: .47, y: .5));
      sim.rocks.add(BirdRock(x: .8, y: .5));
      step(sim);
      expect(sim.boss!.phase, BossPhase.arriving);
      expect(sim.boss!.hp, 12);
      expect(sim.obstacles, isEmpty);
      expect(sim.stars, isEmpty);
      expect(sim.starTrios, isEmpty);
      expect(sim.enemies, isEmpty);
      expect(sim.rocks, isEmpty);
      expect(sim.bossAmmo, isEmpty);
      expect(sim.gates, 0);
      expect(sim.score, 0);
      expect(sim.combo, 7);
      expect(sim.shield, isTrue);
      hitBoss(sim); // Shots during the entrance do not silently drain HP.
      expect(sim.boss!.hp, 12);
      hover(sim, 2);
      expect(sim.boss!.phase, BossPhase.arriving);
      expect(sim.bossAmmo, isEmpty);
      expect(sim.obstacles, isEmpty);
    },
  );

  test(
    'boss fires aimed ammo, spread volleys and helpers with bounded lifetimes',
    () {
      final sim = arena(course: FlightCourse.skyCourier);
      step(sim);
      hover(sim, 3.65);
      expect(sim.boss!.phase, BossPhase.attacking);
      expect(sim.boss!.charge, greaterThan(.8));
      expect(sim.bossAmmo, isEmpty);
      hover(sim, .08);
      expect(sim.bossAmmo, hasLength(1));
      final ammo = sim.bossAmmo.single;
      expect(ammo.vx, lessThan(0));
      expect(ammo.vy, lessThan(0)); // Aimed up-left from the moving boss to .5.
      final startX = ammo.x;
      hover(sim, .1);
      expect(ammo.x, lessThan(startX));
      sim.bossAmmo.clear();
      sim.boss!.fireIn = .01;
      step(sim);
      expect(sim.bossAmmo, hasLength(3));
      expect(sim.bossAmmo.map((a) => a.vy).toSet(), hasLength(3));
      hover(sim, 4);
      expect(sim.boss!.summons, greaterThan(0));
      expect(sim.enemies, isNotEmpty);
      var maxAmmo = 0, maxMinions = 0;
      for (var i = 0; i < 1200; i++) {
        hover(sim, .1);
        maxAmmo = max(maxAmmo, sim.bossAmmo.length);
        maxMinions = max(maxMinions, sim.enemies.length);
        expect(sim.obstacles, isEmpty);
      }
      expect(maxAmmo, lessThan(16));
      expect(maxMinions, lessThan(4));
      expect(sim.boss!.hp, 12);
    },
  );

  test('rocks miss at other heights, hit once, and minions intercept them', () {
    final sim = arena();
    step(sim);
    hover(sim, 2.6);
    final boss = sim.boss!;
    sim.rocks.add(BirdRock(x: boss.x - .05, y: .9));
    step(sim, .2);
    expect(boss.hp, 12);
    sim.rocks.clear();
    sim.enemies.add(SkyEnemy(x: boss.x - .07, y: boss.y));
    hitBoss(sim);
    expect(sim.enemiesDefeated, 1);
    expect(boss.hp, 12);
    hitBoss(sim);
    expect(boss.hp, 11);
    expect(sim.rocks, isEmpty);
    hitBoss(sim, count: 5);
    expect(boss.enraged, isTrue);
    boss.fireIn = .01;
    step(sim);
    expect(sim.bossAmmo, hasLength(3));
    expect(boss.fireIn, lessThan(1.55));
  });

  test(
    'slow-frame ammo hits respect shields, recovery, hearts and course rules',
    () {
      for (final course in [
        FlightCourse.starTrail,
        FlightCourse.classic,
        FlightCourse.skyCourier,
      ]) {
        final sim = arena(course: course)..carryingLetter = true;
        step(sim);
        void collide() {
          sim.birdY = .5;
          sim.velocity = 0;
          sim.bossAmmo.add(BossAmmo(x: .8, y: .52, vx: -2, vy: 0));
          step(sim, .25);
        }

        collide();
        expect(sim.bossAmmo, isEmpty);
        if (course == FlightCourse.classic) {
          expect(sim.endReason, EndReason.collision);
          expect(sim.shoot(), isFalse);
        } else if (course == FlightCourse.skyCourier) {
          expect(sim.carryingLetter, isFalse);
          expect(sim.lettersDropped, 1);
          expect(sim.phase, RunPhase.playing);
        } else {
          expect(sim.shield, isFalse);
          expect(sim.hearts, 3);
          collide();
          expect(sim.hearts, 3);
          for (var hp = 2; hp >= 0; hp--) {
            sim.invulnerableUntil = 0;
            collide();
            expect(sim.hearts, hp);
          }
          expect(sim.endReason, EndReason.collision);
        }
      }
    },
  );

  test(
    'victory pays once, clears hazards, resumes gates and schedules a rematch',
    () {
      final sim = arena()..shield = false;
      step(sim);
      hover(sim, 2.6);
      final boss = sim.boss!;
      // Unrelated hazards must vanish before collision resolution on the kill.
      sim.bossAmmo.add(BossAmmo(x: .47, y: .5, vx: -.5, vy: 0));
      sim.enemies.add(SkyEnemy(x: .47, y: .5));
      hitBoss(sim, count: boss.maxHp + 2);
      expect(boss.hp, 0);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.bossesDefeated, 1);
      expect(sim.score, FlightSimulation.bossBonus);
      expect(sim.hearts, 3);
      expect(sim.shield, isTrue);
      expect(sim.enemies, isEmpty);
      expect(sim.bossAmmo, isEmpty);
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.bossDefeated),
        hasLength(1),
      );
      hover(sim, 1.9);
      expect(sim.obstacles, isEmpty);
      expect(sim.score, FlightSimulation.bossBonus);
      hover(sim, .2);
      expect(sim.boss, isNull);
      expect(sim.obstacles, hasLength(1));
      expect(sim.obstacles.single.x, greaterThan(2));
      sim.elapsed += FlightSimulation.bossInterval - .3;
      step(sim);
      expect(sim.boss, isNull);
      sim.elapsed += .3;
      step(sim);
      expect(sim.boss!.number, 2);
      expect(sim.boss!.hp, 15);
      expect(sim.obstacles, isEmpty);
    },
  );

  test('pause, resume countdown and ending freeze the encounter', () {
    final sim = arena(course: FlightCourse.skyCourier);
    step(sim);
    hover(sim, 4);
    final before = snapshot(sim);
    sim.takeBreak();
    final age = sim.boss!.age, fireIn = sim.boss!.fireIn;
    step(sim, .5);
    expect(sim.boss!.age, age);
    expect(sim.boss!.fireIn, fireIn);
    expect(sim.shoot(), isFalse);
    sim.resume();
    step(sim, 2);
    expect(sim.boss!.age, age);
    step(sim, 1.1);
    expect(snapshot(sim), before);
    sim.end(EndReason.quit);
    step(sim);
    expect(sim.boss!.age, age);
    expect(sim.shoot(), isFalse);
  });

  test(
    'first boss is beatable with normal flaps and cooldown-limited shots',
    () {
      final sim = arena(version: FlightSimulation.currentRulesVersion);
      var now = sim.elapsed * 1000;
      for (var i = 0; i < 1500 && sim.bossesDefeated == 0; i++) {
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
      expect(sim.bossesDefeated, 1);
      expect(sim.phase, RunPhase.playing);
      expect(sim.hearts, greaterThan(0));
      expect(sim.flaps, greaterThan(0));
    },
  );

  for (final reduced in [false, true]) {
    test(
      'boss attacks, defeats and rematches replay exactly across seeks ($reduced)',
      () {
        var now = 0.0;
        final recorder = FlightRecorder(
          ReplayTape(
            mode: PlayMode.touch,
            course: FlightCourse.skyCourier,
            practice: false,
            seed: 7,
            cycleSeconds: 3,
            bird: 0,
            reducedMotion: reduced,
            originMs: 0,
          ),
          () => now,
        );
        final sim = recorder.simulation;
        final checkpoints = <double, Object>{};
        for (var frame = 1; frame <= 3400; frame++) {
          now = frame * 50.0;
          recorder.apply(
            MovementInput(
              valid: true,
              flap: sim.birdY > .5 && sim.velocity > 0,
            ),
            TrackingSample(
              mode: PlayMode.touch,
              timestampMs: now,
              receivedMs: now,
              joints: const [],
            ),
            now,
          );
          if (sim.canShoot) recorder.command('shoot');
          recorder.tick(.05, now, 2.2);
          if (frame % 200 == 0) checkpoints[now] = snapshot(sim);
        }
        expect(sim.bossesDefeated, greaterThanOrEqualTo(2));
        expect(sim.phase, RunPhase.playing);
        final replay = ReplayPlayer(
          ReplayTape.fromJson(recorder.tape.toJson()),
        );
        for (final time in [170000.0, 50000.0, 100000.0, 60000.0, 170000.0]) {
          replay.seek(time);
          expect(snapshot(replay.simulation), checkpoints[time]);
        }
      },
    );
  }
}
