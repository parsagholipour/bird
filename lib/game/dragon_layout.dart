import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// THE ONE SOURCE OF TRUTH for where the Ember Dragon's parts meet.
///
/// Every part (head, neck, torso, wings, tail, legs, heart, effects) is drawn
/// in the same frame, "rig units": 1 unit is the hit radius, the origin is the
/// heart (the hit circle), +x is toward the tail, +y is down, and the dragon
/// faces LEFT toward the bird. At 360 px of screen height one unit is
/// 41.4 px; the dragon stands about 7 units (290 px) tall.
///
/// Parts that share a seam read their numbers from here, so they line up by
/// construction. Nothing in this file paints. A builder may refine the SHAPE
/// of the part it owns, but must keep every number marked ANCHOR (a seam
/// somebody else depends on) and must keep the part inside [envelope].
///
/// The numbers were proven with black silhouettes at 250 px and 120 px in
/// every pose (see reports/00-bible/); do not "improve" an anchor without
/// re-running the envelope test.
abstract final class DragonLayout {
  // ---------------------------------------------------------------- frame --

  /// The hit circle's radius, in rig units. The rules own it; never change.
  static const hitRadius = 1.0;

  /// The heart: the origin. ANCHOR.
  static const heart = Offset.zero;

  /// Pixels per rig unit at 360 px of screen height (0.115 x 360).
  static const pxPerUnit = 41.4;

  // ------------------------------------------------------------- envelope --

  /// What is on screen in the WORST case at 640x360 and 800x360: the dragon
  /// anchors 0.5 screen heights (180 px = 4.35 units) from the right edge,
  /// and the rules bob it 0.07 h (25 px = 0.6 unit), so with the heart at
  /// its highest the top of the screen is at y = -3.74 and with it at its
  /// lowest the bottom is at y = +3.74. Left and elsewhere is open sky.
  static const visibleWorst = Rect.fromLTRB(-9, -3.74, 4.35, 3.74);

  /// The box every combat pose of every part must stay inside, including
  /// wing tips with claws, tail blade, horn tips, fury flames on the hems,
  /// the crown, and the whole-figure [DragonPose.bob] and pitch. ENVELOPE.
  ///
  /// The test `dragon_envelope_test.dart` sweeps every state x wing phase and
  /// fails when any part leaves it. (Defeat and arrival are exempt; see
  /// [layerBounds].) Round 2: the left edge went from -3.40 to -3.55: the
  /// low-lane strike carries the snout further out (the open sky to the left
  /// of the dragon is not screen-limited: at that reach the snout is still
  /// 235 px right of the bird), and the layer clip's -3.9 still holds it.
  static const envelope = Rect.fromLTRB(-3.55, -3.72, 4.30, 3.66);

  /// The calm idle pose (the Reduced Motion pose too) stays this far inside,
  /// so there is head-room for the beat, the bob and the sway.
  static const restEnvelope = Rect.fromLTRB(-2.90, -3.50, 4.22, 3.45);

  /// `DragonBossRig.bounds`: the clip of the silhouette / white-out / fade
  /// layers, generous enough for the arrival swell (x1.1), the defeat pitch
  /// and the tail's fall.
  static const layerBounds = Rect.fromLTRB(-4.0, -4.3, 4.9, 4.9);

  /// The health bar covers x < -0.9 above this y at its lowest, at the worst
  /// bob. Head, crown and horns may pass under it, but the eye and the mouth
  /// must never be under the bar.
  static const healthBarClearance = -3.07;

  // --------------------------------------------------------------- strokes --

  /// The line-weight hierarchy, in rig units (41 px each). Nothing thinner
  /// than [hair] is drawn: it is 1.2 px at phone size and only shimmers.
  /// Outer contours are modulated: full weight on the shade side (lower
  /// right), 0.7 on the lit side, via `DragonKit.inkHero`.
  static const inkHero = .105; // torso, head, neck, tail, wing membrane
  static const inkMajor = .08; // legs, wing arm, jaw, far-side shapes
  static const inkPart = .055; // horns, crown, spines, claws, teeth roots
  static const inkDetail = .04; // scale rows, seams, veins, lids
  static const hair = .03;

  // ------------------------------------------------------------ the torso --

