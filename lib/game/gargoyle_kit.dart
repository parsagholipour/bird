import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'gargoyle_layout.dart';

/// The Searchlight Gargoyle's palette: Indiana limestone and stainless steel
/// around a brass searchlight lamp, with a little verdigris under the brass.
///
/// Values (CIE L*, contract): ink 6, limestone core 24 .. sheen 96 in six steps
/// with the body at 75, steel 18 .. 82, brass 25 .. 86, lamp 62 .. 99 (the lamp
/// and the lenses are always the brightest thing on the creature; limestone's
/// sheen is at most 5% of any part). Verdigris is at most 8% of any part and
/// only ever drips from brass joints.
abstract final class GargoylePalette {
  /// The outer contour. Inner lines use [inkWarm] on brass and limestone.
  static const ink = Color(0xff17162b), inkWarm = Color(0xff33182a);

  // Limestone: a planar, chiselled ramp from the sheen on the lit planes to
  // the core in the crevices. Shadows are violet, never black.
  static const limeSheen = Color(0xfffbf3e0), limeLit = Color(0xffeadcbf);
  static const lime = Color(0xffc9b894), limeShade = Color(0xff9a8b7c);
  static const limeDeep = Color(0xff5f566e), limeCore = Color(0xff3a3552);

  // Stainless steel: one brushed gradient, one specular streak.
  static const steelLit = Color(0xffbcd3e8), steel = Color(0xff7f9dbd);
  static const steelMid = Color(0xff58739a), steelDeep = Color(0xff36496e);
  static const steelCore = Color(0xff252f50);

  // Verdigris (drips from brass joints only).
  static const vdLit = Color(0xff9ad8c4), vd = Color(0xff4fae9a);
  static const vdDeep = Color(0xff2b7a75);

  // Brass: a hard three-stop ramp.
  static const brassLit = Color(0xffffe9a8), brass = Color(0xffe3b454);
  static const brassDeep = Color(0xffa8742f), brassShade = Color(0xff6b4422);

  // The lamp and the lenses: the brightest things on him.
  static const lampCore = Color(0xfffffbe8), lampWarm = Color(0xffffe39a);
  static const lampAmber = Color(0xffffb84a), lampDeep = Color(0xffe9822e);

  // Fury's arc: white-hot core, warm body, orange edge (cracks and beams).
  static const arcCore = Color(0xfffffdf4), arcBody = Color(0xffffe6b0);
  static const arcEdge = Color(0xffff9a4a);

  // Light: New York's moon (the key, cool, upper right) and stone at rest.
  static const moon = Color(0xffcdd6ff), stoneGrey = Color(0xff8e92a6);
  static const dust = Color(0xffd9d0bd), steam = Color(0xffe9e6f6);

  // The tower.
  static const pier = Color(0xff3e3a5e), pierLit = Color(0xff59547f);

  // The HUD's cool dodge tags (never amber: amber means "he is lit").
  static const cool = Color(0xff9fe6ff), coolDeep = Color(0xff3f7fa8);

  static const white = Color(0xffffffff);
}

/// How the sky lights the Gargoyle: [dark] is 0 for a bright sky and 1 for
/// night, [sky] the colour of the moon's rim on his back and top edges. He only
/// ever stands in New York (rainy night, [dark] about .8), but the story scenes
/// and the keepsake paint him on other skies, so the pose takes it.
final class GargoyleSkyLight {
  const GargoyleSkyLight({this.dark = .8, this.sky = GargoylePalette.moon});

  /// Sky at [top] and [horizon] with mist colour [haze]: the average luminance
  /// decides how dark it is (0 above .34, 1 below .04) and the haze tints the
  /// rim so it reads as that region's own bounce.
  factory GargoyleSkyLight.fromSky({
    required Color top,
    required Color horizon,
    required Color haze,
  }) {
    final lum = (top.computeLuminance() + horizon.computeLuminance()) / 2;
    return GargoyleSkyLight(
      dark: 1 - ((lum - .04) / .3).clamp(0.0, 1.0),
      sky: Color.lerp(haze, GargoylePalette.moon, .5)!,
    );
  }

