import 'dart:math' as math;

enum BossPhase { arriving, attacking, defeated }

/// Declaration order is the encounter order; [BossKind.pirate] joins the
/// cycle in rules version 34.
enum BossKind { baronBat, spitterBeetle, duskMoth, pirate }

/// Encounter time advances only with the simulation, including in replays.
class SkyBoss {
  SkyBoss({
    required this.number,
    required this.x,
    this.cinematic = false,
    this.kind = BossKind.baronBat,
    this.wideSpitterFans = true,
    int? maxHp,
  }) : maxHp = maxHp ?? healthFor(kind, number) {
    if (this.maxHp <= 0) throw ArgumentError.value(this.maxHp, 'maxHp');
    hp = this.maxHp;
    if (isSpitter) {
      fireIn = 1;
      summonIn = 4;
    } else if (isMoth) {
      fireIn = 1;
      summonIn = 3.8;
    } else if (isPirate) {
      // The captain fights with his cannon and the tide, not a crew.
      fireIn = 1.4;
      summonIn = double.infinity;
    }
  }

  static int healthFor(BossKind kind, int number) => switch (kind) {
    BossKind.baronBat => 120 + (number - 1).clamp(0, 4) * 30,
    BossKind.spitterBeetle => 180 + (number - 2).clamp(0, 4) * 30,
    BossKind.duskMoth => 240 + (number - 3).clamp(0, 4) * 30,
    BossKind.pirate => 300 + (number - 4).clamp(0, 4) * 30,
  };

