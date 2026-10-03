import 'dart:math' as math;
import 'dart:ui';

import '../domain/steam_geyser.dart';
import 'steam_geyser_kit.dart';

/// One lobe of a steam silhouette: an ellipse.
class _Lobe {
  const _Lobe(this.x, this.y, this.rx, this.ry);
  final double x, y, rx, ry;
}

/// The steam of a vent, one painter per phase.
///
/// * **Hiss** (the warning, 1.5 s): a HOT vent shows a hazard-taped column,
///   bright walls, a pressure fill that climbs from the lid, heat shimmer,
///   curling wisps and tapered spurts; a RIDE vent shows no box at all, only
///   a dotted dome at the top of the reach, a funnel of teal air with rising,
///   growing chevrons.
/// * **Burst** (0.5 s): a hot vent throws a pointed white-hot jet that rolls
///   over into a curling head; a ride vent swells into the soft cool cloud
///   (it never scalds), so the shape says hurts or helps before the colour.
/// * **Billow** (1.25 s): a tall cool cloud that leans and drifts, its ink
///   open on the upper side, a value ramp from base to crown, teal updraft
///   streaks and chevrons that grow as they climb.
///
/// Flat shapes only, batched into a few paths: no blur, no `saveLayer`, no
/// shader. Every measurement is in viewport heights times [h].
abstract final class SteamPlumeArt {
  // ---------------------------------------------------------------------
  // Light

  /// Warm (or cool) light pooled on the night air around a mouth: stacked
  /// translucent ovals, not a gradient (no shader), flatter than they are
  /// tall because the light spills along the roof.
  static void glow(Canvas c, double h, Offset at, double heat, Color tone) {
    if (heat <= 0) return;
    final paint = Paint();
    for (final (r, a) in const [(.40, .035), (.29, .050), (.21, .150)]) {
      c.drawOval(
        Rect.fromCenter(center: at, width: h * r * 2, height: h * r * 1.5),
        paint..color = tone.withValues(alpha: a * heat),
      );
    }
  }

