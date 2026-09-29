import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// Antarctica in polar twilight: aurora curtains over a low sun, snowy peaks
/// lit pink along their western faces, a sheer ice shelf with a far research
/// station, icebergs adrift in the dark sea and an emperor penguin colony
/// beside an orange field hut. Snowfall and twinkling snow.
class AntarcticaScene extends RegionScene {
  const AntarcticaScene();

  @override
  WorldRegion get region => WorldRegion.antarctica;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: _auroraSun,
    radius: .048,
    disc: Color(0xfffff3e4),
    glow: Color(0xffffc0a2),
    halo: .7,
    strength: .55,
  );

  static final _weather = Weather(Weather.of([(Mote.snow, 34)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffc3d4ea);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffd9e3f2),
      Color(0xffc7d4ea),
      Color(0xfffff1ea),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xffe9f1fa),
      Color(0xff9dbfdf),
      Color(0xfffff7f3),
      rimWidth: .0036,
    ),
    Depth.low => const Ground(
      Color(0xff41709a),
      Color(0xff2b537c),
      Color(0xffbcd8ee),
      rimWidth: .0025,
    ),
    Depth.near => const Ground(
      Color(0xfff6fafd),
      Color(0xffcfdeee),
      Color(0xffffffff),
      rimWidth: .006,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .655 + Sketch.waves(x, const [(2.2, .004, .3)]),
    // A tabular shelf: level lips broken by sheer jogs and crevasse notches.
    Depth.mid => _shelfEdge(x),
    Depth.low => .785,
    Depth.near =>
      .905 - .022 * Sketch.humps(x / 1.7) - .008 * Sketch.humps(x / .85 + .4),
  };

  /// The shelf repeats its lip profile every [_shelfSpan] viewport heights.
  static const _shelfSpan = 3.0;

  /// Jogs of the calved front: (centre, level change, width). Where the lip
  /// steps back it climbs, since the edge is then further from the eye.
  static const _shelfSteps = [
    (.3, -.012, .045),
    (.98, .018, .045),
    (2.34, -.02, .045),
    (2.7, .01, .045),
    (2.96, .004, .07),
  ];

  /// Crevasse notches cut into the lip: (centre, depth, half width).
  static const _shelfNotches = [
    (.12, .009, .016),
    (2.5, .012, .02),
    (2.84, .008, .014),
  ];

  /// A snow ramp where the shelf slopes down to the sea: (from, to, depth).
  static const _shelfRamp = (.33, .95, .036);

  /// The lip of the ice shelf in viewport heights at world x [u]: long level
  /// stretches, sheer jogs, crevasse notches and a whisper of snow dune. The
  /// research station stands on the level terrace between u = 1.03 and 2.3.
  static double _shelfEdge(double u) {
    final p = u - (u / _shelfSpan).floorToDouble() * _shelfSpan;
    var y = .7;
    for (final (at, dy, width) in _shelfSteps) {
      final k = ((p - at) / width + .5).clamp(0.0, 1.0);
      y += dy * k * k * (3 - 2 * k);
    }
    for (final (at, depth, half) in _shelfNotches) {
      final k = 1 - (p - at).abs() / half;
      if (k > 0) y += depth * k * k;
    }
    final (r0, r1, rd) = _shelfRamp;
    if (p > r0 && p < r1) {
      y += rd * (.5 - .5 * math.cos((p - r0) / (r1 - r0) * math.pi * 2));
    }
    return y +
        .0016 * math.sin(p * 8.3776 + 1) +
        .0009 * math.sin(p * 20.944 + 2);
  }

  @override
  double period(Depth d) => d == Depth.low ? 2.6 : 3.4;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .36,
    Depth.mid => .14,
    Depth.low => .2,
    Depth.near => .16,
  };

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _range(c, w, h);
      case Depth.mid:
        _shelfPlain(c, w, h);
        _station(c, w * .74, h * .032, h);
      case Depth.low:
        _bergField(c, h);
      case Depth.near:
        _colonyBack(c, size);
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.mid:
        _shelfOverlay(c, f, presence);
      case Depth.low:
        _bergWaterDraw(c, f, presence, period(d) * h);
      case Depth.near:
        // The colony and the field hut stand on the snow, in front of the
        // ridge line, so the sea never shows behind their feet.
        _colonyOverlay(c, f, presence);
      case Depth.far:
        break;
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    // Twilight glow, sun halo and nacreous clouds never move: they are
    // recorded once per viewport and fade level, then replayed. Only the
    // stars and the curtains are painted afresh each frame.
    final level = (presence * _auroraLevels).round();
    if (level > 0) c.drawPicture(_auroraBackdrop(f.size, false, level));
    _auroraStars(c, f, presence);
    _auroraCurtains(c, f, presence);
    // Nacreous clouds hang far below the aurora, so they veil it.
    if (level > 0) c.drawPicture(_auroraBackdrop(f.size, true, level));
  }

  /// Steps of the crossing fade for the recorded sky pictures.
  static const _auroraLevels = 24;

  /// Where the low sun stands, as fractions of the viewport.
  static const _auroraSun = Offset(.2, .6);

  static const _auroraDeep = Color(0xff0a2050);

  /// Curtain palettes, bottom to top: (height along the ray as a fraction of
  /// the curtain, colour, alpha). A pink fringe hangs under a crisp pale hem;
  /// the ray then runs green -> teal -> blue -> violet and fades out.
  static const _auroraEmerald = [
    (-.09, Color(0xffff6fc8), .075),
    (-.02, Color(0xffb8ffa0), .045),
    (0.0, Color(0xffd2ffc4), .44),
    (.05, Color(0xff9cffae), .4),
    (.16, Color(0xff54f5a2), .35),
    (.34, Color(0xff34dcc0), .23),
    (.58, Color(0xff5aa0f0), .1),
    (.82, Color(0xff9b72f2), .05),
    (1.0, Color(0xffb07cff), 0.0),
  ];
  static const _auroraCyan = [
    (-.08, Color(0xff9fe0ff), .03),
    (-.02, Color(0xff9fe0ff), .015),
    (0.0, Color(0xffbdf5ff), .26),
    (.05, Color(0xff9ceeff), .24),
    (.16, Color(0xff7fe6ff), .18),
    (.36, Color(0xff5fb8f5), .11),
    (.6, Color(0xff7f8cf5), .08),
    (.84, Color(0xffa57cf0), .04),
    (1.0, Color(0xffb99cff), 0.0),
  ];
  static const _auroraRose = [
    (-.08, Color(0xffff9ad0), .02),
    (-.02, Color(0xffff9ad0), .012),
    (0.0, Color(0xffffb8e6), .2),
    (.05, Color(0xffffa4e6), .18),
    (.16, Color(0xfff58ae0), .15),
    (.36, Color(0xffd66ef0), .1),
    (.6, Color(0xffa76cf5), .07),
    (.84, Color(0xff8a7cf5), .04),
    (1.0, Color(0xff8a7cf5), 0.0),
  ];

  /// Curtains back to front: (hem height, span, palette, drift speed, seed,
  /// lowest patchiness, ray lean, column width, gain). Narrow columns resolve
  /// the fine streaks of the two nearest curtains.
  static const _auroraCurtainSpecs = [
    (.2, .2, _auroraRose, .1, 5.0, .0, .16, .02, 1.0),
    (.155, .17, _auroraCyan, -.14, 2.0, .25, .12, .02, 1.0),
    (.27, .26, _auroraEmerald, .2, 0.0, .55, .1, .012, 1.0),
    (.35, .1, _auroraEmerald, -.11, 8.0, .0, .07, .02, .6),
  ];

  static final _auroraRgb = {
    for (final palette in const [_auroraRose, _auroraCyan, _auroraEmerald])
      palette: [for (final row in palette) row.$2.toARGB32() & 0xffffff],
  };

  /// How far each palette row leaves the hem's unbroken glow for the rays.
  static final _auroraMix = {
    for (final palette in const [_auroraRose, _auroraCyan, _auroraEmerald])
      palette: [for (final row in palette) _auroraSmooth(row.$1, 0, .4)],
  };

  static const _auroraMaxCols = 320;
  static const _auroraRows = 9;
  static final _auroraPos = Float32List(_auroraMaxCols * _auroraRows * 2);
  static final _auroraCol = Int32List(_auroraMaxCols * _auroraRows);
  static final _auroraIdx = () {
    final idx = Uint16List((_auroraMaxCols - 1) * (_auroraRows - 1) * 6);
    var k = 0;
    for (var i = 0; i < _auroraMaxCols - 1; i++) {
      for (var r = 0; r < _auroraRows - 1; r++) {
        final a = i * _auroraRows + r;
        final b = a + _auroraRows;
        idx[k++] = a;
        idx[k++] = b;
        idx[k++] = b + 1;
        idx[k++] = a;
        idx[k++] = b + 1;
        idx[k++] = a + 1;
      }
    }
    return idx;
  }();
  static final _auroraPaint = Paint()..blendMode = BlendMode.plus;

  /// Aurora curtains as gouraud meshes: one column of vertices per ray, with
  /// the colour and alpha of each vertex set from the palette, so a curtain
  /// and all its rays cost one draw call.
  static void _auroraCurtains(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    for (final (y0, span, palette, speed, seed, patch, lean, cell, gain) in _auroraCurtainSpecs) {
      final step = h * cell;
      final cols = math.min(_auroraMaxCols, ((w + h * .6) / step).ceil() + 1);
      final fine = cell < .015 ? .16 : 0.0;
      final rgb = _auroraRgb[palette]!, mix = _auroraMix[palette]!;
      final drift = t * speed;
      final sway = h * .03 * math.sin(drift * 1.5 + seed) / w;
      var k = 0;
      for (var i = 0; i < cols; i++) {
        final x = -h * .3 + i * step;
        final u = x / h;
        // The hem folds in long S-bends; where the curtain turns face-on
        // (a steep hem) it stands taller and burns brighter.
        final p1 = u * 1.5 + drift * 2 + seed;
        final p2 = u * 3.9 - drift * 3 + seed * 1.7;
        final p3 = u * 9.7 + drift * 4 + seed * .3;
        final hem = h * (y0 + .055 * math.sin(p1) + .024 * math.sin(p2) + .006 * math.sin(p3));
        final slope = .055 * 1.5 * math.cos(p1) + .024 * 3.9 * math.cos(p2);
        final face = math.min(1.0, slope.abs() * 5);
        // Patches of the arc glow brighter than others.
        final env =
            patch +
            (1 - patch) *
                _auroraSmooth(.5 + .5 * math.sin(u * 1.1 + seed * 2.3 + drift * .9), .2, .8);
        // Ray brightness: beating stripes that drift along the curtain.
        final ray =
            (.5 - fine * .5) * (.5 + .5 * math.sin(u * 23 + drift * 4 + seed * 3)) +
            (.3 - fine * .3) * (.5 + .5 * math.sin(u * 57 - drift * 3 + seed)) +
            .2 * (.5 + .5 * math.sin(u * 9.3 - drift * 2 + seed * 5)) +
            fine * (.5 + .5 * math.sin(u * 101 + drift * 5 + seed * 2));
        // The hem burns as one unbroken line; the rays above it come and go.
        final sharp = _auroraSmooth(ray, .38, .82);
        final pulse = .88 + .12 * math.sin(t * .5 + u * 1.3 + seed);
        final bRay = pulse * env * (.08 + .92 * sharp) * (.7 + .6 * face);
        final bHem = pulse * env * (.5 + .5 * sharp) * (.75 + .45 * face);
        final lift = (.5 + .35 * ray + .35 * face) * span * h;
        final lean1 = (x - w * .5) * (lean * (.55 + .45 * ray) + sway);
        final gain1 = gain * presence * 255;
        for (var r = 0; r < _auroraRows; r++) {
          final (tr, _, alpha) = palette[r];
          _auroraPos[k * 2] = x + lean1 * tr;
          _auroraPos[k * 2 + 1] = hem - tr * lift;
          final b = bHem + (bRay - bHem) * mix[r];
          final a = (alpha * gain1 * (b < 1.2 ? b : 1.2)).toInt();
          _auroraCol[k] = ((a < 255 ? a : 255) << 24) | rgb[r];
          k++;
        }
      }
      final mesh = Vertices.raw(
        VertexMode.triangles,
        Float32List.sublistView(_auroraPos, 0, k * 2),
        colors: Int32List.sublistView(_auroraCol, 0, k),
        indices: Uint16List.sublistView(_auroraIdx, 0, (cols - 1) * (_auroraRows - 1) * 6),
      );
      c.drawVertices(mesh, BlendMode.src, _auroraPaint);
      mesh.dispose();
    }
  }

  static double _auroraSmooth(double v, double a, double b) {
    final k = ((v - a) / (b - a)).clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }

  static final _auroraStarCache = <Size, List<Float32List>>{};

  /// Star positions for a viewport, in six batches: three twinkle phases,
  /// each split into bright (high) and dim (near the glow) stars.
  static List<Float32List> _auroraStarPoints(Size size) {
    final hit = _auroraStarCache[size];
    if (hit != null) return hit;
    const n = 90;
    final groups = List.generate(6, (_) => <double>[]);
    for (var i = 0; i < n; i++) {
      final x = size.width * Sketch.hash(i + 200);
      final y = size.height * (.012 + .44 * math.pow(Sketch.hash(i + 300), 1.35));
      groups[i % 3 + (y > size.height * .26 ? 3 : 0)].addAll([x, y]);
    }
    if (_auroraStarCache.length > 4) {
      _auroraStarCache.remove(_auroraStarCache.keys.first);
    }
    return _auroraStarCache[size] = [
      for (final g in groups) Float32List.fromList(g),
    ];
  }

  static void _auroraStars(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .005;
    final batches = _auroraStarPoints(f.size);
    for (var g = 0; g < batches.length; g++) {
      final dim = g >= 3;
      final twinkle = .6 + .4 * math.sin(f.clock * (1.5 + g * .23) + g * 2.1);
      paint
        ..strokeWidth = h * (dim ? .0032 : .0046)
        ..color = Sketch.fade(
          const Color(0xfff2f6ff),
          (dim ? .5 : .82) * twinkle * presence,
        );
      c.drawRawPoints(PointMode.points, batches[g], paint);
    }
    // A few bright stars glint with a four-point sparkle.
    paint.strokeWidth = math.max(.7, h * .0018);
    for (var i = 0; i < _auroraGlints.length; i++) {
      final (x, y, r) = _auroraGlints[i];
      final on = .5 + .5 * math.sin(f.clock * 1.3 + i * 2.2);
      final at = Offset(f.w * x, h * y);
      final reach = h * r * (.6 + .4 * on);
      paint.color = Sketch.fade(const Color(0xffeaf1ff), (.26 + .26 * on) * presence);
      c.drawLine(at - Offset(reach, 0), at + Offset(reach, 0), paint);
      c.drawLine(at - Offset(0, reach), at + Offset(0, reach), paint);
      paint.color = Sketch.fade(const Color(0xfffafcff), .95 * presence);
      c.drawCircle(at, h * .0032, paint);
    }
  }

  /// Bright stars: (x fraction, y fraction, glint reach in heights).
  static const _auroraGlints = [
    (.09, .06, .022),
    (.36, .04, .016),
    (.58, .1, .02),
    (.73, .05, .015),
    (.985, .2, .014),
  ];

  static final _auroraPictures = <(Size, bool, int), Picture>{};

  static Picture _auroraBackdrop(Size size, bool clouds, int level) {
    final key = (size, clouds, level);
    final hit = _auroraPictures.remove(key);
    if (hit != null) return _auroraPictures[key] = hit;
    final recorder = PictureRecorder();
    final a = level / _auroraLevels;
    if (clouds) {
      _auroraClouds(Canvas(recorder), size, a);
    } else {
      _auroraGlow(Canvas(recorder), size, a);
    }
    final picture = recorder.endRecording();
    _auroraPictures[key] = picture;
    if (_auroraPictures.length > 120) {
      _auroraPictures.remove(_auroraPictures.keys.first)!.dispose();
    }
    return picture;
  }

  /// The still sky: deep indigo overhead, twilight belts, the low sun's glow,
  /// pillar and halo, a Southern Cross and stacked nacreous clouds.
  static void _auroraGlow(Canvas c, Size size, double a) {
    final w = size.width, h = size.height;
    final sun = Offset(w * _auroraSun.dx, h * _auroraSun.dy);
    Color k(Color color, double alpha) => Sketch.fade(color, alpha * a);
    // A deep indigo night sky overhead makes the aurora glow.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h * .66),
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, h * .66), [
          k(_auroraDeep, .66),
          k(_auroraDeep, .62),
          k(_auroraDeep, .38),
          k(_auroraDeep, .08),
          k(_auroraDeep, 0),
        ], const [0, .3, .55, .8, 1]),
    );
    // The curtains light the sky around them a little green.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(w * .5, h * .28), width: w * 1.3, height: h * .3),
      const Color(0xff2fd6a0),
      .06 * a,
    );
    // A violet twilight arch between the night and the glow of the horizon.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(w * .5, h * .42), width: w * 1.8, height: h * .34),
      const Color(0xffa070e0),
      .27 * a,
    );
    // A rose belt hugging the horizon.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(w * .55, h * .6), width: w * 1.8, height: h * .14),
      const Color(0xffff9db4),
      .16 * a,
    );
    // Earth's shadow rising opposite the sun, with a pink belt above it.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(w * .86, h * .63), width: w * 1.25, height: h * .34),
      const Color(0xff5c72b4),
      .34 * a,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(w * .82, h * .5), width: w * 1.4, height: h * .2),
      const Color(0xffffa2b4),
      .16 * a,
    );
    // The sun's own glow: a long horizon streak and two warm lobes.
    Sketch.mist(
      c,
      Rect.fromCenter(center: sun, width: h * 2.6, height: h * .16),
      const Color(0xffffc2a4),
      .3 * a,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: sun, width: h * 1.2, height: h * .42),
      const Color(0xffffb08e),
      .3 * a,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: sun, width: h * .5, height: h * .2),
      const Color(0xffffe2bc),
      .38 * a,
    );
    // A sun pillar standing on the sun.
    Sketch.mist(
      c,
      Rect.fromCenter(center: sun - Offset(0, h * .16), width: h * .07, height: h * .5),
      const Color(0xffffe4d2),
      .2 * a,
    );
    // The 22 degree halo: red inside, pale, then blue outside.
    final ring = h * .34;
    c.drawCircle(
      sun,
      ring,
      Paint()
        ..shader = Gradient.radial(
          sun,
          ring,
          [
            k(const Color(0xffffa090), 0),
            k(const Color(0xffffa090), 0),
            k(const Color(0xffffa090), .13),
            k(const Color(0xffffffff), .1),
            k(const Color(0xffa8c8ff), .05),
            k(const Color(0xffa8c8ff), 0),
          ],
          const [0, .86, .91, .95, .985, 1],
        ),
    );
    // Sun dogs on the halo, at the sun's height.
    for (final side in const [-1.0, 1.0]) {
      final dog = Offset(sun.dx + side * ring * .95, sun.dy - h * .012);
      Sketch.mist(
        c,
        Rect.fromCenter(center: dog, width: h * .1, height: h * .06),
        const Color(0xffffd6b4),
        .5 * a,
      );
      Sketch.mist(
        c,
        Rect.fromCenter(center: dog + Offset(side * h * .05, 0), width: h * .14, height: h * .012),
        const Color(0xffb6d2ff),
        .3 * a,
      );
    }
    _auroraCross(c, Offset(w * .9, h * .1), h * .03, a);
  }

  /// Nacreous clouds: mother-of-pearl lens stacks, pink where the sun lights them.
  static void _auroraClouds(Canvas c, Size size, double a) {
    final w = size.width, h = size.height;
    _auroraLens(c, Offset(w * .8, h * .45), h * .26, h * .03, -.03, a * .85, 0, 4);
    _auroraLens(c, Offset(w * .3, h * .385), h * .18, h * .02, .05, a * .8, 1, 2);
  }

  /// The Southern Cross with its two pointer stars.
  static void _auroraCross(Canvas c, Offset at, double s, double a) {
    final glow = Paint()
      ..shader = Gradient.radial(
        Offset.zero,
        1,
        [
          Sketch.fade(const Color(0xffd8e6ff), .5 * a),
          Sketch.fade(const Color(0xffd8e6ff), .12 * a),
          Sketch.fade(const Color(0xffd8e6ff), 0),
        ],
        const [0, .35, 1],
      );
    final core = Paint()..color = Sketch.fade(const Color(0xfff8fbff), .95 * a);
    for (final (x, y, r) in const [
      (0.0, -1.0, 1.0),
      (.12, 1.05, 1.15),
      (-.75, .28, .85),
      (.62, -.15, .75),
      (.42, .42, .4),
      (-2.5, 1.7, 1.1),
      (-3.7, 1.6, 1.25),
    ]) {
      final p = at + Offset(x * s, y * s);
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(s * .42 * r);
      c.drawCircle(Offset.zero, 1, glow);
      c.restore();
      c.drawCircle(p, s * .09 * r, core);
    }
  }

  /// A lens-shaped nacreous cloud: a stack of staggered, feather-edged plates,
  /// cool lilac on top and lit pink underneath, with mother-of-pearl colour
  /// shifting along their length.
  static void _auroraLens(Canvas c, Offset at, double rx, double ry, double tilt, double a, int seed, int plates) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    for (var i = 0; i < plates; i++) {
      final wr = rx * (1 - i * .19) * (.94 + .12 * Sketch.hash(seed * 9 + i));
      final r = ry * (1 - i * .08);
      final y = -i * ry * .8;
      final x = rx * (.07 * i - .06) * (seed.isEven ? 1 : -1);
      // A tall dome over a nearly flat belly, tapering into long tips.
      Path lens(double grow) => Path()
        ..moveTo(x - wr * grow, y)
        ..cubicTo(x - wr * .5, y - r * 1.7 * grow, x + wr * .45, y - r * 1.62 * grow, x + wr * grow, y)
        ..cubicTo(x + wr * .5, y + r * .78 * grow, x - wr * .55, y + r * .82 * grow, x - wr * grow, y)
        ..close();
      final pearl = [
        const Color(0xffd6f4e8),
        const Color(0xffdcd8ff),
        const Color(0xffcfe8ff),
        const Color(0xffe8f6e0),
      ][(i + seed) % 4];
      // Feathered edge: two wider, fainter copies.
      final soft = Paint();
      for (final (grow, alpha) in const [(1.16, .05), (1.07, .07)]) {
        c.drawPath(lens(grow), soft..color = Sketch.fade(pearl, alpha * a));
      }
      c.drawPath(
        lens(1),
        Paint()
          ..shader = Gradient.linear(
            Offset(x, y - r * 1.35),
            Offset(x, y + r * .8),
            [
              Sketch.fade(const Color(0xffb4b8ff), .24 * a),
              Sketch.fade(pearl, .3 * a),
              Sketch.fade(const Color(0xffffb8a6), .46 * a),
            ],
            const [0, .6, 1],
          ),
      );
    }
    c.restore();
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    _bergSun(c, f, presence);
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  // -- range: the far band's mountains -----------------------------------------

  /// Colours of one depth layer of the range; [t] is how hazed it is.
  static ({
    Color lit,
    Color litLow,
    Color litRock,
    Color shade,
    Color shadeLow,
    Color shadeRock,
    Color ice,
    Color iceShade,
    Color rim,
  })
  _rangeTone(double t, [double warm = 0]) => (
    lit: _hazed(Sketch.mix(const Color(0xffffdfd2), const Color(0xffffcfb2), warm), t),
    litLow: _hazed(Sketch.mix(const Color(0xffeed3e6), const Color(0xffefc7cf), warm), t),
    litRock: _hazed(const Color(0xffc2a0b8), t),
    shade: _hazed(const Color(0xff9dadd8), t),
    shadeLow: _hazed(const Color(0xffb3bfe3), t),
    shadeRock: _hazed(const Color(0xff6f7aac), t),
    ice: _hazed(const Color(0xfff4f8fd), t),
    iceShade: _hazed(const Color(0xffbcd5f0), t),
    rim: _hazed(Sketch.mix(const Color(0xfffff1e6), const Color(0xffffe2c8), warm), t * .6),
  );

  static Path _rangePath(Iterable<Offset> pts) {
    final it = pts.iterator..moveNext();
    final path = Path()..moveTo(it.current.dx, it.current.dy);
    while (it.moveNext()) {
      path.lineTo(it.current.dx, it.current.dy);
    }
    return path..close();
  }

  /// One flank of a peak, summit excluded: (x, y) points whose reach grows with
  /// depth below the summit (a concave, horn-like profile), broken by ledges
  /// and the odd gendarme. [side] is -1 for the left flank and 1 for the right.
  static List<Offset> _rangeEdge(
    double ax,
    double ay,
    double baseY,
    double reach,
    double q,
    int seed,
    double side,
    double rough,
  ) {
    const ts = [.03, .06, .1, .15, .21, .28, .36, .45, .55, .66, .77, .88, 1.0];
    final hh = baseY - ay;
    final pts = <Offset>[];
    var d = 0.0;
    for (var i = 0; i < ts.length; i++) {
      double r(int k) => Sketch.hash(seed * 97 + i * 5 + k);
      final t = i == ts.length - 1 ? 1.0 : ts[i] + (r(0) - .5) * .02;
      final y = ay + hh * t;
      final want = reach * math.pow(t, q) * (1 + rough * .3 * (r(1) - .5));
      final prev = d;
      d = math.max(prev + reach * .004, want);
      if (i > 1 && i < 10 && r(2) > .82 && rough > .5) {
        // A gendarme: the ridge climbs onto a small tower and drops again.
        pts.add(Offset(ax + side * (prev + reach * .045), y - hh * .028));
        d = math.max(d, prev + reach * .09);
      } else if (i > 2 && i < 10 && r(3) > .84 && rough > .5) {
        // A shoulder: the flank eases off for a moment.
        pts.add(Offset(ax + side * d, y));
        d += reach * (.03 + .05 * r(4));
        pts.add(Offset(ax + side * d, y + hh * .02));
        continue;
      }
      pts.add(Offset(ax + side * d, y));
    }
    return pts;
  }

  /// The arete between a peak's lit and shaded faces, summit excluded, ending
  /// on the base line. It leans toward the lee side and zigzags.
  static List<Offset> _rangeArete(
    double ax,
    double ay,
    double baseY,
    double reach,
    double lee,
    int seed,
  ) {
    final hh = baseY - ay;
    final e = .02 + .16 * Sketch.hash(seed * 3 + 1);
    final pts = <Offset>[];
    const n = 11;
    for (var i = 1; i <= n; i++) {
      final t = math.pow(i / n, 1.15).toDouble();
      final jog = (Sketch.hash(seed * 41 + i) - .5) * reach * .16;
      final x =
          ax + lee * reach * e * t + (i == n ? 0 : jog * math.min(1, t * 4));
      pts.add(Offset(x, ay + hh * t));
    }
    return pts;
  }

  /// Breaks the straight runs of a flank into small crags: most segments gain
  /// a point knocked sideways by up to [amp].
  static List<Offset> _rangeRough(
    Offset from,
    List<Offset> pts,
    double amp,
    int seed,
  ) {
    final out = <Offset>[];
    var prev = from;
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i], seg = p - prev;
      final r = Sketch.hash(seed * 7 + i);
      if (seg.distance > amp * 1.5 && r > .25) {
        final n = Offset(-seg.dy, seg.dx) / seg.distance;
        final k = Sketch.hash(seed * 5 + i);
        out.add(Offset.lerp(prev, p, .3 + .4 * k)! + n * amp * (r - .55) * 2);
      }
      out.add(p);
      prev = p;
    }
    return out;
  }

  /// A jagged belt of layered rock across a face from [a] to [b], with a few
  /// tilted bedding lines through it.
  static void _rangeBelt(
    Canvas c,
    double h,
    Offset a,
    Offset b,
    double thick,
    int seed,
    Color rock,
    Color strata,
  ) {
    const n = 8;
    final top = <Offset>[], bottom = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = i / n;
      final p = Offset.lerp(a, b, u)!;
      final env = .55 + .45 * math.sin(math.pi * u);
      final j1 = Sketch.hash(seed * 17 + i), j2 = Sketch.hash(seed * 19 + i);
      top.add(p + Offset(0, -thick * (.15 + .5 * j1) * env));
      bottom.add(p + Offset(0, thick * (.5 + .8 * j2) * env));
    }
    c.drawPath(_rangePath([...top, ...bottom.reversed]), Paint()..color = rock);
    // Bedding planes follow the belt's own contour.
    final beds = Path();
    for (var k = 1; k <= 2; k++) {
      final f = .2 + .3 * k;
      for (var i = 0; i <= n; i++) {
        final p = Offset.lerp(top[i], bottom[i], f)!;
        if (i == 0) {
          beds.moveTo(p.dx, p.dy);
        } else {
          beds.lineTo(p.dx, p.dy);
        }
      }
    }
    c.drawPath(
      beds,
      Paint()
        ..color = strata
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(.6, h * .0024),
    );
  }

  /// A jagged spine of rock running down the fall line, pointed at both ends.
  static void _rangeRib(
    Canvas c,
    Offset from,
    Offset to,
    double width,
    int seed,
    Color rock,
  ) {
    const n = 7;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = i / n;
      final p = Offset.lerp(from, to, u)!;
      final env = math.pow(math.sin(math.pi * u), .6).toDouble();
      final j1 = Sketch.hash(seed * 13 + i), j2 = Sketch.hash(seed * 11 + i);
      left.add(p + Offset(-width * env * (.35 + .9 * j1), 0));
      right.add(p + Offset(width * env * (.35 + .9 * j2), 0));
    }
    c.drawPath(_rangePath([...left, ...right.reversed]), Paint()..color = rock);
  }

  /// Lens-shaped snow gullies fanning down a face from near the summit.
  static void _rangeFlutes(
    Canvas c,
    double h,
    Offset apex,
    double x0,
    double x1,
    double baseY,
    int count,
    int seed,
    Color color,
  ) {
    final paint = Paint()..color = color;
    for (var k = 0; k < count; k++) {
      final r1 = Sketch.hash(seed * 7 + k);
      final r2 = Sketch.hash(seed * 11 + k);
      final r3 = Sketch.hash(seed * 13 + k);
      final u = (k + .5 + (r1 - .5) * .7) / count;
      final foot = Offset(x0 + (x1 - x0) * u, baseY);
      final s0 = .07 + .3 * r2, s1 = math.min(1.0, s0 + .28 + .4 * r3);
      final p0 = Offset.lerp(apex, foot, s0)!;
      final p1 = Offset.lerp(apex, foot, s1)!;
      final pm = Offset.lerp(p0, p1, .6)!;
      final wd = h * (.004 + .01 * r1);
      c.drawPath(
        Sketch.poly([
          p0.dx, p0.dy, pm.dx + wd, pm.dy, p1.dx, p1.dy, pm.dx - wd, pm.dy, //
        ]),
        paint,
      );
    }
  }

  /// A wind-built cornice: a small overhanging lip of snow on the right-hand
  /// flank just under a crest, with a shadow curled beneath it.
  static void _rangeCornice(
    Canvas c,
    double h,
    List<Offset> flank,
    Color snow,
    Color under,
  ) {
    final a = flank[0], b = flank[1];
    final w = h * .0075;
    Path lip(double sag) => Path()
      ..moveTo(a.dx - w * .2, a.dy - h * .001)
      ..quadraticBezierTo(
        a.dx + w * .9,
        a.dy - w * .1,
        b.dx + w * 1.25,
        b.dy + w * .3,
      )
      ..quadraticBezierTo(
        b.dx + w * 1.3,
        b.dy + w * sag,
        b.dx + w * .3,
        b.dy + w * (sag + .3),
      )
      ..lineTo(a.dx - w * .2, a.dy + w * 1.2)
      ..close();
    c.drawPath(lip(1.7), Paint()..color = under);
    c.drawPath(lip(.75), Paint()..color = snow);
  }

  /// A hanging glacier: a snow-blue tongue narrowing upward and ending in a
  /// serrated lip of seracs over a dark cliff, with a couple of crevasses.
  static void _rangeIce(
    Canvas c,
    double h,
    Offset at,
    double w,
    double ht,
    int seed,
    Color ice,
    Color? iceShade,
    Color cliff,
  ) {
    final blocks = math.max(3, (w / (h * .011)).round());
    final bw = w / blocks, left = at.dx - w / 2;
    Path tongue(double dy) {
      final top = at.dy - ht * .5 + dy;
      final path = Path()
        ..moveTo(at.dx - w * .07, top)
        ..lineTo(at.dx + w * .1, top + ht * .01)
        ..lineTo(at.dx + w * .3, at.dy - ht * .12 + dy)
        ..lineTo(left + w, at.dy + ht * .08 + dy);
      for (var i = blocks - 1; i >= 0; i--) {
        final yb = at.dy + ht * (.5 + .5 * Sketch.hash(seed * 19 + i)) + dy;
        path
          ..lineTo(left + bw * (i + 1), yb)
          ..lineTo(left + bw * i + bw * .15, yb + ht * .05 * (i.isEven ? 1 : -.4));
      }
      return path
        ..lineTo(left, at.dy + ht * .12 + dy)
        ..lineTo(at.dx - w * .3, at.dy - ht * .15 + dy)
        ..close();
    }

    // Ice that has broken off fans out below the lip.
    final lipY = at.dy + ht * .95;
    c.drawPath(
      Sketch.poly([
        at.dx - w * .25, lipY, at.dx + w * .25, lipY, at.dx + w * .7, lipY + ht * .8, at.dx - w * .7, lipY + ht * .8, //
      ]),
      Paint()..color = Sketch.fade(ice, .45),
    );
    c.drawPath(tongue(h * .009), Paint()..color = cliff);
    c.drawPath(tongue(0), Paint()..color = ice);
    if (iceShade == null) return;
    final crevasse = Paint()
      ..color = iceShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, h * .0018);
    for (var i = 1; i < 4; i += 2) {
      final x = left + w * (i / 4 + (Sketch.hash(seed + i) - .5) * .1);
      c.drawLine(
        Offset(x, at.dy - ht * .1),
        Offset(x + w * .04, at.dy + ht * .5),
        crevasse,
      );
    }
  }

  /// Streamers of spindrift blown off a summit on the wind.
  static void _rangePlume(
    Canvas c,
    Offset root,
    double len,
    double thick,
    Color color,
    double alpha,
  ) {
    for (var k = 0; k < 3; k++) {
      final l = len * (1 - k * .24), th = thick * (1 - k * .15);
      final at = root + Offset(0, (k - .5) * thick * .9);
      final path = Path()
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo(
          at.dx + l * .45,
          at.dy - l * .16 - th,
          at.dx + l,
          at.dy - l * .05,
        )
        ..quadraticBezierTo(
          at.dx + l * .5,
          at.dy - l * .08 + th * .5,
          at.dx,
          at.dy + th * .3,
        )
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = Gradient.linear(
            at,
            at + Offset(l, 0),
            [
              Sketch.fade(color, alpha * (1 - k * .15)),
              Sketch.fade(color, alpha * .55),
              Sketch.fade(color, 0),
            ],
            const [0, .5, 1],
          ),
      );
    }
  }

  /// A row of tiny, very distant peaks, all haze and hardly any detail.
  static void _rangeFarRidge(
    Canvas c,
    double w,
    double h, {
    required double top,
    required double amp,
    required double haze,
    required int seed,
  }) {
    final tone = _rangeTone(haze);
    final base = h * .7, sunX = w * .2;
    final body = <Offset>[Offset(-h * .3, base)];
    final lit = Path();
    var x = -h * .3, i = 0;
    var valley = Offset(x, top * h);
    body.add(valley);
    while (x < w + h * 1.0) {
      final r = Sketch.hash(seed * 61 + i), r2 = Sketch.hash(seed * 67 + i);
      x += h * (.03 + .05 * r);
      // The range dips low where the sun sets behind it.
      final dip = 1 - .75 * math.exp(-math.pow((x - sunX) / (h * .22), 2));
      final apex = Offset(x, (top - amp * math.pow(r2, 1.6) * dip) * h);
      body.add(apex);
      final sun = x > sunX ? -1.0 : 1.0;
      lit
        ..moveTo(valley.dx, valley.dy)
        ..lineTo(apex.dx, apex.dy)
        ..lineTo(
          apex.dx - sun * (x - valley.dx) * .15,
          apex.dy + (valley.dy - apex.dy) * .9,
        )
        ..close();
      x += h * (.015 + .035 * Sketch.hash(seed * 71 + i));
      valley = Offset(x, (top + amp * .25 * Sketch.hash(seed * 73 + i)) * h);
      body.add(valley);
      i++;
    }
    body.add(Offset(x, base));
    c.drawPath(_rangePath(body), Paint()..color = tone.shade);
    c.drawPath(lit, Paint()..color = tone.lit);
  }

  /// A mist bank that lets the peaks melt into the snow plain below them.
  static void _rangeMist(
    Canvas c,
    double w,
    double h,
    double y0,
    double y1,
    double alpha,
  ) {
    const mist = Color(0xffe0e3f2);
    c.drawRect(
      Rect.fromLTRB(-h, y0, w + h * 2, y1),
      Paint()
        ..shader = Gradient.linear(Offset(0, y0), Offset(0, y1), [
          Sketch.fade(mist, 0),
          Sketch.fade(mist, alpha),
        ]),
    );
  }

  /// A flat-topped table mountain of the Transantarctic kind: a dark dolerite
  /// cap over pale layered sandstone, benches, a small butte, snow-filled
  /// gullies and a snow skirt at its foot.
  static void _rangeMesa(
    Canvas c,
    double h, {
    required double x,
    required double top,
    required double half,
    required int seed,
    required double haze,
  }) {
    final tone = _rangeTone(haze);
    final ay = top * h, baseY = h * .7, hh = baseY - ay, hw = half * h;
    double r(int k) => Sketch.hash(seed * 43 + k);
    Offset p(double dx, double t) => Offset(x + dx * hw, ay + hh * t);
    final left = [
      p(-2.0, 1.0),
      p(-1.62, .84),
      p(-1.4, .72),
      p(-1.35 - .03 * r(1), .58),
      p(-1.3, .46),
      p(-1.14, .43),
      p(-1.1 - .02 * r(2), .26),
      p(-1.05, .09),
      p(-1.0, .0),
    ];
    final topLine = [
      p(-.93, -.02),
      p(-.72, -.012),
      p(-.5, .006),
      p(-.28, -.008),
      p(-.08, -.024),
      p(.16, -.012),
      p(.34, .004),
      p(.47, -.012),
      p(.5, -.1),
      p(.7, -.11),
      p(.74, -.03),
      p(.88, -.01),
    ];
    final right = [
      p(1.0, .02),
      p(1.05, .2),
      p(1.11 + .03 * r(3), .4),
      p(1.3, .44),
      p(1.35, .6),
      p(1.44, .72),
      p(1.7, .85),
      p(2.05, 1.0),
    ];
    final shell = _rangePath([...left, ...topLine, ...right]);
    c.drawPath(
      shell,
      Paint()..color = Sketch.mix(tone.shadeRock, tone.shade, .4),
    );
    c.save();
    c.clipPath(shell);
    final box = Rect.fromLTRB(x - hw * 2.1, ay - hh * .15, x + hw * 2.1, baseY);
    // Dolerite cap and paler sandstone beneath it, then a dark sill.
    c.drawRect(
      Rect.fromLTRB(box.left, box.top, box.right, ay + hh * .13),
      Paint()..color = Sketch.mix(tone.shadeRock, const Color(0xff3a4374), .45),
    );
    c.drawRect(
      Rect.fromLTRB(box.left, ay + hh * .13, box.right, ay + hh * .36),
      Paint()..color = Sketch.mix(tone.litRock, tone.shade, .5),
    );
    c.drawRect(
      Rect.fromLTRB(box.left, ay + hh * .36, box.right, ay + hh * .41),
      Paint()..color = Sketch.mix(tone.shadeRock, const Color(0xff3a4374), .3),
    );
    // Columnar joints down the cap and snow-filled gullies down the cliffs.
    final joint = Paint()
      ..color = Sketch.fade(const Color(0xff2f3766), .3)
      ..strokeWidth = math.max(.6, h * .0014);
    for (var i = 0; i < 12; i++) {
      final jx = x - hw * 1.0 + hw * 2.0 * (i + r(20 + i) * .9) / 12;
      c.drawLine(
        Offset(jx, ay + hh * .02 * r(60 + i)),
        Offset(jx + hw * .01, ay + hh * (.08 + .05 * r(40 + i))),
        joint,
      );
    }
    final gully = Paint()..color = Sketch.fade(tone.lit, .5);
    for (var i = 0; i < 9; i++) {
      final gx = x + hw * (-1.25 + 2.5 * (i + r(80 + i) * .8) / 9);
      final gy = ay + hh * (.1 + .3 * r(100 + i));
      final gl = hh * (.12 + .2 * r(120 + i));
      c.drawPath(
        Sketch.poly([
          gx - h * .0018, gy, gx + h * .0018, gy, gx + h * .0028, gy + gl * .8, gx, gy + gl, //
        ]),
        gully,
      );
    }
    // Buttresses: tapering ribs of cliff in alternating tones.
    var bx = x - hw * 1.45, bn = 0;
    while (bx < x + hw * 1.45) {
      final bw = hw * (.08 + .12 * r(200 + bn));
      final foot = ay + hh * (.55 + .2 * r(240 + bn));
      final mid = ay + hh * (.2 + .15 * r(260 + bn));
      c.drawPath(
        Sketch.poly([
          bx, ay - hh * .1, bx + bw, ay - hh * .1, bx + bw * .85, mid, bx + bw * (.4 + .3 * r(280 + bn)), foot, bx + bw * .15, mid, //
        ]),
        Paint()
          ..color = r(220 + bn) > .5
              ? Sketch.fade(tone.shadeRock, .24)
              : Sketch.fade(tone.lit, .22),
      );
      bx += bw * .9;
      bn++;
    }
    // Light on the sun side, shadow on the far end.
    c.drawRect(
      box,
      Paint()
        ..shader = Gradient.linear(
          Offset(box.left, 0),
          Offset(box.right, 0),
          [
            Sketch.fade(tone.lit, .4),
            Sketch.fade(tone.lit, 0),
            Sketch.fade(tone.shadeRock, 0),
            Sketch.fade(tone.shadeRock, .3),
          ],
          const [.1, .4, .62, .9],
        ),
    );
    c.restore();
    // Scree fans spill from the gullies at the foot of the cliffs.
    final fanShader = Gradient.linear(
      Offset(x - hw * 2, 0),
      Offset(x + hw * 2, 0),
      [tone.litLow, tone.lit, tone.shade, tone.shadeLow],
      const [0, .35, .65, 1],
    );
    for (var i = 0; i < 9; i++) {
      final gx = x + hw * (-1.4 + 2.8 * (i + .3 + .5 * r(300 + i)) / 9);
      final fw = hw * (.12 + .1 * r(320 + i));
      final fy = ay + hh * (.58 + .1 * r(340 + i));
      c.drawPath(
        Sketch.poly([gx - hw * .02, fy, gx + hw * .02, fy, gx + fw, baseY, gx - fw, baseY]),
        Paint()..shader = fanShader,
      );
    }
    // A snow lid along the top and a snow skirt across the foot.
    c.drawPath(
      _rangePath([
        for (final o in topLine) o.translate(0, -h * .0015),
        for (final o in topLine.reversed) o.translate(0, h * .005),
      ]),
      Paint()..color = tone.ice,
    );
    final skirt = _rangePath([
      p(-2.05, 1.02),
      ...left.skip(1).take(3),
      p(-.9, .74),
      p(-.5, .66),
      p(-.2, .72),
      p(.4, .66),
      p(.95, .72),
      p(1.3, .66),
      right[4],
      right[5],
      right[6],
      p(2.06, 1.02),
    ]);
    c.drawPath(
      skirt,
      Paint()
        ..shader = Gradient.linear(
          Offset(x - hw * 2, 0),
          Offset(x + hw * 2, 0),
          [tone.litLow, tone.lit, tone.shade, tone.shadeLow],
          const [0, .35, .65, 1],
        ),
    );
  }

  /// A low snow dune: one smooth curve shaded from sunlit to shaded across it.
  static void _rangeHill(
    Canvas c,
    double h, {
    required double x,
    required double top,
    required double half,
    required double haze,
    required int seed,
    double sun = -1,
  }) {
    final tone = _rangeTone(haze);
    final base = h * .7, y = top * h, hw = half * h;
    final crest = x + hw * (-.25 + .5 * Sketch.hash(seed));
    final curve = Path()
      ..moveTo(x - hw, base)
      ..cubicTo(x - hw * .6, y + (base - y) * .5, crest - hw * .4, y, crest, y)
      ..cubicTo(crest + hw * .4, y, x + hw * .6, y + (base - y) * .5, x + hw, base);
    final colors = sun < 0
        ? [Sketch.mix(tone.lit, tone.ice, .3), tone.litLow, tone.shadeLow, tone.shade]
        : [tone.shade, tone.shadeLow, tone.litLow, Sketch.mix(tone.lit, tone.ice, .3)];
    final shader = Gradient.linear(
      Offset(x - hw, 0),
      Offset(x + hw, 0),
      colors,
      const [0, .4, .7, 1],
    );
    c.drawPath(Path.from(curve)..close(), Paint()..shader = shader);
    c.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, h * .002)
        ..shader = Gradient.linear(
          Offset(x - hw, 0),
          Offset(x + hw, 0),
          sun < 0
              ? [tone.rim, Sketch.fade(tone.rim, .5), Sketch.fade(tone.rim, 0)]
              : [Sketch.fade(tone.rim, 0), Sketch.fade(tone.rim, .5), tone.rim],
          const [0, .55, 1],
        ),
    );
  }

  /// A faceted peak: a shaded silhouette, a sunlit face split off along a
  /// zigzag arete with a half-lit spur, snow gullies, rock crags with bedding,
  /// a snow cap and cornice, hanging ice and a plume of spindrift. [sun] is the
  /// side the light comes from (-1 left, 1 right); [detail] scales the
  /// secondary features; [q] > 1 sharpens a horn, < 1 rounds a dome.
  static void _rangePeak(
    Canvas c,
    double h, {
    required double x,
    required double top,
    required double half,
    required int seed,
    required double haze,
    double sun = -1,
    double detail = 1,
    double q = 1.25,
    double rough = 1,
    int glaciers = 0,
    double plume = 0,
    double warm = 0,
  }) {
    final tone = _rangeTone(haze, warm);
    final ay = top * h, baseY = h * .7, reach = half * h, hh = baseY - ay;
    double r(int k) => Sketch.hash(seed * 53 + k);
    final lee = -sun;
    final apex = Offset(x, ay);
    final sunSide = _rangeEdge(
      x, ay, baseY, reach * (.85 + .3 * r(1)), q + (r(2) - .5) * .3, seed, sun, rough, //
    );
    final leeSide = _rangeEdge(
      x, ay, baseY, reach * (.85 + .3 * r(3)), q + (r(4) - .5) * .3, seed + 40, lee, rough, //
    );
    final arete = _rangeArete(x, ay, baseY, reach, lee, seed);
    final sunRough = rough > .5 ? _rangeRough(apex, sunSide, reach * .035, seed) : sunSide;
    final leeRough = rough > .5 ? _rangeRough(apex, leeSide, reach * .035, seed + 3) : leeSide;
    final shell = _rangePath([apex, ...sunRough, ...leeRough.reversed]);
    final litPoly = _rangePath([apex, ...sunRough, ...arete.reversed]);
    final shadePoly = _rangePath([apex, ...arete, ...leeRough.reversed]);
    final visBase = h * .66;
    final rockShade = tone.shadeRock, rockLit = tone.litRock;
    final strataShade = Sketch.fade(
      Sketch.mix(rockShade, const Color(0xff2c3560), .6),
      .7,
    );
    final strataLit = Sketch.fade(
      Sketch.mix(rockLit, const Color(0xff6a4a6e), .6),
      .65,
    );
    final full = detail > .5;

    c.drawPath(
      shell,
      Paint()
        ..shader = Gradient.linear(Offset(0, ay), Offset(0, visBase), [
          tone.shade,
          tone.shadeLow,
        ]),
    );

    // -- shaded face
    c.save();
    c.clipPath(shadePoly);
    _rangeFlutes(
      c, h, apex, arete.last.dx, leeSide.last.dx, baseY, (5 * detail).round(), seed + 1,
      Sketch.fade(Sketch.mix(tone.shade, rockShade, .55), .5), //
    );
    final k = (r(11) * 3).floor();
    final beltShade = r(22) > .3 || r(24) <= .3, beltLit = r(24) > .3;
    if (full) {
      // A rock belt across the face and spines of rock down the arete and
      // the lee flank.
      if (beltShade) {
        _rangeBelt(c, h, arete[1 + k], leeSide[3 + k], hh * (.028 + .014 * r(23)), seed + 2, rockShade, strataShade);
      }
      if (r(21) > .4) {
        _rangeBelt(c, h, arete[5 + k], leeSide[8], hh * .026, seed + 3, rockShade, strataShade);
      }
      _rangeRib(c, arete[1 + k], arete[8] + Offset(lee * reach * .03, 0), reach * .045, seed + 4, rockShade);
      _rangeRib(
        c,
        leeSide[3 + k] + Offset(sun * reach * .03, 0),
        leeSide[9] + Offset(sun * reach * .07, 0),
        reach * .05,
        seed + 5,
        rockShade,
      );
    }
    if (glaciers > 0) {
      final a = arete[5], e = leeSide[7];
      final fw = (e.dx - a.dx).abs();
      _rangeIce(
        c, h,
        Offset((a.dx + e.dx) / 2, (a.dy + e.dy) / 2),
        math.min(fw * .5, h * .04),
        h * .066,
        seed,
        tone.iceShade,
        Sketch.mix(tone.iceShade, tone.shade, .5),
        Sketch.mix(rockShade, const Color(0xff2c3560), .3), //
      );
    }
    // A snow cap: the summit is paler than the rock below.
    c.drawPath(
      _rangePath([apex, arete[0], arete[1], arete[2], leeSide[2], leeSide[1], leeSide[0]]),
      Paint()..color = Sketch.mix(tone.iceShade, tone.shade, .3),
    );
    c.restore();

    // -- sunlit face
    c.drawPath(
      litPoly,
      Paint()
        ..shader = Gradient.linear(Offset(0, ay), Offset(0, visBase), [
          tone.lit,
          tone.litLow,
        ]),
    );
    c.save();
    c.clipPath(litPoly);
    // A half-lit spur: a rib running off the sunlit flank throws its own
    // shadow across the lower part of the face.
    if (detail > .25) {
      final si = 4 + (r(7) > .5 ? 1 : 0);
      final s = sunSide[si];
      final bx =
          sunSide.last.dx + (arete.last.dx - sunSide.last.dx) * (.3 + .35 * r(8));
      final spur = <Offset>[s];
      for (var k = 1; k < 6; k++) {
        final u = k / 6;
        spur.add(
          Offset(
            s.dx + (bx - s.dx) * u + (Sketch.hash(seed * 31 + k) - .5) * reach * .14 * math.sin(u * math.pi),
            s.dy + (baseY - s.dy) * u,
          ),
        );
      }
      spur.add(Offset(bx, baseY));
      final m = math.max(0, si - 3);
      c.drawPath(
        _rangePath([...spur, for (var i = arete.length - 1; i >= m; i--) arete[i]]),
        Paint()
          ..shader = Gradient.linear(Offset(0, ay), Offset(0, visBase), [
            Sketch.mix(tone.lit, tone.shade, .3),
            Sketch.mix(tone.litLow, tone.shade, .5),
          ]),
      );
    }
    _rangeFlutes(
      c, h, apex, sunSide.last.dx, arete.last.dx, baseY, (6 * detail).round(), seed + 4,
      Sketch.fade(Sketch.mix(tone.litLow, tone.shade, .6), .4), //
    );
    if (full) {
      if (beltLit) {
        _rangeBelt(c, h, sunSide[3 + k], arete[1 + k], hh * (.028 + .014 * r(25)), seed + 6, rockLit, strataLit);
      }
      _rangeRib(
        c,
        sunSide[3 + k] + Offset(lee * reach * .02, 0),
        sunSide[9] + Offset(lee * reach * .07, 0),
        reach * .05,
        seed + 7,
        rockLit,
      );
      _rangeRib(c, arete[1 + k] + Offset(sun * reach * .02, 0), arete[7] + Offset(sun * reach * .05, 0), reach * .04, seed + 8, rockLit);
    }
    if (glaciers > 1) {
      final a = arete[7], e = sunSide[9];
      _rangeIce(
        c, h,
        Offset((a.dx + e.dx) / 2, (a.dy + e.dy) / 2),
        math.min((e.dx - a.dx).abs() * .4, h * .032),
        h * .055,
        seed + 9,
        Sketch.mix(tone.ice, tone.litLow, .45),
        null,
        Sketch.mix(rockLit, const Color(0xff4b3a63), .2), //
      );
    }
    // A snow cap on the lit summit.
    c.drawPath(
      _rangePath([apex, sunSide[0], sunSide[1], sunSide[2], arete[1], arete[0]]),
      Paint()..color = tone.ice,
    );
    c.restore();

    // -- crest
    final rim = Path()..moveTo(apex.dx, apex.dy);
    for (final o in sunRough) {
      if (o.dy > ay + hh * .42) break;
      rim.lineTo(o.dx, o.dy);
    }
    c.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, h * .0022)
        ..strokeJoin = StrokeJoin.round
        ..shader = Gradient.linear(Offset(0, ay), Offset(0, ay + hh * .42), [
          tone.rim,
          tone.rim,
          Sketch.fade(tone.rim, 0),
        ], const [0, .45, 1]),
    );
    if (full) {
      // Wind from the west builds the cornice on the right-hand flank.
      _rangeCornice(c, h, sun < 0 ? leeSide : sunSide, tone.ice, tone.iceShade);
    }
    if (plume > 0) {
      _rangePlume(
        c,
        apex + Offset(h * .01, h * .004),
        h * plume,
        h * .011,
        const Color(0xfffff6f2),
        1.0 - haze,
      );
    }
  }

  /// Snowy peaks catching the low sun on their left faces.
  static void _range(Canvas c, double w, double h) {
    // Very distant ranges melt into the peach horizon.
    _rangeFarRidge(c, w, h, top: .6, amp: .03, haze: .78, seed: 3);
    _rangeFarRidge(c, w, h, top: .618, amp: .03, haze: .62, seed: 8);
    _rangeMist(c, w, h, h * .55, h * .66, .3);
    // A hazed back massif and a table mountain over the col.
    for (final (fx, top, half, seed, sun) in const [
      (-.02, .53, .2, 11, 1.0),
      (.37, .5, .22, 12, -1.0),
      (.76, .5, .24, 13, -1.0),
      (.96, .52, .2, 14, -1.0),
      (1.14, .49, .24, 15, -1.0),
      (1.3, .52, .21, 16, -1.0),
    ]) {
      _rangePeak(c, h, x: w * fx, top: top, half: half, seed: seed, haze: .42, sun: sun, detail: .55);
    }
    _rangeMesa(c, h, x: w * .52, top: .57, half: .22, seed: 5, haze: .32);
    _rangeMist(c, w, h, h * .5, h * .66, .42);
    // The main massif; the peaks nearest the sun glow warmest.
    for (final (fx, top, half, seed, sun, haze, glaciers, plume, q, rough) in const [
      (.05, .49, .17, 20, 1.0, .18, 1, 0.0, 1.15, 1.0),
      (.4, .5, .15, 21, -1.0, .24, 0, 0.0, 1.1, 1.0),
      (.31, .4, .2, 23, -1.0, .1, 2, .16, 1.3, 1.0),
      (.66, .415, .27, 24, -1.0, .12, 2, .14, 1.15, 1.0),
      (.73, .465, .14, 25, -1.0, .1, 0, 0.0, 1.1, 1.0),
      (.84, .485, .18, 26, -1.0, .16, 1, 0.0, .85, .6),
      (.96, .41, .21, 27, -1.0, .1, 2, .2, 1.25, 1.0),
      (1.1, .49, .2, 28, -1.0, .14, 0, 0.0, .9, .7),
      (1.22, .43, .24, 29, -1.0, .12, 1, .12, 1.2, 1.0),
      (1.3, .47, .13, 31, -1.0, .1, 0, 0.0, 1.1, 1.0),
      (1.34, .5, .17, 30, -1.0, .18, 0, 0.0, 1.1, 1.0),
    ]) {
      _rangePeak(
        c, h,
        x: w * fx, top: top, half: half, seed: seed, haze: haze, sun: sun,
        glaciers: glaciers, plume: plume, q: q, rough: rough,
        warm: math.max(0.0, 1 - (fx - .2).abs() / .5), //
      );
    }
    _rangeMist(c, w, h, h * .56, h * .66, .3);
    // Snow dunes and moraine ridges at the foot of the range.
    for (final (fx, top, half, seed, sun) in const [
      (.1, .622, .34, 41, 1.0),
      (.37, .628, .3, 42, -1.0),
      (.64, .618, .36, 43, -1.0),
      (.9, .626, .32, 44, -1.0),
      (1.17, .62, .36, 45, -1.0),
    ]) {
      _rangeHill(c, h, x: w * fx, top: top, half: half, haze: .2, seed: seed, sun: sun);
    }
    _rangeMist(c, w, h, h * .6, h * .662, .28);
  }

  /// The research station on the level terrace: modules on legs, a radome, a
  /// mast, a snowcat and fuel drums, all hazed by the distance. [x] is the
  /// centre in pixels, [s] the module unit (a fraction of the viewport height
  /// [h]). Everything stands on the lip, so each base follows the ridge.
  static void _station(Canvas c, double x, double s, double h) {
    Color hz(int v) => _hazed(Color(v), .22);
    double gy(double dx) => _shelfEdge((x + dx * s) / h) * h + s * .05;
    final g = gy(0);
    final red = hz(0xffd9603f), redDark = hz(0xff9f4335), redLit = hz(0xfff2916a);
    final blue = hz(0xff5f88ba), blueDark = hz(0xff3f6394), blueLit = hz(0xff97b8de);
    final steel = hz(0xff566684), duct = hz(0xff8797b2);
    final snow = hz(0xfff8f4f7), snowShade = hz(0xffbfcdea);

    _shelfRoute(c, x, s, h);
    _shelfMast(c, Offset(x + 6.2 * s, gy(6.2)), s, 5.4, steel);
    // Long shadows run east across the snow from the low sun.
    c.drawPath(
      Sketch.poly([
        -5.2, -.2, 8.6, -.2, 9.6, .05, -4.6, .05, //
      ], at: Offset(x, g), s: s),
      Paint()..color = Sketch.fade(const Color(0xff7d94cc), .32),
    );
    _shelfRadome(c, Offset(x - 4.6 * s, gy(-4.6)), s);
    // Gangways join the modules.
    for (final (a, b, y) in const [(-.95, -.4, -1.35), (2.3, 2.85, -1.4)]) {
      c.drawRect(
        Rect.fromLTRB(x + a * s, g + (y - .2) * s, x + b * s, g + (y + .2) * s),
        Paint()..color = duct,
      );
    }
    _shelfModule(
      c,
      Rect.fromLTRB(x - 3.0 * s, g - 1.9 * s, x - .9 * s, g - .85 * s),
      s,
      g,
      red,
      redDark,
      redLit,
      snow,
      1,
    );
    _shelfModule(
      c,
      Rect.fromLTRB(x - .45 * s, g - 2.45 * s, x + 2.35 * s, g - .95 * s),
      s,
      g,
      blue,
      blueDark,
      blueLit,
      snow,
      2,
    );
    _shelfModule(
      c,
      Rect.fromLTRB(x + 2.8 * s, g - 1.9 * s, x + 4.7 * s, g - .85 * s),
      s,
      g,
      red,
      redDark,
      redLit,
      snow,
      3,
      door: true,
    );
    // Roof plant on the hub: a plant room, a stack and whip antennas.
    c.drawRect(
      Rect.fromLTRB(x + .2 * s, g - 2.85 * s, x + 1.05 * s, g - 2.4 * s),
      Paint()..color = blueDark,
    );
    c.drawRect(
      Rect.fromLTRB(x + .2 * s, g - 2.85 * s, x + .78 * s, g - 2.4 * s),
      Paint()..color = blue,
    );
    c.drawRect(
      Rect.fromLTRB(x + 1.62 * s, g - 3.4 * s, x + 1.8 * s, g - 2.4 * s),
      Paint()..color = steel,
    );
    c.drawRect(
      Rect.fromLTRB(x + 1.55 * s, g - 3.48 * s, x + 1.87 * s, g - 3.36 * s),
      Paint()..color = steel,
    );
    final whip = Paint()
      ..color = steel
      ..strokeWidth = math.max(.7, s * .06)
      ..strokeCap = StrokeCap.round;
    for (final (dx, top) in const [(2.05, -3.7), (2.2, -3.2), (-.1, -3.3)]) {
      c.drawLine(Offset(x + dx * s, g - 2.4 * s), Offset(x + dx * s, g + top * s), whip);
    }
    // Drifts bank up against the legs.
    for (final (a, peak, b) in const [
      (-3.6, .34, -1.6),
      (-1.4, .22, .3),
      (1.8, .3, 3.4),
      (4.6, .4, 6.6),
    ]) {
      final mid = (a + b) / 2;
      c.drawPath(
        Sketch.poly([a, .1, a + (b - a) * .25, -peak * .7, mid - .2, -peak, b - (b - a) * .3, -peak * .6, b, .1], at: Offset(x, g), s: s),
        Paint()..color = snowShade,
      );
      c.drawPath(
        Sketch.poly([a, .1, a + (b - a) * .25, -peak * .7, mid - .2, -peak, mid + .6, -peak * .5, mid + .9, .1], at: Offset(x, g), s: s),
        Paint()..color = snow,
      );
    }
    _shelfDrums(c, Offset(x - 7.0 * s, gy(-7.0)), s);
    _shelfSnowcat(c, Offset(x + 10.2 * s, gy(10.2)), s);
    // Two people: one on the steps, one walking out to the snowcat.
    _shelfPerson(c, Offset(x + 5.75 * s, gy(5.75) - s * .02), s, 0);
    _shelfPerson(c, Offset(x + 8.6 * s, gy(8.6) - s * .02), s, 1);
  }

  /// A tiny figure in a parka, only a few pixels high.
  static void _shelfPerson(Canvas c, Offset feet, double s, int seed) {
    final parka = _hazed(seed.isEven ? const Color(0xffc8523f) : const Color(0xff3f5f98), .3);
    final leg = Paint()
      ..color = _hazed(const Color(0xff2f3b5a), .25)
      ..strokeWidth = math.max(.7, s * .08)
      ..strokeCap = StrokeCap.round;
    c.drawLine(feet + Offset(-s * .04, 0), feet + Offset(-s * .03, -s * .26), leg);
    c.drawLine(feet + Offset(s * .05, 0), feet + Offset(s * .04, -s * .26), leg);
    c.drawRRect(
      RRect.fromRectXY(
        Rect.fromLTWH(feet.dx - s * .1, feet.dy - s * .58, s * .22, s * .36),
        s * .07,
        s * .07,
      ),
      Paint()..color = parka,
    );
    c.drawCircle(
      feet + Offset(0, -s * .66),
      math.max(.9, s * .08),
      Paint()..color = _hazed(const Color(0xffefd2c6), .25),
    );
  }

  /// One module on legs: barrel roof, end wall, windows, snow on the roof.
  static void _shelfModule(
    Canvas c,
    Rect body,
    double s,
    double ground,
    Color wall,
    Color shade,
    Color lit,
    Color snow,
    int seed, {
    bool door = false,
  }) {
    final steel = _hazed(const Color(0xff4d5d7a), .25);
    final leg = Paint()
      ..color = steel
      ..strokeWidth = math.max(.8, s * .11);
    final brace = Paint()
      ..color = Sketch.fade(steel, .8)
      ..strokeWidth = math.max(.6, s * .05);
    for (final dx in [body.left + s * .38, body.right - s * .5]) {
      c.drawLine(Offset(dx, body.bottom), Offset(dx, ground), leg);
      c.drawLine(Offset(dx + s * .3, body.bottom), Offset(dx + s * .3, ground), brace);
      c.drawLine(Offset(dx, body.bottom), Offset(dx + s * .3, ground), brace);
      c.drawLine(Offset(dx + s * .3, body.bottom), Offset(dx, ground), brace);
    }
    final r = s * .3;
    final rr = RRect.fromRectAndCorners(
      body,
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomLeft: Radius.circular(s * .05),
      bottomRight: Radius.circular(s * .05),
    );
    c.drawRRect(rr, Paint()..color = wall);
    // The shaded east end wall shows in three-quarter view.
    c.drawPath(
      Sketch.poly([
        body.right - s * .02, body.top + r * .5, //
        body.right + s * .3, body.top + r * .9,
        body.right + s * .3, body.bottom - s * .04,
        body.right - s * .02, body.bottom,
      ]),
      Paint()..color = shade,
    );
    // Roof: a sunlit strip along the top and the belly in shadow.
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(body.left, body.top, body.width, s * .34),
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
      ),
      Paint()..color = lit,
    );
    c.drawRect(
      Rect.fromLTRB(body.left, body.bottom - s * .16, body.right, body.bottom),
      Paint()..color = shade,
    );
    // Sunlit west edge.
    c.drawLine(
      Offset(body.left + s * .03, body.top + r),
      Offset(body.left + s * .03, body.bottom - s * .1),
      Paint()
        ..color = Sketch.fade(const Color(0xffffd8c8), .55)
        ..strokeWidth = math.max(.7, s * .06),
    );
    // Panel seams run down the walls.
    final seam = Paint()
      ..color = Sketch.fade(shade, .35)
      ..strokeWidth = math.max(.5, s * .03);
    for (var x = body.left + s * .5; x < body.right - s * .2; x += s * .5) {
      c.drawLine(Offset(x, body.top + s * .36), Offset(x, body.bottom - s * .16), seam);
    }
    // Windows: a row of small panes, most of them warm.
    final n = ((body.width - s * (door ? 1.2 : .5)) / (s * .62)).floor();
    final pane = s * .3;
    for (var i = 0; i < n; i++) {
      final on = Sketch.hash(seed * 31 + i + 500) < .7;
      c.drawRRect(
        RRect.fromRectXY(
          Rect.fromLTWH(
            body.left + s * .34 + i * s * .62,
            body.top + body.height * .42,
            pane,
            pane * .8,
          ),
          s * .05,
          s * .05,
        ),
        Paint()
          ..color = on
              ? _hazed(const Color(0xffffeec4), .18)
              : _hazed(const Color(0xff33496f), .2),
      );
    }
    if (door) {
      // A door on the end, with steps down to the snow.
      c.drawRect(
        Rect.fromLTWH(body.right - s * .58, body.bottom - s * .78, s * .36, s * .78),
        Paint()..color = _hazed(const Color(0xff6f2c2a), .2),
      );
      final stairs = Path()..moveTo(body.right - s * .2, body.bottom);
      for (var k = 1; k <= 5; k++) {
        stairs
          ..lineTo(body.right - s * .2 + k * s * .16, body.bottom + (k - 1) * (ground - body.bottom) / 5)
          ..lineTo(body.right - s * .2 + k * s * .16, body.bottom + k * (ground - body.bottom) / 5);
      }
      c.drawPath(
        stairs,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = steel
          ..strokeWidth = math.max(.6, s * .06),
      );
    }
    // A cap of snow on the roof.
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(body.left - s * .04, body.top - s * .05, body.width + s * .1, s * .2),
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
        bottomLeft: Radius.circular(s * .1),
        bottomRight: Radius.circular(s * .1),
      ),
      Paint()..color = snow,
    );
  }

  /// A geodesic radome on a squat plant building.
  static void _shelfRadome(Canvas c, Offset base, double s) {
    final r = s * 1.05;
    final centre = base + Offset(0, -s * 1.85);
    c.drawCircle(
      centre,
      r,
      Paint()
        ..shader = Gradient.radial(
          centre + Offset(-r * .4, -r * .4),
          r * 1.7,
          [
            _hazed(const Color(0xfffffbfa), .15),
            _hazed(const Color(0xffd7e2f3), .2),
            _hazed(const Color(0xff9fb0d2), .28),
          ],
          const [0, .55, 1],
        ),
    );
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, s * .045)
      ..color = Sketch.fade(_hazed(const Color(0xff7d90b8), .2), .55);
    for (final k in const [.32, .68]) {
      c.drawOval(Rect.fromCenter(center: centre, width: r * 2 * k, height: r * 2), seam);
    }
    for (final dy in const [-.45, 0.0, .45]) {
      final wd = math.sqrt(1 - dy * dy) * r;
      c.drawArc(
        Rect.fromCenter(center: centre + Offset(0, dy * r), width: wd * 2, height: r * .36),
        0,
        math.pi,
        false,
        seam,
      );
    }
    // The plant building under it, with a door and a lit pane.
    final wall = _hazed(const Color(0xffe6ecf7), .22);
    c.drawRect(
      Rect.fromLTRB(base.dx - s * 1.15, base.dy - s * 1.05, base.dx + s * 1.15, base.dy),
      Paint()..color = wall,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx + s * .5, base.dy - s * 1.05, base.dx + s * 1.15, base.dy),
      Paint()..color = _hazed(const Color(0xffa9b8d6), .25),
    );
    c.drawRect(
      Rect.fromLTWH(base.dx - s * .8, base.dy - s * .78, s * .3, s * .26),
      Paint()..color = _hazed(const Color(0xffffeec4), .18),
    );
    c.drawRect(
      Rect.fromLTWH(base.dx - s * .1, base.dy - s * .72, s * .36, s * .72),
      Paint()..color = _hazed(const Color(0xff7c8fb4), .2),
    );
  }

  /// A guyed lattice mast with cross arms and a dish.
  static void _shelfMast(Canvas c, Offset base, double s, double tall, Color steel) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = steel
      ..strokeWidth = math.max(.7, s * .07);
    final lattice = Path();
    final half = s * .17;
    for (var k = 0; k < 10; k++) {
      final y0 = base.dy - tall * s * k / 10, y1 = base.dy - tall * s * (k + 1) / 10;
      final a = half * (1 - .5 * k / 10), b = half * (1 - .5 * (k + 1) / 10);
      lattice
        ..moveTo(base.dx - a, y0)
        ..lineTo(base.dx + b, y1)
        ..moveTo(base.dx + a, y0)
        ..lineTo(base.dx - b, y1);
    }
    c.drawPath(lattice, line..strokeWidth = math.max(.5, s * .04));
    for (final dx in const [-1, 1]) {
      c.drawLine(
        Offset(base.dx + dx * half, base.dy),
        Offset(base.dx + dx * half * .5, base.dy - tall * s),
        line..strokeWidth = math.max(.7, s * .07),
      );
    }
    // Cross arms, guy wires and a dish.
    for (final (k, len) in const [(.62, .7), (.82, .5)]) {
      c.drawLine(
        Offset(base.dx - len * s, base.dy - tall * s * k),
        Offset(base.dx + len * s, base.dy - tall * s * k),
        line..strokeWidth = math.max(.7, s * .07),
      );
    }
    final guy = Paint()
      ..color = Sketch.fade(steel, .6)
      ..strokeWidth = math.max(.5, s * .035);
    for (final dx in const [-3.2, 2.6]) {
      c.drawLine(
        Offset(base.dx, base.dy - tall * s * .82),
        Offset(base.dx + dx * s, base.dy),
        guy,
      );
    }
    final dish = Offset(base.dx + s * .3, base.dy - tall * s * .45);
    c.drawPath(
      Path()
        ..moveTo(dish.dx - s * .55, dish.dy - s * .35)
        ..quadraticBezierTo(dish.dx + s * .1, dish.dy + s * .55, dish.dx + s * .5, dish.dy - s * .32)
        ..close(),
      Paint()..color = _hazed(const Color(0xffe9eef8), .2),
    );
    c.drawLine(dish + Offset(-s * .05, s * .05), dish + Offset(s * .05, -s * .7), guy);
    c.drawCircle(
      Offset(base.dx, base.dy - tall * s),
      math.max(.8, s * .07),
      Paint()..color = _hazed(const Color(0xffe0654f), .3),
    );
  }

  /// Fuel drums stacked on the lip.
  static void _shelfDrums(Canvas c, Offset base, double s) {
    final colors = [
      _hazed(const Color(0xffe0693f), .22),
      _hazed(const Color(0xff4f82c2), .22),
      _hazed(const Color(0xffd9553f), .22),
    ];
    final ring = Paint()..color = Sketch.fade(const Color(0xff2f4266), .35);
    void drum(double dx, double dy, int k) {
      final r = Rect.fromLTWH(base.dx + dx * s, base.dy + dy * s - s * .5, s * .38, s * .5);
      c.drawRRect(RRect.fromRectXY(r, s * .06, s * .06), Paint()..color = colors[k % 3]);
      c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * .3, r.width, math.max(.5, s * .04)), ring);
      c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * .68, r.width, math.max(.5, s * .04)), ring);
      c.drawRect(
        Rect.fromLTWH(r.left + s * .03, r.top + s * .04, s * .07, r.height - s * .08),
        Paint()..color = Sketch.fade(const Color(0xffffe6d8), .5),
      );
    }
    for (var i = 0; i < 4; i++) {
      drum(i * .42, .05, i);
    }
    for (var i = 0; i < 2; i++) {
      drum(.2 + i * .42, -.42, i + 1);
    }
    // A tarp over the pile.
    c.drawPath(
      Sketch.poly([-.1, -.85, 1.75, -.85, 1.85, -.7, -.15, -.7], at: base, s: s),
      Paint()..color = _hazed(const Color(0xff3f5e93), .25),
    );
  }

  /// A tracked snowcat towing a sledge of crates, facing west.
  static void _shelfSnowcat(Canvas c, Offset base, double s) {
    final track = _hazed(const Color(0xff2e3a55), .2);
    final red = _hazed(const Color(0xffd9553f), .22);
    final redDark = _hazed(const Color(0xff9c3f34), .24);
    // Sledge behind: a deck with two crates and a tow bar.
    c.drawLine(
      base + Offset(s * 1.2, -s * .3),
      base + Offset(s * 2.1, -s * .22),
      Paint()
        ..color = track
        ..strokeWidth = math.max(.6, s * .06),
    );
    c.drawRect(Rect.fromLTWH(base.dx + s * 2.0, base.dy - s * .18, s * 1.9, s * .12), Paint()..color = track);
    c.drawRect(
      Rect.fromLTWH(base.dx + s * 2.15, base.dy - s * .68, s * .7, s * .5),
      Paint()..color = _hazed(const Color(0xff4f82c2), .22),
    );
    c.drawRect(
      Rect.fromLTWH(base.dx + s * 2.95, base.dy - s * .55, s * .8, s * .37),
      Paint()..color = _hazed(const Color(0xffe0a04a), .25),
    );
    // Cab and body.
    c.drawPath(
      Sketch.poly([
        -.1, -.42, .1, -1.05, .95, -1.12, 1.15, -.42, //
      ], at: base, s: s),
      Paint()..color = red,
    );
    c.drawRect(Rect.fromLTWH(base.dx - s * .1, base.dy - s * .5, s * 1.35, s * .16), Paint()..color = redDark);
    c.drawPath(
      Sketch.poly([.02, -.62, .14, -.98, .62, -1.0, .66, -.62], at: base, s: s),
      Paint()..color = _hazed(const Color(0xffb7d5ee), .2),
    );
    // Tracks with a few road wheels.
    c.drawRRect(
      RRect.fromRectXY(
        Rect.fromLTWH(base.dx - s * .2, base.dy - s * .48, s * 1.55, s * .48),
        s * .24,
        s * .24,
      ),
      Paint()..color = track,
    );
    final wheel = Paint()..color = Sketch.fade(const Color(0xff9fb0d2), .7);
    for (var i = 0; i < 4; i++) {
      c.drawCircle(base + Offset((.05 + i * .36) * s, -s * .24), s * .1, wheel);
    }
    // A beacon on the roof.
    c.drawRect(
      Rect.fromLTWH(base.dx + s * .5, base.dy - s * 1.22, s * .12, s * .1),
      Paint()..color = _hazed(const Color(0xffe6a13a), .35),
    );
  }

  /// Marker flags leading west along the plain, shrinking with distance.
  static void _shelfRoute(Canvas c, double x, double s, double h) {
    final pole = Paint()
      ..color = _hazed(const Color(0xff54648a), .3)
      ..strokeWidth = math.max(.6, s * .05);
    for (var i = 0; i < 9; i++) {
      final k = 1 - i * .085;
      final px = x - s * (8.6 + 2.9 * i);
      final py = _shelfEdge(px / h) * h - h * (.004 + .0022 * i);
      final ph = s * 1.05 * k;
      c.drawLine(Offset(px, py), Offset(px, py - ph), pole);
      c.drawPath(
        Sketch.poly([0, -1, .6, -.86, 0, -.7], at: Offset(px, py - ph * .2), s: ph),
        Paint()
          ..color = _hazed(
            i.isEven ? const Color(0xffdd5a45) : const Color(0xffe8894a),
            .3,
          ),
      );
    }
  }

  /// A wind turbine, the flag and the stack's plume: the station's moving parts.
  static void _shelfLive(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h, s = h * .032, x = w * .74;
    double gy(double dx) => _shelfEdge((x + dx * s) / h) * h + s * .05;
    final steel = _hazed(const Color(0xff566684), .22);
    // The turbine stands a little back on the plain.
    final tx = x + 14.6 * s;
    final ty = _shelfEdge(tx / h) * h - h * .012;
    final tk = .82;
    final hub = Offset(tx, ty - 4.7 * s * tk);
    c.drawPath(
      Sketch.poly([-.09, 0, -.045, -4.7, .045, -4.7, .09, 0], at: Offset(tx, ty), s: s * tk),
      Paint()..color = _hazed(const Color(0xffeef2f9), .22),
    );
    final blade = Paint()..color = _hazed(const Color(0xfff1f4fa), .24);
    final spin = f.clock * .55;
    for (var k = 0; k < 3; k++) {
      final a = spin + k * math.pi * 2 / 3 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      final side = Offset(-dir.dy, dir.dx);
      c.drawPath(
        Path()
          ..moveTo(hub.dx + side.dx * s * .07 * tk, hub.dy + side.dy * s * .07 * tk)
          ..lineTo(hub.dx + dir.dx * s * 1.9 * tk + side.dx * s * .02, hub.dy + dir.dy * s * 1.9 * tk + side.dy * s * .02)
          ..lineTo(hub.dx - side.dx * s * .09 * tk, hub.dy - side.dy * s * .09 * tk)
          ..close(),
        blade,
      );
    }
    c.drawCircle(hub, s * .1 * tk, Paint()..color = steel);
    // A pennant on the east module, and a thin plume from the hub's stack.
    final g = gy(0);
    final pole = Offset(x + 3.85 * s, g - 1.9 * s);
    c.drawLine(pole, pole + Offset(0, -s * 1.5), Paint()
      ..color = steel
      ..strokeWidth = math.max(.6, s * .05));
    final wave = math.sin(f.clock * 3.1) * s * .1;
    c.drawPath(
      Path()
        ..moveTo(pole.dx, pole.dy - s * 1.5)
        ..quadraticBezierTo(pole.dx + s * .5, pole.dy - s * 1.5 + wave, pole.dx + s * 1.0, pole.dy - s * 1.35 + wave * 1.6)
        ..quadraticBezierTo(pole.dx + s * .5, pole.dy - s * 1.2 + wave, pole.dx, pole.dy - s * 1.15)
        ..close(),
      Paint()..color = _hazed(const Color(0xffe0553f), .28),
    );
    for (var i = 0; i < 5; i++) {
      final t = (f.clock * .07 + i / 5) % 1;
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(
            x + 1.72 * s + t * s * 3.8 + math.sin(t * 5 + i) * s * .12,
            g - 3.5 * s - t * s * 2.2,
          ),
          width: s * (.6 + 1.9 * t),
          height: s * (.45 + 1.0 * t),
        ),
        const Color(0xffe4dcee),
        .62 * (1 - t) * math.min(1, t * 5),
      );
    }
  }

  // ---- shelf: snow plain, cliff face, sea smoke ------------------------------

  /// The station's moving parts sit behind the shelf lip with the rest of it.
  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d == Depth.mid) _shelfLive(c, f);
  }

  /// The snow plain behind the lip: a blue-lilac gradient with sastrugi.
  static void _shelfPlain(Canvas c, double w, double h) {
    final x0 = -h * .3, x1 = w + h * .8;
    const top = Color(0xffd8e2f1);
    c.drawRect(
      Rect.fromLTRB(x0, h * .657, x1, h * .78),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .657),
          Offset(0, h * .78),
          [
            Sketch.fade(top, 0),
            top,
            const Color(0xffd0dbef),
            const Color(0xffbccae7),
            const Color(0xffb0c1e2),
          ],
          const [0, .05, .3, .62, 1],
        ),
    );
    // The low sun warms the plain on its side of the sky.
    const warm = Color(0xffffd2c2);
    c.drawRect(
      Rect.fromLTRB(x0, h * .657, x1, h * .78),
      Paint()
        ..shader = Gradient.linear(
          Offset(x0, 0),
          Offset(x1, 0),
          [
            Sketch.fade(warm, 0),
            Sketch.fade(warm, .34),
            Sketch.fade(warm, 0),
            Sketch.fade(warm, 0),
          ],
          [0, (w * .2 - x0) / (x1 - x0), (w * .85 - x0) / (x1 - x0), 1],
        ),
    );
    // Long soft dunes, sunlit on the west flank and lilac on the east.
    for (var i = 0; i < 10; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(i + 920);
      final len = h * (.22 + .3 * Sketch.hash(i + 921));
      final lip = _shelfEdge(x / h) * h;
      final y = h * .668 + (lip - h * .668) * (.25 + .6 * Sketch.hash(i + 922));
      final th = h * (.0035 + .006 * (y / h - .668) / .04);
      c.drawPath(
        Path()
          ..moveTo(x - len / 2, y)
          ..quadraticBezierTo(x - len * .18, y - th * 2, x + len / 2, y)
          ..close(),
        Paint()
          ..shader = Gradient.linear(Offset(x - len / 2, 0), Offset(x + len / 2, 0), [
            Sketch.fade(const Color(0xfffff4f2), .7),
            Sketch.fade(const Color(0xffe9eaf7), .3),
            Sketch.fade(const Color(0xff9aaedb), .35),
          ], const [0, .45, 1]),
      );
    }
    // Sastrugi: low wind-carved ridges, sunlit on the west side. They get
    // longer and crisper toward the lip, shorter toward the horizon.
    final lit = Paint()..color = Sketch.fade(const Color(0xfffff2f0), .6);
    final shade = Paint()..color = Sketch.fade(const Color(0xff9aaedb), .38);
    for (var i = 0; i < 80; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(i + 900);
      final lip = _shelfEdge(x / h) * h;
      final k = Sketch.hash(i + 901);
      final y = h * .663 + (lip - h * .663) * (.1 + .78 * k);
      final len = h * (.025 + .11 * k) * (.6 + .8 * Sketch.hash(i + 902));
      final th = h * (.0012 + .0028 * k);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + len * .04, y + th * .6),
          width: len,
          height: th,
        ),
        shade,
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: len * .9, height: th * .8),
        lit,
      );
    }
  }

  static final _shelfFaces = <Size, Picture>{};

  /// The cliff face is static, so it is recorded once per viewport.
  static Picture _shelfFacePicture(Size size) {
    final cached = _shelfFaces.remove(size);
    if (cached != null) return _shelfFaces[size] = cached;
    final recorder = PictureRecorder();
    _shelfFace(Canvas(recorder), size);
    final picture = recorder.endRecording();
    _shelfFaces[size] = picture;
    if (_shelfFaces.length > 6) {
      _shelfFaces.remove(_shelfFaces.keys.first)!.dispose();
    }
    return picture;
  }

  /// Mid-band detail over the ridge: the ice cliff and the sea smoke at its foot.
  static void _shelfOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final face = _shelfFacePicture(f.size);
    if (presence < .999) {
      c.saveLayer(
        Rect.fromLTRB(-h * .5, h * .6, f.w + h, h * .84),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
      c.drawPicture(face);
      c.restore();
    } else {
      c.drawPicture(face);
    }
    // Wisps of sea smoke drift along the foot of the cliff.
    final water = h * .785;
    for (var i = 0; i < 8; i++) {
      final slow = math.sin(f.clock * .12 + i * 1.9);
      final rise = .5 + .5 * math.sin(f.clock * .2 + i * 2.3);
      final x = -h * .2 + (f.w + h * .9) * (i + .5 * Sketch.hash(i + 960)) / 8 + slow * h * .05;
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x, water - h * (.012 + .012 * rise)),
          width: h * (.24 + .16 * Sketch.hash(i + 961)),
          height: h * (.03 + .02 * rise),
        ),
        const Color(0xffeef4fb),
        (.5 + .22 * rise) * presence,
      );
    }
    // Hoar frost glints on the sunlit lip.
    final glint = Paint();
    for (var i = 0; i < 9; i++) {
      final on = math.sin(f.clock * 2.1 + i * 2.7);
      if (on < .25) continue;
      final x = -h * .2 + (f.w + h * .9) * Sketch.hash(i + 970);
      final y = _shelfEdge(x / h) * h + h * .003;
      final r = h * .007 * on;
      glint.color = Sketch.fade(const Color(0xffffffff), .9 * presence);
      c.drawPath(Sketch.poly([x - r, y, x, y - r * .3, x + r, y, x, y + r * .3]), glint);
      c.drawPath(Sketch.poly([x, y - r, x + r * .18, y, x, y + r, x - r * .18, y]), glint);
    }
  }

  /// Panels of the cliff: one per stretch between jogs, long ones split.
  static List<(double, double)> _shelfPanels(double h, double x0, double x1) {
    final cuts = <double>[];
    for (var k = -1; k * _shelfSpan * h < x1; k++) {
      for (final (at, _, _) in _shelfSteps) {
        final x = (at + k * _shelfSpan) * h;
        if (x > x0 + h * .05 && x < x1 - h * .05) cuts.add(x);
      }
    }
    cuts.sort();
    final edges = <double>[x0];
    var n = 0;
    for (final cut in [...cuts, x1]) {
      final prev = edges.last;
      final parts = ((cut - prev) / (h * .75)).ceil();
      for (var i = 1; i < parts; i++) {
        edges.add(
          prev + (cut - prev) * i / parts + h * .07 * (Sketch.hash(++n + 950) - .5),
        );
      }
      edges.add(cut);
    }
    return [for (var i = 0; i + 1 < edges.length; i++) (edges[i], edges[i + 1])];
  }

  /// A polygon between two curves of x over [xa, xb], both in pixels.
  static Path _shelfStrip(
    double xa,
    double xb,
    double h,
    double Function(double) top,
    double Function(double) bottom,
  ) {
    final n = math.max(2, ((xb - xa) / (h * .008)).ceil());
    final path = Path()..moveTo(xa, top(xa));
    for (var i = 1; i <= n; i++) {
      final x = xa + (xb - xa) * i / n;
      path.lineTo(x, top(x));
    }
    for (var i = n; i >= 0; i--) {
      final x = xa + (xb - xa) * i / n;
      path.lineTo(x, bottom(x));
    }
    return path..close();
  }

  static void _shelfFace(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final x0 = -h * .3, x1 = w + h * .8;
    final water = h * .785;
    double lipAt(double x) => _shelfEdge(x / h) * h;
    final panels = _shelfPanels(h, x0, x1);

    bool onRamp(double x) {
      final pm = x / h % _shelfSpan;
      return pm > .3 && pm < .98;
    }

    final pale = Path(), deep = Path(), band = Path(), blue = Path();
    final icicles = Path();
    for (var i = 0; i < panels.length; i++) {
      final (xa, xb) = panels[i];
      final y0 = lipAt((xa + xb) / 2);
      final depth = water - y0;
      // Panels facing the low sun glow pink-white; the others fall into blue.
      final lit = (i.isEven ? .72 : .04) + .24 * Sketch.hash(i + 610);
      // Panels whose lip is higher are further away, and hazier.
      final far = ((.706 - y0 / h) / .03).clamp(0.0, 1.0);
      Color tone(Color shade, Color sun) =>
          _hazed(Sketch.mix(shade, sun, lit), .05 + .24 * far);
      double top(double x) => lipAt(x) + h * .002;
      final whole = _shelfStrip(xa, xb, h, top, (_) => water + h * .03);
      final pm = (xa + xb) / 2 / h % _shelfSpan;
      if (pm > .3 && pm < .98) {
        // The snow ramp: a lit slope with wind ripples and a sledge track.
        c.drawPath(
          whole,
          Paint()
            ..shader = Gradient.linear(Offset(0, h * .69), Offset(0, water), [
              _hazed(const Color(0xfffff3f3), .12),
              _hazed(const Color(0xffdbe4f5), .12),
              _hazed(const Color(0xffa7bde3), .12),
            ], const [0, .45, 1]),
        );
        c.drawPath(
          whole,
          Paint()
            ..shader = Gradient.linear(Offset(xa, 0), Offset(xb, 0), [
              Sketch.fade(const Color(0xff6f89c8), .22),
              Sketch.fade(const Color(0xff6f89c8), 0),
              Sketch.fade(const Color(0xffffffff), .3),
            ], const [0, .5, 1]),
        );
        final ripple = Paint();
        for (var k = 0; k < 34; k++) {
          final rx = xa + (xb - xa) * Sketch.hash(k + 830);
          final ry = lipAt(rx) + h * .01 + (water - lipAt(rx) - h * .02) * Sketch.hash(k + 831);
          final len = h * (.03 + .06 * Sketch.hash(k + 832));
          final th = h * (.0016 + .0018 * Sketch.hash(k + 833));
          ripple.color = Sketch.fade(const Color(0xff8fa6d6), .28);
          c.drawOval(Rect.fromCenter(center: Offset(rx + len * .05, ry + th * .6), width: len, height: th), ripple);
          ripple.color = Sketch.fade(const Color(0xffffffff), .42);
          c.drawOval(Rect.fromCenter(center: Offset(rx, ry), width: len * .9, height: th * .8), ripple);
        }
        // The sledge track winds down the slope.
        final track = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, h * .0016)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Sketch.fade(const Color(0xff7f92cc), .4);
        for (final dy in [0.0, h * .004]) {
          final line = Path();
          for (var q = 0; q <= 24; q++) {
            final tx = xa + (xb - xa) * (.08 + .84 * q / 24);
            final ty = lipAt(tx) + h * (.02 + .02 * math.sin(q * .55)) + (water - lipAt(tx)) * .28 * q / 24 + dy;
            if (q == 0) {
              line.moveTo(tx, ty);
            } else {
              line.lineTo(tx, ty);
            }
          }
          c.drawPath(line, track);
        }
        continue;
      }
      c.drawPath(
        whole,
        Paint()
          ..shader = Gradient.linear(
            Offset(0, y0),
            Offset(0, water),
            [
              tone(const Color(0xffc9d9f0), const Color(0xfffff2f3)),
              tone(const Color(0xff86b0da), const Color(0xffcbe4f5)),
              tone(const Color(0xff3a80b6), const Color(0xff6dbcd9)),
            ],
            const [0, .5, 1],
          ),
      );
      // Each panel is a plane: light pools on its sunward edge, and it
      // darkens into the crease on the other side.
      c.drawPath(
        whole,
        Paint()
          ..shader = Gradient.linear(
            Offset(xa, 0),
            Offset(xb, 0),
            lit > .45
                ? [
                    Sketch.fade(const Color(0xffffffff), .3),
                    Sketch.fade(const Color(0xffffffff), 0),
                  ]
                : [
                    Sketch.fade(const Color(0xff3a6aa8), 0),
                    Sketch.fade(const Color(0xff3a6aa8), .3),
                  ],
          ),
      );
      // Buttresses: broad ribs, lit on the west flank, shaded on the east.
      final ribs = 1 + (Sketch.hash(i + 800) * 2.4).floor();
      for (var r = 0; r < ribs; r++) {
        final xc = xa + (xb - xa) * (.2 + .6 * Sketch.hash(i * 5 + r + 810));
        final rw = h * (.03 + .05 * Sketch.hash(i * 5 + r + 820));
        c.drawPath(
          _shelfStrip(xc - rw, xc, h, top, (_) => water + h * .03),
          Paint()
            ..shader = Gradient.linear(Offset(xc - rw, 0), Offset(xc, 0), [
              Sketch.fade(const Color(0xffffffff), 0),
              Sketch.fade(const Color(0xffffffff), .18),
            ]),
        );
        c.drawPath(
          _shelfStrip(xc, xc + rw * .8, h, top, (_) => water + h * .03),
          Paint()
            ..shader = Gradient.linear(Offset(xc, 0), Offset(xc + rw * .8, 0), [
              Sketch.fade(const Color(0xff2f5f9c), .22),
              Sketch.fade(const Color(0xff2f5f9c), 0),
            ]),
        );
      }
      // Bands of dense blue ice run right across the panel.
      for (var b = 0; b < 2; b++) {
        final by = y0 + depth * (.34 + .3 * b + .1 * (Sketch.hash(i * 3 + b + 840) - .5));
        final th = h * (.004 + .003 * Sketch.hash(i * 3 + b + 843));
        double bw(double px) => by + h * .003 * math.sin(px / h * 11 + i + b * 2);
        blue.moveTo(xa, bw(xa));
        for (var q = 1; q <= 10; q++) {
          final px = xa + (xb - xa) * q / 10;
          blue.lineTo(px, bw(px) - th * math.sin(math.pi * q / 10));
        }
        for (var q = 9; q >= 1; q--) {
          final px = xa + (xb - xa) * q / 10;
          blue.lineTo(px, bw(px) + th * .6 * math.sin(math.pi * q / 10));
        }
        blue.close();
      }
      // Strata: broken firn layers, pale and dense-blue in turn.
      final tilt = (Sketch.hash(i + 620) - .5) * .012;
      for (var k = 0; k < 7; k++) {
        final fy = (k + 1.1) / 8 + .05 * (Sketch.hash(i * 17 + k + 630) - .5);
        final y = y0 + depth * fy;
        final target = k == 2 || k == 5 ? band : (k.isEven ? pale : deep);
        var x = xa + h * .01 * Sketch.hash(i * 7 + k + 640);
        var run = 0;
        while (x < xb - h * .01) {
          final xe = math.min(
            xb - h * .006,
            x + h * (.06 + .32 * Sketch.hash(i * 31 + k * 5 + run + 650)),
          );
          double wob(double px) =>
              y + (px - xa) * tilt + h * .0022 * math.sin(px / h * 23 + k * 1.7);
          // Each layer is a lens that thins out at both ends.
          final th = h * (k == 2 || k == 5 ? .0042 : .0016 + .0008 * Sketch.hash(i * 3 + k + run));
          target.moveTo(x, wob(x));
          for (var q = 1; q <= 5; q++) {
            final px = x + (xe - x) * q / 5;
            target.lineTo(px, wob(px) - th * math.sin(math.pi * q / 5));
          }
          for (var q = 4; q >= 1; q--) {
            final px = x + (xe - x) * q / 5;
            target.lineTo(px, wob(px) + th * .5 * math.sin(math.pi * q / 5));
          }
          target.close();
          x = xe + h * (.01 + .05 * Sketch.hash(i * 13 + k * 3 + run + 660));
          run++;
        }
      }
      // The snow cap and the shadow it throws on the ice below.
      double capBottom(double x) =>
          lipAt(x) +
          h * (.0042 + .0028 * (.5 + .5 * math.sin(x / h * 53 + i * 2)) +
              .0016 * (.5 + .5 * math.sin(x / h * 131 + i)));
      c.drawPath(
        _shelfStrip(
          xa,
          xb,
          h,
          top,
          (x) =>
              lipAt(x) +
              h * (.011 + .006 * (.5 + .5 * math.sin(x / h * 37 + i)) +
                  .004 * (.5 + .5 * math.sin(x / h * 89 + i * 2))),
        ),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, y0),
            Offset(0, y0 + h * .022),
            [
              Sketch.fade(const Color(0xff2a5896), .72),
              Sketch.fade(const Color(0xff4c7fb8), 0),
            ],
          ),
      );
      c.drawPath(
        _shelfStrip(xa, xb, h, top, capBottom),
        Paint()..color = _hazed(const Color(0xfffbf3f4), .1 * far),
      );
      // A fringe of icicles under the cap.
      var ic = 0;
      for (var ix = xa + h * .012; ix < xb - h * .01; ix += h * (.018 + .03 * Sketch.hash(i * 41 + ic))) {
        final yt = capBottom(ix) - h * .0008;
        final len = h * (.003 + .009 * Sketch.hash(i * 43 + ic));
        final wd = h * (.002 + .0016 * Sketch.hash(i * 47 + ic));
        icicles
          ..moveTo(ix - wd, yt)
          ..lineTo(ix + wd * .2, yt + len)
          ..lineTo(ix + wd, yt)
          ..close();
        ic++;
      }
    }
    c.drawPath(blue, Paint()..color = Sketch.fade(const Color(0xff3e86c2), .17));
    c.drawPath(icicles, Paint()..color = Sketch.fade(const Color(0xfff2f9ff), .85));
    c.drawPath(band, Paint()..color = Sketch.fade(const Color(0xfff2fbff), .2));
    c.drawPath(pale, Paint()..color = Sketch.fade(const Color(0xfff7fcff), .6));
    c.drawPath(deep, Paint()..color = Sketch.fade(const Color(0xff3f78b2), .4));

    // Hairline cracks stagger down the face.
    final crack = Path(), crackLit = Path();
    for (var i = 0; i < 16; i++) {
      var x = x0 + (x1 - x0) * Sketch.hash(i + 850);
      if (onRamp(x)) continue;
      var y = lipAt(x) + h * .008;
      final end = y + (water - y) * (.3 + .5 * Sketch.hash(i + 851));
      crack.moveTo(x, y);
      crackLit.moveTo(x + h * .0016, y);
      var j = 0;
      while (y < end) {
        y += h * (.006 + .008 * Sketch.hash(i * 11 + j + 852));
        x += h * .008 * (Sketch.hash(i * 11 + j + 853) - .55);
        crack.lineTo(x, y);
        crackLit.lineTo(x + h * .0016, y);
        j++;
      }
    }
    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(.6, h * .0016);
    c.drawPath(crackLit, crackPaint..color = Sketch.fade(const Color(0xffeaf6ff), .45));
    c.drawPath(crack, crackPaint..color = Sketch.fade(const Color(0xff2b5a94), .5));

    // Creases where the panels meet: a shaded edge and a sunlit edge.
    final crease = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i + 1 < panels.length; i++) {
      final x = panels[i].$2;
      final yTop = math.max(lipAt(x - h * .02), lipAt(x + h * .02));
      final lean = h * .01 * (Sketch.hash(i + 700) - .5);
      crease
        ..strokeWidth = h * .003
        ..color = Sketch.fade(const Color(0xff2d5f98), .26);
      c.drawLine(Offset(x + h * .002, yTop + h * .006), Offset(x + lean, water), crease);
      crease
        ..strokeWidth = h * .002
        ..color = Sketch.fade(const Color(0xfffdfeff), .34);
      c.drawLine(Offset(x - h * .002, yTop + h * .006), Offset(x - h * .003 + lean, water), crease);
    }

    // Crevasses: blue slits that fade as they run down from the lip.
    final slits = <(double, double, double)>[
      for (var i = 0; i < 12; i++)
        (
          x0 + (x1 - x0) * Sketch.hash(i + 720),
          .3 + .5 * Sketch.hash(i + 721),
          h * (.0028 + .003 * Sketch.hash(i + 722)),
        ),
      for (var k = -1; k * _shelfSpan * h < x1; k++)
        for (final (at, _, half) in _shelfNotches)
          ((at + k * _shelfSpan) * h, .6, h * half * .22),
    ];
    for (final (x, len, tw) in slits) {
      if (x < x0 || x > x1 || onRamp(x)) continue;
      final yt = lipAt(x) + h * .005;
      final l = (water - yt) * len;
      final fade = Gradient.linear(Offset(x, yt), Offset(x, yt + l), [
        const Color(0xff24548f),
        Sketch.fade(const Color(0xff2f66a3), .7),
        Sketch.fade(const Color(0xff3f7ab5), 0),
      ], const [0, .45, 1]);
      c.drawPath(
        Sketch.poly([
          x - tw, yt, //
          x + tw, yt,
          x + tw * .5, yt + l * .35,
          x + tw * .7, yt + l * .6,
          x + tw * .1, yt + l,
          x - tw * .3, yt + l * .55,
          x - tw * .55, yt + l * .25,
        ]),
        Paint()..shader = fade,
      );
      c.drawPath(
        Path()
          ..moveTo(x + tw, yt)
          ..lineTo(x + tw * .5, yt + l * .35)
          ..lineTo(x + tw * .7, yt + l * .6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(.7, h * .002)
          ..shader = Gradient.linear(Offset(x, yt), Offset(x, yt + l * .6), [
            Sketch.fade(const Color(0xffd6f0fa), .6),
            Sketch.fade(const Color(0xffd6f0fa), 0),
          ]),
      );
    }

    // Sea caves eaten into the foot of the cliff.
    for (var i = 0; i < 7; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(i + 780);
      if (onRamp(x)) continue;
      final wd = h * (.022 + .026 * Sketch.hash(i + 781));
      final ht = h * (.012 + .014 * Sketch.hash(i + 782));
      final arch = Path()
        ..moveTo(x - wd, water + h * .004)
        ..cubicTo(x - wd, water - ht * 1.3, x + wd, water - ht * 1.3, x + wd, water + h * .004)
        ..close();
      c.drawPath(arch, Paint()..color = const Color(0xff1f5f93));
      c.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0022
          ..color = Sketch.fade(const Color(0xffb7ecf4), .7),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(x, water - ht * .1), width: wd * .9, height: ht * .8),
        Paint()..color = const Color(0xff123f6c),
      );
    }

    // The sea-level ice foot and the blocks calved off the front.
    c.drawRect(
      Rect.fromLTRB(x0, water - h * .03, x1, water + h * .01),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, water - h * .03),
          Offset(0, water),
          [
            Sketch.fade(const Color(0xff52c4d8), 0),
            Sketch.fade(const Color(0xff52c4d8), .5),
          ],
        ),
    );
    final footTop = Path()..moveTo(x0, water + h * .01);
    for (var x = x0; x <= x1; x += h * .012) {
      footTop.lineTo(
        x,
        water -
            h * (.004 + .004 * (.5 + .5 * math.sin(x / h * 19 + 1)) +
                .003 * (.5 + .5 * math.sin(x / h * 61))),
      );
    }
    c.drawPath(
      footTop..lineTo(x1, water + h * .01)..close(),
      Paint()..color = const Color(0xffd3e8f5),
    );
    c.drawRect(
      Rect.fromLTRB(x0, water - h * .008, x1, water + h * .004),
      Paint()
        ..shader = Gradient.linear(Offset(0, water - h * .008), Offset(0, water), [
          Sketch.fade(const Color(0xff2a78a8), 0),
          Sketch.fade(const Color(0xff2a78a8), .5),
        ]),
    );
    final blockLit = Paint()..color = const Color(0xfff4f9fd);
    final blockFront = Paint()..color = const Color(0xffa6cfea);
    final blockShade = Paint()..color = const Color(0xff6099c8);
    for (var i = 0; i < 30; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(i + 760);
      final big = Sketch.hash(i + 761);
      final sz = h * (.01 + .026 * big * big);
      final y = water + h * .004;
      final tilt = (Sketch.hash(i + 762) - .5) * .5;
      c.drawPath(
        Sketch.poly([
          -.6, 0, -.55 + tilt * .3, -.7, .5 + tilt * .3, -.78, .62, 0, //
        ], at: Offset(x, y), s: sz),
        blockFront,
      );
      c.drawPath(
        Sketch.poly([.5 + tilt * .3, -.78, .62, 0, .95, 0, .85 + tilt * .2, -.6], at: Offset(x, y), s: sz),
        blockShade,
      );
      c.drawPath(
        Sketch.poly([-.55 + tilt * .3, -.7, -.2 + tilt, -1.02, .8 + tilt * .4, -1.0, .5 + tilt * .3, -.78], at: Offset(x, y), s: sz),
        blockLit,
      );
    }
    // Sea smoke pools at the foot of the cliff.
    c.drawRect(
      Rect.fromLTRB(x0, water - h * .05, x1, water + h * .01),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, water - h * .05),
          Offset(0, water),
          [
            Sketch.fade(const Color(0xffeaf2fb), 0),
            Sketch.fade(const Color(0xffeaf2fb), .26),
          ],
        ),
    );
  }

  // ---------------------------------------------------------------------------
  // Icebergs and the sea (`_berg...`). Every berg is a list of flat planes
  // (tone, polygon) in units of its own scale, waterline at y = 0 and up
  // negative, so the same data draws the berg and its mirrored reflection.

  static const _bergTone = [
    Color(0xfffdefe9), // 0 lit by the low sun
    Color(0xffeff8fe), // 1 snow and upward-facing planes
    Color(0xffd0e5f5), // 2 lit face
    Color(0xffb0cfe9), // 3 face in half light
    Color(0xff93b4dc), // 4 shade
    Color(0xff7396c8), // 5 deep shade
    Color(0xff5fd2d2), // 6 turquoise
  ];

  /// One period of the low band: (kind, x in viewport heights, scale in
  /// viewport heights). Kinds: 0 tabular, 1 pinnacle, 2 arch, 3 flat bergy
  /// bit, 4 tilted bergy bit. Nothing crosses the period's ends.
  static const _bergLayout = [
    (0, .66, .095),
    (1, 1.2, .088),
    (2, 2.34, .086),
    (4, .13, .04),
    (3, 2.02, .045),
  ];

  /// The waterline of the sea band, as a fraction of the viewport height.
  static const _bergWater = .785;

  /// The ice-breaker rides at anchor in the gap under the research station
  /// (the station stands near x = 1.5 - 2.1 h on a 1000 x 450 screen), so no
  /// berg hides it at the start of a run or in Reduced Motion.
  static const _bergShipX = 1.9;

  static const _bergTabular = <(int, List<double>)>[
    (1, [-3.25, -1.25, -1.8, -1.34, -.4, -1.29, 1.2, -1.37, 1.8, -1.34, 2.15, -1.29, 1.8, -1.07, 1.1, -1.08, -.5, -1.02, -1.9, -1.06, -3.4, -1.0]),
    (0, [-3.4, -1.0, -2.95, -1.03, -2.95, .06, -3.4, .06]),
    (2, [-2.95, -1.03, -1.9, -1.06, -1.0, -1.03, -1.18, .06, -2.95, .06]),
    (3, [-1.0, -1.03, -.5, -1.02, 1.1, -1.08, 1.8, -1.07, 1.8, .06, -1.18, .06]),
    (5, [1.8, -1.07, 2.15, -1.29, 2.15, -.93, 1.8, -.9]),
    (1, [1.8, -.9, 2.15, -.93, 2.6, -.97, 3.45, -.88, 3.6, -.74, 3.6, -.72, 1.8, -.72]),
    (4, [1.8, -.72, 2.9, -.74, 3.6, -.72, 3.6, .06, 1.8, .06]),
    (5, [3.3, -.74, 3.6, -.72, 3.6, .06, 3.3, .06]),
    // Wind-drifted snow mounds on the flat top.
    (0, [-2.35, -1.27, -1.75, -1.5, -1.75, -1.3]),
    (4, [-1.75, -1.5, -1.1, -1.31, -1.75, -1.3]),
    (0, [.1, -1.32, .7, -1.47, .7, -1.34]),
    (4, [.7, -1.47, 1.3, -1.36, .7, -1.34]),
  ];

  static const _bergBitFlat = <(int, List<double>)>[
    (1, [-1.2, -.42, -.6, -.55, .5, -.5, 1.15, -.38, 1.2, -.28, .4, -.36, -.7, -.34, -1.25, -.3]),
    (0, [-1.3, -.3, -1.2, -.3, -.7, -.34, -.7, .06, -1.3, .06]),
    (3, [-.7, -.34, .4, -.36, 1.2, -.28, 1.3, -.3, 1.3, .06, -.7, .06]),
    (5, [1.1, -.3, 1.3, -.3, 1.3, .06, 1.1, .06]),
  ];

  static const _bergBitTilt = <(int, List<double>)>[
    (3, [-1.05, .06, -.95, -.5, -.25, -.9, .4, -.5, .5, -.42, 1.0, .06]),
    (0, [-1.05, .06, -.95, -.5, -.25, -.9, -.3, .06]),
    (4, [-.25, -.9, .4, -.5, .5, -.42, 1.0, .06, .25, .06, -.3, .06]),
  ];

  /// A horn of ice: apex, left and right feet, spine foot, seed. Sunlit cap
  /// and lower left, shaded right, slopes broken into facets by seeded kinks.
  static List<(int, List<double>)> _bergHorn(
    double ax,
    double ay,
    double lx,
    double ly,
    double rx,
    double ry,
    double sx,
    int seed,
  ) {
    const y0 = .06;
    double j(int k) => Sketch.hash(seed * 7 + k) - .5;
    final klx = ax + (lx - ax) * .5 + j(1) * .14,
        kly = ay + (ly - ay) * .5 + j(2) * .14;
    final krx = ax + (rx - ax) * .5 + j(3) * .14,
        kry = ay + (ry - ay) * .5 + j(4) * .14;
    final mx = sx + (ax - sx) * .5 + j(5) * .12, my = ay + (y0 - ay) * .5;
    return [
      (3, [lx, y0, lx, ly, klx, kly, ax, ay, krx, kry, rx, ry, rx, y0]),
      (0, [ax, ay, klx, kly, mx, my]),
      (2, [klx, kly, lx, ly, lx, y0, sx, y0, mx, my]),
      (5, [ax, ay, mx, my, krx, kry]),
      (4, [mx, my, sx, y0, rx, y0, rx, ry, krx, kry]),
      // A second break in each slope: a mid-tone lit facet and a deep gully.
      (3, [klx, kly, mx, my, (lx + sx) / 2, y0, lx, y0, lx, ly]),
      (5, [mx, my, (rx + sx) / 2, y0, sx + (rx - sx) * .15, y0]),
    ];
  }

  static final _bergPinnacle = <(int, List<double>)>[
    ..._bergHorn(-1.32, -1.2, -2.3, -.42, -.7, -.9, -1.3, 1),
    ..._bergHorn(1.5, -.98, .9, -.8, 2.4, -.3, 1.55, 2),
    ..._bergHorn(-.3, -2.0, -1.25, -1.0, .7, -.85, -.32, 3),
    ..._bergHorn(.3, -1.62, -.1, -1.0, 1.25, -.8, .34, 4),
  ];

  static const _bergArch = <(int, List<double>)>[
    (3, [-2.0, .06, -2.05, -.5, -1.7, -.95, -1.1, -1.2, -.4, -1.3, .3, -1.35, .9, -1.28, 1.4, -1.05, 1.85, -.6, 1.95, .06]),
    (0, [-2.0, .06, -2.05, -.5, -1.7, -.95, -1.1, -1.2, -.4, -1.3, -.55, -.8, -.5, .06]),
    (1, [-1.7, -.95, -1.1, -1.2, -.4, -1.3, .3, -1.35, .9, -1.28, 1.4, -1.05, .9, -1.0, .2, -1.05, -.5, -1.02, -1.2, -.98]),
    (4, [.85, .06, .9, -.7, 1.3, -.9, 1.85, -.6, 1.95, .06]),
    (5, [1.4, -1.05, 1.85, -.6, 1.95, .06, 1.6, .06, 1.5, -.7]),
  ];

  /// The arch's opening: wave-worn and pointed, wider at the waterline.
  static final _bergHole = () {
    final p = <double>[-.5, .2];
    for (var k = 0; k <= 12; k++) {
      final t = k / 12;
      p
        ..add(-.5 + 1.35 * t)
        ..add(-.78 * math.pow(math.sin(t * math.pi), .75));
    }
    return p..addAll(const [.85, .2]);
  }();

  static List<(int, List<double>)> _bergPlanes(int kind) => switch (kind) {
    0 => _bergTabular,
    1 => _bergPinnacle,
    2 => _bergArch,
    3 => _bergBitFlat,
    _ => _bergBitTilt,
  };

  /// A wavering, broken line in berg units: strata and meltwater seams.
  static Path _bergWavy(Offset at, double s, double x0, double x1, double y, int seed, {double amp = .025, double gap = .2}) {
    final path = Path();
    var x = x0, k = 0;
    while (x < x1) {
      final end = math.min(x1, x + .4 + .9 * Sketch.hash(seed + k * 3));
      if (Sketch.hash(seed + k * 3 + 1) > gap) {
        final ya = y + amp * (Sketch.hash(seed + k * 3 + 2) - .5) * 2;
        final yb = y + amp * (Sketch.hash(seed + k * 3 + 5) - .5) * 2;
        path
          ..moveTo(at.dx + x * s, at.dy + ya * s)
          ..lineTo(at.dx + end * s, at.dy + yb * s);
      }
      x = end + .05 + .12 * Sketch.hash(seed + k * 3 + 4);
      k++;
    }
    return path;
  }

  /// A polyline in berg units.
  static Path _bergLine(Offset at, double s, List<double> xy) {
    final path = Path()..moveTo(at.dx + xy[0] * s, at.dy + xy[1] * s);
    for (var i = 2; i + 1 < xy.length; i += 2) {
      path.lineTo(at.dx + xy[i] * s, at.dy + xy[i + 1] * s);
    }
    return path;
  }

  /// One berg drawn at [at] (its waterline centre) at scale [s].
  static void _berg(Canvas c, int kind, Offset at, double s) {
    final hole = kind == 2 ? Sketch.poly(_bergHole, at: at, s: s) : null;
    var outline = Path();
    for (final (tone, pts) in _bergPlanes(kind)) {
      var p = Sketch.poly(pts, at: at, s: s);
      outline = Path.combine(PathOperation.union, outline, p);
      if (hole != null) p = Path.combine(PathOperation.difference, p, hole);
      c.drawPath(p, Paint()..color = _bergTone[tone]);
    }
    if (hole != null) {
      outline = Path.combine(PathOperation.difference, outline, hole);
    }
    c.save();
    c.clipPath(outline);
    // Ice near the waterline glows turquoise from the submerged mass.
    final glowH = const [.8, 1.2, 1.0, .5, .6][kind] * s;
    c.drawRect(
      Rect.fromLTRB(at.dx - s * 5, at.dy - glowH, at.dx + s * 5, at.dy + s * .1),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, at.dy + s * .1),
          Offset(0, at.dy - glowH),
          [
            Sketch.fade(_bergTone[6], .7),
            Sketch.fade(_bergTone[6], .28),
            Sketch.fade(_bergTone[6], 0),
          ],
          const [0, .4, 1],
        ),
    );
    _bergDetail(c, kind, at, s, hole);
    c.restore();
    c.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(.6, s * .02)
        ..color = Sketch.fade(const Color(0xff6f97c8), .45),
    );
    if (hole != null) {
      // The tunnel's walls: shadowed on the left, catching sun on the right.
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s * .3;
      final mid = at.dx + .175 * s;
      c.save();
      c.clipPath(hole);
      c.drawPath(hole, edge..color = Sketch.fade(_bergTone[4], .9));
      c.save();
      c.clipRect(Rect.fromLTRB(at.dx - s, at.dy - s, mid, at.dy + s));
      c.drawPath(hole, edge..color = Sketch.fade(_bergTone[5], .95));
      c.restore();
      c.save();
      c.clipRect(Rect.fromLTRB(mid, at.dy - s, at.dx + s, at.dy + s));
      c.drawPath(hole, edge..color = Sketch.fade(_bergTone[0], .9));
      c.restore();
      // The vault overhead stays in shade.
      c.clipRect(Rect.fromLTRB(at.dx - s * .3, at.dy - s, at.dx + s * .65, at.dy - s * .6));
      c.drawPath(hole, edge..color = Sketch.fade(_bergTone[4], .95));
      c.restore();
    }
    _bergBase(c, kind, at, s);
  }

  /// Strata, meltwater seams, cracks and rim light, clipped to the berg.
  static void _bergDetail(Canvas c, int kind, Offset at, double s, Path? hole) {
    Paint line(Color color, double a, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(.5, s * w)
      ..color = Sketch.fade(color, a);
    final dark = line(const Color(0xff6f9fd0), kind == 0 ? .42 : .3, .038);
    final light = line(const Color(0xffffffff), .55, .018);
    void strata(double x0, double x1, List<double> ys, int seed) {
      for (var i = 0; i < ys.length; i++) {
        c.drawPath(_bergWavy(at, s, x0, x1, ys[i], seed + i * 17), dark);
        c.drawPath(_bergWavy(at, s, x0, x1, ys[i] + .055, seed + i * 17), light);
      }
    }

    void crack(List<double> xy) {
      final p = _bergLine(at, s, xy);
      c.drawPath(p, line(const Color(0xff5c86b9), .8, .034));
      c.drawPath(p.shift(Offset(s * .03, 0)), line(const Color(0xffffffff), .5, .014));
    }

    if (kind == 0 || kind == 2) {
      // The low sun warms the west end; the east end sinks into shade.
      final x0 = kind == 0 ? -3.4 : -2.05, x1 = kind == 0 ? 3.6 : 1.95;
      c.drawRect(
        Rect.fromLTRB(at.dx + x0 * s, at.dy - 1.6 * s, at.dx + x1 * s, at.dy + .1 * s),
        Paint()
          ..shader = Gradient.linear(
            Offset(at.dx + x0 * s, 0),
            Offset(at.dx + x1 * s, 0),
            [
              Sketch.fade(const Color(0xffffe2d6), .3),
              Sketch.fade(const Color(0xffffe2d6), 0),
              Sketch.fade(const Color(0xff4f7fbd), 0),
              Sketch.fade(const Color(0xff4f7fbd), .22),
            ],
            const [0, .4, .6, 1],
          ),
      );
    }
    switch (kind) {
      case 0:
        strata(-2.95, 1.8, const [-.9, -.74, -.58, -.43, -.29], 10);
        strata(1.85, 3.55, const [-.5, -.36, -.22], 25);
        // The overhanging lip throws a soft shadow down the cliff.
        for (final (x0, x1, y) in const [(-3.0, 1.8, -1.07), (1.8, 3.6, -.73)]) {
          c.drawRect(
            Rect.fromLTRB(at.dx + x0 * s, at.dy + y * s, at.dx + x1 * s, at.dy + (y + .3) * s),
            Paint()
              ..shader = Gradient.linear(
                Offset(0, at.dy + y * s),
                Offset(0, at.dy + (y + .3) * s),
                [Sketch.fade(const Color(0xff4f7fb5), .3), Sketch.fade(const Color(0xff4f7fb5), 0)],
              ),
          );
        }
        // Meltwater has grooved the face into shallow flutes.
        final flute = line(const Color(0xff7aa9d6), .3, .034);
        final fluteLit = line(const Color(0xffffffff), .45, .014);
        for (var i = 0; i < 11; i++) {
          final x = -2.75 + i * .62 + (Sketch.hash(i + 900) - .5) * .3;
          final top = x > 1.8 ? -.72 : -1.02;
          final len = .25 + .5 * Sketch.hash(i + 910);
          c.drawLine(Offset(at.dx + x * s, at.dy + top * s), Offset(at.dx + (x + .03) * s, at.dy + (top + len) * s), flute);
          c.drawLine(Offset(at.dx + (x + .05) * s, at.dy + (top + .02) * s), Offset(at.dx + (x + .08) * s, at.dy + (top + len * .8) * s), fluteLit);
        }
        crack(const [-1.7, -1.05, -1.62, -.85, -1.74, -.66, -1.66, -.4]);
        crack(const [1.4, -1.08, 1.48, -.9, 1.36, -.66, 1.44, -.5, 1.4, -.36]);
        crack(const [2.9, -.72, 2.96, -.55, 2.86, -.4]);
        // Wind-packed sastrugi on the snow top.
        final sastrugi = line(const Color(0xffb6d3ec), .8, .02);
        for (var i = 0; i < 12; i++) {
          final x = -3.1 + i * .56 + Sketch.hash(i + 920) * .3;
          final y = (x > 1.9 ? -.94 : -1.28) + (x > 1.9 ? .14 : .2) * Sketch.hash(i + 930);
          final len = .3 + .45 * Sketch.hash(i + 940);
          c.drawLine(Offset(at.dx + x * s, at.dy + y * s), Offset(at.dx + (x + len) * s, at.dy + (y + .012) * s), sastrugi);
        }
      case 1:
        strata(-2.3, 2.4, const [-.35, -.62, -.9, -1.18], 40);
        crack(const [-.3, -1.7, -.24, -1.35, -.34, -1.05, -.28, -.7]);
        crack(const [.78, -1.0, .7, -.7, .8, -.45]);
        // Rim light along the sunlit edges.
        final rim = line(const Color(0xffffffff), .7, .03);
        for (final (tone, pts) in _bergPinnacle) {
          if (tone == 0 || tone == 2) {
            c.drawLine(Offset(at.dx + pts[0] * s, at.dy + pts[1] * s), Offset(at.dx + pts[2] * s, at.dy + pts[3] * s), rim);
          }
        }
      case 2:
        strata(-2.05, 1.95, const [-.32, -.55, -.78, -1.02], 70);
        crack(const [-1.2, -1.15, -1.28, -.85, -1.18, -.6, -1.26, -.3]);
        crack(const [1.35, -1.0, 1.28, -.75, 1.4, -.5]);
      default:
        strata(-1.0, 1.0, const [-.2], 100 + kind);
    }
  }

  /// Wave-cut caves and the churn of foam along the waterline.
  static void _bergBase(Canvas c, int kind, Offset at, double s) {
    final notch = Paint()..color = Sketch.fade(const Color(0xff2d6aa0), .85);
    final wet = Paint()..color = Sketch.fade(_bergTone[6], .6);
    void cave(double x, double w, double hgt) {
      final path = Path()
        ..moveTo(at.dx + (x - w / 2) * s, at.dy + .06 * s)
        ..cubicTo(at.dx + (x - w / 2) * s, at.dy - hgt * .95 * s, at.dx + (x - w * .3) * s, at.dy - hgt * s, at.dx + x * s, at.dy - hgt * s)
        ..cubicTo(at.dx + (x + w * .3) * s, at.dy - hgt * s, at.dx + (x + w / 2) * s, at.dy - hgt * .95 * s, at.dx + (x + w / 2) * s, at.dy + .06 * s);
      c.drawPath(path, notch);
      c.save();
      c.clipPath(path);
      c.drawRect(Rect.fromLTRB(at.dx + (x - w / 2) * s, at.dy - hgt * .35 * s, at.dx + (x + w / 2) * s, at.dy + .1 * s), wet);
      c.restore();
    }

    final foam = Paint()..color = Sketch.fade(const Color(0xffffffff), .75);
    void surf(double x0, double x1, int seed) {
      final path = Path()
        ..moveTo(at.dx + x0 * s, at.dy + .08 * s)
        ..lineTo(at.dx + x0 * s, at.dy - .03 * s);
      var k = 0;
      for (var x = x0; x < x1; k++) {
        final nx = math.min(x1, x + .1 + .24 * Sketch.hash(seed + k * 2));
        final peak = .015 + .05 * Sketch.hash(seed + k * 2 + 1);
        path.quadraticBezierTo(at.dx + (x + nx) / 2 * s, at.dy + (-.03 - peak * 2) * s, at.dx + nx * s, at.dy - .03 * s);
        x = nx;
      }
      path
        ..lineTo(at.dx + x1 * s, at.dy + .08 * s)
        ..close();
      c.drawPath(path, foam);
    }

    switch (kind) {
      case 0:
        cave(-2.1, .55, .22);
        cave(.5, 1.0, .3);
        cave(2.6, .6, .16);
        surf(-3.4, 3.6, 200);
      case 1:
        cave(-1.7, .5, .18);
        cave(.9, .7, .22);
        surf(-2.3, 2.4, 240);
      case 2:
        cave(-1.2, .6, .2);
        cave(1.5, .5, .18);
        surf(-2.0, -.5, 280);
        surf(.85, 1.95, 300);
      case 3:
        surf(-1.3, 1.3, 320);
      default:
        surf(-1.05, 1.0, 340);
    }
  }

  /// A far ice-breaker at anchor: red hull, white bridge, orange funnel.
  static void _bergShip(Canvas c, Offset at, double s) {
    Color z(int v) => _hazed(Color(v), .3);
    void poly(List<double> xy, Color color) =>
        c.drawPath(Sketch.poly(xy, at: at, s: s), Paint()..color = color);
    poly(const [-2.5, -.95, 2.2, -.95, 2.95, -1.3, 2.6, .14, -2.4, .14], z(0xffb63d2e));
    poly(const [-2.5, -.95, 2.2, -.95, 2.3, -.8, -2.5, -.8], z(0xfff0e6df));
    poly(const [-2.0, -.95, -2.0, -1.75, -.3, -1.75, -.3, -.95], z(0xfff3f5f7));
    poly(const [-.9, -.95, -.9, -1.75, -.3, -1.75, -.3, -.95], z(0xffc6d0df));
    poly(const [-1.9, -1.55, -.4, -1.55, -.4, -1.38, -1.9, -1.38], z(0xff2c3b55));
    poly(const [-1.6, -1.75, -1.6, -2.3, -.5, -2.3, -.5, -1.75], z(0xfff3f5f7));
    poly(const [-1.55, -2.12, -.55, -2.12, -.55, -1.95, -1.55, -1.95], z(0xff2c3b55));
    poly(const [-1.95, -1.75, -1.95, -2.6, -1.4, -2.6, -1.4, -1.75], z(0xffe0703a));
    poly(const [-1.95, -2.6, -1.4, -2.6, -1.4, -2.42, -1.95, -2.42], z(0xff2c3b55));
    poly(const [.15, -.95, .15, -1.35, .75, -1.35, .75, -.95], z(0xff3a6ea5));
    final rig = Paint()
      ..color = z(0xff44526a)
      ..strokeWidth = math.max(.6, s * .09)
      ..strokeCap = StrokeCap.round;
    c.drawLine(at + Offset(-1.05 * s, -2.3 * s), at + Offset(-1.05 * s, -3.3 * s), rig);
    c.drawLine(at + Offset(-1.35 * s, -3.0 * s), at + Offset(-.75 * s, -3.0 * s), rig);
    c.drawLine(at + Offset(1.2 * s, -.95 * s), at + Offset(1.2 * s, -1.9 * s), rig);
    c.drawLine(at + Offset(1.2 * s, -1.9 * s), at + Offset(2.2 * s, -1.35 * s), rig);
  }

  /// A skua hunched on the snow, facing right.
  static void _bergBird(Canvas c, Offset at, double s) {
    final body = Paint()..color = const Color(0xff5b5f6e);
    c.drawOval(Rect.fromCenter(center: at + Offset(0, -s * .1), width: s * .34, height: s * .2), body);
    c.drawPath(Sketch.poly(const [-.16, -.12, -.34, -.08, -.32, -.02, -.12, -.06], at: at, s: s), body);
    c.drawCircle(at + Offset(s * .15, -s * .2), s * .07, body);
    c.drawPath(
      Sketch.poly(const [.2, -.22, .3, -.18, .2, -.16], at: at, s: s),
      Paint()..color = const Color(0xff2c2f3a),
    );
    c.drawPath(
      Sketch.poly(const [-.06, -.17, .04, -.16, -.02, -.08, -.1, -.1], at: at, s: s),
      Paint()..color = const Color(0xff8a8f9e),
    );
  }

  /// A tiny penguin standing on a berg, its belly turned right.
  static void _bergPenguin(Canvas c, Offset at, double s) {
    c.drawOval(Rect.fromCenter(center: at, width: s * .1, height: s * .028), Paint()..color = Sketch.fade(const Color(0xff7d9fcb), .5));
    c.drawOval(Rect.fromCenter(center: at + Offset(0, -s * .1), width: s * .085, height: s * .2), Paint()..color = const Color(0xff2b364c));
    c.drawOval(Rect.fromCenter(center: at + Offset(s * .012, -s * .085), width: s * .045, height: s * .14), Paint()..color = const Color(0xfff6f8f6));
    c.drawCircle(at + Offset(s * .018, -s * .175), s * .012, Paint()..color = const Color(0xfff2b840));
  }

  /// The whole low band for one period: bergs, bits, a far ship, a bird.
  static void _bergField(Canvas c, double h) {
    final wl = h * _bergWater;
    _bergShip(c, Offset(h * _bergShipX, wl), h * .024);
    for (final (kind, x, s) in _bergLayout) {
      _berg(c, kind, Offset(x * h, wl), s * h);
    }
    _bergBird(c, Offset(h * (.66 - .3 * .095), wl - h * .095 * 1.16), h * .095 * .62);
    for (final (dx, dy, k) in const [(2.5, -.83, 1.0), (2.72, -.8, .85), (3.06, -.86, .95)]) {
      _bergPenguin(c, Offset(h * (.66 + dx * .095), wl + dy * h * .095), h * .095 * k);
    }
  }

  // The sea's static detail is built once per viewport into batched paths
  // (indices below) and drawn each frame with a per-frame alpha, so a
  // crossing can fade it without a layer.
  static const _kGlowA = 0,
      _kGlowB = 1,
      _kGlowC = 2,
      _kReflDark = 3,
      _kReflLit = 4,
      _kStrips = 5,
      _kSwellLight = 6,
      _kSwellDark = 7,
      _kPanUnder = 8,
      _kPanTop = 9,
      _kPanInner = 10,
      _kBrash = 11,
      _kFloeUnder = 12,
      _kFloeTop = 13,
      _kWake = 14,
      _kSeal = 15,
      _kSealBelly = 16,
      _kShelfA = 17,
      _kShelfB = 18,
      _kShadow = 19,
      _kKit = 20;

  static final _bergKits = <(double, double), List<Path>>{};

  /// Adds a polygon wound the same way every time, so batched overlapping
  /// shapes union instead of cancelling.
  static void _bergAdd(Path path, List<Offset> pts) {
    var area = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      area += a.dx * b.dy - b.dx * a.dy;
    }
    path.addPolygon(area < 0 ? pts.reversed.toList() : pts, true);
  }

  static List<Path> _bergKit(double h, double span) {
    final key = (h, span);
    final cached = _bergKits[key];
    if (cached != null) return cached;
    if (_bergKits.length > 4) _bergKits.remove(_bergKits.keys.first);
    final p = [for (var i = 0; i < _kKit; i++) Path()];
    final wl = h * _bergWater;
    const ky = .44;
    for (final (kind, x, sc) in _bergLayout) {
      final s = sc * h, cx = x * h;
      Offset mirror(double px, double py) =>
          Offset(cx + px * s, wl + math.max(0.0, -py) * s * ky);
      final hole = kind == 2
          ? (Path()..addPolygon([for (var i = 0; i < _bergHole.length; i += 2) mirror(_bergHole[i], _bergHole[i + 1])], true))
          : null;
      for (final (tone, pts) in _bergPlanes(kind)) {
        var m = Path();
        _bergAdd(m, [for (var i = 0; i < pts.length; i += 2) mirror(pts[i], pts[i + 1])]);
        if (hole != null) m = Path.combine(PathOperation.difference, m, hole);
        p[tone <= 2 ? _kReflLit : _kReflDark].addPath(m, Offset.zero);
      }
      final half = const [3.4, 2.3, 2.0, 1.3, 1.05][kind] * s;
      // The low sun throws each berg's shadow across the water to the right.
      final tall = const [1.3, 2.05, 1.35, .5, .9][kind] * s;
      _bergAdd(p[_kShadow], [Offset(cx - half * .85, wl), Offset(cx + half, wl), Offset(cx + half + tall * 1.2, wl + tall * .13), Offset(cx - half * .85 + tall, wl + tall * .13)]);
      // Submerged ice glows turquoise under the surface.
      final depth = const [1.1, 1.9, 1.5, .5, .7][kind] * s * ky * 1.4;
      for (var g = 0; g < 3; g++) {
        final k = 1 - g * .28;
        p[_kGlowA + g].addOval(Rect.fromCenter(center: Offset(cx, wl), width: half * 2 * k, height: depth * 2 * k));
      }
      // Ripples slice the reflection into wavering bands.
      for (var k = 0; k < (kind < 3 ? 9 : 3); k++) {
        final y = wl + s * ky * (.12 + k * .17 + .06 * Sketch.hash(kind * 20 + k));
        final x0 = cx - half * (1 - .15 * Sketch.hash(kind * 20 + k + 3));
        final x1 = cx + half * (1 - .15 * Sketch.hash(kind * 20 + k + 6));
        p[_kStrips].addRect(Rect.fromLTRB(x0, y, x1, y + s * (.03 + .012 * k)));
      }
      // Brash ice gathers at the foot of the berg.
      if (kind <= 2) {
        for (var k = 0; k < 18; k++) {
          final bx = cx + (Sketch.hash(kind * 50 + k + 800) - .5) * half * 2.3;
          final t = Sketch.hash(kind * 50 + k + 801);
          final by = wl + h * (.006 + .034 * t * t);
          final a = h * (.0025 + .003 * Sketch.hash(kind * 50 + k + 802)), b = a * .5;
          _bergAdd(p[_kBrash], [Offset(bx - a, by), Offset(bx - a * .3, by - b), Offset(bx + a, by - b * .4), Offset(bx + a * .5, by + b * .5)]);
        }
      }
    }
    // The pale foot of the ice shelf mirrors in broken stripes at the far edge.
    for (var r = 0; r < 6; r++) {
      final y = wl + h * (.003 + .0055 * r);
      var x = h * .02 * Sketch.hash(r + 990);
      var k = 0;
      while (x < span - h * .05) {
        final len = h * (.05 + .16 * Sketch.hash(r * 40 + k + 1000));
        final end = math.min(span - h * .02, x + len);
        p[r < 3 ? _kShelfA : _kShelfB].addRect(Rect.fromLTRB(x, y, end, y + h * .0028));
        x = end + h * (.02 + .07 * Sketch.hash(r * 40 + k + 1001) * (r + 1) * .5);
        k++;
      }
    }
    // Swell lines, longer and stronger toward the viewer.
    for (var i = 0; i < 40; i++) {
      final t = Sketch.hash(i * 3 + 501);
      final y = h * (.796 + .082 * t);
      final len = h * (.03 + .09 * t) * (.7 + .6 * Sketch.hash(i * 3 + 502));
      final x = h * .02 + (span - len - h * .04) * Sketch.hash(i * 3 + 503);
      p[i.isEven ? _kSwellLight : _kSwellDark]
        ..moveTo(x, y)
        ..quadraticBezierTo(x + len / 2, y - h * .003 * (t + .3) * 2, x + len, y);
    }
    // Pancake ice: flat discs with raised rims.
    const pans = 38;
    for (var i = 0; i < pans; i++) {
      final x = span * (i + .15 + .7 * Sketch.hash(i * 5 + 601)) / pans;
      final t = Sketch.hash(i * 5 + 602);
      final y = h * (.805 + .05 * t);
      if ((x - 1.33 * h).abs() < .09 * h && y > h * .8) continue;
      final big = Sketch.hash(i * 5 + 604), rx = h * (.004 + .016 * t * big + .008 * big * big), ry = rx * .3;
      p[_kPanUnder].addOval(Rect.fromCenter(center: Offset(x, y + ry * .65), width: rx * 2, height: ry * 2));
      p[_kPanTop].addOval(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2));
      p[_kPanInner].addOval(Rect.fromCenter(center: Offset(x, y + ry * .1), width: rx * 1.5, height: ry * 1.35));
    }
    // Floes.
    void floe(double cx, double cy, double w, int seed) {
      final top = <Offset>[];
      for (var k = 0; k < 9; k++) {
        final a = k / 9 * math.pi * 2;
        final r = 1 + .3 * (Sketch.hash(seed + k) - .5);
        top.add(Offset(cx + math.cos(a) * w * r, cy + math.sin(a) * w * .16 * r));
      }
      _bergAdd(p[_kFloeTop], top);
      _bergAdd(p[_kFloeUnder], [for (final o in top) o.translate(0, w * .07)]);
    }

    floe(1.33 * h, .835 * h, .06 * h, 700);
    floe(.62 * h, .862 * h, .04 * h, 720);
    floe(2.05 * h, .845 * h, .035 * h, 740);
    // A seal hauled out on the big floe.
    final sx = 1.32 * h, sy = .832 * h;
    p[_kSeal]
      ..addOval(Rect.fromCenter(center: Offset(sx, sy - .006 * h), width: .034 * h, height: .013 * h))
      ..addOval(Rect.fromCenter(center: Offset(sx + .017 * h, sy - .0105 * h), width: .012 * h, height: .0105 * h));
    _bergAdd(p[_kSeal], [Offset(sx - .015 * h, sy - .005 * h), Offset(sx - .03 * h, sy - .012 * h), Offset(sx - .028 * h, sy - .003 * h)]);
    p[_kSealBelly].addOval(Rect.fromCenter(center: Offset(sx, sy - .0035 * h), width: .028 * h, height: .005 * h));
    // The ship's wake.
    final shipX = _bergShipX * h;
    _bergAdd(p[_kWake], [Offset(shipX - .075 * h, wl + .002 * h), Offset(shipX - .2 * h, wl + .004 * h), Offset(shipX - .2 * h, wl + .0075 * h), Offset(shipX - .075 * h, wl + .006 * h)]);
    _bergAdd(p[_kWake], [Offset(shipX - .07 * h, wl + .011 * h), Offset(shipX - .16 * h, wl + .013 * h), Offset(shipX - .16 * h, wl + .0155 * h), Offset(shipX - .07 * h, wl + .0135 * h)]);
    return _bergKits[key] = p;
  }

  static final _bergPaint = Paint();

  /// The sea in front of the low band: submerged glow, mirrored bergs,
  /// swell, brash and pancake ice, floes and a seal, and a few glints.
  static void _bergWaterDraw(Canvas c, SceneFrame f, double presence, double span) {
    final h = f.h, wl = h * _bergWater;
    final k = _bergKit(h, span);
    void fill(int i, Color color, double a) {
      _bergPaint
        ..style = PaintingStyle.fill
        ..color = Sketch.fade(color, a * presence);
      c.drawPath(k[i], _bergPaint);
    }

    void stroke(int i, Color color, double a, double w) {
      _bergPaint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.6, h * w)
        ..color = Sketch.fade(color, a * presence);
      c.drawPath(k[i], _bergPaint);
    }

    c.save();
    // Like the bergs, the sea's detail slides down behind the near band while
    // a crossing hands the low band over.
    c.translate(0, (1 - presence) * h * .2);
    c.clipRect(Rect.fromLTRB(-h, wl + math.max(.5, h * .001), span + h, h * 1.3));
    const teal = Color(0xff58d6d0);
    fill(_kShelfA, const Color(0xffdbeaf6), .3);
    fill(_kShelfB, const Color(0xffdbeaf6), .16);
    fill(_kShadow, const Color(0xff1f4570), .22);
    fill(_kGlowA, teal, .14);
    fill(_kGlowB, teal, .12);
    fill(_kGlowC, teal, .1);
    fill(_kReflDark, const Color(0xff7aaad2), .3);
    fill(_kReflLit, const Color(0xffe8f4fc), .25);
    fill(_kStrips, const Color(0xff3a6892), .8);
    stroke(_kSwellDark, const Color(0xff254b74), .5, .0022);
    stroke(_kSwellLight, const Color(0xffa8cdea), .4, .0022);
    fill(_kBrash, const Color(0xffffffff), .85);
    fill(_kWake, const Color(0xffffffff), .7);
    // The floes and pancakes bob a little on the swell.
    c.save();
    c.translate(0, math.sin(f.clock * 1.1) * h * .0012);
    fill(_kFloeUnder, const Color(0xff8ab7dc), .95);
    fill(_kFloeTop, const Color(0xfff2f9fe), 1);
    fill(_kSeal, const Color(0xff56637f), 1);
    fill(_kSealBelly, const Color(0xff9aa7ba), 1);
    c.translate(0, math.sin(f.clock * 1.3 + 2) * h * .0008);
    fill(_kPanUnder, const Color(0xff86b1d8), 1);
    fill(_kPanTop, const Color(0xffe6f3fb), 1);
    fill(_kPanInner, const Color(0xffcbe2f2), 1);
    c.restore();
    // Glints wink on the swell.
    _bergPaint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .003;
    for (var i = 0; i < 14; i++) {
      final on = .5 + .5 * math.sin(f.clock * (1.1 + i * .07) + i * 2.3);
      final t = Sketch.hash(i + 30);
      final len = h * (.008 + .02 * t);
      final x = len + (span - len * 2) * Sketch.hash(i + 31) + math.sin(f.clock * .4 + i) * h * .004;
      final y = wl + h * (.012 + .07 * t);
      _bergPaint.color = Sketch.fade(const Color(0xffcfe9ff), .5 * on * presence);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), _bergPaint);
    }
    c.restore();
  }

  /// The low sun's glitter path and the aurora's green shimmer on the water.
  void _bergSun(Canvas c, SceneFrame f, double presence) {
    final h = f.h, w = f.w;
    final sx = w * light.at.dx;
    final wl = h * _bergWater;
    c.save();
    c.translate(0, (1 - presence) * h * .2);
    // A soft column widening toward the viewer.
    final column = Sketch.poly([
      sx - h * .012, wl + h * .002, sx + h * .012, wl + h * .002, //
      sx + h * .085, h * .9, sx - h * .085, h * .9,
    ]);
    c.drawPath(column, Paint()..color = Sketch.fade(const Color(0xffffd2bc), .09 * presence));
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .0026;
    for (var i = 0; i < 24; i++) {
      final t = (i + .5) / 24;
      final on = .5 + .5 * math.sin(f.clock * 1.6 + i * 1.9);
      glint.color = Sketch.fade(const Color(0xffffdcc8), .6 * on * presence);
      final y = wl + h * (.004 + .1 * t);
      final spread = h * (.012 + .07 * t);
      final x = sx + math.sin(i * 2.1 + f.clock * .5) * spread * .6;
      final len = h * (.006 + .026 * t) * (.4 + .6 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
    // Green and cyan light from the aurora glitters here and there.
    final glow = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .003;
    for (var i = 0; i < 12; i++) {
      final on = .5 + .5 * math.sin(f.clock * .9 + i * 1.7);
      glow.color = Sketch.fade(i.isEven ? const Color(0xff72f0bf) : const Color(0xff8fe6ff), .22 * on * presence);
      final y = wl + h * (.008 + .085 * Sketch.hash(i + 60));
      final x = w * Sketch.hash(i + 61);
      final len = h * (.03 + .07 * Sketch.hash(i + 62));
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glow);
    }
    c.restore();
  }

  // ---------------------------------------------------------------------------
  // The colony: emperor penguins, the orange field hut and the snow under them.
  // Everything sits in front of the near ridge. The still part is recorded once
  // into a Picture per viewport height; walkers, smoke, flag and glints move.

  static const _colonyInk = Color(0xff20283d);
  static const _colonyInkLit = Color(0xff384662);
  static const _colonyFlipper = Color(0xff2b3654);
  static const _colonyRim = Color(0xffffd6c8);
  static const _colonyShade = Color(0xff7d97c8);
  static const _colonySnow = Color(0xfff8fbff);

  /// Penguin poses: (view, lean, head tilt, flipper swing, gait). View 0 is
  /// the side, 1 the front, 2 the back, 3 a chick. Gait 1 waddles, 2 slides.
  static const _colonyPoses = <(int, double, double, double, double)>[
    (0, 0, 0, .1, 0), // 0 upright, looking ahead
    (0, .02, .6, .08, 0), // 1 head bowed
    (0, -.04, -.85, .45, 0), // 2 calling, bill to the sky
    (0, .13, .1, 1.2, 1), // 3 waddling, leaning in
    (0, 1.42, -.7, -.7, 2), // 4 tobogganing on its belly
    (1, 0, 0, .12, 0), // 5 seen from the front
    (1, 0, .6, .12, 0), // 6 from the front, head turned
    (2, 0, 0, .12, 0), // 7 from behind
    (3, 0, 0, 0, 0), // 8 chick
    (0, 1.42, -.35, .05, 2), // 9 dozing on its belly, head lifted
  ];

  /// The still colony, back to front: (world x, depth below the ridge,
  /// height, pose, faces the sun). Heights are in viewport heights.
  static const _colonyCast = [
    // The huddle, three rows deep.
    (.43, .012, .070, 1, false),
    (.49, .012, .074, 0, true),
    (.55, .012, .072, 5, false),
    (.61, .012, .076, 1, true),
    (.67, .012, .071, 0, false),
    (.73, .012, .074, 6, false),
    (.79, .012, .072, 1, false),
    (.85, .012, .070, 0, true),
    (.91, .012, .068, 5, false),
    (.46, .024, .082, 1, false),
    (.53, .024, .080, 5, false),
    (.60, .024, .084, 7, false),
    (.665, .024, .079, 0, true),
    (.73, .024, .083, 1, false),
    (.80, .024, .080, 6, false),
    (.87, .024, .082, 7, false),
    (.93, .024, .078, 0, true),
    (.50, .036, .092, 0, false),
    (.585, .036, .094, 5, false),
    (.66, .036, .090, 1, true),
    (.735, .036, .095, 6, false),
    (.81, .036, .091, 0, false),
    (.885, .036, .093, 1, true),
    (.545, .047, .036, 8, false),
    (.70, .047, .034, 8, false),
    (.85, .047, .035, 8, true),
    // Strays.
    (.27, .03, .09, 2, false),
    (.31, .042, .034, 8, false),
    (.16, .072, .084, 9, false),
    (1.55, .03, .09, 1, false),
    (1.585, .043, .036, 8, true),
    (3.27, .026, .076, 0, true),
  ];

  /// The waddling line: (world x, depth below the ridge, height).
  static const _colonyWalkers = [
    (1.72, .048, .092),
    (1.88, .052, .098),
    (2.04, .046, .090),
    (2.18, .054, .096),
    (2.31, .050, .094),
  ];

  /// Rear rows peeking over the crest: (world x, height, pose, faces the sun).
  static const _colonyRear = [
    (.18, .062, 0, false),
    (.34, .058, 1, true),
    (.62, .066, 7, false),
    (1.12, .06, 0, true),
    (1.2, .064, 1, false),
    (1.62, .058, 7, false),
    (1.98, .066, 0, false),
    (2.06, .06, 1, true),
    (2.36, .058, 7, false),
    (2.92, .064, 0, true),
    (3.3, .06, 1, false),
  ];

  void _colonyOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    // A crossing fades the whole colony as one layer over the bottom strip of
    // the screen (a few seconds, cheaper than fading every shape).
    final fading = presence < .999;
    if (fading) {
      c.saveLayer(
        Rect.fromLTRB(-h, h * .6, period(Depth.near) * h + h, h * 1.05),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
    }
    c.drawPicture(_colonyStill(h));
    _colonyLive(c, h, f.clock, 1);
    if (fading) c.restore();
  }

  static final _colonyStills = <double, Picture>{};

  Picture _colonyStill(double h) {
    final cached = _colonyStills.remove(h);
    if (cached != null) return _colonyStills[h] = cached;
    final recorder = PictureRecorder();
    _colonyScene(Canvas(recorder), h, 1);
    final picture = recorder.endRecording();
    _colonyStills[h] = picture;
    if (_colonyStills.length > 4) {
      _colonyStills.remove(_colonyStills.keys.first)!.dispose();
    }
    return picture;
  }

  /// Rows of penguins behind the crest: only their heads and shoulders show.
  void _colonyBack(Canvas c, Size size) {
    final h = size.height;
    for (final (x, ht, pose, flip) in _colonyRear) {
      _penguin(
        c,
        pose,
        flip,
        Offset(x * h, (ridge(Depth.near, x, 0) + .01) * h),
        h * ht,
        0,
        1,
        shadow: false,
      );
    }
  }

  /// Everything that stands still on the near snow.
  void _colonyScene(Canvas c, double h, double alpha) {
    final span = period(Depth.near);
    _colonyGround(c, h, span, alpha);
    _colonyCamp(c, h, alpha);
    for (final (x, lift, ht, pose, flip) in _colonyCast) {
      _penguin(
        c,
        pose,
        flip,
        Offset(x * h, (ridge(Depth.near, x, 0) + lift) * h),
        h * ht,
        0,
        alpha,
      );
    }
  }

  /// Everything that moves: the waddling line, a slider, smoke, sparkle.
  void _colonyLive(Canvas c, double h, double t, double alpha) {
    for (var i = 0; i < _colonyWalkers.length; i++) {
      final (x, lift, ht) = _colonyWalkers[i];
      final beat = math.sin(t * 4.4 + i * 1.9);
      _penguin(
        c,
        3,
        false,
        Offset(x * h, (ridge(Depth.near, x, 0) + lift) * h - beat.abs() * h * .004),
        h * ht,
        beat * .05,
        alpha,
      );
    }
    _penguin(
      c,
      4,
      false,
      Offset(h * 1.36, (ridge(Depth.near, 1.36, 0) + .075) * h),
      h * .09,
      math.sin(t * 2.3) * .015,
      alpha,
    );
    _colonyCampLive(c, h, t, alpha);
    // Spindrift skims low over the snow, blowing with the wind.
    final span = period(Depth.near) * h;
    final drift = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .004;
    for (var i = 0; i < 7; i++) {
      final ph = (t * .04 + Sketch.hash(i + 900)) % 1;
      final x = span * ph;
      drift.color = Sketch.fade(const Color(0xffffffff), .4 * math.sin(ph * math.pi) * alpha);
      final y = (ridge(Depth.near, x / h, 0) + .02 + .07 * Sketch.hash(i + 910)) * h;
      final len = h * (.05 + .05 * Sketch.hash(i + 920));
      c.drawLine(Offset(x - len, y), Offset(x + len, y - h * .003), drift);
    }
    // Snow crystals twinkle on the drifts.
    final spark = Paint()..color = Sketch.fade(const Color(0xffffffff), alpha);
    for (var i = 0; i < 12; i++) {
      final on = math.sin(t * 2.6 + i * 2.4);
      if (on < .2) continue;
      final x = span * Sketch.hash(i + 70);
      final y =
          ridge(Depth.near, x / h, 0) * h + h * (.012 + .05 * Sketch.hash(i + 71));
      final s = h * .006 * on;
      c.drawPath(
        Sketch.poly([x, y - s, x + s * .25, y, x, y + s, x - s * .25, y]),
        spark,
      );
      c.drawPath(
        Sketch.poly([x - s, y, x, y + s * .25, x + s, y, x, y - s * .25]),
        spark,
      );
    }
  }

  /// Snow texture in front of the ridge: cool shade under the crest, wind
  /// carved sastrugi and drifts, penguin tracks.
  void _colonyGround(Canvas c, double h, double span, double alpha) {
    final crest = Path();
    for (var x = 0.0; x <= span + .001; x += .04) {
      final y = (ridge(Depth.near, x, 0) + .008) * h;
      x == 0 ? crest.moveTo(0, y) : crest.lineTo(x * h, y);
    }
    // Butt caps: round ones would leave a dot at every seam of the repeat.
    c.drawPath(
      crest,
      _colonyLine(const Color(0xffb4c7e6), .34 * alpha, h * .016)
        ..strokeCap = StrokeCap.butt,
    );
    c.drawPath(
      crest,
      _colonyLine(const Color(0xff9db5dc), .22 * alpha, h * .007)
        ..strokeCap = StrokeCap.butt,
    );
    for (var i = 0; i < 34; i++) {
      final x = .12 + (span - .3) * Sketch.hash(i + 500);
      final lift = .016 + .08 * Sketch.hash(i + 540);
      final len = h * (.05 + .12 * Sketch.hash(i + 580)) * (.7 + 4 * lift);
      final y = (ridge(Depth.near, x, 0) + lift) * h;
      _colonyDrift(
        c,
        Offset(x * h, y),
        len,
        len * (.035 + .045 * Sketch.hash(i + 620)),
        alpha,
      );
    }
    // Each walker leaves a zigzag line of footprints behind it.
    final prints = _colonyFill(const Color(0xff93abd6), .42 * alpha);
    for (final (x, lift, _) in _colonyWalkers) {
      final track = Path();
      for (var k = 0; k < 15; k++) {
        final px = x - .05 - .034 * k;
        final py = (ridge(Depth.near, px, 0) + lift) * h;
        track.addOval(
          Rect.fromCenter(
            center: Offset(px * h, py + (k.isEven ? -1 : 1) * h * .0045),
            width: h * .01,
            height: h * .005,
          ),
        );
      }
      c.drawPath(track, prints);
    }
    // The slider's groove in the snow, with a raised lip catching the sun.
    final gy = (ridge(Depth.near, 1.3, 0) + .078) * h;
    for (final (dy, w, color, a) in [
      (.0, .0075, const Color(0xff9db5dc), .6),
      (-.0065, .0035, const Color(0xffffffff), .9),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(h * 1.42, gy + h * (dy - w))
          ..cubicTo(h * 1.2, gy + h * (dy + .012 - w * .6), h * 1.05, gy + h * (dy - .012 - w * .4), h * .88, gy + h * (dy - .003))
          ..cubicTo(h * 1.05, gy + h * (dy - .012 + w * .4), h * 1.2, gy + h * (dy + .012 + w * .6), h * 1.42, gy + h * (dy + w))
          ..close(),
        _colonyFill(color, a * alpha),
      );
    }
    // Boot prints between the hut steps and the walkers' line, and the
    // runner marks of the sled.
    final boots = Path();
    for (var k = 0; k < 18; k++) {
      final f = k / 17;
      final px = 2.9 - .56 * f;
      final py = (ridge(Depth.near, px, 0) + .04 + .03 * f * f) * h;
      boots.addOval(
        Rect.fromCenter(
          center: Offset(px * h, py + (k.isEven ? -1 : 1) * h * .0035),
          width: h * .014,
          height: h * .0065,
        ),
      );
    }
    c.drawPath(boots, _colonyFill(const Color(0xff8aa3d0), .45 * alpha));
    for (final dy in const [.036, .044]) {
      final run = Path()
        ..moveTo(h * 2.57, (ridge(Depth.near, 2.57, 0) + dy) * h)
        ..quadraticBezierTo(
          h * 2.3,
          (ridge(Depth.near, 2.3, 0) + dy + .006) * h,
          h * 2.0,
          (ridge(Depth.near, 2.0, 0) + dy + .012) * h,
        );
      c.drawPath(run, _colonyLine(const Color(0xff9db5dc), .55 * alpha, h * .0032));
    }
  }

  /// A wind-carved ridge of snow: lit on the sun side, shadow to the right.
  static void _colonyDrift(
    Canvas c,
    Offset at,
    double len,
    double rise,
    double alpha,
  ) {
    c.drawPath(
      Path()
        ..moveTo(at.dx - len * .4, at.dy + rise * .2)
        ..quadraticBezierTo(
          at.dx + len * .1,
          at.dy - rise * 1.5,
          at.dx + len * .6,
          at.dy + rise * .5,
        )
        ..quadraticBezierTo(
          at.dx + len * .1,
          at.dy + rise * .6,
          at.dx - len * .4,
          at.dy + rise * .2,
        )
        ..close(),
      _colonyFill(const Color(0xffb9cbe8), .5 * alpha),
    );
    c.drawPath(
      Path()
        ..moveTo(at.dx - len * .5, at.dy)
        ..quadraticBezierTo(
          at.dx - len * .1,
          at.dy - rise * 2,
          at.dx + len * .45,
          at.dy - rise * .1,
        )
        ..quadraticBezierTo(
          at.dx - len * .1,
          at.dy - rise * .5,
          at.dx - len * .5,
          at.dy,
        )
        ..close(),
      _colonyFill(const Color(0xffffffff), .95 * alpha),
    );
  }

  static Paint _colonyFill(Color color, double alpha) =>
      Paint()..color = Sketch.fade(color, alpha);

  static Paint _colonyLine(Color color, double alpha, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..color = Sketch.fade(color, alpha);

  /// Where the field hut stands: world x and depth below the ridge.
  static const _colonyHutX = 2.86, _colonyHutLift = .03;

  Offset _colonyHutBase(double h) => Offset(
    h * _colonyHutX,
    (ridge(Depth.near, _colonyHutX, 0) + _colonyHutLift) * h,
  );

  /// The camp: sled, hut, flag pole, fuel drums and route markers. Drawn in
  /// hut units [u] (a tenth of the viewport height) from the hut's ground.
  void _colonyCamp(Canvas c, double h, double alpha) {
    final base = _colonyHutBase(h), u = h * .108;
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(u);
    // The long twilight shadow of the whole camp, thrown to the right.
    c.drawPath(
      Path()
        ..moveTo(-1.5, -.02)
        ..quadraticBezierTo(1.2, -.16, 4.3, .06)
        ..quadraticBezierTo(1.4, .2, -1.5, .1)
        ..close(),
      _colonyFill(_colonyShade, .3 * alpha),
    );
    _colonySled(c, const Offset(-2.55, .04), alpha);
    _hut(c, alpha);
    _colonyDrum(c, const Offset(2.35, .0), const Color(0xffd4493a), alpha);
    _colonyDrum(c, const Offset(2.72, .07), const Color(0xffe0662f), alpha);
    _colonyDrum(c, const Offset(3.1, .0), const Color(0xff3f78b6), alpha);
    // Flag pole beside the hut; the pennant itself flutters in the live pass.
    c.drawLine(
      const Offset(1.95, .02),
      const Offset(1.95, -1.85),
      _colonyLine(const Color(0xff6c7d92), alpha, .035),
    );
    c.drawCircle(const Offset(1.95, -1.87), .04, _colonyFill(const Color(0xffdfe6f0), alpha));
    // Route markers: bamboo canes with little flags leading off across the ice.
    for (final (x, y, ht) in const [(-3.75, .1, 1.0), (4.6, .06, .9)]) {
      c.drawLine(
        Offset(x, y),
        Offset(x - .03, y - ht),
        _colonyLine(const Color(0xff8a6f52), alpha, .035),
      );
      c.drawPath(
        Sketch.poly([x - .03, y - ht, x + .3, y - ht + .08, x - .03, y - ht + .18]),
        _colonyFill(const Color(0xffd8453a), alpha),
      );
    }
    c.restore();
  }

  /// Chimney smoke, the pennant, the anemometer and a skua on a drum.
  void _colonyCampLive(Canvas c, double h, double t, double alpha) {
    final base = _colonyHutBase(h);
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(h * .108);
    for (var i = 0; i < 4; i++) {
      final ph = (t / 5 + i / 4) % 1;
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(-.73 + ph * 1.5 + math.sin(ph * 6 + i) * .05, -1.97 - ph * .38),
          width: .36 + .8 * ph,
          height: .3 + .55 * ph,
        ),
        const Color(0xff8593b8),
        .7 * math.sin(ph * math.pi) * alpha,
      );
    }
    final w1 = math.sin(t * 4.2) * .05, w2 = math.sin(t * 4.2 - 1.3) * .08;
    c.drawPath(
      Path()
        ..moveTo(1.95, -1.85)
        ..quadraticBezierTo(2.2, -1.87 + w1, 2.5, -1.78 + w2)
        ..quadraticBezierTo(2.22, -1.7 + w1 * .6, 1.95, -1.58)
        ..close(),
      _colonyFill(const Color(0xffd8453a), alpha),
    );
    c.drawPath(
      Path()
        ..moveTo(1.95, -1.72)
        ..quadraticBezierTo(2.22, -1.75 + w1 * .8, 2.5, -1.78 + w2)
        ..quadraticBezierTo(2.22, -1.7 + w1 * .6, 1.95, -1.58)
        ..close(),
      _colonyFill(const Color(0xffa8322e), .7 * alpha),
    );
    final spin = t * 6, cup = _colonyLine(const Color(0xff59657e), alpha, .028);
    for (var k = 0; k < 2; k++) {
      final a = spin + k * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a) * .35) * .1;
      c.drawLine(const Offset(.62, -2.03) - d, const Offset(.62, -2.03) + d, cup);
    }
    // The skua bobs its head on top of a drum.
    c.save();
    c.translate(2.72, -.52);
    c.scale(.8);
    c.rotate(math.sin(t * 1.7) * .05);
    Paint fill(Color color) => _colonyFill(color, alpha);
    c.save();
    c.rotate(-.25);
    c.drawOval(const Rect.fromLTRB(-.25, -.15, .25, .13), fill(const Color(0xff6d5849)));
    c.drawOval(const Rect.fromLTRB(-.2, -.11, .12, .05), fill(const Color(0xff4d3e35)));
    c.drawOval(const Rect.fromLTRB(-.26, -.06, -.12, .0), fill(const Color(0xffefe9e0)));
    c.restore();
    c.drawPath(Sketch.poly(const [-.22, -.06, -.34, -.12, -.3, -.02]), fill(const Color(0xff3e332c)));
    c.drawCircle(const Offset(.2, -.2), .075, fill(const Color(0xff5a4a3f)));
    c.drawPath(Sketch.poly(const [.26, -.23, .37, -.19, .27, -.16]), fill(const Color(0xff20242f)));
    c.restore();
    c.restore();
  }

  static void _hut(Canvas c, double alpha) {
    Paint fill(Color color, [double a = 1]) => _colonyFill(color, alpha * a);
    // Lamplight from the door pools on the snow.
    c.drawOval(const Rect.fromLTRB(-.5, -.02, 1.3, .16), fill(const Color(0xffffcf7a), .14));
    // Legs and the dark gap under the floor.
    c.drawRect(
      const Rect.fromLTRB(-1.28, -.32, 1.45, 0),
      fill(const Color(0xff2b3752), .9),
    );
    for (final x in const [-1.2, -.5, .3, 1.05, 1.32]) {
      c.drawRect(Rect.fromLTWH(x, -.32, .1, .32), fill(const Color(0xff54423a)));
    }
    // Walls: sunlit front, shaded end.
    final face = Path()
      ..moveTo(-1.3, -.3)
      ..lineTo(-1.3, -.95)
      ..cubicTo(-1.3, -1.25, -1.1, -1.4, -.8, -1.4)
      ..lineTo(.95, -1.4)
      ..lineTo(.95, -.3)
      ..close();
    c.drawPath(
      face,
      _colonyGrad(
        const Offset(0, -1.4),
        const Offset(0, -.3),
        const [Color(0xfff2925b), Color(0xffdf6a3b)],
        alpha,
        flat: 1,
      ),
    );
    c.drawPath(
      Path()
        ..moveTo(.95, -.3)
        ..lineTo(.95, -1.4)
        ..lineTo(1.05, -1.4)
        ..cubicTo(1.3, -1.4, 1.45, -1.22, 1.45, -.95)
        ..lineTo(1.45, -.3)
        ..close(),
      fill(const Color(0xffb5502f)),
    );
    // Corrugated cladding reads as fine vertical ribs.
    final ribs = Path(), glints = Path();
    for (var x = -1.25; x < 1.4; x += .085) {
      final top = x < -.85 ? -.9 : -1.15;
      ribs
        ..moveTo(x, -.32)
        ..lineTo(x, top);
      glints
        ..moveTo(x + .03, -.32)
        ..lineTo(x + .03, top);
    }
    c.drawPath(ribs, _colonyLine(const Color(0xffa64428), .22 * alpha, .02));
    c.drawPath(glints, _colonyLine(const Color(0xffffb98a), .14 * alpha, .015));
    // A seam where the wall panels meet the roof.
    c.drawLine(
      const Offset(-1.3, -.62),
      const Offset(1.45, -.62),
      _colonyLine(const Color(0xff8e3a25), .3 * alpha, .022),
    );
    c.drawLine(
      const Offset(-1.285, -.32),
      const Offset(-1.285, -.95),
      _colonyLine(_colonyRim, .75 * alpha, .03),
    );
    // Warm light spilling from two portholes.
    for (final x in const [-.86, -.36]) {
      c.drawCircle(Offset(x, -.78), .34, fill(const Color(0xffffcf7a), .13));
      c.drawCircle(Offset(x, -.78), .175, fill(const Color(0xff3b4a63)));
      c.drawCircle(Offset(x, -.78), .135, fill(const Color(0xffffd98c)));
      c.drawCircle(Offset(x - .04, -.82), .05, fill(const Color(0xffffefc4), .8));
    }
    // The door, with a lamp over it.
    c.drawRect(const Rect.fromLTRB(.1, -1.0, .7, -.3), fill(const Color(0xff8a3d2b)));
    c.drawRect(const Rect.fromLTRB(.15, -.95, .65, -.3), fill(const Color(0xff2d3d55)));
    c.drawRect(const Rect.fromLTRB(.22, -.88, .58, -.66), fill(const Color(0xffffd788), .9));
    c.drawLine(const Offset(.4, -.88), const Offset(.4, -.66), _colonyLine(const Color(0xff2d3d55), alpha, .025));
    c.drawRect(const Rect.fromLTRB(.53, -.55, .6, -.5), fill(const Color(0xffcfd6e3)));
    c.drawCircle(const Offset(.4, -1.1), .18, fill(const Color(0xffffcf7a), .16));
    c.drawCircle(const Offset(.4, -1.1), .035, fill(const Color(0xffffe9b0)));
    // Steps with a dusting of snow.
    for (final (x0, x1, y) in const [(.0, .8, -.17), (-.07, .88, -.06)]) {
      c.drawRect(Rect.fromLTRB(x0, y, x1, y + .07), fill(const Color(0xff7c5946)));
      c.drawRect(Rect.fromLTRB(x0, y - .02, x1, y + .02), fill(const Color(0xfff2f6fc)));
    }
    // Snow heaped along the roof, thick on the windward side and dripping
    // over the eaves.
    final cap = Path()
      ..moveTo(-1.34, -.98)
      ..cubicTo(-1.36, -1.3, -1.12, -1.46, -.8, -1.46)
      ..lineTo(1.05, -1.46)
      ..cubicTo(1.36, -1.46, 1.5, -1.28, 1.5, -1.0);
    final hem = Path()..moveTo(1.5, -1.0);
    var px = 1.5, py = -1.0;
    for (final (x, y) in const [
      (1.3, -1.12),
      (1.12, -1.03),
      (.9, -1.14),
      (.62, -1.08),
      (.35, -1.2),
      (.1, -1.07),
      (-.2, -1.16),
      (-.5, -1.1),
      (-.78, -1.22),
      (-1.05, -1.06),
      (-1.34, -.98),
    ]) {
      final q = Offset((px + x) / 2, math.max(py, y) + .07);
      cap.quadraticBezierTo(q.dx, q.dy, x, y);
      hem.quadraticBezierTo(q.dx, q.dy, x, y);
      px = x;
      py = y;
    }
    // The chimney stands behind the snow.
    c.drawRect(const Rect.fromLTRB(-.82, -1.86, -.64, -1.3), fill(const Color(0xff414a5e)));
    c.drawRect(const Rect.fromLTRB(-.82, -1.86, -.77, -1.3), fill(const Color(0xff7a86a0)));
    c.drawRect(const Rect.fromLTRB(-.88, -1.9, -.58, -1.84), fill(const Color(0xff2f3648)));
    c.drawOval(const Rect.fromLTRB(-.87, -1.93, -.59, -1.86), fill(_colonySnow));
    c.drawPath(hem.shift(const Offset(0, .075)), _colonyLine(const Color(0xffa8452a), .32 * alpha, .12));
    c.drawPath(cap..close(), fill(const Color(0xfffbfdff)));
    c.save();
    c.clipRect(const Rect.fromLTRB(.95, -1.6, 1.6, -.9));
    c.drawPath(cap, fill(const Color(0xffd0dff3)));
    c.restore();
    c.drawPath(hem, _colonyLine(const Color(0xff9db7de), .55 * alpha, .03));
    // Antenna mast with cross arms on the roof.
    final mast = _colonyLine(const Color(0xff59657e), alpha, .03);
    c.drawLine(const Offset(.62, -1.42), const Offset(.62, -2.0), mast);
    c.drawLine(const Offset(.46, -1.74), const Offset(.78, -1.74), mast);
    c.drawLine(const Offset(.52, -1.88), const Offset(.72, -1.88), mast);
    // A small window on the shaded end wall.
    c.drawRect(const Rect.fromLTRB(1.1, -.9, 1.34, -.68), fill(const Color(0xff5c2f2a)));
    c.drawRect(const Rect.fromLTRB(1.13, -.87, 1.31, -.71), fill(const Color(0xffe6ad62), .9));
    // A low lee drift trailing away from the end wall.
    c.drawPath(
      Path()
        ..moveTo(1.1, .06)
        ..cubicTo(1.4, -.02, 1.75, -.1, 2.1, -.03)
        ..cubicTo(2.4, .02, 2.7, .05, 3.2, .08)
        ..lineTo(1.1, .09)
        ..close(),
      fill(const Color(0xffd6e2f4)),
    );
    c.drawPath(
      Path()
        ..moveTo(1.1, .05)
        ..cubicTo(1.4, -.03, 1.75, -.11, 2.1, -.045)
        ..cubicTo(1.8, -.06, 1.4, .0, 1.1, .05)
        ..close(),
      fill(const Color(0xfffffaf6), .95),
    );
    // Skis and poles leaning against the end wall.
    for (final (x0, x1, color) in const [
      (1.7, 1.52, Color(0xff2f4c78)),
      (1.78, 1.6, Color(0xffc8483a)),
    ]) {
      c.drawLine(Offset(x0, .02), Offset(x1, -1.22), _colonyLine(color, alpha, .055));
      c.drawLine(Offset(x0 - .01, .0), Offset(x1 - .012, -1.1), _colonyLine(_colonyRim, .5 * alpha, .014));
    }
    for (final (x0, x1) in const [(1.86, 1.66), (1.92, 1.72)]) {
      c.drawLine(Offset(x0, .03), Offset(x1, -1.05), _colonyLine(const Color(0xffdde3ee), .9 * alpha, .02));
      c.drawCircle(Offset(x0 - .015, -.1), .04, _colonyLine(const Color(0xff7d8aa2), .8 * alpha, .014));
    }
    // Windward drift piled against the wall, cool on its lee side.
    c.drawPath(
      Path()
        ..moveTo(-2.4, .03)
        ..cubicTo(-2.0, .02, -1.75, -.16, -1.45, -.36)
        ..cubicTo(-1.25, -.46, -1.05, -.36, -.85, -.2)
        ..cubicTo(-.65, -.08, -.3, .0, .2, .05)
        ..close(),
      fill(const Color(0xffcddcf0)),
    );
    c.drawPath(
      Path()
        ..moveTo(-2.4, .01)
        ..cubicTo(-2.0, -.01, -1.75, -.17, -1.45, -.37)
        ..cubicTo(-1.3, -.45, -1.2, -.4, -1.12, -.33)
        ..cubicTo(-1.45, -.22, -1.9, -.06, -2.4, .01)
        ..close(),
      fill(const Color(0xfffffaf6)),
    );
  }

  static void _colonySled(Canvas c, Offset at, double alpha) {
    Paint fill(Color color, [double a = 1]) => _colonyFill(color, alpha * a);
    const wood = Color(0xff9c6b47), dark = Color(0xff5d3f2f), lit = Color(0xffc99a6c);
    c.save();
    c.translate(at.dx, at.dy);
    // Runner, stanchions and deck of a wooden sledge, prow curled up.
    final rail = Path()
      ..moveTo(-.7, -.08)
      ..lineTo(.55, -.08)
      ..quadraticBezierTo(.8, -.08, .8, -.28);
    c.drawPath(rail, _colonyLine(dark, alpha, .075));
    c.drawPath(rail.shift(const Offset(0, -.03)), _colonyLine(lit, .6 * alpha, .022));
    for (final x in const [-.55, -.2, .15, .5]) {
      c.drawLine(Offset(x, -.08), Offset(x, -.27), _colonyLine(dark, alpha, .055));
    }
    c.drawRect(const Rect.fromLTRB(-.72, -.34, .7, -.27), fill(wood));
    c.drawRect(const Rect.fromLTRB(-.72, -.34, .7, -.32), fill(lit));
    // A wooden crate and a lashed blue duffel.
    c.drawRect(const Rect.fromLTRB(-.58, -.74, .04, -.34), fill(const Color(0xffc59a68)));
    c.drawRect(const Rect.fromLTRB(-.58, -.74, -.5, -.34), fill(const Color(0xffe0b884), .8));
    for (final y in const [-.6, -.47]) {
      c.drawLine(Offset(-.58, y), Offset(.04, y), _colonyLine(const Color(0xff8a6440), .55 * alpha, .018));
    }
    c.drawLine(const Offset(-.58, -.74), const Offset(.04, -.34), _colonyLine(const Color(0xff8a6440), .5 * alpha, .02));
    c.drawRRect(
      RRect.fromLTRBR(.1, -.68, .66, -.34, const Radius.circular(.13)),
      fill(const Color(0xff3d6f99)),
    );
    c.drawOval(const Rect.fromLTRB(.14, -.66, .4, -.52), fill(const Color(0xff6a9cc6), .7));
    for (final x in const [.28, .5]) {
      c.drawLine(Offset(x, -.68), Offset(x, -.34), _colonyLine(const Color(0xffe9dcc0), .85 * alpha, .03));
    }
    c.drawLine(const Offset(-.6, -.36), const Offset(.68, -.62), _colonyLine(const Color(0xffe8d7b0), .8 * alpha, .02));
    // Snow on the load.
    c.drawPath(
      Path()
        ..moveTo(-.6, -.72)
        ..quadraticBezierTo(-.3, -.86, .06, -.72)
        ..quadraticBezierTo(-.3, -.68, -.6, -.72)
        ..close(),
      fill(const Color(0xfffbfdff)),
    );
    c.drawPath(
      Path()
        ..moveTo(.12, -.66)
        ..quadraticBezierTo(.38, -.8, .64, -.66)
        ..quadraticBezierTo(.38, -.6, .12, -.66)
        ..close(),
      fill(const Color(0xfffbfdff)),
    );
    c.restore();
  }

  static void _colonyDrum(Canvas c, Offset at, Color body, double alpha) {
    Paint fill(Color color, [double a = 1]) => _colonyFill(color, alpha * a);
    final lit = Sketch.mix(body, const Color(0xffffffff), .35);
    final shade = Sketch.mix(body, const Color(0xff1c2340), .4);
    c.save();
    c.translate(at.dx, at.dy);
    c.drawRect(const Rect.fromLTRB(-.17, -.5, .17, 0), fill(body));
    c.drawOval(const Rect.fromLTRB(-.17, -.045, .17, .045), fill(body));
    c.drawRect(const Rect.fromLTRB(-.17, -.5, -.1, 0), fill(lit, .75));
    c.drawRect(const Rect.fromLTRB(.07, -.5, .17, 0), fill(shade, .7));
    for (final y in const [-.34, -.18]) {
      c.drawArc(
        Rect.fromLTRB(-.17, y - .035, .17, y + .035),
        0,
        3.14,
        false,
        _colonyLine(shade, .8 * alpha, .022),
      );
    }
    c.drawOval(const Rect.fromLTRB(-.17, -.545, .17, -.455), fill(lit));
    c.drawCircle(const Offset(.07, -.5), .022, fill(shade));
    c.drawOval(const Rect.fromLTRB(-.15, -.535, .1, -.475), fill(_colonySnow, .95));
    c.restore();
  }

  static final _colonyPoseCache = <int, Picture>{};

  static Picture _colonyPose(int pose, bool flip) {
    return _colonyPoseCache.putIfAbsent(pose * 2 + (flip ? 1 : 0), () {
      final recorder = PictureRecorder();
      _colonyBody(Canvas(recorder), pose, flip, 1);
      return recorder.endRecording();
    });
  }

  /// One penguin standing at [base], [s] tall (a chick's [s] is its own
  /// height), rocked by [rot] about its feet; [flip] faces the sun.
  static void _penguin(
    Canvas c,
    int pose,
    bool flip,
    Offset base,
    double s,
    double rot,
    double alpha, {
    bool shadow = true,
  }) {
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(s);
    if (shadow) {
      // The low sun throws a long blue shadow across the snow.
      final long = pose == 4 ? .8 : 1.0;
      c.drawPath(
        Path()
          ..moveTo(-.24, -.006)
          ..quadraticBezierTo(.6 * long, -.1, 1.55 * long, .02)
          ..quadraticBezierTo(.55 * long, .075, -.24, .03)
          ..close(),
        _colonyFill(_colonyShade, .3 * alpha),
      );
      c.drawOval(
        const Rect.fromLTRB(-.3, -.03, .32, .04),
        _colonyFill(const Color(0xff7c95c4), .32 * alpha),
      );
    }
    c.rotate(rot);
    if (alpha >= .999) {
      c.drawPicture(_colonyPose(pose, flip));
    } else {
      _colonyBody(c, pose, flip, alpha);
    }
    c.restore();
  }

  static void _colonyBody(Canvas c, int pose, bool flip, double alpha) {
    final p = _colonyPoses[pose];
    switch (p.$1) {
      case 0:
        c.save();
        if (flip) c.scale(-1, 1);
        _colonySide(c, p, flip, alpha);
        c.restore();
      case 1:
        _colonyFront(c, p, flip, alpha);
      case 2:
        _colonyRearView(c, alpha);
      default:
        _colonyChick(c, flip, alpha);
    }
  }

  static final _colonyTorso = Path()
    ..moveTo(-.14, -.01)
    ..cubicTo(-.28, -.16, -.3, -.5, -.16, -.74)
    ..cubicTo(-.12, -.81, -.08, -.85, -.03, -.88)
    ..lineTo(.09, -.88)
    ..cubicTo(.13, -.8, .27, -.64, .27, -.42)
    ..cubicTo(.27, -.22, .23, -.08, .15, -.01)
    ..quadraticBezierTo(0, .02, -.14, -.01)
    ..close();

  /// The white front of a side-on penguin, hugging the torso's front edge.
  static final _colonyBellyPath = Path()
    ..moveTo(-.02, -.88)
    ..lineTo(.095, -.88)
    ..cubicTo(.136, -.8, .277, -.64, .277, -.42)
    ..cubicTo(.277, -.22, .237, -.08, .155, -.005)
    ..quadraticBezierTo(.05, .012, -.06, -.004)
    ..cubicTo(-.16, -.24, -.16, -.6, -.02, -.88)
    ..close();

  static final _colonyFrontTorso = Path()
    ..moveTo(-.14, -.01)
    ..cubicTo(-.3, -.14, -.3, -.55, -.09, -.8)
    ..lineTo(.09, -.8)
    ..cubicTo(.3, -.55, .3, -.14, .14, -.01)
    ..quadraticBezierTo(0, .02, -.14, -.01)
    ..close();

  static final _colonyFlipperPath = Path()
    ..moveTo(-.02, -.01)
    ..cubicTo(.05, .06, .06, .24, .025, .38)
    ..cubicTo(-.03, .3, -.07, .14, -.05, -.01)
    ..close();

  /// A gradient fill. While a crossing fades the colony (alpha below one) it
  /// falls back to the flat colour at [flat], so no shaders are built per frame.
  static Paint _colonyGrad(
    Offset from,
    Offset to,
    List<Color> colors,
    double alpha, {
    List<double>? stops,
    int flat = 0,
  }) => alpha < .999
      ? _colonyFill(colors[flat], alpha)
      : (Paint()
          ..shader = Gradient.linear(from, to, [
            for (final color in colors) Sketch.fade(color, alpha),
          ], stops));

  static void _colonySide(
    Canvas c,
    (int, double, double, double, double) pose,
    bool sunny,
    double alpha,
  ) {
    final (_, lean, tilt, arm, gait) = pose;
    Paint fill(Color color, [double a = 1]) => _colonyFill(color, alpha * a);
    c.save();
    if (gait == 2) c.translate(0, -.25);
    c.rotate(lean);
    // Tail prop and feet.
    c.drawPath(
      Sketch.poly(const [-.14, -.1, -.27, 0, -.06, -.01]),
      fill(const Color(0xff1a2136)),
    );
    final foot = fill(const Color(0xff2a2f40));
    if (gait == 1) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(-.12, -.012), width: .15, height: .05),
        foot,
      );
      c.save();
      c.translate(.2, -.06);
      c.rotate(-.5);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: .14, height: .045), foot);
      c.restore();
    } else {
      for (final x in const [-.06, .13]) {
        c.drawOval(
          Rect.fromCenter(center: Offset(x, -.012), width: .14, height: .05),
          foot,
        );
      }
    }
    // The far flipper, when the bird holds them out.
    if (gait > 0) {
      c.save();
      c.translate(-.1, -.66);
      c.rotate(arm + .3);
      c.drawPath(_colonyFlipperPath, fill(const Color(0xff1b2338)));
      c.restore();
    }
    c.drawPath(_colonyTorso, fill(_colonyInk));
    if (!sunny) {
      // The low sun grazes the back.
      c.drawPath(
        Path()
          ..moveTo(-.14, -.03)
          ..cubicTo(-.28, -.16, -.3, -.5, -.16, -.74)
          ..cubicTo(-.12, -.81, -.08, -.85, -.05, -.87)
          ..cubicTo(-.2, -.6, -.2, -.3, -.09, -.03)
          ..close(),
        fill(_colonyInkLit),
      );
    }
    // White belly, cool where it turns from the light and warm where it faces it.
    c.drawPath(
      _colonyBellyPath,
      _colonyGrad(
        const Offset(-.1, 0),
        const Offset(.27, 0),
        sunny
            ? const [Color(0xffe4ebf6), Color(0xffeef2f9), Color(0xfffff0e6)]
            : const [Color(0xfff1f4fa), Color(0xffe4ebf6), Color(0xffbccbe4)],
        alpha,
        stops: const [0, .55, 1],
        flat: 1,
      ),
    );
    // Straw-yellow breast fading down into the white.
    c.drawPath(
      _colonyBellyPath,
      _colonyGrad(
        const Offset(0, -.84),
        const Offset(0, -.5),
        const [Color(0xfff9cf52), Color(0xfffbe39a), Color(0x00fbeebb)],
        alpha * .92,
        stops: const [0, .35, 1],
        flat: 2,
      ),
    );
    // Rim light along the edge that faces the sun.
    c.drawPath(
      sunny
          ? (Path()
              ..moveTo(.08, -.86)
              ..cubicTo(.14, -.79, .258, -.63, .258, -.42)
              ..cubicTo(.258, -.24, .22, -.09, .145, -.03))
          : (Path()
              ..moveTo(-.135, -.05)
              ..cubicTo(-.265, -.18, -.285, -.5, -.15, -.73)),
      _colonyLine(_colonyRim, .8 * alpha, .02),
    );
    // Near flipper hangs over the line between black back and white front.
    c.save();
    c.translate(-.12, -.68);
    c.rotate(arm + .08);
    c.drawPath(_colonyFlipperPath, fill(_colonyFlipper));
    c.drawPath(
      Path()
        ..moveTo(.03, .04)
        ..cubicTo(.055, .1, .058, .24, .028, .36),
      _colonyLine(const Color(0xffe6ecf6), .75 * alpha, .012),
    );
    c.restore();
    // Head: black cap, golden ear patch, long bill with a pink stripe.
    c.save();
    c.translate(.03, -.84);
    c.rotate(tilt);
    c.drawOval(
      Rect.fromCenter(center: const Offset(.02, -.075), width: .2, height: .19),
      fill(_colonyInk),
    );
    c.drawPath(
      Path()
        ..moveTo(.09, -.115)
        ..lineTo(.22, -.108)
        ..quadraticBezierTo(.285, -.098, .295, -.045)
        ..lineTo(.23, -.07)
        ..lineTo(.09, -.07)
        ..close(),
      fill(const Color(0xff3d4353)),
    );
    c.drawPath(
      Sketch.poly(const [.09, -.07, .23, -.07, .255, -.05, .09, -.038]),
      fill(const Color(0xfff08a70)),
    );
    c.save();
    c.translate(-.012, -.035);
    c.rotate(.5);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: .052, height: .15),
      fill(const Color(0xfff7c440)),
    );
    c.restore();
    if (!sunny) {
      c.drawArc(
        Rect.fromCenter(center: const Offset(.02, -.075), width: .195, height: .185),
        3.3,
        1.5,
        false,
        _colonyLine(_colonyRim, .7 * alpha, .014),
      );
    }
    c.restore();
    c.restore();
  }

  static void _colonyFront(
    Canvas c,
    (int, double, double, double, double) pose,
    bool flip,
    double alpha,
  ) {
    final (_, _, turn, arm, _) = pose;
    Paint fill(Color color, [double a = 1]) => _colonyFill(color, alpha * a);
    final foot = fill(const Color(0xff2a2f40));
    for (final x in const [-.1, .1]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, -.014), width: .15, height: .055),
        foot,
      );
    }
    c.drawPath(_colonyFrontTorso, fill(_colonyInk));
    // Belly: sunlit on the left, cool on the right, with a golden collar.
    final belly = Path()
      ..moveTo(-.1, -.8)
      ..lineTo(.1, -.8)
      ..cubicTo(.2, -.62, .26, -.34, .17, -.01)
      ..quadraticBezierTo(0, .015, -.17, -.01)
      ..cubicTo(-.26, -.34, -.2, -.62, -.1, -.8)
      ..close();
    c.drawPath(
      belly,
      _colonyGrad(
        const Offset(-.27, 0),
        const Offset(.27, 0),
        const [Color(0xfffff1ea), Color(0xffeef3fa), Color(0xffc3d1e8)],
        alpha,
        stops: const [0, .45, 1],
        flat: 1,
      ),
    );
    c.drawPath(
      belly,
      _colonyGrad(
        const Offset(0, -.8),
        const Offset(0, -.5),
        const [Color(0xfff9cf52), Color(0xfffbe39a), Color(0x00fbeebb)],
        alpha * .92,
        stops: const [0, .35, 1],
        flat: 2,
      ),
    );
    c.drawPath(
      Path()
        ..moveTo(-.265, -.4)
        ..cubicTo(-.29, -.55, -.24, -.7, -.1, -.79),
      _colonyLine(_colonyRim, .7 * alpha, .02),
    );
    // Flippers hang at the sides.
    for (final side in const [-1.0, 1.0]) {
      c.save();
      c.translate(side * .25, -.68);
      c.scale(side, 1);
      c.rotate(.08 + arm * .5);
      c.drawPath(_colonyFlipperPath, fill(_colonyFlipper));
      c.restore();
    }
    // Head with two golden ear patches running down into the collar.
    final hx = turn * .035;
    c.drawOval(
      Rect.fromCenter(center: Offset(hx, -.91), width: .2, height: .19),
      fill(_colonyInk),
    );
    for (final side in const [-1.0, 1.0]) {
      c.save();
      c.translate(hx + side * .072, -.86);
      c.rotate(side * .3);
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: .046, height: .13),
        fill(const Color(0xfff7c440)),
      );
      c.restore();
    }
    c.drawPath(
      Sketch.poly([hx - .026, -.925, hx + .026, -.925, hx + turn * .02, -.83]),
      fill(const Color(0xff3d4353)),
    );
    c.drawPath(
      Sketch.poly([hx - .01, -.885, hx + .01, -.885, hx + turn * .02, -.835]),
      fill(const Color(0xfff08a70)),
    );
    c.drawArc(
      Rect.fromCenter(center: Offset(hx, -.91), width: .195, height: .185),
      3.4,
      1.4,
      false,
      _colonyLine(_colonyRim, .6 * alpha, .014),
    );
  }

  static void _colonyRearView(Canvas c, double alpha) {
    Paint fill(Color color, [double a = 1]) => _colonyFill(color, alpha * a);
    for (final x in const [-.1, .1]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, -.014), width: .15, height: .055),
        fill(const Color(0xff2a2f40)),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(-.16, -.01)
        ..cubicTo(-.32, -.14, -.32, -.6, -.09, -.8)
        ..lineTo(.09, -.8)
        ..cubicTo(.32, -.6, .32, -.14, .16, -.01)
        ..close(),
      fill(_colonyInk),
    );
    // Sun-grazed left shoulder and a paler sheen down the back.
    c.drawPath(
      Path()
        ..moveTo(-.15, -.03)
        ..cubicTo(-.3, -.15, -.3, -.58, -.1, -.78)
        ..lineTo(-.03, -.78)
        ..cubicTo(-.21, -.58, -.21, -.2, -.07, -.03)
        ..close(),
      fill(_colonyInkLit, .9),
    );
    c.drawPath(
      Path()
        ..moveTo(-.29, -.45)
        ..cubicTo(-.3, -.6, -.22, -.72, -.1, -.79),
      _colonyLine(_colonyRim, .6 * alpha, .02),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -.91), width: .2, height: .19),
      fill(_colonyInk),
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(0, -.91), width: .195, height: .185),
      3.4,
      1.4,
      false,
      _colonyLine(_colonyRim, .6 * alpha, .014),
    );
    for (final side in const [-1.0, 1.0]) {
      c.save();
      c.translate(side * .26, -.68);
      c.scale(side, 1);
      c.rotate(.08);
      c.drawPath(_colonyFlipperPath, fill(_colonyFlipper));
      c.restore();
    }
  }

  static void _colonyChick(Canvas c, bool flip, double alpha) {
    Paint fill(Color color, [double a = 1]) => _colonyFill(color, alpha * a);
    c.save();
    if (flip) c.scale(-1, 1);
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -.33), width: .78, height: .66),
      fill(const Color(0xffa5b0c4)),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.1, -.36), width: .4, height: .5),
      fill(const Color(0xffcfd8e6), .8),
    );
    c.drawCircle(const Offset(.06, -.78), .22, fill(const Color(0xff2d3442)));
    c.drawOval(
      Rect.fromCenter(center: const Offset(.12, -.78), width: .28, height: .22),
      fill(const Color(0xfff2f4f8)),
    );
    c.drawCircle(const Offset(.16, -.8), .035, fill(const Color(0xff10141c)));
    c.drawPath(
      Sketch.poly(const [.22, -.76, .36, -.72, .22, -.68]),
      fill(const Color(0xff2d3140)),
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(0, -.33), width: .78, height: .66),
      2.4,
      1.5,
      false,
      _colonyLine(_colonyRim, .6 * alpha, .05),
    );
    c.restore();
  }
}
