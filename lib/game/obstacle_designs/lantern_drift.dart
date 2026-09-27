import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Round paper lantern clipped to the circular collision body. The paper is
/// lit from inside, ribbed like a chōchin and capped with lacquered bands so
/// both poles read clearly, while a solid rim marks the collision edge.
abstract final class LanternDriftDesign {
  /// Latitude of the lacquered caps as a fraction of the radius.
  static const _capAt = .56;

  /// How far a latitude line bows toward its pole, per unit of latitude.
  /// The equator stays straight and lines bow more near the caps, the
  /// classic storybook way of drawing a round lantern.
  static const _bow = .24;

  static void paint(
    Canvas c,
    double radius, {
    required Color accent,
    required int appearance,
    required double seconds,
    required bool reducedMotion,
    required bool upper,
    required bool cleared,
    bool perfect = false,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = seconds.isFinite ? math.max(0.0, seconds) : 0.0;
    final variant = (appearance % 3 + 3) % 3;
    final sky = SkyPalette.at(time);
    // Lanterns burn brighter as the sky darkens toward twilight.
    final night = SkyPalette.regionWeight(time, 2);
    final flicker = reducedMotion ? 0.0 : math.sin(time * 2.4);
    final body = _mix(cleared ? _cleared(accent) : accent, sky.haze, .08);
    final flame = cleared
        ? _mix(SkyColors.cream, SkyColors.yellow, .45)
        : switch (variant) {
            1 => _mix(SkyColors.yellow, SkyColors.coral, .3),
            2 => _mix(SkyColors.yellow, SkyColors.mint, .25),
            _ => SkyColors.yellow,
          };
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius);

    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      radius,
      Paint()..shader = _paper(bounds, body, flame, night),
    );
    if (radius >= 8) {
      _glow(c, radius, flame, night, flicker);
      if (radius >= 12) _ribs(c, radius, body);
      _shade(c, bounds, body);
      _caps(c, radius, body, upper);
      if (radius >= 15) {
        _emblem(
          c,
          radius,
          variant,
          accent,
          cleared,
          perfect,
          reducedMotion ? 1 : .82 + .18 * math.sin(time * 3.1),
        );
      }
      _sheen(c, radius);
    }
    _edge(c, radius, body, cleared, perfect);
    c.restore();
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  /// Cleared tint: turn the hue part way toward mint in HSL, lift it slightly
  /// and add a touch of saturation, so complementary accents such as coral
  /// stay bright instead of going muddy the way an RGB mix would.
  static Color _cleared(Color accent) {
    final a = HSLColor.fromColor(accent);
    final mint = HSLColor.fromColor(SkyColors.mint);
    final turn = ((mint.hue - a.hue + 540) % 360) - 180;
    return a
        .withHue((a.hue + turn * .15 + 360) % 360)
        .withSaturation(math.min(1.0, a.saturation * 1.15))
        .withLightness(a.lightness + (mint.lightness - a.lightness) * .25)
        .toColor();
  }

  /// Paper lit from its centre: warm core, true accent midway, deeper edge.
  static Shader _paper(Rect bounds, Color body, Color flame, double night) {
    return RadialGradient(
      center: const Alignment(0, .05),
      radius: .98,
      colors: [
        _mix(_mix(body, SkyColors.cream, .5), flame, .3 + night * .12),
        _mix(body, SkyColors.cream, .2),
        body,
        _mix(body, SkyColors.ink, .22),
      ],
      stops: const [0, .42, .78, 1],
    ).createShader(bounds);
  }

