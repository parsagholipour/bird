import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';

/// Landmark drawing shared by the newer region painters.
abstract final class Scenery {
  /// [c] blended toward the region's [haze] by [t], so distance reads.
  static Color hazed(Color c, Color haze, double t) => Sketch.mix(c, haze, t);

  /// A grid of small windows over [r]; [litChance] of them glow.
  static void windows(
    Canvas c,
    Rect r, {
    required int cols,
    required int rows,
    required Color lit,
    required Color dark,
    int seed = 0,
    double litChance = .5,
  }) {
    if (!(r.width > 0) || !(r.height > 0) || cols < 1 || rows < 1) return;
    final cw = r.width / cols, rh = r.height / rows;
    final on = Paint()..color = lit, off = Paint()..color = dark;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final glow = Sketch.hash(seed * 131 + y * 17 + x) < litChance;
        c.drawRect(
          Rect.fromLTWH(
            r.left + x * cw + cw * .25,
            r.top + y * rh + rh * .25,
            cw * .5,
            rh * .5,
          ),
          glow ? on : off,
        );
      }
    }
  }

  /// A row of [n] round-headed openings filling [r].
  static void arches(Canvas c, Rect r, int n, Color color) {
    if (!(r.width > 0) || !(r.height > 0) || n < 1) return;
    final w = r.width / n;
    final paint = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final x = r.left + i * w + w * .2, aw = w * .6;
      final spring = math.min(r.top + aw / 2, r.bottom);
      c.drawPath(
        Path()
          ..moveTo(x, r.bottom)
          ..lineTo(x, spring)
          ..arcToPoint(
            Offset(x + aw, spring),
            radius: Radius.circular(aw / 2),
            clockwise: true,
          )
          ..lineTo(x + aw, r.bottom)
          ..close(),
        paint,
      );
    }
  }

  /// A round-crowned tree on a short trunk, [s] tall.
  static void tree(
    Canvas c,
    Offset base,
    double s,
    Color trunk,
    Color crown,
    Color crownLit,
  ) {
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .035, base.dy - s * .5, base.dx + s * .035, base.dy),
      Paint()..color = trunk,
    );
    c.drawCircle(
      Offset(base.dx, base.dy - s * .68),
      s * .32,
      Paint()..color = crown,
    );
    c.drawCircle(
      Offset(base.dx - s * .1, base.dy - s * .75),
      s * .2,
      Paint()..color = crownLit,
    );
  }

  /// A tall, narrow cypress, [s] tall.
  static void cypress(Canvas c, Offset base, double s, Color body, Color lit) {
    final path = Path()
      ..moveTo(base.dx, base.dy - s)
      ..quadraticBezierTo(base.dx + s * .2, base.dy - s * .5, base.dx + s * .08, base.dy)
      ..lineTo(base.dx - s * .08, base.dy)
      ..quadraticBezierTo(base.dx - s * .2, base.dy - s * .5, base.dx, base.dy - s)
      ..close();
    c.drawPath(path, Paint()..color = body);
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - s)
        ..quadraticBezierTo(base.dx - s * .2, base.dy - s * .5, base.dx - s * .08, base.dy)
        ..lineTo(base.dx - s * .01, base.dy)
        ..quadraticBezierTo(base.dx - s * .06, base.dy - s * .5, base.dx, base.dy - s)
        ..close(),
      Paint()..color = lit,
    );
  }

  /// A saguaro-style cactus with two raised arms, [s] tall.
  static void cactus(Canvas c, Offset base, double s, Color body, Color lit) {
    final paint = Paint()..color = body;
    final w = s * .16;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(base.dx - w / 2, base.dy - s, base.dx + w / 2, base.dy),
        Radius.circular(w / 2),
      ),
      paint,
    );
    for (final side in const [-1.0, 1.0]) {
      final y = base.dy - s * (side < 0 ? .5 : .62);
      final x = base.dx + side * s * .2;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            math.min(base.dx, x) - w * .35,
            y - w * .5,
            math.max(base.dx, x) + w * .35,
            y + w * .5,
          ),
          Radius.circular(w * .4),
        ),
        paint,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - w * .38, y - s * .28, x + w * .38, y + w * .5),
          Radius.circular(w * .4),
        ),
        paint,
      );
    }
    c.drawRect(
      Rect.fromLTRB(base.dx - w * .32, base.dy - s * .96, base.dx - w * .1, base.dy),
      Paint()..color = lit,
    );
  }

  /// A fan of pointed leaves, [s] tall: agave, yucca or a low palm clump.
  static void agave(Canvas c, Offset base, double s, Color body, Color lit) {
    for (var i = -3; i <= 3; i++) {
      final a = -math.pi / 2 + i * .34;
      final len = s * (1 - i.abs() * .1);
      final tip = base + Offset(math.cos(a), math.sin(a)) * len;
      final side = Offset(-math.sin(a), math.cos(a)) * s * .07;
      c.drawPath(
        Path()
          ..moveTo(base.dx - side.dx, base.dy - side.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(base.dx + side.dx, base.dy + side.dy)
          ..close(),
        Paint()..color = i.isOdd ? lit : body,
      );
    }
  }

  /// A pointed dome on a drum, the bones of a church, mosque or temple.
  static void dome(
    Canvas c,
    Offset base,
    double halfWidth,
    double height,
    Color body,
    Color lit,
  ) {
    final path = Path()
      ..moveTo(base.dx - halfWidth, base.dy)
      ..cubicTo(
        base.dx - halfWidth,
        base.dy - height * .75,
        base.dx - halfWidth * .3,
        base.dy - height * .85,
        base.dx,
        base.dy - height,
      )
      ..cubicTo(
        base.dx + halfWidth * .3,
        base.dy - height * .85,
        base.dx + halfWidth,
        base.dy - height * .75,
        base.dx + halfWidth,
        base.dy,
      )
      ..close();
    c.drawPath(path, Paint()..color = body);
    c.drawPath(
      Path()
        ..moveTo(base.dx - halfWidth, base.dy)
        ..cubicTo(
          base.dx - halfWidth,
          base.dy - height * .75,
          base.dx - halfWidth * .3,
          base.dy - height * .85,
          base.dx,
          base.dy - height,
        )
        ..cubicTo(
          base.dx - halfWidth * .3,
          base.dy - height * .5,
          base.dx - halfWidth * .5,
          base.dy - height * .2,
          base.dx - halfWidth * .45,
          base.dy,
        )
        ..close(),
      Paint()..color = lit,
    );
  }
}
