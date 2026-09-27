import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Three opaque garden structures, clipped to the collision rectangle.
///
/// `appearance % 3` selects a brass conservatory, a carved terracotta blossom
/// column, or a tied bamboo shrine. Top and bottom solids share that identity
/// and mirror around the flight lane: every piece ends in a light capstone
/// with an inked rim, so the solid edge reads first against any sky.
abstract final class GardenStructuresDesign {
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
    final sway = reducedMotion ? 0.0 : math.sin(clock * 1.15) * 1.8;
    final sky = SkyPalette.at(clock);
    final v = appearance % 3;
    final motif = v < 0 ? v + 3 : v;
    final g = _Geo(r, top);

    c.save();
    c.clipRect(r);
    final ink = switch (motif) {
      0 => _conservatory(c, g, sway, cleared, perfect, accent, sky),
      1 => _terracotta(c, g, sway, cleared, perfect, accent, sky),
      _ => _bamboo(c, g, sway, cleared, perfect, accent, sky),
    };
    _seal(c, g, cleared, perfect);
    _outline(c, g, ink);
    c.restore();
  }
}

/// Shared measurements. Distances are measured from the rim (the collision
/// edge facing the flight lane) toward the screen edge.
class _Geo {
  _Geo(this.r, this.top)
    : line = (r.width * .022).clamp(1.5, 2.6),
      cap = math.min((r.width * .11).clamp(6.0, 13.0), r.height * .45);
  final Rect r;
  final bool top;
  final double line, cap;

  double get w => r.width;
  double get h => r.height;
  double y(double dist) => top ? r.bottom - dist : r.top + dist;

