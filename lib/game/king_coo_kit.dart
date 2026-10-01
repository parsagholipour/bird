import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// King Coo's palette: a pouter pigeon's blue-bar lilac greys with a rosy
/// cream breast (the brightest big shape: the target), an iridescent ruff,
/// coral beak and feet (the Alley Pigeon's, so the king is family), a navy
/// police cap with brass piping and a red/blue siren, a silver whistle, a
/// burlap crumb sack and bread tones.
///
/// Values (CIE L*) are the contract: ink 9, feather core 20, plumage ramp
/// 87 / 65 / 47 / 31, breast 96 / 90 / 79 / 61, cap 42 / 25 / 14, brass 81,
/// crumbs 82. New York's night sky is L 19-43 and its haze 43: the ink and the
/// cream chest carry the read there, the lit plumage holds against the dark.
abstract final class KingCooPalette {
  /// The outer contour. Inner lines use [inkCool] on plumage and [inkWarm] on
  /// the breast, brass and sack, so no inner line is a flat black hole.
  static const ink = Color(0xff1b1730);
  static const inkCool = Color(0xff262244), inkWarm = Color(0xff3a1f33);

  // Plumage: dove blue-bar, lifted out of New York's purple haze.
  static const featherLit = Color(0xffdcd6ee), feather = Color(0xff9d9ac6);
  static const featherDeep = Color(0xff6d6b9f), featherDark = Color(0xff46456f);
  static const featherCore = Color(0xff2d2c54);
  static const bar = Color(0xff2f2e58), covert = Color(0xff7d7bb0);

  // Breast: rosy cream, the brightest big shape.
  static const breastHi = Color(0xfffaf0f4), breastLit = Color(0xfff2dce6);
  static const breast = Color(0xffd8bdd0), breastDeep = Color(0xffa98aa4);

  // The iridescent ruff.
  static const irisGreen = Color(0xff57dcab), irisTeal = Color(0xff33b8cb);
  static const irisViolet = Color(0xffa860e4), irisMagenta = Color(0xffe456b8);

  // Eye, beak and feet (the Alley Pigeon's coral).
  static const eyeRim = Color(0xffff6a2a), eyeCore = Color(0xffffc24d);
  static const eyeDeep = Color(0xffb8320f), mouth = Color(0xff4a1026);
  static const beak = Color(0xffffb48a), beakDeep = Color(0xff8a4a3a);
  static const cere = Color(0xfffff2c9);
  static const foot = Color(0xffff8f63), footDeep = Color(0xffc9553f);

  // The cap, the badge and the siren.
  static const navyLit = Color(0xff4b5db5), navy = Color(0xff283672);
  static const navyDeep = Color(0xff171f4a), visor = Color(0xff0f1330);
  static const brass = Color(0xfff3c350), brassDeep = Color(0xffb97a2a);
  static const brassLit = Color(0xfffff0b0);
  static const sirenRed = Color(0xffff4a5e), sirenBlue = Color(0xff4aa8ff);
  static const sirenOff = Color(0xff7a2f3b), sirenOffDeep = Color(0xff3a1a25);

  // Steel: the whistle.
  static const steelLit = Color(0xfff3f6ff), steel = Color(0xffabb5d2);
  static const steelDeep = Color(0xff656f94);

  // The burlap sack and its crumbs.
  static const burlapLit = Color(0xffe9cf98), burlap = Color(0xffc9a46c);
  static const burlapDeep = Color(0xff8c673b), rope = Color(0xff68472a);
  static const patch = Color(0xfff4e6b9);
  static const crumbHi = Color(0xfffff2c6), crumb = Color(0xfff0c77c);
  static const crust = Color(0xffd9963f), crustDeep = Color(0xff9b5c27);
  static const cream = Color(0xfffdf0d0);

  // The squad's language: go is green, stop is red.
  static const go = Color(0xff62e6a0), stop = Color(0xffff5a6a);
  static const cone = Color(0xffff8a3a);

