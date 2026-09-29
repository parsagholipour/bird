import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';
import 'parts.dart';

/// Ancient Arabian obstacles, carved from the same city as the backdrop:
/// minaret shafts under honeycomb muqarnas and a tiled band; a wind tower
/// carrying a turning brass astrolabe; a cedar mashrabiya screen of turned
/// beads round a turning stained-glass star; onion domes whose crescent
/// finials point at the opening; mud-brick ramparts with stepped merlons and
/// Najdi vent triangles; a lantern of coloured glass glowing in its brass
/// cage; and a spinning zellige star of turquoise, lapis and saffron tiles.
abstract final class ArabiaObstacles {
  static const _ink = Color(0xff3a2438);
  static const _gold = Color(0xffe6ae48), _goldDeep = Color(0xffa4702e);
  static const _goldLit = Color(0xffffe39a), _perfect = Color(0xffffd35a);
  static const _turquoise = Color(0xff2aa9a8),
      _turquoiseLit = Color(0xff8fe0d2);
  static const _lapis = Color(0xff2f56a0), _madder = Color(0xffc0413c);
  static const _saffron = Color(0xffeeae38), _cream = Color(0xfffff4e4);
  static const _plum = Color(0xff5a3a54);

  /// Sandstone, rose plaster and whitened stucco as (lit, body, shade).
  static const _stone = [
    (Color(0xfff8dcb8), Color(0xffe4b690), Color(0xffb0806e)),
    (Color(0xfff6c9aa), Color(0xffd89a82), Color(0xffa46a68)),
    (Color(0xfffff6ea), Color(0xffefdcd0), Color(0xffc2a8aa)),
  ];

  /// Cedar, turquoise-painted and honey wood as (lit, body, shade).
  static const _woods = [
    (Color(0xffc08a5a), Color(0xff8a5a3a), Color(0xff5a3626)),
    (Color(0xff5fb4ac), Color(0xff2f7f7e), Color(0xff1f5458)),
    (Color(0xffe0aa66), Color(0xffb47c3e), Color(0xff7a4e28)),
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
    garden: _minaret,
    wind: _astrolabe,
    petal: _mashrabiya,
    switchback: _dome,
    steps: _rampart,
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
    wheel: _zellige,
  );

  /// An eight-point star (khatam) of two squares, [r] to its points.
  static Path _khatam(double r, [Offset at = Offset.zero]) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + i * math.pi / 8;
      final rad = i.isEven ? r : r * .76;
      final p = at + Offset(math.cos(a), math.sin(a)) * rad;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  /// A star of [points] points and [inner] depth, [r] to its points.
  static Path _star(double r, int points, double inner) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / points;
      final p = Offset(math.cos(a), math.sin(a)) * (i.isEven ? r : r * inner);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  /// A pointed niche on the shaft whose hood points at the rim: the apex at
  /// [apex] from the rim, the jambs rising from [foot], [hw] half wide.
  static Path _niche(Column g, double cx, double apex, double foot, double hw) {
    final spring = apex + hw * 1.25;
    return Path()
      ..moveTo(cx - hw, g.y(foot))
      ..lineTo(cx - hw, g.y(spring))
      ..quadraticBezierTo(cx - hw, g.y(apex + hw * .35), cx, g.y(apex))
      ..quadraticBezierTo(cx + hw, g.y(apex + hw * .35), cx + hw, g.y(spring))
      ..lineTo(cx + hw, g.y(foot))
      ..close();
  }

  /// A band of turquoise tile studded with gilt eight-point stars.
  static void _tileBand(
    Canvas c,
    Column g,
    double from,
    double depth,
    PassState pass,
  ) {
    if (depth < 2) return;
    Kit.fill(c, g.band(from, from + depth), _turquoise);
    Kit.fill(c, g.band(from, from + math.max(.8, depth * .12)), _turquoiseLit);
    Kit.fill(
      c,
      g.band(from + depth * .88, from + depth),
      _mix(_turquoise, _ink, .45),
    );
    final n = math.max(1, (g.w / (depth * 1.4)).round());
    final star = pass.perfect ? _perfect : _gold;
    for (var i = 0; i < n; i++) {
      final at = Offset(g.r.left + g.w * (i + .5) / n, g.y(from + depth / 2));
      c.drawPath(_khatam(depth * .32, at), Paint()..color = star);
      c.drawCircle(at, depth * .1, Paint()..color = _cream);
    }
  }

