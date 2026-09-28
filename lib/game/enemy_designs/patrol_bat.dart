import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// A small, unarmored cave bat seen in three-quarter view, facing the bird.
///
/// The head and muzzle face left. The near wing sweeps behind the body, the
/// smaller far wing peeks out past the ears, so the silhouette reads as a
/// flying bat in every pose at the normal 16 px hit radius. Geometry stays
/// within x ±1.9r, y ±1.2r.
abstract final class PatrolBatArt {
  /// Seconds per wingbeat; the downstroke is quicker than the recovery.
  static const wingPeriod = .46;
  static const _downstroke = .42;

  /// Reduced Motion holds the widest, most readable pose.
  static const _restPhase = .2;

  static const _ink = Color(0xff2a1820);
  static const _fur = Color(0xff8b5a48);
  static const _furLit = Color(0xffc98e67);
  static const _furShade = Color(0xff5f3a36);
  static const _ruff = Color(0xffeac291);
  static const _muzzle = Color(0xffe3ad88);
  static const _earInner = Color(0xfff2988a);
  static const _membraneLit = Color(0xffb86d6c);
  static const _membrane = Color(0xff7a4250);
  static const _membraneDark = Color(0xff4a2332);
  static const _farMembrane = Color(0xff563040);
  static const _farMembraneDark = Color(0xff3c1e2b);
  static const _bone = Color(0xffeab98c);
  static const _eyeWhite = Color(0xfffff7e6);

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
    final phase = reducedMotion ? _restPhase : _wrap(time / wingPeriod);
    // The downstroke lifts the body a touch; ears and feet trail behind it.
    final lift = reducedMotion ? 0.0 : (_stroke(phase) - .5) * -.07;
    final trail = reducedMotion ? 0.0 : _stroke(phase - .12) - .5;
    final blink = reducedMotion ? 0.0 : _blink(time);

