import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/enemy_design.dart';
import 'package:push_up_bird/game/obstacle_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const extent = 220;

  Future<Uint8List> raster(void Function(Canvas canvas) draw) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(extent, extent);
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
    return bytes;
  }

  int differingPixels(Uint8List a, Uint8List b) {
    expect(a.length, b.length);
    var count = 0;
    for (var i = 0; i < a.length; i += 4) {
      if (a[i] != b[i] ||
          a[i + 1] != b[i + 1] ||
          a[i + 2] != b[i + 2] ||
          a[i + 3] != b[i + 3]) {
        count++;
      }
    }
    return count;
  }

  Obstacle garden(int appearance) => Obstacle(
    x: .28,
    center: .5,
    gap: .34,
    kind: ObstacleKind.garden,
    appearance: appearance,
  );

  Future<Uint8List> paintGarden(
    int appearance, {
    required bool structures,
    required double seconds,
    required bool reducedMotion,
  }) {
    return raster(
      (canvas) => ObstacleArt.paint(
        canvas,
        garden(appearance),
        extent.toDouble(),
        seconds: seconds,
        reducedMotion: reducedMotion,
        cleared: false,
        perfect: false,
        refined: true,
        gardenStructures: structures,
      ),
    );
  }

  Future<Uint8List> paintEnemy(
    int version,
    int appearance, {
    required double seconds,
    required bool reducedMotion,
  }) {
    final sim = FlightSimulation(
      rules: TapFlyMode(rulesVersion: version),
      practice: true,
      course: FlightCourse.starTrail,
      rulesVersion: version,
      random: Random(1),
    )..elapsed = seconds;
    sim.enemies.add(SkyEnemy(x: .5, y: .5, appearance: appearance));
    return raster(
      (canvas) => CombatArt.paint(
        canvas,
        extent.toDouble(),
        sim,
        reducedMotion: reducedMotion,
      ),
    );
  }

  test('version 16 garden and enemy pixels differ from version 14', () async {
    for (var appearance = 0; appearance < 3; appearance++) {
      final latest = await paintGarden(
        appearance,
        structures: true,
        seconds: 5,
        reducedMotion: true,
      );
      final version14 = await paintGarden(
        appearance,
        structures: false,
        seconds: 5,
        reducedMotion: true,
      );
      expect(
        differingPixels(latest, version14),
        greaterThan(24),
        reason: 'garden appearance $appearance',
      );
      final enemy = await paintEnemy(
        16,
        appearance,
        seconds: 5,
        reducedMotion: true,
      );
      final oldEnemy = await paintEnemy(
        14,
        appearance,
        seconds: 5,
        reducedMotion: true,
      );
      expect(
        differingPixels(enemy, oldEnemy),
        greaterThan(24),
        reason: 'enemy appearance $appearance',
      );
    }
  });

  test(
    'enemy appearances differ, stay centered, and repeat under Reduced Motion',
    () async {
      const radius = 70.0;
      final origin = extent / 2;

      Future<Uint8List> character(
        int appearance, {
        required double seconds,
        required bool reducedMotion,
      }) {
        return raster((canvas) {
          canvas.translate(origin, origin);
          EnemyDesign.paint(
            canvas,
            radius,
            appearance: appearance,
            seconds: seconds,
            reducedMotion: reducedMotion,
          );
        });
      }

      final frames = [
        for (var appearance = 0; appearance < 3; appearance++)
          await character(appearance, seconds: 5, reducedMotion: true),
      ];
      for (var i = 0; i < 3; i++) {
        expect(
          differingPixels(frames[i], frames[(i + 1) % 3]),
          greaterThan(24),
          reason: 'appearance $i',
        );
        expectCenteredBody(frames[i], extent, radius);
        final repeat = await character(i, seconds: 5, reducedMotion: true);
        final later = await character(i, seconds: 9, reducedMotion: true);
        expect(differingPixels(frames[i], repeat), 0, reason: 'repeat $i');
        expect(differingPixels(frames[i], later), 0, reason: 'reduced $i');
      }
    },
  );

  test(
    'garden structures repeat and match at 5s and 9s under Reduced Motion',
    () async {
      final first = await paintGarden(
        1,
        structures: true,
        seconds: 5,
        reducedMotion: true,
      );
      final repeat = await paintGarden(
        1,
        structures: true,
        seconds: 5,
        reducedMotion: true,
      );
      final later = await paintGarden(
        1,
        structures: true,
        seconds: 9,
        reducedMotion: true,
      );
      expect(differingPixels(first, repeat), 0);
      expect(differingPixels(first, later), 0);
    },
  );

  test('fresh touch flights rotate enemy and opening appearances', () {
    final first = _freshAppearances();
    final second = _freshAppearances();
    expect(first.obstacles.take(3).toList(), [0, 1, 2]);
    expect(first.obstacles.take(3).toSet().length, 3);
    expect(first.enemies.take(4).toList(), [3, 1, 2, 0]);
    expect(first.enemies, second.enemies);
    expect(first.obstacles, second.obstacles);
  });

  test('version 15 and 16 share physics aside from opening decoration', () {
    final older = _simulation(15);
    final newer = _simulation(16);
    final seenOlder = <Obstacle>{};
    final seenNewer = <Obstacle>{};
    final seenEnemiesOlder = <SkyEnemy>{};
    final seenEnemiesNewer = <SkyEnemy>{};
    final obstacles15 = <int>[];
    final obstacles16 = <int>[];
    final enemies15 = <int>[];
    final enemies16 = <int>[];
    final openingBorn = <double>[];
    var now = 0.0;
    var sawEight = false;
    var sawBoss = false;

    for (var frame = 0; frame < 3200; frame++) {
      now += 20;
      final upcoming = older.obstacles.where(
        (o) => o.x + o.width > FlightSimulation.birdX,
      );
      final target = upcoming.isEmpty ? .5 : upcoming.first.target;
      final flap = older.birdY > target + .06 && older.velocity > 0;
      final shoot = older.canShoot;
      _drive(older, now, flap: flap, shoot: shoot);
      _drive(newer, now, flap: flap, shoot: shoot);
      _collect(older, seenOlder, obstacles15, openingBorn);
      _collect(newer, seenNewer, obstacles16, null);
      _collectEnemies(older, seenEnemiesOlder, enemies15);
      _collectEnemies(newer, seenEnemiesNewer, enemies16);
      if (!sawEight && older.elapsed >= 8) {
        sawEight = true;
        _expectPhysics(older, newer, openingBorn);
      }
      if (!sawBoss && older.boss != null) {
        sawBoss = true;
        _expectPhysics(older, newer, openingBorn);
      }
      if (older.phase == RunPhase.ended && newer.phase == RunPhase.ended) {
        break;
      }
    }

    expect(sawEight, isTrue);
    expect(obstacles16.take(3).toList(), [0, 1, 2]);
    expect(obstacles16.skip(3).toList(), obstacles15.skip(3).toList());
    expect(enemies16.take(3).toList(), [0, 1, 2]);
    expect(enemies15, everyElement(0));
    expect(enemies16, isNot(equals(enemies15)));
    expect(older.elapsed, greaterThan(45));
    expect(sawBoss, isTrue, reason: '${older.endReason} at ${older.elapsed}');
    _expectPhysics(older, newer, openingBorn);
    expect(older.phase, newer.phase);
    expect(older.boss != null || older.bossesDefeated > 0, isTrue);
  });
}

