import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_backdrop.dart';
import 'world_region.dart';

/// Paris at blue hour: Haussmann rooftops, the Invalides dome and the
/// basilica of Sacré-Cœur on the horizon, the Eiffel Tower glittering over
/// the roofs beside the Arc de Triomphe, the Seine under a stone bridge with
/// a river boat sweeping its floodlight along the quay, and gas lamps and
/// plane trees on the promenade. Stars twinkle over a moon that lights every
/// façade from the right.
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

  // The plane-tree leaves are the scene's own (autumn-coloured, falling from
  // the crowns; see `_sfLeaves`), so the shared weather keeps only a few
  // fireflies to stand in for the bokeh of the lamps.
  static final _weather = Weather(
    Weather.of([(Mote.firefly, 5)]),
  );
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xff8a7ca8);
  static const _gold = Color(0xffffcf6a);
  static const _moonlit = Color(0xfff2ecd0);

  /// Lamp, bench and tree stations along the promenade, as period fractions.
  static const _lamps = [.12, .42, .72];
  // Each bench keeps a lamp's company, close enough for its pool of light.
  static const _benches = [.372, .757];
  static const _trees = [.27, .57, .88];

  /// One shared paint for the per-frame draws; every call reads it at once.
  static final _ink = Paint();
  static Paint _paint(Color c) => _ink..color = c;

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
    Depth.far => .69 + Sketch.waves(x, const [(2.4, .003, .5)]),
    Depth.mid => .74,
    Depth.low => .82 + .004 * math.sin(x * math.pi * 4 + clock * 1.3),
    Depth.near => .935 - .006 * Sketch.humps(x / 1.5),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    // The tower is over half a viewport tall and must clear its ridge.
    Depth.mid => .6,
    Depth.low => .2,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  /// Landmark stations in viewport coordinates of the timed bands.
  static Offset _tower(double w, double h) => Offset(w * .66, h * .76);

  /// The Arc's foot sits a hair under the mid ridge (.74 h), so its plinth is
  /// hidden and the flame stands on the ridge line. [base] is the centre of
  /// its depth: the eternal flame is at `base.dx`.
  static Offset _arcAt(double w, double h) =>
      Offset(math.max(w * .14, h * .1), h * .745);

  /// The Arc's height in viewport heights, and the share of its width that
  /// the shaded left flank takes (it is seen a little from the left).
  static const _arcScale = .15;
  static const _arcFlank = .17;

  /// The flame's own paint, so nothing else can leave a shader or a stroke
  /// style on it between frames.
  static final _arcInk = Paint();

  /// The relief groups on the piers as (across, up) pairs in monument
  /// heights, up being negative, from the middle of the pedestal top: a
  /// winged genius over the volunteers of 1792, and the crowned victor of
  /// 1810 with a victory beside him. Cuts are drapery strokes as (from, to)
  /// pairs and heads are single points.
  static const _arcGroupA = <double>[
    -.092, 0, -.094, -.09, -.082, -.18, -.09, -.24, -.066, -.29, -.05, -.32,
    -.03, -.355, -.024, -.39, -.05, -.42, -.09, -.47, -.04, -.465, -.018, -.445,
    -.014, -.49, 0, -.52, .014, -.49, .018, -.445, .04, -.465, .09, -.47,
    .05, -.42, .024, -.39, .03, -.355, .05, -.32, .066, -.29, .09, -.24,
    .082, -.18, .094, -.09, .092, 0,
  ];
  static const _arcCutsA = <double>[
    -.05, -.30, -.02, -.36, .05, -.30, .022, -.37, -.07, -.16, -.03, -.26,
    .07, -.16, .03, -.25, -.02, -.02, -.015, -.20, .02, -.02, .012, -.19,
  ];
  static const _arcHeadsA = <double>[-.042, -.30, .044, -.30, 0, -.47];
  static const _arcGroupB = <double>[
    -.09, 0, -.092, -.08, -.075, -.16, -.085, -.22, -.06, -.26, -.05, -.30,
    -.035, -.33, -.03, -.38, -.045, -.41, -.07, -.45, -.02, -.435, -.012, -.47,
    0, -.50, .02, -.475, .03, -.44, .08, -.46, .05, -.40, .04, -.35,
    .05, -.31, .07, -.26, .088, -.20, .09, -.12, .092, 0,
  ];
  static const _arcCutsB = <double>[
    -.055, -.20, -.02, -.28, .05, -.20, .02, -.30, -.03, -.03, -.02, -.18,
    .03, -.03, .025, -.16, 0, -.34, 0, -.42,
  ];
  static const _arcHeadsB = <double>[-.045, -.26, 0, -.41, .035, -.33];

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        // Timed bands drift left over a region's leg, so the rows run well
        // past both edges.
        // The far ridge dips to .687 h at its lowest crest.
        _row(c, -h * .2, w + h * .3, h * .72, h, .55, 1, .07, cut: h * .687);
        _basilica(c, Offset(math.max(w * .33, h * .17), h * .7), h);
        // Too crowded beside the basilica on a narrow portrait screen.
        if (w > h * 1.1) _invalides(c, Offset(w * .48, h * .7), h);
      case Depth.mid:
        _row(c, -h * .25, w + h * .55, h * .755, h, .25, 2, .085, detail: true, cut: h * _quayTop);
        _quay(c, -h * .25, w + h * .55, h);
        _eiffel(c, _tower(w, h), _eiffelSize(h));
        _arc(c, _arcAt(w, h), h * _arcScale);
      case Depth.low:
        break;
      case Depth.near:
        final span = period(d) * h;
        for (final fx in _benches) {
          _bench(c, Offset(span * fx, _ground(d, span * fx, h)), h * .058);
        }
        for (var i = 0; i < _trees.length; i++) {
          final px = span * _trees[i];
          _plane(c, Offset(px, _ground(d, px, h)), h * .21, seed: i);
        }
        for (final fx in _lamps) {
          _lamp(c, Offset(span * fx, _ground(d, span * fx, h)), h * .13);
        }
    }
  }

  /// The pavement height under a near-band prop at world x [px]: a hair below
  /// the ridge line, so the terrain fill hides each prop's foot.
  double _ground(Depth d, double px, double h) => ridge(d, px / h, 0) * h + h * .005;

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.low) return;
    final h = f.h, span = period(d) * h;
    final x = _boatX(f.clock, h, span);
    // The boat fades in and out at the seam so its lap never pops.
    final edge = math.min(x, span - x) / (h * .3);
    final a = RegionBlend.smooth(edge);
    // Copies that sit far off screen skip the boat. It is hulled at the water
    // line, pitching a little with the swell under its keel.
    final scroll = f.reducedMotion ? 0.0 : f.distance * d.parallax * h;
    final onScreen = x + copy * span - scroll;
    if (a > 0 && onScreen > -h * .6 && onScreen < f.w + h * .6) {
      final s = h * .06;
      final slope =
          (ridge(d, (x + s) / h, f.clock) - ridge(d, (x - s) / h, f.clock)) * h / (2 * s);
      _boat(c, x, ridge(d, x / h, f.clock) * h, s, a, f.clock, pitch: math.atan(slope));
    }
    // The bridge comes after the boat, which sails behind its arches.
    final cx = span * .5;
    _bridge(c, cx, ridge(d, cx / h, 0) * h, h);
  }

  static double _boatX(double clock, double h, double span) =>
      (h * .3 + clock * h * .03) % span;

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.mid:
        // The tower's hourly glitter, its turning beacon and floodlights.
        _eiffelLive(c, _tower(f.w, h), h, f.clock, presence);
        // The eternal flame under the Arc de Triomphe.
        _arcGlow(c, _arcAt(f.w, h), h * _arcScale, f.clock, presence);
      case Depth.low:
        final span = period(d) * h;
        final cx = span * .5;
        final water = ridge(d, cx / h, 0) * h;
        _seineBridgeShadow(c, cx, water, h, presence);
        _bridgeReflection(c, cx, water, h, f.clock, presence);
        // Bridge lamps glow, and their light lies on the water below.
        for (var i = 0; i < _bridgeLamps; i++) {
          final x = _bridgeLampX(cx, h, i);
          final y = water - h * _bridgeGlobeV;
          Sketch.mist(
            c,
            Rect.fromCenter(center: Offset(x, y), width: h * .09, height: h * .09),
            _gold,
            .5 * presence,
          );
          // The globes hang about h*.11 over the water, so their reflection
          // runs deep (to the near bank), breaking into wider dashes.
          _seineColumn(c, x, water + h * .012, h, f.clock, i * 1.9, _gold, .55 * presence, depth: .095);
        }
        // The boat's bow wave, wash and lit reflections lie on the water.
        final bx = _boatX(f.clock, h, span);
        final a = RegionBlend.smooth(math.min(bx, span - bx) / (h * .3));
        final scroll = f.reducedMotion ? 0.0 : f.distance * d.parallax * h;
        final u = (bx - scroll) % span;
        if (a > 0 && (u < f.w + h * .6 || u > span - h * .6)) {
          _boatWake(c, f, bx, a * presence);
        }
      case Depth.near:
        final span = period(d) * h;
        // The cobbled paving with the props' shadows and fallen leaves, one
        // cached picture per viewport height.
        final paving = _sfPavingFor(h);
        if (presence < .999) {
          c.saveLayer(
            Rect.fromLTRB(0, h * .92, span, h * 1.02),
            Paint()..color = Color.fromRGBO(0, 0, 0, math.max(0.0, presence)),
          );
          c.drawPicture(paving);
          c.restore();
        } else {
          c.drawPicture(paving);
        }
        for (var i = 0; i < _lamps.length; i++) {
          final x = span * _lamps[i];
          final ground = _ground(d, x, h);
          final edge = ridge(d, x / h, 0) * h;
          // Gas flames breathe a little, each on its own beat.
          final flicker = .95 +
              .04 * math.sin(f.clock * 7 + i * 3.1) +
              .025 * math.sin(f.clock * 12.7 + i * 1.3);
          final lantern = Offset(x, ground - h * .13 * _sfLanternAt);
          _sfGlow(c, _sfHalo, _gold, .36, lantern, h * .15 * flicker, h * .15 * flicker, presence);
          _sfGlow(c, _sfCore, _sfWhite, .75, lantern, h * .05 * flicker, h * .05 * flicker, presence);
          // The soft starburst of a lit mantle.
          _sfGlow(c, _sfHalo, _gold, .36, lantern, h * .08 * flicker, h * .006, presence);
          _sfGlow(c, _sfHalo, _gold, .36, lantern, h * .006, h * .055 * flicker, presence);
          // A pool of light on the paving, and its glints on the wet stones.
          _sfGlow(c, _sfPool, _gold, .3, Offset(x, edge + h * .022), h * .19, h * .034, presence);
          for (var k = 0; k < 3; k++) {
            final sway = math.sin(f.clock * 1.6 + i * 2.1 + k * 2.3) * h * .004;
            final len = h * (.02 - k * .004);
            final gy = edge + h * (.014 + k * .014);
            c.drawLine(
              Offset(x - len + sway, gy),
              Offset(x + len + sway, gy),
              _paint(Sketch.fade(_gold, (.42 - k * .1) * flicker * presence))
                ..strokeCap = StrokeCap.round
                ..strokeWidth = h * .0026,
            );
          }
        }
        _sfLeaves(c, h, span, f.clock, presence);
      case Depth.far:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, clock = f.clock;
    // The water is one plane under several scrolling bands: ripples follow
    // the low band, while the far bank (a timed band, drifting on its own
    // clock) carries its lamps and the tower along, so each reflection stays
    // under the thing that casts it. The water lies between the ridge and the
    // near bank.
    final scroll = f.reducedMotion ? 0.0 : f.distance * Depth.low.parallax * h;
    final start = f.blend.startOf(WorldRegion.paris);
    final far = f.reducedMotion
        ? 0.0
        : (f.seconds - start) * WorldBackdrop.cruise * Depth.mid.parallax * h;
    // A campaign level repeats the far bank, so every copy casts its lamps
    // and its tower, each inside its own stretch of the bank.
    final copies = WorldBackdrop.copies(f, Depth.mid).toList();
    void cast(void Function(double far) reflect) {
      for (final copy in copies) {
        if (f.held) {
          c.save();
          c.clipRect(Rect.fromLTRB(copy.from, 0, copy.to, h));
        }
        reflect(far - copy.shift);
        if (f.held) c.restore();
      }
    }

    _seineSheen(c, f, scroll, presence);
    _seineRipples(c, w, h, clock, scroll, presence);
    cast((far) => _seineFarBank(c, w, h, clock, far, presence));
    _seineLights(c, w, h, far, presence);
    cast((far) => _seineTower(c, w, h, clock, far, presence));
    _seineMoon(c, light.at.dx * w, h, clock, presence);
    _seineGlints(c, w, h, clock, scroll, presence);
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final moon = Offset(light.at.dx * w, light.at.dy * h);
    for (var i = 0; i < 46; i++) {
      final p = Offset(w * Sketch.hash(i + 200), h * .44 * Sketch.hash(i + 201));
      // The moon's glare hides its neighbours; the horizon glow drowns the
      // low stars.
      if ((p - moon).distance < h * .1) continue;
      final low = 1 - p.dy / (h * .44);
      final twinkle = .55 + .45 * math.sin(f.clock * (.8 + Sketch.hash(i) * 1.6) + i);
      c.drawCircle(
        p,
        h * (.0012 + .0018 * Sketch.hash(i + 202)),
        _paint(Sketch.fade(const Color(0xfffff6e0), .85 * twinkle * low * presence)),
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
    // Low streaks still holding the last rose of the sunset.
    for (final (fx, fy, fw) in const [(.12, .53, .55), (.62, .57, .7)]) {
      final x = (w * fx - f.clock * h * .003) % (w + h) - h * .5;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .035),
        const Color(0xffd98f9a),
        .32 * presence,
      );
    }
  }

  /// A row of Haussmann blocks: cream limestone façades with tall shuttered
  /// windows, the continuous iron balconies of the second and fifth floors,
  /// zinc mansards with dormers and clusters of chimney pots, corner
  /// buildings and streets between the blocks (see [_HbRow]). [tall] is the
  /// height of a five-floor block up to its cornice, in viewport heights;
  /// [haze] pushes the row into the distance; [detail] marks the nearer row,
  /// whose bays are drawn larger. Below [cut] the ridge hides the row, so
  /// nothing is drawn there.
  static void _row(
    Canvas c,
    double x0,
    double x1,
    double baseY,
    double h,
    double haze,
    int seed,
    double tall, {
    bool detail = false,
    double cut = double.infinity,
  }) => _HbRow(c, baseY, h, haze, seed, tall, detail, cut).paint(x0, x1);

  /// A dome lit from the right, where the moon is. A gradient rounds the shell
  /// from [shade] on the left through [body] to [lit], a bright crescent rims
  /// the lit flank and [ribs] climb it, each given as the sine of its azimuth
  /// (a meridian of the shell is the silhouette curve squeezed toward the
  /// axis). The flank leaves the vertical at [bulge] of the height and bends
  /// in through ([crownX], [crownY]), which sets how pointed the crown is;
  /// [tip] is the width kept at the top for a lantern to stand on.
  static void _dome(
    Canvas c,
    Offset base,
    double hw,
    double ht,
    Color body,
    Color lit, {
    Color? shade,
    List<double> ribs = const [],
    double bulge = .5,
    double crownX = .3,
    double crownY = .82,
    double tip = 0,
  }) {
    final x = base.dx, y = base.dy;
    final dark = shade ?? Sketch.mix(body, const Color(0xff2a2748), .35);
    // One flank from the springing to the crown; [k] squeezes it toward the
    // axis (negative on the left), which traces a meridian of the shell.
    Path flank(double k) => Path()
      ..moveTo(x + hw * k, y)
      ..cubicTo(
        x + hw * k,
        y - ht * bulge,
        x + hw * crownX * k,
        y - ht * crownY,
        x + hw * tip * k,
        y - ht,
      );
    c.drawPath(
      Path()
        ..moveTo(x - hw, y)
        ..cubicTo(
          x - hw,
          y - ht * bulge,
          x - hw * crownX,
          y - ht * crownY,
          x - hw * tip,
          y - ht,
        )
        ..lineTo(x + hw * tip, y - ht)
        ..cubicTo(
          x + hw * crownX,
          y - ht * crownY,
          x + hw,
          y - ht * bulge,
          x + hw,
          y,
        )
        ..close(),
      Paint()
        ..shader = Gradient.linear(
          Offset(x - hw, y),
          Offset(x + hw, y),
          [dark, body, lit],
          const [0, .52, .9],
        ),
    );
    // The moon catches the right edge in a thin bright crescent.
    final rim = Sketch.mix(lit, const Color(0xffffffff), .4);
    c.drawPath(
      Path()
        ..moveTo(x + hw, y)
        ..cubicTo(
          x + hw,
          y - ht * bulge,
          x + hw * crownX,
          y - ht * crownY,
          x + hw * tip,
          y - ht,
        )
        ..cubicTo(
          x + hw * crownX * .82,
          y - ht * crownY,
          x + hw * .82,
          y - ht * bulge,
          x + hw * .82,
          y,
        )
        ..close(),
      Paint()..color = Sketch.fade(rim, .85),
    );
    if (ribs.isNotEmpty) {
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, hw * .06);
      for (final k in ribs) {
        final a = (k + 1) / 2;
        // Each rib is a fine groove with a lit edge on its right.
        c.drawPath(flank(k), line..color = Sketch.fade(dark, .3 + .3 * a));
        c.drawPath(flank(k + .06), line..color = Sketch.fade(rim, .12 + .28 * a));
      }
    }
    // The cornice below throws a soft shadow up the springing.
    c.drawRect(
      Rect.fromLTRB(x - hw, y - ht * .07, x + hw, y),
      Paint()..color = Sketch.fade(dark, .4),
    );
  }

  /// A rect rounded by light: [shade] on the left through [body] to [lit].
  static void _domedFace(Canvas c, Rect r, Color shade, Color body, Color lit) {
    c.drawRect(
      r,
      Paint()
        ..shader = Gradient.linear(
          r.centerLeft,
          r.centerRight,
          [shade, body, lit],
          const [0, .5, .92],
        ),
    );
  }

  /// A projecting cornice centred on [x], its bottom edge at [y]: a lit top,
  /// a face and a shadowed underside.
  static void _domedBand(
    Canvas c,
    double x,
    double y,
    double hw,
    double thick,
    Color body,
    Color lit,
    Color shade,
  ) {
    final fill = Paint()..color = body;
    c.drawRect(Rect.fromLTRB(x - hw, y - thick, x + hw, y), fill);
    c.drawRect(
      Rect.fromLTRB(x - hw * .2, y - thick, x + hw, y - thick * .62),
      fill..color = lit,
    );
    c.drawRect(
      Rect.fromLTRB(x - hw, y - thick * .32, x + hw, y),
      fill..color = shade,
    );
  }

  /// A round-headed opening filling [r].
  static void _domedArch(Canvas c, Rect r, Color color) {
    final head = Radius.circular(r.width / 2);
    c.drawRRect(
      RRect.fromRectAndCorners(r, topLeft: head, topRight: head),
      Paint()..color = color,
    );
  }

  /// A small cross on a finial: [len] tall from [base].
  static void _domedCross(Canvas c, Offset base, double len, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(.7, len * .12)
      ..strokeCap = StrokeCap.round;
    c.drawLine(base, base + Offset(0, -len), paint);
    c.drawLine(
      base + Offset(-len * .3, -len * .68),
      base + Offset(len * .3, -len * .68),
      paint,
    );
  }

  /// A tiny four-point glint, the last light catching gilding.
  static void _domedGlint(Canvas c, Offset p, double r, Color color) {
    Sketch.mist(c, Rect.fromCenter(center: p, width: r * 4.5, height: r * 4.5), color, .5);
    final paint = Paint()
      ..color = Sketch.fade(color, .85)
      ..strokeWidth = math.max(.5, r * .16)
      ..strokeCap = StrokeCap.round;
    // An eight-point star, so it never reads as one more cross.
    c.drawLine(p - Offset(r * 1.2, 0), p + Offset(r * 1.2, 0), paint);
    c.drawLine(p - Offset(0, r * 1.2), p + Offset(0, r * 1.2), paint);
    c.drawLine(p - Offset(r * .6, r * .6), p + Offset(r * .6, r * .6), paint);
    c.drawLine(p - Offset(r * .6, -r * .6), p + Offset(r * .6, -r * .6), paint);
    c.drawCircle(p, r * .3, paint..color = color);
  }

  /// A cylindrical drum lit from the right, [ht] tall above [base]. Its
  /// [windows] sit between pilasters at even angles round the curve, so they
  /// crowd toward the edges as on a real cylinder; [spread] is the angle of
  /// the outermost, in radians.
  static void _domedDrum(
    Canvas c,
    Offset base,
    double hw,
    double ht, {
    required Color body,
    required Color lit,
    required Color shade,
    required Color hole,
    required Color glow,
    int windows = 0,
    double spread = 1.1,
    double litChance = .4,
    int seed = 0,
  }) {
    final x = base.dx, y = base.dy;
    _domedFace(c, Rect.fromLTRB(x - hw, y - ht, x + hw, y), shade, body, lit);
    if (windows < 1) return;
    final step = windows > 1 ? 2 * spread / (windows - 1) : 1.0;
    final ww = math.min(hw * step * .42, hw * .5);
    final pane = Paint();
    for (var i = 0; i < windows; i++) {
      final a = windows > 1 ? -spread + step * i : 0.0;
      final wd = ww * math.cos(a);
      final wx = x + hw * math.sin(a);
      final head = Radius.circular(wd / 2);
      final on = Sketch.hash(seed * 29 + i) < litChance;
      c.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(wx - wd / 2, y - ht * .86, wx + wd / 2, y - ht * .16),
          topLeft: head,
          topRight: head,
        ),
        pane..color = on ? glow : hole,
      );
    }
    final post = Paint();
    for (var i = 0; i < windows - 1; i++) {
      final a = -spread + step * (i + .5);
      final u = (math.sin(a) + 1) / 2;
      final px = x + hw * math.sin(a);
      final pw = hw * step * .16 * math.cos(a);
      c.drawRect(
        Rect.fromLTRB(px - pw / 2, y - ht, px + pw / 2, y),
        post..color = Color.lerp(shade, lit, math.min(1.0, u * 1.1 + .15))!,
      );
    }
  }

  /// A lantern [ht] tall above [base]: a drum of [bays] openings between
  /// columns, a cornice and a small capping dome.
  static void _domedLantern(
    Canvas c,
    Offset base,
    double hw,
    double ht, {
    required Color body,
    required Color lit,
    required Color shade,
    required Color hole,
    int bays = 3,
  }) {
    final x = base.dx, y = base.dy;
    final drum = ht * .56;
    _domedFace(c, Rect.fromLTRB(x - hw, y - drum, x + hw, y), shade, body, lit);
    final cell = hw * 2 / bays;
    final open = Paint()..color = hole;
    for (var i = 0; i < bays; i++) {
      final l = x - hw + cell * i + cell * .3;
      c.drawRect(
        Rect.fromLTRB(l, y - drum * .9, l + cell * .4, y - drum * .1),
        open,
      );
    }
    _domedBand(c, x, y - drum, hw * 1.16, ht * .1, body, lit, shade);
    _dome(
      c,
      Offset(x, y - drum - ht * .1),
      hw * 1.02,
      ht * .34,
      body,
      lit,
      shade: shade,
      bulge: .45,
      crownX: .4,
      crownY: .8,
      tip: .12,
    );
  }

  /// The hill of Montmartre [dx] heights from the church axis, its crest at
  /// [crest]: a broad butte that steepens below the terrace and eases into
  /// the ridge, foot at .72 of the viewport.
  static double _domedHillY(double dx, double crest, double h) {
    final t = math.min(1.0, math.max(0.0, (dx.abs() - .075) / .265));
    final rise = h * .72 - crest;
    return crest +
        h * .004 +
        rise * (.55 * t * (2 - t) + .45 * t * t * (3 - 2 * t));
  }

  /// Montmartre: a mound of dusk-blue lawn lit on its right flank, its crest
  /// caught by the moon and trees along both slopes. [crest] is the height of
  /// the church terrace.
  static void _domedHill(Canvas c, double cx, double crest, double h) {
    final shade = _hazed(const Color(0xff2a3c5c), .38);
    final mid = _hazed(const Color(0xff3c5670), .4);
    final lit = _hazed(const Color(0xff5f7b86), .42);
    final body = Path()..moveTo(cx - h * .34, h * .74);
    final line = Path();
    const n = 34;
    for (var i = 0; i <= n; i++) {
      final dx = -.34 + .68 * i / n;
      final p = Offset(cx + dx * h, _domedHillY(dx, crest, h));
      body.lineTo(p.dx, p.dy);
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    body
      ..lineTo(cx + h * .34, h * .74)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(cx - h * .34, 0),
          Offset(cx + h * .34, 0),
          [shade, mid, lit],
          const [0, .55, 1],
        ),
    );
    c.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .0016)
        ..color = Sketch.fade(lit, .55),
    );
    // Trees crowd the slopes; the moon silvers those on the right.
    final leaf = Paint()..color = _hazed(const Color(0xff203a52), .36);
    final leafLit = Paint()..color = _hazed(const Color(0xff3f6470), .4);
    for (final (dx, r) in const [
      (-.238, .010),
      (-.205, .012),
      (-.172, .014),
      (-.14, .012),
      (-.108, .010),
      (.108, .010),
      (.14, .013),
      (.172, .014),
      (.205, .012),
      (.238, .010),
    ]) {
      final p = Offset(cx + dx * h, _domedHillY(dx, crest, h) - h * r * .35);
      c.drawCircle(p, h * r, leaf);
      if (dx > 0) {
        c.drawCircle(p + Offset(h * r * .28, -h * r * .3), h * r * .58, leafLit);
      }
    }
  }

  /// The terrace before the portico and the great flight of steps below it,
  /// floodlit against the dark hill, with lamps and winding paths beside it.
  static void _domedStairs(Canvas c, double cx, double gy, double h) {
    final stone = _hazed(const Color(0xffd2c9dc), .36);
    final lit = _hazed(const Color(0xfff8eee8), .34);
    final edge = _hazed(const Color(0xff7d76a4), .42);
    final y0 = gy + h * .007, y1 = gy + h * .105;
    double half(double y) => h * .03 + h * .026 * ((y - y0) / (y1 - y0));
    // Winding paths cross the lawns on either side.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = h * .0026
      ..color = Sketch.fade(stone, .55);
    for (final side in const [-1.0, 1.0]) {
      final path = Path()..moveTo(cx + side * h * .064, gy + h * .009);
      for (final (dx, dy) in const [
        (.112, .034),
        (.078, .052),
        (.124, .07),
        (.088, .09),
        (.13, .106),
      ]) {
        path.lineTo(cx + side * h * dx, gy + h * dy);
      }
      c.drawPath(path, track);
    }
    // The flight widens toward the viewer and is lit more on its right.
    c.drawPath(
      Sketch.poly([
        cx - half(y0), y0, cx + half(y0), y0,
        cx + half(y1), y1, cx - half(y1), y1,
      ]),
      Paint()
        ..shader = Gradient.linear(
          Offset(cx - half(y1), 0),
          Offset(cx + half(y1), 0),
          [Sketch.mix(stone, edge, .5), stone, lit],
          const [0, .5, 1],
        ),
    );
    final treads = Path();
    for (var i = 1; i < 22; i++) {
      final y = y0 + (y1 - y0) * i / 22;
      treads
        ..moveTo(cx - half(y), y)
        ..lineTo(cx + half(y), y);
    }
    c.drawPath(
      treads,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0007)
        ..color = Sketch.fade(edge, .5),
    );
    final rail = Paint()
      ..strokeWidth = math.max(.7, h * .0012)
      ..color = edge;
    final lamp = Paint()..color = _hazed(_gold, .1);
    for (final side in const [-1.0, 1.0]) {
      c.drawLine(
        Offset(cx + side * half(y0), y0),
        Offset(cx + side * half(y1), y1),
        rail,
      );
      // A lamp at every few flights, strung up the balustrade.
      for (var i = 1; i <= 4; i++) {
        final y = y0 + (y1 - y0) * i * .2 - h * .004;
        c.drawCircle(
          Offset(cx + side * (half(y) + h * .007), y),
          math.max(.7, h * .0012),
          lamp,
        );
      }
    }
    // The terrace, its lit lip and a balustrade of posts.
    final top = gy - h * .0025;
    c.drawRect(
      Rect.fromLTRB(cx - h * .068, top, cx + h * .068, y0),
      Paint()..color = stone,
    );
    c.drawRect(
      Rect.fromLTRB(cx - h * .068, top, cx + h * .068, gy + h * .0008),
      Paint()..color = lit,
    );
    final posts = Path();
    for (var i = -11; i <= 11; i++) {
      final x = cx + i * h * .0058;
      posts
        ..moveTo(x, gy + h * .001)
        ..lineTo(x, y0 - h * .0008);
    }
    c.drawPath(
      posts,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0008)
        ..color = Sketch.fade(edge, .7),
    );
  }

  /// Sacré-Cœur crowning Montmartre, floodlit white: a facade of three arches
  /// under an arcaded gallery and a gable, the great ogival dome on its ring
  /// of windows with a smaller dome each side, the campanile behind, and the
  /// stairs climbing the hill to the terrace. [by] is the foot of the hill
  /// behind the far ridge.
  static void _basilica(Canvas c, Offset by, double h) {
    final cx = by.dx;
    // The crest stands well above [by], so the portico and the stairs clear
    // the roofs of the row in front, which hide the foot of the hill.
    final gy = by.dy - h * .104;
    double px(double dx) => cx + dx * h;
    double py(double up) => gy - up * h;
    Rect box(double l, double top, double r, double bottom) =>
        Rect.fromLTRB(px(l), py(top), px(r), py(bottom));
    final lit = _hazed(const Color(0xfff8eee8), .34);
    final stone = _hazed(const Color(0xffe2d8e6), .38);
    final shade = _hazed(const Color(0xffa09ac0), .4);
    final mass = _hazed(const Color(0xffbfb7d2), .44);
    final deep = _hazed(const Color(0xff3a3860), .45);
    final glow = _hazed(_gold, .3);
    final fill = Paint();
    void rect(Rect r, Color color) => c.drawRect(r, fill..color = color);
    void poly(List<double> xy, Color color) =>
        c.drawPath(Sketch.poly(xy), fill..color = color);

    _domedHill(c, cx, gy, h);
    // Floodlights wash the crest, and a faint bloom rises round the domes.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(px(0), py(.006)), width: h * .34, height: h * .1),
      const Color(0xffffe2b8),
      .3,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(px(0), py(.078)), width: h * .21, height: h * .21),
      const Color(0xffffe6d4),
      .15,
    );
    _domedStairs(c, cx, gy, h);

    // The campanile stands behind the right flank, taller than the dome: a
    // plain shaft of slits, a belfry of two arches and a pyramid roof.
    const tx = .0665, tw = .0085;
    final tStone = _hazed(const Color(0xffd6cde0), .44);
    final tLit = _hazed(const Color(0xffeee6f0), .4);
    final tShade = _hazed(const Color(0xff9690b8), .46);
    rect(box(tx - tw, .112, tx + tw, .02), tStone);
    rect(box(tx + tw * .45, .112, tx + tw, .02), tLit);
    rect(box(tx - tw, .112, tx - tw * .6, .02), tShade);
    for (final y in const [.04, .057, .074, .091]) {
      rect(box(tx - .0009, y + .0072, tx + .0009, y), deep);
    }
    _domedBand(c, px(tx), py(.112), h * (tw + .0008), h * .002, tStone, tLit, tShade);
    rect(box(tx - tw, .128, tx + tw, .114), tStone);
    rect(box(tx + tw * .45, .128, tx + tw, .114), tLit);
    rect(box(tx - tw, .128, tx - tw * .6, .114), tShade);
    _domedArch(c, box(tx - .0062, .1265, tx - .0012, .1165), deep);
    _domedArch(c, box(tx + .0012, .1265, tx + .0062, .1165), deep);
    _domedBand(c, px(tx), py(.128), h * (tw + .001), h * .0027, tStone, tLit, tShade);
    poly([px(tx - tw * 1.1), py(.1307), px(tx), py(.145), px(tx), py(.1307)], tStone);
    poly([px(tx), py(.145), px(tx + tw * 1.1), py(.1307), px(tx), py(.1307)], tLit);
    _domedCross(c, Offset(px(tx), py(.145)), h * .0065, tStone);

    // Transept and chapel roofs step down beside the facade.
    rect(box(-.066, .028, -.04, 0), mass);
    rect(box(-.066, .028, -.062, 0), shade);
    rect(box(.04, .031, .08, 0), mass);
    rect(box(.072, .031, .08, 0), stone);
    // The crossing carries the domes: a square base with a lit end.
    rect(box(-.042, .056, .042, .03), mass);
    rect(box(.034, .056, .042, .03), stone);
    for (final side in const [-1.0, 1.0]) {
      final sx = side * .036;
      _domedDrum(
        c,
        Offset(px(sx), py(.056)),
        h * .0088,
        h * .0065,
        body: stone,
        lit: lit,
        shade: shade,
        hole: deep,
        glow: glow,
        windows: 3,
        spread: .7,
        litChance: .3,
        seed: side > 0 ? 3 : 4,
      );
      _dome(
        c,
        Offset(px(sx), py(.0625)),
        h * .0092,
        h * .0205,
        stone,
        lit,
        shade: shade,
        ribs: const [-.71, 0.0, .71],
        bulge: .5,
        crownX: .36,
        crownY: .8,
        tip: .16,
      );
      _domedLantern(
        c,
        Offset(px(sx), py(.083)),
        h * .0028,
        h * .0055,
        body: stone,
        lit: lit,
        shade: shade,
        hole: deep,
      );
      _domedCross(c, Offset(px(sx), py(.0885)), h * .0055, stone);
    }
    // The great dome: a drum ringed with arched windows between pilasters, a
    // cornice, then sixteen ribs up an ogival shell to the lantern and cross.
    _domedDrum(
      c,
      Offset(px(0), py(.056)),
      h * .0195,
      h * .0115,
      body: stone,
      lit: lit,
      shade: shade,
      hole: deep,
      glow: glow,
      windows: 5,
      spread: 1.05,
      litChance: .45,
      seed: 5,
    );
    _domedBand(c, px(0), py(.0675), h * .0212, h * .0019, stone, lit, shade);
    _dome(
      c,
      Offset(px(0), py(.0694)),
      h * .0172,
      h * .0425,
      stone,
      lit,
      shade: shade,
      ribs: const [-.92, -.71, -.38, 0.0, .38, .71, .92],
      bulge: .48,
      crownX: .36,
      crownY: .8,
      tip: .16,
    );
    _domedLantern(
      c,
      Offset(px(0), py(.1119)),
      h * .0042,
      h * .0165,
      body: stone,
      lit: lit,
      shade: shade,
      hole: deep,
    );
    _domedCross(c, Offset(px(0), py(.1284)), h * .0075, stone);

    // The facade: a plinth, three arches under an arcaded gallery, a cornice
    // and a gable, its right end catching the moon.
    rect(box(-.0465, .045, .0465, 0), stone);
    rect(box(.038, .045, .0465, 0), lit);
    rect(box(-.0465, .045, -.041, 0), shade);
    rect(box(-.0475, .0035, .0475, 0), shade);
    rect(box(.038, .0035, .0475, 0), stone);
    _domedArch(c, box(-.011, .028, .011, .0035), deep);
    _domedArch(c, box(-.0365, .0195, -.0225, .0035), deep);
    _domedArch(c, box(.0225, .0195, .0365, .0035), deep);
    // The central doorway glows within.
    _domedArch(c, box(-.005, .013, .005, .0035), Sketch.fade(glow, .6));
    // Joan of Arc and Saint Louis ride in niches over the side arches.
    for (final side in const [-1.0, 1.0]) {
      final nx = side * .0295;
      _domedArch(c, box(nx - .0058, .0335, nx + .0058, .0225), deep);
      c.drawOval(
        Rect.fromCenter(center: Offset(px(nx), py(.0262)), width: h * .0064, height: h * .0026),
        fill..color = stone,
      );
      rect(box(nx - .0006, .0318, nx + .0006, .0268), stone);
      c.drawCircle(Offset(px(nx), py(.0325)), h * .0008, fill..color = stone);
    }
    // Christ in majesty stands over the great arch.
    _domedArch(c, box(-.0038, .0435, .0038, .0305), deep);
    rect(box(-.0008, .0402, .0008, .0322), stone);
    rect(box(-.0026, .0388, .0026, .0381), stone);
    c.drawCircle(Offset(px(0), py(.0412)), h * .0009, fill..color = stone);
    Scenery.arches(c, box(-.0435, .0435, -.0135, .0355), 5, deep);
    Scenery.arches(c, box(.0135, .0435, .0435, .0355), 5, deep);
    _domedBand(c, px(0), py(.045), h * .0495, h * .0032, stone, lit, shade);
    poly([px(-.0175), py(.0482), px(0), py(.0555), px(.0175), py(.0482)], stone);
    poly([px(0), py(.0555), px(.0175), py(.0482), px(0), py(.0482)], lit);
    poly(
      [px(-.0125), py(.0488), px(0), py(.0524), px(.0125), py(.0488)],
      Sketch.mix(stone, shade, .55),
    );
    for (final side in const [-1.0, 1.0]) {
      final sx = side * .0452;
      poly([px(sx - .0022), py(.0482), px(sx), py(.0565), px(sx + .0022), py(.0482)], stone);
      poly([px(sx), py(.0565), px(sx + .0022), py(.0482), px(sx), py(.0482)], lit);
    }
    // Floodlights at the foot warm the stone.
    c.drawRect(
      box(-.0465, .034, .0465, 0),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, py(0)),
          Offset(0, py(.034)),
          [Sketch.fade(glow, .3), Sketch.fade(glow, 0)],
        ),
    );
  }

  /// Les Invalides in the last of the light: the long slate-roofed front of
  /// the hôtel with its pedimented pavilions, the church's square base behind
  /// it, the pilastered drum and attic, the gilded dome ribbed like a
  /// segmented fruit and glinting under the floodlights, and the lantern and
  /// spire above. [by] is the foot of the building behind the far ridge.
  static void _invalides(Canvas c, Offset by, double h) {
    final cx = by.dx;
    // The church stands well above [by], so its drum clears the roofs in front.
    final gy = by.dy - h * .072;
    double px(double dx) => cx + dx * h;
    double py(double up) => gy - up * h;
    Rect box(double l, double top, double r, double bottom) =>
        Rect.fromLTRB(px(l), py(top), px(r), py(bottom));
    final lit = _hazed(const Color(0xffe2d4cc), .36);
    final stone = _hazed(const Color(0xffc8bcc6), .4);
    final shade = _hazed(const Color(0xff857c9c), .42);
    final deep = _hazed(const Color(0xff3a3860), .45);
    final slate = _hazed(const Color(0xff3a3b5e), .44);
    final slateLit = _hazed(const Color(0xff5a5b84), .44);
    final gold = _hazed(const Color(0xffdcac4c), .2);
    final goldLit = _hazed(const Color(0xffffeeb0), .26);
    final goldDeep = _hazed(const Color(0xff94693a), .3);
    final glow = _hazed(_gold, .25);
    final fill = Paint();
    void rect(Rect r, Color color) => c.drawRect(r, fill..color = color);
    void poly(List<double> xy, Color color) =>
        c.drawPath(Sketch.poly(xy), fill..color = color);

    // The floodlights bloom round the gilding.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(px(0), py(.078)), width: h * .17, height: h * .17),
      const Color(0xffffd68a),
      .2,
    );

    // The church's square base, set back in the haze under its pilasters.
    rect(box(-.036, .0334, .036, 0), Sketch.mix(stone, shade, .5));
    rect(box(.03, .0334, .036, 0), stone);
    for (var i = -3; i <= 3; i++) {
      rect(box(i * .0095 - .0008, .0334, i * .0095 + .0008, .02), stone);
    }
    // The tall drum, its windows between paired pilasters, under a cornice,
    // then a plain attic ring.
    _domedDrum(
      c,
      Offset(px(0), py(.0334)),
      h * .0165,
      h * .0206,
      body: stone,
      lit: lit,
      shade: shade,
      hole: deep,
      glow: glow,
      windows: 7,
      spread: 1.2,
      litChance: .3,
      seed: 9,
    );
    _domedBand(c, px(0), py(.054), h * .0182, h * .0022, stone, lit, shade);
    _domedDrum(
      c,
      Offset(px(0), py(.0562)),
      h * .0146,
      h * .0045,
      body: stone,
      lit: lit,
      shade: shade,
      hole: deep,
      glow: glow,
    );
    _domedBand(c, px(0), py(.0607), h * .0156, h * .0016, stone, lit, shade);
    // The gilded dome: twelve ribs up a full shell to the lantern.
    _dome(
      c,
      Offset(px(0), py(.0623)),
      h * .0142,
      h * .0305,
      gold,
      goldLit,
      shade: goldDeep,
      ribs: const [-.87, -.5, 0.0, .5, .87],
      bulge: .55,
      crownX: .55,
      crownY: .94,
      tip: .2,
    );
    _domedBand(c, px(0), py(.0928), h * .0058, h * .0012, gold, goldLit, goldDeep);
    _domedLantern(
      c,
      Offset(px(0), py(.094)),
      h * .0046,
      h * .0135,
      body: gold,
      lit: goldLit,
      shade: goldDeep,
      hole: deep,
      bays: 4,
    );
    // A ball and the needle of the spire.
    c.drawCircle(Offset(px(0), py(.1085)), math.max(.8, h * .0013), fill..color = goldLit);
    _domedCross(c, Offset(px(0), py(.1085)), h * .0095, gold);
    final glint = _hazed(const Color(0xfffff2c0), .1);
    _domedGlint(c, Offset(px(.0086), py(.0765)), h * .0032, glint);
    _domedGlint(c, Offset(px(.0036), py(.0885)), h * .0022, glint);
    _domedBand(c, px(0), py(.0334), h * .0385, h * .0024, stone, lit, shade);

    // The long front of the hôtel under its slate roof, a pedimented pavilion
    // in the middle and a slate-capped one at each end.
    rect(box(-.09, .02, .09, 0), stone);
    Scenery.windows(
      c,
      box(-.084, .0185, .084, .002),
      cols: 24,
      rows: 2,
      lit: glow,
      dark: deep,
      seed: 12,
      litChance: .22,
    );
    poly([px(-.092), py(.02), px(-.085), py(.0266), px(.085), py(.0266), px(.092), py(.02)], slate);
    rect(box(-.085, .0266, .085, .0259), slateLit);
    _domedBand(c, px(0), py(.0196), h * .0925, h * .0016, stone, lit, shade);
    for (final (l, r) in const [(-.091, -.077), (.077, .091)]) {
      rect(box(l, .0245, r, 0), stone);
      if (l > 0) rect(box(r - .0025, .0245, r, 0), lit);
      Scenery.windows(
        c,
        box(l + .0012, .0235, r - .0012, .003),
        cols: 2,
        rows: 2,
        lit: glow,
        dark: deep,
        seed: 13,
        litChance: .3,
      );
      poly(
        [px(l - .0012), py(.0245), px(l + .003), py(.0296), px(r - .003), py(.0296), px(r + .0012), py(.0245)],
        slate,
      );
    }
    rect(box(-.0135, .0285, .0135, 0), stone);
    rect(box(.0105, .0285, .0135, 0), lit);
    Scenery.windows(
      c,
      box(-.0128, .0275, .0128, .0125),
      cols: 5,
      rows: 1,
      lit: glow,
      dark: deep,
      seed: 14,
      litChance: .3,
    );
    _domedArch(c, box(-.0036, .0115, .0036, 0), deep);
    poly([px(-.0148), py(.0285), px(0), py(.0326), px(.0148), py(.0285)], stone);
    poly([px(0), py(.0326), px(.0148), py(.0285), px(0), py(.0285)], lit);
    poly(
      [px(-.0102), py(.0288), px(0), py(.0318), px(.0102), py(.0288)],
      Sketch.mix(stone, shade, .55),
    );
  }

  /// Top of the far quay's parapet over the mid ridge, in viewport heights.
  /// The façades behind it are cut off there.
  static const _quayTop = .7315;

  /// The far quay: a stone parapet with a moonlit coping along the mid
  /// ridge, and a chain of cast-iron lamps standing behind it, every third a
  /// pair of lanterns. Each lantern blooms gold and throws a pool of light on
  /// the coping.
  static void _quay(Canvas c, double x0, double x1, double h) {
    final top = h * _quayTop, foot = h * .745;
    final fine = h >= 480;
    final lamp = _hazed(_gold, .15);
    final post = Path(), globe = Path(), core = Path(), pool = Path();
    final glows = <Offset>[];
    final sh = h * .028, by = top + h * .0022, sw = math.max(.7, h * .0016);
    void lantern(double gx, double gy) {
      final r = h * .0029;
      post
        ..addRect(Rect.fromLTRB(gx - r * .8, gy + r * .8, gx + r * .8, gy + r * 1.3))
        ..moveTo(gx - r * 1.3, gy - r * .55)
        ..lineTo(gx + r * 1.3, gy - r * .55)
        ..lineTo(gx, gy - r * 2)
        ..close();
      globe.addOval(Rect.fromCircle(center: Offset(gx, gy), radius: r));
      core.addOval(Rect.fromCircle(center: Offset(gx, gy), radius: r * .5));
      glows.add(Offset(gx, gy));
      pool.addOval(
        Rect.fromCenter(center: Offset(gx, top + h * .0008), width: h * .03, height: h * .0042),
      );
    }

    var i = 0;
    for (var x = x0; x < x1; x += h * .07) {
      final k = i++;
      if (Sketch.hash(k + 400) < .1) continue;
      final ly = by - sh;
      // Shaft on a plinth, with a collar.
      post
        ..addRect(Rect.fromLTRB(x - sw / 2, ly, x + sw / 2, by))
        ..addRect(Rect.fromLTRB(x - h * .0026, by - h * .0055, x + h * .0026, by))
        ..addRect(Rect.fromLTRB(x - h * .002, by - sh * .3, x + h * .002, by - sh * .3 + h * .0011));
      if (fine && k % 3 == 1) {
        final arm = h * .0075;
        post
          ..addRect(Rect.fromLTRB(x - arm, ly, x + arm, ly + h * .0012))
          ..addRect(Rect.fromLTRB(x - sw / 2, ly - h * .0055, x + sw / 2, ly))
          ..addOval(Rect.fromCircle(center: Offset(x, ly - h * .0065), radius: h * .0015));
        for (final side in const [-1.0, 1.0]) {
          final gx = x + side * arm;
          post.addRect(Rect.fromLTRB(gx - sw / 2, ly - h * .0033, gx + sw / 2, ly));
          lantern(gx, ly - h * .0062);
        }
      } else {
        lantern(x, ly - h * .0026);
      }
    }
    c.drawPath(post, Paint()..color = _hazed(const Color(0xff1d1c34), .12));
    c.drawPath(globe, Paint()..color = lamp);
    c.drawPath(core, Paint()..color = _hazed(const Color(0xfffff2c8), .05));
    // The parapet hides the lamp feet: a stone face darkening to the water
    // under a moonlit coping and its own shadow.
    c.drawRect(
      Rect.fromLTRB(x0, top, x1, foot),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, foot),
          [_hazed(const Color(0xff585a86), .2), _hazed(const Color(0xff3c3e66), .2)],
        ),
    );
    final cope = math.max(.7, h * .0017);
    c.drawRect(
      Rect.fromLTRB(x0, top, x1, top + cope),
      Paint()..color = _hazed(const Color(0xff9ea3c8), .2),
    );
    c.drawRect(
      Rect.fromLTRB(x0, top + cope, x1, top + cope + math.max(.5, h * .0013)),
      Paint()..color = _hazed(const Color(0xff2b2d52), .2),
    );
    if (fine) {
      // Upright joints between the blocks of the coping course.
      final joints = Path();
      final step = h * .034;
      for (var x = (x0 / step).floor() * step; x < x1; x += step) {
        joints.addRect(Rect.fromLTRB(x, top + cope * 2.3, x + math.max(.5, h * .0007), foot));
      }
      c.drawPath(joints, Paint()..color = _hazed(const Color(0xff33355c), .2));
      // The booksellers' green boxes sit on the coping between the lamps,
      // their lids propped open.
      final body = Path(), lid = Path();
      final bxw = h * .014, bxh = h * .0042, lift = h * .0028;
      var q = 0;
      for (var x = x0; x < x1; x += h * .07, q++) {
        for (final (off, salt) in const [(.014, 0), (.039, 1)]) {
          if (Sketch.hash(q * 2 + salt + 500) > .62) continue;
          final l = x + h * off;
          body.addRect(Rect.fromLTRB(l, top - bxh, l + bxw, top));
          lid
            ..moveTo(l, top - bxh)
            ..lineTo(l + bxw, top - bxh)
            ..lineTo(l + bxw * .94, top - bxh - lift)
            ..lineTo(l + bxw * .06, top - bxh - lift)
            ..close();
        }
      }
      c.drawPath(body, Paint()..color = _hazed(const Color(0xff27423c), .2));
      c.drawPath(lid, Paint()..color = _hazed(const Color(0xff3f6358), .2));
    }
    // Blooms and pools of gold over it all.
    final glowR = h * .022;
    final glow = Paint()
      ..shader = Gradient.radial(
        Offset.zero,
        glowR,
        [Sketch.fade(lamp, .5), Sketch.fade(lamp, .16), Sketch.fade(lamp, 0)],
        const [0, .3, 1],
      );
    for (final o in glows) {
      c.save();
      c.translate(o.dx, o.dy);
      c.drawCircle(Offset.zero, glowR, glow);
      c.restore();
    }
    c.drawPath(pool, Paint()..color = Sketch.fade(lamp, .3));
  }

  // The Eiffel Tower is drawn to its real proportions. Heights are fractions
  // of [s], the 300 m to the top of the lattice (the mast adds another 30 m);
  // widths are fractions of [s] from the centre line.
  static const _eiffelSpring = .05;
  static const _eiffelCrown = .146;
  static const _eiffelBelt = .171;
  static const _eiffelDeck1 = .192;
  static const _eiffelDeck2 = .386;
  static const _eiffelDeck3 = .92;
  static const _eiffelTop = .978;

  /// Half the width of the outer profile at height [t]: Eiffel's curve, an
  /// exponential that falls from the 125 m footprint and flattens into the
  /// slender summit.
  static double _eiffelW(double t) {
    final k = RegionBlend.smooth((t - .9) / .1);
    return .2083 * (.9 * math.exp(-3.6 * t) + .1 - .09 * k);
  }

  static double _eiffelHalf(double s, double t) => s * _eiffelW(t);

  /// The inner face of a pier, which narrows from 26 m at the ground.
  static double _eiffelIn(double t) => _eiffelW(t) - (.088 - .17 * t);

  /// Bay heights between [t0] and [t1], each about [ratio] times as tall as
  /// the tower is wide there, so the lattice closes up as the shaft slims.
  static List<double> _eiffelBays(double t0, double t1, double ratio) {
    final ts = <double>[t0];
    var t = t0;
    while (true) {
      final step = 2 * _eiffelW(t) * ratio;
      if (t + step * 1.5 >= t1) break;
      t += step;
      ts.add(t);
    }
    ts.add(t1);
    return ts;
  }

  /// The lantern on the summit, where the beacon turns.
  static Offset _eiffelLamp(Offset base, double s) =>
      Offset(base.dx, base.dy - s * .959);

  /// The Eiffel Tower: four splayed lattice piers joined by the great arch,
  /// three platforms with lit galleries and railings, and a slender shaft of
  /// cross-braced bays that closes up toward the lantern and mast. Floodlit
  /// bronze at the feet, moon-cooled iron above, its left flank in shade.
  static void _eiffel(Canvas c, Offset base, double s) {
    final bronze = _hazed(const Color(0xff7b5350), .08);
    final rust = _hazed(const Color(0xff5b4257), .08);
    final iron = _hazed(const Color(0xff3d3153), .08);
    final deep = _hazed(const Color(0xff2b2346), .08);
    final glow = _hazed(const Color(0xffffc66e), .05);
    double px(double u) => base.dx + u * s;
    double py(double t) => base.dy - t * s;
    final foot = Offset(base.dx, base.dy), tip = Offset(base.dx, py(1.1));
    Shader vertical(List<Color> colors, List<double> stops) =>
        Gradient.linear(foot, tip, colors, stops);
    Paint stroke(Shader shader, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..shader = shader
      ..strokeWidth = math.max(.6, w * s);
    const ramp = [0.0, .18, .42, .72, 1.0];
    final litColors = [
      _hazed(const Color(0xffffc66e), .05),
      _hazed(const Color(0xfff0a860), .06),
      _hazed(const Color(0xffd48f78), .08),
      _hazed(const Color(0xffb891a8), .1),
      _hazed(const Color(0xffa9a0cc), .1),
    ];
    final shadeColors = [
      _hazed(const Color(0xff9a6658), .06),
      _hazed(const Color(0xff85595c), .08),
      _hazed(const Color(0xff6a5077), .1),
      _hazed(const Color(0xff5a4a78), .1),
      _hazed(const Color(0xff54487a), .1),
    ];
    final bodyShader = vertical(
      [bronze, rust, iron, deep],
      const [0, .26, .58, 1],
    );
    final litShader = vertical(litColors, ramp);
    final shadeShader = vertical(shadeColors, ramp);
    // The far face of the lattice shows through, dimmer and finer.
    final backLit = vertical([for (final k in litColors) Sketch.fade(k, .5)], ramp);
    final backShade = vertical([for (final k in shadeColors) Sketch.fade(k, .55)], ramp);
    final bloom = vertical([for (final k in litColors) Sketch.fade(k, .17)], ramp);

    // Floodlit haze standing behind the iron.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(base.dx, py(.3)), width: s * .7, height: s * .72),
      _gold,
      .1,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(base.dx, py(.07)), width: s * 1.05, height: s * .3),
      _gold,
      .15,
    );

    // One outline for piers, arch and shaft: the arch is a notch in the foot.
    const rows = 48;
    final body = Path()..moveTo(px(-_eiffelW(0)), py(0));
    for (var i = 1; i <= rows; i++) {
      final t = _eiffelTop * i / rows;
      body.lineTo(px(-_eiffelW(t)), py(t));
    }
    for (var i = rows; i >= 0; i--) {
      final t = _eiffelTop * i / rows;
      body.lineTo(px(_eiffelW(t)), py(t));
    }
    body.lineTo(px(_eiffelIn(0)), py(0));
    for (var i = 1; i <= 3; i++) {
      final t = _eiffelSpring * i / 3;
      body.lineTo(px(_eiffelIn(t)), py(t));
    }
    final ax = _eiffelIn(_eiffelSpring), ay = _eiffelCrown - _eiffelSpring;
    for (var i = 0; i <= 28; i++) {
      final a = math.pi * i / 28;
      body.lineTo(px(ax * math.cos(a)), py(_eiffelSpring + ay * math.sin(a)));
    }
    for (var i = 3; i >= 0; i--) {
      final t = _eiffelSpring * i / 3;
      body.lineTo(px(-_eiffelIn(t)), py(t));
    }
    body.close();
    c.drawPath(body, Paint()..shader = bodyShader);
    // The left flank sits in shade, the right takes the moon.
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(px(-.11), base.dy),
          Offset(px(.11), base.dy),
          [
            Sketch.fade(deep, .5),
            Sketch.fade(deep, 0),
            Sketch.fade(const Color(0xffd8b0a0), .14),
          ],
          const [0, .5, 1],
        ),
    );

    // Lattice: every bay is a tie and an X, split into a shaded and a lit
    // half about its own middle; the far face is offset half a bay.
    final pierL = Path(), pierS = Path();
    final midL = Path(), midS = Path();
    final topL = Path(), topS = Path();
    final backL = Path(), backS = Path();
    void seg(Path lit, Path shade, double u0, double t0, double u1, double t1) {
      var x0 = px(u0), y0 = py(t0), x1 = px(u1), y1 = py(t1);
      if (x0 > x1) {
        final tx = x0, ty = y0;
        x0 = x1;
        y0 = y1;
        x1 = tx;
        y1 = ty;
      }
      final mx = (x0 + x1) / 2, my = (y0 + y1) / 2;
      shade
        ..moveTo(x0, y0)
        ..lineTo(mx, my);
      lit
        ..moveTo(mx, my)
        ..lineTo(x1, y1);
    }

    void lattice(
      Path lit,
      Path shade,
      List<double> ts,
      double Function(double) left,
      double Function(double) right,
    ) {
      for (var i = 0; i + 1 < ts.length; i++) {
        final ta = ts[i], tb = ts[i + 1];
        seg(lit, shade, left(ta), ta, right(ta), ta);
        seg(lit, shade, left(ta), ta, right(tb), tb);
        seg(lit, shade, right(ta), ta, left(tb), tb);
        if (i + 2 < ts.length) {
          final tm = (ta + tb) / 2, tn = (tb + ts[i + 2]) / 2;
          seg(backL, backS, left(tm), tm, right(tn), tn);
          seg(backL, backS, right(tm), tm, left(tn), tn);
        }
      }
      final tt = ts.last;
      seg(lit, shade, left(tt), tt, right(tt), tt);
    }

    const pierBays = [0.0, .056, .098, .134, .171];
    for (final side in const [-1.0, 1.0]) {
      double outer(double t) => side * _eiffelW(t);
      double inner(double t) => side * _eiffelIn(t);
      lattice(pierL, pierS, pierBays, side < 0 ? outer : inner, side < 0 ? inner : outer);
    }
    double shaftL(double t) => -_eiffelW(t);
    double shaftR(double t) => _eiffelW(t);
    lattice(midL, midS, _eiffelBays(.19, .378, .5), shaftL, shaftR);
    final upper = _eiffelBays(.39, .905, .62);
    final split = upper.indexWhere((t) => t >= .62);
    lattice(midL, midS, upper.sublist(0, split + 1), shaftL, shaftR);
    lattice(topL, topS, upper.sublist(split), shaftL, shaftR);
    // A soft bloom of floodlight around the brightest iron.
    c.drawPath(pierL, stroke(bloom, .014));
    c.drawPath(midL, stroke(bloom, .011));
    c.drawPath(backS, stroke(backShade, .0015));
    c.drawPath(backL, stroke(backLit, .0015));
    c.drawPath(pierS, stroke(shadeShader, .0042));
    c.drawPath(pierL, stroke(litShader, .0042));
    c.drawPath(midS, stroke(shadeShader, .0032));
    c.drawPath(midL, stroke(litShader, .0032));
    c.drawPath(topS, stroke(shadeShader, .0024));
    c.drawPath(topL, stroke(litShader, .0024));

    // Corner posts: the outer curve of every section, thinning with height.
    void post(double side, double t0, double t1, double w, {bool inner = false}) {
      final p = Path();
      const n = 12;
      for (var i = 0; i <= n; i++) {
        final t = t0 + (t1 - t0) * i / n;
        final u = side * (inner ? _eiffelIn(t) : _eiffelW(t));
        if (i == 0) {
          p.moveTo(px(u), py(t));
        } else {
          p.lineTo(px(u), py(t));
        }
      }
      // Left posts turn from the light, right posts and inner piers catch it.
      final lit = inner ? side < 0 : side > 0;
      c.drawPath(p, stroke(lit ? litShader : shadeShader, w));
    }

    for (final side in const [-1.0, 1.0]) {
      post(side, 0, .175, .0072);
      post(side, 0, .175, .0058, inner: true);
      post(side, .19, .38, .0056);
      post(side, .39, .62, .0044);
      post(side, .62, .906, .0034);
    }

    // The great arch: floodlit soffit, an outer ring, and a zigzag of ties.
    final soffit = Path(), ring = Path(), zig = Path();
    const arcs = 28;
    for (var i = 0; i <= arcs; i++) {
      final a = math.pi * i / arcs;
      final ca = math.cos(a), sa = math.sin(a);
      final inU = px((ax + .003) * ca), inT = py(_eiffelSpring + (ay + .003) * sa);
      final outU = px((ax + .024) * ca), outT = py(_eiffelSpring + (ay + .024) * sa);
      if (i == 0) {
        soffit.moveTo(inU, inT);
        ring.moveTo(outU, outT);
      } else {
        soffit.lineTo(inU, inT);
        ring.lineTo(outU, outT);
      }
    }
    const teeth = 22;
    for (var i = 0; i <= teeth; i++) {
      final a = math.pi * (.06 + .88 * i / teeth);
      final grow = i.isEven ? .008 : .022;
      final x = px((ax + grow) * math.cos(a));
      final y = py(_eiffelSpring + (ay + grow) * math.sin(a));
      if (i == 0) {
        zig.moveTo(x, y);
      } else {
        zig.lineTo(x, y);
      }
    }
    c.drawPath(zig, stroke(shadeShader, .0018));
    c.drawPath(ring, stroke(shadeShader, .0034));
    c.drawPath(soffit, stroke(litShader, .0052));

    // Platforms: a girder belt under a slab, a glazed gallery with its roof,
    // and a railing over the lit windows.
    final bodyFill = Paint()..shader = bodyShader;
    final rail = Paint()
      ..color = Sketch.fade(deep, .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, s * .0016);
    final lamp = _hazed(_gold, .06);
    void deck(
      double w,
      double under,
      double slab,
      double gallery,
      double roof,
      double railTop,
      double gap, {
      bool arcade = false,
    }) {
      c.drawRect(Rect.fromLTRB(px(-w + .005), py(slab), px(w - .005), py(under)), bodyFill);
      c.drawRect(Rect.fromLTRB(px(-w), py(slab + .002), px(w), py(slab - .005)), bodyFill);
      final gw = w - .011;
      final glass = Rect.fromLTRB(px(-gw), py(gallery), px(gw), py(slab));
      c.drawRect(glass, bodyFill);
      Scenery.windows(
        c,
        glass.deflate(s * .0012),
        cols: math.max(4, (glass.width / (s * .0105)).round()),
        rows: 1,
        lit: lamp,
        dark: iron,
        seed: 40 + (w * 1000).round(),
        litChance: .86,
      );
      c.drawRect(Rect.fromLTRB(px(-gw - .004), py(roof), px(gw + .004), py(gallery)), bodyFill);
      final balusters = Path()
        ..moveTo(px(-w), py(railTop))
        ..lineTo(px(w), py(railTop));
      for (var x = -w + gap; x < w - gap * .5; x += gap) {
        balusters
          ..moveTo(px(x), py(slab))
          ..lineTo(px(x), py(railTop));
      }
      c.drawPath(balusters, rail);
      if (arcade) {
        // The arcade of small arches on the girder belt, lit from below.
        final arches = Path();
        final h0 = under + .003, span = .0075;
        for (var x = -w + .012; x < w - .008; x += .0135) {
          arches
            ..moveTo(px(x - span / 2), py(h0))
            ..quadraticBezierTo(px(x), py(h0 + .02), px(x + span / 2), py(h0));
        }
        c.drawPath(
          arches,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Sketch.fade(glow, .55)
            ..strokeWidth = math.max(.5, s * .0012),
        );
      }
      // Floodlights pick out the lip of the slab and its soffit.
      c.drawLine(
        Offset(px(-w), py(slab)),
        Offset(px(w), py(slab)),
        Paint()
          ..color = Sketch.fade(glow, .85)
          ..strokeWidth = math.max(.6, s * .0026),
      );
      c.drawLine(
        Offset(px(-w + .005), py(under)),
        Offset(px(w - .005), py(under)),
        Paint()
          ..color = Sketch.fade(glow, .6)
          ..strokeWidth = math.max(.6, s * .002),
      );
    }

    deck(
      _eiffelW(_eiffelDeck1) + .009,
      _eiffelBelt,
      _eiffelDeck1,
      .213,
      .218,
      .2,
      .0065,
      arcade: true,
    );
    deck(_eiffelW(_eiffelDeck2) + .007, .374, _eiffelDeck2, .4, .404, .393, .0055);

    // The summit: a slab, the glazed cabin, the lantern and the mast.
    deck(_eiffelW(_eiffelDeck3) + .006, .905, _eiffelDeck3, .944, .949, .93, .0045);
    c.drawRect(
      Rect.fromLTRB(px(-.0085), py(.968), px(.0085), py(.949)),
      Paint()..color = _hazed(const Color(0xffffe6a8), .05),
    );
    c.drawRect(
      Rect.fromLTRB(px(-.0011), py(.968), px(.0011), py(.949)),
      Paint()..color = deep,
    );
    c.drawPath(
      Sketch.poly([
        px(-.0105), py(.968),
        px(.0105), py(.968),
        px(.0026), py(.986),
        px(-.0026), py(.986),
      ]),
      bodyFill,
    );
    c.drawPath(
      Sketch.poly([
        px(-.0034), py(.985),
        px(.0034), py(.985),
        px(.0012), py(1.1),
        px(-.0012), py(1.1),
      ]),
      Paint()..color = deep,
    );
    for (final (t, half) in const [(.997, .0058), (1.032, .0046), (1.064, .0036)]) {
      c.drawRect(
        Rect.fromLTRB(px(-half), py(t + .008), px(half), py(t)),
        Paint()..color = deep,
      );
    }
  }

  /// One paint for the tower's per-frame lights; every call sets what it needs.
  static final _eiffelInk = Paint();
  static const _eiffelSpark = Color(0xfffff2c4);

  /// A beam of the summit beacon in unit coordinates, and its paints: the
  /// light fades along the cone, one paint for each of eight strengths.
  static final _eiffelCone = Path()
    ..moveTo(0, -.004)
    ..lineTo(1, -.032)
    ..lineTo(1, .032)
    ..lineTo(0, .004)
    ..close();
  static final _eiffelBeams = [
    for (var k = 1; k <= 8; k++)
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          const Offset(1, 0),
          [
            Sketch.fade(_eiffelSpark, k / 8 * .34),
            Sketch.fade(_eiffelSpark, k / 8 * .12),
            Sketch.fade(_eiffelSpark, 0),
          ],
          const [0, .3, 1],
        ),
  ];

  /// The tower's height to the top of its lattice, in pixels.
  static double _eiffelSize(double h) => h * .5;

  /// Everything about the tower that moves: the glitter, the beacon and the
  /// floodlights' spill along the quay.
  static void _eiffelLive(Canvas c, Offset base, double h, double clock, double presence) {
    final s = _eiffelSize(h);
    _eiffelGlitter(c, base, s, clock, presence);
    _eiffelBeacon(c, base, s, h, clock, presence);
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(base.dx, base.dy - s * .04), width: s * .95, height: s * .1),
      _gold,
      .12 * presence,
    );
  }

  /// The hourly glitter: the bulbs flash in a burst that runs for about ten
  /// seconds in every twenty-six, and a few still wink between bursts. Every
  /// flash lands somewhere new on the iron.
  static void _eiffelGlitter(Canvas c, Offset base, double s, double clock, double presence) {
    final cycle = (clock / 26) % 1.0;
    final burst = cycle < .38 ? math.sin(cycle / .38 * math.pi) : 0.0;
    final gate = .14 + .86 * burst;
    for (var i = 0; i < 44; i++) {
      if (Sketch.hash(i + 90) > gate) continue;
      final phase = clock * (5 + 3.4 * Sketch.hash(i + 130)) + i * 2.399;
      final flash = math.pow(math.max(0.0, math.sin(phase)), 6).toDouble();
      if (flash < .05) continue;
      final n = i * 131 + (phase / (2 * math.pi)).floor() * 17;
      final t = .05 + .9 * Sketch.hash(n + 1);
      final half = _eiffelHalf(s, t), inner = s * _eiffelIn(t);
      // Low down the flashes keep to the piers, clear of the arch.
      final dx = t < .17
          ? (Sketch.hash(n + 2) < .5 ? -1 : 1) * (inner + (half - inner) * Sketch.hash(n + 3))
          : (Sketch.hash(n + 3) * 2 - 1) * half * .94;
      final p = Offset(base.dx + dx, base.dy - t * s);
      final a = flash * presence;
      final r = s * (.0028 + .0032 * flash);
      _eiffelInk.color = Sketch.fade(_eiffelSpark, .07 * a);
      c.drawCircle(p, r * 3.6, _eiffelInk);
      _eiffelInk.color = Sketch.fade(_eiffelSpark, .16 * a);
      c.drawCircle(p, r * 2.1, _eiffelInk);
      _eiffelInk.color = Sketch.fade(_eiffelSpark, .95 * a);
      c.drawCircle(p, r, _eiffelInk);
      final arm = s * .02 * flash;
      _eiffelInk
        ..color = Sketch.fade(_eiffelSpark, .7 * a)
        ..strokeWidth = math.max(.6, s * .0018)
        ..strokeCap = StrokeCap.round;
      c.drawLine(p.translate(-arm, 0), p.translate(arm, 0), _eiffelInk);
      c.drawLine(p.translate(0, -arm * 1.3), p.translate(0, arm * 1.3), _eiffelInk);
    }
  }

  /// The summit beacon: two beams turn about the lantern, swelling into a
  /// flare each time one swings toward the viewer, while a red light blinks
  /// on the mast.
  static void _eiffelBeacon(
    Canvas c,
    Offset base,
    double s,
    double h,
    double clock,
    double presence,
  ) {
    final o = _eiffelLamp(base, s);
    final beat = .6 + .4 * math.sin(clock * 2.4);
    Sketch.mist(
      c,
      Rect.fromCenter(center: o, width: h * .07, height: h * .07),
      const Color(0xfffff6e0),
      .5 * beat * presence,
    );
    var glare = 0.0;
    for (var j = 0; j < 2; j++) {
      final a = clock * 1.05 + j * math.pi;
      final along = math.cos(a), toward = -math.sin(a);
      glare = math.max(glare, math.pow(math.max(0.0, toward), 5).toDouble());
      // A cone seen from the side, foreshortened as it turns to or from us.
      final level = math.min(8, ((.06 + .26 * along.abs()) * presence / .34 * 8).round());
      if (level < 1 || along.abs() < .03) continue;
      c.save();
      c.translate(o.dx, o.dy);
      c.scale(h * .55 * along, h * .55 * (.3 + .7 * along.abs()));
      c.drawPath(_eiffelCone, _eiffelBeams[level - 1]);
      c.restore();
    }
    if (glare > .04) {
      Sketch.mist(
        c,
        Rect.fromCenter(center: o, width: h * .2, height: h * .2),
        _eiffelSpark,
        .6 * glare * presence,
      );
    }
    // The aviation light at the tip of the mast.
    final tip = Offset(base.dx, base.dy - s * 1.1);
    final on = clock % 1.7 < .3;
    _eiffelInk.color = Sketch.fade(const Color(0xffff5a48), (on ? .95 : .35) * presence);
    c.drawCircle(tip, math.max(.8, s * .0045), _eiffelInk);
    if (on) {
      _eiffelInk.color = Sketch.fade(const Color(0xffff5a48), .22 * presence);
      c.drawCircle(tip, s * .015, _eiffelInk);
    }
  }

  /// The Arc de Triomphe, [s] tall, seen a little from the left: the
  /// floodlit front with its great arch and winged victories, the relief
  /// groups on the piers, the frieze of soldiers, the dentilled cornice and
  /// the attic of shields over an inscription band. The flank turns away in
  /// moon shadow with its small arch, and the moon rakes the right edge. The
  /// eternal flame stands at `base.dx`, lit every frame by [_arcGlow].
  static void _arc(Canvas c, Offset base, double s) {
    Color hz(int argb) => _hazed(Color(argb), .12);
    // Floodlit front (warm at the foot, cool under the moon), lit mouldings,
    // carved shadow, and the flank in shade.
    final faceLow = hz(0xffa89a94), faceMid = hz(0xff8a849f), faceTop = hz(0xff76739a);
    final flankLow = hz(0xff6a5f70), flankMid = hz(0xff504d73), flankTop = hz(0xff403e66);
    final hi = hz(0xffcbc1c4), hiSoft = hz(0xffa89fb0), hiShade = hz(0xff7a7698);
    final mid = hz(0xff67638d), deep = hz(0xff3a3861), recess = hz(0xff5c5880);
    final flankCrown = hz(0xff625e84), flankTooth = hz(0xff5b5780);
    const voidTop = Color(0xff1b1d3c);

    // The block is about as wide as it is tall; the flank takes its share of
    // the width to the left of the front, and depth runs leftward on screen.
    final cx = base.dx, f = s * _arcFlank;
    final xl = cx - s / 2, xf = xl + f, xr = cx + s / 2, xc = (xf + xr) / 2;
    final fw = xr - xf, seam = s * .004, o1 = s * .008, o2 = s * .012;
    // The great arch is 14.6 m by 29.2 m in a 45 m by 50 m front.
    final aw = fw * .163, ry = s * .146, spring = base.dy - s * .438;
    final hair = math.max(.65, s * .007);
    double y(double t) => base.dy - s * t;
    final p = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair;
    void rect(Rect r, Color color) => c.drawRect(r, p..color = color);
    Path arch(double x, double halfW, double rise, double springY, double bottom) =>
        Path()
          ..moveTo(x - halfW, bottom)
          ..lineTo(x - halfW, springY)
          ..arcToPoint(
            Offset(x + halfW, springY),
            radius: Radius.elliptical(halfW, rise),
            clockwise: true,
          )
          ..lineTo(x + halfW, bottom)
          ..close();

    // Floodlight bloom behind the monument, warming the roofs around it.
    Sketch.mist(c, Rect.fromCenter(center: Offset(xc, y(.5)), width: s * 2.2, height: s * 1.7), _gold, .1);
    Sketch.mist(c, Rect.fromCenter(center: Offset(xc, y(.06)), width: s * 1.6, height: s * .5), _gold, .16);

    // The shaded flank and the floodlit front, then the moon's wash that
    // brightens toward the right-hand edge, then a base course.
    c.drawRect(
      Rect.fromLTRB(xl, y(.962), xf + seam, base.dy),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y(.05)),
          Offset(0, y(.962)),
          [flankLow, flankMid, flankTop],
          const [0, .5, 1],
        ),
    );
    c.drawRect(
      Rect.fromLTRB(xf, y(.962), xr, base.dy),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y(.05)),
          Offset(0, y(.962)),
          [faceLow, faceMid, faceTop],
          const [0, .5, 1],
        ),
    );
    c.drawRect(
      Rect.fromLTRB(xf, y(.962), xr, y(.05)),
      Paint()
        ..shader = Gradient.linear(
          Offset(xf, 0),
          Offset(xr, 0),
          [Sketch.fade(_moonlit, 0), Sketch.fade(_moonlit, 0), Sketch.fade(_moonlit, .2)],
          const [0, .5, 1],
        ),
    );
    rect(Rect.fromLTRB(xl - s * .012, y(.05), xf + seam, base.dy), flankLow);
    rect(Rect.fromLTRB(xf, y(.05), xr + s * .012, base.dy), hiSoft);

    // Ashlar: courses and staggered joints, chiselled dark with a lit lip,
    // and a few weathered patches.
    final courses = Path(), joints = Path();
    for (var k = 0; k < 21; k++) {
      final t = .05 + k * .0435, yy = y(t);
      courses
        ..moveTo(xl, yy)
        ..lineTo(xr, yy);
      for (var j = 0; j < 4; j++) {
        final jx = xl + (xr - xl) * Sketch.hash(k * 7 + j + 610);
        joints
          ..moveTo(jx, yy)
          ..lineTo(jx, y(t + .0435));
      }
    }
    final chisel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, s * .0035)
      ..color = const Color(0x1a12143a);
    c.drawPath(courses, chisel);
    c.drawPath(joints, chisel);
    c.drawPath(courses.shift(Offset(0, s * .004)), chisel..color = const Color(0x12fff2e0));
    for (var i = 0; i < 12; i++) {
      final patch = Rect.fromCenter(
        center: Offset(xl + (xr - xl) * Sketch.hash(i + 640), y(.08 + .82 * Sketch.hash(i + 641))),
        width: s * (.03 + .05 * Sketch.hash(i + 642)),
        height: s * (.012 + .022 * Sketch.hash(i + 643)),
      );
      rect(patch, i.isEven ? const Color(0x1512143a) : const Color(0x12fff0dc));
    }

    // The flank's small arch, sharply foreshortened, under a relief tablet.
    final sx = xf - f / 2, srx = f * .19, sry = s * .0844, sSpring = y(.289);
    final tablet = Rect.fromLTRB(sx - f * .3, y(.6), sx + f * .3, y(.42));
    rect(tablet, hiShade);
    rect(tablet.deflate(s * .006), deep);
    c.drawPath(arch(sx, srx + s * .009, sry + s * .009, sSpring, base.dy), p..color = hiShade);
    c.drawPath(
      arch(sx, srx, sry, sSpring, base.dy),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base.dy),
          Offset(0, y(.3736)),
          [const Color(0xff5a4658), voidTop],
          const [0, .8],
        ),
    );

    // Attic: a plinth band, two lines of engraved inscription, and the
    // shields (ten across the front, five along the flank).
    rect(Rect.fromLTRB(xl, y(.79), xf + seam, y(.772)), Sketch.fade(hiShade, .22));
    rect(Rect.fromLTRB(xf, y(.79), xr, y(.772)), Sketch.fade(hi, .16));
    final words = Path();
    void inscribe(double xa, double xb, double t, int seed) {
      var wx = xa, i = 0;
      while (wx < xb - s * .03) {
        final len = s * (.03 + .05 * Sketch.hash(seed + i));
        words
          ..moveTo(wx, y(t))
          ..lineTo(math.min(wx + len, xb), y(t));
        wx += len + s * .02;
        i++;
      }
    }

    inscribe(xf + fw * .05, xr - fw * .05, .842, 520);
    inscribe(xf + fw * .05, xr - fw * .05, .82, 560);
    inscribe(xl + f * .12, xf - f * .1, .831, 590);
    c.drawPath(
      words,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .007)
        ..color = const Color(0x70141436),
    );
    final ringF = Path(), discF = Path(), coreF = Path(), ringS = Path(), discS = Path();
    final sr = s * .027;
    for (var i = 0; i < 10; i++) {
      final ctr = Offset(xf + fw * (i + .5) / 10, y(.9));
      ringF.addOval(Rect.fromCircle(center: ctr, radius: sr));
      discF.addOval(Rect.fromCircle(center: ctr, radius: sr * .78));
      coreF.addOval(Rect.fromCircle(center: ctr, radius: sr * .38));
    }
    for (var i = 0; i < 5; i++) {
      final ctr = Offset(xf - f * (i + .5) / 5, y(.9));
      ringS.addOval(Rect.fromCenter(center: ctr, width: sr * .9, height: sr * 2));
      discS.addOval(Rect.fromCenter(center: ctr, width: sr * .66, height: sr * 1.56));
    }
    c.drawPath(ringF, p..color = mid);
    c.drawPath(discF, p..color = hi);
    c.drawPath(coreF, p..color = mid);
    c.drawPath(ringS, p..color = deep);
    c.drawPath(discS, p..color = hiShade);
    // The top cornice throws its shadow down the attic.
    c.drawRect(
      Rect.fromLTRB(xl, y(.962), xr, y(.93)),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y(.962)),
          Offset(0, y(.93)),
          const [Color(0x70101230), Color(0x00101230)],
        ),
    );

    // Architrave, then the frieze of soldiers, recessed in the cornice's
    // shadow: ranks of heads and shoulders as ragged ticks.
    rect(Rect.fromLTRB(xl, y(.676), xf + seam, y(.66)), hiShade);
    rect(Rect.fromLTRB(xf, y(.676), xr, y(.66)), hiSoft);
    rect(Rect.fromLTRB(xl, y(.722), xf + seam, y(.676)), deep);
    rect(Rect.fromLTRB(xf, y(.722), xr, y(.676)), recess);
    final crowd = Path(), crowdS = Path();
    for (var i = 0; i < 44; i++) {
      final x = xf + fw * (i + .5) / 44;
      crowd
        ..moveTo(x, y(.678))
        ..lineTo(x, y(.678) - s * (.008 + .02 * Sketch.hash(i + 500)));
    }
    for (var i = 0; i < 8; i++) {
      final x = xl + f * (i + .5) / 8;
      crowdS
        ..moveTo(x, y(.678))
        ..lineTo(x, y(.678) - s * (.008 + .02 * Sketch.hash(i + 560)));
    }
    c.drawPath(crowd, line..color = Sketch.fade(hi, .48));
    c.drawPath(crowdS, line..color = Sketch.fade(hiShade, .4));
    c.drawRect(
      Rect.fromLTRB(xl, y(.722), xr, y(.694)),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y(.722)),
          Offset(0, y(.694)),
          const [Color(0x66101230), Color(0x00101230)],
        ),
    );

    // The two cornices: a shadowed band of teeth (dentils, modillions) under
    // a bright corona and a crown moulding, each jutting past the wall.
    void cornice(
      double xa,
      double xb,
      List<double> lv,
      Color low,
      Color fascia,
      Color crown,
      Color tooth,
      double pitch,
    ) {
      rect(Rect.fromLTRB(xa, y(lv[3]), xb, y(lv[0])), low);
      final teeth = Path();
      for (var x = xa + pitch * .3; x < xb - pitch * .5; x += pitch) {
        teeth.addRect(Rect.fromLTRB(x, y(lv[1]), x + pitch * .55, y(lv[0])));
      }
      c.drawPath(teeth, p..color = tooth);
      rect(Rect.fromLTRB(xa, y(lv[2]), xb, y(lv[1])), fascia);
      rect(Rect.fromLTRB(xa, y(lv[3]), xb, y(lv[2])), crown);
    }

    const under = [.722, .738, .758, .772], crest = [.962, .972, .988, 1.0];
    cornice(xl - o1, xf - o1 + seam, under, deep, hiShade, flankCrown, flankTooth, s * .02);
    cornice(xf - o1, xr + o1, under, recess, hi, hiSoft, hiSoft, s * .02);
    cornice(xl - o2, xf - o2 + seam, crest, deep, hiShade, flankCrown, flankTooth, s * .03);
    cornice(xf - o2, xr + o2, crest, recess, hi, hiSoft, hiSoft, s * .03);

    // The relief groups on the piers, each on a pedestal under a framed
    // tablet of battle reliefs. The carved shadow is the group shifted down
    // and left over its lit copy, which leaves the moon's rim on the right.
    void group(double px, List<double> pts, List<double> cuts, List<double> heads) {
      final foot = Offset(px, y(.075));
      rect(Rect.fromLTRB(px - s * .105, foot.dy, px + s * .105, y(.03)), hiSoft);
      rect(Rect.fromLTRB(px - s * .105, foot.dy, px + s * .105, foot.dy + hair), hi);
      final mass = Sketch.poly(pts, at: foot, s: s);
      c.drawPath(mass, p..color = hi);
      c.drawPath(mass.shift(Offset(-s * .011, s * .006)), p..color = mid);
      final cut = Path();
      for (var i = 0; i + 3 < cuts.length; i += 4) {
        cut
          ..moveTo(foot.dx + cuts[i] * s, foot.dy + cuts[i + 1] * s)
          ..lineTo(foot.dx + cuts[i + 2] * s, foot.dy + cuts[i + 3] * s);
      }
      c.drawPath(cut, line..color = Sketch.fade(deep, .8));
      for (var i = 0; i + 1 < heads.length; i += 2) {
        c.drawCircle(
          Offset(foot.dx + heads[i] * s, foot.dy + heads[i + 1] * s),
          s * .011,
          p..color = hi,
        );
      }
      final frame = Rect.fromLTRB(px - s * .078, y(.645), px + s * .078, y(.6));
      rect(frame, hiSoft);
      rect(frame.deflate(s * .006), mid);
      final ranks = Path();
      for (var i = 0; i < 9; i++) {
        final x = frame.left + frame.width * (i + .5) / 9;
        ranks
          ..moveTo(x, frame.bottom - s * .007)
          ..lineTo(x, frame.bottom - s * (.011 + .018 * Sketch.hash(i + 530)));
      }
      c.drawPath(ranks, line..color = Sketch.fade(hi, .6));
    }

    group((xf + xc - aw) / 2, _arcGroupB, _arcCutsB, _arcHeadsB);
    group((xc + aw + xr) / 2, _arcGroupA, _arcCutsA, _arcHeadsA);

    // The great arch: a moulded archivolt on projecting imposts, then the
    // coffered vault lit warm from the floor, the right-hand reveal wall,
    // and, through the far end, the dark avenue with its lights.
    c.drawPath(arch(xc, aw + s * .026, ry + s * .026, spring, spring), p..color = hi);
    c.drawPath(arch(xc, aw + s * .016, ry + s * .016, spring, spring), p..color = mid);
    c.drawPath(arch(xc, aw + s * .008, ry + s * .008, spring, base.dy), p..color = hiSoft);
    rect(Rect.fromLTRB(xc - aw - s * .036, spring - s * .012, xc - aw + s * .002, spring + s * .004), hi);
    rect(Rect.fromLTRB(xc + aw - s * .002, spring - s * .012, xc + aw + s * .036, spring + s * .004), hi);
    final near = arch(xc, aw, ry, spring, base.dy);
    c.drawPath(
      near,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base.dy),
          Offset(0, y(.584)),
          [const Color(0xff9a7458), const Color(0xff5a4658), const Color(0xff2b2a4e), voidTop],
          const [0, .3, .62, 1],
        ),
    );
    c.save();
    c.clipPath(near);
    final ribs = Path();
    for (final z in const [.25, .5, .75]) {
      ribs
        ..moveTo(xc - f * z - aw, spring)
        ..arcToPoint(
          Offset(xc - f * z + aw, spring),
          radius: Radius.elliptical(aw, ry),
          clockwise: true,
        )
        ..moveTo(xc + aw - f * z, spring)
        ..lineTo(xc + aw - f * z, base.dy);
    }
    c.drawPath(ribs, line..color = Sketch.fade(hi, .18));
    c.drawLine(Offset(xc + aw - f, spring), Offset(xc + aw, spring), line..color = Sketch.fade(hi, .3));
    c.drawPath(
      arch(xc - f, aw, ry, spring, base.dy),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y(.584)),
          Offset(0, base.dy),
          [const Color(0xff6d5f86), const Color(0xff3a3660), const Color(0xff262848)],
          const [0, .25, .8],
        ),
    );
    for (var i = 0; i < 5; i++) {
      c.drawCircle(
        Offset(xc - aw + s * (.012 + .07 * Sketch.hash(i + 660)), y(.06 + .3 * Sketch.hash(i + 661))),
        math.max(.5, s * .0045),
        p..color = Sketch.fade(_gold, .85),
      );
    }
    c.restore();

    // Winged victories in the spandrels, blowing their trumpets.
    void victory(double px, double py, double dir) {
      c.save();
      c.translate(px, py);
      c.scale(dir, 1);
      c.rotate(-.5);
      c.drawOval(Rect.fromCenter(center: Offset(-s * .006, -s * .018), width: s * .046, height: s * .013), p..color = mid);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * .06, height: s * .02), p..color = mid);
      c.drawOval(Rect.fromCenter(center: Offset(s * .004, -s * .004), width: s * .05, height: s * .011), p..color = hi);
      c.drawCircle(Offset(s * .034, -s * .005), s * .009, p..color = hi);
      c.drawLine(Offset(s * .04, -s * .008), Offset(s * .07, -s * .03), line..color = Sketch.fade(hi, .8));
      c.restore();
    }

    victory(xc - s * .105, y(.615), 1);
    victory(xc + s * .105, y(.615), -1);

    // Moonlight rakes the right-hand edge and the ledges that face up.
    c.drawRect(
      Rect.fromLTRB(xr - s * .05, y(.962), xr, y(.05)),
      Paint()
        ..shader = Gradient.linear(
          Offset(xr - s * .05, 0),
          Offset(xr, 0),
          [Sketch.fade(_moonlit, 0), Sketch.fade(_moonlit, .3)],
        ),
    );
    rect(Rect.fromLTRB(xr - math.max(.7, s * .007), y(.962), xr, y(.05)), Sketch.fade(_moonlit, .6));
    rect(Rect.fromLTRB(xr, y(.772), xr + o1, y(.722)), Sketch.fade(_moonlit, .55));
    rect(Rect.fromLTRB(xr, y(1.0), xr + o2, y(.962)), Sketch.fade(_moonlit, .55));
    rect(Rect.fromLTRB(xf - o2, y(1.0), xr + o2, y(1.0) + hair), Sketch.fade(_moonlit, .7));
    rect(Rect.fromLTRB(xf - o1, y(.772), xr + o1, y(.772) + hair), Sketch.fade(_moonlit, .5));
    rect(Rect.fromLTRB(xl - o2, y(1.0), xf - o2 + seam, y(1.0) + hair), Sketch.fade(hiShade, .5));
  }

  /// The eternal flame under the arch, guttering on its own beat, and the
  /// warm light it throws on the vault, the wall and the ground. Drawn over
  /// the ridge each frame, in the coordinates of [_arc].
  static void _arcGlow(Canvas c, Offset base, double s, double clock, double presence) {
    if (presence <= 0) return;
    final flick = .84 + .1 * math.sin(clock * 9.3) + .06 * math.sin(clock * 5.7 + 1.3);
    final fx = base.dx, fy = base.dy - s * .05;
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(fx + s * .07, base.dy - s * .16), width: s * .26, height: s * .26),
      const Color(0xffffa050),
      .18 * flick * presence,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(fx, base.dy - s * .045), width: s * .9, height: s * .09),
      _gold,
      .2 * flick * presence,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(fx, fy - s * .04), width: s * .2, height: s * .2),
      const Color(0xffffb050),
      .6 * flick * presence,
    );
    // The slab of the Unknown Soldier, and the flame: an orange tongue round
    // a pale core.
    c.drawRect(
      Rect.fromLTRB(fx - s * .032, fy - s * .004, fx + s * .032, fy + s * .01),
      _arcInk..color = Sketch.fade(const Color(0xffb8a8a4), .85 * presence),
    );
    final tall = s * .052 * (.75 + .25 * flick);
    c.drawOval(
      Rect.fromLTRB(fx - s * .011, fy - tall, fx + s * .011, fy),
      _arcInk..color = Sketch.fade(const Color(0xffff9a3a), .95 * presence),
    );
    c.drawOval(
      Rect.fromLTRB(fx - s * .005, fy - tall * .62, fx + s * .005, fy),
      _arcInk..color = Sketch.fade(const Color(0xffffeaa8), presence),
    );
  }

  static const _bridgeLamps = 5;

  /// Bays along the bridge. A pier stands between each pair, with a lamp on
  /// every second one ([_bridgeLamps] of them, the two ends included) and a
  /// gilded statue on those between.
  static const _bridgeArches = 8;

  /// The bridge's proportions, in viewport heights: half its length, the pier
  /// spacing and a pier's half width, the height the arches spring from above
  /// the waterline and their rise, the depth of the voussoir ring, the height
  /// of the cornice's underside, and where a lamp's main globe hangs.
  static const _bridgeHalfU = .85;
  static const _bridgePitch = 2 * _bridgeHalfU / _bridgeArches;
  static const _bridgePier = .0165;
  static const _bridgeSpring = .010;
  static const _bridgeRise = .034;
  static const _bridgeRing = .0105;
  static const _bridgeWallTop = .0585;
  static const _bridgeGlobeV = .1135;

  static const _bridgeStone = Color(0xff4d4e75);
  static const _bridgeBronze = Color(0xff2b2338);
  static const _bridgeGilt = Color(0xffd9a84c);
  static const _bridgeGiltHi = Color(0xffffe28e);
  static const _bridgeGiltLow = Color(0xff8a6a32);

  /// The recorded bridge, one picture per viewport height, and a paint for the
  /// per-frame water work.
  static final _bridgePictures = <double, Picture>{};
  static final _bridgeInk = Paint();

  static double _bridgeHalf(double h) => h * _bridgeHalfU;
  static double _bridgeLampX(double cx, double h, int i) =>
      cx - _bridgeHalf(h) + _bridgeHalf(h) * 2 * i / (_bridgeLamps - 1);

  /// A stone bridge of eight elliptical arches, after Pont Neuf and Pont
  /// Alexandre III: ashlar piers with rounded cutwaters and gilded medallions,
  /// voussoir rings closing on carved keystones, a dentilled cornice, a
  /// balustrade with a candelabra lamp or a gilded statue on every pier, and
  /// approach ramps running down to the quays. The moon lights every right
  /// flank and leaves every left one in shade. The arches show the far bank
  /// (and the boat, which sails behind them). It never moves, so it is
  /// recorded once per viewport height and only replayed each frame.
  static void _bridge(Canvas c, double cx, double waterY, double h) {
    var picture = _bridgePictures.remove(h);
    if (picture == null) {
      final recorder = PictureRecorder();
      _bridgeDraw(Canvas(recorder), h);
      picture = recorder.endRecording();
      if (_bridgePictures.length >= 4) {
        _bridgePictures.remove(_bridgePictures.keys.first)?.dispose();
      }
    }
    _bridgePictures[h] = picture;
    c.save();
    c.translate(cx, waterY);
    c.drawPicture(picture);
    c.restore();
  }

  /// Records the bridge about its centre on the waterline, in viewport
  /// heights: x runs right and y down, so heights above the water are
  /// negative. Everything below the waterline is hidden by the river.
  static void _bridgeDraw(Canvas c, double h) {
    c.scale(h, h);
    // Fine lines stay at least three-quarters of a pixel on small screens.
    final hair = math.max(.0008, .75 / h);
    final a = _bridgePitch / 2 - _bridgePier;
    final arch = <Offset>[
      for (var s = 0; s <= 32; s++)
        Offset(
          -a * math.cos(math.pi * s / 32),
          -(_bridgeSpring + _bridgeRise * math.sin(math.pi * s / 32)),
        ),
    ];
    final openings = Path();
    for (var i = 0; i < _bridgeArches; i++) {
      final xc = -_bridgeHalfU + (i + .5) * _bridgePitch;
      openings.moveTo(xc - a, .02);
      for (final p in arch) {
        openings.lineTo(xc + p.dx, p.dy);
      }
      openings
        ..lineTo(xc + a, .02)
        ..close();
    }
    final wall = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        Rect.fromLTRB(
          -_bridgeHalfU - _bridgePier,
          -_bridgeWallTop,
          _bridgeHalfU + _bridgePier,
          .02,
        ),
      )
      ..addPath(openings, Offset.zero);
    // A film of damp teal darkens the stone where the river wets it.
    final damp = Paint()
      ..shader = Gradient.linear(
        const Offset(0, -.03),
        const Offset(0, .004),
        const [Color(0x001d3446), Color(0xa316283a)],
      );
    for (final side in const [-1.0, 1.0]) {
      _bridgeRamp(c, side, hair, damp);
    }
    c.drawPath(
      wall,
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, -_bridgeWallTop),
          const Offset(0, .004),
          const [Color(0xff5a5b84), _bridgeStone, Color(0xff3f4066)],
          const [0, .45, 1],
        ),
    );
    // The dark of each vault: deepest under the crown, thinning toward the
    // water so the far bank and the boat still show through.
    c.drawPath(
      openings,
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, -(_bridgeSpring + _bridgeRise)),
          const Offset(0, 0),
          const [Color(0xd00f1128), Color(0x590f1128), Color(0x000f1128)],
          const [0, .5, 1],
        ),
    );
    _bridgeMasonry(c, a, hair);
    _bridgeUnderCornice(c);
    _bridgePiers(c, hair);
    _bridgeRings(c, a, hair);
    _bridgeKeys(c, hair);
    c.drawPath(wall, damp);
    _bridgeCornice(c, hair);
    _bridgeBalustrade(c, hair);
    for (var i = 0; i <= _bridgeArches; i++) {
      final x = -_bridgeHalfU + i * _bridgePitch;
      // The end piers are taller pylons.
      final base = i == 0 || i == _bridgeArches ? .0932 : .0892;
      if (i.isEven) {
        _bridgeLampPost(c, x, base);
      } else {
        _bridgeStatue(c, x, base);
      }
    }
  }

  /// Half the width of an arch's opening at [v] above the waterline, given
  /// the half span [a].
  static double _bridgeOpening(double a, double v) {
    if (v <= _bridgeSpring) return a;
    final t = (v - _bridgeSpring) / _bridgeRise;
    return t >= 1 ? 0.0 : a * math.sqrt(1 - t * t);
  }

  /// The ellipse parameters (0 at the left springing, pi at the right) that
  /// cut an arch of half span [a] and rise [b] into [n] arcs of equal length,
  /// so every voussoir is the same size.
  static List<double> _bridgeSplit(double a, double b, int n) {
    const steps = 96;
    final len = List<double>.filled(steps + 1, 0.0);
    var lastX = -a, lastY = 0.0;
    for (var s = 1; s <= steps; s++) {
      final t = math.pi * s / steps;
      final x = -a * math.cos(t), y = b * math.sin(t);
      len[s] = len[s - 1] + math.sqrt((x - lastX) * (x - lastX) + (y - lastY) * (y - lastY));
      lastX = x;
      lastY = y;
    }
    final out = <double>[0.0];
    var j = 0;
    for (var k = 1; k < n; k++) {
      final target = len[steps] * k / n;
      while (j < steps - 1 && len[j + 1] < target) {
        j++;
      }
      final f = (target - len[j]) / (len[j + 1] - len[j]);
      out.add(math.pi * (j + f) / steps);
    }
    out.add(math.pi);
    return out;
  }

  /// The point at parameter [t] of an arch's intrados, pushed [d] outward
  /// along the normal, as (x from the arch centre, height over the springing).
  static (double, double) _bridgeArchPoint(double a, double b, double t, double d) {
    final x = -a * math.cos(t), v = b * math.sin(t);
    final nx = -math.cos(t) / a, nv = math.sin(t) / b;
    final k = d / math.sqrt(nx * nx + nv * nv);
    return (x + nx * k, v + nv * k);
  }

  static Paint _bridgeStroke(double width, Color color, {StrokeCap cap = StrokeCap.butt}) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round
        ..color = color;

  /// Ashlar coursing over the spandrels: joint lines that stop at the
  /// arches, staggered block ends, and a few stones weathered light or dark.
  static void _bridgeMasonry(Canvas c, double a, double hair) {
    const half = _bridgeHalfU, w = _bridgePitch, q = _bridgePier, course = .0085;
    const l = -half - q, r = half + q;
    final joints = Path(), glints = Path(), light = Path(), dark = Path();
    for (var j = 0; j < 7; j++) {
      final v0 = j * course;
      final v1 = math.min(v0 + course, _bridgeWallTop);
      final o = _bridgeOpening(a, v0);
      bool clear(double x0, double x1) {
        for (var i = 0; i < _bridgeArches; i++) {
          final xc = -half + (i + .5) * w;
          if (x1 > xc - o && x0 < xc + o) return false;
        }
        return true;
      }

      if (j > 0) {
        // The bed joint under this course, cut wherever an arch opens.
        var cursor = l;
        for (var i = 0; i < _bridgeArches; i++) {
          final xc = -half + (i + .5) * w;
          if (xc - o > cursor) {
            joints
              ..moveTo(cursor, -v0)
              ..lineTo(xc - o, -v0);
            glints
              ..moveTo(cursor, -v0 + hair * 1.2)
              ..lineTo(xc - o, -v0 + hair * 1.2);
          }
          cursor = xc + o;
        }
        joints
          ..moveTo(cursor, -v0)
          ..lineTo(r, -v0);
        glints
          ..moveTo(cursor, -v0 + hair * 1.2)
          ..lineTo(r, -v0 + hair * 1.2);
      }
      var bx = l + (j.isOdd ? .012 : .0);
      var m = 0;
      while (bx < r - .004) {
        final bw = .022 + .016 * Sketch.hash(j * 131 + m + 900);
        final bx1 = math.min(bx + bw, r);
        if (bx > l + .002 && clear(bx - .0012, bx + .0012)) {
          joints
            ..moveTo(bx, -v0)
            ..lineTo(bx, -v1);
        }
        if (clear(bx + .0012, bx1 - .0012)) {
          final t = Sketch.hash(j * 131 + m + 1300);
          if (t < .12) {
            light.addRect(Rect.fromLTRB(bx + hair, -v1, bx1, -v0));
          } else if (t < .28) {
            dark.addRect(Rect.fromLTRB(bx + hair, -v1, bx1, -v0));
          }
        }
        bx = bx1;
        m++;
      }
    }
    c.drawPath(light, Paint()..color = const Color(0x24b4b6e6));
    c.drawPath(dark, Paint()..color = const Color(0x2e101228));
    c.drawPath(joints, _bridgeStroke(hair, const Color(0x99242645)));
    c.drawPath(glints, _bridgeStroke(hair, const Color(0x30c9cbea)));
  }

  /// The cornice throws a band of shadow onto the wall, over a row of
  /// dentils, the little blocks that carry it.
  static void _bridgeUnderCornice(Canvas c) {
    const l = -_bridgeHalfU - _bridgePier, r = _bridgeHalfU + _bridgePier;
    c.drawRect(
      Rect.fromLTRB(l, -_bridgeWallTop, r, -_bridgeWallTop + .0046),
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, -_bridgeWallTop),
          const Offset(0, -_bridgeWallTop + .0046),
          const [Color(0xb314152c), Color(0x0014152c)],
        ),
    );
    final dentils = Path();
    for (var x = l + .004; x < r - .008; x += .0125) {
      dentils.addRect(Rect.fromLTWH(x, -_bridgeWallTop + .0004, .0062, .0028));
    }
    c.drawPath(dentils, Paint()..color = const Color(0xcc6a6b95));
  }

  /// The piers: rounded cutwaters shaded dark to lit across their nose, on a
  /// footing at the river, with an impost where the arches spring, drum
  /// courses, a gilded medallion and a capital under the cornice.
  static void _bridgePiers(Canvas c, double hair) {
    const q = _bridgePier;
    final joints = Path(), glints = Path(), edge = Path(), lit = Path();
    final footing = Paint()..color = const Color(0xff383a5e);
    final footingLit = Paint()..color = const Color(0xff5a5b84);
    final impost = Paint()..color = const Color(0xff65668f);
    final under = Paint()..color = const Color(0x66101228);
    final cap = Paint()..color = const Color(0xff6d6e98);
    final bronze = Paint()..color = const Color(0xff33293a);
    final boss = Paint()..color = const Color(0x554a3416);
    final spark = Paint()..color = const Color(0xccfff2b8);
    for (var i = 0; i <= _bridgeArches; i++) {
      final px = -_bridgeHalfU + i * _bridgePitch;
      c.drawRect(
        Rect.fromLTRB(px - q, -_bridgeWallTop, px + q, .02),
        Paint()
          ..shader = Gradient.linear(
            Offset(px - q, 0),
            Offset(px + q, 0),
            const [Color(0xff2f3052), Color(0xff44456c), Color(0xff585990), Color(0xff8586b0)],
            const [0, .34, .74, 1],
          ),
      );
      c.drawRect(Rect.fromLTRB(px - q - .003, -.0045, px + q + .003, .02), footing);
      c.drawRect(Rect.fromLTRB(px + q - .004, -.0045, px + q + .003, .02), footingLit);
      c.drawRect(Rect.fromLTRB(px - q - .0034, -.0102, px + q + .0034, -.0068), impost);
      c.drawRect(Rect.fromLTRB(px - q - .0034, -.0068, px + q + .0034, -.0056), under);
      lit
        ..moveTo(px - q - .0034, -.0102)
        ..lineTo(px + q + .0034, -.0102)
        ..moveTo(px + q, -.0555)
        ..lineTo(px + q, -.0102);
      edge
        ..moveTo(px - q, -.0555)
        ..lineTo(px - q, -.0102);
      for (final v in const [.0170, .0255, .0340, .0425, .0510]) {
        joints
          ..moveTo(px - q, -v)
          ..lineTo(px + q, -v);
        glints
          ..moveTo(px - q, -v + hair * 1.2)
          ..lineTo(px + q, -v + hair * 1.2);
      }
      // The capital under the cornice.
      c.drawRect(
        Rect.fromLTRB(px - q - .003, -_bridgeWallTop, px + q + .003, -_bridgeWallTop + .003),
        cap,
      );
      c.drawRect(
        Rect.fromLTRB(px - q, -_bridgeWallTop + .003, px + q, -_bridgeWallTop + .0042),
        under,
      );
      // A gilded medallion on the shaft.
      final m = Offset(px, -.0405);
      c.drawCircle(m, .0079, bronze);
      c.drawCircle(
        m,
        .0069,
        Paint()
          ..shader = Gradient.radial(
            Offset(px + .0018, -.0424),
            .0086,
            const [_bridgeGiltHi, _bridgeGilt, _bridgeGiltLow],
            const [0, .5, 1],
          ),
      );
      c.drawCircle(m, .0030, boss);
      c.drawCircle(Offset(px + .0009, -.0414), .0014, spark);
    }
    c.drawPath(joints, _bridgeStroke(hair, const Color(0x99242645)));
    c.drawPath(glints, _bridgeStroke(hair, const Color(0x30c9cbea)));
    c.drawPath(edge, _bridgeStroke(hair * 1.3, const Color(0x99101228)));
    c.drawPath(lit, _bridgeStroke(hair * 1.3, const Color(0x99c9cbea)));
  }

  /// The voussoir rings: thirteen equal stones to an arch, alternately
  /// toned, with their joints normal to the curve, a moonlit rim on the
  /// upper right and a shaded reveal on the right of each opening.
  static void _bridgeRings(Canvas c, double a, double hair) {
    const sp = _bridgeSpring, rise = _bridgeRise, d = _bridgeRing, blocks = 13;
    final phi = _bridgeSplit(a, rise, blocks);
    final ring = Path(), tone = Path(), joints = Path();
    final edge = Path(), rimLit = Path(), inLit = Path(), inDark = Path();
    for (var i = 0; i < _bridgeArches; i++) {
      final xc = -_bridgeHalfU + (i + .5) * _bridgePitch;
      // The outer edge, over the crown from the left springing...
      for (var s = 0; s <= 40; s++) {
        final (x, v) = _bridgeArchPoint(a, rise, math.pi * s / 40, d);
        final px = xc + x, py = -(sp + v);
        if (s == 0) {
          ring.moveTo(px, py);
          edge.moveTo(px, py);
        } else {
          ring.lineTo(px, py);
          edge.lineTo(px, py);
        }
        if (s == 20) {
          rimLit.moveTo(px, py);
        } else if (s > 20) {
          rimLit.lineTo(px, py);
        }
      }
      // ...and back along the intrados, whose left half catches the light.
      for (var s = 40; s >= 0; s--) {
        final (x, v) = _bridgeArchPoint(a, rise, math.pi * s / 40, 0);
        ring.lineTo(xc + x, -(sp + v));
      }
      ring.close();
      for (var s = 0; s <= 40; s++) {
        final (x, v) = _bridgeArchPoint(a, rise, math.pi * s / 40, 0);
        final px = xc + x, py = -(sp + v);
        if (s <= 20) {
          if (s == 0) {
            inLit.moveTo(px, py);
          } else {
            inLit.lineTo(px, py);
          }
        }
        if (s >= 20) {
          if (s == 20) {
            inDark.moveTo(px, py);
          } else {
            inDark.lineTo(px, py);
          }
        }
      }
      for (var k = 1; k < blocks; k++) {
        final (ix, iv) = _bridgeArchPoint(a, rise, phi[k], 0);
        final (ox, ov) = _bridgeArchPoint(a, rise, phi[k], d);
        joints
          ..moveTo(xc + ix, -(sp + iv))
          ..lineTo(xc + ox, -(sp + ov));
      }
      // Every second stone a shade darker; the keystone (6) stays plain.
      for (var k = 1; k < blocks; k += 2) {
        for (var s = 0; s <= 3; s++) {
          final (x, v) = _bridgeArchPoint(a, rise, phi[k] + (phi[k + 1] - phi[k]) * s / 3, d);
          if (s == 0) {
            tone.moveTo(xc + x, -(sp + v));
          } else {
            tone.lineTo(xc + x, -(sp + v));
          }
        }
        for (var s = 3; s >= 0; s--) {
          final (x, v) = _bridgeArchPoint(a, rise, phi[k] + (phi[k + 1] - phi[k]) * s / 3, 0);
          tone.lineTo(xc + x, -(sp + v));
        }
        tone.close();
      }
    }
    c.drawPath(
      ring,
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, -.0555),
          const Offset(0, -.010),
          const [Color(0xff6b6c97), Color(0xff585990)],
        ),
    );
    c.drawPath(tone, Paint()..color = const Color(0x22101228));
    c.drawPath(joints, _bridgeStroke(hair, const Color(0xb3242645)));
    c.drawPath(edge, _bridgeStroke(hair * 1.2, const Color(0x99191a35)));
    c.drawPath(rimLit, _bridgeStroke(hair * 1.4, const Color(0xd0c9cbea)));
    c.drawPath(inLit, _bridgeStroke(hair * 1.1, const Color(0x70c9cbea)));
    c.drawPath(inDark, _bridgeStroke(hair * 1.5, const Color(0xa0101228)));
    // Each pier throws a soft shadow on the arch to its left.
    for (var i = 0; i <= _bridgeArches; i++) {
      final x = -_bridgeHalfU + i * _bridgePitch - _bridgePier;
      c.drawRect(
        Rect.fromLTRB(x - .0075, -_bridgeWallTop, x, .02),
        Paint()
          ..shader = Gradient.linear(
            Offset(x - .0075, 0),
            Offset(x, 0),
            const [Color(0x0014152c), Color(0x4014152c)],
          ),
      );
    }
  }

  /// The keystones, each a projecting block with a grotesque mask: a leafy
  /// crest, a lit brow and cheek, dark eyes, an open mouth and a beard.
  static void _bridgeKeys(Canvas c, double hair) {
    const kb = _bridgeSpring + _bridgeRise, kt = _bridgeWallTop;
    final stone = Paint()..color = const Color(0xff696a94);
    final lit = Paint()..color = const Color(0xff8586b0);
    final crest = Paint()..color = const Color(0xff45466e);
    final face = Paint()..color = const Color(0xff7a7ba6);
    final dark = Paint()..color = const Color(0xff1b1c38);
    final shade = Paint()..color = const Color(0x40101228);
    final glint = Paint()..color = const Color(0x55e6e8ff);
    final outline = _bridgeStroke(hair, const Color(0xb3191a35));
    final nose = _bridgeStroke(hair * .9, const Color(0x99191a35));
    for (var i = 0; i < _bridgeArches; i++) {
      final xc = -_bridgeHalfU + (i + .5) * _bridgePitch;
      final key = Sketch.poly([
        xc - .0055, -(kb - .003),
        xc + .0055, -(kb - .003),
        xc + .0079, -kb,
        xc + .0094, -kt,
        xc - .0094, -kt,
        xc - .0079, -kb,
      ]);
      c.drawPath(key, stone);
      c.drawPath(
        Sketch.poly([
          xc, -(kb - .003),
          xc + .0055, -(kb - .003),
          xc + .0079, -kb,
          xc + .0094, -kt,
          xc, -kt,
        ]),
        lit,
      );
      c.drawPath(key, outline);
      c.drawPath(
        Sketch.poly([
          xc - .0046, -.0530,
          xc - .0034, -.0562,
          xc - .0012, -.0552,
          xc, -.0572,
          xc + .0012, -.0552,
          xc + .0034, -.0562,
          xc + .0046, -.0530,
        ]),
        crest,
      );
      final oval = Rect.fromCenter(center: Offset(xc, -.0508), width: .0074, height: .0088);
      c.drawOval(oval, face);
      c.drawPath(
        Path()
          ..addArc(oval, math.pi / 2, math.pi)
          ..close(),
        shade,
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(xc + .0013, -.0521), width: .0028, height: .0034),
        glint,
      );
      for (final s in const [-1.0, 1.0]) {
        c.drawOval(
          Rect.fromCenter(center: Offset(xc + s * .0014, -.0516), width: .0012, height: .0007),
          dark,
        );
      }
      c.drawLine(Offset(xc, -.0513), Offset(xc, -.0499), nose);
      c.drawOval(
        Rect.fromCenter(center: Offset(xc, -.0486), width: .0022, height: .0011),
        dark,
      );
      c.drawPath(Sketch.poly([xc - .0030, -.0474, xc + .0030, -.0474, xc, -.0453]), crest);
    }
  }

  /// The cornice: a projecting moulded band, brightest along its moonlit top,
  /// stepping forward over each pier.
  static void _bridgeCornice(Canvas c, double hair) {
    const l = -_bridgeHalfU - .0205, r = _bridgeHalfU + .0205;
    const top = -.0655, bottom = -_bridgeWallTop;
    c.drawRect(
      Rect.fromLTRB(l, top, r, bottom),
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, top),
          const Offset(0, bottom),
          const [Color(0xff8586b0), Color(0xff6c6d97), Color(0xff575890), Color(0xff44456c)],
          const [0, .28, .68, 1],
        ),
    );
    final seams = Path()
      ..moveTo(l, -.0606)
      ..lineTo(r, -.0606)
      ..moveTo(l, -.0634)
      ..lineTo(r, -.0634);
    final seamLit = Path()
      ..moveTo(l, -.0606 + hair * 1.3)
      ..lineTo(r, -.0606 + hair * 1.3)
      ..moveTo(l, -.0634 + hair * 1.3)
      ..lineTo(r, -.0634 + hair * 1.3);
    c.drawPath(seams, _bridgeStroke(hair, const Color(0x99191a35)));
    c.drawPath(seamLit, _bridgeStroke(hair, const Color(0x40c9cbea)));
    // Over every pier the cornice breaks forward.
    final block = Paint()..color = const Color(0x22b4b6e6);
    final blockEdge = Path();
    final blockLit = Path();
    for (var i = 0; i <= _bridgeArches; i++) {
      final px = -_bridgeHalfU + i * _bridgePitch;
      c.drawRect(Rect.fromLTRB(px - .0185, top, px + .0185, bottom), block);
      blockEdge
        ..moveTo(px - .0185, top)
        ..lineTo(px - .0185, bottom);
      blockLit
        ..moveTo(px + .0185, top)
        ..lineTo(px + .0185, bottom);
    }
    c.drawPath(blockEdge, _bridgeStroke(hair, const Color(0x80191a35)));
    c.drawPath(blockLit, _bridgeStroke(hair, const Color(0x80c9cbea)));
    c.drawLine(
      const Offset(l, top),
      const Offset(r, top),
      _bridgeStroke(hair * 1.5, const Color(0xe6dfe1f6)),
    );
  }

  /// The balustrade: a plinth, vase balusters lit on their right over a dark
  /// backing, a moonlit rail, and a pedestal on every pier.
  static void _bridgeBalustrade(Canvas c, double hair) {
    const half = _bridgeHalfU, w = _bridgePitch, n = _bridgeArches;
    const l = -half - .0205, r = half + .0205;
    const base = .0678, tall = .0094, count = 15;
    // Turned profile of a baluster: (height fraction, half width).
    const profile = [
      (0.0, .0017),
      (.10, .0020),
      (.17, .0012),
      (.48, .0030),
      (.80, .0012),
      (.90, .0021),
      (1.0, .0017),
    ];
    c.drawRect(Rect.fromLTRB(l, -base, r, -.0655), Paint()..color = const Color(0xff65668f));
    final back = Path(), body = Path(), lit = Path();
    for (var i = 0; i < n; i++) {
      final x0 = -half + i * w + .0125, x1 = -half + (i + 1) * w - .0125;
      back.addRect(Rect.fromLTRB(x0, -.0772, x1, -base));
      final pitch = (x1 - x0) / count;
      for (var k = 0; k < count; k++) {
        final bx = x0 + (k + .5) * pitch;
        body.moveTo(bx - profile.first.$2, -base);
        lit.moveTo(bx, -base);
        for (final (t, hw) in profile) {
          body.lineTo(bx + hw, -(base + t * tall));
          lit.lineTo(bx + hw, -(base + t * tall));
        }
        lit
          ..lineTo(bx, -(base + tall))
          ..close();
        for (final (t, hw) in profile.reversed) {
          body.lineTo(bx - hw, -(base + t * tall));
        }
        body.close();
      }
    }
    c.drawPath(back, Paint()..color = const Color(0xd022243f));
    c.drawPath(body, Paint()..color = const Color(0xff6a6b95));
    c.drawPath(lit, Paint()..color = const Color(0x99a5a6cc));
    // The rail, with its moonlit top and the shadow under it.
    c.drawRect(Rect.fromLTRB(l, -.0800, r, -.0772), Paint()..color = const Color(0xff6d6e99));
    c.drawRect(Rect.fromLTRB(l, -.0800, r, -.0792), Paint()..color = const Color(0xff9394bd));
    c.drawRect(Rect.fromLTRB(l, -.0772, r, -.0768), Paint()..color = const Color(0x88101228));
    c.drawLine(
      const Offset(l, -.0800),
      const Offset(r, -.0800),
      _bridgeStroke(hair * 1.3, const Color(0xf0dfe1f6)),
    );
    final die = Paint()..color = const Color(0xff585990);
    final dieLit = Paint()..color = const Color(0xff7b7ca6);
    final dieShade = Paint()..color = const Color(0xff44456c);
    final capFill = Paint()..color = const Color(0xff6f7099);
    final capLit = Paint()..color = const Color(0xff9394bd);
    final panel = _bridgeStroke(hair, const Color(0x66101228));
    for (var i = 0; i <= n; i++) {
      final px = -half + i * w;
      final end = i == 0 || i == n;
      final hw = end ? .0165 : .0125;
      final top = end ? .0905 : .0865;
      final cap = end ? .0208 : .0158;
      c.drawRect(Rect.fromLTRB(px - hw, -top, px + hw, -.0655), die);
      c.drawRect(Rect.fromLTRB(px + hw * .35, -top, px + hw, -.0655), dieLit);
      c.drawRect(Rect.fromLTRB(px - hw, -top, px - hw * .7, -.0655), dieShade);
      c.drawRect(
        Rect.fromLTRB(px - hw + .003, -top + .004, px + hw - .003, -.0655 - .004),
        panel,
      );
      c.drawRect(Rect.fromLTRB(px - cap, -top - .0027, px + cap, -top), capFill);
      c.drawRect(Rect.fromLTRB(px - cap, -top - .0027, px + cap, -top - .0020), capLit);
    }
  }

  /// A candelabra lamp on a pier cap [base] over the water: a bronze shaft
  /// with gilt collars and scrolled brackets, two side arms and a main globe,
  /// each a glowing sphere, under a crown and finial.
  static void _bridgeLampPost(Canvas c, double x, double base) {
    const gc = _bridgeGlobeV;
    // Warm light washes the parapet, and each globe has its halo.
    final wash = Offset(x, -.092);
    c.drawCircle(
      wash,
      .052,
      Paint()
        ..shader = Gradient.radial(
          wash,
          .052,
          const [Color(0x2effd98a), Color(0x00ffd98a)],
        ),
    );
    for (final (dx, v, r) in const [
      (0.0, gc, .034),
      (-.0125, .108, .018),
      (.0125, .108, .018),
    ]) {
      final at = Offset(x + dx, -v);
      c.drawCircle(
        at,
        r,
        Paint()
          ..shader = Gradient.radial(
            at,
            r,
            const [Color(0x66ffdc8a), Color(0x00ffdc8a)],
          ),
      );
    }
    final bronze = Paint()..color = _bridgeBronze;
    final bronzeLit = Paint()..color = const Color(0xff6a5866);
    final gilt = Paint()..color = _bridgeGilt;
    c.drawRect(Rect.fromLTRB(x - .0056, -(base + .0034), x + .0056, -base), bronze);
    c.drawRect(Rect.fromLTRB(x + .0022, -(base + .0034), x + .0056, -base), bronzeLit);
    c.drawRect(Rect.fromLTRB(x - .0056, -(base + .0034), x + .0056, -(base + .0027)), gilt);
    final scrolls = Path();
    final arms = Path();
    for (final s in const [-1.0, 1.0]) {
      scrolls
        ..moveTo(x + s * .0050, -(base + .0030))
        ..quadraticBezierTo(x + s * .0054, -(base + .0074), x + s * .0012, -(base + .0090));
      arms
        ..moveTo(x, -.1000)
        ..quadraticBezierTo(x + s * .0092, -.1000, x + s * .0125, -.1040);
    }
    final ironwork = _bridgeStroke(.0011, _bridgeBronze, cap: StrokeCap.round);
    c.drawPath(scrolls, ironwork);
    c.drawPath(arms, ironwork);
    c.drawPath(
      Sketch.poly([
        x - .0027, -(base + .0034),
        x + .0027, -(base + .0034),
        x + .0013, -.1045,
        x - .0013, -.1045,
      ]),
      bronze,
    );
    c.drawPath(
      Sketch.poly([
        x + .0004, -(base + .0034),
        x + .0027, -(base + .0034),
        x + .0013, -.1045,
        x + .0004, -.1045,
      ]),
      bronzeLit,
    );
    for (final v in const [.0990, .1030]) {
      c.drawRect(Rect.fromLTRB(x - .0032, -(v + .0011), x + .0032, -v), gilt);
    }
    // The cups under the globes.
    c.drawPath(
      Sketch.poly([x - .0016, -.1040, x + .0016, -.1040, x + .0046, -.1074, x - .0046, -.1074]),
      bronze,
    );
    c.drawRect(Rect.fromLTRB(x - .0050, -.1079, x + .0050, -.1073), gilt);
    for (final s in const [-1.0, 1.0]) {
      c.drawRect(
        Rect.fromCenter(center: Offset(x + s * .0125, -.1046), width: .0036, height: .0012),
        gilt,
      );
    }
    for (final (dx, v, r) in const [
      (-.0125, .1080, .0041),
      (.0125, .1080, .0041),
      (0.0, gc, .0068),
    ]) {
      final at = Offset(x + dx, -v);
      c.drawCircle(
        at,
        r,
        Paint()
          ..shader = Gradient.radial(
            at,
            r,
            const [Color(0xfffffbe6), Color(0xffffdf88), Color(0xffe6a54a)],
            const [0, .62, 1],
          ),
      );
    }
    c.drawPath(
      Sketch.poly([
        x - .0046, -(gc + .0060),
        x + .0046, -(gc + .0060),
        x + .0018, -(gc + .0104),
        x - .0018, -(gc + .0104),
      ]),
      bronze,
    );
    c.drawRect(Rect.fromLTRB(x - .0052, -(gc + .0066), x + .0052, -(gc + .0059)), gilt);
    c.drawCircle(Offset(x, -(gc + .0118)), .0015, gilt);
  }

  /// A gilded winged Fame with her trumpet on a pier cap [base] over the
  /// water, on a bronze plinth: the far wing and her left flank in shade,
  /// the right lit.
  static void _bridgeStatue(Canvas c, double x, double base) {
    final feet = base + .0024;
    Path shape(List<double> xy, [double flip = 1]) {
      final path = Path()..moveTo(x + xy[0] * flip, -(feet + xy[1]));
      for (var i = 2; i + 1 < xy.length; i += 2) {
        path.lineTo(x + xy[i] * flip, -(feet + xy[i + 1]));
      }
      return path..close();
    }

    c.drawRect(
      Rect.fromLTRB(x - .0068, -feet, x + .0068, -base),
      Paint()..color = _bridgeGiltLow,
    );
    c.drawRect(
      Rect.fromLTRB(x + .0020, -feet, x + .0068, -base),
      Paint()..color = _bridgeGilt,
    );
    const wing = [
      -.0010, .0196, -.0034, .0222, -.0068, .0270, -.0092, .0322, -.0100, .0350,
      -.0086, .0330, -.0088, .0312, -.0074, .0304, -.0076, .0286, -.0062, .0278,
      -.0062, .0262, -.0048, .0254, -.0046, .0240, -.0030, .0232, -.0016, .0222,
    ];
    c.drawPath(shape(wing), Paint()..color = const Color(0xffa87c34));
    c.drawPath(shape(wing, -1), Paint()..color = _bridgeGilt);
    const robe = [
      -.0040, 0.0, -.0034, .0045, -.0020, .0110, -.0018, .0160, -.0030, .0195, -.0016, .0212,
      .0016, .0212, .0030, .0195, .0018, .0160, .0022, .0110, .0036, .0045, .0040, 0.0,
    ];
    c.drawPath(shape(robe), Paint()..color = _bridgeGilt);
    c.drawPath(
      shape(const [
        -.0040, 0.0, -.0034, .0045, -.0020, .0110, -.0018, .0160,
        -.0030, .0195, -.0016, .0212, 0.0, .0212, 0.0, 0.0,
      ]),
      Paint()..color = const Color(0x59613f10),
    );
    c.drawPath(
      shape(const [
        0.0, 0.0, .0040, 0.0, .0036, .0045, .0022, .0110,
        .0018, .0160, .0030, .0195, .0016, .0212, 0.0, .0212,
      ]),
      Paint()..color = const Color(0xb3ffe28e),
    );
    final head = Offset(x, -(feet + .0240));
    c.drawCircle(head, .0028, Paint()..color = _bridgeGilt);
    c.drawCircle(head + const Offset(.0008, -.0004), .0014, Paint()..color = _bridgeGiltHi);
    // The raised right arm and the trumpet it sounds.
    c.drawLine(
      Offset(x + .0026, -(feet + .0192)),
      Offset(x + .0062, -(feet + .0262)),
      _bridgeStroke(.0012, _bridgeGilt, cap: StrokeCap.round),
    );
    c.drawPath(
      shape(const [.0056, .0266, .0103, .0325, .0121, .0307, .0060, .0262]),
      Paint()..color = _bridgeGiltHi,
    );
  }

  /// One approach ramp, on [side] (-1 left, 1 right): a quay parapet with a
  /// coping, panels, a string course continuing the cornice and courses that
  /// run down into the water, ending in a post topped with a ball.
  static void _bridgeRamp(Canvas c, double side, double hair, Paint damp) {
    const run = .2, x0 = _bridgeHalfU + _bridgePier, top0 = .0800, top1 = .0125;
    double px(double u) => side * (x0 + u);
    double tv(double u) => top0 + (top1 - top0) * u / run;
    // A strip between two lines parallel to the coping, [from] and [to] below it.
    Path band(double from, double to) => Path()
      ..moveTo(px(0), -(top0 - from))
      ..lineTo(px(run), -(top1 - from))
      ..lineTo(px(run), -(top1 - to))
      ..lineTo(px(0), -(top0 - to))
      ..close();
    final body = Path()
      ..moveTo(px(0), -top0)
      ..lineTo(px(run), -top1)
      ..lineTo(px(run), .02)
      ..lineTo(px(0), .02)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, -.08),
          const Offset(0, .004),
          const [Color(0xff5a5b84), _bridgeStone, Color(0xff3f4066)],
          const [0, .5, 1],
        ),
    );
    c.drawPath(band(.0135, .0157), Paint()..color = const Color(0x40b4b6e6));
    c.drawPath(band(.0157, .0176), Paint()..color = const Color(0x55101228));
    c.drawPath(band(0, .0030), Paint()..color = const Color(0xff6a6b95));
    final joints = Path(), glints = Path();
    for (var k = 1; k <= 9; k++) {
      final off = .0176 + k * .0085;
      joints
        ..moveTo(px(0), -(top0 - off))
        ..lineTo(px(run), -(top1 - off));
      glints
        ..moveTo(px(0), -(top0 - off) + hair * 1.2)
        ..lineTo(px(run), -(top1 - off) + hair * 1.2);
    }
    for (var u = .034; u < run - .01; u += .034) {
      joints
        ..moveTo(px(u), -(tv(u) - .0030))
        ..lineTo(px(u), -(tv(u) - .0135));
    }
    c.drawPath(joints, _bridgeStroke(hair, const Color(0x99242645)));
    c.drawPath(glints, _bridgeStroke(hair, const Color(0x30c9cbea)));
    c.drawLine(
      Offset(px(0), -top0),
      Offset(px(run), -top1),
      _bridgeStroke(hair * 1.4, const Color(0xdcc9cbea)),
    );
    // The far end faces the moon on the right and is in shade on the left.
    final end = px(run);
    c.drawRect(
      Rect.fromLTRB(math.min(end, end - side * .0034), -top1, math.max(end, end - side * .0034), .02),
      Paint()..color = side > 0 ? const Color(0x88aeb0e0) : const Color(0x66101228),
    );
    // The end post.
    final pp = px(run - .011), foot = tv(run - .011) - .003;
    c.drawRect(
      Rect.fromLTRB(pp - .0055, -(foot + .0105), pp + .0055, -foot),
      Paint()..color = const Color(0xff585990),
    );
    c.drawRect(
      Rect.fromLTRB(pp + .002, -(foot + .0105), pp + .0055, -foot),
      Paint()..color = const Color(0xff7b7ca6),
    );
    c.drawRect(
      Rect.fromLTRB(pp - .0072, -(foot + .0125), pp + .0072, -(foot + .0105)),
      Paint()..color = const Color(0xff6f7099),
    );
    final ball = Offset(pp, -(foot + .0125 + .0034));
    c.drawCircle(
      ball,
      .0040,
      Paint()
        ..shader = Gradient.radial(
          ball + const Offset(.0012, -.0012),
          .0048,
          const [Color(0xffa6a8d0), Color(0xff5d5e88), Color(0xff34355a)],
          const [0, .5, 1],
        ),
    );
    c.drawPath(body, damp);
  }

  /// The bridge standing in the river: piers, spandrels, cornice and
  /// balustrade mirrored under the waterline in ripple-broken slices that sway
  /// and fade with depth, with dark water pooling in each arch and a lap of
  /// light round every pier's foot. Drawn over the river's own shadow.
  static void _bridgeReflection(
    Canvas c,
    double cx,
    double water,
    double h,
    double clock,
    double presence,
  ) {
    if (presence <= 0) return;
    const half = _bridgeHalfU, w = _bridgePitch, q = _bridgePier;
    final a = w / 2 - q;
    final ink = _bridgeInk;
    c.save();
    c.translate(cx, water);
    c.scale(h, h);
    for (var s = 0; s < 10; s++) {
      final v0 = s * .0084 - (s == 0 ? .004 : 0.0);
      final v1 = s * .0084 + .0056;
      final vm = (v0 + v1) / 2;
      final fade = 1 - s * .07;
      final sway = math.sin(clock * 1.3 + s * 1.7) * .0018 * (1 + s * .25);
      if (vm < _bridgeWallTop) {
        final o = _bridgeOpening(a, vm);
        ink.color = Sketch.fade(_bridgeStone, .4 * fade * presence);
        if (o <= 0) {
          c.drawRect(Rect.fromLTRB(-half - q + sway, v0, half + q + sway, v1), ink);
        } else {
          var x = -half - q;
          for (var i = 0; i < _bridgeArches; i++) {
            final xc = -half + (i + .5) * w;
            c.drawRect(Rect.fromLTRB(x + sway, v0, xc - o + sway, v1), ink);
            x = xc + o;
          }
          c.drawRect(Rect.fromLTRB(x + sway, v0, half + q + sway, v1), ink);
          ink.color = Sketch.fade(const Color(0xff0b0d24), .22 * fade * presence);
          for (var i = 0; i < _bridgeArches; i++) {
            final xc = -half + (i + .5) * w;
            c.drawRect(Rect.fromLTRB(xc - o + sway, v0, xc + o + sway, v1), ink);
          }
        }
      } else if (vm < .0655) {
        ink.color = Sketch.fade(const Color(0xff8586b0), .3 * fade * presence);
        c.drawRect(Rect.fromLTRB(-half - .0205 + sway, v0, half + .0205 + sway, v1), ink);
      } else if (vm < .08) {
        ink.color = Sketch.fade(const Color(0xff5d5e88), .17 * fade * presence);
        c.drawRect(Rect.fromLTRB(-half - .0205 + sway, v0, half + .0205 + sway, v1), ink);
        ink.color = Sketch.fade(const Color(0xff6f7099), .3 * fade * presence);
        for (var i = 0; i <= _bridgeArches; i++) {
          final px = -half + i * w;
          c.drawRect(Rect.fromLTRB(px - .0125 + sway, v0, px + .0125 + sway, v1), ink);
        }
      }
    }
    ink
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .0011;
    for (var i = 0; i <= _bridgeArches; i++) {
      final px = -half + i * w;
      final t = math.sin(clock * 1.6 + i * 1.3) * .002;
      for (var k = 0; k < 3; k++) {
        final len = .027 - k * .0085;
        final y = .0006 + k * .0046;
        ink.color = Sketch.fade(_moonlit, (.34 - k * .1) * presence);
        c.drawLine(Offset(px - len + t, y), Offset(px + len + t, y), ink);
      }
    }
    c.restore();
  }

  // ---------------------------------------------------------------------------
  // The bateau-mouche, drawn in boat space: one unit is the boat's scale, x
  // runs toward the bow, y grows downward and 0 is the waterline amidships.
  // Every outline is built once; a frame only moves, scales and tints them.

  static const _boatHullC = Color(0xff1f2140);
  static const _boatBandC = Color(0xffd6d2e8);
  static const _boatBandLitC = Color(0xffeeeaf8);
  static const _boatFrameC = Color(0xff25233f);
  static const _boatPaneC = Color(0xffffc45a);
  static const _boatPaneHiC = Color(0xffffe7a6);
  static const _boatFolkC = Color(0xff2a1c30);
  static const _boatGlassC = Color(0xff5d6899);
  static const _boatRailC = Color(0xffb4b9d9);
  static const _boatMoonC = Color(0xffeaf0ff);
  static const _boatBeamC = Color(0xfffff2d0);

  static final _boatInk = Paint();
  static final _boatLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _boatTmp = Path();

  /// The deck line: low amidships, lifting toward the bow.
  static double _boatSheer(double x) => x > .3
      ? -.19 - .1 * (x - .3) * (x - .3)
      : -.19 - .03 * (.3 - x) * (.3 - x) / 2.1316;

  /// The raked glass front of the saloon and the wheelhouse over it.
  static double _boatFront(double y) => .62 + .4 * (y + .2);

  /// The saloon's roof crown, a shallow arch.
  static double _boatRoof(double x) => .0656 * x * x + .0219 * x - .6288;

  /// A band of hull between two depths under the deck line.
  static Path _boatStrip(double x0, double x1, double d0, double d1) {
    const n = 24;
    final p = Path()..moveTo(x0, _boatSheer(x0) + d0);
    for (var i = 1; i <= n; i++) {
      final x = x0 + (x1 - x0) * i / n;
      p.lineTo(x, _boatSheer(x) + d0);
    }
    for (var i = n; i >= 0; i--) {
      final x = x0 + (x1 - x0) * i / n;
      p.lineTo(x, _boatSheer(x) + d1);
    }
    return p..close();
  }

  static final Path _boatHull = () {
    final p = Path()..moveTo(-1.16, _boatSheer(-1.16));
    for (var i = 1; i <= 24; i++) {
      final x = -1.16 + i * .1;
      p.lineTo(x, _boatSheer(x));
    }
    return p
      ..lineTo(1.3, _boatSheer(1.3))
      ..cubicTo(1.26, -.12, 1.14, .05, 1.02, .18)
      ..lineTo(-1.1, .18)
      ..close();
  }();

  /// The white bulwark, brighter toward the bow where the moon reaches it.
  static final Path _boatBand = _boatStrip(-1.16, 1.285, 0, .07);
  static final Path _boatBandLit = _boatStrip(.6, 1.285, 0, .07);

  /// A row of lit portholes in the dark topsides.
  static final Path _boatPorts = () {
    final p = Path();
    for (var i = 0; i < 11; i++) {
      final x = -.95 + i * .19;
      p.addOval(Rect.fromCircle(center: Offset(x, _boatSheer(x) + .112), radius: .022));
    }
    return p;
  }();

  /// Rails round the open bow deck and the stern deck, with posts.
  static final Path _boatRail = () {
    final p = Path();
    void run(double x0, double x1) {
      final n = math.max(1, ((x1 - x0) / .09).round());
      for (final lift in const [.125, .065]) {
        p.moveTo(x0, _boatSheer(x0) - lift);
        for (var i = 1; i <= n; i++) {
          final x = x0 + (x1 - x0) * i / n;
          p.lineTo(x, _boatSheer(x) - lift);
        }
      }
      for (var i = 0; i <= n; i++) {
        final x = x0 + (x1 - x0) * i / n;
        p
          ..moveTo(x, _boatSheer(x))
          ..lineTo(x, _boatSheer(x) - .125);
      }
    }

    run(.66, 1.27);
    run(-1.14, -.96);
    return p;
  }();
  static final Path _boatStaff = Path()
    ..moveTo(-1.1, -.2)
    ..lineTo(-1.1, -.68);
  static final Path _boatBowPole = Path()
    ..moveTo(1.24, -.278)
    ..lineTo(1.24, -.36);

  /// The saloon's dark frame under its glass: aft wall, rounded corner, roof
  /// crown and the raked front.
  static final Path _boatSaloon = Path()
    ..moveTo(-.94, -.2)
    ..lineTo(-.94, -.5)
    ..quadraticBezierTo(-.94, -.59, -.85, -.6)
    ..cubicTo(-.45, -.64, .1, -.64, .458, -.605)
    ..lineTo(.62, -.2)
    ..close();

  /// Eight panes between mullions; the last follows the raked front.
  static Path _boatPanePath(double y0, double y1, [Set<int>? only]) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      if (only != null && !only.contains(i)) continue;
      final x0 = -.9 + i * .175;
      final last = i == 7;
      final xr0 = last ? _boatFront(y0) - .012 : x0 + .153;
      final xr1 = last ? _boatFront(y1) - .012 : x0 + .153;
      p
        ..moveTo(x0, y0)
        ..lineTo(xr0, y0)
        ..lineTo(xr1, y1)
        ..lineTo(x0, y1)
        ..close();
    }
    return p;
  }

  static final Path _boatPanes = _boatPanePath(-.44, -.235);
  static final Path _boatPanesHi = _boatPanePath(-.44, -.36);
  static final Path _boatPanesBright = _boatPanePath(-.44, -.235, const {1, 4, 7});
  static final Path _boatPanesDim = _boatPanePath(-.44, -.235, const {3, 6});

  /// Ceiling lamps along the header of the windows.
  static final Path _boatBulbs = () {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final x = i == 7 ? .42 : -.9 + i * .175 + .0765;
      p.addOval(Rect.fromCircle(center: Offset(x, -.453), radius: .017));
    }
    return p;
  }();

  /// Passengers as (x, head height) in the windows: a few seated, a few
  /// standing, some at the glass with a camera.
  static const _boatCrowd = <(double, double)>[
    (-.86, -.375),
    (-.79, -.365),
    (-.66, -.405),
    (-.52, -.37),
    (-.45, -.36),
    (-.30, -.37),
    (-.15, -.41),
    (-.085, -.365),
    (.02, -.37),
    (.095, -.38),
    (.20, -.40),
    (.37, -.37),
    (.455, -.365),
  ];
  static final Path _boatFolk = () {
    final p = Path();
    for (final (x, y) in _boatCrowd) {
      p
        ..addOval(Rect.fromCircle(center: Offset(x, y), radius: .034))
        ..addRRect(
          RRect.fromLTRBAndCorners(
            x - .058,
            y + .043,
            x + .058,
            -.235,
            topLeft: const Radius.circular(.05),
            topRight: const Radius.circular(.05),
          ),
        );
    }
    return p;
  }();

  /// Raised arms: two tourists photographing the tower.
  static final Path _boatArms = Path()
    ..moveTo(-.105, -.33)
    ..lineTo(-.06, -.405)
    ..moveTo(.25, -.32)
    ..lineTo(.295, -.395)
    ..moveTo(.42, -.3)
    ..lineTo(.5, -.35);

  /// The glass roof over the window header, its frames and moonlit rim.
  static final Path _boatGlass = Path()
    ..moveTo(-.94, -.465)
    ..lineTo(-.94, -.5)
    ..quadraticBezierTo(-.94, -.59, -.85, -.6)
    ..cubicTo(-.45, -.64, .1, -.64, .458, -.605)
    ..lineTo(_boatFront(-.465), -.465)
    ..close();
  static final Path _boatRibs = () {
    final p = Path();
    for (var i = 0; i < 7; i++) {
      final x = -.9 + i * .175 + .164;
      p
        ..moveTo(x, -.465)
        ..lineTo(x, _boatRoof(x) + .004);
    }
    return p;
  }();
  static final Path _boatShine = Path()
    ..moveTo(-.62, -.585)
    ..lineTo(-.51, -.485)
    ..moveTo(-.4, -.6)
    ..lineTo(-.33, -.51)
    ..moveTo(.05, -.6)
    ..lineTo(.13, -.51);
  static final Path _boatRoofRim = Path()
    ..moveTo(-.94, -.5)
    ..quadraticBezierTo(-.94, -.59, -.85, -.6)
    ..cubicTo(-.45, -.64, .1, -.64, .458, -.605);
  static final Path _boatRoofRimLit = Path()
    ..moveTo(-.18, -.6306)
    ..quadraticBezierTo(.12, -.632, .458, -.605);

  /// The wheelhouse on the saloon roof, its windows, the pilot and a mullion.
  static final Path _boatHouse = Path()
    ..moveTo(.02, -.6)
    ..lineTo(.02, -.8)
    ..lineTo(_boatFront(-.8), -.8)
    ..lineTo(_boatFront(-.6), -.6)
    ..close();
  static final Path _boatHouseGlass = Path()
    ..moveTo(.06, -.745)
    ..lineTo(_boatFront(-.745) - .012, -.745)
    ..lineTo(_boatFront(-.655) - .012, -.655)
    ..lineTo(.06, -.655)
    ..close();
  static final Path _boatHouseBar = Path()
    ..moveTo(.22, -.745)
    ..lineTo(.22, -.655);
  static final Path _boatCaptain = Path()
    ..addOval(Rect.fromCircle(center: const Offset(.30, -.712), radius: .026))
    ..addRRect(
      RRect.fromLTRBAndCorners(
        .245,
        -.688,
        .355,
        -.655,
        topLeft: const Radius.circular(.04),
        topRight: const Radius.circular(.04),
      ),
    );
  static final Path _boatSlab = Path()
    ..addRect(const Rect.fromLTRB(-.01, -.828, .415, -.797))
    ..addRect(const Rect.fromLTRB(.33, -.855, .39, -.828));
  static final Path _boatSlabRim = Path()
    ..moveTo(-.01, -.828)
    ..lineTo(.415, -.828);
  static final Path _boatMast = Path()
    ..moveTo(.12, -.828)
    ..lineTo(.12, -1.03)
    ..moveTo(.06, -.97)
    ..lineTo(.18, -.97);

  /// The searchlight turret: housing and lens, drawn about its pivot.
  static final Path _boatTurret = Path()
    ..addRRect(RRect.fromLTRBR(-.06, -.04, .13, .04, const Radius.circular(.012)));
  static final Path _boatLens = Path()
    ..addOval(Rect.fromCenter(center: const Offset(.13, 0), width: .04, height: .085));

  /// Where a camera flash may pop, in boat space.
  static const _boatSpots = <(double, double)>[
    (.9, -.37),
    (1.05, -.38),
    (.72, -.365),
    (-1.05, -.34),
    (.2, -.43),
    (-.5, -.43),
  ];

  /// The floodlight as cones about the lamp, apex at the origin, unit long.
  static Path _boatCone(double len, double half) {
    final e = len * math.tan(half);
    return Path()
      ..moveTo(0, 0)
      ..lineTo(len, -e)
      ..quadraticBezierTo(len * 1.07, 0, len, e)
      ..close();
  }

  static final Path _boatBeamWide = _boatCone(5.4, .075);
  static final Path _boatBeamMid = _boatCone(4.5, .045);
  static final Path _boatBeamCore = _boatCone(3.3, .02);
  static final Path _boatBeamHot = _boatCone(1.8, .03);

  /// A bateau-mouche seen from the quay, bound for the right: a white-belted
  /// hull, a long glass saloon lit gold and full of silhouetted passengers,
  /// railed decks fore and aft, the wheelhouse with its swivelling floodlight,
  /// a mast, a tricolour and the odd camera flash. [y] is the water line and
  /// the boat is hulled below it (the water fill hides that), pitched by
  /// [pitch] radians with the swell. [a] fades it at the seam.
  static void _boat(
    Canvas c,
    double x,
    double y,
    double s,
    double a,
    double clock, {
    double pitch = 0,
  }) {
    final cp = math.cos(pitch), sp = math.sin(pitch);
    Offset at(double ux, double uy) =>
        Offset(x + (ux * cp - uy * sp) * s, y + (ux * sp + uy * cp) * s);
    void fill(Path p, Color col, [double k = 1]) =>
        c.drawPath(p, _boatInk..color = Sketch.fade(col, a * k));
    void line(Path p, Color col, double width, [double k = 1]) => c.drawPath(
      p,
      _boatLine
        ..color = Sketch.fade(col, a * k)
        ..strokeWidth = math.max(width, .8 / s),
    );
    void dot(double ux, double uy, double r, Color col, [double k = 1]) => c.drawCircle(
      Offset(ux, uy),
      r,
      _boatInk..color = Sketch.fade(col, a * k),
    );

    // Warm cabin light spills over the far bank behind the boat.
    Sketch.mist(
      c,
      Rect.fromCenter(center: at(-.2, -.42), width: s * 3.8, height: s * 1.5),
      _gold,
      .15 * a,
    );

    // The floodlight rakes across the far bank: cones stack up toward the
    // lamp, and a pool of light lands where the beam meets the façades.
    final swing = -.32 + .22 * math.sin(clock * .35);
    final dir = Offset(math.cos(swing), math.sin(swing));
    final lens = at(.36, -.868) + dir * (s * .135);
    c.save();
    c.translate(lens.dx, lens.dy);
    c.rotate(swing);
    c.scale(s, s);
    fill(_boatBeamWide, _boatBeamC, .05);
    fill(_boatBeamMid, _boatBeamC, .055);
    fill(_boatBeamCore, _boatBeamC, .07);
    fill(_boatBeamHot, _boatBeamC, .06);
    c.restore();
    Sketch.mist(
      c,
      Rect.fromCenter(center: lens + dir * (s * 4.1), width: s * 1.8, height: s * 1.0),
      _boatBeamC,
      .1 * a,
    );

    c.save();
    c.translate(x, y);
    c.rotate(pitch);
    c.scale(s, s);

    // Hull: dark topsides with lit portholes under a white bulwark.
    fill(_boatHull, _boatHullC);
    fill(_boatBand, _boatBandC, .82);
    fill(_boatBandLit, _boatBandLitC, .88);
    fill(_boatPorts, _gold, .8);

    // A tricolour streams aft from the stern staff.
    line(_boatStaff, _boatRailC, .014, .9);
    double wave(double u) => math.sin(clock * 5 + u * 16) * .022 * (u / .225);
    for (var i = 0; i < 3; i++) {
      final ua = i * .075, ub = ua + .075;
      final ya = -.66 + wave(ua), yb = -.66 + wave(ub);
      _boatTmp
        ..reset()
        ..moveTo(-1.1 - ua, ya)
        ..lineTo(-1.1 - ub, yb)
        ..lineTo(-1.1 - ub, yb + .11)
        ..lineTo(-1.1 - ua, ya + .11)
        ..close();
      fill(
        _boatTmp,
        i == 0 ? const Color(0xff3e5bd0) : (i == 1 ? const Color(0xfff2f2fa) : const Color(0xffe2404c)),
        .95,
      );
    }
    line(_boatRail, _boatRailC, .02, .8);
    line(_boatBowPole, _boatRailC, .012, .8);
    dot(1.24, -.368, .022, _boatBeamC, .95);

    // The saloon: gold panes between mullions, ceiling lamps, passengers.
    fill(_boatSaloon, _boatFrameC);
    fill(_boatPanes, _boatPaneC, .96);
    fill(_boatPanesBright, _boatPaneHiC, .32);
    fill(_boatPanesHi, _boatPaneHiC, .45);
    fill(_boatPanesDim, _boatFrameC, .32);
    fill(_boatBulbs, _boatPaneHiC, .95);
    fill(_boatFolk, _boatFolkC, .93);
    line(_boatArms, _boatFolkC, .03, .93);

    // The glass roof glows from within and catches the moon on its rim.
    fill(_boatGlass, _boatGlassC, .5);
    fill(_boatGlass, _gold, .15);
    line(_boatRibs, _boatFrameC, .014, .55);
    line(_boatShine, _boatMoonC, .018, .26);
    line(_boatRoofRim, _boatMoonC, .02, .5);
    line(_boatRoofRimLit, _boatMoonC, .024, .5);

    // The wheelhouse, its pilot, the roof, the mast and the swivelling lamp.
    fill(_boatHouse, _boatFrameC);
    fill(_boatHouseGlass, const Color(0xfffbe6a8), .92);
    fill(_boatCaptain, _boatFolkC, .93);
    line(_boatHouseBar, _boatFrameC, .016, .9);
    fill(_boatSlab, const Color(0xff3c3c62));
    line(_boatSlabRim, _boatMoonC, .016, .6);
    line(_boatMast, const Color(0xff8f93b8), .016, .85);
    c.save();
    c.translate(.36, -.868);
    c.rotate(swing - pitch);
    fill(_boatTurret, const Color(0xff1a1a32));
    fill(_boatLens, _boatBeamC, .95);
    c.restore();

    // Navigation lights: white at the masthead, green on the starboard side.
    dot(.12, -1.04, .075, _boatBeamC, .18);
    dot(.12, -1.04, .026, _boatBeamC, .95);
    dot(.452, -.612, .05, const Color(0xff62ffa8), .3);
    dot(.452, -.612, .02, const Color(0xff9cffc4), .95);

    // Somebody photographs the tower: a flash pops now and then.
    if (clock > 0) {
      for (var k = 0; k < 2; k++) {
        final tick = clock * (.5 + .11 * k) + k * 3.7;
        final n = tick.floor();
        final phase = tick - n;
        if (phase < .14 && Sketch.hash(n * 7 + k * 331 + 3300) > .5) {
          final fl = 1 - phase / .14;
          final spot = _boatSpots[(Sketch.hash(n * 5 + k * 97 + 3400) * _boatSpots.length).floor()];
          final fx = spot.$1, fy = spot.$2;
          dot(fx, fy, .05 + .05 * fl, _boatMoonC, .35 * fl);
          dot(fx, fy, .02, const Color(0xffffffff), fl);
          final arm = .07 + .09 * fl;
          final ray = _boatLine
            ..color = Sketch.fade(const Color(0xffffffff), a * fl)
            ..strokeWidth = math.max(.016, .8 / s);
          c.drawLine(Offset(fx - arm, fy), Offset(fx + arm, fy), ray);
          c.drawLine(Offset(fx, fy - arm * .6), Offset(fx, fy + arm * .6), ray);
        }
      }
    }
    c.restore();

    // The lens blooms in the dark.
    Sketch.mist(c, Rect.fromCenter(center: lens, width: s * .6, height: s * .6), _boatBeamC, .6 * a);
  }

  /// Foam, wash and lit reflections of the boat, painted on the water after
  /// the fill. [alpha] folds in the seam fade and the crossing.
  void _boatWake(Canvas c, SceneFrame f, double bx, double alpha) {
    final h = f.h, s = h * .06, clock = f.clock;
    double edge(double wx) => ridge(Depth.low, wx / h, clock) * h;
    final wl = edge(bx);
    const foam = Color(0xffe4eaff);
    final stern = bx - 1.16 * s, bow = bx + 1.16 * s;

    // The hull darkens the water under it, and the window strip is mirrored
    // in it: broken warm dashes that drift and fade with depth.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(bx - .05 * s, wl + .55 * s), width: s * 3.4, height: s * 1.1),
      _seineDeep,
      .4 * alpha,
    );
    for (var r = 0; r < 5; r++) {
      final row = _seineRows[r]..reset();
      final y = wl + s * (.27 + .1 * r);
      for (var j = 0; j < 4; j++) {
        final wob = math.sin(clock * 2 + r * 1.3 + j * 2.1) * s * (.03 + .025 * r);
        final mid = bx + s * (-.72 + .4 * j) + wob;
        final half = s * (.17 - .012 * r) * (.75 + .25 * math.sin(clock * 1.7 + j * 1.3 + r));
        row
          ..moveTo(mid - half, y)
          ..lineTo(mid + half, y);
      }
      c.drawPath(
        row,
        _seineStroke
          ..color = Sketch.fade(_gold, (.42 - .07 * r) * alpha)
          ..strokeWidth = s * (.06 - .004 * r),
      );
    }
    // The pale bulwark, and the floodlight lens and masthead glimmering deep.
    _seineLight.reset();
    for (var j = 0; j < 4; j++) {
      final mid = bx + s * (-.85 + .55 * j) + math.sin(clock * 1.8 + j * 2.3) * s * .04;
      _seineLight
        ..moveTo(mid - s * .21, wl + s * .1)
        ..lineTo(mid + s * .21, wl + s * .1);
    }
    c.drawPath(
      _seineLight,
      _seineStroke
        ..color = Sketch.fade(const Color(0xffcfd0ee), .2 * alpha)
        ..strokeWidth = s * .05,
    );
    for (var k = 0; k < 3; k++) {
      final wob = math.sin(clock * 1.9 + k * 2.4) * s * (.03 + .03 * k);
      final y = wl + s * (.95 + .2 * k);
      final half = s * (.07 + .025 * k);
      c.drawLine(
        Offset(bx + s * .36 - half + wob, y),
        Offset(bx + s * .36 + half + wob, y),
        _seineStroke
          ..color = Sketch.fade(_boatBeamC, (.34 - .09 * k) * alpha)
          ..strokeWidth = s * .05,
      );
    }

    // A ribbon of foam laps the hull at the water line.
    _seineLight.reset();
    for (var k = 0; k < 6; k++) {
      final x = bx + s * (-1.0 + .4 * k);
      final y = edge(x) + s * .03;
      final half = s * (.13 + .04 * math.sin(clock * 2.6 + k * 1.7));
      _seineLight
        ..moveTo(x - half, y)
        ..lineTo(x + half, y);
    }
    c.drawPath(
      _seineLight,
      _seineStroke
        ..color = Sketch.fade(foam, .3 * alpha)
        ..strokeWidth = s * .05,
    );

    // The bow wave: a heap of foam at the stem, a curl of spray up its rake,
    // and pressure ripples running ahead.
    final by = edge(bow);
    final heap = .5 + .5 * math.sin(clock * 3.1);
    c.drawOval(
      Rect.fromCenter(center: Offset(bow + .04 * s, by + .015 * s), width: s * .66, height: s * .15),
      _seineSolid..color = Sketch.fade(foam, (.4 + .1 * heap) * alpha),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(bow + .1 * s, by), width: s * .34, height: s * .09),
      _seineSolid..color = Sketch.fade(const Color(0xfff6f8ff), .55 * alpha),
    );
    c.drawPath(
      _seineLight
        ..reset()
        ..moveTo(bow + .02 * s, by + .01 * s)
        ..quadraticBezierTo(bow + .26 * s, by - .01 * s, bow + .13 * s, by - .15 * s),
      _seineStroke
        ..color = Sketch.fade(foam, .5 * alpha)
        ..strokeWidth = s * .055,
    );
    for (var k = 0; k < 3; k++) {
      final tw = .5 + .5 * math.sin(clock * 4.2 + k * 2.1);
      final px = bow + s * (.16 + .13 * k) + math.sin(clock * 1.7 + k) * s * .02;
      final py = by - s * (.08 + .07 * ((k + 1) % 3));
      c.drawCircle(
        Offset(px, py),
        s * (.018 + .01 * tw),
        _seineSolid..color = Sketch.fade(foam, (.35 + .4 * tw) * alpha),
      );
    }
    for (var k = 0; k < 3; k++) {
      final x = bow + s * (.4 + .34 * k) + math.sin(clock * 1.2 + k * 2) * s * .04;
      final y = edge(x) + s * (.06 + .075 * k);
      final half = s * (.2 - .04 * k);
      final tw = .65 + .35 * math.sin(clock * 2.2 + k * 1.9);
      c.drawLine(
        Offset(x - half, y),
        Offset(x + half, y),
        _seineStroke
          ..color = Sketch.fade(foam, (.32 - .08 * k) * tw * alpha)
          ..strokeWidth = s * (.05 - .01 * k),
      );
    }

    // The wash: a foam trail off the stern, one arm of the wake fanning
    // toward the viewer, and ripple crests left in the water as the boat
    // moves on, each staying where it was born.
    var px = stern, py = edge(stern) + s * .04;
    for (var k = 0; k < 9; k++) {
      final nx = stern - (k + 1) * .42 * s;
      final ny = edge(nx) + s * (.04 + .012 * (k + 1));
      final life = math.pow(1 - k / 9, 1.5).toDouble();
      final tw = .75 + .25 * math.sin(clock * 3 + k * 1.4);
      c.drawLine(
        Offset(px, py),
        Offset(nx, ny),
        _seineFoam
          ..color = Sketch.fade(foam, .38 * life * tw * alpha)
          ..strokeWidth = s * (.08 - .0055 * k),
      );
      px = nx;
      py = ny;
    }
    px = stern + .05 * s;
    py = wl + s * .06;
    for (var k = 0; k < 7; k++) {
      final nx = px - .66 * s;
      final ny = edge(nx) + s * (.06 + .0495 * (k + 1));
      final life = math.pow(1 - k / 7, 1.3).toDouble();
      c.drawLine(
        Offset(px, py),
        Offset(nx, ny),
        _seineFoam
          ..color = Sketch.fade(foam, .22 * life * alpha)
          ..strokeWidth = s * .04,
      );
      px = nx;
      py = ny;
    }
    final gap = .5 * s;
    for (var j = ((stern - 3.8 * s) / gap).ceil(); j * gap <= stern; j++) {
      final wx = j * gap;
      final age = (stern - wx) / s;
      final ramp = math.min(1.0, age / .35);
      final life = math.pow(math.max(0.0, 1 - age / 3.8), 1.6).toDouble();
      final tw = .55 + .45 * math.sin(clock * 2.4 + j * 1.9);
      final half = s * (.13 + .05 * age);
      final y = edge(wx) + s * (.09 + .1 * age);
      c.drawLine(
        Offset(wx - half, y),
        Offset(wx + half, y),
        _seineStroke
          ..color = Sketch.fade(foam, .3 * ramp * life * tw * alpha)
          ..strokeWidth = s * .04,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // The Seine: sky sheen, ripples and the lights that lie on the water. Every
  // helper here carries the `_seine` prefix and shares the paints below.

  static const _seineDeep = Color(0xff0b1032);
  static const _seineGlow = Color(0xffc48ba6);

  static final _seineStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _seineFoam = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt;
  static final _seineSolid = Paint();
  static final _seineFill = Paint();
  static final _seinePath = Path();
  static final _seineLight = Path();
  static final _seineDark = Path();
  static final _seineRows = [Path(), Path(), Path(), Path(), Path()];

  /// Gradients depend only on the viewport and on the crossing's presence, so
  /// they are rebuilt only when one of those changes.
  static Shader? _seineSheenShader, _seineShadeShader;
  static double _seineSheenH = 0, _seineSheenP = -1;
  static double _seineShadeH = 0, _seineShadeP = -1;

  static double _seineStep(double presence) =>
      (math.min(1.0, math.max(0.0, presence)) * 12).round() / 12;

  /// The water's own light: the far bank's dark reflection hugging the ridge,
  /// then the rose of the horizon glow, fading to the near bank's shadow.
  void _seineSheen(Canvas c, SceneFrame f, double scroll, double presence) {
    final w = f.w, h = f.h;
    final p = _seineStep(presence * presence);
    if (p <= 0) return;
    if (_seineSheenShader == null || _seineSheenH != h || _seineSheenP != p) {
      _seineSheenH = h;
      _seineSheenP = p;
      _seineSheenShader = Gradient.linear(
        Offset(0, h * .816),
        Offset(0, h * .94),
        [
          Sketch.fade(_seineDeep, .24 * p),
          Sketch.fade(_seineDeep, .1 * p),
          Sketch.fade(_seineGlow, .22 * p),
          Sketch.fade(_seineGlow, .08 * p),
          Sketch.fade(_seineGlow, 0),
          Sketch.fade(_seineDeep, .28 * p),
        ],
        const [0, .13, .25, .52, .72, 1],
      );
    }
    // The fill hugs the band's own ridge line, sampled as the backdrop does.
    final step = math.max(4.0, w / 140);
    final path = _seinePath..reset();
    for (var x = 0.0; ; x += step) {
      final sx = math.min(x, w);
      final y = math.min(ridge(Depth.low, (sx + scroll) / h, f.clock), 1.05) * h;
      if (x == 0) {
        path.moveTo(sx, y);
      } else {
        path.lineTo(sx, y);
      }
      if (sx >= w) break;
    }
    path
      ..lineTo(w, h * .94)
      ..lineTo(0, h * .94)
      ..close();
    c.drawPath(path, _seineFill..shader = _seineSheenShader);
  }

  /// The bridge's dark reflection, lying under its whole span.
  static void _seineBridgeShadow(
    Canvas c,
    double cx,
    double water,
    double h,
    double presence,
  ) {
    final p = _seineStep(presence);
    if (p <= 0) return;
    if (_seineShadeShader == null || _seineShadeH != h || _seineShadeP != p) {
      _seineShadeH = h;
      _seineShadeP = p;
      _seineShadeShader = Gradient.linear(
        Offset(0, h * .82),
        Offset(0, h * .89),
        [
          Sketch.fade(_seineDeep, .4 * p),
          Sketch.fade(_seineDeep, .14 * p),
          Sketch.fade(_seineDeep, 0),
        ],
        const [0, .5, 1],
      );
    }
    final half = _bridgeHalf(h) + h * .13;
    final top = water + h * .003, bottom = water + h * .07;
    c.drawPath(
      _seinePath
        ..reset()
        ..moveTo(cx - half, top)
        ..lineTo(cx + half, top)
        ..lineTo(cx + half * .93, bottom)
        ..lineTo(cx - half * .93, bottom)
        ..close(),
      _seineFill..shader = _seineShadeShader,
    );
  }

  /// One lamp's reflection from [top] down: dashes that sway more, run wider
  /// and fade as they sink.
  static void _seineColumn(
    Canvas c,
    double x,
    double top,
    double h,
    double clock,
    double phase,
    Color color,
    double alpha, {
    double depth = .084,
  }) {
    const rows = 5;
    for (var k = 0; k < rows; k++) {
      final t = k / (rows - 1);
      final y = top + h * depth * t;
      final wob = math.sin(clock * 1.5 + phase + k * 2.2) * h * (.003 + .007 * t);
      final half =
          h * .014 * (1 + .9 * t) * (.75 + .25 * math.sin(clock * 2.3 + phase * 1.7 + k * 1.3));
      c.drawLine(
        Offset(x - half + wob, y),
        Offset(x + half + wob, y),
        _seineStroke
          ..color = Sketch.fade(color, alpha * (1 - .78 * t))
          ..strokeWidth = h * (.0034 - .0012 * t),
      );
    }
  }

  /// Long ripple streaks in rows that grow and spread toward the viewer, each
  /// row catching a little more light than the one behind, and dark troughs
  /// between. Rows scroll with the water, nearer rows a touch faster.
  static void _seineRipples(
    Canvas c,
    double w,
    double h,
    double clock,
    double scroll,
    double presence,
  ) {
    const rows = 8;
    final span = w + h * .3;
    for (var r = 0; r < rows; r++) {
      final t = r / (rows - 1);
      final y0 = h * (.834 + .09 * math.pow(t, 1.3).toDouble());
      final gap = h * (.12 - .06 * t);
      final n = (span / gap).ceil();
      final drift = scroll * (1 + .7 * t) + clock * h * .005 * (1 + t);
      final len = h * (.016 + .045 * t);
      _seineLight.reset();
      _seineDark.reset();
      for (var i = 0; i < n; i++) {
        final seed = r * 64 + i;
        if (Sketch.hash(seed + 1100) < .25) continue;
        final x = ((i + .15 + .7 * Sketch.hash(seed + 800)) * gap - drift) % span - h * .15;
        final y = y0 + math.sin(i * 1.9 + r + clock * .8) * h * .0016;
        final half = len * (.55 + .9 * Sketch.hash(seed + 900));
        final streak = Sketch.hash(seed + 1000) > .38 ? _seineLight : _seineDark;
        streak
          ..moveTo(x - half, y)
          ..lineTo(x + half, y);
      }
      final breathe = .65 + .35 * math.sin(clock * .7 + r * 1.9);
      final alpha = (.09 + .09 * t) * breathe * presence;
      final width = h * (.0011 + .0017 * t);
      c.drawPath(
        _seineLight,
        _seineStroke
          ..color = Sketch.fade(const Color(0xffb4c2f0), alpha)
          ..strokeWidth = width,
      );
      c.drawPath(
        _seineDark,
        _seineStroke
          ..color = Sketch.fade(_seineDeep, alpha * 1.8)
          ..strokeWidth = width * 1.3,
      );
    }
  }

  /// Reflections of the far bank, which drifts on its own timed [scroll]: a
  /// string of pearls under the quay's lamp chain, and flecks of lit windows.
  static void _seineFarBank(
    Canvas c,
    double w,
    double h,
    double clock,
    double scroll,
    double presence,
  ) {
    // The lamps stand where _quay puts them: every h*.055 from -h*.25.
    final gap = h * .055;
    for (var k = 0; k < 4; k++) {
      _seineRows[k].reset();
    }
    final first = math.max(0, ((scroll - h * .05 + h * .25) / gap).floor());
    for (var i = first; ; i++) {
      final wx = -h * .25 + i * gap;
      final sx = wx - scroll;
      if (sx > w + h * .05 || wx >= w + h * .55) break;
      if (Sketch.hash(i + 400) < .12) continue;
      for (var k = 0; k < 4; k++) {
        final wob = math.sin(clock * 1.6 + i * 1.3 + k * 2.1) * h * (.0012 + .0016 * k);
        final half = h * (.0045 + .0018 * k);
        final y = h * (.828 + .0165 * k);
        _seineRows[k]
          ..moveTo(sx - half + wob, y)
          ..lineTo(sx + half + wob, y);
      }
    }
    for (var k = 0; k < 4; k++) {
      c.drawPath(
        _seineRows[k],
        _seineStroke
          ..color = Sketch.fade(_gold, (.36 - .08 * k) * presence)
          ..strokeWidth = h * (.0026 + .0004 * k),
      );
    }
  }

  /// Loose glints of the far bank's windows, wrapping with its drift.
  static void _seineLights(
    Canvas c,
    double w,
    double h,
    double scroll,
    double presence,
  ) {
    _seineLight.reset();
    final span = w + h * .6;
    for (var m = 0; m < 12; m++) {
      final x = (Sketch.hash(m + 520) * span - scroll) % span - h * .3;
      final y = h * (.83 + .05 * Sketch.hash(m + 530));
      final half = h * (.003 + .004 * Sketch.hash(m + 540));
      _seineLight
        ..moveTo(x - half, y)
        ..lineTo(x + half, y);
    }
    c.drawPath(
      _seineLight,
      _seineStroke
        ..color = Sketch.fade(_gold, .17 * presence)
        ..strokeWidth = h * .0022,
    );
  }

  /// The floodlit tower in the water: its splayed legs mirrored as they
  /// narrow away from the bank, the first platform a bright bar across them,
  /// and the hourly glitter twinkling in the column.
  static void _seineTower(
    Canvas c,
    double w,
    double h,
    double clock,
    double scroll,
    double presence,
  ) {
    final tx = _tower(w, h).dx - scroll;
    if (tx < -h * .3 || tx > w + h * .3) return;
    final s = h * .52;
    double half(double d) => s * .17 * math.pow(1 - d / s, 2.4).toDouble() + s * .012;
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(tx, h * .87), width: s * .5, height: h * .12),
      _gold,
      .11 * presence,
    );
    for (var i = 0; i < 11; i++) {
      final d = h * (.012 + .0082 * i);
      final t = d / s;
      final hw = half(d);
      final leg = s * (.034 - .012 * t / .16);
      final y = h * .826 + d;
      final wob = math.sin(clock * 1.5 + i * 1.3) * h * (.0015 + .0016 * i);
      final tw = .75 + .25 * math.sin(clock * 2.1 + i * .9);
      final alpha = .3 * (1 - i * .05) * tw * presence;
      final len = leg * .62;
      final off = hw - leg * .5;
      final stroke = _seineStroke
        ..color = Sketch.fade(_gold, alpha)
        ..strokeWidth = h * (.0034 - .00012 * i);
      c.drawLine(Offset(tx - off + wob - len, y), Offset(tx - off + wob + len, y), stroke);
      c.drawLine(Offset(tx + off - wob - len, y), Offset(tx + off - wob + len, y), stroke);
      if (i == 9) {
        c.drawLine(
          Offset(tx - hw - s * .02 + wob, y),
          Offset(tx + hw + s * .02 + wob, y),
          _seineStroke
            ..color = Sketch.fade(_gold, .34 * tw * presence)
            ..strokeWidth = h * .0026,
        );
      }
    }
    for (var i = 0; i < 6; i++) {
      final flash = math.pow(math.max(0.0, math.sin(clock * 6 + i * 2.7)), 6).toDouble();
      if (flash < .06) continue;
      final d = h * (.014 + .075 * Sketch.hash(i + 95));
      final x = tx + (Sketch.hash(i + 91) * 2 - 1) * half(d) * .85;
      final y = h * .826 + d;
      final r = h * (.005 + .006 * flash);
      final glint = _seineStroke
        ..color = Sketch.fade(const Color(0xfffff6d0), .8 * flash * presence)
        ..strokeWidth = h * .0018;
      c.drawLine(Offset(x - r, y), Offset(x + r, y), glint);
      c.drawLine(Offset(x, y - r * .5), Offset(x, y + r * .5), glint);
    }
  }

  /// The moon's glitter road: broken dashes that widen toward the viewer and
  /// sway under the moon, with flankers and a soft pool at its head.
  static void _seineMoon(Canvas c, double moonX, double h, double clock, double presence) {
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(moonX, h * .875), width: h * .3, height: h * .16),
      const Color(0xffd9e0ff),
      .13 * presence,
    );
    for (var i = 0; i < 10; i++) {
      final t = (i + .5) / 10;
      final y = h * (.83 + .096 * t);
      final on = .5 + .5 * math.sin(clock * 1.4 + i * 1.9);
      final x = moonX + math.sin(clock * .9 + i * 2.1) * h * (.006 + .026 * t);
      final len = h * (.012 + .052 * t) * (.55 + .45 * on);
      c.drawLine(
        Offset(x - len, y),
        Offset(x + len, y),
        _seineStroke
          ..color = Sketch.fade(_moonlit, .55 * on * presence)
          ..strokeWidth = h * (.0022 + .003 * t),
      );
      for (final side in const [-1.0, 1.0]) {
        final on2 = .5 + .5 * math.sin(clock * 1.9 + i * 1.3 + side * 2.1);
        final off = h * (.018 + .055 * t) * (.75 + .5 * Sketch.hash(i * 2 + (side > 0 ? 1 : 0) + 640));
        final l2 = len * .5 * (.5 + .5 * on2);
        c.drawLine(
          Offset(x + side * off - l2, y + h * .002),
          Offset(x + side * off + l2, y + h * .002),
          _seineStroke
            ..color = Sketch.fade(const Color(0xffcad6ff), .34 * on2 * presence)
            ..strokeWidth = h * (.0016 + .002 * t),
        );
      }
    }
  }

  /// Sparkles on wave crests: tiny crossed glints that flare and vanish.
  static void _seineGlints(
    Canvas c,
    double w,
    double h,
    double clock,
    double scroll,
    double presence,
  ) {
    final span = w + h * .2;
    for (var i = 0; i < 14; i++) {
      final on = math
          .pow(.5 + .5 * math.sin(clock * (1.1 + .9 * Sketch.hash(i + 610)) + i * 2.3), 3)
          .toDouble();
      if (on < .08) continue;
      final t = Sketch.hash(i + 620);
      final y = h * (.835 + .09 * t);
      final x = (Sketch.hash(i + 630) * span - scroll * (1 + .7 * t)) % span - h * .1;
      final r = h * (.005 + .007 * t) * (.5 + .5 * on);
      final glint = _seineStroke
        ..color = Sketch.fade(i.isEven ? const Color(0xfffff0c8) : const Color(0xffdfe8ff), .75 * on * presence)
        ..strokeWidth = h * .0016;
      c.drawLine(Offset(x - r, y), Offset(x + r, y), glint);
      c.drawLine(Offset(x, y - r * .5), Offset(x, y + r * .5), glint);
    }
  }

  // Promenade street furniture: lamps, plane trees, benches, the paving and
  // its fallen leaves. Everything below carries the `_sf` prefix.
  static const _sfIron = Color(0xff14131f);
  static const _sfRim = Color(0xff4d5482);
  static const _sfWhite = Color(0xfffff2c8);

  /// Height of the lantern's centre over the lamp's foot, in lamp units.
  static const _sfLanternAt = 1.085;

  /// Turned-iron profiles of the lamp as (height, half width) in lamp units.
  static const _sfVase = [
    (.1, .05), (.118, .046), (.14, .036), (.165, .03), (.195, .03),
    (.2, .044), (.215, .049), (.23, .044), (.24, .031), (.27, .0295), (.3, .029),
  ];
  static const _sfShaft = [(.3, .029), (.9, .0195)];
  static const _sfCapital = [
    (.9, .0195), (.912, .0225), (.93, .026), (.945, .034),
    (.96, .044), (.975, .055), (.988, .059),
  ];
  static const _sfHat = [
    (1.185, .08), (1.2, .074), (1.222, .058), (1.244, .036), (1.262, .018), (1.272, .008),
  ];

  static double _sfUnit(double v) => math.max(0.0, math.min(1.0, v));

  /// A shape symmetric about [base]'s vertical, from (height, half width)
  /// pairs in [s] units, bottom to top. With [inner] between 0 and 1 only the
  /// right-hand strip outside that fraction of the width is filled: the
  /// moonlit side of turned iron.
  static Path _sfProfile(
    Offset base,
    double s,
    List<(double, double)> pts, {
    double inner = -1.0,
  }) {
    final path = Path()..moveTo(base.dx + pts.first.$2 * s, base.dy - pts.first.$1 * s);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(base.dx + pts[i].$2 * s, base.dy - pts[i].$1 * s);
    }
    for (var i = pts.length - 1; i >= 0; i--) {
      path.lineTo(base.dx + pts[i].$2 * s * inner, base.dy - pts[i].$1 * s);
    }
    return path..close();
  }

  /// A radial glow in the unit circle: scaled onto a rect it costs no
  /// gradient allocation, and a flicker only has to resize it.
  static Paint _sfGlowPaint(Color color, double peak) => Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      [
        Sketch.fade(color, peak),
        Sketch.fade(color, peak * .55),
        Sketch.fade(color, peak * .2),
        Sketch.fade(color, 0),
      ],
      const [0, .28, .6, 1],
    );
  static final _sfHalo = _sfGlowPaint(_gold, .36);
  static final _sfCore = _sfGlowPaint(_sfWhite, .75);
  static final _sfPool = _sfGlowPaint(_gold, .3);

  /// Draws one of the cached glows as an ellipse of radii [rx] and [ry].
  /// While a crossing fades the band it falls back to [Sketch.mist], which
  /// can carry the fade in its own gradient.
  static void _sfGlow(
    Canvas c,
    Paint paint,
    Color color,
    double peak,
    Offset at,
    double rx,
    double ry,
    double presence,
  ) {
    if (presence >= .999) {
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(rx, ry);
      c.drawCircle(Offset.zero, 1, paint);
      c.restore();
    } else {
      Sketch.mist(
        c,
        Rect.fromCenter(center: at, width: rx * 2, height: ry * 2),
        color,
        peak * presence,
      );
    }
  }

  /// A Paris cast-iron gas lamp, about 1.3 [s] tall: a stepped plinth under
  /// a vase-shaped base, a fluted tapering shaft with collars, a flared
  /// capital carrying two scrolled brackets, and a hexagonal glass lantern
  /// under an ogee hat with a ball finial. Moonlight rims the right of the
  /// iron while the top of the post warms toward the flame. [overlay] adds
  /// the flickering bloom and the pool of light on the paving.
  static void _lamp(Canvas c, Offset base, double s) {
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy - v * s;
    final iron = Paint()..color = _sfIron;
    final rim = Paint()..color = const Color(0x8c4d5482);
    final stroke = Paint()..style = PaintingStyle.stroke;

    // A faint cone of gas-lit haze from the lantern down to the paving.
    c.drawPath(
      Sketch.poly([x(-.05), y(1.09), x(.05), y(1.09), x(.3), y(0), x(-.3), y(0)]),
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx, y(1.09)),
          Offset(base.dx, y(0)),
          const [Color(0x16ffcf6a), Color(0x00ffcf6a)],
        ),
    );
    // Plinth in two steps, then the vase-shaped base.
    c.drawRect(Rect.fromLTRB(x(-.078), y(.05), x(.078), y(0)), iron);
    c.drawRect(Rect.fromLTRB(x(-.06), y(.1), x(.06), y(.05)), iron);
    c.drawRect(Rect.fromLTRB(x(.05), y(.098), x(.06), y(.052)), rim);
    c.drawPath(_sfProfile(base, s, _sfVase), iron);
    c.drawPath(_sfProfile(base, s, _sfVase, inner: .5), rim);
    // The shaft warms toward the lantern; a moonlit half, grooves and a
    // bright edge make the fluting.
    c.drawPath(
      _sfProfile(base, s, _sfShaft),
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx, y(.3)),
          Offset(base.dx, y(.92)),
          const [_sfIron, _sfIron, Color(0xff5a4126)],
          const [0, .55, 1],
        ),
    );
    c.drawPath(_sfProfile(base, s, _sfShaft, inner: .42), rim);
    c.drawPath(
      Path()
        ..moveTo(x(0), y(.33))
        ..lineTo(x(0), y(.88))
        ..moveTo(x(.014), y(.33))
        ..lineTo(x(.0095), y(.88)),
      stroke
        ..color = const Color(0xb3050509)
        ..strokeWidth = math.max(.7, s * .006),
    );
    c.drawPath(
      Path()
        ..moveTo(x(.0245), y(.33))
        ..lineTo(x(.0165), y(.88)),
      stroke
        ..color = const Color(0x99b4bcf0)
        ..strokeWidth = math.max(.6, s * .005),
    );
    // Collars at the foot, the middle and the head of the shaft.
    void collar(double v, double hw, double th) {
      c.drawRRect(
        RRect.fromLTRBR(x(-hw), y(v + th), x(hw), y(v), Radius.circular(s * th * .4)),
        iron,
      );
      c.drawRect(Rect.fromLTRB(x(hw * .05), y(v + th * .92), x(hw * .96), y(v + th * .55)), rim);
    }

    collar(.29, .037, .026);
    collar(.5, .034, .02);
    collar(.885, .03, .03);
    // Flared capital and the plate that carries the lantern, its edge lit
    // from above by the flame.
    c.drawPath(_sfProfile(base, s, _sfCapital), iron);
    c.drawPath(_sfProfile(base, s, _sfCapital, inner: .35), rim);
    c.drawRRect(
      RRect.fromLTRBR(x(-.066), y(1.004), x(.066), y(.985), Radius.circular(s * .006)),
      iron,
    );
    c.drawLine(
      Offset(x(-.058), y(1.003)),
      Offset(x(.058), y(1.003)),
      Paint()
        ..color = const Color(0xffe0a040)
        ..strokeWidth = math.max(.7, s * .006),
    );
    // Two scrolled brackets each side, bronzed toward the flame.
    final scroll = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, s * .013)
      ..shader = Gradient.linear(
        Offset(0, y(.9)),
        Offset(0, y(1.07)),
        const [_sfIron, Color(0xff86602c)],
      );
    for (final k in const [-1.0, 1.0]) {
      double sx(double u) => x(u * k);
      c.drawPath(
        Path()
          ..moveTo(sx(.03), y(.935))
          ..cubicTo(sx(.13), y(.925), sx(.165), y(1.0), sx(.118), y(1.045))
          ..cubicTo(sx(.092), y(1.07), sx(.06), y(1.048), sx(.074), y(1.026))
          ..cubicTo(sx(.084), y(1.012), sx(.1), y(1.02), sx(.097), y(1.032)),
        scroll,
      );
      c.drawPath(
        Path()
          ..moveTo(sx(.03), y(.955))
          ..cubicTo(sx(.08), y(.955), sx(.105), y(.935), sx(.09), y(.917))
          ..cubicTo(sx(.08), y(.905), sx(.062), y(.915), sx(.068), y(.927)),
        scroll,
      );
      c.drawCircle(Offset(sx(.097), y(1.032)), s * .011, iron);
      c.drawCircle(Offset(sx(.068), y(.927)), s * .009, iron);
    }
    // The lantern: a glass hexagon wider at the top, glowing from its mantle.
    c.drawPath(
      Sketch.poly([x(-.034), y(1.003), x(.034), y(1.003), x(.068), y(1.165), x(-.068), y(1.165)]),
      Paint()
        ..shader = Gradient.radial(
          Offset(base.dx, y(_sfLanternAt)),
          s * .1,
          const [Color(0xfffffbe0), Color(0xffffe08a), Color(0xffffc04c), Color(0xffe9922c)],
          const [0, .3, .7, 1],
        ),
    );
    c.drawCircle(Offset(base.dx, y(1.078)), s * .03, Paint()..color = const Color(0xb3fff6d0));
    c.drawPath(
      Path()
        ..moveTo(base.dx, y(1.125))
        ..cubicTo(x(.03), y(1.09), x(.03), y(1.046), base.dx, y(1.046))
        ..cubicTo(x(-.03), y(1.046), x(-.03), y(1.09), base.dx, y(1.125)),
      Paint()..color = const Color(0xffffffee),
    );
    // Frame: two mullions and the corner posts, the right one moonlit.
    stroke
      ..color = _sfIron
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = math.max(.8, s * .009);
    for (final f in const [-.34, .34]) {
      c.drawLine(Offset(x(f * .034), y(1.003)), Offset(x(f * .068), y(1.165)), stroke);
    }
    stroke.strokeWidth = math.max(.9, s * .011);
    c.drawLine(Offset(x(-.034), y(1.003)), Offset(x(-.068), y(1.165)), stroke);
    c.drawLine(Offset(x(.034), y(1.003)), Offset(x(.068), y(1.165)), stroke..color = _sfRim);
    // Cornice, ogee hat with a lit facet, and the ball finial.
    c.drawRRect(
      RRect.fromLTRBR(x(-.076), y(1.185), x(.076), y(1.163), Radius.circular(s * .006)),
      iron,
    );
    c.drawLine(
      Offset(x(-.066), y(1.166)),
      Offset(x(.066), y(1.166)),
      Paint()
        ..color = const Color(0xcc9a6a2c)
        ..strokeWidth = math.max(.7, s * .008),
    );
    c.drawPath(_sfProfile(base, s, _sfHat), iron);
    c.drawPath(_sfProfile(base, s, _sfHat, inner: .35), rim);
    c.drawRect(Rect.fromLTRB(x(-.004), y(1.285), x(.004), y(1.27)), iron);
    c.drawCircle(Offset(base.dx, y(1.293)), s * .015, iron);
    c.drawCircle(Offset(x(.005), y(1.297)), s * .006, Paint()..color = _sfRim);
  }

  static const _sfBark = Color(0xff2b2837);
  static const _sfBarkLit = Color(0xff4a4b66);
  static const _sfLeafDeep = Color(0xff1e2739);
  static const _sfLeafBase = Color(0xff2c384d);
  static const _sfLeafMid = Color(0xff374659);
  static const _sfLeafLit = Color(0xff475b6d);

  /// Crown lobes as (across, height, radius) in tree units, back to front:
  /// the back three sit behind the trunk and its limbs, the rest in front.
  static const _sfLobesBack = [(0.0, .78, .21), (-.31, .66, .17), (.31, .68, .17)];
  static const _sfLobesFront = [
    (-.2, .8, .17), (.2, .82, .17), (0.0, .9, .15), (-.36, .6, .13),
    (.36, .62, .13), (-.1, .66, .11), (.11, .68, .11),
  ];

  /// Round dots in one call: each point becomes a disc of diameter [dia].
  static void _sfDots(Canvas c, List<Offset> pts, double dia, Color color) {
    if (pts.isEmpty) return;
    c.drawPoints(
      PointMode.points,
      pts,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = dia
        ..color = color,
    );
  }

  /// A tapered, gently curved limb from [a] to [b] with half widths [wa] and
  /// [wb] in pixels. [bend] pushes the middle sideways as a share of its
  /// length, toward the left of the a-to-b direction on screen when positive.
  static void _sfLimb(Canvas c, Paint paint, Offset a, Offset b, double wa, double wb, double bend) {
    final d = b - a;
    final len = d.distance;
    if (len <= 0) return;
    final n = Offset(-d.dy / len, d.dx / len);
    final ctrl = (a + b) / 2 + n * (bend * len);
    final wm = (wa + wb) / 2;
    c.drawPath(
      Path()
        ..moveTo(a.dx + n.dx * wa, a.dy + n.dy * wa)
        ..quadraticBezierTo(ctrl.dx + n.dx * wm, ctrl.dy + n.dy * wm, b.dx + n.dx * wb, b.dy + n.dy * wb)
        ..lineTo(b.dx - n.dx * wb, b.dy - n.dy * wb)
        ..quadraticBezierTo(ctrl.dx - n.dx * wm, ctrl.dy - n.dy * wm, a.dx - n.dx * wa, a.dy - n.dy * wa)
        ..close(),
      paint,
    );
  }

  /// One crown lobe in three shaded discs (deep rim, body, moonlit crown)
  /// with tufts scalloping its edge. Lobes to the right and near the top
  /// take more of the moon.
  static void _sfLobe(
    Canvas c,
    Paint fill,
    Offset base,
    double s,
    (double, double, double) lobe,
    int salt,
  ) {
    final (dx, dv, r) = lobe;
    final k = _sfUnit((dx + .45) / .9 * .55 + _sfUnit((dv - .55) / .4) * .45);
    final ctr = Offset(base.dx + dx * s, base.dy - dv * s);
    final rr = r * s;
    final deep = Sketch.mix(_sfLeafDeep, _sfLeafBase, .45 + .4 * k);
    final mid = Sketch.mix(_sfLeafBase, _sfLeafMid, .3 + .7 * k);
    final lit = Sketch.mix(_sfLeafMid, _sfLeafLit, k);
    c.drawCircle(ctr, rr, fill..color = deep);
    // Tufts face away from the heart of the crown.
    final away = math.atan2(dv - .7, dx);
    for (var t = 0; t < 3; t++) {
      final a = away + (t - 1) * .62 + (Sketch.hash(salt * 7 + t) - .5) * .3;
      final up = math.sin(a) > .15 && math.cos(a) > -.35;
      c.drawCircle(
        ctr + Offset(math.cos(a), -math.sin(a)) * (rr * .86),
        rr * (.22 + .1 * Sketch.hash(salt * 5 + t + 40)),
        fill..color = Sketch.mix(deep, mid, up ? .6 : .15),
      );
    }
    c.drawCircle(ctr + Offset(rr * .04, -rr * .07), rr * .9, fill..color = Sketch.mix(deep, mid, .55));
    c.drawCircle(ctr + Offset(rr * .13, -rr * .2), rr * .7, fill..color = mid);
    if (k > .25) c.drawCircle(ctr + Offset(rr * .28, -rr * .36), rr * .4, fill..color = lit);
  }

  /// A plane tree about [s] tall: root flare, a mottled trunk that forks into
  /// three limbs, and a broad crown of layered lobes lit from the right, with
  /// autumn tints (more of them for higher [seed]s) and the pairs of seed
  /// balls that hang under a plane tree's crown.
  static void _plane(Canvas c, Offset base, double s, {int seed = 0}) {
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy - v * s;
    double rnd(int k) => Sketch.hash(seed * 137 + k);
    final lean = (rnd(1) - .5) * .06;
    final fill = Paint();
    final bark = Paint()..color = _sfBark;

    // Roots flare where the trunk meets the paving.
    _sfLimb(c, bark, Offset(x(-.02), y(.09)), Offset(x(-.12), y(-.02)), s * .03, s * .01, -.18);
    _sfLimb(c, bark, Offset(x(.02), y(.09)), Offset(x(.12), y(-.02)), s * .03, s * .01, .18);
    for (var i = 0; i < _sfLobesBack.length; i++) {
      _sfLobe(c, fill, base, s, _sfLobesBack[i], seed * 20 + i);
    }
    // The trunk forks into two spreading limbs and a leader.
    _sfLimb(c, bark, Offset(x(0), y(-.02)), Offset(x(lean), y(.44)), s * .062, s * .04, .02);
    _sfLimb(c, bark, Offset(x(lean - .006), y(.4)), Offset(x(-.22), y(.7)), s * .036, s * .014, .1);
    _sfLimb(c, bark, Offset(x(lean + .006), y(.4)), Offset(x(.21), y(.72)), s * .036, s * .013, -.1);
    _sfLimb(c, bark, Offset(x(lean), y(.42)), Offset(x(lean * .4 - .03), y(.84)), s * .03, s * .011, .03);
    // Moonlight on the right of the trunk.
    _sfLimb(c, fill..color = _sfBarkLit, Offset(x(.034), y(0)), Offset(x(lean + .022), y(.42)), s * .022, s * .015, .02);
    c.drawLine(
      Offset(x(.054), y(.03)),
      Offset(x(lean + .034), y(.42)),
      Paint()
        ..color = const Color(0x99aab4dc)
        ..strokeWidth = math.max(.8, s * .006),
    );
    // Mottled bark: pale flakes and cream scars where the bark has peeled,
    // dark stains between.
    for (var k = 0; k < 12; k++) {
      final vv = .05 + .36 * rnd(20 + k * 3);
      final hw = .062 - .022 * vv / .44;
      final pw = .007 + .009 * rnd(21 + k * 3);
      final ph = .014 + .02 * rnd(22 + k * 3);
      final uu = lean * vv / .44 + (rnd(23 + k * 3) * 2 - 1) * (hw - pw - .004);
      c.drawOval(
        Rect.fromCenter(center: Offset(x(uu), y(vv)), width: pw * 2 * s, height: ph * 2 * s),
        fill
          ..color = switch (k % 3) {
            0 => const Color(0xb8747490),
            1 => const Color(0x99968c7a),
            _ => const Color(0x99161520),
          },
      );
    }
    for (var i = 0; i < _sfLobesFront.length; i++) {
      _sfLobe(c, fill, base, s, _sfLobesFront[i], seed * 20 + 5 + i);
    }

    // Leaf texture over the lobes: bright clusters in the moon, dark ones in
    // the shade, autumn tints and moonlit rim leaves.
    final all = [..._sfLobesBack, ..._sfLobesFront];
    final litDots = <Offset>[], darkDots = <Offset>[], rimDots = <Offset>[];
    final gold = <Offset>[], olive = <Offset>[], bright = <Offset>[];
    final tint = .35 + .3 * (seed % 3);
    for (var i = 0; i < all.length; i++) {
      final (dx, dv, r) = all[i];
      final ctr = Offset(x(dx), y(dv));
      final rr = r * s;
      for (var j = 0; j < 5; j++) {
        final a = rnd(100 + i * 10 + j) * math.pi * 2;
        final p = ctr + Offset(math.cos(a), math.sin(a)) * (rr * (.2 + .65 * rnd(300 + i * 10 + j)));
        if (math.cos(a) > -.25 && math.sin(a) < .2) {
          litDots.add(p);
        } else if (math.sin(a) > .35) {
          darkDots.add(p);
        }
      }
      if (rnd(400 + i) < tint) {
        final sun = dx > -.15;
        for (var j = 0; j < 3; j++) {
          final p = ctr +
              Offset(
                (rnd(500 + i * 4 + j) * 2 - 1) * rr * .6,
                -rnd(520 + i * 4 + j) * rr * .6,
              );
          (sun ? gold : olive).add(p);
          if (sun && j == 0) bright.add(p + Offset(rr * .05, -rr * .05));
        }
      }
      if (dx > -.15 && dv > .6) {
        for (var j = 0; j < 2; j++) {
          final a = .3 + .8 * rnd(700 + i * 2 + j);
          rimDots.add(ctr + Offset(math.cos(a), -math.sin(a)) * (rr * .96));
        }
      }
    }
    _sfDots(c, darkDots, s * .034, const Color(0x99141b2c));
    _sfDots(c, litDots, s * .03, const Color(0x8056697a));
    _sfDots(c, olive, s * .05, const Color(0xcc5f4f31));
    _sfDots(c, gold, s * .05, const Color(0xcc9c8a40));
    _sfDots(c, bright, s * .026, const Color(0xe6d8bd58));
    _sfDots(c, rimDots, s * .014, const Color(0x99a8c0d0));
    // A few gaps of deep shade inside the crown.
    _sfDots(
      c,
      [
        for (var j = 0; j < 4; j++)
          Offset(x((rnd(800 + j) - .5) * .5), y(.66 + .22 * rnd(810 + j))),
      ],
      s * .036,
      const Color(0xff141b2c),
    );
    // Seed balls hang in pairs from thin stalks under the crown.
    final stalk = Path();
    final balls = <Offset>[];
    for (final (bx, bv) in const [(-.34, .48), (.34, .5), (.09, .575)]) {
      stalk
        ..moveTo(x(bx), y(bv))
        ..lineTo(x(bx), y(bv - .045));
      balls
        ..add(Offset(x(bx), y(bv - .06)))
        ..add(Offset(x(bx + .014), y(bv - .048)));
    }
    c.drawPath(
      stalk,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff3a3944)
        ..strokeWidth = math.max(.6, s * .004),
    );
    _sfDots(c, balls, s * .024, const Color(0xff5a4d3a));
  }

  /// A Paris park bench in front view, [s] wide: cast-iron end frames with
  /// scrolled armrests and ball finials, a seat and a slatted back in the
  /// deep green of the city's benches, moonlit from the right.
  static void _bench(Canvas c, Offset base, double s) {
    double x(double u) => base.dx + u * s;
    double y(double v) => base.dy - v * s;
    final iron = Paint()..color = _sfIron;
    final rim = Paint()..color = const Color(0xb34d5482);
    final wood = Paint()
      ..shader = Gradient.linear(
        Offset(x(-.46), 0),
        Offset(x(.46), 0),
        const [Color(0xff2f4d4b), Color(0xff5b8c82)],
      );
    final glint = Paint()
      ..color = const Color(0xb39fd0c6)
      ..strokeWidth = math.max(.7, s * .012);
    // Cast ribs behind the slats show through the gaps.
    for (final u in const [-.2, 0.0, .2]) {
      c.drawRect(Rect.fromLTRB(x(u - .009), y(.53), x(u + .009), y(.27)), iron);
    }
    // The two end frames: foot, leg, rear upright with its ball finial, and
    // an armrest that ends in a curl.
    for (final k in const [-1.0, 1.0]) {
      final cx = k * .43;
      c.drawRRect(
        RRect.fromLTRBR(x(cx - .058), y(.135), x(cx + .058), y(.075), Radius.circular(s * .02)),
        iron,
      );
      c.drawPath(
        Sketch.poly([x(cx - .026), y(.135), x(cx + .026), y(.135), x(cx + .017), y(.28), x(cx - .017), y(.28)]),
        iron,
      );
      c.drawRect(Rect.fromLTRB(x(k * .415 - .012), y(.545), x(k * .415 + .012), y(.27)), iron);
      c.drawRect(Rect.fromLTRB(x(cx - .014), y(.395), x(cx + .014), y(.27)), iron);
      c.drawRRect(
        RRect.fromLTRBR(x(cx - .07), y(.418), x(cx + .07), y(.392), Radius.circular(s * .013)),
        iron,
      );
      c.drawCircle(Offset(x(cx + k * .066), y(.392)), s * .02, iron);
      c.drawCircle(Offset(x(k * .415), y(.558)), s * .02, iron);
    }
    // Moonlight on the right-hand frame.
    c.drawRect(Rect.fromLTRB(x(.436), y(.27), x(.447), y(.137)), rim);
    c.drawRect(Rect.fromLTRB(x(.37), y(.418), x(.49), y(.41)), rim);
    c.drawCircle(Offset(x(.421), y(.564)), s * .007, Paint()..color = const Color(0xffa8b0e0));
    // The rail under the seat, the seat, and its shadow line.
    c.drawRect(Rect.fromLTRB(x(-.43), y(.245), x(.43), y(.212)), iron);
    c.drawRRect(
      RRect.fromLTRBR(x(-.475), y(.3), x(.475), y(.245), Radius.circular(s * .012)),
      wood,
    );
    c.drawLine(Offset(x(-.46), y(.297)), Offset(x(.46), y(.297)), glint);
    c.drawLine(
      Offset(x(-.47), y(.246)),
      Offset(x(.47), y(.246)),
      Paint()
        ..color = const Color(0xaa0b0c18)
        ..strokeWidth = math.max(.7, s * .01),
    );
    // Three slats make the back.
    for (final (v0, v1) in const [(.335, .378), (.405, .448), (.475, .518)]) {
      c.drawRRect(
        RRect.fromLTRBR(x(-.415), y(v1), x(.415), y(v0), Radius.circular(s * .008)),
        wood,
      );
      c.drawLine(Offset(x(-.4), y(v1 - .004)), Offset(x(.4), y(v1 - .004)), glint);
    }
  }

  /// Pavement rows under the ridge as (top, height, sett width), in viewport
  /// heights: setts grow toward the viewer.
  static const _sfRows = [
    (.002, .0095, .026),
    (.0115, .011, .032),
    (.0225, .013, .039),
    (.0355, .015, .047),
    (.0505, .0175, .056),
  ];

  static Picture? _sfPaving;
  static double _sfPavingH = 0;

  /// The paving picture for viewport height [h], recorded once and reused.
  Picture _sfPavingFor(double h) {
    final cached = _sfPaving;
    if (cached != null && _sfPavingH == h) return cached;
    cached?.dispose();
    final recorder = PictureRecorder();
    _sfPave(Canvas(recorder), h);
    final picture = recorder.endRecording();
    _sfPaving = picture;
    _sfPavingH = h;
    return picture;
  }

  static void _sfPts(Canvas c, PointMode mode, List<Offset> pts, Paint paint) {
    if (pts.isNotEmpty) c.drawPoints(mode, pts, paint);
  }

  /// A soft dark ellipse of radii [rx] and [ry]: a cast shadow.
  static void _sfBlob(Canvas c, Offset at, double rx, double ry, Color color) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(rx, ry);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          1,
          [color, Sketch.fade(color, .55), Sketch.fade(color, 0)],
          const [0, .5, 1],
        ),
    );
    c.restore();
  }

  /// Granite setts in running bond over one period of the near band, below
  /// the ridge: each stone may be lighter or darker, lit on its top edge by
  /// the moon, with dark joints and the odd wet glint; then fallen leaves and
  /// the soft shadows of trees, benches and lamp feet, cast to the left.
  void _sfPave(Canvas c, double h) {
    final span = period(Depth.near) * h;
    double edge(double px) => ridge(Depth.near, px / h, 0) * h;
    final line = Paint()..style = PaintingStyle.stroke;
    for (var r = 0; r < _sfRows.length; r++) {
      final (top, rh, sw) = _sfRows[r];
      final n = math.max(1, (span / (h * sw)).round());
      // Joints are jittered but pinned at both ends so the band tiles.
      final xj = <double>[
        for (var k = 0; k <= n; k++)
          k == 0
              ? 0.0
              : k == n
              ? span
              : span * (k + (Sketch.hash(r * 977 + k) - .5) * .5) / n,
      ];
      final light = <Offset>[], dark = <Offset>[], joints = <Offset>[];
      final glints = <Offset>[], sparks = <Offset>[];
      final gap = h * .0008;
      for (var k = 0; k < n; k++) {
        final xa = xj[k], xb = xj[k + 1], xc = (xa + xb) / 2;
        final y0 = edge(xc) + top * h, y1 = y0 + rh * h;
        final yc = (y0 + y1) / 2;
        final tone = Sketch.hash(r * 401 + k + 7);
        if (tone < .3) {
          light
            ..add(Offset(xa + gap, yc))
            ..add(Offset(xb - gap, yc));
        } else if (tone > .7) {
          dark
            ..add(Offset(xa + gap, yc))
            ..add(Offset(xb - gap, yc));
        }
        joints
          ..add(Offset(xa, y0))
          ..add(Offset(xa, y1));
        final gy = y0 + rh * h * .16;
        glints
          ..add(Offset(xa + (xb - xa) * .3, gy))
          ..add(Offset(xb - gap * 2, gy));
        if (Sketch.hash(r * 631 + k + 3) > .82) {
          sparks.add(Offset(xc + (xb - xa) * .2, y0 + rh * h * .32));
        }
      }
      line
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = rh * h * .86;
      _sfPts(c, PointMode.lines, light, line..color = const Color(0x1fb6bcf0));
      _sfPts(c, PointMode.lines, dark, line..color = const Color(0x33080920));
      line.strokeWidth = math.max(.8, h * .0018);
      _sfPts(c, PointMode.lines, joints, line..color = const Color(0x99101128));
      line.strokeWidth = math.max(.6, h * .0012);
      _sfPts(c, PointMode.lines, glints, line..color = const Color(0x40cfd3ff));
      line
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.9, h * .0016);
      _sfPts(c, PointMode.points, sparks, line..color = const Color(0x88dfe4ff));
      // The seam along the top of the row follows the ridge.
      final seam = Path()..moveTo(0, edge(0) + top * h);
      for (var i = 1; i <= 30; i++) {
        final px = span * i / 30;
        seam.lineTo(px, edge(px) + top * h);
      }
      line
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = math.max(.8, h * .0018)
        ..color = const Color(0xb30f1026);
      c.drawPath(seam, line);
    }
    // Fallen leaves, most of them under the trees.
    final litter = [Path(), Path(), Path(), Path()];
    for (var i = 0; i < 28; i++) {
      final lx = i % 4 != 3
          ? span * _trees[i % _trees.length] + (Sketch.hash(i * 3 + 801) - .5) * h * .36
          : span * Sketch.hash(i * 3 + 800);
      final z = Sketch.hash(i * 3 + 802);
      _sfLeafInto(
        litter[i % 4],
        lx,
        edge(lx) + h * (.01 + .05 * z),
        h * (.0048 + .0048 * z),
        Sketch.hash(i * 5 + 803) * math.pi * 2,
        .34,
      );
    }
    for (var i = 0; i < 4; i++) {
      c.drawPath(
        litter[i],
        Paint()..color = Sketch.mix(_sfLeafColors[i], const Color(0xff2a2b45), .3),
      );
    }
    // Shadows fall away from the moon, to the left.
    const shade = Color(0x4008091a);
    for (final fx in _trees) {
      final px = span * fx;
      _sfBlob(c, Offset(px - h * .045, edge(px) + h * .028), h * .11, h * .017, shade);
      _sfBlob(c, Offset(px - h * .1, edge(px) + h * .042), h * .2, h * .022, const Color(0x24080a1c));
    }
    for (final fx in _benches) {
      final px = span * fx;
      _sfBlob(c, Offset(px - h * .02, edge(px) + h * .02), h * .055, h * .009, shade);
    }
    for (final fx in _lamps) {
      final px = span * fx;
      _sfBlob(c, Offset(px, edge(px) + h * .012), h * .035, h * .007, shade);
    }
  }

  static const _sfLeafSlots = 12;
  static const _sfLeafColors = [
    Color(0xffd6a23a),
    Color(0xffc2712c),
    Color(0xff9c4a2b),
    Color(0xffb0a548),
  ];

  /// A plane leaf, palmate with pointed lobes, as a polygon in the unit
  /// circle with its stalk pointing down.
  static const _sfLeafPts = <double>[
    0.0, -1.0, .2, -.5, .72, -.66, .46, -.16, .98, .06, .52, .24, .14, .5, .05, .98,
    -.05, .98, -.14, .5, -.52, .24, -.98, .06, -.46, -.16, -.72, -.66, -.2, -.5,
  ];
  static final Path _sfLeaf = Sketch.poly(_sfLeafPts);
  static final _sfLeafInk = Paint();

  /// Adds a leaf of radius [r] lying at ([cx], [cy]) to [p], turned by [rot]
  /// and foreshortened to [flat] of its height.
  static void _sfLeafInto(Path p, double cx, double cy, double r, double rot, double flat) {
    final cs = math.cos(rot), sn = math.sin(rot);
    for (var i = 0; i + 1 < _sfLeafPts.length; i += 2) {
      final px = _sfLeafPts[i], py = _sfLeafPts[i + 1];
      final ox = cx + (px * cs - py * sn) * r;
      final oy = cy + (px * sn + py * cs) * r * flat;
      if (i == 0) {
        p.moveTo(ox, oy);
      } else {
        p.lineTo(ox, oy);
      }
    }
    p.close();
  }

  /// Plane leaves let go of the crowns, tumble and sway down, and settle on
  /// the paving, where they fade out. Each slot's path is a pure function of
  /// the clock, so nothing is stored between frames.
  void _sfLeaves(Canvas c, double h, double span, double clock, double presence) {
    for (var i = 0; i < _sfLeafSlots; i++) {
      final k = 600 + i * 9;
      final z = Sketch.hash(k + 1);
      final life = 8 + 6 * Sketch.hash(k + 2);
      final ph = (clock / life + Sketch.hash(k + 3)) % 1.0;
      final fall = math.min(1.0, ph / .8);
      final settle = _sfUnit((fall - .92) / .08);
      final x0 = span * _trees[i % _trees.length] + (Sketch.hash(k + 4) * 2 - 1) * h * .075;
      final edge = ridge(Depth.near, x0 / h, 0) * h;
      final y0 = edge - h * (.1 + .09 * Sketch.hash(k + 5));
      final y1 = edge + h * (.006 + .045 * z);
      final drop = math.pow(fall, 1.15).toDouble();
      final x = x0 + math.sin(fall * 10.5 + i * 1.7) * h * .045 * (1 - fall * .6) - h * .05 * fall;
      final y = y0 + (y1 - y0) * drop;
      final flutter = .3 + .7 * math.cos(fall * 19 + i * 2.1).abs();
      final flat = flutter + (.3 - flutter) * settle;
      final rot = i * 1.3 + math.sin(fall * 13 + i * .9) * .9 * (1 - settle) + fall * 4;
      final a = math.min(math.min(1.0, ph / .06), (1 - ph) / .06) * presence;
      if (a <= .01) continue;
      final r = h * (.0062 + .005 * z);
      _sfLeafInk.color = Sketch.fade(_sfLeafColors[i % _sfLeafColors.length], a);
      c.save();
      c.translate(x, y);
      c.rotate(rot);
      c.scale(r, r * flat);
      c.drawPath(_sfLeaf, _sfLeafInk);
      c.restore();
    }
  }
}

