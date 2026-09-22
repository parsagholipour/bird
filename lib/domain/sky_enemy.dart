import 'dart:math' as math;

enum EnemyAttack { none, aimed, fan }

enum EnemyKind { caveBat, spitterBeetle, duskMoth, simpleBat }

/// Small opponents share a hit radius, but have different attack rhythms.
/// All clocks advance with simulation time so pause and replay stay exact.
class SkyEnemy {
  SkyEnemy({
    required this.x,
    required this._y,
    this.appearance = 0,
    this.flightPhase,
    int? maxHp,
  }) : maxHp = maxHp ?? healthFor(appearance) {
    if (this.maxHp <= 0) throw ArgumentError.value(this.maxHp, 'maxHp');
    hp = this.maxHp;
  }

  /// Later encounters toughen the lineup without changing enemies in flight.
  static int healthFor(int appearance, {int bossesDefeated = 0}) {
    final base = switch (EnemyKind.values[appearance %
        EnemyKind.values.length]) {
      EnemyKind.caveBat || EnemyKind.simpleBat => 10,
      EnemyKind.spitterBeetle => 20,
      EnemyKind.duskMoth => 30,
    };
    return base + bossesDefeated.clamp(0, 4) * 5;
  }

  final int maxHp;
  late int hp;
  double lastHitAt = double.negativeInfinity;
  int takeDamage(int damage) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    final before = hp;
    hp = (hp - damage).clamp(0, maxHp);
    if (hp < before) lastHitAt = age;
    return before - hp;
  }

  double x;
  final double _y;
  // Null preserves the original straight flight in older recordings.
  final double? flightPhase;
  final int appearance;
  static const radius = .045, warningSeconds = .75;
  double age = 0, fireIn = 1.1;
  double lastShotAt = double.negativeInfinity;
  int volleys = 0;
  bool preparing = false;
  double flightRoom = 1;

  EnemyKind get kind => EnemyKind.values[appearance % EnemyKind.values.length];
  EnemyAttack get attack => switch (kind) {
    EnemyKind.caveBat || EnemyKind.simpleBat => EnemyAttack.none,
    EnemyKind.spitterBeetle => EnemyAttack.aimed,
    EnemyKind.duskMoth => EnemyAttack.fan,
  };
  double get _flightTime => age + (flightPhase ?? 0);
  double get _flightRate => switch (kind) {
    EnemyKind.simpleBat => 2.8,
    EnemyKind.caveBat => 3.2,
    EnemyKind.spitterBeetle => 3.8,
    EnemyKind.duskMoth => 2.2,
  };
  double get _steadiness =>
      (1 - .75 * math.max(charge, recoil)) *
      flightRoom *
      flightRoom *
      (3 - 2 * flightRoom);

  /// The drawn body, hit circle and emitted ammo all follow the same small
  /// flight arc. Shooters steady themselves through windup and discharge.
  double get y {
    if (flightPhase == null) return _y;
    final amplitude = switch (kind) {
      EnemyKind.simpleBat => .011,
      EnemyKind.caveBat => .010,
      EnemyKind.spitterBeetle => .007,
      EnemyKind.duskMoth => .014,
    };
    final t = _flightTime;
    final bob =
        math.sin(t * _flightRate) * .8 +
        math.sin(t * _flightRate * .57 + .8) * .2;
    return _y + amplitude * bob * _steadiness;
  }

  double get flightBank => flightPhase == null
      ? 0
      : (math.cos(_flightTime * _flightRate) * .055 +
                math.sin(_flightTime * 1.1) * .015) *
            _steadiness;

  /// Small tempo variation and per-spawn phase prevent synchronized flapping.
  double get wingTime => flightPhase == null
      ? age + appearance * .83
      : _flightTime + math.sin(_flightTime * 1.6) * .035;

  double get muzzleX => x - radius * 1.05;
  double get charge =>
      preparing ? (1 - fireIn / warningSeconds).clamp(0.0, 1.0) : 0;
  double get recoil => (1 - (age - lastShotAt) / .24).clamp(0.0, 1.0);
}

class EnemyAmmo {
  EnemyAmmo({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.attack,
  });
  double x, y;
  final double vx, vy;
  final EnemyAttack attack;
  static const radius = .016;
}
