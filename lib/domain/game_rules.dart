import 'dart:math' as math;
import 'tracking.dart';
import 'flight_course.dart';
import 'cloud_friends.dart';
import 'bird_motion.dart';
import 'flight_path.dart';
import 'obstacle.dart';
import 'sky_boss.dart';
import 'sky_enemy.dart';
import 'sky_door.dart';
export 'flight_course.dart';
export 'flight_path.dart';
export 'obstacle.dart';
export 'sky_boss.dart';
export 'sky_enemy.dart';
export 'sky_door.dart';

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
  enemyHit,
  bossDefeated,
  heart,
}

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
  SkyStar({
    required this.x,
    required this._y,
    this.trio,
    this.trioSlot = 0,
    this.passage,
  });
  double x;
  final double _y;
  final Obstacle? passage;
  double get y => passage?.target ?? _y;
  final StarTrio? trio;
  final int trioSlot;
  bool collected = false, missed = false;
  static const radius = .027;
}

/// Three stars on one approach. Its center scrolls with the original pickups.
class StarTrio {
  StarTrio({required this.x, required this._y, this.passage});
  double x;
  final double _y;
  final Obstacle? passage;
  double get y => passage?.target ?? _y;
  int collectedMask = 0;
  bool missed = false;
  double? completedAt;
  static const bonus = 5;
  bool collected(int slot) => collectedMask & (1 << slot) != 0;
}

class BirdRock {
  BirdRock({required this.x, required this.y, this.damage = baseDamage}) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
  }
  double x;
  final double y;
  // A shot retains the weapon's damage at the instant it was fired.
  final int damage;
  static const baseDamage = 10;
  static const radius = .014, speed = 1.65;
}

/// A life pickup that follows the safe opening of its passage.
class SkyHeart {
  SkyHeart({required this.x, required this._y, this.passage});
  double x;
  final double _y;
  final Obstacle? passage;
  double get y => passage?.target ?? _y;
  static const radius = .035, pickupRadius = .085;
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

/// Continuous height control with the player's comfortable squat cadence.
class SquatFlyMode extends PushUpFlightMode {
  SquatFlyMode({required super.cycleSeconds});
  @override
  PlayMode get mode => PlayMode.squat;
}

/// Original flap physics for saved replays and the touch mode baseline.
class LegacyFlapMode implements GameMode {
  @override
  PlayMode get mode => PlayMode.jump;
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

/// A physical jump earns nearly three times the old smile flap height and
/// twice the airtime, with slower passages to allow time to land and recover.
class JumpFlyMode extends LegacyFlapMode {
  @override
  double gapFor(int score) => (.52 - score * .002).clamp(.42, .52);
  @override
  double speedFor(int score) => (.28 + score * .002).clamp(.28, .40);
  @override
  double intervalFor(int score) => 2.8;
  @override
  double get gravity => .55;
  @override
  double get flapImpulse => -.55;
}

/// Touch has a faster arcade cadence. Older journals retain smile physics.
class TapFlyMode extends LegacyFlapMode {
  TapFlyMode({this.rulesVersion = FlightSimulation.currentRulesVersion});
  final int rulesVersion;
  bool get arcade => rulesVersion >= 7;
  @override
  PlayMode get mode => PlayMode.touch;
  @override
  double gapFor(int score) =>
      arcade ? (.38 - score * .003).clamp(.28, .38) : super.gapFor(score);
  @override
  double speedFor(int score) =>
      arcade ? (.40 + score * .003).clamp(.40, .58) : super.speedFor(score);
  @override
  double intervalFor(int score) => arcade ? 1.7 : super.intervalFor(score);
  @override
  double get gravity => arcade ? 1.1 : super.gravity;
  @override
  double get flapImpulse => arcade ? -.54 : super.flapImpulse;
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
    int weaponDamage = BirdRock.baseDamage,
    math.Random? random,
  }) : random = random ?? math.Random(),
       practice = practice || course.relaxed {
    setWeaponDamage(weaponDamage);
  }
  final GameMode rules;
  final bool practice;
  final FlightCourse course;