  static const neutral = GargoyleSkyLight();
  final double dark;
  final Color sky;
}

/// How the Gargoyle is lit right now, shared by every part of him.
///
/// [flash] bleaches fills toward the lamp's white after a hit (the ink holds,
/// so form survives), [fury] is the furious look (lamps white-hot, seams
/// cracked amber), [heat] the lamp's own warm fill on his front faces while it
/// or the lenses burn, [stone] the dormant grey of the arrival, and [dark] and
/// [sky] the backdrop's light (the moon rim).
///
/// Every channel sits on a ladder of eighths ([snapped]; [darkSteps] quarters),
/// so a cache keyed by [key] is always built from the value that names it and
/// pixels depend only on the inputs, never on what was drawn before.
final class GargoyleTone {
  const GargoyleTone({
    this.flash = 0,
    this.fury = 0,
    this.heat = 0,
    this.dark = .8,
    this.sky = GargoylePalette.moon,
    this.stone = 0,
  });

  final double flash, fury, heat, dark, stone;
  final Color sky;

  static const steps = 8, darkSteps = 4;

  /// A fill colour under the hit flash and the dormant stone. The flash goes
  /// near-white toward the lamp's core (up to .95 of the way at the peak, so it
  /// reads on every sky; lights go a little further than darks); the ink holds.
  Color lit(Color color) {
    var c = color;
    if (stone > 0) {
      final hsl = HSLColor.fromColor(c);
      final grey = HSLColor.fromAHSL(c.a, 240, .10, hsl.lightness * .92).toColor();
      c = Color.lerp(c, grey, stone.clamp(0.0, 1.0))!;
    }
    if (flash <= 0) return c;
    final w = flash * 1.3 * (.8 + .2 * math.sqrt(c.computeLuminance()));
    return Color.lerp(c, GargoylePalette.lampCore, w.clamp(0.0, .9))!;
  }

  /// The same look as a colour filter for gradient fills (it never rebuilds
  /// a shader): a desaturating, darkening matrix for the dormant stone then a
  /// blend toward the lamp's white for the flash. Null when neither applies.
  ColorFilter? get filter {
    if (flash <= 0 && stone <= 0) return null;
    final s = 1 - stone.clamp(0.0, 1.0) * .9, dim = 1 - stone.clamp(0.0, 1.0) * .08;
    final w = (flash * 1.3 * .9).clamp(0.0, .9);
    const f = GargoylePalette.lampCore;
    final tint = [f.r * 255 * w, f.g * 255 * w, f.b * 255 * w];
    final k = (1 - w) * dim;
    final m = <double>[
      (.213 + .787 * s) * k, (.715 - .715 * s) * k, (.072 - .072 * s) * k, 0, tint[0], //
      (.213 - .213 * s) * k, (.715 + .285 * s) * k, (.072 - .072 * s) * k, 0, tint[1], //
      (.213 - .213 * s) * k, (.715 - .715 * s) * k, (.072 + .928 * s) * k, 0, tint[2], //
      0, 0, 0, 1, 0,
    ];
    return ColorFilter.matrix(m);
  }

  /// A fill colour that burns from [calm] to [burning] with fury.
  Color burn(Color calm, Color burning) =>
      lit(fury <= 0 ? calm : Color.lerp(calm, burning, fury)!);

  /// The moon rim's strength on the top and back edges: stronger on dark skies,
  /// a little weaker in fury (his own light takes over).
  double get moonRim => ((.45 + dark * .45) * (1 - fury * .35)).clamp(0.0, 1.0);

  /// The lamp's warm fill on the front (left) faces, 0 to 1: a faint .2 at rest
  /// (his lenses), full with the lamp open, more in fury.
  double get lampFill => (.2 + heat * .6 + fury * .2).clamp(0.0, 1.0);

