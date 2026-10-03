import 'dart:math' as math;

import 'alley_pigeon.dart';
import 'king_coo.dart';

export 'alley_pigeon.dart';

/// [crumb] (rules version 45) is the stale crust King Coo's vanguard
/// pigeons throw: one aimed shot, slower than a beetle's seed. Append, never
/// reorder.
enum EnemyAttack { none, aimed, fan, crumb }

/// Declaration order is the appearance index that saved plans and replays
/// rely on: append, never reorder. [alleyPigeon] joins in rules version 43
/// and only campaign level plans lay it ([campaignOnly]). [mummyBat] joins
/// in rules version 52: Neferhoo's helpers, which only his tougher fight
/// sends (no lineup names one).
enum EnemyKind {
  caveBat,
  spitterBeetle,
  duskMoth,
  simpleBat,
  alleyPigeon,
  mummyBat;

  /// Kinds that only a campaign level's lineup (or a campaign boss) can
  /// bring. No endless lineup holds one, at any rules version.
  bool get campaignOnly => switch (this) {
    alleyPigeon || mummyBat => true,
    caveBat || spitterBeetle || duskMoth || simpleBat => false,
  };
}

/// Small opponents share a hit radius, but have different attack rhythms.
/// All clocks advance with simulation time so pause and replay stay exact.
class SkyEnemy {
  SkyEnemy({
    required this.x,
    required this._y,
    this.appearance = 0,
    this.flightPhase,
    this.drift = 1,
    this.sender,
    int? maxHp,
    this.squad = false,
    this.throwsCrumbs = false,
  }) : maxHp = maxHp ?? healthFor(appearance),
       pigeon = !squad && _kindOf(appearance) == EnemyKind.alleyPigeon
           ? PigeonFlight()
           : null {
    if (this.maxHp <= 0) throw ArgumentError.value(this.maxHp, 'maxHp');
    hp = this.maxHp;
  }

  static EnemyKind _kindOf(int appearance) =>
      EnemyKind.values[appearance % EnemyKind.values.length];

  /// Later encounters toughen the lineup without changing enemies in flight.
  static int healthFor(int appearance, {int bossesDefeated = 0}) {
    final base = switch (_kindOf(appearance)) {
      EnemyKind.caveBat ||
      EnemyKind.simpleBat ||
      EnemyKind.alleyPigeon ||
      EnemyKind.mummyBat => 10,
      EnemyKind.spitterBeetle => 20,
      EnemyKind.duskMoth => 30,
    };
    return base + bossesDefeated.clamp(0, 4) * 5;
  }

  final int maxHp;
  late int hp;
  double lastHitAt = double.negativeInfinity;

