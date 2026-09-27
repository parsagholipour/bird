import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Solid blossom column: petal shingles overlap toward a scalloped rim collar
/// that holds one turning bloom, so the open edge reads at a glance.
abstract final class PetalShuttersDesign {
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
    final v = (appearance % 3 + 3) % 3;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    // Points from the rim into the solid; petals point back toward the rim.
    final dir = top ? -1.0 : 1.0;
    final rim = top ? r.bottom : r.top;
    final w = r.width;
    final t = reducedMotion ? 0.0 : seconds;
    // Each tint shades toward its own deep hue, so yellow never turns olive.
    final hue = [
      mix(SkyColors.coralDeep, SkyColors.purple, .3),
      SkyColors.purple,
      mix(SkyColors.gold, SkyColors.coralDeep, .4),
    ][v];
    final plum = mix(hue, SkyColors.ink, .3);
    final light = mix(accent, SkyColors.cream, .42);
    final body = mix(accent, plum, .12);
    final shade = mix(accent, plum, .42);
    final petalA = mix(accent, SkyColors.cream, .5);
    final petalB = mix(accent, SkyColors.cream, .24);
    final shadow = mix(accent, plum, .5).withValues(alpha: .55);
    final capDeep = mix(accent, plum, .58);
    final capLight = mix(accent, SkyColors.cream, .74);

    void bar(double y0, double y1, Color color) => c.drawRect(
      Rect.fromLTRB(r.left, math.min(y0, y1), r.right, math.max(y0, y1)),
      Paint()..color = color,
    );

