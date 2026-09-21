import 'dart:math' as math;

/// Shared by the bird drawing and its rock muzzle, in viewport-height units.
abstract final class BirdFlightMotion {
  static const size = .145;
  static double tilt(double velocity) => (velocity * .6).clamp(-.23, .4);

  static double spring(double sinceFlap) {
    if (sinceFlap < 0 || sinceFlap >= .22) return 0;
    final extending = sinceFlap < .08;
    final t = extending ? sinceFlap / .08 : (sinceFlap - .08) / .14;
    final lobe = 4 * t * (1 - t);
    return (extending ? -.05 : .02) * lobe * lobe;
  }

  static ({double x, double y}) mouth({
    required double velocity,
    required double sinceFlap,
    required bool reducedMotion,
  }) {
    final angle = reducedMotion ? 0.0 : tilt(velocity);
    final stretch = reducedMotion ? 0.0 : spring(sinceFlap);
    // Beak tip (223, 120) in the original 256 × 224 bird illustration.
    final x = size * (223 / 256 - .48) * (1 + stretch);
    final y = size * (120 / 256 - .43) * (1 - stretch);
    return (
      x: x * math.cos(angle) - y * math.sin(angle),
      y: x * math.sin(angle) + y * math.cos(angle),
    );
  }
}
