import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../domain/game_rules.dart';
import '../l10n/l10n.dart';
import '../l10n/text/coop_text.dart';
import '../ui/theme.dart';
import 'star_art.dart';
import 'tether_art.dart';

/// A duel's own pieces: the mystery boxes and the prizes bursting out of
/// them, the brand in its sender's colour on everything one player sent
/// after the other, and a bird's star power. Presentation only: it reads
/// the simulation and never changes it.
///
/// A box is a chunky violet gift under an ink outline: a lid with a gold
/// bow over a body printed with a big cream question mark, floating in a
/// soft ring of light. It bobs, and every few seconds its lid hops as if
/// something inside wants out. Opened, it pops in the opener's colour: the
/// lid flies off, confetti scatters and the prize's sticker jumps out, then
/// flies to where it acts, into the opener's bird for a help, off toward the
/// rival for an attack. A help's sticker is round; an attack's has a spiky
/// rim. Reduced Motion keeps the box still and shows the open box under its
/// prize without the pop or the flight.
abstract final class DuelArt {
  /// A closed box's side, in viewport heights: its body and lid fill the
  /// circle a bird or rock opens it within ([MysteryBox.radius]).
  static const side = .08;

  /// A prize sticker's radius over a burst, in viewport heights.
  static const stickerRadius = .046;

  // The gift's violet, gold bow and print.
  static const _violet = Color(0xff9274f4),
      _violetLit = Color(0xffbba6ff),
      _violetDeep = Color(0xff6447cc),
      _lidLit = Color(0xffcbbaff);
  static const _ink = SkyColors.ink;

  /// Seconds between a closed box's hops, and how long one lasts.
  static const _hopEvery = 2.6, _hopSeconds = .5;

  // ------------------------------------------------------------- boxes --

  /// Every closed box on screen, under the birds.
  static void boxes(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height;
    for (final box in sim.boxes) {
      final x = box.x * h;
      if (box.opened || x < -h * .3 || x > size.width + h * .3) continue;
      _closed(canvas, h, box, sim.elapsed, reducedMotion);
    }
  }

  /// Every box bursting open, over the birds, so the bird that flew into
  /// one never hides its pop or its prize.
  static void bursts(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height;
    for (final box in sim.boxes) {
      final opened = box.openedAt;
      final x = box.x * h;
      if (opened == null || x < -h * .3 || x > size.width + h * .3) continue;
      _burst(
        canvas,
        size,
        sim,
        box,
        (sim.elapsed - opened) / MysteryBox.burstSeconds,
        reducedMotion: reducedMotion,
      );
    }
  }

  static void _closed(
    Canvas canvas,
    double h,
    MysteryBox box,
    double seconds,
    bool reducedMotion,
  ) {
    final s = h * side;
    var center = Offset(box.x, box.y) * h;
    var tilt = 0.0, lift = 0.0, turn = 0.0, squash = 0.0;
    var hop = -1.0, glint = -1.0;
    if (!reducedMotion) {
      center += Offset(0, math.sin(seconds * 2.6 + box.phase) * .008 * h);
      tilt = math.sin(seconds * 1.7 + box.phase) * .06;
      final clock = seconds + box.phase * 1.37;
      final cycle = (clock % _hopEvery) / _hopSeconds;
      if (cycle < 1) {
        hop = cycle;
        lift = math.sin(cycle * math.pi) * .13;
        turn = math.sin(cycle * math.pi * 2) * .16 * (1 - cycle);
        squash = math.sin(cycle * math.pi * 2) * .06;
      }
      final shine = ((clock + _hopEvery * .55) % _hopEvery) / .55;
      if (shine < 1) glint = shine;
    }
    _halo(
      canvas,
      center,
      s,
      turn: reducedMotion ? 0 : seconds * .45 + box.phase,
    );
    canvas
      ..save()
      ..translate(center.dx, center.dy + s * .48)
      ..rotate(tilt)
      ..scale(s * (1 + squash), s * (1 - squash))
      ..translate(0, -.48);
    _shadow(canvas, lift: lift);
    _body(canvas, glint: glint);
    _lid(canvas, const Offset(0, -.27) - Offset(0, lift), turn);
    if (hop >= 0) {
      // Something inside pushes the lid up: two twinkles squeeze out.
      final grow = math.sin(hop * math.pi);
      for (final dir in [-1.0, 1.0]) {
        _twinkleAt(
          canvas,
          Offset(dir * (.42 + .22 * hop), -.2 - lift - .3 * hop),
          .15 * grow,
          rotation: dir * hop,
        );
      }
    }
    canvas.restore();
  }

  /// The ring of light behind a closed box: a soft bloom and slow rays.
  static void _halo(Canvas canvas, Offset center, double s, {double turn = 0}) {
    canvas
      ..save()
      ..translate(center.dx, center.dy - s * .05)
      ..scale(s)
      ..drawCircle(Offset.zero, 1.25, _haloGlow)
      ..rotate(turn)
      ..drawPath(_rays, _rayPaint)
      ..restore();
  }

  static void _shadow(Canvas canvas, {double lift = 0}) {
    canvas
      ..drawRRect(_bodyShape.shift(const Offset(.04, .08)), _shade)
      ..drawRRect(_lidShape.shift(Offset(.04, -.27 - lift + .08)), _shade);
  }

