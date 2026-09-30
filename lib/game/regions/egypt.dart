import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// One band's cached sand art: flat paths as (path, colour, stroke width; 0
/// fills), where the standing things (rocks, scrub, camp) start in that list,
/// the dune crests that shed blown sand and the animated spots.
typedef _DuneArt = (
  List<(Path, Color, double)>,
  int,
  List<(double, double, double)>,
  List<(double, double, double)>,
);

/// The temple's palette, tinted by [haze] toward the desert horizon.
class _TempleInk {
  _TempleInk(double haze)
    : litTop = _tint(const Color(0xfffbe8bd), haze),
      lit = _tint(const Color(0xfff3d7a3), haze),
      litLow = _tint(const Color(0xffe6b985), haze),
      faceTop = _tint(const Color(0xffeacb98), haze),
      face = _tint(const Color(0xffdfb27b), haze),
      faceLow = _tint(const Color(0xffd7a26b), haze),
      shade = _tint(const Color(0xffb98455), haze),
      deep = _tint(const Color(0xff6f4a35), haze),
      groove = _tint(const Color(0xffa06d42), haze),
      mast = _tint(const Color(0xff7b5a40), haze),
      red = _tint(const Color(0xffb85443), haze),
      blue = _tint(const Color(0xff3f86ae), haze),
      gold = _tint(const Color(0xffe3b23e), haze),
      cloth = _tint(const Color(0xfff8f0de), haze),
      gr = _tint(const Color(0xffd39a7c), haze),
      grLit = _tint(const Color(0xffe9bb9c), haze),
      grShade = _tint(const Color(0xffb07359), haze),
      grDeep = _tint(const Color(0xff86523f), haze),
      gild = _tint(const Color(0xfffbdd85), haze),
      gildShade = _tint(const Color(0xffe0a53f), haze),
      trunk = _tint(const Color(0xffb48c68), haze),
      trunkShade = _tint(const Color(0xff9a7456), haze),
      frond = _tint(const Color(0xff6f9a5a), haze),
      frondLit = _tint(const Color(0xff8fb46a), haze);

  final Color litTop, lit, litLow, faceTop, face, faceLow, shade, deep, groove;
  final Color mast, red, blue, gold, cloth, gr, grLit, grShade, grDeep;
  final Color gild, gildShade, trunk, trunkShade, frond, frondLit;

  static Color _tint(Color c, double t) => Sketch.mix(c, EgyptScene._haze, t);
}

/// Egypt at a hot, clear afternoon: the Giza pyramids and the Sphinx on the
/// desert horizon, a temple pylon flanked by obelisks on the dunes, the Nile
/// lined with date palms and green fields, feluccas under lateen sails and
/// papyrus on the near bank. Wind-blown sand and heat shimmer.
class EgyptScene extends RegionScene {
  const EgyptScene();

  @override
  WorldRegion get region => WorldRegion.egypt;

