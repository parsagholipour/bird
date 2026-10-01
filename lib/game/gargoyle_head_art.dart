import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PathOperation, PointMode;

import 'package:flutter/painting.dart';

import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';

/// What the head needs from a [GargoylePose], frozen for one frame: the parts
/// build their own small pose with `of` and never read the boss.
///
/// Every channel is sanitised where it is used ([GargoyleHeadArt.paint] clamps
/// and replaces non-finite numbers), so a hand-built pose can never make the
/// head throw or draw a NaN.
final class GargoyleHeadPose {
  const GargoyleHeadPose({
    required this.tone,
    this.gape = 0,
    this.flare = .3,
    this.brow = .3,
    this.iris = 1,
    this.fury = 0,
    this.crack = 0,
    this.wince = 0,
    this.roar = 0,
    this.glance = 0,
    this.visor = true,
    this.time = 0,
    this.hit = 0,
    this.wind = 0,
    this.crumble = 0,
    this.defeated = false,
  });

  /// The head of [pose]: [visor] is false once the defeat knocks it loose.
  factory GargoyleHeadPose.of(GargoylePose pose) => GargoyleHeadPose(
    tone: pose.tone,
    gape: pose.gape,
    flare: pose.flare,
    brow: pose.brow,
    iris: pose.iris,
    fury: pose.fury,
    crack: pose.crack,
    wince: pose.wince,
    roar: pose.roar,
    glance: pose.glance,
    visor: pose.visor > .5,
    time: pose.time,
    hit: pose.hit,
    wind: pose.wind,
    crumble: pose.crumble,
    defeated: pose.defeated,
  );

  final GargoyleTone tone;

  /// Beak open .. 0 shut (.55 in the vent), lens glow, scowl (0 relaxed .. 1
  /// furious), lens aperture (1 open .. 0 shut), fury, the head's own seams,
  /// the wince after a hit, the roar, the glance.
  final double gape, flare, brow, iris, fury, crack, wince, roar, glance;

  /// The hit's .28 s pulse, the intake before a roar, the body crumbling
  /// (defeat .85 s to 1.1 s).
  final double hit, wind, crumble;

  /// Whether the brow visors are on.
  final bool visor;

  /// The defeat is under way: the lenses go out unevenly (a dazed, knocked-out
  /// look) and the stone gives way.
  final bool defeated;

  /// Seconds on the boss clock (0 under Reduced Motion and in the defeat): the
  /// only thing it moves is the grit that falls off the brow as the stone wakes.
  final double time;
}

/// The Searchlight Gargoyle's head, neck to beak: a limestone skull of chiselled
/// planes under two stepped steel brow hoods that slope down to a deep hooked
/// beak (brass cere, nostril, a jaw that hangs from a pin), a crest of swept
/// steel blades, and two searchlight lenses (brass ring, glass, a white-hot core
/// that IS the beam's source) that sit in octagonal sockets and blink behind
/// steel lids.
///
/// Authored in HEAD-LOCAL units (rig scale 1.0, snout toward -x): the rig has
/// already placed, pitched, nudged and scaled the frame ([GargoyleLayout.
/// headPoint]); a painter never places the head. Anchors are the layout's: the
/// lens centres and radii ([GargoyleLayout.eyeNear], [GargoyleLayout.eyeFar])
/// are the beams' sources and do not move; the beak tip is the most forward
/// point of the creature.
///
/// Budget (contract): 70 ops, 3 shaders (skull limestone, head steel, lens
/// glass), 2 clips (the moon rims of skull and beak). No `saveLayer`, no blur,
/// no `Random`; every static shape is a cached [Path], the pose-dependent ones
/// (the hoods, the lids, the open mouth) are a handful of points built per
/// frame, and every paint is a pure function of the pose, so pixels never
/// depend on what was drawn before.
abstract final class GargoyleHeadArt {
  /// The anchors (all head-local); the layout owns them.
  static const eyeNear = GargoyleLayout.eyeNear, eyeFar = GargoyleLayout.eyeFar;
  static const eyeNearRadius = GargoyleLayout.eyeNearRadius, eyeFarRadius = GargoyleLayout.eyeFarRadius;
  static const beakTip = GargoyleLayout.beakTip, jawHinge = GargoyleLayout.jawHinge;

  /// The open mouth's interior: a dark plum, warmer than the ink so it reads as
  /// a throat and not as a line.
  static const mouthColor = Color(0xff2b1630);

  /// The limestone's shade side: violet, deeper than the palette's `limeShade`
  /// (shadows are violet, never black), so the lit planes pop.
  static const shadeViolet = Color(0xff7a6f86);

  /// Brass ring width around a lens glass, per lens.
  static const ringNear = .075, ringFar = .06;

  // ------------------------------------------------------------ geometry --

  static Path _poly(List<double> v, {bool closed = true}) {
    final p = Path()..moveTo(v[0], v[1]);
    for (var i = 2; i + 1 < v.length; i += 2) {
      p.lineTo(v[i], v[i + 1]);
    }
    if (closed) p.close();
    return p;
  }

  static Offset _at(List<double> v, int i) => Offset(v[i * 2], v[i * 2 + 1]);