  /// The box's body in box units (its side is 1), centred on the box.
  static void _body(Canvas canvas, {double glint = -1, bool open = false}) {
    canvas
      ..drawRRect(_bodyShape.inflate(_outline), _inkFill)
      ..drawRRect(_bodyShape, _deepFill)
      ..drawRRect(_bodyFace, _bodyPaint);
    if (glint >= 0) {
      // A band of light sweeps across the print, lower left to upper right.
      canvas
        ..save()
        ..clipRRect(_bodyFace)
        ..rotate(math.pi / 4)
        ..drawRect(
          Rect.fromCenter(
            center: Offset(0, .9 - glint * 1.8),
            width: 2,
            height: .2,
          ),
          Paint()
            ..color = SkyColors.white.withValues(
              alpha: .55 * math.sin(glint * math.pi),
            ),
        )
        ..restore();
    }
    canvas
      // The lid's shadow across the top of the body, or with the lid off,
      // the dark inside of the box.
      ..drawRRect(open ? _mouth : _lidShadow, open ? _insideFill : _underLid)
      ..drawPath(_bodyGloss, _glossStroke)
      ..drawPath(_mark, _markInk)
      ..drawCircle(_markDot, .11, _inkFill)
      ..drawPath(_mark, _markCream)
      ..drawCircle(_markDot, .062, _creamFill);
  }

  /// The lid, its ribbon and bow, its centre at [at] in box units, turned
  /// by [turn].
  static void _lid(Canvas canvas, Offset at, double turn) {
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(turn)
      ..drawPath(_bowLoops, _bowInk)
      ..drawRRect(_lidShape.inflate(_outline), _inkFill)
      ..drawRRect(_lidShape, _deepFill)
      ..drawRRect(_lidFace, _lidPaint)
      ..drawRect(const Rect.fromLTRB(-.1, -.15, .1, .15), _ribbonFill)
      ..drawRect(const Rect.fromLTRB(.05, -.15, .1, .15), _ribbonShadeFill)
      ..drawPath(_lidGloss, _glossStroke)
      ..drawPath(_bowLoops, _ribbonFill)
      ..drawPath(_bowHoles, _ribbonShadeFill)
      ..drawRRect(_knot.inflate(_outline * .8), _inkFill)
      ..drawRRect(_knot, _ribbonFill)
      ..restore();
  }

  // Box geometry, in box units: the body below, the lid over its top.
  static const _outline = .075;
  static final _bodyShape = RRect.fromLTRBR(
    -.45,
    -.16,
    .45,
    .52,
    const Radius.circular(.1),
  );
  static final _bodyFace = RRect.fromLTRBR(
    -.45,
    -.16,
    .38,
    .44,
    const Radius.circular(.09),
  );
  static final _lidShadow = RRect.fromLTRBR(-.45, -.16, .45, -.06, Radius.zero);
  static final _mouth = RRect.fromLTRBR(
    -.37,
    -.13,
    .37,
    -.02,
    const Radius.circular(.045),
  );
  static final _lidShape = RRect.fromLTRBR(
    -.54,
    -.15,
    .54,
    .15,
    const Radius.circular(.08),
  );
  static final _lidFace = RRect.fromLTRBR(
    -.54,
    -.15,
    .54,
    .07,
    const Radius.circular(.07),
  );
  static final _knot = RRect.fromLTRBR(
    -.1,
    -.27,
    .1,
    -.08,
    const Radius.circular(.06),
  );
  static final Path _bowLoops = () {
    final path = Path();
    for (final dir in [-1.0, 1.0]) {
      path
        ..moveTo(0, -.16)
        ..cubicTo(dir * .04, -.5, dir * .46, -.56, dir * .4, -.27)
        ..cubicTo(dir * .36, -.13, dir * .14, -.12, 0, -.16)
        ..close();
    }
    return path;
  }();
  static final Path _bowHoles = () {
    final path = Path();
    for (final dir in [-1.0, 1.0]) {
      path
        ..moveTo(dir * .1, -.2)
        ..cubicTo(dir * .12, -.38, dir * .32, -.4, dir * .3, -.26)
        ..cubicTo(dir * .28, -.2, dir * .18, -.19, dir * .1, -.2)
        ..close();
    }
    return path;
  }();
  static final _bodyGloss = Path()
    ..moveTo(-.35, .28)
    ..lineTo(-.35, -.0);
  static final _lidGloss = Path()
    ..moveTo(-.42, -.06)
    ..lineTo(-.22, -.06);

  /// The question mark's hook and stem, and its dot.
  static final _mark = Path()
    ..moveTo(-.2, .05)
    ..cubicTo(-.2, -.13, .14, -.14, .14, .03)
    ..cubicTo(.14, .14, -.03, .13, -.03, .25);
  static const _markDot = Offset(-.03, .37);

