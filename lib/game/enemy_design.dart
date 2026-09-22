import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../ui/theme.dart';

/// Storybook enemies drawn around the caller origin, in hit-radius units.
///
/// The opaque body covers the unit circle. Wings, ears, and feelers stay
/// inside the existing envelope, about x ±1.9 and y ±1.2. Light comes from
/// the upper left on every character. [appearance] modulo 3 selects the
/// plum moon bat, the teal armored beetle, or the coral dusk moth.
abstract final class EnemyDesign {
  static void paint(
    Canvas c,
    double radius, {
    required int appearance,
    required double seconds,
    required bool reducedMotion,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = seconds.isFinite ? seconds : 0.0;
    final motion = reducedMotion ? 0.0 : 1.0;
    final raw = appearance % 3;
    final kind = raw < 0 ? raw + 3 : raw;
    c.save();
    c.scale(radius);
    switch (kind) {
      case 0:
        _moonBat(c, time, motion);
      case 1:
        _beetle(c, time, motion);
      default:
        _moth(c, time, motion);
    }
    c.restore();
  }

  static void _moonBat(Canvas c, double time, double motion) {
    final flap = _wave(time, motion, 6.4) * .06;
    final ear = _wave(time, motion, 3.8) * .035;
    final glance = _wave(time, motion, 1.5) * .03;
    _pair(c, (c) {
      _hinge(c, const Offset(-.5, .02), flap, () => _batWing(c));
    });
    _pair(c, (c) {
      _hinge(c, const Offset(-.34, -.68), ear, () => _batEar(c));
    });
    _disc(
      c,
      SkyColors.purple,
      lit: _cream(SkyColors.lavender, .62),
      shade: _inked(SkyColors.purple, .3),
    );
    c.save();
    c.clipPath(_unit);
    c.drawOval(
      const Rect.fromLTWH(-.46, .02, .92, .72),
      _fill(_cream(SkyColors.lavender, .48)),
    );
    c.restore();
    final moon = _crescent(const Offset(0, -.64), .18);
    c.drawPath(moon, _fill(SkyColors.cream));
    c.drawPath(moon, _stroke(SkyColors.ink, .04));
    _eyes(c, -.1, glance, lid: 0);
    _brow(c, const Offset(-.54, -.46), const Offset(-.12, -.38));
    _brow(c, const Offset(.14, -.34), const Offset(.52, -.46));
    _grin(c, const Offset(0, .36), fangs: true);
  }

  static void _batWing(Canvas c) {
    final wing = Path()
      ..moveTo(-.5, -.02)
      ..cubicTo(-.78, -.62, -1.22, -.9, -1.8, -.42)
      ..quadraticBezierTo(-1.46, -.06, -1.68, .2)
      ..quadraticBezierTo(-1.26, .24, -1.24, .54)
      ..quadraticBezierTo(-.84, .3, -.44, .28)
      ..cubicTo(-.64, .1, -.68, .02, -.5, -.02)
      ..close();
    c.drawPath(wing, _fill(SkyColors.lavender));
    c.save();
    c.clipPath(wing);
    c.drawOval(
      const Rect.fromLTWH(-1.7, -.78, 1.15, .62),
      _fill(_cream(SkyColors.lavender, .5)),
    );
    c.restore();
    final bone = _stroke(_inked(SkyColors.purple, .22), .05);
    const shoulder = Offset(-.5, -.02);
    for (final tip in const [
      Offset(-1.8, -.42),
      Offset(-1.68, .2),
      Offset(-1.24, .54),
    ]) {
      c.drawLine(shoulder, tip, bone);
    }
    c.drawPath(wing, _stroke(SkyColors.ink, .06));
  }

  static void _batEar(Canvas c) {
    final ear = Path()
      ..moveTo(-.48, -.6)
      ..lineTo(-.64, -1.14)
      ..lineTo(-.14, -.7)
      ..close();
    final inner = Path()
      ..moveTo(-.44, -.68)
      ..lineTo(-.54, -.98)
      ..lineTo(-.26, -.72)
      ..close();
    c.drawPath(ear, _fill(SkyColors.purple));
    c.drawPath(inner, _fill(_cream(SkyColors.coral, .28)));
    c.drawPath(ear, _stroke(SkyColors.ink, .055));
  }

  static void _beetle(Canvas c, double time, double motion) {
    final buzz = _wave(time, motion, 9.5) * .04;
    final sway = _wave(time, motion, 3.3) * .04;
    final glance = _wave(time, motion, 1.7) * .025;
    _pair(c, (c) {
      _hinge(c, const Offset(-.42, .12), buzz, () => _underwing(c));
      _beetleLeg(c, .0);
      _beetleLeg(c, .28);
    });
    _disc(
      c,
      _inked(SkyColors.teal, .28),
      lit: _cream(SkyColors.teal, .16),
      shade: _inked(SkyColors.teal, .42),
    );
    _elytron(c, _cream(SkyColors.teal, .22));
    c.save();
    c.scale(-1, 1);
    _elytron(c, _inked(SkyColors.teal, .12));
    c.restore();
    c.drawLine(
      const Offset(0, -.48),
      const Offset(0, .86),
      _stroke(_inked(SkyColors.teal, .45), .05),
    );
    _beetleHead(c);
    _crest(c);
    _pair(c, (c) {
      _antenna(c, sway);
      _rivet(c, const Offset(-.46, -.08));
      _rivet(c, const Offset(-.42, .4));
    });
    _eyes(c, -.62, glance, lid: .18, gap: .24);
    _brow(c, const Offset(-.46, -.9), const Offset(-.12, -.82));
    _brow(c, const Offset(.1, -.86), const Offset(.44, -.78));
    _grin(c, const Offset(0, -.4), width: .32);
  }

  static void _underwing(Canvas c) {
    final wing = Path()
      ..moveTo(-.36, .02)
      ..cubicTo(-.85, -.28, -1.35, -.08, -1.58, .22)
      ..cubicTo(-1.48, .58, -.95, .46, -.4, .28)
      ..close();
    c.drawPath(wing, _fill(_cream(SkyColors.mint, .35)));
    c.drawPath(wing, _stroke(_inked(SkyColors.teal, .35), .045));
  }

  static void _beetleLeg(Canvas c, double along) {
    final y = .4 + along;
    c.drawPath(
      Path()
        ..moveTo(-.72, y - .08)
        ..lineTo(-1.02, y + .16)
        ..lineTo(-1.08, y + .48),
      _stroke(_inked(SkyColors.teal, .4), .085),
    );
  }

  static void _elytron(Canvas c, Color color) {
    final plate = Path()
      ..moveTo(-.08, -.46)
      ..cubicTo(-.58, -.82, -1.06, -.28, -1.02, .24)
      ..cubicTo(-.98, .78, -.5, 1.02, -.08, .76)
      ..close();
    c.drawPath(plate, _fill(color));
    c.save();
    c.clipPath(plate);
    c.drawOval(
      const Rect.fromLTWH(-1.05, -.7, .7, .48),
      _fill(_cream(SkyColors.mint, .55)),
    );
    c.restore();
    c.drawPath(plate, _stroke(SkyColors.gold, .055));
    c.drawPath(plate, _stroke(SkyColors.ink, .045));
  }

  static void _beetleHead(Canvas c) {
    c.drawCircle(const Offset(0, -.6), .5, _fill(_cream(SkyColors.teal, .3)));
    c.save();
    c.clipPath(
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(0, -.6), radius: .5)),
    );
    c.drawOval(
      const Rect.fromLTWH(-.46, -.98, .42, .32),
      _fill(_cream(SkyColors.mint, .7)),
    );
    c.restore();
    c.drawCircle(const Offset(0, -.6), .5, _stroke(SkyColors.ink, .06));
  }

  static void _crest(Canvas c) {
    final crest = Path()
      ..moveTo(-.16, -.82)
      ..quadraticBezierTo(0, -1.16, .16, -.82)
      ..quadraticBezierTo(0, -.66, -.16, -.82)
      ..close();
    c.drawPath(crest, _fill(SkyColors.gold));
    c.drawPath(crest, _stroke(SkyColors.ink, .045));
  }

  static void _antenna(Canvas c, double sway) {
    final tip = Offset(-.74, -1.08 + sway);
    c.drawPath(
      Path()
        ..moveTo(-.16, -.96)
        ..cubicTo(-.28, -1.12, -.5, -1.16, tip.dx, tip.dy),
      _stroke(_inked(SkyColors.teal, .5), .05),
    );
    c.drawCircle(tip, .09, _fill(SkyColors.gold));
    c.drawCircle(tip, .09, _stroke(SkyColors.ink, .04));
  }

  static void _rivet(Canvas c, Offset at) {
    c.drawCircle(at, .085, _fill(SkyColors.gold));
    c.drawCircle(at + const Offset(-.02, -.02), .03, _fill(SkyColors.cream));
  }

  static void _moth(Canvas c, double time, double motion) {
    final flap = _wave(time, motion, 4.5) * .05;
    final sway = _wave(time, motion, 2.8) * .045;
    final glance = _wave(time, motion, 1.4) * .03;
    _pair(c, (c) {
      _hinge(c, const Offset(-.2, .22), flap * .7, () => _hindWing(c));
      _hinge(c, const Offset(-.16, -.04), flap, () => _foreWing(c));
    });
    _disc(
      c,
      SkyColors.coral,
      lit: _cream(SkyColors.coral, .42),
      shade: _inked(SkyColors.coralDeep, .18),
    );
    c.save();
    c.clipPath(_unit);
    c.drawRect(const Rect.fromLTRB(-1, .16, 1, .36), _fill(SkyColors.lavender));
    c.drawRect(const Rect.fromLTRB(-1, .5, 1, .66), _fill(SkyColors.coralDeep));
    c.drawRect(
      const Rect.fromLTRB(-1, .78, 1, .94),
      _fill(SkyColors.coralDeep),
    );
    c.restore();
    _eyes(c, -.4, glance, lid: 0);
    _brow(c, const Offset(-.5, -.74), const Offset(-.14, -.68));
    _brow(c, const Offset(.16, -.66), const Offset(.5, -.76));
    _grin(c, const Offset(0, -.02), width: .36);
    _pair(c, (c) => _feeler(c, sway));
  }

  static void _foreWing(Canvas c) {
    final wing = Path()
      ..moveTo(-.48, -.28)
      ..cubicTo(-.92, -.92, -1.42, -1.08, -1.74, -.58)
      ..quadraticBezierTo(-1.88, -.22, -1.58, .02)
      ..quadraticBezierTo(-1.8, .2, -1.4, .28)
      ..quadraticBezierTo(-1.62, .44, -1.08, .34)
      ..quadraticBezierTo(-.72, .14, -.4, .12)
      ..close();
    c.drawPath(wing, _fill(_cream(SkyColors.purple, .18)));
    c.save();
    c.clipPath(wing);
    c.drawCircle(const Offset(-1.5, -.08), .78, _fill(SkyColors.coral));
    c.drawCircle(
      const Offset(-1.68, -.16),
      .36,
      _fill(_cream(SkyColors.lavender, .45)),
    );
    c.drawCircle(const Offset(-1.32, -.06), .24, _fill(SkyColors.cream));
    c.drawCircle(const Offset(-1.32, -.06), .14, _fill(SkyColors.coralDeep));
    c.drawCircle(const Offset(-1.32, -.06), .065, _fill(SkyColors.ink));
    c.restore();
    c.drawPath(wing, _stroke(SkyColors.ink, .06));
  }

  static void _hindWing(Canvas c) {
    final wing = Path()
      ..moveTo(-.38, .18)
      ..cubicTo(-.78, .12, -1.22, .3, -1.4, .6)
      ..quadraticBezierTo(-1.58, .84, -1.16, .98)
      ..quadraticBezierTo(-.78, 1.14, -.42, .88)
      ..quadraticBezierTo(-.28, .55, -.34, .24)
      ..close();
    c.drawPath(wing, _fill(SkyColors.coralDeep));
    c.save();
    c.clipPath(wing);
    c.drawCircle(const Offset(-1.02, .68), .34, _fill(SkyColors.purple));
    c.drawCircle(const Offset(-.92, .6), .14, _fill(SkyColors.cream));
    c.restore();
    c.drawPath(wing, _stroke(SkyColors.ink, .055));
  }

  static void _feeler(Canvas c, double sway) {
    final root = const Offset(-.14, -.8);
    final tip = Offset(-.52, -1.12 + sway);
    final stalk = _stroke(SkyColors.ink, .05);
    c.drawLine(root, tip, stalk);
    for (var i = 1; i <= 3; i++) {
      final at = Offset.lerp(root, tip, i / 4)!;
      c.drawLine(at, at + const Offset(-.15, -.03), stalk);
      c.drawLine(at, at + const Offset(-.03, -.15), stalk);
    }
  }

  static void _disc(
    Canvas c,
    Color base, {
    required Color lit,
    required Color shade,
  }) {
    c.drawPath(_unit, _fill(base));
    c.save();
    c.clipPath(_unit);
    c.drawOval(const Rect.fromLTWH(-.85, -.92, .9, .7), _fill(lit));
    c.drawOval(const Rect.fromLTWH(-.05, .05, 1.05, .95), _fill(shade));
    c.restore();
    c.drawPath(_unit, _stroke(SkyColors.ink, .07));
  }

  static void _eyes(
    Canvas c,
    double y,
    double glance, {
    required double lid,
    double gap = .3,
  }) {
    _eye(c, Offset(-gap, y), glance, lid: lid);
    _eye(c, Offset(gap, y), glance, lid: 0);
  }

  static void _eye(Canvas c, Offset at, double glance, {required double lid}) {
    const rx = .29;
    final ry = .32 * (1 - .45 * lid);
    final oval = Rect.fromCenter(center: at, width: rx * 2, height: ry * 2);
    c.drawOval(oval, _fill(SkyColors.cream));
    c.drawOval(oval, _stroke(SkyColors.ink, .045));
    final pupil = at + Offset(-.035 + glance, .035);
    c.drawCircle(pupil, .12, _fill(SkyColors.ink));
    c.drawCircle(
      pupil + const Offset(-.045, -.05),
      .05,
      _fill(SkyColors.white),
    );
  }

  static void _brow(Canvas c, Offset from, Offset to) {
    c.drawLine(from, to, _stroke(SkyColors.ink, .075));
  }

  static void _grin(
    Canvas c,
    Offset at, {
    bool fangs = false,
    double width = .5,
  }) {
    final mouth = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: width, height: width * .46),
      Radius.circular(width * .24),
    );
    c.drawRRect(mouth, _fill(SkyColors.ink));
    if (!fangs) {
      c.drawArc(
        Rect.fromCenter(
          center: at + Offset(0, -width * .02),
          width: width * .55,
          height: width * .28,
        ),
        .2,
        2.7,
        false,
        _stroke(_cream(SkyColors.coral, .2), .04),
      );
      return;
    }
    final tooth = _fill(SkyColors.cream);
    for (final dx in [-width * .18, width * .06]) {
      c.drawPath(
        Path()
          ..moveTo(at.dx + dx, at.dy - width * .14)
          ..lineTo(at.dx + dx + width * .12, at.dy - width * .14)
          ..lineTo(at.dx + dx + width * .05, at.dy + width * .06)
          ..close(),
        tooth,
      );
    }
  }

  static void _pair(Canvas c, void Function(Canvas canvas) draw) {
    draw(c);
    c.save();
    c.scale(-1, 1);
    draw(c);
    c.restore();
  }

  static void _hinge(
    Canvas c,
    Offset joint,
    double turn,
    void Function() draw,
  ) {
    c.save();
    c.translate(joint.dx, joint.dy);
    c.rotate(turn);
    c.translate(-joint.dx, -joint.dy);
    draw();
    c.restore();
  }

  static Path _crescent(Offset at, double radius) {
    final disk = Path()..addOval(Rect.fromCircle(center: at, radius: radius));
    final bite = Path()
      ..addOval(
        Rect.fromCircle(
          center: at + Offset(radius * .45, -radius * .08),
          radius: radius * .74,
        ),
      );
    return Path.combine(PathOperation.difference, disk, bite);
  }

  static final Path _unit = Path()..addOval(const Rect.fromLTWH(-1, -1, 2, 2));

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static Color _inked(Color color, double t) =>
      Color.lerp(color, SkyColors.ink, t)!;

  static Color _cream(Color color, double t) =>
      Color.lerp(color, SkyColors.cream, t)!;

  static double _wave(double time, double motion, double speed) =>
      motion == 0 ? 0 : math.sin(time * speed);
}
