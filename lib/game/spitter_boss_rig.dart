import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'spitter_boss_motion.dart';

/// A heavy scarab acid brewer: copper shell, glass boiler and a battered hat.
/// Authored in hit-radius units, with the mouth fixed at (-1.05, 0).
abstract final class SpitterBossRig {
  static const acid = Color(0xff6fe3a4), mint = Color(0xffd4ffc1);
  static const ink = Color(0xff223437), gold = Color(0xffffd878);
  static const hatAnchor = Offset(-.58, -.72);
  static const hatBounds = Rect.fromLTWH(-.94, -1, 1.82, 1.29);
  static const eyeCenter = Offset(-.69, -.36);
  static const _copper = Color(0xffc57a47), _rust = Color(0xff714833);
  static const _cream = Color(0xffffefcb), _hat = Color(0xff654f5d);
  static const _rage = Color(0xffffb65f);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  static Paint _gradient(Rect rect, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);

  static void paint(Canvas c, SkyBoss boss, BossMotion m, {double lookY = 0}) {
    final p = SpitterBossMotion(m);
    final glow = boss.enraged ? _rage : acid;
    final aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    for (final far in [true, false]) {
      for (final lower in [true, false]) {
        _wing(c, p, far: far, lower: lower);
      }
    }
    _legs(c, p, far: true);
    _shell(c, p, glow);
    _legs(c, p, far: false);
    _pumpArm(c, p);
    _tank(c, p, glow);
    _hose(c, p, glow);
    _head(c, p, glow, aim);
    if (!m.defeated || m.death < .3) {
      c.save();
      c.translate(hatAnchor.dx, hatAnchor.dy - p.hatLift);
      c.rotate(p.hatTilt);
      hat(c, glow: glow);
      c.restore();
    }
    _gestureArm(c, p);
    if (m.hit > 0 && !m.reducedMotion) {
      c.drawArc(
        const Rect.fromLTWH(-.42, -.23, 1.35, 1.03),
        .1,
        2.4,
        false,
        _line(_cream.withValues(alpha: m.hit * .8), .085),
      );
    }
  }

  static void _wing(
    Canvas c,
    SpitterBossMotion p, {
    required bool far,
    required bool lower,
  }) {
    final stroke = p.wingStroke(far: far, lower: lower);
    c.save();
    c.translate(far ? .25 : .48, -.25);
    c.rotate((lower ? .15 : -.5) + stroke * (lower ? .18 : .29) + p.fold * .82);
    c.scale((far ? .9 : 1) * (1 - p.fold * .61), 1 - p.fold * .3);
    final width = .17 + (1 - stroke * stroke) * .16;
    final length = lower ? 1.22 : 1.48;
    final wing = Path()
      ..moveTo(0, 0)
      ..cubicTo(.3, -.11, length - .3, -width * 1.7, length, -width)
      ..cubicTo(length + .36, .04, length - .02, width, .66, width * .55)
      ..quadraticBezierTo(.15, .13, 0, 0)
      ..close();
    c.drawPath(
      wing,
      _gradient(Rect.fromLTWH(0, -width * 2, length, width * 3), [
        Color(far ? 0xbba1cbbb : 0xeef5e9c7),
        const Color(0xbb86c8b1),
      ]),
    );
    c.drawPath(wing, _line(far ? const Color(0xff4e7f76) : ink, .035));
    c.drawPath(
      Path()
        ..moveTo(.05, 0)
        ..quadraticBezierTo(.78, -.025, length + .06, -width * .37)
        ..moveTo(.53, -.01)
        ..lineTo(.79, -width * .92)
        ..moveTo(.88, -.045)
        ..lineTo(1.1, width * .33),
      _line(const Color(0xff689b89), .025),
    );
    c.drawPath(
      Path()
        ..moveTo(.56, -width * .75)
        ..quadraticBezierTo(1.14, -width * 1.45, length, -width * .75),
      _line(_cream.withValues(alpha: .65), .04),
    );
    c.restore();
  }