  /// Replay journals keep the rules they were recorded with.
  static const currentRulesVersion = 27;
  final int rulesVersion;
  final math.Random random;
  final List<Obstacle> obstacles = [];
  final List<SkyStar> stars = [];
  final List<StarTrio> starTrios = [];
  final List<SkyHeart> heartPickups = [];
  final List<DriftingCloud> clouds = [];
  final Set<CloudFriend> cloudFriends = {};
  final List<FlightEvent> events = [];
  final List<SkyEnemy> enemies = [];
  final List<EnemyAmmo> enemyAmmo = [];
  final List<BirdRock> rocks = [];
  SkyBoss? boss;
  int doorsDestroyed = 0;
  bool _lastPassageHadDoor = false;
  final List<BossAmmo> bossAmmo = [];
  int bossesDefeated = 0;
  static const bossInterval = 45.0, bossBonus = 30;
  double _nextBossAt = bossInterval;
  int? _heartPassagesRemaining;
  bool get supportsBosses => supportsCombat && rulesVersion >= 15;
  bool get supportsHeartPickups =>
      supportsBosses && isTrail && rulesVersion >= 24;
  bool get supportsEnemyAttacks => supportsCombat && rulesVersion >= 18;
  bool get supportsWeaponDamage => supportsCombat && rulesVersion >= 26;
  bool get bossCutscene => boss?.inCutscene ?? false;
  int shots = 0, enemiesDefeated = 0;
  // Presentation counters survive objects leaving the screen within a frame.
  // They do not affect physics, RNG or the recorded replay format.
  int rockImpacts = 0, projectilesDeflected = 0, enemyShots = 0;
  double lastShotAt = double.negativeInfinity;
  static const shotCooldown = .28;
  int _weaponDamage = BirdRock.baseDamage;
  int get weaponDamage => supportsWeaponDamage ? _weaponDamage : 1;

