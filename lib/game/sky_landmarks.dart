import 'dart:math' as math;
import 'dart:ui';
import '../ui/theme.dart';

/// Small distant landmarks give each region a recognizable silhouette. Their
/// position and motion depend only on the replayable simulation clock.
abstract final class SkyLandmarks {
  static void paint(
    Canvas c,
    Size size, {
    required double seconds,
    required double distance,
    required bool reducedMotion,
    required double sunrise,
    required double peach,
    required double twilight,
  }) {
    final w = size.width, h = size.height;
    final motion = reducedMotion ? 0.0 : seconds;
    final travel = reducedMotion ? 0.0 : distance * h;
    double x(double fraction, double rate, double margin) =>
        (w * fraction + margin - travel * rate) % (w + margin * 2) - margin;
    if (sunrise > 0) {
      _windmill(
        c,
        Offset(x(.38, .04, h * .18), h * .76),
        h * .26,
        motion * .16,
        sunrise * .6,
      );
      _windmill(
        c,
        Offset(x(.91, .028, h * .13), h * .66),
        h * .17,
        -motion * .13 + .4,
        sunrise * .42,
      );
    }
    if (peach > 0) {
      for (var i = 0; i < 3; i++) {
        final bob = reducedMotion
            ? 0.0
            : math.sin(motion * .35 + i * 2) * h * .014;
        _balloon(
          c,
          Offset(
            x(.40 + i * .24, .023 + i * .008, h * .09),
            h * (.32 + i % 2 * .18) + bob,
          ),
          h * (.10 + i % 2 * .025),
          i.isEven ? SkyColors.coral : SkyColors.yellow,
          peach * .58,
        );
      }
    }
    if (twilight > 0) {
      for (var i = 0; i < 4; i++) {
        final bob = reducedMotion
            ? 0.0
            : math.sin(motion * .3 + i * 1.7) * h * .018;
        _lantern(
          c,
          Offset(
            x(.33 + i * .19, .018, h * .06),
            h * (.39 + i % 3 * .13) + bob,
          ),
          h * (.045 + i % 2 * .012),
          twilight * .66,
        );
      }
      for (var i = 0; i < 14; i++) {
        final flutter = reducedMotion
            ? 0.0
            : math.sin(motion * .55 + i * 2.8) * h * .014;
        final point = Offset(
          x((i * .137 + .09) % 1, .038, h * .06),
          h * (.72 + (i % 4) * .053) + flutter,
        );
        c.drawCircle(
          point,
          h * .008,
          Paint()..color = SkyColors.mint.withValues(alpha: twilight * .10),
        );
        c.drawCircle(
          point,
          h * .0025,
          Paint()..color = SkyColors.mint.withValues(alpha: twilight * .55),
        );
      }
    }
  }

  static void _windmill(
    Canvas c,
    Offset base,
    double height,
    double angle,
    double opacity,
  ) {
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(height / 100);
    Paint fill(Color color, [double strength = 1]) =>
        Paint()..color = color.withValues(alpha: opacity * strength);
    c.drawPath(
      Path()
        ..moveTo(-47, 4)
        ..quadraticBezierTo(-15, -12, 41, 2)
        ..lineTo(18, 30)
        ..lineTo(-9, 36)
        ..lineTo(-33, 23)
        ..close(),
      fill(SkyColors.rock),
    );
    c.drawOval(const Rect.fromLTWH(-50, -8, 100, 24), fill(SkyColors.mint));
    c.drawOval(const Rect.fromLTWH(-44, -7, 88, 12), fill(SkyColors.cream, .8));
    c.drawPath(
      Path()
        ..moveTo(-16, 0)
        ..lineTo(-10, -64)
        ..lineTo(10, -64)
        ..lineTo(16, 0)
        ..close(),
      fill(SkyColors.cream),
    );
    c.drawPath(
      Path()
        ..moveTo(-15, -63)
        ..lineTo(0, -82)
        ..lineTo(15, -63)
        ..close(),
      fill(SkyColors.coral),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -16, 8, 16),
        const Radius.circular(4),
      ),
      fill(SkyColors.teal),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -44, 6, 8),
        const Radius.circular(2),
      ),
      fill(SkyColors.teal),
    );
    c.translate(0, -58);
    c.rotate(angle);
    final spoke = Paint()
      ..color = SkyColors.teal.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var blade = 0; blade < 4; blade++) {
      c.save();
      c.rotate(blade * math.pi / 2);
      c.drawLine(Offset.zero, const Offset(0, -42), spoke);
      c.drawPath(
        Path()
          ..moveTo(1, -13)
          ..lineTo(11, -17)
          ..lineTo(7, -41)
          ..lineTo(1, -42)
          ..close(),
        fill(SkyColors.cream),
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, 4, fill(SkyColors.gold));
    c.restore();
  }

  static void _balloon(
    Canvas c,
    Offset center,
    double width,
    Color color,
    double opacity,
  ) {
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(width / 60);
    final envelope = Path()
      ..moveTo(-8, 31)
      ..cubicTo(-20, 17, -30, 5, -30, -11)
      ..cubicTo(-30, -45, 30, -45, 30, -11)
      ..cubicTo(30, 5, 20, 17, 8, 31)
      ..close();
    c.drawPath(envelope, Paint()..color = color.withValues(alpha: opacity));
    c.save();
    c.clipPath(envelope);
    c.drawOval(
      const Rect.fromLTWH(-14, -41, 28, 75),
      Paint()..color = SkyColors.cream.withValues(alpha: opacity * .8),
    );
    c.restore();
    final rope = Paint()
      ..color = SkyColors.muted.withValues(alpha: opacity * .6)
      ..strokeWidth = 1.5;
    c.drawLine(const Offset(-8, 30), const Offset(-5, 43), rope);
    c.drawLine(const Offset(8, 30), const Offset(5, 43), rope);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, 41, 16, 10),
        const Radius.circular(3),
      ),
      Paint()..color = SkyColors.sand.withValues(alpha: opacity),
    );
    c.drawOval(
      const Rect.fromLTWH(-9, 26, 18, 7),
      Paint()..color = color.withValues(alpha: opacity),
    );
    c.restore();
  }

  static void _lantern(Canvas c, Offset center, double width, double opacity) {
    final glow = Rect.fromCircle(center: center, radius: width * 1.1);
    c.drawOval(
      glow,
      Paint()
        ..shader = Gradient.radial(center, width * 1.1, [
          SkyColors.cream.withValues(alpha: opacity * .17),
          SkyColors.cream.withValues(alpha: 0),
        ]),
    );
    final body = Rect.fromCenter(
      center: center,
      width: width,
      height: width * 1.3,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(width * .18)),
      Paint()..color = SkyColors.cream.withValues(alpha: opacity * .62),
    );
    c.drawLine(
      Offset(center.dx, body.top + 2),
      Offset(center.dx, body.bottom - 2),
      Paint()
        ..color = SkyColors.yellow.withValues(alpha: opacity * .4)
        ..strokeWidth = width * .25,
    );
    c.drawLine(
      Offset(body.left + 2, body.bottom),
      Offset(body.right - 2, body.bottom),
      Paint()
        ..color = SkyColors.purple.withValues(alpha: opacity)
        ..strokeWidth = 2,
    );
    final tail = Path()
      ..moveTo(center.dx, body.bottom)
      ..quadraticBezierTo(
        center.dx - width * .2,
        body.bottom + width * .3,
        center.dx + width * .1,
        body.bottom + width * .5,
      );
    c.drawPath(
      tail,
      Paint()
        ..color = SkyColors.lavender.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
