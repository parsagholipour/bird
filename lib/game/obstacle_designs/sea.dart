import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../domain/obstacle.dart';
import '../regions/world_region.dart';
import 'kit.dart';

/// Sea obstacles: barnacled pier pilings bound with rope, coral pillars and
/// weed-hung rocks with starfish; a banded lighthouse whose lamp turns at
/// the rim; a coral column crowned by a swaying anemone; dock posts with a
/// painted depth marker pointing at the opening; wet harbour-wall stones; a
/// netted glass fishing float; and a brass compass.
abstract final class SeaObstacles {
  static const _ink = Color(0xff1b3a4a);
  static const _woodLit = Color(0xffcfc0a6), _wood = Color(0xffa39277);
  static const _woodShade = Color(0xff6d604f), _barnacle = Color(0xfff2ebdd);
  static const _weed = Color(0xff4f8f6a), _weedLit = Color(0xff7fbf8a);
  static const _rope = Color(0xffddbb80), _ropeDeep = Color(0xff9a7a48);
  static const _coral = Color(0xfff28b76), _coralLit = Color(0xffffb8a0);
  static const _coralDeep = Color(0xffc05a55), _red = Color(0xffd84a3a);
  static const _white = Color(0xfff8f3ea), _brass = Color(0xffd8a64a);

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
    final sway = reducedMotion ? 0.0 : math.sin(seconds * 1.4 + appearance);
    c.save();
    c.clipRect(r);
    switch (kind) {
      case ObstacleKind.windLift:
        _lighthouse(c, g, v, pass, Kit.spin(seconds, reducedMotion, 1.1));
      case ObstacleKind.petalGate:
        _anemone(c, g, v, pass, sway);
      case ObstacleKind.switchback:
        _dock(c, g, v, pass);
      case ObstacleKind.crystalSteps:
        _harbour(c, g, v, pass);
      default:
        _piling(c, g, v, pass, sway);
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
      _float(c, radius, v, upper, pass);
    } else {
      final swing = reducedMotion
          ? 0.0
          : math.sin(seconds * .9 + v) * .5 + seconds * .15;
      _compass(c, radius, v, pass, swing * (upper ? 1 : -1));
    }
  }

  static Color _mix(Color a, Color b, double t) => Kit.mix(a, b, t);

  /// A pier piling (weathered wood, rope and barnacles), a coral pillar, or
  /// a weed-hung rock with a starfish.
  static void _piling(Canvas c, Column g, int v, PassState pass, double sway) {
    final w = g.w;
    switch (v) {
      case 1:
        _coralBody(c, g);
      case 2:
        Kit.volume(
          c,
          g.r,
          const Color(0xff9aa3a8),
          const Color(0xff737d86),
          const Color(0xff4d5660),
        );
      default:
        Kit.volume(c, g.r, _woodLit, _wood, _woodShade);
    }
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    // A painted white cap band at the rim.
    final cap = math.min((w * .26).clamp(6.0, 14.0), g.h - start);
    Kit.fill(c, g.band(start, start + cap), v == 1 ? _coralLit : _white);
    Kit.fill(
      c,
      g.band(start + cap - 1.4, start + cap),
      _mix(_woodShade, _ink, .3),
    );
    final from = start + cap;
    if (v == 0) {
      // Grain, iron bands and rope lashings.
      final grain = Paint()
        ..color = _woodShade.withValues(alpha: .6)
        ..strokeWidth = math.max(.8, w * .02);
      for (var i = 1; i < 5; i++) {
        final x = g.r.left + w * i / 5 + (i.isEven ? 1 : -1);
        c.drawLine(Offset(x, g.y(from)), Offset(x + 1, g.y(g.h)), grain);
      }
      final lash = math.max(10.0, w * .3);
      for (var d = from + w * .5; d < g.h; d += math.max(60.0, w * 2)) {
        Kit.fill(c, g.band(d, d + lash), _rope);
        for (var t = .15; t < 1; t += .22) {
          c.drawLine(
            Offset(g.r.left, g.y(d + lash * t)),
            Offset(g.r.right, g.y(d + lash * (t + .15))),
            Paint()
              ..color = _ropeDeep
              ..strokeWidth = math.max(1.0, lash * .08),
          );
        }
      }
    }
    // Barnacles cluster and weed hangs below the tide line.
    final barnacle = Paint()..color = _barnacle;
    final shadow = Paint()..color = _mix(_woodShade, _ink, .2);
    for (var i = 0; i < 30; i++) {
      final d = from + 6 + i * math.max(7.0, w * .2);
      if (d > g.h) break;
      final x = g.r.left + w * (.12 + .76 * ((i * 53) % 17) / 16);
      final s = math.max(1.2, w * (.03 + .02 * (i % 3)));
      c.drawCircle(Offset(x, g.y(d)), s * 1.2, shadow);
      c.drawCircle(Offset(x, g.y(d)), s, barnacle);
    }
    final weed = Paint()
      ..color = _weed
      ..strokeWidth = math.max(1.6, w * .05)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final x = g.r.left + w * (.1 + i * .2);
      final len = w * (.5 + .3 * (i % 2));
      final d0 = from;
      c.drawPath(
        Path()
          ..moveTo(x, g.y(d0))
          ..quadraticBezierTo(
            x + sway * 3 + w * .06,
            g.y(d0 + len * .5),
            x + sway * 2,
            g.y(d0 + len),
          ),
        weed..color = i.isEven ? _weed : _weedLit,
      );
    }
    if (v == 2 && g.h > from + w) {
      _starfish(
        c,
        Offset(g.cx + w * .1, g.y(from + w * .7)),
        w * .2,
        const Color(0xffff9360),
      );
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.sea,
        Offset(g.cx, g.y(start + cap / 2)),
        math.min(cap * .45, w * .14),
        perfect: pass.perfect,
      );
    }
  }

  static void _coralBody(Canvas c, Column g) {
    Kit.volume(c, g.r, _coralLit, _coral, _coralDeep);
    // Branching coral texture: pocked polyps and pale ridges.
    final polyp = Paint()..color = _coralDeep.withValues(alpha: .6);
    final ridge = Paint()..color = _coralLit.withValues(alpha: .8);
    for (var i = 0; i < 60; i++) {
      final d = 6.0 + i * math.max(5.0, g.w * .12);
      if (d > g.h) break;
      final x = g.r.left + g.w * (.1 + .8 * ((i * 29) % 13) / 12);
      c.drawCircle(Offset(x, g.y(d)), math.max(1.0, g.w * .035), polyp);
      c.drawCircle(Offset(x - 1, g.y(d) - 1), math.max(.6, g.w * .015), ridge);
    }
  }

  static void _starfish(Canvas c, Offset at, double s, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5 + .2;
      final rad = s * (i.isEven ? 1.0 : .42);
      final p = at + Offset(math.cos(a), math.sin(a)) * rad;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    c.drawPath(path..close(), Paint()..color = color);
    c.drawCircle(at, s * .15, Paint()..color = _mix(color, _white, .5));
  }

  /// A banded lighthouse; its lamp room sits at the rim and the beam lens
  /// turns inside it.
  static void _lighthouse(
    Canvas c,
    Column g,
    int v,
    PassState pass,
    double spin,
  ) {
    final band = [_red, const Color(0xff2f5f9a), const Color(0xff2f7f5a)][v];
    Kit.volume(
      c,
      g.r,
      _white,
      const Color(0xffe9e2d6),
      const Color(0xffbdb3a2),
    );
    final w = g.w;
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final room = math.min(w * .9, g.h - start - 2);
    final lamp = room >= 16;
    final gallery = lamp ? math.min(6.0, w * .12) : 0.0;
    final from = start + (lamp ? room + gallery : 0);
    // Broad bands down the tower, with a small porthole on each white band.
    final pitch = math.max(26.0, w * .8);
    var k = 0;
    for (var d = from; d < g.h; d += pitch, k++) {
      Kit.volume(
        c,
        g.band(d + pitch * .5, d + pitch),
        _mix(band, _white, .3),
        band,
        _mix(band, _ink, .35),
      );
      if (k.isOdd) continue;
      final port = Offset(g.cx, g.y(d + pitch * .25));
      c.drawCircle(port, w * .07, Paint()..color = _ink);
      c.drawCircle(
        port,
        w * .05,
        Paint()
          ..color = k.isEven
              ? const Color(0xffffe08a)
              : const Color(0xff4a6a8a),
      );
    }
    if (!lamp) return;
    // Gallery railing.
    Kit.fill(
      c,
      g.band(start + room, start + room + gallery),
      const Color(0xff2f3342),
    );
    for (var x = g.r.left + 2; x < g.r.right; x += w * .12) {
      Kit.fill(
        c,
        g.band(start + room, start + room + gallery, x, x + 1.2),
        const Color(0xff6f7486),
      );
    }
    // Lamp room: dark glazing with a turning Fresnel lens and its glow.
    final glass = g.band(start, start + room);
    Kit.fill(c, glass, const Color(0xff243248));
    final center = Offset(g.cx, glass.center.dy);
    c.drawCircle(
      center,
      room * .5,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xfffff3c2), Color(0x00fff3c2)],
        ).createShader(Rect.fromCircle(center: center, radius: room * .5)),
    );
    // Lens panels sweep across as it turns.
    final face = math.cos(spin);
    final lensW = w * .5 * (.4 + .6 * face.abs());
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: lensW, height: room * .6),
        Radius.circular(w * .05),
      ),
      Paint()
        ..color = _mix(
          const Color(0xfffff0b0),
          const Color(0xffd8b050),
          1 - face.abs(),
        ),
    );
    for (var i = -1; i <= 1; i++) {
      c.drawLine(
        Offset(center.dx - lensW / 2, center.dy + i * room * .12),
        Offset(center.dx + lensW / 2, center.dy + i * room * .12),
        Paint()
          ..color = const Color(0x99b88a30)
          ..strokeWidth = 1,
      );
    }
    // Mullions of the lantern glazing.
    for (final fx in const [.2, .8]) {
      Kit.fill(
        c,
        g.band(
          start,
          start + room,
          g.r.left + w * fx - .8,
          g.r.left + w * fx + .8,
        ),
        const Color(0xff2f3342),
      );
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.sea,
        center,
        math.min(room * .22, w * .15),
        perfect: pass.perfect,
      );
    }
  }

  /// A coral column crowned with a swaying sea anemone.
  static void _anemone(Canvas c, Column g, int v, PassState pass, double sway) {
    final w = g.w;
    _coralBody(c, g);
    if (w < 12 || g.h < 10) return;
    final start = Kit.edgeDepth(g);
    final crown = math.min(w * .8, g.h - start - 4);
    if (crown < 10) return;
    final from = start + crown + 3;
    // Polyp scales on the column below the crown, pointing at the rim.
    final pitch = math.max(10.0, w * .2);
    var k = 0;
    for (var d = from; d < g.h + pitch; d += pitch, k++) {
      final per = 4;
      final cell = w / per;
      for (var i = 0; i < per + 1; i++) {
        final x = g.r.left + cell * i - (k.isOdd ? cell / 2 : 0);
        c.drawPath(
          Path()
            ..moveTo(x, g.y(d + pitch * 1.3))
            ..quadraticBezierTo(x, g.y(d), x + cell / 2, g.y(d))
            ..quadraticBezierTo(
              x + cell,
              g.y(d),
              x + cell,
              g.y(d + pitch * 1.3),
            )
            ..close(),
          Paint()..color = k.isEven ? _coralLit : _coral,
        );
        c.drawCircle(
          Offset(x + cell / 2, g.y(d + pitch * .5)),
          math.max(.8, cell * .1),
          Paint()..color = _coralDeep,
        );
      }
    }
    // The anemone: a dark well with tentacles waving toward the rim.
    final well = g.band(start, start + crown + 3);
    Kit.fill(c, well, const Color(0xff1f4f63));
    final tentacle = [
      const Color(0xffff9fc8),
      const Color(0xffb9f0a0),
      const Color(0xffffc27a),
    ][v];
    final base = g.y(start + crown);
    final stroke = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, w * .07);
    for (var i = 0; i < 9; i++) {
      final x = g.r.left + w * (i + .5) / 9;
      final lean = (i - 4) * w * .03 + sway * w * .06 * (i.isEven ? 1 : -1);
      final tip = Offset(x + lean, g.y(start + crown * (.12 + .1 * (i % 3))));
      c.drawPath(
        Path()
          ..moveTo(x, base)
          ..quadraticBezierTo(
            x - lean * .5,
            g.y(start + crown * .6),
            tip.dx,
            tip.dy,
          ),
        stroke..color = tentacle,
      );
      c.drawCircle(
        tip,
        stroke.strokeWidth * .75,
        Paint()..color = _mix(tentacle, _white, .5),
      );
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.sea,
        Offset(g.cx, g.y(start + crown * .55)),
        math.min(crown * .22, w * .15),
        perfect: pass.perfect,
      );
    }
  }

  /// A dock post with a painted depth scale; its arrow points at the
  /// opening and rope coils hang from a cleat.
  static void _dock(Canvas c, Column g, int v, PassState pass) {
    final tone = [
      (_woodLit, _wood, _woodShade),
      (
        const Color(0xffb9c4c2),
        const Color(0xff8f9c9c),
        const Color(0xff5f6c6e),
      ),
      (
        const Color(0xffd6b48a),
        const Color(0xffb08a5e),
        const Color(0xff7a5a3a),
      ),
    ][v];
    Kit.volume(c, g.r, tone.$1, tone.$2, tone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final plate = math.min(w * .7, g.h - start);
    Kit.fill(c, g.band(start, start + plate), _white);
    final arrow = pass.cleared
        ? (pass.perfect ? const Color(0xffe8b23a) : const Color(0xff3f9f78))
        : _red;
    c.drawPath(
      Kit.poly([
        g.cx, g.y(start + plate * .12), //
        g.cx + w * .26, g.y(start + plate * .5),
        g.cx + w * .09, g.y(start + plate * .5),
        g.cx + w * .09, g.y(start + plate * .88),
        g.cx - w * .09, g.y(start + plate * .88),
        g.cx - w * .09, g.y(start + plate * .5),
        g.cx - w * .26, g.y(start + plate * .5),
      ]),
      Paint()..color = arrow,
    );
    // Depth ticks down the post.
    final tick = Paint()
      ..color = _mix(tone.$3, _ink, .35)
      ..strokeWidth = math.max(1.0, w * .035);
    var k = 0;
    for (var d = start + plate + 6; d < g.h; d += math.max(9.0, w * .26), k++) {
      c.drawLine(
        Offset(g.r.left + w * .1, g.y(d)),
        Offset(g.r.left + w * (k % 4 == 0 ? .5 : .3), g.y(d)),
        tick,
      );
    }
    // A rope coil on a cleat.
    if (g.h > start + plate + w * 1.4) {
      final at = Offset(g.r.right - w * .3, g.y(start + plate + w * .9));
      c.drawCircle(
        at,
        w * .22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .08
          ..color = _rope,
      );
      c.drawCircle(
        at,
        w * .12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .06
          ..color = _ropeDeep,
      );
    }
    if (pass.cleared && g.h > start + plate + w * 2) {
      Kit.emblem(
        c,
        WorldRegion.sea,
        Offset(g.r.left + w * .3, g.y(start + plate + w * 1.6)),
        w * .15,
        perfect: pass.perfect,
      );
    }
  }

  /// Harbour-wall stones, dark and wet low down, with a band of weed.
  static void _harbour(Canvas c, Column g, int v, PassState pass) {
    final stone = [
      (
        const Color(0xffb8b4a8),
        const Color(0xff97928a),
        const Color(0xff6a665f),
      ),
      (
        const Color(0xffa9b3b3),
        const Color(0xff879293),
        const Color(0xff5b6566),
      ),
      (
        const Color(0xffc2b29a),
        const Color(0xff9e8e76),
        const Color(0xff6e6150),
      ),
    ][v];
    Kit.volume(c, g.r, stone.$1, stone.$2, stone.$3);
    final w = g.w;
    if (w < 10 || g.h < 8) return;
    final start = Kit.edgeDepth(g);
    final coping = math.min(w * .3, g.h - start);
    Kit.fill(c, g.band(start, start + coping), _mix(stone.$1, _white, .4));
    Kit.fill(c, g.band(start + coping - 1.5, start + coping), stone.$3);
    final course = math.max(14.0, w * .45);
    var row = 0;
    for (var d = start + coping; d < g.h; d += course, row++) {
      Kit.fill(c, g.band(d, d + 1.3), _mix(stone.$3, _ink, .3));
      final seam = g.r.left + w * (row.isOdd ? .4 : .72);
      Kit.fill(
        c,
        g.band(d, d + course, seam, seam + 1.3),
        _mix(stone.$3, _ink, .3),
      );
      // Stones darken and weed thickens deeper down.
      final wet = ((d - start) / 160).clamp(0.0, .45);
      Kit.fill(
        c,
        g.band(d + 1.3, d + course),
        _mix(stone.$3, const Color(0xff2a4f5a), .5).withValues(alpha: wet),
      );
      if (row % 3 == 1) {
        for (var i = 0; i < 4; i++) {
          final x = g.r.left + w * (.1 + i * .25);
          c.drawLine(
            Offset(x, g.y(d)),
            Offset(x + 2, g.y(d + course * .6)),
            Paint()
              ..color = _weed
              ..strokeWidth = math.max(1.4, w * .06)
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.sea,
        Offset(g.cx, g.y(start + coping / 2)),
        math.min(w * .15, coping * .35),
        perfect: pass.perfect,
      );
    }
  }

  /// A glass fishing float in a knotted rope net.
  static void _float(Canvas c, double r, int v, bool upper, PassState pass) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    final glass = [
      const Color(0xff6fc6a8),
      const Color(0xff6fa8d6),
      const Color(0xffa8d67a),
    ][v];
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.25, -.3),
          colors: [_mix(glass, _white, .6), glass, _mix(glass, _ink, .4)],
          stops: const [0, .55, 1],
        ).createShader(bounds),
    );
    // The net: a diamond mesh of rope with knots.
    final net = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * .06)
      ..color = _rope;
    final step = r * .5;
    for (var k = -4; k <= 4; k++) {
      c.drawLine(Offset(k * step - r, -r), Offset(k * step + r, r), net);
      c.drawLine(Offset(k * step + r, -r), Offset(k * step - r, r), net);
    }
    final knot = Paint()..color = _ropeDeep;
    for (var i = -3; i <= 3; i++) {
      for (var j = -3; j <= 3; j++) {
        if ((i + j).isOdd) continue;
        c.drawCircle(
          Offset(i * step / 2, j * step / 2),
          math.max(1.0, r * .05),
          knot,
        );
      }
    }
    final side = upper ? -1.0 : 1.0;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, side * r * .95),
        width: r * .9,
        height: r * .45,
      ),
      Paint()..color = _ropeDeep,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-r * .38, -r * .38),
        width: r * .34,
        height: r * .2,
      ),
      Paint()..color = const Color(0xbbffffff),
    );
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.sea,
        Offset.zero,
        r * .24,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, _mix(glass, _ink, .25), _ink, pass, band: .07);
  }

  /// A brass compass: the card swings slowly, north pointer in red.
  static void _compass(
    Canvas c,
    double r,
    int v,
    PassState pass,
    double swing,
  ) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    c.save();
    c.clipPath(Path()..addOval(bounds));
    c.drawCircle(Offset.zero, r, Paint()..color = const Color(0xfffbf4e2));
    c.drawCircle(
      Offset.zero,
      r * .82,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, r * .03)
        ..color = _mix(_brass, _ink, .3),
    );
    for (var i = 0; i < 32; i++) {
      final a = i * math.pi / 16;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        d * r * (i % 4 == 0 ? .66 : .74),
        d * r * .8,
        Paint()
          ..color = _ink.withValues(alpha: .7)
          ..strokeWidth = math.max(.7, r * (i % 4 == 0 ? .03 : .015)),
      );
    }
    c.save();
    c.rotate(swing);
    // Compass rose: long cardinal points over short intercardinals.
    final rose = [
      const Color(0xff2f5f8a),
      const Color(0xff2f7f6a),
      const Color(0xff5a3a6a),
    ][v];
    for (var i = 0; i < 8; i++) {
      final cardinal = i.isEven;
      final len = r * (cardinal ? .64 : .4);
      c.save();
      c.rotate(i * math.pi / 4);
      c.drawPath(
        Kit.poly([0, -len, r * .09, 0, 0, r * .05]),
        Paint()..color = cardinal ? rose : _mix(rose, _white, .45),
      );
      c.drawPath(
        Kit.poly([0, -len, -r * .09, 0, 0, r * .05]),
        Paint()
          ..color = cardinal ? _mix(rose, _white, .35) : _mix(rose, _white, .7),
      );
      c.restore();
    }
    c.drawPath(
      Kit.poly([0, -r * .7, r * .07, -r * .5, -r * .07, -r * .5]),
      Paint()..color = _red,
    );
    c.restore();
    c.drawCircle(Offset.zero, r * .08, Paint()..color = _brass);
    if (pass.cleared) {
      Kit.emblem(
        c,
        WorldRegion.sea,
        Offset(0, r * .36),
        r * .18,
        perfect: pass.perfect,
      );
    }
    c.restore();
    Kit.bezel(c, r, _brass, _ink, pass, band: .12);
  }
}
