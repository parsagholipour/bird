import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Everything the Pirate Captain's water needs to know about one moment.
/// All lengths are in screen heights; [surface] is the drawn surface's y
/// at a screen x (the rules' water line plus the rolling waves).
final class SeaMoment {
  const SeaMoment({
    required this.level,
    required this.distance,
    required this.t,
    required this.churn,
    required this.rush,
    required this.drip,
    required this.pour,
    required this.surface,
    required this.reduced,
    required this.bowX,
    required this.sternX,
    required this.railY,
    this.heave,
    this.lift = 0,
    this.defeatK,
    this.ship = 1,
  });

  /// The rules' water line.
  final double level;
  final double distance;

  /// Seconds on the simulation clock; 0 under Reduced Motion.
  final double t;

  /// How hard the sea churns (warning, surge, arrival), 0 to 1.
  final double churn;

  /// The surge sweeping upward, 0 to 1.
  final double rush;

  /// The retreat: foam sliding back down the face of the water, 0 to 1.
  final double drip;

  /// Water pouring off the deck back into the sea, 0 to 1.
  final double pour;
  final double Function(double x) surface;
  final bool reduced;

  /// Where the hull meets the water at the bow and at the stern.
  final double bowX, sternX;

  /// The hull's rail, where the deck water spills over.
  final double railY;

  /// The swell that heaves up over the wreck after the defeat, and how high
  /// it stands at its crown.
  final double Function(double x)? heave;
  final double lift;

  /// Seconds since the wreck burst, while it sinks.
  final double? defeatK;

  /// How much of the ship is still afloat, 1 to 0: its bow wave, wash and
  /// shadow go with it.
  final double ship;
}

