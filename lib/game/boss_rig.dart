import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'sky_scenery.dart';

/// Authored layers pivot independently; coordinates use the combat hit radius.
abstract final class BossRig {
  static const ink = Color(0xff18182f), plum = Color(0xff514278);
  static const violet = Color(0xffaa89d3), gold = Color(0xffffd878);
  static const cream = Color(0xfffff2c9), ember = Color(0xffff775c);
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

  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion motion, {
    double lookY = 0,
    bool adorned = true,
  }) {
    final eyeY = lookY.isFinite ? lookY.clamp(-1.0, 1.0) * .09 : 0.0;
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.scale(side, 1);
      c.translate(.68, -.06);
      c.rotate(motion.wingBeat + motion.folded * .7);
      c.scale(1 - motion.folded * .7, 1 + motion.folded * .16);
      _wing(c, boss.enraged, adorned: adorned);
      c.restore();
    }
    // Velvet collar and a split cape trail behind the heavier chest.
    if (adorned) {
      final cape = Path()
        ..moveTo(-.76, -.1)
        ..lineTo(-.95, .89)
        ..lineTo(-.48, .67)
        ..lineTo(-.35, 1.25)
        ..lineTo(0, .98)
        ..lineTo(.35, 1.25)
        ..lineTo(.48, .67)
        ..lineTo(.95, .89)
        ..lineTo(.76, -.1)
        ..close();
      c.drawPath(
        cape,
        gradient(const Rect.fromLTWH(-1, -.2, 2, 1.5), [
          const Color(0xff9b486c),
          const Color(0xff382744),
        ]),
      );
      c.drawPath(cape, line(ink));
    }
    for (final side in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(side * .58, -.5)
        ..lineTo(side * .88, -1.24)
        ..quadraticBezierTo(side * .36, -.95, side * .21, -.54)
        ..close();
      c.drawPath(ear, fill(plum));
      c.drawPath(ear, line(ink));
      c.drawLine(
        Offset(side * .58, -.68),
        Offset(side * .75, -1.05),
        line(violet, .075),
      );
    }
    const body = Rect.fromLTWH(-.91, -.81, 1.82, 1.7);
    c.drawOval(body.shift(const Offset(.035, .08)), fill(ink));
    c.drawOval(body, gradient(body, [const Color(0xffd6b6eb), violet, plum]));
    c.drawOval(body, line(ink, .055));
    c.drawArc(
      body.deflate(.07),
      -2.85,
      1.7,
      false,
      line(cream.withValues(alpha: .65), .025),
    );
    // Breastplate, engraved rim and a faceted power gem.
    if (adorned) {
      final armor = Path()
        ..moveTo(-.7, .2)
        ..quadraticBezierTo(0, .05, .7, .2)
        ..quadraticBezierTo(.64, .85, 0, .97)
        ..quadraticBezierTo(-.64, .85, -.7, .2)
        ..close();
      c.drawPath(
        armor,
        gradient(const Rect.fromLTWH(-.7, .15, 1.4, .8), [
          const Color(0xff7c799d),
          const Color(0xff292b4b),
        ]),
      );
      c.drawPath(armor, line(gold, .052));
      c.drawPath(
        Path()
          ..moveTo(-.53, .35)
          ..quadraticBezierTo(-.35, .65, -.11, .73)
          ..moveTo(.53, .35)
          ..quadraticBezierTo(.35, .65, .11, .73),
        line(gold.withValues(alpha: .5), .023),
      );
      final gemColor = boss.enraged ? ember : const Color(0xff98f0dc);
      c.drawPath(SkyScenery.star(const Offset(0, .48), .27), fill(ink));
      final gem = Path()
        ..moveTo(0, .25)
        ..lineTo(.17, .46)
        ..lineTo(0, .71)
        ..lineTo(-.17, .46)
        ..close();
      c.drawPath(
        gem,
        gradient(const Rect.fromLTWH(-.2, .25, .4, .5), [
          cream,
          gemColor,
          plum,
        ]),
      );
      c.drawPath(gem, line(gold, .025));
      c.drawLine(
        const Offset(0, .28),
        const Offset(0, .66),
        line(cream.withValues(alpha: .6), .02),
      );
    } else {
      c.drawOval(
        const Rect.fromLTWH(-.43, .28, .86, .48),
        fill(const Color(0xffc0a3df)),
      );
    }
    // Eyes sit beneath a substantial brow; pupils track toward the player.
    for (final x in [-.36, .36]) {
      final eye = Rect.fromCenter(
        center: Offset(x, -.25),
        width: .56,
        height: .48,
      );
      c.drawOval(eye.inflate(.04), fill(plum));
      c.drawOval(eye, fill(cream));
      if (motion.defeated) {
        c.drawLine(Offset(x - .13, -.34), Offset(x + .1, -.17), line(ink, .07));
        c.drawLine(Offset(x + .1, -.34), Offset(x - .13, -.17), line(ink, .07));
      } else {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x - .09, -.23 + eyeY),
            width: .19,
            height: .28,
          ),
          fill(ink),
        );
        c.drawCircle(
          Offset(x - .12, -.31 + eyeY),
          .045,
          fill(const Color(0xffffffff)),
        );
      }
    }
    c.drawPath(
      Path()
        ..moveTo(-.7, -.59)
        ..quadraticBezierTo(-.38, -.49, -.08, -.42)
        ..moveTo(.7, -.59)
        ..quadraticBezierTo(.38, -.49, .08, -.42),
      line(ink, .105),
    );
    c.drawPath(
      Path()
        ..moveTo(-.63, -.65)
        ..lineTo(-.18, -.52)
        ..moveTo(.63, -.65)
        ..lineTo(.18, -.52),
      line(cream.withValues(alpha: .45), .025),
    );
    final mouth = Rect.fromCenter(
      center: const Offset(-.03, .075),
      width: .54 + motion.mouth * .13,
      height: .18 + motion.mouth * .22,
    );
    c.drawOval(mouth, fill(ink));
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-.03, mouth.bottom - .035),
        width: .2,
        height: .075,
      ),
      fill(const Color(0xffcc6884)),
    );
    for (final x in [-.19, .15]) {
      c.drawPath(
        Path()
          ..moveTo(x - .065, mouth.top)
          ..lineTo(x, mouth.top + .17)
          ..lineTo(x + .065, mouth.top)
          ..close(),
        fill(cream),
      );
    }
    // Segmented shoulder guards bridge the cape and wings.
    if (adorned) {
      for (final side in [-1.0, 1.0]) {
        c.save();
        c.scale(side, 1);
        c.drawOval(
          const Rect.fromLTWH(.66, -.02, .36, .25),
          gradient(const Rect.fromLTWH(.66, -.02, .36, .25), [
            cream,
            gold,
            const Color(0xffac7138),
          ]),
        );
        c.drawOval(const Rect.fromLTWH(.66, -.02, .36, .25), line(ink, .035));
        c.drawCircle(const Offset(.82, .08), .05, fill(cream));
        c.restore();
      }
    }
    if (adorned && motion.death < .3) {
      c.save();
      c.translate(0, -motion.crownLift);
      c.rotate(-motion.rotation * .55);
      crown(c);
      c.restore();
    }
    if (adorned && boss.enraged && !motion.defeated) {
      c.drawPath(
        Path()
          ..moveTo(-.52, .27)
          ..lineTo(-.42, .42)
          ..lineTo(-.5, .53)
          ..moveTo(.46, .36)
          ..lineTo(.35, .48)
          ..lineTo(.42, .64),
        line(ember, .033),
      );
    }
    if (motion.hit > 0 && !motion.reducedMotion) {
      c.drawOval(body, fill(cream.withValues(alpha: motion.hit * .28)));
    }
  }

  static void _wing(Canvas c, bool enraged, {required bool adorned}) {
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(.35, -.86, 1.15, -1.26, 1.72, -.76)
      ..quadraticBezierTo(1.24, -.55, 1.6, -.02)
      ..quadraticBezierTo(1.12, -.3, 1.02, .46)
      ..quadraticBezierTo(.64, .08, .48, .7)
      ..quadraticBezierTo(.24, .3, 0, .35)
      ..close();
    c.drawPath(path.shift(const Offset(.025, .065)), fill(ink));
    c.drawPath(
      path,
      gradient(const Rect.fromLTWH(0, -1, 1.8, 1.8), [
        enraged ? const Color(0xffd78cac) : const Color(0xffb69adf),
        plum,
        const Color(0xff30243f),
      ]),
    );
    c.drawPath(path, line(ink, .06));
    c.drawPath(
      Path()
        ..moveTo(0, .06)
        ..quadraticBezierTo(.6, -.83, 1.72, -.76),
      line((adorned ? gold : violet).withValues(alpha: .9), .042),
    );
    for (final tip in [
      const Offset(1.6, -.02),
      const Offset(1.02, .46),
      const Offset(.48, .7),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(.1, .06)
          ..quadraticBezierTo(tip.dx * .72, -.36, tip.dx, tip.dy),
        line(violet, .03),
      );
    }
    for (var i = 0; adorned && i < 3; i++) {
      final x = .55 + i * .3;
      c.drawPath(
        SkyScenery.star(Offset(x, -.43 - math.sin(i.toDouble()) * .08), .055),
        fill(gold.withValues(alpha: .55)),
      );
    }
  }

  static void crown(Canvas c) {
    final path = Path()
      ..moveTo(-.59, -.84)
      ..lineTo(-.73, -1.52)
      ..lineTo(-.3, -1.26)
      ..lineTo(0, -1.79)
      ..lineTo(.3, -1.26)
      ..lineTo(.73, -1.52)
      ..lineTo(.59, -.84)
      ..close();
    c.drawPath(path.shift(const Offset(.025, .055)), fill(ink));
    c.drawPath(
      path,
      gradient(const Rect.fromLTWH(-.75, -1.8, 1.5, 1), [
        cream,
        gold,
        const Color(0xffb97a3d),
      ]),
    );
    c.drawPath(path, line(ink, .055));
    c.drawLine(
      const Offset(-.53, -.94),
      const Offset(.53, -.94),
      line(cream, .035),
    );
    for (final x in [-.68, 0.0, .68]) {
      c.drawCircle(Offset(x, x == 0 ? -1.78 : -1.51), .07, fill(cream));
    }
    final jewel = Path()
      ..moveTo(0, -1.37)
      ..lineTo(.13, -1.21)
      ..lineTo(0, -1.02)
      ..lineTo(-.13, -1.21)
      ..close();
    c.drawPath(
      jewel,
      gradient(const Rect.fromLTWH(-.14, -1.38, .28, .37), [
        cream,
        ember,
        const Color(0xff932e63),
      ]),
    );
    c.drawPath(jewel, line(ink, .025));
  }
}
