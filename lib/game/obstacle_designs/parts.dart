import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';

/// The replay clock as one obstacle sees it: frozen in Reduced Motion.
class Motion {
  const Motion(this.seconds, this.reduced);
  final double seconds;
  final bool reduced;

  double get time => reduced || !seconds.isFinite ? 0 : seconds;

  /// A turning angle at [speed] radians per second from [rest].
  double spin(double speed, [double rest = 0]) =>
      Kit.spin(seconds, reduced, speed, rest);
}

typedef ColumnPainter =
    void Function(Canvas c, Column g, int v, PassState pass, Motion m);
typedef OrbPainter =
    void Function(
      Canvas c,
      double r,
      int v,
      bool upper,
      PassState pass,
      Motion m,
    );

/// Scaffolding and small drawing parts shared by the newer regional skins,
/// so each region only supplies its materials and motifs.
abstract final class Parts {
  /// Routes an obstacle family to a region's painters, inside the same
  /// clipped, edged frame every regional column uses.
  static void column(
    Canvas c,
    Rect r, {
    required ObstacleKind kind,
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
    required Color ink,
    required ColumnPainter garden,
    required ColumnPainter wind,
    required ColumnPainter petal,
    required ColumnPainter switchback,
    required ColumnPainter steps,
  }) {
    final g = Column(r, top);
    final v = (appearance % 3 + 3) % 3;
    final m = Motion(seconds, reducedMotion);
    c.save();
    c.clipRect(r);
    final paint = switch (kind) {
      ObstacleKind.windLift => wind,
      ObstacleKind.petalGate => petal,
      ObstacleKind.switchback => switchback,
      ObstacleKind.crystalSteps => steps,
      _ => garden,
    };
    paint(c, g, v, pass, m);
    Kit.edge(c, g, ink, pass);
    c.restore();
  }

  static void orb(
    Canvas c,
    double radius, {
    required ObstacleKind kind,
    required bool upper,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
    required OrbPainter lantern,
    required OrbPainter wheel,
  }) {
    final v = (appearance % 3 + 3) % 3;
    final m = Motion(seconds, reducedMotion);
    final paint = kind == ObstacleKind.lanternDrift ? lantern : wheel;
    paint(c, radius, v, upper, pass, m);
  }

  /// Opens a round obstacle: clips to the disc and shades it with a lit
  /// upper-left. Close it with [orbEnd].
  static void orbBegin(Canvas c, double r, Color lit, Color body, Color shade) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.35),
          colors: [lit, body, shade],
          stops: const [0, .55, 1],
        ).createShader(bounds),
    );
  }

  /// Ends [orbBegin] and draws the collision bezel over the clipped body.
  static void orbEnd(
    Canvas c,
    double r,
    Color metal,
    Color ink,
    PassState pass, {
    double band = .11,
  }) {
    c.restore();
    Kit.bezel(c, r, metal, ink, pass, band: band);
  }

  /// Horizontal bands of [colors] down the shaft from [from], each [thick]
  /// deep; [shift] slides the pattern along the shaft.
  static void stripes(
    Canvas c,
    Column g,
    double from,
    double thick,
    List<Color> colors, {
    double shift = 0,
  }) {
    if (!(thick > 0)) return;
    var i = 0;
    for (var d = from - (shift % (thick * colors.length)); d < g.h; d += thick) {
      Kit.fill(c, g.band(d, d + thick), colors[i % colors.length]);
      i++;
    }
  }

  /// Stone courses with joints and staggered seams, from [from] down.
  static void courses(
    Canvas c,
    Column g,
    double from,
    double course,
    Color joint,
    Color lit,
    Color under,
  ) {
    var row = 0;
    for (var d = from; d < g.h; d += course, row++) {
      Kit.fill(c, g.band(d, d + 1.2), joint);
      Kit.fill(c, g.band(d + 1.2, d + 2.6), lit);
      Kit.fill(c, g.band(d + course - 2, d + course), under);
      final seam = g.r.left + g.w * (row.isOdd ? .35 : .68);
      Kit.fill(c, g.band(d, d + course, seam, seam + 1.2), joint);
    }
  }

  /// A crossing lattice of diagonal lines over the shaft from [from].
  static void lattice(
    Canvas c,
    Column g,
    double from,
    double cell,
    Color color, {
    double width = 1.2,
  }) {
    if (!(cell > 2) || g.h - from < cell) return;
    final pen = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (var d = from; d < g.h; d += cell) {
      for (var x = g.r.left; x < g.r.right; x += cell) {
        final cx = x + cell / 2;
        final y0 = g.y(d), y1 = g.y(d + cell);
        c.drawLine(Offset(x, y0), Offset(cx + cell / 2, y1), pen);
        c.drawLine(Offset(cx + cell / 2, y0), Offset(x, y1), pen);
      }
    }
  }

  /// A rimmed wheel of [spokes] spokes turning about [hub].
  static void wheel(
    Canvas c,
    Offset hub,
    double r,
    double spin,
    int spokes,
    Color rim,
    Color spoke,
  ) {
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    final pen = Paint()
      ..strokeWidth = math.max(1.4, r * .1)
      ..strokeCap = StrokeCap.round
      ..color = spoke;
    for (var i = 0; i < spokes; i++) {
      final a = i * math.pi * 2 / spokes;
      c.drawLine(Offset.zero, Offset(math.cos(a), math.sin(a)) * r * .9, pen);
    }
    c.drawCircle(
      Offset.zero,
      r * .9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, r * .14)
        ..color = rim,
    );
    c.drawCircle(Offset.zero, r * .14, Paint()..color = rim);
    c.restore();
  }

  /// A round-headed opening [w] wide and [h] tall on the shaft at [d] from
  /// the rim, facing into the flight lane.
  static void niche(
    Canvas c,
    Column g,
    double d,
    double w,
    double h,
    Color color, {
    double? cx,
  }) {
    if (!(w > 2) || !(h > 2)) return;
    final base = g.y(d + h);
    final r = Rect.fromLTWH(
      (cx ?? g.cx) - w / 2,
      math.min(base, g.y(d)),
      w,
      h,
    );
    c.drawPath(
      Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + w / 2)
        ..arcToPoint(
          Offset(r.right, r.top + w / 2),
          radius: Radius.circular(w / 2),
          clockwise: true,
        )
        ..lineTo(r.right, r.bottom)
        ..close(),
      Paint()..color = color,
    );
  }

  /// A cleared shaft shows its region's seal.
  static void seal(
    Canvas c,
    Column g,
    WorldRegion region,
    double d,
    double s,
    PassState pass,
  ) {
    if (!pass.cleared || s < 2) return;
    Kit.emblem(c, region, Offset(g.cx, g.y(d)), s, perfect: pass.perfect);
  }
}
