import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../ui/theme.dart';
import 'sky_scenery.dart';

/// The solid tower has a constant outline; regional details stay inside it.
abstract final class GateArt {
  static void paint(
    Canvas c,
    Rect r, {
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
    required bool perfect,
  }) {
    if (r.isEmpty) return;
    final palette = SkyPalette.at(seconds);
    final sunrise = SkyPalette.regionWeight(seconds, 0);
    final peach = SkyPalette.regionWeight(seconds, 1);
    final twilight = SkyPalette.regionWeight(seconds, 2);
    Color stone(Color day, Color warm, Color night) => Color.from(
      alpha: 1,
      red: day.r * sunrise + warm.r * peach + night.r * twilight,
      green: day.g * sunrise + warm.g * peach + night.g * twilight,
      blue: day.b * sunrise + warm.b * peach + night.b * twilight,
    );
    final base = stone(
      SkyColors.sand,
      const Color(0xffd9a89b),
      const Color(0xff65729b),
    );
    final light = stone(
      const Color(0xffe6ceb1),
      const Color(0xfff7d2b3),
      const Color(0xff9ba7c3),
    );
    final shade = stone(
      SkyColors.rock,
      const Color(0xffb37f80),
      const Color(0xff434e78),
    );
    // Clip decorative marks to solid material, especially the short endpoint towers.
    c.save();
    c.clipRect(Rect.fromLTRB(r.left - 5, r.top, r.right + 5, r.bottom));
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          colors: [base, light, shade],
          stops: const [0, .3, 1],
        ).createShader(r),
    );
    c.drawRect(
      Rect.fromLTWH(r.left + r.width * .68, r.top, r.width * .32, r.height),
      Paint()..color = shade.withValues(alpha: .6),
    );
    final depth = math.min(17.0, r.height);
    final edge = top ? r.bottom - depth : r.top;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left - 5, edge, r.width + 10, depth),
        const Radius.circular(7),
      ),
      Paint()..color = palette.land,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          r.left - 5,
          top ? r.bottom - math.min(8, depth) : edge,
          r.width + 10,
          math.min(8, depth),
        ),
        const Radius.circular(5),
      ),
      Paint()..color = Color.lerp(palette.land, SkyColors.cream, .4)!,
    );
    final direction = top ? -1.0 : 1.0;
    final rim = top ? r.bottom : r.top;
    final texture = Paint()
      ..color = SkyColors.cream.withValues(alpha: .25)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (double y = r.top + 40; y < r.bottom - 25; y += 48) {
      c.drawLine(
        Offset(r.left + 8, y),
        Offset(r.left + r.width * .55, y - 4),
        texture,
      );
    }
    if (sunrise > 0) _leaves(c, r, rim, direction, palette, sunrise);
    if (peach > 0) _festival(c, r, rim, direction, peach);
    if (twilight > 0) {
      _lantern(c, r, rim, direction, seconds, reducedMotion, twilight);
    }
    if (cleared) {
      for (var i = 0; i < (perfect ? 3 : 1); i++) {
        final center = Offset(
          r.left + r.width * (perfect ? .2 + i * .3 : .5),
          edge + depth / 2,
        );
        final petals = Paint()
          ..color = perfect ? SkyColors.yellow : SkyColors.cream;
        for (var petal = 0; petal < 5; petal++) {
          final a = petal * math.pi * 2 / 5;
          c.drawCircle(
            center + Offset(math.cos(a), math.sin(a)) * 3,
            2.5,
            petals,
          );
        }
        c.drawCircle(center, 2, Paint()..color = SkyColors.coralDeep);
      }
    }
    c.restore();
  }

  static void _leaves(
    Canvas c,
    Rect r,
    double rim,
    double direction,
    SkyPalette palette,
    double alpha,
  ) {
    final y = rim + 23 * direction;
    c.drawPath(
      Path()
        ..moveTo(r.left + r.width * .25, y)
        ..quadraticBezierTo(
          r.right - 3,
          y + 18 * direction,
          r.left + r.width * .3,
          y + 42 * direction,
        ),
      Paint()
        ..color = palette.land.withValues(alpha: .7 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 3; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(
            r.left + r.width * (.32 + i % 2 * .25),
            y + i * 12 * direction,
          ),
          width: 10,
          height: 5,
        ),
        Paint()
          ..color = Color.lerp(
            palette.land,
            SkyColors.mint,
            .5,
          )!.withValues(alpha: alpha),
      );
    }
  }

  static void _festival(
    Canvas c,
    Rect r,
    double rim,
    double direction,
    double alpha,
  ) {
    final y = rim + 24 * direction;
    c.drawPath(
      Path()
        ..moveTo(r.left + 2, y)
        ..quadraticBezierTo(r.center.dx, y + 10 * direction, r.right - 2, y),
      Paint()
        ..color = SkyColors.cream.withValues(alpha: alpha * .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    for (var i = 0; i < 3; i++) {
      final x = r.left + r.width * (.2 + i * .3);
      final py = y + (i == 1 ? 4 : 2) * direction;
      c.drawPath(
        Path()
          ..moveTo(x - 5, py)
          ..lineTo(x + 5, py)
          ..lineTo(x, py + 11 * direction)
          ..close(),
        Paint()
          ..color = [
            SkyColors.coral,
            SkyColors.cream,
            SkyColors.yellow,
          ][i].withValues(alpha: alpha),
      );
    }
    final center = Offset(r.center.dx, rim + 65 * direction);
    c.drawCircle(
      center,
      8,
      Paint()..color = SkyColors.coralDeep.withValues(alpha: .5 * alpha),
    );
    c.drawPath(
      SkyScenery.star(center, 5),
      Paint()..color = SkyColors.cream.withValues(alpha: alpha),
    );
  }

  static void _lantern(
    Canvas c,
    Rect r,
    double rim,
    double direction,
    double seconds,
    bool reduced,
    double alpha,
  ) {
    final center = Offset(r.center.dx, rim + 39 * direction);
    final glow = reduced
        ? 1.0
        : .88 + math.sin(seconds * 1.8 + r.center.dx * .01) * .12;
    c.save();
    c.clipRect(r);
    c.drawCircle(
      center,
      r.width * .48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.yellow.withValues(alpha: .3 * alpha * glow),
            SkyColors.yellow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r.width * .48)),
    );
    c.restore();
    final lamp = Rect.fromCenter(
      center: center,
      width: r.width * .34,
      height: 24,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(lamp, const Radius.circular(5)),
      Paint()..color = SkyColors.cream.withValues(alpha: .92 * alpha),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(lamp.deflate(3), const Radius.circular(3)),
      Paint()..color = SkyColors.yellow.withValues(alpha: .85 * alpha),
    );
    final pen = Paint()
      ..color = SkyColors.gold.withValues(alpha: alpha)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawLine(lamp.topLeft, lamp.topRight, pen);
    c.drawLine(lamp.bottomLeft, lamp.bottomRight, pen);
    c.drawLine(
      Offset(center.dx, lamp.top),
      Offset(center.dx, lamp.bottom),
      pen..strokeWidth = 1,
    );
    for (var i = 0; i < 3; i++) {
      final p = Offset(
        r.left + r.width * (.23 + i % 2 * .48),
        rim + (70 + i * 24) * direction,
      );
      c.drawPath(
        SkyScenery.star(p, i.isEven ? 3 : 2),
        Paint()..color = SkyColors.cream.withValues(alpha: .65 * alpha),
      );
    }
  }
}