/// One row of Haussmann blocks, laid down as a handful of batched layers so a
/// whole street of windows, railings or dormers is a single fill.
///
/// Every façade shares one elevation, measured in storeys of [u] pixels: an
/// entresol under the first floor, four to six floors between stringcourses,
/// the continuous iron balconies of the second and fifth floors, a cornice
/// and a zinc mansard with dormers and crowded chimney pots. The floors have
/// fixed heights, so balcony and cornice lines run level along a street and
/// blocks differ by whole storeys. A block that ends on a cross street may
/// turn the corner in a chamfer under a zinc turret. The moon is on the
/// right: quoins and chamfers on that side catch its light, those on the
/// left fall dark. Detail switches on as the bays grow: [fine] adds shutters,
/// lintels, blinds and framed dormers, [rich] adds sash bars, balusters,
/// consoles, dentils and zinc seams.
class _HbRow {
  _HbRow(
    this.c,
    this.baseY,
    this.h,
    this.haze,
    this.seed,
    this.tall,
    this.detail,
    this.cut,
  );

  final Canvas c;

  /// The pavement line, the viewport height, the share of distance haze, and
  /// the height of a five-floor block up to its cornice.
  final double baseY, h, haze, tall;

  /// Pixel row above which the row shows; anything lower is skipped.
  final double cut;
  final int seed;
  final bool detail;

