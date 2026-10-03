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
/// hinge to talk; a [shut] beak (a one-piece bill, which the generator still
/// supports though no bird draws one now) gives way to the rig's own halves
/// while it is open.
// ignore: unused_field
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
            FlightEventKind.allRings ||
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
/// Each face (an expression, or the mood of a line being said) is cached per
/// bird and beak frame; wings are shared across faces. There is no path
/// parsing or recording per frame, and never more than [debugMaxBodies]
/// bodies.
abstract final class BirdPuppet {
  /// A talking beak's frames: 0 shut to [beaks] wide, the steps a line's
  /// mouth takes in flight (FlightSpeech.mouths).
  static const beaks = 3;

  static final _bodies = <(int, BirdExpression, StoryMood?, int), ui.Picture>{};
  static final _wings = <int, ui.Picture>{};

  /// How many bodies are cached, and the most there can be: each bird's five
  /// expressions and four talking moods, at every beak frame.
  static int get debugCachedBodies => _bodies.length;
  static const debugMaxBodies = 4 * (5 + 4) * (beaks + 1);

  static const _ink = Color(0xff203b45);

  static ui.Picture _recordBody(
    int bird,
    BirdExpression expression,
    StoryMood? mood,
    int beak,
  ) {
    final rig = _birdRigs[bird];
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final closed = mood == StoryMood.happy
        ? _bold(rig.pleased, 6.5)
        : switch (expression) {
            BirdExpression.blink => rig.blink,
            BirdExpression.pleased => rig.pleased,
            _ => null,
          };
    final startled =
        expression == BirdExpression.startled || mood == StoryMood.surprised;
    final dazed = expression == BirdExpression.dazed;
    final lids = _lids(mood);
    final whites = (near: _white(rig, true), far: _white(rig, false));
    // Sorrow looks at the ground.
    final sink = mood == StoryMood.sad ? 7.0 : 0.0;
    var closedDrawn = false, beakDrawn = false;
    for (final layer in rig.body) {
      if (beak > 0 && layer.beak != null) {
        // The whole beak opens in the place of its first layer.
        if (!beakDrawn) _openBeak(canvas, bird, beak, mood);
        beakDrawn = true;
        continue;
      }
      if (dazed && layer.eye != null && layer.eye!.pupil) {
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
      final near = layer.eye?.near;
      final white = near == null ? null : (near ? whites.near : whites.far);
      final lid = lids == null || near == null
          ? null
          : near
          ? lids.near
          : lids.far;
      // The pupil, its catchlight and Orbit's iris: what sorrow lowers.
      final inner =
          white != null &&
          (layer.eye!.pupil || layer.path.getBounds() != white);
      canvas.save();
      if (lid != null) canvas.clipPath(_below(lid));
      if (white != null && mood == StoryMood.surprised) {
        // Eyes popped wide.
        canvas.translate(white.center.dx, white.center.dy);
        canvas.scale(1.08);
        canvas.translate(-white.center.dx, -white.center.dy);
      }
      if (inner && sink > 0) canvas.translate(0, sink);
      if (pupilCenter != null) {
        canvas.translate(pupilCenter.dx, pupilCenter.dy);
        canvas.scale(.63);
        canvas.translate(-pupilCenter.dx, -pupilCenter.dy);
      }
      layer.paint(canvas);
      canvas.restore();
    }
    if (mood == StoryMood.surprised) {
      // Brows thrown high and heavy enough to read at flight size.
      canvas.save();
      canvas.translate(0, -4);
      for (final brow in _bold(rig.startled, 7)) {
        brow.paint(canvas);
      }
      canvas.restore();
    } else if (startled) {
      for (final brow in rig.startled) {
        brow.paint(canvas);
      }
    }
    if (lids != null) _cutLids(canvas, whites, lids);
    _brows(canvas, bird, mood);
    if (mood == StoryMood.sad || mood == StoryMood.surprised) {
      _drop(canvas, sad: mood == StoryMood.sad);
    }
    return recorder.endRecording();
  }

  /// [lines] stroked [width] wide.
  static List<_BirdLayer> _bold(List<_BirdLayer> lines, double width) => [
    for (final line in lines)
      _BirdLayer(
        line.path,
        stroke: line.stroke,
        strokeWidth: width,
        roundCap: true,
        roundJoin: true,
      ),
  ];

  // The talking moods' faces, in the 256 × 224 art whose eyes every bird
  // shares (the near eye round (138.5, 93), the far one round (174, 94)).
  // A lid is a line each eye shows below: drawn down toward the beak in
  // anger, and down at the outer corner in sorrow. The brows follow the
  // story's (StoryCourier), drawn heavier so they read at flight size.

  static ({(Offset, Offset) near, (Offset, Offset) far})? _lids(
    StoryMood? mood,
  ) => switch (mood) {
    StoryMood.angry => (
      near: (const Offset(108, 61), const Offset(168, 92)),
      far: (const Offset(198, 67), const Offset(152, 92)),
    ),
    StoryMood.sad => (
      near: (const Offset(108, 91), const Offset(168, 61)),
      far: (const Offset(148, 67), const Offset(198, 93)),
    ),
    _ => null,
  };

  /// Everything below the line from [lid]'s first point to its second.
  static Path _below((Offset, Offset) lid) {
    final (a, b) = lid;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(b.dx, 224)
      ..lineTo(a.dx, 224)
      ..close();
  }

  /// The edge of each lid where it crosses its eye.
  static void _cutLids(
    Canvas canvas,
    ({Rect? near, Rect? far}) whites,
    ({(Offset, Offset) near, (Offset, Offset) far}) lids,
  ) {
    final edge = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;
    for (final (eye, (a, b)) in [
      (whites.near, lids.near),
      (whites.far, lids.far),
    ]) {
      if (eye == null) continue;
      canvas.save();
      // Out to the outline's own edge, so the cut meets it cleanly.
      canvas.clipPath(Path()..addOval(eye.inflate(2)));
      canvas.drawLine(a, b, edge);
      canvas.restore();
    }
  }

  /// The bounds of the near or far eye's white.
  static Rect? _white(_BirdRig rig, bool near) {
    Rect? white;
    for (final layer in rig.body) {
      if (layer.eye?.near != near || layer.eye!.pupil || layer.fill == null) {
        continue;
      }
      final bounds = layer.path.getBounds();
      if (white == null ||
          bounds.width * bounds.height > white.width * white.height) {
        white = bounds;
      }
    }
    return white;
  }

  /// Brows over the eyes: drawn down hard in anger, tipped up in sorrow.
  static void _brows(Canvas canvas, int bird, StoryMood? mood) {
    final brows = switch (mood) {
      StoryMood.angry => (
        near: (const Offset(124, 66), const Offset(165, 87)),
        far: (const Offset(189, 68), const Offset(158, 85)),
        width: 9.0,
      ),
      StoryMood.sad => (
        near: (const Offset(126, 64), const Offset(155, 50)),
        far: (const Offset(170, 56), const Offset(193, 67)),
        width: 8.0,
      ),
      _ => null,
    };
    if (brows == null) return;
    // Orbit's brows sit a little higher, inside the facial disc.
    final up = Offset(0, bird == 3 ? -3 : 0);
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = brows.width
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in [brows.near, brows.far]) {
      canvas.drawLine(a + up, b + up, ink);
    }
  }