  // The HUD accent (squad-car blue) and gold.
  static const blueLit = Color(0xffd8e2ff), blue = Color(0xff7f9bff);
  static const blueDeep = Color(0xff4a5fc4), gold = Color(0xffffd878);

  // Light: the moon's bounce on upper-right edges, the windows' glow on the
  // lower-left ones, the fury's flush, the hit's bleach, smoke and steam.
  static const rimSky = Color(0xffa4afde), rimMoon = Color(0xffdbe2ff);
  static const rimWarm = Color(0xffffb36b);
  static const furyTint = Color(0xffe0607c), furyBreast = Color(0xffff8f86);
  static const bleach = Color(0xfffff6ec);
  static const steam = Color(0xffeaeaf8);

  static const white = Color(0xffffffff);
}

/// How the sky lights King Coo right now: [dark] is 0 for a bright sky and 1
/// for night, [sky] the colour of the moon's bounce on his upper-right edges.
///
/// Both are pure functions of the backdrop's palette at the flight clock, so
/// they are deterministic and Reduced Motion needs no special case. They
/// reach every part through `pose.tone`.
final class KingCooSkyLight {
  const KingCooSkyLight({this.dark = 0, this.sky = KingCooPalette.rimSky});

  /// Sky at [top] and [horizon] with mist colour [haze]: the average
  /// luminance decides how dark it is (0 above .34, 1 below .04) and the haze
  /// tints the rim so it reads as that region's own bounce light.
  factory KingCooSkyLight.fromSky({
    required Color top,
    required Color horizon,
    required Color haze,
  }) {
    final lum = (top.computeLuminance() + horizon.computeLuminance()) / 2;
    return KingCooSkyLight(
      dark: 1 - ((lum - .04) / .3).clamp(0.0, 1.0),
      sky: Color.lerp(haze, KingCooPalette.rimSky, .5)!,
    );
  }

  static const neutral = KingCooSkyLight();
  final double dark;
  final Color sky;
}

/// How King Coo is lit right now, shared by every part of him.
///
/// [flash] bleaches fills toward cream after a hit (the ink holds), [fury]
/// flushes the plumage and the breast toward a hot pink, and [heat] is the
/// glow of the puffed chest (badge and rim brighten). [siren] (0 off, 1 red,
/// 2 blue) and [sirenGlow] are the siren's light on the cap and head. [dark]
/// and [sky] are the backdrop's light.
///
/// NO paint a part keeps between frames depends on the tone: shaders are
/// built once in unit space, and the tone is laid over them as a translucent
/// wash ([KingCooKit.wash], at most two ops, none when calm) or applied to a
/// flat colour ([lit], [plate], [burn]). So a hit, the fury or a change of
/// sky never builds a shader and pixels cannot depend on what was drawn
/// before.
final class KingCooTone {
  const KingCooTone({
    this.flash = 0,
    this.fury = 0,
    this.heat = 0,
    this.dark = 0,
    this.siren = 0,
    this.sirenGlow = 0,
    this.sky = KingCooPalette.rimSky,
  });
  final double flash, fury, heat, dark, sirenGlow;
  final int siren;
  final Color sky;

  static const calm = KingCooTone();

  /// How far the hit bleaches (0 to .6 of the way to cream).
  double get washAlpha => (flash * 1.1).clamp(0.0, .6);

  /// How far the fury flushes a plumage shape (0 to .16: a warm shift of the
  /// lilac, never a muddy brown) and the breast (0 to .4: a hot pink chest).
  double get furyAlpha => (fury * .16).clamp(0.0, .16);
  double get furyBreastAlpha => (fury * .4).clamp(0.0, .4);

  /// A fill colour under the hit flash: it goes near-white (toward
  /// [KingCooPalette.bleach], up to .6 of the way at the peak) so it reads on
  /// every sky, pale ones included; the ink holds.
  Color lit(Color color) {
    final w = washAlpha;
    return w <= 0 ? color : Color.lerp(color, KingCooPalette.bleach, w)!;
  }

  /// A plumage colour flushed by the fury, then bleached by the flash.
  Color plate(Color color) {
    var c = color;
    if (fury > 0) {
      c = Color.lerp(c, KingCooPalette.furyTint, furyAlpha)!;
    }
    return lit(c);
  }

