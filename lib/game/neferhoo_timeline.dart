import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';
import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';

/// Neferhoo's fight as a pose: the design's eased timeline
/// (`egypt-ws/iter5/test/egypt/mummy_timeline.dart`, `FightState`), ported
/// 1:1 and driven by the real fight: the rules' 12 s clock
/// ([Neferhoo.cycleTime] of [SkyBoss.combatTime]), the screen place the
/// rules give him ([SkyBoss.x], [SkyBoss.y], [NeferhooBoss.handX]) and what
/// the rules latched on [SkyBoss.neferhoo] (the express post, this cycle's
/// ankhs with their lanes, throws and speeds; the landings and hits).
///
/// Every beat is an eased blend with its own anticipation and settle (review
/// 08 M1), the wing's velocity is the real derivative of the wing channel,
/// the calm face thinks (a blink every 3.7 s docked off the lock moments, a
/// gaze that holds a thought, a breath; M2), and the open sky between the
/// ankh's homecoming and the next mail call holds the gag (he buffs his own
/// postmark; M4), laid out for the room the screen's width leaves (N1). The
/// design's single `fury` flag is three here, because the staged fight
/// latches them at different moments: [express] (the mail call's stream,
/// latched at its lock), the ankhs (latched at theirs) and [fury] (the
/// posture, eased in over [furyBlend] from the hit that made him furious).
///
/// Everything is a pure function of the inputs: seeks and replays
/// reproduce a frame exactly. Under Reduced Motion ([reduced]) the clocks
/// freeze (no wingbeat, no bob, no blink, no gag) and the states stay.
class NeferhooTimeline {
  NeferhooTimeline({
    required this.ct,
    required this.phase,
    this.bx = 1.17,
    this.by = .52,
    this.express = false,
    this.fury = false,
    this.ankhs = const [],
    this.previousHome,
    this.reduced = false,
    this.birdX = FlightSimulation.birdX,
    this.roarAt,
    this.inHand,
    this.furyRoar = false,
    this.beats = NeferhooBeats.classic,
    this.deals,
    this.previousAnkhs = const [],
  });

  /// The timeline of [boss] at boss age [at] (now by default): the rules'
  /// clock and latches, eased, with [fury] the posture he has then. In the
  /// arrival the clock rests at the fight's first moment.
  factory NeferhooTimeline.of(SkyBoss boss, {required bool reduced, double? at, bool? fury}) =>
      _fromBoss(boss, reduced, at ?? boss.age, fury ?? boss.enraged);

  /// The whole fight pose of [boss] now (what [NeferhooPose.fight] gives):
  /// the timeline's beats, fury's posture eased in over [furyBlend] from the
  /// hit that made him furious (the wraps tear open, the mask cracks), the
  /// recoil of the hits (a returned letter's landing in full, a scuff on his
  /// wraps at [scuffRecoil]), the RETURN TO SENDER stamp slammed on his chest
  /// by each landing, and his eye on the bird ([lookY], screen heights x 3).
  /// While he is being defeated the pose he died in is held (the defeat's
  /// choreography is the encounter's own).
  static NeferhooPose poseOf(SkyBoss boss, BossMotion m, {double lookY = 0}) {
    final reduced = m.reducedMotion;
    final dead = boss.defeatedAt;
    final age = dead != null && dead.isFinite ? math.min(boss.age, dead) : boss.age;
    if (!age.isFinite) return NeferhooPose(reduced: reduced);
    // fury's posture, eased in
    final furious = boss.enraged;
    final since = age - boss.enragedAt;
    final k = !furious ? 0.0 : (!since.isFinite || reduced ? 1.0 : NeferhooKit.smooth01(since / furyBlend));
    // the wraps open in fury and wider as he weakens (.7 at the onset, .9 near the end)
    final third = boss.maxHp / 3;
    final unwrap = (.7 + .2 * (1 - boss.hp / third)).clamp(.7, .9);
    NeferhooPose at(bool fury) => NeferhooTimeline._fromBoss(boss, reduced, age, fury).pose(unwrap: fury ? unwrap : 0);
    final p = k <= 0 ? at(false) : (k >= 1 ? at(true) : _lerpPose(at(false), at(true), k));
    // his eye on the bird: the gaze rides a little toward the bird's height (a
    // constant share, so it adds nothing to the gaze's own slides)
    final ly = lookY.isFinite ? lookY.clamp(-1.2, 1.2) : 0.0;
    p.look = p.look + Offset(0, .15 * ly);
    // the hits: a recoil (a re-hit blends from the one before)
    final fight = boss.neferhoo;
    double recoil(double at) {
      final t = age - at;
      if (!t.isFinite || t < 0 || t > hitSeconds) return 0;
      final full = (at - fight.lastLandAt).abs() < 1e-6;
      return math.sin(t / hitSeconds * math.pi) * (full ? 1.0 : scuffRecoil);
    }

    p.hit = math.max(p.hit, math.max(recoil(boss.lastHitAt), recoil(boss.previousHitAt)));
    // RETURN TO SENDER: the stamp slams on his chest with each landing, holds, lifts
    final land = age - fight.lastLandAt;
    if (land.isFinite && land >= 0 && land < stampSeconds + stampLift) {
      p.stamp = land < .5 ? land / .5 : 1 - NeferhooKit.ramp(land, stampSeconds, stampSeconds + stampLift);
    }
    return p;
  }

  /// The stage-up hoots' beak at [t] seconds into the roar: one opening per
  /// syllable of `hoopoe_roar` (0, .15, .30 s, .15 s each; the arrival's
  /// `NeferhooEncounterArt.beakPulse`).
  static double roarSyllables(double t) {
    var b = 0.0;
    for (final s in const [0.0, .15, .30]) {
      final k = (t - s) / .15;
      if (k > 0 && k < 1) b = math.max(b, math.sin(k * math.pi));
    }
    return b;
  }

  /// A hit's recoil (seconds, the design's .28 s), and a scuff's share of it.
  static const hitSeconds = .28, scuffRecoil = .35;

  /// How long a landing's stamp stays on his chest, and how long it lifts.
  static const stampSeconds = 1.6, stampLift = .3;

