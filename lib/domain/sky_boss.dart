import 'dart:math' as math;

import 'baron_screech.dart';
import 'dragon_breath.dart';

export 'baron_screech.dart';
export 'dragon_breath.dart';

enum BossPhase { arriving, attacking, defeated }

/// Declaration order is the encounter order; [BossKind.pirate] joins the
/// cycle in rules version 34 and [BossKind.dragon] in rules version 38.
enum BossKind { baronBat, spitterBeetle, duskMoth, pirate, dragon }

/// Encounter time advances only with the simulation, including in replays.
class SkyBoss {
  SkyBoss({
    required this.number,
    required this.x,
    this.cinematic = false,
    this.kind = BossKind.baronBat,
    this.wideSpitterFans = true,
    this.debut = false,
    this.callsSwarm = true,
    this.upgraded = false,
    int? maxHp,
  }) : maxHp = maxHp ?? healthFor(kind, number) {
    if (this.maxHp <= 0) throw ArgumentError.value(this.maxHp, 'maxHp');
    hp = this.maxHp;
    if (screeches) {
      // The upgraded Baron sends his bats in pairs on the screech's clock.
      summonIn = double.infinity;
    } else if (isSpitter) {
      fireIn = 1;
      summonIn = 4;
    } else if (isMoth) {
      fireIn = 1;
      summonIn = 3.8;
    } else if (isPirate) {
      // The captain fights with his cannon and the tide, not a crew.
      fireIn = 1.4;
      summonIn = double.infinity;
    } else if (isDragon) {
      // The dragon summons no helpers: fireballs, its breath and, from rules
      // version 39, the flocks it calls on the breath's clock.
      fireIn = 1.3;
      summonIn = double.infinity;
    }
  }

