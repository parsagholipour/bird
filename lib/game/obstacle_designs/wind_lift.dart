import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Brass-railed accordion column with a readable turbine at the flight lip.
abstract final class WindLiftDesign {
  static void paint(
    Canvas c,
    Rect r, {
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
    required bool perfect,
    required int appearance,
    required Color accent,
  }) {
    if (r.isEmpty || !r.width.isFinite || !r.height.isFinite) return;
    final variant = appearance % 3;
    final clock = seconds.isFinite ? seconds : 0.0;
    final palette = SkyPalette.at(clock);
    var body = Color.lerp(accent, palette.land, .18)!;
    if (cleared) body = Color.lerp(body, SkyColors.mint, .3)!;
    final light = Color.lerp(body, SkyColors.cream, .5)!;
    final shade = Color.lerp(body, SkyColors.ink, .28)!;
    final brass = Color.lerp(SkyColors.gold, palette.accent, .14)!;
    final lip = r.height >= 8 ? 4.0 : math.min(3.0, r.height);
    final fanR = math.min((r.width - 10) / 2, (r.height - lip - 6) / 2);
    final showFan = fanR >= 8;
    final reserve = lip + (showFan ? fanR * (variant == 1 ? 2.08 : 2) + 6 : 0);
    final rail = r.width >= 18
        ? math.min(4.2, math.max(3.0, r.width * .08))
        : 0.0;

    void fill(Rect rect, Color color) =>
        c.drawRect(rect, Paint()..color = color);

    c.save();
    c.clipRect(r);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [light, body, shade],
          stops: const [0, .46, 1],
        ).createShader(r),
    );
    if (rail > 0) {
      final lo = Color.lerp(brass, SkyColors.ink, .28)!;
      fill(Rect.fromLTWH(r.left, r.top, rail, r.height), brass);
      fill(Rect.fromLTWH(r.right - rail, r.top, rail, r.height), lo);
      fill(
        Rect.fromLTWH(r.left, r.top, 1.2, r.height),
        Color.lerp(brass, SkyColors.cream, .5)!,
      );
      fill(
        Rect.fromLTWH(r.right - 1.2, r.top, 1.2, r.height),
        Color.lerp(lo, SkyColors.ink, .35)!,
      );
    }
    _bellows(c, r, top, reserve, rail, light, shade, brass);
    if (showFan) {
      _turbine(
        c,
        r,
        top,
        lip,
        fanR,
        variant,
        body,
        brass,
        variant * .55 + (reducedMotion ? 0.0 : clock * .75),
        cleared,
        perfect,
      );
    } else if (cleared && r.shortestSide >= 14) {
      _gem(
        c,
        Offset(r.center.dx, top ? r.bottom - lip - 6 : r.top + lip + 6),
        perfect ? SkyColors.yellow : SkyColors.cream,
        3,
      );
    }
    if (lip > 0) {
      final y = top ? r.bottom - lip : r.top;
      fill(Rect.fromLTWH(r.left, y, r.width, lip), SkyColors.cream);
      if (lip >= 3) {
        fill(
          Rect.fromLTWH(r.left, top ? y + lip - 1 : y, r.width, 1),
          SkyColors.white,
        );
        fill(
          Rect.fromLTWH(r.left, top ? y : y + lip - 1, r.width, 1),
          Color.lerp(brass, SkyColors.sand, .25)!,
        );
      }
    }
    c.restore();
  }

  static void _bellows(
    Canvas c,
    Rect r,
    bool top,
    double reserve,
    double rail,
    Color light,
    Color shade,
    Color brass,
  ) {
    final band = top
        ? Rect.fromLTRB(r.left, r.top, r.right, r.bottom - reserve)
        : Rect.fromLTRB(r.left, r.top + reserve, r.right, r.bottom);
    final left = r.left + rail + 1, right = r.right - rail - 1;
    if (band.height < 16 || right - left < 8) return;
    final pitch = band.height < 30
        ? band.height
        : math.min(34.0, math.max(24.0, band.height / 3.5));
    final count = math.min(12, (band.height / pitch).floor());
    if (count < 1) return;
    final inset = math.min(6.0, (right - left) * .16);
    final dark = Paint()..color = shade;
    final lit = Paint()..color = light;
    final crease = Paint()
      ..color = SkyColors.cream.withValues(alpha: .8)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final clamp = Paint()..color = Color.lerp(brass, SkyColors.ink, .18)!;
    c.save();
    c.clipRect(band);
    for (var i = 0; i < count; i++) {
      final y = top ? band.bottom - (i + 1) * pitch : band.top + i * pitch;
      final mid = (left + right) / 2;
      final crest = y + pitch * .48;
      c.drawPath(
        Path()
          ..moveTo(left + inset, y + 1)
          ..quadraticBezierTo(mid, y + pitch * .18, right - inset, y + 1)
          ..lineTo(right - 1, crest)
          ..quadraticBezierTo(mid, crest - pitch * .08, left + 1, crest)
          ..close(),
        dark,
      );
      c.drawPath(
        Path()
          ..moveTo(left + 1, crest)
          ..quadraticBezierTo(mid, crest + pitch * .1, right - 1, crest)
          ..lineTo(right - inset, y + pitch - 1)
          ..quadraticBezierTo(mid, y + pitch * .84, left + inset, y + pitch - 1)
          ..close(),
        lit,
      );
      c.drawLine(Offset(left + 2, crest), Offset(right - 2, crest), crease);
      final h = math.min(6.0, pitch * .24);
      final w = math.min(4.0, r.width * .1);
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, crest - h / 2, w, h),
        const Radius.circular(1.4),
      );
      c.drawRRect(box.shift(Offset(r.left + .4, 0)), clamp);
      c.drawRRect(box.shift(Offset(r.right - w - .4, 0)), clamp);
    }
    c.restore();
  }

  static void _turbine(
    Canvas c,
    Rect r,
    bool top,
    double lip,
    double radius,
    int variant,
    Color body,
    Color brass,
    double spin,
    bool cleared,
    bool perfect,
  ) {
    final hub = Offset(
      r.center.dx,
      top ? r.bottom - lip - radius - 1.5 : r.top + lip + radius + 1.5,
    );
    final bezel = Paint()..color = brass;
    if (variant == 1) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: hub, radius: radius * 1.06),
          Radius.circular(radius * .32),
        ),
        bezel,
      );
    }
    c.drawCircle(hub, radius, bezel);
    if (variant == 2) {
      c.drawCircle(
        hub,
        radius * .9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Color.lerp(brass, SkyColors.cream, .35)!,
      );
    }
    final disk = Rect.fromCircle(center: hub, radius: radius * .8);
    c.drawOval(
      disk,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.32, -.38),
          colors: [
            Color.lerp(body, SkyColors.cream, .45)!,
            Color.lerp(body, SkyColors.ink, .32)!,
          ],
        ).createShader(disk),
    );
    final edge = radius * (variant == 1 ? 1.06 : 1);
    final yoke = Paint()
      ..color = brass
      ..strokeWidth = math.max(2.6, math.min(4.2, r.width * .07))
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(r.left, hub.dy), Offset(hub.dx - edge, hub.dy), yoke);
    c.drawLine(Offset(hub.dx + edge, hub.dy), Offset(r.right, hub.dy), yoke);
    final reach = radius * .74;
    final half = reach * const [.22, .34, .12][variant];
    final tip = reach * const [.94, .86, .98][variant];
    final blade = Path()
      ..moveTo(half, -reach * .16)
      ..quadraticBezierTo(half * 1.15, -tip * .68, reach * .05, -tip)
      ..quadraticBezierTo(-half * .25, -tip * .6, -half * .7, -reach * .12)
      ..close();
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    final bladePaint = Paint()..color = Color.lerp(SkyColors.cream, body, .1)!;
    const counts = [4, 3, 6];
    for (var i = 0; i < counts[variant]; i++) {
      c.drawPath(blade, bladePaint);
      c.rotate(math.pi * 2 / counts[variant]);
    }
    c.restore();
    c.drawArc(
      Rect.fromCircle(center: hub, radius: radius * .94),
      math.pi * 1.15,
      math.pi * .58,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = SkyColors.cream.withValues(alpha: .82),
    );
    _hub(c, hub, radius, variant, brass, body);
    if (cleared) {
      _gem(
        c,
        hub,
        perfect ? SkyColors.yellow : SkyColors.cream,
        math.min(3.8, radius * .18),
      );
    }
    if (!perfect) return;
    final pip = Paint()..color = SkyColors.yellow;
    for (final side in const [-1.0, 1.0]) {
      c.drawCircle(Offset(hub.dx + side * radius * .58, hub.dy), 2.1, pip);
    }
  }

  static void _hub(
    Canvas c,
    Offset at,
    double radius,
    int variant,
    Color brass,
    Color body,
  ) {
    final paint = Paint();
    switch (variant) {
      case 1:
        _gem(c, at, Color.lerp(brass, SkyColors.ink, .2)!, radius * .17);
        c.drawCircle(at, radius * .045, paint..color = SkyColors.cream);
      case 2:
        c.drawCircle(
          at,
          radius * .2,
          Paint()..color = Color.lerp(SkyColors.mint, body, .2)!,
        );
        c.drawCircle(
          at,
          radius * .2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = brass,
        );
        c.drawCircle(at, radius * .055, Paint()..color = SkyColors.cream);
      default:
        c.drawCircle(at, radius * .18, paint..color = brass);
        c.drawCircle(
          at + Offset(-radius * .045, -radius * .045),
          radius * .08,
          paint..color = SkyColors.cream,
        );
    }
  }

  static void _gem(Canvas c, Offset at, Color color, double s) {
    if (s < 1 || !at.dx.isFinite) return;
    c.drawPath(
      Path()
        ..moveTo(at.dx, at.dy - s)
        ..lineTo(at.dx + s * .62, at.dy)
        ..lineTo(at.dx, at.dy + s)
        ..lineTo(at.dx - s * .62, at.dy)
        ..close(),
      Paint()..color = color,
    );
  }
}