/// The Pirate Captain's water: a layered turquoise-to-navy body with cartoon
/// wave crescents, light and sparkle, a lacy foam crest, the bow wave and
/// stern wash of the ship, and a little flotsam. Everything follows the
/// simulation clock and the course, so pause and replay seeking stay exact.
abstract final class PirateSeaWater {
  static const foam = Color(0xfff6fffc), foamShade = Color(0xffbdeeee);
  static const ink = Color(0xff0f2c46);
  static const _light = Color(0xffbafff0), _aqua = Color(0xff62e6d6);
  static const _surf = Color(0xff35b9c5), _shallow = Color(0xff1f93b7);
  static const _mid = Color(0xff1b6a9c), _deep = Color(0xff193f7b);
  static const _abyss = Color(0xff142654);
  static const _backTop = Color(0xff2b8fb0), _backLit = Color(0xff8fe8e0);
  static const _wood = Color(0xffa8683f), _woodDark = Color(0xff55301f);
  static const _weed = Color(0xff3f9a62), _weedDark = Color(0xff1f5b45);

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));
  static Paint _stroke(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  static double _hash(int a, [int b = 0]) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// [x] wrapped into the visible width with a margin, for things that
  /// slide left with the course.
  static double _slide(double x, double span) =>
      ((x % span) + span) % span - .2;

  /// The surface as a path across the screen.
  static Path line(Size size, double Function(double x) y) {
    final h = size.height, w = size.width;
    final path = Path();
    final step = math.max(4.0, w / 160);
    for (var x = -step; x <= w + step; x += step) {
      final py = y(x / h) * h;
      x == -step ? path.moveTo(x, py) : path.lineTo(x, py);
    }
    return path;
  }

  static Path _below(Path top, Size size) => Path.from(top)
    ..lineTo(size.width + 20, size.height + 20)
    ..lineTo(-20, size.height + 20)
    ..close();

  /// A tapered crescent: a wave cap whose ends thin to nothing.
  static void _crescent(
    Path p,
    double x0,
    double x1,
    double y,
    double rise,
    double thick,
  ) {
    final mid = (x0 + x1) / 2;
    p
      ..moveTo(x0, y)
      ..quadraticBezierTo(mid, y - rise * 2, x1, y)
      ..quadraticBezierTo(mid, y - (rise - thick) * 2, x0, y);
  }

  // ---------------------------------------------------------------- back --

  /// The darker swell just behind the ship, so the hull sits in the water
  /// rather than on a flat line.
  static void back(
    Canvas c,
    Size size,
    double level,
    double Function(double x) top,
    SeaMoment m,
  ) {
    final h = size.height, w = size.width;
    final crest = line(size, top);
    c.drawPath(
      _below(crest, size),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_backTop, _deep],
            ).createShader(
              Rect.fromLTRB(0, (level - .01) * h, w, (level + .12) * h),
            ),
    );
    // A pale sheen under the crest, then the crest itself.
    c.drawPath(
      crest.shift(Offset(0, h * .008)),
      _stroke(_light, h * .012, .16),
    );
    c.drawPath(crest, _stroke(_backLit, h * .004, .85));
    // Flecks of foam ride the far crest.
    final gap = .07;
    final first = ((m.distance * .8 - .1) / gap).floor();
    for (var k = first; (k * gap - m.distance * .8) * h < w + 10; k++) {
      if (_hash(k, 61) < .4) continue;
      final x = k * gap - m.distance * .8 + _hash(k, 62) * .03;
      c.drawCircle(
        Offset(x * h, (top(x) + .004) * h),
        h * (.0028 + _hash(k, 63) * .002),
        _fill(foam, .6),
      );
    }
  }

  // --------------------------------------------------------------- front --

  static void front(Canvas c, Size size, SeaMoment m) {
    final h = size.height, w = size.width;
    final level = m.level;
    final span = w / h + .4;
    final surface = line(size, m.surface);
    final body = _below(surface, size);
    final depth = Rect.fromLTRB(0, (level - m.lift) * h, w, (level + .34) * h);
    // The top of the water stays a little clear, so the hull shows through
    // just under the surface.
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _surf.withValues(alpha: .7),
            _surf.withValues(alpha: .86),
            _shallow,
            _mid,
            _deep,
            _abyss,
          ],
          stops: const [0, .07, .16, .38, .7, 1],
        ).createShader(depth),
    );
    c.save();
    c.clipPath(body);
    if (m.ship > .01) _hullShadow(c, h, m);
    // A glassy band just under the crest: the surface has thickness.
    c.drawPath(
      surface.shift(Offset(0, h * .013)),
      _stroke(_aqua, h * .022, .26),
    );
    if (level < .82) _shafts(c, h, w, m, span);
    _rows(c, h, w, m);
    _caustics(c, h, m, span);
    if (m.rush > .02 && !m.reduced) _rushStreaks(c, h, m, span);
    if (m.drip > .02 && !m.reduced) _drips(c, h, m, span);
    _weedFronds(c, h, m);
    if (m.ship > .01) _wakeBelow(c, h, m);
    if (m.defeatK != null && !m.reduced) _boil(c, h, m);
    if (m.churn > .05) _bubbles(c, h, m, span);
    // The sea deepens into the navy at the bottom of the screen.
    final floor = Rect.fromLTRB(0, (level + .05) * h, w, h);
    if (floor.height > 2) {
      c.drawRect(
        floor,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_abyss.withValues(alpha: 0), _abyss.withValues(alpha: .4)],
          ).createShader(floor),
      );
    }
    c.restore();
    _crest(c, h, w, m, surface, span);
    if (m.ship > .01) _bowWave(c, h, m);
    _flotsam(c, h, w, m);
    if (m.churn > .05 && !m.reduced) _spray(c, h, m, span);
    if (m.pour > .02 && !m.reduced) _pour(c, h, m);
  }

  /// The ship's shadow darkens the water under the hull.
  static void _hullShadow(Canvas c, double h, SeaMoment m) {
    final hull = Rect.fromLTRB(
      m.bowX * h,
      (m.level + .004) * h,
      m.sternX * h,
      (m.level + .075) * h,
    );
    c.save();
    c.translate(hull.center.dx, hull.center.dy);
    c.scale(hull.width / hull.height, 1);
    final shade = Rect.fromCircle(
      center: Offset.zero,
      radius: hull.height * .8,
    );
    c.drawCircle(
      Offset.zero,
      shade.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _abyss.withValues(alpha: .38 * m.ship),
            _abyss.withValues(alpha: 0),
          ],
        ).createShader(shade),
    );
    c.restore();
  }

  /// Soft shafts of light angle down through deep water.
  static void _shafts(Canvas c, double h, double w, SeaMoment m, double span) {
    final depth = math.min(.3, 1 - m.level);
    for (var i = 0; i < 5; i++) {
      final x = _slide(i * .43 + _hash(i, 71) * .3 - m.distance * .5, span);
      final sway = m.reduced ? 0.0 : math.sin(m.t * .5 + i * 1.9) * .012;
      final top = m.level + .006;
      final half = .022 + _hash(i, 72) * .02;
      final lean = .07 + _hash(i, 73) * .04;
      for (final (k, alpha) in const [(1.0, .05), (.55, .05)]) {
        final ray = Path()
          ..moveTo((x - half * k) * h, top * h)
          ..lineTo((x + half * k) * h, top * h)
          ..lineTo((x + half * .15 * k + lean + sway) * h, (top + depth) * h)
          ..lineTo((x - half * .15 * k + lean + sway) * h, (top + depth) * h)
          ..close();
        c.drawPath(ray, _fill(_light, alpha));
      }
    }
  }

  /// Rows of cartoon wave caps recede into the deep, each drifting with the
  /// course at its own depth: tapered light crescents over dark ones.
  static void _rows(Canvas c, double h, double w, SeaMoment m) {
    for (var row = 0; row < 7; row++) {
      final depth = .026 + row * .036 + row * row * .006;
      final y = (m.level + depth) * h;
      if (y > h + h * .02) break;
      final len = h * (.11 + row * .026);
      final rise = h * (.0075 + row * .0015);
      final drift =
          m.distance * h * (.8 + row * .07) +
          (m.reduced ? 0 : m.t * h * .012 * (row.isEven ? 1 : -1));
      final light = Path(), shade = Path();
      final first = (drift / len).floor() - 1;
      for (var k = first; k * len - drift < w + len; k++) {
        final hv = _hash(k, row + 50);
        if (hv < .26) continue;
        final xc = (k + .5 + (hv - .5) * .5) * len - drift;
        final a = len * (.26 + .2 * _hash(k, row + 70));
        final bob = m.reduced ? 0.0 : math.sin(m.t * 1.3 + k * 1.7) * h * .0018;
        final cy = y + (_hash(k, row + 90) - .5) * h * .012 + bob;
        _crescent(light, xc - a, xc + a, cy, rise, rise * .55);
        _crescent(shade, xc - a, xc + a, cy + h * .0065, rise, rise * .55);
      }
      final fade = 1 - row * .09;
      c.drawPath(shade, _fill(_abyss, .3 * fade));
      c.drawPath(light, _fill(_light, .5 * fade));
    }
  }

  /// Light wobbles across the shallows in lens-shaped patches, and the odd
  /// sparkle twinkles on the crest.
  static void _caustics(Canvas c, double h, SeaMoment m, double span) {
    for (var i = 0; i < 12; i++) {
      final lane = i % 4;
      final x = _slide(
        i * .31 + _hash(i, 3) * .5 - m.distance * (.9 + lane * .04),
        span,
      );
      final y = m.level + .022 + lane * .022 + _hash(i, 5) * .014;
      if (y > 1.02) continue;
      final shimmer = m.reduced ? .7 : .5 + .5 * math.sin(m.t * 1.7 + i * 2.1);
      final l = h * (.026 + _hash(i, 7) * .03) * (1 + lane * .15);
      final tall = h * (.0034 + lane * .0007);
      final p = Path()
        ..moveTo(x * h - l, y * h)
        ..quadraticBezierTo(x * h, y * h - tall * 2, x * h + l, y * h)
        ..quadraticBezierTo(x * h, y * h + tall * 2, x * h - l, y * h)
        ..close();
      c.drawPath(p, _fill(_light, (.34 - lane * .05) * shimmer));
    }
    for (var i = 0; i < 7; i++) {
      final tw = m.reduced
          ? (i.isEven ? .8 : -1.0)
          : math.sin(m.t * 2.6 + i * 2.4 + _hash(i, 9) * 6);
      if (tw < .25) continue;
      final x = _slide(i * .53 + _hash(i, 13) * .4 - m.distance * .95, span);
      final y = m.level + .012 + _hash(i, 15) * .045;
      if (y > 1.0) continue;
      final r = h * (.006 + _hash(i, 17) * .006) * (tw - .1);
      final p = Offset(x * h, y * h);
      final star = Path()
        ..moveTo(p.dx, p.dy - r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r * .55, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r * .55, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
        ..close();
      c.drawPath(star, _fill(foam, .9));
    }
  }

  /// Wisps of white water race upward through a surging sea, each a slim
  /// tapered curl with a bead of foam at its head.
  static void _rushStreaks(Canvas c, double h, SeaMoment m, double span) {
    final wisps = Path(), beads = Path();
    var alpha = 0.0;
    for (var i = 0; i < 18; i++) {
      final x = _slide(i * .19 + _hash(i, 81) * .12 - m.distance, span);
      final life = (m.t * 1.15 + _hash(i, 83)) % 1;
      final len = h * (.04 + .09 * _hash(i, 85)) * (.4 + m.rush * .6);
      final y0 = (m.level + .04 + (1 - life) * .3) * h;
      final lean = h * (_hash(i, 87) - .5) * .02;
      final bulge = h * (.004 + _hash(i, 89) * .004);
      wisps
        ..moveTo(x * h, y0)
        ..quadraticBezierTo(
          x * h + bulge + lean,
          y0 - len * .5,
          x * h + lean,
          y0 - len,
        )
        ..quadraticBezierTo(
          x * h - bulge * .3 + lean,
          y0 - len * .5,
          x * h,
          y0,
        );
      beads.addOval(
        Rect.fromCircle(
          center: Offset(x * h + lean, y0 - len),
          radius: h * .0034,
        ),
      );
      alpha += math.sin(life * math.pi) / 18;
    }
    final a = m.rush * (.35 + .3 * alpha);
    c.drawPath(wisps, _fill(foam, a));
    c.drawPath(beads, _fill(foam, a));
  }

  /// As the tide falls foam slides down the face of the water in slow drips:
  /// each a tapered streak hanging from the crest with a bead at its foot.
  static void _drips(Canvas c, double h, SeaMoment m, double span) {
    final streaks = Path(), beads = Path();
    for (var i = 0; i < 20; i++) {
      final x = _slide(i * .11 + _hash(i, 91) * .1 - m.distance, span);
      final life = (m.t * .45 + _hash(i, 93)) % 1;
      final top = m.surface(x) + .006;
      final foot = top + .014 + life * .11 * (.55 + _hash(i, 97));
      final wide = (.0032 + _hash(i, 99) * .0028) * (1 - life * .4);
      streaks
        ..moveTo((x - wide) * h, top * h)
        ..lineTo((x + wide) * h, top * h)
        ..lineTo((x + wide * .35) * h, foot * h)
        ..lineTo((x - wide * .35) * h, foot * h)
        ..close();
      beads.addOval(
        Rect.fromCircle(
          center: Offset(x * h, foot * h),
          radius: wide * h * 1.25,
        ),
      );
    }
    final a = m.drip * .85;
    c.drawPath(streaks, _fill(foam, a * .75));
    c.drawPath(beads, _fill(foam, a));
  }

  /// Seaweed hangs below any floating knot of it.
  static void _weedFronds(Canvas c, double h, SeaMoment m) {
    for (final (x, k) in _flotsamAt(m)) {
      if (_hash(k, 92) < .4 || _hash(k, 92) > .75) continue;
      final y = m.surface(x) + .004;
      for (var j = 0; j < 4; j++) {
        final dx = (j - 1.5) * .009;
        final sway = m.reduced ? 0.0 : math.sin(m.t * 1.4 + j * 1.3 + k) * .006;
        final len = .026 + _hash(k, 100 + j) * .03;
        final frond = Path()
          ..moveTo((x + dx) * h, y * h)
          ..quadraticBezierTo(
            (x + dx + sway + dx * .8) * h,
            (y + len * .5) * h,
            (x + dx + sway * 1.6) * h,
            (y + len) * h,
          );
        c.drawPath(frond, _stroke(_weedDark, h * .0085, .8));
        c.drawPath(frond, _stroke(_weed, h * .0048, .95));
      }
    }
  }

  /// Water streams past the hull and trails in streaks from the stern.
  static void _wakeBelow(Canvas c, double h, SeaMoment m) {
    final light = Path(), dark = Path();
    // Along the hull, from the bow to the stern.
    final run = m.sternX - m.bowX;
    for (var i = 0; i < 5; i++) {
      final k = m.reduced ? (i * .21) % 1 : (m.t * .12 + i * .21) % 1;
      final half = run * (.08 + _hash(i, 131) * .07);
      final x = m.bowX + run * (.08 + k * .84);
      final y = m.surface(x) + .015 + (i % 3) * .012 + _hash(i, 133) * .004;
      _lens(light, x * h, y * h, half * h, h * .0032);
      _lens(dark, (x + half * .2) * h, (y + .006) * h, half * h * .9, h * .003);
    }
    // Trailing behind the stern.
    final sx = m.sternX * h;
    for (var i = 0; i < 6; i++) {
      final k = m.reduced ? (i * .17) % 1 : (m.t * .3 + i * .17) % 1;
      final x = sx + h * (.015 + k * .34);
      final y = m.surface(m.sternX + k * .3) * h + h * (.012 + (i % 3) * .013);
      final half = h * (.03 + _hash(i, 121) * .03) * (1 - k * .4);
      _lens(light, x, y, half, h * .0034);
      _lens(dark, x + half * .2, y + h * .007, half * .9, h * .003);
    }
    c.drawPath(dark, _fill(_abyss, .22 * m.ship));
    c.drawPath(light, _fill(foam, .45 * m.ship));
  }

  static void _lens(Path p, double x, double y, double half, double tall) => p
    ..moveTo(x - half, y)
    ..quadraticBezierTo(x, y - tall * 2, x + half, y)
    ..quadraticBezierTo(x, y + tall * 2, x - half, y)
    ..close();

  /// Bubbles boil up where the wreck went under.
  static void _boil(Canvas c, double h, SeaMoment m) {
    final k = m.defeatK!;
    final fade = _ramp(k, .3, .6) * (1 - _ramp(k, 1.6, 2.2));
    for (var i = 0; fade > 0 && i < 16; i++) {
      final life = (k * 1.2 + _hash(i, 31)) % 1;
      final x =
          (m.bowX + (m.sternX - m.bowX) * (.1 + .8 * _hash(i, 33))) * h +
          math.sin(life * 9 + i) * h * .006;
      final top = m.level - (m.heave?.call(x / h) ?? 0);
      final y = (top + .01 + .16 * (1 - life)) * h;
      final r = h * (.004 + (i % 3) * .0025) * (.6 + life * .6);
      c.drawCircle(Offset(x, y), r, _fill(foam, .25 * fade));
      c.drawCircle(
        Offset(x, y),
        r,
        _stroke(foam, h * .0018, fade * (.4 + .6 * life)),
      );
    }
  }

  static double _ramp(double v, double a, double b) =>
      ((v - a) / (b - a)).clamp(0.0, 1.0);

  /// Strings of bubbles stream up through a churning sea.
  static void _bubbles(Canvas c, double h, SeaMoment m, double span) {
    for (var i = 0; i < 14; i++) {
      final x = _slide(i * .19 + _hash(i, 9) * .12 - m.distance, span);
      final life = (m.t * .9 + _hash(i, 11)) % 1;
      for (var j = 0; j < 3; j++) {
        final k = (life + j * .06) % 1;
        final y = m.level + .02 + (1 - k) * .3;
        final wobble = math.sin(k * 14 + i) * .004;
        final a = m.churn * .6 * math.sin(k * math.pi);
        final p = Offset((x + wobble) * h, y * h);
        c.drawCircle(p, h * (.0037 - j * .0008), _fill(_light, a * .3));
        c.drawCircle(p, h * (.0037 - j * .0008), _stroke(_light, h * .0022, a));
      }
    }
  }

  // --------------------------------------------------------------- crest --

  /// The crest: a lacy fringe of foam hanging under a crisp ink-edged white
  /// line. The line sits on the rules' surface; the fringe hangs below it, a
  /// continuous scalloped band whose lobes swell with the churn and heap up
  /// against the hull.
  static void _crest(
    Canvas c,
    double h,
    double w,
    SeaMoment m,
    Path surface,
    double span,
  ) {
    final gap = .036 - m.churn * .008;
    final first = ((m.distance - .08) / gap).floor();
    final xs = <double>[], pinch = <double>[], depth = <double>[];
    for (var k = first; (k * gap - m.distance) * h < w + 40; k++) {
      xs.add((k + (_hash(k, 2) - .5) * .5) * gap - m.distance);
      var d = (.0062 + _hash(k, 1) * .0064) * (1 + m.churn * .8 + m.rush * .5);
      final mid = xs.last + gap / 2;
      // The hull pushes the foam up into bigger heaps at its ends.
      d *=
          1 +
          .9 * math.max(0, 1 - (mid - m.bowX).abs() / .05) +
          .8 * math.max(0, 1 - (mid - m.sternX - .05).abs() / .1);
      depth.add(d);
      pinch.add(d * (.32 + _hash(k, 4) * .2));
    }
    final fringe = Path()
      ..moveTo(xs.first * h, (m.surface(xs.first) + pinch.first) * h);
    for (var i = 0; i + 1 < xs.length; i++) {
      final x0 = xs[i], x1 = xs[i + 1], dx = x1 - x0;
      final y0 = m.surface(x0) + pinch[i], y1 = m.surface(x1) + pinch[i + 1];
      // Round, bulging lobes with narrow necks: foam, not teeth.
      final low = (math.max(y0, y1) + depth[i] * 1.36) * h;
      fringe.cubicTo(
        (x0 - dx * .3) * h,
        low,
        (x1 + dx * .3) * h,
        low,
        x1 * h,
        y1 * h,
      );
    }
    for (var i = xs.length - 1; i >= 0; i--) {
      fringe.lineTo(xs[i] * h, (m.surface(xs[i]) - .001) * h);
    }
    fringe.close();
    c.drawPath(fringe.shift(Offset(0, h * .0035)), _fill(ink, .4));
    c.drawPath(fringe.shift(Offset(0, h * .0018)), _fill(foamShade));
    c.drawPath(fringe, _fill(foam));
    // Loose bubbles of foam let go under the fringe.
    for (var i = 1; i + 1 < xs.length; i += 2) {
      if (_hash(first + i, 6) < .45) continue;
      final x = xs[i] + gap * .5, y = m.surface(x) + depth[i] * 1.5 + .003;
      c.drawCircle(
        Offset(x * h, y * h),
        h * (.0022 + _hash(first + i, 8) * .0016),
        _fill(foam, .85),
      );
    }
    // The crisp line, edged in ink so it reads on any scenery.
    c.drawPath(surface, _stroke(ink, h * .0112, .34));
    c.drawPath(surface, _stroke(foam, h * .0062));
  }

  /// The bow wave: foam heaped and curling up against the hull's stem,
  /// throwing a few drops ahead of it.
  static void _bowWave(Canvas c, double h, SeaMoment m) {
    final bx = m.bowX * h, by = m.surface(m.bowX) * h;
    final k = m.reduced ? .95 : .9 + .1 * math.sin(m.t * 2.4);
    final heap = Path();
    for (final (dx, dy, r) in const [
      (-.031, .001, .0062),
      (-.024, -.005, .0066),
      (-.016, -.011, .0072),
      (-.008, -.016, .0076),
      (.001, -.017, .0068),
      (-.026, .004, .0056),
      (-.013, -.004, .0072),
      (.004, -.007, .0068),
      (.012, -.001, .006),
    ]) {
      heap.addOval(
        Rect.fromCircle(
          center: Offset(bx + dx * .72 * h, by + dy * h * k),
          radius: r * .9 * h,
        ),
      );
    }
    c.drawPath(heap.shift(Offset(0, h * .0035)), _fill(ink, .42 * m.ship));
    c.drawPath(heap.shift(Offset(0, h * .002)), _fill(foamShade, m.ship));
    c.drawPath(heap, _fill(foam, m.ship));
    // Drops fly ahead of the stem.
    for (var i = 0; i < 4; i++) {
      final life = m.reduced ? .4 : (m.t * 1.3 + i * .27) % 1;
      final p = Offset(
        bx - h * (.004 + i * .005 + life * .006),
        by - h * (.02 + math.sin(life * math.pi) * .014 + i * .002),
      );
      c.drawCircle(
        p,
        h * (.0034 - i * .0004),
        _fill(foam, (m.reduced ? .9 : math.sin(life * math.pi)) * m.ship),
      );
    }
  }

  // ------------------------------------------------------------- flotsam --

  /// Screen x and world cell of the flotsam in view: a plank, a knot of
  /// seaweed or a crate every few screens.
  static Iterable<(double, int)> _flotsamAt(SeaMoment m) sync* {
    const cell = 2.3;
    final first = ((m.distance - .3) / cell).floor();
    for (var k = first; k * cell - m.distance < 3.2; k++) {
      if (_hash(k, 90) < .5) continue;
      final x = (k + .15 + .7 * _hash(k, 93)) * cell - m.distance;
      if (x < -.2 || x > 3.2) continue;
      // Keep clear of the ship: it has its own wash.
      if (x > m.bowX - .1 && x < m.sternX + .35) continue;
      yield (x, k);
    }
  }

  /// A little flotsam rides the crest, half sunk and ringed with foam.
  static void _flotsam(Canvas c, double h, double w, SeaMoment m) {
    for (final (x, k) in _flotsamAt(m)) {
      if (x * h > w + 20) continue;
      final kind = _hash(k, 92);
      final y = m.surface(x);
      final slope = math
          .atan2(m.surface(x + .012) - m.surface(x - .012), .024)
          .clamp(-.06, .06);
      final at = Offset(x * h, (y + .008) * h);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(slope);
      if (kind < .4) {
        final plank = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: h * .06,
            height: h * .012,
          ),
          Radius.circular(h * .003),
        );
        c.drawRRect(plank.inflate(h * .0018), _fill(_woodDark));
        c.drawRRect(plank, _fill(_wood));
        c.drawLine(
          Offset(-h * .022, -h * .002),
          Offset(h * .02, -h * .002),
          _stroke(foam, h * .0018, .35),
        );
        c.drawCircle(Offset(-h * .02, 0), h * .0014, _fill(_woodDark));
        c.drawCircle(Offset(h * .02, 0), h * .0014, _fill(_woodDark));
      } else if (kind < .75) {
        const knots = [(-.008, .0058), (0.0, .0068), (.008, .0056)];
        for (final (dx, r) in knots) {
          c.drawCircle(Offset(dx * h, 0), h * (r + .0016), _fill(_weedDark));
        }
        for (final (dx, r) in knots) {
          c.drawCircle(Offset(dx * h, 0), h * r, _fill(_weed));
        }
        c.drawCircle(
          Offset(-h * .002, -h * .0015),
          h * .0026,
          _fill(_light, .5),
        );
      } else {
        // A crate, sunk to its lid: the water tints what is below the line.
        final crate = Rect.fromCenter(
          center: Offset(0, h * .005),
          width: h * .03,
          height: h * .026,
        );
        c.drawRect(crate.inflate(h * .002), _fill(_woodDark));
        c.drawRect(crate, _fill(_wood));
        c.drawLine(
          crate.topLeft,
          crate.bottomRight,
          _stroke(_woodDark, h * .0024),
        );
        c.drawLine(
          crate.bottomLeft,
          crate.topRight,
          _stroke(_woodDark, h * .0024),
        );
        c.drawRect(
          Rect.fromLTRB(
            crate.left,
            crate.top + h * .008,
            crate.right,
            crate.bottom,
          ),
          _fill(_mid, .5),
        );
      }
      c.restore();
      // Foam rings its waterline.
      final ring = Offset(x * h, (y + .004) * h);
      for (var i = -2; i <= 2; i++) {
        c.drawCircle(
          ring + Offset(i * h * .012, i.abs() * h * .0006),
          h * (.0042 - i.abs() * .0005),
          _fill(foam, .9),
        );
      }
    }
  }

  // --------------------------------------------------------------- spray --

  /// Spray jumps off the churning crest, fine and see-through so it never
  /// reads as the water line.
  static void _spray(Canvas c, double h, SeaMoment m, double span) {
    for (var i = 0; i < 20; i++) {
      final life = (m.t * 1.3 + _hash(i, 21)) % 1;
      final x = _slide(i * .13 + _hash(i, 23) * .1 - m.distance, span);
      final hop = math.sin(life * math.pi) * .02 * (.5 + _hash(i, 25));
      // Spray is thrown clear of the line: it never touches its ink edge.
      c.drawCircle(
        Offset(x * h, (m.surface(x) - .0105 - hop) * h),
        h * .0032 * (1 - life * .5),
        _fill(foam, math.min(1.0, m.churn + m.rush * .5) * (1 - life) * .45),
      );
    }
  }

  /// Water sheets off the deck and down the hull back into the sea.
  static void _pour(Canvas c, double h, SeaMoment m) {
    final left = m.bowX + .07, right = m.sternX - .06;
    for (var i = 0; i < 6; i++) {
      final x = left + (right - left) * (i + .3 + _hash(i, 111) * .4) / 6;
      final sway = math.sin(m.t * 7 + i * 2.3) * .0015;
      final top = m.railY + .004;
      final bottom = m.surface(x) + .003;
      if (bottom <= top) continue;
      final flow = (m.t * 1.6 + _hash(i, 113)) % 1;
      final a = m.pour * m.ship * (.55 + .3 * math.sin(flow * math.pi));
      final wide = h * (.0058 + _hash(i, 115) * .004);
      c.drawLine(
        Offset((x + sway) * h, top * h),
        Offset((x - sway) * h, bottom * h),
        _stroke(ink, wide + h * .002, a * .3),
      );
      c.drawLine(
        Offset((x + sway) * h, top * h),
        Offset((x - sway) * h, bottom * h),
        _stroke(_light, wide, a),
      );
      c.drawCircle(
        Offset((x - sway) * h, bottom * h),
        wide * 1.5,
        _fill(foam, a),
      );
    }
  }
}
