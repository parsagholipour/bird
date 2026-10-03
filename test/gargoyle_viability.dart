import 'dart:math' as math;

import 'package:push_up_bird/domain/game_rules.dart';

import 'gargoyle_lag.dart';

/// The Searchlight Gargoyle's fairness proof (ported from
/// `reports/04-gargoyle/proof/gargoyle_viability_test.dart`), now reading the
/// shipped pure rules instead of a mirror of them.
///
/// Exhaustive viability check: from a start state, does ANY input sequence of
/// at most five taps a second reach the end of the sweep untouched? A
/// depth-first search with memoised dead states over a quantised (time, height,
/// velocity, tap cooldown, aimed side, feather lanes) space. No bot
/// heuristics: if it says viable a fair path exists (and it returns one); if
/// it exhausts, the design is unfair.
///
/// The physics are Tap & Fly's: a tap sets the climb to `flapImpulse`, gravity
/// pulls at `gravity`, one step per frame (1/60 s).
final _tap = TapFlyMode();
final double gravity = _tap.gravity, flapImpulse = _tap.flapImpulse;
const double birdRadius = FlightSimulation.birdRadius;
const double dt = 1 / 60;

/// A search needs a tap at most this often: five taps a second.
const int tapGapSteps = 12;

const double _yq = .004, _vq = .02;

int _yi(double y) => (y / _yq).round();
int _vi(double v) => ((v + .6) / _vq).round();

/// One bird state at the start of the warning.
class Start {
  const Start(this.y, this.velocity);
  final double y, velocity;
  @override
  String toString() => 'y=${y.toStringAsFixed(2)} v=$velocity';
}

/// The survivable start states of the proof: heights .05 to .95 every .03,
/// each with a velocity of 0, -.3 (rising), -.54 (just tapped) or +.5
/// (falling fast), less those that cannot stay on the screen.
List<Start> survivableStarts() => [
  for (var y0 = .05; y0 <= .951; y0 += .03)
    for (final v0 in const [0.0, -.30, -.54, .5])
      if (!((v0 < 0 ? y0 - v0 * v0 / (2 * gravity) : y0) <
              birdRadius + .01 ||
          y0 > 1 - birdRadius - .01))
        Start(y0, v0),
];

/// Which kind of sweep: a calm zone sweep, a fury zone sweep, or fury's slit.
enum Sweep {
  calm(fury: false, slit: false),
  furyZone(fury: true, slit: false),
  furySlit(fury: true, slit: true);

  const Sweep({required this.fury, required this.slit});
  final bool fury, slit;
}

class SearchResult {
  const SearchResult(this.safe, this.taps, this.nodes);

  /// Whether some tap sequence survives.
  final bool safe;

  /// The frames (counted from the cycle's start, 1/60 s each) at which that
  /// sequence taps.
  final List<int> taps;
  final int nodes;
}

class Search {
  Search(
    this.sweep, {
    this.warnSeconds = SearchlightGargoyle.warnSeconds,
    this.margin = .002,
    this.tail = .3,
    this.cap = 6000000,
    this.withPerch = false,
    this.perchFury,
    this.substeps = 1,
    this.tapGap = tapGapSteps,
    this.slitGeometry,
    this.dropsFeathers = true,
    this.schedule,
    double? endAt,
    this.beamBlind = false,
    this.level = false,
  }) : startStep = ((SearchlightGargoyle.sweepAt - warnSeconds) / dt).round(),
       endStep = ((endAt ?? SearchlightGargoyle.ventAt + tail) / dt).round(),
       feathers = [
         // The perch feather (the first launch, .2 s in) has gone by before
         // the warning begins, so the warning-start search leaves it out;
         // the whole-cycle search ([withPerch]) keeps it.
         if (dropsFeathers)
           for (final at
               in (schedule ??
                       SearchlightGargoyle.feathers(
                         enraged: sweep.fury,
                         slit: sweep.slit,
                       ))
                   .skip(withPerch ? 0 : 1))
             (at / dt).round(),
       ];

  /// The cycle's feather launch times (seconds) when not the sweep's own
  /// ([SearchlightGargoyle.feathers]): a fiercer Gargoyle's (rules 46),
  /// whose vent drops feathers too ([SearchlightGargoyle.fierceFeathers]).
  final List<double>? schedule;

  /// Whether the path ignores the beam: a player who has not yet seen the
  /// warning plans only for the feathers it can see.
  final bool beamBlind;

  /// Whether the feathers are level (rules 49): none crosses the bird's
  /// column steeper than [SearchlightGargoyle.maxFeatherSlope].
  final bool level;

  final Sweep sweep;

  /// Whether this cycle drops its feathers: a staged Gargoyle's warm-up
  /// (rules 44) drops none, and a player who sees none plans for none.
  final bool dropsFeathers;

  /// The warning's length, the dodge margin the path must clear a beam or a
  /// feather by, and how long past the vent's start the search keeps the bird
  /// honest (the last feather is still crossing the bird's column then).
  final double warnSeconds, margin, tail;

