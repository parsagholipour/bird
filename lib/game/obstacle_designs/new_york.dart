import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';

/// New York obstacles: brick walk-ups with fire escapes and lit windows
/// under a limestone cornice, an Art Deco limestone pilaster or a cast-iron
/// front; a riveted steel tower with a clock at the rim; stacked stainless
/// Chrysler arches around a turning sunburst; red-oxide I-beam girders;
/// setback skyscraper faces; a green subway-entrance globe; and a spinning
/// jazz record.
abstract final class NewYorkObstacles {
  static const _ink = Color(0xff1d2233);
  static const _brickLit = Color(0xffc9765a), _brick = Color(0xffa5553f);
  static const _brickShade = Color(0xff6f3328), _stone = Color(0xffe6dac3);
  static const _stoneShade = Color(0xffb9a98c), _iron = Color(0xff262a36);
  static const _window = Color(0xffffd46b), _glass = Color(0xff34426a);
  static const _steel = Color(0xffd3dbe6), _steelShade = Color(0xff8e99ab);
  static const _brass = Color(0xffd9a84a);

  static void column(
    Canvas c,
    Rect r, {
    required ObstacleKind kind,
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
  }) {
    final g = Column(r, top);
    final v = (appearance % 3 + 3) % 3;
    c.save();
    c.clipRect(r);
    switch (kind) {
      case ObstacleKind.windLift:
        _clock(c, g, v, pass, reducedMotion ? 0 : seconds);
      case ObstacleKind.petalGate:
        _crown(c, g, v, pass, Kit.spin(seconds, reducedMotion, .35));
      case ObstacleKind.switchback:
        _girder(c, g, v, pass);
      case ObstacleKind.crystalSteps:
        _setback(c, g, v, pass);
      default:
        _walkUp(c, g, v, pass);
    }
    Kit.edge(c, g, _ink, pass);
    c.restore();
  }

  static void orb(
    Canvas c,
    double radius, {
    required ObstacleKind kind,
    required bool upper,
    required double seconds,
    required bool reducedMotion,
    required PassState pass,
    required int appearance,
  }) {
    final v = (appearance % 3 + 3) % 3;
    if (kind == ObstacleKind.lanternDrift) {
      _globe(c, radius, v, upper, pass, reducedMotion ? 0 : seconds);
    } else {
      _record(
        c,
        radius,
        v,
        pass,
        Kit.spin(seconds, reducedMotion, upper ? 1.6 : -1.6),
      );
    }
  }

  static Color _mix(Color a, Color b, double t) => Kit.mix(a, b, t);

  /// Windows lit by a seeded pattern; cleared buildings light up fully.
  static bool _lit(int seed, PassState pass) {
    if (pass.cleared) return true;
    var x = (seed * 374761393 + 668265263) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
    return (x & 0xffff) / 0xffff < .42;
  }

  /// A limestone cornice at the rim: dentils over a frieze with brackets.
  static double _cornice(Canvas c, Column g, PassState pass) {
    final start = Kit.edgeDepth(g);
    final depth = math.min((g.w * .26).clamp(7.0, 16.0), g.h - start);
    if (depth <= 0) return start;
    Kit.fill(c, g.band(start, start + depth), _stone);
    Kit.fill(
      c,
      g.band(start, start + depth * .22),
      _mix(_stone, const Color(0xffffffff), .4),
    );
    final dentil = math.max(3.0, g.w * .08);
    for (var x = g.r.left + 1; x < g.r.right; x += dentil * 1.7) {
      Kit.fill(
        c,
        g.band(start + depth * .3, start + depth * .52, x, x + dentil),
        _stoneShade,
      );
    }
    Kit.fill(
      c,
      g.band(start + depth * .7, start + depth),
      _mix(_stoneShade, _stone, .3),
    );
    for (final fx in const [.12, .88]) {
      final x = g.r.left + g.w * fx;
      Kit.fill(
        c,
        g.band(
          start + depth * .55,
          start + depth,
          x - g.w * .04,
          x + g.w * .04,
        ),
        _stoneShade,
      );
    }
    if (pass.cleared && depth >= 8) {
      Kit.emblem(
        c,
        WorldRegion.newYork,
        Offset(g.cx, g.y(start + depth * .62)),
        depth * .34,
        perfect: pass.perfect,
      );
    }
    return start + depth;
  }

