import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// The Ember Dragon's palette: obsidian-plum scales lit from within by
/// molten seams, a banded amber belly, back-lit crimson wing membranes with
/// bone spars, bone horns and claws, and a gold circlet.
///
/// The scale ramp shifts hue as it darkens (indigo in the creases, plum in
/// the body, mauve on the crests) so form reads without the ink. Values
/// (CIE L*) are the contract: ink 6, creases 10, shade 13-20, body 29, crest
/// 45, sheen 66; membrane lit half at least 50 (15 above the body); bone
/// 55-76 with ridges and tips at most 90; eye, gem and fire 90+.
abstract final class DragonPalette {
  /// The outer contour. Inner lines use [inkCool] on scales and [inkWarm] on
  /// belly, membrane and gold, so no line is a flat black hole.
  static const ink = Color(0xff181020);
  static const inkCool = Color(0xff151935), inkWarm = Color(0xff3a1226);

  // Scales, from a plate's specular ridge down into its crease.
  static const scaleSheen = Color(0xffce8cb8), scaleLit = Color(0xff8b5890);
  static const scale = Color(0xff53396a), scaleDeep = Color(0xff342a52);
  static const scaleDark = Color(0xff201e3d), scaleCore = Color(0xff151935);

  // The same plates when fury has heated them: oxblood iron.
  static const furyPlate = Color(0xff671f33), furyPlateLit = Color(0xffb14348);

  // The belly's banded plates. Round 2 (colour review D5): the ramp comes
  // down to L* 80 / 68 / 50 (was 88 / 74 / 55) so the belly is no longer the
  // largest bright shape on the body and the face and the heart outrank it.
  static const bellyLit = Color(0xfff6bb6c), belly = Color(0xffe8903f);
  static const bellyDeep = Color(0xffc05a30), bellyDark = Color(0xff893e2d);

  // Wing membranes: fire seen through skin. Glowing beside the bones,
  // crimson between, a dark saturated hem.
  static const membraneGlow = Color(0xffffa25a);
  static const membraneLit = Color(0xffff6d41), membrane = Color(0xffe33d46);
  static const membraneDeep = Color(0xffa82349),
      membraneDark = Color(0xff6a1a3c);

  // Bone: horns, claws, teeth and spines. Mid-toned, so only ridges and
  // tips are bright and the face outranks the horns.
  static const boneLit = Color(0xfff1e1c0), bone = Color(0xffd4b790);
  static const boneDeep = Color(0xffa57b5d), boneShade = Color(0xff74494a);
  static const boneTip = Color(0xff5b3e4d);

  // Fire, from the smoky outer lick to the white-hot heart.
  static const soot = Color(0xff3a1d2a), flameDark = Color(0xffb32a3a);
  static const flame = Color(0xffff6a2a), flameGold = Color(0xffffb23c);
  static const flameYellow = Color(0xffffe066), flameCore = Color(0xfffff6d2);

  // Molten seams between the plates.
  static const seam = Color(0xffff7a2e), seamHot = Color(0xffffcf5a);

  // The circlet.
  static const gold = Color(0xfff6be4b), goldLit = Color(0xfffbebae);
  static const goldDeep = Color(0xffbd7233), goldShade = Color(0xff88482b);
  static const ruby = Color(0xffe0304a), rubyDeep = Color(0xff8a1230);
  static const rubyLit = Color(0xffff8a9a);

  // Rim lights: the sky's bounce (tinted per backdrop by DragonSkyLight)
  // and the fire's own.
  static const rimSky = Color(0xffa4afde), rimFire = Color(0xffff8e4c);

  // The swarm call is cool where the breath is hot: it never reads as fire.
  static const call = Color(0xffb9a4ff), callDeep = Color(0xff4a2f9a);

  // Smoke and ash.
  static const ash = Color(0xff4b3346), smoke = Color(0xffd6cad6);

  static const white = Color(0xffffffff);
}

/// How the sky lights the dragon right now: [dark] is 0 for a bright sky and
/// 1 for night, [sky] the colour of the bounce light on its upper edges.
///
/// Both are pure functions of the backdrop's palette at the flight clock, so
/// they are deterministic and Reduced Motion needs no special case.
final class DragonSkyLight {
  const DragonSkyLight({this.dark = 0, this.sky = DragonPalette.rimSky});

