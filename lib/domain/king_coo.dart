import 'dart:math' as math;

/// The shape of the whistle squadron King Coo calls: a V that follows the
/// bird's lane, or a picket wall with one gap.
enum SquadShape { v, picket }

/// Where one squadron pigeon flies: [behind] is how far behind the
/// formation's leading edge it holds (screen heights), [y] the lane it
/// settles on.
class SquadSlot {
  const SquadSlot({required this.behind, required this.y});
  final double behind, y;
}

/// A squadron as planned at the puff: lanes fixed then, released at the
/// whistle plus [delay] seconds (fury's picket follows its V).
class SquadPlan {
  const SquadPlan({
    required this.shape,
    required this.slots,
    this.delay = 0,
    this.gap,
  });
  final SquadShape shape;
  final List<SquadSlot> slots;
  final double delay;

  /// A picket's gap centre (screen height), else null.
  final double? gap;
}

/// Where one squadron pigeon is at any moment after its release: a pure
/// function of the boss's clock. It is born at the boss ([x0] is the chest's
/// x plus the slot's `behind`, [fromY] the boss's height), flies left at
/// [KingCoo.squadSpeed] on the screen (a sprint does not speed it), and eases
/// to its lane [lane] over [KingCoo.squadEase], then holds it exactly. The
/// squadron rules set `SkyEnemy.x` and `SkyEnemy.y` from it each step.
class SquadTrack {
  const SquadTrack({
    required this.x0,
    required this.fromY,
    required this.lane,
    required this.bornAt,
  });

  final double x0, fromY, lane;

  /// Boss age at release.
  final double bornAt;

  double x(double age) => x0 - KingCoo.squadSpeed * math.max(0.0, age - bornAt);

  double y(double age) =>
      fromY +
      (lane - fromY) * KingCoo._smooth((age - bornAt) / KingCoo.squadEase);

  /// Boss age at which the pigeon crosses screen column [column].
  double crossesAt(double column) =>
      bornAt + (x0 - column) / KingCoo.squadSpeed;
}

/// Where a crumb bomb is in its life, from its lock to the crumbs.
enum LobPhase {
  /// The ring is locked; the wind-up before the toss.
  windup,

  /// The bomb is in the air; the ring still marks the burst.
  flying,

  /// The cloud stands and hurts.
  cloud,

  /// Harmless sprinkles linger.
  crumbs,

  /// Nothing left to draw.
  gone,
}

/// One crumb bomb, latched when its ring locks on the bird (screen x
/// [lockX], height [lockY]). Every time is boss `age`; every phase is a
/// pure function of it. The rules (R2) append one per lock; the art and
/// audio read them from `SkyBoss.lobs`.
class CrumbLob {
  const CrumbLob({
    required this.lockedAt,
    required this.lockX,
    required this.lockY,
    this.fury = false,
  });

  /// Boss age when the ring locked, and where: the bird's column and height
  /// at that moment (height clamped to [KingCoo.lockMin], [KingCoo.lockMax]).
  final double lockedAt, lockX, lockY;

  /// A fury lob drops a bracket of two clouds around the bird's own height.
  final bool fury;

  double get launchAt => lockedAt + KingCoo.lockLead;
  double get burstAt => launchAt + KingCoo.lobFlight;
  double get cloudEndsAt => burstAt + KingCoo.cloudSeconds;
  double get crumbsEndAt => cloudEndsAt + KingCoo.crumbSeconds;

  /// The cloud centres' heights: one at [lockY], or the fury bracket.
  List<double> get cloudHeights => KingCoo.cloudHeights(lockY, fury: fury);

  LobPhase phase(double age) => age < launchAt
      ? LobPhase.windup
      : age < burstAt
      ? LobPhase.flying
      : age < cloudEndsAt
      ? LobPhase.cloud
      : age < crumbsEndAt
      ? LobPhase.crumbs
      : LobPhase.gone;

  /// How far the bomb has flown, 0 at the toss and 1 at the burst.
  double flight(double age) =>
      ((age - launchAt) / KingCoo.lobFlight).clamp(0.0, 1.0);

  /// The standing cloud's radius at [age]; 0 before the burst and after it.
  /// The drawn radius is the hurt radius.
  double cloudRadius(double age) => KingCoo.cloudRadiusAt(age - burstAt);

  /// Whether the cloud hurts at [age].
  bool hurts(double age) => cloudRadius(age) > 0;

