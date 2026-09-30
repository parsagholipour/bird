import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../ui/theme.dart';

/// The Pirate Captain's cannonball: a heavy cast-iron shot with a rim-lit
/// sphere, a spinning casting seam, a sky glint and a hot scorch on its
/// back, trailing gunsmoke and shed sparks along its arc; red-hot in fury.
///
/// Drawn in hit-radius units (1 = `BossAmmo.cannonballRadius`), the wake
/// along -x. The inked body ends exactly on the hit circle, so a dodge that
/// looks clean is clean; a hair-thin pale ring, the halo and the wake sit
/// outside it so the shot stays the most legible thing on screen against
/// sky, scenery and sea alike. Every motion follows simulation time.
abstract final class PirateCannonballArt {
  static const _ink = Color(0xff15141b);
  static const _iron = Color(0xff575d72), _ironLit = Color(0xffb7c0d6);
  static const _ironDeep = Color(0xff191a22), _ironMid = Color(0xff2c2e3b);
  static const _smoke = Color(0xffdfe2ea), _smokeRim = Color(0xff3f3e4d);
  static const _smokeShade = Color(0xffa5a9ba);
  static const _spark = Color(0xffffa24a), _hot = Color(0xffff5a2e);
  static const _ember = Color(0xffffc46a), _bounce = Color(0xff8fd6e6);
  static const _bounds = Rect.fromLTRB(-1, -1, 1, 1);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static double _hash(int a, [int b = 0]) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  // Gradients are fixed in local units, so their shaders are built once and
  // shared by every shot on screen instead of being rebuilt each frame.
  static Paint _glow(Color color, double alpha, double size) =>
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * .5),
            color.withValues(alpha: 0),
          ],
          stops: const [.4, .6, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: size));

  static Paint _along(Color color, double alpha) => Paint()
    ..shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: alpha),
      ],
    ).createShader(const Rect.fromLTRB(-1, -1, 0, 1));

  static final _halo = _glow(_spark, .34, 2.2);
  static final _haloFury = _glow(_hot, .5, 2.6);
  static final _fillPaint = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-.36, -.42),
      radius: 1.15,
      colors: [_ironLit, _iron, _ironMid, _ironDeep],
      stops: [0, .3, .7, 1],
    ).createShader(_bounds);
  static final _heat = Paint()
    ..shader = RadialGradient(
      center: const Alignment(.1, .15),
      colors: [
        const Color(0xffffc46a).withValues(alpha: .8),
        _hot.withValues(alpha: .5),
        _hot.withValues(alpha: 0),
      ],
      stops: const [0, .45, 1],
    ).createShader(_bounds);
  static final _streak = _along(_smoke, .5);
  static final _fireWake = _along(_spark, .85);

  // ---------------------------------------------------------------- wake --

  static void wake(Canvas c, double time, double reach, bool fury, bool fine) {
    final tail = (fury ? 6.2 : 5.4) * reach;
    final root = -.3 / tail;
    c.save();
    c.scale(tail, 1);
    // A faint streak of hot air marks the line of flight.
    c.drawPath(
      Path()
        ..moveTo(root, -.66)
        ..quadraticBezierTo(-.5, -.44, -1, 0)
        ..quadraticBezierTo(-.5, .44, root, .66)
        ..close(),
      _streak,
    );
    if (fury) {
      final lick = math.sin(time * 14);
      c.drawPath(
        Path()
          ..moveTo(root, -.72)
          ..quadraticBezierTo(-.3, -.46 + lick * .1, -.6, lick * .16)
          ..quadraticBezierTo(-.3, .46 + lick * .1, root, .72)
          ..close(),
        _fireWake,
      );
    }
    c.restore();
    // Gunsmoke puffs roll off behind and swell as they fall back: an inked
    // rim so they read on pale sky and dark sea alike, a shaded body and a
    // lit crown.
    final count = fury ? 5 : 4;
    final puffs = <(Offset, double, double)>[];
    for (var i = 0; i < count; i++) {
      final life = (time * 1.9 + i / count) % 1;
      final x = -1.5 - life * (tail - 1.5);
      final wobble = math.sin(time * 5 + i * 2.1) * .12;
      final r = .4 + life * .55;
      final fade = math.sin(math.min(life * 1.4, 1) * math.pi / 2) * (1 - life);
      puffs.add((Offset(x, wobble + life * .25), r, fade));
    }
    // Each puff is a soft cluster of lobes under one thin rim.
    final lobes = <(Offset, double, double)>[];
    for (var i = 0; i < puffs.length; i++) {
      final (at, r, fade) = puffs[i];
      lobes.add((at, r, fade));
      for (var j = 0; j < 2; j++) {
        final a = (_hash(i, j + 5) * .5 + j * .5) * math.pi * 2;
        lobes.add((
          at + Offset(math.cos(a), math.sin(a)) * r * .62,
          r * .62,
          fade,
        ));
      }
    }
    for (final (at, r, fade) in lobes) {
      c.drawCircle(at, r + .1, _fill(_smokeRim.withValues(alpha: .5 * fade)));
    }
    for (final (at, r, fade) in lobes) {
      c.drawCircle(at, r, _fill(_smokeShade.withValues(alpha: .95 * fade)));
    }
    for (final (at, r, fade) in lobes) {
      c.drawCircle(
        at + Offset(-r * .1, -r * .14),
        r * .84,
        _fill(_smoke.withValues(alpha: .95 * fade)),
      );
    }
    for (final (at, r, fade) in puffs) {
      c.drawCircle(
        at + Offset(-r * .28, -r * .34),
        r * .38,
        _fill(SkyColors.cream.withValues(alpha: .85 * fade)),
      );
    }
    // Sparks shed from the scorched iron, each a short hot streak.
    for (var i = 0; i < (fury ? 6 : 4); i++) {
      final life = (time * 2.6 + i / 3.3 + _hash(i) * .3) % 1;
      final side = i.isEven ? -1 : 1;
      final at = Offset(
        -1.15 - life * 2.5,
        side * (.3 + life * .6 + _hash(i, 3) * .25),
      );
      final flicker = .65 + .35 * math.sin(time * 37 + i * 2);
      final a = (1 - life) * flicker;
      final len = .3 * (1 - life * .5);
      c.drawLine(
        at,
        at + Offset(-len, -side * len * .18),
        _stroke((fury ? _hot : _spark).withValues(alpha: a * .8), .13),
      );
      c.drawCircle(
        at,
        .14 * (1 - life * .5),
        _fill((fury ? _ember : const Color(0xffffe08a)).withValues(alpha: a)),
      );
    }
  }

  // ---------------------------------------------------------------- body --

  /// The shot upright on the screen; [tail] is the screen angle behind its
  /// flight, where the propellant scorched it.
  static void body(
    Canvas c,
    double time,
    double edge,
    bool fury,
    bool fine,
    double tail,
  ) {
    final heat = fury ? .75 + .25 * math.sin(time * 9) : 0.0;
    c.drawCircle(Offset.zero, fury ? 2.6 : 2.2, fury ? _haloFury : _halo);
    // A hair of pale light just outside the ink keeps the shot readable
    // over deep sea and dark scenery.
    c.drawCircle(
      Offset.zero,
      1 + (fine ? .05 : .09),
      _stroke(SkyColors.cream.withValues(alpha: .62), fine ? .07 : .1),
    );
    c.drawCircle(Offset.zero, 1, _fill(_ink));
    c.save();
    c.scale(1 - edge);
    c.drawCircle(Offset.zero, 1, _fillPaint);
    // Cool light bounced up from the sea along the belly.
    c.drawArc(
      const Rect.fromLTRB(-.88, -.88, .88, .88),
      1.25,
      1.5,
      false,
      _stroke(
        (fury ? _spark : _bounce).withValues(alpha: fury ? .5 : .5),
        fine ? .08 : .12,
      ),
    );
    // The casting seam, wrapping round the near side as the shot tumbles.
    c.save();
    c.rotate(time * 1.7 + .6);
    final seam = Rect.fromCenter(
      center: Offset.zero,
      width: 1.8,
      height: fine ? .6 : .5,
    );
    c.drawArc(
      seam.shift(const Offset(0, .05)),
      .15,
      math.pi - .3,
      false,
      _stroke(_ironLit.withValues(alpha: .32), fine ? .05 : .06),
    );
    c.drawArc(
      seam,
      .15,
      math.pi - .3,
      false,
      _stroke(_ink.withValues(alpha: .62), fine ? .07 : .1),
    );
    c.restore();
    if (fury) {
      c.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = _heat.shader
          ..color = Color.fromRGBO(0, 0, 0, heat),
      );
      // Glowing cracks in the red-hot shot.
      c.drawPath(
        Path()
          ..moveTo(-.55, .35)
          ..lineTo(-.18, .12)
          ..lineTo(.02, .36)
          ..lineTo(.4, .2)
          ..moveTo(-.18, .12)
          ..lineTo(-.1, -.2)
          ..moveTo(.4, .2)
          ..lineTo(.6, -.12),
        _stroke(_ember.withValues(alpha: .9 * heat), fine ? .07 : .1),
      );
    }
    // Fire behind the shot rims its back edge.
    c.drawArc(
      const Rect.fromLTRB(-.86, -.86, .86, .86),
      tail - .68,
      1.36,
      false,
      _stroke(
        (fury ? _ember : _spark).withValues(alpha: .78),
        fine ? .12 : .17,
      ),
    );
    if (fine) {
      // Pits in the cast iron.
      for (final (x, y, r) in const [
        (.3, -.2, .05),
        (-.2, .4, .06),
        (.46, .3, .04),
        (-.5, .1, .035),
        (.1, .55, .03),
      ]) {
        c.drawCircle(Offset(x, y), r, _fill(_ironDeep.withValues(alpha: .5)));
      }
    }
    // Sky glint on the upper left: a soft sheen, a bright spot and a glint
    // that twinkles as the shot tumbles.
    c.save();
    c.translate(-.36, -.42);
    c.rotate(-.65);
    c.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: fine ? .52 : .58,
        height: fine ? .26 : .32,
      ),
      _fill(SkyColors.cream.withValues(alpha: .92)),
    );
    c.restore();
    c.drawCircle(
      const Offset(-.08, -.66),
      fine ? .07 : .1,
      _fill(SkyColors.cream.withValues(alpha: .7)),
    );
    final twinkle = .55 + .45 * math.sin(time * 7);
    final s = (fine ? .34 : .4) * twinkle;
    final glint = Path()
      ..moveTo(-.5, -.62 - s)
      ..lineTo(-.5 + s * .16, -.62 - s * .16)
      ..lineTo(-.5 + s, -.62)
      ..lineTo(-.5 + s * .16, -.62 + s * .16)
      ..lineTo(-.5, -.62 + s)
      ..lineTo(-.5 - s * .16, -.62 + s * .16)
      ..lineTo(-.5 - s, -.62)
      ..lineTo(-.5 - s * .16, -.62 - s * .16)
      ..close();
    c.drawPath(glint, _fill(const Color(0xffffffff)));
    c.restore();
  }
}
