import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Cyberpunk City obstacles, in the sleek materials of the megacity. Pale
/// alloys keep every solid bright against the neon night, and each carries
/// its own light: pearl, titanium and lilac arcology pylons with a dark
/// glass cap and a light pipe pulsing toward the rim; a turbine tower whose
/// ducted fan spins at the rim; holographic glass between chrome rails with
/// glyphs scrolling; a server-rack pylon of blades with blinking status
/// lights; a stepped glass tower with a chasing light strip; a hover drone
/// whose lens scans the sky; and a spinning energy ring.
abstract final class CyberpunkObstacles {
  static const _ink = Color(0xff120f2a);
  static const _carbon = Color(0xff1a1832);
  static const _carbonLit = Color(0xff34315a);
  static const _void = Color(0xff0b0a1c);
  static const _white = Color(0xfff8f6ff);

  /// Alloys by variant: pearl ceramic, brushed titanium and lilac anodised
  /// aluminium, as (lit, body, shade).
  static const _alloy = [
    (Color(0xfff4f6ff), Color(0xffd3d8ec), Color(0xff9aa1c2)),
    (Color(0xffd6dcea), Color(0xffa9b1c8), Color(0xff6c748f)),
    (Color(0xffe6dcfa), Color(0xffbfb0e2), Color(0xff8474b0)),
  ];

  /// Neon by variant: electric cyan, hot magenta and acid lime.
  static const _neon = [
    Color(0xff3ff0ff),
    Color(0xffff3fb4),
    Color(0xffc8ff4a),
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
    garden: _pylon,
    wind: _turbine,
    petal: _holo,
    switchback: _rack,
    steps: _glass,
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
    lantern: _drone,
    wheel: _ring,
  );

  /// A strip of neon light across [b]: a soft halo band and a hot core.
  static void _tube(
    Canvas c,
    Column g,
    double d,
    double thick,
    Color color, {
    double? left,
    double? right,
    double glow = 1,
  }) {
    final l = left ?? g.r.left, r = right ?? g.r.right;
    Kit.fill(
      c,
      g.band(d - thick * 1.2, d + thick * 2.2, l, r),
      color.withValues(alpha: .28 * glow),
    );
    Kit.fill(c, g.band(d, d + thick, l, r), color);
    Kit.fill(
      c,
      g.band(d + thick * .3, d + thick * .7, l, r),
      _mix(color, _white, .75),
    );
  }

  /// The dark glass cap every pylon wears at the rim: a neon strip and a
  /// row of status lights. Returns the distance from the rim to its foot.
  static double _cap(
    Canvas c,
    Column g,
    Color neon,
    PassState pass,
    Motion m, {
    double scale = .42,
  }) {
    final start = Kit.edgeDepth(g);
    final cap = math.min((g.w * scale).clamp(8.0, 22.0), g.h - start);
    if (cap <= 2) return start;
    Kit.fill(c, g.band(start, start + cap), _carbon);
    Kit.fill(c, g.band(start, start + 1.4), _carbonLit);
    _tube(c, g, start + cap * .56, math.max(1.4, cap * .13), neon);
    // Status lights: one breathes with the replay clock.
    final led = Paint();
    for (var k = 0; k < 3; k++) {
      final on = k != 1 || math.sin(m.time * 3.1) > -.3;
      led.color = on ? (k == 2 ? neon : const Color(0xff6dff9a)) : _carbonLit;
      c.drawCircle(
        Offset(g.r.left + g.w * (.16 + k * .1), g.y(start + cap * .26)),
        math.max(.8, g.w * .022),
        led,
      );
    }
    Kit.fill(c, g.band(start + cap - 1.2, start + cap), _void);
    Parts.seal(
      c,
      g,
      WorldRegion.cyberpunk,
      start + cap * .5,
      math.min(g.w * .13, cap * .34),
      pass,
    );
    return start + cap;
  }

