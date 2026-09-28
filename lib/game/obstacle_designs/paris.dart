import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Parisian obstacles: cream limestone piers with a wrought-iron balcony
/// and a lit window; a Ferris wheel of gondolas on a stone tower; blue
/// louvred shutters; riveted iron lattice girders; slate mansard steps with
/// a copper edge; a gas-lamp globe; and the red sails of a windmill.
abstract final class ParisObstacles {
  static const _ink = Color(0xff1f1d2e);
  static const _iron = Color(0xff26243a), _ironLit = Color(0xff5a5878);
  static const _gold = Color(0xffe8b84a), _copper = Color(0xffc9825a);
  static const _slate = Color(0xff5f6a8a), _zinc = Color(0xff8a94b0);
  static const _red = Color(0xffc8402f), _cream = Color(0xfffff4dc);
  static const _window = Color(0xffffd98a);

  static const _stone = [
    (Color(0xfff4ead2), Color(0xffdfcfac), Color(0xffb5a07c)),
    (Color(0xfff0dfc6), Color(0xffd9c2a0), Color(0xffab9070)),
    (Color(0xffe9e4da), Color(0xffcfc8ba), Color(0xff9c9484)),
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
    garden: _pier,
    wind: _ferris,
    petal: _shutters,
    switchback: _girder,
    steps: _mansard,
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
    lantern: _globe,
    wheel: _windmill,
  );

  /// A limestone pier: an iron balcony at the rim over a lit tall window and
  /// rusticated courses.
  static void _pier(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final rail = math.min((w * .3).clamp(7.0, 16.0), g.h - start);
    final joint = _mix(tone.$3, _ink, .25);
    final winH = math.min(w * 1.1, g.h - start - rail - 6);
    Parts.courses(c, g, start + rail + math.max(0.0, winH) + 6, math.max(10.0, w * .3), joint, tone.$1, tone.$3.withValues(alpha: .6));
    if (winH > 6) {
      Parts.niche(c, g, start + rail + 3, w * .5, winH, _iron);
      Parts.niche(c, g, start + rail + 4.5, w * .5 - 3, winH - 3, _window);
      Kit.fill(c, g.band(start + rail + 3 + winH * .5, start + rail + 4.5 + winH * .5, g.cx - w * .25, g.cx + w * .25), _iron);
    }
    Kit.fill(c, g.band(start, start + rail), _iron);
    for (var x = g.r.left + 2; x < g.r.right - 1; x += 4) {
      Kit.fill(c, g.band(start + 1.5, start + rail - 1.5, x, x + 1.2), _ironLit);
    }
    Kit.fill(c, g.band(start, start + 2), pass.perfect ? const Color(0xffffd35a) : _gold);
    Parts.seal(c, g, WorldRegion.paris, start + rail * .5, math.min(w * .14, rail * .4), pass);
  }

