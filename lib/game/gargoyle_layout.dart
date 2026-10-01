import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// THE ONE SOURCE OF TRUTH for where the Searchlight Gargoyle's parts meet.
///
/// Every part (head, body, lamp, wings, tail, ledge, beams, feathers) is drawn
/// in the same frame, "rig units": 1 unit is the hit radius (.115 of the
/// screen height, 41.4 px at 360 px), the ORIGIN IS THE CHEST LAMP (the hit
/// circle), +x is toward the tail, +y is down, and the Gargoyle faces LEFT,
/// toward the bird. Fan tip to talons he stands 7.4 units (306 px) tall.
///
/// Parts that share a seam read their numbers from here, so they line up by
/// construction. Nothing in this file paints. A builder may refine the SHAPE of
/// the part it owns, but must keep every number marked ANCHOR (a seam somebody
/// else depends on), the line-weight hierarchy, the silhouette gates
/// ([GargoyleGates]) and the part inside [envelope].
///
/// The numbers were proven with black silhouettes at 250 px and 120 px in every
/// pose (`test/gargoyle_silhouette_test.dart`) and with the real pose channels
/// over the whole cycle (`test/gargoyle_envelope_test.dart`); do not "improve"
/// an anchor without re-running both.
///
/// What is NOT here: anything the rules own (the hit circle's size, the beam
/// band, the feather's flight; those are `SearchlightGargoyle` and are only
/// mirrored, and tied together by `test/gargoyle_layout_test.dart`).
abstract final class GargoyleLayout {
  // ---------------------------------------------------------------- frame --

  /// The hit circle's radius, in rig units. The rules own it; never change.
  static const hitRadius = 1.0;

  /// The chest lamp: the origin AND the hit circle. ANCHOR.
  static const lamp = Offset.zero;

  /// Pixels per rig unit at 360 px of screen height (.115 x 360).
  static const pxPerUnit = 41.4;

  /// Where the bird flies, and its hit radius, in screen heights (the rules'
  /// `birdX` and `birdRadius`). The beam is defined where it crosses this
  /// column, so the art needs the column, never the screen width.
  static const birdColumn = .47, birdRadius = .038;

  // ------------------------------------------------------------- envelope --

  /// What is on screen at 640x360 and 800x360. He does not bob: the chest is
  /// 180 px (4.35 units) from the right edge and 180 px from the top and the
  /// bottom, always. Left and elsewhere is open sky. (A screen narrower than
  /// 1.71:1 clips the right edge: the anchor keeps 1.21 h from the left.)
  static const screen = Rect.fromLTRB(-99, -4.35, 4.35, 4.35);

  /// The box every COMBAT pose of every part must stay inside, at every point of
  /// every animation: fans with their blade allowance, the crest, the beak at
  /// its most forward, the tail fan, the talons. ENVELOPE (the report's
  /// numbers). Measured over the whole cycle with the real pose channels the
  /// union is L -4.25 (the beak, on a sweep's lock-on), T -3.83 (the near visor
  /// in the fury roar), R 4.21 (the fans in the fury onset), B 3.17 (the tail
  /// fan): .15 / .02 / .11 / .33 of headroom for the real art. The loosened
  /// blade in flight and the steam are not counted (they leave the screen or
  /// are translucent).
  ///
  /// The ledge and tower pier are staging ([GargoyleStagingArt] draws them) and
  /// are NOT inside it: the pier runs off the screen on purpose.
  static const envelope = Rect.fromLTRB(-4.40, -3.85, 4.32, 3.50);

  /// The calm idle pose (and every Reduced Motion idle pose) stays this far
  /// inside, so there is head-room for a shrug, a sway and a hit.
  static const restEnvelope = Rect.fromLTRB(-4.05, -3.65, 4.10, 3.42);

