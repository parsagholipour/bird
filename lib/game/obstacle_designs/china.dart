import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';

/// Chinese obstacles: red-lacquer columns with gold bands under painted
/// bracket sets; a bamboo frame carrying a turning paper pinwheel; a column
/// of glazed roof tiles with round end caps around a turning plum blossom;
/// slender pagoda posts with upturned eaves; Great Wall brickwork with
/// battlements at the rim; a red silk lantern; and a round lattice window.
abstract final class ChinaObstacles {
  static const _ink = Color(0xff2a1f24);
  static const _redLit = Color(0xffec6a52), _red = Color(0xffc8402f);
  static const _redShade = Color(0xff8c2a22), _gold = Color(0xffe6b44c);
  static const _goldDeep = Color(0xffa8792c), _jade = Color(0xff4f9f86);
  static const _teal = Color(0xff3c8e98), _blue = Color(0xff2f5f8a);
  static const _cream = Color(0xfffff3e0);

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
        _pinwheel(c, g, v, pass, Kit.spin(seconds, reducedMotion, 1.3, v * .3));
      case ObstacleKind.petalGate:
        _tiles(c, g, v, pass, Kit.spin(seconds, reducedMotion, .3));
      case ObstacleKind.switchback:
        _pagoda(c, g, v, pass);
      case ObstacleKind.crystalSteps:
        _wall(c, g, v, pass);
      default:
        _lacquer(c, g, v, pass);
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
      _silk(c, radius, v, upper, pass, reducedMotion ? 0 : seconds);
    } else {
      _lattice(
        c,
        radius,
        v,
        pass,
        Kit.spin(seconds, reducedMotion, upper ? .3 : -.3),
      );
    }
  }

  static Color _mix(Color a, Color b, double t) => Kit.mix(a, b, t);

  /// A lacquered column under a painted bracket set (dougong): a beam with
  /// blue-green cloud bands and stacked gold-edged bracket blocks.
  static void _lacquer(Canvas c, Column g, int v, PassState pass) {
    final body = [
      (_redLit, _red, _redShade),
      (_mix(_jade, _cream, .3), _jade, _mix(_jade, _ink, .4)),
      (_redLit, _red, _redShade),
    ][v];
    Kit.volume(c, g.r, body.$1, body.$2, body.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final beam = (w * .22).clamp(6.0, 14.0);
    final brackets = (w * .36).clamp(8.0, 22.0);
    // The painted beam: teal with a gold-edged blue cartouche.
    Kit.fill(c, g.band(start, start + beam), _teal);
    Kit.fill(c, g.band(start, start + 1.4), _gold);
    Kit.fill(c, g.band(start + beam - 1.4, start + beam), _gold);
    Kit.fill(
      c,
      g.band(
        start + beam * .28,
        start + beam * .72,
        g.cx - w * .22,
        g.cx + w * .22,
      ),
      _blue,
    );
    c.drawCircle(
      Offset(g.cx, g.y(start + beam / 2)),
      beam * .18,
      Paint()..color = _gold,
    );
    // Bracket blocks, stacked and stepped inward toward the shaft.
    final from = start + beam;
    Kit.fill(c, g.band(from, from + brackets), _mix(_redShade, _ink, .45));
    for (var tier = 0; tier < 3; tier++) {
      final inset = w * (.05 + tier * .12);
      final d0 = from + brackets * tier / 3;
      final d1 = from + brackets * (tier + 1) / 3 - 1;
      final block = g.band(d0, d1, g.r.left + inset, g.r.right - inset);
      Kit.fill(c, block, tier.isEven ? _teal : _jade);
      Kit.fill(c, g.band(d0, d0 + 1, block.left, block.right), _gold);
      // Little bracket arms at each end.
      Kit.fill(
        c,
        g.band(d0 + 1, d1, block.left, block.left + w * .06),
        _gold.withValues(alpha: .8),
      );
      Kit.fill(
        c,
        g.band(d0 + 1, d1, block.right - w * .06, block.right),
        _gold.withValues(alpha: .8),
      );
    }
    final shaft = from + brackets;
    // Gold bands on the shaft, and a carved lattice panel for variant 2.
    final pitch = math.max(40.0, w * 1.4);
    for (var d = shaft + pitch * .35; d < g.h; d += pitch) {
      Kit.fill(c, g.band(d, d + 3), _gold);
      Kit.fill(c, g.band(d + 3, d + 4.2), _goldDeep);
    }
    if (v == 2 && g.h > shaft + 20) {
      final panel = g.band(shaft + 8, g.h, g.cx - w * .26, g.cx + w * .26);
      Kit.fill(c, panel, _mix(_redShade, _ink, .3));
      final bar = Paint()
        ..color = _gold
        ..strokeWidth = math.max(1.0, w * .025);
      final step = w * .13;
      for (var d = shaft + 8; d < g.h; d += step) {
        c.drawLine(
          Offset(panel.left, g.y(d)),
          Offset(panel.right, g.y(d)),
          bar,
        );
      }
      for (var x = panel.left; x <= panel.right + .1; x += step) {
        c.drawLine(Offset(x, g.y(shaft + 8)), Offset(x, g.y(g.h)), bar);
      }
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.china,
        Offset(g.cx, g.y(start + beam / 2)),
        math.min(beam * .5, w * .14),
        perfect: pass.perfect,
      );
    }
  }

  /// A bamboo frame with a festival paper pinwheel turning at the rim.
  static void _pinwheel(
    Canvas c,
    Column g,
    int v,
    PassState pass,
    double spin,
  ) {
    const cane = Color(0xffd6c37a),
        caneLit = Color(0xfff2e6ae),
        caneDeep = Color(0xff9f8a45);
    Kit.fill(c, g.r, _mix(_redShade, _ink, .35));
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 4) / 2, (g.h - start - 4) / 2);
    final wheel = radius >= 9;
    final from = wheel ? start + radius * 2 + 6 : start;
    // Two bamboo stiles and rungs hung with little drums.
    for (final left in [g.r.left, g.r.right - w * .2]) {
      Kit.volume(
        c,
        g.band(from, g.h, left, left + w * .2),
        caneLit,
        cane,
        caneDeep,
      );
    }
    final pitch = math.max(22.0, w * .7);
    var k = 0;
    for (var d = from + pitch * .5; d < g.h; d += pitch, k++) {
      Kit.fill(
        c,
        g.band(d, d + 3, g.r.left + w * .2, g.r.right - w * .2),
        cane,
      );
      Kit.fill(
        c,
        g.band(d, d + 1, g.r.left + w * .2, g.r.right - w * .2),
        caneLit,
      );
      // A small clapper drum rides on each rung.
      final drum = Rect.fromCenter(
        center: Offset(g.cx, g.y(d + pitch * .45)),
        width: w * .3,
        height: pitch * .36,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(drum, Radius.circular(w * .05)),
        Paint()..color = k.isEven ? _red : _gold,
      );
      c.drawRect(
        Rect.fromLTRB(
          drum.left,
          drum.center.dy - 1,
          drum.right,
          drum.center.dy + 1,
        ),
        Paint()..color = _cream,
      );
    }
    if (!wheel) return;
    Kit.fill(c, g.band(start, from), _mix(_blue, _ink, .45));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    final colors = [
      [_red, const Color(0xfff2c14e), _jade, const Color(0xff4f7fd0)],
      [const Color(0xfff2c14e), _red, const Color(0xffe87aa0), _teal],
      [_jade, _red, const Color(0xfff2c14e), _cream],
    ][v];
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    for (var i = 0; i < 8; i++) {
      c.save();
      c.rotate(i * math.pi / 4);
      // Each paper sail curls from the hub to its tip.
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(radius * .92, 0)
          ..quadraticBezierTo(
            radius * .7,
            radius * .35,
            radius * .2,
            radius * .38,
          )
          ..close(),
        Paint()..color = colors[i % 4],
      );
      c.drawLine(
        Offset.zero,
        Offset(radius * .92, 0),
        Paint()
          ..color = _mix(colors[i % 4], _ink, .35)
          ..strokeWidth = math.max(.8, radius * .04),
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(hub, radius * .16, Paint()..color = _gold);
    c.drawCircle(hub, radius * .07, Paint()..color = _cream);
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.china, hub, radius * .3, perfect: pass.perfect);
    }
  }

  /// Rows of glazed tube tiles point at the rim, finished with round end
  /// caps, around a turning plum blossom.
  static void _tiles(Canvas c, Column g, int v, PassState pass, double spin) {
    final glaze = [
      (
        const Color(0xfff0c55a),
        const Color(0xffd89a2c),
        const Color(0xffa36a1c),
      ),
      (
        const Color(0xff6fb08a),
        const Color(0xff3f8a66),
        const Color(0xff2a6048),
      ),
      (
        const Color(0xff6f9fd0),
        const Color(0xff3f6fb0),
        const Color(0xff2a4a80),
      ),
    ][v];
    Kit.fill(c, g.r, glaze.$3);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min(w * .38, (g.h - start - 6) * .42);
    final bloom = radius >= 6;
    final capRow = math.max(8.0, w * .18);
    final from = bloom ? start + radius * 2 + 7 : start;
    // End caps (wadang) line the first row with little flowers.
    final tubes = math.max(3, (w / 16).round());
    final tube = w / tubes;
    if (g.h > from + capRow) {
      Kit.fill(c, g.band(from, from + capRow), _mix(glaze.$3, _ink, .3));
      for (var i = 0; i < tubes; i++) {
        final at = Offset(g.r.left + tube * (i + .5), g.y(from + capRow / 2));
        c.drawCircle(at, tube * .42, Paint()..color = glaze.$2);
        c.drawCircle(at, tube * .2, Paint()..color = glaze.$1);
      }
    }
    final pitch = math.max(12.0, w * .22);
    var k = 0;
    for (var d = from + capRow; d < g.h; d += pitch, k++) {
      for (var i = 0; i < tubes; i++) {
        final left = g.r.left + tube * i;
        // Each tube tile: a glossy half-cylinder with a rounded lip.
        final b = g.band(d, d + pitch + 1, left + 1, left + tube - 1);
        c.drawRect(
          b,
          Paint()
            ..shader = LinearGradient(
              colors: [glaze.$1, glaze.$2, glaze.$3],
              stops: const [0, .5, 1],
            ).createShader(b),
        );
        Kit.fill(
          c,
          g.band(d, d + 1.6, left + 1, left + tube - 1),
          _mix(glaze.$1, _cream, .5),
        );
      }
      Kit.fill(
        c,
        g.band(d + pitch - .5, d + pitch + 1),
        _mix(glaze.$3, _ink, .35),
      );
    }
    if (!bloom) return;
    Kit.fill(c, g.band(start, from), _mix(_redShade, _ink, .3));
    final hub = Offset(g.cx, g.y(start + radius + 3.5));
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    const petal = Color(0xfff7c2cf), petalLit = Color(0xfffff0f3);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      final p = Offset(math.cos(a), math.sin(a)) * radius * .5;
      c.drawCircle(p, radius * .46, Paint()..color = petal);
      c.drawCircle(
        p + Offset(-radius * .08, -radius * .08),
        radius * .2,
        Paint()..color = petalLit,
      );
    }
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        Offset.zero,
        d * radius * .32,
        Paint()
          ..color = _redShade
          ..strokeWidth = math.max(.7, radius * .04),
      );
      c.drawCircle(
        d * radius * .34,
        math.max(.8, radius * .05),
        Paint()..color = _gold,
      );
    }
    c.restore();
    c.drawCircle(hub, radius * .12, Paint()..color = const Color(0xffe0607a));
    if (pass.cleared) {
      Kit.emblem(c, WorldRegion.china, hub, radius * .3, perfect: pass.perfect);
    }
  }

  /// A slender pagoda post: storeys of red wall under green-tiled eaves
  /// whose upturned corners point at the opening.
  static void _pagoda(Canvas c, Column g, int v, PassState pass) {
    final wall = [_red, _mix(_red, _goldDeep, .35), _mix(_red, _blue, .25)][v];
    const roof = Color(0xff3f6a5f), roofLit = Color(0xff6f9a8a);
    Kit.fill(c, g.r, _mix(roof, _ink, .45));
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final storey = math.max(20.0, w * .9);
    var k = 0;
    for (var d = start; d < g.h + storey; d += storey, k++) {
      // The eave sits at the rim end of each storey.
      final eave = storey * .3;
      final wallBand = g.band(
        d + eave,
        d + storey,
        g.r.left + w * .14,
        g.r.right - w * .14,
      );
      Kit.volume(
        c,
        wallBand,
        _mix(wall, _cream, .25),
        wall,
        _mix(wall, _ink, .35),
      );
      // A door or window arch on each storey.
      final win = g.band(
        d + eave + storey * .2,
        d + storey * .88,
        g.cx - w * .1,
        g.cx + w * .1,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(win, Radius.circular(w * .1)),
        Paint()..color = k.isEven ? _mix(_ink, _redShade, .3) : _gold,
      );
      // The eave: a tiled roof whose corners sweep up into hooked tips.
      final e0 = g.y(d), e1 = g.y(d + eave);
      final curl = g.dir * eave * .7;
      c.drawPath(
        Path()
          ..moveTo(g.r.left, e0 + curl)
          ..quadraticBezierTo(g.r.left + w * .1, e1, g.r.left + w * .3, e1)
          ..lineTo(g.r.right - w * .3, e1)
          ..quadraticBezierTo(g.r.right - w * .1, e1, g.r.right, e0 + curl)
          ..lineTo(g.r.right, e0)
          ..lineTo(g.r.left, e0)
          ..close(),
        Paint()..color = roof,
      );
      Kit.fill(c, g.band(d, d + eave * .22), roofLit);
      Kit.fill(c, g.band(d + eave * .22, d + eave * .32), _gold);
      // Hooked ridge tips in gold.
      for (final x in [g.r.left + w * .06, g.r.right - w * .06]) {
        c.drawCircle(
          Offset(x, e0 + curl * .8),
          math.max(1.2, w * .045),
          Paint()..color = _gold,
        );
      }
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.china,
        Offset(g.cx, g.y(start + storey * .62)),
        w * .15,
        perfect: pass.perfect,
      );
    }
  }

  /// Great Wall brickwork. The rim is a parapet of merlons whose dark
  /// embrasures show the walkway beyond.
  static void _wall(Canvas c, Column g, int v, PassState pass) {
    final brick = [
      (
        const Color(0xffb9b4ab),
        const Color(0xff9a948a),
        const Color(0xff6f6a62),
      ),
      (
        const Color(0xffc2b19c),
        const Color(0xffa08f7a),
        const Color(0xff736452),
      ),
      (
        const Color(0xffaab0a8),
        const Color(0xff8a918a),
        const Color(0xff626862),
      ),
    ][v];
    Kit.volume(c, g.r, brick.$1, brick.$2, brick.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final parapet = math.min(w * .5, g.h - start);
    // Merlons with shadowed embrasures between them.
    final embrasure = _mix(brick.$3, _ink, .45);
    final n = 3;
    for (var i = 0; i < n; i++) {
      final x0 = g.r.left + w * (i + .62) / n,
          x1 = g.r.left + w * (i + 1) / n - w * .02;
      if (i == n - 1) continue;
      Kit.fill(
        c,
        g.band(start, start + parapet * .55, x0, x1 + w * .06),
        embrasure,
      );
    }
    Kit.fill(c, g.band(start + parapet - 2, start + parapet), brick.$3);
    // A loophole in the parapet.
    Kit.fill(
      c,
      g.band(
        start + parapet * .66,
        start + parapet * .88,
        g.cx - w * .05,
        g.cx + w * .05,
      ),
      embrasure,
    );
    final course = math.max(6.0, w * .16);
    final mortar = _mix(brick.$3, _cream, .25);
    var row = 0;
    for (var d = start + parapet; d < g.h; d += course, row++) {
      Kit.fill(c, g.band(d, d + 1), mortar);
      final len = w / 2.2;
      final offset = row.isOdd ? len / 2 : 0.0;
      for (var x = g.r.left - offset; x < g.r.right; x += len) {
        Kit.fill(c, g.band(d, d + course, x, x + 1), mortar);
      }
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.china,
        Offset(g.cx, g.y(start + parapet * .78)),
        math.min(w * .15, parapet * .22),
        perfect: pass.perfect,
      );
    }
  }

  /// A red silk lantern: ribbed, lit from inside, with gold caps.
  static void _silk(
    Canvas c,
    double r,
    int v,
    bool upper,
    PassState pass,
    double time,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    final silk = [_red, const Color(0xffd94a3a), const Color(0xffe0603f)][v];
    final flicker = .88 + .12 * math.sin(time * 2.6 + v);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, .05),
          colors: [
            _mix(silk, const Color(0xffffd07a), .55 * flicker),
            _mix(silk, _redLit, .2),
            silk,
            _mix(silk, _ink, .3),
          ],
          stops: const [0, .35, .75, 1],
        ).createShader(bounds),
    );
    // Vertical ribs bow outward like the lantern's frame.
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * .035)
      ..color = _mix(silk, _ink, .45).withValues(alpha: .6);
    for (final k in const [.25, .55, .85]) {
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2 * k, height: r * 1.9),
        rib,
      );
    }
    // Gold caps top and bottom with tassel roots.
    final cap = Paint()..color = _gold;
    for (final pole in const [-1.0, 1.0]) {
      c.drawRect(
        Rect.fromLTRB(-r, pole < 0 ? -r : r * .7, r, pole < 0 ? -r * .7 : r),
        cap,
      );
      c.drawRect(
        Rect.fromLTRB(
          -r,
          pole < 0 ? -r * .74 : r * .7,
          r,
          pole < 0 ? -r * .7 : r * .74,
        ),
        Paint()..color = _goldDeep,
      );
    }
    // A painted character-free good-luck knot motif.
    final knot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * .06)
      ..color = _gold;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * .6, height: r * .6),
        Radius.circular(r * .12),
      ),
      knot,
    );
    c.save();
    c.rotate(math.pi / 4);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * .5, height: r * .5),
        Radius.circular(r * .1),
      ),
      knot,
    );
    c.restore();
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-r * .45, -r * .25),
        width: r * .16,
        height: r * .36,
      ),
      Paint()..color = const Color(0x55ffffff),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.china,
        Offset.zero,
        r * .22,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, _goldDeep, _ink, pass, band: .08);
  }

  /// A round garden window: lacquer frame, paper glow and a turning lattice.
  static void _lattice(Canvas c, double r, int v, PassState pass, double spin) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xfffff6e0), Color(0xfff6dcb0)],
        ).createShader(bounds),
    );
    final wood = [_red, const Color(0xff5a3a2a), _jade][v];
    final bar = Paint()
      ..color = wood
      ..strokeWidth = math.max(1.6, r * .07)
      ..strokeCap = StrokeCap.square;
    c.save();
    c.rotate(spin);
    // A cracked-ice lattice: a square grid rotated in a diamond ring.
    for (var k = -2; k <= 2; k++) {
      c.drawLine(Offset(k * r * .3, -r), Offset(k * r * .3, r), bar);
      c.drawLine(Offset(-r, k * r * .3), Offset(r, k * r * .3), bar);
    }
    c.drawRect(
      Rect.fromCenter(center: Offset.zero, width: r * .5, height: r * .5),
      Paint()..color = _gold,
    );
    c.drawRect(
      Rect.fromCenter(center: Offset.zero, width: r * .28, height: r * .28),
      Paint()..color = wood,
    );
    c.restore();
    c.drawCircle(
      Offset.zero,
      r * .8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .14
        ..color = wood,
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.china,
        Offset.zero,
        r * .22,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, _gold, _ink, pass, band: .09);
  }
}
