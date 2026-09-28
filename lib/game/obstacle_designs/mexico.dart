import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Mexican obstacles: adobe pillars tiled in talavera; a paper pinwheel
/// turning on an adobe post; serape stripes with woven diamonds; ribbed
/// saguaro shafts with spines; terracotta steps under a marigold band; a
/// star piñata; and a spinning talavera plate.
abstract final class MexicoObstacles {
  static const _ink = Color(0xff3a1f2a);
  static const _blue = Color(0xff2f5fb0), _white = Color(0xfffff6e8);
  static const _yellow = Color(0xffffc93f), _pink = Color(0xffe6407a);
  static const _green = Color(0xff3f9a5a), _orange = Color(0xfff7a21b);
  static const _teal = Color(0xff2fb5c0), _purple = Color(0xff7a3fa0);
  static const _terracotta = Color(0xffc8643e);

  static const _adobe = [
    (Color(0xfff2c894), Color(0xffdc9a5e), Color(0xffa8683a)),
    (Color(0xfff0b48a), Color(0xffd48a5a), Color(0xff9a5a3a)),
    (Color(0xfff6d8a8), Color(0xffe0b070), Color(0xffb08048)),
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
    garden: _talavera,
    wind: _molino,
    petal: _serape,
    switchback: _saguaro,
    steps: _terracottaSteps,
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
    lantern: _pinata,
    wheel: _plate,
  );

  /// A pillar tiled in talavera: blue-bordered squares with a diamond.
  static void _talavera(Canvas c, Column g, int v, PassState pass, Motion m) {
    final accent = [_blue, _green, _purple][v];
    Kit.volume(c, g.r, _white, _mix(_white, const Color(0xffe8d8c0), .5), const Color(0xffc0b098));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final collar = math.min(math.max(5.0, w * .18), g.h - start);
    Kit.fill(c, g.band(start, start + collar), _terracotta);
    Kit.fill(c, g.band(start + collar * .4, start + collar * .6), pass.perfect ? const Color(0xffffd35a) : _yellow);
    final cell = math.max(9.0, w * .5);
    final cols = math.max(1, (w / cell).round());
    final cw = w / cols;
    var row = 0;
    for (var d = start + collar + 2; d + cell * .6 < g.h; d += cell, row++) {
      for (var i = 0; i < cols; i++) {
        final x0 = g.r.left + i * cw;
        Kit.fill(c, g.band(d, d + cell - 1.5, x0 + 1, x0 + cw - 1), _mix(accent, _white, .75));
        final cx = x0 + cw / 2, cy = g.y(d + (cell - 1.5) / 2);
        final s = math.min(cw, cell) * .38;
        c.drawPath(
          Path()
            ..moveTo(cx, cy - s)
            ..lineTo(cx + s, cy)
            ..lineTo(cx, cy + s)
            ..lineTo(cx - s, cy)
            ..close(),
          Paint()..color = (row + i).isEven ? accent : _mix(accent, _pink, .5),
        );
        c.drawCircle(Offset(cx, cy), s * .3, Paint()..color = _yellow);
      }
    }
    Parts.seal(c, g, WorldRegion.mexico, start + collar * .5, math.min(w * .13, collar * .4), pass);
  }

