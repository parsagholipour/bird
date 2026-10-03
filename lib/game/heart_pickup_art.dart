import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';

abstract final class HeartPickupArt {
  /// A heart the birds missed drifts away this faint.
  static const missedOpacity = .5;

  static void paint(
    Canvas canvas,
    double height,
    SkyHeart heart, {
    required double seconds,
    required bool reducedMotion,
    double opacity = 1,
  }) {
    final center = Offset(heart.x * height, heart.y * height);
    if (opacity < 1) {
      canvas.saveLayer(
        Rect.fromCircle(center: center, radius: height * SkyHeart.haloRadius),
        Paint()..color = SkyColors.white.withValues(alpha: opacity),
      );
    }
    final pulse = reducedMotion ? 1.0 : 1 + math.sin(seconds * 4) * .07;
    canvas.drawCircle(
      center,
      height * .061 * pulse,
      Paint()..color = SkyColors.coral.withValues(alpha: .2),
    );
    canvas.drawCircle(
      center,
      height * .047,
      Paint()..color = SkyColors.cream.withValues(alpha: .95),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(height * SkyHeart.radius);
    final shape = Path()
      ..moveTo(0, .95)
      ..cubicTo(-.28, .68, -1, .20, -1, -.30)
      ..cubicTo(-1, -.93, -.30, -1.12, 0, -.55)
      ..cubicTo(.30, -1.12, 1, -.93, 1, -.30)
      ..cubicTo(1, .20, .28, .68, 0, .95)
      ..close();
    canvas.drawPath(shape, Paint()..color = SkyColors.coralDeep);
    canvas.drawPath(
      shape,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .08,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-.69, -.64, .29, .18),
      Paint()..color = SkyColors.white.withValues(alpha: .85),
    );
    canvas.restore();
    if (opacity < 1) canvas.restore();
  }
}
