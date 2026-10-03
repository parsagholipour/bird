import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/bird_motion.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'bird_puppet.dart';
import 'finish_gate_art.dart';

/// Where the level result's courier sits, in screen pixels, and how it is
/// posed there: the celebrating bird lands exactly in this pose, so the
/// stage's courier takes over without a pop.
class CourierSeat {
  const CourierSeat({
    required this.center,
    required this.width,
    required this.angle,
    required this.wing,
  });
  final Offset center;
  final double width, angle, wing;
}

/// The bird's pose at one moment of the celebration, in screen heights.
typedef FinishBirdPose = ({
  Offset center,
  double scale,
  double angle,
  double wing,
  double stretch,
  double alpha,
});

/// The celebration when the bird crosses a campaign level's finish line,
/// drawn over the frozen flight. Every frame is a pure function of the
/// seconds since the crossing and the ended simulation, so tests can seek it
/// and it never touches the rules, the score or the journal.
///
/// Beats (full motion):
/// * 0–0.075 s: hit-stop. The world holds, the bird presses into the tape,
///   which stretches around its chest, and a warm flash rings the contact.
/// * 0.075 s: the tape snaps. Its halves whip back to the beam and the
///   ground, the confetti cannons on the post tops fire, the camera kicks
///   and punches in, the crest star spins up and the sign swings. The bird
///   beams.
/// * 0.075–0.9 s: the bird dashes on and flies a loop-de-loop (under itself
///   when it crossed too high for one over), trailing sparkles, while the
///   marquee lights flash together and the world warms and brightens.
/// * 0.9–1.7 s: it swoops towards the camera, growing, and lands in the
///   result's courier seat as the camera settles back.
/// * [seconds]: the result stage takes over; its cloud puffs in under the
///   bird. The confetti keeps falling behind the stage until [settled].
///
/// Reduced Motion lights the gate, shows a still burst and the pleased bird,
/// and fades gently: no flash, shake, zoom, spin or flying confetti. The bird
/// cross-fades with the stage's courier.
abstract final class FinishCelebrationArt {
  /// When the result stage takes over from the full celebration.
  static const seconds = 1.7;

  /// When the stage takes over from the calm Reduced Motion celebration.
  static const calmSeconds = .8;

  /// Taps are ignored before this, so a player still tapping to flap cannot
  /// skip the crossing by accident.
  static const skipAfter = .5;

  /// The frozen contact frame before the tape snaps.
  static const hitStop = .075;

  /// When the bird cheers, the fanfare plays and the bird swoops, for the
  /// controller's cues.
  static const cheerAt = .12, fanfareAt = .4, swoopAt = 1.15;

  /// When the last confetti has gone and the frame holds still under the
  /// stage.
  static const settled = 4.2;

  /// How long the calm bird takes to fade as the calm stage fades in.
  static const calmFade = .5;

  static double duration({required bool reducedMotion}) =>
      reducedMotion ? calmSeconds : seconds;

  /// When the celebration's last frame is still, so the loop may stop.
  static double stillAt({required bool reducedMotion}) =>
      reducedMotion ? calmSeconds + calmFade : settled;

  /// The cues the controller plays as the timeline passes them; the crossing
  /// itself plays the snap.
  static const cues = [
    (cheerAt, 'finish_cheer'),
    (fanfareAt, 'complete'),
    (swoopAt, 'finish_swoop'),
  ];

  /// How far the world has warmed, from 0 at the crossing to 1.
  static double warmth(double t, {required bool reducedMotion}) =>
      reducedMotion ? _smooth(t / calmSeconds) : _smooth((t - .15) / 1.1);

  /// Paint for a layer over the whole world: the opposite of the knockout's
  /// dusk, it brightens and warms into a golden afternoon, gently enough
  /// that the cream stage still reads over it.
  static Paint? worldLayer(double t, {required bool reducedMotion}) {
    final k = warmth(t, reducedMotion: reducedMotion);
    if (k <= 0) return null;
    final s = 1 + .1 * k, b = 1 + .03 * k;
    const lr = .2126, lg = .7152, lb = .0722;
    final r = (1 - s) * lr, g = (1 - s) * lg, bl = (1 - s) * lb;
    return Paint()
      ..colorFilter = ColorFilter.matrix([
        b * (r + s), b * g, b * bl, 0, 7 * k, //
        b * r, b * (g + s), b * bl, 0, 2 * k, //
        b * r, b * g, b * (bl + s), 0, -9 * k, //
        0, 0, 0, 1, 0,
      ]);
  }

