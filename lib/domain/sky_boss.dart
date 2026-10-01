import 'dart:math' as math;

import 'baron_screech.dart';
import 'dragon_breath.dart';
import 'king_coo.dart';
import 'searchlight_gargoyle.dart';

export 'baron_screech.dart';
export 'dragon_breath.dart';
export 'king_coo.dart';
export 'searchlight_gargoyle.dart';

enum BossPhase { arriving, attacking, defeated }

/// Declaration order is the encounter order; [BossKind.pirate] joins the
/// cycle in rules version 34 and [BossKind.dragon] in rules version 38.
///
/// [kingCoo] and [searchlightGargoyle] (rules version 43) are mini-boss
/// guardians of New York: [campaignOnly], they sit after the endless cycle
/// and only a campaign level plan can name them. Append, never reorder.
enum BossKind {
  baronBat,
  spitterBeetle,
  duskMoth,
  pirate,
  dragon,
  kingCoo,
  searchlightGargoyle;

  /// The endless boss cycle is the first [endlessCycle] kinds, in order.
  static const endlessCycle = 5;

  /// Kinds no endless flight meets, at any rules version.
  bool get campaignOnly => switch (this) {
    kingCoo || searchlightGargoyle => true,
    baronBat || spitterBeetle || duskMoth || pirate || dragon => false,
  };
}

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
    // The mini-bosses arrive and fall in the cinematic staging only.
    assert(!kind.campaignOnly || cinematic, 'mini-bosses are cinematic');
    hp = this.maxHp;
    if (isKingCoo || isGargoyle) {
      // Neither shoots volleys or calls lineup helpers: each fights on a
      // fixed combat-time cycle (see [KingCoo], [SearchlightGargoyle]).
      fireIn = summonIn = double.infinity;
    } else if (screeches) {
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
    // The mini-bosses have one health at every encounter number.
    BossKind.kingCoo => KingCoo.maxHp,
    BossKind.searchlightGargoyle => SearchlightGargoyle.maxHp,
  };

  /// Damage may skip over half health or zero after a weapon upgrade.
  int takeDamage(int damage) {
    if (damage <= 0) throw ArgumentError.value(damage, 'damage');
    final before = hp;
    final wasEnraged = enraged;
    hp = (hp - damage).clamp(0, maxHp);
    if (hp < before) {
      lastDamage = before - hp;
      previousHitAt = lastHitAt;
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
  bool get isKingCoo => kind == BossKind.kingCoo;
  bool get isGargoyle => kind == BossKind.searchlightGargoyle;

  /// A campaign-only guardian: King Coo or the Searchlight Gargoyle.
  bool get isMiniBoss => kind.campaignOnly;
  String get name => switch (kind) {
    BossKind.baronBat => 'Baron Bat',
    BossKind.spitterBeetle => 'Spitter King',
    BossKind.duskMoth => 'Dusk Empress',
    BossKind.pirate => 'Pirate Captain',
    BossKind.dragon => 'Ember Dragon',
    BossKind.kingCoo => 'King Coo',
    BossKind.searchlightGargoyle => 'Searchlight Gargoyle',
  };
  String get title => switch (kind) {
    BossKind.baronBat => upgraded ? 'THE STORM RETURNS' : 'LORD OF THE STORM',
    BossKind.spitterBeetle => 'BREWER OF THE SWARM',
    BossKind.duskMoth => 'KEEPER OF THE TWILIGHT VEIL',
    BossKind.pirate => 'TERROR OF THE HIGH TIDE',
    BossKind.dragon => 'SOVEREIGN OF THE BURNING SKY',
    BossKind.kingCoo => 'COMMISSIONER OF THE CURB',
    BossKind.searchlightGargoyle => 'WATCHMAN OF THE TALLEST TOWER',
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
    // King Coo fires no shots. The Gargoyle's stone feathers fly at this
    // horizontal speed (see [SearchlightGargoyle.featherShot]).
    BossKind.kingCoo => 0,
    BossKind.searchlightGargoyle =>
      enraged
          ? SearchlightGargoyle.furyFeatherSpeed
          : SearchlightGargoyle.featherSpeed,
  };
  double get volleyInterval => switch (kind) {
    BossKind.baronBat => enraged ? 1.55 : 2.15,
    BossKind.spitterBeetle => enraged ? 1.3 : 1.8,
    BossKind.duskMoth => enraged ? 1.2 : 1.65,
    BossKind.pirate => enraged ? 1.5 : 2.1,
    BossKind.dragon => enraged ? 1.55 : 2.0,
    // The mini-bosses never fire volleys: their attacks run on fixed cycles.
    BossKind.kingCoo || BossKind.searchlightGargoyle => double.infinity,
  };
  double get summonInterval => switch (kind) {
    BossKind.baronBat => enraged ? 4.5 : 6,
    BossKind.spitterBeetle => enraged ? 3.8 : 4.8,
    BossKind.duskMoth => enraged ? 3.6 : 4.6,
    BossKind.pirate ||
    BossKind.dragon ||
    BossKind.kingCoo ||
    BossKind.searchlightGargoyle => double.infinity,
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
    BossKind.kingCoo || BossKind.searchlightGargoyle => const [],
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
  /// [releasedAt] is this boss's age as the rock left the bird, when known
  /// ([BirdRock.releasedAt]): the Searchlight Gargoyle judges his lamp then.
  int strike(int damage, {double? releasedAt}) {
    if (isKingCoo) return _strikeCoo(damage);
    if (isGargoyle) return _lampStrike(damage, releasedAt);
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

  // ---------------------------------------------------------------------
  // King Coo, Commissioner of the Curb (rules version 43, campaign only):
  // crumb bombs, a chest that puffs to whistle in a squadron, and a weak
  // point (see [KingCoo]).
  //
  // The clock-driven getters are pure functions of the boss's age. The state
  // below is what the rules latch and count as the fight runs
  // (`king_coo_rules.dart`): crumb bombs locked at fixed cycle times, the
  // puff window, the squadron, and the pop. None of it draws from a random.

  /// Combat seconds: the boss's age less its arrival.
  double get combatTime => age - arrivalDuration;

  bool get _cooFighting => isKingCoo && phase == BossPhase.attacking;

  /// The position in his 14 s cycle, or 0 when he is not fighting.
  double get cooCycle => _cooFighting ? KingCoo.cycleTime(combatTime) : 0;

  /// The cycle number from 0, or -1 when he is not fighting.
  int get cooCycleNumber => _cooFighting ? KingCoo.cycleNumber(combatTime) : -1;

  /// The crumb bombs latched so far, oldest first: where each ring locked
  /// and when. The rules append one at each lock; every phase and radius is
  /// a pure function of the boss's age ([CrumbLob]). Never pruned, so the
  /// counters below only rise; the art reads [liveLobs].
  final List<CrumbLob> lobs = [];

  /// The bombs still to draw: locked and not yet gone, while he fights. A
  /// defeat (or the arrival) leaves none on screen.
  List<CrumbLob> get liveLobs => phase != BossPhase.attacking
      ? const []
      : [
          for (final lob in lobs)
            if (age < lob.crumbsEndAt) lob,
        ];

  /// Rules latches: the cycle whose rings are being locked, how many of its
  /// rings are locked, and whether that cycle locks fury's three (set at its
  /// first ring, so fury changes the next ring pattern cleanly and never
  /// mixes a single and a bracket in one cycle); the puffs planned and
  /// whistles decided so far; how many of the planned squadrons are out;
  /// and whether this cycle's whistle blew.
  int lobCycle = -1, lobsInCycle = 0;
  bool lobFury = false;
  int puffsLatched = 0, whistlesLatched = 0, squadReleased = 0;
  bool squadCalled = false;

  /// Times a crumb cloud caught the bird, and when a hit last landed on the
  /// taut chest (the x2 window). Render-only, like the dragon's
  /// [lastCoreHitAt].
  int crumbHits = 0;
  double lastPuffHitAt = double.negativeInfinity;

  /// Lobs whose ring has locked, whose bomb has been tossed, and whose cloud
  /// has burst, for edge-triggered cues.
  int get lobsLocked => lobs.length;
  int get lobsLaunched => lobs.where((lob) => age >= lob.launchAt).length;
  int get lobBursts => lobs.where((lob) => age >= lob.burstAt).length;

  /// Health lost to puffed hits in the current window; at
  /// [KingCoo.popDamage] the chest pops. The rules reset it as each window
  /// opens.
  int puffDamage = 0;

  /// When the chest last popped (boss age), or null. A pop closes the window
  /// that step and, if the whistle has not blown, cancels the squadron.
  double? poppedAt;

  /// Whistles blown and pops so far, for edge-triggered cues. A pop before
  /// the whistle means it never blows and [whistles] does not rise.
  int whistles = 0, pops = 0;

  /// The squadron (or squadrons) planned as the current puff opened: lanes
  /// fixed then, released at the whistle (see [KingCoo.squad]). Empty until
  /// the rules plan one.
  List<SquadPlan> squad = const [];

  /// The squadron (or squadrons) a pop before the whistle called off: what
  /// [squad] held when the chest popped, kept for the art that dissolves it
  /// (render-only: nothing in the rules reads it). Cleared as the next puff
  /// plans a new one.
  List<SquadPlan> cancelledSquad = const [];

  /// Boss age at which squadron [plan] (one of [squad]) is released: the
  /// whistle of the cycle whose puff planned it, plus its delay. The art's
  /// clock for the lanes and the queue behind him. Whether it is released at
  /// all is [squadCalled].
  double squadReleaseAt(SquadPlan plan) =>
      arrivalDuration +
      math.max(0, puffsLatched - 1) * KingCoo.period +
      KingCoo.whistleAt +
      plan.delay;

  /// Boss age at which the pigeon of [slot] in [plan] crosses screen column
  /// [column] (the bird's), from where he hovers: the time a lane must be
  /// clear by.
  double squadCrossesAt(SquadPlan plan, SquadSlot slot, double column) =>
      squadReleaseAt(plan) + (x + slot.behind - column) / KingCoo.squadSpeed;

  /// Whether the chest popped in the current cycle's window.
  bool get popped {
    final at = poppedAt;
    if (!_cooFighting || at == null) return false;
    final windowStart =
        arrivalDuration + cooCycleNumber * KingCoo.period + KingCoo.puffAt;
    return at >= windowStart;
  }

  /// Puff windows begun and whistles that have come due, from the clock, for
  /// edge-triggered cues (the rules count blown whistles in [whistles]).
  int get puffs => _cooFighting ? KingCoo.count(combatTime, KingCoo.puffAt) : 0;
  int get whistlesDue =>
      _cooFighting ? KingCoo.count(combatTime, KingCoo.whistleAt) : 0;

  /// Whether the chest is taut and rocks count double: the window is open
  /// and he has not popped.
  bool get puffWindow =>
      _cooFighting && KingCoo.windowOpen(cooCycle) && !popped;

  /// How puffed the chest is, 0 (fluffed) to 1 (taut and lit): the art's
  /// channel, which eases to 0 when he pops.
  double get puffAmount =>
      _cooFighting && !popped ? KingCoo.puffAmount(cooCycle) : 0;

  /// A rock's hit on his chest, as [strike] sees it: half damage while he is
  /// fluffed, double in the puff window. Puffed damage adds up; at
  /// [KingCoo.popDamage] the chest pops (the window closes that instant, see
  /// [popped]) and, if the whistle has not blown, there is no squadron.
  int _strikeCoo(int damage) {
    final puffed = puffWindow;
    final dealt = takeDamage(KingCoo.strikeDamage(damage, puffed: puffed));
    if (puffed && dealt > 0) {
      lastPuffHitAt = age;
      puffDamage += dealt;
      if (puffDamage >= KingCoo.popDamage) {
        poppedAt = age;
        pops++;
      }
    }
    return dealt;
  }

  String get cooHint {
    final cycle = cooCycle;
    if (popped) {
      // A pop after the whistle keeps the squadron that is already out.
      final early =
          poppedAt! <
          arrivalDuration + cooCycleNumber * KingCoo.period + KingCoo.whistleAt;
      if (early) return 'POP! · No squadron';
      if (cycle < KingCoo.squadCrossesBy) {
        return 'SQUADRON · Follow the open lane!';
      }
    }
    if (puffWindow) {
      return cycle >= KingCoo.whistleAt
          ? 'SQUADRON · Follow the open lane!'
          : 'PUFFED · Shoot his chest (x2)!';
    }
    if (squadCalled &&
        squad.isNotEmpty &&
        cycle >= KingCoo.whistleAt &&
        cycle < KingCoo.squadCrossesBy) {
      return 'SQUADRON · Follow the open lane!';
    }
    final locked = lobs.any((lob) => age >= lob.lockedAt && age < lob.burstAt);
    if (locked) return 'CRUMB BOMB · Leave the ring!';
    return enraged
        ? 'FURY · Stay between the rings'
        : 'Dodge the crumb bombs · Shoot his chest when it puffs';
  }

  // ---------------------------------------------------------------------
  // Searchlight Gargoyle (rules version 43, campaign only): a perched
  // statue that sweeps a beam across the sky and opens his chest lamp in the
  // vent after each sweep (see [SearchlightGargoyle]).
  //
  // Every getter is a pure function of the boss's age and of what the rules
  // latched as each warning began. The rules (game_rules `_advanceGargoyle`,
  // `_spotted`) aim each sweep once, drop the feathers, and hurt the bird
  // that touches a beam; a hit on the lamp circle takes damage only if the
  // lamp was open as the rock left the bird ([lampOpenAtRelease]), so health,
  // and with it fury, changes only in the vent or in the second or so of the
  // next cycle's perch that the last rocks of the vent are still flying: a
  // fight's fury is constant from each warning (2.0 s) to the end of its sweep.

  bool get _gargoyleFighting => isGargoyle && phase == BossPhase.attacking;

  /// The position in his 9 s cycle, or 0 when he is not fighting.
  double get gargoyleCycle =>
      _gargoyleFighting ? SearchlightGargoyle.cycleTime(combatTime) : 0;

  /// The cycle number from 0, or -1 when he is not fighting.
  int get gargoyleCycleNumber =>
      _gargoyleFighting ? SearchlightGargoyle.cycleNumber(combatTime) : -1;

  /// Where the current (or last) sweep comes from and whether it is fury's
  /// slit of two beams. The rules aim it once, as each warning begins
  /// ([sweepsAimed] catches up with [sweepWarnings]); these are the latches.
  BeamSide beamSide = BeamSide.high;
  bool slitSweep = false;
  int sweepsAimed = 0;

  /// Counters the rules keep: zone and slit sweeps aimed (every sweep is
  /// one or the other, so they add up to [sweepsAimed]), stone feathers
  /// launched, and the last time (boss age) a rock glanced off the shuttered
  /// lamp. All render-only or cue-only except [sweepsAimed].
  int sweepZone = 0, sweepSlit = 0, feathersLaunched = 0;
  double lastGlanceAt = double.negativeInfinity;

  /// Times the bird was caught in a beam and hurt by it (a bird still
  /// recovering from a hurt is not counted again). Render-only ("SPOTTED!")
  /// and a cue's edge.
  int spots = 0;

  /// Boss age when the bird was last caught in a beam and hurt (render-only,
  /// like [lastGlanceAt]: the health bar's SPOTTED! flash reads it).
  double lastSpotAt = double.negativeInfinity;

  /// Sweeps aimed while enraged: every second one is a slit of two beams
  /// ([SearchlightGargoyle.slitAt]), the first a zone sweep.
  int furySweeps = 0;

  /// How many of the cycle numbered [featherCycle]'s feathers have left: the
  /// rules' cursor into [featherSchedule], reset as each cycle begins.
  int featherCycle = -1, featherSlot = 0;

  GargoylePhase get gargoylePhase => _gargoyleFighting
      ? SearchlightGargoyle.phase(gargoyleCycle)
      : GargoylePhase.perch;

  /// Whether the chest lamp is open: only then do rocks hurt him. Always
  /// false outside the fight.
  bool get lampOpen =>
      _gargoyleFighting && SearchlightGargoyle.lampOpen(gargoyleCycle);

  /// 0 (shuttered) to 1 (open): the art's channel.
  double get lampOpenness =>
      _gargoyleFighting ? SearchlightGargoyle.lampOpenness(gargoyleCycle) : 0;

  /// 0 to 1 through the 1.5 s warning before each sweep, else 0.
  double get sweepWarning =>
      _gargoyleFighting ? SearchlightGargoyle.warning(gargoyleCycle) : 0;

  /// Whether a beam burns now: from ignition to the vent.
  bool get beamOn =>
      _gargoyleFighting && SearchlightGargoyle.beamOn(gargoyleCycle);

  /// Sweeps whose warning has begun, beams that have ignited and vents that
  /// have opened, for edge-triggered cues and for aiming.
  int get sweepWarnings => _gargoyleFighting
      ? SearchlightGargoyle.count(combatTime, SearchlightGargoyle.warnAt)
      : 0;
  int get sweepIgnitions => _gargoyleFighting
      ? SearchlightGargoyle.count(combatTime, SearchlightGargoyle.sweepAt)
      : 0;
  int get lampOpens => _gargoyleFighting
      ? SearchlightGargoyle.count(combatTime, SearchlightGargoyle.ventAt)
      : 0;

  /// The lit band's half-height at the bird's column.
  double get beamHalf => SearchlightGargoyle.half(enraged: enraged);

  /// The centres of the beams burning at the bird's column (one, or two in a
  /// slit sweep, upper first), or empty while none burns. Fury glides the
  /// beams in 1.5 s rather than 1.8 s. This is what the art draws and what
  /// [beamLit] tests.
  List<double> get beamCentres => !beamOn
      ? const []
      : SearchlightGargoyle.centres(
          gargoyleCycle,
          side: beamSide,
          slit: slitSweep,
          fury: enraged,
        );

  /// Whether a circle at [py] with [pr] is caught in a burning beam.
  bool beamLit(double py, double pr) {
    final half = beamHalf;
    return beamCentres.any(
      (centre) => SearchlightGargoyle.lit(centre, half, py, pr),
    );
  }

  /// When this cycle's feathers fall (cycle seconds), given the latched
  /// sweep. The perch feather (.2 s) is first in every schedule; the rest
  /// follow the sweep the warning latched. The rules launch them as
  /// [featherSlot] catches up.
  List<double> get featherSchedule =>
      SearchlightGargoyle.feathers(enraged: enraged, slit: slitSweep);

  /// Whether a rock that left the bird when this boss was [bossAge] seconds
  /// old counts: the lamp was open then (cycle time 6.4 to 9.0 s). Judged at
  /// the release, not where the rock lands, the window the player can use is
  /// the vent they see: a rock takes 0.35 to 0.75 s to arrive, depending on
  /// the screen's width, and judged on arrival the last stretch of the vent
  /// would glance at one width and not at another.
  bool lampOpenAtRelease(double bossAge) {
    final t = bossAge - arrivalDuration;
    return isGargoyle &&
        t >= 0 &&
        SearchlightGargoyle.lampOpen(SearchlightGargoyle.cycleTime(t));
  }

  /// A hit on the chest circle: full damage when the lamp was open as the
  /// rock left ([releasedAt], else as it lands), else the rock clinks off the
  /// shutters ([lastGlanceAt]) and nothing is lost. The rock is spent either
  /// way (the rules consume it before it gets here).
  int _lampStrike(int damage, double? releasedAt) {
    final open = releasedAt == null ? lampOpen : lampOpenAtRelease(releasedAt);
    if (!open) {
      lastGlanceAt = age;
      return 0;
    }
    return takeDamage(damage);
  }

  String get gargoyleHint {
    if (beamOn) {
      return 'BEAM · Stay in the dark';
    }
    if (sweepWarning > 0) {
      if (slitSweep) return 'FURY · Slip between the beams';
      return beamSide == BeamSide.high
          ? 'BEAM INCOMING · Fly low!'
          : 'BEAM INCOMING · Fly high!';
    }
    if (lampOpen) return 'LAMP OPEN · Shoot the lamp!';
    return 'SHUTTERS CLOSED · Save your shots';
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

  /// Render-only: when the hit BEFORE [lastHitAt] landed (negative infinity
  /// for the first hit). Rapid fire lands a hit on top of the last one's
  /// reaction (the weapon's cooldown is .28 s, and a rock grazing the top of
  /// his circle lands up to .05 s later than one fired level with it, so
  /// hits land .28 s apart on average and at least about .22 s apart; a fan
  /// blade's lag is up to .27 s),
  /// so the art reads both and nothing snaps back to rest when a hit lands
  /// again, and a re-hit's flash is damped by [hitGap]. Set by every landed
  /// hit of every boss ([takeDamage]); a glance, a shielded hit and a hit
  /// that takes nothing leave it alone.
  double previousHitAt = double.negativeInfinity;

  /// Seconds between the last two landed hits (infinity for the first).
  double get hitGap =>
      previousHitAt.isFinite ? lastHitAt - previousHitAt : double.infinity;
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
    this.feather = false,
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

  /// One of the Searchlight Gargoyle's stone feathers: it falls from the top
  /// edge ([gravity] pulls it down) and is gone at the bottom, so it may
  /// rise above the screen.
  final bool feather;

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
