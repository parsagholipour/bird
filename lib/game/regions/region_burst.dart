import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'world_region.dart';

/// The burst that celebrates a perfect pass or a gate milestone, in the
/// region's own vocabulary: gold and faience sparkles in Egypt, snowflakes in
/// Antarctica, leaves in the jungle, blossom petals in China, ticker tape in
/// New York and bubbles at sea.
abstract final class RegionBurst {
  static final _leaf = Path()
    ..moveTo(-1, 0)
    ..quadraticBezierTo(-.2, -.62, 1, 0)
    ..quadraticBezierTo(-.2, .62, -1, 0)
    ..close();

  /// [t] runs 0..1 over the burst's life; [alpha] fades it out.
  static void paint(
    Canvas c,
    WorldRegion region,
    Offset center,
    double h, {
    required double t,
    required double alpha,
    required bool perfect,
  }) {
    if (alpha <= 0) return;
    final paint = Paint()..strokeCap = StrokeCap.round;
    const count = 10;
    for (var i = 0; i < count; i++) {
      final a = i * math.pi * 2 / count + .3;
      final spread = h * (.05 + t * (.12 + .03 * (i % 3)));
      // Motes drift outward and settle a little, as if carried by air.
      final at =
          center +
          Offset(math.cos(a), math.sin(a)) * spread +
          Offset(0, t * t * h * .03);
      final size = h * .011 * (1 - t * .6);
      final spin = a + t * 5 * (i.isEven ? 1 : -1);
      final gold = perfect && i.isEven;
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(spin);
      switch (region) {
        case WorldRegion.egypt:
          paint.color = Sketch.fade(
            gold || i % 3 == 0
                ? const Color(0xffffc93f)
                : const Color(0xff49c1c4),
            alpha,
          );
          c.drawPath(
            Sketch.poly([0, -size, size * .6, 0, 0, size, -size * .6, 0]),
            paint,
          );
        case WorldRegion.antarctica:
          paint
            ..color = Sketch.fade(
              gold ? const Color(0xffffe08a) : const Color(0xfff2fbff),
              alpha,
            )
            ..strokeWidth = math.max(1.0, size * .28);
          for (var k = 0; k < 3; k++) {
            final d =
                Offset(math.cos(k * math.pi / 3), math.sin(k * math.pi / 3)) *
                size;
            c.drawLine(-d, d, paint);
          }
        case WorldRegion.jungle:
          paint.color = Sketch.fade(
            gold
                ? const Color(0xfff6c94a)
                : (i.isOdd ? const Color(0xff6fbf5a) : const Color(0xfff25f6b)),
            alpha,
          );
          c.scale(size * 1.2, size * .8);
          c.drawPath(_leaf, paint);
        case WorldRegion.china:
          paint.color = Sketch.fade(
            gold
                ? const Color(0xffffd35a)
                : (i.isOdd ? const Color(0xfff7b8c6) : const Color(0xffffe6ec)),
            alpha,
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: size * 1.8,
              height: size * 1.1,
            ),
            paint,
          );
        case WorldRegion.newYork:
          const tape = [
            Color(0xffffd46b),
            Color(0xfff27a8a),
            Color(0xff7fd0f0),
            Color(0xfff6f1e2),
          ];
          paint.color = Sketch.fade(
            gold ? const Color(0xffffc93f) : tape[i % tape.length],
            alpha,
          );
          c.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: size * .7,
              height: size * 2,
            ),
            paint,
          );
        case WorldRegion.sea:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, size * .22)
            ..color = Sketch.fade(
              gold ? const Color(0xffffd35a) : const Color(0xfff2fbff),
              alpha,
            );
          c.drawCircle(Offset.zero, size * .8, paint);
          paint.style = PaintingStyle.fill;
          c.drawCircle(Offset(-size * .25, -size * .25), size * .2, paint);
      }
      c.restore();
    }
  }
}
