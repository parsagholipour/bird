import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'boss_motion.dart';

/// The water and wood the Pirate Captain's fight throws around: the towering
/// splash of a cannonball, the light and comic dunk of the bird, and the
/// glancing knock of a shot off the armored hull.
///
/// Every effect is a pure function of its age in seconds, so pause and replay
/// seeking are exact. Sizes are in screen heights ([h]) and every effect is
/// drawn round its point of contact, `at`, on the water line (or the hull).
/// With Reduced Motion the pose holds still and only fades.
abstract final class PirateSplashArt {
  static const _foam = Color(0xfff2fffb), _crest = Color(0xff8fe3dc);
  static const _lit = Color(0xffd6faf3), _shade = Color(0xff3aa9b6);
  static const _hollow = Color(0xff1d6a86), _line = Color(0xff123049);
  static const _woodDark = Color(0xff55301f), _wood = Color(0xffa8683f);
  static const _fresh = Color(0xffeebb7c), _hot = Color(0xffffe08a);
  static const _ember = Color(0xffff8a2b), _dust = Color(0xfff6e7c9);

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

  static double _ramp(double v, double a, double b) => BossMotion.ramp(v, a, b);
  static double _ease(double t) => BossMotion.ease(t);
  static double _out(double t) => 1 - (1 - t) * (1 - t) * (1 - t);

  /// A closed, rounded shape through [p]: each point pulls the outline
  /// toward it without quite reaching it, so organic water reads soft.
  static Path _blob(List<Offset> p) {
    final n = p.length;
    Offset mid(int i) => (p[i % n] + p[(i + 1) % n]) / 2;
    final start = mid(n - 1);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final m = mid(i);
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    return path..close();
  }

