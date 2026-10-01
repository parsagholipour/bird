import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/king_coo.dart';

/// THE ONE SOURCE OF TRUTH for where King Coo's parts meet.
///
/// King Coo, Commissioner of the Curb, is a pouter pigeon in a navy police
/// cap: a huge round chest (the hit circle), a small head on an iridescent
/// ruff, a flat wedge tail, a crumb sack under it, a silver whistle on a
/// chain. Every part (head, ruff, cap, whistle, chest, body, legs, tail,
/// sack, wings, the bomb in his hand) is drawn in the same frame, "rig
/// units": 1 unit is the hit radius, the origin is the chest (the hit
/// circle), +x is toward the tail, +y is down, and he faces LEFT toward the
/// bird. At 360 px of screen height one unit is 41.4 px; he stands about 6.4
/// units (265 px) wide and 4.9 (203 px) tall.
///
/// Parts that share a seam read their numbers from here, so they line up by
/// construction. Nothing in this file paints. A builder may refine the SHAPE
/// of the part it owns, but must keep every number marked ANCHOR (a seam
/// somebody else depends on) and keep the part inside [envelope].
///
/// The numbers were proven with black silhouettes at 250 px and 120 px in
/// every pose by `test/king_coo_silhouette_test.dart` and the envelope sweep
/// in `test/king_coo_envelope_test.dart`; do not "improve" an anchor without
/// re-running them.
abstract final class KingCooLayout {
  // ---------------------------------------------------------------- frame --

  /// The hit circle's radius, in rig units. The rules own it (`SkyBoss.radius`
  /// is .115 of the screen height); never change.
  static const hitRadius = 1.0;

  /// The chest: the origin. ANCHOR.
  static const chest = Offset.zero;

  /// Pixels per rig unit at 360 px of screen height (0.115 x 360).
  static const pxPerUnit = 41.4;

  // ------------------------------------------------------------- envelope --

  /// What is on screen in the WORST case at 640x360 and 800x360: the rules
  /// anchor him at `max(birdX + .70, width - .55)` screen heights, so the
  /// chest is .55 h (4.78 units) from the right edge at both widths, and the
  /// hover bobs it .06 h (.52 unit): with the chest at its highest the top of
  /// the screen is at y = -3.83, at its lowest the bottom is at +3.83. The
  /// left is open sky (the bird is 6.6 units away).
  static const screenRight = 4.78, hoverReach = .52;
  static const visibleWorst = Rect.fromLTRB(-9, -3.83, 4.78, 3.83);

  /// The box every COMBAT pose of every part must stay inside, at every point
  /// of the waddle and the wingbeat, including the cap and siren, the whistle,
  /// the bomb in hand, the wing tip at full stretch, the tail feathers, feet,
  /// bob, roll, pitch, cap hop and the wing stomp. ENVELOPE.
  ///
  /// Budget of the margins (units to spare at the worst hover): right `.58`
  /// (24 px) to the screen edge, top `.23` (9.5 px) to the health bar, left
  /// open, bottom `1.3`. The proof silhouette sits `0`-`.15` inside it and
  /// the first-cut art `.05`-`.35`: the real art's room for feathers, rim and
  /// overshoot is the difference, so a part that needs more asks for it with
  /// the failing pose (the envelope test names the part, pose and pixel).
  static const envelope = Rect.fromLTRB(-2.80, -2.90, 4.20, 2.50);

  /// The calm Reduced Motion pose (and any pose held still) stays this far
  /// inside, so the hover, the beat and the cap wobble have head-room.
  static const restEnvelope = Rect.fromLTRB(-2.55, -2.75, 4.10, 2.45);

  /// `KingCooBossRig.bounds`: the clip of the silhouette / white-out / fade
  /// layers. Generous enough for the arrival swell ([arrivalSwell], x1.12 of
  /// the envelope: L -3.08 T -3.25 R 4.65 B 2.58) and the defeat's over-swell
  /// and squash.
  static const layerBounds = Rect.fromLTRB(-3.6, -3.7, 4.9, 3.2);

  /// The health bar covers x < [healthBarRight] above this y at its lowest,
  /// at the worst hover (640x360). The eye, the beak and the whistle must
  /// never be under it; cap and siren stay clear of it too ([envelope]).
  static const healthBarClearance = -3.13, healthBarRight = .56;

