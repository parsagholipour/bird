import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// One foliage and bark palette of the jungle valley at a haze depth. [warm]
/// pulls the greens toward yellow and [dim] toward shadow.
class _AzTone {
  _AzTone(this.haze, {double warm = 0, double dim = 0})
    : deep = _tone(0xff1c4437, haze, warm, dim),
      shade = _tone(0xff2b5f45, haze, warm, dim),
      body = _tone(0xff3f7d49, haze, warm, dim),
      lit = _tone(0xff73ad53, haze, warm, dim),
      glow = _tone(0xffc6d868, haze, warm, dim),
      bark = _tone(0xff8a7258, haze, 0, dim * .5),
      barkShade = _tone(0xff56443a, haze, 0, dim * .5),
      barkLit = _tone(0xffb39774, haze, 0, dim * .5);

  final double haze;
  final Color deep, shade, body, lit, glow, bark, barkShade, barkLit;

  static Color _tone(int argb, double haze, double warm, double dim) {
    var color = Color(argb);
    if (warm > 0) color = Sketch.mix(color, const Color(0xffcdcf5c), warm);
    if (dim > 0) color = Sketch.mix(color, const Color(0xff10281f), dim);
    return AztecScene._hazed(color, haze);
  }
}

/// The Aztec jungle valley's vegetation: ceiba, broadleaf, palm and ahuejote
/// trees built from sunlit and shaded canopy clumps, undergrowth, maize
/// terraces, and the shore of Lake Texcoco with its causeways, chinampas and
/// canoes. Everything static is recorded once into the band's cached picture;
/// only [life] and [mist] run per frame, and neither allocates paths.
///
/// Light comes from the low sun on the left: crowns are lit at the upper left
/// and shaded at the lower right, trunks lit on their left flank.
abstract final class _AztecFlora {
  static final _fill = Paint();
  static final _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Color _hz(int argb, double haze) => AztecScene._hazed(Color(argb), haze);

  static void _dot(Canvas c, double x, double y, double r, Color color) {
    c.drawCircle(Offset(x, y), r, _fill..color = color);
  }

  static void _seg(
    Canvas c,
    double x0,
    double y0,
    double x1,
    double y1,
    double width,
    Color color,
  ) {
    c.drawLine(
      Offset(x0, y0),
      Offset(x1, y1),
      _line
        ..strokeWidth = width
        ..color = color,
    );
  }

  static void _stroke(Canvas c, Path path, double width, Color color) {
    c.drawPath(
      path,
      _line
        ..strokeWidth = width
        ..color = color,
    );
  }

  static void _shape(Canvas c, Path path, Color color) {
    c.drawPath(path, _fill..color = color);
  }

  static double _bez(double t, double p0, double p1, double p2, double p3) {
    final m = 1 - t;
    return m * m * m * p0 + 3 * m * m * t * p1 + 3 * m * t * t * p2 + t * t * t * p3;
  }

  // ---- Crowns and trunks -------------------------------------------------

  /// Lobe layouts (dx, dy, radius in clump radii) for a lumpy clump.
  static const _lobes = [
    [(0.0, 0.0, 1.0), (-.62, .2, .64), (.6, .24, .6), (-.12, -.52, .62)],
    [(0.0, 0.0, 1.0), (-.56, .28, .6), (.58, .1, .66), (.2, -.5, .58)],
    [(0.0, .04, 1.0), (-.66, .16, .58), (.5, .3, .56), (-.3, -.46, .6)],
  ];

  /// A lumpy foliage clump of radius [r] centred at ([x], [y]), lit from the
  /// upper left: a dark crescent underneath, shade, body and a lit crown.
  /// [full] adds the golden rim light and a few leaf specks.
  static void clump(
    Canvas c,
    double x,
    double y,
    double r,
    _AzTone p,
    int seed, {
    bool full = true,
  }) {
    final lobes = _lobes[seed.abs() % 3];
    final f = seed.isEven ? 1.0 : -1.0;
    final n = full ? 4 : 3;
    if (full) {
      for (var i = 0; i < n; i += 2) {
        final (dx, dy, rr) = lobes[i];
        _dot(c, x + dx * f * r + r * .06, y + dy * r + r * .1, rr * r, p.deep);
      }
    }
    for (var i = 0; i < n; i++) {
      final (dx, dy, rr) = lobes[i];
      _dot(c, x + dx * f * r, y + dy * r, rr * r, p.shade);
    }
    for (var i = 0; i < n; i++) {
      final (dx, dy, rr) = lobes[i];
      if (dx * f > .45) continue;
      _dot(c, x + dx * f * r - rr * r * .1, y + dy * r - rr * r * .12, rr * r * .84, p.body);
    }
    for (var i = 0; i < n; i++) {
      final (dx, dy, rr) = lobes[i];
      if (dx * f > .3 || dy > .25) continue;
      final lx = x + dx * f * r - rr * r * .2, ly = y + dy * r - rr * r * .24;
      _dot(c, lx, ly, rr * r * .52, p.lit);
      if (full) _dot(c, lx - rr * r * .14, ly - rr * r * .16, rr * r * .2, p.glow);
    }
    if (full) {
      _dot(c, x + r * .3, y + r * .32, r * .07, p.deep);
      _dot(c, x - r * .36, y - r * .18, r * .05, p.glow);
      _dot(c, x + r * .04, y - r * .52, r * .045, p.glow);
    }
  }

  /// A tapered trunk [len] tall with its foot flared by [flare], lit on the
  /// left and shaded on the right.
  static void _trunk(
    Canvas c,
    double x,
    double y,
    double len,
    double wBase,
    double wTop,
    double flare,
    Color bark,
    Color shade,
    Color lit, {
    double lean = 0,
  }) {
    final tx = x + lean * len;
    _shape(
      c,
      Path()
        ..moveTo(x - wBase - flare, y)
        ..quadraticBezierTo(x - wBase, y - len * .05, x - wBase, y - len * .28)
        ..lineTo(tx - wTop, y - len)
        ..lineTo(tx + wTop, y - len)
        ..lineTo(x + wBase, y - len * .28)
        ..quadraticBezierTo(x + wBase, y - len * .05, x + wBase + flare, y)
        ..close(),
      bark,
    );
    _shape(
      c,
      Path()
        ..moveTo(x + wBase * .1, y)
        ..lineTo(tx + wTop * .1, y - len)
        ..lineTo(tx + wTop, y - len)
        ..lineTo(x + wBase, y - len * .28)
        ..quadraticBezierTo(x + wBase, y - len * .05, x + wBase + flare, y)
        ..close(),
      shade,
    );
    _shape(
      c,
      Path()
        ..moveTo(x - wBase - flare, y)
        ..quadraticBezierTo(x - wBase, y - len * .05, x - wBase, y - len * .28)
        ..lineTo(tx - wTop, y - len)
        ..lineTo(tx - wTop * .35, y - len)
        ..lineTo(x - wBase * .35, y - len * .28)
        ..quadraticBezierTo(x - wBase * .4, y - len * .06, x - wBase * .3, y)
        ..close(),
      lit,
    );
  }

