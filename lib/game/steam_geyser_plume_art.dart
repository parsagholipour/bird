import 'dart:math' as math;
import 'dart:ui';

import 'steam_geyser_kit.dart';

/// The steam of a vent, one painter per phase: the hiss's warning (glow,
/// pressure rings, a dashed ghost column, spitting puffs), the burst's tall
/// scalding jet with its white-hot core, and the billow's soft cloud with its
/// teal lift chevrons.
///
/// Flat discs only. A plume is a handful of batched paths (the union of all
/// its rims in ink, then the union of all its bodies, then shade, crease and
/// gloss), so only the silhouette keeps ink and a whole plume costs around a
/// dozen draws. No blur, no `saveLayer`, no shader. Every measurement is in
/// viewport heights times [h].
abstract final class SteamPlumeArt {
  // ---------------------------------------------------------------------
  // Light

  /// Warm (or cool) light pooled on the night air around a mouth: three
  /// stacked translucent discs, not a gradient; the innermost (r .16 h,
  /// alpha .20 at full heat) is the pool on the roof at the lid.
  static void glow(Canvas c, double h, Offset at, double heat, Color tone) {
    if (heat <= 0) return;
    final paint = Paint();
    for (final (r, a) in const [(.36, .05), (.24, .08), (.16, .20)]) {
      c.drawCircle(at, h * r, paint..color = tone.withValues(alpha: a * heat));
    }
  }