  /// The burst's own light on the night around it: a warm (or, for a ride
  /// vent, cool) oval that fades over the first 0.25 s.
  static void flash(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double p, {
    required bool hot,
  }) {
    final k = 1 - p / .5;
    if (k <= 0) return;
    final tone = hot ? const Color(0xffffb23a) : SteamTones.tealGlow;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx, mouthY - h * .10),
        width: h * .86,
        height: h * .57,
      ),
      Paint()..color = tone.withValues(alpha: .09 * k),
    );
  }

  // ---------------------------------------------------------------------
  // Shape helpers

  static Path _union(
    List<_Lobe> lobes, {
    double grow = 0,
    double dx = 0,
    double dy = 0,
  }) {
    final path = Path();
    for (final o in lobes) {
      final rx = o.rx + grow, ry = o.ry + grow;
      if (rx <= 0 || ry <= 0) continue;
      path.addOval(
        Rect.fromCenter(
          center: Offset(o.x + dx, o.y + dy),
          width: rx * 2,
          height: ry * 2,
        ),
      );
    }
    return path;
  }

  static Path _poly(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    return path..close();
  }

  // ---------------------------------------------------------------------
  // Hiss

  /// Wisps leaking from the mouth: lazy S-curls when asleep, more and faster
  /// under pressure. Thin inked strokes, so they read as steam.
  static void wisps(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double p,
    double clock,
    int seed,
    bool rm,
    Color tone, {
    required int n,
  }) {
    final under = Path();
    final tiers = [Path(), Path()];
    for (var i = 0; i < n; i++) {
      final life = rm
          ? (i + .5) / n
          : (clock * (.38 + SteamMath.hash(seed, i) * .22) * (1 + p) +
                    SteamMath.hash(seed, i + 9)) %
                1;
      final lean = (SteamMath.hash(seed, i + 3) - .5) * h * .05;
      final len = h * (.07 + .06 * p);
      final x0 = cx + (SteamMath.hash(seed, i + 17) - .5) * h * .05;
      final y0 = mouthY - h * .012 - life * h * (.05 + .10 * p);
      final path = Path()..moveTo(x0, y0);
      for (var k = 1; k <= 8; k++) {
        final u = k / 8;
        path.lineTo(
          x0 +
              lean * life * u +
              math.sin(u * 5.5 + life * 3 + i * 2.1 + (rm ? 0 : clock * .6)) *
                  h *
                  .011 *
                  u,
          y0 - len * u,
        );
      }
      under.addPath(path, Offset.zero);
      tiers[life < .5 ? 0 : 1].addPath(path, Offset.zero);
    }
    c.drawPath(
      under,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .30 * (.5 + .5 * p))
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0125
        ..strokeCap = StrokeCap.round,
    );
    for (var k = 0; k < 2; k++) {
      c.drawPath(
        tiers[k],
        Paint()
          ..color = tone.withValues(alpha: (.92 - k * .40) * (.6 + .4 * p))
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0075
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Tapered wedges of steam spurting from under the lid's edge, two a side
  /// (a long low one and a short high one), longer and thicker as the
  /// pressure builds, bending up as they go: the hiss you can see. Pointed,
  /// not round. Drawn before the lid, so they come out from under it.
  static void spurts(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double p,
    double clock,
    bool rm, {
    required bool hot,
  }) {
    final a = SteamMath.smooth(p / .15);
    if (a <= 0) return;
    final wedges = Path();
    for (final side in const [-1.0, 1.0]) {
      for (var k = 0; k < 2; k++) {
        final ang = (k == 0 ? 24.0 : 44.0) * math.pi / 180;
        final pulse = rm
            ? 1.0
            : .90 + .10 * math.sin(clock * 11 + k * 2.3 + side);
        final len = h * (.030 + .052 * p) * (k == 0 ? 1.0 : .62) * pulse;
        final base = Offset(
          cx + side * h * (.034 + .006 * k),
          mouthY - h * (.004 + .004 * k),
        );
        final dir = Offset(side * math.cos(ang), -math.sin(ang));
        final perp = Offset(-dir.dy, dir.dx) * (h * .0058 * (.6 + .8 * p));
        final tip = base + dir * len + Offset(side * len * .10, -len * .22);
        final ctrl = base + dir * (len * .60);
        wedges
          ..moveTo(base.dx + perp.dx, base.dy + perp.dy)
          ..quadraticBezierTo(
            ctrl.dx + perp.dx * .4,
            ctrl.dy + perp.dy * .4,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            ctrl.dx - perp.dx * .4,
            ctrl.dy - perp.dy * .4,
            base.dx - perp.dx,
            base.dy - perp.dy,
          )
          ..close();
      }
    }
    c.drawPath(
      wedges,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .70 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0042
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      wedges,
      Paint()
        ..color = (hot ? SteamTones.hotBody : SteamTones.coolHigh).withValues(
          alpha: .95 * a,
        ),
    );
  }

  /// The warning: the exact reach of the coming steam, drawn for the whole
  /// hiss, ending on the hit box's top ([topY]).
  ///
  /// HOT: a column with bright solid walls, a hazard-tape cap on the hit top,
  /// a pressure fill that climbs from the lid over the 1.5 s, heat shimmer
  /// strokes inside it.
  /// RIDE: no box. A dotted dome at the top of the reach, a funnel of teal
  /// air, chevrons that grow as they rise, and an updraft shimmer.
  ///
  /// One brightness ramp into the burst, no flicker. [lite] draws only the
  /// outline (cap, walls or dome) for the first beats of the burst, fading
  /// by [fade].
  static void ghost(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double topY,
    double p,
    double clock,
    bool rm, {
    required bool hot,
    double fade = 1,
    bool lite = false,
  }) {
    final half = h * .072;
    final fadeIn = SteamMath.smooth(p / .08) * fade;
    if (fadeIn <= 0) return;
    final total = mouthY - topY;
    if (total <= half * 2) return;
    final ramp = SteamMath.smooth((p - .72) / .28);
    final level = SteamMath.smooth(p / .92);
    final fillTop = mouthY - total * level;
    if (hot) {
      _ghostHot(
        c,
        h,
        cx,
        mouthY,
        topY,
        p,
        clock,
        rm,
        half,
        fadeIn,
        ramp,
        fillTop,
        lite,
      );
    } else {
      _ghostRide(
        c,
        h,
        cx,
        mouthY,
        topY,
        p,
        clock,
        rm,
        half,
        fadeIn,
        ramp,
        fillTop,
        lite,
      );
    }
  }

  static void _ghostHot(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double topY,
    double p,
    double clock,
    bool rm,
    double half,
    double fadeIn,
    double ramp,
    double fillTop,
    bool lite,
  ) {
    final left = cx - half, right = cx + half;
    if (!lite) {
      // A dark underlay so the pale fill stands out from lit windows.
      c.drawRect(
        Rect.fromLTRB(left, topY, right, mouthY),
        Paint()..color = SteamTones.ink.withValues(alpha: .20 * fadeIn),
      );
      // The pressure fill climbs from the lid: two warm layers and a bright
      // wavy surface.
      if (mouthY - fillTop > h * .012) {
        c.drawRect(
          Rect.fromLTRB(left, fillTop, right, mouthY),
          Paint()
            ..color = SteamTones.hotBody.withValues(
              alpha: (.36 + .08 * ramp) * fadeIn,
            ),
        );
        final low = fillTop + (mouthY - fillTop) * .55;
        c.drawRect(
          Rect.fromLTRB(left, low, right, mouthY),
          Paint()
            ..color = SteamTones.hotRoot.withValues(
              alpha: (.28 + .12 * ramp) * fadeIn,
            ),
        );
        final surface = Path()..moveTo(left, fillTop);
        for (var i = 1; i <= 10; i++) {
          final u = i / 10;
          surface.lineTo(
            left + 2 * half * u,
            fillTop + math.sin(u * 9 + (rm ? 0 : clock * 6)) * h * .0035,
          );
        }
        c.drawPath(
          surface,
          Paint()
            ..color = SteamTones.hotHigh.withValues(alpha: .95 * fadeIn)
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .0058
            ..strokeCap = StrokeCap.round,
        );
        // Heat shimmer: short wavy strokes rise through the filled part.
        final n = 3 + (p * 3).floor();
        final shimmer = Path();
        final yBottom = mouthY - h * .02, yTop = fillTop + h * .008;
        if (yBottom - yTop > h * .04) {
          for (var i = 0; i < n; i++) {
            final x0 = cx + (i / (n - 1) - .5) * 2 * half * .76;
            final life = rm
                ? (i * .37 + .2) % 1
                : (clock * (.45 + .3 * p) + i * .37) % 1;
            final len = h * (.075 + .03 * (i % 2));
            final yc = yBottom - (yBottom - yTop) * life;
            final y0 = math.min(yBottom, yc + len / 2),
                y1 = math.max(yTop, yc - len / 2);
            if (y0 - y1 < h * .015) continue;
            for (var k = 0; k <= 6; k++) {
              final y = y0 + (y1 - y0) * k / 6;
              final q = Offset(
                x0 +
                    math.sin(y / h * 60 + i * 1.9 + (rm ? 0 : clock * 5)) *
                        h *
                        .0065,
                y,
              );
              k == 0 ? shimmer.moveTo(q.dx, q.dy) : shimmer.lineTo(q.dx, q.dy);
            }
          }
          c.drawPath(
            shimmer,
            Paint()
              ..color = SteamTones.amber.withValues(alpha: .85 * fadeIn)
              ..style = PaintingStyle.stroke
              ..strokeWidth = h * .0050
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
    // Bright solid walls over a dark underlay: the reach, in value as well
    // as in hue.
    final walls = Path()
      ..moveTo(left, mouthY)
      ..lineTo(left, topY)
      ..moveTo(right, mouthY)
      ..lineTo(right, topY);
    c.drawPath(
      walls,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .70 * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0158,
    );
    c.drawPath(
      walls,
      Paint()
        ..color = Color.lerp(
          SteamTones.hotHigh,
          SteamTones.hotRoot,
          .15 + .30 * ramp,
        )!.withValues(alpha: (.92 + .08 * p) * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0078,
    );
    // Hazard-tape cap on the hit box's top: ink and amber diagonals.
    final capHalf = half * 1.28;
    final hb = h * .020;
    final cap = Rect.fromLTRB(cx - capHalf, topY, cx + capHalf, topY + hb);
    final crawl = rm ? 0.0 : (clock * h * .035) % (hb * 1.9);
    final stripes = Path();
    for (var x = cap.left - hb * 2 + crawl; x < cap.right; x += hb * 1.9) {
      double cl(double v) => v.clamp(cap.left, cap.right);
      stripes
        ..moveTo(cl(x), cap.bottom)
        ..lineTo(cl(x + hb), cap.top)
        ..lineTo(cl(x + hb + hb * .95), cap.top)
        ..lineTo(cl(x + hb * .95), cap.bottom)
        ..close();
    }
    c.drawRect(cap, Paint()..color = SteamTones.ink.withValues(alpha: fadeIn));
    c.drawPath(
      stripes,
      Paint()
        ..color = Color.lerp(
          SteamTones.amber,
          SteamTones.hotRoot,
          .2 * ramp,
        )!.withValues(alpha: fadeIn),
    );
    if (!lite) {
      c.drawRect(
        cap,
        Paint()
          ..color = SteamTones.ink.withValues(alpha: fadeIn)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0042,
      );
    }
  }

  static void _ghostRide(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double topY,
    double p,
    double clock,
    bool rm,
    double half,
    double fadeIn,
    double ramp,
    double fillTop,
    bool lite,
  ) {
    final domeY = topY + half;
    // A dotted dome at the top of the reach (no outline anywhere else).
    final dots = Path();
    const nDots = 10;
    final dotR = h * .0100;
    for (var i = 0; i < nDots; i++) {
      final a = math.pi + math.pi * i / (nDots - 1);
      dots.addOval(
        Rect.fromCircle(
          center: Offset(
            cx + math.cos(a) * (half - dotR),
            domeY + math.sin(a) * (half - dotR) + (i == 5 ? 0 : 0),
          ),
          radius: dotR * (i == 5 ? 1.25 : 1.0),
        ),
      );
    }
    c.drawPath(
      dots,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .85 * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0075,
    );
    c.drawPath(
      dots,
      Paint()
        ..color = Color.lerp(
          SteamTones.tealGlow,
          const Color(0xffffffff),
          .62 + .30 * ramp,
        )!.withValues(alpha: fadeIn),
    );
    if (lite) return;
    // The funnel of rising air: soft teal, wider at the top, no edge line.
    final funnel = Path()
      ..moveTo(cx - half * .55, mouthY)
      ..lineTo(cx - half, domeY)
      ..arcToPoint(
        Offset(cx + half, domeY),
        radius: Radius.circular(half),
        clockwise: true,
      )
      ..lineTo(cx + half * .55, mouthY)
      ..close();
    c.drawPath(
      funnel,
      Paint()..color = SteamTones.ink.withValues(alpha: .16 * fadeIn),
    );
    c.drawPath(
      funnel,
      Paint()
        ..color = SteamTones.tealGlow.withValues(
          alpha: (.22 + .08 * ramp) * fadeIn,
        ),
    );
    // The same funnel up to the pressure level: it fills from the lid.
    if (mouthY - fillTop > h * .02) {
      final k = (mouthY - fillTop) / (mouthY - domeY);
      final wTop = half * (.55 + .45 * math.min(1.0, k));
      c.drawPath(
        Path()
          ..moveTo(cx - half * .55, mouthY)
          ..lineTo(cx - wTop, math.max(fillTop, domeY))
          ..lineTo(cx + wTop, math.max(fillTop, domeY))
          ..lineTo(cx + half * .55, mouthY)
          ..close(),
        Paint()
          ..color = SteamTones.tealGlow.withValues(
            alpha: (.18 + .08 * ramp) * fadeIn,
          ),
      );
    }
    // Chevrons rise and grow: small at the lid, wide as they climb.
    final span = mouthY - domeY - h * .03;
    for (var i = 0; i < 4; i++) {
      final k = rm ? (i + .5) / 4 : (clock * (.42 + .75 * p) + i / 4) % 1;
      final y = mouthY - h * .03 - span * k;
      final w = h * (.016 + .052 * k);
      final a =
          math.pow(math.sin(k * math.pi), .6).toDouble() *
          (.40 + .60 * p) *
          fadeIn;
      final chev = Path()
        ..moveTo(cx - w, y + w * .55)
        ..lineTo(cx, y - w * .35)
        ..lineTo(cx + w, y + w * .55);
      c.drawPath(
        chev,
        Paint()
          ..color = SteamTones.ink.withValues(alpha: .55 * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * (.0135 + .006 * k)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      c.drawPath(
        chev,
        Paint()
          ..color = Color.lerp(
            SteamTones.teal,
            SteamTones.tealGlow,
            .35,
          )!.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * (.0080 + .0045 * k)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    // Updraft shimmer: short soft wavy teal-white strokes rising.
    final n = 2 + (p * 2).floor();
    final shimmer = Path();
    final yBottom = mouthY - h * .03, yTop = math.max(fillTop, domeY) + h * .02;
    if (yBottom - yTop > h * .04) {
      for (var i = 0; i < n; i++) {
        final x0 = cx + (i / (n - 1) - .5) * 2 * half * .5;
        final life = rm
            ? (i * .41 + .25) % 1
            : (clock * (.4 + .3 * p) + i * .41) % 1;
        final len = h * .085;
        final yc = yBottom - (yBottom - yTop) * life;
        final y0 = math.min(yBottom, yc + len / 2),
            y1 = math.max(yTop, yc - len / 2);
        if (y0 - y1 < h * .015) continue;
        for (var k = 0; k <= 6; k++) {
          final y = y0 + (y1 - y0) * k / 6;
          final q = Offset(
            x0 +
                math.sin(y / h * 55 + i * 2.3 + (rm ? 0 : clock * 4.5)) *
                    h *
                    .0055,
            y,
          );
          k == 0 ? shimmer.moveTo(q.dx, q.dy) : shimmer.lineTo(q.dx, q.dy);
        }
      }
      c.drawPath(
        shimmer,
        Paint()
          ..color = SteamTones.coolHigh.withValues(alpha: .6 * fadeIn)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0038
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Burst (a hot vent's jet)

  /// Mist along the roof from the lid, soft and uninked: it bursts out wide
  /// in the first tenth of a second (so the bang is sudden even while the
  /// jet is still rising) and settles to a skirt round the jet's foot.
  static void mist(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double p,
    bool rm,
  ) {
    final t = p * SteamCycle.burst;
    final bump = rm ? 0.0 : math.exp(-t * 11);
    final lift = rm ? 0.0 : math.min(1.0, t / .05);
    final lobes = <_Lobe>[
      for (final side in const [-1.0, 1.0]) ...[
        _Lobe(
          cx + side * h * (.062 + .060 * bump),
          mouthY - h * (.010 + .018 * bump),
          h * (.042 + .030 * bump),
          h * (.016 + .020 * bump * lift),
        ),
        if (bump > .12)
          _Lobe(
            cx + side * h * (.030 + .030 * bump),
            mouthY - h * (.022 + .030 * bump),
            h * (.030 + .020 * bump),
            h * (.022 + .022 * bump),
          ),
      ],
    ];
    c.drawPath(
      _union(lobes),
      Paint()..color = SteamTones.hotBody.withValues(alpha: .92),
    );
  }

  /// The white-hot glare at the nozzle: a spiky star that blazes in the
  /// burst's first tenth of a second and settles to a steady glare, then
  /// fades into the cloud.
  static void nozzle(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double p,
    double clock,
    bool rm,
    bool hot,
  ) {
    final blaze = 1 - SteamMath.smooth(p / .30);
    final r = h * (.030 + .048 * blaze);
    final o = Offset(cx, mouthY - h * .014);
    Path star(double outer, double inner, double turn) {
      final path = Path();
      const n = 8;
      for (var i = 0; i < n * 2; i++) {
        final a = turn + i * math.pi / n;
        final rr = i.isEven ? outer : inner;
        final q = o + Offset(math.cos(a) * rr, math.sin(a) * rr * .62);
        i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      return path..close();
    }

    final fade = SteamMath.smooth((1 - p) / .25);
    c.drawPath(
      star(r * 1.5, r * .55, .2),
      Paint()
        ..color = (hot ? SteamTones.amber : SteamTones.tealGlow).withValues(
          alpha: .55 * fade,
        ),
    );
    c.drawPath(
      star(r, r * .42, .2 + math.pi / 8),
      Paint()..color = const Color(0xffffffff).withValues(alpha: fade),
    );
  }

  /// The scalding jet: narrow and white-hot where it leaves the lid, edge
  /// lobes streaming up its sides, an amber rim of heat running up each
  /// edge, an amber core with a white heart, and a head that rolls over:
  /// two shoulders and two curls turning slowly about the crown, with thin
  /// darker contours inside so it has volume. The crown's top edge IS the
  /// hit box's top.
  static void burst(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double topY,
    double p,
    double clock,
    int seed,
    bool rm,
  ) {
    final span = mouthY - topY;
    if (span < h * .010) return;
    final r = math.min(h * .060, span * .34);
    final headY = topY + r;
    final roll = rm ? 0.0 : math.sin(clock * 1.3 + seed) * .16;
    Offset rot(double ox, double oy, double a) => Offset(
      cx + ox * math.cos(a) - oy * math.sin(a),
      headY + ox * math.sin(a) + oy * math.cos(a),
    );
    final crown = _Lobe(cx, headY, r * 1.18, r);
    final shoulders = <_Lobe>[
      for (final s in const [-1.0, 1.0])
        () {
          final q = rot(s * r * 1.14, r * .78, s * roll);
          return _Lobe(q.dx, q.dy, r * .64, r * .60);
        }(),
    ];
    final curls = <_Lobe>[
      for (final s in const [-1.0, 1.0])
        () {
          final q = rot(s * r * 1.30, r * 1.46, s * roll * 1.5);
          return _Lobe(q.dx, q.dy, r * .42, r * .38);
        }(),
    ];
    final head = <_Lobe>[...curls, ...shoulders, crown];

    // The neck: a cone from the lid up into the head, edge lobes streaming
    // up its sides.
    final yEnd = headY + r * .9;
    double wb(double a) =>
        h * .054 + (r * .92 - h * .054) * math.pow(a, .85).toDouble();
    double yAt(double a) => mouthY + (yEnd - mouthY) * a;
    final neck = <Offset>[
      for (var i = 0; i <= 10; i++) Offset(cx - wb(i / 10), yAt(i / 10)),
      for (var i = 10; i >= 0; i--) Offset(cx + wb(i / 10), yAt(i / 10)),
    ];
    final lobes = <_Lobe>[...head];
    const nEdge = 4;
    final flow = rm ? .5 : (clock * 1.8) % 1;
    for (final side in const [-1.0, 1.0]) {
      final stagger = side > 0 ? .5 : 0.0;
      for (var i = 0; i < nEdge; i++) {
        final jitter = SteamMath.hash(seed, i + (side > 0 ? 20 : 0));
        final a = ((i + flow + stagger) / nEdge) % 1.0;
        final fade =
            SteamMath.smooth(a / .14) * SteamMath.smooth((1 - a) / .10);
        final rr =
            h * (.015 + .026 * math.pow(a, .9)) * (.92 + .16 * jitter) * fade;
        if (rr < h * .002) continue;
        lobes.add(
          _Lobe(
            cx + side * (wb(a * .9) + h * .014 - rr),
            yAt(a * .9),
            rr,
            rr * 1.25,
          ),
        );
      }
    }
    final rim = h * .0085;
    final inkC = Color.lerp(
      SteamTones.hotShade,
      SteamTones.ink,
      SteamMath.smooth((1 - p) / .16),
    )!;
    final neckPath = _poly(neck);
    c.drawPath(
      _union(lobes, grow: rim)..addPath(neckPath, Offset.zero),
      Paint()..color = inkC,
    );
    c.drawPath(
      neckPath,
      Paint()
        ..color = inkC
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim * 2
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      _union(lobes)..addPath(neckPath, Offset.zero),
      Paint()..color = SteamTones.hotShade,
    );
    final d = h * .0095;
    c.drawPath(
      _union(lobes, grow: -d, dx: -d * .6, dy: -d)
        ..addPath(neckPath.shift(Offset(-d * .9, -d * .3)), Offset.zero),
      Paint()..color = SteamTones.hotBody,
    );
    // Heat: ember at the lid cooling to cream, in fronts that follow the
    // cone's own curve.
    const bands = [
      (1.0, SteamTones.hotRoot, .30),
      (.62, SteamTones.amber, .30),
      (.30, SteamTones.ember, .36),
    ];
    for (final (frac, color, alpha) in bands) {
      final amax = .62 * frac;
      final pts = <Offset>[
        for (var i = 0; i <= 8; i++)
          Offset(cx - (wb(amax * i / 8) - h * .004), yAt(amax * i / 8)),
        for (var i = 8; i >= 0; i--)
          Offset(cx + (wb(amax * i / 8) - h * .004), yAt(amax * i / 8)),
      ];
      c.drawPath(_poly(pts), Paint()..color = color.withValues(alpha: alpha));
    }
    // The heat lives in the silhouette too: an amber-orange rim running up
    // each edge from the lid to mid-height.
    final rimHeat = Path();
    for (final side in const [-1.0, 1.0]) {
      for (var i = 0; i <= 8; i++) {
        final a = .02 + .58 * i / 8;
        final q = Offset(cx + side * (wb(a) - h * .0105), yAt(a));
        i == 0 ? rimHeat.moveTo(q.dx, q.dy) : rimHeat.lineTo(q.dx, q.dy);
      }
    }
    c.drawPath(
      rimHeat,
      Paint()
        ..color = SteamTones.ember
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0072
        ..strokeCap = StrokeCap.round,
    );
    // The core: amber outside, white-hot inside.
    final coreH = span * .50;
    final wob = rm ? 0.0 : math.sin(clock * 13 + seed) * h * .0018;
    Path core(double w, [double k = 1]) {
      final ch = coreH * k;
      return Path()
        ..moveTo(cx - w * 1.25, mouthY - h * .006)
        ..quadraticBezierTo(
          cx - w * .95 + wob,
          mouthY - ch * .5,
          cx - w * .62 + wob,
          mouthY - ch + w * .5,
        )
        ..arcToPoint(
          Offset(cx + w * .62 + wob, mouthY - ch + w * .5),
          radius: Radius.elliptical(w * .62, w * .95),
          clockwise: true,
        )
        ..quadraticBezierTo(
          cx + w * .95 + wob,
          mouthY - ch * .5,
          cx + w * 1.25,
          mouthY - h * .006,
        )
        ..close();
    }

    c.drawPath(core(h * .030), Paint()..color = SteamTones.amber);
    c.drawPath(core(h * .015, .66), Paint()..color = SteamTones.hotHigh);
    // The head rolls over: curls, then shoulders, then the crown, back to
    // front, each group filled and outlined, so the overlaps read as volumes
    // and not as bubbles.
    for (final group in [
      curls,
      shoulders,
      [crown],
    ]) {
      final path = Path();
      for (final l in group) {
        path.addOval(
          Rect.fromCenter(
            center: Offset(l.x - h * .002, l.y - h * .003),
            width: (l.rx - h * .004) * 2,
            height: (l.ry - h * .004) * 2,
          ),
        );
      }
      c.drawPath(path, Paint()..color = SteamTones.hotBody);
      c.drawPath(
        path,
        Paint()
          ..color = SteamTones.hotDeep.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0034,
      );
    }
    // Creases and lights that turn with the roll.
    final spin = rm ? 0.0 : clock * .55;
    final contours = Path(), lights = Path();
    for (final l in [...shoulders, ...curls]) {
      contours.addArc(
        Rect.fromCenter(
          center: Offset(l.x, l.y),
          width: l.rx * 2 * .70,
          height: l.ry * 2 * .70,
        ),
        math.pi * .12 + spin * .25,
        math.pi * .62,
      );
      lights.addArc(
        Rect.fromCenter(
          center: Offset(l.x, l.y),
          width: l.rx * 2 * .62,
          height: l.ry * 2 * .62,
        ),
        math.pi * 1.05,
        math.pi * .45,
      );
    }
    lights.addArc(
      Rect.fromCenter(
        center: Offset(cx, headY),
        width: r * 2.36 * .74,
        height: r * 2 * .74,
      ),
      math.pi * 1.02,
      math.pi * .52,
    );
    c.drawPath(
      contours,
      Paint()
        ..color = SteamTones.hotDeep.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0030
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      lights,
      Paint()
        ..color = SteamTones.hotHigh.withValues(alpha: .95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0050
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Streaks and droplets thrown from the head in the burst's first moments:
  /// cream streaks and drops, amber sparks and a shock ring over the roof
  /// for a hot vent; only pale teal-white streaks and drops for a ride vent
  /// (it never scalds, so nothing warm flies off it).
  static void spray(
    Canvas c,
    double h,
    double cx,
    double topY,
    double mouthY,
    double p,
    int seed,
    bool rm, {
    required bool hot,
  }) {
    final drops = Path(), sparks = Path(), streaks = Path();
    for (var i = 0; i < 8; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final k = (p * 1.6 + SteamMath.hash(seed, i + 40)) % 1;
      final o = Offset(
        cx + side * h * (.08 + .07 * k + SteamMath.hash(seed, i) * .03),
        topY + h * (.02 + .08 * k * k) - (i >= 6 ? h * .05 : 0),
      );
      final r = h * .0072 * (1 - .5 * k);
      if (i < 6 || !hot) {
        drops.addOval(Rect.fromCircle(center: o, radius: r));
      } else {
        final s = r * 2.2;
        sparks
          ..moveTo(o.dx, o.dy - s)
          ..lineTo(o.dx + s * .35, o.dy - s * .35)
          ..lineTo(o.dx + s, o.dy)
          ..lineTo(o.dx + s * .35, o.dy + s * .35)
          ..lineTo(o.dx, o.dy + s)
          ..lineTo(o.dx - s * .35, o.dy + s * .35)
          ..lineTo(o.dx - s, o.dy)
          ..lineTo(o.dx - s * .35, o.dy - s * .35)
          ..close();
      }
    }
    // A few streaks fly off the head, outward and up.
    for (var i = 0; i < 4; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final k = (p * 1.3 + SteamMath.hash(seed, i + 70)) % 1;
      final a = (28 + 14 * i) * math.pi / 180;
      final from = Offset(
        cx + side * h * (.082 + .075 * k),
        topY + h * (.050 + .006 * i) - h * .060 * k,
      );
      final dir = Offset(side * math.cos(a), -math.sin(a));
      streaks
        ..moveTo(from.dx, from.dy)
        ..lineTo(from.dx + dir.dx * h * .030, from.dy + dir.dy * h * .030);
    }
    final body = hot ? SteamTones.hotBody : SteamTones.coolHigh;
    c.drawPath(
      streaks,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .45 * (1 - p * .7))
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0080
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      streaks,
      Paint()
        ..color = body.withValues(alpha: .95 * (1 - p * .6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0044
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      drops,
      Paint()..color = body.withValues(alpha: .9 * (1 - p * .6)),
    );
    if (hot) {
      c.drawPath(
        sparks,
        Paint()..color = SteamTones.amber.withValues(alpha: .95 * (1 - p * .5)),
      );
      final k = p / .44;
      if (k < 1) {
        final w = h * (.12 + .30 * k);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, mouthY),
            width: w,
            height: w * .22,
          ),
          Paint()
            ..color = SteamTones.hotBody.withValues(alpha: .85 * (1 - k))
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .006,
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Billow (and a ride vent's burst)

  /// The soft cool cloud: tall, leaning on the air and drifting, its ink
  /// open (a full line only on the lower-left shade side and across the
  /// base, none on the upper right), a value ramp from the shaded base to a
  /// near-white crown that dissolves into detached puffs, a wide rolling
  /// foot, and a legible updraft: teal streaks inside, chevrons that grow as
  /// they climb, drift streaks at the flanks.
  ///
  /// [e] is the lift envelope; [cooled] (0 to 1) runs the burst's cream into
  /// the billow's blue. [height], when given, fixes the drawn height as a
  /// fraction of the way to [topY] (a ride vent's burst grows this same
  /// cloud); [crossing] slows the fade-in while it rises round a hot jet.
  static void billow(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double topY,
    double clock,
    int seed,
    double e,
    double cooled,
    bool rm, {
    double? height,
    bool crossing = false,
    double updraft = 1,
    double foot = 1,
  }) {
    final full = mouthY - topY;
    if (full < h * .03 || e <= 0) return;
    final hs = height ?? (.30 + .70 * SteamMath.smooth(e / .9));
    final rs = .72 + .28 * SteamMath.smooth(e / .6);
    final alpha = height != null
        ? 1.0
        : SteamMath.smooth(e / (crossing ? .55 : .20));
    final span = full * hs;
    if (span < h * .02) return;
    final top = mouthY - span;
    final big = math.min(h * .078 * rs, span * .28);
    final headY = top + big * .92;
    // Lean: about 4.5 degrees to the left (the wind of the backdrop's own
    // chimney smoke), with a slow sway.
    final sway = rm ? 0.0 : math.sin(clock * .8 + seed) * h * .008;
    final drift = rm ? 0.0 : math.sin(clock * .45 + seed * .7) * h * .006;
    double xAt(double y) =>
        cx - (mouthY - y) * .060 + sway * (mouthY - y) / full + drift;
    double rollY(int i) =>
        rm ? 0.0 : math.sin(clock * .9 + i * 1.7 + seed) * h * .004;

    final low = <_Lobe>[], mid = <_Lobe>[], high = <_Lobe>[];
    // A wide rolling foot.
    for (final s in const [-1.0, 1.0]) {
      low
        ..add(
          _Lobe(
            cx + s * h * .0865 * rs * foot,
            mouthY - h * .020,
            h * .0365 * rs * foot,
            h * .022,
          ),
        )
        ..add(
          _Lobe(
            cx + s * h * .056 * rs * foot,
            mouthY - h * .036,
            h * .034 * rs * foot,
            h * .026,
          ),
        );
    }
    // The column: lobes alternating up the sides, rolling slowly.
    const rows = [.16, .34, .52, .70, .86];
    for (var i = 0; i < rows.length; i++) {
      final y = mouthY - (mouthY - headY) * rows[i] + rollY(i);
      final s = i.isEven ? -1.0 : 1.0;
      final rr = h * (.044 + .003 * i) * rs;
      final lobe = _Lobe(
        xAt(y) + s * h * (.026 + .002 * i) * rs,
        y,
        rr,
        rr * 1.04,
      );
      final mate = _Lobe(
        xAt(y) - s * h * (.022 + .002 * i) * rs,
        y + h * .016,
        rr * .88,
        rr * .92,
      );
      (rows[i] < .4
            ? low
            : rows[i] < .75
            ? mid
            : high)
        ..add(lobe)
        ..add(mate);
    }
    // The crown, ragged, with shoulders. Anchored nearer the axis than the
    // body, so the top stays centred on the vent however the column leans.
    final hx = xAt(headY) + (cx - xAt(headY)) * .5;
    final ragged = _Lobe(
      hx - big * .36,
      headY - big * .40,
      big * .46,
      big * .42,
    );
    final shoulders = <_Lobe>[
      _Lobe(hx - big * .56, headY + big * .58, big * .58, big * .56),
      _Lobe(hx + big * .60, headY + big * .54, big * .56, big * .54),
    ];
    final main = _Lobe(hx, headY, big * 1.14, big * .94);
    high.add(ragged);
    final all = [...low, ...mid, ...high, ...shoulders, main];
    // A solid core so the body is never thinner than the lift reaches.
    final capHalf = h * .076 * rs;
    final capTop = top + h * .030;
    final cap = RRect.fromLTRBR(
      cx - capHalf + (xAt(capTop) - cx) * .45,
      capTop,
      cx + capHalf + (xAt(capTop) - cx) * .45,
      mouthY,
      Radius.circular(h * .02),
    );

    final hot0 = 1 - cooled;
    Color tone(Color cool, Color hot) => Color.lerp(cool, hot, hot0)!;
    final shade = tone(SteamTones.coolShade, SteamTones.hotShade);
    final lowC = Color.lerp(
      shade,
      tone(SteamTones.coolBody, SteamTones.hotBody),
      .55,
    )!;
    final midC = tone(SteamTones.coolBody, SteamTones.hotBody);
    final highC = Color.lerp(
      midC,
      tone(SteamTones.coolHigh, SteamTones.hotHigh),
      .6,
    )!;
    final crownC = tone(SteamTones.coolHigh, SteamTones.hotHigh);
    final a = .92 * alpha;
    final d = h * .0105;

    // Open ink: the union grown, slid down and left, so the line shows only
    // on the lower-left shade side and across the base.
    final rim = h * .0062;
    Path shape(
      List<_Lobe> ls, {
      double grow = 0,
      double dx = 0,
      double dy = 0,
    }) => _union(ls, grow: grow, dx: dx, dy: dy);
    final inkPath = shape(all, grow: rim, dx: -rim * .9, dy: rim * .8)
      ..addRRect(cap.inflate(rim).shift(Offset(-rim * .9, rim * .8)));
    c.drawPath(
      inkPath,
      Paint()..color = SteamTones.ink.withValues(alpha: .78 * alpha),
    );
    // A faint dark halo all round, so the pale edge holds on a bright sky.
    c.drawPath(
      shape(all, grow: h * .0022)..addRRect(cap.inflate(h * .0022)),
      Paint()..color = SteamTones.coolDeep.withValues(alpha: .5 * alpha),
    );
    c.drawPath(
      shape(all)..addRRect(cap),
      Paint()..color = shade.withValues(alpha: a),
    );
    c.drawPath(
      shape(low, grow: -d, dx: -d * .6, dy: -d),
      Paint()..color = lowC.withValues(alpha: a),
    );
    c.drawPath(
      shape(mid, grow: -d, dx: -d * .6, dy: -d)
        ..addRRect(cap.deflate(d).shift(Offset(-d * .6, -d))),
      Paint()..color = midC.withValues(alpha: a),
    );
    c.drawPath(
      shape(high, grow: -d * 1.1, dx: -d * .6, dy: -d),
      Paint()..color = highC.withValues(alpha: a),
    );
    for (final group in [
      shoulders,
      [main],
    ]) {
      final path = Path();
      for (final l in group) {
        path.addOval(
          Rect.fromCenter(
            center: Offset(l.x - d * .3, l.y - d * .45),
            width: (l.rx - d * .9) * 2,
            height: (l.ry - d * .9) * 2,
          ),
        );
      }
      c.drawPath(path, Paint()..color = highC.withValues(alpha: a));
      c.drawPath(
        path,
        Paint()
          ..color = SteamTones.coolDeep.withValues(alpha: .40 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0026,
      );
    }
    c.drawPath(
      shape([main], grow: -h * .026, dx: -h * .012, dy: -h * .016),
      Paint()..color = crownC.withValues(alpha: a),
    );
    if (updraft <= 0) return;

    // The updraft, legible: long teal streaks climbing inside the column.
    final streaks = Path();
    for (var i = 0; i < 4; i++) {
      final k = rm ? (i * .27 + .12) % 1 : (clock * .5 + i * .27) % 1;
      final y1 = mouthY - h * .05 - (span - h * .12) * k;
      final len = h * (.070 + .020 * (i % 2));
      final x = xAt(y1) + (i - 1.5) * h * .034 * rs;
      streaks
        ..moveTo(x, y1 + len)
        ..lineTo(x, y1);
    }
    c.drawPath(
      streaks,
      Paint()
        ..color = SteamTones.teal.withValues(
          alpha: .62 * math.min(1.0, e * 1.4) * updraft,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0062
        ..strokeCap = StrokeCap.round,
    );
    // Chevrons small at the lid, wide as they climb.
    final under = Path();
    final chevs = <(Path, double, double)>[];
    for (var i = 0; i < 3; i++) {
      final k = rm ? (i + .5) / 3 : (clock * .9 + i / 3) % 1;
      final y = mouthY - h * .045 - (span - h * .10) * k;
      final w = h * (.020 + .034 * k) * rs;
      final al = e * math.sin(k * math.pi).clamp(.25, 1) * alpha * updraft;
      final x = xAt(y);
      final chev = Path()
        ..moveTo(x - w, y + w * .55)
        ..lineTo(x, y - w * .35)
        ..lineTo(x + w, y + w * .55);
      under.addPath(chev, Offset.zero);
      chevs.add((chev, al, k));
    }
    c.drawPath(
      under,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .30 * alpha * updraft)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0135
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final (chev, al, k) in chevs) {
      c.drawPath(
        chev,
        Paint()
          ..color = SteamTones.teal.withValues(alpha: al)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * (.0070 + .003 * k)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    // Drift streaks at the flanks, at the bird's wing height: the air moving.
    if (!rm) {
      final drifts = Path();
      for (var i = 0; i < 4; i++) {
        final s = i.isEven ? -1.0 : 1.0;
        final k = (clock * .45 + i * .26) % 1;
        final y1 = mouthY - h * .06 - (span - h * .10) * k;
        final x = xAt(y1) + s * h * (.128 + .010 * (i ~/ 2));
        drifts
          ..moveTo(x, y1 + h * .030)
          ..lineTo(x, y1);
      }
      c.drawPath(
        drifts,
        Paint()
          ..color = SteamTones.coolHigh.withValues(alpha: .62 * e * updraft)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0042
          ..strokeCap = StrokeCap.round,
      );
    }
    // The crown dissolves into detached puffs that drift off and fade.
    final rimP = Path(), fillP = Path();
    const nPuff = 5;
    for (var i = 0; i < nPuff; i++) {
      final life = rm ? (i + .5) / nPuff : (clock * .5 + i / nPuff) % 1;
      final s = (i % 3 - 1.0);
      final r =
          h *
          (.011 - .006 * life) *
          alpha *
          SteamMath.smooth((e - .4) / .3) *
          updraft;
      if (r <= h * .001) continue;
      final o = Offset(
        hx + s * big * (.55 + .5 * life) + math.sin(life * 3 + i) * h * .008,
        math.max(top - h * .008 + r, headY - big * (.55 + .65 * life)),
      );
      rimP.addOval(Rect.fromCircle(center: o, radius: r + h * .0026));
      fillP.addOval(Rect.fromCircle(center: o, radius: r));
    }
    c.drawPath(
      rimP,
      Paint()..color = SteamTones.coolDeep.withValues(alpha: .6 * alpha),
    );
    c.drawPath(fillP, Paint()..color = crownC.withValues(alpha: alpha));
  }
}
