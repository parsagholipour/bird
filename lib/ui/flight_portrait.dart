import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/sky_scenery.dart';
import '../game/arrival_art.dart';
import '../domain/flight_course.dart';
import 'components.dart';
import 'theme.dart';

/// A finite, local celebration leaves the result buttons immediately usable.
/// Reduced Motion keeps the final decorated portrait without a running ticker.
class FlightPortrait extends StatefulWidget {
  const FlightPortrait({
    super.key,
    required this.bird,
    required this.reducedMotion,
    required this.celebrate,
    this.arrivedCourse,
  });
  final int bird;
  final bool reducedMotion, celebrate;
  final FlightCourse? arrivedCourse;
  @override
  State<FlightPortrait> createState() => _FlightPortraitState();
}

class _FlightPortraitState extends State<FlightPortrait>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    if (widget.celebrate && !widget.reducedMotion) {
      animation.forward(from: 0);
    } else {
      animation.value = 1;
    }
  }

  @override
  void didUpdateWidget(FlightPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.celebrate != widget.celebrate ||
        oldWidget.bird != widget.bird ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _start();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 252,
    height: 166,
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) => CustomPaint(
        painter: _PortraitPainter(
          arrivedCourse: widget.arrivedCourse,
          progress: animation.value,
          celebrate: widget.celebrate,
          accent: [
            SkyColors.yellow,
            SkyColors.coral,
            SkyColors.mint,
            SkyColors.lavender,
          ][widget.bird],
        ),
        child: child,
      ),
      child: Center(
        child: BirdArt(
          bird: widget.bird,
          size: 166,
          reducedMotion: widget.reducedMotion,
          bob: false,
        ),
      ),
    ),
  );
}

class _PortraitPainter extends CustomPainter {
  const _PortraitPainter({
    required this.progress,
    required this.celebrate,
    required this.accent,
    this.arrivedCourse,
  });
  final double progress;
  final bool celebrate;
  final Color accent;
  final FlightCourse? arrivedCourse;
  @override
  void paint(Canvas c, Size size) {
    if (arrivedCourse != null) {
      ArrivalArt.seal(c, Offset(size.width - 36, size.height - 44), 24);
    }
    if (!celebrate) return;
    final center = Offset(size.width / 2, size.height * .48);
    final reveal = Curves.easeOutCubic.transform(progress);
    final radius = size.height * (.31 + reveal * .06);
    c.drawCircle(
      center,
      radius,
      Paint()..color = SkyColors.cream.withValues(alpha: .36),
    );
    c.drawCircle(
      center,
      radius + 7,
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var i = 0; i < 22; i++) {
      final angle = i * math.pi * 2 / 22 + .14;
      final ring = 61 + (i % 3) * 10 + reveal * 8;
      final point =
          center +
          Offset(
            math.cos(angle) * ring * 1.32,
            math.sin(angle) * ring * .79 + math.sin(progress * math.pi) * -13,
          );
      final color = [
        accent,
        SkyColors.coral,
        SkyColors.teal,
        SkyColors.purple,
        SkyColors.gold,
      ][i % 5];
      final paint = Paint()..color = color.withValues(alpha: .4 + reveal * .5);
      if (i % 4 == 0) {
        c.drawPath(
          SkyScenery.star(point, 5.2, rotation: angle + progress * .4),
          paint,
        );
      } else {
        c.save();
        c.translate(point.dx, point.dy);
        c.rotate(angle + reveal);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: i.isEven ? 3 : 5,
              height: i.isEven ? 7 : 3,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        c.restore();
      }
    }
    c.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height - 12),
        width: 95,
        height: 10,
      ),
      Paint()..color = SkyColors.teal.withValues(alpha: .12),
    );
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.arrivedCourse != arrivedCourse ||
      oldDelegate.celebrate != celebrate ||
      oldDelegate.accent != accent;
}
