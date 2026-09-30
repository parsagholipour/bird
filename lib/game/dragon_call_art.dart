import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'dragon_kit.dart';

/// The swarm call: each time the flame gutters out (7.6 s into the breath
/// cycle, and again 1.4 s later in fury) the dragon throws its head back and
/// ROARS the swarm bats in from behind it. The pose does the roar
/// (`DragonPose.wind`, `roar`, `call`); this is the cue laid over it.
///
/// HOOK owned by the fireball / call builder (B6). `BossEncounterArt` calls
/// [paint] whenever `pose.call > 0`, above the dragon and below the bats and
/// the hint text (the bats are painted after the boss, so that order is
/// free). The cue is COOL (violet, never fire) and lives entirely AHEAD of
/// and above the jaws: the face sits behind the mouth, and the fireball's
/// orange orb, streaks and muzzle share the same sky in warm colours, so the
/// two attacks read side by side (rings and bats round the orb, not over it)
/// and neither hides the other. Nothing is a veil: every piece is a line, a
/// glyph or a soft band, and none is large enough to hide a bat or the bird.
///
/// The beats, [tau] seconds from the call landing (7.6 s): from -0.3 the
/// intake pulls six violet wisps into the jaws; at 0 the roar throws two
/// (three in fury) shock rings up over the sky in front of the snout, hangs a
/// herald sigil (a bat in a ring) there, releases six bat-glyph motes that
/// swirl up and out, each trailing a wisp, and a dark billow puffs off the
/// snout; all of it has gone by 1.0. The second call of a fury cycle is the
/// same at 0.8 strength.
abstract final class DragonCallArt {
  /// The cue's length after the call lands, in seconds.
  static const length = 1.0;

  /// How long before the call the intake starts pulling.
  static const intake = .3;

  /// [mouth] and [center] (the heart) are in pixels, [h] is the screen
  /// height, [call] is `DragonPose.call` (0 to 1: intake, roar, fade) and
  /// [seconds] the flight clock for the small wobbles (0 under Reduced Motion).
  ///
  /// [tau] is the time since the call landed (negative during the intake);
  /// pass [boss] (or [tau] and [strength]) to get the choreography: the
  /// beats are then a pure function of the boss clock, so pause, seek and
  /// replay reproduce them. Without either, the cue works out how far along
  /// it is from [call] alone, assuming the fade (it cannot tell the intake
  /// from the fade by value), which shows the glow and the tail of the
  /// motes only.
  ///
  /// [toward] (where the flock comes in) is accepted for the call sites that
  /// pass it but unused: the way to the flock's side runs over the dragon's
  /// face, and the cue must never cross it.
  ///
  /// Reduced Motion is one still frame: a band-and-line ring ahead of the
  /// jaws with the herald hung in it.
  static void paint(
    Canvas c, {
    required Offset mouth,
    required Offset center,
    required double h,
    required double call,
    required double seconds,
    required bool reducedMotion,
    required bool fury,
    double? tau,
    double? strength,
    SkyBoss? boss,
    Offset? toward,
  }) {
    if (!(call > 0) ||
        !h.isFinite ||
        h <= 0 ||
        !mouth.dx.isFinite ||
        !mouth.dy.isFinite) {
      return;
    }
    final clock = boss == null ? null : timing(boss);
    final t = tau ?? clock?.tau ?? _tauOfCall(call);
    final k = (strength ?? clock?.strength ?? 1.0).clamp(0.0, 1.0);
    if (!t.isFinite) return;
    final level = call.clamp(0.0, 1.0);
    // Which way the snout points, tipped a little toward straight up: the roar goes out ahead of and above the jaws, never over the face
    // (which sits behind the mouth, toward the heart).
    final d = mouth - center;
    var a0 = d.distance > 1e-3 ? math.atan2(d.dy, d.dx) : -2.3;
    if (a0 > 0) a0 -= 2 * math.pi;
    a0 = a0.clamp(-3.3, -1.3);
    a0 += (-math.pi / 2 - a0) * .05;
    c.save();
    c.translate(mouth.dx, mouth.dy);
    if (reducedMotion) {
      _still(c, h, level, a0);
    } else {
      final live = seconds.isFinite ? seconds : 0.0;
      if (t < 0) _intake(c, h, t, k, a0);
      _flash(c, h, t, k, a0);
      _rings(c, h, t, k, fury, a0);
      _herald(c, h, t, k, live, a0);
      _motes(c, h, t, k, fury, live, a0);
      _billow(c, h, t, k, a0);
    }
    c.restore();
  }