  /// An arcology pylon: alloy panels with seams and vent slots, a carbon
  /// spine and a light pipe carrying pulses toward the rim.
  static void _pylon(Canvas c, Column g, int v, PassState pass, Motion m) {
    final (lit, body, shade) = _alloy[v];
    final neon = _neon[v];
    Kit.volume(c, g.r, lit, body, shade);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final from = _cap(c, g, neon, pass, m);
    // The carbon spine and its light pipe.
    final spine = w * .11;
    Kit.fill(c, g.band(from, g.h, g.cx - spine, g.cx + spine), _carbon);
    Kit.fill(
      c,
      g.band(from, g.h, g.cx - spine, g.cx - spine + 1.2),
      _carbonLit,
    );
    Kit.fill(
      c,
      g.band(from, g.h, g.cx - w * .028, g.cx + w * .028),
      neon.withValues(alpha: .5),
    );
    // Pulses run up the pipe to the rim.
    final run = math.max(40.0, g.h - from);
    for (var k = 0; k < 2; k++) {
      final d = from + run - ((m.time * 46 + k * run / 2 + v * 17) % run);
      Kit.fill(
        c,
        g.band(d, d + w * .5, g.cx - w * .04, g.cx + w * .04),
        _mix(neon, _white, .5),
      );
    }
    // Panels: a seam with a lit lip, and vent slots either side.
    final panel = math.max(22.0, w * .95);
    for (var d = from + panel * .6; d < g.h; d += panel) {
      Kit.fill(c, g.band(d, d + 1.2), shade);
      Kit.fill(c, g.band(d + 1.2, d + 2.4), lit);
      for (var k = 0; k < 3; k++) {
        final y = d + panel * (.3 + k * .12);
        Kit.fill(
          c,
          g.band(y, y + 1.4, g.r.left + w * .12, g.cx - spine - w * .08),
          _mix(shade, _ink, .35),
        );
        Kit.fill(
          c,
          g.band(y, y + 1.4, g.cx + spine + w * .08, g.r.right - w * .12),
          _mix(shade, _ink, .35),
        );
      }
    }
  }

