import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_enemy.dart';
import '../ui/theme.dart';

/// Hostile pellets drawn in hit-radius units, travelling along +x.
///
/// The solid, ink-rimmed body ends exactly on the hit circle so a dodge that
/// looks clean is clean; the soft halo and the wake behind are allowed to
/// extend further so the pellet and its heading read at a glance. Every
/// motion follows simulation time, so pausing and replay seeking stay exact.
abstract final class EnemyAmmoArt {
  static const mint = Color(0xffb3ffda);
  static const leaf = Color(0xff72dcaa);
  static const jade = Color(0xff3fb98a);
  static const green = Color(0xff246d60);
  static const amber = Color(0xffffc85c);
  static const flame = Color(0xffef7a45);
  static const ember = Color(0xffc2453c);
  static const copper = Color(0xff713f42);
  static const hot = Color(0xfffff4d2);

  /// A fresh pellet pops out of the muzzle; its wake unrolls behind it so
  /// it never smears across the face of the enemy that fired it.
  static const popSeconds = .09, unrollSeconds = .16;

  static void paint(
    Canvas canvas,
    double height,
    EnemyAmmo ammo, {
    required double seconds,
    required bool reducedMotion,
  }) {
    final radius = height * EnemyAmmo.radius;
    if (!radius.isFinite || radius <= 0) return;
    final direction = math.atan2(ammo.vy, ammo.vx);
    // Direction gives each member of a fan its own rhythm without storing
    // particle state or changing projectile movement/collision geometry.
    final time = reducedMotion || !seconds.isFinite
        ? 0.0
        : seconds + direction * .37;
    final age = seconds - ammo.bornAt;
    final unrolled = age.isNaN ? 1.0 : (age / unrollSeconds).clamp(0.0, 1.0);
    final speed = math.sqrt(ammo.vx * ammo.vx + ammo.vy * ammo.vy);
    final reach = (speed / .4).clamp(.7, 1.3) * unrolled;
    canvas.save();
    canvas.translate(ammo.x * height, ammo.y * height);
    canvas.rotate(direction);
    // Keep the sky light on top whichever way the pellet is heading.
    if (math.cos(direction) < 0) canvas.scale(1, -1);
    canvas.scale(radius);
    final fine = radius >= 14;
    // The ink rim holds ~1.6 px at gameplay size and ends on the hit circle.
    final edge = math.max(.15, 1.6 / radius);
    final spit = ammo.attack == EnemyAttack.aimed;
    if (spit) {
      _spitWake(canvas, time, reach, fine);
    } else {
      _emberWake(canvas, time, reach);
    }
    if (!reducedMotion && !age.isNaN && age < popSeconds) {
      // Squirted out long and thin, overshoots round, settles.
      final t = math.max(0.0, age) / popSeconds;
      final pop = .55 + .45 * _backOut(t);
      final stretch = 1 + .45 * (1 - t) * (1 - t);
      canvas.scale(pop * stretch, pop / stretch);
    }
    if (spit) {
      _spit(canvas, edge, time, fine);
    } else {
      _ember(canvas, edge, time, fine);
    }
    canvas.restore();
  }

  static double _backOut(double t) {
    const c1 = 1.70158, c3 = c1 + 1;
    final u = t - 1;
    return 1 + c3 * u * u * u + c1 * u * u;
  }

