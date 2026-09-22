import 'package:flutter/painting.dart';

import '../../domain/sky_boss.dart';
import '../boss_motion.dart';
import '../boss_rig.dart';

/// A simple, unadorned member of the boss's bat family.
///
/// The shared rig keeps the purple body, ears, fangs, and membrane wings while
/// omitting the boss's crown and regalia. The caller owns facing; the rig looks
/// left by default. The small enemy's hit radius stays unchanged.
abstract final class SimpleBatArt {
  static void paint(
    Canvas c,
    double radius, {
    required double seconds,
    required bool reducedMotion,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = seconds.isFinite && seconds > 0 ? seconds : 0.0;

    // This private render snapshot never enters or modifies the simulation.
    // Start past arrival, with full health and no pending attack, so only the
    // normal flying animation is used. There are no cutscenes or combat cues.
    final pose = SkyBoss(number: 1, x: 0)..age = SkyBoss.arrivalSeconds + time;
    final motion = BossMotion(pose, reducedMotion: reducedMotion);

    c.save();
    c.scale(radius);
    c.rotate(motion.rotation);
    BossRig.paint(c, pose, motion, lookY: lookY, adorned: false);
    c.restore();
  }
}