  /// A hanging liana: a thin curve with a leaf bead at its tip.
  static void _vine(Canvas c, double x, double y, double len, double sway, double width, _AzTone p) {
    _stroke(
      c,
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + sway, y + len * .5, x + sway * .3, y + len),
      width,
      p.deep,
    );
    _dot(c, x + sway * .3, y + len, width * 1.3, p.body);
  }

  /// A perched parrot fleck, [u] across, its feet at (x, y + .75u).
  static void _perched(Canvas c, double x, double y, double u, Color body, Color tail) {
    _seg(c, x, y + u * .5, x + u * .25, y + u * 1.9, u * .32, tail);
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: u * .95, height: u * 1.5),
      _fill..color = body,
    );
    _dot(c, x - u * .12, y - u * .85, u * .42, body);
  }

  // ---- Species -----------------------------------------------------------

  static const _ceibaLow = [(-.24, .6, .09), (0.0, .565, .095), (.25, .6, .088)];
  static const _ceibaTop = [
    (-.38, .735, .1),
    (.37, .74, .096),
    (-.13, .8, .115),
    (.14, .79, .11),
    (-.02, .885, .07),
  ];

  /// A ceiba: the valley's sacred giant, with a pale straight trunk flaring
  /// into buttresses and a wide, flat crown of layered clumps hung with
  /// lianas. [s] is the total height.
  static void ceiba(
    Canvas c,
    double x,
    double y,
    double s,
    double haze,
    int seed, {
    bool full = true,
  }) {
    final p = _AzTone(haze);
    final q = _AzTone(haze, dim: .3);
    final f = seed.isEven ? 1.0 : -1.0;
    final bark = Sketch.mix(p.bark, _hz(0xffa8a48c, haze), .55);
    final shade = Sketch.mix(p.barkShade, _hz(0xff6f6d5c, haze), .5);
    _trunk(c, x, y, s * .66, s * .034, s * .024, s * .075, bark, shade, _hz(0xffcfc8a8, haze));
    // The middle buttress fin stands dark against the lit flank.
    _shape(
      c,
      Path()
        ..moveTo(x - s * .05, y)
        ..quadraticBezierTo(x - s * .01, y - s * .03, x - s * .004, y - s * .21)
        ..quadraticBezierTo(x + s * .012, y - s * .04, x + s * .045, y)
        ..close(),
      shade,
    );
    final limb = math.max(.7, s * .02);
    for (final (dx, dy) in const [(-.34, .68), (.33, .69), (-.12, .74), (.12, .75)]) {
      _seg(c, x, y - s * .6, x + dx * f * s, y - dy * s, limb, shade);
    }
    for (var i = 0; i < _ceibaLow.length; i++) {
      final (dx, dy, r) = _ceibaLow[i];
      clump(c, x + dx * f * s, y - dy * s, r * s, q, seed * 11 + i, full: false);
    }
    for (var i = 0; i < _ceibaTop.length; i++) {
      final (dx, dy, r) = _ceibaTop[i];
      clump(c, x + dx * f * s, y - dy * s, r * s, p, seed * 11 + 5 + i, full: full);
    }
    if (!full) return;
    final w = math.max(.6, s * .011);
    for (final (dx, dy, len, sway) in const [
      (-.3, .52, .2, .03),
      (-.05, .48, .27, -.02),
      (.22, .52, .18, .025),
      (.42, .66, .2, -.03),
    ]) {
      _vine(c, x + dx * f * s, y - dy * s, len * s, sway * s, w, p);
    }
    // A scarlet macaw and a blue-and-gold one rest on the crown.
    final u = math.max(1.0, s * .017);
    _perched(c, x - .2 * f * s, y - .891 * s - u * .75, u, const Color(0xffd9402f), const Color(0xff2f6fc0));
    _perched(c, x + .37 * f * s, y - .836 * s - u * .75, u, const Color(0xff2f6fc0), const Color(0xfff2c230));
  }

  /// Crown layouts (dx, dy, radius in tree heights) for the broadleaf trees:
  /// a round dome, a tall oval and a wide spreading crown.
  static const _crowns = [
    [(-.02, .5, .15), (-.22, .58, .2), (.22, .6, .19), (0.0, .74, .2)],
    [(.1, .6, .13), (0.0, .5, .18), (-.05, .68, .17), (.05, .84, .14)],
    [(0.0, .6, .2), (-.3, .52, .16), (.3, .52, .15), (0.0, .76, .14)],
  ];

  /// A round-crowned broadleaf (zapote, mango): [seed] % 3 picks the crown
  /// and [bloom] scatters flowers over it.
  static void broadleaf(
    Canvas c,
    double x,
    double y,
    double s,
    double haze,
    int seed, {
    bool full = true,
    Color? bloom,
  }) {
    final v = seed.abs() % 3;
    final p = _AzTone(haze, warm: v == 1 ? .28 : (v == 2 ? .1 : 0.0));
    final f = (seed ~/ 3).isEven ? 1.0 : -1.0;
    _trunk(c, x, y, s * .5, s * .05, s * .03, s * .04, p.bark, p.barkShade, p.barkLit, lean: .03 * f);
    final limb = math.max(.7, s * .028);
    _seg(c, x, y - s * .4, x - .17 * f * s, y - s * .6, limb, p.barkShade);
    _seg(c, x, y - s * .44, x + .16 * f * s, y - s * .62, limb, p.barkShade);
    final crown = _crowns[v];
    for (var i = 0; i < crown.length; i++) {
      final (dx, dy, r) = crown[i];
      clump(c, x + dx * f * s, y - dy * s, r * s, p, seed * 7 + i, full: full);
    }
    if (bloom != null) {
      final size = math.max(.8, s * .024);
      for (var k = 0; k < 9; k++) {
        final (dx, dy, r) = crown[1 + k % (crown.length - 1)];
        final a = Sketch.hash(seed * 13 + k) * math.pi * 2;
        final d = r * s * .85 * math.sqrt(Sketch.hash(seed * 13 + k + 60));
        _dot(
          c,
          x + dx * f * s + math.cos(a) * d,
          y - dy * s + math.sin(a) * d * .8 - r * s * .1,
          size,
          bloom,
        );
      }
    }
    if (full && v == 2) {
      final w = math.max(.6, s * .012);
      _vine(c, x - .3 * f * s, y - .46 * s, s * .16, s * .02, w, p);
      _vine(c, x + .28 * f * s, y - .46 * s, s * .12, -s * .02, w, p);
    }
  }

  /// An ahuejote, the columnar willow of the chinampa canals: a slim trunk
  /// under a tall plume with long drooping strands.
  static void willow(Canvas c, double x, double y, double s, double haze, int seed) {
    final p = _AzTone(haze, warm: .45);
    final f = seed.isEven ? 1.0 : -1.0;
    _trunk(c, x, y, s * .45, s * .03, s * .02, s * .022, p.bark, p.barkShade, p.barkLit, lean: .02 * f);
    c.drawOval(
      Rect.fromCenter(center: Offset(x + s * .05 * f, y - s * .46), width: s * .22, height: s * .4),
      _fill..color = p.shade,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(x - s * .02 * f, y - s * .66), width: s * .3, height: s * .56),
      _fill..color = p.shade,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(x - s * .05, y - s * .69), width: s * .21, height: s * .45),
      _fill..color = p.body,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(x - s * .09, y - s * .75), width: s * .09, height: s * .26),
      _fill..color = p.lit,
    );
    _dot(c, x - s * .1, y - s * .86, s * .018, p.glow);
    final w = math.max(.6, s * .011);
    for (var i = 0; i < 7; i++) {
      final sx = x + (i - 3) * s * .042;
      final sway = (Sketch.hash(seed * 3 + i) - .5) * s * .05;
      final end = y - s * (.2 + .06 * Sketch.hash(seed * 5 + i));
      _stroke(
        c,
        Path()
          ..moveTo(sx, y - s * .4)
          ..quadraticBezierTo(sx + sway, y - s * .3, sx + sway * .4, end),
        w,
        i.isEven ? p.lit : p.body,
      );
    }
  }

  /// A palm in the valley's colours.
  static void palm(
    Canvas c,
    double x,
    double y,
    double s,
    double haze, {
    double lean = 0,
    bool dates = false,
    double droop = .42,
    bool detail = true,
  }) {
    Sketch.palm(
      c,
      Offset(x, y),
      s,
      lean: lean,
      trunk: _hz(0xff8f7050, haze),
      trunkShade: _hz(0xff5a4436, haze),
      frond: _hz(0xff2f6e45, haze),
      frondLit: _hz(0xff6fb05a, haze),
      detail: detail,
      dates: dates,
      droop: droop,
    );
  }

  /// One tree of [kind] (0 ceiba, 1 broadleaf, 2 palm, 3 willow).
  static void _specimen(
    Canvas c,
    double x,
    double y,
    double s,
    int kind,
    int seed,
    double haze, {
    required bool full,
  }) {
    switch (kind) {
      case 0:
        ceiba(c, x, y, s, haze, seed, full: full);
      case 1:
        broadleaf(
          c,
          x,
          y,
          s,
          haze,
          seed,
          full: full,
          bloom: seed % 5 == 2
              ? const Color(0xfff07aa6)
              : (seed % 7 == 3 ? const Color(0xfffff0d8) : null),
        );
      case 2:
        palm(
          c,
          x,
          y,
          s,
          haze,
          lean: (Sketch.hash(seed + 31) - .5) * .12,
          dates: seed % 4 == 2,
          detail: full,
        );
      default:
        willow(c, x, y, s, haze, seed);
    }
  }

  // ---- Undergrowth -------------------------------------------------------

  static const _blooms = [
    Color(0xfff4a51c),
    Color(0xfff4a51c),
    Color(0xffd8407c),
    Color(0xffe5452f),
  ];

  /// A shrub of radius [r]; [bloom] studs it with marigold, bougainvillea or
  /// hibiscus flowers.
  static void bush(
    Canvas c,
    double x,
    double y,
    double r,
    _AzTone p,
    int seed, {
    bool bloom = false,
  }) {
    final f = seed.isEven ? 1.0 : -1.0;
    _dot(c, x, y, r, p.shade);
    _dot(c, x + r * .85 * f, y + r * .2, r * .68, p.shade);
    _dot(c, x - r * .12, y - r * .14, r * .8, p.body);
    if (f < 0) _dot(c, x - r * .93, y + r * .12, r * .52, p.body);
    _dot(c, x - r * .34, y - r * .44, r * .38, p.lit);
    if (bloom) {
      final size = math.max(.7, r * .13);
      final color = _blooms[seed % 4];
      _dot(c, x - r * .5, y - r * .1, size, color);
      _dot(c, x + r * .1, y - r * .56, size, color);
      _dot(c, x + r * .5 * f, y + r * .02, size, color);
      _dot(c, x - r * .1, y + r * .1, size * .8, const Color(0xfffff1d0));
    }
  }

  /// A tuft of grass blades [s] tall.
  static void tuft(Canvas c, double x, double y, double s, Color color, int seed) {
    final path = Path();
    for (var i = -2; i <= 2; i++) {
      final lean = i * s * .16 + (Sketch.hash(seed * 5 + i + 3) - .5) * s * .1;
      final tall = s * (.62 + .38 * Sketch.hash(seed * 7 + i + 9)) * (1 - i.abs() * .12);
      final at = x + i * s * .05;
      path
        ..moveTo(at - s * .035, y)
        ..lineTo(at + lean, y - tall)
        ..lineTo(at + s * .035, y)
        ..close();
    }
    _shape(c, path, color);
  }

  /// A maguey rosette [s] tall; [spike] raises its flowering quiote.
  static void maguey(Canvas c, double x, double y, double s, double haze, {bool spike = false}) {
    final body = _hz(0xff5f9c8a, haze);
    final lit = _hz(0xff9bc9a2, haze);
    final shade = _hz(0xff3b7566, haze);
    if (spike) {
      final w = math.max(.9, s * .06);
      final top = Offset(x + s * .1, y - s * 2.1);
      final stalk = _hz(0xff8a7a4e, haze);
      _seg(c, x, y - s * .3, top.dx, top.dy, w, stalk);
      for (final (dx, dy) in const [(-.3, .5), (.3, .55), (0.0, .2)]) {
        final bx = top.dx, by = top.dy + s * .35;
        _seg(c, bx, by, bx + dx * s, by - dy * s, w * .7, stalk);
        _dot(c, bx + dx * s, by - dy * s, math.max(.8, s * .07), const Color(0xfff2c744));
      }
    }
    for (var j = 4; j >= 0; j--) {
      for (final i in j == 0 ? const [0] : [-j, j]) {
        final a = -math.pi / 2 + i * .29;
        final len = s * (1 - j * .1);
        final dx = math.cos(a), dy = math.sin(a);
        final tipX = x + dx * len, tipY = y + dy * len + len * .05 * j;
        final midX = x + dx * len * .5, midY = y + dy * len * .5;
        final nx = -dy * s * .16, ny = dx * s * .16;
        _shape(
          c,
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(midX + nx, midY + ny, tipX, tipY)
            ..quadraticBezierTo(midX - nx, midY - ny, x, y)
            ..close(),
          i < 0 ? lit : (i == 0 ? body : shade),
        );
      }
    }
  }

  /// Stepped, stone-walled fields of [tiers] tiers whose lowest riser stands
  /// on [y]; [crops] rows the treads with maize under golden tassels.
  static void terrace(
    Canvas c,
    double cx,
    double y,
    double halfW,
    double tier,
    int tiers,
    double haze,
    int seed, {
    bool crops = true,
  }) {
    final stone = _hz(0xffcbb28c, haze);
    final stoneLit = _hz(0xffe6d3aa, haze);
    final stoneShade = _hz(0xffa08662, haze);
    final field = _hz(0xffa9c65c, haze);
    final fieldDeep = _hz(0xff72a24e, haze);
    final tread = tier * .34;
    final round = Radius.circular(tread * .8);
    for (var t = tiers - 1; t >= 0; t--) {
      final half = halfW * (1 - t * .2);
      final top = y - (t + 1) * tier;
      final bottom = y - t * tier + (t == 0 ? tier * .8 : 0.0);
      c.drawRRect(
        RRect.fromLTRBR(cx - half, top + tread * .5, cx + half, bottom, round),
        _fill..color = stone,
      );
      c.drawRRect(
        RRect.fromLTRBR(cx - half, top + tread * .5, cx - half * .45, bottom, round),
        _fill..color = stoneLit,
      );
      c.drawRRect(
        RRect.fromLTRBR(cx + half * .5, top + tread * .5, cx + half, bottom, round),
        _fill..color = stoneShade,
      );
      c.drawRRect(
        RRect.fromLTRBR(cx - half, top, cx + half, top + tread * 1.35, round),
        _fill..color = (t + seed).isEven ? field : fieldDeep,
      );
    }
    if (!crops) return;
    final leaf = math.max(.6, tier * .07);
    final green = _hz(0xff3f8a3e, haze);
    final gold = _hz(0xffe6b93c, haze);
    for (var t = 0; t < tiers; t++) {
      final half = halfW * (1 - t * .2);
      final baseY = y - (t + 1) * tier + tread;
      final step = tier * .62;
      final n = (half * 1.7 / step).floor();
      final stalks = Path(), tassels = Path();
      for (var m = 0; m < n; m++) {
        final px = cx - half * .85 + m * step + (Sketch.hash(seed * 31 + t * 7 + m) - .5) * step * .4;
        final mh = tier * (.72 + .28 * Sketch.hash(seed * 37 + t * 11 + m));
        stalks
          ..moveTo(px, baseY)
          ..lineTo(px + mh * .06, baseY - mh)
          ..moveTo(px, baseY - mh * .42)
          ..quadraticBezierTo(px - mh * .34, baseY - mh * .75, px - mh * .5, baseY - mh * .52)
          ..moveTo(px, baseY - mh * .58)
          ..quadraticBezierTo(px + mh * .34, baseY - mh * .9, px + mh * .52, baseY - mh * .66);
        tassels
          ..moveTo(px + mh * .06, baseY - mh)
          ..lineTo(px + mh * .06, baseY - mh * 1.18);
      }
      _stroke(c, stalks, leaf, green);
      _stroke(c, tassels, leaf * 1.5, gold);
    }
  }

  // ---- Low band ----------------------------------------------------------

  // (x in thirds of a period, kind, size in viewport heights, variant)
  static const _lowBack = [
    (.34, 1, .058, 1),
    (.7, 1, .064, 2),
    (1.02, 2, .085, 0),
    (1.52, 0, .095, 1),
    (1.86, 1, .06, 0),
    (2.14, 3, .075, 2),
    (2.44, 1, .058, 1),
    (2.78, 1, .066, 2),
  ];
  static const _lowFront = [
    (.1, 1, .085, 0),
    (.5, 2, .13, 0),
    (.88, 0, .17, 0),
    (1.34, 1, .09, 1),
    (1.66, 3, .11, 1),
    (1.98, 2, .12, 1),
    (2.28, 1, .082, 2),
    (2.58, 0, .135, 1),
    (2.9, 2, .1, 2),
  ];

  /// The low band: two rows of mixed trees (hazier behind), milpa terraces
  /// and the flowering undergrowth along the ridge.
  static void low(Canvas c, RegionScene s, Size size) {
    final h = size.height;
    final u = s.period(Depth.low) * h / 3;
    double ry(double x) => s.ridge(Depth.low, x / h, 0) * h;
    var i = 0;
    for (final (xh, kind, tall, v) in _lowBack) {
      final x = u * xh;
      _specimen(c, x, ry(x) + h * .004, h * tall, kind, v + 3 * i++, .22, full: false);
    }
    for (final (xh, half, k) in const [(1.16, .15, 0), (2.44, .13, 1)]) {
      final x = u * xh, tier = h * .0125;
      terrace(c, x, ry(x) + tier * .4, h * half, tier, 3, .14, k);
    }
    for (final (xh, kind, tall, v) in _lowFront) {
      final x = u * xh;
      _specimen(c, x, ry(x) + h * .003, h * tall, kind, v + 3 * i++, .07, full: true);
    }
    for (final (xh, tall, spike) in const [
      (.74, .032, false),
      (1.0, .028, false),
      (1.32, .03, false),
      (1.62, .034, true),
      (2.2, .03, false),
      (2.72, .03, false),
    ]) {
      final x = u * xh;
      maguey(c, x, ry(x) + h * .004, h * tall, .08, spike: spike);
    }
    final p = _AzTone(.08), q = _AzTone(.1, warm: .3);
    var j = 0;
    for (var xh = .02; xh < 3; xh += .1 + .04 * Sketch.hash(j + 700), j++) {
      final x = u * xh;
      final r = h * (.014 + .012 * Sketch.hash(j + 710));
      bush(c, x, ry(x) + r * .3, r, j.isEven ? p : q, j, bloom: Sketch.hash(j + 720) < .4);
      final tx = x + h * .05;
      tuft(c, tx, ry(tx) + h * .004, h * (.026 + .012 * Sketch.hash(j + 730)), p.lit, j);
    }
  }

  // ---- Mid band ----------------------------------------------------------

  /// Footprints of the temples (fraction of the width, size in heights),
  /// which the vegetation keeps clear of.
  static const _temples = [(.14, .2), (.5, .36), (.9, .17)];

  static bool _clear(double x, double pad, double w, double h, double k) {
    for (final (fx, size) in _temples) {
      if ((x - w * fx).abs() < h * size * k * .62 + pad) return false;
    }
    return true;
  }

  /// A low wooded hill of half-width [hw] and height [hgt] on [base]: a dome
  /// with crown bumps along its outline, lit on the left.
  static void hill(Canvas c, double cx, double base, double hw, double hgt, double haze, int seed) {
    final p = _AzTone(haze);
    final top = base - hgt;
    _shape(
      c,
      Path()
        ..moveTo(cx - hw, base)
        ..cubicTo(cx - hw * .85, base - hgt * .95, cx - hw * .35, top - hgt * .02, cx, top)
        ..cubicTo(cx + hw * .35, top - hgt * .02, cx + hw * .85, base - hgt * .95, cx + hw, base)
        ..close(),
      p.shade,
    );
    _shape(
      c,
      Path()
        ..moveTo(cx - hw, base)
        ..cubicTo(cx - hw * .85, base - hgt * .95, cx - hw * .35, top - hgt * .02, cx, top)
        ..quadraticBezierTo(cx - hw * .12, base - hgt * .5, cx - hw * .3, base)
        ..close(),
      p.body,
    );
    for (var m = 0; m < 7; m++) {
      final t = .08 + .14 * m;
      final px = _bez(t, cx - hw, cx - hw * .85, cx - hw * .35, cx);
      final py = _bez(t, base, base - hgt * .95, top - hgt * .02, top);
      final r = hgt * (.1 + .05 * Sketch.hash(seed * 17 + m));
      for (final side in const [-1.0, 1.0]) {
        final qx = side < 0 ? px : 2 * cx - px;
        final inx = cx - qx, iny = base - hgt * .45 - py;
        final len = math.sqrt(inx * inx + iny * iny);
        final ox = qx + inx / len * r * .35, oy = py + iny / len * r * .35;
        _dot(c, ox, oy, r, side < 0 ? p.body : p.shade);
        if (side < 0 && m >= 3) _dot(c, ox - r * .25, oy - r * .3, r * .55, p.lit);
      }
    }
  }

  /// A scalloped forest edge along [y]: one filled silhouette of rounded
  /// crowns [bump] high, about [step] apart, reaching [drop] below the line.
  static void _scallop(
    Canvas c,
    double x0,
    double x1,
    double y,
    double bump,
    double step,
    double drop,
    int seed,
    Color color,
  ) {
    final path = Path()
      ..moveTo(x0, y + drop)
      ..lineTo(x0, y);
    var x = x0, at = y, i = 0;
    while (x < x1) {
      final dx = step * (.7 + .6 * Sketch.hash(seed + i));
      final peak = bump * (1.1 + .9 * Sketch.hash(seed + i + 500));
      final next = y - bump * .2 * Sketch.hash(seed + i + 900);
      path.quadraticBezierTo(x + dx * .5, (at + next) / 2 - peak * 2, x + dx, next);
      x += dx;
      at = next;
      i++;
    }
    path
      ..lineTo(x, y + drop)
      ..close();
    _shape(c, path, color);
  }

  /// The far shore and the open water of Lake Texcoco between [x0] and [x1],
  /// warm with the sunrise near the horizon and cool toward the shore.
  static void lake(Canvas c, double x0, double x1, double h) {
    final top = h * .684, bottom = h * .79;
    c.drawRect(
      Rect.fromLTRB(x0, top, x1, bottom),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          const [Color(0xffffe4bb), Color(0xfff3c4a6), Color(0xffa8aed0)],
          const [0, .3, 1],
        ),
    );
    c.drawRect(
      Rect.fromLTRB(x0, top, x1, top + h * .014),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, top + h * .014),
          const [Color(0x99fff6dc), Color(0x00fff6dc)],
        ),
    );
    // Sun glitter and a few darker ripples.
    final n = ((x1 - x0) / h * 16).round();
    for (var i = 0; i < n; i++) {
      final x = x0 + (x1 - x0) * Sketch.hash(i * 4 + 900);
      final y = top + h * (.008 + .034 * Sketch.hash(i * 4 + 901));
      final len = h * (.008 + .02 * Sketch.hash(i * 4 + 902));
      final wide = math.max(.7, h * .001);
      _seg(
        c,
        x - len,
        y,
        x + len,
        y,
        wide,
        Sketch.fade(i % 3 == 0 ? const Color(0xfffff6dc) : const Color(0xffffd28a), .7),
      );
      if (i % 4 == 0) {
        _seg(c, x - len * .6, y + h * .004, x + len * .6, y + h * .004, wide, const Color(0x55a08cb8));
      }
    }
    // The far shore: two hazy ranks of forest and their soft reflection.
    _scallop(c, x0, x1, top + h * .002, h * .007, h * .02, h * .004, 800, _hz(0xff55766a, .5));
    _scallop(c, x0, x1, top + h * .006, h * .008, h * .016, h * .004, 830, _hz(0xff3f6d52, .4));
    c.drawRect(
      Rect.fromLTRB(x0, top + h * .01, x1, top + h * .022),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top + h * .01),
          Offset(0, top + h * .022),
          const [Color(0x554a5a80), Color(0x004a5a80)],
        ),
    );
  }

  /// A chinampa: a floating garden plot with ahuejote willows and a thatched
  /// hut, riding the water at [y].
  static void chinampa(Canvas c, double x, double y, double len, double h, int seed) {
    const haze = .34;
    final e = h * .0034;
    final soil = _hz(0xff7a5c46, haze);
    final leaf = _hz(0xff78a24c, haze);
    c.drawRRect(
      RRect.fromLTRBR(x - len * .45, y + e * .8, x + len * .45, y + e * 2.6, Radius.circular(e)),
      _fill..color = Sketch.fade(_hz(0xff7a78a0, .2), .3),
    );
    c.drawRRect(
      RRect.fromLTRBR(x - len / 2, y - e, x + len / 2, y + e, Radius.circular(e)),
      _fill..color = soil,
    );
    c.drawRRect(
      RRect.fromLTRBR(x - len / 2, y - e * 1.1, x + len / 2, y - e * .1, Radius.circular(e * .6)),
      _fill..color = leaf,
    );
    for (final (dx, tall) in const [(-.36, .048), (.04, .062), (.34, .052)]) {
      willow(c, x + dx * len, y - e * .6, h * (tall + .012 * Sketch.hash(seed * 3 + (dx * 10).round())), haze, seed);
    }
    final hx = x - len * .14, hw = h * .006, hh = h * .006, floor = y - e;
    c.drawRect(
      Rect.fromLTRB(hx - hw, floor - hh, hx + hw, floor),
      _fill..color = _hz(0xffe0c8a0, haze),
    );
    _shape(
      c,
      Sketch.poly([hx - hw * 1.3, floor - hh, hx + hw * 1.3, floor - hh, hx, floor - hh - hw * 1.4]),
      _hz(0xffb08a52, haze),
    );
  }

  /// A raised causeway running from the near shore toward the far one, with
  /// two bridged gaps.
  static void causeway(Canvas c, double x, double h, double dir) {
    final nearY = h * .75, farY = h * .684;
    final nearHalf = h * .0085, farHalf = h * .0032;
    final farX = x + dir * h * .05;
    final road = _hz(0xffdcc7a2, .36), edge = _hz(0xff9c8466, .36);
    _shape(
      c,
      Sketch.poly([x - nearHalf, nearY, x + nearHalf, nearY, farX + farHalf, farY, farX - farHalf, farY]),
      road,
    );
    _seg(c, x + nearHalf, nearY, farX + farHalf, farY, math.max(.7, h * .0009), edge);
    for (final t in const [.38, .7]) {
      final gx = x + (farX - x) * t, gy = nearY + (farY - nearY) * t;
      final half = nearHalf + (farHalf - nearHalf) * t;
      c.drawRect(
        Rect.fromLTRB(gx - half - .3, gy - h * .0012, gx + half + .3, gy + h * .0012),
        _fill..color = const Color(0xfff4c8aa),
      );
      _seg(c, gx - half, gy, gx + half, gy, math.max(.6, h * .0007), edge);
    }
  }

  /// A dug-out canoe [len] long with a paddler and a wake.
  static void canoe(Canvas c, double x, double y, double len) {
    final hull = _hz(0xff5a4230, .3);
    _shape(
      c,
      Path()
        ..moveTo(x - len, y - len * .07)
        ..quadraticBezierTo(x, y + len * .3, x + len, y - len * .09)
        ..quadraticBezierTo(x, y + len * .02, x - len, y - len * .07)
        ..close(),
      hull,
    );
    _dot(c, x - len * .1, y - len * .22, len * .11, _hz(0xffc0703a, .3));
    _seg(c, x + len * .1, y - len * .2, x + len * .34, y + len * .18, math.max(.6, len * .05), hull);
    _seg(
      c,
      x - len * 1.1,
      y + len * .2,
      x + len * .9,
      y + len * .2,
      math.max(.6, len * .05),
      Sketch.fade(const Color(0xffffffff), .35),
    );
  }

  /// Behind the temples: Lake Texcoco with its causeways, chinampas and
  /// canoes, and wooded and terraced hills on the far shore.
  static void midBack(Canvas c, RegionScene s, Size size, double k) {
    final w = size.width, h = size.height;
    final x0 = -h * .16, x1 = w + h * .62;
    lake(c, x0, x1, h);
    for (var j = 0;; j++) {
      final x = x0 + h * (.4 + .62 * j + .1 * (Sketch.hash(j + 610) - .5));
      if (x > x1) break;
      final len = h * (.1 + .05 * Sketch.hash(j + 611));
      if (!_clear(x, len / 2 + h * .02, w, h, k)) continue;
      chinampa(c, x, h * (.698 + .008 * Sketch.hash(j + 612)), len, h, j);
    }
    for (var j = 0;; j++) {
      final x = x0 + h * (.55 + 1.05 * j);
      if (x > x1) break;
      if (!_clear(x, h * .05, w, h, k)) continue;
      causeway(c, x, h, j.isEven ? 1.0 : -1.0);
    }
    for (var j = 0;; j++) {
      final x = x0 + h * (.2 + .37 * j + .1 * Sketch.hash(j + 640));
      if (x > x1) break;
      if (!_clear(x, h * .02, w, h, k)) continue;
      canoe(c, x, h * (.692 + .014 * Sketch.hash(j + 641)), h * (.011 + .004 * Sketch.hash(j + 642)));
    }
    for (var j = 0;; j++) {
      final x = x0 + h * (.1 + .62 * j + .12 * Sketch.hash(j + 620));
      if (x > x1) break;
      final hw = h * (.15 + .05 * Sketch.hash(j + 621));
      if (j % 3 == 1) {
        // A terraced knoll crowned by a grove.
        final tier = h * .0175, base = h * .745;
        terrace(c, x, base, hw * .9, tier, 4, .3, j, crops: false);
        final tone = _AzTone(.3);
        clump(c, x - hw * .1, base - tier * 4 - h * .003, h * .02, tone, j, full: false);
        clump(c, x + hw * .12, base - tier * 4 - h * .001, h * .016, tone, j + 1, full: false);
      } else {
        hill(c, x, h * .76, hw, h * (.08 + .035 * Sketch.hash(j + 622)), .32, j);
      }
    }
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset((x0 + x1) / 2, h * .7), width: (x1 - x0) * 1.1, height: h * .06),
      const Color(0xffffe6c8),
      .5,
    );
  }

  /// In front of the temples: emergent trees, the canopy mat that climbs
  /// their lower tiers, and flowering undergrowth on the ridge.
  static void midFront(Canvas c, RegionScene s, Size size, double k) {
    final w = size.width, h = size.height;
    final x0 = -h * .16, x1 = w + h * .62;
    double ry(double x) => s.ridge(Depth.mid, x / h, 0) * h;
    for (var row = 0; row < 2; row++) {
      final haze = row == 0 ? .27 : .17;
      final scale = row == 0 ? .78 : 1.0;
      final gap = row == 0 ? .26 : .36;
      var j = 0;
      for (
        var x = x0 + h * (row == 0 ? .05 : .2);
        x < x1;
        x += h * gap * (.75 + .5 * Sketch.hash(row * 90 + j + 300)), j++
      ) {
        if (!_clear(x, h * .03, w, h, k)) continue;
        final r = Sketch.hash(row * 90 + j * 3 + 301);
        final r2 = Sketch.hash(row * 90 + j * 3 + 302);
        final kind = r < .28 ? 0 : (r < .56 ? 2 : (r < .86 ? 1 : 3));
        final tall = switch (kind) {
          0 => .09 + .03 * r2,
          2 => .075 + .03 * r2,
          1 => .058 + .022 * r2,
          _ => .062 + .02 * r2,
        };
        _specimen(c, x, ry(x) + h * .004, h * scale * tall, kind, row * 40 + j, haze, full: false);
      }
    }
    final tones = [_AzTone(.15), _AzTone(.17, warm: .3), _AzTone(.19, dim: .14)];
    var i = 0;
    for (var x = x0; x < x1; x += h * (.036 + .018 * Sketch.hash(i + 400)), i++) {
      final r = h * (.02 + .012 * Sketch.hash(i + 410));
      var top = h * (.016 + .014 * Sketch.hash(i + 420)) + h * .008 * math.sin(x / h * 5.3);
      if (!_clear(x, h * .015, w, h, k)) top = math.min(top, h * .012);
      clump(c, x, ry(x) - top + r, r, tones[i % 3], i, full: false);
    }
    final under = _AzTone(.12);
    var b = 0;
    for (var x = x0 + h * .06; x < x1; x += h * (.13 + .07 * Sketch.hash(b + 500)), b++) {
      final r = h * (.008 + .006 * Sketch.hash(b + 510));
      bush(c, x, ry(x) + r * .2, r, under, b, bloom: Sketch.hash(b + 520) < .65);
    }
  }

  // ---- Per frame ---------------------------------------------------------

  static const _birdBody = [Color(0xffd9402f), Color(0xff4fae4a), Color(0xff4fae4a)];
  static const _birdWing = [Color(0xff2f6fc0), Color(0xfff2d04a), Color(0xffd9402f)];

  /// A parrot fleck [u] long in flight, heading left with its tail trailing;
  /// [flap] in -1..1 lifts the wings.
  static void _parrot(Canvas c, double x, double y, double u, double flap, Color body, Color wing) {
    _seg(c, x + u * .35, y, x + u * 1.6, y + u * .28, u * .2, wing);
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: u * 1.15, height: u * .6),
      _fill..color = body,
    );
    _dot(c, x - u * .5, y - u * .12, u * .28, body);
    final lift = flap * u;
    _seg(c, x + u * .12, y - u * .05, x + u * .62, y - u * .12 - lift * .6, u * .3, body);
    _seg(c, x + u * .05, y - u * .1, x + u * .45, y - u * .32 - lift, u * .38, wing);
  }

  /// Parrot flecks skimming the canopy of the mid and low bands.
  static void life(Canvas c, RegionScene s, Depth d, SceneFrame f) {
    final h = f.h, t = f.clock;
    if (d == Depth.mid) {
      final x0 = -h * .16, span = f.w + h * .78;
      for (var i = 0; i < 3; i++) {
        final x = x0 + span - (t * h * .05 + span * .35 + i * h * .03) % span;
        final y =
            s.ridge(Depth.mid, x / h, 0) * h -
            h * (.09 + .01 * i) +
            math.sin(t * .9 + i * 1.7) * h * .004;
        _parrot(c, x, y, h * .0065, math.sin(t * 12 + i * 2.1), _birdBody[i], _birdWing[i]);
      }
    } else if (d == Depth.low) {
      final span = s.period(Depth.low) * h;
      for (var i = 0; i < 2; i++) {
        final x = span - (t * h * .07 + span * .6 + i * h * .04) % span;
        final y =
            s.ridge(Depth.low, x / h, 0) * h -
            h * (.11 + .015 * i) +
            math.sin(t * .8 + i * 2.2) * h * .005;
        _parrot(c, x, y, h * .0085, math.sin(t * 11 + i * 1.9), _birdBody[i + 1], _birdWing[i + 1]);
      }
    }
  }

  /// Slow wisps of valley mist drifting through the trees.
  static void mist(Canvas c, RegionScene s, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    if (d == Depth.mid) {
      for (var i = 0; i < 3; i++) {
        final x = -h * .2 + (f.w + h * .9) * (i + .5) / 3 + math.sin(f.clock * .13 + i * 2.1) * h * .05;
        final y = s.ridge(Depth.mid, x / h, 0) * h - h * .008;
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(x, y), width: h * .55, height: h * .05),
          const Color(0xffffe8cc),
          .34 * presence,
        );
      }
    } else if (d == Depth.low) {
      final span = s.period(Depth.low) * h;
      for (var i = 0; i < 2; i++) {
        final x = span * (i + .5) / 2 + math.sin(f.clock * .11 + i * 1.9) * h * .06;
        final y = s.ridge(Depth.low, x / h, 0) * h - h * .006;
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(x, y), width: h * .6, height: h * .045),
          const Color(0xffffe8cc),
          .26 * presence,
        );
      }
    }
  }
}

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
    Depth.far => .68 + .004 * math.sin(x * 2.3 + 1) + .003 * math.sin(x * 5.9),
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

  /// Portrait screens shrink the far landmarks so they still fit side by side
  /// instead of piling into one another; 1 from roughly 5:8 upward.
  static double _fit(Size size) => math.min(1.0, size.width / size.height * 1.6);

  /// Height of a totem in viewport heights, and where its torch bowl sits.
  static const _totemSize = .17, _bowlTop = .99;

  static Offset _totemBase(RegionScene s, Depth d, double h, double x) =>
      Offset(x, s.ridge(d, x / h, 0) * h + h * .012);

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    final span = period(d) * h;
    final k = _fit(size);
    switch (d) {
      case Depth.far:
        _volcSierra(c, w, h);
        _volcano(c, w * .36, h * (.7 - .34 * k), h * .5 * k, h * .7, wide: true);
        _volcano(c, w * .76, h * (.7 - .4 * k), h * .36 * k, h * .7);
        _foothills(c, w, h);
      case Depth.mid:
        _AztecFlora.midBack(c, this, size, k);
        // Lesser temples first so the great twin-shrined pyramid stands in
        // front of them.
        for (final (fx, s, twin) in _pyrSites) {
          final base = _pyrBase(this, w, h, fx);
          _pyramid(
            c,
            base,
            h * s * k,
            twin: twin,
            redShrine: fx > .6,
            ground: base.dy - h * _pyrSink,
          );
        }
        _AztecFlora.midFront(c, this, size, k);
      case Depth.low:
        _AztecFlora.low(c, this, size);
      case Depth.near:
        _AztecGround.back(c, this, size);
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
        for (final fx in _totems) {
          _totem(
            c,
            _totemBase(this, d, h, span * fx),
            h * _totemSize,
            variant: _totems.indexOf(fx),
          );
        }
    }
  }

  static const _totems = [.26, .58, .9];

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    if (d == Depth.mid) {
      _pyrLive(this, c, f);
      _AztecFlora.life(c, this, d, f);
      return;
    }
    if (d == Depth.far) {
      _volcPlume(c, f);
      return;
    }
    if (d == Depth.low) {
      _AztecFlora.life(c, this, d, f);
      return;
    }
    if (d != Depth.near) return;
    final h = f.h, span = period(d) * h;
    for (var i = 0; i < _totems.length; i++) {
      final base = _totemBase(this, d, h, span * _totems[i]);
      _ttFire(
        c,
        base + Offset(0, -h * _totemSize * _bowlTop),
        h * _totemSize,
        f.clock,
        i * 17 + copy * 5,
      );
    }
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    _AztecFlora.mist(c, this, d, f, presence);
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
            width: math.max(f.w * 1.3, h * 1.6),
            height: h * .1,
          ),
          const Color(0xffffe6c8),
          .5 * presence,
        );
      case Depth.low:
        break;
      case Depth.near:
        _AztecGround.front(c, this, f, presence);
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h;
    final sun = Offset(light.at.dx * w, light.at.dy * h);
    final r = light.radius * h;
    // Dawn colour the plain gradient lacks: a deeper indigo zenith, then a
    // rose band and an apricot glow, so blue meets gold without going grey.
    c.drawRect(
      Rect.fromLTRB(0, 0, w, h * .68),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, h * .68),
          [
            Sketch.fade(const Color(0xff3a3f8f), .34 * presence),
            Sketch.fade(const Color(0xff6f6ab5), .14 * presence),
            Sketch.fade(const Color(0xffff8fa6), .26 * presence),
            Sketch.fade(const Color(0xffffb27a), .18 * presence),
            Sketch.fade(const Color(0xffffd08a), 0),
          ],
          const [0, .24, .5, .74, 1],
        ),
    );
    // The horizon burns brightest under the sun.
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(sun.dx, h * .62),
        width: math.max(w, h) * 1.5,
        height: h * .34,
      ),
      const Color(0xffffd79a),
      .4 * presence,
    );
    // Long sunrise rays fan out over the sky, fading with distance and long
    // enough to leave the screen at any aspect ratio. Each is a soft-edged
    // shaft, a wide faint wedge under a narrower bright one, that breathes.
    final reach = math.max(w, h) * 1.6;
    final ray = Paint()
      ..shader = Gradient.radial(
        sun,
        reach,
        [
          Sketch.fade(const Color(0xffffe1a0), .13 * presence),
          Sketch.fade(const Color(0xffffe1a0), .05 * presence),
          Sketch.fade(const Color(0xffffe1a0), 0),
        ],
        const [0, .35, 1],
      );
    for (var i = 0; i < 10; i++) {
      final a = -2.6 + i * .3 + math.sin(f.clock * .12 + i) * .02;
      final half =
          .05 + .03 * Sketch.hash(i + 60) + .006 * math.sin(f.clock * .3 + i * 1.7);
      for (final k in const [1.0, .45]) {
        final left = sun + Offset(math.cos(a - half * k), math.sin(a - half * k)) * reach;
        final right = sun + Offset(math.cos(a + half * k), math.sin(a + half * k)) * reach;
        _dawnRay
          ..reset()
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(right.dx, right.dy)
          ..close();
        c.drawPath(_dawnRay, ray);
      }
    }
    // A soft bloom, a white-hot core and a thin horizontal flare give the
    // disc depth.
    c.drawCircle(
      sun,
      r * 4.2,
      Paint()
        ..shader = Gradient.radial(
          sun,
          r * 4.2,
          [
            Sketch.fade(const Color(0xfffff3c9), .45 * presence),
            Sketch.fade(const Color(0xfffff3c9), .34 * presence),
            Sketch.fade(const Color(0xffffd98f), .15 * presence),
            Sketch.fade(const Color(0xffffb56b), .05 * presence),
            Sketch.fade(const Color(0xffffb56b), 0),
          ],
          const [0, .24, .5, .78, 1],
        ),
    );
    c.drawCircle(
      sun,
      r,
      Paint()
        ..shader = Gradient.radial(
          sun,
          r,
          [
            Sketch.fade(const Color(0xfffffdf0), .95 * presence),
            Sketch.fade(const Color(0xfffff6d2), .5 * presence),
            Sketch.fade(const Color(0xfffff0c0), 0),
          ],
          const [0, .55, 1],
        ),
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: sun, width: h * .9, height: h * .03),
      const Color(0xfffff1c8),
      .32 * presence,
    );
    // Thin dawn streaks, gilded near the sun and rose farther off: a soft
    // glow, a shaded lens and a bright underside.
    for (final (fx, fy, fw, color) in const [
      (.3, .16, .5, Color(0xffffdcc0)),
      (.75, .24, .4, Color(0xffffcfb8)),
      (.1, .33, .35, Color(0xffffe3b0)),
      (.55, .5, .45, Color(0xffffd9b0)),
    ]) {
      final x = (w * fx - f.clock * h * .008) % (w + h) - h * .5;
      final y = h * fy;
      Sketch.mist(
        c,
        Rect.fromCenter(center: Offset(x, y), width: h * fw * 2, height: h * .04),
        color,
        .5 * presence,
      );
      final double near = 1.0 - math.min(1.0, (x - sun.dx).abs() / (h * 1.1));
      c.save();
      c.translate(x, y);
      c.scale(h * fw * .8, h * .012);
      _dawnPaint.color = Sketch.fade(const Color(0xffc48aa8), .3 * presence);
      c.drawPath(_dawnLens, _dawnPaint);
      c.translate(0, .5);
      c.scale(.85, .55);
      _dawnPaint.color = Sketch.fade(
        Sketch.mix(const Color(0xffffb59a), const Color(0xffffe6a8), near),
        .75 * presence,
      );
      c.drawPath(_dawnLens, _dawnPaint);
      c.restore();
    }
    // Scarlet macaws cross in a loose pair, long tails trailing behind. The
    // pair start with one wing up and one down so a frozen frame (Reduced
    // Motion) still shows the wing bands.
    final lead = Offset(
      (w * .6 - f.clock * h * .05) % (w + h * .5) - h * .25,
      h * .2 + math.sin(f.clock * .5) * h * .012,
    );
    final fade = math.min(1.0, presence);
    for (var i = 0; i < 2; i++) {
      final u = h * (i == 0 ? .06 : .05);
      final at =
          lead +
          Offset(i * h * .11, i * (h * .03 + math.sin(f.clock * .4 + 1) * h * .008));
      if (at.dx < -u * 3 || at.dx > w + u * 3) continue;
      final flap = f.clock * (i == 0 ? 8.0 : 7.6) + (i == 0 ? 1.9 : 4.4);
      if (fade < .999) {
        c.saveLayer(
          Rect.fromLTRB(at.dx - u * 2.4, at.dy - u * 1.4, at.dx + u * 2.4, at.dy + u * 1.4),
          Paint()..color = Color.fromRGBO(0, 0, 0, fade),
        );
      }
      _macaw(c, at, u, flap, .04 + .03 * math.sin(f.clock * .5 + i));
      if (fade < .999) c.restore();
    }
  }

  static final _dawnRay = Path();
  static final _dawnPaint = Paint();

  // A streak of cloud: a lens with a pointed tail and a flatter underside.
  static final _dawnLens = _macPath('M -1 0 Q 0 -1.1 1 0 Q 0 0.6 -1 0 Z');

  /// A [Path] from absolute SVG-style data (M, L, Q, C, Z) with
  /// space-separated numbers, so the macaw's art stays compact.
  static Path _macPath(String d) {
    final path = Path();
    final t = d.trim().split(RegExp(r'\s+'));
    var i = 0;
    double n() => double.parse(t[i++]);
    while (i < t.length) {
      switch (t[i++]) {
        case 'M':
          path.moveTo(n(), n());
        case 'L':
          path.lineTo(n(), n());
        case 'Q':
          path.quadraticBezierTo(n(), n(), n(), n());
        case 'C':
          path.cubicTo(n(), n(), n(), n(), n(), n());
        default:
          path.close();
      }
    }
    return path;
  }

  static const _macRed = Color(0xffd8261e), _macRedDark = Color(0xff9c1520);
  static const _macLit = Color(0xffff6a35), _macYellow = Color(0xfff7c320);
  static const _macGreen = Color(0xff2fa04c), _macBlue = Color(0xff2a62c6);
  static const _macBlueDark = Color(0xff1c3e94);
  static const _macHorn = Color(0xfff0e2c6), _macBeak = Color(0xff2b2124);
  static const _macFace = Color(0xfffff1e6), _macInk = Color(0xff1b1216);

  // Macaw art, facing right, y down, origin at the body's centre, 1 = the
  // body's length. The caller mirrors it to fly left.
  static final _macBody = _macPath(
    'M 0.415 -0.09 C 0.41 -0.18 0.32 -0.235 0.235 -0.185 C 0.19 -0.155 0.14 -0.135 0.05 -0.125 '
    'C -0.06 -0.115 -0.2 -0.09 -0.32 -0.03 C -0.32 0.01 -0.3 0.03 -0.26 0.05 '
    'C -0.16 0.1 -0.06 0.12 0.03 0.115 C 0.14 0.11 0.23 0.085 0.29 0.035 '
    'C 0.335 0.0 0.37 -0.01 0.395 -0.03 C 0.41 -0.045 0.415 -0.07 0.415 -0.09 Z',
  );
  // Belly light and back shade are drawn generously and clipped to the body.
  static final _macBelly = _macPath(
    'M 0.5 0.3 L -0.5 0.3 L -0.4 0.0 C -0.25 0.03 -0.1 0.055 0.05 0.06 C 0.15 0.06 0.25 0.03 0.33 -0.02 L 0.5 -0.01 Z',
  );
  static final _macBack = _macPath(
    'M 0.5 -0.45 L -0.5 -0.45 L -0.5 -0.03 C -0.3 -0.04 -0.15 -0.075 0.05 -0.085 '
    'C 0.15 -0.09 0.2 -0.115 0.24 -0.155 C 0.3 -0.19 0.36 -0.19 0.5 -0.17 Z',
  );
  static final _macFlow = _macPath(
    'M 0.2 -0.115 Q 0.02 -0.095 -0.28 -0.035 M 0.12 -0.085 Q -0.02 -0.07 -0.24 -0.02',
  );
  static final _macFacePatch = _macPath(
    'M 0.415 -0.082 C 0.412 -0.15 0.37 -0.172 0.322 -0.158 C 0.27 -0.14 0.262 -0.09 0.29 -0.06 '
    'C 0.32 -0.028 0.385 -0.03 0.415 -0.06 Z',
  );
  static final _macFaceLines = _macPath(
    'M 0.31 -0.138 Q 0.34 -0.146 0.38 -0.136 M 0.3 -0.078 Q 0.34 -0.068 0.395 -0.075 M 0.305 -0.058 Q 0.34 -0.05 0.385 -0.056',
  );
  static final _macUpperBeak = _macPath(
    'M 0.4 -0.168 C 0.435 -0.19 0.505 -0.192 0.55 -0.15 C 0.582 -0.118 0.6 -0.075 0.592 -0.035 '
    'C 0.588 -0.012 0.568 -0.014 0.561 -0.034 C 0.55 -0.06 0.53 -0.075 0.5 -0.079 C 0.46 -0.083 0.43 -0.08 0.4 -0.072 Z',
  );
  static final _macLowerBeak = _macPath(
    'M 0.4 -0.08 C 0.44 -0.085 0.48 -0.086 0.505 -0.076 C 0.512 -0.055 0.5 -0.032 0.47 -0.024 '
    'C 0.445 -0.018 0.415 -0.022 0.395 -0.04 Z',
  );
  static final _macBeakShade = _macPath(
    'M 0.4 -0.1 C 0.45 -0.1 0.5 -0.11 0.54 -0.09 C 0.56 -0.075 0.58 -0.06 0.6 -0.02 L 0.6 0 L 0.4 0 Z',
  );

  // The tail's root sits at the origin and streams toward -x; its blue tip and
  // gilded underside are clipped to it.
  static final _macTail = _macPath(
    'M 0.05 -0.05 C -0.1 -0.07 -0.3 -0.1 -0.72 -0.065 C -0.8 -0.05 -0.84 -0.005 -0.9 0.03 '
    'C -0.75 0.09 -0.45 0.115 -0.22 0.105 C -0.1 0.095 -0.03 0.07 0.05 0.05 Z',
  );
  static final _macTailTip = _macPath('M -0.56 -0.2 L -0.7 0 L -0.56 0.2 L -1 0.2 L -1 -0.2 Z');
  static final _macTailUnder = _macPath('M -0.95 0.04 C -0.6 0.06 -0.3 0.06 0.1 0.02 L 0.1 0.2 L -0.95 0.2 Z');
  static final _macTailLines = _macPath('M 0 0.0 L -0.85 0.02 M -0.1 -0.045 L -0.72 -0.03 M -0.1 0.055 L -0.72 0.045');

  // A wing from its root at the origin to the tip at (-0.12, -1), leading edge
  // toward +x: the outline with fingered primaries, then the nested covert
  // bands (red over yellow over green over the blue flight feathers).
  static final _macWing = _macPath(
    'M 0.11 0.05 C 0.2 -0.08 0.22 -0.28 0.165 -0.42 C 0.115 -0.6 0 -0.82 -0.12 -1 Q -0.165 -0.955 -0.063 -0.914 '
    'Q -0.289 -0.946 -0.119 -0.813 Q -0.352 -0.848 -0.176 -0.711 Q -0.404 -0.74 -0.235 -0.609 '
    'Q -0.44 -0.631 -0.285 -0.508 Q -0.467 -0.522 -0.321 -0.407 Q -0.469 -0.4 -0.361 -0.333 '
    'Q -0.463 -0.293 -0.373 -0.24 Q -0.465 -0.202 -0.378 -0.156 Q -0.457 -0.121 -0.368 -0.081 '
    'Q -0.443 -0.054 -0.345 -0.011 Q -0.417 0.016 -0.3 0.06 L -0.12 0.08 Z',
  );
  static final _macWingRed = _macPath(
    'M 0.7 0.35 L -0.1 0.35 L -0.092 0.29 L -0.081 0.23 L -0.072 0.17 L -0.064 0.11 L -0.049 0.05 L -0.033 -0.01 '
    'L -0.019 -0.07 L -0.01 -0.13 L 0.007 -0.19 L 0.025 -0.25 L 0.036 -0.31 L 0.048 -0.37 L 0.062 -0.43 '
    'L 0.07 -0.49 L 0.073 -0.55 L 0.075 -0.61 L 0.065 -0.67 L 0.052 -0.73 L 0.022 -0.79 L 0 -0.84 L 0.7 -0.84 Z',
  );
  static final _macWingYellow = _macPath(
    'M 0.7 0.35 L -0.21 0.35 Q -0.265 0.3 -0.195 0.25 Q -0.245 0.2 -0.18 0.15 Q -0.234 0.1 -0.159 0.05 '
    'Q -0.205 0 -0.133 -0.05 Q -0.187 -0.1 -0.112 -0.15 Q -0.154 -0.2 -0.076 -0.25 Q -0.122 -0.3 -0.052 -0.35 '
    'Q -0.097 -0.4 -0.023 -0.45 Q -0.074 -0.5 -0.01 -0.55 Q -0.062 -0.6 -0.007 -0.65 L -0.024 -0.66 L 0.7 -0.66 Z',
  );
  static final _macWingGreen = _macPath(
    'M 0.7 0.35 L -0.255 0.35 Q -0.31 0.3 -0.24 0.25 Q -0.29 0.2 -0.225 0.15 Q -0.279 0.1 -0.204 0.05 '
    'Q -0.25 0 -0.178 -0.05 Q -0.232 -0.1 -0.157 -0.15 Q -0.199 -0.2 -0.121 -0.25 Q -0.167 -0.3 -0.097 -0.35 '
    'Q -0.142 -0.4 -0.068 -0.45 Q -0.119 -0.5 -0.055 -0.55 L -0.065 -0.6 L 0.7 -0.6 Z',
  );
  static final _macWingLines = _macPath(
    'M -0.063 -0.914 L 0.084 -0.854 M -0.119 -0.813 L 0.028 -0.752 M -0.176 -0.711 L -0.029 -0.65 '
    'M -0.235 -0.609 L -0.088 -0.549 M -0.285 -0.508 L -0.138 -0.447 M -0.321 -0.407 L -0.174 -0.346 '
    'M -0.361 -0.333 L -0.242 -0.321 M -0.373 -0.24 L -0.254 -0.228 M -0.378 -0.156 L -0.259 -0.144 '
    'M -0.368 -0.081 L -0.249 -0.069 M -0.345 -0.011 L -0.227 0.001',
  );
  static final _macWingEdge = _macPath(
    'M 0.11 0.05 C 0.2 -0.08 0.22 -0.28 0.165 -0.42 C 0.135 -0.53 0.09 -0.64 0.04 -0.74',
  );

  static final _macFill = Paint();
  static final _macStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static void _macDraw(Canvas c, Path p, Color color) {
    _macFill.color = color;
    c.drawPath(p, _macFill);
  }

  static void _macLine(Canvas c, Path p, Color color, double width) {
    _macStroke
      ..color = color
      ..strokeWidth = width;
    c.drawPath(p, _macStroke);
  }

  /// A scarlet macaw flying left at [at], [u] pixels per body length, wings
  /// at flap phase [flap] (radians) and pitched up by [bank]. The body rises
  /// on the downstroke, the tail lags it, and the wing tips trail the beat.
  static void _macaw(Canvas c, Offset at, double u, double flap, double bank) {
    final p = math.sin(flap);
    c.save();
    c.translate(at.dx, at.dy + u * .03 * p);
    c.rotate(bank);
    c.scale(-u, u);
    // The far wing beats a little behind, in shade.
    _macWingDraw(c, -.02, -.09, math.sin(flap - .8), math.cos(flap - .8), true);
    c.save();
    c.translate(-.24, 0);
    c.rotate(.07 * math.sin(flap - .8));
    c.save();
    c.clipPath(_macTail);
    _macDraw(c, _macTail, _macRed);
    _macDraw(c, _macTailUnder, _macLit.withValues(alpha: .6));
    _macDraw(c, _macTailTip, _macBlue);
    _macLine(c, _macTailLines, _macRedDark.withValues(alpha: .5), .012);
    c.restore();
    c.restore();
    c.save();
    c.clipPath(_macBody);
    _macDraw(c, _macBody, _macRed);
    _macDraw(c, _macBelly, _macLit.withValues(alpha: .55));
    _macDraw(c, _macBack, _macRedDark.withValues(alpha: .7));
    _macLine(c, _macFlow, _macRedDark.withValues(alpha: .35), .01);
    c.restore();
    // Pale hooked upper mandible over a dark lower one, the bare white face
    // patch with its fine red feather lines over the beak's base, then the eye.
    _macDraw(c, _macLowerBeak, _macBeak);
    _macDraw(c, _macUpperBeak, _macHorn);
    c.save();
    c.clipPath(_macUpperBeak);
    _macDraw(c, _macBeakShade, const Color(0xffbfae90));
    c.restore();
    _macDraw(c, _macFacePatch, _macFace);
    _macLine(c, _macFaceLines, _macRed.withValues(alpha: .75), .008);
    _macFill.color = const Color(0xfff4e58a);
    c.drawCircle(const Offset(.322, -.108), .028, _macFill);
    _macFill.color = _macInk;
    c.drawCircle(const Offset(.325, -.108), .016, _macFill);
    _macFill.color = const Color(0xffffffff);
    c.drawCircle(const Offset(.319, -.115), .005, _macFill);
    _macWingDraw(c, .06, -.075, p, math.cos(flap), false);
    c.restore();
  }

  /// One wing pivoting at ([sx], [sy]): [p] (-1..1) is its height in the beat
  /// and [q] its speed, which shears the tip to lag behind the root. The
  /// planform shortens toward mid-stroke as it points at the viewer.
  static void _macWingDraw(Canvas c, double sx, double sy, double p, double q, bool far) {
    c.save();
    c.translate(sx, sy);
    c.rotate(-1.35 + 1.05 * p);
    c.scale(.62, .95 * (.66 + .34 * p * p));
    c.skew(.3 * q, 0);
    c.clipPath(_macWing);
    // Dark under-feathers show as a rim where the lighter blue is inset.
    _macDraw(c, _macWing, _macBlueDark);
    c.translate(.05, 0);
    _macDraw(c, _macWing, far ? const Color(0xff2a4fa8) : _macBlue);
    c.translate(-.05, 0);
    if (!far) _macLine(c, _macWingLines, _macBlueDark.withValues(alpha: .55), .02);
    _macDraw(c, _macWingGreen, far ? const Color(0xff23703a) : _macGreen);
    _macDraw(c, _macWingYellow, far ? const Color(0xffc99a1a) : _macYellow);
    _macDraw(c, _macWingRed, far ? _macRedDark : _macRed);
    if (!far) _macLine(c, _macWingEdge, const Color(0x99ffd08a), .05);
    c.restore();
  }

  /// Two forested ranges in front of the volcanoes' feet: a paler, hazier one
  /// behind and a darker, warmer one in front, each lit on its left slopes
  /// and shaded on its right, with a ragged crest of treetops.
  static void _foothills(Canvas c, double w, double h) {
    _volcHills(
      c,
      w,
      h,
      (u) =>
          .624 -
          .03 *
              math.max(
                .9 * Sketch.humps(u / .55 + .1),
                .7 * Sketch.humps(u / .27 + .55),
              ),
      h * .012,
      lit: _hazed(const Color(0xffb08a88), .3),
      shade: _hazed(const Color(0xff6a608f), .32),
      base: _hazed(const Color(0xffcf9c94), .32),
      jitter: .004,
      seed: 50,
    );
    _volcHills(
      c,
      w,
      h,
      (u) =>
          .655 -
          .022 *
              math.max(
                .9 * Sketch.humps(u / .31 + .3),
                .75 * Sketch.humps(u / .17 + .8),
              ),
      h * .01,
      lit: _hazed(const Color(0xff9a7a78), .24),
      shade: _hazed(const Color(0xff5a5486), .26),
      base: _hazed(const Color(0xffb88c88), .3),
      jitter: .0035,
      seed: 250,
    );
  }

  /// The faint sierra of the valley rim, jagged and almost lost in haze,
  /// behind both volcanoes.
  static void _volcSierra(Canvas c, double w, double h) {
    _volcHills(
      c,
      w,
      h,
      (u) =>
          .59 -
          .024 * Sketch.peaks(u / 1.15 + .2) -
          .016 * Sketch.peaks(u / .52 + .6) -
          .006 * Sketch.peaks(u / .21 + .1),
      h * .03,
      lit: _hazed(const Color(0xffa58fb8), .55),
      shade: _hazed(const Color(0xff7f74a8), .55),
      base: _hazed(const Color(0xffb8a0b8), .7),
    );
  }

  /// One skyline of hills or mountains from [crest] (height fraction at a
  /// world x in viewport heights): a fill fading into [base] with the right
  /// facing slopes of every crest shaded.
  static void _volcHills(
    Canvas c,
    double w,
    double h,
    double Function(double u) crest,
    double step, {
    required Color lit,
    required Color shade,
    required Color base,
    double jitter = 0,
    int seed = 0,
  }) {
    final n = ((w + h * 1.4) / step).ceil();
    final xs = List<double>.filled(n + 1, 0.0);
    final cy = List<double>.filled(n + 1, 0.0);
    final ys = List<double>.filled(n + 1, 0.0);
    var top = h;
    for (var i = 0; i <= n; i++) {
      xs[i] = -h * .2 + i * step;
      cy[i] = crest(xs[i] / h) * h;
      ys[i] = cy[i] - jitter * h * Sketch.hash(seed + i);
      top = math.min(top, ys[i]);
    }
    final floor = h * .7;
    final fill = Path()..moveTo(xs[0], floor);
    for (var i = 0; i <= n; i++) {
      fill.lineTo(xs[i], ys[i]);
    }
    fill
      ..lineTo(xs[n], floor)
      ..close();
    c.drawPath(
      fill,
      Paint()..shader = Gradient.linear(Offset(0, top), Offset(0, floor), [lit, base]),
    );
    final dark = Path();
    var r = 0;
    while (r < n) {
      if (cy[r + 1] - cy[r] > step * .04) {
        var j = r + 1;
        while (j < n && cy[j + 1] - cy[j] > step * .04) {
          j++;
        }
        dark.moveTo(xs[r], floor);
        for (var k = r; k <= j; k++) {
          dark.lineTo(xs[k], ys[k]);
        }
        dark
          ..lineTo(xs[j], floor)
          ..close();
        r = j;
      } else {
        r++;
      }
    }
    c.drawPath(
      dark,
      Paint()
        ..shader = Gradient.linear(Offset(0, top), Offset(0, floor), [
          Sketch.fade(shade, .9),
          Sketch.fade(shade, 0),
        ]),
    );
  }

  /// The valley's two great volcanoes: [wide] is Iztaccihuatl, the Sleeping
  /// Woman, otherwise Popocatepetl with its smoking crater (the plume itself
  /// is animated in [live]). Light comes from the left, so left faces glow
  /// rose and gold while right faces fall into violet shade, and both fade
  /// into haze towards the foot.
  static void _volcano(
    Canvas c,
    double x,
    double top,
    double half,
    double base, {
    bool wide = false,
  }) {
    if (wide) {
      _volcRidge(c, x, top, half, base);
    } else {
      _volcCone(c, x, top, half, base);
    }
  }

  /// Half-width of a cone flank at depth fraction [t] below the crater rim:
  /// steep near the summit, flattening towards the foot, with a slow wobble.
  static double _volcEdge(
    double t,
    double cr,
    double half,
    double lin,
    double ph,
  ) =>
      (cr + (half - cr) * (lin * t + (1 - lin) * t * t)) *
      (1 + .028 * math.sin(t * 13 + ph) + .012 * math.sin(t * 31 + ph * 2.3));

  /// Flank of the Sleeping Woman as a fraction of the half-width at depth
  /// fraction [d]: it leaves the summit ridge at ([u0], [d0]) and sweeps out
  /// to the foot at 1.
  static double _volcFlank(double d, double u0, double d0, double lin) {
    final g = math.min(1.0, math.max(0.0, (d - d0) / (1 - d0)));
    return (u0 + (1 - u0) * (lin * g + (1 - lin) * g * g)) *
        (1 + .03 * math.sin(d * 15 + u0 * 9) + .012 * math.sin(d * 33 + u0));
  }

  /// A lens-shaped sliver from a left tip to a right tip, [t] thick.
  static Path _volcLens(Offset o, double w, double t, double tilt) => Path()
    ..moveTo(o.dx - w, o.dy - tilt)
    ..quadraticBezierTo(o.dx - w * .15, o.dy - t * 2, o.dx + w, o.dy + tilt)
    ..quadraticBezierTo(o.dx + w * .1, o.dy + t * 1.1, o.dx - w, o.dy - tilt)
    ..close();

  /// A wisp of cloud of half-length [w] catching the sunrise: glowing cream
  /// on top with a rose belly in shade.
  static void _volcWisp(
    Canvas c,
    Offset o,
    double w,
    double t, {
    double tilt = 0.0,
    double alpha = 1.0,
  }) {
    Sketch.mist(
      c,
      Rect.fromCenter(center: o, width: w * 2.4, height: t * 6),
      const Color(0xffffe8d2),
      .32 * alpha,
    );
    c.drawPath(
      _volcLens(o.translate(0, t * .5), w * .96, t * .8, tilt),
      Paint()..color = Sketch.fade(const Color(0xffe2a6bc), .5 * alpha),
    );
    c.drawPath(
      _volcLens(o, w, t, tilt),
      Paint()..color = Sketch.fade(const Color(0xffffeee0), .72 * alpha),
    );
    c.drawPath(
      _volcLens(o.translate(-w * .2, -t * .35), w * .6, t * .55, tilt * .6),
      Paint()..color = Sketch.fade(const Color(0xfffffaee), .8 * alpha),
    );
  }

  /// Popocatepetl: a tall stratovolcano with a notched crater rim, snowcap
  /// tongues running down its gullies, dark ash and lava streaks, strata
  /// low on the slopes and the jagged Ventorrillo shouldering out behind its
  /// left flank.
  static void _volcCone(
    Canvas c,
    double x,
    double top,
    double half,
    double base,
  ) {
    final hh = base - top;
    final cr = half * .15;
    final shade = _hazed(const Color(0xff5f5390), .16);
    final lit = _hazed(const Color(0xffce8486), .16);
    final dark = _hazed(const Color(0xff3a2e54), .2);
    final snowLit = _hazed(const Color(0xffffeedc), .05);
    final snowShade = _hazed(const Color(0xffb0aade), .12);
    // The left flank is straighter; the right swells into a buttress at mid
    // height, so the cone is never symmetric.
    double eL(double t) => _volcEdge(t, cr, half * 1.03, .5, 1.3);
    double eR(double t) {
      final z = (t - .5) / .09;
      return _volcEdge(t, cr, half * .97, .38, 4.1) +
          half * .035 * math.exp(-z * z);
    }

    // The point a of the way across (-1 left edge .. 1 right edge) at depth t.
    double px(double a, double t) => x + a * (a < 0 ? eL(t) : eR(t));
    double py(double t) => top + hh * t;
    const ts = <double>[
      .03, .07, .12, .18, .25, .32, .4, .48, .56, .64, .72, .8, .88, .95, //
    ];
    // Crater rim: (fraction of the crater radius, fraction of the height).
    const rim = <(double, double)>[
      (-.98, .014),
      (-.55, 0.0),
      (-.1, .006),
      (.18, .03),
      (.5, .02),
      (.78, .006),
      (1.0, .018),
    ];

    // A gully or flow: a ribbon down the cone at across-fraction a from
    // depth t0 to t1, growing from width w0 to w1 and meandering by wig.
    void ribbon(
      Path p,
      double a,
      double t0,
      double t1,
      double w0,
      double w1, {
      double wig = 0.0,
      double ph = 0.0,
      bool cap = false,
    }) {
      const n = 6;
      final fore = .4 + .6 * math.sqrt(1 - a * a);
      final l = <Offset>[], r = <Offset>[];
      var end = Offset.zero;
      var g = 0.0;
      for (var i = 0; i <= n; i++) {
        final s = i / n;
        final t = t0 + (t1 - t0) * s;
        final cx = px(a, t) + wig * math.sin(s * 5 + ph) * s;
        g = (w0 + (w1 - w0) * s) * fore;
        l.add(Offset(cx - g, py(t)));
        r.add(Offset(cx + g, py(t)));
        end = Offset(cx, py(t));
      }
      p.moveTo(l[0].dx, l[0].dy);
      for (var i = 1; i <= n; i++) {
        p.lineTo(l[i].dx, l[i].dy);
      }
      for (var i = n; i >= 0; i--) {
        p.lineTo(r[i].dx, r[i].dy);
      }
      p.close();
      if (cap) {
        p.addOval(Rect.fromCenter(center: end, width: g * 2.4, height: g * 1.8));
      }
    }

    // A wisp of cloud behind the summit, the peak standing up out of it.
    _volcWisp(
      c,
      Offset(x + half * .42, py(.035)),
      half * .5,
      hh * .02,
      tilt: -hh * .006,
      alpha: .8,
    );

    // The Ventorrillo: the eroded rim of the ancestral cone, dark and
    // jagged, standing off the left flank a little farther away.
    const ridge = <(double, double)>[
      (-.92, 1.0),
      (-.74, .68),
      (-.6, .47),
      (-.52, .34),
      (-.47, .27),
      (-.43, .3),
      (-.4, .22),
      (-.36, .255),
      (-.325, .19),
      (-.29, .24),
      (-.25, .225),
      (-.2, .3),
      (-.1, .5),
      (0.0, 1.0),
    ];
    final ventShade = Path(), ventLit = Path();
    for (var i = 0; i < ridge.length; i++) {
      final (u, t) = ridge[i];
      if (i == 0) {
        ventShade.moveTo(x + u * half, py(t));
      } else {
        ventShade.lineTo(x + u * half, py(t));
      }
    }
    ventShade.close();
    ventLit.moveTo(x + ridge[0].$1 * half, base);
    for (var i = 1; i <= 8; i++) {
      final (u, t) = ridge[i];
      ventLit.lineTo(x + u * half, py(t));
    }
    ventLit
      ..lineTo(x - .42 * half, py(.6))
      ..lineTo(x - .55 * half, base)
      ..close();
    c.drawPath(ventShade, Paint()..color = _hazed(const Color(0xff6a5c92), .3));
    c.drawPath(ventLit, Paint()..color = _hazed(const Color(0xffb87a80), .3));

    // The cone: sunlit rose on the left, violet shade to the right of a
    // jagged terminator where each spur catches or loses the light.
    final sil = Path()..moveTo(x - eL(1), base);
    for (var i = ts.length - 1; i >= 0; i--) {
      sil.lineTo(px(-1, ts[i]), py(ts[i]));
    }
    for (final (rx, ry) in rim) {
      sil.lineTo(x + cr * rx, top + hh * ry);
    }
    for (final t in ts) {
      sil.lineTo(px(1, t), py(t));
    }
    sil
      ..lineTo(x + eR(1), base)
      ..close();
    c.drawPath(sil, Paint()..color = lit);
    double term(double t) {
      final a = .1 - .16 * t + .07 * t * math.sin(t * 24 + 1.3);
      return a * (a < 0 ? eL(t) : eR(t));
    }

    final shadeArea = Path()..moveTo(x + cr * .18, top + hh * .03);
    for (var i = 4; i < rim.length; i++) {
      final (rx, ry) = rim[i];
      shadeArea.lineTo(x + cr * rx, top + hh * ry);
    }
    for (final t in ts) {
      shadeArea.lineTo(px(1, t), py(t));
    }
    shadeArea
      ..lineTo(x + eR(1), base)
      ..lineTo(x + term(1), base);
    for (var i = ts.length - 1; i >= 0; i--) {
      shadeArea.lineTo(x + term(ts[i]), py(ts[i]));
    }
    shadeArea.close();
    c.drawPath(shadeArea, Paint()..color = shade);

    // Gullies fan down from the summit; a pale lip catches the sun beside
    // each one on the lit side.
    final gl = Path(), gs = Path(), hi = Path();
    for (final (a, t0, t1, w1) in const <(double, double, double, double)>[
      (-.7, .1, .97, .017),
      (-.4, .12, 1.0, .02),
      (-.55, .3, .95, .012),
      (-.2, .3, 1.0, .015),
      (-.86, .34, .9, .011),
    ]) {
      ribbon(gl, a, t0, t1, half * .002, half * w1, wig: half * .03, ph: a * 9);
      ribbon(
        hi,
        a + .06,
        t0 + .04,
        t1,
        half * .001,
        half * .006,
        wig: half * .03,
        ph: a * 9,
      );
    }
    for (final (a, t0, t1, w1) in const <(double, double, double, double)>[
      (0.0, .1, 1.0, .018),
      (.3, .1, .98, .02),
      (.15, .32, 1.0, .014),
      (.48, .3, .97, .016),
      (.6, .12, 1.0, .02),
      (.75, .3, .93, .013),
      (.9, .34, .9, .01),
    ]) {
      ribbon(
        gs,
        a,
        t0,
        t1,
        half * .002,
        half * w1,
        wig: half * .03,
        ph: a * 9 + 2,
      );
    }
    c.drawPath(gl, Paint()..color = Sketch.fade(shade, .55));
    c.drawPath(gs, Paint()..color = Sketch.fade(dark, .5));
    c.drawPath(hi, Paint()..color = Sketch.fade(const Color(0xffffd9b4), .3));

    // Strata: shallow arcs of layered lava and ash low on the slopes.
    final strata = Path();
    for (final (t, a0, a1, sag) in const <(double, double, double, double)>[
      (.36, -.95, -.35, .011),
      (.42, .05, .9, .012),
      (.48, -.9, -.05, .012),
      (.54, -.3, .85, .013),
      (.6, -.95, .25, .012),
      (.66, .1, .9, .012),
    ]) {
      final y = py(t), x0 = px(a0, t), x1 = px(a1, t);
      strata
        ..moveTo(x0, y)
        ..quadraticBezierTo((x0 + x1) / 2, y + hh * sag * 2, x1, y);
    }
    final sw = math.max(.7, hh * .0035);
    c.drawPath(
      strata,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..color = Sketch.fade(dark, .3),
    );
    c.save();
    c.translate(0, sw * 1.4);
    c.drawPath(
      strata,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..color = Sketch.fade(const Color(0xffffd7b0), .16),
    );
    c.restore();

    // An old lava flow: a dark tongue with a rounded toe on the lit slope.
    final flow = Path();
    ribbon(
      flow,
      -.5,
      .34,
      .57,
      half * .004,
      half * .022,
      wig: -half * .03,
      ph: 2.2,
      cap: true,
    );
    c.drawPath(
      flow,
      Paint()..color = Sketch.fade(_hazed(const Color(0xff4a2c48), .2), .5),
    );

    // A thin sun-rim along the left silhouette.
    final rimLight = Path()..moveTo(x - eL(1), base);
    for (var i = ts.length - 1; i >= 0; i--) {
      rimLight.lineTo(px(-1, ts[i]), py(ts[i]));
    }
    rimLight
      ..lineTo(x - cr * .98, top + hh * .014)
      ..lineTo(x - cr * .55, top);
    c.drawPath(
      rimLight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, hh * .004)
        ..color = Sketch.fade(const Color(0xffffe2b0), .4),
    );

    // The snowcap: fingers reach down the gullies, ribs of rock poke up
    // between them, and every edge is ragged.
    const edge = <(double, double)>[
      (-1.0, .27),
      (-.9, .33),
      (-.8, .25),
      (-.7, .4),
      (-.6, .29),
      (-.5, .23),
      (-.4, .36),
      (-.3, .28),
      (-.2, .21),
      (-.1, .31),
      (0.0, .43),
      (.1, .3),
      (.2, .24),
      (.3, .38),
      (.4, .27),
      (.5, .34),
      (.6, .45),
      (.7, .28),
      (.8, .25),
      (.9, .35),
      (1.0, .3),
    ];
    final snow = Path()..moveTo(px(-1, edge.first.$2), py(edge.first.$2));
    for (var i = ts.length - 1; i >= 0; i--) {
      if (ts[i] < edge.first.$2) snow.lineTo(px(-1, ts[i]), py(ts[i]));
    }
    for (final (rx, ry) in rim) {
      snow.lineTo(x + cr * rx, top + hh * ry);
    }
    for (final t in ts) {
      if (t < edge.last.$2) snow.lineTo(px(1, t), py(t));
    }
    for (var i = edge.length - 1; i >= 0; i--) {
      final (a, d) = edge[i];
      snow.lineTo(px(a, d), py(d));
      if (i > 0) {
        final (a2, d2) = edge[i - 1];
        final md = (d + d2) / 2 + .03 * (Sketch.hash(i + 10) - .5);
        snow.lineTo(px((a + a2) / 2, md), py(md));
      }
    }
    snow.close();
    c.drawPath(snow, Paint()..color = snowLit);
    c.save();
    c.clipPath(snow);
    c.drawPath(shadeArea, Paint()..color = snowShade);
    c.drawPath(gl, Paint()..color = Sketch.fade(snowShade, .8));
    c.drawPath(
      gs,
      Paint()..color = Sketch.fade(const Color(0xff8f86c4), .5),
    );
    c.drawPath(hi, Paint()..color = Sketch.fade(const Color(0xfffff8ee), .7));
    c.restore();

    // Rock breaking through the snow near the summit, and the ash streak
    // running down from the crater.
    final crags = Path();
    for (final (a, t, s) in const <(double, double, double)>[
      (-.5, .1, 1.0),
      (-.18, .14, .8),
      (.22, .12, .9),
      (.5, .2, 1.1),
      (-.72, .21, .8),
    ]) {
      crags
        ..moveTo(px(a, t), py(t))
        ..lineTo(px(a + .05 * s, t + .05 * s), py(t + .05 * s))
        ..lineTo(px(a - .05 * s, t + .06 * s), py(t + .06 * s))
        ..close();
    }
    c.drawPath(crags, Paint()..color = Sketch.fade(dark, .55));
    final ash = Path();
    ribbon(
      ash,
      .3,
      .03,
      .6,
      half * .004,
      half * .03,
      wig: half * .05,
      ph: 1.0,
      cap: true,
    );
    c.drawPath(ash, Paint()..color = Sketch.fade(dark, .5));

    // The crater: a dark bowl under the notch with a sunlit lip.
    c.drawPath(
      Sketch.poly([
        x - cr * .5,
        top + hh * .004,
        x - cr * .1,
        top + hh * .007,
        x + cr * .18,
        top + hh * .03,
        x + cr * .5,
        top + hh * .021,
        x + cr * .75,
        top + hh * .006,
        x + cr * .55,
        top + hh * .05,
        x + cr * .1,
        top + hh * .062,
        x - cr * .35,
        top + hh * .04,
      ]),
      Paint()..color = _hazed(const Color(0xff4a3a68), .15),
    );
    c.drawPath(
      Path()
        ..moveTo(x - cr * .98, top + hh * .014)
        ..lineTo(x - cr * .55, top)
        ..lineTo(x - cr * .1, top + hh * .006),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, hh * .004)
        ..color = Sketch.fade(const Color(0xffffeec8), .85),
    );

    // Aerial perspective: the foot of the cone dissolves into haze.
    c.drawPath(
      sil,
      Paint()
        ..shader = Gradient.linear(
          Offset(x, top + hh * .25),
          Offset(x, top + hh * .85),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .6)],
        ),
    );

    // Cloud drifting across the upper slope and the steam haloing the vent.
    _volcWisp(
      c,
      Offset(x + half * .05, py(.2)),
      half * .46,
      hh * .018,
      tilt: hh * .004,
      alpha: .85,
    );
    _volcWisp(
      c,
      Offset(x - half * .3, py(.44)),
      half * .36,
      hh * .013,
      tilt: -hh * .003,
      alpha: .6,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(x + cr * .25, top - hh * .012),
        width: cr * 5,
        height: cr * 2.2,
      ),
      const Color(0xfffff0e4),
      .5,
    );
  }

  /// Iztaccihuatl, the Sleeping Woman: a long glaciated ridge whose four
  /// summits are her head, chest, knees and feet, with the light and shade
  /// wedges of each spur running down to the foot.
  static void _volcRidge(
    Canvas c,
    double x,
    double top,
    double half,
    double base,
  ) {
    final hh = base - top;
    // She stands a little farther off than Popocatepetl, so she is hazier.
    final shade = _hazed(const Color(0xff5f5390), .27);
    final lit = _hazed(const Color(0xffce8486), .27);
    final dark = _hazed(const Color(0xff3a2e54), .32);
    final snowLit = _hazed(const Color(0xffffeedc), .1);
    final snowShade = _hazed(const Color(0xffb0aade), .2);
    double iL(double d) => _volcFlank(d, .46, .2, .42) * half;
    double iR(double d) => _volcFlank(d, .49, .17, .3) * half;
    double py(double d) => top + hh * d;
    double px(double a, double d) => x + a * (a < 0 ? iL(d) : iR(d));
    // Crest points, with a touch of roughness.
    final cu = <double>[], cd = <double>[];
    for (var i = 0; i < _volcCrest.length; i += 2) {
      cu.add(x + _volcCrest[i] * half);
      cd.add(
        top +
            hh *
                (_volcCrest[i + 1] +
                    (i > 0 ? .006 * (Sketch.hash(i + 70) - .5) : 0.0)),
      );
    }
    const fd = <double>[.28, .36, .46, .57, .68, .79, .9];

    // A gully: from ([uS] of the half-width, depth [dS]) fanning out to
    // [aE] of the local width at the foot, [w0] growing to [w1] wide.
    void rib(
      Path p,
      double uS,
      double dS,
      double aE,
      double w0,
      double w1, {
      double wig = 0.0,
      double ph = 0.0,
      bool cap = false,
    }) {
      const n = 6;
      final l = <Offset>[], r = <Offset>[];
      var end = Offset.zero;
      var g = 0.0;
      for (var i = 0; i <= n; i++) {
        final s = i / n;
        final d = dS + (1 - dS) * s;
        final u =
            uS * half * (1 - s) + aE * (aE < 0 ? iL(d) : iR(d)) * s;
        final cx = x + u + wig * math.sin(s * 5 + ph) * s;
        g = w0 + (w1 - w0) * s;
        l.add(Offset(cx - g, py(d)));
        r.add(Offset(cx + g, py(d)));
        end = Offset(cx, py(d));
      }
      p.moveTo(l[0].dx, l[0].dy);
      for (var i = 1; i <= n; i++) {
        p.lineTo(l[i].dx, l[i].dy);
      }
      for (var i = n; i >= 0; i--) {
        p.lineTo(r[i].dx, r[i].dy);
      }
      p.close();
      if (cap) {
        p.addOval(Rect.fromCenter(center: end, width: g * 2.4, height: g * 1.8));
      }
    }

    // The whole ridge, lit; then shade wedges under every right-facing
    // slope, each bounded by a spur below its summit and the gully below the
    // next saddle.
    final sil = Path()..moveTo(x - iL(1), base);
    for (var i = fd.length - 1; i >= 0; i--) {
      sil.lineTo(x - iL(fd[i]), py(fd[i]));
    }
    for (var i = 0; i < cu.length; i++) {
      sil.lineTo(cu[i], cd[i]);
    }
    for (final d in fd) {
      sil.lineTo(x + iR(d), py(d));
    }
    sil
      ..lineTo(x + iR(1), base)
      ..close();
    c.drawPath(sil, Paint()..color = lit);

    final shadeArea = Path();
    for (final (a, b, spur, gully) in const <(int, int, double, double)>[
      (4, 8, -.76, -.5),
      (13, 18, -.03, .42),
      (21, 24, .6, .72),
    ]) {
      shadeArea.moveTo(cu[a], cd[a]);
      for (var i = a + 1; i <= b; i++) {
        shadeArea.lineTo(cu[i], cd[i]);
      }
      shadeArea
        ..lineTo(x + gully * half, base)
        ..lineTo(x + spur * half, base)
        ..close();
    }
    shadeArea
      ..moveTo(cu[26], cd[26])
      ..lineTo(cu[27], cd[27])
      ..lineTo(cu[28], cd[28]);
    for (final d in fd) {
      shadeArea.lineTo(x + iR(d), py(d));
    }
    shadeArea
      ..lineTo(x + iR(1), base)
      ..lineTo(x + .78 * half, base)
      ..close();
    c.drawPath(shadeArea, Paint()..color = shade);

    // Gullies on the lit faces, and in the shade wedges.
    final gl = Path(), gs = Path(), hi = Path();
    for (final (uS, dS, aE, w1) in const <(double, double, double, double)>[
      (-.41, .13, -.86, .02),
      (-.42, .2, -.95, .012),
      (-.17, .14, -.42, .02),
      (-.12, .07, -.25, .017),
      (-.07, .03, -.12, .012),
      (.235, .09, .52, .016),
      (.26, .06, .58, .014),
    ]) {
      rib(gl, uS, dS, aE, half * .002, half * w1, wig: half * .02, ph: uS * 11);
      rib(
        hi,
        uS + .03,
        dS,
        aE + .03,
        half * .001,
        half * .006,
        wig: half * .02,
        ph: uS * 11,
      );
    }
    for (final (uS, dS, aE, w1) in const <(double, double, double, double)>[
      (-.3, .1, -.6, .016),
      (.06, .03, .18, .014),
      (.11, .08, .3, .016),
      (.32, .08, .66, .014),
      (.35, .12, .68, .012),
      (.45, .15, .8, .016),
      (.47, .24, .93, .014),
    ]) {
      rib(
        gs,
        uS,
        dS,
        aE,
        half * .002,
        half * w1,
        wig: half * .02,
        ph: uS * 11 + 2,
      );
    }
    c.drawPath(gl, Paint()..color = Sketch.fade(shade, .5));
    c.drawPath(gs, Paint()..color = Sketch.fade(dark, .45));
    c.drawPath(hi, Paint()..color = Sketch.fade(const Color(0xffffd9b4), .28));

    // Strata low on the flanks.
    final strata = Path();
    for (final (d, a0, a1, sag) in const <(double, double, double, double)>[
      (.37, -.9, -.4, .011),
      (.43, .05, .85, .011),
      (.49, -.85, .1, .011),
      (.55, -.4, .9, .011),
      (.62, -.9, -.1, .01),
    ]) {
      final y = py(d), x0 = px(a0, d), x1 = px(a1, d);
      strata
        ..moveTo(x0, y)
        ..quadraticBezierTo((x0 + x1) / 2, y + hh * sag * 2, x1, y);
    }
    final sw = math.max(.7, hh * .0035);
    c.drawPath(
      strata,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..color = Sketch.fade(dark, .28),
    );
    c.save();
    c.translate(0, sw * 1.4);
    c.drawPath(
      strata,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..color = Sketch.fade(const Color(0xffffd7b0), .15),
    );
    c.restore();

    // An old flow of dark rock down the lit flank.
    final flow = Path();
    rib(
      flow,
      -.36,
      .3,
      -.7,
      half * .004,
      half * .022,
      wig: -half * .03,
      ph: 1.4,
      cap: true,
    );
    c.drawPath(
      flow,
      Paint()..color = Sketch.fade(_hazed(const Color(0xff4a2c48), .28), .45),
    );

    // Sun-rim along the left flank and crest.
    final rimLight = Path()
      ..moveTo(x - iL(.36), py(.36))
      ..lineTo(x - iL(.28), py(.28));
    for (var i = 0; i < cu.length; i++) {
      rimLight.lineTo(cu[i], cd[i]);
    }
    c.drawPath(
      rimLight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, hh * .004)
        ..color = Sketch.fade(const Color(0xffffe2b0), .45),
    );

    // Glaciers: tongues of ice fill the couloirs below the saddles.
    const edge = <double>[
      -.44, .38, -.38, .3, -.33, .43, -.28, .27, -.235, .33, -.21, .47, //
      -.16, .3, -.11, .26, -.06, .35, -.02, .49, .04, .3, .09, .25, //
      .14, .36, .19, .52, .245, .3, .29, .26, .33, .4, .375, .56, //
      .42, .33, .47, .4,
    ];
    final snow = Path()..moveTo(x - iL(.31), py(.31));
    snow.lineTo(x - iL(.28), py(.28));
    for (var i = 0; i < cu.length; i++) {
      snow.lineTo(cu[i], cd[i]);
    }
    snow
      ..lineTo(x + iR(.28), py(.28))
      ..lineTo(x + iR(.36), py(.36));
    for (var i = edge.length - 2; i >= 0; i -= 2) {
      final u = edge[i] * half, d = edge[i + 1];
      snow.lineTo(x + u, py(d));
      if (i > 0) {
        final u2 = edge[i - 2] * half, d2 = edge[i - 1];
        final md = (d + d2) / 2 + .03 * (Sketch.hash(i + 30) - .5);
        snow.lineTo(x + (u + u2) / 2, py(md));
      }
    }
    snow.close();
    c.drawPath(snow, Paint()..color = snowLit);
    c.save();
    c.clipPath(snow);
    c.drawPath(shadeArea, Paint()..color = snowShade);
    c.drawPath(gl, Paint()..color = Sketch.fade(snowShade, .8));
    c.drawPath(
      gs,
      Paint()..color = Sketch.fade(const Color(0xff8f86c4), .5),
    );
    c.drawPath(hi, Paint()..color = Sketch.fade(const Color(0xfffff8ee), .7));
    c.restore();

    // Dark rock breaking through the snow along the crest.
    final crags = Path();
    for (final (u, d) in const <(double, double)>[
      (-.36, .115),
      (-.12, .09),
      (.1, .14),
      (.3, .1),
      (.45, .16),
    ]) {
      crags
        ..moveTo(x + u * half, py(d))
        ..lineTo(x + (u - .03) * half, py(d + .05))
        ..lineTo(x + (u + .03) * half, py(d + .045))
        ..close();
    }
    c.drawPath(crags, Paint()..color = Sketch.fade(dark, .55));

    // Aerial perspective, then clouds catching the light along the ridge.
    c.drawPath(
      sil,
      Paint()
        ..shader = Gradient.linear(
          Offset(x, top + hh * .2),
          Offset(x, top + hh * .85),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .68)],
        ),
    );
    _volcWisp(
      c,
      Offset(x - half * .2, py(.17)),
      half * .5,
      hh * .017,
      tilt: hh * .004,
      alpha: .8,
    );
    _volcWisp(
      c,
      Offset(x + half * .34, py(.12)),
      half * .3,
      hh * .012,
      tilt: -hh * .003,
      alpha: .7,
    );
  }

  /// The Sleeping Woman's crest from her head (left) to her feet, as pairs
  /// of (fraction of the half-width, fraction of the height below the top):
  /// head, neck, chest (the summit), waist, knees, shins and feet.
  static const _volcCrest = <double>[
    -.46, .2, -.43, .14, -.4, .105, -.37, .085, -.34, .078, -.31, .09, //
    -.28, .125, -.25, .16, -.22, .185, -.19, .17, -.15, .11, -.1, .05, //
    -.05, .012, -.01, 0.0, .03, .008, .07, .035, .11, .08, .15, .125, //
    .19, .13, .22, .1, .25, .06, .28, .045, .31, .06, .34, .1, //
    .37, .14, .4, .125, .43, .1, .46, .115, .49, .17,
  ];

  static final _volcSteam = Paint();

  /// Popocatepetl's plume: steam welling out of the crater and streaming
  /// downwind, lit on its sunward side. The puffs cycle on the region clock
  /// and hold a still pose in Reduced Motion. Geometry mirrors the cone drawn
  /// in [features].
  static void _volcPlume(Canvas c, SceneFrame f) {
    final w = f.w, h = f.h, k = _fit(f.size);
    final x = w * .76, top = h * (.7 - .4 * k), half = h * .36 * k;
    final hh = h * .7 - top;
    final vent = Offset(x + half * .03, top + hh * .02);
    const n = 12;
    // Streaming towards the sun keeps the plume on screen beside the right
    // edge of a portrait viewport, over the sky above the Sleeping Woman.
    final reach = hh * .55, lean = -half * .5;
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < n; i++) {
        final p = (f.clock * .03 + i / n) % 1.0;
        final r = half * (.03 + .06 * p) * (.85 + .3 * Sketch.hash(i + 200));
        final a = .62 * math.min(1.0, p * 8) * (1 - p * p);
        final sway = half * .03 * math.sin(f.clock * .35 + i * 1.7) * p;
        final at = Offset(vent.dx + lean * p * p + sway, vent.dy - reach * p);
        final stretch = 1 + 1.1 * p;
        if (pass == 0) {
          _volcSteam.color = Sketch.fade(
            Sketch.mix(const Color(0xffb7a0c8), const Color(0xffe8b8b0), p),
            a * .9,
          );
          c.drawOval(
            Rect.fromCenter(
              center: at + Offset(r * .25, r * .2),
              width: r * 2 * stretch,
              height: r * 1.9,
            ),
            _volcSteam,
          );
        } else {
          _volcSteam.color = Sketch.fade(
            Sketch.mix(const Color(0xfffff2e6), const Color(0xffffd8c0), p),
            a,
          );
          c.drawOval(
            Rect.fromCenter(
              center: at + Offset(-r * .22, -r * .18),
              width: r * 1.6 * stretch,
              height: r * 1.5,
            ),
            _volcSteam,
          );
        }
      }
    }
  }

  /// A five-tier temple pyramid of talud-tablero terraces: a sloped foot under
  /// a vertical panel and cornice, the panels painted or friezed, each tier
  /// stepping back. The great stair climbs its front between sloping alfardas
  /// with carved serpent heads at the foot, up to stucco shrines crowned with
  /// roof combs, banners and smoking braziers. [twin] gives it the double
  /// stair and the two shrines of the Templo Mayor, blue for Tlaloc and red
  /// for Huitzilopochtli, with skull racks (tzompantli) at its foot; otherwise
  /// it has one shrine, blue or, for [redShrine], red. Light comes from the
  /// left, so every side wall and the right-hand alfardas are in shade.
  /// [ground] is the terrain height at the stair foot.
  static void _pyramid(
    Canvas c,
    Offset base,
    double s, {
    bool twin = false,
    bool redShrine = false,
    double? ground,
  }) {
    final cx = base.dx, by = base.dy;
    final gy = ground ?? by - s * .07;
    final tier = s * _pyrTier;
    final topY = by - _pyrTiers * tier;
    final rich = s > _pyrRich;
    final stone = _hazed(const Color(0xffd3b380), .2);
    final lit = _hazed(const Color(0xffe8cd96), .2);
    final crest = _hazed(const Color(0xfff3e2b6), .18);
    final shade = _hazed(const Color(0xffa07d5c), .2);
    final deep = _hazed(const Color(0xff6e5240), .24);
    final dark = _hazed(const Color(0xff4a382e), .25);
    final blue = _hazed(const Color(0xff2384cc), .2);
    final red = _hazed(const Color(0xffc4453a), .2);
    final bone = _hazed(const Color(0xfff0e6cf), .15);
    final panel = Sketch.mix(stone, shade, .55);
    final paintL = twin || !redShrine ? blue : red;
    final paintR = twin ? red : paintL;
    final p = Paint();
    final ln = Paint()..style = PaintingStyle.stroke;
    final lw = math.max(.7, s * .005);

    // A footing carries the base tier down into the terrain so it never
    // hovers over a dip in the ridge.
    final foot = s * .62;
    p.color = lit;
    c.drawRect(Rect.fromLTRB(cx - foot, by, cx + foot, by + s * .12), p);
    p.color = shade;
    c.drawRect(Rect.fromLTRB(cx + foot, by, cx + foot * 1.11, by + s * .12), p);

    final rimLit = Path(), rimDark = Path();
    final fleckLit = Path(), fleckDark = Path(), streaks = Path();
    for (var i = 0; i < _pyrTiers; i++) {
      final hb = s * .62 * (1 - i * .16);
      final y0 = by - i * tier, y1 = y0 - tier;
      final yt = y0 - s * .07, yc = y1 + s * .014;
      final ht = hb - s * .022, hp = hb - s * .014, hc = hb - s * .006;
      final d = hb * .11;
      // The side walls, turned from the sun.
      p.color = shade;
      c.drawPath(
        Sketch.poly([cx + hb, y0, cx + hb + d, y0, cx + ht + d, yt, cx + ht, yt]),
        p,
      );
      c.drawRect(Rect.fromLTRB(cx + hp, yc, cx + hp + d, yt), p);
      c.drawRect(Rect.fromLTRB(cx + hc, y1, cx + hc + d, yc), p);
      // The sloping talud faces up into the light, the vertical tablero above
      // it is a shade duller, and a cornice caps the tier.
      p.color = lit;
      c.drawPath(
        Sketch.poly([cx - hb, y0, cx + hb, y0, cx + ht, yt, cx - ht, yt]),
        p,
      );
      p.color = stone;
      c.drawRect(Rect.fromLTRB(cx - hp, yc, cx + hp, yt), p);
      p.color = lit;
      c.drawRect(Rect.fromLTRB(cx - hc, y1, cx + hc, yc), p);
      // A recessed panel in the tablero: painted on every second tier (blue
      // for Tlaloc's half, red for Huitzilopochtli's), otherwise plain
      // stucco with a row of dentils.
      final m = s * .02;
      final pt = yc + s * .005, pb = yt - s * .005;
      if (i.isOdd) {
        p.color = paintL;
        c.drawRect(Rect.fromLTRB(cx - hp + m, pt, cx, pb), p);
        p.color = paintR;
        c.drawRect(Rect.fromLTRB(cx, pt, cx + hp - m, pb), p);
      } else {
        p.color = panel;
        c.drawRect(Rect.fromLTRB(cx - hp + m, pt, cx + hp - m, pb), p);
      }
      // A core shadow toward the turned edge, the cornice's shadow on the
      // tablero and the tablero's on the talud.
      p.color = Sketch.fade(shade, .28);
      c.drawPath(
        Sketch.poly([cx + hb * .86, y0, cx + hb, y0, cx + ht, yt, cx + ht * .86, yt]),
        p,
      );
      c.drawRect(Rect.fromLTRB(cx + hp * .84, yc, cx + hp, yt), p);
      p.color = Sketch.fade(deep, .5);
      c.drawRect(Rect.fromLTRB(cx - hp, yc, cx + hp, yc + s * .007), p);
      c.drawRect(Rect.fromLTRB(cx - ht, yt, cx + ht, yt + s * .005), p);
      if (i.isEven || rich) {
        final mid = (pt + pb) / 2, ph = pb - pt;
        final cells = math.max(
          6,
          ((hp - m) * 2 / (s * (i.isOdd ? .03 : .036))).floor(),
        );
        final cell = (hp - m) * 2 / cells;
        final frieze = Path();
        for (var j = 0; j < cells; j++) {
          final ex = cx - hp + m + cell * (j + .5);
          if (i.isOdd) {
            frieze.addOval(
              Rect.fromCenter(center: Offset(ex, mid), width: ph * .3, height: ph * .3),
            );
          } else {
            frieze.addRect(
              Rect.fromCenter(center: Offset(ex, mid), width: cell * .44, height: ph * .4),
            );
          }
        }
        p.color = i.isOdd ? Sketch.fade(crest, .8) : Sketch.fade(deep, .6);
        c.drawPath(frieze, p);
      }
      // Sunlit edges to the left, seams to the right.
      rimLit
        ..moveTo(cx - hc, y1)
        ..lineTo(cx + hc, y1)
        ..moveTo(cx - hb, y0)
        ..lineTo(cx - ht, yt)
        ..moveTo(cx - hp, yt)
        ..lineTo(cx - hp, yc);
      rimDark
        ..moveTo(cx + hb, y0)
        ..lineTo(cx + ht, yt)
        ..moveTo(cx + hp, yt)
        ..lineTo(cx + hp, yc);
      if (rich) {
        // Flecks of chipped and re-limed stucco on the talud, and rain
        // streaks running down from the cornice.
        for (var j = 0; j < 7; j++) {
          final r1 = Sketch.hash(i * 37 + j * 11 + 5);
          final r2 = Sketch.hash(i * 23 + j * 7 + 91);
          final r3 = Sketch.hash(i * 19 + j * 3 + 233);
          final ew = s * (.005 + .012 * r3);
          (j.isEven ? fleckLit : fleckDark).addOval(
            Rect.fromCenter(
              center: Offset(
                cx + (r1 * 2 - 1) * ht * .9,
                yt + (y0 - yt) * (.12 + .76 * r2),
              ),
              width: ew,
              height: ew * .4,
            ),
          );
        }
        for (var j = 0; j < 3; j++) {
          final sx =
              cx + (Sketch.hash(i * 29 + j * 13 + 400) * 2 - 1) * (hp - m);
          streaks
            ..moveTo(sx, yc + s * .006)
            ..lineTo(
              sx + s * .002,
              yc + s * (.02 + .02 * Sketch.hash(i * 5 + j + 500)),
            );
        }
      }
    }
    ln.strokeWidth = lw;
    ln.color = crest;
    c.drawPath(rimLit, ln);
    ln.color = Sketch.fade(deep, .55);
    c.drawPath(rimDark, ln);
    if (rich) {
      p.color = Sketch.fade(crest, .55);
      c.drawPath(fleckLit, p);
      p.color = Sketch.fade(deep, .3);
      c.drawPath(fleckDark, p);
      ln.color = Sketch.fade(deep, .22);
      ln.strokeWidth = math.max(.6, s * .003);
      c.drawPath(streaks, ln);
    }

    // Skull racks stand on low platforms either side of the great stair.
    if (twin) {
      _pyrRack(c, cx - s * .56, cx - s * .3, gy, by, s, stone, crest, shade, dark, bone, rich);
      _pyrRack(c, cx + s * .3, cx + s * .56, gy, by, s, stone, crest, shade, dark, bone, rich);
    }

    // The stair narrows a little as it climbs; every step has a lit tread
    // and a shadow under its nosing.
    final sb = twin ? s * .225 : s * .12, st = twin ? s * .18 : s * .095;
    final rise = by - topY;
    double half(double y) => st + (sb - st) * (y - topY) / rise;
    p.color = crest;
    c.drawPath(
      Sketch.poly([cx - sb, by, cx + sb, by, cx + st, topY, cx - st, topY]),
      p,
    );
    final rows = math.max(10, (rise / math.max(s * .026, 4.5)).round());
    final risers = Path(), treads = Path();
    for (var k = 1; k < rows; k++) {
      final y = by - rise * k / rows;
      final hw = half(y);
      risers
        ..moveTo(cx - hw, y)
        ..lineTo(cx + hw, y);
      treads
        ..moveTo(cx - hw, y - lw)
        ..lineTo(cx + hw, y - lw);
    }
    ln.strokeWidth = lw;
    ln.color = Sketch.fade(deep, .5);
    c.drawPath(risers, ln);
    ln.color = Sketch.fade(_hazed(const Color(0xfffff6dc), .1), .9);
    c.drawPath(treads, ln);

    // Alfardas: sloping balustrades down both edges of the stair (and, on the
    // double stair, a broad one between the flights), casting shadow across
    // the flights to their right.
    final aw0 = s * .028, aw1 = s * .022;
    final cw0 = s * .046, cw1 = s * .035;
    final sh0 = s * .016, sh1 = s * .012;
    p.color = Sketch.fade(deep, .4);
    c.drawPath(
      Sketch.poly([
        cx - sb + aw0, by,
        cx - sb + aw0 + sh0, by,
        cx - st + aw1 + sh1, topY,
        cx - st + aw1, topY,
      ]),
      p,
    );
    if (twin) {
      c.drawPath(
        Sketch.poly([
          cx + cw0, by,
          cx + cw0 + sh0, by,
          cx + cw1 + sh1, topY,
          cx + cw1, topY,
        ]),
        p,
      );
    }
    p.color = twin ? Sketch.mix(blue, stone, .45) : stone;
    c.drawPath(
      Sketch.poly([cx - sb, by, cx - sb + aw0, by, cx - st + aw1, topY, cx - st, topY]),
      p,
    );
    p.color = twin ? Sketch.mix(red, shade, .5) : Sketch.mix(stone, shade, .55);
    c.drawPath(
      Sketch.poly([cx + sb - aw0, by, cx + sb, by, cx + st, topY, cx + st - aw1, topY]),
      p,
    );
    p.color = shade;
    c.drawPath(
      Sketch.poly([
        cx + sb, by,
        cx + sb + s * .02, by,
        cx + st + s * .014, topY,
        cx + st, topY,
      ]),
      p,
    );
    if (twin) {
      p.color = stone;
      c.drawPath(
        Sketch.poly([cx - cw0, by, cx + cw0, by, cx + cw1, topY, cx - cw1, topY]),
        p,
      );
      p.color = shade;
      c.drawPath(
        Sketch.poly([cx, by, cx + cw0, by, cx + cw1, topY, cx, topY]),
        p,
      );
    }
    ln.strokeWidth = lw;
    ln.color = crest;
    c.drawLine(Offset(cx - sb, by), Offset(cx - st, topY), ln);
    if (twin) c.drawLine(Offset(cx - cw0, by), Offset(cx - cw1, topY), ln);
    ln.color = Sketch.fade(deep, .6);
    c.drawLine(Offset(cx - sb + aw0, by), Offset(cx - st + aw1, topY), ln);
    c.drawLine(Offset(cx + sb - aw0, by), Offset(cx + st - aw1, topY), ln);
    if (twin) c.drawLine(Offset(cx + cw0, by), Offset(cx + cw1, topY), ln);

    // Serpent heads guard the foot of each alfarda.
    final serp = _hazed(const Color(0xff62534a), .22);
    final serpLit = _hazed(const Color(0xff8a7663), .2);
    final serpShade = Sketch.mix(serp, dark, .35);
    final mouth = Sketch.mix(red, dark, .45);
    final jade = _hazed(const Color(0xff2f9a6a), .2);
    final headW = twin ? s * .058 : s * .05;
    final bottom = gy + s * .004, neck = by + s * .01;
    _pyrSerpent(c, cx - sb + aw0 / 2, bottom, neck, headW, serp, serpLit, bone, mouth, jade);
    _pyrSerpent(c, cx + sb - aw0 / 2, bottom, neck, headW, serpShade, serp, bone, mouth, jade);
    if (twin) {
      _pyrSerpent(c, cx, bottom, neck, headW * 1.25, serp, serpLit, bone, mouth, jade);
    }

    // The shrines: the double stair's two flights lead to Tlaloc's on the
    // left and Huitzilopochtli's on the right.
    if (twin) {
      final tw = s * .085, th = s * .12, off = s * .11;
      _shrine(c, cx - off, topY, tw, th, s, stone, shade, dark, blue, tlaloc: true);
      _shrine(c, cx + off, topY, tw, th, s, stone, shade, dark, red);
    } else {
      _shrine(
        c,
        cx,
        topY,
        s * .17,
        s * .13,
        s,
        stone,
        shade,
        dark,
        paintL,
        tlaloc: !redShrine,
      );
    }
    final pole = twin ? s * .222 : s * .205;
    _pyrBanner(c, cx - pole, topY, s * .27, s, paintL, dark, crest);
    _pyrBanner(c, cx + pole, topY, s * .27, s, paintR, dark, crest);
    for (final bx in _pyrBraziers(twin)) {
      _pyrBrazier(c, cx + bx * s, topY, s, dark, deep, crest);
    }
  }

  /// Pixel size of a pyramid above which the fine stucco and painted detail
  /// is drawn.
  static const _pyrRich = 150.0;

  /// A pyramid tier's height as a fraction of its size, and the tier count.
  static const _pyrTier = .13, _pyrTiers = 5;

  /// Where the pyramids stand in the mid band: (x as a fraction of the width,
  /// size in viewport heights, twin shrines). The lesser temples come first
  /// so the great twin-shrined pyramid stands in front of them.
  static const _pyrSites = [(.14, .2, false), (.9, .17, false), (.5, .36, true)];

  /// How far a pyramid's footing sinks below the ridge, in viewport heights.
  static const _pyrSink = .012;

  /// Height of a brazier's fire bed above its platform, in units of the
  /// pyramid's size.
  static const _pyrBowl = .058;

  /// Base point of the pyramid at [fx] of the width, in mid-band coordinates.
  static Offset _pyrBase(RegionScene sc, double w, double h, double fx) {
    final x = w * fx;
    return Offset(x, sc.ridge(Depth.mid, x / h, 0) * h + h * _pyrSink);
  }

  /// Brazier positions on a pyramid's platform, in units of its size from the
  /// centre: one atop the middle alfarda of a twin pyramid, otherwise a pair
  /// flanking the shrine door.
  static List<double> _pyrBraziers(bool twin) =>
      twin ? const [0.0] : const [-.105, .105];

  static final _pyrFlame = Paint()..color = const Color(0xffffb23f);
  static final _pyrCore = Paint()..color = const Color(0xffffe9a0);
  static final _pyrPuff = Paint();
  static final _pyrFlamePath = Path();
  static final _pyrSmoke = Sketch.mix(const Color(0xff7a686e), _haze, .15);

  /// The moving fire of the platform braziers: a flickering flame and a slow
  /// column of smoke drifting off on the breeze. Reuses one path and paint,
  /// so a frame allocates nothing but colours.
  static void _pyrLive(RegionScene sc, Canvas c, SceneFrame f) {
    final w = f.w, h = f.h, k = _fit(f.size), t = f.clock;
    for (final (fx, sz, twin) in _pyrSites) {
      final s = h * sz * k;
      final base = _pyrBase(sc, w, h, fx);
      final topY = base.dy - _pyrTiers * s * _pyrTier;
      for (final bx in _pyrBraziers(twin)) {
        final seed = fx * 9 + bx * 5;
        final tip = Offset(base.dx + bx * s, topY - s * _pyrBowl);
        final flick = .8 + .2 * math.sin(t * 9 + seed * 7);
        final sway = math.sin(t * 5 + seed * 3) * s * .003;
        final fw = s * .011, fh = s * .036 * flick;
        _pyrFlamePath
          ..reset()
          ..moveTo(tip.dx - fw, tip.dy)
          ..quadraticBezierTo(
            tip.dx - fw * 1.1,
            tip.dy - fh * .5,
            tip.dx + sway,
            tip.dy - fh,
          )
          ..quadraticBezierTo(
            tip.dx + fw * 1.1,
            tip.dy - fh * .5,
            tip.dx + fw,
            tip.dy,
          )
          ..close();
        c.drawPath(_pyrFlamePath, _pyrFlame);
        c.drawOval(
          Rect.fromCenter(
            center: tip + Offset(sway * .4, -fh * .28),
            width: fw * .9,
            height: fh * .5,
          ),
          _pyrCore,
        );
        for (var j = 0; j < 9; j++) {
          final u = (t * .14 + j / 9 + seed) % 1.0;
          final alpha = .38 * (1 - u) * math.min(1.0, u * 5);
          final px =
              tip.dx + s * (.07 * u * u + .014 * math.sin(u * 6 + seed * 4 + t * .7));
          final py = tip.dy - fh * .6 - u * s * .3;
          _pyrPuff.color = Sketch.fade(_pyrSmoke, alpha);
          c.drawCircle(Offset(px, py), s * (.008 + .028 * u), _pyrPuff);
        }
      }
    }
  }

  /// A stucco shrine of half-width [tw] and wall height [th] on the platform
  /// at [topY]: a dais, a painted frieze band in [accent], a dark doorway, a
  /// projecting cornice, a sloped roof with stepped merlons and a stepped roof
  /// comb wearing the god's emblem (rain goggles for Tlaloc, a sun disc for
  /// Huitzilopochtli) under a plume. Light comes from the left, so the side
  /// wall on the right is in shade.
  static void _shrine(
    Canvas c,
    double x,
    double topY,
    double tw,
    double th,
    double s,
    Color stone,
    Color shade,
    Color dark,
    Color accent, {
    bool tlaloc = false,
  }) {
    final p = Paint();
    final ln = Paint()..style = PaintingStyle.stroke;
    final lit = Sketch.mix(stone, const Color(0xfff6e6bc), .4);
    final crest = Sketch.mix(stone, const Color(0xfffff3cf), .65);
    final deep = Sketch.mix(shade, dark, .5);
    final roof = Sketch.mix(accent, dark, .2);
    final accentShade = Sketch.mix(accent, dark, .45);
    final lw = math.max(.6, s * .004);
    final sd = tw * .26;
    final y0 = topY - s * .012, wallTop = y0 - th;

    // A low dais under the walls.
    p.color = lit;
    c.drawRect(Rect.fromLTRB(x - tw * 1.16, y0, x + tw * 1.16, topY), p);
    p.color = shade;
    c.drawRect(
      Rect.fromLTRB(x + tw * 1.16, y0, x + tw * 1.16 + sd * 1.1, topY),
      p,
    );

    // Stuccoed walls: lit front, a core shadow toward the right edge, and the
    // side wall turned from the sun.
    p.color = stone;
    c.drawRect(Rect.fromLTRB(x - tw, wallTop, x + tw, y0), p);
    p.color = Sketch.fade(shade, .3);
    c.drawRect(Rect.fromLTRB(x + tw * .72, wallTop, x + tw, y0), p);
    p.color = shade;
    c.drawRect(Rect.fromLTRB(x + tw, wallTop, x + tw + sd, y0), p);

    // The painted frieze band, edged in cream, with a row of small dentils.
    final bt = wallTop + th * .1, bb = wallTop + th * .36;
    p.color = accent;
    c.drawRect(Rect.fromLTRB(x - tw, bt, x + tw, bb), p);
    p.color = accentShade;
    c.drawRect(Rect.fromLTRB(x + tw, bt, x + tw + sd, bb), p);
    ln.strokeWidth = lw;
    ln.color = crest;
    c.drawLine(Offset(x - tw, bt), Offset(x + tw, bt), ln);
    c.drawLine(Offset(x - tw, bb), Offset(x + tw, bb), ln);
    if (s > _pyrRich) {
      final n = math.max(3, (tw * 2 / (s * .024)).floor());
      final cell = tw * 2 / n;
      final dentils = Path();
      for (var j = 0; j < n; j++) {
        dentils.addRect(
          Rect.fromCenter(
            center: Offset(x - tw + cell * (j + .5), (bt + bb) / 2),
            width: cell * .4,
            height: (bb - bt) * .4,
          ),
        );
      }
      p.color = Sketch.fade(crest, .75);
      c.drawPath(dentils, p);
    }

    // A dark doorway in a lit frame, with a glint of the fire inside.
    final dw = tw * .3;
    p.color = lit;
    c.drawRect(
      Rect.fromLTRB(x - dw * 1.4, y0 - th * .63, x + dw * 1.4, y0),
      p,
    );
    p.color = dark;
    c.drawRect(Rect.fromLTRB(x - dw, y0 - th * .55, x + dw, y0), p);
    p.color = _hazed(const Color(0xffffa544), .1);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x + dw * .15, y0 - th * .1),
        width: dw * .9,
        height: th * .14,
      ),
      p,
    );
    ln.color = Sketch.fade(deep, .6);
    c.drawLine(Offset(x + dw * 1.4, y0 - th * .63), Offset(x + dw * 1.4, y0), ln);
    ln.color = crest;
    c.drawLine(Offset(x - tw, wallTop), Offset(x - tw, y0), ln);

    // The cornice throws a shadow down the wall.
    p.color = Sketch.fade(deep, .55);
    c.drawRect(Rect.fromLTRB(x - tw, wallTop, x + tw, wallTop + s * .007), p);
    final ct = wallTop - s * .014;
    p.color = lit;
    c.drawRect(Rect.fromLTRB(x - tw * 1.16, ct, x + tw * 1.16, wallTop), p);
    p.color = shade;
    c.drawRect(
      Rect.fromLTRB(x + tw * 1.16, ct, x + tw * 1.16 + sd * 1.1, wallTop),
      p,
    );
    ln.color = crest;
    c.drawLine(Offset(x - tw * 1.16, ct), Offset(x + tw * 1.16, ct), ln);

    // A painted roof sloping in, with a stepped merlon at each end.
    final rt = ct - s * .026;
    p.color = roof;
    c.drawPath(
      Sketch.poly([
        x - tw * 1.06, ct,
        x + tw * 1.06, ct,
        x + tw * .92, rt,
        x - tw * .92, rt,
      ]),
      p,
    );
    p.color = accentShade;
    c.drawPath(
      Sketch.poly([
        x + tw * 1.06, ct,
        x + tw * 1.06 + sd, ct,
        x + tw * .92 + sd, rt,
        x + tw * .92, rt,
      ]),
      p,
    );
    final bw = math.max(tw * .11, s * .009), mh = s * .026;
    for (final side in const [-1.0, 1.0]) {
      final mx = x + side * tw * .8;
      p.color = side < 0 ? lit : stone;
      c.drawPath(
        Sketch.poly([
          mx - bw, rt,
          mx - bw, rt - mh * .5,
          mx - bw * .5, rt - mh * .5,
          mx - bw * .5, rt - mh,
          mx + bw * .5, rt - mh,
          mx + bw * .5, rt - mh * .5,
          mx + bw, rt - mh * .5,
          mx + bw, rt,
        ]),
        p,
      );
    }

    // The roof comb: three stepped slabs, banded and crowned in the shrine's
    // colour, the middle one carrying the god's emblem.
    const combs = [(.66, .04), (.5, .028), (.34, .022)];
    var top = rt;
    for (var i = 0; i < combs.length; i++) {
      final (k, hgt) = combs[i];
      final hw = tw * k, bottom = top, hp = s * hgt;
      top = bottom - hp;
      p.color = stone;
      c.drawRect(Rect.fromLTRB(x - hw, top, x + hw, bottom), p);
      p.color = shade;
      c.drawRect(Rect.fromLTRB(x + hw, top, x + hw + sd * k, bottom), p);
      if (i == 0) {
        p.color = accent;
        c.drawRect(
          Rect.fromLTRB(x - hw, top + hp * .3, x + hw, top + hp * .68),
          p,
        );
      } else if (i == 2) {
        p.color = accent;
        c.drawRect(Rect.fromLTRB(x - hw, top, x + hw, bottom), p);
      } else {
        final cy = (top + bottom) / 2, r = math.min(hp * .36, hw * .42);
        if (tlaloc) {
          for (final side in const [-1.0, 1.0]) {
            final e = Offset(x + side * hw * .48, cy);
            p.color = accent;
            c.drawCircle(e, r, p);
            p.color = crest;
            c.drawCircle(e, r * .62, p);
            p.color = dark;
            c.drawCircle(e, r * .28, p);
          }
        } else {
          final e = Offset(x, cy);
          p.color = accent;
          c.drawCircle(e, r, p);
          p.color = crest;
          c.drawCircle(e, r * .66, p);
          p.color = accent;
          c.drawCircle(e, r * .3, p);
        }
      }
      ln.color = crest;
      c.drawLine(Offset(x - hw, top), Offset(x + hw, top), ln);
    }

    // A fan of feathers rises from the crest.
    final plume = tlaloc
        ? [
            _hazed(const Color(0xff3a9a5a), .2),
            _hazed(const Color(0xff2fb59a), .2),
            _hazed(const Color(0xff3a9a5a), .2),
          ]
        : [
            _hazed(const Color(0xffd9402f), .2),
            _hazed(const Color(0xffe3a63a), .2),
            _hazed(const Color(0xffd9402f), .2),
          ];
    ln.strokeCap = StrokeCap.round;
    ln.strokeWidth = math.max(.9, s * .006);
    for (var i = 0; i < 5; i++) {
      final a = (i - 2) * .36;
      final len = s * (.046 - (i - 2).abs() * .008);
      ln.color = plume[i % 3];
      c.drawLine(
        Offset(x, top),
        Offset(x + math.sin(a) * len, top - math.cos(a) * len),
        ln,
      );
    }
  }

  /// A stone brazier on a pedestal standing on the platform at ([x], [y]),
  /// with the soft glow of its fire bed; the flame and smoke are drawn live.
  static void _pyrBrazier(
    Canvas c,
    double x,
    double y,
    double s,
    Color dark,
    Color deep,
    Color crest,
  ) {
    final p = Paint();
    Sketch.mist(
      c,
      Rect.fromCenter(
        center: Offset(x, y - s * _pyrBowl),
        width: s * .2,
        height: s * .2,
      ),
      const Color(0xffffb14a),
      .5,
    );
    p.color = dark;
    c.drawPath(
      Sketch.poly([
        x - s * .011, y,
        x + s * .011, y,
        x + s * .007, y - s * .03,
        x - s * .007, y - s * .03,
      ]),
      p,
    );
    p.color = deep;
    c.drawPath(
      Sketch.poly([
        x - s * .03, y - s * .052,
        x + s * .03, y - s * .052,
        x + s * .015, y - s * .03,
        x - s * .015, y - s * .03,
      ]),
      p,
    );
    p.color = crest;
    c.drawRect(
      Rect.fromLTRB(x - s * .03, y - s * .054, x + s * .03, y - s * .05),
      p,
    );
    p.color = const Color(0xffff8a2a);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x, y - s * .054),
        width: s * .05,
        height: s * .012,
      ),
      p,
    );
  }

  /// A pole planted at ([x], [y]) [height] tall, flying a swallow-tailed cloth
  /// on the breeze.
  static void _pyrBanner(
    Canvas c,
    double x,
    double y,
    double height,
    double s,
    Color cloth,
    Color pole,
    Color trim,
  ) {
    final ln = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.9, s * .005)
      ..color = pole;
    final top = y - height;
    c.drawLine(Offset(x, y), Offset(x, top - s * .008), ln);
    final w = s * .07, b = s * .04;
    final p = Paint()..color = cloth;
    c.drawPath(
      Sketch.poly([
        x, top,
        x + w * .3, top + s * .005,
        x + w * .62, top - s * .002,
        x + w, top + s * .004,
        x + w * .8, top + b * .5,
        x + w * .96, top + b + s * .003,
        x + w * .6, top + b - s * .002,
        x + w * .3, top + b + s * .004,
        x, top + b,
      ]),
      p,
    );
    ln.color = Sketch.fade(trim, .85);
    ln.strokeWidth = math.max(.6, s * .0035);
    c.drawLine(
      Offset(x + w * .08, top + b * .48),
      Offset(x + w * .68, top + b * .47),
      ln,
    );
    p.color = trim;
    c.drawCircle(Offset(x, top - s * .008), math.max(.8, s * .006), p);
  }

  /// A tzompantli: a low stone platform from [x0] to [x1] carrying a dark
  /// rack with two rows of skulls strung on it. [gy] is the ground height and
  /// [by] the pyramid's base, which the platform is carried down to.
  static void _pyrRack(
    Canvas c,
    double x0,
    double x1,
    double gy,
    double by,
    double s,
    Color stone,
    Color crest,
    Color shade,
    Color dark,
    Color bone,
    bool rich,
  ) {
    final p = Paint();
    final top = gy - s * .03, bottom = by + s * .02;
    p.color = stone;
    c.drawRect(Rect.fromLTRB(x0, top, x1, bottom), p);
    p.color = shade;
    c.drawRect(Rect.fromLTRB(x1, top, x1 + s * .02, bottom), p);
    p.color = crest;
    c.drawRect(
      Rect.fromLTRB(x0 - s * .006, top, x1 + s * .006, top + s * .008),
      p,
    );
    // The rack, its posts a shade lighter than the dark frame.
    final rackTop = top - s * .055;
    p.color = dark;
    c.drawRect(Rect.fromLTRB(x0 + s * .008, rackTop, x1 - s * .008, top), p);
    p.color = Sketch.mix(dark, stone, .3);
    for (final f in const [0.0, .5, 1.0]) {
      final px = x0 + s * .012 + (x1 - x0 - s * .024) * f;
      c.drawRect(
        Rect.fromLTRB(px - s * .004, rackTop - s * .006, px + s * .004, top),
        p,
      );
    }
    final skulls = Path(), sockets = Path();
    final r = s * .0068;
    final span = x1 - x0 - s * .04;
    final n = math.max(3, (span / (s * .019)).floor());
    final gap = span / n;
    for (var row = 0; row < 2; row++) {
      final y = top - s * (.016 + .022 * row);
      final count = row == 0 ? n + 1 : n;
      for (var j = 0; j < count; j++) {
        final sx = x0 + s * .02 + gap * (j + (row == 0 ? 0.0 : .5));
        skulls.addOval(Rect.fromCircle(center: Offset(sx, y), radius: r));
        if (rich) {
          sockets.addOval(
            Rect.fromCenter(
              center: Offset(sx, y + r * .15),
              width: r * 1.1,
              height: r * .5,
            ),
          );
        }
      }
    }
    p.color = bone;
    c.drawPath(skulls, p);
    if (rich) {
      p.color = dark;
      c.drawPath(sockets, p);
    }
  }

  /// A carved serpent head seen from the front at the foot of an alfarda: a
  /// stone block with ringed eyes and an open, fanged mouth. [bottom] is where
  /// it meets the ground and [neck] how far its block runs down into it.
  static void _pyrSerpent(
    Canvas c,
    double x,
    double bottom,
    double neck,
    double w,
    Color body,
    Color lit,
    Color bone,
    Color mouth,
    Color stripe,
  ) {
    final p = Paint();
    final hh = w * .82, top = bottom - hh;
    p.color = body;
    if (neck > bottom) {
      c.drawRect(
        Rect.fromLTRB(x - w * .45, bottom - w * .1, x + w * .45, neck),
        p,
      );
    }
    final r = Radius.circular(w * .3);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - w / 2, top, x + w / 2, bottom),
        r,
      ),
      p,
    );
    p.color = lit;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - w * .46, top + w * .05, x - w * .14, bottom - w * .08),
        Radius.circular(w * .18),
      ),
      p,
    );
    // A painted forehead stripe over a heavy brow, then small ringed eyes.
    final pupil = Sketch.mix(body, const Color(0xff000000), .55);
    p.color = stripe;
    c.drawRect(Rect.fromLTRB(x - w * .3, top + hh * .07, x + w * .3, top + hh * .17), p);
    p.color = pupil;
    c.drawRect(Rect.fromLTRB(x - w * .4, top + hh * .2, x + w * .4, top + hh * .3), p);
    for (final side in const [-1.0, 1.0]) {
      final e = Offset(x + side * w * .22, top + hh * .42);
      p.color = bone;
      c.drawCircle(e, w * .1, p);
      p.color = pupil;
      c.drawCircle(e, w * .05, p);
    }
    final mt = top + hh * .62;
    p.color = mouth;
    c.drawRect(Rect.fromLTRB(x - w * .38, mt, x + w * .38, bottom - hh * .06), p);
    p.color = bone;
    for (final side in const [-1.0, 1.0]) {
      c.drawPath(
        Sketch.poly([
          x + side * w * .3, mt,
          x + side * w * .16, mt,
          x + side * w * .23, mt + hh * .26,
        ]),
        p,
      );
    }
  }

  /// A carved stone totem: a stepped plinth under three stacked heads (jaguar,
  /// eagle and feathered serpent, in a different order on each [variant]),
  /// each with a painted glyph band and a lip that shades the face below,
  /// capped by a plumed brazier whose rim sits [_bowlTop] of [s] up. Recorded
  /// once in units of [s] (up is negative), lit from the upper left by the sun
  /// and from above by the fire; the flame itself is [_ttFire].
  static void _totem(Canvas c, Offset base, double s, {int variant = 0}) {
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(s, s);
    _ttPlinth(c);
    for (var i = 0; i < 3; i++) {
      _ttBlock(c, i, (i + variant) % 3, 7 + i * 31 + variant * 101);
    }
    _ttPlumes(c);
    _ttBowl(c);
    c.restore();
  }

  // Totem palette: sunlit, mid and shaded stone, carved recesses, painted
  // jade, red and ochre, moss and the fire's warm light.
  static const _ttLit = Color(0xffc4a980),
      _ttMid = Color(0xff927b62),
      _ttShade = Color(0xff5f4f43),
      _ttDeep = Color(0xff2c241e),
      _ttRimLit = Color(0xffd9c29c),
      _ttBone = Color(0xfff1e4c2),
      _ttOchre = Color(0xffe3a93b),
      _ttOchreDark = Color(0xffb87a26),
      _ttTeal = Color(0xff2fb5a0),
      _ttTealDark = Color(0xff1a7a76),
      _ttTealLit = Color(0xff69dcc4),
      _ttRed = Color(0xffc4453a),
      _ttMoss = Color(0xff5f8c3d),
      _ttMossLit = Color(0xff93b855),
      _ttMossDark = Color(0xff3f6a34),
      _ttFireLight = Color(0xffff9a3c);

  static Paint _ttFill(Color color) => Paint()..color = color;

  static Paint _ttInk(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static void _ttOval(Canvas c, double x, double y, double rx, double ry, Paint p) =>
      c.drawOval(Rect.fromLTRB(x - rx, y - ry, x + rx, y + ry), p);

  /// A left-to-right lit, mid, shaded stone fill over [x0]..[x1].
  static Paint _ttStone(double x0, double x1, [Color lit = _ttLit, Color mid = _ttMid, Color shade = _ttShade]) =>
      Paint()
        ..shader = Gradient.linear(Offset(x0, 0), Offset(x1, 0), [lit, mid, shade], const [0, .5, 1]);

  /// A vertical wash of [color] fading from [alpha] at [y0] to nothing at [y1].
  static Paint _ttWash(Color color, double alpha, double y0, double y1) =>
      Paint()
        ..shader = Gradient.linear(Offset(0, y0), Offset(0, y1), [
          Sketch.fade(color, alpha),
          Sketch.fade(color, 0),
        ]);

  /// The stepped footing. Its lower part hides behind the ridge.
  static void _ttPlinth(Canvas c) {
    c.drawRect(
      const Rect.fromLTRB(-.29, -.115, .29, .06),
      _ttStone(-.29, .29, _ttMid, const Color(0xff7d6c58), _ttShade),
    );
    c.drawRect(const Rect.fromLTRB(-.29, -.115, .29, -.106), _ttFill(Sketch.fade(_ttLit, .7)));
    c.drawRect(const Rect.fromLTRB(-.29, -.106, .29, -.1), _ttFill(Sketch.fade(_ttDeep, .3)));
    // Three carved step-fret panels along the front.
    for (final x in const [-.13, 0.0, .13]) {
      c.drawPath(
        Sketch.poly([
          x - .04, -.075, x + .04, -.075, x + .04, -.09, x + .02, -.09,
          x + .02, -.083, x - .02, -.083, x - .02, -.09, x - .04, -.09,
        ]),
        _ttFill(Sketch.fade(_ttDeep, .55)),
      );
    }
    c.drawRect(
      const Rect.fromLTRB(-.245, -.16, .245, -.115),
      _ttStone(-.245, .245, const Color(0xffa08c72), const Color(0xff85735f), const Color(0xff5f5044)),
    );
    c.drawRect(const Rect.fromLTRB(-.245, -.16, .245, -.152), _ttFill(Sketch.fade(_ttLit, .8)));
    // Shadow gathers where the stone meets the ground.
    c.drawRect(const Rect.fromLTRB(-.29, -.115, .29, .06), _ttWash(_ttDeep, .4, 0, -.115));
    final edge = _ttInk(Sketch.fade(_ttDeep, .55), .006);
    c.drawPath(
      Path()
        ..moveTo(-.29, -.115)
        ..lineTo(-.29, .06)
        ..lineTo(.29, .06)
        ..lineTo(.29, -.115)
        ..close(),
      edge,
    );
    c.drawRect(const Rect.fromLTRB(-.245, -.16, .245, -.115), edge);
    _ttMossClump(c, -.2, -.108, .05, 300);
  }

  /// One head block: stone, weathering, its face, the glyph band and lip, a
  /// crack, chipped edges and moss. [i] counts up from the plinth.
  static void _ttBlock(Canvas c, int i, int kind, int seed) {
    final hw = .2 - i * .015;
    final yb = -(.16 + i * .23), yt = yb - .23;
    const h = .23;
    // The outline is chipped at the corners and notched along the sides.
    final ch0 = .008 + .014 * Sketch.hash(seed + 1);
    final ch1 = .006 + .012 * Sketch.hash(seed + 2);
    final n1 = .006 + .008 * Sketch.hash(seed + 3);
    final n2 = .006 + .008 * Sketch.hash(seed + 4);
    final sil = Sketch.poly([
      -hw + ch0, yt, hw - ch1, yt, hw, yt + ch1,
      hw, yt + h * .38, hw - n1, yt + h * .44, hw, yt + h * .52,
      hw, yb, -hw, yb,
      -hw, yt + h * .66, -hw + n2, yt + h * .6, -hw, yt + h * .5,
      -hw, yt + ch0,
    ]);
    final body = Rect.fromLTRB(-hw, yt, hw, yb);
    c.save();
    c.clipPath(sil);
    c.drawRect(body, _ttStone(-hw, hw));
    // Uneven weathering: broad lighter and darker patches.
    for (var k = 0; k < 4; k++) {
      final rx = hw * (.25 + .3 * Sketch.hash(seed + 18 + k));
      _ttOval(
        c,
        (Sketch.hash(seed + 10 + k) * 2 - 1) * hw,
        yt + Sketch.hash(seed + 14 + k) * h,
        rx,
        rx * .45,
        _ttFill(Sketch.fade(k.isEven ? _ttDeep : _ttLit, .1)),
      );
    }
    // Warm spill from the fire, strongest on the top head.
    c.drawRect(body, _ttWash(_ttFireLight, const [.1, .22, .4][i], yt, yb));
    // Pitting and rain streaks.
    for (var k = 0; k < 14; k++) {
      c.drawCircle(
        Offset((Sketch.hash(seed + 50 + k) * 2 - 1) * hw, yt + Sketch.hash(seed + 70 + k) * h),
        .0035 + .0025 * Sketch.hash(seed + 90 + k),
        _ttFill(Sketch.fade(k % 3 == 0 ? _ttLit : _ttDeep, .22)),
      );
    }
    for (var k = 0; k < 3; k++) {
      final x = (Sketch.hash(seed + 120 + k) * 1.7 - .85) * hw;
      c.drawLine(
        Offset(x, yt + .05),
        Offset(x + .003, yt + .05 + h * (.45 + .3 * Sketch.hash(seed + 130 + k))),
        _ttInk(Sketch.fade(_ttDeep, .09), .006),
      );
    }
    switch (kind) {
      case 0:
        _ttJaguar(c, yt, hw);
      case 1:
        _ttEagle(c, yt);
      default:
        _ttSerpent(c, yt);
    }
    _ttLedge(c, yt, hw, kind);
    // Shadow thrown by the head above, a crack, and the sunlit left edge.
    c.drawRect(Rect.fromLTRB(-hw, yt, hw, yt + .034), _ttWash(_ttDeep, .5, yt, yt + .034));
    final cx = (Sketch.hash(seed + 150) - .5) * hw * 1.4;
    c.drawPath(
      Path()
        ..moveTo(cx, yt + .15)
        ..lineTo(cx + .012, yt + .175)
        ..lineTo(cx - .004, yt + .19)
        ..lineTo(cx + .01, yt + .225),
      _ttInk(Sketch.fade(_ttDeep, .55), .0045),
    );
    c.drawRect(Rect.fromLTRB(-hw, yt, -hw + .008, yb), _ttFill(Sketch.fade(const Color(0xffe8d2a8), .45)));
    c.drawRect(Rect.fromLTRB(hw - .012, yt, hw, yb), _ttFill(Sketch.fade(_ttDeep, .3)));
    c.drawRect(Rect.fromLTRB(-hw, yb - .014, hw, yb), _ttFill(Sketch.fade(_ttDeep, .28)));
    c.restore();
    // Fresh stone shows along the chipped corner; damp moss gathers low down.
    c.drawLine(
      Offset(-hw + ch0, yt),
      Offset(-hw, yt + ch0),
      _ttInk(Sketch.fade(const Color(0xfff0dcb4), .7), .005),
    );
    if (i == 0) {
      _ttMossClump(c, -.11, yb - .004, .05, seed + 200);
      _ttMossClump(c, .13, yb - .002, .035, seed + 210);
    } else {
      _ttMossClump(c, (Sketch.hash(seed + 220) - .5) * .25, yb - .001, .03, seed + 230);
    }
    c.drawPath(sil, _ttInk(Sketch.fade(_ttDeep, .6), .006));
  }

  /// A recessed eye: a lit lip below and right, a dark almond socket, a bone
  /// eyeball, then iris, pupil and a glint. [tilt] slants the corners.
  static void _ttEye(Canvas c, double x, double y, double w, double h, Color iris, {double tilt = 0}) {
    Path almond(double dx, double dy, double sw, double sh) => Path()
      ..moveTo(x - sw + dx, y + tilt * sw + dy)
      ..quadraticBezierTo(x + dx, y - sh * 1.35 + dy, x + sw + dx, y - tilt * sw + dy)
      ..quadraticBezierTo(x + dx, y + sh + dy, x - sw + dx, y + tilt * sw + dy)
      ..close();
    c.drawPath(almond(.004, .005, w, h), _ttFill(_ttRimLit));
    c.drawPath(almond(0, 0, w, h), _ttFill(_ttDeep));
    c.drawPath(almond(0, .002, w * .78, h * .68), _ttFill(_ttBone));
    c.drawCircle(Offset(x, y + .002), h * .5, _ttFill(iris));
    c.drawCircle(Offset(x, y + .002), h * .26, _ttFill(_ttDeep));
    c.drawCircle(Offset(x - h * .17, y - h * .12), h * .1, _ttFill(const Color(0xffffffff)));
  }

  /// A raised brow bar, shadowed below and lit on top.
  static void _ttBrow(Canvas c, double x0, double y0, double x1, double y1, double th) {
    c.drawLine(Offset(x0, y0 + .006), Offset(x1, y1 + .006), _ttInk(Sketch.fade(_ttDeep, .75), th));
    c.drawLine(Offset(x0, y0), Offset(x1, y1), _ttInk(_ttMid, th));
    c.drawLine(Offset(x0, y0 - th * .28), Offset(x1, y1 - th * .28), _ttInk(_ttLit, th * .34));
  }

  /// A bone fang hanging from [x], [y], its right half in shade.
  static void _ttFang(Canvas c, double x, double y, double w, double len) {
    c.drawPath(Sketch.poly([x - w, y, x + w, y, x + w * .1, y + len]), _ttFill(_ttBone));
    c.drawPath(
      Sketch.poly([x + w * .2, y, x + w, y, x + w * .1, y + len]),
      _ttFill(const Color(0xffcdbd95)),
    );
    c.drawLine(Offset(x - w, y), Offset(x + w * .1, y + len), _ttInk(Sketch.fade(_ttDeep, .55), .004));
  }

  /// A gaping mouth of half-width [w] whose upper lip sits at [y]: a lit lip
  /// under a dark lens.
  static void _ttMouth(Canvas c, double y, double w, double sag) {
    final mouth = Path()
      ..moveTo(-w, y)
      ..quadraticBezierTo(0, y - .012, w, y)
      ..quadraticBezierTo(0, y + sag, -w, y)
      ..close();
    c.drawPath(mouth, _ttFill(_ttRimLit));
    c.drawPath(mouth.shift(const Offset(0, -.003)), _ttFill(_ttDeep));
  }

  /// Scale marks: rows of small U strokes starting at [x], [y].
  static void _ttScales(Canvas c, double sx, double x, double y, int rows, int cols, double a) {
    final marks = Path();
    for (var row = 0; row < rows; row++) {
      for (var k = 0; k < cols; k++) {
        final px = sx * (x + k * .033 + (row % 2) * .016), py = y + row * .025;
        marks
          ..moveTo(px - .0155, py)
          ..quadraticBezierTo(px, py + .028, px + .0155, py);
      }
    }
    c.drawPath(marks, _ttInk(Sketch.fade(_ttDeep, a), .0055));
  }

  /// Jaguar: round ears, rosette spots, a heavy scowling brow, a flat nose and
  /// a snarl of fangs.
  static void _ttJaguar(Canvas c, double yt, double hw) {
    for (final sx in const [-1.0, 1.0]) {
      final ex = sx * (hw - .05);
      c.drawCircle(Offset(ex, yt + .06), .036, _ttFill(Sketch.fade(_ttDeep, .55)));
      c.drawCircle(Offset(ex, yt + .058), .031, _ttFill(sx > 0 ? _ttMid : _ttLit));
      c.drawCircle(Offset(ex, yt + .062), .017, _ttFill(const Color(0xff5c4838)));
      for (final (dx, dy, r) in const [
        (.128, .128, .0085),
        (.148, .155, .0075),
        (.118, .173, .008),
        (.152, .19, .0065),
      ]) {
        c.drawCircle(Offset(sx * dx, yt + dy), r, _ttFill(Sketch.fade(_ttDeep, .7)));
        c.drawCircle(Offset(sx * dx, yt + dy), r * .55, _ttFill(Sketch.fade(_ttMid, .9)));
      }
      _ttBrow(c, sx * .125, yt + .078, sx * .03, yt + .096, .019);
      _ttEye(c, sx * .075, yt + .112, .036, .026, _ttOchre, tilt: .12 * sx);
    }
    _ttOval(c, 0, yt + .17, .095, .048, _ttFill(Sketch.fade(_ttLit, .28)));
    c.drawPath(
      Sketch.poly([-.034, yt + .128, .034, yt + .128, .016, yt + .156, -.016, yt + .156]),
      _ttFill(Sketch.fade(_ttDeep, .7)),
    );
    c.drawPath(
      Sketch.poly([-.03, yt + .126, .03, yt + .126, .014, yt + .149, -.014, yt + .149]),
      _ttFill(const Color(0xff7a4032)),
    );
    c.drawPath(
      Sketch.poly([-.03, yt + .126, .03, yt + .126, .026, yt + .134, -.026, yt + .134]),
      _ttFill(const Color(0xffa8604a)),
    );
    _ttMouth(c, yt + .17, .1, .052);
    for (final sx in const [-1.0, 1.0]) {
      _ttFang(c, sx * .056, yt + .166, .014, .05);
      for (var k = 0; k < 2; k++) {
        _ttFang(c, sx * (.012 + k * .02), yt + .164, .0075, .02);
      }
    }
  }

  /// Eagle: a teal painted eye stripe, glaring yellow eyes under a heavy brow,
  /// feathered cheeks and a hooked ochre beak.
  static void _ttEagle(Canvas c, double yt) {
    c.drawRect(Rect.fromLTRB(-.15, yt + .088, .15, yt + .124), _ttFill(Sketch.fade(_ttTealDark, .85)));
    c.drawLine(Offset(-.15, yt + .088), Offset(.15, yt + .088), _ttInk(Sketch.fade(_ttTealLit, .55), .004));
    for (final sx in const [-1.0, 1.0]) {
      _ttBrow(c, sx * .125, yt + .066, sx * .04, yt + .09, .02);
      _ttEye(c, sx * .085, yt + .108, .034, .028, _ttOchre, tilt: .1 * sx);
      _ttScales(c, sx, .07, yt + .148, 3, 3, .4);
      // The gape line runs back from the beak under each cheek.
      c.drawPath(
        Path()
          ..moveTo(sx * .014, yt + .19)
          ..quadraticBezierTo(sx * .06, yt + .17, sx * .1, yt + .19),
        _ttInk(Sketch.fade(_ttDeep, .8), .006),
      );
    }
    final beak = Path()
      ..moveTo(-.026, yt + .072)
      ..cubicTo(-.04, yt + .1, -.045, yt + .15, -.018, yt + .197)
      ..quadraticBezierTo(-.005, yt + .217, 0, yt + .232)
      ..quadraticBezierTo(.005, yt + .217, .018, yt + .197)
      ..cubicTo(.045, yt + .15, .04, yt + .1, .026, yt + .072)
      ..quadraticBezierTo(0, yt + .06, -.026, yt + .072)
      ..close();
    c.drawPath(beak.shift(const Offset(.005, .005)), _ttFill(Sketch.fade(_ttDeep, .6)));
    c.drawPath(beak, _ttFill(const Color(0xffedb845)));
    c.drawPath(
      Path()
        ..moveTo(0, yt + .064)
        ..lineTo(.026, yt + .072)
        ..cubicTo(.04, yt + .1, .045, yt + .15, .018, yt + .197)
        ..quadraticBezierTo(.005, yt + .217, 0, yt + .232)
        ..close(),
      _ttFill(_ttOchreDark),
    );
    c.drawPath(
      Sketch.poly([-.018, yt + .197, .018, yt + .197, 0, yt + .234]),
      _ttFill(Sketch.fade(const Color(0xff7a4a1a), .8)),
    );
    c.drawPath(
      Path()
        ..moveTo(-.003, yt + .082)
        ..quadraticBezierTo(-.01, yt + .14, -.003, yt + .19),
      _ttInk(Sketch.fade(const Color(0xfffff0b0), .8), .005),
    );
    c.drawPath(beak, _ttInk(Sketch.fade(_ttDeep, .8), .005));
    for (final sx in const [-1.0, 1.0]) {
      _ttOval(c, sx * .011, yt + .098, .0055, .0038, _ttFill(_ttDeep));
    }
  }

  /// Feathered serpent: jade goggle eyes with slit pupils, curled nostrils, a
  /// broad snout, big fangs and a forked red tongue.
  static void _ttSerpent(Canvas c, double yt) {
    _ttOval(c, 0, yt + .17, .135, .062, _ttFill(Sketch.fade(_ttDeep, .5)));
    _ttOval(c, 0, yt + .167, .13, .058, _ttFill(_ttMid));
    _ttOval(c, -.03, yt + .15, .085, .036, _ttFill(Sketch.fade(_ttLit, .45)));
    for (final sx in const [-1.0, 1.0]) {
      final ex = sx * .085, ey = yt + .095;
      c.drawCircle(Offset(ex + .003, ey + .004), .04, _ttFill(_ttRimLit));
      c.drawCircle(Offset(ex, ey), .038, _ttFill(_ttTealDark));
      c.drawCircle(Offset(ex, ey), .03, _ttFill(_ttTeal));
      c.drawCircle(Offset(ex, ey), .022, _ttFill(_ttDeep));
      c.drawCircle(Offset(ex, ey), .0155, _ttFill(_ttOchre));
      _ttOval(c, ex, ey, .0042, .0125, _ttFill(_ttDeep));
      c.drawCircle(Offset(ex - .006, ey - .006), .003, _ttFill(const Color(0xffffffff)));
      c.drawPath(
        Path()
          ..moveTo(ex - .034, ey - .004)
          ..quadraticBezierTo(ex, ey - .06, ex + .034, ey - .004),
        _ttInk(Sketch.fade(_ttTealLit, .7), .004),
      );
      c.drawCircle(Offset(sx * .05, yt + .137), .0085, _ttFill(_ttDeep));
      c.drawPath(
        Path()
          ..moveTo(sx * .05, yt + .137)
          ..quadraticBezierTo(sx * .066, yt + .13, sx * .075, yt + .142),
        _ttInk(_ttDeep, .006),
      );
      _ttScales(c, sx, .1, yt + .135, 2, 2, .32);
    }
    _ttMouth(c, yt + .18, .12, .042);
    c.drawPath(
      Path()
        ..moveTo(-.011, yt + .198)
        ..lineTo(-.008, yt + .218)
        ..lineTo(-.026, yt + .238)
        ..lineTo(-.005, yt + .228)
        ..lineTo(0, yt + .222)
        ..lineTo(.005, yt + .228)
        ..lineTo(.026, yt + .238)
        ..lineTo(.008, yt + .218)
        ..lineTo(.011, yt + .198)
        ..close(),
      _ttFill(const Color(0xffd0483a)),
    );
    for (final sx in const [-1.0, 1.0]) {
      _ttFang(c, sx * .07, yt + .176, .0135, .048);
      for (var k = 0; k < 2; k++) {
        _ttFang(c, sx * (.03 + k * .018), yt + .172, .007, .02);
      }
    }
  }

  /// The band above a face: painted glyphs on a shadowed strip, then a
  /// protruding lip that shades the forehead. Jaguars wear stepped frets,
  /// eagles hanging feathers, serpents a scale zigzag.
  static void _ttLedge(Canvas c, double yt, double hw, int kind) {
    switch (kind) {
      case 0:
        {
          const n = 9;
          final w = 2 * hw / n;
          for (var k = 0; k < n; k++) {
            final x = -hw + k * w;
            c.drawRect(
              Rect.fromLTRB(x + w * .12, yt + .009, x + w * .88, yt + .026),
              _ttFill(Sketch.fade(_ttDeep, .55)),
            );
            c.drawRect(
              Rect.fromLTRB(x + w * .16, yt + .01, x + w * .84, yt + .022),
              _ttFill(k.isEven ? _ttRed : _ttTeal),
            );
            c.drawRect(
              Rect.fromLTRB(x + w * .3, yt + .013, x + w * .7, yt + .019),
              _ttFill(Sketch.fade(_ttDeep, .45)),
            );
          }
        }
      case 1:
        {
          const n = 8;
          final w = 2 * hw / n;
          for (var k = 0; k < n; k++) {
            final x = -hw + k * w;
            c.drawPath(
              Sketch.poly([x + w * .08, yt + .004, x + w * .92, yt + .004, x + w * .5, yt + .032]),
              _ttFill(Sketch.fade(_ttDeep, .5)),
            );
            c.drawPath(
              Sketch.poly([x + w * .16, yt + .004, x + w * .84, yt + .004, x + w * .5, yt + .027]),
              _ttFill(k.isEven ? _ttTeal : _ttOchre),
            );
          }
        }
      default:
        {
          const n = 10;
          final zig = Path()..moveTo(-hw, yt + .022);
          for (var k = 1; k <= n; k++) {
            zig.lineTo(-hw + k * 2 * hw / n, yt + (k.isOdd ? .012 : .026));
          }
          c.drawPath(zig, _ttInk(Sketch.fade(_ttDeep, .6), .011));
          c.drawPath(zig, _ttInk(_ttTeal, .0065));
        }
    }
    const wide = .012;
    c.drawRect(Rect.fromLTRB(-hw - wide, yt + .034, hw + wide, yt + .046), _ttFill(Sketch.fade(_ttDeep, .6)));
    c.drawRect(Rect.fromLTRB(-hw - wide, yt + .032, hw + wide, yt + .043), _ttFill(_ttMid));
    c.drawRect(Rect.fromLTRB(-hw - wide, yt + .032, hw + wide, yt + .036), _ttFill(Sketch.fade(_ttLit, .9)));
    c.drawRect(Rect.fromLTRB(-hw - wide, yt + .043, hw + wide, yt + .054), _ttFill(Sketch.fade(_ttDeep, .3)));
  }

  /// A low clump of moss with a flat underside and a bumpy crown, lit from
  /// the upper left.
  static void _ttMossClump(Canvas c, double x, double y, double r, int seed) {
    const n = 6;
    for (var pass = 0; pass < 2; pass++) {
      for (var k = 0; k < n; k++) {
        final u = (k + .5) / n * 2 - 1;
        final rr = r * (.28 + .22 * Sketch.hash(seed + k)) * (1 - .45 * u.abs());
        final cx = x + u * r * .9, cy = y - rr * .55;
        if (pass == 0) {
          c.drawCircle(Offset(cx, cy), rr, _ttFill(_ttMossDark));
          continue;
        }
        c.drawCircle(Offset(cx - rr * .22, cy - rr * .25), rr * .62, _ttFill(_ttMoss));
        if (Sketch.hash(seed + k + 5) > .35) {
          c.drawCircle(Offset(cx - rr * .35, cy - rr * .42), rr * .28, _ttFill(_ttMossLit));
        }
      }
    }
  }

  /// Quetzal plumes fanning out behind the bowl, arching up and drooping.
  static void _ttPlumes(Canvas c) {
    for (final sx in const [-1.0, 1.0]) {
      for (final (tx0, ty, cx0, cy, color, w) in const [
        (.4, -.86, .24, -1.0, _ttTealDark, .05),
        (.37, -.95, .2, -1.07, _ttTeal, .05),
        (.31, -1.02, .15, -1.11, _ttTealLit, .045),
        (.36, -.91, .22, -.98, _ttRed, .032),
        (.22, -1.04, .1, -1.12, _ttTeal, .04),
      ]) {
        final rx = sx * .1, ry = -.93;
        final tx = tx0 * sx, cx = cx0 * sx;
        final dx = tx - rx, dy = ty - ry;
        final len = math.sqrt(dx * dx + dy * dy);
        final nx = -dy / len, ny = dx / len;
        c.drawPath(
          Path()
            ..moveTo(rx, ry)
            ..quadraticBezierTo(cx + nx * w, cy + ny * w, tx, ty)
            ..quadraticBezierTo(cx - nx * w, cy - ny * w, rx, ry)
            ..close(),
          _ttFill(color),
        );
        c.drawPath(
          Path()
            ..moveTo(rx, ry)
            ..quadraticBezierTo(cx, cy, tx, ty),
          _ttInk(const Color(0x59ffffff), .004),
        );
        // Barb splits near the tip, kept inside the vane.
        for (final u in const [.62, .78]) {
          final mx = (1 - u) * (1 - u) * rx + 2 * (1 - u) * u * cx + u * u * tx;
          final my = (1 - u) * (1 - u) * ry + 2 * (1 - u) * u * cy + u * u * ty;
          final reach = 2 * u * (1 - u) * w * .7;
          c.drawLine(
            Offset(mx, my),
            Offset(mx + nx * reach + dx * .04, my + ny * reach + dy * .04),
            _ttInk(Sketch.fade(_ttDeep, .3), .0035),
          );
        }
      }
    }
  }

  /// The brazier: a collar with a sun-disc pendant, a flared carved bowl and
  /// a rim ringing glowing coals. The rim's centre is [_bowlTop] up.
  static void _ttBowl(Canvas c) {
    c.drawRect(const Rect.fromLTRB(-.15, -.885, .15, -.845), _ttStone(-.15, .15));
    c.drawRect(const Rect.fromLTRB(-.15, -.882, .15, -.874), _ttFill(_ttTeal));
    c.drawRect(const Rect.fromLTRB(-.15, -.856, .15, -.85), _ttFill(Sketch.fade(_ttDeep, .5)));
    c.drawRect(const Rect.fromLTRB(-.15, -.885, .15, -.845), _ttInk(Sketch.fade(_ttDeep, .5), .005));
    c.drawCircle(const Offset(0, -.866), .024, _ttFill(Sketch.fade(_ttDeep, .6)));
    c.drawCircle(const Offset(-.002, -.868), .02, _ttFill(_ttOchre));
    c.drawCircle(const Offset(0, -.866), .0095, _ttFill(_ttRed));
    final belly = Path()
      ..moveTo(-.15, -.885)
      ..cubicTo(-.17, -.94, -.235, -.955, -.235, -.99)
      ..cubicTo(-.235, -.9734, -.13, -.96, 0, -.96)
      ..cubicTo(.13, -.96, .235, -.9734, .235, -.99)
      ..cubicTo(.235, -.955, .17, -.94, .15, -.885)
      ..close();
    c.drawPath(
      belly,
      _ttStone(-.235, .235, const Color(0xffc7ad88), const Color(0xff8f7a62), const Color(0xff5b4c40)),
    );
    c.save();
    c.clipPath(belly);
    c.drawRect(const Rect.fromLTRB(-.24, -.99, .24, -.9), _ttWash(_ttFireLight, .5, -.99, -.9));
    // A row of carved diamonds with jade inlay rings the belly.
    for (var k = -2; k <= 2; k++) {
      final x = k * .06;
      c.drawPath(
        Sketch.poly([x - .013, -.925, x, -.941, x + .013, -.925, x, -.909]),
        _ttFill(Sketch.fade(_ttDeep, .55)),
      );
      c.drawPath(
        Sketch.poly([x - .007, -.925, x, -.934, x + .007, -.925, x, -.916]),
        _ttFill(_ttTeal),
      );
    }
    c.restore();
    c.drawPath(belly, _ttInk(Sketch.fade(_ttDeep, .6), .006));
    // Lit lip, sooty hollow and a bed of coals; the live flame starts at the
    // rim's centre line.
    _ttOval(c, 0, -.99, .235, .03, _ttFill(const Color(0xffe1c08e)));
    _ttOval(c, 0, -.99, .235, .03, _ttInk(Sketch.fade(_ttDeep, .55), .005));
    _ttOval(c, 0, -.992, .2, .021, _ttFill(const Color(0xff2a1a12)));
    _ttOval(c, 0, -.99, .17, .012, _ttFill(const Color(0xffe8551c)));
    for (final (x, y, r, color) in const [
      (-.08, -.99, .02, Color(0xffff9a2a)),
      (.03, -.988, .026, Color(0xffffb236)),
      (.09, -.991, .017, Color(0xffff8a22)),
    ]) {
      _ttOval(c, x, y, r, r * .55, _ttFill(color));
    }
  }

  // The torch fire is drawn every frame from shared paints and unit paths
  // placed with the canvas transform, so nothing is allocated per frame.
  static final _ttTongue = Path()
    ..moveTo(-1, 0)
    ..cubicTo(-1.12, -.4, -.5, -.6, -.1, -1)
    ..cubicTo(.05, -.6, 1.1, -.38, 1, 0)
    ..close();
  static final _ttDrop = Path()
    ..moveTo(0, -1)
    ..cubicTo(.3, -.55, .85, 0, .7, .5)
    ..cubicTo(.55, .95, -.55, .95, -.7, .5)
    ..cubicTo(-.85, 0, -.3, -.55, 0, -1)
    ..close();
  static final _ttRipple = Path()
    ..moveTo(0, 0)
    ..cubicTo(.5, -.17, .5, -.33, 0, -.5)
    ..cubicTo(-.5, -.67, -.5, -.83, 0, -1);
  static final _ttHalo = Paint()..color = const Color(0x66ff5a1e);
  static final _ttOuter = Paint()..color = const Color(0xffe8471c);
  static final _ttMidFlame = Paint()..color = const Color(0xffff8d26);
  static final _ttInner = Paint()..color = const Color(0xffffc940);
  static final _ttCore = Paint()..color = const Color(0xfffff2bd);
  static final _ttBrush = Paint();
  static final _ttWave = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = .05;
  static final _ttHot = Paint()
    ..blendMode = BlendMode.plus
    ..shader = Gradient.radial(
      Offset.zero,
      1,
      const [Color(0xb0ffc060), Color(0x55ff9a3a), Color(0x00ff8a2e)],
      const [0, .35, 1],
    );

  /// [n] unit radial glows of [color], from [lo] of [peak] up to all of it, so
  /// a soft light or puff can change brightness without a new shader.
  static List<Paint> _ttRadials(Color color, double peak, int n, double lo) => [
    for (var i = 0; i < n; i++)
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          1,
          [
            Sketch.fade(color, peak * (lo + (1 - lo) * i / (n - 1))),
            Sketch.fade(color, peak * (lo + (1 - lo) * i / (n - 1)) * .4),
            Sketch.fade(color, 0),
          ],
          const [0, .45, 1],
        ),
  ];

  static final _ttGlows = _ttRadials(const Color(0xffff9a3c), .42, 6, .7);
  static final _ttSmokes = _ttRadials(const Color(0xff5a483e), .17, 8, .12);

  /// Flame tongues: x, half width and height (in totem heights) and a
  /// flicker rate. The first two are the low outer licks, the last the tall
  /// centre.
  static const _ttTongues = <(double, double, double, double)>[
    (-.125, .045, .11, 11.0),
    (.12, .045, .12, 12.5),
    (-.075, .062, .22, 9.7),
    (.07, .062, .24, 10.6),
    (0.0, .088, .34, 8.4),
  ];

  /// Coals along the front of the rim: x, y and half width.
  static const _ttCoals = <(double, double, double)>[
    (-.11, .006, .034),
    (-.045, .012, .036),
    (.03, .01, .038),
    (.1, .006, .032),
  ];

  static double _ttFrac(double x) => x - x.floorToDouble();

  static double _ttLean(double t, double ph, int k, double rate) =>
      .06 + .12 * math.sin(t * rate * .5 + k * 1.7 + ph);

  static double _ttRise(double t, double ph, int k, double rate) =>
      1 + .13 * math.sin(t * rate + k * 2.3 + ph * 1.3) + .07 * math.sin(t * rate * 1.9 + k);

  /// One flame tongue standing on the rim's centre line at [x], leaning by
  /// [lean] (a shear).
  static void _ttLick(Canvas c, double x, double hw, double hgt, double lean, Paint p) {
    c.save();
    c.translate(x, 0);
    c.scale(hw, hgt);
    c.skew(lean, 0);
    c.drawPath(_ttTongue, p);
    c.restore();
  }

  /// The brazier fire at [rim], the centre of the bowl's mouth, in units of
  /// the totem height [s]: a warm glow over the stone, drifting smoke and
  /// heat ripples, layered leaning flame tongues with detached licks, glowing
  /// coals and rising embers. [seed] and time [t] set the phase.
  static void _ttFire(Canvas c, Offset rim, double s, double t, int seed) {
    final ph = seed * 1.7;
    final flick = .88 + .07 * math.sin(t * 9.3 + ph) + .05 * math.sin(t * 15.7 + ph * 2);
    c.save();
    c.translate(rim.dx, rim.dy);
    c.scale(s, s);
    final level = ((flick - .76) / .24 * (_ttGlows.length - 1))
        .round()
        .clamp(0, _ttGlows.length - 1)
        .toInt();
    c.save();
    c.translate(0, -.08);
    c.scale(.8 * flick, .8 * flick);
    c.drawCircle(Offset.zero, 1, _ttGlows[level]);
    c.restore();
    // Smoke drifts up and to the left with the leaves, thinning as it goes.
    for (var j = 0; j < 3; j++) {
      final a = _ttFrac(t / (3.8 + j * .6) + j * .37 + Sketch.hash(seed + j));
      final life = math.sin(math.pi * math.min(1.0, a * 1.1));
      if (life <= .04) continue;
      final r = .09 + .17 * a;
      c.save();
      c.translate(-.14 * a + math.sin(t * .8 + j * 2 + ph) * .05 * a, -.36 - a * .5);
      c.scale(r, r * 1.05);
      c.drawCircle(Offset.zero, 1, _ttSmokes[(life * (_ttSmokes.length - 1)).round()]);
      c.restore();
    }
    // Faint ripples of hot air wander up off the flame.
    for (var j = 0; j < 3; j++) {
      final a = _ttFrac(t / (2.1 + j * .35) + j * .31);
      final r = .18 + .07 * a;
      c.save();
      c.translate(
        (j - 1) * .075 + math.sin(t * 2.6 + j * 2.1 + a * 6) * .018 - .05 * a,
        -.3 - a * .3,
      );
      c.scale(r, r);
      _ttWave.color = Sketch.fade(const Color(0xffffe8c8), math.sin(math.pi * a) * .2);
      c.drawPath(_ttRipple, _ttWave);
      c.restore();
    }
    // Tongues from the outer licks to the tall centre: a soft halo and red
    // body first, then the orange, yellow and white-hot layers inside.
    for (var k = 0; k < _ttTongues.length; k++) {
      final (x, hw, hg, rate) = _ttTongues[k];
      final lean = _ttLean(t, ph, k, rate);
      final hgt = hg * _ttRise(t, ph, k, rate) * flick;
      _ttLick(c, x, hw * 1.12, hgt * 1.08, lean, _ttHalo);
      _ttLick(c, x, hw, hgt, lean, _ttOuter);
    }
    for (var k = 2; k < _ttTongues.length; k++) {
      final (x, hw, hg, rate) = _ttTongues[k];
      final hgt = hg * _ttRise(t, ph, k, rate) * flick;
      _ttLick(c, x * .9, hw * .72, hgt * .8, _ttLean(t, ph, k, rate) * 1.1, _ttMidFlame);
    }
    for (var k = 2; k < _ttTongues.length; k++) {
      final (x, hw, hg, rate) = _ttTongues[k];
      final hgt = hg * _ttRise(t, ph, k, rate) * flick;
      _ttLick(c, x * .7, hw * .48, hgt * .58, _ttLean(t, ph, k, rate) * 1.2, _ttInner);
    }
    final (_, coreHw, coreHg, coreRate) = _ttTongues[4];
    _ttLick(
      c,
      0,
      coreHw * .3,
      coreHg * _ttRise(t, ph, 4, coreRate) * flick * .34,
      _ttLean(t, ph, 4, coreRate) * 1.3,
      _ttCore,
    );
    // Licks break off the tip and fade as they rise.
    for (var j = 0; j < 2; j++) {
      final a = _ttFrac(t / .95 + j * .5 + Sketch.hash(seed + 20 + j));
      c.save();
      c.translate(math.sin(t * 5 + j * 3 + ph) * .03 - .03 * a, -.3 * flick - a * .3);
      c.scale(.026 * (1 - a * .5), .06 * (1 - a * .55));
      _ttBrush.color = Sketch.fade(const Color(0xffffb030), 1 - a);
      c.drawPath(_ttDrop, _ttBrush);
      c.restore();
    }
    // Coals: a hot glow over the flame's foot, then bright coals in front of it.
    c.save();
    c.translate(0, -.01);
    c.scale(.22, .07);
    c.drawCircle(Offset.zero, 1, _ttHot);
    c.restore();
    for (var k = 0; k < _ttCoals.length; k++) {
      final (x, y, rx) = _ttCoals[k];
      final g = .5 + .5 * math.sin(t * 6 + k * 2.1 + ph);
      _ttBrush.color = Sketch.mix(const Color(0xffe8551c), const Color(0xffffb236), g);
      c.drawOval(Rect.fromLTRB(x - rx, y - .011, x + rx, y + .011), _ttBrush);
      _ttBrush.color = Sketch.fade(const Color(0xffffe08a), .5 + .4 * g);
      c.drawOval(
        Rect.fromLTRB(x - .004 - rx * .55, y - .008, x - .004 + rx * .55, y + .004),
        _ttBrush,
      );
    }
    // Embers rise on the wind, cooling from gold to red.
    for (var j = 0; j < 7; j++) {
      final a = _ttFrac(t / (1.5 + 1.3 * Sketch.hash(seed + 60 + j)) + Sketch.hash(seed + 70 + j));
      final x = (Sketch.hash(seed + 80 + j) - .5) * .18 - .12 * a + math.sin(t * 3 + j * 1.9) * .025 * a;
      final y = -.04 - a * (.55 + .5 * Sketch.hash(seed + 90 + j));
      _ttBrush.color = Sketch.fade(
        Sketch.mix(const Color(0xffffe08a), const Color(0xffff5a1e), a),
        1 - a,
      );
      c.drawCircle(
        Offset(x, y),
        .012 * (1 - a * .6) * (.7 + .6 * Sketch.hash(seed + 100 + j)),
        _ttBrush,
      );
    }
    c.restore();
  }
}

