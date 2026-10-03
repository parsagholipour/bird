import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';

/// A story scene's mood for the hand-set pose ([GargoylePose.story]).
enum GargoyleMood { plain, happy, surprised, angry, sad, beaten }

/// One wing fan's motion this frame (see [GargoyleLayout.fanTip]): every blade
/// has its own stroke, so the fan ripples when he shrugs (blade i follows blade
/// 0 by [GargoyleTimeline.bladeLag] x i seconds, the far fan a tenth of a
/// second behind and a little higher).
final class GargoyleFanMotion {
  const GargoyleFanMotion({required this.strokes, required this.spread, this.shed = 0});

  /// Per-blade strokes, -1 shrugged up .. 0 rest .. +1 mantled down the back.
  final List<double> strokes;

  /// The fan's opening, 0 rest .. 1 fully open (arrival roar, vent, fury).
  final double spread;

  /// How much of the blade [GargoyleLayout.shedBlade] is gone (1 just left,
  /// regrowing to 0): the near fan only.
  final double shed;

  /// The tip of blade [i] for the near or [far] fan.
  Offset tip(int i, {required bool far}) =>
      GargoyleLayout.fanTip(i, far: far, stroke: strokes[i], spread: spread);
}

/// One burning beam as the art draws it: the rules' lit band at the bird's
/// column (screen heights, the same at every width) and which lens fires it.
final class GargoyleBeam {
  const GargoyleBeam({
    required this.centre,
    required this.half,
    required this.far,
    required this.fury,
    required this.intensity,
  });

  /// The band's centre and half-height at the bird's column, in screen
  /// heights: exactly `SkyBoss.beamCentres` and `beamHalf`. The bird is hurt when
  /// its circle touches this band.
  final double centre, half;

  /// Fired from the far (higher) lens: the slit's upper beam. Zone beams and the
  /// slit's lower beam come from the near lens.
  final bool far;

  /// The furious look (arc-white core, orange edge).
  final bool fury;

  /// 0..1: the ignition ramp, the fade after the vent, the defeat's stutter.
  /// The two edge lines are at FULL strength whenever it is above 0 (the beam
  /// hurts from its first frame), only the haze, body and core scale with it.
  final double intensity;
}

