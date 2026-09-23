import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';

/// A chipped stone shell with an amber core that brightens as it charges.
abstract final class StoneArt {
  static const _bounds = Rect.fromLTRB(-1, -1, 1, 1);
  static const _amber = Color(0xffffb843);
  static const _hot = Color(0xffffefb5);
  static const _slate = Color(0xff425b63);

  static void paint(
    Canvas canvas,
    double height,
    BirdRock rock, {
    required double seconds,
    required bool reducedMotion,
  }) {
    canvas.save();
    canvas.translate(rock.x * height, rock.y * height);
    canvas.scale(rock.radius * height);
    if (rock.rebounding) {
      if (!reducedMotion) {
        final age = rock.reboundAge!;
        // A brief impact squash opens into a tumbling, unpowered shell.
        final squash = (1 - age / .1).clamp(0.0, 1.0) * .22;
        canvas.scale(1 - squash, 1 + squash);
        canvas.rotate(-age * 8);
      }
    } else {
      _trail(canvas, rock.charge, reducedMotion ? 0 : seconds);
    }
    _body(canvas, rock.charge);
    canvas.restore();
  }

  static void charge(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    if (!sim.charging || sim.outOfAmmo || sim.bossCutscene) return;
    final power = sim.shotCharge;
    final origin = sim.shotOrigin(power, reducedMotion: reducedMotion);
    final radius = BirdRock.baseRadius * PowerShot.radiusScale(power) * height;
    final left = sim.fullHoldLeft;
    final urgency = power >= 1 ? 1 - left : 0.0;
    final seconds = reducedMotion ? 0.0 : sim.elapsed;
    final pulse = reducedMotion
        ? 0.0
        : math.sin(seconds * (12 + urgency * 18)) * .06;
    canvas.save();
    canvas.translate(origin.x * height, origin.y * height);
    canvas.scale(radius);
    _glow(canvas, Offset.zero, 1.85 + power * .25 + pulse, .12 + power * .22);
    final energy = _energy(power);
    if (energy > 0) {
      // Small suspended chips stay close to the shell and inside the hold ring.
      for (var i = 0; i < 3; i++) {
        final angle = -1.95 + i * 2.15 + math.sin(seconds * 2 + i) * .12;
        final center = Offset(math.cos(angle), math.sin(angle)) * (1.2 + pulse);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle + .5);
        canvas.scale((.065 + i * .012) * energy);
        canvas.drawPath(_chip, Paint()..color = _slate);
        canvas.drawPath(_chip, _stroke(_hot.withValues(alpha: energy), .24));
        canvas.restore();
      }
    }
    _body(canvas, power);
    if (power >= 1 && left > 0) {
      const ring = Rect.fromLTRB(-1.5, -1.5, 1.5, 1.5);
      final sweep = math.pi * 2 * left;
      canvas.drawArc(
        ring,
        -math.pi / 2,
        sweep,
        false,
        _stroke(_amber.withValues(alpha: .24), .15),
      );
      canvas.drawArc(
        ring,
        -math.pi / 2,
        sweep,
        false,
        _stroke(SkyColors.cream.withValues(alpha: .94), .055),
      );
      final tipAngle = -math.pi / 2 + sweep;
      final tip = Offset(math.cos(tipAngle), math.sin(tipAngle)) * 1.5;
      _glow(canvas, tip, .2, .65);
      canvas.drawCircle(tip, .065, Paint()..color = _hot);
    }
    canvas.restore();
  }

  static double _energy(double charge) =>
      ((charge - .15) / .85).clamp(0.0, 1.0);

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width;

  static void _glow(Canvas canvas, Offset center, double radius, double alpha) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _amber.withValues(alpha: alpha),
            _amber.withValues(alpha: alpha * .55),
            _amber.withValues(alpha: 0),
          ],
          stops: const [0, .4, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  static void _trail(Canvas canvas, double charge, double seconds) {
    final energy = _energy(charge);
    final length = 3.1 + charge * 1.9;
    final bounds = Rect.fromLTRB(-length, -1, -.5, 1);
    final tint = Color.lerp(SkyColors.cream, _amber, energy)!;
    canvas.drawPath(
      Path()
        ..moveTo(-length, .15)
        ..cubicTo(-3, -.15, -1.9, -.85, -.55, -.77)
        ..lineTo(-.35, .72)
        ..cubicTo(-1.8, .9, -2.7, .15, -length, .15)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [
            tint.withValues(alpha: 0),
            tint.withValues(alpha: .15 + energy * .2),
            tint.withValues(alpha: .65),
          ],
          stops: const [0, .5, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-length * .82, .12)
        ..cubicTo(-2.2, .18, -1.45, -.39, -.64, -.36)
        ..lineTo(-.56, .38)
        ..cubicTo(-1.6, .27, -2.2, .01, -length * .82, .12)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [_hot.withValues(alpha: 0), _hot.withValues(alpha: .85)],
        ).createShader(bounds),
    );
    if (energy == 0) return;
    for (var i = 0; i < 3; i++) {
      final travel = (seconds * 1.4 + i * .31) % 1;
      final x = -1.15 - travel * 2.5;
      final y = (i.isEven ? -1 : 1) * (.35 + travel * .45);
      final alpha = energy * (1 - travel) * .85;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - .14 - travel * .14, y + .025),
        _stroke(_hot.withValues(alpha: alpha), .06 * (1 - travel) + .015),
      );
    }
  }

  // Authored planes share the same unit-space shell at every charge size.
  static final _shell = Path()
    ..moveTo(-.95, -.22)
    ..lineTo(-.78, -.59)
    ..quadraticBezierTo(-.74, -.66, -.65, -.7)
    ..lineTo(-.37, -.89)
    ..lineTo(.06, -.96)
    ..quadraticBezierTo(.13, -.97, .2, -.93)
    ..lineTo(.54, -.77)
    ..lineTo(.73, -.52)
    ..lineTo(.68, -.39)
    ..lineTo(.88, -.25)
    ..lineTo(.96, .13)
    ..lineTo(.79, .48)
    ..lineTo(.5, .75)
    ..lineTo(.13, .95)
    ..quadraticBezierTo(.07, .98, -.02, .94)
    ..lineTo(-.24, .86)
    ..lineTo(-.45, .69)
    ..lineTo(-.64, .68)
    ..lineTo(-.85, .39)
    ..lineTo(-.8, .18)
    ..lineTo(-.95, .04)
    ..close();

  static final _crown = Path()
    ..moveTo(-1, -.24)
    ..lineTo(-.8, -.8)
    ..lineTo(.05, -1.08)
    ..lineTo(.63, -.82)
    ..lineTo(.47, -.5)
    ..lineTo(.08, -.67)
    ..lineTo(-.29, -.56)
    ..lineTo(-.6, -.24)
    ..close();

  static final _leftPlane = Path()
    ..moveTo(-1.03, -.26)
    ..lineTo(-.6, -.24)
    ..lineTo(-.55, .09)
    ..lineTo(-.34, .35)
    ..lineTo(-.46, .73)
    ..lineTo(-.94, .5)
    ..close();

  static final _rightPlane = Path()
    ..moveTo(.47, -.5)
    ..lineTo(.64, -.88)
    ..lineTo(1.1, -.3)
    ..lineTo(1.1, .58)
    ..lineTo(.11, 1.06)
    ..lineTo(.08, .61)
    ..lineTo(.43, .33)
    ..lineTo(.58, -.03)
    ..close();

  static final _foot = Path()
    ..moveTo(-.86, .39)
    ..lineTo(-.34, .35)
    ..lineTo(-.14, .57)
    ..lineTo(.08, .61)
    ..lineTo(.79, .48)
    ..lineTo(.49, .93)
    ..lineTo(-.1, 1.12)
    ..lineTo(-.7, .79)
    ..close();

  static final _chip = Path()
    ..moveTo(-.9, -.35)
    ..lineTo(-.25, -.9)
    ..lineTo(.75, -.6)
    ..lineTo(.95, .25)
    ..lineTo(.1, .9)
    ..lineTo(-.65, .55)
    ..close();

  static final _fracture = Path()
    ..moveTo(.22, -.66)
    ..lineTo(.015, -.36)
    ..lineTo(.10, -.17)
    ..lineTo(-.15, .045)
    ..lineTo(-.01, .28)
    ..lineTo(-.16, .57)
    ..lineTo(-.14, .75)
    ..lineTo(-.075, .57)
    ..lineTo(.075, .29)
    ..lineTo(-.055, .06)
    ..lineTo(.175, -.16)
    ..lineTo(.075, -.37)
    ..close();

  static final _branches = Path()
    ..moveTo(-.12, .04)
    ..lineTo(-.37, -.06)
    ..lineTo(-.62, .10)
    ..lineTo(-.37, .015)
    ..lineTo(-.1, .105)
    ..close()
    ..moveTo(.045, .24)
    ..lineTo(.34, .14)
    ..lineTo(.63, .29)
    ..lineTo(.35, .215)
    ..lineTo(.015, .33)
    ..close();

  static void _body(Canvas canvas, double charge) {
    final energy = _energy(charge);
    if (energy > 0) _glow(canvas, Offset.zero, 1.62, energy * .35);
    canvas.save();
    canvas.clipPath(_shell);
    canvas.drawPath(
      _shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              const Color(0xffa8b9b5),
              const Color(0xffc0bba0),
              energy,
            )!,
            Color.lerp(
              const Color(0xff81918d),
              const Color(0xff9c9275),
              energy,
            )!,
            const Color(0xff52666b),
          ],
          stops: const [0, .52, 1],
        ).createShader(_bounds),
    );
    void plane(Path path, Color light, Color shadow) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [light, shadow],
          ).createShader(_bounds),
      );
    }

    plane(_crown, const Color(0xffe0e2cc), const Color(0xff9eafa6));
    plane(_leftPlane, const Color(0xffb1c0b3), const Color(0xff718986));
    plane(_rightPlane, const Color(0xff718582), const Color(0xff344f5b));
    plane(_foot, const Color(0xff70827c), const Color(0xff344e56));
    // Chisel marks follow the facets, giving the rock a bevel rather than a rim.
    canvas.drawPath(
      Path()
        ..moveTo(-.73, -.56)
        ..lineTo(-.34, -.8)
        ..lineTo(.08, -.87)
        ..lineTo(.37, -.74),
      _stroke(const Color(0xfffff6d9).withValues(alpha: .85), .045),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-.69, -.2)
        ..lineTo(-.63, .1)
        ..lineTo(-.43, .34)
        ..moveTo(.7, .39)
        ..lineTo(.4, .65)
        ..lineTo(.13, .79),
      _stroke(const Color(0xffaebdaf).withValues(alpha: .55), .035),
    );
    // Small inset scars have a dark lip and a light lower edge.
    for (final (x, y, size, angle) in [
      (-.31, -.29, .10, -.3),
      (.35, -.23, .065, .6),
      (-.28, .37, .055, .15),
    ]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.scale(size);
      canvas.drawPath(_chip, Paint()..color = _slate.withValues(alpha: .6));
      canvas.drawPath(
        Path()
          ..moveTo(-.6, .55)
          ..lineTo(.1, .9)
          ..lineTo(.85, .25),
        _stroke(const Color(0xffd6d8bd).withValues(alpha: .65), .24),
      );
      canvas.restore();
    }
    if (energy > 0) {
      _glow(canvas, const Offset(-.02, .08), 1.0, energy * .38);
    }
    for (final crack in [_fracture, _branches]) {
      canvas.drawPath(crack, _stroke(_slate.withValues(alpha: .8), .045));
      canvas.drawPath(crack, Paint()..color = const Color(0xff3c504f));
      if (energy > 0) {
        canvas.drawPath(
          crack,
          _stroke(_amber.withValues(alpha: energy * .3), .13),
        );
        canvas.drawPath(crack, _stroke(_amber.withValues(alpha: energy), .035));
        canvas.drawPath(crack, Paint()..color = _hot.withValues(alpha: energy));
      }
    }
    // Warm reflections on the front edge tie the lit core to the solid shell.
    if (energy > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(.78, -.16)
          ..lineTo(.83, .12)
          ..lineTo(.67, .4),
        _stroke(_amber.withValues(alpha: energy * .7), .06),
      );
    }
    canvas.restore();
    canvas.drawPath(_shell, _stroke(SkyColors.ink, .12 - charge * .03));
  }
}
