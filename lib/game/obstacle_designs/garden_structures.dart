import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Three opaque garden structures, clipped to the collision rectangle.
///
/// `appearance % 3` selects a brass conservatory, a carved terracotta blossom
/// column, or a tied bamboo shrine. Top and bottom solids share that identity.
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

    c.save();
    c.clipRect(r);
    switch (motif) {
      case 0:
        _conservatory(c, r, top, sway, cleared, perfect, accent, sky);
      case 1:
        _terracotta(c, r, top, sway, cleared, perfect, accent, sky);
      default:
        _bamboo(c, r, top, sway, cleared, perfect, accent, sky);
    }
    _badge(c, r, top, cleared, perfect);
    _edge(c, r, top, perfect, motif);
    c.restore();
  }
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

double _y(Rect r, bool top, double dist) =>
    top ? r.bottom - dist : r.top + dist;

Rect _band(Rect r, bool top, double a, double b, double left, double right) {
  final y1 = _y(r, top, a);
  final y2 = _y(r, top, b);
  return Rect.fromLTRB(left, math.min(y1, y2), right, math.max(y1, y2));
}

void _fill(Canvas c, Rect b, Color color) {
  if (!(b.width > 0) || !(b.height > 0)) return;
  c.drawRect(b, Paint()..color = color);
}

void _conservatory(
  Canvas c,
  Rect r,
  bool top,
  double sway,
  bool cleared,
  bool perfect,
  Color accent,
  SkyPalette sky,
) {
  final w = r.width;
  final h = r.height;
  var jewel = _mix(_mix(SkyColors.teal, accent, .4), SkyColors.ink, .3);
  var lit = _mix(jewel, SkyColors.mint, .42);
  if (perfect) {
    jewel = _mix(jewel, SkyColors.gold, .1);
    lit = _mix(lit, SkyColors.gold, .08);
  } else if (cleared) {
    jewel = _mix(jewel, SkyColors.mint, .16);
    lit = _mix(lit, SkyColors.cream, .06);
  }
  lit = _mix(lit, sky.haze, .08);
  final fan = _mix(lit, SkyColors.cream, .1);
  final brass = _mix(SkyColors.gold, SkyColors.cream, perfect ? .3 : .14);
  final brassDeep = _mix(SkyColors.gold, SkyColors.ink, perfect ? .26 : .4);

  _fill(c, r, jewel);
  if (w < 8 || h < 8) return;

  final stile = math.min(math.max(3.0, w * .16), w * .3);
  final glassL = r.left + stile;
  final glassR = r.right - stile;
  final glassW = glassR - glassL;
  _fill(c, Rect.fromLTRB(r.left, r.top, r.center.dx, r.bottom), lit);

  final lip = math.min(4.0, h);
  final usable = h - lip;
  final crown = glassW < 8
      ? 0.0
      : math.min(26.0, math.min(usable * .7, glassW * .58));
  final mid = (glassL + glassR) / 2;
  if (crown >= 6) {
    c.drawPath(
      _arch(glassL, glassR, _y(r, top, lip), _y(r, top, lip + crown * 2)),
      Paint()..color = fan,
    );
    final gleam = math.min(crown * .42, 12.0);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(
          glassL + glassW * .3 + sway,
          _y(r, top, lip + gleam * .45),
        ),
        width: math.min(glassW * .22, 10),
        height: gleam,
      ),
      Paint()..color = _mix(fan, SkyColors.cream, .22),
    );
  }

  _fill(c, Rect.fromLTWH(r.left, r.top, stile, h), brass);
  _fill(c, Rect.fromLTWH(r.right - stile, r.top, stile, h), brassDeep);
  final gleamW = math.min(2.4, stile * .34);
  _fill(
    c,
    Rect.fromLTWH(r.left, r.top, gleamW, h),
    _mix(brass, SkyColors.cream, .42),
  );

  if (glassW < 8) return;
  final bar = math.min(stile * .72, math.max(2.6, w * .085));
  _fill(c, Rect.fromLTWH(mid - bar / 2, r.top, bar, h), brass);

  final pitch = math.max(40.0, w * 1.05);
  final first = lip + (crown >= 6 ? crown : pitch);
  for (var d = first; d < h - bar - 1; d += pitch) {
    _fill(c, _band(r, top, d, math.min(h, d + bar), glassL, glassR), brass);
  }
  if (h > first + bar + 4) {
    _fill(c, _band(r, top, h - bar, h, glassL, glassR), brass);
  }

  if (crown < 6) return;
  final thick = math.min(math.max(bar * 1.25, 4.0), crown * .46);
  final outer = _y(r, top, lip + crown * 2);
  final inner = _y(r, top, lip + math.max(0.0, crown - thick) * 2);
  final base = _y(r, top, lip);
  c.drawPath(
    Path()
      ..moveTo(glassL, base)
      ..quadraticBezierTo(mid, outer, glassR, base)
      ..quadraticBezierTo(mid, inner, glassL, base)
      ..close(),
    Paint()..color = brass,
  );
}

