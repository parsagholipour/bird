import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';

/// A left-facing flying beetle, drawn in collision-radius units. Lifted wing
/// cases frame a buzzing blur of flight wings; the mint cheek stores its spit.
///
/// The attack reads in three beats: the body coils back toward its tail while
/// the cheek swells and glows (charge), it snaps forward with the mouth pinned
/// to the projectile origin [muzzle] and bursts (spit), then springs back and
/// settles (recoil). Everything is a pure function of the arguments.
abstract final class AimedEnemyArt {
  /// Art-space launch point; `SkyEnemy.muzzleX` spawns the seed here.
  static const muzzle = Offset(-1.05, 0);

  static const _ink = SkyColors.ink;
  static const _deep = Color(0xff1c4d45);
  static const _jade = Color(0xff2a9474);
  static const _leaf = Color(0xff7fd4a0);
  static const _lime = Color(0xffc3eba2);
  static const _gloss = Color(0xffe4fbd6);
  static const _mint = Color(0xffb3ffda);
  static const _spit = Color(0xff58c69b);
  static const _skin = Color(0xffa3dcab);

  // Near wing hinge and the tip locus of a stroke: up (-1) to down (+1).
  static const _hinge = Offset(.74, -.47);
  static const _upAngle = -.62, _downAngle = .28;
  static const _upReach = .9, _downReach = 1.02;

  static final _head = Path()
    ..moveTo(-1.0, -.13)
    ..cubicTo(-1.03, -.43, -.86, -.64, -.6, -.64)
    ..cubicTo(-.35, -.64, -.16, -.47, -.16, -.2)
    ..cubicTo(-.16, .08, -.22, .31, -.42, .41)
    ..cubicTo(-.62, .5, -.9, .38, -.99, .14)
    ..quadraticBezierTo(-1.08, 0, -1.0, -.13)
    ..close();

  static final _thorax = Path()
    ..moveTo(-.42, -.5)
    ..cubicTo(-.2, -.74, .22, -.68, .32, -.36)
    ..cubicTo(.42, -.04, .34, .32, .1, .44)
    ..cubicTo(-.12, .54, -.38, .42, -.42, .2)
    ..close();

  static final _abdomen = Path()
    ..moveTo(-.05, -.3)
    ..cubicTo(.4, -.5, 1.12, -.44, 1.38, -.08)
    ..cubicTo(1.56, .17, 1.38, .56, .96, .65)
    ..cubicTo(.5, .75, .08, .63, -.1, .37)
    ..close();

  static final _plates = Path()
    ..moveTo(.34, .2)
    ..quadraticBezierTo(.28, .42, .36, .64)
    ..moveTo(.68, .17)
    ..quadraticBezierTo(.62, .41, .7, .64)
    ..moveTo(1.02, .12)
    ..quadraticBezierTo(.97, .34, 1.04, .54);

  static final _elytron = Path()
    ..moveTo(0, .02)
    ..cubicTo(.1, -.36, .72, -.52, 1.26, -.28)
    ..cubicTo(1.52, -.15, 1.66, .06, 1.58, .18)
    ..cubicTo(1.14, .34, .46, .34, 0, .14)
    ..close();

  static final _elytronSeam = Path()
    ..moveTo(.14, .1)
    ..cubicTo(.56, .22, 1.14, .22, 1.52, .12);

  static final _elytronGloss = Path()
    ..moveTo(.2, -.14)
    ..cubicTo(.4, -.32, .74, -.38, 1.02, -.26);

  /// Unit-length membrane; scaled by reach and breadth per frame.
  static final _membrane = Path()
    ..moveTo(0, 0)
    ..cubicTo(.22, -.5, .74, -.6, .97, -.16)
    ..quadraticBezierTo(1.05, .04, .9, .14)
    ..cubicTo(.62, .3, .26, .2, 0, 0)
    ..close();

  static Offset _tip(double stroke) {
    final t = (stroke + 1) / 2;
    final angle = _upAngle + (_downAngle - _upAngle) * t;
    final reach =
        _upReach + (_downReach - _upReach) * t + math.sin(t * math.pi) * .05;
    return Offset(math.cos(angle), math.sin(angle)) * reach;
  }

