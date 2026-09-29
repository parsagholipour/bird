import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Dubai on a bright, hazy morning: a glass skyline with the Burj Khalifa
/// stepping into the sky beside a gold frame and slanted towers, the sail of
/// the Burj Al Arab on its island in a turquoise gulf with a dhow crossing and
/// yachts at their moorings, and golden dunes with a camel caravan and date
/// palms. A hot-air balloon drifts by and sand streaks over the dunes.
class DubaiScene extends RegionScene {
  const DubaiScene();

  @override
  WorldRegion get region => WorldRegion.dubai;

  @override
  double get horizon => .62;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.16, .2),
    radius: .06,
    disc: Color(0xfffffbe8),
    glow: Color(0xffffeec0),
    halo: .5,
    strength: .5,
  );

  static final _weather = Weather(Weather.of([(Mote.sand, 12)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffe6dccb);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffd7d6cf),
      Color(0xffcfcbc0),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xffe4d2b0),
      Color(0xffd6bf98),
      Color(0xfffff0d0),
      rimWidth: .003,
    ),
    Depth.low => const Ground(
      Color(0xff35c1cf),
      Color(0xff2496b8),
      Color(0xffe6fbff),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xffeccb8f),
      Color(0xffd4a664),
      Color(0xfffff0c0),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far =>
      .68 + Sketch.waves(x, const [(2.6, .004, .3), (1.1, .002, 1.7)]),
    Depth.mid =>
      .75 + Sketch.waves(x, const [(2.2, .006, 1.0), (.9, .003, .2)]),
    Depth.low => .83 + .004 * math.sin(x * math.pi * 4 + clock * 1.3),
    Depth.near =>
      .925 - .035 * Sketch.humps(x / 3 + .1) - .012 * Sketch.humps(x + .3),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    Depth.mid => .34,
    Depth.low => .18,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  /// Where the Burj Khalifa stands on the mid band, and how tall it is.
  Offset _burjBase(double w, double h) =>
      Offset(w * .6, ridge(Depth.mid, w * .6 / h, 0) * h + h * .012);
  static double _burjHeight(double h) => h * .66;

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        // A haze-soft skyline running past both edges, so the drift never
        // leaves the right side bare.
        final paint = Paint()..color = _hazed(const Color(0xffaebdc9), .55);
        final lit = Paint()..color = _hazed(const Color(0xffc3d0da), .55);
        var x = -h * .05;
        var i = 0;
        while (x < w + h * .4) {
          final bw = h * (.025 + .03 * Sketch.hash(i + 500));
          final bh = h * (.05 + .12 * Sketch.hash(i + 501));
          final base = ridge(d, (x + bw / 2) / h, 0) * h + h * .02;
          final top = base - bh;
          c.drawRect(Rect.fromLTRB(x, top, x + bw, base), paint);
          c.drawRect(Rect.fromLTRB(x, top, x + bw * .38, base), lit);
          if (i % 5 == 1) {
            c.drawRect(
              Rect.fromLTRB(x + bw * .44, top - h * .035, x + bw * .56, top),
              paint,
            );
          } else if (i % 5 == 3) {
            c.drawRect(
              Rect.fromLTRB(x + bw * .2, top - h * .012, x + bw * .8, top),
              paint,
            );
          }
          x += bw + h * (.004 + .012 * Sketch.hash(i + 502));
          i++;
        }
      case Depth.mid:
        final bx = _burjBase(w, h).dx;
        final fs = h * .22, fx = math.max(w * .2, fs * .45);
        double base(double x) => ridge(d, x / h, 0) * h + h * .012;
        bool clear(double x) =>
            (x - bx).abs() > h * .13 && (x - fx).abs() > h * .14;
        // A paler back row first, then the front row, both running past the
        // right edge for the drift.
        var x = -h * .03;
        var i = 0;
        while (x < w + h * .5) {
          if (clear(x)) {
            _tower(
              c,
              x,
              base(x),
              h * (.032 + .02 * Sketch.hash(i + 540)),
              h * (.1 + .12 * Sketch.hash(i + 541)),
              (Sketch.hash(i + 543) * 4).floor(),
              .5,
            );
          }
          x += h * (.06 + .05 * Sketch.hash(i + 542));
          i++;
        }
        x = h * .02;
        i = 0;
        while (x < w + h * .5) {
          if (clear(x)) {
            // Towers rise toward the Burj, like a real downtown.
            final near = 1 - math.min(1.0, (x - bx).abs() / (h * .9));
            _tower(
              c,
              x,
              base(x),
              h * (.038 + .02 * Sketch.hash(i + 521)),
              h * (.14 + .2 * Sketch.hash(i + 522)) * (.8 + .35 * near),
              (Sketch.hash(i + 523) * 4).floor(),
              .2,
            );
          }
          x += h * (.075 + .05 * Sketch.hash(i + 520));
          i++;
        }
        // Small date palms line the waterfront.
        x = h * .1;
        i = 0;
        while (x < w + h * .5) {
          Sketch.palm(
            c,
            Offset(x, base(x)),
            h * (.06 + .02 * Sketch.hash(i + 560)),
            lean: (Sketch.hash(i + 562) - .5) * .2,
            trunk: _hazed(const Color(0xff8c6a44), .3),
            trunkShade: _hazed(const Color(0xff6f4f30), .3),
            frond: _hazed(const Color(0xff4f8f4a), .35),
            frondLit: _hazed(const Color(0xff86bf62), .35),
            detail: false,
          );
          x += h * (.3 + .25 * Sketch.hash(i + 561));
          i++;
        }
        _frame(c, Offset(fx, base(fx)), fs);
        _burj(c, _burjBase(w, h), _burjHeight(h));
      case Depth.low:
        // The Burj Al Arab on its island, with yachts at a marina mooring.
        final x = span * .55;
        final y = ridge(d, x / h, 0) * h;
        final sand = Paint()..color = const Color(0xffe6cf9c);
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: h * .4, height: h * .07),
          Paint()..color = const Color(0xfffff3d6).withValues(alpha: .7),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y - h * .002),
            width: h * .34,
            height: h * .05,
          ),
          sand,
        );
        _sail(c, Offset(x, y - h * .004), h * .3);
        for (final (fx, s) in const [(.84, 1.0), (.89, .72), (.93, .85)]) {
          final bx = span * fx;
          _yacht(c, Offset(bx, ridge(d, bx / h, 0) * h + h * .002), h * .036 * s);
        }
      case Depth.near:
        for (final (fx, s) in const [(.06, 1.0), (.78, .8)]) {
          final x = span * fx;
          Sketch.palm(
            c,
            Offset(x, ridge(d, x / h, 0) * h + h * .01),
            h * .3 * s,
            lean: fx < .5 ? .12 : -.1,
            trunk: const Color(0xff9a7448),
            trunkShade: const Color(0xff6f4f30),
            frond: const Color(0xff4f8f4a),
            frondLit: const Color(0xff86bf62),
            dates: true,
          );
        }
        for (var k = 0; k < 3; k++) {
          final x = span * (.32 + k * .048);
          _camel(c, Offset(x, ridge(d, x / h, 0) * h + h * .008), h * (.1 - k * .006), k);
        }
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    final h = f.h;
    if (d == Depth.mid) {
      // The Burj's aviation beacon pulses on its needle.
      final tip = _burjBase(f.w, h) - Offset(0, _burjHeight(h));
      final on = .5 + .5 * math.sin(f.clock * 2.4);
      c.drawCircle(tip, h * .012, Paint()..color = Sketch.fade(const Color(0xffff5a4a), .16 * on));
      c.drawCircle(tip, h * .0032, Paint()..color = Sketch.fade(const Color(0xffff7a6a), .35 + .55 * on));
      return;
    }
    if (d != Depth.low) return;
    final span = period(d) * h;
    // Wrapping inside the repeat hands the dhow to the next copy seamlessly.
    final x = (h * .4 + f.clock * h * .015) % span;
    final s = h * .05;
    c.save();
    c.translate(x, ridge(d, x / h, f.clock) * h + s * .12);
    c.rotate(math.sin(f.clock * 1.1 + copy) * .03);
    // Hull, deck stripe and a lateen sail on a slanted yard.
    c.drawPath(
      Sketch.poly([-s, -s * .42, s * 1.2, -s * .62, s * .75, s * .34, -s * .7, s * .34]),
      Paint()..color = const Color(0xff7a4a2a),
    );
    c.drawRect(
      Rect.fromLTRB(-s * .95, -s * .42, s * 1.15, -s * .34),
      Paint()..color = const Color(0xffd9a441),
    );
    c.drawPath(
      Sketch.poly([-s * .7, -s * .5, s * 1.0, -s * .6, s * .1, -s * 1.5]),
      Paint()..color = const Color(0xfffff6e0),
    );
    c.drawPath(
      Sketch.poly([s * .1, -s * 1.5, s * 1.0, -s * .6, s * .35, -s * .58]),
      Paint()..color = const Color(0xffe6d6b4),
    );
    c.restore();
  }

  static final _foam = Paint()..strokeCap = StrokeCap.round;
  static final _ripplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static double _rippleH = -1;
  static Path? _rippleCache;

  /// Slip-face ripples that follow the near dunes, built once per viewport.
  Path _ripples(double h) {
    final cached = _rippleCache;
    if (cached != null && _rippleH == h) return cached;
    final span = period(Depth.near) * h;
    final path = Path();
    for (var r = 0; r < 7; r++) {
      final x0 = span * Sketch.hash(700 + r);
      final len = h * (.16 + .2 * Sketch.hash(710 + r));
      final dy = h * (.014 + .03 * Sketch.hash(720 + r));
      for (var k = 0; k <= 8; k++) {
        final x = x0 + len * k / 8;
        final y = ridge(Depth.near, x / h, 0) * h + dy + math.sin(k / 8 * math.pi) * h * .004;
        if (k == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    _rippleH = h;
    return _rippleCache = path;
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5 + h * .2, h * .7), width: f.w * 1.3 + h, height: h * .09),
          const Color(0xfffff6e6),
          .8 * presence,
        );
      case Depth.mid:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5 + h * .2, h * .76), width: f.w * 1.3 + h, height: h * .1),
          const Color(0xfffff0d8),
          .6 * presence,
        );
      case Depth.low:
        final span = period(d) * h;
        _foam.strokeWidth = h * .003;
        for (var i = 0; i < 12; i++) {
          final x = span * Sketch.hash(i + 530);
          final y = h * (.845 + .045 * Sketch.hash(i + 531));
          final on = .6 + .4 * math.sin(f.clock * 1.3 + i * 2);
          _foam.color = Sketch.fade(const Color(0xffffffff), .45 * on * presence);
          c.drawLine(Offset(x, y), Offset(x + h * (.03 + .012 * math.sin(f.clock + i)), y), _foam);
        }
      case Depth.near:
        _ripplePaint
          ..strokeWidth = math.max(1.0, h * .003)
          ..color = Sketch.fade(const Color(0xffb98a48), .32 * presence);
        c.drawPath(_ripples(h), _ripplePaint);
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .004;
    for (var i = 0; i < 8; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.5 + i * 1.9);
      glint.color = Sketch.fade(const Color(0xffffffe8), .65 * on * presence);
      final y = h * (.835 + i * .008);
      final x = f.w * light.at.dx + math.sin(i * 2.3) * h * .02;
      final len = h * (.05 - i * .004) * (.6 + .4 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  static const _gores = [
    Color(0xffe94f6a),
    Color(0xfffff6e0),
    Color(0xff2fb5d8),
    Color(0xfffff6e0),
  ];

  /// A hot-air balloon envelope in unit radius, centred on the origin.
  static final _envelope = Path()
    ..moveTo(-.3, 1.45)
    ..cubicTo(-1.3, .75, -1.15, -1.05, 0, -1.05)
    ..cubicTo(1.15, -1.05, 1.3, .75, .3, 1.45)
    ..close();

  static final _skyPaint = Paint();

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // Warm glare behind the skyline where the sun burns off the morning haze.
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(w * .3, h * horizon), width: w * 1.6 + h, height: h * .16),
      const Color(0xfffff0d0),
      .5 * presence,
    );
    for (final (fx, fy, fw) in const [(.3, .18, .5), (.8, .3, .35), (.55, .1, .3)]) {
      final x = (w * fx - f.clock * h * .006) % (w + h * 1.2) - h * .6;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .03),
        const Color(0xfffffaf0),
        .55 * presence,
      );
    }
    // A hot-air balloon drifts across, swaying under its envelope.
    final bx = (w * .45 + f.clock * h * .006) % (w + h * .4) - h * .1;
    final by = h * .3 + math.sin(f.clock * .4) * h * .012;
    final r = h * .034;
    c.save();
    c.translate(bx, by);
    c.rotate(math.sin(f.clock * .5) * .04);
    c.scale(r, r);
    c.save();
    c.clipPath(_envelope);
    for (var i = 0; i < 6; i++) {
      _skyPaint.color = Sketch.fade(_gores[i % 4], presence);
      c.drawRect(Rect.fromLTWH(-1.3 + i * .44, -1.1, .44, 2.6), _skyPaint);
    }
    _skyPaint.color = Sketch.fade(const Color(0xffffffff), .22 * presence);
    c.drawOval(Rect.fromCenter(center: const Offset(-.45, -.3), width: .7, height: 1.3), _skyPaint);
    c.restore();
    _skyPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / r
      ..color = Sketch.fade(const Color(0xff7a4a2a), presence);
    c.drawLine(const Offset(-.3, 1.45), const Offset(-.15, 1.85), _skyPaint);
    c.drawLine(const Offset(.3, 1.45), const Offset(.15, 1.85), _skyPaint);
    _skyPaint.style = PaintingStyle.fill;
    c.drawRect(const Rect.fromLTWH(-.17, 1.85, .34, .26), _skyPaint);
    c.restore();
  }

  /// The Burj Khalifa: a Y-shaped tower stepping in tiers to a slim spire.
  static void _burj(Canvas c, Offset base, double s) {
    final body = _hazed(const Color(0xffb9cfe0), .18);
    final lit = _hazed(const Color(0xffe4f0fa), .15);
    final shade = _hazed(const Color(0xff8fa9c2), .18);
    // Half width and top of each setback, in tower heights.
    const steps = [
      (.11, .05),
      (.085, .2),
      (.07, .33),
      (.056, .46),
      (.043, .58),
      (.032, .68),
      (.022, .76),
      (.014, .82),
      (.006, .93),
    ];
    final right = <Offset>[];
    var from = 0.0;
    final shape = Path()..moveTo(base.dx - steps.first.$1 * s, base.dy);
    for (final (half, top) in steps) {
      shape
        ..lineTo(base.dx - half * s, base.dy - from * s)
        ..lineTo(base.dx - half * s, base.dy - top * s);
      right
        ..add(Offset(base.dx + half * s, base.dy - top * s))
        ..add(Offset(base.dx + half * s, base.dy - from * s));
      from = top;
    }
    shape.lineTo(base.dx, base.dy - s);
    for (final p in right.reversed) {
      shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    c.drawPath(shape, Paint()..color = body);
    c.save();
    c.clipPath(shape);
    c.drawRect(Rect.fromLTRB(base.dx - .12 * s, base.dy - s, base.dx - .012 * s, base.dy), Paint()..color = lit);
    c.drawRect(Rect.fromLTRB(base.dx + .03 * s, base.dy - s, base.dx + .12 * s, base.dy), Paint()..color = shade);
    c.restore();
  }

  /// A glass tower with a style of crown: 0 flat, 1 slanted, 2 pointed,
  /// 3 twin blades. [haze] pushes it back into the distance.
  static void _tower(Canvas c, double x, double baseY, double w, double hgt, int style, double haze) {
    final body = _hazed(const Color(0xffa9c4d6), haze);
    final lit = _hazed(const Color(0xffdcebf5), haze - .02);
    final shade = _hazed(const Color(0xff7f9db6), haze);
    final top = baseY - hgt;
    final left = x - w / 2, right = x + w / 2;
    final Path shape;
    switch (style) {
      case 1:
        shape = Sketch.poly([left, baseY, left, top + hgt * .08, right, top - hgt * .06, right, baseY]);
      case 2:
        shape = Sketch.poly([left, baseY, left, top + hgt * .1, x, top - hgt * .1, right, top + hgt * .1, right, baseY]);
      case 3:
        shape = Sketch.poly([left, baseY, left, top, x - w * .05, top + hgt * .06, x - w * .05, baseY - hgt * .25, x + w * .05, baseY - hgt * .25, x + w * .05, top + hgt * .06, right, top, right, baseY]);
      default:
        shape = Sketch.poly([left, baseY, left, top, right, top, right, baseY]);
    }
    c.drawPath(shape, Paint()..color = body);
    // Light and shade are clipped to the silhouette, so crowns stay clean.
    c.save();
    c.clipPath(shape);
    c.drawRect(Rect.fromLTRB(left, top - hgt * .12, x - w * .1, baseY), Paint()..color = lit);
    c.drawRect(Rect.fromLTRB(x + w * .2, top - hgt * .12, right, baseY), Paint()..color = shade);
    final line = Paint()
      ..color = _hazed(const Color(0xffffffff), haze + .1).withValues(alpha: .35)
      ..strokeWidth = math.max(.5, w * .012);
    for (var y = baseY - hgt * .06; y > top + hgt * .12; y -= hgt * .06) {
      c.drawLine(Offset(left, y), Offset(right, y), line);
    }
    c.restore();
  }

  /// The Dubai Frame: two gold towers joined by a bridge at the top.
  static void _frame(Canvas c, Offset base, double s) {
    final gold = _hazed(const Color(0xffd9a441), .2);
    final deep = _hazed(const Color(0xffa8792c), .2);
    final glass = _hazed(const Color(0xff7fb0c8), .25);
    final post = s * .08;
    for (final dx in const [-.3, .3]) {
      c.drawRect(Rect.fromLTRB(base.dx + dx * s - post / 2, base.dy - s, base.dx + dx * s + post / 2, base.dy), Paint()..color = gold);
      c.drawRect(Rect.fromLTRB(base.dx + dx * s, base.dy - s, base.dx + dx * s + post / 2, base.dy), Paint()..color = deep);
    }
    c.drawRect(Rect.fromLTRB(base.dx - s * .34, base.dy - s, base.dx + s * .34, base.dy - s * .92), Paint()..color = gold);
    c.drawRect(Rect.fromLTRB(base.dx - s * .26, base.dy - s * .985, base.dx + s * .26, base.dy - s * .935), Paint()..color = glass);
    c.drawRect(Rect.fromLTRB(base.dx - s * .34, base.dy - s * .94, base.dx + s * .34, base.dy - s * .92), Paint()..color = deep);
  }

  /// The Burj Al Arab: a billowing sail on a slim mast with ribbed fabric.
  static void _sail(Canvas c, Offset base, double s) {
    final white = _hazed(const Color(0xfff8fbff), .12);
    final rib = _hazed(const Color(0xffbfd2e2), .15);
    final path = Path()
      ..moveTo(base.dx - s * .1, base.dy)
      ..lineTo(base.dx - s * .06, base.dy - s)
      ..quadraticBezierTo(base.dx + s * .02, base.dy - s * .4, base.dx + s * .22, base.dy)
      ..close();
    c.drawPath(path, Paint()..color = white);
    // The curve of the fabric turns from the light on its lee edge.
    c.drawPath(
      Path()
        ..moveTo(base.dx - s * .06, base.dy - s)
        ..quadraticBezierTo(base.dx + s * .02, base.dy - s * .4, base.dx + s * .22, base.dy)
        ..lineTo(base.dx + s * .1, base.dy)
        ..quadraticBezierTo(base.dx - s * .01, base.dy - s * .45, base.dx - s * .06, base.dy - s)
        ..close(),
      Paint()..color = _hazed(const Color(0xffd3e2ee), .15),
    );
    final line = Paint()
      ..color = rib
      ..strokeWidth = math.max(.6, s * .006);
    for (var i = 1; i < 6; i++) {
      final y = base.dy - s * i / 6.5;
      c.drawLine(Offset(base.dx - s * (.1 - .004 * i), y), Offset(base.dx + s * (.2 - .04 * i), y), line);
    }
    // The mast spar and the needle above the sail.
    c.drawLine(
      Offset(base.dx - s * .1, base.dy),
      Offset(base.dx - s * .06, base.dy - s * 1.07),
      Paint()
        ..color = _hazed(const Color(0xff9fb6c8), .15)
        ..strokeWidth = math.max(.8, s * .012)
        ..strokeCap = StrokeCap.round,
    );
    c.drawRect(Rect.fromLTRB(base.dx - s * .1, base.dy - s * .04, base.dx + s * .22, base.dy), Paint()..color = const Color(0xff2f8fc0));
    c.drawRect(Rect.fromLTRB(base.dx - s * .1, base.dy - s * .34, base.dx - s * .02, base.dy - s * .3), Paint()..color = rib);
  }

  /// A moored yacht: a white hull, a cabin and a flybridge.
  static void _yacht(Canvas c, Offset base, double s) {
    final white = _hazed(const Color(0xfff8fbff), .1);
    c.drawPath(
      Sketch.poly([base.dx - s, base.dy - s * .4, base.dx + s * 1.15, base.dy - s * .5, base.dx + s * .8, base.dy + s * .5, base.dx - s * .75, base.dy + s * .5]),
      Paint()..color = white,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .5, base.dy - s * .4 - s * .34, base.dx + s * .55, base.dy - s * .42),
      Paint()..color = _hazed(const Color(0xffdfe9f2), .1),
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .3, base.dy - s * .4 - s * .52, base.dx + s * .25, base.dy - s * .4 - s * .34),
      Paint()..color = white,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .42, base.dy - s * .4 - s * .26, base.dx + s * .45, base.dy - s * .4 - s * .16),
      Paint()..color = const Color(0xff4d7590),
    );
  }

  static void _camel(Canvas c, Offset base, double s, int k) {
    const body = Color(0xff7a5636), shade = Color(0xff5a3f28);
    final leg = Paint()
      ..color = shade
      ..strokeWidth = math.max(1.0, s * .05)
      ..strokeCap = StrokeCap.round;
    // Each camel is caught at a different point of its stride.
    final stride = (k.isEven ? .05 : -.05) * s;
    var n = 0;
    for (final dx in const [-.2, -.14, .14, .2]) {
      final swing = (n++).isEven ? stride : -stride;
      c.drawLine(Offset(base.dx + dx * s, base.dy - s * .4), Offset(base.dx + dx * s * 1.05 + swing, base.dy), leg);
    }
    c.drawOval(Rect.fromCenter(center: Offset(base.dx, base.dy - s * .5), width: s * .6, height: s * .26), Paint()..color = body);
    c.drawOval(Rect.fromCenter(center: Offset(base.dx - s * .02, base.dy - s * .66), width: s * .2, height: s * .2), Paint()..color = body);
    c.drawLine(
      Offset(base.dx + s * .22, base.dy - s * .55),
      Offset(base.dx + s * .34, base.dy - s * .86),
      Paint()
        ..color = body
        ..strokeWidth = math.max(1.4, s * .08)
        ..strokeCap = StrokeCap.round,
    );
    c.drawOval(Rect.fromCenter(center: Offset(base.dx + s * .4, base.dy - s * .88), width: s * .18, height: s * .09), Paint()..color = body);
    c.drawLine(
      Offset(base.dx - s * .3, base.dy - s * .52),
      Offset(base.dx - s * .34, base.dy - s * .34),
      leg,
    );
  }
}
