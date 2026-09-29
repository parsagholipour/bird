import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Hazed colours and pens for one church, so its drawing helpers share a
/// palette: [lit] faces catch the low sun on the left and [side] faces turn
/// into shade. [px] is one screen pixel in the church's own units, and [fine]
/// and [rich] say how much detail is big enough on screen to read.
class _ChurchKit {
  _ChurchKit(double haze, double s)
    : px = 1 / math.max(s, 1.0),
      fine = s > 55,
      rich = s > 110,
      lit = MexicoScene._hazed(const Color(0xffeeb768), haze),
      mid = MexicoScene._hazed(const Color(0xffcd8b50), haze + .02),
      side = MexicoScene._hazed(const Color(0xffa8663f), haze + .03),
      deep = MexicoScene._hazed(const Color(0xff70402f), haze + .05),
      trim = MexicoScene._hazed(const Color(0xfffbdca0), haze),
      trimSide = MexicoScene._hazed(const Color(0xffd29c68), haze + .03),
      glint = MexicoScene._hazed(const Color(0xffffeab8), haze),
      dark = MexicoScene._hazed(const Color(0xff3a2226), haze + .05),
      glass = MexicoScene._hazed(const Color(0xff3d2b45), haze + .04),
      glow = MexicoScene._hazed(const Color(0xffffa84a), haze * .5),
      blue = MexicoScene._hazed(const Color(0xff3b86c6), haze),
      gold = MexicoScene._hazed(const Color(0xfff5c441), haze),
      white = MexicoScene._hazed(const Color(0xfff8efdc), haze),
      bell = MexicoScene._hazed(const Color(0xffe2a63a), haze),
      bellSide = MexicoScene._hazed(const Color(0xff9c6420), haze + .03),
      metal = MexicoScene._hazed(const Color(0xfff0c25a), haze);

  final double px;
  final bool fine, rich;
  final Color lit, mid, side, deep, trim, trimSide, glint, dark, glass, glow, blue, gold, white, bell, bellSide, metal;
  final Paint _fill = Paint();
  final Paint _pen = Paint()..style = PaintingStyle.stroke;

  /// The shared fill paint, set to [c].
  Paint fill(Color c) => _fill..color = c;

  /// The shared pen, set to [c] and [width].
  Paint pen(Color c, double width) => _pen
    ..color = c
    ..strokeWidth = width;
}

/// Mexico at dusk: the Sierra Madre and two snowcapped volcanoes in violet,
/// a colonial hill town of pastel houses around a twin-towered cathedral,
/// agave fields, an adobe hut and saguaros on the dusty plain, and prickly
/// pear and marigolds beside a swinging piñata on the near ground. Strings of
/// papel picado sway across a glowing sky, swallows wheel over the range and
/// bougainvillea petals drift on the evening air. Every form is lit from the
/// left, where the sun sinks between the volcanoes.
class MexicoScene extends RegionScene {
  const MexicoScene();

