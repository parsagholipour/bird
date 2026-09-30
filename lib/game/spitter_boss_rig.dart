import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'spitter_boss_motion.dart';

/// The Spitter King, brewer of the swarm: a jade monarch beetle who wears a
/// crown of glowing flasks, carries his whole still as a glass-bellied
/// abdomen and spits what it brews through a brass trumpet mouth.
///
/// Four materials carry the character: jade chitin, brass fittings, glass,
/// and the acid inside it, which runs mint-green and turns amber in fury.
/// Authored in hit-radius units, facing left, with the mouth fixed at
/// (-1.05, 0). Every part is a pure function of the boss state.
abstract final class SpitterBossRig {
  static const acid = Color(0xff6fe3a4), mint = Color(0xffd4ffc1);
  static const ink = Color(0xff223437), gold = Color(0xffffd878);

  /// Where the crown sits on the head (its band's center), and the box the
  /// detached crown needs when the defeat throws it clear.
  static const crownAnchor = Offset(-.46, -.8);
  static const crownBounds = Rect.fromLTRB(-.66, -.84, .66, .2);

  /// The eye's center inside its monocle, for the entrance's glowing eyes.
  static const eyeCenter = Offset(-.58, -.38);

  static const _brass = Color(0xffe6a93f), _copper = Color(0xffc57a47);
  static const _rust = Color(0xff714833), _cream = Color(0xffffefcb);
  static const _cork = Color(0xffd9a273), _rage = Color(0xffffb65f);
  static const _redPupil = Color(0xffe0655a), _gem = Color(0xffef7fa0);
  // Shared with the spitter minion so the King reads as its grand relative.
  static const _deep = Color(0xff1c4d45), _jade = Color(0xff2a9474);
  static const _leaf = Color(0xff7fd4a0), _lime = Color(0xffc3eba2);
  static const _shade = Color(0xff2d5f55), _white = Color(0xffffffff);
  static const _lid = Color(0xff3f9c80), _glass = Color(0xffcdeee2);

  static final _calm = _Brew(mint, acid, const Color(0xff238276));
  static final _hot = _Brew(
    const Color(0xfffff0b8),
    _rage,
    const Color(0xffd0602a),
  );

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  static Paint _gradient(
    Rect rect,
    List<Color> colors, {
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) => Paint()
    ..shader = LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
    ).createShader(rect);
  static Paint _brassOn(Rect rect) =>
      _gradient(rect, const [gold, _brass, _copper]);

