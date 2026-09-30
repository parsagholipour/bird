import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'finish_gate_art.dart';
import 'sky_scenery.dart';

/// A visual destination for timed routes and campaign levels; it has no
/// collision or reward rules.
class ArrivalPose {
  const ArrivalPose({
    required this.x,
    required this.reveal,
    required this.arrived,
    this.finish = false,
  });
  final double x, reveal;
  final bool arrived;

  /// Whether this is a campaign level's finish line, the goal of the whole
  /// flight, drawn as [FinishGateArt]; a timed route's destination keeps the
  /// quiet pennants.
  final bool finish;
  static const approachSeconds = 6.0;

  static ArrivalPose? forFlight(FlightSimulation sim) {
    // A campaign level's finish line is a place on its route, laid beyond
    // the right edge: it scrolls in with the course and meets the bird as
    // the rules complete the level. It stays in the world after a knockout.
    if (sim.finishLine case final line?) {
      return ArrivalPose(
        x: line.x,
        reveal: 1,
        arrived: line.crossed,
        finish: true,
      );
    }
    if (!sim.timed ||
        !sim.started ||
        sim.remainingSeconds > approachSeconds ||
        (sim.phase == RunPhase.ended && sim.endReason != EndReason.completed)) {
      return null;
    }
    return ArrivalPose(
      x: FlightSimulation.birdX + sim.remainingSeconds * sim.speed,
      reveal: ((approachSeconds - sim.remainingSeconds) / .6).clamp(0, 1),
      arrived: sim.endReason == EndReason.completed,
    );
  }
}

abstract final class ArrivalArt {
  static void gate(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final pose = ArrivalPose.forFlight(sim);
    if (pose == null || pose.reveal == 0) return;
    if (pose.finish) {
      FinishGateArt.paint(
        canvas,
        h,
        x: pose.x * h,
        seconds: sim.elapsed,
        arrived: pose.arrived,
        reducedMotion: reducedMotion,
      );
      return;
    }
    final x = pose.x * h;
    final accent = SkyColors.yellow;
    final alpha = pose.reveal;
    final wave = reducedMotion ? 0.0 : math.sin(sim.elapsed * 2.3) * h * .004;
    final pen = Paint()
      ..color = SkyColors.cream.withValues(alpha: .75 * alpha)
      ..strokeWidth = h * .003
      ..strokeCap = StrokeCap.round;
    // A narrow checker ribbon reads as a finish line, leaving all heights open.
    for (var i = 0; i < 28; i++) {
      final y = h * (.17 + i * .024);
      for (var col = 0; col < 2; col++) {
        canvas.drawRect(
          Rect.fromLTWH(x + (col - 1) * h * .009, y, h * .009, h * .024),
          Paint()
            ..color = ((i + col).isEven ? accent : SkyColors.cream).withValues(
              alpha: .22 * alpha,
            ),
        );
      }
    }
    for (final top in [true, false]) {
      final y = h * (top ? .33 : .88);
      canvas.drawPath(
        Path()
          ..moveTo(x - h * .16, y)
          ..quadraticBezierTo(x, y + h * .03, x + h * .16, y),
        pen,
      );
      for (var i = 0; i < 5; i++) {
        final px = x + h * (-.135 + i * .0675);
        final py = y + h * (.012 - (i - 2).abs() * .003);
        canvas.drawPath(
          Path()
            ..moveTo(px - h * .022, py)
            ..lineTo(px + h * .022, py)
            ..lineTo(px + wave, py + h * .038)
            ..close(),
          Paint()
            ..color = [
              accent,
              SkyColors.cream,
              SkyColors.mint,
            ][i % 3].withValues(alpha: alpha),
        );
      }
    }
    final label = Rect.fromCenter(
      // Keep the destination name below the score, wings and shield HUDs.
      center: Offset(x, h * .29),
      width: h * .25,
      height: h * .058,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        label.shift(Offset(0, h * .004)),
        Radius.circular(h * .026),
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .1 * alpha),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(label, Radius.circular(h * .026)),
      Paint()..color = SkyColors.cream.withValues(alpha: alpha),
    );
    final text = TextPainter(
      text: TextSpan(
        text: 'FINISH',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w600,
          fontSize: h * .031,
          color: SkyColors.ink.withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, label.center - Offset(text.width / 2, text.height / 2));
    seal(canvas, Offset(x, h * .95), h * .028, alpha: alpha);
    if (pose.arrived) {
      // The saved replay's final frame keeps a calm, completed destination.
      final center = Offset(x + h * .12, sim.birdY * h);
      canvas.drawCircle(center, h * .034, Paint()..color = SkyColors.cream);
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - h * .014, center.dy)
          ..lineTo(center.dx - h * .003, center.dy + h * .011)
          ..lineTo(center.dx + h * .017, center.dy - h * .012),
        Paint()
          ..color = SkyColors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .006
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  static void seal(
    Canvas canvas,
    Offset center,
    double radius, {
    double alpha = 1,
  }) {
    final accent = SkyColors.yellow;
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(center.dx + side * radius * .12, center.dy + radius * .4)
          ..lineTo(center.dx + side * radius * .76, center.dy + radius * .32)
          ..lineTo(center.dx + side * radius * .96, center.dy + radius * 1.45)
          ..lineTo(center.dx + side * radius * .46, center.dy + radius * 1.2)
          ..lineTo(center.dx + side * radius * .08, center.dy + radius * 1.42)
          ..close(),
        Paint()..color = SkyColors.teal.withValues(alpha: alpha),
      );
    }
    canvas.drawCircle(
      center + Offset(0, radius * .08),
      radius,
      Paint()..color = SkyColors.ink.withValues(alpha: .15 * alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = accent.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      center,
      radius * .79,
      Paint()..color = SkyColors.cream.withValues(alpha: alpha),
    );
    canvas.drawPath(
      SkyScenery.star(center, radius * .56),
      Paint()..color = SkyColors.gold.withValues(alpha: alpha),
    );
  }
}
