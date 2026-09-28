import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';

/// Antarctic obstacles: glacier-ice pillars banded with annual layers and
/// capped with snow or icicles; a rimed instrument mast with a spinning cup
/// anemometer; a frost-plate column around a turning snowflake; striped
/// polar marker poles with mirror caps; snow-ledged serac blocks; an ice
/// lantern with a warm flame; and a snowflake medallion.
abstract final class AntarcticaObstacles {
  static const _ink = Color(0xff1f3552);
  static const _iceLit = Color(0xffeef9ff), _ice = Color(0xffb4dcf1);
  static const _iceShade = Color(0xff7cb2d6), _iceDeep = Color(0xff4c83b3);
  static const _snow = Color(0xfffcfeff), _snowShade = Color(0xffd3e3f1);
  static const _orange = Color(0xffe8743f), _red = Color(0xffd8453a);

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
        _mast(c, g, v, pass, Kit.spin(seconds, reducedMotion, 2.2, v * .7));
      case ObstacleKind.petalGate:
        _frost(c, g, v, pass, Kit.spin(seconds, reducedMotion, .3));
      case ObstacleKind.switchback:
        _marker(c, g, v, pass);
      case ObstacleKind.crystalSteps:
        _serac(c, g, v, pass);
      default:
        _pillar(c, g, v, pass);
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
      _iceLantern(c, radius, v, upper, pass, reducedMotion ? 0 : seconds);
    } else {
      _medallion(
        c,
        radius,
        v,
        pass,
        Kit.spin(seconds, reducedMotion, upper ? .35 : -.35),
      );
    }
  }

  static Color _mix(Color a, Color b, double t) => Kit.mix(a, b, t);

  /// The rim cap: a snow cushion on standing pillars, an icicle fringe on
  /// hanging ones. Returns its depth.
  static double _cap(Canvas c, Column g, {double scale = 1}) {
    final start = Kit.edgeDepth(g);
    final depth = math.min((g.w * .24 * scale).clamp(6.0, 16.0), g.h - start);
    if (depth <= 0) return start;
    final band = g.band(start, start + depth);
    if (!g.top) {
      Kit.fill(c, band, _snow);
      // Drips of snow hang over the ice below.
      final drip = Path()..moveTo(g.r.left, g.y(start + depth * .6));
      final n = math.max(2, (g.w / 12).round());
      for (var i = 0; i < n; i++) {
        final x0 = g.r.left + g.w * i / n, x1 = g.r.left + g.w * (i + 1) / n;
        drip.quadraticBezierTo(
          (x0 + x1) / 2,
          g.y(start + depth * (1.05 + .25 * (i % 2))),
          x1,
          g.y(start + depth * .6),
        );
      }
      drip
        ..lineTo(g.r.right, g.y(start))
        ..lineTo(g.r.left, g.y(start))
        ..close();
      c.drawPath(drip, Paint()..color = _snow);
      Kit.fill(
        c,
        g.band(start + depth * .15, start + depth * .35),
        _snowShade.withValues(alpha: .6),
      );
    } else {
      Kit.fill(c, band, _mix(_iceDeep, _ink, .2));
      // Icicles point down at the opening.
      final n = math.max(3, (g.w / 8).round());
      final pitch = g.w / n;
      for (var i = 0; i < n; i++) {
        final x = g.r.left + pitch * i;
        final len = depth * (.6 + .4 * ((i * 7) % 3) / 2);
        c.drawPath(
          Kit.poly([
            x,
            g.y(start + depth),
            x + pitch,
            g.y(start + depth),
            x + pitch * .5,
            g.y(start + depth - len),
          ]),
          Paint()..color = i.isEven ? _iceLit : _ice,
        );
      }
      Kit.fill(c, g.band(start + depth * .82, start + depth), _snow);
    }
    return start + depth;
  }

  /// Glacier ice banded with annual layers, bubbles and a lit core.
  static void _pillar(Canvas c, Column g, int v, PassState pass) {
    final body = [
      _ice,
      _mix(_ice, const Color(0xffcfd8ea), .5),
      _mix(_ice, _iceShade, .3),
    ][v];
    Kit.volume(c, g.r, _iceLit, body, _iceShade);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final from = _cap(c, g);
    // Annual layers: gently wavy bands, anchored to the rim.
    final pitch = math.max(12.0, w * .38);
    var k = 0;
    for (var d = from + pitch * .4; d < g.h + pitch; d += pitch, k++) {
      final color = v == 1 && k % 3 == 1
          ? const Color(0xff8f9bb0).withValues(alpha: .55)
          : (k.isEven ? _iceLit : _iceShade).withValues(alpha: .5);
      final y0 = g.y(d);
      final path = Path()..moveTo(g.r.left, y0);
      for (var i = 1; i <= 4; i++) {
        path.lineTo(g.r.left + w * i / 4, y0 + (i.isOdd ? 1.5 : -1.5));
      }
      path
        ..lineTo(g.r.right, y0 + g.dir * pitch * .22)
        ..lineTo(g.r.left, y0 + g.dir * pitch * .22)
        ..close();
      c.drawPath(path, Paint()..color = color);
    }
    // A glowing core runs through clear ice.
    Kit.fill(
      c,
      g.band(from, g.h, g.r.left + w * .22, g.r.left + w * .34),
      _iceLit.withValues(alpha: .55),
    );
    final bubble = Paint()..color = _iceLit.withValues(alpha: .8);
    for (var i = 0; i < 40; i++) {
      final d = from + 8 + i * math.max(9.0, w * .3);
      if (d > g.h) break;
      final x = g.r.left + w * (.28 + .5 * ((i * 37) % 11) / 10);
      c.drawCircle(
        Offset(x, g.y(d)),
        math.max(.9, w * (.015 + .012 * (i % 3))),
        bubble,
      );
    }
    if (v == 2) {
      // Hoarfrost feathers along the windward edge.
      final feather = Paint()
        ..color = _snow.withValues(alpha: .85)
        ..strokeWidth = math.max(1.0, w * .025)
        ..strokeCap = StrokeCap.round;
      for (var d = from + 4; d < g.h; d += 9) {
        final y = g.y(d);
        c.drawLine(
          Offset(g.r.left + 1, y),
          Offset(g.r.left + w * .16, y + g.dir * 4),
          feather,
        );
      }
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.antarctica,
        Offset(g.cx, g.y(from + math.min(w * .3, (g.h - from) * .4))),
        w * .15,
        perfect: pass.perfect,
      );
    }
  }

  /// A rimed lattice mast banded in station orange, with a cup anemometer
  /// spinning at the rim.
  static void _mast(Canvas c, Column g, int v, PassState pass, double spin) {
    const steel = Color(0xff8d9bad),
        steelLit = Color(0xffd6e0ea),
        steelDeep = Color(0xff5d6a7d);
    Kit.volume(
      c,
      g.r,
      _mix(steelDeep, _ink, .15),
      _mix(steelDeep, _ink, .3),
      _mix(steelDeep, _ink, .45),
    );
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 6) / 2, (g.h - start - 4) / 2);
    final head = radius >= 9;
    final from = head ? start + radius * 2 + 6 : start;
    // Lattice: two legs and X bracing, repeating from the head.
    final leg = Paint()
      ..color = steel
      ..strokeWidth = math.max(2.0, w * .07);
    final brace = Paint()
      ..color = steel
      ..strokeWidth = math.max(1.2, w * .035);
    final l = g.r.left + w * .12, rr = g.r.right - w * .12;
    c.drawLine(Offset(l, g.y(from)), Offset(l, g.y(g.h)), leg);
    c.drawLine(Offset(rr, g.y(from)), Offset(rr, g.y(g.h)), leg);
    final pitch = math.max(16.0, w * .6);
    var k = 0;
    for (var d = from; d < g.h; d += pitch, k++) {
      c.drawLine(Offset(l, g.y(d)), Offset(rr, g.y(d + pitch)), brace);
      c.drawLine(Offset(rr, g.y(d)), Offset(l, g.y(d + pitch)), brace);
      c.drawLine(Offset(l, g.y(d)), Offset(rr, g.y(d)), brace);
      // Station-orange warning bands on alternate panels.
      if (k % 3 == 0) {
        Kit.fill(c, g.band(d, d + pitch * .18), v == 1 ? _red : _orange);
        Kit.fill(c, g.band(d + pitch * .18, d + pitch * .24), _snow);
      }
    }
    // Rime ice feathers the windward leg.
    final rime = Paint()..color = _snow.withValues(alpha: .9);
    for (var d = from + 3; d < g.h; d += 7) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(l - 1, g.y(d)),
          width: w * .14,
          height: 3,
        ),
        rime,
      );
    }
    Kit.fill(c, g.band(from, g.h, l - 1, l), steelLit);
    if (!head) return;
    Kit.fill(c, g.band(start, from), _mix(const Color(0xff2c4466), _ink, .2));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    final arm = Paint()
      ..color = steelLit
      ..strokeWidth = math.max(1.4, radius * .1)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final a = spin + i * math.pi * 2 / 3;
      final dir = Offset(math.cos(a), math.sin(a));
      final end = hub + dir * radius * .66;
      c.drawLine(hub, end, arm);
      // Hemispherical cups, open side trailing the spin.
      final cup = Rect.fromCircle(center: end, radius: radius * .28);
      c.drawArc(
        cup,
        a + math.pi / 2,
        math.pi,
        true,
        Paint()..color = i == 0 ? _red : steelLit,
      );
      c.drawArc(
        cup,
        a - math.pi / 2,
        math.pi,
        true,
        Paint()..color = _mix(steelDeep, _ink, .2),
      );
    }
    c.drawCircle(hub, radius * .18, Paint()..color = _orange);
    c.drawCircle(
      hub + Offset(-radius * .05, -radius * .05),
      radius * .06,
      Paint()..color = _snow,
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.antarctica,
        hub,
        radius * .3,
        perfect: pass.perfect,
      );
    }
  }

  /// Overlapping frost plates grow toward the rim around a turning
  /// snowflake set in a frosted collar.
  static void _frost(Canvas c, Column g, int v, PassState pass, double spin) {
    Kit.volume(c, g.r, _iceLit, _mix(_ice, _iceShade, .2), _iceDeep);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min(w * .4, (g.h - start - 6) * .42);
    final bloom = radius >= 6;
    final from = bloom ? start + radius * 2 + 7 : start;
    final pitch = math.max(12.0, w * .24);
    final per = v == 1 ? 2 : 3;
    final plate = w / per;
    var k = 0;
    for (var d = from; d < g.h + pitch; d += pitch, k++) {
      final shift = k.isOdd ? plate / 2 : 0.0;
      for (var x = g.r.left - shift; x < g.r.right; x += plate) {
        // Hexagonal frost plates, pointed at the rim.
        final tip = g.y(d), back = g.y(d + pitch * 1.4);
        final mid = g.y(d + pitch * .45);
        c.drawPath(
          Kit.poly([
            x + plate * .5,
            tip,
            x + plate,
            mid,
            x + plate,
            back,
            x,
            back,
            x,
            mid,
          ]),
          Paint()
            ..color = (k + (x > g.cx ? 1 : 0)).isEven
                ? _mix(_iceLit, _ice, .35)
                : _mix(_ice, _iceShade, .3),
        );
        c.drawLine(
          Offset(x + plate * .5, tip + g.dir * 2),
          Offset(x + plate * .5, g.y(d + pitch)),
          Paint()
            ..color = _snow.withValues(alpha: .8)
            ..strokeWidth = math.max(.8, w * .018),
        );
      }
    }
    if (!bloom) return;
    Kit.fill(c, g.band(start, from), _mix(_iceDeep, _ink, .35));
    final hub = Offset(g.cx, g.y(start + radius + 3.5));
    c.drawCircle(hub, radius * .96, Paint()..color = _mix(_iceDeep, _ice, .3));
    _snowflake(c, hub, radius * .9, spin, _snow, math.max(1.3, radius * .12));
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.antarctica,
        hub,
        radius * .32,
        perfect: pass.perfect,
      );
    }
  }

  static void _snowflake(
    Canvas c,
    Offset at,
    double r,
    double spin,
    Color color,
    double stroke,
  ) {
    final arm = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(spin);
    for (var i = 0; i < 6; i++) {
      c.save();
      c.rotate(i * math.pi / 3);
      c.drawLine(Offset.zero, Offset(0, -r), arm);
      for (final (k, len) in const [(.4, .3), (.66, .22)]) {
        c.drawLine(
          Offset(0, -r * k),
          Offset(-r * len, -r * (k + len * .8)),
          arm,
        );
        c.drawLine(
          Offset(0, -r * k),
          Offset(r * len, -r * (k + len * .8)),
          arm,
        );
      }
      c.restore();
    }
    c.drawCircle(Offset.zero, r * .14, Paint()..color = color);
    c.restore();
  }

  /// A striped polar marker pole with a mirror-bright cap and chevrons that
  /// point at the opening.
  static void _marker(Canvas c, Column g, int v, PassState pass) {
    final stripe = [_red, const Color(0xff27344f), const Color(0xff2f5f9a)][v];
    Kit.fill(c, g.r, _snow);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final capH = math.min(w * .5, g.h - start);
    // Survey bands: bold red and white, measured from the rim.
    final from = start + capH;
    final pitch = math.max(12.0, w * .55);
    final band = Paint()..color = stripe;
    for (var d = from; d < g.h; d += pitch * 2) {
      c.drawRect(g.band(d, d + pitch), band);
    }
    // Cylinder shading over the stripes.
    c.drawRect(
      g.band(from, g.h),
      Paint()
        ..shader = LinearGradient(
          colors: [
            _snow.withValues(alpha: .35),
            const Color(0x00ffffff),
            _ink.withValues(alpha: .25),
          ],
          stops: const [0, .45, 1],
        ).createShader(g.r),
    );
    // Mirror cap: a polished steel band reflecting sky and snow.
    final cap = g.band(start, start + capH);
    c.drawRect(
      cap,
      Paint()
        ..shader = LinearGradient(
          colors: const [
            Color(0xff6f86a6),
            Color(0xfff4f8ff),
            Color(0xff9fb4cf),
            Color(0xff3f5577),
          ],
          stops: const [0, .3, .6, 1],
        ).createShader(cap),
    );
    // Chevron flags point to the opening.
    final chevron = Paint()
      ..color = pass.cleared
          ? (pass.perfect ? const Color(0xffffd45b) : const Color(0xffbff0cf))
          : stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, w * .08)
      ..strokeJoin = StrokeJoin.round;
    for (var k = 0; k < 2; k++) {
      final d = start + capH * (.3 + k * .32);
      c.drawPath(
        Path()
          ..moveTo(g.r.left + w * .22, g.y(d + capH * .16))
          ..lineTo(g.cx, g.y(d))
          ..lineTo(g.r.right - w * .22, g.y(d + capH * .16)),
        chevron,
      );
    }
    if (pass.cleared && g.h > from + w * .5) {
      Kit.emblem(
        c,
        WorldRegion.antarctica,
        Offset(g.cx, g.y(from + w * .35)),
        w * .16,
        perfect: pass.perfect,
      );
    }
  }

  /// Serac blocks of blue ice with snow on every ledge.
  static void _serac(Canvas c, Column g, int v, PassState pass) {
    final tint = [
      _ice,
      _mix(_ice, const Color(0xffa9c7ec), .5),
      _mix(_ice, const Color(0xff9ad8e0), .5),
    ][v];
    Kit.volume(c, g.r, _iceLit, tint, _iceDeep);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // A faceted table of ice at the rim.
    final table = math.min(w * .34, g.h - start);
    Kit.fill(c, g.band(start, start + table), _mix(_iceLit, _ice, .3));
    c.drawPath(
      Kit.poly([
        g.r.left, g.y(start), g.r.left + w * .38, g.y(start), //
        g.r.left + w * .2, g.y(start + table), g.r.left, g.y(start + table),
      ]),
      Paint()..color = _snow,
    );
    c.drawPath(
      Kit.poly([
        g.r.right - w * .3, g.y(start), g.r.right, g.y(start), //
        g.r.right, g.y(start + table),
      ]),
      Paint()..color = _iceShade,
    );
    final block = math.max(18.0, w * .7);
    var k = 0;
    for (var d = start + table; d < g.h; d += block, k++) {
      // Each ledge holds a cushion of snow over a blue crack.
      Kit.fill(c, g.band(d, d + 1.4), _mix(_iceDeep, _ink, .2));
      if (!g.top) {
        Kit.fill(c, g.band(d + 1.4, d + 4.5), _snow);
      } else {
        Kit.fill(c, g.band(d - 3, d), _snow);
      }
      final seam = g.r.left + w * (k.isOdd ? .3 : .64);
      c.drawLine(
        Offset(seam, g.y(d + 3)),
        Offset(seam + w * .08, g.y(d + block - 2)),
        Paint()
          ..color = _iceShade
          ..strokeWidth = math.max(1.0, w * .03),
      );
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.antarctica,
        Offset(g.cx, g.y(start + table * .5)),
        math.min(w * .15, table * .3),
        perfect: pass.perfect,
      );
    }
  }

  /// A sphere of clear ice holding a warm flame.
  static void _iceLantern(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    double time,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.35),
          colors: [_iceLit, _ice, _mix(_iceDeep, _ink, .15)],
          stops: const [0, .5, 1],
        ).createShader(bounds),
    );
    final flicker = .85 + .15 * math.sin(time * 3.4 + v * 2);
    final flame = [
      const Color(0xffffb35a),
      const Color(0xffff9a6a),
      const Color(0xffffd06a),
    ][v];
    c.drawCircle(
      Offset(0, r * .1),
      r * .7,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                _mix(
                  flame,
                  const Color(0xffffffff),
                  .5,
                ).withValues(alpha: .95 * flicker),
                flame.withValues(alpha: .55 * flicker),
                flame.withValues(alpha: 0),
              ],
              stops: const [0, .45, 1],
            ).createShader(
              Rect.fromCircle(center: Offset(0, r * .1), radius: r * .7),
            ),
    );
    // A candle stub and its flame.
    c.drawRect(
      Rect.fromLTRB(-r * .1, r * .18, r * .1, r * .45),
      Paint()..color = const Color(0xfffff3dc),
    );
    c.drawPath(
      Path()
        ..moveTo(0, r * .18)
        ..quadraticBezierTo(-r * .12, 0, 0, -r * .2 * flicker)
        ..quadraticBezierTo(r * .12, 0, 0, r * .18)
        ..close(),
      Paint()..color = const Color(0xffffe9a8),
    );
    // Frost cracks and a snow cap toward the tether.
    final crack = Paint()
      ..color = _snow.withValues(alpha: .7)
      ..strokeWidth = math.max(.8, r * .03)
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(-r * .7, -r * .2)
        ..lineTo(-r * .45, -r * .05)
        ..lineTo(-r * .5, r * .25)
        ..moveTo(r * .55, -r * .4)
        ..lineTo(r * .35, -r * .15),
      crack,
    );
    final side = upper ? -1.0 : 1.0;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, side * r * .92),
        width: r * 1.5,
        height: r * .6,
      ),
      Paint()..color = _snow,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-r * .42, -r * .42),
        width: r * .3,
        height: r * .18,
      ),
      Paint()..color = const Color(0xccffffff),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.antarctica,
        Offset(0, r * .05),
        r * .24,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, const Color(0xffd6e6f4), _ink, pass);
  }

  /// A deep-blue disc holding a large turning snowflake.
  static void _medallion(
    Canvas c,
    double r,
    int v,
    PassState pass,
    double spin,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    final deep = [
      const Color(0xff2e5c93),
      const Color(0xff3b4f8f),
      const Color(0xff27707f),
    ][v];
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.35),
          colors: [_mix(deep, _iceLit, .35), deep, _mix(deep, _ink, .35)],
          stops: const [0, .55, 1],
        ).createShader(bounds),
    );
    c.drawCircle(
      Offset.zero,
      r * .78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .05
        ..color = _iceLit.withValues(alpha: .4),
    );
    _snowflake(
      c,
      Offset.zero,
      r * .68,
      spin,
      pass.perfect ? const Color(0xffffe08a) : _snow,
      math.max(1.4, r * .07),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.antarctica,
        Offset.zero,
        r * .22,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, const Color(0xffc9d8e8), _ink, pass);
  }
}
