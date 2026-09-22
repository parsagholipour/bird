import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';

/// A left-facing flying beetle, drawn in collision-radius units. Lifted hard
/// wing cases frame the softer flight wings; the mint cheek stores its spit.
abstract final class AimedEnemyArt {
  static const _deep = Color(0xff234e4c);
  static const _shell = Color(0xff318876);
  static const _light = Color(0xff8cd7b2);
  static const _mint = Color(0xffb3ffda);

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
    final aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    final power = charge.isFinite ? charge.clamp(0.0, 1.0) : 0.0;
    final kick = recoil.isFinite ? recoil.clamp(0.0, 1.0) : 0.0;
    final brace = power * power * (3 - 2 * power);
    final phase = time * 25;
    final nearStroke = reducedMotion ? .48 : math.sin(phase);
    final farStroke = reducedMotion
        ? -.25
        : math.sin(phase + .95 + math.sin(time * 3) * .08);
    final follow = reducedMotion
        ? 0.0
        : math.sin(phase - .85) * .018 + math.sin(time * 4.1) * .025;
    // A damped counter-motion lets the plates and feet settle after the shot.
    // No body bob is added here: the caller moves the hit circle and art together.
    final spring = kick * math.cos((1 - kick) * math.pi * 1.6);
    final hinge = reducedMotion ? 0.0 : math.sin(phase - .45) * .018;

