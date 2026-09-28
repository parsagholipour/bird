import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';

/// Egyptian obstacles: painted sandstone columns with glyph panels and
/// lotus, papyrus or palm capitals; a saqiya water wheel on a mudbrick
/// tower; a broad-collar column of faience petals; granite obelisks whose
/// gilded pyramidions point at the opening; ashlar masonry steps; a pierced
/// brass fanous lantern and an Egyptian-blue faience rosette. Cleared glyphs
/// are gilded.
abstract final class EgyptObstacles {
  static const _ink = Color(0xff4a3222);
  static const _sandLit = Color(0xfff5dcaa), _sand = Color(0xffe2bb82);
  static const _sandShade = Color(0xffc0905a), _sandDeep = Color(0xff9a6a40);
  static const _blue = Color(0xff2f6aa8), _turquoise = Color(0xff3fb3a7);
  static const _red = Color(0xffc24f38), _gold = Color(0xffe9b44c);
  static const _green = Color(0xff5f9a55), _cream = Color(0xfffff4dc);

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
        _saqiya(c, g, v, pass, Kit.spin(seconds, reducedMotion, .7, v * .5));
      case ObstacleKind.petalGate:
        _collar(c, g, v, pass, Kit.spin(seconds, reducedMotion, .35));
      case ObstacleKind.switchback:
        _obelisk(c, g, v, pass);
      case ObstacleKind.crystalSteps:
        _masonry(c, g, v, pass);
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
      _fanous(c, radius, v, upper, pass, reducedMotion ? 0 : seconds);
    } else {
      _rosette(
        c,
        radius,
        v,
        pass,
        Kit.spin(seconds, reducedMotion, upper ? .4 : -.4),
      );
    }
  }

  static Color _mix(Color a, Color b, double t) => Kit.mix(a, b, t);

  // ---------------------------------------------------------------------------
  // Columns

  /// Sandstone column: abacus slab at the rim, a painted capital (papyrus
  /// bud, open lotus or palm fronds), coloured binding bands and a recessed
  /// panel of carved glyphs down the shaft.
  static void _pillar(Canvas c, Column g, int v, PassState pass) {
    Kit.volume(c, g.r, _sandLit, _sand, _sandShade);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final slab = (w * .12).clamp(4.0, 8.0);
    final bell = (w * .5).clamp(10.0, 32.0);
    final bands = (w * .15).clamp(5.0, 10.0);
    _flutes(c, g, start + slab + bell + bands, v == 0 ? 6 : 0);
    _glyphPanel(c, g, start + slab + bell + bands, v, pass);
    _binding(c, g, start + slab + bell, bands);
    _capital(c, g, start + slab, bell, v, pass);
    Kit.fill(c, g.band(start, start + slab), _sandLit);
    Kit.fill(c, g.band(start + slab * .7, start + slab), _sandShade);
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.egypt,
        Offset(g.cx, g.y(start + slab + bell * .5)),
        math.min(bell * .3, w * .16),
        perfect: pass.perfect,
      );
    }
  }

  /// Papyrus-bundle ribs down the shaft.
  static void _flutes(Canvas c, Column g, double from, int ribs) {
    if (ribs == 0 || g.h <= from) return;
    final pitch = g.w / ribs;
    for (var i = 0; i < ribs; i++) {
      final x = g.r.left + pitch * i;
      Kit.fill(
        c,
        g.band(from, g.h, x + pitch * .72, x + pitch),
        _sandShade.withValues(alpha: .45),
      );
      Kit.fill(
        c,
        g.band(from, g.h, x + pitch * .12, x + pitch * .3),
        _sandLit.withValues(alpha: .6),
      );
    }
  }

  static void _binding(Canvas c, Column g, double from, double depth) {
    if (g.h <= from) return;
    const colors = [_blue, _gold, _red, _gold, _turquoise];
    final stripe = depth / colors.length;
    for (var i = 0; i < colors.length; i++) {
      Kit.fill(
        c,
        g.band(from + i * stripe, from + (i + 1) * stripe),
        colors[i],
      );
    }
    Kit.fill(
      c,
      g.band(from + depth - .8, from + depth + .6),
      _ink.withValues(alpha: .5),
    );
  }

  /// The capital flares toward the rim, set against a shadowed backdrop.
  static void _capital(
    Canvas c,
    Column g,
    double from,
    double depth,
    int v,
    PassState pass,
  ) {
    if (g.h <= from) return;
    final w = g.w;
    Kit.fill(c, g.band(from, from + depth), _sandDeep);
    final neck = w * .34;
    final wide = w * .5 - 1;
    final bell = Path()
      ..moveTo(g.cx - wide, g.y(from))
      ..quadraticBezierTo(
        g.cx - wide,
        g.y(from + depth * .7),
        g.cx - neck,
        g.y(from + depth),
      )
      ..lineTo(g.cx + neck, g.y(from + depth))
      ..quadraticBezierTo(
        g.cx + wide,
        g.y(from + depth * .7),
        g.cx + wide,
        g.y(from),
      )
      ..close();
    c.drawPath(bell, Paint()..color = _sand);
    c.save();
    c.clipPath(bell);
    final root = Offset(g.cx, g.y(from + depth));
    switch (v) {
      case 1:
        // Open lotus: blue and green petals fanning from the neck.
        for (var i = -3; i <= 3; i++) {
          final tipX = g.cx + i * wide / 3.2;
          final tip = Offset(tipX, g.y(from - 2));
          final half = w * .11;
          c.drawPath(
            Path()
              ..moveTo(root.dx + i * neck / 4 - half, root.dy)
              ..quadraticBezierTo(
                tip.dx - half,
                g.y(from + depth * .3),
                tip.dx,
                tip.dy,
              )
              ..quadraticBezierTo(
                tip.dx + half,
                g.y(from + depth * .3),
                root.dx + i * neck / 4 + half,
                root.dy,
              )
              ..close(),
            Paint()..color = i.isEven ? _blue : _green,
          );
        }
      case 2:
        // Palm capital: slim fronds with gilded midribs.
        for (var i = -4; i <= 4; i++) {
          final tip = Offset(g.cx + i * wide / 4.3, g.y(from - 1));
          c.drawPath(
            Path()
              ..moveTo(root.dx + i * neck / 5, root.dy)
              ..quadraticBezierTo(
                tip.dx - w * .05,
                g.y(from + depth * .4),
                tip.dx,
                tip.dy,
              )
              ..quadraticBezierTo(
                tip.dx + w * .05,
                g.y(from + depth * .4),
                root.dx + i * neck / 5,
                root.dy,
              )
              ..close(),
            Paint()..color = i.isEven ? _green : _mix(_green, _turquoise, .5),
          );
          c.drawLine(
            Offset(root.dx + i * neck / 5, root.dy),
            tip,
            Paint()
              ..color = _gold
              ..strokeWidth = math.max(.7, w * .012),
          );
        }
      default:
        // Closed papyrus bud: ribbed, with painted sepals at the neck.
        for (var i = -3; i <= 3; i++) {
          c.drawLine(
            Offset(g.cx + i * neck / 3.4, root.dy),
            Offset(g.cx + i * wide / 3.4, g.y(from)),
            Paint()
              ..color = _sandShade
              ..strokeWidth = math.max(.8, w * .02),
          );
        }
        for (var i = -2; i <= 2; i++) {
          final x = g.cx + i * neck / 2.2;
          c.drawPath(
            Kit.poly([
              x - w * .06,
              root.dy,
              x,
              g.y(from + depth * .45),
              x + w * .06,
              root.dy, //
            ]),
            Paint()..color = i.isEven ? _green : _blue,
          );
        }
    }
    c.restore();
    c.drawPath(
      bell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * .02)
        ..color = _ink.withValues(alpha: .6),
    );
    if (pass.perfect) {
      c.drawPath(
        bell,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, w * .02)
          ..color = _gold,
      );
    }
  }

  /// A recessed panel of carved, painted signs running down the shaft.
  static void _glyphPanel(
    Canvas c,
    Column g,
    double from,
    int v,
    PassState pass,
  ) {
    final w = g.w;
    if (g.h <= from + 6 || w < 20) return;
    final left = g.cx - w * .2, right = g.cx + w * .2;
    Kit.fill(
      c,
      g.band(from + 3, g.h, left, right),
      _mix(_sand, _sandShade, .45),
    );
    Kit.fill(
      c,
      g.band(from + 3, g.h, left, left + 1.2),
      _ink.withValues(alpha: .35),
    );
    Kit.fill(c, g.band(from + 3, g.h, right - 1, right), _sandLit);
    final pitch = math.max(14.0, w * .36);
    final s = (right - left) * .34;
    const inks = [_blue, _red, _green, _blue, _gold, _red];
    var k = 0;
    for (var d = from + 3 + pitch * .55; d < g.h + pitch; d += pitch, k++) {
      final at = Offset(g.cx, g.y(d));
      final color = pass.cleared
          ? (pass.perfect ? const Color(0xffffd35a) : _gold)
          : inks[(k + v * 2) % inks.length];
      _glyph(c, at, s, (k + v * 3) % 6, color, g.top);
    }
  }

  /// Simple carved signs: a sun, water, a reed, a loaf, a bird and a basket.
  static void _glyph(
    Canvas c,
    Offset p,
    double s,
    int kind,
    Color color,
    bool flip,
  ) {
    final paint = Paint()..color = color;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * .22)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case 0:
        c.drawCircle(p, s * .8, line);
        c.drawCircle(p, s * .22, paint);
      case 1:
        final path = Path()..moveTo(p.dx - s, p.dy);
        for (var i = 1; i <= 6; i++) {
          path.lineTo(
            p.dx - s + i * s / 3,
            p.dy + (i.isOdd ? -s * .35 : s * .35),
          );
        }
        c.drawPath(path, line);
      case 2:
        c.drawPath(
          Path()
            ..moveTo(p.dx, p.dy + s)
            ..quadraticBezierTo(p.dx - s * .55, p.dy, p.dx + s * .1, p.dy - s)
            ..quadraticBezierTo(p.dx + s * .35, p.dy, p.dx, p.dy + s)
            ..close(),
          paint,
        );
      case 3:
        c.drawArc(
          Rect.fromCenter(
            center: p + Offset(0, s * .35),
            width: s * 1.8,
            height: s * 1.6,
          ),
          math.pi,
          math.pi,
          true,
          paint,
        );
      case 4:
        // A standing ibis in profile.
        c.drawOval(
          Rect.fromCenter(
            center: p + Offset(-s * .1, s * .1),
            width: s * 1.2,
            height: s * .7,
          ),
          paint,
        );
        c.drawLine(
          p + Offset(s * .4, -s * .1),
          p + Offset(s * .55, -s * .7),
          line,
        );
        c.drawLine(
          p + Offset(s * .55, -s * .7),
          p + Offset(s * .95, -s * .3),
          line,
        );
        c.drawLine(p + Offset(-s * .1, s * .4), p + Offset(-s * .1, s), line);
      default:
        c.drawArc(
          Rect.fromCenter(center: p, width: s * 1.8, height: s * 1.6),
          0,
          math.pi,
          true,
          paint,
        );
    }
  }

  /// A mudbrick tower carrying a turning saqiya wheel hung with clay pots.
  static void _saqiya(Canvas c, Column g, int v, PassState pass, double spin) {
    const mud = Color(0xffc99b6c),
        mudLit = Color(0xffe0b98a),
        mudShade = Color(0xffa27549);
    Kit.volume(c, g.r, mudLit, mud, mudShade);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final wheel = radius >= 9;
    final from = wheel ? start + radius * 2 + 6 : start;
    // Brick courses, offset every other row.
    final course = math.max(7.0, w * .13);
    final mortar = Paint()
      ..color = _mix(mudShade, _ink, .25).withValues(alpha: .55);
    var row = 0;
    for (var d = from; d < g.h; d += course, row++) {
      Kit.fill(c, g.band(d, d + 1.1), mortar.color);
      final brick = w / 2.5;
      final offset = row.isOdd ? brick / 2 : 0.0;
      for (var x = g.r.left - offset; x < g.r.right; x += brick) {
        Kit.fill(c, g.band(d, d + course, x, x + 1.1), mortar.color);
      }
    }
    if (!wheel) return;
    final hub = Offset(g.cx, g.y(start + radius + 3));
    Kit.fill(c, g.band(start, start + radius * 2 + 6), const Color(0xff6f4a2f));
    // The axle beam spans the tower.
    Kit.fill(
      c,
      Rect.fromCenter(
        center: hub,
        width: w,
        height: math.max(3.0, radius * .22),
      ),
      const Color(0xff8a5f3a),
    );
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, radius * .16)
      ..color = const Color(0xffa8764a);
    final spoke = Paint()
      ..strokeWidth = math.max(1.4, radius * .1)
      ..color = const Color(0xff8e6038);
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      c.drawLine(
        Offset.zero,
        Offset(math.cos(a), math.sin(a)) * radius * .8,
        spoke,
      );
    }
    c.drawCircle(Offset.zero, radius * .8, rim);
    // Clay pots lashed around the wheel.
    const pots = 8;
    for (var i = 0; i < pots; i++) {
      final a = i * math.pi * 2 / pots;
      final p = Offset(math.cos(a), math.sin(a)) * radius * .8;
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(-spin);
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * .34,
          height: radius * .42,
        ),
        Paint()..color = const Color(0xffc8643e),
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-radius * .05, -radius * .06),
          width: radius * .12,
          height: radius * .16,
        ),
        Paint()..color = const Color(0xffe89066),
      );
      c.drawRect(
        Rect.fromCenter(
          center: Offset(0, -radius * .2),
          width: radius * .22,
          height: radius * .06,
        ),
        Paint()..color = const Color(0xff8e3f28),
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(
      hub,
      radius * .2,
      Paint()..color = v == 2 ? _gold : const Color(0xff7a5232),
    );
    c.drawCircle(
      hub + Offset(-radius * .05, -radius * .05),
      radius * .07,
      Paint()..color = _cream,
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.egypt,
        hub,
        radius * .34,
        perfect: pass.perfect,
      );
    }
  }

  /// A broad collar of faience petals pointing to the rim, around a turning
  /// blue lotus.
  static void _collar(Canvas c, Column g, int v, PassState pass, double spin) {
    Kit.volume(
      c,
      g.r,
      _mix(_gold, _cream, .3),
      _gold,
      _mix(_gold, _sandDeep, .6),
    );
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min(w * .38, (g.h - start - 6) * .42);
    final bloom = radius >= 6;
    final from = bloom ? start + radius * 2 + 7 : start;
    // Rows of teardrop beads, each row a different stone.
    final rows = [
      [_turquoise, _blue, _red],
      [_blue, _gold, _turquoise],
      [_red, _turquoise, _gold],
    ][v];
    final pitch = math.max(11.0, w * .2);
    final per = math.max(3, (w / 14).round());
    final bead = w / per;
    var k = 0;
    for (var d = from; d < g.h + pitch; d += pitch, k++) {
      final color = rows[k % rows.length];
      Kit.fill(c, g.band(d, d + 1.4), _mix(_gold, _ink, .35));
      final shift = k.isOdd ? bead / 2 : 0.0;
      for (var x = g.r.left - shift; x < g.r.right; x += bead) {
        final tip = g.y(d + 2);
        final back = g.y(d + pitch - 1);
        c.drawPath(
          Path()
            ..moveTo(x + bead * .08, back)
            ..quadraticBezierTo(x + bead * .06, tip, x + bead * .5, tip)
            ..quadraticBezierTo(x + bead * .94, tip, x + bead * .92, back)
            ..close(),
          Paint()..color = color,
        );
        c.drawCircle(
          Offset(x + bead * .36, g.y(d + pitch * .45)),
          math.max(.8, bead * .08),
          Paint()..color = _cream.withValues(alpha: .7),
        );
      }
    }
    if (!bloom) return;
    Kit.fill(c, g.band(start, from), _mix(_blue, _ink, .35));
    final hub = Offset(g.cx, g.y(start + radius + 3.5));
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    for (final (n, len, color) in [
      (8, 1.0, _mix(_blue, _cream, .2)),
      (8, .72, _mix(_turquoise, _cream, .35)),
    ]) {
      for (var i = 0; i < n; i++) {
        c.save();
        c.rotate(i * math.pi * 2 / n + (len < 1 ? math.pi / n : 0));
        c.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(
              -radius * .26,
              -radius * .5 * len,
              0,
              -radius * len,
            )
            ..quadraticBezierTo(radius * .26, -radius * .5 * len, 0, 0)
            ..close(),
          Paint()..color = color,
        );
        c.restore();
      }
    }
    c.restore();
    c.drawCircle(hub, radius * .24, Paint()..color = _gold);
    c.drawCircle(hub, radius * .12, Paint()..color = const Color(0xffffe28a));
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.egypt,
        hub,
        radius * .34,
        perfect: pass.perfect,
      );
    }
  }

  /// Aswan granite obelisk. Its gilded pyramidion points at the opening.
  static void _obelisk(Canvas c, Column g, int v, PassState pass) {
    final stone = [
      (
        const Color(0xffdfa596),
        const Color(0xffc3806f),
        const Color(0xff925547),
      ),
      (
        const Color(0xffe8d2b0),
        const Color(0xffcfb088),
        const Color(0xffa3845c),
      ),
      (
        const Color(0xff9aa0a8),
        const Color(0xff7b818d),
        const Color(0xff555a66),
      ),
    ][v];
    Kit.volume(c, g.r, stone.$1, stone.$2, stone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final tipLen = math.min(w * 1.0, g.h - start);
    // The pyramidion: gold facets against a dark granite backing.
    Kit.fill(c, g.band(start, start + tipLen), _mix(stone.$3, _ink, .3));
    final apex = Offset(g.cx, g.y(start));
    final baseL = Offset(g.r.left + 1, g.y(start + tipLen));
    final baseR = Offset(g.r.right - 1, g.y(start + tipLen));
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    c.drawPath(
      Kit.poly([apex.dx, apex.dy, baseL.dx, baseL.dy, g.cx, baseL.dy]),
      Paint()..color = _mix(gold, _cream, .45),
    );
    c.drawPath(
      Kit.poly([apex.dx, apex.dy, g.cx, baseR.dy, baseR.dx, baseR.dy]),
      Paint()..color = _mix(gold, _sandDeep, .3),
    );
    // A carved column of signs runs down the shaft.
    final from = start + tipLen;
    final s = w * .13;
    final pitch = math.max(13.0, w * .42);
    var k = 0;
    for (var d = from + pitch * .6; d < g.h + pitch; d += pitch, k++) {
      final color = pass.cleared ? gold : _mix(stone.$3, _ink, .35);
      _glyph(c, Offset(g.cx, g.y(d)), s, (k + v) % 6, color, g.top);
    }
    Kit.fill(
      c,
      g.band(from, g.h, g.cx - w * .3, g.cx - w * .3 + 1),
      _mix(stone.$3, _ink, .2).withValues(alpha: .5),
    );
    Kit.fill(
      c,
      g.band(from, g.h, g.cx + w * .3 - 1, g.cx + w * .3),
      _mix(stone.$3, _ink, .2).withValues(alpha: .5),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.egypt,
        Offset(g.cx, g.y(start + tipLen * .62)),
        math.min(w * .15, tipLen * .2),
        perfect: pass.perfect,
      );
    }
  }

  /// Ashlar blocks laid in staggered courses, with a white casing stone and a
  /// gilt band at the rim.
  static void _masonry(Canvas c, Column g, int v, PassState pass) {
    final tone = [
      (
        const Color(0xfff6ead0),
        const Color(0xffe4d0a8),
        const Color(0xffbfa57c),
      ),
      (_sandLit, _sand, _sandShade),
      (
        const Color(0xffe6c7a3),
        const Color(0xffcfa47a),
        const Color(0xffa37750),
      ),
    ][v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final casing = math.min(w * .32, g.h - start);
    Kit.fill(c, g.band(start, start + casing), const Color(0xfffcf6e8));
    Kit.fill(
      c,
      g.band(start + casing * .72, start + casing),
      const Color(0xffe2d6bd),
    );
    Kit.fill(
      c,
      g.band(start + casing, start + casing + 2),
      pass.perfect ? const Color(0xffffd35a) : _gold,
    );
    final joint = _mix(tone.$3, _ink, .3);
    final course = math.max(12.0, w * .42);
    var row = 0;
    for (var d = start + casing + 2; d < g.h; d += course, row++) {
      Kit.fill(c, g.band(d, d + 1.2), joint);
      // Each block has a sunlit top edge and a shaded underside.
      Kit.fill(c, g.band(d + 1.2, d + 2.6), tone.$1);
      Kit.fill(
        c,
        g.band(d + course - 2, d + course),
        tone.$3.withValues(alpha: .6),
      );
      final seam = g.r.left + w * (row.isOdd ? .35 : .68);
      Kit.fill(c, g.band(d, d + course, seam, seam + 1.2), joint);
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.egypt,
        Offset(g.cx, g.y(start + casing * .45)),
        math.min(w * .15, casing * .32),
        perfect: pass.perfect,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Floating obstacles

  /// A pierced brass fanous: a band of pointed-arch glass panes lit from
  /// inside, under a pierced dome and over a tapering base.
  static void _fanous(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    double time,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    final brass = pass.perfect
        ? const Color(0xffffd35a)
        : const Color(0xffd9a441);
    final brassDeep = _mix(brass, _ink, .35);
    final flicker = .85 + .15 * math.sin(time * 3.1 + v);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(Offset.zero, r, Paint()..color = brassDeep);
    // Dome and base: pierced brass that lets pinpricks of light through.
    c.drawRect(Rect.fromLTRB(-r, -r, r, -r * .42), Paint()..color = brass);
    c.drawRect(Rect.fromLTRB(-r, r * .5, r, r), Paint()..color = brass);
    c.drawRect(
      Rect.fromLTRB(-r, -r * .5, r, -r * .42),
      Paint()..color = brassDeep,
    );
    c.drawRect(
      Rect.fromLTRB(-r, r * .5, r, r * .58),
      Paint()..color = brassDeep,
    );
    final pin = Paint()
      ..color = const Color(0xfffff0b8).withValues(alpha: flicker);
    for (var i = -3; i <= 3; i++) {
      c.drawCircle(Offset(i * r * .2, -r * .62), r * .04, pin);
      if (i.abs() < 3) {
        c.drawCircle(Offset(i * r * .2 + r * .1, -r * .78), r * .03, pin);
      }
      c.drawCircle(Offset(i * r * .2, r * .7), r * .035, pin);
    }
    // Three pointed-arch panes, the side ones foreshortened.
    final panes = [
      [_red, _turquoise, _gold],
      [_turquoise, _gold, _red],
      [_blue, _red, _turquoise],
    ][v];
    for (var i = 0; i < 3; i++) {
      final cx = (i - 1) * r * .52;
      final half = r * (i == 1 ? .22 : .16);
      final top = -r * .4, bottom = r * .46;
      final arch = Path()
        ..moveTo(cx - half, bottom)
        ..lineTo(cx - half, top + half * 1.1)
        ..quadraticBezierTo(cx - half, top, cx, top - half * .5)
        ..quadraticBezierTo(cx + half, top, cx + half, top + half * 1.1)
        ..lineTo(cx + half, bottom)
        ..close();
      c.drawPath(
        arch,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  _mix(panes[i], const Color(0xffffffff), .55 * flicker),
                  panes[i],
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(cx, r * .05), radius: r * .5),
              ),
      );
      c.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, r * .06)
          ..color = brass,
      );
    }
    // A finial ring on the tether side.
    final side = upper ? -1.0 : 1.0;
    c.drawCircle(Offset(0, side * r * .9), r * .14, Paint()..color = brassDeep);
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.egypt,
        Offset(0, r * .06),
        r * .22,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, brass, _ink, pass, band: .08);
  }

  /// An Egyptian-blue faience disc with a turning gold rosette.
  static void _rosette(Canvas c, double r, int v, PassState pass, double spin) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.35),
          colors: [_mix(_blue, _cream, .25), _blue, _mix(_blue, _ink, .3)],
          stops: const [0, .55, 1],
        ).createShader(bounds),
    );
    // A turquoise ring of dots, like inlaid beads.
    c.drawCircle(
      Offset.zero,
      r * .76,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .14
        ..color = _turquoise,
    );
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      c.drawCircle(
        Offset(math.cos(a), math.sin(a)) * r * .76,
        r * .035,
        Paint()..color = _cream,
      );
    }
    final petals = const [8, 12, 6][v];
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    c.save();
    c.rotate(spin);
    for (var i = 0; i < petals; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / petals);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-r * .22, -r * .34, 0, -r * .64)
          ..quadraticBezierTo(r * .22, -r * .34, 0, 0)
          ..close(),
        Paint()..color = gold,
      );
      c.drawLine(
        Offset(0, -r * .12),
        Offset(0, -r * .5),
        Paint()
          ..color = _mix(gold, _sandDeep, .45)
          ..strokeWidth = math.max(.8, r * .03),
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(Offset.zero, r * .17, Paint()..color = _red);
    c.drawCircle(
      Offset(-r * .04, -r * .05),
      r * .06,
      Paint()..color = _cream.withValues(alpha: .8),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.egypt,
        Offset.zero,
        r * .24,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, gold, _ink, pass);
  }
}
