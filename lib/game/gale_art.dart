import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'gale_football_art.dart';
import 'sky_scenery.dart';

/// A gale reads at speed: the sky streaks with wind, debris tumbles at the
/// bird, and an exclamation mark near the right edge shows where each piece
/// will come through. Every effect follows the simulation clock.
abstract final class GaleArt {
  /// The hazard orange of the warning, shared with the GALE! banner so the
  /// card teaches the mark the player is about to see.
  static const warning = Color(0xffff5a36);

  static const _gust = Color(0xff4f8fb0), _haze = Color(0xffdcecf2);
  // Wind is drawn twice: a steel-blue halo that shows on a pale or snowy
  // sky, under a white core that shows on a dusk or night one.
  static const _gustHalo = Color(0xff3d6f8f);
  static const _warnLit = Color(0xffffb13d), _warnDeep = Color(0xffc2301a);
  static const _wood = Color(0xffb8773f), _woodDark = Color(0xff7a4724);
  static const _woodLight = Color(0xffe6b475), _pine = Color(0xffd9a45e);
  static const _iron = Color(0xff4a4f5c), _ironLight = Color(0xff8a92a3);
  static const _leaf = Color(0xff4f9a4f), _leafLight = Color(0xff96cf6a);
  static const _leafAutumn = Color(0xffe8a73c), _dust = Color(0xffd8c4a2);

  /// The warning stands this many screen heights in from the right edge.
  /// The pause button and the Shoot and Sprint buttons hold the corners,
  /// reaching about half a screen height in, so a mark on the very edge
  /// would hide under a control for the highest and lowest lanes.
  static const _post = .6;

  static double _hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// 0 before the warning, rising into the start, fading as it calms.
  static double intensity(FlightSimulation sim) {
    final gale = sim.gale;
    if (gale == null) return 0;
    return switch (gale.phase) {
      GalePhase.approach => _smooth(
        1 -
            (gale.startDistance - sim.distance - FlightSimulation.birdX) /
                Gale.warningLead,
      ),
      GalePhase.blowing => 1,
      GalePhase.weathered =>
        1 - _smooth((sim.elapsed - gale.weatheredAt!) / Gale.fallSeconds),
    };
  }

  /// Where the wind has carried a gust, in screen heights. Distance keeps
  /// it moving with the course, so it speeds up with the tailwind without
  /// ever jumping, and the clock keeps it blowing while the course is slow.
  static double _travel(FlightSimulation sim, bool reducedMotion) =>
      reducedMotion ? 0 : sim.distance * 3.2 + sim.elapsed * .9;

  // Scratch buffers for the brush strokes, so a frame allocates no lists.
  static final _points = <Offset>[];
  static final _widths = <double>[];