    c.save();
    c.clipRect(r);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [light, body, shade],
          stops: const [.08, .52, 1],
        ).createShader(r),
    );

    final cap = r.height < 12
        ? math.min(4.0, r.height)
        : math.min(9.0, r.height * .3);
    final room = r.height - cap;

    // Shingles: rows start just under the collar and stack away from it, each
    // farther row overlapping the tips of the nearer one like a roof.
    if (w >= 10 && room >= 6) {
      final step = const [19.0, 23.0, 15.0][v];
      final per = const [2, 1, 3][v];
      final pitch = w / per;
      final len = step * (v == 2 ? 1.7 : 1.55);
      final veins = Path();
      final shift = Offset(0, -dir * 2);
      final rows = ((room + len) / step).ceil() + 1;
      for (var k = 0; k < rows && k < 80; k++) {
        final flutter = reducedMotion ? 0.0 : math.sin(t * 2.2 - k * .55) * 1.1;
        final tip = rim + dir * (cap - 3 + k * step) - dir * flutter;
        final base = tip + dir * len;
        final odd = k.isOdd;
        final row = Path();
        final count = odd && per > 1 ? per + 1 : per;
        for (var i = 0; i < count; i++) {
          final cx = switch (v) {
            1 => r.center.dx + (odd ? 1 : -1) * w * .16,
            _ => r.left + pitch * (i + (odd ? 0 : .5)),
          };
          final hw = v == 1 ? w * .5 : pitch * .56;
          // Rounded scales, tapered blades, or softly pointed petals.
          final belly = const [.5, .62, .4][v];
          final point = const [.34, .12, .55][v];
          row
            ..moveTo(cx - hw, base)
            ..cubicTo(
              cx - hw,
              base - dir * len * belly,
              cx - hw * point,
              tip,
              cx,
              tip,
            )
            ..cubicTo(
              cx + hw * point,
              tip,
              cx + hw,
              base - dir * len * belly,
              cx + hw,
              base,
            )
            ..close();
          final reach = math.min(step * .8, len * .5);
          veins
            ..moveTo(cx, tip + dir * 3)
            ..lineTo(cx, tip + dir * (3 + reach));
        }
        c.drawPath(row.shift(shift), Paint()..color = shadow);
        c.drawPath(row, Paint()..color = odd ? petalB : petalA);
      }
      c.drawPath(
        veins,
        Paint()
          ..color = SkyColors.cream.withValues(alpha: .5)
          ..strokeWidth = v == 1 ? 1.5 : 1.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      // Rounded volume: a lit left edge and a shaded right jamb.
      c.drawRect(
        Rect.fromLTWH(r.left, r.top, math.max(1.5, w * .05), r.height),
        Paint()..color = SkyColors.cream.withValues(alpha: .28),
      );
      c.drawRect(
        Rect.fromLTWH(r.right - w * .2, r.top, w * .2, r.height),
        Paint()..color = plum.withValues(alpha: .2),
      );
    }

    // Collar: a deep band with scallops biting into the petals and a pale
    // lip on the very edge, so the collision line is the brightest line.
    final inside = rim + dir * cap;
    bar(rim, inside, capDeep);
    if (cap >= 6 && w >= 12) {
      final count = math.max(2, (w / 16).round());
      final pitch = w / count;
      final bite = Path();
      for (var i = 0; i < count; i++) {
        bite.addOval(
          Rect.fromCenter(
            center: Offset(r.left + pitch * (i + .5), inside),
            width: pitch,
            height: pitch * .6,
          ),
        );
      }
      c.drawPath(bite, Paint()..color = capDeep);
    }
    bar(rim, rim + dir * cap * .45, capLight);
    if (cap >= 3) {
      bar(rim, rim + dir * 1.2, SkyColors.white);
      bar(rim + dir * cap * .45, rim + dir * (cap * .45 + 1), SkyColors.gold);
    }

    // Bloom resting against the collar, fully inside the column.
    final radius = room < 12 ? 0.0 : math.min(w * .39, room * .4);
    if (radius >= 4) {
      final hub = Offset(r.center.dx, rim + dir * (cap + radius + 2));
      final n = const [6, 5, 8][v];
      final turn = t * .4 + v * .4;
      final under = mix(accent, hue, .55);
      final over = mix(accent, SkyColors.cream, .72);
      final petal = Path();
      final inner = Path();
      for (var i = 0; i < n; i++) {
        for (final outer in [true, false]) {
          final a = turn + (i + (outer ? 0 : .5)) * math.pi * 2 / n;
          final rad = radius * (outer ? 1 : .7);
          final cs = math.cos(a), sn = math.sin(a);
          Offset at(double x, double y) =>
              hub + Offset(x * cs - y * sn, x * sn + y * cs);
          final wd = rad * const [.4, .36, .26][v];
          final lean = const [.95, .25, .8][v];
          final l1 = at(-wd, -rad * .12), l2 = at(-wd * lean, -rad * 1.02);
          final r1 = at(wd * lean, -rad * 1.02), r2 = at(wd, -rad * .12);
          final tip = at(0, -rad), root = at(0, 0);
          (outer ? petal : inner)
            ..moveTo(root.dx, root.dy)
            ..cubicTo(l1.dx, l1.dy, l2.dx, l2.dy, tip.dx, tip.dy)
            ..cubicTo(r1.dx, r1.dy, r2.dx, r2.dy, root.dx, root.dy)
            ..close();
        }
      }
      c.drawPath(petal.shift(Offset(0, -dir * 2)), Paint()..color = shadow);
      c.drawPath(petal, Paint()..color = under);
      c.drawPath(inner, Paint()..color = over);
      final heart = [SkyColors.coralDeep, SkyColors.coral, SkyColors.gold][v];
      c.drawCircle(hub, radius * .3, Paint()..color = SkyColors.gold);
      c.drawCircle(hub, radius * .18, Paint()..color = heart);
      c.drawCircle(
        hub + Offset(-radius * .08, -radius * .09),
        radius * .06,
        Paint()..color = SkyColors.cream,
      );
      if (cleared) {
        c.drawCircle(
          hub,
          radius * .42,
          Paint()
            ..color = perfect ? SkyColors.yellow : SkyColors.cream
            ..strokeWidth = perfect ? 2.2 : 1.5
            ..style = PaintingStyle.stroke,
        );
        final jewel = hub + Offset(0, dir * (radius + 9));
        if (perfect && r.deflate(5).contains(jewel)) {
          final star = SkyScenery.star(jewel, math.min(7.0, w * .12));
          c.drawPath(
            star.shift(Offset(0, -dir * 1.5)),
            Paint()..color = capDeep,
          );
          c.drawPath(star, Paint()..color = SkyColors.cream);
        }
      }
    }

    c.restore();
  }
}
