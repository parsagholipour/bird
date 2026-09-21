import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/obstacle.dart';
import '../ui/theme.dart';
import 'gate_art.dart';
import 'sky_scenery.dart';

/// Every solid uses the simulation's current geometry. Decoration is clipped
/// inside that solid so a moving opening stays visually honest.
abstract final class ObstacleArt {
  static void ring(
    Canvas c,
    Rect bounds,
    Obstacle o, {
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
  }) {
    final color = cleared ? SkyColors.teal : accent(o, seconds);
    c.drawOval(
      bounds,
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    c.drawOval(
      bounds,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final count = o.kind == ObstacleKind.petalGate ? 6 : 8;
    final turn = reducedMotion || o.kind == ObstacleKind.garden
        ? 0.0
        : seconds * .16;
    for (var i = 0; i < count; i++) {
      final a = i * math.pi * 2 / count + turn;
      final at =
          bounds.center +
          Offset(
            math.cos(a) * bounds.width / 2,
            math.sin(a) * bounds.height / 2,
          );
      final radius = bounds.width * .065;
      if (o.kind == ObstacleKind.crystalSteps ||
          o.kind == ObstacleKind.switchback) {
        c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy - radius * 1.6)
            ..lineTo(at.dx + radius, at.dy)
            ..lineTo(at.dx, at.dy + radius * 1.6)
            ..lineTo(at.dx - radius, at.dy)
            ..close(),
          Paint()..color = color,
        );
      } else if (o.kind == ObstacleKind.sunWheels ||
          o.kind == ObstacleKind.petalGate) {
        c.drawPath(SkyScenery.star(at, radius * 1.5), Paint()..color = color);
      } else {
        c.drawCircle(at, radius, Paint()..color = color);
        c.drawCircle(
          at - Offset(radius * .2, radius * .2),
          radius * .3,
          Paint()..color = SkyColors.cream,
        );
      }
    }
  }

  static Color accent(Obstacle o, double seconds) {
    final colors = switch (o.kind) {
      ObstacleKind.windLift => [
        SkyColors.teal,
        SkyColors.skyDeep,
        SkyColors.mint,
      ],
      ObstacleKind.petalGate => [
        SkyColors.coral,
        SkyColors.lavender,
        SkyColors.yellow,
      ],
      ObstacleKind.switchback => [
        SkyColors.purple,
        SkyColors.teal,
        SkyColors.coralDeep,
      ],
      ObstacleKind.lanternDrift => [
        SkyColors.coral,
        SkyColors.gold,
        SkyColors.teal,
      ],
      ObstacleKind.sunWheels => [
        SkyColors.gold,
        SkyColors.coral,
        SkyColors.lavender,
      ],
      ObstacleKind.crystalSteps => [
        SkyColors.skyDeep,
        SkyColors.lavender,
        SkyColors.mint,
      ],
      _ => [SkyColors.teal, SkyColors.teal, SkyColors.teal],
    };
    return Color.lerp(
      colors[o.appearance % colors.length],
      SkyPalette.at(seconds).land,
      .16,
    )!;
  }

