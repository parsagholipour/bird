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
    radius: .056,
    disc: Color(0xfff6f1e2),
    glow: Color(0xffc9d0ff),
    halo: .36,
    strength: .34,
    moon: 1,
  );

  static final _weather = Weather(Weather.of([(Mote.rain, 30)]));
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
      Color(0xff403d76),
      Color(0xff141833),
      Color(0xff8b86b8),
      rimWidth: .0016,
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
    Depth.low => _riverWL,
    Depth.near => .94,
  };

  @override
  double period(Depth d) => d == Depth.low ? 2.4 : 3.2;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .56,
    Depth.mid => .4,
    Depth.low => .13,
    Depth.near => .3,
  };

  /// Near rooftops across one repeat: (width, roof height, facade, rooftop)
  /// in viewport heights. Facades: 0 brick, 1 brick with a fire escape,
  /// 2 arched loft, 3 tan strip-window block. Rooftops: 0 chimneys, 1 water
  /// tower, 2 antennas and washing line, 3 pigeon coop and string lights,
  /// 4 neon sign, 5 stair bulkhead. The widths add up to the 3.2 h period.
  static const _roofs = [
    (.34, .81, 1, 1),
    (.26, .79, 0, 0),
    (.36, .85, 2, 3),
    (.22, .78, 3, 5),
    (.32, .81, 1, 2),
    (.3, .87, 0, 4),
    (.26, .8, 2, 0),
    (.34, .84, 3, 1),
    (.28, .79, 1, 5),
    (.24, .85, 0, 2),
    (.28, .82, 2, 1),
  ];

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _skyline(c, w, h);
      case Depth.mid:
        _bridge(c, w * .24, h, w);
      case Depth.low:
        _riverShoreline(c, h);
      case Depth.near:
        _roofRow(c, h);
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    switch (d) {
      case Depth.far:
        _skylineLive(c, f);
      case Depth.mid:
        _bridgeLive(c, f);
      case Depth.low:
        _riverLive(c, f);
      case Depth.near:
        _roofLive(c, f, copy);
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    switch (d) {
      case Depth.low:
        _riverOverlay(c, f, presence);
      case Depth.near:
        _roofOverlay(c, f, presence, period(d) * f.h);
      case Depth.far || Depth.mid:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) =>
      _riverReflect(c, f, presence);

  // ---------------------------------------------------------------------------
  // The East River (low band): the far shore, the water, boats and rain rings.

  /// Repeat width of the low band (the same as [period]) and the waterline, in
  /// viewport heights. Everything on the far shore stands on the waterline.
  static const _riverSpan = 2.4;
  static const _riverWL = .755;
  static const _riverRed = Color(0xffff5a55);
  static const _riverGreen = Color(0xff5cf2a4);
  static const _riverWhite = Color(0xfff6f2ff);
  static const _riverBlue = Color(0xff9bb4ff);
  static const _riverInk = Color(0xff1a1a3c);

  /// Waterfront blocks along one repeat: (x, width, height above the
  /// waterline) in viewport heights. The widths add up to the repeat, so the
  /// row tiles without a seam.
  static final _riverBlocks = _riverMakeBlocks();

  static List<(double, double, double)> _riverMakeBlocks() {
    final blocks = <(double, double, double)>[];
    var x = 0.0;
    for (var i = 0; x < _riverSpan - .001; i++) {
      var w = .05 + .09 * Sketch.hash(i + 3100);
      if (_riverSpan - x - w < .06) w = _riverSpan - x;
      blocks.add((x, w, .021 + .019 * Sketch.hash(i + 3200)));
      x += w;
    }
    return blocks;
  }

  /// 1 warm, 2 blue TV glow, 0 dark: one window of one block.
  static int _riverWin(int block, int col, int row) {
    final n = Sketch.hash(block * 131 + col * 17 + row * 7 + 3300);
    return n < .3
        ? 1
        : n < .4
        ? 2
        : 0;
  }

  /// Where block [i] carries a radio mast (viewport heights), if it does.
  static Offset? _riverMastAt(int i) {
    final kind = Sketch.hash(i + 3500);
    if (kind < .22 || kind >= .4) return null;
    final (bx, bw, bt) = _riverBlocks[i];
    return Offset(bx + bw * (.25 + .5 * Sketch.hash(i + 3600)), _riverWL - bt);
  }

  /// The far shore, static: a hazy second bridge, waterfront blocks with lit
  /// windows, a container crane, the elevated drive and the quay.
  static void _riverShoreline(Canvas c, double h) {
    final wl = _riverWL * h, span = _riverSpan * h, pad = h * .6;
    final fill = Paint();
    _riverTower(c, Offset(h * 1.62, wl), h);
    final block = _hazed(const Color(0xff363564), .1);
    final lift = Sketch.mix(block, const Color(0xffd2c8f0), .26);
    final warm = Path(), blue = Path(), dim = Path();
    // A backing strip hides hairline gaps between abutting blocks.
    c.drawRect(
      Rect.fromLTRB(-pad, wl - h * .016, span + pad, wl + h * .02),
      fill..color = block,
    );
    for (var i = 0; i < _riverBlocks.length; i++) {
      final (bx, bw, bt) = _riverBlocks[i];
      final tone = Sketch.mix(
        block,
        const Color(0xff5a5790),
        .2 * Sketch.hash(i + 3400),
      );
      final r = Rect.fromLTWH(bx * h, wl - bt * h, bw * h, bt * h + h * .02);
      c.drawRect(r, fill..color = tone);
      c.drawRect(
        Rect.fromLTRB(
          r.right - math.min(h * .008, r.width * .18),
          r.top,
          r.right,
          r.bottom,
        ),
        fill..color = Sketch.mix(tone, lift, .5),
      );
      c.drawRect(
        Rect.fromLTWH(r.left, r.top, r.width, h * .0016),
        fill..color = lift,
      );
      final cols = ((bw - .012) / .0105).floor();
      for (var col = 0; col < cols; col++) {
        final wx = (bx + .006 + col * .0105) * h;
        for (var row = 0; row < 3; row++) {
          final wy = r.top + h * (.005 + row * .0085);
          if (wy + h * .0055 > wl - h * .0135) break;
          final win = Rect.fromLTWH(wx, wy, h * .0045, h * .0055);
          final s = _riverWin(i, col, row);
          (s == 1 ? warm : (s == 2 ? blue : dim)).addRect(win);
        }
      }
      final kind = Sketch.hash(i + 3500);
      if (kind < .22) {
        _riverTank(
          c,
          Offset(r.left + r.width * (.25 + .5 * Sketch.hash(i + 3600)), r.top),
          h * .011,
        );
      }
      final mast = _riverMastAt(i);
      if (mast != null) {
        final m = mast * h;
        c.drawLine(
          m,
          m - Offset(0, h * .016),
          fill
            ..color = lift
            ..strokeWidth = math.max(.7, h * .0013),
        );
        fill.strokeWidth = 0;
        c.drawCircle(
          m - Offset(0, h * .016),
          h * .0018,
          fill..color = Sketch.fade(_riverRed, .6),
        );
      }
    }
    c.drawPath(dim, fill..color = Sketch.mix(block, _riverInk, .5));
    c.drawPath(blue, fill..color = Sketch.fade(_riverBlue, .75));
    c.drawPath(warm, fill..color = Sketch.fade(_window, .9));
    _riverCrane(c, Offset(h * .22, wl), h * .1);
    // The elevated drive: dark underside, columns, slab, lit barrier, lamps.
    final deck = wl - h * .0105;
    c.drawRect(
      Rect.fromLTRB(-pad, deck, span + pad, wl + h * .02),
      fill..color = const Color(0xff15153a),
    );
    for (var i = 0; i < 40; i++) {
      c.drawRect(
        Rect.fromLTWH((.03 + i * .06) * h, deck, h * .004, wl - deck),
        fill..color = const Color(0xff28285a),
      );
    }
    c.drawRect(
      Rect.fromLTRB(-pad, deck, span + pad, deck + h * .004),
      fill..color = const Color(0xff26264f),
    );
    c.drawRect(
      Rect.fromLTRB(-pad, deck - h * .0016, span + pad, deck),
      fill..color = Sketch.mix(const Color(0xff26264f), lift, .55),
    );
    for (var i = 0; i < 24; i++) {
      final x = (.05 + i * .1) * h;
      final on = Sketch.hash(i + 3800) < .9;
      c.drawLine(
        Offset(x, deck),
        Offset(x, deck - h * .014),
        fill
          ..color = const Color(0xff1c1c42)
          ..strokeWidth = math.max(.7, h * .0013),
      );
      fill.strokeWidth = 0;
      final head = Offset(x + h * .004, deck - h * .0145);
      if (on) _riverGlow(c, head, h * .0105, _window, .42);
      c.drawCircle(
        head,
        h * .0021,
        fill..color = on ? _window : const Color(0xff4a4878),
      );
    }
    // The quay: a lit stone lip with bollards.
    c.drawRect(
      Rect.fromLTRB(-pad, wl - h * .0034, span + pad, wl + h * .02),
      fill..color = const Color(0xff33326a),
    );
    c.drawRect(
      Rect.fromLTRB(-pad, wl - h * .0034, span + pad, wl - h * .0018),
      fill..color = Sketch.mix(const Color(0xff33326a), lift, .5),
    );
    for (var i = 0; i < 60; i++) {
      c.drawRect(
        Rect.fromLTWH((.02 + i * .04) * h, wl - h * .0056, h * .0026, h * .0026),
        fill..color = const Color(0xff26264f),
      );
    }
  }

  /// A soft round glow: a radial gradient that fades to nothing at [r]. Only
  /// for static art (it builds a shader per call).
  static void _riverGlow(Canvas c, Offset at, double r, Color color, double alpha) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          1,
          [Sketch.fade(color, alpha), Sketch.fade(color, alpha * .35), Sketch.fade(color, 0)],
          const [0, .35, 1],
        ),
    );
    c.restore();
  }

  /// A little wooden rooftop water tank.
  static void _riverTank(Canvas c, Offset roof, double s) {
    final ink = Paint()
      ..color = _riverInk
      ..strokeWidth = math.max(.6, s * .09);
    c.drawLine(roof + Offset(-s * .3, 0), roof + Offset(-s * .3, -s * .5), ink);
    c.drawLine(roof + Offset(s * .3, 0), roof + Offset(s * .3, -s * .5), ink);
    c.drawRect(
      Rect.fromLTRB(roof.dx - s * .45, roof.dy - s * 1.5, roof.dx + s * .45, roof.dy - s * .5),
      Paint()..color = const Color(0xff2f2b52),
    );
    c.drawRect(
      Rect.fromLTRB(roof.dx + s * .2, roof.dy - s * 1.5, roof.dx + s * .45, roof.dy - s * .5),
      Paint()..color = const Color(0xff4a4677),
    );
    c.drawPath(
      Sketch.poly([-.5, -1.5, 0, -1.9, .5, -1.5], at: roof, s: s),
      Paint()..color = _riverInk,
    );
  }

  /// A container gantry crane with its boom raised, on the quay.
  static void _riverCrane(Canvas c, Offset base, double s) {
    final steel = Paint()
      ..color = _hazed(const Color(0xff2e2d5c), .1)
      ..strokeWidth = math.max(.8, s * .022)
      ..strokeCap = StrokeCap.round;
    final lit = Paint()
      ..color = _hazed(const Color(0xff6e6aa4), .1)
      ..strokeWidth = math.max(.6, s * .012);
    Offset p(double x, double y) => base + Offset(x * s, y * s);
    // Portal legs and the girder across them.
    for (final x in const [-.2, .2]) {
      c.drawLine(p(x, 0), p(x, -.56), steel);
      c.drawLine(p(x + (x < 0 ? .045 : -.045), 0), p(x + (x < 0 ? .045 : -.045), -.56), lit);
    }
    for (var k = 0; k < 4; k++) {
      final y = -.08 - k * .12;
      c.drawLine(p(-.2, y), p(.2, y - .12), lit);
    }
    c.drawRect(
      Rect.fromPoints(p(-.28, -.6), p(.28, -.53)),
      Paint()..color = _hazed(const Color(0xff2e2d5c), .1),
    );
    // The raised boom, its lattice and the stay to the apex.
    final tip = p(.96, -.98), root = p(-.02, -.6), apex = p(-.06, -1.0);
    c.drawLine(root, tip, steel);
    c.drawLine(p(.06, -.55), p(.96, -.93), steel);
    for (var k = 1; k < 9; k++) {
      final t = k / 9;
      c.drawLine(
        Offset.lerp(root, tip, t)!,
        Offset.lerp(p(.06, -.55), p(.96, -.93), t + .06)!,
        lit,
      );
    }
    c.drawLine(apex, tip, lit);
    c.drawLine(p(-.2, -.6), apex, steel);
    c.drawLine(p(.0, -.6), apex, steel);
    c.drawRect(
      Rect.fromPoints(p(-.34, -.68), p(-.06, -.6)),
      Paint()..color = _hazed(const Color(0xff383768), .1),
    );
    c.drawCircle(apex - Offset(0, s * .012), s * .016, Paint()..color = Sketch.fade(_riverRed, .6));
  }

  /// A hint of the Manhattan Bridge far up the river: a steel-lattice tower
  /// and the sag of its cables to a lit truss deck, in haze.
  static void _riverTower(Canvas c, Offset base, double h) {
    final steel = Paint()
      ..color = _hazed(const Color(0xff4a4880), .5)
      ..strokeWidth = math.max(.9, h * .0034)
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = _hazed(const Color(0xff5a578f), .5)
      ..strokeWidth = math.max(.5, h * .0011);
    Offset p(double x, double y) => base + Offset(x * h, y * h);
    const top = -.106;
    const half = .024;
    // Deck truss and its lamps.
    final deck = base.dy - h * .026;
    c.drawRect(
      Rect.fromLTRB(base.dx - h * .34, deck, base.dx + h * .34, deck + h * .006),
      Paint()..color = _hazed(const Color(0xff3c3b6c), .45),
    );
    // Cables sag from the tower tops to the deck either side.
    for (final side in const [-1.0, 1.0]) {
      final path = Path()..moveTo(p(side * half, top).dx, p(side * half, top).dy);
      for (var i = 1; i <= 12; i++) {
        final t = i / 12;
        final x = side * (half + t * .3);
        final y = top + (deck / h - base.dy / h - top) * (1 - math.pow(1 - t, 2.1));
        path.lineTo(p(x, y).dx, p(x, y).dy);
        if (i % 2 == 0) c.drawLine(p(x, y), Offset(p(x, y).dx, deck), thin);
      }
      c.drawPath(path, steel..style = PaintingStyle.stroke);
    }
    steel.style = PaintingStyle.fill;
    // Two tapering posts with X bracing and cross struts.
    for (final side in const [-1.0, 1.0]) {
      c.drawLine(p(side * half, top), p(side * (half + .006), 0), steel..strokeWidth = math.max(1.1, h * .0042));
    }
    for (var k = 0; k < 5; k++) {
      final y = top + k * (-top / 5);
      final y2 = top + (k + 1) * (-top / 5);
      final w0 = half + .006 * (k / 5), w1 = half + .006 * ((k + 1) / 5);
      c.drawLine(p(-w0, y), p(w1, y2), thin);
      c.drawLine(p(w0, y), p(-w1, y2), thin);
      c.drawLine(p(-w0, y), p(w0, y), steel..strokeWidth = math.max(.8, h * .003));
    }
    c.drawLine(p(-half - .004, top - .003), p(half + .004, top - .003), steel..strokeWidth = math.max(1.1, h * .004));
    final lamp = Paint()..color = Sketch.fade(_window, .55);
    for (var i = -6; i <= 6; i++) {
      c.drawCircle(Offset(base.dx + i * h * .05, deck - h * .002), h * .0016, lamp);
    }
  }

  /// Live shore life: traffic on the drive and blinking mast lights. Same
  /// coordinates as [_riverShoreline], behind the water.
  void _riverLive(Canvas c, SceneFrame f) {
    final h = f.h, clock = f.clock, span = _riverSpan;
    final y = (_riverWL - .0105) * h - h * .0038;
    final white = Path(), red = Path();
    // Cars glide along in two lanes; each lane repeats evenly so the pattern
    // never pops where copies meet.
    for (final (n, speed, lane, dir) in const [(9, .03, 0, 1.0), (7, -.022, 1, -1.0)]) {
      final gap = span / n;
      for (var i = 0; i < n; i++) {
        final x = ((i * gap + clock * speed) % span) * h;
        final yy = y + lane * h * .0022;
        white
          ..moveTo(x + dir * h * .003, yy)
          ..lineTo(x + dir * h * .0055, yy);
        red
          ..moveTo(x - dir * h * .001, yy)
          ..lineTo(x + dir * h * .001, yy);
      }
    }
    final lane = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.9, h * .0026);
    c.drawPath(white, lane..color = const Color(0xfffff2d0));
    c.drawPath(red, lane..color = Sketch.fade(_riverRed, .9));
    // Aircraft beacons on the crane and the radio masts blink out of step.
    final beacon = Paint();
    void blink(Offset at, double phase, double r) {
      final on = math.sin(clock * 2.4 + phase) > -.2;
      if (!on) return;
      c.drawCircle(at, r * 3.4, beacon..color = Sketch.fade(_riverRed, .22));
      c.drawCircle(at, r, beacon..color = _riverRed);
    }

    final wl = _riverWL * h;
    blink(Offset(h * (.22 - .1 * .06), wl - h * .1 * 1.012), 0, h * .0018);
    for (var i = 0; i < _riverBlocks.length; i++) {
      final m = _riverMastAt(i);
      if (m != null) blink(m * h - Offset(0, h * .016), i * 1.7, h * .0018);
    }
  }

  static final _riverPics = <double, List<Picture>>{};
  static final _riverLayer = Paint();

  /// Static art recorded once per viewport height: 0 the water surface with
  /// its reflections, 1 the piers, the statue and the buoys, 2 the low mist,
  /// 3 the ferry and 4 the tug with its barge (both around their own origin).
  static List<Picture> _riverPictures(double h) {
    final hit = _riverPics[h];
    if (hit != null) return hit;
    if (_riverPics.length > 3) {
      for (final p in _riverPics.remove(_riverPics.keys.first)!) {
        p.dispose();
      }
    }
    Picture record(void Function(Canvas) draw) {
      final recorder = PictureRecorder();
      draw(Canvas(recorder));
      return recorder.endRecording();
    }

    return _riverPics[h] = [
      record((c) => _riverWater(c, h)),
      record((c) => _riverLandmarks(c, h)),
      record((c) => _riverMist(c, h)),
      record((c) => _riverFerry(c, h)),
      record((c) => _riverTug(c, h)),
    ];
  }

  /// A light's reflection: short dashes stacked down from [y0], wider, fainter
  /// and more broken the farther they fall. Dashes are gathered by colour and
  /// strength in [batch] and painted together by [_riverFlush].
  static void _riverStreak(
    Map<(Color, int), Path> batch,
    double x,
    double y0,
    double h,
    Color color,
    double alpha,
    int n,
    double width,
    int seed,
  ) {
    final thick = math.max(.9, h * .0026);
    for (var j = 0; j < n; j++) {
      final t = j / n;
      final bucket = (alpha * (1 - t) * (.6 + .4 * Sketch.hash(seed + j + 9)) * 12).round();
      if (bucket < 1) continue;
      final len = h * width * (.55 + .9 * Sketch.hash(seed + j * 3 + 1)) * (1 + t * 1.2);
      final cx = x + (Sketch.hash(seed + j * 7) - .5) * h * .004 * (1 + t * 2);
      final y = y0 + h * (.0035 + j * .0048 * (1 + t * .5));
      batch.putIfAbsent((color, bucket), Path.new).addRect(Rect.fromCenter(center: Offset(cx, y), width: len, height: thick));
    }
  }

  static void _riverFlush(Canvas c, Map<(Color, int), Path> batch) {
    final p = Paint();
    batch.forEach((k, path) => c.drawPath(path, p..color = Sketch.fade(k.$1, k.$2 / 12)));
  }

  /// The water: pale crests and dark troughs, then the shore's lights and the
  /// city's colours reflected in broken, wavering columns.
  static void _riverWater(Canvas c, double h) {
    final span = _riverSpan * h, wl = _riverWL * h;
    final p = Paint();
    // Ripples: short and dense at the far shore, long and sparse near us.
    final crest = Path(), soft = Path(), trough = Path();
    const rows = 22;
    for (var r = 0; r < rows; r++) {
      final t = r / (rows - 1);
      final y = wl + h * (.004 + .11 * math.pow(t, 1.3));
      final n = (30 - 16 * t).round();
      for (var k = 0; k < n; k++) {
        final a = Sketch.hash(r * 211 + k * 17 + 3600);
        final len = h * (.02 + .075 * t) * (.5 + Sketch.hash(r * 131 + k * 29 + 3700));
        final rect = Rect.fromLTWH(
          span * a,
          y + h * .0022 * (Sketch.hash(r * 53 + k * 11 + 3800) - .5),
          len,
          h * (.0012 + .0016 * t),
        );
        final tone = Sketch.hash(r * 71 + k * 19 + 3900);
        (tone > .5 ? (t < .45 ? crest : soft) : trough).addRect(rect);
      }
    }
    c.drawPath(trough, p..color = Sketch.fade(const Color(0xff0c1029), .32));
    c.drawPath(soft, p..color = Sketch.fade(const Color(0xffa39ad6), .09));
    c.drawPath(crest, p..color = Sketch.fade(const Color(0xffe6b1cc), .12));
    final glints = <(Color, int), Path>{};
    // The far shore's lamps, in warm columns.
    for (var i = 0; i < 24; i++) {
      if (Sketch.hash(i + 3800) >= .9) continue;
      _riverStreak(glints, (.05 + i * .1) * h + h * .004, wl, h, _window, .78, 8, .007, i * 17 + 4000);
    }
    // Lit windows of the blocks.
    for (var i = 0; i < _riverBlocks.length; i++) {
      final (bx, bw, bt) = _riverBlocks[i];
      final cols = ((bw - .012) / .0105).floor();
      for (var col = 0; col < cols; col++) {
        for (var row = 0; row < 3; row++) {
          final wy = wl - bt * h + h * (.005 + row * .0085);
          if (wy + h * .0055 > wl - h * .0135) break;
          final s = _riverWin(i, col, row);
          if (s == 0 || Sketch.hash(i * 37 + col * 5 + row + 4100) > .45) continue;
          _riverStreak(
            glints,
            (bx + .006 + col * .0105 + .00225) * h,
            wl,
            h,
            s == 1 ? _window : _riverBlue,
            s == 1 ? .55 : .42,
            3 + (col + row) % 2,
            .0045,
            i * 41 + col * 3 + row + 4200,
          );
        }
      }
    }
    // Neon and floodlight colour from the far city, spilled at random.
    for (var i = 0; i < 9; i++) {
      final color = const [
        Color(0xfff39ac0),
        Color(0xff8fe6ee),
        Color(0xffffb35e),
        Color(0xffb69cff),
      ][i % 4];
      _riverStreak(glints, span * Sketch.hash(i + 4300), wl, h, color, .3, 7, .011, i * 23 + 4400);
    }
    // The crane's red beacon, the mast lights and the statue's floodlights.
    _riverStreak(glints, h * (.22 - .1 * .06), wl, h, _riverRed, .4, 5, .006, 4500);
    for (var i = 0; i < _riverBlocks.length; i++) {
      final m = _riverMastAt(i);
      if (m != null) _riverStreak(glints, m.dx * h, wl, h, _riverRed, .26, 4, .005, i * 13 + 4600);
    }
    _riverStreak(glints, h * 1.19, wl, h, const Color(0xffbdf0dc), .32, 6, .012, 4700);
    _riverStreak(glints, h * 1.196, wl, h, const Color(0xffffe9a8), .3, 5, .004, 4710);
    _riverFlush(c, glints);
  }

  /// Piers on stilts with their sheds, a floodlit Statue of Liberty out in
  /// the harbour and moored buoys. In front of the water.
  static void _riverLandmarks(Canvas c, double h) {
    final wl = _riverWL * h;
    _riverStatue(c, Offset(h * 1.19, wl + h * .004), h * .085);
    _riverPier(c, .5, .36, h, 1);
    _riverPier(c, 1.9, .24, h, 2);
    // Buoys: a red can and a green nun with their lamps (blinking is live).
    for (final (bx, red) in const [(1.02, true), (.4, false), (1.78, true), (2.28, false)]) {
      final at = Offset(h * bx, wl + h * (.012 + .008 * Sketch.hash((bx * 10).round())));
      final body = red ? const Color(0xff9a3a4e) : const Color(0xff2f7a68);
      c.drawOval(
        Rect.fromCenter(center: at + Offset(0, h * .001), width: h * .014, height: h * .003),
        Paint()..color = Sketch.fade(const Color(0xffbfb4ee), .28),
      );
      c.drawPath(
        Sketch.poly([-.004, 0, -.0026, -.011, .0026, -.011, .004, 0], at: at, s: h),
        Paint()..color = body,
      );
      c.drawPath(
        Sketch.poly([.0006, 0, .0008, -.011, .0026, -.011, .004, 0], at: at, s: h),
        Paint()..color = Sketch.mix(body, const Color(0xffe0d8ff), .3),
      );
      c.drawRect(
        Rect.fromLTWH(at.dx - h * .0015, at.dy - h * .0165, h * .003, h * .0055),
        Paint()..color = _riverInk,
      );
    }
  }

  static void _riverPier(Canvas c, double x0, double w, double h, int seed) {
    final wl = _riverWL * h, f = Paint();
    final left = x0 * h, right = (x0 + w) * h;
    final eave = wl - h * .022, peak = wl - h * .032;
    const wall = Color(0xff2a2a5a);
    // Pilings first, so the deck and shed sit on them.
    final posts = Path(), edge = Path();
    for (var x = left - h * .004; x < right + h * .005; x += h * .0115) {
      final drop = h * (.011 + .006 * Sketch.hash((x / h * 100).round() + seed));
      posts.addRect(Rect.fromLTWH(x, wl - h * .005, h * .0032, h * .005 + drop));
      edge.addRect(Rect.fromLTWH(x + h * .0023, wl - h * .005, h * .0009, h * .005 + drop));
    }
    c.drawPath(posts, f..color = _riverInk);
    c.drawPath(edge, f..color = const Color(0xff5c5a94));
    c.drawRect(
      Rect.fromLTRB(left - h * .006, wl - h * .005, right + h * .006, wl - h * .002),
      f..color = const Color(0xff33326a),
    );
    // Shed walls with a lit top course, a shallow roof and a lit clerestory.
    c.drawRect(Rect.fromLTRB(left, eave, right, wl - h * .005), f..color = wall);
    c.drawRect(Rect.fromLTRB(left, eave, right, eave + h * .0022), f..color = const Color(0xff3e3d74));
    c.drawRect(
      Rect.fromLTRB(right - h * .012, eave, right, wl - h * .005),
      f..color = const Color(0xff3c3b70),
    );
    c.drawPath(
      Sketch.poly([x0 - .005, _riverWL - .022, x0 + w * .5, _riverWL - .032, x0 + w + .005, _riverWL - .022], s: h),
      f..color = const Color(0xff1f1f4a),
    );
    c.drawPath(
      Sketch.poly([x0 + w * .5, _riverWL - .032, x0 + w + .005, _riverWL - .022, x0 + w * .5, _riverWL - .0226], s: h),
      f..color = const Color(0xff3c3b70),
    );
    final mon = Rect.fromLTRB(left + w * h * .37, peak - h * .006, left + w * h * .63, peak + h * .002);
    c.drawRect(mon, f..color = const Color(0xff26265a));
    c.drawRect(
      Rect.fromLTRB(mon.left + h * .004, mon.top + h * .0018, mon.right - h * .004, mon.top + h * .0042),
      f..color = Sketch.fade(_window, .85),
    );
    // Windows and a big lit door.
    final n = (w / .024).floor();
    final lit = Path(), dark = Path();
    for (var i = 0; i < n; i++) {
      final cx = left + (i + .5) * w * h / n;
      final r = Rect.fromCenter(center: Offset(cx, wl - h * .0135), width: h * .0075, height: h * .0105);
      ((Sketch.hash(i * 9 + seed * 31 + 4700) < .72 && (i - n ~/ 2).abs() > 0) ? lit : dark).addRect(r);
    }
    c.drawPath(dark, f..color = const Color(0xff17173a));
    c.drawPath(lit, f..color = Sketch.fade(_window, .95));
    final door = Rect.fromCenter(center: Offset(left + w * h * .5, wl - h * .0105), width: h * .014, height: h * .0125);
    c.drawRect(door, f..color = Sketch.fade(_window, .95));
    c.drawRect(Rect.fromLTWH(door.left, door.top, door.width, h * .0016), f..color = const Color(0xffffeeb8));
    // A rooftop sign in red neon on the first pier, a flag on the second.
    final pole = Paint()
      ..color = _riverInk
      ..strokeWidth = math.max(.7, h * .0013);
    if (seed == 1) {
      final sx = right - w * h * .22;
      c.drawLine(Offset(sx, eave), Offset(sx, eave - h * .012), pole);
      c.drawLine(Offset(sx + h * .034, eave), Offset(sx + h * .034, eave - h * .012), pole);
      c.drawRect(Rect.fromLTWH(sx - h * .004, eave - h * .0225, h * .042, h * .0105), f..color = const Color(0xff1c1b40));
      _riverGlow(c, Offset(sx + h * .017, eave - h * .017), h * .03, _riverRed, .2);
      for (var k = 0; k < 5; k++) {
        c.drawRect(
          Rect.fromLTWH(sx + h * (.0005 + k * .0074), eave - h * .0205, h * .0034, h * .0064),
          f..color = k.isOdd ? const Color(0xffff8a7a) : _riverRed,
        );
      }
    } else {
      final fx = left + w * h * .8;
      c.drawLine(Offset(fx, eave), Offset(fx, eave - h * .024), pole);
      c.drawPath(
        Sketch.poly([0, -.0245, .012, -.0225, 0, -.0195], at: Offset(fx, eave), s: h),
        f..color = const Color(0xffb0404c),
      );
    }
    // Lamp posts at both ends with soft halos.
    for (final x in [left - h * .008, right + h * .008]) {
      c.drawLine(Offset(x, wl - h * .005), Offset(x, wl - h * .026), pole);
      _riverGlow(c, Offset(x, wl - h * .027), h * .012, _window, .4);
      c.drawCircle(Offset(x, wl - h * .027), h * .0022, f..color = _window);
    }
    // A gull dozing on the outer piling.
    final g = Offset(right + h * .0016, wl - h * .0075);
    c.drawOval(Rect.fromCenter(center: g, width: h * .0075, height: h * .0042), f..color = const Color(0xffc9c5e6));
    c.drawCircle(g + Offset(h * .0034, -h * .0018), h * .0017, f..color = const Color(0xffe0dcf4));
  }

  /// The Statue of Liberty on her star-shaped island, floodlit pale green.
  static void _riverStatue(Canvas c, Offset base, double s) {
    Path poly(List<double> xy) => Sketch.poly(xy, at: base, s: s);
    final stone = Paint()..color = _hazed(const Color(0xff9490bc), .2);
    final stoneLit = Paint()..color = _hazed(const Color(0xffc4bfe2), .2);
    final fort = Paint()..color = _hazed(const Color(0xff2f2e5c), .1);
    final green = Paint()..color = const Color(0xff7fb4a6);
    final shade = Paint()..color = const Color(0xff4b7a78);
    // Floodlit wash behind her.
    _riverGlow(c, base + Offset(0, -s * .62), s * .8, const Color(0xffcaeee0), .2);
    // Fort Wood's star wall on the island.
    c.drawPath(poly([-.56, .02, -.5, -.1, -.3, -.15, .3, -.15, .5, -.1, .56, .02]), fort);
    c.drawPath(poly([-.36, -.15, -.32, -.22, -.18, -.24, -.1, -.2, .1, -.2, .18, -.24, .32, -.22, .36, -.15]), fort);
    for (var i = 0; i < 6; i++) {
      c.drawRect(
        Rect.fromLTWH(base.dx + s * (-.3 + i * .12), base.dy - s * .12, s * .03, s * .03),
        Paint()..color = Sketch.fade(_window, .75),
      );
    }
    // Pedestal: tapering block with a cornice, lit on the right.
    c.drawPath(poly([-.2, -.22, -.15, -.52, .15, -.52, .2, -.22]), stone);
    c.drawPath(poly([.05, -.22, .07, -.52, .15, -.52, .2, -.22]), stoneLit);
    c.drawRect(Rect.fromLTRB(base.dx - s * .19, base.dy - s * .56, base.dx + s * .19, base.dy - s * .52), stoneLit);
    // The robed figure, head, crown rays and the raised torch arm.
    c.drawPath(poly([-.11, -.56, -.07, -.84, .07, -.84, .11, -.56]), green);
    c.drawPath(poly([.02, -.56, .03, -.84, .07, -.84, .11, -.56]), shade);
    c.drawPath(poly([-.1, -.56, -.05, -.84, -.02, -.84, -.06, -.56]), Paint()..color = const Color(0xff5f9a91));
    // Torch arm and the flame.
    c.drawPath(poly([.05, -.84, .1, -.8, .13, -.98, .09, -1.0]), green);
    c.drawPath(
      poly([.07, -.99, .11, -.99, .12, -1.06, .1, -1.14, .085, -1.05]),
      Paint()..color = const Color(0xffffe9a8),
    );
    // Head and crown.
    c.drawCircle(base + Offset(0, -s * .885), s * .05, green);
    for (var i = 0; i < 7; i++) {
      final a = math.pi * (1.1 + .8 * i / 6);
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        base + Offset(0, -s * .885) + d * s * .045,
        base + Offset(0, -s * .885) + d * s * .105,
        Paint()
          ..color = green.color
          ..strokeWidth = math.max(.6, s * .014),
      );
    }
    // The tablet held on her left arm.
    c.drawPath(poly([-.14, -.78, -.09, -.8, -.085, -.7, -.135, -.68]), stoneLit);
  }

  /// A tug pushing a laden barge, bow to the right, around the tug's waterline
  /// centre. The bow light is green: we see her starboard side.
  static void _riverTug(Canvas c, double h) {
    final f = Paint();
    final glints = <(Color, int), Path>{};
    Path poly(List<double> xy) => Sketch.poly(xy, s: h);
    final ink = Paint()
      ..color = _riverInk
      ..strokeWidth = math.max(.6, h * .0012);
    // Wake trailing astern, and the bow wave.
    for (var i = 0; i < 6; i++) {
      final x0 = -.064 - i * .028, len = .09 + i * .02;
      f.color = Sketch.fade(const Color(0xffcfc8f4), .26 - i * .035);
      c.drawRect(Rect.fromLTWH(x0 * h - len * h, (.0035 + i * .0024) * h, len * h, math.max(.9, h * .0022)), f);
    }
    c.drawOval(
      Rect.fromLTWH(h * .058, h * -.001, h * .03, h * .0045),
      f..color = Sketch.fade(const Color(0xffeae6ff), .5),
    );
    // Barge ahead of her: raked hull, lit rail, cargo of ribbed containers, work lights.
    c.drawPath(poly([.074, -.0125, .079, .004, .296, .004, .303, -.0125]), f..color = const Color(0xff1b1b3d));
    c.drawPath(poly([.074, -.0125, .0765, -.0035, .3, -.0035, .303, -.0125]), f..color = const Color(0xff262552));
    c.drawRect(Rect.fromLTWH(h * .074, h * -.0135, h * .229, h * .0015), f..color = const Color(0xff5a578f));
    var x = .09;
    var i = 0;
    final ribs = Path(), tops = Path();
    while (x < .285) {
      final wdt = .034 + .01 * Sketch.hash(i + 4800);
      if (x + wdt > .296) break;
      final tone = const [
        Color(0xff7a3f58),
        Color(0xff3d6d80),
        Color(0xff8a7a4a),
        Color(0xff4b4c86),
      ][(Sketch.hash(i + 4850) * 4).floor() % 4];
      final high = Sketch.hash(i + 4900) < .5;
      void box(double bx, double by, Color t) {
        c.drawRect(Rect.fromLTWH(bx * h, by * h, wdt * h, .0122 * h), f..color = t);
        tops.addRect(Rect.fromLTWH(bx * h, by * h, wdt * h, math.max(.7, h * .0012)));
        for (var k = 1; k < 6; k++) {
          ribs.addRect(Rect.fromLTWH((bx + wdt * k / 6) * h, (by + .0016) * h, math.max(.5, h * .0006), .0092 * h));
        }
      }

      box(x, -.0255, tone);
      if (high) box(x + .002, -.0378, Sketch.mix(tone, _riverInk, .3));
      x += wdt + .003;
      i++;
    }
    c.drawPath(ribs, f..color = Sketch.fade(_riverInk, .35));
    c.drawPath(tops, f..color = Sketch.fade(const Color(0xffe0d8ff), .35));
    for (final lx in const [.084, .292]) {
      c.drawLine(Offset(lx * h, h * -.014), Offset(lx * h, h * -.03), ink);
      c.drawCircle(Offset(lx * h, h * -.031), h * .008, f..color = Sketch.fade(_riverWhite, .2));
      c.drawCircle(Offset(lx * h, h * -.031), h * .002, f..color = _riverWhite);
    }
    // The tug: hull, deckhouse, wheelhouse, funnel and mast.
    c.drawPath(poly([-.062, -.01, -.06, .002, .03, .005, .06, .001, .07, -.015, .03, -.011]), f..color = const Color(0xff171735));
    c.drawPath(poly([-.062, -.01, .03, -.011, .07, -.015, .07, -.0135, .03, -.0095, -.062, -.0085]), f..color = const Color(0xff5b5892));
    c.drawRect(Rect.fromLTRB(h * -.045, h * -.026, h * .022, h * -.0105), f..color = const Color(0xff3b3970));
    c.drawRect(Rect.fromLTRB(h * .011, h * -.026, h * .022, h * -.0105), f..color = const Color(0xff4f4c86));
    c.drawRect(Rect.fromLTRB(h * -.03, h * -.041, h * .014, h * -.026), f..color = const Color(0xff44417a));
    c.drawRect(Rect.fromLTRB(h * .004, h * -.041, h * .014, h * -.026), f..color = const Color(0xff55529a));
    c.drawRect(Rect.fromLTRB(h * -.034, h * -.0435, h * .018, h * -.041), f..color = const Color(0xff1c1b3a));
    c.drawPath(poly([-.047, -.026, -.043, -.052, -.03, -.052, -.028, -.026]), f..color = const Color(0xff2e2c58));
    c.drawPath(poly([-.0448, -.038, -.0437, -.045, -.0292, -.045, -.0285, -.038]), f..color = const Color(0xffb0404c));
    c.drawRect(Rect.fromLTRB(h * -.0445, h * -.0525, h * -.0295, h * -.0505), f..color = _riverInk);
    final lit = Path();
    for (var k = 0; k < 4; k++) {
      lit.addRect(Rect.fromLTWH(h * (-.04 + k * .0125), h * -.0225, h * .0075, h * .0062));
    }
    for (var k = 0; k < 3; k++) {
      lit.addRect(Rect.fromLTWH(h * (-.0265 + k * .0115), h * -.0375, h * .0085, h * .0072));
    }
    c.drawPath(lit, f..color = Sketch.fade(_window, .96));
    // Handrail along the foredeck, a searchlight and the mast.
    c.drawLine(
      Offset(h * .024, h * -.0165),
      Offset(h * .066, h * -.0185),
      Paint()
        ..color = const Color(0xff6a67a6)
        ..strokeWidth = math.max(.6, h * .001),
    );
    c.drawLine(Offset(h * -.008, h * -.0435), Offset(h * -.008, h * -.064), ink);
    c.drawRect(Rect.fromLTWH(h * .008, h * -.0465, h * .004, h * .003), f..color = const Color(0xffe8e2ff));
    c.drawCircle(Offset(h * -.008, h * -.0645), h * .009, f..color = Sketch.fade(_riverWhite, .22));
    c.drawCircle(Offset(h * -.008, h * -.0645), h * .0022, f..color = _riverWhite);
    for (final (fx, fy) in const [(.066, -.0075), (.0655, -.0028)]) {
      c.drawCircle(Offset(fx * h, fy * h), h * .0033, f..color = const Color(0xff0f0f28));
    }
    c.drawCircle(Offset(h * .052, h * -.0125), h * .0075, f..color = Sketch.fade(_riverGreen, .3));
    c.drawCircle(Offset(h * .052, h * -.0125), h * .0019, f..color = _riverGreen);
    c.drawCircle(Offset(h * -.059, h * -.0135), h * .0017, f..color = _riverWhite);
    c.drawOval(
      Rect.fromCenter(center: Offset(h * .08, h * .008), width: h * .3, height: h * .009),
      f..color = Sketch.fade(const Color(0xff090c22), .3),
    );
    // Reflections of her windows and lights.
    for (var k = 0; k < 4; k++) {
      _riverStreak(glints, h * (-.036 + k * .0125), 0, h, _window, .5, 4, .005, 5000 + k * 5);
    }
    _riverStreak(glints, h * -.008, 0, h, _riverWhite, .3, 5, .006, 5030);
    _riverStreak(glints, h * .052, 0, h, _riverGreen, .34, 5, .007, 5040);
    _riverStreak(glints, h * .292, 0, h, _riverWhite, .3, 4, .005, 5050);
    _riverFlush(c, glints);
  }

  /// A commuter ferry, bow to the right (the overlay mirrors her): dark hull
  /// with an orange sheer band, pale decks with lit windows and a red port light.
  static void _riverFerry(Canvas c, double h) {
    final f = Paint();
    final glints = <(Color, int), Path>{};
    Path poly(List<double> xy) => Sketch.poly(xy, s: h);
    // Wake astern.
    for (var i = 0; i < 5; i++) {
      final len = .07 + i * .02;
      f.color = Sketch.fade(const Color(0xffcfc8f4), .22 - i * .035);
      c.drawRect(Rect.fromLTWH((-.098 - i * .024 - len) * h, (.003 + i * .0022) * h, len * h, math.max(.9, h * .002)), f);
    }
    c.drawPath(poly([-.096, -.0135, -.093, .0045, .07, .006, .1, .001, .105, -.017, .052, -.0135]), f..color = const Color(0xff4a2c46));
    c.drawPath(poly([-.094, .0005, .07, .0018, .1, -.0005, .1005, .001, .07, .006, -.093, .0045]), f..color = const Color(0xff8a3a48));
    c.drawPath(poly([-.096, -.0135, .052, -.0135, .105, -.017, .1045, -.0145, .052, -.0107, -.096, -.0107]), f..color = const Color(0xffbc7046));
    c.drawRect(Rect.fromLTRB(h * -.088, h * -.031, h * .088, h * -.0135), f..color = const Color(0xff8580b2));
    c.drawRect(Rect.fromLTRB(h * .06, h * -.031, h * .088, h * -.0135), f..color = const Color(0xff9c98c8));
    c.drawRect(Rect.fromLTRB(h * -.088, h * -.0318, h * .088, h * -.031), f..color = const Color(0xffb8b4de));
    c.drawRect(Rect.fromLTRB(h * -.064, h * -.048, h * .064, h * -.0318), f..color = const Color(0xff8f8bbd));
    c.drawRect(Rect.fromLTRB(h * -.064, h * -.0488, h * .064, h * -.048), f..color = const Color(0xffb8b4de));
    c.drawRect(Rect.fromLTRB(h * .028, h * -.062, h * .064, h * -.0488), f..color = const Color(0xff9a96c6));
    c.drawRect(Rect.fromLTRB(h * .022, h * -.0645, h * .07, h * -.062), f..color = const Color(0xff2b2b58));
    for (final fx in const [-.024, .006]) {
      c.drawPath(poly([fx - .006, -.0488, fx - .0045, -.068, fx + .0045, -.068, fx + .006, -.0488]), f..color = const Color(0xff8a4c4e));
      c.drawRect(Rect.fromLTRB((fx - .0046) * h, h * -.0705, (fx + .0046) * h, h * -.0672), f..color = _riverInk);
    }
    // Lifeboats hang over the upper deck.
    for (final lx in const [-.05, -.038, .014, .026]) {
      c.drawOval(Rect.fromCenter(center: Offset(lx * h, h * -.0505), width: h * .0095, height: h * .004), f..color = const Color(0xffc9743e));
    }
    final lit = Path(), dark = Path();
    for (var k = 0; k < 20; k++) {
      (Sketch.hash(k + 5060) < .88 ? lit : dark).addRect(Rect.fromLTWH(h * (-.082 + k * .0082), h * -.0275, h * .0055, h * .0058));
    }
    for (var k = 0; k < 15; k++) {
      (Sketch.hash(k + 5090) < .9 ? lit : dark).addRect(Rect.fromLTWH(h * (-.058 + k * .0082), h * -.0445, h * .0055, h * .0058));
    }
    for (var k = 0; k < 4; k++) {
      lit.addRect(Rect.fromLTWH(h * (.031 + k * .0085), h * -.0582, h * .0058, h * .0055));
    }
    c.drawPath(dark, f..color = const Color(0xff4b4880));
    c.drawPath(lit, f..color = Sketch.fade(const Color(0xffffe6ae), .96));
    c.drawLine(
      Offset(h * .05, h * -.0645),
      Offset(h * .05, h * -.084),
      Paint()
        ..color = _riverInk
        ..strokeWidth = math.max(.7, h * .0013),
    );
    c.drawCircle(Offset(h * .05, h * -.0845), h * .009, f..color = Sketch.fade(_riverWhite, .22));
    c.drawCircle(Offset(h * .05, h * -.0845), h * .0022, f..color = _riverWhite);
    c.drawCircle(Offset(h * .096, h * -.0145), h * .0078, f..color = Sketch.fade(_riverRed, .3));
    c.drawCircle(Offset(h * .096, h * -.0145), h * .0019, f..color = _riverRed);
    c.drawCircle(Offset(h * -.093, h * -.0165), h * .0017, f..color = _riverWhite);
    c.drawOval(
      Rect.fromCenter(center: Offset(0, h * .009), width: h * .22, height: h * .009),
      f..color = Sketch.fade(const Color(0xff090c22), .28),
    );
    for (var k = 0; k < 6; k++) {
      _riverStreak(glints, h * (-.07 + k * .028), h * .002, h, _window, .42, 4, .006, 5100 + k * 5);
    }
    _riverStreak(glints, h * .05, h * .002, h, _riverWhite, .3, 5, .006, 5140);
    _riverStreak(glints, h * .096, h * .002, h, _riverRed, .34, 5, .007, 5150);
    _riverFlush(c, glints);
  }

  /// Low mist banks lying on the water at the foot of the far shore.
  static void _riverMist(Canvas c, double h) {
    final wl = _riverWL * h;
    for (var i = 0; i < 9; i++) {
      final x = _riverSpan * h * (i + .5 * Sketch.hash(i + 5200)) / 9;
      final wd = h * (.34 + .3 * Sketch.hash(i + 5300));
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, wl - h * .002 + h * .01 * Sketch.hash(i + 5400)), width: wd, height: h * (.035 + .02 * Sketch.hash(i + 5500))),
        i.isEven ? const Color(0xffb7a7d8) : const Color(0xffd8a9c0),
        .2,
      );
    }
  }

  /// Everything on the water each frame: the cached art, boats that slide and
  /// bob, gulls, buoy lamps and rain rings.
  void _riverOverlay(Canvas c, SceneFrame f, double presence) {
    if (presence <= .01) return;
    final h = f.h, span = _riverSpan * h, clock = f.clock, wl = _riverWL * h;
    final pics = _riverPictures(h);
    final fading = presence < .995;
    c.save();
    if (fading) {
      c.saveLayer(
        Rect.fromLTRB(-h * .5, h * .62, span + h * .5, h * .95),
        _riverLayer..color = Color.fromRGBO(0, 0, 0, presence),
      );
    }
    // While a crossing fades the river out it also settles a little.
    if (!f.reducedMotion) c.translate(0, h * .05 * (1 - presence));
    c.drawPicture(pics[0]);
    c.drawPicture(pics[1]);
    c.drawPicture(pics[2]);
    // Boats slide along the water at their own pace: the row repeats evenly,
    // so wrapping never pops.
    double slide(double x0, double v) => (((x0 + v * clock) % _riverSpan) + _riverSpan) % _riverSpan;
    c.save();
    c.translate(slide(1.62, -.0148) * h, h * .7715 + math.sin(clock * .9 + 1) * h * .0011);
    c.scale(-1, 1);
    c.drawPicture(pics[3]);
    c.restore();
    c.save();
    c.translate(slide(.05, .0148) * h, h * .7905 + math.sin(clock * 1.2) * h * .0013);
    c.scale(1.12);
    c.drawPicture(pics[4]);
    c.restore();
    // Two gulls wheel low over the river.
    final gull = Sketch.fade(const Color(0xffe4e0f6), .85);
    for (var i = 0; i < 2; i++) {
      final x = slide(.9 + i * 1.1, .05 - i * .09) * h;
      final y = wl - h * (.02 + .012 * math.sin(clock * .6 + i * 2.4));
      Sketch.bird(c, Offset(x, y), h * .0065, gull, flap: math.sin(clock * 5.2 + i * 1.9));
    }
    // Buoy lamps blink and their light wavers below.
    final lamp = Paint();
    for (final (bx, red, phase) in const [(1.02, true, 0.0), (.4, false, 1.3), (1.78, true, 2.6), (2.28, false, .7)]) {
      final at = Offset(h * bx, wl + h * (.012 + .008 * Sketch.hash((bx * 10).round())));
      final on = ((clock * .55 + phase * .3) % 1) < .42;
      if (!on) continue;
      final color = red ? _riverRed : _riverGreen;
      c.drawCircle(at - Offset(0, h * .0178), h * .0065, lamp..color = Sketch.fade(color, .3));
      c.drawCircle(at - Offset(0, h * .0178), h * .0019, lamp..color = color);
      c.drawRect(Rect.fromCenter(center: at + Offset(0, h * .006), width: h * .009, height: math.max(.9, h * .0024)), lamp..color = Sketch.fade(color, .4));
    }
    // A glint slides down every other lamp's reflection.
    for (var i = 0; i < 24; i += 2) {
      final t = (clock * .45 + i * .37) % 1;
      lamp.color = Sketch.fade(const Color(0xfffff0c8), math.sin(t * math.pi) * .6);
      c.drawRect(
        Rect.fromCenter(
          center: Offset((.05 + i * .1) * h + h * .004 + math.sin(clock * 2.6 + i) * h * .0015, wl + h * (.005 + t * .034)),
          width: h * (.006 + .006 * t),
          height: math.max(.9, h * .0022),
        ),
        lamp,
      );
    }
    // Rain rings open and fade on the water.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, h * .0012);
    for (var i = 0; i < 12; i++) {
      final cycle = clock / 1.5 + Sketch.hash(i + 5600) * 9;
      final k = cycle.floor(), t = cycle - k;
      final near = math.pow(Sketch.hash(i * 31 + k * 7 + 5700), 1.5).toDouble();
      final at = Offset(
        span * Sketch.hash(i * 17 + k * 13 + 5800),
        wl + h * (.008 + .085 * near),
      );
      final r = h * (.0035 + .011 * t) * (1 + near * 1.2);
      final a = (t < .1 ? t * 10 : 1.0) * math.pow(1 - t, 1.6) * .5;
      ring.color = Sketch.fade(const Color(0xffdcd6f7), a);
      c.drawOval(Rect.fromCenter(center: at, width: r * 2, height: r * .7), ring);
      if (t > .3) {
        c.drawOval(Rect.fromCenter(center: at, width: r * 1.1, height: r * .38), ring);
      }
    }
    if (fading) c.restore();
    c.restore();
  }

  static final _riverSheen = <Size, Paint>{};

  /// Screen-space light on the water: the city's glow at the far shore and the
  /// moon's broken path.
  void _riverReflect(Canvas c, SceneFrame f, double presence) {
    final h = f.h, wl = _riverWL * h;
    var sheen = _riverSheen[f.size];
    if (sheen == null) {
      if (_riverSheen.length > 3) _riverSheen.remove(_riverSheen.keys.first);
      sheen = _riverSheen[f.size] = Paint()
        ..shader = Gradient.linear(Offset(0, wl), Offset(0, wl + h * .09), [
          const Color(0x26e8a0b4),
          const Color(0x00e8a0b4),
        ]);
    }
    final glow = presence >= .995
        ? sheen
        : (Paint()
            ..shader = Gradient.linear(Offset(0, wl), Offset(0, wl + h * .09), [
              Color.fromRGBO(232, 160, 180, .15 * presence),
              const Color(0x00e8a0b4),
            ]));
    c.drawRect(Rect.fromLTRB(0, wl, f.w, wl + h * .09), glow);
    // The moon's path: dashes that widen, dim and wander away from the far shore.
    final glint = Paint();
    final x0 = f.w * light.at.dx;
    for (var i = 0; i < 16; i++) {
      final t = i / 15;
      final j = Sketch.hash(i * 7 + 5900);
      final on = .5 + .5 * math.sin(f.clock * 1.6 + i * 2.3);
      final len = h * (.007 + .03 * t) * (.55 + .9 * j);
      final dx = (j - .5) * h * (.008 + .03 * t) + math.sin(f.clock * .8 + i * 1.7) * h * (.003 + .01 * t);
      glint.color = Sketch.fade(const Color(0xfff6f1e2), (.62 - .38 * t) * (.35 + .65 * on) * presence);
      c.drawRect(
        Rect.fromCenter(
          center: Offset(x0 + dx, wl + h * (.004 + t * .098)),
          width: len * 2,
          height: math.max(.9, h * (.0022 + .0012 * t)),
        ),
        glint,
      );
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    _nightStars(c, f, presence);
    _nightMoon(c, f, presence);
    _nightClouds(c, f, presence);
    _nightRain(c, f, presence);
    _nightBeams(c, f, presence);
    _nightPlane(c, f, presence);
  }

  /// A few stars survive the city glow, only in the high, clear sky.
  void _nightStars(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final star = Paint();
    for (var i = 0; i < 12; i++) {
      final twinkle = .55 + .45 * math.sin(f.clock * 2 + i * 1.9);
      star.color = Sketch.fade(
        const Color(0xfffff4e0),
        .5 * twinkle * presence,
      );
      c.drawCircle(
        Offset(w * Sketch.hash(i + 600), h * .26 * Sketch.hash(i + 700)),
        h * (.0016 + .0018 * Sketch.hash(i + 800)),
        star,
      );
    }
  }

  /// The light the compositor is painting right now: New York's own moon
  /// while holding, blended with its neighbour's light during a crossing.
  static SkyLight _nightLight(SceneFrame f) {
    final blend = f.blend;
    final a = RegionScene.of(blend.from).light;
    if (!blend.crossing) return a;
    return SkyLight.lerp(a, RegionScene.of(blend.to).light, blend.stage(0, 1));
  }

  // Moon paints live in the moon's own unit space (radius 1, y down).
  static final _nightDisc = Paint()
    ..shader = Gradient.radial(
      const Offset(-.2, -.24),
      1.42,
      const [Color(0xfffffaee), Color(0xfff7f2e3), Color(0xffd6d3dd)],
      const [0, .6, 1],
    );

  /// Bloom around the limb (it also buries the compositor's hard glow ring),
  /// then a faint ring like the halo a moon wears behind thin rain cloud.
  /// Unit radius = 3.6 moon radii.
  static final _nightAureole = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [
        Color(0xffd6daf8),
        Color(0xffd6daf8),
        Color(0xf2d2d7fb),
        Color(0x73d0d6ff),
        Color(0x33c9d0ff),
        Color(0x14c9d0ff),
        Color(0x1cffd9cf),
        Color(0x17cfd9ff),
        Color(0x08cfd9ff),
        Color(0x00cfd9ff),
      ],
      const [0, .25, .33, .4, .5, .6, .667, .764, .889, 1],
    );

  static final _nightVeil = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0x66565c8c), Color(0x38565c8c), Color(0x00565c8c)],
      const [0, .55, 1],
    );

  static final _nightVeilEdge = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0x60eeeafa), Color(0x28eeeafa), Color(0x00eeeafa)],
      const [0, .5, 1],
    );

  /// An organic mare: an ellipse with a wobbling radius, smoothed through
  /// the midpoints of its corners.
  static Path _nightBlob(double cx, double cy, double rx, double ry, int seed) {
    const n = 10;
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = i / n * math.pi * 2;
      final k = 1 + (Sketch.hash(seed * 29 + i) - .5) * .12;
      pts.add(Offset(cx + math.cos(a) * rx * k, cy + math.sin(a) * ry * k));
    }
    Offset mid(int i) => Offset.lerp(pts[i % n], pts[(i + 1) % n], .5)!;
    final path = Path()..moveTo(mid(0).dx, mid(0).dy);
    for (var i = 1; i <= n; i++) {
      final p = pts[i % n], m = mid(i);
      path.quadraticBezierTo(p.dx, p.dy, m.dx, m.dy);
    }
    return path..close();
  }

  static Path _nightUnion(List<(double, double, double, double)> blobs) {
    var path = Path();
    for (var i = 0; i < blobs.length; i++) {
      final (x, y, rx, ry) = blobs[i];
      path = Path.combine(
        PathOperation.union,
        path,
        _nightBlob(x, y, rx, ry, i + 3),
      );
    }
    return path;
  }

  /// The near side of the moon: Imbrium, Serenitatis, Tranquillitatis,
  /// Crisium, Fecunditatis, Procellarum, Nubium and Humorum.
  static final _nightMaria = _nightUnion(const [
    (-.27, -.3, .36, .31),
    (.15, -.33, .21, .2),
    (.31, -.02, .31, .23),
    (.03, -.02, .19, .15),
    (.69, -.2, .11, .09),
    (.6, .26, .17, .12),
    (.36, .3, .1, .09),
    (-.05, -.74, .36, .06),
    (-.6, .1, .27, .46),
    (-.32, .2, .2, .16),
    (-.22, .52, .24, .14),
    (-.52, .5, .12, .11),
  ]);

  static final _nightSoftDark = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0x385f6488), Color(0x1c5f6488), Color(0x005f6488)],
      const [0, .6, 1],
    );

  void _nightMoon(Canvas c, SceneFrame f, double presence) {
    final l = _nightLight(f);
    final weight = l.moon * l.moon * presence;
    if (weight <= .02) return;
    final at = Offset(l.at.dx * f.w, l.at.dy * f.h);
    final r = l.radius * f.h;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, weight);
    _nightAureole.color = paint.color;
    _nightDisc.color = paint.color;
    c.save();
    c.scale(3.6);
    c.drawCircle(Offset.zero, 1, _nightAureole);
    c.restore();
    c.drawCircle(Offset.zero, 1, _nightDisc);
    // Maria, a little deeper at their cores.
    c.drawPath(
      _nightMaria,
      paint..color = Sketch.fade(const Color(0xff8c90b0), .34 * weight),
    );
    _nightSoftDark.color = paint.color = Color.fromRGBO(255, 255, 255, weight);
    for (final (x, y, rx, ry) in const [
      (-.3, -.32, .3, .26),
      (.14, -.32, .17, .16),
      (.32, -.02, .28, .19),
      (-.62, .06, .2, .38),
      (-.22, .52, .2, .11),
    ]) {
      c.save();
      c.translate(x, y);
      c.scale(rx, ry);
      c.drawCircle(Offset.zero, 1, _nightSoftDark);
      c.restore();
    }
    // Craters: soft dark floors with a lit rim.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .022
      ..color = Sketch.fade(const Color(0xffffffff), .34 * weight);
    for (final (x, y, s) in const [
      (.04, .5, .06),
      (.62, .06, .04),
      (.16, .66, .04),
      (.5, -.52, .04),
      (-.1, -.6, .05),
      (.74, .34, .035),
      (.28, .5, .03),
    ]) {
      paint.color = Sketch.fade(const Color(0xff7e82a4), .2 * weight);
      c.drawCircle(Offset(x, y), s, paint);
      c.drawCircle(Offset(x, y), s, ring);
    }
    // Ray systems: bright streaks that never leave the disc.
    final ray = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .03
      ..color = Sketch.fade(const Color(0xffffffff), .42 * weight);
    void rays(Offset from, int n, double reach, double seed) {
      for (var i = 0; i < n; i++) {
        final a = i / n * math.pi * 2 + Sketch.hash(i + seed.round()) * .5;
        final dir = Offset(math.cos(a), math.sin(a));
        final b = from.dx * dir.dx + from.dy * dir.dy;
        final limit = -b + math.sqrt(b * b - (from.distanceSquared - .9025));
        final len = math.min(limit, reach * (.3 + .7 * Sketch.hash(i + 31)));
        c.drawLine(from + dir * .07, from + dir * math.max(.1, len), ray);
      }
    }

    rays(const Offset(-.08, .72), 11, .7, 30);
    rays(const Offset(-.37, .02), 6, .2, 50);
    for (final (x, y, s, a) in const [
      (-.08, .72, .05, .95),
      (-.37, .02, .03, .75),
      (-.55, -.2, .026, .7),
      (-.63, -.02, .022, .6),
    ]) {
      paint.color = Sketch.fade(const Color(0xffffffff), a * weight);
      c.drawCircle(Offset(x, y), s, paint);
    }
    c.restore();
    // Thin rain cloud slides slowly across the face; its lining catches
    // the moonlight.
    final veil = Color.fromRGBO(255, 255, 255, weight);
    _nightVeil.color = veil;
    _nightVeilEdge.color = veil;
    for (var i = 0; i < 2; i++) {
      final drift = math.sin(f.clock * (.05 + .014 * i) + i * 2.6 + .4);
      final centre =
          at +
          Offset(
            (drift * 1.1 + i * .3) * r,
            (.3 + i * .5 + .1 * math.sin(f.clock * .04 + i)) * r,
          );
      final half = Offset(r * (2.3 - i * .5), r * (.26 - i * .05));
      c.save();
      c.translate(centre.dx, centre.dy);
      c.rotate(-.04 + i * .05);
      c.save();
      c.scale(half.dx, half.dy);
      c.drawCircle(Offset.zero, 1, _nightVeil);
      c.restore();
      c.translate(0, -half.dy * .55);
      c.scale(half.dx * .8, half.dy * .55);
      c.drawCircle(Offset.zero, 1, _nightVeilEdge);
      c.restore();
    }
  }

  // ---- Clouds -------------------------------------------------------------

  static final _nightPictures = <(double, double, int), Picture>{};

  /// Each cloud layer is one cached picture that slides sideways and repeats.
  static Picture _nightPicture(Size size, int layer) {
    final key = (size.width, size.height, layer);
    final cached = _nightPictures[key];
    if (cached != null) return cached;
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    switch (layer) {
      case 0:
        _nightWisps(c, size);
      case 1:
        _nightBank(c, size);
      default:
        _nightDeck(c, size);
    }
    final picture = recorder.endRecording();
    if (_nightPictures.length > 12) {
      _nightPictures.remove(_nightPictures.keys.first)!.dispose();
    }
    return _nightPictures[key] = picture;
  }

  static double _nightSpan(Size size) => size.width * 1.4;

  void _nightClouds(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final w = f.w, h = f.h;
    final span = _nightSpan(f.size);
    final fade = presence < .995;
    if (fade) {
      c.saveLayer(
        Rect.fromLTWH(0, 0, w, h * .7),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
    }
    // Far to near: the low glowing bank crawls, the storm deck moves on,
    // the high wisps run fastest.
    for (final (layer, speed) in const [(1, .0035), (2, .006), (0, .011)]) {
      final shift = f.clock * speed * h % span;
      c.save();
      c.translate(-shift, 0);
      c.drawPicture(_nightPicture(f.size, layer));
      c.translate(span, 0);
      c.drawPicture(_nightPicture(f.size, layer));
      c.restore();
    }
    if (fade) c.restore();
  }

  /// The sky gradient the compositor paints, at a height fraction.
  static Color _nightSkyAt(double y) {
    final p = WorldRegion.newYork.palette;
    const horizon = .66;
    final mid = Sketch.mix(p.top, p.horizon, .42);
    final end = Sketch.mix(p.horizon, p.haze, .7);
    if (y <= horizon * .52) return Sketch.mix(p.top, mid, y / (horizon * .52));
    if (y <= horizon) {
      return Sketch.mix(mid, p.horizon, (y - horizon * .52) / (horizon * .48));
    }
    return Sketch.mix(
      p.horizon,
      end,
      ((y - horizon) / (1 - horizon)).clamp(0.0, 1.0),
    );
  }

  /// One storm cloud: a flat base glowing with city light under a crown of
  /// puffs that catch the moon on one side and sink into shadow on the other.
  /// [pitch] is the puff spacing in cloud heights; [detail] adds crown bumps
  /// and per-puff volume, [shafts] lets rain hang from the base.
  static void _nightCloud(
    Canvas c,
    double h,
    Offset base,
    double width,
    double height,
    int seed, {
    required Offset moon,
    double glow = .7,
    double alpha = .86,
    double pitch = .5,
    double flat = 1,
    bool detail = true,
    int shafts = 0,
  }) {
    final n = (width / (height * pitch)).round().clamp(5, 15);
    // The crown peaks somewhere off-centre, so no two clouds match.
    final peak = .3 + .4 * Sketch.hash(seed * 3);
    final skew = math.log(.5) / math.log(peak);
    final puffs = <(Offset, double)>[];
    for (var i = 0; i < n; i++) {
      final u = (i + .5) / n;
      final bell = math.sin(math.pi * math.pow(u, skew));
      final r =
          height * (.2 + .38 * bell) * (.8 + .32 * Sketch.hash(seed * 31 + i));
      final x =
          base.dx +
          (u - .5) * width * .88 +
          (Sketch.hash(seed * 17 + i) - .5) * width / n * .5;
      puffs.add((
        Offset(x, base.dy - r * (.98 - .1 * Sketch.hash(seed * 7 + i))),
        r,
      ));
    }
    final bumps = <(Offset, double)>[];
    if (detail) {
      for (var i = 0; i < n; i++) {
        final (p, r) = puffs[i];
        for (var k = 0; k < 2; k++) {
          final a = -math.pi * (.12 + .76 * Sketch.hash(seed * 13 + i * 3 + k));
          final br = r * (.3 + .2 * Sketch.hash(seed * 11 + i * 3 + k));
          if (p.dy + math.sin(a) * r > base.dy - height * .3) continue;
          bumps.add((p + Offset(math.cos(a), math.sin(a)) * r * .92, br));
        }
      }
    }
    final top = [
      ...puffs,
      ...bumps,
    ].map((p) => p.$1.dy - p.$2).reduce(math.min);
    final left = base.dx - width * .47, right = base.dx + width * .47;
    final body = Path()
      ..addRRect(
        RRect.fromLTRBR(
          left,
          base.dy - height * .22,
          right,
          base.dy,
          Radius.circular(height * .11),
        ),
      );
    for (final (p, r) in puffs) {
      body.addOval(
        Rect.fromCenter(center: p, width: r * 2 * flat, height: r * 2),
      );
    }
    for (final (p, r) in bumps) {
      body.addOval(Rect.fromCircle(center: p, radius: r));
    }
    final near = (1 - (moon - base).distance / (h * 1.9)).clamp(.1, 1.0);
    final dark = Sketch.mix(
      _nightSkyAt((top + base.dy) / 2 / h),
      const Color(0xff1b2046),
      .55,
    );
    final crown = Sketch.mix(dark, const Color(0xff8f98d0), .36 + .24 * near);
    final warm = Sketch.mix(
      const Color(0xffdc9580),
      const Color(0xff9a68a8),
      Sketch.hash(seed * 5),
    );
    final under = Sketch.mix(dark, warm, .3 + .55 * glow);
    // Rain hangs from the base in slanted, softly lit streaks.
    for (var k = 0; k < shafts; k++) {
      final x0 =
          base.dx +
          (Sketch.hash(seed * 19 + k) - .5) * width * .6 +
          k * width * .02;
      final drop = h * (.1 + .09 * Sketch.hash(seed * 23 + k));
      final tint = Sketch.mix(warm, const Color(0xffb9b4dc), .6);
      for (var j = 0; j < 4; j++) {
        final sx =
            x0 +
            j * height * .07 +
            Sketch.hash(seed * 29 + k * 4 + j) * height * .05;
        final len = drop * (.6 + .4 * Sketch.hash(seed * 31 + k * 4 + j));
        final from = Offset(sx, base.dy - height * .1);
        final to = Offset(sx - len * .2, base.dy - height * .1 + len);
        c.drawLine(
          from,
          to,
          Paint()
            ..strokeWidth = math.max(.8, h * .0035)
            ..strokeCap = StrokeCap.round
            ..shader = Gradient.linear(from, to, [
              Sketch.fade(tint, .26),
              Sketch.fade(tint, 0),
            ]),
        );
      }
    }
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, base.dy),
          [
            Sketch.fade(crown, alpha),
            Sketch.fade(dark, alpha),
            Sketch.fade(dark, alpha),
            Sketch.fade(under, alpha),
          ],
          const [0, .42, .68, 1],
        ),
    );
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, height * .02);
    final glowRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = height * .1;
    final shapes = [
      for (final (p, r) in puffs) (p, r, flat),
      for (final (p, r) in bumps) (p, r, 1.0),
    ];
    void edge(Offset p, double r, double fx, Offset dir, double span) {
      final tip = p + Offset(dir.dx * r * fx, dir.dy * r);
      final exposed = !shapes.any((q) {
        final dx = (tip.dx - q.$1.dx) / (q.$2 * q.$3);
        final dy = (tip.dy - q.$1.dy) / q.$2;
        return q.$1 != p && dx * dx + dy * dy < .94;
      });
      if (detail && exposed && tip.dy < base.dy - height * .3) {
        final oval = Rect.fromCenter(
          center: p,
          width: r * 1.97 * fx,
          height: r * 1.97,
        );
        final from = math.atan2(dir.dy * fx, dir.dx) - span / 2;
        c.drawArc(
          oval,
          from,
          span,
          false,
          glowRim..color = Sketch.fade(const Color(0xffc4ccff), .12 * near),
        );
        c.drawArc(
          oval,
          from + span * .1,
          span * .8,
          false,
          rim..color = Sketch.fade(const Color(0xffdde2ff), .42 * near),
        );
      }
    }

    for (final (p, r) in puffs) {
      final d = moon - p;
      final dir = d / d.distance;
      if (detail) {
        final shadeAt = p - dir * r * .25 + Offset(0, r * .15);
        c.drawCircle(
          shadeAt,
          r * .8,
          Paint()
            ..shader = Gradient.radial(shadeAt, r * .8, [
              Sketch.fade(const Color(0xff141838), .3),
              Sketch.fade(const Color(0xff141838), 0),
            ]),
        );
        final lightAt = p + dir * r * .32;
        c.drawCircle(
          lightAt,
          r * .8,
          Paint()
            ..shader = Gradient.radial(lightAt, r * .8, [
              Sketch.fade(const Color(0xffb8c0f0), .4 * near),
              Sketch.fade(const Color(0xffb8c0f0), 0),
            ]),
        );
      }
      edge(p, r, flat, dir, 1.7);
    }
    for (final (p, r) in bumps) {
      final d = moon - p;
      edge(p, r, 1, d / d.distance, 1.5);
    }
    // Warm city light pooled against the flat base.
    c.save();
    c.clipRect(
      Rect.fromLTRB(left - width * .1, top, right + width * .1, base.dy),
    );
    c.translate(base.dx, base.dy);
    c.scale(width * .5, height * .55);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = Gradient.radial(Offset.zero, 1, [
          Sketch.fade(warm, .62 * glow),
          Sketch.fade(warm, 0),
        ]),
    );
    c.restore();
    // Ragged scud hangs just under the base.
    if (detail) {
      for (var k = 0; k < 3; k++) {
        final sx = base.dx + (Sketch.hash(seed * 37 + k) - .5) * width * .8;
        Sketch.mist(
          c,
          Rect.fromCenter(
            center: Offset(sx, base.dy + height * (.02 + .08 * k / 2)),
            width: width * (.16 + .1 * Sketch.hash(seed * 41 + k)),
            height: height * .16,
          ),
          warm,
          .26,
        );
      }
    }
  }

  /// High, thin cloud streaks the moon shines through.
  static void _nightWisps(Canvas c, Size size) {
    final h = size.height, span = _nightSpan(size);
    const n = 8;
    final margin = h * .34;
    for (var i = 0; i < n; i++) {
      final x =
          margin +
          (span - margin * 2) * (i + .3 + .4 * Sketch.hash(i + 1010)) / n;
      final y = h * (.04 + .17 * Sketch.hash(i + 1020));
      final len = h * (.55 + .5 * Sketch.hash(i + 1030));
      c.save();
      c.translate(x, y);
      c.rotate((Sketch.hash(i + 1040) - .5) * .12);
      for (var k = 0; k < 4; k++) {
        final sz = len * (.62 - k * .1);
        Sketch.mist(
          c,
          Rect.fromCenter(
            center: Offset(
              (k - 1.5) * len * .2,
              (Sketch.hash(i * 4 + k + 1050) - .5) * len * .06,
            ),
            width: sz,
            height: sz * .17,
          ),
          const Color(0xffb7b8e6),
          .15,
        );
      }
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset.zero,
          width: len * .9,
          height: len * .04,
        ),
        const Color(0xffdcdcf6),
        .16,
      );
      c.restore();
    }
  }

  /// The low bank glowing over the city: broad, flat storm cloud lit from below.
  static void _nightBank(Canvas c, Size size) {
    final h = size.height, span = _nightSpan(size);
    const n = 9;
    final margin = h * .45;
    final moon = Offset(size.width * .83, h * .15);
    for (var i = 0; i < n; i++) {
      final x =
          margin +
          (span - margin * 2) * (i + .3 + .4 * Sketch.hash(i + 1110)) / n;
      _nightCloud(
        c,
        h,
        Offset(x, h * (.5 + .05 * Sketch.hash(i + 1120))),
        h * (.7 + .6 * Sketch.hash(i + 1130)),
        h * (.06 + .04 * Sketch.hash(i + 1140)),
        i + 40,
        moon: moon,
        glow: .95,
        alpha: .74,
        pitch: 1.1,
        flat: 2.4,
        detail: false,
      );
    }
    // City glow diffusing into long streaks of haze along the skyline.
    for (var i = 0; i < 7; i++) {
      final x =
          margin +
          (span - margin * 2) * (i + .5 + .3 * Sketch.hash(i + 1150)) / 7;
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x, h * (.5 + .04 * Sketch.hash(i + 1160))),
          width: h * (.8 + .5 * Sketch.hash(i + 1170)),
          height: h * .07,
        ),
        const Color(0xffe0a090),
        .22,
      );
    }
  }

  /// The storm deck: heavy cumulus with glowing flat bases.
  static void _nightDeck(Canvas c, Size size) {
    final h = size.height, span = _nightSpan(size);
    const n = 7;
    final margin = h * .4;
    final moon = Offset(size.width * .83, h * .15);
    for (var i = 0; i < n; i++) {
      final x =
          margin +
          (span - margin * 2) * (i + .3 + .4 * Sketch.hash(i + 1210)) / n;
      final base = Offset(x, h * (.36 + .07 * Sketch.hash(i + 1220)));
      final height = math.min(
        h * (.12 + .07 * Sketch.hash(i + 1230)),
        (base.dy - h * .2) / 1.2,
      );
      _nightCloud(
        c,
        h,
        base,
        h * (.5 + .3 * Sketch.hash(i + 1240)),
        height,
        i + 20,
        moon: moon,
        glow: .6,
        shafts: i.isEven ? 3 : 1,
      );
    }
  }

  // ---- Rain, searchlights, aircraft ---------------------------------------

  /// Two fine layers of far rain behind the skyline, under the streaks the
  /// weather paints in front.
  void _nightRain(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final h = f.h;
    final margin = h * .12;
    final spanX = f.w + margin * 2, spanY = h * .8 + margin * 2;
    final travel = f.reducedMotion ? 0.0 : f.distance * h;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var layer = 0; layer < 2; layer++) {
      final far = layer == 0;
      final pts = <Offset>[];
      for (var i = 0; i < (far ? 46 : 26); i++) {
        final r1 = Sketch.hash(i * 3 + 900 + layer * 100);
        final r2 = Sketch.hash(i * 3 + 901 + layer * 100);
        final z = Sketch.hash(i * 3 + 902 + layer * 100);
        final fall = h * (far ? .8 : 1.1) * (.85 + .3 * z);
        final y = (r2 * spanY + f.clock * fall) % spanY - margin;
        final drift =
            f.clock * h * (far ? .12 : .17) + travel * (far ? .08 : .14);
        final x = (r1 * spanX - drift) % spanX - margin;
        final len = h * (far ? .022 : .034) * (.7 + .6 * z);
        pts
          ..add(Offset(x, y))
          ..add(Offset(x - len * .2, y + len));
      }
      c.drawPoints(
        PointMode.lines,
        pts,
        paint
          ..strokeWidth = far ? .7 : .9
          ..color = Sketch.fade(
            const Color(0xffc9d6f2),
            (far ? .13 : .17) * presence,
          ),
      );
    }
  }

  static final _nightBeamOuter = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, -1),
      const [Color(0x38f5ecd2), Color(0x1cf5ecd2), Color(0x00f5ecd2)],
      const [0, .55, 1],
    );
  static final _nightBeamCore = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, -1),
      const [Color(0x40f8f1dc), Color(0x22f8f1dc), Color(0x00f8f1dc)],
      const [0, .6, 1],
    );
  static final _nightBeamSpot = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0x50fff3d9), Color(0x26fff3d9), Color(0x00fff3d9)],
      const [0, .5, 1],
    );
  static final _nightBeamShapes = (
    Sketch.poly(const [-.006, 0, -.04, -1, .04, -1, .006, 0]),
    Sketch.poly(const [-.003, 0, -.02, -1, .02, -1, .003, 0]),
  );

  /// Two premiere searchlights sweep slowly behind the skyline and end in
  /// soft pools on the underside of the cloud deck.
  void _nightBeams(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final w = f.w, h = f.h;
    final fade = Color.fromRGBO(255, 255, 255, presence);
    _nightBeamOuter.color = fade;
    _nightBeamCore.color = fade;
    _nightBeamSpot.color = fade;
    for (final (fx, speed, phase) in const [(.3, .23, 0.0), (.66, .19, 2.2)]) {
      final base = Offset(w * fx, h * .72);
      final a = math.sin(f.clock * speed + phase) * .42;
      final ceiling = h * (.33 + .02 * math.sin(f.clock * .11 + phase));
      final reach = (base.dy - ceiling) / math.cos(a);
      c.save();
      c.translate(base.dx, base.dy);
      c.rotate(a);
      c.save();
      c.scale(h, reach);
      c.drawPath(_nightBeamShapes.$1, _nightBeamOuter);
      c.drawPath(_nightBeamShapes.$2, _nightBeamCore);
      c.restore();
      c.translate(0, -reach);
      c.rotate(-a);
      c.scale(h * .13, h * .03);
      c.drawCircle(Offset.zero, 1, _nightBeamSpot);
      c.restore();
    }
  }

  /// An airliner high overhead, swept wings seen from below: red and green
  /// wingtip lights, a white tail light, a slow red beacon and white strobes.
  void _nightPlane(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final span = w + h * .6;
    final x = (w * .1 + f.clock * h * .028) % span - h * .3;
    final p = Offset(x, h * (.085 - .02 * x / w));
    final beacon = f.clock % 1.4 < .14 ? 1.0 : 0.0;
    final t = f.clock % 1.9;
    final strobe = (t < .06 || (t - .25).abs() < .06) ? 1.0 : 0.0;
    final paint = Paint()..strokeCap = StrokeCap.round;
    // A faint airframe: fuselage and swept wings.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, h * .0016)
      ..color = Sketch.fade(const Color(0xffcfd0f0), .2 * presence);
    c.drawPath(
      Path()
        ..moveTo(p.dx - h * .036, p.dy)
        ..lineTo(p.dx + h * .016, p.dy)
        ..moveTo(p.dx - h * .011, p.dy - h * .011)
        ..lineTo(p.dx + h * .003, p.dy)
        ..lineTo(p.dx - h * .011, p.dy + h * .011),
      paint,
    );
    paint.style = PaintingStyle.fill;
    void light(Offset at, Color color, double size, double alpha) {
      if (alpha <= 0) return;
      paint.color = Sketch.fade(color, .1 * alpha * presence);
      c.drawCircle(at, size * 2.6, paint);
      paint.color = Sketch.fade(color, .95 * alpha * presence);
      c.drawCircle(at, size, paint);
    }

    light(
      p + Offset(-h * .011, -h * .011),
      const Color(0xffff5a5a),
      h * .002,
      1,
    );
    light(
      p + Offset(-h * .011, h * .011),
      const Color(0xff6dff9a),
      h * .002,
      1,
    );
    light(p + Offset(-h * .036, 0), const Color(0xfff2f0ff), h * .0018, 1);
    light(p + Offset(-h * .012, 0), const Color(0xffff4a4a), h * .0028, beacon);
    light(
      p + Offset(-h * .011, -h * .011),
      const Color(0xffffffff),
      h * .003,
      strobe,
    );
    light(
      p + Offset(-h * .011, h * .011),
      const Color(0xffffffff),
      h * .003,
      strobe,
    );
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  /// The night sky exactly as the compositor paints it, at height [y] in
  /// viewport heights. Distant towers borrow it so they melt into the glow.
  static Color _skylineSky(double y) {
    final p = WorldRegion.newYork.palette;
    const horizon = .66;
    final mid = Sketch.mix(p.top, p.horizon, .42);
    final low = Sketch.mix(p.horizon, p.haze, .7);
    if (y <= horizon * .52) {
      return Sketch.mix(p.top, mid, y / (horizon * .52));
    }
    if (y <= horizon) {
      return Sketch.mix(mid, p.horizon, (y - horizon * .52) / (horizon * .48));
    }
    return Sketch.mix(p.horizon, low, ((y - horizon) / (1 - horizon)).clamp(0.0, 1.0));
  }

  /// A tower colour that follows the sky's own gradient, [k] of the way from
  /// the sky to [tone]: the farther the layer, the smaller [k].
  static Paint _skylineTone(double h, Color tone, double k) {
    const ys = [.2, .35, .5, .62, .74];
    return Paint()
      ..shader = Gradient.linear(
        Offset(0, h * .2),
        Offset(0, h * .74),
        [for (final y in ys) Sketch.mix(_skylineSky(y), tone, k)],
        [for (final y in ys) (y - .2) / .54],
      );
  }

  /// A veil of city haze that thickens toward the ground, between layers.
  static void _skylineFog(Canvas c, double span, double h, double alpha) {
    final sky = _skylineSky(.68);
    c.drawRect(
      Rect.fromLTRB(-h * .1, h * .3, span + h * .1, h * .74),
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .3), Offset(0, h * .74), [
          Sketch.fade(sky, 0),
          Sketch.fade(sky, alpha),
        ]),
    );
  }

  /// Midtown's front row across the visible width: (x as a fraction of the
  /// viewport width, half width, roof height, crown, mast height), the last
  /// three in viewport heights. Crowns: 0 flat, 1 setback, 2 ziggurat,
  /// 3 pyramid, 4 mansard, 5 needle, 6 slanted, 7 lantern.
  static const _skylineCast = [
    (.018, .034, .59, 0, .0),
    (.062, .028, .54, 1, .0),
    (.105, .038, .585, 4, .0),
    (.148, .03, .495, 2, .0),
    (.19, .036, .575, 0, .04),
    (.232, .028, .535, 6, .0),
    (.274, .034, .505, 1, .0),
    (.317, .03, .56, 3, .0),
    (.412, .03, .57, 0, .0),
    (.448, .034, .5, 2, .0),
    (.49, .028, .56, 7, .0),
    (.53, .036, .55, 0, .0),
    (.572, .03, .57, 4, .0),
    (.618, .034, .51, 1, .0),
    (.668, .032, .54, 0, .0),
    (.71, .04, .49, 2, .0),
    (.81, .03, .585, 6, .0),
    (.86, .034, .5, 1, .045),
    (.905, .03, .555, 0, .0),
    (.955, .022, .385, 5, .03),
    (.99, .036, .56, 4, .0),
  ];
  static const _skylineEmpireX = .36, _skylineWtcX = .17;

  /// The Chrysler Building stands to the right of the bridge's far tower (at
  /// w * .24 + 1.15 h). The mid band drifts left faster than this one, so the
  /// bridge slides away from it rather than across it: from 6 s before a hold
  /// to its end the tower moves from .07 h right of the Chrysler's centre to
  /// .18 h left of it, so it stands 1.35 h from the bridge's first tower (kept
  /// inside a narrow screen) to leave a clear gap all the way.
  static double _skylineChrysler(double w, double h) => math.min(w * .24 + h * 1.35, w * .94);

  /// Whether a front-row tower would stand in the landmarks' way.
  static bool _skylineCrowded(double w, double h, double fx, double hw) =>
      (w * fx - w * _skylineEmpireX).abs() < h * .085 + hw * h || (w * fx - _skylineChrysler(w, h)).abs() < h * .075 + hw * h;

  /// How far a crown rises above its roof line, in viewport heights.
  static double _skylineRise(int crown, double hw) => switch (crown) {
    1 => .085,
    2 => .092,
    3 => hw * 1.35,
    4 => hw * .5,
    5 => .075,
    6 => hw * 1.1,
    7 => .056 + hw * .4,
    _ => 0.0,
  };

  static void _skyline(Canvas c, double w, double h) {
    // The band drifts left through a hold, so it is composed past the edge.
    final span = w + h * .62;
    // The city's glow: warm light banked up against the night.
    c.drawRect(
      Rect.fromLTRB(-h * .1, h * .26, span + h * .1, h * .74),
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .26), Offset(0, h * .74), [
          Sketch.fade(const Color(0xffff9a78), 0),
          Sketch.fade(const Color(0xffff9a78), .2),
          Sketch.fade(const Color(0xffffb48c), .34),
        ], const [0, .72, 1]),
    );
    _skylineFar(c, w, h, span);
    _skylineFog(c, span, h, .3);
    _skylineMiddle(c, w, h, span);
    _skylineFog(c, span, h, .22);
    _skylineFront(c, w, h, span);
  }

  /// The farthest towers: pale, almost sky-coloured, with One World Trade's
  /// tapering shaft and spire standing among them.
  static void _skylineFar(Canvas c, double w, double h, double span) {
    final paints = (
      body: _skylineTone(h, const Color(0xff5b5b93), .36),
      lit: _skylineTone(h, const Color(0xff8583ba), .36),
      edge: Paint()..color = const Color(0x28f0e2ff),
      shade: Paint()..color = const Color(0x14181a44),
    );
    final glass = _skylineGlass();
    const n = 19;
    for (var i = 0; i < n; i++) {
      final crown = const [0, 1, 5, 2, 0, 7, 1, 4][i % 8];
      _skylineBuilding(
        c,
        glass,
        h,
        paints,
        x: span * (i + .25 + .5 * Sketch.hash(i + 40)) / n - h * .06,
        hw: .026 + .024 * Sketch.hash(i + 41),
        top: .4 + .15 * Sketch.hash(i + 42),
        crown: crown,
        seed: 40 + i,
        mast: crown == 5 ? .05 : 0,
        sc: .62,
        dens: .5,
      );
    }
    _skylineObelisk(c, w * _skylineWtcX, h, paints);
    _skylineFlush(c, glass, h, .62, .32);
  }

  /// One World Trade Center: a chamfered glass shaft tapering to a parapet
  /// and a long mast.
  static void _skylineObelisk(
    Canvas c,
    double x,
    double h,
    ({Paint body, Paint lit, Paint edge, Paint shade}) p,
  ) {
    final shaft = [-.03, .74, -.0245, .312, .0245, .312, .03, .74];
    c.drawPath(Sketch.poly(shaft, at: Offset(x, 0), s: h), p.body);
    c.drawPath(
      Sketch.poly([.007, .312, .0245, .312, .03, .74, .007, .74], at: Offset(x, 0), s: h),
      p.lit,
    );
    c.drawRect(Rect.fromLTRB(x - h * .0255, h * .31, x + h * .0255, h * .3145), p.edge);
    // Faceted glass: a few pale seams and lit floors up the shaft.
    final seam = Paint()
      ..color = const Color(0x1cffffff)
      ..strokeWidth = math.max(.6, h * .0014);
    for (final dx in const [-.014, -.004, .015]) {
      c.drawLine(Offset(x + dx * h, h * .32), Offset(x + dx * h * 1.1, h * .7), seam);
    }
    final mast = Paint()
      ..color = const Color(0xffbdbce6)
      ..strokeWidth = math.max(.8, h * .0026);
    c.drawLine(Offset(x, h * .312), Offset(x, h * .243), mast);
  }

  /// The middle distance: a denser, darker row of towers in haze, with dim
  /// windows, rooftop tanks and a few antennas.
  static void _skylineMiddle(Canvas c, double w, double h, double span) {
    final paints = (
      body: _skylineTone(h, const Color(0xff484a80), .6),
      lit: _skylineTone(h, const Color(0xff6b6ca4), .6),
      edge: Paint()..color = const Color(0x2ee0d4ff),
      shade: Paint()..color = const Color(0x1a13153c),
    );
    final glass = _skylineGlass();
    const n = 23;
    for (var i = 0; i < n; i++) {
      final crown = const [0, 4, 1, 0, 2, 6, 0, 7, 1][i % 9];
      _skylineBuilding(
        c,
        glass,
        h,
        paints,
        x: span * (i + .2 + .6 * Sketch.hash(i + 70)) / n - h * .08,
        hw: .024 + .03 * Sketch.hash(i + 71),
        top: .49 + .12 * Sketch.hash(i + 72),
        crown: crown,
        seed: 70 + i,
        mast: i % 7 == 3 && (crown == 0 || crown == 1) ? .035 : 0,
        sc: .78,
        dens: .75,
      );
    }
    _skylineFlush(c, glass, h, .78, .62);
  }

  /// The lit front row: the hero cast, then the Empire State and Chrysler.
  static void _skylineFront(Canvas c, double w, double h, double span) {
    final paints = (
      body: Paint()
        ..shader = Gradient.linear(Offset(0, h * .25), Offset(0, h * .74), const [
          Color(0xff34386c),
          Color(0xff58507f),
        ]),
      lit: Paint()
        ..shader = Gradient.linear(Offset(0, h * .25), Offset(0, h * .74), const [
          Color(0xff575c94),
          Color(0xff86739f),
        ]),
      edge: Paint()..color = const Color(0x5cc8c8f2),
      shade: Paint()..color = const Color(0x260e1030),
    );
    // Halos first: the crowns' light spills onto the towers around them.
    final chrysler = _skylineChrysler(w, h), empire = w * _skylineEmpireX;
    for (final (px, y, r, tint) in [
      (empire, .34, .15, const Color(0xffffe2a0)),
      (chrysler, .385, .13, const Color(0xffffe6b8)),
    ]) {
      final at = Offset(px, h * y);
      c.drawCircle(
        at,
        h * r,
        Paint()
          ..shader = Gradient.radial(
            at,
            h * r,
            [Sketch.fade(tint, .34), Sketch.fade(tint, .11), Sketch.fade(tint, 0)],
            const [0, .38, 1],
          ),
      );
    }
    final glass = _skylineGlass();
    var i = 0;
    for (final (fx, hw, top, crown, mast) in _skylineCast) {
      if (_skylineCrowded(w, h, fx, hw)) {
        i++;
        continue;
      }
      _skylineBuilding(
        c,
        glass,
        h,
        paints,
        x: w * fx,
        hw: hw,
        top: top,
        crown: crown,
        seed: 10 + i++,
        mast: mast,
      );
    }
    // Filler past the right edge, where the drifting band comes from.
    for (var x = w * 1.03 + h * .05; x < span + h * .1; x += h * (.07 + .04 * Sketch.hash(i))) {
      final crown = const [0, 1, 7, 4, 2, 0][i % 6];
      _skylineBuilding(
        c,
        glass,
        h,
        paints,
        x: x,
        hw: .028 + .012 * Sketch.hash(i + 5),
        top: .5 + .09 * Sketch.hash(i + 6),
        crown: crown,
        seed: 10 + i++,
      );
    }
    _skylineFlush(c, glass, h, 1, 1);
    final towers = _skylineGlass();
    _empireState(c, empire, h, paints, towers);
    _chrysler(c, chrysler, h, paints, towers);
    _skylineFlush(c, towers, h, 1, 1);
    // Street glow at the foot of the towers.
    c.drawRect(
      Rect.fromLTRB(-h * .1, h * .6, span + h * .1, h * .74),
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .6), Offset(0, h * .74), [
          Sketch.fade(const Color(0xffffa072), 0),
          Sketch.fade(const Color(0xffffa072), .3),
        ]),
    );
  }

  static List<List<Offset>> _skylineGlass() => [for (var k = 0; k < 4; k++) <Offset>[]];

  /// Lit windows in a tower face: a grid whose panes are warm, pale, TV-blue
  /// or dark, with the odd office floor left on entirely.
  static void _skylineGrid(
    List<List<Offset>> glass,
    double h,
    double left,
    double right,
    double top,
    double bottom,
    int seed, {
    double sc = 1,
    double dens = 1,
  }) {
    if (dens <= 0) return;
    final px = h * .0105 * sc, py = h * .0158 * sc, wh = h * .0082 * sc;
    final cols = ((right - left) / px).floor();
    if (cols < 1) return;
    final x0 = left + (right - left - cols * px) / 2 + px / 2;
    var j = 0;
    for (var y = top + py * .5; y + wh < bottom; y += py, j++) {
      final row = Sketch.hash(seed * 131 + j * 17 + 3);
      final office = row > .9, asleep = row < .2;
      final glow = dens * (.5 + .5 * ((y / h - .35) / .3).clamp(0.0, 1.0));
      for (var i = 0; i < cols; i++) {
        final n = Sketch.hash(seed * 1009 + j * 61 + i * 7 + 11);
        final int kind;
        if (office) {
          kind = n < .5 ? 0 : (n < .82 ? 1 : 3);
        } else if (asleep) {
          kind = n < .05 ? 0 : (n < .8 ? 3 : -1);
        } else if (n < .15 * glow) {
          kind = 0;
        } else if (n < .2 * glow) {
          kind = 1;
        } else if (n < .23 * glow) {
          kind = 2;
        } else {
          kind = n < .62 ? 3 : -1;
        }
        if (kind < 0) continue;
        final x = x0 + i * px;
        glass[kind]
          ..add(Offset(x, y))
          ..add(Offset(x, y + wh));
      }
    }
  }

  /// Paints the batched panes: one draw call per colour, however many panes.
  static void _skylineFlush(Canvas c, List<List<Offset>> glass, double h, double sc, double alpha) {
    const colors = [_window, Color(0xffffeccb), Color(0xff86b6ff), Color(0xff1e2148)];
    const alphas = [.86, .74, .6, .36];
    final paint = Paint()
      ..strokeWidth = h * .0056 * sc
      ..strokeCap = StrokeCap.butt;
    for (var k = 0; k < 4; k++) {
      if (glass[k].isEmpty) continue;
      paint.color = Sketch.fade(colors[k], alphas[k] * alpha);
      c.drawPoints(PointMode.lines, glass[k], paint);
    }
  }

  /// One block of a tower: body, moonlit right plane, shaded left edge and a
  /// cornice (a bright ledge over a band of shadow).
  static void _skylineTier(
    Canvas c,
    Rect r,
    ({Paint body, Paint lit, Paint edge, Paint shade}) p,
    double h, {
    Paint? glow,
  }) {
    c.drawRect(r, p.body);
    c.drawRect(Rect.fromLTRB(r.right - r.width * .22, r.top, r.right, r.bottom), p.lit);
    c.drawRect(Rect.fromLTRB(r.left, r.top, r.left + r.width * .1, r.bottom), p.shade);
    if (glow != null) c.drawRect(r, glow);
    c.drawRect(Rect.fromLTRB(r.left, r.top + h * .0016, r.right, r.top + h * .0056), p.shade);
    c.drawRect(
      Rect.fromLTRB(r.left - h * .0014, r.top - h * .0016, r.right + h * .0014, r.top + h * .0016),
      p.edge,
    );
  }

  /// A generic tower of the skyline: a windowed block under one of the
  /// [crown] styles, an optional mast, rooftop tank, light piers or a
  /// floodlit crown. Sizes are viewport heights; the base sits behind the
  /// ridge.
  static void _skylineBuilding(
    Canvas c,
    List<List<Offset>> glass,
    double h,
    ({Paint body, Paint lit, Paint edge, Paint shade}) p, {
    required double x,
    required double hw,
    required double top,
    required int crown,
    required int seed,
    double mast = 0,
    double sc = 1,
    double dens = 1,
  }) {
    final hp = hw * h, t = top * h, floor = h * .74;
    final pad = h * .0058 * sc;
    final yTop = t - _skylineRise(crown, hw) * h;
    // A floodlit crown warms the top tiers and the parapet below them.
    Paint? flood;
    if (dens > .8 && (crown == 1 || crown == 2 || crown == 7) && seed % 3 == 0) {
      flood = Paint()
        ..shader = Gradient.linear(
          Offset(0, yTop),
          Offset(0, t + h * .03),
          [
            Sketch.fade(const Color(0xffffe0a0), .6),
            Sketch.fade(const Color(0xffffc27a), .22),
            Sketch.fade(const Color(0xffffc27a), 0),
          ],
          const [0, .7, 1],
        );
    }
    final main = Rect.fromLTRB(x - hp, t, x + hp, floor);
    _skylineTier(c, main, p, h, glow: flood);
    // Every so often the block gets a dimming, so neighbours separate.
    if (dens >= .6) {
      c.drawRect(main, Paint()..color = Color.fromRGBO(12, 14, 40, .08 * Sketch.hash(seed + 900)));
      // Brick, concrete and glass take the city's light differently.
      const tints = [Color(0xff8a3a4a), Color(0xff2a6a9a), Color(0xff7a5a2a), Color(0xff5a3a8a)];
      if (seed % 4 != 0) {
        c.drawRect(main, Paint()..color = Sketch.fade(tints[seed % 4], .05 + .07 * Sketch.hash(seed + 910)));
      }
    }
    _skylineGrid(glass, h, main.left + pad, main.right - pad, t, h * .705, seed, sc: sc, dens: dens);
    // Light piers: vertical floodlit ribs up an Art Deco tower, or (on a few
    // glass towers) faint ribs the whole way down.
    if (dens > .8 && seed % 4 == 1 && crown != 2) {
      final ribs = <Offset>[];
      for (var px = main.left + pad * 1.6; px < main.right - pad; px += h * .0189) {
        ribs
          ..add(Offset(px, t + h * .004))
          ..add(Offset(px, h * .705));
      }
      c.drawPoints(
        PointMode.lines,
        ribs,
        Paint()
          ..strokeWidth = math.max(.6, h * .0013)
          ..color = const Color(0x18ecebff),
      );
    }
    if (dens > .8 && (crown == 2 || seed % 5 == 2)) {
      final piers = <Offset>[];
      final pitch = h * .021;
      final n = ((hp * 2 - pad * 2) / pitch).floor();
      for (var i = 0; i < n; i++) {
        final px = x - hp + pad + (hp * 2 - pad * 2 - (n - 1) * pitch) / 2 + i * pitch;
        piers
          ..add(Offset(px, t + h * .006))
          ..add(Offset(px, t + h * .2));
      }
      c.drawPoints(
        PointMode.lines,
        piers,
        Paint()
          ..strokeWidth = math.max(.7, h * .0016)
          ..shader = Gradient.linear(Offset(0, t), Offset(0, t + h * .2), [
            Sketch.fade(const Color(0xffffe9c0), .34),
            Sketch.fade(const Color(0xffffe9c0), 0),
          ]),
      );
    }
    var y = t;
    void stack(double f, double rise) {
      final r = Rect.fromLTRB(x - hp * f, y - rise * h, x + hp * f, y);
      _skylineTier(c, r, p, h, glow: flood);
      _skylineGrid(glass, h, r.left + pad, r.right - pad, r.top, y, seed + 5 + (f * 10).round(), sc: sc, dens: dens * .8);
      y = r.top;
    }

    switch (crown) {
      case 1:
        stack(.7, .05);
        stack(.42, .035);
      case 2:
        stack(.82, .028);
        stack(.62, .03);
        stack(.42, .034);
      case 3:
        // A pyramid roof, its lit face turned to the moon.
        final apex = Offset(x, t - hp * 1.35);
        c.drawPath(
          Path()
            ..moveTo(x - hp * .94, t)
            ..lineTo(apex.dx, apex.dy)
            ..lineTo(x + hp * .94, t)
            ..close(),
          p.body,
        );
        c.drawPath(
          Path()
            ..moveTo(x, t)
            ..lineTo(apex.dx, apex.dy)
            ..lineTo(x + hp * .94, t)
            ..close(),
          p.lit,
        );
        c.drawCircle(apex, math.max(.7, h * .0018), Paint()..color = Sketch.fade(_window, .8 * dens));
      case 4:
        // A mansard roof with a lit dormer or two.
        c.drawPath(
          Path()
            ..moveTo(x - hp * .97, t)
            ..lineTo(x - hp * .62, t - hp * .5)
            ..lineTo(x + hp * .62, t - hp * .5)
            ..lineTo(x + hp * .97, t)
            ..close(),
          p.body,
        );
        c.drawPath(
          Path()
            ..moveTo(x + hp * .2, t - hp * .5)
            ..lineTo(x + hp * .62, t - hp * .5)
            ..lineTo(x + hp * .97, t)
            ..lineTo(x + hp * .2, t)
            ..close(),
          p.lit,
        );
        final dormer = Paint()..color = Sketch.fade(_window, .7 * dens);
        for (final dx in const [-.42, .05]) {
          c.drawRect(Rect.fromLTWH(x + hp * dx, t - hp * .34, h * .0046 * sc, h * .0056 * sc), dormer);
        }
      case 5:
        // A tier and a slim pyramidal spire.
        stack(.6, .03);
        c.drawPath(
          Path()
            ..moveTo(x - hp * .5, y)
            ..lineTo(x, y - h * .045)
            ..lineTo(x + hp * .5, y)
            ..close(),
          p.body,
        );
        c.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x, y - h * .045)
            ..lineTo(x + hp * .5, y)
            ..close(),
          p.lit,
        );
      case 6:
        // A slanted roof, its edge catching the moon.
        c.drawPath(
          Path()
            ..moveTo(x - hp, t)
            ..lineTo(x + hp, t - hp * 1.1)
            ..lineTo(x + hp, t)
            ..close(),
          p.body,
        );
        c.drawLine(
          Offset(x - hp, t),
          Offset(x + hp, t - hp * 1.1),
          Paint()
            ..color = p.edge.color
            ..strokeWidth = math.max(.6, h * .0016),
        );
      case 7:
        stack(.66, .03);
        stack(.4, .026);
        final dome = Rect.fromCenter(center: Offset(x, y), width: hp * .8, height: hp * .8);
        c.drawArc(dome, math.pi, math.pi, true, p.body);
        c.drawArc(dome, -math.pi / 2, math.pi / 2, true, p.lit);
        if (flood != null) c.drawArc(dome, math.pi, math.pi, true, flood);
      default:
        if (mast <= 0 && seed % 2 == 0) {
          _skylineTank(c, x + hp * (seed.isEven ? .38 : -.34), t, h, sc, dens);
        } else if (mast <= 0) {
          // A rooftop penthouse.
          c.drawRect(Rect.fromLTRB(x - hp * .28, t - h * .012, x + hp * .3, t), p.body);
          c.drawRect(Rect.fromLTRB(x - hp * .28, t - h * .014, x + hp * .3, t - h * .011), p.edge);
        }
    }
    if (mast > 0) {
      final mx = x + hp * .12;
      final line = Paint()
        ..color = Sketch.fade(p.edge.color, 1.8)
        ..strokeWidth = math.max(.7, h * .0022 * sc);
      c.drawLine(Offset(mx, yTop), Offset(mx, yTop - mast * h), line);
      c.drawLine(Offset(mx - h * .004, yTop - mast * h * .55), Offset(mx + h * .004, yTop - mast * h * .55), line);
    }
  }

  /// The classic wooden water tank on stilts, in silhouette on a roof.
  static void _skylineTank(Canvas c, double x, double roof, double h, double sc, double dens) {
    final s = h * .0105 * sc;
    final dark = Paint()..color = Sketch.mix(_skylineSky(roof / h), const Color(0xff24264c), .72 + .2 * dens);
    final legs = Paint()
      ..color = dark.color
      ..strokeWidth = math.max(.6, s * .16);
    for (final dx in const [-.7, -.2, .2, .7]) {
      c.drawLine(Offset(x + dx * s, roof), Offset(x + dx * s * .9, roof - s * 1.0), legs);
    }
    final drum = Rect.fromLTRB(x - s, roof - s * 2.5, x + s, roof - s);
    c.drawRect(drum, dark);
    c.drawPath(
      Sketch.poly([-1.12, -2.5, 0, -3.35, 1.12, -2.5], at: Offset(x, roof), s: s),
      dark,
    );
    c.drawRect(
      Rect.fromLTRB(drum.right - s * .3, drum.top, drum.right, drum.bottom),
      Paint()..color = Color.fromRGBO(190, 190, 240, .16 * dens),
    );
  }

  /// The Empire State Building: stepped setbacks, a floodlit crown, the
  /// mooring mast and antenna, and its long ranks of lit windows.
  static void _empireState(
    Canvas c,
    double x,
    double h,
    ({Paint body, Paint lit, Paint edge, Paint shade}) p,
    List<List<Offset>> glass,
  ) {
    // Half width and roof height of each setback, from the wide base up.
    const tiers = [
      (.08, .625),
      (.056, .555),
      (.049, .455),
      (.041, .4),
      (.034, .372),
      (.028, .348),
      (.021, .327),
      (.015, .31),
      (.01, .298),
    ];
    final flood = Paint()
      ..shader = Gradient.linear(Offset(0, h * .29), Offset(0, h * .405), [
        Sketch.fade(const Color(0xffffefc4), .96),
        Sketch.fade(const Color(0xffffcf80), .4),
      ]);
    final warmShade = Paint()..color = const Color(0x34b0743e);
    final flute = Paint()
      ..color = const Color(0x3ca66a3c)
      ..strokeWidth = math.max(.6, h * .0014);
    final ledge = Paint()..color = const Color(0xf2fff0c4);
    final ribs = Paint()
      ..strokeWidth = math.max(.6, h * .0013)
      ..color = const Color(0x1eecebff);
    var bottom = h * .74;
    for (final (hw, top) in tiers) {
      final r = Rect.fromLTRB(x - hw * h, top * h, x + hw * h, bottom);
      final lit = top <= .372;
      _skylineTier(c, r, p, h, glow: lit ? flood : null);
      if (lit) {
        c.drawRect(Rect.fromLTRB(r.left - h * .0014, r.top - h * .0016, r.right + h * .0014, r.top + h * .0008), ledge);
        c.drawRect(Rect.fromLTRB(r.left, r.top, r.left + r.width * .16, r.bottom), warmShade);
        for (final f in const [-.5, 0.0, .5]) {
          final fx = x + hw * h * f;
          c.drawLine(Offset(fx, r.top + h * .006), Offset(fx, r.bottom), flute);
        }
      } else {
        _skylineGrid(
          glass,
          h,
          r.left + h * .0052,
          r.right - h * .0052,
          r.top,
          math.min(bottom, h * .705),
          300 + (top * 100).round(),
          dens: 1.15,
        );
        // Long limestone piers give the shaft its climb.
        if (hw >= .049) {
          final lines = <Offset>[];
          for (var px = r.left + h * .0105; px < r.right - h * .006; px += h * .021) {
            lines
              ..add(Offset(px, r.top + h * .004))
              ..add(Offset(px, math.min(bottom, h * .705)));
          }
          c.drawPoints(PointMode.lines, lines, ribs);
        }
      }
      bottom = r.top;
    }
    // The lantern's dome, the mooring drum and the stepped antenna.
    final dome = Rect.fromCenter(center: Offset(x, h * .298), width: h * .02, height: h * .022);
    c.drawArc(dome, math.pi, math.pi, true, flood);
    c.drawRect(Rect.fromLTRB(x - h * .0052, h * .2735, x + h * .0052, h * .292), flood);
    c.drawPath(
      Sketch.poly(
        const [
          -.003, .2745, -.003, .246, -.0019, .246, -.0019, .222, -.0009, .222,
          -.0006, .196, .0006, .196, .0009, .222, .0019, .222, .0019, .246,
          .003, .246, .003, .2745, //
        ],
        at: Offset(x, 0),
        s: h,
      ),
      Paint()..color = const Color(0xffe4dcf2),
    );
  }

  /// The Chrysler Building: setbacks, a brick shaft with eagle gargoyles and
  /// a crown of seven terraced steel arches set with triangular windows.
  static void _chrysler(
    Canvas c,
    double x,
    double h,
    ({Paint body, Paint lit, Paint edge, Paint shade}) p,
    List<List<Offset>> glass,
  ) {
    const tiers = [(.06, .63), (.046, .575), (.036, .54), (.031, .448)];
    final ledge = Paint()..color = const Color(0xb8ffe9b4);
    var bottom = h * .74;
    for (final (hw, top) in tiers) {
      final r = Rect.fromLTRB(x - hw * h, top * h, x + hw * h, bottom);
      _skylineTier(c, r, p, h);
      c.drawRect(Rect.fromLTRB(r.left - h * .0014, r.top - h * .0016, r.right + h * .0014, r.top + h * .0006), ledge);
      if (hw < .034) {
        // The shaft is washed by uplights that fade as they climb.
        c.drawRect(
          r,
          Paint()
            ..shader = Gradient.linear(Offset(0, r.top), Offset(0, r.top + h * .09), [
              Sketch.fade(const Color(0xffffe6b8), .3),
              Sketch.fade(const Color(0xffffe6b8), .05),
            ]),
        );
      }
      _skylineGrid(glass, h, r.left + h * .0052, r.right - h * .0052, r.top, math.min(bottom, h * .705), 500 + (top * 100).round(), dens: 1.1);
      bottom = r.top;
    }
    // Pale brick piers and the dark bands of the shaft.
    final pier = Paint()
      ..color = const Color(0x22f2eaff)
      ..strokeWidth = math.max(.6, h * .0014);
    for (final dx in const [-.016, .002, .019]) {
      c.drawLine(Offset(x + dx * h, h * .46), Offset(x + dx * h, h * .535), pier);
    }
    c.drawRect(Rect.fromLTRB(x - h * .0325, h * .447, x + h * .0325, h * .4535), Paint()..color = const Color(0xd9b6b8e8));
    c.drawRect(Rect.fromLTRB(x - h * .031, h * .4535, x + h * .031, h * .4585), Paint()..color = const Color(0x40101238));
    c.drawRect(Rect.fromLTRB(x - h * .036, h * .544, x + h * .036, h * .548), Paint()..color = const Color(0x40101238));
    // The crown, arch over arch, lit like polished steel.
    const steel = Color(0xffa4a6d8), steelLit = Color(0xffeff0ff), steelDark = Color(0xff7b7db2);
    final fill = Paint()..color = steel;
    final litFill = Paint()..color = steelLit;
    final darkFill = Paint()..color = steelDark;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..color = Sketch.fade(steelLit, .8)
      ..strokeWidth = math.max(.6, h * .0015);
    final under = Paint()..color = const Color(0x55262a5c);
    final panes = Path();
    for (var k = 0; k < 7; k++) {
      final r = h * .031 * (1.06 - .13 * k);
      final rh = r * 1.08;
      final yb = h * (.448 - .0158 * k);
      final oval = Rect.fromCenter(center: Offset(x, yb), width: r * 2, height: rh * 2);
      c.drawArc(oval, math.pi, math.pi, true, darkFill);
      c.drawArc(Rect.fromCenter(center: Offset(x, yb), width: r * 1.84, height: rh * 1.84), math.pi, math.pi, true, fill);
      c.drawArc(oval, -math.pi * .5, math.pi * .5, true, litFill..color = Sketch.fade(steelLit, .5));
      c.drawArc(oval, math.pi, math.pi, false, rim);
      c.drawRect(Rect.fromLTRB(x - r, yb - h * .0008, x + r, yb + h * .0016), under);
      // A fan of triangular windows along the band below the next arch.
      final step = h * .0158;
      final n = math.max(2, (5.6 - k * .55).round());
      final ww = math.max(1.1, r * .3 * (1 - k * .05)), hh = math.max(1.6, step * .78);
      for (var j = 0; j < n; j++) {
        final u = (j + .5) / n * 2 - 1;
        final px = x + u * r * .74;
        final py = yb - step * .46;
        final tilt = u * .42;
        final up = Offset(math.sin(tilt), -math.cos(tilt));
        final side = Offset(math.cos(tilt), math.sin(tilt));
        final tip = Offset(px, py) + up * hh * .55;
        final b1 = Offset(px, py) - up * hh * .45 - side * ww / 2;
        final b2 = Offset(px, py) - up * hh * .45 + side * ww / 2;
        panes
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(b2.dx, b2.dy)
          ..lineTo(b1.dx, b1.dy)
          ..close();
      }
    }
    c.drawPath(panes, Paint()..color = Sketch.fade(const Color(0xffffe9b4), .95));
    // The needle spire, its base ringed like a collar.
    c.drawPath(
      Sketch.poly(const [-.0034, .346, -.0009, .272, 0, .262, .0009, .272, .0034, .346], at: Offset(x, 0), s: h),
      Paint()..color = const Color(0xffc8c9ef),
    );
    c.drawLine(
      Offset(x + h * .0007, h * .34),
      Offset(x + h * .0004, h * .266),
      Paint()
        ..color = const Color(0xffffffff)
        ..strokeWidth = math.max(.5, h * .0012),
    );
    // Eagle gargoyles jut from the shaft's corners under the crown.
    for (final s in const [-1.0, 1.0]) {
      c.drawPath(
        Sketch.poly([0, .0045, s * .006, .0, s * .011, -.0035, s * .0148, -.0016, s * .0114, .0006, s * .008, .003, s * .004, .0075, 0, .0098], at: Offset(x + s * h * .031, h * .456), s: h),
        Paint()..color = steel,
      );
    }
  }

  /// Aircraft warning beacons on the tallest masts, breathing slowly. Each
  /// keeps a dim core so the frozen Reduced Motion frame still shows them.
  static void _skylineLive(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h;
    final halo = Paint(), core = Paint();
    void beacon(double x, double y, double phase, double s) {
      final t = .5 + .5 * math.cos((f.clock / 2.4 + phase) * math.pi * 2);
      final on = t * t * (3 - 2 * t);
      halo.color = Sketch.fade(const Color(0xffff5a4e), .07 * on);
      c.drawCircle(Offset(x, y), h * .013 * s, halo);
      halo.color = Sketch.fade(const Color(0xffff5a4e), .13 * on);
      c.drawCircle(Offset(x, y), h * .007 * s, halo);
      core.color = Sketch.fade(const Color(0xffff8b7c), .4 + .5 * on);
      c.drawCircle(Offset(x, y), math.max(.8, h * .0026) * s, core);
    }

    beacon(w * _skylineEmpireX, h * .196, 0, 1.15);
    beacon(_skylineChrysler(w, h), h * .262, .35, 1);
    beacon(w * _skylineWtcX, h * .243, .68, 1);
    for (final (fx, hw, top, crown, mast) in _skylineCast) {
      if (mast <= 0 || _skylineCrowded(w, h, fx, hw)) continue;
      beacon(w * fx + hw * h * .12, h * (top - _skylineRise(crown, hw) - mast), fx * 7, .85);
    }
  }

  // The Brooklyn Bridge. Everything sits on one deck line and one tower line so
  // the parts agree; heights are fractions of the viewport height.
  static const _bridgeDeckY = .655, _bridgeCapY = .462, _bridgeFoot = .78;
  static const _bridgeSide = .02, _bridgeAnchorTop = .606, _bridgeCableIn = .575;
  static const _bridgeSpan = 1.15;

  /// The Brooklyn Bridge: granite towers with twin gothic arches, stone
  /// courses and a cornice, the fan of diagonal stays, the main cables over
  /// their suspenders, a trussed deck with railing lamps, the anchorages and
  /// arched approach viaducts, warehouses on both shores and a low mist.
  /// [x0] is the first tower's x and [w] the viewport width, so the deck can
  /// run on past the drifting right edge.
  static void _bridge(Canvas c, double x0, double h, double w) {
    final xl = -h * .3, xr = w + h * .55;
    final t1 = x0, t2 = x0 + h * _bridgeSpan;
    final a1 = t1 - h * .52, a2 = t2 + h * .52;
    _bridgeMist(c, xl, xr, t1, t2, h, false);
    _bridgeArcade(c, a1 - h * .07, xl, h);
    _bridgeArcade(c, a2 + h * .07, xr, h);
    _bridgeShore(c, xl - h * .3, a1 + h * .16, h, 900);
    _bridgeShore(c, a2 - h * .3, xr, h, 950);
    _bridgeWeb(c, t1, t2, a1, a2, h);
    _bridgeDeck(c, xl, xr, h);
    _bridgeAnchorage(c, a1, h);
    _bridgeAnchorage(c, a2, h);
    _bridgeTower(c, t1, h);
    _bridgeTower(c, t2, h);
    _bridgeCables(c, t1, t2, a1, a2, h);
    _bridgeMist(c, xl, xr, t1, t2, h, true);
  }

  static final _bridgeCableTone = _hazed(const Color(0xffb4b2d8), .1);
  static final _bridgeFlag = [
    Paint()..color = _hazed(const Color(0xffb0566a), .3),
    Paint()..color = _hazed(const Color(0xffd9d5ea), .3),
    Paint()..color = _hazed(const Color(0xff505ea6), .3),
  ];

  /// Low banks of river mist: a thin one behind the piers and a thicker one
  /// that melts the tower feet into the water.
  static void _bridgeMist(
    Canvas c,
    double xl,
    double xr,
    double t1,
    double t2,
    double h,
    bool front,
  ) {
    const tint = Color(0xffbba6cf);
    if (!front) {
      for (var x = xl; x < xr; x += h * .5) {
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(x, h * .738), width: h * .9, height: h * .09),
          tint,
          .14,
        );
      }
      return;
    }
    for (final tx in [t1, t2]) {
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(tx, h * .745), width: h * .46, height: h * .085),
        tint,
        .42,
      );
    }
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset((t1 + t2) / 2, h * .742), width: h * .8, height: h * .07),
      tint,
      .24,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(xr - h * .5, h * .744), width: h * .9, height: h * .08),
      tint,
      .26,
    );
  }

  /// A pointed (equilateral) gothic arch, jambs rising from [baseY] to
  /// [springY], the point 1.73 half-widths higher.
  static Path _bridgeGothic(double cx, double baseY, double hw, double springY) {
    final r = hw * 2;
    return Path()
      ..moveTo(cx - hw, baseY)
      ..lineTo(cx - hw, springY)
      ..arcTo(Rect.fromCircle(center: Offset(cx + hw, springY), radius: r), math.pi, math.pi / 3, false)
      ..arcTo(Rect.fromCircle(center: Offset(cx - hw, springY), radius: r), -math.pi / 3, math.pi / 3, false)
      ..lineTo(cx + hw, baseY)
      ..close();
  }

  /// One granite tower, floodlit from below: a moonlit side face, masonry
  /// courses and joints, a corbelled cornice, twin gothic portals with a
  /// glowing roadway inside, a footing in the water and a flag mast.
  static void _bridgeTower(Canvas c, double tx, double h) {
    const cap = _bridgeCapY, deck = _bridgeDeckY, foot = _bridgeFoot;
    double half(double y) => h * (.052 + (y - cap) * .036);
    double face(double y) => half(y) - h * .0135;
    final top = cap * h, water = h * .76;
    Paint fill(List<Color> colors) => Paint()
      ..shader = Gradient.linear(Offset(0, top), Offset(0, water), colors, const [0, .5, 1]);
    // Front (shade) and side (moonlit) faces with the warm floodlight low down.
    c.drawPath(
      Sketch.poly([
        tx - half(cap), top,
        tx + face(cap), top,
        tx + face(foot), foot * h,
        tx - half(foot), foot * h,
      ]),
      fill([
        _hazed(const Color(0xff615b8b), .1),
        _hazed(const Color(0xff70688f), .1),
        _hazed(const Color(0xff9a8598), .2),
      ]),
    );
    c.drawPath(
      Sketch.poly([
        tx + face(cap), top,
        tx + half(cap), top,
        tx + half(foot), foot * h,
        tx + face(foot), foot * h,
      ]),
      fill([
        _hazed(const Color(0xff8f89b9), .1),
        _hazed(const Color(0xff9a92b8), .1),
        _hazed(const Color(0xffbea7b2), .2),
      ]),
    );
    // Weathering: long pale and dark runs under the cornice.
    final streak = Paint()..color = const Color(0x141c1a3a);
    for (final (dx, len) in const [(-.047, .11), (-.026, .06), (.004, .13), (.024, .07)]) {
      c.drawRect(Rect.fromLTWH(tx + dx * h, (cap + .05) * h, h * .0032, len * h), streak);
    }
    // Courses and staggered joints.
    final courses = Path(), joints = Path();
    var k = 0;
    for (var y = cap + .028; y < foot; y += .0105, k++) {
      courses
        ..moveTo(tx - half(y), y * h)
        ..lineTo(tx + half(y), y * h);
      final start = tx - half(y) + (k.isEven ? .011 : .0) * h + .011 * h;
      for (var x = start; x < tx + face(y) - h * .004; x += h * .022) {
        joints
          ..moveTo(x, y * h)
          ..lineTo(x, (y + .0105) * h);
      }
    }
    final hair = math.max(.5, h * .0011);
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = const Color(0x2a1c1a3a),
    );
    c.drawPath(
      joints,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = const Color(0x181c1a3a),
    );
    // A few blocks weathered paler or darker break up the courses.
    final pale = Path(), dim = Path();
    for (var i = 0; i < 20; i++) {
      final n = tx.round() * 7 + i * 13;
      final row = (Sketch.hash(n) * ((foot - cap - .06) / .0105)).floor();
      final y = (cap + .028 + row * .0105) * h;
      final x = tx - half(cap) + h * (.003 + .07 * Sketch.hash(n + 1));
      (Sketch.hash(n + 2) < .5 ? pale : dim).addRect(Rect.fromLTWH(x, y, h * .022, h * .0105));
    }
    c.drawPath(pale, Paint()..color = const Color(0x12ffffff));
    c.drawPath(dim, Paint()..color = const Color(0x141c1a3a));
    // Heavier rusticated footing where the tower stands in the river.
    final plinth = Rect.fromLTRB(tx - half(.738) - h * .009, .738 * h, tx + half(.738) + h * .009, foot * h);
    c.drawRect(
      plinth,
      Paint()
        ..shader = Gradient.linear(plinth.topCenter, plinth.bottomCenter, [
          _hazed(const Color(0xff7d7599), .14),
          _hazed(const Color(0xff4f4a78), .18),
        ]),
    );
    c.drawRect(
      Rect.fromLTRB(plinth.left, plinth.top, plinth.right, plinth.top + h * .004),
      Paint()..color = _hazed(const Color(0xff9a92b8), .14),
    );
    final rust = Path();
    for (var y = .748; y < foot; y += .009) {
      rust
        ..moveTo(plinth.left, y * h)
        ..lineTo(plinth.right, y * h);
    }
    c.drawPath(
      rust,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = const Color(0x381c1a3a),
    );
    // Cornice: a dark corbel table under two stepped slabs, lit on the right.
    final lip = half(cap) + h * .008;
    c.drawRect(
      Rect.fromLTRB(tx - lip, top + h * .004, tx + lip, top + h * .0135),
      Paint()..color = _hazed(const Color(0xff4d487a), .1),
    );
    final corbels = Path();
    for (var x = tx - lip + h * .003; x < tx + lip - h * .004; x += h * .0075) {
      corbels.addRect(Rect.fromLTWH(x, top + h * .0135, h * .0038, h * .0038));
    }
    c.drawPath(corbels, Paint()..color = _hazed(const Color(0xff5a5586), .1));
    c.drawRect(
      Rect.fromLTRB(tx - lip, top - h * .0055, tx + lip, top + h * .004),
      Paint()..color = _hazed(const Color(0xff8d87b5), .1),
    );
    c.drawRect(
      Rect.fromLTRB(tx + face(cap) + h * .002, top - h * .0055, tx + lip, top + h * .004),
      Paint()..color = _hazed(const Color(0xffaaa3cb), .1),
    );
    // A string course above the roadway.
    c.drawRect(
      Rect.fromLTRB(tx - half(deck) - h * .004, (deck - .011) * h, tx + half(deck) + h * .004, (deck - .0075) * h),
      Paint()..color = _hazed(const Color(0xff8a84b0), .1),
    );
    // Twin portals: dark tunnels whose floors glow with the roadway lamps.
    final arch = h * .0135, mid = tx - h * .0068;
    final baseY = (deck + .0035) * h;
    final spring = (cap + .0754) * h;
    final interior = Paint()
      ..shader = Gradient.linear(Offset(0, spring - arch * 1.73), Offset(0, baseY), [
        const Color(0xff1f2046),
        const Color(0xff2b2a52),
        const Color(0xff6d5668),
      ], const [0, .62, 1]);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, h * .0014)
      ..color = Sketch.fade(_hazed(const Color(0xffa39cc6), .1), .6);
    for (final dx in const [-.0195, .0195]) {
      final ax = mid + dx * h;
      final portal = _bridgeGothic(ax, baseY, arch, spring);
      c.drawPath(portal, interior);
      c.drawPath(portal, rim);
      // Blind lancet in the masonry above each portal.
      final lancet = _bridgeGothic(ax, spring - arch * 1.73 - h * .009, h * .0048, spring - arch * 1.73 - h * .019);
      c.drawPath(lancet, Paint()..color = const Color(0x661c1a3a));
    }
    // Moon rim on the right edge and iron saddles carrying the cables.
    c.drawLine(
      Offset(tx + half(cap + .016), top + h * .016),
      Offset(tx + half(.738), .738 * h),
      Paint()
        ..shader = Gradient.linear(Offset(0, top), Offset(0, .738 * h), const [Color(0x90d6d2f0), Color(0x00d6d2f0)])
        ..strokeWidth = math.max(.6, h * .0016),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(tx - h * .016, top - h * .0125, tx + h * .016, top - h * .003),
        Radius.circular(h * .003),
      ),
      Paint()..color = const Color(0xff2b2a4f),
    );
    // Flag mast; the flag and its beacon are animated in `_bridgeLive`.
    c.drawLine(
      Offset(tx - h * .0068, top - h * .01),
      Offset(tx - h * .0068, top - h * .052),
      Paint()
        ..color = const Color(0xff2b2a4f)
        ..strokeWidth = math.max(.6, h * .0018),
    );
  }

  /// Suspender rods and the fan of diagonal stays, drawn behind the deck rail
  /// and the towers.
  static void _bridgeWeb(Canvas c, double t1, double t2, double a1, double a2, double h) {
    final deck = h * _bridgeDeckY, sy = h * (_bridgeCapY - .007);
    final ay = h * _bridgeCableIn;
    final rods = Path(), stays = Path();
    void hang(double from, double to, double y0, double y1, double sag) {
      final n = ((to - from).abs() / (h * .017)).floor();
      for (var i = 1; i < n; i++) {
        final t = i / n;
        final x = from + (to - from) * t;
        rods
          ..moveTo(x, y0 + (y1 - y0) * t + sag * 4 * t * (1 - t))
          ..lineTo(x, deck);
      }
    }

    hang(t1, t2, sy, sy, _bridgeMainSag(h));
    hang(t1, a1, sy, ay, h * _bridgeSide);
    hang(t2, a2, sy, ay, h * _bridgeSide);
    for (final tx in [t1, t2]) {
      for (final s in const [-1.0, 1.0]) {
        for (var k = 0; k < 12; k++) {
          stays
            ..moveTo(tx + s * h * .03, sy + h * .014)
            ..lineTo(tx + s * h * (.062 + k * .026), deck);
        }
      }
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.55, h * .0013);
    c.drawPath(rods, line..color = Sketch.fade(_bridgeCableTone, .5));
    c.drawPath(stays, line..color = Sketch.fade(_bridgeCableTone, .4));
  }

  static double _bridgeMainSag(double h) =>
      h * (_bridgeDeckY - .014 - (_bridgeCapY - .007));

  /// The main cables over the towers, and the shallower side-span cables
  /// down into the anchorages: a soft glow, the cable and a lit top edge.
  static void _bridgeCables(Canvas c, double t1, double t2, double a1, double a2, double h) {
    final sy = h * (_bridgeCapY - .007);
    final ay = h * _bridgeCableIn;
    final side = h * _bridgeSide;
    final paths = [
      Path()
        ..moveTo(t1, sy)
        ..quadraticBezierTo((t1 + t2) / 2, sy + 2 * _bridgeMainSag(h), t2, sy),
      Path()
        ..moveTo(t1, sy)
        ..quadraticBezierTo((t1 + a1) / 2, (sy + ay) / 2 + 2 * side, a1, ay),
      Path()
        ..moveTo(t2, sy)
        ..quadraticBezierTo((t2 + a2) / 2, (sy + ay) / 2 + 2 * side, a2, ay),
    ];
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .011
      ..color = Sketch.fade(_bridgeCableTone, .08);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, h * .0038)
      ..color = _hazed(const Color(0xff8c89b8), .1);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, h * .0014)
      ..color = Sketch.fade(_bridgeCableTone, .9);
    for (final p in paths) {
      c.drawPath(p, glow);
    }
    for (final p in paths) {
      c.drawPath(p, core);
    }
    c.save();
    c.translate(0, -h * .0009);
    for (final p in paths) {
      c.drawPath(p, edge);
    }
    c.restore();
  }

  /// The roadway: a dark slab, an open Warren truss under it, a railing and
  /// a string of lamp posts.
  static void _bridgeDeck(Canvas c, double xl, double xr, double h) {
    final y = h * _bridgeDeckY;
    final iron = _hazed(const Color(0xff2a2950), .12);
    final hair = math.max(.55, h * .0012);
    // Soft shadow the girders throw on the haze below.
    c.drawRect(
      Rect.fromLTRB(xl, y + h * .0145, xr, y + h * .032),
      Paint()
        ..shader = Gradient.linear(Offset(0, y + h * .0145), Offset(0, y + h * .032), [
          const Color(0x3a1c1a3a),
          const Color(0x001c1a3a),
        ]),
    );
    c.drawRect(
      Rect.fromLTRB(xl, y + h * .004, xr, y + h * .0145),
      Paint()..color = Sketch.fade(iron, .5),
    );
    final pitch = h * .0125;
    final web = Path()..moveTo(xl, y + h * .0145);
    var low = true;
    for (var x = xl; x < xr; x += pitch) {
      web.lineTo(x + pitch, low ? y + h * .004 : y + h * .0145);
      low = !low;
    }
    c.drawPath(
      web,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(iron, .9),
    );
    c.drawRect(Rect.fromLTRB(xl, y, xr, y + h * .004), Paint()..color = iron);
    c.drawRect(
      Rect.fromLTRB(xl, y + h * .0145, xr, y + h * .0162),
      Paint()..color = iron,
    );
    c.drawLine(
      Offset(xl, y),
      Offset(xr, y),
      Paint()
        ..strokeWidth = hair
        ..color = _hazed(const Color(0xffa29fc8), .1),
    );
    // Railing, then a lamp every so often with a small warm halo.
    final rail = Path()
      ..moveTo(xl, y - h * .0072)
      ..lineTo(xr, y - h * .0072);
    final posts = Path();
    for (var x = xl; x < xr; x += h * .0205) {
      posts
        ..moveTo(x, y - h * .0072)
        ..lineTo(x, y);
    }
    c.drawPath(
      rail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(iron, .85),
    );
    c.drawPath(
      posts,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(iron, .6),
    );
    final masts = Path(), heads = Path(), halos = Path();
    for (var x = xl + h * .01; x < xr; x += h * .052) {
      masts
        ..moveTo(x, y - h * .0072)
        ..lineTo(x, y - h * .0135);
      heads.addOval(Rect.fromCircle(center: Offset(x, y - h * .0142), radius: h * .0021));
      halos.addOval(Rect.fromCircle(center: Offset(x, y - h * .0142), radius: h * .0046));
    }
    c.drawPath(
      masts,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = iron,
    );
    c.drawPath(halos, Paint()..color = const Color(0x22ffe9b8));
    c.drawPath(heads, Paint()..color = const Color(0xffffeec4));
  }

  /// A stone anchorage: a heavy stepped block with a cornice, courses and a
  /// rusticated base, the pointed portal where the roadway goes in, blind
  /// lancets above it and an iron saddle on the crown for the side cable.
  static void _bridgeAnchorage(Canvas c, double cx, double h) {
    final hw = h * .082, top = _bridgeAnchorTop * h, base = _bridgeFoot * h;
    final crown = h * .583, chw = hw * .64;
    final hair = math.max(.5, h * .0011);
    Paint tone(Rect r, Color a, Color b) => Paint()
      ..shader = Gradient.linear(r.topCenter, r.bottomCenter, [a, b]);
    // Front face in shade, a moonlit side, and the narrower crown on top.
    final body = Rect.fromLTRB(cx - hw, top, cx + hw * .62, base);
    c.drawRect(body, tone(body, _hazed(const Color(0xff5f5987), .15), _hazed(const Color(0xff7d7096), .2)));
    final side = Rect.fromLTRB(cx + hw * .62, top, cx + hw, base);
    c.drawRect(side, tone(side, _hazed(const Color(0xff8580ae), .15), _hazed(const Color(0xffa18fa8), .2)));
    final upper = Rect.fromLTRB(cx - chw, crown, cx + chw * .55, top);
    c.drawRect(upper, tone(upper, _hazed(const Color(0xff635d8b), .15), _hazed(const Color(0xff5f5987), .15)));
    final upperSide = Rect.fromLTRB(cx + chw * .55, crown, cx + chw, top);
    c.drawRect(upperSide, Paint()..color = _hazed(const Color(0xff8a84b2), .15));
    final courses = Path();
    for (var y = crown + h * .012; y < h * .76; y += h * .0105) {
      final wide = y > top;
      courses
        ..moveTo(cx - (wide ? hw : chw), y)
        ..lineTo(cx + (wide ? hw : chw), y);
    }
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = const Color(0x2a1c1a3a),
    );
    // Cornices under the crown and under the roofline.
    for (final (y, half) in [(crown, chw), (top, hw)]) {
      c.drawRect(
        Rect.fromLTRB(cx - half - h * .006, y - h * .006, cx + half + h * .006, y + h * .003),
        Paint()..color = _hazed(const Color(0xff8f89b7), .12),
      );
      c.drawRect(
        Rect.fromLTRB(cx - half - h * .002, y + h * .003, cx + half + h * .002, y + h * .0085),
        Paint()..color = _hazed(const Color(0xff4d487a), .12),
      );
    }
    // Rusticated footing where the block meets the water.
    c.drawRect(
      Rect.fromLTRB(cx - hw - h * .004, h * .742, cx + hw + h * .004, base),
      Paint()..color = _hazed(const Color(0xff5b5581), .16),
    );
    c.drawLine(
      Offset(cx - hw - h * .004, h * .742),
      Offset(cx + hw + h * .004, h * .742),
      Paint()
        ..color = _hazed(const Color(0xffa39cc6), .15)
        ..strokeWidth = math.max(.6, h * .0018),
    );
    // Portal with a glowing floor, and two blind lancets on each side.
    final portal = _bridgeGothic(cx, h * .664, h * .02, h * .6565);
    c.drawPath(
      portal,
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .622), Offset(0, h * .664), [
          const Color(0xff222248),
          const Color(0xff6d5668),
        ]),
    );
    c.drawPath(
      portal,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .0014)
        ..color = Sketch.fade(_hazed(const Color(0xffa39cc6), .12), .6),
    );
    for (final dx in const [-.056, -.036, .04, .06]) {
      c.drawPath(
        _bridgeGothic(cx + dx * h, h * .648, h * .0062, h * .634),
        Paint()..color = const Color(0x661c1a3a),
      );
    }
    // Iron saddle where the side-span cable goes in.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - h * .014, crown - h * .0125, cx + h * .014, crown - h * .003),
        Radius.circular(h * .003),
      ),
      Paint()..color = const Color(0xff2b2a4f),
    );
  }

  /// A round-arched masonry viaduct from [from] out to [to], carrying the
  /// deck on the approaches.
  static void _bridgeArcade(Canvas c, double from, double to, double h) {
    final dir = to > from ? 1.0 : -1.0;
    final lo = math.min(from, to), hi = math.max(from, to);
    final top = h * (_bridgeDeckY + .0125), base = h * _bridgeFoot;
    c.drawRect(
      Rect.fromLTRB(lo, top, hi, base),
      Paint()
        ..shader = Gradient.linear(Offset(0, top), Offset(0, base), [
          _hazed(const Color(0xff5d5888), .2),
          _hazed(const Color(0xff4a4675), .24),
        ]),
    );
    final courses = Path();
    for (var y = top + h * .009; y < h * .76; y += h * .0105) {
      courses
        ..moveTo(lo, y)
        ..lineTo(hi, y);
    }
    final hair = math.max(.5, h * .0011);
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = const Color(0x241c1a3a),
    );
    final bay = h * .125, pier = h * .024, hw = (bay - pier) / 2;
    final spring = h * .738;
    final arches = Path(), lit = Path();
    for (var k = 0; ; k++) {
      final cx = from + dir * bay * (k + .5);
      if ((cx - to) * dir > bay) break;
      arches
        ..moveTo(cx - hw, base)
        ..lineTo(cx - hw, spring)
        ..arcTo(Rect.fromCircle(center: Offset(cx, spring), radius: hw), math.pi, math.pi, false)
        ..lineTo(cx + hw, base)
        ..close();
      final px = from + dir * bay * k;
      lit.addRect(Rect.fromLTRB(px + pier * .1, top + h * .006, px + pier / 2, base));
    }
    c.drawPath(lit, Paint()..color = Sketch.fade(const Color(0xffa8a2cc), .22));
    c.drawPath(
      arches,
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .688), Offset(0, h * .76), [
          const Color(0xff2b2a52),
          const Color(0xff3d3c68),
        ]),
    );
    c.drawPath(
      arches,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(const Color(0xffa8a2cc), .3),
    );
    c.drawRect(
      Rect.fromLTRB(lo, top - h * .003, hi, top + h * .002),
      Paint()..color = Sketch.fade(const Color(0xff9a94c0), .5),
    );
  }

  /// Warehouses, pier sheds and a tank house along a shore, with a few lit
  /// windows.
  static void _bridgeShore(Canvas c, double from, double to, double h, int seed) {
    final lit = Path(), dark = Path();
    var x = from;
    for (var i = 0; x < to; i++) {
      final n = seed + i * 8;
      final wd = h * (.1 + .09 * Sketch.hash(n + 1));
      final ht = h * (.06 + .045 * Sketch.hash(n + 2));
      final r = Rect.fromLTRB(x, h * _bridgeFoot - ht, x + wd, h * _bridgeFoot);
      _bridgeBuilding(c, r, (Sketch.hash(n) * 4).floor(), n, h, lit, dark);
      x += wd + h * (.012 + .1 * Sketch.hash(n + 3));
    }
    c.drawPath(dark, Paint()..color = Sketch.fade(const Color(0xff26254a), .55));
    c.drawPath(lit, Paint()..color = Sketch.fade(_window, .75));
  }

  static void _bridgeBuilding(Canvas c, Rect r, int kind, int n, double h, Path lit, Path dark) {
    final tone = _hazed(
      const [Color(0xff433f6c), Color(0xff4a4470), Color(0xff3d3b66), Color(0xff48406a)][n % 4],
      .12,
    );
    final roof = Sketch.mix(tone, const Color(0xff1c1a3a), .35);
    c.drawRect(r, Paint()..color = tone);
    c.drawRect(
      Rect.fromLTRB(r.right - r.width * .16, r.top, r.right, r.bottom),
      Paint()..color = Sketch.fade(const Color(0xff9a94c0), .16),
    );
    switch (kind) {
      case 1:
        c.drawPath(
          Sketch.poly([r.left - h * .004, r.top, r.center.dx, r.top - h * .022, r.right + h * .004, r.top]),
          Paint()..color = roof,
        );
        // A pier shed stands on pilings over the water.
        final piles = Path();
        for (var x = r.left + h * .004; x < r.right; x += h * .011) {
          piles
            ..moveTo(x, h * .742)
            ..lineTo(x, h * .762);
        }
        c.drawRect(Rect.fromLTRB(r.left, h * .739, r.right, h * .743), Paint()..color = roof);
        c.drawPath(
          piles,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.6, h * .002)
            ..color = Sketch.fade(const Color(0xff1c1a3a), .7),
        );
      case 2:
        // A wooden tank on legs.
        final tx = r.left + r.width * .3, ty = r.top;
        final s = h * .012;
        c.drawLine(
          Offset(tx - s * .5, ty),
          Offset(tx - s * .4, ty - s * .9),
          Paint()
            ..color = roof
            ..strokeWidth = math.max(.6, h * .0014),
        );
        c.drawLine(
          Offset(tx + s * .5, ty),
          Offset(tx + s * .4, ty - s * .9),
          Paint()
            ..color = roof
            ..strokeWidth = math.max(.6, h * .0014),
        );
        c.drawRect(Rect.fromLTRB(tx - s * .6, ty - s * 2, tx + s * .6, ty - s * .9), Paint()..color = roof);
        c.drawPath(
          Sketch.poly([tx - s * .75, ty - s * 2, tx, ty - s * 2.7, tx + s * .75, ty - s * 2]),
          Paint()..color = roof,
        );
        c.drawRect(Rect.fromLTRB(r.left - h * .002, r.top - h * .004, r.right + h * .002, r.top), Paint()..color = roof);
      case 3:
        c.drawRect(
          Rect.fromLTWH(r.left + r.width * .68, r.top - h * .036, h * .009, h * .036),
          Paint()..color = roof,
        );
        c.drawRect(Rect.fromLTRB(r.left - h * .002, r.top - h * .004, r.right + h * .002, r.top), Paint()..color = roof);
      default:
        c.drawRect(Rect.fromLTRB(r.left - h * .002, r.top - h * .004, r.right + h * .002, r.top), Paint()..color = roof);
    }
    final cols = math.max(2, (r.width / (h * .026)).floor());
    final colW = r.width / cols;
    for (var row = 0; row < 3; row++) {
      final y = r.top + h * (.012 + row * .02);
      if (y > h * .752) break;
      for (var col = 0; col < cols; col++) {
        final win = Rect.fromLTWH(r.left + colW * (col + .3), y, colW * .4, h * .009);
        (Sketch.hash(n * 13 + row * 5 + col) < .3 ? lit : dark).addRect(win);
      }
    }
  }

  /// Flags and beacons on the towers and the traffic on the deck: the only
  /// animated parts of the bridge, a few dozen small draws.
  static void _bridgeLive(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h, clock = f.clock;
    final t1 = w * .24, t2 = t1 + h * _bridgeSpan;
    final a1 = t1 - h * .52, a2 = t2 + h * .52;
    // Flags stir in the rain wind; red beacons breathe slowly.
    final flag = _bridgeFlag;
    final beacon = Paint();
    for (var i = 0; i < 2; i++) {
      final mx = (i == 0 ? t1 : t2) - h * .0068;
      final my = (_bridgeCapY - .052) * h;
      final fw = h * .028, fh = h * .0145;
      double wave(double u) =>
          math.sin(u * 5.2 - clock * 3.1 + i * 1.7) * h * .0026 * u;
      for (var b = 0; b < 3; b++) {
        final y0 = my + fh * b / 3 + h * .002, y1 = my + fh * (b + 1) / 3 + h * .002;
        final path = Path()..moveTo(mx, y0);
        for (var s = 1; s <= 4; s++) {
          path.lineTo(mx + fw * s / 4, y0 + wave(s / 4));
        }
        for (var s = 4; s >= 0; s--) {
          path.lineTo(mx + fw * s / 4, y1 + wave(s / 4));
        }
        c.drawPath(path..close(), flag[b == 1 ? 1 : 0]);
      }
      c.drawRect(Rect.fromLTWH(mx, my + h * .002, fw * .42, fh * .56), flag[2]);
      final pulse = .5 + .5 * math.sin(clock * 1.9 + i * 2.3);
      beacon.color = Sketch.fade(const Color(0xffff6a60), .16 + .14 * pulse);
      c.drawCircle(Offset(mx, my - h * .003), h * .0085, beacon);
      beacon.color = Sketch.fade(const Color(0xffff7a70), .55 + .4 * pulse);
      c.drawCircle(Offset(mx, my - h * .003), h * .0026, beacon);
    }
    // Two banks of river mist drift slowly past the tower feet.
    for (var i = 0; i < 2; i++) {
      final u = (clock * .008 + i * .5 + .13) % 1;
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(-h * .6 + (w + h * 1.5) * u, h * (.744 + i * .004)),
          width: h * (.55 + i * .12),
          height: h * .05,
        ),
        const Color(0xffbba6cf),
        .16 * math.sin(u * math.pi),
      );
    }
    // Two slow streams of cars, white heads one way and red tails the other.
    final deck = h * _bridgeDeckY;
    final start = -h * .6, span = w + h * 1.5;
    final bodies = Path(), heads = Path(), tails = Path();
    for (var lane = 0; lane < 2; lane++) {
      final dir = lane == 0 ? 1.0 : -1.0;
      final y = deck - h * (.0022 + lane * .0032);
      for (var i = 0; i < 7; i++) {
        final slot = (i + .2 + .6 * Sketch.hash(i * 3 + lane * 41 + 7)) / 7;
        final x = start + (span * slot + dir * clock * h * (.032 - lane * .006)) % span;
        if ((x - t1).abs() < h * .062 ||
            (x - t2).abs() < h * .062 ||
            (x - a1).abs() < h * .09 ||
            (x - a2).abs() < h * .09) {
          continue;
        }
        final len = h * (.0105 + .004 * Sketch.hash(i + lane * 17));
        bodies.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y - h * .0016), width: len, height: h * .0042),
            Radius.circular(h * .0016),
          ),
        );
        heads.addOval(Rect.fromCircle(center: Offset(x + dir * len * .5, y), radius: h * .0021));
        tails.addOval(Rect.fromCircle(center: Offset(x - dir * len * .5, y), radius: h * .0018));
      }
    }
    c.drawPath(bodies, Paint()..color = const Color(0xd923224a));
    c.drawPath(heads, Paint()..color = const Color(0xdde8eeff));
    c.drawPath(tails, Paint()..color = const Color(0xccff5a55));
  }

  // ---------------------------------------------------------------------------
  // Near band: brick rooftops.

  static const _roofInk = Color(0xff14121f);
  static const _roofGlow = Color(0xffc48aa4);
  static const _roofMoon = Color(0xffcfd0f0);
  static const _roofStone = Color(0xffb0a6cc);
  static const _roofLamp = Color(0xfff2c46a);
  static const _roofLampLow = Color(0xffd6924e);
  static const _roofTv = Color(0xff6f9be0);
  static const _roofGlass = Color(0xff232441);
  static const _roofFrame = Color(0xff1b192b);
  static const _roofSteam = Color(0xffd8d4ec);
  static const _roofNeonPink = Color(0xffff86b8);
  static const _roofBricks = [
    Color(0xff54404f),
    Color(0xff413b5b),
    Color(0xff5b4249),
    Color(0xff484462),
    Color(0xff574640),
  ];

  /// Which brick tone each lot takes, so neighbours (also across the repeat)
  /// never match.
  static const _roofTones = [0, 3, 1, 4, 2, 0, 3, 1, 4, 2, 3];

  /// One repeat of the near rooftops, left to right, each aware of the roof
  /// heights of its neighbours (the wrap keeps the repeat seamless).
  static void _roofRow(Canvas c, double h) {
    final n = _roofs.length;
    var x = 0.0;
    for (var i = 0; i < n; i++) {
      final (width, roof, facade, top) = _roofs[i];
      _tenement(
        c,
        Rect.fromLTRB(x * h, roof * h, (x + width) * h, h * .96),
        facade,
        top,
        i,
        _roofs[(i + n - 1) % n].$2 * h,
        _roofs[(i + 1) % n].$2 * h,
      );
      x += width;
    }
  }

  /// A brick walk-up seen head on: brickwork, cornice, windows with life, a
  /// fire escape or drainpipe, and the clutter on its roof.
  static void _tenement(
    Canvas c,
    Rect r,
    int facade,
    int top,
    int seed,
    double leftRoof,
    double rightRoof,
  ) {
    final h = r.bottom / .96;
    final base = _roofBricks[_roofTones[seed % _roofTones.length]];
    // The city glow washes the tops; the street end of the wall is darker.
    c.drawRect(
      r,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, r.top),
          Offset(0, r.bottom),
          [
            Sketch.mix(base, _roofGlow, .16),
            base,
            Sketch.mix(base, _roofInk, .34),
          ],
          const [0, .3, 1],
        ),
    );
    _roofBrickwork(c, r, h, base, seed);
    _roofTop(c, r, h, top, base);
    _roofCornice(c, r, h, base, seed, top);
    _roofWindows(c, r, h, facade, seed, base);
    if (facade == 1) _fireEscape(c, r, h);
    if (facade == 0 || facade == 3) _roofDrainpipe(c, r, h, base);
    _roofEdges(c, r, h, leftRoof, rightRoof);
  }

  /// Courses of brick: mortar lines, a running bond of lighter and darker
  /// bricks, and rain streaks running down from the cornice.
  static void _roofBrickwork(
    Canvas c,
    Rect r,
    double h,
    Color base,
    int seed,
  ) {
    final course = h * .0085, brick = h * .02;
    final mortar = Path(), lighter = Path(), darker = Path();
    var row = 0;
    for (var y = r.top + h * .036; y < r.bottom; y += course, row++) {
      mortar
        ..moveTo(r.left, y)
        ..lineTo(r.right, y);
      final shift = row.isOdd ? brick / 2 : 0.0;
      var k = 0;
      for (var x = r.left - shift; x < r.right; x += brick, k++) {
        final n = Sketch.hash(seed * 7919 + row * 131 + k);
        if (n > .1 && n < .9) continue;
        final b = Rect.fromLTRB(
          math.max(x, r.left),
          y + course * .1,
          math.min(x + brick, r.right),
          y + course * .9,
        );
        (n <= .1 ? lighter : darker).addRect(b);
      }
    }
    c.drawPath(darker, Paint()..color = Sketch.fade(_roofInk, .13));
    c.drawPath(lighter, Paint()..color = Sketch.fade(_roofGlow, .11));
    c.drawPath(
      mortar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0014)
        ..color = Sketch.fade(_roofInk, .18),
    );
    // Water stains under the cornice, fading in three steps.
    for (var k = 0; k < 3; k++) {
      final x = r.left + r.width * (.08 + .84 * Sketch.hash(seed * 13 + k));
      final len = h * (.05 + .07 * Sketch.hash(seed * 17 + k));
      final wide = h * (.006 + .007 * Sketch.hash(seed * 19 + k));
      for (var t = 0; t < 3; t++) {
        c.drawRect(
          Rect.fromLTWH(
            x - wide * (1 - t * .2) / 2,
            r.top + h * .03,
            wide * (1 - t * .2),
            len * (1 - t * .3),
          ),
          Paint()..color = Sketch.fade(_roofInk, .06),
        );
      }
    }
  }

  /// Coping, parapet, and a bracketed cornice; some parapets rise into a
  /// small arched pediment.
  static void _roofCornice(
    Canvas c,
    Rect r,
    double h,
    Color base,
    int seed,
    int top,
  ) {
    final stone = Sketch.mix(base, _roofStone, .4);
    final stoneDark = Sketch.mix(base, _roofStone, .22);
    final over = h * .004;
    final l = seed == 0 ? r.left : r.left - over;
    final rt = seed == _roofs.length - 1 ? r.right : r.right + over;
    final y = r.top;
    // Parapet wall.
    c.drawRect(
      Rect.fromLTRB(r.left, y, r.right, y + h * .0145),
      Paint()..color = Sketch.mix(base, _roofInk, .1),
    );
    if (top == 0 || top == 4) {
      final cx = r.center.dx, half = h * .045;
      c.drawPath(
        Path()
          ..moveTo(cx - half, y + h * .001)
          ..lineTo(cx - half, y - h * .008)
          ..quadraticBezierTo(cx, y - h * .028, cx + half, y - h * .008)
          ..lineTo(cx + half, y + h * .001)
          ..close(),
        Paint()..color = Sketch.mix(base, _roofInk, .06),
      );
      c.drawPath(
        Path()
          ..moveTo(cx - half, y - h * .008)
          ..quadraticBezierTo(cx, y - h * .028, cx + half, y - h * .008),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0032
          ..color = stone,
      );
      c.drawRect(
        Rect.fromCenter(
          center: Offset(cx, y - h * .0085),
          width: h * .034,
          height: h * .0048,
        ),
        Paint()..color = Sketch.mix(base, _roofInk, .34),
      );
    }
    // Coping with a wet sheen along its top.
    c.drawRect(
      Rect.fromLTRB(l, y, rt, y + h * .0048),
      Paint()..color = stone,
    );
    c.drawRect(
      Rect.fromLTRB(l, y, rt, y + math.max(.7, h * .0017)),
      Paint()..color = Sketch.mix(stone, _roofGlow, .65),
    );
    // Cornice band, its shadow, and the brackets under it.
    c.drawRect(
      Rect.fromLTRB(l, y + h * .0145, rt, y + h * .0215),
      Paint()..color = stone,
    );
    c.drawRect(
      Rect.fromLTRB(l, y + h * .0145, rt, y + h * .0158),
      Paint()..color = Sketch.mix(stone, _roofMoon, .35),
    );
    c.drawRect(
      Rect.fromLTRB(r.left, y + h * .0215, r.right, y + h * .0315),
      Paint()..color = Sketch.fade(_roofInk, .3),
    );
    final brackets = Path();
    for (var x = r.left + h * .007; x < r.right - h * .01; x += h * .019) {
      brackets.addRect(Rect.fromLTWH(x, y + h * .0215, h * .0048, h * .0085));
    }
    c.drawPath(brackets, Paint()..color = stoneDark);
  }

  /// The number of window columns for a facade [width] (in heights).
  static int _roofCols(double width, int facade) => math.max(
    2,
    (width / (facade == 2 ? .085 : (facade == 3 ? .075 : .062))).floor(),
  );

  /// Window [col] of [row] on a facade. Facade 2 has tall arched windows,
  /// facade 3 wide strip windows, the others plain double-hung ones.
  static Rect _roofWin(Rect r, double h, int facade, int row, int col) {
    final cw = r.width / _roofCols(r.width / h, facade);
    final (wide, tall, pitch, start) = switch (facade) {
      2 => (.5, .046, .066, .056),
      3 => (.62, .022, .044, .05),
      _ => (.44, .029, .046, .052),
    };
    final ww = cw * wide;
    return Rect.fromLTWH(
      r.left + cw * (col + .5) - ww / 2,
      r.top + h * (start + pitch * row),
      ww,
      h * tall,
    );
  }

  /// How many rows of windows show above the ground.
  static int _roofRows(Rect r, double h, int facade) {
    var n = 0;
    while (true) {
      final win = _roofWin(r, h, facade, n, 0);
      if (win.top + win.height * .45 > h * .94) return n;
      n++;
    }
  }

  /// The one window per building that someone switches on and off.
  static (int, int) _roofPick(int seed, int rows, int cols) =>
      (math.min(rows - 1, seed % 2), (seed * 3 + 1) % cols);

  static int _roofState(int seed, int row, int col) {
    final n = Sketch.hash(seed * 331 + row * 17 + col * 5 + 9);
    if (n < .09) return 1; // warm
    if (n < .16) return 2; // curtains
    if (n < .23) return 3; // someone home
    if (n < .27) return 4; // television
    if (n < .3) return 5; // blind half down
    if (n < .44) return 6; // plant on the sill
    if (n < .52) return 7; // window air conditioner
    if (n < .64) return 8; // dark, shade drawn
    return 0;
  }

  /// Every window of a facade: stone lintels and sills, dark frames, glass
  /// that is dark, warm or television blue, and small lives behind it.
  static void _roofWindows(
    Canvas c,
    Rect r,
    double h,
    int facade,
    int seed,
    Color base,
  ) {
    final cols = _roofCols(r.width / h, facade);
    final rows = _roofRows(r, h, facade);
    if (rows < 1) return;
    final arch = facade == 2;
    final pick = _roofPick(seed, rows, cols);
    final stone = Path(), sills = Path(), shade = Path(), frame = Path();
    final glass = Path(), sheen = Path(), warm = Path(), warmLow = Path();
    final tv = Path(), screen = Path(), blind = Path(), drawn = Path();
    final curtain = Path(), person = Path(), pot = Path(), leaves = Path();
    final unit = Path(), haloOuter = Path(), haloInner = Path();
    final haloBlue = Path(), muntin = Path();
    void shape(Path p, Rect rc) {
      if (arch) {
        p.addRRect(
          RRect.fromRectAndCorners(
            rc,
            topLeft: Radius.circular(rc.width / 2),
            topRight: Radius.circular(rc.width / 2),
          ),
        );
      } else {
        p.addRect(rc);
      }
    }

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final g = _roofWin(r, h, facade, row, col);
        final state = (row, col) == pick ? 0 : _roofState(seed, row, col);
        final n = Sketch.hash(seed * 577 + row * 29 + col * 3);
        // Where the glass starts below any arch.
        final y0 = arch ? g.top + g.width * .5 : g.top;
        if (arch) {
          shape(stone, g.inflate(h * .0045));
        } else {
          stone.addRect(
            Rect.fromLTWH(
              g.left - h * .0045,
              g.top - h * .0078,
              g.width + h * .009,
              h * .0046,
            ),
          );
        }
        sills.addRect(
          Rect.fromLTWH(
            g.left - h * .0055,
            g.bottom + h * .0022,
            g.width + h * .011,
            h * .0038,
          ),
        );
        shade.addRect(
          Rect.fromLTWH(
            g.left - h * .002,
            g.bottom + h * .006,
            g.width + h * .004,
            h * .005,
          ),
        );
        shape(frame, g.inflate(h * .0022));
        if (state >= 1 && state <= 3 || state == 5) {
          shape(haloOuter, g.inflate(h * .009));
          shape(haloInner, g.inflate(h * .0045));
        }
        switch (state) {
          case 4:
            shape(haloBlue, g.inflate(h * .008));
            shape(tv, g);
            screen.addRect(
              Rect.fromLTRB(
                g.left + g.width * .16,
                y0 + (g.bottom - y0) * .3,
                g.right - g.width * .16,
                g.bottom - g.height * .1,
              ),
            );
            // The back of a head, watching.
            person.addOval(
              Rect.fromCenter(
                center: Offset(
                  g.left + g.width * (.3 + .4 * n),
                  g.bottom - g.height * .2,
                ),
                width: h * .0078,
                height: h * .0078,
              ),
            );
          case 1 || 2 || 3 || 5:
            shape(warm, g);
            warmLow.addRect(
              Rect.fromLTRB(
                g.left,
                y0 + (g.bottom - y0) * .58,
                g.right,
                g.bottom,
              ),
            );
            if (state == 2) {
              curtain
                ..addPolygon([
                  Offset(g.left, y0),
                  Offset(g.left + g.width * .34, y0),
                  Offset(g.left + g.width * .2, g.bottom),
                  Offset(g.left, g.bottom),
                ], true)
                ..addPolygon([
                  Offset(g.right, y0),
                  Offset(g.right - g.width * .34, y0),
                  Offset(g.right - g.width * .2, g.bottom),
                  Offset(g.right, g.bottom),
                ], true);
            } else if (state == 3) {
              final cx = g.left + g.width * (.3 + .4 * n);
              final body = g.bottom - (g.bottom - y0) * .5;
              person
                ..addOval(
                  Rect.fromCenter(
                    center: Offset(cx, body - h * .0055),
                    width: h * .0084,
                    height: h * .0084,
                  ),
                )
                ..addRRect(
                  RRect.fromRectAndCorners(
                    Rect.fromLTRB(cx - h * .0062, body, cx + h * .0062, g.bottom),
                    topLeft: Radius.circular(h * .0055),
                    topRight: Radius.circular(h * .0055),
                  ),
                );
            } else if (state == 5) {
              blind.addRect(
                Rect.fromLTRB(
                  g.left,
                  y0,
                  g.right,
                  y0 + (g.bottom - y0) * (.35 + .35 * n),
                ),
              );
            }
          default:
            shape(glass, g);
            sheen.addPolygon([
              Offset(g.left, y0),
              Offset(g.left + g.width * .6, y0),
              Offset(g.left, y0 + (g.bottom - y0) * .85),
            ], true);
            if (state == 6) {
              final px = g.left + g.width * (.15 + .45 * n);
              pot.addRect(
                Rect.fromLTWH(px, g.bottom - h * .0068, h * .0088, h * .0068),
              );
              for (final (dx, dy) in const [(.0, .0), (-.0025, -.0032), (.0025, -.0032)]) {
                leaves.addOval(
                  Rect.fromCenter(
                    center: Offset(px + h * (.0044 + dx), g.bottom - h * (.0105 - dy)),
                    width: h * .0058,
                    height: h * .0058,
                  ),
                );
              }
            } else if (state == 7) {
              unit.addRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(
                    g.center.dx - h * .009,
                    g.bottom - h * .0125,
                    h * .018,
                    h * .0125,
                  ),
                  Radius.circular(h * .0012),
                ),
              );
            } else if (state == 8) {
              drawn.addRect(
                Rect.fromLTRB(
                  g.left,
                  y0,
                  g.right,
                  y0 + (g.bottom - y0) * (.3 + .4 * n),
                ),
              );
            }
        }
        muntin
          ..moveTo(g.center.dx, y0)
          ..lineTo(g.center.dx, g.bottom)
          ..moveTo(g.left, y0 + (g.bottom - y0) * .42)
          ..lineTo(g.right, y0 + (g.bottom - y0) * .42);
      }
    }
    Paint p(Color color) => Paint()..color = color;
    c.drawPath(haloOuter, p(Sketch.fade(_roofLamp, .07)));
    c.drawPath(haloInner, p(Sketch.fade(_roofLamp, .09)));
    c.drawPath(haloBlue, p(Sketch.fade(_roofTv, .09)));
    c.drawPath(stone, p(Sketch.mix(base, _roofStone, .42)));
    c.drawPath(sills, p(Sketch.mix(base, _roofStone, .5)));
    c.drawPath(shade, p(Sketch.fade(_roofInk, .28)));
    c.drawPath(frame, p(_roofFrame));
    c.drawPath(glass, p(_roofGlass));
    c.drawPath(sheen, p(Sketch.fade(const Color(0xffc9b8e0), .12)));
    c.drawPath(drawn, p(const Color(0xff3d3e66)));
    c.drawPath(warm, p(_roofLamp));
    c.drawPath(warmLow, p(_roofLampLow));
    c.drawPath(tv, p(_roofTv));
    c.drawPath(screen, p(const Color(0xffa9c9f6)));
    c.drawPath(blind, p(const Color(0xffb5793f)));
    c.drawPath(curtain, p(Sketch.fade(const Color(0xff8c4a48), .9)));
    c.drawPath(person, p(const Color(0xff33201f)));
    c.drawPath(pot, p(const Color(0xff6a3d3c)));
    c.drawPath(leaves, p(const Color(0xff2d5a48)));
    c.drawPath(unit, p(const Color(0xff727a98)));
    c.drawPath(
      muntin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .0017)
        ..color = _roofFrame,
    );
  }

  /// A window that has been switched on: halo, warm glass, muntins.
  static void _roofLit(
    Canvas c,
    Rect g,
    double h,
    bool arch,
    Color high,
    Color low,
  ) {
    final y0 = arch ? g.top + g.width * .5 : g.top;
    Path shape(Rect rc) => Path()
      ..addRRect(
        arch
            ? RRect.fromRectAndCorners(
                rc,
                topLeft: Radius.circular(rc.width / 2),
                topRight: Radius.circular(rc.width / 2),
              )
            : RRect.fromRectAndRadius(rc, Radius.zero),
      );
    c.drawPath(shape(g.inflate(h * .009)), Paint()..color = Sketch.fade(high, .07));
    c.drawPath(shape(g.inflate(h * .0045)), Paint()..color = Sketch.fade(high, .09));
    c.drawPath(shape(g), Paint()..color = high);
    c.drawRect(
      Rect.fromLTRB(g.left, y0 + (g.bottom - y0) * .58, g.right, g.bottom),
      Paint()..color = low,
    );
    c.drawPath(
      Path()
        ..moveTo(g.center.dx, y0)
        ..lineTo(g.center.dx, g.bottom)
        ..moveTo(g.left, y0 + (g.bottom - y0) * .42)
        ..lineTo(g.right, y0 + (g.bottom - y0) * .42),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .0017)
        ..color = _roofFrame,
    );
  }

  /// Where a taller neighbour crowds this facade it falls into shade, and the
  /// exposed edge of a taller building catches the moon.
  static void _roofEdges(
    Canvas c,
    Rect r,
    double h,
    double leftRoof,
    double rightRoof,
  ) {
    if (rightRoof < r.top - 1) {
      final x0 = r.right - h * .05;
      c.drawRect(
        Rect.fromLTRB(x0, r.top, r.right, r.bottom),
        Paint()
          ..shader = Gradient.linear(Offset(x0, 0), Offset(r.right, 0), [
            Sketch.fade(_roofInk, 0),
            Sketch.fade(_roofInk, .5),
          ]),
      );
    }
    if (leftRoof < r.top - 1) {
      final x1 = r.left + h * .035;
      c.drawRect(
        Rect.fromLTRB(r.left, r.top, x1, r.bottom),
        Paint()
          ..shader = Gradient.linear(Offset(r.left, 0), Offset(x1, 0), [
            Sketch.fade(_roofInk, .38),
            Sketch.fade(_roofInk, 0),
          ]),
      );
    }
    if (rightRoof > r.top + 1) {
      c.drawRect(
        Rect.fromLTRB(
          r.right - math.max(.7, h * .0022),
          r.top,
          r.right,
          math.min(rightRoof, r.bottom),
        ),
        Paint()..color = Sketch.fade(_roofMoon, .35),
      );
    }
  }

  /// A cast-iron downspout with brackets, down the right side of the wall.
  static void _roofDrainpipe(Canvas c, Rect r, double h, Color base) {
    final x = r.right - h * .009;
    final pipe = Sketch.mix(base, _roofInk, .5);
    c.drawRect(
      Rect.fromLTRB(x - h * .002, r.top + h * .03, x + h * .002, r.bottom),
      Paint()..color = pipe,
    );
    c.drawRect(
      Rect.fromLTRB(x + h * .0004, r.top + h * .03, x + h * .002, r.bottom),
      Paint()..color = Sketch.fade(_roofMoon, .22),
    );
    final clips = Path();
    for (var y = r.top + h * .05; y < r.bottom; y += h * .04) {
      clips.addRect(Rect.fromLTRB(x - h * .0035, y, x + h * .0035, y + h * .0022));
    }
    c.drawPath(clips, Paint()..color = Sketch.mix(pipe, _roofInk, .5));
  }

  /// Zig-zag iron stairs and railed landings under each floor's windows, with
  /// a ladder up to the roof.
  static void _fireEscape(Canvas c, Rect r, double h) {
    final cols = _roofCols(r.width / h, 1);
    final rows = _roofRows(r, h, 1);
    if (rows < 1 || cols < 3) return;
    final first = _roofWin(r, h, 1, 0, 1);
    final last = _roofWin(r, h, 1, 0, cols - 2);
    final xl = first.left - h * .007, xr = last.right + h * .007;
    final pitch = h * .046;
    final thin = math.max(.7, h * .0019);
    final decks = Path(), rails = Path(), stairs = Path();
    final shadow = Path(), sheen = Path();
    for (var row = 0; row < rows; row++) {
      final y = _roofWin(r, h, 1, row, 0).bottom + h * .0098;
      decks
        ..moveTo(xl, y)
        ..lineTo(xr, y);
      shadow.addRect(Rect.fromLTRB(xl, y + h * .002, xr, y + h * .01));
      sheen
        ..moveTo(xl, y - h * .0022)
        ..lineTo(xr, y - h * .0022);
      // Top rail and balusters.
      rails
        ..moveTo(xl, y - h * .0135)
        ..lineTo(xr, y - h * .0135);
      for (var x = xl; x <= xr + .1; x += h * .0125) {
        rails
          ..moveTo(x, y)
          ..lineTo(x, y - h * .0135);
      }
      // The flight down to the next landing runs the other way each floor.
      final run = math.min((xr - xl) * .55, h * .06);
      final from = row.isEven ? xr - h * .012 : xl + h * .012;
      final to = row.isEven ? from - run : from + run;
      final a = Offset(from, y), b = Offset(to, y + pitch);
      stairs
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..moveTo(a.dx, a.dy - h * .0135)
        ..lineTo(b.dx, b.dy - h * .0135);
      for (var k = 1; k < 7; k++) {
        final p = Offset.lerp(a, b, k / 7)!;
        stairs
          ..moveTo(p.dx - h * .003, p.dy)
          ..lineTo(p.dx + h * .003, p.dy);
      }
    }
    // A ladder from the top landing up to the roof, between two windows.
    final gapX = (first.right + _roofWin(r, h, 1, 0, 2).left) / 2;
    final top = _roofWin(r, h, 1, 0, 0).bottom + h * .0098 - h * .0135;
    for (final dx in const [-.003, .003]) {
      rails
        ..moveTo(gapX + dx * h, top)
        ..lineTo(gapX + dx * h, r.top + h * .034);
    }
    for (var y = top - h * .006; y > r.top + h * .036; y -= h * .0065) {
      rails
        ..moveTo(gapX - h * .003, y)
        ..lineTo(gapX + h * .003, y);
    }
    c.drawPath(shadow, Paint()..color = Sketch.fade(_roofInk, .2));
    final iron = Paint()
      ..style = PaintingStyle.stroke
      ..color = _roofInk
      ..strokeWidth = thin;
    c.drawPath(stairs, iron);
    c.drawPath(rails, iron);
    c.drawPath(
      decks,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _roofInk
        ..strokeWidth = h * .0038,
    );
    c.drawPath(
      sheen,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Sketch.fade(_roofMoon, .28)
        ..strokeWidth = math.max(.5, h * .0012),
    );
  }

  /// The clutter on a roof, tucked behind the parapet at its foot.
  static void _roofTop(Canvas c, Rect r, double h, int top, Color base) {
    final y = r.top + h * .008;
    final w = r.width;
    switch (top) {
      case 0:
        _roofChimney(c, h, Offset(r.left + w * .2, y), h * .03, h * .062, base);
        _roofChimney(c, h, Offset(r.left + w * .8, y), h * .026, h * .045, base);
      case 1:
        _waterTower(c, Offset(r.left + w * .36, y), h * .05);
        _roofChimney(c, h, Offset(r.left + w * .86, y), h * .024, h * .04, base);
      case 2:
        _roofLaundry(c, r, h);
        _roofAntenna(c, h, Offset(r.left + w * .76, y), h * .085);
        _roofAntenna(c, h, Offset(r.left + w * .91, y), h * .06, lean: .08);
      case 3:
        _roofCoop(c, r, h);
      case 4:
        _roofNeon(c, r, h);
      case 5:
        _roofBulkhead(c, r, h, base);
    }
  }

  /// Where the steam of a chimney leaves it, if this roof has one.
  static Offset? _roofSteamAt(Rect r, double h, int top, int seed) {
    if (top == 0) {
      return Offset(r.left + r.width * .2, r.top + h * (.008 - .062 - .0135));
    }
    if (top == 1 && seed.isEven) {
      return Offset(r.left + r.width * .86, r.top + h * (.008 - .04 - .0135));
    }
    return null;
  }

  /// A brick chimney: shaded stack, lit edge, corbelled cap and a flue pot.
  static void _roofChimney(
    Canvas c,
    double h,
    Offset foot,
    double w,
    double ht,
    Color base, {
    double alpha = 1,
  }) {
    final left = foot.dx - w / 2, top = foot.dy - ht;
    final dark = Sketch.mix(base, _roofInk, .42);
    final stone = Sketch.mix(base, _roofStone, .3);
    Paint p(Color color) => Paint()..color = Sketch.fade(color, alpha);
    c.drawRect(Rect.fromLTWH(left, top, w, ht), p(dark));
    c.drawRect(
      Rect.fromLTRB(left + w * .64, top, left + w, foot.dy),
      p(Sketch.mix(dark, _roofGlow, .16)),
    );
    final courses = Path();
    for (var y = top + h * .008; y < foot.dy; y += h * .0085) {
      courses
        ..moveTo(left, y)
        ..lineTo(left + w, y);
    }
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0013)
        ..color = Sketch.fade(_roofInk, .3 * alpha),
    );
    // Soot creeps down from the flue.
    c.drawRect(Rect.fromLTWH(left, top, w, h * .012), p(Sketch.fade(_roofInk, .35)));
    // Two corbelled courses and the pot.
    c.drawRect(
      Rect.fromLTWH(left - w * .08, top - h * .0035, w * 1.16, h * .0035),
      p(Sketch.mix(stone, _roofInk, .3)),
    );
    c.drawRect(
      Rect.fromLTWH(left - w * .16, top - h * .0085, w * 1.32, h * .005),
      p(stone),
    );
    c.drawRect(
      Rect.fromLTWH(left - w * .16, top - h * .0085, w * 1.32, math.max(.6, h * .0014)),
      p(Sketch.mix(stone, _roofMoon, .5)),
    );
    c.drawRect(
      Rect.fromLTWH(foot.dx - w * .19, top - h * .0145, w * .38, h * .006),
      p(const Color(0xff6b3f3f)),
    );
    c.drawRect(
      Rect.fromLTWH(foot.dx - w * .25, top - h * .0158, w * .5, h * .0022),
      p(const Color(0xff845050)),
    );
  }

  /// A cedar water tank on steel legs: staved barrel, iron hoops, conical
  /// roof, braced legs and a feed pipe, lit from the moon's side.
  static void _waterTower(Canvas c, Offset roof, double s) {
    Offset at(double dx, double dy) => Offset(roof.dx + dx * s, roof.dy + dy * s);
    final iron = const Color(0xff1e1a26);
    final thin = math.max(.6, s * .034);
    // Legs and bracing, the far ones fainter.
    final legs = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .07
      ..color = iron;
    final back = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .05
      ..color = Sketch.fade(iron, .6);
    for (final dx in const [-.26, .26]) {
      c.drawLine(at(dx, .1), at(dx, -.62), back);
    }
    c.drawLine(at(0, -.62), at(0, .1), back..strokeWidth = s * .045);
    final brace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thin
      ..color = iron;
    c.drawLine(at(-.42, -.62), at(.42, -.02), brace);
    c.drawLine(at(.42, -.62), at(-.42, -.02), brace);
    c.drawLine(at(-.42, -.32), at(.42, -.32), brace);
    for (final dx in const [-.42, .42]) {
      c.drawLine(at(dx, .1), at(dx * .97, -.62), legs);
    }
    // The barrel: slightly tapered and bulging, staved, lit on the right.
    final bulge = s * .03;
    final tank = Path()
      ..moveTo(roof.dx - s * .5, roof.dy - s * .62)
      ..quadraticBezierTo(
        roof.dx - s * .5 - bulge,
        roof.dy - s * 1.145,
        roof.dx - s * .47,
        roof.dy - s * 1.67,
      )
      ..lineTo(roof.dx + s * .47, roof.dy - s * 1.67)
      ..quadraticBezierTo(
        roof.dx + s * .5 + bulge,
        roof.dy - s * 1.145,
        roof.dx + s * .5,
        roof.dy - s * .62,
      )
      ..close();
    c.drawPath(
      tank,
      Paint()
        ..shader = Gradient.linear(
          Offset(roof.dx - s * .5, 0),
          Offset(roof.dx + s * .5, 0),
          const [Color(0xff36292f), Color(0xff5a4548), Color(0xff85686a), Color(0xff6a5153)],
          const [0, .5, .88, 1],
        ),
    );
    final staves = Path();
    for (var i = 1; i < 10; i++) {
      final f = -1 + 2 * i / 10;
      staves
        ..moveTo(roof.dx + f * s * .5, roof.dy - s * .62)
        ..lineTo(roof.dx + f * s * .47, roof.dy - s * 1.67);
    }
    c.drawPath(
      staves,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .012)
        ..color = Sketch.fade(iron, .3),
    );
    // Iron hoops with a lit edge, bulging with the staves.
    final hoop = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .06
      ..color = iron;
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, s * .018)
      ..color = Sketch.fade(_roofMoon, .32);
    for (final t in const [.1, .36, .62, .88]) {
      final y = -.62 - 1.05 * t;
      final hw = .5 - .03 * t + .03 * 4 * t * (1 - t) * .5;
      c.drawLine(at(-hw, y), at(hw, y), hoop);
      c.drawLine(at(hw * .1, y - .03), at(hw, y - .03), glint);
    }
    // Feed pipe with its valve wheel.
    c.drawLine(
      at(-.1, -.62),
      at(-.1, .1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .05
        ..color = iron,
    );
    c.drawCircle(
      at(-.1, -.2),
      s * .06,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .02)
        ..color = iron,
    );
    // Conical roof of tar paper with a brim and a finial.
    final cone = Sketch.poly([-.56, -1.67, 0, -2.17, .56, -1.67], at: roof, s: s);
    c.drawPath(
      cone,
      Paint()
        ..shader = Gradient.linear(
          Offset(roof.dx - s * .56, 0),
          Offset(roof.dx + s * .56, 0),
          const [Color(0xff2b2230), Color(0xff44364a), Color(0xff5e4d66)],
          const [0, .6, 1],
        ),
    );
    c.drawRect(
      Rect.fromLTRB(
        roof.dx - s * .57,
        roof.dy - s * 1.7,
        roof.dx + s * .57,
        roof.dy - s * 1.64,
      ),
      Paint()..color = const Color(0xff2a212f),
    );
    c.drawLine(
      at(0, -2.17),
      at(0, -2.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, s * .04)
        ..color = iron,
    );
    c.drawCircle(at(0, -2.3), s * .05, Paint()..color = iron);
  }

  /// A rooftop television aerial: mast, graduated crossbars and guy wires.
  static void _roofAntenna(
    Canvas c,
    double h,
    Offset foot,
    double ht, {
    double lean = 0,
    double alpha = 1,
  }) {
    final tip = foot + Offset(lean * ht, -ht);
    Offset up(double t) => Offset.lerp(foot, tip, t)!;
    final mast = Path()
      ..moveTo(foot.dx, foot.dy)
      ..lineTo(tip.dx, tip.dy);
    for (final (t, half) in const [(.42, .032), (.58, .029), (.72, .025), (.85, .02), (.97, .015)]) {
      final p = up(t);
      mast
        ..moveTo(p.dx - h * half, p.dy + h * half * .18)
        ..lineTo(p.dx + h * half, p.dy - h * half * .18);
    }
    c.drawPath(
      mast,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .0022)
        ..color = Sketch.fade(_roofInk, .95 * alpha),
    );
    final wires = Path();
    final anchor = up(.66);
    wires
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(foot.dx - h * .045, foot.dy)
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(foot.dx + h * .045, foot.dy);
    c.drawPath(
      wires,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0011)
        ..color = Sketch.fade(_roofInk, .6 * alpha),
    );
  }

  /// The washing line of a roof: (left post top, right post top, sag).
  static (Offset, Offset, double) _roofLine(Rect r, double h) => (
    Offset(r.left + r.width * .14, r.top - h * .048),
    Offset(r.left + r.width * .6, r.top - h * .042),
    h * .014,
  );

  /// The two posts and the sagging line; the washing itself is [_roofCloth].
  static void _roofLaundry(Canvas c, Rect r, double h) {
    final (a, b, sag) = _roofLine(r, h);
    final y = r.top + h * .008;
    final post = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, h * .0028)
      ..color = _roofInk;
    c.drawLine(Offset(a.dx, y), a, post);
    c.drawLine(Offset(b.dx, y), b, post);
    c.drawLine(Offset(a.dx, a.dy + h * .012), Offset(a.dx + h * .012, a.dy), post);
    c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sag * 2, b.dx, b.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0013)
        ..color = Sketch.fade(_roofInk, .85),
    );
  }

  /// Shirts, trousers and towels on a line from [a] to [b], swaying a little.
  static void _roofCloth(
    Canvas c,
    Offset a,
    Offset b,
    double sag,
    double h,
    double clock, {
    double scale = 1,
    double alpha = 1,
    double shadow = 0,
  }) {
    final paint = Paint();
    var i = 0;
    for (final (t, kind, color) in const [
      (.1, 0, Color(0xff9c7a8e)),
      (.23, 1, Color(0xff7f9cc0)),
      (.36, 2, Color(0xffc4b48a)),
      (.5, 0, Color(0xffe0d8ec)),
      (.63, 1, Color(0xff8fb09c)),
      (.78, 2, Color(0xffb87a7a)),
      (.9, 0, Color(0xffa8a0c8)),
    ]) {
      final u = Offset.lerp(a, b, t)!;
      // The quadratic through the post tops, sagging by [sag] at the middle.
      final y = u.dy + sag * 2 * t * (1 - t) * 2;
      final swing = math.sin(clock * 1.3 + i * 1.7) * h * .0026 * scale;
      final s = h * scale;
      paint.color = Sketch.fade(Sketch.mix(color, _roofInk, shadow), .88 * alpha);
      switch (kind) {
        case 0:
          c.drawPath(
            Path()
              ..moveTo(u.dx - s * .0095, y)
              ..lineTo(u.dx + s * .0095, y)
              ..lineTo(u.dx + s * .0058 + swing, y + s * .005)
              ..lineTo(u.dx + s * .0058 + swing, y + s * .017)
              ..lineTo(u.dx - s * .0058 + swing, y + s * .017)
              ..lineTo(u.dx - s * .0058 + swing, y + s * .005)
              ..close(),
            paint,
          );
        case 1:
          c.drawPath(
            Path()
              ..moveTo(u.dx - s * .006, y)
              ..lineTo(u.dx + s * .006, y)
              ..lineTo(u.dx + s * .0066 + swing, y + s * .02)
              ..lineTo(u.dx + s * .0012 + swing, y + s * .02)
              ..lineTo(u.dx + swing * .5, y + s * .008)
              ..lineTo(u.dx - s * .0012 + swing, y + s * .02)
              ..lineTo(u.dx - s * .0066 + swing, y + s * .02)
              ..close(),
            paint,
          );
        default:
          c.drawPath(
            Path()
              ..moveTo(u.dx - s * .0085, y)
              ..lineTo(u.dx + s * .0085, y)
              ..lineTo(u.dx + s * .0085 + swing, y + s * .019)
              ..lineTo(u.dx - s * .0085 + swing, y + s * .019)
              ..close(),
            paint,
          );
      }
      i++;
    }
  }

  /// A pigeon standing at [foot], facing [dir] (1 right, -1 left).
  static void _roofPigeon(Canvas c, double h, Offset foot, double dir) {
    final body = Paint()..color = const Color(0xff5f5d7c);
    c.drawPath(
      Path()
        ..moveTo(foot.dx - dir * h * .007, foot.dy - h * .0065)
        ..lineTo(foot.dx - dir * h * .0145, foot.dy - h * .0015)
        ..lineTo(foot.dx - dir * h * .0135, foot.dy - h * .0085)
        ..close(),
      body,
    );
    c.drawOval(
      Rect.fromCenter(
        center: foot + Offset(0, -h * .0055),
        width: h * .0155,
        height: h * .0088,
      ),
      body,
    );
    c.drawCircle(
      foot + Offset(dir * h * .0068, -h * .0095),
      h * .0033,
      Paint()..color = const Color(0xff484666),
    );
    c.drawOval(
      Rect.fromCenter(
        center: foot + Offset(dir * h * .003, -h * .0058),
        width: h * .008,
        height: h * .005,
      ),
      Paint()..color = Sketch.fade(const Color(0xffa9a6c8), .55),
    );
    c.drawLine(
      foot + Offset(0, -h * .001),
      foot + Offset(0, h * .001),
      Paint()
        ..strokeWidth = math.max(.5, h * .0012)
        ..color = const Color(0xff2a2233),
    );
  }

  /// A wooden pigeon coop with a wire-mesh front, and pigeons around it, plus
  /// a string of party lights across the rest of the roof.
  static void _roofCoop(Canvas c, Rect r, double h) {
    final y = r.top + h * .008;
    final x = r.left + r.width * .07, w = h * .085, ht = h * .04;
    final wood = const Color(0xff5c4753);
    c.drawRect(Rect.fromLTWH(x, y - ht, w, ht), Paint()..color = wood);
    c.drawRect(
      Rect.fromLTWH(x + w * .86, y - ht, w * .14, ht),
      Paint()..color = Sketch.mix(wood, _roofGlow, .16),
    );
    final planks = Path();
    for (var px = x + h * .006; px < x + w; px += h * .0075) {
      planks
        ..moveTo(px, y - ht)
        ..lineTo(px, y);
    }
    c.drawPath(
      planks,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0011)
        ..color = Sketch.fade(_roofInk, .25),
    );
    // Mesh front and an arched pigeon door with its ramp.
    final mesh = Rect.fromLTWH(x + w * .08, y - ht * .86, w * .52, ht * .6);
    c.drawRect(mesh.inflate(h * .0018), Paint()..color = _roofInk);
    c.drawRect(mesh, Paint()..color = const Color(0xff1f1a2b));
    final wire = Path();
    for (var mx = mesh.left + h * .005; mx < mesh.right; mx += h * .005) {
      wire
        ..moveTo(mx, mesh.top)
        ..lineTo(mx, mesh.bottom);
    }
    for (var my = mesh.top + h * .005; my < mesh.bottom; my += h * .005) {
      wire
        ..moveTo(mesh.left, my)
        ..lineTo(mesh.right, my);
    }
    c.drawPath(
      wire,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.4, h * .0009)
        ..color = Sketch.fade(const Color(0xff8b83a8), .55),
    );
    c.drawPath(
      Path()
        ..moveTo(x + w * .7, y)
        ..lineTo(x + w * .7, y - ht * .42)
        ..arcToPoint(
          Offset(x + w * .84, y - ht * .42),
          radius: Radius.circular(w * .07),
        )
        ..lineTo(x + w * .84, y)
        ..close(),
      Paint()..color = _roofInk,
    );
    c.drawLine(
      Offset(x + w * .7, y - h * .002),
      Offset(x + w * .5, y + h * .004),
      Paint()
        ..strokeWidth = math.max(.6, h * .0018)
        ..color = _roofInk,
    );
    // Shed roof of tar paper, sloping down to the front, with a lit edge.
    c.drawPath(
      Sketch.poly([
        x - w * .07,
        y - ht,
        x + w * 1.07,
        y - ht,
        x + w * 1.07,
        y - ht - h * .008,
        x - w * .07,
        y - ht - h * .015,
      ]),
      Paint()..color = const Color(0xff2b2432),
    );
    c.drawLine(
      Offset(x - w * .07, y - ht - h * .015),
      Offset(x + w * 1.07, y - ht - h * .008),
      Paint()
        ..strokeWidth = math.max(.6, h * .0016)
        ..color = Sketch.fade(_roofGlow, .5),
    );
    _roofPigeon(c, h, Offset(x + w * .22, y - ht - h * .012), 1);
    _roofPigeon(c, h, Offset(x + w * .74, y - ht - h * .009), -1);
    _roofPigeon(c, h, Offset(x + w * 1.24, y - h * .002), -1);
    _roofPigeon(c, h, Offset(x + w * 1.36, y - h * .002), 1);
    _roofLights(c, r, h);
  }

  /// A string of small round party lights on two poles, in pale colours.
  static void _roofLights(Canvas c, Rect r, double h) {
    final y = r.top + h * .008;
    final a = Offset(r.left + r.width * .5, r.top - h * .05);
    final b = Offset(r.left + r.width * .95, r.top - h * .04);
    final sag = h * .016;
    final post = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, h * .0026)
      ..color = _roofInk;
    c.drawLine(Offset(a.dx, y), a, post);
    c.drawLine(Offset(b.dx, y), b, post);
    final wire = Path()..moveTo(a.dx, a.dy);
    for (var i = 1; i <= 12; i++) {
      final t = i / 12;
      final p = Offset.lerp(a, b, t)!;
      wire.lineTo(p.dx, p.dy + sag * 4 * t * (1 - t));
    }
    c.drawPath(
      wire,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0012)
        ..color = Sketch.fade(_roofInk, .85),
    );
    const tints = [Color(0xfffff0c8), Color(0xffffb6cf), Color(0xffb9dcff), Color(0xffffe08a)];
    for (var i = 1; i < 10; i++) {
      final t = i / 10;
      final p = Offset.lerp(a, b, t)! + Offset(0, sag * 4 * t * (1 - t) + h * .003);
      final tint = tints[i % tints.length];
      c.drawCircle(p, h * .0075, Paint()..color = Sketch.fade(tint, .13));
      c.drawCircle(p, h * .0026, Paint()..color = Sketch.fade(tint, .9));
    }
  }

  /// A stair bulkhead with a lit door, a whirlybird vent and a satellite dish.
  static void _roofBulkhead(Canvas c, Rect r, double h, Color base) {
    final y = r.top + h * .008;
    final x = r.left + r.width * .16, w = h * .07, ht = h * .042;
    final wall = Sketch.mix(base, _roofInk, .22);
    c.drawRect(Rect.fromLTWH(x, y - ht, w, ht), Paint()..color = wall);
    c.drawRect(
      Rect.fromLTWH(x + w * .84, y - ht, w * .16, ht),
      Paint()..color = Sketch.mix(wall, _roofGlow, .16),
    );
    final courses = Path();
    for (var cy = y - ht + h * .006; cy < y; cy += h * .0085) {
      courses
        ..moveTo(x, cy)
        ..lineTo(x + w, cy);
    }
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0013)
        ..color = Sketch.fade(_roofInk, .28),
    );
    c.drawPath(
      Sketch.poly([
        x - w * .07,
        y - ht,
        x + w * 1.07,
        y - ht,
        x + w * 1.07,
        y - ht - h * .007,
        x - w * .07,
        y - ht - h * .012,
      ]),
      Paint()..color = const Color(0xff2b2634),
    );
    c.drawLine(
      Offset(x - w * .07, y - ht - h * .012),
      Offset(x + w * 1.07, y - ht - h * .007),
      Paint()
        ..strokeWidth = math.max(.6, h * .0016)
        ..color = Sketch.fade(_roofGlow, .45),
    );
    // The steel door with a wall lamp above it and its spill of light.
    final door = Rect.fromLTWH(x + w * .3, y - ht * .74, w * .32, ht * .74);
    c.drawRect(door.inflate(h * .0015), Paint()..color = _roofInk);
    c.drawRect(door, Paint()..color = const Color(0xff33405a));
    c.drawRect(
      Rect.fromLTWH(door.left, door.top, door.width * .3, door.height),
      Paint()..color = Sketch.fade(_roofMoon, .1),
    );
    final lamp = Offset(door.center.dx, door.top - h * .0055);
    c.drawPath(
      Sketch.poly([
        lamp.dx - h * .002,
        lamp.dy,
        lamp.dx + h * .002,
        lamp.dy,
        lamp.dx + h * .012,
        door.top + h * .002,
        lamp.dx - h * .012,
        door.top + h * .002,
      ]),
      Paint()..color = Sketch.fade(_roofLamp, .12),
    );
    c.drawCircle(lamp, h * .0022, Paint()..color = Sketch.fade(_roofLamp, .85));
    // A whirlybird ventilator on a short stack.
    final vx = r.left + r.width * .66;
    c.drawRect(
      Rect.fromLTWH(vx - h * .003, y - h * .02, h * .006, h * .02),
      Paint()..color = const Color(0xff2a2a3f),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(vx, y - h * .0335), width: h * .025, height: h * .028),
      Paint()..color = const Color(0xff3c3f5a),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(vx + h * .004, y - h * .0335), width: h * .012, height: h * .026),
      Paint()..color = Sketch.fade(_roofMoon, .16),
    );
    final vanes = Path();
    for (final k in const [-.6, -.2, .2, .6]) {
      vanes
        ..moveTo(vx + k * h * .0125, y - h * .0195)
        ..quadraticBezierTo(vx + k * h * .015, y - h * .0335, vx + k * h * .006, y - h * .0475);
    }
    c.drawPath(
      vanes,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0011)
        ..color = Sketch.fade(_roofInk, .5),
    );
    // A small satellite dish tilted at the sky.
    final dx = r.left + r.width * .88;
    c.drawLine(
      Offset(dx, y),
      Offset(dx, y - h * .024),
      Paint()
        ..strokeWidth = math.max(.7, h * .0022)
        ..color = _roofInk,
    );
    c.save();
    c.translate(dx, y - h * .028);
    c.rotate(-.55);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: h * .026, height: h * .013),
      Paint()..color = const Color(0xff7a7e9e),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(0, h * .0008), width: h * .019, height: h * .009),
      Paint()..color = const Color(0xff4a4d6c),
    );
    c.restore();
  }

  /// Where the neon sign of a roof glows.
  static Offset _roofNeonAt(Rect r, double h) =>
      Offset(r.left + r.width * .22, r.top - h * .052);

  /// A vertical rooftop blade sign spelling HOTEL in pink neon on a dark
  /// panel, with two gooseneck vents beside it.
  static void _roofNeon(Canvas c, Rect r, double h) {
    final y = r.top + h * .008;
    final mid = _roofNeonAt(r, h);
    final pw = h * .036, ph = h * .096;
    final panel = Rect.fromCenter(center: mid, width: pw, height: ph);
    // The glow it throws on the rain-wet air.
    c.drawCircle(
      mid,
      h * .07,
      Paint()
        ..shader = Gradient.radial(
          mid,
          h * .07,
          [Sketch.fade(_roofNeonPink, .3), Sketch.fade(_roofNeonPink, .1), Sketch.fade(_roofNeonPink, 0)],
          const [0, .4, 1],
        ),
    );
    final post = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, h * .0026)
      ..color = _roofInk;
    for (final f in const [.2, .8]) {
      c.drawLine(Offset(panel.left + pw * f, panel.bottom), Offset(panel.left + pw * f, y), post);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(panel, Radius.circular(h * .003)),
      Paint()..color = const Color(0xff1d1728),
    );
    final tube = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0024)
      ..color = _roofNeonPink;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, h * .0016)
      ..color = Sketch.fade(const Color(0xff9aa8ff), .8);
    c.drawRRect(
      RRect.fromRectAndRadius(panel.deflate(h * .0032), Radius.circular(h * .002)),
      border,
    );
    // H, O, T, E, L stacked, each in a small box.
    final bw = h * .017, bh = h * .0135, gap = h * .0037;
    final top = panel.top + (ph - (bh * 5 + gap * 4)) / 2;
    final glyphs = Path();
    for (var i = 0; i < 5; i++) {
      final l = mid.dx - bw / 2, rt = mid.dx + bw / 2;
      final t = top + i * (bh + gap), b = t + bh, m = (t + b) / 2;
      switch (i) {
        case 0:
          glyphs
            ..moveTo(l, t)
            ..lineTo(l, b)
            ..moveTo(rt, t)
            ..lineTo(rt, b)
            ..moveTo(l, m)
            ..lineTo(rt, m);
        case 1:
          glyphs.addRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(l, t, rt, b), Radius.circular(bw * .35)),
          );
        case 2:
          glyphs
            ..moveTo(l, t)
            ..lineTo(rt, t)
            ..moveTo(mid.dx, t)
            ..lineTo(mid.dx, b);
        case 3:
          glyphs
            ..moveTo(rt, t)
            ..lineTo(l, t)
            ..lineTo(l, b)
            ..lineTo(rt, b)
            ..moveTo(l, m)
            ..lineTo(rt - bw * .2, m);
        default:
          glyphs
            ..moveTo(l, t)
            ..lineTo(l, b)
            ..lineTo(rt, b);
      }
    }
    c.drawPath(glyphs, tube);
    // Two gooseneck vents on the roof beside it.
    final vent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, h * .0032)
      ..color = _roofInk;
    for (final (f, ht) in const [(.62, .034), (.8, .026)]) {
      final vx = r.left + r.width * f;
      c.drawPath(
        Path()
          ..moveTo(vx, y)
          ..lineTo(vx, y - h * ht)
          ..quadraticBezierTo(vx, y - h * (ht + .012), vx + h * .009, y - h * (ht + .006)),
        vent,
      );
    }
  }

  /// Per-frame life on the rooftops: a light switching on and off in each
  /// building, television flicker, chimney steam, washing on the line and the
  /// slow breath of the neon.
  static void _roofLive(Canvas c, SceneFrame f, int copy) {
    final h = f.h, t = f.clock;
    final puff = Paint();
    var left = 0.0;
    for (var i = 0; i < _roofs.length; i++) {
      final (width, roof, facade, top) = _roofs[i];
      final r = Rect.fromLTRB(left * h, roof * h, (left + width) * h, h * .96);
      left += width;
      final rows = _roofRows(r, h, facade);
      if (rows > 0) {
        final (row, col) = _roofPick(i, rows, _roofCols(width, facade));
        final on = ((t / 4.3 + i * .37 + copy * .5).floor() + i).isEven;
        if (on) {
          final win = _roofWin(r, h, facade, row, col);
          if (i % 3 == 1) {
            // Television light drifts between two blues.
            final k = .5 + .5 * math.sin(t * 1.9 + i);
            _roofLit(
              c,
              win,
              h,
              facade == 2,
              Color.lerp(const Color(0xff5c82c4), _roofTv, k)!,
              Color.lerp(const Color(0xff4a6aa8), const Color(0xff5f86c8), k)!,
            );
          } else {
            _roofLit(c, win, h, facade == 2, _roofLamp, _roofLampLow);
          }
        }
      }
      // Steam rises from the chimney, swells, thins and drifts in the wind.
      final vent = _roofSteamAt(r, h, top, i);
      if (vent != null) {
        for (var k = 0; k < 5; k++) {
          final age = (t * .2 + k / 5 + i * .13) % 1;
          final sway = math.sin(t * .8 + k * 1.3 + i) * .014 * age;
          final p = vent + Offset(h * (sway - .035 * age), -age * h * .17);
          final a = .34 * (1 - age) * math.min(1.0, age * 5);
          final rad = h * (.009 + age * .03);
          // Three stacked discs make a soft-edged puff without a shader.
          for (final (scale, weight) in const [(1.0, .5), (.66, .55), (.36, .6)]) {
            puff.color = Sketch.fade(_roofSteam, a * weight);
            c.drawCircle(p + Offset(rad * (1 - scale) * .3, 0), rad * scale, puff);
          }
        }
      }
      if (top == 2) {
        final (a, b, sag) = _roofLine(r, h);
        _roofCloth(c, a, b, sag, h, t);
      }
      if (top == 4) {
        final breath = .5 + .5 * math.sin(t * 1.1);
        c.drawCircle(
          _roofNeonAt(r, h),
          h * .05,
          Paint()..color = Sketch.fade(_roofNeonPink, .04 + .05 * breath),
        );
      }
    }
  }

  /// A cast-iron gooseneck vent pipe bent over at the top.
  static void _roofGooseneck(
    Canvas c,
    double h,
    Offset foot,
    double ht,
    double alpha,
  ) {
    c.drawPath(
      Path()
        ..moveTo(foot.dx, foot.dy)
        ..lineTo(foot.dx, foot.dy - ht)
        ..quadraticBezierTo(
          foot.dx,
          foot.dy - ht - h * .022,
          foot.dx + h * .016,
          foot.dy - ht - h * .01,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.9, h * .0058)
        ..color = Sketch.fade(_roofInk, alpha),
    );
    c.drawCircle(
      Offset(foot.dx + h * .016, foot.dy - ht - h * .01),
      h * .0048,
      Paint()..color = Sketch.fade(_roofInk, alpha),
    );
  }

  static final _roofJoints = <double, Path>{};

  /// The vertical joints of the parapet brickwork across one repeat, cached
  /// per viewport height.
  static Path _roofJointPath(double h, double span) {
    final cached = _roofJoints[h];
    if (cached != null) return cached;
    if (_roofJoints.length > 6) _roofJoints.clear();
    final path = Path();
    final course = h * .0085, brick = h * .03;
    for (var row = 0; row < 8; row++) {
      final y = h * .943 + row * course;
      var k = 0;
      for (var x = row.isOdd ? brick / 2 : 0.0; x < span; x += brick, k++) {
        path
          ..moveTo(x, y)
          ..lineTo(x, y + course);
      }
    }
    return _roofJoints[h] = path;
  }

  /// The nearest parapet: brick front and wet coping across the bottom, rain
  /// splashing on it, drains, and the dark clutter of the roof behind it.
  static void _roofOverlay(
    Canvas c,
    SceneFrame f,
    double presence,
    double span,
  ) {
    final h = f.h, t = f.clock;
    // Clutter standing behind the parapet, in near-black silhouette.
    // In a crossing they settle behind the parapet (and fade late / in late),
    // so they do not stand alone before the roofs have risen or after they
    // have sunk.
    final settle = presence * presence * presence;
    final alpha = .96 * settle;
    final y = h * .958;
    c.save();
    if (!f.reducedMotion) c.translate(0, h * .12 * (1 - settle));
    _roofAntenna(c, h, Offset(h * .61, y), h * .17, lean: .03, alpha: alpha);
    _roofAntenna(c, h, Offset(h * .69, y), h * .1, lean: -.06, alpha: alpha);
    _roofGooseneck(c, h, Offset(h * 1.8, y), h * .062, alpha);
    _roofGooseneck(c, h, Offset(h * 1.86, y), h * .04, alpha);
    _roofChimney(
      c,
      h,
      Offset(h * 2.42, y),
      h * .04,
      h * .09,
      _roofBricks[2],
      alpha: settle,
    );
    c.restore();
    // The parapet's brick front over the ground, coping on top.
    final front = Rect.fromLTRB(0, h * .943, span, h * 1.01);
    c.drawRect(
      front,
      Paint()..color = Sketch.fade(const Color(0xff45324a), .78 * presence),
    );
    c.drawPath(
      _roofJointPath(h, span),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0013)
        ..color = Sketch.fade(_roofInk, .2 * presence),
    );
    final courses = Path();
    for (var k = 0; k < 8; k++) {
      final cy = h * .943 + k * h * .0085;
      courses
        ..moveTo(0, cy)
        ..lineTo(span, cy);
    }
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0014)
        ..color = Sketch.fade(_roofInk, .28 * presence),
    );
    final coping = Rect.fromLTRB(0, h * .9345, span, h * .9432);
    c.drawRect(
      coping,
      Paint()..color = Sketch.fade(const Color(0xff5d5883), presence),
    );
    c.drawLine(
      Offset(0, h * .9349),
      Offset(span, h * .9349),
      Paint()
        ..strokeWidth = math.max(.6, h * .0017)
        ..color = Sketch.fade(const Color(0xffbdb7df), .55 * presence),
    );
    c.drawLine(
      Offset(0, h * .9434),
      Offset(span, h * .9434),
      Paint()
        ..strokeWidth = math.max(.6, h * .0016)
        ..color = Sketch.fade(_roofInk, .5 * presence),
    );
    // Scuppers with rain stains streaking down the brick below them.
    for (final sx in const [.9, 1.75, 2.62]) {
      final x = h * sx;
      for (var k = 0; k < 3; k++) {
        c.drawRect(
          Rect.fromLTWH(x - h * .006, h * .952, h * .012, h * (.03 - k * .009)),
          Paint()..color = Sketch.fade(_roofInk, .07 * presence),
        );
      }
      c.drawRect(
        Rect.fromLTWH(x - h * .007, h * .9432, h * .014, h * .0055),
        Paint()..color = Sketch.fade(const Color(0xff2e2740), .8 * presence),
      );
    }
    // Raindrops bursting on the wet coping.
    final crown = Paint();
    for (var i = 0; i < 7; i++) {
      final age = (t * .9 + Sketch.hash(i + 910) * 4) % 1;
      final x = span * Sketch.hash(i + 900);
      final half = h * (.003 + .008 * age);
      final lift = h * .0075 * math.sin(age * math.pi);
      crown.color = Sketch.fade(const Color(0xffdedcf5), .5 * (1 - age) * presence);
      c.drawCircle(Offset(x - half, h * .9345 - lift), h * .0016, crown);
      c.drawCircle(Offset(x + half, h * .9345 - lift), h * .0016, crown);
      c.drawCircle(Offset(x, h * .9345 - lift * 1.3), h * .0014, crown);
    }
  }
}
