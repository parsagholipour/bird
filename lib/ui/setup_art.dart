import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// A readable setup illustration, separate from the camera landmark overlay.
class PushUpSetupArt extends CustomPainter {
  const PushUpSetupArt();
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 400, size.height / 140);
    canvas.save();
    canvas.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 140 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(74, 118, 276, 10),
        const Radius.circular(5),
      ),
      Paint()..color = SkyColors.teal.withValues(alpha: .25),
    );
    final view = Path()
      ..moveTo(47, 104)
      ..lineTo(154, 26)
      ..lineTo(158, 115)
      ..close();
    canvas.drawPath(
      view,
      Paint()..color = SkyColors.yellow.withValues(alpha: .18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 86, 22, 34),
        const Radius.circular(5),
      ),
      Paint()..color = SkyColors.ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 91, 14, 23),
        const Radius.circular(2),
      ),
      Paint()..color = SkyColors.sky,
    );
    canvas.drawCircle(
      const Offset(41, 89),
      1,
      Paint()..color = SkyColors.cream,
    );
    void line(Offset a, Offset b, Color color, double width) => canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    // Lower position is a quiet outline; the top position is the solid figure.
    final ghost = Paint()
      ..color = SkyColors.teal.withValues(alpha: .3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(97, 70), 12, ghost);
    canvas.drawPath(
      Path()
        ..moveTo(116, 81)
        ..lineTo(245, 99)
        ..lineTo(317, 116),
      ghost,
    );
    canvas.drawPath(
      Path()
        ..moveTo(120, 81)
        ..lineTo(136, 95)
        ..lineTo(118, 115),
      ghost,
    );
    line(const Offset(242, 82), const Offset(316, 115), SkyColors.ink, 12);
    line(const Offset(164, 63), const Offset(242, 82), SkyColors.ink, 15);
    line(const Offset(122, 52), const Offset(165, 63), SkyColors.coral, 18);
    line(
      const Offset(127, 56),
      const Offset(120, 113),
      SkyColors.coralDeep,
      10,
    );
    line(const Offset(113, 116), const Offset(130, 116), SkyColors.ink, 7);
    line(const Offset(312, 116), const Offset(328, 116), SkyColors.ink, 7);
    canvas.drawCircle(
      const Offset(102, 42),
      15,
      Paint()..color = SkyColors.gold,
    );
    canvas.drawArc(
      const Rect.fromLTWH(87, 27, 30, 30),
      3.2,
      3,
      false,
      Paint()
        ..color = SkyColors.ink
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(const Offset(94, 47), 2, Paint()..color = SkyColors.ink);
    // The direction cue is intentionally still even when Reduced Motion is off.
    final arrow = Paint()
      ..color = SkyColors.teal
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(201, 49)
        ..lineTo(201, 22)
        ..moveTo(194, 29)
        ..lineTo(201, 22)
        ..lineTo(208, 29),
      arrow,
    );
    canvas.drawCircle(
      const Offset(346, 47),
      19,
      Paint()..color = SkyColors.cream,
    );
    canvas.drawPath(
      Path()
        ..moveTo(338, 47)
        ..lineTo(344, 53)
        ..lineTo(355, 40),
      Paint()
        ..color = SkyColors.teal
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PushUpSetupArt oldDelegate) => false;
}