  static void paint(
    Canvas c,
    Obstacle o,
    double h, {
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
    required bool perfect,
  }) {
    final color = cleared
        ? Color.lerp(accent(o, seconds), SkyColors.mint, .35)!
        : accent(o, seconds);
    for (final p in o.passages) {
      for (final top in [true, false]) {
        final r = Rect.fromLTRB(
          p.x * h,
          top ? -10 : p.bottom * h,
          (p.x + p.width) * h,
          top ? p.top * h : h + 10,
        );
        if (r.isEmpty) continue;
        if (o.kind == ObstacleKind.garden) {
          GateArt.paint(
            c,
            r,
            top: top,
            seconds: seconds,
            reducedMotion: reducedMotion,
            cleared: cleared,
            perfect: perfect,
          );
        } else {
          _tower(c, r, top, o, color, reducedMotion ? 0 : seconds);
        }
      }
    }
    for (final orb in o.orbs) {
      final at = Offset(orb.x * h, orb.y * h);
      final radius = orb.radius * h;
      // Tethers point away from the flight lane and are visually distinct from
      // the filled collision bodies. Sun wheels are entirely free floating.
      if (o.kind == ObstacleKind.lanternDrift) {
        final rope = Paint()
          ..color = SkyColors.cream.withValues(alpha: .65)
          ..strokeWidth = 1.5;
        c.drawLine(
          at + Offset(0, orb.upper ? -radius : radius),
          Offset(at.dx, orb.upper ? 0 : h),
          rope,
        );
      }
      c.save();
      c.translate(at.dx, at.dy);
      if (o.kind == ObstacleKind.lanternDrift) {
        _lantern(c, radius, color, o.appearance);
      } else {
        c.rotate(reducedMotion ? 0 : o.angle * (orb.upper ? 1 : -1));
        _sunWheel(c, radius, color, o.appearance);
      }
      if (cleared) {
        c.drawPath(
          SkyScenery.star(Offset.zero, radius * .25),
          Paint()..color = SkyColors.cream,
        );
      }
      c.restore();
    }
  }