  /// The swept area of a buzzing wing: a steady shape that never flickers.
  static final Path _fan = () {
    final path = Path()..moveTo(0, 0);
    for (var i = 0; i <= 12; i++) {
      final p = _tip(-1 + i / 6) * 1.04;
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();

  static final Path _fanEdge = () {
    final path = Path();
    for (var i = 0; i <= 12; i++) {
      final p = _tip(-1 + i / 6) * 1.04;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }();

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
    final time = seconds.isFinite && !reducedMotion ? seconds : 0.0;
    final aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    final power = charge.isFinite ? charge.clamp(0.0, 1.0) : 0.0;
    final kick = recoil.isFinite ? recoil.clamp(0.0, 1.0) : 0.0;

    // Anticipation: a steady coil that holds, then tightens right before firing.
    final wind = _smooth(0, .72, power) + .2 * _smooth(.86, 1, power);
    // Action and reaction measured from the shot (0) to fully settled (1).
    final after = kick > 0 ? 1 - kick : 1.0;
    final thrust = kick > 0 ? math.pow(1 - after, 4).toDouble() : 0.0;
    final spring = kick <= 0
        ? 0.0
        : reducedMotion
        ? math.sin(math.pi * after) * (1 - after) * 1.7
        : math.exp(-4 * after) * math.sin(2.2 * math.pi * after) / .47;
    final dx = .15 * wind + .13 * spring;
    final dy = .015 * wind;
    final tilt = .075 * wind - .03 * thrust + .07 * spring;
    final sx = 1 - .06 * wind - .04 * spring;
    final sy = 1 + .035 * wind - .04 * thrust + .04 * spring;

    // Decorative motion freezes with Reduced Motion; the attack does not.
    final buzz = time * math.pi * 2 * 11;
    final sway = reducedMotion
        ? 0.0
        : math.sin(time * 3.4) * .06 + math.sin(time * 5.3 + 1) * .025;
    final dangle = reducedMotion
        ? 0.0
        : math.sin(time * 3.4 - .9) * .05 + math.sin(time * 5.3) * .02;
    // Secondary action: antennae and feet lag the coil and whip after the shot.
    final lag = kick <= 0 || reducedMotion
        ? 0.0
        : math.exp(-3.4 * after) *
              math.cos(math.pi * 2 * 1.5 * after) *
              (1 - math.pow(after, 4));
    final pull = math.sin(math.pi * _smooth(0, .8, power)) * (1 - power * .5);
    final blink = reducedMotion || power > 0 || kick > 0 ? 0.0 : _blink(time);

    c.save();
    c.scale(radius);
    c.save();
    c.translate(dx, dy);
    c.translate(muzzle.dx, muzzle.dy);
    c.rotate(tilt);
    c.scale(sx, sy);
    c.translate(-muzzle.dx, -muzzle.dy);

    _wings(c, buzz, reducedMotion, far: true);
    _shell(c, far: true, lift: wind * .02 - thrust * .06 + spring * .08);
    _legs(c, dangle + .18 * wind - .3 * lag, wind, far: true);
    _body(c);
    _shell(c, far: false, lift: wind * .04 - thrust * .05 + spring * .07);
    // The translucent near wing overlaps the shell so its blur reads on the
    // dark value behind it, not only against the sky.
    _wings(c, buzz, reducedMotion, far: false);
    _neck(c);
    _legs(c, dangle + .18 * wind - .3 * lag, wind, far: false);
    _antennae(c, sway - .22 * pull + .32 * lag);
    _face(
      c,
      aim: aim,
      power: power,
      wind: wind,
      thrust: thrust,
      after: after,
      blink: blink,
      time: time,
      reducedMotion: reducedMotion,
    );
    c.restore();
    if (kick > 0) _burst(c, after, aim, reducedMotion);
    c.restore();
  }

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// A quick lid close roughly every 3.3 s, derived from time alone.
  static double _blink(double time) {
    final t = (time + 1.3) % 3.3;
    if (t > .16) return 0;
    return math.sin(t / .16 * math.pi);
  }

  /// A steady translucent blur fan with a crisp membrane flicking inside it.
  static void _wings(
    Canvas c,
    double buzz,
    bool reducedMotion, {
    required bool far,
  }) {
    c.save();
    if (far) {
      c.translate(_hinge.dx - .12, _hinge.dy - .07);
      c.rotate(-.08);
      c.scale(.94);
    } else {
      c.translate(_hinge.dx, _hinge.dy);
    }
    c.drawPath(
      _fan,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          1.4,
          far
              ? const [Color(0x00ffffff), Color(0x30eafff3), Color(0x66eafff3)]
              : const [Color(0x00ffffff), Color(0x48f4fff6), Color(0x99f4fff6)],
          const [.25, .7, 1],
        ),
    );
    c.drawPath(_fanEdge, _line(_deep.withValues(alpha: far ? .22 : .34), .045));
    final phase = far ? buzz - .8 : buzz;
    final ghost = reducedMotion ? null : math.sin(phase - 1.25);
    final stroke = reducedMotion ? (far ? -.55 : -.1) : math.sin(phase);
    if (ghost != null) {
      c.drawPath(
        _membraneAt(ghost),
        _fill(const Color(0xfff4fff6).withValues(alpha: far ? .22 : .32)),
      );
    }
    final wing = _membraneAt(stroke);
    c.drawPath(
      wing,
      _fill(far ? const Color(0x99cfeee0) : const Color(0xbbeaf9e8)),
    );
    c.drawPath(wing, _line(_deep.withValues(alpha: far ? .5 : .75), .045));
    final tip = _tip(stroke);
    c.drawLine(
      tip * .12,
      tip * .82 + Offset(tip.dy, -tip.dx) * .12,
      _line(SkyColors.cream.withValues(alpha: far ? .45 : .8), .05),
    );
    c.restore();
  }

  static Path _membraneAt(double stroke) {
    final tip = _tip(stroke);
    final angle = math.atan2(tip.dy, tip.dx);
    final reach = tip.distance;
    // Membranes turn edge-on as the stroke reverses.
    final breadth = (.42 + .55 * (1 - stroke * stroke)) * reach;
    final cs = math.cos(angle), sn = math.sin(angle);
    return _membrane.transform(
      Float64List.fromList([
        cs * reach, sn * reach, 0, 0, //
        -sn * breadth, cs * breadth, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]),
    );
  }

  static void _shell(Canvas c, {required bool far, required double lift}) {
    c.save();
    if (far) {
      c.translate(-.1, -.46);
      c.rotate(-.44 - lift * 1.3);
      c.scale(.9, .76);
    } else {
      c.translate(-.2, -.42);
      c.rotate(-.26 - lift);
    }
    c.drawPath(
      _elytron,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(.6, -.5),
          const Offset(.8, .34),
          far
              ? const [Color(0xff5fae8c), Color(0xff256f5d), _deep]
              : const [_leaf, _jade, _deep],
          const [0, .5, 1],
        ),
    );
    c.drawPath(_elytron, _line(_ink, far ? .085 : .075));
    if (!far) {
      c.drawPath(_elytronSeam, _line(_deep, .05));
      c.drawPath(_elytronGloss, _line(_gloss, .1));
      c.drawCircle(const Offset(1.18, -.14), .055, _fill(_gloss));
    }
    c.restore();
  }

