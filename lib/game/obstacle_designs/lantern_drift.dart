import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Spherical paper lantern clipped to the circular collision body.
abstract final class LanternDriftDesign {
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
    final variant = (appearance % 3 + 3) % 3;
    final sky = SkyPalette.at(time);
    final wave = reducedMotion ? 0.0 : math.sin(time * 2.4);
    final body = _mix(
      cleared ? _mix(accent, SkyColors.mint, .4) : accent,
      sky.haze,
      .08,
    );
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius);
    c.drawCircle(Offset.zero, radius, Paint()..shader = _sphere(bounds, body));

    c.save();
    c.clipPath(Path()..addOval(bounds));
    if (radius >= 8) {
      _volume(c, radius, body, sky.haze, wave, variant, cleared);
      if (radius >= 12) _framework(c, radius);
      _caps(c, radius, upper);
      if (radius >= 15) {
        _emblem(
          c,
          radius,
          variant,
          accent,
          reducedMotion ? 1 : .82 + .18 * math.sin(time * 3.1),
        );
      }
    }
    _edge(c, radius, body, cleared);
    c.restore();
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static Shader _sphere(Rect bounds, Color body) {
    return RadialGradient(
      center: const Alignment(-.34, -.4),
      radius: 1.06,
      colors: [
        _mix(SkyColors.cream, SkyColors.yellow, .18),
        _mix(body, SkyColors.cream, .55),
        body,
        _mix(body, SkyColors.ink, .26),
      ],
      stops: const [0, .24, .6, 1],
    ).createShader(bounds);
  }

  static void _volume(
    Canvas c,
    double radius,
    Color body,
    Color haze,
    double wave,
    int variant,
    bool cleared,
  ) {
    c.drawCircle(
      Offset(radius * .44, radius * .48),
      radius * .74,
      Paint()..color = _mix(body, SkyColors.ink, .55).withValues(alpha: .16),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .4, radius * .02),
        width: radius * .3,
        height: radius * .52,
      ),
      Paint()..color = haze.withValues(alpha: .22),
    );
    final flame = cleared
        ? _mix(SkyColors.cream, SkyColors.yellow, .45)
        : switch (variant) {
            1 => _mix(SkyColors.yellow, SkyColors.coral, .35),
            2 => _mix(SkyColors.yellow, SkyColors.mint, .28),
            _ => SkyColors.yellow,
          };
    final glow = radius * .56;
    c.drawCircle(
      Offset.zero,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            flame.withValues(alpha: .42 + wave * .08),
            flame.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: glow)),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .32, -radius * .34),
        width: radius * .24,
        height: radius * .12,
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .75),
    );
  }

  static void _framework(Canvas c, double radius) {
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.35, radius * .05)
      ..color = SkyColors.cream.withValues(alpha: .84);
    final crease = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = seam.strokeWidth
      ..color = SkyColors.ink.withValues(alpha: .16);
    final rib = Rect.fromCenter(
      center: Offset.zero,
      width: radius * .7,
      height: radius * 1.9,
    );
    final nudge = Offset(radius * .025, radius * .012);
    c.drawOval(rib.shift(nudge), crease);
    c.drawOval(rib, seam);
    c.drawLine(
      Offset(nudge.dx, -radius * .64),
      Offset(nudge.dx, radius * .64),
      crease,
    );
    c.drawLine(Offset(0, -radius * .64), Offset(0, radius * .64), seam);

    final hoop = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.7, radius * .062)
      ..color = _mix(SkyColors.gold, SkyColors.cream, .18);
    for (final side in const [-1.0, 1.0]) {
      c.drawArc(
        Rect.fromCenter(
          center: Offset(0, side * radius * .46),
          width: radius * 1.84,
          height: radius * .32,
        ),
        side < 0 ? 0 : math.pi,
        math.pi,
        false,
        hoop,
      );
    }
  }

  static void _caps(Canvas c, double radius, bool upper) {
    final tether = upper ? -1.0 : 1.0;
    for (final side in const [-1.0, 1.0]) {
      final primary = side == tether;
      final width = radius * (primary ? .94 : .74);
      final inner = side * radius * (primary ? .62 : .72);
      final rect = Rect.fromLTRB(
        -width / 2,
        math.min(side * radius * 1.05, inner),
        width / 2,
        math.max(side * radius * 1.05, inner),
      );
      if (rect.width < 1 || rect.height < 1) continue;
      c.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius * .16)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _mix(SkyColors.gold, SkyColors.cream, side < 0 ? .5 : .14),
              SkyColors.gold,
              _mix(SkyColors.gold, SkyColors.coralDeep, side < 0 ? .2 : .5),
            ],
          ).createShader(rect),
      );
      if (radius < 12) continue;
      final lip = inner - side * radius * .02;
      c.drawLine(
        Offset(-width * .32, lip),
        Offset(width * .32, lip),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1, radius * .04)
          ..color = SkyColors.ink.withValues(alpha: .18),
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-radius * .1, side * radius * .8),
          width: radius * .22,
          height: radius * .065,
        ),
        Paint()..color = SkyColors.cream.withValues(alpha: side < 0 ? .8 : .4),
      );
      if (!primary) continue;
      c.drawCircle(
        Offset(0, side * radius * .83),
        radius * .055,
        Paint()..color = _mix(SkyColors.ink, SkyColors.gold, .42),
      );
    }
  }

  static void _emblem(
    Canvas c,
    double radius,
    int variant,
    Color accent,
    double starAlpha,
  ) {
    final s = radius * .33;
    final plate = switch (variant) {
      1 => _mix(SkyColors.cream, SkyColors.yellow, .28),
      2 => _mix(SkyColors.cream, SkyColors.mint, .22),
      _ => SkyColors.cream,
    };
    c.drawCircle(
      Offset(s * .06, s * .07),
      s * 1.1,
      Paint()..color = SkyColors.ink.withValues(alpha: .14),
    );
    c.drawCircle(Offset.zero, s, Paint()..color = plate);
    switch (variant) {
      case 1:
        _blossom(c, s, accent);
      case 2:
        _bird(c, s);
      default:
        _moon(c, s, starAlpha);
    }
    c.drawCircle(
      Offset.zero,
      s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, s * .15)
        ..color = SkyColors.gold,
    );
  }

  static void _moon(Canvas c, double s, double starAlpha) {
    c.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(
          Rect.fromCircle(center: Offset(-s * .12, s * .02), radius: s * .58),
        )
        ..addOval(
          Rect.fromCircle(center: Offset(s * .16, -s * .02), radius: s * .46),
        ),
      Paint()..color = SkyColors.gold,
    );
    c.drawPath(
      _spark(Offset(s * .48, -s * .4), s * .24),
      Paint()..color = SkyColors.coral.withValues(alpha: starAlpha),
    );
  }

  static void _blossom(Canvas c, double s, Color accent) {
    final petal = Paint()..color = accent;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      c.drawCircle(
        Offset(math.cos(a) * s * .38, math.sin(a) * s * .38),
        s * .28,
        petal,
      );
    }
    c.drawCircle(Offset.zero, s * .22, Paint()..color = SkyColors.gold);
    c.drawCircle(Offset.zero, s * .1, Paint()..color = SkyColors.cream);
  }

  static void _bird(Canvas c, double s) {
    final ink = Paint()..color = SkyColors.ink;
    c.drawPath(
      Path()
        ..moveTo(-s * .76, -s * .02)
        ..lineTo(-s * .34, -s * .18)
        ..lineTo(-s * .34, s * .16)
        ..close(),
      ink,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s * .02, s * .05),
        width: s * .68,
        height: s * .4,
      ),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(-s * .04, 0)
        ..quadraticBezierTo(s * .02, -s * .8, s * .58, -s * .12)
        ..quadraticBezierTo(s * .12, -s * .08, -s * .02, s * .05)
        ..close(),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(s * .3, s * .02)
        ..lineTo(s * .72, s * .1)
        ..lineTo(s * .28, s * .16)
        ..close(),
      Paint()..color = SkyColors.coralDeep,
    );
  }

  static Path _spark(Offset o, double s) {
    return Path()
      ..moveTo(o.dx, o.dy - s)
      ..lineTo(o.dx + s * .36, o.dy - s * .36)
      ..lineTo(o.dx + s, o.dy)
      ..lineTo(o.dx + s * .36, o.dy + s * .36)
      ..lineTo(o.dx, o.dy + s)
      ..lineTo(o.dx - s * .36, o.dy + s * .36)
      ..lineTo(o.dx - s, o.dy)
      ..lineTo(o.dx - s * .36, o.dy - s * .36)
      ..close();
  }

  static void _edge(Canvas c, double radius, Color body, bool cleared) {
    if (cleared && radius >= 8) {
      c.drawCircle(
        Offset.zero,
        radius * .9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, radius * .05)
          ..color = SkyColors.mint.withValues(alpha: .9),
      );
    }
    final width = math.min(radius * .42, math.max(1.35, radius * .06));
    c.drawCircle(
      Offset.zero,
      math.max(0.0, radius - width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = _mix(SkyColors.ink, body, .48).withValues(alpha: .9),
    );
    if (radius < 10) return;
    c.drawCircle(
      Offset.zero,
      math.max(0.0, radius - width - radius * .018),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, radius * .022)
        ..color = SkyColors.cream.withValues(alpha: .72),
    );
  }
}
