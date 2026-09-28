import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../ui/theme.dart';

/// How a small enemy's body reacts to a rock it survives, in world space
/// before the facing flip. [shift] is in hit radii (positive: knocked right,
/// away from the bird), [tilt] in radians (positive: nose up for a
/// left-facing enemy), and [flash] blends toward the white "pop" (0..1).
typedef EnemyHitPose = ({
  double shift,
  double tilt,
  double scaleX,
  double scaleY,
  double flash,
});

/// Short, local impact accents driven entirely by the simulation clock.
abstract final class EnemyHitArt {
  /// Every hit accent, body pose and flash is fully gone after this.
  static const hitSeconds = .28;

  /// The body's knock-back: an instant squash away from the impact, a quick
  /// stretch rebound, a small dazed wobble and a settle. The first frames
  /// flash white while keeping the ink outline. Null when there is nothing
  /// to apply, including under Reduced Motion.
  static EnemyHitPose? pose(double age, {required bool reducedMotion}) {
    if (reducedMotion || !age.isFinite || age < 0 || age >= hitSeconds) {
      return null;
    }
    // A smooth window reaches exactly zero at hitSeconds, so nothing pops.
    final end = 1 - _smooth(.55, 1, age / hitSeconds);
    // Damped springs, strongest on the contact frame: (amount, decay seconds,
    // half period, delay of the peak).
    double spring(double amount, double decay, double half, double peak) =>
        amount *
        math.exp(-age / decay) *
        math.cos((age - peak) * math.pi / half) *
        end;
    final squash = spring(1, .07, .075, 0);
    return (
      // Snaps back fast so the rebound stretch stays inside the art box.
      shift: spring(.28, .045, .08, .02),
      tilt: spring(-.09, .09, .085, .015),
      // Compressed along the impact axis with little bulge, then a rebound
      // stretch along it; the ratio reads as squash at 16 px.
      scaleX: 1 - squash * (squash > 0 ? .24 : .11),
      scaleY: 1 + squash * (squash > 0 ? .03 : .16),
      flash: 1 - _smooth(.02, .055, age),
    );
  }

  /// A layer filter for the hit pop: light and mid tones go to warm white
  /// while dark outline tones stay dark, so the body never looks translucent.
  static ColorFilter flashFilter(double amount) {
    const lo = 54.0, hi = 86.0;
    const ink = SkyColors.ink, pop = Color(0xfffffcf2);
    final k = amount.clamp(0.0, 1.0);
    final matrix = List<double>.filled(20, 0);
    for (var c = 0; c < 3; c++) {
      final from = _channel(ink, c), to = _channel(pop, c);
      final slope = (to - from) / (hi - lo);
      for (var i = 0; i < 3; i++) {
        matrix[c * 5 + i] =
            k * slope * const [.2126, .7152, .0722][i] + (i == c ? 1 - k : 0);
      }
      matrix[c * 5 + 4] = k * (from - slope * lo);
    }
    matrix[18] = 1;
    return ColorFilter.matrix(matrix);
  }

