import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import '../domain/sky_boss.dart' show BossKind;
import '../game/bird_puppet.dart';
import 'story_boss_art.dart';
import 'story_postmaster_art.dart';
import 'theme.dart';

/// One frame of a character's face: the mood of its line, how far its mouth
/// is open (0 shut to [StoryFaces.mouths]) and whether it is mid-blink.
///
/// A talking character steps through a few such frames rather than moving
/// freely, so each frame's art is recorded once and replayed.
typedef StoryFace = ({StoryMood mood, int mouth, bool blink});

/// The frames a face can show.
abstract final class StoryFaces {
  /// The widest a mouth opens.
  static const mouths = 2;
}

/// Someone on the stage of a story scene: the courier, Postmaster Bill or a
/// boss. The stage gives each a place on its floor line; [box] is what the
/// art covers from there, in pixels on a 360-high stage, and [paint] draws
/// it around that place.
sealed class StoryActor {
  const StoryActor();

  /// The art's reach around the actor's place on the floor line.
  Rect get box;

  /// How far above the floor line the actor's middle is, for the light
  /// behind whoever is talking.
  double get heart;

  /// Whether the actor stands on the floor line (the birds) rather than
  /// hovering over it or rising from behind it (the bosses).
  bool get perched;

  /// Paints the actor with its place on the floor line at the origin.
  void paint(Canvas canvas, StoryFace face);
}

/// The player's equipped bird.
final class StoryCourier extends StoryActor {
  const StoryCourier(this.bird);
  final int bird;

  /// Pixels per unit of the birds' 256-wide art.
  static const scale = .62;

  /// Where each bird's feet touch down in its art.
  static const _perch = [
    Offset(126, 204),
    Offset(124, 206),
    Offset(138, 203),
    Offset(126, 217),
  ];

  @override
  Rect get box => Rect.fromLTWH(
    -_perch[bird].dx * scale,
    -_perch[bird].dy * scale,
    256 * scale,
    224 * scale,
  );

  @override
  double get heart => 100 * scale;

  @override
  bool get perched => true;

  @override
  void paint(Canvas canvas, StoryFace face) {
    final mood = face.mood;
    final expression = face.blink
        ? BirdExpression.blink
        : switch (mood) {
            StoryMood.happy => BirdExpression.pleased,
            StoryMood.surprised => BirdExpression.startled,
            _ => BirdExpression.neutral,
          };
    // The wing says what the beak cannot: up when glad or startled, and a
    // little flick with every syllable.
    final lift = switch (mood) {
      StoryMood.happy => -.42,
      StoryMood.surprised => -.62,
      StoryMood.angry => -.2,
      StoryMood.sad => .3,
      StoryMood.plain => .08,
    };
    canvas.save();
    canvas.translate(box.left, box.top);
    canvas.scale(scale);
    BirdPuppet.paint(
      canvas,
      const Rect.fromLTWH(0, 0, 256, 224),
      bird: bird,
      wing: lift - face.mouth * .3,
      expression: expression,
    );
    if (!face.blink) _brows(canvas, mood);
    if (mood == StoryMood.sad || mood == StoryMood.surprised) {
      _drop(canvas, mood == StoryMood.sad);
    }
    canvas.restore();
  }

  // Every bird's eyes sit in the same place in its art.
  static const _near = Offset(146.5, 96), _far = Offset(179, 95.5);

  /// Brows over the eyes: drawn down in a frown, or tipped up in worry.
  void _brows(Canvas c, StoryMood mood) {
    final tilt = switch (mood) {
      StoryMood.angry => 1.0,
      StoryMood.sad => -1.0,
      _ => 0.0,
    };
    if (tilt == 0) return;
    // Orbit's eyes sit a little higher, inside the facial disc.
    final up = bird == 3 ? 4.0 : 0.0;
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = tilt > 0 ? 6.5 : 5
      ..strokeCap = StrokeCap.round;
    if (tilt > 0) {
      // A frown presses down on the eyes.
      c.drawLine(
        _near + Offset(-17, -31.6 - up),
        _near + Offset(15, -14 - up),
        ink,
      );
      c.drawLine(
        _far + Offset(13, -26.5 - up),
        _far + Offset(-9, -12.2 - up),
        ink,
      );
    } else {
      // Worry floats above them, highest between the eyes.
      c.drawLine(
        _near + Offset(-13, -32 - up),
        _near + Offset(11, -39 - up),
        ink,
      );
      c.drawLine(_far + Offset(-7, -33 - up), _far + Offset(11, -27 - up), ink);
    }
  }

