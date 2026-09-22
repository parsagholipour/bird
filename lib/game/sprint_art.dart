import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';

/// The bird keeps its place on screen during a sprint, so speed reads from
/// streaks rushing past and a bright bow wave where it can smash things.
abstract final class SprintArt {
  /// 0 to 1, following the scroll boost as the burst surges and eases.
  static double rush(FlightSimulation sim) =>
      ((sim.sprintBoost - 1) / (Sprint.peakBoost - 1)).clamp(0.0, 1.0);

  /// The ram lasts the whole sprint, so its bow wave only fades at the end.
  static double ram(FlightSimulation sim) {
    if (!sim.sprinting) return 0;
    return math
        .min(sim.sprintAge / .06, sim.sprintRemaining / .18)
        .clamp(0.0, 1.0);
  }

  /// Decorative sky streaks, omitted in Reduced Motion.
  static void streaks(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final t = rush(sim);
    if (t <= 0 || reducedMotion) return;
    final w = size.width, h = size.height;
    final longest = h * .38, span = w + longest * 2;
    final paint = Paint()
      ..color = SkyColors.cream.withValues(alpha: .5 * t)
      ..strokeWidth = h * .004
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final lane = (i * .618034) % 1;
      final length = h * (.16 + (i * .37) % 1 * .22) * t;
      final travel = sim.distance * h * (2.2 + lane);
      final x = w + longest - (lane * span + travel) % span;
      final y = h * (.08 + lane * .84);
      canvas.drawLine(Offset(x, y), Offset(x + length, y), paint);
    }
  }

  static void aura(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final t = ram(sim);
    if (t <= 0) return;
    final center = Offset(FlightSimulation.birdX * height, sim.birdY * height);
    final wind = Paint()
      ..color = SkyColors.cream.withValues(alpha: .75 * t)
      ..strokeWidth = height * .005
      ..strokeCap = StrokeCap.round;
    final reach = .45 + .55 * rush(sim);
    for (final (dy, length) in [(-.03, .09), (0.0, .15), (.03, .09)]) {
      final tail = center + Offset(-height * .065, height * dy);
      canvas.drawLine(tail, tail - Offset(height * length * reach, 0), wind);
    }
    final pulse = reducedMotion ? 0.0 : math.sin(sim.elapsed * 30) * .04;
    final bow = Rect.fromCircle(
      center: center + Offset(height * .01, 0),
      radius: height * .08 * (1 + pulse),
    );
    canvas.drawArc(
      bow,
      -1.15,
      2.3,
      false,
      Paint()
        ..color = SkyColors.yellow.withValues(alpha: .4 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * .026
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      bow,
      -.95,
      1.9,
      false,
      Paint()
        ..color = SkyColors.white.withValues(alpha: .9 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * .006
        ..strokeCap = StrokeCap.round,
    );
  }
}