  late final double u = h * (tall + .02) / 9.3;
  late final double pitch = u * (detail ? .96 : 1.05);
  late final bool fine = pitch >= (detail ? 6.5 : 11);
  late final bool rich = pitch >= (detail ? 8.4 : 16);

  Color _k(int argb, [double t = 1]) => ParisScene._hazed(Color(argb), haze * t);

  late final Color wallA = _k(0xff56517a);
  late final Color wallB = _k(0xff675e82);
  late final Color wallLow = _k(0xff433f66);
  late final Color wallLit = _k(0xff7c7599);
  late final Color wallShade = _k(0xff3f3c62);
  late final Color stone = _k(0xff716b93);
  late final Color stoneHi = _k(0xff9a93b2);
  late final Color shadow = _k(0xff2f2e52);
  late final Color openCol = _k(0xff2a2b4a);
  late final Color shutCol = _k(0xff3b3f66);
  late final Color lit = _k(0xffffcf6a, .6);
  late final Color litCool = _k(0xffbdd0f6, .6);
  late final Color halo = Sketch.fade(lit, .2);
  late final Color mull = _k(0xff3a3048);
  late final Color iron = _k(0xff1f1e38);
  late final Color roofCol = _k(0xff363a5c);
  late final Color roofTopCol = _k(0xff535a83);
  late final Color roofLitCol = _k(0xff7580a8);
  late final Color turretCol = _k(0xff444a72);
  late final Color ridgeCol = _k(0xff9c8ab4);
  late final Color seamCol = _k(0xff2c3050);
  late final Color pedCol = _k(0xff4b5179);
  late final Color brick = _k(0xff5d4a66);
  late final Color brickLit = _k(0xff82697b);
  late final Color capCol = _k(0xff8a85a6);
  late final Color potCol = _k(0xff6c4a58);
  late final Color potRim = _k(0xff90696f);

