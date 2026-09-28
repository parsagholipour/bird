import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Dubai obstacles: glass tower shafts with steel mullions; a wind tower
/// with a turning turbine; gilded mashrabiya lattices around turning stars;
/// stepped, fluted silver spires; golden sandstone with an arabesque band; a
/// turquoise star lantern; and a girih rosette that spins in gold and blue.
abstract final class DubaiObstacles {
  static const _ink = Color(0xff23384a);
  static const _steel = Color(0xff9aa8b8), _white = Color(0xfff8fbff);
  static const _gold = Color(0xffe9b44c), _goldDeep = Color(0xffa8792c);
  static const _turquoise = Color(0xff2fc4d6), _deep = Color(0xff1f7f98);
  static const _sand = Color(0xfff0dcae), _sandShade = Color(0xffc9a56a);

  static const _glass = [
    (Color(0xffcfe6f4), Color(0xff8fbad6), Color(0xff5a86a8)),
    (Color(0xffc8f0ea), Color(0xff7fcbc0), Color(0xff4a9a90)),
    (Color(0xffe6ecf2), Color(0xffb0bccb), Color(0xff7a889c)),
  ];

  static Color _mix(Color a, Color b, double t) => Kit.mix(a, b, t);

  static void column(
    Canvas c,
    Rect r, {
    required ObstacleKind kind,
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
  }) => Parts.column(
    c,
    r,
    kind: kind,
    top: top,
    seconds: seconds,
    reducedMotion: reducedMotion,
    pass: pass,
    appearance: appearance,
    ink: _ink,
    garden: _tower,
    wind: _turbine,
    petal: _mashrabiya,
    switchback: _spire,
    steps: _sandstone,
  );

  static void orb(
    Canvas c,
    double radius, {
    required ObstacleKind kind,
    required bool upper,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
  }) => Parts.orb(
    c,
    radius,
    kind: kind,
    upper: upper,
    seconds: seconds,
    reducedMotion: reducedMotion,
    pass: pass,
    appearance: appearance,
    lantern: _lantern,
    wheel: _rosette,
  );