  static NeferhooPose _lerpPose(NeferhooPose a, NeferhooPose b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    double g(double x, double y) => x < 0 && y < 0 ? -1 : (x < 0 ? y : (y < 0 ? x : l(x, y)));
    return b.copy(
      crest: l(a.crest, b.crest),
      wing: l(a.wing, b.wing),
      lean: l(a.lean, b.lean),
      beak: l(a.beak, b.beak),
      lid: l(a.lid, b.lid),
      brow: l(a.brow, b.brow),
      look: Offset.lerp(a.look, b.look, t),
      fury: l(a.fury, b.fury),
      unwrap: l(a.unwrap, b.unwrap),
      satchelOpen: l(a.satchelOpen, b.satchelOpen),
      ankh: l(a.ankh, b.ankh),
      ankhSpin: l(a.ankhSpin, b.ankhSpin),
      sweep: l(a.sweep, b.sweep),
      hit: l(a.hit, b.hit),
      glow: l(a.glow, b.glow),
      cracked: l(a.cracked, b.cracked),
      smile: l(a.smile, b.smile),
      headTilt: l(a.headTilt, b.headTilt),
      reach: l(a.reach, b.reach),
      glint: g(a.glint, b.glint),
      ringGlint: g(a.ringGlint, b.ringGlint),
      wingRate: l(a.wingRate ?? 0, b.wingRate ?? 0),
      buff: l(a.buff, b.buff),
    );
  }

  /// The time in the cycle (seconds; the rules' [NeferhooBeats.cycleTime]:
  /// 12 s, or 9 in the faster fight).
  final double ct;

  /// The continuous clock (seconds; combat time in the fight): blinks,
  /// breath, the gaze, the idle wingbeat and the gag's wipe read it.
  final double phase;

  /// His chest (the hit circle's centre) in screen fractions, and the bird's
  /// column (the ankh turns [Neferhoo.ankhBehind] behind it).
  final double bx, by, birdX;

  /// This cycle's mail call is the express post (five letters, faster).
  final bool express;

  /// The furious posture (lean in, glare, flat mouth, the gag's glare).
  final bool fury;

  /// This cycle's ankhs (none in the warm-up and in a cycle the signature
  /// does not run; two in fury).
  final List<NeferhooFlight> ankhs;

  /// When the previous cycle's last ankh came home, in that cycle's time
  /// (a homecoming late on a wide screen carries the catch into this cycle).
  final double? previousHome;

  /// Reduced Motion.
  final bool reduced;

  /// When (cycle time) a stage-up roar began, or null.
  final double? roarAt;

  /// The stage-up into fury (its cue is `mummy_fury`, two phrases), not the
  /// one into the full fight (`hoopoe_roar`, three hoots).
  final bool furyRoar;

  /// The letters still fanned in his hand as the rules count them
  /// ([NeferhooBoss.lettersInHand]), or null for a timeline played from the
  /// clock alone (the design's harnesses, a pose held after the fight).
  final int? inHand;

  /// His clock ([NeferhooBeats.classic], or rules 55's faster one).
  final NeferhooBeats beats;

  /// The mail calls this cycle's pose acts (cycle time; a call of the
  /// previous cycle whose deal runs into this one has a negative lock), in
  /// lock order: given by the faster fight, else the one call of the classic
  /// clock at [Neferhoo.mailLockAt] ([express] latched or not).
  final List<NeferhooDeal>? deals;

  /// The faster clock's previous cycle's ankhs, in that cycle's time: on a
  /// wide screen the ankh comes home after its 10.5 s cycle has ended, and
  /// his eye follows it into this one. (The classic clock's homecoming is
  /// always inside its cycle: none.)
  final List<NeferhooFlight> previousAnkhs;
  List<NeferhooDeal> get calls =>
      deals ??
      [
        (
          lock: Neferhoo.mailLockAt,
          release: Neferhoo.mailReleaseAt,
          express: express,
          count: Neferhoo.streamCount(fury: express),
        ),
      ];

  double get handX => bx - Neferhoo.handOffset;

  /// How long the flying ankh takes to leave the hover point above his
  /// shoulder (seconds; the review asked .15, .22 keeps the fury's long
  /// second hand-over under 25 px a frame). The fight art blends the drawn
  /// ankh over the same window.
  static const ankhEase = .22;

  /// How long fury's posture takes to come in.
  static const furyBlend = .8;

  /// The stage-up roar's length (the shared [SkyBoss.stageRoar]).
  static const roarLength = SkyBoss.stageRoar;

  // ------------------------------------------------------------- the fan --

  static double _gapOf(NeferhooDeal d) =>
      d.express ? Neferhoo.furyStreamGap : Neferhoo.streamGap;

  /// Letters still in the hand (the fan): the rules' count in the fight
  /// ([inHand]); else the design's clock value (`FightState.cardsInHand`:
  /// from [Neferhoo.fanDelay] after the lock until each letter is dealt at
  /// [Neferhoo.mailReleaseAt] + k x the gap), which the rules' count equals.
  int get cardsInHand {
    if (inHand case final n?) return n;
    // (the latest call whose fan is up)
    NeferhooDeal? deal;
    for (final d in calls) {
      if (ct >= d.lock + Neferhoo.fanDelay) deal = d;
    }
    if (deal == null || ct >= deal.release + 3) return 0;
    var n = 0;
    for (var k = 0; k < deal.count; k++) {
      if (ct < deal.release + k * _gapOf(deal)) n++;
    }
    return math.min(n, 3);
  }

  // ----------------------------------------------------------- the ankh --

  /// When the (last) ankh of this cycle is home again (cycle time), or null
  /// when this cycle has none: its throw plus the rules' loop length at its
  /// speed ([NeferhooAnkh.length]).
  double? get ankhHome {
    if (ankhs.isEmpty) return null;
    var home = double.negativeInfinity;
    for (final a in ankhs) {
      home = math.max(home, a.home(handX, Neferhoo.turnX(birdX)));
    }
    return home;
  }

