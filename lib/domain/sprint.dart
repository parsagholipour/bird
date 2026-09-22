import 'dart:math' as math;

/// Touch sprint tuning (rules version 29).
///
/// A sprint scrolls the same course faster for a short burst. While it lasts,
/// the bird smashes enemies and stone panels it touches; walls still hurt.
abstract final class Sprint {
  static const seconds = 1.2, cooldown = 15.0;
  static const peakBoost = 2.5;

  /// The burst surges quickly, then eases back so the course speed returns
  /// before the ram ends rather than snapping back at a wall.
  static const surgeSeconds = .15, easeSeconds = .40;

  /// Scroll-speed multiplier `age` seconds after a sprint started.
  static double boost(double age) {
    if (!(age >= 0 && age < seconds)) return 1;
    final envelope = math.min(
      _smooth(age / surgeSeconds),
      _smooth((seconds - age) / easeSeconds),
    );
    return 1 + (peakBoost - 1) * envelope;
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }
}
