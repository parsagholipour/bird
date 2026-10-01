import 'boss_motion.dart';

/// The letterbox of King Coo's encounter, as a [BossMotion] so the parts that
/// read [focus] see the bars as they are drawn.
///
/// It is the Ember Dragon's and the Searchlight Gargoyle's rule exactly (the
/// fix round aligned them): the bars leave 0.2 s earlier than the others' on
/// the way out of the arrival, so the card's exit (4.2 to 4.6 s) is never cut
/// by them; for the COO! (2.5 to 3.6 s) they open to 30% (the shout and the cap's
/// hop get room; a still frame under Reduced Motion, as the dragon's); and after
/// the killing blow they slide in (0.4 to 1.1 s) behind the dying figure
/// instead of cutting across it.
final class KingCooStageMotion extends BossMotion {
  const KingCooStageMotion(super.boss, {required super.reducedMotion});

  @override
  double get focus {
    final age = boss.age;
    if (arriving) {
      final base =
          BossMotion.ease(BossMotion.ramp(age, 0, .65)) *
          (1 - BossMotion.ease(BossMotion.ramp(age, 3.8, 4.4)));
      // Widescreen for the COO! (2.5 to 3.6 s), a still frame under Reduced
      // Motion.
      final open = reducedMotion
          ? 0.0
          : BossMotion.ease(BossMotion.ramp(age, 2.5, 2.75)) *
                (1 - BossMotion.ease(BossMotion.ramp(age, 3.2, 3.6)));
      return base * (1 - .7 * open);
    }
    if (defeated) {
      return BossMotion.ease(BossMotion.ramp(death, .4, 1.1)) * super.focus;
    }
    return super.focus;
  }
}