  /// Closed Catmull-Rom outline of the torso, chest front-left, rump
  /// back-right, in the rest pose. ANCHOR: the extreme points (chest front
  /// -1.38, keel 1.62, rump 2.18, back line -0.66) are what the neck, legs,
  /// tail root and wing root are seated against. Detail inside is yours.
  /// Round 2 (design review D2, numbers from the head's measure on assembled
  /// pixels): points 0, 1, 2 and 13 came down by .24, .20, .12 and .16 (they
  /// were -.90, -.84, -.52 and -.46), so the neck shows about .25 more
  /// between the jaw and the chest; the hit circle still sits in the chest and
  /// the breastplate reads as a gorget on the neck's base. Round 3 (final
  /// design review): points 12 and 13, the chest's front shoulder, came
  /// (.07, .03) and (.07, .01) back and down (were (-1.34,.00), (-1.02,-.30)),
  /// so a jaw dropped over the chest has .07 more air under it.
  static const torsoOutline = <Offset>[
    Offset(-.35, -.66),
    Offset(.45, -.64),
    Offset(1.15, -.40),
    Offset(1.80, -.06),
    Offset(2.18, .48),
    Offset(2.10, 1.04),
    Offset(1.62, 1.24),
    Offset(1.06, 1.08),
    Offset(.36, 1.40),
    Offset(-.40, 1.62),
    Offset(-1.04, 1.30),
    Offset(-1.38, .66),
    Offset(-1.27, .03),
    Offset(-.95, -.29),
  ];

  /// The gem's socket, in the chest at the origin. The breastplate ring
  /// reaches [heartPlateRadius] (just inside the hit circle, so the gem and
  /// its plates ARE the target). ANCHOR for body + effects.
  static const heartSocketRadius = .46;
  static const heartGemRadius = .30;
  static const heartPlateRadius = .98;

  // ------------------------------------------------------------- the neck --

  /// The neck is one tapered tube along a cubic Bezier from [neckBase] (under
  /// the breastplate; no ink cap there) through [neckControl] and a control
  /// that leaves the skull's joint by [neckHandle] (in the head's frame), to
  /// the head's joint [DragonLayout.headNeckJoint]. ANCHOR.
  ///
  /// Round 3 (final design review, "sovereign silhouette"): a swan's S. The
  /// old controls ((.45,-.20), (-1.15,-.30), handle (1.05,.60)) put the bend
  /// under the breastplate, so what showed above the chest was a straight
  /// pillar. Now the neck leaves the chest forward and up (control
  /// (-1.45,-.60), so its throat edge grows out of the chest's front), leans
  /// back through the middle (the handle, (1.10,.55), pulls the last third
  /// back before the skull) and reaches forward again into the jaw: the
  /// throat edge is a long curve, concave under the chin, not a 90 degree
  /// corner.
  static const neckBase = Offset(.30, -.25);
  static const neckControl = Offset(-1.45, -.60);
  static const neckHandle = Offset(1.10, .55);

  /// Widths at the nine samples from base to skull. Never below .74, and .82
  /// at the skull (the head is 1.74 deep), so the head never sits on a stalk.
  /// ANCHOR.
  static const neckWidths = <double>[
    1.25, 1.02, .88, .80, .76, .74, .75, .78, .82, //
  ];

  /// The nine neck-spine samples for a head whose neck joint is at [joint]
  /// and whose skull is turned by [angle] (positive: snout down). [drag] is
  /// the neck's follow-through (DragonPose.neckDrag): the middle of the S
  /// lags behind a fast head.
  static List<Offset> neckSpine(
    Offset joint,
    double angle, {
    Offset drag = Offset.zero,
    double coil = 0,
  }) {
    final c = math.cos(angle), s = math.sin(angle);
    // turn(v, -angle)
    final back = Offset(
      neckHandle.dx * c + neckHandle.dy * s,
      -neckHandle.dx * s + neckHandle.dy * c,
    );
    final p1 = neckControl + drag * .6 + Offset(.16, 0) * coil;
    final p2 = joint + back + drag * .35;
    return [for (var i = 0; i <= 8; i++) _bezier(neckBase, p1, p2, joint, i / 8)];
  }

  // ------------------------------------------------------------- the head --

  /// The head is authored directly in rig units (scale 1.0) around the
  /// skull's centre, snout toward -x, and placed by `DragonPose.head`.
  static const headScale = 1.0;

  /// Where the skull's centre sits calm, and how it is turned (positive:
  /// snout down). ANCHOR: the pose animates from here.
  static const headRest = Offset(-.95, -2.00);
  static const headRestAngle = .16;

