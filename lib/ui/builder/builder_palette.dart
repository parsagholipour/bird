import 'package:flutter/material.dart';

import '../../domain/game_rules.dart';
import '../../game/star_art.dart';
import '../theme.dart';
import 'builder_art.dart';
import 'builder_chrome.dart';
import 'builder_controller.dart';

/// The editor's tools down the left edge: Select, then one key per thing
/// a tap places, each showing that thing as the flight draws it.
class BuilderPalette extends StatelessWidget {
  const BuilderPalette({super.key, required this.controller});
  final BuilderController controller;

  static String name(BuilderTool tool) => switch (tool) {
    BuilderTool.select => 'Select',
    BuilderTool.gate => 'Gate',
    BuilderTool.star => 'Star',
    BuilderTool.trio => 'Trio',
    BuilderTool.heart => 'Heart',
    BuilderTool.enemy => 'Enemy',
    BuilderTool.finish => 'Finish',
  };

  static String _hint(BuilderTool tool) => switch (tool) {
    BuilderTool.select => 'Select: tap something to change it, drag to move it',
    BuilderTool.gate => 'Gate: tap the sky to place a gate',
    BuilderTool.star => 'Star: tap the sky to place a star',
    BuilderTool.trio => 'Star trio: tap the sky to place three stars',
    BuilderTool.heart => 'Heart: tap the sky to place a heart',
    BuilderTool.enemy => 'Enemy: tap the sky to place an enemy',
    BuilderTool.finish => 'Finish: tap the sky to move the finish line',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final tools = controller.tools;
      final boss = controller.plan.boss != null;
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final tool in tools)
            BuilderKey(
              key: ValueKey('tool-${tool.name}'),
              tooltip: tool == BuilderTool.finish && boss
                  ? 'Boss mark: tap the sky to move where the boss waits'
                  : _hint(tool),
              width: 80,
              height: 48,
              labelSize: 11,
              gap: 3,
              label: tool == BuilderTool.finish && boss ? 'Boss' : name(tool),
              selected: controller.tool == tool,
              sound: 'ui_toggle',
              art: SizedBox(
                width: 30,
                height: 40,
                child: CustomPaint(
                  painter: ToolIconPainter(
                    tool,
                    region: controller.plan.region,
                    boss: controller.plan.boss,
                  ),
                ),
              ),
              // A starter level's tools answer, but only to say how to
              // change it.
              muted: controller.readOnly,
              onMuted: () => BuilderToast.warn(
                context,
                'Starter levels stay as they are: remix it to change it.',
              ),
              onPressed: () => controller.pick(tool),
            ),
        ],
      );
    },
  );
}

/// A tool's icon: the thing it places, as the flight draws it.
class ToolIconPainter extends CustomPainter {
  const ToolIconPainter(this.tool, {required this.region, this.boss});
  final BuilderTool tool;
  final WorldRegion region;
  final BossKind? boss;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final h = size.height;
    switch (tool) {
      case BuilderTool.select:
        _pointer(canvas, size);
      case BuilderTool.gate:
        BuilderArt.gateIcon(canvas, size, ObstacleKind.garden, region: region);
        _through(canvas, size);
      case BuilderTool.star:
        BuilderArt.starIcon(canvas, size);
      case BuilderTool.trio:
        // Three smaller stars, the middle one a little higher.
        final w = size.width;
        final sky = w * .2 / StarArt.radius;
        for (var i = -1; i <= 1; i++) {
          BuilderArt.star(
            canvas,
            sky,
            c + Offset(i * w * .3, i == 0 ? -w * .16 : w * .1),
          );
        }
      case BuilderTool.heart:
        BuilderArt.heartIcon(canvas, size);
      case BuilderTool.enemy:
        canvas.save();
        canvas.translate(size.width * .1, size.height * .1);
        BuilderArt.enemyIcon(canvas, size * .8, EnemyKind.simpleBat);
        canvas.restore();
      case BuilderTool.finish:
        if (boss != null) {
          BossPortraitPainter.paintIn(
            canvas,
            Rect.fromCenter(center: c, width: h * 1.2, height: h * 1.2),
            boss!,
          );
        } else {
          _flag(canvas, size);
        }
    }
  }

  /// A small arrow flying through a gate's opening, left to right.
  static void _through(Canvas canvas, Size size) {
    final y = size.height / 2, w = size.width;
    final shaft = Path()
      ..moveTo(w * .04, y)
      ..lineTo(w * .78, y);
    final head = Path()
      ..moveTo(w * .66, y - 5)
      ..lineTo(w * .96, y)
      ..lineTo(w * .66, y + 5)
      ..close();
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(shaft, ink..strokeWidth = 5);
    canvas.drawPath(head, ink..strokeWidth = 2.6);
    canvas.drawPath(
      shaft,
      Paint()
        ..color = SkyColors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2,
    );
    canvas.drawPath(head, Paint()..color = SkyColors.white);
  }

  /// An arrow pointer.
  static void _pointer(Canvas canvas, Size size) {
    final s = size.shortestSide / 24;
    canvas.save();
    canvas.translate(size.width / 2 - 6 * s, size.height / 2 - 11 * s);
    canvas.scale(s);
    final arrow = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 19)
      ..lineTo(4.6, 14.6)
      ..lineTo(8.2, 22)
      ..lineTo(11.6, 20.4)
      ..lineTo(8, 13.2)
      ..lineTo(14, 13)
      ..close();
    canvas.drawPath(arrow, Paint()..color = SkyColors.white);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  /// A chequered finish flag.
  static void _flag(Canvas canvas, Size size) {
    final s = size.shortestSide / 24;
    canvas.save();
    canvas.translate(size.width / 2 - 10 * s, size.height / 2 - 13 * s);
    canvas.scale(s);
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(const Offset(2, 2), const Offset(2, 24), ink);
    const flag = Rect.fromLTWH(2, 2, 16, 11);
    canvas.drawRect(flag, Paint()..color = SkyColors.white);
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 3; j++) {
        if ((i + j).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(2 + i * 4, 2 + j * 11 / 3, 4, 11 / 3),
            Paint()..color = SkyColors.ink,
          );
        }
      }
    }
    canvas.drawRect(flag, ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ToolIconPainter old) =>
      old.tool != tool || old.region != region || old.boss != boss;
}
