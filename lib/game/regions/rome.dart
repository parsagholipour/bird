import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Ancient Rome in the golden light of late afternoon: an aqueduct marching
/// across the Alban hills, the Colosseum with its broken flank between the
/// Pantheon and a triumphal arch, forum temples and cypresses on the dusty
/// road, and marble drums, laurel and a legionary in the foreground. Swallows
/// wheel and olive leaves drift.
class RomeScene extends RegionScene {
  const RomeScene();

  @override
  WorldRegion get region => WorldRegion.rome;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.25, .24),
    radius: .066,
    disc: Color(0xfffff3d2),
    glow: Color(0xffffb894),
    halo: .64,
    strength: .6,
  );

  static final _weather = Weather(Weather.of([(Mote.leaf, 6)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xfff2c9a0);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffcfb3a0),
      Color(0xffc4a898),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xffa3a468),
      Color(0xff868a55),
      Color(0xffdde0a0),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xffcfa870),
      Color(0xffb68a52),
      Color(0xfff2d9a2),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xffb0a25e),
      Color(0xff8a7846),
      Color(0xffdccf8c),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .69,
    // Rolling Alban foothills; the repeating bands use waves that divide
    // their 3-unit period, so the terrain is seamless.
    Depth.mid => .735 + Sketch.waves(x, const [(2.2, .014, .4), (.9, .005, 2.1)]),
    Depth.low => .84 + Sketch.waves(x, const [(1.5, .008, .1), (.6, .003, 1)]),
    Depth.near => .935 + Sketch.waves(x, const [(1.5, .009, 0), (.75, .003, 1.3)]),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    // The Colosseum, Pantheon and the arch's quadriga stand ~.36 h tall.
    Depth.mid => .42,
    Depth.low => .3,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  double _y(Depth d, double x, double h) => ridge(d, x / h, 0) * h;

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        // Timed bands drift left for the whole leg, so everything reaches
        // well past the right edge.
        _hills(c, w, h);
        _aqueductRun(c, w, h);
        _aqueductFront(c, w, h);
      case Depth.mid:
        // Compose from the Colosseum outward so narrow screens keep the
        // landmarks apart (smaller, half-cropped) instead of stacked.
        // This layout is mirrored in _colosseumSpot, _monumentLife and
        // _eveningSwifts (k, cx, panX): change all four together.
        final k =(w / (h * 1.6)).clamp(.5, 1.0);
        final colS = h * .78 * k, panS = h * .17 * k, archS = h * .2 * k;
        final cx = w * .53;
        final panX = math.min(w * .16, cx - colS * .5 - panS * .6 + h * .02);
        final archX = math.max(w * .9, cx + colS * .5 + archS * .55 + h * .03);
        double at(double x) => _y(Depth.mid, x, h) + h * .02;
        _pantheon(c, Offset(panX, at(panX)), panS);
        _colosseum(c, Offset(cx, at(cx)), colS);
        _arch(c, Offset(archX, at(archX)), archS);
        final ts = h * .16 * math.max(k, .7);
        final body = _hazed(const Color(0xff4a5a3a), .25);
        final lit = _hazed(const Color(0xff6f8250), .25);
        void tree(double x, bool pine, double s) {
          if (pine) {
            _pine(c, Offset(x, at(x)), s * 1.1, body, lit);
          } else {
            Scenery.cypress(c, Offset(x, at(x)), s, body, lit);
          }
        }
        tree(panX + panS * .6 + h * .05, false, ts);
        tree(cx - colS * .5 - h * .04, true, ts);
        tree((cx + colS * .5 + archX - archS * .55) / 2, false, ts * .95);
        var i = 0;
        for (var x = archX + archS * .55 + h * .12; x < w + h * .7; x += h * (.34 + .16 * Sketch.hash(i + 610))) {
          tree(x, i.isEven, ts * (.85 + .3 * Sketch.hash(i + 620)));
          i++;
        }
      case Depth.low:
        _forumFeatures(c, h);
      case Depth.near:
        _foreFeatures(c, h, span);
    }
  }

  /// Animated life behind each band's ground: glints and farm smoke (far),
  /// birds round the Pantheon (mid), incense from the forum altar (low) and
  /// the legionary's crest (near).
  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d == Depth.near) return _foreLive(c, f);
    // Life on the landmarks is drawn here, not in overlay(): live() sinks with
    // the band's features in a crossing, so glints, smoke and birds go down
    // with the aqueduct, Pantheon and hills instead of hanging in the air.
    if (d == Depth.far) _aqueductLife(c, f, 1);
    if (d == Depth.mid) {
      _monumentLife(c, f, 1);
      _eveningSwifts(c, f);
    }
    if (d != Depth.low) return;
    final h = f.h;
    final x = _forumAltarX * h;
    final top = _y(d, x, h) + h * .012 - h * _forumAltarS * 1.28;
    final paint = Paint();
    // A thin wisp: small puffs on a lazy S that leans with the breeze.
    for (var i = 0; i < 18; i++) {
      final age = (f.clock * .12 + i / 18) % 1;
      final puff = Offset(x + math.sin(age * 6.2 + i * .05) * h * .007 * (.3 + age) + age * age * h * .055, top - age * h * .17);
      paint.color = Sketch.fade(const Color(0xffefe4d2), .22 * (1 - age) * math.min(1.0, age * 7));
      c.drawCircle(puff, h * (.003 + .0095 * age), paint);
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    if (d == Depth.near) return _foreOverlay(c, f, presence);
    final h = f.h;
    switch (d) {
      case Depth.far:
        _aqueductPlain(c, f, presence);
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5 + h * .15, h * .697), width: f.w + h * 1.2, height: h * .06),
          const Color(0xffffe6c8),
          .42 * presence,
        );
        // A slow cloud shadow crosses the hills.
        final shadow = (f.clock * h * .012 + h * 1.1) % (f.w + h * 1.6) - h * .5;
        Sketch.mist(c, Rect.fromCenter(center: Offset(shadow, h * .58), width: h * 1.5, height: h * .12), const Color(0xff45506a), .15 * presence);
      case Depth.mid:
        _colosseumOverlay(c, f, presence);
        // Olive groves dot the hillside, well past the right edge for the
        // drift of the timed band.
        final olive = Paint()..color = Sketch.fade(const Color(0xff6f7f4a), .8 * presence);
        final lit = Paint()..color = Sketch.fade(const Color(0xff9aa864), .7 * presence);
        final n = ((f.w + h) / (h * .045)).round();
        for (var i = 0; i < n; i++) {
          final x = (f.w + h) * Sketch.hash(i + 600) - h * .3;
          final y = (ridge(Depth.mid, x / h, 0) + .014 + .035 * Sketch.hash(i + 601)) * h;
          final r = h * (.008 + .004 * Sketch.hash(i + 602));
          c.drawCircle(Offset(x, y), r, olive);
          c.drawCircle(Offset(x - r * .3, y - r * .3), r * .55, lit);
        }
      case Depth.low:
        _forumRoad(c, f, presence);
      case Depth.near:
        break;
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final sun = Offset(light.at.dx * f.w, light.at.dy * f.h);
    _eveningWash(c, f, sun, presence);
    _eveningRays(c, f, sun, presence);
    _eveningCirrus(c, f, presence);
    _eveningClouds(c, f, presence);
    _eveningBloom(c, f, sun, presence);
    _eveningSmoke(c, f, presence);
    _eveningFlock(c, f, presence);
    _eveningLeaves(c, f, presence);
  }

  /// Repeat width of the cloud strips, in viewport heights: wider than any
  /// phone screen, so two copies always cover the view.
  static const _eveningSpan = 3.4;
  static final _eveningPaint = Paint();
  static final _eveningStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _eveningStrips = <String, List<Path>>{};

  static Paint _eveningFill(Color color, double alpha) => _eveningPaint
    ..shader = null
    ..blendMode = BlendMode.srcOver
    ..color = Sketch.fade(color, alpha);

  /// Deeper blue at the zenith, a rose belt and a molten horizon: the tints
  /// that turn the flat gradient into an evening sky, with a warm bank under
  /// the sun.
  static void _eveningWash(Canvas c, SceneFrame f, Offset sun, double presence) {
    final w = f.w, h = f.h;
    const deep = Color(0xff3a62b2), rose = Color(0xffe6a0b8), gold = Color(0xffffb46e);
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h * .72),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, h * .72),
          [
            Sketch.fade(deep, .36 * presence),
            Sketch.fade(deep, 0),
            Sketch.fade(rose, .2 * presence),
            Sketch.fade(gold, .3 * presence),
            Sketch.fade(gold, 0),
          ],
          const [0, .3, .56, .86, 1],
        ),
    );
    // Away from the sun the blue deepens toward the top right corner.
    c.drawRect(
      Offset.zero & f.size,
      Paint()
        ..shader = Gradient.radial(Offset(w, 0), h * 1.15, [
          Sketch.fade(deep, .3 * presence),
          Sketch.fade(deep, 0),
        ]),
    );
    Sketch.mist(c, Rect.fromCenter(center: Offset(sun.dx + h * .12, h * .64), width: h * 3.4, height: h * .74), const Color(0xffffa45c), .5 * presence);
  }

  /// Soft crepuscular beams fanning down from the low sun through gaps in
  /// the cloud: a wide faint set under a narrower brighter set.
  static void _eveningRays(Canvas c, SceneFrame f, Offset sun, double presence) {
    final h = f.h, t = f.clock;
    final len = h * 1.3;
    final beat = .8 + .2 * math.sin(t * .3);
    Paint beams(double alpha) => Paint()
      ..shader = Gradient.radial(
        sun,
        len,
        [
          Sketch.fade(const Color(0xffffd9a0), alpha * beat * presence),
          Sketch.fade(const Color(0xffffd9a0), alpha * .45 * beat * presence),
          Sketch.fade(const Color(0xffffd9a0), 0),
        ],
        const [.08, .5, 1],
      );
    final wide = Path(), core = Path();
    const angles = [.36, .6, .84, 1.06, 1.3, 1.55, 1.78, 2.06, 2.38];
    const spreads = [.05, .03, .06, .035, .05, .04, .03, .055, .04];
    for (var i = 0; i < angles.length; i++) {
      final breathe = 1 + .22 * math.sin(t * .4 + i * 1.7);
      for (final (path, k) in [(wide, 1.9), (core, .8)]) {
        final s = spreads[i] * k * breathe;
        path
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(sun.dx + math.cos(angles[i] - s) * len, sun.dy + math.sin(angles[i] - s) * len)
          ..lineTo(sun.dx + math.cos(angles[i] + s) * len, sun.dy + math.sin(angles[i] + s) * len)
          ..close();
      }
    }
    c.drawPath(wide, beams(.16));
    c.drawPath(core, beams(.15));
  }

  /// A lens-shaped streak of cirrus centred on [cx], [cy], [len] long, tilted
  /// by [tilt] with a [curve] sag and [th] thick at the belly.
  static void _eveningStreak(Path p, double cx, double cy, double len, double tilt, double curve, double th) {
    final dx = math.cos(tilt) * len / 2, dy = math.sin(tilt) * len / 2;
    final nx = -math.sin(tilt), ny = math.cos(tilt);
    final a = Offset(cx - dx, cy - dy), b = Offset(cx + dx, cy + dy);
    final m = Offset(cx + nx * curve, cy + ny * curve);
    p
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(m.dx + nx * th, m.dy + ny * th, b.dx, b.dy)
      ..quadraticBezierTo(m.dx - nx * th, m.dy - ny * th, a.dx, a.dy);
  }

  /// Faint high cirrus: bundles of thin streaks and hooked mares' tails.
  static void _eveningCirrus(Canvas c, SceneFrame f, double presence) {
    final layers = _eveningStrips.putIfAbsent('cirrus', () {
      final haze = Path(), thin = Path();
      for (var i = 0; i < 9; i++) {
        final x = _eveningSpan * (i + .2 + .6 * Sketch.hash(950 + i)) / 9;
        final y = .09 * Sketch.hash(960 + i) + (i.isEven ? .02 : .08);
        final len = .32 + .5 * Sketch.hash(970 + i);
        final tilt = -.1 + .16 * Sketch.hash(980 + i);
        final curve = len * .14 * (Sketch.hash(990 + i) - .35);
        for (final (dx, dy, k, thick) in const [(0.0, 0.0, 1.0, .0065), (.06, .022, .6, .0045), (-.05, -.018, .45, .0035)]) {
          _eveningStreak(haze, x + dx, y + dy, len * k, tilt, curve * k, thick * 3.2);
          _eveningStreak(thin, x + dx, y + dy, len * k, tilt, curve * k, thick);
        }
        // The hooked tail at the leading end.
        _eveningStreak(haze, x + len * .5, y + .012 + len * .03, len * .16, tilt + 1.1, len * .03, .006);
      }
      return [haze, thin];
    });
    final h = f.h;
    final x0 = -((f.clock * .0055 * h + .3 * _eveningSpan * h) % (_eveningSpan * h));
    for (var k = 0; k < 2; k++) {
      final x = x0 + k * _eveningSpan * h;
      if (x > f.w) break;
      c.save();
      c.translate(x, h * .03);
      c.scale(h);
      c.drawPath(layers[0], _eveningFill(const Color(0xfffff4e6), .1 * presence));
      c.drawPath(layers[1], _eveningFill(const Color(0xfffff2e0), .34 * presence));
      c.restore();
    }
  }

  /// Shaded puffs as unit-space paths, lit from the upper left: [shade] the
  /// whole mass, then [mid], [lit] and small [rim] highlights on puffs whose
  /// crowns are open to the sun. [floor] cuts a flat cumulus base.
  static List<Path> _eveningPuffs(List<(double, double, double)> puffs, {double squash = 1, double? floor, bool rim = true, double lift = 1}) {
    final shade = Path(), mid = Path(), litA = Path(), litB = Path(), crest = Path();
    for (var i = 0; i < puffs.length; i++) {
      final (x, y, r) = puffs[i];
      final ry = r * squash;
      shade.addOval(Rect.fromCenter(center: Offset(x, y), width: r * 2, height: ry * 2));
      mid.addOval(Rect.fromCenter(center: Offset(x - r * .1, y - ry * .16), width: r * 1.74, height: ry * 1.74));
      // The lit side is a crescent along the puff's upper left edge.
      final whole = Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: r * 2, height: ry * 2));
      final away = Path()..addOval(Rect.fromCenter(center: Offset(x + r * .2 * lift, y + ry * .28 * lift), width: r * 2.02, height: ry * 2.02));
      (i.isEven ? litA : litB).addPath(Path.combine(PathOperation.difference, whole, away), Offset.zero);
      final crown = Offset(x - r * .25, y - ry * .85);
      var open = true;
      for (var j = 0; j < puffs.length && open; j++) {
        if (j == i) continue;
        final (ox, oy, or) = puffs[j];
        final u = (crown.dx - ox) / or, v = (crown.dy - oy) / (or * squash);
        open = u * u + v * v > 1;
      }
      if (open && rim) crest.addOval(Rect.fromCenter(center: Offset(x - r * .3, y - ry * .5), width: r * .8, height: ry * .5));
    }
    if (floor != null) {
      final cut = Path()..addRect(Rect.fromLTRB(-10, -10, 10, floor));
      return [for (final p in [shade, mid, litB, litA, if (rim) crest]) Path.combine(PathOperation.intersect, p, cut)];
    }
    return [shade, mid, litB, litA, if (rim) crest];
  }

  /// Dusk tones of a cloud by height: [a] is 0 in the deep blue, 1 at the
  /// horizon. Lilac shadows warm to rose and salmon; the lit sides gild.
  static List<Color> _eveningTones(double a) => [
    Sketch.mix(const Color(0xff9088b8), const Color(0xffdc8a78), a),
    Sketch.mix(const Color(0xffcdb8d0), const Color(0xfff4ae8a), a),
    Sketch.mix(const Color(0xffe9d2dc), const Color(0xfff8c898), a),
    Sketch.mix(const Color(0xffffeee2), const Color(0xffffdc9c), a),
    const Color(0xfffff8e2),
  ];

  static void _eveningStrip(
    Canvas c,
    SceneFrame f,
    String key,
    List<Path> Function() build,
    double y,
    double speed,
    double phase,
    double a,
    List<double> alphas,
    double presence, {
    double haze = 0,
  }) {
    final layers = _eveningStrips.putIfAbsent(key, build);
    final tones = [for (final t in _eveningTones(a)) haze > 0 ? _hazed(t, haze) : t];
    final h = f.h, span = _eveningSpan * h;
    final x0 = -((f.clock * speed * h + phase * span) % span);
    for (var k = 0; k < 2; k++) {
      final x = x0 + k * span;
      if (x > f.w + h * .1) break;
      c.save();
      c.translate(x, y * h);
      c.scale(h);
      for (var i = 0; i < layers.length; i++) {
        c.drawPath(layers[i], _eveningFill(tones[i], alphas[i] * presence));
      }
      c.restore();
    }
  }

  /// Evening cloud decks, far to near: rows of altocumulus, long stratus
  /// veils and towering cumulus banks standing on the hills, all with warm
  /// undersides.
  static void _eveningClouds(Canvas c, SceneFrame f, double presence) {
    _eveningStrip(c, f, 'alto', () {
      final puffs = <(double, double, double)>[];
      var n = 0;
      for (final (dy, size) in const [(0.0, .03), (.07, .022), (.125, .016)]) {
        var x = .3 + .4 * Sketch.hash(800 + n);
        while (x < _eveningSpan - .5) {
          final count = 3 + (Sketch.hash(810 + n) * 4).floor();
          for (var i = 0; i < count && x < _eveningSpan - .35; i++) {
            final r = size * (.7 + .6 * Sketch.hash(820 + n * 7 + i));
            puffs.add((x, dy + size * .9 * (Sketch.hash(830 + n * 7 + i) - .5), r));
            x += size * (1.0 + .8 * Sketch.hash(840 + n * 7 + i));
          }
          x += .3 + .55 * Sketch.hash(850 + n);
          n++;
        }
      }
      return _eveningPuffs(puffs, squash: .5);
    }, .17, .008, .0, .3, const [.5, .62, .68, .72, .75], presence, haze: .12);
    _eveningStrip(c, f, 'veil', () {
      final puffs = <(double, double, double)>[];
      for (var i = 0; i < 7; i++) {
        final x = _eveningSpan * (i + .3 + .4 * Sketch.hash(860 + i)) / 7;
        final y = .16 * Sketch.hash(870 + i);
        final r = .1 + .12 * Sketch.hash(880 + i);
        puffs
          ..add((x, y, r))
          ..add((x + r * .9, y + .004, r * .7))
          ..add((x - r * .8, y - .003, r * .6));
      }
      return _eveningPuffs(puffs, squash: .11);
    }, .4, .005, .45, .75, const [.42, .5, .55, .6, .66], presence);
    _eveningStrip(c, f, 'cumulus', () {
      final puffs = <(double, double, double)>[];
      for (final (i, cx, width, tall) in const [(0, .5, 1.05, .16), (1, 1.85, .75, .08), (2, 2.75, .9, .12)]) {
        final n = (width / (tall * .55)).round().clamp(4, 14);
        for (var j = 0; j < n; j++) {
          final t = (j + .5) / n;
          final env = math.pow(math.sin(t * math.pi), .8).toDouble();
          final top = tall * (.3 + .7 * env) * (.7 + .3 * Sketch.hash(900 + i * 20 + j));
          var r = width / n * (.8 + .4 * Sketch.hash(910 + i * 20 + j));
          var x = cx - width / 2 + width * t + (Sketch.hash(920 + i * 20 + j) - .5) * r * .4;
          var y = -r * .55;
          puffs.add((x, y, r));
          for (var s = 0; s < 3 && -y + r * .6 < top; s++) {
            final next = r * .78;
            y -= r * .5 + next * .55;
            x += (Sketch.hash(930 + i * 20 + j * 3 + s) - .5) * next * .7;
            r = next;
            puffs.add((x, y, r));
          }
        }
      }
      return _eveningPuffs(puffs, squash: .82, floor: 0, rim: false, lift: 1.15);
    }, .6, .003, .2, 1.0, const [.9, .94, .94, .96], presence, haze: .12);
  }

  /// Golden glare washing over the clouds nearest the sun.
  static void _eveningBloom(Canvas c, SceneFrame f, Offset sun, double presence) {
    final r = f.h * .42;
    const glare = Color(0xffffe2b0);
    c.drawCircle(
      sun,
      r,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = Gradient.radial(
          sun,
          r,
          [Sketch.fade(glare, .55 * presence), Sketch.fade(glare, .2 * presence), Sketch.fade(glare, 0)],
          const [0, .3, 1],
        ),
    );
  }

  /// Thin smoke of far farms curling up from behind the hills.
  static void _eveningSmoke(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final base = h * .6, rise = h * .2;
    const smoke = Color(0xffa08c9c);
    final shader = Gradient.linear(Offset(0, base), Offset(0, base - rise), [Sketch.fade(smoke, 1), Sketch.fade(smoke, 0)]);
    const steps = 10;
    for (var i = 0; i < 4; i++) {
      // Clear of the two smoking farmsteads of the aqueduct (x ~ .1 w and ~.85 w).
      final xb = w * const [.2, .31, .73, .965][i];
      final ph = i * 2.3;
      final lean = .6 + .4 * Sketch.hash(1200 + i);
      Offset at(int k, double side) {
        final u = k / steps;
        final half = h * (.0016 + .0072 * u) * side;
        return Offset(xb + lean * u * u * h * .05 + math.sin(u * 7 - t * .8 + ph) * h * .0065 * (.3 + u) + half, base - u * rise);
      }
      final path = Path();
      for (var k = 0; k <= steps; k++) {
        final p = at(k, -1);
        k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      for (var k = steps; k >= 0; k--) {
        final p = at(k, 1);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(
        path..close(),
        Paint()
          ..shader = shader
          ..color = Sketch.fade(const Color(0xffffffff), .6 * presence),
      );
    }
  }

  /// A starling murmuration breathing and turning across the glow of the
  /// sun, and a few swallows swooping in wide loops.
  static void _eveningFlock(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final cx = w * .37 + math.sin(t * .13 + 1.1) * w * .07 + math.sin(t * .05) * w * .04;
    final cy = h * .3 + math.sin(t * .17) * h * .045;
    final breathe = 1 + .22 * math.sin(t * .31);
    final rot = -.28 + .4 * math.sin(t * .11 + .6);
    final cr = math.cos(rot), sr = math.sin(rot);
    final wings = Path();
    for (var i = 0; i < 28; i++) {
      final rr = math.pow(Sketch.hash(1000 + i), .8).toDouble();
      final a = Sketch.hash(1040 + i) * math.pi * 2;
      final ux = math.cos(a) * rr * h * .17 * breathe;
      final uy = math.sin(a) * rr * h * .055 * (2 - breathe);
      final px = cx + ux * cr - uy * sr + math.sin(t * 2.1 + i) * h * .004;
      final py = cy + ux * sr + uy * cr + math.cos(t * 1.7 + i * 1.3) * h * .004;
      final s = h * (.0045 + .002 * Sketch.hash(1080 + i));
      final lift = s * (.3 + .45 * math.sin(t * 7 + i * 1.9));
      wings
        ..moveTo(px - s, py - lift)
        ..lineTo(px, py)
        ..lineTo(px + s, py - lift);
    }
    _eveningStroke
      ..strokeWidth = math.max(.9, h * .0026)
      ..color = Sketch.fade(const Color(0xff4a3a48), .7 * presence);
    c.drawPath(wings, _eveningStroke);
    for (var i = 0; i < 3; i++) {
      final a = t * (.32 + .08 * i) + i * 2.1;
      final p = Offset(w * (.56 + .16 * i) + math.cos(a) * h * (.26 + .06 * i), h * (.31 + .035 * i) + math.sin(a * 2) * h * .045);
      final span = h * .0115;
      Sketch.bird(c, p, span, Sketch.fade(const Color(0xff4a3a48), .7 * presence), flap: math.sin(t * 4.6 + i * 1.7) * .55);
      final tail = Path()
        ..moveTo(p.dx - span * .16, p.dy + span * .55)
        ..lineTo(p.dx, p.dy + span * .12)
        ..lineTo(p.dx + span * .16, p.dy + span * .55);
      c.drawPath(tail, _eveningStroke..strokeWidth = math.max(.8, span * .09));
    }
  }

  /// Swifts wheeling around the Pantheon's dome; the mid band drifts, so
  /// they travel with it. Drawn behind the mid ridge like the landmarks.
  static void _eveningSwifts(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h, t = f.clock;
    final k = (w / (h * 1.6)).clamp(.5, 1.0);
    final panS = h * .17 * k;
    final panX = math.min(w * .16, w * .53 - h * .78 * k * .5 - panS * .6 + h * .02);
    final cy = (.735 + Sketch.waves(panX / h, const [(2.2, .014, .4), (.9, .005, 2.1)])) * h + h * .02 - panS * 1.55;
    final wings = Path();
    for (var i = 0; i < 7; i++) {
      final a = t * (.55 + .12 * Sketch.hash(1300 + i)) * (i.isEven ? 1 : -1) + i * .9;
      final px = panX + math.cos(a) * panS * (.85 + .5 * Sketch.hash(1310 + i));
      final py = cy + math.sin(a) * panS * (.28 + .12 * Sketch.hash(1320 + i)) - panS * .15 * Sketch.hash(1330 + i);
      final s = h * (.0052 + .0016 * Sketch.hash(1340 + i));
      final lift = s * (.25 + .5 * math.sin(t * 6 + i * 2.3));
      wings
        ..moveTo(px - s, py - lift)
        ..lineTo(px, py)
        ..lineTo(px + s, py - lift);
    }
    c.drawPath(
      wings,
      _eveningStroke
        ..strokeWidth = math.max(.9, h * .0026)
        ..color = Sketch.fade(const Color(0xff4a3a48), .72),
    );
  }

  /// A lance of olive leaf in unit size.
  static final _eveningLeaf = Path()
    ..moveTo(-1, 0)
    ..quadraticBezierTo(-.1, -.3, 1, 0)
    ..quadraticBezierTo(-.1, .3, -1, 0)
    ..close();

  /// Olive leaves tumbling slowly down the sky: grey-green on top, silver
  /// where the underside flashes as they turn.
  static void _eveningLeaves(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final spanX = w + h * .3, spanY = h * .78;
    for (var i = 0; i < 7; i++) {
      final z = Sketch.hash(1100 + i * 3), r1 = Sketch.hash(1101 + i * 3), r2 = Sketch.hash(1102 + i * 3);
      final y = (r2 * spanY + t * h * (.02 + .018 * z)) % spanY - h * .04;
      final x = (r1 * spanX - t * h * (.018 + .014 * z) + math.sin(t * .7 + i * 2.1) * h * .04) % spanX - h * .15;
      final flip = math.cos(t * (1.1 + z) + i * 1.9);
      final size = h * (.013 + .006 * z);
      c.save();
      c.translate(x, y);
      c.rotate(math.sin(t * .6 + i) * .9 + i);
      c.scale(size, size * flip);
      c.drawPath(_eveningLeaf, _eveningFill(flip > 0 ? const Color(0xff708a58) : const Color(0xffc4cdb0), .85 * presence));
      c.restore();
    }
  }

  /// The Alban hills behind the aqueduct: a lavender range, sun-warmed slopes
  /// with a hill town, and the patchwork farmland in front of them.
  static void _hills(Canvas c, double w, double h) {
    final x0 = -h * .35, x1 = w + h * .8;
    _aqueductRange(c, x0, x1, h, 0);
    _aqueductRange(c, x0, x1, h, 1);
    _aqueductFarms(c, x0, x1, h);
  }

  /// Skyline of a hill rank (0 far, 2 near) in viewport heights; `u` is x in
  /// viewport heights.
  static double _aqueductRank(double u, int rank) => switch (rank) {
    0 => .466 + Sketch.waves(u, const [(2.6, .013, .6), (1.05, .007, 2.4), (.47, .003, 1.1)]) - .032 * math.exp(-math.pow((u - 1.6) / .42, 2)),
    1 => .5 + Sketch.waves(u, const [(2.05, .012, 3.9), (.88, .006, 1.3), (.37, .003, 4.4)]),
    _ => .53 + Sketch.waves(u, const [(1.95, .019, 2.0), (.8, .009, .2), (.33, .0035, 2.9)]),
  };

  /// Crest of the foothills standing in front of the arcade, in viewport
  /// heights: valleys rest on the plain (.69) where the arcade stands tall,
  /// mounds climb it and swallow the lower storey.
  static double _aqueductCrest(double u) {
    final t = .5 + .5 * Sketch.waves(u, const [(1.75, .6, .55), (.86, .3, 2.1), (.43, .1, .3)]);
    final s = ((t - .5) / .4).clamp(0.0, 1.0);
    return .69 - .056 * s * s * (3 - 2 * s);
  }

  static List<Offset> _aqueductSample(double x0, double x1, double h, double Function(double u) y, [double step = .016]) {
    final n = ((x1 - x0) / (h * step)).ceil();
    return [for (var i = 0; i <= n; i++) Offset(x0 + i * h * step, y((x0 + i * h * step) / h) * h)];
  }

  /// A smooth line through sampled points (quadratics through midpoints).
  static Path _aqueductLine(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 1; i < p.length - 1; i++) {
      path.quadraticBezierTo(p[i].dx, p[i].dy, (p[i].dx + p[i + 1].dx) / 2, (p[i].dy + p[i + 1].dy) / 2);
    }
    return path..lineTo(p.last.dx, p.last.dy);
  }

  /// Light on a sampled skyline, sun on the left: a shaded crescent falling
  /// from every crest down its right flank and a warm rim along every
  /// climbing flank.
  static void _aqueductLight(Canvas c, List<Offset> p, double h, Color shade, Color rim, {double shadeAlpha = .3, double rimAlpha = .5, double thick = 1}) {
    final wedge = Path(), glint = Path();
    var i = 1;
    while (i < p.length - 1) {
      if (p[i].dy <= p[i - 1].dy && p[i].dy < p[i + 1].dy) {
        var j = i + 1;
        while (j < p.length - 1 && p[j + 1].dy >= p[j].dy) {
          j++;
        }
        final a = p[i], b = p[j], dx = b.dx - a.dx;
        final d = math.max(h * .02, (b.dy - a.dy) * 1.1) * thick;
        wedge.moveTo(a.dx, a.dy);
        for (var k = i + 1; k <= j; k++) {
          wedge.lineTo(p[k].dx, p[k].dy);
        }
        wedge
          ..cubicTo(b.dx - dx * .12, b.dy + d * .5, a.dx + dx * .1, a.dy + d, a.dx, a.dy)
          ..close();
        i = j;
      } else {
        i++;
      }
    }
    var open = false;
    for (var k = 0; k < p.length - 1; k++) {
      if (p[k + 1].dy < p[k].dy - h * .0004) {
        if (!open) {
          glint.moveTo(p[k].dx, p[k].dy);
          open = true;
        }
        glint.lineTo(p[k + 1].dx, p[k + 1].dy);
      } else {
        open = false;
      }
    }
    c.drawPath(wedge, Paint()..color = Sketch.fade(shade, shadeAlpha));
    c.drawPath(
      glint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(.7, h * .0022)
        ..color = Sketch.fade(rim, rimAlpha),
    );
  }

  /// A far range (0) or a sun-warmed rank (1), with light on its flanks.
  static void _aqueductRange(Canvas c, double x0, double x1, double h, int rank) {
    final pts = _aqueductSample(x0, x1, h, (u) => _aqueductRank(u, rank));
    final far = rank == 0;
    final foot = h * .72;
    final top = _hazed(far ? const Color(0xff8c86b0) : const Color(0xffa99a70), far ? .3 : .42);
    final base = _hazed(far ? const Color(0xffa9a0bc) : const Color(0xffb0a078), far ? .5 : .56);
    final body = Path.from(_aqueductLine(pts))
      ..lineTo(x1, foot)
      ..lineTo(x0, foot)
      ..close();
    c.drawPath(body, Paint()..shader = Gradient.linear(Offset(0, h * (far ? .42 : .49)), Offset(0, h * (far ? .56 : .58)), [top, base]));
    if (far) {
      // Forest and clearings mottle the slopes.
      c.save();
      c.clipPath(body);
      final forest = Paint()..color = Sketch.fade(_hazed(const Color(0xff54527e), .3), .11);
      final clear = Paint()..color = Sketch.fade(_hazed(const Color(0xffe6d4c4), .3), .1);
      for (var i = 0; i < 60; i++) {
        final x = x0 + (x1 - x0) * Sketch.hash(1200 + i);
        final y = (_aqueductRank(x / h, 0) + .008 + .05 * Sketch.hash(1260 + i)) * h;
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: h * (.05 + .13 * Sketch.hash(1320 + i)), height: h * (.007 + .011 * Sketch.hash(1380 + i))),
          i.isEven ? forest : clear,
        );
      }
      c.restore();
    } else {
      c.save();
      c.clipPath(body);
      _aqueductQuilt(
        c,
        x0,
        x1,
        h,
        (x) => _aqueductRank(x / h, 1) * h,
        const [0, .008, .018, .03, .046],
        1100,
        (col, y, r) => _hazed(col, .6),
        vine: .2,
        grove: .1,
      );
      c.restore();
    }
    _aqueductLight(
      c,
      pts,
      h,
      _hazed(far ? const Color(0xff5e5486) : const Color(0xff6c6a48), .3),
      _hazed(const Color(0xffffeccb), .1),
      shadeAlpha: far ? .3 : .34,
      rimAlpha: far ? .4 : .5,
    );
    if (far) {
      final x = pts[(pts.length * .27).round()].dx;
      var best = pts.first;
      for (final q in pts) {
        if ((q.dx - x).abs() < h * .35 && (q.dy < best.dy || (best.dx - x).abs() >= h * .35)) best = q;
      }
      _aqueductTown(c, Offset(best.dx + h * .03, best.dy + h * .011), h * .0085);
    }
  }

  /// A hill town on a far slope: a stepped huddle of cream houses under
  /// terracotta roofs, a bell tower rising over them.
  static void _aqueductTown(Canvas c, Offset base, double s) {
    final wall = Paint()..color = _hazed(const Color(0xffe8d2b0), .5), shade = Paint()..color = _hazed(const Color(0xffbb9c80), .5);
    final roof = Paint()..color = _hazed(const Color(0xffb5674a), .48);
    for (final (dx, w, hh) in const [(-2.6, .8, .42), (-1.9, .9, .6), (-1.2, .8, .82), (-.35, 1.0, .74), (.55, .9, .9), (1.4, .8, .66), (2.2, 1.0, .52), (3.0, .8, .36)]) {
      final x = base.dx + dx * s, y = base.dy + s * .12 * dx.abs() * .4;
      c.drawRect(Rect.fromLTWH(x - w * s * .5, y - hh * s, w * s, hh * s + s * .5), wall);
      c.drawRect(Rect.fromLTWH(x + w * s * .1, y - hh * s, w * s * .4, hh * s + s * .5), shade);
      c.drawRect(Rect.fromLTWH(x - w * s * .58, y - hh * s - s * .14, w * s * 1.16, s * .18), roof);
    }
    c.drawRect(Rect.fromLTWH(base.dx - s * .1, base.dy - s * 1.9, s * .34, s * 1.9), wall);
    c.drawRect(Rect.fromLTWH(base.dx + s * .08, base.dy - s * 1.9, s * .16, s * 1.9), shade);
    c.drawPath(Sketch.poly([base.dx - s * .16, base.dy - s * 1.9, base.dx + s * .07, base.dy - s * 2.45, base.dx + s * .3, base.dy - s * 1.9]), roof);
  }

  /// The near rank of hills behind the arcade: a quilt of fields and
  /// vineyards, umbrella pines along the crest and terracotta farmsteads.
  static void _aqueductFarms(Canvas c, double x0, double x1, double h) {
    double ry(double x) => _aqueductRank(x / h, 2) * h;
    final pts = _aqueductSample(x0, x1, h, (u) => _aqueductRank(u, 2));
    final body = Path.from(_aqueductLine(pts))
      ..lineTo(x1, h * .72)
      ..lineTo(x0, h * .72)
      ..close();
    c.drawPath(
      body,
      Paint()..shader = Gradient.linear(Offset(0, h * .52), Offset(0, h * .69), [_hazed(const Color(0xff566a3a), .3), _hazed(const Color(0xff6e7a48), .5)]),
    );
    c.save();
    c.clipPath(body);
    _aqueductQuilt(
      c,
      x0,
      x1,
      h,
      ry,
      const [0, .014, .032, .056, .088, .13, .17],
      900,
      (col, y, r) => _hazed(col, .26 + .2 * ((y - h * .6) / (h * .09)).clamp(0.0, 1.0)),
    );
    c.restore();
    _aqueductLight(c, pts, h, _hazed(const Color(0xff59653a), .34), _hazed(const Color(0xfffff0c8), .1), shadeAlpha: .3, rimAlpha: .5);
    var k = 0;
    for (var x = x0 + h * .1; x < x1; x += h * (.16 + .3 * Sketch.hash(950 + k))) {
      if (Sketch.hash(970 + k) < .62) {
        _aqueductPine(c, Offset(x, ry(x) + h * .005), h * (.028 + .016 * Sketch.hash(960 + k)), _hazed(const Color(0xff56643a), .38), _hazed(const Color(0xff7f8f54), .36));
      }
      k++;
    }
    for (final (i, u) in const [(0, .5), (1, 1.32), (2, 2.18), (3, 2.95)]) {
      final x = u * h;
      final s = h * (.011 + .003 * Sketch.hash(990 + i));
      _aqueductVilla(c, Offset(x, ry(x) + h * (.022 + .012 * Sketch.hash(995 + i))), s, i);
    }
  }

  /// A patchwork of fields hugging the terrain below [top]: [rows] are depths
  /// under the skyline in viewport heights; vineyard rows and olive groves
  /// dot some of the plots. Painted into whatever clip the caller has set.
  static void _aqueductQuilt(
    Canvas c,
    double x0,
    double x1,
    double h,
    double Function(double x) top,
    List<double> rows,
    int seed,
    Color Function(Color base, double y, int row) tone, {
    double vine = .3,
    double grove = .16,
  }) {
    const palette = [Color(0xffc9b06a), Color(0xff9fa257), Color(0xffb98a58), Color(0xffa8b56c), Color(0xff849b52), Color(0xffd3bd84), Color(0xffa89b5c)];
    final vines = Path();
    final dots = <Offset>[];
    for (var r = 0; r < rows.length - 1; r++) {
      // Each row is cut by slanting boundaries shared between neighbours, so
      // the plots tile without gaps; a hairline of hedge shows between them.
      final xs = <double>[], slant = <double>[];
      var x = x0 - h * .12 * Sketch.hash(seed + r);
      for (var i = 0; x < x1 + h * .2; i++) {
        final s = seed + 10 + r * 211 + i * 5;
        xs.add(x);
        slant.add(h * (Sketch.hash(s + 1) - .5) * (.03 + r * .02));
        x += h * (.05 + .07 * Sketch.hash(s)) * (1 + r * .3);
      }
      for (var i = 0; i < xs.length - 1; i++) {
        final s = seed + 10 + r * 211 + i * 5;
        final xa = xs[i], xb = xs[i + 1];
        final tl = Offset(xa, top(xa) + h * rows[r]);
        final tr = Offset(xb, top(xb) + h * rows[r]);
        final bl = Offset(xa + slant[i], top(xa + slant[i]) + h * rows[r + 1]);
        final br = Offset(xb + slant[i + 1], top(xb + slant[i + 1]) + h * rows[r + 1]);
        final mid = (tl + tr + bl + br) / 4;
        Offset pull(Offset o) => Offset.lerp(o, mid, .05)!;
        final (a, b, d, e) = (pull(tl), pull(tr), pull(br), pull(bl));
        final lum = Sketch.hash(s + 3);
        var color = palette[(Sketch.hash(s + 4) * palette.length).floor()];
        color = Sketch.mix(color, lum > .5 ? const Color(0xffffe7b0) : const Color(0xff6f6a3c), (lum - .5).abs() * .3);
        c.drawPath(Sketch.poly([a.dx, a.dy, b.dx, b.dy, d.dx, d.dy, e.dx, e.dy]), Paint()..color = tone(color, mid.dy, r));
        final v = Sketch.hash(s + 5);
        if (v < vine) {
          final along = Sketch.hash(s + 6) < .5;
          for (var q = 1; q <= 5; q++) {
            final f = q / 6;
            final l = along ? Offset.lerp(a, e, f)! : Offset.lerp(a, b, f)!;
            final m = along ? Offset.lerp(b, d, f)! : Offset.lerp(e, d, f)!;
            vines
              ..moveTo(l.dx, l.dy)
              ..lineTo(m.dx, m.dy);
          }
        } else if (v < vine + grove) {
          for (var q = 0; q < 3; q++) {
            for (var p = 0; p < 4; p++) {
              final f = (p + .5 + (q.isOdd ? .5 : 0)) / 4.5;
              final l = Offset.lerp(a, b, f)!, m = Offset.lerp(e, d, f)!;
              dots.add(Offset.lerp(l, m, (q + .8) / 3.6)!);
            }
          }
        }
      }
    }
    c.drawPath(
      vines,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0016)
        ..color = Sketch.fade(tone(const Color(0xff3f5028), h * .5, 0), .55),
    );
    c.drawPoints(
      PointMode.points,
      dots,
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, h * .004)
        ..color = Sketch.fade(tone(const Color(0xff4c5e30), h * .5, 0), .8),
    );
  }

  /// A tiny umbrella pine: a slim leaning trunk under a flat, layered crown.
  static void _aqueductPine(Canvas c, Offset base, double s, Color crown, Color lit) {
    final top = Offset(base.dx + s * .04, base.dy - s * .64);
    c.drawLine(
      base,
      top,
      Paint()
        ..color = Sketch.mix(crown, const Color(0xff3a2a20), .4)
        ..strokeWidth = math.max(.7, s * .07),
    );
    final paint = Paint()..color = crown;
    c.drawOval(Rect.fromCenter(center: top + Offset(-s * .11, s * .02), width: s * .44, height: s * .2), paint);
    c.drawOval(Rect.fromCenter(center: top + Offset(s * .12, s * .04), width: s * .4, height: s * .17), paint);
    c.drawOval(Rect.fromCenter(center: top + Offset(0, -s * .06), width: s * .46, height: s * .2), paint);
    c.drawOval(Rect.fromCenter(center: top + Offset(-s * .08, -s * .1), width: s * .26, height: s * .08), Paint()..color = lit);
  }

  /// A farmstead: cream walls under a low terracotta roof, sometimes a small
  /// tower, with a pair of cypresses.
  static void _aqueductVilla(Canvas c, Offset base, double s, int seed) {
    final wall = _hazed(const Color(0xffeedab4), .38), wallShade = _hazed(const Color(0xffc8aa84), .4);
    final roof = _hazed(const Color(0xffb8613f), .34), roofLit = _hazed(const Color(0xffd68a5c), .32);
    final w = s * 1.5, bh = s * .55;
    if (seed.isEven) {
      c.drawRect(Rect.fromLTRB(base.dx + w * .16, base.dy - bh - s * .62, base.dx + w * .44, base.dy), Paint()..color = wall);
      c.drawRect(Rect.fromLTRB(base.dx + w * .3, base.dy - bh - s * .62, base.dx + w * .44, base.dy), Paint()..color = wallShade);
      c.drawPath(
        Sketch.poly([base.dx + w * .12, base.dy - bh - s * .62, base.dx + w * .3, base.dy - bh - s * .9, base.dx + w * .48, base.dy - bh - s * .62]),
        Paint()..color = roof,
      );
    }
    c.drawRect(Rect.fromLTRB(base.dx - w / 2, base.dy - bh, base.dx + w / 2, base.dy), Paint()..color = wall);
    c.drawRect(Rect.fromLTRB(base.dx + w * .2, base.dy - bh, base.dx + w / 2, base.dy), Paint()..color = wallShade);
    c.drawPath(
      Sketch.poly([base.dx - w * .57, base.dy - bh, base.dx - w * .36, base.dy - bh - s * .3, base.dx + w * .36, base.dy - bh - s * .3, base.dx + w * .57, base.dy - bh]),
      Paint()..color = roof,
    );
    c.drawPath(
      Sketch.poly([base.dx - w * .57, base.dy - bh, base.dx - w * .36, base.dy - bh - s * .3, base.dx - w * .05, base.dy - bh - s * .3, base.dx - w * .18, base.dy - bh]),
      Paint()..color = roofLit,
    );
    c.drawRect(Rect.fromLTRB(base.dx - w * .23, base.dy - bh - s * .5, base.dx - w * .17, base.dy - bh - s * .25), Paint()..color = wallShade);
    c.drawRect(Rect.fromLTRB(base.dx - w * .28, base.dy - bh * .62, base.dx - w * .14, base.dy), Paint()..color = _hazed(const Color(0xff6a4f38), .4));
    for (final dx in const [-.66, -.78]) {
      Scenery.cypress(c, Offset(base.dx + dx * w, base.dy), s * (dx < -.7 ? 1.1 : .85), _hazed(const Color(0xff44573a), .4), _hazed(const Color(0xff6b7f4e), .38));
    }
  }

  /// The aqueduct: two storeys of piers and arches striding across the
  /// valleys, sinking into the hills at either end, and an open water
  /// channel along the top.
  static void _aqueductRun(Canvas c, double w, double h) {
    final x0 = -h * .35, x1 = w + h * .8;
    final p = h * .03;
    final n = ((x1 - x0) / p).ceil() + 1;
    final lit = _hazed(const Color(0xffeac48a), .22);
    final stone = _hazed(const Color(0xffd5a974), .27);
    final deep = _hazed(const Color(0xff5f4030), .3);
    final yWater = h * .5805, yLip = h * .5865, yBlock = h * .5915, yCorn = h * .5985, yWall = h * .6035;
    final yStr = h * .648, yStrB = h * .654, yFoot = h * .7;
    final aw = p * .58, au = p * .5, rl = aw / 2, ru = au / 2;
    final springU = h * .611 + ru, springL = h * .657 + rl;
    final xc = [for (var i = 0; i < n; i++) x0 + (i + .5) * p];
    final ground = [for (final x in xc) _aqueductCrest(x / h) * h];
    // The lower storey stands only where the ground has dropped far enough;
    // higher up, the upper arches reach down to the hillside instead.
    final low = [for (final g in ground) g >= springL + h * .008];
    final up = [for (final g in ground) g >= h * .632];
    double open(int i) => low[i] ? aw : (up[i] ? au : 0);

    final wall = Path()..fillType = PathFillType.evenOdd;
    final holes = Path();
    wall
      ..moveTo(x0, yWall)
      ..lineTo(x1, yWall)
      ..lineTo(x1, yFoot);
    for (var i = n - 1; i >= 0; i--) {
      if (!up[i]) continue;
      final r = low[i] ? rl : ru, spring = low[i] ? springL : springU;
      wall
        ..lineTo(xc[i] + r, yFoot)
        ..lineTo(xc[i] + r, spring)
        ..arcToPoint(Offset(xc[i] - r, spring), radius: Radius.circular(r), clockwise: false)
        ..lineTo(xc[i] - r, yFoot);
      if (low[i]) {
        holes
          ..moveTo(xc[i] - ru, yStr)
          ..lineTo(xc[i] - ru, springU)
          ..arcToPoint(Offset(xc[i] + ru, springU), radius: Radius.circular(ru))
          ..lineTo(xc[i] + ru, yStr)
          ..close();
      }
    }
    wall
      ..lineTo(x0, yFoot)
      ..close();
    wall.addPath(holes, Offset.zero);
    c.drawPath(
      wall,
      Paint()..shader = Gradient.linear(Offset(0, yWall), Offset(0, h * .69), [_hazed(const Color(0xffe3b97e), .25), stone, _hazed(const Color(0xffb08660), .4)], const [0, .45, 1]),
    );

    // Piers: block tones, stone courses, the shaded flank and the sun-caught edge.
    final toneLight = Path(), toneDark = Path(), courses = Path(), shadeP = Path(), rimP = Path();
    final paleStain = Path(), darkStain = Path(), ivy = Path(), ivyLit = Path(), brick = Path();
    for (var i = 0; i < n - 1; i++) {
      final a = xc[i] + (open(i) > 0 ? open(i) / 2 : p / 2);
      final b = xc[i + 1] - (open(i + 1) > 0 ? open(i + 1) / 2 : p / 2);
      final pw = b - a;
      if (pw < p * .1) continue;
      final end = math.min(yFoot, math.max(ground[i], ground[i + 1]) + h * .004);
      final s = 300 + i * 13;
      final t = Sketch.hash(s);
      final r = Rect.fromLTRB(a, yWall + h * .0024, b, end);
      if (t < .3) {
        toneDark.addRect(r);
      } else if (t > .7) {
        toneLight.addRect(r);
      }
      var y = yWall + h * (.005 + .004 * Sketch.hash(s + 1));
      for (var k = 0; y < end - h * .002; k++) {
        final inStr = y > yStr - h * .002 && y < yStrB + h * .002;
        if (!inStr && Sketch.hash(s + 20 + k) > .12) {
          courses
            ..moveTo(a + pw * .25 * Sketch.hash(s + 40 + k), y)
            ..lineTo(b - pw * .2 * Sketch.hash(s + 60 + k), y);
        }
        y += h * (.0072 + .0016 * Sketch.hash(s + 80 + k));
      }
      shadeP.addRect(Rect.fromLTRB(b - pw * .36, yWall + h * .0024, b, end));
      rimP.addRect(Rect.fromLTRB(a, yWall + h * .0024, a + math.max(.7, pw * .14), end));
      // Weathering: lime run-off and rain stains under the cornice, ivy, and
      // patches of Roman brick where a repair was made.
      if (Sketch.hash(s + 100) < .38) {
        final sx = a + pw * (.15 + .4 * Sketch.hash(s + 101)), len = h * (.02 + .03 * Sketch.hash(s + 102));
        paleStain.addPolygon([Offset(sx, yWall + h * .0024), Offset(sx + pw * .34, yWall + h * .0024), Offset(sx + pw * .17, yWall + len)], true);
      }
      if (Sketch.hash(s + 103) < .3) {
        final sx = a + pw * (.1 + .6 * Sketch.hash(s + 104)), len = h * (.03 + .04 * Sketch.hash(s + 105));
        darkStain.addPolygon([Offset(sx, yWall + h * .0024), Offset(sx + pw * .2, yWall + h * .0024), Offset(sx + pw * .1, yWall + len)], true);
      }
      if (Sketch.hash(s + 106) < .3) {
        final cx = a + pw * (.25 + .5 * Sketch.hash(s + 107)), cy = yWall + h * (.004 + .004 * Sketch.hash(s + 108));
        final rr = h * (.0034 + .0016 * Sketch.hash(s + 109));
        ivy
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: rr))
          ..addOval(Rect.fromCircle(center: Offset(cx + rr * .9, cy + rr * .8), radius: rr * .8))
          ..addOval(Rect.fromCircle(center: Offset(cx - rr * .8, cy + rr * .9), radius: rr * .7))
          ..addOval(Rect.fromCenter(center: Offset(cx - rr * .2, cy + rr * 2.4), width: h * .0016, height: rr * 2.6));
        ivyLit.addOval(Rect.fromCircle(center: Offset(cx - rr * .35, cy - rr * .35), radius: rr * .5));
      }
      if (Sketch.hash(s + 110) < .13) {
        final by = yWall + h * (.012 + .03 * Sketch.hash(s + 111));
        if (by + h * .007 < end - h * .004) brick.addRect(Rect.fromLTRB(a + pw * .08, by, b - pw * .08, by + h * .0068));
      }
    }
    c.drawPath(toneLight, Paint()..color = Sketch.fade(lit, .32));
    c.drawPath(toneDark, Paint()..color = Sketch.fade(deep, .13));
    c.drawPath(
      courses,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0014)
        ..color = Sketch.fade(deep, .2),
    );
    c.drawPath(brick, Paint()..color = Sketch.fade(_hazed(const Color(0xffb96a48), .4), .62));
    c.drawPath(paleStain, Paint()..color = Sketch.fade(_hazed(const Color(0xfff2ead8), .3), .3));
    c.drawPath(darkStain, Paint()..color = Sketch.fade(deep, .16));
    c.drawPath(shadeP, Paint()..color = Sketch.fade(deep, .2));
    c.drawPath(rimP, Paint()..color = Sketch.fade(_hazed(const Color(0xfffff0cf), .2), .55));

    // Arches: a lit archivolt ring with voussoir joints outside, a dark soffit
    // ring inside, and the shaded left jamb of every opening.
    final ring = Path(), soffit = Path(), joints = Path(), jamb = Path(), jambLit = Path(), gap = Path();
    final ringW = h * .0032, soffitW = h * .0027;
    void arch(double cx, double r, double spring, double bottom) {
      gap
        ..moveTo(cx - r, bottom)
        ..lineTo(cx - r, spring)
        ..arcToPoint(Offset(cx + r, spring), radius: Radius.circular(r))
        ..lineTo(cx + r, bottom)
        ..close();
      ring.addArc(Rect.fromCircle(center: Offset(cx, spring), radius: r + ringW / 2), math.pi, math.pi);
      soffit.addArc(Rect.fromCircle(center: Offset(cx, spring), radius: r - soffitW / 2), math.pi, math.pi);
      for (var k = 1; k <= 5; k++) {
        final ang = math.pi + k * math.pi / 6, cs = math.cos(ang), sn = math.sin(ang);
        joints
          ..moveTo(cx + cs * (r + ringW * .05), spring + sn * (r + ringW * .05))
          ..lineTo(cx + cs * (r + ringW), spring + sn * (r + ringW));
      }
      if (bottom > spring) {
        jamb.addRect(Rect.fromLTRB(cx - r, spring, cx - r + h * .0016, bottom));
        jambLit.addRect(Rect.fromLTRB(cx + r - h * .001, spring, cx + r, bottom));
      }
    }
    for (var i = 0; i < n; i++) {
      if (!up[i]) continue;
      if (low[i]) {
        arch(xc[i], rl, springL, math.min(yFoot, ground[i] + h * .003));
        arch(xc[i], ru, springU, yStr);
      } else {
        arch(xc[i], ru, springU, math.min(yFoot, ground[i] + h * .003));
      }
    }
    c.drawPath(gap, Paint()..color = Sketch.fade(deep, .16));
    c.drawPath(jamb, Paint()..color = Sketch.fade(deep, .38));
    c.drawPath(jambLit, Paint()..color = Sketch.fade(lit, .7));
    c.drawPath(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringW
        ..color = Sketch.fade(_hazed(const Color(0xffefc98e), .2), .9),
    );
    c.drawPath(
      joints,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0011)
        ..color = Sketch.fade(deep, .42),
    );
    c.drawPath(
      soffit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = soffitW
        ..color = Sketch.fade(deep, .55),
    );

    // The string course between the storeys, over every bay of the lower arcade.
    final str = Path(), strTop = Path(), strShadow = Path();
    for (var i = 0; i < n; i++) {
      if (!low[i]) continue;
      str.addRect(Rect.fromLTRB(xc[i] - p / 2 - .4, yStr, xc[i] + p / 2 + .4, yStrB));
      strTop.addRect(Rect.fromLTRB(xc[i] - p / 2 - .4, yStr, xc[i] + p / 2 + .4, yStr + h * .0013));
      strShadow.addRect(Rect.fromLTRB(xc[i] - p / 2 - .4, yStrB, xc[i] + p / 2 + .4, yStrB + h * .002));
    }
    c.drawPath(str, Paint()..color = _hazed(const Color(0xffe6bd84), .24));
    c.drawPath(strTop, Paint()..color = Sketch.fade(_hazed(const Color(0xfffff0cf), .2), .7));
    c.drawPath(strShadow, Paint()..color = Sketch.fade(deep, .3));
    c.drawPath(ivy, Paint()..color = _hazed(const Color(0xff56743a), .42));
    c.drawPath(ivyLit, Paint()..color = _hazed(const Color(0xff86a55a), .38));

    // Cornice, the channel wall, its coping, and the water itself.
    c.drawRect(Rect.fromLTRB(x0, yCorn, x1, yWall), Paint()..color = lit);
    c.drawRect(Rect.fromLTRB(x0, yWall, x1, yWall + h * .0024), Paint()..color = Sketch.fade(deep, .38));
    c.drawRect(Rect.fromLTRB(x0, yBlock, x1, yCorn), Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(x0, yBlock, x1, yBlock + h * .0011), Paint()..color = Sketch.fade(deep, .16));
    c.drawRect(Rect.fromLTRB(x0, yLip, x1, yBlock), Paint()..color = _hazed(const Color(0xfff4d69c), .2));
    c.drawRect(Rect.fromLTRB(x0, yWater - h * .0018, x1, yWater), Paint()..color = _hazed(const Color(0xffa98a68), .36));
    c.drawRect(
      Rect.fromLTRB(x0, yWater, x1, yLip),
      Paint()..shader = Gradient.linear(Offset(x0, 0), Offset(x1, 0), [_hazed(const Color(0xffe6d6a6), .16), _hazed(const Color(0xff9cc4c6), .22), _hazed(const Color(0xffe2d09c), .18)], const [0, .5, 1]),
    );
    c.drawRect(Rect.fromLTRB(x0, yWater, x1, yWater + h * .0012), Paint()..color = Sketch.fade(deep, .16));
    final sparkle = Path();
    for (var i = 0; i < 44; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(400 + i);
      sparkle.addRect(Rect.fromLTWH(x, yWater + h * .0022, h * (.005 + .008 * Sketch.hash(450 + i)), h * .0014));
    }
    c.drawPath(sparkle, Paint()..color = Sketch.fade(const Color(0xfffffaea), .85));

    // Inspection shafts rise from the channel every few bays; caper and grass
    // take root along the coping.
    final tower = Paint()..color = stone, towerShade = Paint()..color = Sketch.fade(deep, .22);
    for (var i = 5; i < n; i += 11) {
      if (!up[i]) continue;
      final cx = xc[i], top = yWater - h * .0125;
      c.drawRect(Rect.fromLTRB(cx - h * .0055, top, cx + h * .0055, yBlock), tower);
      c.drawRect(Rect.fromLTRB(cx + h * .0005, top, cx + h * .0055, yBlock), towerShade);
      c.drawRect(Rect.fromLTRB(cx - h * .0068, top - h * .002, cx + h * .0068, top), Paint()..color = lit);
      c.drawRect(Rect.fromLTRB(cx - h * .002, top + h * .0025, cx + h * .002, top + h * .0075), Paint()..color = Sketch.fade(deep, .7));
    }
    final green = Paint()..color = _hazed(const Color(0xff65853f), .42), greenLit = Paint()..color = _hazed(const Color(0xff97b263), .38);
    for (var i = 0; i < 26; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(500 + i), r = h * (.0028 + .0022 * Sketch.hash(540 + i));
      c.drawOval(Rect.fromCenter(center: Offset(x, yBlock - r * .3), width: r * 2.6, height: r * 1.7), green);
      c.drawCircle(Offset(x - r * .35, yBlock - r * .8), r * .5, greenLit);
    }
  }

  /// Foothill mounds standing in front of the arcade, with vineyards,
  /// orchards, umbrella pines, a flock, cypress rows and a farmstead each.
  static void _aqueductFront(Canvas c, double w, double h) {
    final x0 = -h * .35, x1 = w + h * .8;
    final pts = _aqueductSample(x0, x1, h, _aqueductCrest, .012);
    double cy(double x) => _aqueductCrest(x / h) * h;
    const ground = Color(0xffcfb3a0);
    final body = Path.from(_aqueductLine(pts))
      ..lineTo(x1, h * .705)
      ..lineTo(x0, h * .705)
      ..close();
    c.drawPath(
      body,
      Paint()..shader = Gradient.linear(Offset(0, h * .63), Offset(0, h * .69), [_hazed(const Color(0xff8a9050), .2), ground]),
    );
    c.save();
    c.clipPath(body);
    _aqueductQuilt(
      c,
      x0,
      x1,
      h,
      cy,
      const [0, .008, .018, .032, .05],
      1300,
      (col, y, r) => Sketch.mix(_hazed(col, .14), ground, ((y - h * .645) / (h * .05)).clamp(0.0, 1.0) * .5),
      vine: .34,
      grove: .16,
    );
    c.restore();
    _aqueductLight(c, pts, h, _hazed(const Color(0xff55603a), .3), _hazed(const Color(0xfffff0c8), .12), shadeAlpha: .3, rimAlpha: .45, thick: 1.2);
    final flock = <Offset>[];
    var k = 0;
    for (final px in _aqueductPeaks(h)) {
      for (final (dx, s) in [(-.1 - .05 * Sketch.hash(1400 + k), .036), (.05 + .04 * Sketch.hash(1410 + k), .031), (.3, .027)]) {
        final x = px + dx * h;
        if (cy(x) < h * .684) {
          _aqueductPine(c, Offset(x, cy(x) + h * .004), h * (s + .006 * Sketch.hash(1420 + k)), _hazed(const Color(0xff56643a), .38), _hazed(const Color(0xff7f8f54), .36));
        }
      }
      final vx = px + h * .17;
      _aqueductVilla(c, Offset(vx, cy(vx) + h * .014), h * .015, k);
      for (var j = 0; j < 9; j++) {
        final fx = px - h * (.3 + .05 * Sketch.hash(1430 + k * 9 + j));
        flock.add(Offset(fx, cy(fx) + h * (.014 + .012 * Sketch.hash(1450 + k * 9 + j))));
      }
      k++;
    }
    c.drawPoints(
      PointMode.points,
      flock,
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.1, h * .0032)
        ..color = _hazed(const Color(0xfff6efe0), .2),
    );
  }

  static final _aqueductPeakCache = <double, List<double>>{};

  /// Crest x positions (in px at viewport height [h]) of the foothill mounds,
  /// so farmsteads and their smoke can share the same spots.
  static List<double> _aqueductPeaks(double h) => _aqueductPeakCache.putIfAbsent(h, () {
    final out = <double>[];
    for (var u = -.4; u < 8; u += .01) {
      final y = _aqueductCrest(u);
      if (y < .68 && y <= _aqueductCrest(u - .01) && y < _aqueductCrest(u + .01) && (out.isEmpty || u * h - out.last > h * .5)) out.add(u * h);
    }
    return out;
  });

  static final _aqueductPlains = <(double, double), ({List<(Path, Color)> fields, Path hedges, Path trees, Path road, Path verge, Path hay, Path wood, Path ox})>{};

  /// The plain between the aqueduct and the near hills, recorded once per
  /// viewport: patchwork fields in fading perspective, hedges, poplars, a
  /// dusty road, and the shapes of a hay cart and its ox at the origin.
  static ({List<(Path, Color)> fields, Path hedges, Path trees, Path road, Path verge, Path hay, Path wood, Path ox}) _aqueductPlainShapes(double w, double h) {
    final cached = _aqueductPlains[(w, h)];
    if (cached != null) return cached;
    final x0 = -h * .35, x1 = w + h * .8;
    const palette = [Color(0xffd9bf80), Color(0xffb0ac68), Color(0xffc99a68), Color(0xffbcbe80), Color(0xff9db06a), Color(0xffdcc79a)];
    const rows = [.69, .7, .714, .734, .762, .8];
    final groups = [for (final _ in palette) Path()];
    final hedges = Path(), trees = Path();
    for (var r = 0; r < rows.length - 1; r++) {
      var x = x0 - h * .1 * Sketch.hash(1500 + r);
      var prev = Offset(x, 0);
      var prevSlant = 0.0;
      for (var i = 0; x < x1 + h * .2; i++) {
        final sd = 1510 + r * 173 + i * 3;
        final cw = h * (.07 + .1 * Sketch.hash(sd)) * (1 + r * .55);
        final slant = h * (Sketch.hash(sd + 1) - .5) * (.06 + r * .06);
        final y0 = h * rows[r], y1 = h * rows[r + 1];
        if (i > 0) {
          groups[(Sketch.hash(sd + 2) * palette.length).floor()]
            ..moveTo(prev.dx, y0)
            ..lineTo(x, y0)
            ..lineTo(x + slant, y1)
            ..lineTo(prev.dx + prevSlant, y1)
            ..close();
          hedges
            ..moveTo(x, y0)
            ..lineTo(x + slant, y1)
            ..moveTo(prev.dx + prevSlant, y1)
            ..lineTo(x + slant, y1);
        }
        prev = Offset(x, y0);
        prevSlant = slant;
        x += cw;
      }
    }
    for (var i = 0; i < 26; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(1600 + i), y = h * (.694 + .026 * Sketch.hash(1640 + i)), th = h * (.011 + .008 * Sketch.hash(1680 + i));
      trees.addOval(Rect.fromCenter(center: Offset(x, y - th / 2), width: th * .3, height: th));
    }
    final road = Path(), verge = Path();
    final hw = h * .0024;
    double cy(double x) => h * .706 + h * .009 * math.sin(x / h * 1.9 + .6);
    final step = h * .06;
    final n = ((x1 - x0) / step).ceil();
    road.moveTo(x0, cy(x0) - hw);
    verge.moveTo(x0, cy(x0) - hw);
    for (var i = 1; i <= n; i++) {
      final x = x0 + i * step;
      road.lineTo(x, cy(x) - hw);
      verge.lineTo(x, cy(x) - hw);
    }
    for (var i = n; i >= 0; i--) {
      final x = x0 + i * step;
      road.lineTo(x, cy(x) + hw);
    }
    road.close();
    verge.moveTo(x0, cy(x0) + hw);
    for (var i = 1; i <= n; i++) {
      final x = x0 + i * step;
      verge.lineTo(x, cy(x) + hw);
    }
    // A hay cart and its ox, wheels on the ground at y = 0, facing right.
    final u = h * .011;
    final hay = Path()
      ..addOval(Rect.fromCenter(center: Offset(0, -u * 1.15), width: u * 2.4, height: u * 1.3))
      ..addOval(Rect.fromCenter(center: Offset(-u * .3, -u * 1.7), width: u * 1.4, height: u * .8));
    final wood = Path()
      ..addRect(Rect.fromLTRB(-u * 1.1, -u * .8, u * 1.1, -u * .55))
      ..addRect(Rect.fromLTRB(u * 1.05, -u * .68, u * 1.75, -u * .58));
    final ox = Path()
      ..addOval(Rect.fromCenter(center: Offset(u * 2.6, -u * .95), width: u * 1.6, height: u * .8))
      ..addOval(Rect.fromCenter(center: Offset(u * 3.5, -u * 1.12), width: u * .55, height: u * .42))
      ..addRect(Rect.fromLTRB(u * 1.95, -u * .7, u * 2.1, 0))
      ..addRect(Rect.fromLTRB(u * 2.25, -u * .7, u * 2.4, 0))
      ..addRect(Rect.fromLTRB(u * 2.9, -u * .7, u * 3.05, 0))
      ..addRect(Rect.fromLTRB(u * 3.15, -u * .7, u * 3.3, 0))
      ..addRect(Rect.fromLTRB(u * 3.55, -u * 1.45, u * 3.65, -u * 1.2));
    final shapes = (
      fields: [for (var i = 0; i < palette.length; i++) (groups[i], palette[i])],
      hedges: hedges,
      trees: trees,
      road: road,
      verge: verge,
      hay: hay,
      wood: wood,
      ox: ox,
    );
    if (_aqueductPlains.length > 6) _aqueductPlains.remove(_aqueductPlains.keys.first);
    return _aqueductPlains[(w, h)] = shapes;
  }

  /// The plain in front of the aqueduct, drawn over the far ground: fields,
  /// poplars, the road and a hay cart trundling along it.
  static void _aqueductPlain(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final g = _aqueductPlainShapes(w, h);
    final paint = Paint();
    for (final (path, color) in g.fields) {
      paint.color = Sketch.fade(_hazed(color, .14), .78 * presence);
      c.drawPath(path, paint);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, h * .0014)
      ..color = Sketch.fade(_hazed(const Color(0xff6a7842), .2), .32 * presence);
    c.drawPath(g.hedges, line);
    paint.color = Sketch.fade(_hazed(const Color(0xff55683c), .28), .85 * presence);
    c.drawPath(g.trees, paint);
    paint.color = Sketch.fade(_hazed(const Color(0xffe9d3aa), .15), .8 * presence);
    c.drawPath(g.road, paint);
    line
      ..strokeWidth = math.max(.5, h * .0012)
      ..color = Sketch.fade(_hazed(const Color(0xffa8875f), .25), .5 * presence);
    c.drawPath(g.verge, line);
    // The cart creeps along the road, wheels and all.
    final x0 = -h * .35, span = w + h * 1.15;
    // Seconds into Rome's leg of the tour, or into a campaign level.
    final local = f.reducedMotion
        ? 8.0
        : f.held
        ? f.clock
        : f.clock % WorldTour.loop - WorldRegion.rome.index * WorldTour.leg;
    final x = x0 + (h * 2.1 - local * h * .0115) % span;
    final y = h * .706 + h * .009 * math.sin(x / h * 1.9 + .6) + h * .0022;
    final u = h * .011;
    c.save();
    c.translate(x, y);
    c.scale(-1, 1);
    paint.color = Sketch.fade(const Color(0xff6b4a34), .9 * presence);
    c.drawPath(g.wood, paint);
    paint.color = Sketch.fade(_hazed(const Color(0xffe0b85c), .1), .95 * presence);
    c.drawPath(g.hay, paint);
    paint.color = Sketch.fade(const Color(0xff5a4032), .9 * presence);
    c.drawPath(g.ox, paint);
    line
      ..strokeWidth = math.max(.6, u * .16)
      ..color = Sketch.fade(const Color(0xff4a3427), .95 * presence);
    c.drawCircle(Offset(-u * .3, -u * .32), u * .3, line);
    c.restore();
  }

  /// Small living touches over the aqueduct: glints drifting down the water
  /// channel and smoke from the farmhouse chimneys.
  static void _aqueductLife(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final fade = presence * presence * presence;
    if (fade <= .01) return;
    final x0 = -h * .35, span = w + h * 1.15;
    final paint = Paint();
    for (var i = 0; i < 9; i++) {
      final x = x0 + (i / 9 + f.clock * .006 + .04 * Sketch.hash(700 + i)) % 1 * span;
      final tw = math.sin(f.clock * .9 + i * 1.7) * .5 + .5;
      paint.color = Sketch.fade(const Color(0xfffffaea), (.3 + .6 * tw) * fade);
      c.drawRect(Rect.fromLTWH(x, h * .5828, h * (.008 + .008 * Sketch.hash(710 + i)), h * .0015), paint);
    }
    final peaks = _aqueductPeaks(h);
    for (var k = 0; k < math.min(2, peaks.length); k++) {
      final vx = peaks[k] + h * .17, s = h * .015;
      final src = Offset(vx - s * .3, _aqueductCrest(vx / h) * h + h * .014 - s * 1.05);
      for (var j = 0; j < 6; j++) {
        final age = (f.clock * .07 + j / 6 + k * .37) % 1;
        final at = src + Offset(math.sin(age * 4 + j + k) * s * .2 + age * age * s * 2.4, -age * h * .08);
        paint.color = Sketch.fade(const Color(0xfff5ebd8), .24 * (1 - age) * math.min(1.0, age * 5) * fade);
        c.drawOval(Rect.fromCenter(center: at, width: h * (.006 + .012 * age), height: h * (.005 + .008 * age)), paint);
      }
    }
  }

  /// A stone pine, the umbrella of the Roman skyline: a leaning, barked trunk
  /// that forks into limbs under a broad crown of needle pads, dark
  /// underneath and lit on top.
  static void _pine(Canvas c, Offset base, double s, Color trunk, Color crown, {Color? lit}) {
    final litColor = lit ?? Sketch.mix(crown, const Color(0xffffffff), .16);
    final dark = Sketch.mix(crown, const Color(0xff10200f), .36);
    final barkLit = Sketch.mix(trunk, litColor, .3);
    final barkDark = Sketch.mix(trunk, const Color(0xff1a1208), .38);
    final top = Offset(base.dx + s * .04, base.dy - s * .72);
    final fork = Offset(top.dx - s * .005, top.dy + s * .17);
    final p = Paint()..color = trunk;
    final left = Offset(base.dx - s * .03, base.dy), right = Offset(base.dx + s * .03, base.dy);
    final ctrlL = Offset(base.dx - s * .014, base.dy - s * .32), ctrlR = Offset(base.dx + s * .04, base.dy - s * .3);
    c.drawPath(
      Path()
        ..moveTo(left.dx, left.dy)
        ..quadraticBezierTo(ctrlL.dx, ctrlL.dy, fork.dx - s * .015, fork.dy)
        ..lineTo(fork.dx + s * .015, fork.dy)
        ..quadraticBezierTo(ctrlR.dx, ctrlR.dy, right.dx, right.dy)
        ..close(),
      p,
    );
    // Bark: a lit left edge, a shaded right flank, and a few fissures.
    c.drawPath(
      Path()
        ..moveTo(left.dx, left.dy)
        ..quadraticBezierTo(ctrlL.dx, ctrlL.dy, fork.dx - s * .015, fork.dy)
        ..lineTo(fork.dx - s * .004, fork.dy)
        ..quadraticBezierTo(ctrlL.dx + s * .014, ctrlL.dy, base.dx - s * .006, base.dy)
        ..close(),
      p..color = barkLit,
    );
    c.drawPath(
      Path()
        ..moveTo(right.dx, right.dy)
        ..quadraticBezierTo(ctrlR.dx, ctrlR.dy, fork.dx + s * .015, fork.dy)
        ..lineTo(fork.dx + s * .004, fork.dy)
        ..quadraticBezierTo(ctrlR.dx - s * .018, ctrlR.dy, base.dx + s * .008, base.dy)
        ..close(),
      p..color = barkDark,
    );
    final fissure = Paint()
      ..color = Sketch.fade(barkDark, .8)
      ..strokeWidth = math.max(.5, s * .004);
    for (final (t, dx) in const [(.12, -.008), (.3, .004), (.5, -.004), (.7, .006)]) {
      final y = base.dy - s * .5 * t * 1.4;
      c.drawLine(Offset(base.dx + dx * s, y), Offset(base.dx + (dx + .004) * s, y - s * .05), fissure);
    }
    // Limbs fork out under the crown.
    for (final (dx, dy, w) in const [(-.15, .0, .011), (.0, -.05, .012), (.16, .02, .011)]) {
      final tip = Offset(top.dx + dx * s, top.dy + dy * s);
      c.drawPath(
        Sketch.poly([fork.dx - s * w, fork.dy, tip.dx - s * w * .4, tip.dy, tip.dx + s * w * .4, tip.dy, fork.dx + s * w, fork.dy]),
        p..color = trunk,
      );
    }
    // The crown: overlapping needle pads, each dark below and lit on top.
    for (final (dx, dy, rw, rh, tone) in const [
      (-.21, .045, .13, .045, 0),
      (.22, .05, .12, .042, 0),
      (-.12, -.012, .16, .055, 1),
      (.12, -.006, .16, .052, 1),
      (-.26, .0, .1, .036, 1),
      (.27, .012, .1, .036, 1),
      (0.0, -.065, .15, .05, 2),
      (.0, .028, .2, .048, 1),
    ]) {
      final cx = top.dx + dx * s, cy = top.dy + dy * s;
      final body = tone == 0 ? Sketch.mix(crown, dark, .5) : crown;
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy + rh * s * .42), width: rw * s * 2, height: rh * s * 1.8), p..color = dark);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rw * s * 2, height: rh * s * 1.85), p..color = body);
      for (var k = 0; k < 5; k++) {
        final a = math.pi * (1.12 + .76 * k / 4);
        c.drawCircle(Offset(cx + math.cos(a) * rw * s * .92, cy + math.sin(a) * rh * s * .8), rh * s * .5, p..color = body);
      }
      if (tone > 0) {
        c.drawOval(Rect.fromCenter(center: Offset(cx - rw * s * .2, cy - rh * s * .42), width: rw * s * 1.35, height: rh * s * .85), p..color = tone == 2 ? litColor : Sketch.mix(crown, litColor, .55));
      }
    }
    // Needle sparkle along the lit crest.
    final spark = Paint()..color = Sketch.fade(litColor, .9);
    for (var k = 0; k < 7; k++) {
      final a = math.pi * (1.1 + .5 * Sketch.hash(k * 3 + 1));
      c.drawCircle(Offset(top.dx + math.cos(a) * s * (.1 + .16 * Sketch.hash(k * 3 + 2)), top.dy - s * .05 + math.sin(a) * s * .05), s * .011, spark);
    }
  }

  /// A votive altar of travertine: moulded base, a die with a garland swag
  /// and bucrania, a projecting cornice and rolled pulvini around the focus,
  /// where a small fire burns (the incense in `live` rises from it).
  static void _altar(Canvas c, Offset base, double s) {
    final lit = _forumTint(_forumLit), stone = _forumTint(const Color(0xffe2cba4)), shade = _forumTint(_forumShade), deep = _forumTint(_forumDeep);
    final p = Paint();
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy - v * s;
    void box(Color col, double l, double b, double r, double t) => c.drawRect(Rect.fromLTRB(x(l), y(t), x(r), y(b)), p..color = col);
    box(shade, -.56, 0, .56, .09);
    box(stone, -.5, .09, .5, .17);
    box(lit, -.5, .15, .5, .17);
    box(stone, -.4, .17, .4, .82);
    box(lit, -.4, .17, -.34, .82);
    box(Sketch.fade(shade, .7), .18, .17, .4, .82);
    // An inscription panel with a garland swagged over it.
    box(Sketch.fade(deep, .28), -.22, .28, .2, .5);
    box(Sketch.fade(lit, .6), -.22, .48, .2, .5);
    for (var i = 0; i < 3; i++) {
      box(Sketch.fade(deep, .55), -.16 + i * .12, .38, -.16 + i * .12 + .08, .4);
    }
    c.drawPath(
      Path()
        ..moveTo(x(-.33), y(.76))
        ..quadraticBezierTo(x(0), y(.5), x(.33), y(.76)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, s * .09)
        ..strokeCap = StrokeCap.round
        ..color = _forumTint(const Color(0xff7d8f52)),
    );
    for (final side in const [-1.0, 1.0]) {
      c.drawCircle(Offset(x(side * .3), y(.76)), s * .055, p..color = Sketch.mix(stone, lit, .5));
    }
    box(lit, -.5, .82, .5, .92);
    box(Sketch.fade(deep, .4), -.4, .79, .4, .82);
    box(shade, .3, .82, .5, .92);
    // Rolled pulvini frame the focus.
    for (final side in const [-1.0, 1.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(x(side * .4), y(.99)), width: s * .3, height: s * .18), p..color = side < 0 ? lit : stone);
      c.drawCircle(Offset(x(side * .47), y(.99)), s * .04, p..color = Sketch.fade(deep, .6));
    }
    box(stone, -.4, .92, .4, .97);
    c.drawOval(Rect.fromCenter(center: Offset(x(0), y(1.0)), width: s * .56, height: s * .16), p..color = const Color(0xff40302c));
    c.drawPath(
      Sketch.poly([x(-.12), y(1.0), x(-.03), y(1.2), x(.02), y(1.1), x(.07), y(1.26), x(.13), y(1.0)]),
      p..color = const Color(0xffd9843c),
    );
    c.drawPath(Sketch.poly([x(-.05), y(1.0), x(.02), y(1.14), x(.08), y(1.0)]), p..color = const Color(0xfff2c46a));
  }

  /// An honorary statue on a plinth: a toga-clad figure in marble, a scroll
  /// or a raised hand depending on [seed].
  static void _forumStatue(Canvas c, Offset base, double s, int seed) {
    final lit = _forumTint(_forumLit), stone = _forumTint(_forumMarble), shade = _forumTint(_forumShade), deep = _forumTint(_forumDeep);
    final p = Paint();
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy - v * s;
    void box(Color col, double l, double b, double r, double t) => c.drawRect(Rect.fromLTRB(x(l), y(t), x(r), y(b)), p..color = col);
    void poly(Color col, List<double> uv) => c.drawPath(Sketch.poly([for (var i = 0; i < uv.length; i++) i.isOdd ? -uv[i] : uv[i]], at: base, s: s), p..color = col);
    box(shade, -.21, 0, .21, .07);
    box(stone, -.165, .07, .165, .29);
    box(lit, -.165, .07, -.125, .29);
    box(Sketch.fade(shade, .8), .06, .07, .165, .29);
    box(Sketch.fade(deep, .5), -.09, .16, .09, .2);
    box(lit, -.2, .29, .2, .335);
    box(Sketch.fade(shade, .7), .05, .29, .2, .31);
    // The figure: hem, folds, shoulders, head.
    poly(stone, [-.1, .335, -.09, .55, -.08, .72, -.095, .78, -.03, .81, .03, .81, .095, .78, .08, .72, .09, .55, .1, .335]);
    poly(shade, [.02, .335, .1, .335, .09, .55, .08, .72, .095, .78, .03, .81, .02, .81]);
    poly(lit, [-.1, .335, -.09, .55, -.08, .72, -.095, .78, -.06, .8, -.055, .55, -.06, .335]);
    poly(Sketch.fade(deep, .38), [-.09, .77, -.055, .8, .09, .58, .09, .52]);
    poly(Sketch.fade(deep, .3), [-.06, .5, -.02, .5, .05, .38, .0, .38]);
    switch (seed % 3) {
      case 0:
        // A raised hand: the orator.
        poly(stone, [-.09, .77, -.135, .9, -.115, .93, -.06, .8]);
        c.drawCircle(Offset(x(-.13), y(.94)), s * .022, p..color = lit);
      case 1:
        // A scroll held at the waist.
        poly(stone, [.08, .72, .15, .66, .16, .69, .09, .76]);
        box(lit, .13, .62, .175, .68);
      default:
        // A veiled head and a hand at the breast.
        poly(shade, [-.05, .87, .0, .93, .055, .87, .05, .8, -.045, .8]);
    }
    c.drawCircle(Offset(x(0), y(.875)), s * .052, p..color = stone);
    c.drawCircle(Offset(x(-.015), y(.885)), s * .03, p..color = lit);
    c.drawArc(Rect.fromCenter(center: Offset(x(0), y(.89)), width: s * .112, height: s * .1), math.pi * 1.05, math.pi * .95, false, p..color = Sketch.mix(stone, deep, .3));
  }

  /// A honorary column on a stepped base, crowned with a bronze statue,
  /// like the one that still stands in the forum. [u] is its unit height.
  static void _forumHonor(Canvas c, Offset base, double u) {
    final lit = _forumTint(_forumLit), stone = _forumTint(_forumMarble), shade = _forumTint(_forumShade), deep = _forumTint(_forumDeep);
    final p = Paint();
    double x(double s) => base.dx + s * u;
    double y(double v) => base.dy - v * u;
    void box(Color col, double l, double b, double r, double t) => c.drawRect(Rect.fromLTRB(x(l), y(t), x(r), y(b)), p..color = col);
    box(shade, -.17, 0, .17, .03);
    box(stone, -.145, .03, .145, .06);
    box(lit, -.145, .052, .145, .06);
    box(stone, -.12, .06, .12, .09);
    box(lit, -.12, .082, .12, .09);
    box(stone, -.085, .09, .085, .2);
    box(lit, -.085, .09, -.06, .2);
    box(Sketch.fade(shade, .75), .035, .09, .085, .2);
    box(Sketch.fade(deep, .4), -.045, .13, .045, .16);
    box(lit, -.1, .2, .1, .225);
    _forumColumn(c, x(0), y(.225), u, shaft: .98, half: .03);
    final capTop = .225 + .016 + .98 + .07;
    box(stone, -.05, capTop, .05, capTop + .02);
    box(lit, -.05, capTop + .014, .05, capTop + .02);
    // The bronze emperor, small against the sky: a gilt-and-verdigris figure.
    const bronze = Color(0xffa8864e), lightBronze = Color(0xffd2b676), verdigris = Color(0xff7f8f68);
    final bt = capTop + .02;
    c.drawPath(
      Sketch.poly([x(-.03), y(bt), x(-.026), y(bt + .05), x(-.016), y(bt + .085), x(.016), y(bt + .085), x(.026), y(bt + .05), x(.03), y(bt)]),
      p..color = _forumTint(bronze),
    );
    c.drawPath(Sketch.poly([x(-.03), y(bt), x(-.026), y(bt + .05), x(-.016), y(bt + .085), x(-.006), y(bt + .085), x(-.012), y(bt + .04), x(-.012), y(bt)]), p..color = _forumTint(lightBronze));
    c.drawPath(Sketch.poly([x(.012), y(bt), x(.03), y(bt), x(.026), y(bt + .05), x(.016), y(bt + .085), x(.006), y(bt + .085)]), p..color = _forumTint(verdigris));
    c.drawCircle(Offset(x(0), y(bt + .1)), u * .017, p..color = _forumTint(lightBronze));
    c.drawLine(Offset(x(.03), y(bt + .01)), Offset(x(.05), y(bt + .13)), Paint()..color = _forumTint(bronze)..strokeWidth = math.max(.6, u * .006));
  }

  /// The three columns that stand over the forum from a broken temple: a
  /// tall podium, a fragment of entablature and the stump of a fourth.
  static void _forumRuin(Canvas c, Offset base, double s) {
    final lit = _forumTint(_forumLit), stone = _forumTint(_forumMarble), shade = _forumTint(_forumShade), deep = _forumTint(_forumDeep);
    final p = Paint();
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy - v * s;
    void box(Color col, double l, double b, double r, double t) => c.drawRect(Rect.fromLTRB(x(l), y(t), x(r), y(b)), p..color = col);
    void poly(Color col, List<double> uv) => c.drawPath(Sketch.poly([for (var i = 0; i < uv.length; i++) i.isOdd ? -uv[i] : uv[i]], at: base, s: s), p..color = col);
    // The podium: a tall block of coursed tufa with a ragged top on the left.
    final tufa = _forumTint(const Color(0xffd8bf98));
    box(shade, -.66, 0, .66, .04);
    poly(tufa, [-.62, .04, -.62, .26, -.55, .28, -.47, .3, -.4, .3, -.3, .32, .62, .32, .62, .04]);
    box(Sketch.fade(lit, .8), -.62, .04, -.585, .27);
    box(Sketch.fade(shade, .7), .36, .04, .62, .32);
    for (final v in const [.09, .14, .19, .245, .295]) {
      box(Sketch.fade(deep, .2), -.62, v, .62, v + .0035);
    }
    for (final (u, v) in const [(-.4, .04), (-.2, .09), (.05, .14), (.3, .19), (-.1, .245), (.48, .295), (.1, .04), (-.5, .19)]) {
      box(Sketch.fade(deep, .18), u, v, u + .004, v + .05);
    }
    box(lit, -.4, .3, .64, .335);
    box(Sketch.fade(deep, .4), -.4, .28, .62, .3);
    // A vaulted opening in the podium, and ivy tumbling over its edge.
    final vault = _forumTint(const Color(0xff4f3a36));
    box(vault, -.31, .05, -.17, .17);
    c.drawCircle(Offset(x(-.24), y(.17)), s * .07, p..color = vault);
    c.drawArc(Rect.fromCircle(center: Offset(x(-.24), y(.17)), radius: s * .078), math.pi, math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = s * .012..color = Sketch.fade(lit, .8));
    box(Sketch.fade(lit, .8), -.325, .05, -.31, .17);
    box(Sketch.fade(shade, .8), -.17, .05, -.155, .17);
    for (final (u, v, r) in const [(-.3, .335, .022), (-.35, .33, .017), (-.25, .34, .018), (-.4, .322, .014), (-.31, .3, .013), (-.36, .292, .011), (-.2, .338, .014)]) {
      c.drawCircle(Offset(x(u), y(v)), s * r, p..color = _forumTint(const Color(0xff587a3e)));
      c.drawCircle(Offset(x(u - r * .3), y(v + r * .35)), s * r * .5, p..color = _forumTint(const Color(0xff8cae5e)));
    }
    // The cella wall stub that still stands behind the columns.
    final brick = _forumTint(const Color(0xffbd8864));
    poly(brick, [-.42, .335, -.42, .66, -.32, .7, -.24, .62, -.2, .335]);
    poly(Sketch.fade(deep, .3), [-.29, .335, -.2, .335, -.24, .62, -.27, .6]);
    for (var v = .37; v < .6; v += .034) {
      box(Sketch.fade(deep, .24), -.42, v, -.25, v + .003);
    }
    box(Sketch.fade(lit, .75), -.42, .335, -.395, .66);
    box(lit, -.43, .335, -.19, .345);
    // Three columns and the bit of entablature they still carry.
    for (final u in const [.12, .3, .48]) {
      _forumColumn(c, x(u), y(.335), s, shaft: .37);
    }
    _forumColumn(c, x(-.08), y(.335), s, shaft: .19, broken: true);
    const top = .335 + .016 + .37 + .07;
    box(stone, .04, top, .58, top + .05);
    box(Sketch.fade(shade, .55), .04, top + .017, .58, top + .02);
    box(lit, .035, top + .045, .585, top + .052);
    box(stone, .0, top + .05, .585, top + .1);
    box(Sketch.mix(stone, shade, .4), .3, top + .05, .585, top + .1);
    box(Sketch.fade(deep, .4), .0, top + .05, .585, top + .06);
    box(shade, -.02, top + .1, .6, top + .112);
    poly(stone, [-.02, top + .112, .6, top + .112, .6, top + .16, .48, top + .175, .3, top + .14, .18, top + .15, .1, top + .125, -.02, top + .13]);
    poly(Sketch.mix(stone, shade, .4), [.3, top + .112, .6, top + .112, .6, top + .16, .48, top + .175, .3, top + .14]);
    box(lit, -.02, top + .112, .28, top + .118);
    // A caper bush in the crack of the cornice, a fallen drum below.
    for (final (u, v, r) in const [(.1, .0, .022), (.135, -.004, .016), (.06, .001, .015)]) {
      c.drawCircle(Offset(x(u), y(top + .155 + v)), s * r, p..color = _forumTint(const Color(0xff6d8a4a)));
    }
    c.drawCircle(Offset(x(.11), y(top + .168)), s * .01, p..color = _forumTint(const Color(0xff9db56e)));
    c.drawOval(Rect.fromCenter(center: Offset(x(.76), y(.035)), width: s * .3, height: s * .075), p..color = stone);
    c.drawOval(Rect.fromCenter(center: Offset(x(.74), y(.05)), width: s * .22, height: s * .04), p..color = lit);
    c.drawOval(Rect.fromCenter(center: Offset(x(.79), y(.028)), width: s * .1, height: s * .042), p..color = Sketch.fade(shade, .6));
  }

  /// A flame of cypress: a dark body under rows of feathery tufts, lit on the
  /// left and deep on the right, leaning a little differently for every
  /// [seed]. Upper tufts sit behind lower ones, like shingles.
  static void _forumCypress(Canvas c, Offset base, double s, int seed) {
    final body = _hazed(const Color(0xff2b472b), .06), mid = _hazed(const Color(0xff3d6238), .06), lit = _hazed(const Color(0xff54803f), .07), tip = _hazed(const Color(0xff779f55), .08), deep = _hazed(const Color(0xff213a26), .06);
    final lean = (Sketch.hash(seed * 7 + 1) - .5) * .06;
    final wmax = s * (.1 + .016 * Sketch.hash(seed * 7 + 2));
    double cx(double t) => base.dx + lean * s * t * t;
    double hw(double t) {
      final flame = math.pow(1 - t, .8).toDouble() * (.7 + .3 * math.sin(math.min(1.0, t * 3.4) * math.pi / 2));
      final lump = 1 + .05 * math.sin(t * 31 + seed * 3.1) + .035 * math.sin(t * 59 + seed * 1.7);
      return wmax * flame * lump;
    }
    const n = 18;
    final outline = Path()..moveTo(cx(0) - hw(0), base.dy);
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      outline.lineTo(cx(t) - hw(t), base.dy - t * s);
    }
    for (var i = n - 1; i >= 0; i--) {
      final t = i / n;
      outline.lineTo(cx(t) + hw(t), base.dy - t * s);
    }
    outline.close();
    final p = Paint()..color = body;
    c.drawPath(outline, p);
    // Rows of feathery tufts, lit on the left and deep on the right; each tone
    // is one path, drawn dark to light.
    final tones = [Path(), Path(), Path(), Path()];
    const count = 120;
    for (var k = 0; k < count; k++) {
      final t = .94 - .93 * k / (count - 1) + (Sketch.hash(seed * 131 + k * 5 + 4) - .5) * .012;
      final xr = (Sketch.hash(seed * 131 + k * 5) * 2 - 1) * .8;
      final shade = xr + (Sketch.hash(seed * 131 + k * 5 + 1) - .5) * .55;
      final tone = shade < -.6 ? 3 : (shade < -.08 ? 2 : (shade < .42 ? 1 : 0));
      final local = hw(t);
      final x = cx(t) + xr * local, y = base.dy - t * s;
      final sz = s * (.03 + .03 * Sketch.hash(seed * 131 + k * 5 + 2)) * math.min(1.0, .4 + local / wmax);
      final tw = math.max(local * .5, s * .01);
      final out = xr * tw * .5;
      tones[tone]
        ..moveTo(x - tw * .5, y + sz * .25)
        ..quadraticBezierTo(x - tw * .55 + out * .4, y - sz * .35, x + out, y - sz)
        ..quadraticBezierTo(x + tw * .6 + out * .4, y - sz * .3, x + tw * .5, y + sz * .25)
        ..close();
    }
    for (var i = 0; i < 4; i++) {
      c.drawPath(tones[i], p..color = [deep, mid, lit, tip][i]);
    }
    c.drawPath(
      Sketch.poly([cx(.86) - hw(.86) * .7, base.dy - s * .86, cx(1), base.dy - s, cx(.86) + hw(.86) * .7, base.dy - s * .86, cx(.9), base.dy - s * .8]),
      p..color = Sketch.mix(mid, lit, .4),
    );
    c.drawPath(
      Sketch.poly([cx(.9) - hw(.9) * .6, base.dy - s * .9, cx(1), base.dy - s, cx(.93), base.dy - s * .87]),
      p..color = tip,
    );
  }

  /// A rounded Mediterranean shrub with lit tops and a few blossoms.
  static void _forumShrub(Canvas c, Offset base, double s, int seed, {Color? bloom}) {
    final body = _hazed(const Color(0xff3f6035), .06), mid = _hazed(const Color(0xff5c8347), .06), lit = _hazed(const Color(0xff8fb264), .07);
    final p = Paint();
    for (var i = 0; i < 5; i++) {
      final dx = (i - 2) * .32 + (Sketch.hash(seed * 11 + i) - .5) * .18;
      final r = .34 - (i - 2).abs() * .06 + .05 * Sketch.hash(seed * 11 + i + 5);
      c.drawCircle(Offset(base.dx + dx * s, base.dy - r * s * .8), r * s, p..color = body);
    }
    for (var i = 0; i < 5; i++) {
      final dx = (i - 2) * .32 + (Sketch.hash(seed * 11 + i) - .5) * .18;
      final r = .34 - (i - 2).abs() * .06 + .05 * Sketch.hash(seed * 11 + i + 5);
      c.drawCircle(Offset(base.dx + (dx - .05) * s, base.dy - r * s * 1.0), r * s * .78, p..color = mid);
      c.drawCircle(Offset(base.dx + (dx - .1) * s, base.dy - r * s * 1.22), r * s * .42, p..color = lit);
    }
    if (bloom != null) {
      p.color = bloom;
      for (var i = 0; i < 7; i++) {
        c.drawCircle(Offset(base.dx + (Sketch.hash(seed * 5 + i) - .5) * s * 1.1, base.dy - s * (.25 + .5 * Sketch.hash(seed * 5 + i + 9))), math.max(.8, s * .05), p);
      }
    }
  }

  // Monuments palette (before haze): warm travertine and marble for the
  // portico and arch, grey Egyptian granite shafts, rosy brick for the
  // rotunda, weathered lead for the dome, dark umber for openings.
  static const _monumentMarble = Color(0xffeedcb6);
  static const _monumentMarbleShade = Color(0xffc9ab80);
  static const _monumentUmber = Color(0xff5a4030);
  static const _monumentGranite = Color(0xffbab2a6);
  static const _monumentGraniteShade = Color(0xff7d7671);
  static const _monumentBrick = Color(0xffd6a67e);
  static const _monumentBrickShade = Color(0xffa27856);
  static const _monumentLead = Color(0xffb6adb2);
  static const _monumentLeadShade = Color(0xff6f6878);
  static const _monumentBronze = Color(0xffa8804a);

  /// Pigeons wheel slowly round the Pantheon's dome, in the same timed
  /// coordinates as the mid band's features.
  void _monumentLife(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final k = (w / (h * 1.6)).clamp(.5, 1.0);
    final panS = h * .17 * k, colS = h * .78 * k;
    final panX = math.min(w * .16, w * .53 - colS * .5 - panS * .6 + h * .02);
    final u = panS * 1.35;
    final gy = _y(Depth.mid, panX, h) + h * .02 - panS * .105;
    final centre = Offset(panX, gy - u * 1.16);
    final color = Sketch.fade(_hazed(const Color(0xff6d6068), .3), .8 * presence);
    for (var i = 0; i < 5; i++) {
      final a = f.clock * (.42 + .07 * (i % 3)) * (i.isEven ? 1 : -1) + i * 1.26;
      final p = centre + Offset(math.cos(a) * u * (.78 + .12 * (i % 2)), math.sin(a) * u * (.16 + .04 * (i % 3)));
      Sketch.bird(c, p, h * .0085, color, flap: math.sin(f.clock * 6 + i * 1.7) * .7);
    }
  }

  /// A round-headed opening as a path: [cx] centre, [hw] half width, the
  /// curve springs at [spring] and the sides run down to [bottom].
  static Path _monumentArchway(double cx, double hw, double spring, double bottom) => Path()
    ..moveTo(cx - hw, bottom)
    ..lineTo(cx - hw, spring)
    ..arcToPoint(Offset(cx + hw, spring), radius: Radius.circular(hw))
    ..lineTo(cx + hw, bottom)
    ..close();

  /// The Pantheon in front elevation: eight granite columns under a plain
  /// pediment, the taller gabled block behind, the brick rotunda with its
  /// stepped rings, and a lead dome cut open by the oculus. Drawn larger than
  /// its layout slot [s] so it reads as a landmark at phone size.
  static void _pantheon(Canvas c, Offset base, double s) {
    final u = s * 1.35;
    final gy = base.dy - s * .105;
    double px(double f) => base.dx + u * f;
    double py(double f) => gy - u * f;
    Rect box(double l, double b, double r, double t) => Rect.fromLTRB(px(l), py(t), px(r), py(b));
    Path tri(double x0, double y0, double x1, double y1, double x2, double y2) =>
        Sketch.poly([px(x0), py(y0), px(x1), py(y1), px(x2), py(y2)]);
    final stone = _hazed(_monumentMarble, .18);
    final stoneShade = _hazed(_monumentMarbleShade, .2);
    final deep = _hazed(_monumentUmber, .3);
    final lit = _hazed(const Color(0xfffff0d2), .12);
    final brickLit = _hazed(_monumentBrick, .2);
    final brickShade = _hazed(_monumentBrickShade, .24);
    final p = Paint();
    final hair = math.max(.5, u * .006);

    // Podium and steps (the ridge hides whatever sinks below it).
    c.drawRect(box(-.5, -.12, .5, .0), p..color = stoneShade);
    for (var i = 0; i < 3; i++) {
      final hw = .48 - i * .014, y0 = i * .014, y1 = y0 + .014;
      c.drawRect(box(-hw, y0, hw, y1), p..color = stone);
      c.drawRect(box(-hw, y1 - .004, hw, y1), p..color = lit);
      c.drawRect(box(hw * .4, y0, hw, y1 - .004), p..color = Sketch.fade(deep, .12));
    }

    // Rotunda: a cylinder shaded from lit left to deep right.
    final drum = Paint()
      ..shader = Gradient.linear(Offset(px(-.55), 0), Offset(px(.55), 0), [
        _hazed(const Color(0xffe6bc90), .18),
        brickLit,
        Sketch.mix(brickLit, brickShade, .7),
        _hazed(const Color(0xff835f44), .26),
      ], const [0, .38, .8, 1]);
    c.drawRect(box(-.55, 0, .55, .525), drum);
    // Relieving arches show only on the flanks; the porch hides the rest.
    final niche = Paint()..color = Sketch.fade(_hazed(const Color(0xff6a4a36), .26), .5);
    for (final (y0, y1) in const [(.035, .175), (.215, .345)]) {
      for (final a in const [-1.22, -.86, .86, 1.22]) {
        final x = .55 * math.sin(a), hw = .036 * math.cos(a) + .006;
        c.drawPath(_monumentArchway(px(x), hw * u, py(y1 - hw), py(y0)), niche);
      }
    }
    final pilaster = Paint()..color = Sketch.fade(lit, .4);
    for (final a in const [-1.35, -1.1, .95, 1.2, 1.38]) {
      final x = .55 * math.sin(a);
      c.drawRect(box(x - .008, .36, x + .004, .486), pilaster);
    }
    for (final f in const [.185, .355]) {
      c.drawRect(box(-.554, f, .554, f + .011), p..color = Sketch.fade(lit, .7));
      c.drawRect(box(-.55, f - .009, .55, f), p..color = Sketch.fade(deep, .22));
    }
    // Rain has streaked the drum below its cornice.
    final stain = Paint()..color = Sketch.fade(deep, .1);
    for (var i = 0; i < 10; i++) {
      final x = (i.isEven ? -1 : 1) * (.42 + .12 * Sketch.hash(i + 645));
      c.drawRect(box(x, .1 + .25 * Sketch.hash(i + 646), x + .008 + .008 * Sketch.hash(i + 647), .474), stain);
    }
    // Rotunda cornice, then the seven stepped rings that buttress the dome.
    c.drawRect(box(-.575, .487, .575, .525), p..color = stone);
    c.drawRect(box(-.56, .474, .56, .487), p..color = Sketch.fade(deep, .3));
    c.drawRect(box(.2, .487, .575, .525), p..color = Sketch.fade(deep, .2));
    c.drawRect(box(-.575, .518, .575, .525), p..color = lit);
    for (var i = 0; i < 6; i++) {
      final y0 = .525 + i * .0215, y1 = y0 + .0215, hw = .545 - i * .0155;
      c.drawRect(box(-hw, y0, hw, y1), drum);
      c.drawRect(box(-hw, y1 - .005, hw, y1), p..color = Sketch.fade(lit, .6));
      c.drawRect(box(-hw, y0, hw, y0 + .004), p..color = Sketch.fade(deep, .28));
    }

    // Lead dome: a hemisphere whose crown is cut by the oculus.
    const cy = .5485, rd = .4715, ringTop = .654, ringHw = .46, oculusY = 1.006;
    final ring = Rect.fromCircle(center: Offset(px(0), py(cy)), radius: u * rd);
    final a0 = math.atan2(-(ringTop - cy), -ringHw);
    final oh = math.sqrt(rd * rd - (oculusY - cy) * (oculusY - cy));
    final a1 = math.atan2(-(oculusY - cy), -oh);
    final dome = Path()
      ..moveTo(px(-ringHw), py(ringTop))
      ..arcTo(ring, a0, a1 - a0, false)
      ..lineTo(px(oh), py(oculusY))
      ..arcTo(ring, -math.pi - a1, a1 - a0, false)
      ..close();
    final leadLit = _hazed(_monumentLead, .2), leadShade = _hazed(_monumentLeadShade, .24);
    c.drawPath(
      dome,
      Paint()
        ..shader = Gradient.radial(Offset(px(-.17), py(.88)), u * .78, [
          _hazed(const Color(0xffd8d0d2), .16),
          leadLit,
          Sketch.mix(leadLit, leadShade, .75),
          leadShade,
        ], const [0, .3, .68, 1]),
    );
    // Lead seams run up the shell to the oculus, foreshortened toward the limb.
    final seams = Path();
    final lam0 = math.asin((ringTop - cy) / rd), lam1 = math.asin((oculusY - cy) / rd);
    for (var k = -3; k <= 3; k++) {
      final th = k * .38;
      for (var j = 0; j <= 6; j++) {
        final lam = lam0 + (lam1 - lam0) * j / 6;
        final x = px(rd * math.cos(lam) * math.sin(th)), y = py(cy + rd * math.sin(lam));
        if (j == 0) {
          seams.moveTo(x, y);
        } else {
          seams.lineTo(x, y);
        }
      }
    }
    c.drawPath(
      seams,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(leadShade, .2),
    );
    // Oculus: a bronze-rimmed round eye open to the sky.
    c.drawOval(Rect.fromCenter(center: Offset(px(0), py(oculusY + .004)), width: u * (oh * 2 + .024), height: u * .042), p..color = _hazed(_monumentBronze, .2));
    c.drawOval(Rect.fromCenter(center: Offset(px(0), py(oculusY + .008)), width: u * oh * 2, height: u * .028), p..color = _hazed(const Color(0xff3c2c26), .3));
    c.drawOval(Rect.fromCenter(center: Offset(px(.02), py(oculusY + .002)), width: u * oh * 1.1, height: u * .009), p..color = Sketch.fade(_hazed(const Color(0xffffe0a8), .1), .5));

    // The gabled block that joins the porch to the rotunda, with the ghost
    // outline of an earlier, steeper pediment on its face.
    final blockPaint = Paint()
      ..shader = Gradient.linear(Offset(px(-.36), 0), Offset(px(.36), 0), [
        _hazed(const Color(0xfff0d9b0), .16),
        _hazed(const Color(0xffe0c398), .2),
        _hazed(const Color(0xffbc9a72), .24),
      ], const [0, .55, 1]);
    c.drawPath(Sketch.poly([px(-.36), py(.42), px(-.36), py(.676), px(0), py(.75), px(.36), py(.676), px(.36), py(.42)]), blockPaint);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(.8, u * .012);
    c.drawPath(
      Path()
        ..moveTo(px(-.36), py(.676))
        ..lineTo(px(0), py(.75))
        ..lineTo(px(.36), py(.676)),
      edge..color = Sketch.fade(lit, .8),
    );
    c.drawPath(
      Path()
        ..moveTo(px(-.3), py(.596))
        ..lineTo(px(0), py(.708))
        ..lineTo(px(.3), py(.596)),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(deep, .26),
    );
    p.style = PaintingStyle.fill;
    // Corner pilasters and a string course keep the block's face from going flat.
    c.drawRect(box(-.36, .42, -.335, .676), p..color = Sketch.fade(lit, .4));
    c.drawRect(box(.335, .42, .36, .676), p..color = Sketch.fade(deep, .14));
    c.drawRect(box(-.36, .655, .36, .662), p..color = Sketch.fade(deep, .12));

    // Portico: a dim porch behind eight granite columns.
    c.drawRect(
      box(-.362, .042, .362, .44),
      Paint()
        ..shader = Gradient.linear(Offset(0, py(.44)), Offset(0, py(.042)), [
          _hazed(const Color(0xff33241d), .28),
          _hazed(const Color(0xff5c4230), .28),
          _hazed(const Color(0xff7a5a40), .26),
        ], const [0, .55, 1]),
    );
    final recess = Paint()..color = _hazed(const Color(0xff8d6c4e), .25);
    for (final x in const [-.2, .2]) {
      c.drawPath(_monumentArchway(px(x), u * .017, py(.25), py(.075)), recess);
    }
    // The great bronze door, framed by a lintel.
    c.drawRect(box(-.034, .042, .034, .32), p..color = _hazed(const Color(0xff8a6a3c), .26));
    c.drawRect(box(-.034, .042, -.02, .32), p..color = Sketch.fade(_hazed(const Color(0xffd8b060), .2), .55));
    c.drawRect(box(-.044, .32, .044, .334), p..color = stone);
    // Columns, the axial bay a little wider than the rest.
    const cols = [-.3325, -.2425, -.1525, -.0625, .0625, .1525, .2425, .3325];
    final granLit = _hazed(_monumentGranite, .16), granShade = _hazed(_monumentGraniteShade, .2);
    final granMid = Sketch.mix(granLit, granShade, .4);
    for (final x in cols) {
      c.drawRect(box(x - .026, .046, x + .026, .404), p..color = granMid);
      c.drawRect(box(x - .026, .046, x - .01, .404), p..color = granLit);
      c.drawRect(box(x + .012, .046, x + .026, .404), p..color = granShade);
      // Attic base and a Corinthian capital of white marble.
      c.drawRect(box(x - .032, .042, x + .032, .056), p..color = stone);
      c.drawPath(Sketch.poly([px(x - .022), py(.404), px(x + .022), py(.404), px(x + .033), py(.435), px(x - .033), py(.435)]), p..color = stone);
      c.drawRect(box(x - .038, .432, x + .038, .441), p..color = lit);
      c.drawRect(box(x + .008, .404, x + .035, .432), p..color = Sketch.fade(deep, .16));
    }

    // Entablature with the lettered frieze, the cornice and its cast shadow.
    c.drawRect(box(-.39, .441, .39, .462), p..color = stone);
    c.drawRect(box(-.39, .462, .39, .49), p..color = _hazed(const Color(0xffeed6ac), .18));
    c.drawRect(box(-.39, .478, .39, .49), p..color = Sketch.fade(deep, .16));
    final letters = Path();
    var lx = -.29;
    for (var i = 0; lx < .29; i++) {
      final len = .008 + .012 * Sketch.hash(i + 640);
      letters
        ..moveTo(px(lx), py(.474))
        ..lineTo(px(lx + len), py(.474));
      lx += len + .012;
    }
    c.drawPath(
      letters,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, u * .011)
        ..color = Sketch.fade(deep, .5),
    );
    c.drawRect(box(-.418, .49, .418, .508), p..color = stone);
    final teeth = Path();
    for (var x = -.4; x < .4; x += .028) {
      teeth
        ..moveTo(px(x), py(.491))
        ..lineTo(px(x), py(.499));
    }
    c.drawPath(
      teeth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, u * .008)
        ..color = Sketch.fade(deep, .22),
    );
    c.drawRect(box(-.418, .504, .418, .511), p..color = lit);
    c.drawRect(box(-.4, .485, .4, .492), p..color = Sketch.fade(deep, .32));
    c.drawRect(box(.2, .49, .418, .508), p..color = Sketch.fade(deep, .13));
    // The pediment: raking cornice around a shadowed tympanum with the
    // bronze eagle and wreath that once filled it.
    c.drawPath(tri(-.418, .508, .418, .508, 0, .652), p..color = stone);
    c.drawPath(tri(-.418, .508, 0, .652, -.39, .508), p..color = Sketch.fade(lit, .65));
    c.drawPath(
      tri(-.35, .518, .35, .518, 0, .6335),
      Paint()
        ..shader = Gradient.linear(Offset(px(-.35), 0), Offset(px(.35), 0), [
          _hazed(const Color(0xffc4a37c), .2),
          _hazed(const Color(0xffb08f68), .22),
          _hazed(const Color(0xff8f7050), .26),
        ], const [0, .5, 1]),
    );
    final bronze = _hazed(_monumentBronze, .2);
    final relief = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, u * .008)
      ..color = Sketch.fade(bronze, .65);
    c.drawCircle(Offset(px(0), py(.566)), u * .04, relief);
    c.drawPath(
      Path()
        ..moveTo(px(0), py(.572))
        ..quadraticBezierTo(px(-.05), py(.61), px(-.088), py(.578))
        ..moveTo(px(0), py(.572))
        ..quadraticBezierTo(px(.05), py(.61), px(.088), py(.578)),
      relief..strokeWidth = math.max(.8, u * .013),
    );
    c.drawOval(Rect.fromCenter(center: Offset(px(0), py(.559)), width: u * .022, height: u * .042), p..color = bronze);
    c.drawCircle(Offset(px(0), py(.586)), u * .008, p..color = bronze);

    // Passers-by on the steps give it scale.
    for (final (x, tone) in const [(-.27, 0xffe8d6b8), (-.2, 0xffb0503c), (-.02, 0xffe8d6b8), (.11, 0xff8a6a4a), (.26, 0xffd6c0a0)]) {
      final f = _hazed(Color(tone), .2);
      c.drawRect(box(x - .008, .042, x + .008, .078), p..color = f);
      c.drawCircle(Offset(px(x), py(.088)), u * .009, p..color = _hazed(const Color(0xffb88a68), .2));
    }
    // A soft, tinted ambient shadow where the podium meets the ground.
    c.drawRect(box(-.5, -.02, .5, .008), p..color = Sketch.fade(deep, .18));
  }

  static const _colosseumLit = Color(0xfff1d49c);
  static const _colosseumShade = Color(0xff986f54);

  /// Where `features(Depth.mid)` seats the Colosseum: base point and scale.
  (Offset, double) _colosseumSpot(Size size) {
    final w = size.width, h = size.height;
    final k = (w / (h * 1.6)).clamp(.5, 1.0);
    final cx = w * .53;
    return (Offset(cx, _y(Depth.mid, cx, h) + h * .02), h * .78 * k);
  }

  /// The Colosseum from outside, lit from the upper left: three tiers of
  /// arches (Tuscan, Ionic, Corinthian half-columns) under a windowed attic
  /// with mast corbels. The arcade turns away at both ends like the real
  /// ellipse; its right flank is broken down in steps, showing the taller
  /// inner ring behind.
  static void _colosseum(Canvas c, Offset base, double s) {
    // The ridge hides the foot; lifting the ring keeps the first tier whole.
    final b = Offset(base.dx, base.dy - s * .02);
    const top = _ColosseumRing.crown;
    // Pier tops, left to right: everything stands to the crown until the
    // wall gives way in ragged steps to the first storey.
    final inner = _ColosseumRing(
      Offset(b.dx + s * .01, b.dy - s * .034),
      s * .8,
      const [top, top, top, top, top, top, top, top, top, top, top, top, top, top, top, .302, .298, .276, .282, .25, .254, .22, .226, .19, .186, .152, .158],
      outer: false,
      first: 11,
      seed: 950,
      haze: .3,
      sun: .5,
    );
    final outer = _ColosseumRing(
      b,
      s,
      const [top, top, top, top, top, top, top, top, top, top, top, top, top, top, top, top, .3, .262, .224, .192, .17, .152, .13, .118, .134, .1, .09, .11, .084, .078, .09, .07, .062],
      outer: true,
      seed: 900,
      haze: .18,
    );
    _colosseumDrawRing(c, inner);
    _colosseumDrawRing(c, outer);
  }

  static void _colosseumArch(Path p, double xl, double xr, double ySill, double ySpring) {
    final r = (xr - xl) / 2;
    p
      ..moveTo(xl, ySill)
      ..lineTo(xl, ySpring)
      ..arcToPoint(Offset(xr, ySpring), radius: Radius.circular(r), clockwise: true)
      ..lineTo(xr, ySill)
      ..close();
  }

  static void _colosseumDrawRing(Canvas c, _ColosseumRing g) {
    final n = g.n, s = g.s, j0 = g.first, tops = _ColosseumRing.tops;
    final wall = g.ramp(g.face);
    final mid = g.ramp((t) => Sketch.mix(g.face(t), const Color(0xfffff0cc), .14));
    final hi = g.ramp((t) => Sketch.mix(g.face(t), const Color(0xfffff4d8), .42));
    final lo = g.ramp((t) => Sketch.mix(g.face(t), const Color(0xff5c3f34), .4));
    final veil = g.ramp((t) => Sketch.fade(const Color(0xff5a3c30), .34 - .14 * t));
    final inkTop = _hazed(const Color(0xff3d2b25), g.haze + .06), inkBottom = _hazed(const Color(0xff7a5a48), g.haze + .06);
    final ink = Paint()..color = inkTop;
    final brickInk = g.ramp((t) => _hazed(Sketch.mix(const Color(0xff7d4c3b), const Color(0xffbb7c58), t), g.haze + .06));

    // The wall itself: one outline, broken piers ragged, broken arches notched.
    final out = Path()..moveTo(g.xs[j0] - g.hp[j0], g.base.dy + s * .07);
    for (var j = j0; j <= n; j++) {
      final xl = g.xs[j] - g.hp[j], xr = g.xs[j] + g.hp[j], z = g.zp[j];
      if (z < _ColosseumRing.crown - .002) {
        final r0 = Sketch.hash(j * 7 + g.seed), r1 = Sketch.hash(j * 7 + g.seed + 1), r2 = Sketch.hash(j * 7 + g.seed + 2);
        out
          ..lineTo(xl, g.y(z - .004 * r0, j))
          ..lineTo(xl + (xr - xl) * (.3 + .3 * r1), g.y(z + .006 * r1, j))
          ..lineTo(xr, g.y(z - .005 * r2, j));
      } else {
        out
          ..lineTo(xl, g.y(z, j))
          ..lineTo(xr, g.y(z, j));
      }
      if (j < n) {
        final zc = g.cut[j], x2 = g.xs[j + 1] - g.hp[j + 1];
        out.lineTo(xr, g.y(zc, j));
        if (zc < _ColosseumRing.crown - .01) {
          // Torn masonry along the broken top.
          for (var q = 1; q < 4; q++) {
            final u = q / 4 + .08 * (Sketch.hash(g.seed + j * 5 + q) - .5);
            out.lineTo(xr + (x2 - xr) * u, g.y(zc + .008 * (Sketch.hash(g.seed + j * 11 + q * 3) - .35), j));
          }
        }
        out.lineTo(x2, g.y(zc, j + 1));
      }
    }
    out
      ..lineTo(g.xs[n] + g.hp[n], g.base.dy + s * .07)
      ..close();
    c.drawPath(out, Paint()..shader = wall);

    // The travertine podium the whole ring stands on, in two low steps.
    final podium = Path(), podiumLit = Path(), podiumJoint = Path();
    for (var i = j0; i < n; i++) {
      if (g.arches[i] < 1) continue;
      podium.addRect(Rect.fromLTRB(g.xs[i], g.ym(.004, i), g.xs[i + 1], g.ym(-.05, i)));
      podiumLit.addRect(Rect.fromLTRB(g.xs[i], g.ym(.004, i), g.xs[i + 1], g.ym(.0005, i)));
      podiumJoint
        ..moveTo(g.xs[i], g.ym(-.014, i))
        ..lineTo(g.xs[i + 1], g.ym(-.014, i))
        ..moveTo(g.xs[i], g.ym(-.032, i))
        ..lineTo(g.xs[i + 1], g.ym(-.032, i));
    }
    c.drawPath(podium, Paint()..shader = lo);
    c.drawPath(
      podiumJoint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .0016)
        ..color = const Color(0x40402c22),
    );
    c.drawPath(podiumLit, Paint()..shader = hi);

    // Arched openings: a lit or shaded reveal, a dark hall behind, a fine
    // archivolt and a keystone.
    final ringLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, s * .0022)
      ..shader = hi;
    for (var k = 0; k < 3; k++) {
      final sillZ = k == 0 ? .002 : tops[k - 1] + .008, headZ = tops[k] - .02;
      final revR = Path(), revL = Path(), dk = Path(), ring = Path(), keys = Path(), brick = Path(), door = Path();
      for (var i = j0; i < n; i++) {
        if (g.arches[i] <= k) continue;
        final xl = g.xs[i] + g.hp[i], xr = g.xs[i + 1] - g.hp[i + 1], ow = xr - xl;
        if (ow < s * .003) continue;
        final ySill = g.ym(sillZ, i), yHead = g.ym(headZ, i);
        final ySpring = math.min(yHead + ow / 2, ySill);
        final th = (g.th[i] + g.th[i + 1]) / 2;
        final rv = ow * .3 * math.sin(th).abs();
        if (th >= 0) {
          _colosseumArch(revR, xl, xr, ySill, ySpring);
          _colosseumArch(dk, xl, xr - rv, ySill, ySpring);
        } else {
          _colosseumArch(revL, xl, xr, ySill, ySpring);
          _colosseumArch(dk, xl + rv, xr, ySill, ySpring);
        }
        final mx = (xl + xr) / 2;
        if (k == 0 && ow > s * .012 && Sketch.hash(g.seed + i * 43) < .16) {
          // Bricked up long ago, leaving a small doorway.
          _colosseumArch(brick, xl, xr, ySill, ySpring);
          final dw = ow * .18;
          _colosseumArch(door, mx - dw, mx + dw, ySill, math.min(ySill - dw * 2.1, ySpring + ow * .12));
        }
        ring.addArc(Rect.fromCircle(center: Offset(mx, ySpring), radius: ow / 2 + s * .004), math.pi, math.pi);
        keys.addRect(Rect.fromLTRB(mx - ow * .08, yHead - s * .0085, mx + ow * .08, yHead - s * .001));
      }
      c.drawPath(revR, Paint()..shader = hi);
      c.drawPath(revL, Paint()..shader = lo);
      c.drawPath(
        dk,
        Paint()..shader = Gradient.linear(Offset(0, g.base.dy - headZ * s * .96), Offset(0, g.base.dy - sillZ * s * .96), [inkTop, inkBottom]),
      );
      if (k == 0) {
        c.drawPath(brick, Paint()..shader = brickInk);
        c.drawPath(door, ink);
      }
      c.drawPath(ring, ringLine);
      c.drawPath(keys, Paint()..shader = mid);
    }

    // Engaged half-columns, one order per storey, and the attic pilasters.
    for (var k = 0; k < 4; k++) {
      final f = _ColosseumRing.floor(k), t = tops[k];
      final capH = const [.005, .0055, .0075, .0045][k];
      final body = Path(), litP = Path(), shadeP = Path(), caps = Path(), capTop = Path(), bases = Path(), cast = Path();
      final light = Path(), dark = Path(), warm = Path();
      for (var j = j0; j <= n; j++) {
        if (g.zp[j] < f + .02) continue;
        final x = g.xs[j], hw = g.hp[j] * (k == 3 ? .7 : .92);
        final broken = g.zp[j] < t - .009 - capH + .001;
        final zTop = broken ? g.zp[j] : t - .009 - capH, zBase = f + .003;
        body.addRect(Rect.fromLTRB(x - hw, g.y(zTop, j), x + hw, g.y(zBase, j)));
        // Drums and blocks of travertine, a shade lighter, darker or warmer.
        final rows = k == 3 ? 3 : 4, rh = (zTop - zBase) / rows;
        for (var r = 0; r < rows; r++) {
          final p = Sketch.hash(g.seed + j * 31 + k * 13 + r * 5);
          final target = p < .26 ? light : (p < .5 ? dark : (p < .58 ? warm : null));
          target?.addRect(Rect.fromLTRB(x - hw, g.y(zBase + (r + 1) * rh, j), x + hw, g.y(zBase + r * rh, j)));
        }
        litP.addRect(Rect.fromLTRB(x - hw, g.y(zTop, j), x - hw * .3, g.y(zBase, j)));
        shadeP.addRect(Rect.fromLTRB(x + hw * .4, g.y(zTop, j), x + hw, g.y(zBase, j)));
        cast.addRect(Rect.fromLTRB(x + hw, g.y(zTop - .004, j), x + hw + g.hp[j] * .35, g.y(zBase, j)));
        if (!broken) {
          caps.addRect(Rect.fromLTRB(x - hw * 1.32, g.y(t - .009, j), x + hw * 1.32, g.y(t - .009 - capH, j)));
          capTop.addRect(Rect.fromLTRB(x - hw * 1.32, g.y(t - .009, j), x + hw * 1.32, g.y(t - .0105, j)));
        }
        bases.addRect(Rect.fromLTRB(x - hw * 1.24, g.y(zBase, j), x + hw * 1.24, g.y(f, j)));
      }
      c.drawPath(cast, Paint()..shader = veil);
      c.drawPath(body, Paint()..shader = mid);
      c.drawPath(light, Paint()..color = const Color(0x22fff3d0));
      c.drawPath(dark, Paint()..color = const Color(0x1c583a2c));
      c.drawPath(warm, Paint()..color = const Color(0x24c88a4a));
      c.drawPath(litP, Paint()..shader = hi);
      c.drawPath(shadeP, Paint()..shader = lo);
      c.drawPath(bases, Paint()..shader = lo);
      c.drawPath(caps, Paint()..shader = wall);
      c.drawPath(capTop, Paint()..shader = hi);
    }

    // Entablatures under each storey, the crown cornice with its sockets.
    for (var k = 0; k < 4; k++) {
      final zTop = k == 3 ? _ColosseumRing.crown : tops[k], zBot = k == 3 ? tops[3] : tops[k] - .009;
      final band = Path(), edge = Path(), drop = Path();
      for (var i = j0; i < n; i++) {
        if (math.min(g.zp[i], g.zp[i + 1]) < zTop - .004) continue;
        for (final (path, z0, z1) in [(band, zBot, zTop), (edge, zTop - .0028, zTop), (drop, zBot - .012, zBot)]) {
          path
            ..moveTo(g.xs[i], g.y(z1, i))
            ..lineTo(g.xs[i + 1], g.y(z1, i + 1))
            ..lineTo(g.xs[i + 1], g.y(z0, i + 1))
            ..lineTo(g.xs[i], g.y(z0, i))
            ..close();
        }
      }
      c.drawPath(drop, Paint()..shader = veil);
      c.drawPath(band, Paint()..shader = mid);
      c.drawPath(edge, Paint()..shader = hi);
    }

    // Attic: a small window in every second bay, recessed panels between,
    // mast corbels under the cornice and their sockets above.
    final win = Path(), panel = Path(), corbel = Path(), corbelShade = Path(), socket = Path();
    for (var i = j0; i < n; i++) {
      final m = math.min(g.zp[i], g.zp[i + 1]);
      if (m < .278) continue;
      final bwc = g.xs[i + 1] - g.xs[i], mx = (g.xs[i] + g.xs[i + 1]) / 2;
      if (i.isOdd) {
        win.addRect(Rect.fromLTRB(mx - bwc * .17, g.ym(.272, i), mx + bwc * .17, g.ym(.243, i)));
      } else {
        panel.addRect(Rect.fromLTRB(mx - bwc * .26, g.ym(.276, i), mx + bwc * .26, g.ym(.24, i)));
      }
      if (m < .296) continue;
      corbel.addRect(Rect.fromLTRB(mx - bwc * .1, g.ym(.294, i), mx + bwc * .1, g.ym(.2835, i)));
      corbelShade.addRect(Rect.fromLTRB(mx - bwc * .1, g.ym(.2865, i), mx + bwc * .1, g.ym(.2835, i)));
      socket.addRect(Rect.fromLTRB(mx - bwc * .07, g.ym(.3035, i), mx + bwc * .07, g.ym(.2985, i)));
    }
    c.drawPath(panel, Paint()..shader = veil);
    c.drawPath(win, ink);
    c.drawPath(corbel, Paint()..shader = hi);
    c.drawPath(corbelShade, Paint()..shader = lo);
    c.drawPath(socket, ink);

    // Rain stains under the cornices and grime where the wall meets the earth.
    final streak = Path(), iron = Path(), grime = Path();
    for (var k = 0; k < 3; k++) {
      final z0 = tops[k] - .009 - .012;
      for (var j = j0; j <= n; j++) {
        if (g.zp[j] < tops[k]) continue;
        final p = Sketch.hash(g.seed + j * 17 + k * 101);
        if (p > .5) continue;
        final len = .014 + .034 * Sketch.hash(g.seed + j * 19 + k * 7), w = g.hp[j] * (.4 + .5 * Sketch.hash(g.seed + j * 23 + k));
        (p < .12 ? iron : streak).addRect(Rect.fromLTRB(g.xs[j] - w, g.y(z0 - len, j), g.xs[j] + w, g.y(z0, j)));
      }
    }
    for (var i = j0; i < n; i++) {
      if (g.arches[i] < 1) continue;
      grime.addRect(Rect.fromLTRB(g.xs[i], g.ym(.024, i), g.xs[i + 1], g.ym(0, i)));
    }
    c.drawPath(streak, Paint()..color = const Color(0x1e4a3226));
    c.drawPath(iron, Paint()..color = const Color(0x28b4632f));
    c.drawPath(
      grime,
      Paint()..shader = Gradient.linear(Offset(0, g.base.dy - .024 * s), Offset(0, g.base.dy), [const Color(0x00402c22), const Color(0x60402c22)]),
    );
    // The sunlit edge of the wall's near end.
    c.drawRect(
      Rect.fromLTRB(g.xs[j0] - g.hp[j0], g.y(_ColosseumRing.crown, j0), g.xs[j0] - g.hp[j0] * .55, g.base.dy),
      Paint()..shader = hi,
    );

    _colosseumGreen(c, g);
  }

  /// Caper, fig and ivy on ledges and broken tops.
  static void _colosseumGreen(Canvas c, _ColosseumRing g) {
    final n = g.n, s = g.s, tops = _ColosseumRing.tops;
    final dark = Path(), mid = Path(), lit = Path(), ivy = Path(), ivyLeaf = Path();
    void tuft(double x, double y, double sz) {
      // A leafy mound of overlapping clumps rather than a flat cap.
      final m = Sketch.hash((x * 7).round() + (y * 3).round()) < .5 ? 1.0 : -1.0, a = .8 + .5 * Sketch.hash((x * 5).round());
      dark.addOval(Rect.fromCenter(center: Offset(x, y - sz * .34), width: sz * 1.9 * a, height: sz * 1.25));
      dark.addOval(Rect.fromCenter(center: Offset(x + m * sz * .55, y - sz * .22), width: sz * 1.1, height: sz * .8));
      mid.addOval(Rect.fromCenter(center: Offset(x - m * sz * .2, y - sz * .5), width: sz * 1.25 * a, height: sz * .85));
      mid.addOval(Rect.fromCenter(center: Offset(x + m * sz * .5, y - sz * .38), width: sz * .7, height: sz * .5));
      lit.addOval(Rect.fromCenter(center: Offset(x - m * sz * .38, y - sz * .68), width: sz * .55, height: sz * .32));
    }

    // Broken tops: shrubs on the flat tears of masonry, ivy draped below.
    for (var i = g.first; i < n; i++) {
      final zc = g.cut[i];
      if (zc >= _ColosseumRing.crown - .01) continue;
      final p = Sketch.hash(g.seed + i * 13 + 5), q = Sketch.hash(g.seed + i * 7 + 2);
      final x1 = g.xs[i] + g.hp[i], x2 = g.xs[i + 1] - g.hp[i + 1], yt = g.ym(zc, i);
      if (p > .38) tuft(x1 + (x2 - x1) * (.2 + .6 * q), yt + s * .001, s * (.006 + .007 * p));
      if (q > .3 && x2 - x1 > s * .008) {
        // Ivy creeps down the face below the tear: soft rounded runs.
        for (var v = 0; v < 2; v++) {
          final u = Sketch.hash(g.seed + i * 19 + v * 5);
          if (u < .25) continue;
          final sx = x1 + (x2 - x1) * (.15 + .7 * Sketch.hash(g.seed + i * 23 + v)), len = s * (.008 + .022 * u * q), w = s * (.0032 + .003 * u);
          ivy.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(sx - w * .8, yt, sx + w * .8, yt + len), Radius.circular(w * .8)));
          ivyLeaf.addOval(Rect.fromCenter(center: Offset(sx + w * .2, yt + len * .85), width: w * 1.7, height: w * 1.3));
        }
      }
    }
    for (var j = g.first; j <= n; j++) {
      final z = g.zp[j];
      if (z >= _ColosseumRing.crown - .01) continue;
      final p = Sketch.hash(g.seed + j * 17 + 9);
      final big = (j == 17 || j == 21 || j == 25) && g.outer;
      if (big || p > .78) tuft(g.xs[j], g.y(z + .002, j), s * (big ? .011 : .005));
    }
    for (var k = 0; k < 4; k++) {
      final t = k == 3 ? _ColosseumRing.crown : tops[k];
      for (var i = g.first; i < n; i++) {
        if (math.min(g.zp[i], g.zp[i + 1]) < t - .004) continue;
        final p = Sketch.hash(g.seed + i * 29 + k * 61);
        if (p < (k == 3 ? .08 : .24)) {
          tuft((g.xs[i] + g.xs[i + 1]) / 2 + g.bw(i) * (p - .15), g.ym(t, i), s * (.004 + .006 * Sketch.hash(g.seed + i * 5 + k)));
        }
      }
    }
    c.drawPath(ivy, Paint()..color = Sketch.fade(_hazed(const Color(0xff466437), g.haze + .06), .45));
    c.drawPath(ivyLeaf, Paint()..color = Sketch.fade(_hazed(const Color(0xff4f7038), g.haze + .06), .8));
    c.drawPath(dark, Paint()..color = _hazed(const Color(0xff456238), g.haze + .06));
    c.drawPath(mid, Paint()..color = _hazed(const Color(0xff67873f), g.haze + .06));
    c.drawPath(lit, Paint()..color = _hazed(const Color(0xff93ae5a), g.haze + .06));
  }

  /// Scrub and a long shadow at the foot of the ruin, over the meadow.
  void _colosseumOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final (base, s) = _colosseumSpot(f.size);
    double ry(double x) => ridge(Depth.mid, x / h, 0) * h;
    // Late sun throws the wall's shadow to the right across the grass.
    for (final (reach, thick, alpha) in const [(.72, .034, .09), (.5, .02, .12)]) {
      final x0 = base.dx - s * .42, x1 = base.dx + s * reach;
      final shadow = Path()..moveTo(x0, ry(x0) + h * .002);
      for (var i = 1; i <= 9; i++) {
        final x = x0 + (x1 - x0) * i / 9;
        shadow.lineTo(x, ry(x) + h * .002);
      }
      for (var i = 9; i >= 0; i--) {
        final t = i / 9, x = x0 + (x1 - x0) * t;
        shadow.lineTo(x, ry(x) + h * (.002 + thick * math.pow(math.sin(math.pi * t), .7)));
      }
      c.drawPath(shadow, Paint()..color = Sketch.fade(const Color(0xff3a4826), alpha * presence));
    }
    // Scrub along the foot of the wall: two clumps and a sunlit top each.
    final paint = Paint();
    for (var i = 0; i < 16; i++) {
      if (Sketch.hash(i + 832) < .3) continue;
      final x = base.dx + s * (-.54 + 1.14 * i / 15 + .07 * (Sketch.hash(i + 830) - .5));
      final r = h * (.005 + .008 * Sketch.hash(i + 831) * Sketch.hash(i + 833) + .003 * Sketch.hash(i + 834));
      final y = ry(x) + r * .2;
      paint.color = Sketch.fade(const Color(0xff4d6835), .95 * presence);
      c.drawOval(Rect.fromCenter(center: Offset(x - r * .7, y - r * .1), width: r * 2.2, height: r * 1.5), paint);
      c.drawOval(Rect.fromCenter(center: Offset(x + r * .75, y - r * .3), width: r * 2, height: r * 1.7), paint);
      paint.color = Sketch.fade(const Color(0xff6c8a45), .9 * presence);
      c.drawOval(Rect.fromCenter(center: Offset(x - r * .2, y - r * .55), width: r * 1.5, height: r * .9), paint);
    }
    // Fallen blocks at the ruin's right foot.
    for (var i = 0; i < 5; i++) {
      final x = base.dx + s * (.1 + .42 * Sketch.hash(i + 840));
      final y = ry(x) + h * (.008 + .014 * Sketch.hash(i + 841));
      final r = h * (.004 + .004 * Sketch.hash(i + 842));
      paint.color = Sketch.fade(const Color(0xffd6bd93), .9 * presence);
      c.drawRect(Rect.fromLTRB(x - r, y - r * .8, x + r, y), paint);
      paint.color = Sketch.fade(const Color(0xffa48764), .9 * presence);
      c.drawRect(Rect.fromLTRB(x + r * .3, y - r * .8, x + r, y), paint);
    }
  }

  /// A triumphal arch after Constantine's: three passages with the sky showing
  /// through, four gilt-yellow columns carrying purple captive statues, roundels
  /// over the side bays, a lettered attic between relief panels, and a
  /// bronze quadriga on top.
  static void _arch(Canvas c, Offset base, double s) {
    final v = s * 1.15;
    final gy = base.dy - s * .1;
    double px(double f) => base.dx + v * f;
    double py(double f) => gy - v * f;
    Rect box(double l, double b, double r, double t) => Rect.fromLTRB(px(l), py(t), px(r), py(b));
    final stone = _hazed(const Color(0xffe4c898), .28);
    final stoneShade = _hazed(_monumentMarbleShade, .28);
    final deep = _hazed(_monumentUmber, .32);
    final lit = _hazed(const Color(0xfff4e0b6), .24);
    final p = Paint();
    final hair = math.max(.5, v * .006);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair;

    // Foundation, plinth and the marble mass with its coursed masonry.
    c.drawRect(box(-.62, -.12, .62, .0), p..color = stoneShade);
    c.drawRect(box(-.6, .0, .6, .05), p..color = stone);
    c.drawRect(box(-.6, .044, .6, .05), p..color = lit);
    c.drawRect(
      box(-.58, .05, .58, .9),
      Paint()
        ..shader = Gradient.linear(Offset(px(-.58), 0), Offset(px(.58), 0), [
          _hazed(const Color(0xffeed6a8), .24),
          stone,
          Sketch.mix(stone, stoneShade, .55),
        ], const [0, .5, 1]),
    );
    final courses = Path();
    for (var i = 1; i < 12; i++) {
      final y = .05 + i * .052;
      courses
        ..moveTo(px(-.58), py(y))
        ..lineTo(px(.58), py(y));
    }
    c.drawPath(courses, line..color = Sketch.fade(stoneShade, .3));

    // Attic: the inscription between two pairs of relief panels.
    final recessed = Sketch.mix(stone, stoneShade, .45);
    c.drawRect(box(-.27, .742, .27, .868), p..color = recessed);
    c.drawRect(box(-.27, .862, .27, .868), p..color = Sketch.fade(deep, .28));
    c.drawRect(box(-.27, .742, -.264, .868), p..color = Sketch.fade(deep, .16));
    c.drawRect(box(.264, .742, .27, .868), p..color = Sketch.fade(lit, .7));
    final letters = Path();
    for (var row = 0; row < 3; row++) {
      var lx = -.23 + (row == 1 ? .03 : 0);
      for (var i = 0; lx < (row == 1 ? .2 : .23); i++) {
        final len = .012 + .016 * Sketch.hash(i + row * 40 + 660);
        letters
          ..moveTo(px(lx), py(.83 - row * .034))
          ..lineTo(px(lx + len), py(.83 - row * .034));
        lx += len + .014;
      }
    }
    c.drawPath(
      letters,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, v * .012)
        ..color = Sketch.fade(deep, .55),
    );
    for (final side in const [-1.0, 1.0]) {
      final l = side < 0 ? -.535 : .315, r = l + .22;
      c.drawRect(box(l, .748, r, .862), p..color = Sketch.mix(stone, stoneShade, .6));
      c.drawRect(box(l, .748, l + .006, .862), p..color = Sketch.fade(deep, .16));
      c.drawRect(box(l, .856, r, .862), p..color = Sketch.fade(deep, .22));
      // A frieze of tiny carved figures, light against the recess.
      final figures = Path();
      final heads = <Offset>[];
      for (var i = 0; i < 8; i++) {
        final x = l + .025 + i * .024, hgt = .034 + .012 * Sketch.hash(i + 690 + (side < 0 ? 0 : 20));
        figures
          ..moveTo(px(x), py(.762))
          ..lineTo(px(x), py(.762 + hgt));
        heads.add(Offset(px(x), py(.766 + hgt + .006)));
      }
      c.drawPath(
        figures,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, v * .013)
          ..color = Sketch.fade(lit, .6),
      );
      final headPaint = Paint()..color = Sketch.fade(lit, .6);
      for (final h in heads) {
        c.drawCircle(h, math.max(.5, v * .0085), headPaint);
      }
    }

    // A narrow frieze of carved figures runs over the side bays.
    for (final side in const [-1.0, 1.0]) {
      final l = side < 0 ? -.576 : .19, r = side < 0 ? -.19 : .576;
      c.drawRect(box(l, .338, r, .384), p..color = Sketch.mix(stone, stoneShade, .5));
      c.drawRect(box(l, .378, r, .384), p..color = Sketch.fade(deep, .16));
      final tiny = Path();
      for (var x = l + .012; x < r - .01; x += .017) {
        final hgt = .014 + .01 * Sketch.hash((x * 900).round() + 650);
        tiny
          ..moveTo(px(x), py(.345))
          ..lineTo(px(x), py(.345 + hgt));
      }
      c.drawPath(
        tiny,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.6, v * .008)
          ..color = Sketch.fade(lit, .5),
      );
    }

    // Three passages; the far side glows through each one.
    final through = Paint()
      ..shader = Gradient.linear(Offset(0, py(.5)), Offset(0, py(0)), [
        _hazed(const Color(0xfff9dcae), .06),
        _hazed(const Color(0xffe6c49c), .16),
        _hazed(const Color(0xffa8a468), .28),
      ], const [0, .55, 1]);
    for (final (cx, hw, spring) in const [(.0, .15, .34), (-.4, .078, .24), (.4, .078, .24)]) {
      c.drawPath(_monumentArchway(px(cx), hw * v, py(spring), py(0.05)), p..color = deep);
      c.drawPath(_monumentArchway(px(cx), (hw - .014) * v, py(spring), py(.05)), through);
      // Shadowed right reveal, lit archivolt and keystone.
      c.drawRect(box(cx + hw - .03, .05, cx + hw - .014, spring), p..color = Sketch.fade(deep, .4));
      c.drawPath(
        Path()
          ..moveTo(px(cx - hw - .01), py(.05))
          ..lineTo(px(cx - hw - .01), py(spring))
          ..arcToPoint(Offset(px(cx + hw + .01), py(spring)), radius: Radius.circular((hw + .01) * v))
          ..lineTo(px(cx + hw + .01), py(.05)),
        line
          ..strokeWidth = math.max(.8, v * .018)
          ..color = Sketch.fade(lit, .85),
      );
      c.drawRect(box(cx - .015, spring + hw + .006, cx + .015, spring + hw + .046), p..color = lit);
    }

    // Spandrel panels beside the great arch and roundels over the side bays.
    for (final side in const [-1.0, 1.0]) {
      final x = side * .18;
      c.drawRect(box(x - .022, .43, x + .022, .6), p..color = Sketch.mix(stone, stoneShade, .6));
      c.drawRect(box(x - .022, .43, x - .016, .6), p..color = Sketch.fade(deep, .15));
      c.drawCircle(Offset(px(x + side * .002), py(.55)), v * .012, p..color = Sketch.fade(lit, .6));
      c.drawCircle(Offset(px(x + side * .002), py(.47)), v * .009, p..color = Sketch.fade(lit, .5));
      final rx = side * .4;
      c.drawCircle(Offset(px(rx), py(.5)), v * .068, p..color = lit);
      c.drawCircle(Offset(px(rx + .004), py(.498)), v * .054, p..color = Sketch.mix(stone, deep, .3));
      c.drawOval(Rect.fromCenter(center: Offset(px(rx + .002), py(.488)), width: v * .05, height: v * .022), p..color = Sketch.fade(lit, .62));
      c.drawCircle(Offset(px(rx - .008), py(.518)), v * .009, p..color = Sketch.fade(lit, .7));
      c.drawLine(Offset(px(rx - .008), py(.512)), Offset(px(rx - .004), py(.494)), line..strokeWidth = math.max(.7, v * .01)..color = Sketch.fade(lit, .7));
      c.drawLine(Offset(px(rx + .02), py(.492)), Offset(px(rx + .034), py(.51)), line..strokeWidth = math.max(.6, v * .008)..color = Sketch.fade(lit, .55));
    }

    // Columns of yellow marble on pedestals, under the projecting entablature.
    final goldLit = _hazed(const Color(0xffe9c878), .2), goldShade = _hazed(const Color(0xff9a7438), .24);
    final goldMid = Sketch.mix(goldLit, goldShade, .4);
    final purple = _hazed(const Color(0xff7c5670), .22);
    for (final x in const [-.529, -.236, .236, .529]) {
      c.drawRect(box(x - .042, .05, x + .042, .17), p..color = stone);
      c.drawRect(box(x + .014, .05, x + .042, .17), p..color = Sketch.fade(deep, .16));
      c.drawRect(box(x - .048, .164, x + .048, .178), p..color = lit);
      c.drawRect(box(x - .026, .178, x + .026, .62), p..color = goldMid);
      c.drawRect(box(x - .026, .178, x - .009, .62), p..color = goldLit);
      c.drawRect(box(x + .012, .178, x + .026, .62), p..color = goldShade);
      c.drawPath(Sketch.poly([px(x - .025), py(.62), px(x + .025), py(.62), px(x + .036), py(.65), px(x - .036), py(.65)]), p..color = stone);
      c.drawRect(box(x - .04, .646, x + .04, .657), p..color = lit);
      // Entablature block over each column, and its statue of a captive.
      c.drawRect(box(x - .056, .657, x + .056, .705), p..color = stone);
      c.drawRect(box(x - .062, .698, x + .062, .71), p..color = lit);
      c.drawRect(box(x + .02, .657, x + .056, .698), p..color = Sketch.fade(deep, .14));
      c.drawRect(box(x - .034, .71, x + .034, .728), p..color = stone);
      c.drawPath(Sketch.poly([px(x - .012), py(.728), px(x + .012), py(.728), px(x + .016), py(.78), px(x + .022), py(.806), px(x - .022), py(.806), px(x - .016), py(.78)]), p..color = purple);
      c.drawRect(box(x - .022, .742, x - .008, .806), p..color = Sketch.fade(lit, .26));
      c.drawCircle(Offset(px(x), py(.822)), v * .0115, p..color = purple);
      c.drawRect(box(x - .03, .762, x - .02, .8), p..color = purple);
    }
    // The entablature runs between the blocks; its cornice throws a shadow.
    c.drawRect(box(-.585, .662, .585, .7), p..color = stone);
    c.drawRect(box(-.585, .694, .585, .704), p..color = lit);
    c.drawRect(box(-.585, .652, .585, .662), p..color = Sketch.fade(deep, .16));

    // Attic cornice and the quadriga.
    c.drawRect(box(-.6, .9, .6, .935), p..color = stone);
    c.drawRect(box(-.6, .93, .6, .94), p..color = lit);
    c.drawRect(box(-.585, .888, .585, .9), p..color = Sketch.fade(deep, .3));
    c.drawRect(box(.3, .9, .6, .935), p..color = Sketch.fade(deep, .13));
    c.drawRect(box(-.2, .94, .2, .968), p..color = stone);
    c.drawRect(box(-.21, .962, .21, .974), p..color = lit);
    _monumentQuadriga(c, Offset(px(0), py(.974)), v, _hazed(const Color(0xff4c3d2f), .4), _hazed(const Color(0xffe0b452), .2));

    // Weathering: rain streaks under the attic cornice, tufts and trailing
    // ivy along the top.
    final stain = Paint()..color = Sketch.fade(deep, .09);
    for (var i = 0; i < 9; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final x = side * (.29 + .27 * Sketch.hash(i + 670));
      c.drawRect(box(x, .888 - .06 - .1 * Sketch.hash(i + 671), x + .008 + .008 * Sketch.hash(i + 672), .888), stain);
    }
    final moss = Paint()..color = _hazed(const Color(0xff55703a), .3);
    final mossLit = Paint()..color = _hazed(const Color(0xff87a052), .3);
    for (final (x, trail) in const [(-.47, .09), (-.12, .0), (.19, .06), (.43, .11), (.52, .0)]) {
      c.drawCircle(Offset(px(x), py(.944)), v * .014, moss);
      c.drawCircle(Offset(px(x + .014), py(.94)), v * .011, moss);
      c.drawCircle(Offset(px(x - .004), py(.952)), v * .007, mossLit);
      if (trail > 0) {
        c.drawPath(Sketch.poly([px(x - .008), py(.936), px(x + .008), py(.936), px(x + .004), py(.93 - trail), px(x - .002), py(.93 - trail * .7)]), moss);
        c.drawCircle(Offset(px(x + .006), py(.93 - trail * .45)), v * .008, mossLit);
        c.drawCircle(Offset(px(x - .004), py(.93 - trail * .8)), v * .006, mossLit);
      }
    }
    // Sun-catching left edge and a contact shadow at the foot.
    c.drawRect(box(-.58, .05, -.572, .9), p..color = Sketch.fade(lit, .6));
    c.drawRect(box(-.6, -.02, .6, .006), p..color = Sketch.fade(deep, .18));
  }

  /// A bronze quadriga: four horses abreast with a charioteer behind, seen
  /// from the front. [at] is the centre of its base, [v] the arch's unit.
  static void _monumentQuadriga(Canvas c, Offset at, double v, Color body, Color gild) {
    double px(double f) => at.dx + v * f;
    double py(double f) => at.dy - v * f;
    final p = Paint()..color = body;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, v * .012)
      ..color = body;
    final spoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, v * .006)
      ..color = Sketch.fade(gild, .7);
    // Wheels stand out past the outer horses, the chariot box behind them.
    for (final x in const [-.2, .2]) {
      c.drawCircle(Offset(px(x), py(.06)), v * .044, rim);
      c.drawLine(Offset(px(x), py(.06 - .038)), Offset(px(x), py(.06 + .038)), spoke);
      c.drawLine(Offset(px(x - .038), py(.06)), Offset(px(x + .038), py(.06)), spoke);
    }
    c.drawRect(Rect.fromLTRB(px(-.16), py(.13), px(.16), py(.04)), p);
    // The charioteer, one arm up with a wreath.
    c.drawPath(Sketch.poly([px(-.02), py(.1), px(.02), py(.1), px(.024), py(.2), px(.012), py(.235), px(-.012), py(.235), px(-.024), py(.2)]), p);
    c.drawCircle(Offset(px(0), py(.256)), v * .0155, p);
    c.drawLine(Offset(px(.014), py(.215)), Offset(px(.062), py(.278)), rim);
    c.drawCircle(Offset(px(.066), py(.286)), v * .012, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.5, v * .006)..color = Sketch.fade(gild, .85));
    // Four horses abreast: chests in a row, arched necks, raised forelegs.
    for (final x in const [-.135, -.045, .045, .135]) {
      final out = x < 0 ? -1.0 : 1.0, lean = x * .16;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(px(x - .036), py(.125), px(x + .036), py(.015)), Radius.circular(v * .022)), p);
      c.drawPath(Sketch.poly([px(x - .021), py(.1), px(x + .021), py(.1), px(x + lean + .012), py(.19), px(x + lean - .012), py(.19)]), p);
      c.save();
      c.translate(px(x + lean * 1.2), py(.213));
      c.rotate(x * 1.1);
      c.drawPath(
        Path()
          ..moveTo(-v * .015, -v * .018)
          ..quadraticBezierTo(-v * .017, v * .006, -v * .008, v * .034)
          ..lineTo(v * .008, v * .034)
          ..quadraticBezierTo(v * .017, v * .006, v * .015, -v * .018)
          ..quadraticBezierTo(0, -v * .03, -v * .015, -v * .018)
          ..close(),
        p,
      );
      c.drawPath(Sketch.poly([-v * .013, -v * .02, -v * .009, -v * .038, -v * .003, -v * .024]), p);
      c.drawPath(Sketch.poly([v * .013, -v * .02, v * .009, -v * .038, v * .003, -v * .024]), p);
      c.restore();
      c.drawPath(
        Path()
          ..moveTo(px(x + out * .014), py(.09))
          ..lineTo(px(x + out * .04), py(.13))
          ..lineTo(px(x + out * .06), py(.112)),
        rim,
      );
      c.drawLine(Offset(px(x - .026), py(.02)), Offset(px(x - .026), py(0)), rim);
      c.drawLine(Offset(px(x + .026), py(.02)), Offset(px(x + .026), py(0)), rim);
      c.drawLine(Offset(px(x - .016), py(.105)), Offset(px(x + lean - .012), py(.19)), spoke);
    }
  }

  /// Forum marble in the warm late light, a touch of haze for the middle
  /// distance. Lit from the upper left, the shade side leans mauve.
  static const _forumLit = Color(0xfffbecca);
  static const _forumMarble = Color(0xffedd8b0);
  static const _forumShade = Color(0xffc09f84);
  static const _forumDeep = Color(0xff7c5c4e);
  static const _forumClay = Color(0xffc8683c);
  static const _forumSoil = Color(0xff4d2f3c);

  static Color _forumTint(Color c) => _hazed(c, .07);

  /// A Corinthian temple front: moulded podium with its flight of steps,
  /// six fluted columns before a recessed cella, a lettered entablature and
  /// a pediment with sculpted figures under terracotta acroteria. [s] is the
  /// height from the ground to the ridge of the roof.
  static void _temple(Canvas c, Offset base, double s) {
    final lit = _forumTint(_forumLit), stone = _forumTint(_forumMarble), shade = _forumTint(_forumShade), deep = _forumTint(_forumDeep), clay = _forumTint(_forumClay);
    final p = Paint();
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy - v * s;
    void box(Color col, double l, double b, double r, double t) => c.drawRect(Rect.fromLTRB(x(l), y(t), x(r), y(b)), p..color = col);
    void poly(Color col, List<double> uv) => c.drawPath(Sketch.poly([for (var i = 0; i < uv.length; i++) i.isOdd ? -uv[i] : uv[i]], at: base, s: s), p..color = col);
    // The podium: moulded plinth, coursed die and a projecting cornice.
    box(shade, -.575, 0, .575, .035);
    box(stone, -.55, .035, .55, .15);
    box(lit, -.55, .035, -.522, .15);
    box(Sketch.fade(shade, .6), .33, .035, .55, .15);
    for (final v in const [.075, .112]) {
      box(Sketch.fade(deep, .2), -.55, v, .55, v + .003);
    }
    box(lit, -.58, .15, .58, .17);
    box(Sketch.fade(deep, .38), -.55, .137, .55, .15);
    // A flight of seven steps between two cheek walls.
    box(stone, -.245, 0, -.195, .17);
    box(shade, .195, 0, .245, .17);
    box(lit, -.25, .15, -.19, .17);
    box(stone, .19, .15, .25, .17);
    const rise = .15 / 7;
    for (var i = 0; i < 7; i++) {
      final v = i * rise;
      box(i.isEven ? stone : Sketch.mix(stone, shade, .35), -.195, v, .195, v + rise);
      box(lit, -.195, v + rise - .005, .195, v + rise);
      box(Sketch.fade(deep, .32), -.195, v, .195, v + .004);
    }
    box(lit, -.47, .17, .47, .19);
    box(shade, -.47, .17, .47, .174);
    // The cella wall behind the porch, in shade: courses, a doorway with a
    // bronze leaf, and a statue niche on either side.
    box(deep, -.43, .19, .43, .64);
    for (var v = .26; v < .6; v += .07) {
      box(Sketch.fade(shade, .22), -.43, v, .43, v + .003);
    }
    box(Sketch.fade(_forumSoil, .3), -.43, .585, .43, .64);
    // Late sun slants between the columns and lights a strip of each bay.
    for (var i = 0; i < 5; i++) {
      if (i == 2) continue;
      final gl = -.40 + .16 * i + .088;
      box(Sketch.fade(const Color(0xffffd694), .3), gl, .19, gl + .034, .55);
      box(Sketch.fade(const Color(0xffffe6b8), .3), gl, .19, gl + .01, .55);
    }
    for (final side in const [-1.0, 1.0]) {
      final nx = side * .32;
      box(_forumTint(const Color(0xff4d362f)), nx - .032, .27, nx + .032, .41);
      c.drawCircle(Offset(x(nx), y(.41)), s * .032, p..color = _forumTint(const Color(0xff4d362f)));
      c.drawOval(Rect.fromCenter(center: Offset(x(nx), y(.34)), width: s * .03, height: s * .12), p..color = Sketch.mix(stone, deep, .25));
      c.drawCircle(Offset(x(nx), y(.415)), s * .011, p..color = Sketch.mix(stone, deep, .2));
    }
    box(lit, -.078, .19, .078, .47);
    box(_forumTint(const Color(0xff3e2a28)), -.06, .19, .06, .445);
    box(Sketch.fade(const Color(0xffb0803c), .55), -.056, .19, -.004, .44);
    box(Sketch.fade(const Color(0xffb0803c), .3), .004, .19, .056, .44);
    box(stone, -.09, .445, .09, .485);
    box(lit, -.09, .478, .09, .485);
    for (var i = 0; i < 6; i++) {
      _forumColumn(c, x(-.40 + .16 * i), y(.19), s);
    }
    // Entablature: three-fascia architrave, a frieze lettered along its
    // middle, a dentilled cornice.
    box(stone, -.47, .64, .47, .69);
    box(Sketch.fade(shade, .55), -.47, .655, .47, .658);
    box(Sketch.fade(shade, .55), -.47, .672, .47, .675);
    box(lit, -.475, .685, .475, .692);
    box(Sketch.fade(deep, .3), -.47, .64, .47, .645);
    box(stone, -.47, .692, .47, .745);
    box(Sketch.mix(stone, shade, .3), .3, .692, .47, .745);
    final letters = Path();
    for (var i = 0; i < 40; i++) {
      final u = -.27 + i * .0138;
      letters.addRect(Rect.fromLTRB(x(u), y(.727), x(u + .0072), y(.71 + .008 * ((i * 7) % 3 == 0 ? 0 : 1))));
    }
    c.drawPath(letters, p..color = Sketch.fade(deep, .55));
    box(Sketch.fade(deep, .34), -.47, .735, .47, .745);
    box(shade, -.485, .745, .485, .758);
    final teeth = Path();
    for (var i = 0; i < 44; i++) {
      final u = -.472 + i * .0215;
      teeth.addRect(Rect.fromLTRB(x(u), y(.758), x(u + .011), y(.748)));
    }
    c.drawPath(teeth, p..color = Sketch.fade(lit, .8));
    box(stone, -.49, .758, .49, .79);
    box(Sketch.mix(stone, shade, .3), .3, .758, .49, .79);
    box(lit, -.49, .784, .49, .79);
    // The pediment: a lit left rake, a shaded right one, a terracotta tympanum
    // full of marble figures, and clay tiles along the edge.
    poly(stone, [-.525, .79, .525, .79, 0, .945]);
    poly(lit, [-.525, .79, 0, .945, 0, .79]);
    poly(shade, [0, .945, .525, .79, 0, .79]);
    poly(Sketch.mix(clay, deep, .32), [-.44, .815, .44, .815, 0, .922]);
    poly(Sketch.fade(const Color(0xffe89a62), .32), [-.44, .815, 0, .815, 0, .922]);
    poly(Sketch.fade(_forumSoil, .3), [-.44, .815, -.44 + .03, .815, 0, .922 - .012]);
    // The pediment group: reclining river gods at the ends, seated and
    // standing figures crowding towards a tall god in the middle.
    for (final (u, kind) in const [(-.36, 2), (-.25, 1), (-.13, 0), (0.0, 0), (.13, 0), (.25, 1), (.36, 2)]) {
      final roof = .815 + .107 * (1 - u.abs() / .44);
      final hgt = (roof - .826) * (kind == 1 ? .74 : .92);
      final tone = u < 0 ? lit : (u == 0 ? Sketch.mix(lit, stone, .5) : stone);
      const b = .823;
      if (kind == 2) {
        final inward = u < 0 ? 1.0 : -1.0;
        c.drawOval(Rect.fromCenter(center: Offset(x(u), y(b + .011)), width: s * .085, height: s * .022), p..color = tone);
        c.drawCircle(Offset(x(u + inward * .03), y(b + .025)), s * .0085, p..color = tone);
        continue;
      }
      final wide = kind == 1 ? .022 : .015;
      poly(tone, [u - wide, b, u - .011, b + hgt * .5, u - .009, b + hgt * .8, u + .009, b + hgt * .8, u + .011, b + hgt * .5, u + wide, b]);
      poly(Sketch.fade(deep, .28), [u + .003, b, u + wide, b, u + .011, b + hgt * .5, u + .009, b + hgt * .8, u + .003, b + hgt * .8]);
      c.drawCircle(Offset(x(u), y(b + hgt * .93)), s * .0088, p..color = tone);
    }
    final tiles = Path()
      ..addPolygon([Offset(x(-.538), y(.782)), Offset(x(0), y(.955)), Offset(x(0), y(.943)), Offset(x(-.522), y(.788))], true);
    c.drawPath(tiles, p..color = clay);
    c.drawPath(
      Path()..addPolygon([Offset(x(.538), y(.782)), Offset(x(0), y(.955)), Offset(x(0), y(.943)), Offset(x(.522), y(.788))], true),
      p..color = Sketch.mix(clay, deep, .3),
    );
    final ante = Path();
    for (var i = 1; i < 9; i++) {
      for (final side in const [-1.0, 1.0]) {
        final f = i / 9;
        final ax = side * .53 * (1 - f), ay = .783 + .172 * f;
        ante
          ..moveTo(x(ax - .011), y(ay))
          ..lineTo(x(ax + .011), y(ay))
          ..lineTo(x(ax), y(ay + .026))
          ..close();
      }
    }
    c.drawPath(ante, p..color = Sketch.mix(clay, const Color(0xffffe0b0), .18));
    // Acroteria: a palmette at the apex and a half-palmette at each corner.
    final palm = Path();
    for (final (a, len) in const [(-.82, .036), (-.4, .048), (0.0, .06), (.4, .048), (.82, .036)]) {
      final tipX = math.sin(a) * len, tipY = math.cos(a) * len;
      palm
        ..moveTo(x(-.006), y(.952))
        ..lineTo(x(tipX), y(.952 + tipY))
        ..lineTo(x(.006), y(.952))
        ..close();
    }
    c.drawPath(palm, p..color = Sketch.mix(clay, const Color(0xffd4a05a), .35));
    box(stone, -.026, .942, .026, .955);
    for (final side in const [-1.0, 1.0]) {
      final ax = side * .54;
      final half = Path();
      for (final (a, len) in const [(.15, .04), (.62, .034), (1.05, .026)]) {
        half
          ..moveTo(x(ax - .005), y(.79))
          ..lineTo(x(ax + side * math.sin(a) * len), y(.79 + math.cos(a) * len))
          ..lineTo(x(ax + .005), y(.79))
          ..close();
      }
      c.drawPath(half, p..color = Sketch.mix(clay, const Color(0xffd4a05a), .35));
    }
    // Moss on the ledges.
    for (final (u, v, r) in const [(.51, .17, .015), (.47, .173, .011), (-.52, .17, .012), (-.02, .19, .01)]) {
      c.drawCircle(Offset(x(u), y(v + r * .4)), s * r, p..color = _forumTint(const Color(0xff6b8a48)));
      c.drawCircle(Offset(x(u - r * .3), y(v + r * .7)), s * r * .55, p..color = _forumTint(const Color(0xff9ab26a)));
    }
    // A dove on the left corner of the cornice.
    _forumDove(c, Offset(x(-.42), y(.79)), s * .038);
  }

  /// A tiny dove at rest: plump body, head, tail and a shaded wing.
  static void _forumDove(Canvas c, Offset at, double u) {
    final p = Paint()..color = const Color(0xfff2ece2);
    c.drawOval(Rect.fromCenter(center: at + Offset(0, -u * .5), width: u * 1.5, height: u * .9), p);
    c.drawCircle(at + Offset(u * .62, -u * .95), u * .34, p);
    c.drawPath(Sketch.poly([-u * .7, -u * .55, -u * 1.5, -u * .42, -u * .7, -u * .3], at: at), p);
    c.drawOval(Rect.fromCenter(center: at + Offset(-u * .1, -u * .55), width: u * 1.0, height: u * .5), p..color = const Color(0xffb9b0ad));
    c.drawCircle(at + Offset(u * .72, -u * 1.0), u * .06, p..color = const Color(0xff4d3a3a));
  }

  /// A fluted Corinthian column: moulded base, shaft lit from the left with
  /// a bounce of warm light on its shade side, acanthus capital and abacus.
  /// [u] scales it like the temple it belongs to; [foot] is the ground line.
  static void _forumColumn(Canvas c, double cx, double foot, double u, {double shaft = .365, double half = .025, bool broken = false}) {
    final lit = _forumTint(_forumLit), stone = _forumTint(_forumMarble), shade = _forumTint(_forumShade);
    final p = Paint();
    final w0 = half * u, w1 = w0 * .84;
    final baseH = u * .016;
    final top = foot - baseH - shaft * u;
    c.drawRect(Rect.fromLTRB(cx - w0 * 1.4, foot - baseH * .5, cx + w0 * 1.4, foot), p..color = stone);
    c.drawRect(Rect.fromLTRB(cx - w0 * 1.4, foot - baseH * .5, cx - w0 * .3, foot), p..color = lit);
    c.drawRect(Rect.fromLTRB(cx + w0 * .35, foot - baseH * .5, cx + w0 * 1.4, foot), p..color = shade);
    c.drawRRect(RRect.fromLTRBR(cx - w0 * 1.22, foot - baseH, cx + w0 * 1.22, foot - baseH * .45, Radius.circular(baseH * .3)), p..color = stone);
    c.drawRect(Rect.fromLTRB(cx - w0 * 1.1, foot - baseH, cx - w0 * .2, foot - baseH * .7), p..color = lit);
    final y0 = foot - baseH;
    void strip(Color col, double a, double b) {
      c.drawPath(
        Path()
          ..moveTo(cx + a * w0, y0)
          ..lineTo(cx + b * w0, y0)
          ..lineTo(cx + b * w1, top)
          ..lineTo(cx + a * w1, top)
          ..close(),
        p..color = col,
      );
    }
    strip(stone, -1, 1);
    strip(lit, -1, -.42);
    strip(shade, .28, 1);
    strip(Sketch.mix(shade, const Color(0xffd98a5a), .3), .78, 1);
    final flutes = Paint()
      ..color = Sketch.fade(shade, .5)
      ..strokeWidth = math.max(.5, w0 * .07);
    for (final a in const [-.08, .58]) {
      c.drawLine(Offset(cx + a * w0, y0), Offset(cx + a * w1, top), flutes);
    }
    if (broken) {
      c.drawPath(
        Sketch.poly([cx - w1, top, cx - w1 * .3, top - u * .035, cx + w1 * .2, top + u * .012, cx + w1, top - u * .02, cx + w1, top + u * .01, cx - w1, top + u * .01]),
        p..color = stone,
      );
      return;
    }
    // Acanthus bell, a scalloped leaf band, corner volutes and the abacus.
    c.drawPath(
      Sketch.poly([cx - w1, top, cx - w1 * 1.2, top - u * .024, cx - u * .027, top - u * .042, cx - u * .033, top - u * .062, cx + u * .033, top - u * .062, cx + u * .027, top - u * .042, cx + w1 * 1.2, top - u * .024, cx + w1, top]),
      p..color = stone,
    );
    c.drawPath(
      Sketch.poly([cx - w1 * 1.2, top - u * .024, cx - u * .027, top - u * .042, cx - u * .033, top - u * .062, cx - u * .008, top - u * .062, cx - w1 * .3, top - u * .01, cx - w1, top]),
      p..color = lit,
    );
    c.drawPath(
      Sketch.poly([cx + w1 * .5, top - u * .008, cx + u * .011, top - u * .062, cx + u * .033, top - u * .062, cx + u * .027, top - u * .042, cx + w1 * 1.2, top - u * .024, cx + w1, top]),
      p..color = shade,
    );
    for (final k in const [-.5, 0.0, .5]) {
      c.drawLine(Offset(cx + k * w1 * 1.3, top - u * .004), Offset(cx + k * w1 * 1.3 * .8, top - u * .03), flutes);
    }
    for (final side in const [-1.0, 1.0]) {
      c.drawCircle(Offset(cx + side * u * .027, top - u * .05), u * .0068, p..color = Sketch.fade(shade, .8));
    }
    c.drawRect(Rect.fromLTRB(cx - u * .04, top - u * .07, cx + u * .04, top - u * .062), p..color = stone);
    c.drawRect(Rect.fromLTRB(cx - u * .04, top - u * .07, cx - u * .005, top - u * .066), p..color = lit);
    c.drawRect(Rect.fromLTRB(cx + u * .012, top - u * .07, cx + u * .04, top - u * .062), p..color = shade);
  }

  /// Cypress positions and heights (in viewport heights) along the low band's
  /// period; the same list places the trees and their long shadows.
  static const _forumCypresses = [(.2, .26), (2.5, .25), (2.64, .19), (2.93, .27)];
  static const _forumAltarX = 1.29, _forumAltarS = .055, _forumTempleX = 1.06, _forumTempleS = .26;
  static const _forumPineX = 1.62, _forumHonorX = 1.86, _forumRuinX = 2.14, _forumMileX = .56, _forumCartX = 1.99;

  /// The low band's landmarks, standing on the crest above the road: a
  /// Corinthian temple with its altar and statues, a stone pine, an honorary
  /// column, the three columns of a broken temple and a line of cypresses.
  void _forumFeatures(Canvas c, double h) {
    double foot(double u) => _y(Depth.low, u * h, h) + h * .012;
    Offset at(double u) => Offset(u * h, foot(u));
    for (var i = 0; i < _forumCypresses.length; i++) {
      final (u, s) = _forumCypresses[i];
      _forumCypress(c, at(u), s * h, i + 1);
    }
    _forumRuin(c, at(_forumRuinX), h * .21);
    _forumHonor(c, at(_forumHonorX), h * .16);
    _pine(c, at(_forumPineX), h * .3, _hazed(const Color(0xff4a3a2c), .05), _hazed(const Color(0xff4f6d3f), .05), lit: _hazed(const Color(0xff7c9c58), .05));
    _temple(c, at(_forumTempleX), h * _forumTempleS);
    _altar(c, at(_forumAltarX), h * _forumAltarS);
    _forumStatue(c, at(.8), h * .1, 0);
    _forumStatue(c, at(1.43), h * .092, 1);
    _forumStatue(c, at(2.76), h * .085, 2);
    for (final (u, s, seed, bloom) in const [
      (.22, .05, 1, null),
      (.6, .045, 2, Color(0xffe8829a)),
      (.94, .042, 3, null),
      (1.19, .04, 4, Color(0xffe8829a)),
      (1.5, .05, 5, null),
      (1.74, .042, 6, Color(0xfff6f0e0)),
      (2.02, .04, 7, null),
      (2.34, .05, 8, Color(0xffe8829a)),
      (2.84, .045, 9, null),
    ]) {
      _forumShrub(c, at(u), h * s, seed, bloom: bloom);
    }
  }

  static final _forumRoads = <double, Picture>{};

  /// The paved road and the ground about it: recorded once per viewport
  /// height and replayed for every copy of the band.
  void _forumRoad(Canvas c, SceneFrame f, double rawPresence) {
    // The paving is tied to this region's ridge, so it clears early while the
    // ridge morphs into the next terrain.
    final fadeIn = ((rawPresence - .4) / .6).clamp(0.0, 1.0);
    final presence = fadeIn * fadeIn;
    if (presence <= .01) return;
    final h = f.h;
    var picture = _forumRoads[h];
    if (picture == null) {
      final recorder = PictureRecorder();
      _forumRoadPaint(Canvas(recorder), h);
      picture = recorder.endRecording();
      if (_forumRoads.length > 6) _forumRoads.remove(_forumRoads.keys.first)?.dispose();
      _forumRoads[h] = picture;
    }
    if (presence >= .999) {
      c.drawPicture(picture);
    } else {
      c.saveLayer(
        Rect.fromLTRB(-h * .7, h * .78, period(Depth.low) * h + h * .7, h * .98),
        Paint()..color = Sketch.fade(const Color(0xff000000), presence),
      );
      c.drawPicture(picture);
      c.restore();
    }
    // The ox swishes its tail.
    final gy = _y(Depth.low, _forumCartX * h, h) + h * .064;
    final root = Offset((_forumCartX + .097) * h, gy - h * .047);
    final sway = math.sin(f.clock * 1.7) * h * .007;
    c.drawPath(
      Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(root.dx - h * .006 + sway * .5, root.dy + h * .014, root.dx - h * .003 + sway, root.dy + h * .03),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, h * .0032)
        ..color = Sketch.fade(const Color(0xffb8a690), presence),
    );
    c.drawCircle(Offset(root.dx - h * .003 + sway, root.dy + h * .031), h * .0042, Paint()..color = Sketch.fade(const Color(0xff6a5644), presence));
  }

  static const _forumBasalt = [Color(0xffab957a), Color(0xffb8a287), Color(0xff9f8872), Color(0xffbda78c), Color(0xffa78f78)];

  void _forumRoadPaint(Canvas c, double h) {
    final span = period(Depth.low) * h;
    double top(double x) => ridge(Depth.low, x / h, 0) * h;
    final p = Paint();
    void wrapped(double x, double r, void Function(double x) draw) {
      draw(x);
      if (x - r < 0) draw(x + span);
      if (x + r > span) draw(x - span);
    }
    final steps = (span / (h * .04)).round();
    final xs = [for (var i = 0; i <= steps; i++) span * i / steps];
    Path band(double a, double b) {
      final path = Path()..moveTo(0, top(0) + a * h);
      for (final x in xs.skip(1)) {
        path.lineTo(x, top(x) + a * h);
      }
      for (final x in xs.reversed) {
        path.lineTo(x, top(x) + b * h);
      }
      return path..close();
    }
    Path line(double a) {
      final path = Path()..moveTo(0, top(0) + a * h);
      for (final x in xs.skip(1)) {
        path.lineTo(x, top(x) + a * h);
      }
      return path;
    }
    // Trodden dust and scuffs on the ground either side of the paving.
    for (var i = 0; i < 90; i++) {
      final x = span * Sketch.hash(i * 5 + 8000);
      final y = top(x) + h * (.004 + .09 * Sketch.hash(i * 5 + 8001));
      final w = h * (.012 + .034 * Sketch.hash(i * 5 + 8002));
      p.color = Sketch.hash(i * 5 + 8003) < .5 ? const Color(0x26f6e0b4) : const Color(0x22a4733c);
      wrapped(x, w, (dx) => c.drawOval(Rect.fromCenter(center: Offset(dx, y), width: w, height: w * .15), p));
    }
    // The road: a dark bed for the joints, kerbs, three rows of basalt setts.
    const roadTop = .017, kerbTop = .0065, kerbBottom = .005;
    const rows = [(.0115, .045, 8100), (.0145, .058, 8200), (.017, .075, 8300)];
    const roadBottom = roadTop + kerbTop + .0115 + .0145 + .017 + kerbBottom;
    c.drawPath(band(roadTop, roadBottom), p..color = const Color(0xff85694f));
    // Joints for one row, from a (usually negative) start so that one stone
    // straddles the seam; [lay] draws that stone again a period later.
    List<double> cuts(double avg, int seed) {
      final n = (span / (h * avg)).round();
      final raw = [for (var i = 0; i < n; i++) .68 + .64 * Sketch.hash(seed + i)];
      final total = raw.fold(0.0, (a, b) => a + b);
      var acc = -raw[0] / total * span * (.15 + .7 * Sketch.hash(seed + 99));
      final out = <double>[acc];
      for (final r in raw) {
        acc += r / total * span;
        out.add(acc);
      }
      return out;
    }
    void lay(List<double> cs, void Function(int i, double xl, double xr) put) {
      for (var i = 0; i < cs.length - 1; i++) {
        put(i, cs[i], cs[i + 1]);
      }
      put(0, cs[0] + span, cs[1] + span);
    }
    // Setts are batched by colour, one path and one draw each, with their lit
    // edges batched by strength.
    final fills = <Color, Path>{};
    final glints = [Path(), Path(), Path(), Path()];
    void sett(double xl, double xr, double a, double b, Color col, int seed, {double gap = .0016, int glint = 0}) {
      final ja = h * .0021;
      double j(int k) => (Sketch.hash(seed * 7 + k) - .5) * 2 * ja;
      final gx = h * gap, gy = h * gap * .8;
      final tl = Offset(xl + gx + j(1), top(xl) + a * h + gy + j(2));
      final tr = Offset(xr - gx + j(3), top(xr) + a * h + gy + j(4));
      final br = Offset(xr - gx + j(5), top(xr) + b * h - gy + j(6));
      final bl = Offset(xl + gx + j(7), top(xl) + b * h - gy + j(8));
      (fills[col] ??= Path()).addPolygon([tl, tr, br, bl], true);
      glints[glint]
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(tr.dx, tr.dy);
    }
    final worn = [for (final t in _forumBasalt) Sketch.mix(t, const Color(0xffb59c80), .2)];
    var y = roadTop + kerbTop;
    for (final (rh, avg, seed) in rows) {
      final rowY = y;
      lay(cuts(avg, seed), (i, xl, xr) {
        final pick = (Sketch.hash(seed + i * 3 + 1) * _forumBasalt.length).floor() % _forumBasalt.length;
        final col = Sketch.hash(seed + i * 3 + 2) < .35 ? worn[pick] : _forumBasalt[pick];
        sett(xl, xr, rowY, rowY + rh, col, seed + i, glint: (Sketch.hash(seed + i * 3) * 3).floor().clamp(0, 2));
      });
      y += rh;
    }
    // The top kerb: long, pale slabs in the sun; the bottom one in shade.
    const kerbLit = [Color(0xffddc7a0), Color(0xffd3bb94), Color(0xffcbb08c)];
    const kerbShade = [Color(0xffb69c7c), Color(0xffab9174)];
    lay(cuts(.24, 8400), (i, xl, xr) => sett(xl, xr, roadTop, roadTop + kerbTop, kerbLit[(Sketch.hash(8410 + i) * 3).floor() % 3], 8420 + i, gap: .0012, glint: 3));
    lay(cuts(.28, 8500), (i, xl, xr) => sett(xl, xr, roadBottom - kerbBottom, roadBottom, kerbShade[(Sketch.hash(8510 + i) * 2).floor() % 2], 8520 + i, gap: .0012, glint: 2));
    fills.forEach((col, path) => c.drawPath(path, p..color = col));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, h * .0013);
    for (var i = 0; i < glints.length; i++) {
      c.drawPath(glints[i], edge..color = Sketch.fade(const Color(0xfff2d9a6), const [.12, .24, .34, .7][i]));
    }
    // The kerb shades the setts under it; wheels have worn two shallow ruts.
    c.drawPath(band(roadTop + kerbTop, roadTop + kerbTop + .0035), p..color = const Color(0x2c3c2430));
    for (final r in const [.0116, .0295]) {
      final ry = roadTop + kerbTop + r + .0115;
      c.drawPath(line(ry), Paint()..style = PaintingStyle.stroke..strokeWidth = h * .0022..color = const Color(0x2e382418));
      c.drawPath(line(ry + .0026), Paint()..style = PaintingStyle.stroke..strokeWidth = h * .0012..color = const Color(0x30f6e2b6));
    }
    // Drifts of dust and worn patches soften the paving into the ground.
    for (var i = 0; i < 46; i++) {
      final x = span * Sketch.hash(i * 4 + 8900);
      final yy = top(x) + h * (roadTop + kerbTop + .043 * Sketch.hash(i * 4 + 8901));
      final w = h * (.03 + .07 * Sketch.hash(i * 4 + 8902));
      p.color = Sketch.hash(i * 4 + 8903) < .6 ? const Color(0x2ef2dcaa) : const Color(0x1e70502e);
      wrapped(x, w, (dx) => c.drawOval(Rect.fromCenter(center: Offset(dx, yy), width: w, height: w * .09 + h * .004), p));
    }
    // Weeds and moss push up between the setts and along the verges.
    final straw = Path(), green = Path(), dry = Path();
    void tuft(Path path, double x, double y, double size, int seed) {
      for (var k = 0; k < 4; k++) {
        final lean = (Sketch.hash(seed * 5 + k) - .5) * size * .9;
        final len = size * (.55 + .45 * Sketch.hash(seed * 5 + k + 40));
        final bx = x + (k - 1.5) * size * .16;
        path
          ..moveTo(bx - size * .07, y)
          ..quadraticBezierTo(bx + lean * .3, y - len * .55, bx + lean, y - len)
          ..quadraticBezierTo(bx + lean * .35 + size * .05, y - len * .5, bx + size * .07, y)
          ..close();
      }
    }
    for (var i = 0; i < 70; i++) {
      final x = span * Sketch.hash(i * 3 + 8600);
      final upper = Sketch.hash(i * 3 + 8601) < .45;
      final yy = top(x) + h * (upper ? .003 + .011 * Sketch.hash(i * 3 + 8602) : .078 + .012 * Sketch.hash(i * 3 + 8602));
      final size = h * (upper ? .012 : .016) * (.7 + .6 * Sketch.hash(i * 3 + 8603));
      final pick = Sketch.hash(i * 3 + 8604);
      wrapped(x, size, (dx) => tuft(pick < .4 ? straw : (pick < .75 ? green : dry), dx, yy, size, i));
    }
    c.drawPath(dry, p..color = const Color(0xff6f7440));
    c.drawPath(straw, p..color = const Color(0xffc2ae66));
    c.drawPath(green, p..color = const Color(0xff88a052));
    for (var i = 0; i < 36; i++) {
      final x = span * Sketch.hash(i * 4 + 8700);
      final yy = top(x) + h * (roadTop + kerbTop + .0115 + .043 * Sketch.hash(i * 4 + 8701));
      p.color = Sketch.fade(const Color(0xff6d8a48), .7);
      wrapped(x, h * .01, (dx) => c.drawOval(Rect.fromCenter(center: Offset(dx, yy), width: h * .008, height: h * .0032), p));
    }
    // Poppies and daisies in the verge, tiny and pale.
    for (var i = 0; i < 16; i++) {
      final x = span * Sketch.hash(i * 4 + 8800);
      final yy = top(x) + h * (i.isEven ? .008 : .083) + h * .004 * Sketch.hash(i * 4 + 8801);
      p.color = i % 3 == 0 ? const Color(0xffd66a4a) : const Color(0xfff6efdc);
      wrapped(x, h * .01, (dx) => c.drawCircle(Offset(dx, yy), math.max(.8, h * .0026), p));
    }
    // Long shadows from the landmarks, laid across the road.
    final shadow = Paint()..color = const Color(0x384a2c3a);
    void cast(double u, double halfW, double height, {double lenK = 1.3, bool gable = false}) {
      final x = u * h, y0 = top(x) + h * .012, dx = height * lenK, dy = math.min(height * .2, h * .078);
      final path = gable
          ? (Path()..addPolygon([Offset(x - halfW, y0), Offset(x + halfW, y0), Offset(x + halfW + dx * .84, y0 + dy * .84), Offset(x + dx, y0 + dy), Offset(x - halfW + dx * .84, y0 + dy * .84)], true))
          : (Path()..addPolygon([Offset(x - halfW, y0), Offset(x + halfW, y0), Offset(x + dx, y0 + dy)], true));
      wrapped(x, dx + halfW, (ox) => c.drawPath(path.shift(Offset(ox - x, 0)), shadow));
    }
    for (final (u, s) in _forumCypresses) {
      cast(u, s * h * .07, s * h);
    }
    cast(_forumTempleX, h * _forumTempleS * .57, h * _forumTempleS * .95, gable: true, lenK: 1.2);
    cast(_forumAltarX, h * _forumAltarS * .5, h * _forumAltarS * 1.3);
    cast(_forumPineX, h * .012, h * .3 * .8, lenK: 1.0);
    cast(_forumHonorX, h * .16 * .06, h * .16 * 1.5);
    cast(_forumRuinX, h * .21 * .6, h * .21 * .9, gable: true, lenK: 1.1);
    cast(.8, h * .1 * .18, h * .1);
    cast(1.43, h * .092 * .18, h * .092);
    cast(2.76, h * .085 * .18, h * .085);
    _forumMilestone(c, _forumMileX * h, top(_forumMileX * h) + h * .069, h);
    for (final (u, dy, size) in const [(.63, .082, .0075), (.66, .085, .0068), (1.53, .08, .0072)]) {
      _forumDove(c, Offset(u * h, top(u * h) + h * dy), h * size);
    }
    _forumCart(c, _forumCartX * h, top(_forumCartX * h) + h * .064, h);
  }

  /// A Roman milestone, a squat drum of stone on a block, with the road's
  /// number cut into it.
  static void _forumMilestone(Canvas c, double x, double gy, double h) {
    final lit = _forumTint(_forumLit), stone = _forumTint(const Color(0xffe0c9a0)), shade = _forumTint(_forumShade);
    final p = Paint();
    c.drawOval(Rect.fromCenter(center: Offset(x + h * .02, gy + h * .002), width: h * .09, height: h * .012), p..color = const Color(0x3a4a2c3a));
    c.drawRect(Rect.fromLTRB(x - h * .0135, gy - h * .009, x + h * .0135, gy), p..color = shade);
    c.drawRect(Rect.fromLTRB(x - h * .0135, gy - h * .009, x - h * .004, gy), p..color = stone);
    final body = Rect.fromLTRB(x - h * .0085, gy - h * .062, x + h * .0085, gy - h * .009);
    c.drawRect(body, p..color = stone);
    c.drawRect(Rect.fromLTRB(x - h * .0085, body.top, x - h * .004, body.bottom), p..color = lit);
    c.drawRect(Rect.fromLTRB(x + h * .0035, body.top, x + h * .0085, body.bottom), p..color = shade);
    c.drawOval(Rect.fromCenter(center: Offset(x, body.top), width: h * .017, height: h * .007), p..color = lit);
    final cut = Paint()
      ..color = const Color(0x886a4f40)
      ..strokeWidth = math.max(.6, h * .0014);
    for (final dy in const [.045, .0395, .034, .0285]) {
      c.drawLine(Offset(x - h * .004, gy - h * dy), Offset(x + h * .004, gy - h * dy), cut);
    }
  }

  /// A two-wheeled cart loaded with amphorae, drawn by a white ox, with its
  /// driver on the bench, parked in the road. The tail is animated in
  /// [_forumRoad]. [x] is the middle of the cart, [gy] the ground line.
  static void _forumCart(Canvas c, double x, double gy, double h) {
    final p = Paint();
    double px(double v) => x + v * h;
    double py(double v) => gy + v * h;
    const wood = Color(0xff9c7346), woodDark = Color(0xff6e4d2e), woodLit = Color(0xffc29360);
    c.drawOval(Rect.fromCenter(center: Offset(px(.05), py(0.002)), width: h * .27, height: h * .014), p..color = const Color(0x3a4a2c3a));
    // The ox first, so the pole and harness cross it.
    const ox = .1;
    const cream = Color(0xffe8dece), creamShade = Color(0xffbfae98), hoof = Color(0xff4a3a32);
    for (final dx in const [.011, -.019]) {
      c.drawRect(Rect.fromLTRB(px(ox + dx), py(-.028), px(ox + dx + .0065), py(-.003)), p..color = creamShade);
      c.drawRect(Rect.fromLTRB(px(ox + dx), py(-.004), px(ox + dx + .0065), py(0)), p..color = hoof);
    }
    c.drawOval(Rect.fromCenter(center: Offset(px(ox), py(-.037)), width: h * .066, height: h * .03), p..color = cream);
    c.drawOval(Rect.fromCenter(center: Offset(px(ox + .004), py(-.03)), width: h * .058, height: h * .014), p..color = Sketch.fade(creamShade, .7));
    c.drawCircle(Offset(px(ox + .019), py(-.047)), h * .011, p..color = cream);
    for (final dx in const [.02, -.027]) {
      c.drawRect(Rect.fromLTRB(px(ox + dx), py(-.028), px(ox + dx + .0068), py(-.003)), p..color = cream);
      c.drawRect(Rect.fromLTRB(px(ox + dx), py(-.004), px(ox + dx + .0068), py(0)), p..color = hoof);
    }
    c.drawPath(
      Sketch.poly([px(ox + .024), py(-.052), px(ox + .05), py(-.04), px(ox + .05), py(-.024), px(ox + .028), py(-.03)]),
      p..color = cream,
    );
    c.save();
    c.translate(px(ox + .054), py(-.027));
    c.rotate(.45);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: h * .022, height: h * .0125), p..color = cream);
    c.drawOval(Rect.fromCenter(center: Offset(h * .008, 0), width: h * .008, height: h * .0095), p..color = const Color(0xffc8a294));
    c.restore();
    c.drawCircle(Offset(px(ox + .057), py(-.031)), math.max(.5, h * .0011), p..color = const Color(0xff2a1e1a));
    final horn = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, h * .0021)
      ..color = const Color(0xfff2ead8);
    c.drawPath(
      Path()
        ..moveTo(px(ox + .046), py(-.036))
        ..quadraticBezierTo(px(ox + .042), py(-.05), px(ox + .05), py(-.054)),
      horn,
    );
    // The yoke and the pole that leads back to the cart.
    c.drawLine(Offset(px(ox + .027), py(-.058)), Offset(px(ox + .031), py(-.04)), Paint()..color = woodDark..strokeWidth = math.max(.8, h * .0032)..strokeCap = StrokeCap.round);
    c.drawLine(Offset(px(.05), py(-.03)), Offset(px(ox + .03), py(-.045)), Paint()..color = wood..strokeWidth = math.max(.8, h * .0032)..strokeCap = StrokeCap.round);
    // The cart: bed, slatted side, a load of amphorae, the driver.
    const bedTop = -.031;
    for (final (dx, hgt, tone) in const [(-.036, .03, 0xffc0683a), (-.011, .034, 0xffb75c34), (.014, .03, 0xffc8703e)]) {
      final base = Offset(px(dx), py(bedTop - .004));
      c.drawOval(Rect.fromCenter(center: base + Offset(0, -h * hgt * .38), width: h * .0135, height: h * hgt * .72), p..color = Color(tone));
      c.drawOval(Rect.fromCenter(center: base + Offset(-h * .003, -h * hgt * .42), width: h * .004, height: h * hgt * .5), p..color = Sketch.fade(const Color(0xffe8a070), .8));
      c.drawRect(Rect.fromLTRB(base.dx - h * .0028, base.dy - h * hgt, base.dx + h * .0028, base.dy - h * hgt * .68), p..color = Color(tone));
      c.drawRect(Rect.fromLTRB(base.dx - h * .0042, base.dy - h * hgt - h * .0015, base.dx + h * .0042, base.dy - h * hgt + h * .0012), p..color = woodDark);
    }
    c.drawRect(Rect.fromLTRB(px(-.056), py(bedTop - .014), px(.05), py(bedTop)), p..color = wood);
    c.drawRect(Rect.fromLTRB(px(-.056), py(bedTop - .014), px(.05), py(bedTop - .0115)), p..color = woodLit);
    c.drawRect(Rect.fromLTRB(px(-.056), py(bedTop - .003), px(.05), py(bedTop)), p..color = woodDark);
    for (var i = 0; i < 9; i++) {
      c.drawLine(Offset(px(-.052 + i * .0125), py(bedTop - .0115)), Offset(px(-.052 + i * .0125), py(bedTop - .003)), Paint()..color = Sketch.fade(woodDark, .55)..strokeWidth = math.max(.5, h * .0011));
    }
    // The driver sits on the front of the bed with a goad.
    c.drawPath(
      Sketch.poly([px(.028), py(bedTop - .0125), px(.029), py(bedTop - .03), px(.035), py(bedTop - .034), px(.043), py(bedTop - .03), px(.046), py(bedTop - .0125)]),
      p..color = const Color(0xffb27a3e),
    );
    c.drawPath(Sketch.poly([px(.028), py(bedTop - .0125), px(.029), py(bedTop - .03), px(.033), py(bedTop - .033), px(.0335), py(bedTop - .0125)]), p..color = const Color(0xffd29a52));
    c.drawLine(Offset(px(.041), py(bedTop - .031)), Offset(px(.061), py(bedTop - .025)), Paint()..color = const Color(0xffc48a5a)..strokeWidth = math.max(.7, h * .0028)..strokeCap = StrokeCap.round);
    c.drawLine(Offset(px(.06), py(bedTop - .025)), Offset(px(.098), py(-.052)), Paint()..color = woodDark..strokeWidth = math.max(.5, h * .0012));
    c.drawCircle(Offset(px(.0375), py(bedTop - .0405)), h * .0058, p..color = const Color(0xffc48a5a));
    c.drawOval(Rect.fromCenter(center: Offset(px(.0375), py(bedTop - .0435)), width: h * .019, height: h * .0036), p..color = const Color(0xffcbb27a));
    c.drawArc(Rect.fromCenter(center: Offset(px(.0375), py(bedTop - .0445)), width: h * .011, height: h * .011), math.pi, math.pi, true, p..color = const Color(0xffb89a5e));
    // The wheel: ring, eight spokes, hub.
    const r = .0175;
    final hub = Offset(px(-.008), py(-r));
    c.drawCircle(hub, h * r, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .0034..color = woodDark);
    c.drawCircle(hub, h * (r - .0034), Paint()..style = PaintingStyle.stroke..strokeWidth = h * .0026..color = wood);
    final spoke = Paint()..color = Sketch.mix(wood, woodLit, .4)..strokeWidth = math.max(.6, h * .0016);
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4 + .2;
      c.drawLine(hub, hub + Offset(math.cos(a), math.sin(a)) * h * (r - .003), spoke);
    }
    c.drawCircle(hub, h * .0034, p..color = woodDark);
    c.drawCircle(hub, h * .0015, p..color = woodLit);
  }

  // ---- foreground: the near band ------------------------------------------
  // Layout along the 3 h period, in viewport heights: (x, size, seed).
  static const _foreCypresses = [(.22, .40, 1), (2.0, .34, 2), (2.9, .26, 3)];
  static const _foreBushes = [(.48, .08, 1), (2.2, .09, 2), (2.74, .07, 3)];
  static const _foreSoldierAt = 1.66;

  static const _foreLit = Color(0xfff8edd3), _foreMarble = Color(0xffe8d7b8), _foreShade = Color(0xffc6b192);
  static const _foreDeep = Color(0xffa08d76), _foreGlow = Color(0xffbfa88a);

  void _foreFeatures(Canvas c, double h, double span) {
    double gy(double x) => _y(Depth.near, x * h, h) + h * .012;
    Offset at(double x) => Offset(x * h, gy(x));
    for (final (x, s, seed) in _foreCypresses) {
      _foreCypress(c, at(x), h * s, seed);
    }
    for (final (x, s, seed) in _foreBushes) {
      _foreLaurel(c, at(x), h * s, seed);
    }
    _foreAmphora(c, at(.63), h * .11, .2, 1);
    _foreAmphora(c, at(.69), h * .09, .1, 2);
    _column(c, at(.82), h * .19, broken: false, fine: true, entablature: true, seed: 1);
    _foreCapital(c, at(1.02), h * .115);
    _column(c, at(1.22), h * .19, broken: true, fine: true, seed: 2);
    _foreDrum(c, at(1.44), h * .05, h * .1);
    _column(c, at(2.56), h * .17, broken: false, fine: true, ivy: true, seed: 3);
    _foreAmphora(c, at(2.4) - Offset(0, h * .02), h * .1, 1.45, 3);
    _foreAmphora(c, at(2.34), h * .085, -.12, 4);
    _legionary(c, at(_foreSoldierAt) - Offset(0, h * .009), h * .2);
    // Grass and wildflowers poke over the crest of the hill.
    for (var i = 0; i < 38; i++) {
      final x = .05 + i * .077 + .04 * Sketch.hash(i + 830);
      _foreTuft(c, Offset(x * h, gy(x) - h * .004), h * (.03 + .03 * Sketch.hash(i + 831)), i);
    }
  }

  /// Cast shadows and the mosaic floor lie on the near ground, in front of it.
  void _foreOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    double ry(double x) => ridge(Depth.near, x, 0) * h;
    final p = Paint();
    void shadow(double x, double half, double alpha) {
      p.color = Sketch.fade(const Color(0xff3a2c16), alpha * presence);
      c.drawOval(Rect.fromCenter(center: Offset(x * h, ry(x) + h * .018), width: half * 2 * h, height: h * .016), p);
    }

    for (final (x, s, _) in _foreCypresses) {
      shadow(x + s * .3, s * .22, .13);
    }
    for (final (x, s, _) in _foreBushes) {
      shadow(x + s * .3, s * .85, .13);
    }
    for (final (x, hf) in const [(.82, .08), (1.22, .08), (2.56, .075), (1.02, .07), (1.44, .06)]) {
      shadow(x + .05, hf, .14);
    }
    shadow(_foreSoldierAt + .05, .13, .16);
    // A patch of villa mosaic under the legionary: a terracotta border round
    // a chequer of cream and slate tesserae, worn away in places.
    const cols = 24, rows = 3;
    final cw = h * .025, rh = h * .013;
    final x0 = (_foreSoldierAt - .3) * h;
    const cream = Color(0xffdccda8), clay = Color(0xffae7250), slate = Color(0xff6f6a62);
    for (var r = 0; r < rows; r++) {
      for (var i = 0; i < cols; i++) {
        final edge = i == 0 || i == cols - 1 || r == rows - 1 || r == 0;
        final hsh = Sketch.hash(i * 7 + r * 131 + 850);
        if (hsh > .93) continue;
        final col = edge ? clay : ((i + r).isEven ? cream : slate);
        final x = x0 + i * cw;
        final y = ry(x / h + .01) + h * (.014 + r * .0125);
        p.color = Sketch.fade(Sketch.mix(col, const Color(0xff8a7846), .12 + .25 * hsh), .85 * presence);
        c.drawRect(Rect.fromLTWH(x, y, cw * .97, rh * .95), p);
      }
    }
  }

  /// The legionary's red crest streams in the breeze.
  void _foreLive(Canvas c, SceneFrame f) {
    final h = f.h;
    final x = _foreSoldierAt * h;
    final base = Offset(x, _y(Depth.near, x, h) + h * .012);
    final k = h * .2 / 100;
    final sw = math.sin(f.clock * 1.7) * 1.4 + math.sin(f.clock * 2.9 + 1) * .6;
    Offset p(double px, double py) => Offset(base.dx + px * k, base.dy - py * k);
    final a = p(-3.4, 99.4), b = p(-4.2, 110), d = p(3 + sw * .4, 113.5), e = p(10 + sw, 113), g = p(12.5 + sw * 1.3, 104.5), i = p(7 + sw * .5, 104), j = p(4, 99.4);
    c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(b.dx, b.dy, d.dx, d.dy)
        ..quadraticBezierTo(e.dx, e.dy, g.dx, g.dy)
        ..quadraticBezierTo(i.dx, i.dy, j.dx, j.dy)
        ..close(),
      Paint()..color = const Color(0xffbf3a2c),
    );
    c.drawPath(_foreLens(p(-1, 101), p(6 + sw * .8, 110.5), 4.5 * k), Paint()..color = const Color(0xffe0634a));
    c.drawPath(_foreLens(p(1.5, 100.5), p(11 + sw * 1.2, 105.5), 3.5 * k), Paint()..color = const Color(0xff8a2620));
  }

  // ---- foreground primitives ----

  static Path _foreLens(Offset a, Offset b, double bulge) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return Path();
    final n = Offset(-d.dy, d.dx) / len * bulge;
    final m = Offset.lerp(a, b, .45)!;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(m.dx + n.dx, m.dy + n.dy, b.dx, b.dy)
      ..quadraticBezierTo(m.dx - n.dx, m.dy - n.dy, a.dx, a.dy)
      ..close();
  }

  /// A smooth closed curve through the midpoints of [p], bent toward each point.
  static Path _foreCurve(List<Offset> p) {
    final n = p.length;
    Offset m(int i) => Offset.lerp(p[i % n], p[(i + 1) % n], .5)!;
    final path = Path()..moveTo(m(n - 1).dx, m(n - 1).dy);
    for (var i = 0; i < n; i++) {
      final b = m(i);
      path.quadraticBezierTo(p[i].dx, p[i].dy, b.dx, b.dy);
    }
    return path..close();
  }

  static Paint _foreCyl(double x0, double x1) => Paint()
    ..shader = Gradient.linear(
      Offset(x0, 0),
      Offset(x1, 0),
      const [Color(0xfff2e4c6), _foreLit, _foreMarble, _foreShade, _foreDeep, _foreGlow],
      const [0, .16, .42, .7, .92, 1],
    );

  /// A tall cypress: scalloped flame silhouette, sun on its left flank, and
  /// small sprays of scale-leaf along the flame.
  static void _foreCypress(Canvas c, Offset base, double s, int seed) {
    final hwMax = s * .105;
    double hw(double t) => hwMax * 1.59 * math.pow(t, .72) * (1 - .55 * t * t * t);
    double lean(double t) => math.sin(t * 2.4 + seed) * s * .012 * (1 - t);
    const n = 20;
    Offset pt(int i, double side) {
      final t = i / n;
      final j = 1 + .07 * (Sketch.hash(seed * 97 + i * 2 + (side > 0 ? 1 : 0)) - .5);
      return Offset(base.dx + lean(t) + side * hw(t) * j, base.dy - s * (1 - t));
    }

    final path = Path()..moveTo(pt(0, -1).dx, pt(0, -1).dy);
    var prev = pt(0, -1);
    for (var i = 1; i <= n; i++) {
      final q = pt(i, -1);
      final m = Offset.lerp(prev, q, .5)!;
      path.quadraticBezierTo(m.dx - s * .012, m.dy, q.dx, q.dy);
      prev = q;
    }
    path.lineTo(pt(n, 1).dx, pt(n, 1).dy);
    prev = pt(n, 1);
    for (var i = n - 1; i >= 0; i--) {
      final q = pt(i, 1);
      final m = Offset.lerp(prev, q, .5)!;
      path.quadraticBezierTo(m.dx + s * .012, m.dy, q.dx, q.dy);
      prev = q;
    }
    path.close();
    c.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx - hwMax, 0),
          Offset(base.dx + hwMax, 0),
          const [Color(0xff52744a), Color(0xff3d5f3b), Color(0xff2c4a30), Color(0xff1f3828)],
          const [0, .32, .68, 1],
        ),
    );
    // The foot sits in shadow.
    c.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base.dy - s * .45),
          Offset(0, base.dy),
          const [Color(0x00142418), Color(0x66142418)],
        ),
    );
    final tuft = Paint();
    for (var i = 0; i < 40; i++) {
      final t = .1 + .86 * Sketch.hash(seed * 300 + i * 3);
      final u = (Sketch.hash(seed * 300 + i * 3 + 1) * 2 - 1) * .8;
      final p = Offset(base.dx + lean(t) + u * hw(t), base.dy - s * (1 - t));
      final len = s * (.045 + .04 * Sketch.hash(seed * 300 + i * 3 + 2));
      final a = -math.pi / 2 + u * .6;
      tuft.color = u < -.25
          ? const Color(0xb87f9f55)
          : (u > .3 ? const Color(0x991a3022) : const Color(0x80456a42));
      c.drawPath(_foreLens(p, p + Offset(math.cos(a), math.sin(a)) * len, s * .024), tuft);
    }
    // Low sun catches the crest of the left flank.
    c.drawPath(
      _foreLens(pt(4, -1) + Offset(s * .012, 0), pt(15, -1) + Offset(s * .012, 0), s * .03),
      Paint()..color = const Color(0x66b6c878),
    );
  }

  /// A bay-laurel bush: a dark mass of leaves with sunlit sprays on its upper
  /// left and a few black berries.
  static void _foreLaurel(Canvas c, Offset base, double s, int seed) {
    final w = s * 1.55;
    final p = Paint()..color = const Color(0xff26422a);
    for (var i = 0; i < 8; i++) {
      final f = i / 7;
      final r = s * (.3 + .16 * math.sin(f * math.pi)) * (.9 + .2 * Sketch.hash(seed * 40 + i));
      c.drawCircle(Offset(base.dx + (f - .5) * w * .78, base.dy - r * .72), r, p);
    }
    const shades = [Color(0xff26422a), Color(0xff386637), Color(0xff4f8040), Color(0xff78a54c), Color(0xffa6c56a)];
    for (var i = 0; i < 64; i++) {
      final f = Sketch.hash(seed * 500 + i * 4);
      final v = Sketch.hash(seed * 500 + i * 4 + 1);
      final top = s * (.15 + .62 * math.pow(math.sin(f * math.pi), .8));
      final pos = Offset(base.dx + (f - .5) * w * .92, base.dy - top * (.15 + .85 * v));
      final light = ((1 - f) * .55 + v * .5 + .18 * (Sketch.hash(seed * 500 + i * 4 + 2) - .5)).clamp(0.0, .999);
      p.color = shades[(light * 5).floor()];
      final a = -math.pi / 2 + (Sketch.hash(seed * 500 + i * 4 + 3) - .5) * 2.4;
      c.drawPath(_foreLens(pos, pos + Offset(math.cos(a), math.sin(a)) * s * .12, s * .05), p);
    }
    p.color = const Color(0xff2e2436);
    for (var i = 0; i < 5; i++) {
      c.drawCircle(
        Offset(base.dx + (Sketch.hash(seed * 60 + i) - .5) * w * .7, base.dy - s * (.25 + .4 * Sketch.hash(seed * 60 + i + 9))),
        s * .018,
        p,
      );
    }
  }

  /// A terracotta amphora standing (or, tilted far over, lying) on its toe.
  static void _foreAmphora(Canvas c, Offset toe, double s, double tilt, int seed) {
    final k = s / 100;
    c.save();
    c.translate(toe.dx, toe.dy);
    c.rotate(tilt);
    Offset q(double x, double y) => Offset(x * k, -y * k);
    const prof = [(0.0, 1.8), (12.0, 8.5), (30.0, 16.0), (46.0, 19.0), (60.0, 17.0), (72.0, 12.5), (80.0, 6.0), (90.0, 5.2), (93.0, 8.2), (100.0, 8.2)];
    final pts = [for (final (y, w) in prof) q(-w, y), for (final (y, w) in prof.reversed) q(w, y)];
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, 4.4 * k)
      ..color = const Color(0xff9a5030);
    for (final sg in const [-1.0, 1.0]) {
      final a = q(sg * 5.2, 89), b = q(sg * 22, 98), d = q(sg * 26, 76), e = q(sg * 14.5, 68);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..cubicTo(b.dx, b.dy, d.dx, d.dy, e.dx, e.dy),
        handle,
      );
    }
    c.drawPath(
      _foreCurve(pts),
      Paint()
        ..shader = Gradient.linear(
          Offset(-19 * k, 0),
          Offset(19 * k, 0),
          const [Color(0xffe39a6c), Color(0xffcf7a45), Color(0xffa85a34), Color(0xff783c26)],
          const [0, .35, .72, 1],
        ),
    );
    final band = Paint()..color = const Color(0xff4a2a20);
    c.drawPath(Sketch.poly([-16.4, -64, 16.4, -64, 14, -69, -14, -69], s: k), band);
    c.drawPath(Sketch.poly([-18.4, -36, 18.4, -36, 18.7, -40, -18.7, -40], s: k), band);
    c.drawPath(_foreLens(q(-12, 58), q(-14.5, 30), 3.4 * k), Paint()..color = const Color(0x66f6c49a));
    c.drawOval(Rect.fromCenter(center: q(0, 100), width: 15.6 * k, height: 3.6 * k), Paint()..color = const Color(0xff3a2018));
    c.restore();
  }

  /// A fluted drum fallen on its side, one end showing its dowel hole.
  static void _foreDrum(Canvas c, Offset base, double dia, double len) {
    final top = base.dy - dia;
    final r = Rect.fromLTRB(base.dx - len / 2, top, base.dx + len / 2, base.dy);
    c.drawOval(Rect.fromCenter(center: Offset(r.left, top + dia / 2), width: dia * .42, height: dia), Paint()..color = _foreShade);
    c.drawRect(
      r,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, base.dy),
          const [_foreLit, _foreMarble, _foreShade, _foreDeep, _foreGlow],
          const [0, .3, .62, .9, 1],
        ),
    );
    final line = Paint()
      ..color = const Color(0x40704e34)
      ..strokeWidth = math.max(.6, dia * .035);
    for (final f in const [.22, .42, .62, .8]) {
      c.drawLine(Offset(r.left + len * .04, top + dia * f), Offset(r.right - len * .02, top + dia * f), line);
    }
    c.drawOval(Rect.fromCenter(center: Offset(r.right, top + dia / 2), width: dia * .42, height: dia), Paint()..color = const Color(0xffefe2c4));
    c.drawOval(Rect.fromCenter(center: Offset(r.right, top + dia / 2), width: dia * .3, height: dia * .72), Paint()..color = const Color(0xffdac6a4));
    c.drawOval(Rect.fromCenter(center: Offset(r.right + dia * .02, top + dia / 2), width: dia * .1, height: dia * .18), Paint()..color = const Color(0xff7a6650));
    final moss = Paint()..color = const Color(0xd95c8a3c);
    for (final f in const [.15, .38, .66]) {
      c.drawOval(Rect.fromCenter(center: Offset(r.left + len * f, top + dia * .06), width: len * .16, height: dia * .16), moss);
    }
  }

  /// A Corinthian capital lying on its side in the grass: bell, two rows of
  /// acanthus and the square abacus slab.
  static void _foreCapital(Canvas c, Offset base, double s) {
    final hb = s * .8, hs = s * .48;
    final l = base.dx - s * .5, r = base.dx + s * .5;
    final bell = Path()
      ..moveTo(l, base.dy - hs * .1)
      ..lineTo(l + s * .05, base.dy - hs)
      ..quadraticBezierTo(base.dx + s * .1, base.dy - hs * .85, r - s * .2, base.dy - hb * .94)
      ..lineTo(r - s * .2, base.dy)
      ..lineTo(l + s * .05, base.dy)
      ..close();
    c.drawPath(
      bell,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base.dy - hb),
          Offset(0, base.dy),
          const [_foreLit, _foreMarble, _foreShade, _foreDeep],
          const [0, .35, .72, 1],
        ),
    );
    final leaf = Paint();
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < 3; i++) {
        final x = l + s * (.14 + row * .1 + i * .13);
        final y = base.dy - hs * (.35 + row * .32) - i * hs * .05;
        final len = s * (.2 - row * .03);
        for (final a in const [-.55, 0.0, .55]) {
          final tip = Offset(x + math.cos(a - .5) * len * (a == 0 ? 1 : .75), y + math.sin(a - .5) * len * (a == 0 ? 1 : .75));
          c.drawPath(_foreLens(Offset(x + s * .012, y + s * .016), tip + Offset(s * .012, s * .016), s * .045), leaf..color = const Color(0x664a3422));
          c.drawPath(_foreLens(Offset(x, y), tip, s * .045), leaf..color = row == 0 ? const Color(0xffe9d9bb) : const Color(0xfff6ead0));
        }
      }
    }
    // Abacus slab with its shadowed underside.
    final slab = Rect.fromLTRB(r - s * .2, base.dy - hb, r, base.dy - hb * .05);
    c.drawRect(slab, Paint()..color = _foreMarble);
    c.drawRect(Rect.fromLTRB(slab.left, slab.top, slab.left + s * .04, slab.bottom), Paint()..color = _foreLit);
    c.drawRect(Rect.fromLTRB(slab.right - s * .05, slab.top, slab.right, slab.bottom), Paint()..color = _foreShade);
    c.drawRect(Rect.fromLTRB(slab.left, slab.top + hb * .05, slab.right, slab.top + hb * .09), Paint()..color = const Color(0x554e3a28));
    c.drawOval(Rect.fromCenter(center: Offset(slab.center.dx, slab.top + hb * .34), width: s * .1, height: s * .1), Paint()..color = _foreDeep);
    c.drawOval(Rect.fromCenter(center: Offset(slab.center.dx, slab.top + hb * .34), width: s * .05, height: s * .05), Paint()..color = _foreShade);
    final moss = Paint()..color = const Color(0xd95c8a3c);
    for (final f in const [.12, .4, .58]) {
      c.drawOval(Rect.fromCenter(center: Offset(l + s * f, base.dy - hs * (1.02 - f * .2)), width: s * .14, height: s * .05), moss);
    }
  }

  /// A tuft of grass, sometimes with a wildflower, rooted on the crest.
  static void _foreTuft(Canvas c, Offset root, double s, int seed) {
    final dark = Path(), lit = Path();
    double? flowerY, flowerX;
    for (var i = 0; i < 6; i++) {
      final dx = (i - 2.5) * s * .11;
      final tall = .7 + .5 * Sketch.hash(seed * 20 + i);
      final tip = Offset(root.dx + dx * 2 + (Sketch.hash(seed * 20 + i + 7) - .5) * s * .35, root.dy - s * tall);
      final path = i.isEven ? dark : lit;
      path
        ..moveTo(root.dx + dx - s * .05, root.dy)
        ..quadraticBezierTo(root.dx + dx * 1.2, root.dy - s * tall * .55, tip.dx, tip.dy)
        ..quadraticBezierTo(root.dx + dx * 1.5, root.dy - s * tall * .5, root.dx + dx + s * .05, root.dy)
        ..close();
      if (i == 3) {
        flowerX = tip.dx;
        flowerY = tip.dy;
      }
    }
    c.drawPath(dark, Paint()..color = const Color(0xff556f3a));
    c.drawPath(lit, Paint()..color = const Color(0xff8fa653));
    if (Sketch.hash(seed + 900) < .4 && flowerX != null && flowerY != null) {
      const petals = [Color(0xfff4ecd8), Color(0xffc8382e), Color(0xffa585c4)];
      c.drawCircle(Offset(flowerX, flowerY), s * .1, Paint()..color = petals[seed % 3]);
    }
  }

  /// A fluted marble column on a moulded base under an acanthus capital, or a
  /// broken stump of drums. [fine] adds the flutes, drum joints and carving
  /// (the near band); [entablature] leaves a fragment of beam on the capital;
  /// [ivy] trails up the shaft.
  static void _column(
    Canvas c,
    Offset base,
    double s, {
    required bool broken,
    bool fine = false,
    bool entablature = false,
    bool ivy = false,
    int seed = 0,
  }) {
    final d = s * .17;
    final cx = base.dx;
    double y(double f) => base.dy - s * f;
    final mid = Paint();
    void rect(double x0, double f0, double x1, double f1, Color col) {
      c.drawRect(Rect.fromLTRB(cx + x0 * d, y(f1), cx + x1 * d, y(f0)), mid..color = col);
    }

    // Plinth and moulded base.
    rect(-.95, 0, .95, .045, _foreMarble);
    rect(-.95, 0, -.6, .045, _foreLit);
    rect(.45, 0, .95, .045, _foreShade);
    for (final (hw, f0, f1) in const [(.81, .045, .08), (.71, .092, .12)]) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(cx - hw * d, y(f1), cx + hw * d, y(f0)), Radius.circular(s * .012)),
        _foreCyl(cx - hw * d, cx + hw * d),
      );
    }
    rect(-.62, .08, .62, .092, _foreDeep);

    // The shaft, tapering with a slight swell (entasis).
    const f0 = .12, f1 = .8;
    double hw(double u) => d * .5 * (1 - .17 * u) + d * .012 * math.sin(math.pi * u);
    final uTop = broken ? .6 : 1.0;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= 8; i++) {
      final u = uTop * i / 8;
      final yy = y(f0 + (f1 - f0) * u);
      left.add(Offset(cx - hw(u), yy));
      right.add(Offset(cx + hw(u), yy));
    }
    final shaft = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      shaft.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      shaft.lineTo(p.dx, p.dy);
    }
    shaft.close();
    final cyl = _foreCyl(cx - d * .52, cx + d * .52);
    c.drawPath(shaft, cyl);

    void flutes(double ua, double ub, double dx) {
      for (var i = 0; i < 9; i++) {
        final th = (-72 + i * 18) * math.pi / 180;
        final rel = math.sin(th), dw = .075 * math.cos(th);
        final ya = y(f0 + (f1 - f0) * ua), yb = y(f0 + (f1 - f0) * ub);
        mid.color = Color.fromARGB((46 + 40 * (rel + 1) / 2).round(), 0x6a, 0x4a, 0x30);
        c.drawPath(
          Sketch.poly([
            cx + dx + (rel - dw) * hw(ua), ya,
            cx + dx + (rel + dw) * hw(ua), ya,
            cx + dx + (rel + dw) * hw(ub), yb,
            cx + dx + (rel - dw) * hw(ub), yb,
          ]),
          mid,
        );
      }
    }

    if (fine) {
      flutes(.03, uTop - .03, 0);
      final joint = Paint()
        ..color = const Color(0x594a3422)
        ..strokeWidth = math.max(.6, d * .04);
      final glint = Paint()
        ..color = const Color(0x55fff4d8)
        ..strokeWidth = math.max(.5, d * .03);
      for (final u in const [.27, .52, .77]) {
        if (u >= uTop - .02) continue;
        final yy = y(f0 + (f1 - f0) * u);
        c.drawLine(Offset(cx - hw(u), yy), Offset(cx + hw(u), yy), joint);
        c.drawLine(Offset(cx - hw(u), yy + d * .05), Offset(cx + hw(u), yy + d * .05), glint);
      }
      // Rain runs down the stone from the top.
      c.drawPath(_foreLens(Offset(cx - d * .1, y(f0 + (f1 - f0) * uTop)), Offset(cx - d * .06, y(.4)), d * .06), Paint()..color = const Color(0x1f6a4a30));
      c.drawPath(_foreLens(Offset(cx + d * .22, y(f0 + (f1 - f0) * uTop)), Offset(cx + d * .2, y(.3)), d * .07), Paint()..color = const Color(0x1f6a4a30));
    } else {
      flutes(.05, uTop - .05, 0);
    }

    if (broken) {
      // The next drum slipped and cocked over; above it the shaft snapped.
      final dx = d * .16;
      final ua = .6, ub = .9;
      final pts = <double>[];
      for (var i = 0; i <= 4; i++) {
        final u = ua + (ub - ua) * i / 4;
        pts.addAll([cx + dx - hw(u) + (u - ua) * d * .3, y(f0 + (f1 - f0) * u)]);
      }
      // Jagged fracture, high on the left and stepping down to the right.
      final ft = y(f0 + (f1 - f0) * ub);
      final fx = cx + dx + (ub - ua) * d * .3;
      pts.addAll([fx - hw(ub) * .5, ft - s * .075, fx - hw(ub) * .1, ft + s * .02, fx + hw(ub) * .35, ft - s * .05, fx + hw(ub), ft + s * .04]);
      for (var i = 4; i >= 0; i--) {
        final u = ua + (ub - ua) * i / 4;
        pts.addAll([cx + dx + hw(u) + (u - ua) * d * .3, y(f0 + (f1 - f0) * u)]);
      }
      c.drawPath(Sketch.poly(pts), cyl);
      c.drawLine(
        Offset(cx - hw(ua) + dx * .1, y(f0 + (f1 - f0) * ua)),
        Offset(cx + hw(ua) + dx * 1.1, y(f0 + (f1 - f0) * ua)),
        Paint()
          ..color = const Color(0x8c3a281a)
          ..strokeWidth = math.max(.7, d * .06),
      );
      if (fine) {
        final yy = y(f0 + (f1 - f0) * ua);
        flutes(ua + .02, ub - .06, dx + d * .04);
        // The break, a paler face of fresh stone with a dark crack.
        c.drawPath(Sketch.poly([fx - hw(ub) * .5, ft - s * .075, fx - hw(ub) * .1, ft + s * .02, fx - hw(ub) * .3, ft + s * .045]), Paint()..color = const Color(0xfff6ecd6));
        c.drawPath(Sketch.poly([fx - hw(ub) * .1, ft + s * .02, fx + hw(ub) * .35, ft - s * .05, fx + hw(ub) * .1, ft + s * .045]), Paint()..color = const Color(0xffb8a488));
        c.drawLine(Offset(fx - hw(ub) * .2, ft + s * .02), Offset(fx - hw(ub) * .35, yy - s * .05), Paint()..color = const Color(0x664a3422)..strokeWidth = math.max(.5, d * .03));
        // Chips lie where they fell.
        for (final (px, w, hgt) in [(.95, .3, .14), (1.35, .22, .1), (-1.15, .25, .12)]) {
          c.drawPath(
            Sketch.poly([cx + px * d, base.dy, cx + (px + w * .3) * d, base.dy - hgt * d, cx + (px + w) * d, base.dy - hgt * d * .4, cx + (px + w * 1.1) * d, base.dy]),
            Paint()..color = _foreMarble,
          );
        }
      }
    } else {
      // Astragal, then the Corinthian capital.
      rect(-.48, .8, .48, .812, _foreMarble);
      rect(-.48, .8, -.3, .812, _foreLit);
      final capL = <Offset>[Offset(cx - d * .42, y(.812)), Offset(cx - d * .52, y(.86)), Offset(cx - d * .68, y(.905)), Offset(cx - d * .8, y(.93))];
      final cap = Path()..moveTo(capL.first.dx, capL.first.dy);
      for (final p in capL.skip(1)) {
        cap.lineTo(p.dx, p.dy);
      }
      for (final p in capL.reversed) {
        cap.lineTo(2 * cx - p.dx, p.dy);
      }
      cap.close();
      c.drawPath(cap, _foreCyl(cx - d * .8, cx + d * .8));
      if (fine) {
        final leaf = Paint();
        void acanthus(double x, double f, double len, double wid, Color col) {
          leaf.color = col;
          final o = Offset(cx + x * d, y(f));
          for (final a in const [-.5, 0.0, .5]) {
            final l = len * (a == 0 ? 1 : .74);
            c.drawPath(_foreLens(o, o + Offset(math.sin(a + x * .25), -math.cos(a + x * .25)) * l * s, wid * s), leaf);
          }
        }

        for (var i = 0; i < 5; i++) {
          final x = (i - 2) * .27;
          acanthus(x, .815, .085 - .012 * (x * x), .026, i < 2 ? const Color(0xffefe1c3) : const Color(0xffd9c7a6));
        }
        for (var i = 0; i < 3; i++) {
          final x = (i - 1) * .4;
          acanthus(x, .85, .088, .026, i == 0 ? const Color(0xfffaf0da) : (i == 1 ? const Color(0xffefe1c3) : const Color(0xffd3bf9c)));
        }
        // Volutes curl under the corners of the abacus.
        for (final sg in const [-1.0, 1.0]) {
          final o = Offset(cx + sg * d * .66, y(.915));
          c.drawCircle(o, d * .15, Paint()..color = sg < 0 ? _foreLit : _foreMarble);
          c.drawCircle(o, d * .08, Paint()..color = _foreDeep);
        }
      }
      // Abacus.
      rect(-.9, .93, .9, 1.0, _foreMarble);
      rect(-.9, .93, -.5, 1.0, _foreLit);
      rect(.5, .93, .9, 1.0, _foreShade);
      rect(-.9, .93, .9, .94, _foreDeep);
      if (entablature) _foreEntablature(c, Offset(cx, y(1.0)), d, seed);
    }

    if (fine) {
      // Moss where damp gathers at the foot.
      final moss = Paint()..color = const Color(0xdc5c8a3c);
      for (var i = 0; i < 6; i++) {
        final mx = cx + (Sketch.hash(seed * 30 + i) * 2 - 1) * d * .85;
        c.drawOval(Rect.fromCenter(center: Offset(mx, y(.06 + .05 * Sketch.hash(seed * 30 + i + 5))), width: d * (.3 + .25 * Sketch.hash(seed * 30 + i + 9)), height: d * .16), moss);
      }
      if (ivy) {
        final vine = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.6, d * .04)
          ..color = const Color(0xff36552f);
        final path = Path()..moveTo(cx + d * .3, y(.1));
        for (var i = 1; i <= 12; i++) {
          final t = i / 12;
          path.lineTo(cx + d * (.32 - .1 * math.sin(t * 6)), y(.1 + .5 * t));
        }
        c.drawPath(path, vine);
        for (var i = 0; i < 16; i++) {
          final t = i / 15;
          final o = Offset(cx + d * (.32 - .1 * math.sin(t * 6)) + (i.isEven ? -1 : 1) * d * .12, y(.1 + .5 * t));
          c.drawCircle(o, d * (.1 + .05 * Sketch.hash(seed * 70 + i)), Paint()..color = i % 3 == 0 ? const Color(0xff6a9a48) : const Color(0xff3d6a38));
        }
      }
    }
  }

  /// A fragment of entablature still resting on a capital: three fasciae, a
  /// carved frieze, dentils and the projecting cornice, both ends broken.
  static void _foreEntablature(Canvas c, Offset top, double d, int seed) {
    final p = Paint();
    double y = top.dy;
    void block(double h, double xl, double xr, Color col, {Color? under, Color? litCol}) {
      final r = Rect.fromLTRB(top.dx + xl * d, y - h * d, top.dx + xr * d, y);
      // Broken ends: the outline steps in a little at each corner.
      c.drawPath(
        Sketch.poly([
          r.left, r.bottom,
          r.left + d * .12, r.center.dy,
          r.left, r.top,
          r.right, r.top,
          r.right - d * .16, r.center.dy,
          r.right, r.bottom,
        ]),
        p..color = col,
      );
      c.drawRect(Rect.fromLTRB(r.left + d * .12, r.top, r.right - d * .2, r.top + h * d * .18), p..color = litCol ?? _foreLit);
      c.drawRect(Rect.fromLTRB(r.left + d * .1, r.bottom - h * d * .2, r.right - d * .02, r.bottom), p..color = under ?? _foreShade);
      y -= h * d;
    }

    block(.22, -1.7, 1.0, _foreMarble);
    block(.24, -1.74, 1.04, _foreMarble);
    block(.26, -1.78, 1.08, _foreMarble);
    final fy = y;
    block(.5, -1.72, .96, const Color(0xffdcc9a8), under: _foreDeep, litCol: const Color(0xffefe0c2));
    // Carved frieze: paired garland swags and rosettes.
    final relief = Paint()..color = const Color(0x554a3422);
    for (var i = 0; i < 7; i++) {
      final x = top.dx + (-1.55 + i * .37) * d;
      c.drawPath(
        Path()
          ..moveTo(x, fy - d * .12)
          ..quadraticBezierTo(x + d * .18, fy - d * .38, x + d * .36, fy - d * .12),
        relief
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.6, d * .05),
      );
      c.drawCircle(Offset(x + d * .18, fy - d * .38), d * .05, relief..style = PaintingStyle.fill);
    }
    relief.style = PaintingStyle.fill;
    block(.14, -1.74, .98, _foreMarble);
    final dy = y;
    for (var i = 0; i < 9; i++) {
      c.drawRect(Rect.fromLTWH(top.dx + (-1.62 + i * .3) * d, dy, d * .14, d * .1), p..color = const Color(0x664a3422));
    }
    block(.22, -1.95, 1.2, _foreMarble);
    c.drawRect(Rect.fromLTRB(top.dx - 1.9 * d, y - d * .06, top.dx + 1.14 * d, y), p..color = _foreLit);
  }

  /// A legionary at rest, feet apart, shield grounded on his left and a pilum
  /// on his right. [s] is the height to the crown of the helmet; the crest
  /// itself is animated in [_foreLive].
  static void _legionary(Canvas c, Offset base, double s) {
    final k = s / 100;
    Offset p(double x, double y) => Offset(base.dx + x * k, base.dy - y * k);
    final paint = Paint();
    void poly(List<double> v, Color col) {
      final path = Path()..moveTo(p(v[0], v[1]).dx, p(v[0], v[1]).dy);
      for (var i = 2; i + 1 < v.length; i += 2) {
        path.lineTo(p(v[i], v[i + 1]).dx, p(v[i], v[i + 1]).dy);
      }
      c.drawPath(path..close(), paint..color = col);
    }

    void line(double x0, double y0, double x1, double y1, double w, Color col) {
      c.drawLine(p(x0, y0), p(x1, y1), paint..color = col..strokeWidth = math.max(.5, w * k));
    }

    void oval(double x, double y, double w, double h, Color col) {
      c.drawOval(Rect.fromCenter(center: p(x, y), width: w * k, height: h * k), paint..color = col);
    }

    const skin = Color(0xffcf9464), skinShade = Color(0xffa26c48), skinLit = Color(0xffe0ab7c);
    const red = Color(0xffbf3f2f), redLit = Color(0xffd85a44), redShade = Color(0xff8a2d25);
    const steel = Color(0xffaab2b6), steelLit = Color(0xffdcdcd0), steelShade = Color(0xff6f7a84);
    const bronze = Color(0xffc9a040), bronzeLit = Color(0xffe8c45c), bronzeShade = Color(0xff8a6626);
    const leather = Color(0xff5a3a26);

    // Cloak hanging behind the right shoulder.
    poly([7, 79, 15, 77, 22, 66, 25.5, 50, 22, 38, 17, 42, 13, 55, 9, 68], const Color(0xff6e2a2c));
    poly([15, 77, 22, 66, 25.5, 50, 22, 38, 20.5, 52, 18, 66], const Color(0xff562022));
    line(12, 74, 17, 44, 1.2, const Color(0xff8a3a38));

    // Bare legs and hobnailed boots.
    for (final cx in const [-6.8, 6.6]) {
      poly([cx - 4.8, 34, cx - 4.3, 25, cx - 4.7, 15, cx - 3.1, 6, cx + 3.1, 6, cx + 4.7, 15, cx + 4.3, 25, cx + 4.8, 34], skin);
      poly([cx + 1, 34, cx + 4.8, 34, cx + 4.3, 25, cx + 4.7, 15, cx + 3.1, 6, cx + .9, 6, cx + 1.6, 15, cx + 1.2, 25], skinShade);
      c.drawPath(_foreLens(p(cx - 2.1, 25), p(cx - 2.4, 9), 1.6 * k), paint..color = skinLit);
    }
    poly([-10.2, 7.5, -3.4, 7.5, -2.6, 1.2, -3, 0, -13.2, 0, -13.5, 2.2, -11, 4], leather);
    poly([3.2, 7.5, 10.0, 7.5, 11, 4, 14, 2.2, 13.6, 0, 3.4, 0, 2.6, 1.2], leather);
    for (final (x0, x1) in const [(-10.0, -3.6), (3.4, 10.0)]) {
      for (final yy in const [6.4, 4.8, 3.2]) {
        line(x0, yy, x1, yy, .8, const Color(0xffa9784c));
      }
    }
    line(-13.4, .6, -2.8, .6, 1.2, const Color(0xff2e1c12));
    line(3.2, .6, 13.7, .6, 1.2, const Color(0xff2e1c12));

    // Scarlet tunic with its linen hem, and the studded apron straps.
    poly([-11.5, 58, 11.5, 58, 13.8, 34, 11, 33, 4, 34.6, -4, 33.6, -11, 34.6, -13.8, 34], red);
    poly([1.5, 58, 11.5, 58, 13.8, 34, 11, 33, 4, 34.6, 1, 34], redShade);
    poly([-11.5, 58, -4, 58, -5.5, 34, -13.8, 34], redLit);
    for (final x in const [-6.0, -1.5, 3.5]) {
      line(x, 56, x - .4, 35.6, .7, const Color(0x668a2d25));
    }
    poly([-13.8, 34, 13.8, 34, 13.6, 36.4, -13.6, 36.4], const Color(0xffe6d2ae));
    for (var i = 0; i < 5; i++) {
      final x = -6.4 + i * 3.2;
      final bottom = 42 + 1.5 * Sketch.hash(i + 860);
      poly([x - 1.1, 57, x + 1.1, 57, x + 1, bottom, x - 1, bottom], leather);
      oval(x, bottom - .2, 2.4, 2.2, bronze);
    }

    // Pilum: ash shaft, iron shank and a pyramidal head; the hand grips it.
    line(25.4, 0, 24, 90, 1.7, const Color(0xff7a5a38));
    line(24, 89, 23.4, 118, 1.1, const Color(0xffa7aeb4));
    line(24, 88, 24, 91.5, 2.4, bronze);
    poly([23.4, 124.5, 22.3, 117.5, 24.5, 117.5], steelLit);

    // Segmented armour: overlapping bands, lit on the left, shadowed right.
    poly([-14.5, 78, 14.5, 78, 12.6, 57, -12.6, 57], steel);
    for (var i = 0; i < 6; i++) {
      final y0 = 57.4 + i * 3.45, hwB = 12.7 + i * .34;
      poly([-hwB, y0 + 3.5, hwB, y0 + 3.5, hwB, y0, -hwB, y0], steel);
      poly([-hwB, y0 + 3.5, -hwB * .3, y0 + 3.5, -hwB * .3, y0, -hwB, y0], steelLit);
      poly([hwB * .35, y0 + 3.5, hwB, y0 + 3.5, hwB, y0, hwB * .35, y0], steelShade);
      line(-hwB, y0, hwB, y0, .8, const Color(0xff454d58));
    }
    oval(0, 66, 3.2, 3.6, bronze);
    // Belt with bronze plates.
    poly([-12.9, 58.4, 12.9, 58.4, 12.9, 55.4, -12.9, 55.4], leather);
    for (var i = 0; i < 4; i++) {
      poly([-10.2 + i * 6.8, 58, -7.8 + i * 6.8, 58, -7.8 + i * 6.8, 55.8, -10.2 + i * 6.8, 55.8], i < 2 ? bronzeLit : bronze);
    }

    // Right arm: red sleeve, bare forearm, fist on the pilum.
    poly([14.2, 78, 20.2, 77, 24.2, 63, 19.4, 62], red);
    poly([19, 63, 24.2, 63, 25.6, 55.6, 22.2, 55], skin);
    poly([22.6, 63, 24.2, 63, 25.6, 55.6, 24.2, 55], skinShade);
    oval(24, 54.6, 5.4, 5.2, skin);
    oval(24.9, 54, 2.6, 2.6, skinShade);
    // Left arm behind the shield.
    poly([-14.2, 78, -19.6, 76, -23.4, 66, -18.2, 64.4], redLit);
    poly([-23.4, 66, -18.2, 64.4, -17.8, 60, -22.4, 60.6], skin);

    // Scutum: curved red board with gold edging, boss and winged thunderbolt.
    c.save();
    c.translate(p(-21, 1.5).dx, p(-21, 1.5).dy);
    c.rotate(.05);
    Offset q(double x, double y) => Offset(x * k, -y * k);
    final board = RRect.fromRectAndRadius(Rect.fromPoints(q(-11.2, 0), q(11.2, 62)), Radius.circular(3.6 * k));
    c.drawRRect(
      board,
      Paint()
        ..shader = Gradient.linear(q(-11.2, 0), q(11.2, 0), const [redLit, red, redShade], const [0, .5, 1]),
    );
    c.drawRRect(
      board.deflate(1.3 * k),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, 1.5 * k)
        ..color = const Color(0xffd8a93c),
    );
    final gold = Paint()..color = const Color(0xffe0b446);
    for (final sg in const [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        c.drawPath(_foreLens(q(sg * 3.6, 31.0 + i), q(sg * 9.4, 27.5 + i * 3.6), 1.5 * k), gold);
      }
    }
    final bolt = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, 1.3 * k)
      ..strokeJoin = StrokeJoin.round
      ..color = gold.color;
    c.drawPath(Path()..moveTo(q(0, 36).dx, q(0, 36).dy)..lineTo(q(2, 42).dx, q(2, 42).dy)..lineTo(q(-1.2, 43).dx, q(-1.2, 43).dy)..lineTo(q(1, 53).dx, q(1, 53).dy), bolt);
    c.drawPath(Path()..moveTo(q(0, 27).dx, q(0, 27).dy)..lineTo(q(-2, 21).dx, q(-2, 21).dy)..lineTo(q(1.2, 20).dx, q(1.2, 20).dy)..lineTo(q(-1, 10).dx, q(-1, 10).dy), bolt);
    c.drawCircle(q(0, 31.5), 4.6 * k, Paint()..color = bronzeShade);
    c.drawCircle(q(-.4, 32), 3.9 * k, Paint()..color = bronze);
    c.drawCircle(q(-1.4, 33.2), 1.5 * k, Paint()..color = bronzeLit);
    c.restore();
    // His left hand hooks over the rim.
    oval(-18.6, 61.6, 6.2, 4.4, skin);
    line(-21, 63, -16.4, 63, 1.5, skinLit);

    // Shoulder guards and the gorget round the neck.
    for (final sg in const [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        c.drawPath(
          _foreLens(p(sg * (10.2 + i * 1.8), 79.4 - i * 2.3), p(sg * (18.4 + i * 1.6), 76.6 - i * 2.4), 2.3 * k),
          paint..color = sg < 0 ? (i == 0 ? steelLit : steel) : (i == 0 ? steel : steelShade),
        );
      }
    }
    poly([-5.4, 78, 5.4, 78, 4.4, 80.4, -4.4, 80.4], steel);
    poly([1, 78, 5.4, 78, 4.4, 80.4, 1, 80.4], steelShade);

    // Head: neck, face, cheek pieces and the bronze helmet.
    poly([-2.6, 80, 2.6, 80, 2.9, 83.4, -2.9, 83.4], skinShade);
    oval(0, 87, 10.4, 12.4, skin);
    oval(1.8, 87, 6.8, 12, const Color(0x59a26c48));
    poly([-5.4, 91, -3.6, 88, -3.4, 82.6, -5, 81.4, -6.6, 86], bronze);
    poly([5.4, 91, 3.6, 88, 3.4, 82.6, 5, 81.4, 6.6, 86], bronzeShade);
    oval(-2.1, 87.5, 1.5, 1.5, const Color(0xff33200f));
    oval(2.1, 87.5, 1.5, 1.5, const Color(0xff33200f));
    c.drawPath(_foreLens(p(.2, 86.6), p(.9, 83.8), .9 * k), paint..color = const Color(0x80a26c48));
    line(-1.6, 83.2, 1.6, 83.2, .9, const Color(0xff8a4a3a));
    line(-3.6, 82.8, 0, 81.6, .8, leather);
    line(0, 81.6, 3.6, 82.8, .8, leather);
    final dome = Path()..moveTo(p(-6.8, 91.6).dx, p(-6.8, 91.6).dy);
    dome.arcTo(Rect.fromCenter(center: p(0, 91.6), width: 13.6 * k, height: 17.6 * k), math.pi, math.pi, false);
    c.drawPath(dome..close(), paint..color = bronze);
    c.drawPath(_foreLens(p(-4.8, 92.2), p(-1.4, 99), 2.4 * k), paint..color = bronzeLit);
    c.drawPath(_foreLens(p(4.8, 92.2), p(2.2, 98.4), 2 * k), paint..color = bronzeShade);
    poly([-6.9, 91.8, 6.9, 91.8, 6.9, 89.6, -6.9, 89.6], bronzeShade);
    poly([-4.8, 89.6, 4.8, 89.6, 4.8, 88.6, -4.8, 88.6], const Color(0x66704028));
    poly([-1.6, 99.6, 1.6, 99.6, 1.6, 98.4, -1.6, 98.4], bronzeShade);
  }
}