  /// Health just before the latest damaging hit. Presentation only: the
  /// health bar drains the lost chunk from this value.
  late int hpBeforeLastHit = maxHp;
  int takeDamage(int damage) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    final before = hp;
    hp = (hp - damage).clamp(0, maxHp);
    if (hp < before) {
      lastHitAt = age;
      hpBeforeLastHit = before;
    }
    return before - hp;
  }

  double x;
  double _y;
  // Null preserves the original straight flight in older recordings.
  final double? flightPhase;
  final int appearance;

  /// Fraction of the scroll speed this enemy closes in at. Only the helpers
  /// of a boss's debut encounter drift slower ([debutDrift]).
  final double drift;
  static const debutDrift = .6;

  /// The duel player whose mystery box sent this enemy after their rival,
  /// or null for an ordinary one. It flies through its sender.
  final int? sender;
  static const radius = .045, warningSeconds = .75;
  double age = 0, fireIn = 1.1;
  double lastShotAt = double.negativeInfinity;
  int volleys = 0;
  bool preparing = false;
  double flightRoom = 1;

  EnemyKind get kind => _kindOf(appearance);

  /// An Alley Pigeon that flies on King Coo's squadron track instead of
  /// raiding stars (rules version 43): no prey, no [pigeon] raid state.
  /// The squadron rules (R2) set its position directly.
  final bool squad;

  /// One of King Coo's vanguard pigeons from rules version 45: it winds up
  /// and throws a crust at the bird ([EnemyAttack.crumb]) as it crosses.
  final bool throwsCrumbs;

  /// A thrown crust's speed, and the seconds between a pigeon's throws.
  static const crumbSpeed = .40, crumbInterval = 2.2;

  /// The raid state of an Alley Pigeon that goes for stars, or null for every
  /// other enemy and for squadron pigeons. See [PigeonFlight]; the art, the
  /// audio and the UI read it, the pigeon rules (R1) drive it.
  final PigeonFlight? pigeon;

  /// Whether this enemy steals stars (rules version 43).
  bool get snatches => pigeon != null;

  /// Puts the enemy at [x] with [y] as the height its flight bob rides on.
  /// Only the rules that steer an enemy off the plain course (a pigeon's
  /// raid) call this.
  void placeAt(double x, double y) {
    this.x = x;
    _y = y;
  }

  /// King Coo's squadron track, set for a [squad] pigeon while it flies (see
  /// [SquadTrack]). The squadron rules set [x] and [y] from it on every
  /// step; the pigeon holds its lane exactly (no bob), so the hit circle is
  /// the lane the boss planned.
  SquadTrack? track;

  EnemyAttack get attack => switch (kind) {
    // A raiding pigeon fires nothing: it takes stars.
    EnemyKind.alleyPigeon =>
      throwsCrumbs ? EnemyAttack.crumb : EnemyAttack.none,
    // A mummy bat only flies at the bird, as a simple bat does.
    EnemyKind.caveBat ||
    EnemyKind.simpleBat ||
    EnemyKind.mummyBat => EnemyAttack.none,
    EnemyKind.spitterBeetle => EnemyAttack.aimed,
    EnemyKind.duskMoth => EnemyAttack.fan,
  };
  double get _flightTime => age + (flightPhase ?? 0);
  double get _flightRate => switch (kind) {
    // A mummy bat flies the simple bat's arc (its bandages are art only).
    EnemyKind.simpleBat || EnemyKind.mummyBat => 2.8,
    EnemyKind.caveBat => 3.2,
    EnemyKind.spitterBeetle => 3.8,
    EnemyKind.duskMoth => 2.2,
    EnemyKind.alleyPigeon => 2.6,
  };
  double get _steadiness =>
      (1 - .75 * math.max(charge, recoil)) *
      flightRoom *
      flightRoom *
      (3 - 2 * flightRoom);

  /// The drawn body, hit circle and emitted ammo all follow the same small
  /// flight arc. Shooters steady themselves through windup and discharge.
  double get y {
    if (flightPhase == null || track != null) return _y;
    final amplitude = switch (kind) {
      EnemyKind.simpleBat || EnemyKind.mummyBat => .011,
      EnemyKind.caveBat => .010,
      EnemyKind.spitterBeetle => .007,
      EnemyKind.duskMoth => .014,
      EnemyKind.alleyPigeon => AlleyPigeon.bob,
    };
    final t = _flightTime;
    final bob =
        math.sin(t * _flightRate) * .8 +
        math.sin(t * _flightRate * .57 + .8) * .2;
    return _y + amplitude * bob * _steadiness;
  }

  set y(double value) => _y = value;

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
  double get charge {
    // A pigeon's telegraph is its 0.80 s warning (see [AlleyPigeon]).
    final raid = pigeon;
    if (raid != null) return raid.warning(age);
    return preparing ? (1 - fireIn / warningSeconds).clamp(0.0, 1.0) : 0;
  }

  double get recoil => (1 - (age - lastShotAt) / .24).clamp(0.0, 1.0);
}

class EnemyAmmo {
  EnemyAmmo({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.attack,
    this.bornAt = double.negativeInfinity,
    this.sender,
  });
  double x, y;
  final double vx, vy;
  final EnemyAttack attack;

  /// The duel player who sent the enemy that fired it ([SkyEnemy.sender]).
  /// It only hits that player's rival.
  final int? sender;

  /// Simulation time at launch, for the launch pop only. Render-only: no
  /// rule reads it, so it cannot change collisions, scoring or replays.
  final double bornAt;
  static const radius = .016;
}

/// Why a pellet stopped short of leaving the screen.
enum AmmoStop { blocked, deflected, struck }

/// Where a pellet stopped, kept for a moment so it can splash instead of
/// vanishing. Render-only: the rules write these but never read them.
class EnemyAmmoImpact {
  const EnemyAmmoImpact({
    required this.x,
    required this.y,
    required this.worldX,
    required this.birdY,
    required this.direction,
    required this.attack,
    required this.stop,
    required this.at,
  });

  /// Screen and world position at impact; a struck pellet follows the bird.
  final double x, y, worldX, birdY;
  final double direction, at;
  final EnemyAttack attack;
  final AmmoStop stop;
}

/// Where a charged rock shattered a pellet, kept for a moment so the blast
/// can play out. Render-only: the rules write these but never read them.
class AmmoShatter {
  const AmmoShatter({
    required this.x,
    required this.y,
    required this.worldX,
    required this.reach,
    required this.charge,
    required this.direction,
    required this.attack,
    required this.at,
  });

  /// Screen and world position of the blast; it stays with the scenery.
  final double x, y, worldX;

  /// The blast radius. An enemy is caught when its hit circle touches it.
  final double reach;

  /// The shattering rock's charge and the pellet's heading when it broke.
  final double charge, direction, at;
  final EnemyAttack attack;
}