  /// A brush stroke along [_points], [_widths] giving the half width at
  /// each one, so a gust can thin to nothing at its tail and stay full
  /// through its curl.
  static Path _ribbon(double scale) {
    final n = _points.length;
    final path = Path();
    Offset normal(int i) {
      final d = _points[math.min(n - 1, i + 1)] - _points[math.max(0, i - 1)];
      final length = d.distance;
      return length == 0 ? Offset.zero : Offset(-d.dy, d.dx) / length;
    }

    for (var i = 0; i < n; i++) {
      final p = _points[i] + normal(i) * (_widths[i] * scale);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    for (var i = n - 1; i >= 0; i--) {
      final p = _points[i] - normal(i) * (_widths[i] * scale);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// Lays out one gust in [_points]: a loose wave running [length] back
  /// from its head, then, when [turn] is 1 (down) or -1 (up), the curl the
  /// wind rolls over into at the front. The tail is thin, so each gust
  /// reads as blowing leftwards rather than as a line lying still.
  static void _gustPath(
    Offset head,
    double length,
    double weight, {
    required double wave,
    required double sway,
    required double curl,
    required int turn,
  }) {
    _points.clear();
    _widths.clear();
    const body = 14;
    for (var k = 0; k <= body; k++) {
      final s = 1 - k / body;
      _points.add(
        head +
            Offset(
              length * s,
              wave * math.sin(s * 3.4 + sway) * (.25 + .75 * s),
            ),
      );
      _widths.add(weight * _smooth((1 - s) / .7));
    }
    if (turn == 0 || curl <= 0) return;
    // A hook that starts on the head heading left, climbs (or drops)
    // round a centre beside it and winds in, left open so it reads as a
    // curl of air rather than a loop of string.
    const coil = 12, sweep = 4.7;
    final center = head + Offset(0, turn * curl);
    for (var k = 1; k <= coil; k++) {
      final u = k / coil;
      final a = math.pi / 2 + sweep * u;
      final r = curl * (1 - .42 * u);
      _points.add(center + Offset(r * math.cos(a), -turn * r * math.sin(a)));
      _widths.add(weight * (1 - .55 * u));
    }
  }

  static final _halo = Paint();
  static final _core = Paint();

  /// A cool wash blowing in from the right, gusts curling across the sky
  /// behind the course and whatever the wind has picked up on the way.
  /// Reduced Motion keeps the same picture of wind, standing still.
  static void backdrop(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final t = intensity(sim);
    if (t <= 0) return;
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            _gust.withValues(alpha: .24 * t),
            _haze.withValues(alpha: .09 * t),
            _haze.withValues(alpha: 0),
          ],
          stops: const [0, .5, 1],
        ).createShader(Offset.zero & size),
    );
    final travel = _travel(sim, reducedMotion);
    // Sheets of torn air far back, too faint to hide anything, give the
    // gusts a body of wind to ride in. Pointed at both ends and fattest
    // near the front, so they read as air on the move, not as cloud.
    for (var i = 0; i < 5; i++) {
      final length = h * (.9 + .7 * _hash(i, 31));
      final span = w + length;
      final x = w - (travel * h * .55 + _hash(i, 33) * span) % span;
      final y = h * (.1 + .8 * _hash(i, 35));
      final weight = h * (.018 + .02 * _hash(i, 37));
      final sheet = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + length * .25, y - weight, x + length, y)
        ..quadraticBezierTo(x + length * .25, y + weight * .6, x, y)
        ..close();
      canvas
        ..drawPath(sheet, _halo..color = _gustHalo.withValues(alpha: .05 * t))
        ..drawPath(
          sheet,
          _core..color = SkyColors.white.withValues(alpha: .1 * t),
        );
    }
    for (var i = 0; i < 12; i++) {
      final depth = _hash(i, 5);
      final length = h * (.34 + .5 * depth);
      final curl = _hash(i, 9) < .62 ? h * (.02 + .016 * depth) : 0.0;
      final span = w + length + curl * 4;
      final x =
          w +
          curl * 2 -
          (travel * h * (.8 + .6 * depth) + _hash(i, 7) * span) % span;
      // Even lanes hold the top of the sky and odd ones the bottom, so the
      // whole height stays windy without the gusts bunching into bands.
      final y = h * (.05 + (_hash(i, 11) * .45 + (i.isOdd ? .45 : 0)));
      final weight = h * (.0026 + .003 * depth);
      final wave = h * (.012 + .014 * _hash(i, 13));
      final sway = i * 1.7 + travel * .8;
      final halo = _gustHalo.withValues(alpha: (.12 + .14 * depth) * t);
      final core = SkyColors.white.withValues(alpha: (.42 + .4 * depth) * t);
      _gustPath(
        Offset(x, y),
        length,
        weight,
        wave: wave,
        sway: sway,
        curl: curl,
        turn: i % 3 == 0 ? 1 : -1,
      );
      _paintGust(canvas, halo, core);
      if (i % 4 == 1) {
        // A thinner strand riding alongside, as air tears in layers.
        _gustPath(
          Offset(x + length * .12, y + h * .022),
          length * .6,
          weight * .7,
          wave: wave,
          sway: sway,
          curl: 0,
          turn: 0,
        );
        _paintGust(canvas, halo, core);
      }
    }
    _flecks(canvas, size, sim, t, reducedMotion);
  }

  static void _paintGust(Canvas canvas, Color halo, Color core) => canvas
    ..drawPath(_ribbon(2.3), _halo..color = halo)
    ..drawPath(_ribbon(1), _core..color = core);

  /// One of the gale's gusts, for drawing beyond the playfield (the GALE!
  /// card), so the warning carries the same wind the sky will.
  static void gust(
    Canvas canvas,
    Offset head,
    double length,
    double weight,
    Color color, {
    double curl = 0,
    int turn = -1,
    double sway = 0,
  }) {
    _gustPath(
      head,
      length,
      weight,
      wave: weight * 3,
      sway: sway,
      curl: curl,
      turn: turn,
    );
    canvas.drawPath(_ribbon(1), _core..color = color);
  }

  /// Whatever the wind has picked up where the bird is flying: leaves over
  /// green country, sand over the desert, snow over the ice. Each fleck
  /// changes over at its own point of a crossing, so they never swap at
  /// once.
  static void _flecks(
    Canvas canvas,
    Size size,
    FlightSimulation sim,
    double t,
    bool reducedMotion,
  ) {
    final w = size.width, h = size.height;
    final blend = WorldTour.at(sim.elapsed, held: sim.region);
    final travel = _travel(sim, reducedMotion);
    final clock = reducedMotion ? 0.0 : sim.elapsed;
    final fill = Paint(), rib = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final region = _hash(i, 61) < blend.t ? blend.to : blend.from;
      final depth = _hash(i, 63);
      final span = w + h * .2;
      final x =
          w +
          h * .1 -
          (travel * h * (.9 + .7 * depth) + _hash(i, 65) * span) % span;
      final y =
          h * (.06 + .88 * _hash(i, 67)) +
          math.sin(clock * (2.2 + depth) + i) * h * .03;
      final alpha = t * (.55 + .4 * depth);
      switch (region) {
        case WorldRegion.antarctica:
          canvas.drawCircle(
            Offset(x, y),
            h * (.004 + .004 * depth),
            fill..color = SkyColors.white.withValues(alpha: alpha),
          );
          canvas.drawCircle(
            Offset(x, y),
            h * (.004 + .004 * depth),
            rib
              ..style = PaintingStyle.stroke
              ..strokeWidth = h * .0015
              ..color = _gustHalo.withValues(alpha: alpha * .45),
          );
          rib.style = PaintingStyle.fill;
        case WorldRegion.cyberpunk:
          // Torn holo-sign shards: thin glowing slivers that flicker as
          // they tumble, cyan and magenta over the neon city.
          final shard = h * (.01 + .008 * depth);
          final tint = i.isEven
              ? const Color(0xff5ff4ff)
              : const Color(0xffff5fcf);
          final lit = reducedMotion
              ? .8
              : .55 + .45 * math.sin(clock * 11 + i * 2.3).abs();
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(clock * (2.2 + 2 * depth) * (i.isEven ? 1 : -1) + i);
          canvas.drawPath(
            Path()
              ..moveTo(-shard, -shard * .18)
              ..lineTo(shard * .7, -shard * .32)
              ..lineTo(shard, shard * .2)
              ..lineTo(-shard * .6, shard * .3)
              ..close(),
            fill..color = tint.withValues(alpha: alpha * .55 * lit),
          );
          canvas.drawLine(
            Offset(-shard * .7, 0),
            Offset(shard * .7, -shard * .04),
            rib
              ..strokeWidth = math.max(.8, shard * .16)
              ..color = SkyColors.white.withValues(alpha: alpha * lit),
          );
          canvas.restore();
        case WorldRegion.egypt || WorldRegion.arabia:
          canvas.drawLine(
            Offset(x, y),
            Offset(x + h * (.012 + .02 * depth), y - h * .002),
            rib
              ..strokeWidth = h * (.003 + .002 * depth)
              ..color = Color.lerp(
                _dust,
                _wood,
                .35,
              )!.withValues(alpha: alpha * .9),
          );
        default:
          final leaf = h * (.013 + .009 * depth);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(clock * (3 + 3 * depth) * (i.isEven ? 1 : -1) + i);
          // Flipping over on its long axis, so it tumbles rather than spins.
          final flip = reducedMotion ? .7 : math.cos(clock * 7.5 + i * 2.1);
          canvas.scale(1, flip.abs() < .25 ? .25 * flip.sign : flip);
          final shape = Path()
            ..moveTo(-leaf, 0)
            ..quadraticBezierTo(0, -leaf * .75, leaf, 0)
            ..quadraticBezierTo(0, leaf * .75, -leaf, 0)
            ..close();
          canvas.drawPath(
            shape,
            fill
              ..color = (switch (i % 3) {
                0 => _leafAutumn,
                1 => _leaf,
                _ => _leafLight,
              }).withValues(alpha: alpha),
          );
          canvas.drawLine(
            Offset(-leaf * 1.25, 0),
            Offset(leaf * .7, 0),
            rib
              ..strokeWidth = leaf * .16
              ..color = _woodDark.withValues(alpha: alpha * .7),
          );
          canvas.restore();
      }
    }
  }

  /// Air parting round the bird while the gale blows: streamlines bend
  /// over and under it and run on behind, so the wind reads right where
  /// the player is looking. Unlike a sprint, nothing piles up on the nose;
  /// the air comes from ahead and slips past.
  static void buffet(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final gale = sim.gale;
    if (gale == null) return;
    final t = gale.wind(sim.elapsed);
    if (t <= 0) return;
    final bird = Offset(sim.birdScreenX * h, sim.birdY * h);
    for (final (i, lane) in const [-.088, -.062, .064, .09].indexed) {
      final side = lane.sign;
      final loop = h * .62;
      final head = reducedMotion
          ? bird.dx - h * (.1 + .05 * i)
          : bird.dx +
                h * .3 -
                (sim.elapsed * h * (1.9 + .25 * i) + _hash(i, 71) * loop) %
                    loop;
      final length = h * (.17 + .05 * _hash(i, 73));
      _points.clear();
      _widths.clear();
      const steps = 12;
      for (var k = 0; k <= steps; k++) {
        final u = k / steps;
        final x = head + length * u;
        final near = (x - bird.dx - h * .01) / (h * .062);
        // The stream bulges clear of the body as it passes.
        final bulge = h * .028 * math.exp(-near * near);
        _points.add(Offset(x, bird.dy + h * lane + side * bulge));
        _widths.add(h * .0038 * math.sin(math.pi * u));
      }
      final fade = t * (i == 1 || i == 2 ? .8 : .55);
      canvas
        ..drawPath(
          _ribbon(2.2),
          _halo..color = _gustHalo.withValues(alpha: .2 * fade),
        )
        ..drawPath(
          _ribbon(1),
          _core..color = SkyColors.white.withValues(alpha: .85 * fade),
        );
    }
  }

  /// Debris on screen: cartwheels, barrels, crates and torn boughs (or,
  /// over Brazil, footballs), each tumbling on the circle it really hits,
  /// with the wind tearing off it.
  /// A piece that struck the bird glances away; [impacts] draws the burst
  /// over the bird.
  static void debris(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    final r = GaleDebris.radius * h;
    final scroll = sim.speed * sim.courseBoost;
    for (final d in sim.galeDebris) {
      final hitAge = d.hitAt == null ? null : sim.elapsed - d.hitAt!;
      if (hitAge != null) {
        _struck(canvas, h, sim, d, hitAge, scroll, reducedMotion);
        continue;
      }
      final center = Offset(d.x * h, d.y * h);
      if (center.dx - r * 1.3 > w || center.dx + r * 4 < 0) continue;
      _wake(canvas, center, r, d, reducedMotion);
      _body(
        canvas,
        center,
        r,
        d.shape,
        reducedMotion ? _restingTurn(d.shape) : d.age * d.spin,
        1,
        football: _football(sim, d),
      );
    }
  }

  static double _restingTurn(int shape) => shape * .7 - .35;

  /// Over Brazil the gale throws footballs. A piece keeps the region it was
  /// launched in, so one never changes costume mid-flight on a crossing.
  static bool _football(FlightSimulation sim, GaleDebris d) =>
      WorldTour.at(sim.elapsed - d.age, held: sim.region).dominant ==
      WorldRegion.brazil;

  /// What the wind tears off a piece: a pale smear the width of its body
  /// streaming back the way it came, with torn streaks along its middle
  /// and edges. The smear is exactly as wide as the circle the piece hits,
  /// so the lane it holds reads even mid-tumble.
  static void _wake(
    Canvas canvas,
    Offset center,
    double r,
    GaleDebris d,
    bool reducedMotion,
  ) {
    final smear = Rect.fromLTRB(
      center.dx,
      center.dy - r,
      center.dx + r * 4.2,
      center.dy + r,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - r)
        ..quadraticBezierTo(
          center.dx + r * 2.2,
          center.dy - r * .78,
          center.dx + r * 4.2,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx + r * 2.2,
          center.dy + r * .78,
          center.dx,
          center.dy + r,
        )
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [
            SkyColors.white.withValues(alpha: .42),
            SkyColors.white.withValues(alpha: .14),
            SkyColors.white.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(smear),
    );
    final flutter = reducedMotion ? 0.0 : d.age * 9;
    for (final (i, (lane, reach)) in const [
      (-.78, 2.9),
      (0.0, 3.8),
      (.78, 2.6),
    ].indexed) {
      final y = center.dy + r * lane;
      _gustPath(
        Offset(center.dx + r * (i == 1 ? 1.15 : .7), y),
        r * reach,
        r * (i == 1 ? .085 : .07),
        wave: r * .12,
        sway: flutter + i * 2,
        curl: 0,
        turn: 0,
      );
      // Unlike a gust, a streak is torn off the piece: it starts as a thread
      // at the body, swells, and frays out behind.
      for (var k = 0; k < _widths.length; k++) {
        _widths[k] =
            r *
            (i == 1 ? .085 : .07) *
            _smooth(k / 6) *
            (1 - k / _widths.length);
      }
      canvas
        ..drawPath(
          _ribbon(2.4),
          _halo..color = _gustHalo.withValues(alpha: .32),
        )
        ..drawPath(
          _ribbon(1),
          _core..color = SkyColors.white.withValues(alpha: .92),
        );
    }
  }

  /// One piece of debris at [center], turned to [turn], filling the circle
  /// of radius [r] it hits. Ink outlines keep it solid over any sky. A
  /// [football]'s shape picks its kit.
  static void _body(
    Canvas canvas,
    Offset center,
    double r,
    int shape,
    double turn,
    double alpha, {
    bool football = false,
  }) {
    if (football) {
      GaleFootballArt.paint(canvas, center, r, shape, turn, alpha);
      return;
    }
    // A shadow behind the piece lifts it off a busy backdrop.
    canvas.drawCircle(
      center + Offset(r * .1, r * .16),
      r * .98,
      Paint()..color = SkyColors.ink.withValues(alpha: .2 * alpha),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turn);
    Paint fill(Color c) => Paint()..color = c.withValues(alpha: alpha);
    Paint stroke(Color c, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c.withValues(alpha: alpha);
    final ink = SkyColors.ink.withValues(alpha: .9);
    switch (shape) {
      case 0:
        // A cartwheel torn off its axle: iron tyre, wooden rim, six spokes.
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final end = Offset(math.cos(a), math.sin(a)) * (r * .74);
          canvas.drawLine(Offset.zero, end, stroke(ink, r * .24));
        }
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final end = Offset(math.cos(a), math.sin(a)) * (r * .74);
          canvas.drawLine(Offset.zero, end, stroke(_wood, r * .12));
        }
        canvas.drawCircle(Offset.zero, r * .8, stroke(_wood, r * .22));
        canvas.drawCircle(Offset.zero, r * .8, stroke(_woodLight, r * .06));
        canvas.drawCircle(Offset.zero, r * .64, stroke(ink, r * .06));
        canvas.drawCircle(Offset.zero, r * .92, stroke(_iron, r * .12));
        canvas.drawCircle(Offset.zero, r * .98, stroke(ink, r * .08));
        canvas.drawCircle(Offset.zero, r * .22, fill(_woodDark));
        canvas.drawCircle(Offset.zero, r * .22, stroke(ink, r * .07));
        canvas.drawCircle(Offset.zero, r * .09, fill(_ironLight));
      case 1:
        // A barrel: bulging staves under two iron hoops.
        final barrel = Path()
          ..moveTo(-r * .56, -r * .86)
          ..quadraticBezierTo(0, -r * .96, r * .56, -r * .86)
          ..quadraticBezierTo(r * .96, 0, r * .56, r * .86)
          ..quadraticBezierTo(0, r * .96, -r * .56, r * .86)
          ..quadraticBezierTo(-r * .96, 0, -r * .56, -r * .86)
          ..close();
        canvas.drawPath(barrel, fill(_wood));
        canvas.save();
        canvas.clipPath(barrel);
        canvas.drawRect(
          Rect.fromLTRB(-r, -r, -r * .28, r),
          fill(_woodLight.withValues(alpha: .55)),
        );
        canvas.drawRect(
          Rect.fromLTRB(r * .36, -r, r, r),
          fill(_woodDark.withValues(alpha: .45)),
        );
        for (final x in [-.26, .2]) {
          canvas.drawPath(
            Path()
              ..moveTo(r * x, -r)
              ..quadraticBezierTo(r * x * 1.5, 0, r * x, r),
            stroke(_woodDark, r * .06),
          );
        }
        for (final y in [-.5, .5]) {
          canvas.drawPath(
            Path()
              ..moveTo(-r, r * y)
              ..quadraticBezierTo(0, r * (y + .1), r, r * y),
            stroke(_iron, r * .2),
          );
          canvas.drawPath(
            Path()
              ..moveTo(-r, r * (y - .05))
              ..quadraticBezierTo(0, r * (y + .05), r, r * (y - .05)),
            stroke(_ironLight, r * .05),
          );
        }
        canvas.restore();
        canvas.drawPath(barrel, stroke(ink, r * .1));
      case 2:
        // A crate: a pine frame round a slatted panel, braced corner to
        // corner, with a nail in each corner.
        final box = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 1.56,
            height: r * 1.56,
          ),
          Radius.circular(r * .14),
        );
        canvas.drawRRect(box, fill(_pine));
        final panel = box.deflate(r * .22);
        canvas.drawRRect(panel, fill(_wood));
        for (final y in [-.18, .18]) {
          canvas.drawLine(
            Offset(-r * .56, r * y),
            Offset(r * .56, r * y),
            stroke(_woodDark, r * .05),
          );
        }
        canvas.save();
        canvas.clipRRect(panel);
        canvas.drawLine(
          Offset(-r * .7, r * .7),
          Offset(r * .7, -r * .7),
          stroke(ink, r * .34),
        );
        canvas.drawLine(
          Offset(-r * .7, r * .7),
          Offset(r * .7, -r * .7),
          stroke(_woodLight, r * .22),
        );
        canvas.restore();
        canvas.drawRRect(panel, stroke(ink, r * .06));
        for (final c in [
          Offset(-r * .67, -r * .67),
          Offset(r * .67, -r * .67),
          Offset(-r * .67, r * .67),
          Offset(r * .67, r * .67),
        ]) {
          canvas.drawCircle(c, r * .07, fill(_iron));
        }
        canvas.drawRRect(box, stroke(ink, r * .1));
      default:
        // A bough torn from a tree, still in leaf: a broken stick through a
        // round clump, one leaf already turning.
        canvas.drawLine(
          Offset(-r * .98, r * .3),
          Offset(r * .92, -r * .26),
          stroke(ink, r * .28),
        );
        canvas.drawLine(
          Offset(-r * .98, r * .3),
          Offset(r * .92, -r * .26),
          stroke(_woodDark, r * .16),
        );
        for (final (i, (x, y, turn, size)) in const [
          (-.5, -.3, -.9, .62),
          (.1, -.52, .2, .66),
          (.52, .1, 1.1, .6),
          (-.36, .42, 2.5, .6),
          (.24, .5, -2.2, .56),
          (-.02, -.02, .7, .66),
        ].indexed) {
          canvas.save();
          canvas.translate(r * x, r * y);
          canvas.rotate(turn);
          final l = r * size, wide = r * size * .56;
          final leaf = Path()
            ..moveTo(-l, 0)
            ..quadraticBezierTo(-l * .1, -wide, l, 0)
            ..quadraticBezierTo(-l * .1, wide, -l, 0)
            ..close();
          canvas.drawPath(
            leaf,
            fill(
              i == 2
                  ? _leafAutumn
                  : i.isEven
                  ? _leaf
                  : _leafLight,
            ),
          );
          canvas.drawLine(
            Offset(-l * .8, 0),
            Offset(l * .6, 0),
            stroke(_woodDark.withValues(alpha: .6), r * .05),
          );
          canvas.drawPath(leaf, stroke(ink, r * .07));
          canvas.restore();
        }
        canvas.drawLine(
          Offset(r * .55, -r * .17),
          Offset(r * .92, -r * .26),
          stroke(_woodDark, r * .16),
        );
    }
    canvas.restore();
  }

  static const _knockSeconds = .65, _burstSeconds = .5;

  /// Where a piece met the bird, in screen heights, and whether it was the
  /// higher of the two. The bird's height comes from the hit it recorded,
  /// so the answer holds while the bird flies on; a strike during hit
  /// protection records nothing and falls back to the piece's own lane.
  static ({Offset contact, bool up}) _strike(
    FlightSimulation sim,
    GaleDebris d,
    double age,
    double scroll,
  ) {
    var birdY = d.y;
    for (final e in sim.events) {
      if (e.at == d.hitAt &&
          (e.kind == FlightEventKind.hit ||
              e.kind == FlightEventKind.shieldUsed)) {
        birdY = e.y;
      }
    }
    final struckAt = Offset(d.x + (GaleDebris.speed + scroll) * age, d.y);
    final toBird = Offset(FlightSimulation.birdX, birdY) - struckAt;
    return (
      contact:
          struckAt +
          (toBird.distance == 0
              ? const Offset(-GaleDebris.radius, 0)
              : toBird / toBird.distance * GaleDebris.radius),
      up: birdY >= d.y,
    );
  }

  /// A piece that hit the bird glances off, losing most of its pace and
  /// spinning hard. Pieces above the bird bounce up; pieces below it drop
  /// away.
  static void _struck(
    Canvas canvas,
    double h,
    FlightSimulation sim,
    GaleDebris d,
    double age,
    double scroll,
    bool reducedMotion,
  ) {
    if (age >= _knockSeconds) return;
    final r = GaleDebris.radius * h;
    final fade = 1 - _smooth((age - .22) / (_knockSeconds - .22));
    var center = Offset(d.x * h, d.y * h);
    var turn = _restingTurn(d.shape);
    if (!reducedMotion) {
      final up = _strike(sim, d, age, scroll).up;
      final lift = up ? -.5 * age + .9 * age * age : .45 * age + .6 * age * age;
      center += Offset((GaleDebris.speed + scroll) * age * .6 * h, lift * h);
      turn = d.age * d.spin + age * age * 22 * d.spin.sign;
    }
    final squash = reducedMotion ? 1.0 : 1 - .16 * (1 - _smooth(age / .12));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(squash, 2 - squash);
    canvas.translate(-center.dx, -center.dy);
    _body(canvas, center, r, d.shape, turn, fade, football: _football(sim, d));
    canvas.restore();
  }

  /// Strikes on the bird, drawn over it so the hit is never hidden behind
  /// the one it hurt.
  static void impacts(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final scroll = sim.speed * sim.courseBoost;
    for (final d in sim.galeDebris) {
      final age = sim.elapsed - (d.hitAt ?? double.infinity);
      if (!(age >= 0 && age < _burstSeconds)) continue;
      final strike = _strike(sim, d, age, scroll);
      _burst(
        canvas,
        h,
        strike.contact * h,
        d,
        age,
        scroll,
        strike.up,
        reducedMotion,
        football: _football(sim, d),
      );
    }
  }

  /// The strike itself: a white star of impact, a ring of air, splinters
  /// (leaves from a bough, torn turf from a [football]) thrown back the way
  /// the piece came, and a puff of dust the course carries away.
  static void _burst(
    Canvas canvas,
    double h,
    Offset contact,
    GaleDebris d,
    double age,
    double scroll,
    bool up,
    bool reducedMotion, {
    bool football = false,
  }) {
    if (age >= _burstSeconds) return;
    final r = GaleDebris.radius * h;
    final s = age / _burstSeconds;
    // The course carries the burst off only slowly, so the splinters fly
    // clear behind the bird instead of dragging back across it.
    final at = contact - Offset(scroll * age * h * .35, 0);
    final seed = d.shape * 7 + (d.y * 97).round();
    if (!reducedMotion) {
      for (var i = 0; i < 3; i++) {
        final u = _hash(i + 3, seed);
        canvas.drawCircle(
          at + Offset(r * (.4 + 1.6 * s * (.5 + u)), r * (u - .5) * 1.4),
          r * (.45 + 1.1 * s) * (.7 + .5 * u),
          Paint()..color = _dust.withValues(alpha: (1 - s) * .4),
        );
      }
    }
    final flash = reducedMotion ? .45 : 1 - (age / .16).clamp(0.0, 1.0);
    if (flash > 0) {
      final open = reducedMotion ? .5 : 1 - flash;
      final pow = Path();
      for (var i = 0; i < 16; i++) {
        final reach =
            r *
            (i.isEven ? 1.0 + .45 * open : .45 + .15 * open) *
            (.85 + .3 * _hash(i, seed));
        final p = at + Offset.fromDirection(i * math.pi / 8 + .2, reach);
        i == 0 ? pow.moveTo(p.dx, p.dy) : pow.lineTo(p.dx, p.dy);
      }
      pow.close();
      final alpha = reducedMotion ? 1 - s : flash;
      canvas
        ..drawPath(
          pow,
          Paint()..color = SkyColors.cream.withValues(alpha: alpha),
        )
        ..drawPath(
          pow,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .1
            ..strokeJoin = StrokeJoin.round
            ..color = SkyColors.ink.withValues(alpha: alpha * .55),
        )
        ..drawCircle(
          at,
          r * .36,
          Paint()..color = SkyColors.yellow.withValues(alpha: alpha),
        );
    }
    if (!reducedMotion && s < .7) {
      final ring = s / .7;
      canvas.drawCircle(
        at,
        r * (1.1 + 2.2 * ring),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .22 * (1 - ring)
          ..color = SkyColors.white.withValues(alpha: (1 - ring) * .85),
      );
    }
    final travel = reducedMotion ? .45 : 1 - (1 - s) * (1 - s);
    final alpha = math.min(1.0, (1 - s) * 2.2);
    final leafy = !football && d.shape == 3;
    for (var i = 0; i < 6; i++) {
      final u = _hash(i, seed + 11), v = _hash(i + 20, seed + 11);
      // Thrown back up the course, fanning to the side it bounced.
      final angle = (up ? -.35 : .35) + (i / 5 - .5) * 2.4 + (u - .5) * .4;
      final reach = r * (.6 + (2.2 + 1.4 * v) * travel);
      final fall = reducedMotion ? 0.0 : age * age * h * .9;
      final p = at + Offset.fromDirection(angle, reach) + Offset(0, fall);
      final size = r * (.26 + .14 * v);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(u * 6 + (reducedMotion ? 0 : age * (v - .5) * 24));
      // A football tears up turf: grass blades and the odd clod of earth.
      final clod = football && i % 3 == 2;
      final piece = football
          ? (clod
                ? (Path()..addOval(
                    Rect.fromCenter(
                      center: Offset.zero,
                      width: size * 1.2,
                      height: size * .85,
                    ),
                  ))
                : (Path()
                    ..moveTo(-size, size * .34)
                    ..quadraticBezierTo(0, -size * .3, size * 1.25, -size * .4)
                    ..quadraticBezierTo(0, size * .3, -size, -size * .24)
                    ..close()))
          : leafy
          ? (Path()
              ..moveTo(-size, 0)
              ..quadraticBezierTo(0, -size * .6, size, 0)
              ..quadraticBezierTo(0, size * .6, -size, 0)
              ..close())
          : (Path()
              ..moveTo(-size, -size * .16)
              ..lineTo(size * .9, -size * .3)
              ..lineTo(size * 1.1, size * .05)
              ..lineTo(size * .6, size * .22)
              ..lineTo(-size * .9, size * .2)
              ..close());
      canvas
        ..drawPath(
          piece,
          Paint()
            ..color =
                (clod
                        ? _woodDark
                        : football
                        ? (i.isEven ? _leaf : _leafLight)
                        : leafy
                        ? (i.isEven ? _leaf : _leafAutumn)
                        : (i.isEven ? _woodLight : _wood))
                    .withValues(alpha: alpha),
        )
        ..drawPath(
          piece,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * (football ? .05 : .07)
            ..strokeJoin = StrokeJoin.round
            ..color = SkyColors.ink.withValues(alpha: alpha * .8),
        )
        ..restore();
    }
  }

  /// A mark for each piece still off screen, at the height it will come
  /// through: an orange "!" standing clear of the corner controls at the
  /// head of a lane that runs out to the right edge, the lane as tall as
  /// the piece it holds. Chevrons stream down the lane toward the bird and
  /// a ring round the mark runs down with the time left. Everything is
  /// timed from the seconds until the piece appears, never from the clock,
  /// so the flash quickens all the way in and a replay shows it the same.
  static void warnings(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    final scroll = sim.speed * sim.courseBoost;
    final pace = GaleDebris.speed + scroll;
    for (final d in sim.galeDebris) {
      if (d.hitAt != null) continue;
      final enter = d.entersIn(w / h, scroll);
      // Once the piece is in view the mark pops and clears out of its way.
      final shown = enter > 0
          ? 0.0
          : (w / h + GaleDebris.radius - d.x) / pace / .16;
      if (shown >= 1) continue;
      _mark(
        canvas,
        size,
        d.y * h,
        enter: enter,
        leaving: shown,
        reducedMotion: reducedMotion,
      );
    }
  }

  static void _mark(
    Canvas canvas,
    Size size,
    double y, {
    required double enter,
    required double leaving,
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    final soon = (1 - enter / GaleDebris.warningSeconds).clamp(0.0, 1.0);
    // The phase runs faster as the seconds run out: about two and a half
    // flashes a second at first, seven as the piece breaks in.
    final phase = 44 * enter - 15.7 * enter * enter;
    final blink = reducedMotion ? 0.0 : .5 + .5 * math.cos(phase);
    // Leaving, the mark snaps out quickly behind a ring of its own colour
    // rather than lingering as a ghost over the piece's path.
    final gone = _smooth(leaving);
    final show = (1 - gone) * (1 - gone);
    final swell = reducedMotion
        ? 1.0
        : (1 + .1 * blink * soon) * (1 + .2 * gone);
    final radius = h * (reducedMotion ? .05 : .043 + .012 * soon) * swell;
    final center = Offset(w - h * _post, y);
    final lane = GaleDebris.radius * h;

    // The lane: a hot band out to the edge the piece will burst through.
    final band = Rect.fromLTRB(center.dx, y - lane, w, y + lane);
    final heat = (.16 + .2 * soon) * show;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        band,
        topLeft: Radius.circular(lane),
        bottomLeft: Radius.circular(lane),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [
            warning.withValues(alpha: heat * .35),
            warning.withValues(alpha: heat),
            _warnDeep.withValues(alpha: heat * 1.4),
          ],
          stops: const [0, .7, 1],
        ).createShader(band),
    );
    final rail = Paint()
      ..strokeWidth = h * .003
      ..shader = LinearGradient(
        colors: [
          warning.withValues(alpha: 0),
          warning.withValues(alpha: .45 * show),
        ],
      ).createShader(band);
    for (final edge in [-lane, lane]) {
      canvas.drawLine(
        Offset(center.dx + radius * 1.2, y + edge),
        Offset(w, y + edge),
        rail,
      );
    }
    // Chevrons streaming down the lane, the way the piece will fly.
    final gap = h * .085;
    final drift = reducedMotion
        ? gap * .5
        : (GaleDebris.warningSeconds - enter) * h * .55 % gap;
    final chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final start = center.dx + radius * 1.5;
    for (var x = w + gap - drift; x > start; x -= gap) {
      final along = ((x - start) / (w - start)).clamp(0.0, 1.0);
      final a = math.min(along * 4, 1.0) * (.55 + .45 * soon) * show;
      if (a <= 0) continue;
      final arm = lane * .5;
      final path = Path()
        ..moveTo(x + arm * .8, y - arm)
        ..lineTo(x, y)
        ..lineTo(x + arm * .8, y + arm);
      canvas
        ..drawPath(
          path,
          chevron
            ..strokeWidth = h * .011
            ..color = _warnDeep.withValues(alpha: .6 * a),
        )
        ..drawPath(
          path,
          chevron
            ..strokeWidth = h * .0055
            ..color = SkyColors.cream.withValues(alpha: a),
        );
    }

    if (gone > 0 && !reducedMotion) {
      canvas.drawCircle(
        center,
        radius * (1.15 + 1.1 * gone),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .012 * (1 - gone)
          ..color = warning.withValues(alpha: 1 - gone),
      );
    }
    final glow = Rect.fromCircle(center: center, radius: radius * 2.2);
    canvas.drawCircle(
      center,
      radius * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            warning.withValues(alpha: (.3 + .25 * soon + .2 * blink) * show),
            warning.withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    // The disc: ink rim for a pale sky, hot fill that flashes toward
    // yellow, cream mark on an ink shadow.
    canvas.drawCircle(
      center + Offset(0, h * .006),
      radius,
      Paint()..color = SkyColors.ink.withValues(alpha: .35 * show),
    );
    final disc = Rect.fromCircle(center: center, radius: radius);
    final hot = reducedMotion ? .35 * soon : .55 * blink;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.4),
          radius: 1.05,
          colors: [
            Color.lerp(
              _warnLit,
              SkyColors.yellow,
              hot,
            )!.withValues(alpha: show),
            Color.lerp(warning, _warnLit, hot)!.withValues(alpha: show),
            _warnDeep.withValues(alpha: show),
          ],
          stops: const [0, .55, 1],
        ).createShader(disc),
    );
    canvas.drawCircle(
      center,
      radius * .84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .06
        ..color = SkyColors.cream.withValues(alpha: .35 * show),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0065
        ..color = SkyColors.ink.withValues(alpha: .9 * show),
    );
    void bang(Offset at, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: at - Offset(0, radius * .17),
            width: radius * .34,
            height: radius * .98,
          ),
          Radius.circular(radius * .17),
        ),
        Paint()..color = color,
      );
      canvas.drawCircle(
        at + Offset(0, radius * .56),
        radius * .19,
        Paint()..color = color,
      );
    }

    bang(
      center + Offset(radius * .04, radius * .08),
      SkyColors.ink.withValues(alpha: .5 * show),
    );
    bang(center, SkyColors.cream.withValues(alpha: show));

    // The ring of time left, running down clockwise from the top.
    final ring = Rect.fromCircle(center: center, radius: radius + h * .014);
    canvas.drawCircle(
      center,
      radius + h * .014,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .011
        ..color = SkyColors.ink.withValues(alpha: .45 * show),
    );
    if (soon < 1) {
      canvas.drawArc(
        ring,
        -math.pi / 2 + math.pi * 2 * soon,
        math.pi * 2 * (1 - soon),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0065
          ..strokeCap = StrokeCap.round
          ..color = SkyColors.cream.withValues(alpha: show),
      );
    }
  }

  /// A hard knock when debris strikes the bird.
  static Offset cameraOffset(FlightSimulation sim, bool reducedMotion) {
    if (reducedMotion) return Offset.zero;
    var x = 0.0, y = 0.0;
    for (final d in sim.galeDebris) {
      final age = sim.elapsed - (d.hitAt ?? double.infinity);
      if (!(age >= 0 && age < .3)) continue;
      final decay = (1 - age / .3) * (1 - age / .3);
      x += .012 * decay * math.cos(age * 70);
      y += .006 * decay * math.sin(age * 55 + d.y * 9);
    }
    return Offset(x.clamp(-.014, .014), y.clamp(-.0085, .0085));
  }
}