  /// Live upgrades should go through FlightRecorder.setWeaponDamage so seeks
  /// restore the same weapon and shots already in flight keep their damage.
  void setWeaponDamage(int damage) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    _weaponDamage = damage;
  }

  bool get supportsCombat =>
      rules.mode == PlayMode.touch && rulesVersion >= 7 && !isCruise;
  double get shotCooldownRemaining =>
      math.max(0, lastShotAt + shotCooldown - elapsed);
  bool get canShoot =>
      supportsCombat &&
      !bossCutscene &&
      phase == RunPhase.playing &&
      shotCooldownRemaining == 0;
  static const birdX = .47, birdRadius = .038;
  static const _enemyPassageLead = .55, _enemyEntryMargin = .15;
  RunPhase phase = RunPhase.countdown;
  EndReason? endReason;
  double birdY = .5, velocity = 0, countdown = 3, elapsed = 0, distance = 0;
  final FlightPath flightPath = FlightPath();
  double lastFlapAt = double.negativeInfinity;
  static const jumpGlideSeconds = 3.0, starGlideSeconds = .75;
  static const maxGlideSeconds = 5.0, glideFallSpeed = .06;
  static const glideEaseOutSeconds = 1.25, maxJumpFallSpeed = .20;
  static const _jumpFallAcceleration = .24;
  double _glideRemaining = 0;
  double lastGlideStarAt = double.negativeInfinity;
  bool get supportsJumpGlide =>
      rules.mode == PlayMode.jump && rulesVersion >= 9;
  bool get smoothJumpDescent => supportsJumpGlide && rulesVersion >= 11;
  double get glideRemaining => supportsJumpGlide ? _glideRemaining : 0;
  bool get hasGlideCharge => glideRemaining > 0 && phase != RunPhase.ended;
  bool get gliding => hasGlideCharge && velocity >= 0;
  int score = 0, repetitions = 0, flaps = 0;
  int gates = 0, collectedStars = 0, combo = 0, bestCombo = 0;
  int completedTrios = 0;
  static const maxHearts = 5;
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
  bool get endless => rulesVersion >= 12;
  bool get timed => !endless && course.legacyTimed;
  bool get collectsStars => course.collectsStars;
  bool get supportsStarTrios => collectsStars && rulesVersion >= 6;
  int get multiplier => 1 + (combo ~/ 6).clamp(0, 2);
  int get shieldCharge => collectedStars % 9;
  double get remainingSeconds => math.max(0, course.duration - elapsed);
  String get clockLabel {
    if (timed) return '${remainingSeconds.ceil()}s';
    final seconds = elapsed.floor();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  // Time, not points, gently increases the pace. A star bonus never causes a
  // sudden jump in speed; the asymptote keeps long flights physically playable.
  double get paceMultiplier =>
      endless ? 1 + (isCruise ? .25 : .65) * (1 - math.exp(-elapsed / 240)) : 1;
  double get speed => endless
      ? rules.speedFor(0) *
            (isCruise
                ? .75
                : isTrail || isCourier
                ? .9
                : 1) *
            paceMultiplier
      : isCruise
      ? rules.speedFor(0) * .75
      : isTrail || isCourier
      ? rules.speedFor(gates) * .9
      : rules.speedFor(score);
  int get _difficulty => endless ? (elapsed / 20).floor() : gates;
  double get gap => isCruise
      ? .48
      : supportsCombat
      ? rules.gapFor(_difficulty)
      : isTrail || isCourier
      ? math.min(.48, rules.gapFor(_difficulty) + .09)
      : rules.gapFor(endless ? _difficulty : score);
  // The leading constellation occupies .42 height units before its gate.
  // At the slowest trail speed, this allowance leaves at least a calibrated
  // half-cycle between clearing one gate and reaching the next pickup halo.
  double get spawnInterval {
    final interval =
        rules.intervalFor(collectsStars || isCourier ? gates : score) +
        (supportsCombat
            ? (isTrail ? .25 : 0)
            : isTrail
            ? 1.3
            : isCruise
            ? 1.6
            : isCourier
            ? .65
            : 0);
    final mode = rules;
    if (!endless || mode is! PushUpFlightMode) return interval;
    // Budget for the widest switchback and the leading pickup halo, including
    // a little headroom for acceleration while the next gate approaches.
    final occupied =
        (rulesVersion >= 13 ? .30 : .24) +
        birdRadius +
        (collectsStars ? .42 - .085 : birdRadius);
    return math.max(interval, mode.cycleSeconds / 2 + occupied / speed + .15);
  }

  bool shoot({bool reducedMotion = false}) {
    if (!canShoot) return false;
    final mouth = BirdFlightMotion.mouth(
      velocity: velocity,
      sinceFlap: elapsed - lastFlapAt,
      reducedMotion: reducedMotion,
    );
    rocks.add(
      BirdRock(x: birdX + mouth.x, y: birdY + mouth.y, damage: weaponDamage),
    );
    lastShotAt = elapsed;
    shots++;
    return true;
  }

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
  final List<ObstacleKind> _patterns = [];
  int _patternTier = -1;
  ObstacleKind _lastPattern = ObstacleKind.garden;
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
    if (rules.mode.controlsHeight) {
      birdY = .85 - input.height.clamp(0, 1) * .70;
      if (phase == RunPhase.playing) {
        repetitions = math.max(0, input.repetitions - _repBaseline);
      }
    } else if (input.flap && phase == RunPhase.playing && !bossCutscene) {
      velocity = isCruise ? rules.flapImpulse * .8 : rules.flapImpulse;
      lastFlapAt = elapsed;
      flaps++;
      if (supportsJumpGlide) {
        // Refresh the base allowance without erasing time earned from stars.
        _glideRemaining = math.max(_glideRemaining, jumpGlideSeconds);
      }
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
          math.max(_passageEntryX(viewportWidth), birdX + speed * lead),
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
      if (supportsBosses) _advanceBoss(step, viewportWidth);
      if (bossCutscene) {
        // Let the player watch the reveal and victory without falling into a
        // boundary. No input queues up to launch the bird when control returns.
        birdY += (.52 - birdY) * (1 - math.exp(-step * 3));
        birdY = birdY.clamp(birdRadius + .001, 1 - birdRadius - .001);
        velocity = 0;
      } else if (!rules.mode.controlsHeight) {
        if (smoothJumpDescent && velocity >= 0) {
          _advanceJumpDescent(step);
        } else {
          velocity += rules.gravity * (isCruise ? .65 : 1) * step;
          if (gliding) {
            // The upward boost keeps its original height. Only the descent uses
            // the banked glide, so a player gets the full rest after takeoff.
            velocity = math.min(velocity, glideFallSpeed);
            _glideRemaining = math.max(0, _glideRemaining - step);
          }
        }
        birdY += velocity * step;
      }
      if (boss == null) _spawnIn -= step;
      for (final obstacle in obstacles) {
        obstacle.x -= speed * step;
        obstacle.advance(elapsed);
      }
      if (boss == null && _spawnIn <= 0) {
        final center = rules.passageCenter(_index++, random, _previousCenter);
        _previousCenter = center;
        final spacing = speed * spawnInterval;
        final x = obstacles.isEmpty
            ? _passageEntryX(viewportWidth)
            : math.max(
                _passageEntryX(viewportWidth),
                obstacles.last.x + spacing,
              );
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
      flightPath.record(distance, birdY);
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
      if (supportsHeartPickups && phase == RunPhase.playing) {
        _advanceHearts(speed * step);
      }
      if (supportsCombat && phase == RunPhase.playing) {
        _advanceCombat(step, speed, viewportWidth);
      }
      if (discoversClouds && phase == RunPhase.playing) {
        _advanceClouds(speed * step);
      }
      obstacles.removeWhere((o) => o.x + o.width < -.1);
      events.removeWhere((e) => elapsed - e.at > 2);
    }
  }

  // Reserve room for the leading enemy, including its wings, so the whole
  // approach scrolls in from the right while retaining enemy/gate spacing.
  double _passageEntryX(double viewportWidth) =>
      viewportWidth +
      (rulesVersion >= 25 && supportsCombat
          ? _enemyPassageLead + _enemyEntryMargin
          : .1);

  void _addPassage(double x, double center) {
    // Height controls reward the complete calibrated movement. The collision
    // opening stays unchanged; its aiming mark follows the comfortable endpoint.
    final target = rulesVersion >= 3 && rules.mode.controlsHeight
        ? (center < .5 ? .15 : .85)
        : center;
    // After boss 2, occasional ordinary walls have a shootable opening.
    // Keep a clear passage between them and leave reward-heart gates open.
    final hasDoor =
        supportsCombat &&
        rulesVersion >= 27 &&
        bossesDefeated >= 2 &&
        !_lastPassageHadDoor &&
        _heartPassagesRemaining != 1 &&
        random.nextDouble() < .25;
    _lastPassageHadDoor = hasDoor;
    final nextKind = _nextPattern();
    final kind = hasDoor ? ObstacleKind.garden : nextKind;
    final moving = kind != ObstacleKind.garden;
    final amplitude = moving ? (rules.mode.controlsHeight ? .035 : .065) : 0.0;
    // Even the tightest phase leaves a generous safe lane. Height controls keep
    // their calibrated endpoints rather than demanding extra mini repetitions.
    final safeGap =
        2 * ((center - target).abs() + amplitude + birdRadius + .025);
    final opening = endless ? math.max(gap, safeGap) : gap;
    final obstacle = Obstacle(
      x: x,
      center: center,
      gap: opening,
      target: target,
      width: kind.width,
      kind: kind,
      amplitude: amplitude,
      period: math.max(7, rules.intervalFor(0) * 2.5),
      phaseOffset: moving ? random.nextDouble() * math.pi * 2 : 0,
      bornAt: elapsed,
      fixedTarget: rules.mode.controlsHeight,
      appearance: _obstacleAppearance(),
      door: hasDoor ? SkyDoor() : null,
      courierStop: isCourier
          ? (_index.isOdd ? CourierStop.pickup : CourierStop.postbox)
          : null,
    );
    obstacles.add(obstacle);
    if (_heartPassagesRemaining case final remaining?) {
      if (remaining == 1) {
        heartPickups.add(
          SkyHeart(x: x + obstacle.width / 2, y: target, passage: obstacle),
        );
        _heartPassagesRemaining = null;
      } else {
        _heartPassagesRemaining = remaining - 1;
      }
    }
    if (collectsStars) {
      final passage = endless ? obstacle : null;
      final trio = supportsStarTrios
          ? StarTrio(x: x - .25, y: target, passage: passage)
          : null;
      if (trio != null) starTrios.add(trio);
      for (var i = 0; i < 3; i++) {
        stars.add(
          SkyStar(
            x: x - .42 + i * .17,
            y: target,
            trio: trio,
            trioSlot: i,
            passage: passage,
          ),
        );
      }
    }
    // Alternate approaches leave room to learn the tighter gate rhythm.
    // Enemies share the aiming height and remain in front of their building.
    if (supportsCombat && _index.isOdd && !hasDoor) {
      enemies.add(
        SkyEnemy(
          x: x - _enemyPassageLead,
          y: target,
          appearance: _enemyAppearance(_index ~/ 2),
          maxHp: _enemyHealth(_enemyAppearance(_index ~/ 2)),
          flightPhase: rulesVersion >= 20 ? _index * 2.399963 : null,
        ),
      );
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

  ObstacleKind _nextPattern() {
    if (!endless || _index <= 3 || elapsed < 18) return ObstacleKind.garden;
    final tier = rulesVersion >= 13
        ? (elapsed / 18).floor().clamp(1, ObstacleKind.values.length - 1)
        : elapsed < 36
        ? 1
        : elapsed < 54
        ? 2
        : 3;
    if (_patterns.isEmpty || tier != _patternTier) {
      _patternTier = tier;
      _patterns
        ..clear()
        ..addAll(ObstacleKind.values.take(tier + 1))
        ..shuffle(random);
      // Shuffle bags guarantee variety without back-to-back identical hazards.
      if (_patterns.last == _lastPattern) {
        final first = _patterns.first;
        _patterns[0] = _patterns.last;
        _patterns[_patterns.length - 1] = first;
      }
    }
    return _lastPattern = _patterns.removeLast();
  }

  /// Same draw as version 13, then the opening three gates show each structure.
  int _obstacleAppearance() {
    final sampled = rulesVersion >= 13 ? random.nextInt(3) : 0;
    if (rulesVersion >= 16 && _index <= 3) return (_index - 1) % 3;
    return sampled;
  }

  int _enemyAppearance(int index, {bool bossHelper = false}) {
    if (rulesVersion < 16) return 0;
    if (rulesVersion < 19) return index % 3;
    // Baron Bat's smaller relatives lead the lineup. The natural cave bat
    // stays a distinct fourth character in normal flight.
    const lineup = [3, 1, 2, 0];
    return lineup[index % (bossHelper ? 3 : lineup.length)];
  }

  int _enemyHealth(int appearance) => supportsWeaponDamage
      ? SkyEnemy.healthFor(appearance, bossesDefeated: bossesDefeated)
      : 1;

  void _advanceJumpDescent(double dt) {
    final ending = (1 - _glideRemaining / glideEaseOutSeconds).clamp(0.0, 1.0);
    final ease = ending * ending * (3 - 2 * ending);
    final target = glideFallSpeed + (maxJumpFallSpeed - glideFallSpeed) * ease;
    // Ease out before the reserve expires; afterwards keep the same gentle
    // terminal speed. Rate-limited braking also softens a star's glide refill.
    final change = _jumpFallAcceleration * dt;
    velocity += (target - velocity).clamp(-change, change);
    _glideRemaining = math.max(0, _glideRemaining - dt);
  }

  void _advanceCombat(double dt, double scrollSpeed, double viewportWidth) {
    for (final enemy in enemies) {
      enemy.x -= scrollSpeed * dt;
      if (supportsEnemyAttacks) enemy.age += dt;
      if (enemy.flightPhase != null) {
        // Settle into the aiming lane on the final approach, so a small
        // flight bob cannot turn a narrow passage into a surprise collision.
        enemy.flightRoom = ((enemy.x - birdX - .22) / .65).clamp(0.0, 1.0);
      }
    }
    final spent = <BirdRock>{};
    for (final rock in rocks) {
      rock.x += BirdRock.speed * dt;
      // The same small physics steps used for buildings also prevent rocks
      // tunneling through enemies, even when a rendered frame is slow.
      if (obstacles.any(
        (o) => _circleTouchesObstacle(
          rock.x,
          rock.y,
          BirdRock.radius,
          o,
          includeDoor: false,
        ),
      )) {
        spent.add(rock);
        rockImpacts++;
        continue;
      }
      for (final obstacle in obstacles) {
        if (!_circleTouchesDoor(rock.x, rock.y, BirdRock.radius, obstacle)) {
          continue;
        }
        final seal = obstacle.door!;
        spent.add(rock);
        seal.takeDamage(rock.damage, hitY: rock.y);
        rockImpacts++;
        if (seal.destroyed) doorsDestroyed++;
        break;
      }
      if (spent.contains(rock)) continue;
      for (final enemy in enemies) {
        final dx = rock.x - enemy.x, dy = rock.y - enemy.y;
        const radius = BirdRock.radius + SkyEnemy.radius;
        if (dx * dx + dy * dy > radius * radius) continue;
        spent.add(rock);
        enemy.takeDamage(supportsWeaponDamage ? rock.damage : enemy.hp);
        if (enemy.hp > 0) {
          rockImpacts++;
          break;
        }
        enemies.remove(enemy);
        enemiesDefeated++;
        final bonus = isTrail ? 3 : 0;
        score += bonus;
        events.add(
          FlightEvent(
            FlightEventKind.enemyHit,
            elapsed,
            enemy.y,
            value: bonus,
            gateWorldX: distance + enemy.x,
          ),
        );
        break;
      }
      final target = boss;
      if (!spent.contains(rock) && target?.phase == BossPhase.attacking) {
        final dx = rock.x - target!.x, dy = rock.y - target.y;
        final reach =
            BirdRock.radius +
            (target.shielded ? SkyBoss.shieldRadius : SkyBoss.radius);
        if (dx * dx + dy * dy <= reach * reach) {
          spent.add(rock);
          if (target.shielded) {
            target.lastShieldHitAt = target.age;
            continue;
          }
          target.takeDamage(supportsWeaponDamage ? rock.damage : 1);
          if (target.hp == 0) _defeatBoss(target);
        }
      }
    }
    rocks.removeWhere(
      (rock) => spent.contains(rock) || rock.x > viewportWidth + .2,
    );
    enemies.removeWhere((enemy) {
      final dx = birdX - enemy.x, dy = birdY - enemy.y;
      const radius = birdRadius + SkyEnemy.radius;
      if (dx * dx + dy * dy <= radius * radius) {
        if (isTrail) {
          _damage();
        } else if (isCourier) {
          _dropLetter();
        } else {
          end(EndReason.collision);
        }
        return true;
      }
      return enemy.x < -.1;
    });
    if (supportsEnemyAttacks) {
      _advanceEnemyAttacks(dt, viewportWidth);
    }
    bossAmmo.removeWhere((ammo) {
      ammo.x += ammo.vx * dt;
      ammo.y += ammo.vy * dt;
      final dx = birdX - ammo.x, dy = birdY - ammo.y;
      const reach = birdRadius + BossAmmo.radius;
      if (dx * dx + dy * dy <= reach * reach) {
        if (isTrail) {
          _damage();
        } else if (isCourier) {
          _dropLetter();
        } else {
          end(EndReason.collision);
        }
        return true;
      }
      return ammo.x < -.1 ||
          ammo.x > viewportWidth + .2 ||
          ammo.y < -.1 ||
          ammo.y > 1.1;
    });
  }

  void _advanceEnemyAttacks(double dt, double viewportWidth) {
    for (final enemy in enemies) {
      // An entire warning must be visible. Close or passed enemies stop
      // attacking; there are no off-screen or point-blank ambushes.
      final canAttack =
          phase == RunPhase.playing &&
          !bossCutscene &&
          enemy.attack != EnemyAttack.none &&
          enemy.x < viewportWidth - .12 &&
          enemy.x > birdX + .40;
      enemy.preparing = canAttack;
      if (!canAttack) {
        enemy.fireIn = math.max(enemy.fireIn, SkyEnemy.warningSeconds);
        continue;
      }
      enemy.fireIn -= dt;
      final fan = enemy.attack == EnemyAttack.fan;
      if (enemy.fireIn > 0 || enemyAmmo.length + (fan ? 3 : 1) > 12) continue;
      final aim = math.atan2(birdY - enemy.y, birdX - enemy.muzzleX);
      final speed = fan ? .34 : .44;
      for (final offset in fan ? [-.30, 0.0, .30] : [0.0]) {
        enemyAmmo.add(
          EnemyAmmo(
            x: enemy.muzzleX,
            y: enemy.y,
            vx: math.cos(aim + offset) * speed,
            vy: math.sin(aim + offset) * speed,
            attack: enemy.attack,
          ),
        );
      }
      enemy.volleys++;
      enemyShots++;
      enemy.lastShotAt = enemy.age;
      enemy.fireIn += fan ? 3.2 : 2.4;
    }
    enemyAmmo.removeWhere((ammo) {
      ammo.x += ammo.vx * dt;
      ammo.y += ammo.vy * dt;
      if (ammo.x < -.1 ||
          ammo.x > viewportWidth + .2 ||
          ammo.y < -.1 ||
          ammo.y > 1.1 ||
          obstacles.any(
            (o) => _circleTouchesObstacle(ammo.x, ammo.y, EnemyAmmo.radius, o),
          )) {
        return true;
      }
      // A well-timed shot can cancel a pellet instead of demanding a dodge
      // while the player is lining up with a narrow gate.
      for (final rock in rocks) {
        final dx = rock.x - ammo.x, dy = rock.y - ammo.y;
        const reach = BirdRock.radius + EnemyAmmo.radius;
        if (dx * dx + dy * dy <= reach * reach) {
          rocks.remove(rock);
          projectilesDeflected++;
          return true;
        }
      }
      final dx = birdX - ammo.x, dy = birdY - ammo.y;
      const reach = birdRadius + EnemyAmmo.radius;
      if (dx * dx + dy * dy > reach * reach) return false;
      if (isTrail) {
        _damage();
      } else if (isCourier) {
        _dropLetter();
      } else {
        end(EndReason.collision);
      }
      return true;
    });
  }

  void _advanceBoss(double dt, double viewportWidth) {
    if (boss == null) {
      if (elapsed < _nextBossAt) return;
      final number = bossesDefeated + 1;
      final kind = rulesVersion >= 22
          ? BossKind.values[bossesDefeated % 3]
          : rulesVersion >= 21 && bossesDefeated.isOdd
          ? BossKind.spitterBeetle
          : BossKind.baronBat;
      boss = SkyBoss(
        number: number,
        x: viewportWidth + .3,
        cinematic: rulesVersion >= 17,
        wideSpitterFans: rulesVersion >= 23,
        kind: kind,
        maxHp:
            SkyBoss.healthFor(kind, number) ~/ (supportsWeaponDamage ? 1 : 10),
      );
      // Remove pickups with their gates so the interlude cannot break a combo
      // or award a passage that was never flown. Existing cargo is retained.
      obstacles.clear();
      stars.clear();
      starTrios.clear();
      heartPickups.clear();
      _heartPassagesRemaining = null;
      enemies.clear();
      rocks.clear();
      bossAmmo.clear();
      enemyAmmo.clear();
      events.clear();
    }
    final current = boss!;
    current.age += dt;
    if (current.phase == BossPhase.defeated) {
      if (current.age - current.defeatedAt! >= current.departureDuration) {
        boss = null;
        // A full normal-flight interval follows the victory celebration.
        _nextBossAt = elapsed + bossInterval;
        if (supportsHeartPickups) {
          // One of the next 2–7 gates carries the reward, leaving ample flight
          // time to reach it before the next boss. Use the replay's seeded RNG.
          _heartPassagesRemaining = 2 + random.nextInt(6);
        }
        _spawnIn = 0;
        _previousCenter = birdY.clamp(.28, .72);
      }
      return;
    }
    // The moth's denser fans need room to separate before reaching the bird,
    // especially on narrow landscape phones.
    final targetX = current.isMoth
        ? math.max(birdX + .7, viewportWidth - .54)
        : math.max(birdX + .55, viewportWidth - .72);
    final entrance =
        (current.cinematic
                ? (current.age - .95) / 1.7
                : current.age / current.arrivalDuration)
            .clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - entrance, 3);
    current.x = (viewportWidth + .3) * (1 - ease) + targetX * ease;
    if (current.cinematic && current.phase == BossPhase.arriving) {
      current.y = .5 - .14 * math.sin(entrance * math.pi);
    }
    if (current.phase != BossPhase.attacking) return;
    final fightingFor = current.age - current.arrivalDuration;
    current.y = current.isMoth
        ? .5 + math.sin(fightingFor * 1.15) * .15
        : current.isSpitter
        ? .5 + math.sin(fightingFor * 1.05) * .13
        : .5 + math.sin(fightingFor * .85) * .10;
    current.fireIn -= dt;
    if (current.fireIn <= 0) {
      final muzzleX = current.muzzleX;
      final aim = math.atan2(birdY - current.y, birdX - muzzleX);
      for (final offset in current.volleyOffsets) {
        final speed = current.projectileSpeed;
        bossAmmo.add(
          BossAmmo(
            x: muzzleX,
            y: current.y,
            vx: math.cos(aim + offset) * speed,
            vy: math.sin(aim + offset) * speed,
          ),
        );
      }
      current.volleys++;
      current.lastVolleyAt = current.age;
      current.fireIn += current.volleyInterval;
    }
    current.summonIn -= dt;
    if (current.summonIn <= 0) {
      final appearance = current.isMoth
          ? EnemyKind.duskMoth.index
          : current.isSpitter
          ? EnemyKind.spitterBeetle.index
          : _enemyAppearance(current.summons, bossHelper: true);
      enemies.add(
        SkyEnemy(
          // Helpers enter from the right like ordinary enemies. Older replays
          // retain the original summon position and shooter approach time.
          x: rulesVersion >= 25
              ? viewportWidth + _enemyEntryMargin
              : rulesVersion >= 18 &&
                    (current.isSpitter ||
                        current.isMoth ||
                        current.summons % 3 != 0)
              ? math.max(current.x - .16, birdX + 1.0)
              : current.x - .16,
          y: current.summons.isEven ? .3 : .7,
          appearance: appearance,
          maxHp: _enemyHealth(appearance),
          flightPhase: rulesVersion >= 20
              ? (current.number * 11 + current.summons) * 2.399963
              : null,
        ),
      );
      current.summons++;
      current.lastSummonAt = current.age;
      current.summonIn += current.summonInterval;
    }
  }

  void _defeatBoss(SkyBoss current) {
    current.defeatedAt = current.age;
    bossesDefeated++;
    bossAmmo.clear();
    enemyAmmo.clear();
    enemies.clear();
    final bonus = isTrail ? bossBonus : 0;
    score += bonus;
    if (isTrail) shield = true;
    _event(FlightEventKind.bossDefeated, bonus);
  }

  void _advanceHearts(double travel) {
    heartPickups.removeWhere((heart) {
      heart.x -= travel;
      final dx = birdX - heart.x, dy = birdY - heart.y;
      if (dx * dx + dy * dy <= SkyHeart.pickupRadius * SkyHeart.pickupRadius) {
        if (hearts < maxHearts) {
          hearts++;
          _event(FlightEventKind.heart, 1);
        }
        return true;
      }
      return heart.x < birdX - SkyHeart.pickupRadius;
    });
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
        if (hasGlideCharge) {
          final extended = math.min(
            maxGlideSeconds,
            _glideRemaining + starGlideSeconds,
          );
          if (extended > _glideRemaining) lastGlideStarAt = elapsed;
          _glideRemaining = extended;
        }
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

  bool _touches(Obstacle o) =>
      _circleTouchesObstacle(birdX, birdY, birdRadius, o);

  bool _circleTouchesDoor(double x, double y, double radius, Obstacle o) {
    if (o.door == null || o.door!.destroyed) return false;
    final dx = x - x.clamp(o.x, o.x + o.width);
    final dy = y - y.clamp(o.top, o.bottom);
    return dx * dx + dy * dy <= radius * radius;
  }

  bool _circleTouchesObstacle(
    double x,
    double y,
    double radius,
    Obstacle o, {
    bool includeDoor = true,
  }) {
    if (includeDoor && _circleTouchesDoor(x, y, radius, o)) return true;
    bool circleRect(ObstaclePassage passage, double top, double bottom) {
      if (bottom <= top) return false;
      final nearX = x.clamp(passage.x, passage.x + passage.width);
      final nearY = y.clamp(top, bottom);
      final dx = x - nearX, dy = y - nearY;
      return dx * dx + dy * dy <= radius * radius;
    }

    if (o.orbs.any((orb) {
      final dx = x - orb.x, dy = y - orb.y;
      final reach = radius + orb.radius;
      return dx * dx + dy * dy <= reach * reach;
    })) {
      return true;
    }
    return o.passages.any(
      (p) => circleRect(p, 0, p.top) || circleRect(p, p.bottom, 1),
    );
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