  /// Whether the search includes the perch feather, from its launch.
  final bool withPerch;

  /// Whether the perch feather flies at fury's speed, when [withPerch]; null
  /// means as the sweep's own fury. Health only changes in the vent and in the
  /// first moments of the next perch, so a cycle whose perch feather left
  /// calm (.36 a second) can still have a fury sweep: the mixed case.
  final bool? perchFury;

  /// The fewest frames between taps: 12 is five taps a second, 24 two and a
  /// half (a casual player's pace).
  final int tapGap;

  /// A slit geometry other than the shipped one (the before-and-after of the
  /// fix round); the half-height is the geometry's own.
  final SlitGeometry? slitGeometry;

  /// Physics steps per 1/60 s frame. The proof's model takes one; the
  /// simulation takes two (its 1/120 s substeps), which a pilot that flies
  /// the model's taps through the simulation must match.
  final int substeps;

  /// The sky's edges hurt like a beam: the path stays this far inside them.
  static const wallMargin = .002;
  final int cap;
  final int startStep, endStep;

  /// The frame the warning begins and the perch feather leaves.
  static final warnStep = (SearchlightGargoyle.warnAt / dt).round();
  static final perchStep = (SearchlightGargoyle.calmFeathers.first / dt).round();
  final List<int> feathers;

  /// Per feather in [feathers], whether it flies at fury's speed (null: as the
  /// sweep's own fury). Differs only for the mixed case, a perch feather that
  /// left calm in a cycle whose sweep is fury's, and for a pilot re-planning
  /// around feathers already falling.
  late List<bool?> furies = [
    for (var i = 0; i < feathers.length; i++) withPerch && i == 0 ? perchFury : null,
  ];
  int nodes = 0;
  final dead = <(int, int, int)>{};
  final taps = <int>[];

  /// The clearance of the bird at [y] from the feather launched at
  /// [launchStep] along the lane [lane]: how far past touching.
  double clearFeather(
    int step,
    int launchStep,
    double lane,
    double y, {
    bool? fury,
  }) {
    final tau = (step - launchStep) * dt;
    final shot = SearchlightGargoyle.featherShot(
      lane,
      enraged: fury ?? sweep.fury,
      level: level,
    );
    if (tau < 0 || tau > shot.flight + .4) return 9;
    final px = shot.ahead + shot.vx * tau;
    final py =
        SearchlightGargoyle.featherY +
        shot.vy * tau +
        .5 * SearchlightGargoyle.featherGravity * tau * tau;
    return math.sqrt(px * px + (py - y) * (py - y)) -
        (SearchlightGargoyle.featherRadius + birdRadius);
  }

  /// Whether the bird at [y] is caught in a beam of [side] at [step].
  bool spotted(int step, double y, BeamSide? side) {
    if (side == null || beamBlind) return false;
    final x = step * dt;
    final geometry = slitGeometry;
    final bool custom = sweep.slit && geometry != null;
    final half = custom
        ? geometry.half
        : SearchlightGargoyle.half(enraged: sweep.fury);
    final centres = custom
        ? slitCentresFor(geometry, x)
        : SearchlightGargoyle.centres(
            x,
            side: side,
            slit: sweep.slit,
            fury: sweep.fury,
          );
    for (final c in centres) {
      if ((y - c).abs() < half + birdRadius + margin) return true;
    }
    return false;
  }

  /// Returns true when a safe continuation exists from the state reached at
  /// [step]; [since] is the frames since the last tap.
  bool go(
    int step,
    double y,
    double v,
    int since,
    BeamSide? side,
    List<double?> lanes,
  ) {
    if (++nodes > cap) throw StateError('cap');
    // The sweep is aimed from where the bird is as the warning begins.
    if (side == null && step >= warnStep) side = SearchlightGargoyle.aimAt(y);
    if (y < birdRadius + wallMargin || y > 1 - birdRadius - wallMargin) {
      return false;
    }
    if (spotted(step, y, side)) return false;
    for (var i = 0; i < feathers.length; i++) {
      final lane = lanes[i];
      if (lane != null &&
          clearFeather(step, feathers[i], lane, y, fury: furies[i]) < margin) {
        return false;
      }
    }
    if (step >= endStep) return true;
    // The state, packed without overflow: a fiercer Gargoyle's cycle (rules
    // 46) has more feathers than one 64-bit key holds lanes for, and a tap
    // gap over 15 frames needs its own count.
    var state = step;
    state = state * 512 + _yi(y);
    state = state * 256 + _vi(v);
    state = state * 32 + since.clamp(0, math.max(15, tapGap));
    state = state * 4 + (side?.index ?? 2);
    var near = 0, far = 0;
    for (var i = 0; i < lanes.length; i++) {
      final l = lanes[i];
      final lane = l == null ? 0 : _yi(l) + 1;
      if (i < 6) {
        near = near * 512 + lane;
      } else {
        far = far * 512 + lane;
      }
    }
    final key = (state, near, far);
    if (dead.contains(key)) return false;
    final next = step + 1;
    final nextLanes = [...lanes];
    // A feather's lane is where the bird is as it leaves.
    for (var i = 0; i < feathers.length; i++) {
      if (next == feathers[i]) nextLanes[i] = y;
    }
    final canTap = since >= tapGap;
    // Try first the move that heads toward the middle of the sky.
    final options = canTap ? (y > .5 ? [true, false] : [false, true]) : [false];
    for (final tap in options) {
      var nv = tap ? flapImpulse : v;
      var ny = y;
      for (var i = 0; i < substeps; i++) {
        nv += gravity * dt / substeps;
        ny += nv * dt / substeps;
      }
      if (go(next, ny, nv, tap ? 1 : since + 1, side, nextLanes)) {
        if (tap) taps.add(step);
        return true;
      }
    }
    dead.add(key);
    return false;
  }

