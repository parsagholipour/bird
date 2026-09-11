import 'dart:math' as math;
import 'tracking.dart';

enum RunPhase { countdown, playing, paused, ended }

enum EndReason {
  collision,
  trackingLost,
  postureLost,
  backgrounded,
  breakTaken,
  quit,
  stalled,
}

class Obstacle {
  Obstacle({
    required this.x,
    required this.center,
    required this.gap,
    this.width = .14,
  });
  double x;
  final double center, gap, width;
  bool scored = false;
  double get top => center - gap / 2;
  double get bottom => center + gap / 2;
}

/// Extension point for exercise games. Distances are in units of viewport height.
abstract interface class GameMode {
  PlayMode get mode;
  double gapFor(int score);
  double speedFor(int score);
  double intervalFor(int score);
  double passageCenter(int index, math.Random random, double previous);
  double get gravity;
  double get flapImpulse;
}

class PushUpFlightMode implements GameMode {
  PushUpFlightMode({required this.cycleSeconds});
  final double cycleSeconds;
  @override
  PlayMode get mode => PlayMode.pushUp;
  @override
  double gapFor(int score) => (.40 - score * .003).clamp(.29, .40);
  @override
  double speedFor(int score) => (.30 + score * .002).clamp(.30, .45);
  // One transition per half cycle, plus a movement/reaction allowance. Never
  // tighten below the cadence measured during calibration.
  @override
  double intervalFor(int score) => (cycleSeconds / 2 + .65).clamp(1.65, 6.65);
  @override
  double passageCenter(int index, math.Random random, double previous) =>
      index.isEven ? .25 : .75;
  @override
  double get gravity => 0;
  @override
  double get flapImpulse => 0;
}

class GrinGlideMode implements GameMode {
  @override
  PlayMode get mode => PlayMode.smile;
  @override
  double gapFor(int score) => (.46 - score * .003).clamp(.33, .46);
  @override
  double speedFor(int score) => (.34 + score * .003).clamp(.34, .53);
  @override
  double intervalFor(int score) => 2.2;
  @override
  double passageCenter(int index, math.Random random, double previous) =>
      (previous + (random.nextDouble() - .5) * .32).clamp(.28, .72);
  @override
  double get gravity => .85;
  @override
  double get flapImpulse => -.40;
}

class RunResult {
  const RunResult({
    required this.id,
    required this.mode,
    required this.practice,
    required this.score,
    required this.repetitions,
    required this.flaps,
    required this.durationSeconds,
    required this.reason,
    required this.finishedAt,
  });
  final String id;
  final PlayMode mode;
  final bool practice;
  final int score, repetitions, flaps;
  final double durationSeconds;
  final EndReason reason;
  final DateTime finishedAt;
}

/// Deterministic simulation, independent of Flame, Flutter and camera hardware.
class FlightSimulation {
  FlightSimulation({
    required this.rules,
    required this.practice,
    math.Random? random,
  }) : random = random ?? math.Random();
  final GameMode rules;
  final bool practice;
  final math.Random random;
  final List<Obstacle> obstacles = [];
  static const birdX = .47, birdRadius = .038;
  RunPhase phase = RunPhase.countdown;
  EndReason? endReason;
  double birdY = .5, velocity = 0, countdown = 3, elapsed = 0, distance = 0;
  int score = 0, repetitions = 0, flaps = 0;
  double _lastValidMs = double.negativeInfinity;
  double _lastValidReceivedMs = double.negativeInfinity;
  double _lastReceivedMs = double.negativeInfinity;
  double _spawnIn = 0, _previousCenter = .5;
  double _lastSampleMs = double.negativeInfinity;
  bool _inputValid = false, started = false;
  String trackingFeedback = 'Find your position';
  int _index = 0, _repBaseline = 0;
  int _latestReps = 0;
  double get lastValidMs => _lastValidMs;
  bool get hasTracking => _inputValid;
  // Packet age is checked when consuming the sample. Availability is measured
  // from its arrival; subtracting inference latency again made tracking expire
  // between camera packets and continually restarted the countdown.
  bool trackingFresh(double now) =>
      _inputValid && now - _lastValidReceivedMs <= 200;

  void apply(MovementInput input, TrackingSample sample, double now) {
    if (phase == RunPhase.ended ||
        sample.mode != rules.mode ||
        sample.timestampMs <= _lastSampleMs) {
      return;
    }
    _lastReceivedMs = now;
    _lastSampleMs = sample.timestampMs;
    _inputValid = input.valid && sample.freshAt(now);
    trackingFeedback = input.feedback;
    if (!_inputValid) return;
    _lastValidMs = sample.timestampMs;
    _lastValidReceivedMs = now;
    _latestReps = input.repetitions;
    if (rules.mode == PlayMode.pushUp) {
      birdY = .85 - input.height.clamp(0, 1) * .70;
      if (phase == RunPhase.playing) {
        repetitions = math.max(0, input.repetitions - _repBaseline);
      }
    } else if (input.flap && phase == RunPhase.playing) {
      velocity = rules.flapImpulse;
      flaps++;
    }
  }