/// Everything the Searchlight Gargoyle's pose derives from the boss clock.
///
/// Every channel is a pure function of the [SkyBoss] (its age and latches) and
/// its [BossMotion], so pausing, replaying and seeking reproduce a frame
/// exactly. **Motion** channels (sway, blink, the shrug, steam, dust, the
/// rattle) settle to one still frame under Reduced Motion (`time == 0` and
/// [reduced]); **state** channels (lamp, flare, brow, fury, flash, cracks, the
/// beam and its warning, the phase postures, the stone) keep showing, so every
/// state stays readable.
///
/// THE CYCLE (combat seconds x = t mod 9; the rules own 2.0 / 3.5 / 6.4 / 8.7):
///
///   0.0  perch     shuttered, sway, blink; a stone feather at .2 and 4.6
///                  (fury 4.5 and 5.2): wind-up .25 s (lean -.8, head up),
///                  flick .15 s (fan -1, a blade leaves at the launch), settle
///                  .3 s
///   2.0  WARNING   (1.5 s) brow drops, he rears back (lean -.45, head up),
///                  fan flares, eyes climb from .3 to 1; at 3.05 he LOCKS ON:
///                  leans in and swings the head to where the beam starts
///   3.5  SWEEP     eyes at 1, lean +.7, the head follows the beam's own angle
///                  (pitch = .40 x the angle, -.35..+.5) through its 1.8 s glide
///                  and hold
///   6.4  VENT      the beam dies, the lamp opens over .3 s, lean -.6, head
///                  back, beak open, steam 1.2 s, fan thrown up
///   8.7  the lamp closes; he settles; 8.8 the next feather's wind-up
///
/// CONTINUITY. No channel pops at a phase edge, a hit, the enrage, the
/// arrival's end or the killing blow: every beat starts from the value the
/// previous one left, and the defeat blends out of the pose he died in (the
/// killing blow freezes it for the hit-stop, the throes take over by .32 s).
final class GargoylePose {
  /// The pose of [boss] now. Any non-finite time in the boss or the sky's light
  /// is replaced by a harmless value first, so no channel is ever NaN; a boss
  /// with only finite times is used as it is. [lookY] (-1 up .. 1 down) turns
  /// the head a hair toward the bird while he perches, [gap] is the distance
  /// from his lenses to the bird's column in screen heights (the pitch that
  /// follows the beam needs it: .51 at 640 wide, about .96 at 800; the rig's
  /// default is the narrow case).
  factory GargoylePose(
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    GargoyleSkyLight light = GargoyleSkyLight.neutral,
    double gap = defaultGap,
  }) {
    final safe = _sane(boss, m);
    return GargoylePose._build(
      safe.$1,
      safe.$2,
      lookY: lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0,
      light: light.dark.isFinite ? light : GargoyleSkyLight.neutral,
      gap: gap.isFinite ? gap.clamp(.3, 2.0) : defaultGap,
    );
  }

  /// A hand-set pose for a story scene: the mood's look, the beak opened by
  /// [talk] (0..1) and the lenses irised by [blink] (0..1). Still, Reduced
  /// Motion identical.
  factory GargoylePose.story(
    GargoyleMood mood, {
    double talk = 0,
    double blink = 0,
    GargoyleSkyLight light = GargoyleSkyLight.neutral,
  }) {
    final ch = _Ch();
    switch (mood) {
      case GargoyleMood.plain:
        break;
      case GargoyleMood.happy:
        ch
          ..flare = .75
          ..brow = .05
          ..pitch = -.22
          ..headY = -.08
          ..wing = -.35
          ..spread = .25
          ..lean = -.2;
      case GargoyleMood.surprised:
        ch
          ..flare = 1
          ..brow = 0
          ..pitch = -.30
          ..lean = -.5
          ..wing = -.7
          ..spread = .5
          ..gape = .3;
      case GargoyleMood.angry:
        ch
          ..flare = 1
          ..brow = 1
          ..fury = 1
          ..furyBlend = 1
          ..crack = .6
          ..pitch = .12
          ..lean = .6
          ..wing = -.4
          ..spread = .6;
      case GargoyleMood.sad:
        ch
          ..flare = .12
          ..brow = .75
          ..pitch = .32
          ..headY = .18
          ..wing = .8
          ..lean = .2
          ..visor = 1
          ..iris = .75;
      case GargoyleMood.beaten:
        ch
          ..flare = .05
          ..brow = .2
          ..pitch = .5
          ..headY = .5
          ..headX = .2
          ..wing = 1
          ..lean = .4
          ..crack = 1
          ..damage = 1
          ..lamp = .2
          ..shatter = 1
          ..visor = 0
          ..iris = .3;
    }
    ch.gape = math.max(ch.gape, talk.clamp(0.0, 1.0) * .55);
    ch.iris = ch.iris * (1 - blink.clamp(0.0, 1.0));
    return GargoylePose._fromCh(
      ch,
      age: 0,
      time: 0,
      reduced: true,
      defeated: mood == GargoyleMood.beaten,
      arriving: false,
      death: 0,
      light: light,
      warnSide: null,
      slit: false,
      beams: const [],
      nearFan: _fan(ch, far: false),
      farFan: _fan(ch, far: true),
    );
  }

  /// A pose with every channel set by hand (studies, sheets, tests): all
  /// default to the calm idle. Not a function of any boss clock.
  factory GargoylePose.custom({
    double stone = 0,
    double lamp = 0,
    double shatter = 0,
    double flare = .3,
    double brow = .3,
    double iris = 1,
    double gape = 0,
    double roar = 0,
    double fury = 0,
    double flash = 0,
    double hit = 0,
    double crack = 0,
    double damage = 0,
    double crumble = 0,
    double glance = 0,
    double lean = 0,
    double pitch = 0,
    Offset head = Offset.zero,
    double wing = 0,
    double spread = 0,
    double tail = 0,
    double steam = 0,
    double grip = 0,
    double visor = 1,
    GargoyleSkyLight light = GargoyleSkyLight.neutral,
  }) {
    final ch = _Ch()
      ..stone = stone
      ..lamp = lamp
      ..shatter = shatter
      ..flare = flare
      ..brow = brow
      ..iris = iris
      ..gape = gape
      ..roar = roar
      ..fury = fury
      ..furyBlend = fury
      ..flash = flash
      ..hit = hit
      ..wince = hit
      ..crack = crack
      ..damage = damage
      ..crumble = crumble
      ..glance = glance
      ..lean = lean
      ..pitch = pitch
      ..headX = head.dx
      ..headY = head.dy
      ..wing = wing
      ..spread = spread
      ..tail = tail
      ..steam = steam
      ..grip = grip
      ..visor = visor
      ..chest = 0;
    return GargoylePose._fromCh(
      ch,
      age: 0,
      time: 0,
      reduced: true,
      defeated: false,
      arriving: false,
      death: 0,
      light: light,
      warnSide: null,
      slit: false,
      beams: const [],
      nearFan: _fan(ch, far: false),
      farFan: _fan(ch, far: true),
    );
  }

  /// The distance from his lenses to the bird's column at 640x360 (screen
  /// heights): the narrow case the pitch that follows the beam is tuned on.
  static const defaultGap = .51;

  /// The rest pose: perching, shuttered, nothing happening (and the Reduced
  /// Motion idle).
  static final still = () {
    final boss = SkyBoss(number: 6, x: 0, kind: BossKind.searchlightGargoyle, cinematic: true);
    boss.age = boss.arrivalDuration + 1.0;
    return GargoylePose(boss, BossMotion(boss, reducedMotion: true));
  }();

  /// The defeat [death] seconds in, as a pose of its own: the knocked-off visor
  /// starts from where the slumped head really is. The pose he died in has
  /// faded out of it by .32 s (the visor leaves at .3), so this is exact for any
  /// real defeat from then on.
  static GargoylePose atDeath(double death, {bool reduced = false}) {
    final boss = SkyBoss(number: 6, x: 0, kind: BossKind.searchlightGargoyle, cinematic: true);
    boss.age = boss.arrivalDuration + 10;
    boss.defeatedAt = boss.age - death;
    return GargoylePose(boss, BossMotion(boss, reducedMotion: reduced));
  }

  static (SkyBoss, BossMotion) _sane(SkyBoss b, BossMotion m) {
    // -infinity is legitimate ("never happened"); NaN and +infinity are not.
    bool bad(double v) => v.isNaN || v == double.infinity;
    final clean = b.age.isFinite &&
        !bad(b.lastHitAt) &&
        !bad(b.previousHitAt) &&
        !bad(b.enragedAt) &&
        !bad(b.lastGlanceAt) &&
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
      ..lastHitAt = never(b.lastHitAt)
      ..previousHitAt = never(b.previousHitAt)
      ..enragedAt = never(b.enragedAt)
      ..lastGlanceAt = never(b.lastGlanceAt)
      ..beamSide = b.beamSide
      ..slitSweep = b.slitSweep
      ..sweepsAimed = b.sweepsAimed
      ..spots = b.spots;
    if (b.defeatedAt != null) {
      final d = b.defeatedAt!;
      copy.defeatedAt = d.isFinite ? d : age;
    }
    return (copy, BossMotion(copy, reducedMotion: m.reducedMotion));
  }

  // ------------------------------------------------------------- build --

  factory GargoylePose._build(
    SkyBoss boss,
    BossMotion m, {
    required double lookY,
    required GargoyleSkyLight light,
    required double gap,
  }) {
    final env = _Env(boss, m, gap: gap, look: lookY);
    final ch = env.at(boss.age);
    final reduced = m.reducedMotion;
    // Every lagged blade evaluates the whole state machine at its own earlier
    // time, so "the fan ripples" holds through every beat, not only in idle.
    final near = GargoyleFanMotion(
      strokes: [
        for (var i = 0; i < GargoyleLayout.fanBlades; i++)
          reduced || i == 0
              ? ch.wing
              : env.at(boss.age - i * GargoyleTimeline.bladeLag).wing.clamp(-1.0, 1.0),
      ],
      spread: ch.spread,
      shed: ch.shed,
    );
    final far = GargoyleFanMotion(
      strokes: [
        for (var i = 0; i < GargoyleLayout.fanBlades; i++)
          // The far fan rides a little higher, so the pair crowns him, and
          // beats a tenth of a second behind at nine tenths of the stroke.
          ((reduced ? ch.wing : env.at(boss.age - .1 - i * GargoyleTimeline.bladeLag).wing) * .9 - .12)
              .clamp(-1.0, 1.0),
      ],
      spread: ch.spread,
    );
    final beams = env.beams(boss.age);
    final warning = ch.warning;
    return GargoylePose._fromCh(
      ch,
      age: boss.age,
      time: reduced || m.defeated ? 0.0 : boss.age,
      reduced: reduced,
      defeated: m.defeated,
      arriving: boss.age < boss.arrivalDuration && !m.defeated,
      death: m.defeated ? m.death : 0,
      light: light,
      warnSide: warning > 0 || beams.isNotEmpty ? boss.beamSide : null,
      slit: warning > 0 || beams.isNotEmpty ? boss.slitSweep : false,
      beams: beams,
      nearFan: near,
      farFan: far,
    );
  }

  GargoylePose._fromCh(
    this._ch, {
    required this.age,
    required this.time,
    required this.reduced,
    required this.defeated,
    required this.arriving,
    required this.death,
    required this.light,
    required this.warnSide,
    required bool slit,
    required this.beams,
    required this.nearFan,
    required this.farFan,
    GargoyleTone? toneOverride,
  }) : warnSlit = slit,
       // ignore: prefer_initializing_formals (a named parameter cannot be private)
       _toneOverride = toneOverride,
       stone = _ch.stone,
       lamp = _ch.lamp,
       shatter = _ch.shatter,
       flare = _ch.flare,
       brow = _ch.brow,
       iris = _ch.iris,
       gape = _ch.gape,
       roar = _ch.roar,
       wind = _ch.wind,
       fury = _ch.fury,
       furyBlend = _ch.furyBlend,
       rage = _ch.rage,
       flash = _ch.flash,
       hit = _ch.hit,
       wince = _ch.wince,
       crack = _ch.crack,
       damage = _ch.damage,
       crumble = _ch.crumble,
       glance = _ch.glance,
       warning = _ch.warning,
       warnRelease = _ch.warnRelease,
       lean = _ch.lean,
       pitch = _ch.pitch,
       head = Offset(_ch.headX, _ch.headY),
       wing = _ch.wing,
       spread = _ch.spread,
       tail = _ch.tail,
       chest = _ch.chest,
       visor = _ch.visor,
       steam = _ch.steam,
       grip = _ch.grip,
       dust = _ch.dust,
       shedTau = _ch.shedTau,
       settle = _ch.settle;

  // ------------------------------------------------------------ inputs --

  /// Seconds on the boss clock, always (what the phase math reads); [time] is
  /// the same, or 0 whenever he must hold still (Reduced Motion, the defeat).
  final double age, time;
  final bool reduced, defeated, arriving;

  /// Seconds since the killing blow, or 0 while he lives.
  final double death;

  /// The backdrop's light.
  final GargoyleSkyLight light;

  // ------------------------------------------------ state channels (kept
  // under Reduced Motion) --

  /// 1 = dormant stone (the arrival before the lightning), cooling to 0 by 2.10
  /// s; the whole creature greys with it ([GargoyleTone.stone]). 0 otherwise.
  final double stone;

  /// The lamp's louvres: 0 shuttered .. 1 open (the rules' `lampOpenness`).
  final double lamp;

  /// The lamp glass broken, 0 .. 1 (defeat .6 s), and the lamp's glance (a
  /// rock clinked off the shuttered lamp, a .15 s pulse: the louvres rattle
  /// (motion) and a brass spark flies (state)).
  final double shatter, glance;

  /// The lenses' glow, 0 .. 1: idle .3 (a slow pulse), the warning climbs to 1,
  /// the sweep holds 1, the vent .2, fury's floor .8; sparks at the arrival's
  /// lightning.
  final double flare;

  /// The brow visors' scowl, 0 .. 1: they drop over the lenses as he gets
  /// angry (idle .3, warning and sweep 1, fury 1, a wince lifts it).
  final double brow;

  /// The lens aperture: 1 open .. 0 shut (the blink irises the lenses; the
  /// defeat shuts them).
  final double iris;

  /// How far the beak is open, 0 .. 1: the vent (.55), the roars, the talk.
  final double gape;

  /// The roar (arrival and fury onset), 0 .. 1: head thrown up, beak wide, fan
  /// flung open. Also the intake before it, [wind].
  final double roar, wind;

  /// Fury, 0 .. 1: lamps white-hot, seams cracked amber, fan opened. Eases in
  /// over .45 s from the moment he crosses half health; [furyBlend] is the raw
  /// ramp, [rage] the onset's 1.1 s pulse (the ring).
  final double fury, furyBlend, rage;

  /// The hit flash (bleach, peak .55, .3 under Reduced Motion), the hit's .28 s
  /// pulse and the wince expression that follows it.
  final double flash, hit, wince;

  /// The seam cracks, 0 .. 1 (fury .6, the defeat 1) and the body crumbling
  /// (.85 s .. 1.1 s after the killing blow: the rig draws nothing at 1).
  final double crack, crumble;

  /// How much of his health is gone, 0 .. 1 (`1 - hp / maxHp`: a pure function
  /// of the rules' health, 1 once he is down, as the rules' `hp` is 0 then): the body's hairline cracks grow
  /// with it, so a fight shows its damage long before the fury's seams.
  final double damage;

  /// The warning's progress through its 1.5 s (0 outside it), the side and
  /// kind it announces (null outside the warning and the sweep).
  final double warning;

  /// The warning's tail: 1 at the instant the beam ignites (the fan is as full
  /// as it was) falling to 0 over [GargoyleBeamLook.warnReleaseSeconds], so the
  /// fan, veil and tag dissolve UNDER the beam instead of vanishing in one
  /// frame. 0 at any other time. Not in [channels] (a render-only tail: the
  /// warning's own channel is 0 from the ignition on).
  final double warnRelease;
  final BeamSide? warnSide;
  final bool warnSlit;

  /// The upper body's lean toward the bird (about the hips; -1 rears back, +1
  /// leans in; see [GargoyleLayout.bodyTurn]).
  final double lean;

  /// The head's pitch in radians (positive: nose DOWN), its nudge in rig units,
  /// both about [GargoyleLayout.headPivot].
  final double pitch;
  final Offset head;

  /// Near fan's blade-0 stroke (-1 shrugged up .. +1 mantled) and the fan's
  /// opening, for parts that want one number (see [nearFan] for the blades).
  final double wing, spread;

  /// The tail fan's swing (-1 cocked up .. +1 drooped), the chest's swell (0 ..
  /// about .15), and whether the brow visor is still on (1; the defeat knocks
  /// it loose at .3 s, 0 after).
  final double tail, chest, visor;

  // ------------------------------------------------- motion channels (zero
  // under Reduced Motion) --

  /// Steam from the shoulder ports, a 1.2 s pulse from the vent (0 .. 1).
  final double steam;

  /// The talons' clench on the ledge, 0 .. 1 (a flick, a hit, the roar).
  final double grip;

  /// The telegraph of a loosening feather: 0 .. 1 while a feather is about to
  /// drop from the cornice (.45 s before the launch), else 0.
  final double dust;

  /// Seconds since the shed blade left the near fan (it flies up and away for
  /// about .6 s), or -1. See [GargoyleLayout.shedVelocity].
  final double shedTau;

  /// 1 when idle life shows, .. 0 while a beat holds him (kept for parts that
  /// want to fade their own flutter).
  final double settle;

  // ------------------------------------------------------------ structured --

  /// The two fans, blade by blade.
  final GargoyleFanMotion nearFan, farFan;

  /// The beams burning now (0, 1 or 2): the rules' bands, and which lens fires.
  final List<GargoyleBeam> beams;

  // -------------------------------------------------------- derived --

  final _Ch _ch;
  final GargoyleTone? _toneOverride;

  /// The look every part shares, on the ladder [GargoyleTone.snapped].
  GargoyleTone get tone => _toneOverride ?? exactTone.snapped();

  /// The same look at full precision (the tests).
  GargoyleTone get exactTone => GargoyleTone(
    flash: flash,
    fury: fury,
    heat: math.max(math.max(lamp * .9, flare * .45), math.max(fury * .3, roar * .5)),
    dark: light.dark,
    sky: light.sky,
    stone: stone,
  );

  /// This same moment under another look (studies and the prewarm): the same
  /// channels with [tone] in place of the derived one.
  GargoylePose withTone(GargoyleTone tone) => GargoylePose._fromCh(
    _ch,
    age: age,
    time: time,
    reduced: reduced,
    defeated: defeated,
    arriving: arriving,
    death: death,
    light: light,
    warnSide: warnSide,
    slit: warnSlit,
    beams: beams,
    nearFan: nearFan,
    farFan: farFan,
    toneOverride: tone.snapped(),
  );

  /// [local] in the head's authored frame as a rig point: pitch, nudge and the
  /// body's lean, exactly [GargoyleLayout.headPoint].
  Offset headPoint(Offset local) =>
      GargoyleLayout.headPoint(local, pitch: pitch, nudge: head, lean: lean);

  /// [local] in the upper body's frame (before the lean, which pivots on the lamp)
  /// as a rig point.
  Offset bodyPoint(Offset local) =>
      GargoyleLayout.turn(local - GargoyleLayout.leanPivot, GargoyleLayout.bodyTurn(lean)) + GargoyleLayout.leanPivot;

  /// Every scalar channel by name (tests diff poses with it; builders print it).
  Map<String, double> get channels => {
    'stone': stone, 'lamp': lamp, 'shatter': shatter, 'glance': glance, 'flare': flare,
    'brow': brow, 'iris': iris, 'gape': gape, 'roar': roar, 'fury': fury,
    'furyBlend': furyBlend, 'rage': rage, 'flash': flash, 'hit': hit, 'wince': wince,
    'crack': crack, 'damage': damage, 'crumble': crumble, 'warning': warning, 'lean': lean, 'pitch': pitch,
    'headX': head.dx, 'headY': head.dy, 'wing': wing, 'spread': spread, 'tail': tail,
    'chest': chest, 'visor': visor, 'steam': steam, 'grip': grip, 'dust': dust,
    'shedTau': shedTau, 'shed': nearFan.shed, 'beams': beams.length.toDouble(),
    for (var i = 0; i < nearFan.strokes.length; i++) 'near$i': nearFan.strokes[i],
    for (var i = 0; i < farFan.strokes.length; i++) 'far$i': farFan.strokes[i],
  };

  /// The pitch that follows a beam whose band is at [centre] at the bird's
  /// column, from lenses [gap] screen heights from it: .40 of the beam's own
  /// angle (the report's .55, lowered so a LOW beam never bows the beak into
  /// the throat notch), -.35 .. +.5. (The rules' band is a height at the column; the
  /// lenses are at about y .235.)
  static double beamPitch(double centre, {double gap = defaultGap}) =>
      (.40 * math.atan2(centre - lensY, gap)).clamp(-.35, .5);

  /// The height of his lenses in screen heights at rest (.5 - 2.4 x .115).
  static const lensY = .224;
}

