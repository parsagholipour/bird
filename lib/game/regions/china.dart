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
    radius: .078,
    disc: Color(0xffee6f57),
    glow: Color(0xffffc4a0),
    halo: .62,
    strength: .5,
  );

  static final _weather = Weather(Weather.of([(Mote.petal, 26)]));
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
      Color(0xffdcc0cb),
      Color(0xff7385a8),
      Color(0x99ffe6d6),
      rimWidth: .0022,
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
    Depth.low =>
      .778 +
          Sketch.waves(x, const [(3.0, .008, .4), (1.5, .006, 1.3), (.6, .0025, 2.2)]),
    Depth.near =>
      .925 - .03 * Sketch.humps(x / 1.7 + .2) - .01 * Sketch.humps(x / .425),
  };

  @override
  double period(Depth d) => d == Depth.low ? 3.0 : 3.4;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .46,
    Depth.mid => .45,
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
        _riverBank(c, h);
      case Depth.near:
        _shoreFeatures(c, h);
    }
  }

  double _midRidge(double x) => ridge(Depth.mid, x, 0);

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d == Depth.mid) _pagodaLive(c, f);
    if (d == Depth.low) _riverLive(c, f);
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        // Mist banks wrap the feet of the karst towers.
        _karstMist(c, f, presence);
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
        _shoreOverlay(c, f, presence);
      case Depth.low:
        _riverWater(c, f, presence);
    }
  }

  // The sun's path of light is painted with the water in overlay(), so the raft stands in front of it.

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // Seconds into China's own leg, so every visit composes the same dusk,
    // or into a campaign level.
    final t = f.reducedMotion
        ? 0.0
        : f.held
        ? f.clock
        : (f.clock % WorldTour.loop) - WorldRegion.china.index * WorldTour.leg;
    // The sun's dressing rides the compositor's sun while the tour hands over.
    final blend = f.blend;
    final sun = blend.crossing
        ? SkyLight.lerp(
            RegionScene.of(blend.from).light,
            RegionScene.of(blend.to).light,
            blend.stage(0, 1),
          )
        : light;
    final at = Offset(w * sun.at.dx, h * sun.at.dy), r = sun.radius * h;
    _duskHorizon(c, w, h, presence);
    _duskSun(c, at, r, t, presence);
    _duskCirrus(c, w, h, t, presence);
    _duskStrata(c, w, h, t, presence);
    _duskSunBars(c, at, r, t, presence);
    _duskMoon(c, w, h, presence);
    _duskLanterns(c, w, h, t, presence, held: f.held);
    _duskBanks(c, w, h, t, presence);
    _duskRuyi(c, w, h, t, presence);
    _duskKite(c, w, h, t, presence);
    _duskGeese(c, w, h, t, presence, held: f.held);
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  // Karst ------------------------------------------------------------------

  /// Haze of each ink-wash rank, farthest first.
  static const _karstHaze = [.78, .64, .48, .3];
  static const _karstShadeAlpha = [.1, .18, .24, .3];
  static const _karstRimAlpha = [.3, .42, .5, .6];
  static const _karstBody = Color(0xff8c88a6);
  static const _karstLit = Color(0xffe8c4c6);
  static const _karstShade = Color(0xff5b6088);
  static const _karstVeg = Color(0xff4d7466);
  static const _karstVegLit = Color(0xff8fae86);
  static const _karstRim = Color(0xfffde6d4);
  static const _karstMistColor = Color(0xfff8d6c4);

  /// Karst towers per rank, farthest rank first: (x as a fraction of w, crown
  /// y, half width in h, crown share of the height, crown squareness, lean,
  /// features: 1 cave, 2 waterfall, 4 pavilion, 8 companion summit, 16 lone
  /// pine, 64 tiny far pavilion). They leave a notch for the sun.
  static const _karstRanks = <List<(double, double, double, double, double, double, int)>>[
    [
      (-.03, .30, .06, .34, 1.6, .1, 0),
      (.06, .22, .045, .38, 1.4, -.12, 0),
      (.15, .33, .07, .3, 1.8, .05, 0),
      (.25, .24, .05, .36, 1.5, .14, 0),
      (.33, .34, .065, .28, 1.9, -.06, 0),
      (.42, .26, .05, .34, 1.5, .08, 0),
      (.5, .36, .06, .3, 1.8, 0.0, 0),
      (.56, .4, .05, .3, 1.9, 0.0, 0),
      (.665, .46, .09, .24, 2.2, 0.0, 0),
      (.75, .27, .05, .36, 1.5, .12, 0),
      (.81, .36, .06, .3, 1.8, -.08, 0),
      (.9, .24, .05, .36, 1.5, .06, 0),
      (.98, .33, .065, .28, 1.9, 0.0, 0),
      (1.07, .26, .05, .34, 1.5, -.1, 0),
      (1.17, .35, .07, .3, 1.8, .05, 0),
      (1.27, .25, .05, .36, 1.5, .1, 0),
      (1.37, .33, .06, .3, 1.8, 0.0, 0),
    ],
    [
      (0.0, .36, .06, .3, 1.7, -.08, 0),
      (.09, .29, .05, .34, 1.5, .12, 0),
      (.19, .38, .07, .28, 1.9, 0.0, 0),
      (.29, .31, .05, .34, 1.6, -.14, 64),
      (.37, .4, .06, .28, 1.8, .06, 0),
      (.47, .34, .05, .34, 1.5, .1, 0),
      (.54, .44, .06, .26, 2.0, 0.0, 0),
      (.71, .45, .07, .24, 2.1, 0.0, 0),
      (.78, .31, .055, .34, 1.5, .1, 0),
      (.87, .4, .07, .28, 1.8, -.05, 8),
      (.94, .3, .05, .34, 1.5, .14, 0),
      (1.03, .38, .065, .28, 1.8, 0.0, 0),
      (1.12, .3, .05, .34, 1.5, -.1, 0),
      (1.22, .39, .07, .28, 1.8, .05, 0),
      (1.32, .32, .055, .34, 1.6, 0.0, 0),
    ],
    [
      (-.02, .4, .065, .3, 1.7, .08, 1),
      (.07, .34, .05, .34, 1.5, -.1, 0),
      (.14, .41, .065, .3, 1.8, .04, 0),
      (.24, .35, .05, .34, 1.6, .14, 0),
      (.31, .38, .07, .17, 3.0, .1, 4),
      (.4, .43, .065, .26, 1.9, -.06, 0),
      (.49, .36, .05, .34, 1.5, .1, 8),
      (.55, .45, .06, .26, 2.0, 0.0, 0),
      (.65, .49, .085, .22, 2.3, 0.0, 0),
      (.735, .36, .055, .32, 1.6, -.12, 2),
      (.82, .42, .065, .3, 1.8, .05, 0),
      (.9, .35, .05, .34, 1.5, .1, 0),
      (.97, .4, .065, .28, 1.7, 0.0, 1),
      (1.06, .43, .065, .3, 1.8, 0.0, 0),
      (1.15, .36, .055, .32, 1.6, -.1, 0),
      (1.25, .41, .065, .3, 1.8, 0.0, 0),
      (1.34, .37, .05, .32, 1.6, .05, 0),
    ],
    [
      (.03, .44, .07, .28, 1.8, .06, 2),
      (.11, .4, .05, .32, 1.6, -.12, 0),
      (.2, .46, .07, .3, 1.8, .05, 0),
      (.29, .42, .055, .3, 1.7, .12, 1),
      (.37, .39, .06, .3, 1.7, -.06, 16),
      (.46, .44, .065, .3, 1.8, -.04, 0),
      (.53, .37, .05, .34, 1.5, -.1, 3),
      (.6, .48, .065, .26, 2.0, 0.0, 0),
      (.7, .49, .07, .24, 2.1, 0.0, 0),
      (.78, .4, .06, .3, 1.7, .1, 9),
      (.87, .45, .065, .3, 1.8, .06, 0),
      (.95, .38, .05, .34, 1.5, -.1, 2),
      (1.03, .44, .065, .3, 1.8, .05, 2),
      (1.12, .41, .055, .3, 1.7, .1, 1),
      (1.21, .46, .065, .3, 1.8, -.05, 16),
      (1.3, .39, .055, .32, 1.6, -.08, 0),
      (1.38, .44, .06, .3, 1.8, 0.0, 0),
    ],
  ];

  /// Guilin karst in four ink-wash ranks, each paler and flatter than the
  /// next, with mist lying between the ranks.
  static void _karsts(Canvas c, double w, double h) {
    for (var r = 0; r < _karstRanks.length; r++) {
      final rank = _karstRanks[r];
      for (var i = 0; i < rank.length; i++) {
        final (fx, top, half, cap, pw, lean, feat) = rank[i];
        final cx = w * fx;
        final lit = cx < w * .64 ? 1.0 : -1.0;
        if (feat & 8 != 0) {
          // A lower companion summit shares the foot, on the sunward side.
          _karstTower(c, h, r, i + 40, cx + lit * half * h * 1.3, top + .07, half * .6, cap, pw, lit * .1, 0, lit);
        }
        _karstTower(c, h, r, i, cx, top, half, cap, pw, lean, feat, lit);
      }
      _karstMistBand(c, w, h, r);
    }
  }

  /// Half width of a tower at height fraction [t] (0 foot .. 1 crown): a
  /// steep, slightly concave wall with ledges, under a rounded crown.
  static double _karstHalf(double t, double half, double cap, double pw, double seed) {
    final tc = 1 - cap;
    double wall(double t) {
      final taper = 1 + .55 * math.pow(1 - t, 2.2) - .28 * t;
      final rough = .08 * math.sin(t * 8 + seed * 6.3) + .05 * math.sin(t * 15 + seed * 11) + .03 * math.sin(t * 23 + seed * 5);
      // A shoulder that swells out of one stretch of the wall.
      final s = t - (.3 + .3 * ((seed * 7.7) % 1));
      final shoulder = ((seed * 3.1) % 1) > .35 ? .15 * math.exp(-s * s / .006) : 0.0;
      return half * (taper + rough + shoulder);
    }

    if (t <= tc) return wall(t);
    final u = ((t - tc) / cap).clamp(0.0, 1.0);
    return wall(tc) * math.pow(1 - math.pow(u, pw), 1 / pw);
  }

  /// A smooth curve through [pts] (quadratic segments between midpoints).
  static void _karstCurve(Path p, List<Offset> pts, {bool move = true}) {
    if (pts.length < 2) return;
    if (move) {
      p.moveTo(pts.first.dx, pts.first.dy);
    } else {
      p.lineTo(pts.first.dx, pts.first.dy);
    }
    for (var i = 1; i < pts.length - 1; i++) {
      final m = Offset.lerp(pts[i], pts[i + 1], .5)!;
      p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
    }
    p.lineTo(pts.last.dx, pts.last.dy);
  }

  static void _karstTower(
    Canvas c,
    double h,
    int rank,
    int idx,
    double cx,
    double topFrac,
    double halfFrac,
    double cap,
    double pw,
    double lean,
    int feat,
    double lit,
  ) {
    final haze = _karstHaze[rank];
    final seed = rank * 1.7 + idx * 2.3;
    final key = 900 + rank * 100 + idx * 7;
    final base = h * .72, top = topFrac * h, hgt = base - top, half = halfFrac * h;
    double hw(double t, double sd) => _karstHalf(t, half, cap, pw, seed + sd);
    double off(double t) => lean * hgt * .3 * t * t;
    double edge(double t, double sg) => cx + sg * hw(t, sg > 0 ? 1.9 : 0) + off(t);
    final tc = 1 - cap;
    final ts = <double>[
      for (var i = 0; i <= 16; i++) tc * math.pow(i / 16, 1.3),
      for (var i = 1; i <= 10; i++) tc + cap * math.sin(i / 10 * math.pi / 2),
    ];
    final left = [for (final t in ts) Offset(edge(t, -1), base - t * hgt)];
    final right = [for (final t in ts) Offset(edge(t, 1), base - t * hgt)];
    final litSide = lit > 0 ? right : left, awaySide = lit > 0 ? left : right;
    final away = -lit;

    // Body: soft plane from the sunward side to the far side.
    final bodyC = _hazed(_karstBody, haze);
    final litC = _hazed(_karstLit, haze * .7);
    final shadeC = _hazed(_karstShade, haze);
    final body = Path();
    _karstCurve(body, left);
    _karstCurve(body, right.reversed.toList(), move: false);
    body.close();
    final span = half * 1.15;
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(cx + lit * span, 0),
          Offset(cx - lit * span, 0),
          [litC, bodyC, Sketch.mix(bodyC, shadeC, .5)],
          const [0, .4, 1],
        ),
    );

    // Shade plane down the far side, with a wavering inner edge.
    final outer = <Offset>[], inner = <Offset>[];
    for (var i = 3; i < ts.length; i++) {
      final t = ts[i];
      final e = awaySide[i];
      final f = .5 + .25 * math.sin(t * 7 + seed) + .1 * math.sin(t * 19 + seed * 3);
      outer.add(e);
      inner.add(Offset(e.dx - away * hw(t, away > 0 ? 1.9 : 0) * f, e.dy));
    }
    final plane = Path();
    _karstCurve(plane, outer);
    _karstCurve(plane, inner.reversed.toList(), move: false);
    plane.close();
    c.drawPath(plane, Paint()..color = Sketch.fade(shadeC, _karstShadeAlpha[rank]));

    // Limestone fluting: long vertical grooves that follow the wall, dark on
    // the far side and pale where the sun catches it.
    final dark = Path(), pale = Path();
    final strokes = const [3, 4, 8, 11][rank];
    for (var k = 0; k < strokes + 4; k++) {
      final onLit = k >= strokes;
      final j = Sketch.hash(key + k);
      final s = onLit ? -away * (.12 + .7 * j) : away * (.1 + .82 * (k + j) / strokes);
      final sd = s > 0 ? 1.9 : 0.0;
      final y0 = top + hgt * (.1 + .36 * Sketch.hash(key + 40 + k));
      final y1 = math.min(y0 + hgt * (.14 + .2 * Sketch.hash(key + 80 + k)), h * .64);
      final path = onLit ? pale : dark;
      for (var m = 0; m <= 3; m++) {
        final y = y0 + (y1 - y0) * m / 3;
        final t = ((base - y) / hgt).clamp(0.0, 1.0);
        final x = cx + off(t) + s * hw(t, sd) * .94;
        if (m == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    final line = math.max(.6, h * .0017);
    c.drawPath(
      dark,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = line
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Sketch.fade(shadeC, const [.2, .3, .34, .34][rank]),
    );
    c.drawPath(
      pale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = line
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Sketch.fade(_hazed(_karstRim, haze * .5), const [.2, .3, .34, .34][rank]),
    );

    // Rim light on the sunward edge, over the crown.
    final rim = <Offset>[
      for (var i = 6; i < ts.length; i++) litSide[i],
      ...[for (var i = ts.length - 2; i >= ts.length - 4; i--) awaySide[i]],
    ];
    final rimPath = Path();
    _karstCurve(rimPath, rim);
    c.drawPath(
      rimPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .0026)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Sketch.fade(_hazed(_karstRim, haze * .45), _karstRimAlpha[rank]),
    );

    if (rank >= 1) {
      _karstScrub(c, h, rank, key, cx, top, hgt, base, lit, left, right, hw, off, haze);
    }
    if (feat & 1 != 0) {
      _karstCave(c, h, key, cx, hgt, base, lit, hw, off, haze);
    }
    if (feat & 2 != 0) {
      _karstFall(c, h, cx + off(.8) + away * hw(.8, 0) * .35, top + h * .055, haze);
    }
    if (feat & 4 != 0) {
      _karstPavilion(c, Offset(cx + off(1), top + h * .004), h * .017, haze);
    }
    if (feat & 16 != 0) {
      _karstLonePine(c, Offset(cx + off(1) + lit * h * .004, top + h * .008), h * .034, haze, lit);
    }
    if (feat & 64 != 0) {
      _karstPavilion(c, Offset(cx + off(1), top + h * .003), h * .008, haze);
    }
  }

  /// A lone windswept pine on a summit, the classic shan shui accent.
  static void _karstLonePine(Canvas c, Offset at, double s, double haze, double lit) {
    final bark = _hazed(const Color(0xff4a3f43), haze * .5);
    final needles = _hazed(_karstVeg, haze * .35);
    c.drawPath(
      Path()
        ..moveTo(at.dx, at.dy)
        ..cubicTo(at.dx - lit * s * .12, at.dy - s * .3, at.dx + lit * s * .1, at.dy - s * .5, at.dx - lit * s * .04, at.dy - s * .85),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, s * .07)
        ..strokeCap = StrokeCap.round
        ..color = bark,
    );
    final crown = Path();
    for (final (dx, dy, w, k) in const [(.05, .5, .8, .16), (-.08, .72, .95, .17), (.06, .92, .7, .15)]) {
      crown.addOval(Rect.fromCenter(center: at + Offset(-lit * s * dx, -s * dy), width: s * w, height: s * k));
    }
    c.drawPath(crown, Paint()..color = needles);
  }

  /// Scrub and small trees: a hedge over the crown, tufts on the ledges.
  static void _karstScrub(
    Canvas c,
    double h,
    int rank,
    int key,
    double cx,
    double top,
    double hgt,
    double base,
    double lit,
    List<Offset> left,
    List<Offset> right,
    double Function(double, double) hw,
    double Function(double) off,
    double haze,
  ) {
    final veg = _hazed(_karstVeg, haze * .65), vegLit = _hazed(_karstVegLit, haze * .8);
    final alpha = const <double>[0, .55, .75, .9][rank];
    final depth = h * (.02 + .016 * Sketch.hash(key + 5));
    final cl = left.where((p) => p.dy <= top + depth * 1.8).toList();
    final cr = right.where((p) => p.dy <= top + depth * 1.8).toList();
    if (cl.length < 2 || cr.length < 2) return;
    // Foliage washes down from the crown and thins out into the rock.
    final cap = Path();
    _karstCurve(cap, cl);
    _karstCurve(cap, cr.reversed.toList(), move: false);
    cap.close();
    final hem = math.max(cl.first.dy, cr.first.dy);
    Paint wash(Color color) => Paint()
      ..shader = Gradient.linear(Offset(0, top), Offset(0, hem), [
        Sketch.fade(color, alpha),
        Sketch.fade(color, alpha * .85),
        Sketch.fade(color, 0),
      ], const [0, .5, 1]);
    final px = math.max(.8, h * .0028);
    c.drawPath(cap.shift(Offset(lit * px, -px * .7)), wash(vegLit));
    c.drawPath(cap, wash(veg));
    // Little trees roughen the skyline; dark dots of scrub fleck the slope.
    final bumps = Path(), lights = Path(), flecks = Path();
    final pts = [...cl.where((p) => p.dy <= top + depth), ...cr.where((p) => p.dy <= top + depth)];
    for (var i = 0; i < pts.length; i += 2) {
      final p = pts[i];
      final r = h * (.003 + .0035 * Sketch.hash(key + 20 + i));
      bumps.addOval(Rect.fromCircle(center: p + Offset(0, -r * .3), radius: r));
      lights.addOval(Rect.fromCircle(center: p + Offset(lit * r * .35, -r * .7), radius: r));
    }
    final n = const [0, 4, 8, 13][rank];
    for (var i = 0; i < n; i++) {
      final y = top + depth * (.25 + 1.5 * Sketch.hash(key + 200 + i));
      final t = ((base - y) / hgt).clamp(0.0, 1.0);
      final x = cx + off(t) + (Sketch.hash(key + 230 + i) * 2 - 1) * hw(t, 0) * .8;
      final r = h * (.0022 + .0022 * Sketch.hash(key + 260 + i));
      flecks.addOval(Rect.fromCenter(center: Offset(x, y), width: r * 2.2, height: r * 1.5));
    }
    c.drawPath(lights, Paint()..color = Sketch.fade(vegLit, alpha * .9));
    c.drawPath(bumps, Paint()..color = Sketch.fade(veg, alpha));
    c.drawPath(flecks, Paint()..color = Sketch.fade(veg, alpha * .8));
    // Shrubs cling to ledges in the wall.
    final tufts = Path(), tuftLights = Path();
    final count = const [0, 0, 1, 2][rank];
    for (var k = 0; k < count; k++) {
      final y = top + hgt * (.16 + .3 * Sketch.hash(key + 60 + k));
      if (y > h * .58) continue;
      final t = ((base - y) / hgt).clamp(0.0, 1.0);
      final sg = Sketch.hash(key + 70 + k) > .5 ? 1.0 : -1.0;
      final x = cx + off(t) + sg * hw(t, sg > 0 ? 1.9 : 0);
      final r = h * (.0035 + .003 * Sketch.hash(key + 80 + k));
      for (final (dx, dy, s) in const [(.2, 0.0, 1.0), (-.8, .5, .8), (.3, 1.0, .65)]) {
        final at = Offset(x - sg * r * dx, y + r * dy);
        tufts.addOval(Rect.fromCircle(center: at, radius: r * s));
        tuftLights.addOval(Rect.fromCircle(center: at + Offset(lit * r * .3, -r * .35), radius: r * s));
      }
    }
    c.drawPath(tuftLights, Paint()..color = Sketch.fade(vegLit, alpha));
    c.drawPath(tufts, Paint()..color = Sketch.fade(veg, alpha));
  }

  /// A dark cave mouth in the wall, brow of green above it.
  static void _karstCave(
    Canvas c,
    double h,
    int key,
    double cx,
    double hgt,
    double base,
    double lit,
    double Function(double, double) hw,
    double Function(double) off,
    double haze,
  ) {
    final y = h * (.49 + .03 * Sketch.hash(key + 90));
    final t = ((base - y) / hgt).clamp(0.0, 1.0);
    final r = h * .013;
    final x = cx + off(t) + lit * hw(t, 0) * .28;
    final ink = _hazed(const Color(0xff3e3f66), haze * .6);
    c.drawPath(
      Path()
        ..moveTo(x - r, y + r * .9)
        ..cubicTo(x - r * 1.05, y - r * .2, x - r * .5, y - r * 1.15, x + r * .1, y - r * 1.1)
        ..cubicTo(x + r * .8, y - r, x + r * 1.05, y, x + r, y + r * .9)
        ..close(),
      Paint()
        ..shader = Gradient.linear(Offset(0, y - r * 1.1), Offset(0, y + r * .9), [
          Sketch.fade(ink, .85),
          Sketch.fade(_hazed(const Color(0xff6a6790), haze * .6), .5),
        ]),
    );
    c.drawPath(
      Path()
        ..addOval(Rect.fromCircle(center: Offset(x - r * .55, y - r * 1.1), radius: r * .4))
        ..addOval(Rect.fromCircle(center: Offset(x + r * .35, y - r * 1.25), radius: r * .5))
        ..addOval(Rect.fromCircle(center: Offset(x + r * 1.05, y - r * .8), radius: r * .36)),
      Paint()..color = Sketch.fade(_hazed(_karstVeg, haze), .8),
    );
  }

  /// A thin waterfall thread down a shaded wall, with spray at its foot.
  static void _karstFall(Canvas c, double h, double x, double y0, double haze) {
    final y1 = y0 + h * .1;
    final silk = _hazed(const Color(0xffeaf3f4), haze * .5);
    final thread = Path()
      ..moveTo(x, y0)
      ..cubicTo(x + h * .004, y0 + h * .03, x - h * .004, y0 + h * .06, x + h * .001, y1);
    c.drawPath(
      thread,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .006
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(silk, .18),
    );
    c.drawPath(
      thread,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .0022)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(silk, .62),
    );
    Sketch.mist(c, Rect.fromCenter(center: Offset(x, y1), width: h * .06, height: h * .03), silk, .75);
  }

  /// A small temple pavilion on a summit: red columns, curved dark roof.
  static void _karstPavilion(Canvas c, Offset at, double s, double haze) {
    final roof = _hazed(const Color(0xff45605e), haze * .8);
    final column = _hazed(const Color(0xffb5493c), haze * .8);
    final gold = _hazed(const Color(0xffe0b24f), haze * .6);
    // A stone plinth and three columns.
    c.drawRect(
      Rect.fromLTRB(at.dx - s * 1.2, at.dy - s * .3, at.dx + s * 1.2, at.dy + s * .6),
      Paint()..color = _hazed(const Color(0xff9a9290), haze * .8),
    );
    for (final dx in const [-.8, 0.0, .8]) {
      c.drawRect(
        Rect.fromLTRB(at.dx + dx * s - s * .09, at.dy - s * 1.3, at.dx + dx * s + s * .09, at.dy - s * .3),
        Paint()..color = column,
      );
    }
    c.drawPath(
      Path()
        ..moveTo(at.dx - s * 2.1, at.dy - s * 1.75)
        ..quadraticBezierTo(at.dx - s * 1.2, at.dy - s * 1.45, at.dx - s * .9, at.dy - s * 1.85)
        ..quadraticBezierTo(at.dx - s * .3, at.dy - s * 2.4, at.dx, at.dy - s * 2.65)
        ..quadraticBezierTo(at.dx + s * .3, at.dy - s * 2.4, at.dx + s * .9, at.dy - s * 1.85)
        ..quadraticBezierTo(at.dx + s * 1.2, at.dy - s * 1.45, at.dx + s * 2.1, at.dy - s * 1.75)
        ..lineTo(at.dx + s * 1.3, at.dy - s * 1.25)
        ..lineTo(at.dx - s * 1.3, at.dy - s * 1.25)
        ..close(),
      Paint()..color = roof,
    );
    c.drawCircle(at + Offset(0, -s * 2.75), s * .13, Paint()..color = gold);
    // Shrubs gather at the foot of the plinth.
    final shrub = Path();
    for (final (dx, r) in const [(-1.35, .4), (-.95, .48), (1.0, .44), (1.4, .36)]) {
      shrub.addOval(Rect.fromCircle(center: at + Offset(dx * s, s * .5), radius: r * s));
    }
    c.drawPath(shrub, Paint()..color = _hazed(_karstVeg, haze * .65));
  }

  /// Mist lying between two ranks: a continuous bank plus loose patches.
  static void _karstMistBand(Canvas c, double w, double h, int rank) {
    final top = h * (.38 + .025 * rank), bottom = h * .72;
    final fog = const [.85, .8, .75, .7][rank];
    c.drawRect(
      Rect.fromLTRB(-h, top, w + h * 1.4, bottom),
      Paint()
        ..shader = Gradient.linear(Offset(0, top), Offset(0, bottom), [
          Sketch.fade(_karstMistColor, 0),
          Sketch.fade(_karstMistColor, fog * .3),
          Sketch.fade(_karstMistColor, fog),
        ], const [0, .45, 1]),
    );
    for (var k = 0; k < 6; k++) {
      final x = w * (k / 5 * 1.4 - .08) + (Sketch.hash(rank * 13 + k + 500) - .5) * h * .5;
      final y = h * (.47 + .03 * rank + .05 * Sketch.hash(rank * 13 + k + 520));
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x, y),
          width: h * (.9 + .8 * Sketch.hash(rank * 13 + k + 540)),
          height: h * (.07 + .05 * Sketch.hash(rank * 13 + k + 560)),
        ),
        _karstMistColor,
        .55,
      );
    }
  }

  /// Mist banks drift along the feet of the karst, in front of the towers.
  static void _karstMist(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    for (var i = 0; i < 7; i++) {
      final x = (f.w + h * 1.6) * (i + .6 * Sketch.hash(i + 410)) / 7 - h * .5 + math.sin(f.clock * .1 + i * 1.7) * h * .04;
      final y = h * (.5 + .1 * Sketch.hash(i + 420));
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x, y),
          width: h * (.6 + .5 * Sketch.hash(i + 430)),
          height: h * (.05 + .04 * Sketch.hash(i + 440)),
        ),
        _karstMistColor,
        (.45 + .3 * Sketch.hash(i + 450)) * presence,
      );
    }
  }

  /// Foothills the wall climbs, behind the mid ridge: (x in w, x in h, lift,
  /// left flank, right flank), every size in viewport heights. Nothing rises
  /// in the pagoda's territory (x about 0.7 to 1.0 w).
  static const _wallHillSpec = <(double, double, double, double, double)>[
    (.09, 0.0, .04, .26, .30),
    (.30, 0.0, .055, .30, .26),
    (.50, 0.0, .025, .22, .24),
    (1.0, .22, .04, .26, .30),
  ];

  /// Crumbled stretches of the wall: (x in w, x in h, half width, depth).
  static const _wallBreakSpec = <(double, double, double, double)>[
    (.185, 0.0, .09, .85),
    (.665, 0.0, .07, .9),
  ];

  static double _wallLift(double x, double w, double h) {
    var lift = 0.0;
    for (final (fw, fh, a, l, r) in _wallHillSpec) {
      final d = x - (w * fw + h * fh);
      final u = d < 0 ? -d / (h * l) : d / (h * r);
      if (u < 1) lift += a * h * math.pow(1 - math.pow(u, 1.7), 1.6);
    }
    if (lift <= 0) return 0;
    return lift * (1 + .07 * math.sin(x / h * 19 + 1.3) + .05 * math.sin(x / h * 47 + .4));
  }

  /// 1 where the wall stands whole, lower where masonry has fallen away in
  /// blocks of uneven height.
  static double _wallRuin(double x, double w, double h) {
    for (final (fw, fh, half, depth) in _wallBreakSpec) {
      final d = (x - (w * fw + h * fh)) / (h * half);
      if (d.abs() >= 1) continue;
      final keep = Sketch.hash((x / (h * .018)).floor() + 611);
      final stand = (1 - depth) * .3 + .85 * math.pow(keep, 1.5);
      return math.max(.12, 1 - (1 - d * d) * (1 - math.min(.95, stand)));
    }
    return 1;
  }

  /// The Great Wall follows the mid ridge, climbing low foothills, crenellated,
  /// with watchtowers, a beacon tower and a few crumbled stretches.
  void _wall(Canvas c, double w, double h) {
    final sunX = light.at.dx * w;
    final x0 = -h * .3, x1 = w + h * .8, dx = h * .007, q = h * .0045;
    double hy(double x) => _midRidge(x / h) * h - _wallLift(x, w, h);
    double rd(double x) => _midRidge(x / h) * h;
    // The wall's base line: smooth on gentle ground, a staircase on steep.
    final xs = <double>[], by = <double>[];
    for (var x = x0; x <= x1; x += dx) {
      final y = hy(x);
      final steep = (hy(x + dx) - hy(x - dx)).abs() > dx * .5;
      final wy = steep ? (y / q).round() * q : y;
      if (by.isNotEmpty && (wy - by.last).abs() > q * .6) {
        xs.add(x);
        by.add(by.last);
      }
      xs.add(x);
      by.add(wy);
    }
    final n = xs.length;
    final ruin = List<double>.generate(n, (i) => _wallRuin(xs[i], w, h));
    int at(double x) {
      var lo = 0, hi = n - 1;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (xs[mid] < x) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      return lo;
    }

    _wallSlopes(c, w, h, sunX, x0, x1, hy, rd);

    // The beacon tower stands on the tallest foothill, behind the wall.
    final beaconX = w * .3;
    _wallBeacon(c, Offset(beaconX, hy(beaconX) - h * .004), h * .078, beaconX < sunX ? 1.0 : -1.0);

    // ---- wall body: heights are offsets above the local base line.
    final fnd = h * .008, body = h * .030, corbel = h * .0335, parapet = h * .041;
    double faceTop(int i) => ruin[i] > .97 ? body : fnd + (body - fnd) * ruin[i];
    Path strip(double lo, double hi, {bool whole = false}) {
      final p = Path();
      var i = 0;
      while (i < n) {
        if (!whole && ruin[i] <= .97) {
          i++;
          continue;
        }
        var j = i;
        while (j + 1 < n && (whole || ruin[j + 1] > .97)) {
          j++;
        }
        p.moveTo(xs[i], by[i] - lo);
        for (var k = i + 1; k <= j; k++) {
          p.lineTo(xs[k], by[k] - lo);
        }
        for (var k = j; k >= i; k--) {
          final t = whole ? math.min(hi, faceTop(k)) : hi;
          if (whole && k < j && ruin[k] != ruin[k + 1]) {
            p.lineTo(xs[k + 1], by[k + 1] - math.min(hi, faceTop(k)));
          }
          p.lineTo(xs[k], by[k] - t);
        }
        p.close();
        i = j + 1;
      }
      return p;
    }

    final faceC = _hazed(const Color(0xffcbb59f), .3);
    final faceLit = _hazed(const Color(0xffe9d3b6), .24);
    final faceShade = _hazed(const Color(0xff9d8a86), .3);
    final course = _hazed(const Color(0xff7d6a68), .3);
    c.drawPath(strip(-h * .004, body, whole: true), Paint()..color = faceC);
    // Warm sun-catching band up top, cool footing below.
    c.drawPath(strip(body - h * .007, body, whole: true), Paint()..color = Sketch.fade(faceLit, .8));
    c.drawPath(strip(-h * .004, fnd, whole: true), Paint()..color = faceShade);
    // Brick courses follow the slope; joints are staggered ticks.
    final lines = Path(), joints = Path();
    var row = 0;
    for (final off in [h * .0125, h * .0175, h * .0225, h * .0265]) {
      var pen = false;
      for (var i = 0; i < n; i++) {
        if (off > faceTop(i) - h * .001) {
          pen = false;
          continue;
        }
        if (pen) {
          lines.lineTo(xs[i], by[i] - off);
        } else {
          lines.moveTo(xs[i], by[i] - off);
          pen = true;
        }
      }
      final gap = h * .0125;
      for (var x = x0 + (row.isOdd ? gap * .5 : 0.0) + gap * Sketch.hash(row + 91); x < xs.last; x += gap * (.9 + .3 * Sketch.hash((x / gap).floor() + row * 31))) {
        final i = at(x);
        if (off + h * .005 > faceTop(i)) continue;
        joints
          ..moveTo(x, by[i] - off)
          ..lineTo(x, by[i] - off + h * .005);
      }
      row++;
    }
    final hair = math.max(.5, h * .0012);
    c.drawPath(
      lines,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(course, .3),
    );
    c.drawPath(
      joints,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(course, .24),
    );
    // Hairline cracks in the masonry.
    final cracks = Path();
    for (var k = 0; k < 14; k++) {
      final x = x0 + (xs.last - x0) * Sketch.hash(k + 1200);
      final i = at(x);
      if (ruin[i] <= .97) continue;
      final y = by[i] - body + h * .002;
      cracks
        ..moveTo(x, y)
        ..lineTo(x + h * .002, y + h * .006)
        ..lineTo(x - h * .001, y + h * .011)
        ..lineTo(x + h * .0015, y + h * .016);
    }
    c.drawPath(
      cracks,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0011)
        ..color = Sketch.fade(course, .55),
    );
    // Water stains and moss on the face.
    final stain = Path(), moss = Paint()..color = Sketch.fade(_hazed(const Color(0xff6f8468), .35), .5);
    for (var k = 0; k < 46; k++) {
      final x = x0 + (xs.last - x0) * Sketch.hash(k + 520);
      final i = at(x);
      if (ruin[i] <= .97) continue;
      if (k.isEven) {
        final len = h * (.005 + .008 * Sketch.hash(k + 570));
        stain
          ..moveTo(x, by[i] - body + h * .002)
          ..lineTo(x + h * .001, by[i] - body + h * .002 + len);
      } else {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, by[i] - fnd - h * .002),
            width: h * (.008 + .012 * Sketch.hash(k + 620)),
            height: h * .005,
          ),
          moss,
        );
      }
    }
    c.drawPath(
      stain,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(course, .3),
    );
    // Corbel course, its shadow, the parapet and the walkway floor.
    c.drawPath(strip(body - h * .003, body, whole: false), Paint()..color = Sketch.fade(course, .3));
    c.drawPath(strip(body, corbel), Paint()..color = faceLit);
    c.drawPath(strip(corbel, parapet), Paint()..color = faceC);
    c.drawPath(strip(parapet - h * .004, parapet), Paint()..color = _hazed(const Color(0xfff7e4cc), .18));
    c.drawPath(strip(corbel, corbel + h * .0025), Paint()..color = Sketch.fade(course, .28));
    // Loopholes in every other merlon.
    final slits = Path();
    final mw = h * .0098, pitch = h * .0158;
    final merlon = Path(), cap = Path(), edge = Path();
    for (var x = x0 + pitch * .3; x < xs.last - pitch; x += pitch) {
      final i = at(x), j = at(x + mw);
      if (ruin[i] <= .97 || ruin[j] <= .97) continue;
      final idx = ((x - x0) / pitch).round();
      if (Sketch.hash(idx + 470) < .09) continue;
      final yl = by[i] - parapet, yr = by[j] - parapet;
      final top = math.min(yl, yr) - h * (Sketch.hash(idx + 1470) < .07 ? .0045 : .0085);
      merlon.addRect(Rect.fromLTRB(x, top, x + mw, math.max(yl, yr) + h * .003));
      cap.addRect(Rect.fromLTWH(x, top, mw, h * .0028));
      final toSun = x < sunX;
      edge.addRect(
        Rect.fromLTRB(toSun ? x + mw - h * .0026 : x, top, toSun ? x + mw : x + h * .0026, toSun ? yr : yl),
      );
      if (idx.isEven) {
        slits.addRect(Rect.fromLTWH(x + mw * .5 - h * .0007, top + h * .0034, h * .0014, h * .0036));
      }
    }
    c.drawPath(merlon, Paint()..color = faceC);
    c.drawPath(edge, Paint()..color = Sketch.fade(faceLit, .85));
    c.drawPath(cap, Paint()..color = _hazed(const Color(0xfff9e6cd), .18));
    c.drawPath(slits, Paint()..color = Sketch.fade(course, .55));

    // ---- crumbled stretches: rubble, saplings and fallen blocks.
    for (final (fw, fh, half, _) in _wallBreakSpec) {
      final cx = w * fw + h * fh;
      final rubble = [faceShade, faceC, _hazed(const Color(0xff8d7b78), .3)];
      for (var k = 0; k < 16; k++) {
        final x = cx + h * half * (Sketch.hash(k + 700) * 2 - 1) * 1.05;
        final i = at(x);
        final s = h * (.003 + .0045 * Sketch.hash(k + 740));
        final y = by[i] + h * .003 + h * .004 * Sketch.hash(k + 780);
        c.drawPath(
          Sketch.poly([-1, 0, -.6, -.9, .5, -1, 1, 0], at: Offset(x, y), s: s),
          Paint()..color = rubble[k % 3],
        );
      }
      final leaf = Paint()..color = _hazed(const Color(0xff6f8468), .32);
      for (var k = 0; k < 6; k++) {
        final x = cx + h * half * (Sketch.hash(k + 800) * 1.6 - .8);
        final i = at(x);
        final top = by[i] - faceTop(i);
        for (final (dx, dy, r) in const [(0.0, 0.0, 1.0), (-.8, .4, .7), (.8, .5, .75)]) {
          c.drawCircle(Offset(x + dx * h * .0045, top + dy * h * .002), r * h * .0045, leaf);
        }
      }
    }

    // ---- towers: sun-facing sides catch the warm light, and each throws a
    // soft shadow onto the wall away from the sun.
    final shadow = Paint()..color = Sketch.fade(_hazed(const Color(0xff6b5670), .15), .26);
    void tower(double x, double t, int kind, bool flag) {
      final bw = t * .3;
      final sun = x < sunX ? 1.0 : -1.0;
      var y = 0.0;
      for (final k in [-1.0, 0.0, 1.0]) {
        y = math.max(y, by[at(x + k * bw)]);
      }
      final ex = x - sun * bw;
      final reach = h * .05;
      final xa = ex - sun * reach;
      final ia = at(xa);
      c.drawPath(
        Path()
          ..moveTo(ex, by[at(ex)] - parapet)
          ..lineTo(xa, by[ia] - parapet + h * .016)
          ..lineTo(xa, by[ia])
          ..lineTo(ex, by[at(ex)])
          ..close(),
        shadow,
      );
      _wallTower(c, Offset(x, y + h * .006), t, kind, sun, flag: flag);
    }

    tower(w * .09, h * .09, 1, false);
    tower(w * .3 + h * .27, h * .085, 0, true);
    tower(w * .5 + h * .2, h * .07, 0, false);
    tower(w + h * .22, h * .09, 0, true);

    // ---- vegetation crowding the foot of the wall and the foothill slopes.
    for (var k = 0; k < 90; k++) {
      final x = x0 + (xs.last - x0) * Sketch.hash(k + 900);
      final i = at(x);
      final gap = _midRidge(x / h) * h - by[i];
      final r = Sketch.hash(k + 940);
      final s = h * (.0055 + .006 * r);
      final y = by[i] + h * .004 + gap * Sketch.hash(k + 960) * .75;
      final tall = k % 3 == 0 && gap > h * .012;
      _wallTree(c, Offset(x, y), tall ? s * 1.5 : s, k, x < sunX ? 1.0 : -1.0);
    }

    // River mist thins the footing of the foothills.
    for (final (fx, fy, fw) in const [(.16, .0, .5), (.46, .01, .45), (.66, .0, .4), (.98, .0, .5)]) {
      final x = w * fx;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, rd(x) - h * (.008 + fy)), width: h * fw * 1.5, height: h * .06),
        const Color(0xfff8e2da),
        .55,
      );
    }
  }

  /// Foothill faces: a hazy body, a sun-lit and a shaded flank.
  void _wallSlopes(Canvas c, double w, double h, double sunX, double x0, double x1, double Function(double) hy, double Function(double) rd) {
    final dx = h * .01;
    var top = h, bottom = 0.0;
    final body = Path()..moveTo(x0, hy(x0));
    for (var x = x0 + dx; x < x1 + dx; x += dx) {
      final y = hy(x);
      top = math.min(top, y);
      bottom = math.max(bottom, rd(x));
      body.lineTo(x, y);
    }
    body
      ..lineTo(x1 + dx, rd(x1 + dx) + h * .08)
      ..lineTo(x0, rd(x0) + h * .08)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(Offset(0, top), Offset(0, bottom), [
          _hazed(const Color(0xff9c96b6), .16),
          _hazed(const Color(0xffa8a2bd), .1),
        ]),
    );
    final lit = Paint()..color = _hazed(const Color(0xffcdb6c0), .12);
    final shade = Paint()..color = _hazed(const Color(0xff8b88a8), .14);
    for (final (fw, fh, _, l, r) in _wallHillSpec) {
      final cx = w * fw + h * fh;
      final sgn = cx < sunX ? 1.0 : -1.0;
      final litReach = h * (sgn > 0 ? r : l), shadeReach = h * (sgn > 0 ? l : r);
      Path wedge(double dir, double reach, double inner) {
        final p = Path()..moveTo(cx, hy(cx));
        for (var k = 1; k <= 12; k++) {
          final x = cx + dir * reach * k / 12;
          p.lineTo(x, hy(x));
        }
        final xi = cx + dir * reach * inner;
        return p
          ..lineTo(xi, rd(xi) + h * .004)
          ..close();
      }

      c.drawPath(wedge(-sgn, shadeReach, .32), shade);
      c.drawPath(wedge(sgn, litReach, .6), lit);
    }
  }

  /// A tiny stacked pine, round-crowned tree or russet maple, lit on the sun's
  /// side.
  static void _wallTree(Canvas c, Offset p, double s, int seed, double sun) {
    final dark = _hazed(const Color(0xff52706a), .34);
    final lit = _hazed(const Color(0xff829c7f), .3);
    final trunk = Paint()
      ..color = _hazed(const Color(0xff5a4a4c), .34)
      ..strokeWidth = math.max(.5, s * .12);
    switch (seed % 6) {
      case 0 || 1 || 2:
        // A stacked pine: three tiers, sun-side half lighter.
        final tiers = Path(), sunny = Path();
        for (var k = 0; k < 3; k++) {
          final half = s * (.6 - k * .15);
          final y = p.dy - k * s * .5;
          tiers.addPolygon([Offset(p.dx - half, y), Offset(p.dx + half, y), Offset(p.dx, y - s * .78)], true);
          sunny.addPolygon([Offset(p.dx, y), Offset(p.dx + sun * half, y), Offset(p.dx, y - s * .78)], true);
        }
        c.drawLine(p + Offset(0, s * .12), p + Offset(0, -s * .1), trunk);
        c.drawPath(tiers, Paint()..color = dark);
        c.drawPath(sunny, Paint()..color = lit);
      case 3 || 4:
        c.drawLine(p, p + Offset(0, -s * .35), trunk);
        final crown = Paint()..color = dark, glow = Paint()..color = lit;
        for (final (dx, dy, r) in const [(-.42, -.62, .5), (.4, -.6, .48), (0.0, -.85, .58)]) {
          c.drawCircle(p + Offset(dx * s, dy * s), r * s, crown);
        }
        for (final (dx, dy, r) in const [(.36, -.7, .3), (0.0, -1.0, .32)]) {
          c.drawCircle(p + Offset((sun > 0 ? dx : -dx) * s, dy * s), r * s, glow);
        }
      default:
        c.drawLine(p, p + Offset(0, -s * .5), trunk);
        c.drawOval(Rect.fromCenter(center: p + Offset(0, -s * .8), width: s * 1.3, height: s * .95), Paint()..color = _hazed(const Color(0xff9a6a5c), .4));
        c.drawOval(Rect.fromCenter(center: p + Offset(sun * s * .2, -s * .92), width: s * .7, height: s * .45), Paint()..color = _hazed(const Color(0xffbb8e72), .42));
    }
  }

  /// A Great Wall watchtower. [kind] 0 is the flat-topped, crenellated tower
  /// with arched windows; 1 carries a small tiled pavilion. [sun] is +1 when
  /// the sun lies to the right. [t] is the tower's height.
  static void _wallTower(Canvas c, Offset base, double t, int kind, double sun, {bool flag = false}) {
    final face = _hazed(const Color(0xffcdb7a0), .2);
    final lit = _hazed(const Color(0xffecd5b6), .14);
    final shade = _hazed(const Color(0xff9d8a86), .2);
    final deep = _hazed(const Color(0xff6c5b5f), .2);
    final roofC = _hazed(const Color(0xff4f6d6a), .28);
    final roofLit = _hazed(const Color(0xff7f9a90), .26);
    final beam = _hazed(const Color(0xffa5574b), .28);
    final cx = base.dx, y0 = base.dy;
    final bw = t * .3, tw = t * .26;
    final y1 = y0 - t * (kind == 0 ? .78 : .6);
    final slab = t * .15;
    double half(double y) => bw + (tw - bw) * ((y0 - y) / (y0 - y1)).clamp(0.0, 1.0);
    Paint fill(Color col) => Paint()..color = col;
    Path arch(double x, double yb, double hw, double hgt) => Path()
      ..moveTo(x - hw, yb)
      ..lineTo(x - hw, yb - hgt + hw)
      ..arcToPoint(Offset(x + hw, yb - hgt + hw), radius: Radius.circular(hw))
      ..lineTo(x + hw, yb)
      ..close();

    // Footing, front face and the sun-lit flank.
    c.drawPath(Sketch.poly([-bw * 1.1, .0, bw * 1.1, .0, bw * 1.07, -t * .08, -bw * 1.07, -t * .08], at: base, s: 1), fill(shade));
    c.drawPath(Sketch.poly([-bw, -t * .07, bw, -t * .07, tw, y1 - y0, -tw, y1 - y0], at: base, s: 1), fill(face));
    c.drawPath(
      Sketch.poly([
        sun * bw, 0,
        sun * (bw + slab), -t * .03,
        sun * (tw + slab * .92), y1 - y0 - t * .03,
        sun * tw, y1 - y0,
      ], at: base),
      fill(lit),
    );
    c.drawPath(
      Sketch.poly([
        sun * bw * 1.08, 0,
        sun * (bw * 1.08 + slab), -t * .03,
        sun * (bw * 1.07 + slab), -t * .11,
        sun * bw * 1.05, -t * .08,
      ], at: base),
      fill(_hazed(const Color(0xffcbb49a), .22)),
    );
    // Brick courses and staggered joints.
    final courses = Path(), joints = Path();
    for (var k = 1; k < 8; k++) {
      final y = y0 - t * (.07 + .1 * k);
      if (y < y1 + t * .02) break;
      final hw = half(y);
      courses
        ..moveTo(cx - hw, y)
        ..lineTo(cx + hw, y);
      for (var j = 0; j < 4; j++) {
        final x = cx - hw + (j + (k.isOdd ? .3 : .8)) * hw * .5;
        joints
          ..moveTo(x, y)
          ..lineTo(x, y + t * .1);
      }
    }
    final hair = math.max(.45, t * .01);
    c.drawPath(courses, Paint()..style = PaintingStyle.stroke..strokeWidth = hair..color = Sketch.fade(deep, .26));
    c.drawPath(joints, Paint()..style = PaintingStyle.stroke..strokeWidth = hair..color = Sketch.fade(deep, .2));
    // String course between the storeys, with its shadow.
    final ys = y0 - t * (kind == 0 ? .43 : .34);
    c.drawPath(Sketch.poly([-half(ys) * 1.07, 0, half(ys) * 1.07, 0, half(ys) * 1.07, -t * .035, -half(ys) * 1.07, -t * .035], at: Offset(cx, ys)), fill(lit));
    c.drawRect(Rect.fromLTWH(cx - half(ys), ys, half(ys) * 2, t * .022), fill(Sketch.fade(deep, .22)));
    // Openings: a door below, three arched windows above.
    c.drawPath(arch(cx, y0 - t * .08, t * .052, t * .21), fill(deep));
    c.drawPath(arch(cx, y0 - t * .08, t * .052, t * .05), fill(Sketch.fade(shade, .8)));
    final wy = ys - t * .05;
    for (final dx in const [-.155, 0.0, .155]) {
      c.drawPath(arch(cx + dx * t, wy, t * .04, t * .16), fill(deep));
      c.drawRect(Rect.fromLTWH(cx + dx * t - t * .05, wy, t * .1, t * .017), fill(lit));
    }
    // A slit window in the sun-lit flank.
    c.drawPath(
      Sketch.poly([
        sun * (bw + slab * .45), wy - y0 + t * .03,
        sun * (bw + slab * .7), wy - y0 + t * .015,
        sun * (bw + slab * .7), wy - y0 - t * .1,
        sun * (bw + slab * .45), wy - y0 - t * .085,
      ], at: base),
      fill(Sketch.fade(deep, .7)),
    );
    // Cornice and shadow beneath it.
    c.drawRect(Rect.fromLTWH(cx - tw * 1.1, y1 + t * .0, tw * 2.2, t * .03), fill(Sketch.fade(deep, .22)));
    c.drawPath(Sketch.poly([-tw * 1.1, 0, tw * 1.1, 0, tw * 1.1, -t * .05, -tw * 1.1, -t * .05], at: Offset(cx, y1)), fill(lit));
    c.drawPath(Sketch.poly([sun * tw * 1.1, 0, sun * (tw * 1.1 + slab * .9), -t * .03, sun * (tw * 1.1 + slab * .9), -t * .08, sun * tw * 1.1, -t * .05], at: Offset(cx, y1)), fill(_hazed(const Color(0xfff2dfc4), .12)));
    final yTop = y1 - t * .05;
    if (kind == 0) {
      // Parapet with five merlons, sun-side edges lit.
      c.drawRect(Rect.fromLTRB(cx - tw * 1.05, yTop - t * .06, cx + tw * 1.05, yTop), fill(face));
      c.drawPath(Sketch.poly([sun * tw * 1.05, 0, sun * (tw * 1.05 + slab * .8), -t * .02, sun * (tw * 1.05 + slab * .8), -t * .08, sun * tw * 1.05, -t * .06], at: Offset(cx, yTop)), fill(lit));
      final mm = Path(), ml = Path();
      for (var k = 0; k < 5; k++) {
        final x = cx - tw * 1.05 + k * (tw * 2.1 - t * .075) / 4;
        final r = Rect.fromLTWH(x, yTop - t * .13, t * .075, t * .075);
        mm.addRect(r);
        ml.addRect(Rect.fromLTWH(x, r.top, t * .075, t * .014));
      }
      c.drawPath(mm, fill(face));
      c.drawPath(ml, fill(_hazed(const Color(0xfff9e6cd), .1)));
      if (flag) _wallFlag(c, Offset(cx - sun * tw * .98, yTop - t * .13), t * .85, sun);
      c.drawRect(Rect.fromLTRB(cx - tw * 1.05, yTop - t * .06, cx + tw * 1.05, yTop - t * .048), fill(lit));
    } else {
      // Pavilion: parapet, red posts and a hip roof with upswept eaves.
      final ypar = yTop - t * .05;
      c.drawRect(Rect.fromLTRB(cx - tw * 1.02, ypar, cx + tw * 1.02, yTop), fill(face));
      c.drawRect(Rect.fromLTRB(cx - tw * 1.02, ypar, cx + tw * 1.02, ypar + t * .012), fill(lit));
      final ypost = ypar - t * .15;
      c.drawRect(Rect.fromLTRB(cx - tw * .92, ypost, cx + tw * .92, ypar), fill(beam));
      c.drawRect(Rect.fromLTRB(cx - tw * .62, ypost + t * .03, cx + tw * .62, ypar - t * .01), fill(deep));
      for (final dx in const [-.62, -.2, .2, .62]) {
        c.drawRect(Rect.fromLTWH(cx + dx * tw - t * .012, ypost, t * .024, ypar - ypost), fill(beam));
      }
      final ye = ypost - t * .005;
      final roof = Path()
        ..moveTo(cx - t * .5, ye - t * .05)
        ..quadraticBezierTo(cx - t * .42, ye + t * .03, cx - t * .3, ye + t * .015)
        ..lineTo(cx + t * .3, ye + t * .015)
        ..quadraticBezierTo(cx + t * .42, ye + t * .03, cx + t * .5, ye - t * .05)
        ..quadraticBezierTo(cx + t * .26, ye - t * .06, cx + t * .1, ye - t * .24)
        ..lineTo(cx - t * .1, ye - t * .24)
        ..quadraticBezierTo(cx - t * .26, ye - t * .06, cx - t * .5, ye - t * .05)
        ..close();
      c.drawPath(roof, fill(roofC));
      final litRoof = Path()..moveTo(cx, ye - t * .24);
      litRoof
        ..lineTo(cx + sun * t * .1, ye - t * .24)
        ..quadraticBezierTo(cx + sun * t * .26, ye - t * .06, cx + sun * t * .5, ye - t * .05)
        ..quadraticBezierTo(cx + sun * t * .42, ye + t * .03, cx + sun * t * .3, ye + t * .015)
        ..lineTo(cx, ye + t * .015)
        ..close();
      c.drawPath(litRoof, fill(roofLit));
      // Shadow under the eaves and glazed hip ridges catching the light.
      c.drawRect(Rect.fromLTRB(cx - t * .25, ye + t * .015, cx + t * .25, ye + t * .05), fill(Sketch.fade(deep, .4)));
      final hips = Path();
      for (final d in const [-1.0, 1.0]) {
        hips
          ..moveTo(cx + d * t * .1, ye - t * .24)
          ..quadraticBezierTo(cx + d * t * .26, ye - t * .06, cx + d * t * .5, ye - t * .05);
      }
      c.drawPath(hips, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.7, t * .016)..strokeCap = StrokeCap.round..color = Sketch.fade(_hazed(const Color(0xffdfe3d0), .2), .8));
      final tiles = Path();
      for (final dx in const [-.3, -.15, 0.0, .15, .3]) {
        tiles
          ..moveTo(cx + dx * t * .34, ye - t * .22)
          ..lineTo(cx + dx * t, ye + t * .01);
      }
      c.drawPath(tiles, Paint()..style = PaintingStyle.stroke..strokeWidth = hair..color = Sketch.fade(deep, .3));
      c.drawLine(Offset(cx - t * .1, ye - t * .24), Offset(cx + t * .1, ye - t * .24), Paint()..color = _hazed(const Color(0xffe6d2b4), .2)..strokeWidth = math.max(.8, t * .02)..strokeCap = StrokeCap.round);
      c.drawCircle(Offset(cx - t * .1, ye - t * .255), t * .018, fill(roofLit));
      c.drawCircle(Offset(cx + t * .1, ye - t * .255), t * .018, fill(roofLit));
      _wallFlag(c, Offset(cx, ye - t * .24), t, sun);
    }
  }

  /// A small vermilion pennant on a thin pole, streaming away from the sun.
  static void _wallFlag(Canvas c, Offset p, double t, double sun) {
    final pole = p + Offset(0, -t * .16);
    c.drawLine(p, pole, Paint()..color = _hazed(const Color(0xff6c5b5f), .2)..strokeWidth = math.max(.6, t * .012));
    final d = -sun;
    c.drawPath(
      Path()
        ..moveTo(pole.dx, pole.dy)
        ..quadraticBezierTo(pole.dx + d * t * .07, pole.dy - t * .015, pole.dx + d * t * .17, pole.dy + t * .005)
        ..lineTo(pole.dx + d * t * .13, pole.dy + t * .03)
        ..lineTo(pole.dx + d * t * .18, pole.dy + t * .055)
        ..quadraticBezierTo(pole.dx + d * t * .08, pole.dy + t * .04, pole.dx, pole.dy + t * .05)
        ..close(),
      Paint()..color = _hazed(const Color(0xffc4483c), .28),
    );
  }

  /// A beacon tower: a tall, solid, tapering tower of rammed earth and brick
  /// on a hilltop, with a thin wisp of smoke standing above it.
  static void _wallBeacon(Canvas c, Offset base, double t, double sun) {
    final face = _hazed(const Color(0xffb9a086), .22);
    final lit = _hazed(const Color(0xffdcc3a2), .18);
    final shade = _hazed(const Color(0xff8d7a78), .24);
    final deep = _hazed(const Color(0xff65565a), .22);
    final cx = base.dx, y0 = base.dy;
    final bw = t * .34, tw = t * .25, y1 = y0 - t;
    double half(double y) => bw + (tw - bw) * ((y0 - y) / (y0 - y1)).clamp(0.0, 1.0);
    Paint fill(Color col) => Paint()..color = col;
    // Smoke first, so the tower stands in front of its foot.
    final smoke = Path()..moveTo(cx - t * .015, y1 - t * .04);
    final right = <Offset>[];
    for (var k = 1; k <= 12; k++) {
      final u = k / 12;
      final x = cx + t * (.12 * math.sin(u * 3.4) + .1 * u);
      final y = y1 - t * (.04 + .8 * u);
      final wdt = t * (.02 + .07 * u);
      smoke.lineTo(x - wdt, y);
      right.add(Offset(x + wdt, y));
    }
    for (final p in right.reversed) {
      smoke.lineTo(p.dx, p.dy);
    }
    smoke.lineTo(cx + t * .015, y1 - t * .04);
    smoke.close();
    c.drawPath(
      smoke,
      Paint()
        ..shader = Gradient.linear(Offset(0, y1 - t * .04), Offset(0, y1 - t), [
          Sketch.fade(_hazed(const Color(0xff9c8494), .12), .5),
          Sketch.fade(_hazed(const Color(0xffa8929e), .12), 0),
        ]),
    );
    // Body: shaded face, a lit sun-side flank and rammed-earth strata.
    c.drawPath(Sketch.poly([-bw, .0, bw, .0, tw, y1 - y0, -tw, y1 - y0], at: base), fill(face));
    c.drawPath(Sketch.poly([sun * bw, 0, sun * (bw + t * .1), -t * .02, sun * (tw + t * .09), y1 - y0 - t * .02, sun * tw, y1 - y0], at: base), fill(lit));
    c.drawPath(Sketch.poly([-bw, .0, -bw * .55, .0, -tw * .55, y1 - y0, -tw, y1 - y0], at: base), fill(Sketch.fade(shade, .45)));
    c.drawPath(Sketch.poly([-bw * 1.05, .0, bw * 1.05, .0, bw * 1.03, -t * .07, -bw * 1.03, -t * .07], at: base), fill(shade));
    final strata = Path();
    for (var k = 1; k < 16; k++) {
      final y = y0 - t * (.07 + k * .058);
      if (y < y1 + t * .06) break;
      final hw = half(y);
      strata
        ..moveTo(cx - hw, y + (k.isEven ? t * .004 : 0))
        ..lineTo(cx + hw, y - (k.isEven ? 0 : t * .004));
    }
    final hair = math.max(.45, t * .009);
    c.drawPath(strata, Paint()..style = PaintingStyle.stroke..strokeWidth = hair..color = Sketch.fade(deep, .22));
    // Vertical weathering streaks and the raised doorway.
    final streaks = Path();
    for (final (dx, top, len) in const [(-.13, .6, .2), (.05, .8, .28), (.15, .5, .15)]) {
      streaks
        ..moveTo(cx + dx * t, y0 - t * top)
        ..lineTo(cx + dx * t + t * .01, y0 - t * (top - len));
    }
    c.drawPath(streaks, Paint()..style = PaintingStyle.stroke..strokeWidth = hair * 1.4..color = Sketch.fade(deep, .16));
    final door = Path()
      ..moveTo(cx - t * .045, y0 - t * .64)
      ..lineTo(cx - t * .045, y0 - t * .71)
      ..arcToPoint(Offset(cx + t * .045, y0 - t * .71), radius: Radius.circular(t * .045))
      ..lineTo(cx + t * .045, y0 - t * .64)
      ..close();
    c.drawPath(door, fill(deep));
    // Overhanging cap, crenellations and a dark hearth notch.
    c.drawRect(Rect.fromLTRB(cx - tw * 1.14, y1, cx + tw * 1.14, y1 + t * .035), fill(Sketch.fade(deep, .28)));
    c.drawRect(Rect.fromLTRB(cx - tw * 1.14, y1 - t * .05, cx + tw * 1.14, y1), fill(lit));
    c.drawPath(Sketch.poly([sun * tw * 1.14, 0, sun * (tw * 1.14 + t * .08), -t * .015, sun * (tw * 1.14 + t * .08), -t * .065, sun * tw * 1.14, -t * .05], at: Offset(cx, y1)), fill(_hazed(const Color(0xfff2dfc4), .12)));
    final mm = Path();
    for (var k = 0; k < 4; k++) {
      final x = cx - tw * 1.1 + k * (tw * 2.2 - t * .07) / 3;
      mm.addRect(Rect.fromLTWH(x, y1 - t * .11, t * .07, t * .06));
    }
    c.drawPath(mm, fill(face));
    c.drawRect(Rect.fromLTWH(cx - tw * .5, y1 - t * .07, tw, t * .02), fill(Sketch.fade(deep, .5)));
  }

  // Hill-temple palette, pre-hazed for the mid distance. The sun sits to the
  // left, so every form has a warm lit facet, a body tone and a cool shade.
  static final _pagodaBrickLit = _hazed(const Color(0xffd0806b), .3);
  static final _pagodaBrick = _hazed(const Color(0xffb4634f), .3);
  static final _pagodaBrickShade = _hazed(const Color(0xff8a4f58), .32);
  static final _pagodaLacquerLit = _hazed(const Color(0xffd8624f), .3);
  static final _pagodaLacquer = _hazed(const Color(0xffbb473c), .3);
  static final _pagodaLacquerShade = _hazed(const Color(0xff8d3f4b), .32);
  static final _pagodaRoofLit = _hazed(const Color(0xff78b0a2), .28);
  static final _pagodaRoof = _hazed(const Color(0xff4d827b), .3);
  static final _pagodaRoofShade = _hazed(const Color(0xff35605f), .32);
  static final _pagodaStoneLit = _hazed(const Color(0xffdccbbd), .28);
  static final _pagodaStone = _hazed(const Color(0xffbcaca9), .3);
  static final _pagodaStoneShade = _hazed(const Color(0xff918899), .32);
  static final _pagodaDark = _hazed(const Color(0xff4a3441), .3);
  static final _pagodaGold = _hazed(const Color(0xffdcae66), .34);
  static final _pagodaGlow = _hazed(const Color(0xffe9b877), .22);
  static final _pagodaRim = _hazed(const Color(0xffffe6cc), .12);
  static final _pagodaLeaf = _hazed(const Color(0xff3b6a61), .3);
  static final _pagodaLeafLit = _hazed(const Color(0xff72a184), .26);
  static final _pagodaHillLit = _hazed(const Color(0xff5f8f73), .22);
  static final _pagodaHillShade = _hazed(const Color(0xff3a5f58), .28);
  static const _pagodaMist = Color(0xffb9b0cb);
  static const _pagodaSmoke = Color(0xfff8ebe6);
  static final _pagodaFlags = [
    _hazed(const Color(0xffc9584a), .3),
    _hazed(const Color(0xffe2b653), .3),
    _hazed(const Color(0xff4f9a90), .3),
  ];
  static final _pagodaBlossom = _hazed(const Color(0xffefb1c0), .3);

  /// Height of the temple mound at [dx] pagoda scales from its axis. The
  /// ridge blends into a broad, flat-topped knoll, so the mound melts into
  /// the slope on both sides.
  double _pagodaTop(double cx, double s, double dx) {
    final h = s * 5;
    double ry(double d) => _midRidge((cx + d * s) / h) * h;
    final t = (dx / 1.95).abs();
    if (t >= 1) return ry(dx);
    final e = math.pow(1 - t * t * t * t, 1.6).toDouble();
    return ry(dx) * (1 - e) + (ry(0) - s * .5) * e;
  }

  /// The hill temple on the mid ridge: a wooded, terraced mound with a
  /// courtyard wall, two halls, a small storeyed tower and the seven-storey
  /// pagoda. [base] is the ridge at the pagoda's axis, [s] its scale (.2 h).
  void _pagoda(Canvas c, Offset base, double s) {
    final cx = base.dx, h = s * 5;
    double top(double dx) => _pagodaTop(cx, s, dx);
    double x(double dx) => cx + dx * s;
    final axis = base.dy - h * .01;
    final fill = Paint();
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final hair = math.max(.5, s * .006);

    // The mound: lit on the left, shaded on the right, misting at the foot.
    final pts = [for (var k = -44; k <= 44; k++) Offset(x(k * .05), top(k * .05))];
    final hill = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts) {
      hill.lineTo(p.dx, p.dy);
    }
    hill
      ..lineTo(pts.last.dx, h * .74)
      ..lineTo(pts.first.dx, h * .74)
      ..close();
    c.drawPath(
      hill,
      fill
        ..shader = Gradient.linear(
          Offset(x(-2), 0),
          Offset(x(2), 0),
          [_pagodaHillLit, Sketch.mix(_pagodaHillLit, _pagodaHillShade, .5), _pagodaHillShade],
          const [0, .42, 1],
        ),
    );
    c.drawPath(
      hill,
      fill
        ..shader = Gradient.linear(Offset(0, axis - s * .16), Offset(0, axis + h * .012), [
          Sketch.fade(_pagodaMist, 0),
          Sketch.fade(_pagodaMist, .55),
        ]),
    );
    fill.shader = null;
    // Ink-wash terrace contours, following the crest.
    c.save();
    c.clipPath(hill);
    for (var k = 1; k <= 3; k++) {
      final band = Path()..moveTo(pts.first.dx, pts.first.dy + k * s * .15);
      for (final p in pts) {
        band.lineTo(p.dx, p.dy + k * s * .15 + math.sin(p.dx / s * 3 + k) * s * .012);
      }
      c.drawPath(
        band,
        ink
          ..strokeWidth = s * .07
          ..color = k.isOdd ? Sketch.fade(_pagodaLeaf, .2) : Sketch.fade(_pagodaLeafLit, .24),
      );
    }
    c.restore();

    // Trees crowning the flanks and behind the buildings, then the courtyard wall.
    for (var i = 0; i < 16; i++) {
      final dx = (i < 8 ? -1.95 + i * .085 : 1.3 + (i - 8) * .085) + .06 * Sketch.hash(i + 430);
      _pagodaCanopy(c, x(dx), top(dx) + s * (.035 + .02 * Sketch.hash(i + 431)), s * (.16 + .07 * Sketch.hash(i + 432)), i);
    }
    for (final (dx, t, kind) in const [
      (-1.86, .2, 0), (-1.5, .19, 1), (-.7, .24, 1), (.68, .27, 1), (1.5, .2, 1), (1.85, .2, 0),
    ]) {
      _pagodaTree(c, x(dx), top(dx) + s * .03, s * t, kind);
    }
    _pagodaWall(c, cx, s, top);
    // The pagoda's shadow falls to the right, across the courtyard wall.
    c.drawPath(
      Sketch.poly([x(.5), top(.5) - s * .065, x(1.05), top(1.05) - s * .065, x(1.05), top(1.05) + s * .03, x(.5), top(.5) + s * .03]),
      Paint()..color = Sketch.fade(_pagodaDark, .14),
    );

    // Halls, bell tower and the pagoda itself.
    _pagodaHall(c, x(-1.02), top(-1.02) + s * .02, s, s * .33);
    _pagodaTower(c, x(1.0), top(1.0) + s * .02, s * .62, 2);
    _pagodaTower(c, cx, top(0) + s * .02, s * .93, 7);
    _pagodaCenser(c, x(-.5), top(-.5) + s * .02, s);

    // Retaining wall of the terrace and the stair down the middle.
    Sketch.mist(c, Rect.fromCenter(center: Offset(cx, top(0) + s * .02), width: s * 3.2, height: s * .12), _pagodaMist, .2);
    final wallTop = <Offset>[], wallBottom = <Offset>[];
    for (var k = -34; k <= 34; k++) {
      final dx = k * .05;
      final taper = ((1.7 - dx.abs()) / .5).clamp(0.0, 1.0);
      wallTop.add(Offset(x(dx), top(dx) + s * .02));
      wallBottom.add(Offset(x(dx), top(dx) + s * (.02 + .075 * taper)));
    }
    final wallPath = Path()..moveTo(wallTop.first.dx, wallTop.first.dy);
    for (final p in wallTop) {
      wallPath.lineTo(p.dx, p.dy);
    }
    for (final p in wallBottom.reversed) {
      wallPath.lineTo(p.dx, p.dy);
    }
    wallPath.close();
    c.save();
    c.clipPath(hill);
    final cast = Path()..moveTo(wallBottom.first.dx, wallBottom.first.dy + s * .05);
    for (final p in wallBottom) {
      cast.lineTo(p.dx, p.dy + s * .05);
    }
    c.drawPath(cast, ink..strokeWidth = s * .1..color = Sketch.fade(_pagodaLeaf, .34));
    c.restore();
    c.drawPath(
      wallPath,
      fill
        ..shader = Gradient.linear(
          Offset(x(-1.8), 0),
          Offset(x(1.8), 0),
          [_pagodaStoneLit, _pagodaStone, _pagodaStoneShade],
          const [0, .45, 1],
        ),
    );
    fill.shader = null;
    final courses = Path();
    for (var k = 0; k < wallTop.length; k++) {
      final p = wallTop[k], q = wallBottom[k];
      final y = p.dy + (q.dy - p.dy) * .5;
      if (k == 0) {
        courses.moveTo(p.dx, y);
      } else {
        courses.lineTo(p.dx, y);
      }
      if (k.isEven && q.dy - p.dy > s * .03) {
        courses
          ..moveTo(p.dx, p.dy)
          ..lineTo(p.dx, q.dy)
          ..moveTo(p.dx, y);
      }
    }
    c.drawPath(courses, ink..strokeWidth = hair..color = Sketch.fade(_pagodaDark, .26));
    final coping = Path()..moveTo(wallTop.first.dx, wallTop.first.dy);
    for (final p in wallTop) {
      coping.lineTo(p.dx, p.dy);
    }
    c.drawPath(coping, ink..strokeWidth = hair * 1.6..color = Sketch.fade(_pagodaRim, .7));
    // Central stair: a stone flight with treads and low balustrades.
    final stairTop = top(0) + s * .02, stairBottom = axis + h * .012;
    c.drawPath(
      Sketch.poly([-s * .075, stairTop, s * .075, stairTop, s * .12, stairBottom, -s * .12, stairBottom], at: Offset(cx, 0)),
      fill..color = _pagodaStoneLit,
    );
    c.drawPath(
      Sketch.poly([0, stairTop, s * .075, stairTop, s * .12, stairBottom, 0, stairBottom], at: Offset(cx, 0)),
      fill..color = _pagodaStone,
    );
    final treads = Path();
    for (var k = 1; k < 14; k++) {
      final f = k / 14, half = s * (.075 + .045 * f);
      final y = stairTop + (stairBottom - stairTop) * f;
      treads
        ..moveTo(cx - half, y)
        ..lineTo(cx + half, y);
    }
    c.drawPath(treads, ink..strokeWidth = hair..color = Sketch.fade(_pagodaDark, .32));
    for (final sg in const [-1.0, 1.0]) {
      c.drawLine(
        Offset(cx + sg * s * .082, stairTop),
        Offset(cx + sg * s * .13, stairBottom),
        ink..strokeWidth = hair * 2.4..color = sg < 0 ? _pagodaStoneLit : _pagodaStoneShade,
      );
    }

    _pagodaGate(c, cx, stairTop + (stairBottom - stairTop) * .52, s);

    // Foliage on the slope below the terrace: two rows of layered canopies
    // with pines, cypresses and plums standing among them.
    for (var row = 0; row < 3; row++) {
      for (var i = 0; i < 26; i++) {
        final dx = -2.25 + 4.5 * (i + Sketch.hash(i * 3 + row * 97 + 400) * .8) / 26;
        if (dx.abs() < .2) continue;
        final y = top(dx) + s * (.1 + .085 * row + .05 * Sketch.hash(i + row * 31 + 401));
        final w = s * (.12 + .07 * Sketch.hash(i + row * 41 + 402));
        _pagodaCanopy(c, x(dx), y, w, i + row * 40);
      }
      for (var i = 0; i < 7; i++) {
        final dx = -1.9 + 3.8 * (i + .3 + .4 * Sketch.hash(i + row * 13 + 410)) / 7;
        if (dx.abs() < .3 || (dx + .5).abs() < .24) continue;
        final y = top(dx) + s * (.12 + .1 * row);
        _pagodaTree(c, x(dx), y, s * (.11 + .05 * Sketch.hash(i + row * 7 + 420)), (i + row) % 5 == 3 ? 2 : ((i + row) % 3 == 1 ? 1 : 0));
      }
      // A veil of mist between the rows of foliage.
      if (row < 2) {
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(x(row == 0 ? -.4 : .5), top(0) + s * (.27 + .08 * row)), width: s * 3.4, height: s * .14),
          _pagodaMist,
          .3,
        );
      }
    }
    // Mist lying at the foot of the mound.
    for (final (dx, w) in const [(-.9, 1.8), (.9, 2.0)]) {
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x(dx), axis - h * .002), width: s * w, height: h * .04),
        _pagodaMist,
        .6,
      );
    }
  }

  /// A clump of foliage in the ink-painter's dotted manner: three overlapping
  /// lobes in shade, each with a sunlit crown. [seed] varies the lobes.
  static void _pagodaCanopy(Canvas c, double x, double y, double w, int seed) {
    final fill = Paint();
    final v = Sketch.hash(seed * 7 + 3), flip = seed.isEven ? 1.0 : -1.0;
    c.drawOval(Rect.fromCenter(center: Offset(x, y + w * .1), width: w * 1.1, height: w * .34), fill..color = Sketch.fade(_pagodaHillShade, .55));
    final lobes = [
      (-.27 * flip, .0, .3 + .05 * v),
      (.29 * flip, -.02, .27 + .05 * (1 - v)),
      (.0 * flip, -.13, .34),
    ];
    for (final (dx, dy, r) in lobes) {
      c.drawOval(Rect.fromCenter(center: Offset(x + dx * w, y + dy * w), width: r * 2 * w, height: r * 1.5 * w), fill..color = _pagodaLeaf);
    }
    for (final (dx, dy, r) in lobes) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x + (dx - .07) * w, y + (dy - .08) * w), width: r * 1.3 * w, height: r * .8 * w),
        fill..color = _pagodaLeafLit,
      );
    }
  }

  /// The red courtyard wall with its grey tile cap, following the terrace.
  static void _pagodaWall(Canvas c, double cx, double s, double Function(double) top) {
    final pts = [for (var k = -31; k <= 31; k++) k * .05];
    // The wall dips into the hillside where it ends.
    double wy(double dx) => top(dx) - s * .065 * ((1.55 - dx.abs()) / .4).clamp(0.0, 1.0);
    final body = Path()..moveTo(cx + pts.first * s, top(pts.first) + s * .03);
    for (final dx in pts) {
      body.lineTo(cx + dx * s, wy(dx));
    }
    for (final dx in pts.reversed) {
      body.lineTo(cx + dx * s, top(dx) + s * .03);
    }
    body.close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(cx - s * 1.8, 0),
          Offset(cx + s * 1.8, 0),
          [Sketch.mix(_pagodaLacquerLit, _haze, .2), Sketch.mix(_pagodaLacquer, _haze, .2), Sketch.mix(_pagodaLacquerShade, _haze, .2)],
          const [0, .45, 1],
        ),
    );
    final cap = Path()..moveTo(cx + pts.first * s, wy(pts.first));
    for (final dx in pts) {
      cap.lineTo(cx + dx * s, wy(dx));
    }
    c.drawPath(
      cap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .026
        ..color = _pagodaRoofShade,
    );
    final posts = Path();
    for (var k = 0; k < pts.length; k += 5) {
      final dx = pts[k];
      posts
        ..moveTo(cx + dx * s, wy(dx) + s * .005)
        ..lineTo(cx + dx * s, top(dx) + s * .02);
    }
    c.drawPath(
      posts,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .006)
        ..color = Sketch.fade(_pagodaDark, .28),
    );
  }

  static Path _pagodaArch(double cx, double base, double half, double height) {
    return Path()
      ..moveTo(cx - half, base)
      ..lineTo(cx - half, base - height + half)
      ..quadraticBezierTo(cx - half, base - height, cx, base - height)
      ..quadraticBezierTo(cx + half, base - height, cx + half, base - height + half)
      ..lineTo(cx + half, base)
      ..close();
  }

  /// A cloud-pruned pine (0), a slim cypress (1) or a plum in blossom (2).
  static void _pagodaTree(Canvas c, double x, double y, double t, int kind) {
    final fill = Paint();
    switch (kind) {
      case 1:
        c.drawPath(
          Path()
            ..moveTo(x, y - t)
            ..quadraticBezierTo(x + t * .24, y - t * .55, x + t * .12, y)
            ..lineTo(x - t * .12, y)
            ..quadraticBezierTo(x - t * .24, y - t * .55, x, y - t)
            ..close(),
          fill..color = _pagodaLeaf,
        );
        c.drawPath(
          Path()
            ..moveTo(x, y - t)
            ..quadraticBezierTo(x - t * .24, y - t * .55, x - t * .12, y)
            ..quadraticBezierTo(x - t * .04, y - t * .5, x, y - t)
            ..close(),
          fill..color = _pagodaLeafLit,
        );
      case 2:
        c.drawLine(
          Offset(x, y),
          Offset(x + t * .06, y - t * .5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.6, t * .07)
            ..color = _pagodaDark,
        );
        for (final (dx, dy, r) in const [(-.16, -.62, .2), (.14, -.7, .22), (0.0, -.9, .18)]) {
          c.drawCircle(Offset(x + dx * t, y + dy * t), r * t, fill..color = _pagodaBlossom);
          c.drawCircle(Offset(x + (dx - .05) * t, y + (dy - .05) * t), r * t * .5, fill..color = _pagodaRim);
        }
      default:
        c.drawLine(
          Offset(x, y),
          Offset(x + t * .08, y - t * .55),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.6, t * .07)
            ..color = _pagodaDark,
        );
        for (final (dx, dy, w, hgt) in const [(.05, -.5, .95, .26), (-.06, -.7, .7, .24), (.06, -.9, .46, .2)]) {
          c.drawOval(
            Rect.fromCenter(center: Offset(x + dx * t, y + dy * t), width: w * t, height: hgt * t),
            fill..color = _pagodaLeaf,
          );
          c.drawOval(
            Rect.fromCenter(center: Offset(x + (dx - .08) * t, y + (dy - .05) * t), width: w * t * .55, height: hgt * t * .55),
            fill..color = _pagodaLeafLit,
          );
        }
    }
  }

  /// A curved, upswept glazed roof seen from the front: a lit and a shaded
  /// hip around the front slope, tile courses, bracket band and corner bells.
  /// [y0] is the top of the wall, [body] the wall's half width, [ew] the eave
  /// reach, [rx] half the ridge; [u] only guards the hairline widths.
  static void _pagodaEave(
    Canvas c,
    double cx,
    double y0,
    double body,
    double ew,
    double rx,
    double rise,
    double curl,
    double u, {
    bool ends = false,
  }) {
    final yE = y0 + curl * .55, tipY = yE - curl * 1.35, ridgeY = y0 - rise;
    final fx = ew * .66;
    final fill = Paint();
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final hair = math.max(.5, u * .006);
    Path hip(double sg) => Path()
      ..moveTo(cx + sg * ew, tipY)
      ..cubicTo(
        cx + sg * ew * .86,
        tipY + curl * 1.1,
        cx + sg * (rx + (ew - rx) * .25),
        ridgeY + rise * .55,
        cx + sg * rx,
        ridgeY,
      )
      ..lineTo(cx + sg * fx, yE)
      ..quadraticBezierTo(cx + sg * ew * .97, yE + curl * .25, cx + sg * ew, tipY)
      ..close();
    c.drawPath(
      Sketch.poly([-rx - u * .02, ridgeY, rx + u * .02, ridgeY, fx + u * .02, yE, -fx - u * .02, yE], at: Offset(cx, 0)),
      fill..color = _pagodaRoof,
    );
    c.drawPath(hip(-1), fill..color = _pagodaRoofLit);
    c.drawPath(hip(1), fill..color = _pagodaRoofShade);
    // Tile courses across the front slope, hip ridges and the crest line.
    final tiles = Path();
    for (final f in const [.3, .55, .8]) {
      final y = ridgeY + (yE - ridgeY) * f, xl = rx + (fx - rx) * f;
      tiles
        ..moveTo(cx - xl, y)
        ..lineTo(cx + xl, y);
    }
    for (final sg in const [-1.0, 1.0]) {
      tiles
        ..moveTo(cx + sg * rx, ridgeY)
        ..lineTo(cx + sg * fx, yE);
    }
    c.drawPath(tiles, ink..strokeWidth = hair..color = Sketch.fade(_pagodaDark, .34));
    c.drawLine(Offset(cx - rx, ridgeY), Offset(cx + rx, ridgeY), ink..strokeWidth = hair * 1.8..color = _pagodaRoofLit);
    c.drawPath(
      Path()
        ..moveTo(cx - ew, tipY)
        ..cubicTo(cx - ew * .86, tipY + curl * 1.1, cx - (rx + (ew - rx) * .25), ridgeY + rise * .55, cx - rx, ridgeY),
      ink..strokeWidth = hair * 1.5..color = Sketch.fade(_pagodaRim, .6),
    );
    final edge = Path()
      ..moveTo(cx - ew, tipY)
      ..quadraticBezierTo(cx - ew * .97, yE + curl * .25, cx - fx, yE)
      ..lineTo(cx + fx, yE)
      ..quadraticBezierTo(cx + ew * .97, yE + curl * .25, cx + ew, tipY);
    c.drawPath(edge, ink..strokeWidth = hair * 1.4..color = Sketch.fade(_pagodaDark, .55));
    c.drawLine(Offset(cx - fx, yE - curl * .3), Offset(cx + fx, yE - curl * .3), ink..strokeWidth = hair * 1.2..color = Sketch.fade(_pagodaRoofLit, .55));
    // Bracket band under the eave, with a soft shadow on the wall below.
    final band = curl * .55;
    c.drawRect(Rect.fromLTRB(cx - body * 1.05, yE, cx + body * 1.05, yE + band), fill..color = Sketch.fade(_pagodaDark, .8));
    c.drawRect(Rect.fromLTRB(cx - body, yE + band, cx + body, yE + band * 2.4), fill..color = Sketch.fade(_pagodaDark, .13));
    final brackets = Path();
    for (var bx = -body * .96; bx < body; bx += math.max(u * .028, body * .18)) {
      brackets.addRect(Rect.fromLTWH(cx + bx, yE + band * .15, math.max(.6, u * .008), band * .55));
    }
    c.drawPath(brackets, fill..color = Sketch.fade(_pagodaGold, .7));
    // Corner bells, and ridge-end ornaments on the long halls.
    final r = math.max(.55, u * .009);
    for (final sg in const [-1.0, 1.0]) {
      c.drawCircle(Offset(cx + sg * ew * .985, tipY + curl * 1.05), r, fill..color = _pagodaGold);
      if (ends) {
        c.drawPath(
          Path()
            ..moveTo(cx + sg * rx, ridgeY)
            ..quadraticBezierTo(cx + sg * (rx + u * .012), ridgeY - u * .01, cx + sg * (rx + u * .02), ridgeY - u * .034)
            ..quadraticBezierTo(cx + sg * (rx + u * .004), ridgeY - u * .02, cx + sg * (rx - u * .02), ridgeY - u * .004)
            ..close(),
          fill..color = _pagodaRoofLit,
        );
      }
    }
  }

  /// A long temple hall: stone footing and steps, lacquer-red wall with
  /// columns, doors and lattice, and a wide hip roof.
  static void _pagodaHall(Canvas c, double cx, double foot, double u, double half) {
    final fill = Paint();
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final hair = math.max(.5, u * .006);
    final footTop = foot - u * .03, wallTop = footTop - u * .125;
    Shader across(Color a, Color b, Color d) => Gradient.linear(
      Offset(cx - half * 1.2, 0),
      Offset(cx + half * 1.2, 0),
      [a, b, d],
      const [0, .45, 1],
    );
    c.drawRect(
      Rect.fromLTRB(cx - half * 1.2, footTop, cx + half * 1.2, foot + u * .12),
      fill..shader = across(_pagodaStoneLit, _pagodaStone, _pagodaStoneShade),
    );
    c.drawRect(
      Rect.fromLTRB(cx - half, wallTop, cx + half, footTop),
      fill..shader = across(_pagodaLacquerLit, _pagodaLacquer, _pagodaLacquerShade),
    );
    fill.shader = null;
    c.drawLine(Offset(cx - half * 1.2, footTop), Offset(cx + half * 1.2, footTop), ink..strokeWidth = hair * 1.5..color = Sketch.fade(_pagodaRim, .7));
    final bay = half * 2 / 5;
    final cols = Path();
    for (var k = 0; k <= 5; k++) {
      cols
        ..moveTo(cx - half + k * bay, wallTop)
        ..lineTo(cx - half + k * bay, footTop);
    }
    c.drawPath(cols, ink..strokeWidth = hair * 1.6..color = Sketch.fade(_pagodaDark, .5));
    // Central doors with a dim lamp glow, lattice windows in the side bays.
    c.drawRect(
      Rect.fromLTRB(cx - bay * .32, wallTop + u * .03, cx + bay * .32, footTop),
      fill..color = _pagodaDark,
    );
    c.drawRect(
      Rect.fromLTRB(cx - bay * .22, wallTop + u * .045, cx + bay * .22, footTop - u * .008),
      fill..color = Sketch.mix(_pagodaGlow, _pagodaDark, .35),
    );
    for (final k in const [0, 1, 3, 4]) {
      final l = cx - half + k * bay + bay * .2, r = cx - half + k * bay + bay * .8;
      c.drawRect(Rect.fromLTRB(l, wallTop + u * .04, r, footTop - u * .03), fill..color = Sketch.fade(_pagodaDark, .55));
    }
    // Steps up the front.
    final steps = Path();
    for (var k = 1; k <= 3; k++) {
      final y = foot + u * .04 * k / 3 - u * .01;
      steps
        ..moveTo(cx - bay * .5, y)
        ..lineTo(cx + bay * .5, y);
    }
    c.drawPath(steps, ink..strokeWidth = hair..color = Sketch.fade(_pagodaDark, .3));
    _pagodaEave(c, cx, wallTop, half, half * 1.44, half * .92, u * .07, u * .034, u, ends: true);
  }

  /// A storeyed tower: the seven-storey pagoda ([tiers] = 7, with a stone
  /// footing and a Sumeru finial) or a small bell tower. [u] is its scale and
  /// [foot] the ground line; returns the y of the top of the finial.
  static double _pagodaTower(Canvas c, double cx, double foot, double u, int tiers) {
    final fill = Paint();
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final hair = math.max(.5, u * .006);
    var y = foot;
    if (tiers > 3) {
      // Two-stage stone footing and a stair.
      final yFoot = foot;
      for (final (half, hgt) in const [(.5, .05), (.4, .042)]) {
        final l = cx - half * u, r = cx + half * u, f = half * u * .42;
        c.drawRect(Rect.fromLTRB(l, y - hgt * u, cx - f, y), fill..color = _pagodaStoneLit);
        c.drawRect(Rect.fromLTRB(cx - f, y - hgt * u, cx + f, y), fill..color = _pagodaStone);
        c.drawRect(Rect.fromLTRB(cx + f, y - hgt * u, r, y), fill..color = _pagodaStoneShade);
        c.drawLine(Offset(l, y - hgt * u), Offset(r, y - hgt * u), ink..strokeWidth = hair * 1.5..color = Sketch.fade(_pagodaRim, .7));
        y -= hgt * u;
      }
      final stair = Path()
        ..moveTo(cx - u * .085, y)
        ..lineTo(cx + u * .085, y)
        ..lineTo(cx + u * .115, yFoot)
        ..lineTo(cx - u * .115, yFoot)
        ..close();
      c.drawPath(stair, fill..color = _pagodaStoneLit);
      c.drawPath(
        Sketch.poly([0, y, u * .085, y, u * .115, yFoot, 0, yFoot], at: Offset(cx, 0)),
        fill..color = _pagodaStone,
      );
      final treads = Path();
      for (var k = 1; k < 5; k++) {
        final yy = y + (yFoot - y) * k / 5, half = u * (.085 + .03 * k / 5);
        treads
          ..moveTo(cx - half, yy)
          ..lineTo(cx + half, yy);
      }
      c.drawPath(treads, ink..strokeWidth = hair..color = Sketch.fade(_pagodaDark, .3));
    }
    if (tiers > 3) {
      final posts = Path();
      for (var px = -.38; px <= .381; px += .055) {
        posts.addRect(Rect.fromLTWH(cx + px * u - u * .004, y - u * .028, u * .008, u * .028));
      }
      c.drawPath(posts, fill..color = _pagodaStoneLit);
      c.drawLine(Offset(cx - u * .4, y - u * .028), Offset(cx + u * .4, y - u * .028), ink..strokeWidth = hair * 1.5..color = _pagodaStone);
    }
    var lastTip = Offset.zero;
    for (var i = 0; i < tiers; i++) {
      final hw = u * (.15 - .0105 * i);
      final bh = u * (i == 0 && tiers > 3 ? .12 : .104 - .003 * i);
      final rise = u * (.06 - .0022 * i);
      final curl = u * (.032 - .0012 * i);
      final ew = hw * 1.95;
      final yTop = y - bh, f = hw * .42;
      // Brick storey: a lit, a front and a shaded facet of the octagon.
      c.drawRect(Rect.fromLTRB(cx - hw, yTop, cx - f, y), fill..color = _pagodaBrickLit);
      c.drawRect(Rect.fromLTRB(cx - f, yTop, cx + f, y), fill..color = _pagodaBrick);
      c.drawRect(Rect.fromLTRB(cx + f, yTop, cx + hw, y), fill..color = _pagodaBrickShade);
      final bricks = Path();
      for (var yy = y - u * .02; yy > yTop + u * .012; yy -= u * .02) {
        bricks
          ..moveTo(cx - hw, yy)
          ..lineTo(cx + hw, yy);
      }
      for (final px in [-hw, -f, f, hw]) {
        bricks
          ..moveTo(cx + px, yTop)
          ..lineTo(cx + px, y);
      }
      c.drawPath(bricks, ink..strokeWidth = hair..color = Sketch.fade(_pagodaDark, .2));
      c.drawLine(Offset(cx - hw, yTop), Offset(cx - hw, y), ink..strokeWidth = hair * 1.5..color = Sketch.fade(_pagodaRim, .55));
      if (i == 0 && tiers > 3) {
        c.drawPath(_pagodaArch(cx, y, hw * .2, bh * .66), fill..color = _pagodaDark);
        c.drawPath(_pagodaArch(cx, y, hw * .13, bh * .55), fill..color = Sketch.mix(_pagodaGlow, _pagodaDark, .3));
      } else {
        final lit = i.isOdd && tiers > 3;
        c.drawPath(_pagodaArch(cx, y - bh * .16, hw * .17, bh * .56), fill..color = lit ? Sketch.mix(_pagodaGlow, _pagodaDark, .28) : Sketch.fade(_pagodaDark, .85));
      }
      // Balcony rail resting on the roof below.
      if (i > 0 || tiers <= 3) {
        c.drawRect(Rect.fromLTRB(cx - hw * 1.16, y - u * .012, cx + hw * 1.16, y + u * .004), fill..color = Sketch.mix(_pagodaStone, _pagodaStoneShade, .3));
        c.drawLine(Offset(cx - hw * 1.16, y - u * .012), Offset(cx + hw * 1.16, y - u * .012), ink..strokeWidth = hair * 1.2..color = Sketch.fade(_pagodaRim, .4));
      }
      _pagodaEave(c, cx, yTop, hw, ew, ew * .34, rise, curl, u);
      lastTip = Offset(ew, yTop + curl * .55 - curl * 1.35);
      y = yTop - rise + u * .006;
    }
    // Sumeru finial: drum, bowl, wheel of rings, flame and pearl, with the
    // iron chains that tie it to the roof corners.
    if (tiers > 3) {
      final chain = Path();
      for (final sg in const [-1.0, 1.0]) {
        chain
          ..moveTo(cx, y - u * .1)
          ..lineTo(cx + sg * lastTip.dx * .96, lastTip.dy);
      }
      c.drawPath(chain, ink..strokeWidth = hair * .8..color = Sketch.fade(_pagodaDark, .4));
    }
    final scale = tiers > 3 ? 1.0 : .8;
    c.drawRect(Rect.fromLTRB(cx - u * .022 * scale, y - u * .02 * scale, cx + u * .022 * scale, y + u * .004), fill..color = _pagodaStone);
    y -= u * .02 * scale;
    c.drawPath(
      Path()
        ..moveTo(cx - u * .032 * scale, y)
        ..quadraticBezierTo(cx - u * .03 * scale, y - u * .036 * scale, cx, y - u * .036 * scale)
        ..quadraticBezierTo(cx + u * .03 * scale, y - u * .036 * scale, cx + u * .032 * scale, y)
        ..close(),
      fill..color = _pagodaStoneShade,
    );
    y -= u * .034 * scale;
    for (var k = 0; k < 6; k++) {
      final half = u * scale * (.026 - k * .0028);
      c.drawRect(Rect.fromLTRB(cx - half, y - u * .009 * scale, cx + half, y), fill..color = _pagodaGold);
      y -= u * .0125 * scale;
    }
    c.drawPath(
      Path()
        ..moveTo(cx, y - u * .05 * scale)
        ..quadraticBezierTo(cx + u * .02 * scale, y - u * .018 * scale, cx, y)
        ..quadraticBezierTo(cx - u * .02 * scale, y - u * .018 * scale, cx, y - u * .05 * scale)
        ..close(),
      fill..color = _pagodaGold,
    );
    y -= u * .05 * scale;
    c.drawCircle(Offset(cx, y - u * .006), math.max(.6, u * .01 * scale), fill..color = _pagodaRim);
    return y - u * .016;
  }

  /// A small bronze tripod censer on the terrace, where the incense burns.
  static void _pagodaCenser(Canvas c, double x, double y, double u) {
    final fill = Paint()..color = _pagodaDark;
    c.drawPath(Sketch.poly([-.026, -.045, .026, -.045, .02, -.016, -.02, -.016], at: Offset(x, y), s: u), fill);
    c.drawRect(Rect.fromLTRB(x - u * .03, y - u * .05, x + u * .03, y - u * .043), fill..color = _pagodaGold);
    c.drawPath(
      Path()
        ..moveTo(x - u * .02, y - u * .05)
        ..quadraticBezierTo(x, y - u * .075, x + u * .02, y - u * .05)
        ..close(),
      fill..color = _pagodaDark,
    );
    for (final dx in const [-.016, .016]) {
      c.drawRect(Rect.fromLTRB(x + (dx - .004) * u, y - u * .018, x + (dx + .004) * u, y), fill..color = _pagodaDark);
    }
  }

  /// A small red three-bay gateway across the temple stair.
  static void _pagodaGate(Canvas c, double cx, double y, double u) {
    final fill = Paint();
    for (final sg in const [-1.0, 1.0]) {
      final px = cx + sg * u * .135;
      c.drawRect(Rect.fromLTRB(px - u * .009, y - u * .1, px + u * .009, y), fill..color = sg < 0 ? _pagodaLacquerLit : _pagodaLacquerShade);
      c.drawRect(Rect.fromLTRB(px - u * .015, y - u * .012, px + u * .015, y + u * .004), fill..color = _pagodaStoneShade);
    }
    c.drawRect(Rect.fromLTRB(cx - u * .152, y - u * .108, cx + u * .152, y - u * .09), fill..color = _pagodaLacquer);
    c.drawRect(Rect.fromLTRB(cx - u * .152, y - u * .1, cx + u * .152, y - u * .096), fill..color = Sketch.fade(_pagodaGold, .7));
    _pagodaEave(c, cx, y - u * .108, u * .15, u * .23, u * .13, u * .034, u * .017, u, ends: true);
  }

  /// The moving parts of the hill temple, in the space of [_pagoda]: incense
  /// curling up from the censer, a string of pennants and a few doves
  /// circling the finial. Cheap: about a dozen draws, all from the clock.
  void _pagodaLive(Canvas c, SceneFrame f) {
    final h = f.h, s = h * .2, cx = f.w * .86, t = f.clock;
    double top(double dx) => _pagodaTop(cx, s, dx);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Incense: a thin wisp that fades as it climbs, swaying on the breeze.
    final ix = cx - s * .5, iy = top(-.5) + s * .02 - s * .075;
    Offset smoke(int j) => Offset(
      ix + math.sin(t * .7 + j * .8) * s * (.004 + .005 * j) + j * j * s * .0016,
      iy - j * s * .07,
    );
    for (var k = 0; k < 4; k++) {
      final path = Path()..moveTo(smoke(k * 2).dx, smoke(k * 2).dy);
      path
        ..lineTo(smoke(k * 2 + 1).dx, smoke(k * 2 + 1).dy)
        ..lineTo(smoke(k * 2 + 2).dx, smoke(k * 2 + 2).dy);
      c.drawPath(
        path,
        ink
          ..strokeWidth = s * (.016 - k * .002)
          ..color = Sketch.fade(_pagodaSmoke, .42 - k * .1),
      );
    }
    // Pennants on a string between the bell tower and a pole.
    final pole = Offset(cx + s * 1.52, top(1.52) + s * .03);
    final poleTop = pole + Offset(0, -s * .34);
    final tip = Offset(cx + s * 1.17, top(1.0) + s * .02 - s * .176);
    c.drawLine(pole, poleTop, ink..strokeWidth = math.max(.6, s * .008)..color = _pagodaDark);
    final sag = Offset((tip.dx + poleTop.dx) / 2, (tip.dy + poleTop.dy) / 2 + s * .03);
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(sag.dx, sag.dy + s * .03, poleTop.dx, poleTop.dy),
      ink..strokeWidth = math.max(.5, s * .004)..color = Sketch.fade(_pagodaDark, .7),
    );
    final flags = [Path(), Path(), Path()];
    for (var i = 0; i < 6; i++) {
      final u = (i + .7) / 6.4;
      // Point on the quadratic string.
      final x = (1 - u) * (1 - u) * tip.dx + 2 * (1 - u) * u * sag.dx + u * u * poleTop.dx;
      final y = (1 - u) * (1 - u) * tip.dy + 2 * (1 - u) * u * (sag.dy + s * .03) + u * u * poleTop.dy;
      final wave = math.sin(t * 3.2 + i * 1.1) * s * .008;
      flags[i % 3]
        ..moveTo(x - s * .012, y)
        ..lineTo(x + s * .012, y)
        ..lineTo(x + wave, y + s * .05);
    }
    for (var k = 0; k < 3; k++) {
      c.drawPath(flags[k], Paint()..color = _pagodaFlags[k]);
    }
    // Doves wheeling around the finial.
    final dove = Sketch.fade(_pagodaDark, .55);
    final centre = Offset(cx, top(0) - s * 1.05);
    for (var i = 0; i < 3; i++) {
      final a = t * (.32 + .04 * i) + i * 2.1;
      final p = centre + Offset(math.cos(a) * s * (.55 + .12 * i), math.sin(a * 1.3) * s * (.12 + .04 * i));
      Sketch.bird(c, p, s * .034, dove, flap: math.sin(t * 4.2 + i * 1.7) * .6);
    }
  }

  // ---------------------------------------------------------------------------
  // Shore: the near bank, one repeating garden scroll. Standing pieces are
  // recorded behind the bank (`_shoreFeatures`); everything that lies on the
  // bank itself is one cached picture drawn over it (`_shoreGround`).

  static const _shoreInk = Color(0xff20363a);
  static const _shoreRim = Color(0xffefc4a8);

  /// Direction to the low sun: up, and a little to the right.
  static const _shoreSun = Offset(.55, -.85);

  // Set pieces as x in viewport heights within the 3.4 h period.
  static const _shoreBoulderX = .2,
      _shorePineX = .5,
      _shoreScholarX = 1.02,
      _shoreBambooX = 1.44,
      _shorePondX = 1.86,
      _shorePavilionX = 2.5,
      _shoreLanternX = 2.9,
      _shorePlumX = 3.14,
      _shoreCloseBambooX = 3.4;

  /// Highest-ground-first: the lowest bank line (largest y) across a stretch,
  /// so a piece whose foot sits there stays buried on the whole stretch.
  double _shoreFoot(double x, double half, double h) {
    var y = 0.0;
    for (var i = -2; i <= 2; i++) {
      y = math.max(y, ridge(Depth.near, x + half * i / 2, 0));
    }
    return y * h;
  }

  void _shoreFeatures(Canvas c, double h) {
    // A hazed rank of bamboo stands far back, behind the pine.
    _shoreBamboo(c, Offset((_shoreBambooX + .55) * h, _shoreFoot(_shoreBambooX + .55, .1, h) + h * .012), h, 41, culms: 7, haze: .34, tall: .85);
    _shorePine(c, Offset(_shorePineX * h, _shoreFoot(_shorePineX, .04, h) + h * .012), h * .25);
    _shoreBamboo(c, Offset(_shoreBambooX * h, _shoreFoot(_shoreBambooX, .1, h) + h * .012), h, 7, culms: 9);
    _rock(c, Offset(_shoreScholarX * h, _shoreFoot(_shoreScholarX, .06, h) + h * .008), h * .066);
    _rock(c, Offset(_shoreBoulderX * h, _shoreFoot(_shoreBoulderX, .05, h) + h * .008), h * .036, kind: 1);
    _rock(c, Offset((_shorePineX + .3) * h, _shoreFoot(_shorePineX + .3, .04, h) + h * .008), h * .022, kind: 1);
    final pav = _shorePavilionX;
    _pavilion(c, Offset(pav * h, _shoreFoot(pav, .13, h) - h * .012), h * .076);
    _shoreLantern(c, Offset(_shoreLanternX * h, _shoreFoot(_shoreLanternX, .02, h) + h * .008), h * .042);
    _plum(c, Offset(_shorePlumX * h, _shoreFoot(_shorePlumX, .04, h) + h * .012), h * .21);
    _shoreBamboo(c, Offset(_shoreCloseBambooX * h, _shoreFoot(_shoreCloseBambooX, .1, h) + h * .012), h, 23, culms: 8, tall: .9);
  }

  /// A smooth closed curve through [p] (Catmull-Rom turned into cubics).
  static Path _shoreBlob(List<Offset> p) {
    final n = p.length;
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < n; i++) {
      final a = p[(i + n - 1) % n], b = p[i], d = p[(i + 1) % n], e = p[(i + 2) % n];
      final c1 = b + (d - a) / 6, c2 = d - (e - b) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, d.dx, d.dy);
    }
    return path..close();
  }

  /// Unit (x, y) pairs scaled by [s] around [at].
  static List<Offset> _shorePts(List<double> xy, Offset at, double s) => [
    for (var i = 0; i + 1 < xy.length; i += 2)
      Offset(at.dx + xy[i] * s, at.dy + xy[i + 1] * s),
  ];

  /// The edge of [base] that faces the sun (or, with a negative [d], faces away):
  /// what a copy of the shape moved by [d] leaves uncovered.
  static void _shoreEdge(Canvas c, Path base, double d, Color color) {
    final by = _shoreSun * -d;
    c.drawPath(
      Path.combine(PathOperation.difference, base, base.shift(by)),
      Paint()..color = color,
    );
  }

  /// A flat cloud of needles: dark underside, mid body, a sunlit crown, fuzzy
  /// tips above and a few tufts hanging below.
  static void _shoreNeedles(Canvas c, Offset at, double w, double h, int seed) {
    final n = math.max(3, (w / (h * 1.15)).round() + 2);
    final under = Path(), body = Path(), top = Path();
    final fuzz = Path(), hang = Path(), spark = Path();
    for (var i = 0; i < n; i++) {
      final t = (i + .5) / n;
      final k = 1 - math.pow(2 * t - 1, 2).toDouble() * .55;
      final bw = w / n * (1.85 + .35 * Sketch.hash(seed + i));
      final bh = h * (.62 + .38 * k) * (.86 + .28 * Sketch.hash(seed + i * 7 + 1));
      final cx = at.dx + (t - .5) * w * .86;
      final cy = at.dy - (k - .6) * h * .3 + (Sketch.hash(seed + i * 3) - .5) * h * .12;
      under.addOval(Rect.fromCenter(center: Offset(cx, cy + h * .14), width: bw * 1.05, height: bh));
      body.addOval(Rect.fromCenter(center: Offset(cx, cy - h * .02), width: bw, height: bh * .86));
      top.addOval(Rect.fromCenter(center: Offset(cx + bw * .1, cy - h * .16), width: bw * .74, height: bh * .48));
      if (i.isEven) {
        hang.moveTo(cx - bw * .2, cy + h * .34);
        hang.lineTo(cx - bw * .3, cy + h * .34 + h * .3);
        hang.moveTo(cx + bw * .08, cy + h * .38);
        hang.lineTo(cx + bw * .04, cy + h * .38 + h * .36);
      }
    }
    // Needle sprays fuzz the upper outline.
    final m = n * 3;
    for (var i = 0; i < m; i++) {
      final a = -math.pi * (.06 + .88 * (i + Sketch.hash(seed + i * 5)) / m);
      final rx = w * .46, ry = h * .5;
      final e = Offset(at.dx + math.cos(a) * rx, at.dy - h * .06 + math.sin(a) * ry);
      final l = h * (.16 + .16 * Sketch.hash(seed + i * 9 + 2));
      final tip = e + Offset(math.cos(a) * l * .6, math.sin(a) * l);
      (i % 3 == 0 ? spark : fuzz)
        ..moveTo(e.dx, e.dy)
        ..lineTo(tip.dx, tip.dy);
    }
    // Brush-stroke needle arcs: dark across the body, pale along the crown.
    final arcDark = Path(), arcLit = Path();
    for (var i = 0; i < n * 3; i++) {
      final t = (i + .5 + (Sketch.hash(seed + i * 11) - .5) * .8) / (n * 3);
      final k = 1 - math.pow(2 * t - 1, 2).toDouble() * .5;
      final x = at.dx + (t - .5) * w * .8;
      final crown = i.isEven;
      final y = at.dy - h * (crown ? .12 + .18 * k : -.06 + .16 * Sketch.hash(seed + i * 5)) - (k - .6) * h * .28;
      final len = h * (.2 + .12 * Sketch.hash(seed + i * 3 + 1));
      (crown ? arcLit : arcDark)
        ..moveTo(x - len, y + len * .18)
        ..quadraticBezierTo(x, y - len * .32, x + len, y + len * .18);
    }
    final ink = Sketch.mix(const Color(0xff2b4743), _shoreInk, .3);
    c.drawPath(under, Paint()..color = ink);
    c.drawPath(
      hang,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, h * .07)
        ..color = ink,
    );
    c.drawPath(body, Paint()..color = const Color(0xff37594f));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .06);
    c.drawPath(fuzz, stroke..color = const Color(0xff37594f));
    c.drawPath(arcDark, stroke..color = Sketch.fade(ink, .55)..strokeWidth = math.max(.7, h * .045));
    c.drawPath(top, Paint()..color = const Color(0xff5a8571));
    c.drawPath(arcLit, stroke..color = Sketch.fade(const Color(0xff8db597), .55)..strokeWidth = math.max(.7, h * .04));
    c.drawPath(spark, stroke..color = Sketch.mix(const Color(0xff7fa88b), _shoreRim, .3));
  }

  /// A windswept pine: a twisted, scaly trunk, long limbs and flat needle clouds.
  static void _shorePine(Canvas c, Offset base, double s) {
    const bark = Color(0xff4c3b3b), barkDark = Color(0xff2d2427);
    final barkLit = Sketch.mix(const Color(0xff9a7462), _shoreRim, .25);
    const p1 = Offset(-.17, -.32), p2 = Offset(.18, -.62), p3 = Offset(0, -1);
    Offset centre(double t) {
      final u = 1 - t;
      return base + (p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)) * s;
    }

    const n = 26;
    final left = <Offset>[], right = <Offset>[], inner = <Offset>[], edge = <Offset>[];
    final crack = Path(), furrow = Path(), plates = Path();
    var furrowOpen = false;
    for (var i = 0; i <= n; i++) {
      final t = i / n, u = 1 - t;
      final d = p1 * (3 * u * u) + (p2 - p1) * (6 * u * t) + (p3 - p2) * (3 * t * t);
      final r = Offset(-d.dy, d.dx) / d.distance;
      final w = s * (.05 * (1 - .55 * t) + .06 * math.exp(-t * 16));
      final ctr = centre(t);
      left.add(ctr - r * w);
      right.add(ctr + r * w);
      inner.add(ctr + r * w * .15);
      edge.add(ctr + r * w * .62);
      if (i > 0 && i < n) {
        if (i.isOdd) {
          crack.moveTo(ctr.dx + r.dx * w * (-.7 + .4 * Sketch.hash(i + 500)), ctr.dy + r.dy * w * (-.7 + .4 * Sketch.hash(i + 500)));
          crack.lineTo(ctr.dx + r.dx * w * (.05 + .4 * Sketch.hash(i + 520)), ctr.dy + r.dy * w * .3 + s * .012);
        }
        final o = ctr - r * w * .45;
        if (Sketch.hash(i + 540) > .3 && furrowOpen) {
          furrow.lineTo(o.dx, o.dy);
        } else {
          furrow.moveTo(o.dx, o.dy);
          furrowOpen = Sketch.hash(i + 540) > .3;
        }
        if (i % 3 == 1) {
          final o = ctr + r * w * .55;
          plates.addOval(Rect.fromCenter(center: o, width: w * .5, height: s * .022));
        }
      }
    }
    c.drawPath(Path()..addPolygon([...left, ...right.reversed], true), Paint()..color = bark);
    c.drawPath(Path()..addPolygon([...edge, ...inner.reversed], true), Paint()..color = Sketch.mix(bark, barkLit, .38));
    c.drawPath(Path()..addPolygon([...right, ...edge.reversed], true), Paint()..color = barkLit);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, s * .008)
      ..color = Sketch.fade(barkDark, .75);
    c.drawPath(furrow, line);
    c.drawPath(crack, line);
    c.drawPath(plates, Paint()..color = Sketch.fade(barkLit, .55));

    void limb(Offset from, Offset to, double sag, double w0, double w1) {
      final ctl = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) + sag * s);
      final top = <Offset>[], bot = <Offset>[];
      for (var i = 0; i <= 10; i++) {
        final t = i / 10, u = 1 - t;
        final p = from * (u * u) + ctl * (2 * u * t) + to * (t * t);
        final d = (ctl - from) * (2 * u) + (to - ctl) * (2 * t);
        final r = Offset(-d.dy, d.dx) / d.distance;
        final w = s * (w0 + (w1 - w0) * t);
        top.add(p - r * w * (d.dx > 0 ? 1 : -1));
        bot.add(p + r * w * (d.dx > 0 ? 1 : -1));
      }
      c.drawPath(Path()..addPolygon([...top, ...bot.reversed], true), Paint()..color = bark);
      c.drawPath(
        Path()..addPolygon(top, false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, s * .007)
          ..strokeCap = StrokeCap.round
          ..color = Sketch.fade(barkLit, .7),
      );
    }

    final cone = Paint()..color = const Color(0xff6b4a3c);
    // (attach on trunk, tip x, tip y, sag, cloud width, cloud height): back limbs first.
    const limbs = [
      (.3, -.7, -.42, .02, .5, .13),
      (.46, .68, -.62, .03, .52, .13),
      (.6, -.46, -.8, .02, .42, .12),
      (.76, .44, -.94, .03, .34, .11),
    ];
    for (final (i, (t, tx, ty, sag, cw, ch)) in limbs.indexed) {
      final from = centre(t);
      final to = base + Offset(tx, ty) * s;
      limb(from, to, sag, .022, .009);
      // A second, smaller cloud partway along the limb.
      final mid = Offset.lerp(from, to, .55)!;
      _shoreNeedles(c, mid + Offset(0, -s * .05), s * cw * .5, s * ch * .8, 100 + i * 31);
      _shoreNeedles(c, to + Offset(0, -s * .05), s * cw, s * ch, 200 + i * 17);
      c.drawOval(Rect.fromCenter(center: to + Offset(s * cw * (tx > 0 ? .28 : -.28), s * ch * .62), width: s * .022, height: s * .034), cone);
    }
    _shoreNeedles(c, centre(1) + Offset(s * .02, -s * .08), s * .46, s * .17, 300);
    // A small bird rests on the crown of the lowest cloud.
    final perch = base + Offset(-.62, -.5) * s;
    final bird = Paint()..color = const Color(0xff2d3540);
    c.drawOval(Rect.fromCenter(center: perch + Offset(0, -s * .028), width: s * .075, height: s * .05), bird);
    c.drawCircle(perch + Offset(s * .034, -s * .058), s * .02, bird);
    c.drawPath(Sketch.poly([-.03, -.03, -.09, -.045, -.08, -.005], at: perch, s: s), bird);
    c.drawOval(Rect.fromCenter(center: perch + Offset(s * .012, -s * .02), width: s * .04, height: s * .028), Paint()..color = const Color(0xffb9b4bd));
    c.drawPath(Sketch.poly([.05, -.062, .075, -.056, .05, -.052], at: perch, s: s), Paint()..color = const Color(0xffcfa25a));
  }

  /// A water-worn scholar's rock: tall, pierced and wrinkled with moss at
  /// its foot ([kind] 0), or a squat mossy boulder ([kind] 1).
  static void _rock(Canvas c, Offset base, double s, {int kind = 0}) {
    final tall = kind == 0;
    final outline = _shoreBlob(_shorePts(
      tall
          ? const [-.95, .3, -.98, -.1, -.78, -.5, -.9, -.95, -.72, -1.45, -.82, -1.95, -.6, -2.4, -.25, -2.75, .05, -2.58, .3, -2.95, .62, -2.6, .5, -2.15, .72, -1.75, .55, -1.25, .85, -.8, .72, -.4, .95, -.05, .9, .3]
          : const [-1, .3, -1.06, -.25, -.76, -.72, -.2, -.96, .4, -.88, .86, -.6, 1.06, -.15, .96, .3],
      base,
      s,
    ));
    var rock = outline;
    if (tall) {
      for (final (hx, hy, rx, ry, rot) in const [
        (-.02, -1.68, .3, .5, .2),
        (.08, -.72, .2, .26, -.3),
      ]) {
        final pts = <Offset>[
          for (var i = 0; i < 9; i++)
            () {
              final a = i / 9 * math.pi * 2;
              final wob = 1 + .14 * math.sin(a * 3 + hx * 9);
              final x = math.cos(a) * rx * wob, y = math.sin(a) * ry * wob;
              return base + Offset(x * math.cos(rot) - y * math.sin(rot) + hx, x * math.sin(rot) + y * math.cos(rot) + hy) * s;
            }(),
        ];
        rock = Path.combine(PathOperation.difference, rock, _shoreBlob(pts));
      }
    }
    final palette = tall
        ? const [Color(0xff7b8d88), Color(0xff4a5e60), Color(0xffb4c1b3)]
        : const [Color(0xff6a7b74), Color(0xff425456), Color(0xff9dad9f)];
    c.drawPath(rock, Paint()..color = palette[0]);
    _shoreEdge(c, rock, -s * .5, Sketch.fade(palette[1], .55));
    _shoreEdge(c, rock, -s * .2, Sketch.fade(_shoreInk, .5));
    _shoreEdge(c, rock, s * .32, Sketch.fade(palette[2], .7));
    _shoreEdge(c, rock, s * .07, Sketch.mix(palette[2], _shoreRim, .7));
    // Wrinkles that follow the stone's flow.
    final wrinkle = Path(), pits = Path();
    final marks = tall
        ? const [-.72, -.35, -.55, -.65, -.7, -.95, -.6, -1.5, -.52, -1.75, -.6, -2.05, .38, -1.4, .5, -1.6, .45, -1.95, .6, -.95, .7, -1.15, .6, -1.45, -.4, -.15, -.2, -.35, -.3, -.55, .3, -.15, .55, -.35, .6, -.5, -.3, -2.3, -.15, -2.5, -.05, -2.4, .35, -2.5, .4, -2.7, .5, -2.4]
        : const [-.7, -.3, -.4, -.55, -.1, -.5, .2, -.4, .5, -.3, .7, -.2];
    for (var i = 0; i + 5 < marks.length; i += 6) {
      final a = base + Offset(marks[i], marks[i + 1]) * s;
      final m = base + Offset(marks[i + 2], marks[i + 3]) * s;
      final b = base + Offset(marks[i + 4], marks[i + 5]) * s;
      wrinkle
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(m.dx, m.dy, b.dx, b.dy);
    }
    for (var i = 0; i < (tall ? 9 : 4); i++) {
      final p = base + Offset(-.7 + 1.4 * Sketch.hash(i + 610), -(.15 + (tall ? 2.0 : .6) * Sketch.hash(i + 620))) * s;
      pits.addOval(Rect.fromCenter(center: p, width: s * .12, height: s * .07));
    }
    c.save();
    c.clipPath(rock);
    c.drawPath(
      wrinkle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, s * .03)
        ..color = Sketch.fade(_shoreInk, .38),
    );
    c.drawPath(pits, Paint()..color = Sketch.fade(_shoreInk, .5));
    c.restore();
    // Moss climbs from the foot and caps the ledges.
    final moss = Path();
    for (var i = 0; i < (tall ? 6 : 6); i++) {
      final x = -.95 + 1.9 * (i + Sketch.hash(i + 630) * .6) / (tall ? 6 : 6);
      final y = -(.02 + (tall ? .3 : .28) * Sketch.hash(i + 640));
      moss.addOval(Rect.fromCenter(center: base + Offset(x, y) * s, width: s * (.3 + .3 * Sketch.hash(i + 650)), height: s * (.2 + .18 * Sketch.hash(i + 660))));
    }
    if (tall) {
      moss.addOval(Rect.fromCenter(center: base + Offset(.3, -2.85) * s, width: s * .5, height: s * .16));
      moss.addOval(Rect.fromCenter(center: base + Offset(-.5, -2.5) * s, width: s * .4, height: s * .14));
      moss.addOval(Rect.fromCenter(center: base + Offset(.78, -.84) * s, width: s * .35, height: s * .12));
    } else {
      moss.addOval(Rect.fromCenter(center: base + Offset(.1, -.95) * s, width: s * 1.1, height: s * .3));
    }
    final mossCut = Path.combine(PathOperation.intersect, rock, moss);
    c.drawPath(mossCut, Paint()..color = const Color(0xff466f4f));
    _shoreEdge(c, mossCut, s * .08, Sketch.mix(const Color(0xff7fa974), _shoreRim, .25));
  }

  /// A garden pavilion on a stone terrace: red columns, a painted beam, a
  /// hanging lattice fascia, benches, and a two-tier roof with upswept eaves.
  static void _pavilion(Canvas c, Offset base, double s) {
    const column = Color(0xffae4238), columnDark = Color(0xff6f2b2e), gold = Color(0xffd6a852);
    const roof = Color(0xff35544f), roofLit = Color(0xff628a7f), interior = Color(0xff2a2528);
    const stone = Color(0xff8b8d89), stoneDark = Color(0xff5f6767);
    Offset p(double x, double y) => Offset(base.dx + x * s, base.dy + y * s);
    Rect r(double x0, double y0, double x1, double y1) => Rect.fromPoints(p(x0, y0), p(x1, y1));
    final fill = Paint();
    Paint col(Color color) => fill..color = color;
    final hair = math.max(.6, s * .012);

    // The dim room behind the columns: a low table, two stools, a hung lantern.
    c.drawRect(r(-.82, -1, .82, -.3), col(interior));
    c.drawRect(r(-.82, -.42, .82, -.3), col(Sketch.mix(interior, stoneDark, .25)));
    c.drawRect(r(-.18, -.52, .18, -.47), col(const Color(0xff4a4143)));
    c.drawRect(r(-.13, -.47, -.1, -.3), col(const Color(0xff3c3538)));
    c.drawRect(r(.1, -.47, .13, -.3), col(const Color(0xff3c3538)));
    for (final dx in const [-.36, .36]) {
      c.drawOval(Rect.fromCenter(center: p(dx, -.4), width: s * .17, height: s * .07), col(const Color(0xff4a4143)));
    }
    c.drawLine(p(0, -1), p(0, -.86), Paint()..color = Sketch.fade(gold, .6)..strokeWidth = hair);
    c.drawOval(Rect.fromCenter(center: p(0, -.8), width: s * .13, height: s * .16), col(const Color(0xff9c3a34)));
    c.drawOval(Rect.fromCenter(center: p(.015, -.81), width: s * .05, height: s * .08), col(const Color(0xffc9695a)));

    // Terrace: cut stone with a lit lip, joints, and three steps up.
    c.drawRect(r(-1.14, -.34, 1.14, .7), col(stone));
    c.drawRect(r(-1.14, -.34, 1.14, -.27), col(Sketch.mix(const Color(0xffc9c5b8), _shoreRim, .28)));
    c.drawRect(r(-1.14, -.27, 1.14, -.2), col(stoneDark));
    c.drawRect(r(-1.14, -.2, -1.1, .7), col(Sketch.fade(_shoreInk, .3)));
    final joints = Path();
    for (var k = -2.6; k <= 2.7; k += .4) {
      joints
        ..moveTo(base.dx + k * s * .42, base.dy - s * .2)
        ..lineTo(base.dx + k * s * .42, base.dy + s * .7);
    }
    joints
      ..moveTo(base.dx - s * 1.14, base.dy + s * .12)
      ..lineTo(base.dx + s * 1.14, base.dy + s * .12);
    c.drawPath(joints, Paint()..style = PaintingStyle.stroke..strokeWidth = hair..color = Sketch.fade(_shoreInk, .3));
    for (final (k, half, y0, y1) in const [(0, .56, .04, .7), (1, .46, -.08, .04), (2, .36, -.2, -.08)]) {
      c.drawRect(r(-half, y0, half, y1), col(k.isEven ? const Color(0xff9a9b95) : const Color(0xffb4b2a8)));
      c.drawRect(r(-half, y0, half, y0 + .035), col(Sketch.mix(const Color(0xffe0d8c8), _shoreRim, .3)));
      c.drawRect(r(-half, y0 + .035, half, y0 + .07), col(Sketch.fade(_shoreInk, .3)));
    }

    // Benches in the outer bays: a seat, a curved backrest and slats.
    final slats = Path();
    for (final side in const [-1.0, 1.0]) {
      final x0 = side < 0 ? -.8 : .3, x1 = side < 0 ? -.3 : .8;
      c.drawRect(r(x0, -.56, x1, -.5), col(columnDark));
      c.drawRect(r(x0, -.5, x1, -.34), col(Sketch.fade(_shoreInk, .55)));
      c.drawRect(r(x0, -.78, x1, -.73), col(column));
      for (var x = x0 + .05; x < x1; x += .07) {
        slats
          ..moveTo(base.dx + x * s, base.dy - s * .73)
          ..lineTo(base.dx + x * s, base.dy - s * .56);
      }
    }
    c.drawPath(slats, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.6, s * .014)..color = Sketch.fade(columnDark, .95));

    // Columns: shade side, sunlit side, stone plinth and a gilded collar.
    for (final x in const [-.8, -.3, .3, .8]) {
      c.drawRect(r(x - .05, -1, x + .05, -.3), col(column));
      c.drawRect(r(x - .05, -1, x - .02, -.3), col(Sketch.fade(columnDark, .6)));
      c.drawRect(r(x + .022, -1, x + .05, -.3), col(Sketch.mix(const Color(0xffd7786a), _shoreRim, .3)));
      c.drawRect(r(x - .075, -.37, x + .075, -.3), col(const Color(0xff7d807c)));
      c.drawRect(r(x - .065, -1, x + .065, -.95), col(gold));
    }
    // The hanging lattice fascia below the beam.
    final fascia = Path();
    for (var x = -.8; x < .79; x += .1) {
      fascia
        ..moveTo(base.dx + x * s, base.dy - s * .95)
        ..lineTo(base.dx + (x + .1) * s, base.dy - s * .95)
        ..lineTo(base.dx + (x + .05) * s, base.dy - s * .84)
        ..close();
    }
    c.drawPath(fascia, Paint()..color = Sketch.fade(gold, .85));
    // Painted beam: verdigris ground, gold studs and a red fillet.
    c.drawRect(r(-1, -1.1, 1, -.98), col(const Color(0xff2e6d67)));
    c.drawRect(r(-1, -1.1, 1, -1.075), col(const Color(0xff9f3d38)));
    final studs = Path();
    for (var x = -.94; x < .95; x += .125) {
      studs.addRect(r(x, -1.05, x + .05, -1.005));
    }
    c.drawPath(studs, Paint()..color = Sketch.fade(gold, .9));
    for (final side in const [-1.0, 1.0]) {
      c.drawCircle(p(side * 1.0, -1.04), s * .055, col(gold));
    }
    c.drawRect(r(-1.06, -1.17, 1.06, -1.1), col(const Color(0xff1f2c2f)));

    // Lower roof: two upswept eaves and a concave slope.
    final lower = Path()
      ..moveTo(base.dx - s * 1.52, base.dy - s * 1.36)
      ..quadraticBezierTo(base.dx - s * 1.24, base.dy - s * 1.12, base.dx - s * .92, base.dy - s * 1.12)
      ..lineTo(base.dx + s * .92, base.dy - s * 1.12)
      ..quadraticBezierTo(base.dx + s * 1.24, base.dy - s * 1.12, base.dx + s * 1.52, base.dy - s * 1.36)
      ..quadraticBezierTo(base.dx + s * .98, base.dy - s * 1.38, base.dx + s * .52, base.dy - s * 1.7)
      ..lineTo(base.dx - s * .52, base.dy - s * 1.7)
      ..quadraticBezierTo(base.dx - s * .98, base.dy - s * 1.38, base.dx - s * 1.52, base.dy - s * 1.36)
      ..close();
    // Neck between the tiers, with lattice lights.
    c.drawRect(r(-.5, -1.9, .5, -1.66), col(const Color(0xff9d3b36)));
    c.drawRect(r(-.5, -1.9, -.44, -1.66), col(Sketch.fade(columnDark, .6)));
    for (final x in const [-.34, -.06, .22]) {
      c.drawRect(r(x, -1.86, x + .16, -1.7), col(const Color(0xff33272a)));
      c.drawRect(r(x + .07, -1.86, x + .09, -1.7), col(Sketch.fade(gold, .55)));
    }
    final lowerEave = Path()
      ..moveTo(base.dx - s * 1.52, base.dy - s * 1.36)
      ..quadraticBezierTo(base.dx - s * 1.24, base.dy - s * 1.12, base.dx - s * .92, base.dy - s * 1.12)
      ..lineTo(base.dx + s * .92, base.dy - s * 1.12)
      ..quadraticBezierTo(base.dx + s * 1.24, base.dy - s * 1.12, base.dx + s * 1.52, base.dy - s * 1.36);
    _shoreRoof(c, lower, lowerEave, base, s, roof, roofLit, gold, spread: 1.36, top: -1.7, lip: -1.13, half: .52);
    final upper = Path()
      ..moveTo(base.dx - s * .98, base.dy - s * 2.08)
      ..quadraticBezierTo(base.dx - s * .78, base.dy - s * 1.9, base.dx - s * .58, base.dy - s * 1.9)
      ..lineTo(base.dx + s * .58, base.dy - s * 1.9)
      ..quadraticBezierTo(base.dx + s * .78, base.dy - s * 1.9, base.dx + s * .98, base.dy - s * 2.08)
      ..quadraticBezierTo(base.dx + s * .62, base.dy - s * 2.1, base.dx + s * .16, base.dy - s * 2.34)
      ..lineTo(base.dx - s * .16, base.dy - s * 2.34)
      ..quadraticBezierTo(base.dx - s * .62, base.dy - s * 2.1, base.dx - s * .98, base.dy - s * 2.08)
      ..close();
    final upperEave = Path()
      ..moveTo(base.dx - s * .98, base.dy - s * 2.08)
      ..quadraticBezierTo(base.dx - s * .78, base.dy - s * 1.9, base.dx - s * .58, base.dy - s * 1.9)
      ..lineTo(base.dx + s * .58, base.dy - s * 1.9)
      ..quadraticBezierTo(base.dx + s * .78, base.dy - s * 1.9, base.dx + s * .98, base.dy - s * 2.08);
    _shoreRoof(c, upper, upperEave, base, s, roof, roofLit, gold, spread: .84, top: -2.34, lip: -1.91, half: .16);
    // Finial: a gilded gourd on a spike.
    c.drawLine(p(0, -2.34), p(0, -2.62), Paint()..color = gold..strokeWidth = math.max(.8, s * .03)..strokeCap = StrokeCap.round);
    c.drawOval(Rect.fromCenter(center: p(0, -2.44), width: s * .13, height: s * .16), col(gold));
    c.drawCircle(p(0, -2.33), s * .06, col(const Color(0xff9f3d38)));
  }

  /// One roof tier: body, sunlit slope, tile rows, gilded ridge and eave, and
  /// a row of drip tiles.
  static void _shoreRoof(Canvas c, Path roof, Path eave, Offset base, double s, Color body, Color lit, Color gold, {required double spread, required double top, required double lip, required double half}) {
    c.drawPath(roof, Paint()..color = body);
    _shoreEdge(c, roof, -s * .16, Sketch.fade(_shoreInk, .4));
    _shoreEdge(c, roof, s * .2, Sketch.fade(lit, .75));
    _shoreEdge(c, roof, s * .06, Sketch.mix(lit, _shoreRim, .6));
    final tiles = Path(), dark = Path();
    const rows = 13;
    for (var i = 0; i <= rows; i++) {
      final u = i / rows * 2 - 1;
      final xt = u * half, xe = u * spread * .96;
      final ye = lip - math.pow(math.max(0, (xe.abs() - spread * .6) / (spread * .4)), 2) * .16;
      final a = Offset(base.dx + xt * s, base.dy + (top + .03) * s);
      final b = Offset(base.dx + xe * s, base.dy + ye * s);
      (u >= 0 ? tiles : dark)
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    c.save();
    c.clipPath(roof);
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.6, s * .014);
    c.drawPath(tiles, line..color = Sketch.fade(lit, .5));
    c.drawPath(dark, line..color = Sketch.fade(_shoreInk, .4));
    c.restore();
    // Gilded eave line and drip tiles.
    c.drawPath(eave, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.8, s * .035)..color = Sketch.fade(gold, .9));
    final drips = Path();
    for (var x = -spread * .62; x <= spread * .62; x += .11) {
      drips.addOval(Rect.fromCenter(center: Offset(base.dx + x * s, base.dy + (lip + .03) * s), width: s * .06, height: s * .06));
    }
    c.drawPath(drips, Paint()..color = Sketch.fade(gold, .85));
  }

  /// A plum in blossom, as an ink painter draws it: a gnarled dark trunk,
  /// kinked limbs and sprays of pale pink flowers with a few red buds.
  static void _plum(Canvas c, Offset base, double s) {
    const barkC = Color(0xff44323a);
    final barkLit = Sketch.mix(const Color(0xff94706c), _shoreRim, .3);
    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final bark = stroke(barkC), lit = stroke(Sketch.fade(barkLit, .85));
    final tips = <Offset>[], twigs = <Offset>[];
    void branch(Offset from, double a, double len, int depth, int seed) {
      final kink = (Sketch.hash(seed) - .5) * .9;
      final mid = from + Offset(math.cos(a + kink), math.sin(a + kink)) * len * .5;
      final to = mid + Offset(math.cos(a - kink * .7), math.sin(a - kink * .7)) * len * .5;
      final w = math.max(.7, s * (.008 + .0165 * depth));
      final seg = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(to.dx, to.dy);
      c.drawPath(seg, bark..strokeWidth = w);
      if (depth >= 2) c.drawPath(seg.shift(Offset(w * .24, -w * .2)), lit..strokeWidth = w * .3);
      if (depth <= 1) twigs.add(mid);
      if (depth == 0) {
        tips.add(to);
        return;
      }
      branch(to, a - .4 - .3 * Sketch.hash(seed + 1), len * (.68 + .12 * Sketch.hash(seed + 2)), depth - 1, seed * 2 + 1);
      branch(to, a + .38 + .3 * Sketch.hash(seed + 3), len * .66, depth - 1, seed * 2 + 2);
      if (depth == 2 && Sketch.hash(seed + 4) > .35) {
        branch(mid, a + (Sketch.hash(seed + 5) > .5 ? 1 : -1) * .95, len * .5, 0, seed * 2 + 7);
      }
    }

    c.drawOval(Rect.fromCenter(center: base + Offset(0, -s * .02), width: s * .2, height: s * .09), Paint()..color = barkC);
    branch(base, -1.5, s * .34, 4, 3);
    branch(base + Offset(s * .01, -s * .13), -2.5, s * .3, 3, 11);
    branch(base + Offset(-s * .01, -s * .2), -.6, s * .29, 3, 17);
    // Pale lichen on the old wood.
    final lichen = Path();
    for (var i = 0; i < 7; i++) {
      lichen.addOval(Rect.fromCenter(center: base + Offset((Sketch.hash(i + 800) - .5) * s * .05, -s * (.03 + .3 * Sketch.hash(i + 810))), width: s * .022, height: s * .012));
    }
    c.drawPath(lichen, Paint()..color = const Color(0xff9db5a0));

    final glow = Path(), petals = Path(), pale = Path(), warm = Path(), heart = Path(), buds = Path();
    void flower(Offset o, double r, int k) {
      (k % 3 == 0 ? pale : (k % 3 == 1 ? petals : warm)).addOval(Rect.fromCircle(center: o, radius: r));
      heart.addOval(Rect.fromCircle(center: o + Offset(r * .12, r * .1), radius: r * .3));
    }

    for (final (i, t) in tips.indexed) {
      glow.addOval(Rect.fromCircle(center: t, radius: s * .085));
      for (var j = 0; j < 6; j++) {
        final a = Sketch.hash(i * 17 + j + 700) * math.pi * 2;
        final d = s * .065 * math.sqrt(Sketch.hash(i * 19 + j + 720));
        flower(t + Offset(math.cos(a), math.sin(a) * .8) * d, s * (.024 + .012 * Sketch.hash(i * 23 + j + 740)), i + j);
      }
      buds.addOval(Rect.fromCircle(center: t + Offset(s * .03, -s * .05), radius: s * .012));
    }
    for (final (i, t) in twigs.indexed) {
      flower(t, s * .026, i);
      if (i.isOdd) buds.addOval(Rect.fromCircle(center: t + Offset(s * .02, s * .03), radius: s * .011));
    }
    c.drawPath(glow, Paint()..color = const Color(0x2ff7b8c6));
    c.drawPath(petals, Paint()..color = const Color(0xfff2aebf));
    c.drawPath(warm, Paint()..color = Sketch.mix(const Color(0xfff9c9c9), _shoreRim, .25));
    c.drawPath(pale, Paint()..color = const Color(0xfffff0f2));
    c.drawPath(heart, Paint()..color = const Color(0xffdc7b96));
    c.drawPath(buds, Paint()..color = const Color(0xffb6456a));
  }

  /// A clump of bamboo: jointed culms with a sunlit edge and drooping sprays
  /// of lance leaves. [haze] pales a clump standing further back.
  static void _shoreBamboo(Canvas c, Offset base, double h, int seed, {int culms = 8, double haze = 0, double tall = 1}) {
    Color tint(Color a) => haze > 0 ? _hazed(a, haze) : a;
    final body = Path(), rim = Path(), nodes = Path();
    final dark = Path(), mid = Path(), lit = Path();
    Path pick(double r) => r < .3 ? dark : (r < .72 ? mid : lit);
    for (var i = 0; i < culms; i++) {
      final k = i - (culms - 1) / 2;
      final r = seed + i * 13;
      final x0 = base.dx + k * h * .021 + (Sketch.hash(r) - .5) * h * .012;
      final height = h * (.15 + .08 * Sketch.hash(r + 1)) * tall * (1 - .18 * (k.abs() / culms * 2));
      final lean = k * h * .007 + (Sketch.hash(r + 2) - .5) * h * .05;
      final p0 = Offset(x0, base.dy), p2 = Offset(x0 + lean, base.dy - height);
      final p1 = Offset(x0 + lean * .3 + (Sketch.hash(r + 3) - .5) * h * .03, base.dy - height * .5);
      Offset at(double t) {
        final u = 1 - t;
        return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
      }

      Offset norm(double t) {
        final d = (p1 - p0) * (2 * (1 - t)) + (p2 - p1) * (2 * t);
        return Offset(-d.dy, d.dx) / d.distance;
      }

      final l = <Offset>[], rr = <Offset>[], inner = <Offset>[];
      for (var j = 0; j <= 10; j++) {
        final t = j / 10, w = h * (.0034 - .0014 * t), ctr = at(t), nv = norm(t);
        l.add(ctr - nv * w);
        rr.add(ctr + nv * w);
        inner.add(ctr + nv * w * .2);
      }
      body.addPolygon([...l, ...rr.reversed], true);
      rim.addPolygon([...rr, ...inner.reversed], true);
      for (var j = 0; j < 8; j++) {
        final t = .09 + j * .112 + Sketch.hash(r + 20 + j) * .025;
        final w = h * (.0034 - .0014 * t) * 1.35, ctr = at(t), nv = norm(t);
        nodes
          ..moveTo(ctr.dx - nv.dx * w, ctr.dy - nv.dy * w)
          ..lineTo(ctr.dx + nv.dx * w, ctr.dy + nv.dy * w);
        if (t > .5 && Sketch.hash(r + 40 + j) > .3) {
          final side = Sketch.hash(r + 60 + j) > .5 ? 1.0 : -1.0;
          final o = ctr + Offset(side * h * .012, -h * .008);
          for (var q = 0; q < 4; q++) {
            final ang = (side > 0 ? .5 : math.pi - .5) + (q - 1.5) * .55 * side;
            _shoreLeaf(pick(Sketch.hash(r + 100 + j * 4 + q)), o, ang, h * (.026 + .014 * Sketch.hash(r + 80 + j * 4 + q)), sag: .22);
          }
        }
      }
      for (var q = 0; q < 4; q++) {
        _shoreLeaf(pick(Sketch.hash(r + 220 + q)), p2, -math.pi / 2 + (q - 1.5) * .62, h * (.028 + .012 * Sketch.hash(r + 200 + q)), sag: .2);
      }
    }
    c.drawPath(body, Paint()..color = tint(const Color(0xff2e5548)));
    c.drawPath(rim, Paint()..color = tint(Sketch.mix(const Color(0xff88b08e), _shoreRim, .2)));
    c.drawPath(
      nodes,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, h * .0026)
        ..color = tint(const Color(0xff9dbe9a)),
    );
    c.drawPath(dark, Paint()..color = tint(const Color(0xff28493f)));
    c.drawPath(mid, Paint()..color = tint(const Color(0xff3f6f58)));
    c.drawPath(lit, Paint()..color = tint(Sketch.mix(const Color(0xff70a173), _shoreRim, .18)));
  }

  /// A small stone garden lantern: stepped foot, pillar, lamp box and hipped cap.
  static void _shoreLantern(Canvas c, Offset base, double s) {
    const stone = Color(0xff878c88), shade = Color(0xff596265);
    final light = Sketch.mix(const Color(0xffbfc0b3), _shoreRim, .3);
    Offset p(double x, double y) => Offset(base.dx + x * s, base.dy + y * s);
    Rect r(double x0, double y0, double x1, double y1) => Rect.fromPoints(p(x0, y0), p(x1, y1));
    final fill = Paint();
    void block(Rect rect, {double lit = .1}) {
      c.drawRect(rect, fill..color = stone);
      c.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.left + rect.width * .32, rect.bottom), fill..color = Sketch.fade(shade, .6));
      c.drawRect(Rect.fromLTRB(rect.right - rect.width * .16, rect.top, rect.right, rect.bottom), fill..color = Sketch.fade(light, .5));
      c.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + s * lit), fill..color = light);
    }

    block(r(-.62, -.14, .62, .45));
    block(r(-.44, -.3, .44, -.14), lit: .07);
    block(r(-.16, -.92, .16, -.3), lit: 0);
    block(r(-.24, -.64, .24, -.54), lit: .05);
    block(r(-.54, -1.0, .54, -.9), lit: .05);
    block(r(-.38, -1.5, .38, -1.0), lit: .06);
    c.drawRect(r(-.18, -1.38, .18, -1.1), fill..color = const Color(0xff2b2a2d));
    c.drawRect(r(-.1, -1.31, .1, -1.14), fill..color = const Color(0xff5b4a45));
    final cap = Path()
      ..moveTo(base.dx - s * .76, base.dy - s * 1.62)
      ..quadraticBezierTo(base.dx - s * .62, base.dy - s * 1.5, base.dx - s * .46, base.dy - s * 1.5)
      ..lineTo(base.dx + s * .46, base.dy - s * 1.5)
      ..quadraticBezierTo(base.dx + s * .62, base.dy - s * 1.5, base.dx + s * .76, base.dy - s * 1.62)
      ..quadraticBezierTo(base.dx + s * .42, base.dy - s * 1.68, base.dx + s * .14, base.dy - s * 1.94)
      ..lineTo(base.dx - s * .14, base.dy - s * 1.94)
      ..quadraticBezierTo(base.dx - s * .42, base.dy - s * 1.68, base.dx - s * .76, base.dy - s * 1.62)
      ..close();
    c.drawPath(cap, fill..color = const Color(0xff6b7371));
    _shoreEdge(c, cap, -s * .12, Sketch.fade(_shoreInk, .4));
    _shoreEdge(c, cap, s * .14, light);
    c.drawOval(Rect.fromCenter(center: p(-.1, -1.9), width: s * .5, height: s * .16), fill..color = const Color(0xff55805a));
    c.drawCircle(p(0, -2.05), s * .11, fill..color = stone);
    c.drawCircle(p(.03, -2.08), s * .05, fill..color = light);
  }

  /// A lens-shaped leaf or petal from [o], [len] long pointing at [ang]; [sag]
  /// lets the tip droop.
  static void _shoreLeaf(Path into, Offset o, double ang, double len, {double fat = .17, double sag = 0}) {
    final dir = Offset(math.cos(ang), math.sin(ang));
    final tip = o + dir * len + Offset(0, len * sag);
    final m = o + dir * len * .5 + Offset(0, len * sag * .3);
    final pp = Offset(-dir.dy, dir.dx) * len * fat;
    into
      ..moveTo(o.dx, o.dy)
      ..quadraticBezierTo(m.dx + pp.dx, m.dy + pp.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(m.dx - pp.dx * .6, m.dy - pp.dy * .6, o.dx, o.dy)
      ..close();
  }

  // Everything that lies on the bank is recorded once per viewport height.
  static final _shorePictures = <double, Picture>{};

  void _shoreOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h, span = period(Depth.near) * h;
    // While the bank hands over, its surface detail slides down with it.
    c.save();
    if (!f.reducedMotion) c.translate(0, h * .16 * (1 - presence));
    var picture = _shorePictures.remove(h);
    if (picture == null) {
      final recorder = PictureRecorder();
      _shoreGround(Canvas(recorder), h);
      picture = recorder.endRecording();
      if (_shorePictures.length > 6) _shorePictures.remove(_shorePictures.keys.first)!.dispose();
    }
    _shorePictures[h] = picture;
    if (presence >= .995) {
      c.drawPicture(picture);
    } else if (presence > .01) {
      // Only while a crossing hands the bank over.
      c.saveLayer(Rect.fromLTRB(-h * .5, h * .78, span + h * .5, h * 1.02), Paint()..color = Color.fromRGBO(0, 0, 0, presence));
      c.drawPicture(picture);
      c.restore();
    }
    final clock = f.clock;
    // Koi turn slow laps of the pond; a ripple widens beside a lily pad.
    final pond = _shorePondRect(h);
    final ink = Paint();
    for (var i = 0; i < 3; i++) {
      final a = clock * (.16 + .05 * i) * (i.isOdd ? -1 : 1) + i * 2.1;
      final at = Offset(pond.center.dx + math.cos(a) * pond.width * (.3 + .07 * i), pond.center.dy + math.sin(a) * pond.height * (.24 + .05 * i));
      final vel = Offset(-math.sin(a) * pond.width * (i.isOdd ? -1 : 1), math.cos(a) * pond.height * (i.isOdd ? -1 : 1));
      _shoreKoi(c, at, math.atan2(vel.dy, vel.dx), h * (.03 - .003 * i), math.sin(clock * 3.2 + i * 1.7), presence, i);
    }
    for (var i = 0; i < 2; i++) {
      final age = (clock * .22 + i * .5) % 1;
      final ctr = Offset(pond.center.dx + pond.width * (i == 0 ? -.2 : .18), pond.center.dy + pond.height * (i == 0 ? .05 : .2));
      c.drawOval(
        Rect.fromCenter(center: ctr, width: h * .05 * age + h * .006, height: h * .015 * age + h * .002),
        ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.6, h * .0018)
          ..color = Sketch.fade(const Color(0xfffff0e6), .5 * (1 - age) * presence),
      );
    }
    // Reed clumps sway a little in the evening air.
    final mid = Path(), lit = Path(), heads = Path();
    for (final (i, x) in const [.11, .33, .74, .97, 1.21, 1.63, 2.06, 2.31, 2.7, 3.0, 3.29].indexed) {
      final ox = x * h, oy = ridge(Depth.near, x, 0) * h + h * .008;
      for (var k = 0; k < 4; k++) {
        final tall = h * (.034 + .016 * Sketch.hash(i * 5 + k + 950)) * (k == 1 || k == 2 ? 1.25 : 1);
        final lean = (k - 1.5) * h * .011;
        final sway = math.sin(clock * 1.25 + i * 1.7 + k * .6) * h * .0048 * (.6 + .4 * k / 3);
        final tip = Offset(ox + lean * 1.4 + sway, oy - tall);
        final ctl = Offset(ox + lean * .9 + sway * .2, oy - tall * .55);
        final bw = h * .0021;
        (k.isOdd ? lit : mid)
          ..moveTo(ox + lean * .3 - bw, oy)
          ..quadraticBezierTo(ctl.dx - bw * .6, ctl.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(ctl.dx + bw * .8, ctl.dy, ox + lean * .3 + bw, oy)
          ..close();
        if (k == 1 && i.isEven) heads.addOval(Rect.fromCenter(center: tip + Offset(0, -h * .004), width: h * .005, height: h * .015));
      }
    }
    c.drawPath(mid, Paint()..color = Sketch.fade(const Color(0xff55805f), presence));
    c.drawPath(lit, Paint()..color = Sketch.fade(Sketch.mix(const Color(0xff8fb58a), _shoreRim, .2), presence));
    c.drawPath(heads, Paint()..color = Sketch.fade(const Color(0xff6b4b3e), presence));
    c.restore();
  }

  /// The lotus pond's outline, in period coordinates.
  Rect _shorePondRect(double h) {
    var top = 0.0;
    for (var i = -6; i <= 6; i++) {
      top = math.max(top, ridge(Depth.near, _shorePondX + i * .27 / 6, 0));
    }
    return Rect.fromCenter(center: Offset(_shorePondX * h, top * h + h * .014 + h * .026), width: h * .54, height: h * .052);
  }

  /// A small koi: cream body, a coral patch, fanned tail; [flick] swings the tail.
  static void _shoreKoi(Canvas c, Offset at, double ang, double len, double flick, double presence, int kind) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(ang);
    final fill = Paint();
    final body = Sketch.fade(const Color(0xfff1e0d2), .9 * presence);
    final coral = Sketch.fade(kind == 1 ? const Color(0xffcf6e58) : const Color(0xffd9805f), .92 * presence);
    final tail = Path()
      ..moveTo(-len * .42, 0)
      ..quadraticBezierTo(-len * .75, -len * (.25 + .1 * flick), -len * (.95 + .05 * flick), -len * (.22 + .3 * flick))
      ..quadraticBezierTo(-len * .72, len * .02 * flick, -len * (.95 - .04 * flick), len * (.26 + .22 * flick))
      ..quadraticBezierTo(-len * .7, len * .24, -len * .42, 0)
      ..close();
    c.drawPath(tail, fill..color = kind == 1 ? coral : body);
    c.drawOval(Rect.fromCenter(center: Offset(len * .02, 0), width: len, height: len * .34), fill..color = body);
    c.drawOval(Rect.fromCenter(center: Offset(len * .16, -len * .02), width: len * .42, height: len * .26), fill..color = coral);
    c.drawOval(Rect.fromCenter(center: Offset(-len * .2, len * .04), width: len * .26, height: len * .2), fill..color = kind == 2 ? coral : body);
    c.drawOval(Rect.fromCenter(center: Offset(len * .08, len * .2), width: len * .26, height: len * .1), fill..color = Sketch.fade(const Color(0xfff6ebe2), .7 * presence));
    c.restore();
  }

  /// A cattle egret-like heron standing at the water's edge.
  static void _shoreEgret(Canvas c, Offset at, double s) {
    final fill = Paint();
    final leg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, s * .03)
      ..color = const Color(0xff4c4444);
    c.drawLine(at + Offset(s * .04, 0), at + Offset(s * .06, -s * .36), leg);
    c.drawLine(at + Offset(-s * .06, 0), at + Offset(-s * .02, -s * .36), leg);
    final body = Path()
      ..moveTo(at.dx - s * .3, at.dy - s * .56)
      ..quadraticBezierTo(at.dx - s * .12, at.dy - s * .34, at.dx + s * .16, at.dy - s * .4)
      ..quadraticBezierTo(at.dx + s * .42, at.dy - s * .46, at.dx + s * .5, at.dy - s * .34)
      ..quadraticBezierTo(at.dx + s * .3, at.dy - s * .52, at.dx + s * .18, at.dy - s * .66)
      ..quadraticBezierTo(at.dx - s * .1, at.dy - s * .74, at.dx - s * .3, at.dy - s * .56)
      ..close();
    c.drawPath(body, fill..color = const Color(0xffebe0dc));
    _shoreEdge(c, body, -s * .12, const Color(0xffbfb3c6));
    _shoreEdge(c, body, s * .05, Sketch.mix(const Color(0xfffff6ee), _shoreRim, .4));
    c.drawPath(
      Path()
        ..moveTo(at.dx - s * .26, at.dy - s * .6)
        ..quadraticBezierTo(at.dx - s * .5, at.dy - s * .78, at.dx - s * .34, at.dy - s * 1.0)
        ..quadraticBezierTo(at.dx - s * .3, at.dy - s * 1.06, at.dx - s * .36, at.dy - s * 1.1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, s * .07)
        ..color = const Color(0xffebe0dc),
    );
    c.drawCircle(at + Offset(-s * .37, -s * 1.1), s * .055, fill..color = const Color(0xffebe0dc));
    c.drawPath(Sketch.poly([-.4, -1.13, -.62, -1.09, -.4, -1.08], at: at, s: s), fill..color = const Color(0xff9c8657));
  }

  /// A lotus pond ringed with stones: sunset water, pads, blossoms, and a
  /// line of stepping stones across the front.
  void _shorePondStatic(Canvas c, double h) {
    final rect = _shorePondRect(h);
    final rx = rect.width / 2, ry = rect.height / 2, ctr = rect.center;
    c.drawOval(rect.inflate(h * .006).shift(Offset(0, h * .004)), Paint()..color = Sketch.fade(_shoreInk, .4));
    c.drawOval(
      rect,
      Paint()
        ..shader = Gradient.linear(rect.topCenter, rect.bottomCenter, const [Color(0xffdcb8c4), Color(0xffa78fb0), Color(0xff536f7c)], const [0, .5, 1]),
    );
    // Sky and the far bank lie in the water: pale streaks and a dark lower edge.
    final streak = Path();
    for (var i = 0; i < 7; i++) {
      final y = ctr.dy - ry * .7 + ry * 1.3 * (i + .5) / 7;
      final half = rx * (.5 + .4 * Sketch.hash(i + 970)) * math.sqrt(1 - math.pow((y - ctr.dy) / ry, 2));
      final x = ctr.dx + (Sketch.hash(i + 980) - .5) * rx * .4;
      streak
        ..moveTo(x - half * .6, y)
        ..lineTo(x + half * .6, y);
    }
    c.drawPath(streak, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = math.max(.7, h * .0022)..color = const Color(0x59fff0e8));
    // Lotus pads, flattened by the low viewpoint, and their stems' blossoms.
    final padDark = Path(), padLit = Path(), notch = Path(), veins = Path();
    const pads = [
      (-.62, -.1, 1.0), (-.44, .34, .8), (-.3, -.38, .7), (-.08, .05, 1.15), (.12, -.42, .75),
      (.3, .3, .9), (.5, -.12, 1.05), (.68, .2, .7), (-.78, .3, .6), (.05, .55, .55),
    ];
    for (final (i, (u, v, k)) in pads.indexed) {
      final pc = Offset(ctr.dx + u * rx * .92, ctr.dy + v * ry * .78);
      final w = h * .046 * k, hh = w * .3;
      padDark.addOval(Rect.fromCenter(center: pc + Offset(0, hh * .12), width: w, height: hh));
      padLit.addOval(Rect.fromCenter(center: pc + Offset(w * .02, -hh * .06), width: w * .86, height: hh * .78));
      final a = Sketch.hash(i + 990) * math.pi * 2;
      notch
        ..moveTo(pc.dx, pc.dy)
        ..lineTo(pc.dx + math.cos(a - .2) * w * .55, pc.dy + math.sin(a - .2) * hh * .55)
        ..lineTo(pc.dx + math.cos(a + .2) * w * .55, pc.dy + math.sin(a + .2) * hh * .55)
        ..close();
      for (var q = 0; q < 4; q++) {
        final b = Sketch.hash(i * 7 + q + 1000) * math.pi * 2;
        veins
          ..moveTo(pc.dx, pc.dy)
          ..lineTo(pc.dx + math.cos(b) * w * .4, pc.dy - hh * .04 + math.sin(b) * hh * .38);
      }
    }
    c.drawPath(padDark, Paint()..color = const Color(0xff3c6853));
    c.drawPath(padLit, Paint()..color = Sketch.mix(const Color(0xff78ab73), _shoreRim, .08));
    c.drawPath(notch, Paint()..color = const Color(0xff9a86a8));
    c.drawPath(veins, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.5, h * .0012)..color = const Color(0x66d4eccd));
    // Blossoms on their stems, and a bud.
    final stem = Path(), petalA = Path(), petalB = Path(), heart = Path();
    for (final (u, v, hgt) in const [(-.44, -.05, 1.0), (.3, .06, 1.25), (.62, -.32, .85)]) {
      final base = Offset(ctr.dx + u * rx, ctr.dy + v * ry);
      final top = base + Offset(h * .006 * u, -h * .05 * hgt);
      stem
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx - h * .004, base.dy - h * .03 * hgt, top.dx, top.dy);
      for (var q = -2; q <= 2; q++) {
        _shoreLeaf(q.isOdd ? petalB : petalA, top, -math.pi / 2 + q * .42, h * (.024 - .003 * q.abs()), fat: .3);
      }
      heart.addOval(Rect.fromCenter(center: top + Offset(0, -h * .004), width: h * .008, height: h * .006));
    }
    c.drawPath(stem, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.7, h * .0018)..color = const Color(0xff4c7a5a));
    c.drawPath(petalA, Paint()..color = const Color(0xffee9db8));
    c.drawPath(petalB, Paint()..color = const Color(0xfffbd3df));
    c.drawPath(heart, Paint()..color = const Color(0xffe6c98a));
    // Rim stones in two tones, larger toward the viewer.
    final stonesA = Path(), stonesB = Path(), lit = Path();
    const n = 34;
    for (var i = 0; i < n; i++) {
      final a = (i + Sketch.hash(i + 1010) * .5) / n * math.pi * 2;
      final near = .55 + .45 * math.max(0, math.sin(a));
      final e = Offset(ctr.dx + math.cos(a) * rx * 1.02, ctr.dy + math.sin(a) * ry * 1.14);
      final w = h * (.017 + .012 * Sketch.hash(i + 1020)) * near, hh = w * .5;
      (i.isEven ? stonesA : stonesB).addOval(Rect.fromCenter(center: e, width: w, height: hh));
      lit.addOval(Rect.fromCenter(center: e + Offset(w * .05, -hh * .2), width: w * .8, height: hh * .5));
    }
    c.drawPath(stonesA, Paint()..color = const Color(0xff727b7a));
    c.drawPath(stonesB, Paint()..color = const Color(0xff8a918b));
    c.drawPath(lit, Paint()..color = Sketch.mix(const Color(0xffc3c4b8), _shoreRim, .3));
    // Stepping stones across the front of the pond.
    final sides = Path(), tops = Path(), tint = Path(), under = Path();
    for (var i = 0; i < 6; i++) {
      final u = -.72 + i * .29 + (Sketch.hash(i + 1030) - .5) * .05;
      final v = .5 + .06 * math.sin(i * 1.3);
      final sc = Offset(ctr.dx + u * rx, ctr.dy + v * ry);
      final w = h * (.036 + .012 * Sketch.hash(i + 1040)), hh = w * .42;
      under.addOval(Rect.fromCenter(center: sc + Offset(w * .04, hh * .55), width: w * 1.15, height: hh * .9));
      sides.addOval(Rect.fromCenter(center: sc + Offset(0, hh * .22), width: w, height: hh));
      tops.addOval(Rect.fromCenter(center: sc, width: w * .94, height: hh * .8));
      tint.addOval(Rect.fromCenter(center: sc + Offset(w * .08, -hh * .1), width: w * .6, height: hh * .4));
    }
    c.drawPath(under, Paint()..color = Sketch.fade(_shoreInk, .4));
    c.drawPath(sides, Paint()..color = const Color(0xff5d676b));
    c.drawPath(tops, Paint()..color = const Color(0xffa0a59f));
    c.drawPath(tint, Paint()..color = Sketch.mix(const Color(0xffd0cfc2), _shoreRim, .3));
    _shoreEgret(c, Offset(ctr.dx - rx * 1.07, ctr.dy + ry * .32), h * .062);
  }

  /// The bank's own surface, in front of the standing pieces: shading, mossy
  /// swales, pebbles, contact shadows, the stone path, the pond, fallen
  /// blossom and grass tufts breaking the bank line.
  void _shoreGround(Canvas c, double h) {
    final span = period(Depth.near) * h;
    double yr(double px) => ridge(Depth.near, px / h, 0) * h;
    final steps = (span / (h * .03)).round();

    // The continuous textures are clipped to exactly one period (no
    // anti-aliasing, so neighbouring copies meet without a seam).
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, span, h * 1.1), doAntiAlias: false);
    final shade = Path()..moveTo(0, yr(0));
    for (var i = 1; i <= steps; i++) {
      shade.lineTo(span * i / steps, yr(span * i / steps));
    }
    shade
      ..lineTo(span, h + 2)
      ..lineTo(0, h + 2)
      ..close();
    c.drawPath(
      shade,
      Paint()..shader = Gradient.linear(Offset(0, h * .89), Offset(0, h), [Sketch.fade(_shoreInk, 0), Sketch.fade(_shoreInk, .34)]),
    );
    // Terraced swales, engraved into the bank.
    for (var k = 0; k < 3; k++) {
      final line = Path();
      for (var i = 0; i <= steps; i++) {
        final x = span * i / steps;
        final y = yr(x) + h * (.02 + .019 * k) + math.sin(x / span * math.pi * 2 * (3 + k) + k * 2.1) * h * .0045;
        i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
      }
      c.drawPath(line, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = h * .0055..color = Sketch.fade(_shoreInk, .17));
      c.drawPath(line.shift(Offset(0, -h * .0045)), Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = h * .003..color = Sketch.fade(const Color(0xff97bfa2), .17));
    }
    c.restore();
    // Moss cushions, pebbles and the odd tiny wildflower.
    final mossDark = Path(), mossLit = Path(), pebA = Path(), pebB = Path(), wild = Path();
    for (var i = 0; i < 26; i++) {
      final x = h * .08 + (span - h * .16) * (i + Sketch.hash(i + 900) * .8) / 26;
      final y = yr(x) + h * (.014 + .05 * Sketch.hash(i + 920));
      final w = h * (.025 + .04 * Sketch.hash(i + 940));
      mossDark.addOval(Rect.fromCenter(center: Offset(x, y + h * .002), width: w, height: w * .26));
      mossLit.addOval(Rect.fromCenter(center: Offset(x - w * .05, y - h * .001), width: w * .78, height: w * .17));
    }
    for (var i = 0; i < 56; i++) {
      final x = h * .08 + (span - h * .16) * (i + Sketch.hash(i + 1100) * .8) / 56;
      final y = yr(x) + h * (.014 + .062 * Sketch.hash(i + 1120));
      final w = h * (.005 + .006 * Sketch.hash(i + 1140));
      (i.isEven ? pebA : pebB).addOval(Rect.fromCenter(center: Offset(x, y), width: w, height: w * .55));
      if (i % 5 == 0) wild.addOval(Rect.fromCircle(center: Offset(x + h * .02, y - h * .006), radius: h * .0028));
    }
    c.drawPath(mossDark, Paint()..color = Sketch.fade(const Color(0xff2b4a44), .38));
    c.drawPath(mossLit, Paint()..color = Sketch.fade(const Color(0xff86b581), .2));
    c.drawPath(pebA, Paint()..color = Sketch.fade(const Color(0xff7d8b86), .9));
    c.drawPath(pebB, Paint()..color = Sketch.fade(const Color(0xffa3ada2), .8));
    c.drawPath(wild, Paint()..color = Sketch.fade(const Color(0xfff3e2e2), .9));

    // Contact and long cast shadows (the sun is behind, so they fall toward us).
    for (final (x, half, a) in const [
      (_shorePineX, .1, 1.0), (_shoreScholarX, .07, 1.0), (_shoreBoulderX, .05, .8), (_shorePineX + .3, .035, .7),
      (_shoreBambooX, .13, .9), (_shoreBambooX + .55, .1, .45), (_shorePavilionX, .18, 1.0), (_shoreLanternX, .03, .8),
      (_shorePlumX, .09, .9), (_shoreCloseBambooX, .11, .8),
    ]) {
      final px = x * h, py = yr(px) + h * .018;
      c.drawOval(Rect.fromCenter(center: Offset(px + h * .012, py + h * .022), width: half * 2.5 * h, height: h * .024), Paint()..color = Sketch.fade(_shoreInk, .16 * a));
      c.drawOval(Rect.fromCenter(center: Offset(px, py), width: half * 1.9 * h, height: h * .016), Paint()..color = Sketch.fade(_shoreInk, .28 * a));
    }
    // A flagged stone path climbs from the pavilion steps toward the viewer.
    final slabSide = Path(), slabTop = Path(), slabLit = Path();
    for (var i = 0; i < 4; i++) {
      final px = _shorePavilionX * h + (i.isEven ? -1 : 1) * h * .01;
      final py = yr(px) + h * (.018 + .017 * i);
      final w = h * (.05 + .014 * i), hh = w * .3;
      slabSide.addOval(Rect.fromCenter(center: Offset(px, py + hh * .22), width: w, height: hh));
      slabTop.addOval(Rect.fromCenter(center: Offset(px, py), width: w * .94, height: hh * .82));
      slabLit.addOval(Rect.fromCenter(center: Offset(px + w * .06, py - hh * .12), width: w * .6, height: hh * .34));
    }
    c.drawPath(slabSide, Paint()..color = const Color(0xff59646a));
    c.drawPath(slabTop, Paint()..color = const Color(0xff9ba19c));
    c.drawPath(slabLit, Paint()..color = Sketch.mix(const Color(0xffd0d0c2), _shoreRim, .3));

    _shorePondStatic(c, h);

    // Fallen plum blossom under the tree and drifting on the bank.
    final fallen = Path(), fallenPale = Path();
    for (var i = 0; i < 24; i++) {
      final x = (_shorePlumX + (Sketch.hash(i + 1200) - .5) * .7) * h;
      final y = yr(x) + h * (.014 + .05 * Sketch.hash(i + 1220));
      _shoreLeaf(i.isEven ? fallen : fallenPale, Offset(x, y), Sketch.hash(i + 1240) * math.pi, h * (.006 + .003 * Sketch.hash(i + 1260)), fat: .38);
    }
    c.drawPath(fallen, Paint()..color = const Color(0xfff2aebf));
    c.drawPath(fallenPale, Paint()..color = const Color(0xfff8dde5));

    // Fern clumps at the feet of the set pieces: arching fronds that droop at the tips.
    final fernDark = Path(), fernMid = Path(), fernLit = Path();
    for (final (i, x) in const [.3, .62, .93, 1.12, 1.36, 1.7, 2.3, 2.68, 3.0, 3.27].indexed) {
      final o = Offset(x * h, yr(x * h) + h * (.012 + .008 * Sketch.hash(i + 1500)));
      for (var k = 0; k < 7; k++) {
        final a = -math.pi / 2 + (k - 3) * .38 + (Sketch.hash(i * 9 + k + 1520) - .5) * .2;
        final len = h * (.028 + .016 * Sketch.hash(i * 7 + k + 1540)) * (1 - .18 * (k - 3).abs() / 3);
        _shoreLeaf(k == 3 ? fernLit : (k.isEven ? fernMid : (k < 3 ? fernDark : fernLit)), o, a, len, fat: .2, sag: .32);
      }
    }
    c.drawPath(fernDark, Paint()..color = const Color(0xff2f5346));
    c.drawPath(fernMid, Paint()..color = const Color(0xff4a7c5a));
    c.drawPath(fernLit, Paint()..color = Sketch.mix(const Color(0xff7bae76), _shoreRim, .2));

    // Grass tufts along the bank line, three shades, lit on the sunward side.
    final dark = Path(), mid = Path(), lit = Path();
    const tufts = 68;
    for (var i = 0; i < tufts; i++) {
      final x = span * (i + Sketch.hash(i + 1300) * .7) / tufts;
      final base = Offset(x, yr(x) + h * (.004 + .012 * Sketch.hash(i + 1320)));
      final count = 4 + (Sketch.hash(i + 1340) * 4).floor();
      for (var k = 0; k < count; k++) {
        final r = Sketch.hash(i * 11 + k + 1360);
        final spread = (k / (count - 1) - .5) * 1.3 + (r - .5) * .3;
        final len = h * (.011 + .03 * Sketch.hash(i * 13 + k + 1380)) * (1 - .45 * spread.abs());
        final bw = h * .0017;
        final tip = base + Offset(math.sin(spread) * len * .55 + h * .004 * (r - .3), -math.cos(spread) * len);
        final ctl = base + Offset(math.sin(spread) * len * .16, -len * .55);
        (spread > .25 ? lit : (k.isEven ? mid : dark))
          ..moveTo(base.dx - bw, base.dy)
          ..quadraticBezierTo(ctl.dx - bw * .5, ctl.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(ctl.dx + bw * .7, ctl.dy, base.dx + bw, base.dy)
          ..close();
      }
    }
    c.drawPath(dark, Paint()..color = const Color(0xff2f5147));
    c.drawPath(mid, Paint()..color = const Color(0xff4f7b5e));
    c.drawPath(lit, Paint()..color = Sketch.mix(const Color(0xff86b381), _shoreRim, .18));
  }

  // ---------------------------------------------------------------------------
  // The Li River: far bank, water surface, rafts.

  /// Bamboo groves on the far bank: (x, height, half-width, seed), in
  /// viewport heights along the low band's period.
  static const _riverGroves = <(double, double, double, int)>[
    (.3, .118, .16, 1),
    (.63, .07, .1, 2),
    (1.27, .135, .19, 3),
    (1.86, .085, .12, 4),
    (2.36, .124, .17, 5),
    (2.71, .062, .085, 6),
  ];

  static const _riverLight = Color(0xfffff0e6);
  static const _riverDeep = Color(0xff6a6f9e);
  static const _riverTeal = Color(0xff3a6670);
  static final _riverStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _riverFill = Paint();

  /// Vegetation fades toward the lavender of the mid slopes behind it.
  static Color _riverHaze(Color c, double t) => Sketch.mix(c, const Color(0xffb9b0c9), t);

  /// A tapered ripple stroke: a thin lens, [len] long and [th] thick.
  static void _riverLens(Path p, double x, double y, double len, double th) {
    p
      ..moveTo(x - len / 2, y)
      ..quadraticBezierTo(x, y - th, x + len / 2, y)
      ..quadraticBezierTo(x, y + th, x - len / 2, y);
  }

  /// Position and size of the i-th bush of the far-bank scrub line.
  static (double, double) _riverBush(int i, double span, double h) => (
    span * (i + .15 + .7 * Sketch.hash(i + 900)) / 46,
    h * (.011 + .015 * Sketch.hash(i + 950)),
  );

  /// The far bank, drawn behind the water: bamboo groves with their feet
  /// behind the waterline, a line of scrub, a stilt hut and reed clumps.
  void _riverBank(Canvas c, double h) {
    final span = period(Depth.low) * h;
    double bank(double x) => ridge(Depth.low, x / h, 0) * h;
    // A paler second rank of bamboo stands behind each grove.
    for (final (gx, gh, gw, seed) in _riverGroves) {
      final x = (gx + (seed.isEven ? -1 : 1) * gw * .5) * h;
      _riverGrove(c, Offset(x, bank(x) + h * .014), gh * h * .8, gw * h * .82, seed + 30, .5);
    }
    final dark = Paint()..color = _riverHaze(const Color(0xff2f5748), .3);
    final lit = Paint()..color = Sketch.fade(_riverHaze(const Color(0xffa3c48a), .3), .75);
    final tone = [
      Paint()..color = _riverHaze(const Color(0xff4b7f63), .3),
      Paint()..color = _riverHaze(const Color(0xff5a7d55), .3),
      Paint()..color = _riverHaze(const Color(0xff3d6c5e), .3),
    ];
    // Broadleaf trees stand among the bamboo.
    final treeDark = Paint()..color = _riverHaze(const Color(0xff33604f), .4);
    final treeTone = Paint()..color = _riverHaze(const Color(0xff4f8768), .4);
    final treeLit = Paint()..color = Sketch.fade(_riverHaze(const Color(0xffa9c88c), .38), .5);
    for (final (fx, fs) in const [(.02, .05), (.47, .06), (.8, .045), (1.7, .06), (2.12, .052), (2.55, .048)]) {
      _riverTree(c, Offset(fx * h, bank(fx * h) + h * .01), fs * h, (fx * 40).round(), treeDark, treeTone, treeLit);
    }
    for (var i = 0; i < 46; i++) {
      final (x, s) = _riverBush(i, span, h);
      final y = bank(x) + h * .008;
      final r = Sketch.hash(i + 990);
      for (var k = 0; k < 4; k++) {
        final ox = (k - 1.5) * s * .66;
        final oy = s * (.3 + .32 * math.sin((k + r * 3) * 1.9).abs());
        c.drawCircle(Offset(x + ox, y - oy), s * (.58 + .16 * Sketch.hash(i * 4 + k + 1000)), dark);
      }
      c.drawOval(Rect.fromCenter(center: Offset(x, y - s * .3), width: s * 3.4, height: s * .9), dark);
      final t = tone[i % 3];
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(x + (k - 1) * s * .7, y - s * (.78 + .22 * Sketch.hash(i * 3 + k + 1100))), s * (.42 + .1 * Sketch.hash(i * 3 + k + 1200)), t);
      }
      c.drawCircle(Offset(x - s * .1, y - s * 1.22), s * .17, lit);
      c.drawCircle(Offset(x + s * .5, y - s * 1.08), s * .14, lit);
    }
    _riverHut(c, Offset(h * .97, bank(h * .97) + h * .008), h * .05);
    for (final (fx, fs, seed) in const [
      (.05, .05, 11), (.49, .04, 12), (.83, .045, 13), (1.12, .05, 14), //
      (1.6, .055, 15), (2.06, .045, 16), (2.55, .05, 17), (2.9, .04, 18),
    ]) {
      _riverReeds(c, Offset(fx * h, bank(fx * h) + h * .01), fs * h, seed, .22);
    }
  }

  static final _riverGrovePics = <double, List<Picture>>{};

  /// Each front grove recorded once, base at the origin, so it can sway.
  static List<Picture> _riverGrovePictures(double h) {
    final hit = _riverGrovePics[h];
    if (hit != null) return hit;
    if (_riverGrovePics.length > 3) {
      for (final p in _riverGrovePics.remove(_riverGrovePics.keys.first)!) {
        p.dispose();
      }
    }
    final out = <Picture>[];
    for (final (_, gh, gw, seed) in _riverGroves) {
      final recorder = PictureRecorder();
      _riverGrove(Canvas(recorder), Offset.zero, gh * h, gw * h, seed, .16 + .1 * Sketch.hash(seed + 5));
      out.add(recorder.endRecording());
    }
    return _riverGrovePics[h] = out;
  }

  /// The front groves of bamboo, swaying a little in the evening wind.
  void _riverLive(Canvas c, SceneFrame f) {
    final h = f.h, t = f.clock;
    final pictures = _riverGrovePictures(h);
    for (var i = 0; i < _riverGroves.length; i++) {
      final (gx, _, _, seed) = _riverGroves[i];
      final sway = (.018 * math.sin(t * .9 + seed * 1.7) + .008 * math.sin(t * 2.1 + seed * 3.1)) * (.75 + .25 * math.sin(t * .27 + seed));
      c.save();
      c.translate(gx * h, ridge(Depth.low, gx, 0) * h + h * .012);
      c.skew(sway, 0);
      c.drawPicture(pictures[i]);
      c.restore();
    }
  }

  /// A rounded broadleaf tree at the water's edge: shade, body and a lit crown.
  static void _riverTree(Canvas c, Offset base, double s, int seed, Paint dark, Paint tone, Paint lit) {
    double r(int k) => (Sketch.hash(seed * 53 + k) - .5) * .1;
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .05, base.dy - s * .6, base.dx + s * .05, base.dy + s * .1),
      Paint()..color = _riverHaze(const Color(0xff4c3d36), .4),
    );
    final lobes = [
      (-.34 + r(1), -.86 + r(2), .34),
      (.04 + r(3), -1.1 + r(4), .38),
      (.38 + r(5), -.86 + r(6), .32),
      (-.12 + r(7), -.7 + r(8), .3),
      (.22 + r(9), -.66 + r(10), .28),
    ];
    for (final (x, y, rad) in lobes) {
      c.drawCircle(base + Offset(x * s, y * s), rad * s, dark);
    }
    for (final (x, y, rad) in lobes) {
      c.drawCircle(base + Offset(x * s + s * .07, y * s - s * .08), rad * s * .82, tone);
    }
    for (final (x, y, rad) in lobes.take(3)) {
      c.drawCircle(base + Offset(x * s + s * .13, y * s - s * .15), rad * s * .4, lit);
    }
  }

  /// A bamboo grove: arching culms whose tips carry drooping plumes of leaves.
  static void _riverGrove(Canvas c, Offset base, double gh, double gw, int seed, double haze) {
    final dark = _riverHaze(const Color(0xff2f5a4c), haze);
    final mid = _riverHaze(const Color(0xff4f8566), haze);
    final lit = Sketch.mix(_riverHaze(const Color(0xff9dbf83), haze), const Color(0xffffd6a4), .18);
    double r(int k) => Sketch.hash(seed * 97 + k);
    Sketch.mist(c, Rect.fromCenter(center: base + Offset(0, -gh * .6), width: gw * 2.1, height: gh * 1.0), dark, .3);
    final n = 9 + (gw / gh * 4).round();
    final culms = Path();
    final plumes = <(Offset, double, double)>[];
    for (var i = 0; i < n; i++) {
      final u = (i + .5) / n * 2 - 1;
      final x0 = base.dx + u * gw * .42 + (r(i) - .5) * gw * .08;
      final top = gh * (.72 + .28 * (1 - u.abs()) * (.6 + .4 * r(i + 20)));
      final lean = u * gw * (.42 + .3 * r(i + 40)) + (r(i + 80) - .5) * gw * .1;
      final p0 = Offset(x0, base.dy);
      final p1 = Offset(x0 + lean * .04, base.dy - top * .75);
      final p2 = Offset(x0 + lean * .5, base.dy - top * 1.06);
      final p3 = Offset(x0 + lean, base.dy - top * .86);
      culms
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
      for (final t in const [1.0, .9, .78, .66]) {
        final m = 1 - t;
        plumes.add((
          Offset(
            m * m * m * p0.dx + 3 * m * m * t * p1.dx + 3 * m * t * t * p2.dx + t * t * t * p3.dx,
            m * m * m * p0.dy + 3 * m * m * t * p1.dy + 3 * m * t * t * p2.dy + t * t * t * p3.dy,
          ),
          u,
          t,
        ));
      }
    }
    for (var j = 0; j < 5; j++) {
      c.drawOval(
        Rect.fromCenter(center: Offset(base.dx + (j / 4 - .5) * gw * .9, base.dy - gh * .04), width: gw * .5, height: gh * .18),
        Paint()..color = dark,
      );
    }
    c.drawPath(
      culms,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, gh * .017)
        ..color = _riverHaze(const Color(0xff6f9a6a), haze),
    );
    final bd = Path(), bm = Path(), bl = Path();
    void blade(Path p, Offset at, double a, double len, double wid) {
      final dx = math.cos(a), dy = math.sin(a);
      final tip = at + Offset(dx * len, dy * len + len * .14);
      final m = at + Offset(dx * len * .5, dy * len * .5);
      p
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo(m.dx - dy * wid, m.dy + dx * wid, tip.dx, tip.dy)
        ..quadraticBezierTo(m.dx + dy * wid, m.dy - dx * wid, at.dx, at.dy);
    }

    for (var i = 0; i < plumes.length; i++) {
      final (q, u, t) = plumes[i];
      final side = u >= 0 ? 1.0 : -1.0;
      const m = 6;
      for (var j = 0; j < m; j++) {
        final spread = (j - (m - 1) / 2) * .5;
        final a = math.pi / 2 - side * (.3 + .5 * u.abs()) + spread + (r(i * 8 + j + 60) - .5) * .3;
        final len = gh * .15 * (.75 + .5 * r(i * 8 + j + 300)) * (.85 + .15 * t);
        blade(bd, q, a, len, gh * .024);
        if (t >= .78) blade(bm, q + Offset(0, -gh * .022), a, len * .84, gh * .02);
        if (t >= .9 && r(i * 8 + j + 500) > .35) blade(bl, q + Offset(side * gh * .012, -gh * .045), a, len * .6, gh * .017);
      }
    }
    c.drawPath(bd, Paint()..color = dark);
    c.drawPath(bm, Paint()..color = mid);
    c.drawPath(bl, Paint()..color = lit);
  }

  /// A clump of reeds with pale plumes.
  static void _riverReeds(Canvas c, Offset base, double s, int seed, double haze) {
    final blades = Path(), hi = Path(), plumes = Path();
    for (var i = 0; i < 8; i++) {
      final u = (i - 3.5) / 3.5;
      final r1 = Sketch.hash(seed * 31 + i), r2 = Sketch.hash(seed * 31 + i + 9);
      final x0 = base.dx + u * s * .12;
      final tip = Offset(base.dx + u * s * .5 + (r1 - .5) * s * .15, base.dy - s * (.72 + .28 * r2));
      final ctrl = Offset(x0 + u * s * .06, base.dy - s * .5);
      (i.isEven ? blades : hi)
        ..moveTo(x0, base.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
      if (i % 3 == 0) {
        final d = tip - ctrl;
        final e = tip + d / d.distance * s * .22;
        final m = Offset.lerp(tip, e, .5)!;
        final nx = -d.dy / d.distance * s * .04, ny = d.dx / d.distance * s * .04;
        plumes
          ..moveTo(tip.dx, tip.dy)
          ..quadraticBezierTo(m.dx + nx, m.dy + ny, e.dx, e.dy)
          ..quadraticBezierTo(m.dx - nx, m.dy - ny, tip.dx, tip.dy);
      }
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, s * .04);
    c.drawPath(blades, stroke..color = _riverHaze(const Color(0xff5d7f58), haze));
    c.drawPath(hi, stroke..color = _riverHaze(const Color(0xffa4bd86), haze));
    c.drawPath(plumes, Paint()..color = _riverHaze(const Color(0xffeed6c8), haze));
  }

  /// A small stilt hut among the bamboo, a warm window barely lit.
  static void _riverHut(Canvas c, Offset base, double s) {
    final wall = Paint()..color = _hazed(const Color(0xff8a6c58), .28);
    final shade = Paint()..color = _hazed(const Color(0xff6f5748), .3);
    final thatch = Paint()..color = _hazed(const Color(0xffb99c68), .25);
    final thatchShade = Paint()..color = _hazed(const Color(0xff8f7549), .28);
    final post = Paint()
      ..color = _hazed(const Color(0xff5b4a3f), .3)
      ..strokeWidth = math.max(.8, s * .06);
    for (final dx in const [-.55, -.2, .2, .55]) {
      c.drawLine(base + Offset(dx * s, -s * .28), base + Offset(dx * s, s * .12), post);
    }
    c.drawRect(Rect.fromLTRB(base.dx - s * .7, base.dy - s * .34, base.dx + s * .7, base.dy - s * .27), shade);
    c.drawRect(Rect.fromLTRB(base.dx - s * .45, base.dy - s * .8, base.dx + s * .45, base.dy - s * .34), wall);
    c.drawRect(Rect.fromLTRB(base.dx + s * .1, base.dy - s * .8, base.dx + s * .45, base.dy - s * .34), shade);
    c.drawPath(Sketch.poly([-.68, -.74, 0, -1.34, .68, -.74], at: base, s: s), thatch);
    c.drawPath(Sketch.poly([0, -1.34, .68, -.74, .06, -.74], at: base, s: s), thatchShade);
    c.drawRect(Rect.fromLTRB(base.dx - s * .3, base.dy - s * .66, base.dx - s * .12, base.dy - s * .36), shade);
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .06, base.dy - s * .62, base.dx + s * .04, base.dy - s * .5),
      Paint()..color = _hazed(const Color(0xfff0b26a), .3),
    );
  }

  static final _riverCache = <double, List<Path>>{};
  static final _riverShaders = <double, Shader>{};

  /// Ripple strokes (0-2 light, 3-5 dark, far to near), grove reflections
  /// (6-8, near to far), scrub reflections (9) and reflected karst towers (10-12,
  /// wide to narrow, stacked so their edges feather), built once per height.
  List<Path> _riverPaths(double h) {
    final hit = _riverCache[h];
    if (hit != null) return hit;
    if (_riverCache.length > 6) _riverCache.remove(_riverCache.keys.first);
    final span = period(Depth.low) * h;
    double bank(double x) => ridge(Depth.low, x / h, 0) * h;
    final paths = [for (var i = 0; i < 13; i++) Path()];
    // Ripples come in small families of parallel strokes.
    for (var i = 0; i < 44; i++) {
      final t = math.pow(Sketch.hash(i * 9 + 11), 1.4).toDouble();
      final x = span * Sketch.hash(i * 9 + 12);
      final y0 = bank(x) + h * .014;
      final y = y0 + (h * .878 - y0) * t;
      final g = t < .34 ? 0 : (t < .67 ? 1 : 2);
      final dark = Sketch.hash(i * 9 + 14) < .4;
      final n = 2 + (Sketch.hash(i * 9 + 15) * 2.6).floor();
      for (var k = 0; k < n; k++) {
        final len = h * (.018 + .085 * t) * (.55 + .75 * Sketch.hash(i * 9 + 20 + k));
        final dx = (Sketch.hash(i * 9 + 30 + k) - .5) * len * .8;
        _riverLens(paths[g + (dark ? 3 : 0)], x + dx, y + k * h * (.006 + .008 * t), len, h * (.0014 + .0018 * t));
      }
    }
    for (final (gx, _, gw, seed) in _riverGroves) {
      final cx = gx * h;
      for (var k = 0; k < 8; k++) {
        final t = (k + .5) / 8;
        final y = bank(cx) + h * (.014 + k * .0068);
        final half = gw * h * (.3 + .7 * math.min(1.0, t * 1.5)) * (.9 + .2 * Sketch.hash(seed * 13 + k));
        final p = paths[k < 3 ? 6 : (k < 6 ? 7 : 8)];
        final jitter = (Sketch.hash(seed * 17 + k) - .5) * h * .02;
        for (var j = 0; j < 3; j++) {
          final a = cx + jitter - half + half * 2 * (j / 3 + .04 * Sketch.hash(seed * 7 + k * 3 + j));
          final b = cx + jitter - half + half * 2 * ((j + 1) / 3 - .07 * Sketch.hash(seed * 5 + k * 3 + j));
          _riverLens(p, (a + b) / 2, y, b - a, h * .0026);
        }
      }
    }
    for (var i = 0; i < 46; i++) {
      final (x, s) = _riverBush(i, span, h);
      _riverLens(paths[9], x, bank(x) + h * .013, s * 3.2, h * .003);
    }
    // Soft karst towers hanging from the bank in the water, rounded tips down.
    for (final (fx, fw, fd) in const [
      (.15, .06, .11), (.55, .08, .1), (1.0, .05, .09), (1.45, .09, .12), //
      (1.95, .06, .1), (2.4, .08, .11), (2.8, .06, .09),
    ]) {
      final x = fx * h, hw = fw * h, y = bank(x) + h * .006, d = fd * h;
      for (var l = 0; l < 3; l++) {
        final w = hw * const [1.0, .72, .48][l], dd = d * const [1.0, .9, .78][l];
        paths[10 + l]
          ..moveTo(x - w, y)
          ..cubicTo(x - w * .95, y + dd * .5, x - w * .55, y + dd, x, y + dd)
          ..cubicTo(x + w * .55, y + dd, x + w * .95, y + dd * .5, x + w, y)
          ..close();
      }
    }
    return _riverCache[h] = paths;
  }

  static final _riverPics = <double, List<Picture>>{};
  static final _riverLayer = Paint();

  /// Static art recorded once per height: 0 the boulders and egrets, 1-2 the
  /// distant rafts and 3 the fisherman's raft (the last three around their origin).
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
      record((c) {
        for (final (fx, fy, fs) in const [(.52, .824, .026), (1.62, .818, .018), (2.16, .83, .032), (2.92, .815, .014)]) {
          _riverRock(c, Offset(fx * h, fy * h), fs * h, 1);
        }
        _riverEgret(c, Offset(h * .52 + h * .006, h * .824 - h * .026 * .95), h * .022, 1, 1);
        _riverEgret(c, Offset(h * 2.16 - h * .008, h * .83 - h * .032 * .95), h * .028, -1, 1);
      }),
      record((c) => _riverFarRaft(c, Offset.zero, h * .034, 1)),
      record((c) => _riverFarRaft(c, Offset.zero, h * .024, 1)),
      record((c) => _raft(c, Offset.zero, h * .092)),
    ];
  }

  /// Draws a recorded picture, faded by [a] (a layer only while a crossing fades it).
  static void _riverPicture(Canvas c, Picture p, Rect bounds, double a) {
    if (a >= .995) {
      c.drawPicture(p);
      return;
    }
    c.saveLayer(bounds, _riverLayer..color = Color.fromRGBO(0, 0, 0, a));
    c.drawPicture(p);
    c.restore();
  }

  /// Everything on the water: ripples, reflected groves, mist, the sun's
  /// path, rocks and rafts.
  void _riverWater(Canvas c, SceneFrame f, double a) {
    final h = f.h, span = period(Depth.low) * h, clock = f.clock;
    final paths = _riverPaths(h);
    final fill = _riverFill;
    // Dusky reflection of the shore below, mist lying along the far bank above.
    final top = h * .742, bottom = h * .93;
    const fog = Color(0xfff6dcd6);
    c.drawRect(
      Rect.fromLTRB(0, top, span, bottom),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          [
            Sketch.fade(fog, 0),
            Sketch.fade(fog, .4 * a),
            Sketch.fade(fog, .14 * a),
            Sketch.fade(fog, 0),
            Sketch.fade(_riverTeal, 0),
            Sketch.fade(_riverTeal, .4 * a),
          ],
          const [0, .19, .38, .5, .52, 1],
        ),
    );
    final fade = _riverShaders[h] ??= Gradient.linear(
      Offset(0, h * .772),
      Offset(0, h * .9),
      [Sketch.fade(const Color(0xff7d7ba8), .16), Sketch.fade(const Color(0xff7d7ba8), .02)],
    );
    fill
      ..shader = fade
      ..color = Sketch.fade(const Color(0xffffffff), a);
    for (var i = 10; i < 13; i++) {
      c.drawPath(paths[i], fill);
    }
    fill.shader = null;
    fill.color = Sketch.fade(_riverTeal, .3 * a);
    c.drawPath(paths[9], fill);
    for (var i = 0; i < 3; i++) {
      fill.color = Sketch.fade(_riverTeal, (.34 - i * .09) * a);
      c.drawPath(paths[6 + i], fill);
    }
    c.save();
    var shift = 0.0;
    for (var i = 0; i < 6; i++) {
      final near = i % 3;
      final shimmer = .8 + .2 * math.sin(clock * .8 + i * 1.7);
      fill.color = i < 3
          ? Sketch.fade(_riverLight, (.34 + .1 * near) * shimmer * a)
          : Sketch.fade(_riverDeep, (.15 + .04 * near) * a);
      final to = math.sin(clock * .5 + i * 2.1) * h * .004;
      c.translate(to - shift, 0);
      shift = to;
      c.drawPath(paths[i], fill);
    }
    c.restore();
    // The sun's path: a warm glow and twinkling dashes; the sun's screen
    // position, in this copy's own coordinates.
    final scroll = f.reducedMotion ? 0.0 : f.distance * Depth.low.parallax * h;
    final sx = (f.w * light.at.dx + scroll) % span;
    Sketch.mist(c, Rect.fromCenter(center: Offset(sx, h * .845), width: h * .36, height: h * .17), const Color(0xffff9c7a), .36 * a);
    final glints = [for (var i = 0; i < 6; i++) Path()];
    for (var i = 0; i < 18; i++) {
      final t = i / 17;
      final y = h * (.806 + .092 * math.pow(t, 1.1));
      final len = h * (.028 + .1 * t) * (.55 + .45 * Sketch.hash(i + 40));
      final x = sx + (Sketch.hash(i + 60) * 2 - 1) * h * (.02 + .055 * t);
      _riverLens(glints[i % 3 + ((i ~/ 3) % 2) * 3], x, y, len, h * (.0026 + .0026 * t));
    }
    for (var g = 0; g < 6; g++) {
      final on = .5 + .5 * math.sin(clock * (1.0 + .35 * g) + g * 1.9);
      fill.color = Sketch.fade(g < 3 ? const Color(0xffffb08a) : const Color(0xffffeedd), (.28 + .55 * on) * a);
      c.drawPath(glints[g], fill);
    }
    // Drifting mist lies on the water.
    for (var i = 0; i < 2; i++) {
      final x = (span * (i + .35) / 2 + clock * h * (.012 + .006 * i)) % span;
      Sketch.mist(c, Rect.fromCenter(center: Offset(x, h * (.803 + .012 * i)), width: h * (.55 + .15 * i), height: h * .04), fog, .32 * a);
    }
    // Fish rise now and then: rings spread and fade.
    for (var i = 0; i < 3; i++) {
      final cycle = 6.5 + i * 2.3;
      final ph = ((clock + i * 3.1) % cycle) / cycle;
      if (ph > .5) continue;
      final at = Offset(h * (.35 + i * 1.03), h * (.836 + .012 * i));
      for (var k = 0; k < 2; k++) {
        final t = ph / .5 - k * .28;
        if (t <= 0) continue;
        _riverStroke
          ..strokeWidth = math.max(.7, h * .0018)
          ..color = Sketch.fade(_riverLight, .6 * (1 - t) * a);
        c.drawOval(Rect.fromCenter(center: at, width: h * (.008 + .05 * t), height: h * (.0025 + .014 * t)), _riverStroke);
      }
    }
    // Boulders and egrets, two distant rafts and the fisherman's raft.
    final pics = _riverPictures(h);
    _riverPicture(c, pics[0], Rect.fromLTRB(-h * .1, h * .74, span + h * .1, h * .9), a);
    for (final (i, x0, v, y, sz) in [(1, 2.05, .006, .812, .034), (2, 1.5, .004, .806, .024)]) {
      c.save();
      c.translate((h * x0 - clock * h * v) % span, h * y);
      _riverPicture(c, pics[i], Rect.fromLTRB(-h * sz * 3, -h * sz * 2, h * sz * 3, h * sz), a);
      c.restore();
    }
    final s = h * .092;
    c.save();
    c.translate((h * .95 - clock * h * .011) % span, h * .862 + math.sin(clock * 1.3) * h * .0016);
    _raftWater(c, s, a, clock);
    c.rotate(math.sin(clock * 1.1) * .012);
    _riverPicture(c, pics[3], Rect.fromLTRB(-s * 2, -s * 1.1, s * 1.3, s * .3), a);
    _raftGlow(c, s, a, clock);
    c.restore();
  }

  /// A water-worn boulder in the shallows, ringed by ripples.
  static void _riverRock(Canvas c, Offset at, double s, double a) {
    final fill = Paint();
    Color col(int v, [double k = 1]) => Sketch.fade(_hazed(Color(v), .22), a * k);
    _riverStroke
      ..strokeWidth = math.max(.8, s * .06)
      ..color = Sketch.fade(_riverLight, .42 * a);
    c.drawOval(Rect.fromCenter(center: at + Offset(0, s * .06), width: s * 2.9, height: s * .34), _riverStroke);
    final shadow = Path();
    _riverLens(shadow, at.dx + s * .1, at.dy + s * .3, s * 1.9, s * .22);
    c.drawPath(shadow, fill..color = Sketch.fade(_riverTeal, .32 * a));
    c.drawPath(
      Path()
        ..moveTo(at.dx - s, at.dy)
        ..cubicTo(at.dx - s * 1.05, at.dy - s * .6, at.dx - s * .5, at.dy - s * 1.1, at.dx + s * .05, at.dy - s * 1.05)
        ..cubicTo(at.dx + s * .7, at.dy - s, at.dx + s * 1.1, at.dy - s * .5, at.dx + s, at.dy)
        ..close(),
      fill..color = col(0xff6d7a84),
    );
    c.drawPath(
      Path()
        ..moveTo(at.dx + s * .15, at.dy - s * 1.03)
        ..cubicTo(at.dx + s * .75, at.dy - s * .98, at.dx + s * 1.1, at.dy - s * .5, at.dx + s, at.dy)
        ..lineTo(at.dx + s * .45, at.dy)
        ..cubicTo(at.dx + s * .6, at.dy - s * .5, at.dx + s * .5, at.dy - s * .8, at.dx + s * .15, at.dy - s * 1.03)
        ..close(),
      fill..color = col(0xff525e6c),
    );
    c.drawOval(Rect.fromCenter(center: at + Offset(-s * .35, -s * .78), width: s * .9, height: s * .38), fill..color = col(0xffa6b0b0));
    c.drawOval(Rect.fromCenter(center: at + Offset(-s * .05, -s * 1.0), width: s * .7, height: s * .2), fill..color = col(0xff5f8467));
  }

  /// A little egret standing on a boulder, looking to [dir].
  static void _riverEgret(Canvas c, Offset at, double u, double dir, double a) {
    final fill = Paint()..color = Sketch.fade(_hazed(const Color(0xfff6f1ea), .1), a);
    Offset q(double x, double y) => Offset(at.dx + x * dir * u, at.dy + y * u);
    _riverStroke
      ..strokeWidth = math.max(.6, u * .05)
      ..color = Sketch.fade(const Color(0xff3a3a40), .8 * a);
    c.drawLine(q(-.02, -.2), q(-.02, 0), _riverStroke);
    c.drawLine(q(.08, -.2), q(.08, 0), _riverStroke);
    c.drawPath(
      Path()
        ..moveTo(q(-.5, -.16).dx, q(-.5, -.16).dy)
        ..quadraticBezierTo(q(-.1, .0).dx, q(-.1, .0).dy, q(.2, -.3).dx, q(.2, -.3).dy)
        ..quadraticBezierTo(q(.2, -.55).dx, q(.2, -.55).dy, q(.06, -.6).dx, q(.06, -.6).dy)
        ..quadraticBezierTo(q(-.2, -.5).dx, q(-.2, -.5).dy, q(-.5, -.16).dx, q(-.5, -.16).dy)
        ..close(),
      fill,
    );
    _riverStroke
      ..strokeWidth = math.max(.6, u * .09)
      ..color = fill.color;
    c.drawPath(Path()..moveTo(q(.14, -.55).dx, q(.14, -.55).dy)..quadraticBezierTo(q(.3, -.75).dx, q(.3, -.75).dy, q(.22, -.98).dx, q(.22, -.98).dy), _riverStroke);
    c.drawCircle(q(.24, -1.0), u * .08, fill);
    _riverStroke
      ..strokeWidth = math.max(.5, u * .04)
      ..color = Sketch.fade(const Color(0xffd9a02c), .9 * a);
    c.drawLine(q(.3, -1.0), q(.5, -.95), _riverStroke);
  }

  /// A small distant raft: a hat, a pole, a low deck.
  static void _riverFarRaft(Canvas c, Offset at, double s, double a) {
    Color col(int v, [double k = 1]) => Sketch.fade(_hazed(Color(v), .38), a * k);
    final fill = Paint();
    final wake = Path();
    _riverLens(wake, at.dx - s * .1, at.dy + s * .14, s * 2.9, s * .16);
    c.drawPath(wake, fill..color = Sketch.fade(_riverLight, .42 * a));
    final refl = Path();
    _riverLens(refl, at.dx, at.dy + s * .36, s * 1.6, s * .16);
    _riverLens(refl, at.dx + s * .2, at.dy + s * .6, s * .4, s * .14);
    c.drawPath(refl, fill..color = Sketch.fade(_riverTeal, .34 * a));
    c.drawPath(
      Path()
        ..moveTo(at.dx - s * 1.15, at.dy - s * .3)
        ..quadraticBezierTo(at.dx - s * 1.0, at.dy, at.dx - s * .8, at.dy)
        ..lineTo(at.dx + s, at.dy)
        ..lineTo(at.dx + s, at.dy - s * .12)
        ..lineTo(at.dx - s * .75, at.dy - s * .12)
        ..close(),
      fill..color = col(0xffc9ae72),
    );
    c.drawRect(Rect.fromLTRB(at.dx + s * .1, at.dy - s * .9, at.dx + s * .3, at.dy - s * .12), fill..color = col(0xff4a5876));
    c.drawPath(Sketch.poly([-.2, -.86, .2, -1.2, .6, -.86], at: at + Offset(s * .2, 0), s: s), fill..color = col(0xffdcc890));
    _riverStroke
      ..strokeWidth = math.max(.6, s * .05)
      ..color = col(0xff5b4634);
    c.drawLine(at + Offset(s * .05, -s * 1.15), at + Offset(s * .8, s * .12), _riverStroke);
    for (final dx in const [-.6, -.3]) {
      c.drawOval(Rect.fromCenter(center: at + Offset(dx * s, -s * .3), width: s * .2, height: s * .34), fill..color = col(0xff2c3446));
    }
  }

  /// The fisherman's bamboo raft: cormorants, a punting pole, a lamp at the bow.
  static void _raft(Canvas c, Offset at, double s) {
    const a = 1.0;
    Offset p(double x, double y) => Offset(at.dx + x * s, at.dy + y * s);
    Path poly(List<double> xy) => Sketch.poly(xy, at: at, s: s);
    Color col(int v, [double k = 1]) => Sketch.fade(_hazed(Color(v), .06), a * k);
    final fill = _riverFill;
    final line = _riverStroke;

    // Rings on the water under the raft.
    line
      ..strokeWidth = math.max(.8, s * .026)
      ..color = Sketch.fade(_riverLight, .5 * a);
    c.drawOval(Rect.fromCenter(center: p(0, .07), width: s * 2.4, height: s * .16), line);
    line.color = Sketch.fade(_riverLight, .28 * a);
    c.drawOval(Rect.fromCenter(center: p(.05, .1), width: s * 3.0, height: s * .3), line);

    // The raft: bundled bamboo poles with an upswept bow.
    final b0 = p(-1.08, -.24), b1 = p(-.98, -.02), b2 = p(-.72, 0), b3 = p(-.7, -.1), b4 = p(-.93, -.13);
    c.drawPath(
      Path()
        ..moveTo(b0.dx, b0.dy)
        ..quadraticBezierTo(b1.dx, b1.dy, b2.dx, b2.dy)
        ..lineTo(p(.98, 0).dx, p(.98, 0).dy)
        ..lineTo(p(.98, -.1).dx, p(.98, -.1).dy)
        ..lineTo(b3.dx, b3.dy)
        ..quadraticBezierTo(b4.dx, b4.dy, b0.dx, b0.dy)
        ..close(),
      fill..color = col(0xffd2b872),
    );
    final under = Path();
    _riverLens(under, at.dx - s * .02, at.dy + s * .03, s * 1.8, s * .1);
    c.drawPath(under, fill..color = Sketch.fade(const Color(0xff5c7484), .5 * a));
    line
      ..strokeWidth = math.max(.8, s * .03)
      ..color = col(0xffefdca2);
    c.drawPath(
      Path()
        ..moveTo(p(-1.06, -.24).dx, p(-1.06, -.24).dy)
        ..quadraticBezierTo(p(-.93, -.14).dx, p(-.93, -.14).dy, b3.dx, b3.dy)
        ..lineTo(p(.98, -.1).dx, p(.98, -.1).dy),
      line,
    );
    line
      ..strokeWidth = math.max(.6, s * .014)
      ..color = col(0xffa38646);
    final nodes = Path();
    for (var k = 0; k < 7; k++) {
      nodes
        ..moveTo(p(-.6 + k * .26, -.1).dx, p(0, -.1).dy)
        ..lineTo(p(-.6 + k * .26, 0).dx, p(0, 0).dy);
    }
    nodes
      ..moveTo(b3.dx, p(0, -.05).dy)
      ..lineTo(p(.98, -.05).dx, p(0, -.05).dy);
    c.drawPath(nodes, line);

    // A fish basket at the stern.
    c.drawRect(Rect.fromLTRB(p(.6, 0).dx, p(0, -.27).dy, p(.86, 0).dx, p(0, -.1).dy), fill..color = col(0xff9a7148));
    c.drawRect(Rect.fromLTRB(p(.58, 0).dx, p(0, -.3).dy, p(.88, 0).dx, p(0, -.26).dy), fill..color = col(0xff6f4e33));
    line
      ..strokeWidth = math.max(.6, s * .012)
      ..color = col(0xffc29a66);
    c.drawLine(p(.66, -.26), p(.7, -.1), line);
    c.drawLine(p(.76, -.26), p(.8, -.1), line);

    // Cormorants on the bow half of the raft.
    _riverCormorant(c, p(-.76, -.1), s * .27, -1, 0, a);
    _riverCormorant(c, p(-.43, -.1), s * .27, 1, 1, a);
    _riverCormorant(c, p(-.06, -.1), s * .25, 1, 0, a);

    // The fisherman: straw hat, straw cape and a long pole.
    const x0 = .34;
    line
      ..strokeWidth = math.max(.9, s * .045)
      ..color = col(0xff2d3652);
    c.drawLine(p(x0 - .045, -.3), p(x0 - .06, -.1), line);
    c.drawLine(p(x0 + .05, -.3), p(x0 + .08, -.1), line);
    c.drawPath(poly([x0 - .09, -.55, x0 + .09, -.55, x0 + .11, -.3, x0 - .1, -.3]), fill..color = col(0xff3f4e72));
    c.drawPath(
      poly([x0 - .12, -.57, x0 + .12, -.57, x0 + .17, -.27, x0 + .12, -.22, x0 + .07, -.27, x0 + .02, -.21, x0 - .03, -.27, x0 - .08, -.22, x0 - .13, -.27, x0 - .17, -.25]),
      fill..color = col(0xff9c7d52),
    );
    c.drawPath(poly([x0 - .12, -.57, x0 - .02, -.57, x0 - .04, -.24, x0 - .08, -.22, x0 - .13, -.27, x0 - .17, -.25]), fill..color = col(0xffb99a62));
    line
      ..strokeWidth = math.max(.5, s * .01)
      ..color = Sketch.fade(const Color(0xff5a4230), .5 * a);
    for (final dx in const [-.09, -.03, .03, .09]) {
      c.drawLine(p(x0 + dx, -.5), p(x0 + dx * 1.3, -.3), line);
    }
    c.drawOval(Rect.fromCenter(center: p(x0, -.6), width: s * .11, height: s * .09), fill..color = col(0xffc99872));
    c.drawPath(
      Path()
        ..moveTo(p(x0 - .28, -.6).dx, p(0, -.6).dy)
        ..quadraticBezierTo(p(x0 - .1, -.65).dx, p(0, -.65).dy, p(x0, -.83).dx, p(0, -.83).dy)
        ..quadraticBezierTo(p(x0 + .1, -.65).dx, p(0, -.65).dy, p(x0 + .28, -.6).dx, p(0, -.6).dy)
        ..close(),
      fill..color = col(0xffe2cd97),
    );
    c.drawPath(
      Path()
        ..moveTo(p(x0, -.83).dx, p(0, -.83).dy)
        ..quadraticBezierTo(p(x0 + .1, -.65).dx, p(0, -.65).dy, p(x0 + .28, -.6).dx, p(0, -.6).dy)
        ..lineTo(p(x0 + .04, -.6).dx, p(0, -.6).dy)
        ..close(),
      fill..color = col(0xffbc9f66),
    );
    line
      ..strokeWidth = math.max(.9, s * .035)
      ..color = col(0xff3f4e72);
    c.drawLine(p(x0 + .06, -.5), p(x0 + .18, -.4), line);
    line
      ..strokeWidth = math.max(.9, s * .028)
      ..color = col(0xff5b4634);
    c.drawLine(p(x0 - .03, -.9), p(x0 + .45, .14), line);

    // Lamp on a short pole at the bow.
    line
      ..strokeWidth = math.max(.8, s * .022)
      ..color = col(0xff5b4634);
    c.drawLine(p(-.93, -.14), p(-.93, -.64), line);
    c.drawLine(p(-.93, -.64), p(-.8, -.64), line);
    c.drawLine(p(-.8, -.64), p(-.8, -.58), line);
    c.drawOval(Rect.fromCenter(center: p(-.8, -.5), width: s * .1, height: s * .13), fill..color = Sketch.fade(const Color(0xffd8583a), .9 * a));
    c.drawRect(Rect.fromLTRB(p(-.84, 0).dx, p(0, -.585).dy, p(-.76, 0).dx, p(0, -.575).dy), fill..color = col(0xff3f2c26));
    // A cormorant fishing beyond the bow.
    _riverCormorant(c, p(-1.55, .05), s * .25, -1, 2, a);
  }

  /// The raft's moving water, around its origin: the wobbling mirror image
  /// and the lamp's streak.
  static void _raftWater(Canvas c, double s, double a, double clock) {
    final fill = _riverFill;
    final refl = Path();
    final wob = math.sin(clock * .9) * s * .03;
    _riverLens(refl, wob, s * .17, s * 2.1, s * .07);
    _riverLens(refl, -.55 * s - wob, s * .27, s * .7, s * .06);
    _riverLens(refl, .34 * s + wob, s * .3, s * .34, s * .06);
    _riverLens(refl, .34 * s - wob, s * .42, s * .24, s * .05);
    _riverLens(refl, .34 * s + wob, s * .54, s * .36, s * .05);
    _riverLens(refl, .6 * s - wob, s * .66, s * .3, s * .04);
    c.drawPath(refl, fill..color = Sketch.fade(const Color(0xff2f4a5e), .42 * a));
    final glow = Path();
    for (var k = 0; k < 3; k++) {
      _riverLens(glow, -.8 * s + math.sin(clock * 1.1 + k) * s * .012, s * (.22 + k * .1), s * (.18 - k * .04), s * .05);
    }
    c.drawPath(glow, fill..color = Sketch.fade(const Color(0xffff9a5a), .38 * a));
  }

  /// The raft's lamp glow and the rings spreading from the pole, in the
  /// raft's own (swaying) frame.
  static void _raftGlow(Canvas c, double s, double a, double clock) {
    final flick = .85 + .15 * math.sin(clock * 2.3);
    _riverFill.color = Sketch.fade(const Color(0xffffb27a), .1 * flick * a);
    c.drawCircle(Offset(-.8 * s, -.5 * s), s * .2, _riverFill);
    _riverFill.color = Sketch.fade(const Color(0xffffb27a), .12 * flick * a);
    c.drawCircle(Offset(-.8 * s, -.5 * s), s * .12, _riverFill);
    for (var k = 0; k < 3; k++) {
      final t = (clock * .35 + k / 3) % 1.0;
      _riverStroke
        ..strokeWidth = math.max(.7, s * .02)
        ..color = Sketch.fade(_riverLight, .55 * (1 - t) * a);
      c.drawOval(Rect.fromCenter(center: Offset(.79 * s, .16 * s), width: s * (.12 + .5 * t), height: s * (.04 + .12 * t)), _riverStroke);
    }
  }

  /// A cormorant, pose 0 perched, 1 drying its wings, 2 swimming.
  static void _riverCormorant(Canvas c, Offset at, double u, double dir, int pose, double a) {
    Color col(int v) => Sketch.fade(Color(v), a);
    final fill = _riverFill;
    final line = _riverStroke;
    Offset q(double x, double y) => Offset(at.dx + x * dir * u, at.dy + y * u);
    Path poly(List<double> xy) => Sketch.poly([for (var i = 0; i < xy.length; i++) i.isEven ? xy[i] * dir : xy[i]], at: at, s: u);
    const ink = 0xff222938;
    if (pose == 2) {
      line
        ..strokeWidth = math.max(.8, u * .09)
        ..color = Sketch.fade(_riverLight, .5 * a);
      c.drawOval(Rect.fromCenter(center: at + Offset(0, u * .12), width: u * 1.8, height: u * .3), line);
      c.drawOval(Rect.fromCenter(center: q(.05, -.04), width: u * .9, height: u * .36), fill..color = col(ink));
      line
        ..strokeWidth = u * .14
        ..color = col(ink);
      c.drawPath(Path()..moveTo(q(.2, -.08).dx, q(.2, -.08).dy)..quadraticBezierTo(q(.42, -.34).dx, q(.42, -.34).dy, q(.3, -.62).dx, q(.3, -.62).dy), line);
      c.drawCircle(q(.31, -.66), u * .09, fill..color = col(ink));
      c.drawPath(poly([.36, -.7, .62, -.64, .6, -.6, .36, -.62]), fill..color = col(0xff8b9098));
      return;
    }
    line
      ..strokeWidth = math.max(.6, u * .06)
      ..color = col(0xff3a3028);
    c.drawLine(q(-.05, -.14), q(-.05, 0), line);
    c.drawLine(q(.1, -.14), q(.11, 0), line);
    if (pose == 1) {
      for (final sd in const [-1.0, 1.0]) {
        c.drawPath(
          Path()
            ..moveTo(at.dx + sd * u * .05, at.dy - u * .66)
            ..quadraticBezierTo(at.dx + sd * u * .45, at.dy - u * .86, at.dx + sd * u * .86, at.dy - u * .66)
            ..lineTo(at.dx + sd * u * .95, at.dy - u * .5)
            ..lineTo(at.dx + sd * u * .82, at.dy - u * .55)
            ..lineTo(at.dx + sd * u * .8, at.dy - u * .4)
            ..lineTo(at.dx + sd * u * .64, at.dy - u * .47)
            ..lineTo(at.dx + sd * u * .6, at.dy - u * .33)
            ..lineTo(at.dx + sd * u * .44, at.dy - u * .42)
            ..lineTo(at.dx + sd * u * .08, at.dy - u * .36)
            ..close(),
          fill..color = col(ink),
        );
      }
      c.drawOval(Rect.fromCenter(center: at + Offset(0, -u * .36), width: u * .32, height: u * .62), fill..color = col(ink));
    } else {
      c.drawPath(poly([-.1, -.32, -.42, -.02, -.24, 0, -.02, -.22]), fill..color = col(ink));
      c.save();
      c.translate(q(-.03, -.38).dx, q(-.03, -.38).dy);
      c.rotate(.28 * dir);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: u * .38, height: u * .74), fill..color = col(ink));
      c.drawOval(Rect.fromCenter(center: Offset(-u * .04 * dir, u * .04), width: u * .18, height: u * .42), fill..color = col(0xff56688a));
      c.restore();
    }
    line
      ..strokeWidth = u * .12
      ..color = col(ink);
    c.drawPath(Path()..moveTo(q(.07, -.64).dx, q(.07, -.64).dy)..quadraticBezierTo(q(.2, -.84).dx, q(.2, -.84).dy, q(.1, -.97).dx, q(.1, -.97).dy), line);
    c.drawCircle(q(.11, -1.0), u * .085, fill..color = col(ink));
    c.drawPath(poly([.16, -1.04, .4, -1.0, .43, -.95, .38, -.95, .16, -.97]), fill..color = col(0xff8b9098));
    c.drawCircle(q(.2, -.955), u * .04, fill..color = col(0xffe2a63a));
  }

  /// A tiny paper sky lantern, dim and hazed so it never reads as a pickup.
  static void _skyLantern(Canvas c, Offset p, double s, double alpha) {
    if (alpha <= 0) return;
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(s * 3, s * 3);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = _duskLampGlow
        ..color = Sketch.fade(const Color(0xffffffff), alpha),
    );
    c.restore();
    // Flared paper body, its warm lit core, a dark rim and the little flame.
    c.drawPath(
      Sketch.poly([-.66, -1, .66, -1, .46, .8, -.46, .8], at: p, s: s),
      Paint()..color = Sketch.fade(const Color(0xffe6b797), .82 * alpha),
    );
    c.drawPath(
      Sketch.poly([-.36, -.55, .36, -.55, .27, .68, -.27, .68], at: p, s: s),
      Paint()..color = Sketch.fade(const Color(0xffffae62), .8 * alpha),
    );
    c.drawRect(
      Rect.fromLTRB(p.dx - s * .7, p.dy - s * 1.08, p.dx + s * .7, p.dy - s * .9),
      Paint()..color = Sketch.fade(const Color(0xff9a6f6a), .8 * alpha),
    );
    c.drawCircle(
      p + Offset(0, s * 1.05),
      s * .17,
      Paint()..color = Sketch.fade(const Color(0xffffd89a), .9 * alpha),
    );
  }

  // --- dusk sky: sun dressing, clouds, kite, geese, lanterns -----------------

  /// Wraps a drifting element across the viewport with a margin either side.
  static double _duskDrift(double w, double h, double t, double fx, double speed) {
    final span = w + h * 1.6;
    return (w * fx - t * speed * h + h * .8) % span - h * .8;
  }

  // Size-free shaders in the unit space of the shapes they fill, built once.
  static final Shader _duskBankCool = Gradient.linear(
    const Offset(0, -.1),
    const Offset(0, .03),
    const [Color(0xffe2d6ee), Color(0xffd4c0da), Color(0xffe9bbbf), Color(0xfff6b8a1)],
    const [0, .42, .8, 1],
  );
  static final Shader _duskBankWarm = Gradient.linear(
    const Offset(0, -.1),
    const Offset(0, .03),
    const [Color(0xfff3dcdf), Color(0xfff2c9c6), Color(0xfff7bca6), Color(0xfffaaf92)],
    const [0, .42, .8, 1],
  );
  static final Shader _duskBarFill = Gradient.linear(
    const Offset(0, -.2),
    const Offset(0, .14),
    const [Color(0xfffbeae4), Color(0xfff2cfcd), Color(0xffdcaab8)],
    const [0, .55, 1],
  );
  static final Shader _duskLampGlow = Gradient.radial(
    Offset.zero,
    1,
    const [Color(0x55ffc98a), Color(0x00ffc98a)],
  );

  /// A soft warm band of light along the horizon behind the karsts, and the
  /// first deepening of dusk violet at the top of the sky.
  static void _duskHorizon(Canvas c, double w, double h, double a) {
    if (a <= 0) return;
    c.save();
    c.scale(w, h * .36);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()
        ..shader = _duskZenith
        ..color = Sketch.fade(const Color(0xffffffff), a),
    );
    c.restore();
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(w * .62, h * .56), width: w * 1.5, height: h * .3),
      const Color(0xffffdcc0),
      .55 * a,
    );
  }

  /// The sun: crepuscular rays, a soft bloom, a shaded vermilion disc and
  /// faint halo rings. Drawn over the compositor's flat disc.
  static void _duskSun(Canvas c, Offset at, double r, double t, double a) {
    if (a <= 0) return;
    // Everything is drawn in units of the sun's radius around its centre; the
    // shaders and the ray fan are shared, only the paint alpha changes.
    final paint = Paint();
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r, r);
    c.save();
    c.scale(15, 15);
    paint
      ..shader = _duskRayFill
      ..color = Sketch.fade(const Color(0xffffffff), (.8 + .2 * math.sin(t * .5)) * a);
    c.drawPath(_duskRays, paint);
    c.restore();
    paint
      ..shader = _duskBloom
      ..color = Sketch.fade(const Color(0xffffffff), a);
    c.drawCircle(Offset.zero, 3, paint);
    paint.shader = _duskDisc;
    c.drawCircle(Offset.zero, 1, paint);
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = .05
      ..color = Sketch.fade(const Color(0xfffff0e0), .16 * a);
    c.drawCircle(Offset.zero, 1.6, paint);
    paint.color = Sketch.fade(const Color(0xfffff0e0), .09 * a);
    c.drawCircle(Offset.zero, 2.3, paint);
    c.restore();
  }

  // The sun's shared shaders and its fan of crepuscular rays (unit radius).
  static final Shader _duskZenith = Gradient.linear(
    Offset.zero,
    const Offset(0, 1),
    const [Color(0x4d7a66a6), Color(0x007a66a6)],
  );
  static final Shader _duskRayFill = Gradient.radial(
    Offset.zero,
    1,
    const [Color(0x33ffcaa8), Color(0x00ffcaa8)],
  );
  static final Shader _duskBloom = Gradient.radial(
    Offset.zero,
    3,
    const [Color(0x80ffcaa8), Color(0x33ffcaa8), Color(0x00ffcaa8)],
    const [.33, .5, 1],
  );
  static final Shader _duskDisc = Gradient.radial(
    const Offset(-.18, -.2),
    1.32,
    const [Color(0xffffb794), Color(0xfff67d62), Color(0xffe4533f)],
    const [0, .55, 1],
  );
  static final Path _duskRays = () {
    final rays = Path();
    for (var i = 0; i < 12; i++) {
      final ang = -math.pi * 1.06 + i * .3 + (Sketch.hash(i + 610) - .5) * .16;
      final half = .011 + .016 * Sketch.hash(i + 620);
      rays
        ..moveTo(0, 0)
        ..lineTo(math.cos(ang - half), math.sin(ang - half))
        ..lineTo(math.cos(ang + half), math.sin(ang + half))
        ..close();
    }
    return rays;
  }();

  // Unit shapes, built once: a tapered lens (width 1) and the crescent moon
  // (radius 1).
  static final _duskLens = _duskLensPath(1, 1, 0, 0);
  static final _duskMoonShape = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 1)),
    Path()..addOval(Rect.fromCircle(center: const Offset(.42, -.16), radius: .86)),
  );

  /// A cloud bank of width 1 as (body, crest): shallow rounded domes on a
  /// flat belly, tapering to points. Each lobe is (x of its right cusp, height).
  static (Path, Path) _duskBank(List<(double, double)> lobes) {
    final body = Path()..moveTo(-.5, 0), crest = Path()..moveTo(-.5, 0);
    var x0 = -.5, y0 = 0.0;
    for (var i = 0; i < lobes.length; i++) {
      final (x1, hgt) = lobes[i];
      final last = i == lobes.length - 1;
      final y1 = last ? 0.0 : -math.min(hgt, lobes[i + 1].$2) * .7;
      final span = x1 - x0, k = hgt * 1.33;
      final ax = x0 + span * (i == 0 ? .35 : .05);
      final bx = x1 - span * (last ? .35 : .05);
      body.cubicTo(ax, y0 - k, bx, y1 - k, x1, y1);
      crest.cubicTo(ax, y0 - k, bx, y1 - k, x1, y1);
      x0 = x1;
      y0 = y1;
    }
    body
      ..cubicTo(.3, .03, -.3, .03, -.5, 0)
      ..close();
    return (body, crest);
  }

  static final _duskBankA = _duskBank(const [(-.3, .035), (-.05, .075), (.18, .05), (.36, .07), (.5, .025)]);
  static final _duskBankB = _duskBank(const [(-.32, .045), (-.08, .07), (.2, .085), (.5, .03)]);
  static final _duskBankC = _duskBank(const [(-.22, .03), (.08, .055), (.3, .04), (.5, .02)]);
  static final _duskBankD = _duskBank(const [(-.3, .02), (-.1, .04), (.15, .05), (.34, .03), (.5, .015)]);

  static void _duskLensAt(Canvas c, Offset at, double half, double thick, Paint paint) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(half * 2, thick / .63);
    c.drawPath(_duskLens, paint);
    c.restore();
  }

  /// A tapered lens of width 1 about (tx, ty), stretched by (sx, sy).
  static Path _duskLensPath(double sx, double sy, double tx, double ty) => Path()
    ..moveTo(-.5 * sx + tx, ty)
    ..cubicTo(-.3 * sx + tx, -.55 * sy + ty, .25 * sx + tx, -.6 * sy + ty, .5 * sx + tx, ty)
    ..cubicTo(.28 * sx + tx, .24 * sy + ty, -.28 * sx + tx, .3 * sy + ty, -.5 * sx + tx, ty)
    ..close();

  // A cirrus streak: one lens with two fine combed hairlines beside it.
  static final _duskStreak = Path()
    ..addPath(_duskLens, Offset.zero)
    ..addPath(_duskLensPath(.7, .16, .05, -.315), Offset.zero)
    ..addPath(_duskLensPath(.55, .16, .05, .378), Offset.zero);

  /// Fine combed cirrus high in the lavender sky.
  static void _duskCirrus(Canvas c, double w, double h, double t, double a) {
    if (a <= 0) return;
    final paint = Paint();
    var i = 0;
    for (final (fx, y, len, thick, tilt, alpha) in const [
      (.08, .06, 1.2, .016, -.03, .3),
      (.42, .12, .9, .012, -.02, .26),
      (.72, .05, 1.1, .014, -.025, .28),
      (.95, .18, .8, .011, -.02, .22),
      (.25, .22, .7, .01, -.03, .2),
      (.6, .17, .75, .009, -.02, .18),
    ]) {
      final x = _duskDrift(w, h, t, fx, .004 + .0015 * (i % 3));
      paint.color = Sketch.fade(const Color(0xfff2dfee), alpha * a);
      c.save();
      c.translate(x, h * y);
      c.rotate(tilt);
      c.scale(h * len, h * thick / .63);
      c.drawPath(_duskStreak, paint);
      c.restore();
      i++;
    }
  }

  /// Long strata lying near the horizon, mostly behind the karsts.
  static void _duskStrata(Canvas c, double w, double h, double t, double a) {
    if (a <= 0) return;
    final paint = Paint();
    for (final (fx, y, len, thick) in const [
      (.15, .5, 1.3, .02),
      (.55, .47, 1.6, .018),
      (.85, .53, 1.2, .02),
      (.35, .58, 1.5, .018),
      (.7, .6, 1.4, .016),
    ]) {
      final x = _duskDrift(w, h, t, fx, .01);
      paint.color = Sketch.fade(const Color(0xfff3c3bb), .5 * a);
      _duskLensAt(c, Offset(x, h * y), h * len / 2, h * thick, paint);
      paint.color = Sketch.fade(const Color(0xfffff0e0), .35 * a);
      _duskLensAt(c, Offset(x, h * y - h * thick * .25), h * len * .4, h * thick * .3, paint);
    }
  }

  /// Bars of mist veiling the lower half of the sun.
  static void _duskSunBars(Canvas c, Offset at, double r, double t, double a) {
    if (a <= 0) return;
    final paint = Paint()
      ..shader = _duskBarFill
      ..color = Sketch.fade(const Color(0xffffffff), .9 * a);
    var i = 0;
    // Broken bars, staggered like mist strokes: (dx, dy, half length, thickness).
    for (final (dx, dy, half, thick) in const [
      (.7, -.44, 1.7, .08),
      (-1.9, -.36, 1.2, .06),
      (.15, .3, 2.5, .15),
      (-2.4, .4, 1.4, .09),
      (-.6, .8, 3.2, .2),
      (2.9, .72, 1.5, .1),
    ]) {
      final sway = math.sin(t * .15 + i * 2.1) * r * .3;
      _duskLensAt(c, at + Offset(dx * r + sway, dy * r), half * r, thick * r, paint);
      i++;
    }
  }

  /// Layered ink-wash cloud banks, their bellies lit warm by the low sun.
  static void _duskBanks(Canvas c, double w, double h, double t, double a) {
    if (a <= 0) return;
    final paint = Paint();
    final line = Paint()..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    for (final (fx, y, width, speed, warm, flip, bank) in [
      (.27, .19, 1.05, .007, false, 1.0, _duskBankA),
      (.82, .145, .85, .006, false, -1.0, _duskBankB),
      (.37, .34, .6, .009, true, 1.0, _duskBankC),
      (.95, .335, .55, .01, true, -1.0, _duskBankB),
      (.68, .085, .5, .005, false, 1.0, _duskBankD),
    ]) {
      final x = _duskDrift(w, h, t, fx, speed);
      final wide = h * width;
      c.save();
      c.translate(x, h * y);
      c.scale(wide * flip, wide);
      // A hazier bank behind, then the bank itself with its bright crest.
      c.save();
      c.translate(.13, -.014);
      c.scale(1.12, 1);
      paint
        ..shader = null
        ..color = Sketch.fade(warm ? const Color(0xffeccbcb) : const Color(0xffcbb7d8), .5 * a);
      c.drawPath(bank.$1, paint);
      c.restore();
      paint
        ..shader = warm ? _duskBankWarm : _duskBankCool
        ..color = Sketch.fade(const Color(0xffffffff), .96 * a);
      c.drawPath(bank.$1, paint);
      // Nested ink contours inside the domes give the layered, brushed look.
      line
        ..strokeWidth = .0022
        ..color = Sketch.fade(warm ? const Color(0xffc9909a) : const Color(0xffa48cba), .24 * a);
      for (final k in const [.84, .62]) {
        c.save();
        c.translate(0, .004);
        c.scale(k, k * .8);
        c.drawPath(bank.$2, line);
        c.restore();
      }
      line
        ..strokeWidth = .0028
        ..color = Sketch.fade(const Color(0xfffff3ec), .5 * a);
      c.drawPath(bank.$2, line);
      c.restore();
    }
  }

  // An auspicious ruyi cloud (head on the left, a streaming tail) and the
  // spiral curl inside its head, in a unit box about 1 wide.
  static final _duskRuyiShape = Path()
    ..moveTo(-.5, .06)
    ..cubicTo(-.58, -.04, -.55, -.2, -.4, -.22)
    ..cubicTo(-.38, -.34, -.2, -.38, -.13, -.28)
    ..cubicTo(-.02, -.32, .08, -.22, .06, -.11)
    ..cubicTo(.22, -.13, .42, -.06, .6, -.16)
    ..cubicTo(.46, -.02, .24, .05, .02, .07)
    ..cubicTo(-.12, .12, -.36, .13, -.5, .06)
    ..close();
  static final _duskRuyiCurl = () {
    final curl = Path();
    for (var i = 0; i <= 24; i++) {
      final u = i / 24, ang = 2.4 + u * math.pi * 3.2, rad = .12 * (1 - u * .82);
      final p = Offset(-.3 + math.cos(ang) * rad * 1.1, -.09 + math.sin(ang) * rad * .95);
      i == 0 ? curl.moveTo(p.dx, p.dy) : curl.lineTo(p.dx, p.dy);
    }
    return curl;
  }();

  /// A drifting auspicious cloud, pale and flat, high between the banks.
  static void _duskRuyi(Canvas c, double w, double h, double t, double a) {
    if (a <= 0) return;
    final x = _duskDrift(w, h, t, .44, .005);
    c.save();
    c.translate(x, h * .07);
    c.scale(h * .24, h * .24);
    c.drawPath(_duskRuyiShape, Paint()..color = Sketch.fade(const Color(0xfff7e6ee), .62 * a));
    c.drawPath(
      _duskRuyiCurl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .012
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(const Color(0xffb79fc8), .55 * a),
    );
    c.restore();
  }

  /// A pale crescent rising in the east, opposite the sun.
  static void _duskMoon(Canvas c, double w, double h, double a) {
    if (a <= 0) return;
    final at = Offset(w * .075, h * .105);
    final r = h * .024;
    Sketch.mist(c, Rect.fromCenter(center: at, width: r * 7, height: r * 7), const Color(0xfffff0e6), .3 * a);
    // Earthshine: the dark limb barely there beside the bright crescent.
    c.drawCircle(at, r, Paint()..color = Sketch.fade(const Color(0xfffff0e6), .09 * a));
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(-.5);
    c.scale(r, r);
    c.drawPath(_duskMoonShape, Paint()..color = Sketch.fade(const Color(0xfffff6ee), .7 * a));
    c.restore();
  }

  /// A centipede dragon kite streaming on the wind, its string running down
  /// behind the karsts.
  static void _duskKite(Canvas c, double w, double h, double t, double a) {
    if (a <= 0) return;
    final head = Offset(w * .13 + math.sin(t * .5) * h * .012, h * .26 + math.sin(t * .37) * h * .008);
    final holder = Offset(w * .24, h * .7);
    c.drawPath(
      Path()
        ..moveTo(head.dx, head.dy)
        ..quadraticBezierTo(head.dx + (holder.dx - head.dx) * .2, head.dy + (holder.dy - head.dy) * .8, holder.dx, holder.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0012)
        ..color = Sketch.fade(const Color(0xff8a7a92), .5 * a),
    );
    const n = 11;
    final r0 = h * .0125;
    Offset at(double s) => head + Offset(-s * h * .13 + math.sin(s * 6 - t * 2.2) * h * .02 * math.min(1.0, s * 2.5), s * h * .2);
    // Tail ribbons, then the legs, then the painted paper discs.
    final end = at(1);
    final ribbon = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, h * .002);
    for (final (k, color) in const [(-1.0, Color(0xffe0b26e)), (1.0, Color(0xffc45c56))]) {
      final path = Path()..moveTo(end.dx, end.dy);
      for (var j = 1; j <= 5; j++) {
        path.lineTo(end.dx - j * h * .008 + k * h * .004 * j * .5, end.dy + j * h * .012 + math.sin(j * 1.3 - t * 3 + k) * h * .006);
      }
      ribbon.color = Sketch.fade(color, .8 * a);
      c.drawPath(path, ribbon);
    }
    final legs = Path();
    final paint = Paint();
    for (var k = n; k >= 1; k--) {
      final s = k / n;
      final p = at(s), r = r0 * (1 - s * .38);
      final q = at(math.min(1.0, s + .04)) - at(math.max(0.0, s - .04));
      final side = Offset(-q.dy, q.dx) / q.distance * r * 1.75;
      legs
        ..moveTo(p.dx - side.dx, p.dy - side.dy)
        ..lineTo(p.dx + side.dx, p.dy + side.dy);
    }
    c.drawPath(
      legs,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0016)
        ..color = Sketch.fade(const Color(0xff6a4a52), .55 * a),
    );
    for (var k = n; k >= 1; k--) {
      final s = k / n;
      final p = at(s), r = r0 * (1 - s * .38);
      final red = k.isEven;
      paint.color = Sketch.fade(red ? const Color(0xffc45c56) : const Color(0xffe6c384), .92 * a);
      c.drawCircle(p, r, paint);
      paint.color = Sketch.fade(red ? const Color(0xffe6c384) : const Color(0xffc45c56), .8 * a);
      c.drawCircle(p, r * .45, paint);
    }
    // The dragon's head: mane, horns, eyes.
    final mane = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, h * .0024)
      ..color = Sketch.fade(const Color(0xff4f8a80), .9 * a);
    final hr = r0 * 1.6;
    for (var j = 0; j < 4; j++) {
      final ang = -2.6 + j * .5;
      c.drawLine(head + Offset(math.cos(ang), math.sin(ang)) * hr * .8, head + Offset(math.cos(ang), math.sin(ang)) * hr * 1.7, mane);
    }
    paint.color = Sketch.fade(const Color(0xffa8433f), a);
    c.drawCircle(head, hr, paint);
    paint.color = Sketch.fade(const Color(0xffe6c384), .95 * a);
    c.drawCircle(head + Offset(hr * .05, hr * .5), hr * .38, paint);
    paint.color = Sketch.fade(const Color(0xfffff4e6), a);
    for (final dx in const [-.42, .42]) {
      c.drawCircle(head + Offset(hr * dx, -hr * .12), hr * .2, paint);
    }
    c.drawPath(
      Path()
        ..moveTo(head.dx - hr * .55, head.dy - hr * .7)
        ..quadraticBezierTo(head.dx - hr * .9, head.dy - hr * 1.5, head.dx - hr * .3, head.dy - hr * 1.7)
        ..moveTo(head.dx + hr * .55, head.dy - hr * .7)
        ..quadraticBezierTo(head.dx + hr * .9, head.dy - hr * 1.5, head.dx + hr * .3, head.dy - hr * 1.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, h * .0022)
        ..color = Sketch.fade(const Color(0xffe6c384), .95 * a),
    );
  }

  /// A loose V of wild geese, flapping in a travelling wave.
  static void _duskGeese(
    Canvas c,
    double w,
    double h,
    double t,
    double a, {
    bool held = false,
  }) {
    if (a <= 0) return;
    if (held) {
      // A campaign level outlasts one skein: another flies in from the
      // right once the last has gone off the left, a few seconds later.
      final enter = -(w * .16 + h * .1) / (h * .05);
      final leave = (w * .84 + h * .2) / (h * .05);
      final cycle = leave - enter + 8;
      t = enter + (t - enter) % cycle;
    }
    final lead = Offset(w * .84 - t * h * .05, h * (.235 - t * .0024));
    final paint = Paint()..color = Sketch.fade(const Color(0xff6f5f7b), .6 * a);
    for (var i = 0; i < 9; i++) {
      final row = (i + 1) ~/ 2;
      final side = i.isOdd ? -1.0 : 1.0;
      final flap = math.sin(t * 5.2 - i * .55);
      _duskGoose(
        c,
        lead + Offset(row * h * .034, side * row * h * .011 - flap * h * .0012),
        h * (.0125 - .0004 * row),
        paint,
        flap,
      );
    }
  }

  // A goose facing left, body 1 long: body, neck, head and bill in one path.
  static final _duskGooseBody = Path()
    ..moveTo(.72, -.05)
    ..quadraticBezierTo(.3, -.26, -.22, -.15)
    ..quadraticBezierTo(-.46, -.08, -.44, .07)
    ..quadraticBezierTo(-.3, .22, .2, .15)
    ..quadraticBezierTo(.5, .09, .72, -.05)
    ..close()
    ..moveTo(-.28, -.17)
    ..quadraticBezierTo(-.62, -.36, -.93, -.36)
    ..lineTo(-1.09, -.34)
    ..lineTo(-1.3, -.26)
    ..lineTo(-1.1, -.22)
    ..lineTo(-.92, -.2)
    ..quadraticBezierTo(-.62, -.12, -.32, .1)
    ..close();

  // The whole goose, baked for 24 wing poses from full downstroke to full
  // upstroke: the body plus a far and a near broad wing swung about the shoulder.
  static const _duskPoses = 24;
  static final _duskGoosePoses = [
    for (var i = 0; i < _duskPoses; i++) _duskGoosePose(i / (_duskPoses - 1) * 2 - 1),
  ];

  static Path _duskGoosePose(double flap) {
    final pose = Path()..addPath(_duskGooseBody, Offset.zero);
    final phi = .25 - flap * 1.3, cs = math.cos(phi), sn = math.sin(phi);
    for (final (dx, dy, k) in const [(.12, -.06, .86), (-.08, -.1, 1.0)]) {
      // A broad wing blade: u along the arm, v toward the trailing edge.
      Offset pt(double u, double v) => Offset(dx + k * (u * cs - v * sn), dy + k * (u * sn + v * cs));
      final a = pt(.6, -.14), b = pt(1.42, .08), c1 = pt(1.02, .5), d = pt(.7, .6), e = pt(.3, .62), f = pt(0, .4);
      // Wound the same way as the body, so overlaps merge instead of cancelling.
      pose
        ..moveTo(dx, dy)
        ..lineTo(f.dx, f.dy)
        ..quadraticBezierTo(e.dx, e.dy, d.dx, d.dy)
        ..quadraticBezierTo(c1.dx, c1.dy, b.dx, b.dy)
        ..quadraticBezierTo(a.dx, a.dy, dx, dy)
        ..close();
    }
    return pose;
  }

  /// One goose flying left; [flap] in -1..1.
  static void _duskGoose(Canvas c, Offset p, double s, Paint paint, double flap) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(s, s);
    c.drawPath(_duskGoosePoses[((flap * .5 + .5) * (_duskPoses - 1)).round()], paint);
    c.restore();
  }

  /// A few dim lanterns released far off, hugging the edges and the top.
  static void _duskLanterns(
    Canvas c,
    double w,
    double h,
    double t,
    double a, {
    bool held = false,
  }) {
    if (a <= 0) return;
    // In a campaign level each lantern comes round again: it rises from
    // behind the hills, climbs out of the top and is let go once more.
    const below = .3, rise = .0085;
    var i = 0;
    for (final (fx, fy, size, alpha) in const [
      (.9, .3, .011, .62),
      (.955, .22, .009, .55),
      (.87, .16, .008, .48),
      (.985, .35, .01, .58),
      (.035, .21, .01, .62),
      (.02, .34, .009, .55),
      (.06, .4, .007, .45),
    ]) {
      final x = w * fx + math.sin(t * .4 + i * 1.7) * h * .008;
      final climb = held
          ? (t + below / rise) % ((fy + below + .03) / rise) - below / rise
          : t;
      final y = h * fy - climb * h * rise;
      final top = ((y / h) / .06).clamp(0.0, 1.0);
      // A new lantern is lit as it clears the hills.
      final lit = held ? RegionBlend.smooth((climb + below / rise) / 5) : 1.0;
      _skyLantern(c, Offset(x, y), h * size, alpha * top * a * lit);
      i++;
    }
  }
}
