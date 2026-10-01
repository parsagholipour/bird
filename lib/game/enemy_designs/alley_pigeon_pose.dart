import 'dart:math' as math;

import '../../domain/sky_enemy.dart';

/// What an Alley Pigeon is doing, for the art (not the rules). One stage per
/// drawn pose: the rules' five [PigeonPhase]s split the carry phase in two
/// (the gloat, then the climb) and add the two reactions to a rock.
/// How many plumages there are (`AlleyPigeonArt.coatCount`, here so the pose
/// does not import the painter).
abstract final class AlleyPigeonArtCoats {
  static const count = 3;
}

enum PigeonStage {
  /// Flapping along or hovering over its prey (or a preyless glider).
  glide,

  /// The 0.80 s telegraph: crouch, puffed collar, raised quivering wings.
  warn,

  /// The 0.44 s swoop: wings swept back, nose along the path.
  dive,

  /// The star is in its beak and it chuckles (the first 0.65 s).
  gloat,

  /// Climbing away with the star.
  climb,

  /// Leaving with no star: spooked before the snatch, or the star was shot
  /// out of its beak.
  flee,
}

/// A pigeon's pose as a pure function of its raid state and its own clock,
/// so a replay, a seek or a pause draws exactly the same pigeon.
///
/// The painter draws the pigeon looking left; [tilt] is in that frame (radians,
/// positive lifts the nose) and stays correct when the caller mirrors the
/// picture to face right.
final class PigeonPose {
  const PigeonPose({
    this.stage = PigeonStage.glide,
    this.warn = 0,
    this.dive = 0,
    this.stageTime = 0,
    this.tilt = 0,
    this.kick = 0,
    this.loot = false,
    this.startle = 0,
    this.facingRight = false,
    this.coat = 0,
    this.reach = 0,
    this.flare = 0,
    this.drift = 0,
    this.scale = 1,
    this.beat = 1,
    this.settle = 1,
  });

  final PigeonStage stage;

  /// 0 to 1 through the warning (the enemy's `charge`).
  final double warn;

  /// 0 to 1 through the dive.
  final double dive;

  /// Seconds since the stage began (0 for a plain glide).
  final double stageTime;

  /// Body pitch along the path of flight.
  final double tilt;

  /// 1 at the snatch, falling to 0 over 0.24 s.
  final double kick;

  /// Whether a star rides in its beak.
  final bool loot;

  /// 1 on the frame a rock lands, easing to 0 by [startleSeconds]: wide eyes,
  /// open beak. Zero in Reduced Motion's still frames.
  final double startle;

  /// Whether the picture must be mirrored: a pigeon faces left until it
  /// starts its warning, then right toward its prey and away with the star.
  final bool facingRight;

  /// Which plumage it wears (its slot in the flock, so a V of three is three
  /// different birds): 0 blue-bar, 1 checker, 2 white-wing.
  final int coat;

  /// The strike's anticipation and its follow-through: 0 to 1 as the dive
  /// closes in on the star (neck stretched toward it, beak opening), and back
  /// to 0 over the first 0.12 s after the snatch.
  final double reach;

  /// The braking flare of the wings: half-spread as the beak closes in, a
  /// full flare at the snatch, folding back by 0.18 s after it.
  final double flare;

  /// A render-only forward displacement, in hit radii: the momentum the dive
  /// carries through the snatch, relaxing into the climb's own pace. The
  /// rules' path changes speed in one step; the picture does not.
  final double drift;

  /// The bird's size and wingbeat tempo relative to the standard pigeon (a
  /// squadron glider is a little bigger or smaller, a little quicker or
  /// slower than its neighbours); 1 for a raider.
  final double scale, beat;

  /// How far the snatch has settled, 0 at the snatch to 1 (also 1 for a
  /// pigeon that has not just snatched): what the wings, tail and feet blend
  /// by so the dive's pose carries into the climb's without a jump.
  final double settle;

  /// This pose with every number made safe to paint: non-finite values become
  /// the resting value and the rest are clamped to their ranges.
  PigeonPose cleaned() {
    double f(double v, double lo, double hi, double rest) =>
        v.isFinite ? v.clamp(lo, hi).toDouble() : rest;
    return PigeonPose(
      stage: stage,
      warn: f(warn, 0, 1, 0),
      dive: f(dive, 0, 1, 0),
      stageTime: f(stageTime, 0, 1e6, 0),
      tilt: f(tilt, -1.2, 1.2, 0),
      kick: f(kick, 0, 1, 0),
      loot: loot,
      startle: f(startle, 0, 1, 0),
      facingRight: facingRight,
      coat: coat,
      reach: f(reach, 0, 1, 0),
      flare: f(flare, 0, 1, 0),
      drift: f(drift, -3, 3, 0),
      scale: f(scale, .5, 1.5, 1),
      beat: f(beat, .5, 2, 1),
      settle: f(settle, 0, 1, 1),
    );
  }

  static const startleSeconds = .42;