  @override
  double get horizon => .66;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.8, .19),
    radius: .062,
    disc: Color(0xfffffdf3),
    glow: Color(0xfffff0d2),
    halo: .5,
    strength: .4,
  );

  static final _weather = Weather(Weather.of([(Mote.sand, 26)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xfff1cf9c);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xfff0d7a8),
      Color(0xffe9c793),
      Color(0xfffcebc9),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xffe9ba7c),
      Color(0xffd79b5d),
      Color(0xfffce6ba),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xff78b8bd),
      Color(0xff4f96a6),
      Color(0xffd6f0e6),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xffe6b878),
      Color(0xffc4864f),
      Color(0xfffadcaa),
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far =>
      .646 + Sketch.waves(x, const [(3.1, .008, .4), (1.3, .004, 2.1)]),
    Depth.mid =>
      .752 -
          _duneSwell(x) *
              (.055 * dune(x / 1.7 + .2) +
                  .02 * dune(x / .83 + .5) +
                  .007 * dune(x / .37 + .1)) +
          Sketch.waves(x, const [(2.3, .003, 1.1)]),
    Depth.low => .806 + Sketch.waves(x, const [(.8, .0015, 0)]),
    Depth.near =>
      .945 -
          .042 * dune(x / 1.6, 2) -
          .012 * dune(x / .8 + .3, 4) -
          .005 * dune(x / .4 + .6, 8),
  };

  @override
  double period(Depth d) => d == Depth.low ? 2.4 : 3.2;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .3,
    Depth.mid => .32,
    Depth.low => .22,
    Depth.near => .5,
  };

  /// The mid dunes calm down around the temple and swell toward the right.
  static double _duneSwell(double x) {
    final t = ((x - .5) / .9).clamp(0.0, 1.0);
    return .4 + .6 * t * t * (3 - 2 * t);
  }

  /// A dune profile in 0..1, repeating every unit. The wind blows leftward:
  /// a steep slip face climbs to a knife-edged brink, then the long windward
  /// back rolls off to the next trough. Every dune gets its own height and
  /// brink position from its index; [wrap] repeats those seeds after that many
  /// dunes so a distance-scrolled band still tiles.
  static double dune(double x, [int wrap = 0]) {
    final k = x.floor();
    final p = x - k;
    final s = wrap > 0 ? k % wrap : k;
    final brink = .2 + .14 * Sketch.hash(s + 31);
    final tall = .66 + .34 * Sketch.hash(s + 7);
    final double v;
    if (p < brink) {
      v = math.pow(p / brink, 1.8).toDouble();
    } else {
      final u = (p - brink) / (1 - brink);
      v = 1 - (u * u * (3 - 2 * u) * .86 + u * .14);
    }
    return v * tall;
  }

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _pyramids(c, w * .535, h, w);
      case Depth.mid:
        _temple(c, w * .17, h);
        for (final (fx, s) in const [(.47, 1.0), (.52, .82), (.9, .9)]) {
          _duneTuft(c, Offset(w * fx, h * .73), h * .03 * s);
        }
      case Depth.low:
        _bank(c, h);
      case Depth.near:
        _reedShore(c, h, period(d) * h);
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    switch (d) {
      case Depth.mid:
        _templeFlags(c, f);
        _templeSmoke(c, f);
      case Depth.near:
        _reedLive(c, f);
      // The feluccas sail the river itself, in `_nileOverlay`.
      case Depth.far:
      case Depth.low:
        break;
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    switch (d) {
      case Depth.far:
        _duneOverlay(c, d, f, presence);
      case Depth.low:
        _nileOverlay(c, f, presence);
      case Depth.near:
        _duneOverlay(c, d, f, presence);
        _reedFront(c, f, presence);
      case Depth.mid:
        _duneOverlay(c, d, f, presence);
    }
  }

  // ---------------------------------------------------------------------------
  // Dunes. Each band's sand detail is built once per viewport as a handful of
  // flat paths (shade wedges, sunlit shoulders, wind ripples, rocks, scrub, a
  // tent) and replayed by `_duneOverlay`; only the caravan's legs, the sand
  // streaming off the crests, glitter and heat shimmer move.

  static const _duneShadeTone = Color(0xffb0644a);
  static const _duneCoreTone = Color(0xff924b3f);
  static const _duneLightTone = Color(0xfffff2d4);
  static const _duneDarkTone = Color(0xffa96b3f);

  static final _duneArts = <(Depth, double, double), _DuneArt>{};
  static final _dunePaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _duneScratch = Path();
  static final _duneLegs = Path();

  _DuneArt _duneArt(Depth d, double w, double h) {
    final key = (d, w, h);
    final cached = _duneArts[key];
    if (cached != null) return cached;
    if (_duneArts.length > 12) _duneArts.remove(_duneArts.keys.first);
    return _duneArts[key] = _duneBuild(d, w, h);
  }

  /// A second, hazier row of dunes in front of the Giza plateau.
  static double _duneFold(double x) =>
      .695 - .02 * dune(x / 1.15 + .35) - .008 * dune(x / .46 + .6);

  /// Paints one band's sand: the cached paths, then whatever moves.
  void _duneOverlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    final (layers, objects, crests, spots) = _duneArt(d, f.w, h);
    // Standing things fade faster than the surface they stand on, so they
    // never hang over a ridge that is morphing into the next region.
    final solid = presence * presence * presence;
    for (var i = 0; i < layers.length; i++) {
      final (path, color, width) = layers[i];
      _dunePaint
        ..style = width > 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = width
        ..color = Sketch.fade(color, i < objects ? presence : solid);
      c.drawPath(path, _dunePaint);
    }
    switch (d) {
      case Depth.far:
        _duneShimmer(c, f, presence);
      case Depth.mid:
        _dunePlumes(c, crests, f, solid, .075, 1);
        _duneCaravan(c, spots, f, solid);
      case Depth.near:
        _dunePlumes(c, crests, f, solid, .11, -1);
        _duneGlitter(c, spots, f, solid);
      case Depth.low:
        break;
    }
  }

  _DuneArt _duneBuild(Depth d, double w, double h) {
    final far = d == Depth.far, near = d == Depth.near;
    final x0 = near ? 0.0 : -.3;
    final x1 = near ? period(d) : w / h + 1.0;
    double y(double x) => far ? _duneFold(x) : ridge(d, x, 0);
    // Contrast falls with distance; the far haze pulls colours together.
    final k = far ? .55 : (near ? 1.0 : .9);
    final haze = far ? .42 : (near ? 0.0 : .2);
    final layers = <(Path, Color, double)>[];
    void add(Path p, Color color, [double width = 0]) =>
        layers.add((p, color, width));
    final shade = Path(), core = Path(), lit = Path();
    final crests = _duneFaces(
      shade,
      core,
      lit,
      y,
      x0,
      x1,
      h,
      far ? .016 : (near ? .045 : .04),
    );
    if (far) {
      _duneEscarpment(layers, x0, x1, h);
      final fold = Path()..moveTo(x0 * h, h * .84);
      for (var x = x0; x <= x1; x += .01) {
        fold.lineTo(x * h, y(x) * h);
      }
      fold
        ..lineTo(x1 * h, h * .84)
        ..close();
      add(fold, const Color(0xd8f7e4bb));
    }
    add(shade, _duneShadeTone.withValues(alpha: .4 * k));
    add(core, _duneCoreTone.withValues(alpha: .3 * k));
    add(lit, _duneLightTone.withValues(alpha: .36 * k));
    final rippleLight = Path(), rippleDark = Path();
    _duneRipples(
      rippleLight,
      rippleDark,
      y,
      x0,
      x1,
      h,
      far
          ? const [.008, .016, .025]
          : (near
                ? const [.012, .024, .038, .053, .07, .088]
                : const [.008, .016, .025, .035, .046]),
      far ? .045 : (near ? .085 : .06),
      far ? .0016 : (near ? .0032 : .0021),
      far ? .74 : (near ? .995 : .786),
      far ? 21 : (near ? 3 : 11),
    );
    add(rippleDark, _duneDarkTone.withValues(alpha: .3 * k));
    add(rippleLight, _duneLightTone.withValues(alpha: .55 * k));
    final spots = <(double, double, double)>[];
    var objects = layers.length;
    if (far) {
      final rim = Path();
      for (var x = x0; x <= x1; x += .01) {
        if (x == x0) {
          rim.moveTo(x * h, y(x) * h);
        } else {
          rim.lineTo(x * h, y(x) * h);
        }
      }
      add(rim, _duneLightTone.withValues(alpha: .5), h * .0022);
      objects = layers.length;
      _duneScatter(layers, y, x0, x1, h, haze, far: true);
    } else {
      objects = layers.length;
      _duneScatter(layers, y, x0, x1, h, haze, far: false, near: near);
      if (near) {
        _duneTracks(layers, y, h);
        for (var i = 0; i < 12; i++) {
          final x = x1 * (i + .2 + .6 * Sketch.hash(i + 500)) / 12;
          spots.add((
            x * h,
            (y(x) + .022 + .07 * Sketch.hash(i + 520)) * h,
            Sketch.hash(i + 540),
          ));
        }
      } else {
        _duneCamp(layers, spots, y, h, haze);
      }
    }
    return (layers, objects, crests, spots);
  }

  /// The shaded face of the Giza plateau's edge: a jagged band of shadow
  /// under the horizon line and a light course of limestone along it.
  void _duneEscarpment(
    List<(Path, Color, double)> layers,
    double x0,
    double x1,
    double h,
  ) {
    final band = Path(), course = Path();
    double edge(double x) => ridge(Depth.far, x, 0);
    double drop(double x) =>
        .008 + .003 * math.sin(x * 31) + .003 * math.sin(x * 77 + 1);
    band.moveTo(x0 * h, edge(x0) * h);
    for (var x = x0; x <= x1; x += .01) {
      band.lineTo(x * h, edge(x) * h);
    }
    for (var x = x1; x >= x0; x -= .01) {
      band.lineTo(x * h, (edge(x) + drop(x)) * h);
    }
    band.close();
    for (var x = x0, i = 0; x < x1; i++) {
      final len = .03 + .05 * Sketch.hash(i + 860);
      final y0 = (edge(x) + .0045) * h, y1 = (edge(x + len) + .0045) * h;
      course
        ..moveTo(x * h, y0)
        ..lineTo((x + len) * h, y1);
      x += len + .02 + .06 * Sketch.hash(i + 890);
    }
    layers
      ..add((band, _duneShadeTone.withValues(alpha: .17), 0))
      ..add((course, _duneLightTone.withValues(alpha: .42), h * .0018));
  }

  /// Shade wedges under every slip face of [y], the darker core tucked under
  /// each brink and the sunlit shoulder on every windward back. Returns the
  /// brinks (x, y, strength) whose crest lies in [x0, x1).
  List<(double, double, double)> _duneFaces(
    Path shade,
    Path core,
    Path lit,
    double Function(double) y,
    double x0,
    double x1,
    double h,
    double thick,
  ) {
    const step = .005;
    final lo = x0 - .7, n = ((x1 + .7 - lo) / step).ceil();
    final xs = [for (var i = 0; i <= n; i++) lo + i * step];
    final ys = [for (final x in xs) y(x)];
    double slope(int i) =>
        (ys[math.min(n, i + 1)] - ys[math.max(0, i - 1)]) / (2 * step);
    final crests = <(double, double, double)>[];
    var i = 1;
    while (i < n) {
      final s = slope(i);
      if (s > -.018 && s < .022) {
        i++;
        continue;
      }
      final rising = s <= -.018;
      final a = i;
      while (i < n && (rising ? slope(i) <= -.018 : slope(i) >= .022)) {
        i++;
      }
      final b = i - 1, len = b - a;
      final rise = (ys[a] - ys[b]).abs();
      if (len < 8 || rise < .005) continue;
      final strength = (rise / .04).clamp(.35, 1.0);
      if (rising) {
        if (xs[b] < x0 || xs[b] >= x1) continue;
        crests.add((xs[b] * h, ys[b] * h, strength));
        final t = thick * strength;
        shade.moveTo(xs[a] * h, ys[a] * h);
        for (var j = a + 1; j <= b; j++) {
          shade.lineTo(xs[j] * h, ys[j] * h);
        }
        for (var j = b; j >= a; j--) {
          final u = (j - a) / len;
          final wobble = 1 + .1 * math.sin(u * 9 + xs[a] * 13);
          shade.lineTo(
            xs[j] * h,
            (ys[j] + t * math.sin(math.pi * math.pow(u, 2.1)) * wobble) * h,
          );
        }
        shade.close();
        final j0 = a + (len * .3).round();
        core.moveTo(xs[j0] * h, ys[j0] * h);
        for (var j = j0 + 1; j <= b; j++) {
          core.lineTo(xs[j] * h, ys[j] * h);
        }
        for (var j = b; j >= j0; j--) {
          final u = (j - j0) / (b - j0);
          core.lineTo(
            xs[j] * h,
            (ys[j] + t * .55 * math.sin(math.pi * math.pow(u, 1.6))) * h,
          );
        }
        core.close();
      } else {
        if (xs[a] < x0 || xs[a] >= x1) continue;
        final tl = thick * .5 * strength;
        lit.moveTo(xs[a] * h, ys[a] * h);
        for (var j = a + 1; j <= b; j++) {
          lit.lineTo(xs[j] * h, ys[j] * h);
        }
        for (var j = b; j >= a; j--) {
          final u = (j - a) / len;
          lit.lineTo(
            xs[j] * h,
            (ys[j] + tl * math.sin(math.pi * math.pow(u, .6))) * h,
          );
        }
        lit.close();
      }
    }
    return crests;
  }

  /// Broken rows of wind ripples that follow the contour of every windward
  /// back: each is a slim tapered lens, a light one on the crest of the
  /// ripple and a thinner shadow just under it. [wide] is the lens thickness
  /// in viewport heights.
  void _duneRipples(
    Path light,
    Path dark,
    double Function(double) y,
    double x0,
    double x1,
    double h,
    List<double> rows,
    double reach,
    double wide,
    double limit,
    int seed,
  ) {
    double slope(double x) => (y(x + .004) - y(x - .004)) / .008;
    void lens(Path path, double xa, double xb, double o, double th) {
      final xm = (xa + xb) / 2;
      final ya = y(xa) + o, ym = y(xm) + o, yb = y(xb) + o;
      final mid = 2 * ym - (ya + yb) / 2;
      path
        ..moveTo(xa * h, ya * h)
        ..quadraticBezierTo(xm * h, (mid - th) * h, xb * h, yb * h)
        ..quadraticBezierTo(xm * h, (mid + th * .35) * h, xa * h, ya * h);
    }

    for (var j = 0; j < rows.length; j++) {
      var x = x0 + Sketch.hash(seed + j) * reach;
      for (var n = 0; x < x1; n++) {
        final r1 = Sketch.hash(seed * 31 + j * 97 + n);
        final r2 = Sketch.hash(seed * 17 + j * 57 + n + 5000);
        final r3 = Sketch.hash(seed * 7 + j * 41 + n + 9000);
        final len = reach * (.5 + 1.0 * r1);
        final xa = x, xb = math.min(x + len, x1), xm = (xa + xb) / 2;
        x = xb + reach * (.25 + 1.0 * r2);
        if (slope(xa) < -.02 || slope(xm) < -.02 || slope(xb) < -.02) continue;
        final o =
            rows[j] * (1 + .1 * math.sin(xm * 13 + j)) + (r3 - .5) * wide * 1.6;
        if (y(xm) + o > limit) continue;
        final th = wide * (.6 + .8 * r2) * 1.5;
        lens(light, xa, xb, o, th);
        lens(dark, xa + len * .12, xb - len * .12, o + wide * 1.5, th * .8);
      }
    }
  }

  /// Rocks, dry scrub and grass tufts scattered on a band's sand.
  void _duneScatter(
    List<(Path, Color, double)> layers,
    double Function(double) y,
    double x0,
    double x1,
    double h,
    double haze, {
    required bool far,
    bool near = false,
  }) {
    final rockShadow = Path(),
        rock = Path(),
        facet = Path(),
        edge = Path(),
        twig = Path(),
        leaf = Path(),
        bladeDark = Path(),
        bladeLight = Path(),
        bushShadow = Path();
    final span = x1 - x0;
    final rocks = far ? 0 : (near ? 4 : 7);
    for (var i = 0; i < rocks; i++) {
      final x = x0 + span * (i + .25 + .5 * Sketch.hash(i + 610)) / rocks;
      final r = Sketch.hash(i + 620), q = Sketch.hash(i + 630);
      final s = h * (near ? .024 + .018 * r : .007 + .007 * r);
      final oy = near ? .03 + .05 * q : .012 + .02 * q;
      final at = Offset(x * h, (y(x) + oy) * h);
      _duneRock(rockShadow, rock, facet, edge, at, s, i);
      if (near && i.isEven) {
        // A small companion boulder.
        final beside = at + Offset(s * 1.9, s * .25);
        _duneRock(rockShadow, rock, facet, edge, beside, s * .5, i + 40);
      }
    }
    final bushes = far ? 9 : (near ? 4 : 13);
    for (var i = 0; i < bushes; i++) {
      final x = x0 + span * (i + .1 + .8 * Sketch.hash(i + 650)) / bushes;
      final q = Sketch.hash(i + 660);
      final oy = far
          ? .012 + .03 * q
          : (near ? .028 + .05 * q : .014 + .024 * q);
      final s =
          h *
          (far ? .008 : (near ? .05 : .017)) *
          (.7 + .5 * Sketch.hash(i + 670));
      final by = (y(x) + oy) * h;
      if (i.isOdd || far) {
        _duneBlades(bladeDark, bladeLight, x * h, by, s, i);
        bushShadow.addOval(
          Rect.fromCenter(
            center: Offset(x * h - s * .3, by + s * .05),
            width: s * 1.8,
            height: s * .3,
          ),
        );
      } else {
        _duneShrub(twig, leaf, x * h, by, s, i);
        bushShadow.addOval(
          Rect.fromCenter(
            center: Offset(x * h - s * .4, by + s * .06),
            width: s * 2.2,
            height: s * .34,
          ),
        );
      }
    }
    final u = near ? 1.0 : (far ? .5 : .8);
    final wide = h * (near ? .004 : .0028);
    layers
      ..add((bushShadow, _duneShadeTone.withValues(alpha: .34 * u), 0))
      ..add((rockShadow, _duneShadeTone.withValues(alpha: .4 * u), 0))
      ..add((rock, _hazed(const Color(0xff9a6c4e), haze), 0))
      ..add((facet, _hazed(const Color(0xffd6a878), haze), 0))
      ..add((edge, _duneLightTone.withValues(alpha: .55 * u), h * .0022))
      ..add((twig, _hazed(const Color(0xff7b6540), haze), wide))
      ..add((leaf, _hazed(const Color(0xffa6a35e), haze), wide * 1.4))
      ..add((bladeDark, _hazed(const Color(0xff8b8646), haze), wide))
      ..add((bladeLight, _hazed(const Color(0xffc6bf7a), haze), wide * .65));
  }

  /// A faceted rock: dark body, sunlit right flank, bright top edge and a
  /// shadow pooled to its left.
  static void _duneRock(
    Path shadow,
    Path body,
    Path facet,
    Path edge,
    Offset at,
    double s,
    int seed,
  ) {
    double j(int i) => .86 + .28 * Sketch.hash(seed * 7 + i);
    body.addPath(
      Sketch.poly(
        [
          -1.0, 0, -.98, -.3 * j(0), -.72, -.62 * j(1), -.3, -.9 * j(2), //
          .1, -j(3), .5, -.8 * j(4), .86, -.42 * j(5), 1.0, 0,
        ],
        at: at,
        s: s,
      ),
      Offset.zero,
    );
    facet.addPath(
      Sketch.poly(
        [
          .1, -j(3), .5, -.8 * j(4), .86, -.42 * j(5), 1.0, 0, //
          .46, 0, .42, -.36, .02, -.6,
        ],
        at: at,
        s: s,
      ),
      Offset.zero,
    );
    edge
      ..moveTo(at.dx - s * .3, at.dy - s * .9 * j(2))
      ..lineTo(at.dx + s * .1, at.dy - s * j(3))
      ..lineTo(at.dx + s * .5, at.dy - s * .8 * j(4))
      ..lineTo(at.dx + s * .86, at.dy - s * .42 * j(5));
    shadow.addOval(
      Rect.fromCenter(
        center: at + Offset(-s * .75, s * .04),
        width: s * 2.8,
        height: s * .38,
      ),
    );
  }

  /// A dry camel-thorn bush: a fan of bare curved twigs with sparse pale
  /// leaves.
  static void _duneShrub(
    Path twig,
    Path leaf,
    double x,
    double y,
    double s,
    int seed,
  ) {
    for (var i = 0; i < 9; i++) {
      final a = -math.pi * (.06 + .88 * i / 8);
      final len = s * (.7 + .5 * Sketch.hash(seed * 13 + i));
      final dir = Offset(math.cos(a), math.sin(a));
      final bend = (Sketch.hash(seed * 5 + i + 90) - .5) * s * .5;
      final tip = Offset(x + dir.dx * len + bend, y + dir.dy * len * .95);
      twig
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + dir.dx * len * .35 - bend * .3,
          y + dir.dy * len * .6,
          tip.dx,
          tip.dy,
        );
      for (final t in const [.6, .82, 1.0]) {
        final p = Offset.lerp(Offset(x, y), tip, t)!;
        leaf
          ..moveTo(p.dx, p.dy)
          ..lineTo(p.dx + dir.dx * s * .16, p.dy + dir.dy * s * .16);
      }
    }
  }

  /// A clump of dry grass: curved blades in two tones, drawn as strokes.
  static void _duneBlades(
    Path dark,
    Path light,
    double x,
    double y,
    double s,
    int seed,
  ) {
    for (var i = -3; i <= 3; i++) {
      final tall =
          s * (1 - i.abs() * .13) * (.85 + .3 * Sketch.hash(seed * 11 + i + 4));
      final lean = i * s * .34 + (Sketch.hash(seed * 3 + i + 40) - .5) * s * .2;
      (i.isEven ? dark : light)
        ..moveTo(x + i * s * .05, y)
        ..quadraticBezierTo(x + lean * .5, y - tall * .6, x + lean, y - tall);
    }
  }

  /// Camel footprints trailing over the near dunes.
  void _duneTracks(
    List<(Path, Color, double)> layers,
    double Function(double) y,
    double h,
  ) {
    final print = Path(), rim = Path();
    final x1 = period(Depth.near);
    for (var i = 0; i < 26; i++) {
      final x = .12 + i * (x1 - .3) / 26;
      final side = i.isEven ? -1.0 : 1.0;
      final py = (y(x) + .05 + .012 * math.sin(x * 4.2) + side * .0055) * h;
      final px = x * h;
      print.addOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: h * .016,
          height: h * .0065,
        ),
      );
      rim.addOval(
        Rect.fromCenter(
          center: Offset(px + h * .0025, py - h * .0018),
          width: h * .011,
          height: h * .0035,
        ),
      );
    }
    layers
      ..add((print, _duneShadeTone.withValues(alpha: .34), 0))
      ..add((rim, _duneLightTone.withValues(alpha: .34), 0));
  }

  /// A goat-hair tent camped on the mid dunes, the worn track running to it,
  /// and the caravan's spots along the crest.
  void _duneCamp(
    List<(Path, Color, double)> layers,
    List<(double, double, double)> spots,
    double Function(double) y,
    double h,
    double haze,
  ) {
    final track = Path();
    for (var i = 0; i <= 40; i++) {
      final x = .8 + i * .018;
      final ty = (y(x) + .024 + .005 * math.sin(x * 11)) * h;
      if (i == 0) {
        track.moveTo(x * h, ty);
      } else {
        track.lineTo(x * h, ty);
      }
    }
    layers.add((track, _duneDarkTone.withValues(alpha: .26), h * .005));
    final tx = .98 * h, ty = (y(.98) + .012) * h, s = h * .11;
    Offset p(double u, double v) => Offset(tx + u * s, ty + v * s);
    Path poly(List<double> q) => Sketch.poly(q, at: Offset(tx, ty), s: s);
    Path lines(List<(double, double, double, double)> q) {
      final path = Path();
      for (final (a, b, c, d) in q) {
        path
          ..moveTo(p(a, b).dx, p(a, b).dy)
          ..lineTo(p(c, d).dx, p(c, d).dy);
      }
      return path;
    }

    Color tone(int c, [double a = 1]) =>
        _hazed(Color(c), haze).withValues(alpha: a);
    const roof = <double>[
      -.53, -.24, -.44, -.335, -.36, -.36, -.27, -.32, -.18, -.3, -.09, -.34, //
      0,
      -.385,
      .09,
      -.34,
      .18,
      -.3,
      .27,
      -.32,
      .36,
      -.36,
      .44,
      -.335,
      .53,
      -.24,
    ];
    final cloth = Path()
      ..moveTo(p(-.55, 0).dx, p(-.55, 0).dy)
      ..lineTo(p(-.53, -.24).dx, p(-.53, -.24).dy);
    _duneArc(cloth, roof, tx, ty, s);
    cloth
      ..lineTo(p(.55, 0).dx, p(.55, 0).dy)
      ..close();
    final crown = Path()..moveTo(p(-.53, -.24).dx, p(-.53, -.24).dy);
    _duneArc(crown, roof, tx, ty, s);
    layers
      ..add((
        Path()..addOval(
          Rect.fromCenter(center: p(-.5, .02), width: s * 1.5, height: s * .12),
        ),
        _duneShadeTone.withValues(alpha: .38),
        0,
      ))
      // The goat-hair cloth: long, low, lifted on three poles.
      ..add((cloth, tone(0xff4b382b), 0))
      // The open front: a dark interior under the raised awning.
      ..add((
        poly(const [
          -.41,
          0,
          -.41,
          -.2,
          -.2,
          -.24,
          0,
          -.2,
          .2,
          -.24,
          .41,
          -.2,
          .41,
          0,
        ]),
        tone(0xff32231a),
        0,
      ))
      // The sunlit crown of the roof and the woven stripes on the awning.
      ..add((crown, tone(0xff8a6a4c), s * .05))
      ..add((
        lines(const [
          (-.5, -.16, -.44, -.2),
          (-.3, -.22, -.24, -.25),
          (.24, -.25, .3, -.22),
          (.44, -.2, .5, -.16),
        ]),
        tone(0xffb08a5e, .7),
        h * .0016,
      ))
      ..add((
        lines(const [(-.41, -.2, -.41, 0), (.41, -.2, .41, 0), (0, -.2, 0, 0)]),
        tone(0xff5a4131),
        h * .0022,
      ))
      ..add((
        lines(const [(-.53, -.24, -.8, .01), (.53, -.24, .8, .01)]),
        tone(0xff4c3729, .75),
        h * .0012,
      ))
      ..add((
        poly(const [-.3, .012, .3, .012, .34, .065, -.34, .065]),
        tone(0xffa7513b),
        0,
      ))
      ..add((
        lines(const [(-.2, .03, .2, .03), (-.24, .05, .24, .05)]),
        tone(0xffe4c589, .8),
        h * .0014,
      ));
    // The caravan is baked: a leader on foot, five camels along the crest and
    // one kneeling by the tent. Only the legs move (`_duneCaravan`).
    final shadows = Path(), body = Path(), belly = Path(), sheen = Path();
    final robe = Path(), wrap = Path(), staff = Path(), tail = Path();
    final loads = [Path(), Path(), Path()];
    final sc = h * .054;
    for (var i = 0; i < 7; i++) {
      final resting = i == 6;
      final x = resting ? 1.14 : 1.66 - i * .066 - (i == 0 ? 0 : .03);
      final a = (math.atan2(y(x + .012) - y(x - .012), .024) * .85).clamp(
        -.4,
        .4,
      );
      final at = Offset(x * h, y(x) * h + h * (resting ? .003 : .0025));
      shadows.addOval(
        Rect.fromCenter(
          center: at + Offset(resting ? h * .012 : -h * .02, h * .003),
          width: h * (i == 0 ? .03 : (resting ? .085 : .075)),
          height: h * .009,
        ),
      );
      if (resting) {
        // Kneeling and facing the tent.
        final m = _duneMatrix(at.dx, at.dy, a, -sc, sc);
        body.addPath(_duneKneeling, Offset.zero, matrix4: m);
        belly.addPath(_duneFolded, Offset.zero, matrix4: m);
        continue;
      }
      spots.add((at.dx, at.dy, a.toDouble()));
      final m = _duneMatrix(at.dx, at.dy, a, sc, sc);
      Float64List at2(double u, double v, [double flip = 1]) {
        final p = _duneAt(m, u, v);
        return _duneMatrix(p.dx, p.dy, a, sc, sc);
      }

      if (i == 0) {
        robe.addPath(_duneRobe, Offset.zero, matrix4: m);
        wrap.addPath(_duneHead, Offset.zero, matrix4: at2(0, -.72));
        final p0 = _duneAt(m, .11, -.02), p1 = _duneAt(m, .14, -.82);
        staff
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy);
        continue;
      }
      body.addPath(_duneCamel, Offset.zero, matrix4: m);
      belly.addPath(_duneBelly, Offset.zero, matrix4: m);
      sheen.addPath(_duneCamelTop, Offset.zero, matrix4: m);
      final t0 = _duneAt(m, -.51, -.58), t1 = _duneAt(m, -.6, -.36);
      tail
        ..moveTo(t0.dx, t0.dy)
        ..lineTo(t1.dx, t1.dy);
      if (i.isOdd) {
        loads[i ~/ 2 % 3].addPath(_duneLoad, Offset.zero, matrix4: m);
      }
      if (i == 2 || i == 4) {
        robe.addPath(_duneRobe, Offset.zero, matrix4: at2(-.02, -.04));
        wrap.addPath(_duneHead, Offset.zero, matrix4: at2(-.02, -.82));
      }
    }
    layers
      ..add((shadows, _duneShadeTone.withValues(alpha: .36), 0))
      ..add((body, _hazed(const Color(0xff8a5d3f), .2), 0))
      ..add((belly, _hazed(const Color(0xff65422c), .2), 0))
      ..add((sheen, _hazed(const Color(0xffb98a5c), .2), 0))
      ..add((tail, _hazed(const Color(0xff65422c), .2), sc * .03))
      ..add((loads[0], _hazed(const Color(0xffb3573f), .15), 0))
      ..add((loads[1], _hazed(const Color(0xff3f7f86), .15), 0))
      ..add((loads[2], _hazed(const Color(0xffc79a4a), .15), 0))
      ..add((robe, _hazed(const Color(0xffe9dcc0), .1), 0))
      ..add((wrap, _hazed(const Color(0xff2f2b3a), .2), 0))
      ..add((staff, _hazed(const Color(0xff65422c), .2), sc * .02));
    _duneOutcrop(layers, Offset(.7 * h, (y(.7) + .02) * h), h * .05, haze);
    _duneAcacia(layers, Offset(2.05 * h, (y(2.05) + .022) * h), h * .13, haze);
  }

  /// Appends a smooth curve through [xy] (pairs in units of [s] around
  /// ([ox], [oy])) to a path already standing on the first point.
  static void _duneArc(
    Path path,
    List<double> xy,
    double ox,
    double oy,
    double s,
  ) {
    Offset at(int i) {
      final k = i.clamp(0, xy.length ~/ 2 - 1);
      return Offset(ox + xy[k * 2] * s, oy + xy[k * 2 + 1] * s);
    }

    for (var i = 0; i < xy.length ~/ 2 - 1; i++) {
      final a = at(i - 1), b = at(i), c = at(i + 1), d = at(i + 2);
      final c1 = b + (c - a) / 6, c2 = c - (d - b) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, c.dx, c.dy);
    }
  }

  /// A lone flat-topped acacia: a leaning trunk, forked branches and a
  /// layered crown of olive foliage.
  void _duneAcacia(
    List<(Path, Color, double)> layers,
    Offset at,
    double s,
    double haze,
  ) {
    Offset p(double u, double v) => at + Offset(u * s, v * s);
    final trunk = Path()
      ..moveTo(p(0, 0).dx, p(0, 0).dy)
      ..quadraticBezierTo(
        p(-.07, -.28).dx,
        p(-.07, -.28).dy,
        p(-.02, -.52).dx,
        p(-.02, -.52).dy,
      )
      ..moveTo(p(-.02, -.52).dx, p(-.02, -.52).dy)
      ..quadraticBezierTo(
        p(-.2, -.6).dx,
        p(-.2, -.6).dy,
        p(-.36, -.7).dx,
        p(-.36, -.7).dy,
      )
      ..moveTo(p(-.02, -.52).dx, p(-.02, -.52).dy)
      ..quadraticBezierTo(
        p(.16, -.6).dx,
        p(.16, -.6).dy,
        p(.36, -.72).dx,
        p(.36, -.72).dy,
      );
    final under = Path(), body = Path(), top = Path();
    for (final (u, v, w, hh) in const [
      (-.4, -.72, .42, .15),
      (-.2, -.8, .46, .17),
      (.02, -.84, .5, .18),
      (.24, -.79, .46, .17),
      (.42, -.73, .38, .14),
    ]) {
      under.addOval(
        Rect.fromCenter(center: p(u, v + .03), width: w * s, height: hh * s),
      );
      body.addOval(
        Rect.fromCenter(center: p(u, v), width: w * s, height: hh * s),
      );
      top.addOval(
        Rect.fromCenter(
          center: p(u + .03, v - .045),
          width: w * .72 * s,
          height: hh * .55 * s,
        ),
      );
    }
    final shadow = Path()
      ..addOval(
        Rect.fromCenter(center: p(-.35, .01), width: s * 1.1, height: s * .08),
      );
    layers
      ..add((shadow, _duneShadeTone.withValues(alpha: .34), 0))
      ..add((trunk, _hazed(const Color(0xff5b4331), haze), s * .06))
      ..add((under, _hazed(const Color(0xff56663a), haze), 0))
      ..add((body, _hazed(const Color(0xff7b8c4c), haze), 0))
      ..add((top, _hazed(const Color(0xffa6b463), haze), 0));
  }

  /// A low sandstone knoll of stepped ledges with a few boulders at its foot.
  void _duneOutcrop(
    List<(Path, Color, double)> layers,
    Offset at,
    double s,
    double haze,
  ) {
    Path poly(List<double> q) => Sketch.poly(q, at: at, s: s);
    final shadow = Path()
      ..addOval(
        Rect.fromCenter(
          center: at + Offset(-s * .5, s * .04),
          width: s * 2.8,
          height: s * .24,
        ),
      );
    final strata = Path();
    for (final (a, b, c) in const [(-.8, -.2, .95), (-.5, -.4, .7)]) {
      strata
        ..moveTo(at.dx + a * s, at.dy + b * s)
        ..lineTo(at.dx + c * s, at.dy + b * s);
    }
    final rocks = Path(), rocksLit = Path(), rocksEdge = Path();
    _duneRock(
      shadow,
      rocks,
      rocksLit,
      rocksEdge,
      at + Offset(s * 1.3, s * .06),
      s * .2,
      3,
    );
    _duneRock(
      shadow,
      rocks,
      rocksLit,
      rocksEdge,
      at + Offset(-s * 1.25, s * .05),
      s * .14,
      8,
    );
    layers
      ..add((shadow, _duneShadeTone.withValues(alpha: .38), 0))
      ..add((
        poly(const [
          -1.0, 0, -.92, -.22, -.7, -.34, -.55, -.5, -.25, -.58, .1, -.55, //
          .35, -.64, .6, -.52, .8, -.3, 1.0, -.14, 1.15, 0,
        ]),
        _hazed(const Color(0xffa27650), haze),
        0,
      ))
      ..add((
        poly(const [
          .1, -.55, .35, -.64, .6, -.52, .8, -.3, 1.0, -.14, 1.15, 0, //
          .55, 0, .5, -.24, .2, -.34,
        ]),
        _hazed(const Color(0xffdcb283), haze),
        0,
      ))
      ..add((
        strata,
        _hazed(const Color(0xff7c5540), haze).withValues(alpha: .45),
        s * .045,
      ))
      ..add((rocks, _hazed(const Color(0xff9a6c4e), haze), 0))
      ..add((rocksLit, _hazed(const Color(0xffd6a878), haze), 0));
  }

  static final _duneHead = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: .05));
  static final _duneFolded = Path()
    ..addOval(const Rect.fromLTWH(-.5, -.12, .95, .12));

  /// translate * rotate * scale as a 4x4 column-major matrix.
  static Float64List _duneMatrix(
    double tx,
    double ty,
    double angle,
    double sx,
    double sy,
  ) {
    final c = math.cos(angle), s = math.sin(angle);
    return Float64List.fromList([
      c * sx, s * sx, 0, 0, //
      -s * sy, c * sy, 0, 0,
      0, 0, 1, 0,
      tx, ty, 0, 1,
    ]);
  }

  static Offset _duneAt(Float64List m, double u, double v) =>
      Offset(m[0] * u + m[4] * v + m[12], m[1] * u + m[5] * v + m[13]);

  static final _duneCamel = Path()
    ..moveTo(-.5, -.6)
    ..cubicTo(-.4, -.66, -.28, -.66, -.18, -.7)
    ..cubicTo(-.12, -.8, -.06, -.94, .02, -.93)
    ..cubicTo(.1, -.92, .14, -.76, .22, -.7)
    ..cubicTo(.34, -.72, .44, -.86, .54, -.98)
    ..cubicTo(.58, -1.04, .66, -1.08, .72, -1.05)
    ..cubicTo(.78, -1.03, .84, -.99, .84, -.95)
    ..cubicTo(.83, -.91, .76, -.91, .7, -.92)
    ..cubicTo(.62, -.86, .52, -.74, .42, -.62)
    ..cubicTo(.38, -.54, .36, -.48, .32, -.45)
    ..cubicTo(.1, -.36, -.16, -.36, -.3, -.42)
    ..cubicTo(-.4, -.4, -.52, -.44, -.53, -.52)
    ..cubicTo(-.54, -.56, -.52, -.58, -.5, -.6)
    ..close();
  static final _duneKneeling = Path()
    ..moveTo(-.5, -.28)
    ..cubicTo(-.42, -.36, -.3, -.38, -.2, -.42)
    ..cubicTo(-.14, -.52, -.08, -.66, 0, -.65)
    ..cubicTo(.08, -.64, .14, -.5, .24, -.44)
    ..cubicTo(.34, -.58, .42, -.82, .5, -.96)
    ..cubicTo(.54, -1.02, .62, -1.05, .68, -1.02)
    ..cubicTo(.74, -1.0, .8, -.96, .8, -.92)
    ..cubicTo(.79, -.88, .72, -.88, .66, -.88)
    ..cubicTo(.6, -.8, .56, -.62, .5, -.46)
    ..cubicTo(.48, -.32, .46, -.2, .4, -.12)
    ..cubicTo(.2, -.06, -.2, -.06, -.42, -.1)
    ..cubicTo(-.54, -.12, -.56, -.22, -.5, -.28)
    ..close();
  static final _duneCamelTop = Path()
    ..moveTo(-.5, -.6)
    ..cubicTo(-.4, -.66, -.28, -.66, -.18, -.7)
    ..cubicTo(-.12, -.8, -.06, -.94, .02, -.93)
    ..cubicTo(.1, -.92, .14, -.76, .22, -.7)
    ..cubicTo(.34, -.72, .44, -.86, .54, -.98)
    ..cubicTo(.58, -1.04, .66, -1.08, .72, -1.05)
    ..cubicTo(.66, -1.03, .6, -1.0, .56, -.94)
    ..cubicTo(.46, -.82, .36, -.68, .24, -.66)
    ..cubicTo(.16, -.72, .12, -.88, .02, -.89)
    ..cubicTo(-.06, -.9, -.12, -.76, -.18, -.66)
    ..cubicTo(-.28, -.62, -.4, -.62, -.5, -.56)
    ..close();
  static final _duneBelly = Path()
    ..moveTo(-.5, -.5)
    ..cubicTo(-.3, -.5, .1, -.5, .38, -.55)
    ..lineTo(.32, -.45)
    ..cubicTo(.1, -.36, -.16, -.36, -.3, -.42)
    ..cubicTo(-.4, -.4, -.52, -.44, -.53, -.52)
    ..close();
  static final _duneLoad = Path()
    ..moveTo(-.26, -.66)
    ..lineTo(-.22, -.84)
    ..quadraticBezierTo(-.06, -.98, .12, -.86)
    ..lineTo(.17, -.68)
    ..close();
  static final _duneRobe = Path()
    ..moveTo(-.09, -.1)
    ..lineTo(-.055, -.58)
    ..lineTo(0, -.66)
    ..lineTo(.05, -.58)
    ..lineTo(.1, -.1)
    ..close();

  /// The caravan's legs: the only part of it that moves. Far legs stay in
  /// shade; the leader's stride shares the near legs' path.
  void _duneCaravan(
    Canvas c,
    List<(double, double, double)> spots,
    SceneFrame f,
    double presence,
  ) {
    final s = f.h * .054;
    final far = _duneScratch..reset();
    final near = _duneLegs..reset();
    for (var i = 0; i < spots.length; i++) {
      final (x, y, a) = spots[i];
      final t = f.clock * 2.6 + i * 1.3;
      final cs = math.cos(a) * s, sn = math.sin(a) * s;
      Offset at(double u, double v) =>
          Offset(x + cs * u - sn * v, y + sn * u + cs * v);
      if (i == 0) {
        for (final side in const [0.0, math.pi]) {
          final foot = at(math.sin(t + side) * .09, 0);
          final hip = at(0, -.12);
          near
            ..moveTo(hip.dx, hip.dy)
            ..lineTo(foot.dx, foot.dy);
        }
        continue;
      }
      for (final isNear in const [false, true]) {
        final path = isNear ? near : far;
        for (final (hx, ph) in const [(-.4, 0.0), (.26, .5)]) {
          final sw = math.sin(t + ph + (isNear ? 0 : math.pi)) * .1;
          final hip = at(hx + (isNear ? .04 : 0), -.42);
          final knee = at(hx + sw * .4 + .02, -.22);
          final foot = at(hx + sw, isNear ? 0 : -.01);
          path
            ..moveTo(hip.dx, hip.dy)
            ..lineTo(knee.dx, knee.dy)
            ..lineTo(foot.dx, foot.dy);
        }
      }
    }
    _dunePaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .055
      ..color = Sketch.fade(_hazed(const Color(0xff65422c), .2), presence);
    c.drawPath(far, _dunePaint);
    _dunePaint.color = Sketch.fade(
      _hazed(const Color(0xff8a5d3f), .2),
      presence,
    );
    c.drawPath(near, _dunePaint);
  }

  /// Sand streaming off the brink of each slip face, thin and slow. [lift]
  /// is 1 to let it fly off the crest into the air and -1 to let it slide
  /// down the face instead.
  void _dunePlumes(
    Canvas c,
    List<(double, double, double)> crests,
    SceneFrame f,
    double presence,
    double reach,
    double lift,
  ) {
    final h = f.h;
    _dunePaint.style = PaintingStyle.fill;
    for (var i = 0; i < crests.length; i++) {
      final (x, y, k) = crests[i];
      final rate = .06 + .05 * Sketch.hash(i + 700);
      final phase = (f.clock * rate + Sketch.hash(i + 710)) % 1.0;
      final on = math.sin(math.pi * phase);
      final alpha = .4 * on * on * k * presence;
      if (alpha < .03) continue;
      final len = h * reach * (.5 + .9 * phase);
      final rise = h * .012 * (.4 + phase) * lift;
      _duneScratch
        ..reset()
        ..moveTo(x, y - h * .004 * lift)
        ..quadraticBezierTo(x - len * .5, y - rise * 1.3, x - len, y - rise)
        ..quadraticBezierTo(
          x - len * .45,
          y - rise * .2,
          x + h * .004,
          y + h * .005,
        )
        ..close();
      _dunePaint.color = Sketch.fade(_duneLightTone, alpha);
      c.drawPath(_duneScratch, _dunePaint);
    }
  }

  /// A few grains of sand catching the sun on the foreground dunes.
  void _duneGlitter(
    Canvas c,
    List<(double, double, double)> spots,
    SceneFrame f,
    double presence,
  ) {
    final h = f.h;
    _duneScratch.reset();
    for (final (x, y, r) in spots) {
      final on = math.sin(f.clock * (1.1 + .9 * r) + r * 40);
      if (on < .55) continue;
      final s = h * .0075 * on;
      _duneScratch
        ..moveTo(x - s, y)
        ..quadraticBezierTo(x, y, x, y - s * 1.5)
        ..quadraticBezierTo(x, y, x + s, y)
        ..quadraticBezierTo(x, y, x, y + s * 1.5)
        ..quadraticBezierTo(x, y, x - s, y);
    }
    _dunePaint
      ..style = PaintingStyle.fill
      ..color = Sketch.fade(const Color(0xfffffaea), .9 * presence);
    c.drawPath(_duneScratch, _dunePaint);
  }

  /// Heat shimmer: faint, wavering lines just above the horizon dunes.
  void _duneShimmer(Canvas c, SceneFrame f, double presence) {
    final h = f.h, time = f.clock;
    _duneScratch.reset();
    for (var i = 0; i < 18; i++) {
      final x = (f.w + h) * Sketch.hash(i + 80) - h * .3;
      final y =
          ridge(Depth.far, x / h, 0) * h -
          h * (.004 + .022 * Sketch.hash(i + 90));
      final wobble = math.sin(time * (1.6 + i * .21) + i * 2);
      final len = h * (.03 + .035 * Sketch.hash(i + 99)) * (.65 + .35 * wobble);
      _duneScratch
        ..moveTo(x - len, y + wobble * h * .0016)
        ..quadraticBezierTo(
          x,
          y - wobble * h * .0036,
          x + len,
          y - wobble * h * .0016,
        );
    }
    _dunePaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .0028
      ..color = Sketch.fade(const Color(0xfffff3da), .3 * presence);
    c.drawPath(_duneScratch, _dunePaint);
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final sun = _afternoonSun(f);
    _afternoonHazeBank(c, f, presence);
    _afternoonMoon(c, f, presence);
    _afternoonCirrus(c, f, presence);
    _afternoonGlare(c, f, sun, presence);
    _afternoonBirds(c, f, presence);
  }

  static const _afternoonCream = Color(0xfffff4dc);

  /// Seconds of drift for the sky, zero halfway through the hold (and always
  /// in Reduced Motion) where every drifting shape is laid out.
  static double _afternoonDrift(SceneFrame f) => f.reducedMotion
      ? 0
      : f.held
      ? f.clock - WorldTour.hold / 2
      : f.clock - 96;

  /// Where the compositor is drawing the sun right now: it slides from one
  /// region's light to the next during a crossing and the glare must follow.
  SkyLight _afternoonSun(SceneFrame f) {
    final blend = f.blend;
    if (!blend.crossing) return light;
    return SkyLight.lerp(
      RegionScene.of(blend.from).light,
      RegionScene.of(blend.to).light,
      blend.stage(0, 1),
    );
  }

  /// The desert sky deepens to a clear blue overhead, bleaches to cream toward
  /// the horizon and sinks into a warm bank of dust, its lid shimmering in
  /// the heat.
  void _afternoonHazeBank(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final zenith = Rect.fromLTRB(0, 0, w, h * .34);
    c.drawRect(
      zenith,
      Paint()
        ..shader = Gradient.linear(zenith.topLeft, zenith.bottomLeft, [
          Sketch.fade(const Color(0xff3f92cc), .3 * presence),
          Sketch.fade(const Color(0xff5aa6d6), 0),
        ]),
    );
    final top = h * .26, bottom = h * .7;
    final sheet = Rect.fromLTRB(0, top, w, bottom);
    c.drawRect(
      sheet,
      Paint()
        ..shader = Gradient.linear(
          sheet.topLeft,
          sheet.bottomLeft,
          [
            Sketch.fade(const Color(0xffe9f4f8), 0),
            Sketch.fade(const Color(0xffe6f2f6), .22 * presence),
            Sketch.fade(const Color(0xfff4f2e6), .38 * presence),
            Sketch.fade(const Color(0xfffdeccc), .5 * presence),
            Sketch.fade(const Color(0xffffe0aa), .58 * presence),
            Sketch.fade(const Color(0xfff6cd96), .56 * presence),
            Sketch.fade(const Color(0xfff1cf9c), .5 * presence),
          ],
          const [0, .227, .409, .591, .727, .877, 1],
        ),
    );
    // The dusty air glows gold on the sun's side of the horizon.
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(w * light.at.dx, h * .6),
        width: h * 1.7,
        height: h * .3,
      ),
      const Color(0xffffd48a),
      .38 * presence,
    );
    // Thin strata of dust drift in the haze, a little faster nearer the ground.
    final dust = Paint(), dustShade = Paint();
    final t = _afternoonDrift(f);
    for (final (fx, fy, size, seed, speed) in const [
      (.1, .5, 1.1, 14, .004),
      (.6, .56, .9, 15, .0055),
    ]) {
      final reach = h * size * 1.35, span = w + reach * 2;
      final x = (w * fx - t * h * speed + reach) % span - reach;
      final path = _afternoonCirrusPath(seed);
      c.save();
      c.translate(x, h * fy);
      c.scale(h * size);
      c.save();
      c.translate(0, -.008);
      c.drawPath(
        path,
        dustShade..color = Sketch.fade(const Color(0xffe0b47a), .16 * presence),
      );
      c.restore();
      c.drawPath(
        path,
        dust..color = Sketch.fade(const Color(0xfffff3d6), .3 * presence),
      );
      c.restore();
    }
    // A lid of dust, its crest wavering slowly with the heat.
    final lid = Path()..moveTo(-h * .1, bottom);
    for (var i = 0; i <= 30; i++) {
      final x = -h * .1 + (w + h * .2) * i / 30;
      final y =
          h *
          (.568 +
              .006 * math.sin(x / h * 3.3 + f.clock * .3) +
              .0035 * math.sin(x / h * 9.1 - f.clock * .55));
      lid.lineTo(x, y);
    }
    lid
      ..lineTo(w + h * .1, bottom)
      ..close();
    c.drawPath(
      lid,
      Paint()
        ..shader = Gradient.linear(Offset(0, h * .56), Offset(0, h * .66), [
          Sketch.fade(const Color(0xfffff0d0), .3 * presence),
          Sketch.fade(const Color(0xffffdca0), .12 * presence),
        ]),
    );
  }

  /// A pale daytime moon, a ghost of a crescent lit from the sun's side.
  void _afternoonMoon(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final at = Offset(f.w * .17, h * .37), r = h * .03;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(-.22);
    c.scale(r);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()..color = Sketch.fade(const Color(0xffffffff), .07 * presence),
    );
    const d = .5;
    final k = math.sqrt(1 - d * d / 4);
    c.drawPath(
      Path()
        ..moveTo(-d / 2, -k)
        ..arcToPoint(
          Offset(-d / 2, k),
          radius: const Radius.circular(1),
          largeArc: true,
        )
        ..arcToPoint(
          Offset(-d / 2, -k),
          radius: const Radius.circular(1),
          clockwise: false,
        )
        ..close(),
      Paint()..color = Sketch.fade(const Color(0xfffffdf6), .55 * presence),
    );
    c.restore();
  }

  /// High cirrus: hooked mares' tails combed by the upper wind, and thin
  /// sheets that drift a little faster the lower they sit. Shapes are built
  /// once in unit size and only translated and scaled each frame.
  void _afternoonCirrus(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // Laid out for the middle of the hold; the drift wraps around the sky.
    final t = _afternoonDrift(f);
    final shade = Paint()
      ..color = Sketch.fade(const Color(0xff9fc3dc), .34 * presence);
    final lit = Paint();
    for (final (fx, fy, size, seed, speed) in const [
      (.03, .08, .42, 1, .0028),
      (.62, .05, .3, 2, .0022),
      (.42, .3, .26, 3, .0034),
      (.3, .19, .5, 12, .0024),
      (.8, .4, .46, 13, .0042),
    ]) {
      final reach = h * size * 1.35, span = w + reach * 2;
      final x = (w * fx - t * h * speed + reach) % span - reach;
      final path = _afternoonCirrusPath(seed);
      c.save();
      c.translate(x, h * fy);
      c.scale(h * size);
      c.save();
      c.translate(.004, .012);
      c.drawPath(path, shade);
      c.restore();
      c.drawPath(
        path,
        lit
          ..color = Sketch.fade(
            const Color(0xfffdfeff),
            (seed >= 10 ? .38 : .46) * presence,
          ),
      );
      c.restore();
    }
  }

  static final _afternoonCirrusCache = <int, Path>{};

  static Path _afternoonCirrusPath(int seed) =>
      _afternoonCirrusCache.putIfAbsent(
        seed,
        () => seed >= 10
            ? _afternoonSheetShape(seed)
            : _afternoonStreakShape(seed),
      );

  /// Fills [path] with a ribbon following [at] over t = 0..1, [width] being
  /// its half thickness there.
  static void _afternoonRibbon(
    Path path,
    Offset Function(double) at,
    double Function(double) width, {
    int steps = 14,
  }) {
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final p = at(t);
      final d = at(math.min(1.0, t + .02)) - at(math.max(0.0, t - .02));
      final n = d.distance == 0
          ? const Offset(0, 1)
          : Offset(-d.dy, d.dx) / d.distance;
      left.add(p + n * width(t));
      right.add(p - n * width(t));
    }
    path.moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
  }

  /// Cirrus uncinus in unit size: streaks with a thick, hooked head trailing
  /// a tail that sweeps down with the wind, and a few finer fibres beside it.
  /// Heads are spaced down the bundle but shifted at random, and tails fan a
  /// little, so no two streaks agree.
  static Path _afternoonStreakShape(int seed) {
    final path = Path();
    final flip = seed.isEven ? -1.0 : 1.0;
    final n = 5 + seed % 2;
    for (var k = 0; k < n; k++) {
      double rnd(int j) => Sketch.hash(seed * 131 + k * 7 + j);
      final head = Offset(
        flip * (.02 + .16 * rnd(1) + k * .015),
        (k + .35 + .5 * rnd(2)) / n * .24,
      );
      final len = .34 + .66 * rnd(3);
      final slope = -.02 + .1 * rnd(8);
      final sag = .12 + .2 * rnd(4);
      final wide = .0075 + .0065 * rnd(5);
      Offset curve(double t, double scale) => Offset(
        flip * len * scale * t,
        len * scale * (slope * t + sag * t * t),
      );
      Offset centre(double t) => head + curve(t, 1);
      _afternoonRibbon(
        path,
        centre,
        (t) =>
            wide *
            math.pow(1 - t, 1.5) *
            (.3 + .7 * math.sqrt(math.min(1, t / .14))),
      );
      // The head curls up and back against the wind, on most streaks.
      if (rnd(9) > .28) {
        final hook = .012 + .012 * rnd(6);
        _afternoonRibbon(
          path,
          (t) {
            final a = t * math.pi * .8;
            return head +
                Offset(-flip * hook * math.sin(a), -hook * (1 - math.cos(a)));
          },
          (t) => wide * .7 * (1 - t),
          steps: 8,
        );
      }
      // Fine fibres drift beside and beyond the main streak.
      for (final (side, reach) in [(-1.7, .7), (2.0, 1.15)]) {
        final start = centre(.2) + Offset(0, side * wide);
        _afternoonRibbon(
          path,
          (t) => start + curve(t, reach * .85),
          (t) => wide * .28 * (1 - t),
          steps: 8,
        );
      }
    }
    return path;
  }

  /// A thin sheet of high cloud in unit size: long, flat lenses that taper to
  /// nothing at both ends, stacked with a little offset.
  static Path _afternoonSheetShape(int seed) {
    final path = Path();
    for (var k = 0; k < 4; k++) {
      double rnd(int j) => Sketch.hash(seed * 97 + k * 11 + j);
      final len = .55 + .45 * rnd(1);
      final x0 = (rnd(2) - .5) * .25 + k * .05;
      final y0 = k * .014 + (rnd(3) - .5) * .008;
      final bow = (rnd(4) - .5) * .02;
      _afternoonRibbon(
        path,
        (t) => Offset(x0 + len * t, y0 + bow * math.sin(math.pi * t)),
        (t) => (.0055 + .005 * rnd(5)) * math.pow(math.sin(math.pi * t), .7),
        steps: 20,
      );
    }
    return path;
  }

  /// The sun in full glare: a bloom that swallows the disc's hard rim, a wide
  /// screened glow, faint rays and the ghost of an ice-crystal halo.
  void _afternoonGlare(Canvas c, SceneFrame f, SkyLight sun, double presence) {
    final k = presence * (1 - sun.moon).clamp(0.0, 1.0);
    if (k <= .01) return;
    final h = f.h;
    final at = Offset(sun.at.dx * f.w, sun.at.dy * h);
    final r = sun.radius * h;
    final reach = h * .95;
    c.drawCircle(
      at,
      reach,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = Gradient.radial(
          at,
          reach,
          [
            Sketch.fade(const Color(0xffffeed0), .34 * k),
            Sketch.fade(const Color(0xffffe2bc), .2 * k),
            Sketch.fade(const Color(0xffffd0a8), .07 * k),
            Sketch.fade(const Color(0xffffd0a8), 0),
          ],
          const [0, .1, .36, 1],
        ),
    );
    // Rays fan out and turn very slowly; some reach far, most stay short.
    final rays = Path();
    final spin = f.clock * .01;
    for (var i = 0; i < 12; i++) {
      final a = spin + i * math.pi * 2 / 12 + (Sketch.hash(i + 300) - .5) * .4;
      final dir = Offset(math.cos(a), math.sin(a));
      final side = Offset(-dir.dy, dir.dx);
      final len = h * (.28 + .5 * math.pow(Sketch.hash(i + 320), 1.6));
      final base = at + dir * r * 1.2;
      final wide = r * (.14 + .12 * Sketch.hash(i + 340));
      rays
        ..moveTo(base.dx + side.dx * wide, base.dy + side.dy * wide)
        ..lineTo(at.dx + dir.dx * len, at.dy + dir.dy * len)
        ..lineTo(base.dx - side.dx * wide, base.dy - side.dy * wide)
        ..close();
    }
    c.drawPath(
      rays,
      Paint()
        ..blendMode = BlendMode.screen
        ..color = Sketch.fade(_afternoonCream, .04 * k),
    );
    // A 22 degree halo: a faint warm rim inside a wider pale band.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.screen;
    c.drawCircle(
      at,
      h * .31,
      ring
        ..strokeWidth = h * .034
        ..color = Sketch.fade(_afternoonCream, .022 * k),
    );
    c.drawCircle(
      at,
      h * .3,
      ring
        ..strokeWidth = h * .007
        ..color = Sketch.fade(const Color(0xffffc9a0), .05 * k),
    );
    final bloom = r * 3.4;
    c.drawCircle(
      at,
      bloom,
      Paint()
        ..shader = Gradient.radial(
          at,
          bloom,
          [
            Sketch.fade(const Color(0xfffffffc), k),
            Sketch.fade(sun.disc, k),
            Sketch.fade(const Color(0xfffff5d8), k),
            Sketch.fade(const Color(0xfffff5df), .82 * k),
            Sketch.fade(const Color(0xfffff1d6), .5 * k),
            Sketch.fade(const Color(0xffffe9d0), .22 * k),
            Sketch.fade(const Color(0xffffe4c4), 0),
          ],
          const [0, .18, .285, .32, .43, .63, 1],
        ),
    );
  }

  /// Kites and an Egyptian vulture wheeling on one thermal, and ibises in
  /// formation far above the fields.
  void _afternoonBirds(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, time = f.clock;
    final t = _afternoonDrift(f);
    final kite = Sketch.fade(const Color(0xff5b493c), .58 * presence);
    final kiteCoverts = Sketch.fade(const Color(0xff9a8168), .5 * presence);
    final thermal = Offset(w * .6, h * .27);
    for (final (i, radius, phase, span, spin) in const [
      (0, .12, 0.0, .025, .3),
      (1, .085, 3.4, .02, .34),
    ]) {
      final a = time * spin + phase;
      _afternoonRaptor(
        c,
        thermal +
            Offset(
              math.cos(a) * h * radius * 1.5,
              math.sin(a) * h * radius * .5 + i * h * .012,
            ),
        h * span,
        a + math.pi,
        kite,
        kiteCoverts,
      );
    }
    final a = time * .22 + 1.3;
    _afternoonRaptor(
      c,
      Offset(w * .37, h * .12) +
          Offset(math.cos(a) * h * .1, math.sin(a) * h * .03),
      h * .022,
      a + math.pi,
      Sketch.fade(const Color(0xff3f342d), .6 * presence),
      Sketch.fade(const Color(0xffe7dcc6), .7 * presence),
    );
    // Sacred ibises: white with black wing tips, in a shallow V.
    final span = w + h * 2;
    final ink = Sketch.fade(const Color(0xff4c4a55), .62 * presence);
    final white = Paint()
      ..color = Sketch.fade(const Color(0xfff9f4ea), .85 * presence);
    final black = Paint()..color = ink;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = ink;
    for (final (fx, fy, size, speed, flock) in const [
      (.14, .245, .0105, .022, 7),
      (.2, .47, .0068, .016, 5),
    ]) {
      final lead = (w * fx + t * h * speed + h) % span - h;
      for (var i = 0; i < flock; i++) {
        final rank = (i + 1) ~/ 2, side = i.isEven ? -1.0 : 1.0;
        final flap = math.sin(time * 5.2 + i * .9 + fx * 9);
        _afternoonIbis(
          c,
          Offset(
            lead - rank * h * size * 2.6,
            h * fy + side * rank * h * size * 1.1 + flap * h * size * .12,
          ),
          h * size,
          flap,
          white,
          black,
          line,
        );
      }
    }
  }

  /// A soaring raptor seen from below, banked by [heading] round the thermal:
  /// broad fingered wings, a forked tail, and optionally pale wing coverts.
  void _afternoonRaptor(
    Canvas c,
    Offset p,
    double span,
    double heading,
    Color color,
    Color? coverts,
  ) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(1, .68);
    c.rotate(heading);
    c.scale(span);
    c.drawPath(_afternoonRaptorShape, Paint()..color = color);
    if (coverts != null) {
      c.drawPath(_afternoonCovertShape, Paint()..color = coverts);
    }
    c.restore();
  }

  static final _afternoonRaptorShape = Path()
    ..moveTo(0, -.52)
    ..quadraticBezierTo(.06, -.46, .075, -.34)
    ..lineTo(.13, -.2)
    ..quadraticBezierTo(.55, -.24, .98, -.04)
    ..lineTo(1.03, .06)
    ..lineTo(.93, .02)
    ..lineTo(.96, .13)
    ..lineTo(.85, .07)
    ..lineTo(.85, .18)
    ..lineTo(.74, .1)
    ..quadraticBezierTo(.45, .2, .17, .14)
    ..lineTo(.09, .36)
    ..lineTo(.16, .66)
    ..lineTo(0, .54)
    ..lineTo(-.16, .66)
    ..lineTo(-.09, .36)
    ..lineTo(-.17, .14)
    ..quadraticBezierTo(-.45, .2, -.74, .1)
    ..lineTo(-.85, .18)
    ..lineTo(-.85, .07)
    ..lineTo(-.96, .13)
    ..lineTo(-.93, .02)
    ..lineTo(-1.03, .06)
    ..lineTo(-.98, -.04)
    ..quadraticBezierTo(-.55, -.24, -.13, -.2)
    ..lineTo(-.075, -.34)
    ..quadraticBezierTo(-.06, -.46, 0, -.52)
    ..close();

  static final _afternoonCovertShape = Path()
    ..moveTo(0, -.4)
    ..lineTo(.11, -.19)
    ..quadraticBezierTo(.36, -.19, .62, -.09)
    ..lineTo(.6, .03)
    ..quadraticBezierTo(.34, .12, .16, .1)
    ..lineTo(.07, .3)
    ..lineTo(-.07, .3)
    ..lineTo(-.16, .1)
    ..quadraticBezierTo(-.34, .12, -.6, .03)
    ..lineTo(-.62, -.09)
    ..quadraticBezierTo(-.36, -.19, -.11, -.19)
    ..close();

  /// A distant sacred ibis in flight facing right: white body, black head,
  /// bill and legs, and two broad wings whose outer thirds are black; [flap]
  /// runs -1..1 from downstroke to upstroke. [white], [ink] (fills) and
  /// [line] (a round stroke) are shared paints so a flock allocates none.
  void _afternoonIbis(
    Canvas c,
    Offset p,
    double s,
    double flap,
    Paint white,
    Paint ink,
    Paint line,
  ) {
    final lift = s * .95 * flap;
    // One wing: a leaf from the shoulder to the tip, white inside and black
    // beyond two thirds of its length.
    void wing(Offset shoulder, Offset tip) {
      final v = tip - shoulder;
      final len = v.distance;
      final u = v / len;
      var fwd = Offset(1 - u.dx * u.dx, -u.dx * u.dy);
      fwd = fwd.distance < .01 ? const Offset(1, 0) : fwd / fwd.distance;
      Path leaf(double k) {
        final t = shoulder + v * k;
        final mid = shoulder + v * (.5 * k);
        return Path()
          ..moveTo(
            shoulder.dx + fwd.dx * len * .03,
            shoulder.dy + fwd.dy * len * .03,
          )
          ..quadraticBezierTo(
            mid.dx + fwd.dx * len * .1 * k,
            mid.dy + fwd.dy * len * .1 * k,
            t.dx,
            t.dy,
          )
          ..quadraticBezierTo(
            mid.dx - fwd.dx * len * .3 * k,
            mid.dy - fwd.dy * len * .3 * k,
            shoulder.dx - fwd.dx * len * .3,
            shoulder.dy - fwd.dy * len * .3,
          )
          ..close();
      }

      c.drawPath(leaf(1), ink);
      c.drawPath(leaf(.66), white);
    }

    wing(
      p + Offset(s * .2, -s * .05),
      p + Offset(s * .1, -s * .05 - lift * .9),
    );
    c.drawOval(
      Rect.fromCenter(
        center: p + Offset(-s * .05, s * .04),
        width: s * 1.0,
        height: s * .26,
      ),
      white,
    );
    // The bare black neck and the long down-curved bill.
    line.strokeWidth = math.max(.7, s * .13);
    c.drawPath(
      Path()
        ..moveTo(p.dx + s * .32, p.dy + s * .01)
        ..quadraticBezierTo(
          p.dx + s * .58,
          p.dy - s * .14,
          p.dx + s * .68,
          p.dy - s * .08,
        )
        ..quadraticBezierTo(
          p.dx + s * .88,
          p.dy - s * .04,
          p.dx + s * .96,
          p.dy + s * .1,
        ),
      line,
    );
    wing(p + Offset(-s * .02, -s * .02), p + Offset(-s * .62, -s * .02 - lift));
    // Legs trail behind.
    line.strokeWidth = math.max(.5, s * .06);
    c.drawLine(
      p + Offset(-s * .5, s * .1),
      p + Offset(-s * 1.05, s * .2),
      line,
    );
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  /// The far band's skyline at pixel x, so ruins and camels stand exactly on it.
  static double _gizaSkyline(double x, double h) =>
      const EgyptScene().ridge(Depth.far, x / h, 0) * h;

  /// The sky's own colour at the skyline: dust haze in this tone melts a
  /// monument into the horizon without tinting the sky around it.
  static const _gizaSky = Color(0xfffae6bf);

  static void _gizaDust(
    Canvas c,
    double x,
    double y,
    double width,
    double height,
    double alpha,
  ) => Sketch.mist(
    c,
    Rect.fromCenter(center: Offset(x, y), width: width, height: height),
    _gizaSky,
    alpha,
  );

  /// Where the Sphinx's rump stands. Shared with the temple, whose right-hand
  /// obelisk (pylon x + .3 h, pylon at .17 w) must clear it at every width.
  static double _gizaSphinxX(double w, double h) => math.max(w * .535 - h * .56, w * .17 + h * .335);

  /// The Giza plateau: Khufu, Khafre with its limestone cap, Menkaure and the
  /// queens' pyramids, lit from the right, mastabas and the causeway at their
  /// feet, the Sphinx and its temples, a camel caravan for scale. Farthest
  /// things first, each layer a little less hazed than the one behind.
  static void _pyramids(Canvas c, double x0, double h, double w) {
    _gizaHills(c, w + h * .8, h);
    // Pyramids of Abusir and Dahshur far behind the plateau, nearly lost.
    final sphinxX = _gizaSphinxX(w, h);
    _gizaPyramid(c, h, x0 + h * .62, h * .07, haze: .66, seed: 3, corner: .34);
    _gizaPyramid(c, h, x0 + h * 1.06, h * .09, haze: .62, seed: 5, corner: .3);
    // The three great pyramids, Khufu farthest.
    _gizaPyramid(
      c,
      h,
      x0,
      h * .225,
      haze: .42,
      flat: h * .007,
      seed: 1,
      corner: .3,
    );
    // Khafre's causeway climbs from the valley temple to its foot.
    _gizaCauseway(c, h, sphinxX + h * .3, x0 + h * .22);
    _gizaMastabas(c, h, x0 - h * .17, x0 + h * .19, .22);
    _gizaPyramid(
      c,
      h,
      x0 + h * .4,
      h * .208,
      haze: .34,
      cap: .27,
      seed: 2,
      corner: .3,
    );
    _gizaPyramid(
      c,
      h,
      x0 + h * .72,
      h * .1,
      haze: .27,
      granite: .12,
      seed: 4,
      corner: .3,
    );
    // Menkaure's three queens and the little satellite before Khufu.
    for (final (dx, tall, seed) in const [(.845, .05, 6), (.9, .034, 7), (.95, .028, 8)]) {
      _gizaPyramid(c, h, x0 + h * dx, h * tall, haze: .24, seed: seed, corner: .3);
    }
    for (final (dx, tall, seed) in const [(.215, .035, 9), (.262, .027, 10)]) {
      _gizaPyramid(c, h, x0 + h * dx, h * tall, haze: .3, seed: seed, corner: .3);
    }
    // The Sphinx in its quarry pit, with the temples before its paws.
    _gizaSphinx(c, h, sphinxX, h * .23);
    _gizaRuins(c, h, sphinxX + h * .24, h * .085, h * .014, 21);
    _gizaRuins(c, h, sphinxX + h * .34, h * .07, h * .02, 22, pillars: true);
    _gizaCaravan(c, h, x0 + h * .52);
    // Tiny people at the Sphinx's paws.
    final folk = Paint()
      ..color = _hazed(const Color(0xff5b4331), .14)
      ..strokeWidth = math.max(.8, h * .002)
      ..strokeCap = StrokeCap.round;
    for (final (dx, tall) in const [(.25, .011), (.259, .009), (.33, .01)]) {
      final x = sphinxX + h * dx, y = _gizaSkyline(x, h) + 1;
      c.drawLine(Offset(x, y), Offset(x, y - h * tall), folk);
    }
  }

  /// Two swells of hazy desert and limestone behind the pyramids.
  static void _gizaHills(Canvas c, double right, double h) {
    for (final (haze, lift, seed) in const [(.78, .034, 1), (.62, .017, 2)]) {
      final path = Path()..moveTo(-h * .1, h * .7);
      final step = h * .05;
      for (var x = -h * .1; x <= right; x += step) {
        final bump = .5 + .5 * math.sin(x / h * (2.3 + seed) + seed * 1.7) * math.sin(x / h * 1.1 + seed);
        path.lineTo(x, _gizaSkyline(x, h) - h * lift * (.25 + .75 * bump));
      }
      path
        ..lineTo(right, h * .7)
        ..close();
      c.drawPath(
        path,
        Paint()..color = _hazed(const Color(0xffe6c390), haze),
      );
    }
  }

  /// One pyramid of stepped masonry, sharing its real slope (about 50 degrees,
  /// widened a little by the viewing angle). [cap] is the share of the height
  /// still in smooth casing, [granite] the share in dark granite at the foot.
  static void _gizaPyramid(
    Canvas c,
    double h,
    double x,
    double height, {
    required double haze,
    double corner = .3,
    double cap = 0,
    double granite = 0,
    double flat = 0,
    double ratio = .95,
    int seed = 1,
  }) {
    final base = _gizaSkyline(x, h);
    final apex = base - height;
    final bottom = base + h * .04;
    final half = height * ratio;
    final slope = (half - flat) / height;
    double hw(double y) => flat + (y - apex) * slope;
    double hip(double y) => x + corner * hw(y);
    final litTop = _hazed(const Color(0xfffdf1cc), haze * .7);
    final litFoot = _hazed(const Color(0xfff1d09a), math.min(.9, haze * 1.3));
    final shadeTop = _hazed(const Color(0xffbf8853), haze * .7);
    final shadeFoot = _hazed(const Color(0xffdcb07c), math.min(.9, haze * 1.3));
    if (height < h * .075 || haze > .55) {
      // Small or far pyramids: two plain faces and a few courses, no clip.
      final hipTop = Offset(x + corner * flat, apex), hipFoot = Offset(hip(bottom), bottom);
      c.drawPath(
        Sketch.poly([x - flat, apex, hipTop.dx, apex, hipFoot.dx, bottom, x - hw(bottom), bottom]),
        Paint()..shader = Gradient.linear(Offset(0, apex), Offset(0, base), [shadeTop, shadeFoot]),
      );
      c.drawPath(
        Sketch.poly([hipTop.dx, apex, x + flat, apex, x + hw(bottom), bottom, hipFoot.dx, bottom]),
        Paint()..shader = Gradient.linear(Offset(0, apex), Offset(0, base), [litTop, litFoot]),
      );
      final line = Paint()
        ..color = Sketch.fade(_hazed(const Color(0xffa8703f), haze * .8), .38)
        ..strokeWidth = math.max(.5, h * .0012);
      for (var y = apex + h * .007; y < base; y += h * (.006 + .004 * (y - apex) / height)) {
        c.drawLine(Offset(hip(y), y), Offset(x + hw(y), y), line);
        c.drawLine(Offset(x - hw(y), y), Offset(hip(y), y), line);
      }
      c.drawLine(
        hipTop,
        hipFoot,
        Paint()
          ..color = Sketch.fade(const Color(0xfffff3d2), .7)
          ..strokeWidth = math.max(.7, h * .002),
      );
      _gizaDust(c, x, base - h * .003, half * 2.6, h * .05, .55);
      return;
    }
    // Courses: thin near the apex, thick at the foot, like the real masonry.
    final ys = <double>[];
    var yc = apex + height * cap + h * .004, n = 0;
    while (yc < bottom) {
      ys.add(yc);
      yc += h * (.0042 + .0056 * ((yc - apex) / height)) * (.75 + .5 * Sketch.hash(seed * 131 + n));
      n++;
    }
    double under(int i) => i + 1 < ys.length ? ys[i + 1] : bottom;
    // Each course starts a hair inside the slope and follows it out: the
    // skyline is serrated by the masonry rather than cut into stairs.
    double notch(int i, int side) =>
        h * .0022 * (.4 + 1.1 * Sketch.hash(seed * 53 + i * 2 + side)) * (Sketch.hash(seed * 19 + i * 3 + side) > .93 ? 2.2 : 1);
    final silhouette = Path()..moveTo(x - flat, apex);
    for (var i = 0; i < ys.length; i++) {
      silhouette
        ..lineTo(x - hw(ys[i]) + notch(i, 0), ys[i])
        ..lineTo(x - hw(under(i)), under(i));
    }
    for (var i = ys.length - 1; i >= 0; i--) {
      silhouette
        ..lineTo(x + hw(under(i)), under(i))
        ..lineTo(x + hw(ys[i]) - notch(i, 1), ys[i]);
    }
    silhouette
      ..lineTo(x + flat, apex)
      ..close();

    final wide = hw(bottom) + h * .02, top = apex - 3;
    final hipTop = Offset(x + corner * flat, apex);
    final hipFoot = Offset(hip(bottom), bottom);
    final shadeFace = Sketch.poly([x - wide, top, hipTop.dx, top, hipFoot.dx, bottom + 2, x - wide, bottom + 2]);
    final litFace = Sketch.poly([hipTop.dx, top, x + wide, top, x + wide, bottom + 2, hipFoot.dx, bottom + 2]);
    c.save();
    c.clipPath(silhouette);
    c.drawPath(
      shadeFace,
      Paint()..shader = Gradient.linear(Offset(0, apex), Offset(0, base), [shadeTop, shadeFoot]),
    );
    c.drawPath(
      litFace,
      Paint()..shader = Gradient.linear(Offset(0, apex), Offset(0, base), [litTop, litFoot]),
    );
    // The shaded face darkens away from the corner.
    final deep = _hazed(const Color(0xff8a5a30), haze);
    c.drawPath(
      shadeFace,
      Paint()..shader = Gradient.linear(Offset(x - hw(base), 0), Offset(hip(base), 0), [Sketch.fade(deep, .2), Sketch.fade(deep, 0)]),
    );
    // A course line under each layer of blocks; a lit tread above it. The
    // courses blur away toward the apex, where they are thin.
    final line = math.max(.5, h * .0014);
    final litLine = Paint()..strokeWidth = line;
    final shadeLine = Paint()..strokeWidth = line;
    final tread = Paint()..strokeWidth = line;
    final pale = Paint()..color = Sketch.fade(const Color(0xffffffff), .09);
    final dark = Paint()..color = Sketch.fade(const Color(0xff8a5a30), .06);
    final litInk = _hazed(const Color(0xffb27b4a), haze * .8);
    final shadeInk = _hazed(const Color(0xff704a2c), haze * .8);
    for (var i = 0; i < ys.length; i++) {
      final y = ys[i], wy = hw(y);
      if (Sketch.hash(seed * 17 + i) < .14) continue;
      final k = .3 + .7 * ((y - apex) / height).clamp(0.0, 1.0);
      litLine.color = Sketch.fade(litInk, .5 * k);
      shadeLine.color = Sketch.fade(shadeInk, .34 * k);
      tread.color = Sketch.fade(const Color(0xfffff6dc), .36 * k);
      c.drawLine(Offset(x - wy - 2, y), Offset(hip(y), y), shadeLine);
      c.drawLine(Offset(hip(y), y), Offset(x + wy + 2, y), litLine);
      c.drawLine(Offset(hip(y), y - line), Offset(x + wy + 2, y - line), tread);
      // Patches of paler or darker stone break up the rhythm of each course.
      if (i + 1 < ys.length) {
        final y2 = ys[i + 1], w2 = hw(y2);
        for (var side = 0; side < 2; side++) {
          final r = Sketch.hash(seed * 29 + i * 2 + side);
          if (r > .62) continue;
          final u0 = Sketch.hash(seed * 41 + i * 2 + side);
          final u1 = math.min(1.0, u0 + .18 + .4 * Sketch.hash(seed * 43 + i * 2 + side));
          final aTop = side == 0 ? x - wy : hip(y), bTop = side == 0 ? hip(y) : x + wy;
          final aBot = side == 0 ? x - w2 : hip(y2), bBot = side == 0 ? hip(y2) : x + w2;
          c.drawPath(
            Sketch.poly([
              aTop + (bTop - aTop) * u0, y, aTop + (bTop - aTop) * u1, y, //
              aBot + (bBot - aBot) * u1, y2, aBot + (bBot - aBot) * u0, y2,
            ]),
            r < .3 ? pale : dark,
          );
        }
      }
    }
    if (cap > 0) _gizaCap(c, h, x, apex + height * cap, hw, seed, shadeFace, litFace, haze);
    if (granite > 0) _gizaGranite(c, h, x, base - height * granite, bottom, hw, seed, shadeFace, litFace, haze);
    // The hip glints, and a rim of light on the sunlit edge.
    c.drawLine(
      hipTop,
      hipFoot,
      Paint()
        ..color = Sketch.fade(const Color(0xfffff3d2), .7)
        ..strokeWidth = math.max(.8, h * .0028),
    );
    c.drawLine(
      Offset(x + flat - .8, apex),
      Offset(x + hw(bottom) - .8, bottom),
      Paint()
        ..color = Sketch.fade(const Color(0xffffffff), .34)
        ..strokeWidth = math.max(.7, h * .002),
    );
    c.restore();
    if (haze < .5 && cap == 0 && flat > 0) {
      // Khufu lost its capstone: a small flat summit.
      c.drawLine(
        Offset(x - flat, apex + .3),
        Offset(x + flat, apex + .3),
        Paint()
          ..color = Sketch.fade(const Color(0xfffff3d2), .75)
          ..strokeWidth = math.max(.8, h * .002),
      );
    }
    _gizaDust(c, x, base - h * .003, half * 2.6, h * .07, .55);
  }

  /// Khafre's cap: smooth, bright casing stones with a ragged lower edge.
  static void _gizaCap(
    Canvas c,
    double h,
    double x,
    double yCut,
    double Function(double) hw,
    int seed,
    Path shadeFace,
    Path litFace,
    double haze,
  ) {
    final span = hw(yCut) + 3;
    final cut = <Offset>[
      for (var k = 0; k <= 14; k++)
        Offset(
          x + (-1 + 2 * k / 14) * span,
          yCut + h * (.001 + .012 * Sketch.hash(seed * 7 + k)),
        ),
    ];
    final cap = Path()..moveTo(cut.first.dx, yCut - h * .3);
    for (final p in cut) {
      cap.lineTo(p.dx, p.dy);
    }
    cap
      ..lineTo(cut.last.dx, yCut - h * .3)
      ..close();
    c.save();
    c.clipPath(shadeFace);
    c.drawPath(cap, Paint()..color = _hazed(const Color(0xffe9cca4), haze * .8));
    c.restore();
    c.save();
    c.clipPath(litFace);
    c.drawPath(cap, Paint()..color = _hazed(const Color(0xfffffaec), haze * .55));
    c.restore();
    // The ragged lower edge casts a hairline of shadow.
    final edge = Path()..moveTo(cut.first.dx, cut.first.dy);
    for (final p in cut.skip(1)) {
      edge.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .002)
        ..color = Sketch.fade(_hazed(const Color(0xff9a6a40), haze), .5),
    );
  }

  /// Menkaure's dark red granite casing, still on the lowest courses.
  static void _gizaGranite(
    Canvas c,
    double h,
    double x,
    double yCut,
    double bottom,
    double Function(double) hw,
    int seed,
    Path shadeFace,
    Path litFace,
    double haze,
  ) {
    final span = hw(bottom) + 3;
    final cut = <Offset>[
      for (var k = 0; k <= 12; k++)
        Offset(
          x + (-1 + 2 * k / 12) * span,
          yCut + h * .01 * (Sketch.hash(seed * 11 + k) - .5),
        ),
    ];
    final band = Path()..moveTo(cut.first.dx, bottom + 2);
    for (final p in cut) {
      band.lineTo(p.dx, p.dy);
    }
    band
      ..lineTo(cut.last.dx, bottom + 2)
      ..close();
    c.save();
    c.clipPath(shadeFace);
    c.drawPath(band, Paint()..color = _hazed(const Color(0xff8e6f5c), haze * 1.25));
    c.restore();
    c.save();
    c.clipPath(litFace);
    c.drawPath(band, Paint()..color = _hazed(const Color(0xffbc9880), haze * 1.25));
    c.restore();
  }

  /// Low, flat-topped tombs of the necropolis between x [from] and [to].
  static void _gizaMastabas(
    Canvas c,
    double h,
    double from,
    double to,
    double haze,
  ) {
    final front = Paint()..color = _hazed(const Color(0xffc19461), haze);
    final end = Paint()..color = _hazed(const Color(0xfff2d7a3), haze);
    final lip = Paint()
      ..color = Sketch.fade(const Color(0xfffff2cc), .6)
      ..strokeWidth = math.max(.6, h * .0016);
    final seed = (from * 3).round();
    var x = from, i = 0;
    while (x < to) {
      final w = h * (.009 + .024 * Sketch.hash(seed + i));
      final ht = h * (.006 + .011 * Sketch.hash(seed + i + 40));
      final base = _gizaSkyline(x + w / 2, h) + 1;
      c.drawPath(
        Sketch.poly([x, base, x + w * .1, base - ht, x + w * .9, base - ht, x + w, base]),
        front,
      );
      c.drawPath(
        Sketch.poly([x + w * .62, base - ht, x + w * .9, base - ht, x + w, base, x + w * .7, base]),
        end,
      );
      c.drawLine(Offset(x + w * .1, base - ht), Offset(x + w * .9, base - ht), lip);
      x += w + h * (.005 + .03 * Sketch.hash(seed + i + 80));
      i++;
    }
  }

  /// A walled processional way running up to the pyramid's foot.
  static void _gizaCauseway(Canvas c, double h, double from, double to) {
    final y0 = _gizaSkyline(from, h), y1 = _gizaSkyline(to, h) - h * .008;
    c.drawPath(
      Sketch.poly([from, y0 - h * .003, to, y1 - h * .004, to, y1 + h * .03, from, y0 + h * .03]),
      Paint()..color = _hazed(const Color(0xffd9b382), .4),
    );
    c.drawLine(
      Offset(from, y0 - h * .003),
      Offset(to, y1 - h * .004),
      Paint()
        ..color = Sketch.fade(const Color(0xfffff0c6), .6)
        ..strokeWidth = math.max(.6, h * .0016),
    );
  }

  /// Ruined temple walls: ragged tops, block courses, a doorway and a row of
  /// square pillars, in megalithic limestone.
  static void _gizaRuins(
    Canvas c,
    double h,
    double x,
    double width,
    double height,
    int seed, {
    bool pillars = false,
  }) {
    const haze = .16;
    final base = _gizaSkyline(x + width / 2, h) + 1.5;
    final top = [
      for (var i = 0; i <= 6; i++) height * (.62 + .38 * Sketch.hash(seed * 13 + i)),
    ];
    final wall = Path()..moveTo(x, base);
    for (var i = 0; i <= 6; i++) {
      wall.lineTo(x + width * i / 6, base - top[i]);
      if (i < 6) wall.lineTo(x + width * (i + 1) / 6, base - top[i]);
    }
    wall
      ..lineTo(x + width, base)
      ..close();
    c.drawPath(wall, Paint()..color = _hazed(const Color(0xffc99a68), haze));
    c.save();
    c.clipPath(wall);
    final course = Paint()
      ..color = Sketch.fade(_hazed(const Color(0xff8f6238), haze), .32)
      ..strokeWidth = math.max(.5, h * .0012);
    for (var y = base - height * .3; y > base - height; y -= height * .28) {
      c.drawLine(Offset(x, y), Offset(x + width, y), course);
    }
    // Sunlit end and a dark doorway.
    c.drawRect(
      Rect.fromLTRB(x + width * .86, base - height, x + width, base),
      Paint()..color = _hazed(const Color(0xfff0d09a), haze),
    );
    c.drawRect(
      Rect.fromLTWH(x + width * .32, base - height * .55, width * .1, height * .55),
      Paint()..color = _hazed(const Color(0xff6f4a2e), haze),
    );
    c.restore();
    c.drawLine(
      Offset(x, base - top[0]),
      Offset(x + width, base - top[6]),
      Paint()
        ..color = Sketch.fade(const Color(0xfffff2cc), .5)
        ..strokeWidth = math.max(.6, h * .0016),
    );
    if (pillars) {
      // T-shaped monolith pillars, all one height, catching light on the right.
      final pillar = Paint()..color = _hazed(const Color(0xffbb8f5d), haze);
      final edge = Paint()..color = _hazed(const Color(0xffefcf98), haze);
      final pw = math.max(1.3, h * .0058);
      for (var i = 0; i < 5; i++) {
        final px = x + width * (.08 + .19 * i);
        final top = base - height * 1.35;
        c.drawRect(Rect.fromLTWH(px, top, pw, base - top), pillar);
        c.drawRect(Rect.fromLTWH(px + pw * .6, top, pw * .4, base - top), edge);
      }
      // The architrave still spans the pillars in one place.
      c.drawRect(
        Rect.fromLTWH(x + width * .08, base - height * 1.5, width * .4, height * .2),
        pillar,
      );
    }
  }

  /// A few camels and riders crossing between the pyramids' feet.
  static void _gizaCaravan(Canvas c, double h, double x) {
    for (var i = 0; i < 4; i++) {
      final cx = x + h * .034 * i;
      _gizaCamel(c, Offset(cx, _gizaSkyline(cx, h) + .8), h * (.019 - .0006 * i), i != 2);
    }
  }

  static void _gizaCamel(Canvas c, Offset at, double s, bool rider) {
    final ink = _hazed(const Color(0xff5d4331), .16);
    final paint = Paint()..color = ink;
    c.save();
    c.translate(at.dx, at.dy);
    c.drawPath(
      Sketch.poly(
        const [
          -.48, -.5, -.5, -.68, -.2, -.74, -.1, -.98, .05, -.98, .12, -.76, //
          .3, -.72, .5, -1.12, .74, -1.16, .74, -1.05, .56, -.98, .42, -.56,
          .35, -.48,
        ],
        s: s,
      ),
      paint,
    );
    final leg = Paint()
      ..color = ink
      ..strokeWidth = math.max(.7, s * .08)
      ..strokeCap = StrokeCap.round;
    for (final (lx, lean) in const [(-.4, -.05), (-.3, .05), (.26, .04), (.35, -.04)]) {
      c.drawLine(Offset(lx * s, -.5 * s), Offset((lx + lean) * s, 0), leg);
    }
    if (rider) {
      c.drawLine(Offset(-.02 * s, -.96 * s), Offset(-.02 * s, -1.16 * s), leg..strokeWidth = s * .2);
      c.drawCircle(Offset(-.02 * s, -1.26 * s), s * .09, paint);
    }
    c.restore();
  }

  /// The Great Sphinx, in profile, facing the sun: nemes headdress with its
  /// striped lappet, the worn face, a lion's long back and paws stretched out,
  /// in the stratified limestone pit it was carved from.
  static void _gizaSphinx(Canvas c, double h, double x, double len) {
    final ground = _gizaSkyline(x + len * .5, h) + h * .003;
    final at = Offset(x, ground);
    const haze = .12;
    final shade = _hazed(const Color(0xffa07048), haze);
    final mid = _hazed(const Color(0xffd3a672), haze);
    final lit = _hazed(const Color(0xffeccc94), haze);
    final rim = Sketch.fade(const Color(0xfffff3d0), .8);
    final ink = Sketch.fade(_hazed(const Color(0xff5f3d24), haze), .6);
    final hair = math.max(.5, h * .0012);
    Path shape(List<double> xy) => Sketch.poly(xy, at: at, s: len);
    Offset pt(double px, double py) => at + Offset(px * len, py * len);
    // The quarry wall behind the body: stratified limestone, in shadow.
    final wall = shape(const [
      -.2, .06, -.2, -.18, -.1, -.205, .1, -.2, .3, -.21, .5, -.2, //
      .62, -.2, .74, -.185, .9, -.16, 1.02, -.11, 1.12, -.04, 1.16, .02, 1.16, .06,
    ]);
    c.drawPath(wall, Paint()..color = _hazed(const Color(0xffb88a58), haze + .06));
    c.save();
    c.clipPath(wall);
    final strata = Paint()
      ..color = Sketch.fade(_hazed(const Color(0xff7d5230), haze), .34)
      ..strokeWidth = hair;
    for (final (y, x0, x1) in const [
      (-.17, -.2, .62), (-.145, -.2, .9), (-.115, -.1, 1.02), (-.085, .1, 1.1), (-.05, -.2, 1.16),
    ]) {
      c.drawLine(pt(x0, y), pt(x1, y), strata);
    }
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(pt(-.2, -.18).dx, pt(-.2, -.18).dy)
        ..lineTo(pt(-.1, -.205).dx, pt(-.1, -.205).dy)
        ..lineTo(pt(.1, -.2).dx, pt(.1, -.2).dy)
        ..lineTo(pt(.3, -.21).dx, pt(.3, -.21).dy)
        ..lineTo(pt(.5, -.2).dx, pt(.5, -.2).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair * 1.5
        ..color = Sketch.fade(const Color(0xfffff0c8), .5),
    );
    // The head is drawn from two cubic arcs: up the back of the headdress and
    // over the crown to the brow.
    List<double> arc(List<double> p) {
      final out = <double>[];
      for (var i = 1; i <= 6; i++) {
        final t = i / 6, u = 1 - t;
        for (var k = 0; k < 2; k++) {
          out.add(u * u * u * p[k] + 3 * u * u * t * p[2 + k] + 3 * u * t * t * p[4 + k] + t * t * t * p[6 + k]);
        }
      }
      return out;
    }

    final nape = arc(const [.535, -.15, .545, -.235, .575, -.3, .65, -.302]);
    final crown = arc(const [.65, -.302, .705, -.304, .742, -.288, .757, -.248]);
    // The whole body in one silhouette, shaded from the rump to the chest.
    final body = shape([
      0, .06, 0, -.045, .012, -.09, .045, -.12, .1, -.137, .2, -.142, //
      .32, -.14, .44, -.135, .5, -.137, .535, -.15, ...nape, ...crown,
      .768, -.232, .777, -.216, .766, -.207, .774, -.197, .762, -.183, .75, -.17,
      .758, -.152, .785, -.124, .81, -.092, .835, -.066, .87, -.055, .93, -.049,
      .985, -.045, 1.01, -.032, 1.01, .06,
    ]);
    c.drawPath(
      body,
      Paint()..shader = Gradient.linear(at, at + Offset(len, 0), [shade, mid, mid, lit], const [0, .3, .62, 1]),
    );
    c.save();
    c.clipPath(body);
    // Underside and contact shadow.
    c.drawPath(
      shape(const [-.02, .06, -.02, -.04, .3, -.03, .6, -.036, .74, -.06, .8, -.1, .84, .06]),
      Paint()..color = Sketch.fade(_hazed(const Color(0xff70452a), haze), .5),
    );
    c.drawPath(
      shape(const [.8, .06, .85, -.026, 1.01, -.02, 1.01, .06]),
      Paint()..color = Sketch.fade(_hazed(const Color(0xff70452a), haze), .4),
    );
    // Worn strata across the flank, and the tail curling over the haunch.
    for (final (y, x0, x1) in const [(-.108, .05, .5), (-.08, .02, .42), (-.054, .1, .6)]) {
      c.drawLine(pt(x0, y), pt(x1, y), strata);
    }
    c.drawPath(
      Path()
        ..moveTo(pt(.06, -.12).dx, pt(.06, -.12).dy)
        ..quadraticBezierTo(pt(-.005, -.09).dx, pt(-.005, -.09).dy, pt(.03, -.03).dx, pt(.03, -.03).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = Sketch.fade(ink, .55),
    );
    // Sunlit back and shoulder.
    c.drawPath(
      shape(const [.1, -.137, .2, -.142, .32, -.14, .44, -.135, .5, -.137, .535, -.15, .52, -.126, .3, -.122, .1, -.116]),
      Paint()..color = Sketch.fade(lit, .85),
    );
    // Headdress: the back cloth in shade, the crown and the striped lappet lit.
    final hood = <double>[.535, -.15, ...nape];
    for (var i = 0; i + 1 < crown.length; i += 2) {
      if (crown[i] <= .7) hood.addAll([crown[i], crown[i + 1]]);
    }
    c.drawPath(
      shape([...hood, .695, -.15]),
      Paint()..color = Sketch.mix(shade, mid, .42),
    );
    for (final (y, x0) in const [(-.262, .578), (-.232, .563), (-.202, .553), (-.172, .543)]) {
      c.drawLine(pt(x0, y), pt(.694, y), strata..strokeWidth = hair);
    }
    final top = <double>[];
    final under = <double>[];
    for (var i = 0; i + 1 < crown.length; i += 2) {
      top.addAll([crown[i], crown[i + 1]]);
      under.insertAll(0, [crown[i] - .012, crown[i + 1] + .034]);
    }
    c.drawPath(shape([...top, ...under]), Paint()..color = lit);
    c.drawPath(
      shape(const [.695, -.264, .752, -.258, .762, -.16, .73, -.135, .695, -.15]),
      Paint()..color = _hazed(const Color(0xffdcb070), haze),
    );
    final stripe = Paint()
      ..color = Sketch.fade(_hazed(const Color(0xff8a5c34), haze), .55)
      ..strokeWidth = math.max(.5, len * .005);
    for (final dx in const [.707, .72, .733, .746]) {
      c.drawLine(pt(dx, -.256), pt(dx + .004, -.14), stripe);
    }
    // The face and chest catch the sun.
    c.drawPath(
      shape(const [.742, -.272, .757, -.248, .768, -.232, .777, -.216, .766, -.207, .774, -.197, .762, -.183, .75, -.17, .742, -.18]),
      Paint()..color = _hazed(const Color(0xfff6e0b0), haze),
    );
    c.drawLine(
      pt(.745, -.236),
      pt(.759, -.237),
      Paint()
        ..color = ink
        ..strokeWidth = math.max(.6, len * .009),
    );
    c.drawPath(
      shape(const [.75, -.17, .758, -.152, .785, -.124, .81, -.092, .835, -.066, .84, -.056, .77, -.068, .745, -.13]),
      Paint()..color = Sketch.fade(lit, .95),
    );
    // Forepaws: the sunlit tops and a groove between them.
    c.drawPath(
      shape(const [.82, -.064, .87, -.055, .93, -.049, .985, -.045, 1.01, -.032, .995, -.026, .84, -.04]),
      Paint()..color = _hazed(const Color(0xfff2d9a6), haze),
    );
    c.drawLine(
      pt(.85, -.02),
      pt(1.0, -.015),
      Paint()
        ..color = ink
        ..strokeWidth = hair,
    );
    c.restore();
    // Rim light along the back, the headdress and the brow.
    final outline = Path()..moveTo(pt(.1, -.137).dx, pt(.1, -.137).dy);
    for (final (px, py) in const [(.2, -.142), (.32, -.14), (.44, -.135), (.5, -.137), (.535, -.15)]) {
      outline.lineTo(pt(px, py).dx, pt(px, py).dy);
    }
    for (final pts in [nape, crown]) {
      for (var i = 0; i + 1 < pts.length; i += 2) {
        outline.lineTo(pt(pts[i], pts[i + 1]).dx, pt(pts[i], pts[i + 1]).dy);
      }
    }
    c.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, h * .0018)
        ..strokeJoin = StrokeJoin.round
        ..color = rim,
    );
    _gizaDust(c, x + len * .5, ground - h * .002, len * 1.6, h * .04, .35);
  }

  // ---------------------------------------------------------------------------
  // The temple: a pylon of two battered towers with flag masts, a deep gate
  // under a winged sun, seated colossi, granite obelisks, an enclosure wall
  // and an avenue of sphinxes running off toward the pyramids.

  static const _templeRise = .225;
  static const _templeFoot = .076;
  static const _templeTop = .06;
  static const _templeSpread = .122;
  static final _templeInk = _TempleInk(.2);
  static final _templeFar = _TempleInk(.42);

  /// Flag masts per tower, as (position across the tower, height in h).
  static const _templeMasts = [
    [(-.72, .085), (.72, .07)],
    [(-.72, .075), (.72, .092)],
  ];

  /// Screen y of the mid-band dune under pixel column [px].
  double _templeGround(double px, double h) => ridge(Depth.mid, px / h, 0) * h;

  /// The pylon's floor, a hair under the deepest trough of the dune beneath
  /// it, so the sand buries its foot whatever the dune does.
  double _templeFloor(double x, double h) {
    var deep = 0.0;
    for (var i = -8; i <= 8; i++) {
      deep = math.max(deep, _templeGround(x + i * h * .03, h));
    }
    return deep + h * .012;
  }

  void _temple(Canvas c, double x, double h) {
    final ink = _templeInk;
    final floor = _templeFloor(x, h);
    // The compound stops short of the Giza Sphinx that sits behind it.
    final limit = _gizaSphinxX(x / .17, h) + h * .12;
    _templeWalls(c, x, h, floor, limit);
    _templeShadows(c, x, h, floor, limit);
    _templeGrove(c, x, h, limit);
    _templeGate(c, x, h, ink, floor);
    for (var i = 0; i < 2; i++) {
      _templeTower(c, x + (i * 2 - 1) * h * _templeSpread, i, h, ink, floor);
    }
    _templeColossus(c, Offset(x - h * .07, floor + h * .004), h * .09, ink);
    _templeColossus(c, Offset(x + h * .105, floor + h * .004), h * .09, ink, tall: true);
    final left = x - h * .28, right = x + h * .3;
    _templeObelisk(c, Offset(left, _templeGround(left, h) + h * .012), h * .27, ink, 0);
    _templeObelisk(c, Offset(right, _templeGround(right, h) + h * .012), h * .245, ink, 1);
    _templeDrift(c, left, h * .09, h * .017, h);
    _templeDrift(c, right, h * .085, h * .015, h);
    _templeCenser(c, Offset(x - h * .226, _templeGround(x - h * .226, h) + h * .004), h * .03, ink);
    // Sacred ibises perch on the cornices and the wall.
    final crown = floor - h * _templeRise - h * .031;
    _templeIbis(c, Offset(x - h * _templeSpread + h * .016, crown), h * .024, 1, ink);
    _templeIbis(c, Offset(x + h * _templeSpread - h * .05, crown), h * .021, -1, ink);
    _templeAvenue(c, x, h);
    // Dust hangs at the foot of the compound and softens where it meets the dune.
    final far = ground(Depth.far);
    final dust = Sketch.mix(far.top, far.bottom, .12);
    final top = floor - h * .07;
    c.drawRect(
      Rect.fromLTRB(x - h * 1.4, top, math.min(x + h * .46, limit) + h * .02, floor + h * .02),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, floor),
          [Sketch.fade(dust, 0), Sketch.fade(dust, .34)],
        ),
    );
  }

  /// Shadows the obelisks and the left tower throw on the wall behind them,
  /// always toward the left, away from the sun.
  void _templeShadows(Canvas c, double x, double h, double floor, double limit) {
    final top = floor - h * .1, bottom = floor + h * .01;
    final wallEnd = math.min(x + h * .46, limit);
    final tint = Sketch.fade(_templeInk.deep, .3);
    for (final edge in [x - h * .28, x - h * .198, math.min(x + h * .3, wallEnd)]) {
      final l = edge - h * .07;
      c.drawRect(
        Rect.fromLTRB(l, top, edge, bottom),
        Paint()
          ..shader = Gradient.linear(
            Offset(l, 0),
            Offset(edge, 0),
            [Sketch.fade(_templeInk.deep, 0), tint],
          ),
      );
    }
  }

  /// A drift of sand banked against the compound: a low mound rising behind
  /// the dune's crest, with a lit edge of its own.
  void _templeDrift(Canvas c, double px, double hw, double amp, double h) {
    final g = ground(Depth.mid);
    final edge = <Offset>[];
    for (var i = 0; i <= 14; i++) {
      final u = i / 7 - 1;
      final x = px + u * hw;
      edge.add(Offset(x, _templeGround(x, h) - amp * math.pow(1 - u * u, 2)));
    }
    final fill = Path()..moveTo(edge.first.dx, edge.first.dy + h * .03);
    final rim = Path()..moveTo(edge.first.dx, edge.first.dy);
    for (final o in edge) {
      fill.lineTo(o.dx, o.dy);
      rim.lineTo(o.dx, o.dy);
    }
    fill
      ..lineTo(edge.last.dx, edge.last.dy + h * .03)
      ..close();
    c.drawPath(fill, Paint()..color = Sketch.mix(g.top, g.bottom, .06));
    c.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(.8, g.rimWidth * h * .8)
        ..color = Sketch.fade(g.rim, .9),
    );
  }

  /// A bronze censer on its stand, its smoke drawn live by [_templeSmoke].
  void _templeCenser(Canvas c, Offset base, double s, _TempleInk ink) {
    c.drawPath(
      Sketch.poly([base.dx - s * .1, base.dy, base.dx - s * .05, base.dy - s * .6, base.dx + s * .05, base.dy - s * .6, base.dx + s * .1, base.dy]),
      Paint()..color = ink.mast,
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx - s * .3, base.dy - s * .62)
        ..quadraticBezierTo(base.dx, base.dy - s * .25, base.dx + s * .3, base.dy - s * .62)
        ..close(),
      Paint()..color = ink.deep,
    );
    c.drawLine(
      Offset(base.dx - s * .3, base.dy - s * .62),
      Offset(base.dx + s * .3, base.dy - s * .62),
      Paint()
        ..color = ink.gold
        ..strokeWidth = math.max(.6, s * .05),
    );
  }

  /// The censer's smoke: a chain of puffs that swell and thin as they climb,
  /// swaying and leaning with the wind.
  void _templeSmoke(Canvas c, SceneFrame f) {
    final h = f.h, x = f.w * .17 - h * .226;
    final base = Offset(x, _templeGround(x, h) - h * .0145);
    final paint = Paint();
    for (var i = 0; i < 7; i++) {
      final k = i / 6;
      final at = Offset(
        base.dx - k * k * h * .04 + math.sin(f.clock * 1.1 + k * 5) * h * .008 * k,
        base.dy - k * h * .1,
      );
      c.drawCircle(
        at,
        h * (.0028 + .0085 * k),
        paint..color = Sketch.fade(_templeInk.cloth, .5 * math.pow(1 - k, 1.4) + .05),
      );
    }
  }

  /// A sacred ibis, white with a dark head and a long curved bill, facing
  /// left when [dir] is 1.
  void _templeIbis(Canvas c, Offset foot, double s, double dir, _TempleInk ink) {
    Offset p(double u, double v) => foot + Offset(dir * u * s, -v * s);
    c.drawOval(Rect.fromCenter(center: p(0, .5), width: s * .78, height: s * .44), Paint()..color = ink.cloth);
    c.drawLine(p(.3, .5), p(.52, .42), Paint()..color = ink.deep..strokeWidth = math.max(.6, s * .09)..strokeCap = StrokeCap.round);
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, s * .085)
      ..color = ink.deep;
    c.drawPath(
      Path()
        ..moveTo(p(-.22, .58).dx, p(-.22, .58).dy)
        ..lineTo(p(-.34, .92).dx, p(-.34, .92).dy)
        ..quadraticBezierTo(p(-.52, .92).dx, p(-.52, .92).dy, p(-.6, .76).dx, p(-.6, .76).dy),
      dark,
    );
    c.drawLine(foot + Offset(-dir * s * .06, -s * .3), foot, dark..strokeWidth = math.max(.5, s * .05));
  }

  /// The pennants stream toward the left on the wind that carries the sand.
  void _templeFlags(Canvas c, SceneFrame f) {
    final h = f.h, x = f.w * .17;
    final ink = _templeInk;
    final crown = _templeFloor(x, h) - h * _templeRise;
    final colors = [ink.red, ink.cloth, ink.blue, ink.red];
    final paint = Paint();
    var n = 0;
    for (var side = 0; side < 2; side++) {
      final cx = x + (side * 2 - 1) * h * _templeSpread;
      for (final (u, up) in _templeMasts[side]) {
        final mx = cx + u * h * _templeTop;
        final top = crown - h * up + h * .004;
        final wave = math.sin(f.clock * (2.1 + .35 * n) + n * 1.9);
        final len = h * (.036 + .006 * (n % 2)), wd = h * .0105;
        c.drawPath(
          Path()
            ..moveTo(mx, top)
            ..quadraticBezierTo(
              mx - len * .5,
              top + wave * h * .0045,
              mx - len,
              top + wd * .5 + wave * h * .007,
            )
            ..quadraticBezierTo(
              mx - len * .5,
              top + wd - wave * h * .003,
              mx,
              top + wd,
            )
            ..close(),
          paint..color = colors[n % 4],
        );
        n++;
      }
    }
  }

  /// One battered tower: sloping front, lit return face, painted registers,
  /// flag-mast niches and a cavetto cornice over a torus roll.
  void _templeTower(
    Canvas c,
    double cx,
    int seed,
    double h,
    _TempleInk ink,
    double floor,
  ) {
    final crown = floor - h * _templeRise;
    final b = h * _templeFoot, t = h * _templeTop;
    double half(double y) => t + (b - t) * (y - crown) / (floor - crown);
    final dx = h * .02, dy = -h * .005;
    final front = Sketch.poly([cx - b, floor, cx - t, crown, cx + t, crown, cx + b, floor]);
    c.drawPath(
      front,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, crown),
          Offset(0, floor),
          [ink.faceTop, ink.face, ink.faceLow],
          const [0, .55, 1],
        ),
    );
    // The left flank rolls off into shade.
    c.drawPath(
      front,
      Paint()
        ..shader = Gradient.linear(
          Offset(cx - b, 0),
          Offset(cx + b * .3, 0),
          [Sketch.fade(ink.shade, .6), Sketch.fade(ink.shade, 0)],
        ),
    );
    // Rain-dark streaks weather the wall below the cornice.
    for (final (sx, len) in const [(-.42, .11), (.14, .08), (.62, .13)]) {
      final y0 = crown + h * .03, y1 = y0 + h * len, w = h * .005;
      c.drawPath(
        Sketch.poly([cx + sx * half(y0) - w, y0, cx + sx * half(y0) + w, y0, cx + sx * half(y1) + w * .4, y1, cx + sx * half(y1) - w * .4, y1]),
        Paint()..color = Sketch.fade(ink.groove, .1),
      );
    }
    // Courses of masonry.
    final course = Path();
    for (var y = crown + h * .05; y < floor; y += h * .021) {
      course
        ..moveTo(cx - half(y), y)
        ..lineTo(cx + half(y), y);
    }
    c.drawPath(
      course,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0014)
        ..color = Sketch.fade(ink.groove, .18),
    );
    _templeRelief(c, cx, seed, h, ink, crown, floor, half);
    // The return face turns toward the sun.
    c.drawPath(
      Sketch.poly([cx + t, crown, cx + t + dx, crown + dy, cx + b + dx, floor + dy, cx + b, floor]),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, crown),
          Offset(0, floor),
          [ink.litTop, ink.lit, ink.litLow],
          const [0, .5, 1],
        ),
    );
    // A column of inscription runs down the return.
    final column = Path();
    for (var y = crown + h * .03; y < floor - h * .02; y += h * .0125) {
      final mx = cx + half(y) + dx * .5;
      column
        ..moveTo(mx, y)
        ..lineTo(mx, y + h * (.004 + .003 * Sketch.hash(seed * 61 + (y / h * 400).round())));
    }
    c.drawPath(
      column,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0022)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(ink.groove, .38),
    );
    // Torus rolls along both edges of the front.
    final roll = math.max(.7, h * .005);
    c.drawLine(
      Offset(cx - t, crown),
      Offset(cx - b, floor),
      Paint()
        ..color = ink.shade
        ..strokeWidth = roll * 1.3,
    );
    c.drawLine(
      Offset(cx + t, crown),
      Offset(cx + b, floor),
      Paint()
        ..color = ink.litTop
        ..strokeWidth = roll,
    );
    // Flag-mast niches with their cedar masts rising over the cornice.
    final mast = Paint()
      ..color = ink.mast
      ..strokeWidth = math.max(.7, h * .0026)
      ..strokeCap = StrokeCap.round;
    final slotLit = Paint()
      ..color = Sketch.fade(ink.litTop, .5)
      ..strokeWidth = math.max(.5, h * .0013);
    final slot = Paint()..color = Sketch.mix(ink.face, ink.groove, .6);
    for (final (u, up) in _templeMasts[seed]) {
      final y0 = crown + h * .016, y1 = crown + h * .17;
      final x0 = cx + u * half(y0), x1 = cx + u * half(y1);
      final w = h * .0026;
      c.drawPath(Sketch.poly([x0 - w, y0, x0 + w, y0, x1 + w, y1, x1 - w, y1]), slot);
      c.drawLine(Offset(x0 - w, y0), Offset(x1 - w, y1), slotLit);
      final top = crown - h * up;
      c.drawLine(Offset(x0, crown), Offset(x0, top), mast);
      c.drawCircle(Offset(x0, top), h * .0032, Paint()..color = ink.litTop);
    }
    _templeCornice(c, cx, h, ink, crown, t, dx);
  }

  /// A cavetto cornice: a flat abacus over a concave flare over a torus roll.
  void _templeCornice(
    Canvas c,
    double cx,
    double h,
    _TempleInk ink,
    double crown,
    double t,
    double dx, [
    double k = 1,
  ]) {
    final u = h * k;
    final cl = cx - t - u * .003, cr = cx + t + u * .003 + dx;
    final fl = cx - t - u * .018, fr = cx + t + u * .018 + dx;
    final y0 = crown - u * .007, y1 = crown - u * .024, y2 = crown - u * .031;
    // Shadow the cornice throws on the wall below.
    c.drawRect(
      Rect.fromLTRB(cl, crown, cr, crown + u * .011),
      Paint()..color = Sketch.fade(ink.shade, .5),
    );
    c.drawRRect(
      RRect.fromLTRBR(cl - u * .0015, y0, cr + u * .0015, crown + u * .003, Radius.circular(u * .003)),
      Paint()..color = ink.lit,
    );
    final flare = Path()
      ..moveTo(cl, y0)
      ..quadraticBezierTo(cl, y1 + u * .003, fl, y1)
      ..lineTo(fr, y1)
      ..quadraticBezierTo(cr, y1 + u * .003, cr, y0)
      ..close();
    c.drawPath(
      flare,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, y1),
          Offset(0, y0),
          [ink.litTop, ink.face, ink.shade],
          const [0, .55, 1],
        ),
    );
    // The gorges of the cavetto, and the sunlit abacus above.
    final gorge = Path();
    for (var i = 1; i < 7; i++) {
      final q = i / 7;
      final gx = cl + (cr - cl) * q;
      final out = (q - .5) * u * .03;
      gorge
        ..moveTo(gx, y0 - u * .001)
        ..lineTo(gx + out, y1 + u * .002);
    }
    c.drawPath(
      gorge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, u * .0013)
        ..color = Sketch.fade(ink.groove, .4),
    );
    c.drawRect(Rect.fromLTRB(fl - u * .002, y2, fr + u * .002, y1), Paint()..color = ink.litTop);
    c.drawLine(
      Offset(fl - u * .002, y1),
      Offset(fr + u * .002, y1),
      Paint()
        ..color = Sketch.fade(ink.shade, .6)
        ..strokeWidth = math.max(.5, u * .0014),
    );
  }

  /// The painted face of a tower: a colour band under the cornice, a row of
  /// khekher ticks and registers of tiny hieroglyphs between coloured rules.
  void _templeRelief(
    Canvas c,
    double cx,
    int seed,
    double h,
    _TempleInk ink,
    double crown,
    double floor,
    double Function(double) half,
  ) {
    final inset = h * .008;
    var y = crown + h * .012;
    for (final color in [ink.red, ink.blue, ink.gold]) {
      final ya = y, yb = y + h * .0042;
      final wa = half(ya) - inset, wb = half(yb) - inset;
      c.drawPath(Sketch.poly([cx - wa, ya, cx + wa, ya, cx + wb, yb, cx - wb, yb]), Paint()..color = color);
      y = yb;
    }
    // Khekher ticks: alternating red, blue and gold.
    final ticks = [Path(), Path(), Path()];
    final ty = crown + h * .034;
    final span = half(ty) - inset * 1.6;
    for (var i = 0; i < 9; i++) {
      final px = cx - span + span * 2 * i / 8;
      ticks[i % 3].addRect(Rect.fromLTWH(px - h * .0017, ty, h * .0034, h * .0085));
    }
    for (final (i, color) in [ink.red, ink.blue, ink.gold].indexed) {
      c.drawPath(ticks[i], Paint()..color = Sketch.fade(color, .9));
    }
    // The king smites his enemies in the big field under the frieze, with
    // registers of tiny hieroglyphs below it.
    final rule = Paint()
      ..strokeWidth = math.max(.6, h * .0028)
      ..color = Sketch.fade(ink.red, .5);
    void ruleAt(double dy) {
      final w = half(crown + dy) - h * .014;
      c.drawLine(Offset(cx - w, crown + dy), Offset(cx + w, crown + dy), rule);
    }

    ruleAt(h * .052);
    final outward = seed == 0 ? -1.0 : 1.0;
    _templeSmite(c, cx + outward * h * .02, -outward, crown + h * .122, h * .064, ink);
    ruleAt(h * .13);
    final glyph = Path(), blueGlyph = Path(), redGlyph = Path();
    for (var r = 0; ; r++) {
      final gy = crown + h * (.139 + .0115 * r);
      if (gy > floor - h * .035) break;
      final gw = half(gy) - inset * 1.8;
      for (var col = 0; col < 3; col++) {
        final gx = cx + (col - 1) * gw * .58;
        final q = Sketch.hash(seed * 977 + col * 7 + r);
        if (q < .14) continue;
        final target = q > .93
            ? blueGlyph
            : q > .86
            ? redGlyph
            : glyph;
        if (q < .5) {
          target.addRect(Rect.fromLTWH(gx - h * .0013, gy, h * .0026, h * .0085));
        } else if (q < .72) {
          target.addOval(Rect.fromCenter(center: Offset(gx, gy + h * .004), width: h * .0054, height: h * .0054));
        } else {
          target.addRect(Rect.fromLTWH(gx - h * .0033, gy + h * .003, h * .0066, h * .0026));
        }
      }
    }
    c.drawPath(glyph, Paint()..color = Sketch.fade(ink.groove, .55));
    c.drawPath(blueGlyph, Paint()..color = Sketch.fade(ink.blue, .85));
    c.drawPath(redGlyph, Paint()..color = Sketch.fade(ink.red, .85));
  }

  /// The king smiting his enemies, painted on a pylon face: red skin, white
  /// kilt and crown, a raised mace and a huddle of captives at his feet.
  void _templeSmite(Canvas c, double cx, double dir, double feet, double s, _TempleInk ink) {
    Offset p(double u, double v) => Offset(cx + dir * u * s, feet + v * s);
    Path trace(List<Offset> pts, {bool close = false}) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (final q in pts.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      return close ? (path..close()) : path;
    }

    final skin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(.8, s * .085)
      ..color = Sketch.fade(ink.red, .72);
    c.drawPath(trace([p(-.02, -.46), p(-.12, -.24), p(-.2, 0)]), skin);
    c.drawPath(trace([p(-.02, -.46), p(.1, -.26), p(.2, 0)]), skin);
    skin.strokeWidth = math.max(.9, s * .14);
    c.drawPath(trace([p(0, -.48), p(.04, -.74)]), skin);
    skin.strokeWidth = math.max(.8, s * .065);
    c.drawPath(trace([p(.03, -.74), p(-.14, -.82), p(-.1, -.98)]), skin);
    c.drawPath(trace([p(.04, -.72), p(.28, -.66)]), skin);
    c.drawPath(
      trace([p(-.08, -.5), p(.09, -.5), p(.17, -.3), p(-.1, -.3)], close: true),
      Paint()..color = Sketch.fade(ink.cloth, .85),
    );
    c.drawCircle(p(.07, -.85), s * .075, Paint()..color = Sketch.fade(ink.red, .8));
    c.drawPath(
      trace([p(.02, -.9), p(.1, -.9), p(.075, -1.08)], close: true),
      Paint()..color = Sketch.fade(ink.cloth, .9),
    );
    c.drawCircle(p(-.1, -1.02), s * .055, Paint()..color = Sketch.fade(ink.gold, .85));
    // The captives, small and dark, kneeling before him.
    final captive = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, s * .05)
      ..color = Sketch.fade(ink.blue, .6);
    for (final (u, v) in const [(.3, -.5), (.4, -.42)]) {
      c.drawCircle(p(u, v), s * .04, Paint()..color = Sketch.fade(ink.blue, .65));
      c.drawPath(trace([p(u - .02, v + .05), p(u - .06, v + .2), p(u + .05, v + .26)]), captive);
    }
  }

  /// The gate block set back between the towers: a deep doorway under a
  /// winged sun disk and its own cornice.
  void _templeGate(Canvas c, double x, double h, _TempleInk ink, double floor) {
    final gx = x + h * .012;
    final top = floor - h * .135;
    final half = h * .058;
    // A hall behind the gate lifts a second, hazier roof into the gap.
    final far = _templeFar;
    final hallTop = floor - h * .185;
    c.drawRect(
      Rect.fromLTRB(gx - h * .075, hallTop, gx + h * .075, floor),
      Paint()
        ..shader = Gradient.linear(Offset(0, hallTop), Offset(0, floor), [far.faceTop, far.face]),
    );
    c.drawRect(Rect.fromLTRB(gx - h * .075, hallTop + h * .006, gx + h * .075, hallTop + h * .0085), Paint()..color = Sketch.fade(far.red, .7));
    c.drawRect(Rect.fromLTRB(gx - h * .075, hallTop + h * .0085, gx + h * .075, hallTop + h * .011), Paint()..color = Sketch.fade(far.blue, .7));
    for (var i = 0; i < 3; i++) {
      final wx = gx + (i - 1) * h * .036;
      c.drawRect(Rect.fromLTWH(wx - h * .0032, hallTop + h * .017, h * .0064, h * .013), Paint()..color = Sketch.fade(far.deep, .55));
    }
    _templeCornice(c, gx, h, far, hallTop, h * .06, 0, .75);
    final shaded = Sketch.mix(ink.face, ink.shade, .5);
    c.drawRect(
      Rect.fromLTRB(gx - half, top, gx + half, floor),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, floor),
          [Sketch.mix(ink.faceTop, ink.shade, .3), shaded, ink.faceLow],
          const [0, .5, 1],
        ),
    );
    // The doorway.
    final door = h * .026, doorTop = floor - h * .088;
    c.drawRect(
      Rect.fromLTRB(gx - door - h * .004, doorTop - h * .004, gx + door + h * .004, floor),
      Paint()..color = ink.shade,
    );
    c.drawRect(
      Rect.fromLTRB(gx - door, doorTop, gx + door, floor),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, doorTop),
          Offset(0, floor),
          [ink.deep, Sketch.mix(ink.deep, ink.shade, .55)],
        ),
    );
    // The left jamb turns toward the sun; a far door gives the passage depth.
    c.drawRect(
      Rect.fromLTRB(gx - door, doorTop, gx - door + h * .004, floor),
      Paint()..color = Sketch.fade(ink.litTop, .35),
    );
    c.drawRect(
      Rect.fromLTRB(gx - door * .38, doorTop + h * .028, gx + door * .38, floor),
      Paint()..color = Sketch.fade(ink.face, .38),
    );
    // Two priests in white linen stand in the doorway.
    final foot = _templeGround(gx, h) - h * .002;
    final linen = Paint()..color = ink.cloth;
    final skin = Paint()..color = ink.grShade;
    for (final (dx, tall) in const [(-.009, .026), (.012, .022)]) {
      final px = gx + h * dx, top = foot - h * tall;
      c.drawPath(
        Sketch.poly([px - h * .0035, top + h * .006, px + h * .0035, top + h * .006, px + h * .0055, foot, px - h * .0055, foot]),
        linen,
      );
      c.drawCircle(Offset(px, top + h * .003), h * .0033, skin);
    }
    _templeWings(c, Offset(gx, top + h * .022), h * .1, ink);
    _templeCornice(c, gx, h, ink, top, half - h * .012, 0);
  }

  /// The winged sun disk over a gateway: gold disk, blue, red and gold pinions.
  void _templeWings(Canvas c, Offset at, double span, _TempleInk ink) {
    final w = math.max(.7, span * .045);
    for (final side in const [-1.0, 1.0]) {
      for (final (i, color) in [ink.blue, ink.red, ink.gold].indexed) {
        final y = at.dy + (i - 1) * span * .05;
        final reach = span * (.5 - i * .05);
        c.drawPath(
          Path()
            ..moveTo(at.dx + side * span * .07, y - span * .012)
            ..quadraticBezierTo(
              at.dx + side * reach * .6,
              y - span * .06,
              at.dx + side * reach,
              y - span * .02 + i * span * .02,
            ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 1.6
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      }
    }
    c.drawCircle(at, span * .062, Paint()..color = ink.gold);
    c.drawCircle(at, span * .028, Paint()..color = ink.litTop);
  }

  /// A seated pharaoh in front of the pylon, carved in red granite. With
  /// [tall] he wears the double crown instead of the striped headcloth.
  void _templeColossus(Canvas c, Offset base, double s, _TempleInk ink, {bool tall = false}) {
    final light = Paint()
      ..shader = Gradient.linear(
        Offset(base.dx - s * .3, 0),
        Offset(base.dx + s * .3, 0),
        [ink.grShade, ink.gr, ink.grLit],
        const [0, .55, 1],
      );
    final dark = Paint()..color = ink.grShade;
    void part(List<double> xy, Paint paint) => c.drawPath(Sketch.poly(xy, at: base, s: s), paint);
    // The figure throws its shadow on the pylon, away from the sun.
    c.drawPath(
      Sketch.poly(
        const [-.31, .0, -.31, -.52, -.26, -.78, -.185, -.77, -.11, -.99, .11, -.99, .185, -.77, .26, -.78, .31, -.52, .31, .0],
        at: base + Offset(-s * .5, s * .02),
        s: s,
      ),
      Paint()..color = Sketch.fade(ink.deep, .16),
    );
    // Plinth, throne block and the seat back rising behind the figure.
    part(const [-.4, .03, -.4, -.06, .4, -.06, .4, .03], Paint()..color = ink.grDeep);
    part(const [-.31, -.06, -.31, -.52, .31, -.52, .31, -.06], dark);
    part(const [-.27, -.5, -.27, -.78, -.2, -.84, .2, -.84, .27, -.78, .27, -.5], dark);
    // Two legs and the hands resting on the knees.
    part(const [-.25, -.06, -.25, -.5, -.02, -.5, -.02, -.06], light);
    part(const [.02, -.06, .02, -.5, .25, -.5, .25, -.06], light);
    final hand = Paint()..color = ink.grLit;
    part(const [-.24, -.5, -.24, -.57, -.09, -.57, -.09, -.5], hand);
    part(const [.09, -.5, .09, -.57, .24, -.57, .24, -.5], hand);
    // Torso with its upper arms, and the broad collar.
    part(const [-.15, -.55, -.18, -.72, -.13, -.79, .13, -.79, .18, -.72, .15, -.55], light);
    part(const [-.18, -.72, -.235, -.66, -.235, -.55, -.16, -.55], light);
    part(const [.18, -.72, .235, -.66, .235, -.55, .16, -.55], light);
    part(const [-.13, -.79, .13, -.79, .16, -.73, .0, -.67, -.16, -.73], Paint()..color = Sketch.fade(ink.gold, .85));
    part(const [-.045, -.79, -.045, -.86, .045, -.86, .045, -.79], light);
    // The headcloth, or the double crown, and the sunlit face.
    part(const [-.11, -.99, .11, -.99, .185, -.77, .09, -.78, .085, -.86, -.085, -.86, -.09, -.78, -.185, -.77], dark);
    if (tall) {
      part(const [-.09, -.97, .09, -.97, .075, -1.04, -.075, -1.04], Paint()..color = ink.red);
      part(const [-.05, -1.04, .05, -1.04, .06, -1.2, .0, -1.27, -.06, -1.2], Paint()..color = ink.cloth);
    } else {
      part(const [-.11, -.99, .11, -.99, .1, -.95, -.1, -.95], Paint()..color = ink.grLit);
      c.drawCircle(base + Offset(0, -s * .955), s * .02, Paint()..color = ink.gold);
    }
    part(const [-.065, -.86, -.065, -.95, .065, -.95, .065, -.86], hand);
    // A lit edge runs down the right of the seat.
    c.drawLine(
      base + Offset(s * .31, -s * .07),
      base + Offset(s * .31, -s * .5),
      Paint()
        ..color = Sketch.fade(ink.litTop, .55)
        ..strokeWidth = math.max(.5, s * .01),
    );
  }

  /// A granite obelisk: two faces, columns of inscription, a stepped plinth
  /// and a gilded pyramidion that catches the sun.
  static void _templeObelisk(Canvas c, Offset base, double height, _TempleInk ink, int seed) {
    final half = height * .06, neck = height * .042;
    final shoulder = base.dy - height * .9, tip = base.dy - height;
    const edge = .2;
    double wide(double y) => neck + (half - neck) * (y - shoulder) / (base.dy - shoulder);
    // Stepped plinth.
    for (final (k, (grow, top)) in const [(1.6, .04), (1.32, .075)].indexed) {
      final pw = half * grow;
      final y = base.dy - height * top;
      c.drawRect(
        Rect.fromLTRB(base.dx - pw, y, base.dx + pw * edge, base.dy + height * .02),
        Paint()..color = k == 0 ? ink.shade : ink.faceLow,
      );
      c.drawRect(
        Rect.fromLTRB(base.dx + pw * edge, y, base.dx + pw, base.dy + height * .02),
        Paint()..color = k == 0 ? ink.lit : ink.litLow,
      );
    }
    // The shaft: shaded face on the left, sunlit face on the right.
    final foot = base.dy - height * .05;
    c.drawPath(
      Sketch.poly([base.dx - half, foot, base.dx - neck, shoulder, base.dx + neck * edge, shoulder, base.dx + half * edge, foot]),
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx - half, 0),
          Offset(base.dx + half * edge, 0),
          [ink.grDeep, ink.grShade],
        ),
    );
    c.drawPath(
      Sketch.poly([base.dx + half * edge, foot, base.dx + neck * edge, shoulder, base.dx + neck, shoulder, base.dx + half, foot]),
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx + half * edge, 0),
          Offset(base.dx + half, 0),
          [ink.gr, ink.grLit],
        ),
    );
    // Columns of inscription running down both faces.
    final glyphs = Path();
    for (var r = 0; ; r++) {
      final y = shoulder + height * (.05 + .028 * r);
      if (y > base.dy - height * .09) break;
      final w = wide(y);
      for (final u in const [-.68, -.28, .6]) {
        final q = Sketch.hash(seed * 401 + r * 5 + (u * 10).round());
        if (q < .12) continue;
        final gx = base.dx + u * w;
        glyphs
          ..moveTo(gx, y)
          ..lineTo(gx, y + height * (.008 + .012 * q));
      }
    }
    c.drawPath(
      glyphs,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.55, height * .0055)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(ink.grDeep, .5),
    );
    // The arris where the two faces meet.
    c.drawLine(
      Offset(base.dx + half * edge, foot),
      Offset(base.dx + neck * edge, shoulder),
      Paint()
        ..color = Sketch.fade(ink.litTop, .55)
        ..strokeWidth = math.max(.5, height * .004),
    );
    // The gilded pyramidion.
    c.drawPath(
      Sketch.poly([base.dx - neck, shoulder, base.dx, tip, base.dx + neck * edge, shoulder]),
      Paint()..color = ink.gildShade,
    );
    c.drawPath(
      Sketch.poly([base.dx + neck * edge, shoulder, base.dx, tip, base.dx + neck, shoulder]),
      Paint()..color = ink.gild,
    );
  }

  /// Enclosure walls run away from both sides of the pylon.
  void _templeWalls(Canvas c, double x, double h, double floor, double limit) {
    final ink = _TempleInk(.3);
    final top = floor - h * .092;
    _templeWall(c, x - h * 1.4, x - h * .17, top, h, ink);
    _templeWall(c, x + h * .17, math.min(x + h * .46, limit), top, h, ink, cap: true);
  }

  void _templeWall(Canvas c, double x0, double x1, double top, double h, _TempleInk ink, {bool cap = false}) {
    var deep = 0.0;
    for (var px = x0; px <= x1; px += h * .05) {
      deep = math.max(deep, _templeGround(px, h));
    }
    final bottom = deep + h * .02;
    c.drawRect(
      Rect.fromLTRB(x0, top, x1, bottom),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          [ink.faceTop, ink.face, ink.faceLow],
          const [0, .5, 1],
        ),
    );
    final joint = Path();
    for (var px = x0 + h * .06; px < x1; px += h * .09) {
      joint
        ..moveTo(px, top + h * .01)
        ..lineTo(px, bottom);
    }
    c.drawPath(
      joint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0014)
        ..color = Sketch.fade(ink.groove, .18),
    );
    c.drawRect(Rect.fromLTRB(x0, top - h * .009, x1, top), Paint()..color = ink.litTop);
    c.drawRect(Rect.fromLTRB(x0, top, x1, top + h * .007), Paint()..color = Sketch.fade(ink.shade, .5));
    c.drawRect(Rect.fromLTRB(x0, top + h * .009, x1, top + h * .0115), Paint()..color = Sketch.fade(ink.red, .8));
    c.drawRect(Rect.fromLTRB(x0, top + h * .0115, x1, top + h * .014), Paint()..color = Sketch.fade(ink.blue, .8));
    if (cap) {
      // The wall's end turns a lit face to the sun.
      c.drawRect(Rect.fromLTRB(x1, top - h * .009, x1 + h * .009, bottom), Paint()..color = ink.lit);
      c.drawRect(Rect.fromLTRB(x1 - h * .002, top - h * .011, x1 + h * .011, top - h * .006), Paint()..color = ink.litTop);
    }
  }

  /// A few date palms over the enclosure.
  void _templeGrove(Canvas c, double x, double h, double limit) {
    final ink = _TempleInk(.3);
    // Kept low enough that the crowns stay under the Sphinx's paws behind them.
    for (final (dx, tall, lean) in const [(.34, .092, .05), (.42, .078, -.06)]) {
      final px = math.min(x + h * dx, limit - h * tall * .5);
      // At narrow widths the pylon would hide the palms; leave them out.
      if (px < x + h * .27) continue;
      Sketch.palm(
        c,
        Offset(px, _templeGround(px, h) + h * .012),
        h * tall,
        lean: lean,
        trunk: ink.trunk,
        trunkShade: ink.trunkShade,
        frond: ink.frond,
        frondLit: ink.frondLit,
        detail: false,
      );
    }
  }

  /// An avenue of sphinxes leaving the temple, shrinking into the haze. Each
  /// stands on a plinth that steps down with the dune beneath it.
  void _templeAvenue(Canvas c, double x, double h) {
    var px = x + h * .39;
    for (var i = 0; i < 6; i++) {
      final k = i / 5;
      final s = h * (.066 - .03 * k);
      final ink = _TempleInk(.24 + .14 * k);
      var high = h * 2, low = 0.0;
      for (final dx in const [-.74, -.3, 0.0, .35, .7]) {
        final g = _templeGround(px + dx * s, h);
        high = math.min(high, g);
        low = math.max(low, g);
      }
      _templeSphinx(c, Offset(px, high + h * .004), s, ink, low + h * .012);
      px += s * (1.5 + .1 * k);
    }
  }

  /// A crouching sphinx in profile, facing the pylon, on its plinth.
  static void _templeSphinx(Canvas c, Offset base, double s, _TempleInk ink, double ground) {
    final bottom = math.max(ground, base.dy + s * .05);
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .74, base.dy - s * .1, base.dx + s * .7, bottom),
      Paint()..color = ink.lit,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .74, base.dy - s * .035, base.dx + s * .7, bottom),
      Paint()..color = ink.shade,
    );
    c.drawPath(
      Sketch.poly(
        const [
          .58, -.10, .62, -.22, .52, -.34, .30, -.39, .08, -.39, -.02, -.44, //
          -.08, -.56, -.10, -.66, -.20, -.74, -.32, -.70, -.37, -.62, -.385, -.58,
          -.37, -.54, -.33, -.50, -.30, -.44, -.28, -.34, -.34, -.26, -.66, -.22, -.68, -.10,
        ],
        at: base,
        s: s,
      ),
      Paint()
        ..shader = Gradient.linear(
          base + Offset(0, -s * .75),
          base,
          [ink.litTop, ink.face, ink.shade],
          const [0, .4, 1],
        ),
    );
    // Nemes lappet on the shoulder, the sunlit face and the haunch in shade.
    c.drawPath(
      Sketch.poly(const [-.10, -.66, -.02, -.44, .0, -.36, -.1, -.36, -.16, -.5], at: base, s: s),
      Paint()..color = Sketch.fade(ink.groove, .6),
    );
    c.drawPath(
      Sketch.poly(const [-.32, -.70, -.37, -.62, -.385, -.58, -.37, -.54, -.33, -.50, -.26, -.56, -.25, -.66], at: base, s: s),
      Paint()..color = Sketch.fade(ink.litTop, .7),
    );
    c.drawPath(
      Sketch.poly(const [.2, -.1, .58, -.1, .62, -.22, .52, -.34, .34, -.3], at: base, s: s),
      Paint()..color = Sketch.fade(ink.groove, .3),
    );
  }

  static void _duneTuft(Canvas c, Offset at, double s) {
    final dark = Path(), light = Path();
    _duneBlades(dark, light, at.dx, at.dy, s, at.dx.round());
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .12
      ..color = _hazed(const Color(0xff8f8b4a), .3);
    c.drawPath(dark, paint);
    c.drawPath(
      light,
      paint
        ..strokeWidth = s * .08
        ..color = _hazed(const Color(0xffc2bd78), .3),
    );
  }

  // ---------------------------------------------------------------------------
  // The Nile (low band): crops, villages and palm groves on the far bank, then
  // the river itself in `_nileOverlay`. One repeat is `_nileSpan` heights wide.

  /// The low band's repeat width in viewport heights (see `period`).
  static const _nileSpan = 2.4;

  /// The desert/field border in heights from the top: periodic, so it tiles.
  static double _nileEdge(double u) =>
      .774 +
      Sketch.waves(u, const [
        (_nileSpan / 3, .0032, .7),
        (_nileSpan / 8, .0018, 2.1),
      ]);

  /// The two villages that sit on low mounds above the flood: (from, to, seed).
  static const _nileMounds = [(.14, .7, 3), (1.84, 2.3, 8)];

  static double _nileMoundY(double u, double u0, double u1) {
    final t = ((u - u0) / (u1 - u0)).clamp(0.0, 1.0);
    return .793 - .0125 * math.pow(math.sin(math.pi * t), .55);
  }

  /// The far bank of the Nile: fields, villages, groves and the folk who work
  /// them, painted back to front.
  static void _bank(Canvas c, double h) {
    _nileStrip(c, h, far: true);
    for (final (u0, u1, seed) in _nileMounds) {
      _nileVillage(c, h, u0, u1, seed);
    }
    _nileStrip(c, h, far: false);
    _nileGroves(c, h);
    _nileBankLife(c, h);
  }

  /// A strip of patchwork fields: quadrilaterals of different crops with
  /// furrows, lit far edges, hedges and the odd irrigation canal.
  static void _nileStrip(Canvas c, double h, {required bool far}) {
    final span = _nileSpan * h;
    final yBot = far ? .7905 : .813;
    double yTop(double u) => far ? _nileEdge(u) : .7895;
    const crops = [
      (Color(0xff8fc25c), Color(0xffa8d36e)),
      (Color(0xffb5cf66), Color(0xffc9de7c)),
      (Color(0xff5f9647), Color(0xff7bad57)),
      (Color(0xffd5c46e), Color(0xffe6d987)),
      (Color(0xffae8b5c), Color(0xffc3a370)),
      (Color(0xff74a651), Color(0xff8fbb63)),
    ];
    final haze = far ? .2 : 0.0;
    final furrows = Path(), glints = Path(), hedges = Path();
    final seed = far ? 10 : 40;
    var x = 0.0, kind = seed % 6, i = 0, slantL = 0.0;
    while (x < span - h * .01) {
      var w = (.15 + .26 * Sketch.hash(seed + i * 3)) * h;
      if (span - (x + w) < h * .2) w = span - x;
      final xr = x + w;
      final slantR = xr >= span - .5
          ? 0.0
          : (Sketch.hash(seed + i * 3 + 1) - .5) * h * .035;
      kind = (kind + 1 + (Sketch.hash(seed + i * 3 + 2) * 5).floor()) % 6;
      final (base, lit) = crops[kind];
      final tall = kind == 2 || kind == 3;
      // The patch: a slanted quadrilateral, its top following the border and
      // bumpy where the crop is tall.
      final patch = Path()..moveTo(x + slantL, yBot * h);
      final ytL = yTop(x / h) * h;
      patch.lineTo(x, ytL);
      final n = math.max(2, (w / (h * .035)).round());
      for (var k = 1; k <= n; k++) {
        final px = x + w * k / n;
        var py = yTop(px / h) * h;
        if (tall && k < n) py -= h * .0032 * (k.isOdd ? 1 : .2);
        patch.lineTo(px, py);
      }
      patch
        ..lineTo(xr + slantR, yBot * h)
        ..close();
      c.drawPath(patch, Paint()..color = _hazed(base, haze));
      // Sunlit far edge of the crop.
      glints
        ..moveTo(x + h * .0012, ytL + h * .0012)
        ..lineTo(xr - h * .0012, yTop(xr / h) * h + h * .0012);
      // Furrows: rows bunch toward the horizon, so spacing grows downhill.
      final yc = yTop((x + w / 2) / h) * h;
      const rows = 6;
      for (var r = 1; r < rows; r++) {
        final f = math.pow(r / rows, 1.25).toDouble();
        final y = yc + (yBot * h - yc) * f;
        final k = (y - yc) / (yBot * h - yc);
        final l = x + slantL * k + h * .0012, rr = xr + slantR * k - h * .0012;
        if (far && r > 3) break;
        if (r.isEven) {
          furrows
            ..moveTo(l, y)
            ..lineTo(rr, y);
        }
      }
      if (i > 0) {
        hedges
          ..moveTo(x, ytL)
          ..lineTo(x + slantL, yBot * h);
      }
      x = xr;
      slantL = slantR;
      i++;
    }
    c.drawPath(
      furrows,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .0016)
        ..color = Sketch.fade(_hazed(const Color(0xff3f6a2a), haze), .34),
    );
    c.drawPath(
      glints,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .0018)
        ..color = Sketch.fade(const Color(0xfff3f6b4), .42),
    );
    c.drawPath(
      hedges,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, h * .0028)
        ..color = Sketch.fade(_hazed(const Color(0xff3e6a2f), haze), .38),
    );
    if (!far) {
      // Irrigation canals catch the sky between the crops.
      for (final (u, len, dy) in const [(.9, .34, .0), (1.55, .28, .002)]) {
        final y = (.7985 + dy) * h;
        final canal = Path()
          ..moveTo(u * h, y)
          ..lineTo((u + len) * h, y - h * .0006)
          ..lineTo((u + len - .03) * h, y + h * .0042)
          ..lineTo((u + .02) * h, y + h * .0042)
          ..close();
        c.drawPath(canal, Paint()..color = const Color(0xff4f8a63));
        c.drawPath(
          Sketch.poly([
            (u + .03) * h, y + h * .0008, //
            (u + len - .02) * h, y + h * .0006,
            (u + len - .04) * h, y + h * .0034,
            (u + .025) * h, y + h * .0034,
          ]),
          Paint()..color = const Color(0xff9fd3cf),
        );
      }
    }
  }

  // --- villages ---------------------------------------------------------------

  /// A village on its mound: earth, mud-brick houses, a sheikh's tomb, a
  /// dovecote and, in the bigger one, a small mosque with its minaret.
  static void _nileVillage(Canvas c, double h, double u0, double u1, int seed) {
    final steps = ((u1 - u0) / .025).round();
    final mound = Path()..moveTo(u0 * h, .8 * h);
    for (var i = 0; i <= steps; i++) {
      final u = u0 + (u1 - u0) * i / steps;
      mound.lineTo(u * h, _nileMoundY(u, u0, u1) * h);
    }
    mound
      ..lineTo(u1 * h, .8 * h)
      ..close();
    c.drawPath(mound, Paint()..color = const Color(0xffd6ad76));
    final rim = Path()..moveTo(u0 * h, _nileMoundY(u0, u0, u1) * h);
    for (var i = 0; i <= steps; i++) {
      final u = u0 + (u1 - u0) * i / steps;
      rim.lineTo(u * h, _nileMoundY(u, u0, u1) * h);
    }
    c.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, h * .0026)
        ..color = const Color(0xfff0d29a),
    );
    // Trees and palms tuck in behind the walls, in shade.
    final backdrop = seed == 3
        ? const [(.2, .085), (.36, .075), (.5, .08), (.61, .09)]
        : const [(1.9, .08), (2.06, .072), (2.2, .085)];
    for (var i = 0; i < backdrop.length; i++) {
      final (u, tall) = backdrop[i];
      _nilePalm(
        c,
        Offset(u * h, _nileMoundY(u, u0, u1) * h + h * .002),
        h * tall,
        lean: (Sketch.hash(seed * 7 + i) - .5) * .18,
        seed: seed * 7 + i,
        haze: .3,
      );
    }
    void house(double u, double w, double ht, int kind, int s) {
      final y = _nileMoundY(u, u0, u1) * h + h * .003;
      _nileHouse(c, u * h, y, w * h, ht * h, kind, seed * 31 + s, .12);
    }

    if (seed == 3) {
      house(.19, .06, .048, 0, 0);
      house(.255, .05, .066, 1, 1);
      _nileTomb(c, Offset(.335 * h, _nileMoundY(.335, u0, u1) * h + h * .003), h * .058, .1);
      house(.405, .07, .05, 2, 2);
      _nileDovecote(c, Offset(.47 * h, _nileMoundY(.47, u0, u1) * h + h * .004), h * .115, .1);
      house(.535, .056, .072, 3, 3);
      house(.595, .06, .045, 0, 4);
      house(.65, .052, .06, 1, 5);
    } else {
      house(1.88, .055, .048, 2, 0);
      house(1.945, .06, .06, 0, 1);
      _nileMosque(c, Offset(2.07 * h, _nileMoundY(2.07, u0, u1) * h + h * .003), h, .1);
      house(2.175, .05, .046, 1, 2);
      house(2.24, .052, .056, 3, 3);
    }
  }

  /// A flat-roofed mud-brick house seen at a slight angle: lit end wall,
  /// parapet, small windows, a doorway and something stacked on the roof.
  static void _nileHouse(
    Canvas c,
    double x,
    double base,
    double w,
    double ht,
    int kind,
    int seed,
    double haze,
  ) {
    const walls = [
      (Color(0xffc99c6a), Color(0xffe3bc88), Color(0xffedca9a), Color(0xffa87b4c)),
      (Color(0xffe9dcc2), Color(0xfffaf0da), Color(0xfffff7e6), Color(0xffc7b491)),
      (Color(0xffd9b17c), Color(0xffedca95), Color(0xfff3d8a6), Color(0xffb88e5b)),
      (Color(0xffd7a784), Color(0xffe9c19e), Color(0xfff1cfb2), Color(0xffb6836a)),
    ];
    final (a, b, r, s) = walls[kind % 4];
    final face = _hazed(a, haze), side = _hazed(b, haze);
    final roof = _hazed(r, haze), shade = _hazed(s, haze);
    final d = w * .24, rise = w * .09;
    final left = x - w / 2, right = x + w / 2;
    // Roof clutter first, so the parapet hides its feet.
    switch ((seed * 7 + 3) % 6) {
      case 0:
        c.drawPath(
          Sketch.poly([
            left + w * .12, base - ht, //
            left + w * .2, base - ht - ht * .3,
            left + w * .56, base - ht - ht * .34,
            left + w * .62, base - ht,
          ]),
          Paint()..color = _hazed(const Color(0xffc9b068), haze),
        );
      case 1:
        c.drawRect(
          Rect.fromLTRB(left + w * .5, base - ht - ht * .32, left + w * .8, base - ht),
          Paint()..color = face,
        );
        c.drawRect(
          Rect.fromLTRB(left + w * .48, base - ht - ht * .38, left + w * .82, base - ht - ht * .3),
          Paint()..color = roof,
        );
      case 2:
        c.drawPath(
          Path()
            ..moveTo(left + w * .16, base - ht)
            ..quadraticBezierTo(left + w * .16, base - ht * 1.4, left + w * .36, base - ht * 1.4)
            ..quadraticBezierTo(left + w * .56, base - ht * 1.4, left + w * .56, base - ht)
            ..close(),
          Paint()..color = _hazed(const Color(0xfff3e7cd), haze),
        );
      case 3:
        // A black water tank on a low stand.
        c.drawRect(
          Rect.fromLTRB(left + w * .56, base - ht - ht * .05, left + w * .8, base - ht),
          Paint()..color = _hazed(const Color(0xff6f5238), haze),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left + w * .54, base - ht - ht * .24, left + w * .82, base - ht - ht * .04),
            Radius.circular(w * .08),
          ),
          Paint()..color = _hazed(const Color(0xff454c52), haze),
        );
        c.drawRect(
          Rect.fromLTRB(left + w * .72, base - ht - ht * .22, left + w * .8, base - ht - ht * .06),
          Paint()..color = _hazed(const Color(0xff6b747a), haze),
        );
      case 4:
        // Washing on a line between two poles.
        final pole = Paint()
          ..color = _hazed(const Color(0xff5b3c28), haze)
          ..strokeWidth = math.max(.6, w * .014);
        c.drawLine(Offset(left + w * .14, base - ht), Offset(left + w * .14, base - ht - ht * .42), pole);
        c.drawLine(Offset(left + w * .84, base - ht), Offset(left + w * .84, base - ht - ht * .42), pole);
        c.drawLine(Offset(left + w * .14, base - ht - ht * .4), Offset(left + w * .84, base - ht - ht * .36), pole);
        for (final (fx, col) in const [(.26, 0xff4f7fa8), (.42, 0xfff3ead6), (.58, 0xffc7893f), (.72, 0xff8c5a7a)]) {
          c.drawRect(
            Rect.fromLTWH(left + w * fx, base - ht - ht * .39, w * .09, ht * .2),
            Paint()..color = _hazed(Color(col), haze),
          );
        }
      default:
        // A satellite dish tilted at the sky.
        c.drawOval(
          Rect.fromCenter(center: Offset(left + w * .7, base - ht - ht * .28), width: w * .2, height: w * .14),
          Paint()..color = _hazed(const Color(0xffdedad0), haze),
        );
        c.drawLine(
          Offset(left + w * .7, base - ht - ht * .2),
          Offset(left + w * .7, base - ht),
          Paint()
            ..color = _hazed(const Color(0xff7d766c), haze)
            ..strokeWidth = math.max(.6, w * .02),
        );
    }
    c.drawRect(Rect.fromLTRB(left, base - ht, right, base), Paint()..color = face);
    c.drawPath(
      Sketch.poly([
        right, base, right + d, base - rise, //
        right + d, base - ht - rise, right, base - ht,
      ]),
      Paint()..color = side,
    );
    c.drawPath(
      Sketch.poly([
        left, base - ht, left + d, base - ht - rise, //
        right + d, base - ht - rise, right, base - ht,
      ]),
      Paint()..color = roof,
    );
    // Parapet lip and its shadow, roof-beam ends peeking through.
    c.drawRect(
      Rect.fromLTRB(left, base - ht + ht * .07, right, base - ht + ht * .15),
      Paint()..color = Sketch.fade(shade, .55),
    );
    final beams = Paint()..color = Sketch.fade(_hazed(const Color(0xff5b3c28), haze), .8);
    for (var k = 0; k < 3; k++) {
      c.drawRect(
        Rect.fromLTWH(left + w * (.16 + k * .28), base - ht + ht * .09, w * .08, ht * .07),
        beams,
      );
    }
    // Windows with light lintels, and a doorway.
    final dark = Paint()..color = _hazed(const Color(0xff4d3122), haze);
    final lintel = Paint()..color = Sketch.fade(roof, .9);
    for (final (fx, fy) in seed.isEven
        ? const [(.2, .34), (.62, .34)]
        : const [(.24, .38), (.5, .38), (.76, .38)]) {
      final r = Rect.fromLTWH(left + w * fx, base - ht + ht * fy, w * .13, ht * .2);
      c.drawRect(r, dark);
      c.drawRect(Rect.fromLTWH(r.left - w * .02, r.top - ht * .04, r.width + w * .04, ht * .04), lintel);
    }
    final doorX = left + w * (seed.isEven ? .38 : .08);
    c.drawPath(
      Path()
        ..moveTo(doorX, base)
        ..lineTo(doorX, base - ht * .34)
        ..quadraticBezierTo(doorX + w * .07, base - ht * .5, doorX + w * .14, base - ht * .34)
        ..lineTo(doorX + w * .14, base)
        ..close(),
      kind == 3 ? (Paint()..color = _hazed(const Color(0xff4d7c8a), haze)) : dark,
    );
  }

  /// A sheikh's tomb: a whitewashed cube under a small dome.
  static void _nileTomb(Canvas c, Offset base, double s, double haze) {
    final face = _hazed(const Color(0xffefe4cc), haze);
    final side = _hazed(const Color(0xfffff6e2), haze);
    final shade = _hazed(const Color(0xffc9b594), haze);
    final w = s, ht = s * .66;
    c.drawRect(
      Rect.fromLTRB(base.dx - w / 2, base.dy - ht, base.dx + w / 2, base.dy),
      Paint()..color = face,
    );
    c.drawPath(
      Sketch.poly([
        base.dx + w / 2, base.dy, base.dx + w * .68, base.dy - w * .05, //
        base.dx + w * .68, base.dy - ht - w * .05, base.dx + w / 2, base.dy - ht,
      ]),
      Paint()..color = side,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - w * .56, base.dy - ht - w * .07, base.dx + w * .56, base.dy - ht + w * .03),
      Paint()..color = side,
    );
    // The dome, lit on the right.
    final top = base.dy - ht - w * .07;
    final dome = Rect.fromCenter(center: Offset(base.dx, top), width: w * .82, height: w * .82);
    c.drawArc(dome, math.pi, math.pi, true, Paint()..color = face);
    c.drawArc(
      Rect.fromCenter(center: Offset(base.dx + w * .1, top), width: w * .62, height: w * .82),
      -math.pi * .5,
      math.pi * .5,
      true,
      Paint()..color = side,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - w * .06, top - w * .05, base.dx + w * .06, top),
      Paint()..color = shade,
    );
    c.drawLine(
      Offset(base.dx, top - w * .38),
      Offset(base.dx, top - w * .6),
      Paint()
        ..color = shade
        ..strokeWidth = math.max(.7, w * .03),
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx - w * .09, base.dy)
        ..lineTo(base.dx - w * .09, base.dy - ht * .42)
        ..quadraticBezierTo(base.dx, base.dy - ht * .68, base.dx + w * .09, base.dy - ht * .42)
        ..lineTo(base.dx + w * .09, base.dy)
        ..close(),
      Paint()..color = _hazed(const Color(0xff5f4230), haze),
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - w / 2, base.dy - ht * .12, base.dx + w / 2, base.dy),
      Paint()..color = Sketch.fade(shade, .5),
    );
  }

  /// A tapering pigeon tower, peppered with nesting holes and crowned with
  /// four little horns.
  static void _nileDovecote(Canvas c, Offset base, double ht, double haze) {
    final face = _hazed(const Color(0xffe1c69a), haze);
    final lit = _hazed(const Color(0xfff2dcb0), haze);
    final shade = _hazed(const Color(0xffb98f62), haze);
    final bottom = ht * .2, top = ht * .15;
    c.drawPath(
      Sketch.poly([
        base.dx - bottom, base.dy, base.dx - top, base.dy - ht, //
        base.dx + top, base.dy - ht, base.dx + bottom, base.dy,
      ]),
      Paint()..color = face,
    );
    c.drawPath(
      Sketch.poly([
        base.dx + top * .25, base.dy - ht, base.dx + top, base.dy - ht, //
        base.dx + bottom, base.dy, base.dx + bottom * .25, base.dy,
      ]),
      Paint()..color = lit,
    );
    c.drawPath(
      Sketch.poly([
        base.dx - bottom, base.dy, base.dx - top, base.dy - ht, //
        base.dx - top * .55, base.dy - ht, base.dx - bottom * .55, base.dy,
      ]),
      Paint()..color = Sketch.fade(shade, .55),
    );
    // Cornices at three heights and a crown of horns.
    final ledge = Paint()..color = lit;
    for (final f in const [.34, .68, 1.0]) {
      final half = bottom + (top - bottom) * f + ht * .03;
      c.drawRect(
        Rect.fromLTRB(base.dx - half, base.dy - ht * f - ht * .02, base.dx + half, base.dy - ht * f + ht * .012),
        ledge,
      );
    }
    for (final dx in const [-.85, -.28, .28, .85]) {
      c.drawPath(
        Sketch.poly([
          base.dx + dx * top - ht * .035, base.dy - ht - ht * .02, //
          base.dx + dx * top, base.dy - ht - ht * .12,
          base.dx + dx * top + ht * .035, base.dy - ht - ht * .02,
        ]),
        ledge,
      );
    }
    final holes = Path();
    for (var row = 0; row < 8; row++) {
      final f = .1 + row * .11 + (row >= 3 ? .02 : 0) + (row >= 6 ? .02 : 0);
      final half = bottom + (top - bottom) * f;
      for (var k = -1; k <= 1; k++) {
        if (Sketch.hash(row * 5 + k + 60) < .18) continue;
        final px = base.dx + k * half * .48;
        holes.addRect(Rect.fromCenter(center: Offset(px, base.dy - ht * f), width: ht * .038, height: ht * .05));
      }
    }
    c.drawPath(holes, Paint()..color = _hazed(const Color(0xff5b3d2b), haze));
  }

  /// A village mosque: a low prayer hall with a small dome and a tall,
  /// slim minaret with two balconies.
  static void _nileMosque(Canvas c, Offset base, double h, double haze) {
    final face = _hazed(const Color(0xffefe2c6), haze);
    final lit = _hazed(const Color(0xfffff5df), haze);
    final shade = _hazed(const Color(0xffc5ae8a), haze);
    final gold = _hazed(const Color(0xffe6c35a), haze);
    // Prayer hall with a dome.
    final w = h * .085, ht = h * .036;
    c.drawRect(
      Rect.fromLTRB(base.dx - w / 2, base.dy - ht, base.dx + w / 2, base.dy),
      Paint()..color = face,
    );
    c.drawPath(
      Sketch.poly([
        base.dx + w / 2, base.dy, base.dx + w * .6, base.dy - w * .05, //
        base.dx + w * .6, base.dy - ht - w * .05, base.dx + w / 2, base.dy - ht,
      ]),
      Paint()..color = lit,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - w * .52, base.dy - ht - h * .004, base.dx + w * .52, base.dy - ht + h * .004),
      Paint()..color = lit,
    );
    final dr = w * .26;
    final domeC = Offset(base.dx - w * .12, base.dy - ht - h * .002);
    c.drawArc(Rect.fromCenter(center: domeC, width: dr * 2, height: dr * 2.2), math.pi, math.pi, true, Paint()..color = face);
    c.drawArc(
      Rect.fromCenter(center: domeC + Offset(dr * .25, 0), width: dr * 1.4, height: dr * 2.2),
      -math.pi / 2,
      math.pi / 2,
      true,
      Paint()..color = lit,
    );
    c.drawLine(
      domeC - Offset(0, dr * 1.05),
      domeC - Offset(0, dr * 1.6),
      Paint()
        ..color = gold
        ..strokeWidth = math.max(.8, h * .0022)
        ..strokeCap = StrokeCap.round,
    );
    // Arched windows along the hall.
    final win = Paint()..color = _hazed(const Color(0xff4d6a72), haze);
    for (var k = 0; k < 4; k++) {
      final px = base.dx - w * .38 + k * w * .21;
      c.drawPath(
        Path()
          ..moveTo(px, base.dy - ht * .12)
          ..lineTo(px, base.dy - ht * .5)
          ..quadraticBezierTo(px + w * .03, base.dy - ht * .68, px + w * .06, base.dy - ht * .5)
          ..lineTo(px + w * .06, base.dy - ht * .12)
          ..close(),
        win,
      );
    }
    // The minaret.
    final mx = base.dx + w * .62;
    final mh = h * .135, mw = h * .0105;
    c.drawPath(
      Sketch.poly([
        mx - mw, base.dy, mx - mw * .8, base.dy - mh, //
        mx + mw * .8, base.dy - mh, mx + mw, base.dy,
      ]),
      Paint()..color = face,
    );
    c.drawPath(
      Sketch.poly([
        mx + mw * .1, base.dy, mx + mw * .1, base.dy - mh, //
        mx + mw * .8, base.dy - mh, mx + mw, base.dy,
      ]),
      Paint()..color = lit,
    );
    for (final f in const [.55, .86]) {
      final y = base.dy - mh * f;
      c.drawRect(Rect.fromLTRB(mx - mw * 1.7, y - h * .003, mx + mw * 1.7, y + h * .002), Paint()..color = shade);
      c.drawRect(Rect.fromLTRB(mx - mw * 1.5, y - h * .0075, mx + mw * 1.5, y - h * .003), Paint()..color = lit);
    }
    final capY = base.dy - mh;
    c.drawPath(
      Path()
        ..moveTo(mx - mw * 1.05, capY)
        ..quadraticBezierTo(mx - mw * 1.0, capY - mw * 1.9, mx, capY - mw * 3.0)
        ..quadraticBezierTo(mx + mw * 1.0, capY - mw * 1.9, mx + mw * 1.05, capY)
        ..close(),
      Paint()..color = _hazed(const Color(0xff87aa9c), haze),
    );
    c.drawLine(
      Offset(mx, capY - mw * 3.0),
      Offset(mx, capY - mw * 4.6),
      Paint()
        ..color = gold
        ..strokeWidth = math.max(.8, h * .0022)
        ..strokeCap = StrokeCap.round,
    );
    c.drawRect(
      Rect.fromLTRB(mx - mw * .35, base.dy - mh * .3, mx + mw * .35, base.dy - mh * .22),
      win,
    );
  }

  // --- palms, trees ---------------------------------------------------------------

  /// The palm groves: (u, height, lean, layer). Layer 0 is the far tier in
  /// haze, 2 stands at the water's edge. Clear of the repeat's seam.
  static const _nileGrove = [
    (.15, .115, .05, 2),
    (.69, .11, -.04, 2),
    (.9, .09, .04, 1),
    (.97, .125, -.05, 2),
    (1.13, .135, .03, 2),
    (1.27, .095, -.05, 1),
    (1.36, .118, .04, 2),
    (1.45, .085, .05, 0),
    (1.53, .125, -.04, 2),
    (1.83, .105, .05, 2),
    (2.31, .095, -.04, 2),
  ];

  static void _nileGroves(Canvas c, double h) {
    final shadows = Path();
    // Farther tiers first so the near ones overlap them.
    for (var layer = 0; layer < 3; layer++) {
      for (var i = 0; i < _nileGrove.length; i++) {
        final (u, tall, lean, l) = _nileGrove[i];
        if (l != layer) continue;
        final y = switch (l) {
          0 => .786,
          1 => .797,
          _ => .809,
        };
        final base = Offset(u * h, y * h);
        _nilePalm(c, base, h * tall, lean: lean, seed: i + 100, haze: l == 0 ? .3 : (l == 1 ? .1 : 0), dates: l > 0);
        // A long, low shadow thrown away from the sun.
        shadows
          ..moveTo(base.dx + h * .004, base.dy - h * .001)
          ..lineTo(base.dx - h * tall * .95, base.dy - h * .003)
          ..lineTo(base.dx - h * tall * .95, base.dy + h * .001)
          ..lineTo(base.dx - h * .004, base.dy + h * .003)
          ..close();
      }
    }
    _nileTree(c, Offset(.77 * h, .799 * h), h * .085, 0);
    _nileTree(c, Offset(1.76 * h, .798 * h), h * .075, 1);
    // Tamarisk bushes and stacks of cane and hay along the field edges.
    for (var i = 0; i < 16; i++) {
      final u = .05 + 2.3 * (i + Sketch.hash(i + 2100) * .8) / 16;
      if ((u > .14 && u < .7) || (u > 1.84 && u < 2.3)) continue;
      final near = Sketch.hash(i + 2200) < .5;
      _nileBush(c, Offset(u * h, (near ? .8 : .789) * h), h * (.018 + .012 * Sketch.hash(i + 2300)), haze: near ? 0 : .15);
    }
    _nileStack(c, Offset(.74 * h, .794 * h), h * .034);
    _nileStack(c, Offset(1.9 * h, .797 * h), h * .03);
    _nileStack(c, Offset(1.06 * h, .795 * h), h * .028);
    c.drawPath(shadows, Paint()..color = const Color(0x2a1f4a2a));
  }

  /// A date palm: slender curved trunk with a flared foot and scar pattern,
  /// a shaggy collar and a crown of serrated, arching pinnate fronds, with
  /// dates hanging in the shade of the crown.
  static void _nilePalm(
    Canvas c,
    Offset base,
    double height, {
    double lean = 0,
    int seed = 0,
    double haze = 0,
    bool dates = false,
  }) {
    final trunk = _hazed(const Color(0xffa98a68), haze);
    final trunkShade = _hazed(const Color(0xff7d6249), haze);
    final crown = base + Offset(lean * height, -height);
    final bend = base + Offset(lean * height * .12, -height * .55);
    final low = height * .05, high = height * .028;
    Offset at(double k) => Offset.lerp(
      Offset.lerp(base, bend, k)!,
      Offset.lerp(bend, crown, k)!,
      k,
    )!;
    double half(double k) => low + (high - low) * k;
    final body = Path()..moveTo(base.dx - low * 1.5, base.dy);
    body
      ..quadraticBezierTo(base.dx - low * 1.05, base.dy - height * .05, base.dx - low, base.dy - height * .08)
      ..quadraticBezierTo(bend.dx - low, bend.dy, crown.dx - high, crown.dy)
      ..lineTo(crown.dx + high, crown.dy)
      ..quadraticBezierTo(bend.dx + low, bend.dy, base.dx + low, base.dy - height * .08)
      ..quadraticBezierTo(base.dx + low * 1.05, base.dy - height * .05, base.dx + low * 1.5, base.dy)
      ..close();
    c.drawPath(body, Paint()..color = trunk);
    c.drawPath(
      Path()
        ..moveTo(base.dx + low * .12, base.dy)
        ..quadraticBezierTo(bend.dx + low * .12, bend.dy, crown.dx + high * .12, crown.dy)
        ..lineTo(crown.dx + high, crown.dy)
        ..quadraticBezierTo(bend.dx + low, bend.dy, base.dx + low, base.dy - height * .08)
        ..quadraticBezierTo(base.dx + low * 1.05, base.dy - height * .05, base.dx + low * 1.5, base.dy)
        ..close(),
      Paint()..color = _hazed(const Color(0xffc3a47c), haze),
    );
    // Scar pattern: zig-zag bands of leaf bases up the trunk.
    final scars = Path();
    for (var k = .1; k < .94; k += .06) {
      final p = at(k), hw = half(k);
      scars
        ..moveTo(p.dx - hw, p.dy + hw * .3)
        ..lineTo(p.dx, p.dy - hw * .05)
        ..lineTo(p.dx + hw, p.dy + hw * .3);
    }
    c.drawPath(
      scars,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, height * .0085)
        ..strokeJoin = StrokeJoin.round
        ..color = Sketch.fade(trunkShade, .85),
    );
    // Fronds: dark ones behind, lit ones in front, each a serrated feather.
    final dark = Path(), mid = Path(), lit = Path(), ribs = Path();
    double jitter(int n) => Sketch.hash(seed * 13 + n) - .5;
    const back = [3.5, 3.0, 2.55, -.35, .1, .6];
    const front = [3.0, 2.55, 2.02, 1.57, 1.12, .62, .18];
    for (var i = 0; i < back.length; i++) {
      final a = back[i] + jitter(i) * .2;
      _nileFrond(dark, crown, a, height * (.42 + jitter(i + 20) * .08), .15 + .5 * math.pow(math.cos(a), 2), null);
    }
    for (var i = 0; i < front.length; i++) {
      final a = front[i] + jitter(i + 40) * .2;
      final len = height * (.39 + jitter(i + 60) * .08 - (i == 3 ? .08 : 0));
      _nileFrond(i.isEven ? lit : mid, crown, a, len, .1 + .46 * math.pow(math.cos(a), 2), ribs);
    }
    c.drawPath(dark, Paint()..color = _hazed(const Color(0xff54834a), haze));
    c.drawPath(mid, Paint()..color = _hazed(const Color(0xff6b9b4f), haze));
    c.drawPath(lit, Paint()..color = _hazed(const Color(0xff8fbb62), haze));
    c.drawPath(
      ribs,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, height * .006)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(_hazed(const Color(0xffd4e69a), haze), .55),
    );
    // A shaggy collar of old frond bases and, under it, bunches of dates.
    c.drawPath(
      Sketch.poly([
        crown.dx - height * .05, crown.dy, crown.dx - height * .045, crown.dy + height * .05, //
        crown.dx - height * .02, crown.dy + height * .035, crown.dx, crown.dy + height * .06,
        crown.dx + height * .02, crown.dy + height * .035, crown.dx + height * .045, crown.dy + height * .05,
        crown.dx + height * .05, crown.dy,
      ]),
      Paint()..color = _hazed(const Color(0xff6f5238), haze),
    );
    if (dates) {
      final fruit = Path();
      for (final (dx, dy) in const [(-.06, .06), (.05, .07), (.005, .085)]) {
        final p = crown + Offset(dx * height, dy * height);
        for (final (ox, oy) in const [(-.5, 0.0), (.5, .0), (0.0, .6), (-.4, 1.1), (.4, 1.1)]) {
          fruit.addOval(Rect.fromCenter(center: p + Offset(ox, oy) * height * .016, width: height * .022, height: height * .03));
        }
      }
      c.drawPath(fruit, Paint()..color = _hazed(const Color(0xff9b5a2c), haze));
    }
    c.drawCircle(crown, height * .03, Paint()..color = _hazed(const Color(0xff456f3a), haze));
  }

  /// Adds one pinnate frond to [out]: the rib bows out and droops, and short
  /// leaflets sweep forward along both sides. [angle] is counter-clockwise
  /// from the right; [droop] is how far the tip falls, as a fraction of [len].
  static void _nileFrond(Path out, Offset root, double angle, double len, double droop, Path? rib) {
    final dir = Offset(math.cos(angle), -math.sin(angle));
    final tip = root + dir * len + Offset(0, len * droop);
    final ctl = root + dir * len * .62 - Offset(0, len * .13);
    Offset at(double t) => Offset.lerp(Offset.lerp(root, ctl, t)!, Offset.lerp(ctl, tip, t)!, t)!;
    Offset tangent(double t) {
      final d = (ctl - root) * (2 * (1 - t)) + (tip - ctl) * (2 * t);
      return d / d.distance;
    }

    const n = 10;
    final upper = <Offset>[], lower = <Offset>[];
    for (var i = 1; i <= n; i++) {
      final t = i / (n + .6), tn = (i - .5) / (n + .6);
      final wide = len * .115 * math.pow(math.sin(math.pi * math.min(1.0, t * 1.12)), .7);
      final wn = wide * .5;
      final tg = tangent(t), nm = Offset(-tg.dy, tg.dx);
      final tgn = tangent(tn), nmn = Offset(-tgn.dy, tgn.dx);
      final lead = tg * (len / n * .85);
      upper
        ..add(at(tn) + nmn * wn)
        ..add(at(t) + nm * wide + lead);
      lower
        ..add(at(tn) - nmn * wn)
        ..add(at(t) - nm * wide + lead);
    }
    out.moveTo(root.dx, root.dy);
    for (final p in upper) {
      out.lineTo(p.dx, p.dy);
    }
    out.lineTo(tip.dx, tip.dy);
    for (final p in lower.reversed) {
      out.lineTo(p.dx, p.dy);
    }
    out.close();
    rib
      ?..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(ctl.dx, ctl.dy, tip.dx, tip.dy);
  }

  /// A round-crowned sycamore fig: dark leaf masses lit from the upper right.
  static void _nileTree(Canvas c, Offset base, double s, int seed) {
    c.drawPath(
      Sketch.poly([
        base.dx - s * .05, base.dy, base.dx - s * .03, base.dy - s * .42, //
        base.dx + s * .03, base.dy - s * .42, base.dx + s * .06, base.dy,
      ]),
      Paint()..color = const Color(0xff6e5238),
    );
    const blobs = [
      (-.26, -.66, .26),
      (.24, -.66, .27),
      (0.0, -.86, .3),
      (-.08, -.56, .3),
      (.3, -.5, .2),
      (-.34, -.5, .19),
    ];
    for (final (dx, dy, r) in blobs) {
      c.drawCircle(base + Offset(dx, dy) * s, r * s, Paint()..color = const Color(0xff4b7a3f));
    }
    for (final (dx, dy, r) in blobs) {
      c.drawCircle(base + Offset(dx + .05, dy - .06) * s, r * s * .78, Paint()..color = const Color(0xff67994b));
    }
    for (final (dx, dy, r) in blobs.take(4)) {
      c.drawCircle(base + Offset(dx + .1, dy - .12) * s, r * s * .42, Paint()..color = const Color(0xff88b65c));
    }
  }

  // --- life on the bank ---------------------------------------------------------

  /// The muddy bank itself, its grass and the people and animals that use it.
  static void _nileBankLife(Canvas c, double h) {
    final span = _nileSpan * h;
    double bank(double u) =>
        h * (.8035 + Sketch.waves(u, const [(_nileSpan / 6, .0014, 1.3), (_nileSpan / 13, .0009, .4)]));
    // Raised earth bank with a sunlit crest.
    final berm = Path()..moveTo(0, .812 * h);
    final crest = Path();
    const bermSteps = 48;
    for (var i = 0; i <= bermSteps; i++) {
      final x = span * i / bermSteps;
      final y = bank(x / h);
      berm.lineTo(x, y);
      if (x == 0) {
        crest.moveTo(x, y);
      } else {
        crest.lineTo(x, y);
      }
    }
    berm
      ..lineTo(span, .812 * h)
      ..close();
    c.drawPath(berm, Paint()..color = const Color(0xff9a8657));
    c.drawPath(
      crest,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, h * .0022)
        ..color = const Color(0xffd0c384),
    );
    // Grass and reeds along the water: tufts of short blades in two greens.
    final grassA = Path(), grassB = Path();
    for (var i = 0; i < 120; i++) {
      final x = span * (i + Sketch.hash(i + 300) * .8) / 120;
      final y = bank(x / h);
      final path = i % 3 == 0 ? grassB : grassA;
      for (var k = -1; k <= 1; k++) {
        final blade = h * (.004 + .008 * Sketch.hash(i * 3 + k + 500)) * (k == 0 ? 1.3 : 1);
        final tilt = (Sketch.hash(i * 3 + k + 700) - .5) * h * .01 + k * h * .003;
        final bx = x + k * h * .0032;
        path
          ..moveTo(bx - h * .0015, y + h * .003)
          ..quadraticBezierTo(bx + tilt * .3, y - blade * .5, bx + tilt, y - blade)
          ..lineTo(bx + h * .0015, y + h * .003)
          ..close();
      }
    }
    c.drawPath(grassA, Paint()..color = const Color(0xff5a8a42));
    c.drawPath(grassB, Paint()..color = const Color(0xff8bb95a));
    // Egrets stand about on the bank; a grey heron waits at the water.
    for (final (u, size, flip, craned) in const [
      (.98, .03, false, 1.0),
      (1.03, .026, true, .55),
      (1.6, .028, false, .8),
      (1.93, .03, true, 1.0),
      (.63, .026, false, .3),
      (1.4, .026, true, .9),
    ]) {
      _nileEgret(c, Offset(u * h, .8055 * h), h * size, flip: flip, craned: craned);
    }
    _nileEgret(c, Offset(1.16 * h, .8055 * h), h * .04, flip: true, craned: 1, body: const Color(0xffa9b6ba), cap: true);
    // Small cattle egrets among the crops.
    for (final (u, y) in const [(.82, .794), (.86, .797), (1.22, .793), (1.29, .796), (1.75, .794)]) {
      _nileEgret(c, Offset(u * h, y * h), h * .017, flip: u > 1, craned: .1);
    }
    // A villager leads a laden donkey along the bank; more work the crops.
    _nileDonkey(c, Offset(.72 * h, .8 * h), h * .05, true);
    _nileFolk(c, Offset(.81 * h, .8 * h), h * .03, const Color(0xff4f6f9a), const Color(0xfff2ead2), staff: true);
    _nileFolk(c, Offset(1.79 * h, .798 * h), h * .026, const Color(0xff2f2a30), const Color(0xff2f2a30), jar: true);
    _nileFolk(c, Offset(1.03 * h, .8 * h), h * .026, const Color(0xffb5865a), const Color(0xfff2ead2), staff: true);
    _nileBuffalo(c, Offset(1.22 * h, .806 * h), h * .052, true);
    _nileBuffalo(c, Offset(2.36 * h, .806 * h), h * .046, false);
  }

  /// A round tamarisk bush of three greens.
  static void _nileBush(Canvas c, Offset base, double s, {double haze = 0}) {
    for (final (dx, dy, r, col) in const [
      (-.5, -.3, .42, 0xff4c7a3c),
      (.5, -.28, .4, 0xff4c7a3c),
      (0.0, -.5, .5, 0xff5d9046),
      (-.2, -.28, .46, 0xff5d9046),
      (.25, -.6, .28, 0xff7fb356),
    ]) {
      c.drawCircle(base + Offset(dx, dy) * s, r * s, Paint()..color = _hazed(Color(col), haze));
    }
  }

  /// A beehive stack of cane or hay, bound with rope.
  static void _nileStack(Canvas c, Offset base, double s) {
    final body = Path()
      ..moveTo(base.dx - s * .5, base.dy)
      ..quadraticBezierTo(base.dx - s * .52, base.dy - s * .7, base.dx, base.dy - s * 1.05)
      ..quadraticBezierTo(base.dx + s * .52, base.dy - s * .7, base.dx + s * .5, base.dy)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xffbf9c58));
    c.drawPath(
      Path()
        ..moveTo(base.dx + s * .08, base.dy)
        ..quadraticBezierTo(base.dx + s * .1, base.dy - s * .7, base.dx, base.dy - s * 1.05)
        ..quadraticBezierTo(base.dx + s * .52, base.dy - s * .7, base.dx + s * .5, base.dy)
        ..close(),
      Paint()..color = const Color(0xffdcbf78),
    );
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, s * .05)
      ..color = const Color(0xff8a6a3a);
    c.drawLine(Offset(base.dx - s * .46, base.dy - s * .3), Offset(base.dx + s * .46, base.dy - s * .3), band);
    c.drawLine(Offset(base.dx - s * .36, base.dy - s * .62), Offset(base.dx + s * .36, base.dy - s * .62), band);
  }

  /// A water buffalo standing on the bank, head low, horns swept back.
  static void _nileBuffalo(Canvas c, Offset base, double s, bool left) {
    c.save();
    c.translate(base.dx, base.dy);
    if (!left) c.scale(-1, 1);
    final coat = Paint()..color = const Color(0xff6b6360);
    final leg = Paint()
      ..color = const Color(0xff4d4745)
      ..strokeWidth = math.max(.9, s * .07)
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-.3, -.2, .22, .32]) {
      c.drawLine(Offset(dx * s, -s * .3), Offset(dx * s, 0), leg);
    }
    c.drawPath(
      Path()
        ..moveTo(-s * .38, -s * .5)
        ..quadraticBezierTo(-s * .05, -s * .62, s * .34, -s * .5)
        ..quadraticBezierTo(s * .44, -s * .36, s * .34, -s * .26)
        ..quadraticBezierTo(0, -s * .2, -s * .34, -s * .26)
        ..quadraticBezierTo(-s * .46, -s * .38, -s * .38, -s * .5)
        ..close(),
      coat,
    );
    c.drawPath(
      Path()
        ..moveTo(-s * .3, -s * .5)
        ..quadraticBezierTo(-s * .05, -s * .61, s * .3, -s * .5)
        ..quadraticBezierTo(0, -s * .53, -s * .3, -s * .5)
        ..close(),
      Paint()..color = const Color(0xff8c827a),
    );
    // Lowered head, broad muzzle and horns sweeping back.
    c.drawPath(
      Sketch.poly([-s * .36, -s * .5, -s * .5, -s * .44, -s * .58, -s * .28, -s * .48, -s * .24, -s * .34, -s * .34]),
      coat,
    );
    c.drawOval(Rect.fromCenter(center: Offset(-s * .55, -s * .26), width: s * .12, height: s * .09), Paint()..color = const Color(0xff8b8079));
    c.drawPath(
      Path()
        ..moveTo(-s * .44, -s * .47)
        ..quadraticBezierTo(-s * .5, -s * .6, -s * .36, -s * .62)
        ..quadraticBezierTo(-s * .44, -s * .55, -s * .4, -s * .47)
        ..close(),
      Paint()..color = const Color(0xffcdc3b0),
    );
    c.drawLine(Offset(s * .38, -s * .46), Offset(s * .44, -s * .16), leg..strokeWidth = math.max(.6, s * .035));
    c.restore();
  }

  /// A tiny villager: [s] is the height. [jar] balances a water jar on the head.
  static void _nileFolk(
    Canvas c,
    Offset base,
    double s,
    Color robe,
    Color turban, {
    bool jar = false,
    bool staff = false,
  }) {
    final paint = Paint()..color = robe;
    c.drawPath(
      Sketch.poly([
        base.dx - s * .12, base.dy - s * .7, base.dx + s * .12, base.dy - s * .7, //
        base.dx + s * .2, base.dy, base.dx - s * .2, base.dy,
      ]),
      paint,
    );
    c.drawCircle(base + Offset(0, -s * .8), s * .095, Paint()..color = const Color(0xff87573a));
    if (!jar) {
      c.drawOval(
        Rect.fromCenter(center: base + Offset(0, -s * .87), width: s * .27, height: s * .13),
        Paint()..color = turban,
      );
    } else {
      c.drawOval(
        Rect.fromCenter(center: base + Offset(0, -s * .96), width: s * .2, height: s * .17),
        Paint()..color = const Color(0xffb26a3d),
      );
    }
    if (staff) {
      c.drawLine(
        base + Offset(s * .26, -s * .68),
        base + Offset(s * .3, 0),
        Paint()
          ..color = const Color(0xff5b3f2a)
          ..strokeWidth = math.max(.7, s * .04),
      );
    }
  }

  /// A donkey under a bundle of fodder, walking left ([left]) or right.
  static void _nileDonkey(Canvas c, Offset base, double s, bool left) {
    c.save();
    c.translate(base.dx, base.dy);
    if (!left) c.scale(-1, 1);
    final coat = Paint()..color = const Color(0xff8d7f74);
    final dark = Paint()
      ..color = const Color(0xff5f5249)
      ..strokeWidth = math.max(.8, s * .05)
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-.3, -.22, .2, .28]) {
      c.drawLine(Offset(dx * s, -s * .3), Offset(dx * s + (dx < 0 ? .01 : -.01) * s, 0), dark);
    }
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * .38), width: s * .74, height: s * .3), coat);
    // Neck, head with pale muzzle, ears and tail.
    c.drawPath(
      Sketch.poly([
        -s * .28, -s * .45, -s * .42, -s * .68, //
        -s * .5, -s * .66, -s * .38, -s * .32,
      ]),
      coat,
    );
    c.drawOval(Rect.fromCenter(center: Offset(-s * .5, -s * .63), width: s * .26, height: s * .14), coat);
    c.drawOval(Rect.fromCenter(center: Offset(-s * .58, -s * .61), width: s * .1, height: s * .1), Paint()..color = const Color(0xffd9cdbb));
    c.drawLine(Offset(-s * .44, -s * .7), Offset(-s * .42, -s * .84), dark);
    c.drawLine(Offset(-s * .48, -s * .7), Offset(-s * .49, -s * .83), dark);
    c.drawLine(Offset(s * .36, -s * .42), Offset(s * .4, -s * .22), dark);
    // A big bundle of green fodder and a red saddle blanket.
    c.drawRect(
      Rect.fromLTRB(-s * .18, -s * .55, s * .2, -s * .47),
      Paint()..color = const Color(0xffb04a3a),
    );
    c.drawPath(
      Path()
        ..moveTo(-s * .3, -s * .5)
        ..quadraticBezierTo(-s * .34, -s * .82, -s * .05, -s * .86)
        ..quadraticBezierTo(s * .3, -s * .88, s * .34, -s * .5)
        ..close(),
      Paint()..color = const Color(0xff7bab4c),
    );
    c.drawPath(
      Path()
        ..moveTo(-s * .05, -s * .86)
        ..quadraticBezierTo(s * .3, -s * .88, s * .34, -s * .5)
        ..lineTo(s * .12, -s * .52)
        ..quadraticBezierTo(s * .12, -s * .78, -s * .05, -s * .86),
      Paint()..color = const Color(0xff95c260),
    );
    c.restore();
  }

  // ---------------------------------------------------------------------------
  // The near bank's water garden: papyrus, reeds and cattails, blue lotus and
  // lily pads, a wading ibis, a kingfisher and a crocodile's eyes.

  static const _reedStemDark = Color(0xff3d7a3e);
  static const _reedStemLit = Color(0xff8fc65e);
  static const _reedRayDark = Color(0xff5b9147);
  static const _reedRayMid = Color(0xff88b958);
  static const _reedRayLit = Color(0xffc0dc78);
  static const _reedCalmTint = Color(0xffc9d6a9);

  /// Papyrus clumps as (place in the repeat, size, seed).
  static const _reedClumps = [(.075, 1.0, 1), (.43, 1.2, 2), (.84, .95, 3)];

  /// Reed and cattail stands as (place, size, seed).
  static const _reedStands = [
    (.14, 1.0, 4),
    (.385, .9, 5),
    (.56, .62, 8),
    (.745, 1.0, 6),
    (.9, .9, 7),
  ];

  /// Lily-pad rafts as (place, pads, seed); the pad count includes flowers.
  static const _reedRafts = [
    (.25, 5, 11),
    (.5, 4, 12),
    (.655, 5, 13),
    (.81, 5, 14),
    (.97, 4, 15),
  ];

  static const _reedIbisAt = .585, _reedCrocAt = .655, _reedKingAt = .315;

  /// Where the Nile meets the near bank at [x]: the water line plants stand on.
  double _reedWater(double h, double x) =>
      math.min(h * .89, ridge(Depth.near, x / h, 0) * h - h * .008);

  /// Tallest things soften toward a pale sage, so the band's top edge is calm.
  static Color _reedCalm(Color c, double y, double h, [double amount = .4]) =>
      Sketch.mix(
        c,
        _reedCalmTint,
        ((h * .86 - y) / (h * .2)).clamp(0.0, 1.0) * amount,
      );

  /// Position and pad radius of pad [i] of the raft [seed] at place [f].
  (double, double, double) _reedPad(double h, double span, double f, int seed, int i) {
    final k = seed * 23 + i;
    final x = span * f + (Sketch.hash(k) - .5) * h * .34;
    final near = Sketch.hash(k + 7);
    final y = _reedWater(h, x) - h * (.005 + .034 * (1 - near));
    final rx = h * (.02 + .016 * near + .008 * Sketch.hash(k + 3));
    return (x, y, rx);
  }

  void _reedShore(Canvas c, double h, double span) {
    // The big date palm stands in the water behind everything else.
    Sketch.palm(
      c,
      Offset(span * .7, h * .95),
      h * .44,
      lean: -.08,
      trunk: const Color(0xffa27451),
      trunkShade: const Color(0xff7d5739),
      frond: const Color(0xff5c8a4c),
      frondLit: const Color(0xff84ac60),
      dates: true,
    );
    final layers = <(double, VoidCallback)>[];
    for (final (f, count, seed) in _reedRafts) {
      for (var i = 0; i < count; i++) {
        final (x, y, rx) = _reedPad(h, span, f, seed, i);
        final k = seed * 23 + i;
        layers.add((y, () => _reedLilyPad(c, Offset(x, y), rx, k)));
        if (seed == 14 && i == 1) {
          layers.add((y + .05, () => _reedFrog(c, Offset(x - rx * .1, y - rx * .04), rx * .5)));
        }
        if (i == 0 || (i == 2 && Sketch.hash(k + 21) < .45)) {
          final white = Sketch.hash(k + 11) < .34;
          final s = h * (.033 + .01 * Sketch.hash(k + 5));
          layers.add((
            y + .1,
            () => _reedLotus(
              c,
              Offset(x + rx * .3, y - rx * .06),
              s,
              white: white,
              bud: !white && Sketch.hash(k + 13) < .3,
            ),
          ));
        }
      }
    }
    // Duckweed specks drift between the pads.
    final weed = Paint()
      ..color = Sketch.fade(const Color(0xff6fae4c), .85)
      ..strokeWidth = math.max(1.0, h * .0028)
      ..strokeCap = StrokeCap.round;
    for (final (f, _, seed) in _reedRafts) {
      final specks = <Offset>[];
      for (var i = 0; i < 16; i++) {
        final x = span * f + (Sketch.hash(seed * 7 + i) - .5) * h * .5;
        specks.add(Offset(x, _reedWater(h, x) - h * (.008 + .05 * Sketch.hash(seed * 5 + i))));
      }
      layers.add((0, () => c.drawPoints(PointMode.points, specks, weed)));
    }
    for (final (f, s, seed) in _reedStands) {
      final x = span * f, y = _reedWater(h, x);
      layers.add((y - h * .004, () => _reedStand(c, Offset(x, y), h * .12 * s, seed, h)));
    }
    final kx = span * _reedKingAt, ky = _reedWater(h, kx);
    layers.add((ky, () => _reedPerch(c, Offset(kx, ky), h * .09, h)));
    layers.add((ky + .1, () => _reedStand(c, Offset(kx, ky + h * .004), h * .05, 9, h, cattails: false, plumes: 0)));
    final cx = span * _reedCrocAt, cy = _reedWater(h, cx) - h * .02;
    layers.add((cy, () => _reedCroc(c, Offset(cx, cy), h * .0145)));
    layers.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw) in layers) {
      draw();
    }
  }

  /// A papyrus clump: triangular stems crowned by dense, drooping umbels.
  static void _papyrus(Canvas c, Offset base, double height, double h, {int seed = 0}) {
    const n = 7;
    double z(int i) => Sketch.hash(seed * 13 + i);
    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) => z(a).compareTo(z(b)));
    // The clump's shade falls on the water away from the sun, then broken
    // reflections and a ring of ripples where it meets the surface.
    c.drawOval(
      Rect.fromCenter(center: base + Offset(-height * .32, height * .05), width: height * 1.1, height: height * .11),
      Paint()..color = Sketch.fade(const Color(0xff2d5d55), .2),
    );
    final mirror = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.9, height * .022);
    for (var k = 0; k < 4; k++) {
      mirror.color = Sketch.fade(const Color(0xff2f5f3d), .24 - k * .045);
      final half = height * (.2 - k * .035);
      final y = base.dy + height * (.045 + k * .05);
      c.drawLine(Offset(base.dx - half, y), Offset(base.dx + half * .8, y), mirror);
    }
    c.drawLine(
      base + Offset(-height * .3, height * .012),
      base + Offset(height * .28, height * .012),
      Paint()
        ..color = Sketch.fade(const Color(0xffeafaf4), .5)
        ..strokeWidth = math.max(.7, height * .012)
        ..strokeCap = StrokeCap.round,
    );
    for (final i in order) {
      final j = seed * 31 + i;
      final u = (i + .5) / n * 2 - 1 + (Sketch.hash(j) - .5) * .2;
      final back = z(i) < .42;
      final tall = height * (1 - .22 * u * u) * (.86 + .22 * Sketch.hash(j + 3));
      final b = base + Offset(u * height * .14, 0);
      final top = b + Offset(u * height * .2 + (Sketch.hash(j + 5) - .5) * height * .06, -tall * (back ? .9 : 1));
      final calm = _reedCalm(_reedStemDark, top.dy, h);
      final dark = back ? Sketch.mix(calm, const Color(0xff2b5a3c), .35) : calm;
      final lit = back ? Sketch.mix(_reedStemLit, calm, .5) : _reedCalm(_reedStemLit, top.dy, h);
      _reedStem(c, b, top, math.max(1.2, height * .034), dark, lit);
      final r = height * .32 * (.9 + .25 * Sketch.hash(j + 9)) * (back ? .88 : 1);
      _reedUmbel(c, top, r, j, back: back, dry: i == 1 && seed.isOdd, h: h);
    }
    // Papery brown sheaths collar the foot of the stems; young shoots rise
    // between them, still sharp and unopened.
    final sheath = Path();
    for (var i = 0; i < 7; i++) {
      final dx = (i - 3) * height * .05;
      _reedBlade(sheath, base + Offset(dx, height * .01), height * (.1 + .04 * Sketch.hash(seed + i * 5)), dx * 1.1, height * .02);
    }
    c.drawPath(sheath, Paint()..color = const Color(0xff9c8150));
    final shoot = Path();
    for (var i = 0; i < 3; i++) {
      final dx = (i - 1) * height * .13 + (Sketch.hash(seed + i) - .5) * height * .05;
      _reedBlade(shoot, base + Offset(dx, 0), height * (.26 + .06 * i), dx * .8, height * .014);
    }
    c.drawPath(shoot, Paint()..color = _reedStemLit);
  }

  /// A tapered, gently bowed stem with a lit edge on the sun side.
  static void _reedStem(Canvas c, Offset b, Offset top, double w, Color dark, Color lit) {
    final mid = Offset.lerp(b, top, .55)! + Offset((top.dx - b.dx) * .12, 0);
    c.drawPath(
      Path()
        ..moveTo(b.dx, b.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = dark,
    );
    c.drawPath(
      Path()
        ..moveTo(b.dx + w * .22, b.dy)
        ..quadraticBezierTo(mid.dx + w * .22, mid.dy, top.dx + w * .22, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .36
        ..strokeCap = StrokeCap.round
        ..color = lit,
    );
  }

  /// A papyrus umbel: a mop of fine rays radiating from the stem, dark on the
  /// shaded underside and pale where the sun catches them, with drooping
  /// bracts hanging under the hub.
  static void _reedUmbel(
    Canvas c,
    Offset hub,
    double r,
    int seed, {
    bool back = false,
    bool dry = false,
    double h = 450,
  }) {
    final tones = [Path(), Path(), Path(), Path()];
    final tips = [<Offset>[], <Offset>[], <Offset>[], <Offset>[]];
    final n = 54 + (Sketch.hash(seed + 71) * 10).round();
    for (var k = 0; k < n; k++) {
      final u = (k + Sketch.hash(seed * 97 + k)) / n;
      final a = -math.pi * (-.3 + 1.6 * u);
      final cs = math.cos(a), sn = math.sin(a);
      final below = sn > 0 ? .78 : 1.0;
      final len = r * below * (.66 + .34 * Sketch.hash(seed * 61 + k * 7));
      final end = hub + Offset(cs * len, sn * len + len * (.1 + .3 * cs * cs));
      final ctl = hub + Offset(cs * len * .58, sn * len * .58 - len * .06);
      final light = cs * .55 - sn * .85 + (Sketch.hash(seed * 31 + k) - .5) * .6;
      final t = light < -.35 ? 0 : (light < .1 ? 1 : (light < .55 ? 2 : 3));
      tones[t]
        ..moveTo(hub.dx, hub.dy)
        ..quadraticBezierTo(ctl.dx, ctl.dy, end.dx, end.dy);
      tips[t].add(end);
    }
    final palette = dry
        ? const [Color(0xff7e6230), Color(0xffa17f40), Color(0xffc8a35c), Color(0xffe6cf8c)]
        : const [Color(0xff4b7f3f), _reedRayDark, _reedRayMid, _reedRayLit];
    final width = math.max(.6, r * .034);
    Color tone(int t) {
      final col = _reedCalm(palette[t], hub.dy, h, .34);
      return back ? Sketch.mix(col, const Color(0xff2b5a3c), .3) : col;
    }
    // A dense, darker core where the rays crowd together.
    c.drawCircle(hub + Offset(0, r * .04), r * .3, Paint()..color = Sketch.fade(tone(0), .6));
    for (var t = 0; t < 4; t++) {
      c.drawPath(
        tones[t],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = tone(t),
      );
      if (t > 1 && !back) {
        c.drawPoints(
          PointMode.points,
          tips[t],
          Paint()
            ..strokeWidth = width * 1.7
            ..strokeCap = StrokeCap.round
            ..color = Sketch.fade(dry ? const Color(0xfff0dca0) : const Color(0xffdcecab), t == 3 ? .75 : .4),
        );
      }
    }
    // Long bracts droop from under the hub.
    final bracts = Path();
    for (var k = -2; k <= 2; k++) {
      final tip = hub + Offset(k * r * .26, r * (.5 - k.abs() * .05));
      bracts
        ..moveTo(hub.dx, hub.dy)
        ..quadraticBezierTo(hub.dx + k * r * .3, hub.dy - r * .04, tip.dx, tip.dy);
    }
    c.drawPath(
      bracts,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, r * .032)
        ..strokeCap = StrokeCap.round
        ..color = tone(1),
    );
  }

  /// One tapered blade appended to [p]: base [b], rising [hgt], leaning [dx].
  static void _reedBlade(Path p, Offset b, double hgt, double dx, double bw) {
    final tip = b + Offset(dx, -hgt * .9);
    p
      ..moveTo(b.dx - bw, b.dy)
      ..cubicTo(b.dx - bw * .4, b.dy - hgt * .55, b.dx + dx * .35, b.dy - hgt * 1.02, tip.dx, tip.dy)
      ..cubicTo(b.dx + dx * .35 + bw * .5, b.dy - hgt * .97, b.dx + bw * .6, b.dy - hgt * .5, b.dx + bw, b.dy)
      ..close();
  }

  /// Reeds and cattails in the shallows: arching blades and brown spikes.
  static void _reedStand(Canvas c, Offset base, double height, int seed, double h, {bool cattails = true, int plumes = 2, bool water = true}) {
    final tones = [Path(), Path(), Path()];
    for (var k = 0; k < 12; k++) {
      final j = seed * 41 + k;
      final u = (k + .5) / 12 * 2 - 1;
      final hgt = height * (.55 + .45 * Sketch.hash(j)) * (1 - .3 * u.abs());
      final dx = (u * .42 + (Sketch.hash(j + 3) - .5) * .3) * height;
      _reedBlade(
        tones[dx > height * .1 ? 2 : (Sketch.hash(j + 8) < .5 ? 0 : 1)],
        base + Offset(u * height * .14, 0),
        hgt,
        dx,
        height * .03 * (.7 + .6 * Sketch.hash(j + 5)),
      );
    }
    final colours = [
      const Color(0xff3f7440),
      const Color(0xff5e9a47),
      const Color(0xff8cc060),
    ];
    for (var t = 0; t < 3; t++) {
      c.drawPath(tones[t], Paint()..color = _reedCalm(colours[t], base.dy - height, h, .25));
    }
    for (var k = 0; k < plumes; k++) {
      final j = seed * 29 + k;
      _reedPlume(
        c,
        base + Offset((k - .5) * height * .3, 0),
        height * (1.15 + .25 * Sketch.hash(j)),
        (Sketch.hash(j + 2) - .3) * .35,
        h,
      );
    }
    for (var k = 0; k < (cattails ? 3 : 0); k++) {
      final j = seed * 17 + k;
      _reedCattail(
        c,
        base + Offset((k - 1) * height * .17, 0),
        height * (.85 + .3 * Sketch.hash(j)),
        (Sketch.hash(j + 2) - .5) * .3,
      );
    }
    if (water) {
      // Where the stems enter the water: a pale ring and a broken reflection.
      c.drawLine(
        base + Offset(-height * .32, height * .01),
        base + Offset(height * .3, height * .01),
        Paint()
          ..color = Sketch.fade(const Color(0xffeafaf4), .5)
          ..strokeWidth = math.max(.7, height * .014)
          ..strokeCap = StrokeCap.round,
      );
      c.drawLine(
        base + Offset(-height * .2, height * .07),
        base + Offset(height * .18, height * .07),
        Paint()
          ..color = Sketch.fade(const Color(0xff2f5f3d), .2)
          ..strokeWidth = math.max(.9, height * .03)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// A tall reed with a feathery, nodding seed plume.
  static void _reedPlume(Canvas c, Offset base, double height, double lean, double h) {
    final top = base + Offset(lean * height, -height);
    final mid = base + Offset(lean * height * .2, -height * .55);
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, height * .02)
        ..strokeCap = StrokeCap.round
        ..color = _reedCalm(const Color(0xff8d9c56), top.dy, h),
    );
    // The panicle rises, then nods over to one side like a soft feather.
    final len = height * .2;
    final side = lean >= 0 ? 1.0 : -1.0;
    final tip = top + Offset(side * len * .8, -len * .05);
    final ctl = top + Offset(side * len * .1, -len * .95);
    final perp = Offset(side, .35) * (len * .17);
    final plume = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(ctl.dx + perp.dx, ctl.dy - perp.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(ctl.dx - perp.dx * .8, ctl.dy + perp.dy * .8, top.dx, top.dy);
    c.drawPath(plume, Paint()..color = _reedCalm(const Color(0xff947548), top.dy, h));
    c.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctl.dx + perp.dx * .9, ctl.dy - perp.dy * .9, tip.dx, tip.dy)
        ..quadraticBezierTo(ctl.dx + perp.dx * .1, ctl.dy - perp.dy * .1, top.dx, top.dy),
      Paint()..color = _reedCalm(const Color(0xffd9bf80), top.dy, h),
    );
    final hair = Path();
    for (var k = 1; k <= 5; k++) {
      final t = k / 6.0;
      final q = Offset.lerp(Offset.lerp(top, ctl, t)!, Offset.lerp(ctl, tip, t)!, t)!;
      hair
        ..moveTo(q.dx, q.dy)
        ..lineTo(q.dx + side * len * .1, q.dy - len * .12);
    }
    c.drawPath(
      hair,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, len * .035)
        ..strokeCap = StrokeCap.round
        ..color = _reedCalm(const Color(0xffb8965a), top.dy, h),
    );
  }

  static void _reedCattail(Canvas c, Offset base, double height, double lean) {
    final top = base + Offset(lean * height, -height);
    final mid = base + Offset(lean * height * .1, -height * .55);
    final dir = (top - mid) / (top - mid).distance;
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.9, height * .028)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xff5b8f45),
    );
    final w = height * .07;
    final p0 = top - dir * height * .2 - dir * height * .04;
    final p1 = top - dir * height * .04;
    c.drawLine(
      p0,
      p1,
      Paint()
        ..color = const Color(0xff65402a)
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      p0 + Offset(w * .2, 0),
      p1 + Offset(w * .2, 0),
      Paint()
        ..color = const Color(0xffb98552)
        ..strokeWidth = w * .34
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      p1,
      p1 + dir * height * .12,
      Paint()
        ..color = const Color(0xff7d8a4a)
        ..strokeWidth = math.max(.7, height * .02)
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A floating lily pad seen at a grazing angle, with a notch and a shadow.
  static void _reedLilyPad(Canvas c, Offset at, double rx, int seed) {
    final ry = rx * .3;
    final notch = -math.pi * (.1 + .8 * Sketch.hash(seed + 50)) + math.pi;
    Path face(double dy) => Path()
      ..moveTo(at.dx, at.dy + dy)
      ..arcTo(
        Rect.fromCenter(center: at + Offset(0, dy), width: rx * 2, height: ry * 2),
        notch + .18,
        math.pi * 2 - .36,
        false,
      )
      ..close();
    c.drawOval(
      Rect.fromCenter(center: at + Offset(rx * .06, ry * .95), width: rx * 2.3, height: ry * 1.5),
      Paint()..color = Sketch.fade(const Color(0xff2d5d55), .3),
    );
    final age = Sketch.hash(seed + 90);
    c.drawPath(face(ry * .38), Paint()..color = Sketch.mix(const Color(0xff2f6b3d), const Color(0xff5b5a2e), age * .5));
    c.drawPath(face(0), Paint()..color = Sketch.mix(const Color(0xff5c9b48), const Color(0xff8fa64e), age * .7));
    c.drawOval(
      Rect.fromCenter(center: at + Offset(rx * .22, -ry * .12), width: rx * 1.1, height: ry * .95),
      Paint()..color = Sketch.fade(const Color(0xffa4cf6c), .55),
    );
    final veins = Path();
    for (var k = 0; k < 5; k++) {
      final a = notch + .5 + (math.pi * 2 - 1) * k / 4.0;
      veins
        ..moveTo(at.dx, at.dy)
        ..lineTo(at.dx + math.cos(a) * rx * .86, at.dy + math.sin(a) * ry * .86);
    }
    c.drawPath(
      veins,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, rx * .03)
        ..color = Sketch.fade(const Color(0xffcfe79a), .4),
    );
  }

  /// A blue lotus (or a white water lily, or a bud) floating on the water.
  static void _reedLotus(Canvas c, Offset at, double s, {bool white = false, bool bud = false}) {
    final lit = white ? const Color(0xfffffaf2) : const Color(0xffc4d3fa);
    final mid = white ? const Color(0xfff2e6da) : const Color(0xff9db3ee);
    final dark = white ? const Color(0xffd9c6c0) : const Color(0xff7a8fd6);
    final base = at + Offset(0, -s * .32);
    c.drawLine(
      at,
      base,
      Paint()
        ..color = const Color(0xff3b7a45)
        ..strokeWidth = math.max(.8, s * .08)
        ..strokeCap = StrokeCap.round,
    );
    void petal(double ang, double len, double wid, Color col) {
      final dir = Offset(math.sin(ang), -math.cos(ang));
      final perp = Offset(-dir.dy, dir.dx);
      final tip = base + dir * len;
      final m = base + dir * len * .55;
      c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(m.dx + perp.dx * wid, m.dy + perp.dy * wid, tip.dx, tip.dy)
          ..quadraticBezierTo(m.dx - perp.dx * wid, m.dy - perp.dy * wid, base.dx, base.dy),
        Paint()..color = col,
      );
    }

    petal(-1.35, s * .34, s * .12, const Color(0xff3f8a4c));
    petal(1.35, s * .34, s * .12, const Color(0xff3f8a4c));
    if (bud) {
      petal(-.12, s * .95, s * .2, dark);
      petal(.16, s * .9, s * .2, mid);
      petal(0, s * .8, s * .16, lit);
      return;
    }
    for (final (a, l) in const [(-1.2, .62), (1.2, .62), (-.85, .82), (.85, .82)]) {
      petal(a, s * l, s * .17, dark);
    }
    for (final (a, l) in const [(-.5, .95), (.5, .95)]) {
      petal(a, s * l, s * .19, mid);
    }
    c.drawOval(
      Rect.fromCenter(center: base + Offset(0, -s * .08), width: s * .34, height: s * .2),
      Paint()..color = const Color(0xfff2cf62),
    );
    petal(-.22, s * 1.05, s * .2, lit);
    petal(.22, s * 1.05, s * .2, lit);
    petal(0, s * 1.12, s * .2, Sketch.mix(lit, const Color(0xffffffff), .4));
  }

  /// A bare reed leaning over the water with a kingfisher perched on its tip.
  static void _reedPerch(Canvas c, Offset base, double height, double h) {
    final top = base + Offset(height * .12, -height);
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx - height * .05, base.dy - height * .6, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, height * .034)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xff8a8a4c),
    );
    _reedKingfisher(c, top + Offset(0, height * .01), h * .03);
  }

  /// A small kingfisher, perched and watching the water. Origin at its feet.
  static void _reedKingfisher(Canvas c, Offset at, double s) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(s);
    final paint = Paint();
    // Tail, then the orange body and the blue back over it.
    c.drawPath(
      Sketch.poly(const [-.1, -.3, -.42, .4, -.05, .3]),
      paint..color = const Color(0xff2a6f98),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -.58), width: .68, height: .98),
      paint..color = const Color(0xffe0a06a),
    );
    c.drawPath(
      Path()
        ..moveTo(-.02, -1.05)
        ..quadraticBezierTo(-.44, -.6, -.12, -.12)
        ..quadraticBezierTo(-.08, -.6, .12, -1.0)
        ..close(),
      paint..color = const Color(0xff2f86b8),
    );
    c.drawCircle(const Offset(.12, -1.12), .3, paint..color = const Color(0xff3b96c6));
    c.drawOval(
      Rect.fromCenter(center: const Offset(.26, -1.02), width: .22, height: .16),
      paint..color = const Color(0xffd98c50),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(.3, -.86), width: .2, height: .13),
      paint..color = const Color(0xfffff6e6),
    );
    c.drawCircle(const Offset(.2, -1.16), .045, paint..color = const Color(0xff1f2a33));
    c.drawPath(
      Sketch.poly(const [.36, -1.14, 1.05, -.96, .38, -1.0]),
      paint..color = const Color(0xff2a2f36),
    );
    c.restore();
  }

  /// A crocodile's eyes and nostrils just above the water: watching, calm.
  static void _reedCroc(Canvas c, Offset at, double s) {
    // The dim shape of the head under the surface.
    c.drawOval(
      Rect.fromCenter(center: at + Offset(s * 2.4, s * .7), width: s * 9.5, height: s * 1.5),
      Paint()..color = Sketch.fade(const Color(0xff2d5048), .3),
    );
    final scale = Paint()..color = const Color(0xff4d6034);
    final lit = Paint()..color = const Color(0xff97a866);
    void dome(Offset p, double w, double hgt) {
      final r = Rect.fromCenter(center: p, width: w, height: hgt * 2);
      c.drawArc(r, math.pi, math.pi, true, scale);
      c.drawArc(r.translate(w * .1, -hgt * .06).deflate(hgt * .12), math.pi * 1.15, math.pi * .65, false, lit..style = PaintingStyle.stroke..strokeWidth = math.max(.6, s * .18));
      lit.style = PaintingStyle.fill;
    }
    // Snout ridge, then the two nostrils, then the brow with its eye.
    c.drawOval(
      Rect.fromCenter(center: at + Offset(s * 2.5, s * .02), width: s * 5, height: s * .5),
      Paint()..color = const Color(0xff3f5230),
    );
    dome(at + Offset(s * 4.6, s * .1), s * .8, s * .38);
    dome(at + Offset(s * 3.8, s * .1), s * .7, s * .3);
    dome(at, s * 1.7, s * .78);
    c.drawCircle(at + Offset(s * .12, -s * .32), s * .22, Paint()..color = const Color(0xfff0cf5a));
    c.drawLine(
      at + Offset(s * .12, -s * .5),
      at + Offset(s * .12, -s * .14),
      Paint()
        ..color = const Color(0xff1e2418)
        ..strokeWidth = math.max(.5, s * .1),
    );
  }

  /// The crocodile's eyelid, drawn over its eye for the length of a blink.
  static void _reedCrocLid(Canvas c, Offset at, double s) {
    c.drawOval(
      Rect.fromCenter(center: at + Offset(s * .12, -s * .3), width: s * .62, height: s * .55),
      Paint()..color = const Color(0xff4d6034),
    );
  }

  static final _reedIbisPics = <Size, Picture>{};

  /// A sacred ibis wading in the shallows, facing right, feet at [feet]. [dip]
  /// (0..1) lowers its head toward the water to probe.
  static void _reedIbis(Canvas c, Offset feet, double s, double dip) {
    c.save();
    c.translate(feet.dx, feet.dy);
    c.scale(s);
    c.drawPath(
      Path()
        ..moveTo(-.02, -.8)
        ..lineTo(-.11, -.42)
        ..lineTo(-.08, -.03)
        ..lineTo(.07, -.03)
        ..moveTo(.2, -.78)
        ..lineTo(.28, -.44)
        ..lineTo(.3, -.03)
        ..lineTo(.45, -.03),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xff5a4842),
    );
    final paint = Paint();
    // Neck and head first: bare and black, the white chest overlaps the
    // neck's foot. It swings down when the bird probes.
    final head = Offset.lerp(const Offset(.86, -1.86), const Offset(1.14, -.34), dip)!;
    final c1 = Offset.lerp(const Offset(.92, -1.32), const Offset(.92, -1.15), dip)!;
    final c2 = Offset.lerp(const Offset(.66, -1.62), const Offset(1.08, -.84), dip)!;
    c.drawPath(
      Path()
        ..moveTo(.5, -1.16)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, head.dx, head.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .135
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xff26262c),
    );
    c.save();
    c.translate(head.dx, head.dy);
    c.rotate(dip * 1.0);
    c.drawPath(
      Path()
        ..moveTo(-.02, -.05)
        ..quadraticBezierTo(.36, -.08, .6, .28)
        ..quadraticBezierTo(.32, .08, -.02, .05)
        ..close(),
      paint..color = const Color(0xff3f3f46),
    );
    c.restore();
    c.drawCircle(head, .09, paint..color = const Color(0xff26262c));
    // Body: white, with a shaded belly and sleek dark plumes over the tail.
    c.drawPath(
      Path()
        ..moveTo(-.78, -1.0)
        ..quadraticBezierTo(-.4, -1.44, .18, -1.42)
        ..quadraticBezierTo(.64, -1.4, .7, -1.14)
        ..quadraticBezierTo(.64, -.8, .08, -.78)
        ..quadraticBezierTo(-.44, -.76, -.78, -1.0)
        ..close(),
      paint..color = const Color(0xfffff9ee),
    );
    c.drawPath(
      Path()
        ..moveTo(.68, -1.04)
        ..quadraticBezierTo(.58, -.8, .08, -.78)
        ..quadraticBezierTo(-.44, -.76, -.78, -1.0)
        ..quadraticBezierTo(-.3, -.9, .12, -.9)
        ..quadraticBezierTo(.5, -.92, .68, -1.04)
        ..close(),
      paint..color = const Color(0xffe2d6c0),
    );
    c.drawPath(
      Path()
        ..moveTo(.02, -1.4)
        ..quadraticBezierTo(-.5, -1.36, -.98, -.9)
        ..quadraticBezierTo(-.5, -1.0, -.02, -1.1)
        ..close(),
      paint..color = const Color(0xff2b3138),
    );
    c.drawPath(
      Path()
        ..moveTo(-.16, -1.3)
        ..quadraticBezierTo(-.56, -1.2, -.86, -.93)
        ..quadraticBezierTo(-.5, -1.0, -.12, -1.06)
        ..close(),
      paint..color = const Color(0xff46596a),
    );
    c.restore();
  }

  static final _reedClumpPics = <(Size, int), Picture>{};

  /// One papyrus clump recorded where it stands, so it can sway as a whole.
  Picture _reedClump(Size size, int i) {
    final key = (size, i);
    var picture = _reedClumpPics.remove(key);
    if (picture == null) {
      final h = size.height;
      final (f, s, seed) = _reedClumps[i];
      final x = period(Depth.near) * h * f, y = _reedWater(h, x);
      final recorder = PictureRecorder();
      _papyrus(Canvas(recorder), Offset(x, y), h * .14 * s, h, seed: seed);
      picture = recorder.endRecording();
    }
    _reedClumpPics[key] = picture;
    if (_reedClumpPics.length > 3 * _reedClumps.length) {
      _reedClumpPics.remove(_reedClumpPics.keys.first)!.dispose();
    }
    return picture;
  }

  /// Animated water life behind the near bank: swaying papyrus, ripple
  /// rings, the ibis probing the shallows and the crocodile's slow blink.
  void _reedLive(Canvas c, SceneFrame f) {
    final h = f.h, span = period(Depth.near) * h, t = f.clock;
    for (var i = 0; i < _reedClumps.length; i++) {
      // The breeze leans the whole clump from its foot, a little out of step.
      final (fx, _, seed) = _reedClumps[i];
      final x = span * fx, y = _reedWater(h, x);
      final sway = math.sin(t * .8 + seed * 1.7) * .026 + math.sin(t * 1.9 + seed * 3.9) * .01;
      c.save();
      c.translate(x, y);
      c.skew(sway, 0);
      c.translate(-x, -y);
      c.drawPicture(_reedClump(f.size, i));
      c.restore();
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, h * .002);
    void rings(Offset at, double s, int seed) {
      for (var k = 0; k < 2; k++) {
        final phase = (t * .2 + seed * .37 + k * .5) % 1.0;
        ring.color = Sketch.fade(const Color(0xfff2fffa), (1 - phase) * .6);
        final rx = s * (.7 + 3.6 * phase);
        c.drawOval(Rect.fromCenter(center: at, width: rx * 2, height: rx * .5), ring);
      }
    }

    final ix = span * _reedIbisAt, iy = _reedWater(h, ix);
    final cycle = t % 11.0;
    final dip = cycle > 7.0 && cycle < 9.4 ? math.sin(math.pi * (cycle - 7.0) / 2.4) : 0.0;
    if (dip > .01) {
      _reedIbis(c, Offset(ix, iy), h * .056, dip.clamp(0.0, 1.0));
    } else {
      // Standing tall, the ibis is a recorded picture; only probing is live.
      var pic = _reedIbisPics.remove(f.size);
      if (pic == null) {
        final recorder = PictureRecorder();
        _reedIbis(Canvas(recorder), Offset.zero, h * .056, 0);
        pic = recorder.endRecording();
      }
      _reedIbisPics[f.size] = pic;
      if (_reedIbisPics.length > 4) _reedIbisPics.remove(_reedIbisPics.keys.first)!.dispose();
      c.save();
      c.translate(ix, iy);
      c.drawPicture(pic);
      c.restore();
    }
    rings(Offset(ix + h * .008, iy + h * .003), h * .012, 1);
    final cx = span * _reedCrocAt, cy = _reedWater(h, cx) - h * .02;
    rings(Offset(cx + h * .03, cy + h * .004), h * .012, 3);
    final blink = t % 7.3;
    if (blink > 6.85 && blink < 7.05) _reedCrocLid(c, Offset(cx, cy), h * .0145);
    for (final (fr, _, seed) in _reedRafts) {
      final (x, y, rx) = _reedPad(h, span, fr, seed, 0);
      rings(Offset(x, y + rx * .34), rx * .9, seed);
    }
  }

  /// The bank's front: a band of wet sand at the water line and reed stands
  /// on the crest, recorded once and replayed; dragonflies hover live.
  static final _reedFronts = <Size, Picture>{};

  void _reedFront(Canvas c, SceneFrame f, double presence) {
    if (presence <= .01) return;
    final h = f.h, span = period(Depth.near) * h;
    var picture = _reedFronts.remove(f.size);
    picture ??= _reedRecordFront(f.size);
    _reedFronts[f.size] = picture;
    if (_reedFronts.length > 6) _reedFronts.remove(_reedFronts.keys.first)!.dispose();
    if (presence >= .995) {
      c.drawPicture(picture);
    } else {
      c.saveLayer(
        Rect.fromLTWH(-h, h * .8, span + h * 2, h * .25),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
      c.drawPicture(picture);
      c.restore();
    }
    for (var i = 0; i < 3; i++) {
      final t = f.clock * .5 + i * 2.3;
      final p = Offset(
        span * (const [.24, .52, .8][i]) + math.sin(t) * h * .06,
        h * (.795 + .012 * i) + math.cos(t * 1.6) * h * .012,
      );
      _reedFly(c, p, h * .013, math.cos(t) >= 0 ? 1.0 : -1.0, i == 1 ? const Color(0xffc0463a) : const Color(0xff2f8fb0), presence);
    }
  }

  /// A dragonfly seen from the side, hovering, facing [d] (1 right, -1 left).
  static void _reedFly(Canvas c, Offset p, double s, double d, Color body, double presence) {
    final wing = Paint()..color = Sketch.fade(const Color(0xffe8f6ff), .6 * presence);
    final thorax = p + Offset(s * .3 * d, 0);
    for (final (dx, lift, len) in const [(-.05, .62, 1.1), (.35, .5, 1.0)]) {
      final r = thorax + Offset(s * dx * d, -s * .1);
      c.drawPath(
        Path()
          ..moveTo(r.dx, r.dy)
          ..quadraticBezierTo(r.dx - s * len * .5 * d, r.dy - s * lift * 1.6, r.dx - s * len * 1.2 * d, r.dy - s * lift * .55)
          ..quadraticBezierTo(r.dx - s * len * .5 * d, r.dy - s * .05, r.dx, r.dy),
        wing,
      );
    }
    final paint = Paint()
      ..strokeWidth = s * .26
      ..strokeCap = StrokeCap.round
      ..color = Sketch.fade(body, .95 * presence);
    c.drawLine(p + Offset(-s * 1.5 * d, s * .05), thorax, paint);
    c.drawCircle(thorax + Offset(s * .12 * d, 0), s * .3, paint..style = PaintingStyle.fill);
    c.drawCircle(thorax + Offset(s * .38 * d, -s * .02), s * .27, paint);
  }

  /// A tiny green frog sitting on a pad, facing right. [s] is its body length.
  static void _reedFrog(Canvas c, Offset at, double s) {
    final paint = Paint();
    c.drawOval(Rect.fromCenter(center: at + Offset(-s * .05, -s * .28), width: s * 1.1, height: s * .6), paint..color = const Color(0xff4f8a3a));
    c.drawOval(Rect.fromCenter(center: at + Offset(-s * .3, -s * .18), width: s * .5, height: s * .4), paint..color = const Color(0xff3f7a30));
    c.drawOval(Rect.fromCenter(center: at + Offset(s * .3, -s * .42), width: s * .48, height: s * .4), paint..color = const Color(0xff6aa64a));
    c.drawCircle(at + Offset(s * .38, -s * .62), s * .1, paint..color = const Color(0xfff2e08a));
    c.drawCircle(at + Offset(s * .42, -s * .62), s * .04, paint..color = const Color(0xff1e2a1c));
  }

  Picture _reedRecordFront(Size size) {
    final h = size.height, span = period(Depth.near) * h;
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    double crest(double x) => ridge(Depth.near, x / h, 0) * h;
    // Wet sand along the water line, darker where the river laps it.
    final wet = Path()..moveTo(0, crest(0));
    for (var x = 0.0; x <= span; x += h * .04) {
      wet.lineTo(x, crest(x) + h * .0012);
    }
    for (var x = span; x >= 0; x -= h * .04) {
      wet.lineTo(
        x,
        crest(x) + h * (.008 + .0035 * math.sin(x / h * 23) + .002 * math.sin(x / h * 57 + 1)),
      );
    }
    wet.close();
    c.drawPath(wet, Paint()..color = Sketch.fade(const Color(0xff8a5a30), .42));
    // A few pebbles and shells caught in the wet band.
    final pebble = Paint();
    for (var i = 0; i < 26; i++) {
      final x = span * (i + Sketch.hash(i + 300)) / 26;
      final y = crest(x) + h * (.004 + .009 * Sketch.hash(i + 330));
      pebble.color = i.isEven ? const Color(0xff7d5330) : const Color(0xfff0d9a8);
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: h * (.005 + .004 * Sketch.hash(i + 360)), height: h * .003),
        pebble,
      );
    }
    for (final (f, kind, s, seed) in const [
      (.105, 0, .8, 21),
      (.4, 1, 1.0, 22),
      (.615, 0, .7, 23),
      (.835, 1, 1.0, 24),
      (.98, 0, .8, 25),
    ]) {
      final x = span * f, y = crest(x) + h * .012;
      _reedStand(c, Offset(x, y), h * .085 * s, seed + kind * 30, h, plumes: kind, water: false);
      // A mound of damp earth hides the feet of the stems.
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + h * .002), width: h * .075 * s, height: h * .014),
        Paint()..color = Sketch.fade(const Color(0xff7a5230), .85),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(x - h * .006 * s, y - h * .001), width: h * .04 * s, height: h * .008),
        Paint()..color = Sketch.fade(const Color(0xffa57a48), .8),
      );
    }
    return recorder.endRecording();
  }

  // --- the river ------------------------------------------------------------------

  /// Mirrored bank features for the water, as (u, width, height, tone) in
  /// heights: house blocks and their white walls sit under each village.
  static const _nileBlocks = [
    (.19, .06, .048, 0), (.255, .05, .066, 1), (.335, .058, .055, 1), //
    (.405, .07, .05, 0), (.47, .05, .115, 0), (.535, .056, .072, 0),
    (.595, .06, .045, 0), (.65, .052, .06, 1), (1.88, .055, .048, 0),
    (1.945, .06, .06, 0), (2.07, .085, .036, 1), (2.12, .02, .1, 1),
    (2.175, .05, .046, 1), (2.24, .052, .056, 0),
  ];

  static final _nileWaters =
      <double, ({Paint sheen, Path shade, Path blocks, Path walls, Path trunks, Path reedsA, Path reedsB, List<Path> light, List<Path> dark})>{};

  /// The static parts of the river for one repeat, built once per viewport:
  /// bank reflections cut into wobbling rows, ripple dashes, the wet mud lip.
  static ({Paint sheen, Path shade, Path blocks, Path walls, Path trunks, Path reedsA, Path reedsB, List<Path> light, List<Path> dark}) _nileWater(double h) {
    final cached = _nileWaters[h];
    if (cached != null) return cached;
    final span = _nileSpan * h;
    final top = .8065 * h;
    // Rows of a mirrored shape: thin slices with a little sideways wobble
    // whose gaps widen with distance from the shore.
    void mirror(Path out, double x0, double x1, double depth, int seed, {double shrink = 0}) {
      var y = top + h * .0012;
      var row = 0;
      while (y < top + depth) {
        final k = (y - top) / depth;
        final rowH = h * (.0032 + .0014 * k);
        final wob = (Sketch.hash(seed + row * 3) - .5) * h * .008 * (.4 + k);
        final inset = shrink * k * (x1 - x0) * .5;
        out.addRect(Rect.fromLTRB(x0 + wob + inset, y, x1 + wob - inset, y + rowH));
        y += rowH + h * (.0016 + .0022 * k);
        row++;
      }
    }

    final blocks = Path(), walls = Path(), trunks = Path(), shade = Path();
    var seed = 900;
    for (final (u, w, ht, tone) in _nileBlocks) {
      final x0 = (u - w / 2) * h, x1 = (u + w / 2) * h;
      mirror(tone == 0 ? blocks : walls, x0, x1, math.min(ht * h * .85, h * .05), seed += 40, shrink: .12);
    }
    for (var i = 0; i < _nileGrove.length; i++) {
      final (u, tall, lean, layer) = _nileGrove[i];
      if (layer == 0) continue;
      final x = (u + lean * tall * .1) * h;
      mirror(trunks, x - h * .0035, x + h * .0035, math.min(tall * h * .9, h * .06), seed += 40);
    }
    for (final (u, r) in const [(.77, .045), (1.76, .04)]) {
      mirror(shade, (u - r) * h, (u + r) * h, h * .05, seed += 40, shrink: .5);
    }
    // Reed tufts standing in the shallows along the shore.
    final reedsA = Path(), reedsB = Path();
    for (var i = 0; i < 26; i++) {
      final x = span * (.03 + .94 * (i + Sketch.hash(i + 1300) * .7) / 26);
      final y = top + h * (.001 + .006 * Sketch.hash(i + 1400));
      for (var k = -2; k <= 2; k++) {
        final blade = h * (.007 + .012 * Sketch.hash(i * 5 + k + 1500)) * (1 - k.abs() * .16);
        final tilt = (Sketch.hash(i * 5 + k + 1600) - .5) * h * .008 + k * h * .0025;
        final bx = x + k * h * .0028;
        (k.isEven ? reedsA : reedsB)
          ..moveTo(bx - h * .0013, y)
          ..quadraticBezierTo(bx + tilt * .2, y - blade * .5, bx + tilt, y - blade)
          ..lineTo(bx + h * .0013, y)
          ..close();
      }
    }
    // Ripple dashes in three widths, near ones longer and bolder.
    final light = [Path(), Path(), Path()], dark = [Path(), Path(), Path()];
    for (var j = 0; j < 84; j++) {
      final x = span * Sketch.hash(j * 7 + 11);
      final k = math.pow(Sketch.hash(j * 7 + 12), .9).toDouble();
      final y = h * (.815 + .072 * k);
      final len = h * (.012 + .04 * Sketch.hash(j * 7 + 13)) * (.55 + k * 1.1);
      final bucket = k < .34 ? 0 : (k < .68 ? 1 : 2);
      light[bucket]
        ..moveTo(x - len, y)
        ..lineTo(x + len, y);
      dark[bucket]
        ..moveTo(x - len * .55 + h * .004, y + h * (.0035 + .002 * bucket))
        ..lineTo(x + len * .55 + h * .004, y + h * (.0035 + .002 * bucket));
    }
    final y1 = .93 * h;
    // Hard, pixel-snapped edges: when the canvas is unclipped every repeat draws
    // its own rect, and snapped edges leave no hairline or double band between them.
    final sheen = Paint()
      ..isAntiAlias = false
      ..shader = Gradient.linear(
        Offset(0, top),
        Offset(0, y1),
        const [
          Color(0xff275f55), Color(0xa02f7562), Color(0x40469a86), //
          Color(0x30f3fff2), Color(0x18c5f0ee), Color(0x40357fa0),
        ],
        const [0, .06, .2, .42, .62, 1],
      );
    return _nileWaters[h] = (
      sheen: sheen,
      shade: shade,
      blocks: blocks,
      walls: walls,
      trunks: trunks,
      reedsA: reedsA,
      reedsB: reedsB,
      light: light,
      dark: dark,
    );
  }

  static final _nileFill = Paint();
  static final _nileStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  /// The Nile in front of its ground: reflections, ripples, glints, a
  /// shadoof at work, egrets and the feluccas. [presence] fades it out at a
  /// crossing; boats also sink so they slip behind the near bank.
  static void _nileOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h, time = f.clock, span = _nileSpan * h;
    final view = c.getLocalClipBounds();
    final water = _nileWater(h);
    final top = .8065 * h;
    // Shore-side tint and the sky's sheen across the whole river.
    // The tint is the same everywhere, so it is drawn once, by the repeat that
    // holds the left edge of the view, to keep translucent seams out.
    final bounded = view.left > -1e5 && view.right < 1e6;
    final sheen = water.sheen..color = Color.fromRGBO(255, 255, 255, presence);
    if (!bounded) {
      c.drawRect(Rect.fromLTRB(0, top, span, .93 * h), sheen);
    } else if (view.left >= 0 && view.left < span) {
      c.drawRect(Rect.fromLTRB(view.left - 2, top, view.right + 2, .93 * h), sheen);
    }
    // Mirrored village walls, trunks and trees, broken into rows.
    _nileFill.color = Sketch.fade(const Color(0xff3c6e4e), .34 * presence);
    c.drawPath(water.shade, _nileFill);
    _nileFill.color = Sketch.fade(const Color(0xff2f5f46), .3 * presence);
    c.drawPath(water.trunks, _nileFill);
    _nileFill.color = Sketch.fade(const Color(0xffb9946a), .3 * presence);
    c.drawPath(water.blocks, _nileFill);
    _nileFill.color = Sketch.fade(const Color(0xfff2e6c8), .36 * presence);
    c.drawPath(water.walls, _nileFill);
    // Reeds standing in the shallows.
    _nileFill.color = Sketch.fade(const Color(0xff4f7d3d), presence);
    c.drawPath(water.reedsA, _nileFill);
    _nileFill.color = Sketch.fade(const Color(0xff7aa84d), presence);
    c.drawPath(water.reedsB, _nileFill);
    // Ripples drift a little sideways on the clock.
    for (var b = 0; b < 3; b++) {
      final drift = math.sin(time * (.5 + b * .13) + b * 2) * h * (.004 + b * .002);
      c.save();
      c.translate(drift, 0);
      _nileStroke
        ..strokeWidth = math.max(.6, h * (.0014 + b * .0009))
        ..color = Sketch.fade(const Color(0xff2f7f92), .32 * presence);
      c.drawPath(water.dark[b], _nileStroke);
      _nileStroke.color = Sketch.fade(const Color(0xfff2fff4), (.3 + b * .08) * presence);
      c.drawPath(water.light[b], _nileStroke);
      c.restore();
    }
    // Sun glints twinkle on the ripples.
    _nileStroke
      ..strokeWidth = h * .0035
      ..color = Sketch.fade(const Color(0xfffff6dc), .75 * presence);
    for (var i = 0; i < 22; i++) {
      final phase = time * (1.1 + i * .09) + i * 2.1;
      final on = .5 + .5 * math.sin(phase);
      if (on < .35) continue;
      final x = span * Sketch.hash(i + 40);
      if (x < view.left - h * .1 || x > view.right + h * .1) continue;
      final y = h * (.818 + .06 * Sketch.hash(i + 60));
      final len = h * .016 * on;
      c.drawLine(Offset(x - len, y), Offset(x + len, y), _nileStroke);
    }
    _nileShadoof(c, Offset(1.62 * h, .8065 * h + (1 - presence) * h * .3), h, time, presence, view);
    // Egrets: one gliding low over the river on a slow lap, one fishing.
    final flyX = (span * .45 - time * h * .045) % span;
    if (flyX > view.left - h * .2 && flyX < view.right + h * .2) {
      _nileEgretFly(
        c,
        Offset(flyX, h * (.831 + .004 * math.sin(time * .9))),
        h * .018,
        math.sin(time * 5.2),
        presence,
      );
    }
    // The feluccas, far to near: (u, y, size, heading right?, speed, style).
    // Every repeat draws its own replica of each boat, and the next repeat
    // paints its water over the spill of this one, so a boat within reach of
    // the seam is drawn once more at the start of the next repeat, on top.
    // They fade with the crossing; the layer only exists while it is running.
    final fade = presence < .995;
    if (fade) {
      c.saveLayer(
        Rect.fromLTWH(-h, h * .6, span + h * 2, h * .6),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
    }
    for (final (u, y, size, right, speed, style) in const [
      (1.95, .828, .026, false, .006, 2),
      (1.2, .846, .04, false, .011, 1),
      (.35, .863, .057, true, .009, 0),
      (.9, .832, .03, false, .0035, 3),
    ]) {
      final dir = right ? 1.0 : -1.0;
      final x = ((u * h + dir * time * speed * h) % span + span) % span;
      final sink = (1 - presence) * h * .3;
      // The hull plus its wake reach about 3.6 half-lengths from the middle.
      for (final px in [x, if (x > span - size * h * 3.6) x - span]) {
        if (px < view.left - h * .3 || px > view.right + h * .3) continue;
        _felucca(
          c,
          Offset(px, y * h + sink),
          size * h,
          flip: right,
          style: style,
          clock: time,
          haze: style == 2 ? .3 : (style == 1 ? .1 : 0),
        );
      }
    }
    if (fade) c.restore();
  }

  /// Sunlight on the river, screen-space: a glittering column under the sun.
  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, time = f.clock;
    final x0 = light.at.dx * w;
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(x0, h * .855), width: h * .34, height: h * .1),
      const Color(0xfffff0c0),
      .26 * presence,
    );
    _nileStroke.strokeWidth = math.max(.8, h * .0032);
    for (var i = 0; i < 26; i++) {
      final k = Sketch.hash(i + 200);
      final y = h * (.812 + .066 * k);
      final spread = h * (.03 + .07 * k);
      final x = x0 + (Sketch.hash(i + 230) - .5) * 2 * spread + math.sin(time * 1.3 + i * 1.7) * h * .006;
      final twinkle = .5 + .5 * math.sin(time * (1.6 + (i % 5) * .3) + i * 2.4);
      final len = h * (.008 + .02 * k) * (.55 + .45 * twinkle);
      _nileStroke.color = Sketch.fade(const Color(0xfffff9e4), (.35 + .5 * twinkle) * presence);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), _nileStroke);
    }
  }

  /// A shadoof: two mud pillars, a counterweighted pole and a bucket, worked
  /// by a farmer, dipping into the Nile on a slow beat.
  static void _nileShadoof(Canvas c, Offset base, double h, double time, double presence, Rect view) {
    if (base.dx < view.left - h * .3 || base.dx > view.right + h * .3) return;
    final swing = math.sin(time * .55);
    final s = h * .06;
    final mud = Paint()..color = Sketch.fade(const Color(0xff7a5a3a), presence);
    final lit = Paint()..color = Sketch.fade(const Color(0xffa8815a), presence);
    final wood = Paint()
      ..color = Sketch.fade(const Color(0xff5a3e2a), presence)
      ..strokeWidth = math.max(.9, s * .05)
      ..strokeCap = StrokeCap.round;
    final rope = Paint()
      ..color = Sketch.fade(const Color(0xff3f2f22), presence * .9)
      ..strokeWidth = math.max(.6, s * .022);
    // Pillars joined by a crossbeam.
    final pivot = base + Offset(0, -s * .95);
    for (final dx in const [-.11, .11]) {
      c.drawPath(
        Sketch.poly([
          base.dx + (dx - .09) * s, base.dy, base.dx + (dx - .05) * s, pivot.dy + s * .05, //
          base.dx + (dx + .05) * s, pivot.dy + s * .05, base.dx + (dx + .09) * s, base.dy,
        ]),
        dx < 0 ? mud : lit,
      );
    }
    c.drawLine(pivot + Offset(-s * .17, 0), pivot + Offset(s * .17, 0), wood);
    // The pole rocks about the pivot: the long arm dips, the mud weight rises.
    final tilt = -.16 - swing * .2;
    final dir = Offset(math.cos(tilt), math.sin(tilt));
    final long = pivot + dir * s * 1.5;
    final short = pivot - dir * s * .55;
    wood.strokeWidth = math.max(1.0, s * .06);
    c.drawLine(short, long, wood);
    c.drawCircle(short + Offset(0, s * .07), s * .12, mud);
    c.drawCircle(short + Offset(s * .03, s * .04), s * .05, lit);
    // Bucket on a rope from the tip.
    final drop = s * .42;
    c.drawLine(long, long + Offset(0, drop), rope);
    final bucket = long + Offset(0, drop);
    c.drawPath(
      Sketch.poly([
        bucket.dx - s * .07, bucket.dy, bucket.dx + s * .07, bucket.dy, //
        bucket.dx + s * .05, bucket.dy + s * .1, bucket.dx - s * .05, bucket.dy + s * .1,
      ]),
      Paint()..color = Sketch.fade(const Color(0xff7a5a3e), presence),
    );
    // The farmer at the foot of the pillars, hauling on the rope.
    final fx = base.dx - s * .42;
    c.drawPath(
      Sketch.poly([
        fx - s * .06, base.dy - s * .32, fx + s * .06, base.dy - s * .32, //
        fx + s * .1, base.dy, fx - s * .1, base.dy,
      ]),
      Paint()..color = Sketch.fade(const Color(0xffe8e0cc), presence),
    );
    c.drawCircle(Offset(fx, base.dy - s * .38), s * .048, Paint()..color = Sketch.fade(const Color(0xff87573a), presence));
    c.drawOval(
      Rect.fromCenter(center: Offset(fx, base.dy - s * .42), width: s * .13, height: s * .06),
      Paint()..color = Sketch.fade(const Color(0xff4f6f9a), presence),
    );
    c.drawLine(Offset(fx + s * .04, base.dy - s * .28), short + Offset(s * .04, s * .12), rope);
  }

  /// An egret gliding low, white with a tucked neck and trailing legs.
  static void _nileEgretFly(Canvas c, Offset p, double s, double flap, double presence) {
    final white = Paint()..color = Sketch.fade(const Color(0xfffbf8ee), presence);
    final lift = s * (.35 + flap * .5);
    // Wings sweep up and down about the shoulder.
    final wings = Path()
      ..moveTo(p.dx - s * .1, p.dy - s * .04)
      ..quadraticBezierTo(p.dx - s * .9, p.dy - lift * 1.2, p.dx - s * 1.5, p.dy - lift * .5 + s * .1)
      ..quadraticBezierTo(p.dx - s * .7, p.dy - lift * .3, p.dx + s * .1, p.dy + s * .08)
      ..quadraticBezierTo(p.dx + s * .7, p.dy - lift * .3, p.dx + s * 1.3, p.dy - lift * .5 + s * .1)
      ..quadraticBezierTo(p.dx + s * .8, p.dy - lift * 1.2, p.dx + s * .1, p.dy - s * .04)
      ..close();
    c.drawPath(wings, white);
    c.drawOval(Rect.fromCenter(center: p + Offset(s * .05, s * .05), width: s * 1.0, height: s * .3), white);
    c.drawCircle(p + Offset(-s * .5, -s * .02), s * .1, white);
    c.drawLine(
      p + Offset(-s * .58, -s * .02),
      p + Offset(-s * .82, s * .03),
      Paint()
        ..color = Sketch.fade(const Color(0xffe6b34a), presence)
        ..strokeWidth = math.max(.7, s * .07)
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      p + Offset(s * .5, s * .08),
      p + Offset(s * 1.15, s * .2),
      Paint()
        ..color = Sketch.fade(const Color(0xff4a4238), presence)
        ..strokeWidth = math.max(.6, s * .05)
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A standing egret on the bank, [s] tall, facing left ([flip] to face right).
  static void _nileEgret(
    Canvas c,
    Offset base,
    double s, {
    bool flip = false,
    double craned = 1,
    Color body = const Color(0xfffbf8ee),
    bool cap = false,
  }) {
    c.save();
    c.translate(base.dx, base.dy);
    if (flip) c.scale(-1, 1);
    final white = Paint()..color = body;
    final leg = Paint()
      ..color = const Color(0xff4a4238)
      ..strokeWidth = math.max(.6, s * .045)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(-s * .02, -s * .34), Offset(-s * .04, 0), leg);
    c.drawLine(Offset(s * .08, -s * .34), Offset(s * .1, 0), leg);
    // Plumed body, S-curved neck, head and yellow bill.
    c.drawPath(
      Path()
        ..moveTo(-s * .12, -s * .42)
        ..quadraticBezierTo(s * .12, -s * .28, s * .34, -s * .44)
        ..quadraticBezierTo(s * .18, -s * .4, s * .1, -s * .55)
        ..quadraticBezierTo(-s * .02, -s * .56, -s * .12, -s * .42)
        ..close(),
      white,
    );
    final neckTop = Offset(-s * .16, -s * (.62 + .32 * craned));
    c.drawPath(
      Path()
        ..moveTo(s * .0, -s * .5)
        ..cubicTo(s * .1, -s * .62, -s * .2, -s * .68, neckTop.dx, neckTop.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = body
        ..strokeWidth = math.max(.8, s * .09)
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(neckTop, s * .075, white);
    if (cap) {
      c.drawLine(
        neckTop + Offset(s * .02, -s * .05),
        neckTop + Offset(s * .2, -s * .1),
        Paint()
          ..color = const Color(0xff3a4046)
          ..strokeWidth = math.max(.6, s * .04)
          ..strokeCap = StrokeCap.round,
      );
    }
    c.drawLine(
      neckTop + Offset(-s * .06, 0),
      neckTop + Offset(-s * .24, s * .04),
      Paint()
        ..color = const Color(0xffe6b34a)
        ..strokeWidth = math.max(.7, s * .06)
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  /// A felucca under its patched lateen sail, with crew, rigging and wake.
  /// [at] is the waterline amidships, [s] half the hull length; the bow points
  /// left unless [flip]. [style] picks the paint and sail; [haze] pales far ones.
  static void _felucca(
    Canvas c,
    Offset at,
    double s, {
    required bool flip,
    required int style,
    required double clock,
    double haze = 0,
  }) {
    final bob = math.sin(clock * 1.3 + style * 1.7) * s * .03;
    final roll = math.sin(clock * 1.05 + style * 2.3) * .016;
    final sailTone = Sketch.mix(Color(0xff000000 | const [0xf7edd6, 0xf3e2bd, 0xf1e6cf, 0xf1e6cf][style]), const Color(0xffdfe4d2), haze);
    c.save();
    c.translate(at.dx, at.dy);
    if (flip) c.scale(-1, 1);
    // Wake trailing off the stern, a bow wave and the sail's broken reflection.
    final foam = Paint()
      ..color = Sketch.fade(const Color(0xffffffff), .5 * (1 - haze * .5))
      ..strokeWidth = math.max(.7, s * .05)
      ..strokeCap = StrokeCap.round;
    for (final (y, from, to, a) in const [(.1, .95, 3.4, .5), (.17, 1.2, 2.7, .4), (.24, 1.5, 2.3, .3)]) {
      foam.color = Sketch.fade(const Color(0xffffffff), a * (1 - haze * .5));
      c.drawLine(Offset(from * s, y * s), Offset(to * s, (y + .012) * s), foam);
    }
    foam.color = Sketch.fade(const Color(0xffffffff), .65);
    c.drawPath(
      Path()
        ..moveTo(-1.02 * s, -.02 * s)
        ..quadraticBezierTo(-.96 * s, .1 * s, -.7 * s, .11 * s),
      foam
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, s * .06),
    );
    final glint = Paint()
      ..color = Sketch.fade(sailTone, .32)
      ..strokeWidth = math.max(.8, s * .07)
      ..strokeCap = StrokeCap.round;
    for (final (y, x0, x1) in const [(.3, -.55, .5), (.46, -.4, .3), (.62, -.25, .12)]) {
      c.drawLine(Offset(x0 * s, y * s), Offset(x1 * s, y * s), glint);
    }
    glint
      ..color = Sketch.fade(const Color(0xff2b5560), .3)
      ..strokeWidth = math.max(.8, s * .06);
    c.drawLine(Offset(-.7 * s, .23 * s), Offset(-.05 * s, .23 * s), glint);
    c.drawLine(Offset(.2 * s, .23 * s), Offset(.75 * s, .23 * s), glint);

    c.translate(0, bob);
    c.rotate(roll);
    c.drawPicture(_nileBoat(style, s, haze));
    c.restore();
  }

  static final _nileBoats = <(int, double, double), Picture>{};

  /// The boat's hull, sail and crew recorded once, so each frame only draws
  /// one picture under the bobbing transform.
  static Picture _nileBoat(int style, double s, double haze) {
    final key = (style, s, haze);
    final cached = _nileBoats[key];
    if (cached != null) return cached;
    if (_nileBoats.length > 24) {
      for (final picture in _nileBoats.values) {
        picture.dispose();
      }
      _nileBoats.clear();
    }
    final recorder = PictureRecorder();
    _nileBoatBody(Canvas(recorder), s, style, haze);
    return _nileBoats[key] = recorder.endRecording();
  }

  /// A fisherman's skiff: a small upswept hull and a man about to cast his net.
  static void _nileSkiffBody(Canvas c, double s, double haze) {
    Color tone(int rgb) => Sketch.mix(Color(0xff000000 | rgb), const Color(0xffdfe4d2), haze);
    final sheer = Path()
      ..moveTo(-1.0 * s, -.24 * s)
      ..quadraticBezierTo(-.5 * s, -.02 * s, 0, -.05 * s)
      ..quadraticBezierTo(.6 * s, -.06 * s, 1.0 * s, -.2 * s);
    final hull = Path.from(sheer)
      ..quadraticBezierTo(.7 * s, .15 * s, 0, .15 * s)
      ..quadraticBezierTo(-.7 * s, .15 * s, -1.0 * s, -.24 * s)
      ..close();
    c.drawPath(hull, Paint()..color = tone(0x7c5a3c));
    c.drawPath(
      sheer.shift(Offset(0, s * .05)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = tone(0x3d7f8c)
        ..strokeWidth = s * .08,
    );
    c.drawPath(
      sheer,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = tone(0xdcc28f)
        ..strokeWidth = s * .05,
    );
    // The fisherman, arms swung out with a cast net spread before him.
    final robe = tone(0xf1e9d3);
    c.drawPath(
      Sketch.poly([-.14 * s, -.86 * s, .08 * s, -.86 * s, .16 * s, -.06 * s, -.2 * s, -.06 * s]),
      Paint()..color = robe,
    );
    c.drawCircle(Offset(-.03 * s, -1.0 * s), s * .1, Paint()..color = tone(0x87573a));
    c.drawOval(Rect.fromCenter(center: Offset(-.03 * s, -1.08 * s), width: s * .26, height: s * .13), Paint()..color = tone(0xf5efe0));
    // The net has just been cast: a wide disc, foreshortened, on the water.
    final hand = Offset(-.36 * s, -.72 * s);
    final centre = Offset(-1.45 * s, -.14 * s);
    c.drawLine(Offset(-.08 * s, -.8 * s), hand, Paint()
      ..color = robe
      ..strokeWidth = math.max(.8, s * .08)
      ..strokeCap = StrokeCap.round);
    final disc = Rect.fromCenter(center: centre, width: 1.5 * s, height: .34 * s);
    c.drawOval(disc, Paint()..color = Sketch.fade(const Color(0xffe9f4ee), .45));
    final spokes = Path();
    for (var k = -2; k <= 2; k++) {
      spokes
        ..moveTo(centre.dx + k * s * .15, centre.dy - s * .17 * math.sqrt(1 - k * k / 6.25))
        ..lineTo(centre.dx + k * s * .15, centre.dy + s * .17 * math.sqrt(1 - k * k / 6.25));
    }
    c.drawPath(
      spokes,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .02)
        ..color = Sketch.fade(tone(0x4f5a55), .5),
    );
    c.drawOval(
      disc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, s * .04)
        ..color = Sketch.fade(tone(0x4f5a55), .8),
    );
    c.drawLine(hand, centre, Paint()
      ..color = Sketch.fade(tone(0x4f5a55), .6)
      ..strokeWidth = math.max(.5, s * .02));
  }

  static void _nileBoatBody(Canvas c, double s, int style, double haze) {
    if (style == 3) {
      _nileSkiffBody(c, s, haze);
      return;
    }
    Color tone(int rgb) => Sketch.mix(Color(0xff000000 | rgb), const Color(0xffdfe4d2), haze);
    final hullTone = tone(const [0x76452c, 0x8a3f2f, 0x5e4432][style]);
    final bandTone = tone(const [0x2f7ba0, 0xf1e8d2, 0xc98d3a][style]);
    final sailTone = tone(const [0xf7edd6, 0xf3e2bd, 0xf1e6cf][style]);
    final sailShade = tone(const [0xe0d1b3, 0xdcc79b, 0xd8ccb4][style]);
    final sailPatch = tone(const [0xede0c2, 0xe9d3a6, 0xe4d8be][style]);
    final wood = tone(0x5a3e2b);
    final hair = math.max(.6, s * .022);
    // Hull: upswept prow, low waist, square stern; painted band and planks.
    final hull = Path()
      ..moveTo(-1.04 * s, -.27 * s)
      ..cubicTo(-.6 * s, -.05 * s, .3 * s, -.1 * s, .98 * s, -.17 * s)
      ..lineTo(.92 * s, .05 * s)
      ..cubicTo(.4 * s, .17 * s, -.6 * s, .16 * s, -.88 * s, .03 * s)
      ..quadraticBezierTo(-.98 * s, -.07 * s, -1.04 * s, -.27 * s)
      ..close();
    c.drawPath(hull, Paint()..color = hullTone);
    final sheer = Path()
      ..moveTo(-1.04 * s, -.27 * s)
      ..cubicTo(-.6 * s, -.05 * s, .3 * s, -.1 * s, .98 * s, -.17 * s);
    // Dark waterline and lit stern post.
    c.drawPath(
      Path()
        ..moveTo(-.86 * s, .045 * s)
        ..cubicTo(-.6 * s, .16 * s, .4 * s, .17 * s, .92 * s, .05 * s)
        ..lineTo(.92 * s, .0 * s)
        ..cubicTo(.4 * s, .11 * s, -.6 * s, .11 * s, -.86 * s, .0),
      Paint()..color = Sketch.fade(const Color(0xff24160e), .5),
    );
    // Mast, long yard and the patched triangular sail.
    final tack = Offset(-.9 * s, -.3 * s);
    final peak = Offset(.5 * s, -2.05 * s);
    final clew = Offset(.66 * s, -.25 * s);
    final mastTop = Offset(-.22 * s, -1.2 * s);
    c.drawLine(Offset(-.3 * s, -.14 * s), mastTop, Paint()
      ..color = wood
      ..strokeWidth = math.max(.9, s * .05)
      ..strokeCap = StrokeCap.round);
    final sail = Path()..moveTo(tack.dx, tack.dy);
    sail
      ..lineTo(peak.dx, peak.dy)
      ..quadraticBezierTo(clew.dx + s * .25, -1.1 * s, clew.dx, clew.dy)
      ..quadraticBezierTo((tack.dx + clew.dx) / 2, .06 * s, tack.dx, tack.dy)
      ..close();
    c.drawPath(sail, Paint()..color = sailTone);
    // Panels run parallel to the foot; every other one is a slightly different cloth.
    final seams = Path();
    final patches = Path();
    const cuts = 7;
    Offset yardAt(double t) => Offset.lerp(tack, peak, t)!;
    Offset leechAt(double t) {
      final mid = Offset(clew.dx + s * .25, -1.1 * s);
      final a = Offset.lerp(clew, mid, t)!, b = Offset.lerp(mid, peak, t)!;
      return Offset.lerp(a, b, t)!;
    }

    for (var k = 1; k < cuts; k++) {
      final t = k / cuts;
      final a = yardAt(t), b = leechAt(t);
      seams
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
      if (k.isEven) {
        final t0 = (k - 1) / cuts;
        final a0 = yardAt(t0), b0 = leechAt(t0);
        patches
          ..moveTo(a0.dx, a0.dy)
          ..lineTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b0.dx, b0.dy)
          ..close();
      }
    }
    c.drawPath(patches, Paint()..color = sailPatch);
    // The luff side of the sail sits in shade, curling at the foot.
    c.drawPath(
      Path()
        ..moveTo(tack.dx, tack.dy)
        ..lineTo(peak.dx, peak.dy)
        ..lineTo(peak.dx + s * .05, peak.dy + s * .28)
        ..quadraticBezierTo(-.05 * s, -1.0 * s, -.22 * s, -.5 * s)
        ..quadraticBezierTo(-.5 * s, -.2 * s, tack.dx, tack.dy)
        ..close(),
      Paint()..color = Sketch.fade(sailShade, .75),
    );
    c.drawPath(
      seams,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .014)
        ..color = Sketch.fade(const Color(0xff8a7458), .35 * (1 - haze)),
    );
    // The painted band and gunwale pass in front of the sail's foot.
    c.drawPath(
      sheer.shift(Offset(0, s * .055)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = bandTone
        ..strokeWidth = s * .075,
    );
    c.drawPath(
      sheer.shift(Offset(0, s * .012)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = tone(0xe8d8b0)
        ..strokeWidth = s * .04,
    );
    c.drawPath(
      sheer.shift(Offset(0, s * .13)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Sketch.fade(const Color(0xff2b1a10), .4)
        ..strokeWidth = hair,
    );
    // Yard, rigging, and a slim pennant at the peak.
    c.drawLine(
      tack + Offset(-s * .05, s * .01),
      peak + Offset(s * .04, -s * .05),
      Paint()
        ..color = wood
        ..strokeWidth = math.max(.9, s * .04)
        ..strokeCap = StrokeCap.round,
    );
    final rig = Paint()
      ..color = Sketch.fade(const Color(0xff3f2f22), .7 * (1 - haze))
      ..strokeWidth = hair;
    c.drawLine(mastTop, Offset(-1.0 * s, -.25 * s), rig);
    c.drawLine(peak, Offset(.9 * s, -.17 * s), rig);
    c.drawLine(clew, Offset(.82 * s, -.16 * s), rig);
    c.drawPath(
      Sketch.poly([peak.dx + s * .04, peak.dy - s * .05, peak.dx + s * .2, peak.dy - s * .0, peak.dx + s * .04, peak.dy + s * .04]),
      Paint()..color = tone(0xc4483a),
    );
    // Crew: a helmsman at the tiller, a sailor by the mast and one forward.
    if (style < 2) {
      void sailor(double x, double h, Color robe, {bool sits = false}) {
        final y = -.14 * s + (sits ? .0 : -.02 * s);
        c.drawPath(
          Sketch.poly([x - s * .05, y - h * .7, x + s * .05, y - h * .7, x + s * .075, y, x - s * .075, y]),
          Paint()..color = robe,
        );
        c.drawCircle(Offset(x, y - h * .82), s * .05, Paint()..color = tone(0x87573a));
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y - h * .9), width: s * .12, height: s * .07),
          Paint()..color = tone(0xf2ead2),
        );
      }

      sailor(.78 * s, s * .38, tone(0xf0e8d4), sits: true);
      sailor(.12 * s, s * .42, tone(0x4f6f9a));
      if (style == 0) sailor(-.62 * s, s * .4, tone(0xd9b98a));
      c.drawLine(Offset(.86 * s, -.15 * s), Offset(1.12 * s, -.3 * s), Paint()
        ..color = wood
        ..strokeWidth = math.max(.8, s * .04)
        ..strokeCap = StrokeCap.round);
    }
  }
}
