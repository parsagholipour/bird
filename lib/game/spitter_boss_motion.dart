import 'dart:math' as math;

import 'boss_motion.dart';

/// Seekable secondary motion. The body and muzzle stay with the simulation;
/// these poses articulate the brewer's wings, tools and limbs.
class SpitterBossMotion {
  const SpitterBossMotion(this.motion);
  final BossMotion motion;
  bool get still => motion.reducedMotion;
  double get time => still || motion.defeated ? 0 : motion.boss.age;
  double get charge => BossMotion.ease(motion.boss.charge);
  double get recoil => still ? 0 : motion.recoil;
  double get collapse => motion.defeated
      ? (still ? 1 : BossMotion.ease(BossMotion.ramp(motion.death, 0, .8)))
      : 0;
  double get fold => motion.defeated
      ? collapse
      : still
      ? 0
      : motion.folded;
  double get breath =>
      still || motion.defeated ? 0 : math.sin(time * 3.4) * .018;

  double wingStroke({required bool far, required bool lower}) {
    if (still || motion.defeated) return lower ? -.25 : .4;
    return math.sin(
      time * (motion.boss.enraged ? 29 : 23) +
          (far ? 1.1 : 0) +
          (lower ? 1.75 : 0),
    );
  }

  double get tip => still || !motion.arriving
      ? 0
      : BossMotion.pulse(motion.boss.age - 2.35, 1.1);
  double get summon => motion.summon <= 0
      ? 0
      : still
      ? 1
      : motion.summon;
  double get beckon => still ? 0 : math.sin(time * 19) * summon * .13;
  double get hatTilt =>
      still ? 0 : -tip * .27 + recoil * .2 + motion.hit * .13 + breath;
  double get hatLift => still ? 0 : tip * .12 + recoil * .12;
  double get tankRock =>
      still ? 0 : breath * -.8 + recoil * .13 - charge * .035 + collapse * .16;
  double get slosh => still ? 0 : math.sin(time * 4.6) * .035 - recoil * .21;
  double get vents => motion.boss.enraged ? 1 : charge * .65;
  double get pump => charge * .13 - recoil * .19;
  double bubble(int index) => still || motion.defeated
      ? (index * .29 + .15) % 1
      : (time * (.43 + index * .035) + index * .29) % 1;
}