// ---------------------------------------------------------------------------
// The state machine. Everything below is private: parts read channels only.

double _ramp(double v, double a, double b) => BossMotion.ramp(v, a, b);
double _ease(double t) => BossMotion.ease(t);
double _outCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
double _mix(double a, double b, double t) => a + (b - a) * t;

/// Piecewise smoothstep through [k] (time, value) keys: eased between
/// neighbours, constant outside them.
double _kf(double x, List<(double, double)> k) {
  if (x <= k.first.$1) return k.first.$2;
  for (var i = 1; i < k.length; i++) {
    if (x < k[i].$1) {
      final (t0, v0) = k[i - 1];
      final (t1, v1) = k[i];
      return _mix(v0, v1, _ease((x - t0) / (t1 - t0)));
    }
  }
  return k.last.$2;
}

/// The hit flash: bites in .03 s, drains by .28 s.
double _hitFlash(double tau) => tau < 0 || tau > .28
    ? 0
    : tau < .03
    ? tau / .03
    : 1 - _ease(_ramp(tau, .03, .28));

/// The arrival's roar: a fast attack (.16 s), a hold (.30 s), a slow release
/// (.45 s): full from 2.81 to 3.11, gone by 3.56.
double _roarOfArrival(double k) => k <= 0
    ? 0
    : k < .16
    ? _ease(k / .16)
    : k < .46
    ? 1
    : k < .91
    ? 1 - _ease((k - .46) / .45)
    : 0;

