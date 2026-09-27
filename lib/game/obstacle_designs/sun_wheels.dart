import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Raised sun medallion clipped to the circular collision body: a dark-lined
/// bezel marks the solid edge while a folded-paper rotor turns inside it.
abstract final class SunWheelsDesign {
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
    final variant = _variant(appearance);
    final sky = SkyPalette.at(time);
    final tone = cleared ? _cleared(accent) : accent;
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius);

    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      radius,
      Paint()..shader = _face(bounds, tone, sky),
    );
    if (radius >= 8) {
      if (radius >= 14) _dial(c, radius, variant, tone);
      _rotor(c, radius, variant, tone, time, reducedMotion, upper);
      _shade(c, bounds);
      _hub(c, radius, variant, tone, time, reducedMotion, cleared, perfect);
    }
    _bezel(c, radius, variant, tone, perfect);
    c.restore();
  }

  static int _variant(int appearance) {
    final raw = appearance % 3;
    return raw < 0 ? raw + 3 : raw;
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

  /// Warm dial face. It stays lighter than the bezel so the ring reads as the
  /// raised, solid edge against pale day skies and dark night skies alike.
  static Shader _face(Rect bounds, Color tone, SkyPalette sky) {
    return RadialGradient(
      center: const Alignment(-.28, -.34),
      radius: .95,
      colors: [
        SkyColors.cream,
        _mix(_mix(SkyColors.cream, sky.haze, .3), tone, .12),
        _mix(SkyColors.cream, tone, .42),
      ],
      stops: const [0, .42, 1],
    ).createShader(bounds);
  }

  /// Faint engraved rings on the dial, drawn beneath the rotor.
  static void _dial(Canvas c, double radius, int variant, Color tone) {
    final ink = _mix(tone, SkyColors.ink, .3).withValues(alpha: .3);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(1.2, math.max(.6, radius * .02))
      ..color = ink;
    c.drawCircle(Offset.zero, radius * .6, line);
    if (variant != 1) return;
    // The cog variant gets a dotted timing track between its teeth.
    final dot = Paint()..color = ink;
    for (var i = 0; i < 12; i++) {
      final angle = (i + .5) * math.pi / 6;
      c.drawCircle(
        Offset(math.cos(angle), math.sin(angle)) * radius * .7,
        math.max(.6, radius * .018),
        dot,
      );
    }
  }

  static void _rotor(
    Canvas c,
    double radius,
    int variant,
    Color tone,
    double time,
    bool reducedMotion,
    bool upper,
  ) {
    final count = const [8, 6, 5][variant];
    final fill = switch (variant) {
      1 => _mix(tone, SkyColors.cream, .08),
      2 => _mix(tone, SkyColors.cream, .12),
      _ => _mix(tone, SkyColors.yellow, .3),
    };
    final fold = Paint()..color = _mix(fill, SkyColors.ink, .2);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(2.4, math.max(.8, radius * .036))
      ..strokeJoin = StrokeJoin.round
      ..color = _mix(tone, SkyColors.ink, .55);
    final body = Paint()..color = fill;
    final crease = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(1.4, math.max(.55, radius * .024))
      ..strokeCap = StrokeCap.round
      ..color = SkyColors.cream.withValues(alpha: .85);
    final blade = _blade(radius, variant);
    final half = Rect.fromLTRB(0, 0, radius, radius);
    c.save();
    c.rotate(_spin(time, reducedMotion, upper, count));
    for (var i = 0; i < count; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / count);
      c.drawPath(blade, line);
      c.drawPath(blade, body);
      // One side of every blade is folded into shade, like a paper pinwheel,
      // which gives the rotor volume without a light that spins with it.
      c.save();
      c.clipRect(half);
      c.drawPath(blade, fold);
      c.restore();
      if (radius >= 12) {
        c.drawLine(
          Offset(radius * .38, -radius * .012),
          Offset(radius * (variant == 1 ? .66 : .68), -radius * .012),
          crease,
        );
      }
      c.restore();
    }
    c.restore();
  }

  static double _spin(double time, bool reducedMotion, bool upper, int count) {
    final rest = upper ? 0.0 : math.pi / count;
    if (reducedMotion || time == 0) return rest;
    const speed = .42;
    final period = math.pi * 2 / speed;
    final turn = (time % period) * speed;
    return upper ? rest + turn : rest - turn;
  }

  static final _blades = <int, (double, Path)>{};

  /// Blade outlines only depend on the orb size, which is fixed per viewport.
  static Path _blade(double radius, int variant) {
    final cached = _blades[variant];
    if (cached != null && cached.$1 == radius) return cached.$2;
    final path = switch (variant) {
      1 => _tooth(radius),
      2 => _petal(radius),
      _ => _ray(radius),
    };
    _blades[variant] = (radius, path);
    return path;
  }

  static Path _ray(double r) => Path()
    ..moveTo(r * .26, -r * .07)
    ..quadraticBezierTo(r * .52, -r * .12, r * .82, 0)
    ..quadraticBezierTo(r * .52, r * .12, r * .26, r * .07)
    ..close();

  static Path _tooth(double r) {
    final inner = r * .26, outer = r * .76, root = r * .09, tip = r * .12;
    final round = r * .05;
    return Path()
      ..moveTo(inner, -root)
      ..lineTo(outer - round, -tip)
      ..quadraticBezierTo(outer, -tip, outer, -tip + round)
      ..lineTo(outer, tip - round)
      ..quadraticBezierTo(outer, tip, outer - round, tip)
      ..lineTo(inner, root)
      ..close();
  }

  static Path _petal(double r) => Path()
    ..moveTo(r * .26, -r * .06)
    ..cubicTo(r * .42, -r * .21, r * .7, -r * .17, r * .81, -r * .02)
    ..cubicTo(r * .7, r * .1, r * .44, r * .15, r * .26, r * .06)
    ..close();

  /// Static volume over the turning rotor: a soft terminator toward the
  /// lower right and a glaze toward the upper left.
  static void _shade(Canvas c, Rect bounds) {
    final radius = bounds.width / 2;
    c.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.34, -.4),
          radius: 1.1,
          colors: [
            SkyColors.ink.withValues(alpha: 0),
            SkyColors.ink.withValues(alpha: 0),
            SkyColors.ink.withValues(alpha: .16),
          ],
          stops: const [0, .6, 1],
        ).createShader(bounds),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * .34, -radius * .42),
        width: radius * .5,
        height: radius * .26,
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .22),
    );
  }

  static void _hub(
    Canvas c,
    double radius,
    int variant,
    Color tone,
    double time,
    bool reducedMotion,
    bool cleared,
    bool perfect,
  ) {
    final plate = radius * .32;
    final brass = perfect
        ? SkyColors.gold
        : _mix(SkyColors.gold, SkyColors.ink, .4);
    c.drawCircle(
      Offset(radius * .02, radius * .035),
      plate,
      Paint()..color = SkyColors.ink.withValues(alpha: .18),
    );
    c.drawCircle(
      Offset.zero,
      plate,
      Paint()..color = _mix(SkyColors.sand, SkyColors.cream, .5),
    );
    c.drawCircle(
      Offset.zero,
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(2.0, math.max(.7, radius * .036))
        ..color = brass,
    );
    if (radius >= 16) _balls(c, radius);
    if (cleared) {
      // A deep mint seat so the cream star painted over the orb stays legible.
      c.drawCircle(
        Offset.zero,
        radius * .23,
        Paint()..color = _mix(SkyColors.teal, SkyColors.ink, .3),
      );
      return;
    }
    _jewel(c, radius, variant, tone, time, reducedMotion);
  }

  static void _balls(Canvas c, double radius) {
    final orbit = radius * .255;
    final ball = radius * .04;
    final metal = _mix(SkyColors.sand, SkyColors.ink, .28);
    final shine = Paint()..color = SkyColors.cream;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      final at = Offset(math.cos(angle) * orbit, math.sin(angle) * orbit);
      c.drawCircle(at, ball, Paint()..color = metal);
      c.drawCircle(at + Offset(-ball * .3, -ball * .3), ball * .38, shine);
    }
  }

  static void _jewel(
    Canvas c,
    double radius,
    int variant,
    Color tone,
    double time,
    bool reducedMotion,
  ) {
    final size = radius * (variant == 2 ? .15 : .14);
    if (size < .4) return;
    final shape = switch (variant) {
      1 => _ngon(6, size, -math.pi / 2),
      2 => _ngon(4, size, -math.pi / 2),
      _ => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: size)),
    };
    c.drawCircle(
      Offset.zero,
      size * 1.34,
      Paint()..color = _mix(SkyColors.ink, tone, .22),
    );
    c.drawPath(shape, Paint()..color = _mix(tone, SkyColors.yellow, .45));
    final gleam = reducedMotion ? .7 : _pulse(time);
    c.save();
    c.clipPath(shape);
    c.drawCircle(
      Offset(size * .34, size * .38),
      size * .78,
      Paint()..color = _mix(tone, SkyColors.ink, .3).withValues(alpha: .55),
    );
    c.drawCircle(
      Offset(-size * .3, -size * .34),
      size * .26,
      Paint()..color = SkyColors.white.withValues(alpha: gleam),
    );
    c.restore();
  }

  static double _pulse(double time) {
    const period = math.pi * 2 / 2.15;
    final local = (time % period) * 2.15;
    return .5 + .35 * (math.sin(local) * .5 + .5);
  }

  static Path _ngon(int sides, double radius, double turn) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = turn + i * math.pi * 2 / sides;
      final x = math.cos(angle) * radius, y = math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  /// The collision edge: a saturated bezel band with a crisp ink outline, a
  /// cream inner lip, lit and shaded arcs, and evenly spaced studs.
  static void _bezel(
    Canvas c,
    double radius,
    int variant,
    Color tone,
    bool perfect,
  ) {
    final outline = math.min(3.4, math.max(1.3, radius * .045));
    final band = math.min(radius * .3, math.max(radius * .15, 2.2));
    final bandAt = radius - band / 2;
    c.drawCircle(
      Offset.zero,
      math.max(0.0, bandAt),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = band
        ..color = _mix(tone, SkyColors.ink, .12),
    );
    if (radius >= 10) {
      final arc = Rect.fromCircle(
        center: Offset.zero,
        radius: radius - outline - (band - outline) / 2,
      );
      final width = (band - outline) * .45;
      c.drawArc(
        arc,
        math.pi * .8,
        math.pi * .95,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = SkyColors.cream.withValues(alpha: .38),
      );
      c.drawArc(
        arc,
        -math.pi * .15,
        math.pi * .8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = SkyColors.ink.withValues(alpha: .16),
      );
    }
    if (radius >= 18) _studs(c, radius, band, outline, variant, tone);
    final lip = math.min(1.6, math.max(.6, radius * .022));
    final lipAt = radius - band - lip / 2;
    if (lipAt > 0) {
      c.drawCircle(
        Offset.zero,
        lipAt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lip
          ..color = _mix(tone, SkyColors.ink, .5),
      );
      c.drawCircle(
        Offset.zero,
        lipAt - lip,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = perfect ? lip * 1.6 : lip
          // A perfect pass lights the inner lip in yellow, like a gilt bezel.
          ..color = perfect
              ? SkyColors.yellow
              : SkyColors.cream.withValues(alpha: .8),
      );
    }
    c.drawCircle(
      Offset.zero,
      math.max(0.0, radius - outline / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline
        ..color = _mix(tone, SkyColors.ink, .62),
    );
  }

  static void _studs(
    Canvas c,
    double radius,
    double band,
    double outline,
    int variant,
    Color tone,
  ) {
    final count = const [12, 12, 10][variant];
    final at = radius - outline / 2 - band / 2;
    final size = math.min(band * .2, radius * .032);
    final base = Paint()..color = _mix(tone, SkyColors.ink, .38);
    final shine = Paint()..color = _mix(SkyColors.cream, tone, .2);
    for (var i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count;
      final p = Offset(math.cos(angle), math.sin(angle)) * at;
      c.drawCircle(p, size, base);
      c.drawCircle(p + Offset(-size, -size) * .3, size * .5, shine);
    }
  }
}
