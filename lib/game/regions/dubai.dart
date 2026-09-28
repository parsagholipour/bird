import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Dubai on a bright, hazy morning: a glass skyline with the Burj Khalifa
/// stepping into the sky beside a gold frame and slanted towers, the sail of
/// the Burj Al Arab on its island in a turquoise gulf with a dhow crossing,
/// and golden dunes with a camel caravan and date palms. A hot-air balloon
/// drifts by and sand streaks over the dunes.
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
    Depth.far => .68,
    Depth.mid => .75,
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

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    switch (d) {
      case Depth.far:
        var x = -h * .05;
        var i = 0;
        while (x < w + h * .05) {
          final bw = h * (.03 + .03 * Sketch.hash(i + 500));
          final bh = h * (.05 + .13 * Sketch.hash(i + 501));
          c.drawRect(
            Rect.fromLTRB(x, h * .71 - bh, x + bw, h * .71),
            Paint()..color = _hazed(const Color(0xffaebdc9), .55),
          );
          if (i % 4 == 1) {
            c.drawRect(
              Rect.fromLTRB(x + bw * .42, h * .71 - bh - h * .035, x + bw * .58, h * .71 - bh),
              Paint()..color = _hazed(const Color(0xffaebdc9), .55),
            );
          }
          x += bw + h * .006;
          i++;
        }
      case Depth.mid:
        _frame(c, Offset(w * .12, h * .76), h * .22);
        _tower(c, w * .3, h * .76, h * .05, h * .32, 1);
        _tower(c, w * .38, h * .76, h * .045, h * .26, 2);
        _burj(c, Offset(w * .6, h * .76), h * .66);
        _tower(c, w * .74, h * .76, h * .055, h * .3, 3);
        _tower(c, w * .82, h * .76, h * .05, h * .22, 0);
        _tower(c, w * .92, h * .76, h * .05, h * .34, 1);
      case Depth.low:
        final x = span * .55;
        final y = ridge(d, x / h, 0) * h;
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y + h * .012), width: h * .34, height: h * .05),
          Paint()..color = const Color(0xffe6cf9c),
        );
        _sail(c, Offset(x, y + h * .006), h * .3);
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
          final x = span * (.32 + k * .075);
          _camel(c, Offset(x, ridge(d, x / h, 0) * h + h * .008), h * (.1 - k * .006));
        }
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.low) return;
    final h = f.h, span = period(d) * h;
    final x = (h * .4 + f.clock * h * .015) % span;
    final y = ridge(d, x / h, f.clock) * h + h * .006;
    final s = h * .05;
    c.drawPath(
      Sketch.poly([x - s, y - s * .32, x + s * 1.1, y - s * .5, x + s * .7, y + s * .1, x - s * .7, y + s * .1]),
      Paint()..color = const Color(0xff7a4a2a),
    );
    c.drawPath(
      Sketch.poly([x + s * .05, y - s * 1.3, x + s * .95, y - s * .5, x + s * .05, y - s * .42]),
      Paint()..color = const Color(0xfffff6e0),
    );
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .7), width: f.w * 1.3, height: h * .09),
          const Color(0xfffff6e6),
          .8 * presence,
        );
      case Depth.mid:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .76), width: f.w * 1.3, height: h * .1),
          const Color(0xfffff0d8),
          .6 * presence,
        );
      case Depth.low:
        final foam = Paint()
          ..color = Sketch.fade(const Color(0xffffffff), .45 * presence)
          ..strokeWidth = h * .003
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final x = (f.w + h) * Sketch.hash(i + 530) - h * .4;
          final y = h * (.85 + .05 * Sketch.hash(i + 531));
          c.drawLine(Offset(x, y), Offset(x + h * (.03 + .012 * math.sin(f.clock + i)), y), foam);
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
    for (var i = 0; i < 8; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.5 + i * 1.9);
      glint.color = Sketch.fade(const Color(0xffffffe8), .65 * on * presence);
      final y = h * (.835 + i * .008);
      final x = f.w * light.at.dx + math.sin(i * 2.3) * h * .02;
      final len = h * (.05 - i * .004) * (.6 + .4 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    for (final (fx, fy, fw) in const [(.3, .18, .5), (.8, .3, .35)]) {
      final x = (w * fx - f.clock * h * .006) % (w + h * 1.2) - h * .6;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, h * fy), width: h * fw * 2, height: h * .03),
        const Color(0xfffffaf0),
        .55 * presence,
      );
    }
    // A hot-air balloon rises and drifts.
    final bx = (w * .45 + f.clock * h * .006) % (w + h * .4) - h * .1;
    final by = h * .3 + math.sin(f.clock * .4) * h * .012;
    final r = h * .035;
    final stripes = [const Color(0xffe94f6a), const Color(0xfffff6e0), const Color(0xff2fb5d8)];
    for (var i = 0; i < 3; i++) {
      c.drawOval(
        Rect.fromCenter(center: Offset(bx + (i - 1) * r * .5, by), width: r, height: r * 1.3),
        Paint()..color = Sketch.fade(stripes[i], presence),
      );
    }
    c.drawRect(
      Rect.fromCenter(center: Offset(bx, by + r * 1.2), width: r * .4, height: r * .3),
      Paint()..color = Sketch.fade(const Color(0xff7a4a2a), presence),
    );
  }

  /// The Burj Khalifa: a Y-shaped tower stepping in tiers to a slim spire.
  static void _burj(Canvas c, Offset base, double s) {
    final body = _hazed(const Color(0xffb9cfe0), .18);
    final lit = _hazed(const Color(0xffe4f0fa), .15);
    final shade = _hazed(const Color(0xff8fa9c2), .18);
    const tiers = [
      (.09, .0, .16),
      (.075, .16, .32),
      (.06, .32, .5),
      (.045, .5, .66),
      (.032, .66, .8),
      (.02, .8, .9),
    ];
    for (final (half, from, to) in tiers) {
      final r = Rect.fromLTRB(base.dx - half * s, base.dy - to * s, base.dx + half * s, base.dy - from * s);
      c.drawRect(r, Paint()..color = body);
      c.drawRect(Rect.fromLTRB(r.left, r.top, base.dx - half * s * .2, r.bottom), Paint()..color = lit);
      c.drawRect(Rect.fromLTRB(base.dx + half * s * .35, r.top, r.right, r.bottom), Paint()..color = shade);
    }
    c.drawPath(
      Sketch.poly([base.dx - s * .012, base.dy - s * .9, base.dx + s * .012, base.dy - s * .9, base.dx, base.dy - s]),
      Paint()..color = body,
    );
  }

  /// A glass tower with a style of crown: 0 flat, 1 slanted, 2 pointed,
  /// 3 twin blades.
  static void _tower(Canvas c, double x, double baseY, double w, double hgt, int style) {
    final body = _hazed(const Color(0xffa9c4d6), .2);
    final lit = _hazed(const Color(0xffdcebf5), .18);
    final shade = _hazed(const Color(0xff7f9db6), .2);
    final top = baseY - hgt;
    final left = x - w / 2, right = x + w / 2;
    Path shape;
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
    c.drawRect(Rect.fromLTRB(left, top + hgt * .1, x - w * .1, baseY), Paint()..color = lit);
    c.drawRect(Rect.fromLTRB(x + w * .2, top + hgt * .1, right, baseY), Paint()..color = shade);
    final line = Paint()
      ..color = _hazed(const Color(0xffffffff), .3).withValues(alpha: .35)
      ..strokeWidth = math.max(.5, w * .012);
    for (var y = baseY - hgt * .06; y > top + hgt * .12; y -= hgt * .06) {
      c.drawLine(Offset(left, y), Offset(right, y), line);
    }
  }

  /// The Dubai Frame: two gold towers joined by a bridge at the top.
  static void _frame(Canvas c, Offset base, double s) {
    final gold = _hazed(const Color(0xffd9a441), .2);
    final deep = _hazed(const Color(0xffa8792c), .2);
    final post = s * .08;
    for (final dx in const [-.3, .3]) {
      c.drawRect(Rect.fromLTRB(base.dx + dx * s - post / 2, base.dy - s, base.dx + dx * s + post / 2, base.dy), Paint()..color = gold);
      c.drawRect(Rect.fromLTRB(base.dx + dx * s, base.dy - s, base.dx + dx * s + post / 2, base.dy), Paint()..color = deep);
    }
    c.drawRect(Rect.fromLTRB(base.dx - s * .34, base.dy - s, base.dx + s * .34, base.dy - s * .92), Paint()..color = gold);
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
    final line = Paint()
      ..color = rib
      ..strokeWidth = math.max(.6, s * .006);
    for (var i = 1; i < 6; i++) {
      final y = base.dy - s * i / 6.5;
      c.drawLine(Offset(base.dx - s * (.1 - .004 * i), y), Offset(base.dx + s * (.2 - .04 * i), y), line);
    }
    c.drawRect(Rect.fromLTRB(base.dx - s * .1, base.dy - s * .04, base.dx + s * .22, base.dy), Paint()..color = const Color(0xff2f8fc0));
    c.drawRect(Rect.fromLTRB(base.dx - s * .1, base.dy - s * .34, base.dx - s * .02, base.dy - s * .3), Paint()..color = rib);
  }

  static void _camel(Canvas c, Offset base, double s) {
    const body = Color(0xff7a5636), shade = Color(0xff5a3f28);
    final leg = Paint()
      ..color = shade
      ..strokeWidth = math.max(1.0, s * .05)
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-.2, -.14, .14, .2]) {
      c.drawLine(Offset(base.dx + dx * s, base.dy - s * .4), Offset(base.dx + dx * s * 1.05, base.dy), leg);
    }
    c.drawOval(Rect.fromCenter(center: Offset(base.dx, base.dy - s * .5), width: s * .6, height: s * .26), Paint()..color = body);
    c.drawOval(Rect.fromCenter(center: Offset(base.dx - s * .05, base.dy - s * .66), width: s * .18, height: s * .16), Paint()..color = body);
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