  static void _glow(
    Canvas c,
    double radius,
    Color flame,
    double night,
    double flicker,
  ) {
    final glow = radius * (.6 + night * .08);
    c.drawCircle(
      Offset.zero,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            flame.withValues(alpha: .34 + night * .28 + flicker * .06),
            flame.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: glow)),
    );
  }

  /// Bamboo hoops silhouetted by the inner light.
  static void _ribs(Canvas c, double radius, Color body) {
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.1, radius * .032)
      ..color = _mix(body, SkyColors.ink, .45).withValues(alpha: .42);
    final crease = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, radius * .018)
      ..color = SkyColors.cream.withValues(alpha: .38);
    const steps = 6;
    for (var i = 1; i < steps; i++) {
      final t = _capAt * (2 * i / steps - 1);
      final y = radius * t;
      final half = radius * math.sqrt(math.max(0.0, 1 - t * t));
      final sag = half * _bow * t.abs();
      if (sag < .5) {
        c.drawLine(Offset(-half, y), Offset(half, y), rib);
        c.drawLine(
          Offset(-half * .7, y + rib.strokeWidth * 1.1),
          Offset(-half * .1, y + rib.strokeWidth * 1.1),
          crease,
        );
        continue;
      }
      final hoop = Rect.fromCenter(
        center: Offset(0, y),
        width: half * 2,
        height: sag * 2,
      );
      // Upper hoops show their top arc, lower hoops their bottom arc.
      final start = t < 0 ? math.pi : 0.0;
      c.drawArc(hoop, start, math.pi, false, rib);
      c.drawArc(
        hoop.shift(Offset(0, rib.strokeWidth * 1.1)),
        t < 0 ? math.pi * 1.18 : math.pi * .32,
        math.pi * .5,
        false,
        crease,
      );
    }
  }

  /// Soft terminator on the lower right so the paper reads as a sphere.
  static void _shade(Canvas c, Rect bounds, Color body) {
    final dark = _mix(body, SkyColors.ink, .6);
    c.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.38, -.42),
          radius: 1.34,
          colors: [
            dark.withValues(alpha: 0),
            dark.withValues(alpha: 0),
            dark.withValues(alpha: .26),
          ],
          stops: const [0, .6, 1],
        ).createShader(bounds),
    );
  }

  /// Lacquered bands at both poles, mirror images of each other. Their inner
  /// edge bows like the hoops so the band wraps the sphere.
  static void _caps(Canvas c, double radius, Color body, bool upper) {
    final y0 = radius * _capAt;
    final half = radius * math.sqrt(1 - _capAt * _capAt);
    final sag = half * _bow * _capAt;
    final light = _mix(body, SkyColors.ink, .36);
    final dark = _mix(body, SkyColors.ink, .64);
    final lacquer = Paint()
      ..shader = LinearGradient(
        colors: [light, _mix(light, dark, .45), dark],
        stops: const [.12, .5, 1],
      ).createShader(Rect.fromLTRB(-half, -radius, half, radius));
    final trim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, radius * .045)
      ..color = _mix(SkyColors.gold, SkyColors.yellow, .25);
    final tether = upper ? -1.0 : 1.0;
    final rim = math.max(radius * .07, 1.25);
    for (final side in const [-1.0, 1.0]) {
      final y = side * y0;
      final band = Rect.fromCenter(
        center: Offset(0, y),
        width: half * 2,
        height: sag * 2,
      );
      // The arc runs from the left end through the pole-side bulge.
      c.drawPath(
        Path()
          ..moveTo(-radius, y)
          ..lineTo(-half, y)
          ..arcTo(band, math.pi, -side * math.pi, false)
          ..lineTo(radius, y)
          ..lineTo(radius, side * radius)
          ..lineTo(-radius, side * radius)
          ..close(),
        lacquer,
      );
      if (radius < 12) continue;
      c.drawArc(band, side < 0 ? math.pi : 0, math.pi, false, trim);
      // Visible band thickness on the centre line, inside the rim.
      final inner = y0 + sag, outer = radius - rim;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-half * .42, side * (inner + outer) / 2),
          width: half * .4,
          height: math.max(1.0, (outer - inner) * .26),
        ),
        Paint()
          ..color = SkyColors.cream.withValues(alpha: side < 0 ? .45 : .26),
      );
      if (side != tether) continue;
      final eye = Offset(0, side * (inner + outer) / 2);
      c.drawCircle(
        eye,
        radius * .062,
        Paint()..color = _mix(SkyColors.gold, SkyColors.cream, .2),
      );
      c.drawCircle(eye, radius * .03, Paint()..color = SkyColors.ink);
    }
  }

  static void _emblem(
    Canvas c,
    double radius,
    int variant,
    Color accent,
    bool cleared,
    bool perfect,
    double starAlpha,
  ) {
    final s = radius * .31;
    final plate = cleared
        ? _mix(SkyColors.teal, SkyColors.ink, .12)
        : switch (variant) {
            1 => _mix(SkyColors.cream, SkyColors.yellow, .22),
            2 => _mix(SkyColors.cream, SkyColors.mint, .2),
            _ => SkyColors.cream,
          };
    c.drawCircle(
      Offset(s * .06, s * .1),
      s * 1.08,
      Paint()..color = SkyColors.ink.withValues(alpha: .16),
    );
    c.drawCircle(Offset.zero, s, Paint()..color = plate);
    // Once cleared, the plate becomes a dark seal for the shared cream star.
    if (!cleared) {
      switch (variant) {
        case 1:
          _blossom(c, s, accent);
        case 2:
          _bird(c, s);
        default:
          _moon(c, s, starAlpha);
      }
    }
    c.drawCircle(
      Offset.zero,
      s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, s * .14)
        ..color = SkyColors.gold,
    );
    if (perfect) {
      // A perfect pass rings the seal in bright yellow just outside the gold.
      final halo = math.max(1.2, s * .1);
      c.drawCircle(
        Offset.zero,
        s * 1.07 + halo / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = halo
          ..color = SkyColors.yellow,
      );
    }
    c.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: s * .8),
      math.pi * 1.1,
      math.pi * .45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.9, s * .08)
        ..color = SkyColors.white.withValues(alpha: cleared ? .3 : .7),
    );
  }

  static void _moon(Canvas c, double s, double starAlpha) {
    c.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(
          Rect.fromCircle(center: Offset(-s * .12, s * .04), radius: s * .56),
        )
        ..addOval(
          Rect.fromCircle(center: Offset(s * .14, -s * .04), radius: s * .46),
        ),
      Paint()..color = SkyColors.gold,
    );
    c.drawPath(
      _spark(Offset(s * .42, -s * .36), s * .22),
      Paint()..color = SkyColors.coral.withValues(alpha: starAlpha),
    );
  }

  static void _blossom(Canvas c, double s, Color accent) {
    final petal = Paint()..color = _mix(accent, SkyColors.coral, .35);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      c.drawCircle(
        Offset(math.cos(a) * s * .38, math.sin(a) * s * .38),
        s * .28,
        petal,
      );
    }
    c.drawCircle(Offset.zero, s * .22, Paint()..color = SkyColors.gold);
    c.drawCircle(Offset.zero, s * .1, Paint()..color = SkyColors.cream);
  }

  static void _bird(Canvas c, double s) {
    final ink = Paint()..color = SkyColors.ink;
    c.drawPath(
      Path()
        ..moveTo(-s * .76, -s * .02)
        ..lineTo(-s * .34, -s * .18)
        ..lineTo(-s * .34, s * .16)
        ..close(),
      ink,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s * .02, s * .05),
        width: s * .68,
        height: s * .4,
      ),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(-s * .04, 0)
        ..quadraticBezierTo(s * .02, -s * .8, s * .58, -s * .12)
        ..quadraticBezierTo(s * .12, -s * .08, -s * .02, s * .05)
        ..close(),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(s * .3, s * .02)
        ..lineTo(s * .72, s * .1)
        ..lineTo(s * .28, s * .16)
        ..close(),
      Paint()..color = SkyColors.coralDeep,
    );
  }

  static Path _spark(Offset o, double s) {
    return Path()
      ..moveTo(o.dx, o.dy - s)
      ..lineTo(o.dx + s * .36, o.dy - s * .36)
      ..lineTo(o.dx + s, o.dy)
      ..lineTo(o.dx + s * .36, o.dy + s * .36)
      ..lineTo(o.dx, o.dy + s)
      ..lineTo(o.dx - s * .36, o.dy + s * .36)
      ..lineTo(o.dx - s, o.dy)
      ..lineTo(o.dx - s * .36, o.dy - s * .36)
      ..close();
  }

  /// Paper sheen on the upper left, kept soft so it never reads as glass.
  static void _sheen(Canvas c, double radius) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .5, -radius * .3),
        width: radius * .2,
        height: radius * .42,
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .26),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .52, -radius * .36),
        width: radius * .09,
        height: radius * .16,
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .6),
    );
  }

  static void _edge(
    Canvas c,
    double radius,
    Color body,
    bool cleared,
    bool perfect,
  ) {
    final width = math.min(radius * .18, math.max(radius * .07, 1.25));
    c.drawCircle(
      Offset.zero,
      math.max(0.0, radius - width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = _mix(body, SkyColors.ink, .56),
    );
    if (radius < 10) return;
    final lip = math.min(width * .4, radius * .035);
    final lipAt = radius - width - lip / 2;
    if (lipAt <= 0) return;
    c.drawCircle(
      Offset.zero,
      lipAt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lip
        ..color = perfect
            ? SkyColors.yellow
            : (cleared ? SkyColors.mint : SkyColors.cream).withValues(
                alpha: cleared ? .95 : .6,
              ),
    );
  }
}