/// The Aztec near band's ground: a carved terrace wall along the ridge with a
/// paved forecourt in front of it, and the plants that grow around both.
///
/// [back] records what grows on the terrace behind the wall lip into the
/// band's cached features, so its roots hide behind the ridge. [front] paints
/// the wall, stairs, paving, calendar stones and forecourt plants over the
/// ridge from one picture cached per viewport height.
///
/// Sizes are fractions of the viewport height h and x positions are in
/// viewport heights, like the ridge itself. Light comes from the low sun
/// behind the volcanoes, so top faces glow and upright faces sit in shade.
abstract final class _AztecGround {
  // The wall below the ridge rim: a cornice, then a frieze of glyphs and frets.
  static const _rim = .002, _corniceB = .0068, _wallH = .0245;
  // Paving courses: cumulative depth below the wall, and how much of the
  // ridge's swell each joint keeps (the far ones follow it, near ones flatten).
  static const _cum = [0.0, .0095, .0235, .043, .075];
  static const _keep = [1.0, .8, .55, .3, .1];
  // Slabs per course over one period, and the course's stagger.
  static const _slabs = [(60, .5), (40, .3), (27, .7), (18, .45)];
  static const _modules = 72, _chunks = 12;
  static const _step = .025;
  static const _sunRx = .105, _sunRy = .036;
  static const _stones = [.3, 1.8];
  static const _stairs = [1.05, 2.55];
  static const _frontMarigolds = [(.62, 1.0), (1.4, .85), (2.1, 1.0), (2.85, .8)];
  static const _backFerns = [
    (.06, .05),
    (.47, .062),
    (1.5, .072),
    (1.96, .058),
    (2.4, .066),
    (2.96, .05),
  ];
  static const _backOrchids = [(.53, .076, 1.0), (1.99, .08, -1.0)];
  static const _backMarigolds = [(.98, .05), (2.34, .046)];