/// The fury onset's roar: a beat of stillness after the blow (the flinch lands
/// first), a fast throw by .30 s, a hold, the long fall.
double _roarOfFury(double since) => since < .12
    ? 0
    : since < .30
    ? _outCubic((since - .12) / .18)
    : since < .60
    ? 1
    : since < 1.1
    ? 1 - _ease((since - .60) / .50)
    : 0;

/// A channel set: the pose's numbers while the state machine builds them.
final class _Ch {
  double stone = 0, lamp = 0, shatter = 0, flare = .3, brow = .3, iris = 1, gape = 0;
  double roar = 0, wind = 0, fury = 0, furyBlend = 0, rage = 0, flash = 0, hit = 0;
  double wince = 0, crack = 0, damage = 0, crumble = 0, glance = 0, warning = 0, warnRelease = 0, lean = 0, pitch = 0;
  double headX = 0, headY = 0, wing = 0, spread = 0, tail = 0, chest = 0, visor = 1;
  double steam = 0, grip = 0, dust = 0, shed = 0, shedTau = -1, settle = 1;
}

GargoyleFanMotion _fan(_Ch ch, {required bool far}) => GargoyleFanMotion(
  strokes: List.filled(GargoyleLayout.fanBlades, far ? (ch.wing * .9 - .12).clamp(-1.0, 1.0) : ch.wing),
  spread: ch.spread,
  shed: far ? 0 : ch.shed,
);

