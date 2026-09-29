import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/star_art.dart';
import 'components.dart';
import 'theme.dart';

/// The title screen shares its bird and island with the playable world.
class HomeWorld extends StatelessWidget {
  const HomeWorld({super.key, required this.bird, required this.reducedMotion});
  final int bird;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _WorldPainter())),
          const Positioned(left: -70, top: 72, child: Cloud(width: 205)),
          const Positioned(right: -60, top: 82, child: Cloud(width: 235)),
          Positioned(
            right: 82,
            top: 211,
            child: Image.asset(
              'assets/images/island.png',
              width: 350,
              height: 219,
              excludeFromSemantics: true,
            ),
          ),
          Positioned(
            right: 126,
            top: 79,
            child: Transform.rotate(
              angle: -.09,
              child: BirdArt(
                bird: bird,
                size: 262,
                reducedMotion: reducedMotion,
              ),
            ),
          ),
          const Positioned(left: -100, bottom: -72, child: Cloud(width: 480)),
          const Positioned(right: -104, bottom: -98, child: Cloud(width: 620)),
        ],
      ),
    ),
  );
}

class _WorldPainter extends CustomPainter {
  const _WorldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 450);
    final paint = Paint();
    // A warm halo frames the bird, leaving the title and play action clear.
    for (final (radius, alpha) in [(160.0, .12), (125.0, .18), (93.0, .3)]) {
      canvas.drawCircle(
        const Offset(745, 173),
        radius,
        paint..color = SkyColors.cream.withValues(alpha: alpha),
      );
    }
    for (final (x, y, scale) in [(34.0, 303.0, .7), (931.0, 246.0, .9)]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      canvas.drawPath(
        Path()
          ..moveTo(-67, 8)
          ..lineTo(65, 8)
          ..lineTo(18, 81)
          ..lineTo(-16, 59)
          ..close(),
        paint..color = const Color(0xff7ebdb5).withValues(alpha: .5),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-70, -7, 140, 33),
        paint..color = const Color(0xff92cdb9),
      );
      canvas.drawLine(
        const Offset(10, 0),
        const Offset(10, -63),
        Paint()
          ..color = SkyColors.teal.withValues(alpha: .65)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        Path()
          ..moveTo(12, -62)
          ..lineTo(53, -52)
          ..lineTo(12, -39)
          ..close(),
        paint..color = SkyColors.cream.withValues(alpha: .85),
      );
      canvas.restore();
    }
    final trail = Path()
      ..moveTo(479, 285)
      ..cubicTo(477, 222, 574, 258, 584, 183)
      ..cubicTo(604, 56, 806, 34, 887, 163);
    for (final metric in trail.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 13) {
        final point = metric.getTangentForOffset(d)!.position;
        canvas.drawCircle(
          point,
          2,
          paint..color = SkyColors.cream.withValues(alpha: .9),
        );
      }
    }
    for (final (position, radius, rotation) in [
      (const Offset(546, 201), 17.0, -.15),
      (const Offset(608, 97), 24.0, -.2),
      (const Offset(864, 159), 29.0, .15),
      (const Offset(845, 268), 14.0, .3),
    ]) {
      // The same collectible the bird gathers in flight, at rest.
      StarArt.paint(canvas, position, radius * 1.1, rotation: rotation);
    }
    for (final position in [
      const Offset(525, 118),
      const Offset(884, 224),
      const Offset(806, 67),
      const Offset(493, 192),
    ]) {
      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        canvas.drawLine(
          position + Offset(math.cos(angle), math.sin(angle)) * 3,
          position + Offset(math.cos(angle), math.sin(angle)) * 7,
          Paint()
            ..color = SkyColors.cream
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WorldPainter oldDelegate) => false;
}
