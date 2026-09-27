import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/obstacle.dart';
import '../ui/theme.dart';
import 'gate_art.dart';
import 'obstacle_designs/crystal_steps.dart';
import 'obstacle_designs/garden_gate.dart';
import 'obstacle_designs/garden_structures.dart';
import 'obstacle_designs/lantern_drift.dart';
import 'obstacle_designs/petal_shutters.dart';
import 'obstacle_designs/sun_wheels.dart';
import 'obstacle_designs/switchback.dart';
import 'obstacle_designs/wind_lift.dart';
import 'sky_scenery.dart';

/// Every solid uses the simulation's current geometry. Decoration is clipped
/// inside that solid so a moving opening stays visually honest.
abstract final class ObstacleArt {
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
    bool refined = true,
    bool gardenStructures = true,
  }) {
    final region = accent(o, seconds);
    final color = cleared ? Color.lerp(region, SkyColors.mint, .35)! : region;
    for (final p in o.passages) {
      for (final top in [true, false]) {
        final r = Rect.fromLTRB(
          p.x * h,
          top ? -10 : p.bottom * h,
          (p.x + p.width) * h,
          top ? p.top * h : h + 10,
        );
        if (r.isEmpty) continue;
        if (refined) {
          _refinedTower(
            c,
            r,
            top: top,
            o: o,
            region: region,
            seconds: seconds,
            reducedMotion: reducedMotion,
            cleared: cleared,
            perfect: perfect,
            gardenStructures: gardenStructures,
          );
        } else if (o.kind == ObstacleKind.garden) {
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
        _rope(c, at, radius, orb.upper ? 0 : h, upper: orb.upper);
      }
      c.save();
      c.translate(at.dx, at.dy);
      if (refined) {
        final body = Rect.fromCircle(center: Offset.zero, radius: radius);
        c.save();
        c.clipPath(Path()..addOval(body));
        if (o.kind == ObstacleKind.lanternDrift) {
          LanternDriftDesign.paint(
            c,
            radius,
            accent: region,
            appearance: o.appearance,
            seconds: seconds,
            reducedMotion: reducedMotion,
            upper: orb.upper,
            cleared: cleared,
            perfect: perfect,
          );
        } else {
          SunWheelsDesign.paint(
            c,
            radius,
            accent: region,
            appearance: o.appearance,
            seconds: seconds,
            reducedMotion: reducedMotion,
            upper: orb.upper,
            cleared: cleared,
            perfect: perfect,
          );
        }
        c.restore();
      } else if (o.kind == ObstacleKind.lanternDrift) {
        _lantern(c, radius, color, o.appearance);
      } else {
        c.rotate(reducedMotion ? 0 : o.angle * (orb.upper ? 1 : -1));
        _sunWheel(c, radius, color, o.appearance);
      }
      if (cleared) {
        _clearedStar(
          c,
          radius,
          region,
          fill: perfect ? SkyColors.yellow : SkyColors.cream,
        );
      }
      c.restore();
    }
  }

  /// The cleared seal star on a floating orb: soft drop, [fill] body, a thin
  /// ink outline tinted by the accent, and a small glint on the top point.
  static void _clearedStar(
    Canvas c,
    double radius,
    Color accent, {
    required Color fill,
  }) {
    final size = radius * .25;
    final star = SkyScenery.star(Offset.zero, size);
    final drop = Offset(size * .06, size * .12);
    c.drawPath(
      star.shift(drop),
      Paint()..color = SkyColors.ink.withValues(alpha: .3),
    );
    c.drawPath(star, Paint()..color = fill);
    c.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1.0, size * .11)
        ..color = Color.lerp(SkyColors.ink, accent, .22)!,
    );
    c.drawCircle(
      Offset(-size * .1, -size * .42),
      size * .12,
      Paint()..color = SkyColors.white.withValues(alpha: .75),
    );
  }

  /// A thin twisted cord: a dusky twine core reads on pale day skies and the
  /// cream twist marks on it read at night. It tucks under the lantern's rim
  /// (painted afterwards) with a small knot where it meets the hanger.
  static void _rope(
    Canvas c,
    Offset at,
    double radius,
    double anchorY, {
    required bool upper,
  }) {
    final side = upper ? -1.0 : 1.0;
    final width = math.max(1.5, radius * .04);
    final from = at + Offset(0, side * radius * .9);
    final core = Color.lerp(SkyColors.ink, SkyColors.gold, .3)!;
    c.drawLine(
      from,
      Offset(at.dx, anchorY),
      Paint()
        ..color = core.withValues(alpha: .85)
        ..strokeWidth = width,
    );
    // Short slanted strands, stepped from the knot so the lay never crawls.
    final step = width * 2.6, half = width * .32;
    final twist = Path();
    final start = at.dy + side * radius;
    final length = (anchorY - start).abs();
    for (var d = step * .5; d < length; d += step) {
      final y = start + side * d;
      twist
        ..moveTo(at.dx - half, y - half * .9)
        ..lineTo(at.dx + half, y + half * .9);
    }
    c.drawPath(
      twist,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * .34
        ..color = SkyColors.cream.withValues(alpha: .72),
    );
    final knot = at + Offset(0, side * (radius + width * .35));
    c.drawOval(
      Rect.fromCenter(center: knot, width: width * 2.3, height: width * 1.8),
      Paint()..color = core,
    );
    c.drawCircle(
      knot + Offset(-width * .35, -width * .3),
      width * .34,
      Paint()..color = SkyColors.cream.withValues(alpha: .65),
    );
  }

  static void _refinedTower(
    Canvas c,
    Rect r, {
    required bool top,
    required Obstacle o,
    required Color region,
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
    required bool perfect,
    required bool gardenStructures,
  }) {
    c.save();
    c.clipRect(r);
    switch (o.kind) {
      case ObstacleKind.garden:
        if (gardenStructures) {
          GardenStructuresDesign.paint(
            c,
            r,
            top: top,
            seconds: seconds,
            reducedMotion: reducedMotion,
            cleared: cleared,
            perfect: perfect,
            appearance: o.appearance,
            accent: region,
          );
          break;
        }
        GardenGateDesign.paint(
          c,
          r,
          top: top,
          seconds: seconds,
          reducedMotion: reducedMotion,
          cleared: cleared,
          perfect: perfect,
          appearance: o.appearance,
          accent: region,
        );
      case ObstacleKind.windLift:
        WindLiftDesign.paint(
          c,
          r,
          top: top,
          seconds: seconds,
          reducedMotion: reducedMotion,
          cleared: cleared,
          perfect: perfect,
          appearance: o.appearance,
          accent: region,
        );
      case ObstacleKind.petalGate:
        PetalShuttersDesign.paint(
          c,
          r,
          top: top,
          seconds: seconds,
          reducedMotion: reducedMotion,
          cleared: cleared,
          perfect: perfect,
          appearance: o.appearance,
          accent: region,
        );
      case ObstacleKind.switchback:
        SwitchbackDesign.paint(
          c,
          r,
          top: top,
          seconds: seconds,
          reducedMotion: reducedMotion,
          cleared: cleared,
          perfect: perfect,
          appearance: o.appearance,
          accent: region,
        );
      case ObstacleKind.crystalSteps:
        CrystalStepsDesign.paint(
          c,
          r,
          top: top,
          seconds: seconds,
          reducedMotion: reducedMotion,
          cleared: cleared,
          perfect: perfect,
          appearance: o.appearance,
          accent: region,
        );
      case ObstacleKind.lanternDrift:
      case ObstacleKind.sunWheels:
        break;
    }
    c.restore();
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
