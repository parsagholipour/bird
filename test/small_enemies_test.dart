import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

FlightSimulation _arena({
  int version = FlightSimulation.currentRulesVersion,
  FlightCourse course = FlightCourse.starTrail,
  GameMode? rules,
}) {
  final sim = FlightSimulation(
    rules: rules ?? TapFlyMode(rulesVersion: version),
    practice: true,
    course: course,
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

void _step(FlightSimulation sim, double dt, {double width = 2.2}) {
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

void _hover(FlightSimulation sim, double seconds) {
  for (var i = 0; i < (seconds * 100).round(); i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    _step(sim, .01);
  }
}

EnemyAmmo _pellet(double x, double y) =>
    EnemyAmmo(x: x, y: y, vx: -.44, vy: 0, attack: EnemyAttack.aimed);

void main() {
  test('flight arcs stay small and hits follow the moving body', () {
    for (var kind = 0; kind < 4; kind++) {
      final moving = SkyEnemy(x: 1, y: .5, appearance: kind, flightPhase: .2);
      final legacy = SkyEnemy(x: 1, y: .5, appearance: kind);
      final heights = <double>[];
      for (var frame = 0; frame < 300; frame++) {
        moving.age = legacy.age = frame / 30;
        heights.add(moving.y);
        expect((moving.y - .5).abs(), lessThanOrEqualTo(.014));
        expect(moving.flightBank.abs(), lessThanOrEqualTo(.07));
        expect(legacy.y, .5);
        expect(legacy.flightBank, 0);
      }
      expect(
        heights.reduce(math.max) - heights.reduce(math.min),
        greaterThan(.01),
      );
    }
    final sim = _arena();
    final bat = SkyEnemy(x: 1.5, y: .5, appearance: 3, flightPhase: .48);
    expect(bat.y, greaterThan(.51));
    sim.enemies.add(bat);
    // This rock is outside the old stationary hit circle but inside the bobbed one.
    sim.rocks.add(BirdRock(x: 1.5, y: .566));
    _step(sim, .001);
    expect(sim.enemiesDefeated, 1);
    expect(sim.enemies, isEmpty);
  });

  test('simple bat is harmless at range; shooters have distinct volleys', () {
    for (var kind = 0; kind < 4; kind++) {
      final sim = _arena();
      final enemy = SkyEnemy(x: 1.95, y: .5, appearance: kind);
      sim.enemies.add(enemy);
      _hover(sim, .5);
      expect(sim.enemyAmmo, isEmpty);
      final shoots = enemy.attack != EnemyAttack.none;
      if (shoots) expect(enemy.charge, greaterThan(0));
      _hover(sim, .62);
      expect(sim.enemyAmmo.length, [0, 1, 3, 0][kind]);
      expect(enemy.volleys, shoots ? 1 : 0);
      if (!shoots) continue;
      expect(enemy.recoil, greaterThan(.8));
      for (final ammo in sim.enemyAmmo) {
        expect(ammo.vx, lessThan(0));
        expect(
          math.sqrt(ammo.vx * ammo.vx + ammo.vy * ammo.vy),
          closeTo(kind == 1 ? .44 : .34, 1e-10),
        );
      }
      if (kind == 1) {
        expect(sim.enemyAmmo.single.vy.abs(), lessThan(.001));
      } else {
        expect(sim.enemyAmmo.any((a) => a.vy > .09), isTrue);
        expect(sim.enemyAmmo.any((a) => a.vy < -.09), isTrue);
      }
    }
  });

  test('aimed shot locks direction on firing rather than following bird', () {
    final sim = _arena();
    final enemy = SkyEnemy(x: 1.7, y: .3, appearance: 1)..fireIn = 0;
    sim.enemies.add(enemy);
    _step(sim, .01);
    final ammo = sim.enemyAmmo.single;
    expect(ammo.vy, greaterThan(0));
    final vx = ammo.vx, vy = ammo.vy, x = ammo.x, y = ammo.y;
    sim.birdY = .1;
    sim.velocity = 0;
    _step(sim, .1);
    expect(ammo.vx, vx);
    expect(ammo.vy, vy);
    expect(ammo.x, closeTo(x + vx * .1, 1e-10));
    expect(ammo.y, closeTo(y + vy * .1, 1e-10));
  });

  test('no offscreen, passed, close-range or posthumous shots', () {
    for (final x in [2.4, .2, .8]) {
      final sim = _arena();
      final enemy = SkyEnemy(x: x, y: .2, appearance: 2)..fireIn = 0;
      sim.enemies.add(enemy);
      _hover(sim, .2);
      expect(sim.enemyAmmo, isEmpty, reason: 'enemy at $x');
      expect(enemy.charge, 0);
      expect(enemy.fireIn, greaterThanOrEqualTo(SkyEnemy.warningSeconds));
    }
    final sim = _arena();
    sim.enemies.add(SkyEnemy(x: 1.7, y: .5, appearance: 2)..fireIn = 0);
    sim.rocks.add(BirdRock(x: 1.68, y: .5, damage: 30));
    _step(sim, .02);
    expect(sim.enemies, isEmpty);
    expect(sim.enemyAmmo, isEmpty);
  });

  test('rocks intercept pellets and buildings block enemy fire', () {
    final sim = _arena();
    sim.enemyAmmo.add(_pellet(1, .5));
    sim.rocks.add(BirdRock(x: .98, y: .5));
    _step(sim, .02);
    expect(sim.enemyAmmo, isEmpty);
    expect(sim.rocks, isEmpty);
    expect(sim.enemiesDefeated, 0);
    sim.obstacles.add(Obstacle(x: 1.2, center: .7, gap: .3));
    sim.enemyAmmo.add(_pellet(1.22, .2));
    _step(sim, .02);
    expect(sim.enemyAmmo, isEmpty);
  });

  test('pellets follow shield, heart, courier and classic collision rules', () {
    final trail = _arena();
    trail.enemyAmmo.add(_pellet(FlightSimulation.birdX, .5));
    _step(trail, .01);
    expect(trail.shield, isFalse);
    expect(trail.hearts, 3);
    trail.enemyAmmo.add(_pellet(FlightSimulation.birdX, trail.birdY));
    _step(trail, .01);
    expect(trail.hearts, 3);
    trail.invulnerableUntil = 0;
    trail.enemyAmmo.add(_pellet(FlightSimulation.birdX, trail.birdY));
    _step(trail, .01);
    expect(trail.hearts, 2);
    final courier = _arena(course: FlightCourse.skyCourier)
      ..carryingLetter = true;
    courier.enemyAmmo.add(_pellet(FlightSimulation.birdX, .5));
    _step(courier, .01);
    expect(courier.lettersDropped, 1);
    expect(courier.phase, RunPhase.playing);
    final classic = _arena(course: FlightCourse.classic);
    classic.enemyAmmo.add(_pellet(FlightSimulation.birdX, .5));
    _step(classic, .01);
    expect(classic.endReason, EndReason.collision);
  });

  test('pause and countdown freeze attacks; boss transitions clear ammo', () {
    final sim = _arena();
    final enemy = SkyEnemy(x: 1.9, y: .3, appearance: 1, flightPhase: .6);
    sim.enemies.add(enemy);
    sim.enemyAmmo.add(_pellet(1.4, .7));
    final before = _snapshot(sim);
    for (final phase in [RunPhase.paused, RunPhase.countdown, RunPhase.ended]) {
      sim.phase = phase;
      sim.countdown = 2;
      _step(sim, .1);
      expect(_snapshot(sim), before);
    }
    sim.phase = RunPhase.playing;
    sim.elapsed = FlightSimulation.bossInterval - .001;
    _step(sim, .02);
    expect(sim.bossCutscene, isTrue);
    expect(sim.enemyAmmo, isEmpty);
    expect(sim.enemies, isEmpty);
    final boss = sim.boss!..age = 5;
    _step(sim, .01);
    boss.hp = 1;
    sim.enemyAmmo.add(_pellet(1.1, .2));
    sim.rocks.add(BirdRock(x: boss.x - .08, y: boss.y));
    _step(sim, .02);
    expect(sim.boss!.phase, BossPhase.defeated);
    expect(sim.enemyAmmo, isEmpty);
  });

  test('legacy journals and non-touch courses never gain enemy attacks', () {
    for (final version in [15, 16, 17, 18]) {
      for (final course in FlightCourse.values) {
        for (final rules in [TapFlyMode(), JumpFlyMode()]) {
          final sim = _arena(version: version, course: course, rules: rules);
          sim.enemies.add(SkyEnemy(x: 1.95, y: .3, appearance: 2));
          _hover(sim, 1.15);
          expect(
            sim.enemyAmmo.isNotEmpty,
            version >= 18 && !course.relaxed && rules.mode == PlayMode.touch,
          );
        }
      }
    }
  });

  test(
    'boss summons can complete their windup on a small landscape screen',
    () {
      for (final kind in [1, 2]) {
        final sim = _arena()
          ..elapsed = 50
          ..boss = (SkyBoss(number: 1, x: 1.05, cinematic: true)
            ..age = 6
            ..summons = kind
            ..summonIn = 0
            ..fireIn = 20);
        final attacks = <EnemyAttack>{};
        // Include travel from the screen edge before the visible windup starts.
        for (var frame = 0; frame < 200; frame++) {
          sim.birdY = .5;
          sim.velocity = 0;
          _step(sim, .01, width: 640 / 360);
          attacks.addAll(sim.enemyAmmo.map((a) => a.attack));
        }
        expect(attacks, {EnemyAttack.values[kind]});
      }
    },
  );

  test(
    'active enemy attacks reproduce exactly through backward replay seeks',
    () {
      var now = 0.0;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.touch,
          course: FlightCourse.skyCourier,
          practice: true,
          seed: 7,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: false,
          originMs: 0,
        ),
        () => now,
      );
      final snapshots = <double, Object>{};
      final kinds = <EnemyAttack>{};
      for (var frame = 0; frame < 1850; frame++) {
        now += 20;
        final sim = recorder.simulation;
        final ahead = sim.obstacles.where(
          (o) => o.x + o.width > FlightSimulation.birdX,
        );
        final target = ahead.isEmpty ? .5 : ahead.first.target;
        recorder.apply(
          MovementInput(
            valid: true,
            flap: sim.birdY > target + .06 && sim.velocity > 0,
          ),
          TrackingSample(
            mode: PlayMode.touch,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        recorder.tick(.02, now, 2.2);
        for (final ammo in sim.enemyAmmo) {
          if (kinds.add(ammo.attack)) snapshots[now] = _snapshot(sim);
        }
      }
      expect(kinds, {EnemyAttack.aimed, EnemyAttack.fan});
      final replay = ReplayPlayer(ReplayTape.fromJson(recorder.tape.toJson()));
      for (final at in [
        ...snapshots.keys.toList().reversed,
        ...snapshots.keys,
      ]) {
        replay.seek(at);
        expect(_snapshot(replay.simulation), snapshots[at]);
      }
    },
  );
}

Object _snapshot(FlightSimulation sim) => [
  sim.enemies
      .map(
        (e) => [
          e.x,
          e.y,
          e.appearance,
          e.age,
          e.fireIn,
          e.lastShotAt,
          e.volleys,
          e.preparing,
        ],
      )
      .toList(),
  sim.enemyAmmo.map((a) => [a.x, a.y, a.vx, a.vy, a.attack]).toList(),
];