  /// The call's clock read off [boss]: seconds from the call landing
  /// (negative through the intake) and its strength, for the first call of a
  /// cycle and, in fury, its follow-up; null between calls. A pure function
  /// of the boss clock, the same as `DragonPose.call`.
  static ({double tau, double strength})? timing(SkyBoss boss) {
    if (!boss.isDragon ||
        !boss.callsSwarm ||
        boss.phase != BossPhase.attacking) {
      return null;
    }
    final cycle = (boss.age - boss.arrivalDuration) % DragonBreath.period;
    final first = cycle - SkyBoss.swarmCallAt;
    if (first >= -intake && first < length) return (tau: first, strength: 1.0);
    if (boss.swarmFollowsUp) {
      final second = first - SkyBoss.swarmFollowAfter;
      if (second >= -intake && second < length) {
        return (tau: second, strength: .8);
      }
    }
    return null;
  }

  /// Where in the fade a bare [call] value sits (0.45 s in at 1, gone at
  /// 1.0 s): the inverse of the pose's smoothstep fade.
  static double _tauOfCall(double call) {
    if (call >= .999) return .3;
    final y = call.clamp(0.0, 1.0);
    final x = .5 - math.sin(math.asin(1 - 2 * y) / 3);
    return .45 + .55 * x;
  }

  // ------------------------------------------------------------ caches --

  static final _glowShader = ui.Gradient.radial(
    Offset.zero,
    1,
    [
      DragonPalette.call.withValues(alpha: .9),
      DragonPalette.call.withValues(alpha: .32),
      DragonPalette.callDeep.withValues(alpha: 0),
    ],
    const [.1, .5, 1],
  );

  /// A soft puff of ash-violet smoke.
  static final _smokeShader = ui.Gradient.radial(
    Offset.zero,
    1,
    [
      DragonPalette.ash.withValues(alpha: .75),
      DragonPalette.ash.withValues(alpha: .35),
      DragonPalette.ash.withValues(alpha: 0),
    ],
    const [.1, .55, 1],
  );

  /// The bat glyph, half a unit each way: ears, an arched wing and a
  /// scalloped trailing edge, so even at 7 px it is a bat and not a chevron.
  static final Path _bat = () {
    const half = <Offset>[
      Offset(0, -.4),
      Offset(.14, -.7),
      Offset(.25, -.34),
      Offset(.58, -.6),
      Offset(1, -.36),
      Offset(.82, -.08),
      Offset(.88, .24),
      Offset(.62, .04),
      Offset(.56, .38),
      Offset(.3, .1),
      Offset(0, .3),
    ];
    final p = Path()..moveTo(half.first.dx, half.first.dy);
    for (var i = 1; i < half.length; i++) {
      p.lineTo(half[i].dx, half[i].dy);
    }
    for (var i = half.length - 2; i >= 1; i--) {
      p.lineTo(-half[i].dx, half[i].dy);
    }
    return p..close();
  }();