/// The state machine behind [GargoylePose]: a function of the boss and of an
/// instant [at] (the lagged blades ask it about earlier instants).
final class _Env {
  _Env(this.b, this.m, {required this.gap, required this.look})
    : reduced = m.reducedMotion,
      arrival = b.arrivalDuration,
      defeatAt = b.defeatedAt ?? double.infinity;

  final SkyBoss b;
  final BossMotion m;
  final double gap, look;
  final bool reduced;
  final double arrival, defeatAt;

  static const period = GargoyleTimeline.period;

  bool fights(double age) => age >= arrival && age < defeatAt;
  double combat(double age) => age - arrival;

  /// Seconds into the 9 s cycle, or 0 before combat.
  double cycleAt(double age) {
    final t = combat(age);
    return t < 0 ? 0 : t % period;
  }

  double warningAt(double x) =>
      x < GargoyleTimeline.warnAt || x >= GargoyleTimeline.sweepAt
      ? 0
      : (x - GargoyleTimeline.warnAt) / (GargoyleTimeline.sweepAt - GargoyleTimeline.warnAt);

  bool get high => b.beamSide == BeamSide.high;

  /// The zone or slit beam's pitch target at cycle time [x] in the sweep.
  double aim(double x) {
    if (b.slitSweep) {
      final (u, l) = (
        _centreSlit(x, upper: true),
        _centreSlit(x, upper: false),
      );
      return GargoylePose.beamPitch((u + l) / 2, gap: gap);
    }
    return GargoylePose.beamPitch(_centreZone(x), gap: gap);
  }

  double _glide(double from, double to, double s, double seconds) =>
      _mix(from, to, _ease((s / seconds).clamp(0.0, 1.0)));

  /// The zone beam's centre at the bird's column at cycle time [x] (clamped to
  /// the sweep): the rules' glide (`SearchlightGargoyle.centre`), which takes
  /// [GargoyleTimeline.furyGlideSeconds] at fury's pace (`SkyBoss.furyPace`)
  /// and [GargoyleTimeline.glideSeconds] otherwise. Used for the head's aim and for
  /// the instants the rules' own getter is silent (the fade after the vent, the
  /// defeat's stutter); the beam burning NOW is always read from
  /// `SkyBoss.beamCentres`, so the drawn band is the rules' in any tree.
  double _centreZone(double x) {
    final s = x.clamp(GargoyleTimeline.sweepAt, GargoyleTimeline.ventAt) - GargoyleTimeline.sweepAt;
    final seconds = b.furyPace ? GargoyleTimeline.furyGlideSeconds : GargoyleTimeline.glideSeconds;
    return high
        ? _glide(SearchlightGargoyle.highFrom, SearchlightGargoyle.highTo, s, seconds)
        : _glide(SearchlightGargoyle.lowFrom, SearchlightGargoyle.lowTo, s, seconds);
  }

  double _centreSlit(double x, {required bool upper}) {
    final s = x.clamp(GargoyleTimeline.sweepAt, GargoyleTimeline.ventAt) - GargoyleTimeline.sweepAt;
    final (from, to) = upper ? SearchlightGargoyle.slitUpper : SearchlightGargoyle.slitLower;
    return _glide(from, to, s, GargoyleTimeline.furyGlideSeconds);
  }

