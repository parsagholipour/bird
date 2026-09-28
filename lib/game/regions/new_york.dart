import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// New York on a rainy night: an Art Deco skyline with the Empire State and
/// Chrysler buildings under a full moon, the Brooklyn Bridge's gothic towers
/// and cables over the East River, and brick rooftops with wooden water
/// towers, fire escapes, lit windows and steam. Searchlights sweep the sky.
class NewYorkScene extends RegionScene {
  const NewYorkScene();

  @override
  WorldRegion get region => WorldRegion.newYork;

  @override
  double get horizon => .66;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.83, .15),
    radius: .042,
    disc: Color(0xfff6f1e2),
    glow: Color(0xffd3d8ff),
    halo: .3,
    strength: .3,
    moon: 1,
  );

  static final _weather = Weather(Weather.of([(Mote.rain, 22)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xff6c5f92);
  static const _window = Color(0xffffd98a);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xff4a4a7c),
      Color(0xff3f406e),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xff3a3a64),
      Color(0xff30305a),
      Color(0xff5c5a86),
      rimWidth: .002,
    ),
    Depth.low => const Ground(
      Color(0xff2e3460),
      Color(0xff1c2243),
      Color(0xff7c79a8),
      rimWidth: .002,
    ),
    Depth.near => const Ground(
      Color(0xff2b2744),
      Color(0xff1e1b32),
      Color(0xff4d4870),
      rimWidth: .003,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .705,
    Depth.mid => .76,
    Depth.low => .79,
    Depth.near => .94,
  };

  @override
  double period(Depth d) => d == Depth.low ? 2.4 : 3.2;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .45,
    Depth.mid => .34,
    Depth.low => .1,
    Depth.near => .26,
  };

  /// Near rooftops across one repeat: (width, roof height) in viewport
  /// heights, with a water tower, fire escape and chimney on some.
  static const _roofs = [
    (.34, .8, 1),
    (.28, .76, 0),
    (.4, .83, 2),
    (.22, .74, 3),
    (.36, .79, 1),
    (.3, .85, 0),
    (.26, .77, 2),
    (.38, .82, 3),
    (.3, .75, 0),
    (.36, .8, 2),
  ];

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _skyline(c, w, h);
      case Depth.mid:
        _bridge(c, w * .24, h);
      case Depth.low:
        break;
      case Depth.near:
        var x = 0.0;
        for (var i = 0; i < _roofs.length; i++) {
          final (width, roof, kind) = _roofs[i];
          _tenement(
            c,
            Rect.fromLTRB(x * h, roof * h, (x + width) * h, h * .96),
            kind,
            i,
          );
          x += width;
        }
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.near) return;
    final h = f.h;
    // Now and then someone switches a light on or off.
    final lamp = Paint()..color = const Color(0xfff2c46a);
    final dark = Paint()..color = const Color(0xff2a2a47);
    var left = 0.0;
    for (var i = 0; i < _roofs.length; i++) {
      final (width, roof, _) = _roofs[i];
      final on = ((f.clock / 4.3 + i * .37 + copy * .5).floor() + i).isEven;
      // The same grid as the static windows in [_tenement].
      final cols = math.max(2, (width / .06).floor());
      final colW = width * h / cols;
      final win = Rect.fromLTWH(
        left * h + colW * (cols ~/ 2 + .3),
        (roof + .035 + .045 * (i % 3)) * h,
        colW * .4,
        h * .026,
      );
      c.drawRect(win, on ? lamp : dark);
      left += width;
    }
    // Rooftop vents breathe steam that rises, swells and fades.
    var x = 0.0;
    for (var i = 0; i < _roofs.length; i++) {
      final (width, roof, kind) = _roofs[i];
      if (kind == 3 || i == 5) {
        final vent = Offset((x + width * .7) * h, roof * h - h * .02);
        for (var k = 0; k < 4; k++) {
          final age = ((f.clock * .35 + k / 4 + i * .13) % 1);
          final p = vent + Offset(-age * h * .05, -age * h * .12);
          final r = h * (.016 + age * .035);
          Sketch.mist(
            c,
            Rect.fromCenter(center: p, width: r * 2.4, height: r * 2),
            const Color(0xffdcd8ee),
            .55 * (1 - age) * math.min(1.0, age * 5),
          );
        }
      }
      x += width;
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    if (d != Depth.low) return;
    final h = f.h;
    // Wavering reflections of the city lights on the river.
    final streak = Paint()
      ..strokeWidth = h * .004
      ..strokeCap = StrokeCap.round;
    final span = period(d) * h;
    for (var i = 0; i < 14; i++) {
      final x = span * Sketch.hash(i + 500);
      final warm = i % 3 != 0;
      for (var k = 0; k < 3; k++) {
        final on = .5 + .5 * math.sin(f.clock * 2 + i * 1.3 + k * 2.1);
        streak.color = Sketch.fade(
          warm ? _window : const Color(0xfff39ac0),
          .45 * on * presence,
        );
        final y = h * (.8 + k * .018 + .01 * Sketch.hash(i + 520));
        final len = h * (.012 + .008 * on);
        c.drawLine(Offset(x - len, y), Offset(x + len, y), streak);
      }
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .004;
    for (var i = 0; i < 7; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.7 + i * 2.2);
      glint.color = Sketch.fade(const Color(0xfff6f1e2), .55 * on * presence);
      final y = h * (.8 + i * .012);
      final x = f.w * light.at.dx + math.sin(i * 1.7 + f.clock) * h * .008;
      final len = h * (.03 - i * .002);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final star = Paint();
    for (var i = 0; i < 18; i++) {
      final twinkle = .55 + .45 * math.sin(f.clock * 2 + i * 1.9);
      star.color = Sketch.fade(
        const Color(0xfffff4e0),
        .7 * twinkle * presence,
      );
      c.drawCircle(
        Offset(w * Sketch.hash(i + 600), h * .4 * Sketch.hash(i + 700)),
        h * (.0016 + .002 * Sketch.hash(i + 800)),
        star,
      );
    }
    // Two premiere searchlights sweep slowly behind the skyline.
    for (final (fx, speed, phase) in const [(.3, .23, 0.0), (.66, .19, 2.2)]) {
      final base = Offset(w * fx, h * .72);
      final a = -math.pi / 2 + math.sin(f.clock * speed + phase) * .42;
      final reach = h * 1.1;
      final tip = base + Offset(math.cos(a), math.sin(a)) * reach;
      final side = Offset(-math.sin(a), math.cos(a)) * h * .06;
      c.drawPath(
        Path()
          ..moveTo(base.dx - h * .004, base.dy)
          ..lineTo(tip.dx - side.dx, tip.dy - side.dy)
          ..lineTo(tip.dx + side.dx, tip.dy + side.dy)
          ..lineTo(base.dx + h * .004, base.dy)
          ..close(),
        Paint()
          ..shader = Gradient.linear(base, tip, [
            Sketch.fade(const Color(0xfffff3d6), .2 * presence),
            Sketch.fade(const Color(0xfffff3d6), 0),
          ]),
      );
    }
    // An airliner's blinking light crossing high above.
    final plane = Offset(
      (w * .1 + f.clock * h * .02) % (w + h * .4) - h * .2,
      h * .09,
    );
    final blink = math.sin(f.clock * 5) > .3;
    c.drawCircle(
      plane,
      h * .003,
      Paint()..color = Sketch.fade(const Color(0xffe8e6ff), .7 * presence),
    );
    if (blink) {
      c.drawCircle(
        plane + Offset(h * .006, 0),
        h * .004,
        Paint()..color = Sketch.fade(const Color(0xffff6f6f), presence),
      );
    }
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  static void _skyline(Canvas c, double w, double h) {
    final body = _hazed(const Color(0xff454879), .15);
    final back = _hazed(const Color(0xff525488), .3);
    final lit = _hazed(const Color(0xff6a6aa0), .15);
    final windows = Path();
    final dim = Path();
    void tower(
      double x,
      double top,
      double width,
      Color color, {
      int seed = 0,
    }) {
      final r = Rect.fromLTRB(
        x - width / 2 * h,
        top * h,
        x + width / 2 * h,
        h * .74,
      );
      c.drawRect(r, Paint()..color = color);
      c.drawRect(
        Rect.fromLTRB(r.right - r.width * .22, r.top, r.right, r.bottom),
        Paint()..color = Sketch.mix(color, lit, .5),
      );
      final cell = h * .011;
      for (var y = r.top + cell; y < h * .71; y += cell * 1.6) {
        for (
          var wx = r.left + cell * .6;
          wx < r.right - cell * .6;
          wx += cell * 1.3
        ) {
          final n = Sketch.hash((wx * 13 + y * 7).round() + seed);
          if (n < .22) {
            windows.addRect(Rect.fromLTWH(wx, y, cell * .55, cell * .7));
          } else if (n < .34) {
            dim.addRect(Rect.fromLTWH(wx, y, cell * .55, cell * .7));
          }
        }
      }
    }

    // Distant, paler towers first, then the nearer skyline.
    for (var i = 0; i < 14; i++) {
      final x = (w + h * .6) * i / 14 - h * .1;
      tower(
        x,
        .5 + .08 * Sketch.hash(i + 40),
        .07 + .04 * Sketch.hash(i + 41),
        back,
        seed: i,
      );
    }
    for (var i = 0; i < 12; i++) {
      final x = (w + h * .8) * (i + .5) / 12 - h * .2;
      // Leave room for the two landmark towers.
      if ((x - w * .36).abs() < h * .09 || (x - w * .62).abs() < h * .07) {
        continue;
      }
      tower(
        x,
        .55 + .09 * Sketch.hash(i + 60),
        .06 + .05 * Sketch.hash(i + 61),
        body,
        seed: 100 + i,
      );
    }
    _empireState(c, Offset(w * .36, h * .74), h, body, lit, windows);
    _chrysler(c, Offset(w * .62, h * .74), h, body, lit, windows);
    c.drawPath(dim, Paint()..color = Sketch.fade(_window, .28));
    c.drawPath(windows, Paint()..color = Sketch.fade(_window, .78));
  }

  /// Stepped setbacks rising to the mooring mast and antenna.
  static void _empireState(
    Canvas c,
    Offset base,
    double h,
    Color body,
    Color lit,
    Path windows,
  ) {
    final steps = [
      (.1, .52),
      (.08, .47),
      (.064, .38),
      (.05, .36),
      (.034, .34),
      (.02, .3),
    ];
    for (final (width, top) in steps) {
      final r = Rect.fromLTRB(
        base.dx - width / 2 * h,
        top * h,
        base.dx + width / 2 * h,
        base.dy,
      );
      c.drawRect(r, Paint()..color = body);
      c.drawRect(
        Rect.fromLTRB(base.dx + width * .18 * h, r.top, r.right, r.bottom),
        Paint()..color = lit,
      );
    }
    c.drawLine(
      Offset(base.dx, h * .3),
      Offset(base.dx, h * .22),
      Paint()
        ..color = lit
        ..strokeWidth = h * .004,
    );
    // Floodlit crown.
    c.drawRect(
      Rect.fromLTRB(base.dx - h * .017, h * .33, base.dx + h * .017, h * .36),
      Paint()..color = Sketch.fade(const Color(0xffffe7a8), .75),
    );
    final cell = h * .01;
    for (var y = h * .4; y < h * .7; y += cell * 1.5) {
      for (
        var x = base.dx - h * .028;
        x < base.dx + h * .028;
        x += cell * 1.2
      ) {
        if (Sketch.hash((x * 3 + y * 5).round()) < .3) {
          windows.addRect(Rect.fromLTWH(x, y, cell * .5, cell * .7));
        }
      }
    }
  }

  /// The terraced sunburst crown with triangular windows and a needle spire.
  static void _chrysler(
    Canvas c,
    Offset base,
    double h,
    Color body,
    Color lit,
    Path windows,
  ) {
    final half = h * .03;
    c.drawRect(
      Rect.fromLTRB(base.dx - half, h * .44, base.dx + half, base.dy),
      Paint()..color = body,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx + half * .4, h * .44, base.dx + half, base.dy),
      Paint()..color = lit,
    );
    final steel = Sketch.mix(lit, const Color(0xffc9cde6), .5);
    final glow = Sketch.fade(const Color(0xffffe7b0), .85);
    for (var k = 0; k < 5; k++) {
      final r = half * (1 - k * .17);
      final y = h * (.44 - k * .022);
      final arch = Rect.fromCenter(
        center: Offset(base.dx, y),
        width: r * 2,
        height: r * 1.6,
      );
      c.drawArc(arch, math.pi, math.pi, true, Paint()..color = steel);
      c.drawRect(
        Rect.fromLTRB(base.dx - r, y - h * .001, base.dx + r, y + h * .004),
        Paint()..color = steel,
      );
      // Triangular windows ring each arch.
      for (var j = 0; j < 5; j++) {
        final a = math.pi + math.pi * (j + .5) / 5;
        final p = Offset(
          base.dx + math.cos(a) * r * .72,
          y + math.sin(a) * r * .56,
        );
        c.drawPath(
          Sketch.poly([
            p.dx,
            p.dy - h * .005,
            p.dx + h * .003,
            p.dy + h * .003,
            p.dx - h * .003,
            p.dy + h * .003,
          ]),
          Paint()..color = glow,
        );
      }
    }
    c.drawPath(
      Sketch.poly([
        base.dx - h * .005,
        h * .352,
        base.dx,
        h * .3,
        base.dx + h * .005,
        h * .352,
      ]),
      Paint()..color = steel,
    );
    final cell = h * .01;
    for (var y = h * .47; y < h * .7; y += cell * 1.5) {
      for (
        var x = base.dx - half + cell * .5;
        x < base.dx + half - cell * .5;
        x += cell * 1.2
      ) {
        if (Sketch.hash((x * 7 + y * 3).round()) < .3) {
          windows.addRect(Rect.fromLTWH(x, y, cell * .5, cell * .7));
        }
      }
    }
  }

  /// The Brooklyn Bridge: granite towers with twin gothic arches, main
  /// cables and a web of suspenders over the river, with warehouses below.
  static void _bridge(Canvas c, double x0, double h) {
    final stone = _hazed(const Color(0xff6c6690), .1);
    final stoneLit = _hazed(const Color(0xff8a84ac), .1);
    final cable = Paint()
      ..style = PaintingStyle.stroke
      ..color = _hazed(const Color(0xffa7a6cc), .1)
      ..strokeWidth = h * .003;
    final thin = Paint()
      ..color = Sketch.fade(_hazed(const Color(0xff9d9cc4), .1), .6)
      ..strokeWidth = h * .0015;
    final deck = h * .705;
    final towers = [x0, x0 + h * .95];
    final top = h * .46;
    // Suspenders first, then the cables over them.
    Offset main(double t) {
      final a = Offset(towers[0], top + h * .012),
          b = Offset(towers[1], top + h * .012);
      final p = Offset.lerp(a, b, t)!;
      return p + Offset(0, (deck - top - h * .02) * 4 * t * (1 - t));
    }

    for (var i = 1; i < 30; i++) {
      final p = main(i / 30);
      c.drawLine(p, Offset(p.dx, deck), thin);
    }
    final span = Path()..moveTo(towers[0], top + h * .012);
    for (var i = 1; i <= 30; i++) {
      final p = main(i / 30);
      span.lineTo(p.dx, p.dy);
    }
    c.drawPath(span, cable);
    for (final (from, to) in [
      (Offset(towers[0], top + h * .012), Offset(towers[0] - h * .45, deck)),
      (Offset(towers[1], top + h * .012), Offset(towers[1] + h * .45, deck)),
    ]) {
      final side = Path()..moveTo(from.dx, from.dy);
      for (var i = 1; i <= 12; i++) {
        final t = i / 12;
        final p = Offset.lerp(from, to, t)!;
        final q =
            p + Offset(0, -(deck - from.dy) * .25 * math.sin(t * math.pi));
        side.lineTo(q.dx, q.dy);
        c.drawLine(q, Offset(q.dx, deck), thin);
      }
      c.drawPath(side, cable);
    }
    // Deck and its lamps.
    c.drawRect(
      Rect.fromLTRB(x0 - h * .5, deck, x0 + h * 1.5, deck + h * .012),
      Paint()..color = stone,
    );
    final lamp = Paint()..color = Sketch.fade(_window, .9);
    for (var x = x0 - h * .45; x < x0 + h * 1.45; x += h * .06) {
      c.drawCircle(Offset(x, deck - h * .002), h * .0028, lamp);
    }
    for (final tx in towers) {
      final r = Rect.fromLTRB(tx - h * .04, top, tx + h * .04, h * .78);
      c.drawRect(r, Paint()..color = stone);
      c.drawRect(
        Rect.fromLTRB(tx + h * .012, top, r.right, r.bottom),
        Paint()..color = stoneLit,
      );
      c.drawRect(
        Rect.fromLTRB(
          r.left - h * .005,
          top - h * .012,
          r.right + h * .005,
          top,
        ),
        Paint()..color = stoneLit,
      );
      // Twin pointed arches.
      final arch = Paint()..color = const Color(0xff2c2d52);
      for (final dx in const [-.019, .019]) {
        final ax = tx + dx * h;
        c.drawPath(
          Path()
            ..moveTo(ax - h * .011, deck + h * .01)
            ..lineTo(ax - h * .011, h * .55)
            ..quadraticBezierTo(ax - h * .011, h * .52, ax, h * .505)
            ..quadraticBezierTo(ax + h * .011, h * .52, ax + h * .011, h * .55)
            ..lineTo(ax + h * .011, deck + h * .01)
            ..close(),
          arch,
        );
      }
    }
    // Warehouses along the far shore.
    final shed = _hazed(const Color(0xff403d68), .1);
    final lit = Path();
    for (var i = 0; i < 9; i++) {
      final x = x0 - h * .6 + i * h * .32;
      final tall = h * (.03 + .03 * Sketch.hash(i + 900));
      final r = Rect.fromLTWH(
        x,
        h * .76 - tall,
        h * (.18 + .08 * Sketch.hash(i + 901)),
        tall + h * .04,
      );
      c.drawRect(r, Paint()..color = shed);
      for (var k = 0; k < 4; k++) {
        if (Sketch.hash(i * 5 + k) < .5) {
          lit.addRect(
            Rect.fromLTWH(
              r.left + r.width * (.12 + k * .2),
              r.top + tall * .35,
              h * .008,
              h * .008,
            ),
          );
        }
      }
    }
    c.drawPath(lit, Paint()..color = Sketch.fade(_window, .8));
  }

  /// A brick walk-up: parapet, window grid, fire escape or water tower.
  static void _tenement(Canvas c, Rect r, int kind, int seed) {
    final h = r.bottom / .96;
    final brick = [
      const Color(0xff4b3a4f),
      const Color(0xff3f3957),
      const Color(0xff533e4a),
      const Color(0xff45405e),
    ][seed % 4];
    c.drawRect(r, Paint()..color = brick);
    c.drawRect(
      Rect.fromLTRB(r.right - r.width * .12, r.top, r.right, r.bottom),
      Paint()..color = Sketch.mix(brick, const Color(0xff1a1828), .35),
    );
    c.drawRect(
      Rect.fromLTRB(r.left, r.top, r.right, r.top + h * .012),
      Paint()..color = Sketch.mix(brick, const Color(0xff9a8fb0), .35),
    );
    // Windows: warm when lit, dusky blue when dark.
    final lit = Path(), dark = Path();
    final cols = math.max(2, (r.width / (h * .06)).floor());
    final colW = r.width / cols;
    for (var row = 0; row < 5; row++) {
      final y = r.top + h * (.035 + row * .045);
      if (y > r.bottom - h * .03) break;
      for (var col = 0; col < cols; col++) {
        final win = Rect.fromLTWH(
          r.left + colW * (col + .3),
          y,
          colW * .4,
          h * .026,
        );
        (Sketch.hash(seed * 31 + row * 7 + col) < .3 ? lit : dark).addRect(win);
      }
    }
    c.drawPath(dark, Paint()..color = const Color(0xff2a2a47));
    c.drawPath(lit, Paint()..color = const Color(0xfff2c46a));
    if (kind == 1) _fireEscape(c, r, h);
    if (kind == 2) {
      _waterTower(c, Offset(r.left + r.width * .35, r.top), h * .05);
    }
    if (kind == 0) {
      c.drawRect(
        Rect.fromLTWH(
          r.left + r.width * .7,
          r.top - h * .03,
          h * .018,
          h * .03,
        ),
        Paint()..color = Sketch.mix(brick, const Color(0xff1a1828), .3),
      );
    }
  }

  static void _fireEscape(Canvas c, Rect r, double h) {
    final iron = Paint()
      ..color = const Color(0xff17151f)
      ..strokeWidth = h * .003;
    final left = r.left + r.width * .22, right = r.left + r.width * .78;
    for (var row = 0; row < 4; row++) {
      final y = r.top + h * (.065 + row * .045);
      if (y > r.bottom - h * .02) break;
      c.drawLine(
        Offset(left, y),
        Offset(right, y),
        iron..strokeWidth = h * .004,
      );
      c.drawLine(
        Offset(left, y - h * .012),
        Offset(right, y - h * .012),
        iron..strokeWidth = h * .0018,
      );
      for (var x = left; x <= right; x += h * .012) {
        c.drawLine(Offset(x, y), Offset(x, y - h * .012), iron);
      }
      final down = row.isEven;
      c.drawLine(
        Offset(down ? left + h * .01 : right - h * .01, y),
        Offset(down ? right - h * .02 : left + h * .02, y + h * .045),
        iron..strokeWidth = h * .003,
      );
    }
  }

  static void _waterTower(Canvas c, Offset roof, double s) {
    final wood = Paint()..color = const Color(0xff5d4a4a);
    final hoop = Paint()
      ..color = const Color(0xff2a2433)
      ..strokeWidth = s * .05;
    final leg = Paint()
      ..color = const Color(0xff2a2433)
      ..strokeWidth = s * .06;
    for (final dx in const [-.45, .45]) {
      c.drawLine(
        roof + Offset(dx * s, s * .1),
        roof + Offset(dx * s * .8, -s * .6),
        leg,
      );
    }
    final tank = Rect.fromLTRB(
      roof.dx - s * .5,
      roof.dy - s * 1.5,
      roof.dx + s * .5,
      roof.dy - s * .55,
    );
    c.drawRect(tank, wood);
    c.drawRect(
      Rect.fromLTRB(tank.right - s * .2, tank.top, tank.right, tank.bottom),
      Paint()..color = const Color(0xff4a3a40),
    );
    for (final k in const [.25, .55, .85]) {
      final y = tank.top + tank.height * k;
      c.drawLine(Offset(tank.left, y), Offset(tank.right, y), hoop);
    }
    c.drawPath(
      Sketch.poly([-.56, -1.48, 0, -1.95, .56, -1.48], at: roof, s: s),
      Paint()..color = const Color(0xff3f3242),
    );
  }
}