  /// A walk-up: brick with a fire escape, a limestone Art Deco pilaster, or
  /// a painted cast-iron front with arched windows.
  static void _walkUp(Canvas c, Column g, int v, PassState pass) {
    final w = g.w;
    switch (v) {
      case 1:
        Kit.volume(c, g.r, _stone, _mix(_stone, _stoneShade, .3), _stoneShade);
      case 2:
        Kit.volume(
          c,
          g.r,
          const Color(0xff9fb3a8),
          const Color(0xff72887e),
          const Color(0xff4a5c55),
        );
      default:
        Kit.volume(c, g.r, _brickLit, _brick, _brickShade);
    }
    if (w < 10 || g.h < 8) return;
    final from = _cornice(c, g, pass);
    final floor = math.max(22.0, w * .6);
    final dark = Path(), lit = Path();
    var row = 0;
    for (var d = from + floor * .3; d < g.h; d += floor, row++) {
      if (v == 0) {
        // Brick courses between the windows.
        for (var k = 0; k < 3; k++) {
          Kit.fill(
            c,
            g.band(d + floor * (.7 + k * .1), d + floor * (.7 + k * .1) + .8),
            _brickShade.withValues(alpha: .35),
          );
        }
      }
      for (final fx in const [.2, .6]) {
        final win = g.band(
          d,
          d + floor * .52,
          g.r.left + w * fx,
          g.r.left + w * (fx + .22),
        );
        final path = (_lit(row * 7 + (fx * 10).round(), pass) ? lit : dark);
        if (v == 2) {
          path.addRRect(
            RRect.fromRectAndCorners(
              win,
              topLeft: Radius.circular(win.width / 2),
              topRight: Radius.circular(win.width / 2),
            ),
          );
        } else {
          path.addRect(win);
        }
        Kit.fill(
          c,
          Rect.fromLTRB(
            win.left - 1,
            g.top ? win.bottom : win.bottom,
            win.right + 1,
            win.bottom + 1.6,
          ),
          v == 0 ? _stone : _mix(_stoneShade, _ink, .2),
        );
      }
      if (v == 1) {
        // Chevron spandrels between floors, the Deco signature.
        final y = g.y(d + floor * .76);
        c.drawPath(
          Path()
            ..moveTo(g.r.left + w * .2, y + 2)
            ..lineTo(g.cx, y - 2)
            ..lineTo(g.r.right - w * .2, y + 2),
          Paint()
            ..color = _stoneShade
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.2, w * .03),
        );
      }
    }
    c.drawPath(dark, Paint()..color = _glass);
    c.drawPath(lit, Paint()..color = _window);
    if (v == 0) _fireEscape(c, g, from, floor);
  }

  static void _fireEscape(Canvas c, Column g, double from, double floor) {
    final w = g.w;
    final iron = Paint()
      ..color = _iron
      ..strokeWidth = math.max(1.2, w * .03);
    final left = g.r.left + w * .1, right = g.r.right - w * .1;
    var k = 0;
    for (var d = from + floor * .85; d < g.h; d += floor, k++) {
      final y = g.y(d);
      c.drawLine(
        Offset(left, y),
        Offset(right, y),
        iron..strokeWidth = math.max(1.6, w * .04),
      );
      final rail = g.y(d - floor * .22);
      c.drawLine(
        Offset(left, rail),
        Offset(right, rail),
        iron..strokeWidth = math.max(1.0, w * .018),
      );
      for (var x = left; x <= right; x += w * .1) {
        c.drawLine(Offset(x, y), Offset(x, rail), iron);
      }
      // The stair drops diagonally to the next landing.
      final down = k.isEven;
      c.drawLine(
        Offset(down ? left + w * .08 : right - w * .08, y),
        Offset(down ? right - w * .15 : left + w * .15, g.y(d + floor)),
        iron..strokeWidth = math.max(1.4, w * .03),
      );
    }
  }

  /// A riveted green steel tower with a clock face at the rim.
  static void _clock(Canvas c, Column g, int v, PassState pass, double time) {
    const copper = Color(0xff6fb7a1),
        copperLit = Color(0xffa6dccb),
        copperDeep = Color(0xff3f7e6c);
    Kit.volume(c, g.r, copperLit, copper, copperDeep);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 6) / 2, (g.h - start - 4) / 2);
    final face = radius >= 9;
    final from = face ? start + radius * 2 + 6 : start;
    // Riveted panels.
    final panel = math.max(18.0, w * .6);
    final rivet = Paint()..color = _mix(copperDeep, _ink, .3);
    for (var d = from; d < g.h; d += panel) {
      Kit.fill(c, g.band(d, d + 1.6), copperDeep);
      for (var x = g.r.left + w * .12; x < g.r.right; x += w * .19) {
        c.drawCircle(Offset(x, g.y(d + 4)), math.max(.9, w * .022), rivet);
      }
      Kit.fill(
        c,
        g.band(d + panel * .3, d + panel * .85, g.cx - w * .2, g.cx + w * .2),
        _mix(copper, copperDeep, .4),
      );
    }
    if (!face) return;
    Kit.fill(c, g.band(start, from), _mix(copperDeep, _ink, .3));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    c.drawCircle(hub, radius * .96, Paint()..color = _brass);
    c.drawCircle(hub, radius * .84, Paint()..color = const Color(0xfffff5dc));
    // Hour ticks, bolder at the quarters.
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        hub + d * radius * (i % 3 == 0 ? .56 : .66),
        hub + d * radius * .76,
        Paint()
          ..color = _ink
          ..strokeWidth = math.max(1.0, radius * (i % 3 == 0 ? .08 : .04)),
      );
    }
    // Hands keep the replay clock: the minute hand sweeps, the hour creeps.
    final minute = -math.pi / 2 + (time % 60) / 60 * math.pi * 2 + v;
    final hour = -math.pi / 2 + (time % 720) / 720 * math.pi * 2 + v * 2;
    final hand = Paint()
      ..color = _ink
      ..strokeCap = StrokeCap.round;
    c.drawLine(
      hub,
      hub + Offset(math.cos(hour), math.sin(hour)) * radius * .42,
      hand..strokeWidth = math.max(1.6, radius * .1),
    );
    c.drawLine(
      hub,
      hub + Offset(math.cos(minute), math.sin(minute)) * radius * .66,
      hand..strokeWidth = math.max(1.1, radius * .06),
    );
    c.drawCircle(hub, radius * .08, Paint()..color = _brass);
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.newYork,
        hub + Offset(0, radius * .38),
        radius * .22,
        perfect: pass.perfect,
      );
    }
  }

  /// Stacked stainless-steel arches pierced with triangular windows, like
  /// the Chrysler crown, around a turning Deco sunburst.
  static void _crown(Canvas c, Column g, int v, PassState pass, double spin) {
    Kit.fill(c, g.r, _mix(_ink, _glass, .5));
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min(w * .4, (g.h - start - 6) * .42);
    final burst = radius >= 6;
    final from = burst ? start + radius * 2 + 7 : start;
    final pitch = math.max(16.0, w * .42);
    final glow = [_window, const Color(0xffffe9b0), const Color(0xfff5c0ff)][v];
    var k = 0;
    for (var d = from; d < g.h + pitch; d += pitch, k++) {
      // Each arch opens toward the rim and steps out as it recedes.
      final arch = Path()
        ..moveTo(g.r.left, g.y(d + pitch))
        ..lineTo(g.r.left, g.y(d + pitch * .5))
        ..quadraticBezierTo(g.r.left, g.y(d), g.cx, g.y(d))
        ..quadraticBezierTo(g.r.right, g.y(d), g.r.right, g.y(d + pitch * .5))
        ..lineTo(g.r.right, g.y(d + pitch))
        ..close();
      c.drawPath(
        arch,
        Paint()
          ..shader = LinearGradient(
            colors: const [_steel, Color(0xfff6f9ff), _steelShade],
            stops: const [0, .35, 1],
          ).createShader(g.r),
      );
      // Rays of the arch.
      final ray = Paint()
        ..color = _steelShade
        ..strokeWidth = math.max(.8, w * .015);
      for (var i = 1; i < 6; i++) {
        final x = g.r.left + w * i / 6;
        c.drawLine(
          Offset(x, g.y(d + pitch * .2)),
          Offset(g.cx + (x - g.cx) * 1.2, g.y(d + pitch)),
          ray,
        );
      }
      // A row of triangular windows.
      final lit = Paint()..color = glow;
      for (var i = 0; i < 3; i++) {
        final x = g.r.left + w * (.25 + i * .25);
        final y = g.y(d + pitch * .55);
        c.drawPath(
          Kit.poly([
            x,
            y + g.dir * pitch * -.14,
            x + w * .06,
            y + g.dir * pitch * .12,
            x - w * .06,
            y + g.dir * pitch * .12,
          ]),
          lit,
        );
      }
    }
    if (!burst) return;
    Kit.fill(c, g.band(start, from), _ink);
    final hub = Offset(g.cx, g.y(start + radius + 3.5));
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    for (var i = 0; i < 16; i++) {
      c.save();
      c.rotate(i * math.pi / 8);
      c.drawPath(
        Kit.poly([
          -radius * .1,
          0,
          0,
          -radius * (i.isEven ? 1.0 : .7),
          radius * .1,
          0,
        ]),
        Paint()..color = i.isEven ? _brass : _steel,
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(hub, radius * .3, Paint()..color = _ink);
    c.drawCircle(hub, radius * .22, Paint()..color = glow);
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.newYork,
        hub,
        radius * .3,
        perfect: pass.perfect,
      );
    }
  }

  /// A red-oxide I-beam: flanges, web, rivet rows and an end plate whose
  /// stencilled arrow points at the opening.
  static void _girder(Canvas c, Column g, int v, PassState pass) {
    final paint = [
      (
        const Color(0xffd8654a),
        const Color(0xffb5452f),
        const Color(0xff7a2a1f),
      ),
      (
        const Color(0xff8a9aa8),
        const Color(0xff66778a),
        const Color(0xff3f4b5a),
      ),
      (
        const Color(0xffe0a64a),
        const Color(0xffc27f2a),
        const Color(0xff84521a),
      ),
    ][v];
    final w = g.w;
    Kit.fill(c, g.r, paint.$3);
    if (w < 10 || g.h < 8) return;
    // Flanges on both sides, the recessed web between them.
    final flange = w * .22;
    Kit.volume(
      c,
      Rect.fromLTRB(g.r.left, g.r.top, g.r.left + flange, g.r.bottom),
      paint.$1,
      paint.$2,
      paint.$3,
    );
    Kit.volume(
      c,
      Rect.fromLTRB(g.r.right - flange, g.r.top, g.r.right, g.r.bottom),
      paint.$1,
      paint.$2,
      paint.$3,
    );
    Kit.fill(
      c,
      Rect.fromLTRB(g.r.left + flange, g.r.top, g.r.right - flange, g.r.bottom),
      _mix(paint.$2, paint.$3, .55),
    );
    final start = Kit.edgeDepth(g);
    final plate = math.min(w * .6, g.h - start);
    Kit.fill(c, g.band(start, start + plate), paint.$2);
    Kit.fill(c, g.band(start + plate - 1.5, start + plate), paint.$3);
    // Stencilled arrow on the end plate.
    final arrow = pass.cleared
        ? (pass.perfect ? const Color(0xffffd45b) : const Color(0xffbff0cf))
        : const Color(0xfffff3dc);
    final tip = g.y(start + plate * .18), back = g.y(start + plate * .82);
    c.drawPath(
      Kit.poly([
        g.cx,
        tip,
        g.cx + w * .2,
        g.y(start + plate * .5),
        g.cx + w * .07,
        g.y(start + plate * .5), //
        g.cx + w * .07,
        back,
        g.cx - w * .07,
        back,
        g.cx - w * .07,
        g.y(start + plate * .5),
        g.cx - w * .2, g.y(start + plate * .5),
      ]),
      Paint()..color = arrow,
    );
    // Rivets march down the flanges; diagonal lattice ties the web.
    final rivet = Paint()..color = _mix(paint.$1, const Color(0xffffffff), .25);
    final pitch = math.max(8.0, w * .22);
    for (var d = start + plate + 4; d < g.h; d += pitch) {
      c.drawCircle(
        Offset(g.r.left + flange * .5, g.y(d)),
        math.max(.9, w * .03),
        rivet,
      );
      c.drawCircle(
        Offset(g.r.right - flange * .5, g.y(d)),
        math.max(.9, w * .03),
        rivet,
      );
    }
    final lattice = Paint()
      ..color = paint.$2
      ..strokeWidth = math.max(1.4, w * .05);
    final bay = math.max(18.0, w * .7);
    var k = 0;
    for (var d = start + plate; d < g.h; d += bay, k++) {
      c.drawLine(
        Offset(k.isEven ? g.r.left + flange : g.r.right - flange, g.y(d)),
        Offset(k.isEven ? g.r.right - flange : g.r.left + flange, g.y(d + bay)),
        lattice,
      );
    }
    if (pass.cleared && g.h > start + plate + w * .5) {
      Kit.emblem(
        c,
        WorldRegion.newYork,
        Offset(g.cx, g.y(start + plate + w * .35)),
        w * .16,
        perfect: pass.perfect,
      );
    }
  }

  /// A setback skyscraper face: stepped Deco cap and a grid of windows.
  static void _setback(Canvas c, Column g, int v, PassState pass) {
    final stone = [
      (
        const Color(0xffeee4d0),
        const Color(0xffd4c6aa),
        const Color(0xffa8987a),
      ),
      (
        const Color(0xffd8b89a),
        const Color(0xffbb9272),
        const Color(0xff8a6448),
      ),
      (
        const Color(0xffc9cfd9),
        const Color(0xffa3abb9),
        const Color(0xff737c8d),
      ),
    ][v];
    Kit.volume(c, g.r, stone.$1, stone.$2, stone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // Stepped crown: three receding tiers with a chevron band.
    final crown = math.min(w * .7, g.h - start);
    for (var tier = 0; tier < 3; tier++) {
      final inset = w * (.3 - tier * .12);
      Kit.fill(
        c,
        g.band(
          start + crown * tier / 3,
          start + crown * (tier + 1) / 3,
          g.r.left + inset,
          g.r.right - inset,
        ),
        tier.isEven ? stone.$1 : stone.$2,
      );
    }
    Kit.fill(
      c,
      g.band(start, start + crown * .33, g.r.left, g.r.left + w * .3),
      stone.$3,
    );
    Kit.fill(
      c,
      g.band(start, start + crown * .33, g.r.right - w * .3, g.r.right),
      stone.$3,
    );
    Kit.fill(
      c,
      g.band(
        start + crown * .33,
        start + crown * .66,
        g.r.left,
        g.r.left + w * .18,
      ),
      _mix(stone.$3, _ink, .2),
    );
    Kit.fill(
      c,
      g.band(
        start + crown * .33,
        start + crown * .66,
        g.r.right - w * .18,
        g.r.right,
      ),
      _mix(stone.$3, _ink, .2),
    );
    Kit.fill(c, g.band(start + crown - 2, start + crown), _brass);
    // Window grid: tall piers between lit and dark panes.
    final lit = Path(), dark = Path();
    final floor = math.max(9.0, w * .26);
    var row = 0;
    for (var d = start + crown + 3; d < g.h; d += floor, row++) {
      for (var col = 0; col < 3; col++) {
        final x = g.r.left + w * (.14 + col * .27);
        final pane = g.band(d, d + floor * .62, x, x + w * .16);
        ((_lit(row * 3 + col + v * 11, pass)) ? lit : dark).addRect(pane);
      }
    }
    c.drawPath(dark, Paint()..color = _glass);
    c.drawPath(lit, Paint()..color = _window);
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.newYork,
        Offset(g.cx, g.y(start + crown * .5)),
        math.min(w * .15, crown * .25),
        perfect: pass.perfect,
      );
    }
  }

  /// A subway entrance globe: green glass under a cast-iron cap.
  static void _globe(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    double time,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    final glass = [
      const Color(0xff5fd08a),
      const Color(0xff9ce07a),
      const Color(0xffff8a7a),
    ][v];
    final hum = .9 + .1 * math.sin(time * 5.1 + v);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, .1),
          colors: [
            _mix(glass, const Color(0xffffffff), .7 * hum),
            glass,
            _mix(glass, _ink, .45),
          ],
          stops: const [0, .5, 1],
        ).createShader(bounds),
    );
    // Ribbed glass and the iron cage around it.
    final cage = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * .05)
      ..color = _iron;
    for (final k in const [.4, .8]) {
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2 * k, height: r * 2),
        cage,
      );
    }
    final side = upper ? -1.0 : 1.0;
    c.drawRect(
      Rect.fromLTRB(-r, side < 0 ? -r : r * .62, r, side < 0 ? -r * .62 : r),
      Paint()..color = _iron,
    );
    c.drawRect(
      Rect.fromLTRB(-r, side < 0 ? r * .72 : -r, r, side < 0 ? r : -r * .72),
      Paint()..color = _mix(_iron, _brass, .3),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-r * .35, -r * .15),
        width: r * .2,
        height: r * .44,
      ),
      Paint()..color = const Color(0x66ffffff),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.newYork,
        Offset.zero,
        r * .24,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, _mix(_iron, _brass, .45), _ink, pass, band: .08);
  }

  /// A spinning jazz record: grooves catch a fixed highlight while the
  /// label turns.
  static void _record(Canvas c, double r, int v, PassState pass, double spin) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(Offset.zero, r, Paint()..color = const Color(0xff17161f));
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, r * .012)
      ..color = const Color(0xff34334a);
    for (var k = .42; k < .95; k += .06) {
      c.drawCircle(Offset.zero, r * k, groove);
    }
    // Two static sheen wedges sell the spin.
    for (final a in const [-2.4, .74]) {
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * .7),
        a,
        .5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .5
          ..color = const Color(0x22e8e6ff),
      );
    }
    final label = [
      const Color(0xffe8453c),
      const Color(0xff3f7fd0),
      const Color(0xfff2c14e),
    ][v];
    c.save();
    c.rotate(spin);
    c.drawCircle(Offset.zero, r * .36, Paint()..color = label);
    c.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * .26),
      -2.6,
      2.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, r * .05)
        ..color = const Color(0xfffff3dc),
    );
    c.drawRect(
      Rect.fromCenter(
        center: Offset(0, r * .16),
        width: r * .3,
        height: r * .05,
      ),
      Paint()..color = const Color(0xfffff3dc),
    );
    c.restore();
    c.drawCircle(
      Offset.zero,
      r * .05,
      Paint()..color = const Color(0xff17161f),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.newYork,
        Offset.zero,
        r * .22,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, const Color(0xff4a4860), _ink, pass, band: .07);
  }
}
