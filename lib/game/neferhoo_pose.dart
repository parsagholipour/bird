import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';
import 'neferhoo_timeline.dart';

/// Every channel Neferhoo's art reads: the design's `MummyPose`, ported 1:1
/// (`egypt-ws/iter5/test/egypt/mummy_rig.dart`; every name and default is the
/// design's). Pure data: in the fight [NeferhooPose.fight] sets it from the
/// boss's clock and the rules' latches (`NeferhooTimeline`); the arrival, the
/// defeat and the story build their own.
class NeferhooPose {
  NeferhooPose({
    this.crest = .35,
    this.wing = 0,
    this.lean = 0,
    this.beak = 0,
    this.lid = 0,
    this.brow = 0,
    this.look = Offset.zero,
    this.fury = 0,
    this.unwrap = 0,
    this.mask = true,
    this.satchelOpen = 0,
    this.cards = 0,
    this.cardSpread = 1,
    this.ankh = 0,
    this.ankhSpin = 0,
    this.sweep = 0,
    this.hit = 0,
    this.phase = 0,
    this.stamp = 0,
    this.glow = 0,
    this.specs = false,
    this.cracked = 0,
    this.legs = 0,
    this.ribbons = 1,
    this.sleepy = 0,
    this.smile = 0,
    this.headTilt = 0,
    this.prop,
    this.reach = 0,
    this.sad = 0,
    this.glint = -1,
    this.specsUp = 0,
    this.satchelFull = 1,
    this.wingRate,
    this.reduced = false,
    this.buff = 0,
    this.ringGlint = -1,
  });
  /// The pose of [boss] now, in the fight: the rules' clock and what they
  /// latched (the mail call's lane, the letters, the ankhs), eased by the
  /// design's timeline ([NeferhooTimeline]); [lookY] is where the bird is
  /// relative to him (screen heights x 3, as the other rigs take it). Under
  /// Reduced Motion ([BossMotion.reducedMotion]) the clocks freeze and the
  /// states stay ([frozen]).
  factory NeferhooPose.fight(SkyBoss boss, BossMotion m, {double lookY = 0}) =>
      NeferhooTimeline.poseOf(boss, m, lookY: lookY);


  double crest, wing, lean, beak, lid, brow, fury, unwrap;
  Offset look;
  bool mask;
  double satchelOpen;
  int cards;
  double cardSpread, ankh, ankhSpin, sweep, hit, phase, stamp, glow;
  bool specs;
  double cracked, legs, ribbons, sleepy, smile, headTilt;
  String? prop; // story props: 'letter' (the lost letter), 'cap'

  /// 0..1: the near wing reaches forward and down, its splayed primaries
  /// holding the fan of letters (or the lost letter) like fingers.
  double reach;

  /// 0..1: the sad face (drooping lid, corner low, brow tilted up at the
  /// front, mouth crease down). Explicit, so a sleepy hero is not a sad one.
  double sad;

  /// The gold's gleam: -1 = the idle sheen (a pure function of [phase]),
  /// 0..1 = an event gleam at that position of its sweep (mail lock, ankh
  /// lock, the arrival's reveal), which also silences the idle one.
  double glint;

  /// The postmark ring's own gleam (the open-sky gag's shine): -1 = none, 0..1 = where it is on
  /// its sweep. Separate from [glint] (the MASK's gleam at the mail lock, the ankh lock and the
  /// reveal) so the two never fight: a lock never makes the ring gleam, the gag never fires the
  /// lock's mask gleam at the wrong moment.
  double ringGlint;

  /// 0..1: the spectacles pushed up onto the forehead (bare head only).
  double specsUp;

  /// 0..1: how full the satchel is (1 = the dead letters peek out, 0 = empty:
  /// the defeat has scattered them).
  double satchelFull;

  /// The wing stroke's velocity, -1..1 (the cosine of the idle beat), which
  /// the feather tips, the tail and the streamers lag behind. null = derive
  /// it from [phase] with the idle beat; 0 = a held pose (no lag).
  double? wingRate;

  /// Reduced Motion: wingbeat, flutters, glints, motes, sway and bob freeze
  /// (the pose's states stay: fan, ankh raised, stamp, unwrap, crack, glow).
  bool reduced;

  /// 0..1: the open-sky gag (review 08 M4): the near wingtip buffs the chest
  /// postmark. 0 = not buffing; the timeline drives the wipe cycle through
  /// [phase] while it is above 0, the wing reads it for the wingtip's path
  /// and the body for the ring's response (glint, a squeak of the pad).
  double buff;

  /// The idle wingbeat's angular speed (rad/s of [phase]): the timeline's
  /// `wing = sin(phase * wingBeat) * .55`. One copy, read by every part.
  static const wingBeat = 4.2;

  /// The wing-stroke velocity the parts lag behind (-1..1).
  double get stroke => wingRate ?? math.cos(phase * wingBeat);

  /// The same pose with every clock frozen (Reduced Motion): [phase] pinned
  /// to a calm value, no lag, no event gleam, hit flash capped at .12.
  NeferhooPose frozen() => copy(phase: .35, wingRate: 0, glint: -1, ringGlint: -1, hit: math.min(hit, .12), reduced: true);

  NeferhooPose copy({
    double? crest,
    double? wing,
    double? lean,
    double? beak,
    double? lid,
    double? brow,
    Offset? look,
    double? fury,
    double? unwrap,
    bool? mask,
    double? satchelOpen,
    int? cards,
    double? cardSpread,
    double? ankh,
    double? ankhSpin,
    double? sweep,
    double? hit,
    double? phase,
    double? stamp,
    double? glow,
    bool? specs,
    double? cracked,
    double? legs,
    double? ribbons,
    double? sleepy,
    double? smile,
    double? headTilt,
    String? prop,
    double? reach,
    double? sad,
    double? glint,
    double? ringGlint,
    double? specsUp,
    double? satchelFull,
    double? wingRate,
    bool? reduced,
    double? buff,
  }) => NeferhooPose(
    crest: crest ?? this.crest,
    wing: wing ?? this.wing,
    lean: lean ?? this.lean,
    beak: beak ?? this.beak,
    lid: lid ?? this.lid,
    brow: brow ?? this.brow,
    look: look ?? this.look,
    fury: fury ?? this.fury,
    unwrap: unwrap ?? this.unwrap,
    mask: mask ?? this.mask,
    satchelOpen: satchelOpen ?? this.satchelOpen,
    cards: cards ?? this.cards,
    cardSpread: cardSpread ?? this.cardSpread,
    ankh: ankh ?? this.ankh,
    ankhSpin: ankhSpin ?? this.ankhSpin,
    sweep: sweep ?? this.sweep,
    hit: hit ?? this.hit,
    phase: phase ?? this.phase,
    stamp: stamp ?? this.stamp,
    glow: glow ?? this.glow,
    specs: specs ?? this.specs,
    cracked: cracked ?? this.cracked,
    legs: legs ?? this.legs,
    ribbons: ribbons ?? this.ribbons,
    sleepy: sleepy ?? this.sleepy,
    smile: smile ?? this.smile,
    headTilt: headTilt ?? this.headTilt,
    prop: prop ?? this.prop,
    reach: reach ?? this.reach,
    sad: sad ?? this.sad,
    glint: glint ?? this.glint,
    ringGlint: ringGlint ?? this.ringGlint,
    specsUp: specsUp ?? this.specsUp,
    satchelFull: satchelFull ?? this.satchelFull,
    wingRate: wingRate ?? this.wingRate,
    reduced: reduced ?? this.reduced,
    buff: buff ?? this.buff,
  );
}
