import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';

/// Jungle obstacles: vine-wrapped hardwood posts under a rope-lashed
/// crossbeam; a timber lift post with a turning pulley wheel; a column of
/// overlapping banana leaves around a turning hibiscus; lashed bamboo poles
/// with carved arrow notches; mossy temple stones split by roots; a woven
/// rattan ball full of fireflies; and a passionflower wheel.
abstract final class JungleObstacles {
  static const _ink = Color(0xff243a22);
  static const _woodLit = Color(0xffc58f5e), _wood = Color(0xff9c6a42);
  static const _woodShade = Color(0xff6c4629), _groove = Color(0xff553520);
  static const _vine = Color(0xff3f8a3a), _leaf = Color(0xff4fa556);
  static const _leafLit = Color(0xff8fd07a), _leafDeep = Color(0xff2d6a38);
  static const _rope = Color(0xffd2ad72), _ropeDeep = Color(0xff8c6a3a);
  static const _moss = Color(0xff86b45a), _red = Color(0xffe8503f);
  static const _yellow = Color(0xfff6c94a);

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
    final sway = reducedMotion
        ? 0.0
        : math.sin(seconds * 1.2 + appearance) * 1.6;
    c.save();
    c.clipRect(r);
    switch (kind) {
      case ObstacleKind.windLift:
        _pulley(c, g, v, pass, Kit.spin(seconds, reducedMotion, .9, v * .4));
      case ObstacleKind.petalGate:
        _leaves(c, g, v, pass, Kit.spin(seconds, reducedMotion, .3), sway);
      case ObstacleKind.switchback:
        _bamboo(c, g, v, pass, sway);
      case ObstacleKind.crystalSteps:
        _ruin(c, g, v, pass);
      default:
        _post(c, g, v, pass, sway);
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
      _rattan(c, radius, v, upper, pass, reducedMotion ? 0 : seconds);
    } else {
      _passionflower(
        c,
        radius,
        v,
        pass,
        Kit.spin(seconds, reducedMotion, upper ? .38 : -.38),
      );
    }
  }

  static Color _mix(Color a, Color b, double t) => Kit.mix(a, b, t);

  /// A lashed crossbeam at the rim: a round log bound with rope.
  static double _beam(Canvas c, Column g, PassState pass) {
    final start = Kit.edgeDepth(g);
    final depth = math.min((g.w * .22).clamp(6.0, 14.0), g.h - start);
    if (depth <= 0) return start;
    final band = g.band(start, start + depth);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [_woodLit, _wood, _woodShade],
        ).createShader(band),
    );
    // Log ends and rope wraps.
    final wrap = math.min(g.w * .2, depth * 1.2);
    for (final fx in const [.24, .76]) {
      final x = g.r.left + g.w * fx;
      final b = g.band(
        start - 1,
        start + depth + 1,
        x - wrap / 2,
        x + wrap / 2,
      );
      Kit.fill(c, b, _rope);
      for (var t = .2; t < 1; t += .27) {
        c.drawLine(
          Offset(b.left + b.width * t, b.bottom),
          Offset(b.left + b.width * (t + .18), b.top),
          Paint()
            ..color = _ropeDeep
            ..strokeWidth = math.max(1.0, depth * .1),
        );
      }
    }
    if (pass.cleared && depth >= 6) {
      Kit.emblem(
        c,
        WorldRegion.jungle,
        Offset(g.cx, g.y(start + depth / 2)),
        depth * .42,
        perfect: pass.perfect,
      );
    }
    return start + depth;
  }

  /// A hardwood post: grooved bark, moss and a climbing vine.
  static void _post(Canvas c, Column g, int v, PassState pass, double sway) {
    final w = g.w;
    if (v == 2) {
      _bundle(c, g, pass);
      return;
    }
    Kit.volume(c, g.r, _woodLit, _wood, _woodShade);
    if (w < 10 || g.h < 8) return;
    final from = _beam(c, g, pass);
    // Bark grooves or, for the strangler fig, braided root strands.
    final groove = Paint()
      ..color = _groove.withValues(alpha: .7)
      ..strokeWidth = math.max(1.0, w * .025);
    final strands = v == 1 ? 5 : 4;
    for (var i = 0; i < strands; i++) {
      final x = g.r.left + w * (i + .5) / strands;
      final path = Path()..moveTo(x, g.y(from));
      for (var d = from; d < g.h + 20; d += 14) {
        final wobble = v == 1
            ? math.sin(d * .09 + i * 1.7) * w * .08
            : math.sin(d * .05 + i) * w * .02;
        path.lineTo(x + wobble, g.y(d));
      }
      c.drawPath(path, groove..style = PaintingStyle.stroke);
    }
    if (v == 1) {
      Kit.fill(
        c,
        g.band(from, g.h, g.r.left + w * .1, g.r.left + w * .2),
        _woodLit.withValues(alpha: .5),
      );
    }
    // A vine spirals around the post, sprouting heart-shaped leaves.
    final vine = Paint()
      ..color = _vine
      ..strokeWidth = math.max(2.0, w * .06)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final turn = math.max(40.0, w * 1.3);
    final path = Path()..moveTo(g.r.left, g.y(from + 4));
    for (var d = from + 4; d < g.h + turn; d += 4) {
      final phase = (d - from) / turn * math.pi * 2;
      path.lineTo(g.cx + math.sin(phase) * w * .48, g.y(d));
    }
    c.drawPath(path, vine);
    var k = 0;
    for (var d = from + turn * .15; d < g.h + turn; d += turn * .5, k++) {
      final phase = (d - from - 4) / turn * math.pi * 2;
      final at = Offset(g.cx + math.sin(phase) * w * .48, g.y(d));
      _leafAt(
        c,
        at,
        w * .2,
        (k.isEven ? -.6 : 3.7) + sway * .05,
        k.isEven ? _leafLit : _leaf,
      );
    }
    // Moss clings to the shaded side.
    final moss = Paint()..color = _moss.withValues(alpha: .8);
    for (var d = from + 10; d < g.h; d += math.max(30.0, w)) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(g.r.right - w * .12, g.y(d)),
          width: w * .22,
          height: w * .3,
        ),
        moss,
      );
    }
  }

  static void _leafAt(
    Canvas c,
    Offset at,
    double s,
    double angle,
    Color color,
  ) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(s * .3, -s * .55, s * 1.05, -s * .35, s * 1.1, 0)
        ..cubicTo(s * 1.05, s * .35, s * .3, s * .55, 0, 0)
        ..close(),
      Paint()..color = color,
    );
    c.drawLine(
      Offset.zero,
      Offset(s * .9, 0),
      Paint()
        ..color = _leafDeep
        ..strokeWidth = math.max(.7, s * .06),
    );
    c.restore();
  }

  /// Three lashed bamboo culms, as a third post style.
  static void _bundle(Canvas c, Column g, PassState pass) {
    final w = g.w;
    Kit.fill(c, g.r, _leafDeep);
    if (w < 10 || g.h < 8) return;
    final from = _beam(c, g, pass);
    final culm = (w - 4) / 3;
    const cane = Color(0xffc9c566),
        caneLit = Color(0xffeae59a),
        caneDeep = Color(0xff8e9a44);
    for (var i = 0; i < 3; i++) {
      final left = g.r.left + 1 + i * (culm + 1);
      Kit.volume(
        c,
        g.band(from, g.h, left, left + culm),
        caneLit,
        cane,
        caneDeep,
      );
      for (var d = from + 12 + i * 9; d < g.h; d += math.max(26.0, w * .8)) {
        Kit.fill(c, g.band(d, d + 2, left, left + culm), caneDeep);
        Kit.fill(c, g.band(d + 2, d + 3, left, left + culm), caneLit);
      }
    }
  }

  /// A timber lift post with a pulley wheel turning at the rim.
  static void _pulley(Canvas c, Column g, int v, PassState pass, double spin) {
    Kit.volume(c, g.r, _woodLit, _wood, _woodShade);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min((w - 6) / 2, (g.h - start - 4) / 2);
    final wheel = radius >= 9;
    final from = wheel ? start + radius * 2 + 6 : start;
    // Plank cladding with pegs.
    final plank = math.max(10.0, w * .28);
    var k = 0;
    for (var d = from; d < g.h; d += plank, k++) {
      Kit.fill(c, g.band(d, d + 1.2), _groove);
      Kit.fill(c, g.band(d + 1.2, d + 2.4), _woodLit.withValues(alpha: .6));
      if (k.isEven) {
        c.drawCircle(
          Offset(g.r.left + w * .18, g.y(d + plank / 2)),
          math.max(1.0, w * .03),
          Paint()..color = _groove,
        );
        c.drawCircle(
          Offset(g.r.right - w * .18, g.y(d + plank / 2)),
          math.max(1.0, w * .03),
          Paint()..color = _groove,
        );
      }
    }
    // The hauling rope runs down one side.
    Kit.fill(
      c,
      g.band(from, g.h, g.r.right - w * .2, g.r.right - w * .12),
      _rope,
    );
    if (!wheel) return;
    Kit.fill(c, g.band(start, from), _mix(_leafDeep, _ink, .3));
    final hub = Offset(g.cx, g.y(start + radius + 3));
    c.drawCircle(hub, radius * .9, Paint()..color = _woodShade);
    c.drawCircle(hub, radius * .78, Paint()..color = _wood);
    c.drawCircle(
      hub,
      radius * .84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .1
        ..color = _rope,
    );
    final spoke = Paint()
      ..color = _woodLit
      ..strokeWidth = math.max(2.0, radius * .14)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = spin + i * math.pi / 2;
      c.drawLine(
        hub,
        hub + Offset(math.cos(a), math.sin(a)) * radius * .7,
        spoke,
      );
    }
    c.drawCircle(hub, radius * .2, Paint()..color = v == 1 ? _red : _groove);
    c.drawCircle(
      hub + Offset(-radius * .05, -radius * .05),
      radius * .07,
      Paint()..color = _woodLit,
    );
    // A few leaves tucked into the bracket.
    _leafAt(
      c,
      Offset(g.r.left + 2, g.y(start + radius * 1.6)),
      w * .2,
      g.top ? .6 : -.6,
      _leaf,
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.jungle,
        hub,
        radius * .32,
        perfect: pass.perfect,
      );
    }
  }

  /// Overlapping banana leaves point at the rim around a turning hibiscus.
  static void _leaves(
    Canvas c,
    Column g,
    int v,
    PassState pass,
    double spin,
    double sway,
  ) {
    Kit.fill(c, g.r, _leafDeep);
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final radius = math.min(w * .4, (g.h - start - 6) * .42);
    final bloom = radius >= 6;
    final from = bloom ? start + radius * 2 + 7 : start;
    final pitch = math.max(16.0, w * .34);
    final shades = [
      [_leaf, _mix(_leaf, _leafLit, .5)],
      [_mix(_leaf, const Color(0xff6fb04a), .5), _leafLit],
      [_mix(_leaf, _leafDeep, .3), _leaf],
    ][v];
    var k = 0;
    for (var d = from; d < g.h + pitch * 2; d += pitch, k++) {
      final left = k.isEven;
      final flutter = k == 0 ? sway : 0.0;
      final tip = Offset(g.cx + (left ? -w * .1 : w * .1) + flutter, g.y(d));
      final base = g.y(d + pitch * 2.2);
      final leaf = Path()
        ..moveTo(g.r.left - 2, base)
        ..quadraticBezierTo(g.r.left - 2, g.y(d + pitch * .5), tip.dx, tip.dy)
        ..quadraticBezierTo(
          g.r.right + 2,
          g.y(d + pitch * .5),
          g.r.right + 2,
          base,
        )
        ..close();
      c.drawPath(leaf, Paint()..color = shades[k % 2]);
      // Midrib and the fine parallel veins of a banana leaf.
      c.drawLine(
        tip,
        Offset(g.cx, base),
        Paint()
          ..color = _mix(shades[k % 2], const Color(0xfff0f6c0), .5)
          ..strokeWidth = math.max(1.0, w * .03),
      );
      final vein = Paint()
        ..color = _leafDeep.withValues(alpha: .35)
        ..strokeWidth = math.max(.6, w * .012);
      for (var t = .25; t < 1; t += .22) {
        final y = g.y(d + pitch * 2.2 * t);
        c.drawLine(
          Offset(g.cx, y),
          Offset(g.r.left + w * .05, y + g.dir * pitch * .5),
          vein,
        );
        c.drawLine(
          Offset(g.cx, y),
          Offset(g.r.right - w * .05, y + g.dir * pitch * .5),
          vein,
        );
      }
    }
    if (!bloom) return;
    Kit.fill(c, g.band(start, from), _mix(_leafDeep, _ink, .35));
    final hub = Offset(g.cx, g.y(start + radius + 3.5));
    final petal = [_red, const Color(0xfff27a45), const Color(0xffe85a8a)][v];
    c.save();
    c.translate(hub.dx, hub.dy);
    c.rotate(spin);
    for (var i = 0; i < 5; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / 5);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(
            -radius * .62,
            -radius * .3,
            -radius * .5,
            -radius * 1.02,
            0,
            -radius * .92,
          )
          ..cubicTo(
            radius * .5,
            -radius * 1.02,
            radius * .62,
            -radius * .3,
            0,
            0,
          )
          ..close(),
        Paint()..color = petal,
      );
      c.drawLine(
        Offset.zero,
        Offset(0, -radius * .6),
        Paint()
          ..color = _mix(petal, const Color(0xff7a1a2a), .5)
          ..strokeWidth = math.max(.8, radius * .05),
      );
      c.restore();
    }
    c.restore();
    c.drawCircle(hub, radius * .2, Paint()..color = const Color(0xff9e2a45));
    c.drawLine(
      hub,
      hub + Offset(radius * .55, -radius * .5),
      Paint()
        ..color = _yellow
        ..strokeWidth = math.max(1.2, radius * .08)
        ..strokeCap = StrokeCap.round,
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.jungle,
        hub,
        radius * .3,
        perfect: pass.perfect,
      );
    }
  }

  /// A lashed bamboo pole: nodes, rope bindings and notches that point at
  /// the opening, with moss hanging from the bindings.
  static void _bamboo(Canvas c, Column g, int v, PassState pass, double sway) {
    const cane = Color(0xffcfc56a),
        caneLit = Color(0xfff0e8a4),
        caneDeep = Color(0xff8f9a45);
    final tone = [
      cane,
      _mix(cane, const Color(0xff9fbf5a), .5),
      _mix(cane, const Color(0xffd9a85a), .45),
    ][v];
    Kit.volume(c, g.r, caneLit, tone, caneDeep);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // A rope collar at the rim with a carved arrow notch below it.
    final collar = math.min(w * .4, g.h - start);
    Kit.fill(c, g.band(start, start + collar), _rope);
    for (var t = .1; t < 1; t += .2) {
      c.drawLine(
        Offset(g.r.left, g.y(start + collar * t)),
        Offset(g.r.right, g.y(start + collar * (t + .12))),
        Paint()
          ..color = _ropeDeep
          ..strokeWidth = math.max(1.0, collar * .06),
      );
    }
    final pitch = math.max(24.0, w * .9);
    var k = 0;
    for (var d = start + collar; d < g.h; d += pitch, k++) {
      Kit.fill(c, g.band(d + pitch - 3, d + pitch - 1), caneDeep);
      Kit.fill(c, g.band(d + pitch - 1, d + pitch), caneLit);
      // Carved chevron notches point toward the opening.
      final notch = Path()
        ..moveTo(g.r.left + w * .28, g.y(d + pitch * .62))
        ..lineTo(g.cx, g.y(d + pitch * .34))
        ..lineTo(g.r.right - w * .28, g.y(d + pitch * .62));
      c.drawPath(
        notch,
        Paint()
          ..color = pass.cleared
              ? (pass.perfect ? const Color(0xffffc93f) : _leafLit)
              : _mix(caneDeep, _ink, .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.6, w * .07)
          ..strokeJoin = StrokeJoin.round,
      );
    }
    // Moss beards trail from the collar.
    final moss = Paint()
      ..color = _moss
      ..strokeWidth = math.max(1.0, w * .04)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = g.r.left + w * (.2 + i * .2);
      final len = w * (.3 + .2 * (i % 2));
      c.drawLine(
        Offset(x, g.y(start + collar)),
        Offset(x + sway * .5, g.y(start + collar + len)),
        moss,
      );
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.jungle,
        Offset(g.cx, g.y(start + collar * .5)),
        math.min(w * .16, collar * .3),
        perfect: pass.perfect,
      );
    }
  }

  /// Mossy temple stones, roots prying between the courses.
  static void _ruin(Canvas c, Column g, int v, PassState pass) {
    final stone = [
      (
        const Color(0xffc3c1a6),
        const Color(0xffa3a288),
        const Color(0xff75755e),
      ),
      (
        const Color(0xffbdb8a0),
        const Color(0xff9c937a),
        const Color(0xff6f6752),
      ),
      (
        const Color(0xffb0bba5),
        const Color(0xff8f9c86),
        const Color(0xff66735f),
      ),
    ][v];
    Kit.volume(c, g.r, stone.$1, stone.$2, stone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // A carved spiral block at the rim.
    final block = math.min(w * .7, g.h - start);
    Kit.fill(c, g.band(start, start + block), stone.$1);
    Kit.fill(c, g.band(start + block - 1.4, start + block), stone.$3);
    if (block > 12) {
      final at = Offset(g.cx, g.y(start + block / 2));
      final spiral = Path()..moveTo(at.dx, at.dy);
      for (var a = 0.0; a < math.pi * 4.2; a += .3) {
        final rr = block * .03 * a;
        spiral.lineTo(at.dx + math.cos(a) * rr, at.dy + math.sin(a) * rr);
      }
      c.drawPath(
        spiral,
        Paint()
          ..color = stone.$3
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, w * .04),
      );
    }
    final course = math.max(14.0, w * .5);
    var k = 0;
    for (var d = start + block; d < g.h; d += course, k++) {
      Kit.fill(c, g.band(d, d + 1.4), _mix(stone.$3, _ink, .3));
      // Moss drapes each ledge.
      final moss = Path()..moveTo(g.r.left, g.y(d + 1.4));
      for (var i = 0; i <= 6; i++) {
        final x = g.r.left + w * i / 6;
        moss.lineTo(x, g.y(d + 1.4 + (i.isEven ? 3.5 : 1.5) + (k % 2) * 2));
      }
      moss
        ..lineTo(g.r.right, g.y(d + 1.4))
        ..close();
      c.drawPath(moss, Paint()..color = _moss);
      final seam = g.r.left + w * (k.isOdd ? .38 : .7);
      Kit.fill(
        c,
        g.band(d, d + course, seam, seam + 1.3),
        _mix(stone.$3, _ink, .3),
      );
    }
    // A root snakes down the stones.
    final root = Path()..moveTo(g.r.left + w * .2, g.y(start + block));
    for (var d = start + block; d < g.h + 20; d += 10) {
      root.lineTo(g.r.left + w * (.2 + .08 * math.sin(d * .08)), g.y(d));
    }
    c.drawPath(
      root,
      Paint()
        ..color = _woodShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, w * .06),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.jungle,
        Offset(g.cx, g.y(start + block / 2)),
        math.min(w * .16, block * .3),
        perfect: pass.perfect,
      );
    }
  }

  /// A woven rattan ball, fireflies glowing through the weave.
  static void _rattan(
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
    c.drawCircle(Offset.zero, r, Paint()..color = const Color(0xff4a3622));
    c.drawCircle(
      Offset.zero,
      r * .95,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xfff2ffb0).withValues(alpha: .95),
            const Color(0xffc8f07a).withValues(alpha: .55),
            const Color(0x004a3622),
          ],
          stops: const [0, .5, 1],
        ).createShader(bounds),
    );
    // Fireflies drifting inside.
    for (var i = 0; i < 6; i++) {
      final a = time * (.6 + i * .1) + i * 1.9;
      final p = Offset(math.cos(a) * r * .45, math.sin(a * 1.3) * r * .4);
      final on = .6 + .4 * math.sin(time * 3 + i * 2);
      c.drawCircle(
        p,
        r * .13,
        Paint()..color = const Color(0xfff4ff9a).withValues(alpha: .45 * on),
      );
      c.drawCircle(
        p,
        r * .055,
        Paint()..color = const Color(0xfffcffd8).withValues(alpha: on),
      );
    }
    // The weave: curved cane strips over and under.
    const cane = Color(0xffd7ab6a), caneDeep = Color(0xff9a7442);
    final strip = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .09
      ..color = cane;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .03
      ..color = caneDeep;
    for (final k in const [-.62, 0.0, .62]) {
      final lat = Rect.fromCenter(
        center: Offset(0, k * r),
        width: r * 2 * math.sqrt(1 - k * k),
        height: r * .5 * (1 - k.abs()) + r * .1,
      );
      c.drawOval(lat, strip);
      c.drawOval(lat, edge);
      final lon = Rect.fromCenter(
        center: Offset(k * r * .7, 0),
        width: r * .7 * (1 - k.abs() * .6),
        height: r * 2,
      );
      c.drawOval(lon, strip);
      c.drawOval(lon, edge);
    }
    final side = upper ? -1.0 : 1.0;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, side * r * .95),
        width: r * .8,
        height: r * .4,
      ),
      Paint()..color = _leaf,
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.jungle,
        Offset.zero,
        r * .24,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(
      c,
      r,
      [cane, const Color(0xffc9a060), const Color(0xffb5c47a)][v],
      _ink,
      pass,
    );
  }

  /// A passionflower: white petals, a corona of banded filaments and a green
  /// crown of stigmas, turning slowly.
  static void _passionflower(
    Canvas c,
    double r,
    int v,
    PassState pass,
    double spin,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(Offset.zero, r, Paint()..color = _leafDeep);
    c.save();
    c.rotate(spin);
    final petal = [
      const Color(0xfff7f2fb),
      const Color(0xffd9c8f2),
      const Color(0xfffbe0ea),
    ][v];
    for (var i = 0; i < 10; i++) {
      c.save();
      c.rotate(i * math.pi / 5);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-r * .24, -r * .5, 0, -r * .84)
          ..quadraticBezierTo(r * .24, -r * .5, 0, 0)
          ..close(),
        Paint()
          ..color = i.isEven ? petal : _mix(petal, const Color(0xffb9a7e0), .3),
      );
      c.restore();
    }
    // Corona filaments: purple base, white band, violet tips.
    final filament = Paint()
      ..strokeWidth = math.max(.9, r * .035)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi * 2 / 36;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        d * r * .2,
        d * r * .34,
        filament..color = const Color(0xff5a2a7a),
      );
      c.drawLine(
        d * r * .34,
        d * r * .44,
        filament..color = const Color(0xfffaf6ff),
      );
      c.drawLine(
        d * r * .44,
        d * r * .6,
        filament..color = const Color(0xff7f5ac4),
      );
    }
    c.restore();
    c.drawCircle(Offset.zero, r * .2, Paint()..color = const Color(0xff8fc46a));
    for (var i = 0; i < 3; i++) {
      final a = spin + i * math.pi * 2 / 3;
      c.drawCircle(
        Offset(math.cos(a), math.sin(a)) * r * .12,
        r * .05,
        Paint()..color = const Color(0xff5a3a2a),
      );
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.jungle,
        Offset.zero,
        r * .22,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, _mix(_leaf, _leafLit, .3), _ink, pass);
  }
}