  static const _wallBase = Color(0xff9a5e38);
  static const _wallDark = Color(0x40402312);
  static const _wallLight = Color(0x38e6a862);
  static const _cornice = Color(0xffd9a866);
  static const _lip = Color(0xfff0c98a);
  static const _panel = Color(0xff68402b);
  static const _jade = Color(0xff35bfa9);
  static const _tints = [
    Color(0x33f0c483),
    Color(0x2eb8683c),
    Color(0x2a8f6a4c),
    Color(0x30dda56c),
    Color(0x26703f22),
  ];
  static const _joint = Color(0xc0653c20);
  static const _jointLit = Color(0x80f6d296);
  static const _pebbleTones = [
    Color(0xffa08a72),
    Color(0xffdcc49c),
    Color(0xff76675a),
    Color(0xffbb6e46),
  ];

  // ---- terrace lines -------------------------------------------------

  /// Height of a line [off] (in h) under the near ridge at [x], keeping only
  /// [keep] of the ridge's swell.
  static double _cy(RegionScene s, double h, double x, double off, double keep) {
    final r = s.ridge(Depth.near, x, 0) * h;
    final mean = h * .92;
    return mean + off * h + keep * (r - mean);
  }

  /// A polyline along a terrace line from [x0] to [x1] in [n] segments.
  static void _line(
    Path p,
    RegionScene s,
    double h,
    double x0,
    double x1,
    int n,
    double off,
    double keep,
  ) {
    for (var i = 0; i <= n; i++) {
      final x = x0 + (x1 - x0) * i / n;
      final y = _cy(s, h, x, off, keep);
      if (i == 0) {
        p.moveTo(x * h, y);
      } else {
        p.lineTo(x * h, y);
      }
    }
  }