  /// 1 at the end of the cloud, fading to 0 as the crumbs go.
  double crumbs(double age) => phase(age) == LobPhase.crumbs
      ? 1 - (age - cloudEndsAt) / KingCoo.crumbSeconds
      : 0;
}

/// King Coo, Commissioner of the Curb: the timing and geometry of his fight
/// (rules version 43, campaign only; spec: `reports/05-king-coo.md` §2).
///
/// Times are combat seconds `t = age - arrivalDuration` (4.6 s for the
/// cinematic bosses); `t mod period` is the cycle time. Fury never retimes the
/// cycle; it only changes what each lock launches. Heights are screen
/// heights (0 = top). Everything here is pure, so seeks stay exact.
abstract final class KingCoo {
  /// Health and the health at which fury begins (half of it).
  static const maxHp = 140, furyHp = 70;

  /// The fixed cycle.
  static const period = 14.0;

  /// Toss times in a cycle: calm (two lobs) and fury (three, bracketed).
  static const calmLaunches = [1.4, 3.8];
  static const furyLaunches = [1.4, 3.2, 5.0];

  /// The ring locks this long before the toss, and the bomb flies this long
  /// to its burst: a telegraph of [telegraph] seconds in all.
  static const lockLead = .8, lobFlight = 1.4;
  static const telegraph = lockLead + lobFlight;

  /// The ring's height is the bird's, clamped to [lockMin], [lockMax].
  static const lockMin = .14, lockMax = .86;

  /// A cloud hurts for [cloudSeconds] (growing over [cloudGrow], shrinking
  /// over the last [cloudShrink]), then sprinkles linger for [crumbSeconds].
  static const cloudRadius = .11;
  static const cloudSeconds = 1.0, cloudGrow = .12, cloudShrink = .15;
  static const crumbSeconds = .4;

  /// Fury's clouds bracket the bird this far above and below its height,
  /// and a centre outside [edgeMin], [edgeMax] is dropped.
  static const furySpread = .30, edgeMin = .12, edgeMax = .88;

  /// The bomb's body is ballistic with this gravity (art only).
  static const bombGravity = .8;

  /// The puff window: the chest swells from [puffAt] (the inhale), the whistle
  /// blows at [whistleAt], the window closes at [windowEnd]; the chest
  /// settles over [puffRelease] more seconds.
  static const puffAt = 7.6, whistleAt = 9.2, windowEnd = 10.0;
  static const puffRelease = .4;

  /// Rocks do half damage (at least 1) on the fluffed chest and double on the
  /// taut, puffed one; [popDamage] of puffed hits in one window pops him.
  static const fluffDivisor = 2, puffMultiplier = 2, popDamage = 60;

  /// Squadron pigeons fly left this fast behind the whistle (screen heights
  /// per second), settle on their lanes over [squadEase], and a fury picket
  /// follows its V by [furyPicketDelay].
  static const squadSpeed = .62, squadEase = .6, furyPicketDelay = 1.4;

  /// A picket's blockers: the first sits [picketFirst] from the gap centre,
  /// the next every [picketSpacing]; the gap is [picketGap] tall. Blockers go
  /// on until one's reach ([pigeonReach]: a pigeon's radius plus the bird's)
  /// covers the last of the sky the bird may legally fly in, from
  /// [birdRadius] (touching the top edge hurts) to `1 - birdRadius`. So the
  /// last blocker of a picket can sit at or beyond the top or bottom edge
  /// (gap .30: 5 pigeons, .50: 4, .70: 5), closing the sliver between the
  /// last blocker and the edge. The fairness proof's own picket had two more
  /// for the centred gap, wholly off screen and out of any legal bird's reach
  /// (`reports/05-king-coo/proof/fair.dart`: 5, 6 and 5): they are left out.
  static const picketGap = .30, picketFirst = .233, picketSpacing = .16;
  static const pigeonReach = .045 + birdRadius, birdRadius = .038;

  /// Where the V's tip may sit, and the wings' offsets from the tip.
  static const vTipMin = .25, vTipMax = .75;
  static const vWings = [(.12, .075), (.24, .15)];

  /// By this cycle time every squadron pigeon, even a fury picket crossing
  /// at the widest phone (width 2.4), has passed the bird's column.
  static const squadCrossesBy = 13.0;

