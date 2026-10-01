import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'boss_rig.dart';

/// The upgraded Baron's screech pose (see [BaronScreech]), derived from the
/// boss clock alone so pauses, replays and seeks repeat exactly.
///
/// Warning: the ears flare and light up, the chest swells, the wings draw
/// up and the jaw drops as sound gathers in his mouth. Release: the jaw
/// flies wide and he lunges at the bird as the wall leaves, wings slamming
/// down. The jaw stays open, shaking, while the wall sweeps; then he
/// settles. Under Reduced Motion the expression (ears, glow, jaw) still
/// plays but the body holds still.
class BaronStormPose {
  BaronStormPose(this.motion);
  final BossMotion motion;
  SkyBoss get boss => motion.boss;
  bool get reduced => motion.reducedMotion;

  /// The screech's kick decays over [kickSeconds]; the settle after the
  /// wall has gone takes [settleSeconds].
  static const kickSeconds = .42, settleSeconds = .45;

  bool get _fighting => boss.screeches && boss.phase == BossPhase.attacking;

  /// Combat time within the screech cycle (as the rules count it), or -1
  /// outside the fight.
  double get cycle =>
      _fighting ? (boss.age - boss.arrivalDuration) % BaronScreech.period : -1;

  /// 0 to 1 through the warning: the rules' own value.
  double get warning => boss.screechWarning;

  /// The warning eased, as sound gathers.
  double get gather => BossMotion.ease(warning);

  /// Seconds since the wall left his mouth while it sweeps, else null.
  double? get sinceRelease =>
      boss.screeching ? cycle - BaronScreech.screechAt : null;

  /// The snap as the wall leaves: instant, then easing off.
  double get kick {
    final s = sinceRelease;
    if (s == null) return 0;
    return math.min(s / .04, 1) *
        (1 - BossMotion.ease(BossMotion.ramp(s, .04, kickSeconds)));
  }

  /// The screech itself: full as it leaves, holding strong through the
  /// sweep and fading through the settle.
  double get voice {
    final t = cycle;
    if (t < BaronScreech.screechAt) return 0;
    if (t < BaronScreech.endAt) {
      return 1 -
          .3 *
              BossMotion.ramp(
                t,
                BaronScreech.screechAt + .3,
                BaronScreech.endAt,
              );
    }
    return .7 *
        (1 -
            BossMotion.ease(
              BossMotion.ramp(
                t,
                BaronScreech.endAt,
                BaronScreech.endAt + settleSeconds,
              ),
            ));
  }

  /// The arrival roar doubles as a first screech.
  double get _roar => boss.screeches ? motion.roar : 0;

  /// Ears flared out (0 at rest).
  double get flare => math.max(math.max(gather, voice), _roar);

  /// A low sonic hum between screeches, so his sound never quite sleeps;
  /// held steady under Reduced Motion.
  double get hum => !boss.screeches || motion.defeated
      ? 0
      : reduced
      ? .12
      : .12 + .08 * math.sin(boss.age * 2.3);

  /// Sonic glow in the ears, the chest resonator and the crown's gem.
  double get glow =>
      math.max(math.max(math.max(gather, voice), _roar * .8), hum);

  /// The jaw: dropping through the warning, wide as the wall leaves.
  double get jaw =>
      math.max(warning > 0 ? .18 + .6 * gather : 0, voice * .85 + kick * .15);

  /// The small bats are called: ears perk and the wings sweep up.
  double get beckon => boss.screeches && !motion.defeated ? motion.summon : 0;

  /// A fast shake while he holds the screech; decoration only.
  double get tremble => reduced || motion.defeated
      ? 0
      : math.sin(boss.age * 71) * voice * (1 - kick);

