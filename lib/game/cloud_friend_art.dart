import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/cloud_friends.dart';
import '../ui/theme.dart';

/// Shared vector art for the sky, the discovery strip and the flight album.
abstract final class CloudFriendArt {
  static final _bodies = <CloudFriend, Path>{
    CloudFriend.whale: Path()
      ..moveTo(88, 42)
      ..cubicTo(96, 42, 99, 34, 102, 30)
      ..quadraticBezierTo(114, 41, 100, 51)
      ..cubicTo(88, 70, 61, 75, 35, 66)
      ..cubicTo(15, 66, 7, 54, 13, 42)
      ..cubicTo(11, 30, 22, 21, 35, 25)
      ..cubicTo(44, 10, 64, 14, 69, 27)
      ..cubicTo(80, 26, 87, 32, 88, 42)
      ..close(),
    CloudFriend.bunny: Path()
      ..moveTo(27, 43)
      ..cubicTo(14, 29, 20, 7, 29, 9)
      ..cubicTo(36, 10, 38, 25, 38, 34)
      ..cubicTo(40, 17, 48, 2, 55, 7)
      ..cubicTo(63, 13, 56, 29, 51, 36)
      ..cubicTo(63, 25, 76, 31, 79, 42)
      ..cubicTo(92, 36, 107, 43, 100, 55)
      ..cubicTo(100, 69, 82, 73, 73, 68)
      ..cubicTo(56, 76, 33, 72, 28, 64)
      ..cubicTo(13, 65, 11, 49, 27, 43)
      ..close(),
    CloudFriend.turtle: Path()
      ..moveTo(19, 48)
      ..cubicTo(13, 36, 23, 24, 35, 26)
      ..cubicTo(41, 10, 59, 12, 65, 26)
      ..cubicTo(77, 24, 84, 34, 82, 45)
      ..cubicTo(90, 28, 111, 35, 106, 49)
      ..quadraticBezierTo(105, 60, 89, 59)
      ..cubicTo(91, 74, 76, 74, 73, 64)
      ..quadraticBezierTo(54, 70, 37, 63)
      ..cubicTo(29, 79, 14, 70, 22, 59)
      ..quadraticBezierTo(4, 61, 7, 53)
      ..quadraticBezierTo(9, 50, 19, 48)
      ..close(),
  };

  static Color accent(CloudFriend friend) => switch (friend) {
    CloudFriend.whale => SkyColors.skyDeep,
    CloudFriend.bunny => SkyColors.coral,
    CloudFriend.turtle => SkyColors.mint,
  };

  static void paint(
    Canvas canvas,
    Rect bounds,
    CloudFriend friend, {
    bool discovered = true,
  }) {
    canvas.save();
    final scale = math.min(bounds.width / 112, bounds.height / 80);
    canvas.translate(
      bounds.center.dx - 56 * scale,
      bounds.center.dy - 40 * scale,
    );
    canvas.scale(scale);
    final shape = _bodies[friend]!;
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(
      shape,
      Paint()..color = SkyColors.teal.withValues(alpha: .14),
    );
    canvas.restore();
    canvas.drawPath(
      shape,
      Paint()..color = discovered ? SkyColors.white : SkyColors.sky,
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = discovered
            ? accent(friend).withValues(alpha: .8)
            : SkyColors.skyDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    if (!discovered) {
      canvas.restore();
      return;
    }
    final detail = Paint()
      ..color = accent(friend)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    switch (friend) {
      case CloudFriend.whale:
        canvas.drawPath(
          Path()
            ..moveTo(40, 17)
            ..quadraticBezierTo(39, 8, 32, 8)
            ..moveTo(42, 16)
            ..quadraticBezierTo(47, 5, 54, 9),
          detail,
        );
        canvas.drawPath(
          Path()
            ..moveTo(58, 54)
            ..quadraticBezierTo(64, 64, 70, 53),
          detail,
        );
      case CloudFriend.bunny:
        canvas.drawLine(const Offset(28, 17), const Offset(32, 33), detail);
        canvas.drawLine(const Offset(51, 16), const Offset(46, 31), detail);
      case CloudFriend.turtle:
        canvas.drawPath(
          Path()
            ..moveTo(34, 49)
            ..quadraticBezierTo(45, 34, 61, 47)
            ..moveTo(49, 39)
            ..lineTo(49, 31),
          detail,
        );
    }
    final face = switch (friend) {
      CloudFriend.whale => const Offset(29, 46),
      CloudFriend.bunny => const Offset(37, 50),
      CloudFriend.turtle => const Offset(96, 47),
    };
    final ink = Paint()
      ..color = SkyColors.ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: face, width: 8, height: 6),
      0,
      math.pi,
      false,
      ink,
    );
    canvas.drawOval(
      Rect.fromCenter(center: face + const Offset(-6, 6), width: 7, height: 4),
      Paint()..color = SkyColors.coral.withValues(alpha: .45),
    );
    canvas.restore();
  }

  static void inSky(
    Canvas canvas, {
    required Offset center,
    required double height,
    required CloudFriend friend,
    required bool known,
    required double seconds,
    required bool reducedMotion,
  }) {
    final wave = reducedMotion ? 0.0 : math.sin(seconds * 1.6 + friend.index);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: height * (.40 + wave * .008),
        height: height * (.29 + wave * .006),
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .13),
    );
    paint(
      canvas,
      Rect.fromCenter(
        center: center + Offset(0, wave * height * .004),
        width: height * .34,
        height: height * .243,
      ),
      friend,
    );
    if (known) {
      final at = center + Offset(height * .12, height * .09);
      canvas.drawCircle(at, height * .018, Paint()..color = SkyColors.mint);
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - height * .008, at.dy)
          ..lineTo(at.dx - height * .002, at.dy + height * .005)
          ..lineTo(at.dx + height * .009, at.dy - height * .006),
        Paint()
          ..color = SkyColors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