  static final _inkFill = Paint()..color = _ink;
  static final _deepFill = Paint()..color = _violetDeep;
  static final _creamFill = Paint()..color = SkyColors.cream;
  static final _shade = Paint()..color = _ink.withValues(alpha: .2);
  static final _underLid = Paint()..color = _violetDeep.withValues(alpha: .7);
  static final _insideFill = Paint()..color = const Color(0xff33246e);
  static final _ribbonFill = Paint()..color = SkyColors.yellow;
  static final _ribbonShadeFill = Paint()..color = SkyColors.gold;
  static final _bodyPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_violetLit, _violet],
      stops: [.05, .6],
    ).createShader(const Rect.fromLTRB(-.45, -.16, .38, .44));
  static final _lidPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_lidLit, _violetLit],
    ).createShader(const Rect.fromLTRB(-.54, -.15, .54, .07));
  static final _bowInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = _outline * 2
    ..strokeJoin = StrokeJoin.round;
  static final _glossStroke = Paint()
    ..color = SkyColors.white.withValues(alpha: .75)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .07
    ..strokeCap = StrokeCap.round;
  static final _markInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .29
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _markCream = Paint()
    ..color = SkyColors.cream
    ..style = PaintingStyle.stroke
    ..strokeWidth = .135
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Additive light only brightens: a bloom on bright skies, a lamp on dark.
  static final _haloGlow = Paint()
    ..blendMode = BlendMode.plus
    ..shader = RadialGradient(
      colors: [
        const Color(0xfffff3c4).withValues(alpha: .5),
        _violetLit.withValues(alpha: .26),
        _violetLit.withValues(alpha: 0),
      ],
      stops: const [.25, .55, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.25));
  static final Path _rays = () {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      const spread = .16;
      final reach = i.isEven ? 1.32 : 1.08;
      Offset at(double angle, double r) =>
          Offset(math.cos(angle), math.sin(angle)) * r;
      final p0 = at(a - spread, .5), p1 = at(a, reach), p2 = at(a + spread, .5);
      path
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
    }
    return path;
  }();
  static final _rayPaint = Paint()
    ..shader = RadialGradient(
      colors: [
        SkyColors.cream.withValues(alpha: .7),
        SkyColors.cream.withValues(alpha: 0),
      ],
      stops: const [.35, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.32));

  // ------------------------------------------------------------ bursts --

  /// An opened box, [t] from 0 as it opens to 1 as its burst ends.
  static void _burst(
    Canvas canvas,
    Size size,
    FlightSimulation sim,
    MysteryBox box,
    double t, {
    required bool reducedMotion,
  }) {
    if (t < 0 || t >= 1) return;
    final h = size.height, s = h * side;
    final player = (box.opener ?? 0) % 2;
    final color = TetherArt.players[player];
    final center = Offset(box.x, box.y) * h;
    final prize = box.prize;
    // The sticker holds still on screen where the box opened, while the
    // course scrolls the box away under it: up and ahead of the box, clear
    // of a bird that flew into it and of its player tag.
    final scroll = sim.speed * sim.courseBoost * MysteryBox.burstSeconds;
    final from = center + Offset(scroll * t * h, 0);
    var rest = from + Offset(s * .3, -s * 2.4);
    // Near the top of the sky it shows under the box instead.
    if (rest.dy < h * .08) rest = from + Offset(s * .3, s * 2.2);
    if (reducedMotion) {
      // The open box stays put under its prize, then both go.
      if (t < .7) {
        canvas
          ..save()
          ..translate(center.dx, center.dy)
          ..scale(s);
        _body(canvas, open: true);
        // The lid sits popped askew on one corner, the box open beside it.
        _lid(canvas, const Offset(.22, -.4), .4);
        canvas.restore();
      }
      if (prize != null) {
        prizeIcon(
          canvas,
          rest,
          h * stickerRadius,
          prize,
          color: color,
          opacity: 1 - _smooth((t - .75) / .25),
        );
      }
      return;
    }
    final seed = box.phase * 7.31;
    final away = (seed.floor()).isEven ? 1.0 : -1.0;

    // A shock ring in the opener's colour.
    final ring = _outCubic(t / .45);
    if (ring < 1) {
      canvas.drawCircle(
        center,
        s * (.6 + 1.6 * ring),
        Paint()
          ..color = color.withValues(alpha: 1 - ring)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .24 * (1 - ring),
      );
    }

    // The pop: an inked splash in the opener's colour that jumps out and
    // snaps away.
    final pop = t < .1 ? _outBack(t / .1) : 1 - _smooth((t - .14) / .18);
    if (pop > 0) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(seed)
        ..scale(s * .8 * pop)
        ..drawPath(_splash, _splashInk)
        ..drawPath(_splash, Paint()..color = color)
        ..drawCircle(Offset.zero, .46, _creamFill)
        ..restore();
    }

    // The empty box bulges as it opens, then pops away.
    final bodyScale = t < .12
        ? 1 + .18 * math.sin(t / .12 * math.pi)
        : 1 - _smooth((t - .26) / .16);
    if (bodyScale > 0) {
      canvas
        ..save()
        ..translate(center.dx, center.dy + s * .48)
        ..scale(s * bodyScale)
        ..translate(0, -.48);
      _body(canvas, open: true);
      canvas.restore();
    }

    // Confetti in the opener's colour, gold, cream and violet.
    _confetti(canvas, center, s, t, seed, color);

    // The lid flies off, tumbling.
    if (t < .55) {
      final shrink = 1 - _smooth((t - .3) / .25);
      final at =
          center + Offset(away * 1.5 * t, -.27 - 3.4 * t + 4.2 * t * t) * s;
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..scale(s * shrink);
      _lid(canvas, Offset.zero, away * 5 * t);
      canvas.restore();
    }

    if (prize == null) return;
    // The sticker jumps out of the box, hangs a moment over it, then flies
    // to where the prize acts.
    final appear = t < .07 ? 0.0 : _outBack(((t - .07) / .25).clamp(0, 1));
    var at = Offset.lerp(from, rest, _outCubic((t - .07) / .3))!;
    var scale = appear;
    var opacity = 1.0;
    if (t > .6) {
      final u = (t - .6) / .4;
      final ease = u * u;
      final target = _prizeTarget(size, sim, player, prize);
      at = Offset.lerp(rest, target, ease)!;
      if (prize.attack) {
        // A streak behind it, back the way it came.
        final back = rest - at;
        final length = back.distance;
        if (length > 1) {
          // A tapering streak in the opener's colour.
          final along = back / length;
          final tail = at + along * math.min(length, s * 2.6);
          final wide =
              Offset(-along.dy, along.dx) * (h * stickerRadius * scale * .7);
          canvas.drawPath(
            Path()
              ..moveTo(at.dx + wide.dx, at.dy + wide.dy)
              ..lineTo(tail.dx, tail.dy)
              ..lineTo(at.dx - wide.dx, at.dy - wide.dy)
              ..close(),
            Paint()
              ..shader = ui.Gradient.linear(at, tail, [
                color.withValues(alpha: .85),
                color.withValues(alpha: 0),
              ]),
          );
        }
        scale *= 1 - .25 * ease;
      } else {
        scale *= 1 - .6 * ease;
      }
      opacity = 1 - _smooth((u - .7) / .3);
    }
    prizeIcon(
      canvas,
      at,
      h * stickerRadius * scale,
      prize,
      color: color,
      opacity: opacity,
    );
  }

  /// Where [player]'s [prize] flies at the end of its burst, in pixels:
  /// into their own bird for a help, toward where an attack comes from.
  static Offset _prizeTarget(
    Size size,
    FlightSimulation sim,
    int player,
    BoxPrize prize,
  ) {
    final h = size.height;
    final flock = sim.flock;
    if (flock.length < 2) return Offset(size.width + h * .3, h * .5);
    final bird = flock[player], rival = flock[1 - player];
    return switch (prize) {
      BoxPrize.heart ||
      BoxPrize.shield ||
      BoxPrize.starPower => Offset(bird.x * h, bird.y * h),
      BoxPrize.meteorShower => Offset((rival.x + .45) * h, -h * .25),
      BoxPrize.batSwarm ||
      BoxPrize.spitter => Offset(size.width + h * .25, rival.y * h),
    };
  }

  static void _confetti(
    Canvas canvas,
    Offset center,
    double s,
    double t,
    double seed,
    Color color,
  ) {
    final fade = 1 - _smooth((t - .4) / .4);
    if (fade <= 0) return;
    final colors = [color, SkyColors.yellow, SkyColors.cream, _violetLit];
    final pieces = [for (final _ in colors) Path()];
    final fly = _outCubic(t / .7);
    for (var i = 0; i < 10; i++) {
      final jitter = _hash(seed + i * 1.618);
      final angle = i * math.pi * 2 / 10 + jitter * .6;
      final speed = 1.2 + 1.0 * _hash(seed * 1.3 + i * 2.7);
      final at =
          center +
          Offset(math.cos(angle), math.sin(angle) - .25) * (speed * fly * s) +
          Offset(0, s * 1.5 * t * t);
      final spin = angle + t * (i.isEven ? 9 : -9);
      final w = s * .13 * fade, l = s * .07 * fade;
      final along = Offset(math.cos(spin), math.sin(spin));
      final across = Offset(-along.dy, along.dx);
      final a = at + along * w + across * l, b = at + along * w - across * l;
      final c = at - along * w - across * l, d = at - along * w + across * l;
      pieces[i % colors.length]
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(d.dx, d.dy)
        ..close();
    }
    for (final (i, piece) in pieces.indexed) {
      canvas.drawPath(piece, Paint()..color = colors[i]);
    }
  }

  static final Path _splash = () {
    final path = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final a = i * math.pi / points;
      final r = i.isEven ? 1.0 : .64;
      final p = Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();
  static final _splashInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .16
    ..strokeJoin = StrokeJoin.round;

  // ----------------------------------------------------------- stickers --

  /// [prize]'s round sticker, [radius] pixels, with a rim in [color]: a
  /// smooth rim for a help, a spiky one for an attack, around a cream face
  /// printed with the prize.
  static void prizeIcon(
    Canvas canvas,
    Offset center,
    double radius,
    BoxPrize prize, {
    required Color color,
    double opacity = 1,
  }) {
    if (opacity <= 0 || !(radius > 0)) return;
    final fading = opacity < 1;
    if (fading) {
      // Fade the sticker as one piece, so its layers don't show through.
      canvas.saveLayer(
        Rect.fromCircle(center: center, radius: radius * 1.6),
        Paint()..color = SkyColors.white.withValues(alpha: opacity),
      );
    }
    final rim = prize.attack ? _spikes : _round;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(radius)
      ..save()
      ..translate(0, .14)
      ..drawPath(rim, _shade)
      ..restore()
      ..drawPath(rim, _rimInk)
      ..drawPath(rim, Paint()..color = Color.lerp(color, _ink, .22)!)
      ..save()
      ..translate(0, -.06)
      ..scale(.97)
      ..drawPath(rim, Paint()..color = color)
      ..restore()
      ..drawCircle(Offset.zero, .74, _inkFill)
      ..drawCircle(Offset.zero, .68, _creamFill)
      ..drawArc(
        const Rect.fromLTRB(-.68, -.68, .68, .68),
        .2,
        math.pi * .8,
        false,
        _faceShade,
      )
      ..drawArc(
        const Rect.fromLTRB(-.84, -.84, .84, .84),
        math.pi * 1.1,
        math.pi * .32,
        false,
        _rimGloss,
      );
    _glyph(canvas, prize);
    canvas.restore();
    if (fading) canvas.restore();
  }

  static void _glyph(Canvas canvas, BoxPrize prize) {
    switch (prize) {
      case BoxPrize.heart:
        canvas
          ..drawPath(_heart, _fill(SkyColors.coralDeep))
          ..drawPath(_heartLit, _fill(SkyColors.coral))
          ..drawPath(_heart, _glyphInk)
          ..drawOval(
            const Rect.fromLTRB(-.36, -.3, -.2, -.2),
            _fill(SkyColors.white.withValues(alpha: .9)),
          );
      case BoxPrize.shield:
        canvas
          ..drawPath(_shield, _fill(SkyColors.teal))
          ..drawPath(_shieldLit, _fill(SkyColors.mint))
          ..drawPath(_shieldCross, _crossStroke)
          ..drawPath(_shield, _glyphInk);
      case BoxPrize.starPower:
        // The star in the rainbow burst it lights around its bird.
        canvas
          ..save()
          ..scale(4.5);
        for (final (i, ray) in _auraRays.indexed) {
          canvas.drawPath(ray, _fill(_rainbow[i]));
        }
        canvas.restore();
        StarArt.mini(canvas, const Offset(0, .02), .42, outline: .07);
      case BoxPrize.batSwarm:
        for (final at in [const Offset(-.36, -.36), const Offset(.38, -.32)]) {
          canvas
            ..save()
            ..translate(at.dx, at.dy)
            ..scale(.26)
            ..drawPath(_bat, _fill(SkyColors.purple))
            ..drawPath(_bat, _thickInk)
            ..restore();
        }
        canvas
          ..save()
          ..translate(0, .14)
          ..scale(.66)
          ..drawPath(_bat, _fill(SkyColors.purple))
          ..drawPath(_batLit, _fill(SkyColors.lavender))
          ..drawPath(_bat, _thickInk)
          ..drawCircle(const Offset(-.08, -.02), .07, _fill(SkyColors.yellow))
          ..drawCircle(const Offset(.08, -.02), .07, _fill(SkyColors.yellow))
          ..restore();
      case BoxPrize.spitter:
        // A flying beetle, buzzing wing up, spitting to the left.
        const head = Offset(-.16, .07), eye = Offset(-.21, .01);
        canvas
          ..drawPath(_beetleWing, _fill(_beetleWingTint))
          ..drawPath(_beetleWing, _glyphInk)
          ..drawPath(_beetleLegs, _legInk)
          ..drawPath(_beetleShell, _fill(_beetleDeep))
          ..drawPath(_beetleShellLit, _fill(_beetleLeaf))
          ..drawPath(_beetleSeam, _seamInk)
          ..drawPath(_beetleShell, _glyphInk)
          ..drawPath(_beetleFeelers, _legInk)
          ..drawCircle(const Offset(-.33, -.36), .045, _inkFill)
          ..drawCircle(const Offset(-.1, -.4), .045, _inkFill)
          ..drawRRect(_beetleSpout, _fill(_beetleJade))
          ..drawRRect(_beetleSpout, _glyphInk)
          ..drawCircle(head, .18, _fill(_beetleJade))
          ..drawCircle(head, .18, _glyphInk)
          ..drawCircle(eye, .085, _creamFill)
          ..drawCircle(eye, .085, _seamInk)
          ..drawCircle(eye - const Offset(.03, -.01), .045, _inkFill)
          ..drawPath(_spitDrop, _fill(_beetleSpit))
          ..drawPath(_spitDrop, _glyphInk);
      case BoxPrize.meteorShower:
        canvas
          ..drawPath(_flameSmall, _fill(_ember))
          ..drawPath(_flameSmall, _glyphInk)
          ..drawCircle(const Offset(-.4, -.36), .085, _fill(_rock))
          ..drawCircle(const Offset(-.4, -.36), .085, _glyphInk)
          ..drawPath(_flame, _fill(_ember))
          ..drawPath(_flameCore, _fill(SkyColors.yellow))
          ..drawPath(_flame, _glyphInk)
          ..drawPath(_rockShape, _fill(_rock))
          ..drawPath(_rockLit, _fill(_rockLight))
          ..drawCircle(const Offset(-.22, .22), .055, _fill(_rock))
          ..drawCircle(const Offset(-.03, .08), .04, _fill(_rock))
          ..drawPath(_rockShape, _glyphInk);
    }
  }

  static Paint _fill(Color color) => Paint()..color = color;

  static final Path _round = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1));
  static final Path _spikes = () {
    final path = Path();
    const points = 9;
    for (var i = 0; i < points * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / points;
      final r = i.isEven ? 1.2 : .9;
      final p = Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();
  static final _rimInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .2
    ..strokeJoin = StrokeJoin.round;
  static final _faceShade = Paint()
    ..color = const Color(0xffeadfc8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .1;
  static final _rimGloss = Paint()
    ..color = SkyColors.white.withValues(alpha: .7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .09
    ..strokeCap = StrokeCap.round;
  static final _glyphInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .07
    ..strokeJoin = StrokeJoin.round;
  static final _thickInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .14
    ..strokeJoin = StrokeJoin.round;

  /// [path] scaled by [scale] and moved by [offset].
  static Path _placed(Path path, double scale, [Offset offset = Offset.zero]) =>
      path.transform(
        Float64List.fromList([
          scale, 0, 0, 0, //
          0, scale, 0, 0, //
          0, 0, 1, 0, //
          offset.dx, offset.dy, 0, 1,
        ]),
      );

  /// The part of [path] lit from the upper left.
  static Path _litPart(Path path, Offset shift) =>
      Path.combine(PathOperation.intersect, path, path.shift(shift));

  static final _heart = _placed(
    Path()
      ..moveTo(0, .95)
      ..cubicTo(-.28, .68, -1, .20, -1, -.30)
      ..cubicTo(-1, -.93, -.30, -1.12, 0, -.55)
      ..cubicTo(.30, -1.12, 1, -.93, 1, -.30)
      ..cubicTo(1, .20, .28, .68, 0, .95)
      ..close(),
    .48,
    const Offset(0, .04),
  );
  static final _heartLit = _litPart(_heart, const Offset(-.06, -.09));

  static final _shield = Path()
    ..moveTo(0, -.5)
    ..quadraticBezierTo(.22, -.36, .44, -.36)
    ..lineTo(.38, .1)
    ..quadraticBezierTo(.28, .4, 0, .52)
    ..quadraticBezierTo(-.28, .4, -.38, .1)
    ..lineTo(-.44, -.36)
    ..quadraticBezierTo(-.22, -.36, 0, -.5)
    ..close();
  static final _shieldLit = _litPart(_shield, const Offset(-.08, -.08));
  static final _shieldCross = Path()
    ..moveTo(0, -.3)
    ..lineTo(0, .3)
    ..moveTo(-.22, -.05)
    ..lineTo(.22, -.05);
  static final _crossStroke = Paint()
    ..color = SkyColors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = .11
    ..strokeCap = StrokeCap.round;

  /// A bat, wings spread, facing out of the sticker; about 2 wide.
  static final Path _bat = () {
    // The right half from between the ears to under the body, as
    // (control, end) pairs; the left half mirrors it back.
    const right = [
      (Offset(.05, -.26), Offset(.12, -.42)),
      (Offset(.17, -.3), Offset(.2, -.14)),
      (Offset(.55, -.46), Offset(1.0, -.3)),
      (Offset(.88, -.06), Offset(.92, .2)),
      (Offset(.76, .04), Offset(.62, .17)),
      (Offset(.5, .04), Offset(.36, .18)),
      (Offset(.26, .12), Offset(.17, .3)),
      (Offset(.1, .4), Offset(0, .4)),
    ];
    const start = Offset(0, -.18);
    final path = Path()..moveTo(start.dx, start.dy);
    for (final (c, e) in right) {
      path.quadraticBezierTo(c.dx, c.dy, e.dx, e.dy);
    }
    for (var i = right.length - 1; i >= 0; i--) {
      final c = right[i].$1;
      final e = i == 0 ? start : right[i - 1].$2;
      path.quadraticBezierTo(-c.dx, c.dy, -e.dx, e.dy);
    }
    return path..close();
  }();
  static final _batLit = _litPart(_bat, const Offset(-.08, -.12));

  static const _beetleDeep = Color(0xff2a9474),
      _beetleLeaf = Color(0xff7fd4a0),
      _beetleJade = Color(0xff3f9a7c),
      _beetleSpit = Color(0xffb3ffda),
      _beetleWingTint = Color(0xffe4fbf0);
  static final _beetleShell = Path()
    ..moveTo(-.06, .2)
    ..cubicTo(-.1, -.14, .1, -.32, .32, -.3)
    ..cubicTo(.56, -.28, .66, -.04, .6, .14)
    ..quadraticBezierTo(.52, .28, .26, .28)
    ..quadraticBezierTo(.04, .28, -.06, .2)
    ..close();
  static final _beetleShellLit = _litPart(
    _beetleShell,
    const Offset(-.06, -.1),
  );
  static final _beetleSeam = Path()
    ..moveTo(.3, -.29)
    ..quadraticBezierTo(.2, -.04, .3, .27);
  static final _beetleWing = Path()
    ..moveTo(.26, -.26)
    ..cubicTo(.3, -.5, .62, -.62, .7, -.5)
    ..cubicTo(.76, -.38, .56, -.24, .4, -.2)
    ..close();
  static final _beetleSpout = RRect.fromLTRBR(
    -.44,
    .07,
    -.28,
    .17,
    const Radius.circular(.04),
  );
  static final _spitDrop = Path()
    ..moveTo(-.44, .03)
    ..quadraticBezierTo(-.5, -.04, -.56, -.04)
    ..arcToPoint(
      const Offset(-.56, .1),
      radius: const Radius.circular(.07),
      clockwise: false,
    )
    ..quadraticBezierTo(-.5, .1, -.44, .03)
    ..close();
  static final _seamInk = Paint()
    ..color = _ink.withValues(alpha: .8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .05
    ..strokeCap = StrokeCap.round;
  static final _beetleLegs = Path()
    ..moveTo(.04, .24)
    ..lineTo(-.04, .4)
    ..moveTo(.26, .27)
    ..lineTo(.24, .43)
    ..moveTo(.48, .24)
    ..lineTo(.54, .4);
  static final _beetleFeelers = Path()
    ..moveTo(-.2, -.08)
    ..quadraticBezierTo(-.24, -.3, -.33, -.36)
    ..moveTo(-.12, -.1)
    ..quadraticBezierTo(-.08, -.3, -.1, -.4);
  static final _legInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .07
    ..strokeCap = StrokeCap.round;

  static const _rock = Color(0xff5a4652),
      _rockLight = Color(0xff8c7180),
      _ember = Color(0xffff8c4a);
  static final _rockShape = Path()
    ..moveTo(-.42, .1)
    ..quadraticBezierTo(-.44, -.1, -.24, -.13)
    ..quadraticBezierTo(-.06, -.2, .06, -.05)
    ..quadraticBezierTo(.16, .08, .1, .25)
    ..quadraticBezierTo(.02, .42, -.18, .42)
    ..quadraticBezierTo(-.4, .4, -.42, .1)
    ..close();
  static final _rockLit = _litPart(_rockShape, const Offset(-.07, -.09));

  /// The big meteor's flame, licking up to the right behind the rock.
  static final _flame = Path()
    ..moveTo(-.36, -.02)
    ..quadraticBezierTo(-.18, -.36, .18, -.38)
    ..quadraticBezierTo(.42, -.42, .6, -.6)
    ..quadraticBezierTo(.52, -.42, .38, -.31)
    ..quadraticBezierTo(.52, -.28, .58, -.2)
    ..quadraticBezierTo(.32, -.12, .12, .14)
    ..close();
  static final _flameCore = Path()
    ..moveTo(-.22, -.04)
    ..quadraticBezierTo(-.06, -.26, .18, -.28)
    ..quadraticBezierTo(.32, -.3, .44, -.42)
    ..quadraticBezierTo(.36, -.26, .26, -.19)
    ..quadraticBezierTo(.14, -.06, .04, .06)
    ..close();

  /// A small meteor ahead of it, the shower's next.
  static final _flameSmall = Path()
    ..moveTo(-.46, -.39)
    ..quadraticBezierTo(-.34, -.56, -.12, -.6)
    ..quadraticBezierTo(-.22, -.44, -.33, -.3)
    ..close();

  // -------------------------------------------------------------- marks --

  /// A brand in its sender's colour under every enemy, pellet, bat and
  /// meteor one duel player sent after the other: a lit ring around each
  /// (one ring around a whole flock of bats) and a small player tag on the
  /// leader, so the rival sees at a glance whose attack is coming.
  static void marks(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height;
    final breath = reducedMotion ? 0.0 : math.sin(sim.elapsed * 6) * .04;
    bool onScreen(Offset p) =>
        p.dx > -h * .25 && p.dx < size.width + h * .25 && p.dy > -h * .25;

    for (final enemy in sim.enemies) {
      final sender = enemy.sender;
      if (sender == null) continue;
      final at = Offset(enemy.x, enemy.y) * h;
      if (!onScreen(at)) continue;
      final r = SkyEnemy.radius * h * 1.5 * (1 + breath);
      _ring(canvas, h, at, r, sender);
      // Outside the ring: the enemy is drawn over its mark.
      _tag(
        canvas,
        h,
        at + Offset.fromDirection(-math.pi * .75, r + h * .016),
        sender,
      );
    }
    for (final ammo in sim.enemyAmmo) {
      final sender = ammo.sender;
      if (sender == null) continue;
      final at = Offset(ammo.x, ammo.y) * h;
      if (!onScreen(at)) continue;
      _ring(canvas, h, at, EnemyAmmo.radius * h * 1.6, sender, thin: true);
    }

    // A flock: bats from one sender a swarm's spacing apart.
    final batRadius = SwarmBat.radius * h * 1.45 * (1 + breath);
    for (final sender in [0, 1]) {
      final bats = [
        for (final bat in sim.swarm)
          if (bat.sender == sender) Offset(bat.x, bat.y) * h,
      ]..sort((a, b) => a.dx.compareTo(b.dx));
      var from = 0;
      for (var i = 1; i <= bats.length; i++) {
        if (i < bats.length &&
            (bats[i].dx - bats[i - 1].dx).abs() < Duel.batSpacing * 1.7 * h) {
          continue;
        }
        final flock = bats.sublist(from, i);
        from = i;
        if (!flock.any(onScreen)) continue;
        var top = flock.first.dy, bottom = top;
        for (final p in flock) {
          top = math.min(top, p.dy);
          bottom = math.max(bottom, p.dy);
        }
        final capsule = RRect.fromLTRBR(
          flock.first.dx - batRadius,
          top - batRadius,
          flock.last.dx + batRadius,
          bottom + batRadius,
          Radius.circular(batRadius),
        );
        _capsule(canvas, h, capsule, sender);
        _tag(
          canvas,
          h,
          flock.first +
              Offset.fromDirection(-math.pi * .75, batRadius + h * .012),
          sender,
        );
      }
    }

    final scroll = sim.speed * sim.courseBoost;
    for (final m in sim.meteors) {
      final sender = m.sender;
      if (sender == null) continue;
      if (m.y < -Meteor.radius) {
        // Still above the sky: tag the warning arrow where it will come in.
        if (m.vy <= 0) continue;
        final enter = -m.y / m.vy;
        final x = (m.x + (m.vx - scroll) * enter) * h;
        if (x < 0 || x > size.width) continue;
        final at = Offset(x, h * .055);
        _glow(canvas, at, h * .07, sender);
        _tag(canvas, h, at + Offset(h * .055, h * .045), sender);
        continue;
      }
      final at = Offset(m.x, m.y) * h;
      if (!onScreen(at)) continue;
      final r = Meteor.radius * h * 1.45 * (1 + breath);
      _ring(canvas, h, at, r, sender);
      _tag(
        canvas,
        h,
        at + Offset.fromDirection(math.pi * .75, r + h * .014),
        sender,
      );
    }
  }

  /// Each player's mark paints, made once: a glow on a unit circle placed
  /// with the canvas transform, and an ink and a colour stroke whose widths
  /// are set per use.
  static final _markGlows = [
    for (final color in TetherArt.players)
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: .5), color.withValues(alpha: 0)],
          stops: const [.45, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
  ];
  static final _markFills = [
    for (final color in TetherArt.players)
      Paint()..color = color.withValues(alpha: .22),
  ];
  static final _markStrokes = [
    for (final color in TetherArt.players)
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke,
  ];
  static final _inkStroke = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke;

  static void _glow(Canvas canvas, Offset at, double r, int sender) => canvas
    ..save()
    ..translate(at.dx, at.dy)
    ..scale(r)
    ..drawCircle(Offset.zero, 1, _markGlows[sender % 2])
    ..restore();

  /// A lit, ink-edged ring in [sender]'s colour around a hazard at [at].
  static void _ring(
    Canvas canvas,
    double h,
    Offset at,
    double r,
    int sender, {
    bool thin = false,
  }) {
    final width = h * (thin ? .0035 : .0075);
    _glow(canvas, at, r * 1.25, sender);
    canvas
      ..drawCircle(at, r, _inkStroke..strokeWidth = width + h * .005)
      ..drawCircle(at, r, _markStrokes[sender % 2]..strokeWidth = width);
  }

  /// The ring around a whole flock: a capsule from its first bat to its last.
  static void _capsule(Canvas canvas, double h, RRect capsule, int sender) {
    final width = h * .0075;
    canvas
      ..drawRRect(capsule.inflate(h * .012), _markFills[sender % 2])
      ..drawRRect(capsule, _inkStroke..strokeWidth = width + h * .005)
      ..drawRRect(capsule, _markStrokes[sender % 2]..strokeWidth = width);
  }

  /// A small "P1"/"P2" tag in [player]'s colour, centred on [at].
  static void _tag(Canvas canvas, double h, Offset at, int player) {
    final text = _label(player, h);
    final r = h * .0175;
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: text.width + r * 1.3, height: r * 2),
      Radius.circular(r),
    );
    canvas
      ..drawRRect(pill.shift(Offset(0, h * .004)), _tagShadow)
      ..drawRRect(pill.inflate(h * .0042), _inkFill)
      ..drawRRect(pill, _tagLips[player % 2])
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            pill.left,
            pill.top,
            pill.right,
            pill.bottom - h * .003,
          ),
          Radius.circular(r),
        ),
        _tagFaces[player % 2],
      );
    text.paint(
      canvas,
      at - Offset(text.width / 2, text.height / 2 + h * .0015),
    );
  }

  static final _tagShadow = Paint()..color = _ink.withValues(alpha: .25);
  static final _tagLips = [
    for (final color in TetherArt.players)
      Paint()..color = Color.lerp(color, _ink, .2)!,
  ];
  static final _tagFaces = [
    for (final color in TetherArt.players) Paint()..color = color,
  ];

  /// The hazard tags' lettering, laid out once per size.
  // (keyed by player, not words: a language switch empties it)
  static final _labels = L10n.cache(<(int, double), TextPainter>{});

  static TextPainter _label(int player, double h) {
    if (_labels.length > 8) {
      for (final painter in _labels.values) {
        painter.dispose();
      }
      _labels.clear();
    }
    return _labels.putIfAbsent(
      (player, h),
      () => TextPainter(
        text: TextSpan(
          text: L10n.strings.coopPlayerTag(player),
          style: TextStyle(
            fontFamily: L10n.fonts.heading,
            fontFamilyFallback: L10n.fonts.headingFallback,
            fontWeight: FontWeight.w700,
            fontSize: h * .025,
            height: 1,
            color: SkyColors.white,
          ),
        ),
        textDirection: L10n.textDirection,
      )..layout(),
    );
  }

  // --------------------------------------------------------- star power --

  /// The viewed bird's star power: a spinning rainbow burst of light behind
  /// it and twinkles circling it. Through its last second the twinkles go
  /// and the burst throbs and shrinks away; Reduced Motion holds it still
  /// and dims it instead.
  static void starPower(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final left = sim.starPowerRemaining;
    if (left <= 0) return;
    final center = Offset(sim.birdScreenX, sim.birdY) * h;
    var strength = 1.0, reach = 1.0;
    if (left < 1) {
      reach = .6 + .4 * left;
      if (reducedMotion) {
        strength = .5;
      } else {
        // It throbs, quicker as the last second runs out: a soft pulse
        // from three to six beats a second, never a hard strobe.
        final spent = 1 - left;
        final beat = math.cos(math.pi * 2 * (3 * spent + 1.5 * spent * spent));
        strength = .6 + .4 * beat;
      }
    }
    final spin = reducedMotion ? 0.0 : sim.elapsed * 1.6;
    final breath = reducedMotion ? 0.0 : math.sin(sim.elapsed * 9) * .05;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(h)
      ..drawCircle(
        Offset.zero,
        .15 * reach,
        strength == 1 ? _auraGlowFull : _auraGlow(strength),
      )
      ..save()
      ..rotate(spin)
      ..scale(reach * (1 + breath));
    for (final (i, ray) in _auraRays.indexed) {
      canvas.drawPath(
        ray,
        strength == 1
            ? _rayPaints[i]
            : (Paint()..color = _rainbow[i].withValues(alpha: .55 * strength)),
      );
    }
    canvas.restore();
    if (left >= 1) {
      for (var i = 0; i < 4; i++) {
        final angle = -spin * 1.3 + i * math.pi / 2 + math.pi / 4;
        final twinkle = reducedMotion
            ? 1.0
            : .75 + .25 * math.sin(sim.elapsed * 8 + i * 1.7);
        _twinkleAt(
          canvas,
          Offset(math.cos(angle), math.sin(angle)) * (.118 * reach),
          .017 * twinkle * reach,
          rotation: angle,
        );
      }
    }
    canvas.restore();
  }

  static const _rainbow = [
    Color(0xffff6f61),
    Color(0xffffa94d),
    SkyColors.yellow,
    Color(0xff7ddc8c),
    Color(0xff5ec2f0),
    Color(0xffb08cff),
  ];

  /// Twelve rays in viewport heights, two opposite ones per rainbow colour.
  static final List<Path> _auraRays = [
    for (var c = 0; c < _rainbow.length; c++)
      () {
        final path = Path();
        for (final i in [c, c + _rainbow.length]) {
          final a = i * math.pi * 2 / 12;
          final reach = i.isEven ? .14 : .118;
          const spread = .17;
          Offset at(double angle, double r) =>
              Offset(math.cos(angle), math.sin(angle)) * r;
          final p0 = at(a - spread, .05), p1 = at(a, reach);
          final p2 = at(a + spread, .05);
          path
            ..moveTo(p0.dx, p0.dy)
            ..lineTo(p1.dx, p1.dy)
            ..lineTo(p2.dx, p2.dy)
            ..close();
        }
        return path;
      }(),
  ];

  static final _rayPaints = [
    for (final color in _rainbow) Paint()..color = color.withValues(alpha: .55),
  ];
  static final _auraGlowFull = _auraGlow(1);

  static Paint _auraGlow(double strength) => Paint()
    ..blendMode = BlendMode.plus
    ..shader = RadialGradient(
      colors: [
        const Color(0xfffff3c4).withValues(alpha: .55 * strength),
        SkyColors.yellow.withValues(alpha: .25 * strength),
        SkyColors.yellow.withValues(alpha: 0),
      ],
      stops: const [.3, .6, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: .15));

  // ------------------------------------------------------------- shared --

  /// A four-point white twinkle with an ink edge, [radius] in canvas units.
  static void _twinkleAt(
    Canvas canvas,
    Offset at,
    double radius, {
    double rotation = 0,
  }) {
    if (radius <= 0) return;
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(rotation)
      ..scale(radius)
      ..drawPath(_twinkle, _twinkleInk)
      ..drawPath(_twinkle, _whiteFill)
      ..restore();
  }

  static final Path _twinkle = () {
    final path = Path()..moveTo(0, -1);
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      path.quadraticBezierTo(
        math.cos(a + math.pi / 4) * .2,
        math.sin(a + math.pi / 4) * .2,
        math.cos(a + math.pi / 2),
        math.sin(a + math.pi / 2),
      );
    }
    return path..close();
  }();
  static final _whiteFill = Paint()..color = SkyColors.white;
  static final _twinkleInk = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .35
    ..strokeJoin = StrokeJoin.round;

  /// A steady pseudo-random value in [0, 1) for [x].
  static double _hash(double x) {
    final v = math.sin(x * 12.9898) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _outCubic(double t) {
    final x = 1 - t.clamp(0.0, 1.0);
    return 1 - x * x * x;
  }

  static double _outBack(double t) {
    final x = t.clamp(0.0, 1.0) - 1;
    const k = 2.2;
    return 1 + (k + 1) * x * x * x + k * x * x;
  }
}

/// [DuelArt.prizeIcon] as a painter, for a prize sticker in the HUD.
class DuelPrizePainter extends CustomPainter {
  const DuelPrizePainter(this.prize, {required this.color});
  final BoxPrize prize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => DuelArt.prizeIcon(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2 / 1.25,
    prize,
    color: color,
  );

  @override
  bool shouldRepaint(DuelPrizePainter old) =>
      old.prize != prize || old.color != color;
}
