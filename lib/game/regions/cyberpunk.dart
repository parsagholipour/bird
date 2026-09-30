import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// Cyberpunk City: a sleek, vertical megacity at night. Arcology spires
/// with antenna crowns and vertical light strips rise out of a violet haze
/// under an orbital ring and a pale moon, one needle silhouetted against it;
/// flying traffic and an advertising airship cross the sky. A space-elevator
/// arcology splits open around a core of light, its tether climbing into
/// the sky and a holographic koi circling it, while a maglev glides past
/// giant screens. Below, an elevated freeway and neon-signed canal fronts
/// pour colour into the water, and the near rooftops carry dishes, fans,
/// holo projectors, billboards and drones behind a glass balustrade.
/// Everything glows in hot magenta, electric cyan and acid lime on
/// blue-black, and fine neon drizzle and data motes drift over it all.
class CyberpunkScene extends RegionScene {
  const CyberpunkScene();

  @override
  WorldRegion get region => WorldRegion.cyberpunk;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.2, .155),
    radius: .07,
    disc: Color(0xfff0ecff),
    glow: Color(0xffc38cff),
    halo: .4,
    strength: .28,
    moon: 1,
  );

  static final _weather = Weather(
    Weather.of([(Mote.drizzle, 26), (Mote.data, 9)]),
  );
  @override
  Weather get weather => _weather;

  // The signature palette: hot magenta, electric cyan and acid lime on
  // blue-black, with violet and a little warm amber for contrast.
  static const _magenta = Color(0xffff3fb4);
  static const _pink = Color(0xffff8fd6);
  static const _cyan = Color(0xff3ff0ff);
  static const _ice = Color(0xffa8f8ff);
  static const _lime = Color(0xffc8ff4a);
  static const _violet = Color(0xff9a6bff);
  static const _amber = Color(0xffffb454);
  static const _red = Color(0xffff4a5e);
  static const _white = Color(0xfff6f4ff);
  static const _ink = Color(0xff07061a);

  /// Ridge lines of the bands, in viewport heights.
  static const _farY = .7, _midY = .758, _wl = .776, _nearY = .95;

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xff2d2562),
      Color(0xff251f54),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xff1c1a4a),
      Color(0xff161442),
      Color(0xff4d3f92),
      rimWidth: .002,
    ),
    Depth.low => const Ground(
      Color(0xff2c1d5e),
      Color(0xff0a0a24),
      Color(0xffb68ae8),
      rimWidth: .0014,
    ),
    Depth.near => const Ground(
      Color(0xff131132),
      Color(0xff08071c),
      Color(0xff34b9dc),
      rimWidth: .0028,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => _farY,
    Depth.mid => _midY,
    Depth.low => _wl + .0015 * math.sin(x * math.pi * 6 + clock * 1.6),
    Depth.near => _nearY,
  };

  @override
  double period(Depth d) => d == Depth.low ? 2.4 : 3.2;

  @override
  double sink(Depth d) => switch (d) {
    // The hyper-spires reach a tenth of the way down the sky.
    Depth.far => .64,
    // The space elevator's arcology tops out near the top of the screen.
    Depth.mid => .8,
    Depth.low => .2,
    Depth.near => .34,
  };

  /// The skylines and the guideway are laid out between fixed ends, so a
  /// campaign level repeats exactly those stretches and one copy's rail
  /// thins out along the next one's.
  @override
  (double, double) span(Depth d, Size size) {
    final w = size.width, h = size.height;
    return d == Depth.mid ? (-h * .22, w + h * .58) : (-h * .14, w + h * .34);
  }

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _far(c, w, h);
      case Depth.mid:
        _mid(c, w, h);
      case Depth.low:
        _canalBank(c, h);
      case Depth.near:
        _roofRow(c, h);
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    switch (d) {
      case Depth.far:
        _farLive(c, f);
      case Depth.mid:
        _midLive(c, f);
      case Depth.low:
        _canalLive(c, f);
      case Depth.near:
        _roofLive(c, f);
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    switch (d) {
      case Depth.low:
        _canalOverlay(c, f, presence);
      case Depth.near:
        _roofOverlay(c, f, presence);
      case Depth.far || Depth.mid:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) =>
      _canalReflect(c, f, presence);

  // ---------------------------------------------------------------------------
  // Shared light: blooms, neon tubes, invented glyphs and the koi.

  static final _glows = <int, Paint>{};

  /// A soft round bloom of [color] in unit space; scale the canvas to size
  /// it. One shader per colour, so per-frame glows stay cheap.
  static Paint _glowPaint(Color color) => _glows.putIfAbsent(
    color.toARGB32(),
    () => Paint()
      ..shader = Gradient.radial(
        Offset.zero,
        1,
        [
          color,
          Sketch.fade(color, .42),
          Sketch.fade(color, .12),
          Sketch.fade(color, 0),
        ],
        const [0, .22, .55, 1],
      ),
  );

  /// An elliptical bloom [rx] by [ry] around [at].
  static void _bloom(
    Canvas c,
    Offset at,
    double rx,
    double ry,
    Color color,
    double alpha,
  ) {
    if (!(alpha > .002) || !(rx > 0) || !(ry > 0)) return;
    final paint = _glowPaint(color)
      ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0));
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(rx, ry);
    c.drawCircle(Offset.zero, 1, paint);
    c.restore();
  }

  static final _tube = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// A neon tube along [path]: a wide faint bloom, a tighter glow, the
  /// coloured glass and a hot pale core, so it reads as light, not paint.
  static void _neon(
    Canvas c,
    Path path,
    Color color,
    double width, {
    double alpha = 1,
    bool bloom = true,
  }) {
    if (bloom) {
      c.drawPath(
        path,
        _tube
          ..strokeWidth = width * 7
          ..color = Sketch.fade(color, .06 * alpha),
      );
      c.drawPath(
        path,
        _tube
          ..strokeWidth = width * 3.4
          ..color = Sketch.fade(color, .18 * alpha),
      );
    }
    c.drawPath(
      path,
      _tube
        ..strokeWidth = width * 1.5
        ..color = Sketch.fade(color, .8 * alpha),
    );
    c.drawPath(
      path,
      _tube
        ..strokeWidth = width * .55
        ..color = Sketch.fade(Sketch.mix(color, _white, .72), alpha),
    );
  }

  /// Invented glyphs for the signs: two to four strokes on a 3 by 4 grid,
  /// one unit wide and 1.3 tall. They read as lettering without spelling
  /// anything.
  static const _glyphFrames = [(0, 2), (0, 9), (3, 5), (2, 11), (1, 10)];
  static const _glyphSlants = [
    (0, 4), (2, 4), (3, 7), (5, 7), (6, 10), (8, 10), (4, 6), (4, 8), //
    (7, 9), (7, 11), (3, 8), (5, 6),
  ];
  static const _glyphTicks = [(1, 4), (3, 4), (6, 7), (10, 11), (4, 5)];

  /// Adds glyph [n], [size] wide with its top-left corner at [at]: a frame
  /// stroke, a slant and sometimes a tick or a second slant, like a script
  /// that never spells a word.
  static void _addGlyph(Path path, int n, Offset at, double size) {
    Offset p(int i) => at + Offset((i % 3) / 2, (i ~/ 3) / 3 * 1.3) * size;
    void stroke((int, int) s) => path
      ..moveTo(p(s.$1).dx, p(s.$1).dy)
      ..lineTo(p(s.$2).dx, p(s.$2).dy);
    List<(int, int)> pick(List<(int, int)> from, int salt) => [
      from[(Sketch.hash(n * 13 + salt) * from.length).floor()],
    ];
    stroke(pick(_glyphFrames, 1).first);
    stroke(pick(_glyphSlants, 2).first);
    final extra = Sketch.hash(n * 7 + 3);
    if (extra < .55) stroke(pick(_glyphTicks, 4).first);
    if (extra > .7) stroke(pick(_glyphSlants, 5).first);
  }

  static const _glyphCount = 32;

  static final _glyphPen = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// A koi [length] long swimming toward +x ([dir] -1 flips it), its body
  /// rippling with [phase]. As a hologram it is a translucent body with a
  /// bright outline and scanlines; [solid] paints it as on a screen.
  static void _koi(
    Canvas c,
    Offset at,
    double length,
    double dir,
    double phase,
    double alpha, {
    required Color body,
    required Color spots,
    bool solid = false,
  }) {
    if (alpha <= .01 || length <= 0) return;
    const n = 12;
    final spine = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final u = k / n;
      spine.add(
        Offset(
          -u * length,
          math.sin(phase - u * 4.2) * length * .07 * math.pow(u, 1.3),
        ),
      );
    }
    double half(double u) =>
        length *
        .14 *
        math.pow(math.sin(math.pi * (u * .9 + .07)), .75) *
        (1 - .6 * u);
    final left = <Offset>[], right = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final a = spine[math.max(0, k - 1)], b = spine[math.min(n, k + 1)];
      final d = b - a;
      final normal = Offset(-d.dy, d.dx) / d.distance;
      final w = half(k / n);
      left.add(spine[k] + normal * w);
      right.add(spine[k] - normal * w);
    }
    final shape = Path()..moveTo(spine[0].dx + length * .035, spine[0].dy);
    for (final p in left) {
      shape.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    final tail = spine[n], back = spine[n - 1];
    final sway = math.sin(phase - 4.2) * length * .06;
    final fin = Path()
      ..moveTo(back.dx, back.dy)
      ..quadraticBezierTo(
        tail.dx - length * .08,
        tail.dy - length * .04,
        tail.dx - length * .2,
        tail.dy - length * .13 + sway,
      )
      ..quadraticBezierTo(
        tail.dx - length * .1,
        tail.dy + sway * .5,
        tail.dx - length * .2,
        tail.dy + length * .13 + sway,
      )
      ..quadraticBezierTo(
        tail.dx - length * .08,
        tail.dy + length * .04,
        back.dx,
        back.dy,
      )
      ..close();
    final pectoral = Path();
    final root = spine[3];
    for (final side in const [-1.0, 1.0]) {
      pectoral
        ..moveTo(root.dx, root.dy + side * half(.25) * .8)
        ..quadraticBezierTo(
          root.dx - length * .05,
          root.dy + side * length * .12,
          root.dx - length * .12,
          root.dy + side * length * .1,
        )
        ..quadraticBezierTo(
          root.dx - length * .07,
          root.dy + side * half(.25),
          root.dx - length * .04,
          root.dy + side * half(.3) * .7,
        )
        ..close();
    }
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(dir, 1);
    final paint = Paint();
    if (!solid) {
      _bloom(
        c,
        Offset(-length * .45, 0),
        length * .75,
        length * .3,
        body,
        .3 * alpha,
      );
    }
    final fill = solid ? .95 : .3;
    c.drawPath(fin, paint..color = Sketch.fade(body, fill * .8 * alpha));
    c.drawPath(pectoral, paint..color = Sketch.fade(body, fill * .8 * alpha));
    c.drawPath(shape, paint..color = Sketch.fade(body, fill * alpha));
    // Spots along the back.
    for (final (u, dy, s) in const [
      (.22, -.3, .05),
      (.4, .2, .06),
      (.58, -.1, .04),
    ]) {
      final p = spine[(u * n).round()];
      c.drawCircle(
        p + Offset(0, dy * half(u)),
        length * s,
        paint..color = Sketch.fade(spots, (solid ? .95 : .55) * alpha),
      );
    }
    if (!solid) {
      c.save();
      c.clipPath(shape);
      final scan = Paint()..color = Sketch.fade(_white, .14 * alpha);
      for (var y = -length * .15; y < length * .15; y += length * .035) {
        c.drawRect(
          Rect.fromLTWH(-length * 1.1, y, length * 1.2, length * .008),
          scan,
        );
      }
      c.restore();
    }
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(.7, length * .012)
      ..color = Sketch.fade(
        Sketch.mix(body, _white, .55),
        (solid ? .6 : .9) * alpha,
      );
    c.drawPath(shape, outline);
    c.drawPath(fin, outline);
    c.drawCircle(
      spine[0] + Offset(-length * .02, -half(.02) * .3),
      math.max(.7, length * .012),
      paint..color = Sketch.fade(solid ? _ink : _white, alpha),
    );
    c.restore();
  }

  /// The night sky exactly as the compositor paints it, at height [y] in
  /// viewport heights. Distant towers borrow it so they melt into the haze.
  static Color _skyAt(double y) {
    final p = WorldRegion.cyberpunk.palette;
    const horizon = .64;
    final mid = Sketch.mix(p.top, p.horizon, .42);
    final low = Sketch.mix(p.horizon, p.haze, .7);
    if (y <= horizon * .52) {
      return Sketch.mix(p.top, mid, (y / (horizon * .52)).clamp(0.0, 1.0));
    }
    if (y <= horizon) {
      return Sketch.mix(mid, p.horizon, (y - horizon * .52) / (horizon * .48));
    }
    return Sketch.mix(
      p.horizon,
      low,
      ((y - horizon) / (1 - horizon)).clamp(0.0, 1.0),
    );
  }

  /// A tower colour that follows the sky's gradient, [k] of the way from
  /// the sky to [tone]: the farther the layer, the smaller [k].
  static Paint _skyTone(double h, Color tone, double k) {
    const ys = [.05, .25, .45, .6, .72];
    return Paint()
      ..shader = Gradient.linear(
        Offset(0, h * ys.first),
        Offset(0, h * ys.last),
        [for (final y in ys) Sketch.mix(_skyAt(y), tone, k)],
        [for (final y in ys) (y - ys.first) / (ys.last - ys.first)],
      );
  }

  // ---------------------------------------------------------------------------
  // Sky: horizon glow, stars, the moon, the orbital ring, the lit cloud deck,
  // sweeping beams and flying traffic.

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    _skyGlow(c, f, presence);
    _skyStars(c, f, presence);
    _skyMoon(c, f, presence);
    _skyRing(c, f, presence);
    _skyClouds(c, f, presence);
    _skyBeams(c, f, presence);
    _skyTraffic(c, f, presence);
    _skyShip(c, f, presence);
  }

  static final _skyGlowPaint = Paint()
    ..shader = Gradient.linear(
      const Offset(0, .26),
      const Offset(0, .76),
      [
        Sketch.fade(_magenta, 0),
        Sketch.fade(_magenta, .1),
        Sketch.fade(const Color(0xffff5aa8), .34),
        Sketch.fade(const Color(0xffff7ab0), .4),
      ],
      const [0, .45, .82, 1],
    );

  /// The city's light pollution: magenta banked against the horizon with
  /// pools of cyan and violet where the brightest districts are.
  void _skyGlow(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // The glow's gradient runs in unit height, so one shader serves every
    // viewport; the paint's alpha carries the crossing's presence.
    c.save();
    c.scale(1, h);
    c.drawRect(
      Rect.fromLTRB(0, .26, w, .76),
      _skyGlowPaint..color = Color.fromRGBO(0, 0, 0, presence),
    );
    c.restore();
    _bloom(c, Offset(w * .2, h * .66), w * .42, h * .2, _cyan, .2 * presence);
    _bloom(
      c,
      Offset(w * .64, h * .67),
      w * .36,
      h * .22,
      _violet,
      .3 * presence,
    );
  }

  /// Only a few stars survive the glow, high in the clear sky.
  void _skyStars(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final star = Paint();
    for (var i = 0; i < 18; i++) {
      final twinkle = .55 + .45 * math.sin(f.clock * 1.7 + i * 2.3);
      star.color = Sketch.fade(
        i % 5 == 0 ? _ice : _white,
        (.25 + .35 * Sketch.hash(i + 9100)) * twinkle * presence,
      );
      c.drawCircle(
        Offset(w * Sketch.hash(i + 9110), h * .3 * Sketch.hash(i + 9120)),
        h * (.0012 + .0016 * Sketch.hash(i + 9130)),
        star,
      );
    }
  }

  /// The light the compositor is painting right now: this moon while
  /// holding, blended with the neighbour's light during a crossing.
  static SkyLight _skyLight(SceneFrame f) {
    final blend = f.blend;
    final a = RegionScene.of(blend.from).light;
    if (!blend.crossing) return a;
    return SkyLight.lerp(a, RegionScene.of(blend.to).light, blend.stage(0, 1));
  }

  // Moon paints live in the moon's unit space (radius 1, y down).
  static final _moonDisc = Paint()
    ..shader = Gradient.radial(
      const Offset(.3, -.3),
      1.5,
      const [Color(0xfffdfbff), Color(0xffe6e2fa), Color(0xffa9a2d6)],
      const [0, .55, 1],
    );
  static final _moonShadow = Paint()
    ..shader = Gradient.linear(
      const Offset(-1.05, 0),
      const Offset(-.12, 0),
      const [Color(0xe8261d58), Color(0x7a312a66), Color(0x00312a66)],
      const [0, .5, 1],
    );
  static final _moonAureole = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [
        Color(0xffe8dcff),
        Color(0xffe8dcff),
        Color(0x80d6b8ff),
        Color(0x33c890ff),
        Color(0x14c890ff),
        Color(0x00c890ff),
      ],
      const [0, .26, .31, .45, .7, 1],
    );

  /// A waxing gibbous moon, cool and violet-lit, with a thin cloud streak
  /// and the pinprick lights of a colony on its night side.
  void _skyMoon(Canvas c, SceneFrame f, double presence) {
    final l = _skyLight(f);
    final weight = l.moon * l.moon * presence;
    if (weight <= .02) return;
    final at = Offset(l.at.dx * f.w, l.at.dy * f.h);
    final r = l.radius * f.h;
    final tint = Color.fromRGBO(255, 255, 255, weight);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    c.save();
    c.scale(3.8);
    c.drawCircle(Offset.zero, 1, _moonAureole..color = tint);
    c.restore();
    c.drawCircle(Offset.zero, 1.01, _moonDisc..color = tint);
    // Soft maria.
    for (final (x, y, s) in const [
      (.18, -.3, .34),
      (.44, .1, .26),
      (-.06, .04, .24),
      (.24, .46, .18),
      (-.32, -.44, .16),
    ]) {
      _bloom(c, Offset(x, y), s, s, const Color(0xff7c72b8), .5 * weight);
    }
    // The night side, shaded across the limb.
    c.save();
    c.clipPath(Path()..addOval(const Rect.fromLTRB(-1.02, -1.02, 1.02, 1.02)));
    c.drawRect(
      const Rect.fromLTRB(-1.1, -1.1, .3, 1.1),
      _moonShadow..color = tint,
    );
    c.restore();
    // A colony's lights on the dark limb.
    final city = Paint()..color = Sketch.fade(_ice, .7 * weight);
    for (final (x, y) in const [
      (-.72, .12),
      (-.66, .2),
      (-.78, .02),
      (-.6, .32),
      (-.7, -.24),
    ]) {
      c.drawCircle(Offset(x, y), .03, city);
    }
    c.restore();
    // A streak of high cloud across the face.
    final drift = math.sin(f.clock * .05) * r * .4;
    _bloom(
      c,
      at + Offset(drift - r * .3, r * .45),
      r * 2.4,
      r * .16,
      const Color(0xff2a2160),
      .75 * weight,
    );
  }

  /// An orbital ring arcs over the whole sky, catching sunlight from below
  /// the horizon: a double track with station lights drifting along it.
  void _skyRing(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final center = Offset(w * .44, h * 1.9);
    final rx = w * .95 + h * .5, ry = h * 1.72;
    const tilt = -.05;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(tilt);
    final oval = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawArc(
      oval,
      math.pi * 1.1,
      math.pi * .8,
      false,
      pen
        ..strokeWidth = h * .014
        ..color = Sketch.fade(const Color(0xffb9a4ff), .05 * presence),
    );
    c.drawArc(
      oval,
      math.pi * 1.1,
      math.pi * .8,
      false,
      pen
        ..strokeWidth = math.max(.8, h * .0024)
        ..color = Sketch.fade(const Color(0xffe4dcff), .34 * presence),
    );
    final inner = oval.deflate(h * .008);
    c.drawArc(
      inner,
      math.pi * 1.1,
      math.pi * .8,
      false,
      pen
        ..strokeWidth = math.max(.6, h * .0012)
        ..color = Sketch.fade(const Color(0xffc9bcff), .2 * presence),
    );
    // Stations ride the ring, bright where they catch the sun.
    final dot = Paint();
    for (var i = 0; i < 9; i++) {
      final a = math.pi * (1.14 + .72 * ((i / 9 + f.clock * .0016) % 1));
      final p = Offset(math.cos(a) * rx, math.sin(a) * ry);
      final big = i % 3 == 0;
      dot.color = Sketch.fade(big ? _white : _ice, (big ? .8 : .5) * presence);
      c.drawCircle(p, h * (big ? .0026 : .0015), dot);
      if (big) {
        dot.color = Sketch.fade(_ice, .12 * presence);
        c.drawCircle(p, h * .008, dot);
      }
    }
    c.restore();
  }

  // ---- Cloud deck -----------------------------------------------------------

  static final _cloudPictures = <(double, double, int), Picture>{};

  static double _cloudSpan(Size size) => size.width * 1.4;

  static Picture _cloudPicture(Size size, int layer) {
    final key = (size.width, size.height, layer);
    final hit = _cloudPictures[key];
    if (hit != null) return hit;
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    if (layer == 0) {
      _cloudWisps(c, size);
    } else {
      _cloudDeck(c, size);
    }
    final picture = recorder.endRecording();
    if (_cloudPictures.length > 12) {
      _cloudPictures.remove(_cloudPictures.keys.first)!.dispose();
    }
    return _cloudPictures[key] = picture;
  }

  void _skyClouds(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final span = _cloudSpan(f.size);
    final fade = presence < .995;
    if (fade) {
      c.saveLayer(
        Rect.fromLTWH(0, 0, w, h * .72),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
    }
    for (final (layer, speed) in const [(1, .004), (0, .009)]) {
      final shift = f.clock * speed * h % span;
      c.save();
      c.translate(-shift, 0);
      c.drawPicture(_cloudPicture(f.size, layer));
      c.translate(span, 0);
      c.drawPicture(_cloudPicture(f.size, layer));
      c.restore();
    }
    if (fade) c.restore();
  }

  /// Thin, high streaks the moonlight silvers.
  static void _cloudWisps(Canvas c, Size size) {
    final h = size.height, span = _cloudSpan(size);
    const n = 7;
    for (var i = 0; i < n; i++) {
      final x = span * (i + .5 * Sketch.hash(i + 9200)) / n;
      final y = h * (.06 + .16 * Sketch.hash(i + 9210));
      final len = h * (.5 + .5 * Sketch.hash(i + 9220));
      for (var k = 0; k < 3; k++) {
        Sketch.mist(
          c,
          Rect.fromCenter(
            center: Offset(
              x + (k - 1) * len * .25,
              y + (Sketch.hash(i * 3 + k + 9230) - .5) * h * .012,
            ),
            width: len * (.7 - k * .12),
            height: h * (.01 + .008 * Sketch.hash(i * 3 + k + 9240)),
          ),
          const Color(0xffa99ae0),
          .14,
        );
      }
    }
  }

  /// The low deck: flat strata of smog, dark on top and lit from beneath
  /// by the city in pools of magenta and cyan.
  static void _cloudDeck(Canvas c, Size size) {
    final h = size.height, span = _cloudSpan(size);
    const n = 7;
    for (var i = 0; i < n; i++) {
      final x = span * (i + .3 + .4 * Sketch.hash(i + 9300)) / n;
      final y = h * (.3 + .17 * Sketch.hash(i + 9310));
      final len = h * (.45 + .5 * Sketch.hash(i + 9320));
      final thick = h * (.016 + .016 * Sketch.hash(i + 9330));
      final tint = switch (i % 3) {
        0 => const Color(0xffff5fb0),
        1 => const Color(0xffb46bff),
        _ => const Color(0xff4fd8ff),
      };
      // Body: a dark flat band.
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, y), width: len, height: thick * 2.2),
        const Color(0xff241a58),
        .42,
      );
      // Underglow where the city light hits the base.
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x + len * .08, y + thick * .55),
          width: len * .8,
          height: thick * 1.1,
        ),
        tint,
        .2,
      );
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x + len * .1, y + thick * .7),
          width: len * .42,
          height: thick * .45,
        ),
        Sketch.mix(tint, _white, .5),
        .16,
      );
    }
  }

  // ---- Beams and traffic ----------------------------------------------------

  static final _beamPaint = <int, Paint>{};

  /// A beam's gradient in unit space: bright at the foot, gone at the tip.
  static Paint _beam(Color color) => _beamPaint.putIfAbsent(
    color.toARGB32(),
    () => Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        const Offset(0, -1),
        [
          Sketch.fade(color, .34),
          Sketch.fade(color, .12),
          Sketch.fade(color, 0),
        ],
        const [0, .5, 1],
      ),
  );

  static final _beamShape = Sketch.poly(const [
    -.004, 0, -.024, -1, .024, -1, .004, 0, //
  ]);

  /// Two narrow beams sweep from arcology crowns, cyan and magenta.
  void _skyBeams(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    for (final (fx, speed, phase, color) in const [
      (.34, .21, 0.0, _cyan),
      (.74, .17, 2.4, _magenta),
    ]) {
      final base = Offset(w * fx, h * .62);
      final a = math.sin(f.clock * speed + phase) * .36;
      final reach = h * .55;
      c.save();
      c.translate(base.dx, base.dy);
      c.rotate(a);
      c.scale(h, reach);
      c.drawPath(
        _beamShape,
        _beam(color)..color = Color.fromRGBO(0, 0, 0, presence),
      );
      c.restore();
    }
  }

  /// Flying traffic on three sky lanes at different depths: far lanes of
  /// pinprick head and tail lights, a nearer lane of streaking cars.
  void _skyTraffic(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final travel = f.reducedMotion ? 0.0 : f.distance * h;
    final heads = <Offset>[], tails = <Offset>[], trails = <Offset>[];
    for (final (y0, n, speed, drift, scale, lane) in const [
      (.44, 16, .05, .02, .6, 0),
      (.47, 12, -.04, .02, .55, 1),
      (.3, 7, .09, .04, 1.0, 2),
      (.2, 4, -.13, .07, 1.5, 3),
    ]) {
      final span = w + h * .4;
      for (var i = 0; i < n; i++) {
        final x0 = span * (i + .4 * Sketch.hash(lane * 31 + i + 9400)) / n;
        final x =
            ((x0 + f.clock * speed * h - travel * drift) % span + span) % span -
            h * .2;
        final y =
            h * (y0 + .012 * math.sin(x / h * 2.2 + lane)) +
            (Sketch.hash(lane * 17 + i + 9410) - .5) * h * .012;
        final dir = speed.sign;
        final len = h * .006 * scale;
        heads.add(Offset(x + dir * len, y));
        tails.add(Offset(x - dir * len, y));
        if (lane >= 2) {
          trails
            ..add(Offset(x - dir * len, y))
            ..add(Offset(x - dir * len * 7, y));
        }
      }
    }
    final pen = Paint()..strokeCap = StrokeCap.round;
    c.drawPoints(
      PointMode.lines,
      trails,
      pen
        ..strokeWidth = math.max(.8, h * .0022)
        ..color = Sketch.fade(_pink, .34 * presence),
    );
    c.drawPoints(
      PointMode.points,
      tails,
      pen
        ..strokeWidth = math.max(1.2, h * .0036)
        ..color = Sketch.fade(_red, .8 * presence),
    );
    c.drawPoints(
      PointMode.points,
      heads,
      pen
        ..strokeWidth = math.max(1.2, h * .0036)
        ..color = Sketch.fade(const Color(0xfffff6dc), .9 * presence),
    );
  }

  /// The airship's hull in unit space: dark on top, lit from below.
  static final _shipHull = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -.5),
      const Offset(0, .5),
      const [Color(0xff34306e), Color(0xff17153e), Color(0xff6a2a82)],
      const [0, .55, 1],
    );

  /// An advertising airship drifting over the city: a dark hull lit from
  /// below, a long screen scrolling glyphs, running lights and a faint
  /// beam sweeping the smog beneath.
  void _skyShip(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final len = h * .2, tall = h * .036;
    var x = w * .64 + (_legTime(f) - 8) * h * .026;
    // A campaign level outlasts the crossing, so the ship comes round again
    // from the left after a short gap.
    if (f.held) x = Sketch.wrap(x, -len, w + len * 2 + h * .6);
    if (x < -len || x > w + len) return;
    final at = Offset(x, h * (.118 + .005 * math.sin(f.clock * .45)));
    final a = presence;
    // The beam.
    final sweep = math.sin(f.clock * .5) * .35;
    c.save();
    c.translate(at.dx + len * .05, at.dy + tall * .6);
    c.rotate(sweep);
    c.scale(h, h * .3);
    c.drawPath(
      Sketch.poly(const [-.006, 0, .006, 0, .05, 1, -.05, 1]),
      _beam(_ice)..color = Color.fromRGBO(0, 0, 0, .22 * a),
    );
    c.restore();
    // Fins, then the hull.
    final fin = Paint()..color = Sketch.fade(const Color(0xff1c1a46), a);
    c.drawPath(
      Sketch.poly([-.44, -.06, -.56, -.2, -.36, -.08], at: at, s: len),
      fin,
    );
    c.drawPath(
      Sketch.poly([-.44, .06, -.56, .18, -.36, .08], at: at, s: len),
      fin,
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(len, tall);
    c.drawOval(
      const Rect.fromLTRB(-.5, -.5, .5, .5),
      _shipHull..color = Color.fromRGBO(0, 0, 0, a),
    );
    c.restore();
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: at + Offset(len * .04, tall * .56),
          width: len * .16,
          height: tall * .28,
        ),
        Radius.circular(tall * .1),
      ),
      Paint()..color = Sketch.fade(const Color(0xff15133a), a),
    );
    // The screen band, its glyphs scrolling.
    final screen = Rect.fromCenter(
      center: at + Offset(len * .02, -tall * .02),
      width: len * .6,
      height: tall * .42,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(screen, Radius.circular(tall * .08)),
      Paint()..color = Sketch.fade(const Color(0xff090822), a),
    );
    c.save();
    c.clipRect(screen);
    final glyphs = Path();
    final gs = screen.height * .62;
    final shift = (f.clock * h * .02) % (gs * 1.5);
    for (var k = -1; k < 14; k++) {
      final gx = screen.right - k * gs * 1.5 + shift - gs * 1.5;
      _addGlyph(
        glyphs,
        (k + (f.clock * h * .02 / (gs * 1.5)).floor()) * 3 + 5,
        Offset(gx, screen.top + screen.height * .12),
        gs,
      );
    }
    _glyphPen.strokeWidth = math.max(.7, h * .0016);
    c.drawPath(glyphs, _glyphPen..color = Sketch.fade(_pink, .95 * a));
    c.restore();
    _bloom(
      c,
      screen.center,
      screen.width * .6,
      screen.height * 1.6,
      _magenta,
      .22 * a,
    );
    // Running lights.
    final strobe = f.clock % 1.6 < .12 ? 1.0 : 0.0;
    c.drawCircle(
      at + Offset(len * .5, 0),
      h * .0022,
      Paint()..color = Sketch.fade(_white, a),
    );
    c.drawCircle(
      at + Offset(-len * .5, -tall * .1),
      h * .002,
      Paint()..color = Sketch.fade(_red, a),
    );
    if (strobe > 0) {
      _bloom(c, at + Offset(0, -tall * .5), h * .012, h * .012, _white, .7 * a);
    }
  }

  // ---------------------------------------------------------------------------
  // Far band: two layers of arcology towers melting into violet haze, and
  // the hyper-spires that stand over the whole city.

  /// One tower of the skyline: centre x in pixels, half width and roof in
  /// viewport heights, crown style and seed.
  static List<(double, double, double, int, int)> _farLayer(
    double w,
    double h,
    int layer,
  ) {
    final towers = <(double, double, double, int, int)>[];
    final x0 = -h * .14, x1 = w + h * .34;
    var x = x0;
    for (var i = 0; x < x1; i++) {
      final seed = layer * 1000 + i;
      final hw = layer == 0
          ? .012 + .02 * Sketch.hash(seed + 9500)
          : .02 + .026 * Sketch.hash(seed + 9500);
      final tall = Sketch.hash(seed + 9515) < .18;
      final top = layer == 0
          ? .2 + .28 * Sketch.hash(seed + 9510)
          : (tall
                ? .24 + .08 * Sketch.hash(seed + 9510)
                : .4 + .2 * Sketch.hash(seed + 9510));
      final crown = (Sketch.hash(seed + 9520) * 8).floor();
      towers.add((x + hw * h, hw, top, crown, seed));
      x +=
          hw * h * 2 +
          h * (layer == 0 ? .004 : .002) +
          h * (layer == 0 ? .03 : .045) * Sketch.hash(seed + 9530);
    }
    return towers;
  }

  static final _farCache = <(double, double), _FarPlan>{};

  static _FarPlan _farPlan(double w, double h) =>
      _farCache.putIfAbsent((w, h), () {
        if (_farCache.length > 4) _farCache.remove(_farCache.keys.first);
        return _FarPlan(_farLayer(w, h, 0), _farLayer(w, h, 1));
      });

  /// The hyper-spires: centre as a fraction of the viewport width, top in
  /// viewport heights, and style.
  static const _hypers = [(.19, .07, 0), (.76, .17, 1)];

  static void _far(Canvas c, double w, double h) {
    final plan = _farPlan(w, h);
    final x0 = -h * .14, x1 = w + h * .34;
    // The ghost layer: pale towers barely darker than the haze.
    final ghostBody = _skyTone(h, const Color(0xff2a2462), .34);
    final ghostLit = _skyTone(h, const Color(0xff6a58b0), .34);
    final strips = <Color, Path>{};
    for (final t in plan.ghosts) {
      _farTower(c, h, t, ghostBody, ghostLit, strips, .45);
    }
    _farStrips(c, h, strips, .5);
    // Haze swallows the ghost layer's feet.
    _farHaze(c, h, x0, x1, .52, .5);
    for (final (fx, top, kind) in _hypers) {
      _hyper(c, w * fx, h, top, kind);
    }
    // The near far row: darker, crisper, full of light.
    final rowBody = _skyTone(h, const Color(0xff110e38), .8);
    final rowLit = _skyTone(h, const Color(0xff33287a), .74);
    strips.clear();
    final windows = <Color, List<Offset>>{};
    for (final t in plan.row) {
      _farTower(c, h, t, rowBody, rowLit, strips, 1, windows: windows);
    }
    _farWindows(c, h, windows);
    _farStrips(c, h, strips, 1);
    _farHaze(c, h, x0, x1, .6, .42);
  }

  /// A veil of glowing haze thickening down to the far ridge.
  static void _farHaze(
    Canvas c,
    double h,
    double x0,
    double x1,
    double from,
    double alpha,
  ) {
    final glow = Sketch.mix(_skyAt(.66), const Color(0xffff7ab8), .25);
    c.drawRect(
      Rect.fromLTRB(x0, h * from, x1, h * .72),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * from),
          Offset(0, h * .72),
          [
            Sketch.fade(glow, 0),
            Sketch.fade(glow, alpha * .6),
            Sketch.fade(glow, alpha),
          ],
          const [0, .6, 1],
        ),
    );
  }

  /// A tower silhouette in one of eight crown styles: 0 flat with a
  /// parapet, 1 raked, 2 needle, 3 setback, 4 capsule, 5 twin prongs,
  /// 6 disc crown, 7 notched, from [top] down to [base] (pixels).
  static Path _towerShape(
    double x,
    double hw,
    double top,
    int crown,
    double base,
  ) {
    final l = x - hw, r = x + hw;
    final path = Path();
    switch (crown) {
      case 1:
        path.addPolygon([
          Offset(l, base),
          Offset(l, top + hw * 1.1),
          Offset(r, top),
          Offset(r, base),
        ], true);
      case 2:
        path.addPolygon([
          Offset(l, base),
          Offset(l, top + hw * 2.2),
          Offset(x - hw * .3, top + hw * .6),
          Offset(x, top - hw * 2.6),
          Offset(x + hw * .3, top + hw * .6),
          Offset(r, top + hw * 2.2),
          Offset(r, base),
        ], true);
      case 3:
        path.addPolygon([
          Offset(l, base),
          Offset(l, top + hw * 1.6),
          Offset(l + hw * .35, top + hw * 1.6),
          Offset(l + hw * .35, top + hw * .6),
          Offset(x - hw * .1, top + hw * .6),
          Offset(x - hw * .1, top),
          Offset(r - hw * .3, top),
          Offset(r - hw * .3, top + hw * .9),
          Offset(r, top + hw * .9),
          Offset(r, base),
        ], true);
      case 4:
        path
          ..moveTo(l, base)
          ..lineTo(l, top + hw)
          ..arcToPoint(Offset(r, top + hw), radius: Radius.circular(hw))
          ..lineTo(r, base)
          ..close();
      case 5:
        path.addPolygon([
          Offset(l, base),
          Offset(l, top - hw * 1.4),
          Offset(l + hw * .5, top + hw * .3),
          Offset(r - hw * .5, top + hw * .3),
          Offset(r, top - hw * 1.8),
          Offset(r, base),
        ], true);
      case 6:
        path
          ..addRect(Rect.fromLTRB(l, top + hw * .5, r, base))
          ..addRect(
            Rect.fromLTRB(
              l - hw * .35,
              top + hw * .2,
              r + hw * .35,
              top + hw * .55,
            ),
          )
          ..addRect(
            Rect.fromLTRB(x - hw * .45, top - hw * .6, x + hw * .45, top + hw),
          );
      case 7:
        path.addPolygon([
          Offset(l, base),
          Offset(l, top),
          Offset(x, top + hw * .9),
          Offset(r, top),
          Offset(r, base),
        ], true);
      default:
        path.addRect(Rect.fromLTRB(l, top, r, base));
    }
    return path;
  }

  /// One far tower: body, a moonlit right face, the odd vertical light
  /// strip and, on the nearer row, lit windows and a mast.
  static void _farTower(
    Canvas c,
    double h,
    (double, double, double, int, int) t,
    Paint body,
    Paint lit,
    Map<Color, Path> strips,
    double detail, {
    Map<Color, List<Offset>>? windows,
  }) {
    final (x, hwu, topu, crown, seed) = t;
    final hw = hwu * h, top = topu * h;
    final path = _towerShape(x, hw, top, crown, h * .74);
    c.drawPath(path, body);
    c.save();
    c.clipPath(path);
    c.drawRect(
      Rect.fromLTRB(
        x + hw * (detail >= 1 ? .6 : .45),
        top - hw * 3,
        x + hw * 1.5,
        h,
      ),
      lit,
    );
    if (detail >= 1) {
      // A rim of city glow down the left edge.
      c.drawRect(
        Rect.fromLTRB(
          x - hw,
          top - hw * 3,
          x - hw + math.max(.8, h * .0016),
          h,
        ),
        Paint()..color = Sketch.fade(_pink, .32),
      );
    }
    c.restore();
    final n = Sketch.hash(seed + 9540);
    // Vertical light strips run up the corners of about half the towers.
    if (n < .55) {
      final color = switch ((n * 100).floor() % 4) {
        0 => _magenta,
        1 => _cyan,
        2 => _violet,
        _ => _pink,
      };
      final edge = n < .3 ? x - hw * .82 : x + hw * .3;
      strips.putIfAbsent(color, Path.new)
        ..moveTo(edge, top + hw * (crown == 2 ? 2.4 : 1.2))
        ..lineTo(edge, h * .72);
    }
    if (windows != null) {
      final floor = h * .0085;
      final cols = math.max(1, (hw * 2 / (h * .0068)).floor() - 1);
      final pitch = hw * 2 / (cols + 1);
      var row = 0;
      for (var y = top + hw * 2.6; y < h * .7; y += floor, row++) {
        for (var k = 0; k < cols; k++) {
          final r = Sketch.hash(seed * 997 + row * 31 + k * 7);
          if (r > .34) continue;
          final color = r < .2
              ? const Color(0xffcfe8ff)
              : (r < .27 ? _pink : (r < .31 ? _ice : _amber));
          windows
              .putIfAbsent(color, () => <Offset>[])
              .add(Offset(x - hw + pitch * (k + 1), y));
        }
      }
    }
    if (detail >= 1 && crown != 2 && n > .6) {
      final mast = h * (.02 + .03 * Sketch.hash(seed + 9550));
      c.drawLine(
        Offset(x, top),
        Offset(x, top - mast),
        Paint()
          ..color = Sketch.fade(const Color(0xff8a7cc8), .7)
          ..strokeWidth = math.max(.7, h * .0014),
      );
    }
  }

  static void _farStrips(
    Canvas c,
    double h,
    Map<Color, Path> strips,
    double alpha,
  ) {
    final pen = Paint()..style = PaintingStyle.stroke;
    strips.forEach((color, path) {
      c.drawPath(
        path,
        pen
          ..strokeWidth = h * .006
          ..color = Sketch.fade(color, .08 * alpha),
      );
      c.drawPath(
        path,
        pen
          ..strokeWidth = math.max(.7, h * .0016)
          ..color = Sketch.fade(color, .7 * alpha),
      );
    });
  }

  static void _farWindows(
    Canvas c,
    double h,
    Map<Color, List<Offset>> windows,
  ) {
    final pen = Paint()
      ..strokeWidth = math.max(1.0, h * .0026)
      ..strokeCap = StrokeCap.square;
    windows.forEach((color, points) {
      c.drawPoints(
        PointMode.points,
        points,
        pen..color = Sketch.fade(color, .7),
      );
    });
  }

  /// A hyper-spire: a needle of glass taller than anything else in the
  /// city, girdled by lit platform rings, with a light strip up its spine.
  static void _hyper(Canvas c, double x, double h, double top, int kind) {
    final body = _skyTone(h, const Color(0xff1e1a56), kind == 0 ? .5 : .6);
    final lit = _skyTone(h, const Color(0xff6c5cc0), .5);
    final t = top * h;
    final base = h * .74;
    final hwBase = h * (kind == 0 ? .05 : .065), hwTop = h * .006;
    final path = Path()
      ..moveTo(x - hwBase, base)
      ..cubicTo(
        x - hwBase * .7,
        base - (base - t) * .5,
        x - hwTop * 2,
        t + (base - t) * .25,
        x - hwTop,
        t,
      )
      ..lineTo(x + hwTop, t)
      ..cubicTo(
        x + hwTop * 2,
        t + (base - t) * .25,
        x + hwBase * .7,
        base - (base - t) * .5,
        x + hwBase,
        base,
      )
      ..close();
    c.drawPath(path, body);
    c.save();
    c.clipPath(path);
    c.drawRect(Rect.fromLTRB(x + hwTop * .5, t, x + hwBase, base), lit);
    c.restore();
    // The spine strip and the mast.
    final spine = Path()
      ..moveTo(x, t + h * .01)
      ..lineTo(x, base);
    _neon(c, spine, kind == 0 ? _cyan : _magenta, h * .0016, alpha: .7);
    c.drawLine(
      Offset(x, t),
      Offset(x, t - h * .05),
      Paint()
        ..color = const Color(0xffb4a8e8)
        ..strokeWidth = math.max(.8, h * .0018),
    );
    // Platform rings where the spire widens.
    for (final (k, color) in [(.18, _ice), (.42, _pink), (.66, _ice)]) {
      final y = t + (base - t) * k;
      final half = hwTop + (hwBase - hwTop) * math.pow(k, 1.6) + h * .012;
      final ring = Rect.fromCenter(
        center: Offset(x, y),
        width: half * 2,
        height: h * .008,
      );
      c.drawOval(ring, Paint()..color = Sketch.mix(_skyAt(y / h), _ink, .5));
      c.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, h * .0016)
          ..color = Sketch.fade(color, .7),
      );
    }
  }

  /// Aircraft warning lights blink on the hyper-spires' masts and a few
  /// crowns, out of step with each other.
  void _farLive(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h, clock = f.clock;
    final paint = Paint();
    void blink(Offset at, double phase) {
      final on = math.sin(clock * 2.1 + phase) > .1;
      if (!on) return;
      _bloom(c, at, h * .012, h * .012, _red, .5);
      c.drawCircle(at, h * .0022, paint..color = _red);
    }

    for (final (fx, top, kind) in _hypers) {
      blink(Offset(w * fx, h * (top - .05)), kind * 1.9);
    }
    final plan = _farPlan(w, h);
    for (final (x, _, top, crown, seed) in plan.row) {
      if (crown == 2 || Sketch.hash(seed + 9540) <= .6) continue;
      final mast = h * (.02 + .03 * Sketch.hash(seed + 9550));
      blink(Offset(x, top * h - mast), seed * 1.3);
    }
  }
  // ---------------------------------------------------------------------------
  // Mid band: the space-elevator arcology split around its core of light,
  // sleek glass towers with sky bridges and giant screens, and the maglev
  // guideway sweeping in front of them.

  /// Seconds into the city's leg (negative while it is still arriving);
  /// Reduced Motion holds the middle of the hold.
  static double _legTime(SceneFrame f) {
    if (f.reducedMotion) return 8;
    if (f.held) return f.clock;
    final start = WorldRegion.cyberpunk.index * WorldTour.leg;
    return (f.clock % WorldTour.loop) - start;
  }

  /// The spire's axis in the mid band's viewport coordinates: the band
  /// drifts left through a hold, so it stands just right of centre then.
  static double _spireX(double w, double h) => w * .56 + h * .14;
  static const _spireTop = .075, _spireBase = .8;

  /// The spire's outer profile from the top down: (height, half width) in
  /// viewport heights. Every halo terrace steps the blades out, like the
  /// setbacks of a supertall.
  static const _spireProfile = [
    (.075, .011),
    (.2, .02),
    (.2, .029),
    (.34, .039),
    (.34, .05),
    (.5, .062),
    (.5, .075),
    (.66, .092),
    (.8, .128),
  ];

  static double _spireU(double y) =>
      ((y - _spireTop) / (_spireBase - _spireTop)).clamp(0.0, 1.0);

  /// Half the spire's width at height [y] (both in viewport heights); at a
  /// terrace, the narrower tier above it.
  static double _spireHalf(double y) {
    for (var i = 1; i < _spireProfile.length; i++) {
      final (y0, w0) = _spireProfile[i - 1];
      final (y1, w1) = _spireProfile[i];
      if (y1 > y0 && y <= y1) {
        return w0 + (w1 - w0) * ((y - y0) / (y1 - y0)).clamp(0.0, 1.0);
      }
    }
    return _spireProfile.last.$2;
  }

  /// Half the slot between its two blades, where the core shows through.
  static double _spireSlot(double y) => .0022 + .0078 * _spireU(y);

  /// The halo platforms on the terraces: height, reach past the wider tier
  /// and colour.
  static const _halos = [
    (.2, .022, _ice),
    (.34, .026, _magenta),
    (.5, .03, _cyan),
  ];

  /// A halo platform's half width.
  static double _haloHalf(double y, double reach) =>
      _spireHalf(y + .0001) + reach;

  static final _midCache = <(double, double), _MidPlan>{};

  static _MidPlan _midPlan(double w, double h) =>
      _midCache.putIfAbsent((w, h), () {
        if (_midCache.length > 4) _midCache.remove(_midCache.keys.first);
        return _MidPlan.build(w, h);
      });

  static void _mid(Canvas c, double w, double h) {
    final plan = _midPlan(w, h);
    final x0 = -h * .22, x1 = w + h * .58;
    final windows = <Color, List<Offset>>{};
    // Towers behind the spire first, then the spire, then its neighbours'
    // bridges and screens.
    for (final t in plan.towers) {
      _midTower(c, h, t, windows);
    }
    _midWindows(c, h, windows);
    for (final (a, b, y) in plan.bridges) {
      _midBridge(c, h, a, b, y);
    }
    for (final (r, kind) in plan.screens) {
      _screenFrame(c, h, r, kind);
    }
    _spire(c, _spireX(w, h), h);
    _rail(c, h, x0, x1);
    // Street glow rising from the canal level between the towers' feet.
    c.drawRect(
      Rect.fromLTRB(x0, h * .56, x1, h * .78),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .56),
          Offset(0, h * .78),
          [
            Sketch.fade(const Color(0xffff6ab4), 0),
            Sketch.fade(const Color(0xffff6ab4), .22),
            Sketch.fade(const Color(0xffffa0c8), .3),
          ],
          const [0, .7, 1],
        ),
    );
  }

  static final _midBody = <double, (Paint, Paint)>{};

  /// The glass of the mid towers: deep blue at the crown warming to violet
  /// where the street glow reaches it, and the moonlit face.
  static (Paint, Paint) _midInk(double h) => _midBody.putIfAbsent(h, () {
    if (_midBody.length > 4) _midBody.remove(_midBody.keys.first);
    return (
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .25),
          Offset(0, h * .76),
          const [Color(0xff111237), Color(0xff17164a), Color(0xff2c1c5e)],
          const [0, .55, 1],
        ),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .25),
          Offset(0, h * .76),
          const [Color(0xff2a2c6e), Color(0xff262565), Color(0xff3c2872)],
          const [0, .55, 1],
        ),
    );
  });

  /// A mid tower's silhouette: 0 raked slab, 1 rounded shoulder, 2 setback,
  /// 3 twin slabs, 4 drum, 5 finned crown.
  static Path _midShape(
    double x,
    double hw,
    double top,
    int style,
    double base,
  ) {
    final l = x - hw, r = x + hw;
    switch (style) {
      case 0:
        return Path()..addPolygon([
          Offset(l, base),
          Offset(l, top + hw * .9),
          Offset(r, top),
          Offset(r, base),
        ], true);
      case 1:
        return Path()
          ..moveTo(l, base)
          ..lineTo(l, top)
          ..lineTo(r - hw, top)
          ..arcToPoint(Offset(r, top + hw), radius: Radius.circular(hw))
          ..lineTo(r, base)
          ..close();
      case 2:
        return Path()..addPolygon([
          Offset(l, base),
          Offset(l, top + hw * 1.4),
          Offset(l + hw * .45, top + hw * 1.4),
          Offset(l + hw * .45, top),
          Offset(r, top),
          Offset(r, base),
        ], true);
      case 3:
        return Path()
          ..addRect(Rect.fromLTRB(l, top + hw * 1.6, x + hw * .1, base))
          ..addRect(Rect.fromLTRB(x - hw * .1, top, r, base));
      case 4:
        return Path()..addRRect(
          RRect.fromLTRBAndCorners(
            l,
            top,
            r,
            base,
            topLeft: Radius.elliptical(hw, hw * .35),
            topRight: Radius.elliptical(hw, hw * .35),
          ),
        );
      default:
        final path = Path()..addRect(Rect.fromLTRB(l, top, r, base));
        for (var k = 0; k < 3; k++) {
          final fx = l + hw * (.4 + k * .6);
          path.addRect(
            Rect.fromLTRB(fx, top - hw * (.5 + .3 * k), fx + hw * .14, top),
          );
        }
        return path;
    }
  }

  /// One sleek glass tower: body, moonlit face, a rim of street glow, glass
  /// mullions, LED floor bands, lit windows and a light line on its crown.
  static void _midTower(
    Canvas c,
    double h,
    (double, double, double, int, int) t,
    Map<Color, List<Offset>> windows,
  ) {
    final (x, hwu, topu, style, seed) = t;
    final hw = hwu * h, top = topu * h, base = h * .8;
    final (body, lit) = _midInk(h);
    final shape = _midShape(x, hw, top, style, base);
    c.drawPath(shape, body);
    c.save();
    c.clipPath(shape);
    c.drawRect(
      Rect.fromLTRB(x + hw * .56, top - hw * 2, x + hw * 1.2, base),
      lit,
    );
    final thin = math.max(.8, h * .0016);
    c.drawRect(
      Rect.fromLTRB(x - hw, top - hw * 2, x - hw + thin, base),
      Paint()..color = Sketch.fade(_pink, .5),
    );
    c.drawRect(
      Rect.fromLTRB(x + hw - thin, top - hw * 2, x + hw, base),
      Paint()..color = Sketch.fade(const Color(0xffa8b4ff), .34),
    );
    // Mullions.
    final mullion = Paint()
      ..color = const Color(0x1ab8c0ff)
      ..strokeWidth = math.max(.6, h * .001);
    final cols = math.max(2, (hw * 2 / (h * .012)).round());
    for (var k = 1; k < cols; k++) {
      final mx = x - hw + hw * 2 * k / cols;
      c.drawLine(Offset(mx, top), Offset(mx, base), mullion);
    }
    // LED floor bands every few floors, in the tower's colour.
    final color = switch (seed % 5) {
      0 => _cyan,
      1 => _magenta,
      2 => _violet,
      3 => _ice,
      _ => _pink,
    };
    final bandEvery = h * (.05 + .04 * Sketch.hash(seed + 9600));
    final band = Paint()
      ..color = Sketch.fade(color, .5)
      ..strokeWidth = math.max(.7, h * .0014);
    for (var y = top + bandEvery * .7; y < h * .74; y += bandEvery) {
      c.drawLine(Offset(x - hw, y), Offset(x + hw, y), band);
    }
    c.restore();
    // Lit windows, sparse and cool, the odd office floor left on.
    final pitchX = h * .0095, pitchY = h * .011;
    final n = ((hw * 2 - h * .006) / pitchX).floor();
    final x0 = x - (n - 1) * pitchX / 2;
    var row = 0;
    for (var y = top + hw * 1.8 + h * .01; y < h * .74; y += pitchY, row++) {
      final office = Sketch.hash(seed * 131 + row * 17) > .9;
      for (var k = 0; k < n; k++) {
        final r = Sketch.hash(seed * 1013 + row * 37 + k * 11);
        if (!office && r > .24) continue;
        final tint = office
            ? const Color(0xffdff2ff)
            : (r < .12
                  ? const Color(0xffcfe4ff)
                  : (r < .18 ? _ice : (r < .21 ? _pink : _amber)));
        windows
            .putIfAbsent(tint, () => <Offset>[])
            .add(Offset(x0 + k * pitchX, y));
      }
    }
    // The crown's light line.
    final crown = switch (style) {
      0 =>
        Path()
          ..moveTo(x - hw, top + hw * .9)
          ..lineTo(x + hw, top),
      1 =>
        Path()
          ..moveTo(x - hw, top)
          ..lineTo(x, top)
          ..arcToPoint(Offset(x + hw, top + hw), radius: Radius.circular(hw)),
      2 =>
        Path()
          ..moveTo(x - hw, top + hw * 1.4)
          ..lineTo(x - hw * .55, top + hw * 1.4)
          ..moveTo(x - hw * .55, top)
          ..lineTo(x + hw, top),
      3 =>
        Path()
          ..moveTo(x - hw * .1, top)
          ..lineTo(x + hw, top),
      4 =>
        Path()
          ..moveTo(x - hw, top + hw * .35)
          ..quadraticBezierTo(x, top - hw * .1, x + hw, top + hw * .35),
      _ =>
        Path()
          ..moveTo(x - hw, top)
          ..lineTo(x + hw, top),
    };
    _neon(c, crown, color, h * .0017, alpha: .85);
  }

  static void _midWindows(
    Canvas c,
    double h,
    Map<Color, List<Offset>> windows,
  ) {
    final pen = Paint()
      ..strokeWidth = math.max(1.1, h * .0034)
      ..strokeCap = StrokeCap.square;
    windows.forEach((color, points) {
      c.drawPoints(
        PointMode.points,
        points,
        pen..color = Sketch.fade(color, .8),
      );
    });
  }

  /// A glazed sky bridge between two towers, its walkway lit.
  static void _midBridge(Canvas c, double h, double a, double b, double y) {
    final r = Rect.fromLTRB(a, y * h - h * .007, b, y * h + h * .007);
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(h * .007)),
      Paint()..color = const Color(0xff1a1a4a),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(h * .002), Radius.circular(h * .005)),
      Paint()..color = const Color(0xff2d3274),
    );
    final lamp = Paint()..color = Sketch.fade(_ice, .8);
    for (var x = a + h * .008; x < b - h * .006; x += h * .011) {
      c.drawRect(Rect.fromLTWH(x, y * h - h * .002, h * .006, h * .003), lamp);
    }
    c.drawLine(
      Offset(a, y * h + h * .006),
      Offset(b, y * h + h * .006),
      Paint()
        ..color = Sketch.fade(_cyan, .6)
        ..strokeWidth = math.max(.7, h * .0014),
    );
  }

  /// A giant screen's frame and the backdrop of what it plays;
  /// [_screenLive] animates it.
  static void _screenFrame(Canvas c, double h, Rect r, int kind) {
    _bloom(c, r.center, r.width * .9, r.height * .75, _violet, .25);
    c.drawRect(r.inflate(h * .004), Paint()..color = const Color(0xff0c0b26));
    c.drawRect(r, switch (kind) {
      0 => Paint()..color = const Color(0xff0a1e3a),
      1 =>
        Paint()
          ..shader = Gradient.linear(r.topLeft, r.bottomLeft, const [
            Color(0xff2a0a44),
            Color(0xff4a0f5a),
          ]),
      _ => Paint()..color = const Color(0xff101238),
    });
  }

  /// The space elevator's anchor arcology: two tapering blades of dark glass
  /// split around a core of light, girdled by halo platforms, with the
  /// anchor station at the top. The tether and its climbers are live.
  static void _spire(Canvas c, double x, double h) {
    final top = _spireTop * h;
    // The glow the arcology throws on the smog around it.
    _bloom(c, Offset(x, h * .36), h * .2, h * .42, _cyan, .12);
    _bloom(c, Offset(x, h * .6), h * .3, h * .2, _magenta, .14);
    // The far halves of the halo rings pass behind the blades.
    for (final (y, reach, color) in _halos) {
      _halo(c, x, h, y, reach, color, back: true);
    }
    // The blades: stepped outer edges from the profile, the slot inside.
    for (final side in const [-1.0, 1.0]) {
      final outer = [
        for (final (y, half) in _spireProfile)
          Offset(x + side * half * h, y * h),
      ];
      final inner = [
        for (var i = 0; i <= 24; i++)
          (_spireTop + (_spireBase - _spireTop) * i / 24),
      ].map((y) => Offset(x + side * _spireSlot(y) * h, y * h)).toList();
      final blade = Path()..moveTo(inner.first.dx, top);
      for (final p in outer) {
        blade.lineTo(p.dx, p.dy);
      }
      for (final p in inner.reversed) {
        blade.lineTo(p.dx, p.dy);
      }
      blade.close();
      c.drawPath(
        blade,
        Paint()
          ..shader = Gradient.linear(
            Offset(0, top),
            Offset(0, h * .76),
            [
              side < 0 ? const Color(0xff13133f) : const Color(0xff1d2160),
              side < 0 ? const Color(0xff101038) : const Color(0xff1a1d56),
              side < 0 ? const Color(0xff24164e) : const Color(0xff2e2064),
            ],
            const [0, .5, 1],
          ),
      );
      c.save();
      c.clipPath(blade);
      // Facets: a lighter plane on each blade's outer half, stepping with
      // the terraces.
      final facet = Path()..moveTo(x + side * _spireSlot(_spireTop) * h, top);
      for (final (y, half) in _spireProfile) {
        facet.lineTo(x + side * (half * .5 + _spireSlot(y) * .5) * h, y * h);
      }
      for (final (y, half) in _spireProfile.reversed) {
        facet.lineTo(x + side * half * h, y * h);
      }
      facet.close();
      c.drawPath(
        facet,
        Paint()
          ..color = side < 0
              ? const Color(0x20ff8ad0)
              : const Color(0x2a8ea8ff),
      );
      // Floors: faint ribs that follow the taper, and lit windows.
      final rib = Paint()
        ..color = const Color(0x28c8d0ff)
        ..strokeWidth = math.max(.6, h * .001);
      final lights = <Offset>[];
      var row = 0;
      for (var y = _spireTop + .016; y < .76; y += .0095, row++) {
        final a = _spireSlot(y) * h, b = _spireHalf(y) * h;
        c.drawLine(
          Offset(x + side * a, y * h),
          Offset(x + side * b, y * h),
          rib,
        );
        final count = ((b - a) / (h * .0078)).floor();
        for (var k = 0; k < count; k++) {
          final n = Sketch.hash(
            row * 53 + k * 7 + (side < 0 ? 0 : 5000) + 9700,
          );
          if (n > .22) continue;
          lights.add(
            Offset(
              x + side * (a + h * .005 + k * h * .0078),
              y * h + h * .0048,
            ),
          );
        }
      }
      c.drawPoints(
        PointMode.points,
        lights,
        Paint()
          ..strokeWidth = math.max(1.0, h * .0026)
          ..strokeCap = StrokeCap.square
          ..color = Sketch.fade(
            side < 0 ? const Color(0xffffc6ec) : const Color(0xffcfeaff),
            .8,
          ),
      );
      // A light seam down each blade's facet line.
      final seam = Path()
        ..moveTo(
          x +
              side *
                  (_spireProfile.first.$2 * .5 + _spireSlot(_spireTop) * .5) *
                  h,
          top,
        );
      for (final (y, half) in _spireProfile.skip(1)) {
        seam.lineTo(x + side * (half * .5 + _spireSlot(y) * .5) * h, y * h);
      }
      c.drawPath(
        seam,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.6, h * .0011)
          ..color = Sketch.fade(side < 0 ? _pink : _ice, .35),
      );
      c.restore();
      // Rim light down the stepped outer edge.
      final rim = Path()..moveTo(outer.first.dx, outer.first.dy);
      for (final p in outer.skip(1)) {
        rim.lineTo(p.dx, p.dy);
      }
      _neon(c, rim, side < 0 ? _magenta : _cyan, h * .0015, alpha: .8);
    }
    // The core of light through the slot.
    final core = Path()
      ..moveTo(x, top + h * .01)
      ..lineTo(x, h * .78);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      core,
      pen
        ..strokeWidth = h * .04
        ..color = Sketch.fade(_cyan, .08),
    );
    c.drawPath(
      core,
      pen
        ..strokeWidth = h * .014
        ..color = Sketch.fade(_cyan, .22),
    );
    for (final side in const [-1.0, 1.0]) {
      final slot = Path()..moveTo(x, top + h * .01);
      for (var i = 1; i <= 20; i++) {
        final y = _spireTop + .01 + (.78 - _spireTop - .01) * i / 20;
        slot.lineTo(x + side * _spireSlot(y) * h * .9, y * h);
      }
      slot.lineTo(x, h * .78);
      slot.close();
      c.drawPath(slot, Paint()..color = const Color(0xffbff8ff));
    }
    c.drawPath(
      core,
      pen
        ..strokeWidth = math.max(.8, h * .0018)
        ..color = _white,
    );
    // The front halves of the halo rings.
    for (final (y, reach, color) in _halos) {
      _halo(c, x, h, y, reach, color, back: false);
    }
    // The tether: a thread of light from the anchor station up out of the
    // sky, fading as it climbs.
    final tether = (Offset(x, top - h * .01), Offset(x, -h * .02));
    c.drawLine(
      tether.$1,
      tether.$2,
      Paint()
        ..strokeWidth = h * .012
        ..shader = Gradient.linear(tether.$1, tether.$2, [
          Sketch.fade(_cyan, .18),
          Sketch.fade(_cyan, 0),
        ]),
    );
    c.drawLine(
      tether.$1,
      tether.$2,
      Paint()
        ..strokeWidth = math.max(1.0, h * .0024)
        ..shader = Gradient.linear(
          tether.$1,
          tether.$2,
          [
            Sketch.fade(_ice, .95),
            Sketch.fade(_ice, .5),
            Sketch.fade(_ice, .12),
          ],
          const [0, .45, 1],
        ),
    );
    // The anchor station: a lens of light where the tether leaves.
    _bloom(c, Offset(x, top - h * .004), h * .05, h * .05, _ice, .5);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x, top - h * .002),
        width: h * .036,
        height: h * .012,
      ),
      Paint()..color = const Color(0xff2a2c6a),
    );
    _neon(
      c,
      Path()..addOval(
        Rect.fromCenter(
          center: Offset(x, top - h * .002),
          width: h * .036,
          height: h * .012,
        ),
      ),
      _ice,
      h * .0014,
    );
    c.drawCircle(Offset(x, top - h * .008), h * .004, Paint()..color = _white);
  }

  /// One halo platform: a flat ring round the spire at height [y]; [back]
  /// draws the half that passes behind the blades.
  static void _halo(
    Canvas c,
    double x,
    double h,
    double y,
    double reach,
    Color color, {
    required bool back,
  }) {
    final half = _haloHalf(y, reach) * h;
    final oval = Rect.fromCenter(
      center: Offset(x, y * h),
      width: half * 2,
      height: half * .22,
    );
    final start = back ? math.pi : 0.0;
    final deck = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .006
      ..color = back ? const Color(0xff1d1a4e) : const Color(0xff2a2766);
    c.drawArc(oval, start, math.pi, false, deck);
    final path = Path()..addArc(oval.inflate(h * .002), start, math.pi);
    _neon(c, path, color, h * (back ? .0011 : .0017), alpha: back ? .5 : .95);
    if (!back) {
      // Windows along the platform's lit edge.
      final lamp = Paint()..color = Sketch.fade(_white, .8);
      for (var k = 1; k < 14; k++) {
        final a = math.pi * k / 14;
        c.drawCircle(
          Offset(
            x + math.cos(a) * half,
            y * h + math.sin(a) * half * .11 + h * .003,
          ),
          math.max(.6, h * .0011),
          lamp,
        );
      }
    }
  }

  /// The maglev guideway's top edge at x (pixels), in pixels.
  static double _railY(double x, double h) =>
      h *
      (.498 +
          .018 * math.sin(x / h * 1.7 + .5) +
          .007 * math.sin(x / h * 4.1 + 1.3));

  /// The maglev guideway: a slender beam on T-pylons with a light strip
  /// along its edge and lamps beneath.
  static void _rail(Canvas c, double h, double x0, double x1) {
    final step = h * .02;
    final top = Path(), under = <Offset>[];
    final beam = Path();
    final pts = <Offset>[];
    for (var x = x0; x <= x1 + step; x += step) {
      pts.add(Offset(x, _railY(x, h)));
    }
    beam.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      beam.lineTo(p.dx, p.dy);
    }
    for (final p in pts.reversed) {
      beam.lineTo(p.dx, p.dy + h * .011);
    }
    beam.close();
    // Pylons first, behind the beam.
    final pylon = Paint()..color = const Color(0xff15143e);
    final pylonLit = Paint()..color = const Color(0xff2e2a6c);
    for (var x = x0 + h * .1; x < x1; x += h * .34) {
      final y = _railY(x, h) + h * .011;
      c.drawPath(
        Sketch.poly([
          x - h * .006,
          y,
          x + h * .006,
          y,
          x + h * .004,
          h * .8,
          x - h * .004,
          h * .8, //
        ]),
        pylon,
      );
      c.drawRect(
        Rect.fromLTRB(x + h * .002, y, x + h * .005, h * .8),
        pylonLit,
      );
      c.drawRect(
        Rect.fromLTRB(x - h * .016, y, x + h * .016, y + h * .005),
        pylon,
      );
      under.add(Offset(x, y + h * .008));
    }
    c.drawPath(
      beam,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .47),
          Offset(0, h * .53),
          const [Color(0xff34357a), Color(0xff1a1a48)],
        ),
    );
    for (final p in pts) {
      top.addRect(
        Rect.fromLTWH(
          p.dx,
          p.dy + h * .0055,
          h * .008,
          math.max(.8, h * .0014),
        ),
      );
    }
    c.drawPath(top, Paint()..color = Sketch.fade(_amber, .55));
    final edge = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      edge.lineTo(p.dx, p.dy);
    }
    _neon(c, edge, _cyan, h * .0016, alpha: .9);
    final lamp = Paint()..color = _red;
    for (final p in under) {
      c.drawCircle(p, h * .0018, lamp);
    }
  }

  void _midLive(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h;
    final plan = _midPlan(w, h);
    for (final (r, kind) in plan.screens) {
      _screenLive(c, f, r, kind);
    }
    _tether(c, f, _spireX(w, h));
    _haloLights(c, f, _spireX(w, h));
    _spireKoi(c, f, _spireX(w, h));
    _train(c, f, -h * .22, w + h * .58);
  }

  /// Climbers riding the tether up (cyan) and down (magenta); the thread
  /// itself is static, drawn with the spire.
  void _tether(Canvas c, SceneFrame f, double x) {
    final h = f.h, top = _spireTop * h - h * .01;
    for (var k = 0; k < 3; k++) {
      final up = k != 1;
      final period = 9.0 + k * 2;
      final u = ((f.clock / period + k * .37) % 1);
      final t = up ? u : 1 - u;
      final y = top - (top + h * .04) * t;
      final color = up ? _cyan : _magenta;
      final fade = (1 - t * .8).clamp(0.0, 1.0);
      _bloom(c, Offset(x, y), h * .014, h * .02, color, .5 * fade);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: h * .0065,
            height: h * .016,
          ),
          Radius.circular(h * .003),
        ),
        Paint()..color = Sketch.fade(Sketch.mix(color, _white, .6), fade),
      );
    }
  }

  /// A holographic koi as big as a tower swims slow loops round the space
  /// elevator: larger and brighter on the near side of its orbit, faint and
  /// small when it passes behind.
  void _spireKoi(Canvas c, SceneFrame f, double x) {
    final h = f.h;
    final theta = f.clock * .21 + 1.1;
    final near = (math.sin(theta) + 1) / 2;
    final at = Offset(
      x + math.cos(theta) * h * .21,
      h * (.27 + .035 * math.sin(theta) + .006 * math.sin(f.clock * .9)),
    );
    final dir = -math.sin(theta) >= 0 ? 1.0 : -1.0;
    _koi(
      c,
      at,
      h * (.11 + .05 * near),
      dir,
      f.clock * 2.6,
      .45 + .5 * near,
      body: _cyan,
      spots: _magenta,
    );
  }

  /// Lights running round the front of each halo platform.
  void _haloLights(Canvas c, SceneFrame f, double x) {
    final h = f.h;
    final paint = Paint();
    for (final (i, (y, reach, color)) in _halos.indexed) {
      final half = _haloHalf(y, reach) * h;
      for (var k = 0; k < 3; k++) {
        final a = ((f.clock * (.18 + i * .05) + k / 3 + i * .2) % 1) * math.pi;
        final p = Offset(
          x + math.cos(a) * half,
          y * h + math.sin(a) * half * .11,
        );
        _bloom(c, p, h * .012, h * .006, color, .6);
        c.drawCircle(p, h * .0018, paint..color = _white);
      }
    }
  }

  static final _trainPaints = <double, Paint>{};

  /// The maglev: five sleek cars riding the guideway's curve, a headlight
  /// ahead of the nose, a light band along the windows.
  void _train(Canvas c, SceneFrame f, double x0, double x1) {
    final h = f.h;
    final since = ((_legTime(f) - 4.6) % 11 + 11) % 11;
    final head = x0 + since * .34 * h;
    const cars = 5;
    final car = h * .085, gap = h * .004;
    final paint = _trainPaints.putIfAbsent(h, () {
      if (_trainPaints.length > 3) _trainPaints.remove(_trainPaints.keys.first);
      return Paint()
        ..shader = Gradient.linear(
          Offset(0, -h * .017),
          Offset.zero,
          const [Color(0xfff2f2ff), Color(0xffb8bce0), Color(0xff6a6ca8)],
          const [0, .55, 1],
        );
    });
    if (head - cars * (car + gap) > x1) return;
    _bloom(
      c,
      Offset(head + h * .05, _railY(head + h * .05, h) - h * .012),
      h * .07,
      h * .02,
      _ice,
      .35,
    );
    for (var k = 0; k < cars; k++) {
      final front = head - k * (car + gap);
      final back = front - car;
      final a = Offset(back, _railY(back, h) - h * .004);
      final b = Offset(front, _railY(front, h) - h * .004);
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      final len = (b - a).distance;
      c.save();
      c.translate(a.dx, a.dy);
      c.rotate(angle);
      final body = Path();
      if (k == 0) {
        body
          ..moveTo(0, 0)
          ..lineTo(0, -h * .017)
          ..lineTo(len * .62, -h * .017)
          ..quadraticBezierTo(len, -h * .016, len, 0)
          ..close();
      } else if (k == cars - 1) {
        body
          ..moveTo(len, 0)
          ..lineTo(len, -h * .017)
          ..lineTo(len * .3, -h * .017)
          ..quadraticBezierTo(0, -h * .015, 0, 0)
          ..close();
      } else {
        body.addRRect(
          RRect.fromLTRBR(0, -h * .017, len, 0, Radius.circular(h * .003)),
        );
      }
      c.drawPath(body, paint);
      // The window band with its light line.
      c.drawRect(
        Rect.fromLTRB(
          len * (k == 0 ? .08 : .04),
          -h * .013,
          len * (k == 0 ? .6 : .96),
          -h * .008,
        ),
        Paint()..color = const Color(0xff161a44),
      );
      c.drawRect(
        Rect.fromLTRB(
          len * (k == 0 ? .08 : .04),
          -h * .0098,
          len * (k == 0 ? .6 : .96),
          -h * .0082,
        ),
        Paint()..color = _cyan,
      );
      c.drawRect(
        Rect.fromLTRB(0, -h * .0022, len, -h * .0008),
        Paint()..color = Sketch.fade(_magenta, .9),
      );
      if (k == 0) {
        c.drawCircle(
          Offset(len * .96, -h * .004),
          h * .0022,
          Paint()..color = _white,
        );
      }
      if (k == cars - 1) {
        c.drawCircle(
          Offset(len * .04, -h * .004),
          h * .002,
          Paint()..color = _red,
        );
      }
      c.restore();
    }
  }

  static final _screenPen = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square;

  /// What plays on a giant screen: 0 glyph rain, 1 flowing wave bands,
  /// 2 a turning emblem over an equaliser. A glitch tears a slice across
  /// it now and then.
  void _screenLive(Canvas c, SceneFrame f, Rect r, int kind) {
    final h = f.h, t = f.clock;
    c.save();
    c.clipRect(r);
    switch (kind) {
      case 0:
        final cols = math.max(3, (r.width / (h * .011)).floor());
        final cw = r.width / cols, gh = cw * 1.25;
        final heads = Path(), trail = Path(), faint = Path();
        for (var k = 0; k < cols; k++) {
          final speed = h * (.03 + .03 * Sketch.hash(k + 9800));
          final head =
              (t * speed + Sketch.hash(k + 9810) * r.height * 2) %
              (r.height * 1.6);
          for (var j = 0; j < 7; j++) {
            final y = r.top + head - j * gh;
            if (y < r.top - gh || y > r.bottom) continue;
            final glyph = (k * 7 + j + (t * 3).floor()) % _glyphCount;
            _addGlyph(
              j == 0 ? heads : (j < 3 ? trail : faint),
              glyph,
              Offset(r.left + k * cw + cw * .2, y),
              cw * .6,
            );
          }
        }
        _glyphPen.strokeWidth = math.max(.8, cw * .12);
        c.drawPath(faint, _glyphPen..color = Sketch.fade(_cyan, .35));
        c.drawPath(trail, _glyphPen..color = Sketch.fade(_cyan, .75));
        c.drawPath(heads, _glyphPen..color = _white);
      case 1:
        for (var k = 0; k < 5; k++) {
          final path = Path();
          for (var i = 0; i <= 16; i++) {
            final x = r.left + r.width * i / 16;
            final y =
                r.top +
                r.height * (.2 + k * .15) +
                math.sin(i / 16 * math.pi * 2 + t * (1.1 + k * .3) + k) *
                    r.height *
                    .08;
            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          c.drawPath(
            path,
            _screenPen
              ..strokeWidth = r.height * .06
              ..color = Sketch.fade(
                [_magenta, _pink, _violet, _cyan, _ice][k],
                .75,
              ),
          );
        }
      default:
        final mid = r.center - Offset(0, r.height * .12);
        final s = math.min(r.width, r.height) * .3;
        final hexagon = Path();
        for (var i = 0; i < 6; i++) {
          final a = t * .8 + i * math.pi / 3;
          final p = mid + Offset(math.cos(a), math.sin(a) * .9) * s;
          if (i == 0) {
            hexagon.moveTo(p.dx, p.dy);
          } else {
            hexagon.lineTo(p.dx, p.dy);
          }
        }
        hexagon.close();
        c.drawPath(
          hexagon,
          _screenPen
            ..strokeWidth = math.max(1.0, h * .0024)
            ..color = _lime,
        );
        c.drawCircle(
          mid,
          s * (.35 + .1 * math.sin(t * 3)),
          Paint()..color = Sketch.fade(_lime, .8),
        );
        final bars = 9;
        final bw = r.width / bars;
        for (var k = 0; k < bars; k++) {
          final v =
              .3 + .7 * (.5 + .5 * math.sin(t * (3 + k * .7) + k * 1.3)).abs();
          c.drawRect(
            Rect.fromLTRB(
              r.left + k * bw + bw * .2,
              r.bottom - r.height * .3 * v,
              r.left + k * bw + bw * .8,
              r.bottom - r.height * .04,
            ),
            Paint()..color = Sketch.fade(k.isEven ? _cyan : _lime, .8),
          );
        }
    }
    // Scanlines and the glass sheen.
    final scan = Paint()..color = const Color(0x26000000);
    for (var y = r.top; y < r.bottom; y += math.max(2.0, h * .005)) {
      c.drawRect(
        Rect.fromLTWH(r.left, y, r.width, math.max(.7, h * .0016)),
        scan,
      );
    }
    final tick = (t * 1.5).floor();
    if (t != 0 && Sketch.hash(tick * 7 + kind + 9900) > .82) {
      final y = r.top + r.height * Sketch.hash(tick * 11 + kind + 9910);
      c.drawRect(
        Rect.fromLTWH(r.left, y, r.width, r.height * .12),
        Paint()..color = Sketch.fade(kind == 1 ? _cyan : _magenta, .45),
      );
    }
    c.restore();
  }
  // ---------------------------------------------------------------------------
  // Low band: the canal. Neon-signed fronts on the far bank, an elevated
  // freeway streaming with lights, and water that doubles all of it.

  /// Repeat width of the low band (as [period]), in viewport heights.
  static const _canalSpan = 2.4;

  /// The freeway deck's top edge, in viewport heights.
  static const _roadY = .594;

  /// Canal-front blocks along one repeat: (x, width, roof) in viewport
  /// heights. The widths add up to the repeat, so the row tiles.
  static final _canalBlocks = _canalMakeBlocks();

  static List<(double, double, double)> _canalMakeBlocks() {
    final blocks = <(double, double, double)>[];
    var x = 0.0;
    for (var i = 0; x < _canalSpan - .001; i++) {
      var w = .1 + .13 * Sketch.hash(i + 10100);
      if (_canalSpan - x - w < .1) w = _canalSpan - x;
      blocks.add((x, w, .628 + .06 * Sketch.hash(i + 10110)));
      x += w;
    }
    return blocks;
  }

  static const _signColors = [_magenta, _cyan, _lime, _amber, _pink, _violet];

  /// The bank's neon signs: a rectangle in viewport heights, a colour index
  /// and whether the sign flickers. Tall signs hang on the facades; wide
  /// ones run above the shop fronts.
  static final _canalSigns = _canalMakeSigns();

  static List<(Rect, int, bool)> _canalMakeSigns() {
    final signs = <(Rect, int, bool)>[];
    for (var i = 0; i < _canalBlocks.length; i++) {
      final (bx, bw, roof) = _canalBlocks[i];
      final n = Sketch.hash(i + 10200);
      final color = (Sketch.hash(i + 10210) * _signColors.length).floor();
      if (n < .7) {
        final sw = .02 + .008 * Sketch.hash(i + 10220);
        final sx = bx + .01 + (bw - sw - .02) * Sketch.hash(i + 10230);
        final top = roof + .012;
        signs.add((
          Rect.fromLTRB(
            sx,
            top,
            sx + sw,
            math.min(top + .065 + .04 * Sketch.hash(i + 10240), .702),
          ),
          color,
          Sketch.hash(i + 10250) < .3,
        ));
      }
      if (n > .28 && bw > .12) {
        final sw = bw * (.45 + .3 * Sketch.hash(i + 10260));
        signs.add((
          Rect.fromLTWH(bx + (bw - sw) / 2, .714, sw, .017),
          (color + 2) % _signColors.length,
          Sketch.hash(i + 10270) < .2,
        ));
      }
    }
    return signs;
  }

  /// A neon sign: a dark box with a thin frame and a row or column of
  /// glowing invented glyphs. [on] dims it through a flicker.
  static void _sign(
    Canvas c,
    Rect r,
    Color color,
    int seed, {
    double on = 1,
    bool halo = true,
  }) {
    final vertical = r.height > r.width;
    if (halo) {
      _bloom(
        c,
        r.center,
        r.width * (vertical ? 2.4 : .9),
        r.height * (vertical ? .9 : 2.6),
        color,
        .3 * on,
      );
    }
    c.drawRect(r, Paint()..color = const Color(0xff0e0b26));
    c.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, r.shortestSide * .08)
        ..color = Sketch.fade(color, .45 * on + .1),
    );
    final glyphs = Path();
    final size = r.shortestSide * .62;
    if (vertical) {
      final n = math.max(1, ((r.height - size * .4) / (size * 1.55)).floor());
      final y0 = r.top + (r.height - n * size * 1.55 + size * .25) / 2;
      for (var k = 0; k < n; k++) {
        _addGlyph(
          glyphs,
          seed * 5 + k,
          Offset(r.center.dx - size / 2, y0 + k * size * 1.55),
          size,
        );
      }
    } else {
      final gs = r.height * .5;
      final n = math.max(1, ((r.width - gs) / (gs * 1.5)).floor());
      final x0 = r.left + (r.width - n * gs * 1.5 + gs * .5) / 2;
      for (var k = 0; k < n; k++) {
        _addGlyph(
          glyphs,
          seed * 5 + k,
          Offset(x0 + k * gs * 1.5, r.top + r.height * .18),
          gs,
        );
      }
    }
    _neon(c, glyphs, color, math.max(.6, size * .09), alpha: on);
  }

  /// The far bank, static: blocks with lit windows and signs, shop fronts,
  /// the freeway on its pillars and the promenade along the water.
  static void _canalBank(Canvas c, double h) {
    final span = _canalSpan * h, wl = _wl * h, pad = h * .6;
    final fill = Paint();
    c.drawRect(
      Rect.fromLTRB(0, h * .69, span, wl + h * .02),
      fill..color = const Color(0xff1a1542),
    );
    final lit = <Color, List<Offset>>{};
    final balcony = Path();
    for (var i = 0; i < _canalBlocks.length; i++) {
      final (bx, bw, roof) = _canalBlocks[i];
      final r = Rect.fromLTWH(
        bx * h,
        roof * h,
        bw * h,
        wl - roof * h + h * .02,
      );
      final tone = Sketch.mix(
        const Color(0xff161239),
        const Color(0xff22194e),
        Sketch.hash(i + 10300),
      );
      c.drawRect(
        r,
        fill
          ..shader = Gradient.linear(r.topLeft, r.bottomLeft, [
            tone,
            Sketch.mix(tone, const Color(0xff4a2270), .55),
          ]),
      );
      fill.shader = null;
      // A moonlit right edge, a rim of glow on the left and a cap line.
      c.drawRect(
        Rect.fromLTRB(r.right - h * .006, r.top, r.right, r.bottom),
        fill..color = Sketch.fade(const Color(0xff4c4a9a), .45),
      );
      c.drawRect(
        Rect.fromLTRB(
          r.left,
          r.top,
          r.left + math.max(.8, h * .0015),
          r.bottom,
        ),
        fill..color = Sketch.fade(_pink, .3),
      );
      c.drawRect(
        Rect.fromLTWH(r.left, r.top, r.width, math.max(.8, h * .0018)),
        fill..color = const Color(0xff5a4fa6),
      );
      // Windows down to the shop signs, with thin balcony rails.
      final cols = ((bw - .012) / .0105).floor();
      var row = 0;
      for (var y = roof + .012; y < .706; y += .0105, row++) {
        if (row % 3 == 2) {
          balcony
            ..moveTo(r.left + h * .004, (y - .003) * h)
            ..lineTo(r.right - h * .004, (y - .003) * h);
        }
        for (var col = 0; col < cols; col++) {
          final n = Sketch.hash(i * 151 + col * 17 + row * 7 + 10310);
          if (n > .32) continue;
          final color = n < .17
              ? const Color(0xffcfe2ff)
              : (n < .24 ? _amber : (n < .28 ? _pink : _ice));
          lit
              .putIfAbsent(color, () => <Offset>[])
              .add(Offset((bx + .008 + col * .0105) * h, y * h));
        }
      }
      // Rooftop clutter: a mast or a plant box.
      final kind = Sketch.hash(i + 10320);
      if (kind < .3) {
        final mx = r.left + r.width * (.2 + .6 * Sketch.hash(i + 10330));
        c.drawLine(
          Offset(mx, r.top),
          Offset(mx, r.top - h * .03),
          Paint()
            ..color = const Color(0xff3a3478)
            ..strokeWidth = math.max(.7, h * .0015),
        );
      } else if (kind < .55) {
        c.drawRect(
          Rect.fromLTWH(
            r.left + r.width * .2,
            r.top - h * .008,
            r.width * .3,
            h * .008,
          ),
          fill..color = const Color(0xff211c50),
        );
      }
    }
    final pen = Paint()
      ..strokeWidth = math.max(1.0, h * .003)
      ..strokeCap = StrokeCap.square;
    lit.forEach((color, points) {
      c.drawPoints(
        PointMode.points,
        points,
        pen..color = Sketch.fade(color, .75),
      );
    });
    c.drawPath(
      balcony,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .0011)
        ..color = const Color(0x557a70d0),
    );
    // Shop fronts along the quay, lit in warm and cool colours, under
    // striped awnings, with a few passers-by in silhouette.
    const shopTop = .742;
    for (var i = 0; i < _canalBlocks.length; i++) {
      final (bx, bw, _) = _canalBlocks[i];
      final n = math.max(1, (bw / .07).round());
      final sw = bw / n;
      for (var k = 0; k < n; k++) {
        final seed = i * 13 + k;
        final pick = (Sketch.hash(seed + 10400) * 6).floor();
        final dark = pick == 5;
        final glow = _shopGlow[pick];
        final r = Rect.fromLTRB(
          (bx + k * sw + .006) * h,
          shopTop * h,
          (bx + (k + 1) * sw - .006) * h,
          wl - h * .004,
        );
        c.drawRect(
          r,
          fill
            ..shader = Gradient.linear(r.topLeft, r.bottomLeft, [
              Sketch.fade(glow, dark ? 1 : .85),
              Sketch.mix(glow, _white, dark ? 0 : .4),
            ]),
        );
        fill.shader = null;
        if (!dark) {
          _bloom(c, r.center, r.width * .8, h * .03, glow, .22);
          final people = (Sketch.hash(seed + 10410) * 3).floor();
          for (var p = 0; p < people; p++) {
            final px =
                r.left +
                r.width * (.2 + .6 * Sketch.hash(seed * 7 + p + 10420));
            final ph = h * (.017 + .004 * Sketch.hash(seed * 7 + p + 10430));
            c.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTRB(
                  px - h * .003,
                  r.bottom - ph,
                  px + h * .003,
                  r.bottom,
                ),
                Radius.circular(h * .003),
              ),
              fill..color = const Color(0xff120e2e),
            );
            c.drawCircle(Offset(px, r.bottom - ph - h * .003), h * .0033, fill);
          }
        }
        c.drawRect(
          Rect.fromLTRB(
            r.center.dx - h * .001,
            r.top,
            r.center.dx + h * .001,
            r.bottom,
          ),
          fill..color = const Color(0x6610082a),
        );
        final awning =
            _signColors[(Sketch.hash(seed + 10440) * _signColors.length)
                .floor()];
        c.drawPath(
          Sketch.poly([
            r.left - h * .002, r.top, r.right + h * .002, r.top, //
            r.right + h * .006, r.top + h * .007, r.left - h * .006,
            r.top + h * .007,
          ]),
          fill..color = Sketch.mix(awning, const Color(0xff1a1240), .55),
        );
        c.drawLine(
          Offset(r.left - h * .006, r.top + h * .007),
          Offset(r.right + h * .006, r.top + h * .007),
          Paint()
            ..color = Sketch.fade(awning, .9)
            ..strokeWidth = math.max(.7, h * .0014),
        );
      }
    }
    // Signs: tall ones on the facades, wide ones over the shops.
    for (final (r, color, _) in _canalSigns) {
      _sign(
        c,
        Rect.fromLTRB(r.left * h, r.top * h, r.right * h, r.bottom * h),
        _signColors[color],
        (r.left * 97 + r.top * 13).round(),
      );
    }
    // The promenade: a lit railing along the water's edge.
    c.drawRect(
      Rect.fromLTRB(-pad, wl - h * .005, span + pad, wl + h * .02),
      fill..color = const Color(0xff221c50),
    );
    c.drawLine(
      Offset(-pad, wl - h * .005),
      Offset(span + pad, wl - h * .005),
      Paint()
        ..color = Sketch.fade(_ice, .55)
        ..strokeWidth = math.max(.7, h * .0012),
    );
    for (var x = 0.0; x < span; x += h * .03) {
      c.drawRect(
        Rect.fromLTWH(x, wl - h * .01, math.max(.7, h * .0012), h * .005),
        fill..color = const Color(0xff3a3478),
      );
    }
    _canalFreeway(c, h, span, pad);
  }

  static const _shopGlow = [
    Color(0xffffc27a),
    Color(0xffff8fd6),
    Color(0xff8ff4ff),
    Color(0xffd8ff8a),
    Color(0xffffe0a8),
    Color(0xff2a2456),
  ];

  /// The elevated freeway high over the canal fronts: a slab with a lit
  /// fascia on slender pillars, a barrier light strip, amber soffit lamps
  /// and tall street lights.
  static void _canalFreeway(Canvas c, double h, double span, double pad) {
    final road = _roadY * h, wl = _wl * h;
    final fill = Paint();
    for (var x = h * .06; x < span; x += h * .3) {
      c.drawPath(
        Sketch.poly([
          x - h * .008, road + h * .016, x + h * .008, road + h * .016, //
          x + h * .006, wl, x - h * .006, wl,
        ]),
        fill..color = const Color(0xff15123a),
      );
      c.drawRect(
        Rect.fromLTRB(x + h * .002, road + h * .016, x + h * .006, wl),
        fill..color = const Color(0xff2c2766),
      );
      // A pillar-mounted sign faces the water.
      c.drawRect(
        Rect.fromLTRB(
          x - h * .012,
          road + h * .016,
          x + h * .012,
          road + h * .022,
        ),
        fill..color = const Color(0xff15123a),
      );
    }
    final deck = Rect.fromLTRB(-pad, road, span + pad, road + h * .016);
    c.drawRect(
      deck,
      fill
        ..shader = Gradient.linear(
          deck.topLeft,
          deck.bottomLeft,
          const [Color(0xff3a3478), Color(0xff23205a), Color(0xff120f34)],
          const [0, .45, 1],
        ),
    );
    fill.shader = null;
    // The fascia's accent stripe and the soffit lamps.
    c.drawRect(
      Rect.fromLTRB(-pad, road + h * .007, span + pad, road + h * .0085),
      fill..color = Sketch.fade(_magenta, .75),
    );
    final soffit = Paint()..color = Sketch.fade(_amber, .85);
    for (var x = h * .02; x < span; x += h * .04) {
      c.drawRect(
        Rect.fromLTWH(x, road + h * .0152, h * .012, math.max(.8, h * .0014)),
        soffit,
      );
    }
    // Barrier strip.
    c.drawRect(
      Rect.fromLTRB(-pad, road - h * .004, span + pad, road),
      fill..color = const Color(0xff221d52),
    );
    _neon(
      c,
      Path()
        ..moveTo(-pad, road - h * .004)
        ..lineTo(span + pad, road - h * .004),
      _ice,
      h * .0011,
      alpha: .7,
    );
    // Street lights on the barrier, bent over the lanes.
    final pole = Paint()
      ..color = const Color(0xff3a3480)
      ..strokeWidth = math.max(.7, h * .0014)
      ..style = PaintingStyle.stroke;
    for (var x = h * .1; x < span; x += h * .2) {
      c.drawPath(
        Path()
          ..moveTo(x, road - h * .004)
          ..lineTo(x, road - h * .03)
          ..quadraticBezierTo(
            x,
            road - h * .034,
            x + h * .008,
            road - h * .033,
          ),
        pole,
      );
      _bloom(
        c,
        Offset(x + h * .009, road - h * .031),
        h * .018,
        h * .014,
        _ice,
        .45,
      );
      c.drawCircle(
        Offset(x + h * .009, road - h * .032),
        h * .0022,
        Paint()..color = _white,
      );
    }
  }

  static final _canalPics = <double, List<Picture>>{};
  static final _canalLayer = Paint();

  /// Static water art recorded once per viewport height: 0 the surface
  /// with its ripples and reflections, 1 the water taxi (about its origin).
  static List<Picture> _canalPictures(double h) {
    final hit = _canalPics[h];
    if (hit != null) return hit;
    if (_canalPics.length > 3) {
      for (final p in _canalPics.remove(_canalPics.keys.first)!) {
        p.dispose();
      }
    }
    Picture record(void Function(Canvas) draw) {
      final recorder = PictureRecorder();
      draw(Canvas(recorder));
      return recorder.endRecording();
    }

    return _canalPics[h] = [
      record((c) => _canalWater(c, h)),
      record((c) => _canalTaxi(c, h)),
    ];
  }

  /// A light's reflection: short dashes stacked down from the waterline,
  /// wider, fainter and more broken the farther they fall, batched by colour
  /// and strength.
  static void _canalStreak(
    Map<(Color, int), Path> batch,
    double x,
    double h,
    Color color,
    double alpha,
    int n,
    double width,
    int seed,
  ) {
    final wl = _wl * h;
    final thick = math.max(.9, h * .0024);
    for (var j = 0; j < n; j++) {
      final t = j / n;
      final bucket =
          (alpha * (1 - t) * (.6 + .4 * Sketch.hash(seed + j + 9)) * 12)
              .round();
      if (bucket < 1) continue;
      final len =
          h *
          width *
          (.55 + .9 * Sketch.hash(seed + j * 3 + 1)) *
          (1 + t * 1.1);
      final cx = x + (Sketch.hash(seed + j * 7) - .5) * h * .004 * (1 + t * 2);
      final y = wl + h * (.004 + j * .0046 * (1 + t * .5));
      batch
          .putIfAbsent((color, bucket), Path.new)
          .addRect(
            Rect.fromCenter(center: Offset(cx, y), width: len, height: thick),
          );
    }
  }

  /// The canal: dark ripples, then the bank's lights and signs doubled in
  /// broken, wavering colour.
  static void _canalWater(Canvas c, double h) {
    final span = _canalSpan * h, wl = _wl * h;
    final p = Paint();
    final crest = Path(), trough = Path();
    const rows = 18;
    for (var r = 0; r < rows; r++) {
      final t = r / (rows - 1);
      final y = wl + h * (.004 + .1 * math.pow(t, 1.3));
      final n = (26 - 12 * t).round();
      for (var k = 0; k < n; k++) {
        final a = Sketch.hash(r * 211 + k * 17 + 10600);
        final len =
            h * (.02 + .06 * t) * (.5 + Sketch.hash(r * 131 + k * 29 + 10610));
        final rect = Rect.fromLTWH(
          span * a,
          y + h * .002 * (Sketch.hash(r * 53 + k * 11 + 10620) - .5),
          len,
          h * (.0012 + .0014 * t),
        );
        (Sketch.hash(r * 71 + k * 19 + 10630) > .55 ? crest : trough).addRect(
          rect,
        );
      }
    }
    c.drawPath(trough, p..color = Sketch.fade(const Color(0xff05051a), .4));
    c.drawPath(crest, p..color = Sketch.fade(const Color(0xffb690ff), .12));
    final glints = <(Color, int), Path>{};
    // Every sign pours its colour into the water.
    for (final (i, (r, color, _)) in _canalSigns.indexed) {
      final tint = _signColors[color];
      final wide = r.width > r.height;
      for (var k = 0; k < (wide ? 3 : 1); k++) {
        final x = (r.left + r.width * (wide ? (k + .5) / 3 : .5)) * h;
        _canalStreak(
          glints,
          x,
          h,
          tint,
          wide ? .55 : .75,
          wide ? 9 : 13,
          wide ? .012 : .008,
          i * 41 + k * 7 + 10700,
        );
      }
    }
    // Shop fronts in soft warm and cool columns.
    for (var i = 0; i < _canalBlocks.length; i++) {
      final (bx, bw, _) = _canalBlocks[i];
      final n = math.max(1, (bw / .07).round());
      final sw = bw / n;
      for (var k = 0; k < n; k++) {
        final seed = i * 13 + k;
        final pick = (Sketch.hash(seed + 10400) * 6).floor();
        if (pick == 5) continue;
        final glow = _shopGlow[pick];
        _canalStreak(
          glints,
          (bx + (k + .5) * sw) * h,
          h,
          glow,
          .4,
          6,
          sw * .5,
          seed * 17 + 10800,
        );
      }
    }
    // The freeway's street lights.
    for (var x = .1; x < _canalSpan; x += .2) {
      _canalStreak(
        glints,
        (x + .009) * h,
        h,
        _ice,
        .45,
        10,
        .006,
        (x * 100).round() + 10900,
      );
    }
    final paint = Paint();
    glints.forEach(
      (k, path) =>
          c.drawPath(path, paint..color = Sketch.fade(k.$1, k.$2 / 12)),
    );
  }

  /// A water taxi: a low white hull with a tinted canopy, a light strip and
  /// a lamp at the bow, pointing right, its keel at the origin.
  static void _canalTaxi(Canvas c, double h) {
    final s = h * .05;
    Offset p(double x, double y) => Offset(x * s, y * s);
    c.drawOval(
      Rect.fromCenter(center: p(0, .06), width: s * 1.9, height: s * .16),
      Paint()..color = Sketch.fade(_ice, .18),
    );
    c.drawPath(
      Path()
        ..moveTo(p(-.9, -.22).dx, p(-.9, -.22).dy)
        ..lineTo(p(.7, -.22).dx, p(.7, -.22).dy)
        ..quadraticBezierTo(
          p(1.05, -.2).dx,
          p(1.05, -.2).dy,
          p(.95, 0).dx,
          p(.95, 0).dy,
        )
        ..lineTo(p(-.85, 0).dx, p(-.85, 0).dy)
        ..close(),
      Paint()
        ..shader = Gradient.linear(p(0, -.22), p(0, 0), const [
          Color(0xffeef0ff),
          Color(0xff8a8cc8),
        ]),
    );
    c.drawPath(
      Path()
        ..moveTo(p(-.45, -.22).dx, p(-.45, -.22).dy)
        ..quadraticBezierTo(
          p(-.3, -.5).dx,
          p(-.3, -.5).dy,
          p(.2, -.48).dx,
          p(.2, -.48).dy,
        )
        ..quadraticBezierTo(
          p(.45, -.45).dx,
          p(.45, -.45).dy,
          p(.55, -.22).dx,
          p(.55, -.22).dy,
        )
        ..close(),
      Paint()..color = const Color(0xff1d2258),
    );
    c.drawLine(
      p(-.3, -.36),
      p(.4, -.34),
      Paint()
        ..color = Sketch.fade(_cyan, .9)
        ..strokeWidth = math.max(.8, s * .035),
    );
    c.drawLine(
      p(-.85, -.07),
      p(.9, -.07),
      Paint()
        ..color = _magenta
        ..strokeWidth = math.max(.8, s * .03),
    );
    _bloom(c, p(1.0, -.12), s * .5, s * .22, _ice, .5);
    c.drawCircle(p(.94, -.12), s * .04, Paint()..color = _white);
    c.drawCircle(p(-.86, -.12), s * .035, Paint()..color = _red);
  }

  /// Live bank life: traffic streaming both ways on the freeway, the odd
  /// flickering sign, and blinking masts.
  void _canalLive(Canvas c, SceneFrame f) {
    final h = f.h, clock = f.clock, span = _canalSpan;
    final road = _roadY * h;
    final white = Path(), red = Path();
    for (final (n, speed, lane, dir) in const [
      (11, .07, 0, 1.0),
      (9, -.055, 1, -1.0),
    ]) {
      final gap = span / n;
      for (var i = 0; i < n; i++) {
        final x = ((i * gap + clock * speed) % span + span) % span * h;
        final y = road - h * (.0065 - lane * .0026);
        white
          ..moveTo(x + dir * h * .004, y)
          ..lineTo(x + dir * h * .007, y);
        red
          ..moveTo(x - dir * h * .0015, y)
          ..lineTo(x + dir * h * .0015, y);
      }
    }
    final lane = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, h * .0028);
    c.drawPath(white, lane..color = const Color(0xfffff4dc));
    c.drawPath(red, lane..color = _red);
    // Flicker: a failing tube stutters for a moment every few seconds.
    for (final (i, (r, _, flicker)) in _canalSigns.indexed) {
      if (!flicker) continue;
      final on = _flicker(clock, i);
      if (on >= 1) continue;
      c.drawRect(
        Rect.fromLTRB(
          r.left * h,
          r.top * h,
          r.right * h,
          r.bottom * h,
        ).inflate(h * .002),
        Paint()..color = Sketch.fade(const Color(0xff0e0b26), .85 * (1 - on)),
      );
    }
  }

  /// How lit a failing neon tube is at [clock]: steady most of the time,
  /// stuttering for about a third of a second every few seconds. Always lit
  /// at a frozen clock.
  static double _flicker(double clock, int seed) {
    if (clock == 0) return 1;
    final period = 3.5 + 2.5 * Sketch.hash(seed + 11000);
    final t = (clock + Sketch.hash(seed + 11010) * period) % period;
    if (t > .36) return 1;
    return Sketch.hash((clock * 24).floor() * 7 + seed) > .45 ? 1 : .15;
  }

  /// The water, each frame: cached reflections, the gliding taxis and the
  /// shimmer sliding down the brightest columns.
  void _canalOverlay(Canvas c, SceneFrame f, double presence) {
    if (presence <= .01) return;
    final h = f.h, span = _canalSpan * h, clock = f.clock, wl = _wl * h;
    final pics = _canalPictures(h);
    final fading = presence < .995;
    c.save();
    if (fading) {
      c.saveLayer(
        Rect.fromLTRB(-h * .5, h * .7, span + h * .5, h * .96),
        _canalLayer..color = Color.fromRGBO(0, 0, 0, presence),
      );
    }
    if (!f.reducedMotion) c.translate(0, h * .04 * (1 - presence));
    c.drawPicture(pics[0]);
    double slide(double x0, double v) =>
        (((x0 + v * clock) % _canalSpan) + _canalSpan) % _canalSpan;
    for (final (x0, v, y, flip) in const [
      (.5, .06, .806, false),
      (1.7, -.045, .818, true),
    ]) {
      c.save();
      c.translate(
        slide(x0, v) * h,
        h * y + math.sin(clock * 1.3 + x0) * h * .001,
      );
      if (flip) c.scale(-1, 1);
      // The wake: a fan of pale lines trailing the stern.
      final wake = Paint()
        ..color = Sketch.fade(_ice, .22)
        ..strokeWidth = math.max(.7, h * .0012);
      for (var k = 0; k < 3; k++) {
        c.drawLine(
          Offset(-h * .044, h * .001 * k),
          Offset(-h * (.1 + .03 * k), h * (.002 + .003 * k)),
          wake,
        );
      }
      c.drawPicture(pics[1]);
      c.restore();
    }
    // Glints slide down the street lights' reflections.
    final glint = Paint();
    for (var k = 0; k < 12; k++) {
      final x = (.1 + k * .2 + .009) * h;
      final t = (clock * .5 + k * .37) % 1;
      glint.color = Sketch.fade(_white, math.sin(t * math.pi) * .55);
      c.drawRect(
        Rect.fromCenter(
          center: Offset(
            x + math.sin(clock * 2.4 + k) * h * .0015,
            wl + h * (.006 + t * .04),
          ),
          width: h * (.006 + .008 * t),
          height: math.max(.9, h * .002),
        ),
        glint,
      );
    }
    if (fading) c.restore();
    c.restore();
  }

  static final _canalSheen = <Size, Paint>{};

  /// Screen-space light on the canal: the city's magenta glow at the far
  /// bank and the moon's broken path.
  void _canalReflect(Canvas c, SceneFrame f, double presence) {
    final h = f.h, wl = _wl * h;
    var sheen = _canalSheen[f.size];
    if (sheen == null) {
      if (_canalSheen.length > 3) _canalSheen.remove(_canalSheen.keys.first);
      sheen = _canalSheen[f.size] = Paint()
        ..shader = Gradient.linear(Offset(0, wl), Offset(0, wl + h * .08), [
          const Color(0x33ff6ab8),
          const Color(0x00ff6ab8),
        ]);
    }
    if (presence >= .995) {
      c.drawRect(Rect.fromLTRB(0, wl, f.w, wl + h * .08), sheen);
    } else {
      c.drawRect(
        Rect.fromLTRB(0, wl, f.w, wl + h * .08),
        Paint()
          ..shader = Gradient.linear(Offset(0, wl), Offset(0, wl + h * .08), [
            Color.fromRGBO(255, 106, 184, .2 * presence),
            const Color(0x00ff6ab8),
          ]),
      );
    }
    final glint = Paint();
    final x0 = f.w * light.at.dx;
    for (var i = 0; i < 12; i++) {
      final t = i / 11;
      final j = Sketch.hash(i * 7 + 11100);
      final on = .5 + .5 * math.sin(f.clock * 1.6 + i * 2.3);
      final len = h * (.006 + .024 * t) * (.55 + .9 * j);
      final dx =
          (j - .5) * h * (.008 + .026 * t) +
          math.sin(f.clock * .8 + i * 1.7) * h * (.003 + .008 * t);
      glint.color = Sketch.fade(
        const Color(0xffe8e0ff),
        (.5 - .3 * t) * (.35 + .65 * on) * presence,
      );
      c.drawRect(
        Rect.fromCenter(
          center: Offset(x0 + dx, wl + h * (.004 + t * .07)),
          width: len * 2,
          height: math.max(.9, h * (.002 + .001 * t)),
        ),
        glint,
      );
    }
  }
  // ---------------------------------------------------------------------------
  // Near band: sleek rooftops. Glass, ribbon-window, diagrid and louvred facades
  // under LED-trimmed parapets, carrying fans, dishes, holo projectors,
  // masts, vents, a drone pad and a rooftop neon frame, strung together
  // with cable bundles.

  /// Rooftops across one 3.2 h repeat: (width, roof height, facade, roof
  /// kit) in viewport heights. Facades: 0 glass curtain, 1 panel block with
  /// window slits, 2 diagrid, 3 louvred block with a hanging sign.
  /// Kits: 0 fans, 1 dishes, 2 holo projector, 3 mast, 4 vent stacks,
  /// 5 drone pad, 6 neon frame, 7 billboard.
  static const _roofs = [
    (.34, .83, 0, 1),
    (.26, .806, 1, 7),
    (.3, .862, 2, 0),
    (.24, .816, 3, 4),
    (.36, .842, 0, 5),
    (.28, .79, 1, 3),
    (.3, .872, 2, 6),
    (.26, .824, 3, 2),
    (.32, .81, 0, 7),
    (.24, .856, 1, 4),
    (.3, .836, 2, 3),
  ];

  static const _roofTrim = [_cyan, _magenta, _lime, _violet, _pink, _ice];

  /// Each roof's rectangle in period pixels, running below the screen.
  static Rect _roofRect(int i, double h) {
    var x = 0.0;
    for (var k = 0; k < i; k++) {
      x += _roofs[k].$1;
    }
    final (w, roof, _, _) = _roofs[i];
    return Rect.fromLTRB(x * h, roof * h, (x + w) * h, h * 1.02);
  }

  /// Whether roof [i] carries a stair bulkhead, and where across it.
  static double? _roofBulkhead(int i) {
    final (_, _, _, kit) = _roofs[i];
    return switch (kit) {
      0 => .86,
      2 => .16,
      4 => .88,
      5 => .12,
      _ => null,
    };
  }

  /// Setback tiers where part of a roof rises another storey or two:
  /// (roof, from, to as fractions across it, rise in viewport heights).
  static const _roofTiers = [
    (0, .03, .22, .036),
    (4, .68, .97, .05),
    (10, .56, .93, .066),
  ];

  static void _roofRow(Canvas c, double h) {
    for (var i = 0; i < _roofs.length; i++) {
      _roofFacade(c, i, _roofRect(i, h), h);
    }
    for (final (i, from, to, rise) in _roofTiers) {
      _roofTier(c, i, _roofRect(i, h), h, from, to, rise);
    }
    for (var i = 0; i < _roofs.length; i++) {
      final r = _roofRect(i, h);
      final at = _roofBulkhead(i);
      if (at != null) _roofStair(c, r, h, at, i);
      _roofKit(c, i, r, h);
    }
    // Cable bundles hang between neighbouring parapets.
    final cable = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xff09081c);
    for (var i = 0; i < _roofs.length; i++) {
      final a = _roofRect(i, h);
      final next = (i + 1) % _roofs.length;
      final b = _roofRect(next, h).shift(Offset(next == 0 ? 3.2 * h : 0, 0));
      if ((a.top - b.top).abs() > h * .04 || Sketch.hash(i + 11600) < .35) {
        continue;
      }
      final from = Offset(a.right - h * .03, a.top - h * .008);
      final to = Offset(b.left + h * .03, b.top - h * .008);
      for (var k = 0; k < 3; k++) {
        c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy + k * h * .002)
            ..quadraticBezierTo(
              (from.dx + to.dx) / 2,
              math.max(from.dy, to.dy) + h * (.022 + .008 * k),
              to.dx,
              to.dy + k * h * .002,
            ),
          cable..strokeWidth = math.max(.7, h * (.0018 - k * .0003)),
        );
      }
    }
  }

  /// A facade from the roof down: dark, glassy and restrained, washed at
  /// the top by its parapet's LED strip.
  static void _roofFacade(Canvas c, int i, Rect r, double h) {
    final (_, _, facade, _) = _roofs[i];
    final trim = _roofTrim[i % _roofTrim.length];
    final fill = Paint();
    final base = switch (facade) {
      0 => const Color(0xff10123a),
      1 => const Color(0xff161232),
      2 => const Color(0xff141238),
      _ => const Color(0xff12102c),
    };
    c.drawRect(
      r,
      fill
        ..shader = Gradient.linear(
          r.topLeft,
          Offset(r.left, h * .98),
          [
            Sketch.mix(base, const Color(0xff32286c), .45),
            base,
            Sketch.mix(base, _ink, .55),
          ],
          const [0, .35, 1],
        ),
    );
    fill.shader = null;
    final lit = <Color, Path>{};
    void pane(Color color, Rect rect) =>
        lit.putIfAbsent(color, Path.new).addRect(rect);
    switch (facade) {
      case 0:
        // Glass curtain wall: fine mullions, the city reflected in a
        // slanting sheen, vertical LED fins and a few lit offices, each a
        // run of panes in one tone.
        final mullion = Paint()
          ..color = const Color(0x1eb4c0ff)
          ..strokeWidth = math.max(.6, h * .001);
        final pitch = h * .016;
        for (var x = r.left + pitch; x < r.right; x += pitch) {
          c.drawLine(Offset(x, r.top + h * .008), Offset(x, r.bottom), mullion);
        }
        final cols = ((r.width - pitch) / pitch).floor();
        var row = 0;
        for (var y = r.top + h * .02; y < h; y += h * .02, row++) {
          c.drawLine(Offset(r.left, y), Offset(r.right, y), mullion);
          final n = Sketch.hash(i * 331 + row * 29 + 11200);
          if (n > .55) continue;
          final run = 2 + (Sketch.hash(i * 17 + row * 5 + 11210) * 4).floor();
          final from = (Sketch.hash(i * 13 + row * 3 + 11220) * (cols - run))
              .floor();
          final tone = n < .25
              ? const Color(0x8cffc88a)
              : (n < .42 ? const Color(0x80bcd6ff) : const Color(0x80ff9ad8));
          for (var k = from; k < from + run && k < cols; k++) {
            pane(
              tone,
              Rect.fromLTWH(
                r.left + pitch * (k + 1) + h * .0012,
                y + h * .002,
                pitch - h * .0024,
                h * .016,
              ),
            );
          }
        }
        c.save();
        c.clipRect(r);
        c.drawPath(
          Sketch.poly([
            r.left + r.width * .3, r.top, r.left + r.width * .55, r.top, //
            r.left + r.width * .25, h, r.left, h,
          ]),
          fill..color = const Color(0x12d8d0ff),
        );
        c.restore();
        for (var k = 3; k < cols; k += 4) {
          final x = r.left + pitch * k;
          c.drawLine(
            Offset(x, r.top + h * .008),
            Offset(x, h),
            Paint()
              ..color = Sketch.fade(trim, .32)
              ..strokeWidth = math.max(.8, h * .0016),
          );
        }
      case 1:
        // Ribbon windows: long glass strips, each floor lit in one tone.
        var row = 0;
        for (var y = r.top + h * .016; y < h; y += h * .022, row++) {
          final strip = Rect.fromLTRB(
            r.left + h * .01,
            y,
            r.right - h * .01,
            y + h * .008,
          );
          c.drawRect(strip, fill..color = const Color(0xff0a0920));
          final n = Sketch.hash(i * 89 + row * 7 + 11310);
          if (n > .6) continue;
          final tone = n < .25
              ? const Color(0x99ffc27a)
              : (n < .45 ? const Color(0x88bcd6ff) : const Color(0x88ff9ad8));
          var x = strip.left;
          var seg = 0;
          while (x < strip.right) {
            final len =
                h * (.03 + .06 * Sketch.hash(i * 97 + row * 13 + seg + 11300));
            if (Sketch.hash(i * 61 + row * 5 + seg + 11320) < .7) {
              pane(
                tone,
                Rect.fromLTRB(
                  x,
                  strip.top + h * .0015,
                  math.min(x + len, strip.right),
                  strip.bottom - h * .0015,
                ),
              );
            }
            x += len + h * .003;
            seg++;
          }
        }
        _neon(
          c,
          Path()
            ..moveTo(r.left + h * .004, r.top + h * .012)
            ..lineTo(r.left + h * .004, h),
          trim,
          h * .0013,
          alpha: .75,
        );
      case 2:
        // A diagrid: the structure's diagonals cross the glass in
        // diamonds, a few of them lit, with a light line on every node row.
        final cell = h * .036;
        final lines = Path();
        c.save();
        c.clipRect(r);
        for (var x = r.left - h; x < r.right + h; x += cell) {
          lines
            ..moveTo(x, r.top)
            ..lineTo(x + h, r.top + h * 1.3)
            ..moveTo(x, r.top)
            ..lineTo(x - h, r.top + h * 1.3);
        }
        var row = 0;
        for (var y = r.top + cell * .65; y < h; y += cell * .65, row++) {
          var col = 0;
          for (
            var x = r.left + (row.isOdd ? cell / 2 : 0);
            x < r.right;
            x += cell, col++
          ) {
            final n = Sketch.hash(i * 211 + row * 31 + col * 7 + 11400);
            if (n > .16) continue;
            final color = n < .07
                ? const Color(0x80ffc27a)
                : (n < .11 ? const Color(0x80ff9ad8) : const Color(0x808ff4ff));
            c.drawPath(
              Sketch.poly([
                x, y - cell * .3, x + cell * .38, y, x, y + cell * .3, //
                x - cell * .38, y,
              ]),
              fill..color = color,
            );
          }
        }
        c.drawPath(
          lines,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.9, h * .0022)
            ..color = const Color(0xff2a2660),
        );
        c.drawPath(
          lines,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.6, h * .0008)
            ..color = Sketch.fade(trim, .28),
        );
        c.restore();
      default:
        // Louvres and a tall hanging sign.
        for (var y = r.top + h * .012; y < h; y += h * .007) {
          c.drawRect(
            Rect.fromLTWH(r.left, y, r.width, math.max(.6, h * .0013)),
            fill..color = const Color(0x2aa898ff),
          );
        }
        _sign(
          c,
          Rect.fromLTWH(
            r.left + r.width * .62,
            r.top + h * .016,
            h * .03,
            h * .13,
          ),
          trim,
          i * 7 + 3,
        );
    }
    final paint = Paint();
    lit.forEach((color, path) => c.drawPath(path, paint..color = color));
    // The parapet LED washes the top floors.
    c.drawRect(
      Rect.fromLTRB(r.left, r.top, r.right, r.top + h * .05),
      fill
        ..shader = Gradient.linear(r.topLeft, Offset(r.left, r.top + h * .05), [
          Sketch.fade(trim, .16),
          Sketch.fade(trim, 0),
        ]),
    );
    fill.shader = null;
    // Moonlit right edge, the parapet cap and its LED strip.
    c.drawRect(
      Rect.fromLTRB(r.right - h * .006, r.top, r.right, r.bottom),
      fill..color = Sketch.fade(const Color(0xff6a68c0), .28),
    );
    c.drawRect(
      Rect.fromLTRB(r.left, r.top - h * .006, r.right, r.top + h * .003),
      fill..color = const Color(0xff262360),
    );
    c.drawRect(
      Rect.fromLTRB(r.left, r.top - h * .006, r.right, r.top - h * .0042),
      fill..color = const Color(0xff5c58ac),
    );
    _neon(
      c,
      Path()
        ..moveTo(r.left + h * .004, r.top + h * .0035)
        ..lineTo(r.right - h * .004, r.top + h * .0035),
      trim,
      h * .0016,
    );
  }

  /// A setback tier on roof [i]: glass with a lit office run, a moonlit
  /// edge, its own LED-trimmed parapet and a whip antenna.
  static void _roofTier(
    Canvas c,
    int i,
    Rect roof,
    double h,
    double from,
    double to,
    double rise,
  ) {
    final trim = _roofTrim[(i + 2) % _roofTrim.length];
    final r = Rect.fromLTRB(
      roof.left + roof.width * from,
      roof.top - rise * h,
      roof.left + roof.width * to,
      roof.top,
    );
    c.drawRect(
      r,
      Paint()
        ..shader = Gradient.linear(r.topLeft, r.bottomLeft, const [
          Color(0xff26215a),
          Color(0xff13123a),
        ]),
    );
    final mullion = Paint()
      ..color = const Color(0x1eb4c0ff)
      ..strokeWidth = math.max(.6, h * .001);
    for (var x = r.left + h * .014; x < r.right; x += h * .014) {
      c.drawLine(Offset(x, r.top + h * .006), Offset(x, r.bottom), mullion);
    }
    for (var y = r.top + h * .018; y < r.bottom - h * .004; y += h * .018) {
      final lit = Sketch.hash(i * 37 + (y / h * 1000).round() + 11800);
      if (lit > .6) continue;
      final a = r.left + r.width * (.1 + .4 * lit);
      c.drawRect(
        Rect.fromLTRB(
          a,
          y,
          math.min(a + r.width * .4, r.right - h * .006),
          y + h * .01,
        ),
        Paint()
          ..color = lit < .3
              ? const Color(0x8cffc88a)
              : const Color(0x80bcd6ff),
      );
    }
    c.drawRect(
      Rect.fromLTRB(r.right - h * .006, r.top, r.right, r.bottom),
      Paint()..color = Sketch.fade(const Color(0xff6a68c0), .3),
    );
    c.drawRect(
      Rect.fromLTRB(r.left, r.top - h * .005, r.right, r.top + h * .002),
      Paint()..color = const Color(0xff2a2764),
    );
    _neon(
      c,
      Path()
        ..moveTo(r.left + h * .003, r.top + h * .003)
        ..lineTo(r.right - h * .003, r.top + h * .003),
      trim,
      h * .0014,
    );
    final whip = Offset(r.right - h * .012, r.top - h * .005);
    c.drawLine(
      whip,
      whip - Offset(0, h * .035),
      Paint()
        ..color = const Color(0xff4a46a0)
        ..strokeWidth = math.max(.7, h * .0012),
    );
  }

  /// A stair bulkhead: a box on the roof with a lit door and a lamp.
  static void _roofStair(Canvas c, Rect r, double h, double fx, int i) {
    final x = r.left + r.width * fx;
    final box = Rect.fromLTRB(
      x - h * .03,
      r.top - h * .042,
      x + h * .03,
      r.top,
    );
    c.drawRect(box, Paint()..color = const Color(0xff1c1946));
    c.drawRect(
      Rect.fromLTRB(box.right - h * .008, box.top, box.right, box.bottom),
      Paint()..color = const Color(0xff2e2b6c),
    );
    c.drawRect(
      Rect.fromLTRB(
        box.left - h * .002,
        box.top - h * .004,
        box.right + h * .002,
        box.top,
      ),
      Paint()..color = const Color(0xff4a46a0),
    );
    final door = Rect.fromLTRB(
      x - h * .016,
      box.top + h * .012,
      x - h * .004,
      box.bottom,
    );
    final warm = i.isEven ? const Color(0xffffc27a) : const Color(0xffbcd6ff);
    _bloom(c, door.center, h * .03, h * .025, warm, .25);
    c.drawRect(door, Paint()..color = warm);
    c.drawCircle(
      Offset(door.center.dx, box.top + h * .007),
      h * .0022,
      Paint()..color = _white,
    );
  }

  /// Where a roof's kit stands: a point on the roof, as a fraction across.
  static Offset _kitAt(Rect r, double h, double fx) =>
      Offset(r.left + r.width * fx, r.top - h * .006);

  /// The roof kit: static parts only; [_roofLive] animates fans, holograms,
  /// steam, beacons and signs.
  static void _roofKit(Canvas c, int i, Rect r, double h) {
    final (_, _, _, kit) = _roofs[i];
    final trim = _roofTrim[i % _roofTrim.length];
    final dark = Paint()..color = const Color(0xff1e1b4c);
    final mid = Paint()..color = const Color(0xff2e2a6a);
    final light = Paint()..color = const Color(0xff5a55a8);
    switch (kit) {
      case 0:
        // Fans: housings with round grilles.
        for (final fx in const [.2, .44, .7]) {
          final at = _kitAt(r, h, fx);
          final box = Rect.fromLTRB(
            at.dx - h * .024,
            at.dy - h * .03,
            at.dx + h * .024,
            at.dy,
          );
          c.drawRect(box, mid);
          c.drawRect(
            Rect.fromLTRB(box.left, box.top, box.right, box.top + h * .003),
            light,
          );
          c.drawRect(
            Rect.fromLTRB(box.right - h * .005, box.top, box.right, box.bottom),
            dark,
          );
          c.drawCircle(box.center, h * .011, dark);
          c.drawCircle(
            box.center,
            h * .011,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(.7, h * .0014)
              ..color = light.color,
          );
        }
      case 1:
        // Dishes: two tilted reflectors on masts.
        for (final (fx, s, tilt) in const [(.3, 1.0, -.5), (.66, .7, -.9)]) {
          final at = _kitAt(r, h, fx);
          c.drawRect(
            Rect.fromLTRB(
              at.dx - h * .002,
              at.dy - h * .026 * s,
              at.dx + h * .002,
              at.dy,
            ),
            mid,
          );
          c.save();
          c.translate(at.dx, at.dy - h * .03 * s);
          c.rotate(tilt);
          final dish = Rect.fromCenter(
            center: Offset.zero,
            width: h * .05 * s,
            height: h * .018 * s,
          );
          c.drawOval(dish, Paint()..color = const Color(0xff8a88c8));
          c.drawOval(
            Rect.fromLTRB(
              dish.left,
              dish.top,
              dish.right,
              dish.center.dy + dish.height * .1,
            ),
            Paint()..color = const Color(0xffc6c4f0),
          );
          c.drawLine(
            Offset.zero,
            Offset(0, -h * .022 * s),
            Paint()
              ..color = light.color
              ..strokeWidth = math.max(.7, h * .0012),
          );
          c.restore();
        }
      case 2:
        // A holo projector: a low box with an emitter lens.
        final at = _kitAt(r, h, .5);
        c.drawRect(
          Rect.fromLTRB(
            at.dx - h * .03,
            at.dy - h * .012,
            at.dx + h * .03,
            at.dy,
          ),
          mid,
        );
        c.drawRect(
          Rect.fromLTRB(
            at.dx - h * .03,
            at.dy - h * .012,
            at.dx + h * .03,
            at.dy - h * .009,
          ),
          light,
        );
        c.drawOval(
          Rect.fromCenter(
            center: at - Offset(0, h * .013),
            width: h * .02,
            height: h * .005,
          ),
          Paint()..color = Sketch.mix(trim, _white, .5),
        );
      case 3:
        // A lattice mast with whips and a small dish.
        final at = _kitAt(r, h, .35);
        final top = at.dy - h * .12;
        final steel = Paint()
          ..color = const Color(0xff3c3780)
          ..strokeWidth = math.max(.7, h * .0016);
        c.drawLine(
          Offset(at.dx - h * .008, at.dy),
          Offset(at.dx - h * .002, top),
          steel,
        );
        c.drawLine(
          Offset(at.dx + h * .008, at.dy),
          Offset(at.dx + h * .002, top),
          steel,
        );
        for (var k = 0; k < 6; k++) {
          final y0 = at.dy - h * .12 * k / 6,
              y1 = at.dy - h * .12 * (k + 1) / 6;
          final w0 = h * (.008 - .006 * k / 6),
              w1 = h * (.008 - .006 * (k + 1) / 6);
          c.drawLine(
            Offset(at.dx - w0, y0),
            Offset(at.dx + w1, y1),
            steel..strokeWidth = math.max(.6, h * .001),
          );
        }
        c.drawLine(Offset(at.dx, top), Offset(at.dx, top - h * .03), steel);
        c.drawLine(
          Offset(at.dx + h * .01, at.dy - h * .07),
          Offset(at.dx + h * .01, at.dy - h * .1),
          steel,
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(at.dx - h * .012, at.dy - h * .06),
            width: h * .012,
            height: h * .02,
          ),
          Paint()..color = const Color(0xff8a88c8),
        );
      case 4:
        // Vent stacks.
        for (final (fx, s) in const [(.25, 1.0), (.4, .7), (.72, .85)]) {
          final at = _kitAt(r, h, fx);
          final pipe = Rect.fromLTRB(
            at.dx - h * .007,
            at.dy - h * .04 * s,
            at.dx + h * .007,
            at.dy,
          );
          c.drawRect(pipe, mid);
          c.drawRect(
            Rect.fromLTRB(
              pipe.right - h * .004,
              pipe.top,
              pipe.right,
              pipe.bottom,
            ),
            dark,
          );
          c.drawRect(
            Rect.fromLTRB(
              pipe.left - h * .003,
              pipe.top - h * .004,
              pipe.right + h * .003,
              pipe.top,
            ),
            light,
          );
        }
      case 5:
        // A drone pad: a lit ring on the roof and a parked drone.
        final at = _kitAt(r, h, .45);
        final pad = Rect.fromCenter(
          center: at - Offset(0, h * .003),
          width: h * .1,
          height: h * .014,
        );
        c.drawOval(pad, dark);
        _neon(c, Path()..addOval(pad), _lime, h * .0012, alpha: .8);
        _drone(c, at - Offset(0, h * .014), h * .6, lights: false);
      case 6:
        // A rooftop neon frame: a scaffold holding three big glyphs.
        final at = _kitAt(r, h, .5);
        final frame = _roofFrame(at, h);
        final steel = Paint()
          ..color = const Color(0xff2e2a6a)
          ..strokeWidth = math.max(.8, h * .002);
        for (final x in [frame.left + h * .01, frame.right - h * .01]) {
          c.drawLine(Offset(x, at.dy), Offset(x, frame.top), steel);
        }
        c.drawLine(frame.bottomLeft, frame.bottomRight, steel);
        _roofFrameSign(c, frame, h, 1);
      default:
        // A billboard on stilts; its screen plays in [_roofLive].
        final s = _roofBoard(r, h);
        final steel = Paint()
          ..color = const Color(0xff2a2764)
          ..strokeWidth = math.max(.9, h * .003);
        for (final x in [s.left + h * .025, s.right - h * .025]) {
          c.drawLine(Offset(x, r.top), Offset(x, s.bottom), steel);
        }
        c.drawLine(
          Offset(s.left + h * .025, r.top - h * .004),
          Offset(s.right - h * .025, s.bottom + h * .006),
          steel..strokeWidth = math.max(.7, h * .0015),
        );
        _bloom(c, s.center, s.width * .75, s.height * .9, trim, .3);
        c.drawRect(
          s.inflate(h * .004),
          Paint()..color = const Color(0xff15133a),
        );
        _boardBackdrop(c, s, i % 3);
        _neon(
          c,
          Path()..addRect(s.inflate(h * .002)),
          trim,
          h * .0012,
          alpha: .8,
        );
        // A catwalk with uplights.
        c.drawRect(
          Rect.fromLTRB(
            s.left,
            s.bottom + h * .005,
            s.right,
            s.bottom + h * .008,
          ),
          Paint()..color = const Color(0xff2a2764),
        );
        for (final fx in const [.2, .5, .8]) {
          c.drawCircle(
            Offset(s.left + s.width * fx, s.bottom + h * .004),
            h * .002,
            Paint()..color = _white,
          );
        }
    }
  }

  /// The rooftop neon frame over its kit point.
  static Rect _roofFrame(Offset at, double h) => Rect.fromLTRB(
    at.dx - h * .085,
    at.dy - h * .11,
    at.dx + h * .085,
    at.dy - h * .026,
  );

  /// The still backdrop of what a billboard plays: a violet dusk under a
  /// striped synth sun, deep water for the koi, or the dark of the eye.
  static void _boardBackdrop(Canvas c, Rect s, int kind) {
    switch (kind) {
      case 0:
        c.drawRect(
          s,
          Paint()
            ..shader = Gradient.linear(
              s.topCenter,
              s.bottomCenter,
              const [Color(0xff1a0a3a), Color(0xff5a1260), Color(0xff240a3e)],
              const [0, .62, 1],
            ),
        );
        final sun = _boardSun(s), r = s.height * .36;
        c.save();
        c.clipRect(Rect.fromLTRB(s.left, s.top, s.right, sun.dy));
        c.drawCircle(
          sun,
          r,
          Paint()
            ..shader = Gradient.linear(sun - Offset(0, r), sun, const [
              Color(0xffffe36a),
              Color(0xffff3fb4),
            ]),
        );
        c.restore();
      case 1:
        c.drawRect(
          s,
          Paint()
            ..shader = Gradient.linear(s.topLeft, s.bottomRight, const [
              Color(0xff062a3a),
              Color(0xff0c1a44),
            ]),
        );
      default:
        c.drawRect(s, Paint()..color = const Color(0xff0e0a2a));
    }
  }

  static Offset _boardSun(Rect s) =>
      Offset(s.center.dx, s.top + s.height * .62);

  /// A rooftop billboard's screen.
  static Rect _roofBoard(Rect r, double h) => Rect.fromCenter(
    center: Offset(r.center.dx, r.top - h * .03 - h * .047),
    width: h * .18,
    height: h * .094,
  );

  /// The big glyphs on the rooftop neon frame, dimmed by [on].
  static void _roofFrameSign(Canvas c, Rect frame, double h, double on) {
    final glyphs = Path();
    for (var k = 0; k < 3; k++) {
      _addGlyph(
        glyphs,
        17 + k * 5,
        Offset(frame.left + h * .014 + k * h * .054, frame.top + h * .006),
        h * .042,
      );
    }
    _neon(c, glyphs, _magenta, h * .0028, alpha: on);
  }

  /// A small quadcopter seen side-on, sized by [h] (a viewport height for
  /// the flying drones, less for a parked one); [lights] adds its running
  /// lights and [tilt] banks it into its flight.
  static void _drone(
    Canvas c,
    Offset at,
    double h, {
    bool lights = true,
    double tilt = 0,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    final body = Paint()..color = const Color(0xff2a2864);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: h * .026, height: h * .008),
        Radius.circular(h * .004),
      ),
      body,
    );
    c.drawRect(
      Rect.fromLTRB(-h * .02, -h * .006, h * .02, -h * .0045),
      Paint()..color = const Color(0xff4a47a0),
    );
    for (final x in const [-.02, .02]) {
      c.drawRect(
        Rect.fromCenter(
          center: Offset(x * h, -h * .007),
          width: h * .016,
          height: math.max(.7, h * .0014),
        ),
        Paint()..color = const Color(0xffb8b4f0),
      );
    }
    c.drawCircle(Offset(h * .008, h * .002), h * .0025, Paint()..color = _ice);
    if (lights) {
      c.drawCircle(
        Offset(-h * .02, -h * .004),
        h * .0018,
        Paint()..color = _red,
      );
      c.drawCircle(
        Offset(h * .02, -h * .004),
        h * .0018,
        Paint()..color = const Color(0xff6dff9a),
      );
    }
    c.restore();
  }

  static final _steamPaint = _glowPaint(const Color(0xffb8a8e8));

  /// Rooftop life each frame: spinning fans, holograms, steam, beacons, the
  /// neon frame's stutter and drones crossing the band.
  void _roofLive(Canvas c, SceneFrame f) {
    final h = f.h, clock = f.clock;
    for (var i = 0; i < _roofs.length; i++) {
      final r = _roofRect(i, h);
      final (_, _, _, kit) = _roofs[i];
      final trim = _roofTrim[i % _roofTrim.length];
      switch (kit) {
        case 0:
          final blade = Paint()
            ..color = const Color(0xff6a66b8)
            ..strokeWidth = math.max(.8, h * .0022)
            ..strokeCap = StrokeCap.round;
          for (final (k, fx) in const [.2, .44, .7].indexed) {
            final at = _kitAt(r, h, fx) - Offset(0, h * .015);
            final a = clock * (5 + k) + k;
            for (var b = 0; b < 3; b++) {
              final d =
                  Offset(
                    math.cos(a + b * 2.094),
                    math.sin(a + b * 2.094) * .9,
                  ) *
                  h *
                  .0095;
              c.drawLine(at - d * .15, at + d, blade);
            }
          }
        case 2:
          _roofHologram(c, f, _kitAt(r, h, .5) - Offset(0, h * .014), trim, i);
        case 3:
          final at = _kitAt(r, h, .35) - Offset(0, h * .15);
          if (math.sin(clock * 2.6 + i) > 0) {
            _bloom(c, at, h * .014, h * .014, _red, .6);
            c.drawCircle(at, h * .0022, Paint()..color = _red);
          }
        case 4:
          for (final (k, (fx, s)) in const [
            (.25, 1.0),
            (.4, .7),
            (.72, .85),
          ].indexed) {
            final at = _kitAt(r, h, fx) - Offset(0, h * .04 * s + h * .004);
            for (var p = 0; p < 3; p++) {
              final t = (clock * .35 + p / 3 + k * .21) % 1;
              final rad = h * (.008 + .03 * t);
              _steamPaint.color = Color.fromRGBO(
                0,
                0,
                0,
                .22 * (1 - t) * math.min(1, t * 6 + .2),
              );
              c.save();
              c.translate(
                at.dx + h * .03 * t * t + math.sin(clock + p) * h * .003,
                at.dy - h * .08 * t,
              );
              c.scale(rad, rad * .8);
              c.drawCircle(Offset.zero, 1, _steamPaint);
              c.restore();
            }
          }
        case 5:
          final at = _kitAt(r, h, .45) - Offset(0, h * .003);
          for (var k = 0; k < 6; k++) {
            final a = k / 6 * math.pi * 2 + clock * 2.4;
            final on = ((clock * 2.4 / (math.pi * 2) * 6).floor() % 6) == k;
            final p =
                at + Offset(math.cos(a) * h * .05, math.sin(a) * h * .007);
            c.drawCircle(
              p,
              h * .0016,
              Paint()..color = Sketch.fade(on ? _white : _lime, on ? 1 : .5),
            );
          }
          if (math.sin(clock * 3 + i) > .3) {
            c.drawCircle(
              at - Offset(h * .02, h * .015),
              h * .0016,
              Paint()..color = _red,
            );
          }
        case 6:
          final on = _flicker(clock, i + 40);
          if (on < 1) {
            final frame = _roofFrame(_kitAt(r, h, .5), h);
            c.drawRect(
              frame.inflate(h * .004),
              Paint()
                ..color = Sketch.fade(const Color(0xff120f30), .8 * (1 - on)),
            );
          }
        case 7:
          _roofBillboard(c, f, _roofBoard(r, h), i);
        default:
          break;
      }
    }
    // Drones cruise across the rooftops, bobbing, lights blinking.
    final span = period(Depth.near) * h;
    for (var k = 0; k < 2; k++) {
      final x = ((.4 + k * 1.6) * h + clock * h * (k == 0 ? .09 : -.07)) % span;
      final xx = x < 0 ? x + span : x;
      final y = h * (.74 + .03 * k) + math.sin(clock * 1.7 + k * 2) * h * .008;
      _drone(c, Offset(xx, y), h, tilt: (k == 0 ? .12 : -.12));
      if (math.sin(clock * 5 + k) > 0) {
        _bloom(
          c,
          Offset(xx + (k == 0 ? h * .02 : -h * .02), y - h * .004),
          h * .01,
          h * .01,
          k == 0 ? const Color(0xff6dff9a) : _red,
          .5,
        );
      }
    }
  }

  static final _coneShape = Sketch.poly(const [
    -.004, 0, .004, 0, .04, -.03, -.04, -.03, //
  ]);
  static final _cones = <int, Paint>{};

  /// A projector's cone of light in viewport-height units, fading upward.
  static Paint _cone(Color color) => _cones.putIfAbsent(
    color.toARGB32(),
    () => Paint()
      ..shader = Gradient.linear(Offset.zero, const Offset(0, -.05), [
        Sketch.fade(color, .3),
        Sketch.fade(color, .04),
      ]),
  );

  /// A rooftop hologram: a turning wireframe mark over its projector, a
  /// cone of light, scanlines and a stutter now and then.
  void _roofHologram(Canvas c, SceneFrame f, Offset at, Color color, int seed) {
    final h = f.h, clock = f.clock;
    final glitch = _flicker(clock, seed + 70);
    final alpha = .8 * glitch;
    final center = at - Offset(0, h * .05);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(h);
    c.drawPath(
      _coneShape,
      _cone(color)..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    c.restore();
    _bloom(c, center, h * .05, h * .04, color, .3 * alpha);
    // A turning diamond prism.
    final a = clock * .9 + seed;
    final s = h * .03;
    final pts = [
      for (var k = 0; k < 4; k++)
        center +
            Offset(
              math.cos(a + k * math.pi / 2) * s,
              math.sin(a + k * math.pi / 2) * s * .3,
            ),
    ];
    final top = center - Offset(0, s * 1.1),
        bottom = center + Offset(0, s * .9);
    final wire = Path();
    for (var k = 0; k < 4; k++) {
      wire
        ..moveTo(top.dx, top.dy)
        ..lineTo(pts[k].dx, pts[k].dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..moveTo(pts[k].dx, pts[k].dy)
        ..lineTo(pts[(k + 1) % 4].dx, pts[(k + 1) % 4].dy);
    }
    _neon(c, wire, color, h * .0014, alpha: alpha, bloom: false);
    final scan = Paint()..color = Sketch.fade(color, .12 * alpha);
    for (var y = center.dy - s * 1.2; y < center.dy + s; y += h * .006) {
      c.drawRect(
        Rect.fromLTWH(center.dx - s * 1.1, y, s * 2.2, math.max(.6, h * .001)),
        scan,
      );
    }
  }

  /// What a rooftop billboard plays: 0 a striped synth sun over a scrolling
  /// grid, 1 a koi swimming through glyphs, 2 a turning prism eye. A glitch
  /// tears a slice across it now and then.
  void _roofBillboard(Canvas c, SceneFrame f, Rect s, int seed) {
    final h = f.h, t = f.clock;
    final kind = seed % 3;
    c.save();
    c.clipRect(s);
    switch (kind) {
      case 0:
        final sun = _boardSun(s);
        final r = s.height * .36;
        c.save();
        c.clipRect(Rect.fromLTRB(s.left, s.top, s.right, sun.dy));
        // Stripes slide down through the sun.
        final gap = s.height * .07;
        final bar = Paint()..color = const Color(0xff5a1260);
        for (
          var y = sun.dy - r + (t * s.height * .08) % gap;
          y < sun.dy;
          y += gap
        ) {
          final k = (y - (sun.dy - r)) / r;
          final bottom = y + gap * .12 + gap * .35 * k;
          final dy = sun.dy - (y + bottom) / 2;
          final chord = math.sqrt(math.max(0.0, r * r - dy * dy));
          c.drawRect(
            Rect.fromLTRB(sun.dx - chord, y, sun.dx + chord, bottom),
            bar,
          );
        }
        c.restore();
        // The grid rushing toward the viewer.
        final grid = Paint()
          ..color = Sketch.fade(_cyan, .7)
          ..strokeWidth = math.max(.6, h * .0011);
        for (var k = -6; k <= 6; k++) {
          c.drawLine(
            Offset(s.center.dx + k * s.width * .02, sun.dy),
            Offset(s.center.dx + k * s.width * .16, s.bottom),
            grid,
          );
        }
        for (var k = 0; k < 5; k++) {
          final u = ((k + (t * .8) % 1) / 5);
          final y = sun.dy + (s.bottom - sun.dy) * u * u;
          c.drawLine(Offset(s.left, y), Offset(s.right, y), grid);
        }
      case 1:
        final glyphs = Path();
        for (var k = 0; k < 4; k++) {
          _addGlyph(
            glyphs,
            seed * 3 + k,
            Offset(s.right - s.width * .14, s.top + s.height * (.08 + k * .22)),
            s.height * .12,
          );
        }
        _glyphPen.strokeWidth = math.max(.8, h * .0018);
        c.drawPath(glyphs, _glyphPen..color = Sketch.fade(_ice, .8));
        final swim = (t * .09 + seed * .3) % 1;
        _koi(
          c,
          Offset(s.left + s.width * (-.1 + swim * 1.4), s.center.dy),
          s.width * .42,
          1,
          t * 5,
          1,
          body: const Color(0xffff8a3a),
          spots: _white,
          solid: true,
        );
      default:
        final mid = s.center;
        final pen = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, h * .0018);
        for (var k = 0; k < 4; k++) {
          final grow = ((t * .5 + k / 4) % 1);
          final d = s.height * (.08 + .5 * grow);
          pen.color = Sketch.fade(k.isEven ? _lime : _cyan, (1 - grow) * .9);
          c.drawPath(
            Sketch.poly([0, -d, d * 1.6, 0, 0, d, -d * 1.6, 0], at: mid),
            pen,
          );
        }
        final look = math.sin(t * .9 + seed) * s.width * .08;
        c.drawCircle(
          mid + Offset(look, 0),
          s.height * .12,
          Paint()..color = _lime,
        );
        c.drawCircle(
          mid + Offset(look, 0),
          s.height * .05,
          Paint()..color = _ink,
        );
    }
    // Scanlines and the odd torn slice.
    final scan = Paint()..color = const Color(0x2a000000);
    for (var y = s.top; y < s.bottom; y += math.max(2.0, h * .005)) {
      c.drawRect(
        Rect.fromLTWH(s.left, y, s.width, math.max(.7, h * .0015)),
        scan,
      );
    }
    final tick = (t * 1.3).floor();
    if (t != 0 && Sketch.hash(tick * 5 + seed + 11700) > .85) {
      final y = s.top + s.height * Sketch.hash(tick * 3 + seed + 11710);
      c.drawRect(
        Rect.fromLTWH(s.left, y, s.width, s.height * .1),
        Paint()..color = Sketch.fade(kind == 1 ? _magenta : _cyan, .5),
      );
    }
    c.restore();
  }

  /// Wet roofs catch the neon: short shimmering glints along each roof.
  void _roofOverlay(Canvas c, SceneFrame f, double presence) {
    if (presence <= .01) return;
    final h = f.h, clock = f.clock;
    final paint = Paint();
    // The terrace we fly over: a glass balustrade with a lit handrail.
    final span = period(Depth.near) * h, rail = _nearY * h;
    paint.color = Sketch.fade(const Color(0xffb8c0ff), .05 * presence);
    c.drawRect(Rect.fromLTRB(0, rail - h * .022, span, rail), paint);
    c.drawPoints(
      PointMode.lines,
      [
        for (var x = h * .02; x < span; x += h * .08) ...[
          Offset(x, rail - h * .022),
          Offset(x, rail),
        ],
      ],
      Paint()
        ..color = Sketch.fade(const Color(0xff2a2764), presence)
        ..strokeWidth = math.max(.8, h * .0024),
    );
    paint.color = Sketch.fade(const Color(0xff3a3680), presence);
    c.drawRect(Rect.fromLTRB(0, rail - h * .025, span, rail - h * .021), paint);
    paint.color = Sketch.fade(_ice, .55 * presence);
    c.drawRect(Rect.fromLTRB(0, rail - h * .025, span, rail - h * .024), paint);
    for (var i = 0; i < _roofs.length; i++) {
      final r = _roofRect(i, h);
      final trim = _roofTrim[i % _roofTrim.length];
      for (var k = 0; k < 3; k++) {
        final fx = .15 + .7 * Sketch.hash(i * 7 + k + 11500);
        final on = .5 + .5 * math.sin(clock * (1.2 + k * .4) + i * 1.3 + k);
        paint.color = Sketch.fade(
          k == 0 ? trim : _white,
          (.12 + .2 * on) * presence,
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(r.left + r.width * fx, r.top - h * .0015),
            width: h * (.02 + .02 * Sketch.hash(i * 5 + k + 11510)),
            height: math.max(.8, h * .0018),
          ),
          paint,
        );
      }
    }
  }
}

