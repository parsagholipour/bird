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
    final lip = r.height >= 10
        ? math.min(7.0, math.max(4.0, r.width * .07))
        : math.min(3.0, r.height);
    final fanR = math.min((r.width - 10) / 2, (r.height - lip - 6) / 2);
    final showFan = fanR >= 8;
    final reserve = lip + (showFan ? fanR * (variant == 1 ? 2.12 : 2) + 6 : 0);
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
        shade,
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
    if (lip > 0) _collar(c, r, top, lip, brass, perfect);
    c.restore();
  }

  /// The flight edge is a rounded brass bumper: a dark rim line against the
  /// sky, a cream glint just inside it and a soft shadow onto the column.
  static void _collar(
    Canvas c,
    Rect r,
    bool top,
    double lip,
    Color brass,
    bool perfect,
  ) {
    final y = top ? r.bottom - lip : r.top;
    final band = Rect.fromLTWH(r.left, y, r.width, lip);
    final deep = Color.lerp(brass, SkyColors.ink, .42)!;
    if (lip < 4) {
      c.drawRect(band, Paint()..color = SkyColors.cream);
      return;
    }
    final glint = perfect
        ? Color.lerp(SkyColors.yellow, SkyColors.cream, .35)!
        : Color.lerp(brass, SkyColors.cream, .72)!;
    c.drawRect(
      Rect.fromLTWH(r.left, top ? y - 3 : y + lip, r.width, 3),
      Paint()..color = SkyColors.ink.withValues(alpha: .13),
    );
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: top ? Alignment.bottomCenter : Alignment.topCenter,
          end: top ? Alignment.topCenter : Alignment.bottomCenter,
          colors: [deep, glint, glint, brass, deep],
          stops: const [0, .2, .38, .72, 1],
        ).createShader(band),
    );
    if (r.width < 30) return;
    // Two bolt heads mark the collar ends without cluttering the rim.
    final bolt = Paint()..color = Color.lerp(brass, SkyColors.ink, .25)!;
    final shine = Paint()..color = SkyColors.cream.withValues(alpha: .85);
    final cy = y + lip * (top ? .42 : .58);
    final s = math.min(1.5, lip * .22);
    for (final x in [r.left + r.width * .16, r.right - r.width * .16]) {
      c.drawCircle(Offset(x, cy), s, bolt);
      c.drawCircle(Offset(x - s * .35, cy - s * .35), s * .4, shine);
    }
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
    // Pleats run all the way to the far edge; the clip trims the last one.
    final count = math.min(40, (band.height / pitch).ceil());
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
    Color shade,
    Color brass,
    double spin,
    bool cleared,
    bool perfect,
  ) {
    final hub = Offset(
      r.center.dx,
      top ? r.bottom - lip - radius - 2 : r.top + lip + radius + 2,
    );
    final deep = Color.lerp(brass, SkyColors.ink, .38)!;
    final contact = Paint()..color = SkyColors.ink.withValues(alpha: .16);
    if (variant == 1) {
      // A squared cowl in the column's own shade keeps the brass ring round.
      final cowl = RRect.fromRectAndRadius(
        Rect.fromCircle(center: hub, radius: radius * 1.06),
        Radius.circular(radius * .36),
      );
      c.drawRRect(cowl.shift(const Offset(0, 1.6)), contact);
      c.drawRRect(cowl, Paint()..color = Color.lerp(shade, body, .35)!);
      c.drawRRect(
        cowl.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Color.lerp(body, SkyColors.cream, .35)!,
      );
    } else {
      c.drawCircle(hub + const Offset(0, 1.6), radius, contact);
    }
    final ringR = variant == 1 ? radius * .94 : radius;
    c.drawCircle(hub, ringR, Paint()..color = brass);
    // Bevel: a lit upper-left and a shaded lower-right on the brass ring.
    final bevel = Rect.fromCircle(center: hub, radius: ringR - 1.1);
    c.drawArc(
      bevel,
      math.pi * .9,
      math.pi * .8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Color.lerp(brass, SkyColors.cream, .55)!,
    );
    c.drawArc(
      bevel,
      -math.pi * .1,
      math.pi * .8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = deep,
    );
    final well = radius * .8;
    if (variant == 2 || perfect) {
      c.drawCircle(
        hub,
        (ringR + well) / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = perfect ? 2.2 : 1.6
          ..color = perfect
              ? SkyColors.yellow
              : Color.lerp(brass, SkyColors.cream, .4)!,
      );
    } else if (radius >= 14) {
      final bolt = Paint()..color = deep;
      final at = (ringR + well) / 2;
      final size = math.max(1.0, radius * .045);
      for (var i = 0; i < 4; i++) {
        final a =
            math.pi / 4 + i * math.pi / 2 + (variant == 1 ? math.pi / 4 : 0);
        c.drawCircle(hub + Offset(math.cos(a), math.sin(a)) * at, size, bolt);
      }
    }
    final disk = Rect.fromCircle(center: hub, radius: well);
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
    // The recessed well casts a thin shadow just inside its rim.
    c.drawArc(
      disk.deflate(.9),
      math.pi * 1.05,
      math.pi * .9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = SkyColors.ink.withValues(alpha: .2),
    );
    final edge = variant == 1 ? radius * 1.06 : radius;
    final yoke = Paint()
      ..color = brass
      ..strokeWidth = math.max(2.6, math.min(4.2, r.width * .07))
      ..strokeCap = StrokeCap.butt;
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
    const counts = [4, 3, 6];
    final step = math.pi * 2 / counts[variant];
    // Blade shadows fall down-right regardless of spin, then the lit blades.
    for (final (offset, paint) in [
      (
        Offset(radius * .04, radius * .06),
        Paint()..color = SkyColors.ink.withValues(alpha: .2),
      ),
      (Offset.zero, Paint()..color = Color.lerp(SkyColors.cream, body, .1)!),
    ]) {
      c.save();
      c.translate(hub.dx + offset.dx, hub.dy + offset.dy);
      c.rotate(spin);
      for (var i = 0; i < counts[variant]; i++) {
        c.drawPath(blade, paint);
        c.rotate(step);
      }
      c.restore();
    }
    c.drawArc(
      Rect.fromCircle(center: hub, radius: radius * .68),
      math.pi * 1.12,
      math.pi * .42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.cream.withValues(alpha: .55),
    );
    _hub(c, hub, radius, variant, brass, body);
    if (cleared) {
      // An ink backing keeps the cleared gem legible on the brass hub.
      final size = math.min(4.4, radius * .2);
      _gem(c, hub, SkyColors.ink.withValues(alpha: .7), size + 1.4);
      _gem(c, hub, perfect ? SkyColors.yellow : SkyColors.cream, size);
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
