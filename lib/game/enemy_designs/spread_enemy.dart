import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';

/// A left-facing dusk moth whose three throat glands telegraph a fan volley.
/// The silhouette stays within x ±1.9r, y ±1.2r, including attack poses.
abstract final class SpreadEnemyArt {
  static void paint(
    Canvas c,
    double radius, {
    required double seconds,
    required bool reducedMotion,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = seconds.isFinite ? seconds : 0.0;
    final aim = _unit(lookY, -1, 1);
    final preparing = _unit(charge, 0, 1);
    final kick = _unit(recoil, 0, 1);
    final beat = reducedMotion ? .55 : .5 + .5 * math.sin(time * 16);
    final lift = .58 + beat * .34 + preparing * .16;
    final furSway = reducedMotion ? 0.0 : math.sin(time * 5.1) * .025;

    c.save();
    c.scale(radius);
    c.translate(kick * .1, 0);

    // Wings sweep back from the thorax. The far pair has a different beat
    // and silhouette, so this reads as a flying animal in profile.
    _farWings(c, lift, preparing);
    _feet(c, furSway);
    _abdomen(c);
    _nearWings(c, lift);
    _thorax(c, preparing);
    _antennae(c, furSway);
    _head(c, aim, preparing, kick);
    _glands(c, preparing, kick);
    c.restore();
  }

  static void _farWings(Canvas c, double lift, double charge) {
    final wing = Path()
      ..moveTo(-.28, -.12)
      ..cubicTo(-.48, -.45, -.32, -.75 * lift, .14, -1.02 * lift)
      ..cubicTo(.45, -1.09 * lift, .91, -.99 * lift, 1.05, -.76 * lift)
      ..quadraticBezierTo(.73, -.37, .45, -.11)
      ..quadraticBezierTo(.13, .08, -.28, -.12)
      ..close();
    c.drawPath(wing, _fill(_far));
    c.drawPath(wing, _stroke(_edge, .055));
    c.drawPath(
      Path()
        ..moveTo(-.18, -.2)
        ..quadraticBezierTo(.15, -.43 * lift, .75, -.83 * lift),
      _stroke(_dusty, .045),
    );
    final hind = Path()
      ..moveTo(-.1, .05)
      ..quadraticBezierTo(.24, .38, .7, .79 + charge * .13)
      ..quadraticBezierTo(.46, .92 + charge * .1, .21, .64)
      ..quadraticBezierTo(-.06, .73, -.25, .34)
      ..close();
    c.drawPath(hind, _fill(_far));
    c.drawPath(hind, _stroke(_edge, .05));
  }

  static void _feet(Canvas c, double sway) {
    final leg = _stroke(_edge, .065);
    c.drawPath(
      Path()
        ..moveTo(-.36, .21)
        ..lineTo(-.53, .6)
        ..lineTo(-.87, .65 + sway)
        ..lineTo(-.98, .6 + sway),
      leg,
    );
    c.drawPath(
      Path()
        ..moveTo(.07, .35)
        ..lineTo(.21, .73)
        ..lineTo(-.11, .87 + sway),
      leg,
    );
  }

  static void _abdomen(Canvas c) {
    final shape = Path()
      ..moveTo(-.27, -.39)
      ..cubicTo(.3, -.5, 1.0, -.15, 1.48, .15)
      ..lineTo(1.32, .28)
      ..lineTo(1.36, .35)
      ..cubicTo(.9, .59, .32, .66, -.18, .38)
      ..quadraticBezierTo(-.49, .04, -.27, -.39)
      ..close();
    c.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_furLight, _fur, _far],
          stops: [0, .53, 1],
        ).createShader(const Rect.fromLTRB(-.45, -.5, 1.5, .63)),
    );
    c.save();
    c.clipPath(shape);
    for (var i = 0; i < 4; i++) {
      final x = .29 + .26 * i;
      c.drawPath(
        Path()
          ..moveTo(x, -.43)
          ..quadraticBezierTo(x + .23, -.03, x + .01, .61),
        _stroke(_far.withValues(alpha: .66), .065),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(.11, -.2)
        ..quadraticBezierTo(.53, -.1, 1.06, .09),
      _stroke(_furLight.withValues(alpha: .7), .07),
    );
    c.restore();
    c.drawPath(shape, _stroke(_edge, .06));
  }

  static void _nearWings(Canvas c, double lift) {
    final spread = .67 + lift * .33;
    final hind = Path()
      ..moveTo(-.13, .02)
      ..cubicTo(.29, .23, .93, .51 * spread, 1.31, .83 * spread)
      ..quadraticBezierTo(1.31, 1.03 * spread, 1.05, .98 * spread)
      ..quadraticBezierTo(.84, 1.17 * spread, .66, .93 * spread)
      ..quadraticBezierTo(.37, 1.06 * spread, .27, .77 * spread)
      ..quadraticBezierTo(-.11, .51, -.13, .02)
      ..close();
    c.drawPath(
      hind,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_coral, _dusty, _far],
        ).createShader(const Rect.fromLTRB(0, 0, 1.35, 1.16)),
    );
    c.drawPath(hind, _stroke(_edge, .055));
    c.drawPath(
      Path()
        ..moveTo(.19, .36)
        ..quadraticBezierTo(.68, .67 * spread, 1.18, .85 * spread),
      _stroke(_furLight.withValues(alpha: .68), .065),
    );

    final upper = -1.04 * lift;
    final wing = Path()
      ..moveTo(-.2, -.12)
      ..cubicTo(.02, -.53 * lift, .72, upper - .07, 1.46, upper + .06)
      ..quadraticBezierTo(1.72, upper + .16, 1.66, upper + .35)
      ..quadraticBezierTo(1.6, -.29 * lift, 1.37, -.18 * lift)
      ..quadraticBezierTo(1.3, .01, 1.06, -.025)
      ..quadraticBezierTo(.83, .2, .64, .03)
      ..quadraticBezierTo(.31, .19, -.2, -.12)
      ..close();
    c.drawPath(
      wing,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_wingLight, _coral, _dusty],
          stops: [0, .53, 1],
        ).createShader(Rect.fromLTRB(-.2, upper, 1.7, .2)),
    );
    c.save();
    c.clipPath(wing);
    // Broad natural wing bands stay visible at the normal 16 px radius.
    c.drawPath(
      Path()
        ..moveTo(.81, upper - .1)
        ..quadraticBezierTo(.93, -.45 * lift, 1.1, .13),
      _stroke(_far.withValues(alpha: .57), .23),
    );
    c.drawPath(
      Path()
        ..moveTo(1.32, upper - .05)
        ..quadraticBezierTo(1.45, -.48 * lift, 1.47, .01),
      _stroke(_furLight.withValues(alpha: .76), .11),
    );
    final eyespot = Offset(.69, -.42 * lift);
    c.drawOval(
      Rect.fromCenter(center: eyespot, width: .35, height: .25 * lift),
      _fill(_furLight),
    );
    c.drawOval(
      Rect.fromCenter(center: eyespot, width: .18, height: .15 * lift),
      _fill(_far),
    );
    final veins = _stroke(_far.withValues(alpha: .45), .032);
    for (final end in [
      Offset(1.48, upper + .14),
      Offset(1.44, -.25 * lift),
      const Offset(.92, .06),
    ]) {
      c.drawLine(const Offset(-.07, -.14), end, veins);
    }
    c.restore();
    c.drawPath(wing, _stroke(_edge, .06));
    c.drawPath(
      Path()
        ..moveTo(-.13, -.16)
        ..quadraticBezierTo(.54, upper - .06, 1.45, upper + .07),
      _stroke(_furLight.withValues(alpha: .8), .055),
    );
  }

  static void _thorax(Canvas c, double charge) {
    final shape = Path()
      ..moveTo(-.66, -.39)
      ..lineTo(-.42, -.53)
      ..lineTo(-.38, -.43)
      ..lineTo(-.15, -.48)
      ..lineTo(-.17, -.34)
      ..quadraticBezierTo(.16, -.26, .21, .09)
      ..lineTo(.33, .2)
      ..lineTo(.15, .24)
      ..lineTo(.18, .39)
      ..lineTo(-.04, .36)
      ..lineTo(-.14, .49 + .025 * charge)
      ..lineTo(-.24, .4)
      ..lineTo(-.46, .48)
      ..lineTo(-.47, .36)
      ..quadraticBezierTo(-.76, .23, -.66, -.39)
      ..close();
    c.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_furLight, _fur, _dusty],
        ).createShader(const Rect.fromLTRB(-.7, -.53, .3, .5)),
    );
    c.drawPath(shape, _stroke(_edge, .055));
    final fur = _stroke(_furLight.withValues(alpha: .64), .04);
    c.drawLine(const Offset(-.31, -.27), const Offset(-.13, -.17), fur);
    c.drawLine(const Offset(-.2, -.02), const Offset(-.05, .07), fur);
    c.drawLine(const Offset(-.31, .17), const Offset(-.2, .31), fur);
  }

  static void _antennae(Canvas c, double sway) {
    final near = Path()
      ..moveTo(-.685, -.51)
      ..quadraticBezierTo(-1.2, -.57, -1.53, -.83 + sway);
    final far = Path()
      ..moveTo(-.485, -.6)
      ..quadraticBezierTo(-.71, -.72, -1.02, -1.04 - sway);
    c.drawPath(far, _stroke(_far, .052));
    c.drawPath(near, _stroke(_edge, .055));
    for (var i = 0; i < 4; i++) {
      final f = i / 3;
      final x = -1.08 - f * .36;
      final y = -.47 - f * .31 + sway * f;
      c.drawLine(
        Offset(x, y),
        Offset(x - .13, y + .045),
        _stroke(_furLight, .05),
      );
      c.drawLine(Offset(x, y), Offset(x + .035, y - .14), _stroke(_dusty, .05));
    }
  }

  static void _head(Canvas c, double aim, double charge, double kick) {
    c.save();
    // Keep the head compact above the shared gameplay muzzle (-1.05r, 0).
    c.translate(.185, -.24);
    final head = Path()
      ..moveTo(-.54, -.38)
      ..quadraticBezierTo(-.89, -.54, -1.12, -.26)
      ..quadraticBezierTo(-1.26, -.09, -1.18, .14)
      ..lineTo(-1.235, .24)
      ..quadraticBezierTo(-1.13, .45, -.87, .37)
      ..quadraticBezierTo(-.47, .29, -.54, -.38)
      ..close();
    c.drawPath(
      head,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_furLight, _fur],
        ).createShader(const Rect.fromLTRB(-1.3, -.49, -.5, .4)),
    );
    c.drawPath(head, _stroke(_edge, .06));

    // A single forward-set eye makes the direction unambiguous. The tiny
    // rim and pupil are intentionally large enough for normal gameplay.
    final eyeAt = Offset(-1.055, -.115 + aim * .025);
    c.drawOval(
      Rect.fromCenter(center: eyeAt, width: .29, height: .34),
      _fill(_edge),
    );
    c.drawOval(
      Rect.fromCenter(
        center: eyeAt + const Offset(-.023, -.005),
        width: .17,
        height: .235,
      ),
      _fill(SkyColors.cream),
    );
    final pupil = eyeAt + Offset(-.065, aim * .055);
    c.drawOval(
      Rect.fromCenter(center: pupil, width: .098, height: .155),
      _fill(_edge),
    );
    c.drawCircle(pupil + const Offset(-.012, -.042), .028, _fill(_wingLight));

    final opening = .045 + charge * .11 + kick * .035;
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-1.235, .24),
        width: .12,
        height: opening * 2,
      ),
      _fill(_edge),
    );
    // A small resting curl retracts into the short tube as it charges.
    // Its charged tip coincides with the opening and projectile origin.
    final curl = 1 - charge;
    c.drawPath(
      Path()
        ..moveTo(-1.12, .27)
        ..quadraticBezierTo(-1.37, .25 + curl * .26, -1.16, .24 + curl * .28)
        ..quadraticBezierTo(
          -1.05 - charge * .16,
          .24 + curl * .2,
          -1.235 + curl * .12,
          .24 + curl * .1,
        ),
      _stroke(_edge, .06),
    );
    c.restore();
  }

  static void _glands(Canvas c, double charge, double recoil) {
    const centers = [Offset(-.67, .05), Offset(-.53, .18), Offset(-.73, .24)];
    for (var i = 0; i < centers.length; i++) {
      final amount = ((charge - i * .13) / .74).clamp(0.0, 1.0);
      final at = centers[i];
      final radius = .105 + amount * .025;
      if (amount > 0) {
        c.drawCircle(
          at,
          radius * (1.7 + amount * .4),
          Paint()
            ..shader = RadialGradient(
              colors: [
                SkyColors.yellow.withValues(alpha: .28 * amount),
                SkyColors.yellow.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: at, radius: radius * 2.1)),
        );
      }
      c.drawOval(
        Rect.fromCenter(center: at, width: radius * 1.7, height: radius * 2.15),
        _fill(Color.lerp(_dusty, SkyColors.yellow, .28 + amount * .72)!),
      );
      c.drawOval(
        Rect.fromCenter(center: at, width: radius * 1.7, height: radius * 2.15),
        _stroke(_edge, .035),
      );
      c.drawCircle(
        at + const Offset(-.023, -.034),
        .035 + amount * .012,
        _fill(SkyColors.cream.withValues(alpha: .55 + amount * .45)),
      );
    }
    if (recoil > .05) {
      final flash = Paint()..color = SkyColors.cream.withValues(alpha: recoil);
      for (final dy in [-.15, 0.0, .15]) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(-1.14, dy),
            width: .12 + recoil * .14,
            height: .07,
          ),
          flash,
        );
      }
    }
  }

  static const _edge = Color(0xff4b343d);
  static const _far = Color(0xff8a505b);
  static const _dusty = Color(0xffb46562);
  static const _coral = Color(0xffd88671);
  static const _wingLight = Color(0xfff3b899);
  static const _fur = Color(0xffc98e7b);
  static const _furLight = Color(0xfff0c7a4);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static double _unit(double value, double low, double high) =>
      value.isFinite ? value.clamp(low, high) : 0;
}