  /// Where the skull sits (and how it is turned) at the full snap of the
  /// breath, per lane of the band it burns: the strike drives the head down
  /// and forward at the band. Round 2 (design review D2): the middle and low
  /// heads came up and back, so the jaw no longer lands on the breastplate
  /// (chin to chest .00 in the low strike before, .39 now, .44 at the snap).
  /// Round 3 (final design review): the low strike still had only .39 to .44
  /// of air under the jaw (target .55). The mouth is where B5's jet leaves
  /// and B5's fairness test pins it (within 1 px of the burn band), so the
  /// low pose keeps round 2's mouth EXACTLY (at (-2.92,-.51) at the blast to
  /// .002) and turns the head about it: (-1.727,-1.602) at .50 rad instead of
  /// (-1.65,-1.48) at .40. The jaw is held by the head art at .86 rad below
  /// the horizontal whatever the head's turn, so a steeper head lifts the
  /// chin: chin to chest .62 at the blast, .68 at the snap, .69 at the thump
  /// (was .39, .44, .45). (Round 2's history: B1's (-1.70,-1.54, .34) moves
  /// the mouth and fails the fairness test; the old pose was
  /// (-1.30,-1.22, .52).)
  static const headHigh = Offset(-1.45, -2.10), headHighAngle = -.05;
  static const headMiddle = Offset(-1.55, -1.86), headMiddleAngle = .24;
  static const headLow = Offset(-1.727, -1.602), headLowAngle = .50;

  /// Where the skull sits with the fireball fully charged (charge = 1). It is
  /// derived from the rules' mouth: the jaws must open exactly at
  /// (-2.548, -1.870) = the rules' `dragonMouth` / 0.115. Do not touch.
  static const headCharge = Offset(-1.148, -2.160);
  static const headChargeAngle = .09;

  /// In the head's frame. ANCHOR (rig, arrival glint, falling crown and the
  /// flame read them):
  static const headMouth = Offset(-1.42, .163);
  static const headEye = Offset(-.46, -.33);
  static const headNostril = Offset(-1.34, -.26);
  static const headCrownSeat = Offset(.02, -.90);
  static const headCrownTurn = .12;
  static const headNeckJoint = Offset(.44, .32);
  static const headJawHinge = Offset(.26, .36);

  /// Box around the crown in its own frame (origin = seat).
  static const crownBounds = Rect.fromLTRB(-.6, -.52, .6, .26);

  /// The rules' mouth, in rig units, at full charge.
  static const rulesMouth = Offset(-.293 / .115, -.215 / .115);

  // ------------------------------------------------------------ the wings --

  /// Where the near wing's arm grows from (a shoulder plate of radius ~.5
  /// caps the root and covers the neck's back edge) and where the membrane's
  /// last panel meets the flank. ANCHOR.
  static const nearShoulder = Offset(.85, -.72);
  static const nearRoot = Offset(2.30, .40);

  /// The far wing is the near wing's key poses scaled, turned and pivoted
  /// about its own shoulder behind the neck's root; it beats a phase behind.
  static const farShoulder = Offset(.60, -.80);
  static const farScale = .88;
  static const farTilt = -.14;

  /// Guide for the thumb claw and the tip claws (allowance included in the
  /// keys below: the tips here are BONE tips, and a claw adds up to
  /// [clawAllowance] beyond them, already inside the envelope).
  static const thumbOffset = Offset(-.22, -.30);
  static const clawAllowance = .20;

  /// The wing's key poses: UP (stroke -1), MID (0), DOWN (+1) and FOLDED.
  /// (Round 2: the five right-most bone tips came in by .05, so the raised
  /// wing of the rear-back's body lean keeps clear of the envelope's right
  /// edge. Round 3, "10-12% more wing": the shoulder came down .13 (the arm
  /// grows from the back, not from above it), the right-most tips came in
  /// by .10 more (the fury snap kissed the frame: the body 3 px from the
  /// right, the wing tip 4 px from the top) and the trailing tips hang
  /// lower and further in, so the membrane is 10% larger in each of the
  /// three keys (up +10.8%, mid +10.1%, down +9.9%, measured as the polygon
  /// shoulder, elbow, wrist, four tips, root). Nothing grew toward the top or
  /// the right; the head test's arm clearance (calm .37, head-up .11) is why
  /// the shoulder did not also move toward the neck.)
  /// [elbow], [wrist] and four finger [tips] (lead finger first) are in rig
  /// units. Any stroke in [-1.2, 1.2] interpolates, per joint, so the wrist
  /// can lag the elbow and each finger lag the wrist. The envelope holds for
  /// every combination: this is what keeps the wing on screen.
  static const wingUp = DragonWingKey(Offset(1.55, -2.20), Offset(1.85, -2.85), [
    Offset(3.50, -3.30),
    Offset(3.75, -2.78),
    Offset(3.80, -1.45),
    Offset(3.20, -.30),
  ]);
  static const wingMid = DragonWingKey(Offset(1.80, -2.10), Offset(2.15, -2.50), [
    Offset(3.75, -3.10),
    Offset(3.80, -2.00),
    Offset(3.75, .05),
    Offset(3.20, 1.15),
  ]);
  static const wingDown = DragonWingKey(Offset(2.10, -1.20), Offset(2.50, -1.75), [
    Offset(3.80, -1.60),
    Offset(3.80, -.30),
    Offset(3.60, 1.40),
    Offset(3.10, 1.80),
  ]);
  static const wingFolded = DragonWingKey(Offset(1.40, -.55), Offset(1.55, -1.15), [
    Offset(3.00, -.90),
    Offset(3.10, -.50),
    Offset(3.00, -.10),
    Offset(2.60, .10),
  ]);

