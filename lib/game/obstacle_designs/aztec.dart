import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Aztec obstacles: carved stone pillars with a mask at the rim and bands of
/// stepped fret; a sun stone whose rays turn in a masonry tower; feather
/// bands of quetzal green, turquoise, gold and red; stepped temple pyramids
/// with a central stair; jade-inlaid ashlar; a jade mask lit from behind and
/// a gold sun disc. Cleared masks and stones are gilded.
abstract final class AztecObstacles {
  static const _ink = Color(0xff2f2418);
  static const _jade = Color(0xff2fb5a0), _jadeDeep = Color(0xff1f7f78);
  static const _gold = Color(0xffe6b44c), _red = Color(0xffc0472f);
  static const _obsidian = Color(0xff2a2530), _cream = Color(0xfff6ead0);

  static const _stone = [
    (Color(0xffd9c6a2), Color(0xffb39b78), Color(0xff85704f)),
    (Color(0xffc9c0b0), Color(0xffa39a8a), Color(0xff787064)),
    (Color(0xffdcb98a), Color(0xffb88f60), Color(0xff8a643e)),
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
    garden: _pillar,
    wind: _sunStone,
    petal: _feathers,
    switchback: _pyramid,
    steps: _ashlar,
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
    lantern: _mask,
    wheel: _sun,
  );

  static void _fret(Canvas c, Column g, double d, double thick, Color color) {
    final unit = math.max(3.0, thick);
    var i = 0;
    for (var x = g.r.left + 1; x < g.r.right - 1; x += unit, i++) {
      final up = i.isEven;
      Kit.fill(
        c,
        g.band(
          d + (up ? 0 : thick * .5),
          d + (up ? thick * .5 : thick),
          x,
          math.min(x + unit, g.r.right),
        ),
        color,
      );
    }
  }

  /// A carved pillar: a face at the rim, then bands of stepped fret.
  static void _pillar(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final cap = math.min((w * .5).clamp(9.0, 22.0), g.h - start);
    Kit.fill(c, g.band(start, start + cap), tone.$1);
    Kit.fill(c, g.band(start + cap - 2, start + cap), tone.$3);
    final face = pass.perfect ? const Color(0xffffd35a) : _obsidian;
    for (final side in const [-1.0, 1.0]) {
      c.drawRect(
        Rect.fromCenter(
          center: Offset(g.cx + side * w * .22, g.y(start + cap * .4)),
          width: w * .18,
          height: cap * .28,
        ),
        Paint()..color = face,
      );
    }
    c.drawRect(
      Rect.fromCenter(
        center: Offset(g.cx, g.y(start + cap * .75)),
        width: w * .36,
        height: cap * .14,
      ),
      Paint()..color = face,
    );
    final thick = math.max(6.0, w * .22);
    final band = [_jade, _red, _jadeDeep][v];
    for (var d = start + cap + 4; d + thick < g.h; d += thick * 2.6) {
      _fret(c, g, d, thick, band);
    }
    Parts.seal(c, g, WorldRegion.aztec, start + cap * .5, math.min(w * .15, cap * .3), pass);
  }

  /// A masonry tower with a sun stone: rays, rings and a gold face.
  static void _sunStone(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final disc = radius >= 9;
    final from = disc ? start + radius * 2 + 6 : start;
    Parts.courses(c, g, from, math.max(8.0, w * .3), _mix(tone.$3, _ink, .3), tone.$1, tone.$3.withValues(alpha: .6));
    if (!disc) return;
    final hub = Offset(g.cx, g.y(start + radius + 3));
    c.drawCircle(hub, radius, Paint()..color = tone.$3);
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(m.spin(.6, v * .4));
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    for (var i = 0; i < 12; i++) {
      c.save();
      c.rotate(i * math.pi / 6);
      c.drawPath(
        Path()
          ..moveTo(-radius * .1, -radius * .5)
          ..lineTo(0, -radius * .95)
          ..lineTo(radius * .1, -radius * .5)
          ..close(),
        Paint()..color = i.isEven ? gold : _jade,
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(
      hub,
      radius * .5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, radius * .12)
        ..color = _jadeDeep,
    );
    c.drawCircle(hub, radius * .36, Paint()..color = gold);
    c.drawCircle(hub, radius * .16, Paint()..color = _obsidian);
    Parts.seal(c, g, WorldRegion.aztec, start + radius + 3, radius * .3, pass);
  }

  /// Bands of quetzal feathers that ripple along the shaft.
  static void _feathers(Canvas c, Column g, int v, PassState pass, Motion m) {
    final order = [
      [_jade, _jadeDeep, _gold, _red],
      [_red, _gold, _jade, _cream],
      [_jadeDeep, _jade, _cream, _gold],
    ][v];
    Kit.volume(c, g.r, _mix(order[0], _cream, .3), order[0], _mix(order[0], _ink, .4));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final thick = math.max(5.0, w * .28);
    Parts.stripes(c, g, start, thick, order, shift: m.time * 12);
    // A quill runs down the middle of the feathered shaft.
    Kit.fill(
      c,
      g.band(start, g.h, g.cx - .8, g.cx + .8),
      _mix(_ink, order[0], .3),
    );
    Parts.seal(c, g, WorldRegion.aztec, start + thick * .5, math.min(w * .15, thick * .4), pass);
  }

  /// A stepped temple pyramid with a stair up its centre.
  static void _pyramid(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v];
    Kit.volume(c, g.r, tone.$3, _mix(tone.$3, tone.$2, .5), _mix(tone.$3, _ink, .3));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final step = math.max(8.0, w * .32);
    var k = 0;
    for (var d = start; d < g.h; d += step, k++) {
      final inset = math.max(0.0, w * .2 - k * w * .05);
      final r = g.band(d, d + step, g.r.left + inset, g.r.right - inset);
      Kit.fill(c, r, k.isEven ? tone.$1 : tone.$2);
      Kit.fill(c, g.band(d, d + 1.6, g.r.left + inset, g.r.right - inset), _mix(tone.$1, _cream, .5));
      Kit.fill(c, g.band(d + step - 2, d + step, g.r.left + inset, g.r.right - inset), tone.$3.withValues(alpha: .7));
    }
    final stair = math.max(4.0, w * .26);
    Kit.fill(c, g.band(start, g.h, g.cx - stair / 2, g.cx + stair / 2), _mix(tone.$1, _cream, .4));
    for (var d = start + 3; d < g.h; d += 4) {
      Kit.fill(c, g.band(d, d + 1, g.cx - stair / 2, g.cx + stair / 2), tone.$3);
    }
    Parts.seal(c, g, WorldRegion.aztec, start + step * .5, math.min(w * .13, step * .3), pass);
  }