  // Layers, back to front: chimneys, walls, roofs, stone, openings, iron.
  final pStack = Path(), pStackLit = Path(), pCap = Path();
  final pPot = Path(), pPotRim = Path();
  final pRoof = Path(), pRoofTop = Path(), pSeam = Path(), pTurr = Path();
  final pRoofLit = Path(), pRidge = Path();
  final pBand = Path(), pShade = Path(), pHi = Path();
  final pEdgeDark = Path(), pEdgeLit = Path();
  final pDorm = Path(), pOpen = Path(), pShut = Path(), pHalo = Path();
  final pLit = Path(), pLitCool = Path(), pMull = Path();
  final pPed = Path(), pPedLit = Path();
  final pBody = Path(), pRail = Path(), pIron = Path(), pSpire = Path();
  final walls = <Rect>[], wallTop = <Color>[], wallBot = <Color>[];

  /// Lays blocks from [x0] to [x1]: two to four façades each, a cross street
  /// after most of them, then draws every layer.
  void paint(double x0, double x1) {
    final gap = pitch * (detail ? 1.5 : 1.1);
    var x = x0, bi = 0, block = 0;
    var streetBefore = true;
    while (x < x1) {
      final kb = seed * 977 + block * 13;
      final fr = Sketch.hash(kb + 1);
      final floors = fr < .17 ? 4 : (fr < .85 ? 5 : 6);
      final count = 2 + (Sketch.hash(kb + 2) * 3).floor();
      final streetAfter = Sketch.hash(kb + 3) < .75;
      final cornerL = streetBefore && Sketch.hash(kb + 4) < .7;
      final cornerR = streetAfter && Sketch.hash(kb + 5) < .7;
      for (var j = 0; j < count; j++) {
        final n = seed * 613 + bi * 29;
        bi++;
        final bays = 5 + (Sketch.hash(n + 1) * (detail ? 4 : 5)).floor();
        final cl = cornerL && j == 0;
        final cr = cornerR && j == count - 1;
        final nReg = bays - (cl ? 1 : 0) - (cr ? 1 : 0);
        final bw = (cl ? pitch * .72 : 0.0) + nReg * pitch + (cr ? pitch * .72 : 0.0);
        _building(
          x,
          bw,
          n,
          floors,
          nReg,
          cl,
          cr,
          endL: j == 0 && streetBefore,
          endR: j == count - 1 && streetAfter,
          last: j == count - 1,
        );
        x += bw;
      }
      if (streetAfter) x += gap;
      streetBefore = streetAfter;
      block++;
    }
    _flush();
  }