  /// One joint's position at [stroke] (-1 up .. 1 down), interpolating the
  /// three key poses, then folding toward [wingFolded] by [fold].
  static Offset wingJoint(
    Offset Function(DragonWingKey) pick,
    double stroke, {
    double fold = 0,
  }) {
    final s = stroke.clamp(-1.2, 1.2);
    final p = Offset.lerp(
      pick(wingMid),
      s < 0 ? pick(wingUp) : pick(wingDown),
      s.abs(),
    )!;
    return fold <= 0 ? p : Offset.lerp(p, pick(wingFolded), fold.clamp(0.0, 1.0))!;
  }

  /// The near wing's joints with an independent stroke for the [elbow], the
  /// [wrist] and each of the four [tips] (each in -1..1), so the wing can
  /// bend and whip. Missing tip strokes default to the wrist's.
  static DragonWingKey wingAt({
    required double elbow,
    double? wrist,
    List<double>? tips,
    double fold = 0,
  }) {
    final w = wrist ?? elbow;
    return DragonWingKey(
      wingJoint((k) => k.elbow, elbow, fold: fold),
      wingJoint((k) => k.wrist, w, fold: fold),
      [
        for (var i = 0; i < 4; i++)
          wingJoint((k) => k.tips[i], tips == null ? w : tips[i], fold: fold),
      ],
    );
  }

  /// The far wing's joints for a near wing pose [near].
  static DragonWingKey farOf(DragonWingKey near) {
    Offset f(Offset q) =>
        farShoulder + _turn((q - nearShoulder) * farScale, farTilt);
    return DragonWingKey(f(near.elbow), f(near.wrist), [
      for (final t in near.tips) f(t),
    ]);
  }

  /// The far wing's flank anchor.
  static Offset get farRoot =>
      farShoulder + _turn((nearRoot - nearShoulder) * farScale, farTilt);

  // ------------------------------------------------------ tail and hips --

  /// The tail's rest spine: a heavy root from the rump sweeping down and out,
  /// hooking back under itself, ending in the blade. ANCHOR: the root, and
  /// the blade must end inside the envelope with 0.3 of sway spare.
  /// Round 3 (final design review: "the tail tucks into the hind foot"): the
  /// last four points came in and up, from (3.15,1.48), (3.55,2.05),
  /// (3.62,2.50), (3.34,2.72) to (3.15,1.42), (3.50,1.84), (3.63,2.16),
  /// (3.50,2.36): the hook no longer swings back under the hind foot, it drops
  /// and ends in the blade (the art's own, along the last heading), .3 higher
  /// and clear of the foot; the art's lowest reach (the thump's whip) went
  /// from 3.63 to 3.46 against the envelope's 3.66.
  static const tailSpine = <Offset>[
    Offset(1.85, .75),
    Offset(2.55, 1.05),
    Offset(3.15, 1.42),
    Offset(3.50, 1.84),
    Offset(3.63, 2.16),
    Offset(3.50, 2.36),
  ];
  static const tailWidths = <double>[1.25, .96, .68, .44, .28, .16];

  /// The blade at the tail's end: length along the tail's last heading and
  /// half-width at its widest.
  static const tailBladeLength = .70;
  static const tailBladeHalfWidth = .40;

  // ----------------------------------------------------------------- legs --

  /// Hip / knee / ankle for the near hind leg (a digitigrade Z) and the near
  /// foreleg (reaching forward, claws out). Far legs are these shifted by
  /// [farLegShift] and painted in shade. ANCHOR: hip and shoulder sit inside
  /// the torso outline. (Round 2: the dead `hindWidths` / `foreWidths` are
  /// gone; the body art owns the limbs' widths, ten samples each.)
  static const hindLeg = <Offset>[Offset(1.55, .70), Offset(1.12, 1.52), Offset(1.78, 2.10)];
  static const hindFoot = Offset(.32, .12);
  static const foreLeg = <Offset>[Offset(-.80, .60), Offset(-1.18, 1.42), Offset(-1.86, 1.66)];
  static const foreFoot = Offset(-.34, .04);
  static const farLegShift = Offset(.28, -.10);

