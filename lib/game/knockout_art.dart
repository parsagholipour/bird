import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/bird_motion.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'bird_puppet.dart';
import 'tether_art.dart';

/// The cartoon knockout after the last heart is lost, drawn over the frozen
/// flight. Every frame is a pure function of the seconds since the fatal
/// bump and the ended simulation, so tests can seek it and it never touches
/// the rules, the score or the journal.
///
/// Beats (full motion):
/// * 0–0.1 s: hit-stop. The world freezes, the camera kicks, a flash and a
///   starburst mark the contact and the bird squashes wide-eyed and white.
/// * 0.1–0.5 s: the bird pops up and back, feathers burst out in its own
///   colours and dizzy stars start circling its head.
/// * 0.5–1.3 s: it tumbles, spinning, and drops off the bottom of the screen
///   (or plunges into the Pirate Captain's sea with a splash and bubbles).
/// * To [seconds]: the feathers flutter down while the world settles into a
///   dim, cool, desaturated still for the game-over stage.
///
/// Reduced Motion swaps the face for the dazed one under three still stars,
/// then fades the bird out in place while the world dims: no spin, shake,
/// flash, zoom or flying pieces.
abstract final class KnockoutArt {
  /// When the game-over stage takes over from the full knockout.
  static const seconds = 1.9;

  /// When the stage takes over from the calm Reduced Motion knockout.
  static const calmSeconds = 1.2;

  /// Taps are ignored before this, so a player still mashing the screen
  /// cannot skip the moment by accident.
  static const skipAfter = .6;

  /// The frozen impact frame before anything moves.
  static const hitStop = .1;

  static double duration({required bool reducedMotion}) =>
      reducedMotion ? calmSeconds : seconds;

  static const _gravity = 2.4, _spin = 8.6;

  /// How far the world has wound down, from 0 (live) to 1 (the still).
  static double settle(double t, {required bool reducedMotion}) =>
      reducedMotion ? _smooth(t / .9) : _smooth((t - .06) / 1.05);

  /// Paint for a layer over the whole world: it slowly loses colour and
  /// light under a soft lavender dusk, so the cream stage reads on any
  /// region's sky without the world turning grey and cold.
  static Paint? worldLayer(double t, {required bool reducedMotion}) {
    final k = settle(t, reducedMotion: reducedMotion);
    if (k <= 0) return null;
    final s = 1 - .56 * k, b = 1 - .3 * k;
    const lr = .2126, lg = .7152, lb = .0722;
    final r = (1 - s) * lr, g = (1 - s) * lg, bl = (1 - s) * lb;
    return Paint()
      ..colorFilter = ColorFilter.matrix([
        b * (r + s), b * g, b * bl, 0, 12 * k, //
        b * r, b * (g + s), b * bl, 0, 4 * k, //
        b * r, b * g, b * (bl + s), 0, 24 * k, //
        0, 0, 0, 1, 0,
      ]);
  }

  /// A slow push towards the impact, as scale about [focus] in pixels.
  static double zoom(double t, {required bool reducedMotion}) =>
      reducedMotion ? 1 : 1 + .035 * _outCubic(t / .6);

  /// The impact's camera kick in screen heights, like the boss camera shake.
  static Offset cameraOffset(double t, {required bool reducedMotion}) {
    if (reducedMotion || t < 0 || t >= .42) return Offset.zero;
    final a = .014 * math.exp(-t * 8.5) * (1 - t / .42);
    return Offset(math.sin(t * 91 + .6) * a, math.cos(t * 73) * a * .8);
  }

  /// Where the world zooms from: the bird at the moment of the bump.
  static Offset focus(FlightSimulation sim, double h) =>
      Offset(sim.birdScreenX * h, sim.birdY * h);

  /// The sea the bird falls into during the Pirate Captain's encounter.
  static double? _sea(FlightSimulation sim) {
    final level = sim.boss?.waterLevel;
    // A sea still rolling in (or draining) below the screen catches nothing.
    return level == null || level > .97 ? null : level;
  }

  /// Whether the knocked-out bird falls into the Pirate Captain's sea.
  static bool atSea(FlightSimulation sim) => _sea(sim) != null;

