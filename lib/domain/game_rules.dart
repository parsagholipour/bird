import 'dart:math' as math;
import 'tracking.dart';
import 'flight_course.dart';
import 'cloud_friends.dart';
export 'flight_course.dart';

enum RunPhase { countdown, playing, paused, ended }

enum EndReason {
  collision,
  trackingLost,
  postureLost,
  backgrounded,
  breakTaken,
  quit,
  stalled,
  completed,
}

enum FlightEventKind {
  star,
  streak,
  perfect,
  shieldReady,
  shieldUsed,
  hit,
  milestone,
  finalStretch,
  magnet,
  letter,
  delivery,
  letterLost,
  cloudFriend,
  starTrio,
}

enum CourierStop { pickup, postbox }

class FlightEvent {
  const FlightEvent(
    this.kind,
    this.at,
    this.y, {
    this.value = 0,
    this.gateWorldX,
    this.gateY,
  });
  final FlightEventKind kind;
  final double at, y;
  final int value;
  // Visual handoffs stay attached to their gate as the world scrolls.
  final double? gateWorldX, gateY;
}

class SkyStar {
  SkyStar({required this.x, required this.y, this.trio, this.trioSlot = 0});
  double x;
  final double y;
  final StarTrio? trio;
  final int trioSlot;
  bool collected = false, missed = false;
  static const radius = .027;
}

/// Three stars on one approach. Its center scrolls with the original pickups.
class StarTrio {
  StarTrio({required this.x, required this.y});
  double x;
  final double y;
  int collectedMask = 0;
  bool missed = false;
  double? completedAt;
  static const bonus = 5;
  bool collected(int slot) => collectedMask & (1 << slot) != 0;
}

class Obstacle {
  Obstacle({
    required this.x,
    required this.center,
    required this.gap,
    this.width = .14,
    double? target,
    this.courierStop,
  }) : target = target ?? center;
  double x;
  final double center, gap, width, target;
  final CourierStop? courierStop;
  bool scored = false;
  bool hit = false;
  double? courierActionAt;
  double maxDeviation = 0;
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

/// Tap flight uses the same flap physics, with its own records and replay mode.
class TapFlyMode extends GrinGlideMode {
  @override
  PlayMode get mode => PlayMode.touch;
}

class RunResult {
  const RunResult({
    required this.id,
    required this.mode,
    required bool practice,
    required this.score,
    required this.repetitions,
    required this.flaps,
    required this.durationSeconds,
    required this.reason,
    required this.finishedAt,
    this.course = FlightCourse.classic,
    this.stars = 0,
    this.bestCombo = 0,
    this.perfectPasses = 0,
    int? gates,
  }) : gates = gates ?? score,
       practice = practice || course == FlightCourse.cloudCruise;
  final String id;
  final PlayMode mode;
  final bool practice;
  final int score, repetitions, flaps;
  final double durationSeconds;
  final EndReason reason;
  final DateTime finishedAt;
  final FlightCourse course;
  final int stars, bestCombo, perfectPasses, gates;
}

/// Deterministic simulation, independent of Flame, Flutter and camera hardware.
class FlightSimulation {
  FlightSimulation({
    required this.rules,
    required bool practice,
    this.course = FlightCourse.classic,
    this.rulesVersion = currentRulesVersion,
    math.Random? random,
  }) : random = random ?? math.Random(),
       practice = practice || course.relaxed;
  final GameMode rules;
  final bool practice;
  final FlightCourse course;

