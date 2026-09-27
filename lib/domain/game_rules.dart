import 'dart:math' as math;
import 'tracking.dart';
import 'flight_course.dart';
import 'bird_motion.dart';
import 'flight_path.dart';
import 'obstacle.dart';
import 'power_shot.dart';
import 'rush_path.dart';
import 'sky_boss.dart';
import 'sky_enemy.dart';
import 'sky_door.dart';
import 'sprint.dart';
export 'flight_course.dart';
export 'flight_path.dart';
export 'obstacle.dart';
export 'power_shot.dart';
export 'rush_path.dart';
export 'sky_boss.dart';
export 'sky_enemy.dart';
export 'sky_door.dart';
export 'sprint.dart';

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
  starTrio,
  enemyHit,
  enemyRammed,
  bossDefeated,
  heart,
  rushWarning,
  sprintRing,
  smashed,
  meteorSmashed,
  scorched,
  rushEscaped,
  swarmSmashed,
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
  double? collectedAt, collectedY;
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
  // Freeze the last star's height on collection; its aura still scrolls with x.
  double? completedY;
  static const bonus = 5;
  bool collected(int slot) => collectedMask & (1 << slot) != 0;
}

class BirdRock {
  BirdRock({
    required this.x,
    required this.y,
    this.damage = baseDamage,
    this.charge = 0,
  }) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    if (!(charge >= 0 && charge <= 1)) {
      throw ArgumentError.value(charge, 'charge');
    }
  }
  double x, y;
  double velocityX = speed, velocityY = 0;
  double? reboundAge;
  bool get rebounding => reboundAge != null;
  // A shot retains the weapon's damage at the instant it was fired.
  final int damage;
  final double charge;
  double get radius => baseRadius * PowerShot.radiusScale(charge);
  static const baseDamage = 10;
  static const baseRadius = .014, speed = 1.65;
  static const reboundGravity = 1.8;

  /// The wall absorbs most of the shot's energy. Its spent shell falls away
  /// without damaging another target or cancelling incoming ammo.
  void rebound(double scrollSpeed) {
    if (rebounding) return;
    reboundAge = 0;
    velocityX = -(speed + scrollSpeed) * .45 - scrollSpeed;
    velocityY = -.18;
  }

  void advance(double dt) {
    x += velocityX * dt;
    if (!rebounding) return;
    y += velocityY * dt + .5 * reboundGravity * dt * dt;
    velocityY += reboundGravity * dt;
    reboundAge = reboundAge! + dt;
  }
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
    required this.practice,
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
  }) : gates = gates ?? score;
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
    required this.practice,
    this.course = FlightCourse.classic,
    this.rulesVersion = currentRulesVersion,
    int weaponDamage = BirdRock.baseDamage,
    math.Random? random,
  }) : random = random ?? math.Random() {
    setWeaponDamage(weaponDamage);
  }
  final GameMode rules;
  final bool practice;
  final FlightCourse course;

  /// Replay journals keep the rules they were recorded with.
  static const currentRulesVersion = 32;
  final int rulesVersion;
  final math.Random random;
  final List<Obstacle> obstacles = [];
  final List<SkyStar> stars = [];
  final List<StarTrio> starTrios = [];
  final List<SkyHeart> heartPickups = [];
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
  int dryFires = 0;
  double lastShotCharge = 0;
  double lastShotAt = double.negativeInfinity;
  static const shotCooldown = .28;
  bool get supportsPowerShots => supportsCombat && rulesVersion >= 28;

  /// Share of the ammo reserve left, from 0 to 1. See [PowerShot].
  double ammo = 1;
  double? chargeStartedAt;

  /// Reserve at the moment the current press started. Refill changes [ammo]
  /// while the button is held, and the 500 ms full-charge window has to
  /// start from when the shot could first reach full power.
  double? _chargeAmmo;

  // A charge only exists while its press can still be released into a shot.
  bool get charging => chargeStartedAt != null && phase == RunPhase.playing;
  bool get outOfAmmo => supportsPowerShots && !PowerShot.canAfford(ammo);

  /// Continuous power of the held shot, limited by what the reserve can pay.
  double get shotCharge {
    if (!charging) return 0;
    final held = (elapsed - chargeStartedAt!) / PowerShot.fullChargeSeconds;
    return math.min(held.clamp(0.0, 1.0), PowerShot.affordable(ammo));
  }

  /// When the held shot first reached charge 1, or null if it has not.
  double? get _fullChargeAt {
    final started = chargeStartedAt;
    final ammoThen = _chargeAmmo;
    if (!charging || started == null || ammoThen == null) return null;
    final byTime = started + PowerShot.fullChargeSeconds;
    final at = PowerShot.affordable(ammoThen) >= 1
        ? byTime
        : math.max(
            byTime,
            math.max(started, lastShotAt + PowerShot.refillDelay) +
                (PowerShot.fullCost - ammoThen) / PowerShot.refillPerSecond,
          );
    return elapsed + 1e-9 >= at ? at : null;
  }

  /// 1 until the shot is fully charged, then the share of the 500 ms
  /// window still left. At 0 the shot releases itself.
  double get fullHoldLeft {
    final at = _fullChargeAt;
    if (at == null) return 1;
    return ((PowerShot.maxFullHoldSeconds - (elapsed - at)) /
            PowerShot.maxFullHoldSeconds)
        .clamp(0.0, 1.0);
  }

  bool get _fullHoldExpired {
    final at = _fullChargeAt;
    return at != null &&
        shotCharge >= 1 - 1e-9 &&
        elapsed - at >= PowerShot.maxFullHoldSeconds - 1e-9;
  }

  void _endCharge() {
    chargeStartedAt = null;
    _chargeAmmo = null;
  }

  double get shotCost => PowerShot.cost(shotCharge);
  int _weaponDamage = BirdRock.baseDamage;
  int get weaponDamage => supportsWeaponDamage ? _weaponDamage : 1;

  /// Live upgrades should go through FlightRecorder.setWeaponDamage so seeks
  /// restore the same weapon and shots already in flight keep their damage.
  void setWeaponDamage(int damage) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    _weaponDamage = damage;
  }

  bool get supportsCombat =>
      rules.mode == PlayMode.touch && rulesVersion >= 7;
  double get shotCooldownRemaining =>
      math.max(0, lastShotAt + shotCooldown - elapsed);
  bool get _combatReady =>
      supportsCombat && !bossCutscene && phase == RunPhase.playing;
  bool get canShoot => _combatReady && shotCooldownRemaining == 0 && !outOfAmmo;

  /// A press may start charging during the cooldown or while the reserve
  /// refills; [shoot] decides at release whether the rock can be fired.
  bool get canCharge => supportsPowerShots && _combatReady && !charging;

  bool get supportsSprint => supportsCombat && rulesVersion >= 29;
  double lastSprintAt = double.negativeInfinity;
  int sprints = 0;
  double get sprintAge => elapsed - lastSprintAt;
  bool get sprinting => supportsSprint && sprintAge < Sprint.seconds;
  double get sprintRemaining => sprinting ? Sprint.seconds - sprintAge : 0;
  double get sprintCooldownRemaining => supportsSprint
      ? math.max(0, lastSprintAt + Sprint.cooldown - elapsed)
      : 0;
  bool get canSprint =>
      supportsSprint && _combatReady && sprintCooldownRemaining == 0;

  double get sprintBoost => sprinting ? Sprint.boost(sprintAge) : 1;

  bool get supportsRushPaths => supportsSprint && isTrail && rulesVersion >= 32;
  RushPath? rushPath;
  double _nextRushAt = Rush.firstAt;
  final List<SprintRing> sprintRings = [];
  final List<Meteor> meteors = [];
  final List<LavaVent> lavaVents = [];
  final List<SwarmBat> swarm = [];

  /// Kinds still to run this round, drawn from the end by [Rush.nextKind]
  /// with the flight's seeded random.
  final List<RushPathKind> rushKinds = [];

  /// The latest run's kind, which outlasts the run for its escape banner.
  RushPathKind? lastRushKind;
  int rushPathsRun = 0, rushWarnings = 0, rushPathsEscaped = 0;
  int ringSprints = 0, ringChain = 0;
  int smashes = 0, smashChain = 0, meteorsSmashed = 0;
  int ventsErupted = 0, swarmSmashed = 0;
  double ringSprintFrom = double.negativeInfinity;
  double ringSprintUntil = double.negativeInfinity;
  bool get ringSprinting =>
      elapsed >= ringSprintFrom && elapsed < ringSprintUntil;
  double get _ringEnvelope => ringSprinting
      ? RingSprint.envelope(elapsed - ringSprintFrom, ringSprintUntil - elapsed)
      : 0;
  double get ringSprintBoost => 1 + (RingSprint.peakBoost - 1) * _ringEnvelope;
  double get ringSprintRemaining =>
      ringSprinting ? ringSprintUntil - elapsed : 0;

  /// Multiplies [speed] for everything that scrolls with the course.
  double get courseBoost => math.max(sprintBoost, ringSprintBoost);

  /// Either sprint smashes bats, stone panels and rubble.
  bool get ramming => sprinting || ringSprinting;
  bool get _rushHoldsSpawns => rushPath?.holdsSpawns ?? false;
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
  bool shield = true;
  double invulnerableUntil = 0;
  double get recoveryRemaining =>
      isTrail ? math.max(0, invulnerableUntil - elapsed) : 0;
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
  bool get endless => rulesVersion >= 12;
  bool get timed => !endless && course.legacyTimed;
  bool get collectsStars => course.collectsStars;
  bool get supportsStarTrios => collectsStars && rulesVersion >= 6;
  bool get subtleStarRewards => collectsStars && rulesVersion >= 30;
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
      endless ? 1 + .65 * (1 - math.exp(-elapsed / 240)) : 1;
  double get speed => endless
      ? rules.speedFor(0) * (isTrail ? .9 : 1) * paceMultiplier
      : isTrail
      ? rules.speedFor(gates) * .9
      : rules.speedFor(score);
  int get _difficulty => endless ? (elapsed / 20).floor() : gates;
  double get gap => supportsCombat
      ? rules.gapFor(_difficulty)
      : isTrail
      ? math.min(.48, rules.gapFor(_difficulty) + .09)
      : rules.gapFor(endless ? _difficulty : score);
  // The leading star group occupies .42 height units before its gate.
  // At the slowest trail speed, this allowance leaves at least a calibrated
  // half-cycle between clearing one gate and reaching the next pickup halo.
  double get spawnInterval {
    final interval =
        rules.intervalFor(collectsStars ? gates : score) +
        (supportsCombat
            ? (isTrail ? .25 : 0)
            : isTrail
            ? 1.3
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

  bool startCharge() {
    if (!canCharge) return false;
    chargeStartedAt = elapsed;
    _chargeAmmo = ammo;
    return true;
  }

  /// The cooldown runs from the press, on the same clock as the burst.
  bool sprint() {
    if (!canSprint) return false;
    lastSprintAt = elapsed;
    sprints++;
    return true;
  }

  /// Releases the held charge, or fires a tapped rock when nothing is held.
  /// A full charge also calls this on its own once it has been held for
  /// [PowerShot.maxFullHoldSeconds].
  bool shoot({bool reducedMotion = false}) {
    final charge = shotCharge;
    _endCharge();
    if (!canShoot) {
      if (_combatReady && outOfAmmo) dryFires++;
      return false;
    }
    final origin = shotOrigin(charge, reducedMotion: reducedMotion);
    rocks.add(
      BirdRock(
        x: origin.x,
        y: origin.y,
        damage: supportsPowerShots
            ? PowerShot.damage(weaponDamage, charge)
            : weaponDamage,
        charge: charge,
      ),
    );
    if (supportsPowerShots) {
      ammo = math.max(0, ammo - PowerShot.cost(charge));
    }
    lastShotAt = elapsed;
    lastShotCharge = charge;
    shots++;
    return true;
  }

  /// A charging rock grows forward from the beak, so a larger rock covers no
  /// more of the bird than a tapped one. It fires from where it was drawn.
  ({double x, double y}) shotOrigin(
    double charge, {
    bool reducedMotion = false,
  }) {
    final mouth = BirdFlightMotion.mouth(
      velocity: velocity,
      sinceFlap: elapsed - lastFlapAt,
      reducedMotion: reducedMotion,
    );
    final lead = BirdRock.baseRadius * (PowerShot.radiusScale(charge) - 1);
    return (x: birdX + mouth.x + lead, y: birdY + mouth.y);
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
      velocity = rules.flapImpulse;
      lastFlapAt = elapsed;
      flaps++;
      if (supportsJumpGlide) {
        // Refresh the base allowance without erasing time earned from stars.
        _glideRemaining = math.max(_glideRemaining, jumpGlideSeconds);
      }
    }
  }

  void tick(
    double dt,
    double nowMs, {
    double viewportWidth = 2.2,
    bool reducedMotion = false,
  }) {
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
      // A sprint covers the same course sooner, so spawning follows distance
      // and passages keep their spacing.
      final boost = courseBoost;
      final scroll = speed * boost;
      distance += scroll * step;
      if (supportsBosses) _advanceBoss(step, viewportWidth);
      if (bossCutscene) {
        // Let the player watch the reveal and victory without falling into a
        // boundary. No input queues up to launch the bird when control returns.
        birdY += (.52 - birdY) * (1 - math.exp(-step * 3));
        birdY = birdY.clamp(birdRadius + .001, 1 - birdRadius - .001);
        velocity = 0;
        _endCharge();
      } else if (!rules.mode.controlsHeight) {
        if (smoothJumpDescent && velocity >= 0) {
          _advanceJumpDescent(step);
        } else {
          velocity += rules.gravity * step;
          if (gliding) {
            // The upward boost keeps its original height. Only the descent uses
            // the banked glide, so a player gets the full rest after takeoff.
            velocity = math.min(velocity, glideFallSpeed);
            _glideRemaining = math.max(0, _glideRemaining - step);
          }
        }
        birdY += velocity * step;
      }
      if (boss == null) _spawnIn -= step * boost;
      for (final obstacle in obstacles) {
        obstacle.x -= scroll * step;
        obstacle.advance(elapsed);
      }
      if (boss == null && !_rushHoldsSpawns && _spawnIn <= 0) {
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
        if (!collectsStars) {
          end(EndReason.collision);
          break;
        }
        _damage();
        birdY = birdY.clamp(birdRadius + .001, 1 - birdRadius - .001);
        velocity = 0;
      }
      flightPath.record(distance, birdY);
      if (!ramming) smashChain = 0;
      for (final o in obstacles) {
        if (phase == RunPhase.ended) break;
        if (ramming) {
          _ramPanel(o);
          _smashObstacle(o);
        }
        if (!o.hit && _touches(o)) {
          if (!isTrail) {
            end(EndReason.collision);
            break;
          }
          o.hit = true;
          _damage();
        }
        if (o.x < birdX + birdRadius && o.x + o.width > birdX - birdRadius) {
          o.maxDeviation = math.max(o.maxDeviation, (birdY - o.target).abs());
        }
        if (!o.scored && o.x + o.width < birdX - birdRadius) {
          o.scored = true;
          if (!o.hit && !o.rubble) {
            gates++;
            if (!collectsStars) score++;
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
        _advanceStars(scroll * step);
      }
      if (supportsHeartPickups && phase == RunPhase.playing) {
        _advanceHearts(scroll * step);
      }
      if (supportsRushPaths && phase == RunPhase.playing) {
        _advanceRushPath(step, scroll, viewportWidth);
      }
      if (supportsCombat && phase == RunPhase.playing) {
        _advanceCombat(step, scroll, viewportWidth, rush: scroll - speed);
        if (_fullHoldExpired) shoot(reducedMotion: reducedMotion);
      }
      if (supportsRushPaths && phase == RunPhase.playing) {
        _scheduleRushPath(viewportWidth);
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

  /// [rush] is a sprint's extra scroll speed. Hostile ammo closes on the
  /// charging bird that much faster, while a boss holds its place on screen.
  void _advanceCombat(
    double dt,
    double scrollSpeed,
    double viewportWidth, {
    required double rush,
  }) {
    if (supportsPowerShots && elapsed - lastShotAt >= PowerShot.refillDelay) {
      ammo = math.min(1, ammo + PowerShot.refillPerSecond * dt);
    }
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
      final previousX = rock.x;
      rock.advance(dt);
      if (rock.rebounding) continue;
      void hitWall() {
        if (rulesVersion >= 31) {
          // Back out of this substep's penetration before returning left.
          // The wall has also scrolled since the previous clear position.
          rock.x = previousX - scrollSpeed * dt;
          rock.rebound(scrollSpeed);
        } else {
          spent.add(rock);
        }
        rockImpacts++;
      }

      // The same small physics steps used for buildings also prevent rocks
      // tunneling through enemies, even when a rendered frame is slow.
      if (obstacles.any(
        (o) => _circleTouchesObstacle(
          rock.x,
          rock.y,
          rock.radius,
          o,
          includeDoor: false,
        ),
      )) {
        hitWall();
        continue;
      }
      for (final obstacle in obstacles) {
        if (!_circleTouchesDoor(rock.x, rock.y, rock.radius, obstacle)) {
          continue;
        }
        final seal = obstacle.door!;
        hitWall();
        seal.takeDamage(rock.damage, hitY: rock.y);
        if (seal.destroyed) doorsDestroyed++;
        break;
      }
      if (spent.contains(rock) || rock.rebounding) continue;
      for (final enemy in enemies) {
        final dx = rock.x - enemy.x, dy = rock.y - enemy.y;
        final radius = rock.radius + SkyEnemy.radius;
        if (dx * dx + dy * dy > radius * radius) continue;
        spent.add(rock);
        enemy.takeDamage(supportsWeaponDamage ? rock.damage : enemy.hp);
        if (enemy.hp > 0) {
          rockImpacts++;
          break;
        }
        enemies.remove(enemy);
        _defeatEnemy(enemy);
        break;
      }
      final target = boss;
      if (!spent.contains(rock) && target?.phase == BossPhase.attacking) {
        final dx = rock.x - target!.x, dy = rock.y - target.y;
        final reach =
            rock.radius +
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
      (rock) =>
          spent.contains(rock) ||
          rock.x > viewportWidth + .2 ||
          (rock.rebounding && (rock.x < -.2 || rock.y > 1.2)),
    );
    enemies.removeWhere((enemy) {
      final dx = birdX - enemy.x, dy = birdY - enemy.y;
      const radius = birdRadius + SkyEnemy.radius;
      if (dx * dx + dy * dy <= radius * radius) {
        if (ramming) {
          _defeatEnemy(enemy, rammed: true);
        } else if (isTrail) {
          _damage();
        } else {
          end(EndReason.collision);
        }
        return true;
      }
      return enemy.x < -.1;
    });
    if (supportsEnemyAttacks) {
      _advanceEnemyAttacks(dt, viewportWidth, rush);
    }
    bossAmmo.removeWhere((ammo) {
      ammo.x += (ammo.vx - rush) * dt;
      ammo.y += ammo.vy * dt;
      final dx = birdX - ammo.x, dy = birdY - ammo.y;
      const reach = birdRadius + BossAmmo.radius;
      if (dx * dx + dy * dy <= reach * reach) {
        if (isTrail) {
          _damage();
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

  void _advanceEnemyAttacks(double dt, double viewportWidth, double rush) {
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
      ammo.x += (ammo.vx - rush) * dt;
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
        if (rock.rebounding) continue;
        final dx = rock.x - ammo.x, dy = rock.y - ammo.y;
        final reach = rock.radius + EnemyAmmo.radius;
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
      } else {
        end(EndReason.collision);
      }
      return true;
    });
  }

  void _advanceBoss(double dt, double viewportWidth) {
    if (boss == null) {
      // Passages resume before a run ends; the boss waits for the escape.
      if (elapsed < _nextBossAt || rushPath != null) return;
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
      sprintRings.clear();
      meteors.clear();
      lavaVents.clear();
      swarm.clear();
      rushPath = null;
      events.clear();
    }
    final current = boss!;
    current.age += dt;
    if (current.phase == BossPhase.defeated) {
      if (current.age - current.defeatedAt! >= current.departureDuration) {
        boss = null;
        // A full normal-flight interval follows the victory celebration.
        _nextBossAt = elapsed + bossInterval;
        if (supportsRushPaths) _nextRushAt = elapsed + Rush.afterBoss;
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

  /// A ram ignores the enemy's remaining health; the reward is the same.
  void _defeatEnemy(SkyEnemy enemy, {bool rammed = false}) {
    enemiesDefeated++;
    if (rammed) smashChain++;
    final bonus = isTrail ? 3 : 0;
    score += bonus;
    events.add(
      FlightEvent(
        rammed ? FlightEventKind.enemyRammed : FlightEventKind.enemyHit,
        elapsed,
        enemy.y,
        value: bonus,
        gateWorldX: distance + enemy.x,
      ),
    );
  }

  /// Only the panel breaks; the wall around it keeps its normal collision.
  void _ramPanel(Obstacle o) {
    final panel = o.door;
    if (panel == null || !_circleTouchesDoor(birdX, birdY, birdRadius, o)) {
      return;
    }
    panel.takeDamage(panel.hp, hitY: birdY);
    doorsDestroyed++;
  }

  /// Any sprint breaks rubble; a ring sprint smashes ordinary walls too.
  /// The bow wave breaks the whole barrier as the bird passes, through its
  /// opening or not, so a sprint leaves nothing standing behind it.
  void _smashObstacle(Obstacle o) {
    if (o.smashed || !(o.rubble || ringSprinting)) return;
    const reach = birdRadius + Rush.ramReach;
    if (birdX + reach < o.x || birdX - reach > o.x + o.width) return;
    o.smashedAt = elapsed;
    o.smashY = birdY;
    smashes++;
    smashChain++;
    score += Rush.smashPoints;
    events.add(
      FlightEvent(
        FlightEventKind.smashed,
        elapsed,
        birdY,
        value: smashChain,
        gateWorldX: distance + o.x,
      ),
    );
  }

  /// Laid once everything else has scrolled this step, so its rings, bats
  /// and barriers keep their spacing.
  void _scheduleRushPath(double viewportWidth) {
    if (rushPath != null || boss != null || elapsed < _nextRushAt) return;
    _nextRushAt = double.infinity;
    // Too close to a boss: the next run follows the victory instead.
    if (_nextBossAt - elapsed >= Rush.bossLead) {
      rushPath = _layRushPath(viewportWidth);
    }
  }

  void _advanceRushPath(double dt, double scroll, double viewportWidth) {
    final travel = scroll * dt;
    sprintRings.removeWhere((ring) {
      ring.x -= travel;
      final dx = birdX - ring.x, dy = birdY - ring.y;
      if (!ring.collected &&
          dx * dx + dy * dy <=
              SprintRing.pickupRadius * SprintRing.pickupRadius) {
        ring.collected = true;
        ring.collectedAt = elapsed;
        _ringSprint();
      }
      return ring.x < -.2;
    });
    _advanceMeteors(dt, scroll);
    _advanceVents(travel);
    _advanceSwarm(dt, scroll);
    final path = rushPath;
    if (path == null) return;
    if (!path.resumed && distance >= path.resumeDistance) {
      path.resumed = true;
      _spawnIn = 0;
      _previousCenter = path.exitCenter;
    }
    final bird = distance + birdX;
    switch (path.phase) {
      case RushPhase.approach:
        if (!path.warned && path.startDistance - bird <= Rush.warningLead) {
          path.warned = true;
          rushWarnings++;
          _event(FlightEventKind.rushWarning, path.kind.index);
        }
        if (bird >= path.startDistance) {
          path.phase = RushPhase.running;
          path.startedAt = elapsed;
          path.fireDistance = bird - Rush.fireStartGap;
          path.meteorIn = Rush.firstMeteorDelay;
          path.flockIn = Rush.firstFlockDelay;
        }
      case RushPhase.running:
        switch (path.kind) {
          case RushPathKind.wildfire:
            _advanceFire(path, dt, bird);
          case RushPathKind.skyfall:
            _advanceSkyfall(path, dt, bird);
          case RushPathKind.eruption:
            // Vents are laid with the run and rumble on their own.
            break;
          case RushPathKind.swarm:
            _releaseFlocks(path, dt, viewportWidth);
        }
        if (phase == RunPhase.playing && bird >= path.endDistance) {
          _escape(path);
        }
      case RushPhase.escaped:
        if (elapsed - path.escapedAt! >= Rush.burnOutSeconds) rushPath = null;
    }
  }

  /// Six beats: a star group leads into a sprint ring at the same height,
  /// then a rubble barrier whose gap sits at the next beat's height. Odd
  /// beats put a bat right after the ring, where a ring sprint smashes it.
  RushPath _layRushPath(double viewportWidth) {
    final kind = lastRushKind = Rush.nextKind(rushKinds, random, lastRushKind);
    final last = obstacles.lastOrNull;
    final startX = math.max(
      viewportWidth + .1,
      last == null ? 0.0 : last.x + last.width + Rush.clearance,
    );
    var lane = _previousCenter.clamp(.3, .7);
    final heights = [lane];
    for (var i = 0; i < Rush.beats; i++) {
      final change = .16 + random.nextDouble() * .16;
      var next = lane + (random.nextBool() ? change : -change);
      if (next < .24 || next > .76) next = 2 * lane - next;
      lane = next.clamp(.24, .76);
      heights.add(lane);
    }
    for (var i = 0; i < Rush.beats; i++) {
      final base = startX + i * Rush.beatLength, y = heights[i];
      final trio = StarTrio(x: base + .22, y: y);
      starTrios.add(trio);
      for (var k = 0; k < 3; k++) {
        stars.add(
          SkyStar(x: base + .05 + k * .17, y: y, trio: trio, trioSlot: k),
        );
      }
      sprintRings.add(SprintRing(x: base + Rush.ringAt, y: y));
      if (kind == RushPathKind.eruption && i > 0) {
        lavaVents.add(
          LavaVent(
            x: base + Rush.ventAt,
            top: math.max(y - Rush.ventOver, Rush.ventCeiling),
          ),
        );
      }
      if (i.isOdd) {
        final appearance = (i ~/ 2).isEven
            ? EnemyKind.simpleBat.index
            : EnemyKind.caveBat.index;
        enemies.add(
          SkyEnemy(
            x: base + Rush.batAt,
            y: y,
            appearance: appearance,
            maxHp: _enemyHealth(appearance),
            flightPhase: (rushPathsRun * 7 + i) * 2.399963,
          ),
        );
      }
      obstacles.add(
        Obstacle(
          x: base + Rush.barrierAt,
          center: heights[i + 1],
          gap: Rush.barrierGap,
          width: Rush.barrierWidth,
          target: heights[i + 1],
          fixedTarget: true,
          // The material follows the run: three shapes per path kind.
          appearance: kind.index * 3 + i % 3,
          bornAt: elapsed,
          rubble: true,
        ),
      );
    }
    final start = distance + startX;
    final end =
        start +
        (Rush.beats - 1) * Rush.beatLength +
        Rush.barrierAt +
        Rush.barrierWidth +
        birdRadius;
    rushPathsRun++;
    return RushPath(
      kind: kind,
      number: rushPathsRun,
      startDistance: start,
      endDistance: end,
      resumeDistance:
          end + Rush.exitClearance - _passageEntryX(viewportWidth),
      heights: heights,
    );
  }

  void _ringSprint() {
    final chained = ringSprinting;
    ringSprintFrom = elapsed - RingSprint.surgeAgeFor(_ringEnvelope);
    ringSprintUntil = elapsed + RingSprint.seconds;
    ringSprints++;
    ringChain = chained ? ringChain + 1 : 1;
    rushPath?.rings++;
    _event(FlightEventKind.sprintRing, ringChain);
  }

  /// A caught bird is hurt and knocks the fire back, so one catch cannot
  /// repeat before it recovers. A ring sprint drags it along behind.
  void _advanceFire(RushPath path, double dt, double bird) {
    path.fireDistance += speed * Rush.fireChase * dt;
    if (ringSprinting) {
      path.fireDistance = math.max(path.fireDistance, bird - Rush.fireMaxGap);
    }
    if (bird - path.fireDistance > birdRadius) return;
    path.fireDistance = bird - Rush.fireKnockback;
    if (elapsed < invulnerableUntil) return;
    path.catches++;
    _damage();
    _event(FlightEventKind.scorched);
  }

  /// Meteors alternate between the ring route and a random height. An aimed
  /// meteor leads the bird at its current speed, so a cruising bird on the
  /// route has to dodge and a sprinting one smashes through. The rest
  /// scatter across the course where a cruising bird would be.
  void _advanceSkyfall(RushPath path, double dt, double bird) {
    path.meteorIn -= dt;
    if (path.meteorIn > 0) return;
    path.meteorIn += Rush.meteorInterval;
    final aimed = path.meteors.isEven;
    path.meteors++;
    const lead = Rush.meteorLead;
    final pace = speed * (aimed ? courseBoost : 1);
    final targetY = aimed
        ? path.routeY(bird + pace * lead).clamp(.12, .88)
        : .12 + random.nextDouble() * .76;
    meteors.add(
      Meteor(
        x: birdX + pace * lead + Rush.meteorDrift,
        y: Rush.meteorTop,
        vx: -Rush.meteorDrift / lead,
        vy: (targetY - Rush.meteorTop) / lead,
        aimed: aimed,
      ),
    );
  }

  void _advanceMeteors(double dt, double scroll) {
    meteors.removeWhere((m) {
      m.age += dt;
      m.x += (m.vx - scroll) * dt;
      m.y += m.vy * dt;
      final dx = birdX - m.x, dy = birdY - m.y;
      final reach =
          birdRadius + Meteor.radius + (ramming ? Rush.ramReach : 0);
      if (dx * dx + dy * dy <= reach * reach) {
        if (ramming) {
          smashChain++;
          _smashMeteor(m, chain: smashChain);
        } else {
          _damage();
        }
        return true;
      }
      for (final rock in rocks) {
        if (rock.rebounding) continue;
        final rx = rock.x - m.x, ry = rock.y - m.y;
        final hit = rock.radius + Meteor.radius;
        if (rx * rx + ry * ry <= hit * hit) {
          rocks.remove(rock);
          rockImpacts++;
          _smashMeteor(m);
          return true;
        }
      }
      return m.y > 1 + Meteor.radius || m.x < -.2;
    });
  }

  void _smashMeteor(Meteor m, {int chain = 0}) {
    meteorsSmashed++;
    score += Rush.meteorPoints;
    events.add(
      FlightEvent(
        FlightEventKind.meteorSmashed,
        elapsed,
        m.y,
        value: chain,
        gateWorldX: distance + m.x,
      ),
    );
  }

  /// Lava cannot be smashed, only outrun or flown over. The fuse is timed
  /// from course speed, so a sprinting bird has passed before a vent blows.
  void _advanceVents(double travel) {
    lavaVents.removeWhere((vent) {
      vent.x -= travel;
      if (vent.rumbledAt == null && vent.x - birdX <= speed * Rush.ventFuse) {
        vent.rumbledAt = elapsed;
      }
      if (vent.rumbling &&
          (elapsed >= vent.fuseEndsAt! || birdX - vent.x >= Rush.ventBehind)) {
        vent.eruptedAt = elapsed;
        ventsErupted++;
      }
      final top = vent.plumeTop(elapsed);
      if (top < 1 && elapsed >= invulnerableUntil) {
        const half = LavaVent.width / 2;
        final dx = birdX - birdX.clamp(vent.x - half, vent.x + half);
        final dy = birdY - birdY.clamp(top, 1.0);
        if (dx * dx + dy * dy <= birdRadius * birdRadius) {
          rushPath?.catches++;
          _damage();
          _event(FlightEventKind.scorched);
        }
      }
      return vent.x < -.2;
    });
  }

  /// Flocks alternate between the ring route and a random side of it.
  void _releaseFlocks(RushPath path, double dt, double viewportWidth) {
    path.flockIn -= dt;
    if (path.flockIn > 0) return;
    path.flockIn += Rush.flockInterval;
    final lane = path.flocks.isEven
        ? 0.0
        : random.nextBool()
        ? Rush.flockLane
        : -Rush.flockLane;
    path.flocks++;
    for (var k = 0; k < Rush.flockSize; k++) {
      final x = viewportWidth + .1 + k * Rush.flockSpacing;
      if (distance + x > path.endDistance) break;
      swarm.add(
        SwarmBat(
          x: x,
          y: path.routeY(distance + x) + lane,
          route: path,
          lane: lane,
          phase: (path.flocks * Rush.flockSize + k) * 2.399963,
        ),
      );
    }
  }

  void _advanceSwarm(double dt, double scroll) {
    swarm.removeWhere((bat) {
      bat.age += dt;
      bat.x -= (scroll + Rush.swarmSpeed) * dt;
      bat.y =
          bat.route.routeY(distance + bat.x) +
          bat.lane +
          .012 * math.sin(bat.age * 9 + bat.phase);
      final dx = birdX - bat.x, dy = birdY - bat.y;
      final reach =
          birdRadius + SwarmBat.radius + (ramming ? Rush.ramReach : 0);
      if (dx * dx + dy * dy <= reach * reach) {
        if (ramming) {
          smashChain++;
          _smashBat(bat, chain: smashChain);
        } else {
          _damage();
        }
        return true;
      }
      for (final rock in rocks) {
        if (rock.rebounding) continue;
        final rx = rock.x - bat.x, ry = rock.y - bat.y;
        final hit = rock.radius + SwarmBat.radius;
        if (rx * rx + ry * ry <= hit * hit) {
          rocks.remove(rock);
          rockImpacts++;
          _smashBat(bat);
          return true;
        }
      }
      return bat.x < -.2;
    });
  }

  void _smashBat(SwarmBat bat, {int chain = 0}) {
    swarmSmashed++;
    score += Rush.batPoints;
    events.add(
      FlightEvent(
        FlightEventKind.swarmSmashed,
        elapsed,
        bat.y,
        value: chain,
        gateWorldX: distance + bat.x,
      ),
    );
  }

  void _escape(RushPath path) {
    path.phase = RushPhase.escaped;
    path.escapedAt = elapsed;
    path.bonus = Rush.escapeBonus + (path.hurt ? 0 : Rush.flawlessBonus);
    score += path.bonus;
    rushPathsEscaped++;
    _event(FlightEventKind.rushEscaped, path.bonus);
    _nextBossAt = math.max(_nextBossAt, elapsed + Rush.bossDelayAfter);
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
        star.collectedAt = elapsed;
        star.collectedY = star.y;
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
            trio.completedY = trio.y;
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
    if (rushPath?.phase == RushPhase.running) rushPath!.hurt = true;
    if (shield) {
      shield = false;
      _event(FlightEventKind.shieldUsed);
    } else {
      hearts--;
      _event(FlightEventKind.hit);
      if (hearts <= 0) end(EndReason.collision);
    }
  }

  void _event(FlightEventKind kind, [int value = 0]) =>
      events.add(FlightEvent(kind, elapsed, birdY, value: value));

  bool _touches(Obstacle o) =>
      _circleTouchesObstacle(birdX, birdY, birdRadius, o);

  bool _circleTouchesDoor(double x, double y, double radius, Obstacle o) {
    if (o.door == null || o.door!.destroyed || o.smashed) return false;
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
    if (o.smashed) return false;
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
    _endCharge();
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
