import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'king_coo_boss_rig.dart';
import 'king_coo_kit.dart';
import 'king_coo_pose.dart';

/// King Coo as a still portrait for the story screens: the same rig, in the
/// same z-order, held in the pose [KingCooPose.story] gives the scene's mood
/// (a wing on the hip, a grin and a bagel, a cap hop, puffed with the siren
/// red, a worried brow, and the beaten king: no cap, sheepish), plus his
/// props, which are the story's and not the fight's: the bagel Bill offers
/// (the happy pose reaches for it) and the pretzel a beaten king is left with.
///
/// Kept beside the rig, as `DragonStoryArt` is beside the dragon's, so that
/// nowhere in the story art has to know the parts. Paints at the origin in
/// rig units, facing left (`StoryBossArt.portrait` fits it to the stage).
abstract final class KingCooStoryArt {
  /// Paints him for [mood]; [beaten] is the scene after his fall (no cap),
  /// [talk] (0 to 1) opens the beak as the line is written out and [blink]
  /// (0 to 1) lowers the lids.
  static void paint(
    Canvas c,
    KingCooMood mood, {
    bool beaten = false,
    double talk = 0,
    double blink = 0,
  }) {
    final pose = KingCooPose.story(
      mood,
      beaten: beaten,
      talk: talk,
      blink: blink,
    );
    KingCooBossRig.paintPose(c, pose, cap: !beaten);
    final hand = KingCooBossRig.bombOrigin(pose);
    if (mood == KingCooMood.happy) {
      bagel(c, hand, .46);
    } else if (beaten) {
      pretzel(c, hand, .46);
    }
  }

  /// Everything the props can reach around their centre (rig units): the
  /// story fit's reach already holds them (the hand is inside the figure's).
  static const propRadius = .55;

  static const _ink = KingCooPalette.ink;
  static const _crust = KingCooPalette.crust, _deep = KingCooPalette.crustDeep;

  /// A sesame bagel held out at [at], [radius] rig units across: a golden
  /// ring with a hole you can see the wing through, a glossy crust, seeds.
  static void bagel(Canvas c, Offset at, double radius) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(-.35);
    c.scale(radius);
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCenter(center: Offset.zero, width: 2, height: 1.84))
      ..addOval(Rect.fromCenter(center: Offset.zero, width: .62, height: .56));
    c.drawPath(
      ring,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.4),
          radius: 1.1,
          colors: [
            KingCooPalette.crumbHi,
            KingCooPalette.crumb,
            _crust,
          ],
          stops: [0, .45, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.1)),
    );
    // The underside's shade and a hard glint on the crust.
    c.drawPath(
      Path()..addArc(
        Rect.fromCenter(center: Offset.zero, width: 1.7, height: 1.55),
        .2,
        1.9,
      ),
      KingCooKit.line(_deep, .16, .55),
    );
    c.drawPath(
      Path()..addArc(
        Rect.fromCenter(center: Offset.zero, width: 1.7, height: 1.55),
        3.5,
        .9,
      ),
      KingCooKit.line(KingCooPalette.white, .09, .85),
    );
    for (var i = 0; i < 10; i++) {
      final a = i * 2 * math.pi / 10 + .3;
      final r = .66 + (i.isEven ? .03 : -.02);
      final seed = Offset(math.cos(a) * r, math.sin(a) * r * .93);
      c.save();
      c.translate(seed.dx, seed.dy);
      c.rotate(a);
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: .15, height: .07),
        KingCooKit.fill(KingCooPalette.cream),
      );
      c.restore();
    }
    c.drawPath(ring, KingCooKit.line(_ink, .12));
    c.restore();
  }

  /// A salted pretzel in the beaten king's wing, [radius] rig units across:
  /// the knot of a thick rope of dough, crossed over twice, with salt.
  static void pretzel(Canvas c, Offset at, double radius) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(.25);
    c.scale(radius);
    final knot = Path()
      ..moveTo(-.52, .62)
      ..cubicTo(-1.25, .1, -.95, -.9, -.2, -.82)
      ..cubicTo(.35, -.74, .52, -.15, 0, .15)
      ..cubicTo(-.3, .34, -.1, .6, .0, .66)
      ..moveTo(.52, .62)
      ..cubicTo(1.25, .1, .95, -.9, .2, -.82)
      ..cubicTo(-.35, -.74, -.52, -.15, 0, .15)
      ..cubicTo(.3, .34, .1, .6, .0, .66);
    c.drawPath(knot, KingCooKit.line(_ink, .56));
    c.drawPath(knot, KingCooKit.line(_deep, .36));
    c.drawPath(knot, KingCooKit.line(_crust, .26));
    c.drawPath(
      Path()
        ..moveTo(-.95, -.2)
        ..quadraticBezierTo(-.9, -.7, -.5, -.82),
      KingCooKit.line(KingCooPalette.crumbHi, .07, .9),
    );
    for (final p in const [
      Offset(-.8, -.1),
      Offset(-.45, -.66),
      Offset(.45, -.62),
      Offset(.82, -.05),
      Offset(0, .02),
      Offset(-.55, .5),
      Offset(.55, .5),
    ]) {
      c.drawCircle(p, .045, KingCooKit.fill(KingCooPalette.white));
    }
    c.restore();
  }
}
