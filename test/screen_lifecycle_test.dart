import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';

void _step(FlightSimulation sim, double dt, double width) {
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

void main() {
  testWidgets('missed stars remain drawn until they scroll offscreen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sim = FlightSimulation(
      rules: TapFlyMode(),
      practice: true,
      course: FlightCourse.starTrail,
    );
    _step(sim, 3, 800 / 360);
    sim.obstacles.clear();
    sim.enemies.clear();
    sim.stars.clear();
    sim.starTrios.clear();
    final star = SkyStar(x: .25, y: .2);
    sim.stars.add(star);
    _step(sim, .01, 800 / 360);
    expect(star.missed, isTrue);
    expect(sim.stars, contains(star));
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: true,
      onChanged: () {},
      playback: true,
      transparent: true,
    );
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() async {
      await game.loaded;
      game.pauseEngine();
      Future<List<int>> render() async {
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        return bytes;
      }

      final missed = await render();
      star.missed = false;
      final uncollected = await render();
      expect(missed, uncollected, reason: 'Passing a star must not hide it');
      star.collected = true;
      expect(await render(), isNot(equals(uncollected)));
    });
    await tester.pumpWidget(const SizedBox());
  });

  test('missed stars scroll offscreen without repeatedly breaking streaks', () {
    final sim = FlightSimulation(
      rules: TapFlyMode(),
      practice: true,
      course: FlightCourse.starTrail,
    );
    _step(sim, 3, 2.2);
    sim.stars.clear();
    sim.combo = 6;
    final missed = SkyStar(x: .25, y: .2);
    sim.stars.add(missed);
    _step(sim, .01, 2.2);
    expect(missed.missed, isTrue);
    expect(sim.combo, 0);
    sim.stars.add(SkyStar(x: FlightSimulation.birdX, y: sim.birdY));
    _step(sim, .01, 2.2);
    expect(sim.combo, 1);
    for (var frame = 0; frame < 100; frame++) {
      final previousX = missed.x;
      sim.birdY = .5;
      sim.velocity = 0;
      _step(sim, .01, 2.2);
      if (sim.stars.contains(missed)) {
        expect(missed.x, lessThan(previousX));
      } else {
        expect(missed.x + SkyStar.radius, lessThan(0));
      }
      expect(sim.combo, 1);
      expect(sim.score, 1);
    }
    expect(sim.stars, isNot(contains(missed)));
  });

  test('older replays keep their original enemy entry positions', () {
    final sim = FlightSimulation(
      rules: TapFlyMode(rulesVersion: 24),
      rulesVersion: 24,
      practice: true,
    );
    _step(sim, 3, 2.2);
    expect(sim.obstacles.single.x, closeTo(2.3, 1e-10));
    expect(sim.enemies.single.x, closeTo(1.75, 1e-10));
    sim.enemies.clear();
    sim.boss = SkyBoss(number: 1, x: 1, cinematic: true)
      ..age = 6
      ..summonIn = 0;
    _step(sim, .01, 2.2);
    expect(sim.enemies.single.x, closeTo(1.3159999067146453, 1e-10));
  });

  for (final width in [1.4, 2.2, 2.8]) {
    test('ordinary enemies enter from the right edge at width $width', () {
      final sim = FlightSimulation(
        rules: TapFlyMode(),
        practice: true,
        course: FlightCourse.starTrail,
        random: math.Random(7),
      )..invulnerableUntil = double.infinity;
      final seen = <SkyEnemy>{};
      void checkNewEnemies() {
        for (final enemy in sim.enemies.where((e) => !seen.contains(e))) {
          expect(
            enemy.x,
            greaterThanOrEqualTo(width + .12),
            reason: 'Enemy ${seen.length + 1} appeared inside the screen',
          );
          seen.add(enemy);
        }
      }

      _step(sim, 3, width);
      checkNewEnemies();
      for (var frame = 0; frame < 2000; frame++) {
        sim.birdY = .5;
        sim.velocity = 0;
        _step(sim, .01, width);
        checkNewEnemies();
      }
      expect(seen.length, greaterThanOrEqualTo(3));
    });

    test('boss helpers enter from the right edge at width $width', () {
      for (final kind in BossKind.values) {
        for (var summon = 0; summon < 3; summon++) {
          final sim = FlightSimulation(rules: TapFlyMode(), practice: true);
          _step(sim, 3, width);
          sim.enemies.clear();
          sim.obstacles.clear();
          sim.boss = SkyBoss(number: 1, x: 1, cinematic: true, kind: kind)
            ..age = 6
            ..summons = summon
            ..summonIn = 0;
          _step(sim, .01, width);
          expect(sim.enemies.single.x, greaterThanOrEqualTo(width + .12));
        }
      }
    });
  }
}