/// The far band's two rows of towers for one viewport.
class _FarPlan {
  const _FarPlan(this.ghosts, this.row);
  final List<(double, double, double, int, int)> ghosts, row;
}

/// The mid band's layout for one viewport: towers (x in pixels, half width
/// and roof in viewport heights, style, seed), screens on their faces and
/// sky bridges (left, right in pixels, height in viewport heights).
class _MidPlan {
  _MidPlan(this.towers, this.screens, this.bridges);
  final List<(double, double, double, int, int)> towers;
  final List<(Rect, int)> screens;
  final List<(double, double, double)> bridges;

  factory _MidPlan.build(double w, double h) {
    final towers = <(double, double, double, int, int)>[];
    final spire = CyberpunkScene._spireX(w, h);
    final x1 = w + h * .58;
    var x = -h * .22;
    for (var i = 0; x < x1; i++) {
      final hw = .026 + .026 * Sketch.hash(i + 9620);
      final cx = x + hw * h;
      if ((cx - spire).abs() < h * (.1 + hw)) {
        x = spire + h * .1;
        continue;
      }
      final tall = Sketch.hash(i + 9630) < .2;
      final top = tall
          ? .27 + .07 * Sketch.hash(i + 9640)
          : .38 + .2 * Sketch.hash(i + 9640);
      towers.add((cx, hw, top, (Sketch.hash(i + 9650) * 6).floor(), 20 + i));
      x = cx + hw * h + h * (.012 + .05 * Sketch.hash(i + 9660));
    }
    final screens = <(Rect, int)>[];
    final bridges = <(double, double, double)>[];
    var kind = 0;
    for (var i = 0; i < towers.length; i++) {
      final (tx, hw, top, style, seed) = towers[i];
      if (hw > .034 && screens.length < 5 && Sketch.hash(seed + 9670) < .75) {
        final sw = hw * h * 1.7;
        final sh = h * (kind % 3 == 1 ? .07 : .12);
        final sy = top * h + hw * h * 1.6 + h * .014;
        screens.add((Rect.fromLTWH(tx - sw / 2, sy, sw, sh), kind % 3));
        kind++;
      }
      if (i + 1 < towers.length) {
        final (nx, nhw, ntop, _, _) = towers[i + 1];
        final a = tx + hw * h, b = nx - nhw * h;
        final gap = b - a;
        if (gap > h * .01 && gap < h * .09 && Sketch.hash(seed + 9680) < .6) {
          final y = math.max(top, ntop) + .04 + .1 * Sketch.hash(seed + 9690);
          if (y < .66) bridges.add((a, b, y));
        }
      }
    }
    return _MidPlan(towers, screens, bridges);
  }
}
