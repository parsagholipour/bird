import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// An Aztec sunrise over the Valley of Mexico: snow-capped volcanoes fading
/// into haze, stepped temple pyramids with a stair and a shrine on top,
/// jungle-green terraces, and carved totems with flickering torches beside
/// agave on the near ground. Sun rays fan across the sky and leaves drift.
class AztecScene extends RegionScene {
  const AztecScene();

  @override
  WorldRegion get region => WorldRegion.aztec;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.2, .42),
    radius: .07,
    disc: Color(0xffffe6a8),
    glow: Color(0xffffb46a),
    halo: .58,
    strength: .5,
  );

  static final _weather = Weather(Weather.of([(Mote.leaf, 12)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xfff2b58f);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffb7a0b8),
      Color(0xffa8949f),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xff6f9a54),
      Color(0xff56824a),
      Color(0xffbfd98f),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xff7fa85a),
      Color(0xff5f8a48),
      Color(0xffd4e6a4),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xffc48a4e),
      Color(0xffa06a3a),
      Color(0xffe6b878),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .68,
    Depth.mid => .74 - .03 * Sketch.humps(x / 1.6 + .1),
    Depth.low => .84 - .02 * Sketch.humps(x / 1.5 + .2),
    Depth.near =>
      .935 - .025 * Sketch.humps(x / 1.5 + .3) - .008 * Sketch.humps(x / .5),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    Depth.mid => .3,
    Depth.low => .2,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        _volcano(c, w * .36, h * .36, h * .5, h * .7, wide: true);
        _volcano(c, w * .74, h * .3, h * .36, h * .7);
      case Depth.mid:
        for (final (fx, s) in const [(.16, .2), (.52, .36), (.88, .17)]) {
          final x = w * fx;
          _pyramid(c, Offset(x, ridge(Depth.mid, x / h, 0) * h + h * .02), h * s);
        }
      case Depth.low:
        for (var i = 0; i < 6; i++) {
          final x = span * (i + .3 + .4 * Sketch.hash(i + 40)) / 6;
          final s = h * (.07 + .03 * Sketch.hash(i + 41));
          Scenery.tree(
            c,
            Offset(x, ridge(d, x / h, 0) * h + h * .015),
            s,
            _hazed(const Color(0xff5a4a3a), .15),
            _hazed(const Color(0xff3f7f4a), .15),
            _hazed(const Color(0xff67a55a), .15),
          );
        }
      case Depth.near:
        for (final (fx, s) in const [(.08, 1.0), (.4, .8), (.72, 1.1)]) {
          final x = span * fx;
          Scenery.agave(
            c,
            Offset(x, ridge(d, x / h, 0) * h + h * .012),
            h * .1 * s,
            const Color(0xff4c8a5a),
            const Color(0xff7ab878),
          );
        }
        for (final fx in const [.26, .58, .9]) {
          final x = span * fx;
          _totem(c, Offset(x, ridge(d, x / h, 0) * h + h * .012), h * .12);
        }
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.near) return;
    final h = f.h, span = period(d) * h;
    for (final fx in const [.26, .58, .9]) {
      final x = span * fx;
      final base = Offset(x, ridge(d, x / h, 0) * h + h * .012);
      final flick = .8 + .2 * math.sin(f.clock * 9 + fx * 20 + copy);
      final tip = base + Offset(0, -h * .132);
      Sketch.mist(
        c,
        Rect.fromCenter(center: tip, width: h * .07, height: h * .07),
        const Color(0xffffb14a),
        .55 * flick,
      );
      c.drawPath(
        Path()
          ..moveTo(tip.dx - h * .01, tip.dy)
          ..quadraticBezierTo(
            tip.dx - h * .012,
            tip.dy - h * .02 * flick,
            tip.dx + math.sin(f.clock * 6 + fx) * h * .004,
            tip.dy - h * .035 * flick,
          )
          ..quadraticBezierTo(tip.dx + h * .012, tip.dy - h * .02, tip.dx + h * .01, tip.dy)
          ..close(),
        Paint()..color = const Color(0xffffc13f),
      );
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        for (var i = 0; i < 5; i++) {
          final x = (f.w + h) * i / 5 - h * .1 + math.sin(f.clock * .1 + i) * h * .03;
          Sketch.mist(
            c,
            Rect.fromCenter(
              center: Offset(x, h * (.665 + .01 * (i % 2))),
              width: h * .9,
              height: h * .1,
            ),
            const Color(0xffffe1c8),
            .8 * presence,
          );
        }
      case Depth.mid:
        Sketch.mist(
          c,
          Rect.fromCenter(
            center: Offset(f.w * .5, h * .74),
            width: f.w * 1.3,
            height: h * .1,
          ),
          const Color(0xffffe6c8),
          .5 * presence,
        );
      case Depth.low || Depth.near:
        break;
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final sun = Offset(light.at.dx * w, light.at.dy * h);
    // Long sunrise rays fan out over the sky.
    for (var i = 0; i < 7; i++) {
      final a = -1.25 + i * .28 + math.sin(f.clock * .12 + i) * .02;
      final left = sun + Offset(math.cos(a - .04), math.sin(a - .04)) * w * 1.4;
      final right = sun + Offset(math.cos(a + .04), math.sin(a + .04)) * w * 1.4;
      c.drawPath(
        Path()
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(right.dx, right.dy)
          ..close(),
        Paint()..color = Sketch.fade(const Color(0xffffe1a0), .1 * presence),
      );
    }
    for (final (fx, fy, fw) in const [(.3, .16, .5), (.75, .24, .4)]) {
      final x = (w * fx - f.clock * h * .008) % (w + h) - h * .5;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .04),
        const Color(0xffffdcc0),
        .6 * presence,
      );
    }
    // Macaws cross in a loose pair.
    final lead = Offset((w * .6 - f.clock * h * .035) % (w + h * .4) - h * .2, h * .2);
    for (var i = 0; i < 2; i++) {
      Sketch.bird(
        c,
        lead + Offset(i * h * .04, i * h * .02),
        h * .013,
        Sketch.fade(i == 0 ? const Color(0xffd9402f) : const Color(0xff2f6fc0), .85 * presence),
        flap: math.sin(f.clock * 3.4 + i) * .5,
      );
    }
  }

  static void _volcano(
    Canvas c,
    double x,
    double top,
    double half,
    double base, {
    bool wide = false,
  }) {
    final body = _hazed(const Color(0xff8f7fae), .35);
    final lit = _hazed(const Color(0xffb69cc4), .3);
    final snow = _hazed(const Color(0xfffff0ec), .12);
    final crater = half * (wide ? .3 : .16);
    c.drawPath(
      Sketch.poly([x - half, base, x - crater, top, x + crater, top, x + half, base]),
      Paint()..color = body,
    );
    c.drawPath(
      Sketch.poly([x - half, base, x - crater, top, x + crater * .4, top, x - half * .1, base]),
      Paint()..color = lit,
    );
    final drop = (base - top) * .22;
    c.drawPath(
      Sketch.poly([
        x - crater,
        top,
        x + crater,
        top,
        x + crater * 2.2,
        top + drop * .8,
        x + crater * .9,
        top + drop * .55,
        x + crater * .2,
        top + drop * 1.1,
        x - crater * .5,
        top + drop * .6,
        x - crater * 1.9,
        top + drop * .9,
      ]),
      Paint()..color = snow,
    );
    if (!wide) {
      Sketch.mist(
        c,
        Rect.fromCenter(
          center: Offset(x + half * .2, top - (base - top) * .1),
          width: half * .9,
          height: half * .25,
        ),
        const Color(0xfff8ece6),
        .7,
      );
    }
  }

  /// A five-tier temple pyramid with a stair and a shrine crowned by a comb.
  static void _pyramid(Canvas c, Offset base, double s) {
    final stone = _hazed(const Color(0xffcfae7c), .2);
    final shade = _hazed(const Color(0xffa8865c), .2);
    final dark = _hazed(const Color(0xff5a4634), .25);
    final stair = _hazed(const Color(0xffe6cf9e), .18);
    final teal = _hazed(const Color(0xff2fb5a0), .2);
    const tiers = 5;
    final tier = s * .13;
    for (var i = 0; i < tiers; i++) {
      final half = s * .62 * (1 - i * .16);
      final bottom = base.dy - i * tier;
      c.drawRect(
        Rect.fromLTRB(base.dx - half, bottom - tier, base.dx + half, bottom),
        Paint()..color = stone,
      );
      c.drawRect(
        Rect.fromLTRB(base.dx, bottom - tier, base.dx + half, bottom),
        Paint()..color = shade,
      );
      c.drawRect(
        Rect.fromLTRB(base.dx - half, bottom - tier, base.dx + half, bottom - tier + s * .012),
        Paint()..color = stair,
      );
    }
    final topY = base.dy - tiers * tier;
    c.drawPath(
      Sketch.poly([
        base.dx - s * .09,
        base.dy,
        base.dx + s * .09,
        base.dy,
        base.dx + s * .07,
        topY,
        base.dx - s * .07,
        topY,
      ]),
      Paint()..color = stair,
    );
    final step = Paint()
      ..color = shade
      ..strokeWidth = math.max(.6, s * .004);
    for (var k = 1; k < 14; k++) {
      final y = base.dy - (base.dy - topY) * k / 14;
      final half = s * (.09 - .02 * k / 14);
      c.drawLine(Offset(base.dx - half, y), Offset(base.dx + half, y), step);
    }
    final tw = s * .17, th = s * .13;
    c.drawRect(
      Rect.fromLTRB(base.dx - tw, topY - th, base.dx + tw, topY),
      Paint()..color = stone,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx, topY - th, base.dx + tw, topY),
      Paint()..color = shade,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - tw * .35, topY - th * .75, base.dx + tw * .35, topY),
      Paint()..color = dark,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - tw * 1.15, topY - th - s * .03, base.dx + tw * 1.15, topY - th),
      Paint()..color = shade,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - tw * .6, topY - th - s * .08, base.dx + tw * .6, topY - th - s * .03),
      Paint()..color = stone,
    );
    c.drawRect(
      Rect.fromLTRB(base.dx - tw * .6, topY - th - s * .062, base.dx + tw * .6, topY - th - s * .048),
      Paint()..color = teal,
    );
  }

  /// A carved stone totem of three stacked faces with a torch bowl on top.
  static void _totem(Canvas c, Offset base, double s) {
    const stone = Color(0xff8d7a66), lit = Color(0xffb09a80);
    const dark = Color(0xff3f342c);
    for (var i = 0; i < 3; i++) {
      final y = base.dy - (i + 1) * s * .3;
      final half = s * (.2 - i * .02);
      final r = Rect.fromLTRB(base.dx - half, y, base.dx + half, y + s * .3);
      c.drawRect(r, Paint()..color = stone);
      c.drawRect(
        Rect.fromLTRB(r.left, r.top, r.left + half * .5, r.bottom),
        Paint()..color = lit,
      );
      for (final dx in const [-.45, .45]) {
        c.drawRect(
          Rect.fromCenter(
            center: Offset(base.dx + dx * half, y + s * .09),
            width: half * .4,
            height: s * .06,
          ),
          Paint()..color = dark,
        );
      }
      c.drawRect(
        Rect.fromCenter(
          center: Offset(base.dx, y + s * .2),
          width: half * 1.1,
          height: s * .05,
        ),
        Paint()..color = dark,
      );
    }
    c.drawPath(
      Sketch.poly([
        base.dx - s * .24,
        base.dy - s * .9,
        base.dx + s * .24,
        base.dy - s * .9,
        base.dx + s * .14,
        base.dy - s * 1.0,
        base.dx - s * .14,
        base.dy - s * 1.0,
      ]),
      Paint()..color = const Color(0xff5a4a3e),
    );
  }
}
