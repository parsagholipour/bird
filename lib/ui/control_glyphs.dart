import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// The four ways to steer the bird.
enum FlyControl {
  pushUp('Push-ups', Color(0xffff9f8a)),
  squat('Squats', SkyColors.mint),
  jump('Jumps', SkyColors.yellow),
  tap('Taps', SkyColors.lavender);

  const FlyControl(this.label, this.color);
  final String label;
  final Color color;
}

/// A round sticker with a tiny inked pictogram of [control], drawn on a
/// 28-unit grid so it stays crisp at any size.
class ControlGlyph extends StatelessWidget {
  const ControlGlyph(this.control, {super.key, this.size = 30});
  final FlyControl control;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GlyphPainter(control));
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.control);
  final FlyControl control;

  static final _ink = Paint()
    ..color = SkyColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _thin = Paint()
    ..color = SkyColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.9
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _fill = Paint()..color = SkyColors.ink;
  static final _ground = Paint()
    ..color = SkyColors.ink.withValues(alpha: .38)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 28);
    const center = Offset(14, 14);
    canvas.drawCircle(center, 13.2, Paint()..color = control.color);
    canvas.drawCircle(
      center,
      13.2,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    // A soft highlight keeps the sticker in the family of the round buttons.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 10.2),
      math.pi * 1.08,
      math.pi * .38,
      false,
      Paint()
        ..color = SkyColors.white.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    switch (control) {
      case FlyControl.pushUp:
        _pushUp(canvas);
      case FlyControl.squat:
        _squat(canvas);
      case FlyControl.jump:
        _jump(canvas);
      case FlyControl.tap:
        _tap(canvas);
    }
  }

  void _line(Canvas canvas, List<Offset> points, [Paint? paint]) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint ?? _ink);
  }

  void _pushUp(Canvas c) {
    _line(c, const [Offset(5.5, 21.4), Offset(22.5, 21.4)], _ground);
    c.drawCircle(const Offset(21.4, 10.6), 2.7, _fill);
    _line(c, const [Offset(18.2, 12.8), Offset(6.4, 19.4)]);
    _line(c, const [Offset(17.2, 13.4), Offset(17.2, 20.4)]);
  }

  void _squat(Canvas c) {
    _line(c, const [Offset(6, 22.6), Offset(22, 22.6)], _ground);
    c.drawCircle(const Offset(13.2, 6.2), 2.7, _fill);
    _line(c, const [
      Offset(12.4, 9.6),
      Offset(8.6, 15.4),
      Offset(16.4, 16),
      Offset(15, 21.6),
    ]);
    _line(c, const [Offset(12, 11.4), Offset(20.4, 11.8)]);
  }

  void _jump(Canvas c) {
    _line(c, const [Offset(9, 23), Offset(19, 23)], _ground);
    c.drawCircle(const Offset(14, 5.6), 2.7, _fill);
    _line(c, const [Offset(14, 9), Offset(14, 15.6)]);
    _line(c, const [Offset(7.4, 6.2), Offset(14, 10.6), Offset(20.6, 6.2)]);
    _line(c, const [Offset(10.4, 20.2), Offset(14, 15.6), Offset(17.6, 20.2)]);
  }

  void _tap(Canvas c) {
    for (final r in [4.2, 7.4]) {
      c.drawArc(
        Rect.fromCircle(center: const Offset(12.5, 8.6), radius: r),
        math.pi * 1.16,
        math.pi * .68,
        false,
        _thin,
      );
    }
    final finger = Path()
      ..moveTo(10.4, 9)
      ..quadraticBezierTo(12.5, 7.4, 14.6, 9)
      ..lineTo(14.6, 15.2)
      ..lineTo(19.6, 16.2)
      ..quadraticBezierTo(21.4, 16.8, 21.2, 19)
      ..lineTo(20, 22.4)
      ..quadraticBezierTo(19.6, 23.6, 18.4, 23.6)
      ..lineTo(13.2, 23.6)
      ..quadraticBezierTo(11.8, 23.6, 11, 22.4)
      ..lineTo(8.6, 18.4)
      ..quadraticBezierTo(8, 17, 9.4, 16.4)
      ..quadraticBezierTo(10.2, 16.2, 10.4, 17.2)
      ..close();
    c.drawPath(finger, Paint()..color = SkyColors.cream);
    c.drawPath(finger, _thin);
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.control != control;
}