  /// `GargoyleBossRig.bounds`: the clip of the silhouette / white-out / fade
  /// layers (arrival's lightning flash, defeat's white-out), generous enough for
  /// every arrival and defeat pose and the lamp bloom.
  static const layerBounds = Rect.fromLTRB(-4.9, -4.5, 4.9, 4.4);

  /// The health bar strip covers x < [healthBarRight640] above
  /// [healthBarBottom] at 640 wide (x < [healthBarRight800] at 800 wide). Crest
  /// tips may pass under it; **the lenses and the beak never**. Measured from
  /// the real `BossHealthBarArt.bounds` by `test/gargoyle_envelope_test.dart`.
  static const healthBarBottom = -3.65;
  static const healthBarRight640 = .14, healthBarRight800 = -.85;

  /// Clear air to keep between the beak's tip and the bird's hit circle, in px
  /// at 360 px high (the nearest he comes is 640 wide: 89 px).
  static const beakToBirdMinPx = 85.0;

  // -------------------------------------------------------------- strokes --

  /// The line-weight hierarchy, in rig units. Nothing thinner than [hair] is
  /// drawn: it is 1 px at phone size and only shimmers.
  static const inkHero = .10; // torso, head, ledge
  static const inkMajor = .075; // wings, legs, tail, pauldrons
  static const inkPart = .05; // beak, visors, blades' edge lines
  static const inkDetail = .035; // scoring, louvres, cracks' dark edge
  static const hair = .025;

  // ----------------------------------------------------------- the lamp --

  /// The chest lamp: an octagonal brass medallion ([housingRadius] is its
  /// circumradius) around round glass the size of the hit circle, with
  /// [louvreCount] sunburst louvres that close it (lamp 0) or open it (lamp 1).
  /// Plates and louvres end INSIDE r = 1: the lamp IS the target. ANCHOR.
  static const lampRadius = 1.0, housingRadius = 1.36, louvreCount = 11;
  static const hubRadius = .17;

  // ------------------------------------------------------------ the head --

  /// The head is authored in its own frame ("head-local": snout toward -x, rig
  /// scale 1.0), then placed by [headPoint]: pitched about [headPivot], nudged,
  /// scaled [headScale] and shifted [headShift] (both BAKED: they make the head
  /// bigger and thrust it forward without changing the authored numbers), and
  /// finally carried by the body's lean about the hips. ANCHOR: the pose
  /// animates from here; a part never places the head itself.
  static const headPivot = Offset(-.85, -1.45);
  static const headScale = 1.12;
  static const headShift = Offset(.25, -.12);

  /// The two searchlight lenses, head-local: the beam SOURCES. The near lens is
  /// the lower and bigger one (it fires the zone beam and the slit's lower
  /// beam), the far lens the higher one (the slit's upper beam). After
  /// [headPoint] at rest they are (-2.46,-2.51) and (-1.53,-2.79) (radii .40
  /// and .30 after the head's baked scale). ANCHOR.
  static const eyeNear = Offset(-2.40, -2.40), eyeNearRadius = .36;
  static const eyeFar = Offset(-1.55, -2.60), eyeFarRadius = .27;

  /// The hooked steel beak: the tip (the furthest forward point of the
  /// creature), and where the jaw hangs. Head-local. ANCHOR.
  static const beakTip = Offset(-3.82, -1.80), beakHook = Offset(-3.56, -1.12);
  static const jawHinge = Offset(-2.15, -1.62);

  /// Where the hooked beak meets the brow (the scowl's low point), and the
  /// brow visor's lower edge: it descends toward the beak by at least
  /// [GargoyleGates.scowlDegrees], which is what stops him reading as a
  /// goggle-eyed owl. Head-local. ANCHOR.
  static const visorInner = Offset(-1.70, -2.92), visorOuter = Offset(-3.05, -2.14);

  /// The crest: steel blades raked back from the crown; the top of the tallest
  /// (head-local, before [headPoint]) is the creature's highest point at rest:
  /// y -3.16, about -3.5 in rig units.
  static const crestTop = Offset(-.88, -3.16);