  /// The camera's punch in on the contact, as scale about [focus].
  static double zoom(double t, {required bool reducedMotion}) {
    if (reducedMotion || t <= 0) return 1;
    final punch = _outCubic((t - hitStop) / .12) * (1 - _smooth((t - .5) / .8));
    return 1 + .055 * punch;
  }

  /// The snap's camera kick in screen heights.
  static Offset cameraOffset(double t, {required bool reducedMotion}) {
    final u = t - hitStop;
    if (reducedMotion || u < 0 || u >= .32) return Offset.zero;
    final a = .009 * math.exp(-u * 11) * (1 - u / .32);
    return Offset(math.sin(u * 83 + 1.1) * a, math.cos(u * 67) * a);
  }

  /// Where the camera punches in: the bird at the line.
  static Offset focus(FlightSimulation sim, double h) =>
      Offset(sim.birdScreenX * h, sim.birdY * h);

  /// The height where the bird meets the tape, in screen heights. A bird
  /// crossing above the tape breaks it at its top.
  static double contact(FlightSimulation sim) =>
      sim.birdY.clamp(FinishGateArt.tapeTop + .05, .95);

  /// The flight HUD fades out as the celebration takes the screen.
  static double hudOpacity(double t, {required bool reducedMotion}) =>
      1 - _smooth((t - (reducedMotion ? .1 : .25)) / .4);

  // ------------------------------------------------------------ the bird --

  static const _loopRadius = .105, _dash = .3, _loopTime = .56, _loopEase = .25;
  static const _loopFrom = hitStop + _dash, _loopTo = _loopFrom + _loopTime;

  /// Whether the bird loops under itself: it crossed too high for a loop
  /// over the top to stay on screen.
  static bool loopsUnder(FlightSimulation sim) =>
      sim.birdY < .1 + 2 * _loopRadius;

  static double _flightTilt(FlightSimulation sim) =>
      sim.rules.mode.controlsHeight || !sim.started
      ? 0
      : BirdFlightMotion.tilt(sim.velocity);

  // The loop's entry speed, in screen heights a second.
  static const _loopSpeed =
      2 * math.pi * _loopRadius * (1 + _loopEase) / _loopTime;

  /// How far past the line the bird loops, clear of the gate.
  static const _dashDistance = .4;

  /// Where the loop starts and ends, in screen heights.
  static Offset _loopGate(FlightSimulation sim) =>
      Offset(sim.birdScreenX + _dashDistance, sim.birdY);

