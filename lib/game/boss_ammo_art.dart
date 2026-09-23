import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_enemy.dart';
import '../ui/theme.dart';

/// Boss relatives of the small mint spit and amber ember: boiling globules
/// and spinning pollen rosettes, still centered on the existing hit circles.
abstract final class BossAmmoArt {
  static const _mint = Color(0xffb3ffda), _green = Color(0xff246d60);
  static const _amber = Color(0xffffc85c), _copper = Color(0xff713f42);
  static const _bounds = Rect.fromLTRB(-1, -1, 1, 1);
  static final _petal = Path()
    ..moveTo(.24, -.16)
    ..lineTo(.61, -.48)
    ..quadraticBezierTo(.97, -.37, 1.08, -.08)
    ..lineTo(.79, .10)
    ..quadraticBezierTo(.78, .44, .46, .54)
    ..lineTo(.49, .16)
    ..close();

  static void paint(
    Canvas c, {
    required Offset center,
    required double radius,
    required double direction,
    required EnemyAttack attack,
    required double seconds,
    required bool reducedMotion,
    bool showTrail = true,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = reducedMotion || !seconds.isFinite
        ? 0.0
        : seconds + direction * .37;
    final mint = attack == EnemyAttack.aimed;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(direction);
    c.scale(radius);
    if (showTrail) _trail(c, time, mint);
    c.drawCircle(
      Offset.zero,
      1.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (mint ? _mint : _amber).withValues(alpha: .32),
            (mint ? _mint : _amber).withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTRB(-1.65, -1.65, 1.65, 1.65)),
    );
    final edge = math.max(.13, 1 / radius);
    if (mint) {
      _globule(c, time, edge);
    } else {
      _rosette(c, time, edge);
    }
    c.restore();
  }

  static void _trail(Canvas c, double time, bool mint) {
    final color = mint ? _mint : _amber;
    final wave = math.sin(time * (mint ? 9 : 12)) * .27;
    for (final side in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(-.58, side * .53)
          ..cubicTo(
            -1.6,
            side * (1 + wave),
            -3.0,
            -side * .12,
            -4.5,
            side * .45,
          )
          ..cubicTo(
            -2.8,
            -side * .26,
            -1.75,
            side * (.34 + wave),
            -.58,
            side * .22,
          )
          ..close(),
        Paint()
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0), color.withValues(alpha: .6)],
          ).createShader(const Rect.fromLTRB(-4.5, -1, -.5, 1)),
      );
    }
    for (var i = 0; i < 4; i++) {
      final life = (time * (mint ? .95 : 1.3) + i / 4) % 1;
      final fade = math.sin(life * math.pi);
      final at = Offset(-1.05 - life * 3.4, math.sin(life * 7 + i) * .4);
      final r = (mint ? .23 : .12) * (1 - life * .55);
      if (mint) {
        c.drawCircle(at, r, _fill(_green.withValues(alpha: fade * .45)));
        c.drawCircle(at, r, _stroke(_mint.withValues(alpha: fade * .8), .055));
      } else {
        c.drawLine(
          at - Offset(r, r * .5),
          at + Offset(r, -r * .5),
          _stroke(_amber.withValues(alpha: fade), .08),
        );
      }
    }
  }

  static void _globule(Canvas c, double time, double edge) {
    // Satellite bubbles swell at the rear of the pressurized liquid shell.
    for (final side in [-1.0, 1.0]) {
      final at = Offset(-.76, side * .54);
      final r = .23 + math.sin(time * 8 + side) * .035;
      c.drawCircle(at, r, _fill(_mint));
      c.drawCircle(at, r, _stroke(_green, edge * .7));
    }
    c.save();
    final pressure = 1 + math.sin(time * 8) * .035;
    c.scale(pressure, 1 / pressure);
    c.drawCircle(
      Offset.zero,
      .96,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.3, -.4),
          colors: [_mint, Color(0xff4cbb92), _green],
          stops: [0, .58, 1],
        ).createShader(_bounds),
    );
    c.drawCircle(Offset.zero, .96, _stroke(SkyColors.ink, edge));
    c.drawArc(
      const Rect.fromLTRB(-.8, -.8, .8, .8),
      -2.7,
      2.4,
      false,
      _stroke(_mint.withValues(alpha: .85), .09),
    );
    c.save();
    c.rotate(time * 2.6);
    c.drawPath(
      Path()
        ..moveTo(.61, -.09)
        ..cubicTo(.60, -.61, -.28, -.69, -.51, -.19)
        ..cubicTo(-.18, -.40, .34, -.23, .22, .12)
        ..cubicTo(.06, .46, -.36, .26, -.37, .03)
        ..cubicTo(-.54, .68, .73, .58, .61, -.09)
        ..close(),
      _fill(const Color(0xffeaffc5)),
    );
    c.drawCircle(const Offset(-.45, .47), .12, _fill(_mint));
    c.drawCircle(const Offset(.37, -.52), .08, _fill(SkyColors.cream));
    c.restore();
    c.drawOval(
      const Rect.fromLTWH(.22, -.75, .35, .16),
      _fill(SkyColors.cream),
    );
    c.restore();
  }

  static void _rosette(Canvas c, double time, double edge) {
    c.save();
    c.rotate(time * 2.2);
    c.drawCircle(Offset.zero, .7, _fill(_copper));
    for (var i = 0; i < 5; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / 5);
      c.drawPath(
        _petal,
        Paint()
          ..shader = const LinearGradient(
            colors: [_copper, Color(0xffe98651), _amber],
            stops: [0, .6, 1],
          ).createShader(_bounds),
      );
      c.drawPath(_petal, _stroke(SkyColors.ink, edge));
      c.drawPath(
        Path()
          ..moveTo(.48, -.13)
          ..lineTo(.68, -.29)
          ..lineTo(.92, -.10),
        _stroke(const Color(0xffffe1a1), .085),
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, .38, _fill(_copper));
    c.drawCircle(Offset.zero, .29, _fill(_amber));
    final pulse = .18 + math.sin(time * 10) * .025;
    c.drawCircle(Offset.zero, pulse, _fill(SkyColors.cream));
    c.restore();
  }

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