void expectCenteredBody(Uint8List bytes, int extent, double radius) {
  final cx = extent ~/ 2;
  final cy = extent ~/ 2;
  expect(bytes[(cy * extent + cx) * 4 + 3], 255);
  for (final step in const [
    Offset(.4, 0),
    Offset(-.4, 0),
    Offset(0, .4),
    Offset(0, -.4),
  ]) {
    final x = cx + (step.dx * radius).round();
    final y = cy + (step.dy * radius).round();
    expect(bytes[(y * extent + x) * 4 + 3], 255);
  }
  var minX = extent, minY = extent, maxX = 0, maxY = 0, count = 0;
  final limit = radius * .75;
  for (var y = 0; y < extent; y++) {
    for (var x = 0; x < extent; x++) {
      final dx = x + .5 - cx - .5;
      final dy = y + .5 - cy - .5;
      if (dx * dx + dy * dy > limit * limit) continue;
      if (bytes[(y * extent + x) * 4 + 3] < 250) continue;
      count++;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  expect(count, greaterThan(40));
  expect(((minX + maxX) / 2 - cx).abs(), lessThan(2));
  expect(((minY + maxY) / 2 - cy).abs(), lessThan(2));
}

final class _Appearances {
  const _Appearances(this.obstacles, this.enemies);
  final List<int> obstacles, enemies;
}

_Appearances _freshAppearances() {
  var now = 0.0;
  final recorder = FlightRecorder(
    ReplayTape(
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      practice: false,
      seed: 4,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: false,
      originMs: 0,
    ),
    () => now,
  );
  final sim = recorder.simulation;
  final obstacles = <int>[];
  final enemies = <int>[];
  final seenObstacles = <Obstacle>{};
  final seenEnemies = <SkyEnemy>{};
  for (var i = 0; i < 900 && sim.phase != RunPhase.ended; i++) {
    now += 20;
    final upcoming = sim.obstacles.where(
      (o) => o.x + o.width > FlightSimulation.birdX,
    );
    final target = upcoming.isEmpty ? .5 : upcoming.first.target;
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
    if (sim.canShoot) recorder.command('shoot');
    recorder.tick(.02, now, 2.2);
    for (final obstacle in sim.obstacles) {
      if (seenObstacles.add(obstacle)) obstacles.add(obstacle.appearance);
    }
    for (final enemy in sim.enemies) {
      if (seenEnemies.add(enemy)) enemies.add(enemy.appearance);
    }
    if (obstacles.length >= 3 && enemies.length >= 4 && sim.elapsed > 12) {
      break;
    }
  }
  expect(sim.phase, RunPhase.playing, reason: '${sim.endReason}');
  return _Appearances(obstacles, enemies);
}

FlightSimulation _simulation(int version) {
  return FlightSimulation(
    rules: TapFlyMode(rulesVersion: version),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: version,
    random: Random(4),
  );
}

void _drive(
  FlightSimulation sim,
  double now, {
  required bool flap,
  required bool shoot,
}) {
  sim.apply(
    MovementInput(valid: true, flap: flap),
    TrackingSample(
      mode: PlayMode.touch,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  if (shoot) sim.shoot();
  sim.tick(.02, now, viewportWidth: 2.2);
}

void _collect(
  FlightSimulation sim,
  Set<Obstacle> seen,
  List<int> appearances,
  List<double>? openingBorn,
) {
  for (final obstacle in sim.obstacles) {
    if (!seen.add(obstacle)) continue;
    appearances.add(obstacle.appearance);
    if (openingBorn != null && openingBorn.length < 3) {
      openingBorn.add(obstacle.bornAt);
    }
  }
}

void _collectEnemies(
  FlightSimulation sim,
  Set<SkyEnemy> seen,
  List<int> appearances,
) {
  for (final enemy in sim.enemies) {
    if (seen.add(enemy)) appearances.add(enemy.appearance);
  }
}

void _expectPhysics(
  FlightSimulation older,
  FlightSimulation newer,
  List<double> openingBorn,
) {
  expect(newer.phase, older.phase);
  expect(newer.endReason, older.endReason);
  expect(newer.score, older.score);
  expect(newer.speed, older.speed);
  expect(newer.birdY, older.birdY);
  expect(newer.velocity, older.velocity);
  expect(newer.distance, older.distance);
  expect(newer.elapsed, older.elapsed);
  expect(newer.gates, older.gates);
  expect(newer.hearts, older.hearts);
  expect(newer.shield, older.shield);
  expect(newer.shots, older.shots);
  expect(newer.enemiesDefeated, older.enemiesDefeated);
  expect(newer.bossesDefeated, older.bossesDefeated);
  bool opening(Obstacle obstacle) =>
      openingBorn.any((born) => born == obstacle.bornAt);
  expect(
    newer.obstacles
        .map(
          (o) => [
            o.kind,
            o.x,
            o.center,
            o.gap,
            o.target,
            o.width,
            o.amplitude,
            o.phaseOffset,
            o.period,
            o.motion,
            o.angle,
            for (final passage in o.passages)
              (passage.x, passage.width, passage.center, passage.gap),
            for (final orb in o.orbs) (orb.x, orb.y, orb.radius),
            opening(o) ? null : o.appearance,
          ],
        )
        .toList(),
    older.obstacles
        .map(
          (o) => [
            o.kind,
            o.x,
            o.center,
            o.gap,
            o.target,
            o.width,
            o.amplitude,
            o.phaseOffset,
            o.period,
            o.motion,
            o.angle,
            for (final passage in o.passages)
              (passage.x, passage.width, passage.center, passage.gap),
            for (final orb in o.orbs) (orb.x, orb.y, orb.radius),
            opening(o) ? null : o.appearance,
          ],
        )
        .toList(),
  );
  expect(
    newer.enemies.map((e) => (e.x, e.y)).toList(),
    older.enemies.map((e) => (e.x, e.y)).toList(),
  );
  expect(
    newer.rocks.map((r) => (r.x, r.y)).toList(),
    older.rocks.map((r) => (r.x, r.y)).toList(),
  );
  expect(
    newer.stars.map((s) => (s.x, s.y, s.collected)).toList(),
    older.stars.map((s) => (s.x, s.y, s.collected)).toList(),
  );
  expect(_bossView(newer), _bossView(older));
  expect(
    newer.bossAmmo.map((a) => (a.x, a.y, a.vx, a.vy)).toList(),
    older.bossAmmo.map((a) => (a.x, a.y, a.vx, a.vy)).toList(),
  );
}

List<Object?> _bossView(FlightSimulation sim) {
  final boss = sim.boss;
  if (boss == null) return const [null];
  return [
    boss.phase,
    boss.number,
    boss.hp,
    boss.x,
    boss.y,
    boss.age,
    boss.fireIn,
    boss.summonIn,
    boss.volleys,
    boss.summons,
    boss.defeatedAt,
  ];
}