  /// A Ferris wheel on a stone tower, gondolas hanging level as it turns.
  static void _ferris(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final wheel = radius >= 9;
    final from = wheel ? start + radius * 2 + 6 : start;
    Parts.courses(c, g, from, math.max(9.0, w * .3), _mix(tone.$3, _ink, .25), tone.$1, tone.$3.withValues(alpha: .6));
    if (!wheel) return;
    final hub = Offset(g.cx, g.y(start + radius + 3));
    Kit.fill(c, g.band(start, start + radius * 2 + 6), const Color(0xff2f3050));
    final spin = m.spin(.5, v * .5);
    Parts.wheel(c, hub, radius, spin, 12, _ironLit, _iron);
    final pods = [_red, _gold, const Color(0xff4f9fd0)];
    for (var i = 0; i < 8; i++) {
      final a = spin + i * math.pi / 4;
      final p = hub + Offset(math.cos(a), math.sin(a)) * radius * .9;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p + Offset(0, radius * .1), width: radius * .26, height: radius * .22),
          Radius.circular(radius * .05),
        ),
        Paint()..color = pods[(i + v) % pods.length],
      );
    }
    Parts.seal(c, g, WorldRegion.paris, start + radius + 3, radius * .22, pass);
  }

  /// Blue louvred shutters, their slats catching light in turn.
  static void _shutters(Canvas c, Column g, int v, PassState pass, Motion m) {
    final blue = [const Color(0xff5f86a8), const Color(0xff5f9a86), const Color(0xff8a6a9a)][v];
    Kit.volume(c, g.r, _mix(blue, _cream, .35), blue, _mix(blue, _ink, .4));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    Parts.stripes(c, g, start + 2, 4, [_mix(blue, _cream, .25), _mix(blue, _ink, .25)], shift: m.time * 5);
    Kit.fill(c, g.band(start, g.h, g.cx - .9, g.cx + .9), _iron);
    for (var d = start + 10; d < g.h - 4; d += 30) {
      Kit.fill(c, g.band(d, d + 3, g.r.left, g.r.left + w * .18), _iron);
      Kit.fill(c, g.band(d, d + 3, g.r.right - w * .18, g.r.right), _iron);
    }
    Parts.seal(c, g, WorldRegion.paris, start + 10, math.min(w * .15, 8), pass);
  }

  /// A riveted iron girder tower of crossing braces.
  static void _girder(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tint = [const Color(0xff3a3050), const Color(0xff2f3a50), const Color(0xff3a3a3a)][v];
    Kit.volume(c, g.r, _mix(tint, _zinc, .3), tint, _mix(tint, _ink, .5));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    Kit.fill(c, g.band(start, start + 4), _ironLit);
    Parts.lattice(c, g, start + 4, math.max(9.0, w * .5), _ironLit, width: math.max(1.2, w * .05));
    Kit.fill(c, g.band(start, g.h, g.r.left + 2, g.r.left + 2 + math.max(2.0, w * .07)), _ironLit);
    Kit.fill(c, g.band(start, g.h, g.r.right - 2 - math.max(2.0, w * .07), g.r.right - 2), _ironLit);
    final rivet = Paint()..color = _zinc;
    for (var d = start + 10; d < g.h; d += 18) {
      c.drawCircle(Offset(g.r.left + 3, g.y(d)), 1, rivet);
      c.drawCircle(Offset(g.r.right - 3, g.y(d)), 1, rivet);
    }
    Parts.seal(c, g, WorldRegion.paris, start + 4 + math.max(5.0, w * .16), math.min(w * .14, 7), pass);
  }

  /// Slate mansard steps under a copper edge with a small dormer.
  static void _mansard(Canvas c, Column g, int v, PassState pass, Motion m) {
    final slate = [_slate, const Color(0xff66738a), const Color(0xff5f6a6a)][v];
    Kit.volume(c, g.r, _mix(slate, _zinc, .45), slate, _mix(slate, _ink, .45));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final trim = math.min(w * .18, g.h - start);
    Kit.fill(c, g.band(start, start + trim), _copper);
    Kit.fill(c, g.band(start + trim * .6, start + trim), _mix(_copper, _ink, .3));
    Parts.courses(c, g, start + trim, math.max(7.0, w * .22), _mix(slate, _ink, .5), _mix(slate, _zinc, .5), _mix(slate, _ink, .3));
    final dormer = math.min(w * .6, g.h - start - trim - 8);
    if (dormer > 8) {
      Parts.niche(c, g, start + trim + 6, w * .4, dormer * .8, _iron);
      Parts.niche(c, g, start + trim + 7.5, w * .4 - 3, dormer * .8 - 3, _window);
    }
    Parts.seal(c, g, WorldRegion.paris, start + trim * .5, math.min(w * .13, trim * .4), pass);
  }

  /// A gas-lamp globe with a gold frame and a flickering flame.
  static void _globe(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final glass = [const Color(0xffffe08a), const Color(0xffffc98a), const Color(0xfff6f0c0)][v];
    Parts.orbBegin(c, r, const Color(0xfffffbe6), glass, _mix(glass, _copper, .5));
    final flick = .85 + .15 * math.sin(m.time * 5 + v);
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * .06)
      ..color = gold;
    for (final k in const [.34, .68]) {
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2 * k, height: r * 1.9), rib);
    }
    c.drawLine(Offset(-r, 0), Offset(r, 0), rib);
    c.drawPath(
      Path()
        ..moveTo(0, r * .3)
        ..quadraticBezierTo(-r * .2, -r * .05, 0, -r * .35 * flick)
        ..quadraticBezierTo(r * .2, -r * .05, 0, r * .3)
        ..close(),
      Paint()..color = _mix(const Color(0xffff9a3a), _cream, .3 * flick),
    );
    c.drawRect(Rect.fromLTRB(-r * .4, r * .5, r * .4, r), Paint()..color = _iron);
    c.drawRect(Rect.fromLTRB(-r * .3, -r, r * .3, -r * .72), Paint()..color = _iron);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.paris, Offset(0, r * .62), r * .16, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, gold, _ink, pass, band: .09);
  }

  /// A dark disc with the four red sails of a windmill turning on it.
  static void _windmill(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    Parts.orbBegin(c, r, const Color(0xff5a3a6a), const Color(0xff3a2a52), const Color(0xff1f1838));
    final sails = const [4, 6, 5][v];
    c.save();
    c.rotate(m.spin(upper ? .8 : -.8));
    for (var i = 0; i < sails; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / sails);
      final blade = Rect.fromLTRB(-r * .11, -r * .95, r * .11, -r * .14);
      c.drawRect(blade, Paint()..color = _red);
      final lat = Paint()
        ..color = _cream.withValues(alpha: .7)
        ..strokeWidth = math.max(.7, r * .02);
      for (var k = 1; k < 5; k++) {
        final y = blade.top + blade.height * k / 5;
        c.drawLine(Offset(blade.left, y), Offset(blade.right, y), lat);
      }
      c.drawLine(Offset(0, blade.top), Offset(0, blade.bottom), lat);
      c.restore();
    }
    c.restore();
    c.drawCircle(Offset.zero, r * .16, Paint()..color = _gold);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.paris, Offset.zero, r * .2, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, _gold, _ink, pass);
  }
}
