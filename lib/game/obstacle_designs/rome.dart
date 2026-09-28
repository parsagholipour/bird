import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Roman obstacles: fluted marble columns under scrolled capitals; a
/// bronze-rimmed chariot wheel on a brick plinth; a wall of scarlet legion
/// shields; a Trajan-style column wound with relief; travertine arcades like
/// the Colosseum's; a bronze oil lamp; and a gold coin ringed with laurel.
abstract final class RomeObstacles {
  static const _ink = Color(0xff3a2a1e);
  static const _gold = Color(0xffd9a441), _goldDeep = Color(0xff9a6f22);
  static const _red = Color(0xffb8402f), _redDeep = Color(0xff7a2a20);
  static const _bronze = Color(0xff9a6a3a), _laurel = Color(0xff5f8a4a);
  static const _cream = Color(0xfffff4dc), _dark = Color(0xff4a3524);

  static const _marble = [
    (Color(0xfff8f2e4), Color(0xffe8dfc8), Color(0xffbfae90)),
    (Color(0xfff2ece0), Color(0xffdcd4c4), Color(0xffaaa290)),
    (Color(0xfffbeed6), Color(0xffecd8b4), Color(0xffc4a878)),
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
    garden: _fluted,
    wind: _chariot,
    petal: _shields,
    switchback: _trajan,
    steps: _arcade,
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
    lantern: _lamp,
    wheel: _coin,
  );

  /// A fluted marble shaft under a scrolled capital and abacus.
  static void _fluted(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _marble[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final slab = math.min(math.max(3.0, w * .1), g.h - start);
    final bell = math.max(0.0, math.min(math.max(8.0, w * .32), g.h - start - slab));
    final flute = _mix(tone.$3, _ink, .1).withValues(alpha: .55);
    for (var x = g.r.left + w * .12; x < g.r.right - 1; x += math.max(4.0, w * .14)) {
      Kit.fill(c, g.band(start + slab + bell, g.h, x, x + 1), flute);
    }
    Kit.fill(c, g.band(start, start + slab), tone.$1);
    Kit.fill(c, g.band(start + slab * .6, start + slab), tone.$3);
    Kit.fill(c, g.band(start + slab, start + slab + bell), _mix(tone.$2, tone.$1, .4));
    final scroll = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, bell * .1)
      ..color = tone.$3;
    for (final side in const [.24, .76]) {
      c.drawCircle(Offset(g.r.left + w * side, g.y(start + slab + bell * .5)), bell * .3, scroll);
      c.drawCircle(Offset(g.r.left + w * side, g.y(start + slab + bell * .5)), bell * .08, Paint()..color = tone.$3);
    }
    Kit.fill(c, g.band(start + slab + bell, start + slab + bell + 2), pass.perfect ? const Color(0xffffd35a) : _gold);
    Parts.seal(c, g, WorldRegion.rome, start + slab + bell * .5, math.min(w * .12, bell * .25), pass);
  }

  /// A chariot wheel with a bronze rim on a brick plinth.
  static void _chariot(Canvas c, Column g, int v, PassState pass, Motion m) {
    final brick = [const Color(0xffc8703f), const Color(0xffb8623f), const Color(0xffd08050)][v];
    Kit.volume(c, g.r, _mix(brick, _cream, .3), brick, _mix(brick, _ink, .4));
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final wheel = radius >= 9;
    final from = wheel ? start + radius * 2 + 6 : start;
    Parts.courses(c, g, from, math.max(8.0, w * .24), _mix(brick, _ink, .5), _mix(brick, _cream, .3), _mix(brick, _ink, .3));
    if (!wheel) return;
    Kit.fill(c, g.band(start, start + radius * 2 + 6), _mix(brick, _ink, .55));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    Parts.wheel(c, hub, radius, m.spin(.9, v * .5), 8, pass.perfect ? const Color(0xffffd35a) : _bronze, const Color(0xffcfa070));
    Parts.seal(c, g, WorldRegion.rome, start + radius + 3, radius * .18, pass);
  }

