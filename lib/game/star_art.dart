import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../ui/theme.dart';

/// The collectible star and its smaller relatives. The star is inked and
/// shaded like the birds: a chubby soft-cornered silhouette, a gold
/// underside, a gloss stroke and a warm glow. Its idle life (a slow sway, a
/// breath and a glint every few seconds) follows only the replayable clock.
abstract final class StarArt {
  /// Outer point radius of an in-flight star, in viewport heights. Rounded
  /// points reach less far than sharp ones, so this sits a little above
  /// `SkyStar.radius` to keep the pickup's familiar footprint.
  static const radius = .032;

  /// Glow radius as a multiple of the point radius.
  static const glowScale = 1.8;

  /// How far a star's art reaches from its center, in viewport heights.
  static const reach = radius * glowScale;

  /// Inner-to-outer radius ratio of the rounded silhouette.
  static const inner = .54;

  /// Seconds between glints on one star.
  static const glintPeriod = 3.2;

  static const _light = Color(0xffffe68a);
  static const _outline = .105;

  /// A rounded five-point star. [tip] and [valley] are the fractions of an
  /// edge spent rounding the points and the notches between them; [puff]
  /// bows each edge outward as a fraction of its length.
  static Path path(
    Offset center,
    double radius, {
    double rotation = -math.pi / 2,
    double inner = StarArt.inner,
    double tip = .32,
    double valley = .22,
    double puff = .025,
  }) {
    final points = [
      for (var i = 0; i < 10; i++)
        center +
            Offset(
                  math.cos(rotation + i * math.pi / 5),
                  math.sin(rotation + i * math.pi / 5),
                ) *
                radius *
                (i.isEven ? 1 : inner),
    ];
    final edge = (points[1] - points[0]).distance;
    Offset toward(Offset from, Offset to, double d) =>
        from + (to - from) / (to - from).distance * d;
    double round(int i) => edge * (i.isEven ? tip : valley);
    final path = Path();
    final first = toward(points[0], points[9], round(0));
    path.moveTo(first.dx, first.dy);
    for (var i = 0; i < 10; i++) {
      final v = points[i], next = points[(i + 1) % 10];
      final leave = toward(v, next, round(i));
      path.quadraticBezierTo(v.dx, v.dy, leave.dx, leave.dy);
      // Each straight run bows gently outward, away from the center.
      final arrive = toward(next, v, round(i + 1));
      final mid = (leave + arrive) / 2;
      final out = mid - center;
      final bow = mid + out / out.distance * edge * puff;
      path.quadraticBezierTo(bow.dx, bow.dy, arrive.dx, arrive.dy);
    }
    return path..close();
  }

