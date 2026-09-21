import 'package:flutter/material.dart';

/// The same full-body guide is used before and during camera setup.
class JumpSetupArt extends CustomPainter {
  const JumpSetupArt({this.color = const Color(0xff386657)});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final unit = size.height;
    Offset point(double x, double y) => Offset(center + x * unit, y * unit);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (unit * .014).clamp(2, 6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(point(0, .21), unit * .065, paint);
    final body = Path()
      ..moveTo(point(-.11, .35).dx, point(-.11, .35).dy)
      ..lineTo(point(.11, .35).dx, point(.11, .35).dy)
      ..lineTo(point(.08, .60).dx, point(.08, .60).dy)
      ..lineTo(point(-.08, .60).dx, point(-.08, .60).dy)
      ..close();
    canvas.drawPath(body, paint);
    for (final side in [-1, 1]) {
      canvas.drawLine(point(side * .11, .35), point(side * .19, .56), paint);
      canvas.drawLine(point(side * .07, .60), point(side * .10, .84), paint);
      canvas.drawLine(point(side * .10, .84), point(side * .15, .84), paint);
    }
    paint.color = color.withValues(alpha: .45);
    canvas.drawLine(point(-.23, .9), point(.23, .9), paint);
    canvas.drawLine(point(.28, .59), point(.28, .33), paint);
    canvas.drawLine(point(.28, .33), point(.23, .39), paint);
    canvas.drawLine(point(.28, .33), point(.33, .39), paint);
  }

  @override
  bool shouldRepaint(covariant JumpSetupArt oldDelegate) =>
      color != oldDelegate.color;
}
