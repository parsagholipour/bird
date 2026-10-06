import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/game_rules.dart';
import '../../domain/tracking.dart';
import '../../game/bird_puppet.dart';
import '../../game/door_art.dart';
import '../../game/enemy_art.dart';
import '../../game/finish_gate_art.dart';
import '../../game/heart_pickup_art.dart';
import '../../game/obstacle_art.dart';
import '../../game/star_art.dart';
import '../theme.dart';
import 'builder_chrome.dart' show BossPortraitPainter;

/// The editor's pictures of what a level holds, painted with the flight's
/// own art so a level looks in the editor as it will in the sky. Everything
/// is drawn in pixels of a sky [h] tall, as the flight draws it: a world
/// position x shows at `x * h` from the canvas's left edge.
abstract final class BuilderArt {
  /// The flight's obstacle for [gate] with its leading edge at [x] (sky
  /// heights from the canvas's left edge), held at its swing on arrival.
  static Obstacle obstacle(BuiltGate gate, PlayMode mode, double x) {
    final y = gate.y / BuiltPlan.unit;
    return Obstacle(
      x: x,
      center: y,
      gap: gate.gap / BuiltPlan.unit,
      width: gate.kind.width,
      target: BuiltPlan.laneTarget(mode, y),
      fixedTarget: mode.controlsHeight,
      kind: gate.kind,
      amplitude: gate.amp / BuiltPlan.unit,
      period: 1,
      phaseOffset: gate.phase * math.pi / 180,
      appearance: gate.look,
      door: gate.door ? SkyDoor() : null,
    )..advance(0);
  }