  /// How hot the lamp and lenses look, 0 to 1 (the white core grows with it).
  double get glow => (.4 + heat * .6 + fury * .3).clamp(0.0, 1.0);

  /// Crack colour: amber at rest, arc-white at its core in fury.
  Color get crackEdge => Color.lerp(GargoylePalette.lampAmber, GargoylePalette.arcEdge, fury)!;
  Color get crackCore => Color.lerp(GargoylePalette.lampWarm, GargoylePalette.arcCore, fury)!;

  /// This tone on the ladder of eighths ([darkSteps] quarters for the sky's
  /// darkness, the sky colour on its 5-bit steps).
  GargoyleTone snapped() => GargoyleTone(
    flash: _snap(flash, steps),
    fury: _snap(fury, steps),
    heat: _snap(heat, steps),
    dark: _snap(dark, darkSteps),
    stone: _snap(stone, steps),
    sky: Color(sky.toARGB32() & 0xfff8f8f8),
  );

  static double _snap(double v, int n) => v.isFinite ? ((v.clamp(0.0, 1.0)) * n).round() / n : 0;

  /// A bucket id for caches keyed by tone (eighths; the darkness in quarters).
  int get key => Object.hash(
    (flash * steps).round(),
    (fury * steps).round(),
    (heat * steps).round(),
    (stone * steps).round(),
    (dark * darkSteps).round(),
  );
}

/// How the boss beam LOOKS, and the contract its renderer keeps.
///
/// **The renderer contract** (`GargoyleBeamArt`, G5): per beam three layered
/// wedges (a haze 130% as wide at alpha [hazeAlpha], the body, a core 50% as
/// wide), two hairline edges ([edgeWidthPx], the exact lit band), one lens
/// flare: 6 draw ops and about 40 vertices; twin beams 12. No blur, no
/// `saveLayer`. The wedges are fixed unit triangles and their gradient paints
/// are cached forever (calm and fury sets): a beam is PLACED by one affine
/// transform ([GargoyleKit.beamFrame]) that carries the unit triangle onto
/// the eye, through the rules' band at the bird's column, and out to the left
/// edge, so the drawn band at the bird IS the rules' band (within 1 px at 640
/// and 800) and the apex is at the lens. The edge lines are drawn in screen
/// space (a transform would skew their width).
///
/// **Not New York's searchlights.** The region's own beams (`new_york.dart`,
/// `_nightBeams`) are cool cream (#f5ecd2, saturation .14), at most .22 alpha,
/// .08 h wide, hard-edge-less, rising from the skyline and ending in soft pools
/// on the clouds. The boss beam must never be mistaken for one, nor the other
/// way round, so it differs on SEVEN axes: (1) hue and saturation: warm amber
/// (#ffb84a / #ffd36a, saturation .58 to .71), never cream (.14); (2) strength:
/// the core is .42 alpha (.55 in fury) against the region's .25, and the body
/// .27 against a region beam that is ten times thinner; (3) HARD EDGES: two 1.6
/// px amber hairlines that exactly bound the lit band (the region's beams have
/// none); (4) origin: it comes out of HIS LENSES, widening to the left, while
/// the region's rise from the skyline; (5) width: .18 h tall at the bird, the
/// region's are .08 h at their widest; (6) a lens flare at the source and a
/// dashed fan that announces it; (7) it glides across the sky under his head's
/// aim while the region's rotate slowly about their bases. Fury goes arc-white
/// with an orange edge, never cream.
abstract final class GargoyleBeamLook {
  static const edge = Color(0xffffb84a), body = Color(0xffffd36a), core = Color(0xfffff3cf);
  static const furyEdge = Color(0xffff9a4a), furyBody = Color(0xffffe6b0), furyCore = Color(0xfffffdf4);

  /// New York's own searchlight colour (mirrors `new_york.dart`, for the
  /// contrast test).
  static const regionCream = Color(0xfff5ecd2);

