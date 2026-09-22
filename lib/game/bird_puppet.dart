import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../domain/bird_motion.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';

part 'bird_vector_paths.dart';

enum _BirdTone { primary, secondary, cream, ink, coralDeep, coral, white }

enum _BirdEye {
  farEye,
  nearEye,
  nearPupil,
  farPupil,
  nearCatchlight,
  farCatchlight,
}

enum BirdExpression { neutral, blink, pleased, startled }

class _BirdLayer {
  const _BirdLayer(
    this.path, {
    this.fill,
    this.stroke,
    this.strokeWidth = 0,
    this.roundCap = false,
    this.roundJoin = false,
    this.wing = false,
    this.eye,
  });
  final Path path;
  final _BirdTone? fill, stroke;
  final double strokeWidth;
  final bool roundCap, roundJoin, wing;
  final _BirdEye? eye;
}

/// Visual pose derived only from replayable simulation state. It never changes
/// the collision circle, movement, score, or tracking input.
class BirdPose {
  const BirdPose({
    this.wing = 0,
    this.tilt = 0,
    this.spring = 0,
    this.flapWake = 0,
    this.expression = BirdExpression.neutral,
  });
  final double wing, tilt, spring, flapWake;
  final BirdExpression expression;

  static BirdPose forFlight(
    FlightSimulation simulation, {
    required bool reducedMotion,
    int bird = 0,
  }) {
    if (reducedMotion || !simulation.started) return const BirdPose();
    final expression = _expression(simulation, bird);
    if (simulation.rules.mode.controlsHeight) {
      // Raising the body presses the wing down; lowering opens it for the next
      // stroke. Using height keeps each calibrated endpoint stable and readable.
      final range = ((simulation.birdY - .15) / .70).clamp(0.0, 1.0);
      return BirdPose(wing: -.42 + range * 1.02, expression: expression);
    }
    final sinceFlap = simulation.elapsed - simulation.lastFlapAt;
    final t = (sinceFlap / .38).clamp(0.0, 1.0);
    final stroke = sinceFlap >= 0 && sinceFlap < .38
        ? -math.sin(t * math.pi * 2) * (1 - t) * .70
        : 0.0;
    final glide = simulation.gliding
        ? math
              .min(
                simulation.glideRemaining / .2,
                simulation.velocity / FlightSimulation.glideFallSpeed,
              )
              .clamp(0.0, 1.0)
        : 0.0;
    return BirdPose(
      expression: expression,
      wing: .10 + stroke - .48 * glide,
      tilt: BirdFlightMotion.tilt(simulation.velocity),
      spring: BirdFlightMotion.spring(sinceFlap),
      flapWake: sinceFlap >= 0 && sinceFlap < .32 ? sinceFlap / .32 : 0,
    );
  }

  static BirdExpression _expression(FlightSimulation sim, int bird) {
    if (sim.phase == RunPhase.ended) {
      return switch (sim.endReason) {
        EndReason.completed => BirdExpression.pleased,
        EndReason.collision => BirdExpression.startled,
        _ => BirdExpression.neutral,
      };
    }
    var pleased = false;
    for (final event in sim.events.reversed) {
      final age = sim.elapsed - event.at;
      if (age < 0) continue;
      if (age < .5 &&
          switch (event.kind) {
            FlightEventKind.hit ||
            FlightEventKind.shieldUsed ||
            FlightEventKind.letterLost => true,
            _ => false,
          }) {
        return BirdExpression.startled;
      }
      if (age < .7 &&
          switch (event.kind) {
            FlightEventKind.starTrio ||
            FlightEventKind.enemyHit ||
            FlightEventKind.enemyRammed ||
            FlightEventKind.bossDefeated ||
            FlightEventKind.heart ||
            FlightEventKind.delivery ||
            FlightEventKind.letter ||
            FlightEventKind.cloudFriend ||
            FlightEventKind.magnet ||
            FlightEventKind.milestone ||
            FlightEventKind.streak ||
            FlightEventKind.perfect => true,
            _ => false,
          }) {
        pleased = true;
      }
    }
    if (pleased) return BirdExpression.pleased;
    // A short, staggered blink feels alive without an independent animation clock.
    return sim.elapsed > 2 && (sim.elapsed + bird * .61) % 4.8 < .13
        ? BirdExpression.blink
        : BirdExpression.neutral;
  }
}