  /// A cached shader at a moment's strength: the paint's alpha scales it.
  static Paint _shaded(Shader shader, double alpha) => Paint()
    ..shader = shader
    ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0));

  /// A lit edge on the lower right: [path]'s outline, nudged up and left and
  /// clipped to the shape, leaves a bounce-light sliver along the far side.
  static void _rim(Canvas c, Path path, Color color, double width) {
    c.save();
    c.clipPath(path);
    c.translate(-.045, -.045);
    c.drawPath(path, _line(color, width));
    c.restore();
  }

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
  static const _bounds = Rect.fromLTRB(-2.2, -2.3, 2.5, 1.7);

  static void _paintBody(Canvas c, SkyBoss boss, BossMotion m, double lookY) {
    final p = SpitterBossMotion(m);
    final fury = boss.enraged;
    final brew = fury ? _hot : _calm;
    final aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    _halo(c, p, brew, m.silhouette);
    _wing(c, p, far: true);
    _elytron(c, p, far: true);
    _wing(c, p, far: false);
    _elytron(c, p, far: false);
    _legs(c, p, far: true);
    _abdomen(c, p, brew);
    _thorax(c, p);
    _hose(c, p, brew);
    _legs(c, p, far: false);
    _armLimb(c, p);
    _head(c, p, brew, aim, fury: fury);
    if (!m.defeated || m.death < .3) {
      c.save();
      c.translate(crownAnchor.dx, crownAnchor.dy - p.crownLift);
      c.rotate(p.crownTilt);
      c.scale(_crownScale);
      _crownArt(c, brew, p.level, p.rattle, math.max(p.glint, p.summon));
      _crownSteam(c, p, brew);
      c.restore();
    }
    _claw(c, p);
  }

  /// A soft bloom behind the vat: the brew lights the sky around the King.
  static void _halo(Canvas c, SpitterBossMotion p, _Brew brew, double veil) {
    final strength = (.14 + p.heat * .32) * (1 - veil) * (1 - p.collapse * .5);
    if (strength <= .01) return;
    c.drawCircle(_haloAt, _haloRadius, _shaded(brew.halo, strength));
  }

  static const _haloAt = Offset(.75, .45), _haloRadius = 1.5;

  /// A puff of steam: a soft disc with a faint cartoon outline.
  static void _puff(Canvas c, Offset at, double r, Color tint, double alpha) {
    if (alpha <= .01) return;
    c.drawCircle(at, r, _fill(tint.withValues(alpha: alpha)));
    c.drawCircle(at, r, _line(ink.withValues(alpha: alpha * .45), .02));
  }

  // ------------------------------------------------------------- wings --

  static final _wingPath = Path()
    ..moveTo(0, 0)
    ..cubicTo(.35, -.2, .95, -.5, 1.55, -.42)
    ..cubicTo(1.86, -.38, 2.0, -.1, 1.9, .1)
    ..cubicTo(1.7, .34, 1.1, .46, .58, .36)
    ..cubicTo(.3, .28, .1, .16, 0, 0)
    ..close();
  static final _wingVeins = Path()
    ..moveTo(.06, -.02)
    ..cubicTo(.4, -.16, .95, -.38, 1.55, -.34)
    ..moveTo(.14, -.03)
    ..quadraticBezierTo(1.0, -.1, 1.82, -.01)
    ..moveTo(.14, -.01)
    ..quadraticBezierTo(.9, .07, 1.68, .22)
    ..moveTo(.12, .0)
    ..quadraticBezierTo(.6, .16, 1.15, .36);
  static final _wingGloss = Path()
    ..moveTo(.5, -.24)
    ..quadraticBezierTo(1.1, -.44, 1.62, -.32);
  // The leading edge is gilded, like the wing cases.
  static final _wingEdge = Path()
    ..moveTo(.04, -.02)
    ..cubicTo(.36, -.19, .94, -.49, 1.54, -.41);
  static final _nearWingFill = _gradient(
    const Rect.fromLTWH(0, -.5, 2, 1),
    const [Color(0xe6f2fff0), Color(0xb39fd6bf)],
  );
  static final _farWingFill = _gradient(
    const Rect.fromLTWH(0, -.5, 2, 1),
    const [Color(0x99cfeee0), Color(0x8878b9a2)],
  );

  static void _wing(Canvas c, SpitterBossMotion p, {required bool far}) {
    final stroke = p.wingStroke(far: far);
    c.save();
    c.translate(far ? .1 : .2, far ? -.4 : -.32);
    c.rotate(-.42 + stroke * .34 + p.fold * 1.05 + (far ? -.16 : 0));
    c.scale((far ? .92 : 1) * (1 - p.fold * .5), 1 - p.fold * .25);
    c.drawPath(_wingPath, far ? _farWingFill : _nearWingFill);
    c.drawPath(_wingPath, _line(far ? _shade : ink, .05));
    c.drawPath(
      _wingVeins,
      _line(const Color(0xff5f9a86).withValues(alpha: far ? .5 : .8), .028),
    );
    if (!far) {
      c.drawPath(_wingEdge, _line(gold.withValues(alpha: .85), .03));
      c.drawPath(
        _wingGloss,
        _line(const Color(0xfff4fff6).withValues(alpha: .75), .05),
      );
    }
    c.restore();
  }

  // -------------------------------------------------------- wing cases --

  static final _elytronPath = Path()
    ..moveTo(0, .05)
    ..cubicTo(.08, -.34, .5, -.52, .95, -.4)
    ..cubicTo(1.28, -.32, 1.52, -.12, 1.5, .06)
    ..cubicTo(1.2, .28, .5, .34, 0, .22)
    ..close();
  static final _elytronTrim = Path()
    ..moveTo(.1, -.2)
    ..cubicTo(.22, -.36, .6, -.44, .95, -.32)
    ..cubicTo(1.24, -.24, 1.4, -.08, 1.4, .04);
  static final _elytronGrooves = Path()
    ..moveTo(.16, .02)
    ..cubicTo(.5, -.08, 1.0, -.06, 1.34, .04)
    ..moveTo(.16, .13)
    ..cubicTo(.5, .12, .95, .16, 1.24, .18);
  static final _elytronGloss = Path()
    ..moveTo(.3, -.26)
    ..quadraticBezierTo(.62, -.36, .9, -.29);
  // Gold-tipped thorns along the crest: the royal serration of the mantle.
  static final _elytronThorns = Path()
    ..moveTo(.12, -.3)
    ..lineTo(.3, -.6)
    ..lineTo(.3, -.34)
    ..close()
    ..moveTo(.42, -.4)
    ..lineTo(.64, -.7)
    ..lineTo(.64, -.44)
    ..close()
    ..moveTo(.74, -.42)
    ..lineTo(.98, -.66)
    ..lineTo(.98, -.4)
    ..close();
  // A gilded drop crest on the wing case: the King's coat of arms.
  static final _elytronCrest = Path()
    ..moveTo(.62, -.2)
    ..cubicTo(.66, -.12, .72, -.08, .72, -.02)
    ..cubicTo(.72, .04, .67, .07, .62, .07)
    ..cubicTo(.57, .07, .52, .04, .52, -.02)
    ..cubicTo(.52, -.08, .58, -.12, .62, -.2)
    ..close();
  // Old duels: a few scratches across the shell.
  static final _elytronScratches = Path()
    ..moveTo(.98, -.02)
    ..lineTo(1.1, -.16)
    ..moveTo(1.05, .04)
    ..lineTo(1.18, -.08);
  static final _elytronFill = _gradient(
    const Rect.fromLTWH(0, -.5, 1.5, .85),
    const [_leaf, _jade, _deep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final _elytronFarFill = _gradient(
    const Rect.fromLTWH(0, -.5, 1.5, .85),
    const [_jade, _deep, Color(0xff15383a)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static void _elytron(Canvas c, SpitterBossMotion p, {required bool far}) {
    // Raised like a mantle in flight; they drop over the back when the wings
    // fold, and settle a little with every windup.
    c.save();
    c.translate(far ? .1 : .12, far ? -.36 : -.34);
    c.rotate((far ? -.78 : -.72) + p.fold * .8 + p.rattle * .012 + p.breath);
    c.scale(far ? .95 : 1);
    c.drawPath(_elytronPath, far ? _elytronFarFill : _elytronFill);
    if (!far) {
      _rim(c, _elytronPath, _lime.withValues(alpha: .5), .12);
      c.drawPath(_elytronThorns, _fill(_brass));
      c.drawPath(_elytronThorns, _line(ink, .06));
    }
    c.drawPath(_elytronPath, _line(ink, .085));
    if (!far) {
      c.drawPath(_elytronTrim, _line(gold, .05));
      c.drawPath(_elytronGrooves, _line(_deep.withValues(alpha: .55), .03));
      c.drawPath(
        _elytronGloss,
        _line(const Color(0xffe4fbd6).withValues(alpha: .85), .06),
      );
      c.drawPath(_elytronCrest, _fill(gold));
      c.drawPath(_elytronCrest, _line(ink, .035));
      c.drawPath(_elytronScratches, _line(_lime.withValues(alpha: .7), .03));
    }
    c.restore();
  }

  // ----------------------------------------------------------- abdomen --

  static final _vatGlass = Path()
    ..moveTo(.2, .04)
    ..cubicTo(.4, -.3, .98, -.34, 1.2, .0)
    ..cubicTo(1.44, .34, 1.36, .84, .98, 1.0)
    ..cubicTo(.6, 1.14, .18, .9, .16, .5)
    ..cubicTo(.16, .3, .14, .18, .2, .04)
    ..close();
  static final _vatCracks = Path()
    ..moveTo(1.04, -.1)
    ..lineTo(.92, .08)
    ..lineTo(1.04, .22)
    ..lineTo(.9, .4)
    ..lineTo(.98, .55)
    ..moveTo(.92, .08)
    ..lineTo(.76, .12)
    ..moveTo(1.04, .22)
    ..lineTo(1.22, .28)
    ..moveTo(.9, .4)
    ..lineTo(.72, .46);
  static final _vatSheen = Path()
    ..moveTo(.3, .0)
    ..cubicTo(.4, -.12, .55, -.2, .74, -.22);
  static final _vatBounce = Path()
    ..moveTo(1.2, .6)
    ..quadraticBezierTo(1.12, .82, .92, .9);
  static final _belt = Path()
    ..moveTo(.17, .5)
    ..quadraticBezierTo(.78, .7, 1.39, .5);
  static final _beltGloss = Path()
    ..moveTo(.22, .47)
    ..quadraticBezierTo(.78, .65, 1.34, .47);
  static final _vatGlassFill = _gradient(
    const Rect.fromLTWH(.1, -.3, 1.3, 1.3),
    const [Color(0xffe6faf1), Color(0xffbfe8d9), Color(0xff92cdb8)],
  );
  static final _vatShade = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-.35, -.45),
      radius: 1.05,
      colors: [Color(0x00000000), Color(0x00000000), Color(0x59173f3b)],
      stops: [0, .55, 1],
    ).createShader(const Rect.fromLTWH(.1, -.3, 1.3, 1.3));

  /// The still: a glass-bellied abdomen in a brass cage, with its pressure
  /// dial, relief valve, tailpipe and tap. It hangs from the thorax.
  static void _abdomen(Canvas c, SpitterBossMotion p, _Brew brew) {
    c.save();
    c.translate(.36, .15);
    c.rotate(p.vatRock);
    c.scale(.9);
    c.translate(-.2, -.04);
    _exhaust(c, p, brew);
    _tap(c, p, brew);
    _vat(c, p, brew);
    _dial(c, p);
    _valve(c, p, brew);
    c.restore();
  }

  static void _vat(Canvas c, SpitterBossMotion p, _Brew brew) {
    // Empty glass first, so the part above the liquid still reads as a vessel.
    c.drawPath(_vatGlass, _vatGlassFill);
    c.save();
    c.clipPath(_vatGlass);
    final top = 1.05 - p.level * 1.28;
    final wave = p.slosh;
    final surface = Path()
      ..moveTo(-.1, top + wave)
      ..cubicTo(.4, top - .07, .9, top + .07, 1.5, top - wave);
    final liquid = Path.from(surface)
      ..lineTo(1.5, 1.2)
      ..lineTo(-.1, 1.2)
      ..close();
    c.drawPath(liquid, brew.vatLiquid);
    // Inner glow: the brew lights itself from within.
    c.drawCircle(
      _vatGlowAt,
      _vatGlowRadius,
      _shaded(brew.vatGlow, .3 + p.heat * .5),
    );
    c.drawPath(
      surface.shift(const Offset(0, .045)),
      _line(brew.core.withValues(alpha: .5), .07),
    );
    c.drawPath(surface, _line(brew.core, .05));
    for (var i = 0; i < 6; i++) {
      final rise = p.bubble(i);
      final r = .05 + (i % 3) * .028;
      final at = Offset(
        .42 + i * .12 + math.sin(rise * 6 + i) * .03,
        .96 - rise * (.96 - top),
      );
      c.drawCircle(at, r, _fill(brew.core.withValues(alpha: .3)));
      c.drawCircle(at, r, _line(brew.core.withValues(alpha: .95), .026));
      c.drawCircle(at + Offset(-r * .35, -r * .35), r * .22, _fill(_white));
    }
    // The glass wall thickens toward the lower right.
    c.drawPath(_vatGlass, _vatShade);
    c.restore();
    c.drawPath(_vatGlass, _line(ink, .09));
    // Glass sheen from the upper left, and a bounce light low on the right.
    c.drawPath(_vatSheen, _line(_white.withValues(alpha: .9), .06));
    c.drawCircle(const Offset(.24, .18), .03, _fill(_white));
    c.drawPath(_vatBounce, _line(_white.withValues(alpha: .45), .05));
    if (p.cracks > .05) {
      // Cracks glow through: fury hairlines, then the burst.
      c.drawPath(_vatCracks, _line(ink, .1 * p.cracks));
      c.drawPath(
        _vatCracks,
        _line(brew.mid.withValues(alpha: p.cracks), .09 * p.cracks),
      );
      c.drawPath(
        _vatCracks,
        _line(_white.withValues(alpha: p.cracks), .035 * p.cracks),
      );
    }
    // A brass belt hoops the glass like a cage.
    c.drawPath(_belt, _line(ink, .17));
    c.drawPath(_belt, _line(_brass, .095));
    c.drawPath(_beltGloss, _line(gold, .03));
    for (final t in const [.15, .38, .85]) {
      c.drawCircle(
        Offset(.17 + 1.22 * t, .5 + math.sin(t * math.pi) * .1),
        .02,
        _fill(_rust),
      );
    }
  }

  static const _vatGlowAt = Offset(.72, .6), _vatGlowRadius = .7;

  static final _exhaustPipe = Path()
    ..moveTo(1.22, .34)
    ..quadraticBezierTo(1.46, .36, 1.56, .2);
  static final _exhaustGloss = Path()
    ..moveTo(1.28, .3)
    ..quadraticBezierTo(1.44, .3, 1.52, .18);
  static final _exhaustBell = Path()
    ..moveTo(0, -.08)
    ..cubicTo(.1, -.09, .16, -.13, .22, -.2)
    ..lineTo(.22, .2)
    ..cubicTo(.16, .13, .1, .09, 0, .08)
    ..close();
  static const _exhaustLip = Rect.fromLTWH(.17, -.2, .1, .4);
  static final _exhaustBellFill = _brassOn(_exhaustBell.getBounds());
  static final _exhaustLipFill = _brassOn(_exhaustLip);

  /// A brass tailpipe at the back, echoing the trumpet mouth: the still
  /// breathes out steam, thicker and faster as pressure builds, hot cream in
  /// fury.
  static void _exhaust(Canvas c, SpitterBossMotion p, _Brew brew) {
    c.drawPath(_exhaustPipe, _line(ink, .2));
    c.drawPath(_exhaustPipe, _line(_brass, .12));
    c.drawPath(_exhaustGloss, _line(gold, .03));
    c.save();
    c.translate(1.56, .2);
    c.rotate(-.9);
    c.drawPath(_exhaustBell, _exhaustBellFill);
    c.drawPath(_exhaustBell, _line(ink, .05));
    c.drawOval(_exhaustLip.inflate(.025), _fill(ink));
    c.drawOval(_exhaustLip, _exhaustLipFill);
    c.drawOval(
      Rect.fromCenter(center: const Offset(.22, 0), width: .06, height: .27),
      _fill(ink),
    );
    c.restore();
    if (p.motion.defeated) return;
    final amount = .35 + math.max(math.max(p.vents, p.pop), p.summon) * .65;
    final tint = identical(brew, _hot) ? _cream : mint;
    for (var i = 0; i < 4; i++) {
      final rise = p.bubble(i + 1);
      _puff(
        c,
        Offset(1.72 + rise * .5, -.02 - rise * .42 - i * .015),
        .06 + rise * .1 + amount * .03,
        tint,
        (1 - rise) * amount,
      );
    }
  }

  static final _tapBody = RRect.fromRectAndRadius(
    const Rect.fromLTWH(.66, .98, .2, .13),
    const Radius.circular(.04),
  );
  static final _tapFill = _brassOn(_tapBody.outerRect);
  static final _tapSpout = Path()
    ..moveTo(.76, 1.08)
    ..lineTo(.76, 1.2);

  /// A spigot under the belly, drawing off a drop now and then.
  static void _tap(Canvas c, SpitterBossMotion p, _Brew brew) {
    c.drawRRect(_tapBody.inflate(.025), _fill(ink));
    c.drawRRect(_tapBody, _tapFill);
    c.drawPath(_tapSpout, _line(ink, .12));
    c.drawPath(_tapSpout, _line(_brass, .06));
    if (p.motion.defeated) return;
    final drip = p.still ? .3 : (p.time * .45) % 1;
    final fade = 1 - drip * drip;
    final at = Offset(.76, 1.24 + drip * drip * .4);
    final size = .03 + math.min(drip * 2.5, 1) * .03;
    c.drawCircle(at, size + .02, _fill(ink.withValues(alpha: fade)));
    c.drawCircle(at, size, _fill(brew.mid.withValues(alpha: fade)));
  }

  static const _dialAt = Offset(.66, .68);
  static final _dialFill = _gradient(
    Rect.fromCircle(center: _dialAt, radius: .16),
    const [gold, _copper],
  );

  static void _dial(Canvas c, SpitterBossMotion p) {
    c.drawCircle(_dialAt, .19, _fill(ink));
    c.drawCircle(_dialAt, .155, _dialFill);
    c.drawCircle(_dialAt, .115, _fill(_cream));
    c.drawArc(
      Rect.fromCircle(center: _dialAt, radius: .085),
      -math.pi / 2 + .5,
      .7,
      false,
      _line(_redPupil, .035),
    );
    final needle =
        -.8 + p.charge * 1.7 + p.vents * .3 - p.recoil * .6 + p.rattle * .12;
    c.drawLine(
      _dialAt,
      _dialAt + Offset(math.sin(needle), -math.cos(needle)) * .09,
      _line(_rust, .035),
    );
    c.drawCircle(_dialAt, .028, _fill(ink));
  }

  static final _valveBarrel = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-.13, -.5, .26, .24),
    const Radius.circular(.05),
  );
  static final _valveCap = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-.17, -.7, .34, .12),
    const Radius.circular(.06),
  );
  static final _valveBarrelFill = _brassOn(_valveBarrel.outerRect);
  static final _valveCapFill = _gradient(_valveCap.outerRect, const [
    gold,
    _brass,
  ]);

  /// A spring-loaded pressure cap on the vat's crown: it lifts with the
  /// windup, blows off when fury begins and vents steam while hot.
  static void _valve(Canvas c, SpitterBossMotion p, _Brew brew) {
    final lift = p.pump + p.pop;
    c.save();
    c.translate(.7 + p.rattle * .012, 0);
    c.drawRRect(_valveBarrel.inflate(.025), _fill(ink));
    c.drawRRect(_valveBarrel, _valveBarrelFill);
    c.drawLine(const Offset(0, -.5), Offset(0, -.6 - lift), _line(ink, .1));
    c.drawLine(const Offset(0, -.5), Offset(0, -.6 - lift), _line(gold, .045));
    c.save();
    c.translate(0, -lift);
    c.drawRRect(_valveCap.inflate(.025), _fill(ink));
    c.drawRRect(_valveCap, _valveCapFill);
    c.restore();
    if ((p.vents > .1 || p.pop > 0) && !p.motion.defeated) {
      final amount = math.max(p.vents, p.pop);
      final tint = identical(brew, _hot) ? _cream : brew.mid;
      for (var i = 0; i < 3; i++) {
        final rise = p.bubble(i);
        _puff(
          c,
          Offset(-.05 + i * .07 + rise * .12, -.76 - lift - rise * .4),
          .035 + rise * .07,
          tint,
          (1 - rise) * amount * .6,
        );
      }
    }
    c.restore();
  }

  // ------------------------------------------------------------ thorax --

  static final _thoraxPath = Path()
    ..moveTo(-.46, .02)
    ..cubicTo(-.47, -.3, -.24, -.46, .04, -.44)
    ..cubicTo(.3, -.42, .38, -.2, .34, .08)
    ..cubicTo(.3, .34, .1, .48, -.14, .46)
    ..cubicTo(-.34, .44, -.45, .28, -.46, .02)
    ..close();
  // The dark dorsal plate over a pale belly: the minion's two-tone read.
  static final _thoraxPlate = Path()
    ..moveTo(-.6, -.6)
    ..lineTo(.5, -.6)
    ..lineTo(.5, .06)
    ..cubicTo(.2, .2, -.2, .18, -.6, -.02)
    ..close();
  static final _thoraxSeam = Path()
    ..moveTo(-.44, -.02)
    ..cubicTo(-.2, .18, .2, .2, .5, .06);
  static final _thoraxTrim = Path()
    ..moveTo(-.38, -.08)
    ..cubicTo(-.16, .1, .2, .12, .44, 0);
  static final _thoraxGrooves = Path()
    ..moveTo(-.26, .24)
    ..quadraticBezierTo(-.2, .36, -.24, .5)
    ..moveTo(.02, .26)
    ..quadraticBezierTo(.08, .38, .04, .5);
  static final _clamp = Path()
    ..moveTo(.3, -.2)
    ..cubicTo(.2, .06, .2, .4, .32, .62);
  static final _clampGloss = Path()
    ..moveTo(.27, -.16)
    ..cubicTo(.18, .06, .18, .38, .28, .58);
  static final _thoraxFill = _gradient(
    const Rect.fromLTWH(-.5, -.5, .9, 1),
    const [_lime, _leaf, Color(0xff3f9a7c)],
  );
  static final _plateFill = _gradient(
    const Rect.fromLTWH(-.5, -.5, .9, .7),
    const [Color(0xff5fae8c), _jade, _deep],
  );

  static void _thorax(Canvas c, SpitterBossMotion p) {
    c.save();
    c.translate(0, p.breath);
    c.drawPath(_thoraxPath, _thoraxFill);
    c.save();
    c.clipPath(_thoraxPath);
    c.drawPath(_thoraxPlate, _plateFill);
    c.drawPath(_thoraxSeam, _line(ink, .07));
    c.drawPath(_thoraxTrim, _line(gold, .04));
    c.drawPath(
      _thoraxGrooves,
      _line(const Color(0xff3f9a7c).withValues(alpha: .8), .05),
    );
    c.restore();
    _rim(c, _thoraxPath, _white.withValues(alpha: .35), .1);
    c.drawPath(_thoraxPath, _line(ink, .085));
    // A brass clamp ring where the abdomen plugs into the thorax.
    c.drawPath(_clamp, _line(ink, .2));
    c.drawPath(_clamp, _line(_brass, .12));
    c.drawPath(_clampGloss, _line(gold, .03));
    for (final t in const [.15, .5, .85]) {
      c.drawCircle(
        Offset(.3 - .1 * math.sin(t * math.pi) * 1.05 + t * .02, -.2 + .82 * t),
        .025,
        _fill(_rust),
      );
    }
    c.restore();
  }

  // -------------------------------------------------------------- legs --

  static void _legs(Canvas c, SpitterBossMotion p, {required bool far}) {
    for (var i = 0; i < 2; i++) {
      final root = Offset(-.3 + i * .3 + (far ? .18 : 0), .34 + i * .06);
      final trail = p.breath * (i.isEven ? 2 : -2);
      final tuck = p.charge * .1 - p.recoil * .08 + p.collapse * .2;
      final knee = Offset(root.dx + .06 + i * .03, .82 - tuck);
      final foot = Offset(
        root.dx + .24 + trail - p.collapse * .26,
        1.05 - tuck + (i == 1 ? .04 : 0) - p.collapse * .1,
      );
      final leg = Path()
        ..moveTo(root.dx, root.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy);
      c.drawPath(leg, _line(far ? _shade : ink, .14));
      if (!far) c.drawPath(leg, _line(_jade, .07));
      c.drawCircle(knee, .055, _fill(far ? _shade : _brass));
      if (!far) c.drawCircle(knee, .055, _line(ink, .035));
      c.drawOval(
        Rect.fromCenter(
          center: foot + const Offset(.03, 0),
          width: .2,
          height: .11,
        ),
        _fill(far ? _shade : ink),
      );
    }
  }

  // -------------------------------------------------------------- hose --

  static Offset _cubic(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }

  static void _hose(Canvas c, SpitterBossMotion p, _Brew brew) {
    const a = Offset(.34, .6), b = Offset(.1, .86);
    const cc = Offset(-.26, .78), d = Offset(-.36, .44);
    final hose = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(b.dx, b.dy + p.pump * .5, cc.dx, cc.dy, d.dx, d.dy);
    c.drawPath(hose, _line(ink, .15));
    c.drawPath(hose, _line(_glass, .09));
    c.drawPath(hose, _line(brew.mid.withValues(alpha: .4 + p.heat * .6), .05));
    // Beads of brew run up the tube toward the jowl.
    for (var i = 0; i < 3; i++) {
      final t = (p.still ? .2 : p.time * .5 + i / 3) % 1;
      c.drawCircle(
        _cubic(a, b + Offset(0, p.pump * .5), cc, d, t),
        .03,
        _fill(brew.core.withValues(alpha: .95)),
      );
    }
    for (final at in [a, d]) {
      c.drawCircle(at, .085, _fill(ink));
      c.drawCircle(at, .055, _fill(_brass));
    }
  }

  // -------------------------------------------------------------- head --

  static final _headPath = Path()
    ..moveTo(-.9, .0)
    ..cubicTo(-.98, -.44, -.82, -.86, -.48, -.86)
    ..cubicTo(-.16, -.86, .04, -.62, .02, -.28)
    ..cubicTo(.0, .08, -.14, .4, -.46, .42)
    ..cubicTo(-.74, .44, -.88, .28, -.9, .08)
    ..close();
  // A gilded cheek guard runs from the crown down to the jowl.
  static final _guard = Path()
    ..moveTo(-.1, -.66)
    ..cubicTo(.0, -.4, -.02, -.02, -.16, .24);
  static const _guardRivets = [
    Offset(-.05, -.5),
    Offset(-.03, -.2),
    Offset(-.09, .1),
  ];
  static final _headFill = _gradient(
    const Rect.fromLTWH(-.95, -.86, 1, 1.3),
    const [Color(0xffd3f3b8), Color(0xff8ad3a0), Color(0xff3f9c80)],
  );
  // Soft occlusion: the head over the thorax, and the crown band on the brow.
  static const _headShadowAt = Offset(-.02, .1);
  static final _headShadow = Paint()
    ..shader = const RadialGradient(
      colors: [Color(0x4d173f3b), Color(0x00173f3b)],
    ).createShader(Rect.fromCircle(center: _headShadowAt, radius: .6));
  static const _bandShadeRect = Rect.fromLTRB(-1, -.86, .1, -.5);
  static final _bandShade = _gradient(
    _bandShadeRect,
    const [Color(0x40173f3b), Color(0x00173f3b)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static void _head(
    Canvas c,
    SpitterBossMotion p,
    _Brew brew,
    double aim, {
    required bool fury,
  }) {
    c.drawCircle(_headShadowAt, .6, _headShadow);
    c.drawPath(_headPath, _headFill);
    c.save();
    c.clipPath(_headPath);
    c.drawRect(_bandShadeRect, _bandShade);
    c.restore();
    _rim(c, _headPath, _white.withValues(alpha: .35), .1);
    c.drawPath(_headPath, _line(ink, .085));
    // Jowl sac: the acid store swells and brightens through the windup.
    final jowl = Rect.fromCenter(
      center: Offset(-.4 - p.charge * .03, .27 + p.charge * .06),
      width: .5 + p.charge * .24 - p.recoil * .1,
      height: .3 + p.charge * .26 - p.recoil * .08,
    );
    c.drawOval(
      jowl,
      _gradient(jowl, [
        Color.lerp(brew.core, _cream, p.charge * .6)!,
        brew.mid,
        fury ? const Color(0xffc9713e) : _lid,
      ]),
    );
    c.drawOval(jowl, _line(ink, .055));
    c.drawArc(jowl.deflate(.07), 3.6, 1.35, false, _line(_cream, .045));
    c.drawPath(_guard, _line(ink, .11));
    c.drawPath(_guard, _line(_brass, .06));
    for (final at in _guardRivets) {
      c.drawCircle(at, .022, _fill(_rust));
    }
    _eye(c, p, aim, fury: fury);
    _mouth(c, p, brew);
  }

  static final _mouthBellFill = _brassOn(
    const Rect.fromLTRB(-1.05, -.3, -.86, .3),
  );
  static final _mouthLipFill = _brassOn(
    Rect.fromCenter(center: const Offset(-1.05, 0), width: .24, height: .62),
  );

  /// The brass trumpet mouth: it flares from the face and its dark throat
  /// stays centered on the projectile origin, so the spit never wanders
  /// through any pose. The bell swells and glows as the acid is driven up.
  static void _mouth(Canvas c, SpitterBossMotion p, _Brew brew) {
    final swell = 1 + p.charge * .24 + p.recoil * .1;
    // Tipped down a touch, like a tuba, so the bell shows its flare.
    c.save();
    c.translate(-1.05, 0);
    c.rotate(-.22);
    c.translate(1.05, 0);
    final bell = Path()
      ..moveTo(-.86, -.15 * swell)
      ..cubicTo(-.95, -.16 * swell, -1.0, -.2 * swell, -1.05, -.28 * swell)
      ..lineTo(-1.05, .28 * swell)
      ..cubicTo(-1.0, .2 * swell, -.95, .16 * swell, -.86, .15 * swell)
      ..close();
    c.drawPath(bell, _mouthBellFill);
    c.drawPath(bell, _line(ink, .05));
    c.drawLine(
      Offset(-.94, -.17 * swell),
      Offset(-.94, .17 * swell),
      _line(ink, .035),
    );
    final lip = Rect.fromCenter(
      center: const Offset(-1.05, 0),
      width: .24,
      height: .56 * swell,
    );
    c.drawOval(lip.inflate(.03), _fill(ink));
    c.drawOval(lip, _mouthLipFill);
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-1.05, 0),
        width: .17,
        height: .42 * swell + p.recoil * .06,
      ),
      _fill(ink),
    );
    if (p.charge > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(-1.05, 0),
          width: .06,
          height: .14 + p.charge * .14,
        ),
        _fill(brew.mid.withValues(alpha: p.charge)),
      );
    }
    c.restore();
  }

  static const _eyeBox = Rect.fromLTWH(-.87, -.66, .58, .56);
  static final _lens = _eyeBox.deflate(.02);
  static final _lensPath = Path()..addOval(_lens);
  static final _monocleFill = _brassOn(_eyeBox.inflate(.05));
  static final _lensCalm = _gradient(_lens, const [_cream, Color(0xffcdebc4)]);
  static final _lensFury = _gradient(_lens, const [_cream, Color(0xffffd3a8)]);
  static const _irisBox = Rect.fromLTWH(-.15, -.18, .3, .36);
  static final _irisCalm = _gradient(
    _irisBox,
    const [Color(0xffffc35a), Color(0xffe07a1d)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final _irisFury = _gradient(
    _irisBox,
    const [Color(0xffff9a6a), Color(0xffd63a3a)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final _brow = Path()
    ..moveTo(-.98, -.46)
    ..cubicTo(-.9, -.76, -.52, -.86, -.2, -.66)
    ..cubicTo(-.5, -.66, -.8, -.56, -.98, -.46)
    ..close();

  static void _eye(
    Canvas c,
    SpitterBossMotion p,
    double aim, {
    required bool fury,
  }) {
    // Monocle: a brass ring around the eye.
    c.drawOval(_eyeBox.inflate(.075), _fill(ink));
    c.drawOval(_eyeBox.inflate(.05), _monocleFill);
    c.drawOval(_eyeBox, _fill(ink));
    c.drawOval(_lens, fury ? _lensFury : _lensCalm);
    final squint = p.motion.defeated ? 0.0 : p.motion.hit;
    c.save();
    c.clipPath(_lensPath);
    if (p.motion.defeated) {
      c.drawLine(
        const Offset(-.76, -.54),
        const Offset(-.46, -.24),
        _line(ink, .07),
      );
      c.drawLine(
        const Offset(-.76, -.24),
        const Offset(-.46, -.54),
        _line(ink, .07),
      );
    } else {
      // An amber iris (hot red in fury) around a slit pupil, tracking the bird.
      c.save();
      c.translate(-.67 - aim.abs() * .015, -.38 + aim * .1);
      final size = (fury ? .9 : 1.0) * (1 - p.charge * .12);
      c.scale(size);
      c.drawOval(_irisBox, fury ? _irisFury : _irisCalm);
      c.drawOval(_irisBox, _line(ink, .025));
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: fury ? .08 : .12,
          height: .28,
        ),
        _fill(ink),
      );
      c.drawCircle(const Offset(-.06, -.09), .04, _fill(_cream));
      c.restore();
      // The lazy imperious lid sits low, and drops with the windup, hits and
      // the odd blink.
      final lid =
          _lens.top +
          _lens.height *
              (.34 +
                  p.charge * .12 +
                  squint * .34 +
                  (fury ? .06 : 0) +
                  // The lid follows the gaze: up lifts it, down lowers it.
                  (aim < 0 ? aim * .1 : aim * .05) +
                  p.blink * .66);
      final lidPath = Path()
        ..moveTo(_lens.left - .05, _lens.top - .1)
        ..lineTo(_lens.right + .05, _lens.top - .1)
        ..lineTo(_lens.right + .05, lid - .06)
        ..lineTo(_lens.left - .05, lid + .06)
        ..close();
      c.drawPath(lidPath, _fill(_lid));
      c.drawLine(
        Offset(_lens.left - .05, lid + .06),
        Offset(_lens.right + .05, lid - .06),
        _line(ink, .05),
      );
    }
    c.restore();
    c.drawArc(_lens.deflate(.03), 3.85, 1.4, false, _line(_cream, .03));
    if (p.motion.defeated) return;
    // Heavy brow ridge, gilded, dropping into a scowl with fury.
    final drop = p.charge * .05 + (fury ? .06 : 0);
    c.save();
    c.clipPath(_headPath);
    c.translate(0, drop * .8);
    c.drawPath(_brow, _fill(_deep));
    c.drawPath(_brow, _line(ink, .065));
    c.drawCircle(const Offset(-.82, -.63), .03, _fill(gold));
    c.restore();
  }

  // -------------------------------------------------------------- arms --

  /// The near arm: elbow, hand and the claw's turn. It rests folded under the
  /// chin, beckons the swarm out to the left and lifts the crown in the
  /// entrance's bow.
  static (Offset, Offset, double) _armPose(SpitterBossMotion p) {
    final gesture = math.max(p.tip, p.summon);
    return (
      Offset(-.2 - gesture * .42, .62 - gesture * .5 + p.collapse * .1),
      Offset(
        -.5 - p.summon * .72 - p.tip * .48 + p.recoil * .12,
        .7 - p.tip * 1.38 - p.summon * 1.12 + p.beckon + p.collapse * .12,
      ),
      // Pincers open toward the crown, or back toward the swarm's caller.
      -.25 + gesture * 2.85 + p.beckon * 3 + p.collapse * .8,
    );
  }

  /// The limb goes behind the head, so a raised arm never covers the face
  /// or the trumpet; the claw is drawn last, over the crown it lifts.
  static void _armLimb(Canvas c, SpitterBossMotion p) {
    final (elbow, hand, _) = _armPose(p);
    final arm = Path()
      ..moveTo(-.05, .3)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(hand.dx, hand.dy);
    c.drawPath(arm, _line(ink, .19));
    c.drawPath(arm, _line(_jade, .11));
    c.drawCircle(elbow, .07, _fill(_brass));
    c.drawCircle(elbow, .07, _line(ink, .04));
  }

  static final _clawPath = Path()
    ..moveTo(.05, -.11)
    ..quadraticBezierTo(-.2, -.22, -.32, -.04)
    ..quadraticBezierTo(-.2, -.07, -.1, -.015)
    ..quadraticBezierTo(-.2, .06, -.29, .1)
    ..quadraticBezierTo(-.16, .22, .05, .11)
    ..close();
  static final _clawGloss = Path()
    ..moveTo(-.02, -.09)
    ..quadraticBezierTo(-.16, -.15, -.24, -.06);

  static void _claw(Canvas c, SpitterBossMotion p) {
    final (_, hand, turn) = _armPose(p);
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(turn);
    // A chunky two-fingered pincer in a brass cuff.
    c.drawPath(_clawPath, _fill(_jade));
    c.drawPath(_clawPath, _line(ink, .06));
    c.drawPath(_clawGloss, _line(_lime.withValues(alpha: .8), .03));
    c.drawLine(
      const Offset(.06, -.11),
      const Offset(.06, .11),
      _line(ink, .13),
    );
    c.drawLine(
      const Offset(.06, -.09),
      const Offset(.06, .09),
      _line(_brass, .07),
    );
    c.restore();
  }

  // ------------------------------------------------------------- crown --

  /// The crown as a headwear object, for the defeat's tumbling debris.
  /// Origin: the center of the band.
  static void crown(Canvas c, {Color glow = acid}) {
    c.scale(_crownScale);
    _crownArt(c, glow == acid ? _calm : _hot, .6, 0, 0);
  }

  static const _crownScale = .88;
  static final _flaskCenter = _Flask(.21, .7, .075, .28);
  static final _flaskSide = _Flask(.17, .5, .065, .2);
  static final _crownBand = Path()
    ..moveTo(-.5, .1)
    ..quadraticBezierTo(0, -.1, .5, .1);
  static final _crownBandGloss = Path()
    ..moveTo(-.44, .05)
    ..quadraticBezierTo(0, -.14, .44, .05);
  static final _crownGem = Path()
    ..moveTo(0, -.12)
    ..lineTo(.09, -.02)
    ..lineTo(0, .1)
    ..lineTo(-.09, -.02)
    ..close();
  static const _gemAt = Offset(-.03, -.05);

  static void _crownArt(
    Canvas c,
    _Brew brew,
    double level,
    double rattle,
    double glint,
  ) {
    // Three corked flasks stand in the band as the crown's points.
    for (final (x, tilt, flask) in [
      (-.32, -.3, _flaskSide),
      (.32, .3, _flaskSide),
      (0.0, 0.0, _flaskCenter),
    ]) {
      c.save();
      c.translate(x, .02);
      c.rotate(tilt + rattle * .04 * (identical(flask, _flaskCenter) ? 1 : -1));
      c.drawPath(flask.path, _fill(const Color(0xf0e6fbf1)));
      c.save();
      c.clipPath(flask.path);
      final top = -flask.height * (.25 + level * .65);
      c.drawRect(Rect.fromLTRB(-.3, top, .3, .1), brew.flaskLiquid);
      c.drawLine(Offset(-.3, top), Offset(.3, top), _line(brew.core, .03));
      c.restore();
      c.drawPath(flask.path, _line(ink, .06));
      c.drawPath(flask.highlight, _line(_white.withValues(alpha: .85), .035));
      c.drawRRect(flask.cork.inflate(.02), _fill(ink));
      c.drawRRect(flask.cork, _fill(_cork));
      c.drawRect(flask.collar, _fill(_brass));
      c.restore();
    }
    c.drawPath(_crownBand, _line(ink, .23));
    c.drawPath(_crownBand, _line(_brass, .15));
    c.drawPath(_crownBandGloss, _line(gold, .04));
    // A rose jewel at the brow of the crown, glinting now and then.
    c.drawPath(_crownGem, _line(ink, .07));
    c.drawPath(_crownGem, _fill(_gem));
    c.drawCircle(_gemAt, .02, _fill(_cream));
    if (glint > 0) _sparkle(c, _gemAt, .2 * glint);
  }

  /// The crown boils over: steam curls off the corks while pressure is up.
  static void _crownSteam(Canvas c, SpitterBossMotion p, _Brew brew) {
    if (p.vents <= .1 || p.motion.defeated) return;
    final tint = identical(brew, _hot) ? _cream : mint;
    for (var i = 0; i < 3; i++) {
      final rise = p.bubble(i + 2);
      _puff(
        c,
        Offset(
          (i - 1) * .3 + rise * .08,
          -.86 + (i == 1 ? -.2 : 0) - rise * .35,
        ),
        .04 + rise * .08,
        tint,
        (1 - rise) * p.vents * .7,
      );
    }
  }

  /// A four-point glint.
  static void _sparkle(Canvas c, Offset at, double r) {
    final star = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx + r * .12, at.dy - r * .12, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx + r * .12, at.dy + r * .12, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx - r * .12, at.dy + r * .12, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx - r * .12, at.dy - r * .12, at.dx, at.dy - r)
      ..close();
    c.drawPath(star, _fill(_white));
  }
}