  /// The head's REFERENCE OUTLINES, head-local (closed Catmull-Rom control
  /// points for the skull, polygons for the rest): the silhouette the contract
  /// proof rig draws and the first-cut art paints. A builder may carve the
  /// shapes but keeps their extremes (skull back -.74, crown -3.10, beak front
  /// -3.66, hook bottom -1.12, crest top -3.30) and the gates below.
  static const skullOutline = <Offset>[
    Offset(-.90, -1.70), Offset(-.74, -2.25), Offset(-.84, -2.78), Offset(-1.20, -3.08), Offset(-1.80, -3.06),
    Offset(-2.40, -2.92), Offset(-2.90, -2.72), Offset(-3.12, -2.42), Offset(-2.95, -2.00), Offset(-2.45, -1.55),
    Offset(-1.95, -1.25), Offset(-1.40, -1.28), Offset(-1.02, -1.50),
  ];
  static const beakOutline = <Offset>[
    Offset(-2.80, -2.98), Offset(-3.25, -2.90), Offset(-3.55, -2.68), Offset(-3.74, -2.35), Offset(-3.82, -1.95),
    Offset(-3.78, -1.55), Offset(-3.68, -1.25), Offset(-3.56, -1.12), Offset(-3.46, -1.30), Offset(-3.36, -1.56),
    Offset(-3.18, -1.84), Offset(-2.92, -2.06), Offset(-2.72, -2.25),
  ];
  static const jawOutline = <Offset>[
    Offset(-2.15, -1.62), Offset(-3.04, -1.98), Offset(-3.38, -1.66), Offset(-3.16, -1.30), Offset(-2.65, -1.20),
    Offset(-2.20, -1.22),
  ];

  /// The crest: three broad steel blades raked back from the crown, each a
  /// triangle from its root (centre x on the crown, [crestHalfRoot] either
  /// side) to its tip; the tallest tip is the creature's highest point at rest.
  static const crestRoots = <double>[-1.74, -1.36, -.98];
  static const crestTips = <Offset>[Offset(-1.20, -3.10), Offset(-.88, -3.16), Offset(-.56, -3.10)];
  static const crestHalfRoot = .28;

  /// The brow visors: the near hood's lower edge runs from [visorInner] to
  /// [visorOuter] (the scowl), the far hood sits over the far lens.
  static const visorNearOutline = <Offset>[
    Offset(-3.14, -2.74), Offset(-2.40, -2.92), Offset(-1.66, -3.08), Offset(-1.10, -3.04), Offset(-1.10, -2.94),
    Offset(-1.50, -2.95), visorInner, visorOuter,
  ];
  static const visorFarOutline = <Offset>[
    Offset(-1.98, -3.06), Offset(-1.25, -3.16), Offset(-1.02, -2.98), Offset(-1.22, -2.86), Offset(-1.90, -2.76),
  ];

  /// How far the visors sit below their drawn position for a `brow` channel
  /// value: a hood already covers a quarter of the lens at rest and more as he
  /// gets angry (head-local units).
  static double visorDrop(double brow) => .02 + brow.clamp(0.0, 1.0) * .22;

  /// The seat of the near brow visor (the headwear he loses at death).
  /// Head-local. ANCHOR for the falling visor.
  static const visorSeat = Offset(-2.35, -2.90);

  /// Box of the visor in its own frame (origin = seat), for the tumble. The
  /// drawn hood measures (-.70, -.20, .80, .90) around the seat (it hangs
  /// below it, toward the beak): the box carries a margin on every side.
  static const visorBounds = Rect.fromLTRB(-.95, -.30, .95, .95);

