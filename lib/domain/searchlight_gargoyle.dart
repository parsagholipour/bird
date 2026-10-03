import 'dart:math' as math;

/// Which side of the sky the Gargoyle's beam comes from. It is aimed once, as
/// each warning begins: a bird in the upper half (height under .5) draws the
/// beam from above ([high]), anywhere else from below ([low]). The bird's safe
/// place is the dark side the beam never reaches.
enum BeamSide { high, low }

/// Where the Gargoyle is in his 9 s cycle.
enum GargoylePhase {
  /// Shuttered, waiting; a stone feather falls.
  perch,

  /// The 1.5 s warning: the sweep is aimed, the dark side is marked.
  warning,

  /// The beam glides 1.8 s from its outer to its inner end, then holds.
  sweep,

  /// The lamp is open and nothing attacks: the moment to shoot.
  vent,
}

/// The Searchlight Gargoyle, Watchman of the Tallest Tower: the timing and
/// geometry of his fight (rules version 43, campaign only; spec:
/// `reports/04-gargoyle.md` §2). He perches and does not fly.
///
/// Times are combat seconds `t = age - arrivalDuration` (4.6 s for the
/// cinematic bosses); `x = t mod period` is the cycle time and `k =
/// floor(t / period)` the cycle number. Heights are screen heights (0 =
/// top). The beam is defined where it crosses the bird's column, so it is the
/// same at every screen width. Everything here is pure, so seeks stay exact.
abstract final class SearchlightGargoyle {
  /// Health and the health at which fury begins (half of it).
  static const maxHp = 160, furyHp = 80;

  /// The 9 s cycle: perch, warning, sweep, vent. The sweep is aimed at
  /// [warnAt]; the beam ignites at [sweepAt] and holds until the vent at
  /// [ventAt]; the lamp is open from [ventAt] to the end of the cycle.
  static const period = 9.0;
  static const warnAt = 2.0, sweepAt = 3.5, ventAt = 6.4;

  /// The warning and the beam's glide, and how long the lamp takes to open
  /// and close (art channel).
  static const warnSeconds = sweepAt - warnAt;
  static const glideSeconds = 1.8, furyGlideSeconds = 1.5;
  static const lampOpenSeconds = .3, lampCloseAt = 8.7;

  /// The lit band's half-height at the bird's column, and in fury.
  static const litHalf = .09, furyLitHalf = .095;

  /// The beam's centre at the bird's column, from its outer to its inner end.
  static const highFrom = .16, highTo = .42;
  static const lowFrom = .84, lowTo = .58;

  /// Fury's slit sweep: two beams, each (from, to); the dark slit between
  /// their inner ends is [slitTop] to [slitBottom] for the bird's centre, a
  /// corridor .314 tall. The first design closed to .26 and .74, a corridor of
  /// .214 that a player hovering with a late, jittery thumb only held about
  /// half the time (52 to 70% at 50 to 100 ms of lag and 40 ms of jitter); the
  /// play review recommended .22 and .78; its lag sweep (ported in
  /// `test/gargoyle_lag.dart`) shows .21 and .79 hold 95% or better at 100 ms.
  static const slitUpper = (.12, .21), slitLower = (.88, .79);
  static const slitTop = .343, slitBottom = .657;

  /// Stone feathers: the spawn point relative to the bird's column and the
  /// top edge, the radius and gravity, and the horizontal speed (calm, fury).
  static const featherOffsetX = .62, featherY = -.06;
  static const featherRadius = .028, featherGravity = .30;
  static const featherSpeed = .36, furyFeatherSpeed = .44;

  /// Level feathers (rules version 49): the steepest a feather crosses the
  /// bird's column, drop over run, the slope a calm one aimed at height .3
  /// has. Aimed from [featherOffsetX] ahead, a feather at a low bird came in
  /// nearly twice as steep as one at a high bird (2.27 at .9, .98 at .1): it
  /// lit a band .33 tall at the column, against .18, and a bird pinned
  /// against the bottom edge had to climb into it, starting about 0.55 s
  /// before it crossed rather than 0.36. A level feather that would be
  /// steeper leaves further ahead and flies faster, in the same flight time,
  /// so it crosses at this slope: from .3 down (fury: from .45 down) every
  /// height lights the same .22 and leaves about the same 0.36 s.
  static const maxFeatherSlope = 1.3;

  /// Cycle times of feather launches: a calm cycle, a fury zone-sweep cycle
  /// and a slit cycle.
  static const calmFeathers = [.2, 4.6];
  static const furyFeathers = [.2, 4.5, 5.2];
  static const slitFeathers = [.2];