  Rect band(double a, double b, [double? left, double? right]) {
    final y1 = y(a), y2 = y(b);
    return Rect.fromLTRB(
      left ?? r.left,
      math.min(y1, y2),
      right ?? r.right,
      math.max(y1, y2),
    );
  }
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

void _fill(Canvas c, Rect b, Color color) {
  if (!(b.width > 0) || !(b.height > 0)) return;
  c.drawRect(b, Paint()..color = color);
}

/// Capstone at the rim: body, a lit bevel next to the edge, and a shadow
/// where it meets the structure below.
void _cap(Canvas c, _Geo g, Color body, Color lit, Color shade, Color ink) {
  final cap = g.cap;
  if (cap <= 0) return;
  _fill(c, g.band(0, cap), body);
  _fill(c, g.band(g.line, g.line + cap * .26), lit);
  _fill(c, g.band(cap * .74, cap), shade);
  if (g.h > cap + 1) {
    _fill(c, g.band(cap, math.min(g.h, cap + g.line * .8)), ink);
  }
}

/// Inked silhouette: both sides and, strongest, the collision edge.
void _outline(Canvas c, _Geo g, Color ink) {
  final r = g.r;
  _fill(c, Rect.fromLTWH(r.left, r.top, g.line, r.height), ink);
  _fill(c, Rect.fromLTWH(r.right - g.line, r.top, g.line, r.height), ink);
  _fill(c, g.band(0, math.min(g.h, g.line * 1.2)), ink);
}

Color _conservatory(
  Canvas c,
  _Geo g,
  double sway,
  bool cleared,
  bool perfect,
  Color accent,
  SkyPalette sky,
) {
  final r = g.r;
  final w = g.w;
  final h = g.h;
  var glass = _mix(_mix(SkyColors.teal, accent, .3), SkyColors.ink, .22);
  var lit = _mix(glass, SkyColors.mint, .5);
  if (perfect) {
    glass = _mix(glass, SkyColors.gold, .1);
    lit = _mix(lit, SkyColors.yellow, .14);
  } else if (cleared) {
    glass = _mix(glass, SkyColors.mint, .18);
    lit = _mix(lit, SkyColors.cream, .1);
  }
  lit = _mix(lit, sky.haze, .08);
  final deepGlass = _mix(glass, SkyColors.ink, .24);
  final brass = _mix(SkyColors.gold, SkyColors.yellow, perfect ? .5 : .28);
  final brassLit = _mix(brass, SkyColors.cream, .5);
  final brassDeep = _mix(SkyColors.gold, SkyColors.ink, .34);
  final ink = _mix(_mix(SkyColors.ink, SkyColors.gold, .18), sky.land, .1);

  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        colors: [lit, glass, deepGlass],
        stops: const [0, .45, 1],
      ).createShader(r),
  );
  if (w < 8 || h < 8) return ink;

  final stile = (w * .12).clamp(3.0, w * .3);
  final glassL = r.left + stile;
  final glassR = r.right - stile;
  final glassW = glassR - glassL;
  final mid = r.center.dx;
  final bar = (w * .06).clamp(2.0, stile * .8);
  final cap = g.cap;

  // Fanlight: a half-round window of radiating panes right under the cap.
  // Skip the fanlight when a short piece would squash it into a sliver.
  final crownRoom = math.max(0.0, h - cap - bar) * .6;
  final crown = glassW < 8 || crownRoom < glassW * .4
      ? 0.0
      : math.min(glassW * .5, crownRoom);
  final pitch = math.max(36.0, w * .95);
  final first = cap + (crown >= 6 ? crown + bar : pitch * .6);

  // Diagonal sky reflections, one per pane, drawn before the mullions hide
  // their ends. Tied to rows measured from the rim so they never tile oddly.
  final glint = Paint()
    ..color = _mix(lit, SkyColors.cream, .45)
    ..strokeWidth = math.max(1.6, glassW * .09)
    ..strokeCap = StrokeCap.round;
  final thin = Paint()
    ..color = _mix(lit, SkyColors.cream, .3)
    ..strokeWidth = math.max(1.0, glassW * .04)
    ..strokeCap = StrokeCap.round;
  final paneW = (glassW - bar) / 2;
  for (var d = first; d < h; d += pitch) {
    final span = math.min(pitch - bar, h - d);
    if (span < 8 || paneW < 4) break;
    final rise = math.min(span * .5, paneW * 1.2);
    final at = g.y(d + span * .3);
    final x0 = glassL + paneW * .2 + sway * .6;
    c.drawLine(
      Offset(x0, at + rise * .5),
      Offset(x0 + paneW * .55, at - rise * .5),
      glint,
    );
    c.drawLine(
      Offset(x0 + paneW * .4, at + rise * .6),
      Offset(x0 + paneW * .7, at + rise * .1),
      thin,
    );
  }

  // Frame: lit left stile, shaded right stile, mullion and transoms.
  _fill(c, Rect.fromLTWH(r.left, r.top, stile, h), brass);
  _fill(c, Rect.fromLTWH(r.left + stile * .3, r.top, stile * .28, h), brassLit);
  _fill(c, Rect.fromLTWH(r.right - stile, r.top, stile, h), brassDeep);
  if (glassW >= 8) {
    _fill(c, Rect.fromLTWH(mid - bar / 2, r.top, bar, h), brass);
    _fill(c, Rect.fromLTWH(mid - bar / 2, r.top, bar * .35, h), brassLit);
    for (var d = first; d < h; d += pitch) {
      final b = g.band(d - bar, d, glassL, glassR);
      _fill(c, b, brass);
      _fill(c, g.band(d - bar, d - bar * .6, glassL, glassR), brassDeep);
    }
  }

  if (crown >= 6) {
    final base = g.y(cap);
    final apex = g.y(cap + crown);
    final hub = Offset(mid, base);
    final ring = Paint()
      ..color = brass
      ..style = PaintingStyle.stroke
      ..strokeWidth = bar;
    final arc = Rect.fromCenter(
      center: hub,
      width: glassW - bar,
      height: (crown - bar / 2) * 2,
    );
    // Spokes of the fanlight fan out from a small brass hub.
    final spoke = Paint()
      ..color = brass
      ..strokeWidth = bar * .75;
    for (final a in const [.28, .5, .72]) {
      final t = a * math.pi;
      c.drawLine(
        hub,
        Offset(
          mid - math.cos(t) * glassW * .5,
          base + (apex - base) * math.sin(t),
        ),
        spoke,
      );
    }
    c.drawArc(arc, g.top ? math.pi : 0, math.pi, false, ring);
    _fill(c, g.band(cap + crown, cap + crown + bar, glassL, glassR), brass);
    c.drawCircle(hub, math.min(crown * .28, bar * 1.6), Paint()..color = brass);
    c.drawCircle(
      hub,
      math.min(crown * .14, bar * .8),
      Paint()..color = brassDeep,
    );
  }

  _cap(c, g, brass, brassLit, brassDeep, ink);
  // Rivets along the brass cap.
  if (cap >= 7) {
    final rivet = Paint()..color = brassDeep;
    final shine = Paint()..color = brassLit;
    final ry = g.y(cap * .55);
    for (final fx in const [.2, .8]) {
      final at = Offset(r.left + w * fx, ry);
      c.drawCircle(at, cap * .14, rivet);
      c.drawCircle(at - Offset(cap * .04, cap * .04), cap * .06, shine);
    }
  }
  return ink;
}