  /// A closed strip between two terrace lines.
  static void _band(
    Path p,
    RegionScene s,
    double h,
    double x0,
    double x1,
    int n,
    double offTop,
    double offBot, {
    double keepTop = 1,
    double keepBot = 1,
  }) {
    _line(p, s, h, x0, x1, n, offTop, keepTop);
    for (var i = n; i >= 0; i--) {
      final x = x0 + (x1 - x0) * i / n;
      p.lineTo(x * h, _cy(s, h, x, offBot, keepBot));
    }
    p.close();
  }

  static int _segs(double x0, double x1) =>
      math.max(1, ((x1 - x0) / _step).round());

  static Paint _fill(Color c) => Paint()..color = c;

  static Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round;

  /// Whether a forecourt plant or pebble at [x] would land on a stone or stair.
  static bool _free(double x) {
    for (final sx in _stones) {
      if ((x - sx).abs() < .14) return false;
    }
    for (final sx in _stairs) {
      if ((x - sx).abs() < .17) return false;
    }
    return true;
  }

  // ---- the cached forecourt picture ----------------------------------

  static Picture? _picture;
  static double _pictureH = 0;
  static final _fade = Paint();

  /// The wall, paving and forecourt over the near ridge, fading with
  /// [presence] while a crossing hands the band over.
  static void front(Canvas c, RegionScene s, SceneFrame f, double presence) {
    final h = f.h;
    if (!(h > 1) || presence <= .01) return;
    var pic = _picture;
    if (pic == null || _pictureH != h) {
      pic?.dispose();
      pic = _picture = _record(s, h);
      _pictureH = h;
    }
    if (presence >= .995) {
      c.drawPicture(pic);
      return;
    }
    _fade.color = Color.fromRGBO(0, 0, 0, presence);
    c.saveLayer(
      Rect.fromLTRB(-h, h * .85, (s.period(Depth.near) + 1) * h, h * 1.05),
      _fade,
    );
    c.drawPicture(pic);
    c.restore();
  }