  /// Where he looks while the ankh is out: the eye follows it (the first
  /// ankh in fury, then the second), and rests on the hand it comes home to,
  /// so the gaze never jumps when the ankh lands. In the `look` channel's
  /// units (x -1 toward the bird, y +1 down).
  Offset _ankhGaze(List<NeferhooFlight> ankhs, double ct) {
    final turnX = Neferhoo.turnX(birdX);
    Offset eyeDir(Offset p) {
      // the eye is at about (bx - .146, by - .161) in screen heights
      final dx = p.dx - (bx - .15), dy = p.dy - (by - .17);
      return Offset((dx / .45).clamp(-1.0, .55), (dy / .28).clamp(-.9, .9));
    }

    var sum = Offset.zero, tot = 0.0;
    for (final a in ankhs) {
      final total = a.length(handX, turnX);
      final s = (ct - a.throwAt) * a.speed;
      // each ankh holds the eye while it flies, and lets go smoothly at both ends
      final presence = NeferhooKit.smooth01(s / .25) * NeferhooKit.smooth01((total - s) / .25);
      if (presence <= 0) continue;
      sum += eyeDir(a.at(s.clamp(0.0, total), handX, turnX)) * presence;
      tot += presence;
    }
    // with none in the air the eye rests on the hand the ankh comes home to
    final home = eyeDir(Offset(handX, ankhs.isEmpty ? .5 : ankhs.first.laneB));
    return (sum + home * math.max(0.0, 1 - tot)) / math.max(1.0, tot);
  }

  // ------------------------------------------------- the open-sky gag --

  /// When the gag starts: after the ankh is home and caught (+.3 s) and never
  /// before 10.0 s (calm) / 10.3 s (fury). The homecoming scales with the
  /// screen's width (9.46 s at 640 px, 10.50 at 800, 10.92 at 864, 11.55 at
  /// 960), so a fixed start would begin the wipe before the ankh is home on
  /// every phone wider than 720 px.
  ///
  /// The faster clock (rules 55) keeps the same 2.0 s (fury 1.7 s) before
  /// its cycle's end as the floor: there the ankh is home too late for any
  /// room in the full fight and fury (the gag drops out), and only the
  /// warm-up, which throws no ankh, still has it.
  double get gagStart => math.max(
    beats.isFaster ? beats.period - (fury ? 1.7 : 2.0) : (fury ? 10.3 : 10.0),
    (ankhHome ?? double.negativeInfinity) + .3,
  );
  double get gagLength => _gagEnd - gagStart;

  /// When the gag must be over: the cycle's end, or (the faster clock) the
  /// cycle's second call if it comes before.
  double get _gagEnd {
    var end = beats.period;
    if (beats.isFaster) {
      for (final d in calls) {
        if (d.lock > beats.mailLockAt && d.lock < end) end = d.lock;
      }
    }
    return end;
  }

  /// What fits in the room left before the cycle ends: calm plays two wipes
  /// with 1.8 s, one with 1.15, and below that only the squint, the ring's
  /// star, the glance and the blink, down to .5 s; fury is always ONE brisk
  /// wipe and a glare. The part after the wipe is time-scaled ([GagPlan.kf]).
  GagPlan get gagPlan {
    final start = gagStart, room = _gagEnd - start;
    final wipes = fury ? (room >= 1.15 ? 1 : 0) : (room >= 1.8 ? 2 : (room >= 1.15 ? 1 : 0));
    final tIn = wipes == 2 ? .25 : (fury ? .21 : .22);
    final wipeEnd = wipes == 0 ? .25 : tIn + wipes / 3;
    final kf = ((room - wipeEnd) / GagPlan.finale).clamp(.6, 1.0);
    return GagPlan(start, room, wipes, tIn, wipeEnd, kf, wipes > 0 || room >= .5);
  }

  // ------------------------------------------------------------ the wing --

  /// The idle wingbeat (the pose derives the tips' lag from it).
  double _idleWing(double t) => reduced ? 0 : math.sin((phase - ct + t) * NeferhooPose.wingBeat) * .55;

  static double _mailEndOf(NeferhooDeal d) => _lastReleaseOf(d) + .35;
  static double _lastReleaseOf(NeferhooDeal d) => d.release + (d.count - 1) * _gapOf(d);

  // the ankh's lock and throw (rules: [NeferhooBeats.ankhLockAt], [NeferhooBeats.ankhThrowAt])
  double get _ankhLock => beats.ankhLockAt;
  double get _throwAt => beats.ankhThrowAt;

  // the throw: a coil, a whip, a settle
  /// The moments a blink keeps off: each call's lock to its first letter,
  /// the ankh's lock, its throw to the catch (the classic clock's fixed
  /// windows; the faster clock's from its beats).
  ///
  /// The faster clock's second call (9.6 s) runs past its cycle's end: its
  /// window is also kept one cycle back, so a blink it hands on lands in the
  /// next cycle where that cycle reads it too.
  List<(double, double)> get _keep => !beats.isFaster
      ? _classicKeep
      : [
          for (final (at, kind) in beats.callMoments)
            if (kind != NeferhooCallKind.wave)
              for (final shift in [0.0, -beats.period]) (at - .395 + shift, at + Neferhoo.windupSeconds + .25 + shift),
          (_ankhLock - .395, _ankhLock + .6),
          (_throwAt - .545, _throwAt + .75),
        ];

  double get _windStart => _throwAt - .34;
  double get _whipStart => _throwAt - .06;
  static const _wingHeld = -.9, _wingCoil = -1.0, _wingThrown = .9;

  bool get _hasAnkh => ankhs.isNotEmpty;