  /// The body's swell at the arrival's roar, at most.
  static const arrivalSwell = 1.12;

  /// The rules' anchor for him (`FlightSimulation._advanceBoss`, mirrored and
  /// pinned by `king_coo_layout_test`): the chest's screen x for a bird at
  /// [birdX] on a screen [width] heights wide, and its screen y (heights) at
  /// combat second [combat]. The staging and the bomb's flight use them with
  /// the rig's anchors: `screen = boss + anchor * (h * SkyBoss.radius)`.
  static double anchorX(double birdX, double width) =>
      math.max(birdX + .70, width - .55);
  static double hoverY(double combat) => .5 + .06 * math.sin(.9 * combat);

  // --------------------------------------------------------------- strokes --

  /// The line-weight hierarchy, in rig units (41 px each). Nothing thinner
  /// than [hair] is drawn: it is 1.2 px at phone size and only shimmers.
  static const inkHero = .10; // chest, body, head (the three big masses)
  static const inkMajor = .075; // wings, legs, tail, sack, ruff
  static const inkPart = .05; // cap, beak, whistle, badge, cere
  static const inkDetail = .035; // scallop rows, hatch, veins, lids
  static const hair = .03;

  // ------------------------------------------------------------- the chest --

  /// The chest is the biggest shape and the hit circle. FLUFFED (calm) it is
  /// a scalloped ball of radius [chestFluffRadius]; PUFFED (the window) it is
  /// exactly [hitRadius], smooth and lit. The outline bumps are [chestBumps]
  /// in every state: their depth shrinks from [chestFluffDepth] to
  /// [chestTautDepth] as the chest swells, so the outline never pops. ANCHOR.
  static const chestFluffRadius = .84;
  static const chestBumps = 15;
  static const chestFluffDepth = .07, chestTautDepth = .012;

  /// The chest's outline radius for a swell [puff] (see `KingCooPose.puff`):
  /// .84 fluffed .. 1.0 puffed, and past it in the defeat's inflating
  /// (1.3 is radius 1.36).
  static double chestRadiusAt(double puff) => puff <= 1
      ? chestFluffRadius + (1 - chestFluffRadius) * math.max(0, puff)
      : 1 + (puff - 1) * 1.2;

  /// The brass badge: the aim point. Its centre and half width.
  static const badge = Offset(.02, .10);
  static const badgeSize = .27;

  // ------------------------------------------------------------ the body --

  /// Closed Catmull-Rom outline of the body behind the chest: a teardrop that
  /// starts tangent to the chest's top (y -1.03) and tapers down to the tail
  /// root (the back slopes 25 degrees), so the chest is a GLOBE in front of a
  /// slim body, not a hunch (a hunched back read as a hen at 120 px).
  /// ANCHOR: the extremes (back -1.03 at x .10, rump 2.46, belly 1.08, front
  /// -.92) and the taper (the torso is at most [bodyDepthMax] deep at
  /// x = [bodyDepthAt]) are what the head, legs, sack, wings and tail are
  /// seated against. Detail inside is yours.
  static const bodyDepthAt = 1.5, bodyDepthMax = 1.75;
  static const bodyOutline = <Offset>[
    Offset(-.70, -.95),
    Offset(.10, -1.03),
    Offset(.95, -.88),
    Offset(1.65, -.55),
    Offset(2.15, -.18),
    Offset(2.42, .14),
    Offset(2.46, .44),
    Offset(2.20, .72),
    Offset(1.60, .93),
    Offset(.90, 1.06),
    Offset(.15, 1.08),
    Offset(-.55, .90),
    Offset(-.90, .35),
    Offset(-.92, -.35),
  ];

  // ------------------------------------------------------------- the head --

  /// The skull's centre at rest (`headRest`), and its outline in the HEAD
  /// frame (origin the skull centre, beak toward -x). The pose moves the head
  /// by `KingCooPose.head` and turns it by `headTilt` about the centre.
  /// ANCHOR.
  static const headRest = Offset(-1.14, -1.58);
  static const skullOutline = <Offset>[
    Offset(-.30, -.54),
    Offset(.24, -.48),
    Offset(.56, -.14),
    Offset(.54, .30),
    Offset(.22, .56),
    Offset(-.32, .54),
    Offset(-.54, .32),
    Offset(-.58, -.05),
    Offset(-.50, -.36),
  ];