  /// The fiercer Gargoyle (rules version 46, a staged campaign fight) guards
  /// his open lamp: once he has grown stronger, feathers fall in the vent
  /// too, aimed at the bird lining up its shots. One a cycle in the full
  /// fight, two in fury; each has crossed the bird's column before the cycle
  /// ends. (His beams glide and his feathers fly at fury's pace from the full
  /// fight on: `SkyBoss.furyPace`.)
  static const ventFeathers = [7.0];
  static const furyVentFeathers = [6.5, 7.4];

  /// The chest lamp's hit circle is the usual boss circle; the boss anchors
  /// to [anchorY] and stands back of the bird by at least [anchorAhead], or
  /// [anchorEdge] in from the right edge, whichever is further out.
  static const anchorY = .5, anchorAhead = .74, anchorEdge = .50;

  /// The warning's length is what the viability search proved fair: shorter
  /// leaves a bird unable to reach the dark side. Not a knob.
  static const minWarnSeconds = 1.3;

  /// The position in the cycle, or 0 before combat begins.
  static double cycleTime(double t) => t < 0 ? 0 : t % period;

  /// The cycle number from 0, or -1 before combat begins.
  static int cycleNumber(double t) => t < 0 ? -1 : (t / period).floor();

  /// How many cycles have reached cycle time [at] by combat time [t].
  static int count(double t, double at) =>
      t < at ? 0 : ((t - at) / period).floor() + 1;

  static GargoylePhase phase(double x) => x < warnAt
      ? GargoylePhase.perch
      : x < sweepAt
      ? GargoylePhase.warning
      : x < ventAt
      ? GargoylePhase.sweep
      : GargoylePhase.vent;

  /// Whether the lamp is open (a rock reaching it counts) at cycle time [x].
  static bool lampOpen(double x) => x >= ventAt;

  /// 0 (shuttered) to 1 (open): opens over [lampOpenSeconds] at the vent and
  /// closes from [lampCloseAt] to the end of the cycle. An art channel; the
  /// rules only read [lampOpen].
  static double lampOpenness(double x) {
    if (x < ventAt) return 0;
    if (x < ventAt + lampOpenSeconds) return (x - ventAt) / lampOpenSeconds;
    if (x < lampCloseAt) return 1;
    return (1 - (x - lampCloseAt) / (period - lampCloseAt)).clamp(0.0, 1.0);
  }

  /// 0 to 1 through the warning, else 0.
  static double warning(double x) =>
      x < warnAt || x >= sweepAt ? 0 : (x - warnAt) / warnSeconds;

  /// Whether a beam burns at cycle time [x] (from ignition to the vent).
  static bool beamOn(double x) => x >= sweepAt && x < ventAt;

  /// Where the bird draws a beam from: a bird in the upper half of the sky
  /// (height under .5) draws it from above, so its safe place is the dark
  /// lower side; anywhere else, from below.
  static BeamSide aimAt(double birdY) =>
      birdY < anchorY ? BeamSide.high : BeamSide.low;

  /// A fury sweep is a slit when [enraged] at the aim and [furySweeps], the
  /// fury sweeps already aimed, is odd: the first fury sweep is a zone sweep.
  static bool slitAt({required bool enraged, required int furySweeps}) =>
      enraged && furySweeps.isOdd;