  /// A fill colour that burns from [calm] to [hot] with fury.
  Color burn(Color calm, Color hot) =>
      lit(fury <= 0 ? calm : Color.lerp(calm, hot, fury)!);

  /// The moon's rim: stronger on a dark sky, weaker in fury (the flush takes
  /// over), gone under a hit's bleach.
  double get skyRim =>
      ((.55 + dark * .4) * (1 - fury * .4) * (1 - washAlpha)).clamp(0.0, 1.0);

  /// The windows' warm bounce on lower-left edges.
  double get warmRim =>
      ((.28 + heat * .3 + fury * .2) * (1 - washAlpha)).clamp(0.0, 1.0);

  /// The siren's colour, or the lamp's dim red when it is off.
  Color get sirenColor => siren == 2
      ? KingCooPalette.sirenBlue
      : siren == 1
      ? KingCooPalette.sirenRed
      : KingCooPalette.sirenOff;

  /// Quantised (1/8 steps) so per-tone caches a part chooses to keep stay
  /// small. The kit's own caches never use it.
  int get key => Object.hash(
    (flash * 8).round(),
    (fury * 8).round(),
    (heat * 8).round(),
    (dark * 4).round(),
    siren,
    (sirenGlow * 4).round(),
  );
}

/// Paints, gradients and path builders shared by King Coo's parts.
///
/// The rule: nothing pose-independent is built per frame. A static `Path` is
/// a `static final` in the part; a gradient is built ONCE in unit space
/// (through [linear], [radial], [sweep] inside [cached]) and drawn under a
/// transform; a scalloped outline comes from [scallop]. [shadersBuilt] counts
/// every shader built through the kit: the budget test holds a warm frame to
/// its share.
abstract final class KingCooKit {
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

  /// Diagnostic only: gradient shaders built through [linear], [radial],
  /// [sweep] and [glow]. `king_coo_budget_test.dart` reads it; it never
  /// influences a pixel.
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

  static Paint sweep(
    Offset center,
    List<Color> colors, [
    List<double>? stops,
  ]) {
    shadersBuilt++;
    return Paint()
      ..shader = ui.Gradient.sweep(center, colors, stops ?? _even(colors));
  }

  static List<double>? _even(List<Color> colors) => colors.length == 2
      ? null
      : [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];

  // ---------------------------------------------------------- caching --

  static final Map<Object, Paint> _paints = {};
  static final Map<Object, Path> _paths = {};

  /// How many paints (and, separately, paths) the caches keep: the oldest
  /// goes, singly, when full.
  static const cacheCapacity = 256;

  static int get cacheSize => _paints.length + _paths.length;

  /// Empties every cache (paints, paths, glows): the next frame rebuilds what
  /// it needs, to the same pixels. For tests (determinism) and memory
  /// pressure; a game never needs it.
  static void clearCaches() {
    _paints.clear();
    _paths.clear();
    _glows.clear();
  }

  /// A paint kept between frames under [key] (a record of the values that
  /// change its look). Build gradients in UNIT space and draw them under a
  /// transform so one paint serves every pose.
  static Paint cached(Object key, Paint Function() make) {
    final hit = _paints.remove(key);
    if (hit != null) return _paints[key] = hit;
    if (_paints.length >= cacheCapacity) _paints.remove(_paints.keys.first);
    return _paints[key] = make();
  }

  /// A path kept between frames under [key] (for shapes that come in a few
  /// quantised variants, like the chest's outline).
  static Path cachedPath(Object key, Path Function() make) {
    final hit = _paths.remove(key);
    if (hit != null) return _paths[key] = hit;
    if (_paths.length >= cacheCapacity) _paths.remove(_paths.keys.first);
    return _paths[key] = make();
  }

  static final Map<int, ui.Shader> _glows = {};