  /// Seconds after the bump when the tumbling bird hits the sea, or null.
  static double? splashAt(FlightSimulation sim, {required bool reducedMotion}) {
    final sea = _sea(sim);
    if (sea == null || reducedMotion) return null;
    final (v0, _) = _launch(sim.birdY);
    // Solve y0 - v0 u + g u² / 2 = sea - lead for the first u after the hop.
    final drop = sea - _entryLead - sim.birdY;
    final u =
        (v0 + math.sqrt(math.max(0, v0 * v0 + 2 * _gravity * drop))) / _gravity;
    return hitStop + u;
  }

  /// The knocked-out bird's centre in screen heights at [t]: a recoil that
  /// dies away, a hop and a cartoon-floaty fall. In the sea it slows sharply
  /// once under. Reduced Motion keeps it where it was hit.
  static Offset birdCenter(
    FlightSimulation sim,
    double t, {
    required bool reducedMotion,
  }) {
    final x0 = sim.birdScreenX, y0 = sim.birdY;
    if (reducedMotion) return Offset(x0, y0);
    final u = math.max(0.0, t - hitStop);
    final (v0, _) = _launch(y0);
    final x = x0 - _recoil(u);
    final entry = splashAt(sim, reducedMotion: false);
    if (entry != null && t > entry) {
      final ue = entry - hitStop, dt = t - entry;
      final entryY = y0 - v0 * ue + _gravity * ue * ue / 2;
      final entrySpeed = -v0 + _gravity * ue;
      return Offset(
        x,
        entryY + entrySpeed * (1 - math.exp(-6 * dt)) / 6 + .05 * dt,
      );
    }
    return Offset(x, y0 - v0 * u + _gravity * u * u / 2);
  }

  static double _recoil(double u) => .14 * (1 - math.exp(-2.6 * u));

  // The splash starts as the bird's belly meets the water.
  static const _entryLead = .03;

  static (double, double) _launch(double y0) {
    final hop = (y0 - .2).clamp(0.0, .13);
    return (math.sqrt(2 * _gravity * hop), hop);
  }