  /// The skull: chamfered planes, not a dome. Back -.74, crown -3.08, chin -1.28.
  static const _skullPts = <double>[
    -1.02, -1.50, -.78, -1.84, -.74, -2.30, -.78, -2.66, -1.00, -2.90, -1.30, -3.07, -1.80, -3.08, //
    -2.40, -2.98, -2.90, -2.80, -3.12, -2.45, -2.98, -2.00, -2.50, -1.56, -2.00, -1.26, -1.42, -1.28,
  ];
  static final _skull = _poly(_skullPts);

  /// The upper mandible: carved facets and a deep hook that hangs BELOW the
  /// jaw. Tip (most forward) -3.82, hook -3.56,-1.12. Indices: 0 rear top,
  /// [_hookAt] the hook, [_gapeAt] the gape corner; the points between them are
  /// the cutting edge the jaw closes on.
  static const _hookAt = 6;
  static const _beakPts = <double>[
    -2.90, -2.97, -3.24, -2.89, -3.58, -2.70, -3.78, -2.34, -3.82, -1.98, -3.74, -1.56, //
    -3.56, -1.12, -3.52, -1.32, -3.42, -1.52, -3.28, -1.74, -3.06, -1.98, -2.90, -2.14, -2.86, -2.60,
  ];
  static final _beak = _poly(_beakPts);

  /// The lower mandible, hung from the hinge: a thin blade in front, a deep
  /// plate at the hinge. Its upper edge (indices 2..4) IS the beak's cutting edge.
  static const _jawPts = <double>[
    -2.15, -1.62, -2.50, -1.88, -3.06, -1.98, -3.28, -1.74, -3.42, -1.52, -3.30, -1.38, -3.05, -1.34, -2.70, -1.30, -2.25, -1.30,
  ];
  static final _jaw = _poly(_jawPts);
  static final _jawShade = _poly(const [-3.30, -1.38, -3.05, -1.34, -2.70, -1.30, -2.25, -1.30, -2.30, -1.44, -2.72, -1.46, -3.08, -1.48]);
  static final _jawLine = Path()
    ..moveTo(-2.34, -1.74)
    ..lineTo(-2.52, -1.62)
    ..lineTo(-2.34, -1.50)
    ..moveTo(-2.54, -1.76)
    ..lineTo(-2.72, -1.64)
    ..lineTo(-2.54, -1.52)
    ..moveTo(-2.74, -1.78)
    ..lineTo(-2.92, -1.66)
    ..lineTo(-2.74, -1.54);

  /// The beak's shaded underside, along the cutting edge to the hook, and its
  /// culmen streak.
  static final _beakShade = _poly(const [
    -3.56, -1.12, -3.52, -1.32, -3.42, -1.52, -3.28, -1.74, -3.06, -1.98, -2.90, -2.14, -3.10, -2.12, -3.34, -1.90, -3.50, -1.66, -3.62, -1.40, -3.66, -1.22,
  ]);
  static final _culmen = Path()
    ..moveTo(-3.22, -2.80)
    ..lineTo(-3.54, -2.62)
    ..lineTo(-3.70, -2.30)
    ..lineTo(-3.72, -1.96)
    ..moveTo(-3.66, -1.62)
    ..lineTo(-3.60, -1.40)
    ..moveTo(-3.55, -1.27)
    ..lineTo(-3.55, -1.27);

  /// The sky-lit facet along the culmen, the brass cere over the beak's root
  /// (its front edge follows the culmen) and the nostril cut in it.
  static final _beakLit = _poly(const [-3.24, -2.89, -3.58, -2.70, -3.78, -2.34, -3.82, -1.98, -3.74, -1.56, -3.66, -1.64, -3.68, -1.96, -3.64, -2.30, -3.50, -2.58, -3.24, -2.78]);
  static final _cere = _poly(const [-3.06, -2.95, -3.28, -2.88, -3.42, -2.74, -3.40, -2.54, -3.20, -2.42, -3.02, -2.44]);
  static final _cereShade = _poly(const [-3.02, -2.44, -3.20, -2.42, -3.40, -2.54, -3.39, -2.61, -3.20, -2.52, -3.02, -2.53]);
  static final _nostril = _poly(const [-3.36, -2.72, -3.25, -2.68, -3.22, -2.62, -3.30, -2.60, -3.37, -2.65]);

  /// The skull's planes: the shaded cheek below the brow, the dark edge at the
  /// back, and the carved plumage (overlapping pointed feathers, lower rows
  /// first so the upper rows lie over them).
  static final _planeCheek = _poly(const [-2.10, -2.04, -.78, -1.88, -1.02, -1.50, -1.42, -1.28, -2.00, -1.26, -2.50, -1.56, -2.30, -1.80]);
  static final _planeBack = _poly(const [-1.00, -2.52, -.76, -2.38, -.78, -1.88, -.95, -1.93]);
  static final _planesShade = Path()
    ..addPath(_planeCheek, Offset.zero)
    ..addPath(_planeBack, Offset.zero);