  // ---------------------------------------------------------------------------
  // Columns

  /// A minaret shaft: honeycomb muqarnas corbelling out under a cedar
  /// balcony at the rim, a tiled band, then sandstone with tall pointed
  /// windows, rose ablaq courses or a stucco lozenge net.
  static void _minaret(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // The balcony: a cedar railing of turned balusters.
    final rail = math.min((w * .2).clamp(4.0, 12.0), g.h - start);
    final (woodLit, wood, woodShade) = _woods[0];
    Kit.fill(c, g.band(start, start + rail), _mix(woodShade, _ink, .3));
    final balusters = math.max(3, (w / 7).round());
    for (var i = 0; i < balusters; i++) {
      final x = g.r.left + w * (i + .5) / balusters;
      Kit.fill(
        c,
        g.band(
          start + rail * .15,
          start + rail * .9,
          x - w * .025,
          x + w * .025,
        ),
        wood,
      );
      c.drawCircle(
        Offset(x, g.y(start + rail * .5)),
        w * .035,
        Paint()..color = woodLit,
      );
    }
    Kit.fill(c, g.band(start, start + rail * .15), woodLit);
    Kit.fill(c, g.band(start + rail * .85, start + rail), wood);
    // Muqarnas: three tiers of pointed cells stepping in from the balcony.
    final tier = (w * .15).clamp(4.0, 10.0);
    var d = start + rail;
    for (var t = 0; t < 3 && d < g.h; t++, d += tier) {
      Kit.fill(
        c,
        g.band(d, d + tier),
        t.isEven ? tone.$1 : _mix(tone.$2, tone.$1, .4),
      );
      final n = 3 + (t.isOdd ? 1 : 0);
      final cell = w / n;
      for (var k = 0; k < n; k++) {
        final cx = g.r.left + cell * (k + .5);
        c.drawPath(
          _niche(g, cx, d + tier * .12, d + tier, cell * .36),
          Paint()..color = _mix(tone.$3, _plum, .25),
        );
        Kit.fill(
          c,
          g.band(d + tier * .5, d + tier, cx + cell * .12, cx + cell * .36),
          _mix(tone.$3, tone.$2, .5),
        );
      }
      Kit.fill(c, g.band(d + tier - .8, d + tier), _mix(tone.$3, _ink, .3));
    }
    final band = (w * .22).clamp(5.0, 14.0);
    _tileBand(c, g, d, band, pass);
    final shaft = d + band;
    switch (v) {
      case 1:
        // Ablaq: courses of cream and rose stone.
        final course = math.max(7.0, w * .2);
        var k = 0;
        for (var y = shaft; y < g.h; y += course, k++) {
          Kit.fill(
            c,
            g.band(y, y + course),
            k.isEven ? _mix(_cream, tone.$2, .25) : tone.$2,
          );
          Kit.fill(c, g.band(y, y + 1), _mix(tone.$3, _ink, .2));
        }
        Kit.volume(
          c,
          g.band(shaft, g.h),
          const Color(0x33ffffff),
          const Color(0x00000000),
          const Color(0x40503040),
        );
      case 2:
        // A stucco net of lozenges in raised relief.
        final cell = math.max(9.0, w * .34);
        Parts.lattice(
          c,
          g,
          shaft + 2,
          cell,
          _mix(tone.$3, _plum, .2),
          width: math.max(1.2, w * .03),
        );
        Parts.lattice(
          c,
          g,
          shaft + 3,
          cell,
          tone.$1,
          width: math.max(.8, w * .015),
        );
      default:
        // Tall pointed windows with a gilt colonnette between their lights.
        final pitch = math.max(24.0, w * .9);
        for (var y = shaft + 4; y + pitch * .7 < g.h + pitch; y += pitch) {
          final hw = w * .2;
          c.drawPath(
            _niche(g, g.cx, y, y + pitch * .72, hw + w * .05),
            Paint()..color = tone.$1,
          );
          c.drawPath(
            _niche(g, g.cx, y + w * .04, y + pitch * .72, hw),
            Paint()..color = _mix(_plum, _ink, .3),
          );
          Kit.fill(
            c,
            g.band(
              y + hw * 1.3,
              y + pitch * .72,
              g.cx - w * .02,
              g.cx + w * .02,
            ),
            pass.perfect ? _perfect : _gold,
          );
          Kit.fill(c, g.band(y + pitch * .72, y + pitch * .76), tone.$1);
          Kit.fill(c, g.band(y + pitch * .76, y + pitch * .8), tone.$3);
        }
    }
    Parts.seal(
      c,
      g,
      WorldRegion.arabia,
      d + band / 2,
      math.min(w * .13, band * .42),
      pass,
    );
  }