  /// The burst's own light on the night around it: two big warm discs that
  /// fade over the first 0.25 s (skipped in Reduced Motion).
  static void flash(Canvas c, double h, double cx, double mouthY, double p) {
    final k = 1 - p / .5;
    if (k <= 0) return;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx, mouthY - h * .10),
        width: h * 1.0,
        height: h * .66,
      ),
      Paint()..color = const Color(0xffffb23a).withValues(alpha: .13 * k),
    );
  }

  // ---------------------------------------------------------------------
  // Hiss

  /// Wisps leaking from the mouth: lazy when asleep, denser under pressure.
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
    final tiers = [Path(), Path()];
    for (var i = 0; i < n; i++) {
      final life = rm
          ? (i + .5) / n
          : (clock * (.9 + SteamMath.hash(seed, i) * .5) +
                    SteamMath.hash(seed, i + 9)) %
                1;
      final drift = (SteamMath.hash(seed, i + 3) - .5) * h * .05 * (.4 + life);
      final r = h * (.011 + .02 * life) * (.6 + p);
      tiers[math.min(1, (life * 2).floor())].addOval(
        Rect.fromCircle(
          center: Offset(cx + drift, mouthY - life * h * (.05 + .13 * p)),
          radius: r,
        ),
      );
    }
    final paint = Paint();
    for (var k = 0; k < 2; k++) {
      c.drawPath(
        tiers[k],
        paint
          ..color = tone.withValues(alpha: (.78 - k * .36) * (.55 + .45 * p)),
      );
    }
  }

  /// Puffs spitting out sideways as pressure builds, with short hiss lines
  /// beside them: the hiss you can see. A cluster of three discs a side
  /// (rim, then body) and one path of dashes.
  static void jets(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double p,
    double clock,
    bool rm,
    Color body,
    Color tone,
  ) {
    final a = SteamMath.smooth(p / .2);
    if (a <= 0) return;
    final spit = rm ? 1.0 : .82 + .18 * math.sin(clock * 29);
    final rim = Path(), fill = Path(), lines = Path();
    for (final side in [-1.0, 1.0]) {
      // Puffs born at the lid's edge that swell as they climb away and
      // shrink to nothing: three a side, at different ages (a steady set,
      // mid-life, in Reduced Motion).
      for (var k = 0; k < 3; k++) {
        final life = rm ? .35 + .15 * k : (clock * (1.3 + .8 * p) + k / 3) % 1;
        final o = Offset(
          cx + side * h * (.026 + .050 * life * (.6 + .4 * p)),
          mouthY - h * (.006 + .072 * life * (.6 + .4 * p)),
        );
        final r =
            h *
            (.0045 + .0085 * math.pow(math.sin(life * math.pi), .7)) *
            (.7 + .6 * p);
        rim.addOval(Rect.fromCircle(center: o, radius: r + h * .0030));
        fill.addOval(Rect.fromCircle(center: o, radius: r));
      }
      // Hiss lines fan out beyond them.
      for (var k = 0; k < 2; k++) {
        final ang = .05 + k * .40;
        final len = h * (.016 + .026 * p) * spit;
        final from = Offset(
          cx + side * h * (.105 + .014 * k),
          mouthY - h * (.014 + .030 * k),
        );
        final dir = Offset(side * math.cos(ang), -math.sin(ang));
        lines
          ..moveTo(from.dx, from.dy)
          ..lineTo(from.dx + dir.dx * len, from.dy + dir.dy * len);
      }
    }
    c.drawPath(rim, Paint()..color = SteamTones.ink.withValues(alpha: .85 * a));
    c.drawPath(fill, Paint()..color = body.withValues(alpha: a));
    c.drawPath(
      lines,
      Paint()
        ..color = tone.withValues(alpha: .9 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0055
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Pressure waves leaving the mouth: nested arcs rising and widening over
  /// the vent, faster as the hiss builds (a steady set in Reduced Motion).
  static void rings(
    Canvas c,
    double h,
    double cx,
    double y,
    double p,
    double clock,
    bool rm,
    Color tone,
  ) {
    final a = SteamMath.smooth(p / .15);
    if (a <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .0055
      ..strokeCap = StrokeCap.round;
    final under = Path();
    final arcs = <(Path, double)>[];
    for (var i = 0; i < 3; i++) {
      final life = rm ? (i + .5) / 3 : (clock * (.9 + 1.6 * p) + i / 3) % 1;
      final r = h * (.045 + .13 * life);
      final rect = Rect.fromCircle(center: Offset(cx, y - h * .012), radius: r);
      final arc = Path()..addArc(rect, math.pi * 1.16, math.pi * .68);
      under.addPath(arc, Offset.zero);
      arcs.add((arc, a * (1 - life) * (.5 + .5 * p)));
    }
    c.drawPath(
      under,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .22 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0105
        ..strokeCap = StrokeCap.round,
    );
    for (final (arc, alpha) in arcs) {
      c.drawPath(arc, paint..color = tone.withValues(alpha: alpha));
    }
  }

  /// The reach capsule (a dome over straight sides) down to [bottom].
  static Path _capsule(
    double cx,
    double half,
    double dome,
    double topY,
    double bottom,
  ) => Path()
    ..moveTo(cx - half, bottom)
    ..lineTo(cx - half, topY + dome)
    ..arcToPoint(
      Offset(cx + half, topY + dome),
      radius: Radius.circular(half),
      clockwise: true,
    )
    ..lineTo(cx + half, bottom)
    ..close();

  /// The shape the plume will take: a dashed capsule filling with pressure,
  /// a dome over it and a tick where the reach ends. [tone] is amber for a
  /// hot vent and teal for a soft one.
  static void ghost(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double topY,
    double p,
    double clock,
    bool rm,
    Color tone,
    Color body, {
    required bool flash,
  }) {
    final half = h * .072;
    final dome = half * .9;
    final fadeIn = SteamMath.smooth(p / .12);
    if (fadeIn <= 0) return;
    final span = mouthY - (topY + dome);
    if (span <= 0) return;
    final rails = Path();
    final dashes = math.min(14, math.max(3, (span / (h * .05)).round()));
    for (var i = 0; i < dashes; i++) {
      final a = topY + dome + span * i / dashes;
      final b = a + span / dashes * .58;
      rails
        ..moveTo(cx - half, a)
        ..lineTo(cx - half, b)
        ..moveTo(cx + half, a)
        ..lineTo(cx + half, b);
    }
    rails
      ..moveTo(cx - half, topY + dome)
      ..arcToPoint(
        Offset(cx + half, topY + dome),
        radius: Radius.circular(half),
        clockwise: true,
      );
    // The last 0.2 s before the burst the ghost snaps bright (a steady
    // bright in Reduced Motion).
    final snap = flash
        ? (rm ? 1.0 : (math.sin(clock * 46) > 0 ? 1.0 : .55))
        : 0.0;
    // The whole capsule is washed pale warm (or cool): three stacked bands
    // make a gradient with no shader, alpha .10 at the mouth, .18 midway
    // and .28 under the dome.
    final wash = Color.lerp(body, tone, .12)!;
    final total = mouthY - topY;
    // A dark underlay so the pale wash stands out from lit windows.
    c.drawPath(
      _capsule(cx, half, dome, topY, mouthY),
      Paint()..color = SteamTones.ink.withValues(alpha: .16 * fadeIn),
    );
    final washPaint = Paint();
    // (the top band brightens as the pressure builds)
    for (final (from, alpha) in [
      (0.0, .10),
      (1 / 3, .08),
      (2 / 3, .10 + .10 * p + .08 * snap),
    ]) {
      c.drawPath(
        _capsule(cx, half, dome, topY, mouthY - total * from),
        washPaint..color = wash.withValues(alpha: alpha * fadeIn),
      );
    }
    c.drawPath(
      rails,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .7 * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0180
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      rails,
      Paint()
        ..color = Color.lerp(
          body,
          tone,
          .25 * snap,
        )!.withValues(alpha: (.80 + .2 * p) * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0105
        ..strokeCap = StrokeCap.round,
    );
    // A bar at the top marks where the reach ends.
    final tick = Path()
      ..moveTo(cx - half * 1.3, topY + dome * .15)
      ..lineTo(cx + half * 1.3, topY + dome * .15);
    c.drawPath(
      tick,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .55 * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0125
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      tick,
      Paint()
        ..color = tone.withValues(alpha: (.45 + .55 * p) * fadeIn)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0065
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---------------------------------------------------------------------
  // Puff columns

  /// A column of puffs from [mouthY] up to a crowned top at [topY]. The
  /// crown's top edge IS the hit box's top.
  static List<(Offset, double)> _column(
    double cx,
    double mouthY,
    double topY,
    double h, {
    required double crownR,
    required double baseR,
    required double topR,
    required double spacing,
    required double side,
    required double swayRate,
    required double clock,
    required int seed,
    required double lobe,
  }) {
    final crownY = topY + crownR;
    final bodyTop = crownY + crownR * .35, bodyBase = mouthY - h * .012;
    final span = bodyBase - bodyTop;
    final puffs = <(Offset, double)>[];
    final n = math.max(2, (span / spacing).round());
    for (var i = 0; i < n; i++) {
      final u = (i + .5) / n;
      final off =
          (i.isEven ? -1.0 : 1.0) * side * (.6 + SteamMath.hash(seed, i));
      final sway = math.sin(u * 5.3 + clock * swayRate + seed) * h * .010 * u;
      final grow = .92 + .16 * SteamMath.hash(seed, i + 70);
      puffs.add((
        Offset(cx + off + sway, bodyBase - span * u),
        (baseR + (topR - baseR) * u) * grow,
      ));
    }
    puffs
      ..add((Offset(cx - lobe, crownY + crownR * .34), crownR * .80))
      ..add((Offset(cx + lobe, crownY + crownR * .34), crownR * .80))
      ..add((Offset(cx, crownY), crownR));
    return puffs;
  }

  static Path _discs(List<(Offset, double)> puffs, [double grow = 0]) {
    final path = Path();
    for (final (o, r) in puffs) {
      path.addOval(Rect.fromCircle(center: o, radius: r + grow));
    }
    return path;
  }

  /// Volume for a flat puff, batched: a shade disc low-right inside each
  /// puff and a gloss arc along its upper-left rim.
  static void _shadeAndGloss(
    Canvas c,
    double h,
    List<(Offset, double)> puffs,
    Color shade,
    double shadeAlpha,
    double glossAlpha,
  ) {
    final shadePath = Path(), glossPath = Path();
    for (final (o, r) in puffs) {
      shadePath.addOval(
        Rect.fromCircle(center: o + Offset(r * .22, r * .26), radius: r * .62),
      );
      glossPath.addArc(
        Rect.fromCircle(center: o, radius: r * .76),
        -2.75,
        1.05,
      );
    }
    c.drawPath(shadePath, Paint()..color = shade.withValues(alpha: shadeAlpha));
    c.drawPath(
      glossPath,
      Paint()
        ..color = const Color(0xffffffff).withValues(alpha: glossAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0046
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A path smoothly through [pts] (quadratics through the midpoints).
  static Path _smooth(List<Offset> pts, {bool close = true}) {
    final path = Path()
      ..moveTo(
        (pts.first.dx + pts.last.dx) / 2,
        (pts.first.dy + pts.last.dy) / 2,
      );
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      path.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    if (close) path.close();
    return path;
  }

  /// A flame-like tongue from [baseY] up to [tipY]: broad at the nozzle,
  /// tapering to a rounded point, its edges licking with the clock.
  static Path _tongue(
    double cx,
    double baseY,
    double tipY,
    double halfBase,
    double clock,
    double phase,
    double h,
  ) {
    const n = 7;
    final left = <Offset>[], right = <Offset>[];
    for (var j = 0; j <= n; j++) {
      final u = j / n;
      final w =
          halfBase *
          math.pow(1 - u, .85) *
          (1 + .10 * math.sin(u * 9 + clock * 10 + phase));
      final x = cx + math.sin(u * 5 + clock * 7 + phase) * h * .0045 * u;
      final y = baseY - (baseY - tipY) * u;
      left.add(Offset(x - w, y));
      right.add(Offset(x + w, y));
    }
    return _smooth([...left, ...right.reversed]);
  }

  // ---------------------------------------------------------------------
  // Burst

  /// The scalding jet: a scalloped cream column over an amber root, a hot
  /// core of amber and white streaming up the middle and a crown that
  /// mushrooms at the top, inked once around its silhouette.
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
    final span0 = mouthY - topY;
    if (span0 < h * .03) return;
    final crownR = math.min(h * .088, span0 * .42);
    final puffs =
        _column(
            cx,
            mouthY,
            topY,
            h,
            crownR: crownR,
            baseR: h * .060,
            topR: h * .078,
            spacing: h * .066,
            side: h * .016,
            swayRate: 5.2,
            clock: clock,
            seed: seed,
            lobe: h * .042,
          )
          // The jet flares where it leaves the roof: two skirt puffs at the
          // mouth (far below anywhere the bird flies).
          ..add((Offset(cx - h * .072, mouthY - h * .022), h * .044))
          ..add((Offset(cx + h * .072, mouthY - h * .022), h * .044));
    final crownY = topY + crownR;
    // Down the middle runs a capsule so the solid body is never narrower
    // than the hit box however the puffs fall.
    final capTop = crownY, capHalf = h * .064;
    final capsule = RRect.fromLTRBR(
      cx - capHalf,
      capTop,
      cx + capHalf,
      mouthY,
      Radius.circular(capHalf),
    );
    final rimW = h * .0085;
    c.drawPath(
      _discs(puffs, rimW)..addRRect(capsule.inflate(rimW)),
      Paint()..color = SteamTones.ink,
    );

    // Bodies in three bands: amber root, warm middle, cream top.
    final root = <(Offset, double)>[],
        mid = <(Offset, double)>[],
        top = <(Offset, double)>[];
    for (final puff in puffs) {
      final u = ((mouthY - puff.$1.dy) / span0).clamp(0.0, 1.0);
      (u < .28
              ? root
              : u < .62
              ? mid
              : top)
          .add(puff);
    }
    final body = Paint()..color = SteamTones.hotBody;
    c.drawRRect(capsule, body);
    c.drawPath(_discs(top), body);
    c.drawPath(
      _discs(mid),
      body..color = Color.lerp(SteamTones.hotBody, SteamTones.hotRoot, .42)!,
    );
    c.drawPath(
      _discs(root),
      body..color = Color.lerp(SteamTones.hotBody, SteamTones.hotRoot, .9)!,
    );
    _shadeAndGloss(c, h, puffs, SteamTones.hotShade, .62, .9);

    // The hot core: an amber tongue with a white-hot one inside it.
    final coreBase = mouthY - h * .014;
    final coreTop = crownY + crownR * .55;
    if (coreBase - coreTop > h * .04) {
      c.drawPath(
        _tongue(cx, coreBase, coreTop, h * .040, clock, 0, h),
        Paint()..color = SteamTones.amber.withValues(alpha: .92),
      );
      c.drawPath(
        _tongue(
          cx,
          coreBase + h * .004,
          coreTop + (coreBase - coreTop) * .22,
          h * .024,
          clock,
          1.7,
          h,
        ),
        Paint()..color = SteamTones.hotHigh,
      );
    }
    // Two bright seams of jet streaming up the column.
    final seam = Path();
    for (final k in [-1.0, 1.0]) {
      seam.moveTo(cx + k * h * .050, mouthY - h * .05);
      for (var j = 1; j <= 6; j++) {
        final u = j / 6;
        seam.lineTo(
          cx +
              k * h * (.050 - .010 * u) +
              math.sin(u * 6 + clock * 7 + k) * h * .005,
          mouthY - h * .05 - (mouthY - h * .05 - crownY - crownR * .55) * u,
        );
      }
    }
    c.drawPath(
      seam,
      Paint()
        ..color = const Color(0xffffffff).withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0050
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Sparks and droplets thrown from the crown in the burst's first moments,
  /// and a shock ring over the roof.
  static void spray(
    Canvas c,
    double h,
    double cx,
    double topY,
    double mouthY,
    double p,
    int seed,
    bool rm,
  ) {
    final drops = Path(), sparks = Path();
    for (var i = 0; i < 8; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final k = (p * 1.6 + SteamMath.hash(seed, i + 40)) % 1;
      final o = Offset(
        cx + side * h * (.08 + .07 * k + SteamMath.hash(seed, i) * .03),
        topY + h * (.02 + .08 * k * k) - (i >= 6 ? h * .05 : 0),
      );
      final r = h * .0072 * (1 - .5 * k);
      if (i < 6) {
        drops.addOval(Rect.fromCircle(center: o, radius: r));
      } else {
        // A four-point ember.
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
    c.drawPath(
      drops,
      Paint()..color = SteamTones.hotBody.withValues(alpha: .9 * (1 - p * .6)),
    );
    c.drawPath(
      sparks,
      Paint()..color = SteamTones.amber.withValues(alpha: .95 * (1 - p * .5)),
    );
    // The shock ring: a flat ripple over the roof in the first 0.22 s, and a
    // white-hot flash at the mouth in the first 0.07 s.
    final flash = 1 - p / .14;
    if (flash > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY - h * .008),
          width: h * (.10 + .10 * (1 - flash)),
          height: h * .05,
        ),
        Paint()..color = SteamTones.hotHigh.withValues(alpha: .9 * flash),
      );
    }
    final k = p / .44;
    if (k < 1) {
      final w = h * (.12 + .30 * k);
      c.drawOval(
        Rect.fromCenter(center: Offset(cx, mouthY), width: w, height: w * .22),
        Paint()
          ..color = SteamTones.hotBody.withValues(alpha: .85 * (1 - k))
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .006,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Billow

  /// The soft cloud: fatter puffs in cool blue-white with a thin rim, swelling
  /// out of the vent as the lift comes in and sinking back as it dies. [e] is
  /// the lift envelope; [cooled] (0 to 1) runs the burst's cream into the
  /// billow's blue as the burst collapses.
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
    bool rm,
  ) {
    if (mouthY - topY < h * .03 || e <= 0) return;
    final full = _column(
      cx,
      mouthY,
      topY,
      h,
      crownR: math.min(h * .112, (mouthY - topY) * .42),
      baseR: h * .070,
      topR: h * .094,
      spacing: h * .082,
      side: h * .026,
      swayRate: 2.4,
      clock: clock,
      seed: seed,
      lobe: h * .058,
    );
    // A skirt of puffs at the mouth keeps the cloud broad at the foot.
    final crown = full.last;
    full
      ..removeLast()
      ..add((Offset(cx - h * .092, mouthY - h * .026), h * .052))
      ..add((Offset(cx + h * .092, mouthY - h * .026), h * .052))
      ..add(crown);
    // The cloud swells out of the vent and sinks back into it: the column
    // contracts toward the mouth as the lift fades, so it never breaks up.
    final hs = .30 + .70 * SteamMath.smooth(e / .9);
    final rs = .72 + .28 * SteamMath.smooth(e / .6);
    final alpha = SteamMath.smooth(e / .35);
    final puffs = [
      for (final (o, r) in full)
        (Offset(o.dx, mouthY - (mouthY - o.dy) * hs), r * rs),
    ];
    // A capsule down the middle keeps the body at least as wide as the lift
    // reaches however the puffs fall (scaled with the swell, like the puffs).
    final capHalf = h * .074 * rs;
    final capTop = mouthY - (mouthY - full.last.$1.dy) * hs;
    final capsule = RRect.fromLTRBR(
      cx - capHalf,
      capTop,
      cx + capHalf,
      mouthY,
      Radius.circular(capHalf),
    );
    final rim = h * .0060;
    c.drawPath(
      _discs(puffs, rim)..addRRect(capsule.inflate(rim)),
      Paint()..color = SteamTones.ink.withValues(alpha: .8 * alpha * alpha),
    );
    final body = Color.lerp(SteamTones.hotBody, SteamTones.coolBody, cooled)!;
    final shadeTone = Color.lerp(
      SteamTones.hotShade,
      SteamTones.coolShade,
      cooled,
    )!;
    c.drawPath(
      _discs(puffs)..addRRect(capsule),
      Paint()..color = body.withValues(alpha: alpha),
    );
    _shadeAndGloss(c, h, puffs, shadeTone, .55 * alpha, .85 * alpha);
    // Little puffs break off the crown and drift away: follow-through.
    final crownTop = mouthY - (mouthY - topY) * hs;
    final rim2 = Path(), fill2 = Path();
    for (var i = 0; i < (rm ? 0 : 3); i++) {
      final life = (clock * .55 + i / 3) % 1;
      final o = Offset(
        cx +
            (SteamMath.hash(seed, i + 5) - .5) * h * .13 +
            math.sin(life * 4 + i) * h * .02,
        crownTop - h * (.03 + .09 * life),
      );
      final r = h * (.0085 - .004 * life) * alpha;
      if (r <= 0) continue;
      rim2.addOval(Rect.fromCircle(center: o, radius: r + h * .0032));
      fill2.addOval(Rect.fromCircle(center: o, radius: r));
    }
    c.drawPath(
      rim2,
      Paint()..color = SteamTones.ink.withValues(alpha: .7 * alpha),
    );
    c.drawPath(fill2, Paint()..color = body.withValues(alpha: alpha));
  }

  /// Three teal chevrons climbing the billow: the updraft you can ride.
  static void chevrons(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double topY,
    double e,
    double clock,
    bool rm,
  ) {
    final span = mouthY - topY - h * .08;
    if (span <= 0 || e <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .009
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < 3; i++) {
      final k = rm ? (i + .5) / 3 : (clock * .9 + i / 3) % 1;
      final y = mouthY - h * .04 - span * k;
      final w = h * .032;
      paint.color = SteamTones.teal.withValues(
        alpha: e * math.sin(k * math.pi).clamp(.25, 1),
      );
      c.drawPath(
        Path()
          ..moveTo(cx - w, y + w * .55)
          ..lineTo(cx, y - w * .35)
          ..lineTo(cx + w, y + w * .55),
        paint,
      );
    }
  }
}
