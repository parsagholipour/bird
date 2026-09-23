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
        homestead: true,
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
      for (var i = 0; i < 4; i++) {
        _tree(
          c,
          Offset(x(.18 + i * .2, .03, h * .08), h * (.74 + (i % 2) * .03)),
          h * (.055 + (i % 2) * .012),
          peach * .62,
        );
      }
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
      for (var i = 0; i < 2; i++) {
        _trellis(
          c,
          Offset(x(.22 + i * .48, .026, h * .12), h * .78),
          h * .2,
          twilight * .55,
        );
      }
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
          h * .012,
          Paint()..color = SkyColors.mint.withValues(alpha: twilight * .12),
        );
        c.drawPath(
          _spark(point, h * .0045),
          Paint()..color = SkyColors.cream.withValues(alpha: twilight * .7),
        );
      }
    }
  }

  static void _windmill(
    Canvas c,
    Offset base,
    double height,
    double angle,
    double opacity, {
    bool homestead = false,
  }) {
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
        ..moveTo(2, -64)
        ..lineTo(10, -64)
        ..lineTo(16, 0)
        ..lineTo(4, 0)
        ..close(),
      fill(SkyColors.sand, .55),
    );
    c.drawCircle(const Offset(0, -36), 5.5, fill(SkyColors.yellow, .9));
    c.drawCircle(const Offset(-1.4, -37.4), 1.8, fill(SkyColors.cream));
    for (final (dx, color) in [
      (-28.0, SkyColors.coral),
      (-16.0, SkyColors.yellow),
      (18.0, SkyColors.coral),
      (30.0, SkyColors.yellow),
    ]) {
      c.drawCircle(Offset(dx, -1), 3.2, fill(color, .9));
      c.drawCircle(Offset(dx, -1), 1.1, fill(SkyColors.cream));
    }
    if (homestead) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, -18, 26, 20),
          const Radius.circular(3),
        ),
        fill(SkyColors.cream),
      );
      c.drawPath(
        Path()
          ..moveTo(20, -16)
          ..lineTo(37, -34)
          ..lineTo(54, -16)
          ..close(),
        fill(SkyColors.coral),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(33, -10, 8, 12),
          const Radius.circular(2),
        ),
        fill(SkyColors.teal),
      );
      c.drawCircle(const Offset(29, -8), 2.5, fill(SkyColors.yellow, .95));
    }
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
    c.translate(0, -58);
    c.rotate(angle);
    final spoke = Paint()
      ..color = SkyColors.teal.withValues(alpha: opacity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var blade = 0; blade < 4; blade++) {
      c.save();
      c.rotate(blade * math.pi / 2);
      c.drawLine(Offset.zero, const Offset(0, -40), spoke);
      c.drawPath(
        Path()
          ..moveTo(1, -8)
          ..quadraticBezierTo(18, -14, 20, -30)
          ..quadraticBezierTo(12, -44, 1, -42)
          ..close(),
        fill(SkyColors.cream),
      );
      c.drawPath(
        Path()
          ..moveTo(1, -16)
          ..quadraticBezierTo(11, -20, 12, -32)
          ..quadraticBezierTo(7, -38, 1, -36)
          ..close(),
        fill(SkyColors.teal, .75),
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, 5, fill(SkyColors.gold));
    c.drawCircle(const Offset(-1.2, -1.2), 1.8, fill(SkyColors.cream));
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
    c.drawRect(
      const Rect.fromLTWH(-22, -46, 8, 78),
      Paint()..color = SkyColors.cream.withValues(alpha: opacity * .28),
    );
    c.drawRect(
      const Rect.fromLTWH(8, -46, 7, 78),
      Paint()..color = SkyColors.cream.withValues(alpha: opacity * .22),
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
    c.drawLine(const Offset(-6, 44), const Offset(6, 44), rope);
    c.drawLine(const Offset(-6, 48), const Offset(6, 48), rope);
    c.drawLine(const Offset(8, 44), const Offset(18, 50), rope);
    c.drawPath(
      Path()
        ..moveTo(18, 48)
        ..lineTo(30, 46)
        ..lineTo(18, 54)
        ..close(),
      Paint()..color = color.withValues(alpha: opacity),
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
    c.drawLine(
      Offset(center.dx, body.top - width * .7),
      Offset(center.dx, body.top),
      Paint()
        ..color = SkyColors.purple.withValues(alpha: opacity * .7)
        ..strokeWidth = 1.2,
    );
    c.drawPath(
      Path()
        ..moveTo(body.left + width * .12, body.top)
        ..lineTo(center.dx, body.top - width * .28)
        ..lineTo(body.right - width * .12, body.top)
        ..close(),
      Paint()..color = SkyColors.purple.withValues(alpha: opacity),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(width * .22)),
      Paint()..color = SkyColors.cream.withValues(alpha: opacity * .7),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        body.deflate(width * .16),
        Radius.circular(width * .12),
      ),
      Paint()..color = SkyColors.yellow.withValues(alpha: opacity * .55),
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
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          body.left - width * .04,
          body.bottom - width * .06,
          body.right + width * .04,
          body.bottom + width * .08,
        ),
        Radius.circular(width * .06),
      ),
      Paint()..color = SkyColors.purple.withValues(alpha: opacity),
    );
  }

  static void _tree(Canvas c, Offset base, double s, double opacity) {
    c.drawLine(
      base,
      base + Offset(0, -s * .42),
      Paint()
        ..color = SkyColors.rock.withValues(alpha: opacity)
        ..strokeWidth = s * .12
        ..strokeCap = StrokeCap.round,
    );
    final canopy = Paint()..color = SkyColors.teal.withValues(alpha: opacity);
    final crown = base + Offset(0, -s * .7);
    c.drawCircle(crown, s * .36, canopy);
    c.drawCircle(crown + Offset(-s * .22, s * .1), s * .22, canopy);
    c.drawCircle(crown + Offset(s * .2, s * .12), s * .2, canopy);
    c.drawCircle(
      crown + Offset(-s * .06, -s * .12),
      s * .12,
      Paint()..color = SkyColors.mint.withValues(alpha: opacity),
    );
  }

  static void _trellis(Canvas c, Offset base, double height, double opacity) {
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(height / 80);
    final post = Paint()
      ..color = SkyColors.purple.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-22, 6), const Offset(-22, -26), post);
    c.drawLine(const Offset(22, 6), const Offset(22, -26), post);
    c.drawArc(
      const Rect.fromLTWH(-22, -48, 44, 44),
      math.pi,
      math.pi,
      false,
      post,
    );
    final leaf = Paint()
      ..color = SkyColors.mint.withValues(alpha: opacity * .85);
    for (final p in const [
      Offset(-14, -6),
      Offset(0, -34),
      Offset(12, -2),
      Offset(-4, -20),
    ]) {
      c.drawOval(Rect.fromCenter(center: p, width: 11, height: 7), leaf);
    }
    c.drawCircle(
      const Offset(0, -18),
      3.2,
      Paint()..color = SkyColors.coral.withValues(alpha: opacity),
    );
    c.restore();
  }

  static Path _spark(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * .35, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * .35, center.dy)
      ..close()
      ..moveTo(center.dx - radius, center.dy)
      ..lineTo(center.dx, center.dy + radius * .35)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy - radius * .35)
      ..close();
  }
}