  /// The lit temple plane between the far hood and the back of the head, the
  /// two stepped bands that echo the skull's back edge, and the chisel marks
  /// in the cheek's mid-tone.
  static final _planeTemple = _poly(const [-1.32, -2.60, -.84, -2.68, -.76, -2.36, -1.04, -2.14, -1.34, -2.30]);
  static final _bands = Path()
    ..moveTo(-1.26, -2.98)
    ..lineTo(-1.04, -2.78)
    ..lineTo(-.92, -2.56)
    ..lineTo(-.90, -2.20)
    ..lineTo(-.95, -1.88)
    ..lineTo(-1.16, -1.58)
    ..moveTo(-1.30, -2.88)
    ..lineTo(-1.14, -2.72)
    ..lineTo(-1.04, -2.52)
    ..lineTo(-1.04, -2.22)
    ..lineTo(-1.08, -1.94);
  static final _hatch = Path()
    ..moveTo(-2.04, -1.72)
    ..lineTo(-1.88, -1.56)
    ..moveTo(-1.90, -1.72)
    ..lineTo(-1.74, -1.56)
    ..moveTo(-1.76, -1.72)
    ..lineTo(-1.60, -1.56)
    ..moveTo(-1.62, -1.72)
    ..lineTo(-1.46, -1.56)
    ..moveTo(-1.98, -1.94)
    ..lineTo(-1.82, -1.78)
    ..moveTo(-1.84, -1.94)
    ..lineTo(-1.68, -1.78);

  /// Gloss on the limestone: hard cream-white streaks (and a dot after each,
  /// like the roster's pill glints) along the upper-left bevel of the planes,
  /// and the moon's rim on the planes' upper-right edges.
  static final _stoneGloss = Path()
    ..moveTo(-.95, -2.36)
    ..quadraticBezierTo(-.86, -2.26, -.87, -2.06)
    ..moveTo(-.90, -1.94)
    ..lineTo(-.90, -1.94)
    ..moveTo(-1.98, -2.00)
    ..lineTo(-1.60, -1.945)
    ..moveTo(-1.50, -1.93)
    ..lineTo(-1.50, -1.93)
    ..moveTo(-2.00, -1.50)
    ..lineTo(-1.72, -1.44);
  static final _stoneRim = Path()
    ..moveTo(-1.28, -2.70)
    ..lineTo(-.86, -2.74)
    ..lineTo(-.80, -2.50)
    ..moveTo(-1.14, -1.985)
    ..lineTo(-.86, -1.92);

  /// The crease: a carved jowl line at the corner of the beak's hinge, bent
  /// like a chisel cut and dropping down the cheek (a sneer, never a smile),
  /// with a short second cut under it. Age and disdain in two strokes.
  static final _crease = Path()
    ..moveTo(-2.08, -1.90)
    ..lineTo(-1.90, -1.76)
    ..lineTo(-1.84, -1.50)
    ..moveTo(-1.78, -1.82)
    ..lineTo(-1.68, -1.62);

  /// The crest: a fan of four swept steel blades laid over the crown, each as
  /// (root, tip, half width); the tips are raked back (every tip is behind its
  /// root) and the tallest, -3.20, is the creature's highest point at rest.
  static const crestBlades = <(Offset, Offset, double)>[
    (Offset(-1.50, -2.98), Offset(-.62, -3.20), .13),
    (Offset(-1.36, -2.90), Offset(-.46, -3.05), .13),
    (Offset(-1.22, -2.76), Offset(-.42, -2.80), .13),
    (Offset(-1.10, -2.60), Offset(-.48, -2.52), .12),
  ];
  static final _crest = () {
    final p = Path();
    for (final (root, tip, w) in crestBlades) {
      final dx = tip.dx - root.dx, dy = tip.dy - root.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final nx = -dy / len, ny = dx / len;
      p
        ..moveTo(root.dx + nx * w, root.dy + ny * w)
        ..lineTo(root.dx + dx * .62 + nx * w * .95, root.dy + dy * .62 + ny * w * .95)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(root.dx + dx * .80 - nx * w * .9, root.dy + dy * .80 - ny * w * .9)
        ..lineTo(root.dx - nx * w, root.dy - ny * w)
        ..close();
    }
    return p;
  }();
  static final _crestShine = Path()
    ..moveTo(-1.44, -3.03)
    ..lineTo(-.80, -3.22)
    ..moveTo(-1.30, -2.92)
    ..lineTo(-.68, -3.03)
    ..moveTo(-1.16, -2.78)
    ..lineTo(-.62, -2.80)
    ..moveTo(-1.04, -2.62)
    ..lineTo(-.64, -2.56);

  /// The lenses' stepped limestone frames: an octagonal bevel around each
  /// socket (the lamp housing's rhyme), cut to the skull so it never leaves it.
  static final _frames = () {
    final raw = Path();
    for (final (c, r) in [(eyeFar, eyeFarRadius + .30), (eyeNear, eyeNearRadius + .30)]) {
      raw.addPath(GargoyleKit.octagon(r), c);
    }
    return Path.combine(PathOperation.intersect, raw, _skull);
  }();