  /// In the HEAD frame. ANCHOR (the rig's `eyeAt`, `beakAt`, `mouthAt`,
  /// `whistleAt`, `capAt`, `sirenAt` read them; the arrival glint, the COO!
  /// ring and the falling cap start from them):
  static const headEye = Offset(-.18, -.04); // eye centre (the iris, K8)
  static const headBeakTip = Offset(-1.10, .02); // upper mandible tip
  // The jaw pivots here. SIGN: the beak points toward -x, so a turn that is
  // clockwise-positive LIFTS the tip: the lower mandible swings open by
  // `rotate(-.72 * gape)` (down) and the upper one by `rotate(+.16 * gape)`
  // (up). (.72 and .16 are magnitudes; the first cut had them as written and
  // its jaw opened into the upper beak: K2 found it, K8 fixed the text.)
  static const headBeakHinge = Offset(-.42, .14);
  static const headMouth = Offset(-.78, .14); // where the beak opens
  static const headWhistle = Offset(-.74, .06); // whistle in the beak
  static const headCapSeat = Offset(0, -.36); // cap band centre
  static const headSiren = Offset(0, -.94); // siren dome top of the cap
  static const headRuffRadius = .72; // the ruff's outer radius about the head

  /// The same anchors for the REST pose, in rig units: eye (-1.32,-1.62),
  /// beak tip (-2.24,-1.56), whistle (-1.88,-1.52), cap seat (-1.14,-1.94),
  /// siren (-1.17,-2.52) (the cap's rest tilt of -.05 leans it .03). The
  /// report's table has the head at (-1.12,-1.30) and the beak tip at -2.08:
  /// the silhouette review raised the head .28 onto a NECK (a hen has none)
  /// and lengthened the beak .14 so it leads the face, the two things that
  /// made him read as a pigeon.
  static const eyeRest = Offset(-1.32, -1.62); // headRest + headEye
  static const beakTipRest = Offset(-2.24, -1.56);
  static const whistleMouthRest = Offset(-1.88, -1.52);
  static const capSeatRest = Offset(-1.14, -1.94);
  static const sirenRest = Offset(-1.17, -2.52);

  /// The neck: an iridescent tube from behind the chest's upper left (its
  /// base) to the skull, [neckWidth] across at the base.
  static const neckBase = Offset(-.62, -.80);
  static const neckWidth = .62;

  /// The whistle hangs on a chain at the neck until it is raised into the
  /// beak: its resting place, and where the chain is anchored (rig units).
  static const whistleRest = Offset(-.84, -.36);
  static const chainAnchor = Offset(-.50, -1.00);

  // ------------------------------------------------------------ the wings --

  /// Wing roots (rig units) and the wing's size. The wing is drawn in its own
  /// frame (root at the origin, pointing +x, length [wingLocalLength], leading
  /// edge on -y) scaled by [wingScale] and turned by the wing's angle:
  /// 0 points at the tail, +pi/2 straight down, pi at the bird, -pi/2 up.
  /// ANCHOR.
  static const nearShoulder = Offset(.25, -.55);
  static const farShoulder = Offset(.50, -.78);
  static const wingLocalLength = 1.90, wingScale = .88;

  /// The wing tip in the wing's own frame (before [wingScale]).
  static const wingTipLocal = Offset(1.90, -.04);

  /// How long the wing reaches from its root at scale 1 (`1.67`).
  static const wingReach = wingLocalLength * wingScale;

  /// Rest angles of the two wings (Reduced Motion and the silhouette sheets).
  static const restWingNear = .05, restWingFar = -.50;

  /// The toss, in the near wing's angle: dipped into the sack, swung back
  /// with the bomb, and the angle at which the bomb leaves the hand
  /// ([tossRelease]: the wing tip is then exactly at [lobRelease]).
  static const windupDip = .70, windupBack = -.75, tossRelease = 2.58;

  /// The toss follow-through overshoots [tossRelease] by this, and the wing
  /// stretches this much (whip) for a moment.
  static const followOvershoot = .57, followStretch = 1.25;

  // ----------------------------------------------- tail, legs, sack, bomb --

  /// The tail: a flat wedge of four feathers fanned from [tailRoot] (inside
  /// the rump), feather lengths and width. ANCHOR: the root.
  static const tailRoot = Offset(2.30, .24);
  static const tailLengths = <double>[1.44, 1.56, 1.56, 1.44];
  static const tailWidth = .44;