Color _terracotta(
  Canvas c,
  _Geo g,
  double sway,
  bool cleared,
  bool perfect,
  Color accent,
  SkyPalette sky,
) {
  final r = g.r;
  final w = g.w;
  final h = g.h;
  var clay = _mix(SkyColors.sand, SkyColors.coral, .5);
  var deep = _mix(SkyColors.coralDeep, SkyColors.ink, .3);
  var highlight = _mix(_mix(SkyColors.cream, SkyColors.sand, .4), sky.haze, .1);
  if (perfect) {
    clay = _mix(clay, SkyColors.gold, .14);
    highlight = _mix(highlight, SkyColors.gold, .12);
  } else if (cleared) {
    clay = _mix(clay, SkyColors.mint, .1);
  }
  deep = _mix(deep, sky.land, .08);
  final groove = _mix(clay, deep, .62);
  final ridge = _mix(clay, SkyColors.cream, .42);
  final stone = _mix(SkyColors.cream, SkyColors.sand, .3);
  final stoneLit = _mix(SkyColors.cream, SkyColors.white, .4);
  final stoneShade = _mix(SkyColors.sand, SkyColors.rock, .35);
  final petal = _mix(SkyColors.coral, SkyColors.cream, .34);
  final shade = _mix(SkyColors.coralDeep, SkyColors.sand, .12);
  final heart = perfect
      ? SkyColors.gold
      : (cleared ? _mix(accent, SkyColors.mint, .4) : accent);
  final ink = _mix(_mix(SkyColors.ink, SkyColors.coralDeep, .32), sky.land, .1);

  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        colors: [highlight, clay, deep],
        stops: const [0, .45, 1],
      ).createShader(r),
  );
  if (w < 8 || h < 8) return ink;

  // Two carved flutes: a shadowed groove with a sunlit ridge on its right.
  final fluteW = (w * .085).clamp(2.4, 9.0);
  for (final fx in const [.3, .7]) {
    final x = r.left + w * fx - fluteW / 2;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, r.top - fluteW, fluteW, h + fluteW * 2),
        Radius.circular(fluteW / 2),
      ),
      Paint()..color = groove,
    );
    _fill(
      c,
      Rect.fromLTWH(x + fluteW, r.top, math.max(1.0, fluteW * .4), h),
      ridge,
    );
  }

  final cap = g.cap;
  final collar = math.max(3.0, cap * .5);
  final radius = math.min(w * .4, math.max(0.0, h - cap - collar) * .5 - 2);
  final medallion = radius >= 4 ? radius * 2 + 6 : 0.0;
  final top0 = cap + medallion;

  // Stone collars pace the column, measured from the rim so the first always
  // sits right under the medallion.
  final step = math.max(w * 1.3, 44.0);
  for (var d = top0; d + collar < h; d += step) {
    _fill(c, g.band(d, d + collar), stone);
    _fill(c, g.band(d, d + collar * .3), stoneLit);
    _fill(c, g.band(d + collar * .7, d + collar), stoneShade);
    _fill(c, g.band(d + collar, d + collar + g.line * .7), ink);
    _fill(c, g.band(d - g.line * .7, d), ink);
  }

  if (radius >= 4) {
    _blossom(
      c,
      Offset(r.center.dx, g.y(cap + 3 + radius)),
      radius,
      deep,
      petal,
      shade,
      heart,
      sway * .35,
      ink,
    );
  }

  _cap(c, g, stone, stoneLit, stoneShade, ink);
  return ink;
}

void _blossom(
  Canvas c,
  Offset at,
  double radius,
  Color bed,
  Color petal,
  Color shade,
  Color heart,
  double glint,
  Color ink,
) {
  c.drawCircle(at, radius, Paint()..color = ink);
  c.drawCircle(at, radius * .9, Paint()..color = bed);
  c.save();
  c.translate(at.dx, at.dy);
  final petalPaint = Paint();
  for (var i = 0; i < 6; i++) {
    c.save();
    c.rotate(i * math.pi / 3);
    petalPaint.color = i.isEven ? petal : shade;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(glint, -radius * .42),
        width: radius * .66,
        height: radius * .8,
      ),
      petalPaint,
    );
    c.restore();
  }
  c.restore();
  c.drawCircle(at, radius * .3, Paint()..color = ink);
  c.drawCircle(at, radius * .25, Paint()..color = heart);
  c.drawCircle(
    at + Offset(-radius * .08 + glint * .4, -radius * .08),
    math.max(1.0, radius * .08),
    Paint()..color = SkyColors.cream,
  );
}