/// Cached body and wing display lists preserve the original vector geometry.
/// Each expression is cached per bird; wings are shared across expressions.
/// There is no path parsing or recording per frame.
abstract final class BirdPuppet {
  static final _bodies = <(int, BirdExpression), ui.Picture>{};
  static final _wings = <int, ui.Picture>{};

  static Color _color(_BirdTone tone, int bird) => switch (tone) {
    _BirdTone.primary => [
      SkyColors.yellow,
      SkyColors.coral,
      SkyColors.mint,
      SkyColors.lavender,
    ][bird],
    _BirdTone.secondary => [
      SkyColors.gold,
      SkyColors.coralDeep,
      SkyColors.teal,
      SkyColors.purple,
    ][bird],
    _BirdTone.cream => SkyColors.cream,
    _BirdTone.ink => SkyColors.ink,
    _BirdTone.coralDeep => SkyColors.coralDeep,
    _BirdTone.coral => SkyColors.coral,
    _BirdTone.white => SkyColors.white,
  };

  static ui.Picture _record(
    int bird,
    bool wing, [
    BirdExpression expression = BirdExpression.neutral,
  ]) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final layer in _birdLayers.where((layer) => layer.wing == wing)) {
      if (layer.eye != null &&
          (expression == BirdExpression.blink ||
              expression == BirdExpression.pleased)) {
        if (layer.eye == _BirdEye.farEye) _closedEyes(canvas, expression);
        continue;
      }
      final pupilCenter = expression == BirdExpression.startled
          ? switch (layer.eye) {
              _BirdEye.nearPupil ||
              _BirdEye.nearCatchlight => const Offset(146.5, 96.5),
              _BirdEye.farPupil ||
              _BirdEye.farCatchlight => const Offset(179, 96),
              _ => null,
            }
          : null;
      if (pupilCenter != null) {
        canvas.save();
        canvas.translate(pupilCenter.dx, pupilCenter.dy);
        canvas.scale(.63);
        canvas.translate(-pupilCenter.dx, -pupilCenter.dy);
      }
      if (layer.fill case final tone?) {
        canvas.drawPath(layer.path, Paint()..color = _color(tone, bird));
      }
      if (layer.stroke case final tone?) {
        canvas.drawPath(
          layer.path,
          Paint()
            ..color = _color(tone, bird)
            ..style = PaintingStyle.stroke
            ..strokeWidth = layer.strokeWidth
            ..strokeCap = layer.roundCap ? StrokeCap.round : StrokeCap.butt
            ..strokeJoin = layer.roundJoin
                ? StrokeJoin.round
                : StrokeJoin.miter,
        );
      }
      if (pupilCenter != null) canvas.restore();
    }
    if (!wing && expression == BirdExpression.startled) {
      canvas.drawPath(
        Path()
          ..moveTo(122, 62)
          ..quadraticBezierTo(132, 55, 144, 58)
          ..moveTo(166, 65)
          ..quadraticBezierTo(175, 60, 183, 66),
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
    return recorder.endRecording();
  }

  static void _closedEyes(Canvas canvas, BirdExpression expression) {
    final happy = expression == BirdExpression.pleased;
    canvas.drawPath(
      Path()
        ..moveTo(121, 98)
        ..quadraticBezierTo(138, happy ? 78 : 109, 155, 98)
        ..moveTo(164, 96)
        ..quadraticBezierTo(174, happy ? 83 : 103, 184, 96),
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
  }

  static void paint(
    Canvas canvas,
    Rect bounds, {
    required int bird,
    required double wing,
    BirdExpression expression = BirdExpression.neutral,
  }) {
    final body = _bodies.putIfAbsent((
      bird,
      expression,
    ), () => _record(bird, false, expression));
    final wingPicture = _wings.putIfAbsent(bird, () => _record(bird, true));
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    canvas.scale(bounds.width / 256, bounds.height / 224);
    canvas.drawPicture(body);
    canvas.translate(95, 122);
    canvas.rotate(wing);
    canvas.translate(-95, -122);
    canvas.drawPicture(wingPicture);
    canvas.restore();
  }
}
