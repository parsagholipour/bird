import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../domain/bird_motion.dart';
import '../domain/campaign_story.dart' show StoryMood;
import '../domain/game_rules.dart';

part 'bird_vector_paths.dart';

/// How a layer inside a bird's eye group reacts to an expression. Every eye
/// layer hides while the eyes are closed; pupils and their catchlights shrink
/// towards the pupil's centre when startled. A mood's lids cut the near and
/// far eye's own layers; [eye] belongs to both (Peaches' lashes).
enum _BirdEye {
  eye,
  nearEye,
  farEye,
  nearPupil,
  farPupil,
  nearGlint,
  farGlint;

  /// A pupil or its catchlight: what a startled or dazed face changes.
  bool get pupil => index >= nearPupil.index;

  /// Whether the layer is the near eye's (true), the far eye's (false) or
  /// both (null).
  bool? get near => switch (this) {
    nearEye || nearPupil || nearGlint => true,
    farEye || farPupil || farGlint => false,
    eye => null,
  };
}

/// A layer of the beak: the [upper] and [lower] halves part about the rig's
/// hinge to talk; a [shut] beak (Minty's bill) gives way to the rig's own
/// halves while it is open.
enum _BirdBeak { upper, lower, shut }

/// [dazed] is the knockout face: pupils give way to dizzy spirals.
enum BirdExpression { neutral, blink, pleased, startled, dazed }

class _BirdLayer {
  const _BirdLayer(
    this.path, {
    this.fill,
    this.stroke,
    this.strokeWidth = 0,
    this.roundCap = false,
    this.roundJoin = false,
    this.eye,
    this.beak,
    this.clip,
  });
  final Path path;
  final Color? fill, stroke;
  final double strokeWidth;
  final bool roundCap, roundJoin;
  final _BirdEye? eye;
  final _BirdBeak? beak;

  /// Markings are clipped to the body so they follow its outline exactly.
  final Path? clip;

  void paint(Canvas canvas) {
    if (clip case final clip?) {
      canvas.save();
      canvas.clipPath(clip);
    }
    if (fill case final color?) {
      canvas.drawPath(path, Paint()..color = color);
    }
    if (stroke case final color?) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = roundCap ? StrokeCap.round : StrokeCap.butt
          ..strokeJoin = roundJoin ? StrokeJoin.round : StrokeJoin.miter,
      );
    }
    if (clip != null) canvas.restore();
  }
}