Path _arch(double left, double right, double base, double control) => Path()
  ..moveTo(left, base)
  ..quadraticBezierTo((left + right) / 2, control, right, base)
  ..close();

void _terracotta(
  Canvas c,
  Rect r,
  bool top,
  double sway,
  bool cleared,
  bool perfect,
  Color accent,
  SkyPalette sky,
) {
  final w = r.width;
  final h = r.height;
  var clay = _mix(SkyColors.sand, SkyColors.coral, .5);
  var deep = _mix(SkyColors.coralDeep, SkyColors.ink, .34);
  var highlight = _mix(
    _mix(SkyColors.cream, SkyColors.sand, .46),
    sky.haze,
    .1,
  );
  if (perfect) {
    clay = _mix(clay, SkyColors.gold, .14);
    highlight = _mix(highlight, SkyColors.gold, .12);
  } else if (cleared) {
    clay = _mix(clay, SkyColors.mint, .1);
  }
  final petal = _mix(SkyColors.coral, SkyColors.cream, .3);
  final shade = _mix(SkyColors.coralDeep, SkyColors.sand, .18);
  final heart = perfect
      ? SkyColors.gold
      : (cleared ? _mix(accent, SkyColors.mint, .4) : accent);

  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [highlight, clay, deep],
        stops: const [0, .48, 1],
      ).createShader(r),
  );
  if (w < 8 || h < 8) return;

  final fluteW = math.max(3.0, w * .085);
  for (final fx in const [.1, .5, .9]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + w * fx - fluteW / 2, r.top - 2, fluteW, h + 4),
        Radius.circular(fluteW / 2),
      ),
      Paint()..color = deep,
    );
  }

  final lip = math.min(4.0, h);
  final margin = lip + (h > w * 1.15 ? 2.6 : .8);
  final room = math.max(0.0, h - margin);
  final radius = math.min(w * .42, room * .5);
  if (radius >= 3.4) {
    _blossom(
      c,
      Offset(r.center.dx, _y(r, top, margin + radius)),
      radius,
      deep,
      petal,
      shade,
      heart,
      sway * .35,
    );
  }

  final ringT = math.max(3.6, w * .1);
  final step = math.max(w * 1.2, ringT + 18);
  final cover = margin + math.max(radius, 0) * 2 + w * .08;
  var rings = 0;
  for (var d = cover; d + ringT < h && rings < 3; d += step, rings++) {
    _fill(c, _band(r, top, d, d + ringT * .58, r.left, r.right), deep);
    _fill(
      c,
      _band(r, top, d + ringT * .58, d + ringT, r.left, r.right),
      highlight,
    );
  }
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
) {
  c.drawCircle(at, radius, Paint()..color = bed);
  c.save();
  c.translate(at.dx, at.dy);
  for (var i = 0; i < 6; i++) {
    c.save();
    c.rotate(i * math.pi / 3);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(glint, -radius * .4),
        width: radius * .7,
        height: radius * .86,
      ),
      Paint()..color = i.isEven ? petal : shade,
    );
    c.restore();
  }
  c.restore();
  c.drawCircle(
    at,
    radius,
    Paint()
      ..color = bed
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, radius * .14),
  );
  c.drawCircle(at, radius * .28, Paint()..color = heart);
  c.drawCircle(
    at + Offset(-radius * .09 + glint, -radius * .1),
    math.max(1.15, radius * .1),
    Paint()..color = SkyColors.cream,
  );
}

