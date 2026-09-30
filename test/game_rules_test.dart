import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

TrackingSample sample(double t, [PlayMode mode = PlayMode.pushUp]) =>
    TrackingSample(mode: mode, timestampMs: t, receivedMs: t, joints: []);
void main() {
  test('brief missed detections pause the countdown without restarting it', () {
    final game = FlightSimulation(
      rules: PushUpFlightMode(cycleSeconds: 3),
      practice: true,
    );
    for (var frame = 0; frame < 450; frame++) {
      final now = frame * 16.0;
      if (frame % 3 == 0) {
        game.apply(
          MovementInput(valid: frame % 21 != 0),
          sample(now - 150),
          now,
        );
      }
      game.tick(.016, now);
      if (game.started) break;
    }
    expect(game.started, isTrue);
  });
  test('stale packets still cannot start or move the bird', () {
    final game = FlightSimulation(
      rules: PushUpFlightMode(cycleSeconds: 3),
      practice: true,
    );
    for (var now = 0.0; now < 5000; now += 40) {
      game.apply(
        const MovementInput(valid: true, height: 1),
        sample(now - 210),
        now,
      );
      game.tick(.04, now);
    }
    expect(game.started, isFalse);
    expect(game.countdown, 3);
    expect(game.birdY, .5);
  });
  test(
    'countdown completes at the camera rate and latency observed on device',
    () {
      final game = FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: true,
      );
      // The camera screen reports ~21 Hz and 160 ms p95; a previously displayed
      // reading was 18 Hz / 184 ms. Every delivered packet is fresh on arrival.
      var nextArrival = 160.0;
      for (var now = 160.0; now < 5000; now += 8) {
        if (now >= nextArrival) {
          game.apply(
            const MovementInput(valid: true),
            sample(nextArrival - 160),
            now,
          );
          nextArrival += 50;
        }
        game.tick(.008, now);
      }
      expect(
        game.started,
        isTrue,
        reason: 'Countdown repeatedly reset to ${game.countdown}',
      );
    },
  );
  late FlightSimulation sim;
  late double now;
  void input({bool valid = true, double height = .5, int repetitions = 0}) =>
      sim.apply(
        MovementInput(valid: valid, height: height, repetitions: repetitions),
        sample(now),
        now,
      );
  void start({
    bool practice = false,
    int rulesVersion = FlightSimulation.currentRulesVersion,
  }) {
    sim = FlightSimulation(
      rules: PushUpFlightMode(cycleSeconds: 3),
      practice: practice,
      random: Random(1),
      rulesVersion: rulesVersion,
    );
    now = 0;
    for (var i = 0; i < 190; i++) {
      now += 16;
      input();
      sim.tick(.016, now);
    }
    expect(sim.phase, RunPhase.playing);
  }

  test(
    'countdown waits for tracking, pauses briefly and restarts after loss',
    () {
      sim = FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: false,
      );
      now = 0;
      sim.tick(.1, 100);
      expect(sim.countdown, 3);
      input();
      sim.tick(.1, 100);
      expect(sim.countdown, 2.9);
      sim.tick(.1, 300);
      expect(sim.countdown, 2.9);
      sim.tick(.1, 600);
      expect(sim.countdown, 3);
    },
  );
  test('alternating passages cannot be cleared by holding one height', () {
    final mode = PushUpFlightMode(cycleSeconds: 4);
    final high = mode.passageCenter(0, Random(0), .5),
        low = mode.passageCenter(1, Random(0), .5);
    expect(high + mode.gapFor(0) / 2, lessThan(low - mode.gapFor(0) / 2));
    for (var score = 0; score < 300; score++) {
      expect(mode.intervalFor(score), greaterThanOrEqualTo(2));
      expect(mode.gapFor(score), greaterThan(.25));
      expect(high - mode.gapFor(score) / 2, greaterThan(0));
      expect(low + mode.gapFor(score) / 2, lessThan(1));
    }
  });
  test(
    'short tracking glitches keep the simulation moving; >500ms ends run',
    () {
      start();
      final distance = sim.distance;
      for (var i = 0; i < 30; i++) {
        now += 16;
        sim.tick(.016, now);
      }
      expect(sim.phase, RunPhase.playing);
      expect(sim.distance, greaterThan(distance));
      now += 32;
      sim.tick(.032, now);
      expect(sim.phase, RunPhase.ended);
      expect(sim.endReason, EndReason.trackingLost);
    },
  );
  test('posture loss has the same bounded grace period', () {
    start();
    for (var i = 0; i < 33; i++) {
      now += 16;
      input(valid: false);
      sim.tick(.016, now);
    }
    expect(sim.endReason, EndReason.postureLost);
  });
  test(
    'collision ends a run and swept movement does not tunnel through obstacles',
    () {
      start();
      sim.obstacles.clear();
      sim.obstacles.add(
        Obstacle(
          x: FlightSimulation.birdX + .04,
          center: .25,
          gap: .3,
          width: .03,
        ),
      );
      now += 200;
      input(height: 0);
      sim.tick(.2, now);
      expect(sim.endReason, EndReason.collision);
    },
  );
  test(
    'each fully cleared obstacle scores once, separately from repetitions',
    () {
      start();
      sim.obstacles.clear();
      sim.obstacles.add(
        Obstacle(x: FlightSimulation.birdX - .22, center: .5, gap: .4),
      );
      now += 16;
      input(repetitions: 3);
      sim.tick(.016, now);
      expect(sim.score, 1);
      expect(sim.repetitions, 3);
      now += 16;
      input(repetitions: 3);
      sim.tick(.016, now);
      expect(sim.score, 1);
    },
  );
  test('rules before version 35 end a scored run on a break or background', () {
    start(rulesVersion: 34);
    sim.takeBreak();
    expect(sim.endReason, EndReason.breakTaken);
    start(rulesVersion: 34);
    sim.background();
    expect(sim.endReason, EndReason.backgrounded);
    start(rulesVersion: 34);
    sim.takeBreak();
    expect(sim.phase, RunPhase.ended);
    sim.resume();
    expect(sim.phase, RunPhase.ended);
  });
  for (final practice in [false, true]) {
    test(
      '${practice ? 'practice' : 'scored'} flights pause on a break or background and resume with a countdown',
      () {
        for (final leave in [() => sim.takeBreak(), () => sim.background()]) {
          start(practice: practice);
          final distance = sim.distance;
          final score = sim.score;
          leave();
          expect(sim.phase, RunPhase.paused);
          expect(sim.endReason, isNull);
          now += 1000;
          sim.tick(.016, now);
          expect(sim.distance, distance);
          expect(sim.score, score);
          sim.resume();
          expect(sim.phase, RunPhase.countdown);
          expect(sim.countdown, 3);
          sim.tick(.016, now);
          expect(sim.countdown, 3);
          for (var i = 0; i < 190 && sim.phase == RunPhase.countdown; i++) {
            now += 16;
            input();
            sim.tick(.016, now);
          }
          expect(sim.phase, RunPhase.playing);
          expect(sim.distance, greaterThanOrEqualTo(distance));
        }
      },
    );
  }
  test('a paused scored flight survives a background', () {
    start();
    sim.takeBreak();
    sim.background();
    expect(sim.phase, RunPhase.paused);
    sim.resume();
    expect(sim.phase, RunPhase.countdown);
  });
  test(
    'practice tracking loss pauses and simulation stalls cannot freeze scored time',
    () {
      start(practice: true);
      now += 510;
      sim.tick(.016, now);
      expect(sim.phase, RunPhase.paused);
      start();
      now += 600;
      sim.tick(.6, now);
      expect(sim.endReason, EndReason.stalled);
    },
  );
  test('wrong detector samples do not control the run', () {
    start();
    final before = sim.birdY;
    now += 16;
    sim.apply(
      const MovementInput(valid: true, height: 1),
      sample(now, PlayMode.jump),
      now,
    );
    expect(sim.birdY, before);
  });
  test('jump uses gravity and a flap impulse without counting push-ups', () {
    final game = FlightSimulation(rules: JumpFlyMode(), practice: false);
    var t = 0.0;
    for (var i = 0; i < 190; i++) {
      t += 16;
      game.apply(const MovementInput(valid: true), sample(t, PlayMode.jump), t);
      game.tick(.016, t);
    }
    final y = game.birdY;
    t += 16;
    game.apply(
      const MovementInput(valid: true, flap: true, repetitions: 5),
      sample(t, PlayMode.jump),
      t,
    );
    game.tick(.016, t);
    expect(game.birdY, lessThan(y));
    expect(game.flaps, 1);
    expect(game.repetitions, 0);
  });

  test('new flights resolve missing course names to Star Trail', () {
    expect(FlightCourse.named(null), FlightCourse.starTrail);
    expect(FlightCourse.named('unknown'), FlightCourse.starTrail);
    expect(FlightCourse.named('skyCourier'), FlightCourse.starTrail);
    expect(FlightCourse.named('cloudCruise'), FlightCourse.starTrail);
  });
}
