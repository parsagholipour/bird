import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'king_coo_kit.dart';
import 'king_coo_layout.dart';

/// How King Coo feels in a story scene (the campaign's `StoryMood`, by name).
enum KingCooMood { plain, happy, surprised, angry, sad }

/// Everything King Coo's pose derives from the boss clock.
///
/// Every channel is a pure function of the [SkyBoss] (its age, its phase
/// timings, the crumb lobs the rules latched, the pop, the hits and the fury)
/// and its [BossMotion], so pausing, replaying and seeking reproduce a frame
/// exactly. No wall clock, no random, no history. MOTION channels (the
/// waddle, the wingbeat, bob, roll, head-bob, cap wobble, steam, tremble,
/// springs, overshoots) are 0 under Reduced Motion (`BossMotion.reducedMotion`)
/// and while he is held still; STATE channels (the puff, the whistle, the
/// wind-up and toss poses, the pop, the fury tone, the hit flash at .3, the
/// siren's colour) keep showing, so every state stays readable.
///
/// CONVENTIONS. Angles are radians, clockwise on screen. A wing's angle: 0
/// points at the tail, +pi/2 straight down, pi at the bird, -pi/2 up. `pitch`
/// and `roll` turn the whole figure about the chest (positive: nose UP);
/// `headTilt` turns the head about its centre (positive: beak UP). Offsets are
/// rig units (hit radius 1), +y down. Weights are 0..1.
///
/// THE COMBAT CYCLE (cycle seconds in the rules' fixed 14 s cycle; `lock` and
/// `launch` are the times each latched [CrumbLob] gives):
///
///   lock .. lock+.8   wind-up: dip into the sack (0-.3 of it), backswing with
///                     the bomb in hand (.3-.58), hold (.58-.825), swing
///                     (.825-1: the wing tip reaches [KingCooLayout.lobRelease]
///                     at exactly the launch); follow-through .3 s, arm home
///                     by .65 s
///   7.6               PUFF: the chest swells (front-loaded, taut by ~9), head
///                     rears, wings akimbo, siren blinks, the squadron cue
///                     rises
///   8.5 - 9.0         the whistle is raised into the beak
///   9.2               WHISTLE: blast (head thrust, wings up, cap hop, siren
///                     flash) for .4 s
///   10.0 - 10.4       the window closes; the chest settles, the whistle drops
///
/// CONTINUITY. No channel pops at a lock, a launch, a puff, a pop, a hit, the
/// fury, the arrival's end or the killing blow: a beat begins from zero, the
/// arm starts from the wing's own beat and returns to it, and the defeat
/// blends out of the pose he died in (the killing blow freezes it for the
/// hit-stop, then the inflating takes over). The only discrete channels are
/// [siren] (a colour), [capOff], [dizzy]'s X eyes above .5 and [bombHeld]
/// (the bomb changes hands at the launch); [capSpin] is continuous modulo
/// 2 pi.
final class KingCooPose {
  /// The pose of [boss] now. [lookY] turns his eye toward the bird (-1 up, 1
  /// down); [light] is the backdrop's light. Any non-finite time in the boss
  /// (a NaN age from a bad replay, a NaN `lastHitAt`, a lob with a NaN time)
  /// is replaced by a harmless value first, so no channel is ever NaN.
  ///
  /// [at] evaluates the same boss state at another boss age (the flying bomb
  /// starts from the hand at `lob.launchAt`, the falling cap from the pose at
  /// .3 s of the defeat): every channel is a pure function of the state and
  /// the age.
  factory KingCooPose(
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    KingCooSkyLight light = KingCooSkyLight.neutral,
    double? at,
  }) => KingCooPose._(
    boss,
    m.reducedMotion,
    m.defeated && m.death.isFinite
        ? (at == null ? m.death : at - boss.defeatedAt!)
        : 0,
    lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0,
    light.dark.isFinite ? light : KingCooSkyLight.neutral,
    null,
    at,
  );

  /// A static pose for a story scene: the campaign's [mood] (`beaten` drops
  /// the cap and looks sheepish), [talk] (0..1) opening the beak and [blink]
  /// (0..1) lowering the lids.
  factory KingCooPose.story(
    KingCooMood mood, {
    bool beaten = false,
    double talk = 0,
    double blink = 0,
    KingCooSkyLight light = KingCooSkyLight.neutral,
  }) => KingCooPose._(
    _restBoss(),
    true,
    0,
    0,
    light,
    _Story(mood, beaten, talk.clamp(0.0, 1.0), blink.clamp(0.0, 1.0)),
    null,
  );

  /// The rest pose: calm, wings half raised, chest fluffed, cap level.
  static final still = KingCooPose(
    _restBoss(),
    BossMotion(_restBoss(), reducedMotion: true),
  );

  /// The defeat [death] seconds in, as a pose of its own: the falling cap
  /// starts from where the rising cap really is. The pose he died in has
  /// settled into a canonical one by 0.3 s (when the cap leaves), so the cap
  /// (and the head it leaves) is exact for any real defeat from then on.
  static KingCooPose atDeath(double death, {bool reduced = false}) {
    final boss = _restBoss();
    boss.age = boss.arrivalDuration + 10;
    boss.defeatedAt = boss.age - death;
    return KingCooPose(boss, BossMotion(boss, reducedMotion: reduced));
  }

  static SkyBoss _restBoss() =>
      SkyBoss(number: 6, x: 0, kind: BossKind.kingCoo, cinematic: true)
        ..age = 4.6 + 1.2;

  KingCooPose._(
    SkyBoss boss,
    bool isReduced,
    double deathSeconds,
    double lookAt,
    this.light,
    _Story? story,
    double? at,
  ) : reduced = isReduced,
      death = deathSeconds {
    _solve(boss, lookAt, story, at);
  }

  // ------------------------------------------------------------ inputs --

  /// The backdrop's light (how dark the sky is and the colour it bounces).
  final KingCooSkyLight light;

  /// Whether the motion channels are held at zero, and, while he is being
  /// defeated, the seconds since the killing hit.
  final bool reduced;
  final double death;

  /// Where he is in his life.
  late final bool defeated, arriving, fighting;

  /// Boss age, the clock the MOTION channels run on (frozen at the killing
  /// hit; 0 under Reduced Motion), the combat second (negative in the
  /// arrival), and the place in the 14 s cycle (-1 outside the fight).
  late final double age, time, combat, cycle;
  late final int cycleNumber;

  // -------------------------------------------------------- the figure --

  /// The whole figure turns about the chest by `roll + pitch` (radians,
  /// positive: nose UP), is squashed by [deflate] (a popped chest sags wide
  /// and low), scaled by [swell] (the arrival's roar), and shifted by [bob]
  /// (rig units, at most .3 long). The rig applies exactly
  /// `translate(bob) rotate(roll+pitch) scale(scaleX, scaleY)`; [toRig] is
  /// the same map for anchors.
  late final double roll, pitch, deflate, swell;
  late final Offset bob;

  /// The figure's scale as painted: [swell] and the squash.
  double get scaleX => swell * (1 + .06 * deflate);
  double get scaleY => swell * (1 - .16 * deflate);

  /// [local] (in the figure's frame, origin the chest) as a rig point: the
  /// squash and swell, then the turn, then the bob. Every part is painted
  /// under this map, so anchors given through it land on the pixels.
  Offset toRig(Offset local) =>
      KingCooKit.turn(
        Offset(local.dx * scaleX, local.dy * scaleY),
        roll + pitch,
      ) +
      bob;

  // ------------------------------------------ the waddle-hover (motion) --

  /// The wingbeat's phase in radians (1.6 Hz, 2.1 Hz in fury, continuous
  /// through the onset; 2 beats per 1.25 s waddle). 0 when held still.
  late final double beatPhase;

  /// The near wing's beat waveform, -1..1 (`sin(x + .45 sin x)`: a quick
  /// downstroke, a slow upstroke), sampled [lag] seconds ago; the parts hang
  /// follow-through on it (legs .25, sack .15). 0 when held still.
  double beatAt(double lag) {
    if (time == 0) return 0;
    return _wave(_beatPhaseAt(time - lag, _furyAt));
  }

  late final double _furyAt;

  // ------------------------------------------------ wings, tail, legs --

  /// The wings' angles (see the conventions above), and [wingStretch] (1, or
  /// up to 1.25 in the toss's whip). [armThrow] is 1 while the near wing is
  /// the throwing arm (wind-up to follow-through, 0 at rest): the parts may
  /// tighten the feathers then.
  late final double wingNear, wingFar, wingStretch, armThrow;

  /// The tail's fan (0 closed .. 1 wide) and its wag (radians, motion), the
  /// legs' phase (radians; 0 under Reduced Motion) and the sack's sway about
  /// its strap (radians, motion).
  late final double tailFan, tailWag, pedal, sackSwing;

  /// 0..1 pulse over the .25 s of the fury's onset: both wings slam down
  /// like fists, the feet stamp, the body drops. The staging shakes on it.
  late final double stomp;

  /// Where the near wing's tip is (figure frame): where the bomb is held and
  /// where it leaves (at [KingCooLayout.lobRelease] at the release).
  Offset get handAt {
    final s = KingCooLayout.wingScale;
    final tip = Offset(
      KingCooLayout.wingTipLocal.dx * s * wingStretch,
      KingCooLayout.wingTipLocal.dy *
          s *
          (wingStretch > 1 ? 1 + (wingStretch - 1) * .3 : 1),
    );
    return KingCooLayout.nearShoulder + KingCooKit.turn(tip, wingNear);
  }

  // ---------------------------------------------------------- the chest --

  /// The chest: 0 fluffed (scalloped, radius .84, rocks do half) .. 1 puffed
  /// (smooth, exactly the hit circle, rocks count x2); up to 1.3 in the
  /// defeat's inflating, and 3% over at the whistle (motion). The window
  /// opens at 7.6 s; the swell is front-loaded (`1-(1-x)^2.2`) so the chest
  /// reads taut well before the whistle.
  late final double puff;

  /// The chest's outline radius for this [puff] (.84 .. 1.0, and beyond).
  double get chestRadius => KingCooLayout.chestRadiusAt(puff);

  // ------------------------------------------------------ head and face --

  /// The skull's offset from [KingCooLayout.headRest] and its turn (positive:
  /// beak UP). The head-bob is a quick thrust forward, a hold and a return
  /// once per waddle (motion).
  late final Offset head;
  late final double headTilt;

  /// The skull's centre in the figure frame, and [local] (in the head's
  /// frame) as a point of the figure frame (before [toRig]).
  Offset get headCentre => KingCooLayout.headRest + head;
  Offset headPoint(Offset local) =>
      headCentre + KingCooKit.turn(local, headTilt);

  /// [local] (in the head's frame, as the cap is authored: its band centre
  /// at [KingCooLayout.headCapSeat]) as a point of the figure frame: the cap
  /// hops by [capLift], tilts and spins about its seat, and rides the head's
  /// turn.
  Offset capPoint(Offset local) {
    const seat = KingCooLayout.headCapSeat;
    final turned = seat + KingCooKit.turn(local - seat, capTilt + capSpin);
    return headCentre + capLift + KingCooKit.turn(turned, headTilt);
  }

  /// The beak: 0 shut .. 1 wide (the COO!); the cheeks puffed (whistle, the
  /// throw's hold); the lids narrowed (0 open .. 1 a slit); the brow (0 the
  /// resting grump .. 1 furious); worry (brow raised and bent: the pop, the
  /// beaten); dizzy (0 .. 1, X eyes above .5); a blink (motion); and where he
  /// looks (x: -1 toward where he is throwing; y: -1 up .. 1 down).
  late final double beak, cheek, squint, anger, worry, dizzy, blink;
  late final double lookX, lookY;

  /// The cap: its tilt about the band (radians; idle -.05, hit -.3 and a
  /// spring, fury +.30), its lift (the hop at the whistle, the hit, the roar,
  /// the pop's flight), its spin (the pop's flight, radians) and whether it is
  /// OFF his head (the defeat: the staging tumbles it from
  /// `KingCooBossRig.capDrop`; the beaten story pose).
  late final double capTilt, capSpin;
  late final Offset capLift;
  late final bool capOff;

  /// The whistle: 0 hanging on its chain .. 1 in the beak; where it is (the
  /// figure frame); the blast: 1 at the whistle's blow (9.2 s) for .4 s.
  late final double whistle, blast;
  late final Offset whistleAt;

  /// The siren: 0 off (a dim lamp), 1 red, 2 blue (it strobes red/blue 3 Hz
  /// in the window and the arrival's silhouette; under Reduced Motion it is
  /// blue while he inhales and red from the whistle), its glow 0..1 and the
  /// squadron cue: 0..1, the envelope of the lanes the window raises (0 when
  /// he pops before the whistle).
  late final int siren;
  late final double sirenGlow, squadCue;

  /// The window in which his rocks count double (the rules' `puffWindow`), as
  /// a state: 0 outside it, easing to 1 over .15 s at its start, back to 0 over
  /// .15 s at its end or at a pop. The chest wears its "x2" and its gold only
  /// then. (Kept under Reduced Motion: it is the one state a player must read.)
  late final double doubleDamage;

  // ------------------------------------------------------- the throw --

  /// 0..1 through the wind-up, then 1 .. 0 as the arm goes home (0 when
  /// there is no throw); the bomb in his hand (0 or 1 from the dip's end
  /// until the release); the bomb's spin (radians, motion); the release's
  /// weight, 1 at the launch falling to 0 over the follow-through; and
  /// whether the active lob is a fury lob.
  late final double windup, bombHeld, bombSpin, follow;
  late final bool furyLob;

  // --------------------------------------------------- tone and effects --

  /// The hit's pale flash (peak .55; .3 under Reduced Motion) and its
  /// expression (the flinch's squint; stays under Reduced Motion).
  late final double flash, wince;

  /// Fury, 0..1 (eases in over .45 s from the half-health crossing; 1 at
  /// once under Reduced Motion), the heat of the puffed chest, and the steam
  /// that rises from his head in fury (motion).
  late final double fury, heat, steam;

  /// The tone every part paints in, from the channels above and the sky's
  /// light.
  late final KingCooTone tone;

  // ------------------------------------------------- arrival and defeat --

  /// The arrival's shadow (1 all shadow .. 0 in colour: the flash reveal at
  /// 1.9 s, .12 s to cross-fade, .25 s under Reduced Motion), the one orange
  /// eye the silhouette shows, the COO! (0..1..0 over .8 s from 2.65 s), the
  /// shock ring's progress (0..1 over .5 s) and the boss's own opacity (the
  /// defeat fades him by the burst).
  late final double silhouette, eyeGlint, roar, shock, opacity;

  // -------------------------------------------------------------- store --

  /// Every continuous numeric channel by name (tests and debugging).
  Map<String, double> get values => {
    'roll': roll,
    'pitch': pitch,
    'deflate': deflate,
    'swell': swell,
    'bob.x': bob.dx,
    'bob.y': bob.dy,
    'wingNear': wingNear,
    'wingFar': wingFar,
    'wingStretch': wingStretch,
    'armThrow': armThrow,
    'tailFan': tailFan,
    'tailWag': tailWag,
    'pedal': pedal,
    'sackSwing': sackSwing,
    'stomp': stomp,
    'puff': puff,
    'head.x': head.dx,
    'head.y': head.dy,
    'headTilt': headTilt,
    'beak': beak,
    'cheek': cheek,
    'squint': squint,
    'anger': anger,
    'worry': worry,
    'dizzy': dizzy,
    'blink': blink,
    'lookX': lookX,
    'lookY': lookY,
    'capTilt': capTilt,
    'capLift.x': capLift.dx,
    'capLift.y': capLift.dy,
    'whistle': whistle,
    'blast': blast,
    'whistleAt.x': whistleAt.dx,
    'whistleAt.y': whistleAt.dy,
    'sirenGlow': sirenGlow,
    'squadCue': squadCue,
    'doubleDamage': doubleDamage,
    'windup': windup,
    'bombSpin': bombSpin,
    'follow': follow,
    'flash': flash,
    'wince': wince,
    'fury': fury,
    'heat': heat,
    'steam': steam,
    'silhouette': silhouette,
    'eyeGlint': eyeGlint,
    'roar': roar,
    'shock': shock,
    'opacity': opacity,
  };

  // --------------------------------------------------------------- math --

  static double _ramp(double v, double a, double b) => BossMotion.ramp(v, a, b);
  static double _ease(double t) => BossMotion.ease(t);
  static double _pulse(double v, double span) => BossMotion.pulse(v, span);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _max(double a, double b) => a > b ? a : b;

  /// The wingbeat waveform: the downstroke is quick (37% of the beat), the
  /// upstroke slow.
  static double _wave(double phi) => math.sin(phi + .45 * math.sin(phi));

  /// The wingbeat phase at boss age [t], continuous through the fury's onset
  /// at [furyAt] (the rate goes 1.6 Hz -> 2.1 Hz there; +infinity: never,
  /// -infinity: always).
  static double _beatPhaseAt(double t, double furyAt) {
    const calm = 2 * math.pi * KingCooTimeline.beatHz;
    const hot = 2 * math.pi * KingCooTimeline.furyBeatHz;
    if (furyAt == double.infinity || t <= furyAt) return calm * t;
    if (furyAt == double.negativeInfinity) return hot * t;
    return calm * furyAt + hot * (t - furyAt);
  }

  /// The hit's flash: bites in 0.03 s, drains by 0.28 s.
  static double _hitFlash(double tau) => tau < 0 || tau > .28
      ? 0
      : tau < .03
      ? tau / .03
      : 1 - _ease(_ramp(tau, .03, .28));

  /// The chest's shape as the cycle puffs it: a front-loaded rise, a smooth
  /// release.
  static double _shapePuff(double raw, bool rising) => raw <= 0
      ? 0
      : rising
      ? 1 - math.pow(1 - raw, KingCooTimeline.puffFrontLoad).toDouble()
      : _ease(raw);

  /// How far the whistle is raised at cycle time [c]: up over 8.5..9.0, down
  /// over .3 s after the window closes.
  static double _raiseAt(double c) =>
      _ease(
        _ramp(
          c,
          KingCooTimeline.whistleRaiseFrom,
          KingCooTimeline.whistleRaiseTo,
        ),
      ) *
      (1 -
          _ease(
            _ramp(
              c,
              KingCoo.windowEnd,
              KingCoo.windowEnd + KingCooTimeline.whistleLowerSeconds,
            ),
          ));

  // ------------------------------------------------------------- solver --

  static bool _bad(double v) => v.isNaN || v == double.infinity;

  void _solve(SkyBoss boss, double lookAt, _Story? story, double? at) {
    // ---- inputs, made safe -------------------------------------------
    final rawAge = at ?? boss.age;
    final ageIn = rawAge.isFinite ? rawAge.clamp(-1e7, 1e7) : 0.0;
    final arrival = boss.arrivalDuration;
    double never(double v) => _bad(v) ? double.negativeInfinity : v;
    final isCoo = boss.isKingCoo;
    final dying = boss.defeatedAt != null;
    final deathAt = !dying
        ? double.infinity
        : (boss.defeatedAt!.isFinite ? boss.defeatedAt! : ageIn);
    // The age every BODY channel reads: frozen at the killing hit.
    final t = dying ? math.min(ageIn, deathAt) : ageIn;
    final motion = !reduced;

    defeated = dying;
    arriving = !dying && ageIn < arrival;
    fighting = isCoo && !dying && ageIn >= arrival;
    age = ageIn;
    time = motion ? t : 0;
    combat = t - arrival;
    final inFight = isCoo && combat >= 0;
    cycle = inFight ? KingCoo.cycleTime(combat) : -1;
    cycleNumber = inFight ? KingCoo.cycleNumber(combat) : -1;
    final c = inFight ? KingCoo.cycleTime(combat) : 0.0;

    // ---- fury ----------------------------------------------------------
    final enragedNow = isCoo && boss.enraged;
    final furyAtRaw = never(boss.enragedAt);
    _furyAt = !enragedNow
        ? double.infinity
        : (furyAtRaw.isFinite ? furyAtRaw : double.negativeInfinity);
    final furyBlend = !enragedNow
        ? 0.0
        : (!_furyAt.isFinite || !motion)
        ? 1.0
        : _ramp(t - _furyAt, 0, KingCooTimeline.furyBlendSeconds);
    final stompV = !enragedNow || !_furyAt.isFinite || !motion
        ? 0.0
        : _pulse(t - _furyAt, KingCooTimeline.stompSeconds);

    // ---- the hover (motion) --------------------------------------------
    final phase = motion ? _beatPhaseAt(t, _furyAt) : 0.0;
    final s = motion ? _wave(phase) : 0.0;
    final sFar = motion ? _wave(phase - .7) : 0.0;
    final amp = .75 * (1 + .35 * furyBlend);
    final turns = phase / (4 * math.pi);
    final step = motion
        ? _ease(_ramp(turns - turns.floorToDouble(), 0, .18)) -
              _ease(_ramp(turns - turns.floorToDouble(), .5, .68))
        : 0.0;
    final w = _W()
      ..roll = motion ? .05 * math.sin(phase / 2) : 0
      ..bobY = motion ? -.10 * (1 - math.cos(phase)) / 2 : 0
      ..headX = -.14 * step
      ..headY = .03 * step
      ..wingNear = motion
          ? KingCooLayout.restWingNear - .15 + amp * s
          : KingCooLayout.restWingNear
      ..wingFar = motion ? -.50 + amp * sFar : KingCooLayout.restWingFar
      ..capTilt = -.05 + (motion ? .03 * math.sin(phase * .45) : 0)
      ..tailFan = .42 + (motion ? .05 * math.sin(phase / 2) : 0);
    final tailWagV = motion ? .05 * math.sin(phase / 2 - .9) : 0.0;
    final sackSwingV = motion ? .05 * math.sin(phase / 2 + 1.0) : 0.0;

    // ---- the pop ---------------------------------------------------------
    final pAt = boss.poppedAt;
    final windowStart = inFight
        ? arrival + cycleNumber * KingCoo.period + KingCoo.puffAt
        : double.infinity;
    final popped =
        inFight &&
        pAt != null &&
        pAt.isFinite &&
        pAt >= windowStart &&
        pAt <= t + 1e-9;
    final popAge = popped ? t - pAt : -1.0;
    final cycleAtPop = popped ? KingCoo.cycleTime(pAt - arrival) : 0.0;
    final popSquash = popped
        ? _ease(_ramp(popAge, 0, KingCooTimeline.popSquash))
        : 0.0;
    // The squash holds while he is dizzy, then he recovers.
    final popHold = popped
        ? 1 -
              _ease(
                _ramp(
                  popAge,
                  KingCooTimeline.popDizzy,
                  KingCooTimeline.popDizzy + KingCooTimeline.popRecover,
                ),
              )
        : 0.0;

    // ---- layers -----------------------------------------------------------
    _throw(w, boss, t, inFight, motion);
    _window(w, c, t, inFight, popped, popAge, cycleAtPop, popSquash, motion);
    _pop(w, popped, popAge, popSquash, popHold, motion);
    _furyLayer(w, furyBlend, stompV, t, motion);
    final hitTau = t - never(boss.lastHitAt);
    final winceV = dying ? 0.0 : _pulse(hitTau, KingCooTimeline.hitSeconds);
    final winceExpr = dying ? 0.0 : _ease(_ramp(winceV, .2, .5));
    _hit(w, hitTau, winceV, winceExpr, dying, motion);
    _arrival(w, ageIn, arriving, motion);
    _defeat(w, dying, motion);
    if (story != null) _story(w, story);

    // ---- assemble ------------------------------------------------------
    final bobLen = math.sqrt(w.bobX * w.bobX + w.bobY * w.bobY);
    if (bobLen > .3) {
      w.bobX *= .3 / bobLen;
      w.bobY *= .3 / bobLen;
    }
    roll = w.roll;
    pitch = w.pitch;
    deflate = w.deflate.clamp(0.0, 1.0);
    swell = w.swell;
    bob = Offset(w.bobX, w.bobY);
    beatPhase = phase;
    wingNear = w.wingNear;
    wingFar = w.wingFar;
    wingStretch = w.stretch;
    armThrow = w.arm;
    tailFan = w.tailFan;
    tailWag = tailWagV;
    pedal = story != null ? 0 : phase;
    sackSwing = sackSwingV;
    stomp = stompV;
    puff = w.puff;
    head = Offset(w.headX, w.headY);
    headTilt = w.headTilt;
    beak = w.beak.clamp(0.0, 1.0);
    cheek = w.cheek.clamp(0.0, 1.0);
    squint = w.squint.clamp(0.0, 1.0);
    anger = w.anger.clamp(0.0, 1.0);
    worry = w.worry.clamp(0.0, 1.0);
    dizzy = w.dizzy.clamp(0.0, 1.0);
    blink = story != null
        ? story.blink
        : motion && !dying && !arriving
        ? _pulse(t % 4.3 - 3.1, .16)
        : 0.0;
    lookX = w.lookX;
    lookY = lookAt;
    capTilt = w.capTilt;
    capSpin = w.capSpin;
    capLift = Offset(w.capLiftX, w.capLiftY);
    capOff = w.capOff;
    whistle = w.whistle;
    blast = w.blast;
    final mouth = headPoint(KingCooLayout.headWhistle) + const Offset(-.02, .05);
    final swing = motion && popped && popAge >= 0 && popAge < 3
        ? Offset(math.sin(popAge * 11) * .22 * math.exp(-4 * popAge), 0)
        : Offset.zero;
    final buzz = motion && w.blast > 0
        ? Offset(math.sin(t * 90) * .012, 0)
        : Offset.zero;
    whistleAt =
        Offset.lerp(KingCooLayout.whistleRest, mouth, w.whistle)! + swing + buzz;
    siren = w.sirenGlow > .02 ? w.siren : 0;
    sirenGlow = w.sirenGlow.clamp(0.0, 1.0);
    squadCue = w.squadCue;
    doubleDamage = w.doubleDamage;
    windup = w.windup;
    bombHeld = w.bombHeld;
    bombSpin = w.bombSpin;
    follow = w.follow;
    furyLob = w.furyLob;
    flash = dying
        ? 0.0
        : reduced
        ? _pulse(hitTau, KingCooTimeline.hitSeconds) * .3
        : _hitFlash(hitTau) * .55;
    wince = winceExpr;
    fury = furyBlend;
    heat = dying
        ? 0.0
        : _max(math.min(w.puff, 1.0) * .6, _max(w.whistle * .8, w.blast))
              .clamp(0.0, 1.0);
    steam = motion
        ? _ramp(furyBlend, .4, 1) *
              (1 - w.deflate.clamp(0.0, 1.0)) *
              (dying ? 1 - _ease(_ramp(death, 0, .15)) : 1)
        : 0.0;
    silhouette = w.silhouette;
    eyeGlint = w.silhouette * _ramp(w.silhouette, .2, .5);
    roar = w.roar;
    shock = w.shock;
    opacity = w.opacity;
    tone = KingCooTone(
      flash: flash,
      fury: fury,
      heat: heat,
      dark: light.dark,
      siren: siren,
      sirenGlow: sirenGlow,
      sky: light.sky,
    );
  }

  // The crumb throw: the latched lob whose wind-up or follow-through is on.
  void _throw(_W w, SkyBoss boss, double t, bool inFight, bool motion) {
    if (!inFight) return;
    CrumbLob? lob;
    const tail = KingCooTimeline.followSeconds + KingCooTimeline.armReturnSeconds;
    for (final candidate in boss.lobs) {
      if (!candidate.lockedAt.isFinite ||
          !candidate.launchAt.isFinite ||
          !candidate.lockX.isFinite ||
          !candidate.lockY.isFinite) {
        continue;
      }
      if (candidate.lockedAt <= t && t < candidate.launchAt + tail) {
        lob = candidate;
      }
    }
    if (lob == null) return;
    final length = math.max(.05, lob.launchAt - lob.lockedAt);
    final u = _ramp(t - lob.lockedAt, 0, length);
    final after = t - lob.launchAt;
    final base = w.wingNear;
    w.furyLob = lob.fury;
    if (after < 0) {
      final dip = _ease(_ramp(u, 0, KingCooTimeline.dipEnd));
      final back = _ease(
        _ramp(u, KingCooTimeline.dipEnd, KingCooTimeline.backEnd),
      );
      final swing = math.pow(_ramp(u, KingCooTimeline.swingStart, 1), 1.6)
          .toDouble();
      final hold = back * (1 - swing);
      w.arm = _ramp(u, 0, .1);
      w.windup = u;
      w.follow = swing;
      if (u < KingCooTimeline.dipEnd) {
        w.wingNear = _lerp(base, KingCooLayout.windupDip, dip);
      } else if (u < KingCooTimeline.swingStart) {
        w.wingNear = _lerp(
          KingCooLayout.windupDip,
          KingCooLayout.windupBack,
          back,
        );
        // The held bomb trembles a little (motion).
        if (motion) {
          w.wingNear +=
              .03 * math.sin(t * 38) * _ease(_ramp(u, KingCooTimeline.backEnd, .65));
        }
      } else {
        w.wingNear = _lerp(
          KingCooLayout.windupBack,
          KingCooLayout.tossRelease,
          swing,
        );
      }
      w.bombHeld = u >= KingCooTimeline.dipEnd ? 1 : 0;
      w.bombSpin = motion ? u * 6 : 0;
      // The body leans forward into the sack, back with the swing, then into
      // the throw.
      w.pitch += _lerp(-.04 * dip * (1 - back) + .10 * back, -.07, swing);
      w.headX += .06 * hold - .10 * swing;
      w.headY += .02 * dip * (1 - back) + .06 * swing;
      w.beak = _max(w.beak, .10 * hold + .45 * swing);
      w.cheek = _max(w.cheek, .35 * hold);
      w.squint = _max(w.squint, .25 * hold);
      w.lookX = _lerp(w.lookX, -1, dip);
      w.tailFan = _lerp(w.tailFan, .9, _ease(u));
    } else {
      const fw = KingCooTimeline.followSeconds;
      const home = KingCooTimeline.armReturnSeconds;
      final reach = _ramp(after, 0, fw);
      final out = _ease(_ramp(after, fw, fw + home));
      final release = 1 - _ease(_ramp(after, 0, fw + home));
      w.follow = release;
      w.windup = 1 - out;
      w.arm = 1 - out;
      w.wingNear = _lerp(
        KingCooLayout.tossRelease +
            KingCooLayout.followOvershoot * math.sin(math.pi * reach),
        base,
        out,
      );
      w.stretch =
          1 + (KingCooLayout.followStretch - 1) * math.sin(math.pi * reach);
      w.pitch += -.07 * release;
      w.headX += -.10 * release;
      w.headY += .06 * release;
      w.beak = _max(w.beak, .45 * release);
      w.lookX = _lerp(w.lookX, -1, release);
      w.tailFan = _lerp(w.tailFan, .9, release);
      if (motion) w.bobX += .05 * _pulse(after, fw);
    }
  }

  // The puff window: the chest swells, the head rears, the whistle goes up
  // and is blown, the siren blinks, the squadron cue rises; a pop cuts it.
  void _window(
    _W w,
    double c,
    double t,
    bool inFight,
    bool popped,
    double popAge,
    double cycleAtPop,
    double popSquash,
    bool motion,
  ) {
    if (!inFight) return;
    var shaped = _shapePuff(KingCoo.puffAmount(c), c < KingCoo.whistleAt);
    var raise = _raiseAt(c);
    var blast = _pulse(c - KingCoo.whistleAt, KingCooTimeline.blastSeconds);
    var cue =
        _ease(
          _ramp(c, KingCoo.puffAt, KingCoo.puffAt + KingCooTimeline.squadCueIn),
        ) *
        (1 -
            _ease(
              _ramp(
                c,
                KingCoo.windowEnd,
                KingCoo.windowEnd + KingCooTimeline.squadCueOut,
              ),
            ));
    if (popped) {
      final blown = cycleAtPop >= KingCoo.whistleAt;
      shaped =
          _shapePuff(KingCoo.puffAmount(cycleAtPop), cycleAtPop < KingCoo.whistleAt) *
          (1 - popSquash);
      final out = _ease(_ramp(popAge, 0, .2));
      raise = _raiseAt(cycleAtPop) * (1 - out);
      blast = blown
          ? _pulse(cycleAtPop - KingCoo.whistleAt, KingCooTimeline.blastSeconds) *
                (1 - out)
          : 0.0;
      // Popped before the whistle: the squadron is cancelled, the lanes go
      // out with the pop.
      if (!blown) cue *= 1 - _ease(_ramp(popAge, 0, .25));
    }
    w.puff = _max(w.puff, shaped);
    w.squadCue = cue;
    // The double-damage window: from the puff (7.6) to the window's end
    // (10.0) or the pop, with a .15 s ease each side.
    w.doubleDamage =
        _ease(_ramp(c, KingCoo.puffAt, KingCoo.puffAt + .15)) *
        (1 - _ease(_ramp(c, KingCoo.windowEnd - .15, KingCoo.windowEnd))) *
        (popped ? 1 - _ease(_ramp(popAge, 0, .15)) : 1);
    // The chest overshoots 3% as the swell lands (motion).
    if (motion && !popped) {
      w.puff +=
          .03 *
          math.sin(math.pi * _ramp(c, KingCoo.whistleAt, KingCoo.whistleAt + .4));
    }
    final inWindow = c >= KingCoo.puffAt && c < KingCoo.windowEnd + .4;
    if (inWindow) {
      // The siren goes out with the pop (a .25 s fade), not with a click.
      final glow =
          _ease(_ramp(c, KingCoo.puffAt, KingCoo.puffAt + .3)) *
          (1 - _ease(_ramp(c, KingCoo.windowEnd, KingCoo.windowEnd + .4))) *
          (popped ? 1 - _ease(_ramp(popAge, 0, .25)) : 1);
      if (glow > w.sirenGlow) {
        w.sirenGlow = glow;
        w.siren = motion
            ? ((t * KingCooTimeline.sirenHz).floor().isEven ? 2 : 1)
            : (c >= KingCoo.whistleAt ? 1 : 2);
      }
    }
    // The inhale: the head rears and tucks, the wings go akimbo, the tail
    // fans, the cheeks puff.
    final k = shaped;
    if (k > 0) {
      w.headX = _lerp(w.headX, .30, k);
      w.headY = _lerp(w.headY, .14, k);
      w.headTilt += -.22 * k; // beak-down, but the visor must not catch up (K8)
      w.capLiftY += -.06 * k;
      w.cheek = _max(w.cheek, .5 * k);
      w.tailFan = _lerp(w.tailFan, 1.0, k);
      w.pitch += .05 * k;
      w.beak = _max(w.beak, .08 * k);
      if (w.arm < 1) {
        w.wingNear = _lerp(w.wingNear, -.05 - .55 * k, k);
        w.wingFar = _lerp(w.wingFar, -.30 - .5 * k, k);
      }
    }
    // The whistle: into the beak, head forward, wings up; the blow.
    if (raise > 0) {
      w.headX = _lerp(w.headX, -.08, raise);
      w.headY = _lerp(w.headY, -.03, raise);
      w.headTilt = _lerp(w.headTilt, .05, raise);
      w.beak = _lerp(w.beak, .14, raise);
      w.cheek = _lerp(w.cheek, 1.0, raise);
      w.pitch = _lerp(w.pitch, -.04, raise);
      w.capLiftY = _lerp(w.capLiftY, -.05, raise);
      if (w.arm < 1) {
        w.wingNear = _lerp(w.wingNear, -.80, raise);
        w.wingFar = _lerp(w.wingFar, -1.05, raise);
      }
    }
    if (blast > 0) {
      w.capLiftY += -.09 * blast;
      w.capTilt += -.10 * blast;
      w.headX += -.06 * blast;
      if (w.arm < 1) {
        w.wingNear = _lerp(w.wingNear, -1.0, blast * .5);
        w.wingFar = _lerp(w.wingFar, -1.15, blast * .5);
      }
    }
    w.whistle = raise;
    w.blast = blast;
  }

  // The pop: a squash, X eyes, limp wings, the cap launched (it hops, spins
  // and lands back crooked .9 s later), the whistle knocked out.
  void _pop(
    _W w,
    bool popped,
    double popAge,
    double squash,
    double hold,
    bool motion,
  ) {
    if (!popped) return;
    final k = squash * hold;
    w.deflate += .7 * k;
    w.dizzy = _max(
      w.dizzy,
      _ease(_ramp(popAge, 0, .08)) *
          (popAge < KingCooTimeline.popDizzy ? 1.0 : hold),
    );
    w.headX = _lerp(w.headX, .14, k);
    w.headY = _lerp(w.headY, .22, k);
    w.headTilt = _lerp(w.headTilt, .25, k);
    w.beak = _lerp(w.beak, .5, k);
    w.wingNear = _lerp(w.wingNear, .9, k);
    w.wingFar = _lerp(w.wingFar, .6, k);
    w.tailFan = _lerp(w.tailFan, .25, k);
    w.roll = _lerp(w.roll, .10, k);
    w.worry = _max(w.worry, .6 * k);
    // The cap is launched, tumbles once and lands back crooked.
    final flight = _ramp(popAge, 0, KingCooTimeline.popCapFlight);
    if (motion) {
      w.capLiftY += -KingCooTimeline.popCapHop * 4 * flight * (1 - flight);
      w.capLiftX += .8 * math.sin(math.pi * flight);
      w.capSpin = 2 * math.pi * _ease(flight) * (popAge < 3.2 ? 1 : 0);
    }
    w.capTilt +=
        .35 *
        _ease(_ramp(popAge, .2, KingCooTimeline.popCapFlight)) *
        hold;
  }

  // The fury: a scowl, the cap cocked forward, the tail fanned, the chest
  // part-swollen, the siren steady red; the stomp at the onset.
  void _furyLayer(_W w, double f, double stomp, double t, bool motion) {
    if (f > 0) {
      w.squint = _max(w.squint, .30 * f);
      w.anger = _max(w.anger, f);
      w.capTilt = _lerp(w.capTilt, .30, f);
      w.tailFan = _lerp(w.tailFan, 1.0, f);
      w.headX += -.05 * f;
      w.headY += .05 * f;
      w.pitch += .03 * f;
      w.beak = _max(w.beak, .12 * f);
      w.puff = _max(w.puff, .30 * f);
      final glow = f * (.55 + (motion ? .25 * math.sin(t * 7) : 0));
      if (glow > w.sirenGlow) {
        w.sirenGlow = glow;
        if (w.siren == 0) w.siren = 1;
      }
    }
    if (stomp > 0) {
      // Both wings slam down like fists and the body drops.
      w.wingNear = _lerp(w.wingNear, 1.15, stomp);
      w.wingFar = _lerp(w.wingFar, .95, stomp);
      w.bobY += .14 * stomp;
    }
  }

  // The hit: the head snaps back, the cap flies up and cocks, the wings pump,
  // the eyes squeeze (the expression stays under Reduced Motion).
  void _hit(
    _W w,
    double hitTau,
    double wince,
    double expr,
    bool dying,
    bool motion,
  ) {
    if (wince > 0 || expr > 0) {
      w.squint = _max(w.squint, expr);
      w.worry = _max(w.worry, .3 * expr);
      w.capTilt += -.3 * wince;
      if (motion) {
        w.headX += .22 * wince;
        w.headY += .06 * wince;
        w.headTilt += -.2 * wince;
        w.capLiftX += .05 * wince;
        w.capLiftY += -.12 * wince;
        w.pitch += .05 * wince;
        w.bobX += .04 * wince;
        w.bobY += .03 * wince;
        w.beak = _max(w.beak, .35 * wince);
        if (w.arm < 1) {
          w.wingNear = _lerp(w.wingNear, -.95, wince * .7);
          w.wingFar = _lerp(w.wingFar, -1.1, wince * .7);
        }
      }
    }
    // The cap spins on his head a moment after the blow: a damped spring on
    // its tilt (motion).
    if (motion && !dying && hitTau >= 0 && hitTau < 1) {
      w.capTilt +=
          .30 * math.exp(-8 * hitTau) * math.sin(2 * math.pi * hitTau / .22);
    }
  }

  // The arrival: a shadow with one orange eye and a strobing siren; the flash
  // reveal; he rears and puffs; the COO!
  void _arrival(_W w, double a, bool arriving, bool motion) {
    if (!arriving) return;
    final reveal = a - KingCooTimeline.flashAt - (reduced ? .1 : 0);
    w.silhouette = 1 - _ease(_ramp(reveal, 0, reduced ? .25 : .12));
    final rear = _ease(_ramp(a, KingCooTimeline.rearAt, KingCooTimeline.cooAt));
    final roar = _pulse(a - KingCooTimeline.cooAt, .8);
    w.roar = roar;
    w.shock = _ramp(a - KingCooTimeline.cooAt, 0, .5);
    // The chest swells as he rears (2.35..2.65), stays through the COO! and
    // settles by 4.0.
    final k = rear * (1 - _ease(_ramp(a, 3.3, 4.0)));
    w.puff = _max(w.puff, k);
    w.headX = _lerp(w.headX, .30, k);
    w.headY = _lerp(w.headY, .14, k);
    w.headTilt += -.22 * k * (1 - roar);
    w.cheek = _max(w.cheek, .5 * k);
    w.tailFan = _lerp(w.tailFan, 1.0, k);
    w.pitch += .05 * k + .07 * roar;
    // The COO!: beak wide, head thrown up, wings thrown up, the cap hops.
    w.beak = _max(w.beak, roar);
    w.capLiftY += -.18 * roar;
    w.capTilt += -.15 * roar;
    w.headX += .18 * roar;
    w.headTilt += .25 * roar;
    final up = _max(k * .6, roar);
    w.wingNear = _lerp(w.wingNear, -.9, up);
    w.wingFar = _lerp(w.wingFar, -1.1, up);
    if (motion) {
      w.swell =
          1 +
          (KingCooLayout.arrivalSwell - 1) *
              math.sin(
                math.pi *
                    _ramp(a, KingCooTimeline.swellFrom, KingCooTimeline.swellTo),
              );
    }
    // The siren strobes in the shadow and blinks through the COO!.
    final glow = _max(
      1 - _ease(_ramp(a, KingCooTimeline.flashAt, KingCooTimeline.flashAt + .25)),
      _ease(_ramp(a, 2.3, 2.5)) * (1 - _ease(_ramp(a, 3.2, 3.6))),
    );
    if (glow > w.sirenGlow) {
      w.sirenGlow = glow;
      w.siren = motion ? ((a * 4).floor().isEven ? 1 : 2) : 1;
    }
  }

  // The defeat: frozen for the hit-stop, then the pose he died in settles into
  // a canonical one by .3 s (head, cap, tilt and hover all the same whatever
  // he was doing, so the cap's fall starts from a known place), he inflates
  // (the cap rises off and leaves at .3 s, the eyes go to X), and at the burst
  // he POPS (squash, limp wings); the staging fades him by 1.07 s.
  void _defeat(_W w, bool dying, bool motion) {
    if (!dying) return;
    final d = death;
    final inflate = reduced
        ? _ease(_ramp(d, KingCooTimeline.hitStop, .30))
        : _ease(_ramp(d, KingCooTimeline.hitStop, KingCooTimeline.inflateEnd));
    final pop = _ease(
      _ramp(d, KingCooTimeline.inflateEnd, KingCooTimeline.popAt + .05),
    );
    final settle = _ease(
      _ramp(d, KingCooTimeline.hitStop, KingCooTimeline.capOffAt),
    );
    w.puff = _lerp(_lerp(w.puff, 1.30, inflate), .30, pop);
    // The hover, the flinch and the pop's squash fade out by .3 s.
    w.deflate = _lerp(_lerp(w.deflate, 0, settle), 1.0, pop);
    w.headX = _lerp(w.headX, _lerp(0, .16, inflate), settle);
    w.headY = _lerp(w.headY, _lerp(0, .10, inflate), settle);
    w.headTilt = _lerp(w.headTilt, _lerp(0, .22, inflate), settle);
    w.pitch = _lerp(w.pitch, _lerp(0, .10, inflate), settle);
    w.roll = _lerp(_lerp(w.roll, 0, settle), .12, pop);
    w.bobX = _lerp(w.bobX, 0, settle);
    w.bobY = _lerp(w.bobY, 0, settle);
    w.capLiftX = _lerp(w.capLiftX, 0, settle);
    w.capSpin = _lerp(w.capSpin, 0, settle);
    w.swell = _lerp(w.swell, 1, settle);
    w.dizzy = _max(
      w.dizzy,
      _ease(_ramp(d, KingCooTimeline.hitStop, KingCooTimeline.hitStop + .08)),
    );
    w.cheek = _max(w.cheek, inflate);
    w.worry = _max(w.worry, .5 * inflate);
    w.beak = _lerp(w.beak, .5, inflate);
    w.wingNear = _lerp(_lerp(w.wingNear, -1.25, inflate), .9, pop);
    w.wingFar = _lerp(_lerp(w.wingFar, -1.45, inflate), .6, pop);
    w.stretch = _lerp(w.stretch, 1, inflate);
    w.tailFan = _lerp(w.tailFan, 1.0, inflate);
    w.arm = _lerp(w.arm, 0, inflate);
    w.bombHeld = 0;
    // The cap rises off his head with the blow, and is OFF from .3 s: the
    // staging tumbles it from there.
    w.capLiftY = _lerp(w.capLiftY, -.6, settle);
    w.capTilt = _lerp(w.capTilt, .5, settle);
    w.capOff = d >= KingCooTimeline.capOffAt;
    if (motion) {
      w.bobX += math.sin(d * 61) * .02 * inflate * (1 - pop);
      w.bobY += math.cos(d * 47) * .02 * inflate * (1 - pop);
    }
    // The whistle, the siren and the lanes go out with the cap.
    final out = 1 - _ease(_ramp(d, KingCooTimeline.hitStop, .4));
    w.whistle *= out;
    w.blast *= out;
    w.sirenGlow *= out;
    w.squadCue *= out;
    w.doubleDamage = 0;
    w.opacity = 1 - _ramp(d, .78, 1.07);
  }

  // A story scene: a still pose for the campaign's mood.
  void _story(_W w, _Story s) {
    w.windup = 0;
    w.arm = 0;
    w.follow = 0;
    w.bombHeld = 0;
    w.blast = 0;
    w.whistle = 0;
    w.squadCue = 0;
    w.sirenGlow = 0;
    w.siren = 0;
    w.puff = 0;
    w.squint = 0;
    w.worry = 0;
    w.anger = 0;
    w.cheek = 0;
    w.beak = 0;
    w.headTilt = 0;
    w.headX = 0;
    w.headY = 0;
    w.pitch = 0;
    w.capLiftY = 0;
    w.capLiftX = 0;
    w.capTilt = -.05;
    w.tailFan = .42;
    w.stretch = 1;
    switch (s.mood) {
      case KingCooMood.plain:
        // A wing on the hip.
        w.wingNear = .45;
        w.wingFar = KingCooLayout.restWingFar;
      case KingCooMood.happy:
        // A grin and a wing out for a bagel.
        w.wingNear = 2.55;
        w.wingFar = -.3;
        w.puff = .15;
        w.beak = .22;
        w.squint = .45;
        w.cheek = .35;
        w.headTilt = .05;
        w.capTilt = -.12;
        w.tailFan = .75;
      case KingCooMood.surprised:
        w.wingNear = -.95;
        w.wingFar = -1.1;
        w.beak = .32;
        w.worry = .15;
        w.capLiftY = -.30;
        w.headY = -.04;
        w.headTilt = .12;
        w.tailFan = .9;
        w.pitch = .03;
      case KingCooMood.angry:
        // Puffed and furious, the siren red.
        w.wingNear = -.4;
        w.wingFar = -.85;
        w.puff = 1;
        w.beak = .16;
        w.squint = .4;
        w.anger = 1;
        w.cheek = .3;
        w.capTilt = .30;
        w.headX = -.05;
        w.headY = .05;
        w.tailFan = 1.0;
        w.siren = 1;
        w.sirenGlow = 1;
      case KingCooMood.sad:
        w.wingNear = .75;
        w.wingFar = .5;
        w.worry = 1;
        w.headX = .10;
        w.headY = .15;
        w.headTilt = -.2;
        w.capTilt = -.3;
        w.tailFan = .25;
        w.pitch = -.03;
    }
    if (s.beaten) {
      // No cap, a pretzel, sheepish.
      w.capOff = true;
      w.worry = _max(w.worry, .6);
      w.squint = _max(w.squint, .25);
      w.headX = _max(w.headX, .10);
      w.headY = _max(w.headY, .12);
      w.headTilt = -.15;
      w.tailFan = .3;
      // (K8: a beaten king holds his pretzel out in front of his belly, and one who is offered a bagel still reaches for it.)
      w.wingNear = s.mood == KingCooMood.happy ? w.wingNear : 2.0;
      w.wingFar = .4;
      w.siren = 0;
      w.sirenGlow = 0;
      w.anger = 0;
      w.puff = 0;
    }
    w.beak = _max(w.beak, s.talk * .45);
  }
}

/// The working set the solver's layers blend over: one field per channel.
class _W {
  double roll = 0, pitch = 0, deflate = 0, swell = 1, bobX = 0, bobY = 0;
  double headX = 0, headY = 0, headTilt = 0;
  double wingNear = 0, wingFar = 0, stretch = 1, arm = 0, tailFan = .6;
  double capTilt = -.05, capLiftX = 0, capLiftY = 0, capSpin = 0;
  bool capOff = false;
  double puff = 0, beak = 0, cheek = 0, squint = 0, anger = 0, worry = 0;
  double dizzy = 0, lookX = 0;
  double whistle = 0, blast = 0, squadCue = 0, doubleDamage = 0;
  int siren = 0;
  double sirenGlow = 0;
  double windup = 0, bombHeld = 0, bombSpin = 0, follow = 0;
  bool furyLob = false;
  double silhouette = 0, roar = 0, shock = 0, opacity = 1;
}

class _Story {
  const _Story(this.mood, this.beaten, this.talk, this.blink);
  final KingCooMood mood;
  final bool beaten;
  final double talk, blink;
}