  void tick(double dt, double nowMs, {double viewportWidth = 2.2}) {
    if (phase == RunPhase.ended || phase == RunPhase.paused) return;
    if (!dt.isFinite || dt <= 0) return;
    if (dt > .5 && phase == RunPhase.playing) {
      if (practice) {
        phase = RunPhase.paused;
      } else {
        end(EndReason.stalled);
      }
      return;
    }
    if (phase == RunPhase.countdown) {
      if (!trackingFresh(nowMs)) {
        // Pause through brief occlusions instead of restarting on one bad
        // packet. Long gaps still require a complete countdown.
        if (nowMs - _lastValidReceivedMs > 500) countdown = 3;
        return;
      }
      countdown -= dt;
      if (countdown > 0) return;
      phase = RunPhase.playing;
      _repBaseline = _latestReps - repetitions;
      if (!started) {
        started = true;
        // First passage is visible with enough approach time for the calibrated movement.
        final firstCenter = rules.passageCenter(
          _index++,
          random,
          _previousCenter,
        );
        _previousCenter = firstCenter;
        final lead = math.max(2.5, rules.intervalFor(0));
        obstacles.add(
          Obstacle(
            x: math.max(viewportWidth + .1, birdX + rules.speedFor(0) * lead),
            center: firstCenter,
            gap: rules.gapFor(0),
          ),
        );
        _spawnIn = rules.intervalFor(0);
      }
      return;
    }
    if (nowMs - _lastValidMs > 500) {
      if (practice) {
        phase = RunPhase.paused;
      } else {
        end(
          nowMs - _lastReceivedMs <= 200
              ? EndReason.postureLost
              : EndReason.trackingLost,
        );
      }
      return;
    }
    // Substeps prevent tunneling through obstacles on a slow frame.
    var remaining = dt;
    while (remaining > 0 && phase == RunPhase.playing) {
      final step = math.min(remaining, 1 / 120);
      remaining -= step;
      elapsed += step;
      final speed = rules.speedFor(score);
      distance += speed * step;
      if (rules.mode == PlayMode.smile) {
        velocity += rules.gravity * step;
        birdY += velocity * step;
      }
      _spawnIn -= step;
      for (final obstacle in obstacles) {
        obstacle.x -= speed * step;
      }
      if (_spawnIn <= 0) {
        final center = rules.passageCenter(_index++, random, _previousCenter);
        _previousCenter = center;
        final spacing = speed * rules.intervalFor(score);
        final x = obstacles.isEmpty
            ? viewportWidth + .1
            : math.max(viewportWidth + .1, obstacles.last.x + spacing);
        obstacles.add(Obstacle(x: x, center: center, gap: rules.gapFor(score)));
        _spawnIn += rules.intervalFor(score);
      }
      if (birdY - birdRadius <= 0 || birdY + birdRadius >= 1) {
        end(EndReason.collision);
        break;
      }
      for (final o in obstacles) {
        if (_touches(o)) {
          end(EndReason.collision);
          break;
        }
        if (!o.scored && o.x + o.width < birdX - birdRadius) {
          o.scored = true;
          score++;
        }
      }
      obstacles.removeWhere((o) => o.x + o.width < -.1);
    }
  }

  bool _touches(Obstacle o) {
    bool circleRect(double top, double bottom) {
      final nearX = birdX.clamp(o.x, o.x + o.width);
      final nearY = birdY.clamp(top, bottom);
      final dx = birdX - nearX, dy = birdY - nearY;
      return dx * dx + dy * dy <= birdRadius * birdRadius;
    }

    return circleRect(0, o.top) || circleRect(o.bottom, 1);
  }

  void takeBreak() {
    if (phase == RunPhase.ended) return;
    if (practice) {
      phase = RunPhase.paused;
    } else {
      end(EndReason.breakTaken);
    }
  }

  void background() {
    if (phase == RunPhase.ended) return;
    if (practice || !started) {
      phase = RunPhase.paused;
    } else {
      end(EndReason.backgrounded);
    }
  }

  void resume() {
    if (phase != RunPhase.paused) return;
    if (!practice && started) return;
    phase = RunPhase.countdown;
    countdown = 3;
    _inputValid = false;
    _lastValidMs = double.negativeInfinity;
  }

  void end(EndReason reason) {
    if (phase == RunPhase.ended) return;
    phase = RunPhase.ended;
    endReason = reason;
  }
}
