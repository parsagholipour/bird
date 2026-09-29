import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';

/// The Pirate Captain's sea: a back swell behind the ship, the water in
/// front of the hull, the tide's warning, splashes, hull knocks and the
/// marks where each cannonball will cross the bird's flight line.
///
/// The drawn surface follows [SkyBoss.waterLevel] (the line the rules test
/// for the bird) within a few thousandths of the screen, so a dodge that
/// looks clean is clean. Waves travel with the course and every motion
/// follows the simulation clock, so pause and replay seeking stay exact.
abstract final class PirateSeaArt {
  static const foam = Color(0xfff2fffb), _crest = Color(0xff8fe3dc);
  static const _surface = Color(0xff3aa9b6), _mid = Color(0xff237e9c);
  static const _deep = Color(0xff1b4d78), _abyss = Color(0xff172c58);
  static const _back = Color(0xff2a7597), _backLit = Color(0xff6cc3cc);
  static const _line = Color(0xff123049), _warn = Color(0xffff5a36);
  static const _cream = Color(0xfffff9ed), _chevron = Color(0xffc9fff6);
  static const _wood = Color(0xffa8683f), _woodDark = Color(0xff55301f);

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()..color = color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));
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

  /// The wave height at screen x (screen heights), within ±.005 of the
  /// level: two swells riding the course and slowly rolling on their own.
  static double wave(double x, double distance, double t, {double swell = 1}) {
    final w = x + distance;
    return (.0031 * math.sin(w * 9.1 + t * 1.4) +
            .0019 * math.sin(w * 21.7 - t * 2.3 + 1.1)) *
        swell;
  }

  static double _time(FlightSimulation sim, BossMotion m) =>
      m.reducedMotion ? 0.0 : sim.elapsed;

  /// How hard the sea churns: through each warning, the surge and on
  /// arrival.
  static double _churn(SkyBoss boss) {
    if (boss.phase == BossPhase.arriving) {
      return 1 - BossMotion.ramp(boss.age, 2.2, 3);
    }
    if (boss.phase != BossPhase.attacking) return .4;
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    return math.max(
      boss.tideWarning * .8,
      BossMotion.ramp(cycle, SkyBoss.tideRiseAt, SkyBoss.tideRiseAt + .2) *
          (1 - BossMotion.ramp(cycle, SkyBoss.tidePeakAt, SkyBoss.tideFallAt)),
    );
  }

  static Path _surfacePath(
    Size size,
    double level,
    double distance,
    double t, {
    double swell = 1,
    double phase = 0,
    double lift = 0,
  }) {
    final h = size.height, w = size.width;
    final path = Path();
    final step = math.max(4.0, w / 160);
    for (var x = -step; x <= w + step; x += step) {
      final y = (level - lift + wave(x / h + phase, distance, t, swell: swell)) * h;
      x == -step ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path;
  }

  // ---------------------------------------------------------------- back --

  /// A darker swell just behind the ship, so the hull sits in the water
  /// rather than on a flat line.
  static void back(Canvas c, Size size, FlightSimulation sim, SkyBoss boss, BossMotion m) {
    final level = boss.waterLevel;
    if (level == null || level > 1.03) return;
    final h = size.height, w = size.width;
    final t = _time(sim, m);
    final top = _surfacePath(size, level, sim.distance * .8, t * .8, phase: .37, lift: .0045);
    final body = Path.from(top)
      ..lineTo(w + 20, h + 20)
      ..lineTo(-20, h + 20)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [_back, _deep],
        ).createShader(Rect.fromLTRB(0, (level - .01) * h, w, (level + .12) * h)),
    );
    c.drawPath(top, _stroke(_backLit, h * .004, .85));
  }

  // --------------------------------------------------------------- front --

  /// The sea in front of the hull, with its foam crest, glints and the
  /// churn of a surge. [shipX] is where the hull meets the water.
  static void front(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m, {
    required double bowX,
    required double sternX,
  }) {
    final level = boss.waterLevel;
    if (level == null || level > 1.03) return;
    final h = size.height, w = size.width;
    final t = _time(sim, m);
    final churn = m.reducedMotion ? 0.0 : _churn(boss);
    final swell = 1 + churn * .25;
    final surface = _surfacePath(size, level, sim.distance, t, swell: swell);
    final body = Path.from(surface)
      ..lineTo(w + 20, h + 20)
      ..lineTo(-20, h + 20)
      ..close();
    final depth = Rect.fromLTRB(0, level * h, w, (level + .42) * h);
    // The top of the water stays a little clear, so the hull shows through
    // just under the surface.
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _surface.withValues(alpha: .78),
            _surface.withValues(alpha: .92),
            _mid,
            _deep,
            _abyss,
          ],
          stops: const [0, .06, .22, .62, 1],
        ).createShader(depth),
    );
    c.save();
    c.clipPath(body);
    // Horizontal light bands and glints drift with the course.
    for (var i = 0; i < 4; i++) {
      final y = (level + .028 + i * .05 + i * i * .012) * h;
      if (y > h) break;
      c.drawLine(
        Offset(0, y),
        Offset(w, y + h * .004),
        _stroke(_crest, h * (.006 - i * .001), .12 - i * .02),
      );
    }
    final span = w / h + .4;
    for (var i = 0; i < 26; i++) {
      final lane = i % 5;
      final gx = ((i * .37 + _hash(i) * .6 - sim.distance * (.9 + lane * .05)) % span + span) % span - .2;
      final gy = level + .018 + lane * .03 + _hash(i, 3) * .02;
      if (gy > 1.02) continue;
      final shimmer = m.reducedMotion ? .6 : .45 + .55 * math.sin(t * 2.3 + i * 1.7).abs();
      final len = h * (.02 + _hash(i, 5) * .03) * (1 - lane * .12);
      c.drawLine(
        Offset(gx * h, gy * h),
        Offset(gx * h + len, gy * h),
        _stroke(_crest, h * .0032, (.55 - lane * .08) * shimmer),
      );
    }
    if (churn > .05) {
      // Rising currents stream up through the surge.
      for (var i = 0; i < 14; i++) {
        final x = ((i * .19 + _hash(i, 9) * .12 - sim.distance) % span + span) % span - .2;
        final life = (t * .9 + _hash(i, 11)) % 1;
        final y = level + .03 + (1 - life) * .3;
        c.drawLine(
          Offset(x * h, y * h),
          Offset(x * h, (y - .04) * h),
          _stroke(_crest, h * .004, churn * .35 * math.sin(life * math.pi)),
        );
      }
    }
    c.restore();
    // Around the hull: foam wash where the bow and stern cut the water.
    for (final (x, big) in [(bowX, 1.3), (sternX, .9)]) {
      for (var i = 0; i < 5; i++) {
        final bob = m.reducedMotion ? 0.0 : math.sin(t * 3 + i * 1.3) * .004;
        final at = Offset(
          (x + (i - 2) * .018 * big) * h,
          (level + wave(x, sim.distance, t) + bob - .002 + (i - 2).abs() * .002) * h,
        );
        c.drawCircle(at, h * .009 * big * (1 - (i - 2).abs() * .15), _fill(foam, .9));
      }
    }
    // The crest: an ink edge, a bright foam line and scalloped caps.
    c.drawPath(surface.shift(Offset(0, h * .004)), _stroke(_line, h * .005, .45));
    c.drawPath(surface, _stroke(foam, h * (.0055 + churn * .002)));
    final gap = .034;
    final first = ((-sim.distance) / gap).floor();
    for (var i = first; (i * gap + sim.distance) * h < w + 10; i++) {
      final x = i * gap + sim.distance;
      if (x < -.02) continue;
      final world = i;
      final size0 = .0028 + _hash(world, 1) * .0022 + churn * .0012;
      final y = level + wave(x, sim.distance, t, swell: swell) + .0005;
      c.drawCircle(Offset(x * h, (y - size0 * .35) * h), size0 * h, _fill(foam, .95));
    }
    if (churn > .05 && !m.reducedMotion) {
      // Spray jumps off the churning crest.
      for (var i = 0; i < 18; i++) {
        final life = (t * 1.3 + _hash(i, 21)) % 1;
        final x = ((i * .13 + _hash(i, 23) * .1 - sim.distance) % span + span) % span - .2;
        final hop = math.sin(life * math.pi) * .02 * (.5 + _hash(i, 25));
        c.drawCircle(
          Offset(x * h, (level - .003 - hop) * h),
          h * .0035 * (1 - life * .5),
          _fill(foam, churn * (1 - life)),
        );
      }
    }
  }

  // --------------------------------------------------------------- tide --

  /// The warning before each surge: the high-water line the sea will reach,
  /// a pale band over everything it will cover, chevrons welling up toward
  /// the line and a tag spelling it out. It holds until the water arrives.
  static void tideWarning(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) {
    if (boss.phase != BossPhase.attacking) return;
    final level = boss.waterLevel;
    if (level == null) return;
    final warning = boss.tideWarning;
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    final rising = cycle >= SkyBoss.tideRiseAt && cycle < SkyBoss.tidePeakAt + .2;
    if (warning <= 0 && !rising) return;
    final h = size.height, w = size.width;
    final t = _time(sim, m);
    final show = warning > 0
        ? BossMotion.ease(BossMotion.ramp(warning, 0, .18))
        : 1 - BossMotion.ease(BossMotion.ramp(boss.tide, .55, 1));
    if (show <= 0) return;
    // The flash quickens as the surge nears; Reduced Motion holds it lit.
    final seconds = warning > 0 ? warning * (SkyBoss.tideRiseAt - SkyBoss.tideWarnAt) : 1.3;
    final blink = m.reducedMotion ? 1.0 : .5 + .5 * math.cos(seconds * (9 + seconds * 9));
    const peak = SkyBoss.tidePeak;
    final lineY = peak * h;
    // The band the water will fill, from the line down to today's surface.
    final band = Rect.fromLTRB(0, lineY, w, level * h);
    if (band.height > 1) {
      c.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xff7fe6dc).withValues(alpha: (.26 + .08 * blink) * show),
              const Color(0xff3aa9b6).withValues(alpha: .1 * show),
            ],
          ).createShader(band),
      );
      // Chevrons well up out of the sea toward the line.
      final gap = h * .19;
      final rise = m.reducedMotion ? .5 : (t * .9) % 1;
      final columns = (w / gap).ceil() + 1;
      final scroll = (sim.distance * h) % gap;
      for (var col = 0; col < columns; col++) {
        final x = col * gap + gap * .5 - scroll;
        for (var row = 0; row < 3; row++) {
          final k = ((row + rise) / 3);
          final y = level * h - (level * h - lineY) * (.15 + k * .8);
          final fade = math.sin(k * math.pi) * show;
          if (fade <= .02) continue;
          final arm = h * .022;
          final chevron = Path()
            ..moveTo(x - arm, y + arm * .7)
            ..lineTo(x, y)
            ..lineTo(x + arm, y + arm * .7);
          c.drawPath(chevron, _stroke(_line, h * .01, .35 * fade));
          c.drawPath(chevron, _stroke(_chevron, h * .005, .85 * fade));
        }
      }
    }
    // The high-water line itself: the shape the surface will take, dashed
    // and marching with the waves.
    final line = _surfacePath(size, peak, sim.distance, t);
    final dashed = _dash(line, h * .034, h * .018, m.reducedMotion ? 0 : (t * h * .06) % (h * .052));
    c.drawPath(dashed, _stroke(_line, h * .011, .55 * show));
    c.drawPath(dashed, _stroke(_cream, h * .0055, (.7 + .3 * blink) * show));
    // Tags at both ends: an arrow up to the line and the words.
    _tag(c, size, Offset(h * .03, lineY), show, blink, m.reducedMotion, t);
  }

  static Path _dash(Path source, double on, double off, double shift) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var d = -shift;
      while (d < metric.length) {
        final start = math.max(0.0, d);
        final end = math.min(metric.length, d + on);
        if (end > start) dashed.addPath(metric.extractPath(start, end), Offset.zero);
        d += on + off;
      }
    }
    return dashed;
  }

  static void _tag(
    Canvas c,
    Size size,
    Offset anchor,
    double show,
    double blink,
    bool reduced,
    double t,
  ) {
    final h = size.height;
    final title = TextPainter(
      text: TextSpan(
        text: 'HIGH TIDE',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: h * .042,
          letterSpacing: h * .003,
          color: _cream.withValues(alpha: show),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pad = h * .016, arrow = h * .03;
    final plate = Rect.fromLTWH(
      anchor.dx,
      anchor.dy - title.height - pad * 2 - h * .018,
      arrow + pad * 3 + title.width,
      title.height + pad * 1.4,
    );
    final bob = reduced ? 0.0 : math.sin(t * 5) * h * .003;
    final r = RRect.fromRectAndRadius(plate.shift(Offset(0, bob)), Radius.circular(h * .018));
    c.drawRRect(r.shift(Offset(0, h * .005)), _fill(_line, .45 * show));
    c.drawRRect(r, _fill(const Color(0xff17445c), .94 * show));
    c.drawRRect(r, _stroke(Color.lerp(_chevron, _warn, .3 * blink)!, h * .004, show));
    // A pointer from the plate down onto the line.
    final tip = Offset(r.left + pad + arrow / 2, anchor.dy - h * .002);
    c.drawPath(
      Path()
        ..moveTo(tip.dx - h * .012, r.bottom - 1)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + h * .012, r.bottom - 1)
        ..close(),
      _fill(const Color(0xff17445c), .94 * show),
    );
    // An up arrow: fly above.
    final a = Offset(r.left + pad + arrow / 2, r.center.dy);
    final up = Path()
      ..moveTo(a.dx, a.dy - arrow * .5)
      ..lineTo(a.dx + arrow * .45, a.dy)
      ..lineTo(a.dx + arrow * .16, a.dy)
      ..lineTo(a.dx + arrow * .16, a.dy + arrow * .45)
      ..lineTo(a.dx - arrow * .16, a.dy + arrow * .45)
      ..lineTo(a.dx - arrow * .16, a.dy)
      ..lineTo(a.dx - arrow * .45, a.dy)
      ..close();
    c.drawPath(up, _fill(Color.lerp(_warn, const Color(0xffffb13d), blink)!, show));
    title.paint(c, Offset(r.left + pad * 2 + arrow, r.center.dy - title.height / 2));
  }

  // ------------------------------------------------------------ splashes --

  /// Where cannonballs and the bird met the sea: a white column and a crown
  /// of drops for a ball, a wide double sheet for the bird, ripples for both.
  static void splashes(Canvas c, Size size, FlightSimulation sim, SkyBoss boss, BossMotion m) {
    final level = boss.waterLevel;
    if (level == null) return;
    final h = size.height;
    for (final splash in sim.seaSplashes) {
      final age = sim.elapsed - splash.at;
      if (age < 0 || age > 1.2) continue;
      final at = Offset(splash.x * h, level * h);
      if (splash.bird) {
        _birdSplash(c, h, at, age, m.reducedMotion);
      } else {
        _ballSplash(c, h, at, age, m.reducedMotion, splash.at);
      }
    }
  }

  static void _ripples(Canvas c, double h, Offset at, double age, double big) {
    for (var i = 0; i < 2; i++) {
      final u = BossMotion.ramp(age, i * .15, .9 + i * .15);
      if (u <= 0 || u >= 1) continue;
      final rect = Rect.fromCenter(
        center: at + Offset(0, h * .004),
        width: h * (.04 + u * .2) * big,
        height: h * (.008 + u * .016) * big,
      );
      c.drawOval(rect, _stroke(foam, h * .005 * (1 - u), (1 - u) * .9));
    }
  }

  static void _ballSplash(Canvas c, double h, Offset at, double age, bool reduced, double seed) {
    _ripples(c, h, at, age, 1);
    // The column shoots up and slumps back.
    final u = reduced ? .3 : age;
    final rise = u < .2 ? math.sin(u / .2 * math.pi / 2) : math.max(0.0, 1 - (u - .2) / .5);
    final fade = 1 - BossMotion.ramp(age, .6, 1.1);
    if (rise > 0 && fade > 0) {
      final tall = h * .1 * rise, wide = h * .018 * (1 + (1 - rise) * .6);
      final column = Path()
        ..moveTo(at.dx - wide * 1.6, at.dy)
        ..quadraticBezierTo(at.dx - wide * .7, at.dy - tall * .3, at.dx - wide * .5, at.dy - tall * .8)
        ..quadraticBezierTo(at.dx, at.dy - tall * 1.15, at.dx + wide * .5, at.dy - tall * .8)
        ..quadraticBezierTo(at.dx + wide * .7, at.dy - tall * .3, at.dx + wide * 1.6, at.dy)
        ..close();
      c.drawPath(column, _stroke(_line, h * .006, .4 * fade));
      c.drawPath(column, _fill(_crest, fade));
      c.drawPath(
        Path()
          ..moveTo(at.dx - wide * .9, at.dy)
          ..quadraticBezierTo(at.dx - wide * .3, at.dy - tall * .5, at.dx, at.dy - tall * 1.0)
          ..quadraticBezierTo(at.dx + wide * .3, at.dy - tall * .5, at.dx + wide * .9, at.dy)
          ..close(),
        _fill(foam, fade),
      );
    }
    // A crown of drops flung out on arcs.
    if (!reduced || age < .6) {
      for (var i = 0; i < 9; i++) {
        final a = -math.pi / 2 + (i - 4) * .28;
        final speed = h * (.32 + _hash(i, seed.floor()) * .18);
        final life = reduced ? .25 : age;
        final p = at +
            Offset(math.cos(a) * speed * life, math.sin(a) * speed * life + h * 1.6 * life * life);
        if (p.dy > at.dy) continue;
        final r = h * (.004 + (i % 3) * .0015) * (1 - BossMotion.ramp(age, .3, .9));
        if (r <= 0) continue;
        c.drawCircle(p, r + h * .0015, _fill(_line, .3));
        c.drawCircle(p, r, _fill(foam));
      }
    }
    // Foam settles where it went in.
    final settle = BossMotion.ramp(age, .1, .3) * (1 - BossMotion.ramp(age, .7, 1.2));
    if (settle > 0) {
      for (var i = -2; i <= 2; i++) {
        c.drawCircle(at + Offset(i * h * .012, -h * .002), h * (.007 - i.abs() * .001), _fill(foam, settle));
      }
    }
  }

  static void _birdSplash(Canvas c, double h, Offset at, double age, bool reduced) {
    _ripples(c, h, at, age, 1.5);
    final u = reduced ? .25 : age;
    final rise = u < .16 ? math.sin(u / .16 * math.pi / 2) : math.max(0.0, 1 - (u - .16) / .55);
    final fade = 1 - BossMotion.ramp(age, .55, 1.0);
    if (rise > 0 && fade > 0) {
      // Two curling sheets thrown out either side.
      for (final side in [-1.0, 1.0]) {
        final tip = at + Offset(side * h * (.05 + (1 - rise) * .03), -h * .075 * rise);
        final sheet = Path()
          ..moveTo(at.dx + side * h * .008, at.dy)
          ..quadraticBezierTo(at.dx + side * h * .02, at.dy - h * .05 * rise, tip.dx, tip.dy)
          ..quadraticBezierTo(
            tip.dx + side * h * .012,
            tip.dy + h * .02,
            at.dx + side * h * .065,
            at.dy,
          )
          ..close();
        c.drawPath(sheet, _stroke(_line, h * .006, .4 * fade));
        c.drawPath(sheet, _fill(_crest, fade));
        c.drawPath(
          Path()
            ..moveTo(at.dx + side * h * .015, at.dy)
            ..quadraticBezierTo(at.dx + side * h * .024, at.dy - h * .035 * rise, tip.dx - side * h * .006, tip.dy + h * .008)
            ..lineTo(at.dx + side * h * .045, at.dy)
            ..close(),
          _fill(foam, fade),
        );
      }
    }
    for (var i = 0; i < 12; i++) {
      final a = -math.pi / 2 + (i - 5.5) * .24;
      final speed = h * (.28 + _hash(i, 77) * .2);
      final life = reduced ? .22 : age;
      final p = at +
          Offset(math.cos(a) * speed * life, math.sin(a) * speed * life + h * 1.7 * life * life);
      if (p.dy > at.dy) continue;
      final r = h * (.0045 + (i % 3) * .0015) * (1 - BossMotion.ramp(age, .35, 1));
      if (r <= 0) continue;
      c.drawCircle(p, r + h * .0015, _fill(_line, .3));
      c.drawCircle(p, r, _fill(foam));
    }
  }

  // ------------------------------------------------------- hull knocks --

  /// A shot that glanced off the hull knocks out a puff of splinters where
  /// it struck.
  static void hullKnocks(Canvas c, double h, FlightSimulation sim, SkyBoss boss, BossMotion m) {
    for (final rock in sim.rocks) {
      final age = rock.reboundAge;
      if (age == null || age > .5) continue;
      // Back out the rebound to the point of impact.
      final at = Offset(
        rock.x - rock.velocityX * age,
        rock.y - (-.18 * age + .9 * age * age),
      );
      if (at.dy < boss.y + SkyBoss.hullTop - .03) continue;
      final p = at * h;
      final flash = 1 - age / .12;
      if (flash > 0) {
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 + .3;
          final r = h * (i.isEven ? .03 : .013) * (m.reducedMotion ? .8 : .7 + flash * .5);
          final q = p + Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? star.moveTo(q.dx, q.dy) : star.lineTo(q.dx, q.dy);
        }
        star.close();
        c.drawPath(star, _fill(const Color(0xffffe7a6), flash));
        c.drawPath(star, _stroke(_woodDark, h * .003, flash));
      }
      final k = m.reducedMotion ? .2 : age;
      for (var i = 0; i < 6; i++) {
        final a = math.pi + (i - 2.5) * .45 - .3;
        final v = h * (.22 + (i % 3) * .08);
        final q = p + Offset(math.cos(a) * v * k, math.sin(a) * v * k + h * 1.4 * k * k);
        final fade = 1 - age / .5;
        c.save();
        c.translate(q.dx, q.dy);
        c.rotate(a + k * (8 + i));
        final chip = Rect.fromCenter(center: Offset.zero, width: h * .014, height: h * .0055);
        c.drawRect(chip.inflate(h * .0015), _fill(_woodDark, fade));
        c.drawRect(chip, _fill(_wood, fade));
        c.restore();
      }
    }
  }

  // ------------------------------------------------------------ aim marks --

  /// Where each cannonball will cross the bird's flight line: a treasure-map
  /// X in a ring that closes as the ball comes down, and a pointer at the
  /// top edge for a lob that has climbed out of view.
  static void aimMarks(Canvas c, Size size, FlightSimulation sim, SkyBoss boss, BossMotion m) {
    final level = boss.waterLevel ?? 1.0;
    final h = size.height;
    const x = FlightSimulation.birdX;
    for (final ball in sim.bossAmmo) {
      if (!ball.cannonball) continue;
      if (ball.y < -ball.radius) _overhead(c, h, ball, m);
      if (ball.vx >= 0 || ball.x <= x + .06) continue;
      final time = (ball.x - x) / -ball.vx;
      final y = ball.y + ball.vy * time + ball.gravity * time * time / 2;
      if (y > level - ball.radius * .5 || y < .02) continue;
      final near = 1 - BossMotion.ramp(time, .25, 2.2);
      final alpha = BossMotion.ramp(time, .06, .2) * (.35 + .55 * near);
      if (alpha <= 0) continue;
      final at = Offset(x * h, y * h);
      final ring = h * (.052 + (1 - near) * .03);
      c.drawCircle(at, ring, _stroke(_line, h * .008, .4 * alpha));
      c.drawCircle(at, ring, _stroke(_cream, h * .0035, alpha));
      // Four ticks on the ring close in with it.
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4;
        final d = Offset(math.cos(a), math.sin(a));
        c.drawLine(at + d * (ring - h * .012), at + d * (ring + h * .006), _stroke(_cream, h * .004, alpha));
      }
      final arm = h * .016;
      for (final s in [1.0, -1.0]) {
        c.drawLine(at + Offset(-arm, -arm * s), at + Offset(arm, arm * s), _stroke(_line, h * .011, .5 * alpha));
      }
      for (final s in [1.0, -1.0]) {
        c.drawLine(at + Offset(-arm, -arm * s), at + Offset(arm, arm * s), _stroke(_warn, h * .0055, alpha));
      }
    }
  }

  static void _overhead(Canvas c, double h, BossAmmo ball, BossMotion m) {
    // How far above the screen: the pointer swells as the ball comes back.
    final up = -ball.y;
    final alpha = (1 - BossMotion.ramp(up, .05, .6)) * .9 + .1;
    final at = Offset(ball.x * h, h * .03);
    final falling = ball.vy > 0;
    final r = h * .012;
    final arrow = Path()
      ..moveTo(at.dx - r, at.dy - r * (falling ? .6 : -.6))
      ..lineTo(at.dx, at.dy + r * (falling ? .6 : -.6))
      ..lineTo(at.dx + r, at.dy - r * (falling ? .6 : -.6));
    c.drawPath(arrow, _stroke(_line, h * .009, .45 * alpha));
    c.drawPath(arrow, _stroke(_cream, h * .0045, alpha));
  }
}