  static void _tower(
    Canvas c,
    Rect r,
    bool top,
    Obstacle o,
    Color color,
    double time,
  ) {
    c.save();
    c.clipRect(r);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, SkyColors.cream, .55)!,
            color,
            Color.lerp(color, SkyColors.ink, .23)!,
          ],
          stops: const [0, .55, 1],
        ).createShader(r),
    );
    final rim = top ? r.bottom : r.top;
    final direction = top ? -1.0 : 1.0;
    final line = Paint()
      ..color = SkyColors.cream.withValues(alpha: .65)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    switch (o.kind) {
      case ObstacleKind.windLift:
        // A mint bellows with brass rails and a broad turbine at its moving tip.
        for (double y = r.top; y < r.bottom; y += 18) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left + 6, y, r.width - 12, 10),
              const Radius.circular(5),
            ),
            Paint()..color = SkyColors.cream.withValues(alpha: .32),
          );
        }
        for (final x in [r.left + 3, r.right - 5]) {
          c.drawRect(
            Rect.fromLTWH(x, r.top, 2, r.height),
            Paint()..color = SkyColors.gold,
          );
        }
        final radius = r.width * .44;
        final hub = Offset(r.center.dx, rim + (radius + 5) * direction);
        c.drawCircle(hub, radius, Paint()..color = SkyColors.cream);
        c.drawCircle(hub, radius * .84, Paint()..color = color);
        c.save();
        c.translate(hub.dx, hub.dy);
        c.rotate(time * .8 + o.appearance);
        for (var i = 0; i < 4; i++) {
          c.rotate(math.pi / 2);
          c.drawOval(
            Rect.fromLTWH(
              -radius * .16,
              -radius * .73,
              radius * .43,
              radius * .64,
            ),
            Paint()..color = SkyColors.cream,
          );
        }
        c.drawCircle(
          Offset.zero,
          radius * .17,
          Paint()..color = SkyColors.gold,
        );
        c.restore();
      case ObstacleKind.petalGate:
        // Layered leaf shutters end in a full blossom, rather than a stone cap.
        for (
          double y = rim + 18 * direction;
          (top ? y > r.top : y < r.bottom);
          y += 30 * direction
        ) {
          c.drawPath(
            Path()
              ..moveTo(r.left, y)
              ..quadraticBezierTo(r.center.dx, y + 24 * direction, r.right, y),
            line,
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset(r.center.dx - r.width * .23, y + 13 * direction),
              width: r.width * .38,
              height: 10,
            ),
            Paint()..color = SkyColors.cream.withValues(alpha: .35),
          );
        }
        final radius = r.width * .44;
        final hub = Offset(r.center.dx, rim + (radius + 3) * direction);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          c.drawCircle(
            hub + Offset(math.cos(a), math.sin(a)) * radius * .54,
            radius * .43,
            Paint()..color = SkyColors.cream,
          );
        }
        c.drawCircle(hub, radius * .32, Paint()..color = SkyColors.gold);
        c.drawCircle(
          hub - Offset(radius * .08, radius * .08),
          radius * .09,
          Paint()..color = SkyColors.cream,
        );
      case ObstacleKind.switchback:
      case ObstacleKind.crystalSteps:
        final crystal = o.kind == ObstacleKind.crystalSteps;
        final length = r.width * (crystal ? 2.8 : 2.0);
        for (
          double y = rim;
          (top ? y > r.top - length : y < r.bottom + length);
          y += length * direction
        ) {
          final middle = y + length * .5 * direction;
          final end = y + length * direction;
          c.drawPath(
            Path()
              ..moveTo(r.left, y)
              ..lineTo(r.right, middle)
              ..lineTo(r.left, end)
              ..close(),
            Paint()
              ..color = SkyColors.cream.withValues(alpha: crystal ? .44 : .25),
          );
          c.drawPath(
            Path()
              ..moveTo(r.right, y)
              ..lineTo(r.left + r.width * .42, middle)
              ..lineTo(r.right, end)
              ..close(),
            Paint()..color = SkyColors.ink.withValues(alpha: .13),
          );
          c.drawLine(Offset(r.left, y), Offset(r.right, middle), line);
        }
        if (crystal) {
          c.drawLine(
            Offset(r.left + r.width * .2, rim),
            Offset(r.left + r.width * .2, rim + 75 * direction),
            line..strokeWidth = 3,
          );
        } else {
          final hub = Offset(r.center.dx, rim + r.width * .7 * direction);
          c.drawPath(
            SkyScenery.star(hub, r.width * .22),
            Paint()..color = SkyColors.cream,
          );
        }
      default:
        break;
    }
    // The actual moving edge stays bright and crisp against every sky region.
    c.drawRect(
      Rect.fromLTWH(r.left, top ? r.bottom - 4 : r.top, r.width, 4),
      Paint()..color = SkyColors.cream.withValues(alpha: .9),
    );
    c.restore();
  }

  static void _lantern(Canvas c, double r, Color color, int variant) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.35),
          colors: [
            SkyColors.cream,
            color,
            Color.lerp(color, SkyColors.ink, .2)!,
          ],
          stops: const [0, .6, 1],
        ).createShader(bounds),
    );
    c.save();
    c.clipPath(Path()..addOval(bounds));
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = SkyColors.cream.withValues(alpha: .7);
    for (final width in [.55, 1.35]) {
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * width, height: r * 2),
        rib,
      );
    }
    for (final y in [-.65, .65]) {
      c.drawArc(
        Rect.fromCenter(
          center: Offset(0, r * y),
          width: r * 2,
          height: r * .25,
        ),
        0,
        math.pi * 2,
        false,
        rib..strokeWidth = 1.5,
      );
    }
    final badge = variant == 1
        ? (Path()
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * .22)))
        : SkyScenery.star(Offset.zero, r * .29);
    c.drawPath(badge, Paint()..color = SkyColors.cream);
    for (final y in [-1.0, 1.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, r * y),
            width: r * .55,
            height: r * .3,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = SkyColors.gold,
      );
    }
    c.restore();
  }

  static void _sunWheel(Canvas c, double r, Color color, int variant) {
    c.drawCircle(
      Offset.zero,
      r,
      Paint()..color = Color.lerp(color, SkyColors.ink, .16)!,
    );
    c.drawCircle(Offset.zero, r * .94, Paint()..color = SkyColors.cream);
    final blades = variant == 1 ? 8 : 6;
    for (var i = 0; i < blades; i++) {
      final a = i * math.pi * 2 / blades;
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * .91),
        a,
        math.pi * 1.3 / blades,
        true,
        Paint()..color = color,
      );
    }
    c.drawCircle(Offset.zero, r * .32, Paint()..color = SkyColors.gold);
    c.drawCircle(Offset.zero, r * .18, Paint()..color = SkyColors.cream);
    c.drawCircle(
      const Offset(-2, -2),
      r * .06,
      Paint()..color = SkyColors.white,
    );
  }
}