  void _building(
    double left,
    double bw,
    int n,
    int floors,
    int nReg,
    bool cl,
    bool cr, {
    required bool endL,
    required bool endR,
    required bool last,
  }) {
    final right = left + bw;
    double ty(double t) => baseY - t * u;
    final xl0 = cl ? pitch * .72 : 0.0;
    final xr0 = cr ? pitch * .72 : 0.0;
    final top = floors == 4 ? 6.6 : (floors == 5 ? 7.65 : 8.5);
    final corn = top + .3;
    final line = math.max(.5, u * .05);

    // The elevation in storeys above the pavement: floor spans, thin
    // stringcourses and the heavy slabs that carry the continuous balconies.
    final spans = <(double, double)>[
      (2.32, 3.32),
      (3.48, 4.58),
      (4.68, 5.65),
      floors == 4 ? (5.81, 6.6) : (5.73, 6.65),
      if (floors >= 5) (6.8, 7.65),
      if (floors == 6) (7.73, 8.5),
    ];
    final bands = <(double, double)>[
      (2.2, 2.32),
      (4.58, 4.68),
      if (floors >= 5) (5.65, 5.73),
      if (floors == 6) (7.65, 7.73),
    ];
    final slabs = <(double, double)>[
      (3.32, 3.48),
      floors == 4 ? (5.65, 5.81) : (6.65, 6.8),
    ];
    // Centres of the window bays and their width: chamfers are narrower.
    final bayC = <(double, double)>[
      if (cl) (left + xl0 * .5, .62),
      for (var j = 0; j < nReg; j++) (left + xl0 + pitch * (j + .5), 1.0),
      if (cr) (right - xr0 * .5, .62),
    ];

    // Limestone, a shade darker toward the street.
    final tint = Color.lerp(wallA, wallB, Sketch.hash(n + 3))!;
    walls.add(Rect.fromLTRB(left, ty(corn), right, baseY + h * .03));
    wallTop.add(tint);
    wallBot.add(Color.lerp(tint, wallLow, .55)!);

    for (final (b0, b1) in bands) {
      if (ty(b1) > cut) continue;
      pBand.addRect(Rect.fromLTRB(left, ty(b1), right, ty(b0)));
      pHi.addRect(Rect.fromLTRB(left, ty(b1), right, ty(b1) + line));
      pShade.addRect(Rect.fromLTRB(left, ty(b0), right, ty(b0) + math.max(.5, u * .09)));
    }
    for (final (s0, s1) in slabs) {
      if (ty(s1) > cut) continue;
      pBand.addRect(Rect.fromLTRB(left, ty(s1), right, ty(s0)));
      pHi.addRect(Rect.fromLTRB(left, ty(s1), right, ty(s1) + line));
      pShade.addRect(Rect.fromLTRB(left, ty(s0), right, ty(s0) + u * .16));
      if (rich) {
        // Consoles under the slab at every pier.
        for (var i = 0; i <= nReg; i++) {
          final bx = left + xl0 + pitch * i;
          pShade
            ..moveTo(bx - pitch * .09, ty(s0))
            ..lineTo(bx + pitch * .09, ty(s0))
            ..lineTo(bx, ty(s0) + u * .3)
            ..close();
        }
      }
    }
    // The cornice: a moonlit crown over a deep shadow.
    pBand.addRect(Rect.fromLTRB(left, ty(corn), right, ty(top)));
    pHi.addRect(Rect.fromLTRB(left, ty(corn), right, ty(corn) + line * 1.4));
    pShade.addRect(Rect.fromLTRB(left, ty(top), right, ty(top) + u * .2));
    if (rich) {
      for (var dx = left + u * .1; dx < right - u * .2; dx += u * .3) {
        pShade.addRect(Rect.fromLTRB(dx, ty(top) - u * .1, dx + u * .13, ty(top)));
      }
    }

    // Windows, floor by floor; the continuous balconies close each of the
    // second and the top floor.
    const wfrac = [.78, .86, .78, .74, .66, .6];
    final ww0 = pitch * (fine ? .4 : .5);
    final topBalcony = floors == 4 ? 3 : 4;
    for (var k = 0; k < spans.length; k++) {
      final (b0, b1) = spans[k];
      if (ty(b1) > cut) continue;
      final wb = b0 + .05, wt = wb + (b1 - b0) * wfrac[k];
      final balcony = k == 1 || k == topBalcony;
      for (var m = 0; m < bayC.length; m++) {
        final (cx, s) = bayC[m];
        final ww = ww0 * s;
        final wr = Rect.fromLTRB(cx - ww / 2, ty(wt), cx + ww / 2, ty(wb));
        final r = Sketch.hash(n * 61 + k * 13 + m);
        final r2 = Sketch.hash(n * 61 + k * 13 + m + 700);
        pOpen.addRect(wr);
        if (r < .42) {
          // Blinds half drawn on some of the lit windows.
          final blind = fine && r2 > .55 ? wr.height * (.1 + .3 * r2) : 0.0;
          (r2 > .92 ? pLitCool : pLit).addRect(
            Rect.fromLTRB(wr.left, wr.top + blind, wr.right, wr.bottom),
          );
          if (fine) pHalo.addRect(wr.inflate(u * .1));
          if (rich) {
            final mw = math.max(.6, u * .05);
            pMull
              ..addRect(Rect.fromLTRB(cx - mw / 2, wr.top, cx + mw / 2, wr.bottom))
              ..addRect(Rect.fromLTRB(wr.left, wr.top + wr.height * .36, wr.right, wr.top + wr.height * .36 + mw));
          }
        }
        if (!fine) continue;
        if (s == 1) {
          // Shutters folded back against the wall.
          final sw = ww * .34;
          pShut
            ..addRect(Rect.fromLTRB(wr.left - sw, wr.top, wr.left, wr.bottom))
            ..addRect(Rect.fromLTRB(wr.right, wr.top, wr.right + sw, wr.bottom));
        }
        pBand.addRect(Rect.fromLTRB(cx - ww * .68, wr.top - u * .08, cx + ww * .68, wr.top));
        if (!balcony) {
          pBand.addRect(Rect.fromLTRB(cx - ww * .66, wr.bottom, cx + ww * .66, wr.bottom + u * .06));
          if (k != 4 && k != 5) {
            // A guard rail across the open casement.
            final ry = ty(wb + .36);
            pRail.addRect(Rect.fromLTRB(cx - ww * .72, ry, cx + ww * .72, ry + math.max(.6, u * .04)));
            if (rich) {
              for (var q = 0; q < 5; q++) {
                final bx = cx - ww * .66 + ww * 1.32 * q / 4;
                pIron
                  ..moveTo(bx, ry)
                  ..lineTo(bx, wr.bottom);
              }
            } else {
              pBody.addRect(Rect.fromLTRB(cx - ww * .72, ry, cx + ww * .72, wr.bottom));
            }
          }
        } else if (rich && k == 1 && m.isEven) {
          // Small pediments over the windows of the noble floor.
          pBand
            ..moveTo(cx - ww * .74, wr.top - u * .08)
            ..lineTo(cx, wr.top - u * .08 - u * .16)
            ..lineTo(cx + ww * .74, wr.top - u * .08)
            ..close();
        }
      }
      if (!balcony) continue;
      // The balcony: a rail along the whole façade over a lattice of iron.
      final rt = ty(b0 + .48), rb = ty(b0 + .06);
      pRail.addRect(Rect.fromLTRB(left, rt, right, rt + math.max(.7, u * .05)));
      if (!rich) {
        pBody.addRect(Rect.fromLTRB(left, rt, right, ty(b0)));
        continue;
      }
      pRail.addRect(Rect.fromLTRB(left, rb - line, right, rb));
      for (var bx = left + u * .15; bx < right; bx += u * .3) {
        pIron
          ..moveTo(bx, rt)
          ..lineTo(bx, rb);
      }
      for (final (cx, s) in bayC) {
        final d = ww0 * s * .62, mid = (rt + rb) / 2;
        pIron
          ..moveTo(cx - d, mid)
          ..lineTo(cx, rt)
          ..lineTo(cx + d, mid)
          ..lineTo(cx, rb)
          ..lineTo(cx - d, mid);
      }
    }

    // Moonlight rakes the right-hand edge; the left is a dark party line.
    final hair = math.max(.5, pitch * .06);
    final lw = math.max(.7, pitch * .16);
    pEdgeDark.addRect(Rect.fromLTRB(left, ty(corn), left + hair, baseY));
    if (cl) pEdgeDark.addRect(Rect.fromLTRB(left, ty(corn), left + xl0, baseY));
    pEdgeLit.addRect(Rect.fromLTRB(right - (cr ? xr0 : lw), ty(corn), right, baseY));

    // The mansard: a steep zinc brisis under a shallow terrasson; at the end
    // of a block the roof shows its profile.
    final yc = ty(corn);
    final bH = u * (1.02 + .16 * Sketch.hash(n + 5));
    final tH = u * .26;
    final insL = endL ? pitch * .34 : 0.0, insR = endR ? pitch * .34 : 0.0;
    final tl = endL ? u * .3 : 0.0, tr = endR ? u * .3 : 0.0;
    final yTop = yc - bH - tH;
    pRoof
      ..moveTo(left, yc)
      ..lineTo(left + insL, yc - bH)
      ..lineTo(right - insR, yc - bH)
      ..lineTo(right, yc)
      ..close();
    pRoofTop
      ..moveTo(left + insL, yc - bH)
      ..lineTo(left + insL + tl, yTop)
      ..lineTo(right - insR - tr, yTop)
      ..lineTo(right - insR, yc - bH)
      ..close();
    pRidge.addRect(Rect.fromLTRB(left + insL + tl, yTop - line * 1.3, right - insR - tr, yTop));
    pRoofLit.addRect(Rect.fromLTRB(left + insL, yc - bH - line * .5, right - insR, yc - bH + line));
    if (endR) {
      final w = math.max(.7, pitch * .1);
      pRoofLit
        ..moveTo(right, yc)
        ..lineTo(right - insR, yc - bH)
        ..lineTo(right - insR - w, yc - bH)
        ..lineTo(right - w, yc)
        ..close();
    }
    if (rich) {
      final sw = math.max(.5, u * .03);
      for (var sx = left + insL + u * .3; sx < right - insR - u * .2; sx += u * .5) {
        pSeam.addRect(Rect.fromLTRB(sx, yc - bH, sx + sw, yc));
      }
    }

    // Dormers sit over the window axes, every bay or every other one.
    final dstep = Sketch.hash(n + 9) < .55 ? 1 : 2;
    for (var j = 0; j < nReg; j++) {
      if (dstep == 2 && (j + n) % 2 == 1) continue;
      if ((endL && !cl && j == 0) || (endR && !cr && j == nReg - 1)) continue;
      final cx = left + xl0 + pitch * (j + .5);
      final dr = Sketch.hash(n * 37 + j + 300);
      final dr2 = Sketch.hash(n * 37 + j + 340);
      if (fine) {
        _dormer(cx, yc - u * .1, dr < .38, dr2 > .82);
      } else if (pitch >= 3) {
        final o = Rect.fromLTRB(cx - pitch * .17, yc - u * .55, cx + pitch * .17, yc - u * .12);
        (dr < .38 ? pLit : pOpen).addRect(o);
      }
    }
    if (cl) _turret(left + xl0 * .5, yc, bH, n);
    if (cr) _turret(right - xr0 * .5, yc, bH, n + 1);

    // A stack of flues straddles each party wall, crowned with pots.
    if (Sketch.hash(n + 11) < .8 && !(last && cr)) {
      final sw = pitch * (.45 + .3 * Sketch.hash(n + 12));
      final sx = last ? right - insR - tr - sw * .8 : right;
      _stack(sx, yTop, sw, u * (.75 + .7 * Sketch.hash(n + 13)), n);
    }
  }