  /// A drop by the brow: a tear of worry, or the sweat of a start.
  void _drop(Canvas c, bool sad) {
    final at = sad ? const Offset(112, 62) : const Offset(104, 50);
    final drop = Path()
      ..moveTo(at.dx, at.dy - 13)
      ..cubicTo(at.dx + 10, at.dy, at.dx + 8, at.dy + 10, at.dx, at.dy + 10)
      ..cubicTo(at.dx - 8, at.dy + 10, at.dx - 10, at.dy, at.dx, at.dy - 13)
      ..close();
    c.drawPath(drop, Paint()..color = const Color(0xff9fe0f2));
    c.drawPath(
      drop,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawLine(
      at + const Offset(-2.5, 1),
      at + const Offset(-2.5, 4),
      Paint()
        ..color = SkyColors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool operator ==(Object other) => other is StoryCourier && other.bird == bird;

  @override
  int get hashCode => bird.hashCode;
}

/// Postmaster Bill. He faces right, like the birds, unless [facingLeft].
final class StoryPostmaster extends StoryActor {
  const StoryPostmaster({this.facingLeft = false});
  final bool facingLeft;

  static const _scale = StoryCourier.scale;
  static const _size = StoryPostmasterArt.size;
  static const _perch = StoryPostmasterArt.perch;

  @override
  Rect get box {
    final left = facingLeft ? _perch.dx - _size.width : -_perch.dx;
    return Rect.fromLTWH(
      left * _scale,
      -_perch.dy * _scale,
      _size.width * _scale,
      _size.height * _scale,
    );
  }

  @override
  double get heart => 150 * _scale;

  @override
  bool get perched => true;

  @override
  void paint(Canvas canvas, StoryFace face) {
    final picture = _StoryPictures.of((StoryPostmaster, face), (c) {
      StoryPostmasterArt.paint(
        c,
        mood: face.mood,
        open: face.mouth / StoryFaces.mouths,
        blink: face.blink ? 1 : 0,
        // He talks with his wing as well as his bill.
        wing:
            face.mouth * .09 +
            switch (face.mood) {
              StoryMood.happy => .5,
              StoryMood.surprised => .8,
              _ => 0,
            },
      );
    });
    canvas.save();
    canvas.scale(facingLeft ? -_scale : _scale, _scale);
    canvas.translate(-_perch.dx, -_perch.dy);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  bool operator ==(Object other) =>
      other is StoryPostmaster && other.facingLeft == facingLeft;

  @override
  int get hashCode => facingLeft.hashCode;
}

/// A scene's boss; [beaten] in the scene after its fall.
final class StoryBoss extends StoryActor {
  const StoryBoss(this.kind, {this.beaten = false});
  final BossKind kind;
  final bool beaten;

  @override
  Rect get box {
    final (:unit, :origin, :reach) = StoryBossArt.portrait(
      kind,
      beaten: beaten,
    );
    return Rect.fromLTRB(
      origin.dx + reach.left * unit,
      origin.dy + reach.top * unit,
      origin.dx + reach.right * unit,
      origin.dy + reach.bottom * unit,
    );
  }

  @override
  double get heart => -StoryBossArt.portrait(kind, beaten: beaten).origin.dy;

  @override
  bool get perched => false;

  @override
  void paint(Canvas canvas, StoryFace face) {
    final (:unit, :origin, reach: _) = StoryBossArt.portrait(
      kind,
      beaten: beaten,
    );
    final picture = _StoryPictures.of((kind, beaten, face), (c) {
      StoryBossArt.paint(
        c,
        kind,
        face.mood,
        beaten: beaten,
        talk: face.mouth / StoryFaces.mouths,
        blink: face.blink ? 1 : 0,
      );
    });
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(unit);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  bool operator ==(Object other) =>
      other is StoryBoss && other.kind == kind && other.beaten == beaten;

  @override
  int get hashCode => Object.hash(kind, beaten);
}

/// Recorded frames of the cast, newest kept: a rig is built into paths once
/// per frame of a face, and replayed from then on.
abstract final class _StoryPictures {
  static final _pictures = <Object, ui.Picture>{};
  static const _keep = 40;

  static ui.Picture of(Object key, void Function(Canvas canvas) draw) {
    final cached = _pictures.remove(key);
    if (cached != null) return _pictures[key] = cached;
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = _pictures[key] = recorder.endRecording();
    while (_pictures.length > _keep) {
      _pictures.remove(_pictures.keys.first)!.dispose();
    }
    return picture;
  }
}