  /// Layer widths relative to the band and their peak alphas (calm, fury). The
  /// beam's alpha never exceeds [maxAlpha] anywhere (the bird stays clear).
  static const hazeGrow = 1.30, coreGrow = .50;
  static const hazeAlpha = .13, bodyAlpha = .27, coreAlpha = .42;
  static const furyBodyAlpha = .34, furyCoreAlpha = .55, maxAlpha = .55;

  /// The wedge fades to nothing at its far end; these are the gradient's
  /// stops (along the beam): full at the lens, [fadeMid] of the alpha at
  /// [fadeAt], none at the end.
  static const fadeAt = .62, fadeMid = .80;

  /// The hairline edges' width (px, never scaled) and peak alpha, and the lens
  /// flare's radius in px at 360 px high (scaled with the screen).
  static const edgeWidthPx = 1.6, edgeAlpha = .75, flareRadiusPx = 11.0;

  /// The per-beam budget the renderer keeps.
  static const maxOps = 6, maxVertices = 40;

  /// Seconds the beam takes to reach full strength at the rules' ignition
  /// (it hurts from the first frame, so the EDGES are at full at once and only
  /// the haze/body/core ramp), and to fade after the vent closes it.
  static const igniteSeconds = .10, fadeSeconds = .10, igniteFloor = .70;

  /// How long the warning's fan, veil and tag take to dissolve UNDER the
  /// beam once it burns (the beam's body is already at [igniteFloor] on its
  /// first frame and rises to full in [igniteSeconds]): the screen never
  /// shows less danger than the frame before.
  static const warnReleaseSeconds = .15;
}

/// Paints, gradients and path builders shared by the Gargoyle's parts.
abstract final class GargoyleKit {
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

  /// Diagnostic only: gradient shaders built through [linear], [radial] and
  /// [glow]. `gargoyle_budget_test.dart` reads it to hold the per-frame budget
  /// of new shaders; it never influences a pixel.
  static int shadersBuilt = 0;

  static Paint linear(Offset from, Offset to, List<Color> colors, [List<double>? stops]) {
    shadersBuilt++;
    return Paint()..shader = ui.Gradient.linear(from, to, colors, stops ?? _even(colors));
  }

  static Paint radial(Offset center, double radius, List<Color> colors, [List<double>? stops]) {
    shadersBuilt++;
    return Paint()..shader = ui.Gradient.radial(center, radius, colors, stops ?? _even(colors));
  }

  static List<double>? _even(List<Color> colors) =>
      colors.length == 2 ? null : [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];

  // ---------------------------------------------------------- caching --

  static final Map<Object, Paint> _paints = {};

  /// How many paints [cached] keeps: the oldest goes, singly, when it is full.
  static const cacheCapacity = 256;

  /// How many paints [cached] holds now (never more than [cacheCapacity]).
  static int get cacheSize => _paints.length;

  /// A paint kept between frames under [key]. **Build gradients in the part's
  /// own frame, once, and key them by a part id only** (they never depend on
  /// the pose: the part's frame is already placed by the rig), so a whole fight
  /// builds each shader once. A tone-dependent look is done with
  /// [GargoyleTone.lit] on flat colours and [GargoyleTone.filter] on gradient
  /// paints, never by rebuilding a shader. Bounded and least-recently-used.
  static Paint cached(Object key, Paint Function() make) {
    final hit = _paints.remove(key);
    if (hit != null) return _paints[key] = hit;
    if (_paints.length >= cacheCapacity) _paints.remove(_paints.keys.first);
    built.add(key);
    return _paints[key] = make();
  }

  /// Diagnostic only: the key of every shader built through [cached] and
  /// [glow] since the last [clearCaches] (the budget test names them).
  static final List<Object> built = [];

  /// A shared gradient [paint] with the tone's colour filter set for this draw
  /// (paints are reused and drawn at once, and every draw sets the filter, so
  /// it never leaks from one tone into another).
  static Paint toned(Paint paint, GargoyleTone tone) {
    paint.colorFilter = tone.filter;
    return paint;
  }