  /// A dormer window under a small pediment; [round] makes it an oeil-de-boeuf.
  void _dormer(double cx, double base, bool on, bool round) {
    final dw = pitch * .3, fw = dw * 1.55;
    if (round) {
      final ctr = Offset(cx, base - u * .33);
      pDorm.addOval(Rect.fromCircle(center: ctr, radius: dw * .78));
      (on ? pLit : pOpen).addOval(Rect.fromCircle(center: ctr, radius: dw * .5));
      return;
    }
    final ft = base - u * .6;
    pDorm.addRect(Rect.fromLTRB(cx - fw / 2, ft, cx + fw / 2, base));
    final o = Rect.fromLTRB(cx - dw / 2, ft + u * .08, cx + dw / 2, base - u * .04);
    if (on) {
      pLit.addRect(o);
      pHalo.addRect(o.inflate(u * .1));
    } else {
      pOpen.addRect(o);
    }
    final pw = fw * .64;
    pPed
      ..moveTo(cx - pw, ft)
      ..lineTo(cx, ft - u * .3)
      ..lineTo(cx + pw, ft)
      ..close();
    pPedLit
      ..moveTo(cx, ft - u * .3)
      ..lineTo(cx + pw, ft)
      ..lineTo(cx, ft)
      ..close();
  }