  /// A point of the head frame in rig units: pitched (positive: nose DOWN)
  /// about [headPivot], then nudged by [nudge], then carried by the body's
  /// [lean] about the lamp (`lean` is the pose channel; positive leans toward
  /// the bird). Mirrors `GargoylePose.headPoint`.
  static Offset headPoint(
    Offset local, {
    double pitch = 0,
    Offset nudge = Offset.zero,
    double lean = 0,
  }) {
    var q = (local - headPivot) * headScale + headPivot + headShift;
    q = headPivot + turn(q - headPivot, -pitch) + nudge;
    return leanPivot + turn(q - leanPivot, bodyTurn(lean));
  }

  // ------------------------------------------------------------ the body --

  /// The upper body (torso, ruff, both fans, head, lamp) leans about the
  /// chest lamp, so the hit circle NEVER moves and the lamp is always drawn
  /// exactly on it; the tail, the legs and the talons stay on the ledge. It
  /// rests turned [baseLean] radians (toward the bird) and the pose's `lean`
  /// channel (-.8 rears back .. +.8 leans in) moves it by [leanRadians] per
  /// unit. ANCHOR. (The report leaned about the hips; that slid the lamp 12 px
  /// off the hit circle in a hit.)
  static const leanPivot = Offset.zero;
  static const baseLean = -.05, leanRadians = .10;

  /// The body's turn for a lean channel value.
  static double bodyTurn(double lean) => baseLean - lean * leanRadians;

  /// The wing roots: the near fan grows from a limestone pauldron at
  /// [shoulder], the far fan from behind the neck at [farShoulder]. The tail
  /// fan's root is [tailRoot]. ANCHOR.
  static const shoulder = Offset(.80, -1.25), farShoulder = Offset(1.10, -1.55);
  static const tailRoot = Offset(1.40, 2.05);

  /// The steam ports on the shoulders: where the vent's puffs leave.
  static const steamPorts = <Offset>[Offset(.55, -1.95), Offset(1.15, -2.25)];

  /// Where the fury's seam cracks start (torso left, torso right, the thigh):
  /// every part that draws a crack begins it from one of these. ANCHOR. The
  /// right one is ON the chest (its right edge there is x 1.18; the first cut's
  /// (1.90, -.60) lay under the wing's hub).
  static const crackSeeds = <Offset>[Offset(-1.55, -.20), Offset(1.52, .14), Offset(-.60, 1.80)];

  /// Stepped, rectilinear chest and back: the reference silhouette of the
  /// upper body (closed polygon, rig units, before the lean). Extremes: chest
  /// front -1.88, back 1.68, top -1.92, rump 2.84. ANCHOR for the extremes;
  /// the steps inside are the builder's.
  static const torsoOutline = <Offset>[
    Offset(-1.10, -1.85), Offset(-1.10, -1.05), Offset(-1.50, -1.05), Offset(-1.50, -.55),
    Offset(-1.88, -.55), Offset(-1.88, .35), Offset(-1.64, .35), Offset(-1.64, 1.10),
    Offset(-1.28, 1.10), Offset(-1.28, 1.75), Offset(-.88, 1.75), Offset(-.88, 2.45),
    Offset(-.40, 2.80), Offset(.50, 2.84), Offset(1.15, 2.66), Offset(1.55, 2.10),
    Offset(1.55, 1.60), Offset(1.68, 1.60), Offset(1.68, .70), Offset(1.45, .70),
    Offset(1.45, -.20), Offset(1.18, -.20), Offset(1.18, -.85), Offset(.70, -.85),
    Offset(.70, -1.55), Offset(-.20, -1.92),
  ];

  /// The neck ruff (stacked limestone feathers around the collar): reference
  /// outline, drawn over the torso and under the near fan.
  static const ruffOutline = <Offset>[
    Offset(-1.45, -1.25), Offset(-1.35, -.75), Offset(-.95, -.50), Offset(-.40, -.65),
    Offset(.20, -.55), Offset(.70, -1.00), Offset(1.00, -1.70), Offset(.30, -2.05),
    Offset(-.60, -2.05),
  ];