  /// Draws the knockout over the dimmed world: flash, burst, feathers, the
  /// tumbling bird with its dizzy stars and, at sea, the plunge. [beak] opens
  /// the tumbling bird's beak while a line it is saying goes on through the
  /// fall (BirdPuppet.beaks); the calm Reduced Motion bird keeps it shut.
  static void paint(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required int bird,
    required double seconds,
    required bool reducedMotion,
    Offset shake = Offset.zero,
    int beak = 0,
  }) {
    final t = seconds;
    if (!t.isFinite || t < 0) return;
    final h = size.height;
    if (h <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(shake.dx, shake.dy);
    if (reducedMotion) {
      _calm(canvas, h, sim, bird, t);
    } else {
      _tumble(canvas, size, sim, bird, t, beak);
    }
    canvas.restore();
  }

  /// A co-op pair's rope, tied between the two birds as they tumble. In
  /// Reduced Motion it fades out with them.
  static void rope(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required double seconds,
    required bool reducedMotion,
    Offset shake = Offset.zero,
  }) {
    final partner = sim.partner;
    final h = size.height;
    if (partner == null ||
        !sim.roped ||
        !seconds.isFinite ||
        seconds < 0 ||
        h <= 0) {
      return;
    }
    Offset at(FlightBird bird) => sim.viewing(
      bird,
      () => birdCenter(sim, seconds, reducedMotion: reducedMotion),
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(shake.dx, shake.dy);
    TetherArt.between(
      canvas,
      h,
      at(sim.lead) + TetherArt.tie,
      at(partner) + TetherArt.tie,
      seconds: sim.elapsed,
      opacity: reducedMotion ? 1 - _smooth((seconds - .3) / .75) : 1,
      reducedMotion: reducedMotion,
    );
    canvas.restore();
  }

  // ------------------------------------------------------------- calm --

  static void _calm(
    Canvas c,
    double h,
    FlightSimulation sim,
    int bird,
    double t,
  ) {
    final fade = 1 - _smooth((t - .3) / .75);
    if (fade <= 0) return;
    final bw = h * BirdFlightMotion.size;
    final center = Offset(sim.birdScreenX * h, sim.birdY * h);
    final shrink = 1 - .08 * _smooth(t / 1.05);
    c.saveLayer(
      Rect.fromCircle(center: center, radius: bw * 1.2),
      Paint()..color = Color.fromRGBO(0, 0, 0, fade),
    );
    c.translate(center.dx, center.dy);
    c.scale(shrink);
    _bird(
      c,
      bw,
      bird,
      angle: _tilt(sim),
      expression: BirdExpression.dazed,
      wing: .25,
    );
    // Three still stars rest above the head instead of circling it.
    for (var i = 0; i < 3; i++) {
      _star(
        c,
        Offset((i - 1) * bw * .32, -bw * (.62 + (i == 1 ? .08 : 0))),
        bw * (i == 1 ? .12 : .1),
        (i - 1) * .3,
        1,
      );
    }
    c.restore();
  }

  // ------------------------------------------------------------ tumble --

  static double _tilt(FlightSimulation sim) =>
      sim.rules.mode.controlsHeight || !sim.started
      ? 0
      : BirdFlightMotion.tilt(sim.velocity);

  static void _tumble(
    Canvas c,
    Size size,
    FlightSimulation sim,
    int bird,
    double t,
    int beak,
  ) {
    final h = size.height;
    final bw = h * BirdFlightMotion.size;
    final x0 = sim.birdScreenX, y0 = sim.birdY;
    final sea = _sea(sim);
    final contact = _contact(sim);
    final u = math.max(0.0, t - hitStop);
    final entry = splashAt(sim, reducedMotion: false);
    final center = birdCenter(sim, t, reducedMotion: false) * h;
    final y = center.dy / h;
    final spin = _tilt(sim) - _spin * (u - (1 - math.exp(-5 * u)) / 5);

    _flash(c, size, t);
    _impact(c, h, bw, Offset(x0 * h, y0 * h), contact, t);

    final debris = _Debris.of(bird);
    // Feathers stay behind the bird so its dizzy face always reads.
    _feathers(c, h, bw, Offset(x0 * h, y0 * h), u, debris: debris);

    final waterline = sea == null ? null : sea * h;
    final underwater = waterline != null && entry != null && t > entry;
    if (y * h - bw * 1.3 < size.height) {
      c.save();
      if (underwater) {
        c.clipRect(Rect.fromLTRB(-size.width, -h, size.width * 2, waterline));
      }
      // Circling stars: the far side of the orbit passes behind the head.
      // The bird swells as it is knocked loose so the dazed face reads at
      // gameplay size.
      final kb = bw * (1 + .26 * _outBack(u / .26));
      final head = center + Offset(0, -kb * .5);
      _orbit(c, kb, head, u, behind: true);
      final squash = t < hitStop
          ? .17
          : .17 * math.exp(-7 * u) * math.cos(19 * u);
      c.save();
      c.translate(center.dx, center.dy);
      _bird(
        c,
        kb,
        bird,
        angle: t < hitStop ? _tilt(sim) : spin,
        scaleX: 1 - squash,
        scaleY: 1 + squash * .75,
        expression: t < hitStop
            ? BirdExpression.startled
            : BirdExpression.dazed,
        // Wings flail through the fall.
        wing: t < hitStop ? -.55 : -.2 + .62 * math.sin(u * 27),
        whiten: t < .035 ? 1 : (1 - (t - .035) / .03).clamp(0.0, 1.0),
        beak: beak,
      );
      c.restore();
      _orbit(c, kb, head, u, behind: false);
      c.restore();
    }
    if (waterline != null && entry != null && t >= entry) {
      final xe = x0 - _recoil(entry - hitStop);
      _plunge(c, h, bw, Offset(xe * h, waterline), t - entry);
    }
  }

  /// Which way the blow came from: the top or bottom edge, the sea, or the
  /// wall, enemy or shot ahead.
  static Offset _contact(FlightSimulation sim) {
    const r = FlightSimulation.birdRadius;
    final sea = _sea(sim);
    if (sim.birdY <= r + .012) return const Offset(0, -1);
    if (sim.birdY >= 1 - r - .012) return const Offset(0, 1);
    if (sea != null && sim.birdY + r >= sea - .012) return const Offset(0, 1);
    return const Offset(.97, -.24);
  }

  static void _flash(Canvas c, Size size, double t) {
    const life = .16;
    if (t >= life) return;
    final k = 1 - t / life;
    c.drawRect(
      Offset.zero & size,
      Paint()..color = SkyColors.white.withValues(alpha: .42 * k * k),
    );
  }

  /// A hot cartoon starburst and a quick shock ring where the bird hit.
  static void _impact(
    Canvas c,
    double h,
    double bw,
    Offset bird,
    Offset contact,
    double t,
  ) {
    final at = bird + contact * bw * .5;
    final ring = t / .24;
    if (ring < 1) {
      c.drawCircle(
        at,
        bw * (.3 + 1.05 * _outCubic(ring)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bw * .09 * (1 - ring)
          ..color = SkyColors.white.withValues(alpha: .95 * (1 - ring)),
      );
    }
    final k = t / .2;
    if (k >= 1) return;
    final grow = k < .3
        ? 1 + .18 * math.sin(k / .3 * math.pi)
        : 1 - _inQuad((k - .3) / .7);
    if (grow <= 0) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(math.atan2(contact.dy, contact.dx) + .2);
    c.scale(bw * .34 * grow);
    c.drawPath(_burst, Paint()..color = SkyColors.yellow);
    c.drawPath(
      _burst,
      Paint()
        ..color = SkyColors.coralDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = .09
        ..strokeJoin = StrokeJoin.round,
    );
    c.scale(.56);
    c.drawPath(_burst, Paint()..color = SkyColors.white);
    c.restore();
  }

  static void _bird(
    Canvas c,
    double bw,
    int bird, {
    required double angle,
    required BirdExpression expression,
    required double wing,
    double scaleX = 1,
    double scaleY = 1,
    double whiten = 0,
    int beak = 0,
  }) {
    c.save();
    c.rotate(angle);
    c.scale(scaleX, scaleY);
    if (whiten > 0) {
      c.saveLayer(
        Rect.fromCircle(center: Offset.zero, radius: bw),
        Paint()..colorFilter = _whiten(whiten),
      );
    }
    BirdPuppet.paint(
      c,
      Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
      bird: bird,
      wing: wing,
      expression: expression,
      beak: beak,
    );
    if (whiten > 0) c.restore();
    c.restore();
  }

  /// Fills blow out to white while the ink lines stay a readable grey.
  static ColorFilter _whiten(double w) {
    const k = 3.2, b = -80.0;
    final keep = 1 - w;
    return ColorFilter.matrix([
      keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b, //
      0, 0, 0, 1, 0,
    ]);
  }

  /// Three stars circling above the head on a tilted ring; [behind] draws
  /// the half of the orbit that passes behind the bird, smaller and dimmer.
  static void _orbit(
    Canvas c,
    double bw,
    Offset head,
    double u, {
    required bool behind,
  }) {
    final grow = _outBack((u - .04) / .18);
    if (grow <= 0) return;
    for (var i = 0; i < 3; i++) {
      final a = u * 7.5 + i * 2 * math.pi / 3;
      final depth = math.sin(a); // > 0 in front of the head
      if ((depth < 0) != behind) continue;
      final p =
          head + Offset(math.cos(a) * bw * .44, depth * bw * .13 - bw * .08);
      final near = .72 + .28 * (depth + 1) / 2;
      _star(c, p, bw * .115 * grow * near, a * .6, behind ? .8 : 1);
    }
  }

  static void _star(
    Canvas c,
    Offset at,
    double radius,
    double turn,
    double alpha,
  ) {
    if (radius <= .2) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(radius);
    c.drawPath(
      _twinkle,
      Paint()..color = SkyColors.yellow.withValues(alpha: alpha),
    );
    c.drawPath(
      _twinkle,
      Paint()
        ..color = const Color(0xffb86a2a).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.13, 1.1 / radius)
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawCircle(
      const Offset(-.12, -.14),
      .2,
      Paint()..color = SkyColors.white.withValues(alpha: alpha * .9),
    );
    c.restore();
  }

  static const _featherCount = 8;

  /// Feathers (and each bird's signature bits) burst from the bird, then
  /// rock and flutter down under drag, fading before the stage arrives.
  static void _feathers(
    Canvas c,
    double h,
    double bw,
    Offset origin,
    double u, {
    required _Debris debris,
  }) {
    if (u <= 0) return;
    for (var i = 0; i < _featherCount; i++) {
      final r1 = _hash(i, 3), r2 = _hash(i, 7), r3 = _hash(i, 11);
      // Mostly up and out, never straight down into the fall.
      final a =
          -math.pi / 2 + (i / (_featherCount - 1) - .5) * 4.6 + (r1 - .5) * .35;
      final speed = h * (.5 + .38 * r2);
      const drag = 4.2;
      final burst = speed * (1 - math.exp(-drag * u)) / drag;
      final sink = h * .16 * (u - (1 - math.exp(-2.2 * u)) / 2.2);
      final sway =
          math.sin(u * (4.2 + r3 * 1.6) + r1 * 6) *
          h *
          .022 *
          math.min(1, u * 2.5);
      final p =
          origin +
          Offset(math.cos(a), math.sin(a)) * (bw * .2 + burst) +
          Offset(sway, sink);
      final life = 1 - _smooth((u - 1.05 - r3 * .25) / .45);
      final pop = _outBack(u / .08);
      final size = bw * (.16 + .05 * r2) * pop;
      if (life <= 0 || size <= .5) continue;
      final rock = math.sin(u * (4.2 + r3 * 1.6) + r1 * 6 + 1.2);
      final turn =
          a + math.pi / 2 + (r1 - .5) * 2 * math.exp(-3 * u) + rock * .55;
      final accent = debris.accent != null && i % 3 == 1;
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(turn);
      c.scale(size * (accent ? .7 : 1));
      final alpha = life;
      if (accent) {
        debris.accent!(c, alpha);
      } else {
        _feather(c, debris, i.isOdd, alpha, 1.1 / size);
      }
      c.restore();
    }
  }

  static void _feather(
    Canvas c,
    _Debris d,
    bool second,
    double alpha,
    double line,
  ) {
    final fill = second ? d.wing : d.body;
    c.drawPath(_featherShape, Paint()..color = fill.withValues(alpha: alpha));
    c.drawPath(
      _featherShine,
      Paint()..color = d.light.withValues(alpha: alpha * .9),
    );
    c.drawPath(
      _featherShape,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.07, line)
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      _quill,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: alpha * .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.06, line * .85)
        ..strokeCap = StrokeCap.round,
    );
  }

  // -------------------------------------------------------------- sea --

  static const _foam = Color(0xfff2fffb), _crest = Color(0xff8fe3dc);
  static const _deepLine = Color(0xff123049);

  /// The KO plunge: a tall crown and two curling sheets, a spray of drops,
  /// rings on the water and a few bubbles rising from where it went under.
  static void _plunge(Canvas c, double h, double bw, Offset at, double age) {
    // Rings spread over the frozen water.
    for (var i = 0; i < 3; i++) {
      final k = (age - i * .12) / .7;
      if (k <= 0 || k >= 1) continue;
      c.drawOval(
        Rect.fromCenter(
          center: at + Offset(0, h * .004),
          width: bw * (.8 + 2.6 * _outCubic(k)),
          height: bw * (.16 + .36 * _outCubic(k)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .006 * (1 - k)
          ..color = _foam.withValues(alpha: .9 * (1 - k)),
      );
    }
    final rise = age < .13
        ? math.sin(age / .13 * math.pi / 2)
        : math.max(0.0, 1 - (age - .13) / .5);
    final fade = 1 - _smooth((age - .42) / .33);
    if (rise > 0 && fade > 0) {
      for (final side in [-1.0, 1.0]) {
        final root = at + Offset(side * bw * .3, 0);
        final tip =
            at + Offset(side * bw * (.95 + (1 - rise) * .3), -bw * 1.05 * rise);
        final sheet = Path()
          ..moveTo(root.dx - side * bw * .16, root.dy)
          ..quadraticBezierTo(root.dx, root.dy - bw * .9 * rise, tip.dx, tip.dy)
          ..quadraticBezierTo(
            tip.dx + side * bw * .2,
            tip.dy + bw * .14,
            tip.dx + side * bw * .1,
            tip.dy + bw * .32,
          )
          ..quadraticBezierTo(
            root.dx + side * bw * .3,
            root.dy - bw * .2,
            root.dx + side * bw * .42,
            root.dy,
          )
          ..close();
        c.drawPath(
          sheet,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .006
            ..strokeJoin = StrokeJoin.round
            ..color = _deepLine.withValues(alpha: .5 * fade),
        );
        c.drawPath(sheet, Paint()..color = _crest.withValues(alpha: fade));
        c.drawCircle(
          tip,
          bw * .09,
          Paint()..color = _foam.withValues(alpha: fade),
        );
      }
      // A ragged crown of water rings the hole the bird left.
      _crown(c, h, at, bw * .62 * (1 + (1 - rise) * .25), bw * .8 * rise, fade);
    }
    // Drops arc out and fall back.
    for (var i = 0; i < 12; i++) {
      final a = -math.pi / 2 + (i - 5.5) * .2;
      final speed = h * (1.0 + _hash(i, 21) * .55);
      final p =
          at +
          Offset(math.cos(a) * speed * age, math.sin(a) * speed * age) +
          Offset(0, h * 3.4 * age * age);
      if (p.dy > at.dy) continue;
      final r = h * (.006 + (i % 3) * .002) * (1 - _smooth((age - .4) / .35));
      if (r <= 0) continue;
      c.drawCircle(
        p,
        r + h * .002,
        Paint()..color = _deepLine.withValues(alpha: .35),
      );
      c.drawCircle(p, r, Paint()..color = _foam);
    }
    // Bubbles rise from below the surface and pop.
    for (var i = 0; i < 5; i++) {
      final k = (age - .2 - i * .1) / .35;
      if (k <= 0 || k >= 1) continue;
      final p =
          at + Offset((_hash(i, 31) - .5) * bw * .9, -bw * (.05 + .35 * k));
      final r = bw * (.07 + .05 * _hash(i, 41)) * (k < .85 ? 1 : (1 - k) / .15);
      c.drawCircle(
        p,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, bw * .025)
          ..color = _foam.withValues(alpha: .95),
      );
      c.drawCircle(
        p + Offset(-r * .35, -r * .35),
        r * .25,
        Paint()..color = _foam,
      );
    }
  }

  static void _crown(
    Canvas c,
    double h,
    Offset at,
    double width,
    double height,
    double fade,
  ) {
    if (height <= 0 || fade <= 0) return;
    const lobes = 7;
    final crown = Path()..moveTo(at.dx - width, at.dy);
    for (var i = 0; i < lobes; i++) {
      final k = (i + .5) / lobes;
      final x = at.dx - width * .85 + width * 1.7 * k;
      final edge = (k - .5).abs() * 2;
      final tip = height * (1 - edge * .5) * (i.isEven ? 1 : .78);
      final lean = (k - .5) * width * .4;
      final left = x - width * .85 / lobes, right = x + width * .85 / lobes;
      crown
        ..quadraticBezierTo(
          left,
          at.dy - tip * .5,
          x + lean - width * .05,
          at.dy - tip,
        )
        ..quadraticBezierTo(
          x + lean,
          at.dy - tip * 1.14,
          x + lean + width * .05,
          at.dy - tip,
        )
        ..quadraticBezierTo(
          right,
          at.dy - tip * .5,
          right,
          at.dy - height * .16,
        );
    }
    crown
      ..lineTo(at.dx + width, at.dy)
      ..close();
    c.drawPath(
      crown,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .006
        ..strokeJoin = StrokeJoin.round
        ..color = _deepLine.withValues(alpha: .45 * fade),
    );
    c.drawPath(crown, Paint()..color = _crest.withValues(alpha: fade));
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(.62, .68);
    c.translate(-at.dx, -at.dy);
    c.drawPath(crown, Paint()..color = _foam.withValues(alpha: fade));
    c.restore();
  }

  // ----------------------------------------------------------- shapes --

  static final _burst = _starPath(10, 1, .5);
  static final _twinkle = _starPath(5, 1, .48, curved: true);

  static Path _starPath(
    int points,
    double outer,
    double inner, {
    bool curved = false,
  }) {
    final path = Path();
    for (var i = 0; i < points; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / points;
      final tip = Offset(math.cos(a), math.sin(a)) * outer;
      final b = a + math.pi / points;
      final valley = Offset(math.cos(b), math.sin(b)) * inner;
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      if (!curved) {
        if (i > 0) path.lineTo(tip.dx, tip.dy);
        path.lineTo(valley.dx, valley.dy);
      } else {
        final next = a + 2 * math.pi / points;
        final nextTip = Offset(math.cos(next), math.sin(next)) * outer;
        path.quadraticBezierTo(
          valley.dx * .78,
          valley.dy * .78,
          nextTip.dx,
          nextTip.dy,
        );
      }
    }
    return path..close();
  }

  /// A soft contour feather, tip up, with a notch in one vane.
  /// A slim contour feather, tip up: a broad right vane, a narrow left one
  /// with a split, and a soft curl, two units long.
  static final _featherShape = Path()
    ..moveTo(.04, -1)
    ..cubicTo(.34, -.78, .4, -.14, .24, .3)
    ..lineTo(.33, .36)
    ..cubicTo(.24, .56, .12, .68, .03, .72)
    ..lineTo(-.03, .72)
    ..cubicTo(-.19, .52, -.24, .12, -.19, -.26)
    ..lineTo(-.27, -.33)
    ..cubicTo(-.2, -.7, -.1, -.92, .04, -1)
    ..close();
  static final _featherShine = Path()
    ..moveTo(.08, -.86)
    ..cubicTo(.26, -.64, .3, -.12, .19, .24)
    ..lineTo(.07, .3)
    ..cubicTo(.13, -.1, .14, -.5, .08, -.86)
    ..close();
  static final _quill = Path()
    ..moveTo(-.02, 1.04)
    ..quadraticBezierTo(.04, .1, .03, -.8);

  static double _hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
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

  static double _inQuad(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x;
  }

  static double _outBack(double t) {
    if (t <= 0) return 0;
    final x = t.clamp(0.0, 1.0) - 1;
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }
}

