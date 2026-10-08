import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../l10n/l10n.dart';
import '../l10n/text/coop_text.dart';
import '../ui/theme.dart';

/// The rope between a co-op flight's two birds and the player tags over
/// them. Presentation only: it reads the simulation and never changes it.
///
/// The rope is a chunky twisted cartoon rope with an ink outline, pale straw
/// while it hangs slack in a soft, gently swaying curve. The closer the birds
/// pull to [Tether.length], the straighter it runs and the hotter it glows,
/// from straw to orange, so a player can see at a glance that it is about to
/// pull. A hard snap flashes it bright yellow and twangs it: a ripple runs
/// along it and quiver lines spring out beside it. Reduced Motion keeps the
/// sag and the heat, without the sway, the ripple or the flash.
abstract final class TetherArt {
  /// Player 1's and player 2's colours, shared with their controls.
  static const players = [SkyColors.coral, SkyColors.teal];

  /// Where the rope is tied, in viewport heights from the bird's centre:
  /// around its middle, a little under the wing.
  static const tie = Offset(-.004, .018);

  /// How long a snap glows.
  static const _snapSeconds = .32;

  // Slack straw, lighter than the jungle's wooden bridges, and the hot
  // orange of a rope at full stretch: body, lower shade and twist lines.
  static const _straw = Color(0xfff9dea0),
      _strawShade = Color(0xffe2b16a),
      _strawTwist = Color(0xffac733c);
  static const _hot = Color(0xffff8c4a),
      _hotShade = Color(0xffe85d36),
      _hotTwist = Color(0xffb53a24);
  static const _flash = Color(0xffffe066);

  /// Light falls from the upper left, so the rope's gloss runs along its
  /// upper side.
  static const _light = Offset(-.29, -.96);

  /// The rope of [sim]'s pair, from bird to bird.
  static void rope(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final partner = sim.partner;
    if (partner == null || !sim.roped) return;
    final lead = sim.lead;
    between(
      canvas,
      h,
      Offset(lead.x, lead.y) + tie,
      Offset(partner.x, partner.y) + tie,
      seconds: sim.elapsed,
      snap: reducedMotion ? 0 : _snapGlow(sim),
      reducedMotion: reducedMotion,
    );
  }

  /// How brightly [sim]'s latest hard snap still shows, from 1 as it
  /// happens down to 0. The rope pulls a little on every step it is taut,
  /// so only a hard snap ([FlightSimulation.ropeSnappedAt]) flashes.
  static double _snapGlow(FlightSimulation sim) {
    final age = sim.elapsed - sim.ropeSnappedAt;
    return age >= 0 && age < _snapSeconds ? 1 - age / _snapSeconds : 0;
  }

