import 'dart:math' as math;

import 'package:push_up_bird/domain/game_rules.dart';

/// The play review's lag sweep (reports/21-review-play/scripts/slit_mc.dart),
/// ported: how likely is a player who hovers by tapping, with a late and
/// jittery thumb, to get through one of the Gargoyle's sweeps?
///
/// A one-dimensional Monte Carlo of the bird's own Tap & Fly physics against a
/// beam geometry, one sweep from its warning. The bird starts level at the
/// warning, reacts after [react], then hovers: it taps when below a trigger
/// height and not rising, at most [taps] a second, each tap landing [lag] plus
/// a normal jitter of [sigma] late, the trigger wandering by [triggerNoise]
/// every 0.25 s. It has no foresight: it hovers where the dark side or the
/// slit is, as a person would.

final double _g = TapFlyMode().gravity, _flap = TapFlyMode().flapImpulse;
const double _r = FlightSimulation.birdRadius;

/// What a sweep is, as the survival model needs it.
enum Kind { calmZone, furyZone, furySlit }

/// A slit geometry: where each beam ends, and the lit half-height.
class SlitGeometry {
  const SlitGeometry(this.upper, this.lower, this.half);

  /// (outer, inner) centre of the upper and of the lower beam.
  final (double, double) upper, lower;
  final double half;

  /// The corridor between the beams for the bird's centre, at its narrowest.
  double get corridor => (lower.$2 - half - _r) - (upper.$2 + half + _r);
  double get top => upper.$2 + half + _r;
  double get bottom => lower.$2 - half - _r;

  /// The geometry the rules shipped before the play review's fix: inner ends
  /// .26 and .74, a corridor of .214.
  static const before = SlitGeometry((.12, .26), (.88, .74), .095);

  /// The shipped geometry.
  static const shipped = SlitGeometry(
    SearchlightGargoyle.slitUpper,
    SearchlightGargoyle.slitLower,
    SearchlightGargoyle.furyLitHalf,
  );
}

double _smooth(double t) {
  final x = t.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// The two beams of a slit sweep of [geometry] at cycle time [x] (upper
/// first), or none while no beam burns: [SearchlightGargoyle.slitCentres] for
/// any geometry.
List<double> slitCentresFor(SlitGeometry geometry, double x) {
  if (!SearchlightGargoyle.beamOn(x)) return const [];
  final e = _smooth(
    (x - SearchlightGargoyle.sweepAt) / SearchlightGargoyle.furyGlideSeconds,
  );
  double lerp((double, double) p) => p.$1 + (p.$2 - p.$1) * e;
  return [lerp(geometry.upper), lerp(geometry.lower)];
}

/// The beam centres at the bird's column at cycle time [x].
List<double> _centres(
  double x,
  Kind kind,
  BeamSide side,
  SlitGeometry geometry,
) {
  if (kind == Kind.furySlit) return slitCentresFor(geometry, x);
  return SearchlightGargoyle.centres(
    x,
    side: side,
    slit: false,
    fury: kind == Kind.furyZone,
  );
}

double _half(Kind kind, SlitGeometry geometry) => kind == Kind.furySlit
    ? geometry.half
    : SearchlightGargoyle.half(enraged: kind == Kind.furyZone);

class Gauss {
  Gauss(int seed) : _random = math.Random(seed);
  final math.Random _random;
  double next() {
    final u = 1 - _random.nextDouble(), v = _random.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }
}

/// Whether one hovering bird gets through one sweep of [kind] unspotted.
bool survives({
  required Kind kind,
  required BeamSide side,
  required SlitGeometry geometry,
  required double lag,
  required double sigma,
  required Gauss gauss,
  double react = .5,
  double taps = 3,
  double triggerNoise = .02,
}) {
  const dt = 1 / 120;
  // Where it hovers: just inside the dark side's far edge, or the slit's
  // middle, with the lag's drift allowed for.
  final mean = kind == Kind.furySlit
      ? .5
      : side == BeamSide.high
      ? .76
      : .24;
  final adjust = lag * .5 + .5 * _g * lag * lag;
  final trigger = mean + .066 - adjust;
  final half = _half(kind, geometry);
  var y = side == BeamSide.high ? .55 : .45;
  var v = 0.0, t = 0.0, last = -10.0;
  var m = trigger;
  final pending = <double>[];
  for (var step = 0; step < 4.5 / dt; step++) {
    final x = SearchlightGargoyle.warnAt + t;
    if (x >= SearchlightGargoyle.ventAt) break;
    if (step % 30 == 0) m = trigger + gauss.next() * triggerNoise;
    if (t >= react &&
        step.isEven &&
        y > m &&
        v > -.25 &&
        t - last >= 1 / taps &&
        pending.isEmpty) {
      pending.add(t + math.max(0.0, lag + gauss.next() * sigma));
      last = t;
    }
    if (pending.isNotEmpty && pending.first <= t) {
      pending.removeAt(0);
      v = _flap;
    }
    v += _g * dt;
    y += v * dt;
    t += dt;
    if (y - _r <= 0 || y + _r >= 1) return false;
    for (final c in _centres(x, kind, side, geometry)) {
      if ((y - c).abs() < half + _r) return false;
    }
  }
  return true;
}

/// The share of [n] hovering birds that get through a sweep of [kind] with
/// the given thumb [lag] and jitter [sigma] (seconds), half of them aimed
/// from above and half from below.
double survival(
  Kind kind, {
  required double lag,
  required double sigma,
  SlitGeometry geometry = SlitGeometry.shipped,
  int n = 2000,
  int seed = 7,
}) {
  final gauss = Gauss(seed);
  var ok = 0;
  for (var i = 0; i < n; i++) {
    final side = i.isEven ? BeamSide.high : BeamSide.low;
    if (survives(
      kind: kind,
      side: side,
      geometry: geometry,
      lag: lag,
      sigma: sigma,
      gauss: gauss,
    )) {
      ok++;
    }
  }
  return ok / n;
}