  /// The feathered thigh and the far leg's knee (Catmull-Rom control points).
  static const thighOutline = <Offset>[
    Offset(-1.55, 1.5), Offset(-.70, 1.35), Offset(-.05, 2.15), Offset(-.25, 2.8),
    Offset(-1.25, 2.85), Offset(-1.50, 2.15),
  ];
  static const farLegOutline = <Offset>[
    Offset(.55, 2.2), Offset(1.35, 2.25), Offset(1.55, ledgeY - .02), Offset(.45, ledgeY - .02),
  ];

  /// The three stone talons on the ledge lip, as their heel x (the toe points
  /// left and down onto the lip at y [ledgeY]). ANCHOR: they grip the lip.
  static const talonHeels = <double>[-1.0, -.45, .10];

  // ----------------------------------------------------- the wing fans --

  /// Two fans of [fanBlades] stainless blades: a blade is a pointed steel
  /// feather with chevron notches, drawn from the pauldron to its TIP. A fan
  /// is posed by a blade's stroke (-1 shrugged up, 0 rest, +1 mantled down the
  /// back) and the fan's spread (0 rest .. 1 fully open): [fanTip] places every
  /// blade's tip by interpolating six KEY poses, each proven inside the
  /// envelope, so the fan fits for every stroke and spread, and for any lag
  /// between the blades (each blade depends on its own stroke only).
  static const fanBlades = 7;

  /// A blade's outline in its own frame (x along the blade from the root to
  /// the tip, y across), for a blade of [length]: the pointed feather. A
  /// builder may add notches and a keel but keeps these extremes (the
  /// envelope test measures them with [bladeAllowance]).
  static const bladeRoot = .45, bladeHalfRoot = .40, bladeHalf = .36, bladeShoulder = .55;

  /// Extra room a blade's outline and ink take beyond the tip's straight line
  /// (half its width at the shoulder, and half the ink) for the envelope.
  static const bladeAllowance = bladeHalf + inkMajor / 2;

  /// The tip of blade [i] (0 the top blade .. 6 the lowest) of the near or
  /// [far] fan for blade stroke [stroke] (-1..1) and fan [spread] (0..1).
  static Offset fanTip(int i, {required bool far, double stroke = 0, double spread = 0}) {
    final keys = _fanKeys(far);
    final s = stroke.clamp(-1.0, 1.0), k = spread.clamp(0.0, 1.0);
    Offset at(int sp) {
      final rest = keys[sp][1][i];
      final edge = s < 0 ? keys[sp][0][i] : keys[sp][2][i];
      return Offset.lerp(rest, edge, s.abs())!;
    }

    return Offset.lerp(at(0), at(1), k)!;
  }

  /// A fan's root.
  static Offset fanRoot({required bool far}) => far ? farShoulder : shoulder;

  /// The outline of a blade from [root] to [tip] (closed polygon in rig units).
  static List<Offset> bladeOutline(Offset root, Offset tip) {
    final d = tip - root;
    final len = d.distance;
    if (len < 1e-6) return [root, root, root];
    final u = d / len, n = Offset(-u.dy, u.dx);
    Offset pt(double along, double side) => root + u * along + n * side;
    return [
      pt(bladeRoot, bladeHalfRoot),
      pt(len - bladeShoulder, bladeHalf),
      tip,
      pt(len - bladeShoulder, -bladeHalf),
      pt(bladeRoot, -bladeHalfRoot),
    ];
  }

  /// The wing hub (a stepped pauldron over the blades' roots), as offsets from
  /// the fan's root. ANCHOR: it caps the roots and hides the far fan's pivot.
  static const hubOutline = <Offset>[
    Offset(-.55, .35), Offset(-.35, -.55), Offset(.45, -.80), Offset(1.0, -.25), Offset(.80, .55), Offset(0, .75),
  ];

