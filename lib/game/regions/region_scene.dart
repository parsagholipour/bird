import 'dart:math' as math;
import 'dart:ui';

import 'antarctica.dart';
import 'arabia.dart';
import 'aztec.dart';
import 'brazil.dart';
import 'china.dart';
import 'egypt.dart';
import 'jungle.dart';
import 'mexico.dart';
import 'new_york.dart';
import 'paris.dart';
import 'rome.dart';
import 'sea.dart';
import 'weather.dart';
import 'world_region.dart';

/// The four parallax bands every region fills, back to front.
enum Depth {
  far(.018, timed: true),
  mid(.05, timed: true),
  low(.1),
  near(.18);

  const Depth(this.parallax, {this.timed = false});

  /// Viewport heights travelled per unit of flown distance.
  final double parallax;

  /// Timed bands drift on the region's own clock, so a landmark enters where
  /// it was composed on every flight. Nearer bands follow the flown distance.
  final bool timed;
}

/// A sun or a moon. [at] is a fraction of the viewport; sizes are in
/// viewport heights. [moon] shades the disc into a crescent.
class SkyLight {
  const SkyLight({
    required this.at,
    required this.radius,
    required this.disc,
    required this.glow,
    this.halo = .32,
    this.strength = .3,
    this.moon = 0,
  });
  final Offset at;
  final double radius, halo, strength, moon;
  final Color disc, glow;

  static SkyLight lerp(SkyLight a, SkyLight b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    double mix(double x, double y) => x + (y - x) * t;
    return SkyLight(
      at: Offset.lerp(a.at, b.at, t)!,
      radius: mix(a.radius, b.radius),
      disc: Color.lerp(a.disc, b.disc, t)!,
      glow: Color.lerp(a.glow, b.glow, t)!,
      halo: mix(a.halo, b.halo),
      strength: mix(a.strength, b.strength),
      moon: mix(a.moon, b.moon),
    );
  }
}

/// Colours of one terrain band: a vertical fill and a lit ridge line.
class Ground {
  const Ground(this.top, this.bottom, this.rim, {this.rimWidth = .005});
  final Color top, bottom, rim;

  /// Ridge line thickness in viewport heights.
  final double rimWidth;

  static Ground lerp(Ground a, Ground b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return Ground(
      Color.lerp(a.top, b.top, t)!,
      Color.lerp(a.bottom, b.bottom, t)!,
      Color.lerp(a.rim, b.rim, t)!,
      rimWidth: a.rimWidth + (b.rimWidth - a.rimWidth) * t,
    );
  }
}

/// One replayable frame of the scenery.
class SceneFrame {
  const SceneFrame(
    this.size, {
    required this.seconds,
    required this.distance,
    required this.reducedMotion,
  });
  final Size size;
  final double seconds, distance;
  final bool reducedMotion;
  double get w => size.width;
  double get h => size.height;

  /// Animation clock, frozen in Reduced Motion.
  double get clock => reducedMotion ? 0 : seconds;
}

/// One region's backdrop. Coordinates are pixels; sizes scale with the
/// viewport height `h`, and world x positions are in viewport heights.
///
/// Per depth, [features] (landmarks, trees, buildings) are recorded once and
/// drawn *before* the terrain, so their bases hide behind the ridge and a
/// crossing can sink them below the horizon without any fading layer.
abstract class RegionScene {
  const RegionScene();

  WorldRegion get region;
  SkyLight get light;
  Weather get weather;

  /// Where the sky gradient reaches the horizon colour, as a height fraction.
  double get horizon;

  Ground ground(Depth d);

  /// Ridge height in viewport heights from the top at world x (in viewport
  /// heights). Values over 1 leave the band empty. [clock] moves water.
  double ridge(Depth d, double x, double clock);

  /// Repeat width of a distance-scrolled band, in viewport heights. Timed
  /// bands are composed once across the viewport instead.
  double period(Depth d) => 3;

  /// How far a band's features drop to hide behind its ridge.
  double sink(Depth d) => .32;

  /// Static features, recorded into a cached picture. Timed bands use
  /// viewport coordinates; repeating bands draw one period from x = 0.
  void features(Canvas c, Depth d, Size size) {}

