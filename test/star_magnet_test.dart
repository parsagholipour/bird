import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

class FlightHarness {
  FlightHarness({
    FlightCourse course = FlightCourse.starTrail,
    bool practice = false,
    int rulesVersion = FlightSimulation.currentRulesVersion,
  }) : sim =
           FlightSimulation(
               rules: PushUpFlightMode(cycleSeconds: 3),
               practice: practice,
               course: course,
               rulesVersion: rulesVersion,
               random: Random(7),
             )
             ..phase = RunPhase.playing
             ..started = true;
  final FlightSimulation sim;
  double now = 0;
  void step([double dt = .02]) {
    now += dt * 1000;
    sim.apply(
      const MovementInput(valid: true, height: .5),
      TrackingSample(
        mode: PlayMode.pushUp,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    sim.tick(dt, now);
  }

  void pass({bool perfect = true}) {
    sim.obstacles.clear();
    sim.obstacles.add(
      Obstacle(
        x: FlightSimulation.birdX - FlightSimulation.birdRadius - .141,
        center: .5,
        gap: .45,
      )..maxDeviation = perfect ? 0 : .12,
    );
    step();
  }

  void charge() {
    for (var i = 0; i < 3; i++) {
      pass();
    }
  }
}

void main() {
  test(
    'new push-up targets follow calibrated endpoints and old journals keep their geometry',
    () {
      for (final course in FlightCourse.values) {
        final modern = FlightSimulation(
          rules: PushUpFlightMode(cycleSeconds: 3),
          practice: false,
          course: course,
          random: Random(7),
        );
        final legacy = FlightSimulation(
          rules: PushUpFlightMode(cycleSeconds: 3),
          practice: false,
          course: course,
          random: Random(7),
          rulesVersion: 2,
        );
        for (var i = 0; i < 160; i++) {
          final now = (i + 1) * 20.0;
          for (final sim in [modern, legacy]) {
            sim.apply(
              const MovementInput(valid: true, height: 1),
              TrackingSample(
                mode: PlayMode.pushUp,
                timestampMs: now,
                receivedMs: now,
                joints: const [],
              ),
              now,
            );
            sim.tick(.02, now);
          }
        }
        final currentGate = modern.obstacles.first;
        final oldGate = legacy.obstacles.first;
        expect(currentGate.target, .15);
        expect(oldGate.target, oldGate.center);
        expect(currentGate.center, oldGate.center);
        expect(currentGate.gap, oldGate.gap);
        expect(currentGate.x, oldGate.x);
        expect(modern.birdY, closeTo(currentGate.target, 1e-10));
        if (course.collectsStars) {
          expect(modern.stars.first.y, currentGate.target);
          expect(legacy.stars.first.y, oldGate.center);
        }
      }
    },
  );

  test(
    'three perfect gates earn a magnet; other safe passes retain charge',
    () {
      final flight = FlightHarness();
      flight.pass();
      flight.pass(perfect: false);
      flight.pass();
      expect(flight.sim.magnetCharge, 2);
      expect(flight.sim.magnetActive, isFalse);
      flight.pass();
      expect(flight.sim.magnetCharge, 0);
      expect(flight.sim.magnetActivations, 1);
      expect(flight.sim.magnetRemaining, closeTo(8, .02));
      expect(
        flight.sim.events.where((e) => e.kind == FlightEventKind.magnet),
        hasLength(1),
      );
    },
  );

  test('the magnet catches nearby stars outside the ordinary pickup halo', () {
    final flight = FlightHarness()..charge();
    final nearby = SkyStar(x: FlightSimulation.birdX, y: .66);
    final far = SkyStar(x: FlightSimulation.birdX, y: .72);
    flight.sim.stars.addAll([nearby, far]);
    flight.step();
    expect(nearby.collected, isTrue);
    expect(far.collected, isFalse);
    expect(flight.sim.score, 1);
    flight.step();
    expect(flight.sim.score, 1, reason: 'A pulled star only scores once');

    final ordinary = FlightHarness();
    ordinary.sim.stars.add(SkyStar(x: FlightSimulation.birdX, y: .66));
    ordinary.step();
    expect(ordinary.sim.score, 0);
  });

  test('magnet expiry restores the normal halo and the charge can restart', () {
    final flight = FlightHarness()..charge();
    final ends = flight.sim.magnetUntil;
    for (var i = 0; i < 3; i++) {
      flight.pass();
    }
    expect(flight.sim.magnetUntil, ends, reason: 'Active magnets do not stack');
    expect(flight.sim.magnetCharge, 0);
    flight.sim.elapsed = ends - .01;
    flight.step(.02);
    expect(flight.sim.magnetActive, isFalse);
    expect(flight.sim.pickupRadius, .085);
    final star = SkyStar(x: FlightSimulation.birdX, y: .66);
    flight.sim.stars.add(star);
    flight.step();
    expect(star.collected, isFalse);
    flight.pass();
    expect(flight.sim.magnetCharge, 1);
  });

  test(
    'practice pause and resume countdown preserve remaining magnet time',
    () {
      final flight = FlightHarness(practice: true)..charge();
      final left = flight.sim.magnetRemaining;
      flight.sim.takeBreak();
      flight.step(.4);
      expect(flight.sim.magnetRemaining, left);
      flight.sim.resume();
      flight.step(.4);
      expect(flight.sim.phase, RunPhase.countdown);
      expect(flight.sim.magnetRemaining, left);
    },
  );

  test('a star magnet does not shield the bird from collisions', () {
    final flight = FlightHarness()..charge();
    flight.sim.shield = false;
    flight.sim.obstacles.add(
      Obstacle(x: FlightSimulation.birdX, center: .2, gap: .3),
    );
    flight.step();
    expect(flight.sim.hearts, 2);
    expect(flight.sim.magnetActive, isTrue);
  });

  test('Classic keeps its original perfect-pass behavior', () {
    final flight = FlightHarness(course: FlightCourse.classic)..charge();
    expect(flight.sim.score, 3);
    expect(flight.sim.perfectPasses, 3);
    expect(flight.sim.magnetActive, isFalse);
    expect(flight.sim.magnetCharge, 0);
  });

  test('Cloud Cruise earns magnets while remaining practice', () {
    final flight = FlightHarness(course: FlightCourse.cloudCruise)..charge();
    expect(flight.sim.magnetActive, isTrue);
    expect(flight.sim.practice, isTrue);
  });

  test(
    'version two journals retain their old rules even after serialization',
    () {
      final data = ReplayTape(
        mode: PlayMode.pushUp,
        practice: false,
        seed: 7,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
        course: FlightCourse.starTrail,
      ).toJson()..['version'] = 2;
      final legacy = ReplayTape.fromJson(data);
      final roundTrip = ReplayTape.fromJson(legacy.toJson());
      expect(roundTrip.recordedVersion, 2);
      expect(roundTrip.createSimulation().supportsMagnet, isFalse);
      final flight = FlightHarness(rulesVersion: roundTrip.recordedVersion)
        ..charge();
      expect(flight.sim.perfectPasses, 3);
      expect(flight.sim.magnetActivations, 0);
      flight.sim.stars.add(SkyStar(x: FlightSimulation.birdX, y: .66));
      flight.step();
      expect(flight.sim.score, 0);
    },
  );
}