  static void _shell(Canvas c, SpitterBossMotion p, Color glow) {
    c.save();
    c.translate(p.recoil * .035, p.breath);
    final shell = Path()
      ..moveTo(-.34, -.32)
      ..cubicTo(-.12, -.72, .77, -.57, 1.07, -.1)
      ..cubicTo(1.36, .35, .97, .91, .4, .91)
      ..cubicTo(-.16, .93, -.59, .54, -.5, .12)
      ..close();
    c.drawPath(
      shell,
      _gradient(const Rect.fromLTWH(-.5, -.55, 1.7, 1.45), [
        const Color(0xfff7c487),
        _copper,
        _rust,
      ]),
    );
    c.drawPath(shell, _line(ink, .075));
    // Broad overlapping belly plates replace the little beetle's raised elytra.
    for (var i = 0; i < 3; i++) {
      final y = .32 + i * .18;
      c.drawPath(
        Path()
          ..moveTo(-.29 + i * .04, y)
          ..quadraticBezierTo(.37, y + .33, 1.03 - i * .11, y - .035),
        _line(ink.withValues(alpha: .76), .048),
      );
      c.drawPath(
        Path()
          ..moveTo(-.21 + i * .07, y + .065)
          ..quadraticBezierTo(.2, y + .245, .59, y + .17),
        _line(const Color(0xffebad75), .035),
      );
    }
    // Pressure vents open before a volley and stay hot throughout fury.
    for (var i = 0; i < 3; i++) {
      c.save();
      c.translate(.68 + i * .13, .12 - i * .035);
      c.rotate(-.37);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-.035, -.08, .08, .19 + p.vents * .055),
          const Radius.circular(.035),
        ),
        _fill(ink),
      );
      c.drawLine(
        const Offset(0, -.025),
        Offset(0, .035 + p.vents * .11),
        _line(glow.withValues(alpha: .25 + p.vents * .75), .035),
      );
      c.restore();
    }
    // Leather harness visibly carries the boiler's weight.
    final strap = Path()
      ..moveTo(.15, -.35)
      ..quadraticBezierTo(.06, .43, .42, .83);
    c.drawPath(strap, _line(ink, .15));
    c.drawPath(strap, _line(_hat, .105));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(.13, .39, .24, .23),
        const Radius.circular(.04),
      ),
      _line(gold, .045),
    );
    c.drawLine(
      const Offset(.23, .41),
      const Offset(.28, .59),
      _line(gold, .03),
    );
    c.restore();
  }

  static void _legs(Canvas c, SpitterBossMotion p, {required bool far}) {
    for (var i = 0; i < 3; i++) {
      final root = Offset(-.25 + i * .43, .56);
      final trail = p.breath * (i.isEven ? 2 : -2);
      final tuck = p.charge * .12 - p.recoil * .09 + p.collapse * .2;
      final knee = Offset(root.dx + .02 + i * .04, .9 - tuck);
      final foot = Offset(
        root.dx + .23 + trail - p.collapse * .24,
        1.02 - tuck + (i == 1 ? .08 : 0),
      );
      c.save();
      if (far) c.translate(-.13, -.05);
      final leg = Path()
        ..moveTo(root.dx, root.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy)
        ..lineTo(foot.dx + .08, foot.dy - .08 - p.collapse * .07);
      c.drawPath(leg, _line(ink, far ? .09 : .105));
      if (!far) {
        c.drawLine(root, knee, _line(_copper, .053));
        c.drawCircle(knee, .055, _fill(gold));
      }
      c.restore();
    }
  }

  static void _tank(Canvas c, SpitterBossMotion p, Color glow) {
    c.save();
    c.translate(.58, -.14);
    c.rotate(p.tankRock);
    const glass = Rect.fromLTWH(-.25, -.92, .82, 1.05);
    final flask = Path()
      ..moveTo(-.06, -.92)
      ..lineTo(-.06, -.72)
      ..cubicTo(-.52, -.52, -.25, .17, .15, .15)
      ..cubicTo(.62, .17, .78, -.5, .36, -.72)
      ..lineTo(.36, -.92)
      ..close();
    c.drawPath(flask, _gradient(glass, [const Color(0xff527c6e), ink]));
    c.save();
    c.clipPath(flask);
    final level = -.32 - p.charge * .2 + p.recoil * .16;
    final liquid = Path()
      ..moveTo(-.4, level + p.slosh)
      ..cubicTo(-.02, level - .09, .24, level + .08, .7, level - p.slosh)
      ..lineTo(.7, .3)
      ..lineTo(-.4, .3)
      ..close();
    c.drawPath(liquid, _gradient(glass, [mint, glow, const Color(0xff238276)]));
    c.drawPath(
      Path()
        ..moveTo(-.4, level + p.slosh)
        ..cubicTo(-.02, level - .09, .24, level + .08, .7, level - p.slosh),
      _line(mint, .035),
    );
    for (var i = 0; i < 4; i++) {
      c.drawCircle(
        Offset(-.11 + i * .17, .07 - p.bubble(i) * .58),
        .03 + i % 2 * .017,
        _line(mint.withValues(alpha: .7), .018),
      );
    }
    c.restore();
    c.drawPath(flask, _line(ink, .07));
    c.drawPath(
      Path()
        ..moveTo(-.055, -.61)
        ..quadraticBezierTo(-.2, -.42, -.12, -.17)
        ..moveTo(-.095, -.065)
        ..lineTo(-.07, -.025),
      _line(_cream.withValues(alpha: .78), .06),
    );
    // Rim, spring-mounted lid and pressure dial tell the attack story.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-.135, -.9, .58, .13),
        const Radius.circular(.04),
      ),
      _fill(_copper),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-.115, -1.02 - p.pump, .54, .14),
        const Radius.circular(.045),
      ),
      _gradient(const Rect.fromLTWH(-.1, -1.02, .5, .14), [gold, _copper]),
    );
    c.drawLine(
      Offset(.15, -.91 - p.pump),
      const Offset(.15, -.8),
      _line(ink, .065),
    );
    c.drawOval(const Rect.fromLTWH(-.24, -.04, .8, .2), _fill(_rust));
    c.drawArc(
      const Rect.fromLTWH(-.24, -.04, .8, .2),
      0,
      math.pi,
      false,
      _line(gold, .04),
    );
    const dial = Offset(.23, -.35);
    c.drawCircle(dial, .17, _fill(ink));
    c.drawCircle(dial, .135, _fill(_cream));
    final needle = -.8 + p.charge * 1.7 + p.vents * .3 - p.recoil * .6;
    c.drawLine(
      dial,
      dial + Offset(math.sin(needle), -math.cos(needle)) * .10,
      _line(_rust, .032),
    );
    c.drawCircle(dial, .026, _fill(ink));
    if (p.vents > .1 && !p.motion.defeated) {
      for (var i = 0; i < 3; i++) {
        final rise = p.bubble(i);
        c.drawCircle(
          Offset(.1 + i * .07 + rise * .12, -1.05 - p.pump - rise * .36),
          .025 + rise * .055,
          _fill(glow.withValues(alpha: (1 - rise) * p.vents * .55)),
        );
      }
    }
    c.restore();
  }

  static void _hose(Canvas c, SpitterBossMotion p, Color glow) {
    final hose = Path()
      ..moveTo(.77, -.02)
      ..cubicTo(.92, .41, .07, .48 + p.pump, -.36, .24);
    c.drawPath(hose, _line(ink, .145));
    c.drawPath(hose, _line(const Color(0xff436958), .085));
    c.drawPath(hose, _line(glow.withValues(alpha: .4 + p.charge * .6), .035));
    c.drawCircle(const Offset(-.36, .24), .11, _fill(_rust));
    c.drawCircle(const Offset(-.36, .24), .072, _fill(gold));
  }

  static void _head(Canvas c, SpitterBossMotion p, Color glow, double aim) {
    final head = Path()
      ..moveTo(-1.02, -.09)
      ..cubicTo(-1.1, -.38, -.91, -.7, -.57, -.67)
      ..cubicTo(-.13, -.73, .0, -.34, -.14, .15)
      ..quadraticBezierTo(
        -.18,
        .53 + p.charge * .14,
        -.66,
        .38 + p.charge * .13,
      )
      ..quadraticBezierTo(-.92, .29, -1.02, .09)
      ..close();
    c.drawPath(
      head,
      _gradient(const Rect.fromLTWH(-1.05, -.7, .95, 1.2), [
        const Color(0xffa1bf86),
        const Color(0xff638b68),
        const Color(0xff38584c),
      ]),
    );
    c.drawPath(head, _line(ink, .07));
    final cheek = Rect.fromCenter(
      center: Offset(-.62, .21 + p.charge * .055),
      width: .53 + p.charge * .18 - p.recoil * .1,
      height: .31 + p.charge * .23 - p.recoil * .07,
    );
    c.drawOval(cheek, _gradient(cheek, [mint, glow, const Color(0xff498b66)]));
    c.drawOval(cheek, _line(ink, .04));
    c.drawArc(cheek.deflate(.07), 3.6, 1.35, false, _line(_cream, .04));
    // The goggle's broad leather strap continues around the back of the head.
    c.drawPath(
      Path()
        ..moveTo(-.79, -.38)
        ..quadraticBezierTo(-.28, -.46, -.125, -.32),
      _line(_hat, .17),
    );
    c.drawOval(const Rect.fromLTWH(-1.025, -.46, .15, .25), _fill(_rust));
    const eye = Rect.fromLTWH(-.995, -.62, .62, .51);
    c.drawOval(eye.inflate(.035), _fill(ink));
    c.drawOval(eye, _gradient(eye, [gold, _copper]));
    c.drawOval(
      eye.deflate(.065),
      _gradient(eye, [_cream, const Color(0xffb9dcba)]),
    );
    if (p.motion.defeated) {
      c.drawLine(
        const Offset(-.84, -.45),
        const Offset(-.61, -.25),
        _line(ink, .055),
      );
      c.drawLine(
        const Offset(-.83, -.25),
        const Offset(-.62, -.45),
        _line(ink, .055),
      );
    } else {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-.77, -.35 + aim * .065),
          width: .13,
          height: .21,
        ),
        _fill(ink),
      );
      c.drawCircle(Offset(-.795, -.395 + aim * .065), .032, _fill(_cream));
      c.drawPath(
        Path()
          ..moveTo(-.96, -.545 + p.charge * .08)
          ..lineTo(-.59, -.495 + p.charge * .025),
        _line(ink, .065),
      );
    }
    c.drawArc(eye.deflate(.025), 3.85, 1.6, false, _line(_cream, .032));
    // Curled mandibles flare on recoil; the spit port stays at the muzzle origin.
    final jaw = Path()
      ..moveTo(-.93, .12)
      ..quadraticBezierTo(
        -1.08 - p.recoil * .09,
        .36,
        -.9,
        .46 + p.recoil * .06,
      )
      ..quadraticBezierTo(-.73, .41, -.79, .32);
    c.drawPath(jaw, _line(ink, .11));
    c.drawPath(jaw, _line(_copper, .067));
    c.drawOval(const Rect.fromLTWH(-1.15, -.14, .25, .28), _fill(ink));
    c.drawOval(const Rect.fromLTWH(-1.125, -.115, .20, .23), _fill(_copper));
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-1.05, 0),
        width: .12,
        height: .135 + p.charge * .055 + p.recoil * .075,
      ),
      _fill(ink),
    );
    if (p.charge > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(-1.05, 0),
          width: .065,
          height: .085 + p.charge * .025,
        ),
        _fill(glow.withValues(alpha: p.charge)),
      );
    }
  }

  static void _pumpArm(Canvas c, SpitterBossMotion p) {
    final elbow = Offset(1.04, .52 - p.pump + p.collapse * .15);
    final hand = Offset(
      1.19 - p.collapse * .12,
      .18 - p.pump + p.collapse * .43,
    );
    _arm(c, const Offset(.72, .42), elbow, hand, -.6 + p.collapse, far: true);
  }

  static void _gestureArm(Canvas c, SpitterBossMotion p) {
    final gesture = math.max(p.tip, p.summon);
    final elbow = Offset(
      -.31 - gesture * .38,
      .55 - gesture * .47 + p.collapse * .1,
    );
    final hand = Offset(
      -.64 - p.summon * .68 - p.tip * .33 + p.recoil * .12,
      .48 - p.tip * 1.22 - p.summon * .96 + p.beckon + p.collapse * .17,
    );
    _arm(
      c,
      const Offset(-.11, .18),
      elbow,
      hand,
      -gesture * .65 + p.beckon + p.collapse * .8,
    );
  }

  static void _arm(
    Canvas c,
    Offset root,
    Offset elbow,
    Offset hand,
    double turn, {
    bool far = false,
  }) {
    final arm = Path()
      ..moveTo(root.dx, root.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(hand.dx, hand.dy);
    c.drawPath(arm, _line(ink, .15));
    c.drawPath(arm, _line(far ? _rust : _copper, .092));
    c.drawCircle(root, .115, _fill(ink));
    c.drawCircle(root, .075, _fill(far ? _rust : gold));
    c.drawCircle(elbow, .081, _fill(ink));
    c.drawCircle(elbow, .04, _fill(gold));
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(turn);
    c.drawOval(const Rect.fromLTWH(-.15, -.09, .23, .19), _fill(ink));
    for (final side in [-1.0, 1.0]) {
      final claw = Path()
        ..moveTo(-.085, side * .045)
        ..quadraticBezierTo(-.24, side * .2, -.32, side * .06);
      c.drawPath(claw, _line(ink, .085));
      c.drawPath(claw, _line(far ? _copper : gold, .043));
    }
    c.restore();
  }

  /// Detached hat also appears in the defeat choreography. Origin: brim center.
  static void hat(Canvas c, {Color glow = acid}) {
    final top = Path()
      ..moveTo(-.46, -.03)
      ..lineTo(-.38, -.56)
      ..quadraticBezierTo(-.34, -.85, -.03, -.83)
      ..quadraticBezierTo(.17, -.81, .29, -.92)
      ..quadraticBezierTo(.35, -.67, .16, -.55)
      ..lineTo(.39, -.04)
      ..close();
    c.drawPath(
      top,
      _gradient(const Rect.fromLTWH(-.45, -.92, .88, .94), [
        const Color(0xffa18480),
        _hat,
        const Color(0xff473b49),
      ]),
    );
    c.drawPath(top, _line(ink, .06));
    c.drawPath(
      Path()
        ..moveTo(-.31, -.19)
        ..quadraticBezierTo(.03, -.3, .28, -.21),
      _line(const Color(0xffbd7555), .18),
    );
    c.drawPath(
      Path()
        ..moveTo(-.34, -.13)
        ..quadraticBezierTo(.04, -.2, .33, -.14),
      _line(_rust, .035),
    );
    final brim = Path()
      ..moveTo(-.46, -.10)
      ..cubicTo(-.82, -.17, -.96, -.04, -.73, .12)
      ..cubicTo(-.31, .27, .17, .09, .47, .10)
      ..quadraticBezierTo(.76, .09, .78, -.12)
      ..quadraticBezierTo(.5, -.005, .29, -.09)
      ..quadraticBezierTo(-.08, -.15, -.46, -.10)
      ..close();
    c.drawPath(
      brim,
      _gradient(const Rect.fromLTWH(-.85, -.13, 1.65, .38), [
        const Color(0xffb19788),
        _hat,
        const Color(0xff3d3945),
      ]),
    );
    c.drawPath(brim, _line(ink, .06));
    c.drawPath(
      Path()
        ..moveTo(-.78, .035)
        ..quadraticBezierTo(-.41, .16, -.07, .075),
      _line(const Color(0xffd5b293), .045),
    );
    // Patched fabric and a reagent vial give the hat an eccentric silhouette.
    c.drawPath(
      Path()
        ..moveTo(-.28, -.60)
        ..lineTo(-.1, -.67)
        ..lineTo(-.035, -.49)
        ..lineTo(-.24, -.43)
        ..close(),
      _fill(const Color(0xffb18e7b)),
    );
    for (var i = 0; i < 3; i++) {
      final y = -.59 + i * .065;
      c.drawLine(Offset(-.29, y), Offset(-.225, y + .025), _line(ink, .021));
    }
    c.save();
    c.translate(.19, -.29);
    c.rotate(-.25);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-.045, -.15, .11, .28),
        const Radius.circular(.045),
      ),
      _fill(ink),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-.022, -.045, .065, .15),
        const Radius.circular(.023),
      ),
      _fill(glow),
    );
    c.drawLine(
      const Offset(-.02, -.15),
      const Offset(.04, -.15),
      _line(gold, .065),
    );
    c.restore();
  }
}
