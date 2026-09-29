import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/flight_course.dart';
import '../game/star_art.dart';
import 'components.dart';
import 'theme.dart';

/// The Home illustration previews the selected activity using gameplay art.
class CoursePreview extends StatelessWidget {
  const CoursePreview({
    super.key,
    required this.course,
    required this.bird,
    required this.reducedMotion,
  });
  final FlightCourse course;
  final int bird;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (course) {
      FlightCourse.classic => 'Classic: fly through the gaps.',
      FlightCourse.starTrail =>
        'Star Trail: collect stars with three hearts and a shield.',
    },
    excludeSemantics: true,
    child: SizedBox(
      width: 355,
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 25,
            top: 24,
            child: Image.asset(
              'assets/images/island.png',
              width: 225,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: reducedMotion ? 0 : 220),
                child: CustomPaint(
                  key: ValueKey(course),
                  size: const Size(355, 170),
                  painter: _CoursePainter(course),
                ),
              ),
            ),
          ),
          Positioned(
            left: 84,
            top: -8,
            child: BirdArt(bird: bird, size: 156, reducedMotion: reducedMotion),
          ),
        ],
      ),
    ),
  );
}

class _CoursePainter extends CustomPainter {
  const _CoursePainter(this.course);
  final FlightCourse course;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 355, size.height / 170);
    switch (course) {
      case FlightCourse.classic:
        // The original island remains the Classic course's home illustration.
        break;
      case FlightCourse.starTrail:
        for (final (position, radius) in [
          (const Offset(40, 23), 17.0),
          (const Offset(60, 83), 12.0),
          (const Offset(270, 19), 23.0),
        ]) {
          // The Star Trail's collectible, as the bird meets it in flight.
          StarArt.paint(canvas, position, radius * 1.1);
        }
        canvas.drawArc(
          const Rect.fromLTWH(86, -9, 152, 149),
          -.35,
          math.pi * 1.45,
          false,
          Paint()
            ..color = SkyColors.teal.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoursePainter oldDelegate) =>
      oldDelegate.course != course;
}