  /// The body inside the rig, in rig units: rearing back and swelling in
  /// the warning, lunging at the bird as the wall leaves. Held still under
  /// Reduced Motion.
  Offset get shift => reduced
      ? Offset.zero
      : Offset(
          .07 * gather - .2 * kick + .02 * tremble,
          -.07 * gather + .06 * kick,
        );
  double get scaleX => reduced ? 1 : 1 + .04 * gather + .07 * kick;
  double get scaleY => reduced ? 1 : 1 + .04 * gather - .05 * kick;

  /// A rig point (rig units) after the pose's body shift and swell.
  Offset inRig(Offset p) => shift + Offset(p.dx * scaleX, p.dy * scaleY);

  /// The motion [BossRig] draws the pose with.
  BossMotion get rigMotion => _StormMotion(this, motion);
}

/// The base motion with the screech's jaw, wings and crown on top.
class _StormMotion extends BossMotion {
  _StormMotion(this.pose, this.base)
    : super(base.boss, reducedMotion: base.reducedMotion, speech: base.speech);
  final BaronStormPose pose;
  final BossMotion base;

  @override
  double get mouth => math.max(base.mouth, pose.jaw);

  @override
  double get wingStroke {
    final stroke = base.wingStroke;
    if (reducedMotion) return stroke;
    // Wings draw up with the breath, slam down as the wall leaves, hold
    // half-down (shaking) through the screech and sweep up to call bats.
    final gather = pose.gather * .9;
    final hold = pose.voice * (1 - pose.kick);
    var s = stroke * (1 - gather) - gather;
    s = s * (1 - pose.kick) + pose.kick;
    s = s * (1 - hold * .7) + (.45 + pose.tremble * .25) * hold * .7;
    s = s * (1 - pose.beckon * .8) - pose.beckon * .8;
    return s.clamp(-1.0, 1.0);
  }

  /// A fierce squint as the screech builds and holds; an expression, so it
  /// also plays under Reduced Motion.
  @override
  double get blink =>
      math.max(base.blink, pose.gather * .25 + pose.voice * .35);

  @override
  double get crownLift =>
      base.crownLift + (reducedMotion ? 0 : pose.kick * .1 + pose.gather * .04);
}

/// Draws the upgraded Baron: [BossRig] in his storm regalia, posed by
/// [BaronStormPose].
abstract final class BaronStormRig {
  /// Where the screech leaves from inside his open mouth, in rig units.
  static const mouth = Offset(-.04, .3);

  static void paint(Canvas c, SkyBoss boss, BossMotion m, {double lookY = 0}) {
    final pose = BaronStormPose(m);
    final shift = pose.shift;
    final moved = shift != Offset.zero || pose.scaleX != 1 || pose.scaleY != 1;
    if (moved) {
      c.save();
      c.translate(shift.dx, shift.dy);
      c.scale(pose.scaleX, pose.scaleY);
    }
    BossRig.paint(c, boss, pose.rigMotion, lookY: lookY, storm: pose);
    if (moved) c.restore();
  }

  /// A rig point on screen (pixels), through the encounter's body transform
  /// (see BossEncounterArt.paint) and the pose.
  static Offset toScreen(SkyBoss boss, BossMotion m, double h, Offset rig) {
    final p = BaronStormPose(m).inRig(rig);
    final scale = h * SkyBoss.radius * m.bodyScale;
    final x = p.dx * scale * (1 + m.stretch),
        y = p.dy * scale * (1 - m.stretch);
    final cos = math.cos(m.rotation), sin = math.sin(m.rotation);
    return Offset(boss.x * h, boss.y * h) +
        m.offset * h +
        Offset(x * cos - y * sin, x * sin + y * cos);
  }

  /// The camera's jolt as the screech leaves (screen heights).
  static Offset shake(SkyBoss boss, bool reducedMotion) {
    if (reducedMotion || !boss.screeches) return Offset.zero;
    final pose = BaronStormPose(BossMotion(boss, reducedMotion: false));
    final k = pose.kick;
    if (k <= 0) return Offset.zero;
    return Offset(math.sin(boss.age * 83), math.cos(boss.age * 97)) * k * .005;
  }
}