  /// Replay journals keep the rules they were recorded with.
  static const currentRulesVersion = 6;
  final int rulesVersion;
  final math.Random random;
  final List<Obstacle> obstacles = [];
  final List<SkyStar> stars = [];
  final List<StarTrio> starTrios = [];
  final List<DriftingCloud> clouds = [];
  final Set<CloudFriend> cloudFriends = {};
  final List<FlightEvent> events = [];
  static const birdX = .47, birdRadius = .038;
  RunPhase phase = RunPhase.countdown;
  EndReason? endReason;
  double birdY = .5, velocity = 0, countdown = 3, elapsed = 0, distance = 0;
  double lastFlapAt = double.negativeInfinity;
  int score = 0, repetitions = 0, flaps = 0;
  int gates = 0, collectedStars = 0, combo = 0, bestCombo = 0;
  int completedTrios = 0;
  int perfectPasses = 0, perfectStreak = 0, hearts = 3;
  bool carryingLetter = false;
  int lettersCollected = 0, lettersDropped = 0, courierBumps = 0;
  bool shield = true;
  double invulnerableUntil = 0;
  double get recoveryRemaining =>
      isTrail || isCourier ? math.max(0, invulnerableUntil - elapsed) : 0;
  int magnetCharge = 0, magnetActivations = 0;
  double magnetUntil = 0;
  static const magnetDuration = 8.0;
  bool get supportsMagnet => collectsStars && rulesVersion >= 3;
  double get magnetRemaining =>
      supportsMagnet ? math.max(0, magnetUntil - elapsed) : 0;
  bool get magnetActive => magnetRemaining > 0;
  double get pickupRadius => magnetActive ? .20 : .085;
  static const trailDuration = 60.0;
  bool get isTrail => course == FlightCourse.starTrail;
  bool get isCruise => course.relaxed;
  bool get discoversClouds => isCruise && rulesVersion >= 5;
  bool get isCourier => course == FlightCourse.skyCourier;
  bool get timed => course.timed;
  bool get collectsStars => course.collectsStars;
  bool get supportsStarTrios => collectsStars && rulesVersion >= 6;
  int get multiplier => 1 + (combo ~/ 6).clamp(0, 2);
  int get shieldCharge => collectedStars % 9;
  double get remainingSeconds => math.max(0, course.duration - elapsed);
  double get speed => isCruise
      ? rules.speedFor(0) * .75
      : isTrail || isCourier
      ? rules.speedFor(gates) * .9
      : rules.speedFor(score);
  double get gap => isCruise
      ? .48
      : isTrail || isCourier
      ? math.min(.48, rules.gapFor(gates) + .09)
      : rules.gapFor(score);
  // The leading constellation occupies .42 height units before its gate.
  // At the slowest trail speed, this allowance leaves at least a calibrated
  // half-cycle between clearing one gate and reaching the next pickup halo.
  double get spawnInterval =>
      rules.intervalFor(collectsStars || isCourier ? gates : score) +
      (isTrail
          ? 1.3
          : isCruise
          ? 1.6
          : isCourier
          ? .65
          : 0);
  String get regionName => switch ((elapsed / 20).floor() % 3) {
    0 => 'Sunrise Isles',
    1 => 'Peach Horizon',
    _ => 'Twilight Garden',
  };
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
      velocity = isCruise ? rules.flapImpulse * .8 : rules.flapImpulse;
      lastFlapAt = elapsed;
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
        final lead = math.max(2.5, spawnInterval);
        _addPassage(
          math.max(viewportWidth + .1, birdX + speed * lead),
          firstCenter,
        );
        _spawnIn = spawnInterval;
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
      final previousElapsed = elapsed;
      elapsed += step;
      if (timed &&
          previousElapsed < course.duration - 10 &&
          elapsed >= course.duration - 10) {
        _event(FlightEventKind.finalStretch);
      }
      if (timed && elapsed >= course.duration) {
        elapsed = course.duration;
        end(EndReason.completed);
        break;
      }
      final speed = this.speed;
      distance += speed * step;
      if (rules.mode != PlayMode.pushUp) {
        velocity += rules.gravity * (isCruise ? .65 : 1) * step;
        birdY += velocity * step;
      }
      _spawnIn -= step;
      for (final obstacle in obstacles) {
        obstacle.x -= speed * step;
      }
      if (_spawnIn <= 0) {
        final center = rules.passageCenter(_index++, random, _previousCenter);
        _previousCenter = center;
        final spacing = speed * spawnInterval;
        final x = obstacles.isEmpty
            ? viewportWidth + .1
            : math.max(viewportWidth + .1, obstacles.last.x + spacing);
        _addPassage(x, center);
        _spawnIn += spawnInterval;
      }
      if (birdY - birdRadius <= 0 || birdY + birdRadius >= 1) {
        if (!collectsStars && !isCourier) {
          end(EndReason.collision);
          break;
        }
        if (isCourier) {
          _dropLetter();
        } else if (!isCruise) {
          _damage();
        }
        final atBottom = birdY > .5;
        birdY = birdY.clamp(birdRadius + .001, 1 - birdRadius - .001);
        velocity = isCruise ? (atBottom ? -.18 : .12) : 0;
      }
      for (final o in obstacles) {
        if (phase == RunPhase.ended) break;
        if (!isCruise && !o.hit && _touches(o)) {
          if (!isTrail && !isCourier) {
            end(EndReason.collision);
            break;
          }
          o.hit = true;
          if (isCourier) {
            _dropLetter();
          } else {
            _damage();
          }
        }
        if (o.x < birdX + birdRadius && o.x + o.width > birdX - birdRadius) {
          o.maxDeviation = math.max(o.maxDeviation, (birdY - o.target).abs());
        }
        if (!o.scored && o.x + o.width < birdX - birdRadius) {
          o.scored = true;
          if (!o.hit) {
            gates++;
            if (isCourier) {
              if (o.courierStop == CourierStop.pickup && !carryingLetter) {
                carryingLetter = true;
                lettersCollected++;
                o.courierActionAt = elapsed;
                events.add(
                  FlightEvent(
                    FlightEventKind.letter,
                    elapsed,
                    birdY,
                    gateWorldX: distance + o.x + o.width / 2,
                    gateY: o.target,
                  ),
                );
              } else if (o.courierStop == CourierStop.postbox &&
                  carryingLetter) {
                carryingLetter = false;
                score++;
                o.courierActionAt = elapsed;
                events.add(
                  FlightEvent(
                    FlightEventKind.delivery,
                    elapsed,
                    birdY,
                    value: score,
                    gateWorldX: distance + o.x + o.width / 2,
                    gateY: o.target,
                  ),
                );
              }
            } else if (!collectsStars) {
              score++;
            }
            if (o.maxDeviation <= .075) {
              perfectPasses++;
              perfectStreak++;
              _event(FlightEventKind.perfect, perfectStreak);
              if (supportsMagnet && !magnetActive) {
                magnetCharge++;
                if (magnetCharge == 3) {
                  magnetCharge = 0;
                  magnetUntil = elapsed + magnetDuration;
                  magnetActivations++;
                  _event(FlightEventKind.magnet);
                }
              }
            } else {
              perfectStreak = 0;
            }
            if (gates % 5 == 0) _event(FlightEventKind.milestone, gates);
          }
        }
      }
      if (collectsStars && phase == RunPhase.playing) {
        _advanceStars(speed * step);
      }
      if (discoversClouds && phase == RunPhase.playing) {
        _advanceClouds(speed * step);
      }
      obstacles.removeWhere((o) => o.x + o.width < -.1);
      events.removeWhere((e) => elapsed - e.at > 2);
    }
  }

  void _addPassage(double x, double center) {
    // Push-ups should reward the complete calibrated movement. The collision
    // opening stays unchanged; its aiming mark follows the comfortable endpoint.
    final target = rulesVersion >= 3 && rules.mode == PlayMode.pushUp
        ? (center < .5 ? .15 : .85)
        : center;
    obstacles.add(
      Obstacle(
        x: x,
        center: center,
        gap: gap,
        target: target,
        courierStop: isCourier
            ? (_index.isOdd ? CourierStop.pickup : CourierStop.postbox)
            : null,
      ),
    );
    if (collectsStars) {
      final trio = supportsStarTrios ? StarTrio(x: x - .25, y: target) : null;
      if (trio != null) starTrios.add(trio);
      for (var i = 0; i < 3; i++) {
        stars.add(
          SkyStar(x: x - .42 + i * .17, y: target, trio: trio, trioSlot: i),
        );
      }
    }
    // A friend visits every third ring. The same calm endpoint reaches both
    // the cloud and the stars; no additional movement or cadence is required.
    if (discoversClouds && (_index - 1) % 3 == 0) {
      clouds.add(
        DriftingCloud(
          friend: CloudFriend.values[((_index - 1) ~/ 3) % 3],
          x: x + .07,
          y: target.clamp(.23, .77),
        ),
      );
    }
  }

  void _advanceClouds(double travel) {
    for (final cloud in clouds) {
      cloud.x -= travel;
      if (cloud.discovered || cloud.passed) continue;
      final dx = birdX - cloud.x, dy = birdY - cloud.y;
      if (dx * dx + dy * dy <=
          DriftingCloud.pickupRadius * DriftingCloud.pickupRadius) {
        cloud.discovered = true;
        if (cloudFriends.add(cloud.friend)) {
          events.add(
            FlightEvent(
              FlightEventKind.cloudFriend,
              elapsed,
              cloud.y,
              value: cloud.friend.index,
            ),
          );
        }
      } else if (cloud.x < birdX - DriftingCloud.pickupRadius) {
        cloud.passed = true;
      }
    }
    clouds.removeWhere((cloud) => cloud.x < -.25);
  }

  void _advanceStars(double travel) {
    for (final trio in starTrios) {
      trio.x -= travel;
    }
    for (final star in stars) {
      star.x -= travel;
      if (star.collected || star.missed) continue;
      final dx = birdX - star.x, dy = birdY - star.y;
      // A generous pickup halo rewards intention over pixel precision.
      final radius = pickupRadius;
      if (dx * dx + dy * dy <= radius * radius) {
        final previousMultiplier = multiplier;
        star.collected = true;
        combo++;
        collectedStars++;
        bestCombo = math.max(bestCombo, combo);
        score += multiplier;
        events.add(
          FlightEvent(FlightEventKind.star, elapsed, star.y, value: multiplier),
        );
        final trio = supportsStarTrios ? star.trio : null;
        if (trio != null) {
          trio.collectedMask |= 1 << star.trioSlot;
          if (!trio.missed &&
              trio.collectedMask == 7 &&
              trio.completedAt == null) {
            trio.completedAt = elapsed;
            completedTrios++;
            score += StarTrio.bonus;
            _event(FlightEventKind.starTrio, StarTrio.bonus);
          }
        }
        if (multiplier > previousMultiplier) {
          _event(FlightEventKind.streak, multiplier);
        }
        if (isTrail && collectedStars % 9 == 0 && !shield) {
          shield = true;
          _event(FlightEventKind.shieldReady);
        }
      } else if (star.x < birdX - radius) {
        star.missed = true;
        if (supportsStarTrios) star.trio?.missed = true;
        combo = 0;
      }
    }
    stars.removeWhere((s) => s.x < -.1);
    starTrios.removeWhere((trio) => trio.x + .17 < -.1);
  }

  void _damage() {
    if (elapsed < invulnerableUntil || phase == RunPhase.ended) return;
    combo = 0;
    perfectStreak = 0;
    invulnerableUntil = elapsed + 1.5;
    if (shield) {
      shield = false;
      _event(FlightEventKind.shieldUsed);
    } else {
      hearts--;
      _event(FlightEventKind.hit);
      if (hearts <= 0) end(EndReason.collision);
    }
  }

  void _dropLetter() {
    if (elapsed < invulnerableUntil || phase == RunPhase.ended) return;
    invulnerableUntil = elapsed + 1.5;
    courierBumps++;
    perfectStreak = 0;
    if (carryingLetter) {
      carryingLetter = false;
      lettersDropped++;
      _event(FlightEventKind.letterLost);
    } else {
      _event(FlightEventKind.hit);
    }
  }

  void _event(FlightEventKind kind, [int value = 0]) =>
      events.add(FlightEvent(kind, elapsed, birdY, value: value));

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