  static void _star(Canvas c, double r, int points, double inner, Paint paint) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / points;
      final rad = i.isEven ? r : r * inner;
      final p = Offset(math.cos(a), math.sin(a)) * rad;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    c.drawPath(path..close(), paint);
  }

  /// A glass tower shaft: steel mullions, a reflected streak and a crown.
  static void _tower(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _glass[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final crown = math.min(math.max(5.0, w * .2), g.h - start);
    Kit.fill(c, g.band(start, start + crown), _steel);
    Kit.fill(c, g.band(start + crown - 1.5, start + crown), pass.perfect ? const Color(0xffffd35a) : _gold);
    final mullion = _mix(tone.$3, _ink, .3).withValues(alpha: .6);
    for (var d = start + crown + 6; d < g.h; d += 7) {
      Kit.fill(c, g.band(d, d + .9), mullion);
    }
    for (final fx in const [.25, .5, .75]) {
      Kit.fill(c, g.band(start + crown, g.h, g.r.left + w * fx, g.r.left + w * fx + .9), mullion);
    }
    Kit.fill(c, g.band(start + crown, g.h, g.r.left + w * .1, g.r.left + w * .2), _white.withValues(alpha: .28));
    Parts.seal(c, g, WorldRegion.dubai, start + crown * .5, math.min(w * .14, crown * .4), pass);
  }

  /// A wind tower whose turbine turns on a dark disc.
  static void _turbine(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _glass[(v + 2) % 3];
    Kit.volume(c, g.r, _white, _mix(_sand, _white, .4), _sandShade);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final fan = radius >= 9;
    final from = fan ? start + radius * 2 + 6 : start;
    Parts.courses(c, g, from, math.max(9.0, w * .3), _mix(_sandShade, _ink, .2), _white, _sandShade.withValues(alpha: .6));
    if (!fan) return;
    Kit.fill(c, g.band(start, start + radius * 2 + 6), _mix(tone.$3, _ink, .5));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    c.drawCircle(hub, radius, Paint()..color = _mix(tone.$3, _ink, .3));
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(m.spin(1.2, v * .7));
    final blades = v == 1 ? 4 : 3;
    for (var i = 0; i < blades; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / blades);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-radius * .3, -radius * .5, -radius * .06, -radius * .92)
          ..quadraticBezierTo(radius * .3, -radius * .5, 0, 0)
          ..close(),
        Paint()..color = i.isEven ? _white : tone.$1,
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(hub, radius * .14, Paint()..color = pass.perfect ? const Color(0xffffd35a) : _gold);
    Parts.seal(c, g, WorldRegion.dubai, start + radius * 1.7, radius * .2, pass);
  }

  /// A gilded lattice with an eight-point star turning in each cell.
  static void _mashrabiya(Canvas c, Column g, int v, PassState pass, Motion m) {
    final wood = [const Color(0xffb8843c), const Color(0xff8a5f3a), const Color(0xffc09a5a)][v];
    Kit.volume(c, g.r, _mix(wood, _sand, .4), wood, _mix(wood, _ink, .45));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    Parts.lattice(c, g, start, math.max(8.0, w * .5), _mix(wood, _sand, .5), width: math.max(1.0, w * .04));
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    var row = 0;
    final cell = math.max(10.0, w * .9);
    for (var d = start + cell * .5 + 2; d < g.h - cell * .3; d += cell, row++) {
      c.save();
      c.translate(g.cx, g.y(d));
      c.rotate(m.spin(row.isEven ? .7 : -.7, v * .3));
      _star(c, math.min(cell, w) * .34, 8, .55, Paint()..color = gold);
      _star(c, math.min(cell, w) * .16, 8, .5, Paint()..color = _turquoise);
      c.restore();
    }
    Parts.seal(c, g, WorldRegion.dubai, start + 6, math.min(w * .12, 6), pass);
  }

  /// A silver spire that steps in from its base, fluted like a tall blade.
  static void _spire(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _glass[(v + 1) % 3];
    Kit.volume(c, g.r, _mix(tone.$3, _ink, .35), _mix(tone.$3, _ink, .2), _mix(tone.$3, _ink, .5));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final step = math.max(9.0, w * .34);
    var k = 0;
    for (var d = start; d < g.h; d += step, k++) {
      final inset = math.max(0.0, w * .22 - k * w * .06);
      final l = g.r.left + inset, r = g.r.right - inset;
      Kit.fill(c, g.band(d, d + step, l, r), _mix(tone.$1, _steel, k.isEven ? .1 : .35));
      Kit.fill(c, g.band(d, d + 1.5, l, r), _white);
      Kit.fill(c, g.band(d, d + step, l, l + (r - l) * .28), _white.withValues(alpha: .35));
      Kit.fill(c, g.band(d, d + step, r - (r - l) * .3, r), tone.$3.withValues(alpha: .5));
    }
    Parts.seal(c, g, WorldRegion.dubai, start + step * .5, math.min(w * .13, step * .3), pass);
  }

  /// Golden sandstone under an arabesque band of turquoise zigzags.
  static void _sandstone(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = [
      (const Color(0xfff6e6bd), const Color(0xffe6cf98), const Color(0xffc09a60)),
      (const Color(0xfff2d9a8), const Color(0xffdcba78), const Color(0xffb08850)),
      (const Color(0xfffaf0d8), const Color(0xffeadab0), const Color(0xffc8b088)),
    ][v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final band = math.min(math.max(7.0, w * .3), g.h - start);
    Kit.fill(c, g.band(start, start + band), pass.perfect ? const Color(0xffffd35a) : _gold);
    final zig = Path()..moveTo(g.r.left, g.y(start + band * .5));
    var up = false;
    for (var x = g.r.left; x <= g.r.right; x += math.max(3.0, band * .5)) {
      zig.lineTo(x, g.y(start + band * (up ? .25 : .75)));
      up = !up;
    }
    c.drawPath(
      zig,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, band * .12)
        ..color = _deep,
    );
    Kit.fill(c, g.band(start + band, start + band + 2), _goldDeep);
    Parts.courses(c, g, start + band + 2, math.max(12.0, w * .42), _mix(tone.$3, _ink, .25), tone.$1, tone.$3.withValues(alpha: .6));
    Parts.seal(c, g, WorldRegion.dubai, start + band * .5, math.min(w * .13, band * .28), pass);
  }

  /// A turquoise star lantern glowing from the middle.
  static void _lantern(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final glass = [_turquoise, const Color(0xff4fd0a0), const Color(0xff5fa0e0)][v];
    Parts.orbBegin(c, r, _mix(glass, _white, .6), glass, _mix(glass, _ink, .5));
    final pulse = .85 + .15 * math.sin(m.time * 3 + v);
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    final rib = Paint()
      ..color = gold
      ..strokeWidth = math.max(1.0, r * .05);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawLine(Offset.zero, Offset(math.cos(a), math.sin(a)) * r, rib);
    }
    _star(c, r * .62, 12, .7, Paint()..color = _mix(const Color(0xfffff2c0), glass, .3 * (1 - pulse) + .1));
    _star(c, r * .34, 8, .5, Paint()..color = _white.withValues(alpha: .9 * pulse));
    c.drawCircle(Offset(0, upper ? -r * .9 : r * .9), r * .1, Paint()..color = _goldDeep);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.dubai, Offset.zero, r * .2, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, gold, _ink, pass, band: .09);
  }

  /// A spinning girih rosette of gold and turquoise stars.
  static void _rosette(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final field = [_deep, const Color(0xff2f5f9a), const Color(0xff2f8f6a)][v];
    Parts.orbBegin(c, r, _mix(field, _white, .3), field, _mix(field, _ink, .5));
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    final spin = m.spin(upper ? .6 : -.6);
    c.save();
    c.rotate(spin);
    _star(c, r * .82, const [8, 12, 10][v], .6, Paint()..color = gold);
    c.restore();
    c.save();
    c.rotate(-spin * 1.5);
    _star(c, r * .5, const [8, 12, 10][v], .55, Paint()..color = _turquoise);
    c.restore();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      c.drawCircle(Offset(math.cos(a), math.sin(a)) * r * .9, r * .03, Paint()..color = _white);
    }
    c.drawCircle(Offset.zero, r * .17, Paint()..color = _white);
    c.drawCircle(Offset.zero, r * .08, Paint()..color = _goldDeep);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.dubai, Offset.zero, r * .2, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, gold, _ink, pass);
  }
}