  /// Searches from [start] at the start of the warning, after [idle] seconds
  /// without a tap (a player who has not reacted yet). Returns null when the
  /// bird has left the sky by then.
  SearchResult? from(Start start, {double idle = 0}) {
    var y = start.y, v = start.velocity;
    final skipped = (idle / dt).round();
    for (var i = 0; i < skipped; i++) {
      v += gravity * dt;
      y += v * dt;
    }
    if (y < birdRadius + .01 || y > 1 - birdRadius - .01) return null;
    // The sweep is aimed from where the bird is as the warning begins.
    final side = SearchlightGargoyle.aimAt(start.y);
    taps.clear();
    final ok = go(
      startStep + skipped,
      y,
      v,
      tapGap + skipped,
      side,
      List.filled(feathers.length, null),
    );
    return SearchResult(ok, [for (final t in taps.reversed) t], nodes);
  }

  /// Searches from a live state, for a pilot that replans as it flies: the
  /// bird at [y] with climb [v] at cycle frame [step], [since] frames after its
  /// last tap; [side] if the sweep has been aimed (else the search aims it
  /// from the bird's height as the warning begins); [inFlight] the feathers
  /// already falling, each as its launch frame and lane. Feathers still to
  /// leave come from the sweep's schedule.
  SearchResult fromState(
    int step,
    double y,
    double v,
    int since,
    BeamSide? side,
    List<(int, double)> inFlight, {
    List<bool> inFlightFury = const [],
  }) {
    final launches = [
      if (dropsFeathers)
        for (final at
            in schedule ??
                SearchlightGargoyle.feathers(
                  enraged: sweep.fury,
                  slit: sweep.slit,
                ))
          (at / dt).round(),
    ];
    feathers
      ..clear()
      ..addAll([for (final f in inFlight) f.$1])
      ..addAll([
        for (final launch in launches)
          if (launch > step) launch,
      ]);
    furies = [
      for (var i = 0; i < inFlight.length; i++)
        i < inFlightFury.length ? inFlightFury[i] : null,
      for (var i = inFlight.length; i < feathers.length; i++) null,
    ];
    final lanes = <double?>[
      for (final f in inFlight) f.$2,
      for (var i = inFlight.length; i < feathers.length; i++) null,
    ];
    taps.clear();
    dead.clear();
    final ok = go(step, y, v, since, side, lanes);
    return SearchResult(ok, [for (final t in taps.reversed) t], nodes);
  }

  /// Searches a whole cycle from the perch feather's launch: the bird is at
  /// [start] as the feather leaves (so that is its lane), the sweep is aimed
  /// from wherever the bird is as the warning begins. Needs [withPerch].
  SearchResult fromPerch(Start start) {
    assert(withPerch);
    taps.clear();
    final lanes = List<double?>.filled(feathers.length, null);
    lanes[0] = start.y;
    final ok = go(perchStep, start.y, start.velocity, tapGap, null, lanes);
    return SearchResult(ok, [for (final t in taps.reversed) t], nodes);
  }
}

/// How many of [starts] have no safe tap sequence under [sweep].
({int searched, List<Start> unwinnable}) unwinnable(
  Sweep sweep, {
  double warnSeconds = SearchlightGargoyle.warnSeconds,
  double idle = 0,
  double margin = .002,
  double tail = .3,
  int tapGap = tapGapSteps,
  SlitGeometry? slitGeometry,
  Iterable<Start>? starts,
}) {
  var searched = 0;
  final bad = <Start>[];
  for (final start in starts ?? survivableStarts()) {
    final search = Search(
      sweep,
      warnSeconds: warnSeconds,
      margin: margin,
      tail: tail,
      tapGap: tapGap,
      slitGeometry: slitGeometry,
    );
    final result = search.from(start, idle: idle);
    if (result == null) continue;
    searched++;
    if (!result.safe) bad.add(start);
  }
  return (searched: searched, unwinnable: bad);
}
