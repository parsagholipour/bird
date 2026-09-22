import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../ui/theme.dart';

/// The same cosmetic marks are used in flight and in the crew preview.
abstract final class BirdTrail {
  static const names = [
    'Sunshine bubbles',
    'Peach hearts',
    'Mint leaves',
    'Stardust sparkles',
  ];

  /// Given a [path] of the bird's recent positions, newest first, the marks
  /// are spaced evenly along the line it flew and continue level beyond it.
  static void paint(
    Canvas canvas, {
    required int bird,
    required Offset anchor,
    required double unit,
    double seconds = 0,
    bool animate = true,
    bool empowered = false,
    List<Offset>? path,
  }) {
    final color = empowered
        ? SkyColors.yellow
        : [
            SkyColors.gold,
            SkyColors.coralDeep,
            SkyColors.teal,
            SkyColors.purple,
          ][bird];
    final behind = [for (var i = 1; i <= 6; i++) unit * (5 + i * 2)];
    final points = path == null
        ? [
            for (final (i, length) in behind.indexed)
              anchor +
                  Offset(
                    -length,
                    math.sin((animate ? seconds * 5 : 0) - (i + 1) * .7) * unit,
                  ),
          ]
        : _along([anchor, ...path], behind);
    for (var i = 6; i >= 1; i--) {
      final point = points[i - 1];
      final radius = unit * (1.1 - i * .1);
      final paint = Paint()..color = color.withValues(alpha: .8 - i * .085);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      switch (bird) {
        case 0:
          canvas.drawCircle(Offset.zero, radius, paint);
          canvas.drawCircle(
            Offset(-radius * .3, -radius * .3),
            radius * .25,
            Paint()..color = SkyColors.cream.withValues(alpha: .65),
          );
        case 1:
          canvas.drawPath(
            Path()
              ..moveTo(0, radius)
              ..cubicTo(
                -radius * 2,
                -radius * .25,
                -radius * .65,
                -radius * 1.5,
                0,
                -radius * .55,
              )
              ..cubicTo(
                radius * .65,
                -radius * 1.5,
                radius * 2,
                -radius * .25,
                0,
                radius,
              )
              ..close(),
            paint,
          );
        case 2:
          canvas.rotate(-.5 + math.sin((animate ? seconds * 2 : 0) + i) * .25);
          canvas.drawPath(
            Path()
              ..moveTo(-radius, radius * .7)
              ..quadraticBezierTo(
                -radius * 1.1,
                -radius * 1.25,
                radius,
                -radius * .7,
              )
              ..quadraticBezierTo(
                radius * 1.1,
                radius * 1.25,
                -radius,
                radius * .7,
              )
              ..close(),
            paint,
          );
          canvas.drawLine(
            Offset(-radius * .5, radius * .35),
            Offset(radius * .6, -radius * .42),
            Paint()
              ..color = SkyColors.cream.withValues(alpha: .5)
              ..strokeWidth = .7,
          );
        case 3:
          canvas.rotate(animate ? seconds * .6 + i * .3 : i * .3);
          canvas.drawPath(
            Path()
              ..moveTo(0, -radius * 1.3)
              ..quadraticBezierTo(radius * .2, -radius * .2, radius, 0)
              ..quadraticBezierTo(radius * .2, radius * .2, 0, radius * 1.3)
              ..quadraticBezierTo(-radius * .2, radius * .2, -radius, 0)
              ..quadraticBezierTo(-radius * .2, -radius * .2, 0, -radius * 1.3)
              ..close(),
            paint,
          );
      }
      canvas.restore();
    }
  }

  /// Ascending [lengths] measured along [line] from its first point.
  static List<Offset> _along(List<Offset> line, List<double> lengths) {
    final points = <Offset>[];
    var segment = 0;
    var start = 0.0;
    for (final length in lengths) {
      while (segment < line.length - 1) {
        final gap = (line[segment + 1] - line[segment]).distance;
        if (start + gap >= length) break;
        start += gap;
        segment++;
      }
      if (segment == line.length - 1) {
        points.add(line.last - Offset(length - start, 0));
        continue;
      }
      final a = line[segment], b = line[segment + 1];
      final gap = (b - a).distance;
      points.add(gap == 0 ? a : Offset.lerp(a, b, (length - start) / gap)!);
    }
    return points;
  }
}
