import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';

/// Where each cannonball will cross the bird's flight line: a treasure-map
/// X in a reticle ring that shrinks and fills with red as the ball comes
/// down, and a small tag at the top of the screen for a lob that has
/// climbed out of view.
///
/// These are pure readouts of the simulated arc (nothing here can change the
/// rules) and they stay quiet until a ball is close, so they never crowd
/// the bird lane or hide a shot.
abstract final class PirateAimArt {
  static const _ink = Color(0xff123049), _warn = Color(0xffff5a36);
  static const _cream = Color(0xfffff9ed), _iron = Color(0xff2a2c37);
  static const _glint = Color(0xffaab2c6);

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));
  static Paint _stroke(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  static void paint(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) {
    final level = boss.waterLevel ?? 1.0;
    final h = size.height;
    const x = FlightSimulation.birdX;
    for (final ball in sim.bossAmmo) {
      if (!ball.cannonball) continue;
      if (ball.y < -ball.radius) _overhead(c, size, ball);
      if (ball.vx >= 0 || ball.x <= x + .06) continue;
      final time = (ball.x - x) / -ball.vx;
      final y = ball.y + ball.vy * time + ball.gravity * time * time / 2;
      if (y > level - ball.radius * .5 || y < .02) continue;
      final near = 1 - BossMotion.ramp(time, .25, 2.2);
      final alpha = BossMotion.ramp(time, .06, .2) * (.35 + .55 * near);
      if (alpha <= 0) continue;
      final beat = m.reducedMotion || near < .8
          ? 0.0
          : math.sin(sim.elapsed * 22) * (near - .8) * .2;
      _mark(c, h, Offset(x * h, y * h), near, alpha, beat);
    }
  }

  /// One landing mark: [near] runs 0 to 1 as the ball closes in.
  static void _mark(
    Canvas c,
    double h,
    Offset at,
    double near,
    double alpha,
    double beat,
  ) {
    final ring = h * (.052 + (1 - near) * .03) * (1 + beat);
    // The impact zone warms toward red.
    c.drawCircle(at, ring, _fill(_warn, (.04 + .16 * near * near) * alpha));
    c.drawCircle(at, ring, _stroke(_ink, h * .009, .4 * alpha));
    c.drawCircle(at, ring, _stroke(_cream, h * .0038, alpha * .85));
    // A red sweep runs round the ring and closes as the ball arrives.
    if (near > .02) {
      final arc = Rect.fromCircle(center: at, radius: ring);
      final sweep = math.pi * 2 * near;
      c.drawArc(
        arc,
        -math.pi / 2,
        sweep,
        false,
        _stroke(_ink, h * .0125, .45 * alpha),
      );
      c.drawArc(
        arc,
        -math.pi / 2,
        sweep,
        false,
        _stroke(_warn, h * .0075, alpha),
      );
    }
    // Four ticks on the ring close in with it.
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        at + d * (ring - h * .012),
        at + d * (ring + h * .006),
        _stroke(_cream, h * .004, alpha),
      );
    }
    // The treasure-map X: ink outline, red arms, a cream heart.
    final arm = h * (.014 + near * .004);
    for (final s in [1.0, -1.0]) {
      c.drawLine(
        at + Offset(-arm, -arm * s),
        at + Offset(arm, arm * s),
        _stroke(_ink, h * .0125, .55 * alpha),
      );
    }
    for (final s in [1.0, -1.0]) {
      c.drawLine(
        at + Offset(-arm, -arm * s),
        at + Offset(arm, arm * s),
        _stroke(_warn, h * .0072, alpha),
      );
    }
    c.drawCircle(at, h * .0034, _fill(_cream, alpha));
  }

  /// A tag under the boss plate for a lob that has climbed out of view: a
  /// small iron shot with chevrons showing which way it is heading, red and
  /// pointing down once it is coming back.
  static void _overhead(Canvas c, Size size, BossAmmo ball) {
    final h = size.height;
    final up = -ball.y;
    final alpha = (1 - BossMotion.ramp(up, .1, .7)) * .75 + .25;
    final falling = ball.vy > 0;
    final r = h * .015;
    final gap = h * .02;
    final at = Offset(
      (ball.x * h).clamp(gap * 2, size.width - gap * 2),
      h * .14,
    );
    final dir = falling ? 1.0 : -1.0;
    // A soft capsule to sit on, with the ball in the middle.
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: r * 3.1, height: r * 7.6),
      Radius.circular(r * 1.55),
    );
    c.drawRRect(pill, _fill(_ink, .42 * alpha));
    c.drawRRect(pill, _stroke(_cream, h * .0035, .8 * alpha));
    c.drawCircle(at, r * 1.08, _fill(_ink, alpha));
    c.drawCircle(at, r, _fill(_iron, alpha));
    c.drawCircle(
      at + Offset(-r * .34, -r * .38),
      r * .34,
      _fill(_glint, alpha),
    );
    // Two chevrons on the side it is heading toward.
    final color = falling ? _warn : _cream;
    for (var i = 0; i < 2; i++) {
      final base = at + Offset(0, dir * (r * 1.9 + i * r * .95));
      final chevron = Path()
        ..moveTo(base.dx - r * .85, base.dy - dir * r * .5)
        ..lineTo(base.dx, base.dy + dir * r * .3)
        ..lineTo(base.dx + r * .85, base.dy - dir * r * .5);
      final fade = alpha * (1 - i * .35);
      c.drawPath(chevron, _stroke(_ink, h * .0095, .5 * fade));
      c.drawPath(chevron, _stroke(color, h * .0052, fade));
    }
  }
}