  /// The beams burning (or fading, or stuttering) at [age].
  List<GargoyleBeam> beams(double age) {
    final dead = age >= defeatAt;
    final live = dead ? defeatAt : age;
    if (!fights(live) && !dead) return const [];
    final t = combat(live);
    if (t < 0) return const [];
    final x = t % period;
    var k = 0.0;
    if (x >= GargoyleTimeline.sweepAt && x < GargoyleTimeline.ventAt) {
      // It hurts from its first frame, so it is on from its first frame: the
      // edges at full and the body at [GargoyleBeamLook.igniteFloor] rising to 1.
      k = reduced
          ? 1
          : GargoyleBeamLook.igniteFloor +
                (1 - GargoyleBeamLook.igniteFloor) *
                    _ramp(x, GargoyleTimeline.sweepAt, GargoyleTimeline.sweepAt + GargoyleBeamLook.igniteSeconds);
    } else if (!reduced &&
        !dead &&
        x >= GargoyleTimeline.ventAt &&
        x < GargoyleTimeline.ventAt + GargoyleBeamLook.fadeSeconds) {
      k = 1 - _ramp(x, GargoyleTimeline.ventAt, GargoyleTimeline.ventAt + GargoyleBeamLook.fadeSeconds);
    }
    if (dead) {
      // "The beams stutter out": a beam burning at the killing blow gutters for
      // .3 s; Reduced Motion shows none.
      final d = age - defeatAt;
      if (reduced || k <= 0 || d >= .3) return const [];
      k *= d < .12 ? 1 : (math.sin(d * 75) > 0 ? .85 : .1) * (1 - _ramp(d, .12, .3));
    }
    if (k <= 0) return const [];
    final xs = x >= GargoyleTimeline.ventAt ? GargoyleTimeline.ventAt - 1e-6 : x;
    final fury = b.enraged;
    final half = SearchlightGargoyle.half(enraged: b.furyPace);
    if (!dead && age == b.age && b.beamOn) {
      // The beam burning now is the rules' band, exactly.
      final rules = b.beamCentres;
      if (rules.length == 2) {
        return [
          GargoyleBeam(centre: rules[0], half: b.beamHalf, far: true, fury: fury, intensity: k),
          GargoyleBeam(centre: rules[1], half: b.beamHalf, far: false, fury: fury, intensity: k),
        ];
      }
      if (rules.length == 1) {
        return [GargoyleBeam(centre: rules.first, half: b.beamHalf, far: false, fury: fury, intensity: k)];
      }
    }
    if (b.slitSweep) {
      return [
        GargoyleBeam(centre: _centreSlit(xs, upper: true), half: half, far: true, fury: fury, intensity: k),
        GargoyleBeam(centre: _centreSlit(xs, upper: false), half: half, far: false, fury: fury, intensity: k),
      ];
    }
    return [GargoyleBeam(centre: _centreZone(xs), half: half, far: false, fury: fury, intensity: k)];
  }

  /// Launch times in combat seconds near [t]: this cycle's schedule and the
  /// next cycle's first feather (its wind-up begins before this one ends).
  List<double> events(double t) {
    final k = math.max((t / period).floor(), 0);
    return [
      for (final s in b.featherSchedule) k * period + s,
      if (b.perchFeatherIn(k + 1))
        (k + 1) * period + SearchlightGargoyle.calmFeathers.first,
    ];
  }

  _Ch at(double age) {
    final dead = age >= defeatAt;
    final ch = _Ch();
    _live(ch, dead ? defeatAt : age);
    ch.damage = _damage(b);
    if (age < arrival) _arrival(ch, age);
    if (dead) _defeat(ch, age - defeatAt);
    _limit(ch);
    return ch;
  }

  /// `1 - hp / maxHp`, clamped: the rules' health as a fraction gone.
  static double _damage(SkyBoss b) => b.maxHp <= 0 ? 0.0 : (1 - b.hp / b.maxHp).clamp(0.0, 1.0);

  // ------------------------------------------------------------- live --

