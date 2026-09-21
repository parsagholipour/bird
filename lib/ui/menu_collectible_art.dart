import 'package:flutter/material.dart';
import '../game/sky_scenery.dart';
import 'theme.dart';

enum MenuCollectible { adventure, passport, records, goals }

/// Small illustrated objects from the bird's world, drawn at a 100 × 80 scale.
class MenuCollectibleArt extends StatelessWidget {
  const MenuCollectibleArt(this.collectible, {super.key});
  final MenuCollectible collectible;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(100, 80),
    painter: _CollectiblePainter(collectible),
  );
}

class _CollectiblePainter extends CustomPainter {
  const _CollectiblePainter(this.collectible);
  final MenuCollectible collectible;

  static const outline = Color(0xff35565b);

  void _shape(Canvas canvas, Path path, Color color, {double width = 2.3}) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _line(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _rounded(Canvas canvas, Rect rect, Color color, {double radius = 4}) {
    _shape(
      canvas,
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))),
      color,
    );
  }

  void _star(Canvas canvas, Offset center, double radius) {
    _shape(
      canvas,
      SkyScenery.star(center, radius),
      SkyColors.yellow,
      width: 1.6,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 80);
    canvas.drawOval(
      const Rect.fromLTWH(20, 70, 61, 7),
      Paint()..color = SkyColors.ink.withValues(alpha: .12),
    );
    switch (collectible) {
      case MenuCollectible.adventure:
        _map(canvas);
      case MenuCollectible.passport:
        _passport(canvas);
      case MenuCollectible.records:
        _trophy(canvas);
      case MenuCollectible.goals:
        _wings(canvas);
    }
    canvas.restore();
  }

  void _map(Canvas c) {
    c.save();
    c.translate(50, 40);
    c.rotate(-.1);
    c.translate(-50, -40);
    _shape(
      c,
      Path()
        ..moveTo(11, 17)
        ..lineTo(34, 10)
        ..lineTo(60, 17)
        ..lineTo(84, 10)
        ..lineTo(89, 62)
        ..lineTo(65, 70)
        ..lineTo(38, 63)
        ..lineTo(15, 70)
        ..close(),
      SkyColors.cream,
    );
    c.drawPath(
      Path()
        ..moveTo(34, 11)
        ..lineTo(60, 18)
        ..lineTo(65, 68)
        ..lineTo(38, 62)
        ..close(),
      Paint()..color = const Color(0xffeedcad),
    );
    _line(
      c,
      Path()
        ..moveTo(34, 14)
        ..lineTo(38, 60)
        ..moveTo(60, 20)
        ..lineTo(64, 65),
      SkyColors.sand,
      1.5,
    );
    c.drawPath(
      Path()
        ..moveTo(18, 48)
        ..quadraticBezierTo(25, 33, 34, 39)
        ..quadraticBezierTo(45, 51, 55, 33)
        ..quadraticBezierTo(65, 23, 78, 28)
        ..lineTo(79, 36)
        ..quadraticBezierTo(65, 29, 61, 40)
        ..quadraticBezierTo(45, 60, 31, 47)
        ..quadraticBezierTo(23, 40, 18, 58)
        ..close(),
      Paint()..color = SkyColors.skyDeep,
    );
    final path = Path()
      ..moveTo(24, 57)
      ..cubicTo(58, 68, 39, 27, 70, 22);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        c.drawCircle(
          metric.getTangentForOffset(d)!.position,
          1.6,
          Paint()..color = SkyColors.coralDeep,
        );
      }
    }
    _line(
      c,
      Path()
        ..moveTo(65, 18)
        ..lineTo(73, 26)
        ..moveTo(73, 18)
        ..lineTo(65, 26),
      SkyColors.coralDeep,
      3.5,
    );
    _shape(
      c,
      Path()..addOval(const Rect.fromLTWH(3, 1, 26, 26)),
      SkyColors.yellow,
      width: 2,
    );
    _shape(
      c,
      Path()
        ..moveTo(16, 5)
        ..lineTo(21, 20)
        ..lineTo(16, 17)
        ..lineTo(11, 20)
        ..close(),
      SkyColors.coral,
      width: 1.3,
    );
    c.restore();
  }

  void _passport(Canvas c) {
    c.save();
    c.translate(50, 40);
    c.rotate(.13);
    c.translate(-50, -40);
    _rounded(c, const Rect.fromLTWH(24, 7, 52, 65), SkyColors.teal, radius: 6);
    _rounded(c, const Rect.fromLTWH(29, 9, 49, 60), SkyColors.cream, radius: 4);
    _line(
      c,
      Path()
        ..moveTo(36, 63)
        ..lineTo(72, 63)
        ..moveTo(36, 66)
        ..lineTo(72, 66),
      SkyColors.sand,
      1,
    );
    _shape(
      c,
      Path()
        ..moveTo(58, 56)
        ..lineTo(68, 56)
        ..lineTo(68, 78)
        ..lineTo(63, 74)
        ..lineTo(58, 78)
        ..close(),
      SkyColors.coral,
      width: 1.7,
    );
    _rounded(c, const Rect.fromLTWH(22, 4, 53, 57), SkyColors.teal, radius: 5);
    _line(
      c,
      Path()
        ..moveTo(29, 7)
        ..lineTo(29, 57),
      const Color(0xff2b8279),
      2.5,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 11, 33, 40),
        const Radius.circular(3),
      ),
      Paint()
        ..color = SkyColors.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    _star(c, const Offset(50, 29), 12);
    _line(
      c,
      Path()
        ..moveTo(43, 46)
        ..lineTo(57, 46),
      SkyColors.yellow,
      2.5,
    );
    c.restore();
    _star(c, const Offset(82, 13), 6);
  }

  void _trophy(Canvas c) {
    _shape(
      c,
      Path()
        ..moveTo(27, 18)
        ..lineTo(13, 18)
        ..lineTo(13, 28)
        ..quadraticBezierTo(13, 44, 35, 43)
        ..lineTo(33, 35)
        ..quadraticBezierTo(20, 36, 20, 25)
        ..lineTo(29, 25)
        ..close(),
      SkyColors.gold,
    );
    _shape(
      c,
      Path()
        ..moveTo(73, 18)
        ..lineTo(87, 18)
        ..lineTo(87, 28)
        ..quadraticBezierTo(87, 44, 65, 43)
        ..lineTo(67, 35)
        ..quadraticBezierTo(80, 36, 80, 25)
        ..lineTo(71, 25)
        ..close(),
      SkyColors.gold,
    );
    _rounded(c, const Rect.fromLTWH(45, 41, 10, 22), SkyColors.gold, radius: 2);
    _shape(
      c,
      Path()
        ..moveTo(26, 12)
        ..lineTo(74, 12)
        ..lineTo(70, 34)
        ..quadraticBezierTo(66, 50, 50, 51)
        ..quadraticBezierTo(34, 50, 30, 34)
        ..close(),
      SkyColors.yellow,
    );
    c.drawPath(
      Path()
        ..moveTo(61, 14)
        ..lineTo(72, 14)
        ..lineTo(68, 34)
        ..quadraticBezierTo(64, 47, 51, 49)
        ..lineTo(51, 43)
        ..quadraticBezierTo(61, 37, 61, 14)
        ..close(),
      Paint()..color = SkyColors.gold,
    );
    _line(
      c,
      Path()
        ..moveTo(33, 19)
        ..lineTo(35, 31),
      SkyColors.cream,
      4,
    );
    _star(c, const Offset(50, 30), 10);
    _rounded(
      c,
      const Rect.fromLTWH(24, 10, 52, 7),
      SkyColors.yellow,
      radius: 3,
    );
    _rounded(c, const Rect.fromLTWH(35, 58, 30, 8), SkyColors.gold, radius: 3);
    _rounded(c, const Rect.fromLTWH(29, 65, 42, 9), SkyColors.coral, radius: 3);
    _line(
      c,
      Path()
        ..moveTo(43, 69)
        ..lineTo(57, 69),
      SkyColors.cream,
      2.5,
    );
    _star(c, const Offset(86, 7), 6);
  }

  void _wings(Canvas c) {
    for (final flipped in [false, true]) {
      c.save();
      if (flipped) {
        c.translate(100, 0);
        c.scale(-1, 1);
      }
      _shape(
        c,
        Path()
          ..moveTo(41, 26)
          ..cubicTo(26, 26, 13, 22, 5, 14)
          ..quadraticBezierTo(2, 27, 16, 35)
          ..quadraticBezierTo(7, 34, 9, 38)
          ..quadraticBezierTo(12, 49, 28, 48)
          ..quadraticBezierTo(20, 50, 23, 54)
          ..quadraticBezierTo(32, 61, 44, 49)
          ..close(),
        SkyColors.cream,
      );
      _line(
        c,
        Path()
          ..moveTo(15, 29)
          ..quadraticBezierTo(25, 36, 34, 35)
          ..moveTo(19, 41)
          ..lineTo(33, 43),
        SkyColors.sand,
        2,
      );
      c.restore();
    }
    _shape(
      c,
      Path()
        ..moveTo(38, 49)
        ..lineTo(51, 54)
        ..lineTo(40, 76)
        ..lineTo(36, 67)
        ..lineTo(27, 70)
        ..close(),
      SkyColors.lavender,
    );
    _shape(
      c,
      Path()
        ..moveTo(49, 54)
        ..lineTo(62, 49)
        ..lineTo(73, 70)
        ..lineTo(64, 67)
        ..lineTo(60, 76)
        ..close(),
      SkyColors.purple,
    );
    _shape(
      c,
      Path()..addOval(const Rect.fromLTWH(29, 16, 42, 42)),
      SkyColors.gold,
    );
    _shape(
      c,
      Path()..addOval(const Rect.fromLTWH(33, 20, 34, 34)),
      SkyColors.yellow,
      width: 1.5,
    );
    _star(c, const Offset(50, 37), 12);
    _line(
      c,
      Path()
        ..moveTo(39, 26)
        ..quadraticBezierTo(43, 22, 49, 23),
      SkyColors.cream,
      2.5,
    );
  }

  @override
  bool shouldRepaint(_CollectiblePainter oldDelegate) =>
      oldDelegate.collectible != collectible;
}
