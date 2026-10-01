import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/campaign_story.dart' show StoryMood;
import '../domain/sky_boss.dart';
import 'flight_voices.dart' show FlightSpeech;

/// Pure, seekable animation: no wall clocks, frame history or random particles.
class BossMotion {
  const BossMotion(this.boss, {required this.reducedMotion, this.speech});
  final SkyBoss boss;
  final bool reducedMotion;

  /// The line this boss is saying, if any (the flight's voices; never a
  /// replay's). The rigs open the mouth with [talk] and set the face to
  /// [mood] on top of what the fight already does.
  final FlightSpeech? speech;

  /// The mood of the line being said, while it is said and as the face
  /// settles after it; null in silence and once the boss is beaten.
  StoryMood? get mood => defeated ? null : speech?.mood;

  /// How far the words open the mouth this frame, 0 shut to 1 wide: 0 in
  /// the pauses and in silence, and always under Reduced Motion, where the
  /// mood still shows but the mouth keeps still.
  double get talk => mood == null || reducedMotion
      ? 0
      : (speech!.mouth / FlightSpeech.mouths).clamp(0.0, 1.0);

  /// [fight], the mouth the fight itself makes (a roar, a windup, the shot),
  /// with the words on top: [rest] held through the line and [range] more
  /// with each word. The words get less room the wider the fight's mouth is,
  /// or the more [busy] the boss is with an attack that holds its mouth (a
  /// breath, a roar), so an attack always wins over talking.
  double voiced(
    double fight, {
    double rest = 0,
    double range = 1,
    double busy = 0,
  }) {
    if (mood == null) return fight;
    final room = 1 - math.max(fight, busy).clamp(0.0, 1.0);
    return fight + (rest + talk * range).clamp(0.0, 1.0) * room * room;
  }
  static double ramp(double value, double from, double to) =>
      ((value - from) / (to - from)).clamp(0.0, 1.0);
  static double ease(double t) => t * t * (3 - 2 * t);
  static double pulse(double age, double duration) =>
      age < 0 || age > duration ? 0 : math.sin(age / duration * math.pi);

  bool get arriving => boss.phase == BossPhase.arriving;
  bool get defeated => boss.phase == BossPhase.defeated;
  double get death => defeated ? boss.age - boss.defeatedAt! : -1;
  double get hit => pulse(boss.age - boss.lastHitAt, .28);
  double get recoil => pulse(boss.age - boss.lastVolleyAt, .34);
  double get rage => pulse(boss.age - boss.enragedAt, 1.1);
  double get summon => pulse(boss.age - boss.lastSummonAt, .7);
  double get reveal => ease(ramp(boss.age, SkyBoss.revealAt, 2.45));
  double get roar => arriving ? pulse(boss.age - SkyBoss.roarAt, .8) : 0;
  double get focus => arriving
      ? ease(ramp(boss.age, 0, .65)) * (1 - ease(ramp(boss.age, 4, 4.6)))
      : defeated
      ? 1 - ease(ramp(death, 3, 3.8))
      : 0;
  double get storm => arriving
      ? ease(ramp(boss.age, 0, .9))
      : defeated
      ? 1 - ease(ramp(death, SkyBoss.burstAt, 3.4))
      : 1;
  double get opacity => defeated ? 1 - ramp(death, .78, 1.07) : 1;
  double get silhouette => arriving ? 1 - reveal : 0;
  double get bodyScale => reducedMotion
      ? 1
      : defeated
      ? 1 + pulse(death, .85) * .13 - ramp(death, .65, .85) * .28
      : arriving
      ? 1 + .28 * math.sin(ramp(boss.age, .95, 3.6) * math.pi)
      : 1;
  double get stretch =>
      reducedMotion ? 0 : boss.charge * .06 - recoil * .13 + hit * .07;
  double get rotation => reducedMotion
      ? 0
      : defeated
      ? math.sin(death * 28) * .08 * (1 - ramp(death, .6, .85))
      : arriving
      ? -.28 * (1 - ease(ramp(boss.age, 1.3, 2.55)))
      : math.sin(boss.age * 2) * .035 + recoil * .075 - hit * .055;
  double get folded => reducedMotion
      ? 0
      : arriving
      ? 1 - ease(ramp(boss.age, 1.45, 2.65))
      : defeated
      ? ramp(death, .2, .8) * .7
      : boss.charge * .16;
  double get wingBeat => reducedMotion
      ? 0
      : (math.sin(boss.age * (boss.enraged ? 10 : 7)) * .18 - roar * .3);

  /// The wingbeat as a stroke: -1 raised, 0 spread, 1 swept down. It keeps
  /// [wingBeat]'s rates, but the phase stays continuous when fury speeds the
  /// beat up; the roar throws the wings up.
  double get wingStroke {
    if (reducedMotion) return 0;
    final since = boss.age - boss.enragedAt;
    final phase = !boss.enraged
        ? boss.age * 7
        : since.isFinite
        ? boss.age * 7 + since * 3
        : boss.age * 10;
    return (math.sin(phase) - roar * 1.7).clamp(-1.0, 1.0);
  }

  /// A brief deterministic blink every few seconds while combat idles.
  double get blink {
    if (reducedMotion || defeated || arriving) return 0;
    return pulse(boss.age % 4.3 - 3.1, .16);
  }

  /// The flinch expression after a hit; an expression, not motion, so it also
  /// plays under Reduced Motion.
  double get wince => defeated ? 0 : ramp(hit, .2, .5);
  double get crownLift =>
      reducedMotion ? 0 : hit * .2 + recoil * .1 + roar * .14;
  double get mouth =>
      defeated ? .35 : math.max(roar, math.max(boss.charge * .6, recoil));
  Offset get offset => reducedMotion
      ? Offset.zero
      : Offset(recoil * .017 + hit * .008, -roar * .013);
  Offset get shake {
    if (reducedMotion) return Offset.zero;
    final impact = defeated
        ? pulse(death - SkyBoss.burstAt, .55)
        : roar * .85 + hit * .12 + rage * .18;
    return Offset(math.sin(boss.age * 73), math.cos(boss.age * 91)) *
        impact *
        .006;
  }
}