  /// The celebrating bird at [t]: it dashes on through the tape, loops,
  /// then swoops into [seat] (in screen heights), or with no seat (a
  /// replay) settles into a hover beyond the gate.
  static FinishBirdPose bird(
    FlightSimulation sim,
    double t, {
    required bool reducedMotion,
    CourierSeat? seat,
    double h = 1,
  }) {
    final x0 = sim.birdScreenX, y0 = sim.birdY;
    final tilt = _flightTilt(sim);
    if (reducedMotion) {
      final fade = seat == null
          ? 1.0
          : 1 - _smooth((t - calmSeconds) / calmFade);
      return (
        center: Offset(x0, y0),
        scale: 1.0,
        angle: tilt * (1 - _smooth(t / .4)),
        wing: .1,
        stretch: 0.0,
        alpha: fade,
      );
    }
    final u = t - hitStop;
    // Pressed into the tape, then springing free.
    final stretch = t < hitStop
        ? -.16 * _smooth(t / hitStop)
        : .2 * math.exp(-8 * u) * math.cos(17 * u);
    if (u <= 0) {
      return (
        center: Offset(x0, y0),
        scale: 1.0,
        angle: tilt,
        wing: -.4,
        stretch: stretch,
        alpha: 1.0,
      );
    }
    if (t < _loopFrom) {
      // A burst of speed on from the flight's pace into the loop's.
      final v0 = sim.speed.clamp(.2, .6) * _dash;
      const v1 = _loopSpeed * _dash, d = _dashDistance;
      final s = u / _dash, s2 = s * s, s3 = s2 * s;
      final x =
          (s3 - 2 * s2 + s) * v0 + (-2 * s3 + 3 * s2) * d + (s3 - s2) * v1;
      final k = _smooth(u / .12);
      return (
        center: Offset(x0 + x, y0 - .012 * math.sin(s * math.pi)),
        scale: 1.0,
        angle: tilt * (1 - k),
        wing: .1 - .62 * math.sin(u * 2 * math.pi * 6),
        stretch: stretch,
        alpha: 1.0,
      );
    }
    final gate = _loopGate(sim);
    if (t < _loopTo) {
      final tau = (t - _loopFrom) / _loopTime;
      final turn = 2 * math.pi * tau + _loopEase * math.sin(2 * math.pi * tau);
      final under = loopsUnder(sim);
      final theta = under ? -math.pi / 2 + turn : math.pi / 2 - turn;
      final center = gate + Offset(0, under ? _loopRadius : -_loopRadius);
      return (
        center: center + Offset(math.cos(theta), math.sin(theta)) * _loopRadius,
        scale: 1.0,
        angle: under ? theta + math.pi / 2 : theta - math.pi / 2,
        // Wings swept back through the loop, a beat at the top.
        wing: -.35 + .25 * math.sin(tau * math.pi),
        stretch: stretch,
        alpha: 1.0,
      );
    }
    final sit = _seatIn(seat, h);
    final tau = ((t - _loopTo) / (seconds - _loopTo)).clamp(0.0, 1.0);
    final path = _swoop(sim, gate, sit);
    final s = 1 - (1 - tau) * (1 - tau);
    final p = _bezier(path, s);
    final end = sit?.$2 ?? 1.0;
    final grow = _inOutCubic(tau);
    final scale = 1 + (end - 1) * grow;
    // Nose up as it climbs, down as it drops in, level as it lands.
    final dp = _bezierSlope(path, s) * (2 * (1 - tau));
    final lean = (dp.dy * .3).clamp(-.38, .32);
    final settle = _smooth((tau - .55) / .45);
    final angle = lean * (1 - settle) + (seat?.angle ?? 0) * settle;
    final flap = math.sin((t - _loopTo) * 2 * math.pi * 5.2);
    final wingTo = seat?.wing ?? .1;
    final wing = (.1 + .6 * flap) * (1 - settle) + wingTo * settle;
    final hover = seat == null
        ? .012 * math.sin((t - seconds) * 2.6) * _smooth((t - seconds) / .4)
        : 0.0;
    return (
      center: p + Offset(0, hover),
      scale: scale,
      angle: angle,
      wing: t > seconds && seat == null
          ? .1 + .3 * math.sin((t - seconds) * 2 * math.pi * 2.2)
          : wing,
      stretch: 0.0,
      alpha: seat != null && t >= seconds ? 0.0 : 1.0,
    );
  }

  /// The seat's centre in screen heights and the bird's scale there.
  static (Offset, double)? _seatIn(CourierSeat? seat, double h) => seat == null
      ? null
      : (seat.center / h, seat.width / (h * BirdFlightMotion.size));

  /// The swoop: on and up out of the loop, then over and down towards the
  /// camera into the seat, or into a hover beyond the gate.
  static List<Offset> _swoop(
    FlightSimulation sim,
    Offset from,
    (Offset, double)? seat,
  ) {
    final to =
        seat?.$1 ?? Offset(from.dx + .42, sim.birdY.clamp(.3, .6).toDouble());
    // Up and over the gate's crest, then down into the seat.
    final apex = math.max(.04, math.min(from.dy, to.dy) - .36);
    return [
      from,
      from + const Offset(.14, -.13),
      seat == null
          ? Offset(to.dx - .1, apex)
          : Offset(sim.birdScreenX + .06, apex),
      to,
    ];
  }

