import 'package:flutter/material.dart';

/// A grounded squat and a standing pose show both directions of height control.
class SquatSetupArt extends CustomPainter {
  const SquatSetupArt({this.color = const Color(0xff386657)});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = (size.width / 1.5).clamp(0.0, size.height);
    final origin = Offset(size.width / 2, (size.height - unit) / 2);
    Offset point(double x, double y) => origin + Offset(x * unit, y * unit);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (unit * .014).clamp(2, 6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(point(x1, y1), point(x2, y2), pen);
    for (final squatting in [false, true]) {
      final x = squatting ? .30 : -.30;
      final drop = squatting ? .17 : 0.0;
      canvas.drawCircle(point(x, .18 + drop), unit * .06, pen);
      line(x - .09, .31 + drop, x + .09, .31 + drop);
      line(x, .31 + drop, x, .56 + drop);
      for (final side in [-1, 1]) {
        line(x + side * .09, .31 + drop, x + side * .16, .48 + drop);
        final kneeX = x + side * (squatting ? .16 : .08);
        line(x, .56 + drop, kneeX, .73);
        line(kneeX, .73, x + side * .09, .90);
        line(x + side * .09, .90, x + side * .14, .90);
      }
    }
    pen.color = color.withValues(alpha: .45);
    line(-.55, .95, .55, .95);
    line(0, .35, 0, .60);
    line(0, .35, -.04, .40);
    line(0, .35, .04, .40);
    line(0, .60, -.04, .55);
    line(0, .60, .04, .55);
  }

  @override
  bool shouldRepaint(covariant SquatSetupArt oldDelegate) =>
      color != oldDelegate.color;
}
