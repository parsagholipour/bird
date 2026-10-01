import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'dragon_kit.dart';
import 'dragon_layout.dart';

/// One wing's joint strokes this frame (see [DragonLayout.wingAt]): the
/// elbow leads, the wrist and each finger follow a little later, so the
/// wing bends and whips instead of turning like a rigid fan.
final class DragonWingMotion {
  const DragonWingMotion({
    required this.elbow,
    required this.wrist,
    required this.tips,
    required this.flex,
    required this.fold,
    required this.spread,
    required this.sag,
  });

  /// Strokes, -1 raised .. 1 swept down, for the elbow, the wrist and the
  /// four finger tips (lead finger first).
  final double elbow, wrist;
  final List<double> tips;

  /// Radians each finger trails its bone: positive turns the tip UP about the
  /// wrist (it drags up on the downstroke, down on the upstroke). At most
  /// .2, and zero at the ends of the stroke, so the envelope still holds.
  final List<double> flex;

  /// Wings laid back along the body (defeat), 0 to 1.
  final double fold;

  /// Extra fan spread while bracing, roaring or furious, 0 to 1 (the finger
  /// angles open by up to .12 rad each, outward from the lead finger).
  final double spread;

  /// How much the trailing hems sag, 0 taut .. 1 deep (follows the flex).
  final double sag;
}

typedef _Head = ({Offset at, double angle});

/// What the body is doing at one instant of the boss clock. Every lagged
/// joint (wrist, fingers, far wing, tail, neck drag) evaluates the whole
/// state machine at its own earlier time, so "the wrist follows the elbow by
/// 45 ms" holds exactly through every beat of the breath, not just in idle.
final class _Env {
  const _Env({
    required this.c,
    required this.inhale,
    required this.rear,
    required this.snap,
    required this.blast,
    required this.alert,
    required this.hold,
    required this.pin,
    required this.thump,
    required this.impact,
    required this.over,
    required this.scan,
    required this.sniff,
    required this.exhale,
    required this.wind,
    required this.roar,
    required this.roarKick,
    required this.charge,
    required this.brace,
    required this.lunge,
    required this.kick,
    required this.settle,
    required this.gulp,
    required this.burn,
  });

  /// Seconds into the breath cycle, or -1 outside it.
  final double c;
  final double inhale, rear, snap, blast, alert, hold, pin, thump, impact;
  final double over, scan, sniff, exhale, wind, roar, roarKick, charge, brace;
  final double lunge;
  final double kick, settle;

  /// The three gulps of the inhale (4.33 .. 4.93), each 0 -> 1 -> 0, and the
  /// burn's gate (5.5 .. 7.1: eased in and out) for its slow, heavy motion.
  final double gulp, burn;

  /// How far a coming fireball has the last word over a roar, a flinch or an
  /// intake: 0 with the ball fully charged (the jaws sit on the rules'
  /// anchor), back to 1 as the brace lets go after the launch. It reads
  /// [brace], not the raw charge, so it is continuous through the launch (a
  /// launch during the swarm call used to pop the head 27 degrees).
  double get damp => 1 - DragonPose._ease(DragonPose._ramp(brace, .55, 1));

  /// The rear-back's weight: 1 from the hold until the snap has landed.
  double get rearWeight => rear * (1 - snap);
}