  /// Older rules keep the Spitter King's original 180 HP start
  /// ([tougherSpitter] false); from rules version 37 it starts at 210.
  static int healthFor(
    BossKind kind,
    int number, {
    bool tougherSpitter = true,
  }) => switch (kind) {
    BossKind.baronBat => 120 + (number - 1).clamp(0, 4) * 30,
    BossKind.spitterBeetle =>
      (tougherSpitter ? 210 : 180) + (number - 2).clamp(0, 4) * 30,
    BossKind.duskMoth => 240 + (number - 3).clamp(0, 4) * 30,
    BossKind.pirate => 300 + (number - 4).clamp(0, 4) * 30,
    BossKind.dragon => 360 + (number - 5).clamp(0, 4) * 30,
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

  /// The first time this kind meets the bird in a flight, from rules version
  /// 37: the Dusk Empress fights without her silk shield and her helpers
  /// drift in slower ([SkyEnemy.debutDrift]). Later encounters bring the full
  /// fight.
  final bool debut;

  /// Baron Bat returns upgraded, from rules version 40 on every encounter
  /// after his [debut]: he screeches (see [BaronScreech]) and sends his small
  /// bats in pairs. Only a Baron Bat is ever upgraded.
  final bool upgraded;
  bool get screeches => kind == BossKind.baronBat && upgraded;
  bool get isSpitter => kind == BossKind.spitterBeetle;
  bool get isMoth => kind == BossKind.duskMoth;
  bool get isPirate => kind == BossKind.pirate;
  bool get isDragon => kind == BossKind.dragon;
  String get name => switch (kind) {
    BossKind.baronBat => 'Baron Bat',
    BossKind.spitterBeetle => 'Spitter King',
    BossKind.duskMoth => 'Dusk Empress',
    BossKind.pirate => 'Pirate Captain',
    BossKind.dragon => 'Ember Dragon',
  };
  String get title => switch (kind) {
    BossKind.baronBat => upgraded ? 'THE STORM RETURNS' : 'LORD OF THE STORM',
    BossKind.spitterBeetle => 'BREWER OF THE SWARM',
    BossKind.duskMoth => 'KEEPER OF THE TWILIGHT VEIL',
    BossKind.pirate => 'TERROR OF THE HIGH TIDE',
    BossKind.dragon => 'SOVEREIGN OF THE BURNING SKY',
  };
  double get muzzleOffset => radius * (isSpitter || isMoth ? 1.05 : 1);
  double get muzzleX => x - muzzleOffset;
  double get projectileSpeed => switch (kind) {
    BossKind.baronBat => enraged ? .57 : .48,
    BossKind.spitterBeetle => enraged ? .66 : .56,
    BossKind.duskMoth => enraged ? .72 : .62,
    // Horizontal speed only: cannonballs fly on a ballistic arc.
    BossKind.pirate => enraged ? .6 : .5,
    BossKind.dragon => enraged ? .62 : .52,
  };
  double get volleyInterval => switch (kind) {
    BossKind.baronBat => enraged ? 1.55 : 2.15,
    BossKind.spitterBeetle => enraged ? 1.3 : 1.8,
    BossKind.duskMoth => enraged ? 1.2 : 1.65,
    BossKind.pirate => enraged ? 1.5 : 2.1,
    BossKind.dragon => enraged ? 1.55 : 2.0,
  };
  double get summonInterval => switch (kind) {
    BossKind.baronBat => enraged ? 4.5 : 6,
    BossKind.spitterBeetle => enraged ? 3.8 : 4.8,
    BossKind.duskMoth => enraged ? 3.6 : 4.6,
    BossKind.pirate || BossKind.dragon => double.infinity,
  };
  List<double> get volleyOffsets => switch (kind) {
    BossKind.baronBat =>
      enraged || volleys.isOdd ? const [-.24, 0, .24] : const [0],
    BossKind.spitterBeetle =>
      wideSpitterFans
          // Leave one slot out of full fans as a dodge lane.
          ? enraged || volleys.isOdd
                ? [
                    for (var i = 0; i < acidFan.length; i++)
                      if (i != openSlot) acidFan[i],
                  ]
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
    // A fireball at the bird, then a pair that brackets it. In fury the
    // lone fireball splits into embers ([splitsVolley]).
    BossKind.dragon => volleys.isEven ? const [0] : const [-.22, .22],
  };
  static const radius = .115;

  /// The five aimed slots of a full acid fan, in radians from the aim.
  static const acidFan = [-.60, -.30, 0.0, .30, .60];

  /// The slot of [acidFan] aimed straight at the bird.
  static const centerSlot = 2;

  /// Slots of [acidFan] that may be left open. The outer two are never
  /// chosen: their lane would sit at the very edge of the fan.
  static const openableSlots = [1, centerSlot, 3];

  /// The slot of [acidFan] a full fan leaves out. The center slot, the only
  /// one before rules version 37, keeps the lane on the aim point; newer
  /// rules choose it from the seeded random before every volley.
  int openSlot = centerSlot;

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

  // ---------------------------------------------------------------------
  // Ember Dragon: fireballs from its jaws, and a breath that burns a band
  // of the sky on a fixed combat-time cycle (see [DragonBreath]).

  /// The dragon's jaws, from its heart (the hit circle) in screen heights:
  /// fireballs are born here. The art opens the jaws on this point.
  static const dragonMouth = (-.293, -.215);
  double get mouthX => x + dragonMouth.$1;
  double get mouthY => y + dragonMouth.$2;

  /// A splitting fireball bursts into embers this long after it leaves the
  /// jaws, well short of the bird, at [emberSpread] radians either side.
  static const emberSplitAfter = .45, emberSpread = .5;

  /// After a breath the jaws stay empty at least this long, so the next
  /// fireball gets its whole charge.
  static const dragonRefire = .9;

  /// While the dragon breathes its heart lies open and every hit on it
  /// counts this many times over.
  static const coreMultiplier = 2;

  double get _breathCycle => _combatTime % DragonBreath.period;
  bool get _dragonFighting => isDragon && phase == BossPhase.attacking;

  /// The band the current (or last) breath scorches. The rules aim it once,
  /// as each warning begins ([breathsAimed] catches up with [breaths]).
  BreathLane breathLane = BreathLane.middle;
  int breathsAimed = 0;

  /// 0 to 1 through the inhale before each blast, 0 otherwise.
  double get breathWarning =>
      _dragonFighting ? DragonBreath.warning(_breathCycle) : 0;

  /// Whether the flame burns now: touching its band hurts.
  bool get breathing => _dragonFighting && DragonBreath.blasting(_breathCycle);

  /// From the inhale to the end of the flame the heart lies open.
  bool get breathBusy => _dragonFighting && DragonBreath.busy(_breathCycle);
  bool get coreExposed => breathBusy;

  /// No fireballs from a second before the inhale to the end of the flame.
  bool get breathQuiet => _dragonFighting && DragonBreath.quiet(_breathCycle);

  /// Breaths whose warning has begun, and blasts that have been loosed,
  /// for edge-triggered cues and for aiming.
  int get breaths => _dragonFighting
      ? DragonBreath.count(_combatTime, DragonBreath.warnAt)
      : 0;
  int get breathBlasts => _dragonFighting
      ? DragonBreath.count(_combatTime, DragonBreath.blastAt)
      : 0;

  /// Whether a circle at [py] with [pr] reaches into the burning band.
  bool scorches(double py, double pr) =>
      breathing && DragonBreath.scorches(breathLane, py, pr);

  /// In fury, away from its debut, the lone fireball splits into embers.
  bool get splitsVolley => isDragon && enraged && !debut && volleys.isEven;

  /// From rules version 39 ([callsSwarm]) the dragon calls a flock of swarm
  /// bats, the swarm rush path's own, as each flame gutters out,
  /// [swarmCallAt] into the breath cycle. In fury, away from its debut, a
  /// second flock follows [swarmFollowAfter] later. The rules aim each flock
  /// at the bird's height as it is called, and both have flown past before
  /// the next inhale.
  static const swarmCallAt = 7.6, swarmFollowAfter = 1.4;
  final bool callsSwarm;

  /// Calls and follow-ups whose time has come. The rules release a flock as
  /// [swarmCalls] and [swarmFollows] catch up with them.
  int get swarmCallsDue => _dragonFighting && callsSwarm
      ? DragonBreath.count(_combatTime, swarmCallAt)
      : 0;
  int get swarmFollowsDue => _dragonFighting && callsSwarm
      ? DragonBreath.count(_combatTime, swarmCallAt + swarmFollowAfter)
      : 0;
  int swarmCalls = 0, swarmFollows = 0;

  /// Whether a follow-up flock due now takes wing.
  bool get swarmFollowsUp => enraged && !debut;

  /// Rules damage for a hit worth [damage]: doubled on the open heart.
  int strike(int damage) {
    if (!coreExposed) return takeDamage(damage);
    lastCoreHitAt = age;
    return takeDamage(damage * coreMultiplier);
  }

  /// How long after a call [breathHint] names the swarm.
  static const swarmHintSeconds = 2.5;

  /// Render-only: when a hit last landed on the open heart.
  double lastCoreHitAt = double.negativeInfinity;

  String get breathHint {
    final warning = breathWarning;
    if (warning > 0 || breathing) {
      final dodge = switch (breathLane) {
        BreathLane.high => 'Fly low!',
        BreathLane.middle => 'Climb or dive!',
        BreathLane.low => 'Fly high!',
      };
      return warning > 0
          ? "DRAGON'S BREATH · $dodge Its heart is open"
          : 'FIRE · $dodge Strike the glowing heart';
    }
    if (age - lastSummonAt < swarmHintSeconds) {
      return 'SWARM · Dodge the bats or sprint through them';
    }
    return enraged
        ? debut
              ? 'FURY · Faster fireballs'
              : 'FURY · Fireballs burst into embers'
        : 'Dodge the fireballs · Watch for the breath';
  }

  // ---------------------------------------------------------------------
  // Baron Bat, upgraded: a sonic screech on a fixed combat-time cycle (see
  // [BaronScreech]) and small bats sent in pairs on the same clock.

  double get _screechCycle => _combatTime % BaronScreech.period;
  bool get _screechFighting => screeches && phase == BossPhase.attacking;

  /// Where the current (or last) screech leaves its gap. The rules aim it
  /// once, as each warning begins ([screechesAimed] catches up with
  /// [screechWarnings]).
  ScreechGap screechGap = ScreechGap.middle;
  int screechesAimed = 0;

  /// The screech leaves his mouth, like his fireballs.
  double get screechOriginX => muzzleX;

  /// 0 to 1 through the warning before each screech, 0 otherwise.
  double get screechWarning =>
      _screechFighting ? BaronScreech.warning(_screechCycle) : 0;

  /// Whether the wall of sound is sweeping the sky now.
  bool get screeching =>
      _screechFighting && BaronScreech.sweeping(_screechCycle);

  /// The wall's leading edge in screen x while [screeching], else null.
  double? get screechFront =>
      screeching ? BaronScreech.front(screechOriginX, _screechCycle) : null;

  /// The open part of the sky the current screech leaves, as (top, bottom).
  (double, double) get screechOpening =>
      BaronScreech.opening(screechGap, fury: enraged);

  /// No fireballs from [BaronScreech.quietBefore] ahead of the warning until
  /// the screech has gone.
  bool get screechQuiet =>
      _screechFighting && BaronScreech.quiet(_screechCycle);

  /// Screeches whose warning has begun, and screeches that have left his
  /// mouth, for edge-triggered cues and for aiming.
  int get screechWarnings => _screechFighting
      ? BaronScreech.count(_combatTime, BaronScreech.warnAt)
      : 0;
  int get screechBlasts => _screechFighting
      ? BaronScreech.count(_combatTime, BaronScreech.screechAt)
      : 0;

  /// Whether a circle at [px], [py] with [pr] meets the wall outside the gap.
  bool screechHits(double px, double py, double pr) {
    final front = screechFront;
    return front != null &&
        BaronScreech.reaches(front, px, pr) &&
        BaronScreech.blocked(screechGap, py, pr, fury: enraged);
  }

  /// Pairs of bats whose time has come; the rules send a pair as [batPairs]
  /// and [furyPairs] catch up. A fury pair only takes wing in fury.
  int get batPairsDue => _screechFighting
      ? BaronScreech.count(_combatTime, BaronScreech.pairAt)
      : 0;
  int get furyPairsDue => _screechFighting
      ? BaronScreech.count(_combatTime, BaronScreech.furyPairAt)
      : 0;
  int batPairs = 0, furyPairs = 0;

  String get screechHint {
    if (screechWarning > 0 || screeching) {
      final gap = switch (screechGap) {
        ScreechGap.high => 'high',
        ScreechGap.middle => 'middle',
        ScreechGap.low => 'low',
      };
      return screechWarning > 0
          ? 'SONIC SCREECH · Fly to the $gap gap!'
          : 'SCREECH · Hold the $gap gap';
    }
    return enraged
        ? 'FURY · Faster fireballs, more bats'
        : 'Dodge the fireballs and bats · Watch for the screech';
  }

  static const shieldRadius = radius * 1.85;
  static const shieldPeriod = 8.0, shieldStartsAt = 5.0;
  static const shieldSeconds = 1.6, shieldWarningSeconds = .8;
  // A fixed combat-time cycle gives long openings and survives pause/seek.
  // Fury never changes the cycle or brings a shield up without its warning.
  double get _shieldCycle => (age - arrivalDuration) % shieldPeriod;

  /// Only the Dusk Empress spins a shield, and not on her [debut].
  bool get hasShield => isMoth && !debut;
  bool get shielded =>
      hasShield &&
      phase == BossPhase.attacking &&
      _shieldCycle >= shieldStartsAt &&
      _shieldCycle < shieldStartsAt + shieldSeconds;
  double get shieldWarning =>
      hasShield && phase == BossPhase.attacking && _shieldCycle < shieldStartsAt
      ? ((_shieldCycle - shieldStartsAt + shieldWarningSeconds) /
                shieldWarningSeconds)
            .clamp(0.0, 1.0)
      : 0;
  String get shieldHint => !hasShield
      ? enraged
            ? 'FURY · Seven-shot fans. No veil yet!'
            : 'No veil yet · Fire between the fans!'
      : shielded
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
    this.splitAfter,
    this.ember = false,
  });
  double x, y, vy;
  final double vx;

  /// Downward acceleration; only the Pirate Captain's cannonballs fall.
  final double gravity;
  final double radius;

  /// Seconds of flight before an Ember Dragon fireball bursts into embers,
  /// or null for shots that never split.
  final double? splitAfter;

  /// One of the embers a split fireball bursts into.
  final bool ember;

  /// Seconds in flight, counted only for shots that split.
  double age = 0;
  static const baseRadius = .021, cannonballRadius = .027;
  static const fireballRadius = .025, emberRadius = .016;
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