/// An Erlenmeyer flask standing on its base, bottom center at the origin.
class _Flask {
  _Flask(double baseHalf, this.height, double neckHalf, double neckHeight)
    : path = _outline(baseHalf, height, neckHalf, neckHeight),
      highlight = _glint(baseHalf, height, neckHalf, neckHeight),
      cork = RRect.fromRectAndRadius(
        Rect.fromLTWH(-neckHalf - .02, -height - .09, (neckHalf + .02) * 2, .1),
        const Radius.circular(.03),
      ),
      collar = Rect.fromLTWH(
        -neckHalf - .03,
        -height + .01,
        (neckHalf + .03) * 2,
        .05,
      );
  final double height;
  final Path path, highlight;
  final RRect cork;
  final Rect collar;

  static Path _outline(double bw, double h, double nw, double nh) => Path()
    ..moveTo(-bw + .04, 0)
    ..lineTo(bw - .04, 0)
    ..quadraticBezierTo(bw, 0, bw - .02, -.05)
    ..lineTo(nw, -(h - nh))
    ..lineTo(nw, -h)
    ..lineTo(-nw, -h)
    ..lineTo(-nw, -(h - nh))
    ..lineTo(-bw + .02, -.05)
    ..quadraticBezierTo(-bw, 0, -bw + .04, 0)
    ..close();

