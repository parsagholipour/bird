import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Brazilian obstacles: Copacabana wave mosaic in black and white stone; a
/// giant football spinning on a green plinth; carnival bands of feather
/// and sequin; a goal with a white net over turf; terraced stadium seats;
/// a football floating free; and a spinning pandeiro with jingles.
abstract final class BrazilObstacles {
  static const _ink = Color(0xff1f3a2a);
  static const _green = Color(0xff2fa85a), _greenDeep = Color(0xff1f7a40);
  static const _yellow = Color(0xffffdc2e), _blue = Color(0xff2f6fd0);
  static const _white = Color(0xfffffcf0), _black = Color(0xff26303a);
  static const _magenta = Color(0xffe6407a), _cyan = Color(0xff2fc4d6);
  static const _orange = Color(0xffff8a3a);

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
    garden: _mosaic,
    wind: _plinth,
    petal: _carnival,
    switchback: _goal,
    steps: _stands,
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
    lantern: _football,
    wheel: _pandeiro,
  );

  /// A wavy band across the shaft, [amp] tall, from distance [d].
  static void _wave(Canvas c, Column g, double d, double thick, double amp, Color color, double phase) {
    final path = Path();
    final left = g.r.left, width = g.w;
    path.moveTo(left, g.y(d));
    for (var x = 0.0; x <= width; x += 3) {
      path.lineTo(left + x, g.y(d + amp * math.sin(x / width * math.pi * 2 + phase)));
    }
    path.lineTo(left + width, g.y(d + amp * math.sin(math.pi * 2 + phase) + thick));
    for (var x = width; x >= 0; x -= 3) {
      path.lineTo(left + x, g.y(d + thick + amp * math.sin(x / width * math.pi * 2 + phase)));
    }
    c.drawPath(path..close(), Paint()..color = color);
  }

  /// Copacabana's wave mosaic under a green and yellow collar.
  static void _mosaic(Canvas c, Column g, int v, PassState pass, Motion m) {
    final light = [const Color(0xfffffcf0), const Color(0xfff3ecd8), const Color(0xffeaf3f0)][v];
    Kit.volume(c, g.r, light, _mix(light, const Color(0xffd8d0b8), .5), const Color(0xffb8b098));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final collar = math.min((w * .3).clamp(7.0, 16.0), g.h - start);
    Kit.fill(c, g.band(start, start + collar), _green);
    Kit.fill(c, g.band(start + collar * .35, start + collar * .65), pass.perfect ? const Color(0xffffd35a) : _yellow);
    final thick = math.max(5.0, w * .2);
    final wave = math.max(2.0, w * .09);
    var k = 0;
    for (var d = start + collar + wave + 3; d + thick + wave < g.h; d += thick * 2, k++) {
      _wave(c, g, d, thick, wave, _black, k * 1.1 + v);
    }
    Parts.seal(c, g, WorldRegion.brazil, start + collar * .5, math.min(w * .14, collar * .4), pass);
  }

  /// A giant football turning on a striped plinth.
  static void _plinth(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = [_green, const Color(0xff2f8fc0), _yellow][v];
    Kit.volume(c, g.r, _mix(tone, _white, .35), tone, _mix(tone, _ink, .4));
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final ball = radius >= 9;
    final from = ball ? start + radius * 2 + 6 : start;
    Parts.stripes(c, g, from, math.max(6.0, w * .2), [tone, _mix(tone, _ink, .25)]);
    if (!ball) return;
    Kit.fill(c, g.band(start, start + radius * 2 + 6), _mix(tone, _ink, .5));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    _ball(c, hub, radius, m.spin(.9, v * .6), _black);
    Parts.seal(c, g, WorldRegion.brazil, start + radius + 3, radius * .2, pass);
  }

  /// Bands of carnival feather and sequin that shimmer down the shaft.
  static void _carnival(Canvas c, Column g, int v, PassState pass, Motion m) {
    final order = [
      [_magenta, _yellow, _cyan, _orange],
      [_cyan, _green, _yellow, _magenta],
      [_orange, _magenta, _blue, _yellow],
    ][v];
    Kit.volume(c, g.r, _mix(order[0], _white, .3), order[0], _mix(order[0], _ink, .4));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final thick = math.max(6.0, w * .3);
    Parts.stripes(c, g, start, thick, order, shift: m.time * 14);
    final spark = Paint()..color = _white.withValues(alpha: .8);
    var row = 0;
    for (var d = start + thick * .5; d < g.h; d += thick, row++) {
      for (var x = g.r.left + w * (row.isEven ? .25 : .5); x < g.r.right; x += w * .5) {
        c.drawCircle(Offset(x, g.y(d)), math.max(.8, w * .03), spark);
      }
    }
    Parts.seal(c, g, WorldRegion.brazil, start + thick * .5, math.min(w * .15, thick * .4), pass);
  }

  /// A goal: white posts and crossbar around a net over green turf.
  static void _goal(Canvas c, Column g, int v, PassState pass, Motion m) {
    final turf = [_green, const Color(0xff3fb86a), _greenDeep][v];
    Kit.volume(c, g.r, _mix(turf, _white, .25), turf, _mix(turf, _ink, .4));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final bar = math.min(math.max(4.0, w * .16), g.h - start);
    Parts.lattice(c, g, start + bar, math.max(6.0, w * .28), _white.withValues(alpha: .7), width: math.max(.8, w * .03));
    Kit.fill(c, g.band(start, start + bar), _white);
    Kit.fill(c, g.band(start + bar - 1.5, start + bar), _mix(_white, _ink, .3));
    final post = math.max(2.0, w * .09);
    Kit.fill(c, g.band(start, g.h, g.r.left + 1, g.r.left + 1 + post), _white);
    Kit.fill(c, g.band(start, g.h, g.r.right - 1 - post, g.r.right - 1), _white);
    Parts.seal(c, g, WorldRegion.brazil, start + bar + w * .2, math.min(w * .14, 8), pass);
  }

  /// Terraced stadium seating: rows of yellow, green, blue and white seats.
  static void _stands(Canvas c, Column g, int v, PassState pass, Motion m) {
    final concrete = [const Color(0xffb8c0c8), const Color(0xffc8c0b0), const Color(0xffa8b8c0)][v];
    Kit.volume(c, g.r, _mix(concrete, _white, .3), concrete, _mix(concrete, _ink, .4));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final rail = math.min(math.max(4.0, w * .14), g.h - start);
    Kit.fill(c, g.band(start, start + rail), pass.perfect ? const Color(0xffffd35a) : _yellow);
    Kit.fill(c, g.band(start + rail - 1.5, start + rail), _greenDeep);
    const seats = [_yellow, _green, _blue, _white];
    var row = 0;
    for (var d = start + rail + 2; d < g.h; d += 9, row++) {
      Kit.fill(c, g.band(d + 6, d + 8, g.r.left, g.r.right), _mix(concrete, _ink, .3));
      var i = 0;
      for (var x = g.r.left + 1; x < g.r.right - 1; x += 5, i++) {
        Kit.fill(c, g.band(d, d + 6, x, math.min(x + 3.6, g.r.right)), seats[(i + row + v) % seats.length]);
      }
    }
    Parts.seal(c, g, WorldRegion.brazil, start + rail * .5, math.min(w * .13, rail * .4), pass);
  }

  static void _ball(Canvas c, Offset at, double r, double spin, Color patch) {
    c.drawCircle(at, r, Paint()..color = _white);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(spin);
    final dark = Paint()..color = patch;
    c.drawPath(
      Kit.poly([0, -r * .36, r * .34, -r * .11, r * .21, r * .29, -r * .21, r * .29, -r * .34, -r * .11]),
      dark,
    );
    final seam = Paint()
      ..color = patch
      ..strokeWidth = math.max(.8, r * .05)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(d * r * .36, d * r * .68, seam);
      final side = Offset(-d.dy, d.dx);
      c.drawPath(
        Path()
          ..moveTo(d.dx * r * .68 - side.dx * r * .16, d.dy * r * .68 - side.dy * r * .16)
          ..lineTo(d.dx * r * 1.05, d.dy * r * 1.05)
          ..lineTo(d.dx * r * .68 + side.dx * r * .16, d.dy * r * .68 + side.dy * r * .16)
          ..close(),
        dark,
      );
    }
    c.restore();
    c.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, r * .06)
        ..color = _black,
    );
  }

  /// A football floating free, its seams turning slowly.
  static void _football(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    Parts.orbBegin(c, r, _white, const Color(0xffefe8d4), const Color(0xffb8b098));
    _ball(c, Offset.zero, r * .96, m.spin(upper ? .5 : -.5, v * .5), [_black, _greenDeep, const Color(0xff2f4fa0)][v]);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.brazil, Offset.zero, r * .2, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, pass.perfect ? const Color(0xffffd35a) : _green, _ink, pass, band: .07);
  }

  /// A pandeiro: a yellow skin ringed in green with turning jingles.
  static void _pandeiro(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final skin = [_yellow, const Color(0xffffb84a), const Color(0xffffe98a)][v];
    Parts.orbBegin(c, r, _mix(skin, _white, .5), skin, _mix(skin, _orange, .6));
    final spin = m.spin(upper ? .7 : -.7);
    c.save();
    c.rotate(spin);
    const spokes = 10;
    for (var i = 0; i < spokes; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / spokes);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(-r * .16, -r * .58)
          ..lineTo(r * .16, -r * .58)
          ..close(),
        Paint()..color = i.isEven ? _green : _blue,
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(
      Offset.zero,
      r * .74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .18
        ..color = _greenDeep,
    );
    for (var i = 0; i < 8; i++) {
      final a = -spin * .5 + i * math.pi / 4;
      final p = Offset(math.cos(a), math.sin(a)) * r * .74;
      c.drawCircle(p, r * .07, Paint()..color = const Color(0xffe8f0f4));
      c.drawCircle(p, r * .07, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, r * .02)
        ..color = _black);
    }
    c.drawCircle(Offset.zero, r * .2, Paint()..color = _white);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.brazil, Offset.zero, r * .18, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, pass.perfect ? const Color(0xffffd35a) : _greenDeep, _ink, pass, band: .1);
  }
}
