import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'story_cast_art.dart';
import 'story_speech.dart';
import 'theme.dart';

/// Where everything in a story scene goes on a stage of a given size: the
/// speech panel along the foot, and the cast along its top edge, which is
/// the floor they stand on.
///
/// The courier stands on the left. With only Postmaster Bill to talk to,
/// Bill faces it from the right; at a lair the boss takes the right and
/// Bill backs the courier up from the far left. Safe-area insets move the
/// panel in, and the cast with it.
final class StoryLayout {
  StoryLayout(this.stage, EdgeInsets safe, {required this.lair})
    : panel = _panel(stage, safe),
      skipTop = math.max(10.0, safe.top + 4),
      skipRight = math.max(14.0, safe.right + 8);

  /// The stage's size in its own units: 360 high on a phone.
  final Size stage;

  /// Whether a boss shares the stage.
  final bool lair;
  final Rect panel;
  final double skipTop, skipRight;

  /// The widest the speech panel grows on a broad screen.
  static const maxPanel = 720.0;

  static Rect _panel(Size stage, EdgeInsets safe) {
    final left = math.max(16.0, safe.left + 8);
    final right = stage.width - math.max(16.0, safe.right + 8);
    final width = math.min(right - left, maxPanel);
    final bottom = stage.height - math.max(10.0, safe.bottom + 4);
    return Rect.fromLTWH(
      (left + right - width) / 2,
      bottom - StorySpeech.height,
      width,
      StorySpeech.height,
    );
  }

  /// The line the cast stands on: the panel's top edge.
  double get floor => panel.top;

  /// Each character's place along the floor.
  double get courier => lair
      ? panel.left + math.max(236, panel.width * .36)
      : panel.left + math.max(120, panel.width * .23);
  double get postmaster =>
      lair ? panel.left + 76 : panel.right - math.max(122, panel.width * .23);
  double get boss => panel.right - 138;

  /// Where [actor] stands.
  double placeOf(StoryActor actor) => switch (actor) {
    StoryCourier() => courier,
    StoryPostmaster() => postmaster,
    StoryBoss() => boss,
  };

  /// The left edge of a name tag [width] wide, centred under a speaker at
  /// [x] but kept on the panel.
  double tagLeft(double x, double width) => (x - width / 2).clamp(
    panel.left + 10,
    math.max(panel.left + 10, panel.right - 10 - width),
  );
}

/// One character on the stage for one frame.
typedef StoryPlacement = ({
  StoryActor actor,

  /// Its place along the floor.
  double x,

  /// 1 while it is the one talking, 0 while it listens.
  double voice,

  /// 0 before it has come on, 1 once it has.
  double presence,
  StoryFace face,

  /// Pixels it is lifted off the floor by a hop or a hover.
  double lift,

  /// A squash along its height as it breathes or bounces (1 is none).
  double squash,
});

/// Paints the cast along the floor. Whoever is talking stands a little
/// taller in a pool of light, up on its name tag; listeners step back into
/// the shade of the scene.
class StoryStagePainter extends CustomPainter {
  const StoryStagePainter({required this.cast, required this.floor});
  final List<StoryPlacement> cast;
  final double floor;

  /// How far the talker stands above the floor, on its name tag.
  static const step = StoryNameTag.height / 2 + 5;

  @override
  void paint(Canvas canvas, Size size) {
    // A pool of warm light behind whoever is talking.
    for (final p in cast) {
      final glow = p.voice * p.presence;
      if (glow <= .01) continue;
      final box = p.actor.box;
      final at = Offset(p.x + box.center.dx * .35, floor - p.actor.heart);
      final radius = math.min(box.shortestSide * .78, 150.0);
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              SkyColors.cream.withValues(alpha: .46 * glow),
              SkyColors.cream.withValues(alpha: .16 * glow),
              SkyColors.cream.withValues(alpha: 0),
            ],
            stops: const [0, .55, 1],
          ).createShader(Rect.fromCircle(center: at, radius: radius)),
      );
    }
    // Bosses stand behind the birds, and whoever is talking in front.
    final order = [...cast]
      ..sort((a, b) {
        if (a.actor.perched != b.actor.perched) return a.actor.perched ? 1 : -1;
        return a.voice.compareTo(b.voice);
      });
    for (final p in order) {
      if (p.presence <= 0) continue;
      final actor = p.actor, box = actor.box;
      final away = 1 - Curves.easeOutBack.transform(p.presence.clamp(0, 1));
      canvas.save();
      if (actor.perched) {
        // It pops up from behind the panel, and stands on its name tag
        // while it talks.
        canvas.translate(
          p.x,
          floor + 2 - step * p.voice - p.lift + away * box.height * .7,
        );
      } else {
        canvas.translate(p.x + away * 110, floor - p.lift);
      }
      final scale = lerpDouble(actor.perched ? .9 : .95, 1, p.voice)!;
      canvas.scale(scale, scale * p.squash);
      final shade = 1 - p.voice;
      if (shade > .01) {
        canvas.saveLayer(box.inflate(6), Paint()..colorFilter = _shade(shade));
      }
      actor.paint(canvas, p.face);
      if (shade > .01) canvas.restore();
      canvas.restore();
    }
    // Whatever reaches below the floor sinks into the dark at the foot of
    // the scene, so nothing peeks out round the panel.
    final foot = Rect.fromLTRB(0, floor + 6, size.width, size.height);
    canvas.drawRect(
      foot,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SkyColors.ink.withValues(alpha: 0),
            SkyColors.ink.withValues(alpha: .8),
          ],
          stops: const [0, .7],
        ).createShader(foot),
    );
  }

  /// Steps a listener back into a light, cool shade, by [t] (0 to 1). It
  /// stays gentle, so yellow never turns to mustard and Bill stays white.
  static ColorFilter _shade(double t) {
    final r = 1 - .13 * t, g = 1 - .12 * t, b = 1 - .06 * t;
    return ColorFilter.matrix([
      r, 0, 0, 0, 0, //
      0, g, 0, 0, 0, //
      0, 0, b, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  bool shouldRepaint(StoryStagePainter old) =>
      old.floor != floor || !_same(old.cast, cast);

  static bool _same(List<StoryPlacement> a, List<StoryPlacement> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