  /// Damage may skip over half health or zero after a weapon upgrade.
  int takeDamage(int damage) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    final before = hp;
    final wasEnraged = enraged;
    hp = (hp - damage).clamp(0, maxHp);
    if (hp < before) {
      lastDamage = before - hp;
      lastHitAt = age;
      if (!wasEnraged && enraged) enragedAt = age;
    }
    return before - hp;
  }

  final BossKind kind;
  // Older replay rules retain the original tightly packed acid fans.
  final bool wideSpitterFans;
  bool get isSpitter => kind == BossKind.spitterBeetle;
  bool get isMoth => kind == BossKind.duskMoth;
  bool get isPirate => kind == BossKind.pirate;
  String get name => switch (kind) {
    BossKind.baronBat => 'Baron Bat',
    BossKind.spitterBeetle => 'Spitter King',
    BossKind.duskMoth => 'Dusk Empress',
    BossKind.pirate => 'Pirate Captain',
  };
  String get title => switch (kind) {
    BossKind.baronBat => 'LORD OF THE STORM',
    BossKind.spitterBeetle => 'BREWER OF THE SWARM',
    BossKind.duskMoth => 'KEEPER OF THE TWILIGHT VEIL',
    BossKind.pirate => 'TERROR OF THE HIGH TIDE',
  };
  double get muzzleOffset => radius * (isSpitter || isMoth ? 1.05 : 1);
  double get muzzleX => x - muzzleOffset;
  double get projectileSpeed => switch (kind) {
    BossKind.baronBat => enraged ? .57 : .48,
    BossKind.spitterBeetle => enraged ? .66 : .56,
    BossKind.duskMoth => enraged ? .72 : .62,
    // Horizontal speed only: cannonballs fly on a ballistic arc.
    BossKind.pirate => enraged ? .6 : .5,
  };
  double get volleyInterval => switch (kind) {
    BossKind.baronBat => enraged ? 1.55 : 2.15,
    BossKind.spitterBeetle => enraged ? 1.3 : 1.8,
    BossKind.duskMoth => enraged ? 1.2 : 1.65,
    BossKind.pirate => enraged ? 1.5 : 2.1,
  };
  double get summonInterval => switch (kind) {
    BossKind.baronBat => enraged ? 4.5 : 6,
    BossKind.spitterBeetle => enraged ? 3.8 : 4.8,
    BossKind.duskMoth => enraged ? 3.6 : 4.6,
    BossKind.pirate => double.infinity,
  };
  List<double> get volleyOffsets => switch (kind) {
    BossKind.baronBat =>
      enraged || volleys.isOdd ? const [-.24, 0, .24] : const [0],
    BossKind.spitterBeetle =>
      wideSpitterFans
          // Remove the center shot from full fans to leave a dodge lane.
          ? enraged || volleys.isOdd
                ? const [-.60, -.30, .30, .60]
                : const [-.30, 0, .30]
          : enraged || volleys.isOdd
          ? const [-.36, -.18, 0, .18, .36]
          : const [-.18, 0, .18],
    BossKind.duskMoth =>
      enraged || volleys.isOdd
          ? const [-.72, -.48, -.24, 0, .24, .48, .72]
          : const [-.48, -.24, 0, .24, .48],
    // Heights around the bird where each cannonball's arc passes: a single
    // shot at the bird, then a pair that brackets it. Fury adds a wide
    // broadside every third volley, but never while the tide squeezes the
    // sky, so a surge always leaves room between the balls.
    BossKind.pirate => switch (volleys % (enraged ? 3 : 2)) {
      0 => const [0],
      2 when tide == 0 => const [-.26, 0, .26],
      _ => const [-.16, .16],
    },
  };
  static const radius = .115;

  // ---------------------------------------------------------------------
  // Pirate Captain: a ship on a rising sea, and a cannon that lobs.
  //
  // The sea fills the bottom of the screen for the whole encounter and
  // touching it hurts like a boundary. On a fixed combat-time cycle the tide
  // warns, surges up to [tidePeak], holds, and falls back to [seaLevel].
  // Like the moth's veil, fury never changes the cycle, so pause and seek
  // stay exact and every surge gets its full warning.

  /// Water surface (screen y, 0 = top) between surges.
  static const seaLevel = .9;

  /// Water surface at the height of a surge.
  static const tidePeak = .56;

  /// Below the screen: where the sea starts and ends the encounter.
  static const seaHidden = 1.12;

  /// The ship floats so the captain's hit circle sits this far above the
  /// water surface. It rides every surge up and back down.
  static const shipRide = .2;

  /// Combat-time cycle: calm, warning, rise, hold, fall, calm.
  static const tidePeriod = 10.0, tideWarnAt = 3.0, tideRiseAt = 4.3;
  static const tidePeakAt = 5.2, tideFallAt = 7.4, tideCalmAt = 8.5;

  /// The hull, in screen heights from the captain's center: only the
  /// captain above the rail can be hurt, and shots lower down glance off.
  static const hullLeft = -.3, hullRight = .34, hullTop = .1;

  /// Whether a shot's leading point at [px], [py] strikes the hull, which
  /// reaches from the rail down into the water.
  bool hullBlocks(double px, double py) =>
      isPirate &&
      py >= y + hullTop &&
      px >= x + hullLeft &&
      px <= x + hullRight;

  /// Cannonballs fall at this rate (screen heights per second squared).
  static const cannonGravity = .8;

  /// The cannon pivots on the bow deck, [cannonPivot] from the captain's
  /// center in screen heights; balls leave the barrel [cannonLength] along
  /// their launch direction.
  static const cannonPivot = (-.14, .085), cannonLength = .075;

  double get _combatTime => age - arrivalDuration;
  double get _tideCycle => _combatTime % tidePeriod;

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// How far the tide stands between [seaLevel] (0) and [tidePeak] (1) at
  /// combat time [t].
  static double _surge(double t) {
    if (t < 0) return 0;
    final cycle = t % tidePeriod;
    if (cycle < tideRiseAt) return 0;
    if (cycle < tidePeakAt) {
      return _smooth((cycle - tideRiseAt) / (tidePeakAt - tideRiseAt));
    }
    if (cycle < tideFallAt) return 1;
    if (cycle < tideCalmAt) {
      return 1 - _smooth((cycle - tideFallAt) / (tideCalmAt - tideFallAt));
    }
    return 0;
  }

  /// 0 to 1 as the surge rises; the rules only read [waterLevel].
  double get tide =>
      isPirate && phase == BossPhase.attacking ? _surge(_combatTime) : 0;

  /// 0 to 1 through the warning before each surge, 0 otherwise.
  double get tideWarning {
    if (!isPirate || phase != BossPhase.attacking) return 0;
    final cycle = _tideCycle;
    if (cycle < tideWarnAt || cycle >= tideRiseAt) return 0;
    return (cycle - tideWarnAt) / (tideRiseAt - tideWarnAt);
  }

  /// Surges whose warning has begun, for edge-triggered cues.
  int get tideSurges => !isPirate || phase != BossPhase.attacking
      ? 0
      : ((_combatTime - tideWarnAt) / tidePeriod).floor() + 1;

  /// Surges that have started rising.
  int get tideRises => !isPirate || phase != BossPhase.attacking
      ? 0
      : ((_combatTime - tideRiseAt) / tidePeriod).floor() + 1;

  /// Water surface in screen y, or null when this boss brings no sea. The
  /// sea rolls in during the arrival and drains away after the defeat.
  double? get waterLevel {
    if (!isPirate) return null;
    final defeated = defeatedAt;
    if (defeated != null) {
      final from =
          seaLevel + (tidePeak - seaLevel) * _surge(defeated - arrivalDuration);
      final t = _smooth((age - defeated) / (departureDuration * .8));
      return from + (seaHidden - from) * t;
    }
    if (age < arrivalDuration) {
      final t = _smooth(age / (arrivalDuration * .55));
      return seaHidden + (seaLevel - seaHidden) * t;
    }
    return seaLevel + (tidePeak - seaLevel) * tide;
  }

  String get tideHint => tideWarning > 0
      ? 'TIDE RISING · Fly high!'
      : tide > 0
      ? 'HIGH TIDE · Stay above the water'
      : enraged
      ? 'FURY · Broadsides between the surges'
      : 'Dodge the cannonballs · Keep out of the water';

  /// Cannon launch toward a point [dy] below the bird's height, from the
  /// captain's current position: the barrel angle, the muzzle and the
  /// velocity whose arc passes through that point. The art aims the barrel
  /// with the same solution.
  ({double angle, double x, double y, double vx, double vy}) cannonShot(
    double targetX,
    double targetY,
  ) {
    final pivotX = x + cannonPivot.$1, pivotY = y + cannonPivot.$2;
    final speed = projectileSpeed;
    ({double vx, double vy}) solve(double fromX, double fromY) {
      final dx = targetX - fromX;
      final time = math.max(.35, dx.abs() / speed);
      return (
        vx: dx.sign * speed,
        vy: (targetY - fromY) / time - cannonGravity * time / 2,
      );
    }

    final aim = solve(pivotX, pivotY);
    var angle = math.atan2(aim.vy, aim.vx);
    final muzzleX = pivotX + math.cos(angle) * cannonLength;
    final muzzleY = pivotY + math.sin(angle) * cannonLength;
    final v = solve(muzzleX, muzzleY);
    angle = math.atan2(v.vy, v.vx);
    return (angle: angle, x: muzzleX, y: muzzleY, vx: v.vx, vy: v.vy);
  }

  static const shieldRadius = radius * 1.85;
  static const shieldPeriod = 8.0, shieldStartsAt = 5.0;
  static const shieldSeconds = 1.6, shieldWarningSeconds = .8;
  // A fixed combat-time cycle gives long openings and survives pause/seek.
  // Fury never changes the cycle or brings a shield up without its warning.
  double get _shieldCycle => (age - arrivalDuration) % shieldPeriod;
  bool get shielded =>
      isMoth &&
      phase == BossPhase.attacking &&
      _shieldCycle >= shieldStartsAt &&
      _shieldCycle < shieldStartsAt + shieldSeconds;
  double get shieldWarning =>
      isMoth && phase == BossPhase.attacking && _shieldCycle < shieldStartsAt
      ? ((_shieldCycle - shieldStartsAt + shieldWarningSeconds) /
                shieldWarningSeconds)
            .clamp(0.0, 1.0)
      : 0;
  String get shieldHint => shielded
      ? 'SHIELDED · Dodge until the veil drops'
      : shieldWarning > 0
      ? 'SHIELD FORMING · Get ready to dodge'
      : enraged
      ? 'FURY · Seven-shot fans. Veil is down!'
      : 'Veil is down · Fire between the fans!';
  static const arrivalSeconds = 2.5, departureSeconds = 2.0;
  static const revealAt = 1.65, roarAt = 2.65, burstAt = .85;
  final bool cinematic;
  double get arrivalDuration => cinematic ? 4.6 : arrivalSeconds;
  double get departureDuration => cinematic ? 3.8 : departureSeconds;
  bool get inCutscene => cinematic && phase != BossPhase.attacking;
  final int number, maxHp;
  late int hp;
  int lastDamage = 0;
  double x, y = .5, age = 0;
  double fireIn = 1.2, summonIn = 5;
  double lastHitAt = double.negativeInfinity;
  double lastShieldHitAt = double.negativeInfinity;
  double lastHullHitAt = double.negativeInfinity;
  double lastVolleyAt = double.negativeInfinity;
  double lastSummonAt = double.negativeInfinity;
  double enragedAt = double.negativeInfinity;
  double? defeatedAt;
  int volleys = 0, summons = 0;

  BossPhase get phase => defeatedAt != null
      ? BossPhase.defeated
      : age < arrivalDuration
      ? BossPhase.arriving
      : BossPhase.attacking;
  bool get enraged => hp <= maxHp / 2;
  double get charge =>
      phase == BossPhase.attacking ? (1 - fireIn / .65).clamp(0.0, 1.0) : 0;
}

class BossAmmo {
  BossAmmo({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.gravity = 0,
    this.radius = baseRadius,
  });
  double x, y, vy;
  final double vx;

  /// Downward acceleration; only the Pirate Captain's cannonballs fall.
  final double gravity;
  final double radius;
  static const baseRadius = .021, cannonballRadius = .027;
  bool get cannonball => gravity > 0;
}

/// Render-only: where a cannonball, or the bird, met the sea. The rules
/// never read it.
class SeaSplash {
  SeaSplash({required this.x, required this.at, this.bird = false});

  /// Screen x; it drifts left with the course like the waves.
  double x;
  final double at;

  /// The bird dipped into the water rather than a cannonball.
  final bool bird;
}