    c.save();
    c.scale(radius);
    _flightWing(c, farStroke, far: true);
    _legs(c, follow, brace, spring, far: true);
    _abdomen(c, brace, spring);
    _wingCase(c, hinge, brace, spring, far: true);
    _flightWing(c, nearStroke, far: false);
    _wingCase(c, hinge, brace, spring, far: false);
    _legs(c, follow, brace, spring, far: false);
    _thorax(c, brace, spring);
    _antennae(c, follow, brace, spring);
    _head(c, aim, power, brace, spring);
    c.restore();
  }

  static void _flightWing(Canvas c, double stroke, {required bool far}) {
    c.save();
    c.translate(far ? -.04 : .06, far ? -.37 : -.32);
    final reach = far ? 1.51 : 1.72;
    final tipY = (far ? -.21 : -.12) - stroke * (far ? .46 : .49);
    // Foreshortening makes the membrane turn edge-on at the end of each stroke.
    final breadth = (far ? .105 : .14) + (1 - stroke * stroke) * .13;
    final wing = Path()
      ..moveTo(0, .025)
      ..cubicTo(.34, tipY - .12, reach * .78, tipY - breadth, reach, tipY)
      ..cubicTo(
        reach + .13,
        tipY + breadth * .8,
        reach * .59,
        tipY + breadth * 1.35,
        0,
        .025,
      )
      ..close();
    c.drawPath(
      wing,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(reach, tipY),
          far
              ? const [Color(0x999acfc2), Color(0xb8d9eee0)]
              : const [Color(0xa889cbb9), Color(0xe6f2f7da)],
        ),
    );
    c.drawPath(
      wing,
      _line(far ? const Color(0xff679d8b) : _deep, far ? .035 : .045),
    );
    c.drawPath(
      Path()
        ..moveTo(.08, .015)
        ..quadraticBezierTo(reach * .56, tipY + .01, reach * .94, tipY)
        ..moveTo(reach * .42, tipY * .66)
        ..lineTo(reach * .65, tipY - breadth * .55),
      _line(const Color(0xff81b99d).withValues(alpha: far ? .6 : .8), .028),
    );
    if (!far) {
      c.drawPath(
        Path()
          ..moveTo(reach * .49, tipY - breadth * .5)
          ..quadraticBezierTo(
            reach * .78,
            tipY - breadth * .77,
            reach * .95,
            tipY - .025,
          ),
        _line(SkyColors.cream.withValues(alpha: .8), .045),
      );
    }
    c.restore();
  }

  static void _abdomen(Canvas c, double brace, double spring) {
    c.save();
    c.translate(spring * .055, -brace * .015);
    final body = Path()
      ..moveTo(-.19, -.38)
      ..cubicTo(.29, -.57, .91, -.31, 1.04, .08)
      ..cubicTo(1.2, .48, .82, .71, .44, .65)
      ..cubicTo(.04, .62, -.29, .4, -.3, .07)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(.4, -.4),
          const Offset(.65, .66),
          const [Color(0xff6bab8f), _deep, Color(0xff1c3c40)],
          const [0, .7, 1],
        ),
    );
    c.drawPath(body, _line(SkyColors.ink, .065));
    // Only the lower, flexible segments show beneath the rigid elytra.
    for (final x in [.31, .59, .84]) {
      c.drawPath(
        Path()
          ..moveTo(x, .12)
          ..quadraticBezierTo(x - .07, .37, x + .07, .56),
        _line(const Color(0xff78b594).withValues(alpha: .68), .05),
      );
    }
    c.restore();
  }

  static void _wingCase(
    Canvas c,
    double hinge,
    double brace,
    double spring, {
    required bool far,
  }) {
    c.save();
    c.translate(far ? -.13 : -.025, far ? -.41 : -.29);
    c.rotate(
      (far ? -.56 : -.3) +
          hinge * (far ? -.7 : 1) -
          brace * .045 +
          spring * .09,
    );
    if (far) c.scale(.85, .75);
    final shell = Path()
      ..moveTo(.015, -.015)
      ..cubicTo(.17, -.34, .68, -.4, 1.05, -.04)
      ..quadraticBezierTo(1.21, .08, 1.2, .2)
      ..cubicTo(.92, .43, .35, .31, .015, -.015)
      ..close();
    c.drawPath(
      shell,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(.44, -.29),
          const Offset(.67, .33),
          far
              ? const [Color(0xff8cc9a0), Color(0xff358878), _deep]
              : const [Color(0xffb0e9bd), Color(0xff43a68a), _deep],
          const [0, .47, 1],
        ),
    );
    c.drawPath(shell, _line(SkyColors.ink, far ? .06 : .075));
    c.drawPath(
      Path()
        ..moveTo(.16, -.06)
        ..cubicTo(.48, -.16, .88, -.03, 1.1, .18),
      _line(far ? _shell : const Color(0xff237463), .045),
    );
    if (!far) {
      // A broad reflected edge survives at the 16px collision radius.
      c.drawPath(
        Path()
          ..moveTo(.2, -.17)
          ..cubicTo(.46, -.31, .76, -.23, .94, -.07),
        _line(const Color(0xffd4f0c8), .085),
      );
      c.drawPath(
        Path()
          ..moveTo(.49, .16)
          ..quadraticBezierTo(.86, .29, 1.12, .19),
        _line(_light.withValues(alpha: .7), .045),
      );
    }
    c.restore();
  }

  static void _legs(
    Canvas c,
    double follow,
    double brace,
    double spring, {
    required bool far,
  }) {
    c.save();
    if (far) c.translate(-.06, -.065);
    final trail = follow * (far ? -.8 : 1);
    final tuck = brace * .11 - spring * .095;
    final feet = Path()
      ..moveTo(-.27, .23)
      ..quadraticBezierTo(-.37, .52 - tuck, -.19, .69 - tuck)
      ..lineTo(.015 + trail, .68 - tuck)
      ..moveTo(.13, .39)
      ..quadraticBezierTo(.16, .68 - tuck, .38, .85 - tuck + trail)
      ..lineTo(.62, .8 - tuck + trail)
      ..moveTo(.55, .42)
      ..quadraticBezierTo(.7, .76 - tuck, .96, .88 - tuck - trail)
      ..lineTo(1.17, .75 - tuck - trail);
    c.drawPath(feet, _line(far ? const Color(0xff528f7c) : _deep, .075));
    if (!far) {
      c.drawPath(
        Path()
          ..moveTo(.16, .48)
          ..lineTo(.23, .65 - tuck)
          ..moveTo(.69, .61)
          ..lineTo(.83, .76 - tuck),
        _line(_light, .033),
      );
    }
    c.restore();
  }

  static void _thorax(Canvas c, double brace, double spring) {
    c.save();
    c.translate(spring * .04, 0);
    final shoulder = Path()
      ..moveTo(-.42, -.48)
      ..quadraticBezierTo(-.07, -.66, .22, -.38)
      ..quadraticBezierTo(.43, -.06, .21, .39 - brace * .03)
      ..quadraticBezierTo(-.04, .56, -.38, .28)
      ..close();
    c.drawPath(
      shoulder,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-.21, -.51),
          const Offset(.18, .44),
          const [Color(0xff73c6a3), _shell, _deep],
          const [0, .42, 1],
        ),
    );
    c.drawPath(shoulder, _line(SkyColors.ink, .07));
    c.drawPath(
      Path()
        ..moveTo(-.14, -.42)
        ..quadraticBezierTo(.17, -.29, .14, .06),
      _line(_light, .065),
    );
    c.restore();
  }

  static void _antennae(Canvas c, double follow, double brace, double spring) {
    final bend = follow + brace * .055 + spring * .07;
    final farTip = Offset(-.75 - brace * .025, -1.055 + bend * .6);
    final nearTip = Offset(-1.21 - brace * .025, -.86 + bend);
    c.drawPath(
      Path()
        ..moveTo(-.4, -.52)
        ..cubicTo(-.38, -.83, -.52, -1.04, farTip.dx, farTip.dy),
      _line(const Color(0xff518b76), .055),
    );
    c.drawOval(
      Rect.fromCenter(center: farTip, width: .135, height: .085),
      _fill(_light),
    );
    c.drawPath(
      Path()
        ..moveTo(-.62, -.5)
        ..cubicTo(-.73, -.79, -.97, -.97 + bend, nearTip.dx, nearTip.dy),
      _line(_deep, .065),
    );
    c.drawOval(
      Rect.fromCenter(center: nearTip, width: .17, height: .105),
      _fill(_light),
    );
    c.drawOval(
      Rect.fromCenter(
        center: nearTip + const Offset(-.025, -.02),
        width: .075,
        height: .035,
      ),
      _fill(SkyColors.cream),
    );
  }

  static void _head(
    Canvas c,
    double aim,
    double power,
    double brace,
    double spring,
  ) {
    // All cheek squash pivots around the actual projectile origin. Neither
    // tracking the player nor inflating the throat moves the launch point.
    c.save();
    c.translate(-1.05, 0);
    c.scale(1 - brace * .025 + spring * .035, 1 + brace * .035 - spring * .055);
    c.translate(1.05, 0);
    final head = Path()
      ..moveTo(-1.015, -.13)
      ..quadraticBezierTo(-1.015, -.47, -.78, -.59)
      ..cubicTo(-.5, -.75, -.2, -.5, -.2, -.23)
      ..quadraticBezierTo(-.1, .08, -.3, .31)
      ..quadraticBezierTo(-.52, .5, -.81, .29)
      ..lineTo(-1.045, .095)
      ..close();
    c.drawPath(
      head,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-.81, -.61),
          const Offset(-.31, .36),
          const [Color(0xffc3e8bd), Color(0xff76c6a2), Color(0xff388e7b)],
          const [0, .46, 1],
        ),
    );
    c.drawPath(head, _line(SkyColors.ink, .07));

    final throat = Rect.fromCenter(
      center: Offset(-.57, .205 + brace * .025),
      width: .49 + brace * .095,
      height: .3 + brace * .16,
    );
    final sac = Path()..addOval(throat);
    c.drawPath(sac, _fill(const Color(0xff4b9e88)));
    c.save();
    c.clipPath(sac);
    c.drawRect(
      Rect.fromLTRB(
        throat.left,
        throat.bottom - throat.height * (.22 + power * .78),
        throat.right,
        throat.bottom,
      ),
      Paint()
        ..shader = ui.Gradient.linear(throat.topCenter, throat.bottomCenter, [
          Color.lerp(_light, SkyColors.cream, power)!,
          _mint,
        ]),
    );
    c.restore();
    c.drawPath(sac, _line(_deep.withValues(alpha: .65), .04));
    c.drawPath(
      Path()
        ..moveTo(-.73, .14)
        ..quadraticBezierTo(-.61, .08, -.49, .125),
      _line(SkyColors.cream.withValues(alpha: .35 + power * .5), .05),
    );

    // A tall near eye and a sliver of the far eye give a clear left profile.
    c.drawOval(const Rect.fromLTWH(-1.015, -.365, .125, .23), _fill(_deep));
    const eye = Rect.fromLTWH(-.925, -.515, .46, .46);
    c.drawOval(eye, _fill(SkyColors.cream));
    c.drawOval(eye, _line(_deep, .055));
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-.773, -.281 + aim * .073),
        width: .21,
        height: .29,
      ),
      _fill(SkyColors.ink),
    );
    c.drawCircle(
      Offset(-.803, -.34 + aim * .073),
      .053,
      _fill(SkyColors.cream),
    );
    c.drawPath(
      Path()
        ..moveTo(-.948, -.46 + brace * .025)
        ..quadraticBezierTo(-.77, -.61, -.46, -.445 + brace * .025),
      _line(_deep, .075),
    );

    // A short pursed lip, not a projecting snout. Its center is always (-1.05,0).
    c.drawPath(
      Path()
        ..moveTo(-.91, -.095)
        ..quadraticBezierTo(-1.115, -.12, -1.11, 0)
        ..quadraticBezierTo(-1.11, .125, -.91, .095),
      Paint()
        ..color = _light
        ..style = PaintingStyle.fill,
    );
    c.drawPath(
      Path()
        ..moveTo(-.925, -.095)
        ..quadraticBezierTo(-1.12, -.135, -1.12, 0)
        ..quadraticBezierTo(-1.12, .135, -.925, .095),
      _line(_deep, .055),
    );
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-1.05, 0),
        width: .095 + power * .02,
        height: .105 + power * .09 + math.max(0, spring) * .06,
      ),
      _fill(_deep),
    );
    if (power > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(-1.057, 0),
          width: .048 + power * .025,
          height: .035 + power * .08,
        ),
        _fill(_mint.withValues(alpha: power)),
      );
      c.drawCircle(
        const Offset(-1.071, -.025),
        .024,
        _fill(SkyColors.cream.withValues(alpha: power)),
      );
    }
    c.restore();
  }

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
