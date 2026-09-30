import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Every channel the Pirate Captain's body art reads. `PirateBossRig` derives
/// it from the boss clock; nothing in here keeps history, so any frame can be
/// drawn on its own (and Reduced Motion simply passes a still pose).
class CaptainBodyPose {
  const CaptainBodyPose({
    this.time = 0,
    this.breath = 0,
    this.fury = 0,
    this.roar = 0,
    this.charge = 0,
    this.recoil = 0,
    this.fringe = 0,
    this.hunch = 0,
    this.torchHand = const Offset(-.96, .26),
    this.torchAngle = -1.66,
    this.torchUp = 0,
    this.hookHand = const Offset(.98, .62),
    this.hookTwist = 0,
    this.hookLift = 0,
    this.dizzy = false,
  });

  /// Seconds on the boss clock, 0 when the pose must sit still.
  final double time;

  /// A breath of chest movement, shoulders raised in fury (`hunch`).
  final double breath, hunch;
  final double fury, roar, charge, recoil, fringe;

  /// The torch hand, the torch's heading, and how far it is thrown high.
  final Offset torchHand;
  final double torchAngle, torchUp;

  /// The hook hand, its wrist twist and how far the arm is raised.
  final Offset hookHand;
  final double hookTwist, hookLift;

  /// Knocked silly: the torch gutters.
  final bool dizzy;

  /// Where the torch's flame sits: the top of the wrapped head.
  Offset get flameAt =>
      torchHand +
      Offset(math.cos(torchAngle), math.sin(torchAngle)) *
          PirateCaptainBodyArt.torchReach;

  /// How big the flame runs.
  double get flameSize =>
      (1 + fury * .3 + roar * .3 + recoil * .2 + charge * .12) *
      (dizzy ? .5 : 1);
}

/// The Pirate Captain's body in rig units (1 = the hit radius): the layered
/// crimson coat with lapels, gold epaulettes, waistcoat, baldric, belt and
/// pistol; the sleeved torch arm with its layered flame, embers and cast
/// light; and the sleeved hook arm with its leather cup and polished hook.
///
/// Everything is drawn from the pose only, so it is pure and seekable.
abstract final class PirateCaptainBodyArt {
  static const ink = Color(0xff2a1c28);
  static const _crimson = Color(0xffc53b4d), _coatLit = Color(0xffe8636b);
  static const _coatDeep = Color(0xff7c2238), _coatDark = Color(0xff4d1428);
  static const _facing = Color(0xffa22c47), _facingLit = Color(0xffd4506a);
  static const _gold = Color(0xffffcf5c), _goldDeep = Color(0xffc9862b);
  static const _goldLight = Color(0xfffff0b4);
  static const _vest = Color(0xff22596a), _vestLit = Color(0xff3f8f99);
  static const _vestDark = Color(0xff153a4a);
  static const _cream = Color(0xfffff4dd), _creamShade = Color(0xffe4cfa8);
  static const _leather = Color(0xff4a2c2a), _leatherLit = Color(0xff7c4d3d);
  static const _leatherDeep = Color(0xff2e1a1c);
  static const _steel = Color(0xffeef3f8), _steelMid = Color(0xff9fb0c4);
  static const _steelDark = Color(0xff56627a);
  static const _wood = Color(0xff8a5634), _woodLit = Color(0xffb47a4a);
  static const _woodDark = Color(0xff4f2f22);
  static const _skin = Color(0xfff3b58c), _skinLit = Color(0xffffd6b0);
  static const _skinShade = Color(0xffcf8466);
  static const _ember = Color(0xffff5a3a), _flameDeep = Color(0xffff6a2a);
  static const _flame = Color(0xffffa23a), _flameYellow = Color(0xffffd35c);
  static const _flameCore = Color(0xfffff1b8), _warm = Color(0xffff9a3a);
  static const _white = Color(0xffffffff);