  /// A wind tower whose open head carries a brass astrolabe: its rete of
  /// star pointers and its rule turn against each other. Below, the vents
  /// that catch the wind and courses of plaster with palm-log ends.
  static void _astrolabe(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[(v + 1) % 3];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 8) / 2, (g.h - start - 4) / 2);
    final disc = radius >= 9;
    final from = disc ? start + radius * 2 + 6 : start;
    // Vents: tall slots divided by piers, crossed by a pole.
    final vent = math.min(w * .9, math.max(0.0, g.h - from - 2));
    if (vent > 6) {
      Kit.fill(c, g.band(from + 2, from + 2 + vent), _mix(tone.$3, _plum, .55));
      for (final fx in const [.1, .5, .9]) {
        final x = g.r.left + w * fx;
        Kit.fill(
          c,
          g.band(from + 2, from + 2 + vent, x - w * .1, x + w * .1),
          fx > .6 ? tone.$1 : tone.$2,
        );
      }
      Kit.fill(c, g.band(from + 2, from + 2 + math.max(1.5, w * .05)), tone.$1);
      Kit.fill(
        c,
        g.band(
          from + 2 + vent * .55,
          from + 2 + vent * .55 + math.max(1.5, w * .04),
        ),
        _woods[0].$2,
      );
    }
    Parts.courses(
      c,
      g,
      from + 2 + vent,
      math.max(10.0, w * .32),
      _mix(tone.$3, _ink, .25),
      tone.$1,
      tone.$3.withValues(alpha: .6),
    );
    // Palm-log ends in a row under the vents.
    for (var i = 0; i < 4; i++) {
      final x = g.r.left + w * (i + .5) / 4;
      c.drawCircle(
        Offset(x, g.y(from + vent + 8)),
        math.max(1.0, w * .035),
        Paint()..color = _mix(_woods[0].$3, _ink, .2),
      );
    }
    if (!disc) return;
    Kit.fill(c, g.band(start, from), _mix(_plum, _ink, .45));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    final brass = pass.perfect ? _perfect : _gold;
    // The mater: a brass disc with a ring of degree ticks.
    c.drawCircle(hub, radius, Paint()..color = _goldDeep);
    c.drawCircle(hub, radius * .9, Paint()..color = brass);
    c.drawCircle(
      hub,
      radius * .74,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.35),
          colors: [_goldLit, _mix(brass, _goldDeep, .3)],
        ).createShader(Rect.fromCircle(center: hub, radius: radius * .74)),
    );
    final tick = Paint()
      ..color = _goldDeep
      ..strokeWidth = math.max(.7, radius * .03);
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      final dir = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        hub + dir * radius * (i % 3 == 0 ? .76 : .81),
        hub + dir * radius * .88,
        tick,
      );
    }
    // Engraved almucantars on the plate.
    final engrave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, radius * .02)
      ..color = _goldDeep.withValues(alpha: .6);
    for (final k in const [.22, .38, .54]) {
      c.drawCircle(hub + Offset(0, radius * k * .5), radius * k, engrave);
    }
    // The rete: an off-centre ecliptic ring and flame-shaped star pointers.
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(m.spin(.45, v * .7));
    final rete = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, radius * .07)
      ..color = _mix(brass, _cream, .35);
    c.drawCircle(Offset(0, -radius * .2), radius * .46, rete);
    c.drawLine(Offset(-radius * .7, 0), Offset(radius * .7, 0), rete);
    c.drawLine(
      Offset(0, -radius * .7),
      Offset(0, radius * .7),
      rete..strokeWidth = math.max(1.0, radius * .05),
    );
    final pointer = Paint()..color = _mix(brass, _cream, .45);
    for (var i = 0; i < 7; i++) {
      final a = i * math.pi * 2 / 7 + .3;
      final dir = Offset(math.cos(a), math.sin(a));
      final side = Offset(-dir.dy, dir.dx);
      final root = dir * radius * .5, tip = dir * radius * .78;
      c.drawPath(
        Path()
          ..moveTo(
            root.dx + side.dx * radius * .06,
            root.dy + side.dy * radius * .06,
          )
          ..quadraticBezierTo(
            tip.dx + side.dx * radius * .12,
            tip.dy + side.dy * radius * .12,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            root.dx,
            root.dy,
            root.dx - side.dx * radius * .06,
            root.dy - side.dy * radius * .06,
          )
          ..close(),
        pointer,
      );
      c.drawCircle(tip, math.max(.8, radius * .04), Paint()..color = _cream);
    }
    c.restore();
    // The rule turns the other way.
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(m.spin(-.25, 1.1 + v));
    c.drawPath(
      Kit.poly([
        -radius * .86,
        0,
        -radius * .1,
        -radius * .06,
        radius * .86,
        0,
        radius * .1,
        radius * .06,
      ]),
      Paint()..color = _mix(_goldDeep, _ink, .2),
    );
    c.restore();
    c.drawCircle(hub, radius * .1, Paint()..color = _goldDeep);
    c.drawCircle(hub, radius * .05, Paint()..color = _goldLit);
    // The throne (kursi) joining the disc to the tower.
    final throne = g.y(start + radius * 2 + 3);
    c.drawPath(
      Path()
        ..moveTo(g.cx - radius * .3, throne)
        ..quadraticBezierTo(
          g.cx - radius * .2,
          throne + g.dir * radius * .22,
          g.cx,
          throne + g.dir * radius * .3,
        )
        ..quadraticBezierTo(
          g.cx + radius * .2,
          throne + g.dir * radius * .22,
          g.cx + radius * .3,
          throne,
        )
        ..close(),
      Paint()..color = brass,
    );
    Parts.seal(
      c,
      g,
      WorldRegion.arabia,
      start + radius + 3,
      radius * .26,
      pass,
    );
  }

  /// A mashrabiya screen of turned cedar beads under a stucco panel where a
  /// qamariya, a star of stained glass, turns in the light.
  static void _mashrabiya(Canvas c, Column g, int v, PassState pass, Motion m) {
    final (lit, wood, shade) = _woods[v];
    Kit.volume(c, g.r, lit, wood, shade);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min(w * .38, (g.h - start - 6) * .42);
    final bloom = radius >= 6;
    final from = bloom ? start + radius * 2 + 7 : start;
    // The lattice: dark voids crossed by turned spindles, a bead at every
    // crossing, and a solid rail every few rows.
    Kit.fill(c, g.band(from, g.h), _mix(shade, _ink, .5));
    final pitch = math.max(6.0, w * .17);
    final spindle = math.max(1.0, pitch * .2);
    var row = 0;
    for (var d = from + pitch * .5; d < g.h + pitch; d += pitch, row++) {
      if (row % 5 == 4) {
        Kit.fill(c, g.band(d - pitch * .3, d + pitch * .3), wood);
        Kit.fill(c, g.band(d - pitch * .3, d - pitch * .18), lit);
        continue;
      }
      Kit.fill(c, g.band(d - spindle / 2, d + spindle / 2), wood);
      for (var x = g.r.left + pitch * .5; x < g.r.right; x += pitch) {
        Kit.fill(
          c,
          g.band(
            d - pitch / 2,
            d + pitch / 2,
            x - spindle / 2,
            x + spindle / 2,
          ),
          wood,
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, g.y(d)),
            width: pitch * .44,
            height: pitch * .5,
          ),
          Paint()..color = wood,
        );
        c.drawCircle(
          Offset(x - pitch * .06, g.y(d) - pitch * .08),
          pitch * .1,
          Paint()..color = lit,
        );
      }
    }
    if (!bloom) return;
    // The stucco panel and its turning star of coloured glass.
    Kit.fill(c, g.band(start, from), _mix(_cream, _stone[2].$2, .4));
    Kit.fill(c, g.band(from - 2, from), _mix(shade, _ink, .3));
    final hub = Offset(g.cx, g.y(start + radius + 3.5));
    final glass = [
      [_turquoise, _madder, _saffron, _lapis],
      [_lapis, _saffron, _turquoise, _madder],
      [_madder, _turquoise, _lapis, _saffron],
    ][v];
    c.drawCircle(hub, radius, Paint()..color = _cream);
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(m.spin(.5, v * .4));
    // Eight petals of glass round the star, the stucco left standing between.
    for (var i = 0; i < 8; i++) {
      c.save();
      c.rotate(i * math.pi / 4);
      c.drawPath(
        Path()
          ..moveTo(0, -radius * .5)
          ..quadraticBezierTo(radius * .2, -radius * .7, 0, -radius * .92)
          ..quadraticBezierTo(-radius * .2, -radius * .7, 0, -radius * .5)
          ..close(),
        Paint()..color = _mix(glass[1 + i % 2], _cream, .15),
      );
      c.drawCircle(
        Offset(radius * .38, -radius * .78),
        radius * .06,
        Paint()..color = glass[3],
      );
      c.restore();
    }
    c.drawPath(_khatam(radius * .5), Paint()..color = _cream);
    c.drawPath(
      _khatam(radius * .42),
      Paint()..color = _mix(glass[0], _cream, .15),
    );
    c.drawPath(
      _khatam(radius * .2),
      Paint()..color = pass.perfect ? _perfect : _gold,
    );
    c.restore();
    c.drawCircle(
      hub,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, radius * .08)
        ..color = _mix(_cream, shade, .35),
    );
    Parts.seal(
      c,
      g,
      WorldRegion.arabia,
      start + radius + 3.5,
      radius * .3,
      pass,
    );
  }

  /// An onion dome of turquoise tile, gilt or lapis on its drum, its
  /// crescent finial pointing at the opening; below, tiled bands on
  /// sandstone.
  static void _dome(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[0];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final len = math.min(w * 1.5, g.h - start);
    final (lit, body, shade) = [
      (_turquoiseLit, _turquoise, _mix(_turquoise, _ink, .45)),
      (
        pass.perfect ? const Color(0xfffff0b0) : _goldLit,
        pass.perfect ? _perfect : _gold,
        _goldDeep,
      ),
      (const Color(0xff7fa2e0), _lapis, _mix(_lapis, _ink, .45)),
    ][v];
    // Dawn sky behind the dome.
    Kit.fill(
      c,
      g.band(start, start + len),
      _mix(_plum, const Color(0xff2f7f96), .6),
    );
    final tip = start + len * .3,
        widest = start + len * .66,
        foot = start + len * .92;
    final half = w * .5 - 1;
    Path onion(double k) => Path()
      ..moveTo(g.cx, g.y(tip))
      ..cubicTo(
        g.cx - half * k * .1,
        g.y(tip + len * .08),
        g.cx - half * k * .45,
        g.y(tip + len * .14),
        g.cx - half * k * .78,
        g.y(widest - len * .12),
      )
      ..cubicTo(
        g.cx - half * k * 1.02,
        g.y(widest),
        g.cx - half * k * .98,
        g.y(foot - len * .06),
        g.cx - half * k * .8,
        g.y(foot),
      )
      ..lineTo(g.cx + half * k * .8, g.y(foot))
      ..cubicTo(
        g.cx + half * k * .98,
        g.y(foot - len * .06),
        g.cx + half * k * 1.02,
        g.y(widest),
        g.cx + half * k * .78,
        g.y(widest - len * .12),
      )
      ..cubicTo(
        g.cx + half * k * .45,
        g.y(tip + len * .14),
        g.cx + half * k * .1,
        g.y(tip + len * .08),
        g.cx,
        g.y(tip),
      )
      ..close();
    final dome = onion(1);
    c.drawPath(dome, Paint()..color = body);
    c.save();
    c.clipPath(dome);
    Kit.fill(c, g.band(tip, foot, g.r.left, g.cx - half * .45), shade);
    Kit.fill(c, g.band(tip, foot, g.cx + half * .3, g.r.right), lit);
    // Ribs of tile follow the curve.
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, w * .018)
      ..color = _mix(shade, _ink, .3).withValues(alpha: .7);
    for (final k in const [.3, .62]) {
      c.drawPath(onion(k), rib);
    }
    c.drawLine(Offset(g.cx, g.y(tip)), Offset(g.cx, g.y(foot)), rib);
    c.restore();
    // The drum: a tile band and a row of little arched windows.
    final drum = g.h - foot;
    if (drum > 3) {
      Kit.fill(
        c,
        g.band(foot, foot + math.min(drum, 3)),
        pass.perfect ? _perfect : _gold,
      );
      final band = math.min(drum - 3, math.max(8.0, w * .3));
      Kit.fill(c, g.band(foot + 3, foot + 3 + band), _cream);
      final n = 3;
      for (var i = 0; i < n; i++) {
        final cx = g.r.left + w * (i + .5) / n;
        c.drawPath(
          _niche(g, cx, foot + 3 + band * .15, foot + 3 + band * .9, w * .07),
          Paint()..color = _mix(_plum, _ink, .3),
        );
      }
      final shaft = foot + 3 + band;
      Parts.courses(
        c,
        g,
        shaft,
        math.max(10.0, w * .38),
        _mix(tone.$3, _ink, .25),
        tone.$1,
        tone.$3.withValues(alpha: .6),
      );
      for (var d = shaft + w * 1.2; d < g.h; d += w * 2.4) {
        _tileBand(c, g, d, math.max(4.0, w * .14), pass);
      }
    }
    // The finial: a spike threaded with gilt balls, the crescent nearest the
    // opening.
    final gilt = pass.perfect ? _perfect : _gold;
    final spike = Paint()
      ..color = gilt
      ..strokeWidth = math.max(1.0, w * .03);
    c.drawLine(
      Offset(g.cx, g.y(tip)),
      Offset(g.cx, g.y(start + len * .06)),
      spike,
    );
    for (final (k, r) in const [(.24, .06), (.17, .045)]) {
      c.drawCircle(
        Offset(g.cx, g.y(start + len * k)),
        w * r,
        Paint()..color = gilt,
      );
    }
    final moonAt = Offset(g.cx, g.y(start + len * .08));
    final mr = w * .07;
    c.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moonAt, radius: mr)),
        Path()..addOval(
          Rect.fromCircle(
            center: moonAt + Offset(0, -g.dir * mr * .45),
            radius: mr * .86,
          ),
        ),
      ),
      Paint()..color = gilt,
    );
    Parts.seal(
      c,
      g,
      WorldRegion.arabia,
      widest,
      math.min(w * .14, len * .1),
      pass,
    );
  }

  /// A mud-brick rampart: stepped merlons at the rim with dark embrasures,
  /// a row of Najdi vent triangles, palm-log ends and plastered courses.
  static void _rampart(Canvas c, Column g, int v, PassState pass, Motion m) {
    final tone = _stone[v == 2 ? 2 : (v == 0 ? 1 : 0)];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final parapet = math.min(w * .5, g.h - start);
    // Embrasures cut between three stepped merlons.
    final gap = _mix(tone.$3, _plum, .55);
    Kit.fill(c, g.band(start, start + parapet * .62), gap);
    final n = 3;
    final pitch = w / n;
    for (var i = 0; i < n; i++) {
      final cx = g.r.left + pitch * (i + .5);
      for (final (step, half) in const [(0.0, .18), (.22, .3), (.44, .42)]) {
        Kit.fill(
          c,
          g.band(
            start + parapet * step,
            start + parapet * .64,
            cx - pitch * half,
            cx + pitch * half,
          ),
          tone.$2,
        );
        Kit.fill(
          c,
          g.band(
            start + parapet * step,
            start + parapet * .64,
            cx + pitch * half * .4,
            cx + pitch * half,
          ),
          tone.$1,
        );
        Kit.fill(
          c,
          g.band(
            start + parapet * step,
            start + parapet * step + math.max(.8, parapet * .04),
            cx - pitch * half,
            cx + pitch * half,
          ),
          _mix(tone.$1, _cream, .5),
        );
      }
    }
    Kit.fill(
      c,
      g.band(start + parapet * .62, start + parapet * .66),
      _mix(tone.$3, _ink, .25),
    );
    // Vent triangles and palm-log ends.
    final vents = start + parapet * .72;
    final tri = math.max(3.0, w * .08);
    final count = math.max(2, (w / (tri * 2.4)).floor());
    for (var i = 0; i < count; i++) {
      final cx = g.r.left + w * (i + .5) / count;
      c.drawPath(
        Kit.poly([
          cx - tri * .6,
          g.y(vents + tri),
          cx + tri * .6,
          g.y(vents + tri),
          cx,
          g.y(vents),
        ]),
        Paint()..color = _mix(_plum, _ink, .3),
      );
    }
    final logs = vents + tri + math.max(3.0, w * .08);
    for (
      var x = g.r.left + w * .12;
      x < g.r.right - 2;
      x += math.max(6.0, w * .2)
    ) {
      c.drawCircle(
        Offset(x, g.y(logs)),
        math.max(1.1, w * .03),
        Paint()..color = _mix(_woods[0].$3, _ink, .2),
      );
    }
    // A painted band, then courses of mud brick.
    final band = logs + math.max(3.0, w * .07);
    Kit.fill(
      c,
      g.band(band, band + math.max(2.0, w * .04)),
      v == 2 ? _turquoise : _madder,
    );
    Kit.fill(
      c,
      g.band(band + math.max(2.0, w * .04), band + math.max(3.0, w * .05)),
      pass.perfect ? _perfect : _gold,
    );
    Parts.courses(
      c,
      g,
      band + math.max(3.0, w * .05),
      math.max(7.0, w * .2),
      _mix(tone.$3, _ink, .2),
      tone.$1,
      tone.$3.withValues(alpha: .55),
    );
    Parts.seal(
      c,
      g,
      WorldRegion.arabia,
      start + parapet * .4,
      math.min(w * .12, parapet * .2),
      pass,
    );
  }

  // ---------------------------------------------------------------------------
  // Floating obstacles

  /// A lantern of coloured glass: lamplight fills a globe of ruby, emerald
  /// or sapphire panes set in brass meridians, girt by a pierced band, under
  /// a pierced domed cap on the chain side and over a scalloped foot.
  static void _lantern(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    Motion m,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    final brass = pass.perfect ? _perfect : _gold;
    final flicker =
        .86 +
        .09 * math.sin(m.time * 5.3 + v) +
        .05 * math.sin(m.time * 13.1 + v * 2);
    final (pane, alt) = [
      (_madder, const Color(0xffffb347)),
      (const Color(0xff2f9a78), const Color(0xffffc85a)),
      (_lapis, const Color(0xfff08a78)),
    ][v];
    final side = upper ? -1.0 : 1.0;
    c.save();
    c.clipPath(Path()..addOval(bounds));
    // The flame's light fills the glass.
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, -side * .08),
          colors: [
            _mix(const Color(0xfffff2c8), _cream, .3 * flicker),
            const Color(0xffffc45e),
            _mix(pane, const Color(0xffd0702a), .5),
          ],
          stops: const [0, .42, 1],
          radius: .5 + .12 * flicker,
        ).createShader(bounds),
    );
    // Panes between the meridians, alternately tinted.
    for (var k = 0; k < 6; k++) {
      final x0 = r * math.sin(-math.pi / 2 + k * math.pi / 6);
      final x1 = r * math.sin(-math.pi / 2 + (k + 1) * math.pi / 6);
      c.drawRect(
        Rect.fromLTRB(x0, -r, x1, r),
        Paint()
          ..color = (k.isEven ? pane : alt).withValues(
            alpha: k.isEven ? .5 : .28,
          ),
      );
    }
    // Brass meridians and the pierced girdle.
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * .055)
      ..color = _goldDeep;
    for (final k in const [.5, .87]) {
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2 * k, height: r * 2.1),
        rib,
      );
    }
    c.drawLine(Offset(0, -r), Offset(0, r), rib);
    final girdle = Rect.fromLTRB(-r, -r * .08, r, r * .08);
    c.drawRect(girdle, Paint()..color = brass);
    final glow = Paint()
      ..color = _mix(
        const Color(0xfffff0c0),
        _cream,
        .3,
      ).withValues(alpha: flicker);
    for (var i = -4; i <= 4; i++) {
      c.drawPath(_khatam(r * .045, Offset(i * r * .22, 0)), glow);
    }
    // The domed cap on the chain side, pierced, with a scalloped hem.
    final cap = Path()..moveTo(-r, side * r * .52);
    for (var i = 0; i < 6; i++) {
      final x0 = -r + i * r / 3, x1 = x0 + r / 3;
      cap.quadraticBezierTo((x0 + x1) / 2, side * r * .38, x1, side * r * .52);
    }
    cap
      ..lineTo(r, side * r * 1.1)
      ..lineTo(-r, side * r * 1.1)
      ..close();
    c.drawPath(
      cap,
      Paint()
        ..shader = LinearGradient(
          colors: [_goldLit, brass, _goldDeep],
          stops: const [0, .45, 1],
        ).createShader(bounds),
    );
    for (var i = -2; i <= 2; i++) {
      c.drawCircle(Offset(i * r * .22, side * r * .66), r * .04, glow);
      if (i.abs() < 2) {
        c.drawCircle(
          Offset(i * r * .22 + r * .11, side * r * .78),
          r * .03,
          glow,
        );
      }
    }
    c.drawCircle(Offset(0, side * r * .9), r * .1, Paint()..color = _goldDeep);
    c.drawCircle(Offset(0, side * r * .9), r * .05, Paint()..color = _goldLit);
    // The foot.
    c.drawRect(
      Rect.fromLTRB(-r, -side * r * 1.1, r, -side * r * .78),
      Paint()..color = _goldDeep,
    );
    c.drawRect(
      Rect.fromLTRB(-r, -side * r * .82, r, -side * r * .76),
      Paint()..color = brass,
    );
    // A soft sheen on the glass.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-r * .42, -r * .12),
        width: r * .16,
        height: r * .5,
      ),
      Paint()..color = const Color(0x44ffffff),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.arabia,
        Offset(0, -side * r * .36),
        r * .2,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, brass, _ink, pass, band: .08);
  }

  /// A zellige star of cut tiles, turning: a white star at the heart, kites
  /// of turquoise and lapis, saffron points and a ring of small tiles, all
  /// set in dark grout.
  static void _zellige(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    Motion m,
  ) {
    final field = [
      _cream,
      const Color(0xfff0d8c4),
      _mix(_turquoise, _cream, .7),
    ][v];
    Parts.orbBegin(c, r, _cream, field, _mix(field, _plum, .35));
    final fold = const [8, 10, 12][v];
    final grout = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, r * .025)
      ..color = _mix(_ink, _plum, .3);
    c.save();
    c.rotate(m.spin(upper ? .4 : -.4));
    // The outer ring of small tiles.
    for (var i = 0; i < fold * 2; i++) {
      final a0 = i * math.pi / fold, a1 = (i + 1) * math.pi / fold;
      final path = Path()
        ..moveTo(math.cos(a0) * r * .78, math.sin(a0) * r * .78)
        ..lineTo(math.cos(a0) * r, math.sin(a0) * r)
        ..lineTo(math.cos(a1) * r, math.sin(a1) * r)
        ..lineTo(math.cos(a1) * r * .78, math.sin(a1) * r * .78)
        ..close();
      c.drawPath(path, Paint()..color = i.isEven ? _lapis : _turquoise);
      c.drawPath(path, grout);
    }
    // Saffron points and turquoise/lapis kites round the heart.
    for (var i = 0; i < fold; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / fold;
      final dir = Offset(math.cos(a), math.sin(a));
      final side = Offset(-dir.dy, dir.dx);
      final kite = Kit.poly([
        dir.dx * r * .3, dir.dy * r * .3, //
        (dir * r * .5 + side * r * .15).dx, (dir * r * .5 + side * r * .15).dy,
        dir.dx * r * .76, dir.dy * r * .76,
        (dir * r * .5 - side * r * .15).dx, (dir * r * .5 - side * r * .15).dy,
      ]);
      c.drawPath(kite, Paint()..color = i.isEven ? _turquoise : _lapis);
      c.drawPath(kite, grout);
      final b = a + math.pi / fold;
      final bd = Offset(math.cos(b), math.sin(b));
      final bs = Offset(-bd.dy, bd.dx);
      final point = Kit.poly([
        (bd * r * .42 + bs * r * .08).dx, (bd * r * .42 + bs * r * .08).dy, //
        bd.dx * r * .7, bd.dy * r * .7,
        (bd * r * .42 - bs * r * .08).dx, (bd * r * .42 - bs * r * .08).dy,
      ]);
      c.drawPath(point, Paint()..color = _saffron);
      c.drawPath(point, grout);
    }
    final heart = _star(r * .34, fold, .62);
    c.drawPath(heart, Paint()..color = _cream);
    c.drawPath(heart, grout);
    c.drawPath(
      _star(r * .16, fold, .6),
      Paint()..color = pass.perfect ? _perfect : _madder,
    );
    c.restore();
    c.drawCircle(
      Offset(-r * .3, -r * .34),
      r * .16,
      Paint()..color = const Color(0x33ffffff),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.arabia,
        Offset.zero,
        r * .22,
        perfect: pass.perfect,
      );
    }
    Parts.orbEnd(c, r, pass.perfect ? _perfect : _gold, _ink, pass);
  }
}
