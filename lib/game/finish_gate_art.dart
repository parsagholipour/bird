import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'finish_celebration_art.dart';
import 'sky_scenery.dart';

/// The finish gate of a campaign level: two candy-striped posts, a checkered
/// beam, a hanging FINISH sign ringed with marquee lights, and bunting,
/// standing where the rules put the line. The bird flies in front of it, so
/// it can never hide the bird, a hazard or the HUD, and everything wears the
/// ink outline of the game's other pictures so it reads over bright beaches
/// and dark nights alike.
///
/// The gate is drawn in screen heights, centred on the line's x. In the last
/// [approachSeconds] before the crossing it gets excited: its lights flick
/// on and chase, its glow swells and the flags and bunting quicken. At the
/// crossing ([FinishCelebrationArt]) the tape snaps at the bird's height and
/// whips away, the lights flash together, the crest star spins up in a
/// sunburst and the sign swings. Without a celebration to follow (a replay's
/// last frame) and in Reduced Motion, the crossing shows one still burst of
/// confetti instead, and Reduced Motion stills every other motion.
abstract final class FinishGateArt {
  /// The posts stand this far either side of the line, in screen heights:
  /// wide enough for the bird to pass between them, narrow enough to clear
  /// the hearts panel when the bird meets the line.
  static const postOffset = .135, postWidth = .056;

  /// Everything the gate paints lies within this far of the line's x, but
  /// the celebration's sunburst, which fills the sky behind it.
  static const reach = .6;

  /// The top of the tape, under the beam, and the height of the finial
  /// balls on the post tops, which double as the confetti cannons.
  static const tapeTop = .23, finialY = .124;

  /// How long before the crossing the gate begins to get excited, and when
  /// its marquee lights start to flick on (the "almost there" sting).
  static const approachSeconds = 3.0, lightsAt = 2.6;

  /// Seconds until the bird reaches the line at the flight's speed, or null
  /// with no line or once it is crossed.
  static double? toGo(FlightSimulation sim) {
    final line = sim.finishLine;
    if (line == null || line.crossed) return null;
    return math.max(0.0, line.x - sim.birdScreenX) / math.max(.2, sim.speed);
  }

  static double _near(double? toGo) =>
      toGo == null ? 0 : (1 - toGo / approachSeconds).clamp(0.0, 1.0);

  /// How excited the gate is, from 0 (more than [approachSeconds] away) to 1
  /// at the line.
  static double approach(double? toGo) {
    final v = _near(toGo);
    return v * v * (3 - 2 * v);
  }

  /// The flags and bunting wave this much faster at the line.
  static const _quicken = 1.3;

  /// Seconds the flags have gained by quickening on the way in: the
  /// integral of [approach] over the run-up, so their speed rises smoothly
  /// without a jump in phase.
  static double gained(double? toGo) {
    final v = _near(toGo);
    return _quicken * approachSeconds * (v * v * v - v * v * v * v / 2);
  }

  /// [gained] at the crossing itself.
  static const _gainedAtLine = _quicken * approachSeconds / 2;

  static const _outline = .0065;
  static const _ink = SkyColors.ink;