  static Picture _record(RegionScene s, double h) {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final span = s.period(Depth.near);
    final edges = [for (var k = 0; k < _slabs.length; k++) _edges(k, span)];
    for (var i = 0; i < _chunks; i++) {
      _wall(c, s, h, span, i);
      _paving(c, s, h, span, i, edges);
    }
    for (final x in _stairs) {
      _stair(c, s, h, x);
    }
    for (final x in _stones) {
      _sun(c, s, h, x);
    }
    _scatter(c, s, h, span);
    return rec.endRecording();
  }

  /// Slab joints of course [k] across one period, staggered per course.
  static List<double> _edges(int k, double span) {
    final (count, off) = _slabs[k];
    return [
      for (var i = 0; i < count; i++)
        span *
            (i + off + (Sketch.hash(9200 + k * 101 + i) - .5) * .5) /
            count,
    ];
  }

  // ---- the terrace wall -----------------------------------------------

  static void _wall(
    Canvas c,
    RegionScene s,
    double h,
    double span,
    int chunk,
  ) {
    final x0 = span * chunk / _chunks, x1 = span * (chunk + 1) / _chunks;
    final n = _segs(x0, x1);
    final body = Path();
    _band(body, s, h, x0, x1, n, _rim, _wallH);
    c.drawPath(body, _fill(_wallBase));
    final dark = Path(), light = Path(), joints = Path(), fret = Path();
    final per = _modules ~/ _chunks;
    final w = span / _modules;
    final q = h * .0068;
    final hook = <(double, double)>[];
    for (var i = chunk * per; i < (chunk + 1) * per; i++) {
      final xa = i * w, xb = xa + w, xm = xa + w / 2;
      final t = Sketch.hash(i + 9000);
      if (t < .3) {
        _band(dark, s, h, xa, xb, 1, _corniceB, _wallH);
      } else if (t > .7) {
        _band(light, s, h, xa, xb, 1, _corniceB, _wallH);
      }
      joints
        ..moveTo(xa * h, _cy(s, h, xa, _corniceB, 1))
        ..lineTo(xa * h, _cy(s, h, xa, _wallH, 1));
      if (i.isOdd) {
        joints
          ..moveTo(xa * h, _cy(s, h, xa, _rim, 1))
          ..lineTo(xa * h, _cy(s, h, xa, _corniceB, 1));
      }
      final yc = _cy(s, h, xm, (_corniceB + _wallH) / 2, 1);
      if (i % 3 == 1) {
        hook.add((xm * h, yc));
      } else {
        // Two stepped-fret hooks per module, mirrored so they interlock.
        for (var k = 0; k < 2; k++) {
          _fretHook(
            fret,
            xa * h + k * w * h / 2,
            yc,
            w * h / 2,
            h * .0088,
            (i + k).isEven ? 1 : -1,
          );
        }
      }
    }
    c.drawPath(dark, _fill(_wallDark));
    c.drawPath(light, _fill(_wallLight));
    final cornice = Path();
    _band(cornice, s, h, x0, x1, n, _rim, _corniceB);
    c.drawPath(cornice, _fill(_cornice));
    final jw = math.max(.7, h * .0014);
    c.drawPath(joints, _stroke(const Color(0x8c4a2a16), jw));
    // The cornice throws a soft shadow over the frieze, and the foot of the
    // wall darkens where it meets the paving.
    final under = Path();
    _line(under, s, h, x0, x1, n, _corniceB + .0018, 1);
    c.drawPath(under, _stroke(const Color(0x40402312), h * .0038));
    final edge = Path();
    _line(edge, s, h, x0, x1, n, _corniceB, 1);
    c.drawPath(edge, _stroke(const Color(0x99502c16), math.max(.7, h * .0011)));
    final foot = Path();
    _line(foot, s, h, x0, x1, n, _wallH - .0014, 1);
    c.drawPath(foot, _stroke(const Color(0x4d3a1e0e), h * .0034));
    // Carved stepped frets, each with a lit lower lip.
    final fw = math.max(.7, h * .0012);
    c.save();
    c.translate(fw * .7, fw * .8);
    c.drawPath(fret, _stroke(const Color(0x88f0c98a), fw));
    c.restore();
    c.drawPath(fret, _stroke(const Color(0xd95b3420), fw));
    for (final (i, (x, y)) in hook.indexed) {
      _cartouche(c, Offset(x, y), q, (chunk * per + 1 + i * 3), h);
    }
  }

