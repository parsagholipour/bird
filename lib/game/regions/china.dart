import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// China at dusk, in the manner of a shan shui scroll: karst towers fading
/// into mist under a large red sun, the Great Wall riding a ridge with its
/// watchtowers, a slender pagoda, the Li River with a bamboo raft, and a
/// gnarled pine, a plum in blossom and a pavilion on the near shore. Sky
/// lanterns rise, geese pass in formation and blossom petals drift.
class ChinaScene extends RegionScene {
  const ChinaScene();

  @override
  WorldRegion get region => WorldRegion.china;

  @override
  double get horizon => .62;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.64, .38),
    radius: .072,
    disc: Color(0xfff2856a),
    glow: Color(0xffffbe9c),
    halo: .52,
    strength: .45,
  );

  static final _weather = Weather(Weather.of([(Mote.petal, 18)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xfff2c6b6);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffdcc3c9),
      Color(0xffd0b8c3),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xffa9a4bb),
      Color(0xff7c8599),
      Color(0xffd9c6d0),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xffc1abc4),
      Color(0xff8f8cb0),
      Color(0xffffe4cf),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xff4f6c68),
      Color(0xff3c5552),
      Color(0xff7e9a8f),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .67,
    Depth.mid =>
      .66 - .07 * Sketch.humps(x / 2.2 + .1) - .02 * Sketch.humps(x / .7 + .4),
    Depth.low => .8,
    Depth.near =>
      .925 - .03 * Sketch.humps(x / 1.7 + .2) - .01 * Sketch.humps(x / .425),
  };

  @override
  double period(Depth d) => d == Depth.low ? 3.0 : 3.4;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .46,
    Depth.mid => .18,
    Depth.low => .2,
    Depth.near => .56,
  };

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _karsts(c, w, h);
      case Depth.mid:
        _wall(c, w, h);
        _pagoda(
          c,
          Offset(w * .86, _midRidge(w * .86 / h) * h + h * .01),
          h * .2,
        );
      case Depth.low:
        break;
      case Depth.near:
        final span = period(d) * h;
        _pine(c, Offset(span * .12, h * .93), h * .3);
        _pavilion(c, Offset(span * .5, h * .925), h * .1);
        _plum(c, Offset(span * .82, h * .93), h * .2);
        for (final (fx, s) in const [(.3, 1.0), (.66, .7), (.95, .85)]) {
          _rock(c, Offset(span * fx, h * .935), h * .05 * s);
        }
    }
  }

  double _midRidge(double x) => ridge(Depth.mid, x, 0);

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.near) return;
    final h = f.h;
    final bob = math.sin(f.clock * 1.4 + copy) * h * .002;
    final x = (h * 1.35 - f.clock * h * .006) % (period(d) * h);
    _raft(c, Offset(x, h * .862 + bob), h * .05);
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        // Mist banks wrap the feet of the karst towers.
        for (var i = 0; i < 6; i++) {
          final x =
              (f.w + h) * i / 6 - h * .2 + math.sin(f.clock * .1 + i) * h * .03;
          Sketch.mist(
            c,
            Rect.fromCenter(
              center: Offset(x, h * (.63 + .02 * (i % 2))),
              width: h * .8,
              height: h * .1,
            ),
            const Color(0xfffbe3dc),
            .85 * presence,
          );
        }
      case Depth.mid:
        // River mist rises up the lower slopes, and pine clumps dot them.
        final top = h * .7, bottom = h * .8;
        c.drawRect(
          Rect.fromLTRB(-h * .5, top, f.w + h, bottom),
          Paint()
            ..shader = Gradient.linear(Offset(0, top), Offset(0, bottom), [
              Sketch.fade(const Color(0xfff6dcd6), 0),
              Sketch.fade(const Color(0xfff6dcd6), .7 * presence),
            ]),
        );
        final pine = Paint()
          ..color = Sketch.fade(const Color(0xff5a6f72), .6 * presence);
        for (var i = 0; i < 22; i++) {
          final x = (f.w + h) * Sketch.hash(i + 300) - h * .3;
          final y = (_midRidge(x / h) + .018 + .04 * Sketch.hash(i + 301)) * h;
          final s = h * (.012 + .008 * Sketch.hash(i + 302));
          // A small tiered pine: three stacked, flattened boughs.
          for (var k = 0; k < 3; k++) {
            final half = s * (1 - k * .28);
            final y0 = y - k * s * .55;
            c.drawPath(
              Sketch.poly([
                x - half,
                y0,
                x + half,
                y0,
                x + half * .2,
                y0 - s * .5,
                x - half * .2,
                y0 - s * .5,
              ]),
              pine,
            );
          }
        }
      case Depth.near:
        // Reeds lean out over the water along the shore.
        final span = period(d) * h;
        final reed = Paint()
          ..color = Sketch.fade(const Color(0xff6f8c6e), presence)
          ..strokeWidth = h * .003
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 12; i++) {
          final x = span * (i + Sketch.hash(i + 760) * .5) / 12;
          final y = ridge(d, x / h, 0) * h + h * .01;
          for (var k = -2; k <= 2; k++) {
            final tall = h * (.03 + .012 * (2 - k.abs()));
            c.drawLine(Offset(x + k * h * .004, y), Offset(x + k * h * .012, y - tall), reed);
          }
        }
      case Depth.low:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    // The red sun's long path of light on the river.
    final h = f.h;
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .004;
    for (var i = 0; i < 8; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.5 + i * 1.9);
      glint.color = Sketch.fade(const Color(0xffffe6d2), .6 * on * presence);
      final y = h * (.812 + i * .0075);
      final x = f.w * light.at.dx + math.sin(i * 2.3) * h * .015;
      final len = h * (.055 - i * .005) * (.6 + .4 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // Long ink-wash cloud bands.
    for (final (fx, fy, fw) in const [
      (.2, .2, .5),
      (.7, .12, .4),
      (.45, .3, .3),
    ]) {
      final x = (w * fx - f.clock * h * .006) % (w + h * 1.2) - h * .6;
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x, h * fy),
          width: h * fw * 2,
          height: h * .035,
        ),
        const Color(0xfffce2dc),
        .7 * presence,
      );
    }
    // Wild geese in a loose V.
    final lead = Offset(
      (w * .3 - f.clock * h * .03) % (w + h * .6) - h * .25,
      h * .16,
    );
    final goose = Sketch.fade(const Color(0xff5f4f63), .6 * presence);
    for (var i = 0; i < 7; i++) {
      final row = (i + 1) ~/ 2;
      final side = i.isOdd ? -1.0 : 1.0;
      Sketch.bird(
        c,
        lead + Offset(row * h * .035, side * row * h * .018),
        h * .011,
        goose,
        flap: math.sin(f.clock * 3 + i * .7) * .5,
      );
    }
    // Sky lanterns rise slowly on the evening air.
    for (var i = 0; i < 6; i++) {
      final period = 26.0 + i * 3;
      final age = ((f.clock + i * 7.3) % period) / period;
      final x =
          w * (.1 + .16 * i) + math.sin(age * 6 + i) * h * .03 - age * h * .12;
      final y = h * (.62 - age * .6);
      final fade = math.min(1.0, math.min(age * 6, (1 - age) * 4));
      _skyLantern(
        c,
        Offset(x, y),
        h * (.018 - .003 * (i % 3)),
        fade * presence,
      );
    }
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  /// Rounded karst towers, paler with distance, in two misty ranks.
  static void _karsts(Canvas c, double w, double h) {
    void tower(double x, double top, double half, Color body, Color lit) {
      final base = h * .72;
      final path = Path()
        ..moveTo(x - half * h, base)
        ..cubicTo(
          x - half * h * .95,
          top * h + (base - top * h) * .4,
          x - half * h * .7,
          top * h,
          x,
          top * h,
        )
        ..cubicTo(
          x + half * h * .75,
          top * h,
          x + half * h,
          top * h + (base - top * h) * .45,
          x + half * h * 1.05,
          base,
        )
        ..close();
      c.drawPath(path, Paint()..color = body);
      c.drawPath(
        Path()
          ..moveTo(x - half * h, base)
          ..cubicTo(
            x - half * h * .95,
            top * h + (base - top * h) * .4,
            x - half * h * .7,
            top * h,
            x,
            top * h,
          )
          ..quadraticBezierTo(
            x - half * h * .45,
            top * h + (base - top * h) * .5,
            x - half * h * .3,
            base,
          )
          ..close(),
        Paint()..color = lit,
      );
    }

    final back = _hazed(const Color(0xffb9a7c4), .4);
    final backLit = _hazed(const Color(0xffd6bfd0), .35);
    final front = _hazed(const Color(0xff8f8fae), .3);
    final frontLit = _hazed(const Color(0xffb7a9c2), .25);
    for (final (fx, top, half) in const [
      (.04, .44, .09), (.16, .38, .08), (.3, .46, .1), (.47, .4, .07), //
      (.58, .47, .09), (.76, .36, .08), (.9, .44, .1), (1.05, .41, .08),
    ]) {
      tower(w * fx, top, half, back, backLit);
    }
    for (final (fx, top, half) in const [
      (-.02, .5, .08), (.1, .47, .07), (.24, .52, .09), (.38, .49, .075), //
      (.52, .55, .08), (.68, .5, .085), (.82, .53, .07), (.97, .5, .09),
    ]) {
      tower(w * fx, top, half, front, frontLit);
    }
  }

  /// The Great Wall follows the mid ridge, crenellated, with watchtowers.
  void _wall(Canvas c, double w, double h) {
    final stone = _hazed(const Color(0xffcbb8a2), .25);
    final shade = _hazed(const Color(0xff9e8c7e), .25);
    final top = Path(), crest = <Offset>[];
    for (var x = -h * .4; x <= w + h * .9; x += h * .02) {
      crest.add(Offset(x, _midRidge(x / h) * h - h * .02));
    }
    top.moveTo(crest.first.dx, crest.first.dy + h * .05);
    for (final p in crest) {
      top.lineTo(p.dx, p.dy);
    }
    top
      ..lineTo(crest.last.dx, crest.last.dy + h * .05)
      ..close();
    c.drawPath(top, Paint()..color = stone);
    // Battlements: little merlons along the outer parapet.
    final merlon = Paint()..color = shade;
    for (var i = 0; i < crest.length; i += 2) {
      final p = crest[i];
      c.drawRect(
        Rect.fromLTWH(p.dx - h * .004, p.dy - h * .008, h * .008, h * .008),
        merlon,
      );
    }
    // The walkway's lit top edge.
    final walk = Path()..moveTo(crest.first.dx, crest.first.dy + h * .004);
    for (final p in crest) {
      walk.lineTo(p.dx, p.dy + h * .004);
    }
    c.drawPath(
      walk,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .004
        ..color = _hazed(const Color(0xffeadccb), .2),
    );
    // Watchtowers on the high points.
    for (var i = 0; i < crest.length; i++) {
      if (i % 22 != 8) continue;
      final p = crest[i];
      final tw = h * .04, th = h * .055;
      c.drawRect(
        Rect.fromLTWH(p.dx - tw / 2, p.dy - th, tw, th + h * .02),
        Paint()..color = stone,
      );
      c.drawRect(
        Rect.fromLTWH(p.dx + tw * .1, p.dy - th, tw * .4, th + h * .02),
        Paint()..color = shade,
      );
      c.drawRect(
        Rect.fromLTWH(p.dx - tw * .3, p.dy - th * .6, tw * .18, th * .25),
        Paint()..color = _hazed(const Color(0xff6f5f5a), .2),
      );
      for (var k = 0; k < 3; k++) {
        c.drawRect(
          Rect.fromLTWH(
            p.dx - tw / 2 + k * tw * .4,
            p.dy - th - h * .007,
            tw * .2,
            h * .007,
          ),
          merlon,
        );
      }
    }
  }

  /// A slender brick pagoda with upturned eaves on every storey.
  static void _pagoda(Canvas c, Offset base, double s) {
    final wall = _hazed(const Color(0xffa45a4a), .3);
    final roof = _hazed(const Color(0xff4f6d6a), .3);
    final lit = _hazed(const Color(0xff7f9a90), .3);
    const tiers = 7;
    var y = base.dy;
    for (var i = 0; i < tiers; i++) {
      final k = 1 - i * .09;
      final storey = s * .12 * k;
      final half = s * .11 * k;
      c.drawRect(
        Rect.fromLTRB(base.dx - half, y - storey, base.dx + half, y),
        Paint()..color = wall,
      );
      final eave = half * 1.9;
      final ey = y - storey;
      c.drawPath(
        Path()
          ..moveTo(base.dx - eave, ey - storey * .35)
          ..quadraticBezierTo(
            base.dx - half,
            ey + storey * .1,
            base.dx - half * .6,
            ey - storey * .15,
          )
          ..lineTo(base.dx + half * .6, ey - storey * .15)
          ..quadraticBezierTo(
            base.dx + half,
            ey + storey * .1,
            base.dx + eave,
            ey - storey * .35,
          )
          ..lineTo(base.dx + half * .5, ey - storey * .45)
          ..lineTo(base.dx - half * .5, ey - storey * .45)
          ..close(),
        Paint()..color = roof,
      );
      c.drawLine(
        Offset(base.dx - half * .6, ey - storey * .38),
        Offset(base.dx + half * .6, ey - storey * .38),
        Paint()
          ..color = lit
          ..strokeWidth = s * .006,
      );
      y = ey - storey * .45;
    }
    c.drawLine(
      Offset(base.dx, y),
      Offset(base.dx, y - s * .14),
      Paint()
        ..color = roof
        ..strokeWidth = s * .014,
    );
  }

  /// A windswept pine with flat, layered needle clouds.
  static void _pine(Canvas c, Offset base, double s) {
    const bark = Color(0xff4f3f3a),
        needles = Color(0xff35544c),
        lit = Color(0xff4f7266);
    final trunk = Path()
      ..moveTo(base.dx - s * .04, base.dy)
      ..cubicTo(
        base.dx - s * .1,
        base.dy - s * .35,
        base.dx + s * .16,
        base.dy - s * .55,
        base.dx + s * .02,
        base.dy - s * .95,
      )
      ..lineTo(base.dx + s * .05, base.dy - s * .95)
      ..cubicTo(
        base.dx + s * .2,
        base.dy - s * .55,
        base.dx - s * .04,
        base.dy - s * .35,
        base.dx + s * .04,
        base.dy,
      )
      ..close();
    c.drawPath(trunk, Paint()..color = bark);
    final branch = Paint()
      ..color = bark
      ..strokeWidth = s * .025
      ..strokeCap = StrokeCap.round;
    for (final (y, reach, side) in const [
      (.45, .42, -1.0),
      (.62, .36, 1.0),
      (.8, .3, -1.0),
      (.92, .2, 1.0),
    ]) {
      final from = base + Offset(s * .05, -s * y);
      final to = from + Offset(side * s * reach, -s * .04);
      c.drawLine(from, to, branch);
      for (final (dx, dw, paint) in [(0.0, 1.0, needles), (-.03, .7, lit)]) {
        c.drawOval(
          Rect.fromCenter(
            center: to + Offset(-side * s * reach * .25, -s * (.05 - dx)),
            width: s * reach * 1.1 * dw,
            height: s * .1 * dw,
          ),
          Paint()..color = paint,
        );
      }
    }
  }

  static void _pavilion(Canvas c, Offset base, double s) {
    const column = Color(0xffb8483a),
        roof = Color(0xff3f5a58),
        lit = Color(0xff6f8f86),
        gold = Color(0xffe0b24f);
    c.drawRect(
      Rect.fromLTRB(
        base.dx - s * .9,
        base.dy - s * .12,
        base.dx + s * .9,
        base.dy + s * .2,
      ),
      Paint()..color = const Color(0xff9a9290),
    );
    for (final dx in const [-.7, -.25, .25, .7]) {
      c.drawRect(
        Rect.fromLTRB(
          base.dx + dx * s - s * .04,
          base.dy - s * .75,
          base.dx + dx * s + s * .04,
          base.dy - s * .1,
        ),
        Paint()..color = column,
      );
    }
    c.drawRect(
      Rect.fromLTRB(
        base.dx - s * .8,
        base.dy - s * .82,
        base.dx + s * .8,
        base.dy - s * .72,
      ),
      Paint()..color = gold,
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx - s * 1.25, base.dy - s * .95)
        ..quadraticBezierTo(
          base.dx - s * .9,
          base.dy - s * .78,
          base.dx - s * .75,
          base.dy - s * .9,
        )
        ..quadraticBezierTo(
          base.dx - s * .3,
          base.dy - s * 1.25,
          base.dx,
          base.dy - s * 1.4,
        )
        ..quadraticBezierTo(
          base.dx + s * .3,
          base.dy - s * 1.25,
          base.dx + s * .75,
          base.dy - s * .9,
        )
        ..quadraticBezierTo(
          base.dx + s * .9,
          base.dy - s * .78,
          base.dx + s * 1.25,
          base.dy - s * .95,
        )
        ..lineTo(base.dx + s * .8, base.dy - s * .74)
        ..lineTo(base.dx - s * .8, base.dy - s * .74)
        ..close(),
      Paint()..color = roof,
    );
    c.drawLine(
      Offset(base.dx - s * .6, base.dy - s * .98),
      Offset(base.dx + s * .6, base.dy - s * .98),
      Paint()
        ..color = lit
        ..strokeWidth = s * .04,
    );
    c.drawCircle(base + Offset(0, -s * 1.44), s * .06, Paint()..color = gold);
  }

  static void _plum(Canvas c, Offset base, double s) {
    final bark = Paint()
      ..color = const Color(0xff4a3a3a)
      ..strokeWidth = s * .05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tips = <Offset>[];
    void branch(Offset from, double a, double len, int depth) {
      final to = from + Offset(math.cos(a) * len, math.sin(a) * len);
      bark.strokeWidth = s * .012 * (depth + 1.5);
      c.drawLine(from, to, bark);
      if (depth == 0) {
        tips.add(to);
        return;
      }
      branch(to, a - .45, len * .7, depth - 1);
      branch(to, a + .38, len * .66, depth - 1);
    }

    branch(base, -1.4, s * .42, 3);
    final blossom = Paint()..color = const Color(0xfff7b8c6);
    final light = Paint()..color = const Color(0xfffff0f2);
    for (var i = 0; i < tips.length; i++) {
      final p = tips[i];
      c.drawCircle(p, s * .035, i.isEven ? blossom : light);
      c.drawCircle(p + Offset(-s * .05, s * .04), s * .028, blossom);
    }
  }

  /// A water-worn scholar's rock at the shore.
  static void _rock(Canvas c, Offset base, double s) {
    c.drawPath(
      Path()
        ..moveTo(base.dx - s, base.dy)
        ..quadraticBezierTo(
          base.dx - s * 1.1,
          base.dy - s * .9,
          base.dx - s * .3,
          base.dy - s * 1.2,
        )
        ..quadraticBezierTo(
          base.dx + s * .5,
          base.dy - s * 1.5,
          base.dx + s * .9,
          base.dy - s * .6,
        )
        ..quadraticBezierTo(
          base.dx + s * 1.1,
          base.dy - s * .2,
          base.dx + s,
          base.dy,
        )
        ..close(),
      Paint()..color = const Color(0xff6f7f7a),
    );
    c.drawOval(
      Rect.fromCenter(
        center: base + Offset(-s * .3, -s * .8),
        width: s * .5,
        height: s * .3,
      ),
      Paint()..color = const Color(0xff9aa8a0),
    );
    c.drawCircle(
      base + Offset(s * .3, -s * .6),
      s * .14,
      Paint()..color = const Color(0xff4f5d5a),
    );
  }

  static void _raft(Canvas c, Offset at, double s) {
    c.drawRect(
      Rect.fromLTRB(at.dx - s, at.dy - s * .08, at.dx + s, at.dy + s * .06),
      Paint()..color = const Color(0xffb59a64),
    );
    final pole = Paint()
      ..color = const Color(0xff5a4636)
      ..strokeWidth = s * .05;
    c.drawLine(
      at + Offset(s * .2, -s * .1),
      at + Offset(s * 1.1, s * .5),
      pole,
    );
    // The raftsman in a conical hat, and a small lantern at the bow.
    c.drawRect(
      Rect.fromLTRB(
        at.dx - s * .08,
        at.dy - s * .6,
        at.dx + s * .12,
        at.dy - s * .08,
      ),
      Paint()..color = const Color(0xff4f5b6b),
    );
    c.drawPath(
      Sketch.poly([-.3, -.58, .02, -.8, .34, -.58], at: at, s: s),
      Paint()..color = const Color(0xffd8c08a),
    );
    c.drawCircle(
      at + Offset(-s * .85, -s * .25),
      s * .1,
      Paint()..color = const Color(0xffffb35a),
    );
    final ripple = Paint()
      ..color = const Color(0x66ffffff)
      ..strokeWidth = s * .04
      ..strokeCap = StrokeCap.round;
    c.drawLine(
      at + Offset(-s * 1.2, s * .18),
      at + Offset(s * .9, s * .18),
      ripple,
    );
  }

  static void _skyLantern(Canvas c, Offset p, double s, double alpha) {
    if (alpha <= 0) return;
    c.drawCircle(
      p,
      s * 2.2,
      Paint()..color = Sketch.fade(const Color(0xffffc27a), .18 * alpha),
    );
    c.drawPath(
      Sketch.poly([-.55, -.9, .55, -.9, .45, .7, -.45, .7], at: p, s: s),
      Paint()..color = Sketch.fade(const Color(0xfffff0c8), alpha),
    );
    c.drawPath(
      Sketch.poly([-.3, -.5, .3, -.5, .25, .55, -.25, .55], at: p, s: s),
      Paint()..color = Sketch.fade(const Color(0xffffb24a), alpha),
    );
  }
}
