import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';

/// A small, unarmored bat seen in three-quarter profile, facing the bird.
///
/// The muzzle and eye always face left. The two wings have different projected
/// spans and flap phases, so their silhouette reads as a flying animal at the
/// normal 16 px hit radius. Geometry stays within x ±1.9r, y ±1.2r.
abstract final class PatrolBatArt {
  static const _ink = Color(0xff302536);
  static const _fur = Color(0xff725264);
  static const _furLight = Color(0xffa47a85);
  static const _membrane = Color(0xff8d596f);
  static const _membraneLight = Color(0xffc18b96);
  static const _bone = Color(0xffc7a0a7);

  static void paint(
    Canvas c,
    double radius, {
    required double seconds,
    required bool reducedMotion,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = seconds.isFinite ? seconds : 0.0;
    final nearBeat = reducedMotion ? .22 : .5 + .5 * math.sin(time * 12.0);
    final farBeat = reducedMotion ? .12 : .5 + .5 * math.sin(time * 12.0 + .75);
    final aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;

    c.save();
    c.scale(radius);

    // The far wing is smaller and darker; it peeks above the shoulder before
    // the near wing folds down. Its bones articulate instead of rotating a
    // rigid decorative fin.
    c.save();
    c.translate(-.1, -.11);
    c.scale(.82, .88);
    _wing(c, farBeat, far: true);
    c.restore();

    _tailAndFeet(c);
    _body(c);
    _wing(c, nearBeat, far: false);
    _head(c, aim);

    c.restore();
  }

  static void _wing(Canvas c, double beat, {required bool far}) {
    const shoulder = Offset(.05, -.12);
    final elbow = Offset(.48, -.62 + beat * .59);
    final wrist = Offset(1.03, -1.01 + beat * 1.02);
    final tip = Offset(1.8, -.87 + beat * 1.58);
    final finger1 = Offset(1.62, .12 + beat * .83);
    final finger2 = Offset(1.14, .49 + beat * .45);
    final finger3 = Offset(.65, .67 + beat * .25);
    final membrane = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(.15, -.36, elbow.dx, elbow.dy)
      ..quadraticBezierTo(.7, wrist.dy - .06, wrist.dx, wrist.dy)
      ..quadraticBezierTo(1.39, tip.dy - .07, tip.dx, tip.dy)
      // Taut fingers end in points; the membrane scallops between them.
      ..quadraticBezierTo(1.48, tip.dy + .24, finger1.dx, finger1.dy)
      ..quadraticBezierTo(1.22, finger1.dy - .2, finger2.dx, finger2.dy)
      ..quadraticBezierTo(.87, finger2.dy - .23, finger3.dx, finger3.dy)
      ..quadraticBezierTo(.39, .44, .07, .44)
      ..quadraticBezierTo(.18, .13, shoulder.dx, shoulder.dy)
      ..close();
    c.drawPath(
      membrane,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: far
              ? const [Color(0xff6d4d67), Color(0xff483345)]
              : const [_membraneLight, _membrane, Color(0xff5b3e55)],
        ).createShader(const Rect.fromLTRB(0, -1.1, 1.85, 1)),
    );
    c.drawPath(membrane, _line(_ink, .065));

    final boneColor = far ? _fur : _bone;
    c.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(.18, -.36, elbow.dx, elbow.dy)
        ..lineTo(wrist.dx, wrist.dy)
        ..lineTo(tip.dx, tip.dy),
      _line(boneColor, far ? .043 : .067),
    );
    for (final finger in [finger1, finger2, finger3]) {
      c.drawPath(
        Path()
          ..moveTo(wrist.dx, wrist.dy)
          ..quadraticBezierTo(
            wrist.dx * .42 + finger.dx * .58 - .07,
            wrist.dy * .38 + finger.dy * .62,
            finger.dx,
            finger.dy,
          ),
        _line(boneColor.withValues(alpha: far ? .5 : .72), .036),
      );
    }
    // A tiny hooked thumb at the wrist is a bat's characteristic wing joint.
    c.drawPath(
      Path()
        ..moveTo(wrist.dx - .055, wrist.dy + .035)
        ..quadraticBezierTo(
          wrist.dx - .17,
          wrist.dy - .15,
          wrist.dx - .015,
          wrist.dy - .135,
        ),
      _line(far ? _fur : SkyColors.sand, .046),
    );
  }

  static void _tailAndFeet(Canvas c) {
    final tail = Path()
      ..moveTo(.33, .41)
      ..lineTo(1.06, .79)
      ..quadraticBezierTo(.68, .72, .56, .98)
      ..quadraticBezierTo(.3, .73, -.12, .65)
      ..close();
    c.drawPath(tail, _fill(_membrane));
    c.drawPath(tail, _line(_ink, .055));
    c.drawLine(
      const Offset(.35, .55),
      const Offset(.96, .78),
      _line(_furLight, .043),
    );
    for (final at in const [Offset(.38, .72), Offset(-.01, .76)]) {
      c.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - .1)
          ..lineTo(at.dx + .08, at.dy + .13)
          ..lineTo(at.dx - .04, at.dy + .17)
          ..moveTo(at.dx + .07, at.dy + .09)
          ..lineTo(at.dx + .14, at.dy + .14),
        _line(_ink, .067),
      );
    }
  }

  static void _body(Canvas c) {
    final body = Path()
      ..moveTo(-.66, -.61)
      ..quadraticBezierTo(-.27, -.9, .17, -.57)
      ..lineTo(.42, -.57)
      ..lineTo(.31, -.4)
      ..quadraticBezierTo(.96, -.04, .67, .48)
      ..quadraticBezierTo(.42, .83, -.04, .88)
      ..lineTo(-.1, .74)
      ..lineTo(-.29, .82)
      ..lineTo(-.3, .65)
      ..quadraticBezierTo(-.84, .58, -.87, .14)
      ..quadraticBezierTo(-.96, -.27, -.66, -.61)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_furLight, _fur, Color(0xff4b354a)],
        ).createShader(const Rect.fromLTRB(-.9, -.8, .8, .9)),
    );
    c.drawPath(body, _line(_ink, .065));

    // One clear warm breast patch gives shape without patterned decoration.
    final breast = Path()
      ..moveTo(-.66, -.02)
      ..quadraticBezierTo(-.11, -.19, .1, .21)
      ..quadraticBezierTo(.18, .64, -.2, .67)
      ..quadraticBezierTo(-.77, .55, -.66, -.02)
      ..close();
    c.drawPath(breast, _fill(const Color(0xffb19392)));
  }

  static void _head(Canvas c, double aim) {
    // Head stays forward of both wing roots: long ears, sloping forehead,
    // wedge muzzle and a single visible eye make the facing unambiguous.
    final farEar = Path()
      ..moveTo(-.47, -.57)
      ..quadraticBezierTo(-.4, -.97, -.13, -1.1)
      ..quadraticBezierTo(-.13, -.69, -.2, -.37)
      ..close();
    c.drawPath(farEar, _fill(const Color(0xff584054)));
    c.drawPath(farEar, _line(_ink, .058));
    final nearEar = Path()
      ..moveTo(-.89, -.39)
      ..quadraticBezierTo(-1.04, -.74, -.86, -1.13)
      ..quadraticBezierTo(-.52, -.98, -.48, -.45)
      ..close();
    c.drawPath(nearEar, _fill(_fur));
    c.drawPath(nearEar, _line(_ink, .06));
    c.drawPath(
      Path()
        ..moveTo(-.81, -.57)
        ..quadraticBezierTo(-.91, -.78, -.84, -.96)
        ..quadraticBezierTo(-.64, -.83, -.61, -.55)
        ..close(),
      _fill(const Color(0xffcc9498)),
    );

    final head = Path()
      ..moveTo(-1.23, -.11)
      ..quadraticBezierTo(-1.07, -.19, -1.0, -.4)
      ..quadraticBezierTo(-.87, -.7, -.54, -.58)
      ..quadraticBezierTo(-.28, -.5, -.25, -.25)
      ..lineTo(-.11, -.2)
      ..lineTo(-.25, -.08)
      ..lineTo(-.1, .04)
      ..lineTo(-.32, .09)
      ..quadraticBezierTo(-.51, .3, -.82, .21)
      ..quadraticBezierTo(-1.04, .15, -1.25, .14)
      ..quadraticBezierTo(-1.38, .02, -1.23, -.11)
      ..close();
    c.drawPath(
      head,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_furLight, _fur],
        ).createShader(const Rect.fromLTRB(-1.3, -.6, -.2, .3)),
    );
    c.drawPath(head, _line(_ink, .063));

    // Dark pointed nose and a lighter jaw are legible even at gameplay size.
    c.drawOval(
      const Rect.fromLTWH(-1.12, -.03, .55, .24),
      _fill(const Color(0xffcfaaa2)),
    );
    c.drawPath(
      Path()
        ..moveTo(-1.19, -.12)
        ..lineTo(-1.37, -.035)
        ..quadraticBezierTo(-1.34, .09, -1.18, .045)
        ..close(),
      _fill(_ink),
    );
    c.drawPath(
      Path()
        ..moveTo(-1.17, .12)
        ..quadraticBezierTo(-.97, .2, -.79, .12),
      _line(_ink, .047),
    );
    c.drawPath(
      Path()
        ..moveTo(-1.01, .13)
        ..lineTo(-.87, .14)
        ..lineTo(-.96, .29)
        ..close(),
      _fill(SkyColors.cream),
    );

    final eye = Path()
      ..moveTo(-1.005, -.31)
      ..quadraticBezierTo(-.82, -.48, -.59, -.29)
      ..quadraticBezierTo(-.7, -.09, -.91, -.16)
      ..close();
    c.drawPath(eye, _fill(const Color(0xffffdba1)));
    c.drawPath(eye, _line(_ink, .045));
    c.save();
    c.clipPath(eye);
    final pupil = Offset(-.9, -.275 + aim * .065);
    c.drawOval(
      Rect.fromCenter(center: pupil, width: .15, height: .245),
      _fill(_ink),
    );
    c.drawCircle(
      pupil + const Offset(-.025, -.055),
      .038,
      _fill(SkyColors.cream),
    );
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(-1.005, -.33)
        ..quadraticBezierTo(-.8, -.425, -.6, -.31),
      _line(_ink, .065),
    );
  }

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