  /// Lens sockets (octagons, the lamp housing's rhyme) and rings.
  static final _sockets = () {
    final p = Path();
    for (final (c, r) in [(eyeFar, eyeFarRadius + .14), (eyeNear, eyeNearRadius + .15)]) {
      p.addPath(GargoyleKit.octagon(r), c);
    }
    return p;
  }();
  static final _rings = Path()
    ..addOval(Rect.fromCircle(center: eyeFar, radius: eyeFarRadius + ringFar))
    ..addOval(Rect.fromCircle(center: eyeNear, radius: eyeNearRadius + ringNear));
  static final _ringLit = Path()
    ..addArc(Rect.fromCircle(center: eyeFar, radius: eyeFarRadius + ringFar * .5), -1.25, 1.1)
    ..addArc(Rect.fromCircle(center: eyeNear, radius: eyeNearRadius + ringNear * .5), -1.25, 1.1);
  static final _ringShade = Path()
    ..addArc(Rect.fromCircle(center: eyeFar, radius: eyeFarRadius + ringFar * .5), 1.7, 1.3)
    ..addArc(Rect.fromCircle(center: eyeNear, radius: eyeNearRadius + ringNear * .5), 1.7, 1.3);
  static final _fresnel = Path()
    ..addOval(Rect.fromCircle(center: eyeFar, radius: eyeFarRadius * .72))
    ..addOval(Rect.fromCircle(center: eyeNear, radius: eyeNearRadius * .72));
  static final _glint = Path()
    ..addOval(Rect.fromCenter(center: eyeFar + const Offset(.10, .0), width: .07, height: .13))
    ..addOval(Rect.fromCenter(center: eyeNear + const Offset(.15, .02), width: .09, height: .17));

  /// Verdigris: a few streaks running from the brass (the lens rings, the
  /// cere), each ending in a round drop.
  static final _drips = () {
    final p = Path();
    void drip(double x, double y, double len) => p
      ..moveTo(x - .028, y)
      ..lineTo(x + .028, y)
      ..quadraticBezierTo(x + .02, y + len * .6, x, y + len)
      ..quadraticBezierTo(x - .02, y + len * .6, x - .028, y)
      ..close();
    drip(-2.52, -1.96, .17);
    drip(-2.31, -1.97, .09);
    drip(-3.14, -2.43, .18);
    drip(-1.64, -2.29, .09);
    return p;
  }();

  /// The seams the wake opens, from the lens rims: the first group at any
  /// crack, the second as it deepens.
  static final _seamsA = Path()
    ..moveTo(-2.68, -2.12)
    ..lineTo(-2.82, -1.96)
    ..lineTo(-2.72, -1.82)
    ..lineTo(-2.86, -1.66)
    ..moveTo(-2.24, -2.02)
    ..lineTo(-2.12, -1.88)
    ..lineTo(-2.24, -1.76)
    ..lineTo(-2.08, -1.62)
    ..moveTo(-1.34, -2.46)
    ..lineTo(-1.18, -2.34)
    ..lineTo(-1.28, -2.18)
    ..lineTo(-1.04, -2.02);
  static final _seamsB = Path()
    ..moveTo(-2.14, -2.66)
    ..lineTo(-1.96, -2.52)
    ..lineTo(-2.04, -2.38)
    ..moveTo(-1.80, -2.50)
    ..lineTo(-1.70, -2.36)
    ..lineTo(-1.82, -2.26)
    ..moveTo(-1.0, -2.6)
    ..lineTo(-.88, -2.48)
    ..lineTo(-.98, -2.36);

  // ------------------------------------------------------ the brow hoods --

  /// How far the hoods sit below their drawn position for a `brow` of [brow]:
  /// the layout's [GargoyleLayout.visorDrop], but a relaxed brow lifts the
  /// hoods up to .07 so the idle eyes are awake and not half asleep under a
  /// flat plate; at full scowl it is the layout's drop exactly (the scowl's
  /// slope, its inner end and its full drop are untouched).
  static double hoodDrop(double brow) {
    final b = brow.clamp(0.0, 1.0);
    return math.max(GargoyleLayout.visorDrop(b) - .07 * math.pow(1 - b, 1.3), -.04);
  }

  /// The near hood's lower edge, head-local, for a `brow` channel of [brow]:
  /// from the inner end (toward the crest) to the front tip (over the beak's
  /// root). Its slope is 30 degrees down toward the beak (the gate is 25).
  static ({Offset inner, Offset outer}) visorEdge(double brow) {
    final d = hoodDrop(brow);
    return (inner: Offset(-1.70, -2.92 + d), outer: Offset(-3.05, -2.92 + d + 1.35 * _slope));
  }

  /// The share of the near lens the hood covers along the lens' vertical
  /// diameter (0 .. 1) at [brow]: the gate is >= .25 at rest, never all.
  static double nearLensCover(double brow) {
    final e = visorEdge(brow);
    final t = (eyeNear.dx - e.inner.dx) / (e.outer.dx - e.inner.dx);
    final y = e.inner.dy + (e.outer.dy - e.inner.dy) * t;
    return ((y - (eyeNear.dy - eyeNearRadius)) / (2 * eyeNearRadius)).clamp(0.0, 1.0);
  }

  /// tan(30 degrees): the scowl.
  static const _slope = 0.5773502691896257;

  /// The near hood for a drop of [d]: a dagger wedge, thin at the crest end,
  /// heavy and pointed over the beak's root, its top edge stepped like a
  /// setback tower (every tread stays under the layout's reference line).
  static Path _nearHood(double d) => _poly([
    -3.05, -2.92 + d + 1.35 * _slope, -2.80, -2.70, -2.70, -2.70, -2.70, -2.84, -2.30, -2.84, -2.30, -2.93, -1.90, -2.93, -1.90, -3.02, //
    -1.58, -3.02, -1.58, -3.06, -1.54, -2.92 - .16 * _slope + d,
  ]);

