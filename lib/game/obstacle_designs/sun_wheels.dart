import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Raised sun mechanism clipped to the circular collision body.
abstract final class SunWheelsDesign {
  static void paint(
    Canvas c,
    double radius, {
    required Color accent,
    required int appearance,
    required double seconds,
    required bool reducedMotion,
    required bool upper,
    required bool cleared,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = seconds.isFinite ? math.max(0.0, seconds) : 0.0;
    final variant = _variant(appearance);
    final sky = SkyPalette.at(time);
    final tone = cleared ? _mix(accent, SkyColors.mint, .4) : accent;
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius);

    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      radius,
      Paint()..shader = _face(bounds, tone, sky),
    );
    if (radius >= 8) {
      _glaze(c, radius);
      if (radius >= 12) _rings(c, radius, variant, tone);
      _rotor(c, radius, variant, tone, time, reducedMotion, upper);
      _hub(c, radius, variant, tone, time, reducedMotion, cleared);
    }
    _rim(c, radius, tone);
    c.restore();
  }

  static int _variant(int appearance) {
    final raw = appearance % 3;
    return raw < 0 ? raw + 3 : raw;
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static Shader _face(Rect bounds, Color tone, SkyPalette sky) {
    return RadialGradient(
      center: const Alignment(-.3, -.36),
      radius: 1.05,
      colors: [
        SkyColors.cream,
        _mix(SkyColors.cream, sky.haze, .42),
        _mix(SkyColors.cream, tone, .2),
        _mix(tone, SkyColors.ink, .22),
      ],
      stops: const [0, .3, .7, 1],
    ).createShader(bounds);
  }

  static void _glaze(Canvas c, double radius) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .28, -radius * .32),
        width: radius * .4,
        height: radius * .24,
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .24),
    );
  }

  static void _rings(Canvas c, double radius, int variant, Color tone) {
    final ink = _mix(tone, SkyColors.ink, .4);
    _groove(c, radius * .9, radius, ink);
    if (variant == 1) {
      _race(c, radius, ink);
      return;
    }
    _groove(c, radius * (variant == 2 ? .46 : .5), radius, ink);
    if (variant == 2) _groove(c, radius * .74, radius, ink);
  }

  static void _groove(Canvas c, double at, double radius, Color ink) {
    final width = math.min(1.7, math.max(.65, radius * .036));
    if (at <= width) return;
    c.drawCircle(
      Offset.zero,
      at,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = ink.withValues(alpha: .82),
    );
    final lip = at - width * .65;
    if (lip <= 0) return;
    c.drawCircle(
      Offset.zero,
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.45, width * .4)
        ..color = SkyColors.cream.withValues(alpha: .8),
    );
  }

  static void _race(Canvas c, double radius, Color ink) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(2.4, math.max(.85, radius * .048))
      ..strokeCap = StrokeCap.round
      ..color = ink;
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius * .58);
    for (var i = 0; i < 8; i++) {
      c.drawArc(rect, i * math.pi / 4 - math.pi / 2, math.pi / 9, false, paint);
    }
  }

  static void _rotor(
    Canvas c,
    double radius,
    int variant,
    Color tone,
    double time,
    bool reducedMotion,
    bool upper,
  ) {
    final count = const [8, 6, 5][variant];
    c.save();
    c.rotate(_spin(time, reducedMotion, upper, count));
    final fill = switch (variant) {
      1 => _mix(tone, SkyColors.gold, .08),
      2 => _mix(tone, SkyColors.cream, .22),
      _ => _mix(tone, SkyColors.yellow, .16),
    };
    final shade = _mix(tone, SkyColors.ink, .46);
    final bevel = math.min(3.0, math.max(.7, radius * .08));
    for (var i = 0; i < count; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / count);
      final path = _blade(radius, variant);
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bevel
          ..strokeJoin = StrokeJoin.round
          ..color = shade,
      );
      c.drawPath(path, Paint()..color = fill);
      _ridge(c, radius, variant);
      if (variant == 1) _channel(c, radius, shade);
      c.restore();
    }
    if (variant == 2 && radius >= 14) _sparks(c, radius);
    c.restore();
  }

  static double _spin(double time, bool reducedMotion, bool upper, int count) {
    final rest = upper ? 0.0 : math.pi / count;
    if (reducedMotion || time == 0) return rest;
    const speed = .42;
    final period = math.pi * 2 / speed;
    final turn = (time % period) * speed;
    return upper ? rest + turn : rest - turn;
  }

  static Path _blade(double radius, int variant) => switch (variant) {
    1 => _tooth(radius),
    2 => _scimitar(radius),
    _ => _ray(radius),
  };

  static Path _ray(double r) => Path()
    ..moveTo(r * .28, -r * .04)
    ..quadraticBezierTo(r * .52, -r * .125, r * .82, 0)
    ..quadraticBezierTo(r * .52, r * .125, r * .28, r * .04)
    ..close();

  static Path _tooth(double r) {
    final inner = r * .28, outer = r * .76, root = r * .07, tip = r * .125;
    final chamfer = r * .04;
    return Path()
      ..moveTo(inner, -root)
      ..lineTo(outer - chamfer, -tip)
      ..lineTo(outer, -tip + chamfer)
      ..lineTo(outer, tip - chamfer)
      ..lineTo(outer - chamfer, tip)
      ..lineTo(inner, root)
      ..close();
  }

  static Path _scimitar(double r) => Path()
    ..moveTo(r * .3, -r * .02)
    ..cubicTo(r * .46, -r * .135, r * .68, -r * .11, r * .82, 0)
    ..quadraticBezierTo(r * .74, r * .05, r * .56, r * .032)
    ..quadraticBezierTo(r * .4, r * .07, r * .3, r * .042)
    ..close();

  static void _ridge(Canvas c, double radius, int variant) {
    final bend = switch (variant) {
      2 => -radius * .04,
      1 => radius * .015,
      _ => 0.0,
    };
    final end = radius * (variant == 1 ? .62 : .68);
    c.drawPath(
      Path()
        ..moveTo(radius * .4, bend * .25)
        ..quadraticBezierTo(radius * .54, bend, end, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(1.5, math.max(.55, radius * .028))
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.cream.withValues(alpha: .9),
    );
  }

  static void _channel(Canvas c, double radius, Color shade) {
    c.drawLine(
      Offset(radius * .42, radius * .02),
      Offset(radius * .62, radius * .02),
      Paint()
        ..strokeWidth = math.min(1.6, math.max(.6, radius * .032))
        ..strokeCap = StrokeCap.round
        ..color = shade,
    );
  }

  static void _sparks(Canvas c, double radius) {
    final fill = Paint()..color = _mix(SkyColors.cream, SkyColors.yellow, .35);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.55, radius * .018)
      ..color = _mix(SkyColors.gold, SkyColors.ink, .3);
    for (var i = 0; i < 5; i++) {
      final angle = (i + .5) * math.pi * 2 / 5;
      c.save();
      c.translate(
        math.cos(angle) * radius * .58,
        math.sin(angle) * radius * .58,
      );
      c.rotate(angle + math.pi / 2);
      final gem = _ngon(4, radius * .055, -math.pi / 2);
      c.drawPath(gem, fill);
      c.drawPath(gem, edge);
      c.restore();
    }
  }

  static void _hub(
    Canvas c,
    double radius,
    int variant,
    Color tone,
    double time,
    bool reducedMotion,
    bool cleared,
  ) {
    final plate = radius * .36;
    c.drawCircle(
      Offset.zero,
      plate,
      Paint()..color = _mix(SkyColors.sand, SkyColors.cream, .48),
    );
    c.drawCircle(
      Offset.zero,
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(1.7, math.max(.55, radius * .034))
        ..color = _mix(SkyColors.gold, SkyColors.ink, .4),
    );
    if (radius >= 12) {
      c.drawCircle(
        Offset.zero,
        radius * .27,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.min(2.8, math.max(.75, radius * .07))
          ..color = _mix(SkyColors.ink, tone, .58),
      );
    }
    if (radius >= 16) _balls(c, radius);
    _jewel(c, radius, variant, tone, time, reducedMotion, cleared);
  }

  static void _balls(Canvas c, double radius) {
    final orbit = radius * .27;
    final ball = radius * .046;
    final metal = _mix(SkyColors.sand, SkyColors.ink, .22);
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      final at = Offset(math.cos(angle) * orbit, math.sin(angle) * orbit);
      c.drawCircle(at, ball, Paint()..color = metal);
      c.drawCircle(
        at + Offset(-ball * .28, -ball * .32),
        ball * .36,
        Paint()..color = SkyColors.cream,
      );
    }
  }

  static void _jewel(
    Canvas c,
    double radius,
    int variant,
    Color tone,
    double time,
    bool reducedMotion,
    bool cleared,
  ) {
    final size = radius * (variant == 2 ? .16 : .145);
    if (size < .4) return;
    final shape = switch (variant) {
      1 => _ngon(6, size, -math.pi / 2),
      2 => _ngon(4, size, -math.pi / 2),
      _ => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size)),
    };
    c.drawCircle(
      Offset.zero,
      size * 1.28,
      Paint()..color = _mix(SkyColors.ink, SkyColors.gold, .28),
    );
    c.drawPath(
      shape,
      Paint()
        ..color = _mix(tone, cleared ? SkyColors.cream : SkyColors.yellow, .38),
    );
    final gleam = reducedMotion ? .6 : _pulse(time);
    c.save();
    c.clipPath(shape);
    c.drawCircle(
      Offset(size * .3, size * .34),
      size * .76,
      Paint()..color = _mix(tone, SkyColors.ink, .34).withValues(alpha: .6),
    );
    c.drawCircle(
      Offset(-size * .28, -size * .32),
      size * .22,
      Paint()..color = SkyColors.white.withValues(alpha: gleam),
    );
    c.restore();
  }

  static double _pulse(double time) {
    const period = math.pi * 2 / 2.15;
    final local = (time % period) * 2.15;
    return .42 + .4 * (math.sin(local) * .5 + .5);
  }

  static Path _ngon(int sides, double radius, double turn) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = turn + i * math.pi * 2 / sides;
      final x = math.cos(angle) * radius, y = math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  static void _rim(Canvas c, double radius, Color tone) {
    final width = math.min(radius * .18, math.max(radius * .07, 1.25));
    c.drawCircle(
      Offset.zero,
      math.max(0.0, radius - width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = _mix(tone, SkyColors.ink, .44),
    );
    final lip = math.min(width * .38, radius * .04);
    final lipAt = radius - width - lip / 2;
    if (lipAt <= 0 || lip <= 0) return;
    c.drawCircle(
      Offset.zero,
      lipAt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lip
        ..color = _mix(
          SkyColors.cream,
          SkyColors.yellow,
          .3,
        ).withValues(alpha: .92),
    );
  }
}
