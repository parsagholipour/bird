import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'spitter_boss_motion.dart';

/// A heavy scarab acid brewer: brass-trimmed jade dome, glass boiler and a
/// battered hat.
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
  // Shared with the spitter minion so the King reads as its grand relative.
  static const _deep = Color(0xff1c4d45), _jade = Color(0xff2a9474);
  static const _leaf = Color(0xff7fd4a0), _lime = Color(0xffc3eba2);

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
    // Hits brighten every part additively, so outlines survive the flash and
    // the King never looks ghosted. Reduced Motion keeps a softer flash.
    final flash = m.defeated ? 0.0 : m.hit * (m.reducedMotion ? .2 : .34);
    if (flash > 0) {
      final lift = flash * 255;
      c.saveLayer(
        _bounds,
        Paint()
          ..colorFilter = ColorFilter.matrix([
            1, 0, 0, 0, lift, //
            0, 1, 0, 0, lift * .96,
            0, 0, 1, 0, lift * .82,
            0, 0, 0, 1, 0,
          ]),
      );
    }
    _paintBody(c, boss, m, lookY);
    if (flash > 0) c.restore();
  }

  /// Everything the rig can reach, poses and props included.
  static const _bounds = Rect.fromLTRB(-2.1, -2.2, 2.4, 1.5);

  static void _paintBody(Canvas c, SkyBoss boss, BossMotion m, double lookY) {
    final p = SpitterBossMotion(m);
    final glow = boss.enraged ? _rage : acid;
    final aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    for (final far in [true, false]) {
      for (final lower in [true, false]) {
        _wing(c, p, far: far, lower: lower);
      }
    }
    _legs(c, p, far: true);
    _pumpArm(c, p);
    _shell(c, p, glow);
    _legs(c, p, far: false);
    _tank(c, p, glow, fury: boss.enraged);
    _hose(c, p, glow);
    _head(c, p, glow, aim, fury: boss.enraged);
    if (!m.defeated || m.death < .3) {
      c.save();
      c.translate(hatAnchor.dx, hatAnchor.dy - p.hatLift);
      c.rotate(p.hatTilt);
      hat(c, glow: glow);
      c.restore();
    }
    _gestureArm(c, p);
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
        Color(far ? 0x99cfeee0 : 0xddeaf9e8),
        Color(far ? 0x8878b9a2 : 0xaa9fd6bf),
      ]),
    );
    c.drawPath(wing, _line(far ? const Color(0xff3f7a6c) : ink, .04));
    c.drawPath(
      Path()
        ..moveTo(.05, 0)
        ..quadraticBezierTo(.78, -.025, length + .06, -width * .37)
        ..moveTo(.53, -.01)
        ..lineTo(.79, -width * .92),
      _line(const Color(0xff5f9a86).withValues(alpha: .8), .028),
    );
    if (!far) {
      c.drawPath(
        Path()
          ..moveTo(.56, -width * .75)
          ..quadraticBezierTo(1.14, -width * 1.45, length, -width * .75),
        _line(const Color(0xfff4fff6).withValues(alpha: .7), .045),
      );
    }
    c.restore();
  }

  static final _shellPath = Path()
    ..moveTo(-.34, -.32)
    ..cubicTo(-.12, -.72, .77, -.57, 1.07, -.1)
    ..cubicTo(1.36, .35, .97, .91, .4, .91)
    ..cubicTo(-.16, .93, -.59, .54, -.5, .12)
    ..close();

  static void _shell(Canvas c, SpitterBossMotion p, Color glow) {
    c.save();
    c.translate(p.recoil * .035, p.breath);
    // A pale segmented belly under a dark jade dome: the minion's two-tone
    // read, scaled up and trimmed in brass.
    c.drawPath(
      _shellPath,
      _gradient(const Rect.fromLTWH(-.5, 0, 1.7, .95), const [
        _lime,
        _leaf,
        Color(0xff3f9a7c),
      ]),
    );
    c.save();
    c.clipPath(_shellPath);
    for (var i = 0; i < 3; i++) {
      final x = -.12 + i * .3;
      c.drawPath(
        Path()
          ..moveTo(x, .36 + i * .05)
          ..quadraticBezierTo(x + .1, .66, x - .02, .98),
        _line(const Color(0xff3f9a7c).withValues(alpha: .75), .055),
      );
    }
    final dome = Path()
      ..moveTo(-.7, -.8)
      ..lineTo(-.7, .12)
      ..cubicTo(-.2, .5, .75, .6, 1.4, .22)
      ..lineTo(1.4, -.8)
      ..close();
    c.drawPath(
      dome,
      _gradient(const Rect.fromLTWH(-.5, -.6, 1.7, 1.1), const [
        Color(0xff5fae8c),
        _jade,
        _deep,
      ]),
    );
    final rim = Path()
      ..moveTo(-.7, .12)
      ..cubicTo(-.2, .5, .75, .6, 1.4, .22);
    c.drawPath(rim, _line(ink, .1));
    c.drawPath(
      Path()
        ..moveTo(-.62, .06)
        ..cubicTo(-.18, .39, .72, .48, 1.34, .14),
      _line(gold, .045),
    );
    // Brass rivets along the trim make the dome read as royal armour.
    for (final t in const [.02, .38, .74]) {
      final at = Offset(-.44 + t * 1.5, .27 + math.sin(t * math.pi) * .13);
      c.drawCircle(at, .045, _fill(gold));
    }
    c.drawPath(
      Path()
        ..moveTo(-.28, -.3)
        ..quadraticBezierTo(-.1, -.5, .22, -.5),
      _line(const Color(0xffe4fbd6).withValues(alpha: .85), .085),
    );
    // Pressure vents open before a volley and stay hot throughout fury.
    for (var i = 0; i < 3; i++) {
      c.save();
      c.translate(.7 + i * .15, .14 - i * .06);
      c.rotate(-.5);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-.04, -.07, .085, .17 + p.vents * .05),
          const Radius.circular(.04),
        ),
        _fill(ink),
      );
      c.drawLine(
        const Offset(0, -.02),
        Offset(0, .03 + p.vents * .1),
        _line(glow.withValues(alpha: .2 + p.vents * .8), .04),
      );
      c.restore();
    }
    c.restore();
    c.drawPath(_shellPath, _line(ink, .08));
    c.restore();
  }

  static void _legs(Canvas c, SpitterBossMotion p, {required bool far}) {
    for (var i = 0; i < 3; i++) {
      final root = Offset(-.18 + i * .42, .74);
      final trail = p.breath * (i.isEven ? 2 : -2);
      final tuck = p.charge * .1 - p.recoil * .08 + p.collapse * .2;
      final knee = Offset(root.dx + .1 + i * .03, .98 - tuck);
      final foot = Offset(
        root.dx + .3 + trail - p.collapse * .26,
        1.08 - tuck + (i == 1 ? .05 : 0) - p.collapse * .1,
      );
      c.save();
      if (far) c.translate(-.15, -.07);
      final leg = Path()
        ..moveTo(root.dx, root.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy);
      c.drawPath(leg, _line(far ? const Color(0xff2d5f55) : ink, .15));
      if (!far) c.drawPath(leg, _line(_deep, .075));
      c.drawCircle(foot, .075, _fill(far ? const Color(0xff2d5f55) : ink));
      if (!far) c.drawCircle(foot, .035, _fill(_leaf));
      c.restore();
    }
  }

  static void _tank(
    Canvas c,
    SpitterBossMotion p,
    Color glow, {
    required bool fury,
  }) {
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
    c.drawPath(flask, _gradient(glass, [const Color(0xff4c7468), ink]));
    c.save();
    c.clipPath(flask);
    final level = -.32 - p.charge * .22 + p.recoil * .16;
    final surface = Path()
      ..moveTo(-.4, level + p.slosh)
      ..cubicTo(-.02, level - .09, .24, level + .08, .7, level - p.slosh);
    final liquid = Path.from(surface)
      ..lineTo(.7, .3)
      ..lineTo(-.4, .3)
      ..close();
    c.drawPath(liquid, _gradient(glass, [mint, glow, const Color(0xff238276)]));
    c.drawPath(surface, _line(mint, .04));
    for (var i = 0; i < 4; i++) {
      c.drawCircle(
        Offset(-.11 + i * .17, .07 - p.bubble(i) * .58),
        .03 + i % 2 * .017,
        _line(mint.withValues(alpha: .75), .02),
      );
    }
    c.restore();
    c.drawPath(flask, _line(ink, .09));
    c.drawPath(
      Path()
        ..moveTo(-.055, -.61)
        ..quadraticBezierTo(-.2, -.42, -.12, -.17),
      _line(_cream.withValues(alpha: .8), .06),
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
        const Rect.fromLTWH(-.135, -.9, .58, .13),
        const Radius.circular(.04),
      ),
      _line(ink, .04),
    );
    final lid = -1.02 - p.pump - p.pop;
    c.drawLine(Offset(.15, lid + .08), const Offset(.15, -.8), _line(ink, .07));
    c.drawLine(
      Offset(.15, lid + .08),
      const Offset(.15, -.8),
      _line(gold, .03),
    );
    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(-.115, lid, .54, .14),
      const Radius.circular(.05),
    );
    c.drawRRect(
      cap,
      _gradient(const Rect.fromLTWH(-.1, -1.02, .5, .14), [gold, _copper]),
    );
    c.drawRRect(cap, _line(ink, .04));
    const collar = Rect.fromLTWH(-.24, -.04, .8, .2);
    c.drawOval(collar.inflate(.03), _fill(ink));
    c.drawOval(collar, _gradient(collar, [_copper, _rust]));
    c.drawArc(
      const Rect.fromLTWH(-.24, -.04, .8, .2),
      0,
      math.pi,
      false,
      _line(gold, .045),
    );
    const dial = Offset(.23, -.35);
    c.drawCircle(dial, .17, _fill(ink));
    c.drawCircle(dial, .135, _fill(_cream));
    c.drawArc(
      Rect.fromCircle(center: dial, radius: .1),
      -math.pi / 2 + .5,
      .55,
      false,
      _line(const Color(0xffe0655a), .035),
    );
    final needle = -.8 + p.charge * 1.7 + p.vents * .3 - p.recoil * .6;
    c.drawLine(
      dial,
      dial + Offset(math.sin(needle), -math.cos(needle)) * .1,
      _line(_rust, .035),
    );
    c.drawCircle(dial, .028, _fill(ink));
    if ((p.vents > .1 || p.pop > 0) && !p.motion.defeated) {
      final amount = math.max(p.vents, p.pop);
      for (var i = 0; i < 3; i++) {
        final rise = p.bubble(i);
        c.drawCircle(
          Offset(.1 + i * .08 + rise * .14, lid - .05 - rise * .4),
          .03 + rise * .06,
          _fill(
            (fury ? _cream : glow).withValues(alpha: (1 - rise) * amount * .6),
          ),
        );
      }
    }
    c.restore();
  }

  static void _hose(Canvas c, SpitterBossMotion p, Color glow) {
    final hose = Path()
      ..moveTo(.62, .04)
      ..cubicTo(.55, .42, .02, .5 + p.pump * .6, -.36, .26);
    c.drawPath(hose, _line(ink, .15));
    c.drawPath(hose, _line(const Color(0xff3f6f5e), .085));
    c.drawPath(hose, _line(glow.withValues(alpha: .35 + p.charge * .65), .035));
    c.drawCircle(const Offset(-.36, .26), .1, _fill(ink));
    c.drawCircle(const Offset(-.36, .26), .062, _fill(gold));
  }

  static void _head(
    Canvas c,
    SpitterBossMotion p,
    Color glow,
    double aim, {
    required bool fury,
  }) {
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
      _gradient(const Rect.fromLTWH(-1.05, -.7, .95, 1.2), const [
        Color(0xffd3f3b8),
        Color(0xff8ad3a0),
        Color(0xff3f9c80),
      ]),
    );
    c.drawPath(head, _line(ink, .075));
    // Cheek sac: the acid store swells and brightens through the windup.
    final cheek = Rect.fromCenter(
      center: Offset(-.62, .21 + p.charge * .055),
      width: .53 + p.charge * .2 - p.recoil * .1,
      height: .31 + p.charge * .25 - p.recoil * .07,
    );
    c.drawOval(
      cheek,
      _gradient(cheek, [
        Color.lerp(mint, _cream, p.charge * .6)!,
        glow,
        fury ? const Color(0xffc9713e) : const Color(0xff3f9c80),
      ]),
    );
    c.drawOval(cheek, _line(ink, .05));
    c.drawArc(cheek.deflate(.07), 3.6, 1.35, false, _line(_cream, .045));
    // The goggle's leather strap wraps back around the head.
    c.drawPath(
      Path()
        ..moveTo(-.7, -.4)
        ..quadraticBezierTo(-.28, -.47, -.1, -.3),
      _line(ink, .2),
    );
    c.drawPath(
      Path()
        ..moveTo(-.7, -.4)
        ..quadraticBezierTo(-.28, -.47, -.1, -.3),
      _line(_hat, .13),
    );
    const eye = Rect.fromLTWH(-.995, -.62, .62, .51);
    c.drawOval(eye.inflate(.04), _fill(ink));
    c.drawOval(eye, _gradient(eye, [gold, _copper]));
    final lens = eye.deflate(.065);
    c.drawOval(
      lens,
      _gradient(lens, [
        _cream,
        fury ? const Color(0xffffd3a8) : const Color(0xffcdebc4),
      ]),
    );
    final squint = p.motion.defeated ? 0.0 : p.motion.hit;
    if (p.motion.defeated) {
      c.drawLine(
        const Offset(-.82, -.47),
        const Offset(-.58, -.25),
        _line(ink, .06),
      );
      c.drawLine(
        const Offset(-.82, -.25),
        const Offset(-.58, -.47),
        _line(ink, .06),
      );
    } else {
      final look = Offset(-.74 - aim.abs() * .015, -.35 + aim * .085);
      final size = fury ? .9 : 1.0;
      c.drawOval(
        Rect.fromCenter(center: look, width: .16 * size, height: .23 * size),
        _fill(ink),
      );
      if (fury) {
        c.drawOval(
          Rect.fromCenter(center: look, width: .07, height: .11),
          _fill(const Color(0xffe0655a)),
        );
      }
      c.drawCircle(look + const Offset(-.035, -.06), .036, _fill(_cream));
    }
    c.save();
    c.clipPath(Path()..addOval(lens));
    if (squint > 0) {
      final lid = lens.top + lens.height * (.15 + squint * .45);
      c.drawRect(
        Rect.fromLTRB(lens.left, lens.top - .1, lens.right, lid),
        _fill(const Color(0xff3f9c80)),
      );
      c.drawLine(
        Offset(lens.left, lid),
        Offset(lens.right, lid - .04),
        _line(ink, .05),
      );
    }
    c.restore();
    c.drawArc(eye.deflate(.03), 3.85, 1.6, false, _line(_cream, .035));
    if (!p.motion.defeated) {
      // Fury drops the brow into a hard scowl.
      final scowl = fury ? .1 : 0.0;
      c.drawPath(
        Path()
          ..moveTo(-1.0, -.6 + p.charge * .07 - scowl * .4)
          ..lineTo(-.56, -.51 + p.charge * .03 + scowl),
        _line(ink, .085),
      );
    }
    // A short mandible flares on recoil; the spit port stays at the muzzle.
    final jaw = Path()
      ..moveTo(-.96, .1)
      ..quadraticBezierTo(
        -1.07 - p.recoil * .08,
        .3,
        -.93,
        .42 + p.recoil * .05,
      )
      ..quadraticBezierTo(-.86, .3, -.84, .16)
      ..close();
    c.drawPath(jaw, _fill(_deep));
    c.drawPath(jaw, _line(ink, .05));
    c.drawOval(const Rect.fromLTWH(-1.16, -.15, .27, .3), _fill(ink));
    c.drawOval(
      const Rect.fromLTWH(-1.125, -.115, .2, .23),
      _gradient(const Rect.fromLTWH(-1.125, -.115, .2, .23), [gold, _copper]),
    );
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
    final elbow = Offset(1.12, .5 - p.pump + p.collapse * .15);
    final hand = Offset(
      1.24 - p.collapse * .12,
      .16 - p.pump * 1.4 + p.collapse * .43,
    );
    _arm(c, const Offset(.82, .4), elbow, hand, -.6 + p.collapse, far: true);
  }

  static void _gestureArm(Canvas c, SpitterBossMotion p) {
    final gesture = math.max(p.tip, p.summon);
    final elbow = Offset(
      -.24 - gesture * .42,
      .62 - gesture * .5 + p.collapse * .1,
    );
    final hand = Offset(
      -.58 - p.summon * .72 - p.tip * .38 + p.recoil * .12,
      .62 - p.tip * 1.34 - p.summon * 1.06 + p.beckon + p.collapse * .12,
    );
    _arm(
      c,
      const Offset(-.1, .3),
      elbow,
      hand,
      -gesture * .9 + p.beckon + p.collapse * .8 - .25,
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
    final shade = far ? const Color(0xff2d5f55) : ink;
    c.drawPath(arm, _line(shade, .15));
    if (!far) c.drawPath(arm, _line(_deep, .075));
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(turn);
    // A chunky two-fingered pincer, filled so it never reads as a ring.
    final claw = Path()
      ..moveTo(.05, -.1)
      ..quadraticBezierTo(-.2, -.2, -.3, -.04)
      ..quadraticBezierTo(-.19, -.07, -.1, -.015)
      ..quadraticBezierTo(-.19, .06, -.27, .09)
      ..quadraticBezierTo(-.16, .2, .05, .1)
      ..close();
    c.drawPath(claw, _fill(shade));
    c.drawPath(claw, _line(shade, .06));
    if (!far) {
      c.drawPath(
        Path()
          ..moveTo(-.02, -.08)
          ..quadraticBezierTo(-.15, -.13, -.22, -.06),
        _line(_leaf, .035),
      );
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