  /// A glint along the left wall, up the shoulder and into the neck.
  static Path _glint(double bw, double h, double nw, double nh) {
    final base = h - nh;
    double wall(double y) => bw - (bw - nw) * y / base;
    return Path()
      ..moveTo(-wall(.08) + .05, -.08)
      ..lineTo(-wall(base - .04) + .035, -(base - .04))
      ..lineTo(-nw + .03, -(base + .02))
      ..lineTo(-nw + .03, -h + .09);
  }
}

/// A brew's light, mid and deep liquid colors, with the fills and glows
/// built from them once.
class _Brew {
  _Brew(this.core, this.mid, this.deep)
    : vatLiquid = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mid, mid, deep],
        ).createShader(const Rect.fromLTWH(.1, -.3, 1.3, 1.3)),
      flaskLiquid = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [core, mid, deep],
        ).createShader(const Rect.fromLTRB(-.3, -.6, .3, .1)),
      halo = RadialGradient(colors: [mid, mid.withValues(alpha: 0)])
          .createShader(
            Rect.fromCircle(
              center: SpitterBossRig._haloAt,
              radius: SpitterBossRig._haloRadius,
            ),
          ),
      vatGlow = RadialGradient(colors: [core, core.withValues(alpha: 0)])
          .createShader(
            Rect.fromCircle(
              center: SpitterBossRig._vatGlowAt,
              radius: SpitterBossRig._vatGlowRadius,
            ),
          );
  final Color core, mid, deep;
  final Paint vatLiquid, flaskLiquid;
  final Shader halo, vatGlow;
}
