import 'dart:math' as math;

import 'game_rules.dart' show LevelRoute;

/// What a steam vent asks of the bird: a clear hop over a scalding plume, or
/// a free ride up on the cool billow that follows it.
enum SteamKind {
  /// Hot steam: the plume scalds. Hop over it.
  hop,

  /// Soft steam: the billow lifts a bird inside it, worth two points.
  ride,
}

/// Where a vent is in its cycle. The cycle repeats on the route clock.
enum SteamPhase {
  /// A dark grate and a lazy wisp.
  sleep,

  /// The 1.5 s warning: amber grate, spitting puffs, a ghost column showing
  /// the exact reach.
  hiss,

  /// The 0.5 s white-hot jet that scalds.
  burst,

  /// The cool cloud that lifts a bird inside it.
  billow,
}

/// The steam layer of a campaign level (rules version 43): vents that take
/// the place of a wall on selected passages. A plan layer, not a set piece:
/// passages keep flowing, and route stars and star marks do not change.
///
/// The passage numbers are `first`, `first + every`, ... up to [last] (from
/// 1, like the route's passages); [pattern] is a string of `H` (hop) and `R`
/// (ride) letters that cycles over the slots. JSON key `steam` is written
/// only when a plan has a layer, so every rules 41 tape stays byte-identical.
class SteamPlan {
  const SteamPlan({
    this.first = 0,
    this.every = 0,
    this.last,
    this.pattern = '',
  });

  /// No steam, the default of every plan.
  static const none = SteamPlan();

  /// Steam Alley's steady layer (3-3): eight slots, hop and ride alternating.
  static const steady = SteamPlan(first: 4, every: 4, last: 34, pattern: 'HR');

  /// The light layer of a guardian's run-up (3-4): three slots, ride first.
  static const sparse = SteamPlan(first: 4, every: 4, last: 12, pattern: 'RH');

  final int first, every;

  /// The last slot's passage number at most, or null for no limit.
  final int? last;
  final String pattern;

  bool get isEmpty => pattern.isEmpty;

  /// The slots' passage numbers that fit within [passages] passages.
  List<int> slots(int passages) {
    if (isEmpty || every < 1) return const [];
    final limit = math.min(last ?? passages, passages);
    return [for (var n = first; n <= limit; n += every) n];
  }

  /// What the [index]th slot (from 0) asks.
  SteamKind kindAt(int index) =>
      pattern[index % pattern.length] == 'R' ? SteamKind.ride : SteamKind.hop;

  Map<String, Object?> toJson() => {
    'first': first,
    'every': every,
    'last': last,
    'pattern': pattern,
  };

  /// Reads a layer saved by [toJson]. Anything malformed throws a
  /// [FormatException], like the rest of a replay tape.
  factory SteamPlan.fromJson(Object? json) {
    Never invalid() => throw const FormatException('Invalid steam plan');
    if (json is! Map) invalid();
    final first = json['first'], every = json['every'];
    final last = json['last'], pattern = json['pattern'];
    if (first is! int ||
        every is! int ||
        (last != null && last is! int) ||
        pattern is! String) {
      invalid();
    }
    return SteamPlan(
      first: first,
      every: every,
      last: last as int?,
      pattern: pattern,
    );
  }

  /// Why this layer cannot be laid, or null when it can. [enemyAt] says
  /// whether an enemy leads passage number n: a vent never replaces an
  /// enemy-led passage. The route-dependent rules (no slot within one
  /// passage of a set piece, the last slot passed 2 s before the goal or the
  /// boss) are the rules agent's (see `LevelRoute.geysers`).
  String? problem({bool Function(int passage)? enemyAt}) {
    if (isEmpty) return null;
    if (first < 4 || every < 3) return 'steam';
    if (last != null && last! < first) return 'steam';
    if (pattern.runes.any((r) => r != 0x48 && r != 0x52)) return 'steam';
    if (enemyAt != null && slots(last ?? 1000).any(enemyAt)) return 'steam';
    return null;
  }

  /// The route-dependent rules, which need the laid [route] of a level that
  /// runs [length] cruising seconds (to its goal, or to its boss): no slot
  /// within one passage of a set piece (a vent on the passage before or after
  /// one, or on the next one out from those), and the last vent passed at
  /// least [lastBefore] seconds before the goal or the boss (whose arrival
  /// holds the bird). Null when the layer can be flown.
  String? routeProblem(LevelRoute route, double length) {
    if (isEmpty) return null;
    for (final piece in route.pieces) {
      // The passage just before the piece, and the one just after it.
      final before = route.passages.lastIndexWhere((x) => x < piece.start);
      for (final geyser in route.geysers) {
        final at = geyser.slot - 1;
        if (at >= before - 1 && at <= before + 2) return 'steam';
      }
    }
    for (final geyser in route.geysers) {
      final passed = geyser.burstAt + SteamCycle.arrival(geyser.kind);
      if (length - passed < lastBefore) return 'steam';
    }
    return null;
  }

  /// A vent must be passed this many route seconds before the goal or boss.
  static const lastBefore = 2.0;
}

