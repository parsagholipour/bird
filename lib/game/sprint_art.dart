import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';

/// The bird keeps its place on screen during a sprint, so speed reads from
/// air tearing past it and a bright plow of compressed air at its nose.
abstract final class SprintArt {
  /// 0 to 1, following the scroll boost as the burst surges and eases.
  static double rush(FlightSimulation sim) =>
      ((sim.courseBoost - 1) / (Sprint.peakBoost - 1)).clamp(0.0, 1.0);

  /// 0 to 1 for a ring sprint's extra speed beyond the button's peak.
  static double overdrive(FlightSimulation sim) =>
      ((sim.courseBoost - Sprint.peakBoost) /
              (RingSprint.peakBoost - Sprint.peakBoost))
          .clamp(0.0, 1.0);

  /// The ram lasts the whole sprint, so its bow wave only fades at the end.
  static double ram(FlightSimulation sim) {
    final button = sim.sprinting
        ? math.min(sim.sprintAge / .06, sim.sprintRemaining / .18)
        : 0.0;
    final ring = sim.ringSprinting
        ? math.min(
            (sim.elapsed - sim.ringSprintFrom) / .06,
            sim.ringSprintRemaining / .18,
          )
        : 0.0;
    return math.max(button, ring).clamp(0.0, 1.0);
  }

  /// A slice of torn air: pointed at both ends, fattest just behind its
  /// leading tip, so it reads as a smear rather than a dash.
  static Path _sliver(double x, double y, double length, double weight) =>
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + length * .3, y - weight, x + length, y)
        ..quadraticBezierTo(x + length * .3, y + weight, x, y)
        ..close();

  /// Air torn past the bird. The slivers crowd around its altitude and are
  /// sorted by depth, so the near ones are long, fat and quick and the far
  /// ones barely register. Each carries a warm halo under a white core: the
  /// halo shows on a cold sky, the core on a fire-lit one. Reduced Motion
  /// keeps the field and drops the scroll, leaving a still diagram of the
  /// same rushing air.
  static void streaks(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final t = rush(sim);
    if (t <= 0) return;
    final w = size.width, h = size.height;
    final extra = overdrive(sim);
    final warm = Color.lerp(SkyColors.gold, SkyColors.yellow, extra)!;
    final line = sim.birdY * h;
    final longest = h * .46, span = w + longest * 2;
    final halo = Paint(), core = Paint();
    for (var i = 0; i < 13 + (7 * extra).round(); i++) {
      final lane = (i * .618034) % 1, depth = (i * .7548777) % 1;
      final offset = (i * .4501836) % 1 * 2 - 1;
      final travel = reducedMotion ? 0.0 : sim.distance * h * (1.4 + depth * 4);
      final x = w + longest - (lane * span + travel) % span;
      var dy = offset.abs() * offset * h * .45;
      if (dy.abs() < h * .06) dy = h * .06 * (dy.isNegative ? -1 : 1);
      final y = (line + dy).clamp(h * .03, h * .97);
      final length = h * (.16 + .46 * depth) * (.55 + .45 * t);
      final weight = h * (.0045 + .012 * depth * depth);
      halo.color = warm.withValues(alpha: (.18 + .3 * depth) * t);
      core.color = SkyColors.white.withValues(
        alpha: (.25 + .55 * depth) * t * (1 + .2 * extra),
      );
      canvas
        ..drawPath(_sliver(x, y, length * 1.06, weight * 1.9), halo)
        ..drawPath(_sliver(x + length * .06, y, length * .9, weight), core);
    }
  }

  /// The plow: a wedge of air piling up on the bird's nose. It stays in
  /// front, leaving the space behind the bird to its wake.
  static void aura(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final t = ram(sim);
    if (t <= 0) return;
    final extra = overdrive(sim);
    final center = Offset(FlightSimulation.birdX * height, sim.birdY * height);
    final pulse = reducedMotion ? 0.0 : math.sin(sim.elapsed * 26) * .05;
    final nose = center.dx + height * .055;
    final half = height * (.05 + .022 * rush(sim) + .02 * extra);
    final bulge = height * (.062 + .028 * extra) * (1 + pulse);
    final body = height * (.038 + .018 * extra);

    Path wedge(double reach, double thick) => Path()
      ..moveTo(nose, center.dy - half)
      ..quadraticBezierTo(nose + reach, center.dy, nose, center.dy + half)
      ..quadraticBezierTo(
        nose + reach - thick,
        center.dy,
        nose,
        center.dy - half,
      )
      ..close();

    canvas
      ..drawPath(
        wedge(bulge * 1.32, body * 1.35),
        Paint()
          ..color = Color.lerp(
            SkyColors.cream,
            SkyColors.yellow,
            .3 + .5 * extra,
          )!.withValues(alpha: .3 * t),
      )
      ..drawPath(
        wedge(bulge, body),
        Paint()
          ..color = Color.lerp(
            SkyColors.yellow,
            SkyColors.coral,
            .35 * extra,
          )!.withValues(alpha: .65 * t),
      )
      ..drawPath(
        wedge(bulge * .8, body * .34),
        Paint()..color = SkyColors.white.withValues(alpha: .95 * t),
      );
  }
}