  /// Ashlar blocks with a jade inlay band under a gold moulding.
  static void _ashlar(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final casing = math.min(w * .3, g.h - start);
    Kit.fill(c, g.band(start, start + casing), _jade);
    Kit.fill(c, g.band(start + casing * .7, start + casing), _jadeDeep);
    Kit.fill(c, g.band(start + casing, start + casing + 2), pass.perfect ? const Color(0xffffd35a) : _gold);
    Parts.courses(c, g, start + casing + 2, math.max(12.0, w * .42), _mix(tone.$3, _ink, .3), tone.$1, tone.$3.withValues(alpha: .6));
    Parts.seal(c, g, WorldRegion.aztec, start + casing * .45, math.min(w * .15, casing * .32), pass);
  }

  /// A jade mask lit from within: gold crown, hollow eyes and bared teeth.
  static void _mask(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final jade = [_jade, const Color(0xff4fbf6a), const Color(0xff3f9fbf)][v];
    Parts.orbBegin(c, r, _mix(jade, _cream, .4), jade, _mix(jade, _ink, .45));
    final flicker = .8 + .2 * math.sin(m.time * 4 + v);
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    c.drawRect(Rect.fromLTRB(-r, -r, r, -r * .5), Paint()..color = gold);
    for (var i = -3; i <= 3; i++) {
      c.drawPath(
        Path()
          ..moveTo(i * r * .28 - r * .12, -r * .5)
          ..lineTo(i * r * .28, -r * .7)
          ..lineTo(i * r * .28 + r * .12, -r * .5)
          ..close(),
        Paint()..color = _red,
      );
    }
    for (final side in const [-1.0, 1.0]) {
      c.drawRect(
        Rect.fromCenter(center: Offset(side * r * .34, -r * .12), width: r * .3, height: r * .2),
        Paint()..color = _obsidian,
      );
      c.drawCircle(
        Offset(side * r * .34, -r * .12),
        r * .07,
        Paint()..color = Kit.mix(gold, _cream, .6 * flicker),
      );
    }
    c.drawRect(Rect.fromLTRB(-r * .1, r * .02, r * .1, r * .22), Paint()..color = _jadeDeep);
    c.drawRect(Rect.fromLTRB(-r * .5, r * .34, r * .5, r * .6), Paint()..color = _obsidian);
    for (var i = -3; i <= 3; i++) {
      c.drawRect(
        Rect.fromLTWH(i * r * .13 - r * .05, r * .36, r * .08, r * .1),
        Paint()..color = _cream,
      );
    }
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.aztec, Offset(0, r * .72), r * .16, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, gold, _ink, pass, band: .09);
  }

  /// A gold sun disc with turning rays around a jade heart.
  static void _sun(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    Parts.orbBegin(c, r, _mix(gold, _cream, .5), gold, _mix(gold, _ink, .45));
    c.drawCircle(
      Offset.zero,
      r * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .12
        ..color = [_jade, _red, _jadeDeep][v],
    );
    final rays = const [8, 12, 10][v];
    c.save();
    c.rotate(m.spin(upper ? .5 : -.5));
    for (var i = 0; i < rays; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / rays);
      c.drawPath(
        Path()
          ..moveTo(-r * .1, -r * .3)
          ..lineTo(0, -r * .62)
          ..lineTo(r * .1, -r * .3)
          ..close(),
        Paint()..color = i.isEven ? _red : _obsidian,
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(Offset.zero, r * .22, Paint()..color = _jade);
    c.drawCircle(Offset.zero, r * .1, Paint()..color = _obsidian);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.aztec, Offset.zero, r * .2, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, _goldDeepOf(gold), _ink, pass);
  }

  static Color _goldDeepOf(Color gold) => _mix(gold, _ink, .3);
}