    c.save();
    c.scale(radius);
    c.translate(0, lift);
    _wing(c, _farWing, phase - .09, far: true);
    _feet(c, trail);
    _body(c);
    _wing(c, _nearWing, phase, far: false);
    _head(c, aim, blink, trail);
    c.restore();
  }

  static double _wrap(double v) => v - v.floorToDouble();

  /// 0 = wings raised, 1 = wings down. Snappy power stroke, soft recovery.
  static double _stroke(double phase) {
    final p = _wrap(phase);
    if (p < _downstroke) {
      final u = p / _downstroke;
      return u * u * u * (u * (u * 6 - 15) + 10);
    }
    final u = (p - _downstroke) / (1 - _downstroke);
    return .5 + .5 * math.cos(math.pi * u);
  }

  /// The hand tucks in during the recovery stroke and opens for the next beat.
  static double _fold(double phase) {
    final p = _wrap(phase);
    if (p < _downstroke) return 0;
    final s = math.sin(math.pi * (p - _downstroke) / (1 - _downstroke));
    return s * s;
  }

  static double _blink(double time) {
    final t = _wrap((time + 1.3) / 3.7) * 3.7;
    return t < .16 ? math.sin(math.pi * t / .16) : 0;
  }

  static Offset _q(Offset up, Offset mid, Offset down, double p) =>
      up * (2 * (p - .5) * (p - 1)) +
      mid * (-4 * p * (p - 1)) +
      down * (2 * p * (p - .5));

  static void _wing(Canvas c, _WingRig rig, double phase, {required bool far}) {
    final p = _stroke(phase);
    final lag = _stroke(phase - .05);
    final fold = _fold(phase);
    final s = rig.shoulder, a = rig.attach;
    final e = _q(rig.up[0], rig.mid[0], rig.down[0], p);
    final w = _q(rig.up[1], rig.mid[1], rig.down[1], p);
    Offset finger(int i, double tuck) {
      final tip = _q(rig.up[i], rig.mid[i], rig.down[i], lag);
      return w + (tip - w) * (1 - fold * tuck);
    }

    final t1 = finger(2, .2), t2 = finger(3, .26), t3 = finger(4, .2);
    Offset scallop(Offset from, Offset to, Offset pull, double k) =>
        Offset.lerp((from + to) / 2, pull, k)!;
    final membrane = Path()
      ..moveTo(s.dx, s.dy)
      ..lineTo(e.dx, e.dy)
      ..lineTo(w.dx, w.dy)
      ..lineTo(t1.dx, t1.dy);
    for (final (from, to, pull, k) in [
      (t1, t2, w, .3),
      (t2, t3, w, .3),
      (t3, a, e, .26),
    ]) {
      final ctrl = scallop(from, to, pull, k);
      membrane.quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);
    }
    membrane.close();
    // Lit along the arm, deepening toward the scalloped trailing edge.
    c.drawPath(
      membrane,
      Paint()
        ..shader = ui.Gradient.linear(
          (e + w) / 2,
          (t2 + t3) / 2,
          far
              ? const [_farMembrane, _farMembraneDark]
              : const [_membraneLit, _membrane, _membraneDark],
          far ? null : const [0, .5, 1],
        ),
    );

    final bone = _line(far ? _membraneLit : _bone, far ? .04 : .048);
    for (final tip in [t1, t2, t3]) {
      c.drawLine(w, tip, bone);
    }
    c.drawPath(membrane, _line(_ink, .07));

    // The furred arm is the wing's solid leading edge, tapering to the
    // wrist, where a hooked thumb claw points away from the membrane.
    final armColor = far ? _furShade : _furLit;
    c.drawLine(s, e, _line(_ink, .22));
    c.drawLine(e, w, _line(_ink, .18));
    c.drawLine(s, e, _line(armColor, .1));
    c.drawLine(e, w, _line(armColor, .065));
    final along = (w - e) / (w - e).distance;
    var out = Offset(along.dy, -along.dx);
    if ((t2 - w).dx * out.dx + (t2 - w).dy * out.dy > 0) out = -out;
    final base = w - along * .02;
    c.drawPath(
      Path()
        ..moveTo(base.dx - along.dx * .05, base.dy - along.dy * .05)
        ..lineTo(base.dx + along.dx * .07, base.dy + along.dy * .07)
        ..quadraticBezierTo(
          base.dx + out.dx * .1 + along.dx * .06,
          base.dy + out.dy * .1 + along.dy * .06,
          base.dx + out.dx * .15 - along.dx * .02,
          base.dy + out.dy * .15 - along.dy * .02,
        )
        ..close(),
      _fill(_ink),
    );
  }

  static final _nearWing = _WingRig(
    shoulder: const Offset(.18, -.3),
    attach: const Offset(.62, .36),
    up: const [
      Offset(.36, -.82),
      Offset(.86, -1.06),
      Offset(1.8, -1.0),
      Offset(1.74, -.5),
      Offset(1.3, -.12),
    ],
    mid: const [
      Offset(.6, -.5),
      Offset(1.14, -.56),
      Offset(1.8, -.2),
      Offset(1.56, .34),
      Offset(1.08, .5),
    ],
    down: const [
      Offset(.56, -.06),
      Offset(1.0, .24),
      Offset(1.74, .78),
      Offset(1.24, 1.12),
      Offset(.72, 1.06),
    ],
  );

  static final _farWing = _WingRig(
    shoulder: const Offset(-.34, -.46),
    attach: const Offset(-.42, .02),
    up: const [
      Offset(-.66, -.8),
      Offset(-1.1, -.98),
      Offset(-1.7, -.86),
      Offset(-1.62, -.46),
      Offset(-1.3, -.26),
    ],
    mid: const [
      Offset(-.74, -.6),
      Offset(-1.18, -.62),
      Offset(-1.72, -.3),
      Offset(-1.52, .08),
      Offset(-1.16, .14),
    ],
    down: const [
      Offset(-.74, -.34),
      Offset(-1.14, -.14),
      Offset(-1.72, .36),
      Offset(-1.38, .6),
      Offset(-1.0, .5),
    ],
  );

  static void _feet(Canvas c, double trail) {
    for (final (hip, ankle) in const [
      (Offset(.38, .4), Offset(.5, .62)),
      (Offset(.6, .3), Offset(.77, .48)),
    ]) {
      final a = ankle + Offset(.06 * trail, -.04 * trail);
      c.drawLine(hip, a, _line(_ink, .17));
      c.drawLine(hip, a, _line(_furShade, .08));
      // Little hooked toes, the grip a bat roosts by.
      c.drawPath(
        Path()
          ..moveTo(a.dx - .05, a.dy + .01)
          ..quadraticBezierTo(a.dx - .03, a.dy + .13, a.dx + .07, a.dy + .11)
          ..moveTo(a.dx + .03, a.dy - .03)
          ..quadraticBezierTo(a.dx + .1, a.dy + .08, a.dx + .17, a.dy + .03),
        _line(_ink, .065),
      );
    }
  }

  static final Path _torso = Path()
    ..moveTo(-.4, -.34)
    ..cubicTo(-.1, -.52, .42, -.46, .62, -.18)
    ..cubicTo(.84, .1, .7, .44, .42, .54)
    ..cubicTo(.14, .64, -.22, .56, -.42, .38)
    ..cubicTo(-.62, .2, -.64, -.2, -.4, -.34)
    ..close();
  static final Path _torsoLit = Path.combine(
    PathOperation.difference,
    _torso,
    _torso.shift(const Offset(.08, .12)),
  );
  static final Path _torsoShade = Path.combine(
    PathOperation.difference,
    _torso,
    _torso.shift(const Offset(-.1, -.14)),
  );
  static final Path _ruffPath = Path()
    ..moveTo(-.64, -.04)
    ..quadraticBezierTo(-.72, .26, -.52, .3)
    ..quadraticBezierTo(-.46, .46, -.3, .4)
    ..quadraticBezierTo(-.16, .52, -.04, .38)
    ..quadraticBezierTo(.12, .34, .06, .14)
    ..quadraticBezierTo(-.12, -.08, -.4, -.08)
    ..close();

  static void _body(Canvas c) {
    c.drawPath(_torso, _fill(_fur));
    c.drawPath(_torsoLit, _fill(_furLit));
    c.drawPath(_torsoShade, _fill(_furShade));
    c.drawPath(_torso, _line(_ink, .075));
    c.drawPath(_ruffPath, _fill(_ruff));
    c.drawPath(_ruffPath, _line(_ink, .05));
  }

  static final Path _headPath = Path()
    ..moveTo(-.96, -.5)
    ..cubicTo(-.9, -.8, -.42, -.9, -.22, -.64)
    ..cubicTo(-.06, -.46, -.06, -.12, -.2, .04)
    ..cubicTo(-.36, .2, -.7, .2, -.9, .08)
    ..cubicTo(-1.05, .02, -1.2, -.04, -1.28, -.13)
    ..cubicTo(-1.34, -.22, -1.28, -.32, -1.16, -.36)
    ..cubicTo(-1.06, -.39, -.99, -.43, -.96, -.5)
    ..close();
  static final Path _headLit = Path.combine(
    PathOperation.difference,
    _headPath,
    _headPath.shift(const Offset(.08, .11)),
  );
  static final Path _headShade = Path.combine(
    PathOperation.difference,
    _headPath,
    _headPath.shift(const Offset(-.09, -.12)),
  );
  static final Path _muzzlePath = Path()
    ..moveTo(-1.22, -.2)
    ..quadraticBezierTo(-1.1, -.34, -.9, -.24)
    ..quadraticBezierTo(-.74, -.12, -.8, .04)
    ..quadraticBezierTo(-1.04, .08, -1.24, -.08)
    ..close();
  static final Path _nearEar = Path()
    ..moveTo(-.52, -.66)
    ..quadraticBezierTo(-.5, -1.0, -.21, -1.1)
    ..quadraticBezierTo(-.04, -.85, -.16, -.46)
    ..close();
  static final Path _nearEarInner = Path()
    ..moveTo(-.42, -.64)
    ..quadraticBezierTo(-.4, -.89, -.24, -.97)
    ..quadraticBezierTo(-.14, -.8, -.22, -.56)
    ..close();
  static final Path _farEar = Path()
    ..moveTo(-.72, -.72)
    ..quadraticBezierTo(-.9, -.98, -1.12, -1.06)
    ..quadraticBezierTo(-1.14, -.76, -.96, -.5)
    ..close();
  static final Path _farEarInner = Path()
    ..moveTo(-.8, -.7)
    ..quadraticBezierTo(-.94, -.9, -1.04, -.95)
    ..quadraticBezierTo(-1.05, -.76, -.94, -.6)
    ..close();
  static final Path _eyePath = Path()
    ..moveTo(-1.03, -.29)
    ..quadraticBezierTo(-.83, -.67, -.5, -.46)
    ..quadraticBezierTo(-.55, -.1, -.83, -.12)
    ..quadraticBezierTo(-.98, -.15, -1.03, -.29)
    ..close();

  static void _head(Canvas c, double aim, double blink, double trail) {
    void ear(Path outer, Path inner, Offset pivot, double tilt, bool far) {
      c.save();
      c.translate(pivot.dx, pivot.dy);
      c.rotate(tilt);
      c.translate(-pivot.dx, -pivot.dy);
      c.drawPath(outer, _fill(far ? _furShade : _fur));
      c.drawPath(inner, _fill(far ? const Color(0xffc9727a) : _earInner));
      c.drawPath(outer, _line(_ink, .07));
      c.restore();
    }

    // A slight turn toward the bird makes tracking readable at 16 px.
    c.save();
    c.translate(-.62, -.2);
    c.rotate(aim * .06);
    c.translate(.62, .2);
    ear(_farEar, _farEarInner, const Offset(-.84, -.62), -trail * .1, true);
    c.drawPath(_headPath, _fill(_fur));
    c.drawPath(_headLit, _fill(_furLit));
    c.drawPath(_headShade, _fill(_furShade));
    c.drawPath(_muzzlePath, _fill(_muzzle));
    c.drawPath(_headPath, _line(_ink, .075));
    ear(_nearEar, _nearEarInner, const Offset(-.34, -.56), trail * .12, false);

    // Dark button nose, sly smirk and one little fang.
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-1.21, -.24),
        width: .17,
        height: .13,
      ),
      _fill(_ink),
    );
    c.drawPath(
      Path()
        ..moveTo(-1.02, -.02)
        ..lineTo(-.92, -.01)
        ..lineTo(-.975, .12)
        ..close(),
      _fill(_eyeWhite),
    );
    c.drawPath(
      Path()
        ..moveTo(-1.2, -.07)
        ..quadraticBezierTo(-1.0, .04, -.8, -.03)
        ..quadraticBezierTo(-.75, -.05, -.73, -.1),
      _line(_ink, .05),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.58, -.1), width: .17, height: .1),
      _fill(_earInner.withValues(alpha: .7)),
    );

    // Big eye with a mischievous low lid; the pupil follows the bird.
    c.drawPath(_eyePath, _fill(_eyeWhite));
    c.save();
    c.clipPath(_eyePath);
    final pupil = Offset(-.84, -.31 + aim * .07);
    c.drawOval(
      Rect.fromCenter(center: pupil, width: .22, height: .29),
      _fill(_ink),
    );
    c.drawCircle(pupil + const Offset(-.045, -.065), .05, _fill(_eyeWhite));
    final lid = -.5 + blink * .38;
    c.drawPath(
      Path()
        ..moveTo(-1.07, lid + .1)
        ..lineTo(-.48, lid - .05)
        ..lineTo(-.48, -.72)
        ..lineTo(-1.07, -.72)
        ..close(),
      _fill(_fur),
    );
    c.drawLine(
      Offset(-1.07, lid + .1),
      Offset(-.48, lid - .05),
      _line(_ink, .07),
    );
    // A cheek pushed up under the back of the eye turns the squint into a
    // grin rather than a scowl.
    const cheek = Rect.fromLTWH(-.74, -.25, .42, .3);
    c.drawOval(cheek, _fill(_fur));
    c.drawOval(cheek, _line(_ink, .05));
    c.restore();
    c.drawPath(_eyePath, _line(_ink, .055));
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

final class _WingRig {
  const _WingRig({
    required this.shoulder,
    required this.attach,
    required this.up,
    required this.mid,
    required this.down,
  });

  final Offset shoulder, attach;

  /// Elbow, wrist, then the three fingertips from leading to trailing.
  final List<Offset> up, mid, down;
}