  /// A gate as the bird will meet it, with its aiming mark and the dotted
  /// approach line.
  static void gate(
    Canvas canvas,
    double h,
    BuiltGate gate, {
    required PlayMode mode,
    required double x,
    required WorldRegion region,
    bool aim = true,
  }) {
    final o = obstacle(gate, mode, x);
    ObstacleArt.paint(
      canvas,
      o,
      h,
      seconds: 0,
      reducedMotion: true,
      cleared: false,
      perfect: false,
      held: region,
    );
    if (o.door != null) DoorArt.paint(canvas, h, o, reducedMotion: true);
    if (!aim || o.door != null) return;
    final center = Offset((o.x + o.width / 2) * h, o.target * h);
    canvas.drawCircle(
      center,
      h * .035,
      Paint()
        ..color = SkyColors.white.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, h * .006),
    );
    canvas.drawCircle(
      center,
      h * .008,
      Paint()..color = SkyColors.white.withValues(alpha: .8),
    );
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center - Offset(h * (.10 + i * .06), 0),
        h * .004,
        Paint()..color = SkyColors.white.withValues(alpha: .3 + i * .07),
      );
    }
  }

  static void star(Canvas canvas, double h, Offset center) =>
      StarArt.paint(canvas, center, h * StarArt.radius, reducedMotion: true);

  /// Three stars [BuiltTrio.spacing] apart round [center], tied by a faint
  /// band so they read as one trio.
  static void trio(Canvas canvas, double h, Offset center) {
    const spacing = BuiltTrio.spacing / BuiltPlan.unit;
    final band = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: h * (spacing * 2 + StarArt.radius * 3.4),
        height: h * StarArt.radius * 3.4,
      ),
      Radius.circular(h * StarArt.radius * 1.7),
    );
    canvas.drawRRect(
      band,
      Paint()..color = SkyColors.yellow.withValues(alpha: .22),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, h * .005),
    );
    for (var i = -1; i <= 1; i++) {
      star(canvas, h, center + Offset(i * spacing * h, 0));
    }
  }

  static void heart(Canvas canvas, double h, Offset center) =>
      HeartPickupArt.paint(
        canvas,
        h,
        SkyHeart(x: center.dx / h, y: center.dy / h),
        seconds: 0,
        reducedMotion: true,
      );

  /// A small enemy of [kind] at [center], facing the bird coming from the
  /// left.
  static void enemy(Canvas canvas, double h, EnemyKind kind, Offset center) {
    // The art turns an enemy behind the bird round; this one is always
    // ahead of it, so it is drawn well to the right and moved back.
    const ahead = 10.0;
    canvas.save();
    canvas.translate(-ahead * h, 0);
    EnemyArt.paint(
      canvas,
      h,
      SkyEnemy(
        x: center.dx / h + ahead,
        y: center.dy / h,
        appearance: kind.index,
        flightPhase: 0,
      ),
      birdY: center.dy / h,
      reducedMotion: true,
    );
    canvas.restore();
  }

  /// The finish gate standing at [x] pixels.
  static void finish(Canvas canvas, double h, double x) => FinishGateArt.paint(
    canvas,
    h,
    x: x,
    seconds: 0,
    arrived: false,
    reducedMotion: true,
  );

  /// A boss's mark at [x] pixels: a dashed line across the sky and the boss
  /// waiting on it.
  static void bossMark(Canvas canvas, double h, double x, BossKind kind) {
    final dash = Paint()
      ..color = SkyColors.coralDeep
      ..strokeWidth = math.max(2.0, h * .012)
      ..strokeCap = StrokeCap.round;
    for (var y = h * .04; y < h; y += h * .07) {
      canvas.drawLine(Offset(x, y), Offset(x, y + h * .035), dash);
    }
    final box = Rect.fromCenter(
      center: Offset(x + h * .28, h * .5),
      width: h * .5,
      height: h * .5,
    );
    canvas.drawCircle(
      box.center,
      h * .3,
      Paint()..color = SkyColors.coral.withValues(alpha: .18),
    );
    BossPortraitPainter.paintIn(canvas, box, kind);
  }

  /// The player's bird, faint, where it starts.
  static void ghostBird(Canvas canvas, double h, Offset center, int bird) {
    final bw = h * .145;
    canvas.saveLayer(
      Rect.fromCenter(center: center, width: bw * 1.4, height: bw * 1.4),
      Paint()..color = SkyColors.white.withValues(alpha: .7),
    );
    canvas.translate(center.dx, center.dy);
    BirdPuppet.paint(
      canvas,
      Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
      bird: bird,
      wing: 0,
    );
    canvas.restore();
  }

  /// An icon of a gate of [kind] filling [size], as the flight draws it.
  /// A walled family shows whole, top to bottom with the opening between,
  /// its walls drawn wider than life so they read at icon size; a floating
  /// family shows a close-up of its two orbs.
  static void gateIcon(
    Canvas canvas,
    Size size,
    ObstacleKind kind, {
    required WorldRegion region,
    int look = 0,
  }) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (kind.floating) {
      final h = size.height * 1.8;
      final width = kind.width * h;
      final scale = math.min(1.0, size.width * .94 / width);
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(scale);
      canvas.translate(-width / 2, -h / 2);
      BuilderArt.gate(
        canvas,
        h,
        BuiltGate(x: 0, y: 500, gap: 40, kind: kind, look: look),
        mode: PlayMode.touch,
        x: 0,
        region: region,
        aim: false,
      );
    } else {
      final h = size.height;
      final natural = kind.width * h;
      final stretch = (size.width * .5 / natural).clamp(1.0, 3.0);
      canvas.translate(size.width / 2, 0);
      canvas.scale(stretch, 1);
      canvas.translate(-natural / 2, 0);
      BuilderArt.gate(
        canvas,
        h,
        BuiltGate(x: 0, y: 500, gap: 340, kind: kind, look: look),
        mode: PlayMode.touch,
        x: 0,
        region: region,
        aim: false,
      );
    }
    canvas.restore();
  }

  /// A star filling [size].
  static void starIcon(Canvas canvas, Size size) => star(
    canvas,
    size.shortestSide * .4 / StarArt.radius,
    size.center(Offset.zero),
  );

  /// A heart filling [size].
  static void heartIcon(Canvas canvas, Size size) =>
      heart(canvas, size.shortestSide * .5 / .061, size.center(Offset.zero));

  /// An enemy of [kind] filling [size].
  static void enemyIcon(Canvas canvas, Size size, EnemyKind kind) => enemy(
    canvas,
    size.shortestSide * .34 / SkyEnemy.radius,
    kind,
    size.center(Offset.zero),
  );
}
