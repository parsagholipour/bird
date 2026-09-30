import 'dart:math' as math;

import 'boss_motion.dart';

/// Seekable secondary motion. The body and muzzle stay with the simulation;
/// these poses articulate the brewer's wings, vat, crown and limbs.
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

  /// Wing stroke, -1 raised to 1 swept down. The far pair beats a beat behind.
  double wingStroke({required bool far}) {
    if (still || motion.defeated) return far ? .25 : .4;
    return math.sin(time * (motion.boss.enraged ? 29 : 23) + (far ? 1.1 : 0));
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
  double get crownTilt => still
      ? 0
      : -tip * .27 + recoil * .2 + motion.hit * .13 + breath + rattle * .03;
  double get crownLift => still ? 0 : tip * .14 + recoil * .12;

  /// A brief deterministic blink every few seconds while combat idles.
  double get blink => motion.blink;

  /// A glint that sweeps the crown's jewel every few seconds.
  double get glint => still || motion.defeated
      ? 0
      : BossMotion.pulse(motion.boss.age % 3.7 - 3.2, .4);

  /// Pressure shudder: the crown, valve and vat tremble as the volley nears.
  double get rattle => still ? 0 : math.sin(time * 67) * charge * charge;
  double get vatRock =>
      still ? 0 : breath * -.8 + recoil * .1 - charge * .03 + collapse * .12;
  double get slosh => still ? 0 : math.sin(time * 4.6) * .035 - recoil * .21;

  /// Mandibles part with the windup and clack shut on the spit.
  double get jaw => math.max(charge * .8, recoil);

  /// How full the vat and crown vials stand: pressure raises the acid, the
  /// spit drops it, and fury keeps it boiling high.
  double get level =>
      (motion.boss.enraged ? .7 : .62) + charge * .24 - recoil * .2;

  /// Vent and steam strength: open through windups, wide open in fury.
  double get vents => motion.boss.enraged ? 1 : charge * .65;

  /// Vat brightness and heat: rises with the windup, stays hot in fury.
  double get heat =>
      math.max(motion.boss.enraged ? .55 + charge * .45 : charge, summon * .6);

  /// Cracks spreading through the glass: fury hairlines, then the burst.
  double get cracks => motion.defeated
      ? BossMotion.ease(BossMotion.ramp(motion.death, 0, .7))
      : motion.boss.enraged
      ? .7
      : 0;

  /// The plunger works in quick strokes while pressure builds.
  double get pump =>
      charge * .13 +
      (still ? 0 : math.sin(time * 17) * .035 * charge) -
      recoil * .19;

  /// The valve cap blows once when fury begins.
  double get pop => still || motion.defeated ? 0 : motion.rage * .22;

  /// Where each bubble stands in its 0..1 rise; Reduced Motion parks them.
  double bubble(int index) => still || motion.defeated
      ? (index * .29 + .15) % 1
      : (time * (.43 + index * .035) + index * .29) % 1;
}
