import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'weather.dart';
import 'world_region.dart';

/// A material in three lights: sunlit (the right, where the sun rises), the
/// face turned to the viewer, and the shadow side.
typedef _Tone = (Color lit, Color face, Color shade);

/// The dawn palette of the city's plaster, stone, tile and cloth, tinted by
/// [haze] toward the rose horizon so distance reads.
class _Clay {
  _Clay(this.haze)
    : rose = (_t(0xfff9c9a0, haze), _t(0xffcf9088, haze), _t(0xff9c6c84, haze)),
      ochre = (
        _t(0xfffcd49a, haze),
        _t(0xffd6a082, haze),
        _t(0xff9e7078, haze),
      ),
      white = (
        _t(0xfffff0dc, haze),
        _t(0xffe2cbcc, haze),
        _t(0xffa893ac, haze),
      ),
      tile = (_t(0xff93e0d2, haze), _t(0xff26999f, haze), _t(0xff195e74, haze)),
      gilt = (_t(0xffffe7a0, haze), _t(0xffdea44a, haze), _t(0xff9a623e, haze)),
      rock = (_t(0xfff0b08a, haze), _t(0xffbc7c76, haze), _t(0xff7e5068, haze)),
      deep = _t(0xff5a3c58, haze),
      dark = _t(0xff3a2842, haze),
      lamp = _t(0xffffd27c, haze * .5),
      wood = _t(0xff74463c, haze),
      woodLit = _t(0xffb2784e, haze),
      madder = _t(0xffc0413c, haze),
      saffron = _t(0xffeeae38, haze),
      indigo = _t(0xff3b4a92, haze),
      frond = _t(0xff365e54, haze),
      frondLit = _t(0xff74a06a, haze),
      trunk = _t(0xff8a5c4c, haze),
      trunkShade = _t(0xff5a3e50, haze);

  final double haze;
  final _Tone rose, ochre, white, tile, gilt, rock;
  final Color deep, dark, lamp, wood, woodLit, madder, saffron, indigo;
  final Color frond, frondLit, trunk, trunkShade;

  static Color _t(int argb, double t) =>
      Sketch.mix(Color(argb), ArabiaScene._haze, t);
}

/// Ancient Arabia at first light. A teal sky still holds the crescent moon,
/// the morning star and the last stars while the sun rises behind the city in
/// a rose-gold haze, with a flying carpet far off. Sandstone jebels and a
/// hill fort stand in the far haze. The walled caravan city climbs its tell
/// behind a great gate of ablaq voussoirs: backlit houses of mud plaster
/// stacked roof over roof with wind towers, wooden bays and a few lamps still
/// burning, a turquoise dome between two minarets, and a citadel on its rock.
/// Orchards and a road lie outside the walls; below them a palm oasis with
/// its pool, a souk under dyed awnings, a caravanserai with couched camels
/// and Bedouin tents; and a camel caravan crosses the rose dunes in front.
/// Banners stir, doves circle the minaret, smoke curls from the roofs and
/// sand blows off the crests.
class ArabiaScene extends RegionScene {
  const ArabiaScene();

  @override
  WorldRegion get region => WorldRegion.arabia;

  @override
  double get horizon => .62;

  static const _sunAt = Offset(.82, .44);

  @override
  SkyLight get light => const SkyLight(
    at: _sunAt,
    radius: .068,
    disc: Color(0xfffff2d8),
    glow: Color(0xffffb48c),
    halo: .74,
    strength: .62,
  );