  /// A brick chimney stack of width [sw] and height [sh] rising from behind
  /// the roof at [yTop], its pots crowded on a stone cap.
  void _stack(double sx, double yTop, double sw, double sh, int n) {
    final l = sx - sw / 2, r = sx + sw / 2, t = yTop - sh;
    pStack.addRect(Rect.fromLTRB(l, t, r, yTop + u * .5));
    pStackLit.addRect(Rect.fromLTRB(r - sw * .3, t, r, yTop + u * .5));
    final ch = math.max(.6, u * .16);
    pCap.addRect(Rect.fromLTRB(l - sw * .08, t - ch, r + sw * .08, t));
    final np = math.max(2, math.min(6, (sw / (u * .24)).floor()));
    final slot = sw / np;
    for (var q = 0; q < np; q++) {
      final px = l + slot * q + slot * .18, pw = slot * .64;
      final ph = u * (.34 + .16 * Sketch.hash(n * 5 + q));
      pPot.addRect(Rect.fromLTRB(px, t - ch - ph, px + pw, t - ch));
      pPotRim.addRect(
        Rect.fromLTRB(px - pw * .14, t - ch - ph - math.max(.5, u * .06), px + pw * 1.14, t - ch - ph),
      );
    }
  }

  /// A corner turret over a chamfer: a zinc drum under a curved, pointed cap.
  void _turret(double cx, double yc, double bH, int n) {
    final tw = pitch * .92;
    final l = cx - tw / 2, r = cx + tw / 2;
    final ring = yc - bH - u * .4;
    pTurr.addRect(Rect.fromLTRB(l, ring, r, yc));
    pRoofLit.addRect(Rect.fromLTRB(r - tw * .3, ring, r, yc));
    if (fine) {
      final o = Rect.fromLTRB(cx - tw * .15, ring + u * .18, cx + tw * .15, ring + u * .7);
      (Sketch.hash(n + 20) < .5 ? pLit : pOpen).addRect(o);
    }
    pBand.addRect(Rect.fromLTRB(l - tw * .1, ring - u * .1, r + tw * .1, ring));
    final eave = ring - u * .1;
    final capH = u * (1.6 + .5 * Sketch.hash(n + 21));
    final cw = tw * .62;
    pRoof
      ..moveTo(cx - cw, eave)
      ..quadraticBezierTo(cx - cw * .75, eave - capH * .5, cx, eave - capH)
      ..quadraticBezierTo(cx + cw * .75, eave - capH * .5, cx + cw, eave)
      ..close();
    pRoofLit
      ..moveTo(cx, eave - capH)
      ..quadraticBezierTo(cx + cw * .75, eave - capH * .5, cx + cw, eave)
      ..lineTo(cx + cw * .08, eave)
      ..close();
    pSpire
      ..moveTo(cx, eave - capH)
      ..lineTo(cx, eave - capH - u * .55);
    pRoofLit.addOval(
      Rect.fromCircle(center: Offset(cx, eave - capH - u * .34), radius: math.max(.6, u * .07)),
    );
  }