  /// A turbine tower: a ducted fan spinning at the rim over louvred vents.
  static void _turbine(Canvas c, Column g, int v, PassState pass, Motion m) {
    final (lit, body, shade) = _alloy[(v + 1) % 3];
    final neon = _neon[v];
    Kit.volume(c, g.r, lit, body, shade);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 6) / 2, (g.h - start - 4) / 2);
    final fan = radius >= 8;
    final from = fan ? start + radius * 2 + 6 : start;
    // Louvres: slanted slats with a lit top edge, and a light strip.
    for (var d = from + 3; d < g.h; d += 5) {
      Kit.fill(
        c,
        g.band(d, d + 2.2, g.r.left + w * .14, g.r.right - w * .14),
        _mix(shade, _ink, .3),
      );
      Kit.fill(
        c,
        g.band(d + 2.2, d + 3, g.r.left + w * .14, g.r.right - w * .14),
        lit,
      );
    }
    Kit.fill(
      c,
      g.band(from, g.h, g.r.left + w * .05, g.r.left + w * .09),
      neon.withValues(alpha: .8),
    );
    if (!fan) return;
    Kit.fill(c, g.band(start, from), _carbon);
    final hub = Offset(g.cx, g.y(start + radius + 3));
    c.drawCircle(hub, radius * .99, Paint()..color = _mix(shade, _carbon, .5));
    c.drawCircle(hub, radius * .86, Paint()..color = _void);
    // The glowing duct ring.
    c.drawCircle(
      hub,
      radius * .9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .16
        ..color = neon.withValues(alpha: .25),
    );
    c.drawCircle(
      hub,
      radius * .9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * .06)
        ..color = _mix(neon, _white, .35),
    );
    // Swept rotor blades.
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(m.spin(g.top ? 3.2 : -3.2, v * .6));
    const blades = 7;
    for (var k = 0; k < blades; k++) {
      c.save();
      c.rotate(k * math.pi * 2 / blades);
      c.drawPath(
        Path()
          ..moveTo(radius * .16, -radius * .07)
          ..quadraticBezierTo(
            radius * .5,
            -radius * .26,
            radius * .8,
            -radius * .16,
          )
          ..lineTo(radius * .8, radius * .02)
          ..quadraticBezierTo(
            radius * .5,
            -radius * .02,
            radius * .16,
            radius * .07,
          )
          ..close(),
        Paint()..color = k.isEven ? lit : body,
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(hub, radius * .22, Paint()..color = lit);
    c.drawCircle(hub, radius * .22 - 1.2, Paint()..color = body);
    c.drawCircle(hub, radius * .08, Paint()..color = neon);
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.cyberpunk,
        hub,
        radius * .2,
        perfect: pass.perfect,
      );
    }
  }

  /// A holographic panel: glowing glass between chrome rails, glyph rows
  /// scrolling toward the rim under scanlines.
  static void _holo(Canvas c, Column g, int v, PassState pass, Motion m) {
    final (lit, body, shade) = _alloy[0];
    final neon = _neon[v];
    final deep = [
      const Color(0xff123a6a),
      const Color(0xff4a1256),
      const Color(0xff0e3a44),
    ][v];
    Kit.fill(c, g.r, _carbon);
    final w = g.w;
    final rail = math.max(3.0, w * .16);
    final glass = Rect.fromLTRB(
      g.r.left + rail,
      g.r.top,
      g.r.right - rail,
      g.r.bottom,
    );
    c.drawRect(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_mix(deep, neon, .55), _mix(deep, neon, .3), deep],
        ).createShader(glass),
    );
    Kit.volume(
      c,
      Rect.fromLTRB(g.r.left, g.r.top, g.r.left + rail, g.r.bottom),
      lit,
      body,
      shade,
    );
    Kit.volume(
      c,
      Rect.fromLTRB(g.r.right - rail, g.r.top, g.r.right, g.r.bottom),
      lit,
      body,
      shade,
    );
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // Glyph rows scroll toward the rim.
    final row = math.max(7.0, w * .2);
    final shift = m.time * 14 % row;
    final glyph = Paint()..color = _mix(neon, _white, .6);
    var k = ((m.time * 14) / row).floor();
    for (var d = start + 10 + row - shift; d < g.h; d += row, k--) {
      var x = glass.left + w * .06;
      var seg = 0;
      while (x < glass.right - w * .06) {
        final len = w * (.06 + .16 * _hash(k * 31 + seg * 7 + v * 5));
        final right = math.min(x + len, glass.right - w * .06);
        if (_hash(k * 17 + seg * 3 + v) < .78) {
          Kit.fill(c, g.band(d, d + row * .34, x, right), glyph.color);
        }
        x = right + w * .05;
        seg++;
      }
    }
    // Scanlines and the glass sheen.
    final scan = Paint()..color = const Color(0x2a000000);
    for (var d = start; d < g.h; d += 3) {
      c.drawRect(g.band(d, d + 1, glass.left, glass.right), scan);
    }
    c.drawRect(
      Rect.fromLTRB(
        glass.left,
        g.r.top,
        glass.left + glass.width * .18,
        g.r.bottom,
      ),
      Paint()..color = const Color(0x22ffffff),
    );
    // Mullions every panel, and the chrome cap at the rim with its LED.
    for (var d = start + w * 1.6; d < g.h; d += w * 1.6) {
      Kit.fill(c, g.band(d, d + 2, glass.left, glass.right), shade);
    }
    final cap = math.min(w * .3, g.h - start);
    Kit.volume(c, g.band(start, start + cap), lit, body, shade);
    _tube(c, g, start + cap * .45, math.max(1.3, cap * .16), neon);
    Parts.seal(
      c,
      g,
      WorldRegion.cyberpunk,
      start + cap + math.min(w * .2, 10),
      math.min(w * .13, 7),
      pass,
    );
  }

  /// A server-rack pylon: stacked blades behind light rails, each with
  /// blinking status lights, a vent grille and a handle.
  static void _rack(Canvas c, Column g, int v, PassState pass, Motion m) {
    final (lit, body, shade) = _alloy[1];
    final neon = _neon[v];
    Kit.volume(c, g.r, lit, body, shade);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final from = _cap(c, g, neon, pass, m, scale: .34);
    final pitch = math.max(10.0, w * .28);
    final tick = (m.time * 4).floor();
    final led = Paint();
    var unit = 0;
    for (var d = from + 2; d < g.h; d += pitch, unit++) {
      final face = g.band(
        d,
        d + pitch - 2.4,
        g.r.left + w * .1,
        g.r.right - w * .1,
      );
      Kit.fill(c, face, const Color(0xff1c1e38));
      Kit.fill(
        c,
        g.band(d, d + 1, face.left, face.right),
        const Color(0xff3a3d64),
      );
      // Status lights.
      for (var k = 0; k < 4; k++) {
        final n = _hash(unit * 13 + k * 5 + tick * 7 + v);
        led.color = n < .55
            ? (k == 0 ? const Color(0xff6dff9a) : neon)
            : (n < .7 ? const Color(0xffffb454) : const Color(0xff2e3056));
        c.drawRect(
          Rect.fromCenter(
            center: Offset(
              face.left + w * (.08 + k * .07),
              g.y(d + pitch * .4),
            ),
            width: math.max(1.2, w * .035),
            height: math.max(1.2, w * .035),
          ),
          led,
        );
      }
      // Vent grille and handle.
      for (var k = 0; k < 4; k++) {
        final x = face.left + face.width * (.52 + k * .08);
        Kit.fill(
          c,
          g.band(
            d + pitch * .2,
            d + pitch * .65,
            x,
            x + math.max(1.0, w * .025),
          ),
          const Color(0xff0c0d1c),
        );
      }
      Kit.fill(
        c,
        g.band(
          d + pitch * .74,
          d + pitch * .74 + 1.6,
          face.right - w * .2,
          face.right - w * .06,
        ),
        lit,
      );
    }
    // Light rails either side.
    Kit.fill(
      c,
      g.band(from, g.h, g.r.left + w * .1, g.r.left + w * .1 + 1.2),
      neon.withValues(alpha: .7),
    );
    Kit.fill(
      c,
      g.band(from, g.h, g.r.right - w * .1 - 1.2, g.r.right - w * .1),
      neon.withValues(alpha: .7),
    );
  }

  /// A stepped glass tower: receding tiers at the rim trimmed with neon,
  /// a curtain wall reflecting the sky and a chasing light strip.
  static void _glass(Canvas c, Column g, int v, PassState pass, Motion m) {
    final glass = [
      (
        const Color(0xffe2ebff),
        const Color(0xffa8b8ec),
        const Color(0xff6a78b8),
      ),
      (
        const Color(0xffe8e0ff),
        const Color(0xffb6a6e8),
        const Color(0xff7462ac),
      ),
      (
        const Color(0xffdcf6ff),
        const Color(0xff9fd0e8),
        const Color(0xff5c8cb0),
      ),
    ][v];
    final neon = _neon[v];
    Kit.volume(c, g.r, glass.$1, glass.$2, glass.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // Curtain wall: mullions, floor lines and a slanting sheen.
    final crown = math.min(w * .78, g.h - start);
    final from = start + crown;
    final mullion = Paint()
      ..color = glass.$3.withValues(alpha: .6)
      ..strokeWidth = math.max(1.0, w * .018);
    for (var k = 1; k < 4; k++) {
      final x = g.r.left + w * k / 4;
      c.drawLine(Offset(x, g.y(from)), Offset(x, g.y(g.h)), mullion);
    }
    for (var d = from + 4; d < g.h; d += 7) {
      Kit.fill(c, g.band(d, d + .8), glass.$3.withValues(alpha: .35));
    }
    final sheen = Path()
      ..moveTo(g.r.left + w * .2, g.y(from))
      ..lineTo(g.r.left + w * .5, g.y(from))
      ..lineTo(g.r.left + w * .1, g.y(from + w * 1.4))
      ..lineTo(g.r.left - w * .2, g.y(from + w * 1.4))
      ..close();
    c.drawPath(sheen, Paint()..color = const Color(0x40ffffff));
    // The chasing strip.
    final strip = g.r.left + w * .74;
    Kit.fill(
      c,
      g.band(from, g.h, strip, strip + math.max(1.4, w * .04)),
      neon.withValues(alpha: .55),
    );
    final run = math.max(40.0, g.h - from);
    final d = from + (m.time * 60 + v * 23) % run;
    Kit.fill(
      c,
      g.band(
        d,
        d + w * .7,
        strip - w * .015,
        strip + math.max(1.4, w * .04) + w * .015,
      ),
      _mix(neon, _white, .6),
    );
    // Three receding tiers at the rim, each edged in neon.
    for (var tier = 0; tier < 3; tier++) {
      final inset = w * (.32 - tier * .13);
      final a = start + crown * tier / 3, b = start + crown * (tier + 1) / 3;
      Kit.fill(
        c,
        g.band(a, b, g.r.left, g.r.left + inset),
        _mix(glass.$3, _carbon, .55),
      );
      Kit.fill(
        c,
        g.band(a, b, g.r.right - inset, g.r.right),
        _mix(glass.$3, _carbon, .55),
      );
      Kit.fill(
        c,
        g.band(a, b, g.r.left + inset, g.r.right - inset),
        tier.isEven ? glass.$1 : glass.$2,
      );
      Kit.fill(
        c,
        g.band(
          a,
          a + math.max(1.2, w * .03),
          g.r.left + inset,
          g.r.right - inset,
        ),
        neon,
      );
    }
    Parts.seal(
      c,
      g,
      WorldRegion.cyberpunk,
      start + crown * .5,
      math.min(w * .13, crown * .22),
      pass,
    );
  }

  /// A hover drone: a pearl shell with a dark visor, a lens that scans
  /// side to side, two rotor slots blurring and a status light.
  static void _drone(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    Motion m,
  ) {
    final (lit, body, shade) = _alloy[v == 1 ? 0 : v];
    final neon = _neon[v];
    Parts.orbBegin(c, r, lit, body, shade);
    // Shell seams.
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, r * .025)
      ..color = shade;
    c.drawArc(
      Rect.fromCircle(center: Offset(0, r * .5), radius: r * .9),
      math.pi * 1.15,
      math.pi * .7,
      false,
      seam,
    );
    // Rotor slots, their blades blurring.
    for (final side in const [-1.0, 1.0]) {
      final slot = Rect.fromCenter(
        center: Offset(side * r * .5, -r * .56),
        width: r * .56,
        height: r * .16,
      );
      c.drawOval(slot, Paint()..color = _void);
      final blur = math.cos(m.time * 21 + side * 1.3);
      c.drawOval(
        Rect.fromCenter(
          center: slot.center,
          width: slot.width * (.35 + .6 * blur.abs()),
          height: slot.height * .45,
        ),
        Paint()..color = lit.withValues(alpha: .7),
      );
    }
    // The visor and its scanning lens.
    final visor = RRect.fromRectAndRadius(
      Rect.fromLTRB(-r * .86, -r * .2, r * .86, r * .2),
      Radius.circular(r * .2),
    );
    c.drawRRect(visor, Paint()..color = _carbon);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-r * .8, -r * .17, r * .8, -r * .1),
        Radius.circular(r * .05),
      ),
      Paint()..color = _carbonLit,
    );
    final sweep = math.sin(m.time * 1.4 + v * 2);
    final lens = Offset(sweep * r * .5, 0);
    c.drawCircle(
      lens,
      r * .34,
      Paint()
        ..shader = RadialGradient(
          colors: [neon.withValues(alpha: .6), neon.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: lens, radius: r * .34)),
    );
    c.drawCircle(lens, r * .14, Paint()..color = neon);
    c.drawCircle(lens, r * .07, Paint()..color = _white);
    c.drawCircle(
      lens,
      r * .16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, r * .03)
        ..color = _mix(neon, _white, .4),
    );
    // Status light under the visor.
    final blink = math.sin(m.time * 4 + v) > 0;
    c.drawCircle(
      Offset(0, r * .36),
      r * .05,
      Paint()..color = blink ? const Color(0xffff4a5e) : _carbonLit,
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.cyberpunk,
        Offset(0, r * .62),
        r * .15,
        perfect: pass.perfect,
      );
    }
    Parts.orbEnd(c, r, _mix(shade, _carbon, .35), _ink, pass, band: .08);
  }

  /// An energy ring: segmented light spinning round a plasma core, with a
  /// thin counter-rotating ring of ticks inside it.
  static void _ring(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    Motion m,
  ) {
    final neon = _neon[v];
    Parts.orbBegin(
      c,
      r,
      const Color(0xff3c3a70),
      const Color(0xff1e1c40),
      const Color(0xff0c0b20),
    );
    final spin = m.spin(upper ? 1.3 : -1.3, v * .7);
    final ring = Rect.fromCircle(center: Offset.zero, radius: r * .66);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    const segments = 9;
    for (var k = 0; k < segments; k++) {
      final a = spin + k * math.pi * 2 / segments;
      c.drawArc(
        ring,
        a,
        .5,
        false,
        pen
          ..strokeWidth = r * .24
          ..color = neon.withValues(alpha: .22),
      );
      c.drawArc(
        ring,
        a + .04,
        .42,
        false,
        pen
          ..strokeWidth = r * .12
          ..color = neon,
      );
      c.drawArc(
        ring,
        a + .06,
        .38,
        false,
        pen
          ..strokeWidth = r * .04
          ..color = _mix(neon, _white, .7),
      );
    }
    // The inner ring of ticks turns the other way.
    c.save();
    c.rotate(-spin * 1.6);
    c.drawCircle(
      Offset.zero,
      r * .42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, r * .025)
        ..color = _mix(neon, _white, .5),
    );
    final tickPen = Paint()
      ..strokeWidth = math.max(1.0, r * .04)
      ..color = _white;
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(d * r * .36, d * r * .48, tickPen);
    }
    c.restore();
    // The plasma core.
    final pulse = .85 + .15 * math.sin(m.time * 3 + v);
    c.drawCircle(
      Offset.zero,
      r * .34,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                _white,
                _mix(neon, _white, .4),
                neon.withValues(alpha: 0),
              ],
              stops: const [0, .4, 1],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: r * .34 * pulse),
            ),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.cyberpunk,
        Offset.zero,
        r * .17,
        perfect: pass.perfect,
      );
    }
    Parts.orbEnd(c, r, const Color(0xffc6cce0), _ink, pass, band: .09);
  }

  /// Deterministic noise in [0, 1) for blinking lights and glyph rows.
  static double _hash(int n) {
    var x = (n * 374761393 + 668265263) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
    return (x ^ (x >> 16)) / 0x80000000;
  }
}