  /// The legs: two hips under the belly and the height of the feet. The far
  /// leg hangs a little behind the near one. ANCHOR: the gap between the far
  /// leg and the sack ([sackOutline]) is at least [legSackGap].
  static const nearHip = Offset(.22, 1.02), farHip = Offset(.62, 1.00);
  static const footY = 2.20, footReach = .16, footLift = .10;
  static const legSackGap = .20;

  /// The crumb sack that hangs under the tail on a strap over the back, and
  /// the strap's three points (sack mouth, control, shoulder). ANCHOR.
  static const sackMouth = Offset(1.62, .56), sackCentre = Offset(1.62, 1.08);
  static const sackOutline = <Offset>[
    Offset(1.22, .64),
    Offset(1.62, .56),
    Offset(2.02, .64),
    Offset(2.24, .98),
    Offset(2.16, 1.42),
    Offset(1.86, 1.68),
    Offset(1.40, 1.68),
    Offset(1.10, 1.42),
    Offset(1.02, .98),
  ];
  static const strapFrom = Offset(1.30, .66),
      strapControl = Offset(1.75, -.30),
      strapTo = Offset(.55, -.93);

  /// Where a crumb bomb is born when he lets go: the near wing's tip at the
  /// instant of release ([tossRelease]). ANCHOR: the ballistic bomb art
  /// (`KingCooCrumbArt`) starts here, the wing tip passes within
  /// [lobReleaseTolerance] of it.
  static const lobRelease = Offset(-1.15, .32);
  static const lobReleaseTolerance = .12;

  /// The bomb in his hand: a roll of this radius (rig units).
  static const bombRadius = .30;

  // ------------------------------------------------------ silhouette study --

  /// Negative spaces that MUST stay open at 120 px (19 px per unit) in the
  /// calm pose: the `throat notch` under the beak, the gap between the legs
  /// and the sack, and the pocket between the wing and the tail. A probe
  /// fails when more than [openShare] of it is filled. (A fatter prototype
  /// that loses one reads as a blob: a change that closes one is rejected.)
  static const negativeSpaces = <String, Rect>{
    'throat notch': Rect.fromLTRB(-2.00, -.95, -1.45, -.55),
    'legs to sack': Rect.fromLTRB(.82, 1.36, 1.00, 1.90),
    'wing to tail': Rect.fromLTRB(2.72, -.78, 3.30, -.42),
  };
  static const openShare = .30;

  // -------------------------------------------------------------- z-order --

  /// Back to front. The rig paints in this order; parts must not assume any
  /// other neighbour. The NEAR WING is last (it crosses the chest and the
  /// back; the whistle and the ruff are beneath it), the bomb in his hand
  /// over that, steam over everything.
  static const zOrder = <String>[
    'farWing', 'farLeg', 'tail', 'torso', 'neck', 'sack', 'nearLeg', //
    'chest', 'ruff', 'head', 'cap', 'whistle', 'nearWing', 'bomb', 'steam',
  ];

  /// The part names each owner paints (for the budget and envelope reports).
  static const headParts = <String>[
    'neck', 'ruff', 'head', 'cap', 'whistle', 'steam', //
  ];
  static const bodyParts = <String>[
    'farLeg', 'tail', 'torso', 'sack', 'nearLeg', 'chest', //
  ];
  static const wingParts = <String>['farWing', 'nearWing'];
  static const crumbParts = <String>['bomb'];

  // ------------------------------------------------------------- helpers --

  /// [v] turned by [angle] radians (clockwise on screen).
  static Offset turn(Offset v, double angle) {
    final c = math.cos(angle), s = math.sin(angle);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }
}

/// The per-frame budget (real mid-range Android phones, 60 fps), by owner.
/// `test/king_coo_budget_test.dart` enforces it; a failure names the part,
/// the state and the number. Units: draw ops (paths, circles, lines, rects,
/// ovals, arcs), gradient shaders BUILT on a warm frame (the pose-independent
/// ones live in `static final` or `KingCooKit.cached`), `clipPath`s.
abstract final class KingCooBudget {
  /// The whole rig, per frame, worst state: 210 ops, 12 shaders, 8 clips, 0
  /// `saveLayer` in combat (the arrival silhouette and the defeat white-out
  /// are the staging's two bounded layers), 0 blur masks. The shares may add
  /// up to more than the total: the total is what is enforced. (The head's
  /// is 70, not the report's 60: the tone's washes cost it up to 12 ops in a
  /// fury frame under a hit, which the report did not count.) The first cut
  /// measures 79-132 ops, 6 clips, 0 shaders built on a warm frame.
  static const rigOps = 210, rigShaders = 12, rigClips = 8;

