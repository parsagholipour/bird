import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';

import 'boss_fight_test.dart' show hover;
import 'stone_door_test.dart' show flight, wall;
import 'touch_combat_test.dart' show playing, tick;

Object rockState(FlightSimulation sim) => [
  sim.rockImpacts,
  sim.doorsDestroyed,
  for (final rock in sim.rocks)
    [
      rock.x,
      rock.y,
      rock.velocityX,
      rock.velocityY,
      rock.reboundAge,
      rock.charge,
      rock.damage,
    ],
];

void main() {
  test('a wall hit keeps the rock visible, bounces it back and drops it', () {
    final sim = playing();
    sim.obstacles.add(Obstacle(x: 1, center: .7, gap: .3));
    final rock = BirdRock(x: .96, y: .3);
    sim.rocks.add(rock);

    tick(sim, .02);
    expect(sim.rockImpacts, 1);
    expect(sim.rocks, contains(rock), reason: 'A wall hit must not erase it');
    final impactX = rock.x, impactY = rock.y;

    tick(sim, .2);
    expect(sim.rocks, contains(rock));
    expect(rock.x, lessThan(impactX), reason: 'It rebounds from the wall');
    expect(rock.y, greaterThan(impactY), reason: 'Gravity pulls it down');
    expect(sim.rockImpacts, 1, reason: 'One impact per shot');
  });

  test('all wall families stop charged and base shots even on slow frames', () {
    for (final kind in ObstacleKind.values) {
      for (final charge in [0.0, 1.0]) {
        final sim = playing();
        final obstacle = Obstacle(x: 1, center: .5, gap: .3, kind: kind);
        sim.obstacles.add(obstacle);
        final y = kind.floating ? obstacle.orbs.first.y : .2;
        final rock = BirdRock(x: .8, y: y, charge: charge);
        sim.rocks.add(rock);
        tick(sim, .3);
        expect(rock.rebounding, isTrue, reason: '$kind / $charge');
        expect(sim.rocks, contains(rock));
        expect(rock.x, lessThan(obstacle.x));
        expect(sim.rockImpacts, 1);
      }
    }
  });

  test('a clear opening keeps the outgoing shot straight', () {
    final sim = playing();
    sim.obstacles.add(Obstacle(x: 1, center: .5, gap: .3));
    final rock = BirdRock(x: .96, y: .5);
    sim.rocks.add(rock);
    tick(sim, .2);
    expect(rock.rebounding, isFalse);
    expect(rock.x, closeTo(.96 + BirdRock.speed * .2, 1e-10));
    expect(rock.y, .5);
    expect(sim.rockImpacts, 0);
  });

  test('a panel takes one hit and the shell survives even a lethal shot', () {
    for (final charge in [0.0, 1.0]) {
      final sim = flight(version: FlightSimulation.currentRulesVersion);
      final obstacle = wall(sim);
      final damage = PowerShot.damage(10, charge);
      final rock = BirdRock(
        x: obstacle.x - .04,
        y: .5,
        charge: charge,
        damage: damage,
      );
      sim.rocks.add(rock);
      final cues = CombatAudioCues()..advance(sim);
      tick(sim, .02);
      expect(sim.rocks, contains(rock));
      expect(rock.rebounding, isTrue);
      expect(obstacle.door!.hp, 40 - damage);
      expect(cues.advance(sim), contains('rock_hit'));
      final radius = rock.radius;
      hover(sim, .3);
      expect(sim.rockImpacts, 1);
      expect(sim.doorsDestroyed, charge == 1 ? 1 : 0);
      expect(obstacle.door!.hp, 40 - damage);
      expect(rock.radius, radius);
      expect(rock.damage, damage);
      expect(cues.advance(sim), isEmpty);
    }
  });

  test('returning shells cannot hit enemies or cancel incoming ammo', () {
    final sim = playing();
    sim.obstacles.add(Obstacle(x: 1, center: .7, gap: .3));
    final rock = BirdRock(x: .96, y: .3);
    sim.rocks.add(rock);
    tick(sim, .02);
    final enemy = SkyEnemy(x: rock.x - .05, y: rock.y);
    final ammo = EnemyAmmo(
      x: rock.x - .05,
      y: rock.y,
      vx: 0,
      vy: 0,
      attack: EnemyAttack.aimed,
    );
    sim.enemies.add(enemy);
    sim.enemyAmmo.add(ammo);
    tick(sim, .03);
    expect(sim.rocks, contains(rock));
    expect(enemy.hp, enemy.maxHp);
    expect(sim.enemyAmmo, contains(ammo));
    expect(sim.projectilesDeflected, 0);
  });

  test(
    'gravity accelerates the fall and shells retire below or left of view',
    () {
      for (final (x, y) in [(1.0, .15), (2.0, .85)]) {
        final sim = playing();
        sim.obstacles.add(Obstacle(x: x, center: .5, gap: .3));
        final rock = BirdRock(x: x - .04, y: y);
        sim.rocks.add(rock);
        tick(sim, .02);
        final impactY = rock.y;
        hover(sim, .2);
        final firstY = rock.y;
        hover(sim, .2);
        expect(rock.y - firstY, greaterThan(firstY - impactY));
        for (var i = 0; i < 100 && sim.rocks.contains(rock); i++) {
          hover(sim, .02);
        }
        expect(sim.rocks, isEmpty);
        expect(y < .5 ? rock.x < -.2 : rock.y > 1.2, isTrue);
      }
    },
  );

  test('paused, countdown and ended worlds freeze a rebound', () {
    for (final phase in [RunPhase.paused, RunPhase.countdown, RunPhase.ended]) {
      final sim = playing();
      sim.obstacles.add(Obstacle(x: 1, center: .7, gap: .3));
      sim.rocks.add(BirdRock(x: .96, y: .3));
      tick(sim, .02);
      expect(sim.rocks.single.rebounding, isTrue);
      sim.phase = phase;
      final before = rockState(sim);
      tick(sim, .2);
      expect(rockState(sim), before);
    }
  });

  test('version 30 retains the original consumed-on-wall-hit behavior', () {
    final sim = flight(version: 30);
    sim.obstacles.add(Obstacle(x: 1, center: .7, gap: .3));
    sim.rocks.add(BirdRock(x: .96, y: .3));
    tick(sim, .02);
    expect(sim.rockImpacts, 1);
    expect(sim.rocks, isEmpty);
  });

  for (final reducedMotion in [false, true]) {
    test('wall rebounds replay exactly across seeks ($reducedMotion)', () {
      var now = 0.0;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.touch,
          practice: true,
          course: FlightCourse.starTrail,
          seed: 7,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: reducedMotion,
          originMs: 0,
        ),
        () => now,
      );
      final sim = recorder.simulation;
      final checkpoints = <double, Object>{};
      var reboundFrames = 0;
      for (var frame = 1; frame <= 600; frame++) {
        now = frame * 50.0;
        recorder.apply(
          MovementInput(valid: true, flap: sim.birdY > .5 && sim.velocity > 0),
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
        if (sim.rocks.any((r) => r.rebounding)) {
          reboundFrames++;
          if (reboundFrames % 7 == 0) checkpoints[now] = rockState(sim);
        }
      }
      expect(reboundFrames, greaterThan(20));
      final replay = ReplayPlayer(ReplayTape.fromJson(recorder.tape.toJson()));
      for (final time in [
        ...checkpoints.keys,
        ...checkpoints.keys.toList().reversed,
      ]) {
        replay.seek(time);
        expect(rockState(replay.simulation), checkpoints[time]);
      }
    });
  }
}
