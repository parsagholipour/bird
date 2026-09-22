import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Solid blossom column: overlapping petal plates, veins, and a warm heart.
abstract final class PetalShuttersDesign {
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
    if (r.isEmpty) return;
    final raw = appearance % 3;
    final v = raw < 0 ? raw + 3 : raw;
    final palette = SkyPalette.at(seconds);
    final dir = top ? -1.0 : 1.0;
    final rim = top ? r.bottom : r.top;
    final far = top ? r.top : r.bottom;
    final phase = seconds * 1.35 + appearance;
    final sway = reducedMotion ? 0.0 : math.sin(phase) * 1.6;
    final turn = (reducedMotion ? 0.0 : seconds) * .4 + v * .4;
    final lip = math.min(4.0, r.height);
    final room = r.height - lip;
    final radius = room < 8 ? 0.0 : math.min(r.width * .44, room * .42);
    final pale = Color.lerp(accent, SkyColors.cream, .6)!;
    final deep = Color.lerp(accent, palette.land, .38)!;
    final stemInk = Color.lerp(palette.land, SkyColors.ink, .34)!;
    final bevel = Color.lerp(accent, SkyColors.gold, .45)!;

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    void dot(Offset at, double rad, Color color) =>
        c.drawCircle(at, rad, Paint()..color = color);
    void bar(double y, double h, Color color) => c.drawRect(
      Rect.fromLTWH(r.left, y, r.width, h),
      Paint()..color = color,
    );

    void blade(double y, bool left, double slide, Color color, bool vein) {
      final s = left ? 1.0 : -1.0;
      final tip = (left ? r.left + 2 : r.right - 2) + s * slide;
      final shoulder = r.center.dx - s * r.width * (v == 1 ? .3 : .18);
      final inner = r.center.dx + s * 8;
      final pinch = v == 1 ? 2.0 : 5.0;
      c.drawPath(
        Path()
          ..moveTo(tip, y)
          ..quadraticBezierTo(shoulder, y - 16, inner, y - pinch)
          ..quadraticBezierTo(r.center.dx, y, inner, y + pinch)
          ..quadraticBezierTo(shoulder, y + 16, tip, y)
          ..close(),
        Paint()..color = color,
      );
      if (vein) {
        c.drawLine(
          Offset(inner, y),
          Offset(tip, y),
          stroke(SkyColors.cream, 1.4),
        );
      }
    }

    void scale(double y, double bow, Color color) {
      final g = -dir * bow;
      final mid = r.center.dx;
      c.drawPath(
        Path()
          ..moveTo(r.left + 2, y - g * .3)
          ..quadraticBezierTo(mid, y - g * .7, r.right - 2, y - g * .3)
          ..quadraticBezierTo(mid, y + g, r.left + 2, y - g * .3)
          ..close(),
        Paint()..color = color,
      );
    }

