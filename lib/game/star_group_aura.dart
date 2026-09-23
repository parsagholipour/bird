import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';

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
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.yellow.withValues(alpha: .30 * alpha),
            SkyColors.gold.withValues(alpha: 0),
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
  }
}