  /// Sky at [top] and [horizon] with mist colour [haze]: the average
  /// luminance decides how dark it is (0 above .34, 1 below .04) and the haze
  /// tints the rim so it reads as that region's own bounce light.
  factory DragonSkyLight.fromSky({
    required Color top,
    required Color horizon,
    required Color haze,
  }) {
    final lum = (top.computeLuminance() + horizon.computeLuminance()) / 2;
    return DragonSkyLight(
      dark: 1 - ((lum - .04) / .3).clamp(0.0, 1.0),
      sky: Color.lerp(haze, DragonPalette.rimSky, .5)!,
    );
  }

  static const neutral = DragonSkyLight();
  final double dark;
  final Color sky;
}

/// How the dragon is lit right now, shared by every part of it.
///
/// [flash] bleaches fills toward cream after a hit (lights further than
/// darks, so form survives while the ink holds), [fury] heats every plate,
/// seam and membrane, and [heat] is the fire rising inside it while it
/// charges or inhales. [dark] and [sky] are the backdrop's light.
final class DragonTone {
  const DragonTone({
    this.flash = 0,
    this.fury = 0,
    this.heat = 0,
    this.dark = 0,
    this.sky = DragonPalette.rimSky,
  });
  final double flash, fury, heat, dark;
  final Color sky;

  /// A fill colour under the hit flash: it goes near-white (toward
  /// [DragonPalette.flameCore], at up to .95 of the way at the peak) so it
  /// reads on every sky, pale ones included; the ink holds and lighter
  /// colours flash a little further, so the scales keep their form. (Round 2,
  /// colour review D2: the old bone-cream target at .6 x flash left a lilac
  /// grey petrify.)
  Color lit(Color color) {
    if (flash <= 0) return color;
    final w = flash * 1.8 * (.8 + .2 * math.sqrt(color.computeLuminance()));
    return Color.lerp(color, DragonPalette.flameCore, w.clamp(0.0, .95))!;
  }

  /// A scale-plate colour: plum, heated toward oxblood iron by fury and, on a
  /// dusk or dark sky, deeper toward the crease colour (by [depth] of the way:
  /// the plum body drops from L* 28 to about 17 on the darkest) so it
  /// separates from violet and dark backdrops. A darker value, not a greyer
  /// one: the hue stays saturated and the glints stay bright. (Round 2, colour
  /// review D1.)
  Color plate(Color color) {
    var c = color;
    final deeper = depth;
    if (deeper > 0) c = Color.lerp(c, DragonPalette.scaleCore, deeper)!;
    if (fury > 0) {
      c = Color.lerp(c, _heated(c), (fury * .85).clamp(0.0, 1.0))!;
    }
    return lit(c);
  }

  /// How far a plate goes toward the crease colour on this sky: nothing on a
  /// bright one, .4 at a third of the way to dark (Paris is .41, Mexico .26),
  /// .62 from two thirds (New York, cyberpunk). The sky's darkness reaches the
  /// parts in thirds ([snapped]), so these are the three values there are.
  /// (Round 3: the old line, (dark - .25) * 2.2 from a quarter, was written
  /// for the raw darkness; the review's "formula" started at .5 and left Paris
  /// within 10 L* of its sky.)
  double get depth => (dark * 1.2).clamp(0.0, .62);

  /// A plate at full fury: from oxblood iron ([DragonPalette.furyPlate]) up to
  /// the lit iron by the plate's own value, so fury reads as a change of the
  /// body, not a darker aubergine. (Round 2, colour review D3.)
  static Color _heated(Color c) {
    final y = c.computeLuminance();
    return Color.lerp(
      DragonPalette.furyPlate,
      DragonPalette.furyPlateLit,
      (math.sqrt(y) * 1.25).clamp(0.0, 1.0),
    )!;
  }

  /// A fill colour that burns from [calm] to [burning] with fury.
  Color burn(Color calm, Color burning) =>
      lit(fury <= 0 ? calm : Color.lerp(calm, burning, fury)!);