/// One elliptical ring of the Colosseum seen from outside (see
/// `RomeScene._colosseum`). Pier boundaries are spaced by angle so the arcade
/// turns away at both ends, and cornices bow up a little at the middle as they
/// do when the bowl is seen from below. Heights are in units of [s].
class _ColosseumRing {
  _ColosseumRing(this.base, this.s, this.zp, {required this.outer, this.first = 0, this.seed = 0, this.haze = .2, this.sun = 1}) : n = zp.length - 1;

  static const _thM = 1.22;

  /// Top of each storey (Tuscan, Ionic, Corinthian, attic) and of the crown.
  static const tops = [.072, .15, .228, .294];
  static const crown = .308;

  static double floor(int k) => k == 0 ? 0.0 : tops[k - 1];

  final Offset base;
  final double s, haze, sun;
  final List<double> zp;
  final bool outer;
  final int n, first, seed;

  late final List<double> th = List.generate(n + 1, (j) => -_thM + 2 * _thM * j / n);
  late final List<double> xs = List.generate(n + 1, (j) => base.dx + s * .5 * math.sin(th[j]) / math.sin(_thM));
  late final List<double> bow = List.generate(n + 1, (j) => 1 - .1 * (1 - math.cos(th[j])));

  /// Half width of the pier on boundary j.
  late final List<double> hp = List.generate(n + 1, (j) => .15 * (j == 0 ? bw(0) : (j == n ? bw(n - 1) : (bw(j - 1) + bw(j)) / 2)));

