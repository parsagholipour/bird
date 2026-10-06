import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';

/// The Pirate Captain's weather: a moonlit haze hugging the sea, mist banks
/// that gather as each surge nears, gulls wheeling far off, a bank of storm
/// cloud along the top edge and the flashes of a storm that follows the
/// tide. Painted behind the ship and the sea, over the regional scenery, and
/// kept faint and cool so the bird's lane and every hazard stay legible.
abstract final class PirateMoodArt {
  static const _night = Color(0xff171c39), _ice = Color(0xffb4f6ea);
  static const _moon = Color(0xffd9e8ff), _haze = Color(0xff6f8fc4);
  static const _cream = Color(0xfffff9ed), _storm = Color(0xff222848);

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));
  static Paint _line(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  static double _hash(int a, [int b = 0]) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static void paint(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    final h = size.height, w = size.width;
    final storm = m.storm;
    final sea = boss.waterLevel ?? SkyBoss.seaHidden;
    final t = m.reducedMotion ? 0.0 : boss.age;
    // Mist gathers as a surge nears and while the water is high.
    final gather = math.max(boss.tideWarning * .7, boss.tide);
    _seaHaze(c, h, w, sea, storm, gather);
    _clouds(c, h, w, t, storm);
    _banks(c, h, w, sea, t, storm, gather);
    _gulls(c, h, w, t, storm, m.reducedMotion);
    if (m.reducedMotion) return;
    _flashes(c, boss, h, w);
  }

  /// A cool haze lying along the water, deepest at the sea line.
  static void _seaHaze(
    Canvas c,
    double h,
    double w,
    double sea,
    double storm,
    double gather,
  ) {
    final base = math.min(sea, .97) * h;
    final rect = Rect.fromLTRB(0, base - h * .36, w, base);
    final a = storm * (.15 + .07 * gather);
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _haze.withValues(alpha: 0),
            _haze.withValues(alpha: a * .5),
            _haze.withValues(alpha: a),
          ],
          stops: const [0, .55, 1],
        ).createShader(rect),
    );
  }

  /// A low bank of storm cloud along the top edge: a dark veil that thins
  /// downward, scalloped where it ends, its underside lit cool.
  static void _clouds(Canvas c, double h, double w, double t, double storm) {
    if (storm <= 0) return;
    final veil = Rect.fromLTWH(0, 0, w, h * .16);
    c.drawRect(
      veil,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _storm.withValues(alpha: .3 * storm),
            _storm.withValues(alpha: 0),
          ],
        ).createShader(veil),
    );
    final puffs = Path();
    final lit = Path();
    final step = h * .11;
    final count = (w / step).ceil() + 2;
    final span = count * step;
    for (var i = 0; i < count; i++) {
      final x = ((i * step - t * h * .012) % span + span) % span - step;
      final r = h * (.04 + _hash(i, 5) * .035);
      final y = h * (.0 + _hash(i, 7) * .012);
      final puff = Rect.fromCenter(
        center: Offset(x, y),
        width: r * 2.4,
        height: r * 1.3,
      );
      puffs.addOval(puff);
      lit.addArc(puff, .5, 2.1);
    }
    c.drawPath(puffs, _fill(_storm, .2 * storm));
    c.drawPath(lit, _line(_moon, h * .0035, .12 * storm));
  }

  /// Mist banks drift left above the sea line: far ones cool and small,
  /// near ones pale and wide, each with a silver rim of moonlight.
  static void _banks(
    Canvas c,
    double h,
    double w,
    double sea,
    double t,
    double storm,
    double gather,
  ) {
    final span = w + h;
    for (var i = 0; i < 7; i++) {
      final tier = i % 3;
      final x =
          ((i * .31 * span - t * h * (.02 + tier * .008)) % span + span) %
              span -
          h * .5;
      final y = (math.min(sea, .92) - .05 - tier * .07) * h;
      final wide = h * (.9 + (i % 2) * .5) * (1 + gather * .25);
      final tall = h * (.07 + tier * .02) * (1 + gather * .35);
      final bank = Rect.fromCenter(
        center: Offset(x, y),
        width: wide,
        height: tall,
      );
      final a = storm * (.14 - tier * .025) * (1 + gather * .7);
      c.drawOval(
        bank,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(_ice, _haze, tier * .3)!.withValues(alpha: a),
              _ice.withValues(alpha: 0),
            ],
          ).createShader(bank),
      );
      // Moonlight catches the top of the bank.
      final rim = Rect.fromCenter(
        center: bank.center.translate(0, -tall * .12),
        width: wide * .6,
        height: tall * .8,
      );
      c.drawArc(
        rim,
        math.pi * 1.12,
        math.pi * .76,
        false,
        _line(_moon, h * .0028, a * .9),
      );
    }
  }

  /// Gulls glide far off over the swell: a few small pale ones and a
  /// nearer, darker pair, wings beating out of step.
  static void _gulls(
    Canvas c,
    double h,
    double w,
    double t,
    double storm,
    bool reduced,
  ) {
    for (var i = 0; i < 5; i++) {
      final near = i < 2;
      final drift = t * h * (near ? .05 : .03 + i * .004);
      final wrap = w + h * .2;
      final x = ((w * (.2 + i * .21) - drift) % wrap + wrap) % wrap - h * .1;
      final y =
          h * ((near ? .14 : .2) + (i % 2) * .09) +
          math.sin(t * .7 + i) * h * .012;
      final flap = reduced ? .4 : math.sin(t * (3.4 + i * .5) + i * 1.7);
      final span = h * (near ? .03 : .016 + (i % 2) * .005);
      final droop = span * .28;
      final gull = Path()
        ..moveTo(x - span, y - span * .32 * flap + droop * .3)
        ..quadraticBezierTo(
          x - span * .5,
          y - span * (.55 + .25 * flap),
          x - span * .1,
          y,
        )
        ..quadraticBezierTo(x, y + span * .12, x + span * .1, y)
        ..quadraticBezierTo(
          x + span * .5,
          y - span * (.55 + .25 * flap),
          x + span,
          y - span * .32 * flap + droop * .3,
        );
      final alpha = storm * (near ? .5 : .34);
      c.drawPath(gull, _line(_night, h * (near ? .0055 : .0038), alpha));
    }
  }

  /// The storm: a forked bolt and a flash of the whole sky as the ship
  /// sails in, then a rumble of two quick flickers as each surge starts.
  static void _flashes(Canvas c, SkyBoss boss, double h, double w) {
    final screen = Offset.zero & Size(w, h);
    if (boss.phase == BossPhase.arriving) {
      final bolt = BossMotion.pulse(boss.age - 1.28, .38);
      if (bolt > 0) {
        c.drawRect(screen, _fill(_moon, bolt * .13));
        _bolt(c, h, Offset(w - h * .5, -h * .05), bolt, 1);
      }
      return;
    }
    // The flash greets a surge that comes, never a calm warm-up cycle.
    if (boss.phase != BossPhase.attacking || !boss.tideRuns) return;
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    final since = cycle - SkyBoss.tideRiseAt;
    final flicker =
        BossMotion.pulse(since, .26) * .7 + BossMotion.pulse(since - .3, .34);
    if (flicker <= 0) return;
    c.drawRect(screen, _fill(_moon, flicker * .09));
    final n = boss.tideRises;
    final x = w * (.18 + .5 * _hash(n, 7));
    _bolt(c, h, Offset(x, -h * .05), math.min(1.0, flicker) * .8, .6);
  }

  static void _bolt(Canvas c, double h, Offset from, double bolt, double size) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(from.dx - h * .13 * size, from.dy + h * .18 * size)
      ..lineTo(from.dx - h * .07 * size, from.dy + h * .19 * size)
      ..lineTo(from.dx - h * .2 * size, from.dy + h * .4 * size);
    final fork = Path()
      ..moveTo(from.dx - h * .13 * size, from.dy + h * .18 * size)
      ..lineTo(from.dx - h * .04 * size, from.dy + h * .27 * size)
      ..lineTo(from.dx - h * .06 * size, from.dy + h * .3 * size);
    for (final p in [path, fork]) {
      c.drawPath(p, _line(_moon, h * .03 * size, bolt * .16));
      c.drawPath(p, _line(_ice, h * .01 * size, bolt * .4));
      c.drawPath(p, _line(_cream, h * .0042 * size, bolt * .85));
    }
  }
}