  /// How brightly the molten seams glow, 0 to 1. Even at rest they glow
  /// (.5, was .35): a lit-from-within seam, not a brown crack. (Round 2,
  /// colour review D4.)
  double get glow => (.5 + fury * .5 + heat * .5).clamp(0.0, 1.0);

  /// The seams' colour at [glow]: a fifth of the way to white-hot at rest.
  Color get seam => Color.lerp(
    DragonPalette.seam,
    DragonPalette.seamHot,
    (.2 + fury * .5 + heat * .5).clamp(0.0, 1.0),
  )!;

  /// The sky rim's strength: stronger against dark skies, weaker in fury
  /// (the dragon's own fire takes over).
  double get skyRim => ((.55 + dark * .4) * (1 - fury * .6)).clamp(0.0, 1.0);

  /// The fire rim's strength on undersides.
  double get fireRim => (.3 + glow * .5 + fury * .2).clamp(0.0, 1.0);

  /// How many steps each channel has on the ladder [snapped] puts a tone on:
  /// flash, fury and heat in quarters, the sky's darkness in thirds. A
  /// channel never has more steps than the COARSEST cache key any part uses
  /// on it (the head keys the flash in fifths and sixths, the fury in
  /// quarters to eighths, the heat in quarters and sixths, the darkness in
  /// thirds to eighths), so two tones on the ladder never share a bucket of
  /// any part's cache: whichever tone a part built a paint from, it is the
  /// one the bucket names.
  static const flashSteps = 4, furySteps = 4, heatSteps = 4, darkSteps = 3;

  /// This tone on that ladder (and the sky colour on its 5-bit steps, the
  /// hide's own key for it).
  ///
  /// The parts keep their gradients between frames under [key]. A gradient
  /// built from the raw tone of whichever frame came first gave the same
  /// state different pixels depending on what had been drawn before it (the
  /// final QA found 6 to 8 of 45 states differing by up to 7/255); built from
  /// THIS, it is the same whichever frame builds it. `DragonPose.tone` is
  /// always snapped, so the fills and the shaders agree, and the prewarm's
  /// ladders (which are snapped) build the very paints a live frame would.
  DragonTone snapped() => DragonTone(
    flash: _snap(flash, flashSteps),
    fury: _snap(fury, furySteps),
    heat: _snap(heat, heatSteps),
    dark: _snap(dark, darkSteps),
    sky: Color(sky.toARGB32() & 0xfff8f8f8),
  );

  /// This tone moved [flash], [fury], [heat] and [dark] steps along the
  /// ladder (clamped to 0..1), for the prewarm.
  DragonTone stepped({
    int flash = 0,
    int fury = 0,
    int heat = 0,
    int dark = 0,
  }) {
    double at(double v, int steps, int by) =>
        ((_snap(v, steps) * steps).round() + by).clamp(0, steps) / steps;
    return DragonTone(
      flash: at(this.flash, flashSteps, flash),
      fury: at(this.fury, furySteps, fury),
      heat: at(this.heat, heatSteps, heat),
      dark: at(this.dark, darkSteps, dark),
      sky: Color(sky.toARGB32() & 0xfff8f8f8),
    );
  }

  static double _snap(double v, int steps) =>
      v.isFinite ? (v * steps).round() / steps : 0;

  /// Quantised (1/8 steps; a snapped tone sits on every other one) so per-tone
  /// caches stay small.
  int get key => Object.hash(
    (flash * 8).round(),
    (fury * 8).round(),
    (heat * 8).round(),
    (dark * 4).round(),
  );
}

