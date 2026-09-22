import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';

/// A velvet dusk moth with a lunar diadem and a woven silken veil.
/// Authored in hit-radius units; the pollen port stays at (-1.05, 0).
abstract final class DuskMothBossRig {
  static const coral = Color(0xffefaa91), plum = Color(0xff704663);
  static const pollen = Color(0xffffc96f), silk = Color(0xffffe3ba);
  static const veil = Color(0xffbdefff), ink = Color(0xff392e4b);
  static const eyeCenter = Offset(-.87, -.34);
  // The attachment is the head's crest, not the rear edge of its fur collar.
  static const crownAnchor = Offset(-.76, -.635);
  static const crownBounds = Rect.fromLTRB(-.37, -.69, .32, .145);
  static const _rose = Color(0xffb86e82), _velvet = Color(0xff513954);
  static const _pearl = Color(0xfffff3da), _goldShadow = Color(0xffbe7f64);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint _gradient(Rect rect, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);

  static void paint(Canvas c, SkyBoss boss, BossMotion m, {double lookY = 0}) {
    final time = m.reducedMotion || m.defeated ? 0.0 : boss.age;
    final breath = math.sin(time * 3) * .022;
    final charge = BossMotion.ease(boss.charge);
    final recoil = m.reducedMotion ? 0.0 : m.recoil;
    final glow = boss.enraged ? const Color(0xffffa16d) : pollen;
    final moonlight = boss.shielded ? 1.0 : boss.shieldWarning * .6;
    final aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;

    _wingPair(c, boss, m, far: true, breath: breath, moonlight: moonlight);
    _legs(c, m, breath, far: true);
    _abdomen(c, breath);
    _wingPair(c, boss, m, far: false, breath: breath, moonlight: moonlight);
    _legs(c, m, breath, far: false);
    _mantle(c, charge, breath);
    _antennae(c, breath, recoil);
    _head(c, aim, charge, recoil, boss.enraged);
    _glands(c, charge, recoil, glow);
    if (!m.defeated || m.death < .3) {
      c.save();
      // The fitted rim shares the head's transform; lifting/tilting it alone
      // breaks contact during recoil and the arrival roar.
      c.translate(crownAnchor.dx, crownAnchor.dy);
      crown(c, moonlight: moonlight);
      c.restore();
    }
  }

  static void _abdomen(Canvas c, double breath) {
    final body = Path()
      ..moveTo(-.28, -.3)
      ..cubicTo(.37, -.48, 1.06, -.12, 1.43, .27 + breath)
      ..lineTo(1.26, .35 + breath)
      ..lineTo(1.3, .42 + breath)
      ..cubicTo(.71, .64, .13, .52, -.27, .3)
      ..close();
    c.drawPath(
      body,
      _gradient(const Rect.fromLTRB(-.3, -.4, 1.4, .6), [
        coral,
        _rose,
        _velvet,
      ]),
    );
    c.save();
    c.clipPath(body);
    for (var i = 0; i < 4; i++) {
      final x = .22 + i * .27;
      c.drawPath(
        Path()
          ..moveTo(x, -.32)
          ..quadraticBezierTo(x + .3, .07, x + .04, .61),
        _line(ink.withValues(alpha: .55), .065),
      );
      c.drawPath(
        Path()
          ..moveTo(x + .06, -.1)
          ..quadraticBezierTo(x + .2, .07, x + .17, .24),
        _line(silk.withValues(alpha: .4), .035),
      );
    }
    c.restore();
    c.drawPath(body, _line(ink, .055));
  }