  /// The wing channel at cycle time [t]. A held pose is a blend of the idle
  /// wingbeat into the pose (never a switch), and the throw is its own track.
  double wingAt(double t) {
    final idle = _idleWing(t);
    var wv = idle;
    // mail call: the wing swings to the deal (with a springy settle: the
    // spring's overshoot is the swing's follow-through), drops to its holding
    // angle, and goes back to the idle beat once the hand has come home.
    // Each beat blends from what the wing is doing (the faster clock's
    // second call comes while the ankh's throw settles)
    for (final d in calls) {
      final lock = d.lock, lastRel = _lastReleaseOf(d);
      if (t >= lock && t < lastRel + .5 + .5) {
        final up = reduced ? _e(t, lock, .3) : _spring(t - lock, 13, .62);
        final env = up * (1 - _e5(t, lastRel + .5, .5));
        final held = _lerp(.9, .45, _e(t, lock + .4, .3));
        wv = wv + (held - wv) * env;
      }
    }
    // the ankh: the wing rises with it, trembles as the magic gathers, coils
    // back and WHIPS
    if (_hasAnkh && t >= _ankhLock && t < _throwAt + .4 + .5) {
      final tremble = reduced ? 0.0 : .035 * math.sin(t * 17) * _e(t, _ankhLock + .6, .8) * (1 - _e(t, _windStart, .2));
      double track;
      if (t < _windStart) {
        track = _wingHeld + tremble;
      } else if (t < _whipStart) {
        track = _lerp(_wingHeld, _wingCoil, _e5(t, _windStart, _whipStart - _windStart));
      } else {
        // the whip: a spring (the peak of its velocity falls on the release)
        final s = reduced ? _e(t, _whipStart, .3) : _spring(t - _whipStart, 22, .55);
        track = _lerp(_wingCoil, _wingThrown, s);
      }
      final up = _e5(t, _ankhLock, .4);
      final env = up * (1 - _e5(t, _throwAt + .4, .5));
      wv = wv + (track - wv) * env;
    }
    // the catch (closing round, N3): the wing tucks for a beat as the ankh lands in the hand
    // (the faster clock: not when a deal swings the wing out at the same moment)
    if (!reduced) {
      for (final (c, home) in _homes(t)) {
        if (_dealAtCatch(home - (c - t))) continue;
        wv -= .30 * _bump(c, home - .06, home + .32);
      }
    }
    return wv;
  }

  /// Whether a deal of the faster clock begins within the wing's catch tuck
  /// of an ankh home at [home] (this cycle's time): its swing then takes the
  /// wing, and the tuck is left out (a whole tuck, decided by the clock's
  /// beats, so nothing pops; the next cycle's first call counts too, so a
  /// catch read on both sides of a cycle's join is decided the same way).
  bool _dealAtCatch(double home) {
    if (!beats.isFaster) return false;
    bool near(double lock) => lock > home - .5 && lock < home + .5;
    if (near(beats.period + beats.mailLockAt)) return true;
    for (final d in calls) {
      if (near(d.lock)) return true;
    }
    return false;
  }

  /// The catch windows to read at cycle time [t]: this cycle's homecoming,
  /// and the previous cycle's read one cycle on (its tail may run into this
  /// cycle's first frames on a very wide screen).
  List<(double, double)> _homes(double t) => [
    if (ankhHome case final home?) (t, home),
    if (previousHome case final home?) (t + beats.period, home),
  ];

  // ------------------------------------------------------------ the pose --

