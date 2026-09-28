import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// Egypt at a hot, clear afternoon: the Giza pyramids and the Sphinx on the
/// desert horizon, a temple pylon flanked by obelisks on the dunes, the Nile
/// lined with date palms and green fields, feluccas under lateen sails and
/// papyrus on the near bank. Wind-blown sand and heat shimmer.
class EgyptScene extends RegionScene {
  const EgyptScene();

  @override
  WorldRegion get region => WorldRegion.egypt;

  @override
  double get horizon => .66;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.8, .19),
    radius: .058,
    disc: Color(0xfffffcf0),
    glow: Color(0xffffe6a3),
    halo: .5,
    strength: .46,
  );

  static final _weather = Weather(Weather.of([(Mote.sand, 22)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xfff1cf9c);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xfff0d7a8),
      Color(0xffe9c793),
      Color(0xfffcebc9),
      rimWidth: .003,
    ),
    Depth.mid => const Ground(
      Color(0xffebc187),
      Color(0xffdfaa6c),
      Color(0xfffbe3b6),
      rimWidth: .004,
    ),
    Depth.low => const Ground(
      Color(0xff78b8bd),
      Color(0xff4f96a6),
      Color(0xffd6f0e6),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xffe3b374),
      Color(0xffc98e52),
      Color(0xfff8d9a6),
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far =>
      .646 + Sketch.waves(x, const [(3.1, .008, .4), (1.3, .004, 2.1)]),
    Depth.mid => .745 - .038 * dune(x / 1.7 + .2) - .014 * dune(x / .7 + .5),
    Depth.low => .806 + Sketch.waves(x, const [(.8, .0015, 0)]),
    Depth.near => .93 - .034 * dune(x / 1.6) - .012 * dune(x / .8 + .3),
  };

  @override
  double period(Depth d) => d == Depth.low ? 2.4 : 3.2;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .3,
    Depth.mid => .32,
    Depth.low => .22,
    Depth.near => .5,
  };

  /// A dune profile in 0..1: a long windward slope up to a sharp crest and a
  /// short slip face down, repeating every unit.
  static double dune(double x) {
    final p = x - x.floorToDouble();
    final v = p < .72 ? p / .72 : (1 - p) / .28;
    return v * v * (3 - 2 * v);
  }

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _pyramids(c, w * .56, h);
      case Depth.mid:
        _temple(c, w * .17, h);
        for (final (fx, s) in const [(.47, 1.0), (.52, .82), (.9, .9)]) {
          _duneTuft(c, Offset(w * fx, h * .73), h * .03 * s);
        }
      case Depth.low:
        _bank(c, h);
      case Depth.near:
        for (final (fx, s) in const [
          (.06, .9),
          (.4, 1.1),
          (.58, .8),
          (.86, 1),
        ]) {
          _papyrus(c, Offset(period(d) * h * fx, h * .95), h * .12 * s);
        }
        final palm = Offset(period(d) * h * .7, h * .95);
        Sketch.palm(
          c,
          palm,
          h * .44,
          lean: -.08,
          trunk: const Color(0xffa27451),
          trunkShade: const Color(0xff7d5739),
          frond: const Color(0xff5c8a4c),
          frondLit: const Color(0xff84ac60),
          dates: true,
        );
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d != Depth.near) return;
    final h = f.h;
    // One felucca per repeat, gliding a little faster than the bank.
    final bob = math.sin(f.clock * 1.3 + copy) * h * .003;
    // Wrapping inside the repeat hands the boat to the next copy seamlessly.
    final x = (h * .6 - f.clock * h * .006) % (period(d) * h);
    _felucca(c, Offset(x, h * .872 + bob), h * .06, copy.isEven);
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h, time = f.clock;
    switch (d) {
      case Depth.far:
        // Heat shimmer: faint, wavering lines just above the horizon dunes.
        final shimmer = Paint()
          ..strokeWidth = h * .003
          ..strokeCap = StrokeCap.round
          ..color = Sketch.fade(const Color(0xfffff3da), .26 * presence);
        for (var i = 0; i < 16; i++) {
          final x = (f.w + h) * Sketch.hash(i + 80) - h * .3;
          final y = h * (.62 + .022 * Sketch.hash(i + 90));
          final wobble = math.sin(time * (2.2 + i * .3) + i * 2);
          final len =
              h * (.03 + .03 * Sketch.hash(i + 99)) * (.6 + .4 * wobble);
          c.drawLine(
            Offset(x - len, y + wobble * h * .002),
            Offset(x + len, y - wobble * h * .002),
            shimmer,
          );
        }
      case Depth.low:
        // Sun glints dance on the Nile.
        final glint = Paint()
          ..color = Sketch.fade(const Color(0xfffff6dc), .7 * presence)
          ..strokeWidth = h * .0035
          ..strokeCap = StrokeCap.round;
        final span = period(d) * h;
        for (var i = 0; i < 9; i++) {
          final phase = time * (1.1 + i * .13) + i * 2.1;
          final on = .5 + .5 * math.sin(phase);
          if (on < .3) continue;
          final x = span * Sketch.hash(i + 40);
          final y = h * (.82 + .06 * Sketch.hash(i + 60));
          final len = h * .02 * on;
          c.drawLine(Offset(x - len, y), Offset(x + len, y), glint);
        }
      case Depth.near:
        _duneShade(c, d, h, 0, period(d) * h, 1.6, 0, presence * .8);
        // Wind ripples on the near dunes.
        final ripple = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .003
          ..strokeCap = StrokeCap.round
          ..color = Sketch.fade(const Color(0xfffae1b1), .55 * presence);
        final span = period(d) * h;
        for (var i = 0; i < 7; i++) {
          final x = span * (i + .3) / 7;
          final y = ridge(d, x / h, 0) * h + h * (.018 + .012 * (i % 3));
          c.drawPath(
            Path()
              ..moveTo(x - h * .05, y + h * .004)
              ..quadraticBezierTo(x, y - h * .006, x + h * .05, y + h * .003),
            ripple,
          );
        }
      case Depth.mid:
        _duneShade(c, d, h, -h * .4, f.w + h, 1.7, .2, presence);
    }
  }

  /// Shades the slip face of each large dune, from its crest to the trough.
  void _duneShade(
    Canvas c,
    Depth d,
    double h,
    double from,
    double to,
    double wave,
    double phase,
    double presence,
  ) {
    final shade = Paint()
      ..color = Sketch.fade(const Color(0xffc98f58), .32 * presence);
    final first = ((from / h) / wave + phase).floor();
    for (var k = first; (k - phase) * wave * h < to; k++) {
      final crest = (k + .72 - phase) * wave;
      final trough = (k + 1 - phase) * wave;
      // A lens hugging the slip face: the ridge, then the ridge pushed
      // down by a depth that swells mid-face and vanishes at both ends.
      final path = Path();
      for (var i = 0; i <= 10; i++) {
        final x = crest + (trough - crest) * i / 10;
        final y = ridge(d, x, 0) * h;
        if (i == 0) {
          path.moveTo(x * h, y);
        } else {
          path.lineTo(x * h, y);
        }
      }
      for (var i = 10; i >= 0; i--) {
        final x = crest + (trough - crest) * i / 10;
        final depth = math.sin(math.pi * math.pow(i / 10, .7)) * h * .035;
        path.lineTo(x * h, ridge(d, x, 0) * h + depth);
      }
      path.close();
      c.drawPath(path, shade);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // High cirrus streaks, barely there in the dry air.
    final streak = Paint()
      ..color = Sketch.fade(const Color(0xffffffff), .34 * presence);
    for (final (fx, fy, fw) in const [
      (.12, .12, .34),
      (.36, .07, .22),
      (.6, .3, .26),
    ]) {
      final drift = f.clock * h * .004;
      final x = (w * fx - drift) % (w + h) - h * .3;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, h * fy),
          width: h * fw,
          height: h * .012,
        ),
        streak,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + h * fw * .18, h * fy + h * .014),
          width: h * fw * .6,
          height: h * .008,
        ),
        streak,
      );
    }
    // Black kites wheel on the thermals.
    final kite = Sketch.fade(const Color(0xff6d5a4a), .55 * presence);
    for (var i = 0; i < 3; i++) {
      final a = f.clock * .35 + i * 2.1;
      final center = Offset(w * (.3 + i * .09), h * (.2 + i * .05));
      final p = center + Offset(math.cos(a) * h * .06, math.sin(a) * h * .02);
      Sketch.bird(
        c,
        p,
        h * (.014 - i * .002),
        kite,
        flap: math.sin(f.clock * 1.2 + i) * .3,
      );
    }
  }

  // ---------------------------------------------------------------------------

  static Color _hazed(Color c, double t) => Sketch.mix(c, _haze, t);

  /// Khufu, Khafre with its limestone cap, Menkaure and the queens'
  /// pyramids, lit from the right, with the Sphinx at their feet.
  static void _pyramids(Canvas c, double x0, double h) {
    const haze = .34;
    final lit = _hazed(const Color(0xfff6dfae), haze);
    final shade = _hazed(const Color(0xffcf9f6e), haze);
    final course = Sketch.fade(_hazed(const Color(0xffc49262), haze), .35);
    void pyramid(double x, double apex, double half, {bool cap = false}) {
      final base = h * .7;
      final top = Offset(x, apex * h);
      final edge = Offset(x + half * h * .28, base);
      c.drawPath(
        Sketch.poly([top.dx, top.dy, edge.dx, edge.dy, x - half * h, base]),
        Paint()..color = shade,
      );
      c.drawPath(
        Sketch.poly([top.dx, top.dy, x + half * h, base, edge.dx, edge.dy]),
        Paint()..color = lit,
      );
      // Courses of stone on the sunlit face give the monument its scale.
      final line = Paint()
        ..color = course
        ..strokeWidth = math.max(.6, h * .0016);
      final height = base - top.dy;
      for (var y = top.dy + h * .02; y < base; y += h * .013) {
        final k = (y - top.dy) / height;
        c.drawLine(
          Offset(top.dx + (edge.dx - top.dx) * k, y),
          Offset(top.dx + half * h * k, y),
          line,
        );
      }
      if (cap) {
        final k = .16;
        c.drawPath(
          Sketch.poly([
            top.dx,
            top.dy,
            top.dx + half * h * k,
            top.dy + height * k,
            top.dx + (edge.dx - top.dx) * k,
            top.dy + height * k,
            top.dx - half * h * k,
            top.dy + height * k,
          ]),
          Paint()..color = _hazed(const Color(0xfffff4dd), .2),
        );
      }
    }

    pyramid(x0 + h * .64, .59, .045);
    pyramid(x0 + h * .74, .6, .038);
    pyramid(x0 + h * .83, .605, .032);
    pyramid(x0 + h * .54, .52, .1);
    pyramid(x0 + h * .3, .425, .175, cap: true);
    pyramid(x0, .41, .19);
    _sphinx(c, Offset(x0 - h * .36, h * .652), h * .11, lit, shade);
  }

  static void _sphinx(Canvas c, Offset base, double s, Color lit, Color shade) {
    c.drawPath(
      Sketch.poly(
        const [
          0, .1, 0, -.16, .08, -.22, .5, -.22, .56, -.28, //
          .58, -.46, .64, -.52, .74, -.52, .8, -.46, .8, -.3,
          .86, -.26, .86, -.1, 1.12, -.08, 1.14, .1,
        ],
        at: base,
        s: s,
      ),
      Paint()..color = shade,
    );
    // Lit face, chest and forepaws.
    c.drawPath(
      Sketch.poly(
        const [
          .74, -.5, .8, -.46, .8, -.3, .86, -.26, .86, -.1, 1.12, -.08, //
          1.14, .02, .7, 0, .7, -.3,
        ],
        at: base,
        s: s,
      ),
      Paint()..color = lit,
    );
  }

  static void _temple(Canvas c, double x, double h) {
    const haze = .22;
    final lit = _hazed(const Color(0xfff0cf9c), haze);
    final face = _hazed(const Color(0xffe2b67c), haze);
    final shade = _hazed(const Color(0xffc48f5c), haze);
    final groove = _hazed(const Color(0xffb27d4d), haze);
    final base = h * .78;
    // Two battered pylon towers, the gate between them set back.
    for (final side in const [-1.0, 1.0]) {
      final cx = x + side * h * .1;
      final bottom = h * .13 / 2, top = h * .095 / 2;
      final crown = base - h * .2;
      final tower = Sketch.poly([
        cx - bottom,
        base,
        cx - top,
        crown,
        cx + top,
        crown,
        cx + bottom,
        base,
      ]);
      c.drawPath(tower, Paint()..color = face);
      c.drawPath(
        Sketch.poly([
          cx + top * .35,
          crown,
          cx + top,
          crown,
          cx + bottom,
          base,
          cx + bottom * .35,
          base,
        ]),
        Paint()..color = side < 0 ? shade : lit,
      );
      // Cavetto cornice and torus moulding along the crown.
      c.drawRect(
        Rect.fromLTRB(
          cx - top - h * .006,
          crown - h * .012,
          cx + top + h * .006,
          crown,
        ),
        Paint()..color = lit,
      );
      c.drawRect(
        Rect.fromLTRB(cx - top, crown, cx + top, crown + h * .004),
        Paint()..color = shade,
      );
      // Flagpole recesses.
      final pole = Paint()
        ..color = groove
        ..strokeWidth = h * .004;
      for (final f in const [-.45, .45]) {
        c.drawLine(
          Offset(cx + f * top, crown + h * .02),
          Offset(cx + f * bottom, base),
          pole,
        );
      }
    }
    c.drawRect(
      Rect.fromLTRB(x - h * .038, base - h * .13, x + h * .038, base),
      Paint()..color = shade,
    );
    c.drawRect(
      Rect.fromLTRB(
        x - h * .045,
        base - h * .142,
        x + h * .045,
        base - h * .124,
      ),
      Paint()..color = lit,
    );
    c.drawRect(
      Rect.fromLTRB(x - h * .018, base - h * .1, x + h * .018, base),
      Paint()..color = _hazed(const Color(0xff9c6b43), haze),
    );
    // A pair of obelisks before the gate.
    for (final side in const [-1.0, 1.0]) {
      _obelisk(
        c,
        Offset(x + side * h * .21, base + h * .01),
        h * .27,
        lit,
        shade,
      );
    }
  }

  static void _obelisk(
    Canvas c,
    Offset base,
    double height,
    Color lit,
    Color shade,
  ) {
    final half = height * .06, neck = height * .042;
    final shoulder = base.dy - height * .92;
    c.drawPath(
      Sketch.poly([
        base.dx - half,
        base.dy,
        base.dx - neck,
        shoulder,
        base.dx,
        base.dy - height,
        base.dx + neck,
        shoulder,
        base.dx + half,
        base.dy,
      ]),
      Paint()..color = shade,
    );
    c.drawPath(
      Sketch.poly([
        base.dx + half * .1,
        base.dy,
        base.dx + neck * .1,
        shoulder,
        base.dx,
        base.dy - height,
        base.dx + neck,
        shoulder,
        base.dx + half,
        base.dy,
      ]),
      Paint()..color = lit,
    );
    // The gilded pyramidion catches the sun.
    c.drawPath(
      Sketch.poly([
        base.dx,
        base.dy - height,
        base.dx + neck,
        shoulder,
        base.dx + neck * .1,
        shoulder,
      ]),
      Paint()..color = const Color(0xfff7d27a),
    );
  }

  static void _duneTuft(Canvas c, Offset at, double s) {
    final paint = Paint()
      ..color = _hazed(const Color(0xff9aa25c), .3)
      ..strokeWidth = s * .12
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      c.drawLine(at, at + Offset(i * s * .35, -s * (1 - i.abs() * .18)), paint);
    }
  }

  /// The far bank of the Nile: green fields and palm groves at the water.
  static void _bank(Canvas c, double h) {
    final span = 2.4 * h;
    final field = Path()..moveTo(0, h * .83);
    for (var x = 0.0; x <= span; x += h * .06) {
      final y =
          h * (.79 + .006 * math.sin(x / h * 11) + .004 * math.sin(x / h * 29));
      field.lineTo(x, y);
    }
    field
      ..lineTo(span, h * .83)
      ..close();
    c.drawPath(field, Paint()..color = const Color(0xff9dbb6c));
    c.drawRect(
      Rect.fromLTRB(0, h * .797, span, h * .83),
      Paint()..color = const Color(0xff86a95e),
    );
    for (var i = 0; i < 7; i++) {
      final x = span * (i + Sketch.hash(i + 5) * .6) / 7;
      final tall = .09 + .05 * Sketch.hash(i + 9);
      Sketch.palm(
        c,
        Offset(x, h * .81),
        h * tall,
        lean: (Sketch.hash(i + 21) - .5) * .2,
        trunk: const Color(0xffb48c68),
        trunkShade: const Color(0xff9a7456),
        frond: const Color(0xff6f9a5a),
        frondLit: const Color(0xff8fb46a),
        detail: false,
      );
    }
  }

  /// A papyrus clump: tall stalks crowned by loose, mop-headed umbels.
  static void _papyrus(Canvas c, Offset base, double height) {
    final stem = Paint()
      ..color = const Color(0xff5f8f46)
      ..strokeWidth = math.max(1.0, height * .022)
      ..strokeCap = StrokeCap.round;
    final ray = Paint()
      ..strokeWidth = math.max(.8, height * .014)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final lean = (i - 2.5) * .13;
      final tall = height * (1 - (i - 2.5).abs() * .1);
      final top = base + Offset(lean * height * .9, -tall);
      c.drawLine(base, top, stem);
      ray.color = i.isEven ? const Color(0xff8fb65a) : const Color(0xffb3cd6c);
      final reach = height * (.2 + .03 * (i % 2));
      for (var k = 0; k < 9; k++) {
        final a = -math.pi * (.08 + .84 * k / 8) + lean * .5;
        final droop = (k - 4).abs() / 4;
        c.drawLine(
          top,
          top +
              Offset(
                math.cos(a) * reach,
                math.sin(a) * reach * (1 - droop * .5) + droop * reach * .25,
              ),
          ray,
        );
      }
    }
  }

  static void _felucca(Canvas c, Offset at, double s, bool flip) {
    c.save();
    c.translate(at.dx, at.dy);
    if (flip) c.scale(-1, 1);
    // Hull, then the tall lateen sail on its slanted yard.
    final hull = Path()
      ..moveTo(-s * .9, -s * .12)
      ..quadraticBezierTo(-s * .6, s * .14, 0, s * .14)
      ..quadraticBezierTo(s * .7, s * .14, s, -s * .16)
      ..close();
    c.drawPath(hull, Paint()..color = const Color(0xff7a4f35));
    c.drawRect(
      Rect.fromLTRB(-s * .8, -s * .13, s * .9, -s * .08),
      Paint()..color = const Color(0xff2f6f8f),
    );
    final mast = Offset(-s * .05, -s * .12);
    final wood = Paint()
      ..color = const Color(0xff6b4a33)
      ..strokeWidth = s * .05;
    c.drawLine(mast, mast + Offset(0, -s * 1.3), wood);
    final peak = mast + Offset(s * .55, -s * 2.05);
    final clew = mast + Offset(s * .5, -s * .12);
    c.drawPath(
      Path()
        ..moveTo(mast.dx - s * .75, mast.dy - s * .15)
        ..lineTo(peak.dx, peak.dy)
        ..quadraticBezierTo(
          mast.dx + s * .75,
          mast.dy - s * .9,
          clew.dx,
          clew.dy,
        )
        ..close(),
      Paint()..color = const Color(0xfffffaf0),
    );
    // The sail's belly falls into shade toward its leech.
    c.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..quadraticBezierTo(
          mast.dx + s * .75,
          mast.dy - s * .9,
          clew.dx,
          clew.dy,
        )
        ..lineTo(mast.dx + s * .18, mast.dy - s * .14)
        ..quadraticBezierTo(
          mast.dx + s * .42,
          mast.dy - s * .9,
          peak.dx,
          peak.dy,
        )
        ..close(),
      Paint()..color = const Color(0xffe8dcc6),
    );
    c.drawLine(
      Offset(mast.dx - s * .8, mast.dy - s * .12),
      peak + Offset(s * .03, -s * .05),
      wood..strokeWidth = s * .035,
    );
    // Reflection ripples under the hull.
    final ripple = Paint()
      ..color = const Color(0x55ffffff)
      ..strokeWidth = s * .04
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(-s * .7, s * .24), Offset(s * .5, s * .24), ripple);
    c.drawLine(Offset(-s * .3, s * .34), Offset(s * .2, s * .34), ripple);
    c.restore();
  }
}