  static final Map<int, ui.Shader> _glows = {};

  /// Empties every cache (tests only: to count the shaders a part needs from
  /// cold, or to flood the caches before re-rendering).
  static void clearCaches() {
    _paints.clear();
    _glows.clear();
    built.clear();
  }

  /// A soft round glow of [color] fading out from [alpha]. The gradient is built
  /// once per colour (5-bit steps) in unit space and drawn under a transform
  /// with the alpha on the paint, so a glow costs no shader build per frame.
  static void glow(Canvas c, Offset at, double radius, Color color, double alpha) {
    if (alpha <= 0 || radius <= 0) return;
    final argb = color.toARGB32();
    final solid = Color(0xff000000 | ((argb & 0xf8f8f8) | 0x040404));
    var shader = _glows.remove(solid.toARGB32());
    if (shader == null) {
      if (_glows.length >= 64) _glows.remove(_glows.keys.first);
      shadersBuilt++;
      built.add('glow:${solid.toARGB32().toRadixString(16)}');
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

  // ------------------------------------------------------------ paths --

  /// A polygon through [pts].
  static Path poly(List<Offset> pts, {bool closed = true, Path? into}) {
    final path = into ?? Path();
    path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (closed) path.close();
    return path;
  }

  /// A smooth curve through [pts] (Catmull-Rom as cubic Beziers). Vertices in
  /// [sharp] stay corners.
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
      final c1 = sharp.contains((i % n + n) % n) ? p1 : p1 + (p2 - p0) * (tension / 6);
      final c2 = sharp.contains(((i + 1) % n + n) % n) ? p2 : p2 - (p3 - p1) * (tension / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed) path.close();
    return path;
  }

  /// A regular octagon of [radius] (circumradius), a flat side up: the lamp's
  /// Art Deco housing.
  static Path octagon(double radius) => poly([
    for (var i = 0; i < 8; i++)
      Offset(
        math.cos(math.pi / 8 + i * math.pi / 4) * radius,
        math.sin(math.pi / 8 + i * math.pi / 4) * radius,
      ),
  ]);

  /// A deterministic 0..1 value for slot [i] and [salt].
  static double hash(int i, [int salt = 0]) =>
      ((i * 7919 + salt * 104729 + 13) * 2654435761 % 1000003) / 1000003;

  /// Linear blend of two numbers.
  static double mix(double a, double b, double t) => a + (b - a) * t;

  /// [v] turned by [angle] radians.
  static Offset turn(Offset v, double angle) {
    final cs = math.cos(angle), sn = math.sin(angle);
    return Offset(v.dx * cs - v.dy * sn, v.dx * sn + v.dy * cs);
  }

  /// [color] pulled toward the ink by [amount] (0 = ink, 1 = untouched): the far
  /// fan and far leg stay saturated instead of turning to mud.
  static Color shade(Color color, double amount) => Color.lerp(
    Color.lerp(GargoylePalette.limeCore, GargoylePalette.ink, .4)!,
    color,
    amount,
  )!;

  // ---------------------------------------------------------- lighting --

  /// The moon's rim and the lamp's fill inside [path], clipped to it: the
  /// cool moon crescent along the UPPER-RIGHT (back and top) edge, the warm lamp
  /// fill along the lower-left (front) edge, painted BETWEEN fill and ink so the
  /// ink stays the outer contour and the light sits just inside it (it holds
  /// the silhouette on the night sky). Cost: one clipPath and two strokes; at
  /// most 10 per frame.
  static void edge(
    Canvas c,
    Path path,
    GargoyleTone tone, {
    double width = .10,
    double shift = .06,
    double moon = 1,
    double lamp = 1,
  }) {
    c.save();
    c.clipPath(path, doAntiAlias: false);
    c.save();
    // Shifting a stroke of the outline toward the lower left leaves a crescent
    // of it along the upper right, the edge that faces the moon.
    c.translate(-shift * .75, shift * .75);
    final wide = 1 + tone.dark * .5;
    c.drawPath(path, line(tone.lit(tone.sky), width * wide, tone.moonRim * moon));
    c.restore();
    c.translate(shift * .25, -shift);
    c.drawPath(
      path,
      line(tone.lit(GargoylePalette.lampAmber), width * 1.15, tone.lampFill * .55 * lamp),
    );
    c.restore();
  }

  /// The outer contour of a hero shape: [width] on the shade side (lower left,
  /// away from the moon), about .72 on the lit side. Two strokes, no clip.
  static void inkHero(Canvas c, Path path, [double width = GargoyleLayout.inkHero]) {
    c.drawPath(path, line(GargoylePalette.ink, width * .78));
    c.save();
    c.translate(-width * .16, width * .2);
    c.drawPath(path, line(GargoylePalette.ink, width * .62));
    c.restore();
  }

  /// Ambient occlusion: a [width] band of [GargoylePalette.limeCore] laid along
  /// [edge], clipped to [into], where two parts meet (wing root over torso, beak
  /// over chest, visor over lens).
  static void occlude(Canvas c, Path into, Path edge, {double width = .16, double alpha = .45}) {
    c.save();
    c.clipPath(into, doAntiAlias: false);
    c.drawPath(edge, line(GargoylePalette.limeCore, width, alpha));
    c.restore();
  }

  /// A crack along [path]: a dark edge, an amber body and (hot, in fury) an
  /// arc-white core. [alpha] is the `crack` channel.
  static void crack(Canvas c, Path path, GargoyleTone tone, {double width = .07, double alpha = 1}) {
    if (alpha <= 0) return;
    c.drawPath(path, line(GargoylePalette.ink, width * 2.2, alpha * .6));
    c.drawPath(path, line(tone.crackEdge, width * 1.6, alpha * .55));
    c.drawPath(path, line(tone.crackCore, width * .75, alpha * (.75 + tone.fury * .25)));
  }

  // ------------------------------------------------------------- beams --

  /// Where a beam stands: the affine map from the UNIT TRIANGLE (apex (0,0),
  /// far corners (1,-1) and (1,1)) onto the triangle from the [eye] through the
  /// rules' band at the bird's column and on to [reachX]. [centre] and [half]
  /// are the band's centre and half-height (px) at x = [columnX]. The matrix
  /// is returned as the canvas's `transform` storage, with the far end's
  /// distance factor [reach] (how many times the eye-to-column distance the
  /// wedge runs) and the two edge points the hairlines join (screen px).
  ///
  /// `(eye.dx - reachX) / (eye.dx - columnX)` is the factor: the wedge ends at
  /// [reachX] (the left screen edge). Returns null when the eye is not right of
  /// the column (no beam is drawn then).
  static ({Float64List matrix, double reach, Offset edgeTop, Offset edgeBottom})? beamFrame({
    required Offset eye,
    required double columnX,
    required double centre,
    required double half,
    double reachX = 0,
  }) {
    final d = eye.dx - columnX;
    if (d < 1) return null;
    final reach = math.max(1.0, (eye.dx - reachX) / d);
    final top = Offset(columnX, centre - half), bottom = Offset(columnX, centre + half);
    final mid = Offset(columnX, centre);
    // M(1,0) = reach * (C - E), M(0,1) = reach * (B - A) / 2.
    final ax = reach * (mid.dx - eye.dx), ay = reach * (mid.dy - eye.dy);
    final bx = reach * (bottom.dx - top.dx) / 2, by = reach * (bottom.dy - top.dy) / 2;
    final m = Float64List.fromList([
      ax, ay, 0, 0, //
      bx, by, 0, 0, //
      0, 0, 1, 0, //
      eye.dx, eye.dy, 0, 1,
    ]);
    return (
      matrix: m,
      reach: reach,
      edgeTop: eye + (top - eye) * reach,
      edgeBottom: eye + (bottom - eye) * reach,
    );
  }
}