  void _live(_Ch ch, double age) {
    final t = combat(age);
    final x = t < 0 ? 0.0 : t % period;
    final fights = t >= 0;
    final time = reduced ? 0.0 : age;
    final s = GargoyleTimeline.sweepAt, v = GargoyleTimeline.ventAt;

    // Fury ramps in over .45 s from the moment he crosses half health.
    final since = age - b.enragedAt;
    final enraged = b.enraged && fights;
    ch.furyBlend = !enraged
        ? 0
        : reduced || !since.isFinite
        ? 1
        : _ease(_ramp(since, 0, GargoyleTimeline.furyBlendSeconds));
    ch.rage = !enraged || reduced ? 0 : BossMotion.pulse(since, GargoyleTimeline.rageSeconds);
    ch.fury = (.8 + ch.rage * .2) * ch.furyBlend;

    // The cycle's postures.
    ch.lean = _kf(x, const [
      (0, 0), (2.0, 0), (2.5, -.45), (3.05, -.45), (3.5, .7), (6.4, .7), (6.75, -.6), (8.7, -.6), (9.0, 0),
    ]);
    final aim0 = aim(s), aim1 = aim(v);
    ch.pitch = x < GargoyleTimeline.warnAt
        ? 0
        : x < s
        ? _kf(x, [(2.0, 0), (2.5, -.16), (3.05, -.16), (3.5, aim0)])
        : x < v
        ? aim(x)
        : _kf(x, [(6.4, aim1), (6.75, -.22), (7.6, -.18), (8.7, -.05), (9.0, 0)]);
    ch.wing = _kf(x, const [
      (0, 0), (2.0, 0), (2.5, -.3), (3.5, -.25), (6.4, -.2), (6.75, -1.0), (7.6, -.6), (8.7, -.15), (9.0, 0),
    ]);
    ch.spread = _kf(x, const [
      (0, 0), (2.0, 0), (3.0, .25), (6.4, .25), (6.75, .6), (7.8, .3), (8.7, .1), (9.0, 0),
    ]);
    ch.flare = _kf(x, const [
      (0, .3), (2.0, .3), (3.5, 1.0), (6.4, 1.0), (6.65, .2), (8.7, .2), (9.0, .3),
    ]);
    ch.brow = _kf(x, const [
      (0, .3), (2.0, .3), (2.4, 1.0), (6.4, 1.0), (6.75, .5), (8.7, .5), (9.0, .3),
    ]);
    ch.gape = _kf(x, const [
      (0, 0), (6.4, 0), (6.75, .55), (7.6, .35), (8.5, .05), (9.0, 0),
    ]);
    ch.lamp = fights ? SearchlightGargoyle.lampOpenness(x) : 0;
    ch.warning = fights ? warningAt(x) : 0;
    ch.warnRelease = fights && x >= s && x < s + GargoyleBeamLook.warnReleaseSeconds
        ? 1 - _ease(_ramp(x, s, s + GargoyleBeamLook.warnReleaseSeconds))
        : 0;
    ch.headY = 0;

    // Fury: the fan opens, the eyes stay hot, the brow stays down, seams crack.
    if (ch.furyBlend > 0) {
      ch.spread = _mix(ch.spread, math.max(ch.spread, .55), ch.furyBlend);
      ch.flare = math.max(ch.flare, .8 * ch.furyBlend);
      ch.brow = math.max(ch.brow, .9 * ch.furyBlend);
      ch.crack = .6 * ch.furyBlend;
      final roar = reduced ? 0.0 : _roarOfFury(since);
      if (roar > 0) {
        ch.roar = math.max(ch.roar, roar);
        _toward(ch, roar, pitch: -.30, gape: .9, wing: -1, spread: 1, lean: -.7, headX: .2, headY: -.06);
      }
    }

    // Idle life (motion): breath, the head's bob, the lens pulse, the blink.
    ch.chest = reduced ? 0 : math.sin(time * GargoyleTimeline.breathOmega) * .03;
    if (!reduced) {
      ch.headY += math.sin(time * 1.1 + .6) * .025;
      ch.lean += math.sin(time * GargoyleTimeline.breathOmega) * .04;
      ch.flare = (ch.flare + math.sin(time * GargoyleTimeline.lensOmega) * .05 * (1 - ch.furyBlend * .5)).clamp(0.0, 1.0);
    }
    ch.tail = (-.35 * ch.lean + (reduced ? 0 : math.sin(time * 1.3) * .3)).clamp(-1.0, 1.0);
    ch.iris = 1 - m.blink;
    ch.chest += .05 * ch.lamp;

    // The stone feather's shrug (motion): wind-up, flick, settle.
    if (!reduced) {
      for (final e in events(t)) {
        final wind = _ease(_ramp(t, e - GargoyleTimeline.shrugWindUp - GargoyleTimeline.shrugFlick, e - GargoyleTimeline.shrugFlick));
        final flickIn = _ease(_ramp(t, e - GargoyleTimeline.shrugFlick, e));
        final flickOut = t < e ? 1.0 : 1 - _ease(_ramp(t, e, e + GargoyleTimeline.shrugSettle));
        final w = wind * (1 - flickIn);
        final f = flickIn * flickOut;
        if (t < e - .6 || t > e + GargoyleTimeline.regrowSeconds + .05) continue;
        ch.lean += -.8 * w + .3 * f;
        ch.pitch += -.10 * w + .10 * f;
        ch.headY += -.08 * w;
        ch.wing = _mix(ch.wing, -1, f);
        ch.spread = _mix(ch.spread, math.max(ch.spread, .5), f);
        ch.grip = math.max(ch.grip, f);
        ch.dust = math.max(ch.dust, t < e ? _ramp(t, e - .45, e) : 0);
        if (t >= e && t < e + GargoyleTimeline.regrowSeconds + 1e-9) {
          ch.shedTau = t - e;
          ch.shed = 1 - _ease(_ramp(t, e + .05, e + GargoyleTimeline.regrowSeconds));
        }
      }
      ch.settle = 1 - math.max(ch.grip, ch.warning > 0 ? .5 : 0);
    }

    // Steam from the shoulder ports as the lamp vents (motion).
    if (!reduced && fights && x >= v && x < v + GargoyleTimeline.steamSeconds) {
      ch.steam = math.sin(math.pi * (x - v) / GargoyleTimeline.steamSeconds);
    }

    // The head watches the bird a hair while he perches (motion).
    if (!reduced && look != 0 && (x < GargoyleTimeline.warnAt || x >= v + .4)) {
      ch.pitch += look * .05;
    }

    // A rock glancing off the shuttered lamp (spark = state, rattle = motion).
    ch.glance = BossMotion.pulse(age - b.lastGlanceAt, GargoyleTimeline.glanceSeconds);
    ch.grip = math.max(ch.grip, ch.glance * .6);

    // A hit: flash (state), the flinch (motion), the wince (state).
    // Rapid fire lands a hit on top of the last one's reaction, and a lagged
    // blade is sampled BEFORE the last hit landed: the channel is the larger
    // of the last hit's pulse and the one before it, so nothing snaps back to
    // rest when a hit re-lands (blades 3 to 6 and the far fan used to jump up
    // to 1.2 of their 2.0 stroke in one tick).
    final hitAt = age - b.lastHitAt, beforeAt = age - b.previousHitAt;
    ch.hit = math.max(
      BossMotion.pulse(hitAt, GargoyleTimeline.hitSeconds),
      BossMotion.pulse(beforeAt, GargoyleTimeline.hitSeconds),
    );
    ch.wince = _ramp(ch.hit, .2, .5);
    // The flash: the hit's share of the peak is how long it has been since the
    // hit before (a re-hit inside the flash of the last one barely flashes).
    final gap = b.lastHitAt - b.previousHitAt;
    final share = gap.isFinite ? 1 - math.exp(-math.max(gap, 0.0) / GargoyleTimeline.hitFlashRecover) : 1.0;
    ch.flash = reduced
        ? ch.hit * GargoyleTimeline.hitFlashPeakReduced * share
        : math.max(
            _hitFlash(hitAt) * GargoyleTimeline.hitFlashPeak * share,
            _hitFlash(beforeAt) * GargoyleTimeline.hitFlashPeak,
          );
    if (!reduced && ch.hit > 0) {
      ch.lean += -.9 * ch.hit;
      ch.pitch += -.12 * ch.hit;
      ch.headX += .25 * ch.hit;
      ch.wing = _mix(ch.wing, math.max(ch.wing, .3), ch.hit);
      ch.grip = math.max(ch.grip, ch.hit);
    }
    ch.brow = (ch.brow - ch.wince * .3).clamp(0.0, 1.0);
  }

