import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Ancient Rome in the golden light of late afternoon: an aqueduct marching
/// across the Alban hills, the Colosseum with its broken flank between the
/// Pantheon and a triumphal arch, forum temples and cypresses on the dusty
/// road, and marble drums, laurel and a legionary in the foreground. Swallows
/// wheel and olive leaves drift.
class RomeScene extends RegionScene {
  const RomeScene();

  @override
  WorldRegion get region => WorldRegion.rome;

  @override
  double get horizon => .64;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.25, .24),
    radius: .062,
    disc: Color(0xfffff0c8),
    glow: Color(0xffffd48a),
    halo: .55,
    strength: .5,
  );

  static final _weather = Weather(Weather.of([(Mote.leaf, 8)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xfff2c9a0);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffcfb3a0),
      Color(0xffc4a898),
      Color(0x00000000),
      rimWidth: 0,
    ),
    Depth.mid => const Ground(
      Color(0xffa3a468),
      Color(0xff868a55),
      Color(0xffdde0a0),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xffcfa870),
      Color(0xffb68a52),
      Color(0xfff2d9a2),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xffbf9862),
      Color(0xff9a7548),
      Color(0xffe6c98a),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .69,
    Depth.mid => .74 - .025 * Sketch.humps(x / 1.7 + .2),
    Depth.low => .84 - .01 * Sketch.humps(x / 1.5 + .1),
    Depth.near => .935 - .012 * Sketch.humps(x / 1.5),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .4,
    Depth.mid => .3,
    Depth.low => .2,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  double _y(Depth d, double x, double h) => ridge(d, x / h, 0) * h;

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        for (final (fx, fw, top) in const [(.15, .35, .6), (.6, .45, .58), (.95, .3, .61)]) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(w * fx, h * .7),
              width: h * fw * 2,
              height: h * (.7 - top) * 2,
            ),
            Paint()..color = _hazed(const Color(0xffb59a94), .45),
          );
        }
        final stone = _hazed(const Color(0xffd6b48a), .45);
        final rect = Rect.fromLTRB(-h * .1, h * .625, w + h * .1, h * .7);
        c.drawRect(rect, Paint()..color = stone);
        Scenery.arches(c, rect, ((w + h * .2) / (h * .05)).round(), _hazed(const Color(0xffe8c9a8), .3));
        c.drawRect(Rect.fromLTRB(rect.left, rect.top - h * .006, rect.right, rect.top), Paint()..color = _hazed(const Color(0xffb8926a), .45));
      case Depth.mid:
        _pantheon(c, Offset(w * .16, _y(Depth.mid, w * .16, h) + h * .02), h * .2);
        _colosseum(c, Offset(w * .53, _y(Depth.mid, w * .53, h) + h * .02), h * .78);
        _arch(c, Offset(w * .9, _y(Depth.mid, w * .9, h) + h * .02), h * .2);
        for (final fx in const [.3, .77]) {
          Scenery.cypress(
            c,
            Offset(w * fx, _y(Depth.mid, w * fx, h) + h * .02),
            h * .16,
            _hazed(const Color(0xff4a5a3a), .25),
            _hazed(const Color(0xff6f8250), .25),
          );
        }
      case Depth.low:
        _temple(c, Offset(span * .3, _y(d, span * .3, h) + h * .012), h * .2);
        for (final fx in const [.08, .52, .8]) {
          final x = span * fx;
          Scenery.cypress(
            c,
            Offset(x, _y(d, x, h) + h * .012),
            h * (.2 + .04 * Sketch.hash((fx * 100).round())),
            const Color(0xff3f5a3a),
            const Color(0xff628050),
          );
        }
        for (final (fx, s) in const [(.62, 1.0), (.68, .7)]) {
          final x = span * fx;
          _column(c, Offset(x, _y(d, x, h) + h * .012), h * .08 * s, broken: true);
        }
      case Depth.near:
        for (final fx in const [.06, .7]) {
          final x = span * fx;
          Scenery.cypress(
            c,
            Offset(x, _y(d, x, h) + h * .012),
            h * .38,
            const Color(0xff2f4a30),
            const Color(0xff54754a),
          );
        }
        for (final (fx, s, broken) in const [(.28, 1.0, false), (.4, .75, true)]) {
          final x = span * fx;
          _column(c, Offset(x, _y(d, x, h) + h * .012), h * .22 * s, broken: broken);
        }
        _legionary(c, Offset(span * .55, _y(d, span * .55, h) + h * .012), h * .16);
        for (final fx in const [.2, .84]) {
          final x = span * fx;
          final y = _y(d, x, h) + h * .012;
          c.drawCircle(Offset(x, y - h * .022), h * .028, Paint()..color = const Color(0xff4f8a4a));
          c.drawCircle(Offset(x - h * .01, y - h * .03), h * .016, Paint()..color = const Color(0xff7fb562));
        }
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .69), width: f.w * 1.3, height: h * .08),
          const Color(0xffffe6c8),
          .7 * presence,
        );
      case Depth.mid:
        // Dry-stone walls and olive groves line the hillside.
        final olive = Paint()..color = Sketch.fade(const Color(0xff6f7f4a), .8 * presence);
        for (var i = 0; i < 20; i++) {
          final x = (f.w + h * .6) * Sketch.hash(i + 600) - h * .3;
          final y = (ridge(Depth.mid, x / h, 0) + .014 + .035 * Sketch.hash(i + 601)) * h;
          c.drawCircle(Offset(x, y), h * (.008 + .004 * Sketch.hash(i + 602)), olive);
        }
      case Depth.low || Depth.near:
        break;
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    for (final (fx, fy, fw) in const [(.3, .16, .55), (.7, .26, .4), (.9, .12, .3)]) {
      final x = (w * fx - f.clock * h * .007) % (w + h * 1.2) - h * .6;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .04),
        const Color(0xffffe4bc),
        .7 * presence,
      );
    }
    for (var i = 0; i < 5; i++) {
      final x = (w * .6 - i * h * .06 - f.clock * h * .03) % (w + h * .5) - h * .2;
      Sketch.bird(
        c,
        Offset(x, h * (.3 + .02 * (i % 3)) + math.sin(f.clock * 1.3 + i) * h * .012),
        h * .011,
        Sketch.fade(const Color(0xff4f3f4a), .8 * presence),
        flap: math.sin(f.clock * 3.2 + i * .8) * .5,
      );
    }
  }

  static void _pillars(Canvas c, Rect r, int n, Color body, Color shade) {
    final pw = r.width / (n * 2 - 1);
    for (var i = 0; i < n; i++) {
      final x = r.left + i * pw * 2;
      c.drawRect(Rect.fromLTRB(x, r.top, x + pw, r.bottom), Paint()..color = body);
      c.drawRect(Rect.fromLTRB(x + pw * .55, r.top, x + pw, r.bottom), Paint()..color = shade);
    }
  }

  /// The Pantheon: a columned portico under a pediment before a great dome.
  static void _pantheon(Canvas c, Offset base, double s) {
    final stone = _hazed(const Color(0xffe6cfa8), .2);
    final shade = _hazed(const Color(0xffc4a57c), .22);
    final dark = _hazed(const Color(0xff6a4f38), .25);
    Scenery.dome(c, Offset(base.dx + s * .05, base.dy - s * .3), s * .42, s * .5, _hazed(const Color(0xffb8a48a), .25), _hazed(const Color(0xffd6c4a8), .22));
    c.drawRect(Rect.fromLTRB(base.dx - s * .5, base.dy - s * .5, base.dx + s * .5, base.dy), Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(base.dx - s * .5, base.dy - s * .5, base.dx + s * .5, base.dy - s * .44), Paint()..color = shade);
    c.drawPath(
      Sketch.poly([base.dx - s * .55, base.dy - s * .5, base.dx + s * .55, base.dy - s * .5, base.dx, base.dy - s * .74]),
      Paint()..color = stone,
    );
    c.drawPath(
      Sketch.poly([base.dx - s * .4, base.dy - s * .52, base.dx + s * .4, base.dy - s * .52, base.dx, base.dy - s * .67]),
      Paint()..color = shade,
    );
    c.drawRect(Rect.fromLTRB(base.dx - s * .45, base.dy - s * .42, base.dx + s * .45, base.dy), Paint()..color = dark);
    _pillars(c, Rect.fromLTRB(base.dx - s * .45, base.dy - s * .42, base.dx + s * .45, base.dy), 6, stone, shade);
  }

  /// The Colosseum: three tiers of arches under an attic, its right flank
  /// broken down to the lower storeys.
  static void _colosseum(Canvas c, Offset base, double s) {
    final stone = _hazed(const Color(0xffe2c496), .2);
    final shade = _hazed(const Color(0xffc0a074), .22);
    final dark = _hazed(const Color(0xff6a4f38), .3);
    final left = base.dx - s * .5, right = base.dx + s * .5;
    final tier = s * .085;
    final broken = base.dx + s * .12;
    // Storeys, bottom to top; the top two stop at the break.
    for (var i = 0; i < 3; i++) {
      final bottom = base.dy - i * tier;
      final edge = i == 0 ? right : (i == 1 ? right - s * .06 : broken);
      final r = Rect.fromLTRB(left + i * s * .004, bottom - tier, edge, bottom);
      c.drawRect(r, Paint()..color = stone);
      c.drawRect(Rect.fromLTRB(r.left, r.bottom - tier * .12, r.right, r.bottom), Paint()..color = shade);
      Scenery.arches(c, Rect.fromLTRB(r.left, r.top + tier * .12, r.right, r.bottom - tier * .12), ((r.width) / (s * .04)).round(), dark);
    }
    final attic = Rect.fromLTRB(left + s * .01, base.dy - 3 * tier - tier * .8, broken, base.dy - 3 * tier);
    c.drawRect(attic, Paint()..color = shade);
    Scenery.windows(c, attic, cols: ((attic.width) / (s * .05)).round(), rows: 1, lit: dark, dark: dark, litChance: 1);
    // The ragged edge where the wall gives way.
    c.drawPath(
      Sketch.poly([
        broken,
        base.dy - 3 * tier,
        broken,
        base.dy - 3 * tier - tier * .8,
        broken + s * .03,
        base.dy - 3 * tier,
        broken + s * .05,
        base.dy - 2 * tier - tier * .3,
        broken + s * .09,
        base.dy - 2 * tier,
      ]),
      Paint()..color = stone,
    );
    c.drawRect(Rect.fromLTRB(left, base.dy - 3 * tier - tier * .9, left + s * .012, base.dy), Paint()..color = shade);
  }

  /// A triumphal arch: a block with three passages under a lettered attic.
  static void _arch(Canvas c, Offset base, double s) {
    final stone = _hazed(const Color(0xffe6cfa8), .2);
    final shade = _hazed(const Color(0xffc4a57c), .22);
    final dark = _hazed(const Color(0xff6a4f38), .3);
    final w = s * 1.1;
    c.drawRect(Rect.fromLTRB(base.dx - w / 2, base.dy - s * .85, base.dx + w / 2, base.dy), Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(base.dx - w / 2, base.dy - s * .85, base.dx + w / 2, base.dy - s * .75), Paint()..color = shade);
    c.drawRect(Rect.fromLTRB(base.dx - w * .55, base.dy - s * .9, base.dx + w * .55, base.dy - s * .85), Paint()..color = shade);
    Scenery.arches(c, Rect.fromLTRB(base.dx - w * .48, base.dy - s * .5, base.dx + w * .48, base.dy), 3, dark);
  }

  /// A temple front: steps, four columns and a pediment.
  static void _temple(Canvas c, Offset base, double s) {
    final stone = _hazed(const Color(0xffe6cfa8), .2);
    final shade = _hazed(const Color(0xffc4a57c), .22);
    final dark = _hazed(const Color(0xff6a4f38), .3);
    final w = s * .9;
    c.drawRect(Rect.fromLTRB(base.dx - w * .6, base.dy - s * .08, base.dx + w * .6, base.dy), Paint()..color = shade);
    c.drawRect(Rect.fromLTRB(base.dx - w * .5, base.dy - s * .16, base.dx + w * .5, base.dy - s * .08), Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(base.dx - w * .4, base.dy - s * .7, base.dx + w * .4, base.dy - s * .16), Paint()..color = dark);
    _pillars(c, Rect.fromLTRB(base.dx - w * .4, base.dy - s * .68, base.dx + w * .4, base.dy - s * .16), 4, stone, shade);
    c.drawRect(Rect.fromLTRB(base.dx - w * .5, base.dy - s * .76, base.dx + w * .5, base.dy - s * .68), Paint()..color = stone);
    c.drawPath(
      Sketch.poly([base.dx - w * .55, base.dy - s * .76, base.dx + w * .55, base.dy - s * .76, base.dx, base.dy - s * 1.0]),
      Paint()..color = shade,
    );
  }

  /// A fluted marble column with a capital, or a broken stump of drums.
  static void _column(Canvas c, Offset base, double s, {required bool broken}) {
    const stone = Color(0xffeadcc0), shade = Color(0xffc6b494);
    final w = s * .22;
    final top = base.dy - s * (broken ? .6 : 1.0);
    c.drawRect(Rect.fromLTRB(base.dx - w * .7, base.dy - s * .08, base.dx + w * .7, base.dy), Paint()..color = shade);
    c.drawRect(Rect.fromLTRB(base.dx - w / 2, top, base.dx + w / 2, base.dy - s * .08), Paint()..color = stone);
    c.drawRect(Rect.fromLTRB(base.dx + w * .1, top, base.dx + w / 2, base.dy - s * .08), Paint()..color = shade);
    final flute = Paint()
      ..color = shade
      ..strokeWidth = math.max(.5, w * .05);
    for (final dx in const [-.28, -.05]) {
      c.drawLine(Offset(base.dx + dx * w, top), Offset(base.dx + dx * w, base.dy - s * .08), flute);
    }
    if (broken) {
      c.drawPath(
        Sketch.poly([base.dx - w / 2, top, base.dx - w * .15, top - s * .05, base.dx + w * .1, top + s * .02, base.dx + w / 2, top - s * .03, base.dx + w / 2, top]),
        Paint()..color = stone,
      );
    } else {
      c.drawRect(Rect.fromLTRB(base.dx - w * .8, top - s * .06, base.dx + w * .8, top), Paint()..color = stone);
      c.drawRect(Rect.fromLTRB(base.dx - w * .8, top - s * .02, base.dx + w * .8, top), Paint()..color = shade);
    }
  }

  /// A legionary at rest: red plume, bronze helm, tunic and a scarlet shield.
  static void _legionary(Canvas c, Offset base, double s) {
    final skin = Paint()..color = const Color(0xffc48a5a);
    final iron = Paint()
      ..color = const Color(0xff5a4a3a)
      ..strokeWidth = math.max(1.0, s * .03);
    c.drawLine(Offset(base.dx + s * .3, base.dy), Offset(base.dx + s * .3, base.dy - s * 1.2), iron);
    c.drawPath(
      Sketch.poly([base.dx + s * .3, base.dy - s * 1.3, base.dx + s * .34, base.dy - s * 1.2, base.dx + s * .26, base.dy - s * 1.2]),
      Paint()..color = const Color(0xffb8c0c8),
    );
    for (final dx in const [-.1, .1]) {
      c.drawRect(Rect.fromLTRB(base.dx + dx * s - s * .035, base.dy - s * .4, base.dx + dx * s + s * .035, base.dy), skin);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(base.dx - s * .17, base.dy - s * .8, base.dx + s * .17, base.dy - s * .38),
        Radius.circular(s * .04),
      ),
      Paint()..color = const Color(0xffb8402f),
    );
    c.drawRect(Rect.fromLTRB(base.dx - s * .17, base.dy - s * .5, base.dx + s * .17, base.dy - s * .38), Paint()..color = const Color(0xffe8d2b0));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(base.dx - s * .34, base.dy - s * .8, base.dx - s * .1, base.dy - s * .34),
        Radius.circular(s * .05),
      ),
      Paint()..color = const Color(0xffc8402f),
    );
    c.drawCircle(Offset(base.dx - s * .22, base.dy - s * .57), s * .05, Paint()..color = const Color(0xffe6b44c));
    c.drawCircle(Offset(base.dx, base.dy - s * .9), s * .1, skin);
    c.drawArc(
      Rect.fromCircle(center: Offset(base.dx, base.dy - s * .92), radius: s * .115),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xffc9a040),
    );
    c.drawPath(
      Sketch.poly([base.dx - s * .02, base.dy - s * 1.03, base.dx + s * .02, base.dy - s * 1.03, base.dx + s * .02, base.dy - s * 1.14, base.dx - s * .02, base.dy - s * 1.14]),
      Paint()..color = const Color(0xffc8402f),
    );
  }
}