  /// The sky's light along the hoods' stepped upper edges.
  static final _hoodTop = Path()
    ..moveTo(-2.76, -2.645)
    ..lineTo(-2.73, -2.645)
    ..moveTo(-2.66, -2.785)
    ..lineTo(-2.33, -2.785)
    ..moveTo(-2.26, -2.875)
    ..lineTo(-1.93, -2.875)
    ..moveTo(-1.86, -2.965)
    ..lineTo(-1.62, -2.965)
    ..moveTo(-1.82, -2.845)
    ..lineTo(-1.64, -2.845)
    ..moveTo(-1.56, -2.945)
    ..lineTo(-1.29, -2.945)
    ..moveTo(-1.21, -3.045)
    ..lineTo(-1.10, -3.045)
    ..moveTo(-2.80, -2.50)
    ..lineTo(-2.52, -2.67)
    ..moveTo(-2.44, -2.71)
    ..lineTo(-2.44, -2.71);

  /// The far hood for a drop of [d] (seventh tenths of the near's).
  static Path _farHood(double d) => _poly([
    -1.98, -2.50 + d, -1.86, -2.90, -1.60, -2.90, -1.60, -3.00, -1.25, -3.00, -1.25, -3.10, -1.06, -3.10, -1.06, -2.94 + d,
  ]);

  // -------------------------------------------------------------- paints --

  static Paint _skullPaint() => GargoyleKit.cached(
    'head.skull',
    () => GargoyleKit.linear(
      const Offset(-1.0, -3.1),
      const Offset(-1.9, -1.25),
      const [GargoylePalette.limeSheen, GargoylePalette.limeLit, GargoylePalette.lime, shadeViolet],
      const [0, .26, .5, .8],
    ),
  );

  /// ONE steel gradient across the whole head (crest, hoods, beak, jaw): light
  /// where the sky reaches, deep in the jaw.
  static Paint _steelPaint() => GargoyleKit.cached(
    'head.steel',
    () => GargoyleKit.linear(
      const Offset(-2.6, -3.3),
      const Offset(-3.0, -1.1),
      const [GargoylePalette.steel, GargoylePalette.steelMid, GargoylePalette.steelDeep, GargoylePalette.steelCore],
      const [0, .3, .72, 1],
    ),
  );

  /// The lens glass: a unit radial (drawn under a transform per lens).
  static Paint _glassPaint() => GargoyleKit.cached(
    'head.glass',
    () => GargoyleKit.radial(
      Offset.zero,
      1,
      const [GargoylePalette.lampCore, GargoylePalette.lampWarm, GargoylePalette.lampAmber, GargoylePalette.lampDeep],
      const [0, .28, .62, 1],
    ),
  );

  // -------------------------------------------------------------- helpers --

  static double _f(double v, double lo, double hi, [double fallback = 0]) =>
      v.isFinite ? v.clamp(lo, hi).toDouble() : fallback;