    c.save();
    c.clipRect(r);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(accent, SkyColors.cream, .46)!,
            Color.lerp(accent, palette.land, .18)!,
            Color.lerp(accent, SkyColors.ink, .3)!,
          ],
          stops: const [0, .46, 1],
        ).createShader(r),
    );

    final step = const [24.0, 34.0, 26.0][v];
    final inset = lip + (radius >= 4 ? radius * 1.55 : 1);
    final stop = rim + dir * inset;
    var y = far - dir * 6;
    for (var i = 0; i < 24 && (dir < 0 ? y < stop : y > stop); i++) {
      final front = i.isEven;
      if (v == 2) {
        scale(y + dir * 7, 15, deep);
        scale(y, 12 + sway.abs(), pale);
      } else {
        blade(y + dir * (v == 1 ? 8 : 5), !front, sway, deep, false);
        blade(y, front, -sway, pale, v == 1);
      }
      y += step * -dir;
    }

    final stemEnd = rim + dir * (lip + (radius >= 4 ? radius * .35 : 2));
    c.drawLine(
      Offset(r.center.dx, far - dir * 3),
      Offset(r.center.dx, stemEnd),
      stroke(stemInk, v == 1 ? 3.0 : 2.2),
    );
    if (r.height > 92 && r.width > 18) {
      final leaf = Paint()
        ..color = Color.lerp(palette.land, SkyColors.mint, .48)!;
      for (final side in [-1.0, 1.0]) {
        final o = Offset(r.center.dx, far - dir * (30 + (side < 0 ? 0 : 20)));
        final dx = side * r.width * (v == 1 ? .42 : .32);
        final dy = dir * (v == 1 ? 12 : 8);
        c.drawPath(
          Path()
            ..moveTo(o.dx, o.dy)
            ..quadraticBezierTo(o.dx + dx * .6, o.dy + dy, o.dx + dx, o.dy)
            ..quadraticBezierTo(o.dx + dx * .35, o.dy - dy, o.dx, o.dy)
            ..close(),
          leaf,
        );
      }
    }
    if (r.height >= 40) {
      final y0 = far - dir * r.height * .2;
      final y1 = rim + dir * (lip + math.max(radius, 6) + 12);
      final vein = stroke(
        SkyColors.cream.withValues(alpha: .72),
        v == 1 ? 1.6 : 1.25,
      );
      for (final side in [-1.0, 1.0]) {
        final x = r.center.dx + side * r.width * (v == 2 ? .2 : .28);
        c.drawPath(
          Path()
            ..moveTo(r.center.dx, y0)
            ..quadraticBezierTo(
              r.center.dx + sway * side,
              (y0 + y1) / 2,
              x + sway,
              y1,
            ),
          vein,
        );
      }
    }

    if (radius >= 4) {
      final hub = Offset(r.center.dx, rim + dir * (lip + radius));
      final n = const [6, 5, 8][v];
      final under = Color.lerp(accent, palette.haze, .18)!;
      final petal = Color.lerp(accent, SkyColors.cream, .7)!;
      void bloom(double rad, double angle, Color color) {
        c.save();
        c.translate(hub.dx, hub.dy);
        c.rotate(angle);
        if (v == 1) {
          c.drawPath(
            Path()
              ..moveTo(0, -rad)
              ..quadraticBezierTo(rad * .34, -rad * .36, 0, rad * .02)
              ..quadraticBezierTo(-rad * .34, -rad * .36, 0, -rad)
              ..close(),
            Paint()..color = color,
          );
        } else {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(0, -rad * .46),
              width: rad * (v == 2 ? .4 : .56),
              height: rad * .76,
            ),
            Paint()..color = color,
          );
        }
        c.restore();
      }

      final warm = Color.lerp(SkyColors.gold, palette.accent, .28)!;
      final sepal = Color.lerp(palette.land, SkyColors.mint, .42)!;
      dot(hub, radius * .9, warm);
      for (final side in [-1.0, 1.0]) {
        c.drawOval(
          Rect.fromCenter(
            center: hub + Offset(side * radius * .4, dir * radius * .46),
            width: radius * .52,
            height: radius * .28,
          ),
          Paint()..color = sepal,
        );
      }
      for (var i = 0; i < n; i++) {
        final a = turn + i * math.pi * 2 / n;
        bloom(radius, a, under);
        bloom(radius * .72, a + math.pi / n, petal);
      }
      final heart = [SkyColors.coralDeep, SkyColors.coral, SkyColors.gold][v];
      dot(hub, radius * (v == 2 ? .4 : .28), SkyColors.gold);
      dot(hub, radius * (v == 2 ? .24 : .15), heart);
      dot(
        hub + Offset(-radius * .06, -radius * .07),
        radius * .055,
        SkyColors.cream,
      );
      if (cleared) {
        c.drawCircle(
          hub,
          radius * .58,
          stroke(
            perfect ? SkyColors.yellow : SkyColors.cream,
            perfect ? 2.0 : 1.4,
          ),
        );
        final jewel = hub + Offset(0, dir * (radius + 6));
        if (perfect && r.deflate(5).contains(jewel)) {
          c.drawPath(
            SkyScenery.star(jewel, math.min(5.5, r.width * .12)),
            Paint()..color = SkyColors.cream,
          );
        }
      }
    }

    final yLip = top ? r.bottom - lip : r.top;
    bar(yLip, lip, SkyColors.cream);
    if (lip >= 3) {
      const hair = 1.15;
      bar(top ? r.bottom - hair : r.top, hair, SkyColors.white);
      bar(top ? yLip : yLip + lip - hair, hair, bevel);
    }
    c.restore();
  }
}