  /// A testudo wall of scarlet scuta with gold bosses, swaying in rows.
  static void _shields(Canvas c, Column g, int v, PassState pass, Motion m) {
    final red = [_red, const Color(0xffa83a6a), const Color(0xff2f5fa0)][v];
    Kit.volume(c, g.r, _mix(red, _cream, .3), red, _mix(red, _ink, .45));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final sw = math.max(8.0, w * .5), sh = sw * 1.2;
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    var row = 0;
    for (var d = start + 2; d < g.h; d += sh * .9, row++) {
      final sway = math.sin(m.time * 1.4 + row * 1.3) * sw * .08;
      final offset = (row.isOdd ? sw / 2 : 0.0) + sway;
      for (var x = g.r.left - sw + offset; x < g.r.right; x += sw) {
        final y0 = g.y(d), y1 = g.y(d + sh);
        final rect = Rect.fromLTRB(x + 1, math.min(y0, y1), x + sw - 1, math.max(y0, y1));
        c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(sw * .18)), Paint()..color = _mix(red, _ink, .15));
        c.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1.2), Radius.circular(sw * .16)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.8, sw * .05)
            ..color = gold,
        );
        c.drawCircle(rect.center, sw * .14, Paint()..color = gold);
        c.drawCircle(rect.center, sw * .06, Paint()..color = _goldDeep);
      }
    }
    Parts.seal(c, g, WorldRegion.rome, start + 6, math.min(w * .12, 6), pass);
  }

  /// A Trajan-style column: marble wound with a spiral of relief.
  static void _trajan(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _marble[(v + 1) % 3];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final ring = math.min(math.max(4.0, w * .16), g.h - start);
    Kit.fill(c, g.band(start, start + ring), _laurel);
    Kit.fill(c, g.band(start + ring * .4, start + ring * .6), pass.perfect ? const Color(0xffffd35a) : _gold);
    final pitch = math.max(10.0, w * .5);
    final relief = Paint()
      ..color = _mix(tone.$3, _ink, .15)
      ..strokeWidth = math.max(2.0, w * .09)
      ..strokeCap = StrokeCap.butt;
    for (var d = start + ring; d < g.h + pitch; d += pitch) {
      c.drawLine(Offset(g.r.left, g.y(d)), Offset(g.r.right, g.y(d + pitch * .5)), relief);
    }
    final figure = Paint()..color = tone.$3.withValues(alpha: .8);
    for (var d = start + ring + pitch * .25; d < g.h; d += pitch) {
      for (var x = g.r.left + w * .18; x < g.r.right - w * .1; x += w * .3) {
        c.drawCircle(Offset(x, g.y(d + (x - g.r.left) / w * pitch * .5)), math.max(.8, w * .03), figure);
      }
    }
    Parts.seal(c, g, WorldRegion.rome, start + ring * .5, math.min(w * .12, ring * .4), pass);
  }

  /// Travertine arcades in tiers, as on the Colosseum's outer wall.
  static void _arcade(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = [
      (const Color(0xfff0dcae), const Color(0xffdcc290), const Color(0xffb09468)),
      (const Color(0xffe8d2a8), const Color(0xffd0b486), const Color(0xffa48a5e)),
      (const Color(0xfff4e4c0), const Color(0xffe2cc9c), const Color(0xffb8a070)),
    ][v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final cornice = math.min(math.max(4.0, w * .14), g.h - start);
    Kit.fill(c, g.band(start, start + cornice), tone.$1);
    Kit.fill(c, g.band(start + cornice * .6, start + cornice), tone.$3);
    final tier = math.max(14.0, w * .5);
    final arch = math.max(4.0, tier * .5);
    var row = 0;
    for (var d = start + cornice + 3; d + tier < g.h + tier * .4; d += tier, row++) {
      final n = math.max(1, (w / (arch * 1.5)).round());
      for (var i = 0; i < n; i++) {
        Parts.niche(c, g, d + tier * .15, arch, tier * .72, _dark, cx: g.r.left + w * (i + .5) / n);
      }
      Kit.fill(c, g.band(d + tier - 2, d + tier), tone.$3.withValues(alpha: .7));
    }
    Parts.seal(c, g, WorldRegion.rome, start + cornice * .5, math.min(w * .12, cornice * .4), pass);
  }

  /// A bronze oil lamp ringed with a Greek key, its flame lit.
  static void _lamp(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final metal = [_bronze, const Color(0xffb08040), const Color(0xff7a6a4a)][v];
    Parts.orbBegin(c, r, _mix(metal, _cream, .45), metal, _mix(metal, _ink, .5));
    final flick = .8 + .2 * math.sin(m.time * 6 + v);
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    final key = Paint()..color = _mix(metal, _ink, .55);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      c.save();
      c.rotate(a);
      c.drawRect(Rect.fromLTWH(-r * .05, -r * .9, r * .1, r * .1), key);
      c.drawRect(Rect.fromLTWH(-r * .05, -r * .9, r * .1, r * .03), Paint()..color = gold);
      c.restore();
    }
    c.drawCircle(Offset.zero, r * .55, Paint()..color = _mix(metal, _ink, .35));
    c.drawPath(
      Path()
        ..moveTo(0, r * .3)
        ..quadraticBezierTo(-r * .3, -r * .02, 0, -r * .5 * flick)
        ..quadraticBezierTo(r * .3, -r * .02, 0, r * .3)
        ..close(),
      Paint()..color = _mix(const Color(0xffff9a3a), _cream, .3 * flick),
    );
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.rome, Offset(0, r * .5), r * .18, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, gold, _ink, pass, band: .09);
  }

  /// A gold coin turning under a ring of laurel leaves.
  static void _coin(Canvas c, double r, int v, bool upper, PassState pass, Motion m) {
    final gold = pass.perfect ? const Color(0xffffd35a) : _gold;
    Parts.orbBegin(c, r, _mix(gold, _cream, .5), gold, _mix(gold, _ink, .45));
    final spin = m.spin(upper ? .6 : -.6);
    c.save();
    c.rotate(spin);
    final leaves = const [12, 16, 14][v];
    for (var i = 0; i < leaves; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / leaves);
      c.translate(0, -r * .72);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * .16, height: r * .3), Paint()..color = i.isEven ? _laurel : const Color(0xff7fa85a));
      c.restore();
    }
    c.restore();
    c.drawCircle(Offset.zero, r * .5, Paint()..color = _mix(gold, _ink, .25));
    // A helmeted head in profile, its crest in scarlet.
    c.drawCircle(Offset(0, r * .04), r * .24, Paint()..color = _mix(gold, _cream, .4));
    c.drawArc(Rect.fromCircle(center: Offset(0, r * .0), radius: r * .26), math.pi, math.pi, true, Paint()..color = _goldDeep);
    c.drawRect(Rect.fromLTRB(-r * .03, -r * .42, r * .03, -r * .24), Paint()..color = _red);
    c.drawRect(Rect.fromLTRB(-r * .18, r * .28, r * .18, r * .34), Paint()..color = _redDeep);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.rome, Offset(0, r * .06), r * .16, perfect: pass.perfect);
    }
    Parts.orbEnd(c, r, _goldDeep, _ink, pass);
  }
}