  /// Animated features in the same coordinates as [features], drawn behind
  /// the ridge each frame. [copy] counts repeats of a distance-scrolled band.
  void live(Canvas c, Depth d, SceneFrame f, int copy) {}

  /// Detail painted over the ridge (glints, foam, snow sparkle), in the same
  /// coordinates, fading out with [presence] during a crossing.
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {}

  /// Screen-space light on the water (a sun or moon path), painted after the
  /// low band, fading out with [presence] during a crossing.
  void reflect(Canvas c, SceneFrame f, double presence) {}

  /// Sky decoration over the gradient and light: clouds, aurora, rays.
  void sky(Canvas c, SceneFrame f, double presence) {}

  static RegionScene of(WorldRegion region) => switch (region) {
    WorldRegion.egypt => const EgyptScene(),
    WorldRegion.antarctica => const AntarcticaScene(),
    WorldRegion.jungle => const JungleScene(),
    WorldRegion.china => const ChinaScene(),
    WorldRegion.newYork => const NewYorkScene(),
    WorldRegion.sea => const SeaScene(),
    WorldRegion.aztec => const AztecScene(),
    WorldRegion.paris => const ParisScene(),
    WorldRegion.brazil => const BrazilScene(),
    WorldRegion.arabia => const ArabiaScene(),
    WorldRegion.rome => const RomeScene(),
    WorldRegion.mexico => const MexicoScene(),
  };
}

/// Small shared drawing vocabulary for the region painters.
abstract final class Sketch {
  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static Color fade(Color c, double alpha) =>
      c.withValues(alpha: (c.a * alpha).clamp(0.0, 1.0));

  /// A closed polygon through [points], each given as (x, y) pairs.
  static Path poly(List<double> xy, {Offset at = Offset.zero, double s = 1}) {
    final path = Path()..moveTo(at.dx + xy[0] * s, at.dy + xy[1] * s);
    for (var i = 2; i + 1 < xy.length; i += 2) {
      path.lineTo(at.dx + xy[i] * s, at.dy + xy[i + 1] * s);
    }
    return path..close();
  }

  /// Deterministic noise in [0, 1) for seeded placement.
  static double hash(int n) {
    var x = (n * 374761393 + 668265263) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
    return (x ^ (x >> 16)) / 0x80000000;
  }