  /// The pose the clock gives the rig at [ct].
  NeferhooPose pose({double unwrap = 0}) {
    final ph = phase;
    final p = NeferhooPose(phase: ph, unwrap: unwrap, fury: fury ? 1 : 0, cracked: fury ? 1 : 0, glow: fury ? .8 : 0, reduced: reduced);
    final r = reduced;
    final home = ankhHome;

    // ---- the wing, with its real velocity ------------------------------------
    p.wing = wingAt(ct);
    // (the secant over +-40 ms: the same as cos for the idle beat to half a percent,
    // and smooth through the spring's start and the whip)
    const h = .04;
    final vel = (wingAt(ct + h) - wingAt(ct - h)) / (2 * h);
    p.wingRate = r ? 0 : (vel / (.55 * NeferhooPose.wingBeat)).clamp(-1.0, 1.0);

    // ---- calm acting: the resting face and body (M2) -------------------------
    final breath = r ? 0.0 : math.sin(ph * 1.6);
    final plan = gagPlan;
    final blink = r ? 0.0 : _blink(ph, ct, !fury && plan.active ? plan.start + plan.wipeEnd + .033 : null, _keep, _gagEnd);
    // proud (chin up, chest out, a relaxed lid, brows lifted); fury leans in and glares
    var lean = fury ? -.03 : .05;
    var tilt = fury ? -.05 : .07;
    var lidBase = fury ? 0.0 : .22;
    var brow = fury ? -.8 : .30;
    var look = r ? (fury ? const Offset(-.8, .08) : const Offset(-.5, .05)) : (fury ? Offset(-.85 + .1 * math.sin(ph * .9), .08) : _gaze(ph));
    final restCrest = (fury ? .6 : .4) + (r ? 0 : .02 * math.sin(ph * 2.3));
    var crest = restCrest;
    var smile = 0.0;
    lean += .012 * breath;
    tilt += r ? 0 : .02 * math.sin(ph * 2.1 + 1.2);
    var glow = fury ? .8 : 0.0;

    // ---- the faster clock: he watches the ankh come back (the previous cycle's
    // into this one's first second on a wide screen) BEFORE the deals, which
    // blend from it: its second call comes as the ankh comes home and the
    // first call of the next cycle as it lands, and the watch's settle must
    // not override a deal's crest (nor end in a jump at the cycle's join)
    if (beats.isFaster) {
      if (previousAnkhs.isNotEmpty) {
        (look, crest) = _watch(look, crest, restCrest, previousAnkhs, ct + beats.period, previousHome);
      }
      (look, crest) = _watch(look, crest, restCrest, ankhs, ct, home);
    }

    // ---- mail call: open the satchel, fan the letters, flick them one by one --
    // (each call of the cycle in lock order; the faster clock's calls can
    // overlap at a cycle's join, where the earlier one has let go already)
    for (final d in calls) {
      final lock = d.lock, release = d.release;
      final lastRel = _lastReleaseOf(d), mailEnd = _mailEndOf(d);
      // (the brow's flash begins .05 s before the lock: the faster clock
      // plays it from there, so it never starts with a step)
      if (ct < lock - (beats.isFaster ? .05 : 0) || ct >= mailEnd + 1) continue;
      final inn = _e(ct, lock, .22); // the weight of "dealing"
      final out = 1 - _e(ct, lastRel + .25, .5); // ...fading as the last letter is away
      final deal = inn * out;
      // the brow flashes up (attention!) a beat before it settles into concentration
      brow = _lerp(brow, fury ? -.6 : -.4, deal) + (r ? 0.0 : .4 * _bump(ct, lock - .05, lock + .3));
      // his glance drops to the satchel as it opens, then comes back up to the bird
      final gl = _lerpO(const Offset(.35, .75), const Offset(-1, .1), _e(ct, lock + .3, .45));
      look = _lerpO(look, gl, deal);
      // the crest stays folded through the deal: a small lift as the satchel opens
      crest = _lerp(crest, math.max(crest, .4 + .06 * _e(ct, lock, .35)), deal);
      lidBase = _lerp(lidBase, fury ? 0 : .14, deal); // eyes a touch wider to count the letters
      // (the satchel and the hand)
      final open = ct < release ? _e(ct, lock, .4) : 1 - _e(ct, mailEnd - .35, .35);
      p.satchelOpen = math.max(p.satchelOpen, open);
      p.cards = math.min(cardsInHand, 2);
      // the wing swings to the deal point once it is clear of its idle beat (the art's
      // swing keeps one direction while the wing is down), holds the fan in its
      // fingers until the last letter is away, then comes home
      p.reach = math.max(p.reach, _ramp(ct, lock + .14, lock + .5) * (1 - _ramp(ct, lastRel + .05, lastRel + .5)));
      // the mask catches the light as the lane locks
      final g = _ramp(ct, lock, lock + .7);
      if (g > 0 && g < 1) p.glint = g;
      // a flick at each release: the letter goes, the body gives a little, the brow lifts
      var sweep = 0.0;
      for (var k = 0; k < d.count; k++) {
        final rel = release + k * _gapOf(d);
        final dd = ct - rel;
        if (dd > -.12 && dd < .22) sweep = math.max(sweep, math.sin(((dd + .12) / .34) * math.pi));
      }
      p.sweep = math.max(p.sweep, sweep);
      crest += .2 * sweep;
      brow += .22 * sweep;
      // (no lean here: the body is rigid; a nod is cheaper and reads better)
      tilt -= .03 * sweep; // a little nod with each letter that leaves
    }

    // ---- the ankh: it rises, glows and spins up over his wing; a big sweep throws it
    if (_hasAnkh && ct >= _ankhLock && ct < _throwAt + 1.2) {
      final rise = _e(ct, _ankhLock, .5);
      final settle = 1 - _e(ct, _throwAt + .3, .5); // the glare relaxes after the throw
      final live = _e(ct, _ankhLock, .25) * settle;
      p.ankh = ct < _throwAt ? rise : 0;
      p.ankhSpin = ct < _throwAt ? math.sin(ct * 3) * .3 + _ramp(ct, _throwAt - .6, _throwAt) * 6 : 0;
      // the fan opens with the ankh's rise; the whip snaps it back and it relaxes
      final fanned = _lerp(crest, 1.0, rise);
      final thrown = _lerp(1.0, .62, _e(ct, _throwAt - .04, .22));
      crest = ct < _throwAt - .04 ? fanned : _lerp(thrown, .6, _e(ct, _throwAt + .3, .5));
      glow = math.max(glow, rise * .9 * (1 - _e(ct, _throwAt + .1, .35)));
      final g = _ramp(ct, _ankhLock, _ankhLock + .7);
      if (g < 1) p.glint = g;
      brow = _lerp(brow, -.7, live);
      // he looks up at the ankh as it forms, then fixes the bird: he is aiming
      final aim = _lerpO(const Offset(.35, -.8), const Offset(-1, .12), _e(ct, _ankhLock + .3, .5));
      look = _lerpO(look, aim, live);
      lidBase = _lerp(lidBase, 0, live);
      // the body: chest out as it rises, coiled back with the wing, then the lunge
      final wind = _e5(ct, _windStart, _whipStart - _windStart);
      final sweep = .5 * wind * (1 - _e(ct, _whipStart, .14));
      final chest = rise * (1 - _e5(ct, _throwAt - .12, .3));
      final lunge = _e5(ct, _throwAt - .08, .3) * (1 - _e5(ct, _throwAt + .35, .6));
      lean += .05 * chest + .05 * wind * (1 - _e5(ct, _whipStart, .16)) - .10 * lunge;
      tilt += .05 * chest - .12 * lunge;
      p.sweep = math.max(p.sweep, sweep);
    }

    // ---- he watches the ankh come back and catches it --------------------------
    if (!beats.isFaster) {
      (look, crest) = _watch(look, crest, restCrest, ankhs, ct, home);
    }

    // ---- the catch (closing round, N3): a hand reach, a settle, a gleam, a smile -----------
    // (the wing's tuck is in `wingAt`.) Each window is also read one cycle on, so a late
    // homecoming on a very wide screen carries into the next cycle's first frames.
    if (!r) {
      for (final (c, home) in _homes(ct)) {
        if (c < home - .15 || c > home + .9) continue;
        // a lift of the brow and a pleased little smile, held until the gag begins
        final hold = _e(c, home - .05, .15) * (1 - _e(c, home + .55, .3));
        brow += .28 * hold;
        smile = math.max(smile, (fury ? 0 : .5) * hold);
        // the near hand splays and settles as the ankh lands in it
        p.sweep = math.max(p.sweep, .55 * _bump(c, home - .12, home + .24));
        // calm: a tiny gleam on the mask (not a glow: the ring turns teal for `glow`, and teal means "not now")
        if (!fury) {
          final gl = _ramp(c, home - .02, home + .30);
          if (gl > 0 && gl < 1) p.glint = gl;
        }
      }
    }

    // ---- the open sky: he buffs his own postmark (review 08 M4; re-staged: closing round N1, N6) ----
    // `plan` fits it to the room left after the ankh is home (the part after the wipe is
    // time-scaled, the wipes drop to one and then to none on a wide screen); fury is ONE
    // brisk, irritated wipe and a glare
    final g0 = plan.start;
    if (ct >= g0 && plan.active && !r) {
      final g = ct - g0;
      final u = plan.script(g);
      final tIn = plan.tIn, wipeEnd = plan.wipeEnd;
      // buff: the wingtip arrives, stays for the wipes, goes home (real time: the wipe is at 3 Hz)
      p.buff = plan.wipes == 0 ? 0 : _e5(g, 0, tIn) * (1 - _e5(g, wipeEnd, tIn));
      // he notices a smudge: the gaze drops to the pad, the head dips, the lid narrows
      final notice = _e(g, 0, .3) * (1 - _e(u, wipeEnd + .1, .3));
      look = _lerpO(look, const Offset(-.1, 1.0), notice);
      tilt = _lerp(tilt, tilt - .10, notice);
      lean = _lerp(lean, lean - .03, notice);
      lidBase = _lerp(lidBase, fury ? .1 : .34, notice);
      brow = _lerp(brow, fury ? -.55 : -.1, notice);
      // a nod with each wipe: the body goes with the wing
      final wipe = plan.wipes == 0 ? 0.0 : math.sin(2 * math.pi * 3 * ph) * p.buff * _e(g, tIn, .1) * (1 - _e(g, wipeEnd - .05, .1));
      lean += (fury ? .014 : .008) * wipe;
      // the pad glints as the wing leaves it
      // (the RING's own gleam; the mask's `glint` belongs to the locks and to the glance below)
      final gl = _ramp(u, wipeEnd + .1, wipeEnd + .5);
      if (gl > 0 && gl < 1) p.ringGlint = gl;
      // squint at it...
      final squint = _bump(u, wipeEnd + .06, wipeEnd + .7);
      lidBase = _lerp(lidBase, fury ? .3 : .5, squint);
      brow = _lerp(brow, fury ? -.75 : -.3, squint);
      look = _lerpO(look, const Offset(-.25, .95), squint);
      lean = _lerp(lean, lean - .02, squint);
      // ...then the brow lifts and the gaze slides to the bird: "are you watching?"
      final fin = _e(u, wipeEnd + .34, .4) * (1 - _e(u, plan.end - .3, .3));
      if (!fury) {
        brow = _lerp(brow, .58, fin);
        lidBase = _lerp(lidBase, .12, fin);
        smile = math.max(smile, .3 * fin);
        tilt += .11 * fin; // chin up at the player
        lean += .02 * fin;
        // the smug slow blink after the glance, then the mask catches the light: a "ting"
        final slow = _bump(u, wipeEnd + .40, wipeEnd + .76);
        lidBase = _lerp(lidBase, .9, slow);
        final tingEnd = math.min(wipeEnd + .97, plan.end - .03); // (never cut off by the cycle's end)
        final ting = tingEnd > wipeEnd + .55 ? _ramp(u, wipeEnd + .5, tingEnd) : 0.0;
        if (ting > 0 && ting < 1) p.glint = ting;
      } else {
        // a glare instead of the glance, and an irritated flick of the crest after the wipe
        brow = _lerp(brow, -.9, fin);
        crest += .24 * _bump(u, wipeEnd + .04, wipeEnd + .62);
      }
      look = _lerpO(look, const Offset(-1, .0), fin);
    }

    // ---- the stage-up roar (rules 44's shared 1.4 s roar; not in the design's
    // timeline, which predates the stages): the crest fans, HOO-POO-POO in three
    // beak pulses, he rears back and glares at the bird, his magic glows. Eased in
    // and out, so nothing pops; under Reduced Motion only the states show.
    if (roarAt case final at? when ct >= at && ct < at + roarLength) {
      final t = ct - at;
      final env = _e(t, 0, .3) * (1 - _e(t, roarLength - .45, .45));
      crest = _lerp(crest, 1.0, env);
      brow = _lerp(brow, -.6, env);
      glow = math.max(glow, .8 * env);
      look = _lerpO(look, const Offset(-1, .05), env);
      lidBase = _lerp(lidBase, 0, env);
      if (!r) {
        // the beak opens on the cue's own syllables: HOO-POO-POO (hoots at
        // +.02/.17/.32 s, .15 s each, as in the arrival) into the full fight,
        // fury's cry in two phrases (0-.52 and .6-.88 s)
        p.beak = furyRoar ? .9 * math.max(_bump(t, 0, .52), .85 * _bump(t, .6, .88)) : .9 * roarSyllables(t);
        lean += .10 * env;
        tilt += .08 * env;
      } else {
        p.beak = .5 * env;
      }
    }

    p.lean = lean;
    p.headTilt = tilt;
    // the lid: the relaxed lid, and a blink closes it all the way
    p.lid = lidBase + (1 - lidBase) * blink;
    p.brow = brow;
    p.look = look;
    p.crest = crest.clamp(0.0, 1.0);
    p.smile = smile;
    p.glow = glow;
    return p;
  }

