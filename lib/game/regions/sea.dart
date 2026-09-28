import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// The open sea at dawn: the sun lifting off the horizon with its path of
/// light, a tall ship far out, a lighthouse on a rocky islet, a humpback
/// whale that surfaces and dives, and rolling swells with foam and spray
/// under pink-bellied clouds and wheeling gulls.
class SeaScene extends RegionScene {
  const SeaScene();

  @override
  WorldRegion get region => WorldRegion.sea;

  @override
  double get horizon => .6;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.7, .56),
    radius: .06,
    disc: Color(0xfffff4dc),
    glow: Color(0xffffcf9c),
    halo: .62,
    strength: .56,
  );

  static final _weather = Weather(Weather.of([(Mote.spray, 16)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffffcdb0);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xff9dc2d6),
      Color(0xff8ab5cd),
      Color(0xffffedd6),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xff72a9c6),
      Color(0xff5e9aba),
      Color(0xffd6ebf3),
      rimWidth: .002,
    ),
    Depth.low => const Ground(
      Color(0xff4f93b7),
      Color(0xff3a80a6),
      Color(0xb3e4f2f8),
      rimWidth: .0022,
    ),
    Depth.near => const Ground(
      Color(0xff3781a8),
      Color(0xff22628a),
      Color(0xccf4fbff),
      rimWidth: .0035,
    ),
  };

  static const _tau = math.pi * 2;

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .6,
    Depth.mid => .645 + .003 * math.sin(x * 9 - clock * .8),
    Depth.low =>
      .74 +
          .007 * math.sin(_tau * x / .75 - clock * 1.3) +
          .004 * math.sin(_tau * x / .5 + clock * .9 + 1),
    Depth.near =>
      .875 +
          .016 * math.sin(_tau * x / 1.5 - clock * 1.1) +
          .008 * math.sin(_tau * x / .75 + clock * .8 + 1) +
          .003 * math.sin(_tau * x / .375 - clock * 2),
  };

  @override
  double period(Depth d) => 3.0;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .12,
    Depth.mid => .36,
    Depth.low => .16,
    Depth.near => .14,
  };

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _tallShip(c, Offset(w * .24, h * .603), h * .034);
        _island(c, Offset(w * .98, h * .605), h);
      case Depth.mid:
        _lighthouse(c, Offset(w * .86, h * .65), h);
      case Depth.low || Depth.near:
        break;
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    final h = f.h;
    switch (d) {
      case Depth.mid:
        // The lamp still turns in the dawn light.
        final lamp = Offset(f.w * .86, h * .418);
        final a = f.clock * .9;
        final dir = math.cos(a);
        if (dir.abs() > .05) {
          final reach = h * .55 * dir.abs();
          final side = dir > 0 ? 1.0 : -1.0;
          c.drawPath(
            Path()
              ..moveTo(lamp.dx, lamp.dy - h * .006)
              ..lineTo(lamp.dx + side * reach, lamp.dy - h * .05)
              ..lineTo(lamp.dx + side * reach, lamp.dy + h * .04)
              ..lineTo(lamp.dx, lamp.dy + h * .006)
              ..close(),
            Paint()
              ..shader = Gradient.linear(lamp, lamp + Offset(side * reach, 0), [
                Sketch.fade(const Color(0xfffff6d8), .35 * dir.abs()),
                Sketch.fade(const Color(0xfffff6d8), 0),
              ]),
          );
        }
      case Depth.low:
        // A humpback surfaces, raises its flukes and dives, on a loop.
        final cycle = ((f.clock + copy * 5.3) % 14) / 14;
        final at = Offset(h * 1.6, h * .745);
        if (cycle < .35) {
          final k = cycle / .35;
          final lift = math.sin(k * math.pi);
          _spout(c, at + Offset(-h * .05, -h * .02), h * .05 * lift, lift);
          c.drawOval(
            Rect.fromCenter(
              center: at + Offset(0, h * (.02 - .026 * lift)),
              width: h * .16,
              height: h * .05,
            ),
            Paint()..color = const Color(0xff3d4d63),
          );
        } else if (cycle < .7) {
          final k = (cycle - .35) / .35;
          _fluke(
            c,
            at + Offset(h * .05, h * (.06 - .1 * math.sin(k * math.pi))),
            h * .07,
            k,
          );
        }
      case Depth.near:
        final bob = math.sin(f.clock * 1.6 + copy) * h * .01;
        final tilt = math.sin(f.clock * 1.2 + copy) * .12;
        _buoy(
          c,
          Offset(h * 2.2, ridge(d, 2.2, f.clock) * h + h * .01 + bob * .3),
          h * .05,
          tilt,
        );
      case Depth.far:
        break;
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.low || Depth.near:
        final near = d == Depth.near;
        final span = period(d) * h;
        // A lit band just under every crest gives the swells their volume.
        final face = Path();
        final band = h * (near ? .03 : .018);
        for (var x = 0.0; x <= span + 1; x += h * .03) {
          final y = ridge(d, x / h, f.clock) * h + band * .6;
          if (x == 0) {
            face.moveTo(x, y);
          } else {
            face.lineTo(x, y);
          }
        }
        c.drawPath(
          face,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = band
            ..color = Sketch.fade(
              const Color(0xffbfe6f2),
              (near ? .22 : .18) * presence,
            ),
        );
        // Foam streaks on the crests and flecks of light.
        final foam = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = h * (near ? .005 : .003);
        for (var i = 0; i < (near ? 14 : 10); i++) {
          final x = span * (i + Sketch.hash(i + 950) * .5) / (near ? 14 : 10);
          final y =
              ridge(d, x / h, f.clock) * h +
              h * (near ? .02 : .012) * (1 + Sketch.hash(i + 960));
          final on = .6 + .4 * math.sin(f.clock * 1.2 + i * 2);
          foam.color = Sketch.fade(
            const Color(0xfff2fbff),
            (near ? .55 : .4) * on * presence,
          );
          final len = h * (near ? .04 : .025) * on;
          c.drawLine(Offset(x - len, y), Offset(x + len, y + h * .002), foam);
        }
      case Depth.far || Depth.mid:
        break;
    }
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    // The sun's broken path across the water, widening toward the viewer.
    final h = f.h;
    final glint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .004;
    final sx = f.w * light.at.dx;
    for (var i = 0; i < 16; i++) {
      final k = i / 15;
      final on = .5 + .5 * math.sin(f.clock * 1.8 + i * 1.7);
      glint.color = Sketch.fade(
        const Color(0xfffff1d6),
        (.75 - k * .3) * on * presence,
      );
      final y = h * (.61 + k * .27);
      final x = sx + math.sin(i * 2.9 + f.clock * .6) * h * (.01 + k * .03);
      final len = h * (.012 + k * .05) * (.5 + .5 * on);
      c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // Cumulus lit pink from below by the rising sun.
    for (final (fx, fy, s) in const [
      (.12, .16, 1.0),
      (.42, .08, .7),
      (.58, .27, .85),
      (.92, .12, .8),
    ]) {
      final x = (w * fx - f.clock * h * .008) % (w + h * .6) - h * .3;
      _cloud(c, Offset(x, h * fy), h * .2 * s, presence);
    }
    // Gulls wheeling over the swell.
    for (var i = 0; i < 4; i++) {
      final a = f.clock * (.3 + i * .05) + i * 1.6;
      final center = Offset(w * (.2 + i * .2), h * (.3 + (i % 2) * .08));
      final p = center + Offset(math.cos(a) * h * .08, math.sin(a) * h * .025);
      Sketch.bird(
        c,
        p,
        h * (.018 - (i % 2) * .004),
        Sketch.fade(const Color(0xfff8f8f4), .9 * presence),
        flap: math.sin(f.clock * 4 + i * 1.3),
      );
    }
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  static void _cloud(Canvas c, Offset o, double s, double presence) {
    final top = Paint()
      ..color = Sketch.fade(const Color(0xfffff8f0), .9 * presence);
    final belly = Paint()
      ..color = Sketch.fade(const Color(0xffffc9b8), .9 * presence);
    for (final (dx, dy, r) in const [
      (0.0, .1, .22),
      (.25, 0, .3),
      (.55, .06, .24),
      (.78, .12, .17),
    ]) {
      c.drawCircle(o + Offset(dx * s, dy * s + s * .04), r * s, belly);
    }
    for (final (dx, dy, r) in const [
      (0.0, .06, .2),
      (.25, -.04, .28),
      (.55, .02, .22),
      (.78, .09, .15),
    ]) {
      c.drawCircle(o + Offset(dx * s, dy * s), r * s, top);
    }
  }

  static void _tallShip(Canvas c, Offset at, double s) {
    final hull = _hazed(const Color(0xff4f5f7c), .4);
    final sail = _hazed(const Color(0xfffbf4ea), .25);
    final shade = _hazed(const Color(0xffe0d6cc), .25);
    c.drawPath(
      Path()
        ..moveTo(at.dx - s * 1.5, at.dy - s * .3)
        ..lineTo(at.dx + s * 1.7, at.dy - s * .35)
        ..quadraticBezierTo(
          at.dx + s * 1.2,
          at.dy + s * .25,
          at.dx,
          at.dy + s * .25,
        )
        ..quadraticBezierTo(
          at.dx - s * 1.1,
          at.dy + s * .25,
          at.dx - s * 1.5,
          at.dy - s * .3,
        )
        ..close(),
      Paint()..color = hull,
    );
    // Bowsprit and jib.
    c.drawLine(
      at + Offset(s * 1.6, -s * .35),
      at + Offset(s * 2.4, -s * .8),
      Paint()
        ..color = hull
        ..strokeWidth = s * .06,
    );
    c.drawPath(
      Sketch.poly([1.0, -2.1, 2.3, -.82, 1.05, -.5], at: at, s: s),
      Paint()..color = shade,
    );
    final mast = Paint()
      ..color = hull
      ..strokeWidth = s * .07;
    for (final (dx, tall) in const [(-.8, 2.1), (.1, 2.6), (1.0, 2.2)]) {
      c.drawLine(
        at + Offset(dx * s, -s * .3),
        at + Offset(dx * s, -s * tall),
        mast,
      );
      // Square sails billow forward, stacked up the mast.
      for (var k = 0; k < 3; k++) {
        final top = -s * (.55 + k * .62), bottom = top + s * .52;
        final half = s * (.5 - k * .1);
        final x = at.dx + dx * s;
        c.drawPath(
          Path()
            ..moveTo(x - half, at.dy + top)
            ..lineTo(x + half, at.dy + top)
            ..quadraticBezierTo(
              x + half * 1.25,
              at.dy + (top + bottom) / 2,
              x + half * .95,
              at.dy + bottom,
            )
            ..lineTo(x - half * .95, at.dy + bottom)
            ..quadraticBezierTo(
              x - half * .75,
              at.dy + (top + bottom) / 2,
              x - half,
              at.dy + top,
            )
            ..close(),
          Paint()..color = k == 1 ? shade : sail,
        );
      }
    }
  }

  static void _island(Canvas c, Offset at, double h) {
    c.drawPath(
      Path()
        ..moveTo(at.dx - h * .3, at.dy + h * .02)
        ..quadraticBezierTo(
          at.dx - h * .12,
          at.dy - h * .05,
          at.dx,
          at.dy - h * .04,
        )
        ..quadraticBezierTo(
          at.dx + h * .15,
          at.dy - h * .03,
          at.dx + h * .3,
          at.dy + h * .02,
        )
        ..close(),
      Paint()..color = _hazed(const Color(0xff7f93a6), .45),
    );
  }

  static void _lighthouse(Canvas c, Offset base, double h) {
    const rock = Color(0xff5f5f6c),
        rockLit = Color(0xff8b8791),
        grass = Color(0xff7aa076);
    c.drawPath(
      Path()
        ..moveTo(base.dx - h * .2, base.dy + h * .03)
        ..lineTo(base.dx - h * .15, base.dy - h * .04)
        ..lineTo(base.dx - h * .06, base.dy - h * .07)
        ..lineTo(base.dx + h * .05, base.dy - h * .075)
        ..lineTo(base.dx + h * .13, base.dy - h * .05)
        ..lineTo(base.dx + h * .2, base.dy + h * .03)
        ..close(),
      Paint()..color = rock,
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx - h * .15, base.dy - h * .04)
        ..lineTo(base.dx - h * .06, base.dy - h * .07)
        ..lineTo(base.dx + h * .05, base.dy - h * .075)
        ..lineTo(base.dx + h * .02, base.dy - h * .03)
        ..lineTo(base.dx - h * .1, base.dy - h * .01)
        ..close(),
      Paint()..color = rockLit,
    );
    c.drawRect(
      Rect.fromLTRB(
        base.dx - h * .1,
        base.dy - h * .085,
        base.dx + h * .08,
        base.dy - h * .068,
      ),
      Paint()..color = grass,
    );
    // Keeper's cottage.
    c.drawRect(
      Rect.fromLTRB(
        base.dx + h * .02,
        base.dy - h * .115,
        base.dx + h * .08,
        base.dy - h * .075,
      ),
      Paint()..color = const Color(0xfff4efe8),
    );
    c.drawPath(
      Sketch.poly([.015, -.113, .05, -.14, .085, -.113], at: base, s: h),
      Paint()..color = const Color(0xffc9483e),
    );
    // Tapered tower with red bands, gallery and lantern.
    final foot = base.dy - h * .075, head = base.dy - h * .215;
    final tower = Sketch.poly([
      base.dx - h * .028, foot, base.dx - h * .018, head, //
      base.dx + h * .018, head, base.dx + h * .028, foot,
    ]);
    c.drawPath(tower, Paint()..color = const Color(0xfff7f2ea));
    c.save();
    c.clipPath(tower);
    for (var k = 0; k < 2; k++) {
      final y = foot - (foot - head) * (.22 + k * .4);
      c.drawRect(
        Rect.fromLTRB(base.dx - h * .04, y - h * .022, base.dx + h * .04, y),
        Paint()..color = const Color(0xffd84a3c),
      );
    }
    c.drawRect(
      Rect.fromLTRB(base.dx + h * .006, head, base.dx + h * .04, foot),
      Paint()..color = const Color(0x22203050),
    );
    c.restore();
    c.drawRect(
      Rect.fromLTRB(
        base.dx - h * .026,
        head - h * .006,
        base.dx + h * .026,
        head,
      ),
      Paint()..color = const Color(0xff39394a),
    );
    c.drawRect(
      Rect.fromLTRB(
        base.dx - h * .014,
        head - h * .028,
        base.dx + h * .014,
        head - h * .006,
      ),
      Paint()..color = const Color(0xfffff0b8),
    );
    c.drawPath(
      Sketch.poly(
        [-.018, -.028, 0, -.045, .018, -.028],
        at: Offset(base.dx, head),
        s: h,
      ),
      Paint()..color = const Color(0xffc9483e),
    );
  }

  static void _spout(Canvas c, Offset at, double tall, double alpha) {
    if (tall <= 0) return;
    final mist = Paint()
      ..color = Sketch.fade(const Color(0xffffffff), .55 * alpha);
    for (var k = 0; k < 4; k++) {
      c.drawCircle(
        at + Offset((k - 1.5) * tall * .12, -tall * (.5 + k * .15)),
        tall * (.18 + k * .04),
        mist,
      );
    }
  }

  static void _fluke(Canvas c, Offset at, double s, double k) {
    const skin = Color(0xff3d4d63), belly = Color(0xffe8edf2);
    c.drawPath(
      Path()
        ..moveTo(at.dx - s * .08, at.dy + s)
        ..lineTo(at.dx - s * .06, at.dy - s * .2)
        ..quadraticBezierTo(
          at.dx - s * .6,
          at.dy - s * .3,
          at.dx - s * .95,
          at.dy - s * .7,
        )
        ..quadraticBezierTo(
          at.dx - s * .4,
          at.dy - s * .45,
          at.dx,
          at.dy - s * .5,
        )
        ..quadraticBezierTo(
          at.dx + s * .4,
          at.dy - s * .45,
          at.dx + s * .95,
          at.dy - s * .7,
        )
        ..quadraticBezierTo(
          at.dx + s * .6,
          at.dy - s * .3,
          at.dx + s * .06,
          at.dy - s * .2,
        )
        ..lineTo(at.dx + s * .08, at.dy + s)
        ..close(),
      Paint()..color = skin,
    );
    c.drawPath(
      Path()
        ..moveTo(at.dx - s * .08, at.dy - s * .3)
        ..quadraticBezierTo(
          at.dx - s * .5,
          at.dy - s * .38,
          at.dx - s * .8,
          at.dy - s * .62,
        )
        ..quadraticBezierTo(
          at.dx - s * .35,
          at.dy - s * .44,
          at.dx - s * .02,
          at.dy - s * .46,
        )
        ..close(),
      Paint()..color = belly,
    );
    // Water streams off the trailing edge.
    final drip = Paint()
      ..color = const Color(0xaaffffff)
      ..strokeWidth = s * .03;
    for (var i = 0; i < 4; i++) {
      final x = at.dx - s * .8 + i * s * .5;
      c.drawLine(
        Offset(x, at.dy - s * .6),
        Offset(x, at.dy - s * .6 + s * .5 * k),
        drip,
      );
    }
  }

  static void _buoy(Canvas c, Offset base, double s, double tilt) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(tilt);
    c.drawPath(
      Sketch.poly([-.5, 0, -.3, -1.1, .3, -1.1, .5, 0], s: s),
      Paint()..color = const Color(0xffd8453a),
    );
    c.drawRect(
      Rect.fromLTRB(-s * .42, -s * .7, s * .42, -s * .45),
      Paint()..color = const Color(0xfff6f1e8),
    );
    c.drawRect(
      Rect.fromLTRB(-s * .08, -s * 1.5, s * .08, -s * 1.1),
      Paint()..color = const Color(0xff39394a),
    );
    c.drawCircle(
      Offset(0, -s * 1.55),
      s * .12,
      Paint()..color = const Color(0xffffe08a),
    );
    c.drawRect(
      Rect.fromLTRB(-s * .6, -s * .05, s * .6, s * .2),
      Paint()..color = const Color(0xff39394a),
    );
    c.restore();
  }
}
