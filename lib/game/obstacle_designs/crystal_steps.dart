import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Opaque quartz, amethyst, and peridot columns clipped to the solid.
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
    double clampUnit(double value, double lo, double hi) =>
        value < lo ? lo : (value > hi ? hi : value);

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
    final glow = mix(mix(mineral, SkyColors.cream, .4), sky.haze, .1);
    final lit = mix(mix(mineral, SkyColors.cream, .14), sky.horizon, .08);
    final shade = mix(mix(mineral, SkyColors.ink, .24), sky.land, .12);
    final deep = mix(mix(mineral, SkyColors.ink, .46), sky.land, .16);
    final ice = switch (v) {
      1 => mix(SkyColors.cream, SkyColors.lavender, .4),
      2 => mix(SkyColors.cream, SkyColors.gold, .34),
      _ => mix(SkyColors.white, SkyColors.skyDeep, .18),
    };
    final flash = switch (v) {
      1 => mix(SkyColors.cream, SkyColors.lavender, .26),
      2 => mix(SkyColors.cream, SkyColors.gold, .32),
      _ => mix(SkyColors.white, SkyColors.cream, .12),
    };
    final lipH = math.min(4.0, h);
    final shoulder = math.min(3.0, math.max(0.0, h - lipH));
    final origin = top ? r.bottom : r.top;
    final dir = top ? -1.0 : 1.0;
    double yAt(double inward) => origin + dir * inward;

    void poly(List<Offset> pts, Color color) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var n = 1; n < pts.length; n++) {
        path.lineTo(pts[n].dx, pts[n].dy);
      }
      c.drawPath(path..close(), Paint()..color = color);
    }

    c.save();
    c.clipRect(r);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [glow, mix(mineral, sky.land, .12), deep],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(r),
    );

    final span = math.max(18.0, w * const [1.65, 2.08, 1.24][v]);
    if (w >= 10 && h >= 8) {
      var i = 0;
      for (var dist = 0.0; dist < h; dist += span) {
        final fx = switch (v) {
          1 => i.isEven ? .7 : .32,
          2 => i.isEven ? .36 : .67,
          _ => .5,
        };
        final fy = switch (v) {
          1 => i.isEven ? .4 : .62,
          2 => .32,
          _ => .5,
        };
        final y0 = yAt(dist);
        final y1 = yAt(dist + span);
        final ax = r.left + fx * w;
        final ay = yAt(dist + fy * span);
        final apex = Offset(ax, ay);
        poly([Offset(r.left, y0), Offset(r.right, y0), apex], glow);
        poly([Offset(r.right, y0), Offset(r.right, y1), apex], shade);
        poly([Offset(r.right, y1), Offset(r.left, y1), apex], deep);
        poly([Offset(r.left, y1), Offset(r.left, y0), apex], lit);

        final hw = w * (v == 1 ? .1 : .16);
        final hh = span * (v == 1 ? .2 : .13);
        final syMin = span <= 0
            ? 1.0
            : math.max(.36, (lipH + shoulder + hh + 1) / span);
        final sx = clampUnit(fx + (i.isEven ? -.12 : .1), .38, .68);
        final sy = clampUnit(v == 1 ? fy + .12 : fy - .02, syMin, .7);
        final roomy =
            hw >= 3.2 &&
            hh >= 3.2 &&
            syMin < .68 &&
            sx * w - hw >= 1 &&
            (1 - sx) * w - hw >= 1 &&
            sy * span - hh >= 1 &&
            (1 - sy) * span - hh >= 1;
        if (roomy) {
          Offset pt(double dx, double din) =>
              Offset(r.left + sx * w + dx, yAt(dist + sy * span + din));
          final tip = pt(i.isEven ? -hw * .2 : hw * .15, -hh);
          final east = pt(hw * .95, hh * .08);
          final foot = pt(hw * .12, hh * .82);
          final west = pt(-hw * .78, hh * .16);
          poly([tip, east, foot, west], ice);
          poly([tip, east, pt(0, 0)], mix(SkyColors.cream, ice, .4));
        }

        final face = fy * span;
        final fhw =
            w *
            (v == 1
                ? .09
                : v == 2
                ? .16
                : .13);
        final fhh =
            span *
            (v == 1
                ? .09
                : v == 2
                ? .048
                : .07);
        final minIn = lipH + (shoulder >= 1.5 ? shoulder : 0) + fhh + 1;
        final maxIn = face - fhh - 1;
        if (w >= 22 && maxIn > minIn && fhw >= 2.5 && fhh >= 2) {
          final tin = (minIn + maxIn) / 2;
          final u = (tin - dist) / face;
          final room = (1 - u) * w / 2;
          if (u > .12 && u < .86 && fhw < room - .5) {
            final px = r.center.dx + (ax - r.center.dx) * u;
            final py = yAt(dist + face * u);
            poly([
              Offset(px, py - fhh),
              Offset(px + fhw, py),
              Offset(px, py + fhh),
              Offset(px - fhw, py),
            ], flash);
            poly([
              Offset(px - fhw, py),
              Offset(px, py + (top ? -fhh : fhh)),
              Offset(px + fhw, py),
            ], mix(flash, mineral, .34));
          }
        }

        if (v == 2) {
          final band = math.min(3.5, span * .1);
          if (band >= 1.6) {
            final far = dist + span;
            final y = top ? yAt(far) : yAt(far) - band;
            c.drawRect(
              Rect.fromLTWH(r.left, y, w, band),
              Paint()..color = mix(deep, SkyColors.ink, .32),
            );
          }
        }
        i++;
      }
    }

    if (h >= 28 && w >= 16) {
      final phase = reducedMotion ? .4 : ((clock * .12) % 1 + 1) % 1;
      final sd = phase * h;
      final bh = math.min(16.0, math.max(8.0, h * .1));
      poly([
        Offset(r.left + w * .06, yAt(sd)),
        Offset(r.left + w * .24, yAt(sd + bh * .35)),
        Offset(r.left + w * .2, yAt(sd + bh)),
        Offset(r.left + w * .05, yAt(sd + bh * .62)),
      ], mix(SkyColors.cream, glow, .22));
    }

    final edge = math.min(3.0, w * .1);
    if (edge >= 1.25) {
      c.drawRect(
        Rect.fromLTWH(r.left, r.top, edge, h),
        Paint()..color = mix(SkyColors.cream, glow, .28),
      );
      c.drawRect(
        Rect.fromLTWH(r.right - edge, r.top, edge, h),
        Paint()..color = mix(SkyColors.ink, deep, .3),
      );
    }
    if (shoulder >= 1.5) {
      final y = top ? r.bottom - lipH - shoulder : r.top + lipH;
      c.drawRect(
        Rect.fromLTWH(r.left, y, w, shoulder),
        Paint()..color = mix(deep, SkyColors.ink, .2),
      );
    }
    c.drawRect(
      Rect.fromLTWH(r.left, top ? r.bottom - lipH : r.top, w, lipH),
      Paint()..color = SkyColors.cream,
    );
    if (lipH >= 3) {
      const hair = 1.15;
      c.drawRect(
        Rect.fromLTWH(r.left, top ? r.bottom - hair : r.top, w, hair),
        Paint()..color = SkyColors.white,
      );
    }

    if (cleared && w >= 18 && h >= 20) {
      var s = math.min(perfect ? 5.8 : 4.4, w * .15);
      final gx = r.left + w * .74;
      var gy = yAt(lipH + shoulder + s + 2);
      bool fits(double rad, double cy) =>
          gx - rad >= r.left + 1 &&
          gx + rad <= r.right - 1 &&
          cy - rad >= r.top + 1 &&
          cy + rad <= r.bottom - 1;
      if (!fits(s, gy)) {
        s = math.min(s, (h - lipH - shoulder - 4) / 2);
        if (s > 0) gy = yAt(lipH + shoulder + s + 2);
      }
      if (s >= 2.4 && fits(s, gy)) {
        void gem(Offset o, double rad, Color color) => poly([
          Offset(o.dx, o.dy - rad),
          Offset(o.dx + rad * .7, o.dy),
          Offset(o.dx, o.dy + rad),
          Offset(o.dx - rad * .7, o.dy),
        ], color);
        if (perfect && fits(s + 1.3, gy)) {
          gem(Offset(gx, gy), s + 1.3, SkyColors.gold);
        }
        gem(Offset(gx, gy), s, perfect ? SkyColors.yellow : SkyColors.cream);
        gem(Offset(gx - s * .18, gy - s * .22), s * .26, SkyColors.white);
      }
    }
    c.restore();
  }
}