  /// The hard ranges the envelope was proven on: the lean and the head's pitch
  /// never leave them whatever the beats add up to.
  static void _limit(_Ch ch) {
    ch.lean = ch.lean.clamp(-.8, .8);
    ch.pitch = ch.pitch.clamp(-.22, .5);
  }

  /// Blends the named channels toward a target pose by [k].
  void _toward(
    _Ch ch,
    double k, {
    double? pitch,
    double? gape,
    double? wing,
    double? spread,
    double? lean,
    double? headX,
    double? headY,
    double? flare,
    double? brow,
    double? chest,
  }) {
    if (pitch != null) ch.pitch = _mix(ch.pitch, pitch, k);
    if (gape != null) ch.gape = _mix(ch.gape, gape, k);
    if (wing != null) ch.wing = _mix(ch.wing, wing, k);
    if (spread != null) ch.spread = _mix(ch.spread, spread, k);
    if (lean != null) ch.lean = _mix(ch.lean, lean, k);
    if (headX != null) ch.headX = _mix(ch.headX, headX, k);
    if (headY != null) ch.headY = _mix(ch.headY, headY, k);
    if (flare != null) ch.flare = _mix(ch.flare, flare, k);
    if (brow != null) ch.brow = _mix(ch.brow, brow, k);
    if (chest != null) ch.chest = _mix(ch.chest, chest, k);
  }

  // ---------------------------------------------------------- arrival --

  void _arrival(_Ch ch, double age) {
    const strike = GargoyleTimeline.revealAt;
    // Dormant stone: mantled fan, head bowed, lenses dark, until the lightning;
    // then cool to colour by 2.10 s (Reduced Motion: a .25 s fade).
    ch.stone = reduced
        ? 1 - _ramp(age, strike, strike + .25)
        : 1 - _ease(_ramp(age, GargoyleTimeline.stoneClearFrom, GargoyleTimeline.stoneClearTo));
    final awake = _ease(_ramp(age, strike, 2.65));
    final dormant = 1 - awake;
    _toward(ch, dormant, wing: 1, spread: 0, pitch: .22, lean: .1, flare: 0, brow: .3, gape: 0, headX: 0, headY: 0, chest: 0);
    ch.iris = ch.iris * _mix(.35, 1, _ease(_ramp(age, strike, 2.0)));
    ch.lamp = 0;
    // The lenses ignite with the lightning: two sparks at 1.68 and 1.78.
    for (final at in GargoyleTimeline.lensSparkAt) {
      ch.flare = math.max(ch.flare, BossMotion.pulse(age - at, .10));
    }
    // The fan unfolds (2.0 .. 2.65), the intake, the ROAR (2.65).
    final unfold = age < 2.65
        ? _ease(_ramp(age, GargoyleTimeline.unfoldFrom, GargoyleTimeline.unfoldTo))
        : age < 3.11
        ? 1.0
        : 1 - _ease(_ramp(age, 3.11, 3.56));
    final intake = _ease(_ramp(age, GargoyleTimeline.windAt, GargoyleTimeline.roarAt)) * (age < 2.65 ? 1 : 0);
    ch.wind = intake;
    _toward(ch, unfold, wing: -1, spread: 1, pitch: -.22, lean: -.5, flare: .8, brow: .7);
    final roar = _roarOfArrival(age - GargoyleTimeline.roarAt);
    ch.roar = roar;
    _toward(ch, roar, pitch: -.30, gape: .85, flare: 1, headX: .2, headY: -.05, chest: .06);
    ch.chest += .03 * intake;
    // The lightning's own crack, a flash of seams as the stone wakes.
    ch.crack = math.max(ch.crack, reduced ? 0.0 : BossMotion.pulse(age - strike, .5) * .8);
    ch.grip = math.max(ch.grip, roar);
    ch.settle = 1 - math.max(unfold, roar);
    // Nothing of the fight shows yet.
    ch.warning = 0;
    ch.warnRelease = 0;
    ch.glance = 0;
    ch.wince = 0;
    ch.hit = 0;
    ch.flash = 0;
  }

  // ----------------------------------------------------------- defeat --

  void _defeat(_Ch ch, double death) {
    final throes = reduced ? (death > 0 ? 1.0 : 0.0) : _ease(_ramp(death, .02, .32));
    _toward(
      ch,
      throes,
      wing: 1,
      spread: 0,
      pitch: .55,
      lean: .4,
      headX: .2,
      headY: .55,
      gape: .3,
      flare: 0,
      brow: .3,
      chest: 0,
    );
    ch.lamp = _mix(ch.lamp, .2, throes);
    ch.iris = _mix(ch.iris, 0, reduced ? throes : _ease(_ramp(death, .12, .5)));
    ch.fury = ch.fury * (1 - _ease(_ramp(death, .1, .5)));
    ch.furyBlend = ch.furyBlend * (1 - _ease(_ramp(death, .1, .5)));
    ch.rage = 0;
    ch.roar = 0;
    // The seams the fury opened keep opening (no drop to 0 at the killing
    // blow: the crack never pops, whatever the white-out covers).
    final live = ch.crack;
    ch.crack = reduced ? math.max(live, .8) : math.max(live, _ramp(death, GargoyleTimeline.crackFrom, GargoyleTimeline.crackTo));
    ch.shatter = reduced ? (death >= GargoyleTimeline.glassShatterAt ? 1 : 0) : _ease(_ramp(death, GargoyleTimeline.glassShatterAt, GargoyleTimeline.glassShatterAt + .1));
    ch.crumble = reduced ? 0 : _ramp(death, GargoyleTimeline.burstAt, GargoyleTimeline.burstAt + .25);
    ch.visor = death < GargoyleTimeline.visorLostAt ? 1 : 0;
    ch.flash = 0;
    ch.hit = 0;
    ch.wince = 0;
    ch.glance = 0;
    ch.warning = 0;
    ch.warnRelease = 0;
    ch.grip = math.max(ch.grip, throes);
    ch.steam = reduced
        ? 0
        : BossMotion.pulse(death - .12, .68) * (1 - _ramp(death, .8, .9));
    ch.dust = 0;
    ch.shed = 0;
    ch.shedTau = -1;
    ch.settle = 1 - throes;
  }
}
