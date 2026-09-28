import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../boss_rig.dart';

/// The little sibling of Baron Bat: the same purple body, pointed ears, fangs
/// and scalloped membrane wings, without the crown or regalia.
///
/// It is drawn at small-enemy proportions (a big head-body and short wings)
/// with outlines that hold at the 16 px gameplay radius. Each wing is a small
/// bone rig keyed through a full stroke: raised, spread on the power stroke,
/// swept down, then flexed on the recovery. The rig looks left by default; the
/// caller owns facing. Every pose stays within x ±1.9r, y ±1.2r.
abstract final class SimpleBatArt {
  /// One wingbeat. The downstroke takes 45% of it; the recovery is slower.
  static const cycleSeconds = .62;

  // The small-enemy flight arc (SkyEnemy, simpleBat) rises and sinks at this
  // rate. The bat flaps while climbing and glides on spread wings while it
  // sinks; out of sync it is still a natural flap-flap-glide rhythm.
  static const _arcRate = 2.8;
  static const _blinkEvery = 3.7, _blinkAt = 2.1, _blinkSeconds = .15;

  static const _ink = BossRig.ink, _plum = BossRig.plum;
  static const _violet = BossRig.violet, _cream = BossRig.cream;
  static const _lilac = Color(0xffd6b6eb);
  static const _belly = Color(0xffc0a3df);
  static const _tongue = Color(0xffcc6884);
  static const _blush = Color(0x88f492b4);

  static const _body = Rect.fromLTRB(-.68, -.62, .68, .68);
  static const _shoulder = Offset(.36, -.18), _hip = Offset(.38, .32);

  // Right-wing key poses: wrist, tip, and three trailing finger tips.
  static const _raised = 0, _spread = 1;
  static const _keyTimes = [0.0, .22, .45, .72];
  static const _keys = [
    // Raised: the V at the top of the stroke.
    [
      Offset(.72, -.92),
      Offset(1.36, -1.1),
      Offset(1.5, -.66),
      Offset(1.26, -.3),
      Offset(.86, -.04),
    ],
    // Spread: full span through the power stroke, and the glide pose.
    [
      Offset(.98, -.74),
      Offset(1.74, -.5),
      Offset(1.62, .1),
      Offset(1.2, .4),
      Offset(.76, .48),
    ],
    // Swept down at the bottom of the stroke.
    [
      Offset(1.06, -.3),
      Offset(1.56, .32),
      Offset(1.24, .72),
      Offset(.9, .74),
      Offset(.62, .6),
    ],
    // Flexed recovery: the wrist leads up while the hand trails, folded.
    [
      Offset(.9, -.72),
      Offset(1.42, -.28),
      Offset(1.26, .1),
      Offset(.98, .3),
      Offset(.7, .4),
    ],
  ];