  static double _ramp(double v, double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

  static Paint _flat(GargoyleTone t, Color c, [double a = 1]) => GargoyleKit.fill(t.lit(c), a);
  static Paint _ln(GargoyleTone t, Color c, double w, [double a = 1]) => GargoyleKit.line(t.lit(c), w, a);

  // ---------------------------------------------------------------- paint --

  /// Paints the head in its own frame.
  static void paint(Canvas c, GargoyleHeadPose h) {
    final t = h.tone.snapped();
    final gape = _f(h.gape, 0, 1), flare = _f(h.flare, 0, 1, .3), brow = _f(h.brow, 0, 1, .3);
    final fury = _f(h.fury, 0, 1), crack = _f(h.crack, 0, 1), wince = _f(h.wince, 0, 1);
    final crumble = _f(h.crumble, 0, 1);
    final rawIris = _f(h.iris, 0, 1, 1);
    // The WINK: while he lives and moves, the idle blink closes the near lens
    // only (the far one barely flickers): a theatrical old stage actor. Stone,
    // the knock-out, a pose held still (a story's blink, Reduced Motion) and the
    // wince close both lenses together.
    final wink = h.time > 0 && !h.defeated && t.stone <= 0;
    final irisFar = wink ? 1 - (1 - rawIris) * .15 : rawIris;
    final iris = rawIris * (1 - .85 * wince);
    final irisFarNow = irisFar * (1 - .85 * wince);
    final hot = math.max(flare, fury * .8);
    // Derived looks: the pleased squint of the vent (beak open, lamps low) and
    // the slanted slit of a wince.
    final smug = (_ramp(gape, .22, .5) * (1 - _ramp(flare, .25, .38)) * (h.defeated ? 0 : 1)).clamp(0.0, 1.0);

    _skullPaint2(c, t);
    if (crumble > 0) {
      // The stone gives way: the crest droops off the crown.
      c.save();
      c.translate(-1.2 + crumble * .12, -2.9 + crumble * .45);
      c.rotate(crumble * .35);
      c.translate(1.2, 2.9);
      _crestPaint(c, t);
      c.restore();
    } else {
      _crestPaint(c, t);
    }
    // The mouth: a dark interior between the beak's edge and the hanging jaw.
    final open = gape * .5;
    if (gape > .02) _mouth(c, t, open, gape);
    _jawPaint(c, t, open + crumble * .35);
    _beakPaint(c, t);
    // The lenses sit in their sockets behind the hoods.
    _lenses(c, t, hot: hot, fury: fury, iris: iris, irisFar: irisFarNow, defeated: h.defeated, tilt: -.5 * wince, smug: smug);
    if (crack > 0) _seams(c, t, crack);
    if (h.visor) _hoods(c, t, brow, hot, fury, arch: .07 * math.pow(1 - brow, 1.5).toDouble());
    if (h.time > 0 && t.stone > 0 && t.stone < 1) _grit(c, t, h.time);
  }

  // ---- crest ----------------------------------------------------------

  static void _crestPaint(Canvas c, GargoyleTone t) {
    c.drawPath(_crest, GargoyleKit.toned(_steelPaint(), t));
    c.drawPath(_crest, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(_crestShine, _ln(t, GargoylePalette.steelLit, .04, .9));
    // The moon's edge on the crest's upper side (no clip: a line along it).
    c.drawPath(_crestShine, _ln(t, t.sky, .03, t.moonRim * .7));
  }

  // ---- skull ----------------------------------------------------------

  static void _skullPaint2(Canvas c, GargoyleTone t) {
    c.drawPath(_skull, GargoyleKit.toned(_skullPaint(), t));
    c.drawPath(_planeTemple, _flat(t, GargoylePalette.limeSheen, .45));
    c.drawPath(_planesShade, _flat(t, shadeViolet, .4));
    c.drawPath(_frames, _flat(t, GargoylePalette.limeShade, .42));
    c.drawPath(_frames, _ln(t, GargoylePalette.inkWarm, .03, .55));
    c.drawPath(_bands, _ln(t, shadeViolet, .035, .8));
    c.drawPath(_stoneGloss, _ln(t, GargoylePalette.lampCore, .05, .55));
    c.drawPath(_stoneRim, _ln(t, t.sky, .06, t.moonRim * .6));
    c.drawPath(_crease, GargoyleKit.line(GargoylePalette.ink, .045, .85));
    c.drawPath(_hatch, _ln(t, GargoylePalette.limeDeep, .028, .4));
    GargoyleKit.edge(c, _skull, t, width: .12);
    GargoyleKit.inkHero(c, _skull);
  }

  // ---- mouth and jaw ----------------------------------------------------

  static Offset _turnAbout(Offset p, Offset pivot, double angle) {
    final v = p - pivot;
    final cs = math.cos(angle), sn = math.sin(angle);
    return pivot + Offset(v.dx * cs - v.dy * sn, v.dx * sn + v.dy * cs);
  }

  static void _mouth(Canvas c, GargoyleTone t, double open, double gape) {
    final hinge = GargoyleLayout.jawHinge;
    final a = -open;
    // The beak's cutting edge from the gape corner to the hook, then the jaw's
    // upper edge (turned) back: the space between them is the open mouth.
    final pts = <Offset>[
      _at(_beakPts, 10), _at(_beakPts, 9), _at(_beakPts, 8), _at(_beakPts, 7), _at(_beakPts, _hookAt),
      _turnAbout(_at(_jawPts, 4), hinge, a), _turnAbout(_at(_jawPts, 3), hinge, a), _turnAbout(_at(_jawPts, 2), hinge, a),
      _turnAbout(_at(_jawPts, 1), hinge, a),
    ];
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    p.close();
    c.drawPath(p, GargoyleKit.fill(mouthColor));
    // A warm throat: his lamp behind it.
    c.drawPath(p, _flat(t, GargoylePalette.lampDeep, ((.15 + .5 * gape) * t.lampFill * 1.3).clamp(0.0, .8)));
    // The furnace deep in the throat: a smaller, hotter shape inside it.
    final mid = pts.fold(Offset.zero, (a, b) => a + b) / pts.length.toDouble();
    final inner = Path()..moveTo(mid.dx + (pts.first.dx - mid.dx) * .55, mid.dy + (pts.first.dy - mid.dy) * .55);
    for (final q in pts.skip(1)) {
      inner.lineTo(mid.dx + (q.dx - mid.dx) * .55, mid.dy + (q.dy - mid.dy) * .55);
    }
    inner.close();
    c.drawPath(inner, _flat(t, GargoylePalette.lampAmber, (gape * t.lampFill * 1.1).clamp(0.0, .7)));
  }

  static void _jawPaint(Canvas c, GargoyleTone t, double open) {
    final hinge = GargoyleLayout.jawHinge;
    c.save();
    c.translate(hinge.dx, hinge.dy);
    c.rotate(-open);
    c.translate(-hinge.dx, -hinge.dy);
    c.drawPath(_jaw, GargoyleKit.toned(_steelPaint(), t));
    c.drawPath(_jawShade, _flat(t, GargoylePalette.steelCore, .5));
    c.drawPath(_jawLine, _ln(t, GargoylePalette.steelCore, .03, .7));
    c.drawPath(_jaw, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.restore();
  }

  // ---- beak -------------------------------------------------------------

  static void _beakPaint(Canvas c, GargoyleTone t) {
    c.drawPath(_beak, GargoyleKit.toned(_steelPaint(), t));
    c.drawPath(_beakLit, _flat(t, GargoylePalette.steelLit, .38));
    c.drawPath(_beakShade, _flat(t, GargoylePalette.steelCore, .55));
    c.drawPath(_culmen, _ln(t, GargoylePalette.steelLit, .05, .95));
    GargoyleKit.edge(c, _beak, t, width: .09);
    c.drawPath(_beak, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    // The cere: a brass plate over the beak's root, the nostril in it.
    c.drawPath(_cere, _flat(t, GargoylePalette.brass));
    c.drawPath(_cereShade, _flat(t, GargoylePalette.brassDeep));
    c.drawPath(_cere, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkDetail));
    c.drawPath(_nostril, GargoyleKit.fill(GargoylePalette.ink));
  }

  // ---- lenses -----------------------------------------------------------

  /// A cap of the lens disc above (or below) the chord at [dy] from its
  /// centre, the chord bowed by [bulge] (toward the lens' middle when
  /// positive), the whole cap turned by [tilt] about the centre.
  static void _cap(Path into, Offset ctr, double r, double dy, {required bool above, double bulge = 0, double tilt = 0}) {
    if (above ? dy <= -r : dy >= r) return;
    final v = (dy / r).clamp(-1.0, 1.0);
    final sv = math.asin(v);
    final w = r * math.cos(sv);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final p = Path();
    if (above) {
      p
        ..moveTo(-w, dy)
        ..arcTo(rect, math.pi - sv, math.pi + 2 * sv, false)
        ..quadraticBezierTo(0, dy + bulge * 2, -w, dy)
        ..close();
    } else {
      p
        ..moveTo(w, dy)
        ..arcTo(rect, sv, math.pi - 2 * sv, false)
        ..quadraticBezierTo(0, dy - bulge * 2, w, dy)
        ..close();
    }
    final cs = math.cos(tilt), sn = math.sin(tilt);
    into.addPath(
      p,
      ctr,
      matrix4: Float64List.fromList([cs, sn, 0, 0, -sn, cs, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
    );
  }

  /// The steel lids of a lens at aperture [iris]: the upper lid does most of the
  /// closing (65%), the lower lid rises the rest; shut they meet a little below
  /// the centre. [tilt] slants the slit (a wince); [smug] lifts the lower lid
  /// in a bowed curve (the pleased squint of the vent). [into] collects both
  /// lids of every lens (one path, one op).
  static void _lids(Path into, Offset ctr, double r, double iris, {double tilt = 0, double smug = 0}) {
    final k = 1 - iris;
    if (k <= .005 && smug <= .01) return;
    _cap(into, ctr, r, -r + 2 * r * k * .65, above: true, bulge: r * .04, tilt: tilt);
    _cap(into, ctr, r, r - 2 * r * (k * .35 + .2 * smug), above: false, bulge: r * (.04 + .12 * smug), tilt: tilt);
  }

  static void _lenses(
    Canvas c,
    GargoyleTone t, {
    required double hot,
    required double fury,
    required double iris,
    required double irisFar,
    required bool defeated,
    required double tilt,
    required double smug,
  }) {
    c.drawPath(_sockets, _flat(t, GargoylePalette.limeCore, .92));
    c.drawPath(_rings, _flat(t, GargoylePalette.brass));
    c.drawPath(_ringShade, _ln(t, GargoylePalette.brassShade, .05));
    c.drawPath(_ringLit, _ln(t, GargoylePalette.brassLit, .035));
    c.drawPath(_rings, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    for (final (ctr, r) in [(eyeFar, eyeFarRadius), (eyeNear, eyeNearRadius)]) {
      c.save();
      c.translate(ctr.dx, ctr.dy);
      c.scale(r);
      c.drawCircle(Offset.zero, 1, GargoyleKit.toned(_glassPaint(), t));
      c.restore();
    }
    // Low lamp: a warm dark scrim over the glass (it never greys the amber).
    final dim = (1 - hot) * .5;
    if (dim > .02) {
      final scrim = Path()
        ..addOval(Rect.fromCircle(center: eyeFar, radius: eyeFarRadius))
        ..addOval(Rect.fromCircle(center: eyeNear, radius: eyeNearRadius));
      c.drawPath(scrim, GargoyleKit.fill(const Color(0xff4a2410), dim));
    }
    c.drawPath(_fresnel, _ln(t, GargoylePalette.brassDeep, .02, .45));
    // The white-hot core: it grows and whitens with the lamp.
    final core = Path()
      ..addOval(Rect.fromCircle(center: eyeFar, radius: eyeFarRadius * (.28 + .42 * hot)))
      ..addOval(Rect.fromCircle(center: eyeNear, radius: eyeNearRadius * (.28 + .42 * hot)));
    c.drawPath(core, _flat(t, fury > 0 ? GargoylePalette.arcCore : GargoylePalette.lampCore, .3 + .7 * hot));
    c.drawPath(_glint, GargoyleKit.fill(GargoylePalette.white, .92));
    // Steel lids close the lens (a blink, a wince, the knock-out).
    if (iris < .995 || irisFar < .995 || smug > .01) {
      final lids = Path();
      _lids(lids, eyeFar, eyeFarRadius, defeated ? iris * .6 : irisFar, tilt: tilt, smug: smug);
      _lids(lids, eyeNear, eyeNearRadius, iris, tilt: tilt, smug: smug);
      c.drawPath(lids, _flat(t, GargoylePalette.steelMid));
      c.drawPath(lids, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkDetail));
    }
    c.drawPath(_drips, _flat(t, GargoylePalette.vd));
    final halo = t.stone > .5 ? 0.0 : .05 + .40 * hot * hot;
    GargoyleKit.glow(c, eyeFar, eyeFarRadius * 3.5, GargoylePalette.lampWarm, halo);
    GargoyleKit.glow(c, eyeNear, eyeNearRadius * 3.5, GargoylePalette.lampWarm, halo);
  }

  // ---- cracks -----------------------------------------------------------

  /// A hot seam: dark edge, amber body, white-hot core (arc-white in fury). A
  /// crack OPENS (its width grows with [crack]); it is never a half-faded
  /// ribbon, which only ever read as mud on the stone.
  static void _seam(Canvas c, GargoyleTone t, Path p, double a, double w) {
    c.drawPath(p, GargoyleKit.line(GargoylePalette.ink, w * 2.4, a * .85));
    c.drawPath(p, GargoyleKit.line(t.crackEdge, w * 1.5, a));
    c.drawPath(p, GargoyleKit.line(t.crackCore, w * .6, a));
  }

  static void _seams(Canvas c, GargoyleTone t, double crack) {
    final w = .026 + .02 * crack;
    _seam(c, t, _seamsA, (crack * 5).clamp(0.0, 1.0), w);
    if (crack > .45) _seam(c, t, _seamsB, ((crack - .45) * 6).clamp(0.0, 1.0), w);
  }

  // ---- hoods ------------------------------------------------------------

  /// [arch] lifts the far hood (an arched eyebrow) while the brow is relaxed.
  static void _hoods(Canvas c, GargoyleTone t, double brow, double hot, double fury, {double arch = 0}) {
    final d = hoodDrop(brow);
    final far = _farHood(d * .7 - arch), near = _nearHood(d);
    final e = visorEdge(brow);
    // The contact shadow the near hood throws on the lens (it widens with the scowl).
    c.drawLine(e.inner, e.outer, GargoyleKit.line(GargoylePalette.limeCore, .035 + .12 * brow, .4));
    c.drawPath(far, GargoyleKit.toned(_steelPaint(), t));
    c.drawPath(far, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(near, GargoyleKit.toned(_steelPaint(), t));
    // The chamfer along the scowl, in shade; rivets in the plate; the upper
    // edge's sky light.
    final up = const Offset(0, -.11);
    c.drawPath(_poly([e.outer.dx, e.outer.dy, e.inner.dx, e.inner.dy, e.inner.dx, e.inner.dy + up.dy, e.outer.dx, e.outer.dy + up.dy]), _flat(t, GargoylePalette.steelCore, .42));
    c.drawPath(near, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(_hoodTop, _ln(t, GargoylePalette.steelLit, .03, .85));
    c.drawPoints(
      PointMode.points,
      [Offset(-2.62, -2.58 + d * .5), Offset(-2.22, -2.76 + d * .3)],
      GargoyleKit.line(t.lit(GargoylePalette.brassLit), .065),
    );
    // Brass trim along the scowl: it heats with the lenses.
    final trim = Color.lerp(GargoylePalette.brass, fury > 0 ? GargoylePalette.arcEdge : GargoylePalette.lampWarm, (hot * .55).clamp(0.0, 1.0))!;
    c.drawLine(e.inner + const Offset(0, -.05), e.outer + const Offset(.04, -.06), _ln(t, trim, .035 + .01 * hot));
  }

  // ---- grit -------------------------------------------------------------

  static void _grit(Canvas c, GargoyleTone t, double time) {
    final pts = <Offset>[];
    final k = (time - 1.6).clamp(0.0, 1.2);
    for (var i = 0; i < 9; i++) {
      final hx = GargoyleKit.hash(i), hy = GargoyleKit.hash(i, 3);
      pts.add(Offset(-3.0 + hx * 2.3, -2.9 + hy * .5 + k * (.5 + hx * .6)));
    }
    c.drawPoints(PointMode.points, pts, GargoyleKit.line(GargoylePalette.dust, .07, .7 * (1 - k / 1.2)));
  }

  // ------------------------------------------------------ the loose hood --

  static final _hoodLoose = _nearHood(GargoyleLayout.visorDrop(.3)).shift(-GargoyleLayout.visorSeat);

  /// The near visor on its own, seated at its anchor's origin
  /// ([GargoyleLayout.visorSeat]): what the defeat knocks loose (a tumbling
  /// piece of headwear) and the keepsake shows.
  static void visorPaint(Canvas c, [GargoyleTone tone = const GargoyleTone()]) {
    final t = tone.snapped();
    c.drawPath(_hoodLoose, _flat(t, GargoylePalette.steelMid));
    c.drawPath(_hoodLoose, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
  }
}