/// One bird's artwork, compiled from its SVG in design/: the body layers, the
/// wing that rotates around [wingPivot], the face overlays each expression
/// draws with that bird's own eye placement, and the beak halves that open
/// about [beakHinge] to talk where the body's beak is a single shape.
class _BirdRig {
  const _BirdRig({
    required this.wingPivot,
    required this.beakHinge,
    required this.nearPupil,
    required this.farPupil,
    required this.body,
    required this.wing,
    required this.blink,
    required this.pleased,
    required this.startled,
    required this.upperBeak,
    required this.lowerBeak,
  });
  final Offset wingPivot, beakHinge, nearPupil, farPupil;
  final List<_BirdLayer> body, wing, blink, pleased, startled;
  final List<_BirdLayer> upperBeak, lowerBeak;
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
      if (sim.subtleStarRewards &&
          (event.kind == FlightEventKind.starTrio ||
              event.kind == FlightEventKind.streak)) {
        continue;
      }
      if (age < .5 &&
          switch (event.kind) {
            FlightEventKind.hit ||
            FlightEventKind.shieldUsed ||
            FlightEventKind.scorched ||
            FlightEventKind.rushWarning ||
            FlightEventKind.galeWarning => true,
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
            FlightEventKind.magnet ||
            FlightEventKind.milestone ||
            FlightEventKind.streak ||
            FlightEventKind.perfect ||
            FlightEventKind.sprintRing ||
            FlightEventKind.smashed ||
            FlightEventKind.meteorSmashed ||
            FlightEventKind.swarmSmashed ||
            FlightEventKind.rushEscaped ||
            FlightEventKind.galeWeathered => true,
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

/// Cached body and wing display lists of each bird's compiled vector artwork.
/// Each expression is cached per bird; wings are shared across expressions.
/// There is no path parsing or recording per frame.
abstract final class BirdPuppet {
  static final _bodies = <(int, BirdExpression), ui.Picture>{};
  static final _wings = <int, ui.Picture>{};

  static ui.Picture _recordBody(int bird, BirdExpression expression) {
    final rig = _birdRigs[bird];
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final closed = switch (expression) {
      BirdExpression.blink => rig.blink,
      BirdExpression.pleased => rig.pleased,
      _ => null,
    };
    final startled = expression == BirdExpression.startled;
    final dazed = expression == BirdExpression.dazed;
    var closedDrawn = false;
    for (final layer in rig.body) {
      if (dazed && layer.eye != null && layer.eye != _BirdEye.eye) {
        // Each pupil's place in the stack takes a spiral; glints go.
        if (layer.eye == _BirdEye.nearPupil) {
          _dizzy(canvas, rig, rig.nearPupil, 1);
        } else if (layer.eye == _BirdEye.farPupil) {
          _dizzy(canvas, rig, rig.farPupil, -1);
        }
        continue;
      }
      if (layer.eye != null && closed != null) {
        // Closed eyes take the place of the whole eye group.
        if (!closedDrawn) {
          for (final line in closed) {
            line.paint(canvas);
          }
          closedDrawn = true;
        }
        continue;
      }
      final pupilCenter = startled
          ? switch (layer.eye) {
              _BirdEye.nearPupil || _BirdEye.nearGlint => rig.nearPupil,
              _BirdEye.farPupil || _BirdEye.farGlint => rig.farPupil,
              _ => null,
            }
          : null;
      if (pupilCenter != null) {
        canvas.save();
        canvas.translate(pupilCenter.dx, pupilCenter.dy);
        canvas.scale(.63);
        canvas.translate(-pupilCenter.dx, -pupilCenter.dy);
      }
      layer.paint(canvas);
      if (pupilCenter != null) canvas.restore();
    }
    if (startled) {
      for (final brow in rig.startled) {
        brow.paint(canvas);
      }
    }
    return recorder.endRecording();
  }

  /// A dizzy spiral filling the smallest filled eye shape around [pupil]
  /// (the white, or Orbit's iris). [turn] mirrors the far eye's spiral.
  static void _dizzy(Canvas canvas, _BirdRig rig, Offset pupil, double turn) {
    Rect? eye;
    for (final layer in rig.body) {
      if (layer.eye != _BirdEye.eye || layer.fill == null) continue;
      final bounds = layer.path.getBounds();
      if (!bounds.contains(pupil)) continue;
      if (eye == null ||
          bounds.width * bounds.height < eye.width * eye.height) {
        eye = bounds;
      }
    }
    if (eye == null) return;
    final radius = eye.shortestSide / 2 * .8;
    final turns = (radius / 7.2).clamp(1.4, 2.4);
    final spiral = Path();
    const steps = 64;
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final angle = turn * (k * turns * 2 * math.pi - math.pi * .35);
      final point =
          eye.center + Offset(math.cos(angle), math.sin(angle)) * radius * k;
      i == 0
          ? spiral.moveTo(point.dx, point.dy)
          : spiral.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      spiral,
      Paint()
        ..color = const Color(0xff203b45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static ui.Picture _recordWing(int bird) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final layer in _birdRigs[bird].wing) {
      layer.paint(canvas);
    }
    return recorder.endRecording();
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
    ), () => _recordBody(bird, expression));
    final wingPicture = _wings.putIfAbsent(bird, () => _recordWing(bird));
    final pivot = _birdRigs[bird].wingPivot;
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    canvas.scale(bounds.width / 256, bounds.height / 224);
    canvas.drawPicture(body);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(wing);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawPicture(wingPicture);
    canvas.restore();
  }
}