  /// A small gliding bird: two swept wings and a body, [flap] in -1..1.
  static void bird(
    Canvas c,
    Offset p,
    double span,
    Color color, {
    double flap = 0,
  }) {
    final lift = span * (.2 + flap * .22);
    final path = Path()
      ..moveTo(p.dx - span, p.dy - lift)
      ..quadraticBezierTo(
        p.dx - span * .45,
        p.dy - lift * .9 - span * .05,
        p.dx,
        p.dy + span * .06,
      )
      ..quadraticBezierTo(
        p.dx + span * .45,
        p.dy - lift * .9 - span * .05,
        p.dx + span,
        p.dy - lift,
      )
      ..quadraticBezierTo(
        p.dx + span * .45,
        p.dy - lift * .35,
        p.dx,
        p.dy + span * .2,
      )
      ..quadraticBezierTo(
        p.dx - span * .45,
        p.dy - lift * .35,
        p.dx - span,
        p.dy - lift,
      )
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  /// A soft lens of haze, cheaper than a blur: a radial gradient oval.
  static void mist(Canvas c, Rect r, Color color, double alpha) {
    if (alpha <= 0 || r.isEmpty) return;
    final radius = r.width / 2;
    c.save();
    c.translate(r.center.dx, r.center.dy);
    c.scale(1, r.height / r.width);
    c.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          radius,
          [fade(color, alpha), fade(color, alpha * .5), fade(color, 0)],
          const [0, .5, 1],
        ),
    );
    c.restore();
  }

  /// A palm: a tapered, gently curved trunk and a dense crown of arching
  /// fronds. [lean] bends the crown sideways as a fraction of [height];
  /// [dates] hangs fruit clusters under a date palm's crown.
  static void palm(
    Canvas c,
    Offset base,
    double height, {
    double lean = 0,
    required Color trunk,
    required Color trunkShade,
    required Color frond,
    required Color frondLit,
    bool detail = true,
    bool dates = false,
    double droop = .42,
  }) {
    final crown = base + Offset(lean * height, -height);
    final bend = base + Offset(lean * height * .15, -height * .55);
    final low = height * .05, high = height * .032;
    c.drawPath(
      Path()
        ..moveTo(base.dx - low, base.dy)
        ..quadraticBezierTo(bend.dx - low, bend.dy, crown.dx - high, crown.dy)
        ..lineTo(crown.dx + high, crown.dy)
        ..quadraticBezierTo(bend.dx + low, bend.dy, base.dx + low, base.dy)
        ..close(),
      Paint()..color = trunk,
    );
    if (detail) {
      c.drawPath(
        Path()
          ..moveTo(base.dx + low * .15, base.dy)
          ..quadraticBezierTo(
            bend.dx + low * .15,
            bend.dy,
            crown.dx + high * .15,
            crown.dy,
          )
          ..lineTo(crown.dx + high, crown.dy)
          ..quadraticBezierTo(bend.dx + low, bend.dy, base.dx + low, base.dy)
          ..close(),
        Paint()..color = trunkShade,
      );
      // Leaf-scar rings climb the trunk.
      final rings = Path();
      for (var k = .08; k < .96; k += .075) {
        final a = Offset.lerp(
          Offset.lerp(base, bend, k)!,
          Offset.lerp(bend, crown, k)!,
          k,
        )!;
        final half = low + (high - low) * k;
        rings
          ..moveTo(a.dx - half, a.dy + half * .25)
          ..lineTo(a.dx + half, a.dy - half * .25);
      }
      c.drawPath(
        rings,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = trunkShade
          ..strokeWidth = math.max(.8, height * .009),
      );
    }
    final dark = Paint()..color = frond;
    final lit = Paint()..color = frondLit;
    // Back fronds droop low in shade; front fronds arch up into the light.
    for (final (a, len, sag) in const [
      (3.35, .5, 1.2),
      (-.2, .5, 1.2),
      (2.85, .54, 1),
      (.3, .54, 1),
      (2.3, .5, .7),
      (.85, .5, .7),
    ]) {
      _frond(c, crown, -a, height * len, droop * sag, dark);
    }
    for (final (a, len, sag) in const [
      (3.05, .44, .9),
      (.1, .44, .9),
      (2.55, .46, .6),
      (.6, .46, .6),
      (1.95, .38, .3),
      (1.25, .38, .3),
      (1.6, .3, .1),
    ]) {
      _frond(c, crown, -a, height * len, droop * sag, lit);
    }
    if (dates) {
      final fruit = Paint()..color = const Color(0xffc8763a);
      for (final dx in const [-.07, .06]) {
        c.drawOval(
          Rect.fromCenter(
            center: crown + Offset(dx * height, height * .07),
            width: height * .07,
            height: height * .1,
          ),
          fruit,
        );
      }
    }
    c.drawCircle(crown, height * .035, dark);
  }

  static void _frond(
    Canvas c,
    Offset root,
    double angle,
    double len,
    double droop,
    Paint paint,
  ) {
    final dir = Offset(math.cos(angle), math.sin(angle));
    final tip = root + dir * len + Offset(0, len * droop);
    final mid = root + dir * len * .58 - Offset(0, len * .08);
    final side = Offset(-dir.dy, dir.dx) * len * .14;
    c.drawPath(
      Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(mid.dx + side.dx, mid.dy + side.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(
          mid.dx - side.dx * .6,
          mid.dy - side.dy * .6,
          root.dx,
          root.dy,
        )
        ..close(),
      paint,
    );
  }

  /// Rounded humps with cusps between them, like tree crowns: 0..1.
  static double humps(double x) {
    final p = x - x.floorToDouble();
    return 4 * p * (1 - p);
  }

  /// Symmetric peaks: a triangle wave in 0..1.
  static double peaks(double x) {
    final p = x - x.floorToDouble();
    return 1 - (2 * p - 1).abs();
  }

  /// Sum of sines: a cheap, seamless ridge profile. Each wave is
  /// (period, amplitude, phase) with the period in viewport heights.
  static double waves(double x, List<(double, double, double)> spec) {
    var y = 0.0;
    for (final (period, amplitude, phase) in spec) {
      y += amplitude * math.sin(x / period * math.pi * 2 + phase);
    }
    return y;
  }
}