  static void paint(
    Canvas canvas,
    Offset center,
    double radius, {
    required double age,
    required bool reducedMotion,
  }) {
    if (!age.isFinite || age < 0 || age >= hitSeconds) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radius);
    if (reducedMotion) {
      // One stationary, non-flashing mark holds, then fades out.
      final alpha = 1 - _smooth(.72, 1, age / hitSeconds);
      canvas.translate(-.2, 0);
      _pow(canvas, 1.05, 0, alpha);
      canvas.restore();
      return;
    }
    // Rock chips tumble away first, so everything else draws over them.
    for (final chip in _chips) {
      _chip(canvas, chip, age);
    }
    // Comic speed streaks burst back toward the bird.
    for (final streak in _streaks) {
      _streak(canvas, streak, age);
    }
    // A crescent shock opens toward the bird, behind the pow.
    final wave = age / .11;
    if (wave < 1) {
      final grow = 1 - math.pow(1 - wave, 3).toDouble();
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: .38 + grow * .6),
        math.pi * .64,
        math.pi * .72,
        false,
        Paint()
          ..color = _white
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = .16 * (1 - wave),
      );
    }
    // The pow lands at full size on the contact frame, swells a touch and
    // snaps shut before it can hide the face.
    final size = age < .035
        ? 1 + .12 * math.sin(age / .035 * math.pi)
        : 1 - math.pow(((age - .035) / .075).clamp(0.0, 1.0), 2).toDouble();
    if (size > 0) _pow(canvas, size, age * 2.2, 1);
    canvas.restore();
  }

  static const _white = Color(0xfffffcf2);

  /// Irregular seven-point comic burst, stretched a little toward the bird.
  static final _burst = () {
    const reach = [1.0, .74, .93, .7, .98, .78, .88];
    final path = Path();
    for (var i = 0; i < 14; i++) {
      final angle = math.pi + (i / 14) * math.pi * 2 + (i.isEven ? .05 : 0);
      final r = i.isEven ? reach[i ~/ 2] : .46;
      final at = Offset(math.cos(angle) * r * 1.12, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(at.dx, at.dy);
      } else {
        path.lineTo(at.dx, at.dy);
      }
    }
    return path..close();
  }();

  static void _pow(Canvas canvas, double size, double spin, double alpha) {
    canvas.save();
    canvas.scale(.5 * size);
    canvas.rotate(spin);
    canvas.drawPath(
      _burst,
      Paint()
        ..color = SkyColors.coralDeep.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .24
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      _burst,
      Paint()..color = SkyColors.yellow.withValues(alpha: alpha),
    );
    canvas.scale(.52);
    canvas.drawPath(_burst, Paint()..color = _white.withValues(alpha: alpha));
    canvas.restore();
  }

  /// (direction, reach) of each tapered streak; y points down.
  static const _streaks = [(math.pi, 1.05), (2.62, .85), (3.72, .9)];

  static void _streak(Canvas canvas, (double, double) streak, double age) {
    final (angle, reach) = streak;
    final t = age / .13;
    if (t >= 1) return;
    // The head shoots out; the tail lags, then catches up and closes it.
    final head = .42 + reach * (1 - math.pow(1 - t, 3).toDouble());
    final tail = .42 + reach * t * t;
    final width = .2 * (1 - t);
    final along = Offset(math.cos(angle), math.sin(angle));
    final across = Offset(-along.dy, along.dx) * width / 2;
    final wedge = Path()
      ..moveTo(along.dx * head, along.dy * head)
      ..lineTo(along.dx * tail + across.dx, along.dy * tail + across.dy)
      ..lineTo(along.dx * tail - across.dx, along.dy * tail - across.dy)
      ..close();
    final paint = Paint()
      ..color = SkyColors.coral
      ..strokeWidth = width * .45
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(wedge, paint);
    canvas.drawPath(wedge, paint..style = PaintingStyle.stroke);
  }

  /// Pieces of the spent rock: (direction, travel, size, lifetime, spin).
  static const _chips = [
    (3.9, .7, .17, .21, 9.0),
    (2.75, .85, .14, .19, -11.0),
  ];

  // A split wedge of the rock's shell with a lit top facet.
  static final _chipShape = Path()
    ..moveTo(-1, -.15)
    ..lineTo(.15, -.95)
    ..lineTo(1, .1)
    ..lineTo(.3, .8)
    ..lineTo(-.6, .6)
    ..close();
  static final _chipFacet = Path()
    ..moveTo(-1, -.15)
    ..lineTo(.15, -.95)
    ..lineTo(1, .1)
    ..lineTo(0, .05)
    ..close();

  static void _chip(
    Canvas canvas,
    (double, double, double, double, double) chip,
    double age,
  ) {
    final (angle, travel, size, life, spin) = chip;
    final t = age / life;
    if (t >= 1) return;
    final out = 1 - math.pow(1 - t, 2).toDouble();
    final at =
        Offset(math.cos(angle), math.sin(angle)) * (.3 + travel * out) +
        Offset(0, .9 * t * t);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle + spin * t);
    canvas.scale(size * (t < .6 ? 1 : 1 - (t - .6) / .4));
    canvas.drawPath(
      _chipShape,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = .45
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(_chipShape, Paint()..color = const Color(0xff718986));
    canvas.drawPath(_chipFacet, Paint()..color = const Color(0xffc3cfc3));
    canvas.restore();
  }

  static double _smooth(double from, double to, double value) {
    final t = ((value - from) / (to - from)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double _channel(Color color, int c) =>
      (c == 0
          ? color.r
          : c == 1
          ? color.g
          : color.b) *
      255;
}