  /// Paints the gate at [x] pixels. [seconds] is the flight's clock;
  /// [toGo] the seconds left to the line ([FinishGateArt.toGo]), which
  /// excites the gate on the way in; [celebration] the seconds since the
  /// crossing while its celebration plays, with [contact] the height where
  /// the bird broke the tape.
  static void paint(
    Canvas canvas,
    double h, {
    required double x,
    required double seconds,
    required bool arrived,
    required bool reducedMotion,
    double? toGo,
    double? celebration,
    double contact = .5,
  }) {
    final view = canvas.getLocalClipBounds();
    if (x + h * reach < view.left || x - h * reach > view.right) return;
    final party = arrived ? celebration : null;
    final near = party != null ? 1.0 : approach(toGo);
    // The flags keep waving through the celebration while the flight's
    // clock stands still.
    final t = reducedMotion
        ? 0.0
        : seconds +
              (party == null
                  ? gained(toGo)
                  : _gainedAtLine + (1 + _quicken) * party);
    final u = party == null ? 0.0 : party - FinishCelebrationArt.hitStop;
    canvas.save();
    canvas.translate(x, 0);
    canvas.scale(h);
    if (party != null) _sunburst(canvas, party, reducedMotion);
    _glow(canvas, near, party);
    const hitStop = FinishCelebrationArt.hitStop;
    if (party == null) {
      _tape(canvas, reducedMotion ? 0 : near);
    } else if (reducedMotion) {
      // The calm crossing simply lets the line fade away.
      _tape(canvas, 1, 1 - _smooth(party / .5));
    } else if (party < hitStop) {
      _stretched(canvas, party, contact);
    }
    for (final side in [-1.0, 1.0]) {
      _post(canvas, side * postOffset);
    }
    _beam(canvas);
    _crest(canvas, reducedMotion || party == null ? null : u, party);
    _bunting(canvas, t);
    final swing = reducedMotion || u <= 0
        ? 0.0
        : .17 * math.exp(-2.4 * u) * math.sin(9.5 * u);
    _sign(canvas, swing);
    _lights(canvas, t, near, party, reducedMotion, swing);
    // The snapped halves whip in front of the sign while they recoil.
    if (party != null && !reducedMotion && party >= hitStop) {
      _recoil(canvas, party - hitStop, contact);
    }
    for (final side in [-1.0, 1.0]) {
      _flag(canvas, side * postOffset, t, side);
    }
    _sparkles(canvas, t, reducedMotion);
    // A replay's last frame, and the calm celebration, keep a still burst.
    if (arrived && (party == null || reducedMotion)) {
      _confetti(canvas, party == null ? 1 : _smooth(party / .3));
    }
    canvas.restore();
    _lettering(canvas, h, x, swing);
  }

  /// A soft column of light behind the gate, so the line stands out of dark
  /// scenery. Added light brightens a night and hardly shows on a bright day,
  /// where the outlines do the work. It swells as the bird nears and flares
  /// at the crossing.
  static void _glow(Canvas c, double near, double? party) {
    final flare = party == null
        ? 0.0
        : math.exp(-5 * math.max(0, party - FinishCelebrationArt.hitStop)) *
              _smooth(party / FinishCelebrationArt.hitStop);
    final alpha = .32 + .06 * near + .12 * flare;
    c.drawRect(
      const Rect.fromLTRB(-.55, 0, .55, 1),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          colors: [
            SkyColors.yellow.withValues(alpha: 0),
            SkyColors.yellow.withValues(alpha: alpha),
            SkyColors.yellow.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTRB(-.55, 0, .55, 1)),
    );
  }