  /// One stepped-fret hook (a square spiral) in a cell [cw] wide, [fh] tall,
  /// opening to the right when [dir] is 1 and to the left when -1.
  static void _fretHook(
    Path p,
    double left,
    double yc,
    double cw,
    double fh,
    int dir,
  ) {
    const pts = [0.0, 1.0, 0, 0, 1, 0, 1, .68, .34, .68, .34, .34, .68, .34];
    final inset = cw * .12, span = cw - inset * 2;
    for (var i = 0; i < pts.length; i += 2) {
      final u = dir > 0 ? pts[i] : 1 - pts[i];
      final x = left + inset + u * span;
      final y = yc - fh / 2 + pts[i + 1] * fh;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
  }

  /// A recessed square panel carrying one day-sign glyph in relief.
  static void _cartouche(Canvas c, Offset at, double q, int index, double h) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: q * 2, height: q * 2),
      Radius.circular(q * .2),
    );
    c.drawRRect(r, _fill(_panel));
    final lipY = at.dy + q + math.max(.4, h * .0005);
    c.drawLine(
      Offset(at.dx - q * .8, lipY),
      Offset(at.dx + q * .8, lipY),
      _stroke(const Color(0x70f0c98a), math.max(.5, h * .0007)),
    );
    final kind = (index ~/ 3) % 6;
    final g = q * .74, off = math.max(.45, h * .0007);
    _glyph(c, kind, at + Offset(off, off), g, const Color(0xcc2a140a));
    _glyph(c, kind, at, g, kind % 3 == 1 ? _jade : _lip);
  }

  /// A day-sign in a unit box scaled to half-size [q]: sun, ollin, water,
  /// serpent, flint knife or flower.
  static void _glyph(Canvas c, int kind, Offset at, double q, Color color) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final solid = Paint()..color = color;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(q, q);
    switch (kind) {
      case 0:
        final rays = Path();
        for (var k = 0; k < 8; k++) {
          final a = k * math.pi / 4;
          rays
            ..moveTo(math.cos(a) * .68, math.sin(a) * .68)
            ..lineTo(math.cos(a) * .98, math.sin(a) * .98);
        }
        c.drawCircle(Offset.zero, .42, solid);
        c.drawPath(rays, line..strokeWidth = .24);
      case 1:
        c.drawPath(
          Path()
            ..moveTo(-.78, -.78)
            ..lineTo(.78, .78)
            ..moveTo(.78, -.78)
            ..lineTo(-.78, .78),
          line..strokeWidth = .34,
        );
        c.drawCircle(Offset.zero, .34, solid);
      case 2:
        final wave = Path();
        for (final y in const [-.4, .4]) {
          wave
            ..moveTo(-.92, y)
            ..quadraticBezierTo(-.62, y - .5, -.31, y)
            ..quadraticBezierTo(0, y + .5, .31, y)
            ..quadraticBezierTo(.62, y - .5, .92, y);
        }
        c.drawPath(wave, line..strokeWidth = .26);
      case 3:
        c.drawPath(
          Path()
            ..moveTo(-.82, .7)
            ..cubicTo(-1.0, -.7, .05, -.95, .08, -.1)
            ..cubicTo(.12, .55, .95, .4, .8, -.62),
          line..strokeWidth = .3,
        );
        c.drawCircle(const Offset(.8, -.66), .24, solid);
      case 4:
        c.drawPath(
          Path()
            ..moveTo(0, -.98)
            ..quadraticBezierTo(.78, -.15, 0, .55)
            ..quadraticBezierTo(-.78, -.15, 0, -.98)
            ..close(),
          solid,
        );
        c.drawLine(const Offset(0, .5), const Offset(0, .98), line..strokeWidth = .28);
      default:
        for (final (dx, dy, tall) in const [
          (0.0, -.56, true),
          (0.0, .56, true),
          (-.56, 0.0, false),
          (.56, 0.0, false),
        ]) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(dx, dy),
              width: tall ? .5 : .72,
              height: tall ? .72 : .5,
            ),
            solid,
          );
        }
    }
    c.restore();
  }

  // ---- the paved forecourt --------------------------------------------

  static void _paving(
    Canvas c,
    RegionScene s,
    double h,
    double span,
    int chunk,
    List<List<double>> edges,
  ) {
    final x0 = span * chunk / _chunks, x1 = span * (chunk + 1) / _chunks;
    final n = _segs(x0, x1);
    final tints = [for (final _ in _tints) Path()];
    final vDark = Path(), vLit = Path(), hDark = Path(), hLit = Path();
    final lit = h * .0014;
    for (var k = 0; k < _slabs.length; k++) {
      final e = edges[k];
      final top = _wallH + _cum[k], bottom = _wallH + _cum[k + 1];
      // A slab that wraps the period's seam is drawn in two pieces that share
      // one tint, so the seam never shows.
      for (var p = 0; p <= e.length; p++) {
        final xa = p == 0 ? 0.0 : e[p - 1];
        if (xa < x0 || xa >= x1) continue;
        final xb = p == e.length ? span : e[p];
        final t = Sketch.hash(9100 + k * 131 + (p == e.length ? 0 : p));
        final pick = (t * (_tints.length + 1)).floor();
        if (pick < _tints.length) {
          _band(
            tints[pick],
            s,
            h,
            xa,
            xb,
            _segs(xa, xb),
            top,
            bottom,
            keepTop: _keep[k],
            keepBot: _keep[k + 1],
          );
        }
      }
      for (final b in e) {
        if (b < x0 || b >= x1) continue;
        final y0 = _cy(s, h, b, top, _keep[k]);
        final y1 = _cy(s, h, b, bottom, _keep[k + 1]);
        vDark
          ..moveTo(b * h, y0)
          ..lineTo(b * h, y1);
        vLit
          ..moveTo(b * h + lit, y0)
          ..lineTo(b * h + lit, y1);
      }
      if (k > 0) {
        _line(hDark, s, h, x0, x1, n, top, _keep[k]);
        _line(hLit, s, h, x0, x1, n, top + .0016, _keep[k]);
      }
    }
    for (var i = 0; i < _tints.length; i++) {
      c.drawPath(tints[i], _fill(_tints[i]));
    }
    final jw = math.max(.7, h * .0017);
    c.drawPath(hLit, _stroke(_jointLit, jw * .8));
    c.drawPath(vLit, _stroke(_jointLit, jw * .8));
    c.drawPath(hDark, _stroke(_joint, jw));
    c.drawPath(vDark, _stroke(_joint, jw));
    // The wall's foot shades the first course.
    final foot = Path();
    _line(foot, s, h, x0, x1, n, _wallH + .003, 1);
    c.drawPath(foot, _stroke(const Color(0x2e3a1e0e), h * .0058));
    // Grit in the stone: dark pores and pale flecks.
    final pores = <Offset>[], flecks = <Offset>[];
    for (var q = 0; q < 44; q++) {
      final x = x0 + (x1 - x0) * Sketch.hash(9300 + chunk * 89 + q);
      final t = Sketch.hash(9500 + chunk * 89 + q);
      final top = _cy(s, h, x, _wallH + .003, 1);
      (q.isEven ? pores : flecks).add(Offset(x * h, top + (h - top) * t));
    }
    c.drawPoints(
      PointMode.points,
      pores,
      Paint()
        ..color = const Color(0x66663c20)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.9, h * .0024),
    );
    c.drawPoints(
      PointMode.points,
      flecks,
      Paint()
        ..color = const Color(0x70f6d69c)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, h * .0017),
    );
  }

  // ---- stairs ---------------------------------------------------------

  /// A broad stair climbing to the terrace, with a balustrade each side.
  static void _stair(Canvas c, RegionScene s, double h, double xc) {
    final x = xc * h;
    final top = _cy(s, h, xc, .001, 1);
    final hw = h * .105, cheek = h * .0145;
    final rise = h * .0072, tread = h * .0046;
    const steps = 4;
    final end = top + steps * (rise + tread);
    final wide = hw * (1 + .05 * (steps - 1));
    for (final side in const [-1.0, 1.0]) {
      c.drawPath(
        Sketch.poly([
          x + side * (hw + cheek), top - h * .0035,
          x + side * hw, top - h * .001,
          x + side * wide, end,
          x + side * (wide + cheek * 1.15), end,
        ]),
        _fill(side < 0 ? _cornice : const Color(0xffc99658)),
      );
      c.drawLine(
        Offset(x + side * hw, top - h * .001),
        Offset(x + side * wide, end),
        _stroke(const Color(0x805b3420), math.max(.7, h * .0012)),
      );
    }
    c.drawRect(
      Rect.fromLTRB(x - hw - cheek, top - h * .0035, x + hw + cheek, top),
      _fill(_cornice),
    );
    for (var k = 0; k < steps; k++) {
      final half = hw * (1 + .05 * k);
      final y = top + k * (rise + tread);
      c.drawRect(
        Rect.fromLTRB(x - half, y, x + half, y + rise),
        _fill(const Color(0xff8f5834)),
      );
      c.drawRect(
        Rect.fromLTRB(x - half, y + rise, x + half, y + rise + tread),
        _fill(const Color(0xffefc487)),
      );
      c.drawRect(
        Rect.fromLTRB(x - half, y + rise + tread - h * .0009, x + half, y + rise + tread),
        _fill(const Color(0x554a2a16)),
      );
    }
    c.drawRect(
      Rect.fromLTRB(x - wide, end, x + wide, end + h * .004),
      _fill(const Color(0x483a1e0e)),
    );
  }

  // ---- calendar stones ------------------------------------------------

  /// A sun-stone inlaid flat in the paving, foreshortened to an ellipse:
  /// fire-serpent ring, day-sign ring, the eight rays and a face at the heart.
  static void _sun(Canvas c, RegionScene s, double h, double xc) {
    final cy = _cy(s, h, xc, _wallH + .004 + _sunRy, 1);
    Paint stroke(Color col, double w) => _stroke(col, w);
    c.save();
    c.translate(xc * h, cy);
    c.scale(h * _sunRx, h * _sunRy);
    c.drawCircle(Offset.zero, 1.05, _fill(const Color(0xb04a2a16)));
    c.drawCircle(Offset.zero, 1.0, _fill(const Color(0xffdcae72)));
    c.drawCircle(Offset.zero, .965, _fill(const Color(0xffb04630)));
    c.drawCircle(Offset.zero, .86, _fill(const Color(0xffdcae72)));
    final teeth = Path();
    for (var k = 0; k < 36; k++) {
      final a = k * math.pi / 18;
      teeth
        ..moveTo(math.cos(a) * .885, math.sin(a) * .885)
        ..lineTo(math.cos(a) * .95, math.sin(a) * .95);
    }
    c.drawPath(teeth, stroke(_lip, .05));
    c.drawCircle(Offset.zero, .84, _fill(_jade));
    c.drawCircle(Offset.zero, .69, _fill(const Color(0xffdcae72)));
    final cells = Path();
    for (var k = 0; k < 20; k++) {
      final a = k * math.pi / 10;
      cells
        ..moveTo(math.cos(a) * .69, math.sin(a) * .69)
        ..lineTo(math.cos(a) * .84, math.sin(a) * .84);
    }
    const soft = Color(0x995b3420);
    c.drawPath(cells, stroke(soft, .03));
    c.drawCircle(Offset.zero, .84, stroke(soft, .03));
    c.drawCircle(Offset.zero, .69, stroke(soft, .03));
    final rays = Path(), small = Path();
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      rays
        ..moveTo(math.cos(a - .2) * .44, math.sin(a - .2) * .44)
        ..lineTo(math.cos(a) * .68, math.sin(a) * .68)
        ..lineTo(math.cos(a + .2) * .44, math.sin(a + .2) * .44)
        ..close();
      final b = a + math.pi / 8;
      small
        ..moveTo(math.cos(b - .1) * .46, math.sin(b - .1) * .46)
        ..lineTo(math.cos(b) * .62, math.sin(b) * .62)
        ..lineTo(math.cos(b + .1) * .46, math.sin(b + .1) * .46)
        ..close();
    }
    c.drawPath(rays, _fill(const Color(0xfff0b83c)));
    c.drawPath(small, _fill(const Color(0xffb04630)));
    c.drawPath(rays, stroke(soft, .022));
    c.drawCircle(Offset.zero, .43, _fill(const Color(0xfff0b83c)));
    c.drawCircle(Offset.zero, .37, _fill(const Color(0xffecc98e)));
    const dark = Color(0xff4a2a16);
    for (final dx in const [-.13, .13]) {
      c.drawOval(Rect.fromCenter(center: Offset(dx, -.09), width: .11, height: .075), _fill(dark));
    }
    c.drawOval(Rect.fromCenter(center: const Offset(0, .1), width: .26, height: .1), _fill(dark));
    c.drawPath(
      Sketch.poly([-.055, .11, .055, .11, 0, .33]),
      _fill(const Color(0xffb04630)),
    );
    // Relief: a lit lip on the upper-left arc, a shadow on the lower-right.
    final rim = Rect.fromCircle(center: Offset.zero, radius: .995);
    c.drawArc(rim, math.pi * 1.05, math.pi * .6, false, stroke(const Color(0xb3fff0c8), .06));
    c.drawArc(rim, math.pi * .08, math.pi * .62, false, stroke(const Color(0x664a2a16), .06));
    c.restore();
  }

  // ---- scattered forecourt detail -------------------------------------

  static void _scatter(Canvas c, RegionScene s, double h, double span) {
    double lowY(double x, double t) {
      final top = _cy(s, h, x, _wallH + .003, 1);
      return top + (h - top) * t;
    }

    // Moss stains creep along the foot of the wall.
    final mossDark = Path(), mossLit = Path();
    for (var i = 0; i < 9; i++) {
      final x = span * (i + .5 + (Sketch.hash(10500 + i) - .5) * .6) / 9;
      if (!_free(x)) continue;
      final y = _cy(s, h, x, _wallH + .0035 + .004 * Sketch.hash(10520 + i), 1);
      final wd = h * (.02 + .014 * Sketch.hash(10540 + i));
      mossDark.addOval(Rect.fromCenter(center: Offset(x * h, y), width: wd, height: h * .0065));
      mossLit.addOval(
        Rect.fromCenter(
          center: Offset(x * h - wd * .12, y - h * .0008),
          width: wd * .6,
          height: h * .0038,
        ),
      );
    }
    c.drawPath(mossDark, _fill(const Color(0x995b8a3c)));
    c.drawPath(mossLit, _fill(const Color(0x99a4cc62)));

    // Hairline cracks wander out of the joints.
    final cracks = Path();
    for (var i = 0; i < 7; i++) {
      final x = span * (i + .3 + .4 * Sketch.hash(10600 + i)) / 7;
      if (!_free(x)) continue;
      var px = x * h, py = lowY(x, .1 + .25 * Sketch.hash(10620 + i));
      cracks.moveTo(px, py);
      for (var q = 0; q < 5; q++) {
        px += h * (.006 + .006 * Sketch.hash(10640 + i * 7 + q));
        py += h * (Sketch.hash(10680 + i * 7 + q) - .35) * .01;
        cracks.lineTo(px, py);
        if (q == 1) {
          cracks
            ..moveTo(px, py)
            ..lineTo(px + h * .004, py + h * .007)
            ..moveTo(px, py);
        }
      }
    }
    c.drawPath(cracks, _stroke(const Color(0x8c5b3420), math.max(.6, h * .0011)));

    // Marigold petals strewn along the paving, as on a path of offerings.
    final petalA = Path(), petalB = Path();
    for (final (mx, _) in _frontMarigolds) {
      for (var i = 0; i < 9; i++) {
        final x = mx + (Sketch.hash(10800 + i + (mx * 10).round() * 13) - .5) * .17;
        if (!_free(x)) continue;
        final y = lowY(x, .12 + .6 * Sketch.hash(10830 + i + (mx * 10).round() * 13));
        _petal(
          i.isEven ? petalA : petalB,
          x * h,
          y,
          h * (.0034 + .0022 * Sketch.hash(10860 + i)),
          Sketch.hash(10890 + i) * math.pi,
        );
      }
    }
    c.drawPath(petalA, _fill(const Color(0xfff08a1c)));
    c.drawPath(petalB, _fill(const Color(0xffffb83c)));

    // Pebbles, each with a contact shadow and a bright upper-left edge.
    final shadow = Path(), glint = Path();
    final bodies = [for (final _ in _pebbleTones) Path()];
    for (var i = 0; i < 40; i++) {
      final x = span * Sketch.hash(9900 + i);
      if (!_free(x)) continue;
      final t = .12 + .8 * Sketch.hash(9950 + i);
      final r = h * (.0022 + .0042 * t * (.4 + .6 * Sketch.hash(9990 + i)));
      final y = math.min(lowY(x, t), h - r * .7);
      final tone = (Sketch.hash(9970 + i) * _pebbleTones.length).floor();
      shadow.addOval(
        Rect.fromCenter(
          center: Offset(x * h + r * .35, y + r * .28),
          width: r * 2.1,
          height: r * 1.3,
        ),
      );
      bodies[tone].addOval(
        Rect.fromCenter(center: Offset(x * h, y), width: r * 2, height: r * 1.25),
      );
      glint.addOval(
        Rect.fromCenter(
          center: Offset(x * h - r * .3, y - r * .28),
          width: r * .8,
          height: r * .38,
        ),
      );
    }
    c.drawPath(shadow, _fill(const Color(0x504a2a16)));
    for (var i = 0; i < _pebbleTones.length; i++) {
      c.drawPath(bodies[i], _fill(_pebbleTones[i]));
    }
    c.drawPath(glint, _fill(const Color(0x99f8e4bc)));

    // Marigold clumps at the wall's foot.
    for (final (i, (mx, k)) in _frontMarigolds.indexed) {
      _marigolds(c, Offset(mx * h, lowY(mx, .07)), h * .05 * k, 10400 + i * 40);
    }

    // Grass thrusting up between the slabs.
    final dark = Path(), mid = Path(), lit = Path();
    for (var i = 0; i < 20; i++) {
      final x = span * (i + .5 + (Sketch.hash(10100 + i) - .5) * .9) / 20;
      if (!_free(x)) continue;
      final y = lowY(x, .02 + .3 * Sketch.hash(10140 + i));
      _tuft(
        dark,
        mid,
        lit,
        x * h,
        y,
        h * (.012 + .015 * Sketch.hash(10180 + i)),
        10200 + i * 19,
        5 + i % 4,
      );
    }
    _drawTufts(c, dark, mid, lit);
  }

  static void _drawTufts(Canvas c, Path dark, Path mid, Path lit) {
    c.drawPath(dark, _fill(const Color(0xff3c7538)));
    c.drawPath(mid, _fill(const Color(0xff5f9b45)));
    c.drawPath(lit, _fill(const Color(0xff9acb5c)));
  }

  /// A lens-shaped petal of half-length [len] lying at [ang].
  static void _petal(Path p, double x, double y, double len, double ang) {
    final dx = math.cos(ang), dy = math.sin(ang);
    final nx = -dy * len * .65, ny = dx * len * .65;
    p
      ..moveTo(x - dx * len, y - dy * len)
      ..quadraticBezierTo(x + nx, y + ny, x + dx * len, y + dy * len)
      ..quadraticBezierTo(x - nx, y - ny, x - dx * len, y - dy * len)
      ..close();
  }

  // ---- plants ---------------------------------------------------------

  /// A fan of [blades] grass blades [s] tall rooted at ([x], [y]); blades that
  /// lean toward the sun go into the lighter paths.
  static void _tuft(
    Path dark,
    Path mid,
    Path lit,
    double x,
    double y,
    double s,
    int seed,
    int blades,
  ) {
    for (var b = 0; b < blades; b++) {
      final u = blades == 1 ? 0.0 : b / (blades - 1) * 2 - 1;
      final r = Sketch.hash(seed + b * 7);
      final lean = u * .6 + (r - .5) * .3;
      final len = s * (.6 + .4 * (1 - u.abs())) * (.85 + .3 * Sketch.hash(seed + b * 13 + 3));
      final bx = x + u * s * .1;
      final w = math.max(.45, s * .06);
      final sx = math.cos(lean) * w, sy = math.sin(lean) * w;
      final cx = bx + math.sin(lean) * len * .35;
      final cy = y - math.cos(lean) * len * .68;
      final tip = Offset(
        bx + math.sin(lean) * len * .8 + (r - .4) * len * .3,
        y - math.cos(lean) * len * .97,
      );
      final path = u < -.15
          ? (r > .3 ? lit : mid)
          : (u > .35 ? dark : (r > .5 ? mid : dark));
      path
        ..moveTo(bx - sx, y - sy)
        ..quadraticBezierTo(cx - sx * .5, cy - sy * .5, tip.dx, tip.dy)
        ..quadraticBezierTo(cx + sx * .5, cy + sy * .5, bx + sx, y + sy)
        ..close();
    }
  }

  /// A pinnate frond (fern or marigold leaf) along the quadratic p0-p1-p2:
  /// leaflets go into [leaflets], the midrib into [rib].
  static void _frond(
    Path leaflets,
    Path rib,
    Offset p0,
    Offset p1,
    Offset p2,
    double maxLen,
    int pairs,
  ) {
    rib
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
    for (var k = 0; k < pairs; k++) {
      final t = .12 + .84 * (k + .5) / pairs, u = 1 - t;
      final px = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
      final py = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
      var tx = 2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx);
      var ty = 2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy);
      final m = math.sqrt(tx * tx + ty * ty);
      if (m < 1e-6) continue;
      tx /= m;
      ty /= m;
      final nx = -ty, ny = tx;
      final l = maxLen * math.sin(math.pi * (.16 + .84 * t));
      final b = maxLen * .2;
      for (final side in const [-1.0, 1.0]) {
        leaflets
          ..moveTo(px - tx * b, py - ty * b)
          ..lineTo(px + nx * side * l + tx * l * .55, py + ny * side * l + ty * l * .55)
          ..lineTo(px + tx * b, py + ty * b)
          ..close();
      }
    }
  }

  /// A fern crown of arching fronds, [len] tall, with a fiddlehead unrolling
  /// at its heart.
  static void _fern(Canvas c, double x, double y, double len, int seed) {
    final dark = Path(), mid = Path(), lit = Path(), rib = Path();
    const angles = [-1.28, -.86, -.45, -.08, .3, .72, 1.15];
    for (var i = 0; i < angles.length; i++) {
      final a = angles[i] + (Sketch.hash(seed + i) - .5) * .18;
      final l = len * (.72 + .28 * math.cos(a * .9)) * (.9 + .2 * Sketch.hash(seed + 20 + i));
      final sa = math.sin(a);
      final tip = Offset(x + sa * l * .95, y - l * (1 - .58 * sa.abs()));
      final ctl = Offset(x + sa * l * .5, y - l * (.98 - .2 * sa.abs()));
      _frond(
        a < -.25 ? lit : (a > .25 ? dark : mid),
        rib,
        Offset(x, y),
        ctl,
        tip,
        l * .27,
        9,
      );
    }
    c.drawPath(dark, _fill(const Color(0xff2c6a3e)));
    c.drawPath(mid, _fill(const Color(0xff47904f)));
    c.drawPath(lit, _fill(const Color(0xff7cbd5c)));
    c.drawPath(rib, _stroke(const Color(0xaa1f4a2c), math.max(.6, len * .02)));
    final curl = Rect.fromCircle(center: Offset(x + len * .08, y - len * .5), radius: len * .06);
    c.drawArc(curl, math.pi * .5, math.pi * 1.5, false, _stroke(const Color(0xff5fa552), math.max(.7, len * .028)));
    c.drawLine(Offset(x, y), Offset(curl.center.dx, curl.bottom), _stroke(const Color(0xff5fa552), math.max(.7, len * .028)));
  }

  /// A marigold plant [s] tall: serrated leaves and stems bearing ruffled
  /// orange heads and a bud.
  static void _marigolds(Canvas c, Offset base, double s, int seed) {
    c.drawOval(
      Rect.fromCenter(center: base + Offset(0, s * .02), width: s * .8, height: s * .12),
      _fill(const Color(0x384a2a16)),
    );
    final leaf = Path(), leafLit = Path(), rib = Path();
    for (var i = 0; i < 5; i++) {
      final a = (i - 2) * .5 + (Sketch.hash(seed + i) - .5) * .2;
      final l = s * (.5 + .15 * Sketch.hash(seed + 10 + i));
      final tip = base + Offset(math.sin(a) * l, -math.cos(a) * l * .75 + l * .12 * a.abs());
      final ctl = base + Offset(math.sin(a) * l * .35, -math.cos(a) * l * .9);
      _frond(i.isOdd ? leafLit : leaf, rib, base, ctl, tip, l * .3, 6);
    }
    c.drawPath(leaf, _fill(const Color(0xff2f6b3a)));
    c.drawPath(leafLit, _fill(const Color(0xff5fa04a)));
    c.drawPath(rib, _stroke(const Color(0x881f4a2c), math.max(.5, s * .012)));
    const heads = [(-.22, .78, 1.0), (.16, .95, 1.0), (-.02, .6, .9), (.32, .55, .78)];
    final stem = Path();
    final edge = Path(), outer = Path(), mid = Path(), inner = Path(), core = Path();
    for (var i = 0; i < heads.length; i++) {
      final (dx, ht, k) = heads[i];
      final top = base + Offset(dx * s, -ht * s);
      stem
        ..moveTo(base.dx + dx * s * .25, base.dy)
        ..quadraticBezierTo(base.dx + dx * s * .1, base.dy - ht * s * .6, top.dx, top.dy);
      final r = s * .19 * k;
      edge.addOval(Rect.fromCircle(center: top, radius: r * 1.08));
      for (var p = 0; p < 8; p++) {
        final a = p * math.pi / 4 + i;
        outer.addOval(
          Rect.fromCircle(
            center: top + Offset(math.cos(a), math.sin(a)) * (r * .7),
            radius: r * .36,
          ),
        );
      }
      mid.addOval(Rect.fromCircle(center: top, radius: r * .8));
      for (var p = 0; p < 6; p++) {
        final a = p * math.pi / 3 + .5 + i;
        inner.addOval(
          Rect.fromCircle(
            center: top + Offset(math.cos(a), math.sin(a)) * (r * .36),
            radius: r * .27,
          ),
        );
      }
      core.addOval(
        Rect.fromCircle(center: top + Offset(-r * .1, -r * .12), radius: r * .2),
      );
    }
    // A bud that has not yet opened.
    final bud = base + Offset(-.4 * s, -.36 * s);
    stem
      ..moveTo(base.dx - s * .1, base.dy)
      ..quadraticBezierTo(base.dx - s * .3, base.dy - s * .2, bud.dx, bud.dy);
    c.drawPath(stem, _stroke(const Color(0xff3f7a3a), math.max(.7, s * .03)));
    c.drawOval(
      Rect.fromCenter(center: bud, width: s * .13, height: s * .16),
      _fill(const Color(0xff4f8a3e)),
    );
    c.drawOval(
      Rect.fromCenter(center: bud + Offset(0, -s * .05), width: s * .1, height: s * .08),
      _fill(const Color(0xffe8891c)),
    );
    c.drawPath(edge, _fill(const Color(0xffb45a12)));
    c.drawPath(outer, _fill(const Color(0xffee8a1c)));
    c.drawPath(mid, _fill(const Color(0xfff6a327)));
    c.drawPath(inner, _fill(const Color(0xffffc63f)));
    c.drawPath(core, _fill(const Color(0xffffe27e)));
  }

  /// An orchid spray of four blooms and two buds on a stem arching [dir]
  /// (-1 left, 1 right) from [base], [hgt] tall.
  static void _orchid(Canvas c, Offset base, double hgt, double dir) {
    final tip = base + Offset(dir * hgt * .55, -hgt * .78);
    final ctl = base + Offset(dir * hgt * .08, -hgt * 1.05);
    // Strap leaves at the foot.
    final strap = Path();
    for (final k in const [-1.0, 1.0]) {
      strap
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + k * hgt * .12, base.dy - hgt * .3, base.dx + k * hgt * .3, base.dy - hgt * .26)
        ..quadraticBezierTo(base.dx + k * hgt * .13, base.dy - hgt * .2, base.dx + k * hgt * .03, base.dy)
        ..close();
    }
    c.drawPath(strap, _fill(const Color(0xff3a7a45)));
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(ctl.dx, ctl.dy, tip.dx, tip.dy),
      _stroke(const Color(0xff5b8f45), math.max(.7, hgt * .022)),
    );
    for (var i = 0; i < 4; i++) {
      final t = .5 + i * .16, u = 1 - t;
      final px = u * u * base.dx + 2 * u * t * ctl.dx + t * t * tip.dx;
      final py = u * u * base.dy + 2 * u * t * ctl.dy + t * t * tip.dy;
      final r = hgt * (.11 - i * .012);
      final side = i.isEven ? -1.0 : 1.0;
      _bloom(c, Offset(px + side * r * .9, py - r * .1), r, side * .18);
    }
    final bud = _fill(const Color(0xffe6cf96));
    for (var i = 0; i < 2; i++) {
      final at = tip + Offset(dir * hgt * (.05 + i * .05), hgt * (.03 + i * .06));
      c.drawOval(Rect.fromCenter(center: at, width: hgt * .05, height: hgt * .07), bud);
    }
  }

  /// One orchid bloom seen face on: three sepals, two broad petals and a
  /// magenta lip with a yellow throat.
  static void _bloom(Canvas c, Offset at, double r, double tilt) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    final sepal = _fill(const Color(0xfff4cfe8));
    for (final a in const [-math.pi / 2, math.pi * .17, math.pi * .83]) {
      c.save();
      c.rotate(a);
      c.drawOval(Rect.fromLTRB(0, -r * .2, r * 1.05, r * .2), sepal);
      c.restore();
    }
    final petal = _fill(const Color(0xffecaed8));
    for (final a in const [-.16, math.pi + .16]) {
      c.save();
      c.rotate(a);
      c.drawOval(Rect.fromLTRB(0, -r * .5, r * .95, r * .5), petal);
      c.restore();
    }
    c.drawOval(
      Rect.fromCenter(center: Offset(0, r * .32), width: r * .62, height: r * .5),
      _fill(const Color(0xffa52d8c)),
    );
    c.drawCircle(Offset(0, r * .15), r * .13, _fill(const Color(0xffffd447)));
    c.restore();
  }

  /// Ferns, orchids, marigolds and grass on the terrace behind the wall's lip.
  static void back(Canvas c, RegionScene s, Size size) {
    final h = size.height;
    if (!(h > 1)) return;
    final span = s.period(Depth.near);
    // Roots sit a hair under the ridge line, hidden by the ground fill.
    Offset root(double x) => Offset(x * h, s.ridge(Depth.near, x, 0) * h + h * .005);
    for (final (x, k) in _backMarigolds) {
      _marigolds(c, root(x), h * k, 9600 + (x * 10).round());
    }
    for (final (x, ht, dir) in _backOrchids) {
      _orchid(c, root(x), h * ht, dir);
    }
    for (final (x, len) in _backFerns) {
      final at = root(x);
      _fern(c, at.dx, at.dy, h * len, 9650 + (x * 10).round());
    }
    final dark = Path(), mid = Path(), lit = Path();
    for (var i = 0; i < 28; i++) {
      final x = span * (i + .5 + (Sketch.hash(9700 + i) - .5) * .8) / 28;
      final at = root(x);
      _tuft(
        dark,
        mid,
        lit,
        at.dx,
        at.dy,
        h * (.011 + .016 * Sketch.hash(9760 + i)),
        9800 + i * 17,
        5 + (i % 3) * 2,
      );
    }
    _drawTufts(c, dark, mid, lit);
  }
}
