import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../ui/theme.dart';

/// Short, local impact accents driven entirely by the simulation clock.
abstract final class EnemyHitArt {
  static const hitSeconds = .28, defeatSeconds = .46;

  static void paint(
    Canvas canvas,
    Offset center,
    double radius, {
    required double age,
    required bool reducedMotion,
    bool defeated = false,
  }) {
    final duration = defeated ? defeatSeconds : hitSeconds;
    if (!age.isFinite || age < 0 || age >= duration) return;
    final t = age / duration;
    final fade = (1 - t) * (1 - t);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radius);

    if (reducedMotion) {
      // One stationary mark fades out; no flash, flying debris or expansion.
      _spark(canvas, Offset.zero, defeated ? .7 : .42, fade);
      canvas.restore();
      return;
    }

    final spread = 1 - math.pow(1 - t, 3).toDouble();
    final ringFade = (1 - age / (defeated ? .3 : .18)).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      .35 + spread * (defeated ? 1.45 : .75),
      Paint()
        ..color = SkyColors.gold.withValues(alpha: ringFade * .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .11 * ringFade + .025,
    );

    if (defeated) {
      // Soft little puffs give a defeated enemy volume before the sparks clear.
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 + .35;
        final at = Offset(math.cos(angle), math.sin(angle)) * (.25 + spread);
        canvas.drawCircle(
          at,
          (.28 + spread * .15) * (1 - t),
          Paint()..color = SkyColors.cream.withValues(alpha: fade * .65),
        );
      }
    }

    final count = defeated ? 9 : 5;
    for (var i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + .21;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final travel = .45 + spread * (defeated ? 1.65 : 1.05);
      final at = direction * travel * (i.isEven ? 1 : .8);
      final color = i % 3 == 0 ? SkyColors.coral : SkyColors.gold;
      canvas.drawLine(
        at - direction * (.25 * (1 - t)),
        at + direction * (.12 * (1 - t)),
        Paint()
          ..color = color.withValues(alpha: fade)
          ..strokeWidth = (i.isEven ? .12 : .09) * (1 - t)
          ..strokeCap = StrokeCap.round,
      );
      if (i % 3 == 1) {
        _spark(canvas, at, .16 * (1 - t), fade);
      }
    }

    final core = (1 - age / (defeated ? .18 : .12)).clamp(0.0, 1.0);
    if (core > 0) {
      _spark(
        canvas,
        Offset.zero,
        (defeated ? 1.05 : .65) * (.7 + core * .3),
        core,
      );
    }
    canvas.restore();
  }

  static void _spark(Canvas canvas, Offset at, double radius, double alpha) {
    final shape = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final reach = radius * (i.isEven ? 1 : .3);
      final x = at.dx + math.cos(angle) * reach;
      final y = at.dy + math.sin(angle) * reach;
      if (i == 0) {
        shape.moveTo(x, y);
      } else {
        shape.lineTo(x, y);
      }
    }
    shape.close();
    canvas.drawPath(
      shape,
      Paint()
        ..color = SkyColors.coralDeep.withValues(alpha: alpha * .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .09
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      shape,
      Paint()..color = SkyColors.cream.withValues(alpha: alpha),
    );
  }
}