  /// Soft golden rays fanning out from the crest across the sky once the
  /// line is crossed, turning slowly; Reduced Motion holds them still.
  static void _sunburst(Canvas c, double party, bool reducedMotion) {
    final grow = reducedMotion
        ? _smooth(party / .6)
        : _smooth((party - FinishCelebrationArt.hitStop) / .45);
    if (grow <= 0) return;
    const center = Offset(0, .148), rays = 14;
    final turn = reducedMotion ? 0.0 : party * .2;
    final path = Path();
    for (var i = 0; i < rays; i++) {
      final a = turn + i * 2 * math.pi / rays;
      path
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(a - .085) * 2.4,
          center.dy + math.sin(a - .085) * 2.4,
        )
        ..lineTo(
          center.dx + math.cos(a + .085) * 2.4,
          center.dy + math.sin(a + .085) * 2.4,
        )
        ..close();
    }
    c.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.yellow.withValues(alpha: .22 * grow),
            SkyColors.yellow.withValues(alpha: .08 * grow),
            SkyColors.yellow.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: 1.6)),
    );
  }

  static const _cell = .014, _tapeFoot = 1.02;

  /// The line itself: a narrow checkered tape from the beam to the ground,
  /// exactly where the bird crosses. It firms up as the bird nears.
  static void _tape(Canvas c, double near, [double alpha = 1]) {
    if (alpha <= 0) return;
    const cell = _cell, top = tapeTop;
    final a = (.62 + .3 * near) * alpha;
    final ink = Paint()..color = _ink.withValues(alpha: a);
    final cream = Paint()..color = SkyColors.cream.withValues(alpha: a);
    for (var i = 0; top + i * cell < _tapeFoot; i++) {
      for (var col = 0; col < 2; col++) {
        c.drawRect(
          Rect.fromLTWH((col - 1) * cell, top + i * cell, cell, cell),
          (i + col).isEven ? ink : cream,
        );
      }
    }
  }

  /// How far the bird's chest pushes the tape before it snaps.
  static const _push = .065;

  /// The tape through the hit-stop, drawn taut into a point at the bird's
  /// chest.
  static void _stretched(Canvas c, double party, double contact) {
    final k = _smooth(party / FinishCelebrationArt.hitStop * 1.5);
    final apex = Offset(_push * k, contact);
    _ribbon(c, [
      for (var i = 0; i <= 8; i++)
        Offset.lerp(const Offset(0, tapeTop), apex, i / 8)!,
      for (var i = 1; i <= 8; i++)
        Offset.lerp(apex, const Offset(0, _tapeFoot), i / 8)!,
    ], 1);
  }

  /// The snapped tape [u] seconds after the snap: its halves spring back
  /// to their roots like cut elastic, the torn ends whipping past them and
  /// fluttering, until only a stub hangs under the beam.
  static void _recoil(Canvas c, double u, double contact) {
    if (u > 1.4) {
      _ribbon(c, _half(0, 0, upper: true), 1);
      return;
    }
    _ribbon(c, _half(contact - tapeTop, u, upper: true), 1);
    _ribbon(c, _half(_tapeFoot - contact, u, upper: false), 1);
  }

  /// The points along one snapped half, from its root out to the torn end,
  /// [u] seconds after the snap. Its far part lags the root, so the recoil
  /// runs down it like a whip.
  static List<Offset> _half(double length, double u, {required bool upper}) {
    const joints = 14, lag = .05, stub = .028;
    final root = upper ? const Offset(0, tapeTop) : const Offset(0, _tapeFoot);
    final pull = math.max(0.0, length - stub);
    final lean = length <= 0 ? 0.0 : math.atan2(_push, length);
    final points = [root];
    var p = root;
    for (var i = 1; i <= joints; i++) {
      final s = i / joints;
      final a = math.max(0.0, u - s * lag);
      final span = stub + pull * math.exp(-4.6 * a) * math.cos(7.4 * a);
      final angle =
          lean * math.exp(-6 * a) +
          .75 * math.exp(-3 * a) * math.sin(9 * a) +
          math.sin(s * 10 - u * 18) * .3 * s * math.exp(-2.4 * u);
      final dir = upper
          ? Offset(math.sin(angle), math.cos(angle))
          : Offset(math.sin(angle), -math.cos(angle));
      p += dir * (span / joints);
      points.add(p);
    }
    return points;
  }

  /// A checkered ribbon along [points], two cells wide, with an ink edge.
  static void _ribbon(Canvas c, List<Offset> points, double alpha) {
    if (alpha <= 0) return;
    final edge = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      edge.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cell * 2 + .006
        ..strokeJoin = StrokeJoin.round
        ..color = _ink.withValues(alpha: alpha),
    );
    final cells = Paint()..strokeWidth = _cell;
    var run = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final d = b - a;
      final len = d.distance;
      if (len <= 0) continue;
      final n = Offset(-d.dy, d.dx) / len * (_cell / 2);
      // Every segment alternates its two columns, like the checker.
      final odd = (run / _cell).floor().isOdd;
      run += len;
      for (final (k, side) in [(0, -1.0), (1, 1.0)]) {
        cells.color = ((k == 0) == odd ? SkyColors.cream : _ink).withValues(
          alpha: alpha,
        );
        c.drawLine(a + n * side, b + n * side, cells);
      }
    }
  }

  static void _post(Canvas c, double cx) {
    const w = postWidth, top = .15;
    final rect = Rect.fromLTRB(cx - w / 2, top, cx + w / 2, 1.05);
    // The plinth sits in a soft pool of shade.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx + .012, .985),
        width: .14,
        height: .026,
      ),
      Paint()..color = _ink.withValues(alpha: .18),
    );
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(w * .3));
    c.drawRRect(
      body.shift(const Offset(.009, .004)),
      Paint()..color = _ink.withValues(alpha: .16),
    );
    c.save();
    c.clipRRect(body);
    c.drawRect(rect, Paint()..color = SkyColors.cream);
    // Diagonal candy stripes, one stripe every .08.
    final stripe = Paint()..color = SkyColors.coral;
    for (var y = top - w; y < 1.1; y += .08) {
      c.drawPath(
        Path()
          ..moveTo(rect.left, y + w)
          ..lineTo(rect.right, y)
          ..lineTo(rect.right, y + .04)
          ..lineTo(rect.left, y + .04 + w)
          ..close(),
        stripe,
      );
    }
    // Round the shaft: light down one side, shade down the other.
    c.drawRect(
      Rect.fromLTWH(cx - w * .34, top, w * .16, 1),
      Paint()..color = SkyColors.white.withValues(alpha: .45),
    );
    c.drawRect(
      Rect.fromLTRB(cx + w * .14, top, rect.right, 1.1),
      Paint()..color = _ink.withValues(alpha: .14),
    );
    c.restore();
    c.drawRRect(body, _line());
    // A cap on top and a plinth at the foot hold the shaft in place.
    for (final cap in [
      Rect.fromCenter(
        center: Offset(cx, top + .006),
        width: w * 1.3,
        height: .026,
      ),
      Rect.fromCenter(center: Offset(cx, .96), width: w * 1.9, height: .034),
    ]) {
      final rr = RRect.fromRectAndRadius(cap, Radius.circular(cap.height * .4));
      c.drawRRect(rr, Paint()..color = SkyColors.yellow);
      c.drawRRect(rr, _line());
    }
    // The finial ball.
    final ball = Offset(cx, top - .026);
    c.drawCircle(ball, .027, Paint()..color = SkyColors.yellow);
    c.drawCircle(
      ball.translate(-.008, -.008),
      .008,
      Paint()..color = SkyColors.white.withValues(alpha: .75),
    );
    c.drawCircle(ball, .027, _line());
  }

  /// The checkered beam across the top of the gate.
  static void _beam(Canvas c) {
    const cols = 14, half = postOffset + postWidth / 2 + .012;
    const cell = half * 2 / cols, top = .176;
    final rect = Rect.fromLTWH(-half, top, half * 2, cell * 2);
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(.01));
    c.drawRRect(
      body.shift(const Offset(.005, .008)),
      Paint()..color = _ink.withValues(alpha: .16),
    );
    c.save();
    c.clipRRect(body);
    c.drawRect(rect, Paint()..color = SkyColors.cream);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < cols; col++) {
        if ((row + col).isEven) continue;
        c.drawRect(
          Rect.fromLTWH(-half + col * cell, top + row * cell, cell, cell),
          Paint()..color = _ink,
        );
      }
    }
    c.drawRect(
      Rect.fromLTRB(-half, rect.bottom - .008, half, rect.bottom),
      Paint()..color = _ink.withValues(alpha: .22),
    );
    c.restore();
    c.drawRRect(body, _line());
  }

  /// A gold star crowning the beam: the level's stars are what the flight
  /// was for. At the crossing it spins up, swells and shines ([u] seconds
  /// after the snap); the calm celebration only lights it.
  static void _crest(Canvas c, double? u, double? party) {
    const center = Offset(0, .148);
    final lit = party == null ? 0.0 : _smooth(party / .3);
    if (lit > 0) {
      c.drawCircle(
        center,
        .085,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              SkyColors.white.withValues(alpha: .7 * lit),
              SkyColors.yellow.withValues(alpha: .35 * lit),
              SkyColors.yellow.withValues(alpha: 0),
            ],
            stops: const [0, .4, 1],
          ).createShader(Rect.fromCircle(center: center, radius: .085)),
      );
    }
    c.save();
    if (u != null && u > 0) {
      final spin = 4 * math.pi * _outCubic(u / 1.1);
      final swell =
          1 +
          .16 * _smooth(u / .3) +
          .42 * math.sin((u / .4).clamp(0, 1) * math.pi);
      c.translate(center.dx, center.dy);
      c.rotate(spin);
      c.scale(swell);
      c.translate(-center.dx, -center.dy);
    }
    final star = SkyScenery.star(center, .05);
    c.drawPath(
      star.shift(const Offset(.004, .007)),
      Paint()..color = _ink.withValues(alpha: .16),
    );
    c.drawPath(star, Paint()..color = SkyColors.yellow);
    c.drawPath(
      SkyScenery.star(center.translate(-.004, -.006), .026),
      Paint()..color = SkyColors.white.withValues(alpha: .55 + .35 * lit),
    );
    c.drawPath(star, _line(.0075));
    c.restore();
  }

  /// Where the sign hangs from: it swings about this point under the beam.
  static const _pivot = Offset(0, .232);

  /// The FINISH board, hung from the beam on two short ropes and turned
  /// [swing] radians about [_pivot]. Its lettering is set by [_lettering]
  /// once the canvas is back at pixel scale.
  static void _sign(Canvas c, double swing) {
    const width = .27, top = .255, height = .095;
    for (final side in [-1.0, 1.0]) {
      c.drawLine(
        Offset(side * .09, .232),
        _turned(Offset(side * .09, top + .006), swing),
        Paint()
          ..color = _ink
          ..strokeWidth = .008
          ..strokeCap = StrokeCap.round,
      );
    }
    c.save();
    _turn(c, swing);
    final rect = Rect.fromLTWH(-width / 2, top, width, height);
    final board = RRect.fromRectAndRadius(rect, const Radius.circular(.024));
    c.drawRRect(
      board.shift(const Offset(.005, .009)),
      Paint()..color = _ink.withValues(alpha: .18),
    );
    c.drawRRect(board, Paint()..color = SkyColors.coral);
    // A lit upper half, a deeper lower edge and a cream rim make the board
    // a chunky slab.
    c.save();
    c.clipRRect(board);
    c.drawRect(
      Rect.fromLTWH(rect.left, top, width, height * .46),
      Paint()..color = SkyColors.white.withValues(alpha: .2),
    );
    c.drawRect(
      Rect.fromLTRB(rect.left, rect.bottom - .02, rect.right, rect.bottom),
      Paint()..color = SkyColors.coralDeep,
    );
    c.restore();
    c.drawRRect(
      board.deflate(.0095),
      Paint()
        ..color = SkyColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = .005,
    );
    c.drawRRect(board, _line());
    c.restore();
  }

  static Offset _turned(Offset p, double swing) {
    final d = p - _pivot;
    return _pivot +
        Offset(
          d.dx * math.cos(swing) - d.dy * math.sin(swing),
          d.dx * math.sin(swing) + d.dy * math.cos(swing),
        );
  }

  static void _turn(Canvas c, double swing) {
    if (swing == 0) return;
    c.translate(_pivot.dx, _pivot.dy);
    c.rotate(swing);
    c.translate(-_pivot.dx, -_pivot.dy);
  }

  /// The marquee bulbs round the sign's rim, in order clockwise from its
  /// top left.
  static final _bulbs = [
    for (var i = 0; i < 7; i++) Offset(-.105 + i * .035, .2645),
    const Offset(.1255, .3025),
    for (var i = 0; i < 7; i++) Offset(.105 - i * .035, .3405),
    const Offset(-.1255, .3025),
  ];

  /// How brightly bulb [i] burns: dark far out; flicking on one by one as
  /// the line nears, then chasing round the sign; flashing all together at
  /// the crossing, then chasing fast. Reduced Motion simply switches them on.
  static double _bulb(
    int i,
    double t,
    double near,
    double? party,
    bool reducedMotion,
  ) {
    if (reducedMotion) return near > .25 || party != null ? 1 : 0;
    if (party != null) {
      final u = party - FinishCelebrationArt.hitStop;
      if (u < 0) return 1;
      if (u < .6) return (u / .1).floor().isEven ? 1 : 0;
      return ((i - (u * 12).floor()) % 4 + 4) % 4 == 0 ? .25 : 1;
    }
    final on = (near - .04 - i * .022) / .03;
    if (on <= 0) return 0;
    if (on < 1) return (on * 3).floor().isEven ? 1 : .15;
    if (near < .5) return 1;
    return ((i - (t * 7).floor()) % 4 + 4) % 4 == 0 ? .2 : 1;
  }

  static void _lights(
    Canvas c,
    double t,
    double near,
    double? party,
    bool reducedMotion,
    double swing,
  ) {
    c.save();
    _turn(c, swing);
    const r = .0068;
    final halo = Paint()..blendMode = BlendMode.plus;
    final fill = Paint();
    final edge = _line(.0028);
    for (var i = 0; i < _bulbs.length; i++) {
      final p = _bulbs[i];
      final b = _bulb(i, t, near, party, reducedMotion);
      if (b > 0) {
        halo.color = SkyColors.yellow.withValues(alpha: .5 * b);
        c.drawCircle(p, r * 2.6, halo);
      }
      fill.color = Color.lerp(_bulbOff, SkyColors.yellow, b)!;
      c.drawCircle(p, r, fill);
      c.drawCircle(p, r, edge);
      if (b > .5) {
        c.drawCircle(
          p.translate(-r * .25, -r * .25),
          r * .45,
          Paint()..color = SkyColors.white.withValues(alpha: b),
        );
      }
    }
    c.restore();
  }

  static const _bulbOff = Color(0xffc9b48f);

  /// A swag of pennants strung between the posts, below the sign.
  static void _bunting(Canvas c, double t) {
    const inner = postOffset - postWidth / 2, y = .392, sag = .038;
    c.drawPath(
      Path()
        ..moveTo(-inner, y)
        ..quadraticBezierTo(0, y + sag * 2, inner, y),
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = .005
        ..strokeCap = StrokeCap.round,
    );
    final colors = [
      SkyColors.coral,
      SkyColors.yellow,
      SkyColors.mint,
      SkyColors.lavender,
      SkyColors.white,
    ];
    const count = 7;
    for (var i = 0; i < count; i++) {
      // Along the quadratic string: sag is greatest in the middle.
      final u = (i + .5) / count;
      final px = -inner + inner * 2 * u;
      final py = y + sag * 4 * u * (1 - u);
      final sway = math.sin(t * 2.4 + i * .9) * .005;
      final flap = Path()
        ..moveTo(px - .0165, py)
        ..lineTo(px + .0165, py)
        ..lineTo(px + sway, py + .052)
        ..close();
      c.drawPath(flap, Paint()..color = colors[i % colors.length]);
      c.drawPath(flap, _line(.0035));
    }
  }

  /// A swallowtail pennant on a short pole above a post, streaming away from
  /// the bird.
  static void _flag(Canvas c, double cx, double t, double side) {
    const base = .1, tip = .05;
    final wave = math.sin(t * 3.1 + (side > 0 ? 1.7 : 0));
    c.drawLine(
      Offset(cx, base),
      Offset(cx, tip),
      Paint()
        ..color = _ink
        ..strokeWidth = .007
        ..strokeCap = StrokeCap.round,
    );
    final len = .075 + wave * .006;
    final flag = Path()
      ..moveTo(cx, tip + .002)
      ..quadraticBezierTo(
        cx + len * .5,
        tip + .004 + wave * .006,
        cx + len,
        tip + .012,
      )
      ..lineTo(cx + len * .78, tip + .03)
      ..lineTo(cx + len, tip + .048 + wave * .003)
      ..quadraticBezierTo(
        cx + len * .5,
        tip + .045 + wave * .005,
        cx,
        tip + .05,
      )
      ..close();
    c.drawPath(
      flag,
      Paint()..color = side < 0 ? SkyColors.yellow : SkyColors.coral,
    );
    c.drawPath(flag, _line(.0045));
  }

  /// Four-point twinkles either side of the gate.
  static void _sparkles(Canvas c, double t, bool reducedMotion) {
    const spots = [
      Offset(-.225, .16),
      Offset(.235, .25),
      Offset(-.215, .33),
      Offset(.225, .43),
      Offset(.06, .07),
    ];
    for (var i = 0; i < spots.length; i++) {
      final beat = reducedMotion
          ? 1.0
          : .62 + .38 * math.sin(t * 3.6 + i * 1.9);
      final r = (i == 4 ? .02 : .016) * beat;
      final p = spots[i];
      final path = Path()
        ..moveTo(p.dx, p.dy - r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
        ..close();
      c.drawPath(path, Paint()..color = SkyColors.white);
      c.drawPath(path, _line(.0035));
    }
  }

  /// A still burst above the crossing: a replay's frozen last frame keeps
  /// it, and the calm celebration fades it in ([alpha]). The pieces are laid
  /// by a fixed hash, so every replay of the same crossing paints the same
  /// burst.
  static void _confetti(Canvas c, double alpha) {
    if (alpha <= 0) return;
    final colors = [
      SkyColors.coral,
      SkyColors.yellow,
      SkyColors.mint,
      SkyColors.lavender,
      SkyColors.skyDeep,
      SkyColors.white,
    ];
    double hash(int i, int k) {
      final v = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
      return v - v.floorToDouble();
    }

    if (alpha < 1) {
      c.saveLayer(
        const Rect.fromLTRB(-.7, 0, .7, 1),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }
    for (var i = 0; i < 72; i++) {
      final spread = hash(i, 1), lift = hash(i, 2);
      final x = (spread - .5) * 1.1 * (.5 + lift * .5);
      final y = .05 + math.pow(lift, .85) * .72;
      // Keep the sign, the crest and the beam clear so the word stays easy
      // to read.
      if (x.abs() < .22 && y > .09 && y < .36) continue;
      final color = colors[i % colors.length];
      final fill = Paint()..color = color;
      c.save();
      c.translate(x, y);
      c.rotate(hash(i, 3) * math.pi);
      switch (i % 6) {
        case 0:
        case 1:
        case 2:
          final piece = Rect.fromCenter(
            center: Offset.zero,
            width: .028,
            height: .015,
          );
          c.drawRect(piece, fill);
          c.drawRect(piece, _line(.003));
        case 3:
        case 4:
          c.drawCircle(Offset.zero, .0095, fill);
          c.drawCircle(Offset.zero, .0095, _line(.003));
        default:
          final star = SkyScenery.star(Offset.zero, .024);
          c.drawPath(star, Paint()..color = SkyColors.yellow);
          c.drawPath(star, _line(.0042));
      }
      c.restore();
    }
    if (alpha < 1) c.restore();
  }

  /// FINISH on the sign: cream letters with an ink edge, set at pixel scale
  /// so the text stays crisp, and turned with the swinging sign.
  static void _lettering(Canvas canvas, double h, double x, double swing) {
    final size = h * .062;
    final center = Offset(x, h * (.255 + .095 / 2 + .003));
    TextPainter word(Paint? paint, Color? color) => TextPainter(
      text: TextSpan(
        text: 'FINISH',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: size,
          letterSpacing: size * .06,
          color: color,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final edge = word(
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .012
        ..strokeJoin = StrokeJoin.round,
      null,
    );
    final fill = word(null, SkyColors.cream);
    final at = center - Offset(fill.width / 2, fill.height / 2);
    canvas.save();
    if (swing != 0) {
      canvas.translate(x + _pivot.dx * h, _pivot.dy * h);
      canvas.rotate(swing);
      canvas.translate(-x - _pivot.dx * h, -_pivot.dy * h);
    }
    edge.paint(canvas, at);
    fill.paint(canvas, at);
    canvas.restore();
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _outCubic(double t) {
    final x = 1 - t.clamp(0.0, 1.0);
    return 1 - x * x * x;
  }

  static Paint _line([double width = _outline]) => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round;
}
