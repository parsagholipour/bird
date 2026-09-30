import 'package:flutter/painting.dart';

import 'dragon_body_art.dart';
import 'dragon_head_art.dart';
import 'dragon_hide_art.dart';
import 'dragon_kit.dart';
import 'dragon_pose.dart';
import 'dragon_wing_art.dart';

/// The Ember Dragon as a still portrait for the story screens, assembled from
/// the same parts and in the same order as [DragonBossRig.paintPose] (far wing,
/// far legs, the one-piece hide, near wing, heart, foreleg, smoke), but from a
/// hand-set head, body and wing rather than from a boss clock.
///
/// Kept beside the rig so a change to its draw order has one more place to
/// follow, and nowhere in the story art has to know the parts.
abstract final class DragonStoryArt {
  /// Paints the dragon at the origin in rig units, facing left.
  ///
  /// [stroke] is how high the wings ride, -1 raised to 1 swept down, and
  /// [fold] lays them back along the body (0 open to 1 folded), as in
  /// [DragonWingMotion].
  static void paint(
    Canvas c, {
    required DragonBodyPose body,
    required DragonHeadPose head,
    required DragonTone tone,
    required double stroke,
    double fold = 0,
  }) {
    // The far wing rides a little higher, so the pair crowns the dragon.
    final far = DragonWing.of(_motion(stroke - .12, fold), far: true);
    final near = DragonWing.of(_motion(stroke, fold));
    DragonWingArt.paint(c, far, tone, 0);
    DragonBodyArt.farLegs(c, body);
    final skin = DragonHide(body, head)..paint(c);
    DragonWingArt.paint(c, near, tone, 0);
    DragonBodyArt.heart(c, body);
    skin.paintForeleg(c);
    DragonHeadArt.smoke(c, head);
  }

  /// A still wing: every joint at the same stroke, nothing trailing.
  static DragonWingMotion _motion(double stroke, double fold) {
    final s = stroke.clamp(-1.0, 1.0);
    return DragonWingMotion(
      elbow: s,
      wrist: s,
      tips: [s, s, s, s],
      flex: const [0, 0, 0, 0],
      fold: fold,
      spread: 0,
      sag: .3,
    );
  }
}
