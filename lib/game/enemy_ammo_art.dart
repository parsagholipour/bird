import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_enemy.dart';
import '../ui/theme.dart';

/// Compact hostile cores with translucent wakes, drawn in hit-radius units.
/// Motion follows simulation time so pausing and replay seeking stay exact.
abstract final class EnemyAmmoArt {
  static const _mint = Color(0xffb3ffda);
  static const _green = Color(0xff246d60);
  static const _amber = Color(0xffffc85c);
  static const _copper = Color(0xff713f42);
  static const _bounds = Rect.fromLTRB(-1, -1, 1, 1);

  static final _spit = Path()
    ..moveTo(-1.42, .12)
    ..cubicTo(-.91, -.11, -.87, -.72, -.28, -.89)
    ..cubicTo(.39, -1.08, 1.01, -.54, 1.01, .04)
    ..cubicTo(1.01, .68, .39, 1.04, -.25, .88)
    ..cubicTo(-.87, .74, -.82, .26, -1.42, .12)
    ..close();

  static final _ember = Path()
    ..moveTo(1.08, 0)
    ..lineTo(.44, -.73)
    ..lineTo(-.19, -.96)
    ..lineTo(-.76, -.64)
    ..lineTo(-1.28, -.66)
    ..lineTo(-.97, -.10)
    ..lineTo(-1.30, .43)
    ..lineTo(-.69, .43)
    ..lineTo(-.26, .90)
    ..lineTo(.45, .70)
    ..close();

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
    canvas.save();
    canvas.translate(ammo.x * height, ammo.y * height);
    canvas.rotate(direction);
    canvas.scale(radius);
    final edge = math.max(.14, 1 / radius);
    if (ammo.attack == EnemyAttack.aimed) {
      _mintSpit(canvas, edge, time);
    } else {
      _amberEmber(canvas, edge, time);
    }
    canvas.restore();
  }

  static void _mintSpit(Canvas c, double edge, double time) {
    final wobble = math.sin(time * 10);
    final ripple = math.sin(time * 10 - .9) * .24;
    _wake(
      c,
      Path()
        ..moveTo(-4.1, -.25 + ripple)
        ..cubicTo(-3.1, .50 + ripple, -2.05, -.82 - wobble * .18, -.42, -.59)
        ..lineTo(-.51, .62)
        ..cubicTo(
          -2.20,
          .98 - wobble * .18,
          -2.62,
          .12 + ripple,
          -4.1,
          -.25 + ripple,
        )
        ..close(),
      _mint,
    );
    // Beads peel off, drift down the wake and fade before the loop wraps.
    for (var i = 0; i < 3; i++) {
      final life = (time * 1.35 + i / 3) % 1;
      final alpha = math.sin(life * math.pi);
      final size = .25 * (1 - life * .65);
      final at = Offset(
        -1.25 - life * 2.9,
        math.sin(life * 7 + i * 2.1) * (.12 + life * .25),
      );
      c.drawOval(
        Rect.fromCenter(center: at, width: size * 2.7, height: size * 2),
        _fill(_green.withValues(alpha: .55 * alpha)),
      );
      c.drawCircle(
        at + Offset(size * .18, -size * .2),
        size * .66,
        _fill(_mint.withValues(alpha: alpha)),
      );
    }
    _glow(c, _mint);
    c.save();
    // Squash about the hit center; the flight direction remains easy to read.
    final stretch = 1 + wobble * .085;
    c.scale(stretch, 1 / stretch);
    c.drawPath(
      _spit,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_mint, Color(0xff58c69b), _green],
          stops: [0, .5, 1],
        ).createShader(_bounds),
    );
    c.drawPath(_spit, _stroke(SkyColors.ink, edge));
    c.drawPath(
      Path()
        ..moveTo(-.53, .42)
        ..quadraticBezierTo(.09, .84, .63, .30),
      _stroke(_mint.withValues(alpha: .65), .12),
    );
    c.drawOval(
      Rect.fromLTWH(-.25 + wobble * .07, -.60, .84, .40),
      _fill(SkyColors.cream),
    );
    c.drawCircle(const Offset(.67, -.10), .11, _fill(_mint));
    c.restore();
  }

  static void _amberEmber(Canvas c, double edge, double time) {
    final flutter = math.sin(time * 14);
    final tip = math.sin(time * 11 - 1.2);
    final heat = .5 + .5 * math.sin(time * 13);
    final reach = 4 + tip * .42;
    _wake(
      c,
      Path()
        ..moveTo(-reach, -.42 + tip * .32)
        ..quadraticBezierTo(-2.43, -.58 + flutter * .24, -.52, -.57)
        ..lineTo(-.44, .52)
        ..quadraticBezierTo(
          -2.16,
          .93 - flutter * .24,
          -reach + .45,
          .59 - tip * .28,
        )
        ..quadraticBezierTo(-2.39, .43 - flutter * .15, -1.87, .02)
        ..quadraticBezierTo(
          -3.06,
          -.12 + flutter * .16,
          -reach,
          -.42 + tip * .32,
        )
        ..close(),
      _amber,
    );
    c.drawPath(
      Path()
        ..moveTo(-reach + .84, -.34 + tip * .26)
        ..quadraticBezierTo(-2.15, -.42 + flutter * .20, -1.09, -.26)
        ..moveTo(-reach + 1.35, .51 - tip * .23)
        ..quadraticBezierTo(-1.91, .42 - flutter * .20, -1.21, .12),
      _stroke(_amber.withValues(alpha: .55 + heat * .25), .10),
    );
    _glow(c, _amber, strength: .26 + heat * .22);
    c.save();
    c.rotate(math.sin(time * 8) * .07);
    c.scale(1, 1 + flutter * .055);
    c.drawPath(
      _ember,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_amber, Color(0xffef9250), Color(0xffb95249)],
          stops: [0, .55, 1],
        ).createShader(_bounds),
    );
    c.drawPath(
      Path()
        ..moveTo(-1.28, -.66)
        ..lineTo(-.22, -.36)
        ..lineTo(.96, 0)
        ..lineTo(-.38, .22)
        ..lineTo(-1.30, .43)
        ..lineTo(-.97, -.10)
        ..close(),
      _fill(_copper.withValues(alpha: .75)),
    );
    c.drawPath(
      Path()
        ..moveTo(-.26, .90)
        ..lineTo(-.38, .22)
        ..lineTo(.96, 0)
        ..lineTo(.45, .70)
        ..close(),
      _fill(const Color(0xffd87145)),
    );
    c.drawPath(_ember, _stroke(SkyColors.ink, edge));
    // The hot slit and copper fins distinguish these from collectible stars.
    c.drawPath(
      Path()
        ..moveTo(.86, 0)
        ..lineTo(-.07, -.35)
        ..lineTo(-.52, -.03)
        ..lineTo(-.12, .31)
        ..close(),
      _fill(
        Color.lerp(const Color(0xffffd477), SkyColors.cream, .3 + heat * .7)!,
      ),
    );
    c.drawPath(
      Path()
        ..moveTo(-.16, -.76)
        ..lineTo(.35, -.57)
        ..lineTo(.71, -.19),
      _stroke(_amber, .11),
    );
    c.restore();
  }

  static void _wake(Canvas c, Path shape, Color color) {
    c.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0), color.withValues(alpha: .48)],
        ).createShader(const Rect.fromLTRB(-4.1, -1, -.5, 1)),
    );
  }

  static void _glow(Canvas c, Color color, {double strength = .35}) {
    const bounds = Rect.fromLTRB(-1.5, -1.5, 1.5, 1.5);
    c.drawOval(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: strength),
            color.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );
  }

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