  /// The story's drop (StoryCourier): the sweat of a start by the brow, or
  /// a tear, which in flight runs from the eye so it reads at that size.
  static void _drop(Canvas canvas, {required bool sad}) {
    final at = sad ? const Offset(117, 121) : const Offset(104, 48);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(1.3);
    final drop = Path()
      ..moveTo(0, -13)
      ..cubicTo(10, 0, 8, 10, 0, 10)
      ..cubicTo(-8, 10, -10, 0, 0, -13)
      ..close();
    canvas.drawPath(drop, Paint()..color = const Color(0xff9fe0f2));
    canvas.drawPath(
      drop,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      const Offset(-2.5, 1),
      const Offset(-2.5, 4),
      Paint()
        ..color = const Color(0xffffffff)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  /// How each bird's beak opens wide: the radians its lower half drops and
  /// its upper half lifts about the rig's hinge, and the mouth inside: the
  /// heading of the line the halves close on, and how deep it reaches.
  static const _gapes = [
    (drop: .5, lift: .15, line: .13, depth: 33.0), // Pip
    (drop: .45, lift: .22, line: .25, depth: 24.0), // Peaches
    (drop: .4, lift: .16, line: .14, depth: 46.0), // Minty
    (drop: .55, lift: .24, line: .45, depth: 20.0), // Orbit
  ];

  /// How far each beak frame opens, of wide: a first frame that already
  /// reads, not a third of the way.
  static const _opens = [0.0, .45, .75, 1.0];

  static const _throat = Color(0xff5c1a2e), _tongue = Color(0xffe8607a);

  /// The beak parted to [beak] (1 to [beaks]): the mouth inside, then the
  /// lower half dropped and the upper half lifted about the hinge. A shy
  /// line opens it less, a glad or startled one more.
  static void _openBeak(Canvas canvas, int bird, int beak, StoryMood? mood) {
    final rig = _birdRigs[bird];
    final gape = _gapes[bird];
    final open =
        _opens[beak.clamp(0, beaks)] *
        switch (mood) {
          StoryMood.happy => 1.1,
          StoryMood.surprised => 1.25,
          StoryMood.sad => .7,
          _ => 1.0,
        };
    final hinge = rig.beakHinge;
    final drop = gape.drop * open, lift = gape.lift * open;
    // A wedge from the hinge, under both halves: only the gap between them
    // shows it.
    final mouth = Path()
      ..moveTo(hinge.dx, hinge.dy)
      ..arcTo(
        Rect.fromCircle(center: hinge, radius: gape.depth),
        gape.line - lift - .08,
        drop + lift + .16,
        false,
      )
      ..close();
    canvas.drawPath(mouth, Paint()..color = _throat);
    canvas.save();
    canvas.clipPath(mouth);
    // The tongue lies on the lower half, mostly under it.
    canvas.save();
    canvas.translate(hinge.dx, hinge.dy);
    canvas.rotate(gape.line + drop);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(gape.depth * .5, gape.depth * .04),
        width: gape.depth * .62,
        height: gape.depth * .3,
      ),
      Paint()..color = _tongue,
    );
    canvas.restore();
    canvas.restore();
    canvas.drawPath(
      mouth,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    // The rig's own halves, where it has them, take the place of the body's.
    void half(_BirdBeak part, List<_BirdLayer> rigged, double turn) {
      canvas.save();
      canvas.translate(hinge.dx, hinge.dy);
      canvas.rotate(turn);
      canvas.translate(-hinge.dx, -hinge.dy);
      for (final layer
          in rigged.isEmpty
              ? rig.body.where((layer) => layer.beak == part)
              : rigged) {
        layer.paint(canvas);
      }
      canvas.restore();
    }

    half(_BirdBeak.lower, rig.lowerBeak, drop);
    half(_BirdBeak.upper, rig.upperBeak, -lift);
  }

  /// A dizzy spiral filling the smallest filled eye shape around [pupil]
  /// (the white, or Orbit's iris). [turn] mirrors the far eye's spiral.
  static void _dizzy(Canvas canvas, _BirdRig rig, Offset pupil, double turn) {
    Rect? eye;
    for (final layer in rig.body) {
      if (layer.eye == null || layer.eye!.pupil || layer.fill == null) {
        continue;
      }
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

  /// Paints [bird] into [bounds] (its 256 × 224 art), the wing turned by
  /// [wing] radians. While the bird is saying a line, [mood] is its mood and
  /// [beak] how far the words open its beak, 0 to [beaks]: a plain line keeps
  /// [expression] on the face, any other mood sets the eyes (unless dazed).
  static void paint(
    Canvas canvas,
    Rect bounds, {
    required int bird,
    required double wing,
    BirdExpression expression = BirdExpression.neutral,
    StoryMood? mood,
    int beak = 0,
  }) {
    final eyes = mood == StoryMood.plain || expression == BirdExpression.dazed
        ? null
        : mood;
    final face = eyes == null ? expression : BirdExpression.neutral;
    final open = beak.clamp(0, beaks);
    final body = _bodies.putIfAbsent((
      bird,
      face,
      eyes,
      open,
    ), () => _recordBody(bird, face, eyes, open));
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
