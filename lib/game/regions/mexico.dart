import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Mexico at dusk: the Sierra Madre in violet, a colonial hill town of
/// pastel houses around a twin-towered cathedral, agave fields and saguaros
/// on the dusty plain, and prickly pear beside a swinging piñata on the near
/// ground. Strings of papel picado sway across a glowing sky and marigold
/// petals drift on the evening air.
class MexicoScene extends RegionScene {
  const MexicoScene();

  @override
  WorldRegion get region => WorldRegion.mexico;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.7, .5),
    radius: .07,
    disc: Color(0xffffc07a),
    glow: Color(0xffff8f5a),
    halo: .55,
    strength: .5,
  );

  static final _weather = Weather(Weather.of([(Mote.petal, 14)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xfff0a67a);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xff8a6a9e),
      Color(0xff7a5c8e),
      Color(0xffd08aa0),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xff9a5f4a),
      Color(0xff7f4d3f),
      Color(0xffe0906a),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xffb87a4a),
      Color(0xff9a6238),
      Color(0xffeaa878),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xff6a4a3a),
      Color(0xff4f382e),
      Color(0xffa87a58),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .67 - .05 * Sketch.peaks(x / 1.3 + .1) - .015 * Sketch.peaks(x / .45),
    Depth.mid => .76 - .02 * Sketch.humps(x / 1.4),
    Depth.low => .855 - .01 * Sketch.humps(x / 1.5 + .2),
    Depth.near => .94 - .01 * Sketch.humps(x / 1.5),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    Depth.mid => .3,
    Depth.low => .2,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  static const _wash = [
    Color(0xffe94f6a),
    Color(0xfff6a21b),
    Color(0xff4fc3d9),
    Color(0xfff6e26a),
    Color(0xffb56ac0),
    Color(0xffef7a4a),
  ];

  double _y(Depth d, double x, double h) => ridge(d, x / h, 0) * h;

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        for (final (fx, top, half) in const [(.2, .36, .3), (.55, .32, .34), (.86, .38, .28)]) {
          c.drawPath(
            Sketch.poly([w * fx - h * half, h * .7, w * fx, h * top, w * fx + h * half, h * .7]),
            Paint()..color = _hazed(const Color(0xff7a5c8e), .35),
          );
        }
      case Depth.mid:
        _town(c, w, h, h * .05, .35, 0);
        _church(c, Offset(w * .56, _y(Depth.mid, w * .56, h) + h * .03), h * .34);
        _town(c, w, h, h * .03, .05, 1);
      case Depth.low:
        for (var i = 0; i < 6; i++) {
          final x = span * (i + .3 + .4 * Sketch.hash(i + 720)) / 6;
          Scenery.agave(
            c,
            Offset(x, _y(d, x, h) + h * .012),
            h * (.05 + .02 * Sketch.hash(i + 721)),
            const Color(0xff4f8a86),
            const Color(0xff7fb8a8),
          );
        }
        for (final (fx, s) in const [(.25, 1.0), (.8, .8)]) {
          final x = span * fx;
          Scenery.cactus(c, Offset(x, _y(d, x, h) + h * .012), h * .2 * s, const Color(0xff3f7a4a), const Color(0xff69a55f));
        }
      case Depth.near:
        for (final (fx, s) in const [(.06, 1.0), (.68, .8), (.9, .7)]) {
          final x = span * fx;
          _pear(c, Offset(x, _y(d, x, h) + h * .012), h * .12 * s);
        }
        // Two posts and a beam hold the piñata.
        final wood = Paint()..color = const Color(0xff3a2a24);
        for (final fx in const [.4, .56]) {
          final x = span * fx;
          c.drawRect(Rect.fromLTRB(x - h * .006, _y(d, x, h) - h * .3, x + h * .006, _y(d, x, h) + h * .012), wood);
        }
        c.drawRect(
          Rect.fromLTRB(span * .4 - h * .008, _y(d, span * .4, h) - h * .3, span * .56 + h * .008, _y(d, span * .4, h) - h * .29),
          wood,
        );
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.near) return;
    final h = f.h, span = period(d) * h;
    final anchor = Offset(span * .48, _y(d, span * .48, h) - h * .295);
    final swing = math.sin(f.clock * 1.6 + copy) * .3;
    final len = h * .09;
    final at = anchor + Offset(math.sin(swing) * len, math.cos(swing) * len);
    c.drawLine(
      anchor,
      at,
      Paint()
        ..color = const Color(0xffe8d2a0)
        ..strokeWidth = math.max(.8, h * .002),
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(swing * 1.4);
    final r = h * .045;
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = r * (i.isEven ? 1.0 : .45);
      final p = Offset(math.cos(a), math.sin(a)) * rad;
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    c.drawPath(star..close(), Paint()..color = _wash[(copy.abs()) % _wash.length]);
    c.drawCircle(Offset.zero, r * .3, Paint()..color = const Color(0xfffff1b0));
    c.restore();
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .68), width: f.w * 1.3, height: h * .08),
          const Color(0xffffc9a8),
          .6 * presence,
        );
      case Depth.mid:
        // Windows of the hill town begin to glow with the dusk.
        final glow = Paint()..color = Sketch.fade(const Color(0xffffd36b), .8 * presence);
        for (var i = 0; i < 24; i++) {
          final x = (f.w + h * .6) * Sketch.hash(i + 740) - h * .3;
          final y = (ridge(Depth.mid, x / h, 0) + .015 + .03 * Sketch.hash(i + 741)) * h;
          c.drawRect(Rect.fromLTWH(x, y, h * .005, h * .007), glow);
        }
      case Depth.low || Depth.near:
        break;
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    for (final (fx, fy, fw) in const [(.25, .2, .5), (.75, .3, .4)]) {
      final x = (w * fx - f.clock * h * .006) % (w + h * 1.2) - h * .6;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .04),
        const Color(0xffffb48a),
        .55 * presence,
      );
    }
    // Strings of papel picado: cut-paper flags sway along two swags.
    final string = Paint()
      ..style = PaintingStyle.stroke
      ..color = Sketch.fade(const Color(0xff4a2f3f), .7 * presence)
      ..strokeWidth = math.max(.8, h * .002);
    for (final (index, (y0, sag)) in const [(.08, .05), (.19, .04)].indexed) {
      double yAt(double u) => h * (y0 + sag * 4 * u * (1 - u));
      final path = Path()..moveTo(0, yAt(0));
      for (var i = 1; i <= 30; i++) {
        path.lineTo(w * i / 30, yAt(i / 30));
      }
      c.drawPath(path, string);
      final count = (w / (h * .07)).ceil() + 1;
      final fw = h * .05, fh = h * .04;
      for (var k = 0; k <= count; k++) {
        final u = k / count;
        final x = w * u + math.sin(f.clock * 1.5 + k * .8 + index) * h * .004;
        final y = yAt(u);
        c.drawPath(
          Sketch.poly([
            x - fw / 2, y, x + fw / 2, y, x + fw / 2, y + fh, //
            x + fw / 4, y + fh * .78, x, y + fh, x - fw / 4, y + fh * .78,
            x - fw / 2, y + fh,
          ]),
          Paint()..color = Sketch.fade(_wash[(k + index * 2) % _wash.length], .9 * presence),
        );
        c.drawCircle(
          Offset(x, y + fh * .3),
          fw * .1,
          Paint()..color = Sketch.fade(const Color(0xffffe6b0), .8 * presence),
        );
      }
    }
  }

  /// Rows of pastel houses with flat roofs, offset [lift] above the hill.
  void _town(Canvas c, double w, double h, double lift, double haze, int row) {
    var x = -h * .1;
    var i = 0;
    while (x < w + h * .1) {
      final seed = row * 300 + i;
      final bw = h * (.05 + .03 * Sketch.hash(seed + 700));
      final bh = h * (.05 + .06 * Sketch.hash(seed + 701));
      final base = _y(Depth.mid, x, h) + h * .03 - lift + (row == 0 ? 0 : h * .01);
      final color = _hazed(_wash[(seed * 7 + 3) % _wash.length], haze);
      c.drawRect(Rect.fromLTRB(x, base - bh, x + bw, base), Paint()..color = color);
      c.drawRect(
        Rect.fromLTRB(x, base - bh - h * .006, x + bw, base - bh),
        Paint()..color = _hazed(const Color(0xff7f3d33), haze),
      );
      Scenery.windows(
        c,
        Rect.fromLTRB(x + bw * .05, base - bh + h * .004, x + bw * .95, base - h * .004),
        cols: 2,
        rows: math.max(1, (bh / (h * .03)).floor()),
        lit: _hazed(const Color(0xffffd36b), haze * .5),
        dark: _hazed(const Color(0xff3a2a3a), haze),
        seed: seed,
        litChance: .4,
      );
      x += bw + h * .003;
      i++;
    }
  }

  /// A cathedral: a broad nave between two bell towers under a great dome.
  static void _church(Canvas c, Offset base, double s) {
    final wall = _hazed(const Color(0xffe0a458), .15);
    final shade = _hazed(const Color(0xffb87a3a), .18);
    final dome = _hazed(const Color(0xffc9583a), .15);
    final domeLit = _hazed(const Color(0xffe6805a), .15);
    final dark = _hazed(const Color(0xff4a2f2a), .2);
    Scenery.dome(c, Offset(base.dx, base.dy - s * .32), s * .16, s * .3, dome, domeLit);
    c.drawRect(Rect.fromLTRB(base.dx - s * .3, base.dy - s * .32, base.dx + s * .3, base.dy), Paint()..color = wall);
    c.drawRect(Rect.fromLTRB(base.dx, base.dy - s * .32, base.dx + s * .3, base.dy), Paint()..color = shade);
    for (final side in const [-1.0, 1.0]) {
      final cx = base.dx + side * s * .22;
      c.drawRect(Rect.fromLTRB(cx - s * .07, base.dy - s * .62, cx + s * .07, base.dy), Paint()..color = wall);
      c.drawRect(Rect.fromLTRB(cx, base.dy - s * .62, cx + s * .07, base.dy), Paint()..color = shade);
      c.drawRect(Rect.fromLTRB(cx - s * .04, base.dy - s * .58, cx + s * .04, base.dy - s * .5), Paint()..color = dark);
      Scenery.dome(c, Offset(cx, base.dy - s * .62), s * .08, s * .14, dome, domeLit);
      c.drawLine(
        Offset(cx, base.dy - s * .76),
        Offset(cx, base.dy - s * .82),
        Paint()
          ..color = dark
          ..strokeWidth = math.max(.8, s * .01),
      );
    }
    Scenery.arches(c, Rect.fromLTRB(base.dx - s * .07, base.dy - s * .2, base.dx + s * .07, base.dy), 1, dark);
    Scenery.arches(c, Rect.fromLTRB(base.dx - s * .07, base.dy - s * .3, base.dx + s * .07, base.dy - s * .24), 1, dark);
  }

  /// A prickly pear: stacked oval pads with pink fruit on the rims.
  static void _pear(Canvas c, Offset base, double s) {
    const pad = Color(0xff4f9a5a), lit = Color(0xff7fc27a);
    for (final (dx, dy, w, h, tilt) in const [
      (0.0, -.35, .5, .62, 0.0),
      (-.32, -.72, .4, .5, -.4),
      (.3, -.78, .4, .5, .35),
      (.02, -1.05, .34, .44, .1),
    ]) {
      c.save();
      c.translate(base.dx + dx * s, base.dy + dy * s);
      c.rotate(tilt);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: w * s, height: h * s), Paint()..color = pad);
      c.drawOval(
        Rect.fromCenter(center: Offset(-w * s * .12, -h * s * .1), width: w * s * .45, height: h * s * .55),
        Paint()..color = lit,
      );
      c.restore();
    }
    for (final (dx, dy) in const [(-.5, -.95), (.5, -1.02), (.2, -1.32)]) {
      c.drawCircle(Offset(base.dx + dx * s, base.dy + dy * s), s * .07, Paint()..color = const Color(0xffe6407a));
    }
  }
}
