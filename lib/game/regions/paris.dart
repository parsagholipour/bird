import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Paris on a clear night: Haussmann rooftops and the domes of Sacré-Cœur
/// on the horizon, the Eiffel Tower glittering over the roofs beside the Arc
/// de Triomphe, the Seine under a stone bridge with a river boat gliding by,
/// and gas lamps and plane trees along the quay. Stars twinkle over a moon.
class ParisScene extends RegionScene {
  const ParisScene();

  @override
  WorldRegion get region => WorldRegion.paris;

  @override
  double get horizon => .66;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.8, .2),
    radius: .048,
    disc: Color(0xfff6f0d8),
    glow: Color(0xffc8d0f0),
    halo: .4,
    strength: .3,
    moon: 1,
  );

  static final _weather = Weather(Weather.of([(Mote.firefly, 8)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xff8a7ca8);
  static const _gold = Color(0xffffcf6a);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xff4a4a78),
      Color(0xff3d3f68),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xff33375c),
      Color(0xff2a2d4d),
      Color(0xff5a5f8a),
      rimWidth: .003,
    ),
    Depth.low => const Ground(
      Color(0xff2a3768),
      Color(0xff17224a),
      Color(0xff6d7ab0),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xff3f4062),
      Color(0xff2a2b45),
      Color(0xff7c7da0),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .69,
    Depth.mid => .74,
    Depth.low => .82 + .004 * math.sin(x * math.pi * 4 + clock * 1.3),
    Depth.near => .935 - .006 * Sketch.humps(x / 1.5),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    Depth.mid => .34,
    Depth.low => .16,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        _row(c, -h * .1, w + h * .1, h * .72, h, .55, 1, .06);
        Scenery.dome(
          c,
          Offset(w * .18, h * .68),
          h * .028,
          h * .09,
          _hazed(const Color(0xffcfc8dc), .45),
          _hazed(const Color(0xffefe8f4), .4),
        );
        for (final dx in const [-.045, .045]) {
          Scenery.dome(
            c,
            Offset(w * .18 + dx * h, h * .68),
            h * .014,
            h * .04,
            _hazed(const Color(0xffcfc8dc), .45),
            _hazed(const Color(0xffefe8f4), .4),
          );
        }
      case Depth.mid:
        _row(c, -h * .1, w + h * .1, h * .755, h, .25, 2, .09);
        _eiffel(c, Offset(w * .62, h * .76), h * .52);
        _arc(c, Offset(w * .2, h * .76), h * .15);
      case Depth.low:
        final base = ridge(d, .5, 0) * h;
        _bridge(c, span * .5, base, h);
      case Depth.near:
        for (final fx in const [.12, .42, .72]) {
          final x = span * fx;
          _lamp(c, Offset(x, ridge(d, x / h, 0) * h + h * .01), h * .13);
        }
        for (final fx in const [.27, .57, .88]) {
          final x = span * fx;
          Scenery.tree(
            c,
            Offset(x, ridge(d, x / h, 0) * h + h * .01),
            h * .2,
            const Color(0xff221f33),
            const Color(0xff2f3a4f),
            const Color(0xff3f5062),
          );
        }
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.low) return;
    final h = f.h, span = period(d) * h;
    final x = (h * .3 + f.clock * h * .012) % span;
    final y = ridge(d, x / h, f.clock) * h + h * .006;
    final s = h * .05;
    c.drawPath(
      Sketch.poly([
        x - s,
        y - s * .3,
        x + s * 1.1,
        y - s * .3,
        x + s * .8,
        y + s * .12,
        x - s * .8,
        y + s * .12,
      ]),
      Paint()..color = const Color(0xff1c1a30),
    );
    c.drawRect(
      Rect.fromLTRB(x - s * .6, y - s * .62, x + s * .6, y - s * .3),
      Paint()..color = const Color(0xff2b2945),
    );
    Scenery.windows(
      c,
      Rect.fromLTRB(x - s * .55, y - s * .6, x + s * .55, y - s * .32),
      cols: 5,
      rows: 1,
      lit: _gold,
      dark: const Color(0xff3a3858),
      litChance: 1,
    );
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.mid:
        // The tower's hourly glitter: flashes that run over its lattice.
        final s = h * .52;
        final base = Offset(f.w * .62, h * .76);
        for (var i = 0; i < 16; i++) {
          final flash = math.pow(
            math.max(0.0, math.sin(f.clock * 6 + i * 2.7)),
            6,
          ).toDouble();
          if (flash < .05) continue;
          final t = .04 + .8 * Sketch.hash(i + 90);
          final x = base.dx + (Sketch.hash(i + 91) * 2 - 1) * _eiffelHalf(s, t) * .8;
          final y = base.dy - s * t;
          Sketch.mist(
            c,
            Rect.fromCenter(center: Offset(x, y), width: h * .03, height: h * .03),
            const Color(0xfffff6d0),
            .9 * flash * presence,
          );
        }
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(base.dx, base.dy - s * .3), width: s * .7, height: s * .6),
          _gold,
          .12 * presence,
        );
      case Depth.near:
        final span = period(d) * h;
        for (final fx in const [.12, .42, .72]) {
          final x = span * fx;
          final y = ridge(d, x / h, 0) * h + h * .01 - h * .13;
          Sketch.mist(
            c,
            Rect.fromCenter(center: Offset(x, y), width: h * .14, height: h * .14),
            _gold,
            .55 * presence,
          );
        }
      case Depth.far || Depth.low:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .004;
    for (var i = 0; i < 14; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.6 + i * 1.7);
      glint.color = Sketch.fade(
        i % 3 == 0 ? const Color(0xfff2ecd0) : _gold,
        .55 * on * presence,
      );
      final y = h * (.83 + (i % 5) * .012);
      final x = f.w * ((i + .5) / 14) + math.sin(i * 2.3) * h * .02;
      final len = h * (.02 + .03 * Sketch.hash(i + 70)) * (.6 + .4 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    for (var i = 0; i < 46; i++) {
      final twinkle = .55 + .45 * math.sin(f.clock * (.8 + Sketch.hash(i) * 1.6) + i);
      c.drawCircle(
        Offset(w * Sketch.hash(i + 200), h * .5 * Sketch.hash(i + 201)),
        h * (.0012 + .0018 * Sketch.hash(i + 202)),
        Paint()..color = Sketch.fade(const Color(0xfffff6e0), .85 * twinkle * presence),
      );
    }
    for (final (fx, fy, fw) in const [(.25, .3, .5), (.7, .4, .4)]) {
      final x = (w * fx - f.clock * h * .004) % (w + h) - h * .5;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .04),
        const Color(0xff7d76a8),
        .55 * presence,
      );
    }
  }

  /// A block of Haussmann roofs: cream walls under slate mansards with lit
  /// windows and chimneys. [haze] pushes them into the distance.
  static void _row(
    Canvas c,
    double x0,
    double x1,
    double baseY,
    double h,
    double haze,
    int seed,
    double tall,
  ) {
    var x = x0;
    var i = 0;
    while (x < x1) {
      final bw = h * (.06 + .04 * Sketch.hash(seed * 50 + i));
      final bh = h * (tall + .035 * Sketch.hash(seed * 50 + i + 300));
      final wall = _hazed(const Color(0xff4b4a72), haze);
      final roof = _hazed(const Color(0xff2b2c4b), haze);
      c.drawRect(Rect.fromLTRB(x, baseY - bh, x + bw, baseY), Paint()..color = wall);
      c.drawPath(
        Sketch.poly([x - bw * .03, baseY - bh, x + bw * 1.03, baseY - bh, x + bw * .9, baseY - bh - h * .022, x + bw * .1, baseY - bh - h * .022]),
        Paint()..color = roof,
      );
      c.drawRect(
        Rect.fromLTWH(x + bw * .7, baseY - bh - h * .038, bw * .08, h * .02),
        Paint()..color = roof,
      );
      Scenery.windows(
        c,
        Rect.fromLTRB(x + bw * .08, baseY - bh + h * .006, x + bw * .92, baseY - h * .004),
        cols: 3,
        rows: math.max(1, (bh / (h * .022)).floor()),
        lit: _hazed(_gold, haze * .6),
        dark: _hazed(const Color(0xff2a2b4a), haze),
        seed: seed * 50 + i,
        litChance: .45,
      );
      x += bw + h * .004;
      i++;
    }
  }

  static double _eiffelHalf(double s, double t) =>
      s * .17 * math.pow(1 - t, 2.4).toDouble() + s * .012;

  /// The Eiffel Tower: four splayed legs that merge above an arch, two
  /// platforms and a tapering spire, with a lattice of cross braces.
  static void _eiffel(Canvas c, Offset base, double s) {
    final iron = _hazed(const Color(0xff3a3050), .12);
    final brace = _hazed(const Color(0xff54486e), .1);
    const arch = .16;
    double y(double t) => base.dy - s * t;
    final paint = Paint()..color = iron;
    for (final side in const [-1.0, 1.0]) {
      final leg = Path()..moveTo(base.dx + side * _eiffelHalf(s, 0), y(0));
      for (var i = 1; i <= 8; i++) {
        final t = arch * i / 8;
        leg.lineTo(base.dx + side * _eiffelHalf(s, t), y(t));
      }
      for (var i = 8; i >= 0; i--) {
        final t = arch * i / 8;
        final inner = _eiffelHalf(s, t) - s * (.034 - .012 * t / arch);
        leg.lineTo(base.dx + side * inner, y(t));
      }
      c.drawPath(leg..close(), paint);
    }
    final body = Path()..moveTo(base.dx - _eiffelHalf(s, arch), y(arch));
    for (var i = 1; i <= 24; i++) {
      final t = arch + (1 - arch) * i / 24;
      body.lineTo(base.dx - _eiffelHalf(s, t), y(t));
    }
    for (var i = 24; i >= 0; i--) {
      final t = arch + (1 - arch) * i / 24;
      body.lineTo(base.dx + _eiffelHalf(s, t), y(t));
    }
    c.drawPath(body..close(), paint);
    // The arch between the legs is a shallow curve.
    c.drawPath(
      Path()
        ..moveTo(base.dx - _eiffelHalf(s, .1), y(.1))
        ..quadraticBezierTo(base.dx, y(.2), base.dx + _eiffelHalf(s, .1), y(.1))
        ..lineTo(base.dx + _eiffelHalf(s, .1), y(.115))
        ..quadraticBezierTo(base.dx, y(.215), base.dx - _eiffelHalf(s, .1), y(.115))
        ..close(),
      paint,
    );
    final lines = Paint()
      ..color = brace
      ..strokeWidth = math.max(.6, s * .004);
    for (var k = 0; k < 8; k++) {
      final t0 = .17 + k * .045, t1 = t0 + .045;
      if (t1 > .5) break;
      final a = _eiffelHalf(s, t0) * .88, b = _eiffelHalf(s, t1) * .88;
      c.drawLine(Offset(base.dx - a, y(t0)), Offset(base.dx + b, y(t1)), lines);
      c.drawLine(Offset(base.dx + a, y(t0)), Offset(base.dx - b, y(t1)), lines);
    }
    for (final (t, extra) in const [(.16, .02), (.46, .016), (.78, .01)]) {
      c.drawRect(
        Rect.fromLTRB(
          base.dx - _eiffelHalf(s, t) - s * extra,
          y(t) - s * .012,
          base.dx + _eiffelHalf(s, t) + s * extra,
          y(t) + s * .004,
        ),
        paint,
      );
    }
    c.drawLine(
      Offset(base.dx, y(1)),
      Offset(base.dx, y(1.06)),
      Paint()
        ..color = iron
        ..strokeWidth = math.max(.8, s * .006),
    );
  }

  /// The Arc de Triomphe: a broad block with a tall arch, a frieze and a
  /// stepped attic.
  static void _arc(Canvas c, Offset base, double s) {
    final stone = _hazed(const Color(0xff6a6688), .2);
    final shade = _hazed(const Color(0xff4c4a6c), .2);
    final dark = const Color(0xff1e2140);
    final w = s * 1.1, hgt = s * .9;
    c.drawRect(Rect.fromLTRB(base.dx - w / 2, base.dy - hgt, base.dx + w / 2, base.dy), Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(base.dx, base.dy - hgt, base.dx + w / 2, base.dy), Paint()..color = shade);
    c.drawRect(Rect.fromLTRB(base.dx - w * .55, base.dy - hgt, base.dx + w * .55, base.dy - hgt + s * .06), Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(base.dx - w / 2, base.dy - hgt * .78, base.dx + w / 2, base.dy - hgt * .7), Paint()..color = shade);
    final aw = w * .3;
    c.drawPath(
      Path()
        ..moveTo(base.dx - aw, base.dy)
        ..lineTo(base.dx - aw, base.dy - hgt * .5)
        ..arcToPoint(Offset(base.dx + aw, base.dy - hgt * .5), radius: Radius.circular(aw), clockwise: true)
        ..lineTo(base.dx + aw, base.dy)
        ..close(),
      Paint()..color = dark,
    );
  }

  /// A stone bridge: a deck on round arches with a balustrade and lamps.
  static void _bridge(Canvas c, double cx, double waterY, double h) {
    final half = h * .55;
    final stone = const Color(0xff4a4b70), shade = const Color(0xff363758);
    final deck = Rect.fromLTRB(cx - half, waterY - h * .05, cx + half, waterY + h * .01);
    c.drawRect(deck, Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(deck.left, deck.bottom - h * .012, deck.right, deck.bottom), Paint()..color = shade);
    Scenery.arches(c, Rect.fromLTRB(deck.left, deck.top + h * .012, deck.right, deck.bottom), 6, const Color(0xff1c2447));
    c.drawRect(Rect.fromLTRB(deck.left, deck.top - h * .008, deck.right, deck.top), Paint()..color = stone);
    for (var i = 0; i <= 4; i++) {
      final x = deck.left + deck.width * i / 4;
      c.drawRect(Rect.fromLTWH(x - h * .0015, deck.top - h * .03, h * .003, h * .022), Paint()..color = shade);
      c.drawCircle(Offset(x, deck.top - h * .034), h * .006, Paint()..color = _gold);
    }
  }

  /// A cast-iron gas lamp on the quay.
  static void _lamp(Canvas c, Offset base, double s) {
    final iron = Paint()..color = const Color(0xff14131f);
    c.drawRect(Rect.fromLTRB(base.dx - s * .02, base.dy - s, base.dx + s * .02, base.dy), iron);
    c.drawRect(Rect.fromLTRB(base.dx - s * .05, base.dy - s * .12, base.dx + s * .05, base.dy), iron);
    c.drawRect(Rect.fromLTRB(base.dx - s * .07, base.dy - s * 1.14, base.dx + s * .07, base.dy - s * .98), Paint()..color = _gold);
    c.drawPath(
      Sketch.poly([base.dx - s * .09, base.dy - s * 1.14, base.dx + s * .09, base.dy - s * 1.14, base.dx, base.dy - s * 1.24]),
      iron,
    );
  }
}