Color _bamboo(
  Canvas c,
  _Geo g,
  double sway,
  bool cleared,
  bool perfect,
  Color accent,
  SkyPalette sky,
) {
  final r = g.r;
  final w = g.w;
  final h = g.h;
  final thicket = _mix(_mix(SkyColors.teal, SkyColors.ink, .6), sky.land, .14);
  var cane = _mix(_mix(SkyColors.yellow, SkyColors.mint, .42), sky.haze, .06);
  if (perfect) {
    cane = _mix(cane, SkyColors.yellow, .22);
  } else if (cleared) {
    cane = _mix(cane, SkyColors.mint, .2);
  }
  final caneLit = _mix(cane, SkyColors.cream, .5);
  final caneDeep = _mix(cane, SkyColors.teal, .5);
  final node = _mix(caneDeep, SkyColors.ink, .25);
  final leaf = perfect
      ? _mix(_mix(SkyColors.mint, accent, .2), SkyColors.gold, .12)
      : _mix(
          _mix(SkyColors.teal, SkyColors.mint, .45),
          accent,
          cleared ? .3 : .12,
        );
  final leafLit = _mix(leaf, SkyColors.cream, .3);
  final leafDeep = _mix(SkyColors.teal, SkyColors.ink, .3);
  final rope = _mix(SkyColors.gold, SkyColors.sand, perfect ? .15 : .4);
  final ropeLit = _mix(rope, SkyColors.cream, .45);
  final ropeDeep = _mix(SkyColors.gold, SkyColors.ink, .4);
  final ink = _mix(_mix(SkyColors.ink, SkyColors.teal, .2), sky.land, .1);

  _fill(c, r, thicket);
  if (w < 8 || h < 8) return ink;

  // Three culms with a cel-shaded highlight and a shaded side each; the dark
  // thicket shows through the slim gaps between them.
  final gap = math.max(1.4, w * .03);
  final culmW = (w - g.line * 2 - gap * 2) / 3;
  final caneFill = Paint()..color = cane;
  final litFill = Paint()..color = caneLit;
  final deepFill = Paint()..color = caneDeep;
  final nodeGap = math.max(26.0, w * .8);
  final nodeH = math.max(2.0, w * .035);
  const stagger = [.2, .62, .38];
  for (var i = 0; i < 3; i++) {
    final left = r.left + g.line + i * (culmW + gap);
    c.drawRect(Rect.fromLTWH(left, r.top, culmW, h), caneFill);
    c.drawRect(
      Rect.fromLTWH(left + culmW * .16, r.top, culmW * .16, h),
      litFill,
    );
    c.drawRect(
      Rect.fromLTWH(left + culmW * .74, r.top, culmW * .26, h),
      deepFill,
    );
    for (var d = g.cap + nodeGap * stagger[i]; d < h; d += nodeGap) {
      final b = g.band(d, d + nodeH, left, left + culmW);
      _fill(c, b, node);
      _fill(
        c,
        g.band(
          d + nodeH,
          d + nodeH + math.max(1.0, nodeH * .5),
          left,
          left + culmW,
        ),
        caneLit,
      );
    }
  }

  // Drooping leaf sprays grow from the outer culms' nodes, alternating
  // sides. They hang with gravity on both pieces, like real bamboo.
  final len = (w * .44).clamp(10.0, 40.0);
  final leafRoom = nodeGap * 1.7;
  var k = 0;
  for (var d = g.cap + nodeGap * .55; d < h + len; d += leafRoom, k++) {
    final right = k.isEven;
    final x = right
        ? r.left + g.line + culmW * .92
        : r.right - g.line - culmW * .92;
    final root = Offset(x, g.y(d));
    final s = right ? sway : -sway;
    for (var j = 0; j < 3; j++) {
      final a = const [.2, .75, 1.25][j];
      final angle = right ? a : math.pi - a;
      _leaf(
        c,
        root,
        angle,
        len * const [1.0, .86, .7][j],
        s * (1 - j * .3),
        j == 1 ? leafDeep : leaf,
        j == 1 ? leaf : leafLit,
        ink,
      );
    }
    c.drawCircle(root, math.max(1.2, len * .07), Paint()..color = node);
  }

  // Rim: a tied crossbar pole with rope lashings over each culm.
  _cap(c, g, cane, caneLit, caneDeep, ink);
  final cap = g.cap;
  if (cap >= 5) {
    final ropePaint = Paint()..color = rope;
    final ropeDeepPaint = Paint()
      ..color = ropeDeep
      ..strokeWidth = math.max(1.0, cap * .12);
    final ropeLitPaint = Paint()
      ..color = ropeLit
      ..strokeWidth = math.max(.8, cap * .08);
    final wrapW = math.min(culmW * .5, cap * 1.1);
    for (var i = 0; i < 3; i++) {
      final cx = r.left + g.line + i * (culmW + gap) + culmW / 2;
      final b = g.band(
        g.line,
        cap + g.line * .8,
        cx - wrapW / 2,
        cx + wrapW / 2,
      );
      c.drawRect(b, ropePaint);
      for (var t = .25; t < 1; t += .25) {
        final x = b.left + b.width * t;
        c.drawLine(
          Offset(x - wrapW * .12, b.bottom),
          Offset(x + wrapW * .12, b.top),
          ropeDeepPaint,
        );
      }
      c.drawLine(
        Offset(b.left, b.top + 1),
        Offset(b.right, b.top + 1),
        ropeLitPaint,
      );
    }
  }
  return ink;
}