  /// The watch beat: from just after the throw until the catch's end his
  /// eye follows the ankhs [flights] (cycle time [c], home at [home]) and his
  /// crest lifts, then settles back to [restCrest] after the catch.
  (Offset, double) _watch(Offset look, double crest, double restCrest, List<NeferhooFlight> flights, double c, double? home) {
    if (home == null || c < _throwAt + .2 || c >= home + .9) return (look, crest);
    final watch = _e(c, _throwAt + .2, .3) * (1 - _e(c, home - .2, .5));
    look = _lerpO(look, _ankhGaze(flights, c), watch);
    crest = _lerp(crest, math.max(.6, crest), watch);
    // the crest settles back to rest after the catch
    crest = _lerp(crest, restCrest, _e(c, home - .05, .7));
    return (look, crest);
  }

  // ------------------------------------------------- from the real boss --

  static NeferhooTimeline _fromBoss(SkyBoss boss, bool reduced, double age, bool fury) {
    final raw = age - boss.arrivalDuration;
    final combat = raw.isFinite ? math.max(0.0, raw) : 0.0;
    final beats = boss.neferhooBeats;
    final ct = beats.cycleTime(combat);
    final cycleStart = boss.arrivalDuration + combat - ct; // this cycle's start, in boss age
    final fight = boss.neferhoo;
    return NeferhooTimeline(
      ct: ct,
      phase: combat,
      bx: boss.x,
      // (held at the bob's centre under Reduced Motion, as the rig is drawn)
      by: reduced ? Neferhoo.hoverY(0) : boss.y,
      express: expressOf(boss, cycleStart),
      fury: fury,
      ankhs: [
        for (final a in fight.ankhs)
          if (a.lockedAt >= cycleStart - 1e-9 && a.lockedAt < cycleStart + beats.period) NeferhooFlight.of(a, cycleStart),
      ],
      previousHome: _previousHome(boss, cycleStart, beats.period),
      reduced: reduced,
      roarAt: _roarAt(boss, cycleStart, beats.period),
      beats: beats,
      deals: beats.isFaster ? fasterCalls(boss, cycleStart, combat) : null,
      previousAnkhs: !beats.isFaster
          ? const []
          : [
              for (final a in fight.ankhs)
                if (a.lockedAt >= cycleStart - beats.period - 1e-9 && a.lockedAt < cycleStart - 1e-9) NeferhooFlight.of(a, cycleStart - beats.period),
            ],
      furyRoar: boss.stageReached >= 2,
      // the rules' fan while he fights; a pose held at another moment (the
      // one he died in) reads the clock
      inHand: age == boss.age && boss.phase == BossPhase.attacking ? boss.lettersInHand : null,
    );
  }

