import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/built_reach.dart';
import '../../domain/game_rules.dart';
import '../../game/star_art.dart';
import '../../l10n/l10n.dart';
import '../../l10n/text/builder_text.dart';
import '../theme.dart';
import '../ui_sounds.dart';
import 'builder_chrome.dart';
import 'builder_controller.dart';

/// The whole route in one strip under the sky: gates as little walls,
/// stars, hearts and enemies as dots, the finish, problem flags and seconds
/// from the start. The window over it is what the sky shows; tap or drag
/// anywhere on the strip to go there.
class BuilderTimeline extends StatelessWidget {
  const BuilderTimeline({
    super.key,
    required this.controller,
    required this.view,
  });
  final BuilderController controller;

  /// How much of the route the sky shows (sky heights).
  final double view;

  static double span(BuiltPlan plan) => plan.finishX + 1.2;

  void _go(Offset local, double width) {
    final plan = controller.plan;
    final x = local.dx / width * span(plan);
    controller.scrollTo(math.max(0, x - view / 2));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l = context.l10n;
      final plan = controller.plan;
      final reps = builtReps(plan, l);
      final target = plan.boss == null ? 'finish' : 'boss';
      final length = builtLength(plan, l);
      return Semantics(
        label: reps == null
            ? l.builderRouteSemantics(target, length)
            : l.builderRouteRepsSemantics(target, length, reps),
        child: LayoutBuilder(
          builder: (context, box) => GestureDetector(
            key: const ValueKey('builder-timeline'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              UiSounds.effect(context);
              _go(d.localPosition, box.maxWidth);
            },
            onHorizontalDragStart: (d) => _go(d.localPosition, box.maxWidth),
            onHorizontalDragUpdate: (d) => _go(d.localPosition, box.maxWidth),
            child: CustomPaint(
              size: box.biggest,
              painter: _TimelinePainter(
                words: l,
                plan: plan,
                scroll: controller.scroll,
                view: view,
                issues: controller.issues,
                selected: controller.selection,
                reps: reps,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// A level's whole route as a strip, to look at: the timeline without its
/// window, as a pasted level's preview shows it.
class BuilderRouteStrip extends StatelessWidget {
  const BuilderRouteStrip({super.key, required this.plan});
  final BuiltPlan plan;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    // The route runs left to right in every language, as the sky does.
    child: FlightDirection(
      child: CustomPaint(
        size: const Size.fromHeight(58),
        painter: _TimelinePainter(
          words: context.l10n,
          plan: plan,
          scroll: 0,
          view: 0,
          issues: const [],
          selected: null,
          reps: builtReps(plan, context.l10n),
        ),
      ),
    ),
  );
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.words,
    required this.plan,
    required this.scroll,
    required this.view,
    required this.issues,
    required this.selected,
    required this.reps,
  });

  /// The language its labels are written in.
  final AppLocalizations words;
  final BuiltPlan plan;
  final double scroll, view;
  final List<BuiltIssue> issues;
  final BuiltItem? selected;
  final String? reps;

  static const _track = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final span = BuilderTimeline.span(plan);
    double tx(double worldX) => worldX / span * w;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, _track),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      track.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink,
    );
    canvas.drawRRect(
      track,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffd9f1fa), Color(0xffeef8f2)],
        ).createShader(track.outerRect),
    );
    canvas.save();
    canvas.clipRRect(track);
    // The start zone, hatched, and the sky past the line, dimmed.
    final start = tx(BuiltPlan.firstX / BuiltPlan.unit);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, start, _track),
      Paint()..color = SkyColors.ink.withValues(alpha: .1),
    );
    final hatch = Paint()
      ..color = SkyColors.ink.withValues(alpha: .1)
      ..strokeWidth = 3;
    for (var x = -_track; x < start; x += 9) {
      canvas.drawLine(Offset(x, _track), Offset(x + _track, 0), hatch);
    }
    final finish = tx(plan.finishX);
    canvas.drawRect(
      Rect.fromLTWH(finish, 0, w - finish, _track),
      Paint()..color = SkyColors.ink.withValues(alpha: .16),
    );

    double ty(int y) => 4 + y / BuiltPlan.unit * (_track - 8);
    // A push-up or squat level's two lanes.
    if (plan.mode.controlsHeight) {
      final dots = Paint()..color = SkyColors.ink.withValues(alpha: .22);
      for (final lane in const [BuiltPlan.highLane, BuiltPlan.lowLane]) {
        for (var x = start + 2; x < finish; x += 6) {
          canvas.drawCircle(Offset(x, ty(lane)), .9, dots);
        }
      }
    }
    // The selected thing stands in a yellow column.
    final picked = selected;
    if (picked != null) {
      final left = tx(picked.left / BuiltPlan.unit) - 4;
      final right = tx(picked.right / BuiltPlan.unit) + 4;
      canvas.drawRect(
        Rect.fromLTRB(left, 0, math.max(right, left + 8), _track),
        Paint()..color = SkyColors.yellow.withValues(alpha: .75),
      );
    }
    for (final item in plan.items) {
      final x = tx(item.worldX);
      final on = identical(item, picked);
      switch (item) {
        case BuiltGate gate:
          final width = math.max(4.0, tx(gate.right / BuiltPlan.unit) - x);
          final top = ty(gate.y - gate.gap ~/ 2);
          final bottom = ty(gate.y + gate.gap ~/ 2);
          final wall = Paint()
            ..color = on ? SkyColors.ink : const Color(0xff2f7d5c);
          canvas.drawRect(Rect.fromLTWH(x, 0, width, top), wall);
          canvas.drawRect(
            Rect.fromLTWH(x, bottom, width, _track - bottom),
            wall,
          );
        case BuiltStar():
          _star(canvas, Offset(x, ty(item.y)), on ? 6 : 4.8);
        case BuiltTrio():
          for (var i = -1; i <= 1; i++) {
            _star(
              canvas,
              Offset(
                tx(item.worldX + i * BuiltTrio.spacing / BuiltPlan.unit),
                ty(item.y),
              ),
              on ? 5 : 4,
            );
          }
        case BuiltHeart():
          _heart(canvas, Offset(x, ty(item.y)), on ? 6.5 : 5);
        case BuiltEnemy():
          _dot(canvas, Offset(x, ty(item.y)), SkyColors.purple, on);
      }
    }
    // The line, or the boss's mark.
    final line = Paint()
      ..color = plan.boss == null ? SkyColors.ink : SkyColors.coralDeep
      ..strokeWidth = 3;
    canvas.drawLine(Offset(finish, 0), Offset(finish, _track), line);
    if (plan.boss == null) {
      for (var j = 0; j < 4; j++) {
        canvas.drawRect(
          Rect.fromLTWH(finish + (j.isEven ? 2 : 6), 4 + j * 4.0, 4, 4),
          Paint()..color = SkyColors.ink,
        );
      }
    }
    for (final issue in issues) {
      if (issue.x == null) continue;
      final x = tx(issue.x! / BuiltPlan.unit);
      final flag = Path()
        ..moveTo(x - 5, 0)
        ..lineTo(x + 5, 0)
        ..lineTo(x, 8)
        ..close();
      canvas.drawPath(
        flag,
        Paint()..color = issue.blocking ? SkyColors.coralDeep : SkyColors.gold,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      track,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // The window the sky shows.
    if (view <= 0) {
      _labels(canvas, w, tx);
      return;
    }
    final window = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        tx(scroll).clamp(0.0, w),
        -3,
        tx(scroll + view).clamp(0.0, w),
        _track + 3,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      window,
      Paint()..color = SkyColors.yellow.withValues(alpha: .22),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );
    canvas.drawRRect(
      window,
      Paint()
        ..color = SkyColors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    _labels(canvas, w, tx);
  }

  /// Seconds from the start under the strip, and the level's length.
  void _labels(Canvas canvas, double w, double Function(double) tx) {
    final cruise = BuiltReach.cruise(plan);
    final total = BuiltReach.seconds(plan);
    final step = _step(total, w);
    final length = builtLength(plan, words);
    final label = [
      ?reps,
      plan.boss == null ? length : words.builderRouteToBoss(length),
    ].join(' · '); // l10n-ignore: a separator
    // The level's length and workout at the right end; second labels stop
    // short of it.
    final end = _text(
      canvas,
      label,
      Offset(w, _track + 5),
      right: true,
      bold: true,
      // A workout's count wears its mini game's colour.
      plate: reps == null ? SkyColors.cream : builtModeColor(plan.mode),
    );
    for (var s = 0.0; s <= total + .01; s += step) {
      final x = tx(FlightSimulation.birdX + s * cruise);
      if (x + 24 > end) break;
      _text(
        canvas,
        words.builtSeconds(s.round()),
        Offset(x, _track + 5),
        centred: true,
      );
    }
  }

  /// Seconds between labels: whole steps at least 70 pixels apart.
  static double _step(double total, double width) {
    for (final step in const <double>[5, 10, 15, 20, 30, 60, 120, 300]) {
      if (total / step * 70 <= width * .8) return step;
    }
    return 600;
  }

  static void _dot(Canvas canvas, Offset at, Color color, bool picked) {
    canvas.drawCircle(at, picked ? 5.4 : 4.4, Paint()..color = SkyColors.ink);
    canvas.drawCircle(at, picked ? 3.8 : 2.9, Paint()..color = color);
  }

  /// A star as the flight's HUD draws a small one.
  static void _star(Canvas canvas, Offset at, double radius) =>
      StarArt.mini(canvas, at, radius, outline: radius * .22);

  /// A small coral heart with an ink edge.
  static void _heart(Canvas canvas, Offset at, double r) {
    final heart = Path()
      ..moveTo(at.dx, at.dy + r * .9)
      ..cubicTo(
        at.dx - r * 1.5,
        at.dy - r * .1,
        at.dx - r * .7,
        at.dy - r * 1.2,
        at.dx,
        at.dy - r * .45,
      )
      ..cubicTo(
        at.dx + r * .7,
        at.dy - r * 1.2,
        at.dx + r * 1.5,
        at.dy - r * .1,
        at.dx,
        at.dy + r * .9,
      )
      ..close();
    canvas.drawPath(heart, Paint()..color = SkyColors.coralDeep);
    canvas.drawPath(
      heart,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  /// Writes [text] at [at]; returns where it begins.
  static double _text(
    Canvas canvas,
    String text,
    Offset at, {
    bool centred = false,
    bool right = false,
    bool bold = false,
    Color plate = SkyColors.cream,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: bodyText(
          bold ? 12.5 : 11.5,
          color: bold ? SkyColors.ink : SkyColors.muted,
          weight: FontWeight.w900,
        ).copyWith(height: 1),
      ),
      textDirection: L10n.textDirection,
    )..layout();
    var x = centred
        ? at.dx - painter.width / 2
        : right
        ? at.dx - painter.width
        : at.dx;
    if (!right) x = x.clamp(0.0, double.infinity);
    if (bold) {
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 6, at.dy - 2, painter.width + 12, painter.height + 5),
        const Radius.circular(8),
      );
      canvas.drawRRect(box, Paint()..color = plate);
      canvas.drawRRect(
        box,
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    painter.paint(canvas, Offset(x, at.dy));
    painter.dispose();
    return bold ? x - 6 : x;
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      !identical(old.words, words) ||
      !identical(old.plan, plan) ||
      old.scroll != scroll ||
      old.view != view ||
      !identical(old.selected, selected) ||
      !identical(old.issues, issues);
}
