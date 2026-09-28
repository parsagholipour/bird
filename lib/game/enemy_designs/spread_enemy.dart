import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// A left-facing dusk moth whose three throat glands telegraph a fan volley.
///
/// A small cousin of the Dusk Empress: pearl fur collar, coral face, velvet
/// wine wings with a pearl hem and amber-gemmed eyespots. Values are split
/// into a dark velvet wing rim, a bright collar and an ink outline so it
/// reads against both the daylight and dusk skies at a 16 px hit radius.
/// Everything, including attack poses, stays within x ±1.9r, y ±1.2r.
abstract final class SpreadEnemyArt {
  /// Where the volley leaves the moth; matches `SkyEnemy.muzzleX`.
  static const muzzle = Offset(-1.05, 0);

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
    final time = seconds.isFinite ? seconds : 0.0;
    final aim = _unit(lookY, -1, 1);
    final load = _unit(charge, 0, 1);
    final kick = _unit(recoil, 0, 1);
    final motion = reducedMotion ? 0.0 : 1.0;

    // A slow, slightly irregular moth beat: quick power stroke, floaty
    // recovery. Reduced Motion holds a mid-stroke rest pose.
    final phase = reducedMotion ? .75 : time * 8.4 + math.sin(time * 1.7) * .5;
    // Windup: wings rise and hold open to flash the eyespots.
    final brace = _smooth(load / .3);
    // Release: one hard downstroke, then the normal beat returns.
    final slam = _smooth(kick * 1.15);
    final quiver = math.sin(time * 31) * .035 * brace * motion;
    double stroke(double lag) {
      final cruise = _beat(phase - lag);
      final held = cruise + (1 - cruise) * brace;
      return held + (-1 - held) * slam;
    }

    final nearFore = stroke(0), nearHind = stroke(.45);
    final farFore = stroke(.75), farHind = stroke(1.15);

    // Body motion: a tiny lift on every downstroke, a lean back while
    // charging and a snap forward + damped push back after the volley.
    final since = 1 - kick;
    final push = kick > 0
        ? .1 * math.sin(math.pi * since) * math.sqrt(kick) * motion
        : 0.0;
    final bob = -_beat(phase - 1.3) * .03 * motion;
    final lean = .06 * _smooth(load / .5);
    final sway =
        (math.sin(phase - 1.5) * .035 + math.sin(time * 2.3) * .02) * motion;

    c.save();
    c.scale(radius);
    c.save();
    c.translate(lean + push, bob);

