import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

void main() {
  test(
    'Cloud Cruise never crashes, has no time limit, and is always practice',
    () {
      final cruise = FlightSimulation(
        rules: JumpFlyMode(),
        practice: false,
        course: FlightCourse.cloudCruise,
        random: Random(4),
      );
      expect(cruise.practice, isTrue);
      for (var i = 0; i < 4000; i++) {
        final now = (i + 1) * 20.0;
        cruise.apply(
          const MovementInput(valid: true),
          TrackingSample(
            mode: PlayMode.jump,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        cruise.tick(.02, now);
      }
      expect(cruise.elapsed, greaterThan(60));
      expect(cruise.phase, RunPhase.playing);
      expect(cruise.hearts, 3);
      expect(cruise.stars, isNotEmpty);
      expect(
        cruise.birdY,
        inInclusiveRange(
          FlightSimulation.birdRadius,
          1 - FlightSimulation.birdRadius,
        ),
      );
      cruise.tick(.016, 81000);
      expect(
        cruise.phase,
        RunPhase.paused,
        reason: 'Losing tracking pauses a relaxed flight',
      );
      cruise.resume();
      expect(cruise.phase, RunPhase.countdown);
    },
  );

  late FlightSimulation sim;
  var now = 0.0;
  void tick([double dt = .016, double height = .5]) {
    now += dt * 1000;
    sim.apply(
      MovementInput(valid: true, height: height),
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

  void collect(int count) {
    for (var i = 0; i < count; i++) {
      sim.stars.add(SkyStar(x: FlightSimulation.birdX, y: .5));
      tick();
    }
  }

  void collide() {
    sim.obstacles.add(Obstacle(x: FlightSimulation.birdX, center: .2, gap: .3));
    tick();
  }

  setUp(() {
    now = 0;
    sim = FlightSimulation(
      rules: PushUpFlightMode(cycleSeconds: 3),
      practice: false,
      course: FlightCourse.starTrail,
      random: Random(3),
    );
    for (var i = 0; i < 190; i++) {
      tick();
    }
    expect(sim.started, isTrue);
    sim.obstacles.clear();
    sim.stars.clear();
  });

  test(
    'stars reward streaks, cap multiplier and cannot be collected twice',
    () {
      collect(5);
      expect(sim.score, 5);
      collect(1);
      expect(sim.multiplier, 2);
      expect(sim.score, 7);
      collect(6);
      expect(sim.multiplier, 3);
      expect(sim.bestCombo, 12);
      expect(sim.score, 20);
      tick();
      expect(sim.score, 20);
      expect(sim.collectedStars, 12);
      expect(
        sim.events
            .where((e) => e.kind == FlightEventKind.streak)
            .map((e) => e.value),
        [2, 3],
      );
    },
  );

  test(
    'missing a star resets the live streak but preserves the personal streak',
    () {
      collect(6);
      sim.stars.add(SkyStar(x: FlightSimulation.birdX - .1, y: .15));
      tick();
      expect(sim.combo, 0);
      expect(sim.multiplier, 1);
      expect(sim.bestCombo, 6);
    },
  );

  test('shield absorbs one collision; a gate cannot deal repeated damage', () {
    collide();
    expect(sim.hearts, 3);
    expect(sim.shield, isFalse);
    expect(sim.obstacles.single.hit, isTrue);
    for (var i = 0; i < 110; i++) {
      tick();
    }
    expect(sim.hearts, 3);
    expect(
      sim.gates,
      0,
      reason: 'A collided gate is not an earned unlock point',
    );
    expect(sim.phase, RunPhase.playing);
  });

  test('shield recharges after nine stars; collisions reset the combo', () {
    collect(5);
    collide();
    expect(sim.combo, 0);
    sim.obstacles.clear();
    collect(4);
    expect(sim.shield, isTrue);
    expect(sim.collectedStars, 9);
    expect(
      sim.events.any((e) => e.kind == FlightEventKind.shieldReady),
      isTrue,
    );
  });

  test('three unshielded hits end a trail and cannot score after death', () {
    sim.shield = false;
    for (var hit = 0; hit < 3; hit++) {
      sim.obstacles.clear();
      sim.invulnerableUntil = 0;
      collide();
    }
    expect(sim.hearts, 0);
    expect(sim.phase, RunPhase.ended);
    expect(sim.endReason, EndReason.collision);
    final score = sim.score;
    collect(3);
    expect(sim.score, score);
  });

  test('a trail continues beyond sixty seconds', () {
    sim.elapsed = 59.98;
    tick(.05);
    expect(sim.elapsed, greaterThan(60));
    expect(sim.remainingSeconds, 0);
    expect(sim.endReason, isNull);
  });

  test('endless trails never play a final stretch cue', () {
    sim.elapsed = 49.98;
    tick(.05);
    expect(
      sim.events.where((e) => e.kind == FlightEventKind.finalStretch),
      isEmpty,
    );
    tick(.05);
    expect(
      sim.events.where((e) => e.kind == FlightEventKind.finalStretch),
      isEmpty,
    );
  });

  test(
    'practice pauses the timer and resume requires tracking and countdown',
    () {
      sim =
          FlightSimulation(
              rules: PushUpFlightMode(cycleSeconds: 3),
              practice: true,
              course: FlightCourse.starTrail,
            )
            ..phase = RunPhase.playing
            ..started = true;
      tick();
      sim.takeBreak();
      final elapsed = sim.elapsed;
      tick(.4);
      expect(sim.elapsed, elapsed);
      sim.resume();
      expect(sim.phase, RunPhase.countdown);
      sim.tick(.1, now + 1000);
      expect(sim.countdown, 3);
    },
  );

  test(
    'trail still ends for stale tracking and keeps calibrated movement spacing',
    () {
      now += 600;
      sim.tick(.016, now);
      expect(sim.endReason, EndReason.trackingLost);
      for (final cycle in [1.0, 4.0, 9.0]) {
        final rules = PushUpFlightMode(cycleSeconds: cycle);
        final trail = FlightSimulation(
          rules: rules,
          practice: false,
          course: FlightCourse.starTrail,
        );
        final transitionWindow =
            trail.spawnInterval -
            (.14 + FlightSimulation.birdRadius + .42 - .085) / trail.speed;
        expect(
          transitionWindow,
          greaterThanOrEqualTo(cycle / 2),
          reason:
              'Stars must not require moving faster than the calibrated half-cycle',
        );
        expect(trail.gap, greaterThan(rules.gapFor(0)));
      }
    },
  );

  test(
    'classic perfect passes reward precision without changing score units',
    () {
      sim =
          FlightSimulation(
              rules: PushUpFlightMode(cycleSeconds: 3),
              practice: false,
            )
            ..phase = RunPhase.playing
            ..started = true;
      sim.obstacles.add(
        Obstacle(x: FlightSimulation.birdX - .19, center: .5, gap: .4),
      );
      tick();
      expect(sim.score, 1);
      expect(sim.gates, 1);
      expect(sim.perfectPasses, 1);
      expect(sim.collectedStars, 0);
    },
  );

  test('a full star trail is collectable at each calibrated movement pace', () {
    for (final cycle in [1.0, 4.0, 9.0]) {
      sim = FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: cycle),
        practice: false,
        course: FlightCourse.starTrail,
        random: Random(19),
      );
      now = 0;
      for (
        var frame = 0;
        frame < 3300 && sim.phase != RunPhase.ended;
        frame++
      ) {
        final ahead = sim.obstacles.where((o) => !o.scored);
        final target = ahead.isEmpty ? .5 : ahead.first.target;
        // Move through the full calibrated range no faster than half a cycle.
        final maxStep = .70 / (cycle / 2) * .02;
        final y = sim.birdY + (target - sim.birdY).clamp(-maxStep, maxStep);
        tick(.02, (.85 - y) / .70);
      }
      expect(sim.phase, RunPhase.playing, reason: '$cycle-second cycle');
      expect(sim.elapsed, greaterThan(60));
      expect(sim.hearts, 3);
      expect(sim.shield, isTrue);
      expect(sim.collectedStars, greaterThanOrEqualTo(12));
      expect(sim.perfectPasses, sim.gates);
      expect(sim.completedTrios, sim.collectedStars ~/ 3);
      expect(sim.magnetActivations, greaterThan(0));
      expect(
        sim.bestCombo,
        sim.collectedStars,
        reason:
            'Following passages at the calibrated pace should not miss stars',
      );
    }
  });

  test('new journals preserve course, stars, shields and backward seeking', () {
    final tape = ReplayTape(
      mode: PlayMode.pushUp,
      practice: false,
      seed: 42,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: true,
      originMs: 0,
      course: FlightCourse.starTrail,
    );
    var time = 0.0;
    final recorder = FlightRecorder(tape, () => time);
    for (var i = 0; i < 1600; i++) {
      time += 20;
      final game = recorder.simulation;
      final upcoming = game.obstacles.where(
        (o) =>
            o.x + o.width >=
            FlightSimulation.birdX - FlightSimulation.birdRadius,
      );
      final target = upcoming.isEmpty ? .5 : upcoming.first.target;
      recorder.apply(
        MovementInput(valid: true, height: (.85 - target) / .7),
        TrackingSample(
          mode: PlayMode.pushUp,
          timestampMs: time,
          receivedMs: time,
          joints: const [],
        ),
        time,
      );
      recorder.tick(.02, time, 2.2);
    }
    expect(recorder.simulation.collectedStars, greaterThan(0));
    expect(recorder.simulation.magnetActivations, greaterThan(0));
    final player = ReplayPlayer(ReplayTape.fromJson(tape.toJson()));
    player.seek(tape.durationMs);
    expect(player.simulation.score, recorder.simulation.score);
    expect(player.simulation.hearts, recorder.simulation.hearts);
    expect(player.simulation.shield, recorder.simulation.shield);
    expect(player.simulation.bestCombo, recorder.simulation.bestCombo);
    expect(player.simulation.gates, recorder.simulation.gates);
    expect(player.simulation.magnetUntil, recorder.simulation.magnetUntil);
    expect(player.simulation.magnetCharge, recorder.simulation.magnetCharge);
    player.seek(500);
    player.seek(tape.durationMs);
    expect(
      player.simulation.collectedStars,
      recorder.simulation.collectedStars,
    );
    expect(player.simulation.score, recorder.simulation.score);
    expect(
      player.simulation.magnetActivations,
      recorder.simulation.magnetActivations,
    );
    expect(
      player.simulation.magnetRemaining,
      recorder.simulation.magnetRemaining,
    );
  });

  test('version one recordings remain classic with their original seed', () {
    final json =
        ReplayTape(
            mode: PlayMode.jump,
            practice: false,
            seed: 9,
            cycleSeconds: 3,
            bird: 0,
            reducedMotion: true,
            originMs: 0,
          ).toJson()
          ..['version'] = 1
          ..remove('course');
    final tape = ReplayTape.fromJson(json);
    expect(tape.course, FlightCourse.classic);
    expect(tape.seed, 9);
    expect(tape.createSimulation().isTrail, isFalse);
  });
}
