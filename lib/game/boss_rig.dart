import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'sky_scenery.dart';

/// Baron Bat: the crowned, caped elder of the purple bat family.
///
/// Authored layers pivot independently; coordinates use the combat hit radius
/// (the body oval spans x ±.91, y -.81..89). The rig is symmetric and looks
/// left toward the bird. Every pose stays inside the encounter layer
/// (x ±3, y -2.3..1.7).
abstract final class BossRig {
  static const ink = Color(0xff18182f), plum = Color(0xff514278);
  static const violet = Color(0xffaa89d3), gold = Color(0xffffd878);
  static const cream = Color(0xfffff2c9), ember = Color(0xffff775c);
  static const _lilac = Color(0xffd6b6eb), _wine = Color(0xff6e2a4f);
  static const _lining = Color(0xffc2456a), _bronze = Color(0xffb97a3d);
  static const _steel = Color(0xff6f6d95), _steelDark = Color(0xff262848);
  static const _tongue = Color(0xffcc6884), _mint = Color(0xff98f0dc);
  static Paint fill(Color color) => Paint()..color = color;
  static Paint line(Color color, [double width = .045]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint gradient(Rect rect, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);

  static const _body = Rect.fromLTWH(-.91, -.81, 1.82, 1.7);
  static const _eyeY = -.25, _eyeX = .36;

  // Right-wing rig in body coordinates: the shoulder and hip roots, then the
  // wrist, the tip and three trailing finger tips of each key pose.
  static const _root = Offset(.6, -.2), _hip = Offset(.64, .34);
  static const _spread = [
    Offset(1.42, -1.0),
    Offset(2.42, -.8),
    Offset(2.3, -.08),
    Offset(1.74, .4),
    Offset(1.14, .62),
  ];
  static const _raised = [
    Offset(1.26, -1.28),
    Offset(1.98, -1.74),
    Offset(2.34, -1.18),
    Offset(2.1, -.52),
    Offset(1.46, .02),
  ];
  static const _down = [
    Offset(1.5, -.64),
    Offset(2.34, -.08),
    Offset(2.0, .6),
    Offset(1.48, .88),
    Offset(.98, .8),
  ];
  // Folded into a tall cloak: the wrist tucks by the ear, fingers run down.
  static const _folded = [
    Offset(1.02, -.98),
    Offset(.96, -1.5),
    Offset(1.16, -.62),
    Offset(1.14, .08),
    Offset(.92, .6),
  ];

  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion motion, {
    double lookY = 0,
    bool adorned = true,
  }) {
    final look = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    final fury = boss.enraged && !motion.defeated;
    final flash = motion.hit * (motion.reducedMotion ? .42 : .56);
    if (flash > .01) {
      // One bounded layer blows the fills out toward white for a crisp hit
      // flash while ink outlines stay dark, so the silhouette never ghosts.
      c.saveLayer(
        const Rect.fromLTWH(-3, -2.3, 6, 4),
        Paint()..colorFilter = _flash(flash),
      );
    }
    final wing = _wingPose(motion);
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.scale(side, 1);
      _wing(c, wing, fury, adorned: adorned);
      c.restore();
    }
    if (adorned) _cape(c);
    _ears(c);
    _torso(c, adorned);
    if (adorned) _breastplate(c, boss, motion, fury);
    _face(c, boss, motion, look, fury);
    if (adorned && motion.death < .3) {
      c.save();
      c.translate(0, -motion.crownLift);
      c.rotate(-motion.rotation * .55);
      crown(c);
      c.restore();
    }
    if (flash > .01) c.restore();
  }

  static ColorFilter _flash(double w) {
    const k = 2.6, b = -60.0;
    final keep = 1 - w;
    return ColorFilter.matrix([
      keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b, //
      0, 0, 0, 1, 0,
    ]);
  }

  static List<Offset> _wingPose(BossMotion motion) {
    final s = motion.wingStroke;
    // A parabola through raised (-1), spread (0) and down (1) keeps every
    // point's path smooth through the spread pose.
    return [
      for (var i = 0; i < 5; i++)
        Offset.lerp(
          _spread[i] +
              (_down[i] - _raised[i]) * (s / 2) +
              ((_down[i] + _raised[i]) / 2 - _spread[i]) * (s * s),
          _folded[i],
          motion.folded.clamp(0.0, 1.0),
        )!,
    ];
  }

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

  static void _wing(
    Canvas c,
    List<Offset> wing,
    bool fury, {
    required bool adorned,
  }) {
    final [wrist, tip, f1, f2, f3] = wing;
    final arm = _bulge(_root, wrist, .16), hand = _bulge(wrist, tip, .07);
    final path = Path()..moveTo(_root.dx, _root.dy);
    _quad(path, arm, wrist);
    _quad(path, hand, tip);
    _quad(path, _toward(tip, f1, wrist, .3), f1);
    _quad(path, _toward(f1, f2, wrist, .34), f2);
    _quad(path, _toward(f2, f3, wrist, .34), f3);
    _quad(path, _toward(f3, _hip, _root, .3), _hip);
    path.close();
    c.drawPath(path.shift(const Offset(.03, .07)), fill(ink));
    c.drawPath(
      path,
      gradient(const Rect.fromLTRB(.6, -1.7, 2.4, .9), [
        fury ? const Color(0xffd98fb4) : const Color(0xffb9a0e2),
        fury ? const Color(0xff633a6e) : const Color(0xff5a4884),
        fury ? const Color(0xff2e1a36) : const Color(0xff2b2140),
      ]),
    );
    final bones = Path();
    for (final finger in [f1, f2, f3]) {
      bones.moveTo(wrist.dx, wrist.dy);
      _quad(bones, _bulge(wrist, finger, -.05), finger);
    }
    c.drawPath(bones, line(violet.withValues(alpha: .75), .035));
    for (var i = 0; adorned && i < 3; i++) {
      final at = Offset.lerp(wrist, [f1, f2, f3][i], .5 + i * .06)!;
      c.drawPath(
        SkyScenery.star(at + const Offset(.04, .05), .06 - i * .008),
        fill(gold.withValues(alpha: .55)),
      );
    }
    c.drawPath(path, line(ink, .065));
    // The bright leading edge holds the span against dark skies.
    final edge = Path()..moveTo(_root.dx + .04, _root.dy + .05);
    _quad(edge, arm + const Offset(0, .05), wrist + const Offset(0, .05));
    _quad(edge, hand + const Offset(0, .04), tip + const Offset(-.08, .04));
    c.drawPath(edge, line(fury ? ember : (adorned ? gold : violet), .05));
    // Thumb claw at the wrist.
    c.drawPath(
      Path()
        ..moveTo(wrist.dx - .06, wrist.dy + .02)
        ..quadraticBezierTo(
          wrist.dx - .02,
          wrist.dy - .16,
          wrist.dx - .16,
          wrist.dy - .2,
        )
        ..quadraticBezierTo(
          wrist.dx + .02,
          wrist.dy - .12,
          wrist.dx + .07,
          wrist.dy,
        )
        ..close(),
      fill(cream),
    );
  }

  // A high vampire collar frames the head and a scalloped cape hem trails.
  static void _cape(Canvas c) {
    final hem = Path()..moveTo(-.78, .2);
    const scallops = [
      Offset(-.98, .98),
      Offset(-.5, 1.18),
      Offset(0, 1.3),
      Offset(.5, 1.18),
      Offset(.98, .98),
    ];
    hem.lineTo(scallops.first.dx, scallops.first.dy);
    for (var i = 1; i < scallops.length; i++) {
      final a = scallops[i - 1], b = scallops[i];
      _quad(hem, _toward(a, b, const Offset(0, .5), .28), b);
    }
    hem
      ..lineTo(.78, .2)
      ..close();
    c.drawPath(hem.shift(const Offset(.03, .06)), fill(ink));
    c.drawPath(
      hem,
      gradient(const Rect.fromLTRB(-1, .2, 1, 1.3), [_lining, _wine]),
    );
    c.drawPath(hem, line(ink, .055));
    for (final side in [-1.0, 1.0]) {
      final lapel = Path()
        ..moveTo(side * .42, .3)
        ..lineTo(side * 1.02, .12)
        ..quadraticBezierTo(side * 1.02, -.3, side * 1.16, -.66)
        ..quadraticBezierTo(side * .86, -.5, side * .6, -.44)
        ..close();
      c.drawPath(lapel.shift(const Offset(.03, .06)), fill(ink));
      c.drawPath(
        lapel,
        gradient(const Rect.fromLTRB(-1.2, -.7, 1.2, .3), [_lining, _wine]),
      );
      c.drawPath(lapel, line(ink, .055));
    }
  }

  static void _ears(Canvas c) {
    for (final side in [-1.0, 1.0]) {
      // Swept out past the crown so ears, crown points and collar tips read
      // as one spiky regal crest.
      final ear = Path()
        ..moveTo(side * .66, -.42)
        ..lineTo(side * 1.02, -1.16)
        ..quadraticBezierTo(side * .5, -.98, side * .24, -.58)
        ..close();
      c.drawPath(ear.shift(const Offset(.03, .05)), fill(ink));
      c.drawPath(ear, fill(plum));
      c.drawPath(ear, line(ink, .06));
      c.drawPath(
        Path()
          ..moveTo(side * .62, -.6)
          ..lineTo(side * .9, -.98)
          ..lineTo(side * .5, -.78)
          ..close(),
        fill(const Color(0xff9a6fb7)),
      );
    }
  }

  static void _torso(Canvas c, bool adorned) {
    c.drawOval(_body.shift(const Offset(.035, .08)), fill(ink));
    c.drawOval(_body, gradient(_body, [_lilac, violet, plum]));
    if (!adorned) {
      c.drawOval(
        const Rect.fromLTWH(-.43, .28, .86, .48),
        fill(const Color(0xffc0a3df)),
      );
    }
    c.drawOval(_body, line(ink, .06));
    c.drawArc(
      _body.deflate(.09),
      -2.8,
      1.25,
      false,
      line(cream.withValues(alpha: .55), .04),
    );
  }

  static void _breastplate(
    Canvas c,
    SkyBoss boss,
    BossMotion motion,
    bool fury,
  ) {
    final armor = Path()
      ..moveTo(-.64, .4)
      ..quadraticBezierTo(0, .26, .64, .4)
      ..quadraticBezierTo(.6, .86, 0, 1.02)
      ..quadraticBezierTo(-.6, .86, -.64, .4)
      ..close();
    c.drawPath(armor.shift(const Offset(.02, .05)), fill(ink));
    c.drawPath(
      armor,
      gradient(const Rect.fromLTRB(-.64, .3, .64, 1), [_steel, _steelDark]),
    );
    c.drawPath(armor, line(gold, .055));
    c.drawPath(
      Path()
        ..moveTo(-.46, .48)
        ..quadraticBezierTo(-.34, .76, -.14, .86)
        ..moveTo(.46, .48)
        ..quadraticBezierTo(.34, .76, .14, .86),
      line(gold.withValues(alpha: .45), .025),
    );
    final glow = motion.defeated ? 0.0 : math.max(boss.charge, motion.recoil);
    final gemColor = fury ? ember : _mint;
    c.drawPath(SkyScenery.star(const Offset(0, .64), .25), fill(ink));
    final gem = Path()
      ..moveTo(0, .43)
      ..lineTo(.15, .63)
      ..lineTo(0, .86)
      ..lineTo(-.15, .63)
      ..close();
    c.drawPath(
      gem,
      gradient(const Rect.fromLTRB(-.15, .43, .15, .86), [
        cream,
        Color.lerp(gemColor, cream, glow * .45)!,
        fury ? const Color(0xff932e63) : plum,
      ]),
    );
    if (glow > .05) {
      // The gem powers up: four sparkle rays grow with the wind-up.
      final rays = Path();
      for (final d in const [
        Offset(0, -1),
        Offset(1, 0),
        Offset(0, 1),
        Offset(-1, 0),
      ]) {
        final from = const Offset(0, .645) + d * (.2 + glow * .05);
        final to = const Offset(0, .645) + d * (.21 + glow * .2);
        rays
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);
      }
      c.drawPath(rays, line(Color.lerp(gemColor, cream, .5)!, .045));
    }
    c.drawPath(gem, line(gold, .025));
    c.drawLine(
      const Offset(-.04, .5),
      const Offset(-.08, .62),
      line(cream.withValues(alpha: .8), .025),
    );
  }

  static void _face(
    Canvas c,
    SkyBoss boss,
    BossMotion motion,
    double look,
    bool fury,
  ) {
    final charge = motion.defeated ? 0.0 : boss.charge;
    final wince = motion.wince, blink = motion.blink;
    final eyeShift = look * .09;
    for (final side in [-1.0, 1.0]) {
      final center = Offset(side * _eyeX, _eyeY);
      final eye = Rect.fromCenter(center: center, width: .56, height: .48);
      c.drawOval(eye.inflate(.045), fill(plum));
      if (motion.defeated) {
        c.drawOval(eye, fill(cream));
        final x = center.dx;
        c.drawLine(
          Offset(x - .13, -.36),
          Offset(x + .11, -.15),
          line(ink, .07),
        );
        c.drawLine(
          Offset(x + .11, -.36),
          Offset(x - .13, -.15),
          line(ink, .07),
        );
        continue;
      }
      if (wince > .5) {
        // Squeezed shut: > < chevrons pointing at the nose.
        final x = center.dx;
        c.drawPath(
          Path()
            ..moveTo(x - side * .16, -.38)
            ..lineTo(x + side * .12, -.26)
            ..lineTo(x - side * .16, -.14),
          line(ink, .075),
        );
        continue;
      }
      c.drawOval(eye, fill(fury ? const Color(0xffffe3b8) : cream));
      final pupil = center + Offset(-.09, .03 + eyeShift);
      if (fury) {
        c.drawCircle(pupil, .135, fill(ember));
        c.drawOval(
          Rect.fromCenter(center: pupil, width: .11, height: .19),
          fill(ink),
        );
      } else {
        c.drawOval(
          Rect.fromCenter(center: pupil, width: .2, height: .27),
          fill(ink),
        );
      }
      c.drawCircle(
        pupil + const Offset(-.04, -.075),
        .045,
        fill(const Color(0xffffffff)),
      );
      // A heavy lid slants toward the nose; it drops in fury, charge and
      // blinks.
      final drop = .02 + (fury ? .07 : 0) + charge * .05 + blink * .48;
      final outer = Offset(side * .66, -.47 + drop);
      final inner = Offset(side * .07, -.33 + drop);
      final lid = Path()..moveTo(outer.dx, outer.dy);
      _quad(lid, (outer + inner) / 2 + const Offset(0, .03), inner);
      c.save();
      c.clipRRect(RRect.fromRectXY(eye, eye.width / 2, eye.height / 2));
      c.drawPath(
        Path.from(lid)
          ..lineTo(inner.dx, -.6)
          ..lineTo(outer.dx, -.6)
          ..close(),
        fill(const Color(0xff9d80c6)),
      );
      c.restore();
      c.drawPath(lid, line(ink, .06));
    }
    // Tapered brows: steeper in fury, lifted and worried in defeat.
    final tilt = motion.defeated
        ? -.16
        : (fury ? .07 : 0) + charge * .04 - wince * .05;
    for (final side in [-1.0, 1.0]) {
      final outer = Offset(side * .76, -.64 - tilt * .4);
      final inner = Offset(side * .1, -.47 + tilt);
      c.drawPath(
        Path()
          ..moveTo(outer.dx, outer.dy - .02)
          ..quadraticBezierTo(
            side * .42,
            (outer.dy + inner.dy) / 2 - .09,
            inner.dx,
            inner.dy - .07,
          )
          ..lineTo(inner.dx, inner.dy + .06)
          ..quadraticBezierTo(
            side * .44,
            (outer.dy + inner.dy) / 2 + .01,
            outer.dx,
            outer.dy + .03,
          )
          ..close(),
        fill(ink),
      );
    }
    _mouth(c, motion, charge, fury);
    if (fury) {
      // A popping anger mark on the temple away from the bird.
      final mark = Path();
      for (var turn = 0; turn < 4; turn++) {
        final a = turn * math.pi / 2 + .3;
        final cos = math.cos(a), sin = math.sin(a);
        Offset at(double x, double y) =>
            const Offset(.74, -.46) +
            Offset(x * cos - y * sin, x * sin + y * cos);
        final from = at(.04, .14), bend = at(.055, .055), to = at(.14, .04);
        mark
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);
      }
      c.drawPath(mark, line(ink, .1));
      c.drawPath(mark, line(ember, .05));
    }
  }

  static void _mouth(Canvas c, BossMotion motion, double charge, bool fury) {
    final open = motion.mouth.clamp(0.0, 1.0);
    const left = Offset(-.44, .02), right = Offset(.36, .07);
    const top = Offset(-.04, .14);
    Offset along(double t) =>
        left * ((1 - t) * (1 - t)) + top * (2 * t * (1 - t)) + right * (t * t);
    final drop = open * .3;
    final mouth = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(top.dx, top.dy, right.dx, right.dy)
      ..cubicTo(.3, .3 + drop, -.32, .36 + drop, left.dx, left.dy)
      ..close();
    c.drawPath(mouth, fill(ink));
    c.save();
    c.clipPath(mouth);
    if (charge > 0 || (fury && open > .1)) {
      final heat = math.max(charge, fury ? open * .6 : 0);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-.04, .2 + drop * .6),
          width: .5,
          height: .12 + drop,
        ),
        fill((fury ? ember : gold).withValues(alpha: .75 * heat)),
      );
    }
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-.06, .3 + drop),
        width: .22,
        height: .08 + open * .05,
      ),
      fill(_tongue),
    );
    c.restore();
    final fang = fury ? .16 : .14;
    for (final t in [.27, .72]) {
      final at = along(t);
      c.drawPath(
        Path()
          ..moveTo(at.dx - .06, at.dy - .02)
          ..lineTo(at.dx, at.dy + fang)
          ..lineTo(at.dx + .06, at.dy - .01)
          ..close(),
        fill(cream),
      );
    }
  }

  /// The crown in body coordinates, seated on the head with a jaunty tilt.
  /// It is also drawn on its own when it is knocked off in the defeat.
  static void crown(Canvas c) {
    c.save();
    c.translate(0, -.84);
    c.rotate(.09);
    c.translate(0, .84);
    final path = Path()
      ..moveTo(-.6, -.7)
      ..lineTo(-.74, -1.46)
      ..lineTo(-.33, -1.18)
      ..lineTo(0, -1.74)
      ..lineTo(.33, -1.18)
      ..lineTo(.74, -1.46)
      ..lineTo(.6, -.7)
      ..quadraticBezierTo(0, -.94, -.6, -.7)
      ..close();
    c.drawPath(path.shift(const Offset(.03, .06)), fill(ink));
    c.drawPath(
      path,
      gradient(const Rect.fromLTWH(-.75, -1.75, 1.5, 1.05), [
        cream,
        gold,
        _bronze,
      ]),
    );
    c.drawPath(path, line(ink, .055));
    // The band hugs the head's curve.
    c.drawPath(
      Path()
        ..moveTo(-.62, -.86)
        ..quadraticBezierTo(0, -1.08, .62, -.86),
      line(_bronze, .05),
    );
    c.drawPath(
      Path()
        ..moveTo(-.5, -.93)
        ..quadraticBezierTo(0, -1.12, .5, -.93),
      line(cream.withValues(alpha: .7), .025),
    );
    for (final at in const [
      Offset(-.74, -1.46),
      Offset(0, -1.74),
      Offset(.74, -1.46),
    ]) {
      c.drawCircle(at, .085, fill(ink));
      c.drawCircle(at, .06, fill(cream));
    }
    final jewel = Path()
      ..moveTo(0, -1.4)
      ..lineTo(.13, -1.24)
      ..lineTo(0, -1.06)
      ..lineTo(-.13, -1.24)
      ..close();
    c.drawPath(
      jewel,
      gradient(const Rect.fromLTWH(-.14, -1.4, .28, .36), [
        cream,
        ember,
        const Color(0xff932e63),
      ]),
    );
    c.drawPath(jewel, line(ink, .03));
    c.restore();
  }
}
