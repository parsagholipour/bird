import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'star_art.dart';

/// A small, finite halo at the last star of a fully collected group.
/// Its anchor belongs to the course, never to the bird.
abstract final class StarGroupAura {
  static const duration = .65;

  static void paint(
    Canvas canvas,
    double height,
    StarTrio group, {
    required double seconds,
    required bool reducedMotion,
  }) {
    final at = group.completedAt;
    if (at == null || group.missed || group.collectedMask != 7) return;
    final age = seconds - at;
    if (age < 0 || age >= duration) return;
    final t = age / duration;
    final alpha = (1 - t) * (1 - t);
    final center = Offset(
      (group.x + .17) * height,
      (group.completedY ?? group.y) * height,
    );
    final radius = height * (reducedMotion ? .046 : .040 + .015 * t);
    // The waiting star's own warm light, so the reward reads as the stars'.
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            SkyColors.yellow.withValues(alpha: .32 * alpha),
            SkyColors.yellow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.35)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = SkyColors.gold.withValues(alpha: .70 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * .003,
    );
    // Five small stars ride the ring outward, points first.
    for (var i = 0; i < 5; i++) {
      final angle =
          -math.pi / 2 + i * math.pi * 2 / 5 + (reducedMotion ? 0 : t * .6);
      StarArt.sparkle(
        canvas,
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        height * .01,
        SkyColors.gold.withValues(alpha: alpha),
        rotation: angle + math.pi / 2,
      );
    }
  }
}