/// Paints, gradients and path builders shared by the Ember Dragon's parts.
abstract final class DragonKit {
  static Paint fill(Color color, [double alpha = 1]) => Paint()
    ..color = alpha >= 1
        ? color
        : color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));
  static Paint line(Color color, double width, [double alpha = 1]) =>
      fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  /// Diagnostic only: gradient shaders built through [linear] and [radial]
  /// (and so [glow]). `dragon_budget_test.dart` reads it to hold the
  /// per-frame budget of new shaders; it never influences a pixel.
  static int shadersBuilt = 0;

  static Paint linear(
    Offset from,
    Offset to,
    List<Color> colors, [
    List<double>? stops,
  ]) {
    shadersBuilt++;
    return Paint()
      ..shader = ui.Gradient.linear(from, to, colors, stops ?? _even(colors));
  }

  static Paint radial(
    Offset center,
    double radius,
    List<Color> colors, [
    List<double>? stops,
  ]) {
    shadersBuilt++;
    return Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        colors,
        stops ?? _even(colors),
      );
  }

  static List<double>? _even(List<Color> colors) => colors.length == 2
      ? null
      : [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];

  static final Map<int, ui.Shader> _glows = {};

  /// A soft round glow of [color] fading out from [alpha].
  ///
  /// The gradient is built once per colour, in unit space, and drawn under a
  /// transform with the alpha on the paint, so a glow costs no shader build
  /// per frame (every part that glows benefits, unchanged).
  static void glow(
    Canvas c,
    Offset at,
    double radius,
    Color color,
    double alpha,
  ) {
    if (alpha <= 0 || radius <= 0) return;
    // The colour on 5-bit steps (round 3: a caller that lerps its colour every
    // frame built a shader per frame, 700 to 1000 a cycle in the QA soak);
    // the shader is a pure function of the stepped colour, at most 7/255 from
    // the asked one, and the map turns over oldest first, never all at once.
    final argb = color.toARGB32();
    final solid = Color(0xff000000 | ((argb & 0xf8f8f8) | 0x040404));
    var shader = _glows.remove(solid.toARGB32());
    if (shader == null) {
      if (_glows.length >= 128) _glows.remove(_glows.keys.first);
      shadersBuilt++;
      shader = ui.Gradient.radial(
        Offset.zero,
        1,
        [solid, solid.withValues(alpha: .38), solid.withValues(alpha: 0)],
        const [0, .45, 1],
      );
    }
    _glows[solid.toARGB32()] = shader;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = shader
        ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0)),
    );
    c.restore();
  }

  /// A smooth curve through [pts] (Catmull-Rom as cubic Béziers). Vertices
  /// listed in [sharp] stay corners.
  static Path spline(
    List<Offset> pts, {
    bool closed = true,
    Set<int> sharp = const {},
    double tension = 1,
    Path? into,
  }) {
    final n = pts.length;
    Offset at(int i) => closed ? pts[(i % n + n) % n] : pts[i.clamp(0, n - 1)];
    final path = into ?? Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    final last = closed ? n : n - 1;
    for (var i = 0; i < last; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = sharp.contains((i % n + n) % n)
          ? p1
          : p1 + (p2 - p0) * (tension / 6);
      final c2 = sharp.contains(((i + 1) % n + n) % n)
          ? p2
          : p2 - (p3 - p1) * (tension / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed) path.close();
    return path;
  }

  /// Shading inside [path]: a lit rim on its upper-left edge and a shaded
  /// one on its lower-right, clipped to the shape.
  static void rim(
    Canvas c,
    Path path, {
    required Color light,
    required Color shade,
    double width = .12,
    double shift = .06,
    double alpha = .55,
    Offset toward = const Offset(-1, -1),
  }) {
    c.save();
    c.clipPath(path);
    final d = toward * shift;
    c.translate(-d.dx, -d.dy);
    c.drawPath(path, line(light, width, alpha));
    c.translate(d.dx * 2, d.dy * 2);
    c.drawPath(path, line(shade, width * 1.4, alpha * .8));
    c.restore();
  }

  /// Warm light bouncing up from below: a band of [color] inside the lower
  /// edge of [path], as if lit by the fire it carries.
  static void underglow(
    Canvas c,
    Path path,
    Color color, {
    double width = .16,
    double lift = .08,
    double alpha = .4,
  }) {
    if (alpha <= 0) return;
    c.save();
    c.clipPath(path);
    c.translate(0, -lift);
    c.drawPath(path, line(color, width, alpha));
    c.restore();
  }

  /// A deterministic 0..1 value for slot [i] and [salt].
  static double hash(int i, [int salt = 0]) =>
      ((i * 7919 + salt * 104729 + 13) * 2654435761 % 1000003) / 1000003;

  /// Linear blend of two numbers.
  static double mix(double a, double b, double t) => a + (b - a) * t;

  /// A point [t] of the way along a cubic Bézier.
  static Offset bezier(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }

  /// The tangent of that Bézier at [t] (not normalised).
  static Offset bezierTangent(
    Offset a,
    Offset b,
    Offset c,
    Offset d,
    double t,
  ) {
    final u = 1 - t;
    return (b - a) * (3 * u * u) +
        (c - b) * (6 * u * t) +
        (d - c) * (3 * t * t);
  }

  /// [v] turned by [angle] radians.
  static Offset turn(Offset v, double angle) {
    final cs = math.cos(angle), sn = math.sin(angle);
    return Offset(v.dx * cs - v.dy * sn, v.dx * sn + v.dy * cs);
  }

  /// The unit vector at [angle].
  static Offset heading(double angle) =>
      Offset(math.cos(angle), math.sin(angle));

  /// Unit length copy of [v], or zero.
  static Offset unit(Offset v) {
    final d = v.distance;
    return d == 0 ? Offset.zero : v / d;
  }

  /// A tapered tube along [spine], [widths] across at each point, as one
  /// closed outline: down one side and back up the other.
  static Path tube(List<Offset> spine, List<double> widths, {Path? into}) {
    final n = spine.length;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = spine[i == 0 ? 0 : i - 1], b = spine[i == n - 1 ? i : i + 1];
      final d = unit(b - a);
      final normal = Offset(-d.dy, d.dx);
      left.add(spine[i] + normal * (widths[i] / 2));
      right.add(spine[i] - normal * (widths[i] / 2));
    }
    return spline(
      [...left, ...right.reversed],
      sharp: {n - 1, n, 2 * n - 1, 0},
      into: into,
    );
  }

  // MERGED from the main tree (the other session's dragon_hide_art work, seen
  // at 06:50): additive helpers, kept verbatim so the integrator's overlay of
  // this kit does not break dragon_hide_art.dart / dragon_boss_rig.dart there.

  /// A tube like [tube] with rounded ends: one smooth closed outline with no
  /// corners, for limbs, the neck and the tail.
  static Path capsule(List<Offset> spine, List<double> widths) {
    final (left, right) = tubeEdges(spine, widths);
    final n = spine.length;
    final end = unit(spine[n - 1] - spine[n - 2]);
    final start = unit(spine[1] - spine[0]);
    return spline([
      ...left,
      spine[n - 1] + end * (widths[n - 1] * .5),
      ...right.reversed,
      spine[0] - start * (widths[0] * .5),
    ]);
  }

  /// The union of [paths] as one outline.
  static Path merge(List<Path> paths) {
    var out = paths.first;
    for (var i = 1; i < paths.length; i++) {
      out = combine(PathOperation.union, out, paths[i]);
    }
    return out;
  }

  static int fallbacks = 0; // PROBE-ONLY

  /// [Path.combine] that never throws: should the geometry defeat it for a
  /// frame, the two outlines are simply laid together, which fills the same.
  static Path combine(PathOperation op, Path a, Path b) {
    try {
      return Path.combine(op, a, b);
    } on StateError {
      fallbacks++;
      return switch (op) {
        PathOperation.union => Path.from(a)..addPath(b, Offset.zero),
        _ => a,
      };
    }
  }

  /// Everything outside [path] (within [bounds]), for clipping to it.
  static Path outside(
    Path path, [
    Rect bounds = const Rect.fromLTRB(-12, -12, 12, 12),
  ]) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(bounds)
    ..addPath(path, Offset.zero);

  /// A stroke of [color] that fades in from nothing at [from] to [alpha] at
  /// [to]: contours that melt into the body instead of ending on a seam.
  static Paint fade(
    Offset from,
    Offset to,
    Color color,
    double width, [
    double alpha = 1,
  ]) =>
      linear(from, to, [
          color.withValues(alpha: 0),
          color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0)),
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  /// The dragon's scaled hide, lit from above in rig space. Every part of
  /// the body shares it, so wherever two parts meet their fills match.
  static Paint skin(DragonTone tone) => linear(
    const Offset(-.9, -2.9),
    const Offset(.6, 1.3),
    [
      tone.lit(DragonPalette.scaleLit),
      tone.lit(DragonPalette.scale),
      tone.lit(DragonPalette.scaleDeep),
    ],
    const [0, .48, 1],
  );

  /// The two edges of the tube [tube] builds, for strokes along one side.
  static (List<Offset>, List<Offset>) tubeEdges(
    List<Offset> spine,
    List<double> widths,
  ) {
    final n = spine.length;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = spine[i == 0 ? 0 : i - 1], b = spine[i == n - 1 ? i : i + 1];
      final d = unit(b - a);
      final normal = Offset(-d.dy, d.dx);
      left.add(spine[i] + normal * (widths[i] / 2));
      right.add(spine[i] - normal * (widths[i] / 2));
    }
    return (left, right);
  }

  // ---------------------------------------------------------- the hide --
  // (B9: torso, neck, head, tail and near legs painted as one creature.)

  /// A ribbon along the polyline [pts], [widths] across at each point, as one
  /// smooth closed outline that comes to a point where a width is zero. A
  /// filled ribbon is a contour that can taper, which a stroke cannot: the
  /// hide's fine limb contours melt into the body with it.
  static Path ribbon(List<Offset> pts, List<double> widths, {Path? into}) {
    final n = pts.length;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = pts[i == 0 ? 0 : i - 1], b = pts[i == n - 1 ? i : i + 1];
      final d = unit(b - a);
      final normal = Offset(-d.dy, d.dx);
      left.add(pts[i] + normal * (widths[i] / 2));
      right.add(pts[i] - normal * (widths[i] / 2));
    }
    return spline(
      [...left, ...right.reversed],
      sharp: {0, n - 1, n, 2 * n - 1},
      into: into,
    );
  }

  /// [n] widths for a [ribbon] that swells from nothing to [peak] over the
  /// first [head] of its length and falls back to nothing over the last
  /// [tail] (both fractions, 0..1), so its ends melt into what it lies on.
  static List<double> taper(
    int n,
    double peak, {
    double head = .2,
    double tail = .2,
  }) => [
    for (var i = 0; i < n; i++)
      () {
        final t = n == 1 ? .5 : i / (n - 1);
        final up = head <= 0 ? 1.0 : (t / head).clamp(0.0, 1.0);
        final down = tail <= 0 ? 1.0 : ((1 - t) / tail).clamp(0.0, 1.0);
        final k = math.min(up, down);
        return peak * k * k * (3 - 2 * k);
      }(),
  ];

  /// Rows of scale arcs along a tube, in the vocabulary of the torso's: dark
  /// arcs bowing toward [bulge] (+1 toward higher samples), the pitch
  /// [pitchFrom] .. [pitchTo] (rig units) from sample [from] to [to]. [frame]
  /// gives the tube at a sample: its centre, its unit normal (+ is the side
  /// [plus] wide) and both half widths; [reach] is how much of the width the
  /// arcs cover. Alternate rows are staggered, as the torso's are.
  static void tubeRows(
    Path out,
    ({Offset centre, Offset normal, double plus, double minus}) Function(
      double u,
    )
    frame, {
    required double from,
    required double to,
    required double pitchFrom,
    required double pitchTo,
    required double bulge,
    double reach = 1,
  }) {
    var u = from;
    var row = 0;
    while (u < to) {
      final k = (u - from) / (to - from);
      final pitch = mix(pitchFrom, pitchTo, k);
      final f0 = frame(u);
      // Samples per unit of arclength here, from a quarter-sample step.
      final speed = math.max(
        .05,
        (frame(u + .25).centre - f0.centre).distance / .25,
      );
      final du = pitch / speed;
      final f1 = frame(u + bulge * du * 1.35);
      final width = f0.plus + f0.minus;
      final cols = math.max(1, (width / .3).round());
      final step = 2 * reach / cols;
      final half = step / 2;
      final count = row.isOdd ? cols + 1 : cols;
      Offset at(
        ({Offset centre, Offset normal, double plus, double minus}) f,
        double across,
      ) => f.centre + f.normal * ((across >= 0 ? f.plus : f.minus) * across);
      for (var j = 0; j < count; j++) {
        final fc = -reach + half + j * step - (row.isOdd ? half : 0);
        final a = at(f0, (fc - half).clamp(-reach, reach));
        final b = at(f0, (fc + half).clamp(-reach, reach));
        if ((a - b).distanceSquared < .0025) continue;
        final m = at(f1, fc.clamp(-reach, reach));
        out
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(m.dx, m.dy, b.dx, b.dy);
      }
      u += du;
      row++;
    }
  }

  /// A point on the Catmull-Rom curve through [pts] between vertex [i] and
  /// the next, at [t] (the ends repeat): what [spline] draws.
  static Offset catmull(List<Offset> pts, int i, double t) {
    final n = pts.length;
    Offset at(int k) => pts[k.clamp(0, n - 1)];
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    return bezier(p1, p1 + (p2 - p0) / 6, p2 - (p3 - p1) / 6, p2, t);
  }

  /// Twice the signed area of the polygon through [pts] (shoelace): positive
  /// when it winds clockwise on screen (y down). Closed outlines laid in one
  /// path fill and clip as their union only if they all wind the same way.
  static double winding(List<Offset> pts) {
    var sum = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum;
  }

  /// [path] carried by the affine map x' = a x + c y + tx, y' = b x + d y + ty
  /// (a new path; the source is untouched).
  static Path affine(
    Path path,
    double a,
    double b,
    double c,
    double d,
    double tx,
    double ty,
  ) => path.transform(
    Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1]),
  );

  /// [path] turned by [angle] radians about [about], then moved by [by].
  static Path turned(
    Path path,
    double angle, {
    Offset about = Offset.zero,
    Offset by = Offset.zero,
  }) {
    final cs = math.cos(angle), sn = math.sin(angle);
    // p' = R (p - about) + about + by
    final tx = about.dx - (cs * about.dx - sn * about.dy) + by.dx;
    final ty = about.dy - (sn * about.dx + cs * about.dy) + by.dy;
    return affine(path, cs, sn, -sn, cs, tx, ty);
  }

  // ---------------------------------------------------- lighting helpers --

  /// Two-tone edge light inside [path], clipped to it: the sky's bounce along
  /// the upper-left rim, the fire's along the underside. Painted between fill
  /// and ink, so the ink stays the outer contour and the light sits just
  /// inside it, holding the silhouette on dark backdrops.
  ///
  /// Cost: one clipPath + two strokes. Budget: at most 10 per frame.
  static void edge(
    Canvas c,
    Path path,
    DragonTone tone, {
    double width = .1,
    double shift = .06,
    double fire = 1,
    double sky = 1,
  }) {
    c.save();
    c.clipPath(path, doAntiAlias: false);
    // Shifting a stroke of the outline inward leaves a crescent of it along
    // the edge that faces the light.
    c.save();
    c.translate(shift * .75, shift * .75);
    final wide = 1 + tone.dark * .7;
    c.drawPath(path, line(tone.lit(tone.sky), width * wide, tone.skyRim * sky));
    c.restore();
    c.translate(-shift * .25, -shift);
    c.drawPath(
      path,
      line(tone.lit(DragonPalette.rimFire), width * 1.15, tone.fireRim * fire),
    );
    c.restore();
  }

  /// The outer contour of a hero shape: [width] on the shade side (lower
  /// right), thinner on the lit side. Two strokes, no clip.
  static void inkHero(Canvas c, Path path, [double width = .105]) {
    c.drawPath(path, line(DragonPalette.ink, width * .78));
    c.save();
    c.translate(width * .16, width * .2);
    c.drawPath(path, line(DragonPalette.ink, width * .62));
    c.restore();
  }

  /// A molten seam along [path]: a soft bloom in the seam colour, a white-hot
  /// core (faint at rest, blazing hot), and no dark edge (draw the plate
  /// edge yourself). [alpha] fades it out toward the lit side.
  static void moltenSeam(
    Canvas c,
    Path path,
    DragonTone tone, {
    double width = .085,
    double alpha = 1,
  }) {
    final k = tone.glow * alpha;
    if (k <= 0) return;
    // Fury opens the seams to twice their width (round 2: at x1.4 they were
    // 2 px hairlines at phone size) and even the resting seam has a hot core.
    final wide = 1 + tone.fury * 1.0;
    c.drawPath(
      path,
      line(tone.seam, width * wide, (.55 + .45 * tone.glow) * alpha),
    );
    if (tone.glow >= .5) {
      c.drawPath(
        path,
        line(
          DragonPalette.seamHot,
          width * .36 * wide,
          (tone.glow * .8) * alpha,
        ),
      );
    }
  }

  /// Ambient occlusion: a [width] band of [DragonPalette.scaleCore] laid
  /// along [edge], clipped to [into], where two parts meet (wing root over
  /// torso, jaw over throat, crown over skull).
  static void occlude(
    Canvas c,
    Path into,
    Path edge, {
    double width = .16,
    double alpha = .45,
  }) {
    c.save();
    c.clipPath(into, doAntiAlias: false);
    c.drawPath(edge, line(DragonPalette.scaleCore, width, alpha));
    c.restore();
  }

  /// Paint for a membrane panel, back-lit: white-hot-orange beside the bones
  /// fading through crimson to a dark saturated hem, radial from [wrist].
  /// Stops [0, .34, .74, 1] at L* 75, 64, 52, 38 (fury burns them to flame).
  static Paint membrane(
    Offset wrist,
    double span,
    DragonTone tone, {
    bool far = false,
  }) {
    Color c(Color calm, Color hot) {
      final v = tone.burn(calm, hot);
      return far ? shade(v, .74) : v;
    }

    return radial(
      wrist,
      span,
      [
        c(DragonPalette.membraneGlow, DragonPalette.flameYellow),
        c(DragonPalette.membraneLit, DragonPalette.flameGold),
        c(DragonPalette.membrane, DragonPalette.flame),
        c(DragonPalette.membraneDark, DragonPalette.flameDark),
      ],
      const [0, .34, .74, 1],
    );
  }

  /// Horn, spine and claw bone: shaded at the root, light at the tip.
  static Paint bone(Offset root, Offset tip, DragonTone tone) => linear(
    root,
    tip,
    [
      tone.lit(DragonPalette.boneShade),
      tone.lit(DragonPalette.boneDeep),
      tone.lit(DragonPalette.bone),
      tone.lit(DragonPalette.boneLit),
    ],
    const [0, .3, .75, 1],
  );

  /// [color] pulled toward the ink by [amount] (0 = ink, 1 = untouched):
  /// far-side shapes stay saturated instead of turning to mud.
  static Color shade(Color color, double amount) => Color.lerp(
    Color.lerp(DragonPalette.scaleCore, DragonPalette.ink, .4)!,
    color,
    amount,
  )!;

  // ---------------------------------------------------------- caching --

  static final Map<Object, Paint> _paints = {};

  /// How many paints [cached] keeps: the oldest one goes, singly, when it is
  /// full (it used to clear the whole map at 96 entries, so every paint of
  /// the dragon was rebuilt in one frame).
  static const cacheCapacity = 256;

  /// How many paints [cached] holds now (never more than [cacheCapacity]).
  static int get cacheSize => _paints.length;

  /// A paint kept between frames under [key] (a record of the values that
  /// change its look, quantised, e.g. `(id, tone.key)`). Build gradients in
  /// unit space and draw them under a transform so one paint serves every
  /// pose. Bounded and least-recently-used: a step in the tone costs one
  /// entry's shaders, never the whole set.
  static Paint cached(Object key, Paint Function() make) {
    final hit = _paints.remove(key);
    if (hit != null) return _paints[key] = hit;
    if (_paints.length >= cacheCapacity) _paints.remove(_paints.keys.first);
    return _paints[key] = make();
  }
}

/// A limb, the neck or the tail: a spine with a width at each point, and
/// the rounded outline around it.
final class DragonTube {
  DragonTube(this.spine, this.widths);
  final List<Offset> spine;
  final List<double> widths;

  late final Path path = DragonKit.capsule(spine, widths);

  /// Both edges: left and right of the spine's direction.
  late final (List<Offset>, List<Offset>) edges = DragonKit.tubeEdges(
    spine,
    widths,
  );
}