void _bamboo(
  Canvas c,
  Rect r,
  bool top,
  double sway,
  bool cleared,
  bool perfect,
  Color accent,
  SkyPalette sky,
) {
  final w = r.width;
  final h = r.height;
  final thicket = _mix(_mix(SkyColors.teal, SkyColors.ink, .52), sky.land, .16);
  final cane = _mix(_mix(SkyColors.yellow, SkyColors.sand, .38), sky.haze, .06);
  final caneLit = _mix(SkyColors.cream, SkyColors.yellow, .32);
  final caneDeep = _mix(SkyColors.gold, SkyColors.teal, .34);
  final node = _mix(SkyColors.ink, SkyColors.rock, .38);
  final leaf = perfect
      ? _mix(_mix(SkyColors.mint, accent, .22), SkyColors.gold, .12)
      : _mix(SkyColors.mint, accent, cleared ? .45 : .24);
  final leafDeep = _mix(SkyColors.teal, SkyColors.ink, .28);
  final rope = _mix(SkyColors.gold, SkyColors.sand, perfect ? .22 : .38);
  final ropeDeep = _mix(SkyColors.gold, SkyColors.ink, .36);

  _fill(c, r, thicket);
  if (w < 8 || h < 8) return;

  final culmW = w * .42;
  const slots = [.17, .5, .83];
  final colors = [caneLit, cane, caneDeep];
  for (var i = 0; i < 3; i++) {
    final cx = r.left + w * slots[i];
    final body = Rect.fromCenter(
      center: Offset(cx, r.center.dy),
      width: culmW,
      height: h + culmW,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(culmW / 2)),
      Paint()..color = colors[i],
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - culmW * .2, r.center.dy),
          width: math.max(2.0, culmW * .16),
          height: h + culmW,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = _mix(caneLit, SkyColors.yellow, .2),
    );
  }
  for (final fx in const [.34, .67]) {
    _fill(c, Rect.fromLTWH(r.left + w * fx - 1.15, r.top, 2.3, h), thicket);
  }

  final lip = math.min(4.0, h);
  final nodeH = math.max(2.8, w * .06);
  final nodeGap = math.max(18.0, w * .72);
  for (var d = lip + nodeGap * .42; d < h - 1; d += nodeGap) {
    for (final fx in slots) {
      final cx = r.left + w * fx;
      c.drawRRect(
        RRect.fromRectAndRadius(
          _band(r, top, d, d + nodeH, cx - culmW * .46, cx + culmW * .46),
          Radius.circular(nodeH),
        ),
        Paint()..color = node,
      );
    }
  }

  final spare = h - lip;
  final beam = math.min(math.max(2.8, w * .1), spare * .42);
  if (beam < 2.2 || spare < beam + 1) return;
  final doubleBeam = spare > beam * 2 + 16;
  final gap = math.max(1.6, beam * .38);
  final tieSpan = doubleBeam ? beam * 2 + gap : beam;
  _fill(c, _band(r, top, lip, lip + beam, r.left, r.right), rope);
  _fill(
    c,
    _band(r, top, lip, lip + math.min(1.8, beam * .28), r.left, r.right),
    ropeDeep,
  );
  if (doubleBeam) {
    final far = lip + beam + gap;
    _fill(c, _band(r, top, far, far + beam, r.left, r.right), rope);
    _fill(
      c,
      _band(
        r,
        top,
        far + beam - math.min(1.6, beam * .24),
        far + beam,
        r.left,
        r.right,
      ),
      ropeDeep,
    );
  }
  final knotR = doubleBeam ? math.min(tieSpan * .34, beam) : beam * .42;
  final knotY = _y(r, top, lip + tieSpan * .5);
  c.drawCircle(Offset(r.center.dx, knotY), knotR, Paint()..color = ropeDeep);
  c.drawCircle(
    Offset(r.center.dx - knotR * .28, knotY - knotR * .22),
    knotR * .38,
    Paint()..color = _mix(rope, SkyColors.cream, .3),
  );

  final len = math.min(w * .92, h - (lip + tieSpan) - 1);
  if (len < 8) return;
  final dir = top ? -1.0 : 1.0;
  final root = Offset(r.center.dx, _y(r, top, lip + tieSpan));
  final half = math.min(w * .4, math.max(len * .9, w * .24));
  _leaf(
    c,
    root,
    dir,
    len,
    half,
    1,
    sway,
    leaf,
    _mix(leaf, SkyColors.cream, .26),
    leafDeep,
  );
  if (len < 15) return;
  _leaf(
    c,
    Offset(r.center.dx - w * .06, _y(r, top, lip + tieSpan + len * .08)),
    dir,
    len * .74,
    half * .82,
    -1,
    -sway,
    leafDeep,
    _mix(leaf, SkyColors.cream, .18),
    _mix(leafDeep, SkyColors.ink, .2),
  );
}