  /// The snatch settles in this long: the nose comes level (with a little
  /// flick up), the wings fold, the neck draws back and the momentum is spent.
  static const settleSeconds = .14;

  /// How far the nose is down at the snatch, in radians (up from below).
  static const entryTilt = .20;

  /// The pose of [enemy] at its current clock. [hitAge] is the time since a
  /// rock hurt it (the caller's `enemy.age - enemy.lastHitAt`).
  static PigeonPose of(SkyEnemy enemy, {required double hitAge}) => ofRaid(
    enemy.pigeon,
    age: enemy.age,
    hitAge: hitAge,
    // Only King Coo's squadron are varied; a pigeon that is neither a raider
    // nor of the squad stays the plain glider.
    squadPhase: enemy.squad ? enemy.flightPhase : null,
  );

  /// The golden-angle step `SkyEnemy.flightPhase` advances by from one squad
  /// pigeon to the next (`king_coo_rules.dart`): `flightPhase / squadPhaseStep`
  /// is the glider's release slot `n`.
  static const squadPhaseStep = 2.399963;

  /// A squadron glider's own bank for release slot [n] (radians, within about
  /// +-4 degrees). One source for the real gliders ([squadLook]) and for
  /// K6's ghost of the formation, so the ghost previews the bank it will wear.
  static double squadTilt(int n) => (((n.abs() * 2 + 1) % 5) - 2) * .035;

  /// The pose of a pigeon whose raid state is [raid] (null for a squadron
  /// pigeon, which is always a plain glider whose look comes from its
  /// [squadPhase], its `flightPhase`) at its own clock [age].
  static PigeonPose ofRaid(
    PigeonFlight? raid, {
    required double age,
    required double hitAge,
    double? squadPhase,
  }) {
    final startle = hitAge.isFinite && hitAge >= 0 && hitAge < startleSeconds
        ? 1 - _smooth(hitAge / startleSeconds)
        : 0.0;
    if (raid == null) {
      final look = squadLook(squadPhase);
      return PigeonPose(
        startle: startle,
        coat: look.coat,
        scale: look.scale,
        beat: look.beat,
        tilt: look.tilt,
      );
    }
    // A clock that is not a number draws the resting pigeon.
    if (!age.isFinite) return PigeonPose(startle: startle, coat: raid.slot);
    final coat = raid.slot;
    final since = math.max(0.0, age - raid.phaseAt);
    final side = raid.side;
    // The snatch's settle, if there was one a moment ago.
    final snatched = age - raid.snatchedAt;
    final settleT = snatched.isFinite && snatched >= 0 && snatched < 1
        ? snatched
        : double.infinity;
    final settled = settleT.isFinite
        ? (settleT / settleSeconds).clamp(0.0, 1.0)
        : 1.0;
    final entry = side * entryTilt;
    switch (raid.phase) {
      case PigeonPhase.glide:
        return PigeonPose(startle: startle, coat: coat);
      case PigeonPhase.warning:
        final w = raid.warning(age);
        // A deep crouch, a small lean back like a spring being wound.
        return PigeonPose(
          stage: PigeonStage.warn,
          warn: w,
          stageTime: since,
          tilt: .10 * _smooth(w / .3),
          startle: startle,
          facingRight: true,
          coat: coat,
        );
      case PigeonPhase.dive:
        final u = raid.dive(age);
        // Eased out of the crouch's lean so the nose does not snap over, and
        // eased into the snatch's entry angle so it does not snap level.
        final base =
            .10 +
            (diveTilt(u, slot: raid.slot, side: side) - .10) * _smooth(u / .30);
        final into = _smooth((u - .6) / .4);
        final reach = _smooth((u - .78) / .22);
        return PigeonPose(
          stage: PigeonStage.dive,
          dive: u,
          stageTime: since,
          tilt: base * (1 - into) + entry * into,
          startle: startle,
          facingRight: true,
          coat: coat,
          reach: reach,
          flare: snatchFlare(-1, reach),
          settle: 0,
        );
      case PigeonPhase.carry:
        final tau = raid.fleeTime(age);
        final gloat = tau < AlleyPigeon.gloatSeconds;
        return PigeonPose(
          stage: gloat ? PigeonStage.gloat : PigeonStage.climb,
          stageTime: tau,
          tilt: fleeTilt(tau, side: side) + snatchPitch(settleT, entry),
          kick: raid.kick(age),
          loot: raid.carrying,
          startle: startle,
          facingRight: true,
          coat: coat,
          reach: snatchReach(settleT),
          flare: snatchFlare(settleT, 1),
          drift: snatchDrift(settleT, raid.slot, side),
          settle: settled,
        );
      case PigeonPhase.flee:
        final tau = raid.fleeTime(age);
        return PigeonPose(
          stage: PigeonStage.flee,
          stageTime: tau,
          tilt: fleeTilt(tau, side: side) + snatchPitch(settleT, entry),
          kick: raid.kick(age),
          startle: startle,
          facingRight: true,
          coat: coat,
          reach: snatchReach(settleT),
          flare: snatchFlare(settleT, 1),
          drift: snatchDrift(settleT, raid.slot, side),
          settle: settled,
        );
    }
  }

