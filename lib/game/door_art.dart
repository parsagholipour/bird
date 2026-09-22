import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/obstacle.dart';
import '../domain/sky_door.dart';
import '../ui/theme.dart';

/// The panel exactly fills its parent wall's opening. Chips and fractures
/// reveal its damage; a lethal hit clears collision immediately as debris falls.
abstract final class DoorArt {
  static const _dark = Color(0xff3e3934);
  static const _stone = Color(0xffaf9e81);
  static const _light = Color(0xffeadbb9);
  static const _gold = Color(0xffffce70);

  static void paint(
    Canvas canvas,
    double height,
    Obstacle obstacle, {
    required bool reducedMotion,
  }) {
    final door = obstacle.door!;
    final w = obstacle.width, h = obstacle.bottom - obstacle.top;
    canvas.save();
    canvas.scale(height);
    canvas.translate(obstacle.x, obstacle.top);
    if (door.destroyed) {
      if (!reducedMotion) _debris(canvas, door, w, h);
      canvas.restore();
      return;
    }
    final stage = door.damageStage;
    final hitAge = door.age - door.lastHitAt;
    final impact = (1 - hitAge / .2).clamp(0.0, 1.0);
    // All solid artwork stays inside the collision rectangle, including hits.
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    final slab = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0);
    for (var row = 0; row < 4; row++) {
      final y = row * h / 4;
      final chip = stage >= 2 && row.isOdd ? w * .065 * stage : 0.0;
      slab
        ..lineTo(w, y + h * .05)
        ..lineTo(w - chip, y + h * .1)
        ..lineTo(w - chip * .4, y + h * .18)
        ..lineTo(w, y + h * .25);
    }
    slab.lineTo(0, h);
    for (var row = 3; row >= 0; row--) {
      final y = row * h / 4;
      final chip = stage >= 2 && row.isEven ? w * .065 * stage : 0.0;
      slab
        ..lineTo(0, y + h * .21)
        ..lineTo(chip, y + h * .15)
        ..lineTo(chip * .5, y + h * .06)
        ..lineTo(0, y);
    }
    slab.close();
    canvas.save();
    canvas.clipPath(slab);
    canvas.drawPath(
      slab,
      Paint()
        ..shader = const LinearGradient(
          colors: [_light, _stone, Color(0xff7f7464)],
          stops: [0, .2, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    for (var row = 0; row < 4; row++) {
      final y = row * h / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y + .003), _stroke(_dark, .006));
      canvas.drawLine(
        Offset(.005, y + .008),
        Offset(w - .005, y + .008),
        _stroke(_light, .003),
      );
      final joint = row.isEven ? w * .32 : w * .68;
      canvas.drawLine(
        Offset(joint, y + .006),
        Offset(joint, y + h / 4),
        _stroke(_dark.withValues(alpha: .4), .003),
      );
    }
    // Dark iron brackets distinguish the shootable insert from its walls.
    for (final y in [h * .15, h * .81]) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, .021), Paint()..color = _dark);
      canvas.drawRect(
        Rect.fromLTWH(.004, y + .004, w - .008, .013),
        Paint()..color = _gold,
      );
      for (final x in [w * .15, w * .85]) {
        canvas.drawCircle(Offset(x, y + .01), .003, Paint()..color = _dark);
      }
    }
    final center = Offset(w / 2, h / 2);
    final radius = math.min(w * .35, h * .18);
    canvas.drawCircle(
      center + const Offset(.002, .004),
      radius * 1.12,
      Paint()..color = _dark,
    );
    canvas.drawCircle(center, radius, Paint()..color = _gold);
    canvas.drawCircle(center, radius * .81, Paint()..color = _dark);
    final gem = Path()
      ..moveTo(center.dx, center.dy - radius * .67)
      ..lineTo(center.dx + radius * .4, center.dy)
      ..lineTo(center.dx, center.dy + radius * .67)
      ..lineTo(center.dx - radius * .4, center.dy)
      ..close();
    canvas.drawPath(gem, Paint()..color = stage >= 2 ? SkyColors.coral : _gold);
    const cracks = [
      [
        Offset(0, .29),
        Offset(.3, .35),
        Offset(.23, .43),
        Offset(.52, .5),
        Offset(.75, .63),
        Offset(1, .68),
      ],
      [
        Offset(.85, 0),
        Offset(.61, .15),
        Offset(.7, .27),
        Offset(.43, .38),
        Offset(.52, .5),
      ],
      [
        Offset(.52, .5),
        Offset(.31, .67),
        Offset(.48, .76),
        Offset(.21, .86),
        Offset(.35, 1),
      ],
    ];
    for (var i = 0; i < stage; i++) {
      final path = Path()
        ..addPolygon(
          cracks[i].map((p) => Offset(p.dx * w, p.dy * h)).toList(),
          false,
        );
      canvas.drawPath(
        path.shift(const Offset(.002, .002)),
        _stroke(_light, .006),
      );
      canvas.drawPath(path, _stroke(_dark, .003 + stage * .0015));
    }
    canvas.restore();
    canvas.drawPath(slab, _stroke(_dark, .005));
    // Four health pips are attached to the panel, so several walls can each
    // show their own damage without taking over the match HUD.
    final barY = h * .26;
    for (var i = 0; i < 4; i++) {
      final cell = Rect.fromLTWH(w * .12 + i * w * .2, barY, w * .16, .01);
      canvas.drawRect(cell, Paint()..color = _dark);
      final fill = (door.hp / SkyDoor.maxHp * 4 - i).clamp(0.0, 1.0);
      if (fill > 0) {
        canvas.drawRect(
          Rect.fromLTWH(cell.left, cell.top, cell.width * fill, cell.height),
          Paint()..color = stage >= 2 ? SkyColors.coral : _gold,
        );
      }
    }
    canvas.restore();
    if (!reducedMotion && impact > 0) {
      canvas.save();
      canvas.scale(height);
      for (var i = 0; i < 6; i++) {
        final t = 1 - impact;
        final at = Offset(
          obstacle.x - .004 - t * (.04 + i * .008),
          door.lastHitY + (i - 3) * .01 * t + t * t * .04,
        );
        canvas.drawCircle(
          at,
          .0035 * impact,
          Paint()..color = _gold.withValues(alpha: impact),
        );
      }
      canvas.restore();
    }
  }

  static void _debris(Canvas canvas, SkyDoor door, double w, double h) {
    final t = (door.destructionAge / SkyDoor.crumbleDuration).clamp(0.0, 1.0);
    if (t >= 1) return;
    for (var i = 0; i < 8; i++) {
      final column = i % 2, row = i ~/ 2;
      canvas.save();
      canvas.translate(
        w * (.25 + column * .5) + (column == 0 ? -1 : 1) * t * .06,
        h * (.125 + row * .25) + (row - 1.5) * t * .015 + t * t * .1,
      );
      canvas.rotate((i.isEven ? -1 : 1) * t * 1.4);
      final chunk = Path()
        ..moveTo(-w * .19, -h * .09)
        ..lineTo(w * .1, -h * .11)
        ..lineTo(w * .21, h * .03)
        ..lineTo(w * .05, h * .1)
        ..lineTo(-w * .15, h * .06)
        ..close();
      canvas.drawPath(
        chunk,
        Paint()..color = (i % 3 == 0 ? _gold : _stone).withValues(alpha: 1 - t),
      );
      canvas.drawPath(chunk, _stroke(_dark.withValues(alpha: 1 - t), .003));
      canvas.restore();
    }
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