/// Feather colours from each bird's plumage, plus its signature bit:
/// Peaches sheds little hearts and Orbit a sparkle of stardust.
class _Debris {
  const _Debris(this.body, this.wing, this.light, [this.accent]);
  final Color body, wing, light;
  final void Function(Canvas, double alpha)? accent;

  static _Debris of(int bird) => switch (bird) {
    1 => const _Debris(
      Color(0xffff8198),
      Color(0xffff5f7e),
      Color(0xffffc9cf),
      _heart,
    ),
    2 => const _Debris(Color(0xff8fdda3), Color(0xff45b88a), Color(0xffe6f8e6)),
    3 => const _Debris(
      Color(0xff6e73d6),
      Color(0xff4e50ae),
      Color(0xffc9c1ff),
      _sparkle,
    ),
    _ => const _Debris(Color(0xffffd45b), Color(0xffe8a73c), Color(0xfffff3b0)),
  };

  static void _heart(Canvas c, double alpha) {
    final heart = Path()
      ..moveTo(0, .8)
      ..cubicTo(-1.1, 0, -.9, -.95, 0, -.45)
      ..cubicTo(.9, -.95, 1.1, 0, 0, .8)
      ..close();
    c.drawPath(
      heart,
      Paint()..color = const Color(0xffff5f7e).withValues(alpha: alpha),
    );
    c.drawPath(
      heart,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .12
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawCircle(
      const Offset(-.36, -.3),
      .16,
      Paint()..color = SkyColors.white.withValues(alpha: alpha * .9),
    );
  }

  static void _sparkle(Canvas c, double alpha) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 - math.pi / 2;
      final tip = Offset(math.cos(a), math.sin(a));
      final next = Offset(math.cos(a + math.pi / 2), math.sin(a + math.pi / 2));
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      path.quadraticBezierTo(0, 0, next.dx, next.dy);
    }
    path.close();
    c.drawPath(
      path,
      Paint()..color = const Color(0xffffe89a).withValues(alpha: alpha),
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xff4e50ae).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .1
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
