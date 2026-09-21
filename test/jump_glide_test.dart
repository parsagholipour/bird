import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'cloud_friends_test.dart' show recordCloudCruise;

class GlideFlight {
  GlideFlight({
    GameMode? rules,
    int version = FlightSimulation.currentRulesVersion,
    FlightCourse course = FlightCourse.cloudCruise,
  }) : sim =
           FlightSimulation(
               rules: rules ?? JumpFlyMode(),
               practice: true,
               course: course,
               rulesVersion: version,
               random: Random(5),
             )
             ..phase = RunPhase.playing
             ..started = true;
  final FlightSimulation sim;
  double now = 0;
  void input({bool jump = false}) {
    now += 1;
    sim.apply(
      MovementInput(valid: true, flap: jump),
      TrackingSample(
        mode: sim.rules.mode,
        timestampMs: now,
        receivedMs: now,
        joints: [],
      ),
      now,
    );
  }

  void advance(double seconds) {
    var remaining = seconds;
    while (remaining > 1e-9) {
      final step = min(.02, remaining);
      now += step * 1000;
      input();
      sim.tick(step, now);
      remaining -= step;
    }
  }

  void collect([int count = 1]) {
    sim.stars.addAll(
      List.generate(
        count,
        (_) => SkyStar(x: FlightSimulation.birdX, y: sim.birdY),
      ),
    );
    advance(.01);
  }
}

