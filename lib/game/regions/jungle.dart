import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// A rainforest on a misty morning: a sheer tepui with a ribbon waterfall on
/// the horizon, emergent kapok trees over a rolling canopy, a rope bridge
/// between giants and broad leaves, ferns and heliconia in the foreground.
/// Sun rays slant through the haze; leaves drift and fireflies glow low.
class JungleScene extends RegionScene {
  const JungleScene();

  @override
  WorldRegion get region => WorldRegion.jungle;

  @override
  double get horizon => .6;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.2, .17),
    radius: .052,
    disc: Color(0xfffffbe8),
    glow: Color(0xfffff1b8),
    halo: .6,
    strength: .52,
  );

  static final _weather = Weather(
    Weather.of([(Mote.leaf, 8), (Mote.firefly, 14)]),
  );
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffd3e6c8);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffb3d2bf),
      Color(0xffa6c9b3),
      Color(0xffd9ebd4),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xff74b389),
      Color(0xff579c72),
      Color(0xffa5d69c),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xff43905f),
      Color(0xff2f744d),
      Color(0xff7fc47f),
    ),
    Depth.near => const Ground(
      Color(0xff2a6b47),
      Color(0xff1d5036),
      Color(0xff4f9a5e),
      rimWidth: .006,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far =>
      .64 - .045 * Sketch.humps(x / 1.3 + .2) - .02 * Sketch.humps(x / .55),
    Depth.mid =>
      .7 - .03 * Sketch.humps(x / .23) - .025 * Sketch.humps(x / .61 + .3),
    Depth.low =>
      .8 - .035 * Sketch.humps(x / .3) - .03 * Sketch.humps(x / .75 + .5),
    Depth.near =>
      .92 - .04 * Sketch.humps(x / .425) - .025 * Sketch.humps(x / 1.7 + .3),
  };

  @override
  double period(Depth d) => d == Depth.low ? 3.0 : 3.4;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .42,
    Depth.mid => .34,
    Depth.low => .42,
    Depth.near => .3,
  };

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _tepui(c, w * .68, h);
      case Depth.mid:
        for (final (fx, s, bloom) in const [
          (.12, 1.0, 0),
          (.3, .75, 1),
          (.42, .85, 0),
          (.62, .7, 2),
          (.94, 1.1, 0),
          (1.12, .8, 1),
        ]) {
          _kapok(c, Offset(w * fx, h * .72), h * .2 * s, bloom: bloom);
        }
      case Depth.low:
        _giant(c, Offset(h * .6, h * .82), h * .36);
        _giant(c, Offset(h * 1.5, h * .82), h * .3);
        _bridge(c, Offset(h * .6, h * .56), Offset(h * 1.5, h * .6), h);
      case Depth.near:
        for (final (fx, s, kind) in const [
          (.04, 1.0, 3),
          (.16, .9, 0),
          (.27, .8, 1),
          (.36, 1.0, 2),
          (.5, 1.15, 3),
          (.62, .95, 0),
          (.73, .85, 1),
          (.84, 1.05, 2),
          (.93, .9, 0),
          (.1, .7, 1),
          (.44, .75, 0),
          (.57, .7, 1),
          (.79, .75, 0),
        ]) {
          final at = Offset(period(d) * h * fx, h * .945);
          switch (kind) {
            case 0:
              _monstera(c, at, h * .12 * s);
            case 1:
              _fern(c, at, h * .13 * s);
            case 2:
              _heliconia(c, at, h * .15 * s);
            default:
              _banana(c, at, h * .26 * s);
          }
        }
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.far) return;
    // The waterfall's veil streams down the tepui cliff.
    final h = f.h;
    final x = f.w * .68 + h * .02;
    final top = h * .37, bottom = h * .64;
    final fall = Paint()
      ..color = const Color(0xf2fafffb)
      ..strokeWidth = h * .011;
    c.drawLine(Offset(x, top), Offset(x, bottom), fall);
    c.drawLine(
      Offset(x + h * .014, top + h * .02),
      Offset(x + h * .016, bottom),
      fall..strokeWidth = h * .004,
    );
    final streak = Paint()
      ..color = const Color(0x99c8ebe6)
      ..strokeWidth = h * .003
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final phase = (f.clock * .09 + i / 6) % 1;
      final y = top + phase * (bottom - top);
      // Streaks fade in at the lip and out at the plunge pool.
      streak.color = const Color(
        0xffc8ebe6,
      ).withValues(alpha: .6 * math.sin(phase * math.pi));
      c.drawLine(
        Offset(x - h * .002, y),
        Offset(x - h * .002, y + h * .02),
        streak,
      );
    }
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(x, bottom),
        width: h * .22,
        height: h * .08,
      ),
      const Color(0xffffffff),
      .85,
    );
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        // Morning mist pools at the foot of the tepui.
        final span = f.w + h * 1.6;
        for (var i = 0; i < 4; i++) {
          final x = (span * i / 4 + f.clock * h * .008) % span - h * .6;
          Sketch.mist(
            c,
            Rect.fromCenter(
              center: Offset(x, h * (.63 + .012 * (i % 2))),
              width: h * (.6 + .2 * (i % 3)),
              height: h * .08,
            ),
            _haze,
            .6 * presence,
          );
        }
      case Depth.mid || Depth.low:
        // Sunlit crowns: a lit band hugs the top of every canopy hump,
        // thickest on the side facing the sun.
        final low = d == Depth.low;
        final wave = low ? .3 : .23;
        final lit = Paint()
          ..color = Sketch.fade(
            low ? const Color(0xff5fa86c) : const Color(0xff97cc98),
            .8 * presence,
          );
        final span = d.timed ? f.w + h * 1.2 : period(d) * h;
        final from = d.timed ? -h * .4 : 0.0;
        for (
          var k = (from / h / wave).floor();
          k * wave * h < from + span;
          k++
        ) {
          final crown = Path();
          for (var i = 0; i <= 6; i++) {
            final x = (k + i / 6) * wave;
            final y = ridge(d, x, 0) * h;
            if (i == 0) {
              crown.moveTo(x * h, y);
            } else {
              crown.lineTo(x * h, y);
            }
          }
          for (var i = 6; i >= 0; i--) {
            final t = i / 6;
            final x = (k + t) * wave;
            final thick =
                h * (low ? .02 : .014) * math.sin(math.pi * t) * (1.2 - t * .8);
            crown.lineTo(x * h, ridge(d, x, 0) * h + thick);
          }
          c.drawPath(crown..close(), lit);
        }
        if (d == Depth.mid) {
          final span2 = f.w + h * 1.2;
          for (var i = 0; i < 3; i++) {
            final x = (span2 * i / 3 + f.clock * h * .012) % span2 - h * .4;
            Sketch.mist(
              c,
              Rect.fromCenter(
                center: Offset(x, h * .735),
                width: h * .7,
                height: h * .07,
              ),
              _haze,
              .5 * presence,
            );
          }
        }
      case Depth.near:
        // Ground cover: leafy clumps crowd the ridge line.
        final span = period(d) * h;
        // Broad leaves layered through the undergrowth keep it from reading
        // as a flat band.
        final under = Paint()
          ..color = Sketch.fade(const Color(0xff2b7048), .9 * presence);
        for (var i = 0; i < 14; i++) {
          final x = span * (i + Sketch.hash(i + 730) * .7) / 14;
          final y = ridge(d, x / h, 0) * h + h * (.05 + .06 * Sketch.hash(i + 731));
          final s = h * (.035 + .02 * Sketch.hash(i + 732));
          c.save();
          c.translate(x, y);
          c.rotate(-.6 + 1.2 * Sketch.hash(i + 733));
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 2.6, height: s), under);
          c.restore();
        }
        final dark = Paint()
          ..color = Sketch.fade(const Color(0xff2f7a4c), presence);
        final lit = Paint()
          ..color = Sketch.fade(const Color(0xff4f9f5c), presence);
        for (var i = 0; i < 16; i++) {
          final x = span * (i + Sketch.hash(i + 700) * .6) / 16;
          final y = ridge(d, x / h, 0) * h + h * .012;
          final s = h * (.022 + .016 * Sketch.hash(i + 710));
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x, y),
              width: s * 2.6,
              height: s * 1.3,
            ),
            dark,
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x - s * .5, y - s * .35),
              width: s * 1.5,
              height: s * .8,
            ),
            lit,
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x + s * .6, y - s * .1),
              width: s * 1.2,
              height: s * .7,
            ),
            lit,
          );
        }
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final sun = Offset(w * .2, h * .17);
    // Sun rays slanting through the humid air.
    for (var i = 0; i < 5; i++) {
      final a = .5 + i * .2;
      final pulse = .75 + .25 * math.sin(f.clock * .5 + i * 1.7);
      final spread = .045 + .02 * (i % 2);
      final far = h * 1.3;
      c.drawPath(
        Path()
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(
            sun.dx + math.cos(a - spread) * far,
            sun.dy + math.sin(a - spread) * far,
          )
          ..lineTo(
            sun.dx + math.cos(a + spread) * far,
            sun.dy + math.sin(a + spread) * far,
          )
          ..close(),
        Paint()
          ..shader = Gradient.radial(sun, far, [
            Sketch.fade(const Color(0xfffff6cf), .22 * pulse * presence),
            Sketch.fade(const Color(0xfffff6cf), 0),
          ]),
      );
    }
    // A pair of scarlet macaws crossing high.
    for (var i = 0; i < 2; i++) {
      final x =
          (w * (.9 + i * .06) - f.clock * h * .05) % (w + h * .4) - h * .2;
      final y = h * (.12 + i * .04) + math.sin(f.clock * .8 + i) * h * .01;
      _macaw(
        c,
        Offset(x, y),
        h * .018,
        math.sin(f.clock * 5 + i * 2),
        presence,
      );
    }
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  /// A flat-topped tepui with sheer, streaked walls.
  static void _tepui(Canvas c, double x, double h) {
    final face = _hazed(const Color(0xff8fb3a3), .35);
    final lit = _hazed(const Color(0xffb7cfb8), .3);
    final top = _hazed(const Color(0xff7fae8a), .3);
    final wall = Sketch.poly([
      x - h * .34, h * .7, x - h * .28, h * .44, x - h * .22, h * .37, //
      x + h * .2, h * .36, x + h * .27, h * .42, x + h * .36, h * .7,
    ]);
    c.drawPath(wall, Paint()..color = face);
    c.drawPath(
      Sketch.poly([
        x - h * .34, h * .7, x - h * .28, h * .44, x - h * .22, h * .37, //
        x - h * .12, h * .37, x - h * .16, h * .7,
      ]),
      Paint()..color = lit,
    );
    // Forest cap on the summit plateau.
    final cap = Path()..moveTo(x - h * .23, h * .38);
    for (var i = 0; i <= 10; i++) {
      final px = x - h * .23 + h * .44 * i / 10;
      cap.lineTo(px, h * (.362 - .008 * Sketch.humps(i / 2)));
    }
    cap
      ..lineTo(x + h * .21, h * .385)
      ..close();
    c.drawPath(cap, Paint()..color = top);
    final streak = Paint()
      ..color = Sketch.fade(_hazed(const Color(0xff6f978a), .3), .6)
      ..strokeWidth = h * .003;
    for (var i = 0; i < 9; i++) {
      final sx = x - h * .1 + h * .34 * i / 9;
      c.drawLine(
        Offset(sx, h * .4),
        Offset(sx + h * .01, h * (.52 + .06 * Sketch.hash(i))),
        streak,
      );
    }
  }

  /// An emergent rainforest tree: a slim trunk and a billowing crown that
  /// towers over the canopy.
  static void _kapok(Canvas c, Offset base, double s, {int bloom = 0}) {
    final trunk = _hazed(const Color(0xff8a9580), .3);
    // Some emergents are in flower: pink or golden trumpet trees.
    final (crownColor, shadeColor, litColor) = switch (bloom) {
      1 => (
        const Color(0xffe58fb0),
        const Color(0xffc9708f),
        const Color(0xfff6bcd0),
      ),
      2 => (
        const Color(0xffe8c24f),
        const Color(0xffc9a23a),
        const Color(0xfff6e08a),
      ),
      _ => (
        const Color(0xff5c9d74),
        const Color(0xff4c8a66),
        const Color(0xff93c99a),
      ),
    };
    final crown = _hazed(crownColor, .28);
    final shade = _hazed(shadeColor, .28);
    final lit = _hazed(litColor, .25);
    c.drawPath(
      Sketch.poly([-.03, 0, -.018, -.72, .018, -.72, .03, 0], at: base, s: s),
      Paint()..color = trunk,
    );
    for (final (dx, dy, r, paint) in [
      (-.22, -.74, .2, shade),
      (.22, -.76, .19, shade),
      (0.0, -.84, .26, crown),
      (-.18, -.9, .17, crown),
      (.16, -.92, .16, crown),
      (-.08, -.98, .12, lit),
      (.1, -1.0, .1, lit),
    ]) {
      c.drawCircle(
        base + Offset(dx * s, dy * s),
        r * s,
        Paint()..color = paint,
      );
    }
  }

  /// A buttressed giant whose crown reaches over the canopy.
  static void _giant(Canvas c, Offset base, double s) {
    const bark = Color(0xff6f6250), shade = Color(0xff54493c);
    const leaf = Color(0xff4f9a6a), leafLit = Color(0xff79bb7f);
    c.drawPath(
      Sketch.poly(
        [-.18, .05, -.06, -.2, -.05, -.9, .05, -.9, .06, -.2, .2, .05],
        at: base,
        s: s,
      ),
      Paint()..color = bark,
    );
    c.drawPath(
      Sketch.poly(
        [.02, -.9, .05, -.9, .06, -.2, .2, .05, .04, .05],
        at: base,
        s: s,
      ),
      Paint()..color = shade,
    );
    for (final (dx, dy, r, lit) in const [
      (-.28, -.9, .2, false),
      (.26, -.92, .2, false),
      (0, -1.02, .24, false),
      (-.16, -1.08, .15, true),
      (.14, -1.1, .14, true),
    ]) {
      c.drawOval(
        Rect.fromCenter(
          center: base + Offset(dx * s, dy * s),
          width: r * s * 2.2,
          height: r * s * 1.3,
        ),
        Paint()..color = lit ? leafLit : leaf,
      );
    }
  }

  static void _bridge(Canvas c, Offset a, Offset b, double h) {
    final rope = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .004
      ..color = const Color(0xff8a6a48);
    final sag = h * .07;
    Offset at(double t, double lift) {
      final p = Offset.lerp(a, b, t)!;
      return p + Offset(0, sag * 4 * t * (1 - t) - lift);
    }

    for (final lift in [0.0, h * .035]) {
      final path = Path()..moveTo(a.dx, a.dy - lift);
      for (var i = 1; i <= 16; i++) {
        final p = at(i / 16, lift);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, rope);
    }
    final plank = Paint()
      ..color = const Color(0xffa57e55)
      ..strokeWidth = h * .006
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 20; i++) {
      final p = at(i / 20, 0);
      c.drawLine(p, p + Offset(0, h * .006), plank);
      c.drawLine(p, at(i / 20, h * .035), rope..strokeWidth = h * .002);
    }
    rope.strokeWidth = h * .004;
  }

  /// A monstera: heart-shaped leaves on arching stalks, split to the rib.
  static void _monstera(Canvas c, Offset base, double s) {
    const leaf = Color(0xff2f8a55),
        lit = Color(0xff4fa86a),
        vein = Color(0xff1f6440);
    final stalk = Paint()
      ..color = const Color(0xff3f8a4f)
      ..strokeWidth = s * .05
      ..style = PaintingStyle.stroke;
    for (final (a, len, tilt, color) in const [
      (-2.3, .75, -.5, leaf),
      (-.85, .8, .45, leaf),
      (-1.6, .95, 0.0, lit),
    ]) {
      final tip = base + Offset(math.cos(a) * s * len, math.sin(a) * s * len);
      c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(base.dx, tip.dy, tip.dx, tip.dy),
        stalk,
      );
      c.save();
      c.translate(tip.dx, tip.dy);
      c.rotate(tilt);
      final r = s * .5;
      // Heart-shaped blade hanging from the stalk tip.
      final blade = Path()
        ..moveTo(0, 0)
        ..cubicTo(-r * .3, -r * .55, -r * 1.25, -r * .35, -r * .95, r * .45)
        ..cubicTo(-r * .7, r * 1.05, -r * .15, r * 1.25, 0, r * 1.45)
        ..cubicTo(r * .15, r * 1.25, r * .7, r * 1.05, r * .95, r * .45)
        ..cubicTo(r * 1.25, -r * .35, r * .3, -r * .55, 0, 0)
        ..close();
      c.drawPath(blade, Paint()..color = color);
      c.drawLine(
        Offset.zero,
        Offset(0, r * 1.3),
        Paint()
          ..color = vein
          ..strokeWidth = s * .025,
      );
      // Fenestration: slits running in from the edge.
      final slit = Paint()
        ..color = const Color(0xff1d5036)
        ..strokeWidth = s * .045
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 3; k++) {
        final y = r * (.2 + k * .35);
        c.drawLine(
          Offset(-r * .95 + k * r * .12, y),
          Offset(-r * .3, y + r * .12),
          slit,
        );
        c.drawLine(
          Offset(r * .95 - k * r * .12, y),
          Offset(r * .3, y + r * .12),
          slit,
        );
      }
      c.restore();
    }
  }

  /// A banana plant: a green pseudostem and long ribbed blades arching out,
  /// their edges torn by the wind.
  static void _banana(Canvas c, Offset base, double s) {
    const stem = Color(0xff5b9a4a),
        blade = Color(0xff4c9d58),
        lit = Color(0xff7cc56c);
    c.drawPath(
      Sketch.poly([-.05, 0, -.035, -.45, .035, -.45, .05, 0], at: base, s: s),
      Paint()..color = stem,
    );
    final top = base + Offset(0, -s * .45);
    for (final (a, len, droop, color) in const [
      (-2.6, .62, .55, blade),
      (-.5, .66, .5, blade),
      (-2.05, .7, .25, lit),
      (-1.1, .72, .22, lit),
      (-1.62, .55, .02, blade),
    ]) {
      final dir = Offset(math.cos(a), math.sin(a));
      final tip = top + dir * s * len + Offset(0, s * len * droop);
      final mid = top + dir * s * len * .55 - Offset(0, s * .06);
      final side = Offset(-dir.dy, dir.dx) * s * .11;
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          mid.dx + side.dx * 1.4,
          mid.dy + side.dy * 1.4,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          mid.dx - side.dx * 1.4,
          mid.dy - side.dy * 1.4,
          top.dx,
          top.dy,
        )
        ..close();
      c.drawPath(path, Paint()..color = color);
      c.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xffcfe8a0)
          ..strokeWidth = s * .012,
      );
      // Tears in the blade, perpendicular to the rib.
      final tear = Paint()
        ..color = const Color(0xff2a6b47)
        ..strokeWidth = s * .01;
      for (var k = 1; k < 5; k++) {
        final t = k / 5;
        final p = Offset.lerp(
          Offset.lerp(top, mid, t)!,
          Offset.lerp(mid, tip, t)!,
          t,
        )!;
        final reach = 1.1 * math.sin(math.pi * t);
        final sign = k.isEven ? 1.0 : -1.0;
        c.drawLine(p + side * (.25 * sign), p + side * (reach * sign), tear);
      }
    }
  }

  static void _fern(Canvas c, Offset base, double s) {
    final frond = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .035
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xff4f9f5f);
    final leaflet = Paint()
      ..strokeWidth = s * .05
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xff6fbb6c);
    for (final a in const [-2.5, -2.0, -1.55, -1.1, -.65]) {
      final tip =
          base +
          Offset(math.cos(a) * s, math.sin(a) * s * .9) +
          Offset(0, s * .25);
      final ctrl = base + Offset(math.cos(a) * s * .6, math.sin(a) * s * .9);
      c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy),
        frond,
      );
      for (var k = 1; k < 7; k++) {
        final t = k / 7;
        final p = Offset(
          (1 - t) * (1 - t) * base.dx +
              2 * (1 - t) * t * ctrl.dx +
              t * t * tip.dx,
          (1 - t) * (1 - t) * base.dy +
              2 * (1 - t) * t * ctrl.dy +
              t * t * tip.dy,
        );
        final len = s * .12 * (1 - t * .6);
        c.drawLine(p, p + Offset(-len * .6, -len), leaflet);
        c.drawLine(p, p + Offset(len * .6, -len * .7), leaflet);
      }
    }
  }

  static void _heliconia(Canvas c, Offset base, double s) {
    final stem = Paint()
      ..color = const Color(0xff3f8a52)
      ..strokeWidth = s * .04;
    c.drawLine(base, base + Offset(0, -s), stem);
    // Paddle leaves, then the zigzag of red and gold bracts.
    for (final side in const [-1.0, 1.0]) {
      final tip = base + Offset(side * s * .55, -s * .75);
      c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy - s * .1)
          ..quadraticBezierTo(
            base.dx + side * s * .45,
            base.dy - s * .25,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            base.dx + side * s * .1,
            base.dy - s * .55,
            base.dx,
            base.dy - s * .1,
          )
          ..close(),
        Paint()..color = const Color(0xff3a9258),
      );
    }
    for (var k = 0; k < 5; k++) {
      final side = k.isEven ? 1.0 : -1.0;
      final y = base.dy - s * (.95 - k * .12);
      c.drawPath(
        Sketch.poly([
          base.dx,
          y,
          base.dx + side * s * .2,
          y - s * .05,
          base.dx,
          y + s * .08, //
        ]),
        Paint()..color = const Color(0xffe8503f),
      );
      c.drawLine(
        Offset(base.dx + side * s * .02, y),
        Offset(base.dx + side * s * .18, y - s * .04),
        Paint()
          ..color = const Color(0xfff6c94a)
          ..strokeWidth = s * .02,
      );
    }
  }

  static void _macaw(
    Canvas c,
    Offset p,
    double s,
    double flap,
    double presence,
  ) {
    final body = Paint()
      ..color = Sketch.fade(const Color(0xffe0483c), presence);
    final wing = Paint()
      ..color = Sketch.fade(const Color(0xff3f7fd0), presence);
    final tail = Paint()
      ..color = Sketch.fade(const Color(0xffe0483c), presence)
      ..strokeWidth = s * .3
      ..strokeCap = StrokeCap.round;
    c.drawLine(p, p + Offset(s * 1.8, s * .3), tail);
    c.drawOval(
      Rect.fromCenter(center: p, width: s * 1.6, height: s * .6),
      body,
    );
    c.drawPath(
      Sketch.poly([-.3, 0, .3, 0, .1, -1.1 * flap - .2], at: p, s: s),
      wing,
    );
    c.drawCircle(p + Offset(-s * .8, -s * .1), s * .3, body);
  }
}