  /// Each owner's share: ops, shaders built, clips.
  static const head = (ops: 70, shaders: 3, clips: 2); // head+ruff+cap+whistle+steam
  static const body = (ops: 100, shaders: 4, clips: 3); // chest..sack, legs
  static const wings = (ops: 40, shaders: 2, clips: 2);
  static const assembly = (ops: 6, shaders: 0, clips: 0);

  /// The effects that live outside the rig, per frame (owners K5-K7): a bomb
  /// 25 ops, a ring 30, a cloud 40, the lanes 60, the HUD 60, a burst 80; a
  /// squad pigeon at most 30 ops (11 at once in fury).
  static const bomb = 25, ring = 30, cloud = 40, lanes = 60, hud = 60;
  static const burst = 80, squadPigeon = 30;
}

/// The art's beats, in seconds on the clocks the rules already run. The rules
/// own [KingCoo.lockLead] (the 0.8 s ring), [KingCoo.lobFlight],
/// [KingCoo.puffAt] (7.6), [KingCoo.whistleAt] (9.2), [KingCoo.windowEnd]
/// (10.0), and `SkyBoss`'s arrival (reveal 1.65, roar 2.65, end 4.6) and
/// defeat (burst .85, 3.8 s); everything here is the presentation hung
/// between them. Every effect that must sync with his body reads its time
/// from here and never invents its own.
///
/// COMBAT (cycle seconds in the fixed 14 s cycle):
///   lock +0 .. +.8   wind-up: dip into the sack, backswing, hold, swing
///   launch (toss)    the bomb leaves the hand; follow-through .3 s
///   7.6              PUFF: the chest swells over 1.6 s, the siren blinks, the
///                    squadron cue rises
///   8.5 .. 9.0       the whistle is raised into the beak
///   9.2              WHISTLE (rules: the squadron is released); blast .4 s
///   10.0             window closes; chest settles by 10.4, whistle lowered
/// ARRIVAL (boss age): silhouette 0..1.9, flash reveal 1.9, rears and puffs
///   2.35, COO! 2.65 (swell, shock ring), name card 2.85, bar fills 4.0, ends
///   4.6.
/// DEFEAT (seconds since the killing hit): hit-stop 0..0.12, he puffs up
///   .12..0.8 (the cap leaves at 0.3), POP at 0.85, gone by 1.07.
abstract final class KingCooTimeline {
  // The waddle-hover.
  static const waddleSeconds = 1.25, furyWaddleSeconds = .95;
  static const beatHz = 1.6, furyBeatHz = 2.1;

  // The crumb throw (fractions of the .8 s between the lock and the toss).
  static const windupSeconds = KingCoo.lockLead;
  static const dipEnd = .30, backEnd = .58, swingStart = .825;
  static const followSeconds = .30, armReturnSeconds = .35;

  // The puff window (cycle seconds).
  static const puffAt = KingCoo.puffAt, whistleAt = KingCoo.whistleAt;
  static const windowEnd = KingCoo.windowEnd;
  static const whistleRaiseFrom = 8.5, whistleRaiseTo = 9.0;
  static const blastSeconds = .4, whistleLowerSeconds = .3;
  static const puffFrontLoad = 2.2; // the inhale's curve: 1 - (1-x)^2.2
  static const sirenHz = 3.0, squadCueIn = .3, squadCueOut = .4;

  // The pop (seconds since poppedAt).
  static const popSquash = .22, popDizzy = 1.4, popRecover = 1.2;
  static const popCapFlight = .9, popCapHop = .45;

  // The hit and the fury.
  static const hitSeconds = .28, hitSpring = .40;
  static const furyBlendSeconds = .45, stompSeconds = .25;

  // The arrival (boss age).
  static const flashAt = 1.9, rearAt = 2.35, cooAt = 2.65, cardAt = 2.85;
  static const barFillAt = 4.0;
  static const swellFrom = 2.35, swellTo = 3.45;

  // The defeat (seconds since the killing hit).
  static const hitStop = .12, inflateEnd = .80, capOffAt = .30, popAt = .85;
}
