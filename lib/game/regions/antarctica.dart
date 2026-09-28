import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// Antarctica in polar twilight: aurora curtains over a low sun, snowy peaks
/// lit pink along their western faces, a sheer ice shelf with a far research
/// station, icebergs adrift in the dark sea and an emperor penguin colony
/// beside an orange field hut. Snowfall and twinkling snow.
class AntarcticaScene extends RegionScene {
  const AntarcticaScene();

  @override
  WorldRegion get region => WorldRegion.antarctica;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.2, .6),
    radius: .045,
    disc: Color(0xfffff3e4),
    glow: Color(0xffffc6aa),
    halo: .6,
    strength: .5,
  );

  static final _weather = Weather(Weather.of([(Mote.snow, 34)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffc3d4ea);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffd9e3f2),
      Color(0xffc7d4ea),
      Color(0xfffff1ea),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xfff4f9fd),
      Color(0xff9cc0dd),
      Color(0xffffffff),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xff41709a),
      Color(0xff2b537c),
      Color(0xffbcd8ee),
      rimWidth: .0025,
    ),
    Depth.near => const Ground(
      Color(0xfff6fafd),
      Color(0xffcfdeee),
      Color(0xffffffff),
      rimWidth: .006,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .655 + Sketch.waves(x, const [(2.2, .004, .3)]),
    // A tabular shelf: flat tops broken by sheer steps.
    Depth.mid => .712 - .022 * _shelf(x / 2.3 + .15) - .01 * _shelf(x / .9),
    Depth.low => .785,
    Depth.near =>
      .905 - .022 * Sketch.humps(x / 1.7) - .008 * Sketch.humps(x / .85 + .4),
  };

  /// A smoothed square wave in 0..1: level ice with short steep steps.
  static double _shelf(double x) {
    final p = x - x.floorToDouble();
    final v = ((p < .5 ? p : 1 - p) * 2 - .5) * 9 + .5;
    final k = v.clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }

  @override
  double period(Depth d) => d == Depth.low ? 2.6 : 3.4;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .36,
    Depth.mid => .14,
    Depth.low => .2,
    Depth.near => .16,
  };

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _range(c, w, h);
      case Depth.mid:
        _station(c, Offset(w * .74, h * .7), h * .03);
      case Depth.low:
        _berg(c, Offset(h * .5, h * .79), h * .1, tabular: true);
        _berg(c, Offset(h * 1.55, h * .79), h * .13, tabular: false);
        _berg(c, Offset(h * 2.2, h * .792), h * .05, tabular: true);
      case Depth.near:
        break;
    }
  }

  /// Penguins: (world x, depth below the ridge line, scale).
  static const _colony = [
    (.35, .03, 1.0),
    (.43, .022, .9),
    (.5, .036, 1.05),
    (.58, .026, .85),
    (1.3, .026, 1.0),
    (1.38, .034, .8),
    (2.85, .028, .95),
  ];

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.mid:
        // Crevasse lines and blue shadow on the shelf's sheer face.
        final crack = Paint()
          ..color = Sketch.fade(const Color(0xff7fa9cf), .55 * presence)
          ..strokeWidth = h * .003;
        for (var i = 0; i < 26; i++) {
          final x = (f.w + h * 1.2) * i / 26 - h * .4;
          final y = ridge(d, x / h, 0) * h + h * .012;
          c.drawLine(
            Offset(x, y),
            Offset(x + h * .004, y + h * (.03 + .03 * Sketch.hash(i))),
            crack,
          );
        }
      case Depth.low:
        // Reflections of the bergs and the low sun trail on the water.
        final glint = Paint()
          ..strokeWidth = h * .003
          ..strokeCap = StrokeCap.round;
        final span = period(d) * h;
        for (var i = 0; i < 10; i++) {
          final on = .5 + .5 * math.sin(f.clock * (1.3 + i * .1) + i * 2);
          glint.color = Sketch.fade(
            const Color(0xffffe2d4),
            .55 * on * presence,
          );
          final x = span * Sketch.hash(i + 30);
          final y = h * (.8 + .05 * Sketch.hash(i + 31));
          c.drawLine(Offset(x - h * .02, y), Offset(x + h * .02, y), glint);
        }
      case Depth.near:
        // The colony and the field hut stand on the snow, in front of the
        // ridge line, so the sea never shows behind their feet.
        _hut(
          c,
          Offset(h * 2.5, ridge(d, 2.5, 0) * h + h * .028),
          h * .075,
          presence,
        );
        for (var i = 0; i < _colony.length; i++) {
          final (x, lift, s) = _colony[i];
          // Penguins shift their weight from foot to foot.
          final sway = math.sin(f.clock * 2.2 + i * 1.7) * .06;
          _penguin(
            c,
            Offset(x * h, (ridge(d, x, 0) + lift) * h),
            h * .07 * s,
            sway,
            i.isOdd,
            presence,
          );
        }
        // Snow crystals twinkle on the drifts.
        final spark = Paint()
          ..color = Sketch.fade(const Color(0xffffffff), presence);
        final span = period(d) * h;
        for (var i = 0; i < 12; i++) {
          final on = math.sin(f.clock * 2.6 + i * 2.4);
          if (on < .2) continue;
          final x = span * Sketch.hash(i + 70);
          final y =
              ridge(d, x / h, 0) * h + h * (.012 + .05 * Sketch.hash(i + 71));
          final s = h * .006 * on;
          c.drawPath(
            Sketch.poly([
              x, y - s, x + s * .25, y, x, y + s, x - s * .25, y, //
            ]),
            spark,
          );
          c.drawPath(
            Sketch.poly([x - s, y, x, y + s * .25, x + s, y, x, y - s * .25]),
            spark,
          );
        }
      case Depth.far:
        break;
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // A few bright stars remain in the twilight.
    final star = Paint();
    for (var i = 0; i < 22; i++) {
      final twinkle = .6 + .4 * math.sin(f.clock * 1.8 + i * 2.7);
      star.color = Sketch.fade(
        const Color(0xfffff8ec),
        .8 * twinkle * presence,
      );
      c.drawCircle(
        Offset(w * Sketch.hash(i + 200), h * .36 * Sketch.hash(i + 300)),
        h * (.0018 + .0022 * Sketch.hash(i + 400)),
        star,
      );
    }
    // Aurora curtains: a crisp, bright hem with light streaming up from it,
    // rippling slowly. One vertical gradient per curtain shades both the
    // curtain and its rays.
    for (final (y0, span, color, fringe, speed) in const [
      (.27, .2, Color(0xff72f0bf), Color(0xffd6a2ff), .2),
      (.17, .13, Color(0xff8fe6ff), Color(0xff8fe6ff), -.14),
    ]) {
      final hem = <Offset>[];
      for (var x = -h * .2; x <= w + h * .2; x += w / 40) {
        final u = x / h;
        final y =
            h *
            (y0 +
                .04 * math.sin(u * 1.7 + f.clock * speed * 2) +
                .018 * math.sin(u * 4.6 - f.clock * speed * 3 + 1));
        hem.add(Offset(x, y));
      }
      final base = h * y0, top = base - span * h;
      final light = Paint()
        ..shader = Gradient.linear(
          Offset(0, base + h * .03),
          Offset(0, top),
          [
            Sketch.fade(color, .3 * presence),
            Sketch.fade(color, .1 * presence),
            Sketch.fade(fringe, .07 * presence),
            Sketch.fade(fringe, 0),
          ],
          const [0, .3, .7, 1],
        );
      final curtain = Path()..moveTo(hem.first.dx, hem.first.dy);
      for (final p in hem) {
        curtain.lineTo(p.dx, p.dy);
      }
      for (final p in hem.reversed) {
        curtain.lineTo(
          p.dx,
          p.dy - span * h * (.8 + .2 * math.sin(p.dx / h * 3)),
        );
      }
      curtain.close();
      c.drawPath(curtain, light);
      // A brighter inner band hugs the hem, where the curtain is densest.
      final inner = Path()..moveTo(hem.first.dx, hem.first.dy);
      for (final p in hem) {
        inner.lineTo(p.dx, p.dy);
      }
      for (var i = hem.length - 1; i >= 0; i--) {
        final p = hem[i];
        final ripple = .5 + .5 * math.sin(p.dx / h * 6 + f.clock * speed * 4);
        inner.lineTo(p.dx, p.dy - span * h * (.2 + .25 * ripple));
      }
      c.drawPath(inner..close(), light);
      final line = Path()..moveTo(hem.first.dx, hem.first.dy);
      for (final p in hem) {
        line.lineTo(p.dx, p.dy);
      }
      c.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .005
          ..color = Sketch.fade(
            Sketch.mix(color, const Color(0xffffffff), .4),
            .38 * presence,
          ),
      );
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    // The low sun's path across the dark sea.
    final h = f.h;
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .0035;
    for (var i = 0; i < 9; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.6 + i * 1.9);
      glint.color = Sketch.fade(const Color(0xffffd9c4), .7 * on * presence);
      final y = h * (.792 + i * .011);
      final x = f.w * light.at.dx + math.sin(i * 2.1 + f.clock * .5) * h * .012;
      final len = h * (.02 + i * .004) * (.5 + .5 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  /// Snowy peaks catching the low sun on their left faces.
  static void _range(Canvas c, double w, double h) {
    final lit = _hazed(const Color(0xfffbe3e6), .15);
    final shade = _hazed(const Color(0xff9fb2d8), .2);
    final back = _hazed(const Color(0xffb7c4e2), .35);
    final streak = Sketch.fade(_hazed(const Color(0xffdbe6f7), .1), .8);
    void peak(
      double x,
      double top,
      double half,
      Color face, {
      bool lit2 = true,
    }) {
      final base = h * .7;
      final apex = Offset(x, top * h);
      final ridgeFoot = Offset(x + half * h * .15, base);
      c.drawPath(
        Sketch.poly([x - half * h, base, apex.dx, apex.dy, x + half * h, base]),
        Paint()..color = face,
      );
      if (!lit2) return;
      // A crooked sunlit face and snow gullies on the shaded side.
      c.drawPath(
        Sketch.poly([
          x - half * h,
          base,
          apex.dx,
          apex.dy,
          apex.dx + half * h * .06,
          apex.dy + (base - apex.dy) * .3,
          ridgeFoot.dx - half * h * .1,
          apex.dy + (base - apex.dy) * .6,
          ridgeFoot.dx,
          base,
        ]),
        Paint()..color = lit,
      );
      final gully = Paint()
        ..color = streak
        ..strokeWidth = math.max(1.0, h * .003)
        ..strokeCap = StrokeCap.round;
      for (var k = 1; k <= 3; k++) {
        final from = Offset.lerp(apex, Offset(x + half * h, base), k * .22)!;
        c.drawLine(
          from,
          from + Offset(-half * h * .12, (base - apex.dy) * .22),
          gully,
        );
      }
    }

    for (final (fx, top, half) in const [
      (.08, .52, .2),
      (.3, .5, .18),
      (.62, .47, .24),
      (.92, .53, .17),
    ]) {
      peak(w * fx, top, half, back, lit2: false);
    }
    for (final (fx, top, half) in const [
      (-.02, .55, .16),
      (.18, .5, .15),
      (.46, .43, .2),
      (.54, .5, .13),
      (.78, .48, .19),
      (1.0, .53, .15),
      (1.15, .5, .17),
    ]) {
      peak(w * fx, top, half, shade);
    }
  }

  static void _station(Canvas c, Offset at, double s) {
    final wall = _hazed(const Color(0xffe07748), .25);
    final shade = _hazed(const Color(0xffa84f36), .25);
    c.drawRect(
      Rect.fromLTWH(at.dx - s * 1.6, at.dy - s * .8, s * 3.2, s * .8),
      Paint()..color = wall,
    );
    c.drawRect(
      Rect.fromLTWH(at.dx + s * .9, at.dy - s * .8, s * .7, s * .8),
      Paint()..color = shade,
    );
    c.drawRect(
      Rect.fromLTWH(at.dx - s * .4, at.dy - s * 1.4, s * 1.4, s * .6),
      Paint()..color = wall,
    );
    // A radar dome and a mast.
    c.drawCircle(
      at + Offset(-s * 2.3, -s * .8),
      s * .6,
      Paint()..color = _hazed(const Color(0xfff6f8fb), .2),
    );
    c.drawLine(
      at + Offset(s * .3, -s * 1.4),
      at + Offset(s * .3, -s * 2.6),
      Paint()
        ..color = shade
        ..strokeWidth = s * .12,
    );
  }

  static void _berg(Canvas c, Offset at, double s, {required bool tabular}) {
    const lit = Color(0xfff5fbff),
        face = Color(0xffc8e2f4),
        deep = Color(0xff8fbfe0);
    final top = tabular
        ? [-1.6, .2, -1.4, -.55, -.2, -.62, .9, -.58, 1.5, -.5, 1.8, .2]
        : [
            -1.2,
            .2,
            -.8,
            -.5,
            -.3,
            -.7,
            0.0,
            -1.2,
            .35,
            -.85,
            .7,
            -.5,
            1.1,
            -.35,
            1.4,
            .2,
          ];
    c.drawPath(Sketch.poly(top, at: at, s: s), Paint()..color = face);
    // Sunlit left face and a deep blue cleft.
    c.drawPath(
      Sketch.poly(
        tabular
            ? [-1.6, .2, -1.4, -.55, -.2, -.62, -.5, .2]
            : [-1.2, .2, -.8, -.5, -.3, -.7, 0.0, -1.2, -.2, .2],
        at: at,
        s: s,
      ),
      Paint()..color = lit,
    );
    c.drawPath(
      Sketch.poly(
        tabular ? [.9, -.58, 1.1, .2, .7, .2] : [.35, -.85, .55, .2, .2, .2],
        at: at,
        s: s,
      ),
      Paint()..color = deep,
    );
  }

  static void _hut(Canvas c, Offset base, double s, double alpha) {
    Color a(Color color) => Sketch.fade(color, alpha);
    final orange = a(const Color(0xffe8743f)),
        shade = a(const Color(0xffbe5a33));
    // Stilts, a rounded roof and a porthole window.
    final stilt = Paint()
      ..color = a(const Color(0xff5d6f86))
      ..strokeWidth = s * .08;
    for (final dx in const [-.8, .8]) {
      c.drawLine(
        base + Offset(dx * s, 0),
        base + Offset(dx * s, -s * .4),
        stilt,
      );
    }
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        base.dx - s,
        base.dy - s * 1.3,
        base.dx + s,
        base.dy - s * .35,
      ),
      topLeft: Radius.circular(s * .7),
      topRight: Radius.circular(s * .7),
    );
    c.drawRRect(body, Paint()..color = orange);
    c.drawRect(
      Rect.fromLTRB(
        base.dx + s * .45,
        base.dy - s * 1.2,
        base.dx + s,
        base.dy - s * .35,
      ),
      Paint()..color = shade,
    );
    c.drawCircle(
      base + Offset(-s * .3, -s * .8),
      s * .18,
      Paint()..color = a(const Color(0xfffff0b8)),
    );
    c.drawCircle(
      base + Offset(-s * .3, -s * .8),
      s * .18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .06
        ..color = a(const Color(0xff7c4a33)),
    );
    // Snow on the roof and a flag on its pole.
    c.drawPath(
      Path()
        ..moveTo(base.dx - s * .95, base.dy - s * .95)
        ..quadraticBezierTo(
          base.dx - s * .9,
          base.dy - s * 1.36,
          base.dx,
          base.dy - s * 1.38,
        )
        ..quadraticBezierTo(
          base.dx + s * .9,
          base.dy - s * 1.36,
          base.dx + s * .95,
          base.dy - s * .95,
        )
        ..quadraticBezierTo(
          base.dx,
          base.dy - s * 1.22,
          base.dx - s * .95,
          base.dy - s * .95,
        )
        ..close(),
      Paint()..color = a(const Color(0xfffbfdff)),
    );
    c.drawLine(
      base + Offset(s * 1.4, 0),
      base + Offset(s * 1.4, -s * 2),
      Paint()
        ..color = a(const Color(0xff6c7d92))
        ..strokeWidth = s * .06,
    );
    c.drawPath(
      Sketch.poly([1.43, -2, 2.1, -1.84, 1.43, -1.66], at: base, s: s),
      Paint()..color = a(const Color(0xffd8453a)),
    );
  }

  static void _penguin(
    Canvas c,
    Offset base,
    double s,
    double sway,
    bool turn,
    double alpha,
  ) {
    Color a(Color color) => Sketch.fade(color, alpha);
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(sway * .3);
    if (turn) c.scale(-1, 1);
    // Black back, white front, golden ear patch and a small orange bill.
    c.drawPath(
      Path()
        ..moveTo(-s * .2, 0)
        ..cubicTo(-s * .34, -s * .4, -s * .26, -s * .82, -s * .08, -s * .96)
        ..cubicTo(s * .02, -s * 1.04, s * .16, -s * 1.02, s * .2, -s * .9)
        ..cubicTo(s * .3, -s * .6, s * .3, -s * .3, s * .22, 0)
        ..close(),
      Paint()..color = a(const Color(0xff273349)),
    );
    c.drawPath(
      Path()
        ..moveTo(-s * .02, -s * .02)
        ..cubicTo(s * .02, -s * .3, s * .02, -s * .62, s * .12, -s * .78)
        ..cubicTo(s * .24, -s * .6, s * .26, -s * .3, s * .2, -s * .02)
        ..close(),
      Paint()..color = a(const Color(0xfffbfbf6)),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s * .1, -s * .8),
        width: s * .12,
        height: s * .08,
      ),
      Paint()..color = a(const Color(0xfff6c14a)),
    );
    c.drawPath(
      Sketch.poly(const [.18, -.9, .36, -.84, .18, -.84], s: s),
      Paint()..color = a(const Color(0xffe0823e)),
    );
    c.restore();
  }
}
