import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';

/// The Pirate Captain: a barrel-chested buccaneer in a gold-trimmed crimson
/// coat and a plumed tricorn, with an eyepatch, a braided black beard, a
/// torch for his cannon's fuse, an iron hook, and a green parrot riding his
/// shoulder.
///
/// Authored in hit-radius units around the hit circle, facing left toward
/// the bird. He stands on his ship's deck, so everything below [rail] is
/// hidden by the hull drawn in front of him.
abstract final class PirateBossRig {
  static const ink = Color(0xff2a1c28);
  static const crimson = Color(0xffc53b4d), gold = Color(0xffffcf5c);
  static const bone = Color(0xfffff4dd), sea = Color(0xff4fd1c5);
  static const flame = Color(0xffffa23a), flameCore = Color(0xfffff1b8);

  /// The visible eye; the silhouette reveal lights it alone.
  static const eyeCenter = Offset(-.47, -.4);

  /// Where the hat sits on the head, and what it covers.
  static const hatAnchor = Offset(-.16, -.7);
  static const hatBounds = Rect.fromLTRB(-1.12, -.9, 1.48, .2);

  /// The parrot's feet on the captain's far shoulder.
  static const parrotAnchor = Offset(.6, -.05);
  static const parrotBounds = Rect.fromLTRB(-.5, -.85, .62, .62);

  /// The deck rail in rig units: the hull hides everything below it.
  static const rail = SkyBoss.hullTop / SkyBoss.radius;

  static const _coatLit = Color(0xffe8636b), _coatDeep = Color(0xff7c2238);
  static const _goldDeep = Color(0xffc9862b), _goldLight = Color(0xfffff0b4);
  static const _hat = Color(0xff2d2942), _hatLit = Color(0xff4c4769);
  static const _hatDeep = Color(0xff191625);
  static const _skin = Color(0xfff3b58c), _skinLit = Color(0xffffd6b0);
  static const _skinShade = Color(0xffcf8466), _blush = Color(0xffea7468);
  static const _beard = Color(0xff302c46), _beardLit = Color(0xff5b5680);
  static const _vest = Color(0xff22596a), _vestLit = Color(0xff3a8a95);
  static const _shirt = Color(0xfffff6e6), _leather = Color(0xff4a2c2a);
  static const _steel = Color(0xffdfe6ee), _steelDark = Color(0xff6f7a8c);
  static const _wood = Color(0xff8a5634), _plume = Color(0xffe44a5c);
  static const _plumeLit = Color(0xffff9c93), _ember = Color(0xffff5a3a);
  static const _flameDeep = Color(0xffff6a2a);
  // The parrot.
  static const _parrot = Color(0xff4cc35c), _parrotDeep = Color(0xff26854a);
  static const _parrotLit = Color(0xffb4ec6e), _parrotFace = Color(0xfffff3a6);
  static const _blue = Color(0xff3b7fe0), _red = Color(0xffe8465a);
  static const _beak = Color(0xfff4e8d0), _beakDark = Color(0xff3b3444);

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

  /// Everything the rig can reach, poses and props included.
  static const bounds = Rect.fromLTRB(-2.1, -2.3, 2.1, 1.3);