  static Offset _bezier(List<Offset> p, double s) {
    final r = 1 - s;
    return p[0] * (r * r * r) +
        p[1] * (3 * r * r * s) +
        p[2] * (3 * r * s * s) +
        p[3] * (s * s * s);
  }

  static Offset _bezierSlope(List<Offset> p, double s) {
    final r = 1 - s;
    return (p[1] - p[0]) * (3 * r * r) +
        (p[2] - p[1]) * (6 * r * s) +
        (p[3] - p[2]) * (3 * s * s);
  }

  // ------------------------------------------------------------- paint --

  /// Draws the celebration over the warmed world: the contact's flash and
  /// ring, the confetti and streamers, the sparkle trail and the bird.
  /// [seat] is where the result's courier sits, in pixels; [hideBird]
  /// leaves the bird out once the stage has taken over early (a skip).
  static void paint(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required int bird,
    required double seconds,
    required bool reducedMotion,
    CourierSeat? seat,
    bool hideBird = false,
    Offset shake = Offset.zero,
    int beak = 0,
  }) {
    final t = seconds;
    if (!t.isFinite || t < 0) return;
    final h = size.height;
    if (h <= 0) return;
    final line = sim.finishLine;
    if (line == null) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (reducedMotion) {
      if (!hideBird) _shield(canvas, h, sim, t, true);
      _paintBird(canvas, h, sim, bird, t, true, seat, hideBird, beak);
      canvas.restore();
      return;
    }
    canvas.translate(shake.dx, shake.dy);
    final zoom = FinishCelebrationArt.zoom(t, reducedMotion: false);
    if (zoom != 1) {
      final f = focus(sim, h);
      canvas.translate(f.dx, f.dy);
      canvas.scale(zoom);
      canvas.translate(-f.dx, -f.dy);
    }
    final view = Offset.zero & size;
    final gateX = line.x * h;
    _flash(canvas, size, t);
    _muzzles(canvas, h, gateX, t);
    _streamers(canvas, h, view, gateX, t);
    _confetti(canvas, h, view, gateX, t);
    _pop(canvas, h, sim, t);
    if (!hideBird) {
      _trail(canvas, h, sim, t, seat);
      _shield(canvas, h, sim, t, false);
    }
    _paintBird(canvas, h, sim, bird, t, false, seat, hideBird, beak);
    _ring(canvas, h, sim, t);
    canvas.restore();
  }

  static void _paintBird(
    Canvas c,
    double h,
    FlightSimulation sim,
    int bird,
    double t,
    bool calm,
    CourierSeat? seat,
    bool hide,
    int beak,
  ) {
    if (hide) return;
    final pose = FinishCelebrationArt.bird(
      sim,
      t,
      reducedMotion: calm,
      seat: seat,
      h: h,
    );
    if (pose.alpha <= 0) return;
    final bw = h * BirdFlightMotion.size * pose.scale;
    final center = pose.center * h;
    if (!calm && pose.alpha > 0) {
      // A soft halo lifts the bird out of the confetti round it.
      final halo = Rect.fromCircle(center: center, radius: bw * .9);
      c.drawCircle(
        center,
        bw * .9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              SkyColors.cream.withValues(alpha: .6 * pose.alpha),
              SkyColors.cream.withValues(alpha: 0),
            ],
          ).createShader(halo),
      );
    }
    if (pose.alpha < 1) {
      c.saveLayer(
        Rect.fromCircle(center: center, radius: bw * 1.2),
        Paint()..color = Color.fromRGBO(0, 0, 0, pose.alpha),
      );
    } else {
      c.save();
    }
    c.translate(center.dx, center.dy);
    c.rotate(pose.angle);
    c.scale(1 + pose.stretch, 1 - pose.stretch * .8);
    BirdPuppet.paint(
      c,
      Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
      bird: bird,
      wing: pose.wing,
      expression: BirdExpression.pleased,
      beak: beak,
    );
    c.restore();
  }

  /// A Star Trail's shield bubble, still round the bird as it crosses: it
  /// pops as the tape snaps, or fades in the calm crossing.
  static void _shield(
    Canvas c,
    double h,
    FlightSimulation sim,
    double t,
    bool calm,
  ) {
    if (!sim.isTrail || !sim.shield) return;
    final u = t - hitStop;
    final k = calm
        ? 1 - _smooth(t / .4)
        : u <= 0
        ? 1.0
        : 1 - u / .16;
    if (k <= 0) return;
    final grow = calm || u <= 0 ? 1.0 : 1 + .45 * u / .16;
    final at = Offset(sim.birdScreenX * h, sim.birdY * h);
    final r = h * .078 * grow;
    c.drawCircle(
      at,
      r,
      Paint()..color = SkyColors.cream.withValues(alpha: .16 * k),
    );
    c.drawCircle(
      at,
      r,
      Paint()
        ..color = SkyColors.teal.withValues(alpha: .8 * k)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (calm || u <= 0) return;
    // Droplets of the burst bubble spray out.
    final drop = Paint()
      ..color = SkyColors.teal.withValues(alpha: k)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var i = 0; i < 7; i++) {
      final a = i * 2 * math.pi / 7 + .4;
      c.drawCircle(
        at + Offset(math.cos(a), math.sin(a)) * (r + h * .05 * u / .16),
        h * .008,
        drop,
      );
    }
  }

  /// A soft warm flash on the contact frame.
  static void _flash(Canvas c, Size size, double t) {
    const life = .14;
    if (t >= life) return;
    final k = 1 - t / life;
    c.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xfffff3c4).withValues(alpha: .26 * k * k),
    );
  }

  /// A hot starburst behind the bird as it breaks the tape.
  static void _pop(Canvas c, double h, FlightSimulation sim, double t) {
    final k = t / .24;
    if (k >= 1) return;
    final bw = h * BirdFlightMotion.size;
    final grow = k < .35
        ? .7 + .5 * _outCubic(k / .35)
        : 1.2 * (1 - _smooth((k - .35) / .65));
    if (grow <= 0) return;
    final at = Offset(sim.birdScreenX * h, sim.birdY * h);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(.2 + t * 2);
    c.scale(bw * .62 * grow);
    c.drawPath(_burst, Paint()..color = SkyColors.yellow);
    c.drawPath(
      _burst,
      Paint()
        ..color = SkyColors.coralDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = .07
        ..strokeJoin = StrokeJoin.round,
    );
    c.scale(.58);
    c.drawPath(_burst, Paint()..color = SkyColors.white);
    c.restore();
  }

  /// A bright ring that spreads from the bird, edged in ink so it reads on
  /// a bright sky too.
  static void _ring(Canvas c, double h, FlightSimulation sim, double t) {
    final k = (t - .03) / .34;
    if (k <= 0 || k >= 1) return;
    final at = Offset(sim.birdScreenX * h, sim.birdY * h);
    final bw = h * BirdFlightMotion.size;
    final r = bw * (.5 + 1.5 * _outCubic(k));
    final width = bw * .11 * (1 - k);
    c.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + h * .005
        ..color = SkyColors.ink.withValues(alpha: .35 * (1 - k)),
    );
    c.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = SkyColors.white.withValues(alpha: 1 - k),
    );
  }

  static const _confettiColors = [
    SkyColors.coral,
    SkyColors.yellow,
    SkyColors.mint,
    SkyColors.lavender,
    SkyColors.skyDeep,
    SkyColors.white,
  ];

  /// The cannons' mouths: the finial balls on the post tops.
  static Offset _muzzle(double gateX, double h, double side) => Offset(
    gateX + side * FinishGateArt.postOffset * h,
    FinishGateArt.finialY * h,
  );

  /// A pop of flame-yellow at each post top as the cannons fire.
  static void _muzzles(Canvas c, double h, double gateX, double t) {
    final k = (t - hitStop) / .2;
    if (k < 0 || k >= 1) return;
    for (final side in [-1.0, 1.0]) {
      final at = _muzzle(gateX, h, side);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(side * .5);
      c.scale(h * .05 * (k < .3 ? .6 + 1.3 * k / .3 : 1.9 * (1 - k) / .7));
      c.drawPath(_burst, Paint()..color = SkyColors.yellow);
      c.drawPath(
        _burst,
        Paint()
          ..color = SkyColors.coralDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = .1
          ..strokeJoin = StrokeJoin.round,
      );
      c.scale(.55);
      c.drawPath(_burst, Paint()..color = SkyColors.white);
      c.restore();
    }
  }

  static const _pieces = 84, _streamerCount = 8;
  static const _gravity = 1.6;

  /// Where a launched piece is after [a] seconds: drag slows the blast,
  /// gravity wins and it flutters down at a paper's pace, swaying.
  static Offset _flight(
    Offset from,
    double h,
    double angle,
    double speed,
    double drag,
    double a,
    double sway,
    double phase,
  ) {
    final fall = h * _gravity / drag;
    final e = (1 - math.exp(-drag * a)) / drag;
    final vx = math.cos(angle) * speed, vy = math.sin(angle) * speed;
    final swing = math.sin(a * 4.4 + phase) * sway * _smooth(a / .7);
    return from + Offset(vx * e + swing, (vy - fall) * e + fall * a);
  }

  /// Confetti from the two cannons: paper rectangles that flip as they
  /// tumble, dots and little stars, laid by a fixed hash.
  static void _confetti(Canvas c, double h, Rect view, double gateX, double t) {
    final u = t - hitStop;
    if (u <= 0) return;
    final fade = 1 - _smooth((t - (settled - .6)) / .55);
    if (fade <= 0) return;
    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink.withValues(alpha: fade);
    for (var i = 0; i < _pieces; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final r1 = _hash(i, 1), r2 = _hash(i, 2), r3 = _hash(i, 3);
      final a = u - _hash(i, 4) * .06;
      if (a <= 0) continue;
      // Each cannon throws out and up into a broad fan that blooms under
      // the top edge, a quarter of it back over the gate.
      final across = i % 4 == 0;
      final tilt =
          (across ? -.55 : 1.15) * (side < 0 ? 1.0 : 1.05) + (r1 - .5) * 1.5;
      final angle = -math.pi / 2 + side * tilt;
      final steep = 1 - .45 * (1 - (tilt.abs() / .9).clamp(0.0, 1.0));
      // The right cannon has the open sky to fill.
      final reach = side > 0 && !across ? 1.6 : 1.0;
      final speed = h * (1.2 + r2 * 1.3) * steep * reach;
      final drag = 4.6 + 2.4 * r3;
      final p = _flight(
        _muzzle(gateX, h, side),
        h,
        angle,
        speed,
        drag,
        a,
        h * (.018 + .02 * r1),
        r2 * 6,
      );
      if (!view.inflate(h * .03).contains(p)) continue;
      final color = _confettiColors[i % _confettiColors.length];
      fill.color = color.withValues(alpha: fade);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(r3 * 6 + a * side * (3 + 5 * r1));
      switch (i % 5) {
        case 0:
        case 1:
        case 2:
          // A paper chip, flipping edge-on and back as it tumbles.
          final flip = math.cos(a * (6 + 6 * r2) + r1 * 3);
          final piece = Rect.fromCenter(
            center: Offset.zero,
            width: h * .03,
            height: h * .016 * (.15 + .85 * flip.abs()),
          );
          c.drawRect(piece, fill);
          edge.strokeWidth = h * .0028;
          c.drawRect(piece, edge);
        case 3:
          c.drawCircle(Offset.zero, h * .0095, fill);
          edge.strokeWidth = h * .0026;
          c.drawCircle(Offset.zero, h * .0095, edge);
        default:
          c.scale(h * .024);
          fill.color = SkyColors.yellow.withValues(alpha: fade);
          c.drawPath(_star, fill);
          edge.strokeWidth = .2;
          c.drawPath(_star, edge);
      }
      c.restore();
    }
  }

  /// Curly paper streamers thrown from the cannons, each a ribbon along
  /// the last moments of its own flight.
  static void _streamers(
    Canvas c,
    double h,
    Rect view,
    double gateX,
    double t,
  ) {
    final u = t - hitStop;
    if (u <= 0) return;
    final fade = 1 - _smooth((t - (settled - .7)) / .6);
    if (fade <= 0) return;
    final under = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = h * .0135
      ..color = SkyColors.ink.withValues(alpha: fade);
    final over = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = h * .0075;
    const joints = 11;
    for (var i = 0; i < _streamerCount; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final r1 = _hash(i, 21), r2 = _hash(i, 22);
      final angle = -math.pi / 2 + side * (.95 + .5 * r1);
      final speed = h * (1.3 + .7 * r2);
      final drag = 4.0 + 1.5 * r1;
      final from = _muzzle(gateX, h, side);
      final path = Path();
      var shown = false;
      for (var j = 0; j < joints; j++) {
        // The tail follows the head's path a little behind, curling.
        final a = math.max(0.0, u - j * .035);
        final p = _flight(from, h, angle, speed, drag, a, h * .03, r2 * 6);
        final curl =
            math.sin(j * 1.25 + u * 9 + r1 * 6) * h * .012 * math.min(1, a * 4);
        final q = p + Offset(curl, curl * .4);
        if (view.contains(q)) shown = true;
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      if (!shown) continue;
      over.color = _confettiColors[(i * 2 + 1) % 5].withValues(alpha: fade);
      c.drawPath(path, under);
      c.drawPath(path, over);
    }
  }

  /// Sparkles shed along the bird's path, swelling with it as it nears
  /// the camera.
  static void _trail(
    Canvas c,
    double h,
    FlightSimulation sim,
    double t,
    CourierSeat? seat,
  ) {
    const every = .03, life = .42;
    final last = seat == null ? seconds + .4 : seconds - .06;
    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink;
    final first = math.max(0, ((t - life - hitStop) / every).ceil());
    for (var i = first; ; i++) {
      final born = hitStop + .03 + i * every;
      if (born > t || born > last) break;
      final age = (t - born) / life;
      if (age >= 1) continue;
      final pose = bird(sim, born, reducedMotion: false, seat: seat, h: h);
      final jitter =
          Offset(_hash(i, 31) - .5, _hash(i, 32) - .5) * (.05 * pose.scale);
      final at = (pose.center + jitter + Offset(0, .02 * age)) * h;
      final r =
          h *
          .02 *
          pose.scale *
          (i % 3 == 0 ? 1.25 : .85) *
          (age < .2 ? age / .2 : 1 - _smooth((age - .2) / .8));
      if (r <= .4) continue;
      fill.color = i % 3 == 1 ? SkyColors.yellow : SkyColors.white;
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(i * .7);
      c.scale(r);
      c.drawPath(_sparkle, fill);
      edge.strokeWidth = math.max(.08, .9 / r);
      edge.color = SkyColors.ink.withValues(alpha: .8);
      c.drawPath(_sparkle, edge);
      c.restore();
    }
  }

  // ----------------------------------------------------------- shapes --

  static final _burst = _starPath(10, 1, .5);
  static final _star = _starPath(5, 1, .46);
  static final _sparkle = () {
    final path = Path()..moveTo(0, -1);
    path
      ..quadraticBezierTo(0, 0, 1, 0)
      ..quadraticBezierTo(0, 0, 0, 1)
      ..quadraticBezierTo(0, 0, -1, 0)
      ..quadraticBezierTo(0, 0, 0, -1)
      ..close();
    return path;
  }();

  static Path _starPath(int points, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < points; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / points;
      final tip = Offset(math.cos(a), math.sin(a)) * outer;
      final b = a + math.pi / points;
      final valley = Offset(math.cos(b), math.sin(b)) * inner;
      i == 0 ? path.moveTo(tip.dx, tip.dy) : path.lineTo(tip.dx, tip.dy);
      path.lineTo(valley.dx, valley.dy);
    }
    return path..close();
  }

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

  static double _inOutCubic(double t) {
    final x = t.clamp(0.0, 1.0);
    return x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
  }
}