  static void _body(Canvas c) {
    // A light belly under the dark shell keeps the silhouette two-toned.
    c.drawPath(
      _abdomen,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(.7, -.2),
          const Offset(.8, .7),
          const [_lime, _leaf, Color(0xff3f9a7c)],
          const [0, .5, 1],
        ),
    );
    c.drawPath(
      _plates,
      _line(const Color(0xff3f9a7c).withValues(alpha: .7), .06),
    );
    c.drawPath(_abdomen, _line(_ink, .075));
  }

  static void _neck(Canvas c) {
    c.drawPath(
      _thorax,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-.2, -.6),
          const Offset(.1, .45),
          const [_leaf, _jade, _deep],
          const [0, .5, 1],
        ),
    );
    c.drawPath(_thorax, _line(_ink, .075));
    c.drawPath(
      Path()
        ..moveTo(-.18, -.52)
        ..quadraticBezierTo(.14, -.5, .2, -.22),
      _line(_gloss.withValues(alpha: .8), .08),
    );
  }

  static void _legs(Canvas c, double swing, double wind, {required bool far}) {
    c.save();
    if (far) c.translate(.1, -.08);
    final tuck = wind * .1;
    final path = Path();
    for (final (hip, knee, foot, lag) in const [
      (Offset(-.22, .36), Offset(-.44, .62), Offset(-.26, .84), .6),
      (Offset(.25, .52), Offset(.12, .78), Offset(.4, .92), 1.0),
      (Offset(.74, .6), Offset(.76, .86), Offset(1.06, .9), 1.35),
    ]) {
      final k = knee + Offset(swing * lag * .4, -tuck);
      final f = foot + Offset(swing * lag, -tuck * 1.6 - swing * lag * .2);
      path
        ..moveTo(hip.dx, hip.dy)
        ..quadraticBezierTo(k.dx, k.dy, (k.dx + f.dx) / 2, (k.dy + f.dy) / 2)
        ..lineTo(f.dx, f.dy);
    }
    if (far) {
      c.drawPath(path, _line(_ink, .1));
    } else {
      c.drawPath(path, _line(_ink, .14));
      c.drawPath(path, _line(const Color(0xff3c8b72), .06));
    }
    c.restore();
  }

  static void _antennae(Canvas c, double bend) {
    for (final (base, tip, width, ball, far) in const [
      (Offset(-.48, -.6), Offset(-1.0, -1.02), .07, .08, true),
      (Offset(-.72, -.56), Offset(-1.38, -.9), .08, .095, false),
    ]) {
      final b = bend * (far ? .8 : 1);
      final end = base + _rotate(tip - base, b);
      final mid = base + _rotate(Offset(tip.dx - base.dx, -.34) * .55, b * .45);
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
      final color = far ? const Color(0xff2d5f55) : _ink;
      c.drawPath(path, _line(color, width));
      c.drawCircle(end, ball, _fill(color));
      c.drawCircle(end, ball - .035, _fill(far ? _leaf : _mint));
    }
  }

  static Offset _rotate(Offset v, double angle) {
    final c = math.cos(angle), s = math.sin(angle);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  static void _face(
    Canvas c, {
    required double aim,
    required double power,
    required double wind,
    required double thrust,
    required double after,
    required double blink,
    required double time,
    required bool reducedMotion,
  }) {
    c.drawPath(
      _head,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-.8, -.62),
          const Offset(-.4, .42),
          const [Color(0xffd3f3b8), Color(0xff8ad3a0), Color(0xff3f9c80)],
          const [0, .5, 1],
        ),
    );
    c.drawPath(_head, _line(_ink, .075));

    // Cheek sac: swells and glows through the charge, squeezes on the spit and
    // jiggles back while the body recoils.
    final jiggle = after >= 1
        ? 0.0
        : -.28 *
              math.exp(-4.5 * after) *
              math.cos(math.pi * 2 * 1.4 * after) *
              (1 - math.pow(after, 4));
    final throb = reducedMotion || power < .5
        ? 0.0
        : math.sin(time * (26 + 30 * power)) * .035 * power;
    final swell = 1 + .75 * (1 - math.pow(1 - power, 2)) + jiggle + throb;
    final sac = Rect.fromCenter(
      center: Offset(-.66, .2 + (swell - 1) * .09),
      width: .44 * swell,
      height: .32 * swell,
    );
    final glow = _smooth(.1, 1, power);
    if (glow > 0) {
      c.drawCircle(
        sac.center,
        sac.width * .95,
        Paint()
          ..shader = ui.Gradient.radial(sac.center, sac.width * .95, [
            _mint.withValues(alpha: .55 * glow),
            _mint.withValues(alpha: 0),
          ]),
      );
    }
    c.drawOval(sac, _fill(Color.lerp(_spit, _mint, glow)!));
    c.save();
    c.clipPath(Path()..addOval(sac));
    c.drawOval(
      Rect.fromCenter(
        center: sac.center + Offset(-sac.width * .08, -sac.height * .12),
        width: sac.width * .7,
        height: sac.height * .55,
      ),
      _fill(Color.lerp(_mint, SkyColors.cream, glow)!),
    );
    c.restore();
    c.drawOval(sac, _line(_ink, .055 + glow * .01));
    c.drawOval(
      Rect.fromCenter(
        center: sac.center + Offset(-sac.width * .16, -sac.height * .22),
        width: sac.width * .26,
        height: sac.height * .2,
      ),
      _fill(SkyColors.cream.withValues(alpha: .85)),
    );

    // Big eye under a sly slanted lid that narrows to aim, squeezes on the spit.
    const eye = Rect.fromLTWH(-.96, -.55, .5, .55);
    c.drawOval(eye, _fill(SkyColors.cream));
    final pupil = Offset(-.78, -.23 + aim * .09);
    c.save();
    c.clipPath(Path()..addOval(eye));
    c.drawOval(
      Rect.fromCenter(center: pupil, width: .24, height: .31),
      _fill(_ink),
    );
    c.drawCircle(
      pupil + const Offset(-.04, -.075),
      .055,
      _fill(SkyColors.cream),
    );
    final lid = (wind * .12 + thrust * .2 + blink * .62).clamp(0.0, .62);
    final front = Offset(eye.left - .04, -.41 + lid);
    final back = Offset(eye.right + .04, -.57 + lid * .75);
    final lidPath = Path()
      ..moveTo(front.dx, front.dy)
      ..lineTo(back.dx, back.dy)
      ..lineTo(back.dx, eye.top - .05)
      ..lineTo(front.dx, eye.top - .05)
      ..close();
    c.drawPath(lidPath, _fill(_skin));
    c.restore();
    c.drawOval(eye, _line(_ink, .065));
    c.drawLine(front + const Offset(-.02, .01), back, _line(_ink, .085));

    // Pursed lips; the opening is centered exactly on the muzzle.
    final pucker = 1 + power * .22 + thrust * .3;
    c.save();
    c.translate(muzzle.dx, muzzle.dy);
    c.scale(pucker);
    final lips = Rect.fromCenter(
      center: const Offset(-.01, 0),
      width: .22,
      height: .26,
    );
    c.drawOval(lips, _fill(_skin));
    c.drawOval(lips, _line(_ink, .06 / pucker));
    final hole = Rect.fromCenter(
      center: Offset.zero,
      width: .07 + power * .03 + thrust * .06,
      height: .09 + power * .06 + thrust * .08,
    );
    c.drawOval(hole, _fill(_ink));
    if (power > 0 || thrust > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: hole.width * .6,
          height: hole.height * .6,
        ),
        _fill(_mint.withValues(alpha: math.max(glow, thrust))),
      );
    }
    c.restore();

    // A brief glint on the lip says "about to fire".
    final glint = math.sin(math.pi * _smooth(.74, 1.04, power));
    if (glint > .01) {
      _sparkle(c, const Offset(-1.17, -.24), .3 * glint, glint);
    }
  }

  static void _sparkle(Canvas c, Offset at, double size, double alpha) {
    final star = Path()
      ..moveTo(at.dx, at.dy - size)
      ..quadraticBezierTo(
        at.dx + size * .12,
        at.dy - size * .12,
        at.dx + size * .8,
        at.dy,
      )
      ..quadraticBezierTo(
        at.dx + size * .12,
        at.dy + size * .12,
        at.dx,
        at.dy + size,
      )
      ..quadraticBezierTo(
        at.dx - size * .12,
        at.dy + size * .12,
        at.dx - size * .8,
        at.dy,
      )
      ..quadraticBezierTo(
        at.dx - size * .12,
        at.dy - size * .12,
        at.dx,
        at.dy - size,
      )
      ..close();
    c.drawPath(star, _line(_deep.withValues(alpha: .85 * alpha), .07));
    c.drawPath(star, _fill(SkyColors.cream.withValues(alpha: alpha)));
  }

  /// A lively eight-point pop with alternating long and short rays.
  static final Path _pop = () {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 + .2;
      final r = i.isOdd ? .56 : (i % 4 == 0 ? 1.0 : .78);
      final p = Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();

  /// Muzzle burst left in the world where the seed was launched: a bright
  /// pop behind the seed, an expanding ring and two droplets flung aside.
  static void _burst(Canvas c, double after, double aim, bool reducedMotion) {
    final life = (after / .55).clamp(0.0, 1.0);
    if (life >= 1) return;
    final grow = reducedMotion ? .4 : 1 - math.pow(1 - life, 3).toDouble();
    final fade = math.pow(1 - life, 1.4).toDouble();
    c.save();
    c.translate(muzzle.dx, muzzle.dy);
    c.rotate(aim * .3);
    final flash = math.pow(1 - _smooth(0, .55, life), 2).toDouble();
    if (flash > 0) {
      c.save();
      c.translate(-.07, 0);
      c.scale(.56 * (1 - .2 * life));
      c.drawPath(_pop, _line(_spit.withValues(alpha: flash), .14));
      c.drawPath(
        _pop,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            1,
            [
              SkyColors.cream.withValues(alpha: flash),
              _mint.withValues(alpha: flash),
            ],
            const [.45, 1],
          ),
      );
      c.restore();
    }
    final ring = .34 + .28 * grow;
    final width = .09 * (1 - life) + .02;
    c.drawCircle(
      Offset.zero,
      ring,
      _line(_deep.withValues(alpha: .5 * fade), width + .05),
    );
    c.drawCircle(
      Offset.zero,
      ring,
      _line(_mint.withValues(alpha: fade), width),
    );
    for (final side in const [-1.0, 1.0]) {
      final angle = math.pi + side * 1.05;
      final d = .34 + .38 * grow;
      final at =
          Offset(math.cos(angle), math.sin(angle)) * d +
          Offset(0, reducedMotion ? 0 : life * life * .12);
      final size = .1 * (1 - life * .5);
      c.drawCircle(at, size + .04, _fill(_deep.withValues(alpha: .8 * fade)));
      c.drawCircle(at, size, _fill(_mint.withValues(alpha: fade)));
    }
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