  /// How the key poses were made (degrees; blade 0's angle, the opening
  /// between blades, the long and short blade lengths) for the near fan. The
  /// far fan is raked 8 degrees higher and 10% shorter. Stroke -1 lifts the fan
  /// 14 degrees and opens it 1.5 more; stroke +1 mantles it (lowers 14, closes
  /// 4, shortens 14%); spread 1 raises it 8, opens 6 and adds .3. Every blade is
  /// then capped so its outline clears the envelope.
  static const fanBaseDegrees = -66.0, fanFarBaseDegrees = -74.0, fanOpenDegrees = 10.5;
  static const fanLongLength = 3.55, fanShortLength = 2.95;
  static const fanMarginRight = .20, fanMarginTop = .50, fanShortRatio = .84;

  static List<List<List<Offset>>>? _keysNear, _keysFar;

  /// keys[spread 0|1][stroke -1|0|+1][blade] -> tip.
  static List<List<List<Offset>>> _fanKeys(bool far) =>
      far ? (_keysFar ??= _buildKeys(true)) : (_keysNear ??= _buildKeys(false));

  static List<List<List<Offset>>> _buildKeys(bool far) {
    final root = fanRoot(far: far);
    List<Offset> key(double w, double sp) {
      final fold = math.max(0.0, w);
      final lift = w * 14 - sp * 8;
      final open = fanOpenDegrees + sp * 6 - fold * 4 - math.min(0.0, w) * 1.5;
      final base = (far ? fanFarBaseDegrees : fanBaseDegrees) + lift;
      return [
        for (var i = 0; i < fanBlades; i++)
          () {
            final a = (base + i * open) * math.pi / 180;
            final cx = math.cos(a), sy = math.sin(a);
            // The LONG blades (even) reach the envelope's edge wherever it is
            // nearest along their direction, the SHORT ones (odd) stop at
            // [fanShortRatio] of the room: the outline steps like an Art Deco
            // crown instead of being cut flat against the screen.
            var room = 99.0;
            // The blade's outline must clear the envelope: the tip keeps
            // [fanMarginRight] off the right edge (the shoulder corners are
            // .36 wide and the body's lean, up to .08 rad about the lamp,
            // carries the tips up to .2 sideways) and [fanMarginTop] under the
            // ceiling.
            if (cx > .01) room = math.min(room, (envelope.right - fanMarginRight - root.dx) / cx);
            if (sy < -.01) room = math.min(room, (root.dy - (envelope.top + fanMarginTop)).abs() / -sy);
            final natural = (i.isEven ? fanLongLength : fanShortLength) + sp * .3;
            var len = math.min(natural * (1 - fold * .14), room * (i.isEven ? 1.0 : fanShortRatio));
            if (far) len *= .9;
            return root + Offset(cx, sy) * len;
          }(),
      ];
    }

    return [
      for (final sp in const [0.0, 1.0]) [for (final w in const [-1.0, 0.0, 1.0]) key(w, sp)],
    ];
  }

  /// The tail: a fan of [tailBlades] shorter steel blades from [tailRoot],
  /// blade i at (-8 + 9 i) degrees, [tailLength] long. The pose lifts the whole
  /// fan by a few degrees ([tailSwingDegrees] per unit of the `tail` channel).
  static const tailBlades = 5, tailLength = 2.05, tailSwingDegrees = 6.0;

  /// The tip of tail blade [i] for a `tail` channel of [swing] (-1 cocked up ..
  /// 1 drooped).
  static Offset tailTip(int i, {double swing = 0}) {
    final a = (-8 + i * 9 + swing * tailSwingDegrees) * math.pi / 180;
    return tailRoot + Offset(math.cos(a), math.sin(a)) * (tailLength - i * .03);
  }

  /// The blade that leaves the near fan when he shrugs a stone feather loose
  /// (the top blade, flung up and away), and where it flies: the tip at the
  /// flick, and its launch velocity in rig units per second (up and back).
  static const shedBlade = 0;
  static const shedVelocity = Offset(-1.2, -7.5);