  static final _weather = Weather(Weather.of([(Mote.sand, 14)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffeec3b4);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xffe8bcac),
      Color(0xffdcab9e),
      Color(0xfffadccc),
      rimWidth: .002,
    ),
    Depth.mid => const Ground(
      Color(0xffdba38e),
      Color(0xffc98e80),
      Color(0xfff7d3bd),
      rimWidth: .003,
    ),
    Depth.low => const Ground(
      Color(0xffd89c76),
      Color(0xffc08264),
      Color(0xfff3cca2),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xffecac86),
      Color(0xffc97c66),
      Color(0xffffdcbc),
      rimWidth: .004,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far =>
      .668 + Sketch.waves(x, const [(3.3, .004, .2), (1.4, .002, 1.1)]),
    Depth.mid =>
      .752 + Sketch.waves(x, const [(2.9, .005, .5), (1.2, .002, 1.7)]),
    // The repeating bands use waves and dunes that divide their period, so
    // the terrain tiles seamlessly.
    Depth.low =>
      .836 +
          Sketch.waves(x, const [
            (3.2, .005, .4),
            (1.6, .003, 1.9),
            (.8, .0012, .3),
          ]),
    Depth.near =>
      .958 -
          .046 * _dune(x / 1.6, 2) -
          .014 * _dune(x / .8 + .3, 4) -
          .005 * _dune(x / .4 + .6, 8),
  };

  @override
  double period(Depth d) => 3.2;

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .34,
    // The Mamluk minaret's finial stands about .45 h over the mid ridge.
    Depth.mid => .5,
    Depth.low => .32,
    Depth.near => .5,
  };

  static double _smooth(double x) {
    if (!(x > 0)) return 0;
    if (x >= 1) return 1;
    return x * x * (3 - 2 * x);
  }

  /// A dune in 0..1 repeating every unit: a steep slip face climbs to a
  /// rounded brink, then the long windward back falls toward the sun. Each
  /// dune gets its own height and brink; [wrap] repeats those seeds so a
  /// scrolled band tiles.
  static double _dune(double x, int wrap) {
    final k = x.floor();
    final p = x - k;
    final s = ((k % wrap) + wrap) % wrap;
    final brink = .26 + .12 * Sketch.hash(s + 71);
    final tall = .68 + .32 * Sketch.hash(s + 13);
    final double v;
    if (p < brink) {
      final u = p / brink;
      v = math.pow(u, 1.6) * (1.6 - .6 * u);
    } else {
      final u = (p - brink) / (1 - brink);
      v = 1 - u * u * (3 - 2 * u);
    }
    return v * tall;
  }

  double _y(Depth d, double x, double h) => ridge(d, x / h, 0) * h;

  static Paint _fill(Color c) => Paint()..color = c;

  /// A left-to-right sweep of [colors] across [r], evenly spaced.
  static Paint _sweep(Rect r, List<Color> colors) => Paint()
    ..shader = Gradient.linear(r.centerLeft, r.centerRight, colors, [
      for (var i = 0; i < colors.length; i++) i / (colors.length - 1),
    ]);

  static Paint _pen(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ---------------------------------------------------------------------------
  // Layout shared by the city's features and its live details.

  /// Scale of the city's landmarks: narrower screens get them a little
  /// smaller so they stay apart.
  static double _cityK(double w, double h) => (w / (h * 2.1)).clamp(.8, 1.0);
  static double _gateX(double w) => w * .3;
  static double _mosqueX(double w) => w * .6;
  static double _citadelX(double w, double h) =>
      math.max(w * .95, _mosqueX(w) + h * .62);
  static double _mosqueS(double w, double h) => h * .085 * _cityK(w, h);
  Offset _mosqueBase(double w, double h) {
    final x = _mosqueX(w);
    return Offset(x, _y(Depth.mid, x, h) - h * (.06 + _tell(x, w, h)));
  }

  /// Lamplit windows of the mid band, filled while its picture is recorded
  /// and read by `live` to make them flicker.
  static final _cityLamps = <(double, double), List<Offset>>{};

  /// Banner poles of the mid band as (top of pole, size).
  static final _cityBanners = <(double, double), List<(Offset, double)>>{};

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _farDesert(c, w, h);
      case Depth.mid:
        _city(c, w, h);
      case Depth.low:
        _oasis(c, h, period(d) * h);
      case Depth.near:
        _nearDunes(c, h, period(d) * h);
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    switch (d) {
      case Depth.far:
        _farLive(c, f);
      case Depth.mid:
        _cityLive(c, f);
      case Depth.low:
        _oasisLive(c, f);
      case Depth.near:
        _caravanLive(c, f);
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(
            center: Offset(f.w * .5 + h * .1, h * .672),
            width: f.w + h * 1.4,
            height: h * .07,
          ),
          const Color(0xfffbe0d0),
          .55 * presence,
        );
      case Depth.mid:
        _faded(c, _approachArt(f.w, h), presence);
        // Dawn mist pooled at the foot of the city walls.
        Sketch.mist(
          c,
          Rect.fromCenter(
            center: Offset(f.w * .5 + h * .2, h * .758),
            width: f.w + h * 1.6,
            height: h * .075,
          ),
          const Color(0xfff9dcd0),
          .7 * presence,
        );
      case Depth.low:
        _oasisOverlay(c, f, presence);
      case Depth.near:
        _nearOverlay(c, f, presence);
    }
  }

  // ---------------------------------------------------------------------------
  // Shared architecture.

  /// A pointed arch as a path: sides rise from [bottom] to the springing at
  /// [spring], then two curves meet at a point [hw] * (1 + [point]) above it.
  /// [shoe] (0..1) pinches the jambs inward below the springing, the
  /// horseshoe of Arab arches.
  static Path _arch(
    double cx,
    double hw,
    double spring,
    double bottom, {
    double point = .3,
    double shoe = 0,
  }) {
    final jamb = hw * (1 - shoe * .22);
    final apex = spring - hw * (1 + point);
    return Path()
      ..moveTo(cx - jamb, bottom)
      ..lineTo(cx - jamb, spring + hw * shoe * .2)
      ..cubicTo(
        cx - hw * (1 + shoe * .06),
        spring - hw * .1,
        cx - hw * .98,
        spring - hw * .7,
        cx - hw * .4,
        spring - hw * (.98 + point * .6),
      )
      ..quadraticBezierTo(cx - hw * .14, apex + hw * .1, cx, apex)
      ..quadraticBezierTo(
        cx + hw * .14,
        apex + hw * .1,
        cx + hw * .4,
        spring - hw * (.98 + point * .6),
      )
      ..cubicTo(
        cx + hw * .98,
        spring - hw * .7,
        cx + hw * (1 + shoe * .06),
        spring - hw * .1,
        cx + jamb,
        spring + hw * shoe * .2,
      )
      ..lineTo(cx + jamb, bottom)
      ..close();
  }

  /// A row of stepped merlons standing on [top] from [x0] to [x1]: small
  /// three-step crowns [s] tall with a gap between, lit on the right.
  static void _merlons(
    Canvas c,
    double x0,
    double x1,
    double Function(double x) top,
    double s,
    Color body,
    Color lit,
  ) {
    if (!(s > .6) || x1 <= x0) return;
    final pitch = s * 1.25;
    final n = ((x1 - x0) / pitch).floor();
    if (n < 1) return;
    final start = x0 + (x1 - x0 - n * pitch) / 2 + pitch / 2;
    final path = Path(), light = Path();
    for (var i = 0; i < n; i++) {
      final x = start + i * pitch, y = top(x);
      final a = s * .42, b = s * .28, e = s * .14;
      path.addPath(
        Sketch.poly([
          x - a, y + 1, x - a, y - s * .45, x - b, y - s * .45, //
          x - b, y - s * .75, x - e, y - s * .75, x - e, y - s,
          x + e, y - s, x + e, y - s * .75, x + b, y - s * .75,
          x + b, y - s * .45, x + a, y - s * .45, x + a, y + 1,
        ]),
        Offset.zero,
      );
      light.addPath(
        Sketch.poly([
          x + e * .2, y + 1, x + e * .2, y - s, x + e, y - s, //
          x + e, y - s * .75, x + b, y - s * .75, x + b, y - s * .45,
          x + a, y - s * .45, x + a, y + 1,
        ]),
        Offset.zero,
      );
    }
    c.drawPath(path, _fill(body));
    c.drawPath(light, _fill(lit));
  }

  /// An onion dome standing on [base], [hw] half wide where it springs and
  /// [height] to the tip, bulging past its drum and pinching to a point.
  static Path _onion(Offset base, double hw, double height) {
    final x = base.dx, y = base.dy, hh = height;
    return Path()
      ..moveTo(x - hw, y)
      ..cubicTo(
        x - hw * 1.52,
        y - hh * .12,
        x - hw * 1.3,
        y - hh * .62,
        x - hw * .52,
        y - hh * .74,
      )
      ..cubicTo(x - hw * .2, y - hh * .8, x - hw * .05, y - hh * .9, x, y - hh)
      ..cubicTo(
        x + hw * .05,
        y - hh * .9,
        x + hw * .2,
        y - hh * .8,
        x + hw * .52,
        y - hh * .74,
      )
      ..cubicTo(
        x + hw * 1.3,
        y - hh * .62,
        x + hw * 1.52,
        y - hh * .12,
        x + hw,
        y,
      )
      ..close();
  }

  /// A dome of [style] 0 (turquoise onion, ribbed), 1 (gilded onion) or 2
  /// (whitewashed melon), lit from the right, with a finial.
  static void _dome(
    Canvas c,
    Offset base,
    double hw,
    double height,
    int style,
    _Clay ink,
  ) {
    final (lit, face, shade) = switch (style) {
      0 => ink.tile,
      1 => ink.gilt,
      _ => ink.white,
    };
    final shape = style == 2
        ? (Path()
            ..moveTo(base.dx - hw, base.dy)
            ..cubicTo(
              base.dx - hw,
              base.dy - height * .7,
              base.dx - hw * .4,
              base.dy - height,
              base.dx,
              base.dy - height,
            )
            ..cubicTo(
              base.dx + hw * .4,
              base.dy - height,
              base.dx + hw,
              base.dy - height * .7,
              base.dx + hw,
              base.dy,
            )
            ..close())
        : _onion(base, hw, height);
    c.drawPath(shape, _fill(face));
    c.save();
    c.clipPath(shape);
    // The shadow side, then the lit crescent facing the sun.
    c.drawPath(
      Path()
        ..moveTo(base.dx - hw * 1.6, base.dy)
        ..lineTo(base.dx - hw * 1.6, base.dy - height)
        ..lineTo(base.dx - hw * .1, base.dy - height)
        ..cubicTo(
          base.dx - hw * .6,
          base.dy - height * .7,
          base.dx - hw * .8,
          base.dy - height * .3,
          base.dx - hw * .55,
          base.dy,
        )
        ..close(),
      _fill(shade),
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx + hw * 1.6, base.dy)
        ..lineTo(base.dx + hw * 1.6, base.dy - height)
        ..lineTo(base.dx + hw * .1, base.dy - height)
        ..cubicTo(
          base.dx + hw * .55,
          base.dy - height * .7,
          base.dx + hw * .7,
          base.dy - height * .3,
          base.dx + hw * .5,
          base.dy,
        )
        ..close(),
      _fill(lit),
    );
    if (style != 1) {
      // Ribs follow the profile, squeezed toward the edges.
      final rib = _pen(
        Sketch.mix(face, ink.dark, .35),
        math.max(.5, hw * .045),
      );
      for (final k in const [-.72, -.36, 0.0, .36, .72]) {
        final p = Path()..moveTo(base.dx + hw * k * 1.05, base.dy);
        p.quadraticBezierTo(
          base.dx + hw * k * 1.5,
          base.dy - height * .5,
          base.dx,
          base.dy - height,
        );
        c.drawPath(p, rib);
      }
    }
    // A glint where the sun catches the curve.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx + hw * .62, base.dy - height * .42),
        width: hw * .22,
        height: height * .3,
      ),
      _fill(Sketch.fade(const Color(0xffffffff), .35)),
    );
    c.restore();
    // A band of tile or gilt where the dome springs.
    c.drawRect(
      Rect.fromLTRB(
        base.dx - hw * 1.02,
        base.dy - height * .05,
        base.dx + hw * 1.02,
        base.dy,
      ),
      _fill(style == 0 ? ink.gilt.$2 : ink.tile.$3),
    );
    _finial(c, Offset(base.dx, base.dy - height), height * .38, ink);
  }

  /// A gilt finial: a spike threaded with balls under a small crescent.
  static void _finial(Canvas c, Offset at, double len, _Clay ink) {
    final gold = ink.gilt.$2, lit = ink.gilt.$1;
    c.drawLine(at, at - Offset(0, len), _pen(gold, math.max(.7, len * .06)));
    for (final (k, r) in const [(.22, .1), (.46, .08)]) {
      c.drawCircle(at - Offset(0, len * k), len * r, _fill(gold));
      c.drawCircle(
        at - Offset(-len * r * .3, len * k + len * r * .3),
        len * r * .4,
        _fill(lit),
      );
    }
    final moon = at - Offset(0, len * .86);
    final r = len * .13;
    c.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: r)),
        Path()..addOval(
          Rect.fromCircle(center: moon + Offset(0, -r * .45), radius: r * .88),
        ),
      ),
      _fill(gold),
    );
  }

  /// A minaret of [style] 0 (a Mamluk tower: square shaft, octagon and a
  /// columned lantern under a bulb) or 1 (a square Maghrebi tower with a
  /// carved lattice panel and a small domed lantern). [base] is its foot.
  static void _minaret(
    Canvas c,
    Offset base,
    double height,
    double width,
    int style,
    _Clay ink,
    List<Offset> lamps,
  ) {
    final (lit, face, shade) = ink.white;
    final x = base.dx, y = base.dy, hh = height, mw = width;
    void shaft(double y0, double y1, double half) {
      c.drawRect(Rect.fromLTRB(x - half, y1, x + half, y0), _fill(face));
      c.drawRect(Rect.fromLTRB(x + half * .35, y1, x + half, y0), _fill(lit));
      c.drawRect(
        Rect.fromLTRB(x - half, y1, x - half * .72, y0),
        _fill(Sketch.fade(shade, .8)),
      );
    }

    /// A balcony on corbels of stalactite vaulting, with a railing.
    void balcony(double yb, double half) {
      final step = hh * .012;
      for (var i = 0; i < 3; i++) {
        final r = Rect.fromLTRB(
          x - half - i * mw * .07,
          yb - step * (i + 1),
          x + half + i * mw * .07,
          yb - step * i,
        );
        c.drawRect(r, _fill(i.isEven ? face : shade));
        // Tiny niches of the muqarnas.
        final n = math.max(2, (r.width / (mw * .16)).floor());
        for (var k = 0; k < n; k++) {
          final cx = r.left + r.width * (k + .5) / n;
          c.drawCircle(
            Offset(cx, r.bottom),
            r.height * .45,
            _fill(Sketch.fade(ink.deep, .45)),
          );
        }
      }
      final top = yb - step * 3;
      final rail = Rect.fromLTRB(
        x - half - mw * .2,
        top - hh * .03,
        x + half + mw * .2,
        top,
      );
      c.drawRect(rail, _fill(face));
      c.drawRect(
        Rect.fromLTRB(
          rail.right - rail.width * .3,
          rail.top,
          rail.right,
          rail.bottom,
        ),
        _fill(lit),
      );
      final bar = _pen(Sketch.fade(ink.deep, .6), math.max(.5, mw * .03));
      for (var k = 1; k < 6; k++) {
        final bx = rail.left + rail.width * k / 6;
        c.drawLine(
          Offset(bx, rail.top + rail.height * .25),
          Offset(bx, rail.bottom - rail.height * .15),
          bar,
        );
      }
      c.drawRect(
        Rect.fromLTRB(
          rail.left,
          rail.top,
          rail.right,
          rail.top + rail.height * .2,
        ),
        _fill(lit),
      );
    }

    if (style == 0) {
      final b1 = y - hh * .42, b2 = y - hh * .68;
      shaft(y, b1, mw / 2);
      // A tall panel with a pointed niche and a tile band.
      c.drawPath(
        _arch(x, mw * .16, y - hh * .3, y - hh * .12, point: .5),
        _fill(ink.deep),
      );
      c.drawRect(
        Rect.fromLTRB(x - mw / 2, b1 + hh * .03, x + mw / 2, b1 + hh * .05),
        _fill(ink.tile.$2),
      );
      balcony(b1, mw / 2);
      final top1 = b1 - hh * .066;
      shaft(top1, b2, mw * .38);
      for (final k in const [.3, .62]) {
        final wy = top1 - (top1 - b2) * k;
        c.drawPath(
          _arch(x, mw * .08, wy - hh * .02, wy + hh * .02, point: .5),
          _fill(ink.deep),
        );
      }
      balcony(b2, mw * .38);
      final top2 = b2 - hh * .066;
      // The open lantern: slim columns around a lamp.
      final lanternTop = top2 - hh * .1;
      c.drawRect(
        Rect.fromLTRB(x - mw * .28, lanternTop, x + mw * .28, top2),
        _fill(ink.deep),
      );
      c.drawRect(
        Rect.fromLTRB(x - mw * .16, lanternTop + hh * .02, x + mw * .16, top2),
        _fill(Sketch.fade(ink.lamp, .85)),
      );
      lamps.add(Offset(x, (lanternTop + top2) / 2));
      for (final k in const [-.28, -.02, .22]) {
        c.drawRect(
          Rect.fromLTRB(x + mw * k, lanternTop, x + mw * (k + .06), top2),
          _fill(k > 0 ? lit : face),
        );
      }
      c.drawRect(
        Rect.fromLTRB(
          x - mw * .34,
          lanternTop - hh * .012,
          x + mw * .34,
          lanternTop,
        ),
        _fill(face),
      );
      _dome(c, Offset(x, lanternTop - hh * .012), mw * .3, hh * .12, 0, ink);
    } else {
      final top = y - hh * .8;
      shaft(y, top, mw / 2);
      // Small windows low down, a carved lattice panel high up.
      for (final k in const [.18, .34, .5]) {
        final wy = y - hh * k;
        c.drawPath(
          _arch(
            x - mw * .05,
            mw * .07,
            wy - hh * .015,
            wy + hh * .02,
            point: .4,
            shoe: .6,
          ),
          _fill(ink.deep),
        );
      }
      final panel = Rect.fromLTRB(
        x - mw * .36,
        top + hh * .08,
        x + mw * .36,
        top + hh * .22,
      );
      c.drawRect(panel, _fill(Sketch.mix(face, shade, .45)));
      final net = _pen(Sketch.mix(shade, ink.deep, .3), math.max(.5, mw * .03));
      c.save();
      c.clipRect(panel);
      for (var k = -3; k <= 3; k++) {
        final dx = panel.width * k / 3;
        c.drawLine(
          Offset(panel.left + dx, panel.bottom),
          Offset(panel.left + dx + panel.height, panel.top),
          net,
        );
        c.drawLine(
          Offset(panel.right - dx, panel.bottom),
          Offset(panel.right - dx - panel.height, panel.top),
          net,
        );
      }
      c.restore();
      c.drawRect(
        Rect.fromLTRB(x - mw / 2, top + hh * .035, x + mw / 2, top + hh * .06),
        _fill(ink.tile.$2),
      );
      c.drawRect(
        Rect.fromLTRB(x - mw / 2, top + hh * .06, x + mw / 2, top + hh * .066),
        _fill(ink.gilt.$2),
      );
      _merlons(c, x - mw / 2, x + mw / 2, (_) => top, mw * .2, face, lit);
      // The lantern turret.
      final t0 = top - hh * .005, t1 = top - hh * .1;
      c.drawRect(Rect.fromLTRB(x - mw * .2, t1, x + mw * .2, t0), _fill(face));
      c.drawRect(Rect.fromLTRB(x + mw * .06, t1, x + mw * .2, t0), _fill(lit));
      c.drawPath(
        _arch(x, mw * .08, t1 + hh * .045, t0 - hh * .012, point: .4),
        _fill(Sketch.fade(ink.lamp, .9)),
      );
      lamps.add(Offset(x, t1 + hh * .05));
      _dome(c, Offset(x, t1), mw * .22, hh * .07, 2, ink);
    }
  }

  /// A date palm: a slim curved trunk ringed with leaf scars, a crown of
  /// arching pinnate fronds (shaded on the left, lit on the right) and,
  /// with [dates], amber clusters hanging under the crown.
  static void _datePalm(
    Canvas c,
    Offset base,
    double ht,
    double lean,
    _Clay ink, {
    bool dates = false,
    int seed = 0,
    bool detail = true,
  }) {
    final crown = base + Offset(lean * ht, -ht);
    final bend = base + Offset(lean * ht * .1, -ht * .5);
    final low = ht * .038, high = ht * .026;
    final trunk = Path()
      ..moveTo(base.dx - low, base.dy)
      ..quadraticBezierTo(bend.dx - low, bend.dy, crown.dx - high, crown.dy)
      ..lineTo(crown.dx + high, crown.dy)
      ..quadraticBezierTo(bend.dx + low, bend.dy, base.dx + low, base.dy)
      ..close();
    c.drawPath(trunk, _fill(ink.trunk));
    if (detail) {
      c.drawPath(
        Path()
          ..moveTo(base.dx - low, base.dy)
          ..quadraticBezierTo(bend.dx - low, bend.dy, crown.dx - high, crown.dy)
          ..lineTo(crown.dx - high * .2, crown.dy)
          ..quadraticBezierTo(
            bend.dx - low * .2,
            bend.dy,
            base.dx - low * .2,
            base.dy,
          )
          ..close(),
        _fill(ink.trunkShade),
      );
      final scars = Path();
      for (var k = .06; k < .94; k += .07) {
        final a = Offset.lerp(
          Offset.lerp(base, bend, k)!,
          Offset.lerp(bend, crown, k)!,
          k,
        )!;
        final half = low + (high - low) * k;
        scars
          ..moveTo(a.dx - half, a.dy + half * .5)
          ..lineTo(a.dx, a.dy - half * .1)
          ..lineTo(a.dx + half, a.dy + half * .5);
      }
      c.drawPath(scars, _pen(ink.trunkShade, math.max(.6, ht * .008)));
    }
    // Fronds from the back of the crown to the front, each a rib with
    // leaflets combed toward its tip.
    final n = detail ? 13 : 9;
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < n; i++) {
        final t = (i + .5) / n;
        final back = i.isEven;
        if ((pass == 0) != back) continue;
        final a =
            math.pi * (1.12 - t * 1.24) +
            (Sketch.hash(seed * 31 + i) - .5) * .2;
        final len =
            ht * (back ? .44 : .5) * (.8 + .3 * Sketch.hash(seed * 17 + i));
        final droop = (.3 + .5 * (1 - math.sin(a).abs())) * (back ? 1.1 : .9);
        final right = math.cos(a) > .15;
        final color = back
            ? ink.frond
            : (right ? ink.frondLit : Sketch.mix(ink.frond, ink.frondLit, .45));
        _frond(c, crown, a, len, droop, color, detail);
      }
    }
    if (dates) {
      for (final dx in const [-.07, .05]) {
        final at = crown + Offset(dx * ht, ht * .07);
        c.drawOval(
          Rect.fromCenter(center: at, width: ht * .06, height: ht * .09),
          _fill(Sketch.mix(ink.saffron, ink.madder, .45)),
        );
        c.drawOval(
          Rect.fromCenter(
            center: at + Offset(ht * .01, -ht * .01),
            width: ht * .025,
            height: ht * .04,
          ),
          _fill(Sketch.mix(ink.saffron, const Color(0xffffffff), .2)),
        );
      }
    }
    c.drawCircle(crown, ht * .03, _fill(ink.trunkShade));
  }

  /// One pinnate frond as a filled, serrated blade along a drooping rib.
  static void _frond(
    Canvas c,
    Offset root,
    double angle,
    double len,
    double droop,
    Color color,
    bool detail,
  ) {
    final dir = Offset(math.cos(angle), -math.sin(angle));
    final tip = root + dir * len + Offset(0, len * droop);
    final mid = root + dir * len * .55 - Offset(0, len * .12);
    Offset at(double t) {
      final u = 1 - t;
      return root * (u * u) + mid * (2 * u * t) + tip * (t * t);
    }

    final left = <Offset>[], right = <Offset>[];
    final steps = detail ? 10 : 6;
    for (var k = 0; k <= steps; k++) {
      final t = k / steps;
      final p = at(t);
      final q = at(math.min(1, t + .05)) - at(math.max(0, t - .05));
      final d = q.distance == 0 ? const Offset(1, 0) : q / q.distance;
      final n = Offset(-d.dy, d.dx);
      final wide =
          len *
          .13 *
          math.sin(math.pi * math.min(1, t * 1.15)) *
          (k.isOdd ? 1 : .45);
      // Leaflets sweep forward toward the tip.
      left.add(p + n * wide + d * wide * .6);
      right.add(p - n * wide + d * wide * .6);
    }
    final path = Path()..moveTo(root.dx, root.dy);
    for (final p in left) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path..close(), _fill(color));
  }

  // ---------------------------------------------------------------------------
  // Far band: sandstone jebels, a hill fort and far palm groves.

  /// The far desert: palm groves of distant oases on the horizon, the
  /// sandstone jebels and the hill fort on its butte.
  void _farDesert(Canvas c, double w, double h) {
    final ink = _Clay(.5);
    double ground(double x) => _y(Depth.far, x, h);
    // Palm groves of distant oases along the horizon.
    for (final (x0, n) in [(w * .2, 5), (w * .6, 7), (w + h * .1, 4)]) {
      for (var i = 0; i < n; i++) {
        final x = x0 + i * h * .022 + Sketch.hash(i * 5 + n) * h * .012;
        _datePalm(
          c,
          Offset(x, ground(x) + h * .004),
          h * (.03 + .014 * Sketch.hash(i + n * 3)),
          (Sketch.hash(i + 40) - .5) * .3,
          ink,
          detail: false,
          seed: i,
        );
      }
    }
    _jebel(c, -h * .5, w * .3, h * .19, 3, h, ink);
    _jebel(c, w * .37, w * .5, h * .075, 7, h, ink);
    _jebel(c, w * .91, w + h * .55, h * .15, 11, h, ink);
    _hillFort(
      c,
      Offset(w * .435, ground(w * .435) - h * .07),
      h * .05,
      _Clay(.46),
    );
  }

  /// A sandstone jebel like those of Wadi Rum: sheer walls under a skyline
  /// of weathered domes, streaked by runnels, its flanks lit on the right.
  void _jebel(
    Canvas c,
    double x0,
    double x1,
    double tall,
    int seed,
    double h,
    _Clay ink,
  ) {
    final (lit, face, shade) = ink.rock;
    final domes = 2 + (Sketch.hash(seed) * 3).floor() + ((x1 - x0) / h).floor();
    final centers = [
      for (var i = 0; i < domes; i++)
        (i + .5 + (Sketch.hash(seed * 7 + i) - .5) * .45) / domes,
    ];
    double top(double t) {
      final rise = _smooth(t / .07) * _smooth((1 - t) / .09);
      var crown = 0.0;
      for (var i = 0; i < domes; i++) {
        final d = (t - centers[i]) / (.62 / domes);
        crown = math.max(
          crown,
          (1 - d * d).clamp(0.0, 1.0) *
              (.55 + .45 * Sketch.hash(seed * 13 + i)),
        );
      }
      return rise * (.68 + .32 * math.sqrt(crown));
    }

    final base = _y(Depth.far, x0, h) + h * .03;
    final step = h * .005;
    final pts = <Offset>[];
    for (var x = x0; x <= x1 + step; x += step) {
      final t = ((x - x0) / (x1 - x0)).clamp(0.0, 1.0);
      pts.add(Offset(x, base - tall * top(t)));
    }
    final body = Path()..moveTo(x0, base + h * .05);
    for (final p in pts) {
      body.lineTo(p.dx, p.dy);
    }
    body
      ..lineTo(x1, base + h * .05)
      ..close();
    c.drawPath(body, _fill(face));
    c.save();
    c.clipPath(body);
    // Each dome's sunward flank, and the shade that pools on its left.
    final litPath = Path(), shadePath = Path();
    for (var i = 0; i < domes; i++) {
      final cx = x0 + (x1 - x0) * centers[i];
      final half = (x1 - x0) * .62 / domes;
      litPath.addPath(
        Sketch.poly([
          cx,
          base - tall * 1.1,
          cx + half * .7,
          base - tall * 1.1,
          cx + half * .9,
          base + h * .05,
          cx + half * .15,
          base + h * .05,
        ]),
        Offset.zero,
      );
      shadePath.addPath(
        Sketch.poly([
          cx - half * .9,
          base - tall * 1.1,
          cx - half * .35,
          base - tall * 1.1,
          cx - half * .5,
          base + h * .05,
          cx - half * 1.05,
          base + h * .05,
        ]),
        Offset.zero,
      );
    }
    litPath.addPath(
      Sketch.poly([
        x1 - (x1 - x0) * .05,
        base - tall * 1.1,
        x1 + 2,
        base - tall,
        x1 + 2,
        base + h * .05,
        x1 - (x1 - x0) * .02,
        base + h * .05,
      ]),
      Offset.zero,
    );
    c.drawPath(shadePath, _fill(Sketch.fade(shade, .55)));
    c.drawPath(litPath, _fill(Sketch.fade(lit, .6)));
    // Runnels streaking down from the rim.
    final runnel = _pen(Sketch.fade(shade, .5), math.max(.6, h * .0022));
    for (var i = 0; i < pts.length; i += 3) {
      final r = Sketch.hash(seed * 101 + i);
      if (r > .55) continue;
      final p = pts[i];
      c.drawLine(
        p + Offset(0, h * .004),
        p + Offset(h * .002 * (r - .3), tall * (.25 + .6 * r)),
        runnel,
      );
    }
    // Ledges break the walls into tiers, and a talus of scree at the foot.
    for (final k in const [.38, .62]) {
      final y = base - tall * k;
      c.drawRect(
        Rect.fromLTRB(x0, y, x1, y + h * .0025),
        _fill(Sketch.fade(shade, .35)),
      );
      c.drawRect(
        Rect.fromLTRB(x0, y - h * .002, x1, y),
        _fill(Sketch.fade(lit, .35)),
      );
    }
    c.drawRect(
      Rect.fromLTRB(x0, base - tall * .22, x1, base + h * .05),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base - tall * .22),
          Offset(0, base),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .55)],
        ),
    );
    c.restore();
  }

  /// A walled hill fort on a butte: round corner towers, a square keep and
  /// merlons, lost in the haze.
  static void _hillFort(Canvas c, Offset base, double s, _Clay ink) {
    final (lit, face, shade) = ink.ochre;
    final x = base.dx, y = base.dy;
    c.drawRect(
      Rect.fromLTRB(x - s * 1.4, y - s * .55, x + s * 1.4, y + s * .4),
      _fill(face),
    );
    c.drawRect(
      Rect.fromLTRB(x + s * .9, y - s * .55, x + s * 1.4, y + s * .4),
      _fill(lit),
    );
    _merlons(
      c,
      x - s * 1.4,
      x + s * 1.4,
      (_) => y - s * .55,
      s * .16,
      face,
      lit,
    );
    // The keep.
    c.drawRect(
      Rect.fromLTRB(x - s * .35, y - s * 1.25, x + s * .3, y - s * .5),
      _fill(face),
    );
    c.drawRect(
      Rect.fromLTRB(x + s * .08, y - s * 1.25, x + s * .3, y - s * .5),
      _fill(lit),
    );
    _merlons(
      c,
      x - s * .35,
      x + s * .3,
      (_) => y - s * 1.25,
      s * .15,
      face,
      lit,
    );
    c.drawRect(
      Rect.fromLTRB(x - s * .12, y - s * 1.0, x - s * .04, y - s * .86),
      _fill(ink.deep),
    );
    for (final dx in const [-1.45, 1.35]) {
      final tx = x + s * dx;
      c.drawRect(
        Rect.fromLTRB(tx - s * .22, y - s * .82, tx + s * .22, y + s * .4),
        _fill(face),
      );
      c.drawRect(
        Rect.fromLTRB(tx + s * .02, y - s * .82, tx + s * .22, y + s * .4),
        _fill(lit),
      );
      c.drawRect(
        Rect.fromLTRB(tx - s * .22, y - s * .82, tx - s * .12, y + s * .4),
        _fill(Sketch.fade(shade, .7)),
      );
      _merlons(
        c,
        tx - s * .24,
        tx + s * .24,
        (_) => y - s * .82,
        s * .14,
        face,
        lit,
      );
    }
    // The butte's cap of rock under the walls.
    final (rl, rf, _) = ink.rock;
    c.drawPath(
      Sketch.poly([
        x - s * 2.2,
        y + s * .3,
        x - s * 1.7,
        y + s * .25,
        x + s * 1.8,
        y + s * .25,
        x + s * 2.4,
        y + s * .4,
        x + s * 2.4,
        y + s * 1.5,
        x - s * 2.2,
        y + s * 1.5,
      ]),
      _fill(rf),
    );
    c.drawRect(
      Rect.fromLTRB(x - s * 2.2, y + s * .25, x + s * 2.4, y + s * .33),
      _fill(rl),
    );
  }

  /// A thread of smoke from the hill fort's kitchens.
  void _farLive(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h;
    final x = w * .435 - h * .012, top = _y(Depth.far, w * .435, h) - h * .135;
    final paint = Paint();
    for (var i = 0; i < 10; i++) {
      final age = (f.clock * .07 + i / 10) % 1;
      paint.color = Sketch.fade(
        const Color(0xfff6e2d8),
        .3 * (1 - age) * math.min(1.0, age * 6),
      );
      c.drawCircle(
        Offset(
          x - age * age * h * .05 + math.sin(age * 5 + i) * h * .003,
          top - age * h * .08,
        ),
        h * (.002 + .006 * age),
        paint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mid band: the walled city.

  /// How far up its tell the city has climbed at pixel [x], in viewport
  /// heights: the houses crowd highest round the mosque.
  static double _tell(double x, double w, double h) {
    final d = (x - _mosqueX(w)) / (w * .36 + h * .2);
    return .045 * math.max(0.0, 1 - d * d);
  }

  /// Where the city begins on the left: its corner bastion.
  static double _cityLeft(double w, double h) => w * .07;

  /// The walled city, back to front: palms beyond the walls, the back row
  /// of houses up the tell, the citadel and the mosque, courtyard palms, the
  /// middle and front rows, then the wall and the great gate. Records the
  /// lamps and banner poles that `live` animates.
  void _city(Canvas c, double w, double h) {
    final k = _cityK(w, h);
    final lamps = <Offset>[];
    final banners = <(Offset, double)>[];
    _cityLamps[(w, h)] = lamps;
    _cityBanners[(w, h)] = banners;
    double ground(double x) => _y(Depth.mid, x, h);
    final gate = _gateX(w), mosque = _mosqueX(w), citadel = _citadelX(w, h);
    final left = _cityLeft(w, h), right = w + h * .75;
    final back = _Clay(.42), midInk = _Clay(.24), front = _Clay(.12);
    final ms = _mosqueS(w, h);

    // Palms of the gardens beyond the walls.
    for (var i = 0; i < 5; i++) {
      final x = left - h * (.06 + .09 * i + .03 * Sketch.hash(i + 290));
      _datePalm(
        c,
        Offset(x, ground(x) + h * .004),
        h * (.09 + .05 * Sketch.hash(i + 295)),
        (Sketch.hash(i + 298) - .5) * .3,
        _Clay(.24),
        seed: i + 3,
        detail: false,
      );
    }
    _houseRow(
      c,
      left + h * .1,
      right,
      w,
      h,
      back,
      400,
      lift: .085,
      low: .08,
      high: .13,
      tell: 1,
      lamps: lamps,
      ground: ground,
      keep: [(mosque, ms * 2.2, .06)],
      detail: 0,
      towers: .14,
    );
    _citadel(
      c,
      Offset(citadel, ground(citadel)),
      h * .078 * k,
      _Clay(.24),
      lamps,
      banners,
    );
    _mosque(c, _mosqueBase(w, h), ms, _Clay(.17), lamps, banners);
    // Courtyard palms rising between the roofs.
    for (final (fx, s) in const [
      (.17, 1.0),
      (.41, .85),
      (.72, .95),
      (.9, .8),
    ]) {
      final x = w * fx;
      _datePalm(
        c,
        Offset(x, ground(x) - h * (.05 + _tell(x, w, h))),
        h * .13 * s,
        (Sketch.hash((fx * 100).round()) - .5) * .25,
        midInk,
        seed: (fx * 100).round(),
        detail: false,
      );
    }
    _houseRow(
      c,
      left + h * .05,
      right,
      w,
      h,
      midInk,
      500,
      lift: .048,
      low: .07,
      high: .115,
      tell: .7,
      lamps: lamps,
      ground: ground,
      keep: [(mosque, ms * 2.6, .07)],
      detail: 1,
      towers: .1,
    );
    _houseRow(
      c,
      left + h * .02,
      right,
      w,
      h,
      front,
      600,
      lift: .014,
      low: .075,
      high: .1,
      tell: .25,
      lamps: lamps,
      ground: ground,
    );
    final gs = h * .13 * k;
    _cityWall(
      c,
      left,
      right,
      gate - gs * 1.15,
      gate + gs * 1.15,
      h,
      ground,
      front,
    );
    _gate(
      c,
      Offset(gate, ground(gate) + h * .01),
      gs,
      _Clay(.08),
      lamps,
      banners,
    );
  }

  /// A row of houses from [x0] to [x1], standing [lift] h (plus [tell] of
  /// the tell) up the slope, each [low]..[high] h tall. [keep] lists (x,
  /// half width, max height) spans where houses stay low so a landmark
  /// shows over them.
  void _houseRow(
    Canvas c,
    double x0,
    double x1,
    double w,
    double h,
    _Clay ink,
    int seed, {
    required double lift,
    required double low,
    required double high,
    required double tell,
    required List<Offset> lamps,
    required double Function(double x) ground,
    List<(double, double, double)> keep = const [],
    int detail = 2,
    double towers = 0,
  }) {
    var x = x0;
    var i = 0;
    while (x < x1) {
      final tower = Sketch.hash(seed + i * 5 + 3) < towers;
      var bw = h * (.055 + .045 * Sketch.hash(seed + i * 3));
      var bh = h * (low + (high - low) * Sketch.hash(seed + i * 3 + 1));
      if (tower) {
        bw *= .72;
        bh *= 1.6;
      }
      final mid = x + bw / 2;
      for (final (kx, half, cap) in keep) {
        if ((mid - kx).abs() < half) bh = math.min(bh, h * cap);
      }
      final base = ground(mid) - h * (lift + tell * _tell(mid, w, h)) + h * .02;
      _house(
        c,
        x,
        base,
        bw,
        bh + h * .02,
        ink,
        seed + i,
        lamps,
        h,
        detail: detail,
        tower: tower,
      );
      x += bw * (.7 + .32 * Sketch.hash(seed + i * 3 + 2));
      i++;
    }
  }

  /// A flat-roofed house of mud plaster seen a little from the right: the
  /// front in the cool dawn light, a sunlit return and the roof, a parapet
  /// of Najdi vent triangles or stepped crenels, small windows (a few still
  /// lamplit), palm-log beam ends, now and then a wooden bay window, and
  /// something on the roof: a stair room, a wind tower or dyed cloth.
  void _house(
    Canvas c,
    double x,
    double base,
    double bw,
    double bh,
    _Clay ink,
    int seed,
    List<Offset> lamps,
    double h, {
    int detail = 2,
    bool tower = false,
  }) {
    final pick = Sketch.hash(seed * 3 + 1);
    final tone = pick < .55 ? ink.rose : (pick < .84 ? ink.ochre : ink.white);
    final (lit, face, shade) = tone;
    final d = bw * .2, rise = bw * .07;
    final left = x, right = x + bw, top = base - bh;
    final style = tower ? 2 : (Sketch.hash(seed * 3 + 2) * 4).floor();
    final roofy = Sketch.hash(seed * 7 + 5);
    // Roof clutter first, so the parapet hides its feet.
    if (roofy < .22) {
      _barjeel(
        c,
        Offset(left + bw * .3, top - rise * .5),
        h * .018,
        h * .04,
        tone,
        ink,
      );
    } else if (roofy < .44) {
      final room = Rect.fromLTRB(
        left + bw * .08,
        top - bh * .3,
        left + bw * .5,
        top + 1,
      );
      c.drawRect(room, _fill(face));
      c.drawPath(
        Sketch.poly([
          room.right,
          room.bottom,
          room.right + d * .6,
          room.bottom - rise,
          room.right + d * .6,
          room.top - rise,
          room.right,
          room.top,
        ]),
        _fill(lit),
      );
      c.drawRect(
        Rect.fromLTRB(
          room.left + room.width * .3,
          room.top + room.height * .35,
          room.left + room.width * .55,
          room.bottom,
        ),
        _fill(ink.deep),
      );
    } else if (roofy < .5 && detail > 0) {
      final pole = _pen(ink.wood, math.max(.5, h * .0018));
      final y0 = top - bh * .28;
      c.drawLine(
        Offset(left + bw * .15, top),
        Offset(left + bw * .15, y0),
        pole,
      );
      c.drawLine(
        Offset(right - bw * .1, top),
        Offset(right - bw * .1, y0),
        pole,
      );
      c.drawLine(
        Offset(left + bw * .15, y0),
        Offset(right - bw * .1, y0 + bh * .02),
        pole,
      );
      final cloths = [ink.madder, ink.indigo, ink.saffron, ink.tile.$2];
      for (var k = 0; k < 3; k++) {
        final cx = left + bw * (.22 + k * .22);
        c.drawRect(
          Rect.fromLTWH(cx, y0 + bh * .01 * k, bw * .15, bh * .2),
          _fill(cloths[(seed + k) % 4]),
        );
      }
    } else if (roofy < .58) {
      for (final (fx, s) in const [(.3, 1.0), (.42, .8)]) {
        final jar = Offset(left + bw * fx, top - h * .004);
        c.drawOval(
          Rect.fromCenter(
            center: jar,
            width: h * .008 * s,
            height: h * .01 * s,
          ),
          _fill(Sketch.mix(ink.madder, face, .5)),
        );
      }
    }
    // Front, sunlit return and the flat roof behind its parapet.
    c.drawRect(Rect.fromLTRB(left, top, right, base), _fill(face));
    c.drawRect(
      Rect.fromLTRB(left, top + bh * .55, right, base),
      Paint()
        ..shader = Gradient.linear(Offset(0, top + bh * .55), Offset(0, base), [
          Sketch.fade(shade, 0),
          Sketch.fade(shade, .4),
        ]),
    );
    c.drawPath(
      Sketch.poly([
        right,
        base,
        right + d,
        base - rise,
        right + d,
        top - rise,
        right,
        top,
      ]),
      _fill(lit),
    );
    c.drawPath(
      Sketch.poly([
        left,
        top,
        left + d,
        top - rise,
        right + d,
        top - rise,
        right,
        top,
      ]),
      _fill(Sketch.mix(lit, shade, .3)),
    );
    c.drawRect(
      Rect.fromLTRB(left, top, left + math.max(.6, bw * .04), base),
      _fill(Sketch.fade(shade, .7)),
    );
    final u = h * .01;
    // Parapet.
    switch (style) {
      case 0:
        // Najdi: a row of little vent triangles and pointed crenels.
        final n = math.max(2, (bw / (u * 1.1)).floor());
        final vents = Path(), crown = Path();
        for (var k = 0; k < n; k++) {
          final cx = left + bw * (k + .5) / n;
          vents.addPath(
            Sketch.poly([
              cx - u * .22,
              top + u * .9,
              cx + u * .22,
              top + u * .9,
              cx,
              top + u * .5,
            ]),
            Offset.zero,
          );
          crown.addPath(
            Sketch.poly([
              cx - u * .3,
              top + .5,
              cx,
              top - u * .55,
              cx + u * .3,
              top + .5,
            ]),
            Offset.zero,
          );
        }
        c.drawPath(vents, _fill(ink.deep));
        c.drawPath(crown, _fill(face));
      case 1:
        _merlons(c, left, right, (_) => top + .5, u * .8, face, lit);
      case 2:
        // Whitened corner horns and a white frieze, as on the coast.
        final white = ink.white.$1;
        c.drawRect(
          Rect.fromLTRB(left, top, right, top + u * .35),
          _fill(white),
        );
        for (final cx in [left + u * .25, right - u * .25]) {
          c.drawPath(
            Sketch.poly([
              cx - u * .25,
              top,
              cx,
              top - u * .8,
              cx + u * .25,
              top,
            ]),
            _fill(white),
          );
        }
      default:
        c.drawRect(
          Rect.fromLTRB(left, top - u * .2, right, top + u * .25),
          _fill(lit),
        );
    }
    c.drawRect(
      Rect.fromLTRB(left, top + u * .9, right, top + u * 1.15),
      _fill(Sketch.fade(shade, .6)),
    );
    // Palm-log beam ends under the roof.
    if (tone != ink.white && bw > u * 3 && detail > 0) {
      final beams = Path();
      for (var bx = left + u * .6; bx < right - u * .4; bx += u * 1.1) {
        beams.addRect(Rect.fromLTWH(bx, top + u * 1.25, u * .32, u * .32));
      }
      c.drawPath(beams, _fill(ink.deep));
    }
    // Windows: pointed openings in rows, a few still lamplit.
    final rows = math.max(
      1,
      math.min(tower ? 4 : 2, ((bh - u * 2) / (u * 2.6)).floor()),
    );
    final cols = math.max(1, ((bw - u) / (u * 1.9)).floor());
    final open = tower ? .5 : const [.1, .42, .55][detail];
    for (var r = 0; r < rows; r++) {
      for (var k = 0; k < cols; k++) {
        final hsh = Sketch.hash(seed * 41 + r * 7 + k);
        if (hsh > open) continue;
        final cx = left + bw * (k + .5) / cols;
        final wy = top + u * 1.9 + r * u * 2.6;
        if (wy + u * 1.2 > base - u) continue;
        final lampLit = hsh < (detail == 0 ? .1 : .09);
        final path = _arch(cx, u * .28, wy + u * .25, wy + u * 1.1, point: .5);
        if (style == 2) {
          c.drawRect(
            Rect.fromLTRB(
              cx - u * .45,
              wy - u * .3,
              cx + u * .45,
              wy + u * 1.25,
            ),
            _fill(ink.white.$1),
          );
        }
        c.drawPath(path, _fill(lampLit ? ink.lamp : ink.deep));
        if (lampLit) lamps.add(Offset(cx, wy + u * .7));
      }
    }
    // A projecting wooden bay (rawshan) with its lattice.
    if (style == 1 && detail > 0 && bw > u * 4.5 && bh > u * 6) {
      final bay = Rect.fromLTRB(
        left + bw * .36,
        top + u * 1.8,
        left + bw * .68,
        top + u * 1.8 + bh * .3,
      );
      final wood = Sketch.mix(
        Sketch.hash(seed + 99) < .5
            ? ink.woodLit
            : Sketch.mix(ink.tile.$2, ink.woodLit, .35),
        face,
        .2,
      );
      c.drawRect(bay.inflate(u * .15), _fill(Sketch.mix(wood, ink.dark, .3)));
      c.drawRect(bay, _fill(wood));
      final grid = _pen(
        Sketch.mix(wood, ink.woodLit, .6),
        math.max(.4, u * .12),
      );
      for (var gx = bay.left + u * .5; gx < bay.right; gx += u * .5) {
        c.drawLine(
          Offset(gx, bay.top + u * .3),
          Offset(gx, bay.bottom - u * .2),
          grid,
        );
      }
      for (var gy = bay.top + u * .5; gy < bay.bottom; gy += u * .5) {
        c.drawLine(Offset(bay.left, gy), Offset(bay.right, gy), grid);
      }
      c.drawRect(
        Rect.fromLTRB(
          bay.left - u * .3,
          bay.top - u * .35,
          bay.right + u * .3,
          bay.top,
        ),
        _fill(Sketch.mix(wood, ink.woodLit, .5)),
      );
      c.drawRect(
        Rect.fromLTRB(
          bay.right - bay.width * .2,
          bay.top,
          bay.right,
          bay.bottom,
        ),
        _fill(Sketch.fade(ink.woodLit, .5)),
      );
    }
  }

  /// A wind tower (barjeel) rising from a roof: a square shaft whose top is
  /// open in tall vents on every face, crossed by the ends of its poles.
  static void _barjeel(
    Canvas c,
    Offset foot,
    double tw,
    double th,
    _Tone tone,
    _Clay ink,
  ) {
    final (lit, face, _) = tone;
    final x = foot.dx, y = foot.dy;
    final body = Rect.fromLTRB(x - tw / 2, y - th, x + tw / 2, y + 1);
    c.drawRect(body, _fill(face));
    c.drawRect(
      Rect.fromLTRB(x + tw * .18, y - th, x + tw / 2, y + 1),
      _fill(lit),
    );
    // Vents: dark slots divided by thin piers.
    final vent = Rect.fromLTRB(
      x - tw * .4,
      y - th * .9,
      x + tw * .4,
      y - th * .5,
    );
    c.drawRect(vent, _fill(ink.deep));
    for (final k in const [-.14, .14]) {
      c.drawRect(
        Rect.fromLTRB(
          x + tw * k - tw * .05,
          vent.top,
          x + tw * k + tw * .05,
          vent.bottom,
        ),
        _fill(k > 0 ? lit : face),
      );
    }
    c.drawRect(
      Rect.fromLTRB(x - tw * .56, y - th, x + tw * .56, y - th * .92),
      _fill(face),
    );
    c.drawRect(
      Rect.fromLTRB(x + tw * .1, y - th, x + tw * .56, y - th * .92),
      _fill(lit),
    );
    // Pole ends poking out below the vents.
    final pole = _pen(ink.wood, math.max(.5, tw * .08));
    c.drawLine(
      Offset(x - tw * .7, y - th * .44),
      Offset(x + tw * .7, y - th * .44),
      pole,
    );
  }

  /// The Friday mosque: a low prayer hall behind an arcade, a turquoise onion
  /// dome on a windowed drum between two smaller domes, and two minarets of
  /// different schools.
  void _mosque(
    Canvas c,
    Offset base,
    double s,
    _Clay ink,
    List<Offset> lamps,
    List<(Offset, double)> banners,
  ) {
    final (lit, face, shade) = ink.white;
    final x = base.dx, y = base.dy;
    _minaret(c, Offset(x - s * 2.25, y), s * 4.2, s * .36, 0, ink, lamps);
    _minaret(c, Offset(x + s * 2.3, y), s * 3.4, s * .42, 1, ink, lamps);
    // Prayer hall with its arcade.
    final hall = Rect.fromLTRB(
      x - s * 1.85,
      y - s * .78,
      x + s * 1.85,
      y + s * .3,
    );
    c.drawRect(hall, _fill(face));
    c.drawRect(
      Rect.fromLTRB(hall.right - s * .3, hall.top, hall.right, hall.bottom),
      _fill(lit),
    );
    c.drawRect(
      Rect.fromLTRB(hall.left, hall.top, hall.right, hall.top + s * .06),
      _fill(lit),
    );
    for (var i = 0; i < 7; i++) {
      final ax = hall.left + hall.width * (i + .5) / 7;
      final arch = _arch(
        ax,
        s * .15,
        y - s * .3,
        hall.bottom,
        point: .45,
        shoe: .5,
      );
      c.drawPath(arch, _fill(i == 3 ? ink.lamp : ink.deep));
      if (i == 3) lamps.add(Offset(ax, y - s * .2));
    }
    c.drawRect(
      Rect.fromLTRB(hall.left, y - s * .62, hall.right, y - s * .56),
      _fill(ink.tile.$2),
    );
    _merlons(c, hall.left, hall.right, (_) => hall.top, s * .13, face, lit);
    // Side domes and the great dome on its drum.
    for (final dx in const [-1.25, 1.25]) {
      final db = Offset(x + s * dx, hall.top - s * .02);
      c.drawRect(
        Rect.fromLTRB(
          db.dx - s * .3,
          db.dy - s * .12,
          db.dx + s * .3,
          db.dy + s * .02,
        ),
        _fill(face),
      );
      _dome(c, db - Offset(0, s * .12), s * .28, s * .5, 2, ink);
    }
    final drum = Rect.fromLTRB(
      x - s * .62,
      hall.top - s * .42,
      x + s * .62,
      hall.top + s * .02,
    );
    c.drawRect(drum, _fill(face));
    c.drawRect(
      Rect.fromLTRB(
        drum.right - drum.width * .3,
        drum.top,
        drum.right,
        drum.bottom,
      ),
      _fill(lit),
    );
    c.drawRect(
      Rect.fromLTRB(
        drum.left,
        drum.top,
        drum.left + drum.width * .15,
        drum.bottom,
      ),
      _fill(Sketch.fade(shade, .7)),
    );
    for (var i = 0; i < 5; i++) {
      final wx = drum.left + drum.width * (i + .5) / 5;
      c.drawPath(
        _arch(
          wx,
          s * .045,
          drum.top + s * .2,
          drum.bottom - s * .07,
          point: .5,
        ),
        _fill(i.isOdd ? ink.lamp : ink.deep),
      );
    }
    c.drawRect(
      Rect.fromLTRB(
        drum.left - s * .04,
        drum.top - s * .05,
        drum.right + s * .04,
        drum.top,
      ),
      _fill(ink.gilt.$2),
    );
    _dome(c, Offset(x, drum.top - s * .05), s * .56, s * 1.3, 0, ink);
  }

  /// The citadel on its rock at the city's edge: a craggy spur, curtain walls
  /// with round towers, a palace hall under a gilded dome and a tall keep
  /// flying a banner.
  void _citadel(
    Canvas c,
    Offset foot,
    double s,
    _Clay ink,
    List<Offset> lamps,
    List<(Offset, double)> banners,
  ) {
    final (rl, rf, rs) = ink.rock;
    final x = foot.dx, y = foot.dy;
    // The rock: tiers of ledges stepping up to a crown.
    final crown = y - s * 1.2;
    final rock = Path()
      ..moveTo(x - s * 3.4, y + s * .3)
      ..lineTo(x - s * 3.0, y - s * .2)
      ..lineTo(x - s * 2.5, y - s * .35)
      ..lineTo(x - s * 2.2, y - s * .8)
      ..lineTo(x - s * 1.8, crown + s * .1)
      ..lineTo(x + s * 1.7, crown)
      ..lineTo(x + s * 2.2, y - s * .75)
      ..lineTo(x + s * 2.7, y - s * .6)
      ..lineTo(x + s * 3.1, y - s * .1)
      ..lineTo(x + s * 3.6, y + s * .3)
      ..close();
    c.drawPath(rock, _fill(rf));
    c.save();
    c.clipPath(rock);
    c.drawPath(
      Sketch.poly([
        x + s * .9,
        crown,
        x + s * 1.8,
        crown,
        x + s * 2.4,
        y - s * .7,
        x + s * 3.8,
        y + s,
        x + s * 1.5,
        y + s,
      ]),
      _fill(rl),
    );
    c.drawPath(
      Sketch.poly([
        x - s * 3.4,
        y - s * 1.4,
        x - s * 1.4,
        crown,
        x - s * 1.9,
        y - s * .5,
        x - s * 1.6,
        y + s,
        x - s * 3.4,
        y + s,
      ]),
      _fill(Sketch.fade(rs, .8)),
    );
    final crack = _pen(Sketch.fade(rs, .7), math.max(.6, s * .03));
    for (var i = 0; i < 9; i++) {
      final cx = x - s * 2.6 + s * 5.4 * Sketch.hash(i + 830);
      final cy = crown + s * .2 + s * 1.1 * Sketch.hash(i + 840);
      c.drawLine(
        Offset(cx, cy),
        Offset(
          cx + s * .12 * (Sketch.hash(i + 850) - .5),
          cy + s * (.15 + .3 * Sketch.hash(i + 860)),
        ),
        crack,
      );
    }
    c.restore();
    final (lit, face, shade) = ink.ochre;
    // Curtain wall along the crown.
    final wallTop = crown - s * .55;
    c.drawRect(
      Rect.fromLTRB(x - s * 1.9, wallTop, x + s * 1.75, crown + s * .15),
      _fill(face),
    );
    c.drawRect(
      Rect.fromLTRB(x + s * 1.4, wallTop, x + s * 1.75, crown + s * .15),
      _fill(lit),
    );
    _merlons(c, x - s * 1.9, x + s * 1.75, (_) => wallTop, s * .14, face, lit);
    for (var i = 0; i < 6; i++) {
      final ax = x - s * 1.6 + i * s * .6;
      c.drawRect(
        Rect.fromLTRB(ax, wallTop + s * .2, ax + s * .05, wallTop + s * .34),
        _fill(ink.deep),
      );
    }
    // Palace hall with a gilded dome.
    final hall = Rect.fromLTRB(
      x - s * .2,
      wallTop - s * .45,
      x + s * 1.3,
      wallTop + s * .05,
    );
    c.drawRect(hall, _fill(ink.white.$2));
    c.drawRect(
      Rect.fromLTRB(hall.right - s * .25, hall.top, hall.right, hall.bottom),
      _fill(ink.white.$1),
    );
    for (var i = 0; i < 4; i++) {
      final ax = hall.left + hall.width * (i + .5) / 4;
      c.drawPath(
        _arch(ax, s * .1, hall.top + s * .26, hall.bottom, point: .4, shoe: .5),
        _fill(i == 1 ? ink.lamp : ink.deep),
      );
      if (i == 1) lamps.add(Offset(ax, hall.top + s * .32));
    }
    _dome(
      c,
      Offset(hall.center.dx + s * .1, hall.top),
      s * .34,
      s * .7,
      1,
      ink,
    );
    // Round towers at the ends of the wall.
    for (final tx in [x - s * 1.95, x + s * 1.8]) {
      final tower = Rect.fromLTRB(
        tx - s * .3,
        wallTop - s * .3,
        tx + s * .3,
        crown + s * .3,
      );
      c.drawRect(
        tower,
        Paint()
          ..shader = Gradient.linear(
            tower.centerLeft,
            tower.centerRight,
            [shade, face, face, lit],
            const [0, .35, .6, 1],
          ),
      );
      _merlons(
        c,
        tower.left - s * .04,
        tower.right + s * .04,
        (_) => tower.top,
        s * .15,
        face,
        lit,
      );
      c.drawRect(
        Rect.fromLTRB(
          tx - s * .03,
          tower.top + s * .25,
          tx + s * .03,
          tower.top + s * .45,
        ),
        _fill(ink.deep),
      );
    }
    // The keep.
    final keep = Rect.fromLTRB(
      x - s * 1.25,
      wallTop - s * 1.3,
      x - s * .45,
      wallTop + s * .1,
    );
    c.drawRect(keep, _fill(face));
    c.drawRect(
      Rect.fromLTRB(
        keep.right - keep.width * .3,
        keep.top,
        keep.right,
        keep.bottom,
      ),
      _fill(lit),
    );
    c.drawRect(
      Rect.fromLTRB(
        keep.left,
        keep.top,
        keep.left + keep.width * .14,
        keep.bottom,
      ),
      _fill(Sketch.fade(shade, .8)),
    );
    c.drawRect(
      Rect.fromLTRB(
        keep.left - s * .08,
        keep.top + s * .12,
        keep.right + s * .08,
        keep.top + s * .24,
      ),
      _fill(face),
    );
    c.drawRect(
      Rect.fromLTRB(
        keep.left - s * .08,
        keep.top + s * .22,
        keep.right + s * .08,
        keep.top + s * .26,
      ),
      _fill(Sketch.fade(shade, .8)),
    );
    _merlons(
      c,
      keep.left - s * .08,
      keep.right + s * .08,
      (_) => keep.top + s * .12,
      s * .16,
      face,
      lit,
    );
    for (final (fy, lampLit) in const [(.4, true), (.62, false)]) {
      final wx = keep.center.dx;
      c.drawPath(
        _arch(
          wx,
          s * .06,
          keep.top + keep.height * fy,
          keep.top + keep.height * fy + s * .2,
          point: .4,
        ),
        _fill(lampLit ? ink.lamp : ink.deep),
      );
      if (lampLit) lamps.add(Offset(wx, keep.top + keep.height * fy + s * .08));
    }
    final pole = Offset(keep.center.dx, keep.top - s * .02);
    c.drawLine(
      pole,
      pole - Offset(0, s * .75),
      _pen(ink.wood, math.max(.7, s * .04)),
    );
    banners.add((pole - Offset(0, s * .75), s * .5));
  }

  /// The city wall from [x0] to [x1], broken by the gate between [gapL] and
  /// [gapR]: rammed earth in courses with rows of putlog holes, stepped
  /// merlons and round bastions.
  void _cityWall(
    Canvas c,
    double x0,
    double x1,
    double gapL,
    double gapR,
    double h,
    double Function(double x) ground,
    _Clay ink,
  ) {
    final (lit, face, shade) = ink.rose;
    final wallH = h * .05;
    for (final (a, b) in [(x0, gapL), (gapR, x1)]) {
      final top = Path()..moveTo(a, ground(a) + h * .03);
      for (var x = a; x <= b; x += h * .01) {
        top.lineTo(x, ground(x) - wallH);
      }
      top
        ..lineTo(b, ground(b) - wallH)
        ..lineTo(b, ground(b) + h * .03)
        ..close();
      c.drawPath(top, _fill(face));
      c.save();
      c.clipPath(top);
      // Courses of rammed earth and lines of putlog holes.
      final course = _pen(Sketch.fade(shade, .4), math.max(.5, h * .0016));
      final holes = Path();
      for (var k = 1; k < 4; k++) {
        final line = Path();
        for (var x = a; x <= b; x += h * .01) {
          final y = ground(x) - wallH + wallH * k / 3.6;
          if (x == a) {
            line.moveTo(x, y);
          } else {
            line.lineTo(x, y);
          }
        }
        c.drawPath(line, course);
        for (var x = a + h * .006 * k; x < b; x += h * .022) {
          holes.addRect(
            Rect.fromLTWH(
              x,
              ground(x) - wallH + wallH * k / 3.6 - h * .003,
              h * .0025,
              h * .0022,
            ),
          );
        }
      }
      c.drawPath(holes, _fill(Sketch.fade(ink.deep, .7)));
      // Warm light grazing the top of the wall.
      final glaze = Path()..moveTo(a, ground(a) - wallH);
      for (var x = a; x <= b; x += h * .01) {
        glaze.lineTo(x, ground(x) - wallH);
      }
      c.drawPath(glaze, _pen(lit, h * .005));
      c.restore();
      _merlons(c, a, b, (x) => ground(x) - wallH + .5, h * .012, face, lit);
      // Bastions at intervals, clear of the gate.
      for (var x = a + h * .16; x < b - h * .08; x += h * .34) {
        _bastion(c, Offset(x, ground(x)), h * .05, h * .076, ink);
      }
    }
  }

  /// A round bastion of the city wall: a drum shaded from left to right,
  /// a corbelled parapet with merlons and an arrow slit.
  static void _bastion(
    Canvas c,
    Offset foot,
    double width,
    double height,
    _Clay ink,
  ) {
    final (lit, face, shade) = ink.rose;
    final x = foot.dx, y = foot.dy + height * .3;
    final body = Rect.fromLTRB(
      x - width / 2,
      foot.dy - height,
      x + width / 2,
      y,
    );
    c.drawRect(
      body,
      Paint()
        ..shader = Gradient.linear(
          body.centerLeft,
          body.centerRight,
          [shade, face, face, lit],
          const [0, .3, .62, 1],
        ),
    );
    final lip = Rect.fromLTRB(
      body.left - width * .06,
      body.top,
      body.right + width * .06,
      body.top + height * .12,
    );
    c.drawRect(lip, _sweep(lip, [shade, face, lit]));
    c.drawRect(
      Rect.fromLTRB(lip.left, lip.bottom, lip.right, lip.bottom + height * .04),
      _fill(Sketch.fade(ink.deep, .4)),
    );
    _merlons(
      c,
      lip.left,
      lip.right,
      (_) => lip.top + .5,
      height * .17,
      face,
      lit,
    );
    c.drawRect(
      Rect.fromLTRB(
        x - width * .04,
        body.top + height * .3,
        x + width * .04,
        body.top + height * .55,
      ),
      _fill(ink.deep),
    );
  }

  /// The great gate: two round towers flying banners flank a gate block with
  /// a pointed horseshoe arch in alternating red and cream voussoirs, a tile
  /// frame and a box machicolation; lamplight glows in the passage beyond
  /// the open cedar doors.
  void _gate(
    Canvas c,
    Offset foot,
    double s,
    _Clay ink,
    List<Offset> lamps,
    List<(Offset, double)> banners,
  ) {
    final (lit, face, shade) = ink.rose;
    final x = foot.dx, y = foot.dy;
    // The gate block.
    final block = Rect.fromLTRB(
      x - s * .62,
      y - s * 1.12,
      x + s * .62,
      y + s * .1,
    );
    c.drawRect(block, _fill(face));
    c.drawRect(
      Rect.fromLTRB(block.left, block.top, block.right, block.top + s * .05),
      _fill(lit),
    );
    _merlons(
      c,
      block.left,
      block.right,
      (_) => block.top + .5,
      s * .13,
      face,
      lit,
    );
    // Tile frame (alfiz) around the arch.
    final frame = Rect.fromLTRB(
      x - s * .44,
      y - s * .95,
      x + s * .44,
      y + s * .1,
    );
    c.drawRect(frame, _fill(ink.tile.$2));
    c.drawRect(frame.deflate(s * .04), _fill(face));
    final stars = Paint()..color = ink.gilt.$1;
    for (var i = 0; i < 7; i++) {
      final sx = frame.left + frame.width * (i + .5) / 7;
      c.drawCircle(Offset(sx, frame.top + s * .02), s * .012, stars);
    }
    // Voussoirs: an arch of alternating wedges.
    final spring = y - s * .4, hw = s * .3;
    final outer = _arch(x, hw * 1.25, spring, y + s * .1, point: .32, shoe: .6);
    c.drawPath(outer, _fill(ink.white.$2));
    c.save();
    c.clipPath(outer);
    final apex = Offset(x, spring - hw * .2);
    for (var i = 0; i < 13; i++) {
      if (i.isEven) continue;
      final a0 = math.pi * (1.1 - i / 12 * 1.2),
          a1 = math.pi * (1.1 - (i + 1) / 12 * 1.2);
      c.drawPath(
        Sketch.poly([
          apex.dx, apex.dy, //
          apex.dx + math.cos(a0) * s, apex.dy - math.sin(a0) * s,
          apex.dx + math.cos(a1) * s, apex.dy - math.sin(a1) * s,
        ]),
        _fill(ink.madder),
      );
    }
    c.restore();
    final opening = _arch(x, hw, spring, y + s * .1, point: .32, shoe: .6);
    c.drawPath(opening, _fill(ink.dark));
    c.save();
    c.clipPath(opening);
    // The passage: lamplight at the far end on a street of the city.
    c.drawCircle(
      Offset(x, y - s * .25),
      s * .35,
      Paint()
        ..shader = Gradient.radial(
          Offset(x, y - s * .25),
          s * .35,
          [
            Sketch.fade(ink.lamp, .95),
            Sketch.fade(ink.lamp, .3),
            Sketch.fade(ink.lamp, 0),
          ],
          const [0, .45, 1],
        ),
    );
    lamps.add(Offset(x, y - s * .3));
    c.drawRect(
      Rect.fromLTRB(x - s * .08, y - s * .35, x + s * .08, y + s * .1),
      _fill(Sketch.mix(ink.lamp, ink.rose.$1, .5)),
    );
    // The open doors, studded cedar against the reveals.
    for (final side in const [-1.0, 1.0]) {
      final door = Rect.fromLTRB(
        side < 0 ? x - hw * .82 : x + hw * .5,
        spring - hw * .6,
        side < 0 ? x - hw * .5 : x + hw * .82,
        y + s * .1,
      );
      c.drawRect(door, _fill(side > 0 ? ink.woodLit : ink.wood));
      final studs = Paint()..color = ink.gilt.$2;
      for (var dy = door.top + s * .06; dy < door.bottom; dy += s * .08) {
        c.drawCircle(Offset(door.center.dx, dy), s * .008, studs);
      }
    }
    c.restore();
    // A box machicolation over the arch.
    final box = Rect.fromLTRB(
      x - s * .2,
      y - s * 1.02,
      x + s * .2,
      y - s * .86,
    );
    c.drawRect(box, _fill(face));
    c.drawRect(
      Rect.fromLTRB(box.right - box.width * .3, box.top, box.right, box.bottom),
      _fill(lit),
    );
    for (final k in const [-.12, 0.0, .12]) {
      c.drawRect(
        Rect.fromLTRB(
          x + s * k - s * .02,
          box.bottom,
          x + s * k + s * .02,
          box.bottom + s * .04,
        ),
        _fill(ink.deep),
      );
    }
    // The towers.
    for (final side in const [-1.0, 1.0]) {
      final tx = x + side * s * .8;
      final tower = Rect.fromLTRB(
        tx - s * .34,
        y - s * 1.42,
        tx + s * .34,
        y + s * .1,
      );
      c.drawRect(
        tower,
        Paint()
          ..shader = Gradient.linear(
            tower.centerLeft,
            tower.centerRight,
            [shade, face, face, lit],
            const [0, .3, .62, 1],
          ),
      );
      // Courses, a tile band and slits.
      for (var k = 1; k < 7; k++) {
        final cy = tower.bottom - tower.height * k / 7;
        c.drawRect(
          Rect.fromLTRB(tower.left, cy, tower.right, cy + s * .01),
          _fill(Sketch.fade(shade, .35)),
        );
      }
      final band = Rect.fromLTRB(
        tower.left,
        tower.top + s * .2,
        tower.right,
        tower.top + s * .28,
      );
      c.drawRect(band, _sweep(band, [ink.tile.$3, ink.tile.$2, ink.tile.$1]));
      for (var k = 0; k < 5; k++) {
        c.drawCircle(
          Offset(band.left + band.width * (k + .5) / 5, band.center.dy),
          s * .014,
          _fill(ink.gilt.$1),
        );
      }
      final lip = Rect.fromLTRB(
        tower.left - s * .05,
        tower.top,
        tower.right + s * .05,
        tower.top + s * .14,
      );
      c.drawRect(lip, _sweep(lip, [shade, face, lit]));
      c.drawRect(
        Rect.fromLTRB(lip.left, lip.bottom, lip.right, lip.bottom + s * .03),
        _fill(Sketch.fade(ink.deep, .5)),
      );
      _merlons(c, lip.left, lip.right, (_) => lip.top + .5, s * .16, face, lit);
      for (final fy in const [.45, .7]) {
        c.drawRect(
          Rect.fromLTRB(
            tx - s * .025,
            tower.top + tower.height * fy,
            tx + s * .025,
            tower.top + tower.height * fy + s * .14,
          ),
          _fill(ink.deep),
        );
      }
      final pole = Offset(tx, tower.top - s * .1);
      c.drawLine(
        Offset(tx, tower.top + 1),
        pole - Offset(0, s * .5),
        _pen(ink.wood, math.max(.8, s * .025)),
      );
      banners.add((pole - Offset(0, s * .5), s * .38));
    }
  }

  static const _bannerColors = [
    Color(0xffc23f3a),
    Color(0xff2a9a9a),
    Color(0xffe7a93a),
  ];

  /// Lamps flicker in the windows, banners stream toward the left on the
  /// dawn wind, doves wheel round the tallest minaret and smoke curls from a
  /// few roofs.
  void _cityLive(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h;
    final paint = Paint();
    final lamps = _cityLamps[(w, h)] ?? const <Offset>[];
    for (var i = 0; i < lamps.length; i++) {
      final flick =
          .55 +
          .25 * math.sin(f.clock * (5.1 + i % 3) + i * 1.7) +
          .2 * math.sin(f.clock * 11.3 + i);
      paint.color = Sketch.fade(const Color(0xffffc46a), .22 * flick);
      c.drawCircle(lamps[i], h * .009, paint);
    }
    final banners = _cityBanners[(w, h)] ?? const <(Offset, double)>[];
    for (var i = 0; i < banners.length; i++) {
      final (at, s) = banners[i];
      final path = Path()..moveTo(at.dx, at.dy);
      const n = 6;
      for (var k = 1; k <= n; k++) {
        final t = k / n;
        path.lineTo(
          at.dx - s * t,
          at.dy +
              s * .08 * t +
              math.sin(f.clock * 3.2 - t * 4 + i) * s * .08 * t,
        );
      }
      for (var k = n; k >= 0; k--) {
        final t = k / n;
        path.lineTo(
          at.dx - s * t,
          at.dy +
              s * (.34 - .16 * t) +
              s * .08 * t +
              math.sin(f.clock * 3.2 - t * 4 + i) * s * .08 * t,
        );
      }
      paint.color = _bannerColors[i % 3];
      c.drawPath(path..close(), paint);
    }
    // Doves round the Mamluk minaret.
    final s = _mosqueS(w, h);
    final m = _mosqueBase(w, h) - Offset(s * 2.25, s * 4.2);
    for (var i = 0; i < 5; i++) {
      final a = f.clock * (.5 + .08 * i) + i * 1.3;
      final p =
          m +
          Offset(
            math.cos(a) * h * (.05 + .012 * i),
            math.sin(a) * h * .018 + h * (.02 + .008 * i),
          );
      Sketch.bird(
        c,
        p,
        h * .006,
        const Color(0xfff6ece6),
        flap: math.sin(f.clock * 9 + i * 2),
      );
    }
    // Smoke from bread ovens on the roofs.
    for (final (fx, seed) in const [(.12, 1), (.44, 2), (.74, 3)]) {
      final x = w * fx, top = _y(Depth.mid, x, h) - h * .1;
      for (var j = 0; j < 8; j++) {
        final age = (f.clock * .09 + j / 8 + seed * .3) % 1;
        paint.color = Sketch.fade(
          const Color(0xfff3e4e0),
          .26 * (1 - age) * math.min(1.0, age * 6),
        );
        c.drawCircle(
          Offset(
            x - age * age * h * .06 + math.sin(age * 6 + seed) * h * .004,
            top - age * h * .1,
          ),
          h * (.003 + .008 * age),
          paint,
        );
      }
    }
  }

  /// Draws a cached overlay [picture], faded by [presence] during a crossing.
  static void _faded(Canvas c, Picture picture, double presence) {
    if (presence <= .004) return;
    if (presence >= .996) {
      c.drawPicture(picture);
      return;
    }
    c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, presence));
    c.drawPicture(picture);
    c.restore();
  }

  static final _approachArts = <(double, double), Picture>{};

  /// The ground outside the walls, recorded once per viewport: the road from
  /// the gate toward the oasis, walled gardens of palms and green crops, and
  /// a few early travellers.
  Picture _approachArt(double w, double h) {
    final key = (w, h);
    final cached = _approachArts[key];
    if (cached != null) return cached;
    if (_approachArts.length > 6) {
      _approachArts.remove(_approachArts.keys.first)!.dispose();
    }
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    final ink = _Clay(.16);
    double ground(double x) => _y(Depth.mid, x, h);
    final gx = _gateX(w), left = _cityLeft(w, h);
    final (lit, face, shade) = ink.rose;
    // Walled orchards along the foot of the walls: (x0, x1, depth below
    // the ridge in h, palms).
    final leaf = Paint(), leafLit = Paint();
    for (final (x0, x1, depth, palms) in [
      (left - h * .42, gx - h * .09, .05, 4),
      (gx + h * .1, gx + h * .52, .045, 1),
      (w * .66, w * .93, .05, 4),
      (w * .95, w + h * .6, .045, 3),
    ]) {
      // A greener floor under the trees, feathered at both ends.
      final floor = Path()..moveTo(x0 - h * .02, ground(x0) + h * .012);
      for (var x = x0; x <= x1; x += h * .02) {
        floor.lineTo(x, ground(x) + h * .006);
      }
      floor
        ..lineTo(x1 + h * .02, ground(x1) + h * .012)
        ..quadraticBezierTo(
          x1 + h * .03,
          ground(x1) + h * depth,
          x1 - h * .02,
          ground(x1) + h * depth,
        )
        ..lineTo(x0 + h * .02, ground(x0) + h * depth)
        ..quadraticBezierTo(
          x0 - h * .03,
          ground(x0) + h * depth,
          x0 - h * .02,
          ground(x0) + h * .012,
        )
        ..close();
      c.drawPath(floor, _fill(Sketch.mix(ink.frond, face, .62)));
      // Crowns of fig, pomegranate and citrus in two ragged rows, the far
      // row darker, each crown three lobes lit on the sunward side.
      for (var row = 0; row < 2; row++) {
        final n = ((x1 - x0) / (h * (row == 0 ? .022 : .03))).floor();
        for (var i = 0; i < n; i++) {
          final hsh = Sketch.hash(i * 7 + row * 131 + x0.round());
          if (hsh < .18) continue;
          final x =
              x0 + (x1 - x0) * (i + Sketch.hash(i * 3 + row + x1.round())) / n;
          final y =
              ground(x) + h * (row == 0 ? .014 : depth * .72) + h * .006 * hsh;
          final r = h * (row == 0 ? .006 + .005 * hsh : .008 + .007 * hsh);
          leaf.color = Sketch.mix(ink.frond, ink.deep, row == 0 ? .3 : .08);
          leafLit.color = Sketch.mix(ink.frondLit, lit, row == 0 ? .1 : .25);
          for (final (dx, dy, k) in const [
            (-.7, .2, .7),
            (.65, .25, .65),
            (0.0, -.15, 1.0),
          ]) {
            c.drawCircle(Offset(x + dx * r, y + dy * r), r * k, leaf);
          }
          c.drawCircle(Offset(x + r * .35, y - r * .45), r * .5, leafLit);
          c.drawCircle(Offset(x + r * .85, y + r * .05), r * .3, leafLit);
          if (hsh > .9) {
            c.drawCircle(Offset(x - r * .3, y), r * .18, _fill(ink.madder));
          }
        }
      }
      // Low mud walls in broken runs along the far edge.
      for (var x = x0; x < x1; x += h * .09) {
        final run = Path()..moveTo(x, ground(x) + h * .007);
        final end = math.min(x1, x + h * (.05 + .03 * Sketch.hash(x.round())));
        for (var t = x; t <= end; t += h * .01) {
          run.lineTo(t, ground(t) + h * .007);
        }
        c.drawPath(run, _pen(face, h * .007));
        c.drawPath(run, _pen(lit, h * .0025));
      }
      for (var i = 0; i < palms; i++) {
        final x =
            x0 +
            (x1 - x0) * (i + .3 + .4 * Sketch.hash(i + x0.round())) / palms;
        _datePalm(
          c,
          Offset(x, ground(x) + h * depth * (.45 + .45 * Sketch.hash(i + 7))),
          h * (.07 + .035 * Sketch.hash(i + 13 + x1.round())),
          (Sketch.hash(i + 21) - .5) * .3,
          ink,
          seed: i + 40,
          dates: i.isOdd,
        );
      }
    }
    // The road from the gate, worn pale, with wheel ruts.
    final road = Path()
      ..moveTo(gx - h * .04, ground(gx) + h * .004)
      ..lineTo(gx + h * .04, ground(gx) + h * .004)
      ..quadraticBezierTo(gx + h * .06, h * .8, gx + h * .15, h * .86)
      ..lineTo(gx - h * .05, h * .86)
      ..quadraticBezierTo(
        gx - h * .05,
        h * .8,
        gx - h * .04,
        ground(gx) + h * .004,
      )
      ..close();
    c.drawPath(road, _fill(Sketch.mix(lit, const Color(0xfffff0e0), .3)));
    final rut = _pen(Sketch.fade(shade, .5), math.max(.6, h * .0018));
    for (final k in const [-.015, .015]) {
      c.drawPath(
        Path()
          ..moveTo(gx + h * k, ground(gx) + h * .006)
          ..quadraticBezierTo(
            gx + h * (k + .01),
            h * .8,
            gx + h * (k * 2.4 + .05),
            h * .86,
          ),
        rut,
      );
    }
    // Early travellers: a donkey rider and a water carrier on the road.
    _figure(c, Offset(gx + h * .022, h * .79), h * .03, ink.indigo, ink);
    _figure(
      c,
      Offset(gx - h * .012, h * .775),
      h * .026,
      const Color(0xfff2e6d6),
      ink,
      jar: true,
    );
    _donkey(c, Offset(gx + h * .05, h * .815), h * .03, ink);
    return _approachArts[key] = recorder.endRecording();
  }

  /// A tiny robed figure, [s] tall, in a headcloth; with [jar] a water jar
  /// balanced on the head.
  static void _figure(
    Canvas c,
    Offset foot,
    double s,
    Color robe,
    _Clay ink, {
    bool jar = false,
  }) {
    final x = foot.dx, y = foot.dy;
    c.drawPath(
      Sketch.poly([
        x - s * .16,
        y,
        x + s * .16,
        y,
        x + s * .09,
        y - s * .78,
        x - s * .09,
        y - s * .78,
      ]),
      _fill(robe),
    );
    c.drawPath(
      Sketch.poly([
        x + s * .02,
        y,
        x + s * .16,
        y,
        x + s * .09,
        y - s * .78,
        x + s * .02,
        y - s * .78,
      ]),
      _fill(Sketch.mix(robe, const Color(0xffffffff), .25)),
    );
    c.drawCircle(
      Offset(x, y - s * .86),
      s * .1,
      _fill(const Color(0xff9a6448)),
    );
    c.drawPath(
      Sketch.poly([
        x - s * .12,
        y - s * .84,
        x - s * .09,
        y - s * .98,
        x + s * .09,
        y - s * .98,
        x + s * .11,
        y - s * .86,
        x - s * .02,
        y - s * .9,
        x - s * .06,
        y - s * .66,
      ]),
      _fill(jar ? ink.indigo : ink.white.$1),
    );
    if (jar) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, y - s * 1.08),
          width: s * .22,
          height: s * .2,
        ),
        _fill(const Color(0xffb86a4c)),
      );
    }
  }

  /// A small grey donkey laden with baskets, facing the gate.
  static void _donkey(Canvas c, Offset foot, double s, _Clay ink) {
    final x = foot.dx, y = foot.dy;
    const coat = Color(0xff9a8a8c), belly = Color(0xffc8bcb8);
    final leg = _pen(Sketch.mix(coat, ink.dark, .3), math.max(.6, s * .07));
    for (final dx in const [-.32, -.2, .2, .3]) {
      c.drawLine(Offset(x + s * dx, y - s * .45), Offset(x + s * dx, y), leg);
    }
    c.drawOval(
      Rect.fromLTRB(x - s * .45, y - s * .78, x + s * .4, y - s * .4),
      _fill(coat),
    );
    c.drawOval(
      Rect.fromLTRB(x - s * .35, y - s * .58, x + s * .3, y - s * .42),
      _fill(belly),
    );
    c.drawPath(
      Sketch.poly([
        x - s * .3,
        y - s * .7,
        x - s * .52,
        y - s * 1.0,
        x - s * .72,
        y - s * .92,
        x - s * .62,
        y - s * .8,
        x - s * .45,
        y - s * .6,
      ]),
      _fill(coat),
    );
    c.drawLine(
      Offset(x - s * .5, y - s * .98),
      Offset(x - s * .46, y - s * 1.2),
      _pen(coat, math.max(.6, s * .06)),
    );
    c.drawOval(
      Rect.fromLTRB(x - s * .2, y - s * .98, x + s * .2, y - s * .66),
      _fill(ink.saffron),
    );
    c.drawOval(
      Rect.fromLTRB(x - s * .12, y - s * .92, x + s * .12, y - s * .74),
      _fill(Sketch.mix(ink.saffron, ink.wood, .4)),
    );
  }

  // ---------------------------------------------------------------------------
  // Low band: the oasis, the souk, a caravanserai and the tents.

  /// The oasis, one repeat from x = 0: a palm grove round the pool and its
  /// well, the souk with its shoppers, rugs and a donkey, the caravanserai,
  /// and the tents and a domed tomb under their own palms.
  void _oasis(Canvas c, double h, double span) {
    final ink = _Clay(.06);
    double ground(double x) => _y(Depth.low, x, h);
    // A grove round the pool, back palms first.
    for (final (u, ht, lean, seed) in const [
      (.14, .12, -.08, 1),
      (.26, .16, .06, 2),
      (.8, .15, .1, 4),
      (.93, .11, -.05, 5),
      (2.46, .15, -.1, 7),
      (3.12, .14, .12, 8),
    ]) {
      final x = u * h;
      _datePalm(
        c,
        Offset(x, ground(x) + h * .006),
        h * ht,
        lean,
        ink,
        dates: seed.isEven,
        seed: seed,
      );
    }
    for (var i = 0; i < 4; i++) {
      final u = [1.08, 1.24, 1.4, 1.56][i];
      _stall(c, Offset(u * h, ground(u * h) + h * .004), h * .06, i, ink);
    }
    _rugLine(c, 1.63 * h, h, ground(1.63 * h), ink);
    // Shoppers, a porter's sacks and a laden donkey.
    for (final (u, robe, jar) in [
      (1.02, ink.saffron, false),
      (1.16, ink.indigo, false),
      (1.31, const Color(0xfff2e6d6), true),
      (1.48, ink.madder, false),
      (1.71, const Color(0xfff2e6d6), false),
    ]) {
      final x = u * h;
      _figure(
        c,
        Offset(x, ground(x) + h * .006),
        h * .045,
        robe,
        ink,
        jar: jar,
      );
    }
    for (final u in const [1.18, 1.21, 1.52]) {
      final x = u * h;
      final at = Offset(x, ground(x) + h * .002);
      c.drawOval(
        Rect.fromCenter(center: at, width: h * .014, height: h * .016),
        _fill(const Color(0xffcfae82)),
      );
      c.drawOval(
        Rect.fromCenter(
          center: at - Offset(0, h * .007),
          width: h * .012,
          height: h * .005,
        ),
        _fill(
          Sketch.mix(ink.saffron, ink.madder, Sketch.hash((u * 100).round())),
        ),
      );
    }
    _donkey(c, Offset(1.84 * h, ground(1.84 * h) + h * .006), h * .045, ink);
    _caravanserai(
      c,
      Offset(2.08 * h, ground(2.08 * h) + h * .006),
      h * .1,
      ink,
    );
    _tent(c, Offset(2.66 * h, ground(2.66 * h) + h * .004), h * .06, ink, 0);
    _tent(c, Offset(2.9 * h, ground(2.9 * h) + h * .004), h * .05, ink, 1);
    _qubba(c, Offset(3.03 * h, ground(3.03 * h) + h * .004), h * .05, ink);
    _well(c, Offset(.52 * h, ground(.52 * h) + h * .002), h * .04, ink);
  }

  /// A souk stall: two poles holding a striped awning of dyed cloth with a
  /// scalloped valance, a counter of goods beneath (cones of spice, baskets
  /// and brass pots) and a lantern hung from the ridge.
  static void _stall(Canvas c, Offset foot, double s, int seed, _Clay ink) {
    final x = foot.dx, y = foot.dy;
    final stripes = [
      [ink.madder, const Color(0xfff7e6d0)],
      [ink.indigo, const Color(0xfff2d9a8)],
      [ink.saffron, ink.madder],
      [ink.tile.$2, const Color(0xfff7ead8)],
    ][seed % 4];
    final pole = _pen(ink.wood, math.max(.8, s * .05));
    c.drawLine(Offset(x - s * .7, y), Offset(x - s * .7, y - s * .95), pole);
    c.drawLine(Offset(x + s * .7, y), Offset(x + s * .7, y - s * 1.15), pole);
    // Goods on the counter.
    final counter = Rect.fromLTRB(x - s * .65, y - s * .32, x + s * .65, y);
    c.drawRect(counter, _fill(ink.wood));
    c.drawRect(
      Rect.fromLTRB(
        counter.left,
        counter.top,
        counter.right,
        counter.top + s * .05,
      ),
      _fill(ink.woodLit),
    );
    final spices = [
      ink.saffron,
      ink.madder,
      const Color(0xff8a4a6a),
      const Color(0xffd27a2a),
      const Color(0xff7a8a3a),
    ];
    for (var i = 0; i < 4; i++) {
      final cx = counter.left + counter.width * (i + .5) / 4;
      if ((i + seed).isOdd) {
        c.drawPath(
          Sketch.poly([
            cx - s * .13,
            counter.top,
            cx,
            counter.top - s * .2,
            cx + s * .13,
            counter.top,
          ]),
          _fill(spices[(i + seed) % 5]),
        );
        c.drawRect(
          Rect.fromLTRB(
            cx - s * .15,
            counter.top - s * .03,
            cx + s * .15,
            counter.top + s * .02,
          ),
          _fill(Sketch.mix(ink.wood, ink.saffron, .4)),
        );
      } else {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, counter.top - s * .08),
            width: s * .2,
            height: s * .16,
          ),
          _fill(ink.gilt.$2),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx + s * .03, counter.top - s * .1),
            width: s * .07,
            height: s * .05,
          ),
          _fill(ink.gilt.$1),
        );
      }
    }
    // The awning, sloping down toward the street, with a scalloped edge.
    final back = y - s * 1.15, fore = y - s * .9;
    final awning = Sketch.poly([
      x - s * .85,
      fore,
      x - s * .78,
      back + s * .05,
      x + s * .82,
      back - s * .05,
      x + s * .9,
      fore - s * .05,
    ]);
    c.drawPath(awning, _fill(stripes[0]));
    c.save();
    c.clipPath(awning);
    for (var k = 0; k < 8; k++) {
      if (k.isOdd) continue;
      final sx = x - s * .85 + s * 1.75 * k / 8;
      c.drawRect(
        Rect.fromLTRB(sx, back - s * .2, sx + s * 1.75 / 8, fore + s * .1),
        _fill(stripes[1]),
      );
    }
    c.drawRect(
      Rect.fromLTRB(x - s, back - s * .2, x + s, back + s * .08),
      _fill(Sketch.fade(const Color(0xffffffff), .2)),
    );
    c.restore();
    final valance = Path()..moveTo(x - s * .85, fore);
    for (var k = 0; k < 7; k++) {
      final x0 = x - s * .85 + s * 1.75 * k / 7,
          x1 = x - s * .85 + s * 1.75 * (k + 1) / 7;
      final y0 = fore - s * .05 * k / 7, y1 = fore - s * .05 * (k + 1) / 7;
      valance.quadraticBezierTo((x0 + x1) / 2, (y0 + y1) / 2 + s * .14, x1, y1);
    }
    valance.lineTo(x + s * .9, fore - s * .07);
    valance.lineTo(x - s * .85, fore - s * .02);
    c.drawPath(valance..close(), _fill(stripes[0]));
    // A lantern hung under the awning.
    final lamp = Offset(x + s * .2, fore + s * .2);
    c.drawLine(
      Offset(lamp.dx, fore),
      lamp - Offset(0, s * .08),
      _pen(ink.gilt.$3, math.max(.5, s * .02)),
    );
    c.drawPath(
      Sketch.poly([
        lamp.dx - s * .06,
        lamp.dy - s * .06,
        lamp.dx + s * .06,
        lamp.dy - s * .06,
        lamp.dx + s * .04,
        lamp.dy + s * .08,
        lamp.dx - s * .04,
        lamp.dy + s * .08,
      ]),
      _fill(ink.lamp),
    );
    c.drawRect(
      Rect.fromLTRB(
        lamp.dx - s * .07,
        lamp.dy - s * .1,
        lamp.dx + s * .07,
        lamp.dy - s * .06,
      ),
      _fill(ink.gilt.$2),
    );
  }

  /// A line of rugs airing between two posts, in madder, indigo and saffron.
  static void _rugLine(Canvas c, double x, double h, double ground, _Clay ink) {
    final s = h * .05;
    final pole = _pen(ink.wood, math.max(.8, s * .05));
    c.drawLine(Offset(x - s, ground), Offset(x - s, ground - s * 1.1), pole);
    c.drawLine(
      Offset(x + s * 1.2, ground),
      Offset(x + s * 1.2, ground - s * 1.1),
      pole,
    );
    c.drawLine(
      Offset(x - s, ground - s * 1.05),
      Offset(x + s * 1.2, ground - s * 1.02),
      _pen(ink.trunkShade, math.max(.5, s * .02)),
    );
    for (final (dx, col, trim) in [
      (-.9, ink.madder, ink.saffron),
      (-.2, ink.indigo, ink.madder),
      (.5, Sketch.mix(ink.madder, ink.saffron, .5), ink.indigo),
    ]) {
      final r = Rect.fromLTWH(x + s * dx, ground - s * 1.04, s * .6, s * .72);
      c.drawRect(r, _fill(col));
      c.drawRect(r.deflate(s * .08), _fill(trim));
      c.drawRect(r.deflate(s * .14), _fill(col));
      c.drawPath(
        Sketch.poly([
          r.center.dx,
          r.top + s * .2,
          r.center.dx + s * .12,
          r.center.dy,
          r.center.dx,
          r.bottom - s * .2,
          r.center.dx - s * .12,
          r.center.dy,
        ]),
        _fill(trim),
      );
      final fringe = _pen(const Color(0xfff4e6cc), math.max(.4, s * .02));
      for (var fx = r.left + s * .04; fx < r.right; fx += s * .07) {
        c.drawLine(
          Offset(fx, r.bottom),
          Offset(fx, r.bottom + s * .06),
          fringe,
        );
      }
    }
  }

  /// A caravanserai: a long blind-walled khan with round corner towers, a
  /// tall portal framing a pointed arch, a dome over the entrance hall and
  /// stepped merlons.
  static void _caravanserai(Canvas c, Offset foot, double s, _Clay ink) {
    final (lit, face, shade) = ink.ochre;
    final x = foot.dx, y = foot.dy;
    final wall = Rect.fromLTRB(x - s * 2.6, y - s * .62, x + s * 2.6, y);
    c.drawRect(wall, _fill(face));
    c.drawRect(
      Rect.fromLTRB(wall.left, wall.top, wall.right, wall.top + s * .04),
      _fill(lit),
    );
    _merlons(c, wall.left, wall.right, (_) => wall.top + .5, s * .1, face, lit);
    // Blind arcading along the walls.
    for (var i = 0; i < 12; i++) {
      final ax = wall.left + wall.width * (i + .5) / 12;
      if ((ax - x).abs() < s * .75) continue;
      c.drawPath(
        _arch(ax, s * .08, y - s * .3, y - s * .1, point: .4),
        _fill(Sketch.mix(face, shade, .6)),
      );
    }
    c.drawRect(
      Rect.fromLTRB(wall.left, y - s * .08, wall.right, y),
      _fill(Sketch.fade(shade, .5)),
    );
    // The dome behind the portal.
    _dome(c, Offset(x - s * .05, wall.top - s * .15), s * .36, s * .5, 2, ink);
    // The portal.
    final portal = Rect.fromLTRB(x - s * .6, y - s * 1.08, x + s * .6, y);
    c.drawRect(portal, _fill(face));
    c.drawRect(
      Rect.fromLTRB(
        portal.right - s * .16,
        portal.top,
        portal.right,
        portal.bottom,
      ),
      _fill(lit),
    );
    c.drawRect(portal.deflate(s * .08), _fill(ink.tile.$2));
    c.drawRect(portal.deflate(s * .12), _fill(face));
    c.drawPath(
      _arch(x, s * .34, y - s * .5, y, point: .35),
      _fill(Sketch.mix(face, shade, .5)),
    );
    c.drawPath(
      _arch(x, s * .2, y - s * .34, y, point: .4, shoe: .5),
      _fill(ink.dark),
    );
    _merlons(
      c,
      portal.left,
      portal.right,
      (_) => portal.top + .5,
      s * .13,
      face,
      lit,
    );
    for (final tx in [wall.left, wall.right]) {
      final tower = Rect.fromLTRB(tx - s * .22, y - s * .82, tx + s * .22, y);
      c.drawRect(tower, _sweep(tower, [shade, face, lit]));
      _merlons(
        c,
        tower.left,
        tower.right,
        (_) => tower.top + .5,
        s * .12,
        face,
        lit,
      );
    }
    // Camels couched by the gate.
    for (final (dx, flip) in const [
      (-1.4, false),
      (1.25, true),
      (1.75, false),
    ]) {
      _couchedCamel(c, Offset(x + s * dx, y + s * .02), s * .32, flip, ink);
    }
  }

  /// A camel couched on the sand, its legs folded under it and its long
  /// neck raised, facing right (or left with [flip]).
  static void _couchedCamel(
    Canvas c,
    Offset foot,
    double s,
    bool flip,
    _Clay ink,
  ) {
    c.save();
    c.translate(foot.dx, foot.dy);
    c.scale(flip ? -s : s, s);
    Color tint(int argb) =>
        Sketch.mix(Color(argb), ArabiaScene._haze, ink.haze);
    c.drawPath(
      Path()
        ..moveTo(-1.05, 0)
        ..cubicTo(-1.1, -.35, -.75, -.62, -.45, -.72)
        ..cubicTo(-.3, -1.0, .05, -1.0, .2, -.72)
        ..cubicTo(.3, -.6, .45, -.55, .55, -.58)
        ..cubicTo(.7, -.66, .82, -.95, .98, -1.08)
        ..cubicTo(1.08, -1.14, 1.22, -1.12, 1.3, -1.04)
        ..cubicTo(1.36, -.98, 1.3, -.93, 1.22, -.94)
        ..cubicTo(1.1, -.95, 1.02, -.92, .96, -.86)
        ..cubicTo(.84, -.72, .76, -.46, .72, -.3)
        ..cubicTo(.72, -.15, .8, -.06, .85, 0)
        ..close(),
      _fill(tint(0xffbe8864)),
    );
    // The hump and neck catch the sun on the right.
    c.drawPath(
      Path()
        ..moveTo(-.2, -.94)
        ..cubicTo(0, -.98, .14, -.86, .2, -.72)
        ..cubicTo(.1, -.8, -.05, -.88, -.2, -.94)
        ..close(),
      _fill(tint(0xffe8b48a)),
    );
    // Belly shadow and the folded legs.
    c.drawPath(
      Path()
        ..moveTo(-1.05, 0)
        ..cubicTo(-1.06, -.2, -.9, -.32, -.6, -.3)
        ..lineTo(.6, -.22)
        ..lineTo(.85, 0)
        ..close(),
      _fill(tint(0xff8a5a4e)),
    );
    final fold = _pen(tint(0xff6e4640), .06);
    c.drawLine(const Offset(-.7, -.06), const Offset(-.2, -.1), fold);
    c.drawLine(const Offset(.2, -.08), const Offset(.62, -.04), fold);
    c.drawCircle(
      const Offset(1.16, -1.04),
      .035,
      _fill(const Color(0xff2a1a1a)),
    );
    c.restore();
  }

  /// A Bedouin tent of black goat hair on a row of poles, a striped curtain
  /// closing one end, its front open on a rug and a coffee hearth.
  static void _tent(Canvas c, Offset foot, double s, _Clay ink, int seed) {
    final x = foot.dx, y = foot.dy;
    const hair = Color(0xff735458), hairLit = Color(0xffa27c72);
    final roof = Path()
      ..moveTo(x - s * 1.6, y - s * .35)
      ..quadraticBezierTo(x - s * 1.1, y - s * .95, x - s * .5, y - s * .75)
      ..quadraticBezierTo(x, y - s * 1.0, x + s * .5, y - s * .75)
      ..quadraticBezierTo(x + s * 1.1, y - s * .95, x + s * 1.6, y - s * .35)
      ..lineTo(x + s * 1.5, y - s * .28)
      ..lineTo(x - s * 1.5, y - s * .28)
      ..close();
    c.drawRect(
      Rect.fromLTRB(x - s * 1.4, y - s * .4, x + s * 1.4, y),
      _fill(Sketch.mix(hair, ink.deep, .3)),
    );
    // The open front shows a rug and a hearth.
    c.drawRect(
      Rect.fromLTRB(x - s * .9, y - s * .12, x + s * .5, y),
      _fill(seed.isEven ? ink.madder : ink.indigo),
    );
    c.drawRect(
      Rect.fromLTRB(x - s * .8, y - s * .08, x + s * .4, y - s * .04),
      _fill(ink.saffron),
    );
    c.drawCircle(Offset(x + s * .9, y - s * .05), s * .07, _fill(ink.lamp));
    c.drawPath(roof, _fill(hair));
    c.drawPath(
      Path()
        ..moveTo(x + s * .5, y - s * .75)
        ..quadraticBezierTo(x + s * 1.1, y - s * .95, x + s * 1.6, y - s * .35)
        ..lineTo(x + s * 1.5, y - s * .28)
        ..lineTo(x + s * .5, y - s * .5)
        ..close(),
      _fill(hairLit),
    );
    // The striped side curtain.
    final curtain = Rect.fromLTRB(x + s * 1.1, y - s * .4, x + s * 1.5, y);
    c.drawRect(curtain, _fill(const Color(0xfff2e2cc)));
    for (var k = 0; k < 4; k++) {
      c.drawRect(
        Rect.fromLTRB(
          curtain.left,
          curtain.top + curtain.height * (k + .3) / 4,
          curtain.right,
          curtain.top + curtain.height * (k + .55) / 4,
        ),
        _fill(k.isEven ? ink.madder : hair),
      );
    }
    final rope = _pen(Sketch.fade(hairLit, .8), math.max(.5, s * .02));
    c.drawLine(Offset(x - s * 1.6, y - s * .35), Offset(x - s * 2.0, y), rope);
    c.drawLine(Offset(x + s * 1.6, y - s * .35), Offset(x + s * 2.0, y), rope);
  }

  /// A whitewashed domed tomb.
  static void _qubba(Canvas c, Offset foot, double s, _Clay ink) {
    final (lit, face, _) = ink.white;
    final x = foot.dx, y = foot.dy;
    c.drawRect(
      Rect.fromLTRB(x - s * .6, y - s * .7, x + s * .6, y),
      _fill(face),
    );
    c.drawRect(
      Rect.fromLTRB(x + s * .25, y - s * .7, x + s * .6, y),
      _fill(lit),
    );
    c.drawPath(
      _arch(x - s * .1, s * .16, y - s * .32, y, point: .45),
      _fill(ink.deep),
    );
    _merlons(c, x - s * .6, x + s * .6, (_) => y - s * .7, s * .12, face, lit);
    c.drawRect(
      Rect.fromLTRB(x - s * .42, y - s * .82, x + s * .42, y - s * .68),
      _fill(face),
    );
    _dome(c, Offset(x, y - s * .82), s * .4, s * .62, 2, ink);
  }

  /// A stone well with a timber frame, a pulley and a leather bucket.
  static void _well(Canvas c, Offset foot, double s, _Clay ink) {
    final (lit, face, shade) = ink.ochre;
    final x = foot.dx, y = foot.dy;
    final curb = Rect.fromLTRB(x - s * .6, y - s * .45, x + s * .6, y);
    c.drawRect(curb, _sweep(curb, [shade, face, lit]));
    c.drawRect(
      Rect.fromLTRB(
        curb.left - s * .05,
        curb.top - s * .06,
        curb.right + s * .05,
        curb.top,
      ),
      _fill(lit),
    );
    final beam = _pen(ink.wood, math.max(.8, s * .07));
    c.drawLine(
      Offset(x - s * .45, curb.top),
      Offset(x - s * .3, y - s * 1.4),
      beam,
    );
    c.drawLine(
      Offset(x + s * .45, curb.top),
      Offset(x + s * .3, y - s * 1.4),
      beam,
    );
    c.drawLine(
      Offset(x - s * .45, y - s * 1.36),
      Offset(x + s * .45, y - s * 1.36),
      beam,
    );
    c.drawCircle(Offset(x, y - s * 1.28), s * .1, _fill(ink.woodLit));
    c.drawLine(
      Offset(x, y - s * 1.28),
      Offset(x, y - s * .7),
      _pen(ink.trunkShade, math.max(.5, s * .025)),
    );
    c.drawPath(
      Sketch.poly([
        x - s * .1,
        y - s * .72,
        x + s * .1,
        y - s * .72,
        x + s * .07,
        y - s * .55,
        x - s * .07,
        y - s * .55,
      ]),
      _fill(ink.wood),
    );
  }

  /// Lanterns glow in the souk and the tent hearth's smoke rises.
  void _oasisLive(Canvas c, SceneFrame f) {
    final h = f.h;
    final paint = Paint();
    for (var i = 0; i < 4; i++) {
      final u = [1.08, 1.24, 1.4, 1.56][i];
      final s = h * .06;
      final at = Offset(
        u * h + s * .2,
        _y(Depth.low, u * h, h) + h * .004 - s * .9 + s * .21,
      );
      final flick =
          .6 +
          .25 * math.sin(f.clock * 6 + i * 2) +
          .15 * math.sin(f.clock * 13 + i);
      paint.color = Sketch.fade(const Color(0xffffc46a), .3 * flick);
      c.drawCircle(at, h * .012, paint);
    }
    final hearth = Offset(
      2.66 * h + h * .054,
      _y(Depth.low, 2.66 * h, h) - h * .004,
    );
    for (var j = 0; j < 9; j++) {
      final age = (f.clock * .1 + j / 9) % 1;
      paint.color = Sketch.fade(
        const Color(0xffe8dcdc),
        .3 * (1 - age) * math.min(1.0, age * 6),
      );
      c.drawCircle(
        Offset(
          hearth.dx - age * age * h * .05 + math.sin(age * 6) * h * .004,
          hearth.dy - age * h * .12,
        ),
        h * (.003 + .008 * age),
        paint,
      );
    }
  }

  static final _oasisArts = <double, List<(Path, Color)>>{};

  /// The pool among the palms and the oasis gardens, recorded once per
  /// viewport as flat paths.
  List<(Path, Color)> _oasisArt(double h) {
    final cached = _oasisArts[h];
    if (cached != null) return cached;
    if (_oasisArts.length > 6) _oasisArts.remove(_oasisArts.keys.first);
    double ground(double x) => _y(Depth.low, x, h);
    final out = <(Path, Color)>[];
    // Irrigated plots of green around the pool and under the far palms.
    final green = Path(), greenLit = Path();
    for (final (u0, u1) in const [(.02, 1.0), (2.35, 3.2)]) {
      for (var i = 0; i < 6; i++) {
        final cx = (u0 + (u1 - u0) * (i + .5) / 6) * h;
        final cy = ground(cx) + h * (.012 + .02 * Sketch.hash(i + 700));
        final rw = h * (.07 + .05 * Sketch.hash(i + 710));
        green.addOval(
          Rect.fromCenter(center: Offset(cx, cy), width: rw, height: h * .016),
        );
        greenLit.addOval(
          Rect.fromCenter(
            center: Offset(cx + rw * .1, cy - h * .003),
            width: rw * .7,
            height: h * .007,
          ),
        );
      }
    }
    out.add((green, const Color(0xcc5f8a5c)));
    out.add((greenLit, const Color(0xaa8fb46e)));
    // The pool: a bank, the water reflecting dawn and a sunlit far rim.
    final pool = Rect.fromLTRB(
      .34 * h,
      ground(.52 * h) + h * .008,
      .72 * h,
      ground(.52 * h) + h * .04,
    );
    out.add((Path()..addOval(pool.inflate(h * .006)), const Color(0xffb88064)));
    out.add((Path()..addOval(pool), const Color(0xff4aa6a8)));
    out.add((
      Path()..addOval(
        Rect.fromLTRB(
          pool.left + pool.width * .05,
          pool.top + pool.height * .35,
          pool.right - pool.width * .08,
          pool.bottom - pool.height * .1,
        ),
      ),
      const Color(0xff7cc6c0),
    ));
    out.add((
      Path()..addOval(
        Rect.fromLTRB(
          pool.left + pool.width * .2,
          pool.top + pool.height * .55,
          pool.right - pool.width * .2,
          pool.bottom - pool.height * .15,
        ),
      ),
      const Color(0xfff2c8b0),
    ));
    // Reeds at the water's edge.
    final reeds = Path();
    for (var i = 0; i < 14; i++) {
      final x = pool.left + pool.width * Sketch.hash(i + 720);
      final y = pool.top + pool.height * (.1 + .15 * Sketch.hash(i + 730));
      final ht = h * (.012 + .016 * Sketch.hash(i + 740));
      reeds.addPath(
        Sketch.poly([
          x - h * .0012,
          y,
          x + h * .004 * (Sketch.hash(i + 750) - .5),
          y - ht,
          x + h * .0012,
          y,
        ]),
        Offset.zero,
      );
    }
    out.add((reeds, const Color(0xff4e7a52)));
    return _oasisArts[h] = out;
  }

  static final _oasisPaint = Paint();

  /// The pool and gardens over the low ground, and glints on the water.
  void _oasisOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    for (final (path, color) in _oasisArt(h)) {
      _oasisPaint.color = Sketch.fade(color, presence);
      c.drawPath(path, _oasisPaint);
    }
    // Glints drifting on the pool.
    final pool = Offset(.53 * h, _y(Depth.low, .52 * h, h) + h * .026);
    final glint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final on = .5 + .5 * math.sin(f.clock * 1.6 + i * 2.1);
      glint
        ..strokeWidth = h * .0025
        ..color = Sketch.fade(const Color(0xfffff4e0), .7 * on * presence);
      final x = pool.dx + (Sketch.hash(i + 760) - .5) * h * .26;
      final y = pool.dy + (Sketch.hash(i + 770) - .5) * h * .014;
      c.drawLine(
        Offset(x - h * .008 * on, y),
        Offset(x + h * .008 * on, y),
        glint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Near band: rose dunes and the caravan.

  /// Standing things of the near dunes: a pair of date palms, a lantern post
  /// and water jars. The caravan walks in `live`.
  void _nearDunes(Canvas c, double h, double span) {
    final ink = _Clay(0);
    double ground(double x) => _y(Depth.near, x, h);
    // A pair of palms by a ruined stone and a lantern post.
    for (final (u, ht, lean, seed) in const [
      (2.62, .3, -.1, 11),
      (2.74, .2, .12, 12),
    ]) {
      final x = u * h;
      _datePalm(
        c,
        Offset(x, ground(x) + h * .02),
        h * ht,
        lean,
        ink,
        dates: true,
        seed: seed,
      );
    }
    _lanternPost(c, Offset(.62 * h, ground(.62 * h) + h * .01), h * .12, ink);
    _jars(c, Offset(.7 * h, ground(.7 * h) + h * .01), h * .03, ink);
  }

  /// A brass lantern hung from a crook of cedar.
  static void _lanternPost(Canvas c, Offset foot, double s, _Clay ink) {
    final x = foot.dx, y = foot.dy;
    final post = _pen(ink.wood, math.max(1.0, s * .045));
    c.drawLine(Offset(x, y), Offset(x, y - s), post);
    c.drawLine(Offset(x, y - s), Offset(x + s * .22, y - s * .96), post);
    final lamp = Offset(x + s * .22, y - s * .78);
    c.drawLine(
      Offset(lamp.dx, y - s * .96),
      lamp - Offset(0, s * .1),
      _pen(ink.gilt.$3, math.max(.5, s * .012)),
    );
    _brassLantern(c, lamp, s * .1, ink);
  }

  /// A pierced brass lantern with a glowing heart, [s] its half height.
  static void _brassLantern(Canvas c, Offset at, double s, _Clay ink) {
    c.drawCircle(at, s * 2.2, _fill(Sketch.fade(const Color(0xffffc46a), .18)));
    final body = Path()
      ..moveTo(at.dx - s * .55, at.dy - s * .5)
      ..lineTo(at.dx + s * .55, at.dy - s * .5)
      ..lineTo(at.dx + s * .7, at.dy + s * .2)
      ..lineTo(at.dx + s * .3, at.dy + s * .8)
      ..lineTo(at.dx - s * .3, at.dy + s * .8)
      ..lineTo(at.dx - s * .7, at.dy + s * .2)
      ..close();
    c.drawPath(body, _fill(ink.lamp));
    c.drawPath(body, _pen(ink.gilt.$3, math.max(.6, s * .12)));
    c.drawLine(
      Offset(at.dx, at.dy - s * .5),
      Offset(at.dx, at.dy + s * .8),
      _pen(ink.gilt.$3, math.max(.5, s * .08)),
    );
    c.drawPath(
      Sketch.poly([
        at.dx - s * .6,
        at.dy - s * .5,
        at.dx,
        at.dy - s * 1.1,
        at.dx + s * .6,
        at.dy - s * .5,
      ]),
      _fill(ink.gilt.$2),
    );
  }

  /// A few clay water jars leaning together.
  static void _jars(Canvas c, Offset foot, double s, _Clay ink) {
    for (final (dx, k) in const [(0.0, 1.0), (.9, .8), (-.7, .7)]) {
      final at = Offset(foot.dx + dx * s, foot.dy - s * k * .6);
      c.drawOval(
        Rect.fromCenter(center: at, width: s * k, height: s * k * 1.2),
        _fill(const Color(0xffb86a4c)),
      );
      c.drawOval(
        Rect.fromCenter(
          center: at + Offset(s * k * .18, -s * k * .1),
          width: s * k * .35,
          height: s * k * .6,
        ),
        _fill(const Color(0xffe0967a)),
      );
      c.drawRect(
        Rect.fromCenter(
          center: at - Offset(0, s * k * .62),
          width: s * k * .4,
          height: s * k * .18,
        ),
        _fill(const Color(0xff9a5040)),
      );
    }
  }

  static final _nearArts = <double, List<(Path, Color, double)>>{};

  /// The near dunes' light and shade, recorded once per viewport: violet
  /// shadow on every slip face, a sunlit shoulder on every windward back,
  /// ripples combed by the wind, the caravan's trail along the crests, and
  /// rocks and camelthorn scattered on the sand. Strokes carry their width;
  /// fills have none.
  List<(Path, Color, double)> _nearArt(double h) {
    final cached = _nearArts[h];
    if (cached != null) return cached;
    if (_nearArts.length > 6) _nearArts.remove(_nearArts.keys.first);
    final span = period(Depth.near) * h;
    double y(double x) => _y(Depth.near, x, h);
    final step = h * .006;
    final shade = Path()..moveTo(-step, y(-step));
    final lit = Path()..moveTo(-step, y(-step));
    final shadeBack = <Offset>[], litBack = <Offset>[];
    for (var x = -step; x <= span + step; x += step) {
      final slope = (y(x + step) - y(x - step)) / (2 * step);
      final yy = y(x);
      shade.lineTo(x, yy);
      lit.lineTo(x, yy);
      shadeBack.add(Offset(x, yy + h * .07 * _smooth(-slope * 5)));
      litBack.add(Offset(x, yy + h * .018 * _smooth(slope * 7)));
    }
    for (final p in shadeBack.reversed) {
      shade.lineTo(p.dx, p.dy);
    }
    for (final p in litBack.reversed) {
      lit.lineTo(p.dx, p.dy);
    }
    final ripples = Path();
    for (var r = 0; r < 18; r++) {
      final x0 = span * Sketch.hash(900 + r);
      final len = h * (.12 + .18 * Sketch.hash(910 + r));
      final dy = h * (.014 + .05 * Sketch.hash(920 + r));
      for (var k = 0; k <= 10; k++) {
        final x = x0 + len * k / 10;
        final yy = y(x) + dy + math.sin(k / 10 * math.pi) * h * .003;
        if (k == 0) {
          ripples.moveTo(x, yy);
        } else {
          ripples.lineTo(x, yy);
        }
      }
    }
    // The caravan's trail: paired hoof dimples a little below the crest.
    final trail = Path();
    for (var x = 0.0; x < span; x += h * .013) {
      final yy = y(x) + h * .012;
      trail.addOval(
        Rect.fromCenter(
          center: Offset(x, yy),
          width: h * .005,
          height: h * .0022,
        ),
      );
      trail.addOval(
        Rect.fromCenter(
          center: Offset(x + h * .006, yy + h * .004),
          width: h * .005,
          height: h * .0022,
        ),
      );
    }
    // Faceted rocks: a shaded body, a sunlit right face and a cast shadow.
    final rocks = Path(), rockLit = Path(), rockShadow = Path();
    for (var i = 0; i < 7; i++) {
      final x = span * (i + .3 + .4 * Sketch.hash(960 + i)) / 7;
      final base = y(x) + h * (.03 + .04 * Sketch.hash(970 + i));
      final s = h * (.008 + .012 * Sketch.hash(980 + i));
      rockShadow.addOval(
        Rect.fromLTRB(x - s * 2.6, base - s * .25, x + s * .4, base + s * .3),
      );
      rocks.addPath(
        Sketch.poly([
          x - s * 1.2,
          base,
          x - s * .9,
          base - s * .7,
          x - s * .1,
          base - s * 1.1,
          x + s * .8,
          base - s * .6,
          x + s * 1.1,
          base,
        ]),
        Offset.zero,
      );
      rockLit.addPath(
        Sketch.poly([
          x - s * .1,
          base - s * 1.1,
          x + s * .8,
          base - s * .6,
          x + s * 1.1,
          base,
          x + s * .3,
          base,
        ]),
        Offset.zero,
      );
      if (i.isEven) {
        final t = s * .55;
        rocks.addPath(
          Sketch.poly([
            x + s * 1.1,
            base,
            x + s * 1.3,
            base - t,
            x + s * 1.9,
            base - t * .8,
            x + s * 2.1,
            base,
          ]),
          Offset.zero,
        );
      }
    }
    // Camelthorn: fans of bare twigs with a few grey-green leaves.
    final twigs = Path(), leaves = Path();
    for (var i = 0; i < 9; i++) {
      final x = span * (i + .5 * Sketch.hash(930 + i)) / 9;
      final yy = y(x) + h * (.018 + .035 * Sketch.hash(940 + i));
      final s = h * (.012 + .014 * Sketch.hash(950 + i));
      for (var k = -3; k <= 3; k++) {
        final a = -math.pi / 2 + k * .3;
        final tip = Offset(
          x + math.cos(a) * s * (1 - k.abs() * .1),
          yy + math.sin(a) * s * (1 - k.abs() * .1),
        );
        twigs
          ..moveTo(x, yy)
          ..quadraticBezierTo(
            x + math.cos(a) * s * .3,
            yy + math.sin(a) * s * .6,
            tip.dx,
            tip.dy,
          );
        leaves.addOval(
          Rect.fromCenter(center: tip, width: s * .2, height: s * .14),
        );
      }
    }
    final out = [
      (shade..close(), const Color(0x708a5a7c), 0.0),
      (lit..close(), const Color(0x70fff0dc), 0.0),
      (ripples, const Color(0x55b0706a), math.max(1.0, h * .0028)),
      (trail, const Color(0x55935a60), 0.0),
      (rockShadow, const Color(0x40704060), 0.0),
      (rocks, const Color(0xff9a6a6a), 0.0),
      (rockLit, const Color(0xffe0a68a), 0.0),
      (twigs, const Color(0xcc6e5448), math.max(.8, h * .002)),
      (leaves, const Color(0xcc8a9a6a), 0.0),
    ];
    return _nearArts[h] = out;
  }

  static final _nearPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// The near dunes' cached light and shade, then sand blowing off the
  /// brinks.
  void _nearOverlay(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    for (final (path, color, width) in _nearArt(h)) {
      _nearPaint
        ..style = width > 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = width
        ..color = Sketch.fade(color, presence);
      c.drawPath(path, _nearPaint);
    }
    // Sand streams off each brink on the dawn wind, blowing left.
    _nearPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, h * .0022);
    final crests = _nearCrests.putIfAbsent(h, () {
      // The brinks of the two larger dune trains in the near ridge.
      final span = period(Depth.near) * h;
      return [
        for (final (n, len, shift) in const [(2, 1.6, 0.0), (4, .8, .3)])
          for (var k = 0; k < n; k++)
            (((k + .26 + .12 * Sketch.hash(k + 71) - shift) * len * h) % span)
                .toDouble(),
      ].map((x) => Offset(x, _y(Depth.near, x, h))).toList();
    });
    for (var i = 0; i < crests.length; i++) {
      for (var k = 0; k < 5; k++) {
        final age = (f.clock * .45 + k / 5 + i * .37) % 1;
        final p =
            crests[i] +
            Offset(
              -age * h * .07,
              -math.sin(age * math.pi) * h * .014 - age * h * .004,
            );
        _nearPaint.color = Sketch.fade(
          const Color(0xfffde6cc),
          .5 * (1 - age) * presence,
        );
        c.drawLine(p, p + Offset(h * .008 * (1 - age * .5), 0), _nearPaint);
      }
    }
  }

  static final _nearCrests = <double, List<Offset>>{};

  // ---------------------------------------------------------------------------
  // The caravan: camels and riders walking right along the near dunes.

  /// Camels of the caravan: (offset behind the leader in h, size, rider).
  static const _caravanCamels = [(0.0, 1.0, 1), (.15, .94, 0), (.29, 1.0, 2)];

  /// The caravan's walking speed in h per second and stride period.
  static const _caravanSpeed = .03, _caravanStride = 1.5;

  /// The caravan and its guide walking right along the crests; wrapping
  /// inside the repeat hands them to the next copy seamlessly.
  void _caravanLive(Canvas c, SceneFrame f) {
    final h = f.h;
    final span = period(Depth.near) * h;
    final lead = (h * 1.3 + f.clock * _caravanSpeed * h) % span;
    final ink = _Clay(0);
    // The guide walks ahead with his staff.
    final gx = lead + h * .07;
    _walker(
      c,
      Offset(gx, _y(Depth.near, gx, h) + h * .006),
      h * .075,
      f.clock,
      ink,
    );
    for (var i = 0; i < _caravanCamels.length; i++) {
      final (behind, size, rider) = _caravanCamels[i];
      final x = lead - behind * h;
      final foot = Offset(x, _y(Depth.near, x, h) + h * .008);
      final phase = f.clock / _caravanStride + i * .31;
      _camel(c, foot, h * .085 * size, phase, rider, ink, i);
    }
  }

  static final _camelBody = Path()
    ..moveTo(-.46, -.64)
    ..cubicTo(-.5, -.82, -.34, -.9, -.22, -.95)
    ..cubicTo(-.12, -1.07, .06, -1.08, .13, -.95)
    ..cubicTo(.19, -.87, .26, -.84, .32, -.8)
    ..cubicTo(.4, -.76, .47, -.74, .52, -.82)
    ..cubicTo(.56, -.9, .58, -.98, .64, -1.01)
    ..cubicTo(.7, -1.04, .77, -1.01, .8, -.96)
    ..cubicTo(.82, -.93, .79, -.9, .74, -.9)
    ..cubicTo(.68, -.9, .64, -.86, .62, -.8)
    ..cubicTo(.58, -.7, .5, -.62, .4, -.6)
    ..cubicTo(.3, -.54, .2, -.52, .1, -.53)
    ..cubicTo(-.1, -.55, -.3, -.51, -.42, -.55)
    ..close();

  static final _camelShade = Path()
    ..moveTo(-.46, -.64)
    ..cubicTo(-.48, -.74, -.4, -.8, -.3, -.78)
    ..cubicTo(-.1, -.72, .2, -.7, .38, -.62)
    ..cubicTo(.3, -.55, .2, -.52, .1, -.53)
    ..cubicTo(-.1, -.55, -.3, -.51, -.42, -.55)
    ..close();

  /// One camel walking right, [s] from feet to hump, legs swinging with
  /// [phase]; [rider] 0 carries bales, 1 and 2 carry robed riders.
  static void _camel(
    Canvas c,
    Offset foot,
    double s,
    double phase,
    int rider,
    _Clay ink,
    int seed,
  ) {
    const hide = Color(0xffc08a64), hideLit = Color(0xffe6b088);
    const hideShade = Color(0xff8a5a52);
    final bob = math.sin(phase * math.pi * 4) * s * .012;
    c.save();
    c.translate(foot.dx, foot.dy + bob);
    c.scale(s, s);
    // Legs: far pair in shade first, near pair over the body's belly.
    final far = Paint()
      ..color = hideShade
      ..strokeWidth = .065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final near = Paint()
      ..color = hide
      ..strokeWidth = .07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    void leg(double hipX, double t, Paint paint) {
      final swing = math.sin(t * math.pi * 2);
      final lift = math.max(0.0, math.cos(t * math.pi * 2));
      final hip = Offset(hipX, -.58);
      final foot = Offset(hipX + swing * .13, -lift * .06);
      final knee = Offset(
        (hip.dx + foot.dx) / 2 + .03 + lift * .04,
        -.3 - lift * .03,
      );
      c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..lineTo(knee.dx, knee.dy)
          ..lineTo(foot.dx, foot.dy)
          ..lineTo(foot.dx + .05, foot.dy),
        paint,
      );
    }

    leg(-.3, phase + .5, far);
    leg(.24, phase, far);
    // Tail.
    c.drawPath(
      Path()
        ..moveTo(-.45, -.66)
        ..quadraticBezierTo(
          -.53,
          -.6 + math.sin(phase * 6.28) * .02,
          -.5,
          -.46,
        ),
      far..strokeWidth = .03,
    );
    far.strokeWidth = .065;
    c.drawPath(_camelBody, Paint()..color = hide);
    c.drawPath(_camelShade, Paint()..color = hideShade.withValues(alpha: .6));
    c.drawPath(
      Path()
        ..moveTo(-.1, -1.04)
        ..cubicTo(.04, -1.07, .1, -1.0, .13, -.95)
        ..cubicTo(.08, -.99, 0, -1.02, -.1, -1.04)
        ..close(),
      Paint()..color = hideLit,
    );
    c.drawCircle(
      const Offset(.72, -.97),
      .014,
      Paint()..color = const Color(0xff2a1a1a),
    );
    leg(-.36, phase, near);
    leg(.3, phase + .5, near);
    // Saddle blanket with tassels.
    final cloth = [
      ink.madder,
      ink.indigo,
      Sketch.mix(ink.madder, ink.saffron, .4),
    ][seed % 3];
    final blanket = Path()
      ..moveTo(-.28, -.95)
      ..cubicTo(-.1, -1.02, .1, -1.02, .22, -.92)
      ..lineTo(.2, -.68)
      ..lineTo(-.3, -.7)
      ..close();
    c.drawPath(blanket, Paint()..color = cloth);
    c.drawPath(
      Path()
        ..moveTo(-.29, -.76)
        ..lineTo(.21, -.74)
        ..lineTo(.2, -.68)
        ..lineTo(-.3, -.7)
        ..close(),
      Paint()..color = ink.saffron,
    );
    final tassel = Paint()
      ..color = ink.saffron
      ..strokeWidth = .025
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 6; k++) {
      final tx = -.28 + k * .096;
      final sway = math.sin(phase * 6.28 + k) * .015;
      c.drawLine(Offset(tx, -.69), Offset(tx + sway, -.62), tassel);
    }
    // Halter and lead rope.
    c.drawLine(
      const Offset(.66, -.93),
      const Offset(.8, -.92),
      Paint()
        ..color = ink.madder
        ..strokeWidth = .02,
    );
    if (rider == 0) {
      // Bales of cloth and a rolled rug.
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.3, -1.18, .02, -.96),
          const Radius.circular(.04),
        ),
        Paint()..color = const Color(0xffe6d2b0),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.02, -1.16, .24, -.94),
          const Radius.circular(.04),
        ),
        Paint()..color = ink.indigo,
      );
      c.drawRect(
        const Rect.fromLTRB(-.3, -1.1, .02, -1.06),
        Paint()..color = ink.madder,
      );
      c.drawOval(
        const Rect.fromLTRB(-.36, -1.26, .3, -1.16),
        Paint()..color = Sketch.mix(ink.madder, ink.saffron, .3),
      );
    } else {
      // A robed rider: a flowing robe, a headcloth and its cord.
      final robe = rider == 1 ? ink.indigo : const Color(0xfff2e6d6);
      final robeShade = rider == 1
          ? Sketch.mix(ink.indigo, ink.dark, .4)
          : const Color(0xffc8b4b0);
      c.drawPath(
        Sketch.poly([-.16, -1.0, .12, -.98, .1, -.78, -.2, -.8]),
        Paint()..color = robeShade,
      );
      c.drawPath(
        Sketch.poly([-.12, -1.02, .1, -1.0, .06, -1.3, -.08, -1.3]),
        Paint()..color = robe,
      );
      c.drawPath(
        Sketch.poly([.02, -1.28, .06, -1.3, .12, -1.0, .06, -1.0]),
        Paint()..color = Sketch.mix(robe, const Color(0xffffffff), .25),
      );
      c.drawCircle(
        const Offset(-.01, -1.36),
        .06,
        Paint()..color = const Color(0xff9a6448),
      );
      c.drawPath(
        Sketch.poly([
          -.09,
          -1.36,
          -.06,
          -1.44,
          .05,
          -1.44,
          .07,
          -1.36,
          .01,
          -1.38,
          -.02,
          -1.26,
          -.1,
          -1.22,
        ]),
        Paint()..color = rider == 1 ? const Color(0xfff4ece0) : ink.madder,
      );
      c.drawRect(
        const Rect.fromLTRB(-.07, -1.43, .06, -1.41),
        Paint()..color = const Color(0xff2a1a1a),
      );
      // Reins to the halter.
      c.drawLine(
        const Offset(.08, -1.12),
        const Offset(.66, -.93),
        Paint()
          ..color = const Color(0xff4a3030)
          ..strokeWidth = .012,
      );
    }
    if (seed == 0) {
      // The leader carries a lantern on the saddle horn.
      c.drawLine(
        const Offset(.22, -.95),
        const Offset(.26, -.84),
        Paint()
          ..color = ink.gilt.$3
          ..strokeWidth = .012,
      );
      c.restore();
      _brassLantern(c, foot + Offset(s * .26, bob - s * .8), s * .045, ink);
      return;
    }
    c.restore();
  }

  /// The caravan's guide on foot, robed, with a staff over his shoulder.
  static void _walker(
    Canvas c,
    Offset foot,
    double s,
    double clock,
    _Clay ink,
  ) {
    final t = clock / _caravanStride * 1.4;
    final swing = math.sin(t * math.pi * 2);
    final leg = _pen(const Color(0xff5a3a36), math.max(.8, s * .05));
    c.drawLine(
      foot + Offset(0, -s * .42),
      foot + Offset(swing * s * .1, 0),
      leg,
    );
    c.drawLine(
      foot + Offset(0, -s * .42),
      foot + Offset(-swing * s * .1, 0),
      leg,
    );
    final robe = Path()
      ..moveTo(foot.dx - s * .12, foot.dy - s * .9)
      ..lineTo(foot.dx + s * .1, foot.dy - s * .9)
      ..lineTo(foot.dx + s * .16, foot.dy - s * .2)
      ..lineTo(foot.dx - s * .18, foot.dy - s * .2)
      ..close();
    c.drawPath(robe, _fill(const Color(0xfff0e4d4)));
    c.drawPath(
      Sketch.poly([
        foot.dx + s * .02,
        foot.dy - s * .9,
        foot.dx + s * .1,
        foot.dy - s * .9,
        foot.dx + s * .16,
        foot.dy - s * .2,
        foot.dx + s * .04,
        foot.dy - s * .2,
      ]),
      _fill(const Color(0xffffffff)),
    );
    c.drawRect(
      Rect.fromLTRB(
        foot.dx - s * .13,
        foot.dy - s * .56,
        foot.dx + s * .12,
        foot.dy - s * .52,
      ),
      _fill(ink.madder),
    );
    c.drawCircle(
      foot + Offset(0, -s * .98),
      s * .08,
      _fill(const Color(0xff9a6448)),
    );
    c.drawPath(
      Sketch.poly([
        foot.dx - s * .1,
        foot.dy - s * .98,
        foot.dx - s * .06,
        foot.dy - s * 1.08,
        foot.dx + s * .07,
        foot.dy - s * 1.08,
        foot.dx + s * .09,
        foot.dy - s * .98,
        foot.dx - s * .02,
        foot.dy - s * .96,
        foot.dx - s * .06,
        foot.dy - s * .8,
        foot.dx - s * .14,
        foot.dy - s * .78,
      ]),
      _fill(ink.madder),
    );
    c.drawLine(
      foot + Offset(-s * .25, -s * 1.1),
      foot + Offset(s * .25, -s * .3),
      _pen(ink.wood, math.max(.7, s * .03)),
    );
  }

  // ---------------------------------------------------------------------------
  // Sky: a teal dawn with the last stars, the crescent moon and the morning
  // star, rose-lit cloud streaks and birds.

  /// Where the compositor is drawing the sun right now: it slides between
  /// regions during a crossing and the glow must follow.
  SkyLight _sun(SceneFrame f) {
    final blend = WorldTour.at(f.seconds);
    if (!blend.crossing) return light;
    return SkyLight.lerp(
      RegionScene.of(blend.from).light,
      RegionScene.of(blend.to).light,
      blend.stage(0, 1),
    );
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final sun = _sun(f);
    _dawnWash(c, f, sun, presence);
    _dawnStars(c, f, presence);
    _dawnMoon(c, f, presence);
    _dawnRays(c, f, sun, presence);
    _dawnClouds(c, f, presence);
    _dawnCarpet(c, f, presence);
    _dawnBirds(c, f, presence);
  }

  /// Deep teal overhead away from the sun, a band of pale aqua, the rose
  /// belt and a gold bloom where the sun clears the horizon.
  void _dawnWash(Canvas c, SceneFrame f, SkyLight sun, double presence) {
    final w = f.w, h = f.h;
    final at = Offset(sun.at.dx * w, sun.at.dy * h);
    c.drawRect(
      Offset.zero & f.size,
      Paint()
        ..shader = Gradient.radial(Offset.zero, h * 1.3, [
          Sketch.fade(const Color(0xff1f5f78), .45 * presence),
          Sketch.fade(const Color(0xff1f5f78), 0),
        ]),
    );
    c.drawRect(
      Rect.fromLTWH(0, h * .12, w, h * .56),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .12),
          Offset(0, h * .68),
          [
            Sketch.fade(const Color(0xffbfe8dc), 0),
            Sketch.fade(const Color(0xffcdeee0), .3 * presence),
            Sketch.fade(const Color(0xfffbd6cc), .34 * presence),
            Sketch.fade(const Color(0xfff6b4b0), .42 * presence),
            Sketch.fade(const Color(0xffffc9a8), 0),
          ],
          const [0, .3, .58, .8, 1],
        ),
    );
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(at.dx, h * .6),
        width: h * 2.6,
        height: h * .5,
      ),
      const Color(0xffffc894),
      .55 * presence,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: at, width: h * .7, height: h * .5),
      const Color(0xfffff0cc),
      .5 * presence,
    );
  }

  /// The last stars fading from the teal zenith, away from the sun.
  void _dawnStars(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final paint = Paint();
    for (var i = 0; i < 34; i++) {
      final x = w * Sketch.hash(i * 3 + 1100);
      final y = h * .42 * Sketch.hash(i * 3 + 1101) * Sketch.hash(i * 3 + 1102);
      final fade =
          (1 - y / (h * .42)) *
          (1 - math.min(1.0, math.max(0.0, x / w - .45) * 1.8));
      if (fade <= .05) continue;
      final tw =
          .6 + .4 * math.sin(f.clock * (1.4 + Sketch.hash(i + 1150)) + i * 2.3);
      paint.color = Sketch.fade(
        const Color(0xfffff8ec),
        .85 * fade * tw * presence,
      );
      c.drawCircle(
        Offset(x, y),
        h * (.0016 + .0018 * Sketch.hash(i + 1160)),
        paint,
      );
    }
  }

  static final _moonShape = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 1)),
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(-.42, -.3), radius: .92)),
  );

  /// A thin waning crescent lit from the sun below it, and the morning star
  /// with its four-point sparkle.
  void _dawnMoon(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final moon = Offset(w * .58, h * .15), r = h * .034;
    Sketch.mist(
      c,
      Rect.fromCircle(center: moon, radius: r * 3.2),
      const Color(0xfffff4e0),
      .28 * presence,
    );
    c.save();
    c.translate(moon.dx, moon.dy);
    c.scale(r);
    c.drawPath(
      _moonShape,
      Paint()..color = Sketch.fade(const Color(0xfffff6e2), presence),
    );
    c.restore();
    final star = Offset(w * .66, h * .27);
    final tw = .75 + .25 * math.sin(f.clock * 2.2);
    Sketch.mist(
      c,
      Rect.fromCircle(center: star, radius: h * .02),
      const Color(0xffffffff),
      .4 * tw * presence,
    );
    final spark = Paint()
      ..color = Sketch.fade(const Color(0xffffffff), .9 * presence)
      ..strokeWidth = math.max(.8, h * .0018)
      ..strokeCap = StrokeCap.round;
    final len = h * .012 * tw;
    c.drawLine(star - Offset(len, 0), star + Offset(len, 0), spark);
    c.drawLine(star - Offset(0, len), star + Offset(0, len), spark);
    c.drawCircle(star, h * .003, spark);
  }

  static final _dawnDecks = <int, List<Path>>{};

  /// Appends a lens to [p]: pointed ends at [cx] -/+ [len] / 2, bulging
  /// [up] above and [down] below its axis, tilted by [tilt].
  static void _lens(
    Path p,
    double cx,
    double cy,
    double len,
    double up,
    double down,
    double tilt,
  ) {
    final dx = math.cos(tilt) * len / 2, dy = math.sin(tilt) * len / 2;
    final nx = -math.sin(tilt), ny = math.cos(tilt);
    p
      ..moveTo(cx - dx, cy - dy)
      ..quadraticBezierTo(cx - nx * up * 2, cy - ny * up * 2, cx + dx, cy + dy)
      ..quadraticBezierTo(
        cx + nx * down * 2,
        cy + ny * down * 2,
        cx - dx,
        cy - dy,
      )
      ..close();
  }

  /// A deck of dawn cloud in unit size: tapered lenses stacked with small
  /// offsets as a lilac body, the rose-gold belly lit by the sun still under
  /// the horizon, and a bright rim along the lowest edge.
  static List<Path> _dawnDeck(int seed) => _dawnDecks.putIfAbsent(seed, () {
    final body = Path(), belly = Path(), rim = Path();
    final n = 4 + (Sketch.hash(seed) * 4).floor();
    for (var i = 0; i < n; i++) {
      final cx = (Sketch.hash(seed * 11 + i) - .5) * .8;
      final cy = (Sketch.hash(seed * 13 + i) - .5) * .045 + i * .004;
      final len = .16 + .36 * Sketch.hash(seed * 17 + i);
      final th = .005 + .012 * Sketch.hash(seed * 19 + i);
      final tilt = (Sketch.hash(seed * 23 + i) - .55) * .08;
      _lens(body, cx, cy, len, th * 1.5, th * .5, tilt);
      _lens(
        belly,
        cx + len * .06,
        cy + th * .25,
        len * .8,
        th * .2,
        th * .7,
        tilt,
      );
      _lens(rim, cx + len * .12, cy + th * .6, len * .5, 0, th * .28, tilt);
    }
    return [body, belly, rim];
  });

  /// Decks of dawn cloud drifting slowly left: lilac above, lit rose and
  /// gold from below, brighter the nearer they sit to the horizon.
  void _dawnClouds(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final drift = f.clock * h * .004;
    final body = Paint(), belly = Paint(), rim = Paint();
    for (final (fx, fy, size, seed) in const [
      (.1, .19, 1.1, 1),
      (.44, .31, .85, 2),
      (.74, .1, .75, 3),
      (.96, .27, .7, 4),
      (.26, .43, .75, 5),
      (.62, .46, .55, 6),
    ]) {
      final reach = h * size * .55;
      final x = (w * fx - drift * (.7 + fy) + reach) % (w + reach * 2) - reach;
      final a = (fy / .48).clamp(0.0, 1.0);
      body.color = Sketch.fade(
        Sketch.mix(const Color(0xff84a8b6), const Color(0xffcf9cb2), a),
        .55 * presence,
      );
      belly.color = Sketch.fade(
        Sketch.mix(const Color(0xfff2b4bc), const Color(0xffffc49a), a),
        .9 * presence,
      );
      rim.color = Sketch.fade(const Color(0xfffff0d6), .85 * presence);
      final deck = _dawnDeck(seed);
      c.save();
      c.translate(x, h * fy);
      c.scale(h * size);
      c.drawPath(deck[0], body);
      c.drawPath(deck[1], belly);
      c.drawPath(deck[2], rim);
      c.restore();
    }
  }

  /// Faint rays fanning up from the rising sun through the haze.
  void _dawnRays(Canvas c, SceneFrame f, SkyLight sun, double presence) {
    final h = f.h, t = f.clock;
    final at = Offset(sun.at.dx * f.w, sun.at.dy * h);
    final len = h * 1.1;
    final beat = .8 + .2 * math.sin(t * .3);
    final path = Path();
    const angles = [-2.75, -2.45, -2.18, -1.9, -1.62, -1.36, -1.08, -.8, -.52];
    for (var i = 0; i < angles.length; i++) {
      final spread = .035 * (1 + .25 * math.sin(t * .4 + i * 1.7));
      path
        ..moveTo(at.dx, at.dy)
        ..lineTo(
          at.dx + math.cos(angles[i] - spread) * len,
          at.dy + math.sin(angles[i] - spread) * len,
        )
        ..lineTo(
          at.dx + math.cos(angles[i] + spread) * len,
          at.dy + math.sin(angles[i] + spread) * len,
        )
        ..close();
    }
    c.drawPath(
      path,
      Paint()
        ..shader = Gradient.radial(
          at,
          len,
          [
            Sketch.fade(const Color(0xffffe2b8), .13 * beat * presence),
            Sketch.fade(const Color(0xffffd8b0), .04 * beat * presence),
            Sketch.fade(const Color(0xffffd8b0), 0),
          ],
          const [.06, .45, 1],
        ),
    );
  }

  /// A flying carpet far off over the city, rippling as it glides slowly
  /// left, its rider cross-legged and its tassels streaming. It keeps to the
  /// high right of the sky, away from the flight lane's busiest band.
  void _dawnCarpet(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    // Seconds from the middle of this region's hold, so the carpet is where
    // it was composed whatever the lap; still in Reduced Motion.
    final t = f.reducedMotion
        ? 0.0
        : f.seconds -
              WorldTour.at(f.seconds).startOf(region) -
              WorldTour.hold / 2;
    final pos = Offset(
      w * .88 - t * h * .007,
      h * (.24 + .008 * math.sin(f.clock * .6)),
    );
    final s = h * .03;
    final wave = f.clock * 3.2;
    Offset at(double u, double lift) => Offset(
      pos.dx + (u - .5) * s * 2 + lift * .6,
      pos.dy + math.sin(wave - u * 5) * s * .1 + lift,
    );
    const n = 8;
    // The top of the carpet seen a little from above, and its front edge.
    final top = Path(), edge = Path();
    final back = at(0, -s * .26);
    top.moveTo(back.dx, back.dy);
    for (var k = 1; k <= n; k++) {
      final p = at(k / n, -s * .26);
      top.lineTo(p.dx, p.dy);
    }
    for (var k = n; k >= 0; k--) {
      final p = at(k / n, 0);
      top.lineTo(p.dx, p.dy);
    }
    final front = at(0, 0);
    edge.moveTo(front.dx, front.dy);
    for (var k = 1; k <= n; k++) {
      final p = at(k / n, 0);
      edge.lineTo(p.dx, p.dy);
    }
    for (var k = n; k >= 0; k--) {
      final p = at(k / n, s * .07);
      edge.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      top..close(),
      Paint()..color = Sketch.fade(const Color(0xffc0414a), presence),
    );
    c.drawPath(
      edge..close(),
      Paint()..color = Sketch.fade(const Color(0xff7a2a3a), presence),
    );
    // A saffron border and a medallion woven into the field.
    final trim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, s * .05)
      ..color = Sketch.fade(const Color(0xfff0b040), presence);
    final a = at(.1, -s * .2),
        b = at(.9, -s * .2),
        cc = at(.9, -s * .05),
        d = at(.1, -s * .05);
    c.drawPath(Path()..addPolygon([a, b, cc, d], true), trim);
    final mid = at(.5, -s * .13);
    c.drawOval(
      Rect.fromCenter(center: mid, width: s * .36, height: s * .1),
      Paint()..color = Sketch.fade(const Color(0xff2f5aa0), presence),
    );
    final tassel = Paint()
      ..strokeWidth = math.max(.6, s * .04)
      ..strokeCap = StrokeCap.round
      ..color = Sketch.fade(const Color(0xfff0b040), presence);
    for (final u in const [0.0, 1.0]) {
      for (final lift in [0.0, -s * .26]) {
        final p = at(u, lift);
        c.drawLine(p, p + Offset((u - .5) * s * .3, s * .08), tassel);
      }
    }
    // The rider, cross-legged in a white robe and a madder turban.
    final seat = at(.45, -s * .13);
    c.drawPath(
      Sketch.poly([
        seat.dx - s * .3,
        seat.dy,
        seat.dx + s * .32,
        seat.dy,
        seat.dx + s * .12,
        seat.dy - s * .55,
        seat.dx - s * .1,
        seat.dy - s * .55,
      ]),
      Paint()..color = Sketch.fade(const Color(0xfff4eadc), presence),
    );
    c.drawCircle(
      seat - Offset(0, s * .66),
      s * .11,
      Paint()..color = Sketch.fade(const Color(0xff9a6448), presence),
    );
    c.drawOval(
      Rect.fromCenter(
        center: seat - Offset(0, s * .76),
        width: s * .28,
        height: s * .15,
      ),
      Paint()..color = Sketch.fade(const Color(0xffc0413c), presence),
    );
  }

  /// A falcon wheeling high over the city and a flight of doves.
  void _dawnBirds(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final ink = Sketch.fade(const Color(0xff3e3448), .75 * presence);
    final a = f.clock * .35;
    final falcon = Offset(
      w * .4 + math.cos(a) * h * .12,
      h * .2 + math.sin(a) * h * .035,
    );
    Sketch.bird(c, falcon, h * .016, ink, flap: math.sin(f.clock * .9) * .3);
    final drift = (f.clock * h * .02) % (w + h * .6) - h * .3;
    for (var i = 0; i < 6; i++) {
      final p = Offset(
        w - drift - i * h * .03 - (i % 2) * h * .01,
        h * (.3 + .012 * (i % 3)) + math.sin(f.clock + i) * h * .004,
      );
      Sketch.bird(
        c,
        p,
        h * .007,
        Sketch.fade(const Color(0xff5a4a5a), .6 * presence),
        flap: math.sin(f.clock * 8 + i * 1.3),
      );
    }
  }
}