  /// Storeys of arches still standing in each bay.
  late final List<int> arches = List.generate(n, (i) {
    final m = math.min(zp[i], zp[i + 1]);
    var a = 0;
    while (a < 3 && m >= tops[a] - .014) {
      a++;
    }
    return a;
  });

  /// Height of the wall over each bay: the broken arch's parapet, if any.
  late final List<double> cut = List.generate(n, (i) {
    final m = math.min(zp[i], zp[i + 1]);
    final a = arches[i];
    if (a == 3) return math.min(m, crown);
    return math.min(m, a == 0 ? 0.0 : tops[a - 1] + .008);
  });

  double bw(int i) => xs[i + 1] - xs[i];
  double y(double z, int j) => base.dy - z * s * bow[j];
  double ym(double z, int i) => base.dy - z * s * (bow[i] + bow[i + 1]) / 2;

  /// How much sun a face at angle [t] gets, 0..1, light from the upper left.
  double lit(double t) => ((math.cos(t + .7) + .4) / 1.4).clamp(0.0, 1.0);

  Color face(double t) => RomeScene._hazed(Sketch.mix(RomeScene._colosseumShade, RomeScene._colosseumLit, t * sun), haze);

  /// A left-to-right gradient that follows the sun across the curved wall.
  Shader ramp(Color Function(double lit) at) {
    const k = 12;
    final colors = <Color>[], stops = <double>[];
    for (var i = 0; i <= k; i++) {
      final t = -_thM + 2 * _thM * i / k;
      colors.add(at(lit(t)));
      stops.add((math.sin(t) / math.sin(_thM) + 1) / 2);
    }
    return Gradient.linear(Offset(xs[0], 0), Offset(xs[n], 0), colors, stops);
  }
}