  static double _smooth(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double _glide(double from, double to, double s, double seconds) =>
      from + (to - from) * _smooth(s / seconds);

  /// The centre of the zone beam at the bird's column at cycle time [x], or
  /// null while no beam burns. In fury ([fury]) the beam glides in
  /// [furyGlideSeconds] instead of [glideSeconds], like the slit's two.
  static double? centre(BeamSide side, double x, {bool fury = false}) {
    if (!beamOn(x)) return null;
    final s = x - sweepAt;
    final seconds = fury ? furyGlideSeconds : glideSeconds;
    return side == BeamSide.high
        ? _glide(highFrom, highTo, s, seconds)
        : _glide(lowFrom, lowTo, s, seconds);
  }

  /// The centres of the two slit beams (upper, lower) at cycle time [x], or
  /// null while none burns.
  static (double, double)? slitCentres(double x) {
    if (!beamOn(x)) return null;
    final s = x - sweepAt;
    return (
      _glide(slitUpper.$1, slitUpper.$2, s, furyGlideSeconds),
      _glide(slitLower.$1, slitLower.$2, s, furyGlideSeconds),
    );
  }

  /// The centres of every beam burning at the bird's column at cycle time
  /// [x] (one for a zone sweep from [side], two for a [slit]: upper first),
  /// or empty while none burns. [fury] is the fight's fury at the aim. The
  /// one function the rules, the art and the fairness proof all read.
  static List<double> centres(
    double x, {
    required BeamSide side,
    required bool slit,
    required bool fury,
  }) {
    if (slit) {
      final pair = slitCentres(x);
      return pair == null ? const [] : [pair.$1, pair.$2];
    }
    final one = centre(side, x, fury: fury);
    return one == null ? const [] : [one];
  }

  /// The lit band's half-height.
  static double half({required bool enraged}) =>
      enraged ? furyLitHalf : litHalf;

  /// Whether a circle at height [py] with radius [pr] touches a beam of
  /// [centre] and [half]: the bird is spotted.
  static bool lit(double centre, double half, double py, double pr) =>
      (py - centre).abs() < half + pr;

  /// The safe (dark) heights for the bird's centre while a zone beam holds at
  /// its inner end: from above, `inner + half` downward, from below upward.
  static (double, double) darkSide(
    BeamSide side, {
    required double half,
    required double radius,
  }) => side == BeamSide.high
      ? (highTo + half + radius, 1 - radius)
      : (radius, lowTo - half - radius);

  /// Feather launch times in cycle [k]'s cycle time, for a fight that is
  /// [enraged] (and, if so, a [slit] cycle or a zone cycle).
  static List<double> feathers({required bool enraged, required bool slit}) =>
      !enraged
      ? calmFeathers
      : slit
      ? slitFeathers
      : furyFeathers;

  /// A fiercer Gargoyle's feather launch times (rules version 46): his
  /// warm-up drops the calm cycle's ([armed] false: he has not grown
  /// stronger yet); then the sweep's own ([feathers]) and the vent's. [fury]
  /// and [slit] are the cycle's as its sweep was aimed, so the schedule holds
  /// still through the vent, where his health changes.
  static List<double> fierceFeathers({
    required bool armed,
    required bool fury,
    required bool slit,
  }) => !armed
      ? calmFeathers
      : [
          ...feathers(enraged: fury, slit: slit),
          ...(fury ? furyVentFeathers : ventFeathers),
        ];

  /// How many launches of [schedule] are due by cycle time [x].
  static int due(List<double> schedule, double x) {
    var count = 0;
    for (final at in schedule) {
      if (at <= x) count++;
    }
    return count;
  }

  /// How many of this cycle's feathers have left by cycle time [x]. None
  /// leave in the vent ([ventAt] on): his attacks are over, and a fury that
  /// begins while the lamp is open cannot add a late one. The perch feather
  /// is first in every schedule, so the latch a cycle inherits before its
  /// warning never changes the count before [warnAt].
  static int launchesDue(
    double x, {
    required bool enraged,
    required bool slit,
  }) {
    if (x >= ventAt) return 0;
    var due = 0;
    for (final at in feathers(enraged: enraged, slit: slit)) {
      if (at <= x) due++;
    }
    return due;
  }

  /// A stone feather's launch from the top edge, `ahead` of the bird's column,
  /// aimed to cross the column at height [birdY]: its velocity and the time
  /// it takes. The drop is `y(F) = featherY + vy * F + gravity / 2 * F^2`,
  /// solved for `vy`. A [level] feather (rules version 49) never crosses
  /// steeper than [maxFeatherSlope]: it leaves further ahead, faster, in the
  /// same time. Otherwise it leaves [featherOffsetX] ahead.
  static ({double vx, double vy, double flight, double ahead}) featherShot(
    double birdY, {
    required bool enraged,
    bool level = false,
  }) {
    final speed = enraged ? furyFeatherSpeed : featherSpeed;
    final flight = featherOffsetX / speed;
    // Its speed down as it crosses, times the flight: over a run of `ahead`,
    // the slope at the column is drop / ahead.
    final drop = birdY - featherY + featherGravity / 2 * flight * flight;
    final ahead = level
        ? math.max(featherOffsetX, drop / maxFeatherSlope)
        : featherOffsetX;
    return (
      // Bit for bit as before rules 49 when it leaves [featherOffsetX] ahead.
      vx: ahead == featherOffsetX ? -speed : -ahead / flight,
      vy: (birdY - featherY) / flight - featherGravity / 2 * flight,
      flight: flight,
      ahead: ahead,
    );
  }

  /// The anchor x for a bird column [birdX] and screen width [width].
  static double anchorX(double birdX, double width) =>
      math.max(birdX + anchorAhead, width - anchorEdge);
}