  // ------------------------------------------------ ledge, pier, staging --

  /// The ledge the talons grip (its lip is at [ledgeY], running from
  /// [ledgeLip] right, off the screen), the corbels under it (three steps, to
  /// [corbelBottom]), the tower pier from [pierX] (runs off the top), and the
  /// empty weather-vane mount the courier will fill (a rod to [vaneTop]).
  /// ANCHOR for G8 and for the talons. The lip runs out to -3.0 (it was -2.25
  /// in the first cut) so the pigeons' twig nest has room beside the vane.
  static const ledgeY = 2.95, ledgeLip = -3.0, ledgeRight = 4.6;
  static const corbelBottom = 4.5, pierX = 3.55;
  static const vaneMount = Offset(-2.0, ledgeY), vaneTop = 1.68;

  /// Where his two lenses lie on the rubble when he is gone (head-local sizes
  /// are the lenses'): the defeat's last picture.
  static const rubbleLenses = <(Offset, double)>[(Offset(-1.15, 2.56), .36), (Offset(-.35, 2.68), .27)];

  // ------------------------------------------------------------- z-order --

  /// Back to front. The rig paints in this order; parts must not assume any
  /// other neighbour:
  ///   1 bloom (the lamp's glow)        8 ruff
  ///   2 ledge, pier, vane (staging)    9 near fan
  ///   3 far fan                       10 lamp
  ///   4 tail                          11 head
  ///   5 far leg                       12 cracks
  ///   6 torso                         13 steam
  ///   7 thigh and talons              14 shed (the blade a shrug loosened, in
  ///                                      flight: it leaves off the top of the
  ///                                      screen by design, so the envelope
  ///                                      does not count it)
  static const zOrder = <String>[
    'bloom', 'ledge', 'farFan', 'tail', 'farLeg', 'torso', 'thigh', //
    'ruff', 'nearFan', 'lamp', 'head', 'cracks', 'steam', 'shed',
  ];

  // ------------------------------------------------------------- helpers --

  /// [v] turned by [angle] radians (positive: clockwise on screen, y down).
  static Offset turn(Offset v, double angle) {
    final c = math.cos(angle), s = math.sin(angle);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }
}

/// The silhouette gates: what must be true of the creature at 120 px for him to
/// read as a stern Art Deco eagle gargoyle, not a cute goggle-eyed owl. The
/// contract test measures the REFERENCE rig against all of them and the real
/// art against the raster ones once `enforceRealArt` is on.
abstract final class GargoyleGates {
  /// Negative spaces that must stay open at 120 px in the calm pose, as the
  /// diameter of the largest empty disc in the named region (rig units):
  /// the throat notch (under the beak, in front of the chest), the wing V
  /// (between the crest and the near fan), the tail pocket (between the thigh
  /// and the tail fan).
  static const throatNotch = .6, wingV = 1.0, tailPocket = .5;

  /// The brow visor's lower edge must slope down toward the beak by at least
  /// this many degrees, and cover at least [visorCover] of the near lens.
  static const scowlDegrees = 25.0, visorCover = .25;

  /// The beak must hook: it projects at least [beakProjection] beyond the
  /// brow's front (head-local) and its tip drops at least [beakDrop] below the
  /// near lens' centre.
  static const beakProjection = .55, beakDrop = .70;

  /// At 120 px the creature's silhouette must not be a blob: its area over its
  /// bounding rectangle's stays under [maxFill] (the placeholder owl was .66).
  static const maxFill = .62;
}

