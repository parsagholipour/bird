import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';

import 'boss_fight_test.dart' show step, hover, snapshot;

FlightSimulation flight({
  int bosses = 2,
  int version = 27,
  int seed = 4,
  GameMode? rules,
}) =>
    FlightSimulation(
        rules: rules ?? TapFlyMode(rulesVersion: version),
        practice: true,
        course: FlightCourse.starTrail,
        rulesVersion: version,
        random: Random(seed),
      )
      ..phase = RunPhase.playing
      ..started = true
      ..bossesDefeated = bosses;

Obstacle wall(FlightSimulation sim, {double x = 1.5}) {
  final o = Obstacle(x: x, center: .5, gap: .34, door: SkyDoor());
  sim.obstacles.add(o);
  return o;
}

void hit(FlightSimulation sim, Obstacle o, {int damage = 10, double y = .5}) {
  sim.rocks.add(BirdRock(x: o.x - .02, y: y, damage: damage));
  step(sim);
}

Object state(FlightSimulation sim) => [
  snapshot(sim),
  sim.distance,
  sim.doorsDestroyed,
  sim.heartPickups.map((h) => [h.x, h.y]).toList(),
  sim.obstacles
      .map(
        (o) => [
          o.x,
          o.hit,
          o.scored,
          if (o.door case final d?)
            [d.hp, d.age, d.lastHitAt, d.lastHitY, d.destroyedAt],
        ],
      )
      .toList(),
];