/// The steam vent's cycle in route seconds, relative to the burst at 0 (spec:
/// `reports/03-steam-geysers.md` §2). The period is [period]: hiss from
/// `-hiss` to 0, burst to [burst], billow to [burst] + [billow], then sleep.
/// It repeats before and after, so a vent's state is a pure function of
/// where the bird is on the route.
abstract final class SteamCycle {
  static const period = 4.2;
  static const hiss = 1.5, burst = .5, billow = 1.25;

  /// A cruising bird reaches a hop vent this long after the burst begins
  /// (the plume stands as it arrives) and a ride vent this long after
  /// (mid-billow).
  static const hopArrival = .15, rideArrival = 1.05;

  /// The plume rises over [plumeRise] and falls over [plumeFall] inside the
  /// burst; the lift fades in over [liftIn] and out over [liftOut].
  static const plumeRise = .12, plumeFall = .08;
  static const liftIn = .15, liftOut = .40;

  /// Screen heights: the hit box and lift half-widths, and the mouth of a
  /// short stack or of a manhole cover.
  static const hitHalfWidth = .05, liftHalfWidth = .06;
  static const stackMouth = .80, coverMouth = .915, stackBelow = .47;

  /// Where the burst is when the bird arrives: the vent's `burstAt` is the
  /// route second of a cruising bird's arrival minus this.
  static double arrival(SteamKind kind) =>
      kind == SteamKind.hop ? hopArrival : rideArrival;

  // ---- Rules constants (spec: reports/03-steam-geysers.md section 2) ----

  /// The billow's lift: a bird inside the vent's [liftHalfWidth] is pushed
  /// up at up to [liftSpeed] (screen heights a second), fading in over
  /// [liftFade] below [liftMargin] above the plume's top. It never acts
  /// above that line, so it cannot push the bird toward the ceiling.
  static const liftSpeed = .55, liftMargin = .03, liftFade = .10;

  /// Points: a hop vent cleared unscathed, and a ride vent that lifted the
  /// bird for at least [rideSeconds] (no other score constants move). The
  /// report asked for a quarter second of lift, but a cruising bird crosses
  /// the whole lift column in .20 to .28 s and the lift carries it out of
  /// the zone sooner, so a tenth of a second (about one flap's worth) is
  /// what a bird that needs the ride gets.
  static const hopPoints = 1, ridePoints = 2;
  static const rideSeconds = .10;

  /// A vent leaves the list once it has scrolled this far.
  static const vanishX = -.3;

  /// Only vents this far behind and ahead of the bird count toward the audio
  /// counters (`steamHisses`, `steamBursts`), and only in the cycle the bird
  /// arrives in: one hiss and one burst for every vent it passes.
  static const earshotBehind = .10, earshotAhead = 1.8;

  /// The three stars on the arc above a plume: x from the vent's centre, y
  /// from the arc's height (the plume's top minus [starsAbove]).
  static const starsX = [-.20, -.03, .14];
  static const starsDY = [.05, 0.0, .05];
  static const starsAbove = .14;

  /// A hop vent's plume: the first hops are short stubs ([stubTop] at the
  /// first, rising [stubStep] each, never above [stubFloor]); the top sits
  /// [hopAbove] above the slot's own centre, never above the previous gate's
  /// centre minus [hopBehind] (so the climb from any gate exit is bounded)
  /// and never below [hopMax].
  static const stubTop = .58, stubStep = .04, stubFloor = .42;
  static const hopAbove = .06, hopBehind = .22, hopMax = .64;

  /// A ride vent's plume: the slot's centre plus [rideBelow], held to
  /// [rideMin]..[rideMax] (the lift delivers the bird to about the aim line).
  static const rideBelow = .04, rideMin = .50, rideMax = .62;

  /// The standing plume's top (0 is the top of the screen) of a hop vent on
  /// a slot centred on [centre], after a gate centred on [previous], the
  /// [ordinal]th hop vent of the level (from 0).
  static double hopTop(double centre, double previous, int ordinal) {
    final least = math.max(stubFloor, stubTop - stubStep * ordinal);
    final floor = math.max(least, previous - hopBehind);
    return (centre - hopAbove).clamp(floor, hopMax);
  }

  /// The standing plume's top of a ride vent on a slot centred on [centre].
  static double rideTop(double centre) =>
      (centre + rideBelow).clamp(rideMin, rideMax);

  /// The plume's top a vent of [kind] stands at; see [hopTop] and [rideTop].
  static double top(
    SteamKind kind, {
    required double centre,
    required double previous,
    required int ordinal,
  }) => kind == SteamKind.hop
      ? hopTop(centre, previous, ordinal)
      : rideTop(centre);

  /// The upward speed the billow gives a bird at [birdY] under a plume that
  /// stands to [top], with the lift envelope at [env] (0 to 1).
  static double liftFor(double env, double birdY, double top) =>
      liftSpeed * env * _smooth((birdY - (top - liftMargin)) / liftFade);