  /// The captain in his current pose. [lookY] turns his eye toward the bird
  /// (-1 up, 1 down); [fuse] is the tip of the cannon's wick in rig units,
  /// where the torch dips while the charge builds.
  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    Offset fuse = const Offset(-.98, .66),
    bool parrot = true,
  }) {
    final p = _Pose(boss, m, lookY, fuse);
    final flash = m.defeated ? 0.0 : m.hit * (m.reducedMotion ? .3 : .5);
    if (flash > .01) {
      // A bounded layer blows the fills toward white while the ink holds,
      // so a struck captain never looks ghosted.
      c.saveLayer(bounds, Paint()..colorFilter = _flash(flash));
    }
    if (parrot) _parrotTail(c, p);
    _hookArm(c, p, back: true);
    _torso(c, p);
    _hookArm(c, p, back: false);
    _head(c, p);
    if (!m.defeated || m.death < .3) {
      c.save();
      c.translate(hatAnchor.dx, hatAnchor.dy - p.hatLift);
      c.rotate(p.hatTilt);
      hat(c, fury: p.fury > 0);
      c.restore();
    }
    if (parrot) {
      c.save();
      c.translate(parrotAnchor.dx, parrotAnchor.dy + p.breath * .6);
      paintParrot(
        c,
        time: p.time,
        squawk: p.squawk,
        flap: p.flutter,
        ruffle: p.fury,
        dizzy: m.defeated,
      );
      c.restore();
    }
    _torchArm(c, p);
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

  // ------------------------------------------------------------- torso --

  static void _torso(Canvas c, _Pose p) {
    final b = p.breath;
    final coat = Path()
      ..moveTo(-.9, 1.1)
      ..lineTo(-.94, .44)
      ..cubicTo(-.96, .16 - b, -.8, .02 - b, -.54, -.02 - b)
      ..quadraticBezierTo(0, -.09 - b, .52, -.02 - b)
      ..cubicTo(.8, .02 - b, .96, .16 - b, .95, .44)
      ..lineTo(.97, 1.1)
      ..close();
    c.drawPath(coat, _line(ink, .16));
    c.drawPath(
      coat,
      _gradient(const Rect.fromLTRB(-.95, -.1, .95, 1.1), [
        Color.lerp(_coatLit, _ember, p.fury * .25)!,
        crimson,
        _coatDeep,
      ]),
    );
    c.save();
    c.clipPath(coat);
    // The waistcoat shows in the open front of the coat.
    final vest = Path()
      ..moveTo(-.34, -.1)
      ..lineTo(-.48, 1.1)
      ..lineTo(.36, 1.1)
      ..lineTo(.2, -.1)
      ..close();
    c.drawPath(vest, _gradient(vest.getBounds(), [_vestLit, _vest]));
    for (final y in const [.3, .5]) {
      c.drawCircle(Offset(-.07, y), .045, _fill(gold));
      c.drawCircle(Offset(-.07, y), .045, _line(ink, .02));
    }
    // Folded coat shading down the sides.
    c.drawPath(
      Path()
        ..moveTo(-.8, .2)
        ..quadraticBezierTo(-.66, .6, -.72, 1.05),
      _line(_coatDeep.withValues(alpha: .7), .07),
    );
    c.drawPath(
      Path()
        ..moveTo(.78, .22)
        ..quadraticBezierTo(.64, .6, .7, 1.05),
      _line(_coatDeep.withValues(alpha: .7), .07),
    );
    c.restore();
    // Gold-trimmed lapels frame the waistcoat.
    for (final lapel in [
      Path()
        ..moveTo(-.36, -.08)
        ..lineTo(-.5, 1.1),
      Path()
        ..moveTo(.22, -.08)
        ..lineTo(.38, 1.1),
    ]) {
      c.drawPath(lapel, _line(ink, .13));
      c.drawPath(lapel, _line(gold, .075));
      c.drawPath(lapel, _line(_goldLight.withValues(alpha: .8), .022));
    }
    for (final (x, y) in const [(-.44, .24), (-.47, .5), (.31, .26), (.33, .5)]) {
      c.drawCircle(Offset(x, y), .05, _fill(ink));
      c.drawCircle(Offset(x, y), .035, _fill(_goldLight));
    }
    // A broad belt and a big brass buckle, just above the rail.
    final belt = Path()
      ..moveTo(-.95, .6)
      ..quadraticBezierTo(0, .66, .96, .58)
      ..lineTo(.97, .76)
      ..quadraticBezierTo(0, .84, -.95, .78)
      ..close();
    c.drawPath(belt, _fill(_leather));
    c.drawPath(belt, _line(ink, .05));
    c.drawPath(
      Path()
        ..moveTo(-.9, .64)
        ..quadraticBezierTo(0, .7, .92, .62),
      _line(const Color(0xff6e4639), .025),
    );
    final buckle = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-.28, .56, -.02, .83),
      const Radius.circular(.05),
    );
    c.drawRRect(buckle, _fill(ink));
    c.drawRRect(buckle.deflate(.03), _gradient(buckle.outerRect, [_goldLight, gold, _goldDeep]));
    c.drawRRect(buckle.deflate(.085), _fill(_leather));
    c.drawLine(const Offset(-.15, .64), const Offset(-.15, .75), _line(_goldLight, .03));
    // Epaulettes with swinging gold fringe.
    for (final side in [-1.0, 1.0]) {
      final at = Offset(side * .66, .0 - b);
      final swing = side * p.fringe;
      for (var i = 0; i < 5; i++) {
        final x = at.dx + (i - 2) * .07;
        c.drawLine(
          Offset(x, at.dy + .05),
          Offset(x + swing, at.dy + .19),
          _line(ink, .05),
        );
        c.drawLine(
          Offset(x, at.dy + .05),
          Offset(x + swing, at.dy + .17),
          _line(gold, .028),
        );
      }
      final pad = Rect.fromCenter(center: at, width: .44, height: .17);
      c.drawOval(pad, _fill(ink));
      c.drawOval(pad.deflate(.025), _gradient(pad, [_goldLight, gold, _goldDeep]));
    }
  }

  // -------------------------------------------------------------- head --

  static void _head(Canvas c, _Pose p) {
    c.save();
    c.translate(p.headShift.dx, p.headShift.dy);
    c.rotate(p.headTilt);
    // Ear and gold hoop behind the eyepatch strap.
    final ear = Rect.fromCenter(
      center: const Offset(.18, -.33),
      width: .17,
      height: .23,
    );
    c.drawOval(ear, _fill(ink));
    c.drawOval(ear.deflate(.03), _fill(_skinShade));
    c.drawCircle(
      Offset(.21, -.17 + p.jiggle * .3),
      .065,
      _line(ink, .05),
    );
    c.drawCircle(Offset(.21, -.17 + p.jiggle * .3), .065, _line(gold, .028));
    final face = Path()
      ..moveTo(-.66, -.66)
      ..cubicTo(-.8, -.5, -.8, -.18, -.66, -.04)
      ..quadraticBezierTo(-.3, .08, .08, -.04)
      ..cubicTo(.22, -.14, .26, -.46, .15, -.66)
      ..close();
    c.drawPath(face, _line(ink, .12));
    c.drawPath(
      face,
      _gradient(const Rect.fromLTRB(-.8, -.66, .25, 0), [
        _skinLit,
        Color.lerp(_skin, _blush, p.fury * .45)!,
        _skinShade,
      ]),
    );
    // Rosy weathered cheek.
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-.1, -.24),
        width: .22,
        height: .13,
      ),
      _fill(_blush.withValues(alpha: .5 + p.fury * .3)),
    );
    _eye(c, p);
    _eyepatch(c, p);
    _brows(c, p);
    _beard(c, p);
    _nose(c, p);
    _mustache(c, p);
    c.restore();
  }

  static void _eye(Canvas c, _Pose p) {
    const center = eyeCenter;
    final white = Rect.fromCenter(center: center, width: .2, height: .24);
    if (p.dizzy) {
      // Knocked silly: a spiral where the eye was.
      final spiral = Path()..moveTo(center.dx, center.dy);
      for (var i = 1; i <= 22; i++) {
        final t = i / 22;
        final a = t * math.pi * 4.2;
        spiral.lineTo(
          center.dx + math.cos(a) * .1 * t,
          center.dy + math.sin(a) * .11 * t,
        );
      }
      c.drawOval(white.inflate(.03), _fill(ink));
      c.drawOval(white, _fill(bone));
      c.drawPath(spiral, _line(ink, .03));
      return;
    }
    c.drawOval(white.inflate(.035), _fill(ink));
    c.drawOval(white, _fill(p.fury > 0 ? const Color(0xffffe6c8) : bone));
    final pupil = center + Offset(-.035 - p.aim.abs() * .01, p.aim * .06);
    if (p.fury > 0) {
      c.drawCircle(pupil, .075, _fill(_ember));
    }
    c.drawOval(
      Rect.fromCenter(
        center: pupil,
        width: p.fury > 0 ? .07 : .1,
        height: p.fury > 0 ? .12 : .14,
      ),
      _fill(ink),
    );
    c.drawCircle(pupil + const Offset(-.022, -.035), .025, _fill(bone));
    // A heavy lid: a narrowed glare in fury and while aiming, squeezed shut
    // when struck, flung open by the roar.
    final lid = math.max(
      math.max(p.fury * .32, p.charge * .28),
      math.max(p.wince * .75, p.blink),
    ) * (1 - p.roar);
    if (lid > .01) {
      c.save();
      c.clipPath(Path()..addOval(white));
      final edge = white.top + white.height * lid;
      c.drawRect(
        Rect.fromLTRB(white.left - .05, white.top - .05, white.right + .05, edge),
        _fill(_skinShade),
      );
      c.drawLine(
        Offset(white.left - .05, edge + .03),
        Offset(white.right + .05, edge - .02),
        _line(ink, .04),
      );
      c.restore();
    }
  }

  static void _eyepatch(Canvas c, _Pose p) {
    // The strap climbs under the hat and runs back to the ear.
    final strap = Path()
      ..moveTo(-.3, -.5)
      ..lineTo(-.46, -.72)
      ..moveTo(.02, -.46)
      ..quadraticBezierTo(.12, -.48, .22, -.52);
    c.drawPath(strap, _line(ink, .05));
    final patch = Path()
      ..moveTo(-.28, -.53)
      ..quadraticBezierTo(-.12, -.58, .04, -.5)
      ..quadraticBezierTo(.06, -.33, -.1, -.28)
      ..quadraticBezierTo(-.28, -.3, -.28, -.53)
      ..close();
    c.drawPath(patch, _fill(ink));
    c.drawPath(
      Path()
        ..moveTo(-.22, -.5)
        ..quadraticBezierTo(-.13, -.53, -.04, -.49),
      _line(_hatLit, .03),
    );
  }

  static void _brows(Canvas c, _Pose p) {
    // Bushy brows: they knot down in fury and while aiming, jump up in the
    // roar and slump in defeat.
    final anger = p.dizzy ? -.05 : p.fury * .09 + p.charge * .05;
    final lift = p.roar * .07 + p.wince * .02;
    for (final (outer, inner) in [
      (const Offset(-.66, -.58), const Offset(-.36, -.6)),
      (const Offset(.1, -.6), const Offset(-.2, -.62)),
    ]) {
      final o = outer + Offset(0, -lift - anger * .3);
      final i = inner + Offset(0, anger - lift);
      final brow = Path()
        ..moveTo(o.dx, o.dy + .03)
        ..quadraticBezierTo(
          (o.dx + i.dx) / 2,
          (o.dy + i.dy) / 2 - .07,
          i.dx,
          i.dy - .02,
        )
        ..lineTo(i.dx, i.dy + .05)
        ..quadraticBezierTo(
          (o.dx + i.dx) / 2,
          (o.dy + i.dy) / 2 + .02,
          o.dx,
          o.dy + .06,
        )
        ..close();
      c.drawPath(brow, _line(ink, .05));
      c.drawPath(brow, _fill(_beard));
    }
  }

  static void _nose(Canvas c, _Pose p) {
    const at = Offset(-.7, -.29);
    c.drawCircle(at, .135, _fill(ink));
    c.drawCircle(
      at,
      .1,
      _gradient(Rect.fromCircle(center: at, radius: .1), [
        _skinLit,
        Color.lerp(_skin, _blush, .45 + p.fury * .3)!,
      ]),
    );
    c.drawCircle(at + const Offset(-.03, -.035), .03, _fill(bone));
  }

  static void _mustache(Canvas c, _Pose p) {
    // A handlebar that twitches up with the grin and flares in the roar.
    final flare = p.roar * .06 + p.mouth * .03;
    final m = Path()
      ..moveTo(-.58, -.21)
      ..cubicTo(-.68, -.27 - flare, -.84, -.23, -.9, -.33 - flare)
      ..quadraticBezierTo(-1.0, -.24, -.9, -.13)
      ..cubicTo(-.8, -.07, -.66, -.09, -.56, -.13)
      ..cubicTo(-.44, -.07, -.18, -.06, -.04, -.14)
      ..quadraticBezierTo(.06, -.23 - flare, -.01, -.31 - flare)
      ..cubicTo(-.1, -.22, -.36, -.27, -.58, -.21)
      ..close();
    c.drawPath(m, _line(ink, .06));
    c.drawPath(m, _fill(_beard));
    c.drawPath(
      Path()
        ..moveTo(-.64, -.2)
        ..quadraticBezierTo(-.76, -.2, -.84, -.25)
        ..moveTo(-.46, -.17)
        ..quadraticBezierTo(-.3, -.16, -.14, -.19),
      _line(_beardLit, .025),
    );
  }

  static void _beard(Canvas c, _Pose p) {
    final open = p.mouth;
    final beard = Path()
      ..moveTo(-.74, -.2)
      ..cubicTo(-.9, .06, -.78, .34, -.56, .44 + open * .05)
      ..quadraticBezierTo(-.42, .6 + open * .06, -.26, .5 + open * .05)
      ..quadraticBezierTo(-.08, .56 + open * .04, .02, .38)
      ..cubicTo(.18, .26, .26, .04, .19, -.14)
      ..quadraticBezierTo(-.02, -.04, -.3, -.05)
      ..quadraticBezierTo(-.56, -.07, -.74, -.2)
      ..close();
    // A white shirt ruffle peeks out under the beard.
    final ruffle = Path()
      ..moveTo(-.34, .2)
      ..quadraticBezierTo(-.2, .5, -.06, .2)
      ..close();
    c.drawPath(ruffle, _line(ink, .05));
    c.drawPath(ruffle, _fill(_shirt));
    c.drawPath(beard, _line(ink, .12));
    c.drawPath(
      beard,
      _gradient(beard.getBounds(), [_beardLit, _beard, const Color(0xff1f1c30)]),
    );
    // Curls: lighter strokes give the black beard its volume.
    c.save();
    c.clipPath(beard);
    for (final (x, y, r) in const [
      (-.66, .1, .1),
      (-.48, .3, .1),
      (-.24, .34, .09),
      (-.02, .2, .09),
      (.08, .0, .08),
      (-.56, -.06, .08),
    ]) {
      c.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: r),
        -2.6,
        2.2,
        false,
        _line(_beardLit.withValues(alpha: .8), .03),
      );
    }
    c.restore();
    // Two braids tied off with gold rings swing below.
    for (final (x, len) in const [(-.4, .3), (-.14, .26)]) {
      final top = Offset(x, .44);
      final tip = Offset(x + p.braid, .44 + len);
      final braid = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(x - .04, top.dy + len * .5, tip.dx, tip.dy);
      c.drawPath(braid, _line(ink, .13));
      c.drawPath(braid, _line(_beard, .075));
      for (var i = 1; i <= 2; i++) {
        final at = Offset.lerp(top, tip, i * .3)!;
        c.drawLine(
          at + const Offset(-.03, -.02),
          at + const Offset(.03, .02),
          _line(_beardLit, .025),
        );
      }
      final ring = Offset.lerp(top, tip, .82)!;
      c.drawOval(
        Rect.fromCenter(center: ring, width: .13, height: .07),
        _fill(ink),
      );
      c.drawOval(
        Rect.fromCenter(center: ring, width: .1, height: .045),
        _fill(gold),
      );
    }
    // The mouth opens in the beard under the mustache: a grin with one gold
    // tooth, a gritted snarl while he aims, a bellow in the roar.
    final mouth = Rect.fromCenter(
      center: Offset(-.42, -.05 + open * .07),
      width: .3 + open * .06,
      height: .05 + open * .22,
    );
    if (open > .05) {
      final m = RRect.fromRectAndRadius(mouth, Radius.circular(mouth.height / 2));
      c.drawRRect(m, _fill(ink));
      c.save();
      c.clipRRect(m);
      c.drawRect(
        Rect.fromLTRB(mouth.left, mouth.top, mouth.right, mouth.top + .055),
        _fill(bone),
      );
      c.drawRect(
        Rect.fromLTRB(mouth.center.dx + .02, mouth.top, mouth.center.dx + .08, mouth.top + .055),
        _fill(gold),
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(mouth.center.dx, mouth.bottom),
          width: mouth.width * .6,
          height: mouth.height * .5,
        ),
        _fill(const Color(0xffc9566a)),
      );
      c.restore();
    } else {
      c.drawPath(
        Path()
          ..moveTo(mouth.left, mouth.top)
          ..quadraticBezierTo(mouth.center.dx, mouth.bottom + .03, mouth.right, mouth.top - .02),
        _line(ink, .04),
      );
    }
  }

  // --------------------------------------------------------------- hat --

  /// The plumed tricorn, drawn around its seat on the head. It is also drawn
  /// on its own when it is knocked off in the defeat.
  static void hat(Canvas c, {bool fury = false}) {
    // A crimson plume sweeps back from the crown.
    final plume = Path()
      ..moveTo(.28, -.52)
      ..cubicTo(.7, -.86, 1.24, -.9, 1.44, -.62)
      ..quadraticBezierTo(1.3, -.66, 1.32, -.54)
      ..quadraticBezierTo(1.16, -.6, 1.12, -.46)
      ..quadraticBezierTo(.96, -.54, .9, -.38)
      ..cubicTo(.72, -.46, .5, -.4, .4, -.3)
      ..close();
    c.drawPath(plume, _line(ink, .07));
    c.drawPath(
      plume,
      _gradient(plume.getBounds(), [_plumeLit, fury ? _ember : _plume, _coatDeep]),
    );
    c.drawPath(
      Path()
        ..moveTo(.36, -.42)
        ..cubicTo(.66, -.66, 1.06, -.74, 1.36, -.64),
      _line(_plumeLit.withValues(alpha: .9), .03),
    );
    final crown = Path()
      ..moveTo(-.52, -.05)
      ..cubicTo(-.56, -.42, -.32, -.68, .06, -.7)
      ..cubicTo(.44, -.68, .64, -.42, .62, -.05)
      ..close();
    c.drawPath(crown, _line(ink, .1));
    c.drawPath(crown, _gradient(crown.getBounds(), [_hatLit, _hat, _hatDeep]));
    // A gold band where the crown meets the brim.
    c.drawPath(
      Path()
        ..moveTo(-.5, -.2)
        ..quadraticBezierTo(.06, -.3, .6, -.2),
      _line(_goldDeep, .06),
    );
    c.drawArc(
      const Rect.fromLTRB(-.3, -.62, .3, -.1),
      3.5,
      1.1,
      false,
      _line(_hatLit.withValues(alpha: .9), .05),
    );
    // The turned-up brim: a front corner at left, a back corner at right.
    final brim = Path()
      ..moveTo(-.98, -.4)
      ..quadraticBezierTo(-.72, -.02, -.18, .07)
      ..quadraticBezierTo(.56, .14, 1.12, -.36)
      ..quadraticBezierTo(.92, -.18, .62, -.2)
      ..quadraticBezierTo(.26, -.26, -.16, -.16)
      ..quadraticBezierTo(-.58, -.1, -.98, -.4)
      ..close();
    c.drawPath(brim, _line(ink, .1));
    c.drawPath(brim, _gradient(brim.getBounds(), [_hatLit, _hat, _hatDeep]));
    // Gold braid along the turned-up edge.
    final edge = Path()
      ..moveTo(-.92, -.36)
      ..quadraticBezierTo(-.58, -.08, -.16, -.13)
      ..quadraticBezierTo(.26, -.22, .62, -.16)
      ..quadraticBezierTo(.92, -.14, 1.07, -.33);
    c.drawPath(edge, _line(ink, .085));
    c.drawPath(edge, _line(gold, .05));
    c.drawPath(edge, _line(_goldLight.withValues(alpha: .7), .016));
    for (final at in const [Offset(-.98, -.4), Offset(1.12, -.36)]) {
      c.drawCircle(at, .06, _fill(ink));
      c.drawCircle(at, .038, _fill(gold));
    }
    // Skull and crossbones on the front of the brim.
    _skull(c, const Offset(-.2, -.02), .2, fury: fury);
  }

  /// A cartoon skull over crossed bones, [r] across the skull.
  static void _skull(Canvas c, Offset at, double r, {bool fury = false}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    final bones = Path()
      ..moveTo(-.95, -.55)
      ..lineTo(.95, .75)
      ..moveTo(.95, -.55)
      ..lineTo(-.95, .75);
    c.drawPath(bones, _line(ink, .5));
    c.drawPath(bones, _line(bone, .26));
    for (final end in const [
      Offset(-.95, -.55),
      Offset(.95, .75),
      Offset(.95, -.55),
      Offset(-.95, .75),
    ]) {
      c.drawCircle(end, .24, _fill(ink));
      c.drawCircle(end, .15, _fill(bone));
    }
    final skull = Path()
      ..addOval(const Rect.fromLTRB(-.62, -.78, .62, .38))
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.36, .1, .36, .62),
          const Radius.circular(.12),
        ),
      );
    c.drawPath(skull, _line(ink, .22));
    c.drawPath(skull, _fill(bone));
    for (final x in const [-.25, .25]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, -.16), width: .32, height: .34),
        _fill(fury ? _ember : ink),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(0, .06)
        ..lineTo(-.08, .2)
        ..lineTo(.08, .2)
        ..close(),
      _fill(ink),
    );
    for (final x in const [-.14, 0.0, .14]) {
      c.drawLine(Offset(x, .38), Offset(x, .56), _line(ink, .07));
    }
    c.restore();
  }

  // -------------------------------------------------------------- arms --

  static void _sleeve(Canvas c, Offset shoulder, Offset elbow, Offset hand) {
    final arm = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy);
    c.drawPath(arm, _line(ink, .34));
    c.drawPath(arm, _line(crimson, .22));
    c.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy - .04)
        ..quadraticBezierTo(elbow.dx, elbow.dy - .05, hand.dx, hand.dy - .04),
      _line(_coatLit.withValues(alpha: .55), .05),
    );
  }

  /// A gold-trimmed cuff at [at], turned along [dir].
  static void _cuff(Canvas c, Offset at, Offset dir) {
    final n = dir / math.max(dir.distance, 1e-6);
    final side = Offset(-n.dy, n.dx) * .16;
    c.drawLine(at - side, at + side, _line(ink, .16));
    c.drawLine(at - side, at + side, _line(gold, .09));
  }

  static void _torchArm(Canvas c, _Pose p) {
    final shoulder = Offset(-.72, .16 - p.breath);
    final hand = p.torchHand;
    final elbow = Offset(
      math.min(shoulder.dx, hand.dx) - .22,
      (shoulder.dy + hand.dy) / 2 + .14,
    );
    _sleeve(c, shoulder, elbow, hand);
    final dir = Offset(math.cos(p.torchAngle), math.sin(p.torchAngle));
    // The torch: a short tarred stick, a wrapped head and a flame that always
    // licks upward, whichever way it points.
    final butt = hand - dir * .2, head = hand + dir * .42;
    c.drawLine(butt, head, _line(ink, .13));
    c.drawLine(butt, head, _line(_wood, .07));
    final wrap = head - dir * .06;
    c.drawCircle(wrap, .085, _fill(ink));
    c.drawCircle(wrap, .06, _fill(const Color(0xff6b4a3a)));
    _flame(c, head + dir * .02, p);
    // The fist wraps the stick.
    c.drawCircle(hand, .12, _fill(ink));
    c.drawCircle(hand, .09, _fill(_skin));
    c.drawLine(
      hand + const Offset(-.05, -.02),
      hand + const Offset(.04, -.05),
      _line(_skinShade, .025),
    );
    _cuff(c, Offset.lerp(elbow, hand, .78)!, hand - elbow);
  }

  static void _flame(Canvas c, Offset at, _Pose p) {
    final t = p.time;
    final size = 1 + p.fury * .35 + p.roar * .3;
    final lick = math.sin(t * 13) * .03 + math.sin(t * 21 + 1) * .02;
    final glow = Rect.fromCircle(center: at, radius: .5 * size);
    c.drawCircle(
      at,
      .5 * size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (p.fury > 0 ? _ember : flame).withValues(alpha: .38),
            flame.withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    Path tongue(double w, double hgt, double sway) => Path()
      ..moveTo(at.dx - w, at.dy)
      ..quadraticBezierTo(at.dx - w * 1.1, at.dy - hgt * .55, at.dx + sway, at.dy - hgt)
      ..quadraticBezierTo(at.dx + w * 1.1, at.dy - hgt * .45, at.dx + w, at.dy)
      ..quadraticBezierTo(at.dx, at.dy + w * .9, at.dx - w, at.dy)
      ..close();
    final outer = tongue(.12 * size, (.34 + lick) * size, lick * 2);
    c.drawPath(outer, _line(ink, .05));
    c.drawPath(outer, _fill(p.fury > 0 ? _ember : _flameDeep));
    c.drawPath(tongue(.085 * size, (.25 + lick) * size, lick * 1.5), _fill(flame));
    c.drawPath(tongue(.045 * size, (.14 + lick * .5) * size, lick), _fill(flameCore));
  }

  static void _hookArm(Canvas c, _Pose p, {required bool back}) {
    // Raised high the far arm swings behind the body; otherwise it rests in
    // front at the hip.
    if (back != p.hookBehind) return;
    final shoulder = Offset(.72, .16 - p.breath);
    final hand = p.hookHand;
    final elbow = Offset(
      math.max(shoulder.dx, hand.dx) + .2,
      (shoulder.dy + hand.dy) / 2 + .12,
    );
    _sleeve(c, shoulder, elbow, hand);
    final dir = hand - elbow;
    _cuff(c, hand, dir);
    // The iron hook curls forward and up from the cuff.
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(math.atan2(dir.dy, dir.dx) + p.hookTwist);
    final hook = Path()
      ..moveTo(0, 0)
      ..lineTo(.16, 0)
      ..cubicTo(.34, 0, .38, -.24, .24, -.3)
      ..quadraticBezierTo(.16, -.33, .14, -.24);
    c.drawPath(hook, _line(ink, .12));
    c.drawPath(hook, _line(_steelDark, .075));
    c.drawPath(
      Path()
        ..moveTo(.06, -.015)
        ..lineTo(.18, -.015)
        ..cubicTo(.3, -.02, .33, -.18, .26, -.24),
      _line(_steel, .03),
    );
    c.drawCircle(const Offset(.14, -.24), .035, _fill(_steel));
    c.restore();
  }

  // ------------------------------------------------------------ parrot --

  static void _parrotTail(Canvas c, _Pose p) {
    c.save();
    c.translate(parrotAnchor.dx, parrotAnchor.dy + p.breath * .6);
    final sway = p.time == 0 ? 0.0 : math.sin(p.time * 2.2) * .03;
    for (final (dx, color, len) in [
      (.02, _red, .58),
      (.12, _blue, .5),
      (.2, _parrotDeep, .4),
    ]) {
      final tail = Path()
        ..moveTo(dx - .06, -.1)
        ..quadraticBezierTo(dx + .1 + sway, len * .5, dx + .14 + sway, len)
        ..quadraticBezierTo(dx + .06 + sway, len * .55, dx - .1, -.06)
        ..close();
      c.drawPath(tail, _line(ink, .05));
      c.drawPath(tail, _fill(color));
    }
    c.restore();
  }

  /// The captain's parrot, standing with its feet at the origin and facing
  /// left. It also flies free when the captain is beaten.
  static void paintParrot(
    Canvas c, {
    double time = 0,
    double squawk = 0,
    double flap = 0,
    double ruffle = 0,
    bool dizzy = false,
    bool flying = false,
  }) {
    final bob = time == 0 ? 0.0 : math.sin(time * 3.4) * .025;
    if (flying) {
      // Tail streaming behind while it flies.
      for (final (dy, color) in [(-.02, _red), (.05, _blue)]) {
        final tail = Path()
          ..moveTo(.08, -.2 + dy)
          ..quadraticBezierTo(.36, -.1 + dy, .58, .02 + dy)
          ..quadraticBezierTo(.34, -.02 + dy, .06, -.12 + dy)
          ..close();
        c.drawPath(tail, _line(ink, .05));
        c.drawPath(tail, _fill(color));
      }
    }
    // Far wing behind the body when flapping.
    if (flap > .05) {
      final wing = Path()
        ..moveTo(.04, -.32)
        ..quadraticBezierTo(.1, -.62 - flap * .3, .34, -.7 - flap * .28)
        ..quadraticBezierTo(.26, -.44, .12, -.22)
        ..close();
      c.drawPath(wing, _line(ink, .05));
      c.drawPath(wing, _fill(_parrotDeep));
    }
    final body = Path()
      ..moveTo(-.02, 0)
      ..cubicTo(-.24, -.05, -.28, -.32, -.15, -.44 + bob)
      ..cubicTo(-.04, -.54 + bob, .16, -.48 + bob, .19, -.3)
      ..cubicTo(.23, -.14, .17, -.02, -.02, 0)
      ..close();
    c.drawPath(body, _line(ink, .07));
    c.drawPath(
      body,
      _gradient(body.getBounds(), [_parrotLit, _parrot, _parrotDeep]),
    );
    if (ruffle > 0) {
      // Hackles up: a spiky collar of feathers.
      final spikes = Path();
      for (var i = 0; i < 4; i++) {
        final x = -.12 + i * .08;
        spikes
          ..moveTo(x, -.36 + bob)
          ..lineTo(x + .07, -.46 + bob - (i.isEven ? .05 : .02))
          ..lineTo(x + .08, -.34 + bob);
      }
      c.drawPath(spikes, _line(ink, .04));
      c.drawPath(spikes, _fill(_parrotLit));
    }
    // Near wing: green with a red shoulder and blue flight feathers.
    c.save();
    c.translate(.06, -.3 + bob);
    c.rotate(-flap * 1.1);
    final wing = Path()
      ..moveTo(-.06, -.02)
      ..cubicTo(.12, -.08, .2, .12, .14, .3)
      ..quadraticBezierTo(.06, .2, -.04, .12)
      ..quadraticBezierTo(-.1, .04, -.06, -.02)
      ..close();
    c.drawPath(wing, _line(ink, .05));
    c.drawPath(wing, _fill(_parrotDeep));
    c.save();
    c.clipPath(wing);
    c.drawRect(const Rect.fromLTRB(-.2, .14, .3, .4), _fill(_blue));
    c.drawCircle(const Offset(-.02, .0), .07, _fill(_red));
    c.restore();
    c.restore();
    // Head with a pale face patch, a proud crest and a big hooked beak.
    final head = Offset(-.1, -.5 + bob);
    for (var i = 0; i < 3; i++) {
      final crest = Path()
        ..moveTo(head.dx + .02 + i * .04, head.dy - .1)
        ..quadraticBezierTo(
          head.dx + .06 + i * .06,
          head.dy - .24 - (ruffle > 0 ? .06 : 0),
          head.dx + .14 + i * .07,
          head.dy - .2 - i * .02 - (ruffle > 0 ? .04 : 0),
        );
      c.drawPath(crest, _line(ink, .06));
      c.drawPath(crest, _line(i == 1 ? _red : _parrot, .03));
    }
    c.drawCircle(head, .15, _fill(ink));
    c.drawCircle(head, .12, _fill(_parrot));
    c.drawCircle(head + const Offset(-.03, -.01), .075, _fill(_parrotFace));
    final eye = head + const Offset(-.03, -.02);
    if (dizzy) {
      c.drawLine(eye + const Offset(-.03, -.03), eye + const Offset(.03, .03), _line(ink, .025));
      c.drawLine(eye + const Offset(-.03, .03), eye + const Offset(.03, -.03), _line(ink, .025));
    } else {
      c.drawCircle(eye, .035, _fill(ink));
      c.drawCircle(eye + const Offset(-.01, -.012), .012, _fill(bone));
      if (ruffle > 0) {
        c.drawLine(
          eye + const Offset(-.06, -.07),
          eye + const Offset(.04, -.04),
          _line(ink, .025),
        );
      }
    }
    // The beak opens in a squawk.
    final open = squawk.clamp(0.0, 1.0);
    c.save();
    c.translate(head.dx - .1, head.dy + .02);
    c.save();
    c.rotate(-.35 * open);
    final lower = Path()
      ..moveTo(0, .02)
      ..quadraticBezierTo(-.1, .08, -.14, .06)
      ..quadraticBezierTo(-.08, .01, 0, -.02)
      ..close();
    c.drawPath(lower, _line(ink, .035));
    c.drawPath(lower, _fill(_beakDark));
    c.restore();
    c.rotate(.18 * open);
    final upper = Path()
      ..moveTo(.02, -.07)
      ..cubicTo(-.12, -.12, -.2, -.02, -.17, .07)
      ..quadraticBezierTo(-.13, .01, -.06, .02)
      ..quadraticBezierTo(0, .02, .02, .0)
      ..close();
    c.drawPath(upper, _line(ink, .035));
    c.drawPath(upper, _fill(_beak));
    c.restore();
    if (!flying) {
      // Grey toes grip the shoulder.
      for (final x in const [-.08, .04]) {
        c.drawPath(
          Path()
            ..moveTo(x, -.02)
            ..quadraticBezierTo(x - .04, .03, x - .06, .01),
          _line(_beakDark, .035),
        );
      }
    }
  }
}

