enum BossPhase { arriving, attacking, defeated }

enum BossKind { baronBat, spitterBeetle, duskMoth }

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
    }
  }

  static int healthFor(BossKind kind, int number) => switch (kind) {
    BossKind.baronBat => 120 + (number - 1).clamp(0, 4) * 30,
    BossKind.spitterBeetle => 180 + (number - 2).clamp(0, 4) * 30,
    BossKind.duskMoth => 240 + (number - 3).clamp(0, 4) * 30,
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
  String get name => switch (kind) {
    BossKind.baronBat => 'Baron Bat',
    BossKind.spitterBeetle => 'Spitter King',
    BossKind.duskMoth => 'Dusk Empress',
  };
  String get title => switch (kind) {
    BossKind.baronBat => 'LORD OF THE STORM',
    BossKind.spitterBeetle => 'BREWER OF THE SWARM',
    BossKind.duskMoth => 'KEEPER OF THE TWILIGHT VEIL',
  };
  double get muzzleOffset => radius * (isSpitter || isMoth ? 1.05 : 1);
  double get muzzleX => x - muzzleOffset;
  double get projectileSpeed => switch (kind) {
    BossKind.baronBat => enraged ? .57 : .48,
    BossKind.spitterBeetle => enraged ? .66 : .56,
    BossKind.duskMoth => enraged ? .72 : .62,
  };
  double get volleyInterval => switch (kind) {
    BossKind.baronBat => enraged ? 1.55 : 2.15,
    BossKind.spitterBeetle => enraged ? 1.3 : 1.8,
    BossKind.duskMoth => enraged ? 1.2 : 1.65,
  };
  double get summonInterval => switch (kind) {
    BossKind.baronBat => enraged ? 4.5 : 6,
    BossKind.spitterBeetle => enraged ? 3.8 : 4.8,
    BossKind.duskMoth => enraged ? 3.6 : 4.6,
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
  };
  static const radius = .115;
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
  });
  double x, y;
  final double vx, vy;
  static const radius = .021;
}