  // -------------------------------------------------------------- z-order --

  /// Back to front. The rig paints in this order; parts must not assume any
  /// other neighbour:
  ///  1 heat bloom (scene light)       7 neck, crest spines
  ///  2 far wing                       8 near wing (arm, shoulder plate)
  ///  3 far legs, tail                 9 breastplate + heart gem
  ///  4 torso, belly, back spines     10 head, horns, crown
  ///  5 near hind leg                 11 near foreleg
  ///  6 (reserved: tail sleeves)      12 nostril smoke
  static const zOrder = <String>[
    'bloom', 'farWing', 'farLegs+tail', 'torso', 'hindLeg', 'reserved', //
    'neck', 'nearWing', 'heart', 'head', 'foreleg', 'smoke',
  ];

  // ------------------------------------------------------------- helpers --

  static Offset _turn(Offset v, double a) {
    final c = math.cos(a), s = math.sin(a);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  static Offset _bezier(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }
}

/// A wing pose: elbow, wrist and the four finger tips (lead finger first).
final class DragonWingKey {
  const DragonWingKey(this.elbow, this.wrist, this.tips);
  final Offset elbow, wrist;
  final List<Offset> tips;
}

/// The art's beats, in seconds on the clocks the rules already run. The
/// rules own [DragonBreath.warnAt] (4.0), [DragonBreath.blastAt] (5.5),
/// [DragonBreath.endAt] (7.1), [SkyBoss.swarmCallAt] (7.6), and the arrival's
/// [SkyBoss.revealAt] (1.65) and [SkyBoss.roarAt] (2.65); everything here is
/// the presentation hung between them. Every effect that must sync with the
/// dragon's body reads its time from here and never invents its own.
///
/// BREATH (combat seconds into the 11 s cycle):
///   alert 3.40  sniff 4.00  rear 4.30  HOLD 4.95  snap 5.20  ignite 5.28
///   burn 5.50   gutter 7.10  windUp 7.30  CALL 7.60 (+ CALL 2 9.00 in fury)
/// ARRIVAL (boss age): silhouette 0..1.9, flash reveal 1.9, wind 2.35,
///   ROAR 2.65, title slam 2.85, title hold to 4.2, bar fills 4.0, ends 4.6.
/// DEFEAT (seconds since the last hit): hit-stop 0..0.12, throes .12..0.8,
///   freeze .8..0.86, burst 0.85 (SkyBoss.burstAt), ember snow 1.5..3.3.
abstract final class DragonTimeline {
  static const alertAt = 3.40, alertFull = 3.95, rearAt = 4.30, holdAt = 4.95;
  static const holdEnd = 5.20, snapAt = 5.20, snapSeconds = .08;

  /// The rules' sniff (the warning band appears) and the moment the wings
  /// have flared and pinned: the rear-back starts as they lock.
  static const sniffAt = 4.0, flareEnd = 4.30;

  /// The jet leaves the jaws (`DragonBreathArt.flame`'s `lit`): the snap has
  /// landed and the head is on the band.
  static const igniteAt = 5.28;

  /// The exhale droop after the flame, and the intake before the call.
  static const recoverEnd = 7.6, callWindAt = 7.30;

  /// The swarm call lands at the rules' 7.6; in fury a second follows.
  static const callAt = 7.6, call2At = 9.0;

  static const arrivalFlashAt = 1.9, arrivalWindAt = 2.35;
  static const titleSlamAt = 2.85, titleEndAt = 4.2, barFillAt = 4.0;
  static const throesEnd = .8, freezeEnd = .86;

  /// The wing chain's lags behind the elbow, in seconds: the wrist follows
  /// [wristLag] later and finger i follows [fingerLag] + [fingerStep] * i
  /// later, and the far wing beats [farPhase] radians behind at [farAmp] of
  /// the stroke.
  static const wristLag = .045, fingerLag = .075, fingerStep = .03;
  static const farPhase = .55, farAmp = .88;

  /// Beat frequencies in rad/s: calm, fury (the phase stays continuous), and
  /// the arrival's slow start.
  static const beatOmega = 5.4, furyOmega = 7.2, arrivalOmega = 2.8;

  /// The fury onset's colour/stance ramp, in seconds.
  static const furyBlendSeconds = .45;
}