  /// A paper pinwheel on an adobe post: four vanes spin about a pin.
  static void _molino(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _adobe[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final wheel = radius >= 9;
    final from = wheel ? start + radius * 2 + 6 : start;
    Parts.courses(c, g, from, math.max(8.0, w * .26), _mix(tone.$3, _ink, .3), tone.$1, tone.$3.withValues(alpha: .6));
    if (!wheel) return;
    Kit.fill(c, g.band(start, start + radius * 2 + 6), _mix(tone.$3, _ink, .35));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(m.spin(1.5, v * .5));
    final vanes = [
      [_pink, _yellow, _teal, _orange],
      [_orange, _purple, _yellow, _green],
      [_teal, _pink, _white, _yellow],
    ][v];
    for (var i = 0; i < 4; i++) {
      c.save();
      c.rotate(i * math.pi / 2);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(radius * .95, -radius * .1)
          ..quadraticBezierTo(radius * .8, radius * .7, 0, radius * .1)
          ..close(),
        Paint()..color = vanes[i],
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(hub, radius * .12, Paint()..color = pass.perfect ? const Color(0xffffd35a) : _white);
    Parts.seal(c, g, WorldRegion.mexico, start + radius * 1.75, radius * .18, pass);
  }

  /// Serape stripes that ripple, with a woven diamond down the middle.
  static void _serape(Canvas c, Column g, int v, PassState pass, Motion m) {
    final order = [
      [_pink, _yellow, _teal, _white, _orange],
      [_teal, _orange, _white, _purple, _yellow],
      [_orange, _green, _pink, _white, _blue],
    ][v];
    Kit.volume(c, g.r, _mix(order[0], _white, .3), order[0], _mix(order[0], _ink, .4));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final thick = math.max(5.0, w * .2);
    Parts.stripes(c, g, start, thick, order, shift: m.time * 9);
    final size = math.max(8.0, w * .34);
    for (var d = start + size + 4; d < g.h; d += size * 3) {
      final cy = g.y(d);
      c.drawPath(
        Path()
          ..moveTo(g.cx, cy - size)
          ..lineTo(g.cx + size, cy)
          ..lineTo(g.cx, cy + size)
          ..lineTo(g.cx - size, cy)
          ..close(),
        Paint()..color = _ink.withValues(alpha: .75),
      );
      c.drawPath(
        Path()
          ..moveTo(g.cx, cy - size * .6)
          ..lineTo(g.cx + size * .6, cy)
          ..lineTo(g.cx, cy + size * .6)
          ..lineTo(g.cx - size * .6, cy)
          ..close(),
        Paint()..color = order[(d ~/ 7 + 2) % order.length],
      );
    }
    Parts.seal(c, g, WorldRegion.mexico, start + thick * .5, math.min(w * .14, thick * .4), pass);
  }

  /// A ribbed saguaro shaft with rows of spines and blossoms at the rim.
  static void _saguaro(Canvas c, Column g, int v, PassState pass, Motion m) {
    final green = [_green, const Color(0xff4f8a4a), const Color(0xff3f8a7a)][v];
    Kit.volume(c, g.r, _mix(green, _white, .35), green, _mix(green, _ink, .45));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final rib = _mix(green, _ink, .4).withValues(alpha: .7);
    final ribs = math.max(3, (w / 7).round());
    for (var i = 1; i < ribs; i++) {
      final x = g.r.left + w * i / ribs;
      Kit.fill(c, g.band(start, g.h, x - .6, x + .6), rib);
    }
    final spine = Paint()
      ..color = _white.withValues(alpha: .8)
      ..strokeWidth = .9
      ..strokeCap = StrokeCap.round;
    var row = 0;
    for (var d = start + 8; d < g.h; d += 9, row++) {
      for (var i = 0; i < ribs; i++) {
        final x = g.r.left + w * (i + (row.isOdd ? .5 : 0)) / ribs;
        if (x < g.r.left + 1 || x > g.r.right - 1) continue;
        final y = g.y(d);
        c.drawLine(Offset(x - 1.5, y), Offset(x + 1.5, y), spine);
      }
    }
    final bloom = Kit.mix(_pink, _yellow, v * .3);
    for (var i = 0; i < 3; i++) {
      final x = g.r.left + w * (i + .5) / 3;
      c.drawCircle(Offset(x, g.y(start + 4)), math.max(2.0, w * .07), Paint()..color = bloom);
      c.drawCircle(Offset(x, g.y(start + 4)), math.max(1.0, w * .03), Paint()..color = _yellow);
    }
    Parts.seal(c, g, WorldRegion.mexico, start + 14, math.min(w * .13, 8), pass);
  }

  /// Terracotta blocks under a band of marigolds.
  static void _terracottaSteps(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _adobe[(v + 1) % 3];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final band = math.min(math.max(7.0, w * .3), g.h - start);
    Kit.fill(c, g.band(start, start + band), _mix(_terracotta, _ink, .1));
    final n = math.max(2, (w / (band * .9)).round());
    for (var i = 0; i < n; i++) {
      final at = Offset(g.r.left + w * (i + .5) / n, g.y(start + band * .5));
      c.drawCircle(at, band * .34, Paint()..color = i.isEven ? _orange : _yellow);
      c.drawCircle(at, band * .13, Paint()..color = pass.perfect ? const Color(0xffffd35a) : _pink);
    }
    Kit.fill(c, g.band(start + band, start + band + 2), _mix(tone.$3, _ink, .3));
    Parts.courses(c, g, start + band + 2, math.max(12.0, w * .42), _mix(tone.$3, _ink, .3), tone.$1, tone.$3.withValues(alpha: .6));
    Parts.seal(c, g, WorldRegion.mexico, start + band * .5, math.min(w * .13, band * .26), pass);
  }

  /// A star piñata: paper points in bright colours with a tissue fringe.
  static void _pinata(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final paper = [_pink, _orange, _teal][v];
    Parts.orbBegin(c, r, _mix(paper, _white, .5), paper, _mix(paper, _ink, .45));
    c.save();
    c.rotate(math.sin(m.time * 1.4 + v) * .12);
    final colors = [_yellow, _pink, _teal, _orange, _green];
    for (var i = 0; i < 5; i++) {
      final a0 = -math.pi / 2 + i * math.pi * 2 / 5;
      final tip = Offset(math.cos(a0), math.sin(a0)) * r * .95;
      final l = Offset(math.cos(a0 - .6), math.sin(a0 - .6)) * r * .3;
      final rr = Offset(math.cos(a0 + .6), math.sin(a0 + .6)) * r * .3;
      c.drawPath(
        Path()
          ..moveTo(l.dx, l.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(rr.dx, rr.dy)
          ..close(),
        Paint()..color = colors[(i + v) % colors.length],
      );
      final fringe = Paint()
        ..color = _white.withValues(alpha: .8)
        ..strokeWidth = math.max(.8, r * .03);
      for (var k = 1; k < 4; k++) {
        final at = Offset.lerp(Offset.zero, tip, .25 + k * .2)!;
        final side = Offset(-math.sin(a0), math.cos(a0)) * r * (.14 - k * .03);
        c.drawLine(at - side, at + side, fringe);
      }
    }
    c.restore();
    c.drawCircle(Offset.zero, r * .26, Paint()..color = _yellow);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.mexico, Offset.zero, r * .2, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, pass.perfect ? const Color(0xffffd35a) : _purple, _ink, pass, band: .08);
  }

  /// A talavera plate turning: blue petals around a yellow eye.
  static void _plate(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final accent = [_blue, _green, _pink][v];
    Parts.orbBegin(c, r, _white, const Color(0xfff6ecd8), const Color(0xffc8b898));
    c.drawCircle(
      Offset.zero,
      r * .84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .1
        ..color = accent,
    );
    final petals = const [8, 6, 10][v];
    c.save();
    c.rotate(m.spin(upper ? .5 : -.5));
    for (var i = 0; i < petals; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / petals);
      c.drawPath(
        Path()
          ..moveTo(0, -r * .12)
          ..quadraticBezierTo(-r * .24, -r * .42, 0, -r * .74)
          ..quadraticBezierTo(r * .24, -r * .42, 0, -r * .12)
          ..close(),
        Paint()..color = i.isEven ? accent : _mix(accent, _yellow, .5),
      );
      c.restore();
    }
    c.restore();
    for (var i = 0; i < 20; i++) {
      final a = i * math.pi / 10;
      c.drawCircle(Offset(math.cos(a), math.sin(a)) * r * .92, r * .025, Paint()..color = accent);
    }
    c.drawCircle(Offset.zero, r * .16, Paint()..color = _yellow);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.mexico, Offset.zero, r * .18, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, pass.perfect ? const Color(0xffffd35a) : _terracotta, _ink, pass, band: .08);
  }
}