  static Path _star(Offset c, double outer, double inner, int points, double a0) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = a0 + i * math.pi / points;
      final q = c + Offset(math.cos(a), math.sin(a)) * (i.isEven ? outer : inner);
      i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    return path..close();
  }

  // ------------------------------------------------------------- shared --

  /// Rings spreading over the water in perspective: a dark edge under a
  /// white one so they read on the sea. [flat] is how squashed they are.
  static void _rings(
    Canvas c,
    double h,
    Offset at,
    double age,
    bool reduced,
    double fade, {
    required int count,
    required double reach,
    required double gap,
    required double life,
    double weight = 1,
    double flat = .16,
  }) {
    for (var i = 0; i < count; i++) {
      final k = reduced ? .3 + i * .22 : (age - i * gap) / life;
      if (k <= 0 || k >= 1) continue;
      final e = _out(k);
      final w = h * (.05 + reach * e * (1 - i * .12));
      final ry = w * flat / 2;
      final rect = Rect.fromCenter(
        center: at + Offset(0, ry * .8 + h * .003),
        width: w,
        height: ry * 2,
      );
      final a = (1 - k) * (1 - k * .5) * fade;
      final thin = 1 - k * .55;
      c.drawOval(rect, _stroke(_line, h * .0085 * weight * thin, .3 * a));
      c.drawOval(rect, _stroke(_foam, h * .0045 * weight * thin, a));
    }
  }

  /// A patch of boiling foam on the surface where the water went in.
  static void _foamPad(
    Canvas c,
    double h,
    Offset at,
    double age,
    bool reduced,
    double fade, {
    required double reach,
    required int count,
    required double size,
    required int seed,
    double hold = .55,
  }) {
    final grow = reduced ? .8 : _ease(_ramp(age, .02, .22));
    final alpha = grow * (1 - _ramp(age, hold, hold + .5)) * fade;
    if (alpha <= 0) return;
    for (var i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : i / (count - 1) * 2 - 1;
      final r = h * size * (1 - t.abs() * .45) * (.75 + .5 * _hash(i, seed));
      final p =
          at +
          Offset(
            t * h * reach * grow,
            h * .003 + math.sin(i * 2.3 + seed) * h * .002 - r * .35,
          );
      c.drawCircle(p, r, _fill(_foam, alpha));
    }
    // A few bubbles sit in the foam and pop.
    if (!reduced) {
      for (var i = 0; i < 3; i++) {
        final k = _ramp(age, .18 + i * .12, .5 + i * .12);
        if (k <= 0 || k >= 1) continue;
        final p = at + Offset((_hash(i, seed + 9) - .5) * h * reach * 1.5, -h * .006);
        c.drawCircle(
          p,
          h * (.004 + .004 * k),
          _stroke(_line, h * .0034, .3 * (1 - k) * fade),
        );
        c.drawCircle(p, h * (.004 + .004 * k), _stroke(_foam, h * .002, (1 - k) * fade));
      }
    }
  }

  /// One flying drop: a teardrop that stretches along its flight and rounds
  /// off at the top of its arc, with a dark edge so it reads on any sky.
  static void _bead(
    Canvas c,
    double h,
    Offset p,
    Offset v,
    double r,
    double alpha, {
    Color color = _foam,
  }) {
    final speed = v.distance;
    final dir = speed < 1 ? const Offset(0, 1) : v / speed;
    final len = r * 1.2 + math.min(speed * .022, h * .03);
    final side = Offset(-dir.dy, dir.dx) * r * .92;
    final tail = Path()
      ..moveTo(p.dx + side.dx, p.dy + side.dy)
      ..lineTo(p.dx - dir.dx * len, p.dy - dir.dy * len)
      ..lineTo(p.dx - side.dx, p.dy - side.dy)
      ..close();
    final edge = _stroke(_line, h * .0034, .34 * alpha);
    c.drawPath(tail, edge);
    c.drawCircle(p, r, edge);
    c.drawPath(tail, _fill(color, alpha));
    c.drawCircle(p, r, _fill(color, alpha));
    if (r > h * .0048) {
      c.drawCircle(
        p + Offset(-r * .32, -r * .32),
        r * .3,
        _fill(const Color(0xffffffff), alpha),
      );
    }
  }

  /// A ring of drops thrown up from the surface, each on its own arc; a
  /// drop that lands leaves a tiny ring on the water.
  static void _spray(
    Canvas c,
    double h,
    Offset at,
    double age,
    bool reduced,
    double fade, {
    required int count,
    required double spread,
    required double slowest,
    required double fastest,
    required double gravity,
    required double size,
    required double lift,
    required double stagger,
    required int seed,
    double lean = 0,
  }) {
    for (var i = 0; i < count; i++) {
      final f = count == 1 ? .5 : i / (count - 1);
      final a =
          -math.pi / 2 + (f - .5) * 2 * spread + (_hash(i, seed + 3) - .5) * .2 + lean;
      final speed = h * (slowest + (fastest - slowest) * _hash(i, seed));
      final v = Offset(math.cos(a) * speed, math.sin(a) * speed);
      final g = h * gravity;
      final y0 = -h * lift * (.4 + .6 * _hash(i, seed + 7));
      final s = reduced ? .2 : age - stagger * ((i * 5) % count) / count;
      if (s < 0) continue;
      final p = at + Offset(v.dx * s, y0 + v.dy * s + g * s * s / 2);
      final r = h * size * (.6 + .8 * _hash(i, seed + 5));
      if (p.dy >= at.dy) {
        if (reduced) continue;
        // Landed: a tiny ring where it met the water.
        final land = (-v.dy + math.sqrt(v.dy * v.dy - 2 * g * y0)) / g;
        final k = (s - land) / .2;
        if (k <= 0 || k >= 1) continue;
        final w = h * (.012 + .026 * k) * (r / (h * size));
        c.drawOval(
          Rect.fromCenter(
            center: Offset(at.dx + v.dx * land, at.dy + h * .004),
            width: w,
            height: w * .32,
          ),
          _stroke(_foam, h * .003, (1 - k) * .9 * fade),
        );
        continue;
      }
      _bead(
        c,
        h,
        p,
        v + Offset(0, g * s),
        r,
        fade,
        color: i % 4 == 1 ? _lit : _foam,
      );
    }
  }

  // -------------------------------------------------------------- crown --

  /// A crown of water thrown up round the point of entry: [lobes] tapering
  /// fingers per side, [width] across and [height] tall at the middle.
  static void crown(
    Canvas c,
    double h,
    Offset at,
    double width,
    double height,
    int lobes,
    double fade, {
    int seed = 0,
  }) {
    if (height <= 0 || fade <= 0) return;
    crownBack(c, h, at, width, height, lobes, fade, seed);
    crownFront(c, h, at, width, height, lobes, fade, seed);
  }

  /// The far side of the crown, paler and behind whatever rises in it.
  static void crownBack(
    Canvas c,
    double h,
    Offset at,
    double width,
    double height,
    int lobes,
    double fade,
    int seed,
  ) {
    if (height <= 0 || fade <= 0) return;
    _fingers(c, h, at, width, height, lobes, fade, seed, front: false);
  }

  /// The near side of the crown, with its foam lip.
  static void crownFront(
    Canvas c,
    double h,
    Offset at,
    double width,
    double height,
    int lobes,
    double fade,
    int seed,
  ) {
    if (height <= 0 || fade <= 0) return;
    _fingers(c, h, at, width, height, lobes, fade, seed, front: true);
  }

  /// Half of the crown's ring seen from the side: a sheet of water whose top
  /// edge scallops into rounded, beaded tips and whose foot follows the
  /// ring's curve. The near half laps over the jet, the far half sits behind.
  static void _fingers(
    Canvas c,
    double h,
    Offset at,
    double width,
    double height,
    int lobes,
    double fade,
    int seed, {
    required bool front,
  }) {
    final tint = front ? _crest : Color.lerp(_crest, _shade, .5)!;
    final ry = width * .2;
    const per = 7;
    final steps = lobes * per;
    final top = <Offset>[], foot = <Offset>[];
    final tips = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final f = i / steps;
      final th = front ? math.pi - f * math.pi : math.pi + f * math.pi;
      final cx = math.cos(th), sy = math.sin(th);
      final phase = f * lobes + (front ? 0 : .5);
      final lobe = phase.floor(), local = phase - lobe;
      final hump = math.pow(math.sin(local * math.pi), .7).toDouble();
      final amp = .7 + .3 * _hash(lobe + (front ? 0 : 50), seed);
      final env = math.pow(math.sin(f * math.pi), .55).toDouble();
      final rise = height * env * amp * (.28 + .72 * hump);
      final baseY = at.dy + ry * sy;
      final x = at.dx + cx * width + cx * rise * .3;
      top.add(Offset(x, baseY - rise));
      foot.add(Offset(at.dx + cx * width, baseY));
      if (i % per == per ~/ 2) tips.add(Offset(x, baseY - rise));
    }
    final edge = Path()..moveTo(top.first.dx, top.first.dy);
    for (final q in top.skip(1)) {
      edge.lineTo(q.dx, q.dy);
    }
    final body = Path.from(edge);
    for (final q in foot.reversed) {
      body.lineTo(q.dx, q.dy);
    }
    body.close();
    c.drawPath(body, _stroke(_line, h * .0045, .5 * fade));
    c.drawPath(body, _fill(tint, fade * (front ? 1 : .9)));
    if (front) {
      // A bright foam edge and a lit face under the scallops.
      c.drawPath(
        edge.shift(Offset(0, height * .1 + h * .003)),
        _stroke(_foam, h * .0055, fade),
      );
      c.drawPath(
        edge.shift(Offset(0, height * .34)),
        _stroke(_lit, h * .0032, .7 * fade),
      );
    }
    for (final tip in tips) {
      final r = h * (front ? .0042 : .0034);
      c.drawCircle(tip + Offset(0, -r * .8), r + h * .0015, _fill(_line, .3 * fade));
      c.drawCircle(tip + Offset(0, -r * .8), r, _fill(_foam, fade));
    }
    if (front) {
      // The lip where the crown meets the sea.
      final lip = Rect.fromCenter(
        center: at + Offset(0, ry * .45),
        width: width * 2.05,
        height: ry * 2.1,
      );
      c.drawArc(lip, .15, math.pi - .3, false, _stroke(_line, h * .0075, .3 * fade));
      c.drawArc(lip, .15, math.pi - .3, false, _stroke(_foam, h * .0042, fade));
    }
  }

  // --------------------------------------------------------------- ball --

  /// A cannonball meeting the sea: a heavy coronet of water, a tall
  /// tapering jet that pinches off a drop and slumps back, rings rolling out
  /// over the water and foam left boiling, with a small rebound at the end.
  static void ball(
    Canvas c,
    double h,
    Offset at,
    double age, {
    required bool reduced,
    required int seed,
  }) {
    final fade = 1 - _ramp(age, .8, 1.15);
    if (fade <= 0) return;
    final u = reduced ? .24 : age;
    _rings(
      c, h, at, age, reduced, fade,
      count: 3, reach: .38, gap: .13, life: .9, flat: .15,
    );
    // The hole the ball punched, closing up.
    final hole = 1 - _ramp(u, .03, .22);
    if (hole > 0) {
      final w = h * (.05 + .05 * (1 - hole));
      final r = Rect.fromCenter(
        center: at + Offset(0, h * .006),
        width: w,
        height: w * .28,
      );
      c.drawOval(r, _fill(_hollow, .85 * hole * fade));
    }
    final rise = _out(_ramp(u, 0, .12));
    final slump = _ramp(u, .14, .58);
    final crownH = h * .1 * rise * (1 - slump * slump);
    final crownW = h * (.04 + .034 * _out(_ramp(u, 0, .34)));
    crownBack(c, h, at, crownW, crownH, 5, fade, seed);
    _jet(c, h, at, u, fade, seed);
    crownFront(c, h, at, crownW, crownH, 5, fade, seed);
    _foamPad(
      c, h, at, age, reduced, fade,
      reach: .062, count: 9, size: .0085, seed: seed,
    );
    _spray(
      c, h, at, age, reduced, fade,
      count: 11,
      spread: .62,
      slowest: .5,
      fastest: 1.0,
      gravity: 2.7,
      size: .0044,
      lift: .045,
      stagger: .1,
      seed: seed,
    );
    // The jet collapses and the water bounces back with a small plip.
    final bounce = _ramp(u, .52, .72) * (1 - _ramp(u, .72, .95));
    if (bounce > 0) {
      final tall = h * .05 * math.sin(bounce * math.pi / 2 + (1 - bounce) * 0) * bounce;
      final wide = h * .0085;
      final blob = _blob([
        at + Offset(-wide * 1.7, 0),
        at + Offset(-wide, -tall * .55),
        at + Offset(0, -tall * 1.05),
        at + Offset(wide, -tall * .55),
        at + Offset(wide * 1.7, 0),
      ]);
      c.drawPath(blob, _stroke(_line, h * .0045, .5 * fade));
      c.drawPath(blob, _fill(_crest, fade));
      c.drawCircle(
        at + Offset(-wide * .25, -tall * .55),
        wide * .38,
        _fill(_foam, fade),
      );
    }
  }

  /// The column of water: fat at the foot, drawn out to a soft tip, with a
  /// bulb at the head that pinches off as a drop once it peaks.
  static void _jet(Canvas c, double h, Offset at, double u, double fade, int seed) {
    final up = _out(_ramp(u, .02, .27));
    final down = _ease(_ramp(u, .3, .66));
    final tall = h * .2 * up * (1 - down);
    if (tall < h * .006) return;
    final foot = h * .034 * (1 - .3 * down), neck = h * .0135 * (1 - .25 * down);
    double half(double s) =>
        (neck + (foot - neck) * math.pow(1 - s, 2.3)) *
        (1 + .07 * math.sin(s * 8 + u * 22));
    // The head swells into a bulb just before it pinches off.
    final bulb = 1 + .5 * math.sin(math.pi * _ramp(u, .04, .25)) * (1 - down);
    final left = <Offset>[], right = <Offset>[];
    for (final s in const [0.0, .14, .34, .56, .76, .92]) {
      final w = half(s) * (s > .7 ? 1 + (bulb - 1) * (s - .7) / .22 : 1);
      left.add(at + Offset(-w, -tall * s));
      right.add(at + Offset(w, -tall * s));
    }
    final cap = neck * bulb;
    final body = _blob([
      at + Offset(-foot * 1.15, 0),
      ...left.skip(1),
      at + Offset(-cap * .7, -tall - cap * .55),
      at + Offset(0, -tall - cap * .95),
      at + Offset(cap * .7, -tall - cap * .55),
      ...right.skip(1).toList().reversed,
      at + Offset(foot * 1.15, 0),
    ]);
    c.drawPath(body, _fill(_crest, fade));
    // The shade side, the lit side and a bright core down the middle.
    c.save();
    c.clipPath(body);
    c.drawLine(
      at + Offset(foot * .62, -tall * .05),
      at + Offset(neck * .7, -tall * .95),
      _stroke(_shade, foot * .8, .9 * fade),
    );
    c.drawLine(
      at + Offset(-foot * .3, -tall * .04),
      at + Offset(-neck * .34, -tall * .92),
      _stroke(_foam, foot * .62, fade),
    );
    c.drawLine(
      at + Offset(-foot * .55, -tall * .18),
      at + Offset(-neck * .6, -tall * .56),
      _stroke(const Color(0xffffffff), foot * .16, .95 * fade),
    );
    c.restore();
    c.drawPath(body, _stroke(_line, h * .0048, .5 * fade));
    // Bubbles ride up inside the water.
    for (var i = 0; i < 2; i++) {
      final k = (u * 3 + i * .5) % 1;
      c.drawCircle(
        at + Offset(math.sin(k * 6 + i * 3) * neck * .3, -tall * (.15 + .6 * k)),
        h * .0028,
        _stroke(_line, h * .0022, .35 * fade),
      );
    }
    // The head drop pinches off the tip, rises a little and falls back.
    final s = u - .25;
    if (s > 0) {
      final g = h * 3.2;
      final y = h * .2 * _out(_ramp(.25, .02, .27)) + neck * 1.3 + h * .36 * s - g * s * s / 2;
      final p = at + Offset(0, -y);
      if (p.dy < at.dy) {
        _bead(c, h, p, Offset(0, -(h * .36 - g * s)), h * .0115, fade, color: _lit);
      }
    }
  }

  // --------------------------------------------------------------- bird --

  /// The bird dunking into the sea: lighter and sillier than a cannonball.
  /// A bloop dome pops into a fan of fine spray and two curling sheets, a
  /// comic ring bounces out over the water with a few speed lines above, and
  /// bubbles blub up from where it went under.
  static void bird(
    Canvas c,
    double h,
    Offset at,
    double age, {
    required bool reduced,
    required int seed,
  }) {
    final fade = 1 - _ramp(age, .7, 1.05);
    if (fade <= 0) return;
    final u = reduced ? .2 : age;
    _rings(
      c, h, at, age, reduced, fade,
      count: 2, reach: .3, gap: .11, life: .7, weight: 1.35, flat: .17,
    );
    // Bubbles blub up through the water to pop at the surface.
    for (var i = 0; i < 5; i++) {
      final k = reduced ? .5 : _ramp(age, .05 + i * .07, .68 + i * .05);
      if (k <= 0 || k > 1) continue;
      final r = h * (.006 + .004 * _hash(i, 5));
      final p =
          at +
          Offset(
            (_hash(i, 3) - .5) * h * .09 + math.sin(k * 9 + i * 2) * h * .006,
            h * (.004 + .075 * (1 - k) * (.7 + .5 * _hash(i, 9))),
          );
      if (k >= .96) {
        final pop = (k - .96) / .04;
        c.drawCircle(p, r * (1 + pop), _stroke(_foam, h * .0026, (1 - pop) * fade));
        continue;
      }
      c.drawCircle(p, r, _fill(_foam, .22 * fade));
      c.drawCircle(p, r, _stroke(_line, h * .0044, .28 * fade));
      c.drawCircle(p, r, _stroke(_foam, h * .0026, .95 * fade));
      c.drawCircle(p + Offset(-r * .35, -r * .35), r * .24, _fill(_foam, fade));
    }
    // The bloop: a dome of water swells and pops.
    final dome = reduced ? 0.0 : _ramp(age, 0, .05) * (1 - _ramp(age, .05, .11));
    if (dome > 0) {
      final w = h * .05, tall = h * .034 * dome;
      final r = Rect.fromLTRB(at.dx - w, at.dy - tall, at.dx + w, at.dy + tall);
      c.drawArc(r, math.pi, math.pi, true, _stroke(_line, h * .0045, .5 * fade));
      c.drawArc(r, math.pi, math.pi, true, _fill(_crest, fade));
      c.drawArc(
        r.deflate(h * .009),
        math.pi * 1.15,
        math.pi * .5,
        false,
        _stroke(_foam, h * .006, fade),
      );
    }
    final rise = u < .12 ? _out(u / .12) : math.max(0.0, 1 - (u - .12) / .5);
    final crownW = h * .04 * (1 + (1 - rise) * .3);
    crown(c, h, at, crownW, h * .04 * rise, 4, fade, seed: seed + 5);
    for (final side in [-1.0, 1.0]) {
      _sheet(c, h, at, side, rise, fade, seed);
    }
    _foamPad(
      c, h, at, age, reduced, fade,
      reach: .075, count: 7, size: .0075, seed: seed + 1, hold: .35,
    );
    _spray(
      c, h, at, age, reduced, fade,
      count: 15,
      spread: 1.05,
      slowest: .42,
      fastest: .95,
      gravity: 2.4,
      size: .0034,
      lift: .01,
      stagger: .1,
      seed: seed + 11,
    );
    // Comic speed lines fan out above the dunk.
    final lines = reduced ? .8 : _ramp(age, .02, .07) * (1 - _ramp(age, .13, .26));
    if (lines > 0) {
      final reach = h * (.062 + (reduced ? .015 : age * .14));
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + (i - 2) * .48;
        final d = Offset(math.cos(a), math.sin(a));
        final side = Offset(-d.dy, d.dx);
        final from = at + Offset(0, -h * .018) + d * reach;
        final to = from + d * h * (i == 2 ? .034 : .026);
        final wedge = Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx + side.dx * h * .0045, to.dy + side.dy * h * .0045)
          ..lineTo(to.dx - side.dx * h * .0045, to.dy - side.dy * h * .0045)
          ..close();
        c.drawPath(wedge, _stroke(_line, h * .0036, .26 * lines * fade));
        c.drawPath(wedge, _fill(_foam, lines * fade));
      }
    }
  }

  /// A thin curling sheet of water thrown out to one [side].
  static void _sheet(Canvas c, double h, Offset at, double side, double rise, double fade, int seed) {
    if (rise <= 0 || fade <= 0) return;
    final reach = 1 + (1 - rise) * .3;
    Offset q(double x, double y) => at + Offset(side * x * h * reach, -y * h * rise);
    final sheet = _blob([
      q(.012, 0),
      q(.022, .026),
      q(.05, .048),
      q(.086, .056),
      q(.104, .046),
      q(.088, .036),
      q(.066, .022),
      q(.056, 0),
    ]);
    c.drawPath(sheet, _stroke(_line, h * .0045, .5 * fade));
    c.drawPath(sheet, _fill(_crest, .92 * fade));
    // A paler, thinner face inside the sheet where the light comes through.
    c.save();
    c.translate(at.dx + side * h * .03, at.dy);
    c.scale(.62, .55);
    c.translate(-(at.dx + side * h * .03), -at.dy);
    c.drawPath(sheet, _fill(_lit, .55 * fade));
    c.restore();
    // A bright edge along the top and a bead at the curl.
    c.drawLine(q(.03, .03), q(.084, .05), _stroke(_foam, h * .0046, fade));
    c.drawCircle(q(.104, .046) + Offset(side * h * .004, -h * .002), h * .0058, _fill(_line, .3 * fade));
    c.drawCircle(q(.104, .046) + Offset(side * h * .004, -h * .002), h * .0046, _fill(_foam, fade));
    c.drawCircle(q(.114, .026), h * .0036, _fill(_foam, fade));
  }

  // -------------------------------------------------------------- knock --

  /// A shot glancing off the armored hull at [at]: a ringing flash and a
  /// ward arc where it bounced, sparks, splinters and a puff of dust, and a
  /// pale gouge left in the planking. [level] is the water line's y, under
  /// which the debris drops out of sight (with a plip). [power] scales the
  /// knock for a charged shot.
  static void knock(
    Canvas c,
    double h,
    Offset at,
    double age, {
    required bool reduced,
    required int seed,
    required double level,
    double power = 1,
  }) {
    final fade = 1 - _ramp(age, .3, .5);
    final u = reduced ? .1 : age;
    // Two puffs of dust the shot knocked loose drift up and away.
    for (var i = 0; i < 2; i++) {
      final k = reduced ? .3 : _ramp(age, .02 + i * .03, .3 + i * .04);
      if (k <= 0 || k >= 1) continue;
      final a = math.pi + (i * 2 - 1) * .55 + (_hash(i, seed) - .5) * .3;
      final p =
          at +
          Offset(math.cos(a) * .7, math.sin(a) - .55) *
              h * (.01 + .03 * _out(k)) * power;
      final r = h * (.008 + .008 * k + i * .002) * power;
      final alpha = (1 - k * k) * .95 * fade;
      final puffs = [
        (p + Offset(-r * .55, r * .2), r * .8),
        (p + Offset(r * .5, r * .1), r * .72),
        (p + Offset(-r * .05, -r * .5), r * .86),
      ];
      for (final (q, pr) in puffs) {
        c.drawCircle(q, pr, _stroke(_woodDark, h * .0036, alpha * .55));
      }
      for (final (q, pr) in puffs) {
        c.drawCircle(q, pr, _fill(_dust, alpha));
      }
    }
    // The gouge: a dark score through the paint with bare pale wood along
    // its lit edge, and a couple of lesser scratches beside it.
    final scuff = _ramp(age, .03, .1) * (1 - _ramp(age, .42, .74));
    final mark = reduced ? 1 - _ramp(age, .3, .5) : scuff;
    if (mark > 0) {
      final o = at + Offset(h * .009 * power, h * .002);
      void gash(Offset center, double length, double width, double angle) {
        final d = Offset(math.cos(angle), math.sin(angle));
        final n = Offset(-d.dy, d.dx) * width;
        final a = center - d * length / 2, b = center + d * length / 2;
        final lens = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(center.dx + n.dx, center.dy + n.dy, b.dx, b.dy)
          ..quadraticBezierTo(center.dx - n.dx * .5, center.dy - n.dy * .5, a.dx, a.dy)
          ..close();
        c.drawPath(lens, _fill(const Color(0xff2e170f), .9 * mark));
        c.drawLine(
          a + n * .35,
          b + n * .35,
          _stroke(_fresh, h * .0036, mark),
        );
      }

      gash(o, h * .058 * power, h * .024 * power, -.5);
      gash(o + Offset(-h * .006, h * .016) * power, h * .032 * power, h * .014 * power, -.5);
      gash(o + Offset(h * .013, -h * .015) * power, h * .028 * power, h * .012 * power, -.45);
    }
    // Splinters and sparks fly off to the left and fall in the sea.
    c.save();
    c.clipRect(
      Rect.fromLTRB(at.dx - h * 2, at.dy - h * 2, at.dx + h, math.max(level, at.dy + h * .01)),
    );
    _splinters(c, h, at, age, u, reduced, fade, seed, power);
    _sparks(c, h, at, age, u, reduced, fade, seed, power);
    c.restore();
    _clang(c, h, at, age, reduced, power);
    // Debris that met the sea leaves a ring.
    if (!reduced) {
      for (var i = 0; i < 5; i++) {
        final sp = _splinter(h, i, seed, power);
        final land = _land(sp.$1, sp.$2, at.dy, level, h * 1.8);
        if (land == null) continue;
        final k = (age - land) / .3;
        if (k <= 0 || k >= 1) continue;
        final w = h * (.012 + .02 * k);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(at.dx + sp.$1.dx * land, level + h * .004),
            width: w,
            height: w * .3,
          ),
          _stroke(_foam, h * .0032, (1 - k) * .9),
        );
      }
    }
  }

  /// Launch velocity and spin of the [i]th splinter.
  static (Offset, double) _splinter(double h, int i, int seed, double power) {
    final a = math.pi + (i - 2) * .5 - .35 + (_hash(i, seed + 2) - .5) * .3;
    final v = h * (.5 + .45 * _hash(i, seed + 4)) * power;
    return (Offset(math.cos(a) * v, math.sin(a) * v), (_hash(i, seed + 6) - .5) * 24);
  }

  /// When a body thrown from [y0] with vertical speed [v] falls to [level].
  static double? _land(Offset v, double spin, double y0, double level, double g) {
    final dy = level - y0;
    final disc = v.dy * v.dy + 2 * g * dy;
    if (disc < 0) return null;
    final t = (-v.dy + math.sqrt(disc)) / g;
    return t > 0 ? t : null;
  }

  static void _splinters(
    Canvas c,
    double h,
    Offset at,
    double age,
    double u,
    bool reduced,
    double fade,
    int seed,
    double power,
  ) {
    for (var i = 0; i < 5; i++) {
      final (v, spin) = _splinter(h, i, seed, power);
      final s = reduced ? .16 : u;
      final g = h * 1.8;
      final p = at + Offset(v.dx * s, v.dy * s + g * s * s / 2);
      final len = h * (i.isEven ? .04 : .028) * (.8 + .4 * _hash(i, seed + 8)) * power;
      final w = len * (i.isEven ? .28 : .36);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(math.atan2(v.dy, v.dx) + s * spin);
      final chip = Path()
        ..moveTo(-len / 2, -w / 2)
        ..lineTo(len / 2, 0)
        ..lineTo(-len / 2, w / 2)
        ..lineTo(-len * .38, 0)
        ..close();
      c.drawPath(chip, _stroke(_woodDark, h * .0044, fade));
      c.drawPath(chip, _fill(i.isEven ? _fresh : _wood, fade));
      c.restore();
    }
  }

  static void _sparks(
    Canvas c,
    double h,
    Offset at,
    double age,
    double u,
    bool reduced,
    double fade,
    int seed,
    double power,
  ) {
    for (var i = 0; i < 8; i++) {
      final a = math.pi + (i - 3.5) * .4 + (_hash(i, seed + 1) - .5) * .3 - .1;
      final v = h * (.55 + .7 * _hash(i, seed + 3)) * power;
      final life = .18 + .16 * _hash(i, seed + 5);
      final s = reduced ? .05 + .008 * i : u;
      if (s > life) continue;
      final g = h * 2.2;
      final head = at + Offset(math.cos(a) * v * s, math.sin(a) * v * s + g * s * s / 2);
      final vel = Offset(math.cos(a) * v, math.sin(a) * v + g * s);
      final tail = head - vel / vel.distance * h * .04 * (1 - s / life * .6) * power;
      final alpha = (1 - _ramp(s, life * .5, life)) * fade;
      c.drawLine(head, tail, _stroke(_line, h * .0105, .5 * alpha));
      c.drawLine(head, tail, _stroke(_ember, h * .0072, alpha));
      c.drawLine(head, tail, _stroke(_hot, h * .004, alpha));
      c.drawCircle(head, h * .0036, _fill(const Color(0xffffffff), alpha));
    }
  }

  /// The ring of the strike: a hot starburst, a glint that rings like
  /// metal, and a pair of ward arcs thrown back the way the shot came.
  static void _clang(Canvas c, double h, Offset at, double age, bool reduced, double power) {
    final k = reduced ? .3 : _ramp(age, 0, .2);
    final flash = (1 - k) * (reduced ? 1 - _ramp(age, .08, .3) : 1);
    if (flash <= 0) return;
    final grow = .75 + .45 * k;
    final burst = _star(at, h * .056 * grow * power, h * .024 * power, 8, .3);
    c.drawPath(burst, _stroke(_line, h * .0068, flash));
    c.drawPath(burst, _fill(_hot, flash));
    c.drawCircle(at, h * .022 * power * (1 - k * .4), _fill(const Color(0xffffffff), flash));
    final glint = _star(at, h * .085 * power * (1 - k * .3), h * .013 * power, 4, math.pi / 12);
    c.drawPath(glint, _stroke(_line, h * .003, flash * .5));
    c.drawPath(glint, _fill(const Color(0xffffffff), flash));
    for (var i = 0; i < 2; i++) {
      if (reduced && i > 0) break;
      final e = _out(_ramp(age - i * .035, 0, .22));
      final r = h * (.05 + .06 * (reduced ? .5 : e)) * power * (1 - i * .35);
      final a = reduced ? .85 * flash : (1 - e);
      if (a <= 0) continue;
      final rect = Rect.fromCircle(center: at + Offset(h * .012, 0), radius: r);
      c.drawArc(rect, math.pi - 1.05, 2.1, false, _stroke(_line, h * .0135, .4 * a));
      c.drawArc(rect, math.pi - 1.05, 2.1, false, _stroke(_foam, h * .0068, a));
    }
  }
}