/// The art's beats on the clocks the rules already run, in seconds. The rules
/// own `SearchlightGargoyle` (9 s cycle: warning 2.0, sweep 3.5, vent 6.4, lamp
/// close 8.7) and `SkyBoss` (reveal 1.65, roar 2.65, burst .85); everything
/// here is the presentation hung between them, tied to them by
/// `test/gargoyle_layout_test.dart`. Every effect that must sync with the body
/// reads its time from here and never invents its own.
///
/// CYCLE (x = combat seconds mod 9, see `GargoylePose`):
///   0.0 perch (shuttered) .2 feather   2.0 WARNING: brow drops, head rears
///   then locks on; eyes flare 3.5 SWEEP: lean in, head follows the beam
///   4.6 feather   6.4 VENT: lamp opens .3 s, head back, beak open, steam
///   8.7 lamp closes; 8.8 the next feather's wind-up.
/// ARRIVAL (boss age): storm 0..1.55, ledge slides in .95..2.65, LIGHTNING
///   1.65 (flash, stone to colour by 2.10, lenses ignite 1.68 and 1.78), fan
///   unfolds 2.0..2.65, intake 2.35, ROAR 2.65, card 2.85, bar fills 4.0,
///   control 4.6.
/// DEFEAT (seconds since the last hit): white-out 0..0.12, cracks race
///   .12..0.8, visor knocked loose .3, lamp glass shatters .6, BURST .85,
///   pigeons 1.0..2.4, card 1.55, rubble 2.1..3.8.
abstract final class GargoyleTimeline {
  // The rules' clocks (mirrored; the layout test pins them).
  static const period = 9.0, warnAt = 2.0, sweepAt = 3.5, ventAt = 6.4;
  static const lampOpenSeconds = .3, lampCloseAt = 8.7;
  static const glideSeconds = 1.8, furyGlideSeconds = 1.5;
  static const arrivalSeconds = 4.6, revealAt = 1.65, roarAt = 2.65, burstAt = .85;

  /// A shrug loosens a stone feather: the wind-up, the flick (the feather
  /// leaves at its end, exactly at the rules' launch time) and the settle.
  static const shrugWindUp = .25, shrugFlick = .15, shrugSettle = .30;

  /// The hit flash on the body: its peak (reduced under Reduced Motion), and
  /// how long a re-hit takes to bring it back to full (a hit that lands `dt`
  /// seconds after the one before flashes `1 - e^(-dt / recover)` of the peak,
  /// so rapid fire cannot strobe: three hits a second flash well under half
  /// as hard as one). The first reviewers measured .55 flashing 21 to 23% of
  /// the screen 3.3 times a second; the brightest part is now the lamp's own
  /// burst (a few percent of the screen).
  static const hitFlashPeak = .12, hitFlashPeakReduced = .06, hitFlashRecover = .45;

  /// The blade that left regrows over this long after the launch.
  static const regrowSeconds = .55;

  /// The vent's steam pulse, the glance's spark, the hit's pulse.
  static const steamSeconds = 1.2, glanceSeconds = .15, hitSeconds = .28;

  /// Fury: the colour / stance ramp and the onset's roar pulse.
  static const furyBlendSeconds = .45, rageSeconds = 1.1;

  /// Idle: the blink's period, the breath's rate (rad/s) and the lens pulse's.
  static const blinkPeriod = 4.3, breathOmega = .9, lensOmega = 3.0;

  /// The blades' lag behind blade 0, per blade index, in seconds: the fan
  /// ripples when he shrugs.
  static const bladeLag = .028;

  // Arrival beats.
  static const stoneClearFrom = revealAt, stoneClearTo = 2.10;
  static const lensSparkAt = [1.68, 1.78];
  static const unfoldFrom = 2.0, unfoldTo = 2.65, windAt = 2.35;
  static const cardAt = 2.85, barFillAt = 4.0;

  // Defeat beats.
  static const whiteOutEnd = .12, crackFrom = .12, crackTo = .8;
  static const visorLostAt = .3, glassShatterAt = .6;
  static const pigeonsFrom = 1.0, pigeonsTo = 2.4, cardAtDeath = 1.55, rubbleFrom = 2.1;
}