/// Everything the captain's pose derives from the boss clock.
class _Pose {
  _Pose(SkyBoss boss, BossMotion m, double lookY, Offset fuse)
    : time = m.reducedMotion || m.defeated ? 0.0 : boss.age,
      charge = m.defeated ? 0 : BossMotion.ease(boss.charge),
      recoil = m.reducedMotion ? 0 : m.recoil,
      wince = m.wince,
      roar = m.roar,
      dizzy = m.defeated,
      blink = m.blink,
      fury = boss.enraged && !m.defeated ? .8 + m.rage * .2 : 0,
      aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0 {
    breath = math.sin(time * 2.4) * .02;
    final hit = m.reducedMotion ? 0.0 : m.hit;
    // The tide answers his hook: he raises it through the warning and holds
    // it while the sea surges.
    final call = _tideCall(boss) * (1 - roar);
    final furyShake = fury > 0 && time != 0 ? math.sin(time * 17) * .04 : 0.0;
    mouth = dizzy
        ? .35
        : math.max(roar, math.max(recoil * .9, math.max(charge * .3, call * .5)));
    squawk = dizzy ? .2 : math.max(roar, math.max(recoil, hit));
    flutter = m.reducedMotion
        ? 0
        : math.max(hit, roar * .8) *
              (.6 + .4 * math.sin(boss.age * 30).abs());
    fringe = time == 0 ? 0 : math.sin(time * 2.4 + .6) * .02 + hit * .04;
    braid = time == 0 ? 0 : math.sin(time * 2.1) * .03 - recoil * .05;
    jiggle = time == 0 ? 0 : math.sin(time * 3.1) * .03 + hit * .05;
    headShift = Offset(recoil * .04 + hit * .03, -roar * .05 + breath);
    headTilt = m.reducedMotion
        ? 0
        : recoil * .06 - roar * .05 + hit * .05 + charge * -.04;
    hatLift = m.reducedMotion ? 0 : hit * .16 + recoil * .08 + roar * .14;
    hatTilt = m.reducedMotion ? 0 : -hit * .12 - roar * .06 + recoil * .05;
    // The torch: held up by his face, dipped to the wick while the charge
    // builds, thrust high with the roar and the shot.
    final idleHand = Offset(-.98, .44 + breath);
    const idleAngle = -1.72;
    const dipAngle = 2.28;
    final dipHand = fuse - Offset(math.cos(dipAngle), math.sin(dipAngle)) * .44;
    final raisedHand = const Offset(-1.02, -.1);
    const raisedAngle = -1.92;
    final dip = BossMotion.ease(BossMotion.ramp(charge, 0, .35));
    final up = math.max(recoil, roar);
    torchHand = Offset.lerp(
      Offset.lerp(idleHand, dipHand, dip)!,
      raisedHand,
      up,
    )!;
    torchAngle = _lerpAngle(
      _lerpAngle(idleAngle, dipAngle, dip),
      raisedAngle,
      up,
    );
    // The hook: resting at the hip, raised to call the tide, shaken in fury,
    // flung up in the roar.
    final rest = Offset(1.02, .5 + breath);
    final raised = const Offset(1.16, -.5);
    final lift = math.max(call, roar);
    hookHand =
        Offset.lerp(rest, raised, lift)! +
        Offset(furyShake * (1 - lift), furyShake * .5) +
        Offset(hit * .08, -hit * .06);
    hookBehind = false;
    hookTwist = -lift * .9 + hit * .3;
  }

  final double time, charge, recoil, wince, roar, blink, fury, aim;
  final bool dizzy;
  late final double breath, mouth, squawk, flutter, fringe, braid, jiggle;
  late final double headTilt, hatLift, hatTilt, torchAngle, hookTwist;
  late final Offset headShift, torchHand, hookHand;
  late final bool hookBehind;

  static double _tideCall(SkyBoss boss) {
    if (boss.phase != BossPhase.attacking) return 0;
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    final up = BossMotion.ramp(cycle, SkyBoss.tideWarnAt, SkyBoss.tideWarnAt + .35);
    final down = BossMotion.ramp(
      cycle,
      SkyBoss.tidePeakAt + .2,
      SkyBoss.tidePeakAt + .8,
    );
    return BossMotion.ease(up) * (1 - BossMotion.ease(down));
  }

  static double _lerpAngle(double a, double b, double t) {
    var d = (b - a) % (math.pi * 2);
    if (d > math.pi) d -= math.pi * 2;
    if (d < -math.pi) d += math.pi * 2;
    return a + d * t;
  }
}