  /// The nose's pitch [t] seconds after the snatch (infinite: no snatch), in
  /// the painter's frame (positive lifts the nose). It starts at the dive's
  /// entry angle [entry], flicks past level to 60% of the way up (the beak's
  /// kick) by 40% of the settle, and is level again at [settleSeconds].
  static double snatchPitch(double t, double entry) {
    if (!t.isFinite || t < 0 || t >= settleSeconds) return 0;
    final s = t / settleSeconds;
    return s < .4
        ? entry + (-.6 * entry - entry) * _smooth(s / .4)
        : -.6 * entry * (1 - _smooth((s - .4) / .6));
  }

  /// The neck's stretch toward the star: 1 at the snatch, drawn back by 0.12 s.
  static double snatchReach(double t) =>
      !t.isFinite || t < 0 || t >= .12 ? 0 : 1 - _smooth(t / .12);

  /// The wings' brake: [reach] times .55 before the snatch (pass `t` < 0), a
  /// full flare just after it and folded again by 0.18 s.
  static double snatchFlare(double t, double reach) {
    if (t < 0) return .55 * reach;
    if (!t.isFinite || t >= .18) return 0;
    final up = math.sin(math.pi * (t / .09).clamp(0.0, 1.0) / 2);
    return (.55 + .35 * up) * (1 - _smooth((t - .06) / .12));
  }

  /// The forward momentum the dive carries through the snatch, in hit radii:
  /// the dive arrives at `a * pi / 2 * 1.7 / diveSeconds` (screen heights per
  /// second, `a` the slot's hover offset) and the climb leaves at
  /// [AlleyPigeon.flee]'s pace. A displacement that starts at that difference
  /// in speed, builds and relaxes to nothing (`d(t) = dv * t * e^(-t/tau)`)
  /// keeps the picture's speed continuous through the snatch while the
  /// rules' hit circle, which does change speed in one step, is never more
  /// than about half a radius away.
  static double snatchDrift(double t, int slot, int side) {
    if (!t.isFinite || t < 0) return 0;
    final i = slot.clamp(0, AlleyPigeon.hoverX.length - 1);
    final arrive =
        -AlleyPigeon.hoverX[i] * math.pi / 2 * 1.7 / AlleyPigeon.diveSeconds;
    final leave = AlleyPigeon.flee(1, side).dx;
    final dv = (arrive - leave).clamp(-.5, 1.0);
    const tau = .07;
    return dv * t * math.exp(-t / tau) / SkyEnemy.radius;
  }

  /// The look of a squadron glider, from its enemy's `flightPhase` (the rules
  /// number a squadron's pigeons `n * 2.399963`, so `n` recovers the slot):
  /// plumage cycles with `n` (neighbours in a V differ), and size (+-6%),
  /// wingbeat tempo (+-7%) and a little bank (+-4 degrees) are different
  /// again, so a V of gliders reads as individuals.
  static ({int coat, double scale, double beat, double tilt}) squadLook(
    double? flightPhase,
  ) {
    if (flightPhase == null || !flightPhase.isFinite) {
      return (coat: 0, scale: 1, beat: 1, tilt: 0);
    }
    final n = (flightPhase / squadPhaseStep).round().abs();
    return (
      coat: n % 3,
      scale: .94 + .03 * ((n * 3 + 1) % 5),
      beat: 1 + ((n * 2 + 1) % 3 - 1) * .07,
      tilt: squadTilt(n),
    );
  }

  /// The pitch along the swoop: the rules fly a quarter ellipse from the
  /// hover (`hoverX`, `hoverRise` by slot) to the star, so the heading runs
  /// from straight down (or up, from below the lane) to level at the snatch.
  /// Eased and capped: a dive is a stoop, not a nosedive.
  static double diveTilt(double u, {required int slot, required int side}) {
    final i = slot.clamp(0, AlleyPigeon.hoverX.length - 1);
    final a = -AlleyPigeon.hoverX[i], b = -side * AlleyPigeon.hoverRise[i];
    final theta = math.pi / 2 * math.pow(u.clamp(0.0, 1.0), 1.7);
    // Heading in screen space (y down): (a sin, b cos); positive is down.
    final heading = math.atan2(b * math.cos(theta), a * math.sin(theta));
    // Local frame: positive lifts the nose, so a downward heading is negative.
    return (-heading * .62).clamp(-.95, .95);
  }

  /// The pitch of the gloat and climb [tau] seconds after the snatch.
  static double fleeTilt(double tau, {required int side}) {
    final late = math.max(0.0, tau - AlleyPigeon.gloatSeconds);
    // Velocity is (.70, side * .60 * late) in screen space.
    final heading = math.atan2(side * .60 * late, .70);
    return (-heading * .8).clamp(-.8, .8);
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }
}