  static final _bodyPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_lilac, _violet, _plum],
    ).createShader(_body);
  static final _wingPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xffbb9fe3), Color(0xff65528f), Color(0xff382a52)],
    ).createShader(const Rect.fromLTRB(.3, -1.1, 1.8, .8));
  static final _inkFill = _fill(_ink);
  static final _outline = _line(_ink, .07);
  static final _bones = _line(_violet.withValues(alpha: .8), .04);
  static final _edge = _line(_violet, .05);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

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
    final time = seconds.isFinite && seconds > 0 ? seconds : 0.0;
    final look = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    final tense = charge.isFinite ? charge.clamp(0.0, 1.0) : 0.0;
    final kick = recoil.isFinite ? recoil.clamp(0.0, 1.0) : 0.0;
    final phase = (time / cycleSeconds) % 1;
    // Reduced Motion holds the glide: the clearest, most bat-like silhouette.
    final glide = reducedMotion ? 1.0 : _glide(time);
    // The downstroke lifts the body; it sinks through the recovery.
    final bob = .05 * (1 - glide) * math.cos((phase - .08) * math.pi * 2);
    final blinkAge = (time % _blinkEvery) - _blinkAt;
    final blink = reducedMotion || blinkAge < 0 || blinkAge > _blinkSeconds
        ? 0.0
        : math.sin(blinkAge / _blinkSeconds * math.pi);

    final wing = [
      for (var point = 0; point < 5; point++)
        Offset.lerp(
          Offset.lerp(_pose(point, phase), _keys[_spread][point], glide),
          _keys[_raised][point],
          tense * .5,
        )!,
    ];
    final membrane = _membrane(wing);

    c.save();
    c.scale(radius);
    c.translate(0, bob);
    // Wind-up and recoil only squash, so no pose can leave the art box.
    if (!reducedMotion) {
      c.scale(1 + tense * .04 - kick * .06, 1 - tense * .04 - kick * .03);
    }
    for (final side in const [-1.0, 1.0]) {
      c.save();
      c.scale(side, 1);
      _wing(c, membrane, wing);
      c.restore();
    }
    _ears(c);
    _torso(c);
    _face(c, look, blink, math.max(tense * .6, kick));
    c.restore();
  }

  static double _glide(double time) {
    final t = ((math.cos(time * _arcRate) - .35) / .5).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Cubic Hermite through the key poses; Catmull-Rom tangents over the uneven
  /// key timing keep each point's path and speed continuous (no pops).
  static Offset _pose(int point, double phase) {
    var i = _keyTimes.length - 1;
    while (phase < _keyTimes[i]) {
      i--;
    }
    final j = (i + 1) % _keyTimes.length;
    final t0 = _keyTimes[i], t1 = j == 0 ? 1.0 : _keyTimes[j];
    final dt = t1 - t0;
    final s = (phase - t0) / dt, s2 = s * s, s3 = s * s * s;
    return _keys[i][point] * (2 * s3 - 3 * s2 + 1) +
        _tangent(point, i) * (dt * (s3 - 2 * s2 + s)) +
        _keys[j][point] * (3 * s2 - 2 * s3) +
        _tangent(point, j) * (dt * (s3 - s2));
  }

  static Offset _tangent(int point, int k) {
    const n = 4;
    final prev = (k + n - 1) % n, next = (k + 1) % n;
    final tPrev = _keyTimes[prev] - (prev > k ? 1 : 0);
    final tNext = _keyTimes[next] + (next < k ? 1 : 0);
    return (_keys[next][point] - _keys[prev][point]) / (tNext - tPrev);
  }

  // Scallops dip toward the wrist, so fingers stay pointed in every pose.
  static Offset _toward(Offset a, Offset b, Offset target, double pull) {
    final mid = (a + b) / 2;
    return mid + (target - mid) * pull;
  }

  static Offset _bulge(Offset a, Offset b, double amount) {
    final d = b - a;
    final length = d.distance;
    if (length == 0) return a;
    return (a + b) / 2 + Offset(d.dy, -d.dx) / length * amount;
  }

  static void _quad(Path path, Offset control, Offset to) =>
      path.quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);

  static Path _membrane(List<Offset> wing) {
    final [wrist, tip, f1, f2, f3] = wing;
    final path = Path()..moveTo(_shoulder.dx, _shoulder.dy);
    _quad(path, _bulge(_shoulder, wrist, .14), wrist);
    _quad(path, _bulge(wrist, tip, .05), tip);
    _quad(path, _toward(tip, f1, wrist, .34), f1);
    _quad(path, _toward(f1, f2, wrist, .36), f2);
    _quad(path, _toward(f2, f3, wrist, .36), f3);
    _quad(path, _toward(f3, _hip, _shoulder, .3), _hip);
    return path..close();
  }

  static void _wing(Canvas c, Path membrane, List<Offset> wing) {
    final [wrist, tip, f1, f2, f3] = wing;
    c.drawPath(membrane.shift(const Offset(.02, .05)), _inkFill);
    c.drawPath(membrane, _wingPaint);
    final bones = Path();
    for (final finger in [f1, f2]) {
      bones.moveTo(wrist.dx, wrist.dy);
      _quad(bones, _bulge(wrist, finger, -.04), finger);
    }
    final elbow = Offset.lerp(_shoulder, wrist, .55)!;
    bones
      ..moveTo(elbow.dx, elbow.dy)
      ..lineTo(f3.dx, f3.dy);
    c.drawPath(bones, _bones);
    c.drawPath(membrane, _outline);
    // A lilac leading edge keeps the wing readable against dark skies.
    const lift = Offset(0, .05);
    final edge = Path()..moveTo(_shoulder.dx, _shoulder.dy + lift.dy);
    _quad(edge, _bulge(_shoulder, wrist, .14) + lift, wrist + lift);
    _quad(
      edge,
      _bulge(wrist, tip, .05) + lift * .8,
      tip + const Offset(-.06, .03),
    );
    c.drawPath(edge, _edge);
  }

  static void _ears(Canvas c) {
    for (final side in const [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(side * .52, -.4)
        ..lineTo(side * .79, -1.06)
        ..quadraticBezierTo(side * .34, -.88, side * .14, -.5)
        ..close();
      c.drawPath(ear, _fill(_plum));
      c.drawPath(ear, _line(_ink, .065));
      c.drawLine(
        Offset(side * .52, -.62),
        Offset(side * .67, -.92),
        _line(_violet, .07),
      );
    }
  }

  static void _torso(Canvas c) {
    c.drawOval(_body.shift(const Offset(.03, .06)), _inkFill);
    c.drawOval(_body, _bodyPaint);
    c.drawOval(const Rect.fromLTRB(-.4, .24, .4, .64), _fill(_belly));
    c.drawOval(_body, _outline);
    c.drawArc(
      _body.deflate(.09),
      -2.75,
      1.3,
      false,
      _line(_cream.withValues(alpha: .55), .045),
    );
  }

  static void _face(Canvas c, double look, double blink, double open) {
    for (final side in const [-1.0, 1.0]) {
      final center = Offset(side * .29, -.17);
      final eye = Rect.fromCenter(center: center, width: .42, height: .46);
      c.drawOval(eye.inflate(.045), _fill(_plum));
      c.drawOval(eye, _fill(_cream));
      final pupil = center + Offset(-.07, .03 + look * .07);
      c.drawOval(
        Rect.fromCenter(center: pupil, width: .21, height: .27),
        _inkFill,
      );
      c.drawCircle(
        pupil + const Offset(-.035, -.07),
        .055,
        _fill(const Color(0xffffffff)),
      );
      // A lazy, softly arched upper lid, lower toward the nose, gives a smug
      // rather than angry look; it also closes for blinks.
      final outer = Offset(side * .56, -.42 + blink * .5);
      final inner = Offset(side * .06, -.32 + blink * .5);
      final arch = (outer + inner) / 2 + const Offset(0, -.06);
      final lidLine = Path()..moveTo(outer.dx, outer.dy);
      _quad(lidLine, arch, inner);
      c.save();
      c.clipRRect(RRect.fromRectXY(eye, eye.width / 2, eye.height / 2));
      c.drawPath(
        Path.from(lidLine)
          ..lineTo(inner.dx, -.5)
          ..lineTo(outer.dx, -.5)
          ..close(),
        _fill(_belly),
      );
      c.restore();
      c.drawPath(lidLine, _line(_ink, .075));
      c.drawOval(
        Rect.fromCenter(
          center: Offset(side * .5, .12),
          width: .17,
          height: .09,
        ),
        _fill(_blush),
      );
    }
    // A lopsided grin with the family fangs: the corner toward the bird rides
    // higher. Wind-up or recoil drops the jaw.
    final drop = open * .16;
    final mouth = Path()
      ..moveTo(-.36, .01)
      ..quadraticBezierTo(-.06, .09, .24, .06)
      ..cubicTo(.2, .24 + drop, -.22, .27 + drop, -.36, .01)
      ..close();
    c.drawPath(mouth, _inkFill);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-.05, .18 + drop),
        width: .16,
        height: .06,
      ),
      _fill(_tongue),
    );
    for (final (x, top) in const [(-.19, .05), (.07, .065)]) {
      c.drawPath(
        Path()
          ..moveTo(x - .05, top - .01)
          ..lineTo(x, top + .1)
          ..lineTo(x + .05, top - .01)
          ..close(),
        _fill(_cream),
      );
    }
  }
}