  @override
  WorldRegion get region => WorldRegion.mexico;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.42, .5),
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
      Color(0xff74503e),
      Color(0xff45302c),
      Color(0xffd29a68),
      rimWidth: .0045,
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

  /// Timed bands drift on the region clock (up to about .4 viewport heights
  /// over a visit), so their scenery is composed this far past the right edge.
  static const _reach = .7;

  /// The smoking volcano's world x, shared by its painting and its plume.
  static double _popoX(double w) => w * .8;
  static const _popoTop = .37;

  /// Height of the piñata beam above the near ground at world x [x].
  double _beamY(double x, double h) => _y(Depth.near, x, h) - h * .3;

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        _sierra(c, w, h);
        _izta(c, w * .2, h);
        _popo(c, _popoX(w), h);
        _mtnFoothills(c, w, h);
      case Depth.mid:
        _town(c, w, h, h * .04, .35, 0);
        // The churches stand on terraces above the hill lanes, so the front
        // row of houses hides only their footings and the portals show.
        _church(c, Offset(w * .6, _y(Depth.mid, w * .6, h) - h * .065), h * .34, .15);
        _church(c, Offset(w * .2, _y(Depth.mid, w * .2, h) - h * .07), h * .2, .3, chapel: true);
        _town(c, w, h, 0, .05, 1);
      case Depth.low:
        for (var i = 0; i < 9; i++) {
          final x = span * (i + .3 + .4 * Sketch.hash(i + 720)) / 9;
          // Two of the rosettes have thrown up a flowering quiote.
          _floraAgave(c, Offset(x, _y(d, x, h) + h * .012), h * (.05 + .02 * Sketch.hash(i + 721)), i, quiote: i == 2 || i == 6);
        }
        for (final (i, (fx, s)) in const [(.22, 1.0), (.84, .8)].indexed) {
          final x = span * fx;
          _floraSaguaro(c, Offset(x, _y(d, x, h) + h * .012), h * .2 * s, flip: i.isEven ? 1.0 : -1.0);
        }
        final organ = span * .44;
        _floraOrgan(c, Offset(organ, _y(d, organ, h) + h * .012), h * .15);
        final hut = span * .56;
        _hut(c, Offset(hut, _y(d, hut, h) + h * .012), h * .11);
      case Depth.near:
        for (final (i, (fx, s)) in const [(.06, 1.0), (.7, .8), (.9, .7)].indexed) {
          final x = span * fx;
          _pear(c, Offset(x, _y(d, x, h) + h * .012), h * .12 * s, dir: i == 1 ? -1.0 : 1.0);
        }
        for (final (i, (fx, s)) in _mgSpots.indexed) {
          final x = span * fx;
          _marigolds(c, Offset(x, _y(d, x, h) + h * .012), h * .09 * s, seed: i);
        }
        // Two posts and a beam hold the piñata, all level with its anchor.
        _pnRig(c, d, span, h);
    }
  }

  // ---- The piñata: a seven-point star of fringed crepe paper on a twisted
  // rope. Everything below is drawn in "star units", where 1 is the distance
  // from the star's centre to a point's tip and -y is up the point.

  /// Rope angle from the vertical at time [t]: a lazy swing with a small wobble.
  static double _pnSwing(double t) => math.sin(t * 1.6 + .6) * .28 + math.sin(t * 3.7 + 1.9) * .03;

  /// Angular speed of [_pnSwing], in radians per second.
  static double _pnRate(double t) => math.cos(t * 1.6 + .6) * .448 + math.cos(t * 3.7 + 1.9) * .111;

  static double _pnRadius(double h) => h * .06;
  static double _pnRope(double h) => h * .072;

  /// Where the rope meets the star's top point, and where the star's centre
  /// hangs. The body trails the rope a moment, so the pair never quite line up.
  static (Offset, Offset) _pnHang(Offset pivot, double h, double t) {
    final s = _pnSwing(t), sl = _pnSwing(t - .12);
    final tip = pivot + Offset(math.sin(s), math.cos(s)) * _pnRope(h);
    return (tip, tip + Offset(math.sin(sl), math.cos(sl)) * _pnRadius(h));
  }

  /// Crepe colours round the star, each (paper, pale, deep, tip accent). The
  /// hues alternate warm and cool so neighbouring points never blur together.
  static const _pnPalette = <(Color, Color, Color, Color)>[
    (Color(0xffe8447c), Color(0xfff98bb0), Color(0xff9c2458), Color(0xfff8d12e)),
    (Color(0xfff8c81e), Color(0xfffde36a), Color(0xffb98a0e), Color(0xff22b8c4)),
    (Color(0xff8d4cc4), Color(0xffbc8fe6), Color(0xff542a86), Color(0xfff08a1c)),
    (Color(0xfff07a1c), Color(0xfffaa95a), Color(0xffa8480c), Color(0xffe8447c)),
    (Color(0xff1fb0c0), Color(0xff72dade), Color(0xff0d6f80), Color(0xffe5352f)),
    (Color(0xffe23a30), Color(0xfffb7d70), Color(0xff961a24), Color(0xfff8d12e)),
    (Color(0xff4cb04e), Color(0xff92da74), Color(0xff2a6f38), Color(0xffe8447c)),
  ];
  static final _pnTint = [for (final e in _pnPalette) Sketch.mix(e.$4, const Color(0xffffffff), .38)];

  /// Sunlit and shaded veils in nine strengths, so a point turning in the
  /// swing brightens or dims without any per-frame colour maths.
  static final _pnLit = [for (var i = 0; i <= 8; i++) Sketch.fade(const Color(0xffffd68a), .34 * i / 8)];
  static final _pnShade = [for (var i = 0; i <= 8; i++) Sketch.fade(const Color(0xff2a1450), .44 * i / 8)];

  static const _pnInk = Color(0x6a1e1226);
  static const _pnGloom = Color(0xff1e1226);
  static const _pnCore = Color(0xff6a3358);
  static const _pnCream = Color(0xfffff0cf);
  static const _pnRose = Color(0xffd8305a);
  static const _pnRim = Color(0xffa8621a);
  static const _pnFoil = Color(0xfff4bd3c);
  static const _pnRopeMid = Color(0xffc9a468);
  static const _pnRopeHi = Color(0xffefd9a4);
  static const _pnRopeLo = Color(0xff8a6a3c);
  static const _pnRopeGroove = Color(0x8c5e4020);

  static final _pnFill = Paint();
  static final _pnLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Half the width of a point at height [y] (its tip is at -1).
  static double _pnHalf(double y) => .2312 * (1 + y);

  /// One point of the star, tip up: it meets its neighbours at radius .36.
  static final _cone = Sketch.poly(const [0, -1, .1562, -.3244, .19, -.19, -.19, -.19, -.1562, -.3244]);
  static final _pnHalfL = Sketch.poly(const [0, -1, 0, -.19, -.19, -.19, -.1562, -.3244]);
  static final _pnHalfR = Sketch.poly(const [0, -1, .1562, -.3244, .19, -.19, 0, -.19]);
  static final _pnCap = Sketch.poly(const [0, -1, .0601, -.74, -.0601, -.74]);
  static final _pnAxis = Path()
    ..moveTo(0, -.985)
    ..lineTo(0, -.4);

  /// A row of [n] pointed paper strips glued at height [yh] and hanging out
  /// to [yt] toward the tip, each cut a little differently, like crepe fringe.
  static Path _pnComb(double yh, double yt, int n, double point, int seed) {
    final path = Path();
    final wh = _pnHalf(yh);
    for (var i = 0; i < n; i++) {
      final u0 = -1 + 2 * i / n + .07, u1 = -1 + 2 * (i + 1) / n - .07;
      final y = yt + (Sketch.hash(seed + i) - .5) * .04;
      final tip = y - point * (.7 + .6 * Sketch.hash(seed + 40 + i));
      final wt = _pnHalf(y), wp = _pnHalf(tip);
      path
        ..moveTo(u0 * wh, yh)
        ..lineTo(u1 * wh, yh)
        ..lineTo(u1 * wt, y)
        ..lineTo((u0 + u1) / 2 * wp, tip)
        ..lineTo(u0 * wt, y)
        ..close();
    }
    return path;
  }

  static final _pnBandM = _pnComb(-.56, -.82, 4, .04, 100);
  static final _pnBandB = _pnComb(-.32, -.62, 5, .045, 120);
  static final _pnShadM = _pnBandM.shift(const Offset(0, -.028));
  static final _pnShadB = _pnBandB.shift(const Offset(0, -.028));

  /// A collar of [n] paper strips radiating from [r0] out to [r1].
  static Path _pnRing(int n, double r0, double r1, double point, double phase) {
    final path = Path();
    final half = math.pi / n * .92;
    Offset at(double r, double a) => Offset(r * math.sin(a), -r * math.cos(a));
    for (var i = 0; i < n; i++) {
      final a = phase + 2 * math.pi * i / n;
      final end = r1 * (.96 + .08 * Sketch.hash(i + n * 7));
      final p0 = at(r0, a - half), p1 = at(r0, a + half);
      final p2 = at(end, a + half * .9), p3 = at(end + point, a), p4 = at(end, a - half * .9);
      path
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();
    }
    return path;
  }

  static final _pnRingA = _pnRing(15, .25, .385, .03, 0);
  static final _pnRingB = _pnRing(11, .09, .27, .03, .3);

  /// A seven-point star stamped in the foil medallion.
  static final _pnEmboss = () {
    final xy = <double>[];
    for (var i = 0; i < 14; i++) {
      final a = math.pi * i / 7, r = i.isEven ? .1 : .045;
      xy
        ..add(r * math.sin(a))
        ..add(-r * math.cos(a));
    }
    return Sketch.poly(xy);
  }();

  static Path _pnDisc(double x, double y, double r) => Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  /// Crescents for the body's shaded lower right and its lit upper left.
  static final _pnLuneShade = Path.combine(PathOperation.difference, _pnDisc(0, 0, .415), _pnDisc(-.07, -.06, .415));
  static final _pnLuneLit = Path.combine(PathOperation.difference, _pnDisc(0, 0, .415), _pnDisc(.055, .05, .415));
  static final _pnStreak = Sketch.poly(const [-.075, .045, -.052, .058, .075, -.045, .052, -.058]);

  /// A tassel of fringed crepe hanging out of the origin along -y: a broad
  /// body cut into five pointed strands, a paler core, and the slits between.
  static final _pnTuftSide = Sketch.poly(const [
    -.027, 0, -.0675, -.18, -.0783, -.279, -.0558, -.207, -.036, -.315, -.018, -.225, 0, -.351, //
    .018, -.225, .036, -.315, .0558, -.207, .0783, -.279, .0675, -.18, .027, 0,
  ]);
  static final _pnTuftMid = Sketch.poly(const [
    -.018, 0, -.0405, -.171, -.0414, -.252, -.0216, -.207, 0, -.297, //
    .0216, -.207, .0414, -.252, .0405, -.171, .018, 0,
  ]);
  static final _pnTuftSlits = Path()
    ..moveTo(-.056, -.207)
    ..lineTo(-.03, -.09)
    ..moveTo(-.018, -.225)
    ..lineTo(-.01, -.09)
    ..moveTo(.018, -.225)
    ..lineTo(.01, -.09)
    ..moveTo(.056, -.207)
    ..lineTo(.03, -.09);

  /// The two loose ends of twine at the top knot.
  static final _pnTails = Path()
    ..moveTo(.018, -.95)
    ..cubicTo(.09, -.93, .125, -.86, .105, -.79)
    ..moveTo(-.018, -.95)
    ..cubicTo(-.08, -.92, -.11, -.87, -.095, -.82);

  /// One rope segment in unit space: [0, 1] along its length, one wide.
  static const _pnRopeBox = Rect.fromLTRB(-.5, 0, .5, 1);
  static const _pnRopeLit = Rect.fromLTRB(-.5, 0, -.12, 1);
  static const _pnRopeShade = Rect.fromLTRB(.22, 0, .5, 1);
  static final _pnTwist = () {
    final path = Path();
    for (var i = 0; i < 13; i++) {
      final y = .012 + i * .0715;
      path
        ..moveTo(-.5, y + .05)
        ..lineTo(.5, y)
        ..lineTo(.5, y + .03)
        ..lineTo(-.5, y + .08)
        ..close();
    }
    return path;
  }();

  /// Ground shadows in viewport heights from a post's foot, thrown right by
  /// the low sun: one post, and the beam's shadow joining the two posts'.
  static final _pnPostShade = Sketch.poly(const [-.012, .003, .185, .045, .205, .06, .012, .014]);
  static final _pnBeamShade = Sketch.poly(const [.145, .046, .715, .046, .728, .06, .158, .06]);

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    final h = f.h;
    if (d == Depth.far) {
      // Popocatépetl breathes a slow plume that leans toward the sun on the wind.
      _mtnPlume(c, Offset(_popoX(f.w), h * _popoTop), h, f.clock);
      return;
    }
    if (d != Depth.near) return;
    _mgDrift(c, f, copy);
    final span = period(d) * h;
    _pnStar(c, _pnPivot(span, h), h, f.clock, f.reducedMotion, copy);
  }

  /// The knot on the beam that the piñata's rope swings from.
  Offset _pnPivot(double span, double h) => Offset(span * .48, _beamY(span * .48, h) + h * .013);

  /// One rope segment from [a] to [b], [w] pixels wide, twisted like twine.
  static void _pnRopeSeg(Canvas c, Offset a, Offset b, double w) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final n = math.sqrt(dx * dx + dy * dy);
    if (n < .5) return;
    c.save();
    c.translate(a.dx, a.dy);
    c.rotate(math.atan2(-dx, dy));
    c.scale(w, n);
    c.drawRect(_pnRopeBox, _pnFill..color = _pnRopeMid);
    c.drawRect(_pnRopeLit, _pnFill..color = _pnRopeHi);
    c.drawRect(_pnRopeShade, _pnFill..color = _pnRopeLo);
    c.drawPath(_pnTwist, _pnFill..color = _pnRopeGroove);
    c.restore();
  }

  /// Twine wrapped twice round the top point.
  static final _pnTwine = Sketch.poly(const [-.04, -.895, .04, -.915, .04, -.885, -.04, -.865])
    ..addPath(Sketch.poly(const [-.05, -.85, .05, -.87, .05, -.84, -.05, -.82]), Offset.zero);
  static final _pnTwineShade = _pnTwine.shift(const Offset(0, .014));

  /// The swinging piñata: a taut twisted rope, then the star hung by its top
  /// point. The body trails the rope, its streamers trail the body, and every
  /// point is lit by the same low sun whichever way the swing turns it.
  static void _pnStar(Canvas c, Offset pivot, double h, double t, bool still, int copy) {
    final r = _pnRadius(h);
    final (tip, centre) = _pnHang(pivot, h, t);
    final s = _pnSwing(t), theta = -_pnSwing(t - .12);
    final rate = still ? 0.0 : _pnRate(t);
    final shift = copy.abs();

    // The rope bows a hair against its motion and hangs from a small knot.
    final rw = math.max(2.2, h * .0042);
    final mid = Offset.lerp(pivot, tip, .5)! + Offset(math.cos(s), -math.sin(s)) * (-rate * h * .012);
    _pnRopeSeg(c, pivot, mid, rw);
    _pnRopeSeg(c, mid, tip, rw);
    c.drawCircle(pivot, rw * .9, _pnFill..color = _pnRopeMid);
    c.drawCircle(pivot + Offset(-rw * .25, -rw * .25), rw * .38, _pnFill..color = _pnRopeHi);

    // The star turns slowly on its twisted rope, narrowing a little as it goes.
    final twist = .9 + .1 * math.cos(1.1 * math.sin(t * .6 + .4));
    c.save();
    c.translate(centre.dx, centre.dy);
    c.save();
    c.rotate(theta);
    c.scale(r * twist, r);
    _pnLine
      ..strokeWidth = .02
      ..color = _pnInk;
    // Seven cones, each fringed in three layers laid from the tip down so
    // every row overlaps the one above, with a seam up the middle. The half
    // turned toward the sun takes a warm veil and the other a cool one.
    for (var k = 0; k < 7; k++) {
      final (paper, pale, deep, pop) = _pnPalette[(k + shift) % 7];
      final a = k * math.pi * 2 / 7;
      final w = math.cos(theta + a - .607);
      final q = (w.abs() * 8).round();
      c.save();
      c.rotate(a);
      c.drawPath(_cone, _pnFill..color = deep);
      c.drawPath(_pnCap, _pnFill..color = pop);
      c.drawPath(_pnShadM, _pnFill..color = _pnInk);
      c.drawPath(_pnBandM, _pnFill..color = paper);
      c.drawPath(_pnShadB, _pnFill..color = _pnInk);
      c.drawPath(_pnBandB, _pnFill..color = pale);
      c.drawPath(w >= 0 ? _pnHalfL : _pnHalfR, _pnFill..color = _pnLit[q]);
      c.drawPath(w >= 0 ? _pnHalfR : _pnHalfL, _pnFill..color = _pnShade[q]);
      c.drawPath(_pnAxis, _pnLine);
      c.restore();
    }
    // The papier-mâché body: two collars of fringe round a foil medallion.
    c.drawCircle(Offset.zero, .42, _pnFill..color = _pnCore);
    c.save();
    c.scale(1.06, 1.06);
    c.drawPath(_pnRingA, _pnFill..color = _pnInk);
    c.restore();
    c.drawPath(_pnRingA, _pnFill..color = _pnCream);
    c.save();
    c.scale(1.08, 1.08);
    c.drawPath(_pnRingB, _pnFill..color = _pnInk);
    c.restore();
    c.drawPath(_pnRingB, _pnFill..color = _pnRose);
    c.drawCircle(Offset.zero, .158, _pnFill..color = _pnRim);
    c.drawCircle(Offset.zero, .14, _pnFill..color = _pnFoil);
    c.save();
    c.translate(.008, .008);
    c.drawPath(_pnEmboss, _pnFill..color = _pnRim);
    c.restore();
    c.drawPath(_pnEmboss, _pnFill..color = const Color(0xffffe58a));
    // A tassel at every tip: gravity bends it toward the ground, the swing
    // drags it behind, and the breeze flutters it.
    _pnLine
      ..strokeWidth = .012
      ..color = _pnInk;
    for (var k = 1; k < 7; k++) {
      final i = (k + shift) % 7;
      final a = k * math.pi * 2 / 7;
      final psi = theta + a;
      final bend =
          .75 * math.sin(psi) -
          .55 * rate * math.cos(psi) +
          .06 * math.sin(t * 6.3 + k * 2.1) +
          .03 * math.sin(t * 11 + k * 3.7);
      c.save();
      c.rotate(a);
      c.translate(0, -.97);
      c.rotate(bend);
      c.drawPath(_pnTuftSide, _pnFill..color = _pnPalette[i].$4);
      c.drawPath(_pnTuftMid, _pnFill..color = _pnTint[i]);
      c.drawPath(_pnTuftSlits, _pnLine);
      c.restore();
    }
    // The rope is tied off round the top point: twine, a knot, loose ends.
    c.drawPath(_pnTwineShade, _pnFill..color = _pnInk);
    c.drawPath(_pnTwine, _pnFill..color = _pnRopeMid);
    c.drawCircle(const Offset(0, -.975), .058, _pnFill..color = _pnRopeLo);
    c.drawCircle(const Offset(-.006, -.981), .05, _pnFill..color = _pnRopeMid);
    c.drawCircle(const Offset(-.02, -.995), .02, _pnFill..color = _pnRopeHi);
    _pnLine
      ..strokeWidth = .024
      ..color = _pnRopeMid;
    c.drawPath(_pnTails, _pnLine);
    c.restore();
    // Light and shine stay put in the world while the star turns under them.
    c.scale(r, r);
    c.drawPath(_pnLuneShade, _pnFill..color = const Color(0x502a1450));
    c.drawPath(_pnLuneLit, _pnFill..color = const Color(0x50ffd68a));
    c.save();
    c.translate(-.02 + s * .15, -.015);
    c.drawPath(_pnStreak, _pnFill..color = const Color(0x8cffffff));
    c.restore();
    c.drawOval(const Rect.fromLTRB(-.085, -.09, -.04, -.062), _pnFill..color = const Color(0xd8ffffff));
    c.restore();
  }

  /// The rustic frame: braces, two lashed posts and a log crossbeam, with the
  /// wraps of rope that hold the piñata's knot. Recorded once with the band.
  void _pnRig(Canvas c, Depth d, double span, double h) {
    const lit = Color(0xffd9924f), rim = Color(0xffefbb78), mid = Color(0xff8c5732);
    const shade = Color(0xff4c2d27), dark = Color(0xff2a181a), back = Color(0xff6a4029);
    const rope = Color(0xffc9a468), ropeHi = Color(0xffefd9a4), ropeLo = Color(0xff7a5a30);
    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0013)
      ..color = Sketch.fade(dark, .6);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, h * .0012)
      ..color = Sketch.fade(dark, .42);
    void quad(List<double> xy, Color color) => c.drawPath(Sketch.poly(xy), fill..color = color);

    final px = span * .48;
    final beam = _beamY(px, h);
    final xs = [span * .4, span * .56];
    final bt = h * .0095;
    final top = beam - bt, bottom = beam + bt;

    // Braces climb from each post to the underside of the beam.
    for (var i = 0; i < 2; i++) {
      final dir = i == 0 ? 1.0 : -1.0;
      final p = Offset(xs[i] + dir * h * .004, beam + h * .13);
      final q = Offset(xs[i] + dir * h * .11, bottom - h * .002);
      final v = q - p;
      var n = Offset(v.dy, -v.dx) / v.distance * (h * .0058);
      if (n.dy > 0) n = -n;
      final body = Sketch.poly([
        p.dx + n.dx, p.dy + n.dy, q.dx + n.dx, q.dy + n.dy, //
        q.dx - n.dx, q.dy - n.dy, p.dx - n.dx, p.dy - n.dy,
      ]);
      c.drawPath(body, fill..color = back);
      quad([
        p.dx + n.dx, p.dy + n.dy, q.dx + n.dx, q.dy + n.dy, //
        q.dx + n.dx * .3, q.dy + n.dy * .3, p.dx + n.dx * .3, p.dy + n.dy * .3,
      ], lit);
      quad([
        p.dx - n.dx, p.dy - n.dy, q.dx - n.dx, q.dy - n.dy, //
        q.dx - n.dx * .35, q.dy - n.dy * .35, p.dx - n.dx * .35, p.dy - n.dy * .35,
      ], shade);
      c.drawPath(body, edge);
      for (final u in const [.16, .84]) {
        final nail = Offset.lerp(p, q, u)!;
        c.drawCircle(nail, h * .0021, fill..color = dark);
        c.drawCircle(nail + Offset(-h * .0005, -h * .0006), h * .0008, fill..color = rim);
      }
    }

    // Posts: tapered, lit on the left, with grain, a knot and a crack apiece.
    for (var i = 0; i < 2; i++) {
      final x = xs[i];
      final base = _y(d, x, h) + h * .012;
      final ptop = top - h * .006;
      final wt = h * .0105, wb = h * .0135;
      double wAt(double y) => wt + (wb - wt) * (y - ptop) / (base - ptop);
      final body = Sketch.poly([x - wt, ptop, x + wt, ptop, x + wb, base, x - wb, base]);
      c.drawPath(body, fill..color = mid);
      quad([x + wt * .22, ptop, x + wt, ptop, x + wb, base, x + wb * .22, base], shade);
      quad([x - wt, ptop, x - wt * .5, ptop, x - wb * .5, base, x - wb, base], lit);
      quad([x - wt, ptop, x - wt * .82, ptop, x - wb * .82, base, x - wb, base], rim);
      final g = Path();
      for (var j = 0; j < 5; j++) {
        final f = -.66 + j * .33;
        var y = ptop + h * (.012 + .07 * Sketch.hash(i * 50 + j));
        var n = 0;
        while (y < base - h * .06) {
          final y1 = math.min(y + h * (.05 + .09 * Sketch.hash(i * 97 + j * 13 + n)), base - h * .05);
          final ym = (y + y1) / 2;
          final bend = (Sketch.hash(i * 71 + j * 19 + n) - .5) * .3;
          g
            ..moveTo(x + f * wAt(y), y)
            ..quadraticBezierTo(x + (f + bend) * wAt(ym), ym, x + f * wAt(y1), y1);
          y = y1 + h * (.018 + .05 * Sketch.hash(i * 89 + j * 17 + n + 50));
          n++;
        }
      }
      c.drawPath(g, grain);
      final ky = ptop + (base - ptop) * (i == 0 ? .34 : .5);
      final kx = x + wAt(ky) * (i == 0 ? -.1 : .2);
      c.drawOval(Rect.fromCenter(center: Offset(kx, ky), width: h * .014, height: h * .024), grain);
      c.drawOval(Rect.fromCenter(center: Offset(kx, ky), width: h * .0095, height: h * .015), fill..color = dark);
      c.drawOval(
        Rect.fromCenter(center: Offset(kx - h * .0005, ky - h * .0008), width: h * .005, height: h * .009),
        fill..color = const Color(0xff6f4025),
      );
      final cy = ptop + (base - ptop) * (i == 0 ? .62 : .28);
      final cw = wAt(cy);
      c.drawPath(
        Path()
          ..moveTo(x + cw * .45, cy)
          ..lineTo(x + cw * .38, cy + h * .018)
          ..lineTo(x + cw * .5, cy + h * .034)
          ..lineTo(x + cw * .42, cy + h * .056),
        edge,
      );
      quad([x - wt, ptop, x + wt, ptop, x + wt, ptop + h * .0022, x - wt, ptop + h * .0022], rim);
      c.drawPath(body, edge);
    }

    // The crossbeam: a log, lit along its top and dark underneath.
    final left = xs[0] - h * .05, right = xs[1] + h * .05;
    final log = RRect.fromLTRBR(left, top, right, bottom, Radius.circular(h * .0035));
    c.drawRRect(log, fill..color = mid);
    final l0 = left + h * .003, r0 = right - h * .003;
    quad([l0, beam + bt * .2, r0, beam + bt * .2, r0, bottom - h * .0008, l0, bottom - h * .0008], Sketch.fade(shade, .8));
    quad([l0, top + h * .0008, r0, top + h * .0008, r0, top + bt * .36, l0, top + bt * .36], lit);
    quad([l0, top + h * .0008, r0, top + h * .0008, r0, top + bt * .12, l0, top + bt * .12], rim);
    final bg = Path();
    for (var j = 0; j < 3; j++) {
      final gy = beam + bt * (-.5 + j * .5);
      var x = left + h * (.01 + .05 * Sketch.hash(300 + j));
      var n = 0;
      while (x < right - h * .05) {
        final x1 = math.min(x + h * (.06 + .12 * Sketch.hash(310 + j * 13 + n)), right - h * .03);
        final wob = (Sketch.hash(330 + j * 7 + n) - .5) * bt * .3;
        bg
          ..moveTo(x, gy)
          ..quadraticBezierTo((x + x1) / 2, gy + wob, x1, gy + wob * .3);
        x = x1 + h * (.02 + .06 * Sketch.hash(350 + j * 11 + n));
        n++;
      }
    }
    c.drawPath(bg, grain);
    for (final (fx, fy) in const [(.435, -.2), (.535, .32)]) {
      final at = Offset(span * fx, beam + bt * fy);
      c.drawOval(Rect.fromCenter(center: at, width: h * .02, height: h * .0125), grain);
      c.drawOval(Rect.fromCenter(center: at, width: h * .0125, height: h * .0072), fill..color = dark);
      c.drawOval(
        Rect.fromCenter(center: at + Offset(-h * .0008, -h * .0006), width: h * .0065, height: h * .0035),
        fill..color = const Color(0xff6f4025),
      );
    }
    c.drawRRect(log, edge);

    // Rope: slanted wraps round the beam, and four turns of lashing on the
    // post below where each one meets it.
    void wrapAt(double cx) {
      final wd = h * .0026, sl = h * .0042, y0 = top - h * .0022, y1 = bottom + h * .0022, dx = h * .0012;
      quad([cx - wd + dx, y0, cx + wd + dx, y0, cx + wd + sl + dx, y1, cx - wd + sl + dx, y1], Sketch.fade(dark, .55));
      quad([cx - wd, y0, cx + wd, y0, cx + wd + sl, y1, cx - wd + sl, y1], rope);
      quad([cx - wd, y0, cx - wd * .2, y0, cx - wd * .2 + sl, y1, cx - wd + sl, y1], ropeHi);
      quad([cx + wd * .45, y0, cx + wd, y0, cx + wd + sl, y1, cx + wd * .45 + sl, y1], ropeLo);
    }

    void lash(double cx, double y) {
      final half = h * .0165, th = h * .0052, sl = h * .0026, dy = h * .0018;
      final u = cx - half + 2 * half * .66;
      quad([cx - half, y + dy, cx + half, y + sl + dy, cx + half, y + sl + th + dy, cx - half, y + th + dy], Sketch.fade(dark, .6));
      quad([cx - half, y, cx + half, y + sl, cx + half, y + sl + th, cx - half, y + th], rope);
      quad([cx - half, y, cx + half, y + sl, cx + half, y + sl + th * .32, cx - half, y + th * .32], ropeHi);
      quad([u, y + sl * .66, cx + half, y + sl, cx + half, y + sl + th, u, y + sl * .66 + th], ropeLo);
    }

    for (final x in xs) {
      for (final u in const [-1.0, 0.0, 1.0]) {
        wrapAt(x + u * h * .0085);
      }
      for (var j = 0; j < 4; j++) {
        lash(x, bottom + h * (.0035 + .0068 * j));
      }
    }
    for (final u in const [-.8, 0.0, .8]) {
      wrapAt(px + u * h * .0062);
    }
    // A short loose tail of rope beside the knot.
    c.drawPath(
      Path()
        ..moveTo(px + h * .004, bottom + h * .002)
        ..cubicTo(px + h * .012, bottom + h * .01, px + h * .006, bottom + h * .022, px + h * .013, bottom + h * .031),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1, h * .003)
        ..color = ropeLo,
    );
  }

  /// One post's shadow, and the beam's when [beam] is set, thrown to the right
  /// from the post's foot at ([x], [y]): a soft edge under a darker core.
  static void _pnCast(Canvas c, double x, double y, double h, bool beam, Color soft, Color hard) {
    c.save();
    c.translate(x, y);
    c.scale(h, h);
    _pnLine
      ..strokeWidth = .01
      ..color = soft;
    c.drawPath(_pnPostShade, _pnLine);
    c.drawPath(_pnPostShade, _pnFill..color = hard);
    if (beam) {
      c.drawPath(_pnBeamShade, _pnLine);
      c.drawPath(_pnBeamShade, _pnFill..color = hard);
    }
    c.restore();
  }

  /// Shadows on the near ground, painted over the ridge: the two posts, the
  /// beam and the swinging piñata, all thrown to the right by the low sun.
  void _pnGround(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final h = f.h, span = period(Depth.near) * h;
    final soft = Sketch.fade(_pnGloom, .16 * presence), hard = Sketch.fade(_pnGloom, .32 * presence);
    final x0 = span * .4, x1 = span * .56;
    _pnCast(c, x0, _y(Depth.near, x0, h), h, true, soft, hard);
    _pnCast(c, x1, _y(Depth.near, x1, h), h, false, soft, hard);
    final (_, centre) = _pnHang(_pnPivot(span, h), h, f.clock);
    final gy = _y(Depth.near, centre.dx, h);
    final lift = math.max(0.0, gy - centre.dy);
    final at = Offset(centre.dx + lift * .63, gy + h * .008 + lift * .14);
    final r = _pnRadius(h);
    c.drawOval(Rect.fromCenter(center: at, width: r * 2.8, height: h * .03), _pnFill..color = soft);
    c.drawOval(Rect.fromCenter(center: at, width: r * 2.1, height: h * .018), _pnFill..color = hard);
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    if (d == Depth.near) _pnGround(c, f, presence);
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .68), width: f.w * 1.3 + h * .6, height: h * .08),
          const Color(0xffffc9a8),
          .6 * presence,
        );
      case Depth.mid:
        // Lamps and cookfires along the hill lanes come on with the dusk.
        final halo = Paint()..color = Sketch.fade(const Color(0xffffb35a), .22 * presence);
        final glow = Paint()..color = Sketch.fade(const Color(0xffffd36b), .85 * presence);
        for (var i = 0; i < 24; i++) {
          final x = (f.w + h * _reach) * Sketch.hash(i + 740) - h * .1;
          final y = (ridge(Depth.mid, x / h, 0) + .012 + .025 * Sketch.hash(i + 741)) * h;
          c.drawCircle(Offset(x, y), h * .009, halo);
          c.drawCircle(Offset(x, y), h * .0026, glow);
        }
      case Depth.low:
        break;
      case Depth.near:
        _mgGroundOverlay(c, f, presence);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    _skyGlow(c, f, presence);
    _skyClouds(c, f, presence);
    _skySwallows(c, f, presence);
    _papel(c, f, presence);
  }

  // ------------------------------------------------------------ Sunset sky --
  // Every gradient below lives in unit space and is scaled onto the sky, so the
  // shaders are built once. A paint's alpha fades the whole gradient.

  static Paint _skyAlpha(Paint p, double a) => p..color = Color.fromRGBO(255, 255, 255, a.clamp(0.0, 1.0));

  static final _skyTopPaint = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, 1),
      const [Color(0x8c2a1a5a), Color(0x2e2a1a5a), Color(0x002a1a5a)],
      const [0, .55, 1],
    );
  static final _skyBandPaint = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, 1),
      const [Color(0x00ff8f7a), Color(0x42ff8f5a), Color(0x80ffc27a), Color(0x8cffd9a0)],
      const [0, .42, .7, 1],
    );
  static final _skyGlowPaint = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0x9effe7a8), Color(0x4dffc070), Color(0x00ff9050)],
      const [0, .35, 1],
    );
  static final _skyCorePaint = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0xfffffbe6), Color(0xffffe6a8), Color(0xffffc07a), Color(0x00ffc07a)],
      const [0, .5, .97, 1],
    );
  static final _skyRay = Path()
    ..moveTo(0, 0)
    ..lineTo(-1, -1)
    ..lineTo(1, -1)
    ..close();
  static final _skyRayPaint = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, -1),
      const [Color(0x2affe2a0), Color(0x14ffe2a0), Color(0x06ffe2a0), Color(0x00ffe2a0)],
      const [0, .35, .7, 1],
    );

  /// Crepuscular rays fanning from the sun: (angle from vertical, half width, strength).
  static const _skyRays = [
    (-1.15, .05, .5),
    (-.85, .03, .7),
    (-.55, .045, .9),
    (-.28, .03, .6),
    (-.05, .06, .8),
    (.2, .035, .7),
    (.45, .04, .55),
    (.75, .03, .75),
    (1.05, .05, .5),
  ];

  /// Indigo overhead, a golden band above the range, the sun's warmth along
  /// the horizon, a hot core in its disc and soft rays that the range cuts off.
  void _skyGlow(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final sx = light.at.dx * w, sy = light.at.dy * h, r = light.radius * h;
    c.save();
    c.scale(w, h * .4);
    c.drawRect(const Rect.fromLTWH(0, 0, 1, 1), _skyAlpha(_skyTopPaint, presence));
    c.restore();
    c.save();
    c.translate(0, h * .26);
    c.scale(w, h * .4);
    c.drawRect(const Rect.fromLTWH(0, 0, 1, 1), _skyAlpha(_skyBandPaint, presence));
    c.restore();
    c.save();
    c.translate(sx, h * .54);
    c.scale(h * .62, h * .24);
    c.drawCircle(Offset.zero, 1, _skyAlpha(_skyGlowPaint, presence));
    c.restore();
    // These follow the sun itself, which moves during a crossing, so they
    // vanish faster than the rest of the sky.
    final near = presence * presence * presence;
    if (near <= .001) return;
    c.save();
    c.translate(sx, sy);
    c.scale(r * 1.02, r * 1.02);
    c.drawCircle(Offset.zero, 1, _skyAlpha(_skyCorePaint, near));
    c.restore();
    for (final (i, (angle, hw, strength)) in _skyRays.indexed) {
      final pulse = .7 + .3 * math.sin(f.clock * .25 + i * 1.7);
      c.save();
      c.translate(sx, sy);
      c.rotate(angle + math.sin(f.clock * .12 + i) * .02);
      c.scale(h * .9 * hw, h * .9);
      c.drawPath(_skyRay, _skyAlpha(_skyRayPaint, near * strength * pulse));
      c.restore();
    }
  }

  // Streaks share one lens: a domed top and a flat, sunlit belly. Gradients run
  // from the top (y = -.75) to the belly (y = .18) in the lens's own units.
  static final _skyLens = Path()
    ..moveTo(-1, 0)
    ..quadraticBezierTo(-.25, -1.5, 1, 0)
    ..quadraticBezierTo(.1, .35, -1, 0)
    ..close();
  static final _skyRimLens = Path()
    ..moveTo(-.86, .02)
    ..quadraticBezierTo(0, -.42, .86, .02)
    ..quadraticBezierTo(.1, .33, -.86, .02)
    ..close();

  static Paint _skyStreak(List<Color> colors, [List<double>? stops]) => Paint()
    ..shader = Gradient.linear(const Offset(0, -.75), const Offset(0, .18), colors, stops);

  static final _skyWispPaint = _skyStreak(const [Color(0x1affd6e6), Color(0x8cffe2d0)]);
  static final _skyBodyPaint = _skyStreak(const [Color(0x4d9a5a9e), Color(0x99e8708a), Color(0xb8ff9a7a)], const [0, .55, 1]);
  static final _skyRimPaint = _skyStreak(const [Color(0x00ffb060), Color(0x8cffc878), Color(0xf2ffe4a0)], const [0, .5, 1]);
  static final _skyDuskPaint = _skyStreak(const [Color(0xd13a2350), Color(0xd17a3a60)]);
  static final _skyDuskRimPaint = _skyStreak(const [Color(0x00ffa858), Color(0x99ffc070), Color(0xffffe0a0)], const [0, .6, 1]);

  /// Drifting streaks: (x, y, half length, thickness, drift speed, kind). Kind 0
  /// is a pale high wisp, 1 a rose streak with a gold belly and 2 a dark bar
  /// low in the glow whose lower edge blazes.
  static const _skyStreaks = [
    (.05, .12, .5, .016, .0044, 0),
    (.72, .205, .55, .018, .0036, 0),
    (.36, .265, .42, .014, .005, 0),
    (.12, .335, .42, .05, .007, 1),
    (.82, .365, .52, .06, .006, 1),
    (.5, .405, .34, .045, .008, 1),
    (.28, .445, .4, .022, .01, 2),
    (.88, .462, .34, .018, .011, 2),
    (.6, .478, .3, .014, .009, 2),
  ];

  static void _skyLayer(Canvas c, Path lens, double sx, double sy, Paint paint, double alpha) {
    c.save();
    c.scale(sx, sy);
    c.drawPath(lens, _skyAlpha(paint, alpha));
    c.restore();
  }

  void _skyClouds(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final sunX = light.at.dx * w;
    for (final (i, (fx, fy, len, thick, speed, kind)) in _skyStreaks.indexed) {
      final half = len * h, t = thick * h;
      final span = w + 2 * half + h * .1;
      final x = (w * fx - f.clock * h * speed) % span - half - h * .05;
      // The nearer a streak drifts to the sun, the brighter its belly burns.
      final near = (1 - (x - sunX).abs() / (w * .6 + h * .3)).clamp(0.0, 1.0);
      final sx = i.isOdd ? -half : half;
      c.save();
      c.translate(x, h * fy);
      c.rotate((Sketch.hash(i + 760) - .5) * .05);
      switch (kind) {
        case 0:
          _skyLayer(c, _skyLens, sx, t, _skyWispPaint, presence);
        case 1:
          _skyLayer(c, _skyLens, sx * 1.12, t * 1.6, _skyBodyPaint, presence * .3);
          _skyLayer(c, _skyLens, sx, t, _skyBodyPaint, presence);
          _skyLayer(c, _skyRimLens, sx, t, _skyRimPaint, presence * (.35 + .65 * near));
          c.translate(sx * .3, t * 1.5);
          _skyLayer(c, _skyLens, sx * .55, t * .34, _skyBodyPaint, presence);
          _skyLayer(c, _skyRimLens, sx * .55, t * .34, _skyRimPaint, presence * (.35 + .65 * near));
        default:
          _skyLayer(c, _skyLens, sx, t, _skyDuskPaint, presence);
          _skyLayer(c, _skyRimLens, sx, t, _skyDuskRimPaint, presence * (.45 + .55 * near));
          c.translate(-sx * .35, t * 1.7);
          _skyLayer(c, _skyLens, sx * .5, t * .4, _skyDuskPaint, presence);
          _skyLayer(c, _skyRimLens, sx * .5, t * .4, _skyDuskRimPaint, presence * (.45 + .55 * near));
      }
      c.restore();
    }
  }

  // A barn swallow faces right in unit space (body length one): a slim body,
  // a long forked tail and swept, pointed wings hinged at the shoulder.
  static final _skySwBody = Path()
    ..moveTo(.5, .028)
    ..lineTo(.42, -.004)
    ..cubicTo(.4, -.06, .3, -.078, .22, -.062)
    ..cubicTo(.1, -.082, -.1, -.058, -.3, -.022)
    ..lineTo(-.44, -.006)
    ..lineTo(-.44, .032)
    ..cubicTo(-.28, .07, -.05, .098, .12, .088)
    ..cubicTo(.26, .082, .37, .062, .42, .046)
    ..close();
  static final _skySwTail = Path()
    ..moveTo(-.38, -.02)
    ..lineTo(-1.06, -.092)
    ..lineTo(-.74, .012)
    ..lineTo(-1.06, .122)
    ..lineTo(-.38, .042)
    ..close();
  static final _skySwWing = Path()
    ..moveTo(.13, -.03)
    ..cubicTo(.12, -.3, -.02, -.68, -.42, -1.04)
    ..cubicTo(-.22, -.62, -.16, -.32, -.19, -.02)
    ..close();
  static final _skySwPaint = Paint();

  /// The flock: (x, y, size, speed). Smaller ones are farther and paler.
  static const _skyBirds = [
    (.3, .335, .0155, 1.0),
    (.48, .395, .012, .9),
    (.62, .3, .0135, 1.1),
    (.74, .43, .01, .8),
    (.14, .42, .0095, .85),
  ];

  void _skySwallows(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    for (final (i, (fx, fy, size, speed)) in _skyBirds.indexed) {
      final x = (w * fx - t * h * .035 * speed) % (w + h * .6) - h * .3;
      final a1 = t * .6 + i * 2, a2 = t * 1.3 + i;
      final y = h * fy + math.sin(a1) * h * .012 + math.sin(a2) * h * .004;
      // The body pitches with its climb; wingbeats come in bursts between glides.
      final climb = (.6 * .012 * math.cos(a1) + 1.3 * .004 * math.cos(a2)) * h;
      final pitch = math.atan2(-climb, h * .035 * speed);
      final burst = (math.sin(t * .45 + i * 2.1) * 1.6 + .5).clamp(0.0, 1.0);
      final flap = burst * math.sin(t * (6.5 + i % 3) + i * 2);
      final far = ((.0155 - size) / .007).clamp(0.0, 1.0);
      final dark = Sketch.mix(const Color(0xff2c1a36), const Color(0xffb0607a), far * .55);
      _skySwallow(
        c,
        Offset(x, y),
        h * size * 1.6,
        flap,
        pitch,
        Sketch.fade(dark, presence),
        Sketch.fade(Sketch.mix(dark, const Color(0xffd88a9a), .3), presence),
      );
    }
  }

  static void _skySwallow(Canvas c, Offset p, double u, double flap, double pitch, Color dark, Color pale) {
    final beat = -.72 + flap * .9;
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(pitch);
    c.scale(-u, u);
    // The far wing trails a little behind and paler; the near wing is darkest.
    c.save();
    c.translate(.1, -.035);
    c.rotate(beat * .8 - .05);
    c.scale(.88, .88);
    c.drawPath(_skySwWing, _skySwPaint..color = pale);
    c.restore();
    _skySwPaint.color = dark;
    c.drawPath(_skySwTail, _skySwPaint);
    c.drawPath(_skySwBody, _skySwPaint);
    c.translate(.1, -.035);
    c.rotate(beat);
    c.drawPath(_skySwWing, _skySwPaint);
    c.restore();
  }

  // -------------------------------------------------------- Papel picado --
  // A flag is one unit wide, hung from y = 0.04 (the string, inside its folded
  // hem). Its cut-outs are holes in a single even-odd path, so the sunset shows
  // through them, and the paths are built once per design.

  /// The town's pastel washes plus green, blue, cream and magenta.
  static const _ppTissue = [
    ..._wash,
    Color(0xff3fc46e),
    Color(0xff3f93ea),
    Color(0xfffff0d8),
    Color(0xffd83aa8),
  ];
  static const _ppBase = .72, _ppCy = .41;
  static const _ppEdge = Rect.fromLTRB(-.5, .09, -.482, .7);
  static const _ppHem = Rect.fromLTRB(-.5, -.012, .5, .085);
  static const _ppFold = Rect.fromLTRB(-.5, .085, .5, .097);
  static const _ppPeg = Rect.fromLTRB(-.034, -.05, .034, .105);
  static const _ppPegLit = Rect.fromLTRB(-.034, -.05, -.01, .105);
  static const _ppPegPin = Rect.fromLTRB(-.034, .012, .034, .024);

  /// Six designs: flower, dove, calavera, sun, butterfly and concentric hearts,
  /// each with its own lower edge (scallops, points or fringe) and top border.
  static final _ppFlags = [for (var k = 0; k < 6; k++) _ppBuild(k)];
  static final _ppFill = Paint();
  static final _ppCord = Path();
  static final _ppCordPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static void _ppDot(Path p, double x, double y, double r) => p.addOval(Rect.fromLTRB(x - r, y - r, x + r, y + r));

  static void _ppEllipse(Path p, double x, double y, double rx, double ry) =>
      p.addOval(Rect.fromLTRB(x - rx, y - ry, x + rx, y + ry));

  static void _ppPoly(Path p, List<double> xy) {
    p.moveTo(xy[0], xy[1]);
    for (var i = 2; i + 1 < xy.length; i += 2) {
      p.lineTo(xy[i], xy[i + 1]);
    }
    p.close();
  }

  /// A pointed petal about (cx, cy) from radius r0 to r1 along [angle].
  static void _ppPetal(Path p, double cx, double cy, double angle, double r0, double r1, double half) {
    final ca = math.cos(angle), sa = math.sin(angle);
    double px(double u, double v) => cx + ca * u - sa * v;
    double py(double u, double v) => cy + sa * u + ca * v;
    final len = r1 - r0;
    final a = r0 + len * .15, b = r0 + len * .8;
    p
      ..moveTo(px(r0, 0), py(r0, 0))
      ..cubicTo(px(a, -half * 1.5), py(a, -half * 1.5), px(b, -half * 1.2), py(b, -half * 1.2), px(r1, 0), py(r1, 0))
      ..cubicTo(px(b, half * 1.2), py(b, half * 1.2), px(a, half * 1.5), py(a, half * 1.5), px(r0, 0), py(r0, 0))
      ..close();
  }

  /// A slim lens along [angle]: a paper rib inside a cut.
  static void _ppLens(Path p, double cx, double cy, double angle, double r0, double r1, double half) {
    final ca = math.cos(angle), sa = math.sin(angle);
    final mid = (r0 + r1) / 2;
    p
      ..moveTo(cx + ca * r0, cy + sa * r0)
      ..quadraticBezierTo(cx + ca * mid + sa * half * 2, cy + sa * mid - ca * half * 2, cx + ca * r1, cy + sa * r1)
      ..quadraticBezierTo(cx + ca * mid - sa * half * 2, cy + sa * mid + ca * half * 2, cx + ca * r0, cy + sa * r0)
      ..close();
  }

  static void _ppHeart(Path p, double cx, double cy, double s) {
    p
      ..moveTo(cx, cy + s * .95)
      ..cubicTo(cx - s * .35, cy + s * .62, cx - s * 1.05, cy + s * .25, cx - s, cy - s * .28)
      ..cubicTo(cx - s * .96, cy - s * .78, cx - s * .2, cy - s * .82, cx, cy - s * .32)
      ..cubicTo(cx + s * .2, cy - s * .82, cx + s * .96, cy - s * .78, cx + s, cy - s * .28)
      ..cubicTo(cx + s * 1.05, cy + s * .25, cx + s * .35, cy + s * .62, cx, cy + s * .95)
      ..close();
  }

  static Path _ppBuild(int kind) {
    final p = Path()..fillType = PathFillType.evenOdd;
    final n = kind % 3 == 2 ? 11 : 8;
    // The sheet, with its cut lower edge traced right to left.
    p
      ..moveTo(-.5, -.02)
      ..lineTo(.5, -.02)
      ..lineTo(.5, _ppBase);
    for (var i = 0; i < n; i++) {
      final x0 = .5 - i / n, x1 = .5 - (i + 1) / n, xm = (x0 + x1) / 2;
      switch (kind % 3) {
        case 0:
          p.quadraticBezierTo(xm, _ppBase + .1, x1, _ppBase);
        case 1:
          p
            ..lineTo(xm, _ppBase + .07)
            ..lineTo(x1, _ppBase);
        default:
          p
            ..lineTo(x0 - .012, _ppBase + .085)
            ..lineTo(x1 + .012, _ppBase + .085)
            ..lineTo(x1, _ppBase);
      }
    }
    p.close();
    // A border of bunting under the hem, diamonds down the sides, a row of
    // dots above the lower edge.
    for (var i = 0; i < 9; i++) {
      final x = -.4 + i * .1;
      if (kind.isEven) {
        _ppPoly(p, [x - .034, .118, x + .034, .118, x, .172]);
      } else {
        _ppDot(p, x, .142, .021);
      }
    }
    for (var j = 0; j < 4; j++) {
      final y = .255 + j * .11;
      for (final s in const [-1.0, 1.0]) {
        _ppPoly(p, [s * .445, y - .03, s * .445 + .022, y, s * .445, y + .03, s * .445 - .022, y]);
      }
    }
    for (var i = 0; i < n; i++) {
      _ppDot(p, -.5 + (i + .5) / n, _ppBase - .05, .022);
    }
    final motif = kind % 6;
    final wide = motif == 1 || motif == 4;
    for (final s in const [-1.0, 1.0]) {
      if (!wide) {
        final a = s > 0 ? 0.0 : math.pi;
        _ppPetal(p, s * .245, _ppCy, a, 0, .13, .034);
        _ppLens(p, s * .245, _ppCy, a, .035, .095, .008);
        _ppDot(p, s * .3, _ppCy - .075, .015);
        _ppDot(p, s * .3, _ppCy + .075, .015);
      }
      for (final dy in const [-1.0, 1.0]) {
        if (motif == 4 && dy < 0) continue;
        final cx = s * .335, cy = _ppCy + dy * .185;
        _ppDot(p, cx, cy - .03, .013);
        _ppDot(p, cx + .03, cy, .013);
        _ppDot(p, cx, cy + .03, .013);
        _ppDot(p, cx - .03, cy, .013);
      }
    }
    switch (motif) {
      case 0:
        _ppFlower(p);
      case 1:
        _ppDove(p);
      case 2:
        _ppSkull(p);
      case 3:
        _ppSun(p);
      case 4:
        _ppButterfly(p);
      default:
        _ppHeart(p, 0, .41, .195);
        _ppHeart(p, 0, .415, .14);
        _ppHeart(p, 0, .42, .088);
        _ppHeart(p, 0, .425, .04);
    }
    return p;
  }

  /// Cempasuchil: eight petals cut round a ringed heart.
  static void _ppFlower(Path p) {
    for (var a = 0; a < 8; a++) {
      final angle = a * math.pi / 4 - math.pi / 2;
      _ppPetal(p, 0, _ppCy, angle, .075, .19, .038);
      _ppLens(p, 0, _ppCy, angle, .105, .16, .009);
      final mid = angle + math.pi / 8;
      _ppDot(p, math.cos(mid) * .208, _ppCy + math.sin(mid) * .208, .014);
    }
    _ppDot(p, 0, _ppCy, .05);
    _ppDot(p, 0, _ppCy, .025);
  }

  /// A dove in flight: the whole bird is cut away, its wing ribs left in paper.
  static void _ppDove(Path p) {
    p
      ..moveTo(.3, .395)
      ..lineTo(.265, .375)
      ..cubicTo(.25, .34, .21, .325, .175, .345)
      ..cubicTo(.15, .36, .12, .385, .06, .385)
      ..cubicTo(.06, .31, 0, .235, -.135, .2)
      ..quadraticBezierTo(-.13, .245, -.205, .235)
      ..quadraticBezierTo(-.17, .28, -.255, .29)
      ..quadraticBezierTo(-.2, .325, -.265, .352)
      ..quadraticBezierTo(-.2, .38, -.15, .4)
      ..lineTo(-.2, .425)
      ..lineTo(-.315, .445)
      ..quadraticBezierTo(-.26, .46, -.325, .5)
      ..quadraticBezierTo(-.26, .5, -.285, .55)
      ..quadraticBezierTo(-.22, .52, -.15, .505)
      ..cubicTo(-.08, .535, .02, .555, .1, .525)
      ..cubicTo(.17, .5, .23, .47, .265, .42)
      ..lineTo(.28, .405)
      ..close();
    _ppDot(p, .232, .365, .012);
    _ppLens(p, -.02, .35, -2.32, .03, .165, .007);
    _ppLens(p, -.02, .365, -2.62, .03, .16, .007);
    _ppLens(p, -.05, .385, -2.95, .03, .105, .007);
  }

  /// A calavera: the skull is cut away, its ringed eyes, nose, brow diamond and
  /// teeth left in paper.
  static void _ppSkull(Path p) {
    p
      ..moveTo(0, .225)
      ..cubicTo(.09, .225, .15, .28, .15, .36)
      ..cubicTo(.15, .42, .14, .45, .125, .47)
      ..lineTo(.1, .5)
      ..lineTo(.092, .585)
      ..cubicTo(.09, .6, .08, .607, .065, .607)
      ..lineTo(-.065, .607)
      ..cubicTo(-.08, .607, -.09, .6, -.092, .585)
      ..lineTo(-.1, .5)
      ..lineTo(-.125, .47)
      ..cubicTo(-.14, .45, -.15, .42, -.15, .36)
      ..cubicTo(-.15, .28, -.09, .225, 0, .225)
      ..close();
    for (final s in const [-1.0, 1.0]) {
      _ppEllipse(p, s * .066, .385, .047, .052);
      _ppEllipse(p, s * .066, .385, .028, .031);
      _ppEllipse(p, s * .066, .385, .012, .013);
      _ppDot(p, s * .118, .478, .012);
    }
    _ppPoly(p, [0, .43, .026, .485, -.026, .485]);
    _ppPoly(p, [0, .255, .03, .29, 0, .325, -.03, .29]);
    _ppPoly(p, [0, .272, .015, .29, 0, .308, -.015, .29]);
    _ppPoly(p, [-.078, .535, .078, .535, .078, .548, -.078, .548]);
    for (final x in const [-.058, -.02, .02, .058]) {
      _ppPoly(p, [x - .009, .56, x + .009, .56, x + .009, .595, x - .009, .595]);
    }
  }

  /// A sunburst: twelve kites, long and short in turn, round a ringed disc.
  static void _ppSun(Path p) {
    for (var a = 0; a < 12; a++) {
      final angle = a * math.pi / 6 - math.pi / 2;
      final long = a.isEven;
      final r1 = long ? .205 : .15;
      final hw = long ? .026 : .02;
      final rm = .078 + (r1 - .078) * .42;
      final ca = math.cos(angle), sa = math.sin(angle);
      p
        ..moveTo(ca * .078, _ppCy + sa * .078)
        ..lineTo(ca * rm + sa * hw, _ppCy + sa * rm - ca * hw)
        ..lineTo(ca * r1, _ppCy + sa * r1)
        ..lineTo(ca * rm - sa * hw, _ppCy + sa * rm + ca * hw)
        ..close();
      if (long) {
        _ppLens(p, 0, _ppCy, angle, .11, .165, .006);
      } else {
        _ppDot(p, ca * .19, _ppCy + sa * .19, .012);
      }
    }
    _ppDot(p, 0, _ppCy, .05);
    _ppDot(p, 0, _ppCy, .029);
    _ppDot(p, 0, _ppCy, .012);
  }

  /// A butterfly: four wing cuts round a paper body, eye-spots left in paper.
  static void _ppButterfly(Path p) {
    for (final s in const [-1.0, 1.0]) {
      p
        ..moveTo(s * .035, .392)
        ..cubicTo(s * .08, .32, s * .19, .22, s * .31, .22)
        ..cubicTo(s * .36, .26, s * .35, .32, s * .3, .345)
        ..cubicTo(s * .2, .41, s * .1, .405, s * .035, .408)
        ..close()
        ..moveTo(s * .04, .445)
        ..cubicTo(s * .12, .452, s * .2, .44, s * .235, .478)
        ..cubicTo(s * .27, .52, s * .26, .58, s * .19, .612)
        ..cubicTo(s * .1, .6, s * .05, .52, s * .04, .445)
        ..close();
      _ppDot(p, s * .2, .29, .038);
      _ppDot(p, s * .2, .29, .019);
      _ppDot(p, s * .285, .275, .012);
      _ppDot(p, s * .125, .335, .013);
      _ppDot(p, s * .15, .53, .027);
      _ppDot(p, s * .15, .53, .012);
      _ppDot(p, s * .205, .5, .011);
      p
        ..moveTo(s * .012, .335)
        ..quadraticBezierTo(s * .02, .26, s * .075, .21)
        ..quadraticBezierTo(s * .035, .265, s * .012, .335)
        ..close();
    }
  }

  /// Two strings of tissue flags sway in the evening breeze: a gust rolls
  /// along each string so the flags swing in a travelling wave, the hems lag
  /// the strings and every sheet twists a little on its cord. The sunset shows
  /// through the cuts, and the paper warms where the sun is near.
  void _papel(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final sunX = light.at.dx * w;
    // (left y, right y, sag, size, haze): the upper string hangs farther off.
    for (final (index, (yl, yr, sag, scale, haze)) in const [
      (.078, .108, .05, .84, .16),
      (.205, .168, .055, 1.0, 0.0),
    ].indexed) {
      final fw = h * .072 * scale, pitch = fw * 1.075;
      final sagNow = sag * (1 + .05 * math.sin(t * .8 + index * 1.7));
      double yAt(double u) => h * (yl + (yr - yl) * u + sagNow * 4 * u * (1 - u));
      // The cord runs a flag past both edges as one exact parabola.
      final u0 = -pitch / w, u1 = 1 + pitch / w;
      final y0 = yAt(u0), y1 = yAt(u1);
      _ppCord
        ..reset()
        ..moveTo(u0 * w, y0)
        ..quadraticBezierTo(w / 2, 2 * yAt(.5) - (y0 + y1) / 2, u1 * w, y1);
      final cord = math.max(1.0, h * .0026);
      c.drawPath(
        _ppCord,
        _ppCordPaint
          ..strokeWidth = cord
          ..color = Sketch.fade(const Color(0xff4a2f3f), .8 * presence),
      );
      c.save();
      c.translate(0, -math.max(.8, cord * .6));
      c.drawPath(
        _ppCord,
        _ppCordPaint
          ..strokeWidth = math.max(.7, cord * .45)
          ..color = Sketch.fade(const Color(0xffffd796), .28 * presence),
      );
      c.restore();
      final count = (w / pitch).ceil() + 1;
      final start = (w - (count - 1) * pitch) / 2;
      for (var k = 0; k < count; k++) {
        final x = start + k * pitch;
        final u = x / w;
        final ph = t * 1.7 - k * .55 + index * 1.9;
        final gust = .62 + .38 * math.sin(t * .33 - k * .12 + index);
        // The breeze leans every flag a little downwind (left), gusting.
        final swing = .045 + gust * (.085 * math.sin(ph) + .03 * math.sin(ph * 2.3 + 1));
        final lag = -.12 * gust * math.sin(ph - 1.05);
        final twist = math.cos(.5 * gust * math.sin(t * 1.15 - k * .7 + index * 2.1));
        final slope = h * ((yr - yl) + sagNow * 4 * (1 - 2 * u)) / w;
        final near = (x - sunX) / (w * .3);
        final tissue = _ppTissue[(k * 3 + index * 4) % _ppTissue.length];
        final paper = Sketch.mix(
          Sketch.mix(tissue, const Color(0xffffe2b0), .1 * math.exp(-near * near)),
          const Color(0xff8a5a8e),
          haze,
        );
        c.save();
        c.translate(x, yAt(u));
        c.rotate(swing);
        c.skew(lag, slope);
        c.scale(fw * twist, fw);
        c.translate(0, -.04);
        c.drawPath(_ppFlags[(k * 5 + index * 2) % 6], _ppFill..color = Sketch.fade(paper, .93 * presence));
        c.drawRect(_ppEdge, _ppFill..color = Sketch.fade(const Color(0xfffff4dc), .3 * presence));
        c.drawRect(_ppHem, _ppFill..color = Sketch.fade(Sketch.mix(paper, const Color(0xff2a1236), .2), .97 * presence));
        c.drawRect(_ppFold, _ppFill..color = Sketch.fade(Sketch.mix(paper, const Color(0xffffffff), .4), .7 * presence));
        c.drawRect(_ppPeg, _ppFill..color = Sketch.fade(const Color(0xffaa7446), presence));
        c.drawRect(_ppPegLit, _ppFill..color = Sketch.fade(const Color(0xffdea86a), presence));
        c.drawRect(_ppPegPin, _ppFill..color = Sketch.fade(const Color(0xff543628), presence));
        c.restore();
      }
    }
  }

  // The mountains are painted as sunlit-edge illustrations: each silhouette is
  // filled once in its rim light, then re-filled inside copies of itself
  // shifted toward the shadow, so glowing bands hug every sun-facing slope.
  // The sun sits at .42 of the width, so Iztaccihuatl (left of it) is lit on
  // its right and Popocatepetl (right of it) on its left.

  /// Foot of every mountain and foothill, hidden behind the far ridge.
  static const _mtnBase = .72;

  /// A vertical gradient paint from [top] at [y0] to [base] at [y1].
  static Paint _mtnGrad(double y0, double y1, Color top, Color base, [double alpha = 1]) => Paint()
    ..shader = Gradient.linear(Offset(0, y0), Offset(0, y1), [Sketch.fade(top, alpha), Sketch.fade(base, alpha)]);

  static Path _mtnPoly(List<Offset> pts) => Path()..addPolygon(pts, true);

  /// A closed polygon from (x, y) pairs in mountain units: x from [ox], both in [h].
  static Path _mtnPath(List<double> xy, double ox, double h) =>
      _mtnPoly([for (var i = 0; i + 1 < xy.length; i += 2) Offset(ox + xy[i] * h, xy[i + 1] * h)]);

  /// Splits the polyline [xy] into steps of at most [step] and nudges the new
  /// points by up to [jit], so a crest looks drawn rather than ruled.
  static List<double> _mtnRough(List<double> xy, double step, double jit, int seed) {
    final out = <double>[];
    for (var i = 0; i + 3 < xy.length; i += 2) {
      final x0 = xy[i], y0 = xy[i + 1], x1 = xy[i + 2], y1 = xy[i + 3];
      out
        ..add(x0)
        ..add(y0);
      final k = (math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)) / step).ceil();
      for (var j = 1; j < k; j++) {
        final t = j / k;
        out
          ..add(x0 + (x1 - x0) * t)
          ..add(y0 + (y1 - y0) * t + (Sketch.hash(seed + i * 7 + j) - .5) * 2 * jit);
      }
    }
    out
      ..add(xy[xy.length - 2])
      ..add(xy[xy.length - 1]);
    return out;
  }

  /// The crest height of the (x, y) polyline [xy] at [x].
  static double _mtnCrestY(List<double> xy, double x) {
    if (x <= xy[0]) return xy[1];
    for (var i = 2; i + 1 < xy.length; i += 2) {
      if (x <= xy[i]) {
        final x0 = xy[i - 2], y0 = xy[i - 1], dx = xy[i] - x0;
        return dx <= 0 ? xy[i + 1] : y0 + (xy[i + 1] - y0) * ((x - x0) / dx);
      }
    }
    return xy[xy.length - 1];
  }

  /// A gully from [y0] to [y1] along [center], narrow at the top and opening
  /// downhill. [shoulder] gets the sunlit rib beside it, on the right.
  static void _mtnGully(
    Path gully,
    Path? shoulder,
    double ox,
    double h,
    double y0,
    double y1,
    double wmax,
    double Function(double y) center,
  ) {
    final left = <Offset>[], right = <Offset>[], rib = <Offset>[], ribOut = <Offset>[];
    var y = y0;
    while (true) {
      final t = (y - y0) / (y1 - y0);
      final hw = wmax * (.1 + .9 * t) * math.min(1.0, t * 8 + .2);
      final xc = center(y);
      left.add(Offset(ox + (xc - hw) * h, y * h));
      right.add(Offset(ox + (xc + hw) * h, y * h));
      rib.add(Offset(ox + (xc + hw * 1.1) * h, y * h));
      ribOut.add(Offset(ox + (xc + hw * 3.4) * h, y * h));
      if (y >= y1) break;
      y = math.min(y1, y + .03);
    }
    gully.addPolygon([...left, ...right.reversed], true);
    shoulder?.addPolygon([...rib, ...ribOut.reversed], true);
  }

  /// A hazy range of far Sierra Madre crests behind everything else: a pale
  /// back range and a nearer one whose faces glow toward the setting sun.
  static void _sierra(Canvas c, double w, double h) {
    final step = h * .03;
    final n = ((w + h * _reach + h * .2) / step).ceil();
    final sun = w * .42;
    void range(
      double Function(double x) crest,
      double hazeTop,
      double hazeBase,
      Color tintTop,
      Color tintBase,
      int seed, {
      bool rim = false,
    }) {
      final xs = <double>[for (var i = 0; i <= n; i++) -h * .2 + i * step];
      final ys = <double>[for (var i = 0; i <= n; i++) crest(xs[i]) * h + (Sketch.hash(seed + i) - .5) * h * .004];
      final path = _mtnPoly([Offset(xs.first, h * .74), for (var i = 0; i <= n; i++) Offset(xs[i], ys[i]), Offset(xs.last, h * .74)]);
      final top = ys.reduce(math.min);
      final body = _mtnGrad(top, h * .68, _hazed(tintTop, hazeTop), _hazed(tintBase, hazeBase));
      if (!rim) {
        c.drawPath(path, body);
        return;
      }
      final lit = _mtnGrad(top, h * .68, _hazed(const Color(0xffd890a8), hazeTop * .7), _hazed(const Color(0xffe0a4a4), hazeBase));
      for (final (x0, x1, dir) in [(-h * .3, sun, 1.0), (sun, xs.last + h * .3, -1.0)]) {
        c.save();
        c.clipRect(Rect.fromLTRB(x0, 0, x1, h));
        c.drawPath(path, lit);
        c.translate(-dir * h * .02, h * .014);
        c.clipPath(path);
        c.translate(dir * h * .02, -h * .014);
        c.drawPath(path, body);
        c.restore();
      }
    }

    range(
      (x) => .535 - .04 * Sketch.peaks(x / (h * 1.25) + .55) - .02 * Sketch.peaks(x / (h * .42) + .2) - .008 * Sketch.peaks(x / (h * .15) + .1),
      .62,
      .8,
      const Color(0xff9a78b4),
      const Color(0xff9a78b4),
      1300,
    );
    range(
      (x) => .57 - .05 * Sketch.peaks(x / (h * .9) + .3) - .025 * Sketch.peaks(x / (h * .33) + .7) - .007 * Sketch.peaks(x / (h * .12) + .4),
      .42,
      .66,
      const Color(0xff7e5c9e),
      const Color(0xff8f6fa8),
      1400,
      rim: true,
    );
  }

  /// Mist in the passes, then two ranks of forested foothills in front of
  /// both volcanoes, the nearer one darker and more crowded with treetops.
  static void _mtnFoothills(Canvas c, double w, double h) {
    for (final (fx, fy, fw, fh, alpha) in [(.2 * w, .565, .95, .05, .5), (.8 * w, .585, .75, .045, .5), (.5 * w, .6, .9, .05, .45)]) {
      Sketch.mist(c, Rect.fromCenter(center: Offset(fx, fy * h), width: h * fw, height: h * fh), const Color(0xffffc9a8), alpha);
    }
    final step = h * .012;
    final n = ((w + h * _reach + h * .2) / step).ceil();
    void hills(double Function(double x) crest, double jit, double hazeTop, double hazeBase, Color tint, int seed) {
      final pts = <Offset>[Offset(-h * .2, h * .74)];
      var top = h;
      for (var i = 0; i <= n; i++) {
        final x = -h * .2 + i * step;
        final y = crest(x) * h + (Sketch.hash(seed + i) - .5) * h * jit;
        top = math.min(top, y);
        pts.add(Offset(x, y));
      }
      pts.add(Offset(-h * .2 + n * step, h * .74));
      c.drawPath(_mtnPoly(pts), _mtnGrad(top, h * .68, _hazed(tint, hazeTop), _hazed(tint, hazeBase)));
    }

    hills((x) => .608 - .012 * Sketch.humps(x / (h * .95) + .2) - .006 * Sketch.humps(x / (h * .31) + .5), .002, .5, .6, const Color(0xff6a5090), 1500);
    hills((x) => .622 - .010 * Sketch.humps(x / (h * .7) + .6) - .005 * Sketch.peaks(x / (h * .19)), .006, .34, .5, const Color(0xff4c3a76), 1600);
  }

  /// Popocatepetl's plume: puffs rise from the crater, shadowed and grey at
  /// the vent and catching the sunset higher up, then lean toward the sun on
  /// the same wind that drives the clouds and the swallows.
  static void _mtnPlume(Canvas c, Offset crater, double h, double clock) {
    const n = 8;
    for (var i = 0; i < n; i++) {
      final age = (clock * .05 + i / n) % 1;
      final rise = h * .24 * (1 - math.pow(1 - age, 1.6).toDouble());
      final at = crater + Offset(-h * .3 * age * age + math.sin(age * 6 + i * 1.7) * h * .006, -h * .006 - rise);
      final r = h * (.014 + .05 * math.pow(age, .8).toDouble());
      final fade = age < .87 ? math.pow(math.sin(math.min(1.0, age * 1.15) * math.pi), .8).toDouble() : 0.0;
      final body = Sketch.mix(const Color(0xff8a7498), const Color(0xffffd4c4), math.min(1.0, age * 1.4));
      // A soft shadowed billow, with a warmer lit core toward the sun.
      final shade = Sketch.mix(body, const Color(0xff5a4478), .4);
      Sketch.mist(c, Rect.fromCenter(center: at + Offset(r * .15, r * .12), width: r * 6, height: r * 4.6), shade, .3 * fade);
      Sketch.mist(c, Rect.fromCenter(center: at + Offset(-r * .3, -r * .25), width: r * 3.6, height: r * 2.8), Sketch.mix(body, const Color(0xffffffff), .35), .45 * fade);
    }
  }

  /// The Sleeping Woman's ridge, from her hair at the left through head (the
  /// nose and chin in profile), neck, the two-humped chest, belly, knees and
  /// upturned feet, as (x, y) pairs in mountain units.
  static const _mtnIztaCrest = <double>[
    -.50, .72, -.44, .64, -.40, .585, -.375, .553, -.36, .523, -.335, .512, -.312, .512, -.29, .487, //
    -.278, .497, -.265, .506, -.245, .497, -.222, .523, -.205, .54, -.182, .527, -.155, .49, -.12, .455,
    -.09, .428, -.065, .413, -.045, .418, -.02, .41, 0, .402, .02, .408, .045, .43, .07, .455, //
    .095, .478, .12, .492, .15, .488, .18, .47, .205, .452, .225, .447, .24, .455, .26, .445,
    .285, .46, .31, .49, .33, .505, .35, .49, .365, .477, .385, .49, .41, .53, .44, .585,
    .47, .65, .50, .72,
  ];

  /// Iztaccihuatl's summits: x, y, feet of the slopes either side, snow
  /// depth and how many gullies score it.
  static const _mtnIztaPeaks = [
    (-.325, .5, -.5, -.205, .045, 3),
    (-.01, .402, -.205, .12, .1, 7),
    (.205, .447, .12, .235, .055, 2),
    (.26, .445, .235, .33, .055, 2),
    (.365, .477, .33, .5, .05, 3),
  ];

  /// Rock ribs that break the snow: x, the height they reach and their width.
  static const _mtnIztaSpikes = [(-.112, .462, .02), (-.045, .448, .016), (.05, .47, .02), (.16, .49, .02), (.245, .47, .012), (.33, .5, .015)];

  /// Iztaccíhuatl, the "sleeping woman": a long ridge of snowy peaks, warm on
  /// the slopes that face the sun and cool where they turn away.
  static void _izta(Canvas c, double ox, double h) {
    final crest = _mtnRough(_mtnIztaCrest, .022, .0035, 500);
    final sil = _mtnPath(crest, ox, h);
    final y0 = h * .4, y1 = h * .68;
    Paint g(Color top, double ht, Color base, double hb) => _mtnGrad(y0, y1, _hazed(top, ht), _hazed(base, hb));
    // Gullies fan down from the crest and snow tongues follow every other one.
    final tongues = <(double, double, double, int)>[];
    final gullies = Path(), shoulders = Path();
    for (var pi = 0; pi < _mtnIztaPeaks.length; pi++) {
      final (px, py, xl, xr, sd, gc) = _mtnIztaPeaks[pi];
      final cnt = gc + 1;
      for (var j = 0; j < cnt; j++) {
        final x0 = xl + (xr - xl) * (.08 + .84 * (j + .6 * Sketch.hash(pi * 37 + j + 600)) / cnt);
        final gy = _mtnCrestY(crest, x0) + .008 + (j % 3 == 1 ? .06 * Sketch.hash(pi * 41 + j + 750) : 0.0);
        final lean = (x0 - px) / (_mtnBase - py) + .06 * (Sketch.hash(pi * 43 + j + 760) - .5);
        if (j.isEven && gy < py + .03) {
          final tip = math.max(gy + .03, py + sd * (.6 + Sketch.hash(pi * 31 + j + 640)) + .03);
          tongues.add((
            x0 + lean * (tip - gy),
            tip,
            .006 + .008 * Sketch.hash(pi * 31 + j + 660),
            1 + (2 * Sketch.hash(pi * 31 + j + 680)).floor(),
          ));
        }
        _mtnGully(
          gullies,
          shoulders,
          ox,
          h,
          gy,
          _mtnBase,
          .004 + .004 * Sketch.hash(pi * 53 + j + 730),
          (y) => x0 + lean * (y - gy) + .003 * math.sin(y * 44 + j * 2.3) * math.min(1.0, (y - gy) / (_mtnBase - gy) * 4),
        );
      }
    }
    // The snowline: a tent over each summit, jagged, with tongues and rock ribs.
    double snowy(double x) {
      var y = -1.0;
      for (final (px, py, _, _, sd, _) in _mtnIztaPeaks) {
        y = math.max(y, py + sd - .2 * (x - px).abs());
      }
      y += .010 * Sketch.peaks(x / .034 + .3) + .006 * Sketch.peaks(x / .013 + .1) + .012 * Sketch.peaks(x / .11 + .6) - .012;
      for (final (tx, ty, tw, e) in tongues) {
        final d = (x - tx).abs();
        if (d < tw) {
          final u = d / tw;
          y = math.max(y, y + (ty - y) * (e == 1 ? 1 - u : math.sqrt(1 - u * u)));
        }
      }
      for (final (sx, ty, wv) in _mtnIztaSpikes) {
        final d = (x - sx).abs();
        if (d < wv) y = math.min(y, ty + (y - ty) * (d / wv));
      }
      return y;
    }

    final snow = Path()
      ..moveTo(ox - .6 * h, .2 * h)
      ..lineTo(ox + .6 * h, .2 * h);
    for (var k = 0; k <= 300; k++) {
      final x = .6 - k * .004;
      snow.lineTo(ox + x * h, (snowy(x) + (Sketch.hash(k + 800) - .5) * .003) * h);
    }
    snow.close();
    // Nested clips: the sunlit rim, a lit band, the shaded side, the body.
    final v1 = Offset(-.018 * h, .012 * h), v2 = Offset(-.05 * h, .03 * h), w1 = Offset(.03 * h, .02 * h);
    void level(Paint rock, Color snowColor, List<Offset> shifts) {
      c.save();
      for (final s in shifts) {
        c.translate(s.dx, s.dy);
        c.clipPath(sil);
        c.translate(-s.dx, -s.dy);
      }
      c.drawPath(sil, rock);
      c.drawPath(snow, Paint()..color = snowColor);
      c.restore();
    }

    c.save();
    c.clipPath(sil);
    level(g(const Color(0xfff0a89c), 0, const Color(0xffe8a4a0), .3), const Color(0xfffff0e0), const []);
    level(g(const Color(0xffc87e98), .06, const Color(0xffd694a2), .4), const Color(0xfffad8d8), [v1]);
    level(g(const Color(0xff3c2868), .06, const Color(0xff5a4084), .4), _hazed(const Color(0xffb4a0d2), .1), [v1, v2]);
    level(g(const Color(0xff5a4088), .1, const Color(0xff6c5090), .44), _hazed(const Color(0xffdcc2dc), .06), [v1, v2, w1]);
    c.drawPath(
      shoulders,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y0),
          Offset(0, y1),
          const [Color(0x00ffd0c0), Color(0x28e8a0a4), Color(0x32e8a0a4)],
          const [0, .4, 1],
        ),
    );
    c.drawPath(
      gullies,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y0),
          Offset(0, y1),
          const [Color(0x142c1a52), Color(0x282c1a52), Color(0x5524163f)],
          const [0, .3, 1],
        ),
    );
    c.drawPath(
      sil,
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .5), Offset(0, h * .68), [Sketch.fade(_haze, 0), Sketch.fade(_haze, .39)]),
    );
    c.restore();
  }

  /// Popocatepetl's flank: the half-width of the cone at height [y], concave
  /// like a stratovolcano, steepest under the crater.
  static const _mtnPopoY = <double>[_popoTop, .38, .40, .43, .47, .51, .55, .59, .63, .67, .72];
  static const _mtnPopoH = <double>[.042, .05, .064, .084, .11, .138, .168, .2, .238, .282, .345];

  /// Gullies down the cone, as fractions of the half-width, the height each
  /// snow tongue reaches and each tongue's half-width in the same fractions.
  static const _mtnPopoGully = <double>[-.9, -.74, -.57, -.4, -.22, -.05, .13, .3, .47, .64, .8, .93];
  static const _mtnPopoTip = <double>[.5, .535, .49, .52, .55, .5, .53, .485, .525, .5, .54, .505];
  static const _mtnPopoTongue = <double>[.07, .06, .08, .055, .07, .06, .08, .06, .07, .06, .07, .06];

  static double _mtnPopoHalf(double y) {
    if (y <= _mtnPopoY[0]) return _mtnPopoH[0];
    for (var i = 1; i < _mtnPopoY.length; i++) {
      if (y <= _mtnPopoY[i]) {
        final t = (y - _mtnPopoY[i - 1]) / (_mtnPopoY[i] - _mtnPopoY[i - 1]);
        return _mtnPopoH[i - 1] + (_mtnPopoH[i] - _mtnPopoH[i - 1]) * t;
      }
    }
    return _mtnPopoH.last;
  }

  /// Popocatépetl: a steep, fluted cone with a snowy crown and a notched
  /// crater to smoke from, lit along its left edge by the sinking sun.
  static void _popo(Canvas c, double ox, double h) {
    final ys = <double>[for (var y = .72; y > .372; y -= .0175) y, .372];
    final n = ys.length;
    double edge(int i, double side) {
      final k = math.min(1.0, (ys[i] - _popoTop) / .05);
      return side * _mtnPopoHalf(ys[i]) + (Sketch.hash(i * 7 + (side < 0 ? 3 : 5) + 900) - .5) * .006 * k;
    }

    final left = <Offset>[for (var i = 0; i < n; i++) Offset(ox + edge(i, -1) * h, ys[i] * h)];
    final right = <Offset>[for (var i = 0; i < n; i++) Offset(ox + edge(i, 1) * h, ys[i] * h)];
    const t = _popoTop;
    final rim = <Offset>[
      for (final (x, y) in const [
        (-.043, t + .004), (-.038, t - .001), (-.031, t + .001), (-.018, t + .005), (-.006, t + .009), //
        (.008, t + .007), (.02, t + .003), (.031, t), (.039, t + .001), (.043, t + .006),
      ])
        Offset(ox + x * h, y * h),
    ];
    final sil = _mtnPoly([...left, ...rim, ...right.reversed]);
    // The lit face ends in a soft terminator just right of the axis.
    Path lit(double a, double wob) => _mtnPoly([
      ...left,
      for (var i = n - 1; i >= 0; i--)
        Offset(ox + (a + wob * math.sin(ys[i] * 29 + 1.3)) * _mtnPopoHalf(ys[i]) * h, ys[i] * h),
    ]);
    final litFull = lit(.06, .03), litMid = lit(.4, .04);
    // The snowline: tongues run down the gullies, rock ribs poke up between.
    double snowline(double a) {
      final ridge = .462 + .012 * math.sin(a * 5 + 1) + .01 * Sketch.peaks(a * 2.3 + .2);
      var y = ridge;
      for (var i = 0; i < _mtnPopoGully.length; i++) {
        final d = (a - _mtnPopoGully[i]).abs();
        if (d < _mtnPopoTongue[i]) {
          y = math.max(y, ridge + (_mtnPopoTip[i] - ridge) * (1 - d / _mtnPopoTongue[i]));
        }
      }
      return y;
    }

    final snow = Path()
      ..moveTo(ox - .5 * h, .25 * h)
      ..lineTo(ox + .5 * h, .25 * h);
    for (var k = 0; k <= 130; k++) {
      final y = snowline(1.3 - k * .02) + (Sketch.hash(k + 950) - .5) * .004;
      snow.lineTo(ox + (1.3 - k * .02) * _mtnPopoHalf(y) * h, y * h);
    }
    snow.close();
    // Gullies: long ones from the crater, short ones lower down, and pale
    // ribs between them on the lit side.
    final major = Path(), minor = Path(), ribs = Path();
    for (var i = 0; i < _mtnPopoGully.length; i++) {
      final g = _mtnPopoGully[i];
      _mtnGully(major, null, ox, h, .39, .72, .0085, (y) => g * _mtnPopoHalf(y) + .004 * math.sin(y * 43 + i * 2.1));
    }
    for (var k = 0; k < 10; k++) {
      final g = -.95 + .21 * k + .06 * (Sketch.hash(k + 970) - .5);
      final from = .53 + .07 * Sketch.hash(k + 971);
      _mtnGully(
        minor,
        null,
        ox,
        h,
        from,
        math.min(.72, from + .12 + .1 * Sketch.hash(k + 972)),
        .005,
        (y) => g * _mtnPopoHalf(y) + .004 * math.sin(y * 43 + (k + 20) * 2.1),
      );
    }
    for (var i = 0; i + 1 < _mtnPopoGully.length; i++) {
      final g = (_mtnPopoGully[i] + _mtnPopoGully[i + 1]) / 2;
      if (g < .12) {
        _mtnGully(ribs, null, ox, h, _mtnPopoTip[i] + .01, .72, .006, (y) => g * _mtnPopoHalf(y) + .004 * math.sin(y * 43 + (i + 40) * 2.1));
      }
    }
    final y0 = h * _popoTop, y1 = h * .68;
    Paint tone(Color top, double ht, Color base, double hb, [double alpha = 1]) => _mtnGrad(y0, y1, _hazed(top, ht), _hazed(base, hb), alpha);
    Paint fade3(Color a, Color b, Color d) => Paint()..shader = Gradient.linear(Offset(0, y0), Offset(0, y1), [a, b, d], const [0, .35, 1]);
    c.save();
    c.clipPath(sil);
    // The sunlit edge and crater lip.
    c.drawPath(sil, tone(const Color(0xfff2b09c), 0, const Color(0xffe8a4a0), .3));
    c.drawPath(snow, Paint()..color = const Color(0xfffff0dc));
    // The far edge falls into shade.
    c.save();
    c.translate(.014 * h, .009 * h);
    c.clipPath(sil);
    c.translate(-.014 * h, -.009 * h);
    c.drawPath(sil, tone(const Color(0xff34205c), .06, const Color(0xff4e3878), .4));
    c.drawPath(snow, Paint()..color = _hazed(const Color(0xffa894cc), .08));
    // The body of the cone.
    c.save();
    c.translate(-.02 * h, .012 * h);
    c.clipPath(sil);
    c.translate(.02 * h, -.012 * h);
    c.drawPath(sil, tone(const Color(0xff4a3178), .08, const Color(0xff5e4488), .4));
    c.drawPath(litMid, tone(const Color(0xffae6c94), .06, const Color(0xffcc86a0), .42, .37));
    c.drawPath(litFull, tone(const Color(0xffbe7c9c), .06, const Color(0xffd490a2), .42));
    c.drawPath(ribs, Paint()..color = const Color(0x22ffc4a8));
    c.drawPath(major, fade3(const Color(0x163a2864), const Color(0x2e3a2864), const Color(0x642c1c4e)));
    c.drawPath(minor, Paint()..color = const Color(0x282c1c4e));
    c.drawPath(snow, Paint()..color = _hazed(const Color(0xffbba2d2), .12));
    c.save();
    c.clipPath(litMid);
    c.drawPath(snow, Paint()..color = _hazed(const Color(0xffe4c6dc), .06));
    c.restore();
    c.save();
    c.clipPath(litFull);
    c.drawPath(snow, Paint()..color = const Color(0xfffff0ea));
    c.restore();
    // Flutes carry the gullies up through the snow.
    c.drawPath(major, fade3(const Color(0x163a2864), const Color(0x143a2864), const Color(0x002c1c4e)));
    c.restore();
    c.restore();
    // Aerial perspective thickens toward the foot.
    c.drawPath(
      sil,
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .5), Offset(0, h * .68), [Sketch.fade(_haze, 0), Sketch.fade(_haze, .39)]),
    );
    c.restore();
  }

  /// Stucco washes of the hill town: ochre, terracotta, rose, turquoise,
  /// lilac, cream, sage, raspberry, cobalt and apricot.
  static const _townWalls = [
    Color(0xffe9a83c),
    Color(0xffd8613f),
    Color(0xffea8fa0),
    Color(0xff3fa9b4),
    Color(0xffa07ac4),
    Color(0xfff2d59a),
    Color(0xff7fb890),
    Color(0xffd4486c),
    Color(0xff4f82c4),
    Color(0xfff4b06a),
  ];

  /// Painted shutters and doors: teal, indigo, oxblood, green and brown.
  static const _townWoods = [
    Color(0xff2f6a62),
    Color(0xff2a4f8a),
    Color(0xff7a2f3a),
    Color(0xff3f7a4a),
    Color(0xff5a3422),
  ];

  /// Geraniums and bougainvillea in the balcony pots.
  static const _townBlooms = [
    Color(0xffe2407a),
    Color(0xffd8302a),
    Color(0xffff8a2a),
    Color(0xfff5c02a),
    Color(0xffff6aa0),
  ];

  /// Washing on the line: a sheet, a red shirt, blue trousers and brighter rags.
  static const _townCloth = [
    Color(0xfff6efe0),
    Color(0xffd8483a),
    Color(0xff3a78c0),
    Color(0xfff2c23a),
    Color(0xffe8709a),
    Color(0xff4fb0a0),
  ];

  /// A hillside pueblo in the manner of Guanajuato and Taxco: two rows of
  /// stucco houses of one to three storeys, under clay-tile hips and gables
  /// or flat parapets, with arched doors, shuttered windows, iron balconies
  /// of flower pots, chimneys and the odd lit pane, split by stair lanes with
  /// washing strung across them. Row 0 is the paler back row: its houses
  /// stand on terraces up to [lift] high, so the two rows stagger up the
  /// hill. Every wall is lit on its left and shaded on its right.
  void _town(Canvas c, double w, double h, double lift, double haze, int row) {
    final back = row == 0;
    // Only the near row is close enough for fine detail; the hazy back row
    // keeps to the big shapes.
    final fine = haze < .2;
    Color hz(Color k, [double extra = 0]) => _hazed(k, haze + extra);
    final p = Paint();
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, h * .0011);
    final barge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, h * .0046);
    void rect(Color k, double l, double t, double r, double b) {
      c.drawRect(Rect.fromLTRB(l, t, r, b), p..color = k);
    }

    // A round-headed opening: flat sill, semicircular crown.
    void arch(Color k, double l, double t, double r, double b) {
      final rad = Radius.circular((r - l) / 2);
      c.drawRRect(RRect.fromLTRBAndCorners(l, t, r, b, topLeft: rad, topRight: rad), p..color = k);
    }

    const cream = Color(0xfff2e4c8);
    const violet = Color(0xff33204c);
    // Light comes from the left, so right-hand walls and whatever sits under
    // an eave fall into a cool violet shade.
    final shade = Sketch.fade(hz(violet), .38);
    final under = Sketch.fade(hz(violet), .3);
    final iron = hz(const Color(0xff26182c));
    final glassDark = hz(const Color(0xff2b1c3c));
    final glassLit = _hazed(const Color(0xffffc656), haze * .4);
    final glassCore = _hazed(const Color(0xfffff0b0), haze * .4);
    final glow = Sketch.fade(_hazed(const Color(0xffffb545), haze * .4), .22);
    final stone = hz(const Color(0xffe6c29c));
    var x = -h * .1;
    var i = 0;
    var prevWall = -1;
    var prevLane = true;
    var prevBody = 0.0;
    while (x < w + h * _reach) {
      final seed = row * 300 + i;
      double rnd(int k) => Sketch.hash(seed * 29 + k + 6100);

      // Now and then a stair lane splits the near row: steps climb into an
      // arched passage lit by a wall lamp.
      final laneX = x;
      final lane = !back && !prevLane && rnd(20) < .22 ? h * (.02 + .008 * rnd(21)) : 0.0;
      final laneFoot = _y(Depth.mid, laneX + lane / 2, h) + h * .004;
      if (lane > 0) {
        final gy = laneFoot - h * .004;
        final lx0 = laneX + h * .003, lx1 = laneX + lane - h * .003;
        arch(Sketch.fade(hz(const Color(0xff2a1a3a)), .9), lx0, gy - h * .045, lx1, laneFoot);
        final treads = Path();
        var sy = gy;
        var rise = h * .0068;
        for (var k = 0; k < 6; k++) {
          sy -= rise;
          final inset = k * h * .0004;
          treads.addRect(Rect.fromLTRB(lx0 + inset, sy, lx1 - inset, sy + h * .0017));
          rise *= .88;
        }
        c.drawPath(treads, p..color = stone);
        final lamp = Offset(lx0 + h * .004, gy - h * .03);
        c.drawCircle(lamp, h * .006, p..color = glow);
        c.drawCircle(lamp, h * .0022, p..color = glassLit);
      }
      x += lane;

      // Massing: width, storeys and the terrace the house stands on. The
      // foot sits a hair under the ridge so the terrain always hides it.
      final bw = h * (.05 + .03 * rnd(0));
      final f1 = rnd(1);
      final floors = back ? (f1 < .3 ? 2 : 3) : (f1 < .22 ? 1 : (f1 < .75 ? 2 : 3));
      final gh = h * (.033 + .004 * rnd(2));
      final uh = h * (.027 + .004 * rnd(3));
      final body = gh + (floors - 1) * uh;
      final elev = lift * (.5 + .5 * rnd(4));
      final foot =
          math.max(_y(Depth.mid, x, h), math.max(_y(Depth.mid, x + bw / 2, h), _y(Depth.mid, x + bw, h))) + h * .004;
      final floor0 = foot - elev;
      final top = floor0 - body;
      final xr = x + bw;
      final sx = xr - bw * .17;

      var ci = (rnd(17) * _townWalls.length).floor();
      if (ci == prevWall) ci = (ci + 1) % _townWalls.length;
      prevWall = ci;
      final wallC = Sketch.mix(_townWalls[ci], const Color(0xffff9a5a), .08);
      final wall = hz(wallC);
      final rim = hz(Sketch.mix(wallC, const Color(0xffffe4b0), .55));
      final dado = hz(Sketch.mix(wallC, const Color(0xff4a2a3e), .4));
      final trim = hz(Sketch.mix(wallC, cream, .62));
      final chim = hz(Sketch.mix(wallC, const Color(0xffe8c8a0), .5));
      final chimShade = hz(Sketch.mix(wallC, violet, .55));
      final chimCap = hz(const Color(0xff5a3a48));
      final tileRaw = Sketch.mix(const Color(0xffb14a38), const Color(0xffd47a44), rnd(11) * .7);
      final tile = hz(tileRaw);
      final tileLit = hz(Sketch.mix(tileRaw, const Color(0xffffb27a), .5));
      final tileShade = hz(Sketch.mix(tileRaw, const Color(0xff4a2244), .5));
      final tileRib = hz(Sketch.mix(tileRaw, const Color(0xff4a2244), .3));

      // The terrace wall under a back-row house.
      if (elev > 0) {
        rect(hz(const Color(0xffa8785f)), x - h * .002, floor0, xr + h * .002, foot + h * .006);
        rect(hz(const Color(0xffe2b48f)), x - h * .003, floor0, xr + h * .003, floor0 + h * .0022);
      }

      // Stucco walls: a darker dado at the foot, a sun-warmed left edge and
      // a shaded right flank, with a moulding between the storeys.
      rect(wall, x, top, xr, floor0);
      rect(dado, x, floor0 - h * .0105, xr, floor0);
      rect(rim, x, top, x + math.max(.7, h * .0016), floor0);
      rect(shade, sx, top, xr, foot);
      for (var f = 1; f < floors; f++) {
        final y = floor0 - gh - (f - 1) * uh;
        rect(trim, x, y - h * .0011, sx, y + h * .0011);
      }

      // Roofs: a hipped clay-tile roof, a front gable or a flat parapet.
      final kind = rnd(5);
      final oh = bw * .07;
      var bloomY = top + h * .007;
      if (kind < .36) {
        final rh = bw * (.15 + .06 * rnd(22));
        final tl = x + bw * .13, tr = xr - bw * .13;
        c.drawPath(Sketch.poly([x - oh, top, tl, top - rh, tr, top - rh, xr + oh, top]), p..color = tile);
        c.drawPath(
          Sketch.poly([tl, top - rh, tl + bw * .12, top - rh, x - oh + bw * .14, top, x - oh, top]),
          p..color = tileLit,
        );
        c.drawPath(
          Sketch.poly([tr - bw * .16, top - rh, tr, top - rh, xr + oh, top, xr + oh - bw * .2, top]),
          p..color = tileShade,
        );
        if (fine) {
          // Tile courses run down the slope.
          final n = math.max(3, (bw / (h * .0058)).round());
          final ribs = Path();
          for (var k = 1; k < n; k++) {
            final u = k / n;
            ribs
              ..moveTo(tl + (tr - tl) * u, top - rh)
              ..lineTo(x - oh + (bw + oh * 2) * u, top);
          }
          c.drawPath(ribs, ink..color = tileRib);
        }
        rect(tileLit, tl - bw * .01, top - rh - h * .0016, tr + bw * .01, top - rh + h * .0008);
        rect(tileRib, x - oh, top - h * .0012, xr + oh, top + h * .0016);
        rect(under, x, top + h * .0016, xr, top + h * .0062);
        if (rnd(13) < .5) {
          _townChimney(
            c,
            p,
            x + bw * (.2 + .45 * rnd(23)),
            top - rh * .3,
            top - rh - h * (.008 + .004 * rnd(24)),
            h * .0078,
            chim,
            chimShade,
            chimCap,
          );
        }
      } else if (kind < .6) {
        final ph = bw * (.24 + .06 * rnd(22));
        final ax = x + bw * .5;
        final slope = ph / (bw * .5);
        // The chimney stands behind the gable, so it goes down first.
        if (rnd(13) < .55) {
          _townChimney(
            c,
            p,
            x + bw * .8,
            top - ph * .2,
            top - ph * .4 - h * (.008 + .004 * rnd(24)),
            h * .0078,
            chim,
            chimShade,
            chimCap,
          );
        }
        c.drawPath(Sketch.poly([x, top, ax, top - ph, xr, top]), p..color = wall);
        c.drawPath(Sketch.poly([sx, top, sx, top - ph * (1 - (sx - ax) / (bw * .5)), xr, top]), p..color = shade);
        final eaveL = Offset(x - oh, top + oh * slope), eaveR = Offset(xr + oh, top + oh * slope);
        final apex = Offset(ax, top - ph);
        c.drawPath(
          Path()
            ..moveTo(eaveL.dx, eaveL.dy)
            ..lineTo(apex.dx, apex.dy)
            ..lineTo(eaveR.dx, eaveR.dy),
          barge..color = tile,
        );
        c.drawPath(
          Path()
            ..moveTo(apex.dx, apex.dy)
            ..lineTo(eaveR.dx, eaveR.dy),
          barge..color = tileShade,
        );
        if (fine) {
          c.drawPath(
            Path()
              ..moveTo(eaveL.dx, eaveL.dy)
              ..lineTo(apex.dx, apex.dy),
            ink..color = tileLit,
          );
        }
        if (bw > h * .055) {
          // A round attic vent in the gable.
          c.drawCircle(Offset(ax, top - ph * .36), h * .0034, p..color = (rnd(14) < .4 ? glassLit : glassDark));
        }
      } else {
        final pp = h * (.0075 + .004 * rnd(22));
        bloomY = top - pp + h * .001;
        rect(wall, x, top - pp, xr, top);
        rect(rim, x, top - pp, x + math.max(.7, h * .0016), top);
        rect(shade, sx, top - pp, xr, top);
        rect(rnd(24) < .35 ? tileLit : trim, x - h * .0013, top - pp - h * .0022, xr + h * .0013, top - pp);
        rect(under, x, top - pp, xr, top - pp + h * .0026);
        final roofY = top - pp - h * .0022;
        final extra = rnd(14);
        if (extra < .22 && bw > h * .055) {
          // A little rooftop room under a lean-to of tiles.
          final cuW = bw * .36, cuH = h * .0135;
          final cuX = x + bw * (.1 + .42 * rnd(25));
          final cuWall = hz(Sketch.mix(_townWalls[(ci + 4) % _townWalls.length], cream, .3));
          rect(cuWall, cuX, roofY - cuH, cuX + cuW, roofY);
          rect(shade, cuX + cuW * .66, roofY - cuH, cuX + cuW, roofY);
          rect(tile, cuX - h * .002, roofY - cuH - h * .0022, cuX + cuW + h * .0025, roofY - cuH);
          rect(glassDark, cuX + cuW * .18, roofY - cuH * .7, cuX + cuW * .44, roofY);
        } else if (extra < .44 && bw > h * .055) {
          // Washing on the azotea, strung between two poles.
          final lineY = roofY - h * .012;
          final px0 = x + bw * .12, px1 = xr - bw * .14;
          c.drawPath(
            Path()
              ..moveTo(px0, roofY)
              ..lineTo(px0, lineY)
              ..moveTo(px1, roofY)
              ..lineTo(px1, lineY),
            ink..color = iron,
          );
          _townLaundry(c, p, ink, px0, lineY, px1, lineY, h * .003, h, seed, haze);
        }
      }

      // Windows and shutters, floor by floor, a door in one ground bay.
      final bays = bw < h * .058 ? 2 : (bw < h * .07 ? (rnd(6) < .5 ? 2 : 3) : 3);
      // Openings sit on the lit facade, never on the shaded flank.
      final bayW = (sx - x) / bays;
      final doorBay = math.min(bays - 1, (rnd(7) * bays).floor());
      final arched = rnd(8) < .4;
      final shut = rnd(9) < .62;
      final shutC = hz(_townWoods[(rnd(10) * _townWoods.length).floor()]);
      final ww = math.min(bayW * .42, h * .0125);
      final bf = floors - 1;
      final balc = floors >= 2 && rnd(12) < .58;
      final full = balc && rnd(26) < .2;
      final b0 = full ? 0 : doorBay;
      final b1 = full ? bays - 1 : doorBay;
      void opening(Color k, double l, double t, double r, double b) {
        if (arched) {
          arch(k, l, t, r, b);
        } else {
          rect(k, l, t, r, b);
        }
      }

      final mull = Path();
      for (var f = 0; f < floors; f++) {
        final y0 = floor0 - (f == 0 ? 0.0 : gh + (f - 1) * uh);
        final fh = f == 0 ? gh : uh;
        for (var b = 0; b < bays; b++) {
          if (f == 0 && b == doorBay) continue;
          final cx = x + bayW * (b + .5);
          // Under a balcony the window becomes a tall door onto it.
          final onBalc = balc && f == bf && b >= b0 && b <= b1;
          final wt = y0 - fh * (onBalc ? .84 : .86);
          final wb = onBalc ? y0 - h * .0025 : y0 - fh * .27;
          final l = cx - ww / 2, rr = cx + ww / 2;
          final on = Sketch.hash(seed * 131 + f * 17 + b + 55) < .38;
          if (on && fine) c.drawCircle(Offset(cx, (wt + wb) / 2), ww * .95, p..color = glow);
          if (shut) {
            rect(shutC, l - ww * .42, wt, l, wb);
            rect(shutC, rr, wt, rr + ww * .42, wb);
          } else if (fine) {
            opening(trim, l - h * .0012, wt - h * .0012, rr + h * .0012, wb + h * .0012);
          }
          opening(on ? glassLit : glassDark, l, wt, rr, wb);
          if (on && fine) {
            rect(glassCore, l + ww * .16, wt + (wb - wt) * .3, rr - ww * .16, wb - (wb - wt) * .14);
            mull
              ..moveTo(cx, wt)
              ..lineTo(cx, wb)
              ..moveTo(l, wt + (wb - wt) * .45)
              ..lineTo(rr, wt + (wb - wt) * .45);
          } else if (fine && f == 0 && !shut) {
            // Ground-floor windows carry an iron grille.
            mull
              ..moveTo(l + ww / 3, wt)
              ..lineTo(l + ww / 3, wb)
              ..moveTo(l + ww * 2 / 3, wt)
              ..lineTo(l + ww * 2 / 3, wb);
          }
          if (fine && !onBalc) rect(trim, l - h * .0016, wb, rr + h * .0016, wb + h * .0018);
        }
      }
      if (fine) c.drawPath(mull, ink..color = iron);

      // An arched door in a pale surround, sometimes ajar on a lit hall.
      final dcx = x + bayW * (doorBay + .5);
      final dw = math.min(bayW * .58, h * .0155);
      final dt = floor0 - gh * .82;
      final dl = dcx - dw / 2, dr = dcx + dw / 2;
      final leaf = rnd(15) < .55 ? shutC : hz(_townWoods[(rnd(28) * _townWoods.length).floor()]);
      if (fine) arch(trim, dl - h * .0018, dt - h * .0018, dr + h * .0018, floor0);
      if (rnd(16) < .24) {
        arch(glassLit, dl, dt, dr, floor0);
        rect(leaf, dl, dt + dw / 2, dl + dw * .3, floor0);
      } else {
        arch(leaf, dl, dt, dr, floor0);
        if (fine) c.drawLine(Offset(dcx, dt + dw / 2), Offset(dcx, floor0), ink..color = glassDark);
      }
      if (fine && rnd(27) < .3) {
        final lamp = Offset(dr + h * .003, dt + h * .002);
        c.drawCircle(lamp, h * .0055, p..color = glow);
        c.drawCircle(lamp, h * .0018, p..color = glassLit);
      }

      // A balcony of iron rails and flower pots on the top floor.
      if (balc) {
        _townBalcony(
          c,
          p,
          ink,
          x + bayW * b0 + (full ? -h * .002 : bayW * .1),
          x + bayW * (b1 + 1) + (full ? h * .002 : -bayW * .1),
          floor0 - gh - (bf - 1) * uh,
          h,
          fine,
          seed,
          haze,
        );
      }

      // Bougainvillea spilling over a roof edge.
      if (fine && rnd(18) < .24) {
        _townBloom(c, p, rnd(19) < .5 ? x + bw * .1 : xr - bw * .16, bloomY, h * .0055, haze);
      }

      // Washing across the lane, hung from the flanking walls.
      if (lane > 0 && prevBody >= h * .055 && body >= h * .055) {
        final ly = laneFoot - h * .056;
        _townLaundry(c, p, ink, laneX, ly, laneX + lane, ly + h * .002, h * .0035, h, seed, haze);
      }
      prevBody = body;
      prevLane = lane > 0;
      x += bw;
      i++;
    }
  }

  /// A squat stucco chimney with a cap slab and a clay pot, its right half in
  /// shade. [yBase] hides behind the roof; [yTop] is the cap's underside.
  static void _townChimney(
    Canvas c,
    Paint p,
    double cx,
    double yBase,
    double yTop,
    double cw,
    Color body,
    Color shade,
    Color cap,
  ) {
    c.drawRect(Rect.fromLTRB(cx - cw / 2, yTop, cx + cw / 2, yBase), p..color = body);
    c.drawRect(Rect.fromLTRB(cx + cw * .1, yTop, cx + cw / 2, yBase), p..color = shade);
    c.drawRect(Rect.fromLTRB(cx - cw * .64, yTop - cw * .26, cx + cw * .64, yTop + cw * .1), p..color = cap);
    c.drawRect(Rect.fromLTRB(cx - cw * .22, yTop - cw * .56, cx + cw * .22, yTop - cw * .2), p..color = cap);
  }

  /// An iron-railed balcony between [xl] and [xr] on the floor line [y]: a
  /// stone slab, a top bar over close balusters and, up close, pots of
  /// geraniums along the rail.
  static void _townBalcony(
    Canvas c,
    Paint p,
    Paint ink,
    double xl,
    double xr,
    double y,
    double h,
    bool fine,
    int seed,
    double haze,
  ) {
    final iron = _hazed(const Color(0xff26182c), haze);
    c.drawRect(Rect.fromLTRB(xl, y - h * .0016, xr, y + h * .0024), p..color = _hazed(const Color(0xff3c2a3e), haze));
    final ry = y - h * .0098;
    final bars = Path();
    final n = math.max(3, ((xr - xl) / (h * .0034)).round());
    for (var k = 0; k <= n; k++) {
      final bx = xl + (xr - xl) * k / n;
      bars
        ..moveTo(bx, ry)
        ..lineTo(bx, y - h * .0016);
    }
    c.drawPath(bars, ink..color = iron);
    c.drawRect(Rect.fromLTRB(xl - h * .0004, ry - h * .0007, xr + h * .0004, ry + h * .0007), p..color = iron);
    if (!fine) return;
    final pots = math.max(2, ((xr - xl) / (h * .0105)).floor());
    for (var k = 0; k < pots; k++) {
      final px = xl + (xr - xl) * (k + .5) / pots;
      final bloom = _hazed(_townBlooms[(Sketch.hash(seed * 7 + k + 300) * _townBlooms.length).floor()], haze);
      c.drawRect(
        Rect.fromLTRB(px - h * .0022, ry - h * .0034, px + h * .0022, ry + h * .0003),
        p..color = _hazed(const Color(0xffbb5a38), haze),
      );
      c.drawCircle(Offset(px, ry - h * .0048), h * .0031, p..color = _hazed(const Color(0xff3f7a4a), haze));
      c.drawCircle(Offset(px - h * .0011, ry - h * .0058), h * .0015, p..color = bloom);
      c.drawCircle(Offset(px + h * .0013, ry - h * .0045), h * .0013, p..color = bloom);
    }
  }

  /// A clothesline sagging by [sag] from (x0, y0) to (x1, y1), hung with
  /// sheets, shirts and little dresses.
  static void _townLaundry(
    Canvas c,
    Paint p,
    Paint ink,
    double x0,
    double y0,
    double x1,
    double y1,
    double sag,
    double h,
    int seed,
    double haze,
  ) {
    c.drawPath(
      Path()
        ..moveTo(x0, y0)
        ..quadraticBezierTo((x0 + x1) / 2, (y0 + y1) / 2 + sag * 2, x1, y1),
      ink..color = _hazed(const Color(0xff4a3446), haze),
    );
    final n = math.max(2, ((x1 - x0) / (h * .0078)).floor());
    for (var k = 0; k < n; k++) {
      final u = (k + .5) / n;
      final cx = x0 + (x1 - x0) * u;
      final cy = y0 + (y1 - y0) * u + sag * 4 * u * (1 - u);
      final pick = Sketch.hash(seed * 11 + k + 4200);
      final cw = h * (.0032 + .0028 * Sketch.hash(seed * 11 + k + 4300));
      final len = h * (.0048 + .0045 * pick);
      p.color = _hazed(_townCloth[(pick * _townCloth.length).floor()], haze);
      if (pick > .7) {
        c.drawPath(Sketch.poly([cx - cw * .5, cy, cx + cw * .5, cy, cx + cw * .8, cy + len, cx - cw * .8, cy + len]), p);
      } else {
        c.drawRect(Rect.fromLTRB(cx - cw / 2, cy, cx + cw / 2, cy + len), p);
      }
    }
  }

  /// A bougainvillea bush of magenta bracts over dark leaves, about [s] wide.
  static void _townBloom(Canvas c, Paint p, double cx, double cy, double s, double haze) {
    c.drawCircle(Offset(cx, cy), s * .8, p..color = _hazed(const Color(0xff3f7a4a), haze));
    for (final (dx, dy, r) in const [(-.7, -.1, .62), (.15, -.45, .68), (.75, .1, .6), (-.25, .55, .55), (.5, .85, .42)]) {
      c.drawCircle(Offset(cx + dx * s, cy + dy * s), r * s, p..color = _hazed(const Color(0xffd42a80), haze));
      c.drawCircle(Offset(cx + (dx - .2) * s, cy + (dy - .2) * s), r * s * .45, p..color = _hazed(const Color(0xffff78b8), haze));
    }
  }

  /// A colonial baroque church, lit on its left and shaded on its right. The
  /// cathedral is a retablo facade between two belfries with a talavera-tiled
  /// dome rising behind; a [chapel] is a village church with one tower and a
  /// small dome. It is drawn in units of [s] from [base], the middle of its
  /// ground line (y grows down), and [haze] pushes a distant one back into the
  /// dusk. Its foot runs deep so it always meets the terrain, and the houses
  /// in front hide the lowest storey.
  static void _church(Canvas c, Offset base, double s, double haze, {bool chapel = false}) {
    final k = _ChurchKit(haze, s);
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(s, s);
    if (chapel) {
      _churchChapel(c, k);
    } else {
      _churchCathedral(c, k);
    }
    c.restore();
  }

  static void _churchRect(Canvas c, Paint p, double l, double t, double r, double b) => c.drawRect(Rect.fromLTRB(l, t, r, b), p);

  /// [l, r] x [t, b] in [left] up to x = [split] and in [right] beyond it.
  static void _churchSplit(Canvas c, _ChurchKit k, double l, double t, double r, double b, double split, Color left, Color right) {
    final cut = math.min(math.max(split, l), r);
    if (cut > l) _churchRect(c, k.fill(left), l, t, cut, b);
    if (cut < r) _churchRect(c, k.fill(right), cut, t, r, b);
  }

  /// A round-headed opening [x] +- [hw] wide, from [bottom] up to its
  /// springing line [spring] and a semicircle above that.
  static Path _churchArch(double x, double bottom, double hw, double spring) => Path()
    ..moveTo(x - hw, bottom)
    ..lineTo(x - hw, spring)
    ..arcToPoint(Offset(x + hw, spring), radius: Radius.circular(hw))
    ..lineTo(x + hw, bottom)
    ..close();

  /// A curving baroque gable [hw] wide either side of [cx] and [hgt] tall on
  /// a base at [y]: square shoulders, a scroll in from each side and a peak.
  static Path _churchCrown(double cx, double y, double hw, double hgt) => Path()
    ..moveTo(cx - hw, y)
    ..lineTo(cx - hw, y - hgt * .27)
    ..cubicTo(cx - hw, y - hgt * .49, cx - hw * .65, y - hgt * .49, cx - hw * .5, y - hgt * .58)
    ..cubicTo(cx - hw * .375, y - hgt * .68, cx - hw * .25, y - hgt, cx, y - hgt)
    ..cubicTo(cx + hw * .25, y - hgt, cx + hw * .375, y - hgt * .68, cx + hw * .5, y - hgt * .58)
    ..cubicTo(cx + hw * .65, y - hgt * .49, cx + hw, y - hgt * .49, cx + hw, y - hgt * .27)
    ..lineTo(cx + hw, y)
    ..close();

  /// A projecting cornice whose underside is at [y]: a bright band, a darker
  /// lip and the shadow it throws on the wall [l, r] below. Whatever lies to
  /// the right of [split] has turned into shade.
  static void _churchLedge(
    Canvas c,
    _ChurchKit k,
    double l,
    double r,
    double y, {
    double? split,
    double rise = .012,
    double over = .008,
  }) {
    final cut = split ?? r + over;
    _churchRect(c, k.fill(Sketch.fade(k.deep, .4)), l, y, r, y + rise * 1.05);
    _churchSplit(c, k, l - over, y - rise, r + over, y, cut, k.trim, k.trimSide);
    _churchSplit(c, k, l - over, y - rise * .36, r + over, y, cut, k.trimSide, k.side);
  }

  /// Faint courses of dressed stone across a wall.
  static void _churchCourses(Canvas c, _ChurchKit k, double l, double r, double top, double bottom, double step) {
    final joints = Path();
    for (var y = top + step; y < bottom; y += step) {
      joints
        ..moveTo(l, y)
        ..lineTo(r, y);
    }
    c.drawPath(joints, k.pen(Sketch.fade(k.side, .2), k.px * .7));
  }

  /// A framed arched window: a pale surround round a dark opening, with the
  /// frame's shadow to its right and, up close, light on the right reveal.
  static void _churchWindow(Canvas c, _ChurchKit k, double x, double bottom, double spring, double hw) {
    c.drawPath(_churchArch(x, bottom + hw * .3, hw * 1.5, spring), k.fill(k.trim));
    c.drawPath(_churchArch(x, bottom, hw, spring), k.fill(k.dark));
    if (k.fine) {
      _churchRect(c, k.fill(Sketch.fade(k.deep, .32)), x + hw * 1.5, spring, x + hw * 1.9, bottom + hw * .3);
    }
    if (k.rich) {
      _churchRect(c, k.fill(Sketch.fade(k.lit, .55)), x + hw * .55, spring, x + hw, bottom);
    }
  }

  /// A bronze bell [h] tall hung from a wooden yoke at [top], lit on its left.
  static void _churchBell(Canvas c, _ChurchKit k, double x, double top, double h) {
    final w = h * .36;
    c.drawPath(
      Path()
        ..moveTo(x - w * .34, top + h * .14)
        ..cubicTo(x - w * .36, top + h * .5, x - w * .6, top + h * .64, x - w, top + h * .88)
        ..lineTo(x + w, top + h * .88)
        ..cubicTo(x + w * .6, top + h * .64, x + w * .36, top + h * .5, x + w * .34, top + h * .14)
        ..close(),
      k.fill(k.bellSide),
    );
    c.drawPath(
      Path()
        ..moveTo(x - w * .34, top + h * .14)
        ..cubicTo(x - w * .36, top + h * .5, x - w * .6, top + h * .64, x - w, top + h * .88)
        ..lineTo(x - w * .1, top + h * .88)
        ..cubicTo(x - w * .16, top + h * .64, x - w * .06, top + h * .5, x - w * .06, top + h * .14)
        ..close(),
      k.fill(k.bell),
    );
    _churchRect(c, k.fill(k.bellSide), x - w * 1.06, top + h * .86, x + w * 1.06, top + h * .93);
    c.drawCircle(Offset(x, top + h * .97), w * .16, k.fill(k.bellSide));
    _churchRect(c, k.fill(k.deep), x - w * 1.15, top, x + w * 1.15, top + h * .1);
  }

  /// A gilded ball and cross standing on [y], the cross [h] tall.
  static void _churchCross(Canvas c, _ChurchKit k, double x, double y, double h) {
    final w = math.max(k.px * .9, h * .1);
    c.drawCircle(Offset(x, y - h * .09), h * .1, k.fill(k.metal));
    c.drawLine(Offset(x, y - h * .12), Offset(x, y - h), k.pen(k.metal, w));
    c.drawLine(Offset(x - h * .3, y - h * .7), Offset(x + h * .3, y - h * .7), k.pen(k.metal, w));
    if (k.rich) c.drawCircle(Offset(x - w * .3, y - h * .7), w * .55, k.fill(k.glint));
  }

  /// A slender obelisk finial [h] tall standing on a parapet corner at [base].
  static void _churchPinnacle(Canvas c, _ChurchKit k, double x, double base, double h, Color color) {
    c.drawPath(
      Sketch.poly([x - h * .13, base, x - h * .13, base - h * .55, x, base - h, x + h * .13, base - h * .55, x + h * .13, base]),
      k.fill(color),
    );
    c.drawCircle(Offset(x, base - h * .55), h * .1, k.fill(color));
  }

  /// A white dove perched on a ledge at [y], [w] long, facing left.
  static void _churchPerch(Canvas c, _ChurchKit k, double x, double y, double w) {
    c.drawOval(Rect.fromLTRB(x - w * .5, y - w * .4, x + w * .5, y), k.fill(k.white));
    c.drawCircle(Offset(x - w * .46, y - w * .46), w * .17, k.fill(k.white));
    c.drawPath(
      Sketch.poly([x + w * .35, y - w * .3, x + w * .95, y - w * .05, x + w * .95, y, x + w * .3, y - w * .12]),
      k.fill(k.trimSide),
    );
    c.drawOval(Rect.fromLTRB(x - w * .2, y - w * .2, x + w * .45, y), k.fill(Sketch.fade(k.trimSide, .7)));
  }

  /// Half-width and height of the point at [t] along a dome's outline.
  static (double, double) _churchDomeAt(double hw, double hgt, double t) {
    final u = 1 - t;
    return (
      hw * (u * u * u + 3 * u * u * t + 3 * u * t * t * .3),
      hgt * (3 * u * u * t * .75 + 3 * u * t * t * .85 + t * t * t),
    );
  }

  /// A tiled dome of [hw] half-width and [hgt] height on [base]: talavera
  /// gores of blue and yellow between [n] meridian joints, a warm rim on the
  /// sunlit left and the right side turned into shade.
  static void _churchCupola(Canvas c, _ChurchKit k, double cx, double base, double hw, double hgt, int n) {
    Path gore(double a0, double a1) => Path()
      ..moveTo(cx + a0 * hw, base)
      ..cubicTo(cx + a0 * hw, base - hgt * .75, cx + a0 * hw * .3, base - hgt * .85, cx, base - hgt)
      ..cubicTo(cx + a1 * hw * .3, base - hgt * .85, cx + a1 * hw, base - hgt * .75, cx + a1 * hw, base)
      ..close();
    // Where meridian i meets the base, as a fraction of the half-width.
    double edge(int i) => math.sin(-math.pi / 2 + math.pi * i / n);
    c.drawPath(gore(-1, 1), k.fill(k.blue));
    for (var i = 1; i < n; i += 2) {
      c.drawPath(gore(edge(i), edge(i + 1)), k.fill(k.gold));
    }
    if (k.fine && n > 2) {
      final joints = Path();
      for (var i = 1; i < n; i++) {
        final a = edge(i);
        joints
          ..moveTo(cx + a * hw, base)
          ..cubicTo(cx + a * hw, base - hgt * .75, cx + a * hw * .3, base - hgt * .85, cx, base - hgt);
      }
      c.drawPath(joints, k.pen(Sketch.fade(k.white, .8), k.px * .7));
    }
    if (k.rich && n >= 5) {
      // Two bands of white glaze curve round the shell.
      final band = Path();
      for (final t in const [.28, .56]) {
        final (dx, dy) = _churchDomeAt(hw, hgt, t);
        band
          ..moveTo(cx - dx, base - dy)
          ..quadraticBezierTo(cx, base - dy - hgt * .07, cx + dx, base - dy);
      }
      c.drawPath(band, k.pen(Sketch.fade(k.white, .75), k.px * .8));
    }
    c.drawPath(gore(.34, 1), k.fill(Sketch.fade(k.deep, .4)));
    c.drawPath(gore(-1, -.66), k.fill(Sketch.fade(k.glint, .32)));
  }

  /// A lantern crowning a dome: a small shaft with two slit windows, a
  /// cornice, a tiled cap and a gilded cross. [bottom] is where it meets the
  /// dome and [hw] and [hgt] size the shaft.
  static void _churchLantern(Canvas c, _ChurchKit k, double cx, double bottom, double hw, double hgt) {
    final top = bottom - hgt;
    _churchSplit(c, k, cx - hw, top, cx + hw, bottom, cx + hw * .25, k.lit, k.side);
    _churchRect(c, k.fill(k.trim), cx - hw, top, cx - hw * .72, bottom);
    if (k.fine) {
      for (final dx in const [-.36, .5]) {
        c.drawPath(_churchArch(cx + dx * hw, bottom - hgt * .1, hw * .2, top + hgt * .42), k.fill(k.dark));
      }
    }
    final rise = hw * .45;
    _churchLedge(c, k, cx - hw, cx + hw, top, split: cx + hw * .25, rise: rise, over: hw * .25);
    final capBase = top - rise + .001;
    final capHeight = hw * 1.35;
    _churchCupola(c, k, cx, capBase, hw * 1.1, capHeight, 3);
    _churchCross(c, k, cx, capBase - capHeight, hw * 1.7);
  }

  /// The drum a dome stands on: a cylinder shaded from lit to dark, ribbed
  /// with piers that bunch toward its edges, with arched windows at the front
  /// and 45 degrees either side when [sill] and [spring] are given.
  static void _churchDrum(Canvas c, _ChurchKit k, double cx, double hw, double top, double bottom, {double? sill, double? spring}) {
    _churchRect(c, k.fill(k.lit), cx - hw, top, cx - hw * .15, bottom);
    _churchRect(c, k.fill(k.mid), cx - hw * .15, top, cx + hw * .5, bottom);
    _churchRect(c, k.fill(k.side), cx + hw * .5, top, cx + hw, bottom);
    final u = hw / .14;
    for (final (a, w) in const [(-.924, .006), (-.383, .011), (.383, .011), (.924, .006)]) {
      final x = cx + a * hw;
      _churchRect(c, k.fill(a < 0 ? k.trim : k.trimSide), x - w * u / 2, top, x + w * u / 2, bottom);
    }
    if (sill != null && spring != null) {
      for (final (a, w) in const [(-.707, .7), (0.0, 1.0), (.707, .7)]) {
        _churchWindow(c, k, cx + a * hw, sill, spring, hw * .09 * w);
      }
    }
  }

  /// The atrium terrace a church stands on, its coping catching the light.
  static void _churchTerrace(Canvas c, _ChurchKit k, double l, double r) {
    _churchSplit(c, k, l, .05, r, .8, l + (r - l) * .62, k.mid, k.side);
    _churchRect(c, k.fill(Sketch.fade(k.deep, .35)), l, .05, r, .068);
    _churchRect(c, k.fill(k.trim), l - .012, .034, r + .012, .05);
  }

  /// One belfry tower of the cathedral, centred on [cx]: three storeys under
  /// a balustrade, an octagonal lantern and a tiled cupola. Its front is lit
  /// and its flank turns into shade; the right-hand tower carries a [clock].
  static void _churchTower(Canvas c, _ChurchKit k, double cx, {required bool clock}) {
    const hw = .075;
    final l = cx - hw, r = cx + hw;
    // Where the lit front turns into the shaded flank, and the front's middle.
    final crease = cx + .034;
    final fc = (l + crease) / 2;
    _churchSplit(c, k, l, -.625, r, .5, crease, k.lit, k.side);
    if (k.rich) _churchCourses(c, k, l, crease, -.625, .1, .036);
    _churchRect(c, k.fill(k.trim), l, -.625, l + .011, .5);
    _churchRect(c, k.fill(k.trim), crease - .009, -.625, crease, .5);
    _churchRect(c, k.fill(k.trimSide), crease, -.625, crease + .004, .5);
    _churchRect(c, k.fill(k.trimSide), r - .008, -.625, r, .5);

    // Ground storey and second storey: a framed window, or the clock.
    _churchWindow(c, k, fc, -.11, -.185, .0135);
    _churchLedge(c, k, l, r, -.29, split: crease);
    if (clock) {
      const cy = -.373;
      c.drawCircle(Offset(fc, cy), .03, k.fill(k.mid));
      c.drawCircle(Offset(fc, cy), .0245, k.fill(k.white));
      final hands = Path()
        ..moveTo(fc, cy - .017)
        ..lineTo(fc, cy)
        ..lineTo(fc + .0105, cy + .0045);
      c.drawPath(hands, k.pen(k.dark, math.max(k.px * .8, .0032)));
    } else {
      _churchWindow(c, k, fc, -.335, -.395, .0125);
    }
    _churchLedge(c, k, l, r, -.445, split: crease);

    // Belfry: a stone-framed arch with a bell hung inside, and a slit in the
    // shaded flank.
    c.drawPath(_churchArch(fc, -.5, .039, -.58), k.fill(k.trim));
    c.drawPath(_churchArch(fc, -.503, .03, -.58), k.fill(k.dark));
    if (k.rich) _churchRect(c, k.fill(Sketch.fade(k.lit, .5)), fc + .019, -.58, fc + .03, -.507);
    _churchBell(c, k, fc, -.594, .07);
    _churchRect(c, k.fill(k.trim), fc - .043, -.507, fc + .043, -.497);
    if (k.fine) c.drawPath(_churchArch(cx + .0545, -.507, .0085, -.575), k.fill(k.dark));
    _churchLedge(c, k, l, r, -.625, split: crease, rise: .014, over: .009);

    // Balustrade with corner pinnacles.
    _churchSplit(c, k, l - .003, -.657, r + .003, -.637, crease, k.trim, k.trimSide);
    if (k.rich) {
      final gaps = Path();
      for (var x = l + .006; x < r - .004; x += .0135) {
        gaps.addRect(Rect.fromLTWH(x, -.6535, .006, .0125));
      }
      c.drawPath(gaps, k.fill(k.dark));
    }
    if (k.fine) {
      _churchPinnacle(c, k, l + .004, -.657, .042, k.trim);
      _churchPinnacle(c, k, r - .004, -.657, .042, k.trimSide);
    }

    // Octagonal lantern, its cornice, the tiled cupola and the cross.
    final ol = cx - .052, orr = cx + .052, oc = cx + .018;
    _churchSplit(c, k, ol, -.712, orr, -.655, oc, k.lit, k.side);
    _churchRect(c, k.fill(k.trim), ol, -.712, ol + .008, -.655);
    _churchRect(c, k.fill(k.trim), oc - .007, -.712, oc, -.655);
    _churchRect(c, k.fill(k.trimSide), orr - .006, -.712, orr, -.655);
    c.drawPath(_churchArch(cx - .017, -.663, .0085, -.692), k.fill(k.dark));
    _churchLedge(c, k, ol, orr, -.712, split: oc, over: .006);
    _churchCupola(c, k, cx, -.723, .056, .085, k.rich ? 5 : 3);
    _churchCross(c, k, cx, -.808, .055);
  }

  static void _churchCathedral(Canvas c, _ChurchKit k) {
    // The dome rides behind the facade: a drum ribbed with piers and lit by
    // arched windows, a talavera shell, a lantern and a gilded cross.
    _churchDrum(c, k, 0, .14, -.548, -.34, sill: -.492, spring: -.522);
    _churchLedge(c, k, -.14, .14, -.548, split: .07, over: .01);
    _churchCupola(c, k, 0, -.559, .142, .15, k.rich ? 9 : 5);
    _churchLantern(c, k, 0, -.697, .026, .051);
    if (k.fine) {
      for (final x in const [-.129, .129]) {
        c.drawCircle(Offset(x, -.566), .0065, k.fill(x < 0 ? k.trim : k.trimSide));
      }
    }

    // The facade wall between the towers, with a string course and, in each
    // wing, a tall window under an oculus.
    _churchRect(c, k.fill(k.lit), -.18, -.34, .18, .5);
    if (k.rich) _churchCourses(c, k, -.18, .18, -.34, .1, .034);
    _churchLedge(c, k, -.18, .18, -.235, rise: .01);
    for (final side in const [-1.0, 1.0]) {
      _churchWindow(c, k, side * .152, -.05, -.165, .0092);
      c.drawCircle(Offset(side * .152, -.285), .0135, k.fill(k.trim));
      c.drawCircle(Offset(side * .152, -.285), .0092, k.fill(k.dark));
    }

    // The crown: a curving gable round a blue tiled panel, with a saint in a
    // niche and a cross on the peak.
    final crown = _churchCrown(0, -.34, .12, .105);
    c.drawPath(crown, k.fill(k.trim));
    c.save();
    c.translate(0, -.34);
    c.scale(.76, .7);
    c.translate(0, .34);
    c.drawPath(crown, k.fill(k.blue));
    c.restore();
    c.drawPath(_churchArch(0, -.34, .0105, -.383), k.fill(k.deep));
    if (k.rich) {
      c.drawCircle(const Offset(0, -.3775), .0035, k.fill(k.white));
      _churchRect(c, k.fill(k.white), -.0035, -.372, .0035, -.354);
      for (final x in const [-.048, -.032, .032, .048]) {
        c.drawPath(Sketch.poly([x, -.383, x + .0055, -.3775, x, -.372, x - .0055, -.3775]), k.fill(k.gold));
      }
    }

    // The retablo portal, first storey: a pale panel between pilasters, the
    // door under a carved arch, paired Salomonic columns and a saint's niche
    // in each outer bay.
    _churchRect(c, k.fill(Sketch.fade(k.deep, .3)), .12, -.235, .134, .5);
    _churchRect(c, k.fill(k.trim), -.12, -.235, .12, .5);
    _churchRect(c, k.fill(k.glint), -.12, -.235, -.108, .5);
    _churchRect(c, k.fill(k.trimSide), .108, -.235, .12, .5);
    _churchRect(c, k.fill(Sketch.fade(k.deep, .25)), -.108, -.235, -.104, .5);
    c.drawPath(_churchArch(0, .5, .05, -.125), k.fill(k.mid));
    c.drawPath(_churchArch(0, .5, .033, -.125), k.fill(k.dark));
    if (k.fine) c.drawPath(_churchArch(0, .5, .006, -.06), k.fill(Sketch.fade(k.glow, .85)));
    if (k.rich) {
      // Voussoir joints round the arch and a keystone at its crown.
      final joints = Path();
      for (var i = 1; i < 7; i++) {
        final a = math.pi * i / 7;
        joints
          ..moveTo(math.cos(a) * .034, -.125 - math.sin(a) * .034)
          ..lineTo(math.cos(a) * .049, -.125 - math.sin(a) * .049);
      }
      c.drawPath(joints, k.pen(Sketch.fade(k.trimSide, .9), k.px * .8));
      _churchRect(c, k.fill(k.trim), -.007, -.183, .007, -.165);
    }
    const cols = [-.0775, -.0615, .0615, .0775];
    for (final x in cols) {
      _churchRect(c, k.fill(k.glint), x - .0065, -.222, x - .0015, .5);
      _churchRect(c, k.fill(k.trim), x - .0015, -.222, x + .0025, .5);
      _churchRect(c, k.fill(k.trimSide), x + .0025, -.222, x + .0065, .5);
      _churchRect(c, k.fill(k.trim), x - .0085, -.232, x + .0085, -.222);
      _churchRect(c, k.fill(k.trimSide), x - .0085, -.226, x + .0085, -.222);
      _churchRect(c, k.fill(Sketch.fade(k.deep, .28)), x + .0065, -.222, x + .0105, .5);
    }
    if (k.rich) {
      // The twist of a Salomonic shaft, as slanting flutes.
      final twist = Path();
      for (final x in cols) {
        for (var y = -.212; y < .06; y += .02) {
          twist
            ..moveTo(x - .0065, y + .009)
            ..lineTo(x + .0065, y - .003);
        }
      }
      c.drawPath(twist, k.pen(Sketch.fade(k.deep, .55), k.px * .9));
    }
    for (final x in const [-.098, .098]) {
      if (k.fine) c.drawPath(_churchArch(x, -.03, .0125, -.15), k.fill(k.trimSide));
      c.drawPath(_churchArch(x, -.03, .0095, -.15), k.fill(k.deep));
      if (k.rich) {
        _churchRect(c, k.fill(k.white), x - .0045, -.056, x + .0045, -.03);
        _churchRect(c, k.fill(k.white), x - .0033, -.105, x + .0033, -.056);
        c.drawCircle(Offset(x, -.113), .0037, k.fill(k.white));
      }
    }
    _churchLedge(c, k, -.12, .12, -.235, rise: .02);
    if (k.rich) {
      final teeth = Path();
      for (var x = -.112; x < .108; x += .014) {
        teeth.addRect(Rect.fromLTWH(x, -.2345, .0065, .0055));
      }
      c.drawPath(teeth, k.fill(k.trimSide));
    }

    // Second storey: scrolled shoulders, the rose window and two more niches.
    for (final side in const [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(side * .12, -.255)
          ..quadraticBezierTo(side * .098, -.262, side * .098, -.31)
          ..lineTo(side * .098, -.255)
          ..close(),
        k.fill(side < 0 ? k.trim : k.trimSide),
      );
    }
    _churchRect(c, k.fill(Sketch.fade(k.deep, .28)), .098, -.34, .11, -.31);
    _churchRect(c, k.fill(k.trim), -.098, -.34, .098, -.255);
    _churchRect(c, k.fill(k.glint), -.098, -.34, -.09, -.255);
    _churchRect(c, k.fill(k.trimSide), .09, -.34, .098, -.255);
    const ry = -.295;
    c.drawCircle(const Offset(0, ry), .036, k.fill(k.mid));
    c.drawCircle(const Offset(0, ry), .031, k.fill(k.trim));
    c.drawCircle(const Offset(0, ry), .0255, k.fill(k.glass));
    if (k.fine) {
      final spokes = Path();
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 4;
        spokes
          ..moveTo(math.cos(a) * .0255, ry + math.sin(a) * .0255)
          ..lineTo(-math.cos(a) * .0255, ry - math.sin(a) * .0255);
      }
      final lead = math.max(k.px * .8, .003);
      c.drawPath(spokes, k.pen(k.trim, lead));
      c.drawCircle(const Offset(0, ry), .0135, k.pen(k.trim, lead));
      c.drawCircle(const Offset(0, ry), .0055, k.fill(k.glow));
    }
    if (k.rich) {
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + math.pi / 8;
        c.drawCircle(Offset(math.cos(a) * .0195, ry + math.sin(a) * .0195), .0028, k.fill(k.trim));
      }
    }
    for (final x in const [-.062, .062]) {
      c.drawPath(_churchArch(x, -.262, .0085, -.31), k.fill(k.deep));
      if (k.rich) {
        _churchRect(c, k.fill(k.white), x - .0026, -.293, x + .0026, -.262);
        c.drawCircle(Offset(x, -.298), .003, k.fill(k.white));
      }
    }

    // The facade cornice, the left tower's shadow across the wall, and the
    // finials and cross that crown the gable.
    _churchLedge(c, k, -.18, .18, -.34, rise: .014, over: .01);
    _churchRect(c, k.fill(Sketch.fade(k.deep, .3)), -.17, -.354, -.153, .5);
    if (k.fine) {
      for (final x in const [-.116, .116]) {
        c.drawCircle(Offset(x, -.375), .0065, k.fill(x < 0 ? k.trim : k.trimSide));
      }
    }
    _churchCross(c, k, 0, -.445, .034);

    _churchTower(c, k, -.245, clock: false);
    _churchTower(c, k, .245, clock: true);
    _churchTerrace(c, k, -.36, .36);

    // Doves on the cornice and rail, and three wheeling in the sunlit air.
    if (k.fine) {
      _churchPerch(c, k, -.147, -.354, .022);
      _churchPerch(c, k, .147, -.354, .022);
      _churchPerch(c, k, .25, -.657, .02);
      Sketch.bird(c, const Offset(-.405, -.46), .013, k.white, flap: .6);
      Sketch.bird(c, const Offset(-.37, -.53), .011, k.white, flap: -.2);
      Sketch.bird(c, const Offset(-.44, -.57), .012, k.white, flap: .3);
    }
  }

  static void _churchChapel(Canvas c, _ChurchKit k) {
    const fx = -.0875;
    // The dome behind the nave, with its lantern and cross.
    _churchDrum(c, k, -.1, .092, -.44, -.3, sill: -.398, spring: -.418);
    _churchLedge(c, k, -.192, -.008, -.44, split: -.054);
    _churchCupola(c, k, -.1, -.451, .098, .11, k.rich ? 7 : 5);
    _churchLantern(c, k, -.1, -.552, .016, .03);

    // The facade under a curving gable: door, oculus and a cross on the peak.
    _churchRect(c, k.fill(k.lit), -.28, -.3, .12, .5);
    if (k.rich) _churchCourses(c, k, -.28, .12, -.3, .1, .034);
    _churchRect(c, k.fill(k.trim), -.28, -.3, -.266, .5);
    final crown = _churchCrown(fx, -.3, .1925, .085);
    c.drawPath(crown, k.fill(k.trim));
    c.save();
    c.translate(fx, -.3);
    c.scale(.8, .55);
    c.translate(-fx, .3);
    c.drawPath(crown, k.fill(k.lit));
    c.restore();
    c.drawPath(_churchArch(fx, .5, .04, -.09), k.fill(k.mid));
    c.drawPath(_churchArch(fx, .5, .027, -.09), k.fill(k.dark));
    if (k.fine) {
      c.drawCircle(const Offset(fx, -.205), .027, k.fill(k.mid));
      c.drawCircle(const Offset(fx, -.205), .021, k.fill(k.trim));
      c.drawCircle(const Offset(fx, -.205), .016, k.fill(k.glass));
      c.drawCircle(const Offset(fx, -.205), .0045, k.fill(k.glow));
      _churchRect(c, k.fill(k.glint), fx - .07, -.27, fx - .058, .5);
      _churchRect(c, k.fill(k.trimSide), fx + .058, -.27, fx + .07, .5);
    }
    _churchLedge(c, k, -.28, .12, -.3);
    _churchCross(c, k, fx, -.385, .034);

    // The single belfry tower, with a bell in its arch and a tiled cupola.
    const cx = .185, hw = .08;
    const l = cx - hw, r = cx + hw, crease = cx + .037;
    const fc = (l + crease) / 2;
    _churchSplit(c, k, l, -.53, r, .5, crease, k.lit, k.side);
    _churchRect(c, k.fill(k.trim), l, -.53, l + .011, .5);
    _churchRect(c, k.fill(k.trim), crease - .009, -.53, crease, .5);
    _churchRect(c, k.fill(k.trimSide), crease, -.53, crease + .004, .5);
    _churchRect(c, k.fill(k.trimSide), r - .008, -.53, r, .5);
    _churchWindow(c, k, fc, -.12, -.2, .012);
    _churchLedge(c, k, l, r, -.3, split: crease);
    c.drawPath(_churchArch(fc, -.36, .034, -.47), k.fill(k.trim));
    c.drawPath(_churchArch(fc, -.365, .026, -.47), k.fill(k.dark));
    _churchBell(c, k, fc, -.478, .07);
    _churchRect(c, k.fill(k.trim), fc - .038, -.37, fc + .038, -.36);
    if (k.fine) c.drawPath(_churchArch(cx + .0585, -.37, .008, -.45), k.fill(k.dark));
    _churchLedge(c, k, l, r, -.53, split: crease, rise: .014, over: .009);
    if (k.fine) {
      _churchPinnacle(c, k, l + .004, -.544, .036, k.trim);
      _churchPinnacle(c, k, r - .004, -.544, .036, k.trimSide);
    }
    _churchCupola(c, k, cx, -.541, .058, .09, k.rich ? 5 : 3);
    _churchCross(c, k, cx, -.631, .05);

    _churchTerrace(c, k, -.31, .29);
    if (k.fine) {
      _churchPerch(c, k, -.2, -.312, .036);
      Sketch.bird(c, const Offset(.335, -.56), .018, k.white, flap: .5);
      Sketch.bird(c, const Offset(.305, -.63), .014, k.white, flap: -.3);
    }
  }

  /// Fired-clay tones of the hut's pots: shade, body, sunlit.
  static const _hutClay = <(Color, Color, Color)>[
    (Color(0xff86402c), Color(0xffc0653a), Color(0xffe39160)),
    (Color(0xff7a3a2a), Color(0xffb8583a), Color(0xffdc8656)),
    (Color(0xff8a5a34), Color(0xffc98a52), Color(0xffe8b07a)),
  ];

  /// An irregular patch (bare brick, fresh plaster, a stain) about ([cx], [cy])
  /// in hut units, jittered by [seed] so no two patches look alike.
  static Path _hutBlob(Offset origin, double s, double cx, double cy, double rx, double ry, int seed) {
    final xy = <double>[];
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final j = .72 + .5 * Sketch.hash(seed * 13 + i);
      xy
        ..add(cx + math.cos(a) * rx * j)
        ..add(cy + math.sin(a) * ry * j);
    }
    return Sketch.poly(xy, at: origin, s: s);
  }

  /// A round-bellied clay pot standing at [f], [h] tall. The right edge is
  /// pulled in by [kr], so nested fills at 1, .3 and a negative value read as
  /// shade, body and a sunlit band on the left.
  static Path _hutOllaPath(Offset f, double h, double w, double kr) {
    double lx(double v) => f.dx - v * w * h;
    double rx(double v) => f.dx + v * w * h * kr;
    double y(double v) => f.dy - v * h;
    return Path()
      ..moveTo(lx(.2), y(0))
      ..cubicTo(lx(.46), y(.02), lx(.5), y(.4), lx(.3), y(.66))
      ..cubicTo(lx(.2), y(.78), lx(.17), y(.82), lx(.17), y(.88))
      ..cubicTo(lx(.17), y(.93), lx(.26), y(.95), lx(.27), y(1))
      ..lineTo(rx(.27), y(1))
      ..cubicTo(rx(.26), y(.95), rx(.17), y(.93), rx(.17), y(.88))
      ..cubicTo(rx(.17), y(.82), rx(.2), y(.78), rx(.3), y(.66))
      ..cubicTo(rx(.5), y(.4), rx(.46), y(.02), rx(.2), y(0))
      ..close();
  }

  static void _hutOlla(Canvas c, Offset f, double h, double w, int tone) {
    final t = _hutClay[tone];
    c.drawPath(_hutOllaPath(f, h, w, 1), Paint()..color = t.$1);
    c.drawPath(_hutOllaPath(f, h, w, .3), Paint()..color = t.$2);
    c.drawPath(_hutOllaPath(f, h, w, -.45), Paint()..color = t.$3);
    // A painted band round the belly, curving down across the front.
    final belly = w * h * .37;
    c.drawPath(
      Path()
        ..moveTo(f.dx - belly, f.dy - h * .52)
        ..quadraticBezierTo(f.dx, f.dy - h * .4, f.dx + belly, f.dy - h * .52),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .035)
        ..color = const Color(0x66301810),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(f.dx, f.dy - h * .995), width: w * h * .48, height: h * .085),
      Paint()..color = const Color(0xff2e170f),
    );
  }

  /// A small adobe hut, lit from the left: rough plastered walls with bare
  /// brick showing through, a hipped roof of barrel tiles on rafter tails, a
  /// turquoise plank door and shutters, a window aglow, a string of drying
  /// chilies, clay pots and a stack of firewood. Units are [s], measured from
  /// the visible ground line, which sits .11 s above [base] because the ridge
  /// hides the foot of every feature.
  static void _hut(Canvas c, Offset base, double s) {
    final origin = Offset(base.dx, base.dy - s * .11);
    Offset p(double x, double y) => Offset(origin.dx + x * s, origin.dy + y * s);
    Rect box(double l, double t, double r, double b) => Rect.fromPoints(p(l, t), p(r, b));
    Path shape(List<double> xy) => Sketch.poly(xy, at: origin, s: s);
    void trace(Path path, List<double> xy) {
      final first = p(xy[0], xy[1]);
      path.moveTo(first.dx, first.dy);
      for (var i = 2; i + 1 < xy.length; i += 2) {
        final q = p(xy[i], xy[i + 1]);
        path.lineTo(q.dx, q.dy);
      }
    }

    final hair = math.max(.6, s * .008);
    Paint pen(Color color, [double? width]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width ?? hair
      ..color = color;
    final wood = Paint()..color = const Color(0xff4a2f24);

    // Firewood stacked against the left corner, its cut ends to the eye.
    c.drawPath(shape(const [-.84, .05, -.745, -.165, -.65, .05]), Paint()..color = const Color(0xff2f1c14));
    final logs = <Offset>[p(-.8, -.03), p(-.745, -.03), p(-.69, -.03), p(-.7725, -.078), p(-.7175, -.078), p(-.745, -.126)];
    final cut = Paint()..strokeCap = StrokeCap.round;
    c.drawPoints(PointMode.points, logs, cut..strokeWidth = s * .06..color = const Color(0xff7a4c2c));
    c.drawPoints(PointMode.points, logs, cut..strokeWidth = s * .046..color = const Color(0xffcf9c62));
    c.drawPoints(PointMode.points, logs, cut..strokeWidth = s * .016..color = const Color(0xff9a6a3e));

    // Walls: the front takes the light, the right-hand side falls into shade.
    final front = box(-.6, -.46, .32, .11);
    c.drawRRect(
      RRect.fromRectAndRadius(front, Radius.circular(s * .012)),
      Paint()..shader = Gradient.linear(front.topLeft, front.topRight, const [Color(0xfff2c99e), Color(0xffdcaa7e)]),
    );
    c.drawPath(
      shape(const [.32, -.46, .6, -.495, .6, .06, .32, .11]),
      Paint()..shader = Gradient.linear(p(.32, 0), p(.6, 0), const [Color(0xffb98060), Color(0xff98694f)]),
    );

    // Rough plaster: bare brick where it has fallen, fresh whitewash, cracks.
    final brick = Paint()..color = const Color(0xffc48a5c);
    c.drawPath(_hutBlob(origin, s, -.4, -.055, .09, .045, 1), brick);
    c.drawPath(_hutBlob(origin, s, .29, -.16, .026, .075, 2), brick);
    final seams = Path();
    for (var row = 0; row < 3; row++) {
      final y = -.08 + row * .03;
      trace(seams, [-.47, y, -.33, y]);
      for (var k = 0; k < 3; k++) {
        final x = -.45 + k * .05 + (row.isEven ? .025 : 0.0);
        trace(seams, [x, y, x, y + .03]);
      }
    }
    c.drawPath(seams, pen(const Color(0x59603a26)));
    c.drawPath(_hutBlob(origin, s, -.2, -.07, .09, .03, 3), Paint()..color = const Color(0x66fbe6c4));
    c.drawPath(_hutBlob(origin, s, .12, -.24, .05, .03, 4), Paint()..color = const Color(0x40fbe6c4));
    // A rain streak below the sill, and a plinth splashed with earth.
    c.drawRect(box(-.44, -.105, -.39, -.02), Paint()..color = const Color(0x1f502a1c));
    c.drawPath(
      shape(const [-.6, .11, -.6, -.06, -.5, -.075, -.38, -.05, -.22, -.08, -.05, -.055, .1, -.085, .22, -.06, .32, -.075, .32, .11]),
      Paint()..color = const Color(0x66a06a44),
    );
    final cracks = Path();
    trace(cracks, [-.5, -.13, -.515, -.09, -.5, -.06, -.52, -.03]);
    trace(cracks, [.23, -.35, .25, -.31, .245, -.27, .27, -.22]);
    c.drawPath(cracks, pen(const Color(0x73603a26)));

    // The shaded wall: a dim shuttered window, patches and its own plinth.
    c.drawPath(shape(const [.4, -.31, .52, -.325, .52, -.175, .4, -.16]), Paint()..color = const Color(0xff3a2418));
    c.drawPath(shape(const [.395, -.16, .525, -.175, .525, -.15, .395, -.135]), Paint()..color = const Color(0xffc99a76));
    final shutSeam = Path();
    trace(shutSeam, [.46, -.3175, .46, -.1675]);
    trace(shutSeam, [.4, -.235, .52, -.25]);
    c.drawPath(shutSeam, pen(const Color(0xff6a4028)));
    c.drawPath(_hutBlob(origin, s, .46, -.06, .06, .04, 5), Paint()..color = const Color(0x33502a1c));
    c.drawPath(shape(const [.32, .11, .32, -.065, .46, -.07, .6, -.035, .6, .06]), Paint()..color = const Color(0x59784a30));

    // The corner rounds off into shade; the left edge catches the sun.
    c.drawRect(
      box(.27, -.46, .32, .11),
      Paint()..shader = Gradient.linear(p(.27, 0), p(.32, 0), const [Color(0x00a06a48), Color(0x88a06a48)]),
    );
    c.drawRect(box(-.6, -.46, -.585, .11), Paint()..color = const Color(0x88fbe2b8));

    // The eave throws a band of shadow, and rafter tails poke out under it.
    c.drawRect(
      box(-.6, -.42, .32, -.3),
      Paint()..shader = Gradient.linear(p(0, -.42), p(0, -.3), const [Color(0x73401c14), Color(0x00401c14)]),
    );
    c.drawPath(shape(const [.32, -.42, .4, -.42, .6, -.4557, .6, -.36, .32, -.33]), Paint()..color = const Color(0x40401c14));
    final tail = Paint()..color = const Color(0xff55331f);
    for (var k = 0; k < 9; k++) {
      final x = -.56 + k * .1;
      c.drawRect(box(x - .011, -.385, x + .011, -.35), tail);
    }

    // The window's warm light spills over the plaster before its own frame.
    c.save();
    c.clipRect(front);
    c.drawCircle(
      p(-.42, -.215),
      s * .27,
      Paint()..shader = Gradient.radial(p(-.42, -.215), s * .27, const [Color(0x66ffc060), Color(0x00ffb040)]),
    );
    c.restore();
    c.drawRect(box(-.52, -.325, -.32, -.3), wood);
    c.drawRect(box(-.5, -.3, -.34, -.13), Paint()..color = const Color(0xff3a2418));
    final glow = box(-.485, -.285, -.355, -.145);
    c.drawRect(
      glow,
      Paint()
        ..shader = Gradient.radial(glow.center, s * .1, const [Color(0xfffff2b8), Color(0xffffc65a), Color(0xffe8902c)], const [0, .5, 1]),
    );
    c.drawRect(box(-.485, -.285, -.355, -.265), Paint()..color = const Color(0x66301810));
    c.drawLine(p(-.42, -.285), p(-.42, -.145), pen(const Color(0xff6a4028)));
    c.drawLine(p(-.485, -.215), p(-.355, -.215), pen(const Color(0xff6a4028)));
    c.drawRect(box(-.515, -.13, -.325, -.105), Paint()..color = const Color(0xfff0cfa0));
    c.drawRect(box(-.515, -.105, -.325, -.09), Paint()..color = const Color(0x40401c14));
    void shutter(double l, double r) {
      c.drawRect(box(l, -.3, r, -.13), Paint()..color = const Color(0xff2f8f9c));
      final slats = Path();
      for (final y in const [-.25, -.215, -.18]) {
        trace(slats, [l, y, r, y]);
      }
      c.drawPath(slats, pen(const Color(0x66104a56)));
      c.drawRect(box(l, -.3, l + .008, -.13), Paint()..color = const Color(0x55ffffff));
    }

    shutter(-.582, -.505);
    shutter(-.335, -.258);

    // A plank door in turquoise gone chalky, on a worn stone step.
    c.drawRect(box(0, -.35, .23, .11), wood);
    const planks = [Color(0xff3a9aa6), Color(0xff328f9c), Color(0xff2b8290), Color(0xff247484)];
    for (var k = 0; k < 4; k++) {
      c.drawRect(box(.015 + k * .05, -.335, .015 + (k + 1) * .05 - .004, .11), Paint()..color = planks[k]);
    }
    c.drawPath(
      shape(const [.015, .11, .015, -.02, .05, -.045, .09, -.015, .14, -.05, .18, -.02, .215, -.04, .215, .11]),
      Paint()..color = const Color(0x886a4028),
    );
    final batten = Paint()..color = const Color(0x881f5560);
    c.drawRect(box(.015, -.27, .215, -.245), batten);
    c.drawRect(box(.015, -.075, .215, -.05), batten);
    c.drawLine(p(.03, -.06), p(.2, -.26), pen(const Color(0x881f5560), s * .022));
    final iron = Paint()..color = const Color(0xff2a1e1a);
    c.drawRect(box(.015, -.315, .07, -.3), iron);
    c.drawRect(box(.015, -.1, .07, -.085), iron);
    c.drawCircle(p(.185, -.15), s * .013, iron);
    c.drawCircle(p(.182, -.153), s * .005, Paint()..color = const Color(0xff9a8a70));
    c.drawRect(box(-.04, -.03, .27, .06), Paint()..color = const Color(0xffcf9f6e));
    c.drawRect(box(-.04, -.03, .27, -.02), Paint()..color = const Color(0xffe8c290));

    // A ristra of drying chilies hangs beside the door.
    final red = Path(), deep = Path(), sheen = Path();
    final caps = <Offset>[];
    void chili(Path path, double x, double y, double side) {
      final a = p(x - .014, y), b = p(x - .02, y + .04), t = p(x + side * .008, y + .08);
      final d = p(x + .02, y + .04), e = p(x + .014, y);
      path
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(b.dx, b.dy, t.dx, t.dy)
        ..quadraticBezierTo(d.dx, d.dy, e.dx, e.dy)
        ..close();
    }

    for (var i = 0; i < 7; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final x = .275 + side * .014, y = -.335 + i * .033;
      chili(i % 3 == 2 ? deep : red, x, y, side);
      trace(sheen, [x - .008, y + .012, x - .008 + side * .003, y + .05]);
      caps.add(p(x, y));
    }
    c.drawLine(p(.275, -.35), p(.275, -.115), pen(const Color(0xff6a4a30), s * .012));
    c.drawPath(red, Paint()..color = const Color(0xffc22a2a));
    c.drawPath(deep, Paint()..color = const Color(0xff8a1a22));
    c.drawPath(sheen, pen(const Color(0x99ff9a80)));
    c.drawPoints(
      PointMode.points,
      caps,
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * .02
        ..color = const Color(0xff4d6a2a),
    );

    // Clay pots along the wall.
    _hutOlla(c, p(-.555, .02), s * .17, .9, 0);
    _hutOlla(c, p(-.25, .02), s * .11, .9, 1);
    _hutOlla(c, p(-.12, .02), s * .19, .8, 2);

    // The hipped roof of barrel tiles: a sunlit front slope, a shaded end.
    c.drawPath(
      shape(const [.4, -.42, .24, -.8, .68, -.47]),
      Paint()..shader = Gradient.linear(p(.4, 0), p(.68, 0), const [Color(0xff8e3a2c), Color(0xff74301f)]),
    );
    c.drawPath(
      shape(const [-.7, -.42, -.26, -.8, .24, -.8, .4, -.42]),
      Paint()
        ..shader = Gradient.linear(p(-.7, 0), p(.4, 0), const [Color(0xffd4694a), Color(0xffbf5038), Color(0xffa8402f)], const [0, .5, 1]),
    );
    double roofTop(double x) {
      if (x < -.26) return -.42 - (x + .7) / .44 * .38;
      if (x > .24) return -.42 - (.4 - x) / .16 * .38;
      return -.8;
    }

    final valley = Path(), crest = Path();
    for (var x = -.64; x < .37; x += .075) {
      trace(valley, [x, -.42, x, roofTop(x)]);
      trace(crest, [x + .02, -.42, x + .02, roofTop(x + .02)]);
    }
    for (var k = 1; k < 5; k++) {
      trace(valley, [.24, -.8, .4 + .28 * k / 5, -.42 - .05 * k / 5]);
    }
    for (final y in const [-.5, -.58, -.66, -.74]) {
      final t = (-.42 - y) / .38;
      trace(valley, [-.7 + .44 * t, y, .4 - .16 * t, y]);
    }
    c.drawPath(valley, pen(const Color(0x40501c16)));
    c.drawPath(crest, pen(const Color(0x40f4a680)));
    c.drawPath(_hutBlob(origin, s, -.42, -.56, .06, .03, 6), Paint()..color = const Color(0x40f0a878));
    c.drawPath(_hutBlob(origin, s, .05, -.68, .07, .03, 7), Paint()..color = const Color(0x40501c16));
    c.drawPath(_hutBlob(origin, s, .2, -.52, .05, .025, 8), Paint()..color = const Color(0x38f0a878));
    c.drawPath(_hutBlob(origin, s, -.15, -.5, .05, .02, 9), Paint()..color = const Color(0x38501c16));
    // The eave's thick lip, dark under the overhang, and the ridge and hip caps.
    c.drawPath(shape(const [-.7, -.42, .4, -.42, .4, -.385, -.7, -.385]), Paint()..color = const Color(0xff7a3026));
    c.drawPath(shape(const [.4, -.42, .68, -.47, .68, -.435, .4, -.385]), Paint()..color = const Color(0xff5e2419));
    c.drawLine(p(-.7, -.42), p(.4, -.42), pen(const Color(0x66f4a878)));
    final cap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final hips = Path();
    trace(hips, [-.7, -.42, -.26, -.8]);
    trace(hips, [.4, -.42, .24, -.8]);
    trace(hips, [.24, -.8, .68, -.47]);
    c.drawPath(hips, cap..strokeWidth = s * .03..color = const Color(0xff8a3a2c));
    c.drawLine(p(-.28, -.8), p(.26, -.8), cap..strokeWidth = s * .052..color = const Color(0xff8a3a2c));
    c.drawLine(p(-.28, -.815), p(.26, -.815), cap..strokeWidth = s * .022..color = const Color(0xffe07e5a));
  }

  // ---- Desert flora of the low band: agaves, saguaros and organ pipes.
  // Every form is a few nested fills stepped toward the sun on the left.

  static Offset _floraQ(Offset a, Offset b, Offset e, double u) =>
      a * ((1 - u) * (1 - u)) + b * (2 * (1 - u) * u) + e * (u * u);

  /// A cactus stem or arm along [p], [w] wide: a shade tube with body and
  /// light bands stepped up and left of it, rib grooves that follow the stem
  /// and a warm sheen of spines on the lit edge. [diag] tilts those steps so a
  /// horizontal reach is lit from above rather than from the side.
  static void _floraTube(Canvas c, Path p, double w, Color shade, Color body, Color lit, {double diag = .6}) {
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(p, pen..strokeWidth = w..color = shade);
    c.drawPath(p.shift(Offset(-w * .11, -w * .11 * diag)), pen..strokeWidth = w * .78..color = body);
    c.drawPath(p.shift(Offset(-w * .21, -w * .21 * diag)), pen..strokeWidth = w * .4..color = lit);
    final ribs = Path();
    for (final k in const [-.35, -.13, .13, .35]) {
      ribs.addPath(p, Offset(w * k, w * k * diag));
    }
    c.drawPath(ribs, pen..strokeWidth = math.max(.6, w * .04)..color = const Color(0x5a123a2a));
    c.drawPath(p.shift(Offset(-w * .43, -w * .43 * diag)), pen..strokeWidth = math.max(.6, w * .07)..color = const Color(0x8ce8d9a0));
  }

  /// Saguaro arms as (attach height, reach, tip height, width): each leaves the
  /// trunk sideways, elbows and climbs. Negative reach is to the left.
  static const _floraArmsA = <(double, double, double, double)>[
    (-.5, .24, -.82, .085),
    (-.3, -.2, -.6, .08),
    (-.72, -.12, -.86, .06),
  ];
  static const _floraArmsB = <(double, double, double, double)>[
    (-.46, -.22, -.74, .085),
    (-.62, .17, -.88, .07),
    (-.28, .16, -.44, .06),
  ];

  /// A saguaro: a ribbed trunk crowned in cream blossom, with elbowed arms,
  /// a woodpecker's hole and beads of spines along the rib crests. [flip]
  /// mirrors the arm layout (the light still comes from the left).
  static void _floraSaguaro(Canvas c, Offset base, double s, {double flip = 1}) {
    const shade = Color(0xff2b5a44), body = Color(0xff3f7a4a), lit = Color(0xff74ad5e);
    Offset q(double x, double y) => Offset(base.dx + x * s, base.dy + y * s);
    final blooms = <Offset>[q(0, -1)];
    final arms = flip > 0 ? _floraArmsA : _floraArmsB;
    for (final (y0, reach, tipY, wr) in arms) {
      final r = reach * flip;
      final a = q(r * .12, y0 + .03), b = q(r * .55, y0 + .03), e = q(r, y0 + .03);
      final f = q(r, y0 - .07), g = q(r, tipY + wr / 2);
      final arm = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(b.dx, b.dy, e.dx, e.dy, f.dx, f.dy)
        ..lineTo(g.dx, g.dy);
      _floraTube(c, arm, wr * s, shade, body, lit);
      blooms.add(q(r, tipY));
    }
    final trunk = Path()
      ..moveTo(base.dx, base.dy + s * .04)
      ..lineTo(base.dx, base.dy - s * .935);
    _floraTube(c, trunk, s * .13, shade, body, lit, diag: 0);
    final beads = <Offset>[
      for (var k = 0; k < 19; k++)
        for (final x in const [-.031, 0.0, .031]) q(x, -.06 - k * .045),
    ];
    c.drawPoints(
      PointMode.points,
      beads,
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, s * .011)
        ..color = const Color(0x61f0e6b0),
    );
    final hole = Rect.fromCenter(center: q(.006, -.63), width: s * .024, height: s * .034);
    c.drawOval(hole.inflate(s * .005), Paint()..color = const Color(0x66d9c98a));
    c.drawOval(hole, Paint()..color = const Color(0xff1c2a22));
    final bloom = <Offset>[];
    for (final o in blooms) {
      for (final (dx, dy) in const [(-.022, .008), (.02, -.004), (-.002, -.026)]) {
        bloom.add(o + Offset(dx * s, dy * s));
      }
    }
    final dab = Paint()..strokeCap = StrokeCap.round;
    c.drawPoints(PointMode.points, bloom, dab..strokeWidth = math.max(1.4, s * .04)..color = const Color(0xfff8f0d8));
    c.drawPoints(PointMode.points, bloom, dab..strokeWidth = math.max(.8, s * .016)..color = const Color(0xfff0c040));
  }

  /// Organ-pipe stems as (base x, tip x, tip height, low bend, low rise, width).
  static const _floraPipes = <(double, double, double, double, double, double)>[
    (-.06, -.46, -.4, .65, .05, .095),
    (.06, .48, -.46, .65, .05, .095),
    (-.04, -.3, -.7, .4, .15, .1),
    (.05, .3, -.8, .4, .15, .1),
    (-.02, -.14, -.95, .15, .35, .105),
    (.02, .12, -.99, .15, .35, .105),
    (0.0, 0.0, -.8, 0.0, .5, .11),
  ];

  /// An organ-pipe cactus: stems that splay from one root, curve up and stand
  /// straight, each with its own ribs, the tallest wearing pale night flowers.
  static void _floraOrgan(Canvas c, Offset base, double s) {
    const shade = Color(0xff2d5a48), body = Color(0xff447f52), lit = Color(0xff78b06a);
    Offset q(double x, double y) => Offset(base.dx + x * s, base.dy + y * s);
    final blooms = <Offset>[];
    for (final (x0, tx, ty, k1, h1, wr) in _floraPipes) {
      final a = q(x0, .05), b = q(x0 + (tx - x0) * k1, ty * h1), e = q(tx, ty * .62), f = q(tx, ty + wr / 2);
      final pipe = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(b.dx, b.dy, e.dx, e.dy, f.dx, f.dy);
      _floraTube(c, pipe, wr * s, shade, body, lit, diag: .3);
      if (ty < -.75) blooms.add(q(tx + .02, ty + .05));
    }
    final dab = Paint()..strokeCap = StrokeCap.round;
    c.drawPoints(PointMode.points, blooms, dab..strokeWidth = math.max(1.4, s * .05)..color = const Color(0xffefd0da));
    c.drawPoints(PointMode.points, blooms, dab..strokeWidth = math.max(.8, s * .02)..color = const Color(0xffb0507a));
  }

  /// Agave leaves as (angle from vertical, length, droop, width, layer): the
  /// back and side layers arch out of the rosette and the short front layer
  /// tucks toward the eye, all around one crown.
  static const _floraLeaves = <(double, double, double, double, int)>[
    (-1.05, .7, .1, .11, 0),
    (-.62, .8, .04, .11, 0),
    (-.2, .86, 0.0, .11, 0),
    (.22, .86, 0.0, .11, 0),
    (.62, .8, .04, .11, 0),
    (1.05, .7, .1, .11, 0),
    (-1.55, .85, .36, .12, 1),
    (-1.2, .8, .18, .12, 1),
    (-.75, .74, .05, .12, 1),
    (.75, .74, .05, .12, 1),
    (1.2, .8, .18, .12, 1),
    (1.55, .85, .36, .12, 1),
    (-2.05, .5, 0.0, .14, 2),
    (-2.6, .34, 0.0, .14, 2),
    (2.05, .5, 0.0, .14, 2),
    (2.6, .34, 0.0, .14, 2),
    (3.14, .24, 0.0, .17, 2),
  ];

  /// Shade, sunlit and outline colours of the back, side and front layers.
  static const _floraTones = <(Color, Color, Color)>[
    (Color(0xff2f5f66), Color(0xff45807f), Color(0xff21474f)),
    (Color(0xff42807f), Color(0xff6ba89f), Color(0xff2c5f63)),
    (Color(0xff579a92), Color(0xff93c9b0), Color(0xff2f6b6c)),
  ];

  /// One agave leaf as a curved almond from [r] to a spined tip, split along
  /// its midrib into a sunlit half ([lit], the side facing up-left) and a
  /// shaded one; [edge] and [rib] collect its outline and midrib, [spines] the
  /// terminal needle and [teeth] (front leaves only) the marginal thorns.
  static void _floraLeaf(
    Path lit,
    Path shade,
    Path edge,
    Path rib,
    Path? teeth,
    Path spines,
    Offset r,
    double a,
    double len,
    double droop,
    double wide,
    double s,
  ) {
    final dir = Offset(math.sin(a), -math.cos(a));
    final tip = r + dir * len + Offset(0, droop * len);
    final k = r + dir * (len * .55) + Offset(0, -len * .16 * math.sin(a).abs());
    final chord = tip - r;
    final cd = chord / chord.distance;
    var n = Offset(-cd.dy, cd.dx);
    if (n.dx * -.55 + n.dy * -.83 < 0) n = -n;
    final hw = len * wide;
    final kl = k + n * (hw * 2), kd = k - n * (hw * 2);
    lit
      ..moveTo(r.dx, r.dy)
      ..quadraticBezierTo(kl.dx, kl.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(k.dx, k.dy, r.dx, r.dy)
      ..close();
    shade
      ..moveTo(r.dx, r.dy)
      ..quadraticBezierTo(kd.dx, kd.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(k.dx, k.dy, r.dx, r.dy)
      ..close();
    edge
      ..moveTo(r.dx, r.dy)
      ..quadraticBezierTo(kl.dx, kl.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(kd.dx, kd.dy, r.dx, r.dy);
    rib
      ..moveTo(r.dx, r.dy)
      ..quadraticBezierTo(k.dx, k.dy, tip.dx, tip.dy);
    final tt = tip - k;
    final td = tt / tt.distance;
    final tn = Offset(-td.dy, td.dx);
    final foot = tip - td * (s * .03), apex = tip + td * (s * .07);
    spines
      ..moveTo(foot.dx + tn.dx * s * .012, foot.dy + tn.dy * s * .012)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(foot.dx - tn.dx * s * .012, foot.dy - tn.dy * s * .012)
      ..close();
    if (teeth == null) return;
    for (final side in const [1.0, -1.0]) {
      final ctl = k + n * (hw * 2 * side);
      for (final u in const [.28, .4, .52, .64, .76]) {
        final p0 = _floraQ(r, ctl, tip, u - .04), p1 = _floraQ(r, ctl, tip, u + .04);
        final hook = _floraQ(r, ctl, tip, u) + n * (side * s * .036) - cd * (s * .014);
        teeth
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(hook.dx, hook.dy)
          ..lineTo(p1.dx, p1.dy)
          ..close();
      }
    }
  }

  /// The furled young leaves standing in the heart of the rosette.
  static void _floraSpear(Canvas c, Offset center, double s) {
    c.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * .02), width: s * .5, height: s * .2),
      Paint()..color = const Color(0x731d4046),
    );
    final lit = Path(), shade = Path(), edge = Path(), rib = Path(), spines = Path();
    for (final (a, len, w) in const [(-.16, .62, .085), (.14, .58, .085), (.0, .8, .075)]) {
      _floraLeaf(lit, shade, edge, rib, null, spines, center + Offset(a * s * .12, -s * .02), a, len * s, 0.0, w, s);
    }
    c.drawPath(shade, Paint()..color = const Color(0xff6ea898));
    c.drawPath(lit, Paint()..color = const Color(0xffb0dabc));
    c.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, s * .01)
        ..color = const Color(0xff3d7a76),
    );
    c.drawPath(spines, Paint()..color = const Color(0xff5c3f30));
  }

  /// A flowering quiote: a tall bracted stalk from the crown carrying a
  /// candelabra of branches that end in clusters of yellow flowers.
  static void _floraQuiote(Canvas c, Offset root, double s, int seed) {
    final lean = (Sketch.hash(seed + 90) - .5) * .5;
    final top = root + Offset(lean * s, -s * 2.3);
    final ctl = root + Offset(0, -s * 1.3);
    Offset at(double u) => _floraQ(root, ctl, top, u);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final stalk = Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(ctl.dx, ctl.dy, top.dx, top.dy);
    c.drawPath(stalk, pen..strokeWidth = s * .05..color = const Color(0xff66703f));
    c.drawPath(stalk.shift(Offset(-s * .011, 0)), pen..strokeWidth = s * .026..color = const Color(0xff9aa057));
    final bracts = Path();
    for (var k = 0; k < 6; k++) {
      final o = at(.14 + .08 * k);
      final side = k.isEven ? -1.0 : 1.0;
      bracts
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + side * s * .09, o.dy - s * .1);
    }
    c.drawPath(bracts, pen..strokeWidth = math.max(.6, s * .02)..color = const Color(0xff6a7844));
    final branches = Path();
    final flowers = <Offset>[];
    for (var k = 0; k < 8; k++) {
      final side = k.isEven ? -1.0 : 1.0;
      final len = s * (.5 - .04 * k);
      final o = at(.58 + .05 * k);
      final e = o + Offset(side * len, -len * .5 - s * .12);
      final b = o + Offset(side * len * .7, s * .01);
      branches
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(b.dx, b.dy, e.dx, e.dy);
      flowers
        ..add(e)
        ..add(e + Offset(side * s * .05, s * .04))
        ..add(e + Offset(-side * s * .035, s * .05))
        ..add(_floraQ(o, b, e, .6) + Offset(0, -s * .02));
    }
    flowers
      ..add(top)
      ..add(top + Offset(s * .03, s * .05))
      ..add(top + Offset(-s * .03, s * .05));
    c.drawPath(branches, pen..strokeWidth = math.max(.7, s * .022)..color = const Color(0xff7e8a48));
    final dab = Paint()..strokeCap = StrokeCap.round;
    c.drawPoints(PointMode.points, flowers, dab..strokeWidth = s * .1..color = const Color(0xffcbbd3e));
    c.save();
    c.translate(-s * .014, -s * .014);
    c.drawPoints(PointMode.points, flowers, dab..strokeWidth = s * .055..color = const Color(0xfff4e67c));
    c.restore();
  }

  /// A blue agave, [s] tall: a rosette of stiff, glaucous, spined leaves in
  /// three layers round a furled spear, with a flowering quiote if asked.
  static void _floraAgave(Canvas c, Offset base, double s, int seed, {bool quiote = false}) {
    final center = base + Offset(0, -s * .5);
    if (quiote) _floraQuiote(c, center, s, seed);
    for (var layer = 0; layer < 3; layer++) {
      if (layer == 2) _floraSpear(c, center, s);
      final lit = Path(), shade = Path(), edge = Path(), rib = Path(), teeth = Path(), spines = Path();
      for (var i = 0; i < _floraLeaves.length; i++) {
        final (a, len, droop, wide, l) = _floraLeaves[i];
        if (l != layer) continue;
        final root = center + Offset(math.sin(a) * s * .06, -math.cos(a) * s * .03);
        final ang = a + (Sketch.hash(seed * 31 + i) - .5) * .14;
        final size = len * (.93 + .14 * Sketch.hash(seed * 17 + i + 5)) * s;
        _floraLeaf(lit, shade, edge, rib, layer == 2 ? teeth : null, spines, root, ang, size, droop, wide, s);
      }
      final (deep, light, line) = _floraTones[layer];
      c.drawPath(shade, Paint()..color = deep);
      c.drawPath(lit, Paint()..color = light);
      final pen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(.6, s * .012)
        ..color = line;
      c.drawPath(edge, pen);
      if (layer > 0) c.drawPath(rib, pen..strokeWidth = math.max(.5, s * .008)..color = const Color(0x40dff2d0));
      c.drawPath(teeth, Paint()..color = const Color(0xe67a5238));
      c.drawPath(spines, Paint()..color = const Color(0xff5c3f30));
    }
  }

  /// Where the marigold clumps stand on the near ground: (x as a fraction of
  /// the period, size). Their painting, drifting petals and ground shadows
  /// all read this list.
  static const _mgSpots = [(.22, 1.0), (.3, .8), (.8, .9)];

  static const _mgPetalTones = [Color(0xfff6a21b), Color(0xffe8870f), Color(0xffffc247)];

  /// Ring colours of a bloom, outer skirt to inner whorl, then its dark eye.
  static const _mgPalettes = [
    (Color(0xfff29a18), Color(0xffdb7410), Color(0xfff5a625), Color(0xffd97a12), Color(0xff7c3a0e)),
    (Color(0xfff8b420), Color(0xffe8920f), Color(0xffffc73a), Color(0xffeba020), Color(0xff8a4a0e)),
    (Color(0xffe8800f), Color(0xffc4600a), Color(0xfff09a1c), Color(0xffc86a0e), Color(0xff6e300c)),
  ];

  /// Head [i] of clump [seed] as (dx, dy, radius) in clump sizes above the
  /// base, ordered back to front. Odd clumps are mirrored.
  static (double, double, double) _mgHead(int seed, int i) {
    const layout = [
      (-.12, -.88, .23),
      (.3, -.66, .2),
      (-.5, -.55, .2),
      (.58, -.4, .17),
      (.04, -.4, .16),
    ];
    final (dx, dy, r) = layout[i];
    final j = seed * 31 + i * 7;
    return (
      (seed.isOdd ? -dx : dx) + (Sketch.hash(j + 800) - .5) * .1,
      dy + (Sketch.hash(j + 801) - .5) * .09,
      r * (.92 + .16 * Sketch.hash(j + 802)),
    );
  }

  /// A leaf angle mirrored across the vertical when [flip] is negative.
  static double _mgFlip(double a, double flip) => flip < 0 ? math.pi - a : a;

  /// Bezier handles of a stem that leaves its root upright and reaches its
  /// bloom leaning a little to the bloom's side.
  static (Offset, Offset) _mgCtl(Offset root, Offset head) => (
    Offset(root.dx + (head.dx - root.dx) * .1, root.dy + (head.dy - root.dy) * .55),
    Offset(head.dx - (head.dx - root.dx) * .22, head.dy + (root.dy - head.dy) * .32),
  );

  static Path _mgStemPath(Offset root, Offset head) {
    final (c1, c2) = _mgCtl(root, head);
    return Path()
      ..moveTo(root.dx, root.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, head.dx, head.dy);
  }

  /// The point a fraction [u] up the stem from [root] to [head].
  static Offset _mgOn(Offset root, Offset head, double u) {
    final (c1, c2) = _mgCtl(root, head);
    final v = 1 - u;
    return root * (v * v * v) + c1 * (3 * v * v * u) + c2 * (3 * v * u * u) + head * (u * u * u);
  }

  /// How far a bloom tilts from upright so it sits square on its stem end.
  static double _mgTilt(Offset root, Offset head) => math.atan2((head.dx - root.dx) * .22, (root.dy - head.dy) * .32);

  static double _mgNotch(int seed, int i, double notch) => notch * (.9 + .2 * Sketch.hash(seed + i));

  static double _mgPeak(int seed, int i) => .94 + .12 * Sketch.hash(seed + 50 + i);

  /// A unit ring of [n] rounded petals with a cusp between neighbours, each
  /// petal a little different in reach.
  static Path _mgRuffPath(int n, int seed, double notch) {
    final path = Path();
    final da = math.pi * 2 / n;
    Offset at(double r, double a) => Offset(math.cos(a) * r, math.sin(a) * r);
    final start = at(_mgNotch(seed, 0, notch), 0);
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final a0 = i * da, a1 = a0 + da;
      final reach = _mgPeak(seed, i) * 1.16;
      final c1 = at(reach, a0 + da * .1), c2 = at(reach, a1 - da * .1);
      final end = at(_mgNotch(seed, (i + 1) % n, notch), a1);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    }
    return path..close();
  }

  /// A groove down the middle of each petal of a [_mgRuffPath] ring.
  static Path _mgCreasePath(int n, int seed, double notch) {
    final path = Path();
    final da = math.pi * 2 / n;
    for (var i = 0; i < n; i++) {
      final a = (i + .5) * da + (Sketch.hash(seed + 90 + i) - .5) * da * .3;
      final cs = math.cos(a), sn = math.sin(a);
      final r0 = notch * .85, r1 = _mgPeak(seed, i) * .9;
      path
        ..moveTo(cs * r0, sn * r0)
        ..lineTo(cs * r1, sn * r1);
    }
    return path;
  }

  static final _mgRuff0 = _mgRuffPath(10, 810, .6);
  static final _mgRuff1 = _mgRuffPath(8, 830, .6);
  static final _mgRuff2 = _mgRuffPath(7, 850, .6);
  static final _mgRuff3 = _mgRuffPath(5, 870, .6);
  static final _mgCrease0 = _mgCreasePath(10, 810, .6);
  static final _mgCrease1 = _mgCreasePath(8, 830, .6);
  static final _mgCrease2 = _mgCreasePath(7, 850, .6);

  /// The green cup under a bloom, in bloom radii, stem end towards +y.
  static final _mgCalyx = Path()
    ..moveTo(-.5, .5)
    ..quadraticBezierTo(-.55, 1.05, -.13, 1.34)
    ..lineTo(.13, 1.34)
    ..quadraticBezierTo(.55, 1.05, .5, .5)
    ..close();
  static final _mgCalyxLit = Path()
    ..moveTo(-.5, .5)
    ..quadraticBezierTo(-.55, 1.05, -.13, 1.34)
    ..lineTo(-.03, 1.34)
    ..quadraticBezierTo(-.24, 1.02, -.16, .5)
    ..close();

  /// One ray petal, narrow at its foot (-1) and rounded and notched at its
  /// tip (+1), a unit long each way.
  static final _mgPetal = Path()
    ..moveTo(-1, 0)
    ..cubicTo(-.6, -.5, .2, -.85, .75, -.55)
    ..quadraticBezierTo(1.02, -.3, .86, -.02)
    ..quadraticBezierTo(1.0, .3, .7, .55)
    ..cubicTo(.2, .85, -.6, .5, -1, 0)
    ..close();

  /// A pinnate, serrated marigold leaf one unit long along +x, its rachis
  /// drooping towards +y. [side] picks both rows of leaflets (0), the upper
  /// row (-1) or the lower row (1), so a lit row can be laid over the dark.
  static Path _mgLeafPath(int side) {
    const teeth = [(.12, .5), (.2, .3), (.36, .95), (.46, .55), (.62, .85), (.72, .45), (.86, .4)];
    const droop = .16;
    final path = Path();
    void leaflet(double ox, double oy, double ang, double len) {
      final ca = math.cos(ang), sa = math.sin(ang), wid = len * .2;
      Offset at(double x, double y) => Offset(ox + x * len * ca - y * wid * sa, oy + x * len * sa + y * wid * ca);
      final root = at(0, 0);
      path.moveTo(root.dx, root.dy);
      for (final (x, y) in teeth) {
        final p = at(x, -y);
        path.lineTo(p.dx, p.dy);
      }
      final tip = at(1, 0);
      path.lineTo(tip.dx, tip.dy);
      for (final (x, y) in teeth.reversed) {
        final p = at(x, y);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
    }

    for (var i = 0; i < 5; i++) {
      final u = .1 + i * .17;
      final phi = math.atan(2 * droop * u);
      if (side <= 0) leaflet(u, droop * u * u, phi - 1.0, .3 - i * .032);
      if (side >= 0) leaflet(u, droop * u * u, phi + 1.0, .3 - i * .032);
    }
    leaflet(1, droop, math.atan(2 * droop), .2);
    final lo = side > 0 ? 0.0 : -.022, hi = side < 0 ? 0.0 : .022;
    path.moveTo(0, lo);
    for (var k = 1; k <= 8; k++) {
      final u = k / 8;
      path.lineTo(u, droop * u * u + lo);
    }
    for (var k = 8; k >= 0; k--) {
      final u = k / 8;
      path.lineTo(u, droop * u * u + hi);
    }
    return path..close();
  }

  static final _mgLeafUp = _mgLeafPath(-1);
  static final _mgLeafLow = _mgLeafPath(1);

  /// A leaf rooted at [at], [len] long, pointing along [angle] and drooping
  /// with gravity. Its leaflets on the sun's side (left, and up) glow.
  static void _mgLeafAt(Canvas c, Offset at, double angle, double len, Color dark, Color lit) {
    final sy = math.cos(angle) >= 0 ? 1.0 : -1.0;
    final facing = -math.sin(angle) * sy * .9 + math.cos(angle) * sy * .4;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    c.scale(len, len * sy);
    // The shaded row first, the sunlit row over it.
    final upperLit = facing >= 0;
    c.drawPath(upperLit ? _mgLeafLow : _mgLeafUp, Paint()..color = dark);
    c.drawPath(upperLit ? _mgLeafUp : _mgLeafLow, Paint()..color = lit);
    c.restore();
  }

  /// One marigold head of radius [r] at [p]: a green calyx, then four rings
  /// of ruffled petals that climb towards the sun in a dome, and a dark eye.
  /// [tilt] squares the calyx to the stem and [spin] varies the petals.
  static void _mgBloom(Canvas c, Offset p, double r, double tilt, int pal, double spin) {
    final (o0, o1, o2, o3, core) = _mgPalettes[pal % _mgPalettes.length];
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // The head shades the leaves behind it.
    c.drawCircle(p + Offset(r * .12, r * .16), r * .98, fill..color = const Color(0x301a3a2a));
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(tilt);
    c.scale(r, r);
    c.drawPath(_mgCalyx, fill..color = const Color(0xff2c5e38));
    c.drawPath(_mgCalyxLit, fill..color = const Color(0xff70a84c));
    c.restore();
    void ring(Path shape, Path? crease, double sc, Offset off, double turn, Color color) {
      c.save();
      c.translate(p.dx + off.dx * r, p.dy + off.dy * r);
      c.rotate(spin * turn);
      c.scale(r * sc, r * sc);
      c.drawPath(shape, fill..color = color);
      if (crease != null) {
        c.drawPath(crease, line..strokeWidth = .06..color = Sketch.fade(Sketch.mix(color, const Color(0xff5a1c04), .55), .45));
      }
      c.restore();
    }

    ring(_mgRuff0, _mgCrease0, 1, Offset.zero, 1, o0);
    // The skirt darkens away from the sun and warms where the light rakes it.
    line
      ..strokeWidth = r * .17
      ..color = const Color(0x59781f04);
    c.drawArc(Rect.fromCircle(center: p, radius: r * .83), 0, math.pi * .7, false, line);
    line
      ..strokeWidth = r * .12
      ..color = const Color(0x8cffdc8c);
    c.drawArc(Rect.fromCircle(center: p + Offset(-r * .02, -r * .02), radius: r * .84), -math.pi * .98, math.pi * .6, false, line);
    ring(_mgRuff1, _mgCrease1, .68, const Offset(-.04, -.05), 1.7, o1);
    ring(_mgRuff2, _mgCrease2, .46, const Offset(-.07, -.09), 2.3, o2);
    ring(_mgRuff3, null, .27, const Offset(-.09, -.11), 3.1, o3);
    final eye = p + Offset(-r * .1, -r * .12);
    c.drawCircle(eye, r * .17, fill..color = core);
    c.drawCircle(eye + Offset(-r * .03, -r * .04), r * .075, fill..color = Sketch.mix(core, const Color(0xffe8902a), .5));
    // Sparks of sun on the petal tips that face it.
    for (final a in const [-2.65, -2.2]) {
      c.drawCircle(p + Offset(math.cos(a), math.sin(a)) * (r * .93), r * .06, fill..color = const Color(0xe6fff1c0));
    }
  }

  /// Cempasúchil: a clump of marigolds. Serrated pinnate leaves fan from the
  /// crown, ribbed stems lean to round heads of ruffled petals, layered from
  /// a bright skirt to a dark rust eye, and two buds show a lick of orange.
  /// The low sun on the left rims every bloom and leaf with gold.
  static void _marigolds(Canvas c, Offset base, double s, {int seed = 0}) {
    final flip = seed.isOdd ? -1.0 : 1.0;
    // Evening light scattering round the blooms.
    Sketch.mist(
      c,
      Rect.fromCenter(center: base + Offset(-s * .12, -s * .62), width: s * 2.3, height: s * 1.7),
      const Color(0xffffb35a),
      .16,
    );
    // A shaded back row of leaves; the roots sit just under the crest.
    for (final (k, (a, len, dx)) in const [
      (-2.55, .5, -.28),
      (-2.2, .48, -.18),
      (-1.85, .46, -.06),
      (-1.3, .46, .08),
      (-.95, .48, .2),
      (-.6, .5, .3),
    ].indexed) {
      final r = Sketch.hash(seed * 23 + k + 830);
      _mgLeafAt(
        c,
        base + Offset(dx * s * flip, -s * .1),
        _mgFlip(a + (r - .5) * .22, flip),
        s * len * (.9 + .2 * r),
        const Color(0xff24472f),
        const Color(0xff5a8f46),
      );
    }
    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, s * .05)
      ..color = const Color(0xff2c5a36);
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, s * .018)
      ..color = const Color(0xd98fbf5a);
    final heads = <(Offset, double, double)>[];
    for (var i = 0; i < 5; i++) {
      final (dx, dy, hr) = _mgHead(seed, i);
      final root = base + Offset(dx * s * .3, s * .03);
      final head = base + Offset(dx * s, dy * s);
      final path = _mgStemPath(root, head);
      c.drawPath(path, stem);
      c.drawPath(path.shift(Offset(-s * .014, 0)), glint);
      // Paired leaves climb the stem, one to each side.
      final out = head.dx < base.dx ? -1.0 : 1.0;
      final r = Sketch.hash(seed * 29 + i + 840);
      _mgLeafAt(
        c,
        _mgOn(root, head, .36),
        out < 0 ? -2.35 : -.8,
        s * .34 * (.9 + .2 * r),
        const Color(0xff2f6238),
        const Color(0xff84b656),
      );
      if (i < 4) {
        _mgLeafAt(
          c,
          _mgOn(root, head, .6),
          out < 0 ? -.75 : -2.4,
          s * .27 * (.9 + .2 * r),
          const Color(0xff2f6238),
          const Color(0xff84b656),
        );
      }
      heads.add((head, hr * s, _mgTilt(root, head)));
    }
    // The front row of leaves hides the stems' feet.
    for (final (k, (a, len, dx)) in const [
      (-2.35, .4, -.22),
      (-1.95, .38, -.1),
      (-1.55, .34, .0),
      (-1.15, .38, .12),
      (-.8, .42, .24),
    ].indexed) {
      final r = Sketch.hash(seed * 37 + k + 850);
      _mgLeafAt(
        c,
        base + Offset(dx * s * flip, -s * .1),
        _mgFlip(a + (r - .5) * .22, flip),
        s * len * (.9 + .2 * r),
        const Color(0xff37703f),
        const Color(0xff86b458),
      );
    }
    // Two buds: a green calyx with orange petals just parting at the top.
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, s * .035)
      ..color = const Color(0xff2c5a36);
    final bud = Paint();
    for (final (bx, by, br) in const [(.4, -.98, .085), (-.74, -.3, .07)]) {
      final root = base + Offset(bx * s * .25 * flip, s * .03);
      final b = base + Offset(bx * s * flip, by * s);
      final rb = br * s;
      c.drawPath(_mgStemPath(root, b), thin);
      c.drawOval(Rect.fromCenter(center: b, width: rb * 1.9, height: rb * 2.2), bud..color = const Color(0xff2f6a3c));
      c.drawOval(
        Rect.fromCenter(center: b + Offset(-rb * .38, -rb * .05), width: rb * .5, height: rb * 1.3),
        bud..color = const Color(0xff70a84c),
      );
      c.save();
      c.translate(b.dx, b.dy - rb * .85);
      c.scale(rb * .8, rb * .55);
      c.drawPath(_mgRuff2, bud..color = const Color(0xffe8870f));
      c.translate(-.2, -.15);
      c.scale(.6, .6);
      c.drawPath(_mgRuff3, bud..color = const Color(0xffffb52e));
      c.restore();
    }
    for (final (i, (p, r, tilt)) in heads.indexed) {
      _mgBloom(c, p, r, tilt, seed + i, Sketch.hash(seed * 19 + i + 820) * math.pi * 2);
    }
  }

  static final _mgPaint = Paint();

  /// Marigold petals shaken loose: one per clump lifts away on the wind, the
  /// others tumble down and fade as they reach the ground at the crest.
  void _mgDrift(Canvas c, SceneFrame f, int copy) {
    final h = f.h, span = period(Depth.near) * h;
    for (final (i, (fx, sc)) in _mgSpots.indexed) {
      final x = span * fx, s = h * .09 * sc;
      final ground = _y(Depth.near, x, h);
      final base = ground + h * .012;
      for (var k = 0; k < 3; k++) {
        final seed = 940 + i * 11 + k * 3 + copy * 29;
        final life = (k == 0 ? 8.0 : 4.5) + 3.5 * Sketch.hash(seed);
        final t = (f.clock / life + Sketch.hash(seed + 1)) % 1;
        final alpha = math.min(1.0, math.min(t / .12, (1 - t) / .25));
        if (alpha <= 0) continue;
        final (hx, hy, hr) = _mgHead(i, (i + k * 2) % 5);
        final x0 = x + (hx - hr * .5) * s, y0 = base + (hy + hr * .35) * s;
        final lift = k == 0;
        final px = x0 - h * (lift ? .2 : .07) * t + math.sin(t * 9 + seed) * h * .006;
        final py = lift
            ? y0 - h * .05 * t + math.sin(t * 7 + seed) * h * .006
            : y0 + (ground - h * .004 - y0) * t + math.sin(t * 12 + seed) * h * .004;
        final size = h * (.0045 + .003 * Sketch.hash(seed + 2));
        c.save();
        c.translate(px, py);
        c.rotate(seed + t * (lift ? 7 : 11) * (k.isEven ? 1 : -1));
        c.scale(size, size * (.35 + .65 * math.sin(t * 13 + seed).abs()));
        c.drawPath(_mgPetal, _mgPaint..color = Sketch.fade(_mgPetalTones[seed % 3], alpha * .95));
        c.restore();
      }
    }
  }

  static Picture? _mgGround;
  static double _mgGroundH = 0;

  /// The near ground's surface over the crest: raking light, dust, stones,
  /// fallen petals and grass, recorded once per viewport height and drawn
  /// for each copy of the band.
  void _mgGroundOverlay(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final h = f.h;
    final cached = _mgGround;
    final Picture picture;
    if (cached != null && _mgGroundH == h) {
      picture = cached;
    } else {
      cached?.dispose();
      final recorder = PictureRecorder();
      _mgPaintGround(Canvas(recorder), h);
      picture = _mgGround = recorder.endRecording();
      _mgGroundH = h;
    }
    if (presence >= .999) {
      c.drawPicture(picture);
      return;
    }
    c.saveLayer(
      Rect.fromLTRB(-h, h * .85, h * 4, h * 1.05),
      Paint()..color = Sketch.fade(const Color(0xff000000), presence),
    );
    c.drawPicture(picture);
    c.restore();
  }

  void _mgPaintGround(Canvas c, double h) {
    final span = period(Depth.near) * h;
    double top(double x) => ridge(Depth.near, x / h, 0) * h;
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // The low sun rakes the crest: a warm sheen fading into shadowed soil.
    const steps = 60;
    final sheen = Path()..moveTo(0, top(0));
    for (var i = 1; i <= steps; i++) {
      final x = span * i / steps;
      sheen.lineTo(x, top(x));
    }
    for (var i = steps; i >= 0; i--) {
      final x = span * i / steps;
      sheen.lineTo(x, top(x) + h * .05);
    }
    sheen.close();
    fill.shader = Gradient.linear(
      Offset(0, h * .93),
      Offset(0, h * .985),
      const [Color(0x5cffa262), Color(0x2effa262), Color(0x00ffa262)],
      const [0.0, .45, 1.0],
    );
    c.drawPath(sheen, fill);
    fill.shader = null;
    // Wind-combed furrows: a dark groove with a lit lip above it.
    for (var i = 0; i < 16; i++) {
      final len = h * (.05 + .14 * Sketch.hash(i + 902));
      final x = math.min(span * (i + .2 + .6 * Sketch.hash(i + 900)) / 16, span - len - h * .01);
      final yf = .1 + .8 * Sketch.hash(i + 901);
      final y = top(x) + (h - top(x)) * yf;
      final wd = h * (.0012 + .0026 * yf);
      final furrow = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + len * .5, y - len * .1 * (Sketch.hash(i + 903) - .5), x + len, y + len * .02);
      c.drawPath(furrow.shift(Offset(0, -wd * 1.2)), line..strokeWidth = wd * .7..color = Sketch.fade(const Color(0xffe0a070), .3));
      c.drawPath(furrow, line..strokeWidth = wd..color = Sketch.fade(const Color(0xff2a1a22), .4));
    }
    // Grit: fine dark and sunlit grains, a few coarse ones.
    for (final (count, sz, color, seed) in const [
      (150, .0013, Color(0x59241620), 2000),
      (90, .0022, Color(0x66241620), 2400),
      (36, .0034, Color(0x66241620), 2800),
      (130, .0013, Color(0x66e0a070), 3200),
      (64, .0022, Color(0x70f0b880), 3600),
      (22, .0032, Color(0x70f0b880), 4000),
    ]) {
      final dots = <Offset>[];
      for (var i = 0; i < count; i++) {
        final x = span * Sketch.hash(seed + i * 2);
        dots.add(Offset(x, top(x) + (h - top(x)) * (.04 + .94 * Sketch.hash(seed + i * 2 + 1))));
      }
      c.drawPoints(PointMode.points, dots, line..strokeWidth = h * sz..color = color);
    }
    // Dry cracks in the soil towards the front.
    for (var i = 0; i < 6; i++) {
      var x = span * (i + .3 + .4 * Sketch.hash(i + 1200)) / 6;
      var y = top(x) + (h - top(x)) * (.4 + .3 * Sketch.hash(i + 1201));
      final crack = Path()..moveTo(x, y);
      for (var k = 0; k < 5; k++) {
        x += h * (.008 + .012 * Sketch.hash(i * 9 + k + 1210));
        y += h * (Sketch.hash(i * 9 + k + 1260) - .4) * .014;
        crack.lineTo(x, y);
      }
      c.drawPath(crack, line..strokeWidth = math.max(.7, h * .0013)..color = Sketch.fade(const Color(0xff1e1218), .5));
    }
    // Each clump throws a long shadow to the right and warms the soil at its left.
    for (final (fx, sc) in _mgSpots) {
      final x = span * fx, s = h * .09 * sc;
      final by = top(x) + h * .012;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x - s * .5, by + h * .002), width: s * 2.6, height: s * .36),
        const Color(0xffffa050),
        .24,
      );
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x + s * .4, by + h * .004), width: s * 2.3, height: s * .34),
        const Color(0xff1e1018),
        .45,
      );
    }
    // Stones grow larger towards the viewer.
    for (var i = 0; i < 46; i++) {
      final x = span * (i + .1 + .8 * Sketch.hash(i + 1100)) / 46;
      final yf = .05 + .9 * Sketch.hash(i + 1101);
      final r = h * (.0022 + .0075 * yf * yf) * (.7 + .6 * Sketch.hash(i + 1102));
      final y = math.min(top(x) + (h - top(x)) * yf, h - r);
      _mgPebble(c, x, y, r, i);
      if (i % 5 == 0) _mgPebble(c, x + r * 1.7, y + r * .25, r * .55, i + 60);
    }
    // Fallen petals lie flat, most of them downwind of a clump.
    for (var i = 0; i < 46; i++) {
      final double x;
      if (Sketch.hash(i + 1400) < .6) {
        x = span * _mgSpots[i % _mgSpots.length].$1 + h * .2 * (Sketch.hash(i + 1401) - .7);
      } else {
        x = span * Sketch.hash(i + 1402);
      }
      final y = top(x) + (h - top(x)) * (.1 + .82 * Sketch.hash(i + 1403));
      final pink = i % 9 == 4;
      final body = pink
          ? (i.isEven ? const Color(0xffd63f7e) : const Color(0xffe8639a))
          : _mgPetalTones[(Sketch.hash(i + 1405) * 3).floor()];
      _mgFallen(c, x, y, h * (.0045 + .0035 * Sketch.hash(i + 1404)), Sketch.hash(i + 1406) * math.pi * 2, body);
    }
    // Leaves and tufts plant each clump in the soil.
    for (final (i, (fx, sc)) in _mgSpots.indexed) {
      final x = span * fx, s = h * .09 * sc;
      final by = top(x) + h * .012;
      final flip = i.isOdd ? -1.0 : 1.0;
      for (final (k, (a, len, dx)) in const [
        (-2.75, .34, -.26),
        (-2.2, .38, -.12),
        (-.95, .38, .14),
        (-.4, .32, .26),
      ].indexed) {
        final r = Sketch.hash(i * 29 + k + 1500);
        _mgLeafAt(
          c,
          Offset(x + dx * s * flip, by),
          _mgFlip(a + (r - .5) * .2, flip),
          s * len * (.9 + .2 * r),
          const Color(0xff32663c),
          const Color(0xff92c060),
        );
      }
      _mgTuft(c, x - s * .7, by + h * .003, s * .36, i * 3 + 1600);
      _mgTuft(c, x + s * .05, by - s * .09, s * .3, i * 3 + 1601);
      _mgTuft(c, x + s * .78, by + h * .002, s * .3, i * 3 + 1602);
    }
    // Grass along the whole crest.
    const tufts = 38;
    for (var i = 0; i < tufts; i++) {
      final x = span * (i + .15 + .7 * Sketch.hash(i + 1700)) / tufts;
      final q = Sketch.hash(i + 1701);
      _mgTuft(c, x, top(x) + h * (.003 + .011 * Sketch.hash(i + 1702)), h * (.011 + .026 * q * q), i + 1800);
    }
  }

  static const _mgGrass = [
    (Color(0xffb8904e), Color(0xffffcf86)),
    (Color(0xff5c7238), Color(0xffb4c46a)),
    (Color(0xff46703a), Color(0xff9cc060)),
  ];

  /// A tapered, curved blade of grass rooted at (x, y), [len] tall and
  /// leaning by [lean] blade-heights at its tip.
  static void _mgBlade(Canvas c, Paint paint, double x, double y, double len, double lean, double half) {
    final tx = x + lean * len, ty = y - len;
    final cx = x + lean * len * .18, cy = y - len * .62;
    c.drawPath(
      Path()
        ..moveTo(x - half, y)
        ..quadraticBezierTo(cx - half * .5, cy, tx, ty)
        ..quadraticBezierTo(cx + half * .5, cy, x + half, y)
        ..close(),
      paint,
    );
  }

  /// A fan of grass blades, straw, olive or green, all combed downwind and
  /// warmed on the sunward side.
  static void _mgTuft(Canvas c, double x, double y, double size, int seed) {
    final n = 5 + (Sketch.hash(seed) * 4).floor();
    final paint = Paint();
    for (var k = 0; k < n; k++) {
      final u = k / (n - 1) - .5;
      final r = Sketch.hash(seed * 31 + k);
      final len = size * (.5 + .5 * r) * (1 - .5 * u.abs());
      final lean = u * 1.1 - .28 + (Sketch.hash(seed * 31 + k + 500) - .5) * .35;
      final (shade, lit) = _mgGrass[(Sketch.hash(seed * 17 + k + 900) * 3).floor()];
      paint.color = lean < 0
          ? Sketch.mix(shade, lit, math.min(.85, .25 - lean * .8))
          : Sketch.mix(shade, const Color(0xff2a2030), .3);
      _mgBlade(c, paint, x + u * size * .8 + (r - .5) * size * .1, y, len, lean, math.max(.6, size * .045));
    }
  }

  /// A half-buried stone: contact shadow, dome, shaded belly, sunlit crown.
  static void _mgPebble(Canvas c, double x, double y, double r, int seed) {
    const tones = [Color(0xff8c6a5a), Color(0xff7c5c54), Color(0xffa07c66), Color(0xff6e5450)];
    final tone = tones[(Sketch.hash(seed + 1120) * tones.length).floor()];
    final paint = Paint();
    c.drawOval(Rect.fromCenter(center: Offset(x + r * .3, y + r * .62), width: r * 2.4, height: r * .75), paint..color = const Color(0x73201018));
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 1.5), paint..color = tone);
    c.drawOval(
      Rect.fromCenter(center: Offset(x + r * .1, y + r * .38), width: r * 1.6, height: r * .6),
      paint..color = Sketch.mix(tone, const Color(0xff2a1a24), .45),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(x - r * .25, y - r * .3), width: r * 1.05, height: r * .6),
      paint..color = Sketch.mix(tone, const Color(0xffffc890), .55),
    );
  }

  /// A petal lying on the ground, foreshortened, its sunward half lit.
  static void _mgFallen(Canvas c, double x, double y, double len, double angle, Color body) {
    final paint = Paint();
    c.save();
    c.translate(x, y);
    c.scale(1.0, .42);
    c.rotate(angle);
    c.scale(len, len);
    c.drawPath(_mgPetal, paint..color = body);
    c.translate(-.1, -.14);
    c.scale(.68, .5);
    c.drawPath(_mgPetal, paint..color = Sketch.mix(body, const Color(0xffffe9a8), .5));
    c.restore();
  }

  /// Pads of the prickly pear as (x, y, angle, length, young), in [s] from the
  /// base, drawn back to front: the new pads first and the old base pad last,
  /// so every parent overlaps the neck of the pad growing from its rim.
  static const _pearPads = <(double, double, double, double, bool)>[
    (.3, -.85, 1.0, .3, true),
    (-.36, -.78, -1.05, .3, true),
    (.03, -1.0, .35, .28, true),
    (-.4, -.9, -.3, .26, true),
    (.38, -.96, .2, .25, true),
    (.02, -.58, -.05, .5, false),
    (-.12, -.5, -.6, .55, false),
    (.13, -.52, .5, .56, false),
    (0.0, .06, .04, .72, false),
  ];

  /// Tunas as (x, y, tilt, ripeness): red, orange and yellow-green fruit
  /// sitting on the pad rims.
  static const _pearFruit = <(double, double, double, int)>[
    (-.31, -.95, -.2, 0),
    (.3, -1.0, .25, 1),
    (.43, -.91, .6, 0),
    (-.07, -1.06, -.2, 0),
    (.09, -1.07, .2, 2),
    (-.44, -.68, -.7, 1),
  ];

  /// Shade, body and sunlit colours of a ripe tuna, by ripeness.
  static const _pearTunas = <(Color, Color, Color)>[
    (Color(0xff8f1c48), Color(0xffc72f60), Color(0xffee6a90)),
    (Color(0xffb84f1a), Color(0xffe6782e), Color(0xfff8ac62)),
    (Color(0xff7f8f2a), Color(0xffb0ba3c), Color(0xffdade7a)),
  ];

  /// One oval paddle from a narrow neck at the origin up to [l] along -y. The
  /// right edge is pulled in by [kr], so nested fills at 1, .34 and a negative
  /// value read as shade, body and a sunlit band down the left.
  static Path _pearPath(double l, double kr) => Path()
    ..moveTo(-.09 * l, 0)
    ..cubicTo(-.52 * l, -.16 * l, -.5 * l, -.9 * l, 0, -l)
    ..cubicTo(.5 * l * kr, -.9 * l, .52 * l * kr, -.16 * l, .09 * l * kr, 0)
    ..close();

  /// A paddle at [root], turned by [angle]: blue-green, outlined against its
  /// neighbours, its areoles dotted in a diagonal grid with tufts of spines.
  /// A [young] pad is small, pale and smooth.
  static void _pearPad(Canvas c, Offset root, double angle, double l, bool young) {
    c.save();
    c.translate(root.dx, root.dy);
    c.rotate(angle);
    c.drawPath(_pearPath(l, 1), Paint()..color = young ? const Color(0xff4d9a5c) : const Color(0xff36795a));
    c.drawPath(_pearPath(l, .34), Paint()..color = young ? const Color(0xff7cc36f) : const Color(0xff54a06a));
    c.drawPath(_pearPath(l, -.42), Paint()..color = young ? const Color(0xffaadf8c) : const Color(0xff86c882));
    c.drawPath(
      _pearPath(l, 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(.7, l * .02)
        ..color = young ? const Color(0x99378a4a) : const Color(0xb01f4f3c),
    );
    if (!young) {
      final dots = <Offset>[];
      final tufts = Path();
      final gap = l * .19, sp = l * .055;
      for (var j = 0; j < 5; j++) {
        final t = .2 + .16 * j;
        final hw = l * .39 * math.sin(math.pi * math.pow(t, .8));
        for (var k = -3; k <= 3; k++) {
          final x = (k + (j.isOdd ? .5 : 0.0)) * gap;
          if (x.abs() > hw * .78) continue;
          final o = Offset(x, -t * l);
          dots.add(o);
          for (final dx in const [-.55, 0.0, .55]) {
            tufts
              ..moveTo(o.dx, o.dy)
              ..lineTo(o.dx + dx * sp, o.dy - sp * (1 - dx.abs() * .3));
          }
        }
      }
      c.drawPoints(
        PointMode.points,
        dots,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.1, l * .026)
          ..color = const Color(0xff5b4a2e),
      );
      c.drawPath(
        tufts,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(.6, l * .012)
          ..color = const Color(0xd9f4e8bc),
      );
    }
    c.restore();
  }

  /// A tuna: an egg of fruit with a sunlit cheek and the sunken crown where
  /// its flower fell.
  static void _pearTuna(Canvas c, Offset p, double tilt, double s, int ripeness) {
    final t = _pearTunas[ripeness];
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(tilt);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * .1, height: s * .145), Paint()..color = t.$1);
    c.drawOval(Rect.fromCenter(center: Offset(-s * .012, -s * .008), width: s * .076, height: s * .118), Paint()..color = t.$2);
    c.drawOval(Rect.fromCenter(center: Offset(-s * .022, -s * .03), width: s * .026, height: s * .05), Paint()..color = t.$3);
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * .066), width: s * .05, height: s * .022), Paint()..color = const Color(0xff5a2030));
    c.restore();
  }

  /// An open yellow bloom seen from the side: a fan of silky petals round an
  /// orange heart.
  static void _pearFlower(Canvas c, Offset p, double r) {
    final petals = Path(), inner = Path();
    for (var i = 0; i < 7; i++) {
      final a = -3.0 + i * .47;
      petals
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx + math.cos(a) * r, p.dy + math.sin(a) * r);
      inner
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx + math.cos(a) * r * .62, p.dy + math.sin(a) * r * .62);
    }
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(petals, pen..strokeWidth = r * .55..color = const Color(0xfff0b428));
    c.drawPath(inner, pen..strokeWidth = r * .38..color = const Color(0xfffbd94e));
    c.drawCircle(p, r * .2, Paint()..color = const Color(0xffe7792a));
  }

  /// A prickly pear: paddles of nopal growing edge to edge, each with spined
  /// areoles, red and orange tunas on the rims and yellow flowers on the new
  /// growth. [dir] mirrors the layout without turning the light.
  static void _pear(Canvas c, Offset base, double s, {double dir = 1}) {
    for (final (x, y, a, l, young) in _pearPads) {
      _pearPad(c, base + Offset(x * dir * s, y * s), a * dir, l * s, young);
    }
    for (final (x, y, tilt, ripeness) in _pearFruit) {
      _pearTuna(c, base + Offset(x * dir * s, y * s), tilt * dir, s, ripeness);
    }
    _pearFlower(c, base + Offset(.13 * dir * s, -1.27 * s), s * .075);
    _pearFlower(c, base + Offset(-.47 * dir * s, -1.16 * s), s * .07);
  }
}
