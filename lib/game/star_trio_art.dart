import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'star_art.dart';

/// Approach markers and a finite constellation, driven only by replayable time.
abstract final class StarTrioArt {
  static const celebrationDuration = 1.15;

  static void paint(
    Canvas canvas,
    double height,
    StarTrio trio, {
    required double seconds,
    required bool reducedMotion,
  }) {
    final center = Offset(trio.x * height, trio.y * height);
    final completedAt = trio.completedAt;
    if (completedAt != null) {
      final age = seconds - completedAt;
      if (age < 0 || age >= celebrationDuration) return;
      final t = reducedMotion ? 1.0 : (age / .35).clamp(0.0, 1.0);
      final unfold = 1 - math.pow(1 - t, 3).toDouble();
      final alpha = reducedMotion ? 1.0 : ((1.15 - age) / .45).clamp(0.0, 1.0);
      const destinations = [
        Offset(-.075, .025),
        Offset(0, -.095),
        Offset(.075, .025),
      ];
      final points = [
        for (var i = 0; i < 3; i++)
          center +
              Offset.lerp(Offset((i - 1) * .17, 0), destinations[i], unfold)! *
                  height,
      ];
      final shape = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy)
        ..lineTo(points[2].dx, points[2].dy)
        ..close();
      canvas.drawPath(
        shape,
        Paint()..color = SkyColors.yellow.withValues(alpha: .16 * alpha),
      );
      canvas.drawPath(
        shape,
        Paint()
          ..color = SkyColors.cream.withValues(alpha: .9 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = height * .005
          ..strokeJoin = StrokeJoin.round,
      );
      for (final (i, point) in points.indexed) {
        // The three pickups, in miniature, settle into the constellation.
        StarArt.paint(
          canvas,
          point,
          height * .021,
          opacity: alpha,
          rotation: reducedMotion ? 0 : (1 - unfold) * (i - 1) * .8,
        );
      }
      return;
    }
    final alpha = trio.missed ? .13 : .6;
    // Connections identify one set without moving the actual pickup targets.
    for (var segment = 0; segment < 2; segment++) {
      final start = center + Offset((segment - 1) * .17 * height, 0);
      final end = start + Offset(.17 * height, 0);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + end.dx) / 2,
          start.dy + height * (segment == 0 ? -.035 : .035),
          end.dx,
          end.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = SkyColors.cream.withValues(alpha: alpha)
          ..strokeWidth = height * .004
          ..style = PaintingStyle.stroke,
      );
    }
    for (var i = 0; i < 3; i++) {
      if (!trio.collected(i)) continue;
      // A small star keeps the collected slot, faded when the set is lost.
      final point = center + Offset((i - 1) * .17 * height, 0);
      canvas.drawCircle(
        point,
        height * .014,
        Paint()
          ..color = SkyColors.cream.withValues(alpha: trio.missed ? .3 : .9),
      );
      if (trio.missed) {
        // A flat faded star, so a lost set holds no layer on screen.
        StarArt.sparkle(
          canvas,
          point,
          height * .011,
          SkyColors.gold.withValues(alpha: .3),
        );
      } else {
        StarArt.mini(canvas, point, height * .011);
      }
    }
  }
}
