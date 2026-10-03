import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/tracking.dart';
import '../game/bird_puppet.dart';
import '../game/tether_art.dart';
import 'theme.dart';

/// Small, original game illustrations: each pose shows its actual control.
class ModePickerArt extends CustomPainter {
  const ModePickerArt({required this.mode, required this.color});

  /// The control shown; null shows Fly Together, two birds roped together.
  final PlayMode? mode;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, SkyColors.cream, .4)!, color],
        ).createShader(rect),
    );
    canvas.save();
    final scale = math.min(size.width / 180, size.height / 140);
    canvas.translate((size.width - 180 * scale) / 2, size.height - 140 * scale);
    canvas.scale(scale);
    canvas.drawCircle(
      const Offset(97, 83),
      62,
      Paint()..color = SkyColors.cream.withValues(alpha: .23),
    );
    canvas.drawCircle(
      const Offset(97, 83),
      45,
      Paint()..color = SkyColors.cream.withValues(alpha: .25),
    );
    for (final (x, y, r) in [
      (24.0, 73.0, 4.0),
      (154.0, 43.0, 5.0),
      (156.0, 104.0, 3.0),
    ]) {
      _spark(canvas, Offset(x, y), r);
    }
    switch (mode) {
      case null:
        _together(canvas);
      case PlayMode.touch:
        _touch(canvas);
      case _:
        _movement(canvas);
    }
    canvas.restore();
    // The illustration flows into the paper face of the card.
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - 6)
        ..quadraticBezierTo(
          size.width * .25,
          size.height - 15,
          size.width * .52,
          size.height - 5,
        )
        ..quadraticBezierTo(
          size.width * .8,
          size.height + 3,
          size.width,
          size.height - 8,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = SkyColors.cream,
    );
  }

  void _spark(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = i.isEven ? radius : radius * .3;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path..close(), Paint()..color = SkyColors.cream);
  }

  void _limb(Canvas canvas, List<Offset> points, Color color, double width) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      path,
      pen
        ..color = SkyColors.ink
        ..strokeWidth = width + 4,
    );
    canvas.drawPath(
      path,
      pen
        ..color = color
        ..strokeWidth = width,
    );
  }

  void _shape(Canvas canvas, Path path, Color fill, {double outline = 2.2}) {
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _detail(Canvas canvas, Path path, Color color, {double width = 1.4}) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _head(
    Canvas canvas,
    Offset center, {
    required Color skin,
    double tilt = 0,
    bool facingLeft = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    if (facingLeft) canvas.scale(-1, 1);
    final hair = mode == PlayMode.pushUp
        ? const Color(0xff6a4638)
        : mode == PlayMode.jump
        ? const Color(0xff513d37)
        : const Color(0xff334a54);

    // Round silhouettes and a clear hairline keep the faces readable on phones.
    if (mode == PlayMode.squat) {
      _shape(
        canvas,
        Path()
          ..moveTo(-12, -13)
          ..cubicTo(-27, -19, -31, -4, -26, 4)
          ..quadraticBezierTo(-21, 13, -27, 15)
          ..cubicTo(-12, 18, -10, 1, -14, -5)
          ..close(),
        hair,
      );
      _detail(
        canvas,
        Path()
          ..moveTo(-21, -9)
          ..quadraticBezierTo(-25, -2, -20, 5),
        const Color(0xff637881),
        width: 1.8,
      );
    }
    _shape(
      canvas,
      Path()
        ..moveTo(-13, -7)
        ..cubicTo(-13, -20, 13, -21, 14, -6)
        ..quadraticBezierTo(14, -1, 16, 2)
        ..quadraticBezierTo(18, 5, 13, 6)
        ..cubicTo(11, 18, -3, 19, -10, 10)
        ..quadraticBezierTo(-16, 5, -13, -7)
        ..close(),
      skin,
    );

    final hairline = Path();
    if (mode == PlayMode.pushUp) {
      hairline
        ..moveTo(-13, 3)
        ..cubicTo(-21, -6, -16, -21, -6, -20)
        ..quadraticBezierTo(0, -27, 7, -22)
        ..cubicTo(18, -25, 22, -13, 14, -6)
        ..quadraticBezierTo(10, -7, 8, -12)
        ..quadraticBezierTo(2, -4, -7, -6)
        ..lineTo(-9, 3)
        ..close();
    } else if (mode == PlayMode.jump) {
      hairline
        ..moveTo(-13, 3)
        ..cubicTo(-21, 0, -22, -9, -16, -13)
        ..cubicTo(-21, -20, -12, -27, -6, -23)
        ..cubicTo(-1, -29, 8, -27, 11, -22)
        ..cubicTo(20, -25, 24, -14, 17, -10)
        ..quadraticBezierTo(18, -5, 12, -4)
        ..lineTo(9, -10)
        ..quadraticBezierTo(2, -5, -7, -8)
        ..lineTo(-9, 2)
        ..close();
    } else {
      hairline
        ..moveTo(-13, 3)
        ..cubicTo(-22, -8, -14, -23, 1, -22)
        ..cubicTo(15, -24, 21, -14, 14, -5)
        ..quadraticBezierTo(8, -7, 6, -13)
        ..quadraticBezierTo(1, -6, -8, -5)
        ..lineTo(-9, 3)
        ..close();
    }
    _shape(canvas, hairline, hair);
    _detail(
      canvas,
      mode == PlayMode.jump
          ? (Path()
              ..moveTo(-13, -15)
              ..cubicTo(-13, -21, -5, -21, -5, -16)
              ..moveTo(1, -19)
              ..quadraticBezierTo(7, -23, 11, -17))
          : (Path()
              ..moveTo(-11, -13)
              ..quadraticBezierTo(-5, -19, 5, -18)),
      Color.lerp(hair, SkyColors.cream, .25)!,
      width: 2,
    );
    if (mode == PlayMode.squat) {
      _detail(
        canvas,
        Path()
          ..moveTo(-17, -12)
          ..lineTo(-15, -7),
        SkyColors.coral,
        width: 3,
      );
    }

    // The ear overlaps the hair, so the head feels connected rather than pasted on.
    _shape(
      canvas,
      Path()
        ..moveTo(-10, 1)
        ..cubicTo(-17, -4, -19, 7, -12, 9)
        ..quadraticBezierTo(-9, 9, -9, 6),
      skin,
      outline: 1.8,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(-13, 3)
        ..quadraticBezierTo(-16, 2, -14, 6),
      Color.lerp(skin, hair, .4)!,
      width: 1.2,
    );
    final blush = Paint()..color = SkyColors.coral.withValues(alpha: .4);
    canvas.drawOval(const Rect.fromLTWH(-6, 5, 6, 3.5), blush);
    canvas.drawOval(const Rect.fromLTWH(9, 5, 4, 3), blush);
    for (final eye in [const Offset(-2, 1.5), const Offset(9, 1)]) {
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: 3.1, height: 4),
        Paint()..color = SkyColors.ink,
      );
      canvas.drawCircle(
        eye + const Offset(.45, -.8),
        .55,
        Paint()..color = SkyColors.cream,
      );
    }
    _detail(
      canvas,
      Path()
        ..moveTo(-4, -3)
        ..quadraticBezierTo(-2, -4.5, 0, -3.5)
        ..moveTo(7, -4)
        ..quadraticBezierTo(9, -5, 10.5, -3.5),
      hair,
      width: 1.5,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(4, 2)
        ..lineTo(5, 5)
        ..lineTo(3.5, 5.5),
      Color.lerp(skin, hair, .4)!,
      width: 1.2,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(0, 8.5)
        ..quadraticBezierTo(4.5, 10.5, 9, 7.8)
        ..quadraticBezierTo(7, 15, 2, 12)
        ..quadraticBezierTo(.5, 11, 0, 8.5)
        ..close(),
      SkyColors.cream,
      outline: 1.2,
    );
    canvas.restore();
  }

  void _shirt(Canvas canvas, Offset shoulder, Offset hip, Color color) {
    final length = (hip - shoulder).distance;
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(
      math.atan2(hip.dy - shoulder.dy, hip.dx - shoulder.dx) - math.pi / 2,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(-7, -3)
        ..quadraticBezierTo(-12, -3, -15, 3)
        ..lineTo(-17, 9)
        ..lineTo(-10, 12)
        ..lineTo(-9, length + 2)
        ..quadraticBezierTo(0, length + 6, 10, length + 2)
        ..lineTo(11, 12)
        ..lineTo(17, 9)
        ..lineTo(14, 2)
        ..quadraticBezierTo(11, -3, 7, -3)
        ..quadraticBezierTo(0, 0, -7, -3)
        ..close(),
      color,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(-6, -1)
        ..quadraticBezierTo(0, 5, 6, -1),
      Color.lerp(color, SkyColors.ink, .25)!,
      width: 2,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(-6, length)
        ..quadraticBezierTo(0, length + 3, 7, length),
      Color.lerp(color, SkyColors.ink, .18)!,
      width: 1.5,
    );
    // A simple wing patch ties the runners to the game's bird.
    canvas.drawPath(
      Path()
        ..moveTo(-1, 9)
        ..quadraticBezierTo(4, 5, 8, 7)
        ..quadraticBezierTo(5, 8, 4, 11)
        ..lineTo(1, 11)
        ..close(),
      Paint()..color = SkyColors.cream.withValues(alpha: .9),
    );
    canvas.restore();
  }

  void _pushUpShirt(Canvas canvas, Color color) {
    // In profile, the sleeve follows the planted arm and the body hugs the
    // diagonal torso. The neck and both arms are painted beneath this contour.
    _shape(
      canvas,
      Path()
        ..moveTo(71, 73)
        ..quadraticBezierTo(77, 73, 85, 76)
        ..lineTo(116, 86)
        ..quadraticBezierTo(117, 87, 116, 90)
        ..lineTo(113, 99)
        ..quadraticBezierTo(112, 102, 109, 101)
        ..lineTo(83, 93)
        ..lineTo(81, 95)
        ..quadraticBezierTo(73, 96, 67, 92)
        ..lineTo(65, 84)
        ..quadraticBezierTo(64, 81, 66, 78)
        ..quadraticBezierTo(70, 79, 71, 73)
        ..close(),
      color,
    );
    final seam = Color.lerp(color, SkyColors.ink, .25)!;
    // A curved armhole and cuff make the visible sleeve wrap the upper arm.
    _detail(
      canvas,
      Path()
        ..moveTo(77, 79)
        ..quadraticBezierTo(81, 84, 80, 90)
        ..moveTo(67, 90)
        ..quadraticBezierTo(73, 94, 81, 93),
      seam,
      width: 1.5,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(73, 74)
        ..quadraticBezierTo(73, 81, 66, 81),
      seam,
      width: 1.8,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(113, 87)
        ..lineTo(109, 99)
        ..moveTo(86, 90)
        ..quadraticBezierTo(91, 93, 98, 94),
      Color.lerp(color, SkyColors.ink, .18)!,
      width: 1.3,
    );
    canvas.drawPath(
      Path()
        ..moveTo(87, 83)
        ..quadraticBezierTo(92, 80, 98, 84)
        ..quadraticBezierTo(94, 83, 92, 87)
        ..lineTo(88, 86)
        ..close(),
      Paint()..color = SkyColors.cream.withValues(alpha: .9),
    );
  }

  void _shoe(
    Canvas canvas,
    Offset ankle,
    Color accent, {
    double angle = 0,
    bool facingLeft = false,
  }) {
    canvas.save();
    canvas.translate(ankle.dx, ankle.dy);
    canvas.rotate(angle);
    if (facingLeft) canvas.scale(-1, 1);
    _shape(
      canvas,
      Path()
        ..moveTo(-6, -5)
        ..quadraticBezierTo(-1, -3, 3, -4)
        ..lineTo(7, -1)
        ..quadraticBezierTo(13, 0, 12, 4)
        ..quadraticBezierTo(11, 6, 7, 6)
        ..lineTo(-6, 6)
        ..quadraticBezierTo(-9, 3, -6, -5)
        ..close(),
      SkyColors.cream,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(-5, 0)
        ..lineTo(0, 1)
        ..lineTo(3, -1),
      accent,
      width: 2.5,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(-6, 3.5)
        ..lineTo(10, 3.5),
      SkyColors.ink.withValues(alpha: .4),
      width: 1,
    );
    canvas.restore();
  }

  void _movement(Canvas canvas) {
    final skin = mode == PlayMode.pushUp
        ? const Color(0xffffd4a0)
        : mode == PlayMode.jump
        ? const Color(0xffdca77e)
        : const Color(0xffefbc91);
    const trousers = Color(0xff385460);
    final shirt = mode == PlayMode.pushUp
        ? SkyColors.coral
        : mode == PlayMode.jump
        ? SkyColors.yellow
        : SkyColors.mint;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(95, 126),
        width: mode == PlayMode.pushUp ? 134 : 83,
        height: 9,
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .12),
    );
    if (mode == PlayMode.pushUp) {
      // Side-on plank, planted hands, with an upward cue.
      _limb(
        canvas,
        [const Offset(112, 94), const Offset(139, 102), const Offset(159, 121)],
        trousers,
        11,
      );
      _limb(
        canvas,
        [const Offset(79, 85), const Offset(86, 102), const Offset(82, 120)],
        Color.lerp(skin, SkyColors.sand, .35)!,
        6,
      );
      _limb(canvas, [const Offset(80, 122), const Offset(90, 122)], skin, 5);
      _limb(canvas, [const Offset(61, 75), const Offset(76, 81)], skin, 9);
      _limb(
        canvas,
        [const Offset(73, 84), const Offset(73, 101), const Offset(67, 119)],
        skin,
        8,
      );
      _pushUpShirt(canvas, shirt);
      _shape(
        canvas,
        Path()
          ..moveTo(65, 116)
          ..quadraticBezierTo(61, 117, 61, 121)
          ..quadraticBezierTo(61, 124, 66, 124)
          ..lineTo(79, 124)
          ..quadraticBezierTo(82, 122, 78, 120)
          ..lineTo(70, 118)
          ..close(),
        skin,
      );
      _shoe(canvas, const Offset(158, 120), shirt);
      _head(
        canvas,
        const Offset(49, 69),
        skin: skin,
        tilt: -.25,
        facingLeft: true,
      );
      _arrow(canvas, const Offset(106, 66), const Offset(106, 39));
    } else if (mode == PlayMode.jump) {
      // A tuck in midair, with both feet clear of the ground.
      _limb(
        canvas,
        [const Offset(92, 94), const Offset(73, 107), const Offset(58, 98)],
        trousers,
        9,
      );
      _limb(
        canvas,
        [const Offset(101, 94), const Offset(115, 109), const Offset(128, 104)],
        trousers,
        9,
      );
      _shoe(
        canvas,
        const Offset(57, 98),
        SkyColors.teal,
        angle: .5,
        facingLeft: true,
      );
      _shoe(canvas, const Offset(129, 104), SkyColors.teal, angle: -.2);
      _limb(
        canvas,
        [const Offset(87, 74), const Offset(70, 65), const Offset(64, 48)],
        skin,
        7,
      );
      _limb(
        canvas,
        [const Offset(108, 74), const Offset(125, 61), const Offset(132, 43)],
        skin,
        7,
      );
      _limb(canvas, [const Offset(98, 61), const Offset(97, 72)], skin, 9);
      _shirt(canvas, const Offset(97, 72), const Offset(97, 89), shirt);
      _head(canvas, const Offset(99, 47), skin: skin, tilt: -.08);
      _arrow(canvas, const Offset(143, 91), const Offset(143, 62));
      _limb(
        canvas,
        [const Offset(82, 124), const Offset(84, 117)],
        SkyColors.cream,
        2,
      );
      _limb(
        canvas,
        [const Offset(102, 126), const Offset(101, 118)],
        SkyColors.cream,
        2,
      );
    } else {
      // A deep bend with both shoes visibly grounded.
      _limb(
        canvas,
        [const Offset(103, 96), const Offset(80, 105), const Offset(88, 122)],
        trousers,
        10,
      );
      _limb(
        canvas,
        [const Offset(107, 96), const Offset(130, 103), const Offset(120, 122)],
        trousers,
        10,
      );
      _shoe(canvas, const Offset(88, 120), SkyColors.coral, facingLeft: true);
      _shoe(canvas, const Offset(121, 120), SkyColors.coral);
      _limb(
        canvas,
        [const Offset(99, 82), const Offset(85, 91), const Offset(70, 85)],
        Color.lerp(skin, SkyColors.sand, .35)!,
        6,
      );
      _limb(
        canvas,
        [const Offset(90, 82), const Offset(78, 95), const Offset(61, 88)],
        skin,
        7,
      );
      _limb(canvas, [const Offset(89, 69), const Offset(96, 79)], skin, 9);
      _shirt(canvas, const Offset(95, 79), const Offset(106, 94), shirt);
      _head(
        canvas,
        const Offset(85, 56),
        skin: skin,
        tilt: -.12,
        facingLeft: true,
      );
      _arrow(canvas, const Offset(145, 56), const Offset(145, 84));
    }
  }

  void _arrow(Canvas canvas, Offset from, Offset to) {
    final direction = (to - from).dy.sign;
    final pen = Paint()
      ..color = SkyColors.ink.withValues(alpha: .48)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy)
        ..moveTo(to.dx - 5, to.dy - 6 * direction)
        ..lineTo(to.dx, to.dy)
        ..lineTo(to.dx + 5, to.dy - 6 * direction),
      pen,
    );
  }

  void _touch(Canvas canvas) {
    canvas.save();
    canvas.translate(88, 79);
    canvas.rotate(-.13);
    final phone = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-31, -48, 62, 100),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      phone.shift(const Offset(3, 4)),
      Paint()..color = SkyColors.ink.withValues(alpha: .15),
    );
    canvas.drawRRect(phone, Paint()..color = SkyColors.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -43, 52, 90),
        const Radius.circular(8),
      ),
      Paint()..color = SkyColors.sky,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -43, 22, 5),
        const Radius.circular(3),
      ),
      Paint()..color = SkyColors.ink,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-23, 30, 46, 11),
      Paint()..color = SkyColors.cream,
    );
    BirdPuppet.paint(
      canvas,
      const Rect.fromLTWH(-25, -25, 51, 45),
      bird: 0,
      wing: -.25,
    );
    canvas.drawCircle(
      const Offset(9, 22),
      12,
      Paint()..color = SkyColors.cream.withValues(alpha: .7),
    );
    canvas.drawCircle(
      const Offset(9, 22),
      16,
      Paint()
        ..color = SkyColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
    // A rounded glove makes the touch gesture readable at game-menu size.
    final hand = Path()
      ..moveTo(105, 122)
      ..lineTo(87, 103)
      ..quadraticBezierTo(81, 94, 89, 93)
      ..lineTo(100, 101)
      ..lineTo(95, 80)
      ..quadraticBezierTo(95, 73, 101, 77)
      ..lineTo(110, 94)
      ..quadraticBezierTo(119, 90, 124, 98)
      ..quadraticBezierTo(137, 106, 126, 122)
      ..close();
    canvas.drawPath(hand, Paint()..color = SkyColors.cream);
    canvas.drawPath(
      hand,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    _limb(
      canvas,
      [const Offset(106, 125), const Offset(122, 125)],
      SkyColors.coral,
      7,
    );
  }

  /// Two birds on one rope, each under its player's tag, as Fly Together
  /// draws them in flight.
  void _together(Canvas canvas) {
    const a = Offset(54, 94), b = Offset(134, 62);
    // The flight's own rope, at a scale where it hangs in a soft curve.
    const h = 340.0;
    TetherArt.between(
      canvas,
      h,
      a / h + TetherArt.tie,
      b / h + TetherArt.tie,
      seconds: 0,
      reducedMotion: true,
    );
    for (final (i, center) in [a, b].indexed) {
      BirdPuppet.paint(
        canvas,
        Rect.fromCenter(center: center, width: 84, height: 74),
        bird: i == 0 ? 1 : 2,
        wing: i == 0 ? -.35 : .2,
      );
      _tag(canvas, center + const Offset(0, -46), i);
    }
  }

  /// A player's tag: "P1" or "P2" on a sticker in the player's colour.
  void _tag(Canvas canvas, Offset center, int player) {
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 30, height: 17),
      const Radius.circular(8.5),
    );
    canvas.drawRRect(
      pill.shift(const Offset(0, 1.5)),
      Paint()..color = SkyColors.ink.withValues(alpha: .2),
    );
    canvas.drawRRect(pill, Paint()..color = TetherArt.players[player]);
    canvas.drawRRect(
      pill,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final text = TextPainter(
      text: TextSpan(
        text: 'P${player + 1}',
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          height: 1,
          color: SkyColors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    text.dispose();
  }

  @override
  bool shouldRepaint(covariant ModePickerArt oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.color != color;
}