/// Everything the Ember Dragon's pose derives from the boss clock.
///
/// Every channel is a pure function of the [SkyBoss] and its [BossMotion],
/// so pausing, replaying and seeking reproduce a frame exactly. Motion
/// channels (wingbeat, sways, bob, tremble, lag, spring) settle into one
/// still frame under Reduced Motion (`time == 0` and `reduced`); state
/// channels (charge, inhale, blast, alert, roar, fury, flash, heart) keep
/// showing, so every state stays readable.
///
/// THE BREATH TIMELINE (combat seconds into the 11 s cycle; the art's own
/// beats ride the rules' 4.0 / 5.5 / 7.1):
///
///  3.40  alert   the dragon senses the breath: eyes narrow, heart warms
///  4.00  sniff   rules warnAt: the warning band appears; wings flare wide
///  4.30  rear    head rears back and up (+.36,-.17, -.52 rad), jaws part,
///                the whole body gathers: chest swells, sinks .12, tail lifts
///  4.33  gulps   three throat swallows to 4.93, one each .2 s (wings, head
///                and chest each give a small jerk)
///  4.95  HOLD    everything freezes at full tension (jitter, glow at max)
///  5.20  snap    the head lunges to the band in 0.08 s with 10% overshoot
///  5.28  ignite  the jet leaves the jaws (DragonBreathArt.flame `lit`)
///  5.50  burn    rules blastAt: the bird is hurt inside the band; the body
///                rumbles (17 Hz), the chest heaves, the wings pump slowly
///                against the recoil (gated 5.9 .. 7.1, so it eases in and out)
///  7.10  gutter  rules endAt: the flame tears free; exhale droop to 7.55
///  7.30  wind    a short intake before the call
///  7.60  CALL    rules swarmCallAt: a roar calls the swarm bats (7.6..8.6)
///  9.00  CALL 2  fury only (swarmFollowAfter): a second, shorter call
///
/// CONTINUITY. No channel pops at a launch, a snap, the enrage, the arrival's
/// end or the killing blow: where a beat begins it begins from zero, and the
/// defeat blends out of the pose the boss died in (the killing blow freezes
/// it for the hit-stop, then the throes take over by 0.3 s).
final class DragonPose {
  /// The pose of [boss] now. Any non-finite time in the boss (a NaN age from
  /// a bad replay, an infinite `fireIn`, a NaN `lastHitAt`) or in the sky's
  /// light is replaced by a harmless value first, so no channel is ever NaN
  /// and no part of the art (which rounds and hashes channels) can throw; a
  /// boss with only finite times is used as it is.
  factory DragonPose(
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    DragonSkyLight light = DragonSkyLight.neutral,
  }) {
    final safe = _sane(boss, m);
    return DragonPose._(
      safe.$1,
      safe.$2,
      lookY: lookY,
      light: light.dark.isFinite ? light : DragonSkyLight.neutral,
    );
  }

  /// This same moment under another look ([DragonTone]: flash, fury, heat and
  /// the sky's light). Every gradient the parts keep between frames is keyed
  /// by the tone, so painting a pose in a tone the fight has yet to reach
  /// (into a picture nobody sees) builds its paints ahead of time: see
  /// `DragonBossRig`'s prewarm. Same channels, same everything else.
  DragonPose withTone(DragonTone tone) => DragonPose._(
    _boss,
    _m,
    lookY: aim,
    light: DragonSkyLight(dark: tone.dark, sky: tone.sky),
    toneOverride: tone.snapped(),
  );

  static (SkyBoss, BossMotion) _sane(SkyBoss b, BossMotion m) {
    // -infinity is legitimate ("never happened"); NaN and +infinity are not.
    bool bad(double v) => v.isNaN || v == double.infinity;
    final clean =
        b.age.isFinite &&
        b.fireIn.isFinite &&
        !bad(b.lastHitAt) &&
        !bad(b.lastVolleyAt) &&
        !bad(b.lastSummonAt) &&
        !bad(b.enragedAt) &&
        !bad(b.lastCoreHitAt) &&
        (b.defeatedAt?.isFinite ?? true);
    if (clean) return (b, m);
    double never(double v) => bad(v) ? double.negativeInfinity : v;
    final age = b.age.isNaN ? 0.0 : b.age.clamp(-1e7, 1e7);
    final copy = SkyBoss(
      number: b.number,
      x: b.x,
      kind: b.kind,
      cinematic: b.cinematic,
      debut: b.debut,
      callsSwarm: b.callsSwarm,
      upgraded: b.upgraded,
      maxHp: b.maxHp,
    )
      ..hp = b.hp
      ..age = age
      ..fireIn = b.fireIn.isNaN || b.fireIn == double.infinity
          ? 5.0
          : b.fireIn.clamp(-1e7, 1e7)
      ..breathLane = b.breathLane
      ..lastHitAt = never(b.lastHitAt)
      ..lastVolleyAt = never(b.lastVolleyAt)
      ..lastSummonAt = never(b.lastSummonAt)
      ..enragedAt = never(b.enragedAt)
      ..lastCoreHitAt = never(b.lastCoreHitAt);
    if (b.defeatedAt != null) {
      final d = b.defeatedAt!;
      copy.defeatedAt = d.isFinite ? d : age;
    }
    return (
      copy,
      BossMotion(copy, reducedMotion: m.reducedMotion, speech: m.speech),
    );
  }

  DragonPose._(
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    this.light = DragonSkyLight.neutral,
    DragonTone? toneOverride,
  }) : _boss = boss,
       _m = m,
       // ignore: prefer_initializing_formals (a named parameter cannot be private)
       _toneOverride = toneOverride,
       defeated = m.defeated,
       reduced = m.reducedMotion,
       _age = boss.age,
       _arrival = boss.arrivalDuration,
       _fights = boss.isDragon && boss.phase != BossPhase.arriving,
       _enraged = boss.enraged,
       _enragedAt = boss.enragedAt,
       _lastVolleyAt = boss.lastVolleyAt,
       _lastHitAt = boss.lastHitAt,
       _lastSummonAt = boss.lastSummonAt,
       _fireIn = boss.fireIn,
       _defeatAt = boss.defeatedAt ?? double.infinity,
       _calls = boss.isDragon && boss.callsSwarm,
       _follows = boss.isDragon && boss.callsSwarm && boss.swarmFollowsUp,
       time = m.reducedMotion || m.defeated ? 0.0 : boss.age,
       charge = m.defeated ? 0.0 : BossMotion.ease(boss.charge),
       recoil = m.reducedMotion ? 0.0 : m.recoil,
       shot = m.defeated ? 0.0 : m.recoil,
       wince = m.defeated ? 0.0 : m.hit,
       blink = _lids(m),
       mood = m.mood,
       death = m.defeated ? m.death : 0.0,
       flash = m.defeated
           ? 0.0
           : m.reducedMotion
           ? m.hit * .45
           : _hitFlash(boss.age - boss.lastHitAt) * .55,
       aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0,
       lane = boss.breathLane,
       rage = m.defeated ? 0.0 : m.rage,
       summon = m.summon {
    furyBlend = _enraged && !defeated ? _furyBlendAt(_age) : 0.0;
    fury = _enraged && !defeated ? (.8 + rage * .2) * furyBlend : 0.0;
    // Everything below reads the body at this instant; a dead boss reads the
    // instant of its death (frozen) and the defeat overlays it.
    final e = _env(defeated ? _defeatAt : _age);
    inhale = defeated ? 0.0 : e.inhale;
    blast = defeated ? 0.0 : e.blast;
    alert = defeated ? 0.0 : e.alert;
    hold = defeated ? 0.0 : e.hold;
    thump = defeated ? 0.0 : e.thump;
    impact = defeated ? 0.0 : e.impact;
    wind = defeated ? 0.0 : e.wind;
    roar = defeated ? 0.0 : e.roar;
    call = defeated ? 0.0 : math.max(_callAt(_age), summon * .7);
    lunge = defeated ? 0.0 : e.lunge;
    brace = defeated ? 0.0 : e.brace;
    settle = defeated ? 1.0 : e.settle;
    fold = defeated
        ? (reduced
              ? .3
              : .3 * BossMotion.ease(BossMotion.ramp(death, .05, .5)))
        : 0.0;
    slump = defeated ? _slumpOf(_age) : 0.0;
    crack = defeated
        ? (reduced ? .8 : BossMotion.ramp(death, .08, .8))
        : 0.0;
    breath = time == 0 ? 0 : math.sin(time * 2.2) * .03;
    final coreHit = boss.age - boss.lastCoreHitAt;
    crit = coreHit >= 0 && coreHit < .45 && !defeated ? 1 - coreHit / .45 : 0.0;
    head = _headAt(_age);
    neckDrag = reduced
        ? Offset.zero
        : _clampLen(_headAt(_age - .09).at - head.at, .5);
    neckCoil = math
        .max(
          brace,
          math.max(defeated ? 0.0 : e.inhale * (1 - e.snap), wind),
        )
        .clamp(0.0, 1.0);
    pitch = _pitchAt(_age);
    bob = _bobAt(_age);
    chest =
        breath +
        .20 * inhale * (1 - blast * .7) +
        .08 * roar +
        .06 * lunge.clamp(0.0, 1.0) +
        .05 * wind +
        (defeated
            ? 0.0
            : .03 * e.gulp + .04 * math.sin(e.c * 2 * math.pi * 1.1) * e.burn);
    clutch = math.max(brace, inhale) * (1 - slump);
    legKick = blast > 0 ? thump.clamp(-1.0, 1.0) : 0.0;
    throat = math.max(
      math.max(brace * .75, alert * .3),
      math.max(inhale, blast),
    );
    // The ways it smokes combine as independent odds (1 - prod(1 - x)), so
    // the exhale's puff still shows over the smoke of the burn.
    smoke = defeated
        ? .6 * (1 - BossMotion.ramp(death, .6, 1))
        : 1 -
              (1 - .3) *
                  (1 - fury * .4) *
                  (1 - alert * .25) *
                  (1 - inhale * .5) *
                  (1 - roar * .3) *
                  (1 - (defeated ? 0.0 : e.exhale) * .7);
    // A line said in the fight parts the jaws with its words, but never
    // while the dragon is busy with its fire or a roar.
    gape = m.voiced(
      _gapeOf(_age),
      rest: switch (mood) {
        StoryMood.happy => .12,
        StoryMood.surprised => .2,
        StoryMood.angry => .1,
        _ => 0,
      },
      range: switch (mood) {
        StoryMood.angry => .55,
        StoryMood.sad => .3,
        _ => .42,
      },
      // A third of the way into any of them is busy enough: the jaws are
      // the fire's from the moment it gathers.
      busy:
          math.max(
            math.max(math.max(inhale, blast), math.max(roar, wind)),
            math.max(math.max(charge, brace), call),
          ) *
          3,
    );
  }

  /// The blink lid with the mood of a line on it: heavy in sorrow, narrowed
  /// in a gloat, thrown up (below zero) when startled.
  static double _lids(BossMotion m) => switch (m.mood) {
    StoryMood.sad => math.max(m.blink, .42),
    StoryMood.happy => math.max(m.blink, .14),
    StoryMood.surprised => m.blink - .12,
    _ => m.blink,
  };

  /// The rest pose: calm, wings half raised, nothing charging.
  static final still = () {
    final boss = SkyBoss(
      number: 5,
      x: 0,
      kind: BossKind.dragon,
      cinematic: true,
    );
    boss.age = boss.arrivalDuration + 1;
    return DragonPose(boss, BossMotion(boss, reducedMotion: true));
  }();

  /// The defeat [death] seconds in, as a pose of its own: the falling crown
  /// starts from where the slumped head really is. The pose the boss died in
  /// has faded out of it by 0.3 s (when the circlet leaves), so this is
  /// exact for any real defeat from then on.
  static DragonPose atDeath(double death, {bool reduced = false}) {
    final boss = SkyBoss(
      number: 5,
      x: 0,
      kind: BossKind.dragon,
      cinematic: true,
    );
    boss.age = boss.arrivalDuration + 10;
    boss.defeatedAt = boss.age - death;
    return DragonPose(boss, BossMotion(boss, reducedMotion: reduced));
  }

  // ------------------------------------------------------------ inputs --

  final SkyBoss _boss;
  final BossMotion _m;
  final DragonTone? _toneOverride;

  /// Whether the dragon is still arriving (the silhouette, the reveal, the
  /// roar): four seconds in which nothing else needs the frame's time.
  bool get arriving => _age < _arrival && !defeated;

  final bool defeated, reduced;
  final double _age, _arrival, _enragedAt, _lastVolleyAt, _lastHitAt;
  final double _lastSummonAt, _fireIn, _defeatAt;
  final bool _fights, _enraged, _calls, _follows;

  /// The backdrop's light: how dark the sky is and the colour it bounces.
  final DragonSkyLight light;

  /// Seconds on the boss clock; zero whenever the dragon must hold still.
  final double time;

  // ---------------------------------------------------------- state channels
  // (kept under Reduced Motion)

  /// The fireball's charge, eased 0 to 1 over the 0.65 s before it leaves.
  final double charge;

  /// The shot's recoil pulse (motion; zero under Reduced Motion) and the
  /// same pulse kept as a state for the jaws.
  final double recoil, shot;

  /// The hit's flinch pulse and the pale flash it throws. The flash bites in
  /// two frames and drains over the rest of the 0.28 s (a slow pulse under
  /// Reduced Motion).
  final double wince, flash;

  /// The blink lid, the eye's aim (-1 up .. 1 down), the defeat's clock.
  final double blink, aim, death;

  /// The mood of a line the dragon is saying, or null (BossMotion.mood).
  final StoryMood? mood;

  /// Where the eye looks, -1 up .. 1 down: along [aim], or at the ground in
  /// a sorry line. The head itself keeps to [aim].
  double get look {
    final down = switch (mood) {
      StoryMood.sad => .9,
      StoryMood.surprised => -.4,
      _ => 0.0,
    };
    return (aim + down).clamp(-1.0, 1.0);
  }

  /// Raw pulses: fury onset (1.1 s) and a swarm call landing (0.7 s).
  final double rage, summon;
  final BreathLane lane;

  /// Fury, 0 to 1: the plates heat, the seams flare, the stance changes.
  /// Eases in over 0.45 s from the moment the boss crosses half health, so
  /// the colour never pops.
  late final double fury;

  /// 0 to 1 over the fury onset only (the transformation).
  late final double furyBlend;

  /// 0 to 1 through the inhale (sniff, rear back), held at 1 through the
  /// hold and the flame, released over 0.5 s after it.
  late final double inhale;

  /// The flame: 0 to 1 at the snap, held, 0 again as it gutters out.
  late final double blast;

  /// The breath is coming: 0 to 1 from 3.4 s, held until the flame ends.
  late final double alert;

  /// The held breath, 4.95 to 5.20 s: 1 while the dragon is frozen at full
  /// tension (motion; zero under Reduced Motion).
  late final double hold;

  /// The intake before a roar (arrival, swarm call), 0 to 1 (motion).
  late final double wind;

  /// The roar: 0 to 1 for the arrival roar, the swarm call and the fury
  /// onset. Throws the head up, opens the jaws, flings the wings up.
  late final double roar;

  /// The swarm call's whole envelope (intake, roar, fade), 0 to 1: for the
  /// call cue effect (DragonCallArt).
  late final double call;

  /// The fireball lunge: the head's extension toward its mouth anchor, 0 at
  /// rest, exactly 1 as the fireball leaves, then a damped spring (dips
  /// slightly below 0) back to rest after the shot. Continuous at launch.
  late final double lunge;

  /// The fireball's hold on the body: [charge] while it builds, then it lets
  /// go over the 0.3 s after launch (a fade, not a drop). Wings, claws, neck,
  /// glare and glow read this so nothing pops when the ball leaves.
  late final double brace;

  /// The body's recoil spring after the snap, -1..1 (motion). It builds over
  /// the snap (5.20..5.28) and rings out by 6.4 s.
  late final double thump;

  /// 1 at the instant the jet leaves the jaws (5.28) decaying to 0 within
  /// 0.4 s: for flashes and shakes in the effects layer (motion). It is an
  /// event, so it begins at 1.
  late final double impact;

  /// Wings laid back (defeat), the defeat's sag, and the seam cracks that
  /// run out from the heart as it breaks, 0 to 1.
  late final double fold, slump, crack;

  /// A gentle idle chest swell, and a hit on the open heart just now.
  late final double breath, crit;

  // ------------------------------------------------------ derived channels

  /// The look every part shares (with the sky's light in it), on the steps of
  /// [DragonTone.key] ([DragonTone.snapped]): the parts keep their gradients
  /// between frames under that key, and a gradient built from the raw value of
  /// whichever frame came first would give the same state different pixels
  /// depending on what was drawn before it (the final QA found 6 to 8 of 45
  /// states differing by up to 7/255). See [exactTone] for the raw values.
  DragonTone get tone => _toneOverride ?? exactTone.snapped();

  /// The same look at full precision (the tests and the prewarm's ladders).
  DragonTone get exactTone => DragonTone(
    flash: flash,
    fury: fury,
    heat: math.max(
      math.max(brace * .6, alert * .2),
      math.max(inhale, blast),
    ),
    dark: light.dark,
    sky: light.sky,
  );

  /// How far the jaws are open, 0 to 1: a sliver while sniffing, wider as the
  /// dragon rears (.15 to .35), a dip at the hold (the coil), wide at the
  /// snap and the roar, and a wide snap at a fireball's launch that closes
  /// over 0.3 s. A line's words open it too, while nothing else does.
  late final double gape;

  /// How hard it glares (an angry line glares too).
  double get glare => defeated
      ? 0
      : math.max(
          math.max(math.max(fury, alert * .6), math.max(brace, inhale)),
          mood == StoryMood.angry ? 1 : 0,
        );

  /// The heart's light: dim at rest with a slow heartbeat, blazing while it
  /// is open.
  double get heart => defeated
      ? 1 - BossMotion.ramp(death, .7, 1)
      : (math.max(
                  .2 + fury * .25 + alert * .2,
                  math.max(inhale, blast * .9),
                ) +
                _heartbeat())
            .clamp(0.0, 1.0);

  /// A double thump (lub-dub) once a beat (1.3 Hz): quick and small, gone
  /// while the heart is open, never enough to read as a change of state.
  double _heartbeat() {
    if (reduced) return 0;
    final phase = time * 1.3 % 1;
    final lub = math.pow(math.sin(math.pi * phase.clamp(0.0, .3) / .3), 2);
    final dub = math.pow(
      math.sin(math.pi * (phase - .34).clamp(0.0, .26) / .26),
      2,
    );
    return (lub * .05 + dub * .03).toDouble() * (1 + fury * .6) * (1 - inhale);
  }

  /// Fire rising up the throat and the smoke from the nostrils, 0 to 1.
  late final double throat, smoke;

  /// 1 when idle life (sway, counter-beat, bob) shows; 0 while the fireball
  /// is charged or the breath pins the wings, fading back in over half a
  /// second after either.
  late final double settle;

  /// The whole figure turns about the heart by this many radians; positive
  /// is nose-UP (the head side rises). The rig rotates everything by it.
  late final double pitch;

  /// The whole figure shifts by this in rig units (wing-beat lift, recoil,
  /// flinch, rumble). At most .3 long.
  late final Offset bob;

  /// The chest's swell, 0 to about .3: idle breath, the inhale's great
  /// draught, the roar, the lunge.
  late final double chest;

  /// Claws curl in as it charges or inhales (0 to 1), and the hind legs kick
  /// back at the snap (-1..1, motion).
  late final double clutch, legKick;

  /// The neck lags a fast head: the S bends against the head's movement.
  /// Rig units, at most .5 long; [neckCoil] tightens the S while it gathers.
  late final Offset neckDrag;
  late final double neckCoil;

  /// The wingbeat as a stroke: -1 raised high, 1 swept down. This is the
  /// near wing's elbow; see [nearWing] for the joints.
  double get stroke => _stroke(_age, 0, 1);

  /// The wings' joint strokes. The far wing beats a phase (0.55 rad) behind
  /// at 88% of the amplitude.
  late final DragonWingMotion nearWing = _wingMotion(far: false);
  late final DragonWingMotion farWing = _wingMotion(far: true);

  /// The tail's bend at [u] (0 root .. 1 blade): a vertical offset in rig
  /// units (positive: down) of that point of its rest spine. A travelling
  /// wave that follows the wingbeat plus slow sway; the impulses (the lift
  /// of the inhale, the whip of the snap, the flinch, the roar, the launch's
  /// counter-whip, the exhale sag) reach the blade about 0.11 s after the
  /// root, so it whips instead of swinging as a plank. |value| <= .5.
  double tailBend(double u) {
    final k = u * u;
    final a = _age - .11 * u;
    final aa = math.min(a, _defeatAt);
    final e = _env(aa);
    var v = 0.0;
    if (!reduced) {
      final t = math.min(_age, _defeatAt);
      // The wing-driven wave stops with the wings; the slow sway only
      // stills for the hold, so the tail never looks frozen while it burns.
      final calm = (1 - .5 * e.pin) * (1 - e.hold);
      final wave =
          math.sin(_phaseAt(t) - 1.6 * u) * .6 * e.settle +
          math.sin(t * 1.4 - 2.2 * u + 1) * .4 * calm;
      v += wave * (.04 + .16 * k);
      // Braced against the jet, the tail lashes slowly.
      if (e.c >= 0) {
        final gate =
            _ramp(e.c, 5.5, 5.9) * (1 - _ramp(e.c, 6.8, DragonBreath.endAt));
        v += .24 * k * math.sin(2.1 * (e.c - 5.4) - 1.6 * u) * gate;
      }
      v += .22 * k * e.thump;
      v -= .3 * k * e.kick;
      v += .15 * k * e.exhale;
      final tau = aa - _lastVolleyAt;
      if (_fights && tau >= 0 && tau < .6) {
        v += .22 * k * math.exp(-7 * tau) * math.sin(2 * math.pi * tau / .42);
      }
    }
    v -= .42 * k * e.rearWeight;
    v -= .4 * k * e.roar;
    var out = v * _fade(a);
    out += .5 * k * _slumpOf(a);
    return out.clamp(-.5, .5);
  }

  /// A gentle repeating sway of [amp] at [rate] rad/s, [phase] radians in.
  double sway(double rate, double amp, [double phase = 0]) =>
      time == 0 ? 0 : math.sin(time * rate + phase) * amp;

  /// The near wing's beat as the body feels it, -1..1, sampled [lag] seconds
  /// ago: the waveform, faded out while the wings are pinned (the breath) or
  /// braced (the fireball). Parts hang their follow-through on this (legs
  /// .25, head .14, torso .04), so nothing bobs to a beat that has stopped.
  double beatAt(double lag) {
    if (reduced || defeated) return 0;
    final a = _age - lag;
    return _wave(_phaseAt(a)) * _env(a).settle;
  }

  /// Where the head sits and points, in the (pitched) rig frame: the skull's
  /// centre in rig units and its turn (positive tips the snout down).
  late final ({Offset at, double angle}) head;

  /// [local] (in the head's frame, scale 1) as a rig point. Mirrors
  /// `DragonHeadArt.point`; does not include [pitch] or [bob].
  Offset headPoint(Offset local) =>
      head.at + DragonKit.turn(local * DragonLayout.headScale, -head.angle);

  /// [local] (in the pitched figure's frame) as a rig point: pitch, then bob.
  Offset toRig(Offset local) => DragonKit.turn(local, pitch) + bob;

  // ---------------------------------------------------------------- math --

  static double _ramp(double v, double a, double b) =>
      BossMotion.ramp(v, a, b);
  static double _ease(double t) => BossMotion.ease(t);
  static double _outCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
  static Offset _clampLen(Offset v, double max) {
    final d = v.distance;
    return d <= max || d == 0 ? v : v * (max / d);
  }

  /// The wingbeat waveform: the downstroke is quick (37% of the beat) and the
  /// upstroke slow (63%), measured on the original.
  static double _wave(double phi) => math.sin(phi + .45 * math.sin(phi));

  /// The hit flash: bites in 0.03 s, drains by 0.28 s.
  static double _hitFlash(double tau) => tau < 0 || tau > .28
      ? 0
      : tau < .03
      ? tau / .03
      : 1 - _ease(_ramp(tau, .03, .28));

  /// The hit's flinch: snaps in 0.05 s, relaxes by 0.32 s.
  static double _kickOf(double tau) => tau < 0 || tau > .32
      ? 0
      : tau < .05
      ? _outCubic(tau / .05)
      : 1 - _ease(_ramp(tau, .05, .32));

  // Breath-cycle beats, as functions of the combat second [c] in the cycle.
  static const _sniff = DragonTimeline.sniffAt;
  static const _rear = DragonTimeline.rearAt;
  static const _holdAt0 = DragonTimeline.holdAt;
  static const _snapAt = DragonTimeline.snapAt;
  static const _snapSeconds = DragonTimeline.snapSeconds;
  static const _ignite = DragonTimeline.igniteAt;

  static double _inhaleAt(double c) {
    if (c < _sniff) return 0;
    if (c < _holdAt0) return _ease(_ramp(c, _sniff, _holdAt0));
    if (c < DragonBreath.endAt) return 1;
    return 1 - _ease(_ramp(c, DragonBreath.endAt, DragonBreath.endAt + .5));
  }

  /// The head's rear-back weight: eases in from 4.30 to 4.95 and lets go the
  /// moment the snap takes over (see [_Env.rearWeight]).
  static double _rearAt(double c) =>
      c >= DragonBreath.endAt ? 0 : _ease(_ramp(c, _rear, _holdAt0));

  /// The snap alone (no release), 0 to 1 over 5.20..5.28.
  static double _snapOf(double c) =>
      c < _snapAt ? 0 : _outCubic(_ramp(c, _snapAt, _snapAt + _snapSeconds));

  static double _blastAt(double c) {
    if (c < _snapAt) return 0;
    final out = _ease(_ramp(c, DragonBreath.endAt, DragonBreath.endAt + .45));
    return _snapOf(c) * (1 - out);
  }

  static double _alertAt(double c) => c < DragonTimeline.alertAt
      ? 0
      : _ease(_ramp(c, DragonTimeline.alertAt, DragonTimeline.alertFull)) *
            (1 - _ease(_ramp(c, DragonBreath.endAt, DragonBreath.endAt + .5)));

  /// 1 from 4.95 to 5.17, easing in over the 0.04 s before and out over the
  /// 0.03 s after: 0.25 s above one half.
  static double _holdAt(double c) =>
      _ramp(c, _holdAt0 - .04, _holdAt0) *
      (1 - _ramp(c, DragonTimeline.holdEnd - .03, DragonTimeline.holdEnd));

  /// How far the wings are pinned by the breath: they flare to the ceiling
  /// with ease-out-cubic by 4.30, stay there through the burn and let go
  /// over 0.5 s after the flame.
  static double _pinAt(double c) => c < _sniff
      ? 0
      : c < DragonBreath.endAt
      ? _outCubic(_ramp(c, _sniff, DragonTimeline.flareEnd))
      : 1 - _ease(_ramp(c, DragonBreath.endAt, DragonBreath.endAt + .5));

  /// +10% on the lane reach, peaking a little after the snap has landed.
  static double _overAt(double c) => c >= _snapAt && c < 5.46
      ? .10 * math.sin(math.pi * _ramp(c, _snapAt, 5.46))
      : 0;

  /// A small forward nudge as the dragon draws the first breath (4.0..4.42):
  /// the anticipation before the rear-back, 0 to 1 to 0.
  static double _sniffAt(double c) =>
      c <= _sniff + .02 || c >= _sniff + .42
      ? 0
      : math.sin(math.pi * _ramp(c, _sniff + .02, _sniff + .42));

  /// The body's recoil after the snap: builds over the snap and rings out as
  /// `exp(-9 dt) cos(2 pi dt / .30)` from the ignite.
  static double _thumpAt(double c) {
    if (c < _snapAt || c >= 6.4) return 0;
    final dt = math.max(0.0, c - _ignite);
    return _ease(_ramp(c, _snapAt, _ignite)) *
        math.exp(-9 * dt) *
        math.cos(2 * math.pi * dt / .30);
  }

  static double _impactAt(double c) => c >= _ignite && c < 5.7
      ? math.exp(-9 * (c - _ignite)) * (1 - _ease(_ramp(c, 5.5, 5.7)))
      : 0;

  /// The three gulps of the inhale: the dragon swallows air in three beats
  /// (4.33 .. 4.53, 4.53 .. 4.73, 4.73 .. 4.93), each 0 -> 1 -> 0 (peaks at
  /// 4.43, 4.63, 4.83), the last still 20 ms before the hold.
  static double _gulpAt(double c) {
    final x = (c - 4.33) / .2;
    if (x <= 0 || x >= 3) return 0;
    final f = x - x.floorToDouble();
    return math.pow(math.sin(math.pi * f), 2).toDouble();
  }

  /// The burn's gate: eased in over 5.5 .. 5.9 and out over 6.8 .. 7.1.
  static double _burnAt(double c) =>
      _ease(_ramp(c, DragonBreath.blastAt, 5.9)) *
      (1 - _ease(_ramp(c, 6.8, DragonBreath.endAt)));

  /// The head sweeping the band while the jet burns, +-.12 vertically (5 px):
  /// one whole sweep in the 1.6 s of the flame.
  static double _scanAt(double c) => c < DragonBreath.blastAt
      ? 0
      : math.sin((c - DragonBreath.blastAt) * 2 * math.pi / 1.6) *
            .12 *
            _ramp(c, DragonBreath.blastAt, DragonBreath.blastAt + .4) *
            (1 - _ramp(c, DragonBreath.endAt - .4, DragonBreath.endAt));

  /// 0 to 1 to 0 over the exhale (7.10..7.60): the droop, the smoke puff.
  static double _exhaleAt(double c) => c < DragonBreath.endAt ||
          c >= DragonBreath.endAt + .5
      ? 0
      : math.sin(
          math.pi * _ramp(c, DragonBreath.endAt, DragonBreath.endAt + .5),
        );

  // The swarm call: intake before, roar after, one call at 7.6 s and (in
  // fury) a second at 9.0 s.
  static double _windOfCall(double tau) => tau < -.3
      ? 0
      : tau < 0
      ? _ease((tau + .3) / .3)
      : tau < .15
      ? 1 - _ease(tau / .15)
      : 0;

  static double _roarOfCall(double tau) => tau < 0
      ? 0
      : tau < .15
      ? _ease(tau / .15)
      : tau < .45
      ? 1
      : tau < 1.0
      ? 1 - _ease((tau - .45) / .55)
      : 0;

  /// The arrival's roar: a fast attack (0.16 s: the jaws are open when the
  /// plume and the shockwave are), a hold of 0.30 s and a slow release over
  /// 0.45 s, so it is full from 2.81 to 3.11 (the review found the jaws at 34%
  /// when the plume was full: a symmetric bell peaked at 3.05).
  static double _roarOfArrival(double k) => k <= 0
      ? 0
      : k < .16
      ? _ease(k / .16)
      : k < .46
      ? 1
      : k < .91
      ? 1 - _ease((k - .46) / .45)
      : 0;

  /// The fury onset's roar: a beat of stillness after the blow (the flinch
  /// lands first), a fast throw by 0.30 s, a hold, and the long fall.
  static double _roarOfFury(double since) => since < .12
      ? 0
      : since < .30
      ? _outCubic((since - .12) / .18)
      : since < .60
      ? 1
      : since < 1.1
      ? 1 - _ease((since - .60) / .50)
      : 0;

  /// The fury's extra beat phase: the rate ramps 5.4 -> 7.2 rad/s over the
  /// blend, so the flap quickens instead of lurching.
  static double _furyPhase(double since) {
    const t = DragonTimeline.furyBlendSeconds;
    if (since <= 0) return 0;
    final extra = DragonTimeline.furyOmega - DragonTimeline.beatOmega;
    if (since >= t) return extra * (since - t / 2);
    final x = since / t;
    return extra * t * (x * x * x - x * x * x * x / 2);
  }

  /// Seconds into the breath cycle at [age], or -1 when the dragon is not
  /// breathing then (arrival, or before the fight).
  double _cycleOf(double age) => _fights && age >= _arrival
      ? (age - _arrival) % DragonBreath.period
      : -1.0;

  double _furyBlendAt(double age) {
    if (!_enraged) return 0;
    if (reduced) return 1;
    final since = age - _enragedAt;
    return !since.isFinite
        ? 1.0
        : _ease(_ramp(since, 0, DragonTimeline.furyBlendSeconds));
  }

  double _windAt(double age) {
    if (reduced) return 0;
    var w = 0.0;
    if (age < _arrival) {
      final k = age - SkyBoss.roarAt;
      w = math.max(
        w,
        k < 0 ? _ease(_ramp(k, -.3, 0)) : 1 - _ease(_ramp(k, 0, .2)),
      );
    }
    final c = _cycleOf(age);
    if (c >= 0 && _calls) {
      w = math.max(w, _windOfCall(c - DragonTimeline.callAt));
      if (_follows) {
        w = math.max(
          w,
          _windOfCall(c - SkyBoss.swarmCallAt - SkyBoss.swarmFollowAfter) * .8,
        );
      }
    }
    return w.clamp(0.0, 1.0);
  }

  double _callAt(double age) {
    final c = _cycleOf(age);
    if (c < 0 || !_calls) return 0;
    var v = math.max(
      _windOfCall(c - DragonTimeline.callAt) * .55,
      _roarOfCall(c - SkyBoss.swarmCallAt),
    );
    if (_follows) {
      final tau = c - SkyBoss.swarmCallAt - SkyBoss.swarmFollowAfter;
      v = math.max(
        v,
        math.max(_windOfCall(tau) * .55, _roarOfCall(tau)) * .8,
      );
    }
    return v;
  }

  double _roarAt(double age) {
    final c = _cycleOf(age);
    var r = age < _arrival ? _roarOfArrival(age - SkyBoss.roarAt) : 0.0;
    if (c >= 0 && _calls) {
      r = math.max(r, _roarOfCall(c - SkyBoss.swarmCallAt) * .85);
      if (_follows) {
        r = math.max(
          r,
          _roarOfCall(c - SkyBoss.swarmCallAt - SkyBoss.swarmFollowAfter) * .68,
        );
      }
    }
    // The rules' own pulse for a call, which the clock above anticipates.
    r = math.max(r, BossMotion.pulse(age - _lastSummonAt, .7) * .7);
    // Crossing into fury is a roar too.
    if (_enraged && age < _defeatAt) {
      r = math.max(r, _roarOfFury(age - _enragedAt) * .9);
    }
    return r;
  }

  /// The throw of a roar overshoots: the head goes a little past its roar
  /// pose in the first 0.35 s and settles back (motion; the head only).
  double _roarKickAt(double age) {
    double bump(double tau) =>
        tau <= 0 || tau >= .35 ? 0.0 : math.sin(math.pi * tau / .35);
    var k = 0.0;
    final c = _cycleOf(age);
    if (c >= 0 && _calls) {
      k = math.max(k, bump(c - SkyBoss.swarmCallAt) * .85);
      if (_follows) {
        k = math.max(
          k,
          bump(c - SkyBoss.swarmCallAt - SkyBoss.swarmFollowAfter) * .68,
        );
      }
    }
    if (_enraged && age < _defeatAt) {
      k = math.max(k, bump(age - _enragedAt - .12) * .9);
    }
    return k * .18;
  }

  /// The fireball charge at [age], derived from the rules' countdown: the
  /// shot's own charge if a volley left since, else the countdown run back.
  double _chargeAt(double age) {
    if (!_fights || age < _arrival) return 0;
    final ref = math.min(_age, _defeatAt);
    final left = _lastVolleyAt > age && _lastVolleyAt <= ref
        ? _lastVolleyAt - age
        : _fireIn + (ref - age);
    return _ease((1 - left / .65).clamp(0.0, 1.0));
  }

  double _springAt(double age) {
    final tau = age - _lastVolleyAt;
    if (reduced || !_fights || tau < 0 || tau > .6) return 0;
    // (The tail of the spring is folded away over 0.45 .. 0.6 s, so it ends
    // at exactly zero instead of a 0.2% step.)
    return math.exp(-9 * tau) * math.cos(14 * tau) * (1 - _ramp(tau, .45, .6));
  }

  /// The fireball's hold on the body after it leaves: the wings, claws, neck
  /// and glow let go over 0.45 s instead of dropping with the charge (and a
  /// roar, flinch or intake that the ball had pushed aside comes back as it
  /// lets go, never in one tick).
  double _afterglowAt(double age) {
    final tau = age - _lastVolleyAt;
    if (reduced || !_fights || tau < 0 || tau >= .45) return 0;
    return 1 - _ease(tau / .45);
  }

  /// The jaws in a volley: snap wide from the charge's .55 as the ball
  /// leaves, then close over 0.3 s (kept under Reduced Motion).
  static double _shotGape(double tau) => tau < 0 || tau > .36
      ? 0
      : tau < .05
      ? .55 + .45 * _ease(tau / .05)
      : 1 - _ease(_ramp(tau, .05, .36));

  _Env _env(double age) {
    final c = _cycleOf(age);
    final motion = !reduced;
    final inhale = c < 0 ? 0.0 : _inhaleAt(c);
    final alert = c < 0 ? 0.0 : _alertAt(c);
    final pin = c < 0 ? 0.0 : _pinAt(c);
    final charge = _chargeAt(age);
    final tau = age - _lastVolleyAt;
    final hush = !motion || !_fights || tau < 0 || tau > .5
        ? 0.0
        : 1 - _ease(_ramp(tau, 0, .5));
    return _Env(
      c: c,
      inhale: inhale,
      rear: c < 0 ? 0.0 : _rearAt(c),
      snap: c < 0 ? 0.0 : _snapOf(c),
      blast: c < 0 ? 0.0 : _blastAt(c),
      alert: alert,
      hold: motion && c >= 0 ? _holdAt(c) : 0.0,
      pin: pin,
      thump: motion && c >= 0 ? _thumpAt(c) : 0.0,
      impact: motion && c >= 0 ? _impactAt(c) : 0.0,
      over: motion && c >= 0 ? _overAt(c) : 0.0,
      scan: motion && c >= 0 ? _scanAt(c) : 0.0,
      sniff: motion && c >= 0 ? _sniffAt(c) : 0.0,
      exhale: c < 0 ? 0.0 : _exhaleAt(c),
      wind: _windAt(age),
      roar: _roarAt(age),
      roarKick: motion ? _roarKickAt(age) : 0.0,
      charge: charge,
      brace: charge > 0 ? charge : _afterglowAt(age),
      lunge: charge > 0 ? charge : _springAt(age),
      kick: motion ? _kickOf(age - _lastHitAt) : 0.0,
      settle:
          (1 - math.max(charge, hush)) *
          (1 - pin) *
          (1 - .4 * alert * (1 - inhale)),
      gulp: motion && c >= 0 ? _gulpAt(c) : 0.0,
      burn: c < 0 ? 0.0 : _burnAt(c),
    );
  }

  /// The alive weight of the pose the boss died in, 1 until the killing blow
  /// and gone by 0.3 s after it.
  double _fade(double age) => age < _defeatAt
      ? 1.0
      : reduced
      ? 0.0
      : 1 - _ease(_ramp(age - _defeatAt, 0, .3));

  double _slumpOf(double age) => age < _defeatAt
      ? 0.0
      : reduced
      ? .7
      : _ease(_ramp(age - _defeatAt, 0, .55));

  // The beat keeps its phase when fury quickens it, so the wings never jump.
  double _phaseAt(double age) {
    var phi = age * DragonTimeline.beatOmega - _arrivalLoss(age);
    if (_enraged) {
      final since = age - _enragedAt;
      phi = since.isFinite
          ? phi + _furyPhase(since)
          : age * DragonTimeline.furyOmega;
    }
    return phi;
  }

  /// The arrival's beat starts slow (2.8 rad/s) and quickens to the calm rate
  /// by 2.65 s, so the silhouette flaps majestically; the closed form of the
  /// integral keeps every later frame continuous.
  static double _arrivalLoss(double age) {
    const slow = DragonTimeline.beatOmega - DragonTimeline.arrivalOmega;
    const from = .6, to = 2.65;
    if (age <= from) return slow * age;
    final x = ((age - from) / (to - from)).clamp(0.0, 1.0);
    return slow * (from + (to - from) * (x - x * x * x + x * x * x * x / 2));
  }

  // ------------------------------------------------------------ the wings --

  /// The elbow stroke at [age] (the other joints sample it a little
  /// earlier), [shift] radians behind in the beat and scaled by [amp].
  double _stroke(double age, double shift, double amp) {
    final aa = math.min(age, _defeatAt);
    var s = _aliveStroke(_env(aa), aa, shift);
    if (age >= _defeatAt) {
      // The killing blow freezes the beat for the hit-stop, then the wings
      // fold out and down in three uneven beats and go limp.
      final d = age - _defeatAt;
      final crumple = reduced
          ? 0.0
          : .45 *
                (.55 * math.sin(14 * d) +
                    .30 * math.sin(23 * d + .9) +
                    .15 * math.sin(31 * d + 2.1)) *
                _ease(_ramp(d, 0, .1)) *
                (1 - _ramp(d, .55, .9));
      final target = -.1 + _slumpOf(age) * .9 + crumple;
      s += (target - s) * (reduced ? 1.0 : _ease(_ramp(d, 0, .18)));
    }
    return (s * amp).clamp(-1.0, 1.0);
  }

  double _aliveStroke(_Env e, double age, double shift) {
    final motion = !reduced;
    var s = motion ? -.15 + .85 * _wave(_phaseAt(age) - shift) : -.25;
    // Calm before the breath: the beat settles high and slow.
    s += (-.45 - s) * (e.alert * (1 - e.inhale) * .4);
    // The fireball: the wings brace low and stiff, and the shot kicks them.
    s += (.05 - s) * (e.brace * .6);
    final tau = age - _lastVolleyAt;
    if (motion && _fights && tau >= 0 && tau < .3) {
      s += .25 * math.sin(math.pi * tau / .3);
    }
    s += .2 * e.kick;
    if (e.c >= 0) s = _breathStroke(s, e, motion);
    s += (-.5 - s) * e.wind;
    // The roar throws the wings to the top of the stroke and holds them
    // there (a blend, so it arrives without a clamp's corner).
    s += (-1 - s) * (e.roar / .83).clamp(0.0, 1.0);
    return s.clamp(-1.0, 1.0);
  }

  /// The wings through the breath: flare to -.9 as the sniff lands (ease-out
  /// cubic by 4.30), three gulps while it builds, whip down to +.6 at the snap
  /// (held 50 ms), rebound to -.3 by 5.42, then pin back at +.15 and pump
  /// slowly through the burn until the flame gutters and they return to the
  /// beat over 0.5 s.
  double _breathStroke(double beat, _Env e, bool motion) {
    final c = e.c;
    if (c < _sniff || c >= DragonBreath.endAt + .5) return beat;
    var s = beat + (-.9 - beat) * e.pin;
    if (motion && c >= 4.33 && c < _snapAt) {
      // Three gulps: each swallows the wings from the flare (-.9) toward
      // -.55 and back (the old 22 Hz tremble was 1 px and invisible).
      s += .35 * e.gulp;
    }
    if (c >= _snapAt) {
      final double w;
      if (!motion) {
        // Reduced Motion keeps where the wings end up, not the crack: they
        // settle over 0.25 s instead of 80 ms.
        w = -.9 + 1.05 * _ease(_ramp(c, _snapAt, _snapAt + .25));
      } else if (c < 5.25) {
        w = -.9 + 1.5 * _ease(_ramp(c, _snapAt, 5.25));
      } else if (c < 5.30) {
        w = .6; // held at the bottom of the whip for 50 ms
      } else if (c < 5.42) {
        w = .6 - .9 * _outCubic(_ramp(c, 5.30, 5.42));
      } else {
        w = -.3 + .45 * _ease(_ramp(c, 5.42, 5.8));
      }
      s = w;
      if (motion) {
        // The burn: the wings pump slowly and heavily (.22 at 0.7 Hz).
        s +=
            .22 *
            math.sin(2 * math.pi * .7 * (c - 5.9)) *
            _ramp(c, 5.9, 6.3) *
            (1 - _ramp(c, 6.62, DragonBreath.endAt));
      }
    }
    if (c >= DragonBreath.endAt) {
      s += (beat - s) * _ease(_ramp(c, DragonBreath.endAt, DragonBreath.endAt + .5));
    }
    return s;
  }

  DragonWingMotion _wingMotion({required bool far}) {
    final shift = far ? DragonTimeline.farPhase : 0.0;
    final amp = far ? DragonTimeline.farAmp : 1.0;
    // Under Reduced Motion every joint is at the same stroke (no lag, no
    // ripple through the fingers as a state changes).
    final lead = _stroke(_age, shift, amp);
    double at(double lag) => reduced ? lead : _stroke(_age - lag, shift, amp);
    final trail = reduced ? lead : at(.06);
    final push = ((lead - trail) / .35).clamp(-1.0, 1.0);
    final tips = [
      for (var i = 0; i < 4; i++)
        at(DragonTimeline.fingerLag + DragonTimeline.fingerStep * i),
    ];
    return DragonWingMotion(
      elbow: lead,
      wrist: at(DragonTimeline.wristLag),
      tips: tips,
      // A tip never trails up into the ceiling: the upward flex fades out
      // as its own stroke nears the top of the beat.
      flex: [
        for (var i = 0; i < 4; i++)
          push *
              .2 *
              (.4 + .2 * i) *
              (push > 0 ? _ramp(tips[i], -.95, -.6) : 1.0),
      ],
      fold: fold,
      spread: math
          .max(
            math.max(inhale * .5, fury * .4),
            math.max(roar * .6, wind * .3),
          )
          .clamp(0.0, 1.0),
      sag: push.abs(),
    );
  }

  // ------------------------------------------------------------- the head --

  /// The head's pose when the mouth is on the rules' anchor for the current
  /// look: the same turn about the mouth, so aiming never moves the anchor.
  late final Offset _chargeAt0 =
      DragonLayout.rulesMouth -
      DragonKit.turn(
        DragonLayout.headMouth * DragonLayout.headScale,
        -(DragonLayout.headChargeAngle + aim * .07),
      );

  /// The head at [age] (the neck's drag compares it with a moment earlier).
  _Head _headAt(double age) {
    final aa = math.min(age, _defeatAt);
    final e = _env(aa);
    final motion = !reduced;
    const rest = DragonLayout.headRest;
    final angleRest = DragonLayout.headRestAngle + aim * .07;
    final angleCharge = DragonLayout.headChargeAngle + aim * .07;
    // The fireball: pulled back a little, then lunged to the mouth anchor
    // (exactly the rules' at charge 1); after the shot it springs home.
    var at = Offset.lerp(rest, _chargeAt0, e.lunge)!;
    var angle = angleRest + (angleCharge - angleRest) * e.lunge;
    if (motion && e.charge > 0) {
      // A smooth bump (zero slope at both ends) peaking at charge .275.
      final x = math.min(e.charge / .55, 1.0);
      at += const Offset(.14, .06) * ((1 - math.cos(2 * math.pi * x)) / 2);
    }
    // The ball leaves and the head rocks back and up with it (it starts at
    // zero, so it is continuous with the lunge at the launch).
    final shotAge = aa - _lastVolleyAt;
    if (motion && _fights && shotAge > 0 && shotAge < .28) {
      at += const Offset(.14, -.05) * math.sin(math.pi * shotAge / .28);
    }
    // Idle life: sway, breath and the counter-beat of the wings.
    if (motion) {
      at +=
          Offset(
            math.sin(aa * 1.3) * .03,
            math.sin(aa * 2.2) * .03 * 1.2 + math.sin(aa * 1.1 + 1) * .025,
          ) *
          e.settle;
      at += Offset(0, -.16 * _wave(_phaseAt(aa - .14))) * e.settle;
      angle += .08 * _wave(_phaseAt(aa - .20)) * e.settle;
    }
    // The stance in fury: the head rides lower, glowering.
    at += Offset(0, .10) * (_furyBlendAt(aa) * e.settle);
    // Before the breath: the head dips as the dragon senses it, then noses
    // forward for the first draught (the anticipation of the rear-back).
    at += Offset(0, .05) * (e.alert * (1 - e.pin));
    at += const Offset(-.06, .07) * e.sniff;
    // The inhale rears the head back and up; the hold trembles; the flame
    // drives it at the band and overshoots a little.
    final rw = e.rearWeight;
    // The head goes mostly BACK (there is no head-room above it: the eye
    // must stay clear of the health bar), the body's lean, sink and chest
    // carry the rest.
    at += const Offset(.36, -.17) * rw;
    angle += -.52 * rw;
    // Each gulp jerks the head back a little more.
    at += const Offset(.05, .025) * e.gulp;
    if (e.hold > 0) {
      // The held breath shakes: +-.035 at 26 / 29 Hz (1.5 px: it shows, and
      // it does not alias to a still at 30 fps like 30 / 33 Hz did).
      at +=
          Offset(
            math.sin(e.c * 2 * math.pi * 26),
            math.cos(e.c * 2 * math.pi * 29),
          ) *
          (.025 * e.hold);
    }
    if (e.blast > 0) {
      final (target, reach) = switch (lane) {
        BreathLane.high => (
          DragonLayout.headHighAngle,
          DragonLayout.headHigh - rest,
        ),
        BreathLane.middle => (
          DragonLayout.headMiddleAngle,
          DragonLayout.headMiddle - rest,
        ),
        BreathLane.low => (
          DragonLayout.headLowAngle,
          DragonLayout.headLow - rest,
        ),
      };
      at += reach * (e.blast * (1 + e.over));
      angle = angle + (target - angle) * e.blast;
      at += Offset(0, e.scan) * e.blast;
    }
    // The exhale lets the head sink as it comes home.
    at += Offset(0, .10) * e.exhale;
    // A hit snaps it back, the roar throws it up, the intake draws it in;
    // a coming fireball has the last word, so the jaws open at its anchor.
    final damp = e.damp;
    at += const Offset(.06, -.03) * (e.kick * damp);
    angle += -.12 * e.kick * damp;
    final throwing = (e.roar + e.roarKick) * damp;
    at += const Offset(-.05, -.10) * throwing;
    angle += -.56 * throwing;
    at += const Offset(.16, -.06) * (e.wind * damp);
    angle += -.20 * e.wind * damp;
    if (age >= _defeatAt) {
      // The pose it died in fades out; the killing blow flings the head
      // back, then it droops.
      final f = _fade(age);
      at = rest + (at - rest) * f;
      angle = angleRest + (angle - angleRest) * f;
      final d = age - _defeatAt;
      final throe = reduced
          ? 0.0
          : d < .02 || d > .5
          ? 0.0
          : d < .1
          ? _outCubic((d - .02) / .08)
          : 1 - _ease(_ramp(d, .1, .5));
      at += const Offset(.35, -.25) * throe;
      angle += -.5 * throe;
      final sl = _slumpOf(age);
      at += const Offset(.3, 1.2) * sl;
      angle += .45 * sl;
    }
    return (at: at, angle: angle);
  }

  double _gapeOf(double age) {
    final aa = math.min(age, _defeatAt);
    final e = _env(aa);
    final rear = e.inhale > 0
        ? .15 * _ease(_ramp(e.inhale, 0, .12)) + .2 * e.inhale
        : 0.0;
    // The ways the jaws open combine as independent odds (1 - prod(1 - x)):
    // smooth where one hands over to another, and exactly the single value
    // when only one is active.
    var closed = 1.0;
    for (final v in [
      e.roar,
      e.blast,
      e.charge * .55,
      _fights ? _shotGape(aa - _lastVolleyAt) : 0.0,
      math.max(0.0, rear - e.hold * .12),
      e.wind * .25,
    ]) {
      closed *= 1 - v.clamp(0.0, 1.0);
    }
    final open = 1 - closed;
    if (age < _defeatAt) return open.clamp(0.0, 1.0);
    final d = age - _defeatAt;
    // The jaw goes slack as the head drops (a ramp, not a pop).
    final slack =
        .25 *
        (reduced ? 1.0 : _ease(_ramp(d, 0, .2))) *
        (1 - BossMotion.ramp(d, .9, 1.1));
    return math.max(slack, open * _fade(age)).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------- the whole figure --

  double _pitchAt(double age) {
    final aa = math.min(age, _defeatAt);
    final e = _env(aa);
    final damp = e.damp;
    var alive = 0.0;
    if (!reduced) {
      alive += math.sin(aa * 1.1) * .012 * e.settle;
      alive += -.03 * e.thump + .01 * e.kick * damp;
    }
    alive += .06 * e.rearWeight;
    alive += switch (lane) {
      BreathLane.high => .03,
      BreathLane.middle => -.02,
      BreathLane.low => -.05,
    } * e.blast;
    alive += .04 * e.roar * damp;
    alive += .015 * _furyBlendAt(aa);
    if (age < _defeatAt) return alive;
    // Nose-down by 0.55 s after the killing blow.
    final d = age - _defeatAt;
    return alive * _fade(age) -
        .35 * (reduced ? 1 : _ease(_ramp(d, .05, .55)));
  }

  Offset _bobAt(double age) {
    if (reduced) return Offset.zero;
    final aa = math.min(age, _defeatAt);
    final e = _env(aa);
    final damp = e.damp;
    var b = Offset.zero;
    // Twice the old counter-motion (-.13 against -.07), riding .04 lower
    // than its middle so the highest the body gets is what it was (the
    // ceiling of the envelope is the head's crown at the top of the beat).
    b += Offset(0, .05 - .13 * _wave(_phaseAt(aa - .04))) * e.settle;
    // The dragon sinks as it gathers the breath, then the snap springs it
    // back.
    b += Offset(0, .12) * e.rearWeight;
    // The flame shakes the whole body: 17 Hz, +-.05 (2 px) with a slow swell.
    b += Offset(
          0,
          math.sin(aa * 2 * math.pi * 17) *
              .05 *
              (.65 + .35 * math.sin(aa * 2 * math.pi * .9)),
        ) *
        e.blast;
    b += Offset(.26, -.06) * e.thump;
    b += Offset(.05, -.015) * (e.kick * damp);
    b += Offset(0, -.06) * (e.roar * damp);
    // A roar shakes the chest (the arrival's roar shakes the whole screen
    // already, so it is left out of this one).
    if (aa >= _arrival) {
      b += Offset(0, math.sin(aa * 2 * math.pi * 20) * .016) * e.roar;
    }
    b = _clampLen(b, .3);
    if (age < _defeatAt) return b;
    // The dead weight sinks.
    final d = age - _defeatAt;
    return _clampLen(b * _fade(age) + Offset(0, .3 * _ease(_ramp(d, .1, .9))), .3);
  }
}