  /// Whether this cycle's mail call is the express post: the rules latch it
  /// at the lock ([NeferhooFight.express], [NeferhooFight.mailLockedAt]).
  /// Before this cycle's lock it is what the lock will latch: fury
  /// ([SkyBoss.enraged]) now (the rules latch `enraged` at that instant).
  static bool expressOf(SkyBoss boss, double cycleStart) {
    final fight = boss.neferhoo;
    if (fight.mailLockedAt >= cycleStart - 1e-9) return fight.express;
    return boss.enraged;
  }

  /// The faster fight's mail calls (rules 55) in the time of the cycle that
  /// began at boss age [cycleStart] (combat time [combat] now): the ones the
  /// rules latched from the previous cycle's start on (a previous second
  /// call's deal runs into this cycle), and this cycle's still to come on
  /// the clock (the first call; the second when the ankh runs this cycle),
  /// as the rules will latch them (the express post: fury now).
  static List<NeferhooDeal> fasterCalls(SkyBoss boss, double cycleStart, double combat) {
    final beats = boss.neferhooBeats;
    final fight = boss.neferhoo;
    final deals = <NeferhooDeal>[
      for (final c in fight.calls)
        if (!c.wave && c.lockedAt >= cycleStart - beats.period - 1e-9 && c.lockedAt < cycleStart + beats.period - 1e-9)
          (lock: c.lockedAt - cycleStart, release: c.lockedAt - cycleStart + Neferhoo.windupSeconds, express: c.express, count: c.letters),
    ];
    final cycle = beats.cycleNumber(combat);
    for (final (at, kind) in beats.callMoments) {
      if (kind == NeferhooCallKind.wave) continue;
      if (kind == NeferhooCallKind.second && !boss.signatureArmed(cycle)) continue;
      if (deals.any((d) => (d.lock - at).abs() < 1e-6)) continue;
      final express = boss.enraged;
      deals.add((lock: at, release: at + Neferhoo.windupSeconds, express: express, count: Neferhoo.streamCount(fury: express)));
    }
    deals.sort((a, b) => a.lock.compareTo(b.lock));
    return deals;
  }

  static double? _previousHome(SkyBoss boss, double cycleStart, double period) {
    final from = cycleStart - period;
    final flights = [
      for (final a in boss.neferhoo.ankhs)
        if (a.lockedAt >= from - 1e-9 && a.lockedAt < cycleStart - 1e-9) NeferhooFlight.of(a, from),
    ];
    if (flights.isEmpty) return null;
    final hand = boss.x - Neferhoo.handOffset, turn = Neferhoo.turnX(FlightSimulation.birdX);
    return flights.map((f) => f.home(hand, turn)).reduce(math.max);
  }

  static double? _roarAt(SkyBoss boss, double cycleStart, double period) {
    if (!boss.staged || boss.stageReached == 0) return null;
    final at = boss.stageUpAt - cycleStart;
    if (!at.isFinite || at > period) return null;
    // a roar begun in the previous cycle is read in this cycle's time (negative)
    return at;
  }
}

/// One mail call as the timeline acts it, in a cycle's time: its lock, its
/// first letter, whether it is the express post, and its letters.
typedef NeferhooDeal = ({double lock, double release, bool express, int count});

/// One ankh's flight in a cycle's time: what the timeline reads of a
/// [NeferhooAnkh] the rules latched.
class NeferhooFlight {
  const NeferhooFlight({required this.laneA, required this.laneB, required this.throwAt, required this.speed});

  /// [ankh] in the time of the cycle that began at boss age [cycleStart].
  factory NeferhooFlight.of(NeferhooAnkh ankh, double cycleStart) => NeferhooFlight(
    laneA: ankh.laneA,
    laneB: ankh.laneB,
    throwAt: ankh.thrownAt - cycleStart,
    speed: ankh.speed,
  );

  final double laneA, laneB, throwAt, speed;

  /// The whole loop's length (the rules' [NeferhooAnkh.length]).
  double length(double handX, double turnX) => (handX - turnX) * 2 + math.pi * (laneB - laneA).abs() / 2;

  /// When it is home (cycle time).
  double home(double handX, double turnX) => throwAt + length(handX, turnX) / speed;

  /// Where it is [s] along its loop (the rules' [NeferhooAnkh.at]).
  Offset at(double s, double handX, double turnX) {
    final out = handX - turnX, r = (laneB - laneA).abs() / 2;
    final arc = math.pi * r;
    if (s <= out) return Offset(handX - s, laneA);
    if (s <= out + arc) {
      final a = (s - out) / r;
      final mid = (laneA + laneB) / 2;
      final sign = laneB > laneA ? 1 : -1;
      return Offset(turnX - r * math.sin(a), mid - sign * r * math.cos(a));
    }
    return Offset(turnX + (s - out - arc), laneB);
  }
}