  void _flush() {
    final f = Paint();
    void fill(Path p, Color col) => c.drawPath(p, f..color = col);
    fill(pStack, brick);
    fill(pStackLit, brickLit);
    fill(pCap, capCol);
    fill(pPot, potCol);
    fill(pPotRim, potRim);
    for (var i = 0; i < walls.length; i++) {
      final r = walls[i];
      c.drawRect(
        r,
        Paint()..shader = Gradient.linear(r.topCenter, r.bottomCenter, [wallTop[i], wallBot[i]]),
      );
    }
    fill(pRoof, roofCol);
    fill(pRoofTop, roofTopCol);
    fill(pSeam, seamCol);
    fill(pTurr, turretCol);
    fill(pRoofLit, roofLitCol);
    fill(pRidge, ridgeCol);
    fill(pBand, stone);
    fill(pShade, shadow);
    fill(pHi, stoneHi);
    fill(pEdgeDark, wallShade);
    fill(pEdgeLit, wallLit);
    fill(pDorm, stone);
    fill(pOpen, openCol);
    fill(pShut, shutCol);
    fill(pHalo, halo);
    fill(pLit, lit);
    fill(pLitCool, litCool);
    fill(pMull, mull);
    fill(pPed, pedCol);
    fill(pPedLit, roofLitCol);
    fill(pBody, Sketch.fade(iron, .55));
    fill(pRail, iron);
    final st = Paint()..style = PaintingStyle.stroke;
    c.drawPath(pIron, st..color = iron..strokeWidth = math.max(.5, u * .03));
    c.drawPath(pSpire, st..color = roofLitCol..strokeWidth = math.max(.6, u * .05));
  }
}