  static void _wingPair(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    required bool far,
    required double breath,
    required double moonlight,
  }) {
    final still = m.reducedMotion || m.defeated;
    final beat = still
        ? .5
        : math.sin(boss.age * (boss.enraged ? 19 : 15) + (far ? 1.1 : 0));
    final fold = m.defeated ? .8 : m.folded;
    final recoil = m.reducedMotion ? 0.0 : m.recoil;
    final shelter =
        1 - (boss.shielded ? 1.0 : BossMotion.ease(boss.shieldWarning)) * .12;
    c.save();
    c.translate(far ? -.09 : -.16, far ? -.12 : -.02);
    c.rotate(far ? -.23 - beat * .04 : breath - recoil * .07);
    c.scale(shelter);
    c.scale(far ? .86 : 1.0, (1 - fold * .62) * (.88 + beat * .09));
    _wings(
      c,
      far: far,
      moonlight: moonlight,
      charge: boss.charge,
      recoil: recoil,
    );
    c.restore();
  }

  static void _wings(
    Canvas c, {
    required bool far,
    required double moonlight,
    required double charge,
    required double recoil,
  }) {
    final upper = Path()
      ..moveTo(0, -.02)
      ..cubicTo(.11, -.72, .57, -1.52, 1.49, -1.62)
      ..quadraticBezierTo(1.74, -1.63, 1.67, -1.34)
      ..quadraticBezierTo(1.9, -1.18, 1.63, -.88)
      ..quadraticBezierTo(1.79, -.61, 1.43, -.48)
      ..quadraticBezierTo(1.45, -.23, 1.12, -.25)
      ..quadraticBezierTo(.86, .04, .6, -.1)
      ..quadraticBezierTo(.25, .1, 0, -.02)
      ..close();
    final lower = Path()
      ..moveTo(.01, .04)
      ..cubicTo(.63, .05, 1.26, .35, 1.51, .74)
      ..quadraticBezierTo(1.67, 1.07, 1.34, .99)
      ..quadraticBezierTo(1.38, 1.35, 1.13, 1.1)
      ..quadraticBezierTo(1.06, 1.6, .86, 1.22)
      ..quadraticBezierTo(.56, 1.48, .47, 1.05)
      ..quadraticBezierTo(.15, .9, .01, .04)
      ..close();
    const bounds = Rect.fromLTRB(-.1, -1.65, 1.85, 1.5);
    for (final path in [lower, upper]) {
      c.drawPath(
        path,
        _gradient(bounds, far ? [plum, _rose, _velvet] : [coral, _rose, plum]),
      );
      c.save();
      c.clipPath(path);
      // A broad velvet hem and pearl scallops survive the phone-size render.
      c.drawPath(path, _line(_velvet, far ? .27 : .32));
      c.drawPath(path, _line(far ? _rose : silk, far ? .1 : .13));
      final band = Path()
        ..moveTo(1.18, -1.76)
        ..cubicTo(.65, -.77, .91, -.23, .64, .03)
        ..quadraticBezierTo(.72, .64, 1.1, 1.43);
      c.drawPath(band, _line(_velvet.withValues(alpha: .7), .13));
      c.drawPath(band, _line(coral.withValues(alpha: .75), .035));
      for (final tip in const [
        Offset(1.52, -1.49),
        Offset(1.56, -.98),
        Offset(1.4, -.58),
        Offset(1.39, .84),
        Offset(1.12, 1.17),
        Offset(.6, 1.1),
      ]) {
        c.drawPath(
          Path()
            ..moveTo(.07, -.03)
            ..quadraticBezierTo(tip.dx * .57, tip.dy * .33, tip.dx, tip.dy),
          _line(_velvet.withValues(alpha: far ? .25 : .4), .022),
        );
      }
      if (!far) {
        c.drawPath(
          Path()
            ..moveTo(.15, -.33)
            ..quadraticBezierTo(.42, -1.06, 1.27, -1.47),
          _line(_pearl.withValues(alpha: .6), .043),
        );
        // Sparse paired scales add fabric grain without a noisy dotted fill.
        for (var i = 0; i < 4; i++) {
          final at = Offset(.91 + i * .14, -1.23 + i * .2);
          c.drawLine(
            at,
            at + const Offset(.045, -.047),
            _line(silk.withValues(alpha: .6), .028),
          );
        }
      }
      c.restore();
      c.drawPath(path, _line(ink, far ? .045 : .06));
    }
    for (final lowerSpot in [false, true]) {
      final at = lowerSpot ? const Offset(.72, .62) : const Offset(.71, -.81);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(lowerSpot ? .37 : -.4);
      final scale = lowerSpot ? .82 : 1.0;
      c.scale(scale);
      final eye = Path()
        ..moveTo(-.31, 0)
        ..quadraticBezierTo(0, -.32, .34, 0)
        ..quadraticBezierTo(0, .31, -.31, 0)
        ..close();
      c.drawPath(eye, _fill(_velvet));
      c.drawPath(eye, _line(far ? coral : silk, .035));
      if (!far) {
        // A cut crescent leaves the velvet eyespot visible through its opening.
        c.drawPath(
          _crescent(Offset.zero, .185),
          _fill(Color.lerp(_pearl, veil, moonlight)!),
        );
        final gem = Offset(-.015 + recoil * .015, .014);
        c.drawCircle(
          gem,
          .06 + charge * .023,
          _fill(Color.lerp(coral, pollen, charge)!),
        );
        c.drawCircle(gem + const Offset(-.017, -.022), .02, _fill(_pearl));
      } else {
        c.drawOval(const Rect.fromLTRB(-.12, -.09, .12, .09), _fill(coral));
      }
      c.restore();
    }
  }

  static void _legs(
    Canvas c,
    BossMotion m,
    double breath, {
    required bool far,
  }) {
    for (var i = 0; i < 3; i++) {
      final x = -.4 + i * .27 + (far ? .12 : 0);
      final lift = m.defeated ? -.28 : (i == 0 ? m.summon * -.32 : 0.0);
      final root = Offset(x, .23);
      final knee = Offset(x + .09, .58 + lift);
      final foot = Offset(x - .17 + breath, .78 + lift);
      final leg = Path()
        ..moveTo(root.dx, root.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy)
        ..quadraticBezierTo(
          foot.dx - .13,
          foot.dy + .03,
          foot.dx - .13,
          foot.dy - .045,
        );
      c.drawPath(leg, _line(far ? plum : ink, far ? .042 : .061));
      if (!far) {
        c.drawLine(root, knee, _line(_rose, .029));
        c.drawCircle(knee, .035, _fill(silk));
      }
    }
  }

  static void _mantle(Canvas c, double charge, double breath) {
    final fur = Path()
      ..moveTo(-.68, -.4)
      ..quadraticBezierTo(-.53, -.66, -.37, -.62)
      ..lineTo(-.35, -.49)
      ..quadraticBezierTo(-.18, -.61, -.07, -.5)
      ..lineTo(-.09, -.37)
      ..quadraticBezierTo(.15, -.38, .17, -.21)
      ..lineTo(.09, -.15)
      ..quadraticBezierTo(.33, -.03, .27, .16)
      ..lineTo(.17, .17)
      ..quadraticBezierTo(.32, .38, .15, .48)
      ..lineTo(.04, .4)
      ..quadraticBezierTo(.01, .61 + breath, -.13, .61 + breath)
      ..lineTo(-.23, .47)
      ..quadraticBezierTo(-.37, .6 + charge * .04, -.45, .44)
      ..quadraticBezierTo(-.68, .48, -.74, .24)
      ..quadraticBezierTo(-.86, -.12, -.68, -.4)
      ..close();
    c.drawPath(
      fur,
      _gradient(const Rect.fromLTRB(-.7, -.6, .3, .65), [_pearl, silk, coral]),
    );
    c.drawPath(fur, _line(ink, .055));
    final shadow = Path()
      ..moveTo(-.54, -.32)
      ..quadraticBezierTo(-.23, -.37, -.1, -.18)
      ..lineTo(-.21, -.19)
      ..quadraticBezierTo(-.02, -.01, .06, .04)
      ..lineTo(-.05, .04)
      ..quadraticBezierTo(.12, .3, .07, .37);
    c.drawPath(shadow, _line(_goldShadow.withValues(alpha: .42), .08));
    c.drawPath(
      Path()
        ..moveTo(-.37, -.39)
        ..quadraticBezierTo(-.27, -.33, -.2, -.25)
        ..moveTo(-.2, .02)
        ..quadraticBezierTo(-.12, .11, -.1, .19)
        ..moveTo(-.33, .32)
        ..lineTo(-.23, .43),
      _line(_pearl, .045),
    );
  }

  static void _antennae(Canvas c, double breath, double recoil) {
    for (final far in [true, false]) {
      final root = far ? const Offset(-.47, -.52) : const Offset(-.78, -.55);
      final bend = far ? const Offset(-.64, -.94) : const Offset(-1.12, -.72);
      final tip = far
          ? Offset(-1.04 + recoil * .07, -1.3 - breath)
          : Offset(-1.52 + recoil * .08, -1.08 + breath);
      final stem = Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, tip.dx, tip.dy);
      c.drawPath(stem, _line(ink, .053));
      c.drawPath(stem, _line(far ? _rose : coral, .025));
      for (var i = 2; i <= 6; i++) {
        final t = i / 7;
        final at =
            root * ((1 - t) * (1 - t)) +
            bend * (2 * (1 - t) * t) +
            tip * (t * t);
        final length = .14 * math.sin(t * math.pi) + .055;
        final feathers = Path()
          ..moveTo(at.dx - length, at.dy + .035)
          ..quadraticBezierTo(at.dx - .05, at.dy + .025, at.dx, at.dy)
          ..quadraticBezierTo(
            at.dx + .025,
            at.dy - .06,
            at.dx + .015,
            at.dy - length,
          );
        c.drawPath(feathers, _line(ink, .055));
        c.drawPath(feathers, _line(far ? coral : silk, .031));
      }
    }
  }

  static void _head(
    Canvas c,
    double aim,
    double charge,
    double recoil,
    bool furious,
  ) {
    final head = Path()
      ..moveTo(-.52, -.56)
      ..cubicTo(-.85, -.76, -1.11, -.54, -1.1, -.23)
      ..quadraticBezierTo(-1.14, -.08, -1.05, .06)
      ..quadraticBezierTo(-.92, .18, -.66, .08)
      ..quadraticBezierTo(-.35, -.12, -.52, -.56)
      ..close();
    c.drawPath(
      head,
      _gradient(const Rect.fromLTRB(-1.12, -.68, -.43, .19), [
        _pearl,
        coral,
        _rose,
      ]),
    );
    c.drawPath(head, _line(ink, .055));
    c.drawPath(
      Path()
        ..moveTo(-1.04, -.49)
        ..quadraticBezierTo(-.86, -.66, -.62, -.53),
      _line(_pearl, .048),
    );
    c.drawOval(
      Rect.fromCenter(center: eyeCenter, width: .33, height: .35),
      _fill(ink),
    );
    c.drawOval(
      Rect.fromCenter(
        center: eyeCenter + const Offset(-.022, 0),
        width: .235,
        height: .265,
      ),
      _fill(_pearl),
    );
    final pupil = eyeCenter + Offset(-.064, aim * .052);
    c.drawOval(
      Rect.fromCenter(center: pupil, width: .11, height: .183),
      _fill(plum),
    );
    c.drawOval(
      Rect.fromCenter(
        center: pupil + const Offset(-.012, .005),
        width: .063,
        height: .14,
      ),
      _fill(ink),
    );
    c.drawCircle(pupil + const Offset(-.02, -.05), .032, _fill(_pearl));
    c.drawPath(
      Path()
        ..moveTo(-1.05, -.52 - (furious ? .035 : 0))
        ..quadraticBezierTo(-.89, -.49, -.7, -.46 + charge * .035)
        ..lineTo(-.65, -.52),
      _line(ink, .066),
    );
    c.drawArc(
      const Rect.fromLTRB(-.79, -.12, -.49, .05),
      .2,
      2.2,
      false,
      _line(_rose, .04),
    );
    // A curled proboscis retracts into the same fixed pollen port on windup.
    final curl = 1 - charge;
    c.drawPath(
      Path()
        ..moveTo(-1.01, .015)
        ..cubicTo(
          -1.21,
          .16 + curl * .16,
          -.87,
          .37 * curl + .06,
          -.91,
          .19 * curl + .05,
        )
        ..quadraticBezierTo(-.94, .12 * curl + .05, -1.01, .1 * curl + .01),
      _line(ink, .055),
    );
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-1.05, 0),
        width: .145,
        height: .11 + charge * .14 + recoil * .035,
      ),
      _fill(ink),
    );
  }

  static void _glands(Canvas c, double charge, double recoil, Color glow) {
    const centers = [Offset(-.65, .09), Offset(-.48, .22), Offset(-.66, .36)];
    for (var i = 0; i < centers.length; i++) {
      final at = centers[i] + Offset(recoil * .025, 0);
      final swell = ((charge - i * .12) / .76).clamp(0.0, 1.0);
      final r = .10 + swell * .037;
      if (swell > 0) {
        c.drawCircle(
          at,
          r * 2,
          Paint()
            ..shader = RadialGradient(
              colors: [
                glow.withValues(alpha: swell * .48),
                glow.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: at, radius: r * 2)),
        );
      }
      final gland = Rect.fromCenter(
        center: at,
        width: r * 1.8,
        height: r * 2.15,
      );
      c.drawOval(
        gland,
        _gradient(gland, [
          Color.lerp(coral, glow, .35 + swell * .65)!,
          _goldShadow,
        ]),
      );
      c.drawOval(gland, _line(ink, .034));
      c.drawCircle(at + const Offset(-.024, -.037), .034, _fill(_pearl));
    }
  }

  static Path _crescent(Offset at, double r) => Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: at, radius: r)),
    Path()..addOval(
      Rect.fromCircle(center: at + Offset(r * .48, -r * .24), radius: r * .84),
    ),
  );

  static void crown(Canvas c, {double moonlight = 0}) {
    // The moth faces left: the narrow forehead plate is at the left end of
    // a long side band. Its far rim/prongs sit behind the open, shaded ring.
    final farRim = Path()
      ..moveTo(-.255, -.125)
      ..lineTo(-.17, -.23)
      ..lineTo(-.105, -.38)
      ..lineTo(-.045, -.245)
      ..lineTo(.09, -.265)
      ..lineTo(.185, -.375)
      ..lineTo(.215, -.23)
      ..quadraticBezierTo(.285, -.205, .29, -.155)
      ..quadraticBezierTo(.045, -.095, -.255, -.125)
      ..close();
    c.drawPath(farRim, _gradient(crownBounds, [_goldShadow, plum]));
    c.drawPath(farRim, _line(ink, .035));
    c.drawLine(
      const Offset(-.105, -.34),
      const Offset(-.075, -.26),
      _line(coral, .02),
    );
    final opening = Path()
      ..moveTo(-.255, -.125)
      ..cubicTo(-.195, -.275, .24, -.295, .29, -.155)
      ..cubicTo(.15, -.065, -.07, -.055, -.255, -.125)
      ..close();
    c.drawPath(opening, _gradient(opening.getBounds(), [ink, plum]));
    c.drawPath(opening, _line(_goldShadow, .033));
    c.drawPath(
      Path()
        ..moveTo(-.2, -.185)
        ..cubicTo(-.095, -.255, .17, -.272, .24, -.205),
      _line(silk, .02),
    );

    // A broad near side occludes the lower halves of the far prongs. Only
    // the left forehead plate carries a jewel; this side is curved metal.
    final band = Path()
      ..moveTo(-.255, -.125)
      ..quadraticBezierTo(-.16, -.07, -.065, -.068)
      ..lineTo(.012, -.25)
      ..lineTo(.092, -.081)
      ..quadraticBezierTo(.205, -.095, .29, -.155)
      ..lineTo(.24, .095)
      // Exact first 60% of the head's upper Bezier, with .02 overlap.
      ..cubicTo(.042, -.025, -.1308, .0062, -.2352, .11732)
      ..close();
    c.drawPath(band, _gradient(band.getBounds(), [silk, pollen, _goldShadow]));
    c.drawPath(
      Path()
        ..moveTo(.29, -.155)
        ..lineTo(.24, .095)
        ..quadraticBezierTo(.165, .052, .12, .038)
        ..lineTo(.175, -.107)
        ..close(),
      _fill(_goldShadow),
    );
    c.drawPath(band, _line(ink, .04));
    c.drawPath(
      Path()
        ..moveTo(-.17, .023)
        ..cubicTo(-.065, -.037, .06, -.04, .2, .022),
      _line(_pearl, .026),
    );
    // Foreshortening belongs to the front face, not to the whole crown.
    final forehead = Path()
      ..moveTo(-.2352, .11732)
      ..lineTo(-.31, -.22)
      ..lineTo(-.288, -.36)
      ..lineTo(-.233, -.255)
      ..lineTo(-.182, -.14)
      ..lineTo(-.2, .058)
      ..close();
    c.drawPath(forehead, _gradient(forehead.getBounds(), [silk, pollen]));
    c.drawPath(forehead, _line(ink, .033));
    c.drawLine(
      const Offset(-.288, -.235),
      const Offset(-.234, .06),
      _line(_pearl, .02),
    );
    c.save();
    c.translate(-.29, -.49);
    c.scale(-.34, 1);
    c.drawPath(_crescent(const Offset(-.045, 0), .17), _fill(_goldShadow));
    c.drawPath(_crescent(Offset.zero, .17), _fill(_pearl));
    c.drawPath(_crescent(Offset.zero, .17), _line(ink, .025));
    c.restore();
    final gem = Path()
      ..moveTo(-.261, -.183)
      ..lineTo(-.218, -.096)
      ..lineTo(-.235, -.01)
      ..lineTo(-.274, -.091)
      ..close();
    c.drawPath(gem, _fill(Color.lerp(veil, _pearl, moonlight * .6)!));
    c.drawPath(gem, _line(_goldShadow, .018));
    c.drawLine(
      const Offset(-.257, -.13),
      const Offset(-.259, -.16),
      _line(_pearl, .017),
    );
  }

  /// World-space silk is woven just inside the exact projectile-blocking rim.
  static void paintShield(
    Canvas c,
    Offset center,
    double radius,
    SkyBoss boss,
    BossMotion m,
  ) {
    if (!boss.shielded && boss.shieldWarning <= 0) return;
    final active = boss.shielded;
    final warning = BossMotion.ease(boss.shieldWarning);
    final hit = BossMotion.pulse(boss.age - boss.lastShieldHitAt, .3);
    final weave = m.reducedMotion ? 0.0 : boss.age * .12;
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(radius);
    const bounds = Rect.fromLTRB(-1, -1, 1, 1);
    if (active) {
      c.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = RadialGradient(
            colors: [
              veil.withValues(alpha: 0),
              veil.withValues(alpha: .015),
              veil.withValues(alpha: .19 + hit * .1),
            ],
            stops: const [0, .68, 1],
          ).createShader(bounds),
      );
      // The uninterrupted edge always describes the actual blocked area.
      c.drawCircle(Offset.zero, 1, _line(ink.withValues(alpha: .75), .04));
      c.drawCircle(Offset.zero, 1, _line(veil, .021));
      c.drawCircle(Offset.zero, .964, _line(silk.withValues(alpha: .64), .008));
      c.drawArc(bounds, math.pi * .88, .93, false, _line(_pearl, .029));
    }
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 + weave;
      final sweep = active ? math.pi / 6 : .045 + warning * .38;
      c.drawArc(
        bounds,
        angle,
        sweep,
        false,
        _line(
          active
              ? silk.withValues(alpha: .84)
              : veil.withValues(alpha: .3 + warning * .62),
          active ? .009 : .014,
        ),
      );
      // Crossing thread loops make a scalloped silk hem, keeping the face clear.
      if (active || warning > .35) {
        final start = _polar(angle, .975);
        final end = _polar(angle + sweep, .975);
        final loop = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(
            _polar(angle + sweep / 2, .77).dx,
            _polar(angle + sweep / 2, .77).dy,
            end.dx,
            end.dy,
          );
        c.drawPath(
          loop,
          _line(veil.withValues(alpha: active ? .52 : warning * .5), .009),
        );
        if (active) {
          final cross = Path()
            ..moveTo(_polar(angle + .12, .91).dx, _polar(angle + .12, .91).dy)
            ..quadraticBezierTo(
              _polar(angle + .33, .985).dx,
              _polar(angle + .33, .985).dy,
              _polar(angle + .64, .91).dx,
              _polar(angle + .64, .91).dy,
            );
          c.drawPath(cross, _line(silk.withValues(alpha: .42), .006));
        }
      }
      final at = _polar(angle, active ? .98 : 1);
      c.drawCircle(
        at,
        active ? .015 : .011 + warning * .005,
        _fill(active ? _pearl : veil.withValues(alpha: .5 + warning * .5)),
      );
    }
    // Fixed crescent clasps connect the lunar eyespots to the woven perimeter.
    for (final angle in const [-math.pi / 2, math.pi / 6, math.pi * 5 / 6]) {
      final at = _polar(angle, .935);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(angle + math.pi / 2);
      if (active) {
        c.drawCircle(Offset.zero, .078, _fill(_velvet.withValues(alpha: .84)));
        c.drawCircle(Offset.zero, .078, _line(veil, .012));
        c.drawPath(_crescent(Offset.zero, .046), _fill(_pearl));
      } else {
        c.drawPath(
          _crescent(Offset.zero, .035 + warning * .011),
          _fill(veil.withValues(alpha: .3 + warning * .55)),
        );
      }
      c.restore();
    }
    if (active && hit > 0) {
      c.drawArc(
        bounds,
        math.pi - .4,
        .8,
        false,
        _line(_pearl.withValues(alpha: hit), .055),
      );
      // A caught-shot rosette and short ripples stay at the incoming-shot edge.
      final spread = m.reducedMotion
          ? .5
          : BossMotion.ramp(boss.age - boss.lastShieldHitAt, 0, .3);
      for (var i = 0; i < 2; i++) {
        c.drawArc(
          Rect.fromCircle(
            center: const Offset(-1, 0),
            radius: .075 + i * .07 + spread * .09,
          ),
          -.9,
          1.8,
          false,
          _line(veil.withValues(alpha: hit * (1 - i * .25)), .014),
        );
      }
      final star = Path()
        ..moveTo(-1, -.085)
        ..quadraticBezierTo(-.984, -.015, -.925, 0)
        ..quadraticBezierTo(-.984, .015, -1, .085)
        ..quadraticBezierTo(-1.016, .015, -1.075, 0)
        ..quadraticBezierTo(-1.016, -.015, -1, -.085)
        ..close();
      c.drawPath(star, _fill(_pearl.withValues(alpha: hit)));
    }
    c.restore();
  }

  static Offset _polar(double angle, double radius) =>
      Offset(math.cos(angle), math.sin(angle)) * radius;
}