void main() {
  test(
    'jump descent eases out before glide expiry and never becomes a plunge',
    () {
      final flight = GlideFlight(course: FlightCourse.classic)
        ..input(jump: true)
        ..advance(3.6);
      expect(flight.sim.glideRemaining, inInclusiveRange(.35, .45));
      expect(
        flight.sim.velocity,
        greaterThan(.10),
        reason: 'Descent should gradually pick up before the charge disappears',
      );
      var before = flight.sim.velocity;
      for (var frame = 0; frame < 60; frame++) {
        flight.advance(.02);
        expect(flight.sim.phase, RunPhase.playing);
        expect(flight.sim.velocity, lessThanOrEqualTo(.20 + 1e-9));
        expect(
          (flight.sim.velocity - before).abs(),
          lessThanOrEqualTo(.006),
          reason: 'No abrupt change when glide expires',
        );
        before = flight.sim.velocity;
      }
      expect(flight.sim.glideRemaining, 0);
    },
  );

  test('extending an ending glide slows descent without snapping velocity', () {
    final flight = GlideFlight()
      ..input(jump: true)
      ..advance(4);
    expect(flight.sim.glideRemaining, inInclusiveRange(.15, .30));
    final before = flight.sim.velocity;
    expect(before, greaterThan(.12));
    flight.collect();
    expect((flight.sim.velocity - before).abs(), lessThan(.006));
    flight.advance(.15);
    expect(flight.sim.velocity, lessThan(before));
    expect(flight.sim.glideRemaining, greaterThan(.5));
  });

  test(
    'version 9 and 10 glides retain their original descent for saved replays',
    () {
      for (final version in [9, 10]) {
        final flight =
            GlideFlight(version: version, course: FlightCourse.classic)
              ..input(jump: true)
              ..advance(3.6);
        expect(flight.sim.velocity, closeTo(.06, 1e-9));
        flight.advance(1);
        expect(flight.sim.velocity, greaterThan(.35));
      }
    },
  );

  test(
    'a jump keeps its high boost, then provides three seconds of slow descent',
    () {
      final flight = GlideFlight(), old = GlideFlight(version: 8);
      flight.input(jump: true);
      old.input(jump: true);
      expect(flight.sim.glideRemaining, 3);
      flight.advance(1);
      old.advance(1);
      expect(flight.sim.velocity, lessThan(0));
      expect(
        flight.sim.glideRemaining,
        3,
        reason: 'Ascending does not consume glide',
      );
      expect(flight.sim.birdY, closeTo(old.sim.birdY, 1e-9));
      flight.advance(1);
      expect(flight.sim.gliding, isTrue);
      expect(flight.sim.glideRemaining, inInclusiveRange(2.2, 2.3));
      final y = flight.sim.birdY;
      flight.advance(.8);
      expect(flight.sim.birdY - y, closeTo(.048, .001));
      flight.advance(1.6);
      expect(flight.sim.glideRemaining, 0);
      expect(flight.sim.velocity, greaterThan(FlightSimulation.glideFallSpeed));
    },
  );

  test(
    'stars extend a charged glide once per pickup, capped at five seconds',
    () {
      final flight = GlideFlight()..input(jump: true);
      flight.collect();
      expect(flight.sim.glideRemaining, 3.75);
      final feedbackAt = flight.sim.lastGlideStarAt;
      flight.advance(.1);
      expect(flight.sim.glideRemaining, 3.75);
      expect(flight.sim.lastGlideStarAt, feedbackAt);
      flight.collect(5);
      expect(flight.sim.collectedStars, 6);
      expect(flight.sim.glideRemaining, 5);
      flight.advance(1.6);
      final before = flight.sim.glideRemaining;
      flight.collect();
      expect(
        flight.sim.glideRemaining,
        inInclusiveRange(min(5, before + .75) - .010001, min(5, before + .75)),
      );
    },
  );

  test('stars alone cannot start a glide or revive an exhausted charge', () {
    final flight = GlideFlight();
    flight.collect(3);
    expect(flight.sim.glideRemaining, 0);
    flight.input(jump: true);
    flight.advance(4.5);
    expect(flight.sim.glideRemaining, 0);
    flight.collect();
    expect(flight.sim.glideRemaining, 0);
    flight.input(jump: true);
    expect(flight.sim.glideRemaining, 3);
  });

  test(
    'another jump boosts immediately and refreshes without losing earned glide',
    () {
      final flight = GlideFlight()..input(jump: true);
      flight.collect(2);
      flight.input(jump: true);
      expect(flight.sim.glideRemaining, 4.5);
      flight.advance(3);
      expect(flight.sim.glideRemaining, lessThan(3));
      flight.input(jump: true);
      expect(flight.sim.glideRemaining, 3);
      expect(flight.sim.velocity, closeTo(-.44, 1e-12));
      expect(flight.sim.flaps, 3);
    },
  );

  test(
    'pause, countdown and tracking loss preserve charge without consuming it',
    () {
      final flight = GlideFlight()
        ..input(jump: true)
        ..advance(2);
      final reserve = flight.sim.glideRemaining;
      final y = flight.sim.birdY;
      flight.sim.takeBreak();
      flight.advance(4);
      expect(flight.sim.glideRemaining, reserve);
      expect(flight.sim.birdY, y);
      flight.sim.resume();
      flight.input(jump: true);
      flight.advance(2.9);
      expect(flight.sim.glideRemaining, reserve);
      flight.advance(.2);
      expect(flight.sim.glideRemaining, lessThan(reserve));
      final beforeLoss = flight.sim.glideRemaining;
      flight.sim.tick(.02, flight.now + 600);
      expect(flight.sim.phase, RunPhase.paused);
      expect(flight.sim.glideRemaining, beforeLoss);
    },
  );

  test('invalid input and countdown never grant a charge', () {
    final flight = GlideFlight();
    flight.sim.apply(
      const MovementInput(valid: false, flap: true),
      const TrackingSample(
        mode: PlayMode.jump,
        timestampMs: 0,
        receivedMs: 0,
        joints: [],
      ),
      0,
    );
    expect(flight.sim.glideRemaining, 0);
    flight.sim.phase = RunPhase.countdown;
    flight.input(jump: true);
    expect(flight.sim.glideRemaining, 0);
  });

  test('gliding does not prevent collisions or keep a finished run active', () {
    final flight = GlideFlight(course: FlightCourse.classic)
      ..input(jump: true)
      ..advance(1.5);
    expect(flight.sim.gliding, isTrue);
    flight.sim.obstacles.add(
      Obstacle(x: FlightSimulation.birdX, center: .8, gap: .2),
    );
    flight.advance(.02);
    expect(flight.sim.endReason, EndReason.collision);
    expect(flight.sim.gliding, isFalse);
    expect(flight.sim.hasGlideCharge, isFalse);
  });

  test(
    'touch, push-ups and version 8 jump replays retain their original controls',
    () {
      for (final rules in [TapFlyMode(), PushUpFlightMode(cycleSeconds: 3)]) {
        final flight = GlideFlight(rules: rules)
          ..input(jump: true)
          ..collect(3);
        expect(flight.sim.supportsJumpGlide, isFalse);
        expect(flight.sim.glideRemaining, 0);
      }
      final flight = GlideFlight(version: 8)
        ..input(jump: true)
        ..collect(3)
        ..advance(2);
      expect(flight.sim.supportsJumpGlide, isFalse);
      expect(flight.sim.glideRemaining, 0);
      expect(flight.sim.velocity, greaterThan(.2));
    },
  );

  test(
    'gliding spreads the wings; pause freezes the pose and Reduced Motion is quiet',
    () {
      final flight = GlideFlight()
        ..input(jump: true)
        ..advance(2);
      final pose = BirdPose.forFlight(flight.sim, reducedMotion: false);
      expect(pose.wing, lessThan(-.3));
      flight.sim.takeBreak();
      flight.advance(1);
      expect(
        BirdPose.forFlight(flight.sim, reducedMotion: false).wing,
        pose.wing,
      );
      expect(BirdPose.forFlight(flight.sim, reducedMotion: true).wing, 0);
    },
  );

  test(
    'star-extended glides and feedback survive serialization and backward seeks',
    () {
      final tape = recordCloudCruise(PlayMode.jump).tape;
      final player = ReplayPlayer(ReplayTape.fromJson(tape.toJson()));
      List<Object> state(FlightSimulation sim) => [
        sim.birdY,
        sim.velocity,
        sim.glideRemaining,
        sim.gliding,
        sim.lastGlideStarAt,
        sim.flaps,
        sim.score,
      ];
      var earned = false;
      for (final at in [60000.0, 10000.0, 5000.0, 45000.0, 120000.0]) {
        player.seek(at);
        final direct = ReplayPlayer(tape)..seek(at);
        expect(state(player.simulation), state(direct.simulation));
        earned |= player.simulation.lastGlideStarAt.isFinite;
      }
      expect(earned, isTrue);
      final old = ReplayTape.fromJson(tape.toJson()..['version'] = 8);
      final legacy = ReplayPlayer(old)..seek(old.durationMs);
      expect(legacy.simulation.glideRemaining, 0);
      expect(legacy.simulation.lastGlideStarAt.isFinite, isFalse);
    },
  );

  test(
    'the same cloud route needs fewer jumps while still collecting stars',
    () {
      final modernTape = recordCloudCruise(PlayMode.jump).tape;
      final oldTape = recordCloudCruise(PlayMode.jump, version: 8).tape;
      final modern = ReplayPlayer(modernTape)..seek(modernTape.durationMs);
      final old = ReplayPlayer(oldTape)..seek(oldTape.durationMs);
      expect(modern.simulation.flaps, lessThan(old.simulation.flaps * .75));
      expect(modern.simulation.collectedStars, greaterThan(0));
      expect(modern.simulation.cloudFriends.length, 3);
    },
  );
}