  /// Bird heights (inclusive) for which a picket's gap moves off the centre.
  static const picketMiddle = (.385, .615);

  /// Combat time of the first instant of the fight, from a boss [age].
  static double combatTime(double age, double arrival) => age - arrival;

  /// The position in the cycle, or 0 before combat begins.
  static double cycleTime(double t) => t < 0 ? 0 : t % period;

  /// The cycle number from 0, or -1 before combat begins.
  static int cycleNumber(double t) => t < 0 ? -1 : (t / period).floor();

  /// How many cycles have reached cycle time [at] by combat time [t].
  static int count(double t, double at) =>
      t < at ? 0 : ((t - at) / period).floor() + 1;

  /// Toss times of a cycle, and the times its rings lock.
  static List<double> launches({required bool fury}) =>
      fury ? furyLaunches : calmLaunches;
  static List<double> locks({required bool fury}) => [
    for (final toss in launches(fury: fury)) toss - lockLead,
  ];

  /// The cloud centres of a lob locked at [lockY].
  static List<double> cloudHeights(double lockY, {required bool fury}) {
    final y = lockY.clamp(lockMin, lockMax);
    if (!fury) return [y];
    return [
      for (final c in [y - furySpread, y + furySpread])
        if (c >= edgeMin && c <= edgeMax) c,
    ];
  }

  static double _smooth(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// A cloud's radius [s] seconds after its burst: it grows, holds, shrinks
  /// over the last of its second, and is 0 outside it.
  static double cloudRadiusAt(double s) {
    if (s < 0 || s >= cloudSeconds) return 0;
    return cloudRadius *
        math.min(
          _smooth(s / cloudGrow),
          _smooth((cloudSeconds - s) / cloudShrink),
        );
  }

  /// Whether the chest's ×2 window is open at cycle time [cycle].
  static bool windowOpen(double cycle) => cycle >= puffAt && cycle < windowEnd;

  /// How puffed the chest is at cycle time [cycle]: 0 when fluffed, rising to
  /// 1 over the inhale, held through the window, settling over the release.
  static double puffAmount(double cycle) {
    if (cycle < puffAt || cycle >= windowEnd + puffRelease) return 0;
    if (cycle < whistleAt) return (cycle - puffAt) / (whistleAt - puffAt);
    if (cycle < windowEnd) return 1;
    return 1 - (cycle - windowEnd) / puffRelease;
  }

  /// Rules damage of a hit worth [damage]: halved (at least 1) while
  /// fluffed, doubled while puffed.
  static int strikeDamage(int damage, {required bool puffed}) =>
      puffed ? damage * puffMultiplier : math.max(1, damage ~/ fluffDivisor);

  /// The squadron (or squadrons) called in cycle [cycle] for a bird at
  /// [birdY]: a V on even cycles, a picket on odd ones, and in fury both, the
  /// picket [furyPicketDelay] behind and always centred.
  static List<SquadPlan> squad({
    required int cycle,
    required double birdY,
    required bool fury,
  }) {
    final v = _v(birdY);
    if (fury) return [v, _picket(.5, delay: furyPicketDelay)];
    if (cycle.isEven) return [v];
    final middle = birdY >= picketMiddle.$1 && birdY <= picketMiddle.$2;
    return [_picket(middle ? (cycle % 4 == 1 ? .30 : .70) : .50)];
  }

  static SquadPlan _v(double birdY) {
    final tip = birdY.clamp(vTipMin, vTipMax);
    return SquadPlan(
      shape: SquadShape.v,
      slots: [
        SquadSlot(behind: 0, y: tip),
        for (final (behind, rise) in vWings) ...[
          SquadSlot(behind: behind, y: tip - rise),
          SquadSlot(behind: behind, y: tip + rise),
        ],
      ],
    );
  }

  static SquadPlan _picket(double gap, {double delay = 0}) {
    final slots = <SquadSlot>[];
    for (var y = gap - picketFirst; ; y -= picketSpacing) {
      slots.add(SquadSlot(behind: 0, y: y));
      if (y - pigeonReach <= birdRadius) break;
    }
    for (var y = gap + picketFirst; ; y += picketSpacing) {
      slots.add(SquadSlot(behind: 0, y: y));
      if (y + pigeonReach >= 1 - birdRadius) break;
    }
    return SquadPlan(
      shape: SquadShape.picket,
      slots: slots,
      delay: delay,
      gap: gap,
    );
  }
}