  /// A radial [shader] (built on the unit circle) filling a disc of [radius]
  /// at [at], [alpha] deep.
  static void _disc(
    Canvas c,
    Offset at,
    double radius,
    ui.Shader shader,
    double alpha, {
    BlendMode blend = BlendMode.srcOver,
  }) {
    if (alpha <= 0 || radius <= 0) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius);
    c.drawCircle(Offset.zero, 1, _shaded(shader, alpha, blend));
    c.restore();
  }

  static Paint _shaded(
    ui.Shader shader,
    double alpha, [
    BlendMode blend = BlendMode.srcOver,
  ]) => Paint()
    ..shader = shader
    ..blendMode = blend
    ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));

  static double _easeOut(double t) => 1 - math.pow(1 - t, 2.4).toDouble();

  // ------------------------------------------------------------ pieces --
  // Everything is drawn with the canvas at the jaws, and the roar's pieces
  // keep to the half-plane AHEAD of the mouth (angle [a0], the snout's way,
  // tipped up): the fire's orb, streaks and muzzle share that sky in warm
  // colours, and the face sits behind the mouth where nothing here reaches.

  /// The intake: six wisps of violet curl in from ahead toward the jaws.
  static void _intake(Canvas c, double h, double tau, double k, double a0) {
    final pull = BossMotion.ease(BossMotion.ramp(tau, -intake, 0));
    if (pull <= 0) return;
    final r = h * (.2 - .16 * pull);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    for (var i = 0; i < 6; i++) {
      final a = a0 + (i / 5 - .5) * 1.7 - .2 + pull * .1;
      c.drawArc(
        rect,
        a,
        .5,
        false,
        DragonKit.line(DragonPalette.callDeep, h * .02, .7 * pull * k),
      );
      c.drawArc(
        rect,
        a + .05,
        .4,
        false,
        DragonKit.line(DragonPalette.call, h * .01, pull * k),
      );
    }
  }

  /// The instant the call lands: a sparkle of cool light at the jaws.
  static void _flash(Canvas c, double h, double tau, double k, double a0) {
    final p = BossMotion.ramp(tau, 0, .16);
    if (tau < 0 || p >= 1) return;
    final a = (1 - p) * k;
    c.save();
    c.translate(math.cos(a0) * h * .012, math.sin(a0) * h * .012);
    c.scale(h * (.035 + .04 * _easeOut(p)));
    c.drawPath(_sparkle, DragonKit.fill(DragonPalette.callDeep, a * .55));
    c.scale(.72);
    c.drawPath(_sparkle, DragonKit.fill(_paleCall, a));
    c.restore();
  }

  /// A four-point sparkle, unit radius.
  static final Path _sparkle = Path()
    ..moveTo(1, 0)
    ..quadraticBezierTo(.14, -.14, 0, -1)
    ..quadraticBezierTo(-.14, -.14, -1, 0)
    ..quadraticBezierTo(-.14, .14, 0, 1)
    ..quadraticBezierTo(.14, .14, 1, 0)
    ..close();

  /// Two shock rings (three in fury), thick and elliptical, running out
  /// ahead of and above the jaws: arcs of the ellipse open toward the head,
  /// so the sound goes up over the sky in front of the dragon and never at
  /// the bird or across its face. The first carries a soft band of violet,
  /// so the roar has weight without a veil over anything.
  static void _rings(
    Canvas c,
    double h,
    double tau,
    double k,
    bool fury,
    double a0,
  ) {
    for (var j = 0; j < (fury ? 3 : 2); j++) {
      final t = tau - j * .12;
      if (t < 0 || t > .55) continue;
      final p = t / .55;
      final rx = h * (.09 + .15 * _easeOut(p));
      final alpha = math.pow(1 - p, 1.15).toDouble() * k;
      // The ring's centre drifts ahead as it grows.
      final at = DragonKit.heading(a0) * (rx * .2);
      final rect = Rect.fromCenter(center: at, width: rx * 2, height: rx * 1.4);
      final start = a0 - 1.1;
      if (j == 0) {
        c.drawArc(
          rect,
          start,
          2.2,
          false,
          DragonKit.line(DragonPalette.call, h * .06, alpha * .26),
        );
      }
      c.drawArc(
        rect,
        start,
        2.2,
        false,
        DragonKit.line(
          DragonPalette.callDeep,
          h * (.021 - .007 * p),
          alpha * .7,
        ),
      );
      c.drawArc(
        rect,
        start,
        2.2,
        false,
        DragonKit.line(
          j == 0 ? DragonPalette.call : _paleCall,
          h * (.011 - .004 * p),
          alpha,
        ),
      );
    }
  }

  static const _paleCall = Color(0xffe6dcff);

  /// Where a point [p] (0 to 1) of the way along a mote's arc sits: out
  /// from the jaws toward [end], bowed to one side by [bow] (a quadratic
  /// Bézier), so the motes swirl instead of flying in straight lines.
  static Offset _arc(double p, Offset end, double bow) {
    final side = Offset(-end.dy, end.dx) * bow;
    final ctrl = end * .5 + side;
    final u = 1 - p;
    return ctrl * (2 * u * p) + end * (p * p);
  }

  /// The herald sigil: a bat in a ring, the first thing out of the roar. It
  /// rises ahead of the jaws like a rune hung in the air, and fades.
  static void _herald(
    Canvas c,
    double h,
    double tau,
    double k,
    double time,
    double a0,
  ) {
    final t = tau - .03;
    if (t < 0 || t > .8) return;
    final p = t / .8;
    final at = DragonKit.heading(a0) * (h * (.08 + .12 * _easeOut(p)));
    final grow = .55 + .45 * BossMotion.ease(BossMotion.ramp(p, 0, .25));
    final alpha =
        BossMotion.ramp(p, 0, .08) * (1 - BossMotion.ramp(p, .6, 1)) * k;
    _sigil(c, at, h * .056 * grow, alpha, time + p * 4);
  }

  /// The call at rest: one band-and-line ring ahead of the jaws with the
  /// herald hung in it.
  static void _still(Canvas c, double h, double level, double a0) {
    final rect = Rect.fromCenter(
      center: DragonKit.heading(a0) * (h * .04),
      width: h * .4,
      height: h * .28,
    );
    final start = a0 - 1.1;
    c.drawArc(
      rect,
      start,
      2.2,
      false,
      DragonKit.line(DragonPalette.call, h * .06, .28 * level),
    );
    c.drawArc(
      rect,
      start,
      2.2,
      false,
      DragonKit.line(DragonPalette.callDeep, h * .016, .65 * level),
    );
    c.drawArc(
      rect,
      start,
      2.2,
      false,
      DragonKit.line(DragonPalette.call, h * .008, level),
    );
    _sigil(c, DragonKit.heading(a0) * (h * .15), h * .05, level, 0);
  }

  static void _sigil(Canvas c, Offset at, double r, double alpha, double time) {
    if (alpha <= 0) return;
    c.save();
    c.translate(at.dx, at.dy);
    _disc(c, Offset.zero, r * 1.9, _glowShader, alpha * .7);
    c.drawCircle(
      Offset.zero,
      r,
      DragonKit.line(DragonPalette.callDeep, r * .3, alpha * .9),
    );
    c.drawCircle(
      Offset.zero,
      r,
      DragonKit.line(DragonPalette.call, r * .13, alpha),
    );
    // The bat inside beats its wings.
    final flap = .8 + .2 * math.sin(time * 14);
    c.scale(r * .7, r * .7 * flap);
    c.drawPath(_bat, DragonKit.fill(DragonPalette.callDeep, alpha));
    c.scale(.8);
    c.drawPath(_bat, DragonKit.fill(_paleCall, alpha));
    c.restore();
  }

  /// Bat-glyph motes swirling up out of the roar in a fan ahead of and above
  /// the jaws (never back over the face), each trailing a wisp.
  static void _motes(
    Canvas c,
    double h,
    double tau,
    double k,
    bool fury,
    double time,
    double a0,
  ) {
    final count = fury ? 7 : 6;
    // The fan is centred a little nearer straight up than the snout points.
    final centre = a0 + (-math.pi / 2 - a0) * .3;
    for (var i = 0; i < count; i++) {
      final t = tau - (.07 + .045 * i);
      if (t < 0 || t > .78) continue;
      final p = t / .78;
      final angle = centre + (i / (count - 1) - .5) * .85;
      final end =
          DragonKit.heading(angle) *
          (h * (.22 + .1 * DragonKit.hash(i, 3) + .02 * (i % 2)));
      final bow = i.isEven ? .28 : -.28;
      final e = _easeOut(p);
      final wobble = math.sin(p * 9 + i * 1.7) * h * .005;
      final at = _arc(e, end, bow) + Offset(0, wobble);
      final tail = _arc(math.max(0, e - .2), end, bow) + Offset(0, wobble);
      final alpha =
          BossMotion.ramp(p, 0, .1) * (1 - BossMotion.ramp(p, .5, 1)) * k;
      if (alpha <= .01) continue;
      c.drawLine(
        tail,
        at,
        DragonKit.line(DragonPalette.call, h * .006, alpha * .7),
      );
      final size = h * (.024 + .006 * DragonKit.hash(i, 9));
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate((DragonKit.hash(i, 11) - .5) * .6 + (angle + math.pi / 2) * .5);
      c.scale(size, size * (.8 + .2 * math.sin(time * 15 + i * 1.3)));
      // An ink-violet edge under the light fill: it reads on a pale sky as
      // well as a dark one.
      c.drawPath(_bat, DragonKit.line(DragonPalette.callDeep, .3, alpha));
      c.drawPath(
        _bat,
        DragonKit.fill(fury ? _paleCall : DragonPalette.call, alpha),
      );
      c.restore();
    }
  }

  /// A dark billow puffing up ahead of the snout as the roar lands.
  static void _billow(Canvas c, double h, double tau, double k, double a0) {
    final p = BossMotion.ramp(tau, .04, .8);
    if (p <= 0 || p >= 1) return;
    final a = math.sin(math.pi * math.pow(p, .7)).toDouble() * .5 * k;
    for (var i = 0; i < 2; i++) {
      final q = BossMotion.ramp(p, i * .12, 1);
      final at =
          DragonKit.heading(a0) * (h * (.06 + .05 * q + i * .02)) +
          Offset(0, -h * (.02 + .05 * q));
      _disc(
        c,
        at,
        h * (.022 + .03 * q + i * .008),
        _smokeShader,
        a * (1 - i * .25),
      );
    }
  }
}
