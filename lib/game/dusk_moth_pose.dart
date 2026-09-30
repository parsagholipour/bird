import 'dart:math' as math;

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'dusk_moth_kit.dart';

/// Everything the Dusk Empress's pose derives from the boss clock.
///
/// Every channel is a pure function of the [SkyBoss] and its [BossMotion], so
/// pausing, replaying and seeking reproduce a frame exactly. Motion channels
/// (wingbeat, sways, recoil) collapse to a still frame under Reduced Motion;
/// expression channels (charge, wince, fury, mouth) keep playing.
final class DuskMothPose {
  DuskMothPose(SkyBoss boss, BossMotion m, double lookY)
    : defeated = m.defeated,
      still = m.reducedMotion || m.defeated,
      time = m.reducedMotion || m.defeated ? 0.0 : boss.age,
      charge = BossMotion.ease(boss.charge),
      recoil = m.reducedMotion ? 0.0 : m.recoil,
      roar = m.reducedMotion ? 0.0 : m.roar,
      shout = m.defeated ? 0.0 : m.roar,
      wince = m.defeated ? 1.0 : m.hit,
      blink = m.blink,
      summon = m.summon,
      death = m.defeated ? m.death : 0.0,
      // Fury is a held state (warm wings, glare); the rage pulse only flares it.
      fury = boss.enraged && !m.defeated ? .8 + m.rage * .2 : 0.0,
      // A struck flash brightens the fills while the ink outline holds, so the
      // queen never reads as fading out. Crown pixels stay untouched.
      flash = m.reducedMotion || m.defeated ? 0.0 : m.hit * .55,
      moonlight = boss.shielded ? 1.0 : boss.shieldWarning * .6,
      aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0,
      fold = m.defeated
          ? (m.reducedMotion
                ? .8
                : .8 * BossMotion.ease(BossMotion.ramp(m.death, 0, .25)))
          : m.folded,
      curl = m.defeated
          ? (m.reducedMotion
                ? 1.0
                : BossMotion.ease(BossMotion.ramp(m.death, 0, .3)))
          : 0.0,
      shelter =
          (boss.shielded ? 1.0 : BossMotion.ease(boss.shieldWarning)) * .1,
      _phase = _beatPhase(boss) {
    breath = time == 0 ? 0 : math.sin(time * 3) * .026;
  }

  final bool defeated, still;

  /// Seconds on the boss clock; zero whenever the queen must sit still.
  final double time;
  final double charge, recoil, roar, shout, wince, blink, summon, death;
  final double fury, flash, moonlight, aim, fold, shelter, curl;
  late final double breath;
  final double _phase;

  /// The shock of a hit as motion: 0 under Reduced Motion and in the defeat.
  double get jolt => flash / .55;

  /// The look every part shares.
  DuskTone get tone => DuskTone(flash: flash, fury: fury, moon: moonlight);

  /// How hard she glares: the enraged scowl or the aim before a shot.
  double get glare => defeated ? 0 : math.max(fury, charge * .85);

  /// How far the mouth is open: the roar, the windup, or the shot.
  double get gape =>
      defeated ? 0 : math.max(shout, math.max(charge * .9, recoil * .7));

  /// The wingbeat as a lift: 1 raised high, -1 swept down. [lag] delays a
  /// part behind the near forewing (radians of the beat), so the hindwings,
  /// far wings and tails ripple through the stroke.
  double raise([double lag = 0]) => still
      ? .32
      : (-math.sin(_phase - lag) * .82 + roar * 1.7).clamp(-1.0, 1.0);

  /// A gentle repeating sway of [amp], [rate] rad/s, [phase] radians in.
  double sway(double rate, double amp, [double phase = 0]) =>
      time == 0 ? 0 : math.sin(time * rate + phase) * amp;

  /// A brief sparkle that comes round every few seconds, 0 between them.
  double get twinkle {
    if (time == 0) return 0;
    final t = (time % 2.9) / .55;
    return t >= 1 ? 0 : math.sin(t * math.pi);
  }

  // The beat keeps its phase when fury quickens it, so the wings never jump.
  static double _beatPhase(SkyBoss boss) {
    if (!boss.enraged) return boss.age * 8.5;
    final since = boss.age - boss.enragedAt;
    return since.isFinite ? boss.age * 8.5 + since * 3.5 : boss.age * 12;
  }
}