void _leaf(
  Canvas c,
  Offset root,
  double angle,
  double len,
  double sway,
  Color fill,
  Color lite,
  Color vein,
) {
  // A slim willow-shaped blade from `root` along `angle` (screen radians).
  final ux = math.cos(angle), uy = math.sin(angle);
  final tip = Offset(root.dx + ux * len + sway, root.dy + uy * len);
  final nx = -uy, ny = ux;
  final bulge = len * .24;
  Offset at(double t, double side) => Offset(
    root.dx + ux * len * t + nx * side + sway * t,
    root.dy + uy * len * t + ny * side,
  );
  final a = at(.45, bulge * 1.6), b = at(.45, -bulge * 1.6);
  c.drawPath(
    Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(a.dx, a.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(b.dx, b.dy, root.dx, root.dy)
      ..close(),
    Paint()..color = fill,
  );
  final m = at(.5, 0);
  c.drawPath(
    Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(a.dx, a.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(m.dx, m.dy, root.dx, root.dy)
      ..close(),
    Paint()..color = lite,
  );
  c.drawLine(
    root,
    at(.8, 0),
    Paint()
      ..color = vein
      ..strokeWidth = math.max(.9, len * .04)
      ..strokeCap = StrokeCap.round,
  );
}

/// Cleared pieces wear a small gem in the middle of the cap; a perfect pass
/// turns it into a golden four-point star.
void _seal(Canvas c, _Geo g, bool cleared, bool perfect) {
  if (!cleared || g.w < 16 || g.cap < 6 || g.h < g.cap + 2) return;
  final at = Offset(g.r.center.dx, g.y(g.cap * .5));
  final rad = g.cap * (perfect ? .8 : .5);
  if (perfect) {
    final s = rad * .34;
    final star = Path()
      ..moveTo(at.dx, at.dy - rad)
      ..quadraticBezierTo(at.dx + s * .3, at.dy - s * .3, at.dx + rad, at.dy)
      ..quadraticBezierTo(at.dx + s * .3, at.dy + s * .3, at.dx, at.dy + rad)
      ..quadraticBezierTo(at.dx - s * .3, at.dy + s * .3, at.dx - rad, at.dy)
      ..quadraticBezierTo(at.dx - s * .3, at.dy - s * .3, at.dx, at.dy - rad)
      ..close();
    c.drawPath(star, Paint()..color = SkyColors.yellow);
    c.drawPath(
      star,
      Paint()
        ..color = SkyColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    c.drawCircle(at, rad * .2, Paint()..color = SkyColors.cream);
    return;
  }
  c.drawCircle(
    at,
    rad,
    Paint()..color = _mix(SkyColors.teal, SkyColors.ink, .2),
  );
  c.drawCircle(at, rad * .74, Paint()..color = SkyColors.mint);
  c.drawCircle(
    at - Offset(rad * .22, rad * .22),
    rad * .26,
    Paint()..color = SkyColors.cream,
  );
}