/// The open-sky gag laid out for the room left in the cycle (see
/// [NeferhooTimeline.gagPlan]).
class GagPlan {
  const GagPlan(this.start, this.room, this.wipes, this.tIn, this.wipeEnd, this.kf, this.active);

  /// The script after the wipe (the squint, the ring's star, the glance, the slow blink, the ting), seconds.
  static const finale = 1.083;

  final double start, room, tIn, wipeEnd, kf;

  /// 0, 1 or 2 wipes at 3 Hz (0: no wing at all).
  final int wipes;

  /// False when there is not even half a second left (a very wide screen).
  final bool active;

  /// Script time of the real time [g] since the start: the wipe plays at real speed, the rest at `kf`.
  double script(double g) => g <= wipeEnd ? g : wipeEnd + (g - wipeEnd) / kf;

  /// Script time at the cycle's end.
  double get end => wipeEnd + (room - wipeEnd) / kf;
}

// ---------------------------------------------------------------------------
// the motion toolkit (the design's): everything below is a pure function of time

/// 0..1 smoothstep from [t0] over [d] seconds.
double _e(double t, double t0, double d) => NeferhooKit.smooth01((t - t0) / d);

/// Smoother (zero slope AND zero curvature at both ends): the big, slow moves.
double _e5(double t, double t0, double d) {
  final x = ((t - t0) / d).clamp(0.0, 1.0);
  return x * x * x * (x * (x * 6 - 15) + 10);
}

double _ramp(double v, double a, double b) => NeferhooKit.ramp(v, a, b);
double _lerp(double a, double b, double t) => a + (b - a) * t;
Offset _lerpO(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

/// 0..1..0 bell (sin squared: zero slope at both ends) over [t0, t1].
double _bump(double t, double t0, double t1) {
  if (t <= t0 || t >= t1) return 0;
  final s = math.sin((t - t0) / (t1 - t0) * math.pi);
  return s * s;
}

/// The step response of a damped spring ([tau] seconds after the step): rises
/// from 0 with zero velocity, passes 1 by exp(-pi zeta / sqrt(1 - zeta^2)) and
/// settles. Overshoot and settle for free.
double _spring(double tau, double omega, double zeta) {
  if (tau <= 0) return 0;
  final k = math.sqrt(1 - zeta * zeta);
  final wd = omega * k;
  return 1 - math.exp(-zeta * omega * tau) * (math.cos(wd * tau) + zeta / k * math.sin(wd * tau));
}

/// A blink from the clock: a 75 ms close and a 120 ms open every 3.7 s of
/// [ph]; every third one is a double blink (a second 0.3 s later). The clock
/// is free-running, so over the cycles a blink would land on every beat of
/// the 12 s fight; a blink that WOULD overlap one of the moments the player
/// reads is handed to the end of that moment instead (a whole event, decided
/// by where it starts, so nothing ever pops): the mail call's lock and first
/// letter, the ankh's lock, the throw with its wind-up, whip and catch and,
/// in calm, the gag's finale (its own slow blink and the glance at the
/// player). [ct] is the cycle time of [ph].
double _blink(double ph, double ct, double? finaleFrom, List<(double, double)> keep, double gagEnd) {
  final off = ct - ph;
  double v = 0;
  for (var n = ((ph - 2.5) / 3.7).floor(); n <= (ph / 3.7).floor(); n++) {
    for (final s in n % 3 == 2 ? const [0.0, .30] : const [0.0]) {
      final d = ct - _dock(off + n * 3.7 + s, finaleFrom, keep, gagEnd);
      if (d <= 0 || d >= .195) continue;
      v = math.max(v, d < .075 ? NeferhooKit.smooth01(d / .075) : 1 - NeferhooKit.smooth01((d - .075) / .12));
    }
  }
  return v;
}

/// Where a blink that would START at cycle time [c0] really starts: a blink
/// lasts .195 s, so none may start in (lock - .2 - .195 ... end of the
/// moment). [finaleFrom] is when the calm gag's finale (its slow blink and
/// the glance) begins, if there is one.
double _dock(double c0, double? finaleFrom, List<(double, double)> keep, double gagEnd) {
  // (a blink handed to the end of one moment that falls in another moves on)
  for (var moved = true; moved;) {
    moved = false;
    for (final (a, b) in keep) {
      if (c0 > a && c0 < b) {
        c0 = b;
        moved = true;
      }
    }
  }
  final end = gagEnd - .2; // calm: the gag's finale; a displaced blink ends before the cycle does
  if (finaleFrom != null && c0 > finaleFrom - .195 && c0 < end) return end;
  return c0;
}

/// The moments a blink keeps off ([_dock]), cycle seconds: the classic
/// clock's mail lock and first letter, ankh lock, and throw to catch.
const _classicKeep = [(.205, 1.85), (5.005, 6.0), (6.255, 7.55)];

/// Where a calm gaze rests: a thought held for 2.4 s, then a quick glance on
/// (the player, the player, the player, the satchel, the player, the sky...).
const _gazes = <Offset>[Offset(-.5, .05), Offset(-.75, .18), Offset(-.35, -.05), Offset(.30, .65), Offset(-.62, .10), Offset(-.22, -.55), Offset(-.70, .05)];
Offset _gaze(double ph) {
  const seg = 2.4;
  final n = (ph / seg).floor();
  final u = _e(ph - n * seg, 0, .22);
  return _lerpO(_gazes[((n - 1) % 7 + 7) % 7], _gazes[n % 7], u);
}

/// The ankh's hover point over his shoulder (screen fractions), for a chest
/// at ([bx], [by]): where the flying ankh's first [NeferhooTimeline.ankhEase]
/// seconds blend from.
Offset neferhooAnkhHover(double bx, double by) =>
    Offset(bx + NeferhooLayout.ankhHover.dx * SkyBoss.radius, by + NeferhooLayout.ankhHover.dy * SkyBoss.radius);