  /// A rope of [Tether.length] tied between [a] (player 1's end) and [b]
  /// (player 2's), in viewport heights. [snap] (0 to 1) is how brightly a
  /// fresh snap still shows.
  static void between(
    Canvas canvas,
    double h,
    Offset a,
    Offset b, {
    required double seconds,
    double snap = 0,
    double opacity = 1,
    required bool reducedMotion,
  }) {
    if (opacity <= 0 || h <= 0) return;
    if (reducedMotion) snap = 0;
    final chord = b - a;
    final span = chord.distance;
    // A parabola of the rope's length over this span sags this far.
    final slack = math.max(0.0, Tether.length - span);
    var sag = span > 1e-6 ? math.sqrt(3 * span * slack / 8) : slack / 2;
    // Tension shows as the curve straightening out and the rope heating up.
    final taut = (1 - slack / (Tether.length * .35)).clamp(0.0, 1.0);
    final heat = _smooth((taut - .3) / .65);
    if (!reducedMotion) {
      sag *= 1 + .12 * math.sin(seconds * 5.3) * (1 - taut);
    }
    // The rope hangs down; along a steep chord it bows out behind.
    var normal = span > 1e-6
        ? Offset(-chord.dy / span, chord.dx / span)
        : const Offset(0, 1);
    if (normal.dy < 0) normal = -normal;
    final bow = Offset(normal.dx - .35 * (1 - normal.dy), normal.dy);
    final bowLength = bow.distance;
    final out = bowLength > 1e-6 ? bow / bowLength : const Offset(0, 1);
    final mid = (a + b) / 2 + out * sag;
    final control = mid * 2 - (a + b) / 2;
    final across = span > 1e-6
        ? Offset(-chord.dy / span, chord.dx / span)
        : const Offset(0, 1);
    // A snap twangs a ripple that runs along the rope, pinned at both ends.
    final ripple = snap * .011;

    Offset at(double t) {
      // The quadratic through a, mid (at t = .5) and b.
      final u = 1 - t;
      final base = a * (u * u) + control * (2 * u * t) + b * (t * t);
      if (ripple == 0) return base;
      final wave =
          math.sin(t * math.pi) *
          math.sin(t * math.pi * 3 - seconds * 38) *
          ripple;
      return base + across * wave;
    }

    const samples = 28;
    final points = [for (var i = 0; i <= samples; i++) at(i / samples) * h];
    // How far along the rope each point is, and which way it runs there.
    final lengths = List<double>.filled(samples + 1, 0);
    final tangents = List<Offset>.filled(samples + 1, const Offset(1, 0));
    for (var i = 0; i <= samples; i++) {
      if (i > 0) {
        lengths[i] = lengths[i - 1] + (points[i] - points[i - 1]).distance;
      }
      final along =
          points[math.min(i + 1, samples)] - points[math.max(i - 1, 0)];
      final length = along.distance;
      tangents[i] = length > 1e-6
          ? along / length
          : i > 0
          ? tangents[i - 1]
          : const Offset(1, 0);
    }
    // The rope's centre line, or a line [lift] pixels toward its lit side.
    Path line(double lift) {
      final path = Path();
      for (var i = 0; i <= samples; i++) {
        var p = points[i];
        if (lift != 0) {
          final t = tangents[i];
          final n = Offset(-t.dy, t.dx);
          p += (n.dx * _light.dx + n.dy * _light.dy < 0 ? -n : n) * lift;
        }
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    final fading = opacity < 1;
    if (fading) {
      // Fade the rope as one piece, so its layers don't show through.
      final reach = h * (sag + .06);
      canvas.saveLayer(
        Rect.fromPoints(a * h, b * h).inflate(reach),
        Paint()..color = SkyColors.white.withValues(alpha: opacity),
      );
    }

    final body = h * (.0132 + .0025 * snap);
    final rim = h * .0042;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final centre = line(0);
    if (snap > 0) {
      canvas.drawPath(
        centre,
        stroke
          ..color = SkyColors.cream.withValues(alpha: .7 * snap)
          ..strokeWidth = body * 3.2,
      );
    }
    Color tone(Color slack, Color hot) =>
        Color.lerp(Color.lerp(slack, hot, heat), _flash, snap * .85)!;
    canvas
      ..drawPath(
        centre,
        stroke
          ..color = SkyColors.ink
          ..strokeWidth = body + rim * 2,
      )
      ..drawPath(
        centre,
        stroke
          ..color = tone(_straw, _hot)
          ..strokeWidth = body,
      )
      // Glossy along the top; the strands below cut the gloss into beads.
      ..drawPath(
        line(body * .2),
        stroke
          ..color = SkyColors.cream.withValues(alpha: .9)
          ..strokeWidth = body * .22,
      );

    // The lay of the rope: evenly spaced slanted strands, each a shaded band
    // edged with a dark twist line. Their slant follows the rope's own
    // direction, so the twist looks the same from either end.
    final total = lengths.last;
    final period = body * 1.15;
    final strands = (total / period).floor();
    if (strands > 0) {
      final bands = Path(), twist = Path();
      final gap = total / strands;
      final half = body * .5, lean = body * .42, band = gap * .38;
      var j = 0;
      for (var k = 0; k < strands; k++) {
        final s = (k + .5) * gap;
        while (j < samples - 1 && lengths[j + 1] < s) {
          j++;
        }
        final piece = lengths[j + 1] - lengths[j];
        final f = piece > 1e-6 ? (s - lengths[j]) / piece : 0.0;
        final p = Offset.lerp(points[j], points[j + 1], f)!;
        final t = Offset.lerp(tangents[j], tangents[j + 1], f)!;
        final n = Offset(-t.dy, t.dx);
        // A parallelogram from one edge of the rope to the other.
        final low = p + n * half - t * lean, high = p - n * half + t * lean;
        final b0 = low - t * band, b1 = high - t * band;
        bands
          ..moveTo(b0.dx, b0.dy)
          ..lineTo(low.dx, low.dy)
          ..lineTo(high.dx, high.dy)
          ..lineTo(b1.dx, b1.dy)
          ..close();
        final from = p + n * (half * .8) - t * (lean * .8);
        final to = p - n * (half * .8) + t * (lean * .8);
        twist
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);
      }
      canvas
        ..drawPath(bands, Paint()..color = tone(_strawShade, _hotShade))
        ..drawPath(
          twist,
          stroke
            ..color = tone(_strawTwist, _hotTwist)
            ..strokeWidth = math.max(1.0, body * .18),
        );
    }

    // A knot where each end is tied, in that player's colour. In flight it
    // tucks under the bird; on the menus it marks whose end is whose.
    final knot = body * .95;
    final fill = Paint();
    for (final (player, end) in [(0, points.first), (1, points.last)]) {
      canvas
        ..drawCircle(end, knot + rim, fill..color = SkyColors.ink)
        ..drawCircle(end, knot, fill..color = players[player])
        ..drawCircle(
          end - Offset(knot * .35, knot * .35),
          knot * .3,
          fill..color = SkyColors.white.withValues(alpha: .7),
        );
    }

    // A freshly snapped rope twangs: quiver lines spring out along both
    // sides of its middle and fade.
    if (snap > 0) {
      final quiver = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * .0036
        ..color = SkyColors.ink.withValues(alpha: math.min(1, snap * 1.4));
      final spread = body * (1.5 + 1.6 * (1 - snap));
      for (final side in [-1.0, 1.0]) {
        final path = Path();
        for (var i = 9; i <= samples - 9; i++) {
          final t = tangents[i];
          final p = points[i] + Offset(-t.dy, t.dx) * (spread * side);
          i == 9 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, quiver);
      }
    }

    if (fading) canvas.restore();
  }

  /// A small tag over the bird [sim] describes, so each player can find
  /// their own bird: an ink-rimmed sticker in the player's colour with a
  /// pointer down to the bird.
  static void badge(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required int player,
  }) {
    final color = players[player % players.length];
    final center = Offset(sim.birdScreenX * h, (sim.birdY - .1) * h);
    final w = h * .033, r = h * .0195;
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 2, height: r * 2),
      Radius.circular(r),
    );
    // The pointer grows out of the pill's bottom edge to a rounded tip. It
    // winds the same way as the pill, so where they overlap stays filled.
    final root = center.dy + r - h * .004, tip = center.dy + r + h * .014;
    final pointer = Path()
      ..moveTo(center.dx + h * .0115, root)
      ..lineTo(center.dx + h * .0024, tip - h * .0014)
      ..quadraticBezierTo(
        center.dx,
        tip + h * .0008,
        center.dx - h * .0024,
        tip - h * .0014,
      )
      ..lineTo(center.dx - h * .0115, root)
      ..close();
    final shape = Path()
      ..addRRect(pill)
      ..addPath(pointer, Offset.zero);
    // A soft drop under it, an ink rim, a deeper lower lip, then the face.
    final face = RRect.fromRectAndRadius(
      Rect.fromLTRB(pill.left, pill.top, pill.right, pill.bottom - h * .004),
      Radius.circular(r),
    );
    canvas
      ..drawPath(
        shape.shift(Offset(0, h * .0045)),
        Paint()..color = SkyColors.ink.withValues(alpha: .2),
      )
      ..drawPath(
        shape,
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0084
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(shape, Paint()..color = Color.lerp(color, SkyColors.ink, .16)!)
      ..drawRRect(face, Paint()..color = color);
    final text = _label(player, h);
    text.paint(
      canvas,
      center - Offset(text.width / 2, text.height / 2 + h * .0015),
    );
  }

  /// The player tags' lettering, laid out once per size.
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
            fontSize: h * .028,
            height: 1,
            color: SkyColors.white,
          ),
        ),
        textDirection: L10n.textDirection,
      )..layout(),
    );
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }
}