  // Unit geometry and paints, built once and placed with the canvas
  // transform so a frame full of stars allocates nothing new.
  static final Path _body = path(Offset.zero, 1);
  static final Path _lit = Path.combine(
    PathOperation.intersect,
    _body,
    _body.shift(const Offset(-.07, -.22)),
  );
  static final Path _gloss = Path()
    ..moveTo(-.42, -.2)
    ..quadraticBezierTo(-.2, -.26, -.1, -.52);
  static final Path _twinkle = () {
    final p = Path()..moveTo(0, -1);
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      p.quadraticBezierTo(
        math.cos(a + math.pi / 4) * .16,
        math.sin(a + math.pi / 4) * .16,
        math.cos(a + math.pi / 2),
        math.sin(a + math.pi / 2),
      );
    }
    return p..close();
  }();
  static final Paint _gold = Paint()..color = SkyColors.gold;
  static final Paint _litPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment(0, -1),
      end: Alignment(0, .6),
      colors: [_light, SkyColors.yellow],
    ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));
  static final Paint _glossPaint = Paint()
    ..color = SkyColors.white.withValues(alpha: .9)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .15
    ..strokeCap = StrokeCap.round;
  static final Paint _ink = Paint()
    ..color = SkyColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = _outline
    ..strokeJoin = StrokeJoin.round;
  static final Paint _white = Paint()..color = SkyColors.white;
  static final Paint _glow = _glowPaint(1);

  // Added light only ever brightens, so the glow warms dark skies without
  // greying them and becomes a soft bloom on bright ones. Plus is a plain
  // pipeline blend, cheap enough for a screen full of stars.
  static Paint _glowPaint(double alpha) => Paint()
    ..blendMode = BlendMode.plus
    ..shader = RadialGradient(
      colors: [
        _light.withValues(alpha: .55 * alpha),
        SkyColors.gold.withValues(alpha: .28 * alpha),
        SkyColors.gold.withValues(alpha: 0),
      ],
      stops: const [.3, .62, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));

  /// The full collectible at [center]. [radius] is the outer point radius;
  /// [phase] staggers idle motion between neighbouring stars. Without
  /// [seconds], or in Reduced Motion, the star holds its upright resting pose
  /// with no glint.
  static void paint(
    Canvas canvas,
    Offset center,
    double radius, {
    double? seconds,
    bool reducedMotion = false,
    double phase = 0,
    double opacity = 1,
    bool glow = true,
    double rotation = 0,
  }) {
    if (!(radius > 0) || opacity <= 0) return;
    final t = reducedMotion ? null : seconds;
    final sway = t == null ? 0.0 : math.sin(t * 1.7 + phase * 2.3);
    final breath = t == null ? 0.0 : math.sin(t * 3.1 + phase * 1.7);
    if (glow) {
      final alpha = math.min(opacity, 1.0);
      final r = radius * (glowScale - .08 + breath * .08);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(r);
      canvas.drawCircle(Offset.zero, 1, alpha < 1 ? _glowPaint(alpha) : _glow);
      canvas.restore();
    }
    _star(
      canvas,
      center,
      radius * (1 + breath * .025),
      opacity: opacity,
      rotation: rotation + sway * .09,
      glint: t == null ? -1 : (t + phase * 1.3) % glintPeriod,
    );
  }

  /// A small star for markers, emblems and orbiting sparkles: the
  /// collectible's inked, gold-bottomed body without its glow or idle life.
  /// [outline] sets the ink width in canvas units, to match surrounding art.
  static void mini(
    Canvas canvas,
    Offset center,
    double radius, {
    double opacity = 1,
    double rotation = 0,
    double? outline,
  }) {
    if (!(radius > 0) || opacity <= 0) return;
    _star(
      canvas,
      center,
      radius,
      opacity: opacity,
      rotation: rotation,
      ink: outline == null
          ? _ink
          : (Paint()
              ..color = SkyColors.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = outline / radius
              ..strokeJoin = StrokeJoin.round),
    );
  }

  /// A flat rounded star in one colour, for bursts too small to shade.
  static void sparkle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double rotation = 0,
  }) {
    if (!(radius > 0)) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(radius);
    canvas.drawPath(_body, Paint()..color = color);
    canvas.restore();
  }

  static void _star(
    Canvas canvas,
    Offset center,
    double radius, {
    required double opacity,
    required double rotation,
    double glint = -1,
    Paint? ink,
  }) {
    // Tiny stars skip the gloss and the glint, which would only be noise.
    final detailed = radius > 5;
    if (!detailed) glint = -1;
    final alpha = math.min(opacity, 1.0);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (alpha < 1) {
      // One short-lived layer keeps the shading from showing through itself
      // while a star fades.
      canvas.saveLayer(
        Rect.fromCircle(center: Offset.zero, radius: radius * 1.35),
        Paint()..color = SkyColors.white.withValues(alpha: alpha),
      );
    }
    canvas.rotate(rotation);
    canvas.scale(radius);
    canvas.drawPath(_body, _gold);
    canvas.drawPath(_lit, _litPaint);
    if (glint >= 0 && glint < .45) {
      // A band of light sweeps across the body, lower left to upper right.
      final u = glint / .45;
      canvas.save();
      canvas.clipPath(_body);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(0, 1.3 - u * 2.6),
          width: 3,
          height: .34,
        ),
        Paint()
          ..color = SkyColors.white.withValues(
            alpha: .55 * math.sin(u * math.pi),
          ),
      );
      canvas.restore();
    }
    if (detailed) canvas.drawPath(_gloss, _glossPaint);
    canvas.drawPath(_body, ink ?? _ink);
    if (glint >= .3 && glint < .8) {
      // The sweep ends in a four-point twinkle beside the upper-right point.
      final u = (glint - .3) / .5;
      canvas.save();
      canvas.translate(.82, -.86);
      canvas.rotate(u * .6);
      canvas.scale(.42 * math.sin(u * math.pi));
      canvas.drawPath(_twinkle, _white);
      canvas.restore();
    }
    if (alpha < 1) canvas.restore();
    canvas.restore();
  }
}
