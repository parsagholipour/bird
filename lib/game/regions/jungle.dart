import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// A rainforest on a misty morning: a sheer tepui with a ribbon waterfall on
/// the horizon, emergent kapok trees over a rolling canopy, a rope bridge
/// between giants and broad leaves, ferns and heliconia in the foreground.
/// Sun rays slant through the haze; leaves drift and fireflies glow low.
class JungleScene extends RegionScene {
  const JungleScene();

  @override
  WorldRegion get region => WorldRegion.jungle;

  @override
  double get horizon => .6;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.2, .17),
    radius: .052,
    disc: Color(0xfffffbe8),
    glow: Color(0xfffff1b8),
    halo: .6,
    strength: .52,
  );

  static final _weather = Weather(
    // A few petals from the flowering trees; fireflies are painted in
    // [reflect], where they can glow properly.
    Weather.of([(Mote.leaf, 8), (Mote.petal, 3)]),
  );
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffd3e6c8);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffb3d2bf),
      Color(0xffa6c9b3),
      Color(0xffd9ebd4),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xff74b389),
      Color(0xff579c72),
      Color(0xffa5d69c),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xff43905f),
      Color(0xff2f744d),
      Color(0xff7fc47f),
    ),
    Depth.near => const Ground(
      Color(0xff2a6b47),
      Color(0xff1d5036),
      Color(0xff4f9a5e),
      rimWidth: .006,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far =>
      .64 -
          .045 * Sketch.humps(x / 1.3 + .2) -
          .02 * Sketch.humps(x / .55) -
          .006 * Sketch.humps(x / .13 + .4) -
          .004 * Sketch.humps(x / .07 + .2),
    Depth.mid =>
      .7 -
          .03 * Sketch.humps(x / .23) -
          .025 * Sketch.humps(x / .61 + .3) -
          .011 * Sketch.humps(x / .37 + .6),
    // Every period below divides 3, so the low band repeats seamlessly.
    Depth.low =>
      .8 -
          .035 * Sketch.humps(x / .3) -
          .03 * Sketch.humps(x / .75 + .5) -
          .012 * Sketch.humps(x / .5 + .2),
    Depth.near =>
      // Rounded valleys: the old cusps showed as sharp V notches.
      .92 -
          .04 * math.pow(math.sin(math.pi * x / .425), 2) -
          .025 * Sketch.humps(x / 1.7 + .3),
  };

  @override
  double period(Depth d) => d == Depth.low ? 3.0 : 3.4;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .42,
    Depth.mid => .34,
    Depth.low => .5,
    Depth.near => .3,
  };

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _tepui(c, w * .68, h, w);
      case Depth.mid:
        // Record the near band's cached forest floor now, a band early, so
        // its first frame does not pay for it on top of the plants.
        _understoryGround(size);
        for (final (fx, s, bloom, dome) in const [
          (.12, 1.0, 0, false),
          (.3, .75, 1, false),
          (.42, .85, 0, true),
          (.62, .7, 2, false),
          (.78, .62, 0, true),
          (.94, 1.1, 0, false),
          (1.12, .8, 1, false),
          (1.24, .9, 0, true),
        ]) {
          // Each trunk starts just under the canopy line, hidden by the crowns.
          final at = Offset(w * fx, ridge(d, w * fx / h, 0) * h + h * .012);
          _kapok(c, at, h * .2 * s, bloom: bloom, dome: dome);
        }
        // Palms and cecropias poke through the canopy between the emergents.
        for (final (fx, s, kind) in const [(.21, .5, 0), (.53, .58, 1), (.9, .5, 0)]) {
          final at = Offset(w * fx, ridge(d, w * fx / h, 0) * h + h * .012);
          _canopyEmergent(c, at, h * .2 * s, kind, haze: .34);
        }
      case Depth.low:
        _understoryFrame(size); // likewise the swaying frame of leaves
        // Palms and cecropias stand in the gaps between the two giants.
        for (final (fx, s, kind) in const [(.2, .85, 0), (1.92, 1.0, 1), (2.3, .8, 0), (2.72, 1.05, 1)]) {
          final at = Offset(h * fx, ridge(d, fx, 0) * h + h * .015);
          _canopyEmergent(c, at, h * .2 * s, kind, haze: .26);
        }
        _giant(c, Offset(h * .6, h * .82), h * .36);
        _giant(c, Offset(h * 1.5, h * .82), h * .3, side: -1);
        _bridge(c, Offset(h * .6, h * .56), Offset(h * 1.5, h * .6), h);
      case Depth.near:
        _understoryFeatures(c, size);
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d == Depth.low) _bridgeLive(c, f, copy);
    if (d != Depth.far) return;
    _tepuiLive(c, f);
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    switch (d) {
      case Depth.far:
        // Hazed crowns dress the far ridge, under the tepui's foot mist.
        _canopyCrowns(c, d, f, presence);
        _tepuiOverlay(c, f, presence);
      case Depth.mid || Depth.low:
        // Broccoli crowns: leaf lobes with sunlit tops line every canopy hump.
        _canopyCrowns(c, d, f, presence);
        if (d == Depth.mid) _airMidMist(c, f, presence);
      case Depth.near:
        _understoryOverlay(c, f, presence);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final sun = _airSunAt(f);
    _airSun(c, f, sun, presence);
    _airClouds(c, f, sun, presence);
    _airBeams(c, f, sun, presence, canopy: false);
    _airBirds(c, f, presence);
  }

  /// Screen-space air in front of the low canopy and behind the undergrowth:
  /// mist, light shafts through it, dust in the beams and small creatures.
  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    final sun = _airSunAt(f);
    // The sunward side of the canopy sits in a warmer haze.
    _airBlob(
      c,
      _airLitPuff,
      Offset(sun.dx, f.h * .78),
      f.h * 1.15,
      f.h * .5,
      .14 * presence,
    );
    _airLowMist(c, f, presence);
    _airBeams(c, f, sun, presence, canopy: true);
    // Small creatures thin out faster than the mist so none drift over the
    // next region's scenery in a crossing.
    final small = presence * presence * presence;
    _airMotes(c, f, small);
    _airDragonflies(c, f, small);
    _airMorphos(c, f, small);
    _airFireflies(c, f, small);
  }

  // ---------------------------------------------------------------------------
  // Air: the sun's bloom, cloud veils, god rays, mist banks and everything
  // that flies. All of it is a pure function of the replay clock.

  static const _airLit = Color(0xfffff3d0), _airCool = Color(0xff9dc8b3);

  /// A soft round puff in unit space; scale the canvas to make a bank of it.
  static Shader _airPuff(Color color) => Gradient.radial(
    Offset.zero,
    1,
    [
      Sketch.fade(color, 1),
      Sketch.fade(color, .62),
      Sketch.fade(color, .2),
      Sketch.fade(color, 0),
    ],
    const [0, .38, .74, 1],
  );
  static final _airHazePuff = _airPuff(_haze);
  static final _airLitPuff = _airPuff(_airLit);
  static final _airCoolPuff = _airPuff(_airCool);
  static final _airGlowPuff = _airPuff(const Color(0xffd9f56a));
  static final _airSunCore = Gradient.radial(
    Offset.zero,
    1,
    const [
      Color(0xfffffdf0),
      Color(0xf2fffdf0),
      Color(0x6bfff4c4),
      Color(0x1ffff0b0),
      Color(0x00fff0b0),
    ],
    const [0, .22, .45, .75, 1],
  );
  static final _airBloom = Gradient.radial(
    Offset.zero,
    1,
    const [
      Color(0x8cfff0b0),
      Color(0x4dfff0b0),
      Color(0x1afff0b0),
      Color(0x00fff0b0),
    ],
    const [0, .3, .65, 1],
  );

  static final _airShaded = Paint();
  static final _airFlat = Paint();
  static final _airInk = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static Paint _airFill(Color color, double alpha) =>
      _airFlat..color = Sketch.fade(color, alpha);

  static Paint _airStroke(Color color, double alpha, double width) => _airInk
    ..color = Sketch.fade(color, alpha)
    ..strokeWidth = width;

  /// A soft elliptical puff of [puff] centred on [at]; [alpha] rides on the
  /// paint so the cached shader is reused every frame.
  static void _airBlob(
    Canvas c,
    Shader puff,
    Offset at,
    double rx,
    double ry,
    double alpha,
  ) {
    if (alpha <= .004) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(rx, ry);
    c.drawCircle(
      Offset.zero,
      1,
      _airShaded
        ..shader = puff
        ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)),
    );
    c.restore();
  }

  /// A bank of mist: cool shaded underside, haze body, warm sunlit crest.
  static void _airBank(
    Canvas c,
    double x,
    double y,
    double rx,
    double ry,
    double alpha,
  ) {
    _airBlob(
      c,
      _airCoolPuff,
      Offset(x + rx * .05, y + ry * .32),
      rx * .96,
      ry * .9,
      alpha * .5,
    );
    _airBlob(c, _airHazePuff, Offset(x, y), rx, ry, alpha);
    _airBlob(
      c,
      _airLitPuff,
      Offset(x - rx * .16, y - ry * .3),
      rx * .62,
      ry * .58,
      alpha * .55,
    );
  }

  /// The sun follows the light through a crossing, so its bloom and rays do.
  Offset _airSunAt(SceneFrame f) {
    final blend = f.blend;
    final at = blend.crossing
        ? SkyLight.lerp(
            RegionScene.of(blend.from).light,
            RegionScene.of(blend.to).light,
            blend.stage(0, 1),
          ).at
        : light.at;
    return Offset(at.dx * f.w, at.dy * f.h);
  }

  /// Sun seen through mist: a luminous core that swallows the hard disc's
  /// edge, inside a wide warm bloom.
  static void _airSun(Canvas c, SceneFrame f, Offset sun, double presence) {
    final h = f.h;
    final breath = 1 + .025 * math.sin(f.clock * .6);
    _airBlob(
      c,
      _airBloom,
      sun,
      h * .62 * breath,
      h * .5 * breath,
      presence,
    );
    _airBlob(c, _airSunCore, sun, h * .2, h * .2, presence);
  }

  // (x as a fraction of w, y, half-width, half-height, drift, alpha), sizes in h
  static const _airCloudSpec = [
    (.10, .075, .36, .022, .0060, .34),
    (.62, .055, .44, .018, .0040, .26),
    (.86, .205, .32, .026, .0085, .30),
    (.40, .262, .50, .027, .0050, .30),
    (.03, .200, .30, .019, .0070, .26),
    (.48, .150, .28, .015, .0090, .20),
  ];

  /// Thin streaks of high haze, warmer near the sun, drifting slowly.
  static void _airClouds(
    Canvas c,
    SceneFrame f,
    Offset sun,
    double presence,
  ) {
    final w = f.w, h = f.h;
    final span = w + h * 2;
    for (final (fx, fy, rx, ry, speed, alpha) in _airCloudSpec) {
      final x = (w * fx + h + f.clock * h * speed) % span - h;
      final y = h * fy;
      final warm = (1 - (Offset(x, y) - sun).distance / (h * .9)).clamp(
        0.0,
        1.0,
      );
      final a = alpha * presence;
      _airBlob(
        c,
        _airCoolPuff,
        Offset(x + rx * h * .05, y + ry * h * .55),
        rx * h * .95,
        ry * h * .8,
        a * .5,
      );
      _airBlob(c, _airHazePuff, Offset(x, y), rx * h, ry * h, a);
      _airBlob(
        c,
        _airHazePuff,
        Offset(x + rx * h * .5, y - ry * h * .4),
        rx * h * .55,
        ry * h * .7,
        a * .8,
      );
      _airBlob(
        c,
        _airLitPuff,
        Offset(x - rx * h * .25, y - ry * h * .45),
        rx * h * .6,
        ry * h * .6,
        a * (.3 + .7 * warm),
      );
    }
  }

  // (angle below +x, half-spread, strength, reaches the canopy mist)
  static const _airShafts = [
    (.34, .030, .50, false),
    (.50, .050, .85, true),
    (.66, .026, .70, true),
    (.80, .060, 1.0, true),
    (.97, .030, .80, true),
    (1.12, .050, .85, true),
    (1.29, .028, .60, true),
    (1.50, .045, .45, false),
  ];

  static final _airKits =
      <double, ({List<Path> tri, List<Shader> sky, List<Shader> canopy})>{};

  /// Cached per viewport height: three nested beam triangles (soft edges) and
  /// one shader per beam whose brightness breaks up along its length, like
  /// light finding holes in the canopy.
  static ({List<Path> tri, List<Shader> sky, List<Shader> canopy}) _airKit(
    double h,
  ) {
    final cached = _airKits[h];
    if (cached != null) return cached;
    if (_airKits.length > 4) _airKits.clear();
    final len = h * 2.1;
    const beam = Color(0xfffff2c8);
    final tri = [
      for (final k in const [1.0, .62, .3])
        Path()
          ..moveTo(0, 0)
          ..lineTo(len, -k)
          ..lineTo(len, k)
          ..close(),
    ];
    final sky = <Shader>[], canopy = <Shader>[];
    for (var k = 0; k < _airShafts.length; k++) {
      final angle = _airShafts[k].$1;
      double j(int i) => Sketch.hash(k * 17 + i + 1500);
      sky.add(
        Gradient.linear(
          Offset.zero,
          Offset(len, 0),
          [
            for (final a in [
              0.0,
              0.0,
              .7 + .3 * j(0),
              .5 + .4 * j(1),
              .85,
              .45 + .4 * j(2),
              .3 + .3 * j(3),
              0.0,
            ])
              Sketch.fade(beam, a),
          ],
          const [0, .05, .13, .3, .46, .64, .82, 1],
        ),
      );
      // Light shows where it meets mist: from mid-height down to the canopy.
      double at(double y) => ((y - .17) * h / math.sin(angle)) / len;
      final body = .6 + .4 * j(4);
      canopy.add(
        Gradient.linear(
          Offset.zero,
          Offset(len, 0),
          [
            Sketch.fade(beam, 0),
            Sketch.fade(beam, 0),
            Sketch.fade(beam, body),
            Sketch.fade(beam, body * (.7 + .3 * j(5))),
            Sketch.fade(beam, 0),
            Sketch.fade(beam, 0),
          ],
          [0, at(.5), at(.64), at(.82), at(.97), 1],
        ),
      );
    }
    return _airKits[h] = (tri: tri, sky: sky, canopy: canopy);
  }

  /// God rays fanning from the sun; [canopy] draws the lower half of them in
  /// front of the trees, where the mist catches the light.
  static void _airBeams(
    Canvas c,
    SceneFrame f,
    Offset sun,
    double presence, {
    required bool canopy,
  }) {
    final kit = _airKit(f.h);
    final len = f.h * 2.1;
    c.save();
    // Above the mid canopy for the sky pass, in the mist for the canopy pass.
    c.clipRect(
      Rect.fromLTRB(0, canopy ? f.h * .48 : 0, f.w, f.h * (canopy ? .96 : .7)),
    );
    c.translate(sun.dx, sun.dy);
    for (var k = 0; k < _airShafts.length; k++) {
      final (angle, spread, strength, reaches) = _airShafts[k];
      if (canopy && !reaches) continue;
      final pulse = .74 + .26 * math.sin(f.clock * .45 + k * 1.9);
      final a = angle + .014 * math.sin(f.clock * .21 + k * 2.3);
      final alpha =
          (canopy ? .3 : .4) * strength * pulse * presence / kit.tri.length;
      c.save();
      c.rotate(a);
      c.scale(1, math.tan(spread) * len);
      final paint = _airShaded
        ..shader = (canopy ? kit.canopy : kit.sky)[k]
        ..color = Color.fromRGBO(255, 255, 255, alpha);
      for (final tri in kit.tri) {
        c.drawPath(tri, paint);
      }
      c.restore();
    }
    c.restore();
    if (!canopy) return;
    // Where a beam lands on the canopy it leaves a pool of warm light.
    final y = f.h * .8;
    for (var k = 0; k < _airShafts.length; k++) {
      final (angle, spread, strength, reaches) = _airShafts[k];
      if (!reaches) continue;
      final pulse = .74 + .26 * math.sin(f.clock * .45 + k * 1.9);
      final a = angle + .014 * math.sin(f.clock * .21 + k * 2.3);
      final reach = (y - sun.dy) / math.sin(a);
      _airBlob(
        c,
        _airLitPuff,
        Offset(sun.dx + math.cos(a) * reach, y),
        reach * math.tan(spread) / math.sin(a) * .9,
        f.h * .02,
        .3 * strength * pulse * presence,
      );
    }
  }

  // (x as a fraction of w, y, half-width, half-height, drift, alpha), sizes in h
  static const _airMidBanks = [
    (.10, .705, .46, .040, .010, .46),
    (.46, .732, .56, .050, -.008, .50),
    (.82, .700, .40, .035, .012, .40),
    (.30, .752, .62, .045, .006, .44),
    (.60, .715, .30, .014, .022, .55),
    (.05, .745, .34, .012, -.018, .50),
  ];

  /// Mist pooled in the hollows of the mid canopy, behind the low band, and
  /// slow plumes of it lifting off the crowns as the sun warms them.
  void _airMidMist(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    for (var i = 0; i < 5; i++) {
      final r = Sketch.hash(i + 1800);
      final age = (f.clock / (11 + 5 * r) + Sketch.hash(i + 1810)) % 1;
      final x = h * (.15 + .32 * i + .2 * r) + math.sin(age * 4 + i) * h * .012;
      final y = ridge(Depth.mid, x / h, 0) * h + h * .012 - age * h * .13;
      final fade = math.sin(math.pi * age);
      final a = fade * fade * .4 * presence;
      _airBlob(c, _airHazePuff, Offset(x, y), h * (.05 + .05 * age), h * (.06 + .05 * age), a);
      _airBlob(
        c,
        _airLitPuff,
        Offset(x - h * .012, y - h * .015),
        h * (.03 + .03 * age),
        h * (.04 + .04 * age),
        a * .6,
      );
    }
    final span = w + h * 2.4;
    for (var i = 0; i < _airMidBanks.length; i++) {
      final (fx, y, rx, ry, drift, alpha) = _airMidBanks[i];
      final x = (w * fx + h * 1.2 + f.clock * h * drift) % span - h * 1.2;
      final breath = .86 + .14 * math.sin(f.clock * .35 + i * 2.1);
      _airBank(c, x, h * y, h * rx, h * ry, alpha * breath * presence);
    }
  }

  // (x as a fraction of w, y, half-width, half-height, parallax, drift, alpha)
  static const _airLowBanks = [
    (.05, .815, .55, .050, .05, .004, .50),
    (.34, .845, .70, .060, .08, .006, .55),
    (.66, .805, .50, .045, .06, -.005, .45),
    (.90, .855, .60, .055, .09, .005, .50),
    (.50, .820, .34, .016, .07, .024, .60),
    (.15, .865, .30, .014, .09, -.020, .55),
    (.80, .790, .30, .013, .06, .020, .50),
  ];

  /// Mist lying on the low canopy, between it and the undergrowth.
  static void _airLowMist(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final travel = f.reducedMotion ? 0.0 : f.distance * h;
    final span = w + h * 2.4;
    for (var i = 0; i < _airLowBanks.length; i++) {
      final (fx, y, rx, ry, par, drift, alpha) = _airLowBanks[i];
      final x =
          (w * fx + h * 1.2 - travel * par + f.clock * h * drift) % span -
          h * 1.2;
      final breath = .86 + .14 * math.sin(f.clock * .3 + i * 1.7);
      _airBank(c, x, h * y, h * rx, h * ry, alpha * breath * presence);
    }
  }

  /// Dust turning over in the beams: a few faint motes that twinkle.
  static void _airMotes(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final travel = f.reducedMotion ? 0.0 : f.distance * h;
    final span = w + h * .4;
    for (var i = 0; i < 10; i++) {
      final r1 = Sketch.hash(i * 3 + 1600), r2 = Sketch.hash(i * 3 + 1601);
      final x =
          (r1 * span - travel * .1 - t * h * .008) % span -
          h * .2 +
          math.sin(t * .5 + i) * h * .02;
      final y = h * (.42 + .44 * r2) + math.sin(t * .7 + i * 1.9) * h * .02;
      final twinkle = .5 + .5 * math.sin(t * 1.3 + i * 2.7);
      c.drawCircle(
        Offset(x, y),
        math.max(.7, h * .0026),
        _airFill(const Color(0xfffff6d8), .6 * twinkle * presence),
      );
    }
  }

  /// Small green-gold fireflies drifting over the canopy: a soft halo and a
  /// pale core that pulse out of step.
  static void _airFireflies(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final travel = f.reducedMotion ? 0.0 : f.distance * h;
    final span = w + h * .4;
    for (var i = 0; i < 9; i++) {
      final r1 = Sketch.hash(i * 3 + 1700), r2 = Sketch.hash(i * 3 + 1701);
      final x =
          (r1 * span - travel * .14) % span -
          h * .2 +
          math.sin(t * .7 + i * 1.3) * h * .05;
      final y = h * (.73 + .15 * r2) + math.sin(t * .9 + i * 2.1) * h * .025;
      final s = math.sin(t * 2 + i * 1.7);
      final pulse = .2 + .8 * (.5 + .5 * s) * (.5 + .5 * s);
      _airBlob(
        c,
        _airGlowPuff,
        Offset(x, y),
        h * .03,
        h * .03,
        .6 * pulse * presence,
      );
      c.drawCircle(
        Offset(x, y),
        math.max(.8, h * .0036),
        _airFill(const Color(0xfffdffd6), (.45 + .55 * pulse) * presence),
      );
    }
  }

  // ---- creatures ------------------------------------------------------------

  /// Where a flier is along a lane that wraps just off screen: [from] is its
  /// x at clock 0 as a fraction of w, [speed] in viewport heights per second.
  static double _airLane(SceneFrame f, double from, double speed) {
    final span = f.w + f.h;
    return (f.w * from + f.h * .5 + f.clock * f.h * speed) % span - f.h * .5;
  }

  /// 0 while flapping, 1 while gliding: a short glide every few seconds.
  static double _airGlide(double t, double seed) {
    final u = (t * .17 + seed) % 1;
    return RegionBlend.smooth((u - .74) / .05) *
        (1 - RegionBlend.smooth((u - .94) / .05));
  }

  static void _airBirds(Canvas c, SceneFrame f, double presence) {
    final h = f.h, t = f.clock;
    // Parrots first, farthest: a loose flock of tiny green silhouettes.
    final fx = _airLane(f, .02, .06);
    final fy = h * .255 + math.sin(t * .3) * h * .012;
    for (final (i, (dx, dy)) in const [
      (0.0, 0.0),
      (-.7, -.4),
      (-.6, .45),
      (-1.4, -.85),
      (-1.3, .8),
      (-2.0, .05),
    ].indexed) {
      _airParrot(
        c,
        Offset(
          fx + dx * h * .03,
          fy + dy * h * .03 + math.sin(t * .8 + i * 1.9) * h * .004,
        ),
        h * .014,
        t * 12 + i * 1.1,
        presence,
      );
    }
    _airToucan(
      c,
      Offset(
        _airLane(f, .3, .09),
        h * .275 + math.sin(t * .9) * h * .012,
      ),
      h * .026,
      t * 10 + .4,
      presence,
      burst: 1 - _airGlide(t, .35),
    );
    _airMacaw(
      c,
      Offset(
        _airLane(f, .74, .07),
        h * .19 + math.sin(t * .6 + 1) * h * .01,
      ),
      h * .027,
      t * 11 + 3.2,
      presence,
      glide: _airGlide(t, .55),
    );
    _airMacaw(
      c,
      Offset(
        _airLane(f, .58, .075),
        h * .135 + math.sin(t * .55) * h * .012,
      ),
      h * .034,
      t * 11.5 + 1.3,
      presence,
      glide: _airGlide(t, .1),
    );
  }

  /// Direction of a wing's span as seen from the side, for a flap angle in
  /// -1 (down) .. 1 (up): up-and-back, foreshortened at mid-stroke, then
  /// down-and-back. Back is negative x; y grows downward.
  static Offset _airSpan(double beat) => Offset(
    -(.5 - .2 * beat * beat),
    .3 - .94 * beat - .31 * beat * beat,
  );

  /// A wing seen from the side, hinged at the origin of the canvas. The arm
  /// follows [b0] and the outer hand [b1] (which lags on the flap); the chord
  /// stays fore-and-aft, so the blade thins as it sweeps back. [u0]..[u1]
  /// selects a stretch of the span and [trailK] how much of the trailing
  /// chord to keep, for the coloured bands; [notch] cuts feather tips into the
  /// trailing edge.
  static Path _airWing(
    double b0,
    double b1,
    double len,
    double lead,
    double trail, {
    double u0 = 0,
    double u1 = 1,
    double trailK = 1,
    int n = 8,
    double notch = 0,
  }) {
    final arm = _airSpan(b0) * (len * .42);
    final hand = _airSpan(b1) * (len * .58);
    Offset centre(double u) =>
        u <= .42 ? arm * (u / .42) : arm + hand * ((u - .42) / .58);
    const chord = Offset(1, .3);
    double lw(double u) => lead * (1 - .7 * u * u);
    double tw(double u) =>
        trail *
        math.pow(math.sin(math.pi * (.06 + .86 * u)), .8).toDouble() *
        (1 - .5 * u * u * u) *
        trailK;
    final path = Path();
    for (var i = 0; i <= n; i++) {
      final u = u0 + (u1 - u0) * i / n;
      final p = centre(u) + chord * lw(u);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    for (var i = n; i >= 0; i--) {
      final u = u0 + (u1 - u0) * i / n;
      final cut = notch > 0 && u > .5 && i.isOdd ? 1 - notch : 1.0;
      final p = centre(u) - chord * (tw(u) * cut);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// A tapering feather from [a] to [b], [w0] wide at the root and [w1] at
  /// the tip, cut to the stretch [u0]..[u1] and ending in a point.
  static Path _airFeather(
    Offset a,
    Offset b,
    double w0,
    double w1,
    double u0,
    double u1,
  ) {
    final d = b - a;
    final nrm = Offset(-d.dy, d.dx) / d.distance;
    Offset at(double u, double side) =>
        a + d * u + nrm * ((w0 + (w1 - w0) * u) * side);
    final shoulder = math.min(u1, .8);
    return Path()
      ..moveTo(at(u0, 1).dx, at(u0, 1).dy)
      ..lineTo(at(shoulder, 1).dx, at(shoulder, 1).dy)
      ..quadraticBezierTo(at(.96, 1).dx, at(.96, 1).dy, b.dx, b.dy)
      ..quadraticBezierTo(
        at(.96, -1).dx,
        at(.96, -1).dy,
        at(shoulder, -1).dx,
        at(shoulder, -1).dy,
      )
      ..lineTo(at(u0, -1).dx, at(u0, -1).dy)
      ..close();
  }

  static const _airMacawRed = Color(0xffd93a2d),
      _airMacawLit = Color(0xffee5a42),
      _airMacawShade = Color(0xffa42a2c),
      _airMacawYellow = Color(0xfff0c03a),
      _airMacawBlue = Color(0xff2f66c4),
      _airNavy = Color(0xff1c2c50);

  // The parts of a macaw that never change shape are built once.
  static const _airTailA0 = Offset(-.3, .06), _airTailA1 = Offset(-1.6, .34);
  static const _airTailB0 = Offset(-.32, -.02), _airTailB1 = Offset(-1.85, .16);
  static final _airMacawTail = [
    _airFeather(_airTailA0, _airTailA1, .14, .06, 0, 1),
    _airFeather(_airTailA0, _airTailA1, .14, .06, .56, 1),
    _airFeather(_airTailB0, _airTailB1, .17, .06, 0, 1),
    _airFeather(_airTailB0, _airTailB1, .17, .06, .56, 1),
  ];
  static final _airMacawBody = [
    Path()
      ..moveTo(-.36, .0)
      ..cubicTo(-.25, -.3, .45, -.36, .78, -.2)
      ..cubicTo(.94, -.02, .8, .26, .42, .3)
      ..cubicTo(.05, .34, -.32, .22, -.36, .0)
      ..close(),
    Path()
      ..moveTo(-.22, -.06)
      ..cubicTo(-.05, -.28, .45, -.33, .72, -.19)
      ..cubicTo(.45, -.2, .05, -.12, -.22, -.06)
      ..close(),
    Path()
      ..moveTo(-.32, .1)
      ..cubicTo(-.05, .3, .4, .3, .8, .04)
      ..cubicTo(.5, .2, .1, .17, -.32, .1)
      ..close(),
  ];
  static final _airMacawBeak = [
    Path()
      ..moveTo(.98, -.05)
      ..cubicTo(1.16, -.06, 1.3, -.01, 1.33, .09)
      ..cubicTo(1.2, .17, 1.02, .13, .96, .0)
      ..close(),
    Path()
      ..moveTo(.93, -.34)
      ..cubicTo(1.2, -.42, 1.52, -.24, 1.42, .13)
      ..cubicTo(1.35, .03, 1.16, -.06, .97, -.03)
      ..close(),
    Path()
      ..moveTo(1.42, .13)
      ..cubicTo(1.35, .03, 1.16, -.06, .97, -.03)
      ..cubicTo(1.16, -.02, 1.3, .05, 1.36, .13)
      ..close(),
  ];

  /// One scarlet macaw wing: blue flight feathers with a yellow band and a
  /// red leading edge stacked along the front of the blade.
  static void _airMacawWing(
    Canvas c,
    double beat,
    double lagged,
    double len,
    double presence, {
    bool far = false,
  }) {
    Color tone(Color base) => far ? Sketch.mix(base, _airNavy, .4) : base;
    c.drawPath(
      _airWing(beat, lagged, len, .16, .56, n: 12, notch: .24),
      _airFill(tone(_airMacawBlue), presence),
    );
    c.drawPath(
      _airWing(beat, lagged, len, .16, .56, u1: .88, trailK: .5),
      _airFill(tone(_airMacawYellow), presence),
    );
    c.drawPath(
      _airWing(beat, lagged, len, .16, .56, u1: .66, trailK: .16),
      _airFill(tone(_airMacawRed), presence),
    );
  }

  /// A scarlet macaw in flight, facing right (mirror with [dir]): long
  /// tapering tail, pale face patch, heavy hooked beak, banded wings. [flap]
  /// is the wing phase in radians; [glide] holds the wings out and still.
  static void _airMacaw(
    Canvas c,
    Offset at,
    double s,
    double flap,
    double presence, {
    double glide = 0,
    double dir = 1,
  }) {
    final beat = math.sin(flap) * (1 - glide) + .2 * glide;
    final lagged = math.sin(flap - .85) * (1 - glide) + .2 * glide;
    c.save();
    c.translate(at.dx, at.dy - math.cos(flap) * s * .07 * (1 - glide));
    c.scale(dir * s, s);
    c.rotate(-.1 - .05 * beat);
    // The far wing, a little higher and darker, behind the body.
    c.save();
    c.translate(.4, -.2);
    _airMacawWing(c, beat * .9, lagged * .9, 1.6, presence, far: true);
    c.restore();
    // Tail: two long feathers, red with blue tips.
    final tail = _airMacawTail;
    c.drawPath(
      tail[0],
      _airFill(Sketch.mix(_airMacawShade, _airMacawBlue, .12), presence),
    );
    c.drawPath(
      tail[1],
      _airFill(Sketch.mix(_airMacawBlue, _airNavy, .3), presence),
    );
    c.drawPath(tail[2], _airFill(_airMacawRed, presence));
    c.drawPath(tail[3], _airFill(_airMacawBlue, presence));
    // Body, with a lit back and a shaded belly.
    c.drawPath(_airMacawBody[0], _airFill(_airMacawRed, presence));
    c.drawPath(_airMacawBody[1], _airFill(_airMacawLit, presence * .85));
    c.drawPath(_airMacawBody[2], _airFill(_airMacawShade, presence * .8));
    // Head: pale face patch, dark eye, big hooked beak.
    c.drawCircle(const Offset(.88, -.17), .23, _airFill(_airMacawRed, presence));
    c.drawOval(
      Rect.fromCenter(center: const Offset(.99, -.13), width: .3, height: .21),
      _airFill(const Color(0xfffbf8f2), presence),
    );
    c.drawCircle(
      const Offset(.97, -.15),
      .044,
      _airFill(const Color(0xff241818), presence),
    );
    c.drawPath(
      _airMacawBeak[0],
      _airFill(const Color(0xff403632), presence),
    );
    c.drawPath(
      _airMacawBeak[1],
      _airFill(const Color(0xffe9d6aa), presence),
    );
    c.drawPath(
      _airMacawBeak[2],
      _airFill(const Color(0xffcdb48a), presence),
    );
    // The near wing, over the body.
    c.save();
    c.translate(.26, -.1);
    _airMacawWing(c, beat, lagged, 1.85, presence);
    c.restore();
    c.restore();
  }

  static const _airToucanBlack = Color(0xff2b2b35);
  static final _airToucanTail = Sketch.poly([
    -.45, -.12, -1.75, .0, -1.78, .22, -.45, .24, //
  ]);
  static final _airToucanBill = [
    Path()
      ..moveTo(.96, -.29)
      ..cubicTo(1.5, -.44, 2.1, -.3, 2.3, .1)
      ..cubicTo(1.75, .04, 1.3, .14, .96, .13)
      ..close(),
    Path()
      ..moveTo(.96, .05)
      ..cubicTo(1.3, .06, 1.8, .03, 2.2, .12)
      ..cubicTo(1.8, .27, 1.3, .27, .96, .2)
      ..close(),
    Path()
      ..moveTo(1.95, -.34)
      ..cubicTo(2.14, -.28, 2.27, -.1, 2.3, .1)
      ..cubicTo(2.14, .07, 2.05, .09, 1.92, .1)
      ..close(),
    Path()
      ..moveTo(1.0, -.27)
      ..cubicTo(1.5, -.4, 2.0, -.28, 2.1, -.2)
      ..cubicTo(1.6, -.28, 1.3, -.22, 1.0, -.2)
      ..close(),
    Sketch.poly([.94, -.29, 1.06, -.28, 1.06, .14, .94, .13]),
  ];

  /// A toucan: black body, pale bib, one enormous banded bill. It flaps in
  /// bursts ([burst] 1) and glides with the wings folded ([burst] 0).
  static void _airToucan(
    Canvas c,
    Offset at,
    double s,
    double flap,
    double presence, {
    double burst = 1,
  }) {
    final beat = math.sin(flap) * burst + .15 * (1 - burst);
    final lagged = math.sin(flap - .8) * burst + .15 * (1 - burst);
    const black = _airToucanBlack;
    c.save();
    c.translate(at.dx, at.dy - math.cos(flap) * s * .06 * burst);
    c.scale(s, s);
    c.rotate(.04 * (1 - burst) - .08 * burst);
    c.save();
    c.translate(.3, -.2);
    c.drawPath(
      _airWing(beat * .9, lagged * .9, 1.25, .16, .5),
      _airFill(Sketch.mix(black, const Color(0xff101018), .4), presence),
    );
    c.restore();
    // A square tail, with the red vent showing beneath.
    c.drawPath(_airToucanTail, _airFill(black, presence));
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.55, .2), width: .36, height: .2),
      _airFill(const Color(0xffd6402e), presence),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 1.7, height: .58),
      _airFill(black, presence),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.1, -.12), width: 1.2, height: .26),
      _airFill(const Color(0xff4a4a5c), presence * .8),
    );
    c.drawCircle(const Offset(.78, -.1), .26, _airFill(black, presence));
    // The bib: pale yellow throat with an orange lower edge.
    c.drawOval(
      Rect.fromCenter(center: const Offset(.82, .13), width: .52, height: .42),
      _airFill(const Color(0xffe89a34), presence),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(.82, .1), width: .5, height: .36),
      _airFill(const Color(0xfffbeba6), presence),
    );
    c.drawCircle(
      const Offset(.95, -.15),
      .078,
      _airFill(const Color(0xff4aa8dc), presence),
    );
    c.drawCircle(
      const Offset(.96, -.15),
      .04,
      _airFill(const Color(0xff141418), presence),
    );
    // The bill: a long banana, orange-gold over pale, red at the tip.
    final bill = _airToucanBill;
    c.drawPath(bill[0], _airFill(const Color(0xfff2b23a), presence));
    c.drawPath(bill[1], _airFill(const Color(0xffe58f2f), presence));
    c.drawPath(bill[2], _airFill(const Color(0xffdd4a2c), presence));
    c.drawPath(bill[3], _airFill(const Color(0xfffbd77a), presence * .8));
    c.drawPath(bill[4], _airFill(black, presence));
    c.save();
    c.translate(.2, -.1);
    c.drawPath(
      _airWing(beat, lagged, 1.5, .18, .55),
      _airFill(const Color(0xff1c1c26), presence),
    );
    c.drawPath(
      _airWing(beat, lagged, 1.5, .18, .55, u0: .25, trailK: .4),
      _airFill(const Color(0xff3c4f8c), presence * .8),
    );
    c.restore();
    c.restore();
  }

  static final _airParrotTail = Sketch.poly([
    -.4, -.05, -1.25, .12, -1.2, .2, -.4, .12, //
  ]);

  /// A tiny parrot, hazed into the distance: green body, lighter wings.
  static void _airParrot(
    Canvas c,
    Offset at,
    double s,
    double flap,
    double presence,
  ) {
    final beat = math.sin(flap);
    final lagged = math.sin(flap - .8);
    final body = _hazed(const Color(0xff4c9a55), .3);
    final wing = _hazed(const Color(0xff6dbb63), .25);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(s, s);
    c.save();
    c.translate(.25, -.1);
    c.drawPath(
      _airWing(beat, lagged, 1.0, .1, .3, n: 5),
      _airFill(Sketch.mix(wing, const Color(0xff2f6a4a), .4), presence),
    );
    c.restore();
    c.drawPath(_airParrotTail, _airFill(body, presence));
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 1.1, height: .42),
      _airFill(body, presence),
    );
    c.drawCircle(const Offset(.5, -.1), .2, _airFill(body, presence));
    c.save();
    c.translate(.15, -.06);
    c.drawPath(
      _airWing(beat, lagged, 1.1, .1, .32, n: 5),
      _airFill(wing, presence),
    );
    c.restore();
    c.restore();
  }

  // Morpho wings in unit space: forewing up, hindwing down, both sides.
  static Path _airMorphoHalf(double side) => Path()
    ..moveTo(0, -.05)
    ..quadraticBezierTo(side * .42, -1.0, side * 1.0, -.62)
    ..quadraticBezierTo(side * .98, -.2, side * .16, .02)
    ..quadraticBezierTo(side * .9, .02, side * .8, .5)
    ..quadraticBezierTo(side * .5, .9, side * .05, .38)
    ..close();
  static final _airMorphoWings = Path()
    ..addPath(_airMorphoHalf(1), Offset.zero)
    ..addPath(_airMorphoHalf(-1), Offset.zero);
  static final _airMorphoFold = _airMorphoHalf(1);

  static void _airMorphos(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final travel = f.reducedMotion ? 0.0 : f.distance * h;
    final span = w + h * .6;
    for (var i = 0; i < 3; i++) {
      final r1 = Sketch.hash(i * 3 + 1400), r2 = Sketch.hash(i * 3 + 1401);
      final x =
          (r1 * span - travel * .08 - t * h * .022) % span -
          h * .3 +
          math.sin(t * .6 + i * 2.1) * h * .05;
      final y =
          h * (.7 + .05 * r2 + .02 * i) +
          math.sin(t * 1.1 + i * 1.7) * h * .018;
      final wave = .5 + .5 * math.cos(t * 15 + i * .6);
      final s = h * (.022 + .003 * i);
      final spread = wave > .3;
      c.save();
      c.translate(x, y);
      c.rotate(math.sin(t * .8 + i) * .25);
      c.save();
      if (spread) {
        // Wings open flash iridescent blue inside a dark border.
        c.scale(s * (.3 + .7 * wave), s);
        c.drawPath(_airMorphoWings, _airFill(const Color(0xff1f2f5c), presence));
        c.scale(.8, .8);
        c.drawPath(_airMorphoWings, _airFill(const Color(0xff4b8ae6), presence));
      } else {
        // Closed, the wings stand up together and show their brown underside.
        c.scale(s * .5, s);
        c.drawPath(_airMorphoFold, _airFill(const Color(0xff5a3f2c), presence));
        c.scale(.8, .8);
        c.drawPath(_airMorphoFold, _airFill(const Color(0xff8b6544), presence));
      }
      c.restore();
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * .2, height: s * .8),
        _airFill(const Color(0xff1c1c26), presence),
      );
      c.restore();
    }
  }

  static final _airDragonWing = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(.5, -.2, 1, -.02)
    ..quadraticBezierTo(.5, .12, 0, 0)
    ..close();

  /// Emerald dragonflies hovering over the mist, darting between hover
  /// spots; the wings are a translucent blur so they need no animation.
  static void _airDragonflies(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    for (var i = 0; i < 2; i++) {
      final home = Offset(w * (i == 0 ? .3 : .8), h * (i == 0 ? .745 : .715));
      Offset spot(int k) =>
          home +
          Offset(
            (Sketch.hash(k * 7 + i * 100 + 1) - .5) * h * .5,
            (Sketch.hash(k * 7 + i * 100 + 2) - .5) * h * .08,
          );
      final u = t / 3.1 + i * .41;
      final k = u.floor();
      final move = RegionBlend.smooth((u - k - .8) / .2);
      final from = spot(k), to = spot(k + 1);
      final p =
          Offset.lerp(from, to, move)! +
          Offset(math.sin(t * 9 + i) * h * .0025, math.sin(t * 7 + i * 2) * h * .003);
      final s = h * .017;
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(to.dx >= from.dx ? s : -s, s);
      for (final (a, x, sc) in const [
        (-1.4, .5, 1.0),
        (1.4, .5, 1.0),
        (-1.55, .2, .92),
        (1.55, .2, .92),
      ]) {
        c.save();
        c.translate(x, 0);
        c.rotate(a);
        c.scale(sc * 1.1, .7);
        c.drawPath(_airDragonWing, _airFill(const Color(0xfff4fbff), .5 * presence));
        c.restore();
      }
      c.drawLine(
        const Offset(.9, 0),
        const Offset(-1.7, .05),
        _airStroke(const Color(0xff1f9c8a), presence, .2),
      );
      c.drawCircle(const Offset(.95, 0), .15, _airFill(const Color(0xff2a5f8c), presence));
      c.restore();
    }
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  // -- tepui ------------------------------------------------------------------
  // Everything below is measured in "tepui heights": u runs across from the
  // summit's centre, v runs up (negative) and down from the tepui's base line.

  static const _tepuiLit = Color(0xffcfbc98);
  static const _tepuiPale = Color(0xffeee3c4);
  static const _tepuiBand = Color(0xff9c8562);
  static const _tepuiShade = Color(0xff6a8894);
  static const _tepuiDeep = Color(0xff3f5c69);
  static const _tepuiScrub = Color(0xff4b8560);
  static const _tepuiScrubLit = Color(0xff8fc27a);
  static const _tepuiForest = Color(0xff3a7454);
  static const _tepuiVapour = Color(0xfffbfcf0);
  static const _tepuiUnder = Color(0xffb9d2d2);
  static const _tepuiWater = Color(0xfffafffb);

  /// The summit rim: a nearly level skyline with a low step to the right and
  /// (on the great tepui) the notch the water spills through.
  static double _tepuiRim(double u, int seed, bool main) =>
      -.35 +
      .006 * math.sin(u * 19 + seed) +
      .004 * math.sin(u * 47 + seed * 2) +
      (main
          ? .009 * math.exp(-math.pow((u - .05) / .022, 2)) -
                .012 * math.exp(-math.pow((u + .2) / .05, 2))
          : -.03 * u) +
      .014 * ((u - .13) / .05).clamp(0.0, 1.0);

  /// Where the main stream runs, across the wall.
  static double _tepuiStreamU(double v) => .05 + .005 * math.sin(v * 24 + 1);

  /// A great tepui with a ribbon waterfall, and a smaller, hazier one
  /// standing behind it.
  void _tepui(Canvas c, double x, double h, double w) {
    final back = math.min(x + h * .58, w - h * .04);
    _tepuiMass(c, back, h * .62, h * .84, .95, seed: 5, haze: .62, main: false);
    _tepuiMass(c, x, h * .64, h, 1.3, seed: 0, haze: .34, main: true);
    _tepuiFall(c, x, h);
  }

  /// One flat-topped, sheer-walled mountain: lit and shade planes, bedding,
  /// fluting, ledges with scrub, a forested foot and a cap of stunted forest.
  static void _tepuiMass(
    Canvas c,
    double cx,
    double base,
    double k,
    double wide, {
    required int seed,
    required double haze,
    required bool main,
  }) {
    Color hz(Color col, [double a = 1]) => Sketch.fade(_hazed(col, haze), a);
    double px(double u) => cx + u * k * wide;
    double py(double v) => base + v * k;
    double rim(double u) => _tepuiRim(u, seed, main);
    double rnd(int n) => Sketch.hash(seed * 97 + n);
    final hair = math.max(.6, k * .0026);
    const left = [
      (-.3, -.32),
      (-.312, -.27),
      (-.296, -.22),
      (-.31, -.15),
      (-.3, -.115),
      (-.335, -.07),
      (-.4, -.02),
      (-.55, .05),
      (-.75, .16),
    ];
    const right = [
      (.28, -.325),
      (.29, -.28),
      (.276, -.22),
      (.291, -.16),
      (.284, -.115),
      (.318, -.08),
      (.385, -.02),
      (.53, .05),
      (.75, .16),
    ];
    const rimSteps = 30;
    final wall = Path()..moveTo(px(left.last.$1), py(left.last.$2));
    for (var i = left.length - 2; i >= 0; i--) {
      wall.lineTo(px(left[i].$1), py(left[i].$2));
    }
    for (var i = 0; i <= rimSteps; i++) {
      final u = -.3 + .58 * i / rimSteps;
      wall.lineTo(px(u), py(rim(u)));
    }
    for (final (u, v) in right) {
      wall.lineTo(px(u), py(v));
    }
    wall.close();
    final top = py(-.37), bottom = py(.05);

    // Cloud plumes rising behind the summit.
    if (main) {
      _tepuiCloud(c, Offset(px(-.27), py(-.36)), k * .3, k * .055, seed + 1, .6);
      _tepuiCloud(c, Offset(px(.27), py(-.35)), k * .26, k * .045, seed + 2, .55);
    } else {
      _tepuiCloud(c, Offset(px(-.12), py(-.35)), k * .28, k * .045, seed + 1, .55);
    }

    c.save();
    c.clipPath(wall);
    // The sunlit plane, brightest along its sun-facing edge.
    c.drawRect(
      Rect.fromLTRB(px(-.8), top, px(.9), py(.2)),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          [hz(_tepuiLit), hz(Sketch.mix(_tepuiLit, _tepuiBand, .4))],
        ),
    );
    c.drawRect(
      Rect.fromLTRB(px(-.34), top, px(-.02), py(.2)),
      Paint()
        ..shader = Gradient.linear(
          Offset(px(-.3), 0),
          Offset(px(-.04), 0),
          [hz(_tepuiPale, .5), hz(_tepuiPale, 0)],
        ),
    );
    // Bedding: alternately bleached and dark sandstone courses.
    final rows = main ? 9 : 5;
    for (var j = 0; j < rows; j++) {
      final v0 = -.315 + j * .31 / rows + (rnd(j) - .5) * .012;
      final th = .01 + .02 * rnd(j + 20);
      double wob(double u) =>
          .004 * math.sin(u * 9 + j * 2.1 + seed) + .0025 * math.sin(u * 23 + j);
      final band = Path()..moveTo(px(-.8), py(v0 + wob(-.8)));
      for (var i = 1; i <= 14; i++) {
        final u = -.8 + 1.7 * i / 14;
        band.lineTo(px(u), py(v0 + wob(u)));
      }
      for (var i = 14; i >= 0; i--) {
        final u = -.8 + 1.7 * i / 14;
        band.lineTo(px(u), py(v0 + th + wob(u) * .7));
      }
      c.drawPath(
        band..close(),
        Paint()
          ..color = hz(j.isEven ? _tepuiPale : _tepuiBand, j.isEven ? .5 : .42),
      );
    }
    // The shade plane: a cooler, darker face turned away from the sun.
    final shade = Path()..moveTo(px(.02), py(-.4));
    for (final (u, v) in const [
      (.026, -.31),
      (.026, -.26),
      (.011, -.25),
      (.012, -.19),
      (.027, -.18),
      (.026, -.12),
      (.014, -.11),
      (.012, -.05),
      (.008, .2),
    ]) {
      shade.lineTo(px(u), py(v));
    }
    shade
      ..lineTo(px(.9), py(.2))
      ..lineTo(px(.9), py(-.4))
      ..close();
    c.drawPath(
      shade,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          [hz(_tepuiShade, .84), hz(_tepuiShade, .72)],
        ),
    );
    // Bounce light along the shade plane's far edge.
    c.drawPath(
      Sketch.poly([
        px(.255), py(-.34), px(.29), py(-.34), px(.32), py(-.05), px(.265), py(-.06), //
      ]),
      Paint()..color = hz(_tepuiLit, .16),
    );
    // Weathering: iron-rust stains on the sunlit plane, pale lichen on the
    // shaded one.
    for (var i = 0; i < (main ? 9 : 4); i++) {
      final u = -.27 + .53 * rnd(i + 900);
      final v = rim(u) + .06 + .18 * rnd(i + 910);
      final lit = u < .02;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(px(u), py(v)),
          width: k * (.014 + .02 * rnd(i + 920)) * wide,
          height: k * (.05 + .07 * rnd(i + 930)),
        ),
        Paint()..color = hz(lit ? const Color(0xffb17a56) : const Color(0xffa8b8a0), lit ? .2 : .18),
      );
    }
    // Great clefts split the wall into prows: shade on their left flank, a lit
    // rib on the right.
    final clefts = main
        ? const [-.25, -.18, -.1, .1, .17, .235]
        : const [-.2, -.04, .17];
    for (var i = 0; i < clefts.length; i++) {
      final u = clefts[i] + (rnd(i + 800) - .5) * .016;
      final v0 = rim(u) + .012, v1 = -.02;
      final lit = u < .02;
      final w0 = .004 + .002 * rnd(i + 810), w1 = .013 + .006 * rnd(i + 820);
      c.drawPath(
        Sketch.poly([
          px(u - w0), py(v0), px(u + w0 * .5), py(v0), //
          px(u + w1 * .4), py(v1), px(u - w1), py(v1),
        ]),
        Paint()..color = hz(lit ? _tepuiBand : _tepuiDeep, lit ? .55 : .5),
      );
      c.drawPath(
        Sketch.poly([
          px(u + w0 * .5), py(v0), px(u + w0 * 2.4), py(v0 + .005), //
          px(u + w1 * 1.9), py(v1), px(u + w1 * .4), py(v1),
        ]),
        Paint()..color = hz(lit ? _tepuiPale : _tepuiLit, lit ? .5 : .2),
      );
    }
    // Fluting: finer drainage grooves scored down the wall.
    final flutes = main ? 22 : 12;
    for (var i = 0; i < flutes; i++) {
      final u = -.285 + .57 * (i + .5 + (rnd(i + 40) - .5) * .7) / flutes;
      final r0 = rnd(i + 100), r1 = rnd(i + 200);
      final v0 = rim(u) + .018 + .07 * r0;
      final v1 = -.05 - .16 * r1;
      final w0 = .0025 + .002 * r1, w1 = .006 + .005 * r0;
      final lit = u < .02;
      c.drawPath(
        Sketch.poly([
          px(u - w0), py(v0), px(u + w0 * .6), py(v0), //
          px(u + w1), py(v1), px(u - w1 * .6), py(v1),
        ]),
        Paint()..color = hz(lit ? _tepuiBand : _tepuiDeep, lit ? .36 : .34),
      );
      c.drawPath(
        Sketch.poly([
          px(u + w0 * .6), py(v0), px(u + w0 * 1.7), py(v0 + .01), //
          px(u + w1 * 2.1), py(v1), px(u + w1), py(v1),
        ]),
        Paint()..color = hz(lit ? _tepuiPale : _tepuiLit, lit ? .34 : .14),
      );
    }
    // Rock shelters: shadowed hollows with a lit lower lip, and fine cracks.
    if (main) {
      for (var i = 0; i < 7; i++) {
        final u = -.26 + .52 * rnd(i + 1000);
        if ((u - .05).abs() < .05) continue;
        final v = -.27 + .14 * rnd(i + 1010) + (i > 3 ? .06 : 0);
        final rw = k * (.008 + .008 * rnd(i + 1020)) * wide;
        final rh = rw / wide * (.55 + .3 * rnd(i + 1030));
        c.drawOval(
          Rect.fromCenter(center: Offset(px(u), py(v)), width: rw * 2, height: rh * 2),
          Paint()..color = hz(_tepuiDeep, u < .02 ? .5 : .55),
        );
        c.drawOval(
          Rect.fromCenter(center: Offset(px(u) + rw * .1, py(v) + rh * .55), width: rw * 1.7, height: rh * .7),
          Paint()..color = hz(_tepuiPale, u < .02 ? .35 : .15),
        );
        c.drawOval(
          Rect.fromCenter(center: Offset(px(u), py(v) - rh * .1), width: rw * 1.8, height: rh * 1.5),
          Paint()..color = hz(_tepuiDeep, .35),
        );
      }
    }
    // Dark tannin streaks where seepage runs.
    final streak = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = hz(_tepuiDeep, .26)
      ..strokeWidth = math.max(hair, k * .0032);
    for (var i = 0; i < (main ? 12 : 4); i++) {
      final u = -.27 + .53 * rnd(i + 300);
      final v0 = rim(u) + .03 + .04 * rnd(i + 310);
      final v1 = v0 + .07 + .12 * rnd(i + 320);
      c.drawLine(Offset(px(u), py(v0)), Offset(px(u + .004), py(v1)), streak);
    }
    if (!main) {
      // A thread of water on the distant tepui.
      const tu = -.1;
      final t0 = rim(tu) + .012;
      c.drawPath(
        Sketch.poly([
          px(tu - .002), py(t0), px(tu + .002), py(t0), //
          px(tu + .007), py(-.03), px(tu - .006), py(-.03),
        ]),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, py(t0)),
            Offset(0, py(-.03)),
            [hz(_tepuiWater, .85), hz(_tepuiWater, .15)],
          ),
      );
    }
    // The caprock overhang throws a scalloped shadow down the wall.
    final eave = Path()..moveTo(px(-.31), py(rim(-.3)));
    for (var i = 0; i <= rimSteps; i++) {
      final u = -.3 + .58 * i / rimSteps;
      eave.lineTo(px(u), py(rim(u)));
    }
    for (var i = rimSteps; i >= 0; i--) {
      final u = -.3 + .58 * i / rimSteps;
      eave.lineTo(px(u), py(rim(u) + .014 + .011 * rnd(i + 400)));
    }
    c.drawPath(eave..close(), Paint()..color = hz(_tepuiDeep, .36));
    // Ledges carry scrub, and plants hang from their lips.
    if (main) {
      final hang = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(hair, k * .0026);
      final lipPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(hair, k * .0028);
      final mound = Paint(), moundLit = Paint(), under = Paint();
      var n = 0;
      for (final (u0, u1, v, plants) in const [
        (-.27, -.16, -.265, 4),
        (-.14, -.03, -.235, 3),
        (.09, .21, -.215, 4),
        (-.285, -.2, -.17, 3),
        (.16, .275, -.15, 3),
        (-.12, -.01, -.125, 3),
        (.08, .17, -.1, 2),
        (-.24, -.14, -.085, 2),
        (-.06, -.005, -.19, 2),
        (.085, .13, -.055, 2),
      ]) {
        n += 20;
        final shaded = u0 > 0;
        // The shelf leans a little; ly follows its lip.
        final tilt = (rnd(n + 490) - .5) * .014;
        double ly(double u) => v + tilt * (u - u0) / (u1 - u0);
        under.color = hz(_tepuiDeep, .4);
        c.drawPath(
          Sketch.poly([
            px(u0), py(v + .002), px(u1), py(ly(u1) + .002), //
            px(u1 - .03), py(ly(u1) + .01), px((u0 + u1) / 2), py(ly((u0 + u1) / 2) + .013), px(u0 + .03), py(v + .009),
          ]),
          under,
        );
        lipPaint.color = hz(_tepuiPale, .6);
        c.drawLine(Offset(px(u0 + .004), py(v)), Offset(px(u1 - .003), py(ly(u1 - .003))), lipPaint);
        // Domes of scrub with a lit crown on their sunward side.
        final mounds = 4 + (rnd(n + 495) * 3).floor();
        final path = Path()..moveTo(px(u0 + .006), py(ly(u0 + .006)));
        final lits = <Offset>[];
        final litSizes = <double>[];
        for (var i = 0; i < mounds; i++) {
          final xa = u0 + .006 + (u1 - u0 - .012) * i / mounds;
          final xb = u0 + .006 + (u1 - u0 - .012) * (i + 1) / mounds;
          final bump = k * (.007 + .014 * rnd(n + i + 500));
          path.cubicTo(px(xa + (xb - xa) * .05), py(ly(xa)) - bump * 1.45, px(xb - (xb - xa) * .05), py(ly(xb)) - bump * 1.45, px(xb), py(ly(xb)));
          lits.add(Offset(px(xa * .6 + xb * .4), py(ly(xa)) - bump * .78));
          litSizes.add(bump);
        }
        mound.color = hz(shaded ? _tepuiForest : _tepuiScrub);
        c.drawPath(path..close(), mound);
        moundLit.color = hz(shaded ? _tepuiScrub : _tepuiScrubLit, shaded ? .7 : .9);
        for (var i = 0; i < mounds; i++) {
          c.drawOval(
            Rect.fromCenter(center: lits[i], width: litSizes[i] * 1.0 * wide, height: litSizes[i] * .5),
            moundLit,
          );
        }
        // Trails of vine and fern hang from the lip, some very long.
        for (var i = 0; i < plants; i++) {
          final u = u0 + (u1 - u0) * (i + .25 + rnd(n + i + 540) * .5) / plants;
          final strands = 1 + (rnd(n + i + 560) * 2.4).floor();
          for (var s = 0; s < strands; s++) {
            final long = rnd(n + i + 580) > .8 ? 2.2 : 1.0;
            final len = k * (.012 + .03 * rnd(n + i * 3 + s + 600)) * long;
            final sway = (rnd(n + i * 3 + s + 620) - .5) * len * 1.2;
            hang.color = hz(s == 1 && !shaded ? _tepuiScrubLit : (shaded ? _tepuiForest : _tepuiScrub), .9);
            final x0 = px(u) + (s - .5) * k * .007 * wide * (.6 + rnd(n + i + s + 640));
            final y0 = py(ly(u) + .006);
            final end = Offset(x0 + sway, y0 + len);
            c.drawPath(
              Path()
                ..moveTo(x0, y0)
                ..quadraticBezierTo(x0 - sway * .3, y0 + len * .6, end.dx, end.dy),
              hang,
            );
            if (s != 0 || long > 1) {
              // A tuft of leaves at the tip of the longer trails.
              mound.color = hz(shaded ? _tepuiScrub : _tepuiScrubLit, .9);
              c.drawOval(
                Rect.fromCenter(center: end, width: k * .008 * wide, height: k * .006),
                mound,
              );
            }
          }
        }
      }
    }
    // A pale lip catches the sun along the rim of the lit plane.
    final lip = Path()..moveTo(px(-.3), py(rim(-.3)));
    for (var i = 1; i <= rimSteps; i++) {
      final u = -.3 + .58 * i / rimSteps;
      if (u > .04) break;
      lip.lineTo(px(u), py(rim(u)));
    }
    c.drawPath(
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = hz(_tepuiPale, .8)
        ..strokeWidth = math.max(hair, k * .004),
    );
    // Mist wets the foot of the wall.
    c.drawRect(
      Rect.fromLTRB(px(-.8), py(-.13), px(.9), py(.2)),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, py(-.13)),
          Offset(0, py(.02)),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .6)],
        ),
    );
    c.restore();

    // Forested talus skirt around the foot: a dark back row, then sunlit
    // crowns in front.
    final skirtTop = main ? -.1 : -.085;
    double talus(double u) => skirtTop + math.max(0.0, u.abs() - .27 * wide) * .5 / wide;
    final skirt = Path()..moveTo(px(-.9), py(.25));
    for (var i = 0; i <= 24; i++) {
      final u = -.9 + 1.8 * i / 24;
      skirt.lineTo(px(u), py(talus(u)));
    }
    skirt
      ..lineTo(px(.9), py(.25))
      ..close();
    c.drawPath(skirt, Paint()..color = hz(_tepuiForest));
    final crown = Paint(), crownLit = Paint();
    final crowns = main ? 110 : 46;
    for (var i = 0; i < crowns; i++) {
      final row = i % 3;
      final u = -.85 + 1.7 * (i + rnd(i + 600) * .8) / crowns;
      final r = k * (.011 + .012 * rnd(i + 620)) * (1 + .15 * row);
      final y = py(talus(u) + .008 * row + .01 * rnd(i + 640)) + r * .1;
      final sunny = u < .1;
      crown.color = hz(row == 0 ? _tepuiForest : _tepuiScrub, 1);
      c.drawOval(
        Rect.fromCenter(center: Offset(px(u), y), width: r * 2.4 * wide, height: r * 1.7),
        crown,
      );
      crownLit.color = hz(_tepuiScrubLit, (sunny ? .75 : .32) * (row == 0 ? .4 : 1));
      c.drawOval(
        Rect.fromCenter(
          center: Offset(px(u) - r * .3 * wide, y - r * .5),
          width: r * 1.0 * wide,
          height: r * .55,
        ),
        crownLit,
      );
    }

    // Hoodoos on the plateau.
    if (main) {
      for (final (u, tall, wd) in const [(-.16, .042, .016), (.2, .05, .018), (-.05, .026, .012)]) {
        final b = rim(u) + .012, t = rim(u) - tall;
        c.drawPath(
          Sketch.poly([
            px(u - wd), py(b), px(u - wd * .75), py(t + .012), //
            px(u - wd * .2), py(t), px(u), py(b),
          ]),
          Paint()..color = hz(_tepuiLit),
        );
        c.drawPath(
          Sketch.poly([
            px(u), py(b), px(u - wd * .2), py(t), px(u + wd * .55), py(t + .006), //
            px(u + wd * .85), py(b),
          ]),
          Paint()..color = hz(_tepuiShade, .9),
        );
      }
    }
    // The cap: stunted cloud-forest scrub crowding the rim, a dark under-row
    // and lit crowns above it.
    final cap = main ? 64 : 34;
    final scrub = Paint(), scrubLit = Paint();
    c.drawPath(
      Path()
        ..moveTo(px(-.3), py(rim(-.3) + .006))
        ..lineTo(px(-.3), py(rim(-.3) - .004))
        ..lineTo(px(.29), py(rim(.29) - .004))
        ..lineTo(px(.29), py(rim(.29) + .006))
        ..close(),
      Paint()..color = hz(_tepuiForest),
    );
    for (var i = 0; i <= cap; i++) {
      final u = -.305 + .6 * (i + (rnd(i + 700) - .5) * .6) / cap;
      if (main && (u - .05).abs() < .02) continue;
      final r = k * (.006 + .01 * rnd(i + 720) + (rnd(i + 730) > .88 ? .011 : 0));
      final y = py(rim(u)) - r * .5;
      scrub.color = hz(i.isEven ? _tepuiScrub : _tepuiForest);
      c.drawOval(
        Rect.fromCenter(center: Offset(px(u), y), width: r * 2.4 * wide, height: r * 1.8),
        scrub,
      );
      scrubLit.color = hz(_tepuiScrubLit, u < .1 ? .85 : .4);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(px(u) - r * .3 * wide, y - r * .4),
          width: r * 1.3 * wide,
          height: r * .8,
        ),
        scrubLit,
      );
    }
    // Orchids and blossoms speckle the cloud-forest scrub.
    if (main) {
      final bloom = Paint();
      for (var i = 0; i < 12; i++) {
        final u = -.28 + .56 * rnd(i + 950);
        if ((u - .05).abs() < .025) continue;
        bloom.color = hz(i % 3 == 0 ? const Color(0xfff4eef0) : const Color(0xffe58fae), .9);
        c.drawCircle(Offset(px(u), py(rim(u)) - k * (.006 + .01 * rnd(i + 960))), k * .0028, bloom);
      }
    }
    // Scrub spills over the lip in a few places.
    for (final u in const [-.29, -.2, .1, .26]) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(px(u), py(rim(u) + .012)),
          width: k * .03 * wide,
          height: k * .022,
        ),
        Paint()..color = hz(_tepuiForest, .9),
      );
    }

    // The cloud collar wrapped around the summit.
    if (main) {
      _tepuiCloud(c, Offset(px(-.19), py(-.31)), k * .34, k * .045, seed + 3, .62);
      _tepuiCloud(c, Offset(px(.15), py(-.3)), k * .3, k * .04, seed + 4, .55);
      _tepuiCloud(c, Offset(px(-.04), py(-.15)), k * .34, k * .035, seed + 6, .42);
    } else {
      _tepuiCloud(c, Offset(px(.02), py(-.28)), k * .34, k * .04, seed + 3, .55);
    }
  }

  /// A drift of soft cumulus: a cool underside, a flat-based bank and a lumpy
  /// top, all feathered. [w] and [ht] are pixel sizes.
  static void _tepuiCloud(
    Canvas c,
    Offset at,
    double w,
    double ht,
    int seed,
    double alpha,
  ) {
    void fluff(Offset centre, double rw, double rh, Color color, double a) {
      final r = Rect.fromCenter(center: centre, width: rw, height: rh);
      c.save();
      c.translate(r.center.dx, r.center.dy);
      c.scale(1, rh / rw);
      c.drawCircle(
        Offset.zero,
        rw / 2,
        Paint()
          ..shader = Gradient.radial(
            Offset.zero,
            rw / 2,
            [Sketch.fade(color, a), Sketch.fade(color, a * .85), Sketch.fade(color, 0)],
            const [0, .55, 1],
          ),
      );
      c.restore();
    }

    fluff(at + Offset(0, ht * .4), w * 1.15, ht * 1.2, _tepuiUnder, alpha * .7);
    fluff(at + Offset(0, ht * .08), w * 1.3, ht * 1.5, _tepuiVapour, alpha * .85);
    for (var i = 0; i < 6; i++) {
      final t = (i + .5 + (Sketch.hash(seed * 13 + i) - .5) * .6) / 6;
      final r = ht * (.34 + .38 * math.sin(math.pi * t)) * (.7 + .6 * Sketch.hash(seed * 11 + i));
      fluff(at + Offset((t - .5) * w * .85, -r * .3), r * 3, r * 2.5, _tepuiVapour, alpha);
    }
  }

  /// The ribbon waterfall, its braided streams and the greenery it feeds.
  void _tepuiFall(Canvas c, double x, double h) {
    double px(double u) => x + u * h;
    double py(double v) => h * .64 + v * h;
    final foot = ridge(Depth.far, px(.05) / h, 0);
    final v0 = _tepuiRim(.05, 0, true) + .004;
    final v1 = foot - .64 + .014;
    Path ribbon(double Function(double) centre, double a, double b, double w0, double w1) {
      const n = 16;
      final l = <Offset>[], r = <Offset>[];
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        final v = a + (b - a) * t;
        final u = centre(v);
        final half = w0 + (w1 - w0) * math.pow(t, 1.5);
        l.add(Offset(px(u - half), py(v)));
        r.add(Offset(px(u + half), py(v)));
      }
      final p = Path()..moveTo(l.first.dx, l.first.dy);
      for (final o in l.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      for (final o in r.reversed) {
        p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    Paint water(double from, double to, double a0, double a1) => Paint()
      ..shader = Gradient.linear(
        Offset(0, py(from)),
        Offset(0, py(to)),
        [Sketch.fade(_tepuiWater, a0), Sketch.fade(_tepuiWater, a1)],
      );
    // Spray veil widening below the middle of the fall.
    c.drawPath(ribbon(_tepuiStreamU, -.27, v1, .004, .04), water(-.27, v1, 0, .3));
    // The main stream, and thinner braids that split and rejoin it.
    c.drawPath(ribbon(_tepuiStreamU, v0, v1, .003, .011), water(v0, v1, .95, .5));
    c.drawPath(
      ribbon((v) => _tepuiStreamU(v) - .022 - .002 * math.sin(v * 31), -.27, -.06, .0014, .0035),
      water(-.27, -.06, .7, .1),
    );
    c.drawPath(
      ribbon((v) => _tepuiStreamU(v) + .032 + .008 * math.sin(v * 21 + 2), v0, -.17, .0014, .0018),
      water(v0, -.17, .8, .3),
    );
    c.drawPath(
      ribbon((v) => _tepuiStreamU(v) + .034 - .006 * (v + .17) * 3 + .003 * math.sin(v * 45), -.165, v1, .0012, .0055),
      water(-.165, v1, .7, .35),
    );
    // Bright core down the main stream.
    c.drawPath(
      ribbon(_tepuiStreamU, v0, v1 - .06, .0012, .0035),
      water(v0, v1, 1, .5),
    );
    // Foam where the braids strike the ledges.
    for (final (u, v, r) in const [(.0, -.3, .014), (.088, -.17, .02), (.062, -.205, .012)]) {
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(px(u + .02), py(v)), width: h * r * 3, height: h * r * 1.4),
        _tepuiWater,
        .55,
      );
    }
    // The lip of the fall.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(px(.05), py(v0) + h * .004), width: h * .04, height: h * .016),
      _tepuiWater,
      .95,
    );
    // A faint rainbow hangs in the spray at the foot.
    final bow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, h * .0028);
    final centre = Offset(px(.03), py(v1) + h * .05);
    for (var i = 0; i < 6; i++) {
      bow.color = Sketch.fade(
        const [
          Color(0xffe7605a),
          Color(0xfff2a24a),
          Color(0xfff3dc60),
          Color(0xff7fcf74),
          Color(0xff5fb0d8),
          Color(0xff9a80d0),
        ][i],
        .13,
      );
      c.drawArc(
        Rect.fromCircle(center: centre, radius: h * (.128 - i * .0028)),
        -1.2,
        1.0,
        false,
        bow,
      );
    }
  }

  // The shared unit puff: a radial fade that is only ever scaled and given an
  // alpha, so animated mist costs no new shader per frame.
  static final _tepuiPuffWhite = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0xffffffff), Color(0x88ffffff), Color(0x00ffffff)],
      const [0, .5, 1],
    );
  static final _tepuiPuffHaze = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0xffd3e6c8), Color(0x88d3e6c8), Color(0x00d3e6c8)],
      const [0, .5, 1],
    );

  static void _tepuiPuff(Canvas c, Offset at, double rx, double ry, double alpha, {bool white = true}) {
    if (alpha <= .01) return;
    final paint = white ? _tepuiPuffWhite : _tepuiPuffHaze;
    paint.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(rx, ry);
    c.drawCircle(Offset.zero, 1, paint);
    c.restore();
  }

  /// The waterfall's moving veil: bright streaks sliding down each stream.
  void _tepuiLive(Canvas c, SceneFrame f) {
    final h = f.h, x = f.w * .68;
    double py(double v) => h * .64 + v * h;
    final foot = ridge(Depth.far, (x + h * .05) / h, 0);
    final v0 = _tepuiRim(.05, 0, true) + .004;
    final v1 = foot - .64 + .014;
    final streak = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // (offset from the main stream, first v, last v, width, speed, count)
    for (final (off, a, b, wd, speed, n) in [
      (0.0, v0, v1, .0022, .13, 5),
      (-.021, -.3, v1, .0013, .1, 3),
      (.034, v0, -.17, .0013, .16, 2),
    ]) {
      final span = b - a;
      for (var i = 0; i < n; i++) {
        final phase = (f.clock * speed + i / n + off * 7) % 1;
        final v = a + phase * span;
        final u = _tepuiStreamU(v) + off;
        final fade = math.sin(phase * math.pi);
        streak
          ..strokeWidth = h * wd * (1 + phase)
          ..color = Sketch.fade(_tepuiWater, .6 * fade);
        c.drawLine(Offset(x + u * h, py(v)), Offset(x + u * h, py(v) + h * .026), streak);
      }
    }
  }

  /// Mist pools, the plume at the foot of the fall and wisps round the summit.
  void _tepuiOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h, x = f.w * .68;
    // Morning mist pools at the foot of the tepui.
    final span = f.w + h * 1.6;
    for (var i = 0; i < 4; i++) {
      final mx = (span * i / 4 + f.clock * h * .008) % span - h * .6;
      _tepuiPuff(
        c,
        Offset(mx, h * (.63 + .012 * (i % 2))),
        h * (.3 + .1 * (i % 3)),
        h * .04,
        .6 * presence,
        white: false,
      );
    }
    // Spray boiling up where the water lands. It and the wisps thin out faster
    // than the mist pools, so they never hang in the air over a sinking tepui.
    final lively = presence * presence * presence;
    final fx = x + h * .05;
    final fy = ridge(Depth.far, fx / h, 0) * h;
    final breathe = math.sin(f.clock * .7);
    _tepuiPuff(c, Offset(fx, fy - h * .004), h * (.17 + .012 * breathe), h * .04, .8 * lively);
    _tepuiPuff(
      c,
      Offset(fx + h * .006 * math.sin(f.clock * .4), fy - h * .04),
      h * (.075 + .008 * breathe),
      h * .06,
      (.6 + .08 * breathe) * lively,
    );
    _tepuiPuff(c, Offset(fx - h * .09, fy - h * .01), h * .06, h * .022, .5 * lively);
    _tepuiPuff(c, Offset(fx + h * .1, fy - h * .012), h * .07, h * .024, .5 * lively);
    // Wisps of cloud slide slowly round the summit.
    final drift = math.sin(f.clock * .15) * h * .05;
    _tepuiPuff(c, Offset(x - h * .14 + drift, h * .335), h * .19, h * .024, .5 * lively);
    _tepuiPuff(c, Offset(x + h * .17 - drift, h * .31), h * .16, h * .02, .45 * lively);
  }

  /// An emergent rainforest tree: a pale straight trunk fanning into limbs
  /// under a flat, layered crown of leaf masses, with lianas, epiphytes and,
  /// on some, a mantle of flowers. [dome] swaps the umbrella for a rounder,
  /// Brazil-nut crown.
  static void _kapok(
    Canvas c,
    Offset base,
    double s, {
    int bloom = 0,
    bool dome = false,
  }) {
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy + v * s;
    final barkLit = _hazed(const Color(0xffb8b39c), .24);
    final bark = _hazed(const Color(0xff908e79), .24);
    final barkShade = _hazed(const Color(0xff6b6f5f), .26);
    // Some emergents are in flower: pink or golden trumpet trees.
    final (crownColor, shadeColor, litColor, fleck) = switch (bloom) {
      1 => (
        const Color(0xffe58fb0),
        const Color(0xffc9708f),
        const Color(0xfff6bcd0),
        const Color(0xfffff0f4),
      ),
      2 => (
        const Color(0xffe8c24f),
        const Color(0xffc9a23a),
        const Color(0xfff6e08a),
        const Color(0xfffff6cf),
      ),
      _ => (
        const Color(0xff5c9d74),
        const Color(0xff4c8a66),
        const Color(0xff93c99a),
        const Color(0xffe6f4d0),
      ),
    };
    // The golden crowns are hazed harder so they cannot read as a pickup.
    final gold = bloom == 2 ? .16 : 0.0;
    final crown = _hazed(crownColor, .24 + gold);
    final shade = _hazed(shadeColor, .26 + gold);
    final lit = _hazed(litColor, .18 + gold);
    final leafDeep = _hazed(const Color(0xff2a664a), .26);
    final leaf = _hazed(const Color(0xff4c8a66), .24);
    final leafLit = _hazed(const Color(0xff86c192), .2);
    // Leaf tiers sit behind the flowering ones.
    final backMid = bloom == 0 ? shade : leaf;
    final backLit = bloom == 0 ? crown : leafLit;

    final top = dome ? -.76 : -.66;
    final trunk = Path()
      ..moveTo(x(-.024), y(top))
      ..cubicTo(x(-.03), y(top * .55), x(-.04), y(-.12), x(-.1), y(.03))
      ..lineTo(x(.1), y(.03))
      ..cubicTo(x(.04), y(-.12), x(.03), y(top * .55), x(.024), y(top))
      ..close();
    c.drawPath(trunk, Paint()..color = bark);
    c.save();
    c.clipPath(trunk);
    c.drawRect(
      Rect.fromLTRB(x(-.2), y(top - .05), x(-.006), y(.05)),
      Paint()..color = barkLit,
    );
    c.drawRect(
      Rect.fromLTRB(x(.012), y(top - .05), x(.2), y(.05)),
      Paint()..color = barkShade,
    );
    // A few flutes and the pale rings of old thorn scars.
    final flute = Paint()
      ..style = PaintingStyle.stroke
      ..color = Sketch.fade(barkShade, .55)
      ..strokeWidth = math.max(.6, s * .006);
    for (final u in const [-.016, .003, .02]) {
      c.drawLine(Offset(x(u), y(top)), Offset(x(u * 2.6), y(-.02)), flute);
    }
    c.restore();

    // Limbs fan from the trunk head to the tiers.
    final trunkTop = Offset(x(0), y(top + .02));
    for (final (tx, ty, wide) in dome
        ? const [(-.3, -.86, .022), (.3, -.88, .022), (-.1, -.98, .016)]
        : const [(-.34, -.8, .024), (.33, -.8, .024), (-.12, -.87, .016), (.14, -.88, .016)]) {
      _canopyLimb(c, trunkTop, Offset(x(tx), y(ty)), s * wide, s * wide * .4, s * .018, bark, barkShade, barkLit);
    }
    // Epiphyte clumps ride the limbs.
    final clump = Paint()..color = leafDeep;
    for (final (ex, ey) in const [(-.16, -.74), (.17, -.75), (-.27, -.79)]) {
      c.drawCircle(Offset(x(ex), y(ey)), s * .02, clump);
    }

    void mass(double dx, double dy, double a, double b, Color sh, Color mi, Color li, int seed, [int lobes = 7]) =>
        _canopyMass(c, Offset(x(dx), y(dy)), a * s, b * s, sh, mi, li, seed: seed, lobes: lobes);
    if (dome) {
      mass(-.3, -.8, .24, .14, leafDeep, backMid, backLit, 1, 4);
      mass(.3, -.82, .24, .14, leafDeep, backMid, backLit, 2, 4);
    } else {
      mass(-.3, -.78, .27, .11, leafDeep, backMid, backLit, 1, 4);
      mass(.3, -.8, .27, .11, leafDeep, backMid, backLit, 2, 4);
    }
    // Lianas hang from the underside of the crown.
    final liana = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, s * .008)
      ..color = Sketch.fade(leafDeep, .8);
    final lianaLeaf = Paint()..color = Sketch.fade(leaf, .9);
    for (final (lx, len, sway) in const [(-.36, .26, .3), (-.2, .18, -.25), (.16, .22, .3), (.34, .3, -.3)]) {
      _canopyLiana(c, Offset(x(lx), y(dome ? -.78 : -.74)), len * s, sway, liana, lianaLeaf, s * .012);
    }
    if (dome) {
      mass(0, -.88, .4, .27, shade, crown, lit, 3, 7);
      mass(-.17, -1.0, .26, .16, shade, crown, lit, 4, 4);
      mass(.17, -1.02, .23, .14, shade, crown, lit, 5, 4);
      mass(-.03, -1.1, .17, .1, crown, lit, lit, 6, 4);
    } else {
      mass(0, -.84, .42, .15, shade, crown, lit, 3, 7);
      mass(-.2, -.93, .27, .11, shade, crown, lit, 4, 4);
      mass(.19, -.95, .25, .1, shade, crown, lit, 5, 4);
      mass(-.02, -1.01, .18, .08, crown, lit, lit, 6, 4);
    }
    // Blossoms speckle the crown.
    final flowers = <Offset>[];
    for (var i = 0; i < 16; i++) {
      final a = Sketch.hash(i + 900) * math.pi;
      final r = .12 + .28 * Sketch.hash(i + 920);
      flowers.add(Offset(x(-math.cos(a) * r), y((dome ? -.98 : -.9) - math.sin(a) * r * (dome ? .55 : .3))));
    }
    c.drawPoints(
      PointMode.points,
      flowers,
      Paint()
        ..strokeWidth = math.max(1.1, s * .022)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(_hazed(fleck, .25), bloom == 0 ? .5 : .85),
    );
  }

  /// A buttressed giant whose crown reaches over the canopy. [side] is the
  /// direction of the bridge landing (1 to the right, -1 to the left): a
  /// sturdy limb holds the landing at bridge-end height.
  static void _giant(Canvas c, Offset base, double s, {double side = 1}) {
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy + v * s;
    const barkLit = Color(0xffa08c6a),
        bark = Color(0xff77684f),
        barkShade = Color(0xff54493a),
        barkDeep = Color(0xff3a3229);
    const moss = Color(0xff5c9650), mossLit = Color(0xff8ebd68);
    const leafDeep = Color(0xff347453),
        leafShade = Color(0xff3f8760),
        leaf = Color(0xff55a56f),
        leafLit = Color(0xff8ac98d);

    // Trunk: a slightly wandering column with a flared foot.
    double cx(double v) => .012 * math.sin(v * 3.4 + 1.2);
    double hw(double v) =>
        .082 +
        .012 * math.sin(v * 6.3 + .7) +
        .17 * math.pow(math.max(0.0, (v + .3) / .3), 2.0);
    final trunk = Path();
    const steps = 16;
    for (var i = 0; i <= steps; i++) {
      final v = -1.0 + 1.04 * i / steps;
      final px = x(cx(v) - hw(v)), py = y(v);
      if (i == 0) {
        trunk.moveTo(px, py);
      } else {
        trunk.lineTo(px, py);
      }
    }
    for (var i = steps; i >= 0; i--) {
      final v = -1.0 + 1.04 * i / steps;
      trunk.lineTo(x(cx(v) + hw(v)), y(v));
    }
    trunk.close();
    // Limbs go in behind the trunk so their roots vanish into it. A sturdy
    // bough holds the bridge landing at bridge-end height.
    Offset sp(double u, double v) => Offset(x(side * u), y(v));
    _canopyLimb(c, sp(.03, -.4), sp(.27, -.64), s * .024, s * .015, s * -.02, bark, barkShade, barkLit);
    _canopyLimb(c, sp(0, -.62), sp(.42, -.7), s * .066, s * .022, s * .04, bark, barkShade, barkLit, moss: true);
    _canopyLimb(c, sp(0, -.64), sp(-.36, -.72), s * .048, s * .018, s * -.03, bark, barkShade, barkLit, moss: true);
    _canopyLimb(c, sp(0, -.82), sp(-.42, -1.04), s * .048, s * .02, s * .06, bark, barkShade, barkLit);
    _canopyLimb(c, sp(0, -.82), sp(.44, -1.03), s * .048, s * .02, s * .06, bark, barkShade, barkLit);
    c.drawPath(trunk, Paint()..color = bark);
    c.save();
    c.clipPath(trunk);
    c.drawRect(
      Rect.fromLTRB(x(-.5), y(-1.1), x(.5), y(.1)),
      Paint()
        ..shader = Gradient.linear(
          Offset(x(-.1), 0),
          Offset(x(.1), 0),
          [barkLit, Sketch.mix(barkLit, bark, .5), bark, barkShade],
          const [0, .28, .55, .95],
        ),
    );
    // Bark plates: broken furrows running with the trunk.
    final furrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .011
      ..color = Sketch.fade(barkDeep, .38);
    final ridgeHi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .006
      ..color = Sketch.fade(barkLit, .32);
    for (var i = 0; i < 12; i++) {
      final u = -.88 + 1.76 * (i + .6 * Sketch.hash(i + 5)) / 12;
      final v0 = -.98 + .55 * Sketch.hash(i + 20);
      final len = .3 + .5 * Sketch.hash(i + 40);
      final path = Path(), path2 = Path();
      for (var k = 0; k <= 5; k++) {
        final v = math.min(v0 + len * k / 5, -.01);
        final wob = .006 * math.sin(v * 17 + i * 2.1);
        final px = x(cx(v) + u * hw(v) + wob), py = y(v);
        if (k == 0) {
          path.moveTo(px, py);
          path2.moveTo(px - s * .008, py);
        } else {
          path.lineTo(px, py);
          path2.lineTo(px - s * .008, py);
        }
      }
      c.drawPath(path, furrow);
      if (u < .2) c.drawPath(path2, ridgeHi);
    }
    // The crown shades the upper trunk.
    c.drawRect(
      Rect.fromLTRB(x(-.5), y(-1.1), x(.5), y(-.76)),
      Paint()
        ..shader = Gradient.linear(Offset(0, y(-1.0)), Offset(0, y(-.76)), [Sketch.fade(leafDeep, .6), Sketch.fade(leafDeep, 0)]),
    );
    // Contact shade where the trunk meets the canopy below.
    c.drawRect(
      Rect.fromLTRB(x(-.5), y(-.06), x(.5), y(.1)),
      Paint()..color = Sketch.fade(barkDeep, .35),
    );
    c.restore();

    // Buttress fins: sails of wood swept out to the roots.
    void fin(double xt, double yt, double xo, double xi, Color color) {
      c.drawPath(
        Path()
          ..moveTo(x(xt), y(yt))
          ..quadraticBezierTo(x(xt + (xo - xt) * .12), y(-.03), x(xo), y(.05))
          ..lineTo(x(xi), y(.05))
          ..quadraticBezierTo(x(xt), y(yt * .35), x(xt), y(yt))
          ..close(),
        Paint()..color = color,
      );
      c.drawPath(
        Path()
          ..moveTo(x(xt), y(yt))
          ..quadraticBezierTo(x(xt + (xo - xt) * .12), y(-.03), x(xo), y(.05)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .008
          ..color = Sketch.fade(barkDeep, .4),
      );
    }

    fin(-.075, -.5, -.4, -.12, barkLit);
    fin(.075, -.44, .36, .11, barkShade);
    fin(-.03, -.34, -.16, .02, bark);
    fin(.02, -.3, .17, -.02, Sketch.mix(bark, barkShade, .5));

    // A strangler vine spirals up the trunk.
    final vine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .016
      ..color = const Color(0xff3f5a34);
    final vineLit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .006
      ..color = const Color(0xff7aa55a);
    final vinePath = Path()
      ..moveTo(x(-.22), y(.03))
      ..cubicTo(x(-.02), y(-.12), x(-.08), y(-.3), x(.04), y(-.46))
      ..cubicTo(x(.14), y(-.6), x(-.06), y(-.72), x(.0), y(-.92));
    c.drawPath(vinePath, vine);
    c.drawPath(vinePath.shift(Offset(-s * .004, 0)), vineLit);
    final vineLeaf = Paint()..color = leaf;
    for (final (lx, ly, a) in const [(-.02, -.2, -.6), (.045, -.47, .5), (.07, -.6, -.4), (-.045, -.7, .7), (.02, -.82, -.5)]) {
      c.save();
      c.translate(x(lx), y(ly));
      c.rotate(a);
      c.drawOval(Rect.fromCenter(center: Offset(s * .022, 0), width: s * .05, height: s * .022), vineLeaf);
      c.restore();
    }
    // Moss gathers in the shade and where the fins meet the ground.
    final mossPaint = Paint()..color = moss;
    final mossHi = Paint()..color = mossLit;
    for (final (mx, my, r) in const [
      (-.3, -.01, .034),
      (-.24, -.04, .03),
      (-.18, -.02, .026),
      (.22, -.02, .03),
      (.29, -.0, .034),
      (.16, -.06, .024),
      (.078, -.3, .018),
    ]) {
      // Each patch is a small cluster, longer than wide, not a single dot.
      for (final (ox, oy, q) in const [(0.0, 0.0, 1.0), (.6, .7, .7), (-.5, -.8, .65)]) {
        final at = Offset(x(mx + ox * r), y(my + oy * r));
        c.drawOval(Rect.fromCenter(center: at, width: s * r * 1.8 * q, height: s * r * 2.6 * q), mossPaint);
        c.drawOval(Rect.fromCenter(center: at.translate(-s * r * .3 * q, -s * r * .5 * q), width: s * r * .8 * q, height: s * r * 1.2 * q), mossHi);
      }
    }
    // Lichen freckles on the sunlit face.
    final lichen = Paint()..color = const Color(0x55d8dcc0);
    for (final (lx, ly, r) in const [(-.06, -.62, .02), (-.05, -.28, .026), (-.075, -.82, .016), (-.08, -.4, .014)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x(lx), y(ly)), width: s * r * 2, height: s * r * 1.4), lichen);
    }

    _canopyMass(c, Offset(x(side * .43), y(-.735)), s * .09, s * .055, leafShade, leaf, leafLit, seed: 31, lobes: 3);
    _canopyMass(c, Offset(x(side * -.38), y(-.74)), s * .085, s * .05, leafShade, leaf, leafLit, seed: 32, lobes: 3);

    void mass(double dx, double dy, double a, double b, Color sh, Color mi, Color li, int seed, [int lobes = 8]) =>
        _canopyMass(c, Offset(x(dx * .9), y(dy)), a * s * .88, b * s * .88, sh, mi, li, seed: seed, lobes: lobes);
    // Back layer, in shade.
    mass(-.46, -1.0, .3, .17, leafDeep, leafShade, leaf, 11);
    mass(.48, -1.02, .29, .16, leafDeep, leafShade, leaf, 12);
    mass(0, -1.14, .44, .2, leafDeep, leafShade, leaf, 13, 10);
    mass(-.54, -.9, .2, .11, leafDeep, leafShade, leaf, 14, 6);
    mass(.56, -.92, .18, .1, leafDeep, leafShade, leaf, 15, 6);

    // Lianas and epiphytes hang under the crown.
    final liana = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.9, s * .008)
      ..color = Sketch.fade(leafDeep, .85);
    final lianaLeaf = Paint()..color = leafShade;
    for (final (lx, ly, len, sway) in const [
      (-.5, -.92, .42, .3),
      (-.4, -.94, .3, -.3),
      (-.26, -.95, .5, .2),
      (-.1, -.98, .22, -.3),
      (.16, -.98, .36, .3),
      (.34, -.97, .5, -.25),
      (.5, -.94, .34, .3),
    ]) {
      _canopyLiana(c, Offset(x(lx), y(ly)), len * s, sway, liana, lianaLeaf, s * .02);
    }
    for (final (bx, by, r, hue) in const [
      (.26, -.715, .06, 0),
      (.14, -.705, .045, 1),
      (-.22, -.715, .05, 1),
      (-.36, -1.03, .055, 0),
      (.34, -1.0, .05, 1),
    ]) {
      final at = sp(bx, by);
      _canopyBromeliad(c, at, s * r, hue == 0 ? const Color(0xff3f8a5a) : const Color(0xff53996a), leafLit, hue == 0 ? const Color(0xffb85b78) : const Color(0xffc9738a));
    }
    // Middle and front layers catch the sun.
    mass(-.3, -1.1, .3, .17, leafShade, leaf, leafLit, 21);
    mass(.3, -1.12, .28, .16, leafShade, leaf, leafLit, 22);
    mass(-.5, -.98, .16, .1, leafShade, leaf, leafLit, 23, 6);
    mass(.5, -1.0, .15, .09, leafShade, leaf, leafLit, 24, 6);
    mass(-.08, -1.26, .32, .16, leaf, leafLit, leafLit, 25, 9);
    mass(.22, -1.24, .22, .13, leaf, leafLit, leafLit, 26, 7);
    mass(-.34, -1.2, .2, .12, leaf, leafLit, leafLit, 27, 6);
    // Blossoms and sparks of light on the crown.
    final spark = <Offset>[];
    for (var i = 0; i < 26; i++) {
      final a = Sketch.hash(i + 960) * math.pi;
      final r = .1 + .5 * Sketch.hash(i + 990);
      spark.add(Offset(x(-math.cos(a) * r), y(-1.12 - math.sin(a) * r * .3)));
    }
    c.drawPoints(
      PointMode.points,
      spark,
      Paint()
        ..strokeWidth = math.max(1.3, s * .016)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x99f4f8e0),
    );
  }

  /// A palm ([kind] 0) or a candelabra cecropia ([kind] 1) poking above the
  /// canopy, for variety of silhouette. [haze] tints it toward the mist.
  static void _canopyEmergent(Canvas c, Offset base, double s, int kind, {double haze = 0}) {
    Color hz(Color color) => haze == 0 ? color : _hazed(color, haze);
    if (kind == 0) {
      Sketch.palm(
        c,
        base,
        s * 1.3,
        lean: .05,
        trunk: hz(const Color(0xff85775d)),
        trunkShade: hz(const Color(0xff5f5443)),
        frond: hz(const Color(0xff2f7a52)),
        frondLit: hz(const Color(0xff63b06f)),
        droop: .5,
      );
      return;
    }
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy + v * s;
    final bark = hz(const Color(0xff9a9880)), barkLit = hz(const Color(0xffb7b49a)), barkShade = hz(const Color(0xff6e7160));
    final leaf = hz(const Color(0xff3f8f60)), leafLit = hz(const Color(0xff86c58e)), leafDeep = hz(const Color(0xff2b6a4c));
    // A slim, ringed trunk that forks into a candelabra.
    final tips = const [(-.3, -1.02), (-.1, -1.18), (.14, -1.14), (.32, -.98)];
    for (final (tx, ty) in tips) {
      _canopyLimb(c, Offset(x(0), y(-.66)), Offset(x(tx), y(ty + .08)), s * .022, s * .012, s * .02, bark, barkShade, barkLit);
    }
    final trunk = Path()
      ..moveTo(x(-.05), y(.03))
      ..quadraticBezierTo(x(-.028), y(-.3), x(-.022), y(-.68))
      ..lineTo(x(.022), y(-.68))
      ..quadraticBezierTo(x(.03), y(-.3), x(.05), y(.03))
      ..close();
    c.drawPath(trunk, Paint()..color = bark);
    c.save();
    c.clipPath(trunk);
    c.drawRect(Rect.fromLTRB(x(-.1), y(-.7), x(-.004), y(.05)), Paint()..color = barkLit);
    c.drawRect(Rect.fromLTRB(x(.012), y(-.7), x(.1), y(.05)), Paint()..color = barkShade);
    final rings = Path();
    for (var k = 0; k < 9; k++) {
      final v = -.06 - k * .07;
      rings
        ..moveTo(x(-.06), y(v))
        ..lineTo(x(.06), y(v + .008));
    }
    c.drawPath(rings, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.7, s * .01)..color = Sketch.fade(barkShade, .6));
    c.restore();
    // Each branch ends in a rosette of big, deeply cut hand-shaped leaves.
    for (final (i, (tx, ty)) in tips.indexed) {
      _canopyBromeliad(c, Offset(x(tx), y(ty + .06)), s * (.26 - .02 * (i % 2)), leafDeep, i.isEven ? leaf : leafLit, leaf);
      _canopyBromeliad(c, Offset(x(tx + .03), y(ty + .1)), s * .2, leaf, leafLit, leafLit);
    }
  }

  /// A cloud-like leaf mass, the building block of every crown: three rows of
  /// scalloped leaf clumps, dark underlayer at the bottom to a sunlit crescent
  /// on every top clump. [a] and [b] are the half width and half height.
  static void _canopyMass(
    Canvas c,
    Offset o,
    double a,
    double b,
    Color shade,
    Color mid,
    Color lit, {
    int seed = 0,
    int lobes = 7,
  }) {
    final p = Paint();
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final body = Sketch.mix(shade, mid, .62);
    // A flat shadow the clumps sit on.
    c.drawOval(
      Rect.fromCenter(center: o + Offset(a * .05, b * .34), width: a * 1.9, height: b * 1.0),
      p..color = shade,
    );
    for (var row = 0; row < 3; row++) {
      final count = lobes + row * 2 - 1;
      final ry = b * (.34 - row * .44);
      final span = a * (.92 - row * .1);
      for (var i = 0; i < count; i++) {
        final j = Sketch.hash(seed * 61 + row * 17 + i * 3 + 1);
        final k = Sketch.hash(seed * 61 + row * 17 + i * 3 + 2);
        final ux = 2 * (i + .5 + (j - .5) * .6) / count - 1;
        final r = b * (.5 - row * .06) * (.72 + .55 * k) * (1 - .22 * ux * ux);
        final at = Offset(o.dx + ux * span, o.dy + ry + b * .34 * ux * ux + (k - .5) * b * .16);
        c.drawCircle(at, r, p..color = row == 0 ? shade : (row == 1 ? body : mid));
        if (row > 0) {
          c.drawArc(
            Rect.fromCircle(center: at, radius: r * .82),
            math.pi * 1.02,
            math.pi * .62,
            false,
            arc
              ..strokeWidth = r * .36
              ..color = row == 2 ? lit : Sketch.fade(lit, .55),
          );
        }
      }
    }
    final glints = <Offset>[], pits = <Offset>[];
    for (var i = 0; i < lobes + 3; i++) {
      final h1 = Sketch.hash(seed * 53 + i * 3 + 7), h2 = Sketch.hash(seed * 53 + i * 3 + 8);
      glints.add(o + Offset((h1 - .6) * a * 1.4, -b * (.2 + .6 * h2)));
      pits.add(o + Offset((h2 - .4) * a * 1.4, b * (.02 + .35 * h1)));
    }
    c.drawPoints(
      PointMode.points,
      glints,
      Paint()
        ..strokeWidth = math.max(1, b * .11)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(lit, .7),
    );
    c.drawPoints(
      PointMode.points,
      pits,
      Paint()
        ..strokeWidth = math.max(1, b * .11)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(shade, .55),
    );
  }

  /// A tapered, gently bowed limb from [a] to [b]: sunlit on top, shaded
  /// beneath, optionally furred with moss along the upper edge.
  static void _canopyLimb(
    Canvas c,
    Offset a,
    Offset b,
    double wa,
    double wb,
    double bow,
    Color mid,
    Color shade,
    Color lit, {
    bool moss = false,
  }) {
    final d = b - a;
    var n = Offset(-d.dy, d.dx) / d.distance;
    if (n.dy > 0) n = -n;
    final m = Offset.lerp(a, b, .5)! + n * bow;
    final mw = (wa + wb) * .5;
    final path = Path()
      ..moveTo(a.dx + n.dx * wa, a.dy + n.dy * wa)
      ..quadraticBezierTo(m.dx + n.dx * mw, m.dy + n.dy * mw, b.dx + n.dx * wb, b.dy + n.dy * wb)
      ..lineTo(b.dx - n.dx * wb, b.dy - n.dy * wb)
      ..quadraticBezierTo(m.dx - n.dx * mw, m.dy - n.dy * mw, a.dx - n.dx * wa, a.dy - n.dy * wa)
      ..close();
    c.drawPath(path, Paint()..color = mid);
    c.drawCircle(b, wb, Paint()..color = mid);
    c.drawPath(
      Path()
        ..moveTo(a.dx - n.dx * wa, a.dy - n.dy * wa)
        ..quadraticBezierTo(m.dx - n.dx * mw, m.dy - n.dy * mw, b.dx - n.dx * wb, b.dy - n.dy * wb),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, wa * .5)
        ..color = shade,
    );
    c.drawPath(
      Path()
        ..moveTo(a.dx + n.dx * wa * .7, a.dy + n.dy * wa * .7)
        ..quadraticBezierTo(m.dx + n.dx * mw * .7, m.dy + n.dy * mw * .7, b.dx + n.dx * wb * .7, b.dy + n.dy * wb * .7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, wa * .28)
        ..color = Sketch.fade(lit, .8),
    );
    if (moss) {
      final green = Paint()..color = const Color(0xff5a9550);
      final greenLit = Paint()..color = const Color(0xff86b866);
      for (var k = 0; k < 12; k++) {
        final t = .06 + k * .075 + .04 * Sketch.hash(k + 300);
        final wide = wa + (wb - wa) * t;
        final q = Offset.lerp(a, b, t)! + n * (bow * 4 * t * (1 - t) + wide * (.7 + .35 * Sketch.hash(k + 320)));
        final r = wide * (.24 + .2 * Sketch.hash(k + 310));
        c.drawOval(Rect.fromCenter(center: q, width: r * 2.6, height: r * 1.5), green);
        c.drawOval(Rect.fromCenter(center: q + Offset(-r * .3, -r * .35), width: r * 1.3, height: r * .7), greenLit);
      }
    }
  }

  /// A rosette of pointed leaves with a pink heart, perched on a branch.
  static void _canopyBromeliad(Canvas c, Offset p, double r, Color leaf, Color leafLit, Color heart) {
    final paint = Paint();
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * .44;
      final dir = Offset(math.cos(a), math.sin(a));
      final perp = Offset(-dir.dy, dir.dx);
      final len = r * (i == 3 ? 1.05 : .9 - (i % 2) * .12);
      final tip = p + dir * len;
      c.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(p.dx + dir.dx * len * .5 + perp.dx * r * .2, p.dy + dir.dy * len * .5 + perp.dy * r * .2, tip.dx, tip.dy)
          ..quadraticBezierTo(p.dx + dir.dx * len * .5 - perp.dx * r * .12, p.dy + dir.dy * len * .5 - perp.dy * r * .12, p.dx, p.dy)
          ..close(),
        paint..color = i.isEven ? leaf : leafLit,
      );
    }
    c.drawCircle(p + Offset(0, -r * .1), r * .2, paint..color = heart);
  }

  /// A liana hanging from [from], swaying by [sway], with paired leaves.
  static void _canopyLiana(Canvas c, Offset from, double len, double sway, Paint line, Paint leaf, double leafSize) {
    final p1 = from + Offset(sway * len * .5, len * .35);
    final p2 = from + Offset(-sway * len * .35, len * .7);
    final p3 = from + Offset(sway * len * .15, len);
    c.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy),
      line,
    );
    for (var k = 1; k <= 4; k++) {
      final t = k / 4.3;
      final u = 1 - t;
      final q = from * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t);
      final side = k.isEven ? 1.0 : -1.0;
      c.drawOval(
        Rect.fromCenter(center: q + Offset(side * leafSize * .7, leafSize * .25), width: leafSize * 1.5, height: leafSize * .7),
        leaf,
      );
    }
  }

  static final _canopyPictures = <(Depth, double, double), Picture>{};

  /// The leaf texture is static, so it is recorded once per band and
  /// viewport and replayed; only a crossing fades it, through a layer.
  void _canopyCrowns(Canvas c, Depth d, SceneFrame f, double presence) {
    // Fade early so the leaf lobes are gone before the new ridge settles.
    presence *= presence;
    if (presence <= .004) return;
    final key = (d, f.w, f.h);
    var picture = _canopyPictures[key];
    if (picture == null) {
      if (_canopyPictures.length >= 8) {
        for (final p in _canopyPictures.values) {
          p.dispose();
        }
        _canopyPictures.clear();
      }
      final recorder = PictureRecorder();
      _canopyPaint(Canvas(recorder), d, f.w, f.h);
      picture = _canopyPictures[key] = recorder.endRecording();
    }
    if (presence >= .996) {
      c.drawPicture(picture);
      return;
    }
    final (from, to) = _canopySpan(d, f.w, f.h);
    c.saveLayer(
      Rect.fromLTRB(from - f.h * .1, f.h * .45, to + f.h * .1, d == Depth.far ? f.h * .8 : f.h),
      Paint()..color = Color.fromRGBO(0, 0, 0, presence),
    );
    c.drawPicture(picture);
    c.restore();
  }

  /// The x range the canopy texture covers: a timed band drifts left, so it
  /// runs well past the right edge; a repeating band covers one period plus
  /// a spill.
  (double, double) _canopySpan(Depth d, double w, double h) =>
      d == Depth.low ? (-h * .2, period(d) * h + h * .2) : (-h * .4, w + h * .9);

  void _canopyPaint(Canvas c, Depth d, double w, double h) {
    final low = d == Depth.low, far = d == Depth.far;
    final (from, to) = _canopySpan(d, w, h);
    // The far ridge wears the mid palette dissolved into the distance haze.
    Color hz(Color x) => far ? Sketch.mix(x, _haze, .5) : x;
    final deep = low ? const Color(0xff24603f) : hz(const Color(0xff4d8c6a));
    final shade = low ? const Color(0xff36844f) : hz(const Color(0xff67a684));
    final mid = low ? const Color(0xff479a62) : hz(const Color(0xff7cba8f));
    final lit = low ? const Color(0xff6fb673) : hz(const Color(0xff9acf9a));
    final glint = low ? const Color(0xffa8dc90) : hz(const Color(0xffd0edba));
    final kf = far ? .8 : 1.0;
    final paint = Paint();
    final period = this.period(d) * h;

    // Whole-crown shading: shadowed clefts between the big humps, a sunlit
    // dome on the upper left of each and a dark belly under it.
    final wave = (low ? .3 : .23) * h;
    for (var k = (from / wave).floor() - 1; !far && k * wave < to; k++) {
      final x = k * wave;
      final y = ridge(d, x / h, 0) * h;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + h * (low ? .06 : .045)), width: wave * .3, height: h * (low ? .13 : .1)),
        paint..color = Sketch.fade(deep, .26),
      );
      final cx = x + wave * .42, cy = ridge(d, cx / h, 0) * h;
      c.drawOval(
        Rect.fromCenter(center: Offset(cx - wave * .06, cy + h * .028), width: wave * .62, height: h * (low ? .06 : .045)),
        paint..color = Sketch.fade(lit, .3),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(cx + wave * .08, cy + h * (low ? .11 : .08)), width: wave * .9, height: h * (low ? .07 : .05)),
        paint..color = Sketch.fade(deep, .2),
      );
    }

    // Two rows of leaf lobes make the broccoli edge: a darker back row that
    // fills the clefts, then the crowns with a sunlit crescent each. A few
    // lean yellow or blue-green like different species.
    final warm = low ? const Color(0xff86a844) : hz(const Color(0xffa3c47c));
    final cool = low ? const Color(0xff2c8a70) : hz(const Color(0xff6fb59c));
    for (final (index, (drop, radius, spread)) in [
      (h * (low ? .026 : .018) * kf, low ? .028 : .022, 1.35),
      (0.0, low ? .022 : .0165, 1.0),
    ].indexed) {
      final rb = h * radius * kf;
      final gap0 = rb * spread;
      final cycle = low ? (period / gap0).round() : 0;
      final gap = low ? period / cycle : gap0;
      for (var i = (from / gap).floor(); i * gap < to; i++) {
        final n = (cycle == 0 ? i : i % cycle) * 7 + index * 1009;
        final x = (i + (Sketch.hash(n + 3) - .5) * .7) * gap;
        final k = Sketch.hash(n + 4);
        final v = Sketch.hash(n + 6);
        final r = rb * (.6 + .95 * k * k);
        final poke = h * (.001 + .014 * Sketch.hash(n + 5));
        final y = ridge(d, x / h, 0) * h + r - poke + drop;
        final back = index == 0;
        Color tint(Color base) => back ? base : (v < .25 ? Sketch.mix(base, warm, .16) : (v > .82 ? Sketch.mix(base, cool, .18) : base));
        c.drawCircle(Offset(x + r * .06, y + r * .1), r, paint..color = tint(Sketch.mix(deep, shade, back ? .3 : .65)));
        c.drawCircle(Offset(x, y), r, paint..color = tint(back ? Sketch.mix(shade, lit, .1) : lit));
        c.drawCircle(Offset(x + r * .13, y + r * .2), r * .9, paint..color = tint(back ? shade : mid));
      }
    }

    // Leaf scales: rows of little arcs give the foliage its grain. Light
    // ones catch the sun near the tops, dark ones sit deeper in.
    final light = Path(), dark = Path(), petals = <Offset>[];
    final scale = h * (low ? .0095 : .0075) * kf;
    for (var row = 0; row < (far ? 2 : 5); row++) {
      final step = scale * 2.3;
      final count = low ? (period / step).round() : ((to - from) / step).round();
      for (var j = 0; j < count; j++) {
        final n = (row * 4001 + j) * 5;
        final x = low
            ? (j + .5 * (row % 2) + (Sketch.hash(n + 1) - .5) * .5) / count * period
            : from + (j + .5 * (row % 2) + (Sketch.hash(n + 1) - .5) * .5) * step;
        if (Sketch.hash(n + 6) < .22) continue;
        final y = ridge(d, x / h, 0) * h + h * (.024 + row * (low ? .026 : .019) + (Sketch.hash(n + 2) - .5) * (row < 2 ? .012 : .03));
        final r = scale * (.7 + .6 * Sketch.hash(n + 3));
        for (final shift in low ? const [-1, 0, 1] : const [0]) {
          final xs = x + shift * period;
          if (xs < from || xs > to) continue;
          (row < 2 ? light : dark).addArc(Rect.fromCircle(center: Offset(xs, y), radius: r), math.pi * 1.08, math.pi * .84);
          if (row == 0 && Sketch.hash(n + 4) < .12) petals.add(Offset(xs, y - r * 1.4));
        }
      }
    }
    c.drawPath(
      light,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * .0042
        ..color = Sketch.fade(glint, .42),
    );
    c.drawPath(
      dark,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * .0042
        ..color = Sketch.fade(deep, .24),
    );
    c.drawPoints(
      PointMode.points,
      petals,
      Paint()
        ..strokeWidth = h * .006
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(low ? const Color(0xffe6b8d2) : hz(const Color(0xfff0d6e2)), .8),
    );
  }

  // ---------------------------------------------------------------------------
  // Rope bridge. Geometry in viewport heights: the sag of the deck, the height
  // of the hand ropes above it, the depth of the deck (the far rope sits a step
  // higher on screen because we look down on the bridge a little) and how far
  // in from each trunk the posts stand.

  static const _bridgeSag = .078,
      _bridgeRail = .052,
      _bridgeDepth = .022,
      _bridgePost = .034;
  static const _bridgeShade = Color(0xff4b3826),
      _bridgeBase = Color(0xff7c5d3c),
      _bridgeLit = Color(0xffcaa878),
      _bridgeFarShade = Color(0xff3b2e21),
      _bridgeFarBase = Color(0xff5d4a36),
      _bridgeFarLit = Color(0xff8c7455);
  static const _bridgeLeafDark = Color(0xff3f7f48),
      _bridgeLeafMid = Color(0xff5fa657),
      _bridgeLeafLit = Color(0xff92cc6c);

  /// The near walking rope at fraction [t] of the span from [a] to [b].
  static Offset _bridgeAt(Offset a, Offset b, double h, double t) {
    final p = Offset.lerp(a, b, t)!;
    return Offset(
      p.dx,
      p.dy + h * (_bridgeSag * 4 * t * (1 - t) + _bridgeDepth / 2),
    );
  }

  /// A polyline along the deck from [t0] to [t1], shifted down by [dy].
  static Path _bridgeLine(
    Offset a,
    Offset b,
    double h,
    double t0,
    double t1,
    double dy,
  ) {
    final n = math.max(6, ((t1 - t0) * 44).ceil());
    final path = Path();
    for (var i = 0; i <= n; i++) {
      final p = _bridgeAt(a, b, h, t0 + (t1 - t0) * i / n);
      if (i == 0) {
        path.moveTo(p.dx, p.dy + dy);
      } else {
        path.lineTo(p.dx, p.dy + dy);
      }
    }
    return path;
  }

  /// A laid rope: a shaded body, a lit strand along the top, twist marks.
  static void _bridgeRope(
    Canvas c,
    Path rope,
    double w, {
    Color shade = _bridgeShade,
    Color base = _bridgeBase,
    Color lit = _bridgeLit,
    bool twist = true,
  }) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(rope.shift(Offset(0, w * .16)), p..strokeWidth = w..color = shade);
    c.drawPath(rope, p..strokeWidth = w * .82..color = base);
    if (twist) {
      final ticks = Path();
      for (final m in rope.computeMetrics()) {
        for (var d = w * .9; d < m.length; d += w * 1.05) {
          final t = m.getTangentForOffset(d);
          if (t == null) continue;
          final v = t.vector, n = Offset(-v.dy, v.dx);
          final dir = v * .5 + n * .86;
          final q = t.position;
          ticks
            ..moveTo(q.dx - dir.dx * w * .34, q.dy - dir.dy * w * .34)
            ..lineTo(q.dx + dir.dx * w * .34, q.dy + dir.dy * w * .34);
        }
      }
      c.drawPath(
        ticks,
        p
          ..strokeWidth = math.max(.5, w * .16)
          ..strokeCap = StrokeCap.butt
          ..color = Sketch.fade(shade, .55),
      );
    }
    c.drawPath(
      rope.shift(Offset(0, -w * .2)),
      p
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * .26
        ..color = lit,
    );
  }

  /// Diamond netting between the deck and the hand rope over [x0]..[x1]. Its
  /// strands stand on a fixed grid so any window of it lines up with the rest.
  static Path _bridgeNet(
    Offset a,
    Offset b,
    double h,
    double x0,
    double x1,
    double lift,
  ) {
    final span = b.dx - a.dx, rail = h * _bridgeRail;
    final sp = h * .0185, dx = rail * .82;
    double y(double x) => _bridgeAt(a, b, h, (x - a.dx) / span).dy + lift;
    final net = Path();
    for (
      var x = a.dx + ((x0 - a.dx) / sp).ceil() * sp;
      x + dx <= x1;
      x += sp
    ) {
      net
        ..moveTo(x, y(x))
        ..lineTo(x + dx, y(x + dx) - rail)
        ..moveTo(x, y(x) - rail)
        ..lineTo(x + dx, y(x + dx));
    }
    return net;
  }

  /// A pointed leaf lying along [ang] with its middle at [at].
  static void _bridgeLeaf(
    Path path,
    Offset at,
    double ang,
    double len,
    double wid,
  ) {
    final d = Offset(math.cos(ang), math.sin(ang)) * (len / 2);
    final n = Offset(-d.dy, d.dx) * (wid / len * 2);
    path
      ..moveTo(at.dx - d.dx, at.dy - d.dy)
      ..quadraticBezierTo(at.dx + n.dx, at.dy + n.dy, at.dx + d.dx, at.dy + d.dy)
      ..quadraticBezierTo(at.dx - n.dx, at.dy - n.dy, at.dx - d.dx, at.dy - d.dy);
  }

  static Offset _bridgeQuad(Offset p0, Offset c, Offset p1, double t) =>
      p0 * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + p1 * (t * t);

  /// The rope bridge between the giants: a planked deck lashed to two walking
  /// ropes, diamond netting under the hand ropes, knotted hangers, timber
  /// bearers and posts at each trunk, moss and vines, a sloth and small birds.
  /// The lianas below and the monkey crossing are animated in [_bridgeLive].
  static void _bridge(Canvas c, Offset a, Offset b, double h) {
    final span = b.dx - a.dx;
    final rail = h * _bridgeRail, off = h * _bridgeDepth;
    final hair = math.max(.6, h * .0016);
    final post = h * _bridgePost;
    final xa = a.dx + post, xb = b.dx - post;
    Offset nearAt(double x) => _bridgeAt(a, b, h, (x - a.dx) / span);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // The far side of the bridge sits back in shade.
    c.drawPath(
      _bridgeNet(a, b, h, xa, xb, -off),
      line
        ..strokeWidth = hair
        ..color = const Color(0x334d3d2b),
    );
    const hangers = 13;
    final gap = (xb - xa) / hangers;
    for (var k = 0; k < hangers; k++) {
      final x = xa + gap * (k + .5);
      final y = nearAt(x).dy - off;
      c.drawLine(
        Offset(x, y),
        Offset(x, y - rail),
        line
          ..strokeWidth = h * .0026
          ..color = _bridgeFarBase,
      );
    }
    for (final dy in [-off, -off - rail]) {
      final hand = dy < -off;
      _bridgeRope(
        c,
        hand
            ? _bridgeLine(a, b, h, post / span, 1 - post / span, dy)
            : _bridgeLine(a, b, h, 0, 1, dy),
        h * .0036,
        shade: _bridgeFarShade,
        base: _bridgeFarBase,
        lit: _bridgeFarLit,
        twist: false,
      );
    }
    _bridgeEnd(c, a, b, 1, h, far: true);
    _bridgeEnd(c, a, b, -1, h, far: true);

    // The deck: a soft shadow, then plank by plank.
    c.drawPath(
      _bridgeLine(a, b, h, 0, 1, h * .012),
      line
        ..strokeWidth = h * .009
        ..color = const Color(0x2e1d2a1c),
    );
    const tones = [
      Color(0xffb58e5d),
      Color(0xffa5825a),
      Color(0xffc39c68),
      Color(0xff97764e),
      Color(0xffb39872),
      Color(0xff8d7a5e),
    ];
    final n = ((xb - xa) / (h * .0135)).floor();
    final pitch = (xb - xa) / n;
    final edge = Paint();
    final top = Paint();
    final hi = Path(), grain = Path(), sun = Path();
    final moss = Path();
    final fill = Paint();
    for (var i = 0; i < n; i++) {
      // A few planks are gone or snapped off.
      if (i == 31 || i == 54) continue;
      final k = Sketch.hash(i + 900);
      final x0 = xa + i * pitch + pitch * .1 * (Sketch.hash(i + 901) - .5);
      final broken = i == 12 || i == 44;
      final x1 = x0 + pitch * (broken ? .46 : .8 + .06 * Sketch.hash(i + 902));
      final y0 = nearAt(x0).dy + h * .0025, y1 = nearAt(x1).dy + h * .0025;
      final far = off * (1.1 + .12 * Sketch.hash(i + 903));
      final th = h * .0058;
      final tone = tones[(k * tones.length).floor() % tones.length];
      c.drawPath(
        Sketch.poly([x0, y0, x1, y1, x1, y1 + th, x0, y0 + th]),
        edge..color = Sketch.mix(tone, _bridgeShade, .55),
      );
      if (broken) {
        // A snapped plank: jagged where it split.
        c.drawPath(
          Sketch.poly([
            x0, y0, x1, y1, x1 + pitch * .18, y1 - far * .5, //
            x1, y1 - far * .74, x1 + pitch * .1, y1 - far,
            x0, y0 - far,
          ]),
          top..color = tone,
        );
      } else {
        c.drawPath(
          Sketch.poly([x0, y0, x1, y1, x1, y1 - far, x0, y0 - far]),
          top..color = tone,
        );
        hi
          ..moveTo(x0, y0 - far + hair * .5)
          ..lineTo(x1, y1 - far + hair * .5);
      }
      // Sun catches the left edge of each plank; grain runs along it.
      sun
        ..moveTo(x0 + hair * .5, y0 - far * .95)
        ..lineTo(x0 + hair * .5, y0 - h * .001);
      if (k > .3) {
        final gx = x0 + (x1 - x0) * (.3 + .4 * Sketch.hash(i + 905));
        final gy = nearAt(gx).dy + h * .0025;
        grain
          ..moveTo(gx, gy - far * .85)
          ..lineTo(gx + hair * .5, gy - far * .2);
      }
      if (k > .84) {
        moss.addOval(
          Rect.fromCenter(
            center: Offset((x0 + x1) / 2, y0 - far * .35),
            width: pitch * (1.2 + 1.6 * Sketch.hash(i + 904)),
            height: far * .5,
          ),
        );
      }
    }
    c.drawPath(
      hi,
      line
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = hair
        ..color = const Color(0x8fefd9a8),
    );
    c.drawPath(
      sun,
      line
        ..strokeWidth = hair
        ..color = const Color(0x66f4e2b8),
    );
    c.drawPath(
      grain,
      line
        ..strokeWidth = hair
        ..color = const Color(0x40402d1a),
    );
    c.drawPath(moss, fill..color = const Color(0xb35a9648));

    // Near walking rope and diamond netting.
    _bridgeRope(c, _bridgeLine(a, b, h, 0, 1, 0), h * .0058);
    c.drawPath(
      _bridgeNet(a, b, h, xa, xb, 0),
      line
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, h * .0017)
        ..color = const Color(0x735b4530),
    );
    // Hangers, knotted top and bottom.
    final knots = <Offset>[], knotLit = <Offset>[];
    for (var k = 0; k < hangers; k++) {
      final x = xa + gap * (k + .5);
      final y = nearAt(x).dy;
      c.drawLine(
        Offset(x, y),
        Offset(x, y - rail),
        line
          ..strokeWidth = h * .0034
          ..color = _bridgeShade,
      );
      c.drawLine(
        Offset(x - h * .0006, y),
        Offset(x - h * .0006, y - rail),
        line
          ..strokeWidth = h * .0016
          ..color = _bridgeBase,
      );
      knots
        ..add(Offset(x, y - rail))
        ..add(Offset(x, y - h * .002));
      knotLit
        ..add(Offset(x - h * .0011, y - rail - h * .0012))
        ..add(Offset(x - h * .0011, y - h * .0032));
    }
    c.drawPoints(
      PointMode.points,
      knots,
      line
        ..strokeWidth = h * .0086
        ..color = _bridgeShade,
    );
    c.drawPoints(
      PointMode.points,
      knotLit,
      line
        ..strokeWidth = h * .0046
        ..color = _bridgeBase,
    );
    _bridgeRope(c, _bridgeLine(a, b, h, post / span, 1 - post / span, -rail), h * .0052);
    _bridgeEnd(c, a, b, 1, h, far: false);
    _bridgeEnd(c, a, b, -1, h, far: false);
    _bridgeGrowth(c, a, b, h);
    _bridgeSloth(c, _bridgeAt(a, b, h, .64) + Offset(0, h * .003), h * .05);
    _bridgeBird(c, _bridgeAt(a, b, h, .275) - Offset(0, rail + h * .002), h * .02, 0, -1);
    _bridgeBird(c, _bridgeAt(a, b, h, .82) - Offset(0, rail + h * .002), h * .019, 1, 1);
  }

  /// Timber, posts and lashings where the bridge meets a trunk. [dir] is +1
  /// at the left end [a], -1 at the right end [b]. The hand ropes end on the
  /// posts; a backstay runs from each post top down to a collar on the trunk.
  static void _bridgeEnd(
    Canvas c,
    Offset a,
    Offset b,
    double dir,
    double h, {
    required bool far,
  }) {
    final rail = h * _bridgeRail, off = h * _bridgeDepth;
    final end = dir > 0 ? a : b;
    final span = (b.dx - a.dx).abs();
    final tp = h * _bridgePost / span;
    final foot =
        _bridgeAt(a, b, h, dir > 0 ? tp : 1 - tp) + Offset(0, far ? -off : 0);
    final w = far ? h * .0078 : h * .0092;
    final base = far ? _bridgeFarBase : _bridgeBase;
    final lit = far ? _bridgeFarLit : _bridgeLit;
    final shade = far ? _bridgeFarShade : _bridgeShade;
    final fill = Paint();
    final stay = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTRB(
      foot.dx - w / 2,
      foot.dy - rail - h * .012,
      foot.dx + w / 2,
      foot.dy + h * .003,
    );
    c.drawRect(rect, fill..color = base);
    c.drawRect(
      Rect.fromLTRB(rect.left, rect.top, rect.left + w * .38, rect.bottom),
      fill..color = lit,
    );
    c.drawRect(
      Rect.fromLTRB(rect.right - w * .3, rect.top, rect.right, rect.bottom),
      fill..color = shade,
    );
    // Backstay to the trunk, then the lashing bands and the carved cap.
    final from = Offset(foot.dx, rect.top + h * .004);
    final anchor = Offset(end.dx, end.dy + (far ? -off / 2 : off / 2));
    c.drawLine(
      from,
      anchor,
      stay
        ..strokeWidth = w * .5
        ..color = shade,
    );
    c.drawLine(
      from + Offset(-h * .0007, -h * .0007),
      anchor + Offset(-h * .0007, -h * .0007),
      stay
        ..strokeWidth = w * .2
        ..color = lit,
    );
    for (var k = 0; k < 2; k++) {
      final y = foot.dy - rail - h * .003 + k * h * .0046;
      c.drawLine(
        Offset(rect.left - h * .0008, y),
        Offset(rect.right + h * .0008, y),
        stay
          ..strokeWidth = h * .0036
          ..color = shade,
      );
      c.drawLine(
        Offset(rect.left - h * .0004, y - h * .0007),
        Offset(rect.right, y - h * .0007),
        stay
          ..strokeWidth = h * .0016
          ..color = lit,
      );
    }
    c.drawCircle(Offset(foot.dx, rect.top), w * .62, fill..color = base);
    c.drawCircle(
      Offset(foot.dx - w * .16, rect.top - w * .16),
      w * .3,
      fill..color = lit,
    );
    if (far) return;

    // A timber bearer under the first planks, and a brace back to the trunk.
    final x0 = end.dx - dir * h * .012, x1 = foot.dx + dir * h * .012;
    double y(double x) => _bridgeAt(a, b, h, (x - a.dx) / (b.dx - a.dx)).dy;
    final th = h * .013;
    c.drawPath(
      Sketch.poly([
        x0, y(x0) + h * .003, x1, y(x1) + h * .003, //
        x1, y(x1) + h * .003 + th, x0, y(x0) + h * .003 + th,
      ]),
      fill..color = _bridgeShade,
    );
    c.drawPath(
      Sketch.poly([
        x0, y(x0) + h * .003, x1, y(x1) + h * .003, //
        x1, y(x1) + h * .003 + th * .4, x0, y(x0) + h * .003 + th * .4,
      ]),
      fill..color = _bridgeBase,
    );
    final brace = Offset(end.dx, end.dy + h * .07);
    final braceTo = Offset(foot.dx - dir * h * .004, foot.dy + h * .014);
    c.drawLine(
      brace,
      braceTo,
      stay
        ..strokeWidth = h * .0078
        ..color = _bridgeShade,
    );
    c.drawLine(
      brace + Offset(-h * .001, -h * .001),
      braceTo + Offset(-h * .001, -h * .001),
      stay
        ..strokeWidth = h * .0034
        ..color = _bridgeBase,
    );
    // A rope collar lashes the walking ropes and the stays to the trunk.
    for (var k = 0; k < 4; k++) {
      final yy = end.dy - off / 2 - h * .003 + k * off / 3;
      final path = Path()
        ..moveTo(end.dx - h * .0205, yy)
        ..quadraticBezierTo(end.dx, yy + h * .005, end.dx + h * .0205, yy);
      c.drawPath(
        path,
        stay
          ..strokeWidth = h * .0048
          ..color = _bridgeShade,
      );
      c.drawPath(
        path.shift(Offset(0, -h * .001)),
        stay
          ..strokeWidth = h * .0022
          ..color = _bridgeLit,
      );
    }
    // Loose rope ends hang from the collar, frayed at the tips.
    for (final (dx, len) in const [(-.008, .034), (.006, .024)]) {
      final p0 = Offset(end.dx + dx * h, end.dy + off / 2 + h * .017);
      final tip = p0 + Offset(dir * h * .003, len * h);
      c.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(p0.dx + dir * h * .006, p0.dy + len * h * .5, tip.dx, tip.dy),
        stay
          ..strokeWidth = h * .0032
          ..color = const Color(0xffa98657),
      );
      for (var k = -1; k <= 1; k++) {
        c.drawLine(
          tip,
          tip + Offset(k * h * .0028, h * .006),
          stay
            ..strokeWidth = math.max(.5, h * .001)
            ..color = _bridgeLit,
        );
      }
    }
  }

  /// Moss on the ropes and timber, vines draped over the near hand rope in
  /// festoons, small leaves and a few blossoms.
  static void _bridgeGrowth(Canvas c, Offset a, Offset b, double h) {
    final span = b.dx - a.dx, rail = h * _bridgeRail;
    Offset hand(double t) => _bridgeAt(a, b, h, t) - Offset(0, rail);
    final vine = Path();
    final dark = Path(), mid = Path(), lit = Path();
    final blooms = <Offset>[], pinks = <Offset>[];
    var seed = 960;
    for (final (ta, tb, dip) in const [
      (.06, .17, .03),
      (.17, .235, .02),
      (.33, .45, .036),
      (.45, .5, .014),
      (.6, .72, .03),
      (.72, .8, .022),
      (.86, .94, .03),
    ]) {
      final p0 = hand(ta), p1 = hand(tb);
      final ctrl = Offset(
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2 + h * dip * 2,
      );
      vine
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, p1.dx, p1.dy);
      final count = math.max(4, ((tb - ta) * span / (h * .0085)).round());
      for (var j = 0; j <= count; j++) {
        final q = _bridgeQuad(p0, ctrl, p1, j / count);
        final k = Sketch.hash(seed++);
        final side = j.isEven ? 1.0 : -1.0;
        final ang = math.pi / 2 + side * (.45 + .9 * k);
        final len = h * (.011 + .007 * Sketch.hash(seed++));
        final along = Offset(math.cos(ang), math.sin(ang));
        final at = q + along * (len * .5);
        _bridgeLeaf(k > .5 ? dark : mid, at, ang, len, len * .5);
        if (k > .35) {
          _bridgeLeaf(
            lit,
            at + Offset(-len * .1, -len * .16),
            ang,
            len * .6,
            len * .28,
          );
        }
        if (k > .93) {
          (Sketch.hash(seed++) > .5 ? blooms : pinks).add(
            q + Offset(side * h * .004, h * .006),
          );
        }
      }
      // Pendulous tendrils hang from the belly of the festoon.
      for (final u in const [.32, .62]) {
        final q = _bridgeQuad(p0, ctrl, p1, u);
        final len = h * (.016 + .02 * Sketch.hash(seed++));
        vine
          ..moveTo(q.dx, q.dy)
          ..quadraticBezierTo(q.dx + h * .004, q.dy + len * .5, q.dx - h * .002, q.dy + len);
        _bridgeLeaf(mid, Offset(q.dx - h * .002, q.dy + len), math.pi / 2, h * .016, h * .008);
      }
    }
    c.drawPath(
      vine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, h * .0026)
        ..color = const Color(0xff3b6b3f),
    );
    c.drawPath(dark, Paint()..color = _bridgeLeafDark);
    c.drawPath(mid, Paint()..color = _bridgeLeafMid);
    c.drawPath(lit, Paint()..color = _bridgeLeafLit);
    final dot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .0062;
    c.drawPoints(PointMode.points, blooms, dot..color = const Color(0xfff6f1df));
    c.drawPoints(PointMode.points, pinks, dot..color = const Color(0xffee98b8));

    // Moss cushions along the ropes and on the timber.
    final mossDark = Path(), mossLit = Path();
    for (var i = 0; i < 20; i++) {
      final t = .04 + .92 * Sketch.hash(i + 980);
      final onHand = Sketch.hash(i + 981) > .45;
      final p = _bridgeAt(a, b, h, t) - Offset(0, onHand ? rail : 0);
      final r = h * (.003 + .0035 * Sketch.hash(i + 982));
      final lobes = 2 + (Sketch.hash(i + 983) * 3).floor();
      for (var k = 0; k < lobes; k++) {
        final kr = r * (.7 + .6 * Sketch.hash(i * 7 + k + 990));
        final q = p + Offset((k - (lobes - 1) / 2) * r * 1.3, -kr * .5 - r * .3 * (k.isEven ? 1 : 0));
        mossDark.addOval(Rect.fromCenter(center: q, width: kr * 2.3, height: kr * 1.5));
        mossLit.addOval(Rect.fromCenter(center: q + Offset(-kr * .3, -kr * .35), width: kr * 1.2, height: kr * .7));
      }
    }
    c.drawPath(mossDark, Paint()..color = const Color(0xff4f8a44));
    c.drawPath(mossLit, Paint()..color = const Color(0xff8cc264));
    // Leaves crowd the lashings at both trunks.
    final tuft = Path(), tuftLit = Path();
    for (final (end, dir) in [(a, 1.0), (b, -1.0)]) {
      for (var k = 0; k < 6; k++) {
        final ang = math.pi / 2 - dir * (.2 + k * .38);
        final len = h * (.016 + .006 * Sketch.hash(k + 1000));
        final root = Offset(end.dx + dir * h * .016, end.dy + h * .012);
        final mid = root + Offset(math.cos(ang), math.sin(ang)) * (len * .5);
        _bridgeLeaf(tuft, mid, ang, len, len * .48);
        _bridgeLeaf(tuftLit, mid + Offset(-len * .1, -len * .12), ang, len * .55, len * .24);
      }
    }
    c.drawPath(tuft, Paint()..color = _bridgeLeafDark);
    c.drawPath(tuftLit, Paint()..color = _bridgeLeafMid);
  }

  /// A three-toed sloth hanging from the walking rope at [grip], [s] tall.
  static void _bridgeSloth(Canvas c, Offset grip, double s) {
    const fur = Color(0xff8a7a62), furLit = Color(0xffb3a487), furDark = Color(0xff5f5140);
    const face = Color(0xffe6dcbd), mask = Color(0xff3d3227), algae = Color(0xff8fa568);
    final limb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Far arm and leg hang in shade behind the body.
    c.drawLine(grip + Offset(-s * .06, 0), grip + Offset(-s * .1, s * .42), limb..strokeWidth = s * .12..color = furDark);
    c.drawLine(grip + Offset(s * .34, 0), grip + Offset(s * .36, s * .46), limb..strokeWidth = s * .12..color = furDark);
    c.save();
    c.translate(grip.dx, grip.dy);
    c.rotate(-.1);
    final body = Rect.fromCenter(center: Offset(s * .02, s * .58), width: s * 1.0, height: s * .54);
    c.drawOval(body, Paint()..color = fur);
    c.drawOval(
      Rect.fromCenter(center: Offset(s * .06, s * .44), width: s * .72, height: s * .24),
      Paint()..color = furLit,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(s * .12, s * .5), width: s * .5, height: s * .12),
      Paint()..color = algae.withValues(alpha: .7),
    );
    // Near arm and leg reach up to the rope with hooked claws.
    c.drawLine(Offset(-s * .28, s * .5), Offset(-s * .3, s * .02), limb..strokeWidth = s * .14..color = fur);
    c.drawLine(Offset(s * .38, s * .6), Offset(s * .42, s * .02), limb..strokeWidth = s * .14..color = fur);
    for (final x in [-.3, .42]) {
      for (var k = -1; k <= 1; k++) {
        c.drawLine(
          Offset(s * (x + k * .05), s * .0),
          Offset(s * (x + k * .06), s * .12),
          limb..strokeWidth = s * .035..color = furDark,
        );
      }
    }
    // The head hangs low with its pale face and dark eye stripe.
    c.drawCircle(Offset(-s * .5, s * .78), s * .2, Paint()..color = fur);
    c.drawOval(
      Rect.fromCenter(center: Offset(-s * .55, s * .8), width: s * .28, height: s * .26),
      Paint()..color = face,
    );
    c.save();
    c.translate(-s * .58, s * .78);
    c.rotate(-.35);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * .17, height: s * .06), Paint()..color = mask);
    c.restore();
    c.drawCircle(Offset(-s * .66, s * .85), s * .035, Paint()..color = mask);
    c.restore();
  }

  /// A small bird perched with its feet at [feet], [s] long; [kind] picks a
  /// blue tanager or a green parakeet. [dir] faces it left (-1) or right (1).
  static void _bridgeBird(Canvas c, Offset feet, double s, int kind, double dir) {
    final (body, wing, head, belly) = kind == 0
        ? (const Color(0xff5d9fc4), const Color(0xff36699a), const Color(0xff84c0dc), const Color(0xffd9e7e0))
        : (const Color(0xff72b552), const Color(0xff458a3e), const Color(0xffd0574a), const Color(0xffb9d97c));
    c.save();
    c.translate(feet.dx, feet.dy);
    c.scale(dir, 1);
    final p = Paint();
    c.drawPath(Sketch.poly([-.3, -.8, -1.32, -.34, -1.22, -.14, -.26, -.36], s: s), p..color = wing);
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * .58), width: s * 1.15, height: s * .72), p..color = body);
    c.drawOval(Rect.fromCenter(center: Offset(s * .12, -s * .44), width: s * .7, height: s * .34), p..color = belly);
    c.drawOval(Rect.fromCenter(center: Offset(-s * .12, -s * .66), width: s * .74, height: s * .4), p..color = wing);
    c.drawCircle(Offset(s * .5, -s * .92), s * .3, p..color = head);
    c.drawPath(Sketch.poly([.74, -.98, 1.12, -.84, .74, -.78], s: s), p..color = const Color(0xff3a3026));
    c.drawCircle(Offset(s * .58, -s * .96), s * .06, p..color = const Color(0xfffbf6e6));
    c.drawLine(
      Offset(s * .05, -s * .2),
      Offset(s * .05, 0),
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, s * .08)
        ..color = const Color(0xff3a3026),
    );
    c.restore();
  }

  /// Lianas swaying under the deck and a monkey ambling across it. Same
  /// coordinates as [features]; every copy of the period gets its own walker.
  static void _bridgeLive(Canvas c, SceneFrame f, int copy) {
    final h = f.h;
    final a = Offset(h * .6, h * .56), b = Offset(h * 1.5, h * .6);
    final span = b.dx - a.dx, off = h * _bridgeDepth;
    // Nothing to animate while this copy of the bridge is off screen.
    final view = c.getLocalClipBounds();
    if (view.right < a.dx - h * .1 || view.left > b.dx + h * .1) return;
    final vine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0028)
      ..color = const Color(0xff3b6b3f);
    final dark = Path(), lit = Path();
    const at = [.11, .24, .37, .5, .74, .88];
    for (var i = 0; i < at.length; i++) {
      final p0 = _bridgeAt(a, b, h, at[i]) + Offset(0, h * .004);
      final len = h * (.04 + .07 * Sketch.hash(i + 940));
      final sway = math.sin(f.clock * .55 + i * 2.1) * (h * .003 + len * .07);
      final tip = p0 + Offset(sway, len);
      final ctrl = p0 + Offset(sway * .15, len * .55);
      c.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy),
        vine,
      );
      for (var j = 0; j < 3; j++) {
        final q = _bridgeQuad(p0, ctrl, tip, .5 + j * .22);
        final side = j.isEven ? 1.0 : -1.0;
        final ang = math.pi / 2 + side * (.8 + .3 * Sketch.hash(i * 3 + j + 945));
        final size = h * (.012 + .005 * Sketch.hash(i * 3 + j + 960));
        final mid = q + Offset(math.cos(ang), math.sin(ang)) * (size * .5);
        _bridgeLeaf(dark, mid, ang, size, size * .5);
        _bridgeLeaf(lit, mid + Offset(-size * .08, -size * .14), ang, size * .55, size * .26);
      }
      _bridgeLeaf(dark, tip + Offset(0, h * .004), math.pi / 2 + sway * 4, h * .02, h * .009);
    }
    c.drawPath(dark, Paint()..color = _bridgeLeafMid);
    c.drawPath(lit, Paint()..color = _bridgeLeafLit);

    // A feather charm knotted to the near hand rope swings in the breeze.
    c.save();
    c.translate(a.dx + span * .555, _bridgeAt(a, b, h, .555).dy - h * _bridgeRail);
    c.rotate(math.sin(f.clock * .9 + .6) * .1);
    final cord = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, h * .0018)
      ..color = _bridgeShade;
    c.drawLine(Offset.zero, Offset(0, h * .015), cord);
    c.drawCircle(Offset(0, h * .0185), h * .0038, Paint()..color = const Color(0xff8a4f3a));
    for (final (ang, len, color) in const [
      (1.2, .03, Color(0xffb9503f)),
      (1.57, .035, Color(0xff3f8f8a)),
      (1.93, .029, Color(0xffddd3b8)),
    ]) {
      final root = Offset(0, h * .021);
      final dir = Offset(math.cos(ang), math.sin(ang));
      final feather = Path();
      _bridgeLeaf(feather, root + dir * (len * h * .5), ang, len * h, len * h * .34);
      c.drawPath(feather, Paint()..color = color);
      c.drawLine(root, root + dir * (len * h * .92), cord..strokeWidth = math.max(.5, h * .001)..color = const Color(0x66ffffff));
    }
    c.restore();

    // A monkey crosses on a slow loop; it steps out of one trunk and
    // vanishes into the other. Reduced Motion freezes it mid-span.
    const cycle = 44.0, walk = 32.0;
    final home = Sketch.hash(copy + 950);
    final u = ((f.clock + cycle * (.09 + .16 * home)) % cycle) / walk;
    if (u > 1) return;
    final dir = Sketch.hash(copy + 951) > .5 ? 1.0 : -1.0;
    final t = .04 + .92 * (dir > 0 ? u : 1 - u);
    final m = h * .047;
    final edge = math.min(1.0, math.min(u, 1 - u) / .05);
    final p = _bridgeAt(a, b, h, t);
    final q = _bridgeAt(a, b, h, t + .01);
    final tilt = math.atan2(q.dy - p.dy, q.dx - p.dx);
    _bridgeMonkey(
      c,
      p + Offset(0, -off * .42),
      m,
      u * span / (m * .62) * math.pi * 2,
      edge,
      dir,
      tilt,
    );
    // The netting strung in front of the deck passes over the monkey.
    c.drawPath(
      _bridgeNet(a, b, h, p.dx - m, p.dx + m, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, h * .0017)
        ..color = const Color(0x735b4530),
    );
  }

  /// A brown monkey walking along the deck, its feet at [foot], [m] long from
  /// nose to rump. [ph] is the gait phase, [dir] faces it left or right.
  static void _bridgeMonkey(
    Canvas c,
    Offset foot,
    double m,
    double ph,
    double alpha,
    double dir,
    double tilt,
  ) {
    Color k(Color col) => Sketch.fade(col, alpha);
    final fur = k(const Color(0xff4d3626)), furLit = k(const Color(0xff70503a));
    final furFar = k(const Color(0xff34251b)), skin = k(const Color(0xffd0a87e));
    final belly = k(const Color(0xffa37b52)), dark = k(const Color(0xff1f1610));
    c.save();
    c.translate(foot.dx, foot.dy);
    c.rotate(tilt);
    c.scale(dir, 1);
    final bob = -m * .03 * (1 - math.cos(ph * 2)) / 2;
    final limb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint();
    void reach(Offset from, double x, double phase, Color col, double w) {
      final swing = math.sin(ph + phase), lift = math.max(0.0, math.cos(ph + phase));
      final to = Offset(x + swing * m * .19, -lift * m * .12);
      final mid = Offset.lerp(from, to, .5)! + Offset(-m * .05, -m * .02);
      c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy),
        limb
          ..strokeWidth = m * w
          ..color = col,
      );
    }

    c.drawOval(
      Rect.fromCenter(center: Offset(0, m * .02), width: m * 1.1, height: m * .09),
      fill..color = const Color(0x3320301c),
    );
    // Tail carried high with a curl at the tip.
    c.drawPath(
      Path()
        ..moveTo(-m * .5, -m * .6 + bob)
        ..cubicTo(-m * .98, -m * .62, -m * 1.06, -m * 1.14, -m * .66, -m * 1.2)
        ..quadraticBezierTo(-m * .44, -m * 1.22, -m * .46, -m * 1.04),
      limb
        ..strokeWidth = m * .085
        ..color = fur,
    );
    // Far arm and leg, in shade.
    reach(Offset(m * .3, -m * .55 + bob), m * .46, math.pi, furFar, .15);
    reach(Offset(-m * .32, -m * .52 + bob), -m * .4, 0, furFar, .16);
    c.drawOval(
      Rect.fromCenter(center: Offset(0, -m * .6 + bob), width: m * 1.1, height: m * .5),
      fill..color = fur,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(m * .02, -m * .7 + bob), width: m * .92, height: m * .26),
      fill..color = furLit,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(m * .05, -m * .45 + bob), width: m * .6, height: m * .15),
      fill..color = belly,
    );
    // Near arm and leg.
    reach(Offset(m * .34, -m * .55 + bob), m * .46, 0, fur, .17);
    reach(Offset(-m * .3, -m * .52 + bob), -m * .4, math.pi, fur, .18);
    // Head, face and ear.
    final head = Offset(m * .66, -m * .74 + bob);
    c.drawCircle(head, m * .21, fill..color = fur);
    c.drawCircle(head + Offset(-m * .05, -m * .07), m * .12, fill..color = furLit);
    c.drawOval(
      Rect.fromCenter(center: head + Offset(m * .13, m * .04), width: m * .26, height: m * .2),
      fill..color = skin,
    );
    c.drawCircle(head + Offset(m * .06, -m * .02), m * .035, fill..color = dark);
    c.drawCircle(head + Offset(-m * .1, -m * .1), m * .06, fill..color = skin);
    c.restore();
  }

  /// The near band's plants, rooted along the ridge. Recorded into the cached
  /// features picture, so they sit behind the near ground and sink with it.
  void _understoryFeatures(Canvas c, Size size) {
    final h = size.height;
    final span = period(Depth.near) * h;
    // (position in viewport heights, kind, size in h, variant), back to front.
    for (final (x, kind, s, v) in const [
      (.25, 3, .27, 1),
      (1.35, 3, .25, 2),
      (2.45, 3, .28, 3),
      (.8, 2, .17, 0),
      (1.95, 2, .19, 1),
      (2.95, 2, .16, 2),
      (.55, 0, .19, 1),
      (1.62, 0, .2, 2),
      (2.7, 0, .18, 3),
      (3.2, 0, .15, 4),
      (.05, 1, .17, 0),
      (1.05, 1, .18, 1),
      (1.75, 1, .19, 2),
      (2.2, 1, .17, 0),
      (2.9, 1, .16, 1),
      (3.3, 1, .18, 2),
    ]) {
      final px = x / 3.4 * span;
      void put(double at) {
        final base = Offset(at, ridge(Depth.near, at / h, 0) * h + h * .02);
        switch (kind) {
          case 0:
            _monstera(c, base, h * s, seed: v, fog: .1);
          case 1:
            _fern(c, base, h * s, hue: v % 3, seed: v, fog: .06);
          case 2:
            _heliconia(c, base, h * s, hanging: v == 1, seed: v, fog: .14);
          default:
            _banana(c, base, h * s, seed: v, fruit: v.isOdd, fog: .22);
        }
      }

      put(px);
      if (px < h * .45) put(px + span);
    }
  }

  static final _understoryGrounds = <(double, double), Picture>{};
  static final _understoryFronds = <(double, double), List<(Picture, double, double, double)>>{};

  /// The forest floor in front of the near ridge: roots, moss, litter, a
  /// fallen log, toadstools, seedlings, orchids and bromeliads, and a fringe
  /// of grass that knits the plants behind to the ground. Recorded once per
  /// viewport; everything wraps at the period seam.
  Picture _understoryGround(Size size) {
    final key = (size.width, size.height);
    final cached = _understoryGrounds.remove(key);
    if (cached != null) return _understoryGrounds[key] = cached;
    final h = size.height, span = period(Depth.near) * h;
    final rec = PictureRecorder();
    final c = Canvas(rec);
    double ry(double x) => ridge(Depth.near, x / h, 0) * h;
    double px(double hx) => hx / 3.4 * span;
    void wrap(double x, double reach, void Function(double) draw) {
      draw(x);
      if (x < reach) draw(x + span);
    }

    // Broad tonal patches so the soil is not one flat gradient.
    for (var i = 0; i < 14; i++) {
      final x = span * (i + Sketch.hash(i + 800)) / 14;
      final y = ry(x) + h * (.035 + .06 * Sketch.hash(i + 801));
      final w = h * (.3 + .3 * Sketch.hash(i + 802));
      final dark = i.isEven;
      wrap(x, w, (x) {
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h * .05),
          Paint()..color = dark ? const Color(0x40123a28) : const Color(0x2e4a9a5c),
        );
      });
    }
    // Dappled sunlight falling through the canopy.
    for (var i = 0; i < 9; i++) {
      final x = span * (i + Sketch.hash(i + 780)) / 9;
      final y = ry(x) + h * (.05 + .06 * Sketch.hash(i + 781));
      final w = h * (.12 + .12 * Sketch.hash(i + 782));
      wrap(x, w, (x) {
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: w, height: w * .22),
          Paint()..color = const Color(0x1ef8f0a8),
        );
      });
    }
    // Buttress roots crawling out of the bank.
    for (final (x0, dx, wide) in const [(.78, -.34, .017), (2.1, .3, .015), (2.98, -.26, .016)]) {
      final a = Offset(px(x0), ry(px(x0)) - h * .006);
      final b = Offset(px(x0 + dx), h * 1.03);
      wrap(a.dx, h * .4, (x) {
        final o = Offset(x - a.dx, 0);
        _understoryBlade(
          c,
          a + o,
          Offset(a.dx + (b.dx - a.dx) * .1 + o.dx, a.dy + (b.dy - a.dy) * .7),
          b + o,
          h * wide,
          lit: const Color(0xff85694a),
          shade: const Color(0xff4b3a2b),
          rib: const Color(0xff5f4a35),
          veins: 0,
          belly: 0,
          tipPow: 1,
        );
        // Moss on the crown of the root.
        final moss = Paint()..color = const Color(0xff4d9a4e);
        for (var k = 0; k < 4; k++) {
          final t = .12 + .5 * k / 3;
          final p = _understoryQuad(a + o, Offset(a.dx + (b.dx - a.dx) * .1 + o.dx, a.dy + (b.dy - a.dy) * .7), b + o, t);
          c.drawOval(Rect.fromCenter(center: p + Offset(-h * .004, -h * .006), width: h * .03, height: h * .014), moss);
        }
      });
    }
    // Moss cushions.
    final mossDark = Path(), mossMid = Path(), mossLit = Path();
    for (var i = 0; i < 18; i++) {
      final x = span * (i + Sketch.hash(i + 820) * .8) / 18;
      final y = ry(x) + h * (.03 + .07 * Sketch.hash(i + 821));
      final n = 3 + (Sketch.hash(i + 822) * 3).floor();
      for (var k = 0; k < n; k++) {
        final r = h * (.008 + .011 * Sketch.hash(i * 9 + k + 823));
        final o = Offset((k - n / 2) * r * 1.3, r * .3 * (k.isEven ? 1 : -1));
        mossDark.addOval(Rect.fromCenter(center: Offset(x, y) + o, width: r * 2.6, height: r * 1.7));
        mossMid.addOval(Rect.fromCenter(center: Offset(x, y) + o + Offset(-r * .1, -r * .2), width: r * 2.1, height: r * 1.25));
        mossLit.addOval(Rect.fromCenter(center: Offset(x, y) + o + Offset(-r * .45, -r * .45), width: r * 1.1, height: r * .55));
      }
    }
    c.drawPath(mossDark, Paint()..color = const Color(0xff2c6a3e));
    c.drawPath(mossMid, Paint()..color = const Color(0xff3f8a4c));
    c.drawPath(mossLit, Paint()..color = const Color(0xff70b85c));
    // Leaf litter.
    final litter = [Path(), Path(), Path(), Path()];
    final litterRib = Path();
    for (var i = 0; i < 80; i++) {
      final x = span * (i + Sketch.hash(i + 840)) / 80;
      final y = math.min(h * .992, ry(x) + h * (.022 + .09 * Sketch.hash(i + 841)));
      final l = h * (.011 + .014 * Sketch.hash(i + 842));
      final a = Sketch.hash(i + 843) * math.pi;
      final d = Offset(math.cos(a), math.sin(a) * .55) * (l / 2);
      final n = Offset(-d.dy, d.dx) * .9;
      final p = Offset(x, y);
      litter[i % 4]
        ..moveTo(p.dx - d.dx, p.dy - d.dy)
        ..quadraticBezierTo(p.dx + n.dx, p.dy + n.dy, p.dx + d.dx, p.dy + d.dy)
        ..quadraticBezierTo(p.dx - n.dx, p.dy - n.dy, p.dx - d.dx, p.dy - d.dy)
        ..close();
      litterRib
        ..moveTo(p.dx - d.dx, p.dy - d.dy)
        ..lineTo(p.dx + d.dx, p.dy + d.dy);
    }
    for (final (i, color) in const [
      (0, Color(0xff8f6b3a)),
      (1, Color(0xff6c5a34)),
      (2, Color(0xff9a7c40)),
      (3, Color(0xff56753a)),
    ]) {
      c.drawPath(litter[i], Paint()..color = color);
    }
    c.drawPath(
      litterRib,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0018)
        ..color = const Color(0x552a2014),
    );
    // Pebbles.
    for (var i = 0; i < 9; i++) {
      final x = span * (i + Sketch.hash(i + 860)) / 9;
      final y = math.min(h * .985, ry(x) + h * (.04 + .07 * Sketch.hash(i + 861)));
      final r = h * (.006 + .008 * Sketch.hash(i + 862));
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 2.4, height: r * 1.5), Paint()..color = const Color(0xff415f4e));
      c.drawOval(Rect.fromCenter(center: Offset(x - r * .35, y - r * .3), width: r * 1.2, height: r * .6), Paint()..color = const Color(0xff7a9a84));
    }
    // The fallen log, with a fern and toadstools on and around it.
    wrap(px(1.78), h * .3, (x) {
      final y = ry(x) + h * .074;
      _understoryLog(c, Offset(x, y), h * .36, h * .034, seed: 3);
      _fern(c, Offset(x - h * .07, y - h * .026), h * .05, hue: 2, seed: 1);
      _understoryFrog(c, Offset(x + h * .08, y - h * .03), h * .04);
      _understoryMushrooms(c, Offset(x + h * .17, y + h * .03), h * .03, kind: 1);
      _understorySnail(c, Offset(x - h * .12, y + h * .05), h * .022);
    });
    for (final (hx, kind, s) in const [(.72, 0, .034), (2.62, 2, .03), (3.28, 1, .028), (2.02, 0, .026), (.06, 1, .03)]) {
      wrap(px(hx), h * .1, (x) => _understoryMushrooms(c, Offset(x, ry(x) + h * .07), h * s, kind: kind, seed: kind));
    }
    // Baby monsteras and ferns at the foot of the bank.
    for (final (hx, kind, s, v) in const [
      (.16, 0, .095, 1),
      (1.12, 0, .085, 2),
      (2.2, 0, .08, 3),
      (.56, 1, .07, 0),
      (1.55, 1, .06, 1),
      (2.5, 1, .065, 2),
      (3.02, 1, .07, 0),
    ]) {
      wrap(px(hx), h * .12, (x) {
        final base = Offset(x, ry(x) + h * .045);
        if (kind == 0) {
          _monstera(c, base, h * s, seed: v);
        } else {
          _fern(c, base, h * s, hue: v, seed: v);
        }
      });
    }
    for (final (hx, s, v) in const [(.25, .04, 1), (.84, .036, 2), (1.36, .04, 3), (2.0, .034, 4), (2.72, .04, 5), (3.1, .036, 6), (1.5, .03, 7)]) {
      wrap(px(hx), h * .05, (x) => _understorySeedling(c, Offset(x, ry(x) + h * (.05 + .03 * Sketch.hash(v))), h * s, seed: v));
    }
    // Bromeliads and orchids rooted at the bank.
    for (final hx in const [.95, 2.35, 3.15]) {
      wrap(px(hx), h * .12, (x) => _understoryBromeliad(c, Offset(x, ry(x) + h * .05), h * .085));
    }
    for (final (hx, s) in const [(.4, .16), (1.28, .14), (2.85, .17)]) {
      wrap(px(hx), h * .2, (x) => _understoryOrchid(c, Offset(x, ry(x) + h * .045), h * s, fog: .1));
    }
    // A fringe of grass along the ridge.
    final blades = [Path(), Path(), Path()];
    for (var i = 0; i < 34; i++) {
      final x = h * .04 + (span - h * .08) * (i + .15 + .7 * Sketch.hash(i + 900)) / 34;
      final y = ry(x) + h * .016;
      final n = 5 + (Sketch.hash(i + 901) * 5).floor();
      final ht = h * (.028 + .034 * Sketch.hash(i + 902));
      final lean = (Sketch.hash(i + 903) - .5) * .8;
      for (var k = 0; k < n; k++) {
        final u = n == 1 ? 0.0 : k / (n - 1) * 2 - 1;
        final bx = x + u * h * .02;
        final tx = bx + (u * .7 + lean) * ht * .8;
        final ty = y - ht * (1 - .35 * u.abs()) * (.75 + .5 * Sketch.hash(i * 17 + k));
        final cx = bx + (tx - bx) * .3, cy = (y + ty) / 2;
        final w = math.max(.5, h * .0032);
        blades[(k + i) % 3]
          ..moveTo(bx - w, y)
          ..quadraticBezierTo(cx - w * .5, cy, tx, ty)
          ..quadraticBezierTo(cx + w * .5, cy, bx + w, y)
          ..close();
      }
    }
    for (final (i, color) in const [(0, Color(0xff1f5a3a)), (1, Color(0xff2f7a4c)), (2, Color(0xff5aa85e))]) {
      c.drawPath(blades[i], Paint()..color = color);
    }
    final picture = rec.endRecording();
    _understoryGrounds[key] = picture;
    if (_understoryGrounds.length > 6) _understoryGrounds.remove(_understoryGrounds.keys.first);
    return picture;
  }

  /// Big dark fronds and leaves framing the bottom edge, each recorded once
  /// with its root at the origin so the overlay can sway them for free.
  List<(Picture, double, double, double)> _understoryFrame(Size size) {
    final key = (size.width, size.height);
    final cached = _understoryFronds.remove(key);
    if (cached != null) return _understoryFronds[key] = cached;
    final h = size.height, span = period(Depth.near) * h;
    final out = <(Picture, double, double, double)>[];
    // (position in h, kind, length in h, lean)
    for (final (i, (hx, kind, len, dir)) in const [
      (.34, 0, .27, 1.0),
      (.96, 1, .24, -1.0),
      (1.4, 2, .2, -1.0),
      (2.28, 0, .28, -1.0),
      (2.7, 2, .21, 1.0),
      (3.12, 1, .24, 1.0),
    ].indexed) {
      final rec = PictureRecorder();
      final c = Canvas(rec);
      final l = h * len;
      switch (kind) {
        case 0:
          _understoryFrond(
            c,
            Offset.zero,
            Offset(dir * l * .1, -l * .95),
            Offset(dir * l * .82, -l * .72),
            l * .17,
            rib: const Color(0xff174a30),
            shade: const Color(0xff1f6540),
            lit: const Color(0xff36895a),
            pairs: 26,
            plump: 1.25,
          );
        case 1:
          _understoryBlade(
            c,
            Offset.zero,
            Offset(dir * l * .15, -l * .9),
            Offset(dir * l * .78, -l * .78),
            l * .19,
            lit: const Color(0xff2b7d51),
            shade: const Color(0xff1a5537),
            rib: const Color(0xff66aa68),
            veins: 10,
            tears: 2,
            seed: i,
            belly: .5,
            tipPow: .6,
          );
        default:
          final notch = Offset(dir * l * .1, -l * .92);
          c.drawPath(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(dir * l * .02, -l * .5, notch.dx, notch.dy),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = l * .055
              ..strokeCap = StrokeCap.round
              ..color = const Color(0xff1d5f3b),
          );
          _understoryHeart(
            c,
            notch,
            math.pi / 2 - dir * .9,
            l * .8,
            lit: const Color(0xff2c7f52),
            shade: const Color(0xff1a5a38),
            rib: const Color(0xff78ba76),
            slits: 3,
            seed: i,
          );
      }
      out.add((rec.endRecording(), hx / 3.4 * span, h * 1.04, Sketch.hash(i + 950) * 6.28));
    }
    _understoryFronds[key] = out;
    if (_understoryFronds.length > 6) _understoryFronds.remove(_understoryFronds.keys.first);
    return out;
  }

  /// The near band's overlay: the cached forest floor, the swaying frame of
  /// leaves along the bottom, and a few dewdrops catching the sun. During a
  /// crossing it sinks out of the bottom edge (or fades in Reduced Motion).
  void _understoryOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h, span = period(Depth.near) * h;
    final drop = f.reducedMotion ? 0.0 : sink(Depth.near) * h * (1 - presence) * (1 - presence * .35);
    final fade = f.reducedMotion && presence < 1;
    if (fade) {
      c.saveLayer(Rect.fromLTRB(-h, h * .6, span + h, h * 1.1), Paint()..color = Color.fromRGBO(0, 0, 0, presence));
    }
    c.save();
    c.translate(0, drop);
    c.drawPicture(_understoryGround(f.size));
    // The tree frog on the log blinks now and then.
    if (f.clock % 5.3 < .16) {
      final fx = 1.78 / 3.4 * span + h * .08;
      final fy = ridge(Depth.near, 1.78 / 3.4 * span / h, 0) * h + h * .044;
      c.drawCircle(Offset(fx - h * .016, fy - h * .0288), h * .0076, Paint()..color = const Color(0xff58b447));
    }
    for (final (i, (pic, x, y, phase)) in _understoryFrame(f.size).indexed) {
      c.save();
      c.translate(x, y);
      c.rotate(math.sin(f.clock * (.5 + .05 * i) + phase) * .028 + math.sin(f.clock * .23 + phase * 2) * .012);
      c.drawPicture(pic);
      c.restore();
    }
    // Dewdrops twinkle on the leaves near the ground.
    final dew = Paint();
    for (var i = 0; i < 12; i++) {
      final x = span * (i + Sketch.hash(i + 970)) / 12;
      final y = ridge(Depth.near, x / h, 0) * h + h * (.03 + .06 * Sketch.hash(i + 971));
      final tw = math.sin(f.clock * (1.1 + .3 * Sketch.hash(i + 972)) + Sketch.hash(i + 973) * 6.28) * .5 + .5;
      final a = tw * tw * tw;
      if (a < .06) continue;
      final r = h * .0034 * (.6 + .4 * a);
      dew.color = Color.fromRGBO(240, 255, 226, .85 * a);
      c.drawCircle(Offset(x, y), r, dew);
      if (a > .55) {
        dew
          ..strokeWidth = math.max(.5, h * .0012)
          ..style = PaintingStyle.stroke;
        c.drawLine(Offset(x - r * 2.4, y), Offset(x + r * 2.4, y), dew);
        c.drawLine(Offset(x, y - r * 2.4), Offset(x, y + r * 2.4), dew);
        dew.style = PaintingStyle.fill;
      }
    }
    c.restore();
    if (fade) c.restore();
  }

  // ---------------------------------------------------------------------------
  // Understory: the near band's plants. Everything below is recorded once into
  // cached pictures, so it can afford real leaf structure.

  /// Unit vector towards the morning sun: surfaces facing it take the lit tone.
  static const _understoryLight = Offset(-.55, -.83);

  /// Mist green the taller understory leaves fade into, keeping the flight
  /// corridor calm.
  static const _understoryMist = Color(0xff8cbf98);

  static Color _understoryFog(Color c, double fog) =>
      fog <= 0 ? c : Sketch.mix(c, _understoryMist, fog);

  static Offset _understoryQuad(Offset a, Offset q, Offset b, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * q.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * q.dy + t * t * b.dy,
    );
  }

  static Offset _understoryTan(Offset a, Offset q, Offset b, double t) {
    final dx = 2 * (1 - t) * (q.dx - a.dx) + 2 * t * (b.dx - q.dx);
    final dy = 2 * (1 - t) * (q.dy - a.dy) + 2 * t * (b.dy - q.dy);
    final l = math.sqrt(dx * dx + dy * dy);
    return l < 1e-9 ? const Offset(1, 0) : Offset(dx / l, dy / l);
  }

  /// Continues [path] in a smooth curve through [p] (quadratics through the
  /// midpoints), starting from p.first.
  static void _understorySmooth(Path path, List<Offset> p) {
    path.lineTo(p[0].dx, p[0].dy);
    for (var i = 1; i < p.length - 1; i++) {
      final m = Offset.lerp(p[i], p[i + 1], .5)!;
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
  }

  static double _understoryProfile(double t, double belly, double tipPow) {
    final v = t < belly
        ? math.sin(math.pi / 2 * t / belly)
        : math.cos(math.pi / 2 * (t - belly) / (1 - belly));
    return math.pow(math.max(0.0, v), t < belly ? .8 : tipPow).toDouble();
  }

  /// A leaf blade along the arched spine a -> q -> b: a sun-facing half and a
  /// shaded half, a bright core, midrib, lateral veins and a rim-lit edge.
  /// [tears] cuts wedge-shaped rents from the margin (wind-torn banana).
  static void _understoryBlade(
    Canvas c,
    Offset a,
    Offset q,
    Offset b,
    double wide, {
    required Color lit,
    required Color shade,
    required Color rib,
    int veins = 9,
    int tears = 0,
    int seed = 0,
    double belly = .45,
    double tipPow = .75,
    bool fine = true,
  }) {
    Offset at(double t) => _understoryQuad(a, q, b, t);
    Offset nm(double t) {
      final d = _understoryTan(a, q, b, t);
      return Offset(d.dy, -d.dx);
    }

    double wd(double t) => wide * _understoryProfile(t, belly, tipPow);
    Offset edge(double t, double side) => at(t) + nm(t) * (wd(t) * side);
    final mid = nm(.5);
    final sun =
        mid.dx * _understoryLight.dx + mid.dy * _understoryLight.dy >= 0
        ? 1.0
        : -1.0;
    Path halfPath(double side, double frac, [double t0 = 0, double t1 = 1]) {
      const m = 12;
      final e = [
        for (var i = 0; i <= m; i++) edge(t0 + (t1 - t0) * i / m, side * frac),
      ];
      final s = [for (var i = m; i >= 0; i--) at(t0 + (t1 - t0) * i / m)];
      final p = Path()..moveTo(e.first.dx, e.first.dy);
      _understorySmooth(p, e);
      _understorySmooth(p, s);
      return p..close();
    }

    Path? cut;
    if (tears > 0) {
      final p = Path();
      for (final side in const [-1.0, 1.0]) {
        for (var j = 0; j < tears; j++) {
          final r = Sketch.hash(seed * 31 + j * 7 + (side > 0 ? 3 : 0));
          final t = .14 + .74 * (j + .25 + .5 * r) / tears;
          final dt = .07 + .05 * Sketch.hash(seed * 17 + j * 5);
          final o1 = edge(t, side * 1.5), o2 = edge(t + .03, side * 1.5);
          final inner = edge(math.min(.98, t + dt), side * (.14 + .22 * r));
          p
            ..moveTo(o1.dx, o1.dy)
            ..lineTo(inner.dx, inner.dy)
            ..lineTo(o2.dx, o2.dy)
            ..close();
        }
      }
      cut = p;
    }
    Path clip(Path p) =>
        cut == null ? p : Path.combine(PathOperation.difference, p, cut);
    c.drawPath(clip(halfPath(-sun, 1)), Paint()..color = shade);
    c.drawPath(clip(halfPath(sun, 1)), Paint()..color = lit);
    if (fine) {
      c.drawPath(
        clip(halfPath(sun, .5, .1, .86)),
        Paint()
          ..color = Sketch.fade(
            Sketch.mix(lit, const Color(0xfff0ffb4), .4),
            .55,
          ),
      );
    }
    final stroke = Paint()..style = PaintingStyle.stroke;
    final vein = Path(), veinShade = Path();
    for (var i = 1; i <= veins; i++) {
      final t = .05 + .84 * i / (veins + 1);
      for (final side in const [-1.0, 1.0]) {
        final p = side == sun ? vein : veinShade;
        final from = at(t), to = edge(math.min(.97, t + .1), side * .93);
        final ctl = edge(math.min(.97, t + .03), side * .55);
        p
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(ctl.dx, ctl.dy, to.dx, to.dy);
      }
    }
    final vw = math.max(.5, wide * .035);
    c.drawPath(
      veinShade,
      stroke
        ..strokeWidth = vw
        ..color = Sketch.fade(Sketch.mix(shade, const Color(0xff0c2e1c), .45), .5),
    );
    c.drawPath(
      vein,
      stroke
        ..strokeWidth = vw
        ..color = Sketch.fade(Sketch.mix(lit, rib, .5), .55),
    );
    final spine = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(q.dx, q.dy, b.dx, b.dy);
    c.drawPath(
      spine,
      stroke
        ..strokeWidth = math.max(.7, wide * .13)
        ..strokeCap = StrokeCap.round
        ..color = rib,
    );
    if (!fine) return;
    final rim = Path();
    for (var i = 0; i <= 10; i++) {
      final e = edge(.1 + .78 * i / 10, sun);
      i == 0 ? rim.moveTo(e.dx, e.dy) : rim.lineTo(e.dx, e.dy);
    }
    c.drawPath(
      rim,
      stroke
        ..strokeWidth = math.max(.6, wide * .05)
        ..color = Sketch.fade(Sketch.mix(lit, const Color(0xffe4ffb0), .6), .6),
    );
  }

  /// A monstera blade: a heart hanging from its petiole notch, its margin cut
  /// by slits and its middle by oval holes, lit on the sun side. The notch is
  /// at [notch]; [angle] points along the blade (pi/2 hangs it straight down).
  static void _understoryHeart(
    Canvas c,
    Offset notch,
    double angle,
    double len, {
    required Color lit,
    required Color shade,
    required Color rib,
    int slits = 4,
    int seed = 0,
  }) {
    c.save();
    c.translate(notch.dx, notch.dy);
    c.rotate(angle);
    final up = <Offset>[
      for (final (x, y) in const [
        (0.0, 0.0),
        (-.07, -.1),
        (-.14, -.22),
        (-.14, -.36),
        (-.05, -.46),
        (.13, -.5),
        (.36, -.47),
        (.6, -.36),
        (.82, -.19),
        (1.0, 0.0),
      ])
        Offset(x * len, y * len),
    ];
    final down = [for (final p in up) Offset(p.dx, -p.dy)];
    Path half(List<Offset> pts, double k) {
      final p = Path()..moveTo(0, 0);
      _understorySmooth(p, [for (final o in pts) o * k]);
      return p..close();
    }

    final cut = Path();
    for (final side in const [-1.0, 1.0]) {
      for (var j = 0; j < slits; j++) {
        final u = .16 + .18 * j + .012 * Sketch.hash(seed * 7 + j);
        final inner = Offset((u + .05) * len, side * .16 * len);
        final outer = Offset((u + .2) * len, side * .62 * len);
        final d = (outer - inner) / (outer - inner).distance;
        final perp = Offset(-d.dy, d.dx);
        cut.addPolygon([
          inner + perp * (len * .01),
          outer + perp * (len * .036),
          outer - perp * (len * .036),
          inner - perp * (len * .008),
        ], true);
      }
      // Oval perforations between the midrib and the slits.
      for (var j = 0; j < slits - 1; j++) {
        final u = .21 + .17 * j;
        cut.addOval(
          Rect.fromCenter(
            center: Offset((u + .08) * len, side * .08 * len),
            width: len * .1,
            height: len * .05,
          ),
        );
      }
    }
    final sunUp =
        math.sin(angle) * _understoryLight.dx -
            math.cos(angle) * _understoryLight.dy >
        0;
    Path clip(Path p) =>
        slits == 0 ? p : Path.combine(PathOperation.difference, p, cut);
    c.drawPath(clip(half(sunUp ? down : up, 1)), Paint()..color = shade);
    c.drawPath(clip(half(sunUp ? up : down, 1)), Paint()..color = lit);
    c.drawPath(
      clip(half(sunUp ? up : down, .58)),
      Paint()
        ..color = Sketch.fade(
          Sketch.mix(lit, const Color(0xffe6ffb0), .42),
          .5,
        ),
    );
    // Lateral veins, between the slits.
    final vein = Path();
    for (final side in const [-1.0, 1.0]) {
      for (var j = 0; j <= math.max(slits, 3); j++) {
        final u = .08 + .16 * j;
        vein
          ..moveTo(u * len, side * .012 * len)
          ..quadraticBezierTo(
            (u + .1) * len,
            side * .2 * len,
            (u + .2) * len,
            side * (.36 - .025 * j) * len,
          );
      }
    }
    c.drawPath(
      vein,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, len * .012)
        ..color = Sketch.fade(Sketch.mix(shade, const Color(0xff0c2e1c), .4), .45),
    );
    c.drawPath(
      Sketch.poly(const [
        -.03,
        -.02,
        .6,
        -.009,
        .97,
        0,
        .6,
        .009,
        -.03,
        .02,
      ], s: len),
      Paint()..color = rib,
    );
    c.restore();
  }

  /// A monstera: heart-shaped, holed and slit leaves hanging from arching
  /// petioles.
  static void _monstera(Canvas c, Offset base, double s, {int seed = 0, double fog = 0}) {
    Color f(int v) => _understoryFog(Color(v), fog);
    final stalk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // (notch x, notch y, ctrl x, ctrl y, blade angle, blade length, young)
    final leaves = <(double, double, double, double, double, double, bool)>[
      (.04, -1.02, .0, -.55, math.pi / 2 - .1, .5, true),
      (-.6, -.7, -.55, -.08, math.pi / 2 + .3, .62, false),
      (.56, -.8, .56, -.1, math.pi / 2 - .25, .6, false),
    ];
    for (final (nx, ny, cx, cy, ang, len, young) in leaves) {
      final notch = base + Offset(nx * s, ny * s);
      final ctrl = base + Offset(cx * s, cy * s);
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, notch.dx, notch.dy);
      c.drawPath(
        path,
        stalk
          ..strokeWidth = s * .05
          ..color = f(0xff2f7a45),
      );
      c.drawPath(
        path.shift(Offset(-s * .012, 0)),
        stalk
          ..strokeWidth = s * .016
          ..color = Sketch.fade(f(0xff7fc36a), .8),
      );
      _understoryHeart(
        c,
        notch,
        ang,
        len * s,
        lit: young ? f(0xff7ccb6e) : f(0xff4fae66),
        shade: young ? f(0xff3f9a55) : f(0xff2e7c50),
        rib: young ? f(0xffd6f0a6) : f(0xffb4e08e),
        slits: young ? 0 : 4,
        seed: seed + ny.round(),
      );
    }
  }

  /// A banana plant: a layered green pseudostem, long arching blades split
  /// by the wind, and (on some) a nodding bunch with its purple bud.
  static void _banana(
    Canvas c,
    Offset base,
    double s, {
    int seed = 0,
    bool fruit = false,
    double fog = 0,
  }) {
    Color f(int v) => _understoryFog(Color(v), fog);
    final topY = -.44;
    // Pseudostem: sun side and shade side, sheath rings, mottling.
    final lean = (Sketch.hash(seed + 5) - .5) * .05;
    Offset p(double x, double y) => base + Offset((x + lean * (-y / .44)) * s, y * s);
    Path stem(double l, double r) {
      final path = Path()
        ..moveTo(p(l * 1.5, 0).dx, p(l * 1.5, 0).dy);
      path.quadraticBezierTo(
        p(l * 1.1, -.2).dx,
        p(l * 1.1, -.2).dy,
        p(l * .75, topY).dx,
        p(l * .75, topY).dy,
      );
      path.lineTo(p(r * .75, topY).dx, p(r * .75, topY).dy);
      path.quadraticBezierTo(
        p(r * 1.1, -.2).dx,
        p(r * 1.1, -.2).dy,
        p(r * 1.5, 0).dx,
        p(r * 1.5, 0).dy,
      );
      return path..close();
    }

    c.drawPath(stem(-.05, 0), Paint()..color = f(0xff8cc060));
    c.drawPath(stem(0, .05), Paint()..color = f(0xff5c9a45));
    final ring = Path();
    for (var i = 1; i <= 6; i++) {
      final y = -i * .062;
      final w = .05 - .016 * (i / 6);
      ring
        ..moveTo(p(-w, y).dx, p(-w, y).dy)
        ..quadraticBezierTo(p(0, y + .014).dx, p(0, y + .014).dy, p(w, y).dx, p(w, y).dy);
    }
    c.drawPath(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, s * .006)
        ..color = Sketch.fade(f(0xff3f7a38), .7),
    );
    final blotch = Paint()..color = Sketch.fade(f(0xff3a4a2a), .5);
    for (var i = 0; i < 6; i++) {
      final y = -.05 - .34 * Sketch.hash(seed * 3 + i);
      final x = (Sketch.hash(seed * 5 + i) - .5) * .05;
      c.drawOval(
        Rect.fromCenter(center: p(x, y), width: s * .014, height: s * .03),
        blotch,
      );
    }
    // Dry, papery sheaths hanging at the foot.
    final dry = Paint()..color = f(0xffb59b62);
    for (final side in const [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(p(side * .03, -.18).dx, p(side * .03, -.18).dy)
          ..quadraticBezierTo(p(side * .1, -.08).dx, p(side * .1, -.08).dy, p(side * .09, .02).dx, p(side * .09, .02).dy)
          ..quadraticBezierTo(p(side * .05, -.06).dx, p(side * .05, -.06).dy, p(side * .03, -.18).dx, p(side * .03, -.18).dy)
          ..close(),
        dry,
      );
    }
    final top = p(0, topY);
    // Blades, back to front. (angle, length, droop, tier)
    for (final (a, len, droop, tier) in const [
      (-1.95, .62, .1, 0),
      (-1.2, .66, .12, 0),
      (-2.55, .7, .4, 1),
      (-.6, .72, .38, 1),
      (-3.05, .68, .62, 2),
      (-.1, .66, .6, 2),
    ]) {
      final dir = Offset(math.cos(a), math.sin(a));
      final tip = top + dir * (s * len) + Offset(0, s * len * droop);
      final ctl = top + dir * (s * len * .55) - Offset(0, s * len * .2);
      final (lit, shade, rib) = switch (tier) {
        0 => (f(0xff4a9250), f(0xff2d6c40), f(0xffa7cf82)),
        1 => (f(0xff62ad55), f(0xff397c48), f(0xffcbe6a0)),
        _ => (f(0xff7cc262), f(0xff468a4c), f(0xffe0f2b0)),
      };
      _understoryBlade(
        c,
        top,
        ctl,
        tip,
        s * len * .16,
        lit: lit,
        shade: shade,
        rib: rib,
        veins: 11,
        tears: 3 + tier,
        seed: seed + tier * 3 + a.round(),
        belly: .5,
        tipPow: .6,
      );
    }
    // The youngest leaf, still a pale rolled spear.
    c.drawPath(
      Path()
        ..moveTo(top.dx - s * .014, top.dy)
        ..quadraticBezierTo(top.dx - s * .03, top.dy - s * .2, top.dx + s * .01, top.dy - s * .34)
        ..quadraticBezierTo(top.dx + s * .04, top.dy - s * .18, top.dx + s * .014, top.dy)
        ..close(),
      Paint()..color = f(0xffb6dc7c),
    );
    if (fruit) {
      // A nodding flower stalk: bunched hands of green fingers, then the
      // plum-coloured bud.
      final a = top + Offset(s * .02, s * .02);
      final q = top + Offset(s * .17, -s * .03);
      final b = top + Offset(s * .2, s * .17);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(q.dx, q.dy, b.dx, b.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .018
          ..strokeCap = StrokeCap.round
          ..color = f(0xff5a8a40),
      );
      final finger = Paint()..color = f(0xff8cc257);
      final fingerLit = Paint()..color = f(0xffb6df78);
      // Hands of fingers hang from the stalk, each curving back up.
      for (var hand = 0; hand < 3; hand++) {
        final at = _understoryQuad(a, q, b, .46 + hand * .17);
        for (var k = 0; k < 4; k++) {
          final o = at + Offset((k - 1.5) * s * .008, s * .008 * k);
          c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy)
              ..quadraticBezierTo(o.dx + s * .012, o.dy + s * .075, o.dx + s * .05, o.dy + s * .03)
              ..lineTo(o.dx + s * .045, o.dy + s * .014)
              ..quadraticBezierTo(o.dx + s * .014, o.dy + s * .05, o.dx - s * .004, o.dy - s * .003)
              ..close(),
            k.isEven ? finger : fingerLit,
          );
        }
      }
      final bud = Path()
        ..moveTo(b.dx, b.dy - s * .01)
        ..quadraticBezierTo(b.dx + s * .055, b.dy + s * .02, b.dx + s * .01, b.dy + s * .13)
        ..quadraticBezierTo(b.dx - s * .05, b.dy + s * .04, b.dx, b.dy - s * .01)
        ..close();
      c.drawPath(bud, Paint()..color = f(0xff7d2f60));
      c.drawPath(
        Path()
          ..moveTo(b.dx, b.dy - s * .01)
          ..quadraticBezierTo(b.dx - s * .05, b.dy + s * .04, b.dx + s * .01, b.dy + s * .13)
          ..quadraticBezierTo(b.dx - s * .025, b.dy + s * .05, b.dx, b.dy - s * .01)
          ..close(),
        Paint()..color = f(0xffb0508a),
      );
    }
  }

  /// One fern frond along the arched rachis root -> ctl -> tip: paired
  /// leaflets that swell then taper, lit on the upper face. [reach] is the
  /// longest leaflet.
  static void _understoryFrond(
    Canvas c,
    Offset root,
    Offset ctl,
    Offset tip,
    double reach, {
    required Color rib,
    required Color shade,
    required Color lit,
    int pairs = 22,
    double sweep = .9,
    double plump = 1,
  }) {
    final litPath = Path(), shadePath = Path();
    for (var i = 0; i < pairs; i++) {
      final t = .08 + .9 * (i + .5) / pairs;
      final p = _understoryQuad(root, ctl, tip, t);
      final d = _understoryTan(root, ctl, tip, t);
      var up = Offset(d.dy, -d.dx);
      if (up.dy > 0) up = -up;
      final env = t < .32 ? .55 + 1.4 * t : 1 - (t - .32) * 1.1;
      final lp = reach * env;
      final ww = lp * .16 * plump;
      for (final side in const [1.0, -1.0]) {
        final ang = side > 0 ? sweep : sweep + .15;
        var v = d * math.cos(ang) + up * (side * math.sin(ang));
        if (side < 0) v = v + const Offset(0, .3);
        final tipP = p + v * lp;
        final bulge = up * (side * lp * .16);
        final c1 = p + v * (lp * .55) + bulge;
        final c2 = p + v * (lp * .5) - bulge * .2;
        (side > 0 ? litPath : shadePath)
          ..moveTo(p.dx - d.dx * ww, p.dy - d.dy * ww)
          ..quadraticBezierTo(c1.dx, c1.dy, tipP.dx, tipP.dy)
          ..quadraticBezierTo(c2.dx, c2.dy, p.dx + d.dx * ww, p.dy + d.dy * ww)
          ..close();
      }
    }
    c.drawPath(
      Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(ctl.dx, ctl.dy, tip.dx, tip.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, reach * .15)
        ..color = rib,
    );
    c.drawPath(shadePath, Paint()..color = shade);
    c.drawPath(litPath, Paint()..color = lit);
  }

  /// A fern rosette: arching, drooping fronds with fiddleheads uncurling in
  /// the heart. [hue]: 0 green, 1 blue-green, 2 lime.
  static void _fern(
    Canvas c,
    Offset base,
    double s, {
    int hue = 0,
    double fog = 0,
    int seed = 0,
  }) {
    final (deep, mid, lit) = switch (hue) {
      1 => (
        const Color(0xff236b57),
        const Color(0xff3a9a7c),
        const Color(0xff6fcaa0),
      ),
      2 => (
        const Color(0xff3c7a2e),
        const Color(0xff69b13e),
        const Color(0xffa4d962),
      ),
      _ => (
        const Color(0xff21693f),
        const Color(0xff3b9a55),
        const Color(0xff72c66e),
      ),
    };
    Color f(Color v) => _understoryFog(v, fog);
    // (angle, length, tier): tier 0 droops at the back in the shade.
    for (final (a, len, tier) in const [
      (-2.95, .84, 0),
      (-.2, .86, 0),
      (-2.55, .98, 1),
      (-.6, 1.0, 1),
      (-2.12, .92, 2),
      (-1.0, .95, 2),
      (-1.72, .74, 2),
      (-1.42, .78, 2),
    ]) {
      final wob =
          (Sketch.hash(seed * 13 + tier * 5 + (a * 10).round()) - .5) * .12;
      final dir = Offset(math.cos(a + wob), math.sin(a + wob));
      final tip =
          base +
          dir * (s * len) +
          Offset(0, s * (.2 + .32 * math.cos(a).abs()));
      final ctl = base + dir * (s * len * .55) - Offset(0, s * len * .34);
      _understoryFrond(
        c,
        base,
        ctl,
        tip,
        s * .15 * (len * .5 + .5),
        rib: f(deep),
        shade: f(tier == 0 ? deep : Sketch.mix(deep, mid, .6)),
        lit: f(
          tier == 0
              ? Sketch.mix(deep, mid, .8)
              : (tier == 1 ? mid : Sketch.mix(mid, lit, .65)),
        ),
      );
    }
    // Fiddleheads: young fronds still coiled in the heart of the plant.
    final coil = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, s * .02)
      ..color = f(const Color(0xffb4dd7e));
    for (final (dx, tall) in const [(-.05, .3), (.06, .22)]) {
      final root = base + Offset(dx * s, -s * .02);
      final top = root + Offset(dx * s * .5, -s * tall);
      final path = Path()..moveTo(root.dx, root.dy);
      path.quadraticBezierTo(root.dx, top.dy + s * .05, top.dx, top.dy);
      const turns = 12;
      for (var i = 1; i <= turns; i++) {
        final th = i / turns * math.pi * 2.6;
        final r = s * .05 * (1 - i / (turns + 3));
        path.lineTo(
          top.dx + r * math.sin(th) * (dx > 0 ? -1 : 1),
          top.dy - s * .05 + r * math.cos(th),
        );
      }
      c.drawPath(path, coil);
    }
  }

  /// A heliconia: broad paddle leaves and a chain of boat-shaped bracts,
  /// upright (lobster claw) or nodding on an arching stem.
  static void _heliconia(
    Canvas c,
    Offset base,
    double s, {
    bool hanging = false,
    double fog = 0,
    int seed = 0,
  }) {
    Color f(int v) => _understoryFog(Color(v), fog);
    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .04
      ..color = f(0xff3f8a52);
    // Paddle leaves: a tall one standing behind, then two leaning out.
    _understoryBlade(
      c,
      base,
      base + Offset(s * .02, -s * .5),
      base + Offset(s * .1, -s * .98),
      s * .13,
      lit: f(0xff62b866),
      shade: f(0xff2f8a52),
      rib: f(0xffc6e69a),
      veins: 10,
      belly: .55,
      tipPow: .7,
    );
    for (final side in const [-1.0, 1.0]) {
      _understoryBlade(
        c,
        base + Offset(side * s * .03, -s * .05),
        base + Offset(side * s * .3, -s * .4),
        base + Offset(side * s * (side < 0 ? .62 : .58), -s * (side < 0 ? .56 : .66)),
        s * .12,
        lit: f(0xff52ae5e),
        shade: f(0xff287a48),
        rib: f(0xffc0e494),
        veins: 10,
        belly: .55,
        tipPow: .7,
      );
    }
    if (!hanging) {
      final top = base + Offset(0, -s * 1.04);
      final ctl = base + Offset(s * .05, -s * .6);
      c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(ctl.dx, ctl.dy, top.dx, top.dy),
        stem,
      );
      for (var k = 0; k < 7; k++) {
        final side = k.isEven ? 1.0 : -1.0;
        final at = _understoryQuad(base, ctl, top, .48 + k * .08);
        final z = s * (.3 - .022 * k);
        _understoryBract(c, at, at + Offset(side * z * .9, -z * .55), Offset(0, 1), f);
      }
    } else {
      // The stem arches over and the chain of bracts hangs from its apex.
      final a = base + Offset(0, -s * .08);
      final q = base + Offset(s * .04, -s * 1.5);
      final b = base + Offset(s * .3, -s * .98);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(q.dx, q.dy, b.dx, b.dy),
        stem,
      );
      final k1 = b + Offset(s * .03, s * .36), k2 = b + Offset(s * .16, s * .66);
      c.drawPath(
        Path()
          ..moveTo(b.dx, b.dy)
          ..quadraticBezierTo(k1.dx, k1.dy, k2.dx, k2.dy),
        stem
          ..strokeWidth = s * .026
          ..color = f(0xffc9452f),
      );
      for (var k = 0; k < 6; k++) {
        final side = k.isEven ? 1.0 : -1.0;
        final at = _understoryQuad(b, k1, k2, (k + .3) / 6);
        final d = _understoryTan(b, k1, k2, (k + .3) / 6);
        final axis = d * .5 + Offset(-d.dy, d.dx) * (side * .85);
        final z = s * (.34 - .03 * k);
        _understoryBract(c, at, at + axis / axis.distance * z, Offset(side * .6, .8), f);
      }
    }
  }

  /// One boat-shaped heliconia bract: red with a shaded belly, a golden lip
  /// and a green tip. The belly bulges towards [belly].
  static void _understoryBract(
    Canvas c,
    Offset p,
    Offset tip,
    Offset belly,
    Color Function(int) f,
  ) {
    final axis = tip - p;
    final z = axis.distance;
    var perp = Offset(-axis.dy, axis.dx) / z;
    if (perp.dx * belly.dx + perp.dy * belly.dy < 0) perp = -perp;
    final mid = (p + tip) / 2;
    final bel = mid + perp * (z * .38);
    final inner = mid - perp * (z * .06);
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(bel.dx, bel.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(inner.dx, inner.dy, p.dx, p.dy)
        ..close(),
      Paint()..color = f(0xffe2442f),
    );
    final mid2 = mid + perp * (z * .15);
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(bel.dx, bel.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(mid2.dx, mid2.dy, p.dx, p.dy)
        ..close(),
      Paint()..color = f(0xffb52a2c),
    );
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(inner.dx, inner.dy, tip.dx, tip.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, z * .09)
        ..strokeCap = StrokeCap.round
        ..color = f(0xfff0c445),
    );
    c.drawCircle(
      tip - axis * .04,
      math.max(.8, z * .085),
      Paint()..color = f(0xff86c04c),
    );
  }

  /// A bromeliad: strap leaves swirling out of a flushed coral heart.
  static void _understoryBromeliad(Canvas c, Offset base, double s, {double fog = 0}) {
    Color f(int v) => _understoryFog(Color(v), fog);
    for (final (a, len, tier) in const [
      (-2.95, .8, 0),
      (-.2, .82, 0),
      (-2.5, .9, 0),
      (-.65, .92, 0),
      (-2.1, .95, 1),
      (-1.05, .98, 1),
      (-1.78, .8, 2),
      (-1.36, .86, 2),
    ]) {
      final dir = Offset(math.cos(a), math.sin(a));
      final tip = base + dir * (s * len) + Offset(0, s * .2 * (1 + math.cos(a).abs()));
      final ctl = base + dir * (s * len * .5) - Offset(0, s * len * .3);
      final (lit, shade, rib) = switch (tier) {
        0 => (f(0xff3f9457), f(0xff236a42), f(0xff8fc67c)),
        1 => (f(0xffa2a04c), f(0xff62823c), f(0xffd9d78a)),
        _ => (f(0xffe2664f), f(0xffb03c48), f(0xfff6a58c)),
      };
      _understoryBlade(c, base, ctl, tip, s * .1, lit: lit, shade: shade, rib: rib, veins: 0, belly: .3, tipPow: .55, fine: false);
    }
  }

  /// An orchid spike: an arching stem of magenta blossoms, buds at the tip,
  /// two strap leaves at its foot.
  static void _understoryOrchid(Canvas c, Offset base, double s, {double fog = 0}) {
    Color f(int v) => _understoryFog(Color(v), fog);
    for (final side in const [-1.0, 1.0]) {
      _understoryBlade(
        c,
        base + Offset(side * s * .02, 0),
        base + Offset(side * s * .26, -s * .36),
        base + Offset(side * s * .52, -s * .1),
        s * .055,
        lit: f(0xff4fa860),
        shade: f(0xff2a7a48),
        rib: f(0xffb4e08e),
        veins: 0,
        belly: .4,
        tipPow: .6,
        fine: false,
      );
    }
    final a = base, q = base + Offset(-s * .16, -s * .78), b = base + Offset(s * .3, -s * 1.02);
    c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(q.dx, q.dy, b.dx, b.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, s * .02)
        ..strokeCap = StrokeCap.round
        ..color = f(0xff4a8a48),
    );
    final petal = Paint()..color = f(0xffcf62b2);
    final petalLit = Paint()..color = f(0xffee9fd6);
    final lip = Paint()..color = f(0xfffff0f6);
    final eye = Paint()..color = f(0xfff0c44e);
    final bud = Paint()..color = f(0xff9ab86a);
    for (var i = 0; i < 9; i++) {
      final t = .38 + .6 * i / 8;
      final p = _understoryQuad(a, q, b, t);
      final r = s * (.05 - .03 * (i / 8));
      if (i > 5) {
        c.drawCircle(p + Offset(r * .3, 0), r * .55, i > 6 ? bud : petal);
        continue;
      }
      final o = p + Offset((i.isEven ? -1 : 1) * r * .5, r * .2);
      for (var k = 0; k < 5; k++) {
        final ang = -math.pi / 2 + k * math.pi * 2 / 5;
        c.drawCircle(o + Offset(math.cos(ang), math.sin(ang)) * (r * .55), r * .56, k == 0 || k == 4 ? petalLit : petal);
      }
      c.drawCircle(o + Offset(0, r * .12), r * .34, lip);
      c.drawCircle(o + Offset(0, r * .05), r * .13, eye);
    }
  }

  /// A cluster of toadstools on a mossy foot. [kind]: 0 ochre, 1 cream,
  /// 2 lilac.
  static void _understoryMushrooms(Canvas c, Offset base, double s, {int seed = 0, int kind = 0}) {
    final (cap, capLit, capShade, spot) = switch (kind) {
      1 => (const Color(0xffe4d8bc), const Color(0xfffaf0da), const Color(0xffb9a985), const Color(0xffffffff)),
      2 => (const Color(0xff9a82be), const Color(0xffc4b0e0), const Color(0xff76609e), const Color(0xffe8def5)),
      _ => (const Color(0xffc48650), const Color(0xffe8b07a), const Color(0xff97663a), const Color(0xfff4e2bd)),
    };
    for (final (dx, tall, r) in const [
      (.62, .55, .3),
      (-.5, .9, .5),
      (0.0, 1.2, .62),
      (.28, .6, .32),
    ]) {
      final x = base.dx + dx * s;
      final top = base.dy - tall * s;
      final sw = r * s * .3;
      c.drawPath(
        Path()
          ..moveTo(x - sw, base.dy)
          ..quadraticBezierTo(x - sw * .6, top + s * .3, x - sw * .7, top)
          ..lineTo(x + sw * .7, top)
          ..quadraticBezierTo(x + sw * .6, top + s * .3, x + sw, base.dy)
          ..close(),
        Paint()..color = const Color(0xffe9dfc2),
      );
      c.drawPath(
        Path()
          ..moveTo(x + sw * .1, base.dy)
          ..quadraticBezierTo(x + sw * .2, top + s * .3, x + sw * .1, top)
          ..lineTo(x + sw * .7, top)
          ..quadraticBezierTo(x + sw * .6, top + s * .3, x + sw, base.dy)
          ..close(),
        Paint()..color = const Color(0xffc5b78f),
      );
      final rr = r * s;
      final cy = top;
      // Gills under the cap, then the dome and its lit shoulder.
      c.drawOval(Rect.fromCenter(center: Offset(x, cy + rr * .12), width: rr * 2, height: rr * .55), Paint()..color = capShade);
      c.drawPath(
        Path()
          ..moveTo(x - rr, cy + rr * .12)
          ..cubicTo(x - rr * 1.02, cy - rr * 1.1, x + rr * 1.02, cy - rr * 1.1, x + rr, cy + rr * .12)
          ..quadraticBezierTo(x, cy + rr * .34, x - rr, cy + rr * .12)
          ..close(),
        Paint()..color = cap,
      );
      c.drawOval(Rect.fromCenter(center: Offset(x - rr * .35, cy - rr * .45), width: rr * .8, height: rr * .38), Paint()..color = Sketch.fade(capLit, .85));
      if (kind != 2) {
        final dot = Paint()..color = spot;
        c.drawCircle(Offset(x + rr * .3, cy - rr * .35), rr * .11, dot);
        c.drawCircle(Offset(x + rr * .62, cy - rr * .1), rr * .08, dot);
      }
    }
    // Moss cushion round the foot.
    c.drawOval(Rect.fromCenter(center: base + Offset(0, s * .02), width: s * 1.6, height: s * .22), Paint()..color = const Color(0xff3c7a44));
    c.drawOval(Rect.fromCenter(center: base + Offset(-s * .15, -s * .01), width: s * .9, height: s * .12), Paint()..color = const Color(0xff6ab058));
  }

  /// A mossy fallen log lying across the forest floor, its sawn end towards
  /// the sun, with bracket fungi and a fern growing from the top.
  static void _understoryLog(Canvas c, Offset at, double len, double r, {int seed = 0}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.drawOval(
      Rect.fromCenter(center: Offset(0, r * .8), width: len * 1.1, height: r * .8),
      Paint()..color = const Color(0x5510301f),
    );
    c.rotate(-.025);
    double top(double x) => -r * (.86 + .09 * math.sin(x / r * 1.7 + seed) + .05 * math.sin(x / r * 4.1));
    const n = 14;
    final upper = [for (var i = 0; i <= n; i++) Offset(-len / 2 + len * i / n, top(-len / 2 + len * i / n))];
    final lower = [for (var i = n; i >= 0; i--) Offset(-len / 2 + len * i / n, r * (.72 + .08 * math.sin(i * 1.3)))];
    final body = Path()..moveTo(upper.first.dx, upper.first.dy);
    _understorySmooth(body, upper);
    _understorySmooth(body, lower);
    body.close();
    c.drawPath(body, Paint()..color = const Color(0xff4a3a2c));
    // Sun-facing upper flank.
    final flank = Path()..moveTo(upper.first.dx, upper.first.dy);
    _understorySmooth(flank, upper);
    _understorySmooth(flank, [for (var i = n; i >= 0; i--) Offset(-len / 2 + len * i / n, -r * .1 + r * .07 * math.sin(i * 1.9 + seed))]);
    c.drawPath(flank..close(), Paint()..color = const Color(0xff7c6248));
    final band = Path()..moveTo(upper.first.dx, upper.first.dy + r * .1);
    _understorySmooth(band, [for (final p in upper) p + Offset(0, r * .12)]);
    _understorySmooth(band, [for (var i = n; i >= 0; i--) Offset(-len / 2 + len * i / n, -r * .5)]);
    c.drawPath(band..close(), Paint()..color = Sketch.fade(const Color(0xffa48462), .6));
    // Bark furrows.
    final furrow = Path();
    for (var i = 0; i < 9; i++) {
      final y = -r * .55 + r * 1.1 * Sketch.hash(seed * 11 + i);
      final x0 = -len * .48 + len * .9 * Sketch.hash(seed * 13 + i);
      final l = len * (.08 + .16 * Sketch.hash(seed * 17 + i));
      furrow
        ..moveTo(x0, y)
        ..quadraticBezierTo(x0 + l * .5, y + r * .05, x0 + l, y - r * .02);
    }
    c.drawPath(
      furrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, r * .08)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(const Color(0xff2c2118), .7),
    );
    final scales = Path();
    for (var i = 0; i < 26; i++) {
      final x = -len * .46 + len * .92 * Sketch.hash(seed * 19 + i);
      final y = -r * .78 + r * .7 * Sketch.hash(seed * 23 + i);
      scales
        ..moveTo(x, y)
        ..lineTo(x + r * (.14 + .2 * Sketch.hash(seed * 29 + i)), y - r * .01);
    }
    c.drawPath(
      scales,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, r * .06)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x88b89a74),
    );
    // Moss blankets the top.
    final mossDark = Path(), mossLit = Path();
    for (var i = 0; i < 18; i++) {
      final x = -len * .45 + len * .92 * (i + .5 * Sketch.hash(seed * 3 + i)) / 18;
      if (Sketch.hash(seed * 5 + i) < .22) continue;
      final rad = r * (.2 + .22 * Sketch.hash(seed * 7 + i));
      final y = top(x) + rad * .3;
      mossDark.addOval(Rect.fromCenter(center: Offset(x, y), width: rad * 2.3, height: rad * 1.4));
      mossLit.addOval(Rect.fromCenter(center: Offset(x - rad * .3, y - rad * .3), width: rad * 1.3, height: rad * .7));
    }
    c.drawPath(mossDark, Paint()..color = const Color(0xff3f8447));
    c.drawPath(mossLit, Paint()..color = const Color(0xff7dbd5c));
    // The sawn end: pale wood, growth rings, a dark heart.
    final end = Rect.fromCenter(center: Offset(-len / 2, -r * .06), width: r * .8, height: r * 1.62);
    c.drawOval(end, Paint()..color = const Color(0xffcaa678));
    for (var k = 1; k <= 3; k++) {
      c.drawOval(
        Rect.fromCenter(center: end.center + Offset(r * .03, r * .02), width: end.width * (1 - k * .24), height: end.height * (1 - k * .24)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, r * .04)
          ..color = Sketch.fade(const Color(0xff8c6a40), .75),
      );
    }
    c.drawOval(Rect.fromCenter(center: end.center, width: end.width * .5, height: end.height * .15), Paint()..color = const Color(0xffa07c4e));
    c.drawOval(end, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.6, r * .07)..color = const Color(0xff5e4632));
    // Bracket fungi, stacked up the flank.
    for (final (fx, fy, fs, warm) in const [(.2, -.45, .5, true), (.29, -.1, .38, true), (.78, -.4, .42, false)]) {
      final p = Offset(-len / 2 + len * fx, r * fy);
      final w = r * fs * 1.1;
      c.drawPath(
        Path()
          ..moveTo(p.dx - w, p.dy)
          ..quadraticBezierTo(p.dx - w * .7, p.dy - w * .75, p.dx + w * .1, p.dy - w * .55)
          ..quadraticBezierTo(p.dx + w * .9, p.dy - w * .4, p.dx + w, p.dy + w * .1)
          ..quadraticBezierTo(p.dx, p.dy + w * .3, p.dx - w, p.dy)
          ..close(),
        Paint()..color = warm ? const Color(0xffe6b06a) : const Color(0xffe2dcc6),
      );
      c.drawPath(
        Path()
          ..moveTo(p.dx - w * .75, p.dy - w * .1)
          ..quadraticBezierTo(p.dx, p.dy - w * .48, p.dx + w * .8, p.dy - w * .05),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, w * .1)
          ..color = warm ? const Color(0xffb77a3e) : const Color(0xffa9a088),
      );
      c.drawPath(
        Path()
          ..moveTo(p.dx - w, p.dy)
          ..quadraticBezierTo(p.dx, p.dy + w * .3, p.dx + w, p.dy + w * .1)
          ..quadraticBezierTo(p.dx, p.dy + w * .55, p.dx - w, p.dy)
          ..close(),
        Paint()..color = const Color(0xff8a6a48),
      );
    }
    c.restore();
  }

  /// A young seedling: a pale stalk, a pair of round seed leaves and the
  /// first true leaves.
  static void _understorySeedling(Canvas c, Offset base, double s, {int seed = 0}) {
    final lean = (Sketch.hash(seed) - .5) * .5;
    final top = base + Offset(lean * s * .4, -s * .8);
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx, base.dy - s * .5, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, s * .06)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xffa2cf7a),
    );
    final seedLeaf = Paint()..color = const Color(0xff5db35f);
    final seedLit = Paint()..color = const Color(0xff8fd478);
    for (final side in const [-1.0, 1.0]) {
      final p = top + Offset(side * s * .3, s * .02);
      c.drawOval(Rect.fromCenter(center: p, width: s * .6, height: s * .34), side < 0 ? seedLit : seedLeaf);
    }
    for (final side in const [-1.0, 1.0]) {
      _understoryBlade(
        c,
        top + Offset(0, -s * .02),
        top + Offset(side * s * .2, -s * .35),
        top + Offset(side * s * .42, -s * .34),
        s * .13,
        lit: const Color(0xff6cc36a),
        shade: const Color(0xff2f8d52),
        rib: const Color(0xffcaf0a0),
        veins: 0,
        belly: .4,
        tipPow: .6,
        fine: false,
      );
    }
  }

  /// A red-eyed tree frog perched on the log, facing the sun. [p] is the
  /// spot between its feet.
  static void _understoryFrog(Canvas c, Offset p, double s, {bool blink = false}) {
    Offset o(double x, double y) => p + Offset(x * s, y * s);
    final body = Paint()..color = const Color(0xff58b447);
    final toe = Paint()..color = const Color(0xfff08b2c);
    // Hind leg folded along the flank, then its orange toes.
    c.drawOval(Rect.fromCenter(center: o(.3, -.26), width: s * .62, height: s * .36), Paint()..color = const Color(0xff3f9a3c));
    for (var k = 0; k < 3; k++) {
      c.drawOval(Rect.fromCenter(center: o(.5 + k * .12, -.03 + k * .01), width: s * .14, height: s * .07), toe);
    }
    c.drawOval(Rect.fromCenter(center: o(.06, -.42), width: s * 1.05, height: s * .64), body);
    c.drawOval(Rect.fromCenter(center: o(-.04, -.27), width: s * .8, height: s * .28), Paint()..color = const Color(0xffd3e9ac));
    c.drawOval(Rect.fromCenter(center: o(.02, -.62), width: s * .8, height: s * .2), Paint()..color = const Color(0xff86cf5a));
    c.drawOval(Rect.fromCenter(center: o(.16, -.4), width: s * .42, height: s * .07), Paint()..color = const Color(0xff4a80d8));
    // Head, both bulging red eyes, and the front leg with its toes.
    c.drawOval(Rect.fromCenter(center: o(-.34, -.5), width: s * .56, height: s * .4), Paint()..color = const Color(0xff62bd4e));
    for (final (ex, ey, er) in const [(-.16, -.74, .13), (-.4, -.72, .17)]) {
      c.drawCircle(o(ex, ey), s * er * 1.12, body);
      c.drawCircle(o(ex, ey), s * er * .86, Paint()..color = const Color(0xffe23a34));
      c.drawOval(Rect.fromCenter(center: o(ex, ey), width: s * er * .32, height: s * er * 1.3), Paint()..color = const Color(0xff1c2a1a));
    }
    if (blink) c.drawCircle(o(-.4, -.72), s * .19, body);
    c.drawCircle(o(-.44, -.77), s * .03, Paint()..color = const Color(0xfffff8e8));
    c.drawLine(o(-.2, -.28), o(-.27, -.02), Paint()..color = const Color(0xff4ea63f)..strokeWidth = s * .09..strokeCap = StrokeCap.round);
    for (var k = 0; k < 3; k++) {
      c.drawCircle(o(-.36 + k * .09, -.01), s * .05, toe);
    }
  }

  /// A garden snail crossing the moss, its shell a spiral.
  static void _understorySnail(Canvas c, Offset p, double s) {
    Offset o(double x, double y) => p + Offset(x * s, y * s);
    final stalk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, s * .07)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xffc9bd9c);
    c.drawOval(Rect.fromCenter(center: o(0, -.14), width: s * 1.5, height: s * .3), Paint()..color = const Color(0xffdbcfae));
    c.drawCircle(o(-.68, -.28), s * .18, Paint()..color = const Color(0xffdbcfae));
    c.drawLine(o(-.72, -.4), o(-.82, -.72), stalk);
    c.drawLine(o(-.6, -.4), o(-.6, -.7), stalk);
    c.drawCircle(o(-.82, -.74), s * .06, Paint()..color = const Color(0xff3a3020));
    c.drawCircle(o(-.6, -.72), s * .06, Paint()..color = const Color(0xff3a3020));
    c.drawCircle(o(.2, -.55), s * .52, Paint()..color = const Color(0xffc98846));
    c.drawCircle(o(.14, -.62), s * .3, Paint()..color = const Color(0xffe1a866));
    final spiral = Path()..moveTo(o(.2, -.55).dx, o(.2, -.55).dy);
    for (var i = 1; i <= 14; i++) {
      final th = i / 14 * math.pi * 3.4;
      final r = s * .46 * i / 14;
      spiral.lineTo(o(.2, -.55).dx + math.cos(th) * r, o(.2, -.55).dy + math.sin(th) * r);
    }
    c.drawPath(
      spiral,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .06)
        ..color = const Color(0xff8b5a2a),
    );
  }
}