void _leaf(
  Canvas c,
  Offset root,
  double dir,
  double len,
  double halfW,
  double lean,
  double sway,
  Color fill,
  Color lite,
  Color vein,
) {
  final tip = Offset(root.dx + sway, root.dy + dir * len);
  c.drawPath(
    Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(
        root.dx + lean * halfW + sway * .25,
        root.dy + dir * len * .5,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        root.dx - lean * halfW * .42 + sway * .15,
        root.dy + dir * len * .58,
        root.dx,
        root.dy,
      )
      ..close(),
    Paint()..color = fill,
  );
  c.drawPath(
    Path()
      ..moveTo(root.dx, root.dy + dir * len * .16)
      ..quadraticBezierTo(
        root.dx + lean * halfW * .58 + sway * .2,
        root.dy + dir * len * .48,
        tip.dx,
        tip.dy - dir * 1.2,
      )
      ..quadraticBezierTo(
        root.dx - lean * halfW * .18,
        root.dy + dir * len * .5,
        root.dx,
        root.dy + dir * len * .16,
      )
      ..close(),
    Paint()..color = lite,
  );
  c.drawLine(
    root,
    tip,
    Paint()
      ..color = vein
      ..strokeWidth = math.max(1.6, halfW * .1)
      ..strokeCap = StrokeCap.round,
  );
}

void _badge(Canvas c, Rect r, bool top, bool cleared, bool perfect) {
  if (!cleared || r.width < 16 || r.height < math.min(4.0, r.height) + 10) {
    return;
  }
  final lip = math.min(4.0, r.height);
  final at = Offset(
    r.right - math.max(5.0, r.width * .14),
    _y(r, top, lip + math.min(10.0, (r.height - lip) * .36)),
  );
  final rad = perfect ? 3.2 : 2.5;
  c.drawCircle(
    at,
    rad,
    Paint()..color = perfect ? SkyColors.yellow : SkyColors.mint,
  );
  c.drawCircle(
    at,
    rad * .4,
    Paint()..color = perfect ? SkyColors.coralDeep : SkyColors.coral,
  );
}

void _edge(Canvas c, Rect r, bool top, bool perfect, int motif) {
  final lip = math.min(4.0, r.height);
  if (lip <= 0) return;
  final shoulderH = math.min(2.4, math.max(0.0, r.height - lip));
  if (shoulderH >= 1) {
    final shoulder = perfect
        ? _mix(SkyColors.gold, SkyColors.cream, .2)
        : switch (motif) {
            0 => _mix(SkyColors.gold, SkyColors.ink, .42),
            1 => _mix(SkyColors.coralDeep, SkyColors.ink, .3),
            _ => _mix(SkyColors.teal, SkyColors.ink, .48),
          };
    _fill(c, _band(r, top, lip, lip + shoulderH, r.left, r.right), shoulder);
  }
  _fill(c, _band(r, top, 0, lip, r.left, r.right), SkyColors.cream);
  if (lip >= 2.4) {
    _fill(
      c,
      _band(r, top, 0, math.min(1.15, lip), r.left, r.right),
      SkyColors.white,
    );
  }
}