  /// The time in the cycle relative to the burst, in `[-hiss, period - hiss)`.
  static double cycleTime(double routeSeconds, double burstAt) =>
      (routeSeconds - burstAt + hiss) % period - hiss;

  static SteamPhase phase(double routeSeconds, double burstAt) {
    final t = cycleTime(routeSeconds, burstAt);
    return t < 0
        ? SteamPhase.hiss
        : t < burst
        ? SteamPhase.burst
        : t < burst + billow
        ? SteamPhase.billow
        : SteamPhase.sleep;
  }

  static double _smooth(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// 0 to 1 through the hiss, else 0.
  static double warning(double routeSeconds, double burstAt) {
    final t = cycleTime(routeSeconds, burstAt);
    return t < 0 ? (t + hiss) / hiss : 0;
  }

  /// How much of the plume stands: 0 outside the burst, rising over
  /// [plumeRise] and falling over the last [plumeFall] of it.
  static double plume(double routeSeconds, double burstAt) {
    final t = cycleTime(routeSeconds, burstAt);
    if (t < 0 || t >= burst) return 0;
    return math.min(_smooth(t / plumeRise), _smooth((burst - t) / plumeFall));
  }

  /// The billow's lift envelope: 0 outside the billow, fading in and out.
  static double lift(double routeSeconds, double burstAt) {
    final t = cycleTime(routeSeconds, burstAt) - burst;
    if (t < 0 || t >= billow) return 0;
    return math.min(_smooth(t / liftIn), _smooth((billow - t) / liftOut));
  }
}

/// A vent as the route lays it: which passage's wall it replaces, where, what
/// it asks and when it fires. Values are world and route coordinates, fixed
/// before the flight begins, so every attempt meets the same vents (see
/// `LevelRoute.geysers`).
class SteamGeyser {
  const SteamGeyser({
    required this.slot,
    required this.x,
    required this.kind,
    required this.burstAt,
  });

  /// The passage number (from 1) whose wall the vent replaces.
  final int slot;

  /// World x of the vent's centre: the passage's leading edge plus
  /// [centreOffset], like `LevelRoute.passages`.
  final double x;
  final SteamKind kind;

  /// The route second a burst begins, chosen so a cruising bird reaches the
  /// vent [SteamCycle.arrival] seconds later. The cycle repeats from it in
  /// both directions, every [SteamCycle.period].
  final double burstAt;

  /// The slot is this far from the passage's leading edge to its centre (a
  /// 0.30 wide slot, like sun wheels).
  static const centreOffset = .15, width = .30;

  double get hissAt => burstAt - SteamCycle.hiss;
  double get burstEndAt => burstAt + SteamCycle.burst;
  double get billowEndAt => burstEndAt + SteamCycle.billow;

  SteamPhase phaseAt(double routeSeconds) =>
      SteamCycle.phase(routeSeconds, burstAt);
  double plumeAt(double routeSeconds) =>
      SteamCycle.plume(routeSeconds, burstAt);
  double liftAt(double routeSeconds) => SteamCycle.lift(routeSeconds, burstAt);
}

/// A vent in flight: the route's [geyser] at its scrolling screen [x], with
/// the plume's [top] (screen height, 0 = top) the slot's gate geometry
/// fixes. The simulation keeps them in `FlightSimulation.steamVents`; the
/// art and the audio read them. State is a function of `routeSeconds`.
///
/// The simulation lays one when the route's passage of its slot comes within
/// reach (`FlightSimulation._layVent`), scrolls it with the course (its `x`
/// is the geyser's world x minus the distance flown, so it is exact) and
/// clears it at a boss's arrival.
class SteamVent {
  SteamVent({required this.geyser, required this.x, required this.top});
  final SteamGeyser geyser;
  double x;

  /// What has happened at this vent, written by the rules (never by art):
  /// the last cycle whose hiss and burst were counted for the audio (only
  /// the cycle the bird arrives in is ever counted), whether
  /// the bird ever met the hit box (scalded or not: no point for a hop then),
  /// whether it scalded, the seconds the billow lifted the bird, and whether
  /// the ride was paid and the bird has passed.
  int hissCycle = -(1 << 30), burstCycle = -(1 << 30);
  bool touched = false, scalded = false, rode = false, passed = false;
  double lifted = 0;

  /// The plume's top when it stands fully, and so the hit box's top.
  final double top;

  SteamKind get kind => geyser.kind;
  SteamPhase phaseAt(double routeSeconds) => geyser.phaseAt(routeSeconds);

  /// The billow's lift envelope at [routeSeconds], 0 to 1.
  double liftAt(double routeSeconds) => geyser.liftAt(routeSeconds);

  /// The top of the plume's hit box at [routeSeconds]; 1 when nothing stands.
  double plumeTop(double routeSeconds) =>
      1 - (1 - top) * geyser.plumeAt(routeSeconds);

  /// The bottom of the hit box: the mouth of a stack or of a manhole cover.
  double get mouth => top < SteamCycle.stackBelow
      ? SteamCycle.stackMouth
      : SteamCycle.coverMouth;
}
