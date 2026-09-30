import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Opaque storybook garden ruin, clipped to the collision rectangle.
abstract final class GardenGateDesign {
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
    WorldRegion? held,
  }) {
    if (!r.isFinite || r.isEmpty) return;
    final sky = SkyPalette.at(seconds, held: held);
    final motif = (appearance % 3 + 3) % 3;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    final light = mix(SkyColors.cream, sky.haze, .16);
    final alt = mix(SkyColors.sand, sky.land, .18);
    final mortar = mix(SkyColors.rock, sky.haze, .22);
    final recess = mix(SkyColors.rock, sky.land, .5);
    final shade = mix(SkyColors.ink, sky.land, .5);
    final moss = mix(SkyColors.mint, sky.land, .45);
    final leafC = mix(SkyColors.mint, sky.land, .12);
    final sway = reducedMotion ? 0.0 : math.sin(seconds * 1.35) * 1.6;
    final rim = top ? r.bottom : r.top;
    final inward = top ? -1.0 : 1.0;

    void slab(Rect b, Color color, [double radius = 2]) {
      if (b.width < 3 || b.height < 3) return;
      c.drawRRect(
        RRect.fromRectAndRadius(b, Radius.circular(radius)),
        Paint()..color = color,
      );
    }

    void leaf(Offset p, double s) {
      c.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(p.dx + 9 * s, p.dy - 5, p.dx + 13 * s, p.dy)
          ..quadraticBezierTo(p.dx + 6 * s, p.dy + 4, p.dx, p.dy),
        Paint()..color = leafC,
      );
    }

    void dot(Offset p, double radius, Color color) =>
        c.drawCircle(p, radius, Paint()..color = color);

    void band(double y, double h, Color color) {
      c.drawRect(Rect.fromLTWH(r.left, y, r.width, h), Paint()..color = color);
    }

    c.save();
    c.clipRect(r);
    c.drawRect(
      r.inflate(1),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [mortar, mix(mortar, shade, .28)],
        ).createShader(r),
    );
    if (r.width >= 22 && r.height >= 24) {
      final gap = math.min(28.0, math.max(18.0, r.height / 6));
      final y0 = top ? r.top + 3 : r.top + 12;
      final y1 = top ? r.bottom - 12 : r.bottom - 3;
      var i = 0;
      for (var y = y0; y + 8 < y1; y += gap) {
        final h = math.min(gap - 4, y1 - y);
        if (h < 6) break;
        final share = switch (motif) {
          0 => i.isEven ? .46 : .58,
          1 => .5,
          _ => i.isEven ? .4 : .64,
        };
        final cut = r.left + r.width * share;
        final a = i.isEven ? light : alt;
        final b = i.isEven ? alt : light;
        slab(Rect.fromLTRB(r.left + 3, y, cut - 2, y + h), a);
        slab(Rect.fromLTRB(cut + 2, y, r.right - 3, y + h), b);
        i++;
      }
    }
    final jamb = r.width * .18;
    final shadeRect = Rect.fromLTWH(r.right - jamb, r.top, jamb, r.height);
    c.drawRect(shadeRect, Paint()..color = shade);
    if (r.height >= 14) {
      final y = rim + inward * math.min(20.0, r.height * .34);
      final h = math.min(15.0, r.height * .18);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(r.left + r.width * .32, y),
          width: r.width * .7,
          height: h,
        ),
        Paint()..color = moss,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(r.left + r.width * .22, y - inward),
          width: r.width * .26,
          height: h * .5,
        ),
        Paint()..color = mix(moss, light, .45),
      );
    }
    const hold = 10.0, reach = 104.0;
    final face = Rect.fromLTRB(
      r.left + 3,
      math.max(r.top + 3, top ? r.bottom - hold - reach : r.top + hold),
      r.right - 3,
      math.min(r.bottom - 3, top ? r.bottom - hold : r.top + hold + reach),
    );
    final show = face.width >= 12 && face.height >= 14;
    if (show && motif == 0) {
      final x = face.left + face.width * .3;
      slab(Rect.fromLTRB(x - 5, face.top, x + 5, face.bottom), recess, 5);
      final farY = top ? face.top + 3 : face.bottom - 3;
      final nearY = top ? face.bottom - 3 : face.top + 3;
      final mid = Offset(x + 8 + sway, (farY + nearY) / 2);
      final end = Offset(x + sway * .35, nearY);
      c.drawPath(
        Path()
          ..moveTo(x, farY)
          ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy),
        Paint()
          ..color = mix(SkyColors.teal, leafC, .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      final n = math.min(4, math.max(1, (face.height / 22).floor()));
      for (var i = 0; i < n; i++) {
        final t = (i + 1) / (n + 1);
        final side = i.isEven ? 1.0 : -1.0;
        leaf(Offset(x + sway * t, farY + (nearY - farY) * t), side);
      }
      dot(end, 3.5, SkyColors.cream);
      dot(end, 2.1, accent);
    } else if (show && motif == 1) {
      final h = math.min(face.height, math.max(18.0, face.width * 1.2));
      final arch = Rect.fromLTWH(
        face.left + face.width * .14,
        top ? face.bottom - h : face.top,
        face.width * .68,
        h,
      );
      if (arch.width >= 12 && arch.height >= 14) {
        final radius = Radius.circular(
          math.min(arch.width * .5, math.max(5.0, arch.height * .46)),
        );
        final outer = RRect.fromRectAndCorners(
          arch,
          topLeft: top ? radius : Radius.zero,
          topRight: top ? radius : Radius.zero,
          bottomLeft: top ? Radius.zero : radius,
          bottomRight: top ? Radius.zero : radius,
        );
        c.drawRRect(outer, Paint()..color = recess);
        c.drawRRect(outer.deflate(3), Paint()..color = light);
        final crown = top ? arch.top : arch.bottom;
        final dy = (top ? 1 : -1) * arch.width * .18;
        slab(
          Rect.fromCenter(
            center: Offset(arch.center.dx, crown + dy),
            width: arch.width * .26,
            height: 7,
          ),
          accent,
        );
        final sill = top ? arch.bottom - 4 : arch.top + 4;
        leaf(Offset(arch.left + 2, sill), 1.0);
      }
    } else if (show) {
      final panelH = math.min(face.height, 76.0);
      final panel = Rect.fromLTWH(
        face.left + face.width * .18,
        top ? face.bottom - panelH : face.top,
        face.width * .64,
        panelH,
      );
      if (panel.width >= 10 && panel.height >= 16) {
        slab(panel, light, 4);
        final n = math.min(3, math.max(1, (panel.height / 24).floor()));
        final step = panel.height / n;
        for (var i = 0; i < n; i++) {
          final y = panel.top + step * (i + .5);
          final s = math.min(panel.width * .24, step * .34);
          if (s < 3) continue;
          final cx = panel.center.dx;
          c.drawPath(
            Path()
              ..moveTo(cx, y - s)
              ..lineTo(cx + s * .85, y)
              ..lineTo(cx, y + s)
              ..lineTo(cx - s * .85, y)
              ..close(),
            Paint()..color = i == n ~/ 2 ? accent : recess,
          );
        }
        final y = top ? panel.bottom - 9 : panel.top + 9;
        leaf(Offset(panel.left - 1 + sway, y), 1.0);
      }
    }
    final lip = math.min(4.0, r.height);
    final lipY = top ? r.bottom - lip : r.top;
    final stone = mix(SkyColors.rock, sky.land, .32);
    if (r.height - lip >= 2) {
      final bevel = math.min(3.0, r.height - lip);
      band(top ? lipY - bevel : lipY + lip, bevel, stone);
    }
    band(lipY, lip, SkyColors.cream);
    if (lip >= 3) band(top ? lipY + lip - 1.2 : lipY, 1.2, SkyColors.white);
    if (cleared && r.shortestSide >= 16) {
      final room = ((r.height - 16) / 11).floor();
      final n = perfect ? math.min(3, math.max(1, room)) : 1;
      final x = r.right - math.max(6.0, r.width * .1);
      final petal = perfect ? SkyColors.yellow : SkyColors.mint;
      final heart = perfect ? SkyColors.coralDeep : SkyColors.coral;
      for (var i = 0; i < n; i++) {
        final at = Offset(x, rim + inward * (15.0 + i * 11));
        dot(at, perfect ? 3.3 : 2.7, petal);
        dot(at, 1.2, heart);
      }
    }
    c.restore();
  }
}
