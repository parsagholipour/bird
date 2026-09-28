import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Brazil on a bright beach day: Sugarloaf and the Corcovado with its
/// statue over a bay, hillsides of pastel houses, sailboats on a turquoise
/// sea, then a sandy beach with palms, striped umbrellas, a goal and
/// footballers juggling a ball. Gulls wheel, a hang glider drifts and
/// bougainvillea petals blow past.
class BrazilScene extends RegionScene {
  const BrazilScene();

  @override
  WorldRegion get region => WorldRegion.brazil;

  @override
  double get horizon => .62;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.78, .2),
    radius: .06,
    disc: Color(0xfffff6c8),
    glow: Color(0xffffe89a),
    halo: .5,
    strength: .45,
  );

  static final _weather = Weather(Weather.of([(Mote.petal, 10)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffd8f3f0);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xff8cc4cc),
      Color(0xff7ab6c2),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xff4fae6a),
      Color(0xff3f9a5c),
      Color(0xffa8e0a0),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xff3ac0d8),
      Color(0xff2a9fc4),
      Color(0xffe8fbff),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xfff6dfa4),
      Color(0xffe6c07a),
      Color(0xffffefc0),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .67,
    Depth.mid => .72 - .05 * Sketch.humps(x / 1.8 + .2),
    Depth.low => .79 + .004 * math.sin(x * math.pi * 4 + clock * 1.4),
    Depth.near => .915 - .012 * Sketch.humps(x / 1.5 + .4),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    Depth.mid => .24,
    Depth.low => .16,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  static const _pastel = [
    Color(0xffffa64a),
    Color(0xffe94f6a),
    Color(0xff4fc3d9),
    Color(0xfff6e26a),
    Color(0xff8ed36a),
    Color(0xfff28cc0),
  ];

  double _nearY(double x, double h) => ridge(Depth.near, x / h, 0) * h;

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        _sugarloaf(c, Offset(w * .3, h * .7), h * .3);
        _corcovado(c, Offset(w * .74, h * .7), h * .38);
      case Depth.mid:
        // Rounded green headlands behind the beach.
        for (final (fx, fw, top) in const [(.1, .3, .6), (.55, .4, .62), (.92, .3, .58)]) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(w * fx, h * .74),
              width: h * fw * 2,
              height: h * (.74 - top) * 2,
            ),
            Paint()..color = _hazed(const Color(0xff3f9a5c), .18),
          );
        }
      case Depth.low:
        for (final (fx, s) in const [(.22, 1.0), (.7, .7)]) {
          final x = span * fx;
          _sailboat(c, Offset(x, ridge(d, x / h, 0) * h + h * .004), h * .06 * s);
        }
        _island(c, Offset(span * .5, ridge(d, span * .5 / h, 0) * h + h * .01), h * .1);
      case Depth.near:
        for (final (fx, s, lean) in const [(.08, 1.0, .1), (.72, .85, -.12)]) {
          final x = span * fx;
          Sketch.palm(
            c,
            Offset(x, _nearY(x, h) + h * .01),
            h * .34 * s,
            lean: lean,
            trunk: const Color(0xff9a7448),
            trunkShade: const Color(0xff6f4f30),
            frond: const Color(0xff2f8f4a),
            frondLit: const Color(0xff5fc26a),
          );
        }
        for (final (fx, i) in const [(.32, 0), (.9, 1)]) {
          final x = span * fx;
          _umbrella(c, Offset(x, _nearY(x, h) + h * .012), h * .12, i);
        }
        _goal(c, Offset(span * .58, _nearY(span * .58, h) + h * .01), h * .16);
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.near) return;
    final h = f.h, span = period(d) * h;
    final s = h * .085;
    final ax = span * .4, bx = span * .5;
    final ay = _nearY(ax, h) + h * .006, by = _nearY(bx, h) + h * .006;
    final gx = span * .58 + h * .02;
    final gy = _nearY(gx, h) + h * .006;
    // Two players juggle a ball between them.
    final cycle = f.clock / 1.6;
    final t = cycle - cycle.floorToDouble();
    final leg = math.sin(t * math.pi * 2);
    _player(c, Offset(ax, ay), s, const Color(0xffffdc2e), const Color(0xff2f5fd0), const Color(0xff8a5a3a), leg, true);
    _player(c, Offset(bx, by), s * .95, const Color(0xff2f8f4a), const Color(0xfff6f1e2), const Color(0xffc48a5a), -leg, false);
    final forward = cycle.floor().isEven ? t : 1 - t;
    final ball = Offset(
      ax + (bx - ax) * forward,
      ay - s * .18 - math.sin(t * math.pi) * s * .7,
    );
    _ball(c, ball, s * .09, f.clock * 5);
    // A keeper paces his line.
    final sway = math.sin(f.clock * 1.4) * h * .015;
    _player(c, Offset(gx + sway, gy), s * .85, const Color(0xffe0523a), const Color(0xff26303a), const Color(0xff6f4a30), math.sin(f.clock * 5) * .5, false);
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.mid:
        // Pastel houses climb the hillsides.
        for (var i = 0; i < 46; i++) {
          final x = (f.w + h * .6) * Sketch.hash(i + 400) - h * .3;
          final y = (ridge(Depth.mid, x / h, 0) + .012 + .05 * Sketch.hash(i + 401)) * h;
          final s = h * (.014 + .01 * Sketch.hash(i + 402));
          final color = _pastel[i % _pastel.length];
          c.drawRect(
            Rect.fromLTWH(x, y - s, s * 1.2, s),
            Paint()..color = Sketch.fade(_hazed(color, .1), presence),
          );
          c.drawRect(
            Rect.fromLTWH(x, y - s * 1.12, s * 1.2, s * .14),
            Paint()..color = Sketch.fade(const Color(0xff9a5a3a), .85 * presence),
          );
          c.drawRect(
            Rect.fromLTWH(x + s * .45, y - s * .5, s * .3, s * .5),
            Paint()..color = Sketch.fade(const Color(0xff3a3040), .7 * presence),
          );
        }
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .68), width: f.w * 1.3, height: h * .08),
          const Color(0xffeafaf8),
          .7 * presence,
        );
      case Depth.low:
        // Foam lines roll in across the bay.
        final foam = Paint()
          ..color = Sketch.fade(const Color(0xffffffff), .5 * presence)
          ..strokeWidth = h * .003
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 9; i++) {
          final x = (f.w + h) * Sketch.hash(i + 430) - h * .4;
          final y = h * (.81 + .05 * Sketch.hash(i + 431));
          final phase = math.sin(f.clock * 1.2 + i * 1.9);
          c.drawLine(Offset(x, y), Offset(x + h * (.03 + .015 * phase), y), foam);
        }
      case Depth.near:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .004;
    for (var i = 0; i < 9; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.7 + i * 1.9);
      glint.color = Sketch.fade(const Color(0xfffffce0), .7 * on * presence);
      final y = h * (.8 + i * .008);
      final x = f.w * light.at.dx + math.sin(i * 2.3) * h * .02;
      final len = h * (.05 - i * .003) * (.6 + .4 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    for (final (fx, fy, fw) in const [(.2, .2, .5), (.6, .13, .42), (.9, .32, .3)]) {
      final x = (w * fx - f.clock * h * .008) % (w + h * 1.2) - h * .6;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .06),
        const Color(0xffffffff),
        .8 * presence,
      );
    }
    for (var i = 0; i < 3; i++) {
      final x = (w * .3 + i * h * .07 - f.clock * h * .02) % (w + h * .5) - h * .2;
      Sketch.bird(
        c,
        Offset(x, h * (.26 + .03 * i) + math.sin(f.clock + i) * h * .01),
        h * .012,
        Sketch.fade(const Color(0xfff6fbff), .9 * presence),
        flap: math.sin(f.clock * 3 + i) * .5,
      );
    }
    // A hang glider drifts down the coast.
    final gx = (w * .5 - f.clock * h * .008) % (w + h) - h * .3;
    final gy = h * .3 + math.sin(f.clock * .3) * h * .015;
    c.drawPath(
      Sketch.poly([gx - h * .035, gy + h * .01, gx, gy - h * .012, gx + h * .035, gy + h * .01, gx, gy + h * .004]),
      Paint()..color = Sketch.fade(const Color(0xffe94f6a), presence),
    );
    c.drawLine(
      Offset(gx, gy + h * .005),
      Offset(gx, gy + h * .022),
      Paint()
        ..color = Sketch.fade(const Color(0xff26303a), presence)
        ..strokeWidth = h * .002,
    );
  }

  static void _sugarloaf(Canvas c, Offset base, double s) {
    final body = _hazed(const Color(0xff5f8f88), .3);
    final lit = _hazed(const Color(0xff8fb8ae), .3);
    final path = Path()
      ..moveTo(base.dx - s * .34, base.dy)
      ..cubicTo(base.dx - s * .36, base.dy - s * .6, base.dx - s * .2, base.dy - s * .95, base.dx + s * .02, base.dy - s * .96)
      ..cubicTo(base.dx + s * .22, base.dy - s * .95, base.dx + s * .3, base.dy - s * .5, base.dx + s * .36, base.dy)
      ..close();
    c.drawPath(path, Paint()..color = body);
    c.drawPath(
      Path()
        ..moveTo(base.dx - s * .34, base.dy)
        ..cubicTo(base.dx - s * .36, base.dy - s * .6, base.dx - s * .2, base.dy - s * .95, base.dx + s * .02, base.dy - s * .96)
        ..cubicTo(base.dx - s * .1, base.dy - s * .6, base.dx - s * .16, base.dy - s * .3, base.dx - s * .12, base.dy)
        ..close(),
      Paint()..color = lit,
    );
    // Its smaller neighbour and the cable car line between them.
    c.drawOval(
      Rect.fromCenter(center: Offset(base.dx + s * .9, base.dy), width: s * 1.1, height: s * .7),
      Paint()..color = _hazed(const Color(0xff5f8f88), .4),
    );
    c.drawLine(
      Offset(base.dx + s * .02, base.dy - s * .94),
      Offset(base.dx + s * .9, base.dy - s * .34),
      Paint()
        ..color = _hazed(const Color(0xff3f5a5a), .3)
        ..strokeWidth = math.max(.6, s * .004),
    );
  }

  /// The Corcovado: a steep peak crowned by the statue with open arms.
  static void _corcovado(Canvas c, Offset base, double s) {
    final body = _hazed(const Color(0xff4f8a78), .3);
    final lit = _hazed(const Color(0xff7fb298), .28);
    c.drawPath(
      Sketch.poly([base.dx - s * .5, base.dy, base.dx - s * .1, base.dy - s * .7, base.dx + s * .06, base.dy - s * .72, base.dx + s * .5, base.dy]),
      Paint()..color = body,
    );
    c.drawPath(
      Sketch.poly([base.dx - s * .5, base.dy, base.dx - s * .1, base.dy - s * .7, base.dx, base.dy - s * .71, base.dx - s * .12, base.dy]),
      Paint()..color = lit,
    );
    final stone = Paint()..color = _hazed(const Color(0xfff6f6ee), .1);
    final top = Offset(base.dx - s * .02, base.dy - s * .71);
    final u = s * .16;
    c.drawPath(
      Sketch.poly([top.dx - u * .22, top.dy, top.dx + u * .22, top.dy, top.dx + u * .12, top.dy - u * .8, top.dx - u * .12, top.dy - u * .8]),
      stone,
    );
    c.drawRect(Rect.fromLTRB(top.dx - u * .6, top.dy - u * .78, top.dx + u * .6, top.dy - u * .68), stone);
    c.drawCircle(Offset(top.dx, top.dy - u * .9), u * .08, stone);
  }

  static void _sailboat(Canvas c, Offset base, double s) {
    c.drawPath(
      Sketch.poly([base.dx - s * .5, base.dy - s * .12, base.dx + s * .5, base.dy - s * .12, base.dx + s * .32, base.dy + s * .08, base.dx - s * .32, base.dy + s * .08]),
      Paint()..color = const Color(0xffe94f6a),
    );
    c.drawPath(
      Sketch.poly([base.dx, base.dy - s * 1.0, base.dx + s * .42, base.dy - s * .16, base.dx, base.dy - s * .16]),
      Paint()..color = const Color(0xfffffcf0),
    );
    c.drawPath(
      Sketch.poly([base.dx - s * .06, base.dy - s * .85, base.dx - s * .4, base.dy - s * .16, base.dx - s * .06, base.dy - s * .16]),
      Paint()..color = const Color(0xffffe08a),
    );
  }

  static void _island(Canvas c, Offset base, double s) {
    final body = _hazed(const Color(0xff4f8a78), .3);
    for (final (dx, top, half) in const [(-.35, .9, .3), (.3, .7, .26)]) {
      c.drawPath(
        Sketch.poly([base.dx + dx * s - half * s, base.dy, base.dx + dx * s - half * s * .2, base.dy - s * top, base.dx + dx * s + half * s * .2, base.dy - s * top, base.dx + dx * s + half * s, base.dy]),
        Paint()..color = body,
      );
    }
  }

  static void _umbrella(Canvas c, Offset base, double s, int i) {
    c.drawLine(
      base,
      Offset(base.dx + s * .04, base.dy - s),
      Paint()
        ..color = const Color(0xff7a5a3a)
        ..strokeWidth = math.max(1.0, s * .03),
    );
    final top = Offset(base.dx + s * .04, base.dy - s);
    final a = i.isEven ? const Color(0xffe94f6a) : const Color(0xff2fb5d8);
    for (var k = 0; k < 4; k++) {
      final x0 = top.dx - s * .5 + k * s * .25;
      c.drawPath(
        Sketch.poly([top.dx, top.dy - s * .16, x0, top.dy + s * .04, x0 + s * .25, top.dy + s * .04]),
        Paint()..color = k.isEven ? a : const Color(0xfffffcf0),
      );
    }
  }

  /// A football goal seen from the side: posts, crossbar and a net.
  static void _goal(Canvas c, Offset base, double s) {
    final net = Paint()
      ..color = const Color(0xffffffff).withValues(alpha: .55)
      ..strokeWidth = math.max(.6, s * .008);
    final w = s * 1.1, hgt = s * .7;
    for (var i = 1; i < 8; i++) {
      c.drawLine(Offset(base.dx + w * i / 8, base.dy - hgt), Offset(base.dx + w * i / 8, base.dy), net);
    }
    for (var i = 1; i < 5; i++) {
      c.drawLine(Offset(base.dx, base.dy - hgt * i / 5), Offset(base.dx + w, base.dy - hgt * i / 5), net);
    }
    final post = Paint()
      ..color = const Color(0xfffffcf0)
      ..strokeWidth = math.max(1.2, s * .03)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(base.dx, base.dy), Offset(base.dx, base.dy - hgt), post);
    c.drawLine(Offset(base.dx + w, base.dy), Offset(base.dx + w, base.dy - hgt), post);
    c.drawLine(Offset(base.dx, base.dy - hgt), Offset(base.dx + w, base.dy - hgt), post);
  }

  static void _ball(Canvas c, Offset at, double r, double spin) {
    c.drawCircle(at, r, Paint()..color = const Color(0xfffffcf0));
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(spin);
    c.drawPath(
      Sketch.poly([0, -r * .55, r * .52, -r * .17, r * .32, r * .45, -r * .32, r * .45, -r * .52, -r * .17]),
      Paint()..color = const Color(0xff26303a),
    );
    c.restore();
    c.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, r * .12)
        ..color = const Color(0xff26303a),
    );
  }

  /// A footballer seen from the side: head, jersey, shorts and swinging legs.
  static void _player(
    Canvas c,
    Offset feet,
    double s,
    Color jersey,
    Color shorts,
    Color skin,
    double swing,
    bool faceRight,
  ) {
    final dir = faceRight ? 1.0 : -1.0;
    final hip = feet + Offset(0, -s * .48);
    final leg = Paint()
      ..color = skin
      ..strokeWidth = math.max(1.2, s * .09)
      ..strokeCap = StrokeCap.round;
    c.drawLine(hip, feet + Offset(swing * s * .2 * dir, -s * .02), leg);
    c.drawLine(hip, feet + Offset(-swing * s * .16 * dir, -s * .02), leg);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(hip.dx - s * .13, hip.dy - s * .08, hip.dx + s * .13, hip.dy + s * .12),
        Radius.circular(s * .04),
      ),
      Paint()..color = shorts,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(hip.dx - s * .14, hip.dy - s * .42, hip.dx + s * .14, hip.dy - s * .06),
        Radius.circular(s * .05),
      ),
      Paint()..color = jersey,
    );
    c.drawLine(
      Offset(hip.dx, hip.dy - s * .36),
      Offset(hip.dx + dir * s * .18 - swing * s * .05, hip.dy - s * .16),
      leg..strokeWidth = math.max(1.0, s * .07),
    );
    c.drawCircle(Offset(hip.dx + dir * s * .01, hip.dy - s * .52), s * .09, Paint()..color = skin);
    c.drawArc(
      Rect.fromCircle(center: Offset(hip.dx + dir * s * .01, hip.dy - s * .54), radius: s * .09),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xff2a2020),
    );
  }
}
