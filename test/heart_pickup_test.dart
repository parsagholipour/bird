import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'boss_fight_test.dart' show step, hover, hitBoss, snapshot;

FlightSimulation flight({int seed = 4, int version = 24}) =>
    FlightSimulation(
        rules: TapFlyMode(rulesVersion: version),
        practice: true,
        course: FlightCourse.starTrail,
        rulesVersion: version,
        random: Random(seed),
      )
      ..phase = RunPhase.playing
      ..started = true
      ..invulnerableUntil = double.infinity;

void defeat(FlightSimulation sim) {
  if (sim.boss == null) {
    sim.elapsed = FlightSimulation.bossInterval;
    step(sim);
  }
  final boss = sim.boss!;
  hover(sim, boss.arrivalDuration + .02);
  hitBoss(sim, count: boss.maxHp);
  expect(boss.phase, BossPhase.defeated);
  expect(sim.heartPickups, isEmpty);
  hover(sim, boss.departureDuration + .02);
  expect(sim.boss, isNull);
}

void missPickups(FlightSimulation sim, {double width = 2.2}) {
  sim.birdY = .12;
  sim.velocity = 0;
  step(sim, .05, width);
}

void main() {
  test('no heart is granted before a victory or during its celebration', () {
    final sim = flight();
    while (sim.boss == null) {
      missPickups(sim);
      expect(sim.heartPickups, isEmpty);
    }
    defeat(sim);
    expect(sim.hearts, 3);
    expect(sim.heartPickups, isEmpty);
  });

  test(
    'each defeated boss leaves one random reachable heart before the next',
    () {
      final locations = <int>{};
      for (final width in [640 / 360, 800 / 360]) {
        for (var seed = 0; seed < 8; seed++) {
          final sim = flight(seed: seed);
          for (var encounter = 1; encounter <= 3; encounter++) {
            defeat(sim);
            final seen = <SkyHeart>{};
            final passages = <Obstacle>{...sim.obstacles};
            var passedBird = false;
            while (sim.boss == null) {
              missPickups(sim, width: width);
              passages.addAll(sim.obstacles);
              for (final heart in sim.heartPickups) {
                if (seen.add(heart)) locations.add(passages.length);
                expect(heart.y, heart.passage!.target);
                expect(
                  heart.x,
                  closeTo(heart.passage!.x + heart.passage!.width / 2, .005),
                );
                passedBird |= heart.x < FlightSimulation.birdX;
              }
            }
            expect(seen, hasLength(1));
            expect(passedBird, isTrue);
            expect(sim.heartPickups, isEmpty);
            expect(sim.bossesDefeated, encounter);
            expect(sim.hearts, 3, reason: 'Missing a heart grants no life');
          }
        }
      }
      expect(locations.length, greaterThan(1));
      expect(locations.every((gate) => gate >= 2 && gate <= 7), isTrue);
    },
  );

  test('collecting a heart grants exactly one life, including above three', () {
    for (final lives in [1, 2, 3, 4]) {
      final sim = flight()
        ..hearts = lives
        ..shield = false;
      sim.heartPickups.add(SkyHeart(x: .55, y: .5));
      step(sim, .2);
      expect(sim.hearts, lives + 1);
      expect(sim.heartPickups, isEmpty);
      expect(sim.shield, isFalse);
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.heart),
        hasLength(1),
      );
      hover(sim, 1);
      expect(sim.hearts, lives + 1);
    }
  });

  test('heart pickups stop at five lives without false reward feedback', () {
    final sim = flight()..hearts = 4;
    sim.heartPickups.addAll([SkyHeart(x: .55, y: .5), SkyHeart(x: .55, y: .5)]);
    step(sim, .2);
    expect(sim.hearts, 5);
    expect(sim.heartPickups, isEmpty);
    expect(
      sim.events.where((e) => e.kind == FlightEventKind.heart),
      hasLength(1),
    );
    sim.events.clear();
    sim.heartPickups.add(SkyHeart(x: FlightSimulation.birdX, y: sim.birdY));
    step(sim);
    expect(sim.hearts, 5);
    expect(sim.heartPickups, isEmpty);
    expect(sim.events.where((e) => e.kind == FlightEventKind.heart), isEmpty);
  });

  test('the additional heart absorbs a later hit', () {
    final sim = flight()
      ..hearts = 1
      ..shield = false
      ..invulnerableUntil = 0;
    sim.heartPickups.add(SkyHeart(x: FlightSimulation.birdX, y: .5));
    step(sim);
    expect(sim.hearts, 2);
    sim.bossAmmo.add(
      BossAmmo(x: FlightSimulation.birdX, y: sim.birdY, vx: 0, vy: 0),
    );
    step(sim);
    expect(sim.hearts, 1);
    expect(sim.phase, RunPhase.playing);
  });

  test(
    'a missed heart leaves combos intact and is not attracted by the magnet',
    () {
      final sim = flight()
        ..combo = 7
        ..magnetUntil = 20;
      sim.heartPickups.add(SkyHeart(x: FlightSimulation.birdX, y: .65));
      step(sim);
      expect(sim.hearts, 3);
      for (var i = 0; i < 10; i++) {
        missPickups(sim);
      }
      expect(sim.heartPickups, isEmpty);
      expect(sim.combo, 7);
    },
  );

  test('pause, resume countdown and game over freeze heart pickups', () {
    for (final phase in [RunPhase.paused, RunPhase.countdown, RunPhase.ended]) {
      final sim = flight()..phase = phase;
      final heart = SkyHeart(x: FlightSimulation.birdX, y: .5);
      sim.heartPickups.add(heart);
      step(sim, .2);
      expect(sim.hearts, 3);
      expect(sim.heartPickups.single, heart);
      expect(heart.x, FlightSimulation.birdX);
    }
  });

  test('old replay versions never schedule the new reward', () {
    for (final version in [16, 22, 23]) {
      final sim = flight(version: version);
      defeat(sim);
      while (sim.boss == null) {
        missPickups(sim);
        expect(sim.heartPickups, isEmpty);
      }
      expect(sim.hearts, 3);
    }
  });

  test(
    'seeded flights reproduce the same reward and later random passages',
    () {
      final first = flight(seed: 81), second = flight(seed: 81);
      defeat(first);
      defeat(second);
      var sawHeart = false;
      while (first.boss == null) {
        missPickups(first);
        missPickups(second);
        sawHeart |= first.heartPickups.isNotEmpty;
        expect(snapshot(first), snapshot(second));
        expect(
          first.heartPickups.map((h) => [h.x, h.y]),
          second.heartPickups.map((h) => [h.x, h.y]),
        );
      }
      expect(sawHeart, isTrue);
    },
  );
}