  /// A soft round glow of [color] fading out from [alpha]. The gradient is
  /// built once per colour (on 5-bit steps), in unit space, and drawn under a
  /// transform with the alpha on the paint, so a glow costs no shader build
  /// per frame.
  static void glow(
    Canvas c,
    Offset at,
    double radius,
    Color color,
    double alpha,
  ) {
    if (alpha <= 0 || radius <= 0) return;
    final argb = color.toARGB32();
    final solid = Color(0xff000000 | ((argb & 0xf8f8f8) | 0x040404));
    var shader = _glows.remove(solid.toARGB32());
    if (shader == null) {
      if (_glows.length >= 64) _glows.remove(_glows.keys.first);
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

  // ------------------------------------------------------------- paths --

  /// A smooth closed (or open) curve through [pts] (Catmull-Rom as cubic
  /// Béziers).
  static Path spline(List<Offset> pts, {bool closed = true, Path? into}) {
    final n = pts.length;
    Offset at(int i) => closed ? pts[(i % n + n) % n] : pts[i.clamp(0, n - 1)];
    final path = into ?? Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    final segments = closed ? n : n - 1;
    for (var i = 0; i < segments; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed) path.close();
    return path;
  }

  /// A UNIT circle edged with [n] soft feather bumps of height [depth]
  /// (valleys on radius 1, peaks about `.99 + depth`), turned by [turn]:
  /// scale it to the radius you need. Cached by `(n, depth, turn)`; [depth]
  /// is quantised to 1/256, so pass a stepped value.
  static Path scallop(int n, double depth, {double turn = 0}) {
    final d = (depth * 256).round() / 256, t = (turn * 64).round() / 64;
    return cachedPath(('scallop', n, d, t), () {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a0 = t + 2 * math.pi * i / n, a1 = t + 2 * math.pi * (i + 1) / n;
        final am = (a0 + a1) / 2;
        final p0 = Offset(math.cos(a0), math.sin(a0));
        final p1 = Offset(math.cos(a1), math.sin(a1));
        final ctl = Offset(math.cos(am), math.sin(am)) * (1 + d * 2);
        if (i == 0) path.moveTo(p0.dx, p0.dy);
        path.quadraticBezierTo(ctl.dx, ctl.dy, p1.dx, p1.dy);
      }
      return path..close();
    });
  }

  // ------------------------------------------------------------- lighting --

  /// The tone laid over a filled [path] as translucent washes: the fury's
  /// flush ([plumage] true: toward the plumage tint, else toward the breast's
  /// hot pink; [flush] false: none, for iridescent or metal shapes) and the
  /// hit's bleach. Nothing when calm: a part calls this right after its fill
  /// and pays 0 to 2 ops only while the tone is on.
  static void wash(
    Canvas c,
    Path path,
    KingCooTone tone, {
    bool plumage = true,
    bool flush = true,
  }) {
    final flushAlpha = plumage ? tone.furyAlpha : tone.furyBreastAlpha;
    if (flush && flushAlpha > 0) {
      c.drawPath(
        path,
        fill(
          plumage ? KingCooPalette.furyTint : KingCooPalette.furyBreast,
          flushAlpha,
        ),
      );
    }
    if (tone.washAlpha > 0) {
      c.drawPath(path, fill(KingCooPalette.bleach, tone.washAlpha));
    }
  }

  /// Two-tone edge light inside [path], clipped to it: the moon's bounce
  /// along the UPPER-RIGHT rim (cool, `tone.sky`), the windows' glow along
  /// the LOWER-LEFT one (warm). Painted between fill and ink so the ink stays
  /// the outer contour and the light sits just inside it, holding the
  /// silhouette on dark backdrops. Cost: one clipPath and up to two strokes.
  /// Budget: at most 6 per frame.
  static void edge(
    Canvas c,
    Path path,
    KingCooTone tone, {
    double width = .09,
    double shift = .06,
    double sky = 1,
    double warm = 1,
  }) {
    if (tone.skyRim * sky <= .01 && tone.warmRim * warm <= .01) return;
    c.save();
    c.clipPath(path, doAntiAlias: false);
    edgeIn(c, path, tone, width: width, shift: shift, sky: sky, warm: warm);
    c.restore();
  }

  /// [edge] for a caller that has ALREADY clipped to [path] (saving a clip
  /// when the part clips for its own detail anyway): only the strokes.
  static void edgeIn(
    Canvas c,
    Path path,
    KingCooTone tone, {
    double width = .09,
    double shift = .06,
    double sky = 1,
    double warm = 1,
  }) {
    final rim = tone.skyRim * sky, bounce = tone.warmRim * warm;
    if (rim > .01) {
      // A stroke of the outline shifted inward on the upper-right side
      // leaves a crescent of it along the edge that faces the moon.
      c.save();
      c.translate(-shift * .75, shift * .75);
      final wide = 1 + tone.dark * .7;
      c.drawPath(path, line(tone.lit(tone.sky), width * wide, rim));
      c.restore();
    }
    if (bounce > .01) {
      c.save();
      c.translate(shift * .6, -shift * .6);
      c.drawPath(
        path,
        line(KingCooPalette.rimWarm, width * 1.1, bounce * .7),
      );
      c.restore();
    }
  }

  /// The siren's light on a shape under it: a band of the siren's colour along
  /// the TOP edge of [path] (the light is on the cap above), clipped to it,
  /// fading with [KingCooTone.sirenGlow]. One clipPath and one stroke; nothing
  /// while the siren is off.
  static void sirenRim(
    Canvas c,
    Path path,
    KingCooTone tone, {
    double width = .10,
    double shift = .06,
  }) {
    final glow = tone.sirenGlow;
    if (glow <= .05 || tone.siren == 0) return;
    c.save();
    c.clipPath(path, doAntiAlias: false);
    c.translate(0, shift);
    c.drawPath(path, line(tone.lit(tone.sirenColor), width, (.75 * glow).clamp(0.0, .75)));
    c.restore();
  }

  /// The outer contour of a hero shape: full [width] on the shade side
  /// (lower left, away from the moon), thinner on the lit side. Two strokes,
  /// no clip.
  static void inkHero(Canvas c, Path path, [double width = .10]) {
    c.drawPath(path, line(KingCooPalette.ink, width * .78));
    c.save();
    c.translate(-width * .14, width * .16);
    c.drawPath(path, line(KingCooPalette.ink, width * .62));
    c.restore();
  }

  /// Ambient occlusion: a [width] band of the feather core laid along [edge],
  /// clipped to [into], where two parts meet (wing root over back, ruff over
  /// chest, cap over skull).
  static void occlude(
    Canvas c,
    Path into,
    Path edge, {
    double width = .16,
    double alpha = .4,
  }) {
    c.save();
    c.clipPath(into, doAntiAlias: false);
    c.drawPath(edge, line(KingCooPalette.featherCore, width, alpha));
    c.restore();
  }

  // ------------------------------------------------------------- helpers --

  static Offset polar(double angle, double r) =>
      Offset(math.cos(angle), math.sin(angle)) * r;

  /// [v] turned by [angle] radians (clockwise on screen).
  static Offset turn(Offset v, double angle) {
    final cs = math.cos(angle), sn = math.sin(angle);
    return Offset(v.dx * cs - v.dy * sn, v.dx * sn + v.dy * cs);
  }

  static double mix(double a, double b, double t) => a + (b - a) * t;

  /// 0..1 through [from]..[to] (clamped).
  static double ramp(double v, double from, double to) =>
      ((v - from) / (to - from)).clamp(0.0, 1.0);

  /// Smoothstep of [t] in 0..1.
  static double ease(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// A deterministic 0..1 value for slot [i] and [salt] (no `Random`).
  static double hash(int i, [int salt = 0]) =>
      ((i * 7919 + salt * 104729 + 13) * 2654435761 % 1000003) / 1000003;

  /// [color] pulled toward the ink by [amount] (0 = ink, 1 = untouched): the
  /// far-side shapes stay saturated instead of turning to mud.
  static Color shade(Color color, double amount) => Color.lerp(
    Color.lerp(KingCooPalette.featherCore, KingCooPalette.ink, .4)!,
    color,
    amount,
  )!;
}