    _wing(
      c,
      _foreWing,
      _forePivot,
      _foreAngle(farFore, brace) - .08,
      _foreSquash(farFore),
      far: true,
    );
    _wing(
      c,
      _hindWing,
      _hindPivot,
      _hindAngle(farHind) - .14 + (.03 - _hindAngle(farHind)) * brace * .8,
      _hindSquash(farHind),
      far: true,
    );
    c.drawPath(_abdomen, _abdomenFill);
    c.drawPath(_abdomenStripes, _stripeFill);
    c.drawPath(_abdomen, _outline);
    _wing(
      c,
      _hindWing,
      _hindPivot,
      _hindAngle(nearHind) + (.03 - _hindAngle(nearHind)) * brace * (1 - slam),
      _hindSquash(nearHind),
      far: false,
      gem: load,
    );
    _legs(c, sway);
    _wing(
      c,
      _foreWing,
      _forePivot,
      _foreAngle(nearFore, brace) + quiver,
      _foreSquash(nearFore),
      far: false,
      gem: load,
    );
    _collar(c);
    _antenna(c, far: true, sway: sway, alert: brace, flick: kick);
    _head(c, aim, load, kick);
    _antenna(c, far: false, sway: sway, alert: brace, flick: kick);
    _glands(c, load, kick, time * motion);
    c.restore();
    _muzzle(c, load, kick, time * motion, reducedMotion);
    c.restore();
  }

  /// +1 = top of the stroke, -1 = bottom. The downstroke takes 40% of the
  /// cycle; both reversals ease (zero velocity) so the flutter never snaps.
  static double _beat(double phase) {
    final u = (phase / (2 * math.pi)) % 1.0;
    const down = .4;
    return u < down
        ? math.cos(math.pi * u / down)
        : -math.cos(math.pi * (u - down) / (1 - down));
  }

  static double _foreAngle(double v, double brace) =>
      .1 + .68 * (1 - v) / 2 - .1 * brace;
  static double _foreSquash(double v) => 1 - .2 * (1 - v) / 2;
  static double _hindAngle(double v) => .1 - .32 * (v + 1) / 2;
  static double _hindSquash(double v) => .94 + .06 * (v + 1) / 2;

  static void _wing(
    Canvas c,
    Path path,
    Offset pivot,
    double angle,
    double squash, {
    required bool far,
    double gem = 0,
  }) {
    final fore = identical(path, _foreWing);
    c.save();
    c.translate(pivot.dx, pivot.dy);
    if (far) {
      // The far pair sits a little higher and smaller, peeking out behind.
      c.translate(-.02, -.04);
      c.scale(.9);
    }
    c.rotate(angle);
    c.scale(1, squash);
    c.translate(-pivot.dx, -pivot.dy);
    c.drawPath(
      path,
      far
          ? _farFill
          : fore
          ? _foreFill
          : _hindFill,
    );
    if (far) {
      // The mostly hidden far pair skips the clipped hem; a darker fill
      // and the ink edge carry it, which is cheaper every frame.
      c.drawPath(path, _outline);
      c.restore();
      return;
    }
    c.save();
    c.clipPath(path);
    c.drawPath(path, _velvetRim);
    c.drawPath(path, _pearlHem);
    for (final vein in fore ? _foreVeins : _hindVeins) {
      c.drawPath(vein, _veinPaint);
    }
    c.restore();
    _eyespot(c, fore, gem);
    c.drawPath(path, _outline);
    c.restore();
  }

  static void _eyespot(Canvas c, bool fore, double gem) {
    c.save();
    c.translate(fore ? .86 : .78, fore ? -.6 : .66);
    c.rotate(fore ? -.42 : .5);
    if (!fore) c.scale(.72);
    c.drawPath(_eye, _velvetFill);
    c.drawPath(_eye, _eyeRim);
    c.drawPath(_crescent, _pearlFill);
    // The wing gems warm up with the whole windup, a large second cue.
    final lit = _smooth(gem / .85);
    const at = Offset(.02, .02);
    if (lit > 0) {
      c.drawPath(_eye, Paint()..color = _ember.withValues(alpha: .6 * lit));
      c.drawCircle(
        at,
        .22,
        Paint()..color = _pollen.withValues(alpha: .7 * lit),
      );
    }
    c.drawCircle(
      at,
      .085 + lit * .045,
      Paint()..color = Color.lerp(_coral, _hot, lit)!,
    );
    c.restore();
  }

  static void _legs(Canvas c, double sway) {
    c.drawPath(
      Path()
        ..moveTo(-.34, .3)
        ..quadraticBezierTo(-.36, .58, -.56 + sway, .66)
        ..moveTo(-.1, .3)
        ..quadraticBezierTo(-.08, .6, -.3 + sway * .7, .74),
      _legPaint,
    );
  }

  static void _collar(Canvas c) {
    c.drawPath(_collarPath, _collarFill);
    c.drawPath(_collarShade, _collarShadePaint);
    c.drawPath(_collarPath, _outline);
    c.drawPath(_collarTufts, _tuftPaint);
    c.drawPath(_bib, _wineFill);
  }

  static void _antenna(
    Canvas c, {
    required bool far,
    required double sway,
    required double alert,
    required double flick,
  }) {
    // A feathered plume reads as one soft shape at gameplay size.
    final root = far ? const Offset(-.68, -.72) : const Offset(-.9, -.72);
    final bend = far ? const Offset(-.76, -1.04) : const Offset(-1.12, -1.0);
    final tip =
        (far ? const Offset(-1.12, -1.05) : const Offset(-1.68, -.94)) +
        Offset(-.05 * alert + .1 * flick, sway - .04 * alert + .05 * flick);
    Offset at(double t) =>
        root * ((1 - t) * (1 - t)) + bend * (2 * (1 - t) * t) + tip * (t * t);
    final plume = Path();
    final back = <Offset>[];
    const steps = 8;
    for (var i = 0; i <= steps; i++) {
      final t = .22 + .78 * i / steps;
      final d = (bend - root) * (2 * (1 - t)) + (tip - bend) * (2 * t);
      final n = Offset(-d.dy, d.dx) / d.distance;
      // Alternating barbs give the plume a feathered, fern-like edge.
      final w =
          (far ? .09 : .115) *
          math.pow(math.sin(math.pi * i / steps), .7) *
          (i.isOdd ? 1.0 : .55);
      final p = at(t);
      if (i == 0) {
        plume.moveTo(p.dx, p.dy);
      } else {
        plume.lineTo(p.dx + n.dx * w, p.dy + n.dy * w);
      }
      back.add(p - n * w);
    }
    for (final p in back.reversed) {
      plume.lineTo(p.dx, p.dy);
    }
    plume.close();
    final start = at(.22);
    c.drawPath(
      Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(
          (root.dx + start.dx) / 2 + (bend.dx - root.dx) * .15,
          (root.dy + start.dy) / 2 + (bend.dy - root.dy) * .15,
          start.dx,
          start.dy,
        ),
      _antennaStem,
    );
    c.drawPath(plume, far ? _roseFill : _silkFill);
    c.drawPath(plume, _thinOutline);
    final mid = at(.7);
    c.drawLine(start, mid, far ? _antennaFarRib : _antennaRib);
  }

  static void _head(Canvas c, double aim, double load, double kick) {
    c.save();
    // The face tips a touch toward the bird; the chin stays at the port.
    c.translate(-1.02, -.02);
    c.rotate(aim * .05);
    c.translate(1.02, .02);
    c.drawPath(_headPath, _headFill);
    c.drawPath(_headPath, _outline);
    c.drawPath(_headTuft, _headTuftPaint);
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.66, -.2), width: .2, height: .12),
      _blush,
    );
    const eye = Offset(-.98, -.4);
    c.drawOval(Rect.fromCenter(center: eye, width: .36, height: .4), _inkFill);
    c.drawOval(
      Rect.fromCenter(
        center: eye + const Offset(-.02, .005),
        width: .25,
        height: .3,
      ),
      _pearlFill,
    );
    final pupil = eye + Offset(-.06, aim * .06 + .01);
    c.drawOval(
      Rect.fromCenter(center: pupil, width: .13, height: .19),
      _inkFill,
    );
    c.drawCircle(pupil + const Offset(-.025, -.05), .035, _pearlFill);
    // Brow lowers into a determined squint while the glands fill.
    final focus = _smooth(load / .6);
    c.drawPath(
      Path()
        ..moveTo(-1.16, -.64 + focus * .02)
        ..quadraticBezierTo(-1.0, -.66, -.83, -.61 + focus * .05),
      _brow,
    );
    // The curled proboscis unrolls into the port as the volley builds.
    final curl = 1 - _smooth(load / .7);
    if (curl > .02 && kick < .98) {
      c.drawPath(
        Path()
          ..moveTo(-1.0, .02)
          ..cubicTo(
            -1.04,
            .02 + curl * .2,
            -.84 - .1 * (1 - curl),
            .02 + curl * .24,
            -.87 - .08 * (1 - curl),
            .02 + curl * .12,
          ),
        _proboscis,
      );
    }
    c.restore();
  }

  static void _glands(Canvas c, double load, double kick, double t) {
    // Lit bottom to top, one after another: the energy climbs the throat
    // to the port, so the count (1, 2, 3) is the countdown.
    final full = _smooth((load - .8) / .2);
    final spent = math.pow(kick, 1.3).toDouble();
    if (full > 0 || spent > 0) {
      final glow = math.max(full, spent);
      c.drawCircle(
        _throatGlow,
        .62,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _pollen.withValues(alpha: .55 * glow),
              _ember.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: _throatGlow, radius: .62)),
      );
    }
    for (var i = 0; i < _glandAt.length; i++) {
      final start = .04 + i * .26;
      final lit = _smooth((load - start) / .14);
      final glow = math.max(lit, spent);
      final pop = math.sin(math.pi * lit) * .38;
      final pulse = full * (.05 + .05 * math.sin(t * 20 - i * 1.3));
      final r = (.1 + .025 * lit) * (1 + pop + pulse);
      final at = _glandAt[i];
      if (glow > 0) {
        c.drawCircle(
          at,
          r * 3,
          Paint()
            ..shader = RadialGradient(
              colors: [
                _hot.withValues(alpha: glow),
                _pollen.withValues(alpha: .75 * glow),
                _ember.withValues(alpha: .35 * glow),
                _ember.withValues(alpha: 0),
              ],
              stops: const [0, .3, .62, 1],
            ).createShader(Rect.fromCircle(center: at, radius: r * 3)),
        );
      }
      // Each gland ignites with a quick ember ring, so every step counts.
      final ignite = math.sin(math.pi * lit);
      if (ignite > .01) {
        c.drawCircle(
          at,
          r * (1.4 + 1.5 * lit),
          Paint()
            ..color = _ember.withValues(alpha: .95 * ignite)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .05,
        );
      }
      final gland = Rect.fromCenter(center: at, width: r * 1.9, height: r * 2);
      c.drawOval(gland.inflate(.035), _inkFill);
      c.drawOval(
        gland,
        Paint()
          ..color = Color.lerp(_glandDim, spent > lit ? _hot : _pollen, glow)!,
      );
      c.drawCircle(
        at + Offset(-r * .3, -r * .34),
        r * .34,
        Paint()..color = _pearl.withValues(alpha: .3 + .7 * glow),
      );
    }
  }

  static void _muzzle(
    Canvas c,
    double load,
    double kick,
    double t,
    bool reducedMotion,
  ) {
    // A pollen ember gathers in the port once all three glands are lit.
    final gather = _smooth((load - .7) / .3);
    if (gather > 0) {
      final pulse = 1 + .1 * math.sin(t * 24);
      final r = (.05 + .08 * gather) * pulse;
      c.drawCircle(
        muzzle,
        r * 3.4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _pollen.withValues(alpha: .85 * gather),
              _ember.withValues(alpha: .35 * gather),
              _ember.withValues(alpha: 0),
            ],
            stops: const [0, .45, 1],
          ).createShader(Rect.fromCircle(center: muzzle, radius: r * 3.4)),
      );
      c.drawCircle(muzzle, r + .035, _emberFill);
      c.drawCircle(muzzle, r, _hotFill);
    }
    if (kick <= 0) return;
    // The volley: a hot flash, an ember ring and pop lines, all centred on
    // the real projectile origin. Reduced Motion keeps the flash but does
    // not expand it.
    final since = 1 - kick;
    final grow = reducedMotion ? .35 : 1 - math.pow(1 - since, 3).toDouble();
    final fade = _smooth(kick * 1.3);
    final flash = .34 + .18 * grow;
    c.drawCircle(
      muzzle,
      flash,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _hot.withValues(alpha: fade),
            _pollen.withValues(alpha: .7 * fade),
            _ember.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: muzzle, radius: flash)),
    );
    c.drawCircle(
      muzzle,
      .16 + .42 * grow,
      Paint()
        ..color = _ember.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .02 + .08 * kick,
    );
    // Pop lines sit between and outside the three shot lanes so they
    // never read as extra projectiles.
    final dash = Paint()
      ..color = _ember.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .03 + .07 * kick;
    for (final angle in const [-1.3, -.66, .66, 1.3]) {
      final dir = Offset(-math.cos(angle), math.sin(angle));
      c.drawLine(
        muzzle + dir * (.22 + .3 * grow),
        muzzle + dir * (.36 + .36 * grow),
        dash,
      );
    }
    c.drawCircle(muzzle, .05 + .1 * kick, Paint()..color = _hot);
  }

  // Palette: the Dusk Empress family, pushed further apart in value.
  static const _ink = Color(0xff392e4b);
  static const _velvet = Color(0xff5a2c4e);
  static const _wine = Color(0xff8c3f62);
  static const _rose = Color(0xffc6607a);
  static const _coral = Color(0xfff29a80);
  static const _peach = Color(0xffffc6a4);
  static const _pearl = Color(0xfffff3da);
  static const _silk = Color(0xffffe3ba);
  static const _gold = Color(0xffd99a76);
  static const _pollen = Color(0xffffc96f);
  static const _ember = Color(0xffff9a4a);
  static const _hot = Color(0xfffff4c8);
  static const _glandDim = Color(0xff9c5a4c);

  static const _forePivot = Offset(-.24, -.24);
  static const _hindPivot = Offset(-.14, .1);
  static const _glandAt = [
    Offset(-.5, .38),
    Offset(-.66, .23),
    Offset(-.82, .08),
  ];
  static const _throatGlow = Offset(-.78, .16);

  static final _foreWing = Path()
    ..moveTo(-.36, -.2)
    ..cubicTo(-.32, -.7, .3, -1.04, 1.12, -1.05)
    ..quadraticBezierTo(1.58, -1.06, 1.64, -.86)
    ..quadraticBezierTo(1.84, -.7, 1.62, -.55)
    ..quadraticBezierTo(1.74, -.32, 1.45, -.25)
    ..quadraticBezierTo(1.42, -.03, 1.12, -.07)
    ..quadraticBezierTo(.72, .07, .38, -.05)
    ..quadraticBezierTo(.02, .04, -.36, -.2)
    ..close();
  static final _hindWing = Path()
    ..moveTo(-.22, .04)
    ..cubicTo(.25, .1, .95, .36, 1.28, .7)
    ..quadraticBezierTo(1.46, .94, 1.24, 1.0)
    ..quadraticBezierTo(1.12, 1.14, .92, 1.02)
    ..quadraticBezierTo(.66, 1.12, .52, .92)
    ..quadraticBezierTo(.2, .88, .02, .52)
    ..quadraticBezierTo(-.12, .32, -.22, .04)
    ..close();
  static final _foreVeins = [
    Path()
      ..moveTo(-.1, -.22)
      ..quadraticBezierTo(.5, -.6, 1.3, -.74),
    Path()
      ..moveTo(-.05, -.16)
      ..quadraticBezierTo(.6, -.3, 1.3, -.3),
  ];
  static final _hindVeins = [
    Path()
      ..moveTo(-.05, .12)
      ..quadraticBezierTo(.5, .4, .96, .8),
  ];
  static final _eye = Path()
    ..moveTo(-.3, 0)
    ..quadraticBezierTo(0, -.3, .32, 0)
    ..quadraticBezierTo(0, .29, -.3, 0)
    ..close();
  static final _crescent = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: .17)),
    Path()..addOval(
      Rect.fromCircle(center: const Offset(.075, -.04), radius: .145),
    ),
  );
  static final _abdomen = Path()
    ..moveTo(-.3, -.24)
    ..cubicTo(.3, -.36, 1.02, -.06, 1.42, .26)
    ..quadraticBezierTo(1.52, .38, 1.36, .44)
    ..cubicTo(.84, .6, .2, .54, -.26, .32)
    ..close();
  // Velvet segment bands, pre-clipped to the abdomen once.
  static final _abdomenStripes = Path.combine(
    PathOperation.intersect,
    _abdomen,
    Path.combine(
      PathOperation.union,
      Path.combine(PathOperation.union, _stripe(.24), _stripe(.51)),
      Path.combine(PathOperation.union, _stripe(.78), _stripe(1.05)),
    ),
  );
  static Path _stripe(double x) => Path()
    ..moveTo(x - .04, -.4)
    ..quadraticBezierTo(x + .22, .08, x, .7)
    ..lineTo(x + .08, .7)
    ..quadraticBezierTo(x + .3, .08, x + .04, -.4)
    ..close();
  static final _collarPath = Path()
    ..moveTo(-.76, -.4)
    ..quadraticBezierTo(-.64, -.7, -.42, -.68)
    ..lineTo(-.38, -.57)
    ..quadraticBezierTo(-.2, -.7, -.04, -.55)
    ..lineTo(-.06, -.44)
    ..quadraticBezierTo(.18, -.42, .2, -.2)
    ..lineTo(.09, -.15)
    ..quadraticBezierTo(.32, .0, .22, .18)
    ..lineTo(.1, .17)
    ..quadraticBezierTo(.16, .38, -.02, .44)
    ..lineTo(-.1, .36)
    ..quadraticBezierTo(-.2, .56, -.36, .5)
    ..quadraticBezierTo(-.72, .44, -.82, .12)
    ..quadraticBezierTo(-.88, -.16, -.76, -.4)
    ..close();
  static final _collarShade = Path()
    ..moveTo(-.1, -.3)
    ..quadraticBezierTo(.1, -.1, .06, .1)
    ..quadraticBezierTo(0, .3, -.14, .38)
    ..quadraticBezierTo(-.05, .1, -.1, -.3)
    ..close();
  static final _collarTufts = Path()
    ..moveTo(-.44, -.5)
    ..quadraticBezierTo(-.32, -.42, -.26, -.32)
    ..moveTo(-.16, -.14)
    ..quadraticBezierTo(-.06, -.06, -.04, .04)
    ..moveTo(-.28, .06)
    ..quadraticBezierTo(-.22, .14, -.2, .22);
  // The wine throat is part of the collar silhouette, so it needs no clip.
  static final _bib = Path.combine(
    PathOperation.intersect,
    _collarPath,
    Path()..addOval(
      Rect.fromCenter(center: const Offset(-.84, .44), width: 1.0, height: .9),
    ),
  );
  static final _headPath = Path()
    ..moveTo(-.5, -.68)
    ..cubicTo(-.72, -.88, -1.14, -.82, -1.26, -.52)
    ..quadraticBezierTo(-1.36, -.26, -1.22, -.08)
    ..quadraticBezierTo(-1.12, .05, -.94, .05)
    ..quadraticBezierTo(-.62, .06, -.52, -.18)
    ..quadraticBezierTo(-.42, -.44, -.5, -.68)
    ..close();
  static final _headTuft = Path()
    ..moveTo(-1.1, -.66)
    ..quadraticBezierTo(-.92, -.8, -.66, -.7);

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final _outline = _stroke(_ink, .07);
  static final _thinOutline = _stroke(_ink, .05);
  static final _inkFill = Paint()..color = _ink;
  static final _pearlFill = Paint()..color = _pearl;
  static final _velvetFill = Paint()..color = _velvet;
  static final _velvetRim = _stroke(_velvet, .4);
  static final _pearlHem = _stroke(_silk, .17);
  static final _eyeRim = _stroke(_pearl, .07);
  static final _veinPaint = _stroke(_velvet.withValues(alpha: .3), .045);
  static final _stripeFill = Paint()..color = _velvet.withValues(alpha: .55);
  static final _legPaint = _stroke(_ink, .075);
  static final _tuftPaint = _stroke(_pearl, .05);
  static final _collarShadePaint = Paint()
    ..color = _gold.withValues(alpha: .45);
  static final _headTuftPaint = _stroke(_peach, .06);
  static final _blush = Paint()..color = _rose.withValues(alpha: .55);
  static final _brow = _stroke(_ink, .065);
  static final _proboscis = _stroke(_ink, .055);
  static final _antennaStem = _stroke(_ink, .06);
  static final _antennaRib = _stroke(_gold, .035);
  static final _antennaFarRib = _stroke(_wine, .03);
  static final _silkFill = Paint()..color = _silk;
  static final _roseFill = Paint()..color = _rose;
  static final _wineFill = Paint()..color = _wine;
  static final _emberFill = Paint()..color = _ember;
  static final _hotFill = Paint()..color = _hot;

  static final _foreFill = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-.95, .7),
      radius: 1.25,
      colors: [_peach, _coral, _rose, _wine],
      stops: [0, .3, .62, 1],
    ).createShader(const Rect.fromLTRB(-.4, -1.2, 1.9, .1));
  static final _hindFill = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-1, -1),
      radius: 1.5,
      colors: [_coral, _rose, _wine],
      stops: [.1, .5, 1],
    ).createShader(const Rect.fromLTRB(-.25, 0, 1.5, 1.15));
  static final _farFill = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_rose, _wine, _velvet],
    ).createShader(const Rect.fromLTRB(-.4, -1.2, 1.9, 1.15));
  static final _abdomenFill = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_coral, _rose, _wine],
    ).createShader(const Rect.fromLTRB(-.3, -.36, 1.5, .6));
  static final _collarFill = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_pearl, _silk, _peach],
    ).createShader(const Rect.fromLTRB(-.88, -.7, .32, .56));
  static final _headFill = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_peach, _coral, _rose],
      stops: [0, .55, 1],
    ).createShader(const Rect.fromLTRB(-1.36, -.86, -.42, .06));

  static double _smooth(double x) {
    final t = x.isFinite ? x.clamp(0.0, 1.0) : 0.0;
    return t * t * (3 - 2 * t);
  }

  static double _unit(double value, double low, double high) =>
      value.isFinite ? value.clamp(low, high) : 0;
}