  /// From the torch hand to the base of the flame.
  static const torchReach = .6;

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint _gradient(
    Rect rect,
    List<Color> colors, {
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    List<double>? stops,
  }) => Paint()
    ..shader = LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    ).createShader(rect);

  static double _mix(double a, double b, double t) => a + (b - a) * t;

  /// A deterministic 0..1 value for slot [i].
  static double _hash(int i) => ((i * 7919 + 13) * 104729 % 1000) / 1000;

  // ------------------------------------------------------------- torso --

  // The waistcoat's opening, the shirt in it and the two lapels are fixed
  // shapes: the coat's clip and the beard (drawn over) do the rest.
  static final _opening = Path()
    ..moveTo(-.02, -.12)
    ..lineTo(.52, -.12)
    ..lineTo(.84, 1.1)
    ..lineTo(-.32, 1.1)
    ..close();
  static final _rightLapel = Path()
    ..moveTo(.46, -.12)
    ..lineTo(.86, -.05)
    ..lineTo(.76, .1)
    ..lineTo(.92, .24)
    ..lineTo(.76, .62)
    ..lineTo(.66, .6)
    ..close();
  static final _leftLapel = Path()
    ..moveTo(.04, -.12)
    ..lineTo(-.4, -.06)
    ..lineTo(-.28, .1)
    ..lineTo(-.44, .24)
    ..lineTo(-.3, .64)
    ..lineTo(-.18, .62)
    ..close();
  static final _shirtFrill = Path()
    ..moveTo(-.02, -.12)
    ..lineTo(.52, -.12)
    ..lineTo(.53, .0)
    ..cubicTo(.5, .1, .43, .07, .41, .14)
    ..cubicTo(.38, .21, .3, .16, .27, .22)
    ..cubicTo(.22, .26, .14, .2, .08, .22)
    ..cubicTo(.03, .16, -.01, .08, -.03, .0)
    ..close();
  static final _baldric = Path()
    ..moveTo(-.7, -.02)
    ..lineTo(-.56, -.06)
    ..lineTo(.86, .74)
    ..lineTo(.7, .84)
    ..close();
  static final _openingPaint = _gradient(
    const Rect.fromLTRB(-.32, -.12, .66, 1.1),
    const [_vestLit, _vest, _vestDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static final _shadePaint = _gradient(
    const Rect.fromLTRB(.1, 0, 1.05, 0),
    [_coatDark.withValues(alpha: 0), _coatDark.withValues(alpha: .62)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Every fixed shape and its shader is built once, not per frame.
  static final _baldricPaint = _gradient(
    const Rect.fromLTRB(-.7, -.06, .86, .84),
    const [_leatherLit, _leather, _leatherDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final _slideRRect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: .1, height: .2),
    const Radius.circular(.03),
  );
  static final _slidePaint = _gradient(_slideRRect.outerRect, const [
    _goldLight,
    _gold,
    _goldDeep,
  ]);
  static final _gripPath = Path()
    ..moveTo(-.06, .06)
    ..cubicTo(-.06, -.08, -.05, -.2, -.09, -.3)
    ..quadraticBezierTo(-.1, -.41, .0, -.41)
    ..quadraticBezierTo(.12, -.41, .1, -.3)
    ..cubicTo(.07, -.2, .075, -.08, .065, .06)
    ..close();
  static final _gripPaint = _gradient(
    _gripPath.getBounds(),
    const [_woodLit, _wood, _woodDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static final _lockRRect = RRect.fromRectAndRadius(
    const Rect.fromLTRB(-.11, -.13, .12, -.02),
    const Radius.circular(.035),
  );
  static final _lockPaint = _gradient(_lockRRect.outerRect, const [
    _goldLight,
    _gold,
    _goldDeep,
  ]);
  static final _beltPath = Path()
    ..moveTo(-1.06, .58)
    ..quadraticBezierTo(0, .64, 1.06, .56)
    ..lineTo(1.07, .78)
    ..quadraticBezierTo(0, .86, -1.06, .8)
    ..close();
  static final _beltPaint = _gradient(
    _beltPath.getBounds(),
    const [_leatherLit, _leather, _leatherDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0, .45, 1],
  );
  static final _buckleRRect = RRect.fromRectAndRadius(
    const Rect.fromLTRB(.02, .5, .44, .84),
    const Radius.circular(.13),
  );
  static final _bucklePaint = _gradient(_buckleRRect.outerRect, const [
    _goldLight,
    _gold,
    _goldDeep,
  ]);
  static const _padRect = Rect.fromLTRB(-.31, -.115, .31, .115);
  static final _padPaint = _gradient(_padRect, const [
    _goldLight,
    _gold,
    _goldDeep,
  ]);
  static final _padClip = Path()..addOval(_padRect);

  static void torso(Canvas c, CaptainBodyPose p) {
    final t = -p.breath - p.hunch;
    final f = p.fury;
    final coat = Path()
      ..moveTo(-.94, 1.1)
      ..lineTo(-1.04, .5)
      ..cubicTo(-1.18, .24 + t, -1.1, -.03 + t, -.66, -.06 + t)
      ..quadraticBezierTo(0, -.14 + t, .66, -.06 + t)
      ..cubicTo(1.1, -.03 + t, 1.2, .24 + t, 1.06, .5)
      ..lineTo(1.0, 1.1)
      ..close();
    if (f > 0) {
      // Rage heats the coat: an ember halo hugging the shoulders.
      final pulse = p.time == 0 ? 1.0 : .8 + .2 * math.sin(p.time * 9);
      c.drawPath(coat, _line(_ember.withValues(alpha: .34 * f * pulse), .34));
    }
    c.drawPath(coat, _line(ink, .16));
    c.drawPath(
      coat,
      _gradient(const Rect.fromLTRB(-1, -.12, 1, 1.1), [
        Color.lerp(_coatLit, _ember, f * .3)!,
        Color.lerp(_crimson, const Color(0xffdc3038), f * .6)!,
        Color.lerp(_coatDeep, const Color(0xff8c1a2c), f * .5)!,
      ]),
    );
    c.save();
    c.clipPath(coat);
    // The far side of the coat sinks into shade.
    c.drawRect(const Rect.fromLTRB(.1, -.2, 1.1, 1.2), _shadePaint);
    // The waistcoat and its ruffled shirt front show in the open coat.
    c.drawPath(_opening, _openingPaint);
    c.drawPath(_opening, _line(_vestDark, .05));
    c.drawPath(_shirtFrill, _line(ink, .04));
    c.drawPath(_shirtFrill, _fill(_cream));
    c.drawPath(
      Path()
        ..moveTo(.46, -.1)
        ..lineTo(.48, .0)
        ..moveTo(.36, .06)
        ..lineTo(.38, .14)
        ..moveTo(.2, .1)
        ..lineTo(.21, .2),
      _line(_creamShade, .035),
    );
    // Lapels turned back in a richer red, piped in gold.
    for (final lapel in [_leftLapel, _rightLapel]) {
      c.drawPath(lapel, _fill(_facing));
    }
    c.drawPath(
      Path()
        ..moveTo(.76, .1)
        ..lineTo(.84, -.02)
        ..lineTo(.62, .1),
      _fill(_facingLit.withValues(alpha: .7)),
    );
    for (final lapel in [_leftLapel, _rightLapel]) {
      c.drawPath(lapel, _line(ink, .07));
      c.drawPath(lapel, _line(_gold, .04));
    }
    // Waistcoat buttons.
    for (final (x, y) in const [(.3, .42), (.34, .52), (.72, .4), (.73, .5)]) {
      c.drawCircle(Offset(x, y), .05, _fill(ink));
      c.drawCircle(Offset(x, y), .034, _fill(_gold));
      c.drawCircle(Offset(x - .01, y - .01), .011, _fill(_goldLight));
    }
    // The baldric crosses the chest from the far shoulder to the hip.
    c.drawPath(_baldric, _line(ink, .05));
    c.drawPath(_baldric, _baldricPaint);
    c.drawLine(
      const Offset(-.6, .0),
      const Offset(.8, .78),
      _line(_gold.withValues(alpha: .85), .016),
    );
    // A brass slide with a cabochon holds the strap on the chest.
    const slide = Offset(.5, .5);
    c.save();
    c.translate(slide.dx, slide.dy);
    c.rotate(.5);
    c.drawRRect(_slideRRect.inflate(.025), _fill(ink));
    c.drawRRect(_slideRRect, _slidePaint);
    c.drawCircle(Offset.zero, .03, _fill(_facing));
    c.restore();
    // Folds in the flanks.
    for (final fold in [
      Path()
        ..moveTo(-.82, .22)
        ..quadraticBezierTo(-.68, .6, -.76, 1.05),
      Path()
        ..moveTo(.84, .26)
        ..quadraticBezierTo(.7, .62, .78, 1.05),
    ]) {
      c.drawPath(fold, _line(_coatDeep.withValues(alpha: .7), .07));
    }
    c.restore();
    // The lit rim along the shoulders.
    c.drawPath(
      Path()
        ..moveTo(-1.1, .3 + t)
        ..cubicTo(-1.12, .08 + t, -1.0, -.03 + t, -.66, -.07 + t),
      _line(_coatLit.withValues(alpha: .9), .035),
    );
    _pistol(c);
    _belt(c);
    _epaulette(c, Offset(-.92, .0 + t), -1, p);
  }

  /// A flintlock pistol tucked in the belt, butt up.
  static void _pistol(Canvas c) {
    c.save();
    c.translate(.62, .64);
    c.rotate(-.34);
    // The wooden grip flares into a butt; only the part above the belt shows.
    c.drawPath(_gripPath, _line(ink, .07));
    c.drawPath(_gripPath, _gripPaint);
    // Grain and a brass cap on the butt.
    c.drawPath(
      Path()
        ..moveTo(-.02, -.05)
        ..quadraticBezierTo(.0, -.2, -.04, -.33),
      _line(_woodDark.withValues(alpha: .6), .02),
    );
    final cap = Rect.fromCenter(
      center: const Offset(.0, -.4),
      width: .2,
      height: .075,
    );
    c.drawOval(cap.inflate(.02), _fill(ink));
    c.drawOval(cap, _fill(_gold));
    c.drawLine(
      const Offset(-.05, -.405),
      const Offset(.03, -.415),
      _line(_goldLight, .02),
    );
    // The brass lock with its hammer, at the mouth of the belt.
    c.drawRRect(_lockRRect.inflate(.022), _fill(ink));
    c.drawRRect(_lockRRect, _lockPaint);
    final hammer = Path()
      ..moveTo(.06, -.12)
      ..quadraticBezierTo(.16, -.2, .13, -.27);
    c.drawPath(hammer, _line(ink, .07));
    c.drawPath(hammer, _line(_steelMid, .035));
    c.drawCircle(const Offset(-.03, -.075), .02, _fill(_goldDeep));
    c.restore();
  }

  static void _belt(Canvas c) {
    c.drawPath(_beltPath, _line(ink, .06));
    c.drawPath(_beltPath, _beltPaint);
    c.drawPath(
      Path()
        ..moveTo(-.96, .63)
        ..quadraticBezierTo(0, .69, .96, .61),
      _line(_gold.withValues(alpha: .55), .014),
    );
    // Brass studs down the belt.
    for (final x in const [-.86, -.66, -.02, .58, .78, .94]) {
      final y = .71 + x * .012;
      c.drawCircle(Offset(x, y), .022, _fill(_gold));
    }
    // The buckle: a bold gilt plate around a red enamel skull.
    c.drawRRect(_buckleRRect.inflate(.03), _fill(ink));
    c.drawRRect(_buckleRRect, _bucklePaint);
    final face = _buckleRRect.deflate(.07);
    c.drawRRect(face.inflate(.012), _fill(_goldDeep));
    c.drawRRect(face, _fill(const Color(0xff5c1a30)));
    const skull = Offset(.23, .665);
    c.drawOval(
      Rect.fromCenter(center: skull, width: .15, height: .14),
      _fill(_cream),
    );
    c.drawRect(
      Rect.fromCenter(
        center: skull + const Offset(0, .075),
        width: .09,
        height: .05,
      ),
      _fill(_cream),
    );
    for (final x in const [-.032, .032]) {
      c.drawCircle(
        skull + Offset(x, -.005),
        .02,
        _fill(const Color(0xff5c1a30)),
      );
    }
    for (final at in const [
      Offset(.06, .54),
      Offset(.4, .54),
      Offset(.06, .8),
      Offset(.4, .8),
    ]) {
      c.drawCircle(at, .016, _fill(_goldDeep));
    }
  }

  /// A gold epaulette on the shoulder [at]: twisted bullion fringe swinging
  /// off the pad, wound cord, a ruby boss.
  static void _epaulette(Canvas c, Offset at, double side, CaptainBodyPose p) {
    final tilt = side * .24;
    final swing = side * p.fringe;
    final cs = math.cos(tilt), sn = math.sin(tilt);
    Offset onPad(double x, double y) =>
        at + Offset(x * cs - y * sn, x * sn + y * cs);
    for (var i = 0; i < 7; i++) {
      final from = onPad((i - 3) * .075, .07);
      final len = .2 + (i % 2) * .035 - (i - 3).abs() * .008;
      final to = from + Offset(swing * (1 + i * .1), len);
      c.drawLine(from, to, _line(ink, .062));
      c.drawLine(from, to, _line(_goldDeep, .04));
      c.drawLine(from, to, _line(_gold, .02));
    }
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    c.drawOval(_padRect.inflate(.035), _fill(ink));
    c.drawOval(_padRect, _padPaint);
    c.save();
    c.clipPath(_padClip);
    // Gold cord wound around the pad.
    for (final x in const [-.22, -.11, 0.0, .11, .22]) {
      c.drawPath(
        Path()
          ..moveTo(x - .03, -.12)
          ..quadraticBezierTo(x + .05, 0, x - .03, .12),
        _line(_goldDeep.withValues(alpha: .8), .028),
      );
    }
    c.restore();
    // A soft shine along the top of the gilt.
    c.drawArc(
      _padRect.deflate(.035),
      math.pi * 1.12,
      1.0,
      false,
      _line(_white.withValues(alpha: .55), .022),
    );
    // A ruby boss at the outer end and the strap button at the neck.
    c.drawCircle(Offset(side * .19, 0), .055, _fill(ink));
    c.drawCircle(Offset(side * .19, 0), .038, _fill(const Color(0xffe4465a)));
    c.drawCircle(Offset(side * .19 - .012, -.012), .012, _fill(_goldLight));
    c.restore();
  }

  // -------------------------------------------------------------- arms --

  /// A tapered, softly bent tube along S-E-H: the elbow is a real vertex the
  /// curve passes through. Returns its outline and the sample frames.
  static ({Path outline, List<Offset> mid, List<Offset> normal}) _tube(
    Offset s,
    Offset e,
    Offset h,
    double w0,
    double w1,
  ) {
    final ctrl = e * 2 - (s + h) * .5;
    const n = 14;
    final mid = <Offset>[], normal = <Offset>[];
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final t = i / n, u = 1 - t;
      final pt = s * (u * u) + ctrl * (2 * u * t) + h * (t * t);
      final d = (ctrl - s) * (2 * u) + (h - ctrl) * (2 * t);
      final nrm = Offset(-d.dy, d.dx) / math.max(d.distance, 1e-6);
      final half = (_mix(w0, w1, t) + math.sin(math.pi * t) * .03) / 2;
      mid.add(pt);
      normal.add(nrm);
      left.add(pt + nrm * half);
      right.add(pt - nrm * half);
    }
    return (
      outline: Path()..addPolygon([...left, ...right.reversed], true),
      mid: mid,
      normal: normal,
    );
  }

  /// A crimson sleeve with a lit top, a shaded underside and elbow creases.
  static void _sleeve(
    Canvas c,
    Offset s,
    Offset e,
    Offset h, {
    double w0 = .36,
    double w1 = .25,
    double fury = 0,
  }) {
    final tube = _tube(s, e, h, w0, w1);
    c.drawPath(tube.outline, _line(ink, .1));
    c.drawPath(
      tube.outline,
      _fill(Color.lerp(_crimson, const Color(0xffdc3038), fury * .5)!),
    );
    c.save();
    c.clipPath(tube.outline);
    // Which side faces the light: the upper one.
    final mi = tube.mid.length ~/ 2;
    final lit = tube.normal[mi].dy < 0 ? 1.0 : -1.0;
    final shade = Path(), rim = Path();
    for (var i = 0; i < tube.mid.length; i++) {
      final a = tube.mid[i] - tube.normal[i] * lit * .15;
      final b = tube.mid[i] + tube.normal[i] * lit * .12;
      i == 0 ? shade.moveTo(a.dx, a.dy) : shade.lineTo(a.dx, a.dy);
      i == 0 ? rim.moveTo(b.dx, b.dy) : rim.lineTo(b.dx, b.dy);
    }
    c.drawPath(shade, _line(_coatDark.withValues(alpha: .75), .2));
    c.drawPath(rim, _line(_coatLit.withValues(alpha: .95), .075));
    // Two gold rank bands round the upper sleeve.
    for (final i in const [3, 5]) {
      final k = tube.mid[i], nk = tube.normal[i];
      c.drawLine(k - nk * .3, k + nk * .3, _line(ink, .075));
      c.drawLine(k - nk * .3, k + nk * .3, _line(_gold, .04));
    }
    // Creases where the elbow folds.
    final k = tube.mid[mi];
    final nk = tube.normal[mi];
    final tk = Offset(nk.dy, -nk.dx);
    for (final o in const [-.05, .04]) {
      final base = k + tk * o;
      c.drawLine(
        base - nk * .2,
        base + nk * .05,
        _line(_coatDeep.withValues(alpha: .75), .03),
      );
    }
    c.restore();
  }

  /// A turned-back cuff and a shirt frill, at the wrist of the last sleeve.
  static void _cuff(Canvas c, Offset e, Offset h, {double width = .36}) {
    final dir = (h - e) / math.max((h - e).distance, 1e-6);
    final nrm = Offset(-dir.dy, dir.dx);
    final wrist = h - dir * .02;
    // A shirt frill puffs out of the cuff.
    for (var i = -2; i <= 2; i++) {
      final at = wrist + dir * .1 + nrm * (i * .06);
      c.drawCircle(at, .058, _fill(ink));
    }
    for (var i = -2; i <= 2; i++) {
      final at = wrist + dir * .1 + nrm * (i * .06);
      c.drawCircle(at, .04, _fill(i.isEven ? _cream : _creamShade));
    }
    final a = wrist - dir * .17, b = wrist + dir * .01;
    final cuff = Path()
      ..moveTo((a + nrm * width / 2).dx, (a + nrm * width / 2).dy)
      ..lineTo(
        (b + nrm * (width / 2 + .02)).dx,
        (b + nrm * (width / 2 + .02)).dy,
      )
      ..lineTo(
        (b - nrm * (width / 2 + .02)).dx,
        (b - nrm * (width / 2 + .02)).dy,
      )
      ..lineTo((a - nrm * width / 2).dx, (a - nrm * width / 2).dy)
      ..close();
    c.drawPath(cuff, _line(ink, .09));
    c.drawPath(cuff, _fill(_facing));
    c.drawLine(
      a + nrm * (width / 2 - .03),
      b + nrm * (width / 2 - .03),
      _line(_facingLit.withValues(alpha: .9), .035),
    );
    // Gold braid along the cuff's edge and two buttons.
    c.drawLine(
      b + nrm * (width / 2 - .01),
      b - nrm * (width / 2 - .01),
      _line(ink, .07),
    );
    c.drawLine(
      b + nrm * (width / 2 - .01),
      b - nrm * (width / 2 - .01),
      _line(_gold, .04),
    );
    c.drawLine(
      a + nrm * (width / 2 - .01),
      a - nrm * (width / 2 - .01),
      _line(_gold.withValues(alpha: .8), .025),
    );
    for (final o in const [-.07, .07]) {
      final at = wrist - dir * .08 + nrm * o;
      c.drawCircle(at, .036, _fill(ink));
      c.drawCircle(at, .024, _fill(_gold));
    }
  }

  // --------------------------------------------------------------- torch --

  static final _stickRRect = RRect.fromRectAndRadius(
    const Rect.fromLTRB(-.3, -.06, .46, .06),
    const Radius.circular(.05),
  );
  static final _stickPaint = _gradient(
    _stickRRect.outerRect,
    const [_woodLit, _wood, _woodDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final _ragPath = Path()
    ..moveTo(.34, -.07)
    ..cubicTo(.36, -.17, .5, -.18, .58, -.1)
    ..cubicTo(.66, -.03, .66, .03, .58, .1)
    ..cubicTo(.5, .18, .36, .17, .34, .07)
    ..close();
  static final _cupPath = Path()
    ..moveTo(-.02, -.15)
    ..lineTo(.2, -.11)
    ..lineTo(.2, .11)
    ..lineTo(-.02, .15)
    ..close();
  static final _cupPaint = _gradient(
    _cupPath.getBounds(),
    const [_leatherLit, _leather, _leatherDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final _collarRRect = RRect.fromRectAndRadius(
    const Rect.fromLTRB(.19, -.105, .27, .105),
    const Radius.circular(.025),
  );
  static final _collarPaint = _gradient(
    _collarRRect.outerRect,
    const [_goldLight, _gold, _goldDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static void torchArm(Canvas c, CaptainBodyPose p) {
    final t = -p.breath - p.hunch;
    final shoulder = Offset(-.94, .22 + t);
    final hand = p.torchHand;
    final elbow =
        hand +
        Offset.lerp(
          const Offset(.04, .42),
          const Offset(-.36, .34),
          p.torchUp,
        )!;
    _sleeve(c, shoulder, elbow, hand, fury: p.fury);
    _cuff(c, elbow, hand);
    final dir = Offset(math.cos(p.torchAngle), math.sin(p.torchAngle));
    final head = hand + dir * torchReach;
    // The torch: a tarred stick, a lashed rag head, then the fist over it.
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(p.torchAngle);
    _torchStick(c, p);
    c.restore();
    _paintFlame(c, head, p);
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(p.torchAngle);
    _fist(c);
    c.restore();
  }

  static void _torchStick(Canvas c, CaptainBodyPose p) {
    // Local frame: +x runs along the torch, from the butt toward the flame.
    c.drawRRect(_stickRRect.inflate(.03), _fill(ink));
    c.drawRRect(_stickRRect, _stickPaint);
    c.drawLine(
      const Offset(-.22, -.015),
      const Offset(.3, -.02),
      _line(_woodDark.withValues(alpha: .7), .014),
    );
    // A brass ferrule on the butt.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-.32, -.075, -.24, .075),
        const Radius.circular(.025),
      ),
      _fill(ink),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-.31, -.06, -.25, .06),
        const Radius.circular(.02),
      ),
      _fill(_gold),
    );
    // The rag head: tarred cloth bound with cord, glowing at the crown.
    final rag = _ragPath;
    final heat = math.min(1.0, .5 + p.charge * .5 + p.fury * .3 + p.roar * .3);
    c.drawPath(rag, _line(ink, .07));
    c.drawPath(
      rag,
      _gradient(
        rag.getBounds(),
        [
          const Color(0xff2e1c1c),
          const Color(0xff5b3a2c),
          Color.lerp(const Color(0xff7a4a34), _ember, heat * .8)!,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
    c.save();
    c.clipPath(rag);
    for (final x in const [.4, .47, .54]) {
      c.drawLine(
        Offset(x - .03, -.17),
        Offset(x + .04, .17),
        _line(ink.withValues(alpha: .7), .028),
      );
    }
    c.restore();
    // Cord binding at the neck and a hot crown.
    c.drawLine(
      const Offset(.335, -.075),
      const Offset(.335, .075),
      _line(_leatherLit, .04),
    );
    c.drawArc(
      const Rect.fromLTRB(.44, -.13, .68, .13),
      -1.1,
      2.2,
      false,
      _line(Color.lerp(_flame, _ember, p.fury)!.withValues(alpha: .9), .04),
    );
    // A drip of tar down the stick.
    c.drawOval(
      Rect.fromCenter(center: const Offset(.3, .06), width: .05, height: .09),
      _fill(const Color(0xff2e1c1c)),
    );
  }

  /// The fist wraps the stick: knuckled fingers and a thumb along it.
  static void _fist(Canvas c) {
    final palm = Rect.fromCenter(center: Offset.zero, width: .26, height: .3);
    c.drawRRect(
      RRect.fromRectAndRadius(palm.inflate(.03), const Radius.circular(.1)),
      _fill(ink),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(palm, const Radius.circular(.08)),
      _fill(_skinShade),
    );
    // Four fingers, each a rounded roll across the stick.
    for (var i = 0; i < 4; i++) {
      final x = -.1 + i * .066;
      final finger = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - .036, -.15, x + .036, .1),
        const Radius.circular(.036),
      );
      c.drawRRect(finger.inflate(.02), _fill(ink));
      c.drawRRect(finger, _fill(_skin));
      c.drawLine(
        Offset(x - .016, -.12),
        Offset(x - .016, .06),
        _line(_skinLit, .022),
      );
      c.drawLine(
        Offset(x + .024, -.1),
        Offset(x + .024, .08),
        _line(_skinShade, .02),
      );
    }
    // The thumb pinning the stick from above.
    final thumb = Path()
      ..moveTo(-.1, -.11)
      ..quadraticBezierTo(-.02, -.2, .1, -.13)
      ..quadraticBezierTo(.02, -.09, -.1, -.06)
      ..close();
    c.drawPath(thumb, _line(ink, .05));
    c.drawPath(thumb, _fill(_skinLit));
  }

  /// The torch's flame: layered tongues that always lick upward, a halo,
  /// and a few embers drifting off deterministically.
  static void _paintFlame(Canvas c, Offset at, CaptainBodyPose p) {
    final t = p.time;
    final size = p.flameSize;
    final hot = p.fury > 0;
    final glowR = .95 * size;
    c.drawCircle(
      at + Offset(0, -.15 * size),
      glowR,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                (hot ? _ember : _flame).withValues(alpha: .5),
                _flame.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: at + Offset(0, -.15 * size),
                radius: glowR,
              ),
            ),
    );
    double lick(double k) =>
        math.sin(t * 13 + k) * .03 + math.sin(t * 21 + k * 1.7) * .02;
    Path tongue(double x, double w, double h, double bend) {
      final base = at + Offset(x, 0);
      return Path()
        ..moveTo(base.dx - w, base.dy)
        ..cubicTo(
          base.dx - w * 1.35,
          base.dy - h * .4,
          base.dx - w * .3 + bend * .5,
          base.dy - h * .72,
          base.dx + bend,
          base.dy - h,
        )
        ..cubicTo(
          base.dx + w * .6 + bend * .5,
          base.dy - h * .62,
          base.dx + w * 1.4,
          base.dy - h * .4,
          base.dx + w,
          base.dy,
        )
        ..quadraticBezierTo(base.dx, base.dy + w * .9, base.dx - w, base.dy)
        ..close();
    }

    final l0 = lick(0), l1 = lick(1.3), l2 = lick(2.6);
    final side1 = tongue(-.1 * size, .07 * size, (.3 + l1) * size, -.05 - l1);
    final side2 = tongue(.1 * size, .065 * size, (.26 + l2) * size, .05 + l2);
    final main = tongue(0, .15 * size, (.5 + l0) * size, l0 * 2);
    final outer = hot ? _ember : _flameDeep;
    for (final path in [side1, side2, main]) {
      c.drawPath(path, _line(ink, .06));
    }
    for (final path in [side1, side2, main]) {
      c.drawPath(path, _fill(outer));
    }
    c.drawPath(
      tongue(-.01 * size, .11 * size, (.4 + l0) * size, l0 * 1.6),
      _fill(hot ? _flameDeep : _flame),
    );
    c.drawPath(
      tongue(-.005 * size, .075 * size, (.29 + l0 * .8) * size, l0 * 1.2),
      _fill(_flameYellow),
    );
    c.drawPath(
      tongue(0, .04 * size, (.16 + l0 * .5) * size, l0),
      _fill(_flameCore),
    );
    if (p.dizzy) return;
    // Embers rise off the flame and fade: a fixed ring of slots, each on its
    // own phase, so any frame stands alone.
    for (var i = 0; i < 6; i++) {
      final phase = t == 0
          ? (i * .17 + .08) % 1
          : (t * (.5 + _hash(i) * .25) + i * .167 + _hash(i + 9)) % 1;
      final sway = math.sin(phase * 7 + i * 1.9) * .1 * (.3 + phase);
      final pos =
          at +
          Offset(
            (_hash(i + 3) - .5) * .18 * size + sway,
            -(.3 + phase * .78) * math.min(size, 1.4),
          );
      final r = (.042 - phase * .028) * (.8 + size * .2);
      final alpha = (1 - phase * phase).clamp(0.0, 1.0);
      c.drawCircle(pos, r + .012, _fill(ink.withValues(alpha: .5 * alpha)));
      c.drawCircle(
        pos,
        r,
        _fill(
          Color.lerp(_flameYellow, _ember, phase)!.withValues(alpha: alpha),
        ),
      );
    }
  }

  /// The torch's warm light cast over everything already in the layer (the
  /// beard, the coat, the hat): it only tints where the captain has pixels.
  static void torchLight(Canvas c, CaptainBodyPose p) {
    final at = p.flameAt + Offset(0, -.2 * p.flameSize);
    final flicker = p.time == 0 ? 0.0 : math.sin(p.time * 15) * .03;
    final k = (p.dizzy ? .3 : 1.0) * (1 + p.fury * .25 + p.roar * .3);
    final r = 1.25 * p.flameSize.clamp(.6, 1.4);
    final alpha = ((.34 + flicker) * k).clamp(0.0, .6);
    c.drawCircle(
      at,
      r,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = RadialGradient(
          colors: [
            (p.fury > 0 ? const Color(0xffff7a3a) : _warm).withValues(
              alpha: alpha,
            ),
            _warm.withValues(alpha: alpha * .4),
            _warm.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  // ---------------------------------------------------------------- hook --

  /// The hook arm's sleeve, epaulette and cuff: drawn behind the head, the
  /// hat and the parrot.
  static void hookSleeve(Canvas c, CaptainBodyPose p) {
    final t = -p.breath - p.hunch;
    final shoulder = Offset(.92, .15 + t);
    final hand = p.hookHand;
    final elbow = hand + _hookElbow(p);
    _sleeve(c, shoulder, elbow, hand, fury: p.fury);
    _epaulette(c, Offset(.92, .0 + t), 1, p);
    _cuff(c, elbow, hand);
  }

  static Offset _hookElbow(CaptainBodyPose p) =>
      Offset.lerp(const Offset(.2, -.26), const Offset(.16, .52), p.hookLift)!;

  /// The leather cup and the steel hook, drawn over everything else so the
  /// raised claw always reads against the sails.
  static void hookClaw(Canvas c, CaptainBodyPose p) {
    // The hook points forward, toward the bird, and curls up; the wrist
    // twists it up to a claw when the arm is raised.
    c.save();
    c.translate(p.hookHand.dx, p.hookHand.dy);
    c.rotate(-p.hookTwist);
    c.scale(-1.12, 1.12);
    _hook(c, p);
    c.restore();
  }

  /// The hook in its own frame: +x along the shank, curling toward -y.
  static void _hook(Canvas c, CaptainBodyPose p) {
    // A leather cup, strapped and riveted, on the wrist.
    c.drawPath(_cupPath, _line(ink, .07));
    c.drawPath(_cupPath, _cupPaint);
    for (final x in const [.04, .14]) {
      final w = _mix(.15, .11, (x + .02) / .22);
      c.drawLine(Offset(x, -w), Offset(x, w), _line(ink, .05));
      c.drawLine(Offset(x, -w), Offset(x, w), _line(_leatherDeep, .03));
      c.drawCircle(Offset(x, -w * .55), .016, _fill(_gold));
      c.drawCircle(Offset(x, w * .55), .016, _fill(_gold));
    }
    // A brass collar where the steel is socketed.
    c.drawRRect(_collarRRect.inflate(.02), _fill(ink));
    c.drawRRect(_collarRRect, _collarPaint);
    // The steel: a tapering shank that sweeps up into a sharp, barbed curl.
    c.drawPath(_hookSteel, _line(ink, .07));
    c.drawPath(_hookSteel, _steelPaint);
    // A bright polish streak along the outer curve, and a dark inner edge.
    c.drawPath(_hookGleam, _line(_white, .026));
    c.drawPath(_hookShade, _line(_steelDark.withValues(alpha: .8), .022));
    // A twinkle winks off the polished bend now and then.
    final s = p.time == 0
        ? .55
        : math.max(0.0, 1 - ((p.time * .33 + .2) % 1 - .5).abs() * 9) * .9 + .3;
    _twinkle(c, const Offset(.6, -.28), .09 * s);
  }

  // The steel's outline is the same in every pose.
  static final Path _hookSteel = () {
    const n = 18;
    Offset centre(double t) {
      // A cubic from the collar, forward and then up and back on itself.
      final u = 1 - t;
      const a = Offset(.25, 0),
          b = Offset(.62, .03),
          c = Offset(.8, -.34),
          d = Offset(.5, -.5);
      return a * (u * u * u) +
          b * (3 * u * u * t) +
          c * (3 * u * t * t) +
          d * (t * t * t);
    }

    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final p0 = centre(math.max(t - .01, 0)),
          p1 = centre(math.min(t + .01, 1));
      final d = p1 - p0;
      final nrm = Offset(-d.dy, d.dx) / d.distance;
      // Fat in the shank, thinning to a needle at the point.
      final half = _mix(.075, .008, math.pow(t, 1.4).toDouble());
      final at = centre(t);
      left.add(at + nrm * half);
      right.add(at - nrm * half);
    }
    return Path()..addPolygon([...left, ...right.reversed], true);
  }();

  static final _steelPaint = _gradient(
    _hookSteel.getBounds(),
    const [_steel, _steelMid, _steelDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0, .45, 1],
  );

  static final Path _hookGleam = () {
    final path = Path()..moveTo(.3, -.035);
    path.cubicTo(.56, -.04, .74, -.1, .72, -.3);
    return path;
  }();

  static final Path _hookShade = () {
    final path = Path()..moveTo(.34, .045);
    path.cubicTo(.6, .06, .72, -.06, .66, -.24);
    return path;
  }();

  static void _twinkle(Canvas c, Offset at, double r) {
    if (r <= .01) return;
    final star = Path()
      ..moveTo(at.dx, at.dy - r * 1.5)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + r * 1.5, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r * 1.5)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - r * 1.5, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r * 1.5)
      ..close();
    c.drawPath(star, _fill(_white));
  }
}