  // Gradients are fixed in local units, so their shaders are built once and
  // shared by every pellet on screen instead of being rebuilt each frame.
  static Paint _haloPaint(Color color, double alpha, double size) =>
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * .55),
            color.withValues(alpha: 0),
          ],
          stops: const [.45, .62, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: size));

  /// A wake fill for unit space: transparent at x = -1, [alpha] at x = 0.
  static Paint _wakePaint(Color color, double alpha) => Paint()
    ..shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: alpha),
      ],
    ).createShader(const Rect.fromLTRB(-1, -1, 0, 1));

  static final _spitHalo = _haloPaint(mint, .55, 1.95);
  static final _emberHalo = _haloPaint(amber, .56, 2.05);
  static final _spitWakeOuter = _wakePaint(jade, .85);
  static final _spitWakeInner = _wakePaint(mint, 1);
  static final _emberWakeOuter = _wakePaint(amber, .78);
  static final _emberWakeInner = _wakePaint(hot, .9);
  static final _spitBody = Paint()
    ..shader = const LinearGradient(
      begin: Alignment(.35, -1),
      end: Alignment(-.35, 1),
      colors: [mint, leaf, jade, green],
      stops: [.08, .4, .72, 1],
    ).createShader(_bounds);
  static final _emberBody = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [amber, flame, ember],
      stops: [.12, .5, 1],
    ).createShader(const Rect.fromLTRB(-2.6, -1, 1, 1));
  static final _emberCore = Paint()
    ..shader = RadialGradient(
      colors: [hot, hot, amber.withValues(alpha: 0)],
      stops: const [0, .5, 1],
    ).createShader(_bounds);

  // ---------------------------------------------------------------- spit --

  static void _spitWake(Canvas c, double time, double reach, bool fine) {
    final wag = math.sin(time * 10 - .9);
    final tail = 4.8 * reach;
    if (tail < .9) return;
    // The ribbon is drawn in unit length and stretched to the wake's reach.
    final root = -.3 / tail;
    c.save();
    c.scale(tail, 1);
    c.drawPath(
      Path()
        ..moveTo(root, -.86)
        ..cubicTo(-.35, -.78 + wag * .08, -.66, -.28 + wag * .20, -1, wag * .3)
        ..cubicTo(-.62, .32 + wag * .20, -.33, .80 - wag * .08, root, .86)
        ..close(),
      _spitWakeOuter,
    );
    c.drawPath(
      Path()
        ..moveTo(root, -.46)
        ..quadraticBezierTo(-.5, -.32 + wag * .16, -.8, wag * .26)
        ..quadraticBezierTo(-.5, .32 + wag * .16, root, .46)
        ..close(),
      _spitWakeInner,
    );
    c.restore();
    // Beads peel off the wake and fade before the loop wraps.
    for (var i = 0; i < 3; i++) {
      final life = (time * 1.35 + i / 3) % 1;
      final x = -1.4 - life * (tail - 1.2) * .92;
      if (x < -tail) continue;
      final fade = math.sin(life * math.pi);
      final size = .36 * (1 - life * .55);
      final at = Offset(x, math.sin(life * 6 + i * 2.1) * (.12 + life * .32));
      c.drawCircle(at, size, _fill(jade.withValues(alpha: .95 * fade)));
      if (fine) {
        c.drawCircle(
          at + Offset(size * .2, -size * .25),
          size * .38,
          _fill(mint.withValues(alpha: fade)),
        );
      }
    }
  }

  static void _spit(Canvas c, double edge, double time, bool fine) {
    final wobble = math.sin(time * 10);
    final wag = math.sin(time * 10 - .9);
    c.drawCircle(Offset.zero, 1.95, _spitHalo);
    c.save();
    // The rim's outer edge lands on the hit circle at every scale.
    final body = 1 - edge / 2;
    final stretch = 1 + wobble * .06;
    c.scale(body * stretch, body / stretch);
    final tip = .04 + wag * .12;
    final drop = Path()
      ..moveTo(1, 0)
      ..cubicTo(1, -.56, .56, -1, 0, -1)
      ..cubicTo(-.52, -1, -.86, -.70, -1.16, -.38)
      ..cubicTo(-1.36, -.17, -1.56, tip - .06, -1.82, tip)
      ..cubicTo(-1.56, tip + .14, -1.36, .30, -1.12, .50)
      ..cubicTo(-.82, .82, -.46, 1, 0, 1)
      ..cubicTo(.56, 1, 1, .56, 1, 0)
      ..close();
    c.drawPath(drop, _spitBody);
    if (fine) {
      // Reflected light along the belly gives the drop its liquid volume.
      c.drawPath(
        Path()
          ..moveTo(-.62, .52)
          ..quadraticBezierTo(.05, .92, .70, .40),
        _stroke(mint.withValues(alpha: .7), .13),
      );
    }
    c.drawPath(drop, _stroke(SkyColors.ink, edge / body));
    c.save();
    c.translate(.12 + wobble * .04, -.47);
    c.rotate(-.3);
    c.drawOval(const Rect.fromLTRB(-.5, -.21, .5, .21), _fill(SkyColors.cream));
    c.restore();
    c.drawCircle(const Offset(.64, .06), .13, _fill(SkyColors.cream));
    c.restore();
  }

  // --------------------------------------------------------------- ember --

  static void _emberWake(Canvas c, double time, double reach) {
    final tail = 4.4 * reach;
    if (tail < .9) return;
    final lick = math.sin(time * 11 - 1.2);
    final root = -.4 / tail;
    c.save();
    c.scale(tail, 1);
    c.drawPath(
      Path()
        ..moveTo(root, -.86)
        ..quadraticBezierTo(-.55, -.64 + lick * .16, -1, lick * .22)
        ..quadraticBezierTo(-.55, .64 + lick * .16, root, .86)
        ..close(),
      _emberWakeOuter,
    );
    c.drawPath(
      Path()
        ..moveTo(root, -.34)
        ..quadraticBezierTo(-.45, -.22 + lick * .1, -.75, lick * .18)
        ..quadraticBezierTo(-.45, .22 + lick * .1, root, .34)
        ..close(),
      _emberWakeInner,
    );
    c.restore();
    // Sparks shed from the flames stream backwards, flicker and fade.
    for (var i = 0; i < 3; i++) {
      final life = (time * 1.7 + i / 3) % 1;
      final x = -1.7 - life * (tail - 1.4);
      if (x < -tail) continue;
      final fade =
          math.sin(life * math.pi) * (.75 + .25 * math.sin(time * 31 + i));
      final at = Offset(x, (i - 1) * (.42 + life * .5));
      final s = .5 * (1 - life * .5);
      c.drawLine(
        at,
        at - Offset(s, 0),
        _stroke(Color.lerp(amber, hot, .5)!.withValues(alpha: fade), .26),
      );
    }
  }

  static void _ember(Canvas c, double edge, double time, bool fine) {
    final f1 = math.sin(time * 17.3);
    final f2 = math.sin(time * 23.9 + 1.7);
    final f3 = math.sin(time * 19.1 + 3.1);
    final heat =
        .5 + .28 * math.sin(time * 13) + .22 * math.sin(time * 29.3 + 1.1);
    c.drawCircle(Offset.zero, 2.05, _emberHalo);
    c.save();
    final body = 1 - edge / 2;
    c.scale(body);
    c.rotate(math.sin(time * 7) * .05);
    // A round hot head with three flame tongues licking back; the long
    // middle tongue makes the heading obvious even at a few pixels.
    final shape = Path()
      ..moveTo(1, 0)
      ..cubicTo(1, -.56, .56, -1, 0, -1)
      ..quadraticBezierTo(-.9, -1.08, -1.58 - f1 * .14, -1.02 - f1 * .05)
      ..quadraticBezierTo(-1.25, -.66, -1.04, -.44)
      ..quadraticBezierTo(-1.86, -.40, -2.62 - f2 * .24, .02 + f2 * .07)
      ..quadraticBezierTo(-1.86, .40, -1.04, .46)
      ..quadraticBezierTo(-1.24, .68, -1.50 - f3 * .14, 1.0 + f3 * .05)
      ..quadraticBezierTo(-.85, 1.06, 0, 1)
      ..cubicTo(.56, 1, 1, .56, 1, 0)
      ..close();
    c.drawPath(shape, _emberBody);
    if (fine) {
      c.drawPath(
        Path()
          ..moveTo(-1.38, -.82)
          ..quadraticBezierTo(-.9, -.66, -.52, -.56)
          ..moveTo(-2.2, .02)
          ..quadraticBezierTo(-1.5, .02, -.9, .06)
          ..moveTo(-1.32, .84)
          ..quadraticBezierTo(-.9, .70, -.52, .62),
        _stroke(copper.withValues(alpha: .5), .12),
      );
    }
    // A white-hot heart that flickers without moving the silhouette.
    c.save();
    c.translate(.2, 0);
    c.scale(.58 + heat * .1);
    c.drawCircle(Offset.zero, 1, _emberCore);
    c.restore();
    c.drawPath(shape, _stroke(SkyColors.ink, edge / body));
    c.restore();
  }

  static const _bounds = Rect.fromLTRB(-1, -1, 1, 1);

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
