import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Brazil on a bright beach day: Sugarloaf with its cable car and the
/// Corcovado with its statue over a bay, hillsides of pastel houses, a
/// jangada and a sailboat on a turquoise sea, then a sandy beach with palms,
/// striped umbrellas, a goal and footballers passing a ball. Gulls wheel, a
/// hang glider drifts, cloud gathers on the peak and bougainvillea petals
/// blow past.
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

  static Color _dim(Color c) => Sketch.mix(c, const Color(0xff000000), .16);

  /// Softened favela paints, one per house in turn.
  static const _pastel = [
    Color(0xffffb45e),
    Color(0xfff2758a),
    Color(0xff62cfe0),
    Color(0xfff7e88a),
    Color(0xffa4dc7c),
    Color(0xfff6a3cb),
    Color(0xfffff1dc),
  ];

  static const _navy = Color(0xff26303a);
  static const _cream = Color(0xfffffcf0);

  /// Seconds one pass of the ball takes.
  static const _pass = 1.3;

  /// Near-band layout, in viewport heights along the 3 h repeat.
  static const _palms = [(.25, 1.0, .1), (2.5, .85, -.12)];
  static const _umbrellas = [(.85, 0), (2.85, 1)];
  static const _goalAt = 1.95, _goalWide = .17;
  static const _passers = (1.3, 1.56);

  double _nearY(double x, double h) => ridge(Depth.near, x / h, 0) * h;

  /// Sugarloaf and Corcovado, scaled down on a narrow phone so both fit.
  static (Offset, double, Offset, double) _skyline(double w, double h) {
    final k = math.min(1.0, math.max(.72, w / h / 1.1));
    return (Offset(w * .3, h * .7), h * .3 * k, Offset(w * .76, h * .7), h * .38 * k);
  }

  /// The cable car line, from Sugarloaf's summit to its neighbour's.
  static (Offset, Offset) _cable(Offset base, double s) =>
      (Offset(base.dx + s * .02, base.dy - s * .94), Offset(base.dx + s * .9, base.dy - s * .34));

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _serra(c, w, h);
        final (sugar, sugarSize, corco, corcoSize) = _skyline(w, h);
        _sugarloaf(c, sugar, sugarSize);
        _corcovado(c, corco, corcoSize);
      case Depth.mid:
        _headlands(c, w, h);
      case Depth.low:
        _island(c, Offset(h * 1.5, ridge(d, 1.5, 0) * h + h * .01), h * .1);
        _island(c, Offset(h * 2.45, ridge(d, 2.45, 0) * h + h * .01), h * .05);
      case Depth.near:
        for (final (fx, s, lean) in _palms) {
          final x = h * fx;
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
        for (final (fx, i) in _umbrellas) {
          final x = h * fx;
          _umbrella(c, Offset(x, _nearY(x, h) + h * .012), h * .13, i);
        }
        final gx = h * _goalAt;
        _goal(c, Offset(gx, _nearY(gx, h) + h * .004), h * _goalWide);
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        // Two cable cars pass on Sugarloaf's line.
        final (sugar, sugarSize, _, _) = _skyline(f.w, h);
        final (from, to) = _cable(sugar, sugarSize);
        final u = .5 + .5 * math.sin(f.clock * .25);
        _gondola(c, Offset.lerp(from, to, u)!, sugarSize);
        _gondola(c, Offset.lerp(from, to, 1 - u)!, sugarSize);
      case Depth.low:
        // Boats ride the same swell the water ridge draws.
        for (final (fx, s, raft) in const [(.65, 1.0, false), (2.15, .85, true), (2.75, .45, false)]) {
          final y = ridge(d, fx, f.clock) * h + h * .004;
          final slope = (ridge(d, fx + .02, f.clock) - ridge(d, fx - .02, f.clock)) / .04;
          c.save();
          c.translate(h * fx, y);
          c.rotate(math.atan(slope));
          if (raft) {
            _jangada(c, h * .06 * s);
          } else {
            _sailboat(c, h * .06 * s);
          }
          c.restore();
        }
      case Depth.near:
        _match(c, f);
      case Depth.mid:
        break;
    }
  }

  /// Two players pass a ball to each other while the keeper shuffles.
  void _match(Canvas c, SceneFrame f) {
    final h = f.h, s = h * .072;
    double footY(double x) => _nearY(x, h) - h * .002;
    final ax = h * _passers.$1, bx = h * _passers.$2;
    final ay = footY(ax), by = footY(bx);
    // Reduced Motion (clock 0) freezes the ball in mid-air.
    final p = (f.clock / _pass + .55) % 2.0;
    final q = p - p.floorToDouble();
    final aKicks = p < 1;
    final ballR = s * .11;
    final aFoot = Offset(ax + s * .34, ay - ballR);
    final bFoot = Offset(bx - s * .34, by - ballR);
    final e = math.min(1.0, math.max(0.0, (q - .12) / .88));
    final ball = Offset.lerp(aKicks ? aFoot : bFoot, aKicks ? bFoot : aFoot, e)! -
        Offset(0, math.sin(e * math.pi) * s * .8);
    final kickA = _kick(p), kickB = _kick((p + 1) % 2.0);
    _player(c, Offset(ax, ay), s, _yellowKit, faceRight: true, kick: kickA, arm: .3 - kickA * .6);
    _player(c, Offset(bx, by), s * .96, _blueKit, faceRight: false, kick: kickB, arm: .3 - kickB * .6);
    _ball(c, ball, ballR, f.clock * 6);
    // The keeper paces his line and spreads his gloves.
    final goalW = h * _goalWide;
    final kx = h * _goalAt + goalW * (.5 + .22 * math.sin(f.clock * 1.3));
    _player(c, Offset(kx, footY(kx)), s * .96, _keeperKit, faceRight: false, arm: 2.3, stance: .2, keeper: true);
  }

  /// Leg swing of a kick, -1 wound back to 1 through the ball; [r] counts
  /// the two-pass cycle from the moment this player's foot meets the ball.
  static double _kick(double r) {
    if (r < .12) return -1 + 2 * r / .12;
    if (r < .4) return 1 - (r - .12) / .28;
    if (r > 1.7) return -(r - 1.7) / .3;
    return 0;
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .68), width: f.w * 1.3, height: h * .08),
          const Color(0xffeafaf8),
          .7 * presence,
        );
        // Cloud gathers on the Corcovado's flank, as it does over Rio.
        final (_, _, corco, corcoSize) = _skyline(f.w, h);
        Sketch.mist(
          c,
          Rect.fromCenter(
            center: Offset(corco.dx + math.sin(f.clock * .2) * h * .05, corco.dy - corcoSize * .5),
            width: corcoSize * 1.1,
            height: corcoSize * .07,
          ),
          const Color(0xffffffff),
          .55 * presence,
        );
      case Depth.low:
        // Foam lines roll in across the bay.
        final span = period(d) * h;
        final foam = Paint()
          ..color = Sketch.fade(const Color(0xffffffff), .5 * presence)
          ..strokeWidth = h * .003
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 14; i++) {
          final phase = math.sin(f.clock * 1.2 + i * 1.9);
          final x = span * Sketch.hash(i + 430) + math.sin(f.clock * .5 + i) * h * .01;
          final y = h * (.81 + .09 * Sketch.hash(i + 431));
          c.drawLine(Offset(x, y), Offset(x + h * (.03 + .015 * phase), y), foam);
        }
      case Depth.near:
        _shore(c, f, presence);
        // Towels and sunbathers in the shade of the umbrellas.
        for (final (fx, i) in _umbrellas) {
          final x = h * fx - h * .045, y = _nearY(h * fx, h) + h * .022;
          final towel = i.isEven ? const Color(0xffe94f6a) : const Color(0xff2fb5d8);
          c.drawRRect(
            RRect.fromLTRBR(x, y, x + h * .1, y + h * .013, Radius.circular(h * .002)),
            Paint()..color = Sketch.fade(towel, presence),
          );
          c.drawRRect(
            RRect.fromLTRBR(x + h * .02, y - h * .005, x + h * .085, y + h * .003, Radius.circular(h * .004)),
            Paint()..color = Sketch.fade(i.isEven ? const Color(0xfff6e26a) : _cream, presence),
          );
          c.drawCircle(
            Offset(x + h * .016, y - h * .001),
            h * .006,
            Paint()..color = Sketch.fade(i.isEven ? const Color(0xffc48a5a) : const Color(0xff8a5a3a), presence),
          );
        }
      case Depth.mid:
        break;
    }
  }

  /// Surf lapping the sand: a foam line that breathes along the shore.
  void _shore(Canvas c, SceneFrame f, double presence) {
    final h = f.h, span = period(Depth.near) * h;
    final step = h * .05;
    final path = Path();
    for (var x = 0.0; x <= span + step; x += step) {
      final swell = .5 + .5 * math.sin(f.clock * 1.3 + x / h * math.pi * 4);
      final y = _nearY(x, h) - h * (.003 + .004 * swell);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = h * .004
        ..color = Sketch.fade(const Color(0xffffffff), .7 * presence),
    );
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
      // The sun's path widens toward the viewer.
      final y = h * (.805 + i * .01);
      final x = f.w * light.at.dx + math.sin(i * 2.3) * h * .02;
      final len = h * (.02 + i * .004) * (.6 + .4 * on);
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
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy - h * .006), width: h * fw * 1.1, height: h * .04),
        const Color(0xffffffff),
        .7 * presence,
      );
    }
    for (var i = 0; i < 3; i++) {
      final x = (w * .3 + i * h * .07 - f.clock * h * .02) % (w + h * .5) - h * .2;
      Sketch.bird(
        c,
        Offset(x, h * (.26 + .03 * i) + math.sin(f.clock + i) * h * .01),
        h * .016,
        Sketch.fade(const Color(0xfff6fbff), .9 * presence),
        flap: math.sin(f.clock * 3 + i) * .5,
      );
    }
    _hangGlider(c, w, h, f.clock, presence);
  }

  /// A hang glider drifts down the coast, its pilot slung beneath.
  static void _hangGlider(Canvas c, double w, double h, double clock, double presence) {
    final gx = (w * .5 - clock * h * .008) % (w + h) - h * .3;
    final gy = h * .3 + math.sin(clock * .3) * h * .015;
    final wing = h * .036;
    c.drawPath(
      Sketch.poly([gx - wing, gy + h * .01, gx, gy - h * .012, gx, gy + h * .004]),
      Paint()..color = Sketch.fade(const Color(0xffe94f6a), presence),
    );
    c.drawPath(
      Sketch.poly([gx, gy - h * .012, gx + wing, gy + h * .01, gx, gy + h * .004]),
      Paint()..color = Sketch.fade(const Color(0xfffff6ee), presence),
    );
    final pilot = Paint()
      ..color = Sketch.fade(_navy, presence)
      ..strokeWidth = math.max(.8, h * .002)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(gx, gy + h * .004), Offset(gx, gy + h * .02), pilot);
    c.drawCircle(Offset(gx, gy + h * .0225), h * .0025, pilot);
  }

  /// The Serra do Mar: a haze-blue ridge behind the famous peaks. It runs
  /// well past the right edge so the slow drift never uncovers a gap.
  static void _serra(Canvas c, double w, double h) {
    final path = Path()..moveTo(-h * .2, h * .7);
    for (var x = -h * .2; x <= w + h * 1.6; x += h * .05) {
      final y = h * (.625 - .022 * Sketch.peaks(x / (h * .9) + .2) - .014 * Sketch.peaks(x / (h * .37) + .6));
      path.lineTo(x, y);
    }
    path
      ..lineTo(w + h * 1.6, h * .7)
      ..close();
    c.drawPath(path, Paint()..color = _hazed(const Color(0xff6fa39a), .55));
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
    final (from, to) = _cable(base, s);
    c.drawLine(
      from,
      to,
      Paint()
        ..color = _hazed(const Color(0xff3f5a5a), .3)
        ..strokeWidth = math.max(.6, s * .004),
    );
  }

  static void _gondola(Canvas c, Offset at, double s) {
    final car = Rect.fromCenter(center: at + Offset(0, s * .025), width: s * .05, height: s * .035);
    c.drawLine(
      at,
      at + Offset(0, s * .012),
      Paint()
        ..color = _hazed(const Color(0xff3f5a5a), .3)
        ..strokeWidth = math.max(.6, s * .004),
    );
    c.drawRect(car, Paint()..color = _hazed(const Color(0xffe94f6a), .2));
  }

  /// The Corcovado: a steep peak crowned by the statue with open arms.
  static void _corcovado(Canvas c, Offset base, double s) {
    final body = _hazed(const Color(0xff4f8a78), .3);
    final lit = _hazed(const Color(0xff7fb298), .28);
    c.drawPath(
      Path()
        ..moveTo(base.dx - s * .52, base.dy)
        ..cubicTo(base.dx - s * .3, base.dy - s * .2, base.dx - s * .16, base.dy - s * .6, base.dx - s * .06, base.dy - s * .71)
        ..lineTo(base.dx + s * .03, base.dy - s * .72)
        ..cubicTo(base.dx + s * .16, base.dy - s * .55, base.dx + s * .3, base.dy - s * .2, base.dx + s * .52, base.dy)
        ..close(),
      Paint()..color = body,
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx - s * .52, base.dy)
        ..cubicTo(base.dx - s * .3, base.dy - s * .2, base.dx - s * .16, base.dy - s * .6, base.dx - s * .06, base.dy - s * .71)
        ..lineTo(base.dx - s * .01, base.dy - s * .715)
        ..cubicTo(base.dx - s * .1, base.dy - s * .5, base.dx - s * .14, base.dy - s * .25, base.dx - s * .1, base.dy)
        ..close(),
      Paint()..color = lit,
    );
    // The statue: pedestal, robe, outstretched arms and head.
    final stone = Paint()..color = _hazed(const Color(0xfff6f6ee), .08);
    final top = Offset(base.dx - s * .015, base.dy - s * .715);
    final u = s * .18;
    c.drawRect(Rect.fromLTRB(top.dx - u * .17, top.dy - u * .26, top.dx + u * .17, top.dy), stone);
    c.drawPath(
      Sketch.poly([top.dx - u * .13, top.dy - u * .26, top.dx + u * .13, top.dy - u * .26, top.dx + u * .08, top.dy - u * .86, top.dx - u * .08, top.dy - u * .86]),
      stone,
    );
    c.drawPath(
      Sketch.poly([top.dx - u * .62, top.dy - u * .8, top.dx + u * .62, top.dy - u * .8, top.dx + u * .62, top.dy - u * .72, top.dx - u * .62, top.dy - u * .72]),
      stone,
    );
    c.drawCircle(Offset(top.dx, top.dy - u * .94), u * .07, stone);
  }

  static void _sailboat(Canvas c, double s) {
    c.drawPath(
      Sketch.poly([-s * .5, -s * .12, s * .5, -s * .12, s * .32, s * .08, -s * .32, s * .08]),
      Paint()..color = const Color(0xffe94f6a),
    );
    c.drawRect(Rect.fromLTRB(-s * .46, -s * .12, s * .46, -s * .08), Paint()..color = _cream);
    c.drawPath(
      Sketch.poly([0, -s * 1.0, s * .42, -s * .16, 0, -s * .16]),
      Paint()..color = _cream,
    );
    c.drawPath(
      Sketch.poly([-s * .06, -s * .85, -s * .4, -s * .16, -s * .06, -s * .16]),
      Paint()..color = const Color(0xffbfe6f2),
    );
  }

  /// A jangada, the sailing raft of the north-east coast: logs under one tall
  /// lateen sail.
  static void _jangada(Canvas c, double s) {
    c.drawPath(
      Sketch.poly([-s * .6, -s * .06, s * .6, -s * .1, s * .5, s * .06, -s * .5, s * .06]),
      Paint()..color = const Color(0xffc89a62),
    );
    c.drawLine(
      Offset(-s * .5, -s * .01),
      Offset(s * .5, -s * .02),
      Paint()
        ..color = const Color(0xff8a6540)
        ..strokeWidth = math.max(.6, s * .025),
    );
    c.drawLine(
      Offset(0, -s * .08),
      Offset(0, -s * 1.05),
      Paint()
        ..color = const Color(0xff7a5a3a)
        ..strokeWidth = math.max(.8, s * .03),
    );
    c.drawPath(
      Sketch.poly([s * .03, -s * 1.02, s * .52, -s * .14, -s * .3, -s * .14]),
      Paint()..color = const Color(0xfffff3dc),
    );
    c.drawPath(
      Sketch.poly([s * .02, -s * .62, s * .27, -s * .18, -s * .12, -s * .18]),
      Paint()..color = const Color(0xffffa64a),
    );
  }

  static void _island(Canvas c, Offset base, double s) {
    final body = _hazed(const Color(0xff4f8a78), .3);
    final lit = _hazed(const Color(0xff7fb298), .3);
    for (final (dx, top, half) in const [(-.35, .9, .3), (.3, .7, .26)]) {
      final x = base.dx + dx * s;
      final path = Path()
        ..moveTo(x - half * s, base.dy)
        ..cubicTo(x - half * s * .9, base.dy - s * top * .7, x - half * s * .4, base.dy - s * top, x, base.dy - s * top)
        ..cubicTo(x + half * s * .4, base.dy - s * top, x + half * s * .9, base.dy - s * top * .6, x + half * s, base.dy)
        ..close();
      c.drawPath(path, Paint()..color = body);
      c.drawPath(
        Path()
          ..moveTo(x - half * s, base.dy)
          ..cubicTo(x - half * s * .9, base.dy - s * top * .7, x - half * s * .4, base.dy - s * top, x, base.dy - s * top)
          ..cubicTo(x - half * s * .3, base.dy - s * top * .6, x - half * s * .4, base.dy - s * top * .25, x - half * s * .3, base.dy)
          ..close(),
        Paint()..color = lit,
      );
    }
  }

  /// Rounded green headlands behind the beach, with houses and trees
  /// stacked up their slopes. They run past the right edge so the slow
  /// drift never uncovers a gap.
  void _headlands(Canvas c, double w, double h) {
    const hills = [(.1, 0.0, .3, .6), (.55, 0.0, .4, .62), (.92, 0.0, .3, .58), (1.0, .35, .3, .61)];
    for (final (k, (fx, off, fw, top)) in hills.indexed) {
      final cx = w * fx + h * off, cy = h * .74;
      final a = h * fw, b = h * (.74 - top);
      c.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: a * 2, height: b * 2),
        Paint()..color = _hazed(const Color(0xff3f9a5c), .18),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(cx - a * .18, cy - b * .12), width: a * 1.4, height: b * 1.5),
        Paint()..color = _hazed(const Color(0xff5cb26e), .2),
      );
      double topAt(double u) => cy - b * math.sqrt(1 - u * u);
      for (var i = 0; i < 9; i++) {
        final seed = 500 + k * 100 + i;
        final u = (Sketch.hash(seed) * 2 - 1) * .8;
        final y = topAt(u) + (cy - topAt(u)) * (.15 + .6 * Sketch.hash(seed + 50));
        c.drawCircle(
          Offset(cx + u * a, y),
          h * (.011 + .008 * Sketch.hash(seed + 60)),
          Paint()..color = _hazed(const Color(0xff2f7f4c), .22),
        );
      }
      const rows = 6, cols = 5;
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < cols; col++) {
          final seed = 700 + k * 100 + row * cols + col;
          final u = -.82 + 1.64 * (col + .2 + .6 * Sketch.hash(seed)) / cols;
          final x = cx + u * a;
          final s = h * (.011 + .008 * Sketch.hash(seed + 200));
          final t = topAt(u);
          var y = t + (cy - t) * (.12 + .78 * (row + Sketch.hash(seed + 300)) / rows);
          // Keep at least half of each house above the crest.
          y = math.min(y, ridge(Depth.mid, x / h, 0) * h + s * .6);
          _house(c, Offset(x, y), s, _pastel[(seed + k) % _pastel.length]);
        }
      }
    }
  }

  static void _house(Canvas c, Offset base, double s, Color color) {
    c.drawRect(
      Rect.fromLTWH(base.dx - s * .6, base.dy - s, s * 1.2, s),
      Paint()..color = _hazed(color, .12),
    );
    c.drawRect(
      Rect.fromLTWH(base.dx - s * .68, base.dy - s * 1.14, s * 1.36, s * .16),
      Paint()..color = _hazed(const Color(0xffb0603a), .15),
    );
    c.drawRect(
      Rect.fromLTWH(base.dx - s * .12, base.dy - s * .62, s * .26, s * .38),
      Paint()..color = _hazed(const Color(0xff3a3040), .2),
    );
  }

  static void _umbrella(Canvas c, Offset base, double s, int i) {
    final top = Offset(base.dx + s * .04, base.dy - s);
    c.drawLine(
      base,
      top,
      Paint()
        ..color = const Color(0xff7a5a3a)
        ..strokeWidth = math.max(1.0, s * .03),
    );
    final a = i.isEven ? const Color(0xffe94f6a) : const Color(0xff2fb5d8);
    final apex = Offset(top.dx, top.dy - s * .2);
    // Five domed panels, alternating colour and cream.
    for (var k = 0; k < 5; k++) {
      final x0 = -s * .55 + k * s * .22, x1 = x0 + s * .22;
      c.drawPath(
        Path()
          ..moveTo(top.dx + x0, top.dy + s * .02)
          ..quadraticBezierTo(top.dx + x0 * .8, apex.dy + s * .03, apex.dx, apex.dy)
          ..quadraticBezierTo(top.dx + x1 * .8, apex.dy + s * .03, top.dx + x1, top.dy + s * .02)
          ..close(),
        Paint()..color = k.isEven ? a : _cream,
      );
    }
  }

  /// A football goal in three-quarter view: frame, roof and a net.
  static void _goal(Canvas c, Offset base, double s) {
    final w = s, hgt = s * .62;
    final o = Offset(s * .24, -s * .04);
    final f0 = base, f1 = base + Offset(w, 0);
    final t0 = base + Offset(0, -hgt), t1 = base + Offset(w, -hgt);
    final b0 = f0 + o, b1 = f1 + o, u0 = t0 + o, u1 = t1 + o;
    final sheet = Paint()..color = const Color(0xffffffff).withValues(alpha: .14);
    for (final quad in [
      [b0, b1, u1, u0],
      [f1, b1, u1, t1],
      [t0, t1, u1, u0],
    ]) {
      c.drawPath(Sketch.poly([for (final p in quad) ...[p.dx, p.dy]]), sheet);
    }
    final net = Paint()
      ..color = const Color(0xffffffff).withValues(alpha: .5)
      ..strokeWidth = math.max(.5, s * .006);
    for (var i = 1; i < 8; i++) {
      final k = i / 8;
      c.drawLine(Offset.lerp(b0, b1, k)!, Offset.lerp(u0, u1, k)!, net);
    }
    for (var i = 1; i < 5; i++) {
      final k = i / 5;
      c.drawLine(Offset.lerp(b0, u0, k)!, Offset.lerp(b1, u1, k)!, net);
      c.drawLine(Offset.lerp(f1, t1, k)!, Offset.lerp(b1, u1, k)!, net);
    }
    for (var i = 1; i < 5; i++) {
      final k = i / 5;
      c.drawLine(Offset.lerp(t0, u0, k)!, Offset.lerp(t1, u1, k)!, net);
    }
    final post = Paint()
      ..color = _cream
      ..strokeWidth = math.max(1.2, s * .03)
      ..strokeCap = StrokeCap.round;
    final back = Paint()
      ..color = _cream.withValues(alpha: .7)
      ..strokeWidth = math.max(.8, s * .018)
      ..strokeCap = StrokeCap.round;
    c.drawLine(b1, u1, back);
    c.drawLine(u0, u1, back);
    c.drawLine(t1, u1, back);
    c.drawLine(t0, u0, back);
    c.drawLine(f0, t0, post);
    c.drawLine(f1, t1, post);
    c.drawLine(t0, t1, post);
  }

  static void _ball(Canvas c, Offset at, double r, double spin) {
    c.drawCircle(at, r, Paint()..color = _cream);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(spin);
    c.drawPath(
      Sketch.poly([0, -r * .55, r * .52, -r * .17, r * .32, r * .45, -r * .32, r * .45, -r * .52, -r * .17]),
      Paint()..color = _navy,
    );
    c.restore();
    c.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, r * .12)
        ..color = _navy,
    );
  }

  static const _yellowKit = _Kit(
    Color(0xffffdc2e),
    Color(0xff2f5fd0),
    Color(0xfff6f1e2),
    Color(0xff8a5a3a),
    Color(0xff2a2020),
  );
  static const _blueKit = _Kit(
    Color(0xff4fa8e8),
    Color(0xfff6f1e2),
    Color(0xff2f5fd0),
    Color(0xffc48a5a),
    Color(0xff5a3a24),
  );
  static const _keeperKit = _Kit(
    Color(0xffff7a3a),
    Color(0xff26303a),
    Color(0xff26303a),
    Color(0xff6f4a30),
    Color(0xff2a2020),
  );

  /// A footballer seen from the side, about [s] tall. [kick] swings the near
  /// leg (-1 back, 1 through the ball), [arm] is the near arm's angle from
  /// hanging, [stance] spreads the legs and a [keeper] wears gloves and
  /// holds both arms up.
  static void _player(
    Canvas c,
    Offset feet,
    double s,
    _Kit kit, {
    required bool faceRight,
    double kick = 0,
    double arm = .3,
    double stance = .07,
    bool keeper = false,
  }) {
    final dir = faceRight ? 1.0 : -1.0;
    final hip = feet + Offset(0, -s * .48);
    final sh = hip + Offset(dir * s * .03, -s * .26);
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Far limbs first, in shade.
    _leg(c, line, hip, s, dir, -stance, -stance, kit, true);
    _arm(c, line, sh + Offset(0, s * .03), s, dir, keeper ? -2.3 : -arm - .1, kit, true, keeper);
    final thigh = kick * .6 + stance;
    _leg(c, line, hip, s, dir, thigh, kick < 0 ? kick * 1.5 + stance : kick * .9 + stance, kit, false);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(hip.dx - s * .14, hip.dy - s * .05, hip.dx + s * .14, hip.dy + s * .14),
        Radius.circular(s * .04),
      ),
      fill..color = kit.shorts,
    );
    fill.color = kit.jersey;
    c.drawPath(
      Sketch.poly([hip.dx - s * .125, hip.dy, hip.dx + s * .125, hip.dy, sh.dx + s * .125, sh.dy, sh.dx - s * .125, sh.dy]),
      fill,
    );
    c.drawCircle(sh, s * .125, fill);
    _arm(c, line, sh + Offset(0, s * .03), s, dir, keeper ? 2.3 : arm, kit, false, keeper);
    final head = sh + Offset(dir * s * .03, -s * .2);
    c.drawCircle(head, s * .085, fill..color = kit.skin);
    c.drawArc(
      Rect.fromCircle(center: head, radius: s * .09),
      math.pi,
      math.pi,
      true,
      fill..color = kit.hair,
    );
    c.drawCircle(head + Offset(-dir * s * .06, s * .005), s * .04, fill);
  }

  /// A two-part leg: thigh, then shin, with a sock and a boot. Angles are
  /// radians from hanging straight down, positive toward [dir].
  static void _leg(
    Canvas c,
    Paint line,
    Offset hip,
    double s,
    double dir,
    double thigh,
    double shin,
    _Kit kit,
    bool shade,
  ) {
    final knee = hip + Offset(dir * math.sin(thigh), math.cos(thigh)) * (s * .24);
    final foot = knee + Offset(dir * math.sin(shin), math.cos(shin)) * (s * .24);
    final mid = Offset.lerp(knee, foot, .4)!;
    line
      ..strokeWidth = math.max(1.2, s * .1)
      ..color = shade ? _dim(kit.skin) : kit.skin;
    c.drawLine(hip, knee, line);
    c.drawLine(knee, mid, line);
    line
      ..strokeWidth = math.max(1.2, s * .09)
      ..color = shade ? _dim(kit.socks) : kit.socks;
    c.drawLine(mid, foot, line);
    line
      ..strokeWidth = math.max(1.0, s * .07)
      ..color = shade ? _navy : const Color(0xff141a20);
    c.drawLine(foot, foot + Offset(dir * s * .07, 0), line);
  }

  /// An arm hanging from [root] at angle [a] (radians from down, positive
  /// forward): a short sleeve, or full sleeve and glove for a keeper.
  static void _arm(
    Canvas c,
    Paint line,
    Offset root,
    double s,
    double dir,
    double a,
    _Kit kit,
    bool shade,
    bool keeper,
  ) {
    final hand = root + Offset(dir * math.sin(a), math.cos(a)) * (s * .3);
    final elbow = Offset.lerp(root, hand, keeper ? 1 : .38)!;
    line
      ..strokeWidth = math.max(1.0, s * .07)
      ..color = shade ? _dim(kit.skin) : kit.skin;
    c.drawLine(root, hand, line);
    line
      ..strokeWidth = math.max(1.2, s * .09)
      ..color = shade ? _dim(kit.jersey) : kit.jersey;
    c.drawLine(root, elbow, line);
    if (keeper) {
      c.drawCircle(hand, s * .05, Paint()..color = shade ? _dim(_cream) : _cream);
    }
  }
}

/// The colours a footballer wears.
class _Kit {
  const _Kit(this.jersey, this.shorts, this.socks, this.skin, this.hair);
  final Color jersey, shorts, socks, skin, hair;
}
