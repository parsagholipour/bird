import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Opaque quartz, amethyst, and peridot prisms clipped to one solid column.
///
/// Each column reads as a three-faced crystal: a lit left face, a clear
/// centre face, and a shaded right face. The rim end is cut into a bright
/// faceted table above a dark girdle, so the collision edge always pops.
/// Appearance picks the growth seams: chevrons, slants, or gold-flecked bands.
abstract final class CrystalStepsDesign {
  static void paint(
    Canvas c,
    Rect r, {
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
    required bool perfect,
    required int appearance,
    required Color accent,
  }) {
    if (!r.isFinite || r.isEmpty) return;
    final clock = seconds.isFinite ? seconds : 0.0;
    final sky = SkyPalette.at(clock);
    final v = (appearance % 3 + 3) % 3;
    final w = r.width;
    final h = r.height;

    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

    var mineral = mix(
      accent,
      const [SkyColors.skyDeep, SkyColors.lavender, SkyColors.mint][v],
      .42,
    ).withValues(alpha: 1);
    if (perfect) {
      mineral = mix(mineral, SkyColors.gold, .12);
    } else if (cleared) {
      mineral = mix(mineral, SkyColors.mint, .2);
    }
    final glow = mix(mix(mineral, SkyColors.cream, .5), sky.haze, .08);
    final lit = mix(mix(mineral, SkyColors.cream, .24), sky.horizon, .06);
    final shade = mix(mix(mineral, SkyColors.ink, .3), sky.land, .12);
    final deep = mix(mix(mineral, SkyColors.ink, .5), sky.land, .14);
    final seam = mix(deep, SkyColors.ink, .12);
    final spark = switch (v) {
      1 => mix(SkyColors.white, SkyColors.lavender, .16),
      2 => mix(SkyColors.cream, SkyColors.gold, .5),
      _ => SkyColors.white,
    };
    final lipH = math.min(4.0, h);
    final roomy = w >= 16 && h >= lipH + 16;
    final capH = roomy ? (w * .13).clamp(5.0, 10.0) : 0.0;
    final girdle = roomy ? math.min(2.0, w * .03).clamp(1.2, 2.0) : 0.0;
    final bodyStart = lipH + capH + girdle;
    final origin = top ? r.bottom : r.top;
    final dir = top ? -1.0 : 1.0;
    double yAt(double inward) => origin + dir * inward;
    Rect band(double from, double to, [double? left, double? right]) =>
        Rect.fromLTRB(
          left ?? r.left,
          math.min(yAt(from), yAt(to)),
          right ?? r.right,
          math.max(yAt(from), yAt(to)),
        );
    // Facet boundaries of the prism, shared by the body and the cut table.
    final xa = r.left + w * .27;
    final xb = r.left + w * .71;

    void poly(List<Offset> pts, Color color) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var n = 1; n < pts.length; n++) {
        path.lineTo(pts[n].dx, pts[n].dy);
      }
      c.drawPath(path..close(), Paint()..color = color);
    }

    void sparkle(Offset o, double s, Color color) => poly([
      Offset(o.dx, o.dy - s),
      Offset(o.dx + s * .24, o.dy - s * .24),
      Offset(o.dx + s, o.dy),
      Offset(o.dx + s * .24, o.dy + s * .24),
      Offset(o.dx, o.dy + s),
      Offset(o.dx - s * .24, o.dy + s * .24),
      Offset(o.dx - s, o.dy),
      Offset(o.dx - s * .24, o.dy - s * .24),
    ], color);

    c.save();
    c.clipRect(r);
    // One opaque base first, so facet overlays never leave seams in the solid.
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [mix(lit, mineral, .3), mineral],
        ).createShader(Rect.fromLTRB(xa, r.top, xb, r.bottom)),
    );
    if (w >= 10) {
      c.drawRect(
        Rect.fromLTRB(r.left, r.top, xa, r.bottom),
        Paint()..color = lit,
      );
      c.drawRect(
        Rect.fromLTRB(xb, r.top, r.right, r.bottom),
        Paint()..color = shade,
      );
      final hair = math.min(1.2, w * .02);
      c.drawRect(
        Rect.fromLTWH(xa - hair / 2, r.top, hair, h),
        Paint()..color = glow,
      );
      c.drawRect(
        Rect.fromLTWH(xb - hair / 2, r.top, hair, h),
        Paint()..color = mix(shade, deep, .5),
      );
    }

    // Growth seams step away from the rim; anchoring them to the rim keeps
    // the three columns naturally staggered as their openings move.
    final span = math.max(22.0, w * const [1.7, 2.1, 1.4][v]);
    if (w >= 14 && h > bodyStart + 10) {
      final dark = Paint()
        ..color = seam
        ..strokeWidth = math.min(1.8, w * .026);
      final light = Paint()
        ..color = mix(glow, SkyColors.cream, .3)
        ..strokeWidth = math.min(1.2, w * .018);
      final kink = w * .16;
      final facet = mix(mineral, glow, .62);
      final sparkS = math.min(3.6, w * .055);
      var start = bodyStart;
      for (var i = 0; start < h; i++) {
        final end = start + span * (i == 0 ? .7 : 1);
        final mid = (start + end) / 2;
        // A reflected facet catches the light, alternating corners per step.
        final seg = math.min(end, h) - start;
        if (seg > 12) {
          final cw = xb - xa;
          if (i.isEven) {
            poly([
              Offset(xa, yAt(start)),
              Offset(xa + cw * .62, yAt(start)),
              Offset(xa, yAt(start + seg * .5)),
            ], facet);
          } else {
            poly([
              Offset(xb, yAt(end)),
              Offset(xb - cw * .56, yAt(end)),
              Offset(xb, yAt(end - seg * .46)),
            ], facet);
          }
        }
        // A long glint rides the lit face on alternate segments.
        if (i.isOdd && end - start > 18) {
          final g0 = start + (end - start) * .2;
          final g1 = start + (end - start) * .72;
          final gw = math.max(1.4, w * .045);
          poly([
            Offset(r.left + w * .09, yAt(g1)),
            Offset(r.left + w * .09 + gw, yAt(g1 - gw)),
            Offset(r.left + w * .17 + gw, yAt(g0)),
            Offset(r.left + w * .17, yAt(g0 + gw)),
          ], glow);
        }
        if (sparkS >= 1.6 && !(i == 0 && cleared)) {
          final sx = xa + (xb - xa) * (i.isEven ? .36 : .66);
          final at = Offset(sx, yAt(mid + (i.isEven ? -1 : 1) * span * .08));
          if (v == 2) {
            // Peridot keeps a small gold inclusion instead of a star glint.
            poly([
              Offset(at.dx, at.dy - sparkS),
              Offset(at.dx + sparkS * .7, at.dy),
              Offset(at.dx, at.dy + sparkS),
              Offset(at.dx - sparkS * .7, at.dy),
            ], spark);
          } else {
            sparkle(at, sparkS * (i.isEven ? 1 : .8), spark);
          }
        }
        if (end >= h) break;
        // The ledge line: dark groove, then a thin highlight beneath it.
        final lo = end + 1.6;
        switch (v) {
          case 1:
            c.drawLine(
              Offset(r.left, yAt(end)),
              Offset(r.right, yAt(end + kink)),
              dark,
            );
            c.drawLine(
              Offset(r.left, yAt(lo)),
              Offset(r.right, yAt(lo + kink)),
              light,
            );
          case 2:
            c.drawLine(
              Offset(r.left, yAt(end)),
              Offset(r.right, yAt(end)),
              dark,
            );
            c.drawLine(
              Offset(r.left, yAt(lo)),
              Offset(r.right, yAt(lo)),
              light,
            );
          default:
            final apex = r.left + w * .5;
            c.drawLine(
              Offset(r.left, yAt(end)),
              Offset(apex, yAt(end + kink)),
              dark,
            );
            c.drawLine(
              Offset(apex, yAt(end + kink)),
              Offset(r.right, yAt(end)),
              dark,
            );
            c.drawLine(
              Offset(r.left, yAt(lo)),
              Offset(apex, yAt(lo + kink)),
              light,
            );
            c.drawLine(
              Offset(apex, yAt(lo + kink)),
              Offset(r.right, yAt(lo)),
              light,
            );
        }
        start =
            end +
            (v == 1
                ? kink
                : v == 0
                ? kink * .5
                : 0);
      }
    }

    // A soft slanted shimmer drifts along the prism at a constant speed.
    if (!reducedMotion && w >= 16 && h >= 28) {
      final travel = w * 9;
      final bh = w * .22;
      final slope = w * .4;
      final sd = ((clock * w * 1.1) % travel + travel) % travel - bh - slope;
      if (sd + bh + slope > bodyStart && sd < h) {
        poly([
          Offset(r.left, yAt(sd + slope)),
          Offset(r.right, yAt(sd)),
          Offset(r.right, yAt(sd + bh)),
          Offset(r.left, yAt(sd + slope + bh)),
        ], SkyColors.cream.withValues(alpha: .2));
      }
    }

    // Edge light and core shadow keep the prism rounded at phone scale.
    final edge = math.min(2.5, w * .04);
    if (edge >= 1) {
      c.drawRect(
        Rect.fromLTWH(r.left, r.top, edge, h),
        Paint()..color = mix(SkyColors.cream, glow, .3),
      );
      c.drawRect(
        Rect.fromLTWH(r.right - edge, r.top, edge, h),
        Paint()..color = deep,
      );
    }

    // The cut end: a faceted table narrows toward the rim over a dark girdle.
    if (capH > 0) {
      final o0 = lipH;
      final o1 = lipH + capH;
      final ta = r.left + w * .36;
      final tb = r.left + w * .64;
      var table = mix(glow, SkyColors.white, .55);
      if (perfect) {
        table = mix(table, SkyColors.yellow, .35);
      } else if (cleared) {
        table = mix(table, SkyColors.mint, .3);
      }
      c.drawRect(band(o0, o1), Paint()..color = glow);
      poly([
        Offset(r.left, yAt(o0)),
        Offset(ta, yAt(o0)),
        Offset(xa, yAt(o1)),
        Offset(r.left, yAt(o1)),
      ], glow);
      poly([
        Offset(ta, yAt(o0)),
        Offset(tb, yAt(o0)),
        Offset(xb, yAt(o1)),
        Offset(xa, yAt(o1)),
      ], table);
      poly([
        Offset(tb, yAt(o0)),
        Offset(r.right, yAt(o0)),
        Offset(r.right, yAt(o1)),
        Offset(xb, yAt(o1)),
      ], mix(mineral, shade, .4));
      c.drawRect(
        band(o1, o1 + girdle),
        Paint()..color = mix(deep, SkyColors.ink, .25),
      );
    }
    c.drawRect(band(0, lipH), Paint()..color = SkyColors.cream);
    if (lipH >= 3) {
      const hair = 1.15;
      c.drawRect(band(0, hair), Paint()..color = SkyColors.white);
    }

    if (cleared && capH > 0 && w >= 18) {
      final s = math.min(perfect ? 6.5 : 5.0, w * .1);
      final at = Offset((xa + xb) / 2, yAt(bodyStart + s + 4));
      if (s >= 2.4 && bodyStart + 2 * s + 6 < h) {
        if (perfect) sparkle(at, s + 1.8, SkyColors.gold);
        sparkle(at, s, perfect ? SkyColors.yellow : SkyColors.cream);
        c.drawCircle(at, s * .22, Paint()..color = SkyColors.white);
      }
    }
    c.restore();
  }
}