void main() {
  test(
    'panels spawn randomly only after boss 2, never in consecutive walls',
    () {
      final patterns = <String>{};
      for (final seed in [4, 8, 17]) {
        final sim = flight(seed: seed)..invulnerableUntil = double.infinity;
        final seen = <Obstacle>{};
        final panels = <bool>[];
        for (var i = 0; i < 1800; i++) {
          hover(sim, .02);
          for (final o in sim.obstacles) {
            if (!seen.add(o)) continue;
            panels.add(o.door != null);
            if (o.door != null) {
              expect(o.kind, ObstacleKind.garden);
              expect(o.door!.hp, 40);
              expect(
                sim.enemies.any((e) => (e.x - (o.x - .55)).abs() < .01),
                isFalse,
              );
              if (panels.length > 1) expect(panels[panels.length - 2], isFalse);
            }
          }
        }
        expect(panels, contains(true));
        expect(panels, contains(false));
        patterns.add(panels.join(','));
      }
      expect(patterns.length, greaterThan(1));
      for (final (bosses, version, rules) in <(int, int, GameMode?)>[
        (0, 27, null),
        (1, 27, null),
        (2, 26, null),
        (2, 27, JumpFlyMode()),
        (2, 27, PushUpFlightMode(cycleSeconds: 3)),
      ]) {
        final sim = flight(bosses: bosses, version: version, rules: rules)
          ..invulnerableUntil = double.infinity;
        for (var i = 0; i < 1800; i++) {
          hover(sim, .02);
          expect(sim.obstacles.every((o) => o.door == null), isTrue);
        }
      }
    },
  );

  test('boss 2 keeps its reward heart and normal interval before boss 3', () {
    final sim = flight(bosses: 1)
      ..elapsed = FlightSimulation.bossInterval
      ..invulnerableUntil = double.infinity;
    step(sim);
    final boss = sim.boss!;
    hover(sim, boss.arrivalDuration + .02);
    sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y, damage: 1000));
    step(sim);
    hover(sim, boss.departureDuration + .02);
    expect(sim.boss, isNull);
    expect(sim.obstacles, isNotEmpty);
    final departure = sim.elapsed;
    final hearts = <SkyHeart>{};
    final panels = <Obstacle>{};
    while (sim.boss == null && sim.elapsed < departure + 46) {
      hover(sim, .02);
      panels.addAll(sim.obstacles.where((o) => o.door != null));
      for (final heart in sim.heartPickups) {
        hearts.add(heart);
        expect(heart.passage!.door, isNull);
      }
    }
    expect(hearts, hasLength(1));
    expect(panels, isNotEmpty);
    expect(sim.boss!.number, 3);
    expect(sim.elapsed - departure, closeTo(45, .1));
  });

  test('walls keep scrolling and flapping while the panel is intact', () {
    final sim = flight();
    final o = wall(sim);
    final x = o.x, distance = sim.distance;
    final now = (sim.elapsed + .02) * 1000;
    sim.apply(
      const MovementInput(valid: true, flap: true),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    sim.tick(.02, now, viewportWidth: 2.2);
    expect(sim.flaps, 1);
    expect(sim.velocity, lessThan(0));
    expect(o.x, lessThan(x));
    expect(sim.distance, greaterThan(distance));
    expect(o.door!.hp, 40);
    expect(sim.canShoot, isTrue);
  });

  test('four base shots damage only the insert and play destruction once', () {
    final sim = flight();
    final o = wall(sim);
    final cues = CombatAudioCues()..advance(sim);
    hit(sim, o, y: .15);
    expect(o.door!.hp, 40, reason: 'The normal upper wall blocks this shot');
    expect(sim.rocks, isEmpty);
    cues.advance(sim);
    for (var shot = 1; shot <= 4; shot++) {
      hit(sim, o);
      expect(o.door!.hp, 40 - shot * 10);
      expect(o.door!.damageStage, shot);
      expect(sim.rocks, isEmpty);
      final sounds = cues.advance(sim);
      expect(sounds, contains('rock_hit'));
      expect(sounds.contains('boss_break'), shot == 4);
      expect(cues.advance(sim), isEmpty);
    }
    expect(sim.doorsDestroyed, 1);
    expect(sim.score, 0);
    hit(sim, o, damage: 100);
    expect(sim.doorsDestroyed, 1);
    expect(sim.rocks, isNotEmpty, reason: 'Ammo now flies through the gap');
    sim.rocks.clear();
    hit(sim, o, y: .85);
    expect(sim.rocks, isEmpty, reason: 'The lower wall stays solid');
  });

  test(
    'an intact panel hurts like a wall; destroying it clears collision immediately',
    () {
      for (final broken in [false, true]) {
        final sim = flight()..shield = false;
        final o = wall(sim, x: FlightSimulation.birdX - .06);
        if (broken) o.door!.takeDamage(40, hitY: .5);
        step(sim);
        expect(sim.hearts, broken ? 3 : 2);
        expect(o.hit, !broken);
        if (broken) {
          expect(o.door!.destructionAge, lessThan(SkyDoor.crumbleDuration));
          sim.birdY = .15;
          step(sim);
          expect(sim.hearts, 2, reason: 'Only the opening clears');
        }
      }
    },
  );

  test(
    'normal cooldown shots clear a moving panel before the bird reaches it',
    () {
      for (final width in [640 / 360, 800 / 360]) {
        final sim = flight();
        final o = wall(sim, x: width - .14);
        for (var frame = 0; frame < 180 && !o.door!.destroyed; frame++) {
          if (sim.canShoot) {
            expect(sim.shoot(), isTrue);
            expect(sim.shoot(), isFalse);
          }
          hover(sim, .02);
        }
        expect(o.door!.destroyed, isTrue);
        expect(sim.elapsed, lessThan(2));
        expect(
          o.x,
          greaterThan(FlightSimulation.birdX + FlightSimulation.birdRadius),
        );
        expect(o.hit, isFalse);
        expect(sim.hearts, 3);
      }
    },
  );

  test('airborne damage stays fixed, upgrades and overkill respect health', () {
    final sim = flight();
    final o = wall(sim);
    sim.rocks.add(BirdRock(x: o.x - .02, y: .5, damage: 7));
    sim.setWeaponDamage(100);
    step(sim);
    expect(o.door!.hp, 33);
    hit(sim, o, damage: 13);
    expect(o.door!.damageStage, 2);
    hit(sim, o, damage: 100);
    expect(o.door!.hp, 0);
    expect(sim.doorsDestroyed, 1);
  });

  test('paused, countdown and ended worlds freeze panel damage and debris', () {
    for (final phase in [RunPhase.paused, RunPhase.countdown, RunPhase.ended]) {
      for (final damage in [10, 40]) {
        final sim = flight();
        final o = wall(sim);
        hit(sim, o, damage: damage);
        sim.phase = phase;
        final before = state(sim);
        step(sim, .2);
        expect(state(sim), before);
        expect(sim.shoot(), isFalse);
      }
    }
  });

  for (final reduced in [false, true]) {
    test('random panels and damage replay exactly ($reduced)', () {
      var now = 0.0;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.touch,
          course: FlightCourse.skyCourier,
          practice: true,
          seed: 7,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: reduced,
          originMs: 0,
        ),
        () => now,
      );
      final sim = recorder.simulation;
      final stages = <int>{};
      final checkpoints = <double, Object>{};
      for (var frame = 1; frame <= 5400; frame++) {
        now = frame * 50.0;
        final panel = sim.obstacles
            .where((o) => o.door != null && o.x > FlightSimulation.birdX)
            .firstOrNull;
        recorder.apply(
          MovementInput(
            valid: true,
            flap: sim.birdY > (panel?.center ?? .5) && sim.velocity > 0,
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
        for (final o in sim.obstacles) {
          if (o.door case final d?) {
            if (stages.add(d.damageStage)) checkpoints[now] = state(sim);
          }
        }
        if (frame % 600 == 0) checkpoints[now] = state(sim);
      }
      expect(stages, {0, 1, 2, 3, 4});
      expect(sim.doorsDestroyed, greaterThan(0));
      final replay = ReplayPlayer(ReplayTape.fromJson(recorder.tape.toJson()));
      for (final time in [
        ...checkpoints.keys,
        ...checkpoints.keys.toList().reversed,
      ]) {
        replay.seek(time);
        expect(state(replay.simulation), checkpoints[time]);
      }
    });
  }
}
