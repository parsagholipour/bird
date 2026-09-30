import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'world_region.dart';

/// The burst that celebrates a perfect pass or a gate milestone, in the
/// region's own vocabulary: gold and faience sparkles in Egypt, glitching
/// pixel shards in Cyberpunk City, snowflakes in Antarctica, leaves in the jungle, blossom petals in China, ticker tape in
/// New York and bubbles at sea; feathers and jade in Aztec lands, gold stars
/// over Paris, confetti in Brazil, tile stars in Ancient Arabia, laurel
/// leaves in Rome and marigold petals in Mexico.
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
        case WorldRegion.cyberpunk:
          // A pixel block tearing like a bad signal: its magenta and cyan
          // ghosts split apart as it flies, and every third one trails a
          // torn scan line. Pixels stay square to the screen.
          const neon = [
            Color(0xff5ff4ff),
            Color(0xffff5fcf),
            Color(0xffd4ff5a),
            Color(0xfff4f0ff),
          ];
          c.rotate(-spin);
          final block = Rect.fromCenter(
            center: Offset.zero,
            width: size * 1.8,
            height: size * 1.8,
          );
          final split = size * (.25 + .7 * t);
          paint.color = Sketch.fade(const Color(0xffff3fb4), alpha * .85);
          c.drawRect(block.shift(Offset(-split, -split * .2)), paint);
          paint.color = Sketch.fade(const Color(0xff3fe8ff), alpha * .85);
          c.drawRect(block.shift(Offset(split, split * .2)), paint);
          final core = gold ? const Color(0xffffc93f) : neon[i % neon.length];
          paint.color = Sketch.fade(core, alpha);
          c.drawRect(block, paint);
          paint.color = Sketch.fade(const Color(0xffffffff), alpha * .8);
          c.drawRect(
            Rect.fromLTWH(
              block.left,
              block.top,
              block.width * .45,
              block.height * .45,
            ),
            paint,
          );
          if (i % 3 == 0) {
            paint.color = Sketch.fade(core, alpha * .6);
            c.drawRect(
              Rect.fromLTWH(
                -size * (1.8 + t),
                size * 1.2,
                size * (3 + t * 2),
                math.max(1.0, size * .3),
              ),
              paint,
            );
          }
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
        case WorldRegion.aztec:
          paint.color = Sketch.fade(
            gold || i % 3 == 0
                ? const Color(0xffffc93f)
                : (i.isOdd ? const Color(0xff2fb5a0) : const Color(0xffe0523a)),
            alpha,
          );
          c.scale(size * 1.2, size * .7);
          c.drawPath(_leaf, paint);
        case WorldRegion.paris:
          paint.color = Sketch.fade(
            gold ? const Color(0xffffc93f) : const Color(0xfffff0b8),
            alpha,
          );
          c.drawPath(
            Sketch.poly([
              0, -size * 1.3, size * .3, -size * .3, size * 1.3, 0, //
              size * .3, size * .3, 0, size * 1.3, -size * .3, size * .3,
              -size * 1.3, 0, -size * .3, -size * .3,
            ]),
            paint,
          );
        case WorldRegion.brazil:
          const confetti = [
            Color(0xffffdc2e),
            Color(0xff2fb85a),
            Color(0xff2f7de0),
            Color(0xfff6f1e2),
          ];
          paint.color = Sketch.fade(
            gold ? const Color(0xffffc93f) : confetti[i % confetti.length],
            alpha,
          );
          c.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: size * 1.5,
              height: size * .8,
            ),
            paint,
          );
        case WorldRegion.arabia:
          // Eight-point stars of two squares, in tile turquoise, cream
          // and gilt.
          paint.color = Sketch.fade(
            gold || i % 3 == 0
                ? const Color(0xffffc93f)
                : (i.isOdd ? const Color(0xff36d2c6) : const Color(0xfffff4dc)),
            alpha,
          );
          final square = Rect.fromCenter(
            center: Offset.zero,
            width: size * 1.45,
            height: size * 1.45,
          );
          c.drawRect(square, paint);
          c.rotate(math.pi / 4);
          c.drawRect(square, paint);
        case WorldRegion.rome:
          paint.color = Sketch.fade(
            gold ? const Color(0xffffd35a) : const Color(0xff7fa85a),
            alpha,
          );
          c.scale(size * 1.3, size * .7);
          c.drawPath(_leaf, paint);
        case WorldRegion.mexico:
          paint.color = Sketch.fade(
            gold
                ? const Color(0xffffc93f)
                : (i.isOdd ? const Color(0xfff7a21b) : const Color(0xffe6407a)),
            alpha,
          );
          c.drawCircle(Offset.zero, size * .9, paint);
          c.drawCircle(
            Offset.zero,
            size * .4,
            paint..color = Sketch.fade(const Color(0xfffff1b0), alpha * .8),
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
