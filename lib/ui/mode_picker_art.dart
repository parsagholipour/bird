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

  /// One limb segment: two joint discs joined by their outer tangents, so a
  /// limb tapers smoothly from [ra] to [rb] with no kink at the joints.
  Path _segment(Offset a, Offset b, double ra, double rb) {
    final delta = b - a;
    final d = delta.distance;
    final path = Path()
      ..addOval(Rect.fromCircle(center: a, radius: ra))
      ..addOval(Rect.fromCircle(center: b, radius: rb));
    if (d <= (ra - rb).abs()) return path;
    final theta = math.atan2(delta.dy, delta.dx);
    final phi = math.acos((ra - rb) / d);
    Offset at(Offset c, double r, double angle) =>
        c + Offset(math.cos(angle), math.sin(angle)) * r;
    return Path.combine(
      PathOperation.union,
      path,
      Path()..addPolygon([
        at(a, ra, theta + phi),
        at(b, rb, theta + phi),
        at(b, rb, theta - phi),
        at(a, ra, theta - phi),
      ], true),
    );
  }

  /// A whole limb through [points], tapering through [radii].
  Path _taper(List<Offset> points, List<double> radii) {
    var path = Path();
    for (var i = 0; i < points.length - 1; i++) {
      path = Path.combine(
        PathOperation.union,
        path,
        _segment(points[i], points[i + 1], radii[i], radii[i + 1]),
      );
    }
    return path;
  }

  /// Overlapping pieces painted as one silhouette: a single ink outline runs
  /// around the group, so an arm and its hand, or two legs and the seat of the
  /// trousers, read as one shape rather than stickers stacked on each other.
  void _inked(Canvas canvas, List<(Path, Color)> parts) {
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..strokeJoin = StrokeJoin.round;
    for (final (path, _) in parts) {
      canvas.drawPath(path, ink);
    }
    for (final (path, color) in parts) {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  /// A rounded mitten hand with a thumb, fingers pointing along [angle] from
  /// the [wrist]; [thumb] picks the side (+1 or -1) the thumb sits on.
  Path _mitten(Offset wrist, double angle, {double thumb = -1}) {
    final t = thumb;
    final local = Path()
      ..moveTo(-1.5, -3 * t)
      ..lineTo(1.6, -3.4 * t)
      ..cubicTo(2.6, -5.4 * t, 4.4, -8.4 * t, 6.4, -8.2 * t)
      ..quadraticBezierTo(8.2, -7.8 * t, 7.4, -6 * t)
      ..quadraticBezierTo(6.8, -4.8 * t, 6.4, -4 * t)
      ..cubicTo(12.6, -4.6 * t, 13, 4.2 * t, 7, 4.2 * t)
      ..lineTo(1.6, 3.8 * t)
      ..quadraticBezierTo(-1.4, 3.6 * t, -1.5, 2.8 * t)
      ..close();
    return local.transform(
      (Matrix4.identity()
            ..translateByDouble(wrist.dx, wrist.dy, 0, 1)
            ..rotateZ(angle)
            ..scaleByDouble(1.15, 1.15, 1, 1))
          .storage,
    );
  }

  /// An arm from shoulder through elbow to wrist, ending in a mitten hand,
  /// or, when [planted], a palm pressed flat on the floor, fingers to the left.
  void _arm(
    Canvas canvas,
    Offset shoulder,
    Offset elbow,
    Offset wrist,
    Color skin, {
    double? handAngle,
    double thumb = -1,
    bool planted = false,
    bool open = false,
  }) {
    final crease = Color.lerp(skin, SkyColors.ink, .3)!;
    final limb = _taper([shoulder, elbow, wrist], [4.4, 3.6, 3.0]);
    if (planted) {
      const floor = 124.4;
      final x = wrist.dx, y = wrist.dy;
      _inked(canvas, [
        (limb, skin),
        (
          Path()
            ..moveTo(x + 3, y)
            ..quadraticBezierTo(x + 3.8, floor, x - .5, floor)
            ..lineTo(x - 11, floor)
            ..quadraticBezierTo(x - 14.4, floor, x - 14, floor - 2.4)
            ..quadraticBezierTo(x - 13.4, floor - 4.6, x - 9, floor - 4.9)
            ..quadraticBezierTo(x - 4.4, floor - 5.2, x - 3, y)
            ..close(),
          skin,
        ),
      ]);
      // The thumb lies along the fingers, toward the viewer.
      _detail(
        canvas,
        Path()
          ..moveTo(x - 2.6, floor - 3.4)
          ..quadraticBezierTo(x - 6, floor - 1.6, x - 9.6, floor - 2),
        crease,
        width: 1,
      );
      return;
    }
    final angle =
        handAngle ?? math.atan2(wrist.dy - elbow.dy, wrist.dx - elbow.dx);
    _inked(canvas, [(limb, skin), (_mitten(wrist, angle, thumb: thumb), skin)]);
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(angle);
    // A short crease marks where the thumb meets the palm; an open hand
    // also shows the gaps between its fingers.
    final lines = Path()
      ..moveTo(6.2, -4 * thumb)
      ..quadraticBezierTo(4.6, -2.2 * thumb, 2.8, -2 * thumb);
    if (open) {
      lines
        ..moveTo(11.6, -1.5 * thumb)
        ..lineTo(8.4, -1.2 * thumb)
        ..moveTo(11.4, 1.6 * thumb)
        ..lineTo(8.4, 1.6 * thumb);
    }
    _detail(canvas, lines, crease, width: 1);
    canvas.restore();
  }

  /// A trouser leg from hip through knee to ankle, with a turned-up cuff.
  void _leg(Canvas canvas, Offset hip, Offset knee, Offset ankle, Color color) {
    _inked(canvas, [
      (_taper([hip, knee, ankle], [6.4, 5.0, 4.6]), color),
    ]);
    final shin = ankle - knee;
    final dir = shin / shin.distance;
    final across = Offset(-dir.dy, dir.dx) * 4.2;
    final cuff = ankle - dir * 2.2;
    _detail(
      canvas,
      Path()
        ..moveTo((cuff + across).dx, (cuff + across).dy)
        ..lineTo((cuff - across).dx, (cuff - across).dy),
      Color.lerp(color, SkyColors.ink, .35)!,
      width: 1.2,
    );
  }

  /// A short T-shirt sleeve over the top of an arm, flaring to an open cuff.
  void _sleeve(
    Canvas canvas,
    Offset shoulder,
    Offset elbow,
    Color color,
    Color trim, {
    double length = 9,
  }) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(math.atan2(elbow.dy - shoulder.dy, elbow.dx - shoulder.dx));
    _shape(
      canvas,
      Path()
        ..moveTo(-1, -5.4)
        ..lineTo(length, -6)
        ..quadraticBezierTo(length + 1.2, 0, length, 6.2)
        ..lineTo(-1, 5.6)
        ..cubicTo(-6.4, 5.4, -6.4, -5.2, -1, -5.4)
        ..close(),
      color,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(length - 2.2, -5)
        ..quadraticBezierTo(length - 1, 0, length - 2.2, 5.2),
      trim,
      width: 2,
    );
    canvas.restore();
  }

  /// A T-shirt seen side-on, from the base of the neck to the hips; the chest
  /// faces the -x side of the torso's own frame.
  void _profileTee(
    Canvas canvas,
    Offset neck,
    Offset hip,
    Color color,
    Color trim, {
    bool star = false,
  }) {
    final l = (hip - neck).distance;
    canvas.save();
    canvas.translate(neck.dx, neck.dy);
    canvas.rotate(math.atan2(hip.dy - neck.dy, hip.dx - neck.dx) - math.pi / 2);
    _shape(
      canvas,
      Path()
        ..moveTo(-4.5, -1)
        ..cubicTo(-9.5, 0, -11.5, 4, -11.2, 10)
        ..cubicTo(-11, l * .6, -10, l - 6, -10.4, l - 1)
        ..lineTo(-11.6, l + 2.6)
        ..quadraticBezierTo(0, l + 5.4, 10.6, l + 2.4)
        ..lineTo(9.6, l - 2)
        ..cubicTo(10.4, l * .55, 10.8, 10, 9, 4)
        ..quadraticBezierTo(7.6, -1.4, 4, -2)
        ..quadraticBezierTo(-.5, 1.4, -4.5, -1)
        ..close(),
      color,
    );
    // A ribbed collar and hem band in the trim colour.
    _detail(
      canvas,
      Path()
        ..moveTo(-4.4, -.2)
        ..quadraticBezierTo(-.4, 3.2, 4.2, -1),
      trim,
      width: 2.4,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(-10.2, l)
        ..quadraticBezierTo(0, l + 2.6, 9.6, l - .4),
      Color.lerp(color, SkyColors.ink, .22)!,
      width: 1.4,
    );
    // A soft highlight down the back keeps the flat shirt rounded.
    _detail(
      canvas,
      Path()
        ..moveTo(6.6, 5)
        ..quadraticBezierTo(8, l * .45, 7, l - 4),
      Color.lerp(color, SkyColors.cream, .35)!,
      width: 2,
    );
    if (star) {
      _star(canvas, Offset(-4.6, l * .6), 4.2, SkyColors.yellow);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(-8, l * .38)
          ..quadraticBezierTo(-3, l * .28, 1.6, l * .38)
          ..quadraticBezierTo(-1.6, l * .42, -2.4, l * .54)
          ..lineTo(-6.4, l * .52)
          ..close(),
        Paint()..color = SkyColors.cream.withValues(alpha: .9),
      );
    }
    canvas.restore();
  }

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .48;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    _shape(canvas, path..close(), color, outline: 1.3);
  }

  /// A T-shirt from the front, for the jumper; sleeves are drawn on the arms.
  void _frontTee(Canvas canvas, Offset neck, double hem, Color color) {
    final x = neck.dx, y = neck.dy;
    _shape(
      canvas,
      Path()
        ..moveTo(x - 5.5, y - 1)
        ..quadraticBezierTo(x, y + 4.5, x + 5.5, y - 1)
        ..quadraticBezierTo(x + 10, y, x + 12, y + 3)
        ..quadraticBezierTo(x + 10.6, y + 12, x + 10.2, hem - 3)
        ..lineTo(x + 11, hem + 1)
        ..quadraticBezierTo(x, hem + 4, x - 11, hem + 1)
        ..lineTo(x - 10.2, hem - 3)
        ..quadraticBezierTo(x - 10.6, y + 12, x - 12, y + 3)
        ..quadraticBezierTo(x - 10, y, x - 5.5, y - 1)
        ..close(),
      color,
    );
    final seam = Color.lerp(color, SkyColors.ink, .25)!;
    _detail(
      canvas,
      Path()
        ..moveTo(x - 5, y)
        ..quadraticBezierTo(x, y + 5.4, x + 5, y),
      seam,
      width: 2,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(x - 9.6, hem - 1)
        ..quadraticBezierTo(x, hem + 2, x + 9.6, hem - 1),
      Color.lerp(color, SkyColors.ink, .18)!,
      width: 1.4,
    );
    // A simple wing patch ties the runners to the game's bird.
    canvas.drawPath(
      Path()
        ..moveTo(x - 1, y + 10)
        ..quadraticBezierTo(x + 4, y + 6, x + 8, y + 8)
        ..quadraticBezierTo(x + 5, y + 9, x + 4, y + 12)
        ..lineTo(x + 1, y + 12)
        ..close(),
      Paint()..color = SkyColors.cream.withValues(alpha: .9),
    );
  }

  /// A sneaker around the [ankle]: upper, cream toe cap, laces and a thick
  /// sole; the toe points along +x before [angle] and [facingLeft] apply.
  void _shoe(
    Canvas canvas,
    Offset ankle, {
    required Color upper,
    required Color accent,
    double angle = 0,
    bool facingLeft = false,
  }) {
    canvas.save();
    canvas.translate(ankle.dx, ankle.dy);
    canvas.rotate(angle);
    if (facingLeft) canvas.scale(-1, 1);
    final light = upper.computeLuminance() > .6;
    final sole = RRect.fromLTRBR(
      -8.6,
      3.2,
      14.6,
      7.6,
      const Radius.circular(2.4),
    );
    _shape(
      canvas,
      Path()
        ..moveTo(-6.6, -6.6)
        ..quadraticBezierTo(-2.2, -4.6, 1.6, -6.2)
        ..quadraticBezierTo(4.2, -4.6, 6.4, -3)
        ..cubicTo(10.6, -2, 13.8, .2, 13.8, 4)
        ..lineTo(-7.6, 4)
        ..cubicTo(-8.8, .4, -8.4, -4, -6.6, -6.6)
        ..close(),
      upper,
    );
    // Toe cap.
    _shape(
      canvas,
      Path()
        ..moveTo(8.4, -1.5)
        ..quadraticBezierTo(7.2, 1.4, 8.2, 4)
        ..lineTo(13.8, 4)
        ..cubicTo(13.8, 1, 12, -.9, 8.4, -1.5)
        ..close(),
      light
          ? Color.lerp(SkyColors.cream, SkyColors.ink, .07)!
          : SkyColors.cream,
      outline: 1.4,
    );
    // A side stripe and the laces across the instep.
    _detail(
      canvas,
      Path()
        ..moveTo(-5.6, 1.4)
        ..quadraticBezierTo(-.6, -.6, 4.8, 1.6),
      accent,
      width: 2.2,
    );
    _detail(
      canvas,
      Path()
        ..moveTo(1.4, -5)
        ..lineTo(3.2, -2.6)
        ..moveTo(4.2, -4)
        ..lineTo(5.8, -1.8),
      light ? accent : SkyColors.cream,
      width: 1.5,
    );
    _shape(canvas, Path()..addRRect(sole), SkyColors.white, outline: 2);
    _detail(
      canvas,
      Path()
        ..moveTo(-7.4, 5.6)
        ..lineTo(13.4, 5.6),
      SkyColors.ink.withValues(alpha: .28),
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
    final farSkin = Color.lerp(skin, SkyColors.sand, .35)!;
    const trousers = Color(0xff385460);
    final farTrousers = Color.lerp(trousers, SkyColors.ink, .3)!;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(95, 126),
        width: mode == PlayMode.pushUp ? 134 : 83,
        height: 9,
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .12),
    );
    if (mode == PlayMode.pushUp) {
      // Side-on plank: shoulders stacked over planted hands, and one straight
      // line from the neck through the hips to the heels.
      const shirt = SkyColors.coral;
      final trim = Color.lerp(shirt, SkyColors.ink, .2)!;
      const neck = Offset(72, 80), hip = Offset(111.4, 94.7);
      const ankle = Offset(152, 110);
      const knee = Offset(131.7, 102.4);
      _arm(
        canvas,
        const Offset(84, 82),
        const Offset(85.4, 100),
        const Offset(84.6, 117.6),
        farSkin,
        planted: true,
      );
      _leg(canvas, hip, knee, ankle, trousers);
      _shoe(
        canvas,
        ankle,
        upper: SkyColors.cream,
        accent: shirt,
        angle: -.8,
        facingLeft: true,
      );
      _limb(canvas, [const Offset(63, 76), const Offset(73, 81)], skin, 8);
      _profileTee(canvas, neck, hip, shirt, trim);
      _arm(
        canvas,
        const Offset(77.3, 83),
        const Offset(78.4, 100.4),
        const Offset(77.4, 117.6),
        skin,
        planted: true,
      );
      _sleeve(
        canvas,
        const Offset(77.3, 83),
        const Offset(78.4, 100.4),
        shirt,
        trim,
      );
      _head(
        canvas,
        const Offset(55, 71),
        skin: skin,
        tilt: -.3,
        facingLeft: true,
      );
      _arrow(canvas, const Offset(106, 66), const Offset(106, 39));
    } else if (mode == PlayMode.jump) {
      // A star jump: arms flung up in a V, legs spread, toes pointed, and
      // both feet clear of the ground.
      const shirt = SkyColors.yellow;
      final trim = Color.lerp(shirt, SkyColors.ink, .22)!;
      const shoulderL = Offset(86, 67), shoulderR = Offset(108, 67);
      const elbowL = Offset(74, 58), elbowR = Offset(120, 58);
      canvas.save();
      canvas.translate(0, 1);
      _arm(canvas, shoulderL, elbowL, const Offset(65, 45), skin, open: true);
      _arm(
        canvas,
        shoulderR,
        elbowR,
        const Offset(129, 45),
        skin,
        thumb: 1,
        open: true,
      );
      _inked(canvas, [
        (
          Path()..addRRect(
            RRect.fromLTRBR(88, 79, 106, 90, const Radius.circular(5)),
          ),
          trousers,
        ),
      ]);
      _leg(
        canvas,
        const Offset(91.5, 85),
        const Offset(82.5, 95.5),
        const Offset(76, 104),
        trousers,
      );
      _leg(
        canvas,
        const Offset(102.5, 85),
        const Offset(111.5, 95.5),
        const Offset(118, 104),
        trousers,
      );
      _shoe(
        canvas,
        const Offset(76, 104),
        upper: SkyColors.cream,
        accent: SkyColors.teal,
        angle: -.8,
        facingLeft: true,
      );
      _shoe(
        canvas,
        const Offset(118, 104),
        upper: SkyColors.cream,
        accent: SkyColors.teal,
        angle: .8,
      );
      _limb(canvas, [const Offset(97.5, 52), const Offset(97, 63)], skin, 9);
      _frontTee(canvas, const Offset(97, 62), 86, shirt);
      _sleeve(canvas, shoulderL, elbowL, shirt, trim, length: 7);
      _sleeve(canvas, shoulderR, elbowR, shirt, trim, length: 7);
      _head(canvas, const Offset(98.5, 40), skin: skin, tilt: -.08);
      canvas.restore();
      _arrow(canvas, const Offset(143, 91), const Offset(143, 62));
      _limb(
        canvas,
        [const Offset(89, 124), const Offset(90, 117)],
        SkyColors.cream,
        2,
      );
      _limb(
        canvas,
        [const Offset(105, 124), const Offset(104, 117)],
        SkyColors.cream,
        2,
      );
    } else {
      // A deep squat in three-quarter profile: hips back, knees over the
      // toes, both soles flat and the arms reaching forward for balance.
      const shirt = SkyColors.teal;
      const trim = SkyColors.mint;
      final farShirt = Color.lerp(shirt, SkyColors.ink, .2)!;
      const shoe = SkyColors.yellow;
      _leg(
        canvas,
        const Offset(109, 93),
        const Offset(80, 95),
        const Offset(86, 115),
        farTrousers,
      );
      _shoe(
        canvas,
        const Offset(86, 115),
        upper: Color.lerp(shoe, SkyColors.ink, .15)!,
        accent: SkyColors.coralDeep,
        facingLeft: true,
      );
      _arm(
        canvas,
        const Offset(99.5, 72),
        const Offset(86, 80),
        const Offset(71, 80),
        farSkin,
      );
      _sleeve(
        canvas,
        const Offset(99.5, 72),
        const Offset(86, 80),
        farShirt,
        trim,
        length: 10,
      );
      _leg(
        canvas,
        const Offset(113, 96),
        const Offset(88, 99),
        const Offset(98, 117),
        trousers,
      );
      _shoe(
        canvas,
        const Offset(98, 117),
        upper: shoe,
        accent: SkyColors.coralDeep,
        facingLeft: true,
      );
      _limb(canvas, [const Offset(86, 60), const Offset(93, 69)], skin, 8);
      _profileTee(
        canvas,
        const Offset(93, 68),
        const Offset(111, 93),
        shirt,
        trim,
        star: true,
      );
      _arm(
        canvas,
        const Offset(95.7, 73.5),
        const Offset(81, 83),
        const Offset(65, 85),
        skin,
      );
      _sleeve(
        canvas,
        const Offset(95.7, 73.5),
        const Offset(81, 83),
        shirt,
        trim,
        length: 10,
      );
      _head(
        canvas,
        const Offset(84, 54),
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
