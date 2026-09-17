import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/cloud_friends.dart';
import '../domain/flight_course.dart';
import '../domain/game_rules.dart' show CourierStop;
import '../game/cloud_friend_art.dart';
import '../game/courier_art.dart';
import '../game/sky_scenery.dart';
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
      FlightCourse.skyCourier => 'Sky Courier: carry letters to postboxes.',
      FlightCourse.cloudCruise =>
        'Cloud Cruise: meet a whale, bunny and turtle in the clouds.',
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
          if (course == FlightCourse.skyCourier)
            const Positioned(
              left: 179,
              top: 105,
              child: CustomPaint(
                size: Size(38, 29),
                painter: _CarriedLetterPainter(),
              ),
            ),
        ],
      ),
    ),
  );
}

class _CarriedLetterPainter extends CustomPainter {
  const _CarriedLetterPainter();
  @override
  void paint(Canvas canvas, Size size) => CourierArt.letter(
    canvas,
    Offset(size.width / 2, size.height / 2),
    size.width,
  );
  @override
  bool shouldRepaint(_CarriedLetterPainter oldDelegate) => false;
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
          canvas.drawCircle(
            position,
            radius * 1.5,
            Paint()..color = SkyColors.cream.withValues(alpha: .5),
          );
          canvas.drawPath(
            SkyScenery.star(position + const Offset(0, 3), radius),
            Paint()..color = SkyColors.gold,
          );
          canvas.drawPath(
            SkyScenery.star(position, radius),
            Paint()..color = SkyColors.yellow,
          );
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
      case FlightCourse.skyCourier:
        CourierArt.letter(canvas, const Offset(51, 22), 48);
        CourierArt.station(
          canvas,
          const Offset(46, 96),
          480,
          CourierStop.postbox,
          carrying: true,
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
            Offset(72 + i * 10, 24 + i * 6),
            2.2,
            Paint()..color = SkyColors.teal.withValues(alpha: .7),
          );
        }
      case FlightCourse.cloudCruise:
        CloudFriendArt.paint(
          canvas,
          const Rect.fromLTWH(0, 2, 106, 76),
          CloudFriend.whale,
        );
        CloudFriendArt.paint(
          canvas,
          const Rect.fromLTWH(240, -8, 104, 74),
          CloudFriend.bunny,
        );
        CloudFriendArt.paint(
          canvas,
          const Rect.fromLTWH(4, 96, 100, 71),
          CloudFriend.turtle,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoursePainter oldDelegate) =>
      oldDelegate.course != course;
}
