import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'dragon_kit.dart';
import 'dragon_layout.dart';
import 'dragon_pose.dart';

/// The pose channels the neck and head read.
final class DragonHeadPose {
  const DragonHeadPose({
    this.time = 0,
    this.at = DragonLayout.headRest,
    this.angle = DragonLayout.headRestAngle,
    this.gape = 0,
    this.glare = 0,
    this.look = 0,
    this.blink = 0,
    this.wince = 0,
    this.throat = 0,
    this.smoke = .3,
    this.roar = 0,
    this.call = 0,
    this.alert = 0,
    this.drag = Offset.zero,
    this.coil = 0,
    this.dizzy = false,
    this.crown = true,
    this.tone = const DragonTone(),
  });

  /// The head for [pose]. EVERY head implementation keeps this factory: the
  /// rig builds nothing but `DragonHeadPose.of(pose)`, so this is where a
  /// head reads the channels (throat, smoke, gape, glare, neckDrag...) it
  /// needs from `DragonPose`.
  factory DragonHeadPose.of(DragonPose pose, {bool crown = true}) =>
      DragonHeadPose(
        time: pose.time,
        at: pose.head.at,
        angle: pose.head.angle,
        gape: pose.gape,
        glare: pose.glare,
        look: pose.look,
        blink: pose.blink,
        wince: pose.wince,
        throat: pose.throat,
        smoke: pose.smoke,
        roar: pose.roar,
        call: pose.call,
        alert: pose.alert,
        drag: pose.neckDrag,
        coil: pose.neckCoil,
        dizzy: pose.defeated,
        crown: crown,
        tone: pose.tone,
      );

  /// Seconds on the boss clock, 0 when the pose must hold still.
  final double time;

  /// The skull's centre in rig units and its turn (positive: snout down).
  final Offset at;
  final double angle;

  /// Jaw opening, the scowl, the eye's aim (-1 up, 1 down), the lid.
  final double gape, glare, look, blink, wince;

  /// Fire rising up the throat, 0 to 1 (1 reaches the jaws).
  final double throat;

  /// How thickly smoke curls from the nostrils.
  final double smoke;

  /// The roar (eyes squeezed), the swarm call's envelope (the mouth and
  /// throat glow violet, not orange) and the breath coming (eyes narrow).
  final double roar, call, alert;

  /// The neck's follow-through against a fast head, and how tightly its S
  /// coils while it gathers.
  final Offset drag;
  final double coil;

  /// Knocked senseless: the eye rolls.
  final bool dizzy;

  /// Whether the circlet still sits on the brow.
  final bool crown;
  final DragonTone tone;
}

/// The neck's geometry for one pose (see [DragonHeadArt.neckOf]).
final class DragonNeck {
  DragonNeck._(this.spine, this.nrm, this.plus, this.minus);

  /// The nine spine samples from the chest to the joint, the unit normal at
  /// each (+ is the crest side) and the half widths either side.
  final List<Offset> spine, nrm;
  final List<double> plus, minus;

  /// Both edges at the half-sample steps, chest to skull (17 points each).
  late final List<Offset> crestEdge, throatEdge;

  /// A point [f] of the way across the neck at sample [u]: +1 the crest
  /// (back) edge, -1 the throat edge.
  Offset at(double u, double f) {
    final n = spine.length;
    final i = u.floor().clamp(0, n - 2);
    final t = u - i;
    final centre = Offset.lerp(spine[i], spine[i + 1], t)!;
    final normal = DragonKit.unit(Offset.lerp(nrm[i], nrm[i + 1], t)!);
    final half = f >= 0
        ? plus[i] + (plus[i + 1] - plus[i]) * t
        : minus[i] + (minus[i + 1] - minus[i]) * t;
    return centre + normal * (half * f);
  }

  /// The line [f] of the way across, at half-sample steps.
  List<Offset> along(double f, {double from = 0, double to = 8}) => [
    for (var u = from; u <= to + 1e-6; u += .5) at(u, f),
  ];

  /// The neck as one outline (crest edge out, throat edge back), wound
  /// counter-clockwise on screen like every part of the hide.
  late final Path path = DragonHeadArt._ribbon(crestEdge, filletEdge);

  /// The throat edge with its top rounded into the jaw's underside (radius
  /// [DragonHeadArt._filletRadius]): the outline of the neck. [throatEdge]
  /// itself still runs straight to the jaw's corner: the belly band is laid
  /// along it, and the band's outer edge lies past the silhouette.
  late final List<Offset> filletEdge;
}

/// The Ember Dragon's neck and head in rig units. The head is authored
/// around the skull's centre facing left at [scale] 1.0 (directly in rig
/// units), and every anchor is a [DragonLayout] number.
///
/// Lit like the rest of the dragon: the sky's bounce along the upper-left
/// edges, the fire's own along the undersides, ink on the outside. Nothing
/// behind the skull reaches past x = 1.1: in the rear-back poses the head
/// turns up into the wing arms, and anything longer would chain into them.
abstract final class DragonHeadArt {
  static const _ink = DragonPalette.ink;
  static const scale = DragonLayout.headScale;

  /// Where the jaws open, in the head's own frame.
  static const mouth = DragonLayout.headMouth;

  /// Where the circlet sits, in the head's own frame.
  static const crownSeat = DragonLayout.headCrownSeat;

  /// The eye's centre, in the head's own frame.
  static const eye = DragonLayout.headEye;

  /// The nostril, in the head's own frame.
  static const nostril = DragonLayout.headNostril;

  /// Bounds of [crown] around its seat.
  static const crownBounds = DragonLayout.crownBounds;

  static const _hinge = DragonLayout.headJawHinge;
  static const _joint = DragonLayout.headNeckJoint;

  /// A point of the head's frame in rig units, for pose [p].
  static Offset point(DragonHeadPose p, Offset local) {
    p = _safe(p);
    return p.at + DragonKit.turn(local * scale, -p.angle);
  }

  /// How far the jaw has swung for [gape] (0..1), in radians: 39 degrees at
  /// full gape. The jaw turns about the hinge with `rotate(-open)`, so the
  /// chin drops (the old code turned the other way and closed into the skull).
  static double open(double gape) => _fin(gape).clamp(0.0, 1.0) * .68;

  /// The furthest the lower jaw may point below the horizontal, in radians:
  /// the head's own turn counts toward it. In the low-lane strikes the snout
  /// is already turned down 30 degrees, and a full 39 degree gape on top of
  /// that would drive the chin into the foreleg reaching under it.
  static const _maxJawAngle = .86;

  /// The jaw's swing for [p]: [open] for its gape, held short of
  /// [_maxJawAngle] (never below a third of a radian, so it always opens).
  static double openFor(DragonHeadPose p) {
    p = _safe(p);
    return math.min(open(p.gape), math.max(.3, _maxJawAngle - p.angle));
  }

  /// The jaw's front tip at [gape] (swung by [openBy] if given), in the
  /// head's frame.
  static Offset jawFront(double gape, {double? openBy}) =>
      _hinge + DragonKit.turn(_jawTip - _hinge, -(openBy ?? open(gape)));

  /// The great horn's tip and the circlet's tallest point for [p], in rig
  /// units (for clearance checks against the wing arm).
  static Offset hornTip(DragonHeadPose p) => point(p, _liftedHornTip(p));

  static Offset _liftedHornTip(DragonHeadPose p) =>
      _hornRoot +
      DragonKit.turn(_hornSpine.last - _hornRoot, hornLift(p)) * hornSquash(p);
  static Offset crownTop(DragonHeadPose p) => point(
    p,
    crownSeat +
        DragonKit.turn(_crownTip(_crownFront), DragonLayout.headCrownTurn),
  );

  /// The lowest points of the lower jaw at [gape] in the head's frame: its
  /// tip, two belly points and the chin tusks' tips. They reach toward the
  /// reaching foreleg in the low-lane strikes, so each is kept clear of it.
  static List<Offset> chinPoints(DragonHeadPose p) {
    Offset swung(Offset v) => _hinge + DragonKit.turn(v - _hinge, -openFor(p));
    return [
      swung(_jawTip),
      swung(const Offset(-1.10, .575)),
      swung(const Offset(-.60, .615)),
      swung(const Offset(-1.25, .81)),
      swung(const Offset(-.82, .78)),
    ];
  }

  /// The horn's spine in the head's frame, root to tip (for value checks).
  static List<Offset> get hornSpine => _hornSpine;

  /// The extremities that stick out behind the skull, in the head's frame:
  /// the horn's tip, the frill's tips and the cheek spike's. In the rear-back
  /// poses they swing toward the wing arms, so each is kept short of them.
  static List<Offset> reachFor(DragonHeadPose p) => [
    _liftedHornTip(p),
    ..._frill.tips,
    const Offset(.66, .46),
  ];

  // ------------------------------------------------------- static shapes --

  static const _jawTip = Offset(-1.54, .26);

  /// The jaw's back-bottom corner, where the throat's line meets its own.
  static const _jawCorner = Offset(.36, .64);

  /// The jaw's underside a little in front of the corner (the direction the
  /// fillet rolls into), and the fillet's radius in rig units.
  static const _jawUnderside = Offset(.16, .655);
  static const _filletRadius = .44;

  /// The skull in the head's frame (rig units, snout to -x): a domed
  /// cranium, a brow shelf, a stop, a short heavy muzzle and the upper lip.
  static const _skullPts = <Offset>[
    Offset(.70, .20),
    Offset(.77, -.18),
    Offset(.62, -.63),
    Offset(.24, -.89),
    Offset(-.16, -.90),
    Offset(-.52, -.78),
    Offset(-.82, -.58),
    Offset(-1.00, -.42),
    Offset(-1.20, -.43),
    Offset(-1.40, -.33),
    Offset(-1.56, -.18),
    Offset(-1.60, -.02),
    Offset(-1.42, .163),
    Offset(-.90, .19),
    Offset(-.40, .22),
    Offset(.10, .28),
    Offset(.44, .44),
    Offset(.66, .42),
  ];
  static final _skull = DragonKit.spline(_skullPts, sharp: {0, 12, 15});

  /// The same outline drawn a hair inside the ink, for the fury's ember rim.
  static final _skullUpperIn = DragonKit.spline([
    for (final q in _skullPts.sublist(2, 12)) q + (Offset.zero - q) * .045,
  ], closed: false);

  /// The skull's outline above the mouth: the sky's rim light rides it.
  static final _skullUpper = DragonKit.spline(
    _skullPts.sublist(2, 12),
    closed: false,
  );

  static const _jawPts = <Offset>[
    Offset(.34, .26),
    Offset(-.40, .23),
    Offset(-1.40, .17),
    Offset(-1.54, .26),
    Offset(-1.50, .50),
    Offset(-1.10, .575),
    Offset(-.60, .615),
    Offset(-.10, .67),
    Offset(.16, .655),
    Offset(.36, .64),
    Offset(.50, .52),
    Offset(.52, .46),
  ];
  static final _jaw = DragonKit.spline(_jawPts, sharp: {0, 2});

  /// The jaw's outline without its back edge, so the belly band flows on
  /// into the throat without an ink bar across it.
  static final _jawInk = DragonKit.spline(
    const [
      Offset(.36, .64),
      Offset(.16, .655),
      Offset(-.10, .67),
      Offset(-.60, .615),
      Offset(-1.10, .575),
      Offset(-1.50, .50),
      Offset(-1.54, .26),
      Offset(-1.40, .17),
      Offset(-.40, .23),
      Offset(.34, .26),
    ],
    closed: false,
    sharp: {6},
  );

  /// The amber belly plates that run under the chin and on into the throat:
  /// the same colour and width as the neck's throat band, so chin -> throat
  /// is one strip.
  static const _jawBandOuter = <Offset>[
    Offset(-1.50, .38),
    Offset(-1.50, .50),
    Offset(-1.10, .575),
    Offset(-.60, .615),
    Offset(-.10, .67),
    Offset(.16, .655),
    Offset(.36, .64),
  ];
  static const _jawBandWidths = <double>[.05, .11, .16, .18, .2, .22, .23];
  static final _jawBandInner = () {
    final inner = _inset(_jawBandOuter, _jawBandWidths, const Offset(-.4, .3));
    // The band ends square with the neck's throat band, which leaves the
    // jaw at this corner across the same width (the neck's axis at the joint
    // is the handle, (.87, .5)): chin -> throat is one strip.
    inner[inner.length - 1] = _jawBandOuter.last + const Offset(.115, -.2);
    return inner;
  }();
  static final _jawBand = _ribbon(_jawBandOuter, _jawBandInner);

  /// The jaw's belly plates as two polylines in rig units for [p] (the outer
  /// edge on the jaw's contour, the inner edge across the plates), chin to
  /// throat, swung open with the jaw: the start of the hide's one belly band.
  static (List<Offset>, List<Offset>) jawBandEdges(DragonHeadPose p) {
    final open = openFor(p);
    Offset rig(Offset v) =>
        point(p, _hinge + DragonKit.turn(v - _hinge, -open));
    return (
      [for (final v in _jawBandOuter) rig(v)],
      [for (final v in _jawBandInner) rig(v)],
    );
  }

  /// Plate seams across the jaw band.
  static final _jawSeams = () {
    final p = Path();
    for (final (x, y, dx, dy) in const [
      (-1.30, .53, .02, -.15),
      (-1.04, .595, .01, -.18),
      (-.78, .61, 0.0, -.2),
      (-.52, .635, 0.0, -.21),
      (-.26, .655, -.01, -.22),
      (-.02, .67, -.01, -.22),
      (.20, .65, .05, -.2),
    ]) {
      p
        ..moveTo(x, y)
        ..lineTo(x + dx, y + dy);
    }
    return p;
  }();

  /// Three teeth rising from the lower jaw (hidden when it shuts, they bite
  /// between the upper ones) and two dark-bone chin tusks: one path, painted
  /// with one gradient that darkens from the teeth down to the tusks.
  static final _jawBone = () {
    final p = Path();
    // (Open at the base: the fill closes it, and the ink then leaves no bar
    // across a root that shows between the jaws.)
    _thorn(
      p,
      const Offset(-1.24, .30),
      const Offset(-1.22, .00),
      .15,
      openBase: true,
    );
    _thorn(
      p,
      const Offset(-.64, .30),
      const Offset(-.64, .03),
      .17,
      curl: -.02,
      openBase: true,
    );
    _thorn(
      p,
      const Offset(-.28, .30),
      const Offset(-.28, .10),
      .11,
      openBase: true,
    );
    _thorn(
      p,
      const Offset(-1.10, .57),
      const Offset(-1.25, .81),
      .2,
      curl: .06,
      openBase: true,
    );
    _thorn(
      p,
      const Offset(-.74, .625),
      const Offset(-.82, .78),
      .16,
      curl: .06,
      openBase: true,
    );
    return p;
  }();

  /// The tusk curling up from the chin in front of the snout.
  static final _tusk = Path()
    ..moveTo(-1.30, .50)
    ..quadraticBezierTo(-1.80, .38, -1.66, -.02)
    ..quadraticBezierTo(-1.60, .16, -1.50, .34)
    ..close();

  /// The brow: a dark visor plate over the eye that slants down toward the
  /// snout and ends in a hooked point over the temple.
  static final _brow = DragonKit.spline(
    const [
      Offset(-1.05, -.38),
      Offset(-.70, -.64),
      Offset(-.30, -.77),
      Offset(.12, -.84),
      Offset(.50, -.76),
      Offset(.14, -.62),
      Offset(-.26, -.55),
      Offset(-.64, -.47),
    ],
    sharp: {0, 4},
  );

  /// The brow's lit upper edge.
  static final _browLight = DragonKit.spline(const [
    Offset(-.90, -.50),
    Offset(-.66, -.65),
    Offset(-.30, -.77),
    Offset(.12, -.83),
  ], closed: false);

  /// The great horn: a compact crescent that stands behind the circlet,
  /// rises off the dome and sweeps its tip back. Painted BEHIND the skull, so
  /// the dome's outline swallows the root. It sweeps to x = 1.04 (tip at
  /// -1.03), no higher than -1.2 (the head's top is the envelope's) and no
  /// further (in the head-up poses the tip keeps .19 clear of the wing arm,
  /// measured against the arm as it is drawn).
  static final _hornSpine = <Offset>[
    for (var i = 0; i <= 8; i++)
      DragonKit.bezier(
        const Offset(.30, -.60),
        const Offset(.62, -1.05),
        const Offset(1.10, -1.22),
        const Offset(1.42, -1.02),
        i / 8,
      ),
  ];
  static final _hornWidths = <double>[
    for (var i = 0; i <= 8; i++) .52 * math.pow(1 - i / 8, .95),
  ];
  static final _horn = DragonKit.tube(_hornSpine, _hornWidths);

  /// Two fine slanted growth rings across the horn (not bandages).
  static final _hornRings = () {
    final rings = Path();
    for (final i in const [2, 6]) {
      final a = Offset.lerp(_hornSpine[i], _hornSpine[i + 1], .5)!;
      final d = DragonKit.unit(_hornSpine[i + 1] - _hornSpine[i - 1]);
      final n = Offset(-d.dy, d.dx);
      final w = _hornWidths[i] * .42;
      final from = a + n * w - d * .04;
      final to = a - n * w + d * .04;
      rings
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(a.dx + d.dx * .05, a.dy + d.dy * .05, to.dx, to.dy);
    }
    return rings;
  }();

  /// The hard white glint on the horn's lit edge, ending short of the tip.
  static final _hornGlint = () {
    final (a, b) = DragonKit.tubeEdges(_hornSpine, _hornWidths);
    final top = a[4].dy < b[4].dy ? a : b;
    return DragonKit.spline([
      for (var i = 3; i <= 6; i++) Offset.lerp(top[i], _hornSpine[i], .45)!,
    ], closed: false);
  }();

  /// Crisp pill glints: down the bridge of the snout and along the brow's
  /// top (the house style's hard white "gloss", not a soft sheen).
  static final _snoutGlint = Path()
    ..moveTo(-1.37, -.23)
    ..quadraticBezierTo(-1.27, -.29, -1.14, -.335);
  static final _browGlint = Path()
    ..moveTo(-.66, -.665)
    ..quadraticBezierTo(-.52, -.72, -.36, -.75);

  /// A gold ring clasped round the great horn, echoing the circlet.
  static final _hornRing = () {
    final a = _hornSpine[4];
    final d = DragonKit.unit(_hornSpine[5] - _hornSpine[3]);
    final n = Offset(-d.dy, d.dx);
    final half = _hornWidths[4] / 2 + .04;
    return Path()
      ..moveTo(a.dx + n.dx * half - d.dx * .06, a.dy + n.dy * half - d.dy * .06)
      ..lineTo(a.dx + n.dx * half + d.dx * .06, a.dy + n.dy * half + d.dy * .06)
      ..lineTo(a.dx - n.dx * half + d.dx * .06, a.dy - n.dy * half + d.dy * .06)
      ..lineTo(a.dx - n.dx * half - d.dx * .06, a.dy - n.dy * half - d.dy * .06)
      ..close();
  }();

  /// The dark cheek spike behind the hinge.
  static final _cheekSpike = DragonKit.tube(
    const [Offset(.52, .30), Offset(.60, .34), Offset(.66, .46)],
    const [.26, .13, .02],
  );

  /// Cheek armour: a soft chamfered shield behind the eye with three gill
  /// strokes fanned about the jaw hinge (like the muscle that drives it).
  static final _cheekPlate = Path()
    ..moveTo(.10, -.50)
    ..lineTo(.46, -.56)
    ..lineTo(.70, -.34)
    ..lineTo(.72, .08)
    ..lineTo(.56, .30)
    ..lineTo(.22, .32)
    ..lineTo(.04, .10)
    ..lineTo(.00, -.26)
    ..close();
  static final _cheekLines = () {
    final p = Path();
    for (final r in const [.34, .44, .54]) {
      final pts = [
        for (var i = 0; i <= 3; i++)
          _hinge + DragonKit.heading(-1.72 + .62 * i / 3) * r,
      ];
      p.addPath(DragonKit.spline(pts, closed: false), Offset.zero);
    }
    return p;
  }();

  /// Plate seams across the snout, bowed back, like a crocodile's scutes.
  static final _scutes = () {
    final p = Path();
    for (final x in const [-1.32, -1.10]) {
      p
        ..moveTo(x - .05, -.48)
        ..quadraticBezierTo(x + .07, -.16, x - .01, .15);
    }
    return p;
  }();

  /// The lip's molten seam.
  static final _seams = DragonKit.spline(const [
    Offset(-1.30, .13),
    Offset(-.90, .155),
    Offset(-.50, .175),
    Offset(-.15, .21),
  ], closed: false);

  /// The skull's shadow side: below a line that runs from the nostril to the
  /// hinge and up the back of the head, the light no longer reaches.
  static final _shade = Path()
    ..moveTo(-1.7, -.02)
    ..quadraticBezierTo(-1.1, -.12, -.5, -.02)
    ..quadraticBezierTo(-.05, .04, .18, -.32)
    ..quadraticBezierTo(.42, -.62, .9, -.5)
    ..lineTo(.9, .7)
    ..lineTo(-1.7, .7)
    ..close();

  /// Fangs hang from the upper jaw: a small incisor, the great canine, then
  /// a stepped row that fades toward the hinge.
  static final _teeth = () {
    final p = Path();
    for (final (x, len, w, lean) in const [
      (-1.32, .14, .10, .0),
      (-1.02, .40, .19, .05),
      (-.72, .16, .11, .0),
      (-.46, .28, .14, .03),
      (-.20, .15, .11, .02),
    ]) {
      final y = .17 + (x + 1.42) * .0724;
      _thorn(p, Offset(x, y - .01), Offset(x + lean, y + len), w);
    }
    return p;
  }();

  /// The ruff behind the cheek: five bone spines with a scalloped membrane
  /// between them, hugging the back of the skull. It hides the seam where
  /// the neck meets the head, and stays short of the wing arms.
  static const _frillRoot = Offset(.50, .04);
  static final _frill = () {
    // Four spines, the tallest in front: it is a fan behind the cheek, not
    // a comb (the silhouette's crest is the horn, the circlet and the neck's
    // three thorns).
    const spines = [(-1.0, .5), (-.42, .5), (.14, .42), (.78, .34)];
    final tips = [
      for (final (angle, len) in spines)
        _frillRoot + DragonKit.heading(angle) * len,
    ];
    final fan = Path()..moveTo(_frillRoot.dx, _frillRoot.dy - .12);
    for (var i = 0; i < tips.length; i++) {
      fan.lineTo(tips[i].dx, tips[i].dy);
      if (i + 1 < tips.length) {
        final mid = Offset.lerp(tips[i], tips[i + 1], .5)!;
        final pull = Offset.lerp(mid, _frillRoot, .26)!;
        fan.quadraticBezierTo(pull.dx, pull.dy, tips[i + 1].dx, tips[i + 1].dy);
      }
    }
    fan
      ..lineTo(_frillRoot.dx, _frillRoot.dy + .2)
      ..close();
    final bones = Path();
    for (final tip in tips) {
      _thorn(
        bones,
        _frillRoot,
        tip + DragonKit.unit(tip - _frillRoot) * .05,
        .085,
        curl: .04,
      );
    }
    return (fan: fan, bones: bones, tips: tips);
  }();

  /// The eye, in its own frame: the socket (an almond) with its corners and
  /// control points, a swept-back liner at the outer corner, the catchlights.
  static const _eyeFront = Offset(-.42, .06), _eyeBack = Offset(.42, -.14);
  static const _eyeTop = Offset(-.05, -.40), _eyeBottom = Offset(.05, .28);
  static final _socket = Path()
    ..moveTo(_eyeFront.dx, _eyeFront.dy)
    ..quadraticBezierTo(_eyeTop.dx, _eyeTop.dy, _eyeBack.dx, _eyeBack.dy)
    ..quadraticBezierTo(
      _eyeBottom.dx,
      _eyeBottom.dy,
      _eyeFront.dx,
      _eyeFront.dy,
    )
    ..close();
  static final _liner = () {
    final p = Path();
    _thorn(
      p,
      const Offset(.34, -.12),
      const Offset(.86, -.36),
      .085,
      curl: -.08,
    );
    return p;
  }();
  static const _eyeScale = 1.15;
  static const _catchY = -.035, _catchR = .068;
  static final _catchlights = Path()
    ..addOval(
      Rect.fromCircle(center: const Offset(-.235, _catchY), radius: _catchR),
    )
    ..addOval(Rect.fromCircle(center: const Offset(.13, .04), radius: .026));

  static final _nostrilSlit = Path()
    ..moveTo(-1.46, -.14)
    ..quadraticBezierTo(-1.36, -.36, -1.20, -.22)
    ..quadraticBezierTo(-1.34, -.24, -1.46, -.14)
    ..close();

  // ---------------------------------------------------------------- cache --

  static final Map<Object, Paint> _paints = {};

  /// A paint kept between frames under [key] (see [_tk]). Gradients are
  /// authored in the head's frame (or, for the neck, the rig's) so one paint
  /// serves every pose. Bounded (a tone has ~30 looks; a whole fight visits a
  /// few hundred) so a long session cannot grow it without limit.
  static Paint _paint(Object key, Paint Function() make) {
    var p = _paints[key];
    if (p == null) {
      if (_paints.length >= _cacheLimit) {
        // Drop the oldest quarter (insertion order), not everything: a
        // wholesale clear would rebuild every shader in the next frame.
        final old = _paints.keys.take(_cacheLimit ~/ 4).toList();
        old.forEach(_paints.remove);
      }
      p = _paints[key] = make();
    }
    return p;
  }

  static const _cacheLimit = 480;

  /// How many paints the head keeps between frames (a test bounds it).
  static int get debugCacheEntries => _paints.length + _inks.length;

  /// [v] if it is a finite number, else [or].
  static double _fin(double v, [double or = 0]) => v.isFinite ? v : or;

  static int _q(double v, double steps) => v.isFinite ? (v * steps).round() : 0;

  /// [p] if every channel is a finite number, else a copy with the bad ones
  /// replaced by their rest values: a stray NaN or infinity in the boss clock
  /// must never throw from a quantiser or paint a NaN.
  static DragonHeadPose _safe(DragonHeadPose p) {
    final sum =
        p.time +
        p.at.dx +
        p.at.dy +
        p.angle +
        p.gape +
        p.glare +
        p.look +
        p.blink +
        p.wince +
        p.throat +
        p.smoke +
        p.roar +
        p.call +
        p.alert +
        p.drag.dx +
        p.drag.dy +
        p.coil +
        p.tone.flash +
        p.tone.fury +
        p.tone.heat +
        p.tone.dark;
    if (sum.isFinite) return p;
    final okAt = p.at.dx.isFinite && p.at.dy.isFinite;
    return DragonHeadPose(
      time: _fin(p.time),
      at: okAt ? p.at : DragonLayout.headRest,
      angle: _fin(p.angle, DragonLayout.headRestAngle),
      gape: _fin(p.gape),
      glare: _fin(p.glare),
      look: _fin(p.look),
      blink: _fin(p.blink),
      wince: _fin(p.wince),
      throat: _fin(p.throat),
      smoke: _fin(p.smoke),
      roar: _fin(p.roar),
      call: _fin(p.call),
      alert: _fin(p.alert),
      drag: p.drag.dx.isFinite && p.drag.dy.isFinite ? p.drag : Offset.zero,
      coil: _fin(p.coil),
      dizzy: p.dizzy,
      crown: p.crown,
      tone: _safeTone(p.tone),
    );
  }

  /// [t] with any non-finite channel zeroed (so a stray NaN in the clock
  /// cannot throw from a quantiser or a lerp).
  static DragonTone _safeTone(DragonTone t) =>
      t.flash.isFinite && t.fury.isFinite && t.heat.isFinite && t.dark.isFinite
      ? t
      : DragonTone(
          flash: _fin(t.flash),
          fury: _fin(t.fury),
          heat: _fin(t.heat),
          dark: _fin(t.dark),
          sky: t.sky,
        );

  /// The tone's look, quantised: the parts that change a plate's colour.
  static (int, int, int) _tk(DragonTone t) =>
      (_q(t.flash, 5), _q(t.fury, 6), _q(t.dark, 3));

  static final Map<int, Paint> _inks = {};

  /// The ink paint for [width] (quantised to 1/1000 unit, few distinct
  /// widths exist; bounded all the same: paints 480 + inks 32 = 512).
  static Paint _ink1(double width) {
    final k = (width * 1000).round();
    var p = _inks[k];
    if (p == null) {
      if (_inks.length >= 32) _inks.clear();
      p = _inks[k] = DragonKit.line(_ink, k / 1000);
    }
    return p;
  }

  // ----------------------------------------------------------------- neck --

  /// The nine spine samples of the neck for [p], from the chest to the joint.
  /// [DragonLayout.neckSpine] eased by [passes] rounds of neighbour averaging
  /// (the ends stay exactly where the layout puts them): in the low-lane
  /// strikes the head sits nearly on the chest and the raw curve doubles back
  /// tighter than the neck is wide, so its inner edge would fold.
  static List<Offset> neckSpine(DragonHeadPose p, {int passes = 2}) {
    p = _safe(p);
    var spine = DragonLayout.neckSpine(
      point(p, _joint),
      p.angle,
      drag: p.drag,
      coil: p.coil,
    );
    // The two samples at each end stay as the layout puts them: the tube
    // leaves the breastplate and meets the skull on the curve's own tangent.
    for (var k = 0; k < passes; k++) {
      spine = [
        for (var i = 0; i < spine.length; i++)
          i < 2 || i > spine.length - 3
              ? spine[i]
              : spine[i - 1] * .25 + spine[i] * .5 + spine[i + 1] * .25,
      ];
    }
    return spine;
  }

  /// The neck's geometry for [p]: the spine, the widths either side (held
  /// short of a tight bend's radius), the crest and throat edges (the throat
  /// edge runs straight into the jaw's back corner) and the outline.
  static DragonNeck neckOf(DragonHeadPose p) {
    p = _safe(p);
    final spine = neckSpine(p);
    const widths = DragonLayout.neckWidths;
    final n = spine.length;
    final nrm = <Offset>[];
    // Half widths per side: on the inside of a tight bend the tube would fold
    // over itself, so that side is held to 85% of the bend's radius.
    final plus = <double>[], minus = <double>[];
    // The tube meets the skull along the curve's true tangent there (the
    // handle, turned with the head), not the chord of the last two samples,
    // so its throat edge lands on the jaw's corner at any turn of the head.
    final endTangent = DragonKit.unit(
      -(DragonKit.turn(DragonLayout.neckHandle, -p.angle) + p.drag * .35),
    );
    for (var i = 0; i < n; i++) {
      final a = spine[i == 0 ? 0 : i - 1], b = spine[i == n - 1 ? i : i + 1];
      final d = i == n - 1 ? endTangent : DragonKit.unit(b - a);
      nrm.add(Offset(-d.dy, d.dx));
      var hp = widths[i] / 2, hm = widths[i] / 2;
      if (i > 0 && i < n - 1) {
        final s0 = spine[i] - spine[i - 1], s1 = spine[i + 1] - spine[i];
        final cross = s0.dx * s1.dy - s0.dy * s1.dx;
        final turn = math.atan2(cross, s0.dx * s1.dx + s0.dy * s1.dy);
        if (turn.abs() > 1e-3) {
          final radius = (s0.distance + s1.distance) / 2 / turn.abs();
          if (cross > 0) {
            hp = math.min(hp, radius * .85);
          } else {
            hm = math.min(hm, radius * .85);
          }
        }
      }
      plus.add(hp);
      minus.add(hm);
    }
    final g = DragonNeck._(spine, nrm, plus, minus);
    final crestEdge = g.along(1);
    // The throat's edge climbs the front of the neck and then runs straight
    // into the jaw's back corner, where the jaw's own contour takes over: a
    // clean inside corner however the head is turned. (Left to itself the
    // tube's edge sweeps a hook round the bend at the skull.)
    final throatEdge = g.along(-1);
    final corner = point(p, _jawCorner);
    // The straight run into the corner starts where the throat edge is still
    // .26 clear of it (u = 6.5 at most, u = 3.5 at least): a neck that comes
    // up right under the jaw, as the S neck does, would otherwise leave a
    // run a few hundredths long whose direction is noise (the belly band
    // takes its turn from it).
    var from = 13;
    while (from > 7 && (throatEdge[from] - corner).distance < .26) {
      from--;
    }
    for (var i = from + 1; i < throatEdge.length; i++) {
      throatEdge[i] = Offset.lerp(
        throatEdge[from],
        corner,
        (i - from) / (throatEdge.length - 1 - from),
      )!;
    }
    // The inside corner between the jaw's underside and the neck's front is
    // rounded (a fillet of radius _filletRadius, never a right angle): the
    // outline leaves the neck early and rolls into the underside.
    final fillet = List<Offset>.of(throatEdge);
    // The fillet starts at the last throat sample at least the radius short
    // of the corner and rolls into the jaw's underside from there.
    var j0 = from;
    while (j0 > from && (throatEdge[j0] - corner).distance < _filletRadius) {
      j0--;
    }
    final p0 = throatEdge[j0];
    final reach = (p0 - corner).distance;
    if (reach > .12) {
      final d0 = DragonKit.unit(throatEdge[j0] - throatEdge[j0 - 1]);
      final jd = DragonKit.unit(point(p, _jawUnderside) - corner);
      final end = corner + jd * math.min(_filletRadius, reach * .9);
      final k = (end - p0).distance * .5;
      final a = p0 + d0 * k, b = end - jd * k;
      final last = fillet.length - 1;
      for (var i = j0 + 1; i <= last; i++) {
        fillet[i] = DragonKit.bezier(p0, a, b, end, (i - j0) / (last - j0));
      }
    }
    g
      ..crestEdge = crestEdge
      ..throatEdge = throatEdge
      ..filletEdge = fillet;
    return g;
  }

  /// The crest spines, drawn BEFORE the neck so it covers their roots: dark
  /// bone, raked back and up, biggest at the shoulders.
  static void neckSpikes(Canvas c, DragonTone tone, DragonNeck g) {
    final at = g.at, nrm = g.nrm;
    final spikes = Path();
    // A deliberate sweep, not a comb: three thorns that diminish from the
    // shoulders to the skull (the great horn and the circlet carry the top of
    // the head), raked back along the neck's own line.
    for (final (u, len) in const [(2.8, .30), (4.5, .22), (6.1, .15)]) {
      final root = at(u, .96);
      final i = u.floor();
      final normal = DragonKit.unit(Offset.lerp(nrm[i], nrm[i + 1], u - i)!);
      final out = DragonKit.unit(normal * .55 + const Offset(.7, -.25) * .6);
      _thorn(spikes, root, root + out * len, .17 + .1 * len, curl: -.1);
    }
    c.drawPath(spikes, DragonKit.fill(tone.lit(DragonPalette.boneDeep)));
    c.drawPath(spikes, _ink1(DragonLayout.inkPart));
  }

  /// The neck from the chest to the skull, with throat plates that fill with
  /// fire and spines along its crest. One tube from the fixed base to the
  /// joint: no ink cap at either end (the breastplate covers the base, the
  /// jaw the joint), and the throat band runs on into the jaw's belly band.
  static void neck(Canvas c, DragonHeadPose p) {
    p = _safe(p);
    final tone = p.tone;
    final g = neckOf(p);
    final spine = g.spine, minus = g.minus;
    final n = spine.length;
    final at = g.at;
    final along = g.along;
    final crestEdge = g.crestEdge, throatEdge = g.throatEdge;

    neckSpikes(c, tone, g);

    // The body: lit on the throat (sky) side, deep on the crest.
    c.drawPath(
      _ribbon(crestEdge, g.filletEdge),
      _paint(
        ('neck', _tk(tone)),
        () => DragonKit.linear(
          const Offset(-1.5, -2.3),
          const Offset(.9, -.3),
          [
            // A step darker than the skull, so the head stands out of it.
            tone.plate(
              Color.lerp(DragonPalette.scaleLit, DragonPalette.scale, .35)!,
            ),
            tone.plate(
              Color.lerp(DragonPalette.scale, DragonPalette.scaleDeep, .35)!,
            ),
            tone.plate(DragonPalette.scaleDeep),
          ],
          const [0, .5, 1],
        ),
      ),
    );
    // Core shade along the crest side.
    c.drawPath(
      DragonKit.spline(along(.76), closed: false),
      DragonKit.line(DragonPalette.scaleCore, .22, .3),
    );

    // Plates: overlapping chevron scutes across the neck, their points
    // toward the tail, the pitch shrinking toward the head (foreshortening).
    // A dark seam under a lit edge, half-strength: the neck is a tube, not a
    // ladder.
    final seamsPath = Path(), edgesPath = Path();
    for (final u in const [0.3, 1.4, 2.5, 3.55, 4.5, 5.35, 6.05, 6.7, 7.25]) {
      final a = at(u, .86), tip = at(u - .34, .16), d = at(u, -.3);
      seamsPath
        ..moveTo(a.dx, a.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(d.dx, d.dy);
      final a2 = at(u + .2, .8), tip2 = at(u - .14, .16), d2 = at(u + .2, -.28);
      edgesPath
        ..moveTo(a2.dx, a2.dy)
        ..lineTo(tip2.dx, tip2.dy)
        ..lineTo(d2.dx, d2.dy);
    }
    c.drawPath(
      seamsPath,
      DragonKit.line(tone.seam, .07, .08 + tone.glow * .25),
    );
    c.drawPath(
      seamsPath,
      _paint(('rows', _q(tone.dark, 3)), () {
        final p = DragonKit.linear(
          const Offset(-1.3, -2.0),
          const Offset(.7, -.5),
          [
            DragonPalette.scaleCore.withValues(alpha: .25),
            DragonPalette.scaleCore.withValues(alpha: .6),
            DragonPalette.scaleCore.withValues(alpha: .45),
          ],
          const [0, .5, 1],
        );
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = .055
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        return p;
      }),
    );
    c.drawPath(
      edgesPath,
      DragonKit.line(tone.lit(DragonPalette.scaleLit), .026, .42)
        ..strokeJoin = StrokeJoin.round,
    );

    // The throat plates, one banded amber strip down the front.
    final inner = [
      for (var u = 0.0; u <= 8 + 1e-6; u += .5)
        at(u, -1 + (.23 / minus[u.floor().clamp(0, n - 1)]).clamp(0.0, 1.6)),
    ];
    final band = _ribbon(throatEdge, inner);
    c.drawPath(
      band,
      _paint(
        ('throat', _tk(tone), _q(tone.heat, 4), _q(p.call, 4)),
        () => DragonKit.linear(
          const Offset(-1.2, -1.0),
          const Offset(-.1, -1.0),
          _bellyStops(tone, p.call).reversed.toList(),
        ),
      ),
    );
    // Fire rising in the throat lights the plates from below.
    if (p.throat > .02) {
      // The fire pulses in the throat once it is roaring (motion).
      final pulse = p.time == 0
          ? 1.0
          : .88 + .12 * math.sin(p.time * 9) * p.throat;
      c.drawPath(
        band,
        _paint(
          ('fire', _q(p.throat, 8)),
          () => DragonKit.linear(
            const Offset(0, -.1),
            Offset(-.2, -.1 - 2.2 * (p.throat * 1.15).clamp(0.0, 1.0)),
            [
              // Amber to orange, not lemon: the eye is the brightest thing.
              DragonPalette.flameGold.withValues(alpha: .7),
              DragonPalette.flame.withValues(alpha: .55),
              DragonPalette.flame.withValues(alpha: 0),
            ],
            const [0, .7, 1],
          ),
        )..color = DragonPalette.white.withValues(alpha: pulse.clamp(0.0, 1.0)),
      );
    }
    final seams = Path();
    for (final u in const [
      0.5,
      1.5,
      2.5,
      3.4,
      4.25,
      5.05,
      5.75,
      6.4,
      7.0,
      7.55,
    ]) {
      final a = at(u, -1.02);
      final b = at(u - .1, -1 + (.23 / minus[u.floor()]).clamp(0.0, 1.6));
      seams
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    c.drawPath(
      seams,
      DragonKit.line(tone.lit(DragonPalette.bellyDark), .03, .55),
    );

    // Sky light on the crest.
    c.drawPath(
      DragonKit.spline(along(.9), closed: false),
      DragonKit.line(tone.lit(tone.sky), .07, tone.skyRim * .8),
    );

    // Outer contour: heavier on the shade side (the crest), no cap at either
    // end.
    c.drawPath(
      DragonKit.spline(crestEdge, closed: false),
      _ink1(DragonLayout.inkHero),
    );
    c.drawPath(
      DragonKit.spline(g.filletEdge, closed: false),
      _ink1(DragonLayout.inkHero * .72),
    );
  }

  // ----------------------------------------------------------------- head --

  /// The head: far horn, ruff, jaws, skull, teeth, eye, brow, horns and the
  /// circlet, with the fire in its jaws.
  static void head(Canvas c, DragonHeadPose p) {
    p = _safe(p);
    final tone = p.tone;
    c.save();
    c.translate(p.at.dx, p.at.dy);
    c.rotate(-p.angle);
    c.scale(scale);
    _horns(c, tone, hornLift(p), hornSquash(p));
    _frillPaint(c, p);
    c.drawPath(
      _cheekSpike,
      DragonKit.fill(tone.plate(DragonPalette.scaleDeep)),
    );
    c.drawPath(_cheekSpike, _ink1(DragonLayout.inkPart));
    // The jaw hinges open about the cheek.
    final open = openFor(p);
    if (p.gape > .02) _mouthInside(c, p, open);
    c.save();
    c.translate(_hinge.dx, _hinge.dy);
    c.rotate(-open);
    c.translate(-_hinge.dx, -_hinge.dy);
    _lowerJaw(c, p);
    c.restore();
    _skullPaint(c, p);
    // The tusk rides the jaw, curling up in front of the lip.
    c.save();
    c.translate(_hinge.dx, _hinge.dy);
    c.rotate(-open);
    c.translate(-_hinge.dx, -_hinge.dy);
    _tuskPaint(c, tone);
    c.restore();
    if (p.crown) _crownWorn(c, p);
    c.restore();
  }

  static void _tuskPaint(Canvas c, DragonTone tone) {
    c.drawPath(
      _tusk,
      _paint(
        ('tusk', _tk(tone)),
        () => DragonKit.linear(
          const Offset(-1.4, .4),
          const Offset(-1.66, -.02),
          [
            tone.lit(DragonPalette.boneDeep),
            tone.lit(DragonPalette.bone),
            tone.lit(DragonPalette.boneLit),
          ],
          const [0, .6, 1],
        ),
      ),
    );
    c.drawPath(_tusk, _ink1(DragonLayout.inkPart));
  }

  /// The circlet on the brow, in the head's frame.
  static void _crownWorn(Canvas c, DragonHeadPose p) {
    final tone = p.tone;
    c.save();
    c.translate(crownSeat.dx, crownSeat.dy);
    c.rotate(DragonLayout.headCrownTurn);
    // A slow glint crosses the ruby every few seconds (motion: none in
    // Reduced Motion).
    final glint = p.time == 0
        ? 0.0
        : math.pow(math.max(0.0, math.sin(p.time * 1.9 + .5)), 30).toDouble();
    crown(c, tone: tone, glint: glint);
    c.restore();
  }

  /// As the snout rises the skull turns the great horn's tip toward the wing
  /// arms, and the far wing's wrist sits right under it. The horn answers the
  /// turn the way a horn seen in perspective would: it lays back against it
  /// ([hornLift], radians, negative = counter-clockwise) and foreshortens
  /// ([hornSquash], 1 = full length). At rest and in every calm pose both are
  /// neutral, so the silhouette keeps its full great horn.
  static const _hornLiftK = .5, _hornSquashK = .5;
  static double _rearing(DragonHeadPose p) =>
      ((-_safe(p).angle - .05) / .35).clamp(0.0, 1.0);
  static double hornLift(DragonHeadPose p) =>
      _hornLiftK * math.min(0.0, _safe(p).angle);
  static double hornSquash(DragonHeadPose p) => 1 - _hornSquashK * _rearing(p);

  static const _hornRoot = Offset(.30, -.60);

  static void _horns(Canvas c, DragonTone tone, double lift, double squash) {
    c.save();
    c.translate(_hornRoot.dx, _hornRoot.dy);
    c.rotate(lift);
    c.scale(squash);
    c.translate(-_hornRoot.dx, -_hornRoot.dy);
    // The far horn, in shade, rising a little apart from the near one so the
    // pair reads as a crescent.
    c.save();
    c.translate(-.06, -.07);
    c.rotate(-.07);
    c.scale(.9);
    c.drawPath(
      _horn,
      DragonKit.fill(Color.lerp(_ink, tone.lit(DragonPalette.bone), .46)!),
    );
    c.drawPath(_horn, _ink1(DragonLayout.inkPart));
    c.restore();
    c.drawPath(
      _horn,
      _paint(
        ('horn', _tk(tone)),
        // Lit at the tip only: measured from the tip, the body is bone
        // (L* 76) and the root sinks into the skull's shade.
        () => DragonKit.radial(
          _hornSpine.last,
          1.25,
          [
            tone.lit(DragonPalette.boneLit),
            tone.lit(DragonPalette.bone),
            tone.lit(DragonPalette.boneDeep),
            tone.lit(DragonPalette.scaleDeep),
          ],
          const [0, .16, .54, 1],
        ),
      ),
    );
    c.drawPath(_hornRings, DragonKit.line(DragonPalette.boneTip, .03, .55));
    c.drawPath(_horn, _ink1(DragonLayout.inkPart * 1.2));
    c.drawPath(
      _hornGlint,
      DragonKit.line(DragonPalette.white, .04, tone.flash > .5 ? .3 : .85),
    );
    c.drawPath(
      _hornRing,
      _paint(
        ('ring', _q(tone.flash, 6)),
        () => DragonKit.linear(const Offset(.5, -1.1), const Offset(.8, -.85), [
          tone.lit(DragonPalette.goldLit),
          tone.lit(DragonPalette.gold),
          tone.lit(DragonPalette.goldDeep),
        ]),
      ),
    );
    c.drawPath(_hornRing, _ink1(.045));
    c.restore();
  }

  static void _frillPaint(Canvas c, DragonHeadPose p) {
    final tone = p.tone;
    // The frill lags the head and flutters a little.
    final sway =
        (p.time == 0 ? 0.0 : math.sin(p.time * 2.6) * .025) + p.drag.dy * .25;
    c.save();
    // It flares when the breath is coming and the dragon roars, and lies flat
    // in a flinch; kept short of the wing arms.
    final flare = (1 + .18 * p.alert + .08 * p.roar - .22 * p.wince).clamp(
      .75,
      1.2,
    );
    c.translate(_frillRoot.dx, _frillRoot.dy);
    c.rotate(sway);
    c.scale(flare);
    c.translate(-_frillRoot.dx, -_frillRoot.dy);
    c.drawPath(
      _frill.fan,
      _paint(
        ('frill', _tk(tone)),
        () => DragonKit.radial(
          _frillRoot,
          .8,
          [
            tone.burn(DragonPalette.membraneDeep, DragonPalette.flameDark),
            tone.burn(DragonPalette.membrane, DragonPalette.flame),
            tone.burn(DragonPalette.membraneLit, DragonPalette.flameGold),
          ],
          const [0, .6, 1],
        ),
      ),
    );
    c.drawPath(_frill.bones, DragonKit.fill(tone.lit(DragonPalette.scaleDeep)));
    c.drawPath(_frill.fan, _ink1(DragonLayout.inkMajor));
    c.restore();
  }

  /// The mouth's dark, glowing interior, behind both jaws.
  static void _mouthInside(Canvas c, DragonHeadPose p, double open) {
    final tone = p.tone;
    Offset turned(Offset v) => _hinge + DragonKit.turn(v - _hinge, -open);
    final a = turned(const Offset(-1.40, .17)),
        b = turned(const Offset(.30, .30));
    // The cavity's front is open to the sky: its edge bows back toward the
    // hinge as the jaws part.
    const upper = Offset(-1.42, .17);
    final mid = Offset.lerp(upper, a, .5)!;
    final bow = mid + Offset(.34 * (a - upper).distance, 0);
    final inside = Path()
      ..moveTo(.30, .24)
      ..lineTo(upper.dx, upper.dy)
      ..quadraticBezierTo(bow.dx, bow.dy, a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..close();
    final violet = p.call.clamp(0.0, 1.0);
    c.drawPath(
      inside,
      DragonKit.fill(
        Color.lerp(const Color(0xff4a1024), const Color(0xff2a1650), violet)!,
      ),
    );
    final heat = math.max(p.throat, tone.fury * .5);
    c.drawPath(
      inside,
      _paint(
        ('mouth', _q(heat, 6), _q(violet, 4)),
        () => DragonKit.radial(const Offset(-.1, .42), 1.2, [
          Color.lerp(
            DragonPalette.flameYellow,
            DragonPalette.call,
            violet,
          )!.withValues(alpha: .35 + heat * .65),
          Color.lerp(
            DragonPalette.flame,
            DragonPalette.callDeep,
            violet,
          )!.withValues(alpha: .3 + heat * .5),
          DragonPalette.flameDark.withValues(alpha: 0),
        ]),
      ),
    );
    // The gum under the upper lip.
    c.drawPath(
      Path()
        ..moveTo(-1.40, .23)
        ..lineTo(.10, .34),
      DragonKit.line(const Color(0xffd0566c), .1, (p.gape * 3).clamp(0.0, 1.0)),
    );
  }

  /// The sky's bounce along the skull's upper-left rim, inside the ink (the
  /// caller has clipped to the skull): [DragonKit.edge]'s sky half. The
  /// fire's half is the lip's molten seam. Above a hit flash of .35 the rim
  /// goes white so it still reads on a pale sky.
  static void _skyRim(Canvas c, Path upper, DragonTone tone) {
    const width = .1, shift = .06;
    final white = tone.flash > .35;
    final wide = white ? 1.5 : 1 + tone.dark * .5;
    c.save();
    c.translate(shift * .75, shift * .75);
    c.drawPath(
      upper,
      DragonKit.line(
        white ? DragonPalette.white : tone.sky,
        width * wide,
        white ? .9 : tone.skyRim,
      )..strokeCap = StrokeCap.butt,
    );
    c.restore();
  }

  /// The skull's surface detail, clipped to it: the shadow side, the smoky
  /// eye socket, the ember glow, the cheek armour, the snout's scutes, the
  /// circlet's contact shadow, the lip's molten seam and (on its own, [rim])
  /// the sky's bounce along the upper edge. In the hide the sky rim is the
  /// whole body's, so it passes [rim] false.
  static void _skullDetails(Canvas c, DragonHeadPose p, {required bool rim}) {
    final tone = p.tone;
    c.save();
    c.clipPath(_skull);
    // The shadow side, with a hard edge (cel); a smoky socket round the eye.
    c.drawPath(
      _shade,
      DragonKit.fill(DragonPalette.scaleCore, .22 * (1 - tone.fury * .6)),
    );
    c.drawPath(
      _skull,
      _paint(
        'socketAO',
        () => DragonKit.radial(eye, 1.0, [
          DragonPalette.scaleCore.withValues(alpha: .62),
          DragonPalette.scaleCore.withValues(alpha: 0),
        ]),
      ),
    );
    // Fury and the breath light the muzzle from inside: an ember glow rising
    // from the mouth, so the face stays readable as its plates heat.
    final ember = (tone.fury * .55 + p.throat * .4).clamp(0.0, .8);
    if (ember > .05) {
      c.drawPath(
        _skull,
        _paint(
          'ember',
          () => DragonKit.radial(
            const Offset(-1.25, .25),
            1.1,
            [
              DragonPalette.flame.withValues(alpha: .62),
              DragonPalette.furyPlateLit.withValues(alpha: .38),
              DragonPalette.furyPlateLit.withValues(alpha: 0),
            ],
            const [0, .5, 1],
          ),
        )..color = DragonPalette.white.withValues(alpha: ember),
      );
    }
    // Armour: the cheek shield with its ridges, the snout's scutes.
    c.drawPath(
      _cheekPlate,
      DragonKit.fill(tone.lit(DragonPalette.scaleLit), .1),
    );
    c.drawPath(_cheekLines, DragonKit.line(DragonPalette.scaleDark, .04, .6));
    c.drawPath(_scutes, DragonKit.line(DragonPalette.scaleDark, .04, .7));
    // The circlet's contact shadow on the dome.
    if (p.crown) {
      c.drawPath(
        _crownShadow,
        DragonKit.line(DragonPalette.scaleCore, .17, .55),
      );
    }
    // The lip glows only with the fire in the throat.
    final lipFire = p.throat * .8 + tone.fury * .45;
    if (lipFire > .05) {
      DragonKit.moltenSeam(
        c,
        _seams,
        tone,
        width: .04,
        alpha: lipFire.clamp(0.0, 1.0),
      );
    }
    // The fire's own rim along the snout and brow in fury: the face keeps a
    // lit outline when its plates go dark.
    if (tone.fury > .05) {
      c.drawPath(
        _skullUpperIn,
        _paint('emberRim', () {
            final q = DragonKit.linear(
              const Offset(-1.6, 0),
              const Offset(.75, 0),
              [
                DragonPalette.flameGold.withValues(alpha: .95),
                DragonPalette.flame.withValues(alpha: .75),
                DragonPalette.flame.withValues(alpha: 0),
              ],
              const [0, .5, 1],
            );
            q
              ..style = PaintingStyle.stroke
              ..strokeWidth = .07
              ..strokeCap = StrokeCap.butt;
            return q;
          })
          ..color = DragonPalette.white.withValues(
            alpha: (tone.fury * .85).clamp(0.0, .85),
          ),
      );
    }
    if (rim) _skyRim(c, _skullUpper, tone);
    // The hard white glint down the bridge of the snout.
    c.drawPath(
      _snoutGlint,
      DragonKit.line(DragonPalette.white, .045, tone.flash > .5 ? .3 : .8),
    );
    c.restore();
  }

  /// The upper fangs.
  static void _teethPaint(Canvas c, DragonTone tone) {
    // In fury the fangs blaze: bone lit to white, so the face's teeth read
    // against a dark, heated skull (and against the flash's bleached one).
    final fury = _q(tone.fury, 4);
    c.drawPath(
      _teeth,
      _paint(
        ('teeth', fury, _q(tone.flash, 6)),
        () => DragonKit.linear(
          const Offset(0, .15),
          const Offset(0, .5),
          [
            tone.lit(
              Color.lerp(DragonPalette.boneDeep, DragonPalette.bone, fury / 4)!,
            ),
            tone.lit(
              Color.lerp(DragonPalette.bone, DragonPalette.boneLit, fury / 4)!,
            ),
            tone.lit(
              Color.lerp(DragonPalette.boneLit, DragonPalette.white, fury / 4)!,
            ),
          ],
          const [0, .5, 1],
        ),
      ),
    );
    c.drawPath(_teeth, DragonKit.line(_ink, .035));
  }

  static void _skullPaint(Canvas c, DragonHeadPose p) {
    final tone = p.tone;
    c.drawPath(
      _skull,
      _paint(
        ('skull', _tk(tone)),
        () => DragonKit.linear(
          const Offset(-.95, -.9),
          const Offset(.6, .5),
          [
            tone.plate(
              Color.lerp(DragonPalette.scaleLit, DragonPalette.scaleSheen, .1)!,
            ),
            tone.plate(
              Color.lerp(DragonPalette.scaleLit, DragonPalette.scale, .55)!,
            ),
            tone.plate(DragonPalette.scaleDeep),
          ],
          const [0, .5, 1],
        ),
      ),
    );
    _skullDetails(c, p, rim: true);
    _teethPaint(c, p.tone);
    DragonKit.inkHero(c, _skull, .1);
    _nostril(c, p);
    _eye(c, p);
    _browPaint(c, p);
  }

  static void _nostril(Canvas c, DragonHeadPose p) {
    final tone = p.tone;
    // The nostrils flare with the breath (motion) and with the glare; the
    // ember tucked inside the hook flickers, and only blazes with the fire.
    final breathe = p.time == 0 ? 0.0 : math.sin(p.time * 2.2) * .5 + .5;
    final flick = p.time == 0 ? 0.0 : math.sin(p.time * 11) * .06;
    final flare = .02 * math.max(p.throat, p.glare) + .012 * breathe;
    c.drawPath(_nostrilSlit, DragonKit.fill(_ink));
    final ember = math.max(p.throat, p.alert * .5);
    c.drawCircle(
      nostril + const Offset(.02, .05),
      .028 + .016 * ember + flare * .5,
      DragonKit.fill(tone.seam, (ember * .9 + flick).clamp(0.0, 1.0)),
    );
  }

  static void _browPaint(Canvas c, DragonHeadPose p) {
    final tone = p.tone;
    // The ridge drops and slants down over the eye as it glares (never so far
    // that it buries it), lifts in a flinch, and settles for the roar.
    c.save();
    c.translate(.12, -.80);
    c.rotate(-.11 * p.glare + .12 * p.wince - .06 * p.roar);
    c.translate(-.12, .80 + .015 * p.glare + .02 * p.roar);
    c.drawPath(
      _brow,
      _paint(
        ('brow', _tk(tone)),
        () =>
            DragonKit.linear(const Offset(-.3, -.86), const Offset(-.3, -.5), [
              tone.plate(DragonPalette.scale),
              tone.plate(
                Color.lerp(DragonPalette.scale, DragonPalette.scaleDeep, .55)!,
              ),
            ]),
      ),
    );
    c.drawPath(_brow, _ink1(.075));
    c.drawPath(
      _browLight,
      DragonKit.line(
        Color.lerp(
          tone.lit(DragonPalette.scaleLit),
          DragonPalette.flame,
          tone.fury,
        )!,
        .03 + .01 * tone.fury,
        .55 + .3 * tone.fury,
      ),
    );
    c.drawPath(
      _browGlint,
      DragonKit.line(DragonPalette.white, .04, tone.flash > .5 ? .25 : .8),
    );
    c.restore();
  }

  static void _eye(Canvas c, DragonHeadPose p) {
    final tone = p.tone;
    // The glare (charge, the breath coming, fury) and, apart from it, fury
    // itself: the glare darkens the iris's rim, fury burns it white-hot.
    final glare = p.glare.clamp(0.0, 1.0), fury = tone.fury.clamp(0.0, 1.0);
    final hot = math.max(glare, fury);
    final dark = glare * (1 - fury);
    final roar = p.roar.clamp(0.0, 1.0), wince = p.wince.clamp(0.0, 1.0);
    // The lid: idle .10, alert .18, the glare .22; a roar squeezes it to
    // ~.36, a flinch adds .30 with the lower lid rising; a blink shuts it.
    // (The brow adds to it, so the eye keeps at least half its height open
    // however hard it glares: it is the first read.)
    final open = (.10 + .12 * hot + .26 * roar).clamp(0.0, .42);
    final lid = (open + .30 * wince).clamp(0.0, .6);
    final shut = (lid + .9 * p.blink).clamp(0.0, 1.0);
    final low = (wince * .9 + roar * .18).clamp(0.0, 1.0);
    c.save();
    c.translate(eye.dx, eye.dy);
    // The eye is the first read: 15% bigger than the socket the layout first
    // drew (its centre is the anchor and does not move).
    c.scale(_eyeScale);
    // The glow spills into the socket and onto the scales round it.
    c.save();
    c.scale(.52 + glare * .1 + fury * .28);
    c.drawCircle(
      Offset.zero,
      1,
      _paint(
          'eyeglow',
          () => DragonKit.radial(
            Offset.zero,
            1,
            [
              DragonPalette.flameYellow.withValues(alpha: 1),
              DragonPalette.flameGold.withValues(alpha: .45),
              DragonPalette.flame.withValues(alpha: 0),
            ],
            const [0, .45, 1],
          ),
        )
        ..color = DragonPalette.white.withValues(
          alpha: .3 + hot * .4 + fury * .2,
        ),
    );
    c.restore();
    c.rotate(-.22 - .14 * hot - .06 * roar);
    // The socket is a shadowed recess; a shut lid is skin, not a dark patch.
    c.drawPath(
      _socket,
      DragonKit.fill(
        Color.lerp(
          DragonPalette.scaleDark,
          tone.plate(DragonPalette.scale),
          shut * shut,
        )!,
      ),
    );
    c.drawPath(_socket, _ink1(.05 - .025 * (shut * 16).round() / 16));
    // The open part of the eye: the lid lowers its top edge, a flinch or a
    // roar raises the lower one.
    final topY = _eyeTop.dy + .62 * shut;
    final botY = math.max(_eyeBottom.dy - .32 * low, topY + .02);
    final top = Path()
      ..moveTo(_eyeFront.dx, _eyeFront.dy)
      ..quadraticBezierTo(
        _eyeTop.dx - .08 * hot,
        topY,
        _eyeBack.dx,
        _eyeBack.dy,
      );
    if (shut < .92) {
      final aperture = Path.from(top)
        ..quadraticBezierTo(_eyeBottom.dx, botY, _eyeFront.dx, _eyeFront.dy)
        ..close();
      c.drawPath(
        aperture,
        _paint(
          ('iris', _q(dark, 8), _q(fury, 8)),
          () => DragonKit.radial(
            const Offset(.0, -.02),
            .46,
            [
              DragonPalette.flameCore,
              Color.lerp(
                DragonPalette.flameYellow,
                DragonPalette.flameCore,
                fury * .75,
              )!,
              Color.lerp(
                Color.lerp(
                  DragonPalette.flameGold,
                  DragonPalette.flame,
                  dark * .5,
                )!,
                DragonPalette.flameYellow,
                fury * .8,
              )!,
              Color.lerp(
                Color.lerp(
                  DragonPalette.flame,
                  DragonPalette.flameDark,
                  dark * .8,
                )!,
                DragonPalette.flameGold,
                fury * .6,
              )!,
            ],
            const [0, .38, .7, 1],
          ),
        ),
      );
      // The lid's shadow across the top of the iris.
      c.drawPath(
        top,
        DragonKit.line(DragonPalette.scaleDark, .13, .42 * (1 - fury * .6))
          ..strokeCap = StrokeCap.butt,
      );
      // The lid itself: skin between the socket's brow and the lowered edge,
      // so a squint is a lid coming down over a bright eye, not a dark patch.
      if (shut > .03) {
        c.drawPath(
          Path()
            ..moveTo(_eyeFront.dx, _eyeFront.dy)
            ..quadraticBezierTo(
              _eyeTop.dx,
              _eyeTop.dy,
              _eyeBack.dx,
              _eyeBack.dy,
            )
            ..quadraticBezierTo(
              _eyeTop.dx - .08 * hot,
              topY,
              _eyeFront.dx,
              _eyeFront.dy,
            )
            ..close(),
          DragonKit.fill(
            tone.plate(
              Color.lerp(DragonPalette.scale, DragonPalette.scaleDeep, .4)!,
            ),
          ),
        );
      }
      if (!p.dizzy) {
        final py = p.look * .09;
        // Narrower as the glare tightens: a needle.
        final w = .04 + .03 * (1 - hot);
        // Where the lid's edge crosses the pupil (the quadratic's middle).
        final midTop = .25 * _eyeFront.dy + .5 * topY + .25 * _eyeBack.dy;
        final y0 = math.max(-.22 + py, midTop + .02), y1 = .14 + py;
        if (y1 > y0 + .04) {
          c.drawPath(
            Path()
              ..moveTo(-.05, y0)
              ..quadraticBezierTo(-.05 + w, (y0 + y1) / 2, -.05, y1)
              ..quadraticBezierTo(-.05 - w, (y0 + y1) / 2, -.05, y0)
              ..close(),
            DragonKit.fill(_ink),
          );
        }
      } else {
        c.drawPath(
          Path()
            ..moveTo(-.14, -.11)
            ..lineTo(.09, .07)
            ..moveTo(-.14, .07)
            ..lineTo(.09, -.11),
          DragonKit.line(_ink, .055),
        );
      }
      // The glints, only while the eye is open enough to hold them.
      // The catchlight is a hard opaque white pill in every state, kept
      // clear of the lid (it slides down as the lid comes down).
      final glint = ((1 - shut) * 2.2).clamp(0.0, 1.0);
      if (glint > .05) {
        final midTop = .25 * _eyeFront.dy + .5 * topY + .25 * _eyeBack.dy;
        final dy = math.max(0.0, midTop + .03 - (_catchY - _catchR));
        c.save();
        c.translate(0, dy);
        c.drawPath(_catchlights, DragonKit.fill(DragonPalette.white, glint));
        c.restore();
      }
    }
    c.drawPath(top, _ink1(.11));
    if (p.blink > .5) {
      // A shut lid is a bright seam under the heavy ink.
      c.save();
      c.translate(0, -.085);
      c.drawPath(
        top,
        DragonKit.line(tone.lit(DragonPalette.scaleSheen), .03, .55)
          ..strokeCap = StrokeCap.butt,
      );
      c.restore();
    }
    c.drawPath(_liner, DragonKit.fill(_ink));
    if (fury > .05) {
      // Fury: the lid rim burns.
      c.drawPath(
        top,
        DragonKit.line(
          Color.lerp(DragonPalette.flame, DragonPalette.flameYellow, .5)!,
          .055,
          fury * .95,
        ),
      );
    }
    c.restore();
  }

  /// The tongue, low in the jaw (in the jaw's frame), once the mouth opens.
  static void _tonguePaint(Canvas c, DragonHeadPose p) {
    if (p.gape > .05) {
      // The tongue, low in the jaw.
      final tongue = Path()
        ..moveTo(.30, .30)
        ..quadraticBezierTo(-.45, -.10 + .1 * (1 - p.gape), -1.22, .13)
        ..quadraticBezierTo(-.6, .30, .30, .38)
        ..close();
      c.drawPath(
        tongue,
        _paint(
          'tongue',
          () => DragonKit.linear(
            const Offset(-.4, -.05),
            const Offset(-.4, .34),
            [
              const Color(0xffff8f7c),
              const Color(0xffd0485a),
              const Color(0xff9c2a44),
            ],
            const [0, .5, 1],
          ),
        ),
      );
    }
  }

  /// The lower fangs and the chin tusks (in the jaw's frame).
  static void _jawBonePaint(Canvas c, DragonTone tone) {
    c.drawPath(
      _jawBone,
      _paint(
        ('jawbone', _tk(tone)),
        () => DragonKit.linear(
          const Offset(0, .02),
          const Offset(0, .88),
          [
            tone.lit(DragonPalette.boneLit),
            tone.lit(DragonPalette.bone),
            tone.lit(DragonPalette.boneDeep),
            tone.lit(DragonPalette.boneShade),
          ],
          const [0, .3, .68, 1],
        ),
      ),
    );
    c.drawPath(_jawBone, _ink1(.03));
  }

  static void _lowerJaw(Canvas c, DragonHeadPose p) {
    final tone = p.tone;
    _tonguePaint(c, p);
    c.drawPath(
      _jaw,
      _paint(
        ('jaw', _tk(tone)),
        () => DragonKit.linear(const Offset(0, .2), const Offset(0, .78), [
          tone.plate(DragonPalette.scale),
          tone.plate(DragonPalette.scaleDeep),
        ]),
      ),
    );
    c.drawPath(
      _jawBand,
      _paint(
        ('band', _tk(tone), _q(tone.heat, 4), _q(p.call, 4)),
        () => DragonKit.linear(
          const Offset(0, .48),
          const Offset(0, .8),
          _bellyStops(tone, p.call),
        ),
      ),
    );
    c.drawPath(
      _jawSeams,
      DragonKit.line(tone.lit(DragonPalette.bellyDark), .03, .55),
    );
    _jawBonePaint(c, tone);
    c.drawPath(_jawInk, _ink1(DragonLayout.inkMajor));
  }

  // ---------------------------------------------------------- the hide --
  // (B9) The skull, the jaw and the neck are painted with the torso and tail
  // as ONE hide (see dragon_hide_art.dart): these are the pieces it takes.

  /// [pts] wound counter-clockwise on screen (reversed if need be, the sharp
  /// corners moving with their vertices), as a closed spline.
  static Path _ccwSpline(List<Offset> pts, Set<int> sharp) {
    if (DragonKit.winding(pts) <= 0) return DragonKit.spline(pts, sharp: sharp);
    return DragonKit.spline(
      pts.reversed.toList(),
      sharp: {for (final i in sharp) pts.length - 1 - i},
    );
  }

  static final Path _skullCcw = _ccwSpline(_skullPts, const {0, 12, 15});
  static final Path _jawCcw = _ccwSpline(_jawPts, const {0, 2});

  /// The skull in rig units for [p].
  static Path skullAt(DragonHeadPose p) => _toRig(_skullCcw, _safe(p));

  /// The lower jaw in rig units for [p], swung open about the hinge.
  static Path jawAt(DragonHeadPose p) =>
      _toRig(DragonKit.turned(_jawCcw, -openFor(p), about: _hinge), _safe(p));

  static Path _toRig(Path local, DragonHeadPose p) {
    final cs = math.cos(p.angle) * scale, sn = math.sin(p.angle) * scale;
    // p' = at + turn(v * scale, -angle)
    return DragonKit.affine(local, cs, -sn, sn, cs, p.at.dx, p.at.dy);
  }

  static void _headFrame(Canvas c, DragonHeadPose p) {
    c.translate(p.at.dx, p.at.dy);
    c.rotate(-p.angle);
    c.scale(scale);
  }

  /// What lies BEHIND the skin: the great horns, the frill, the cheek spike,
  /// the mouth's dark inside with the tongue and the lower fangs. The skin
  /// covers their roots, so they grow out of it.
  static void headUnder(Canvas c, DragonHeadPose p) {
    p = _safe(p);
    final tone = p.tone;
    c.save();
    _headFrame(c, p);
    _horns(c, tone, hornLift(p), hornSquash(p));
    _frillPaint(c, p);
    c.drawPath(
      _cheekSpike,
      DragonKit.fill(tone.plate(DragonPalette.scaleDeep)),
    );
    c.drawPath(_cheekSpike, _ink1(DragonLayout.inkPart));
    final open = openFor(p);
    if (p.gape > .02) _mouthInside(c, p, open);
    c.save();
    c.translate(_hinge.dx, _hinge.dy);
    c.rotate(-open);
    c.translate(-_hinge.dx, -_hinge.dy);
    _tonguePaint(c, p);
    _jawBonePaint(c, tone);
    c.restore();
    c.restore();
  }

  /// The skull's surface detail (shade side, eye socket, ember, cheek armour,
  /// scutes, the circlet's shadow, the lip's fire), clipped to the skull.
  static void skullDetails(Canvas c, DragonHeadPose p) {
    p = _safe(p);
    c.save();
    _headFrame(c, p);
    _skullDetails(c, p, rim: false);
    c.restore();
  }

  /// The lower jaw sits in the skull's shade: a dark wash over it, deepest at
  /// the chin and gone by the hinge, so the jaw reads as a form under the
  /// skull though it wears the same skin. (In the jaw's own frame, swung open
  /// with it.)
  static void jawShade(Canvas c, DragonHeadPose p) {
    p = _safe(p);
    final tone = p.tone;
    c.save();
    _headFrame(c, p);
    c.translate(_hinge.dx, _hinge.dy);
    c.rotate(-openFor(p));
    c.translate(-_hinge.dx, -_hinge.dy);
    c.drawPath(
      _jawCcw,
      _paint(
        ('jawShade', _q(tone.dark, 3)),
        () => DragonKit.linear(
          const Offset(-1.55, 0),
          const Offset(.25, 0),
          [
            DragonPalette.scaleCore.withValues(alpha: .42),
            DragonPalette.scaleCore.withValues(alpha: .3),
            DragonPalette.scaleCore.withValues(alpha: 0),
          ],
          const [0, .55, 1],
        ),
      ),
    );
    c.restore();
  }

  /// The lip line: the mouth's closed seam, from the snout's tip to the
  /// cheek, a fine ink that swells at the front. Where the jaws part it lies
  /// on the skull's own lip.
  static final Path _mouthLine = () {
    const pts = [
      Offset(-1.55, .13),
      Offset(-1.42, .165),
      Offset(-1.16, .18),
      Offset(-.90, .195),
      Offset(-.65, .205),
      Offset(-.40, .225),
      Offset(-.15, .25),
      Offset(.10, .285),
      Offset(.28, .335),
    ];
    return DragonKit.ribbon(
      pts,
      DragonKit.taper(pts.length, .075, head: .08, tail: .45),
    );
  }();

  /// The head's features, over the skin: the upper fangs, the lip line, the
  /// nostril, the eye, the brow, the chin tusk and the circlet.
  static void headFeatures(Canvas c, DragonHeadPose p) {
    p = _safe(p);
    final tone = p.tone;
    c.save();
    _headFrame(c, p);
    _teethPaint(c, tone);
    c.drawPath(_mouthLine, DragonKit.fill(_ink));
    _nostril(c, p);
    _eye(c, p);
    _browPaint(c, p);
    // The tusk rides the jaw, curling up in front of the lip.
    final open = openFor(p);
    c.save();
    c.translate(_hinge.dx, _hinge.dy);
    c.rotate(-open);
    c.translate(-_hinge.dx, -_hinge.dy);
    _tuskPaint(c, tone);
    c.restore();
    if (p.crown) _crownWorn(c, p);
    c.restore();
  }

  // ---------------------------------------------------------------- crown --

  /// The circlet is a ring round the dome, seen from the side and a little
  /// from above while the head looks left. Angles go round the ring: 0 is
  /// the back of the skull (right), pi the snout's side (left), pi/2 the side
  /// nearest us and -pi/2 the far side. The band's lower edge is an ellipse
  /// whose near half dips over the dome and whose ends sit on the skull's
  /// line; the far half's inner face shows, in shade, above the near band.
  /// Its tallest point (the front, with the ruby) faces the way the dragon
  /// looks, so it sits at the left and turns away from us. Nothing is taller
  /// than the old circlet (-.45: the calm head already touches the top of
  /// the envelope, -3.72), and it stays inside [crownBounds] with the
  /// falling crown's .1 to spare.
  static const _ringX = .53, _ringY = .09, _ringDepth = .12;
  static const _ringTilt = -.08, _ringBand = .19;

  /// The band's lower edge at angle [a] round the ring.
  static Offset _ringFoot(double a) {
    final x = _ringX * math.cos(a);
    return Offset(x, _ringY + _ringDepth * math.sin(a) + _ringTilt * x);
  }

  /// The band's upper edge (where the points stand) at angle [a].
  static Offset _ringLip(double a) =>
      _ringFoot(a) - const Offset(0, _ringBand);

  /// The point's tip: [p] is (angle, half angle, height, lean back).
  static Offset _crownTip((double, double, double, double) p) {
    final (a, _, h, lean) = p;
    return _ringLip(a) + Offset(lean, -h);
  }

  /// One ogee point standing on the band's upper edge at angle [a], [s]
  /// either side of it: points facing us are wide, points turning toward an
  /// end of the ring narrow as they go edge-on. Drawn from its right corner
  /// to its left; [far] points are walked the other way round the ring.
  static void _crownPoint(
    Path path,
    (double, double, double, double) p, {
    bool far = false,
  }) {
    final (a, s, h, lean) = p;
    final right = _ringLip(far ? a + s : a - s);
    final left = _ringLip(far ? a - s : a + s);
    final tip = _crownTip(p);
    final x = (left.dx + right.dx) / 2, hb = (right.dx - left.dx) / 2;
    path
      ..lineTo(right.dx, right.dy)
      ..quadraticBezierTo(
        x + hb * .15 + lean * .8,
        tip.dy + h * .55,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        x - hb * .1 + lean * .3,
        tip.dy + h * .5,
        left.dx,
        left.dy,
      );
  }

  /// The edge of the ring from angle [from] to [to], in short steps.
  static void _ringEdge(
    Path path,
    double from,
    double to,
    Offset Function(double) at,
  ) {
    final n = math.max(1, ((to - from).abs() / .2).ceil());
    for (var i = 1; i <= n; i++) {
      final q = at(from + (to - from) * i / n);
      path.lineTo(q.dx, q.dy);
    }
  }

  /// The points on the near side, from the back round to the front: angle,
  /// half angle, height, lean. The last is the front's tall point.
  static const _nearPoints = [
    (.56, .3, .22, .03),
    (1.4, .4, .27, .04),
    (2.25, .38, .35, .06),
  ];

  /// The far side's points, seen from behind between the near ones.
  static const _farPoints = [(-.95, .32, .12, .02), (-1.77, .34, .12, .03)];

  /// The front: the tallest point and the ruby face the way the head looks.
  static final _crownFront = _nearPoints.last;

  /// The near half of the band (its outer face) with its points.
  static final _crownBand = () {
    final foot = _ringFoot(math.pi);
    final band = Path()..moveTo(foot.dx, foot.dy);
    _ringEdge(band, math.pi, 0, _ringFoot);
    var a = 0.0;
    final back = _ringLip(0);
    band.lineTo(back.dx, back.dy);
    for (final p in _nearPoints) {
      _ringEdge(band, a, p.$1 - p.$2, _ringLip);
      _crownPoint(band, p);
      a = p.$1 + p.$2;
    }
    _ringEdge(band, a, math.pi, _ringLip);
    return band..close();
  }();

  /// The far half's inner face, seen over the near band, with the far
  /// points (bare: beads there would only read as ink dots).
  static final _crownBack = () {
    final back = _ringLip(0);
    final path = Path()..moveTo(back.dx, back.dy);
    var a = 0.0;
    for (final p in _farPoints) {
      _ringEdge(path, a, p.$1 + p.$2, _ringLip);
      _crownPoint(path, p, far: true);
      a = p.$1 - p.$2;
    }
    _ringEdge(path, a, -math.pi, _ringLip);
    _ringEdge(path, math.pi, 0, _ringLip);
    return path..close();
  }();

  /// The near tips' beads.
  static final _crownBeads = () {
    final beads = Path();
    for (final p in _nearPoints) {
      beads.addOval(
        Rect.fromCircle(
          center: _crownTip(p) + const Offset(0, .015),
          radius: .04,
        ),
      );
    }
    return beads;
  }();

  /// The ruby sits on the band at the front, turned with it: narrower than
  /// it is tall.
  static final _rubyAt = _ringLip(_crownFront.$1) + const Offset(0, .02);

  /// The hard white glint of the gold: a stroke along the near band's face,
  /// curving with the ring.
  static final _crownGlints = () {
    final p = Path();
    Offset at(double a) => _ringFoot(a) - const Offset(0, _ringBand * .5);
    final from = at(2.05);
    p.moveTo(from.dx, from.dy);
    _ringEdge(p, 2.05, 1.5, at);
    return p;
  }();

  /// The band's lower edge in the head's frame, for the contact shadow it
  /// throws on the dome.
  static final _crownShadow = () {
    Offset toHead(Offset q) =>
        crownSeat + DragonKit.turn(q, DragonLayout.headCrownTurn);
    final pts = [
      for (var a = 2.95; a >= .19; a -= .46)
        toHead(_ringFoot(a) + const Offset(0, .04)),
    ];
    return DragonKit.spline(pts, closed: false);
  }();

  /// The gold circlet the Sovereign wears: a ring round the dome, turned
  /// with the head (its tall front point and its ruby toward the snout),
  /// the near band lit, the far band's inner face and points in shade
  /// behind, a bead on every tip and hard white glints. Bright, chunky gold
  /// (the roster's crowns are). Drawn around its seat, and on its own when
  /// the defeat knocks it loose.
  static void crown(
    Canvas c, {
    DragonTone tone = const DragonTone(),
    double glint = 0,
  }) {
    tone = _safeTone(tone);
    glint = _fin(glint);
    final heat = .3 * tone.heat;
    Color g(Color col) =>
        tone.lit(Color.lerp(col, DragonPalette.flameGold, heat)!);
    // The far side first: the inside of the band, in shade.
    c.drawPath(
      _crownBack,
      _paint(
        ('crownBack', _tk(tone), _q(tone.heat, 4)),
        () => DragonKit.linear(
          const Offset(0, -.42),
          const Offset(0, .02),
          [
            g(DragonPalette.goldDeep),
            g(Color.lerp(DragonPalette.goldDeep, DragonPalette.goldShade, .5)!),
            g(DragonPalette.goldShade),
          ],
          const [0, .55, 1],
        ),
      ),
    );
    c.drawPath(_crownBack, _ink1(DragonLayout.inkPart * 1.1));
    // The near side, lit from the front and above, shading as it turns
    // away toward the back of the skull.
    c.drawPath(
      _crownBand,
      _paint(
        ('crown', _tk(tone), _q(tone.heat, 4)),
        () => DragonKit.linear(
          const Offset(-.42, -.42),
          const Offset(.5, .24),
          [
            g(DragonPalette.goldLit),
            g(DragonPalette.gold),
            g(Color.lerp(DragonPalette.gold, DragonPalette.goldDeep, .45)!),
            g(DragonPalette.goldShade),
          ],
          const [0, .32, .7, 1],
        ),
      ),
    );
    c.drawPath(_crownBand, _ink1(DragonLayout.inkPart * 1.3));
    c.drawPath(_crownBeads, DragonKit.fill(g(DragonPalette.goldLit)));
    c.drawPath(_crownBeads, _ink1(.03));
    final ruby = _rubyAt;
    final bezel = Rect.fromCenter(center: ruby, width: .17, height: .24);
    c.drawOval(bezel, DragonKit.fill(g(DragonPalette.goldDeep)));
    c.drawOval(bezel, _ink1(.04));
    c.drawOval(
      Rect.fromCenter(center: ruby, width: .1, height: .16),
      _paint(
        ('ruby', _q(tone.flash, 6)),
        () => DragonKit.radial(
          ruby + const Offset(-.025, -.04),
          .13,
          [
            DragonPalette.white,
            tone.lit(DragonPalette.rubyLit),
            tone.lit(DragonPalette.ruby),
            tone.lit(DragonPalette.rubyDeep),
          ],
          const [0, .18, .55, 1],
        ),
      ),
    );
    c.drawPath(
      _crownGlints,
      DragonKit.line(DragonPalette.white, .04, tone.flash > .5 ? .35 : .9),
    );
    // A hard four-point sparkle rides the tall front point, always; a
    // slower one crosses the ruby (motion).
    final tip = _crownTip(_crownFront);
    c.save();
    c.translate(tip.dx - .075, tip.dy + .14);
    c.scale(.07);
    c.drawPath(_star, DragonKit.fill(DragonPalette.white, .95));
    c.restore();
    if (glint > .05) {
      c.save();
      c.translate(ruby.dx - .025, ruby.dy - .045);
      c.scale(.06 + .12 * glint);
      c.drawPath(_star, DragonKit.fill(DragonPalette.white, glint));
      c.restore();
    }
  }

  /// A four-pointed glint, unit sized.
  static final _star = Path()
    ..moveTo(0, -1)
    ..lineTo(.16, -.16)
    ..lineTo(1, 0)
    ..lineTo(.16, .16)
    ..lineTo(0, 1)
    ..lineTo(-.16, .16)
    ..lineTo(-1, 0)
    ..lineTo(-.16, -.16)
    ..close();

  // ---------------------------------------------------------------- smoke --

  /// Smoke curling up from the nostrils, drifting on the boss clock: soft
  /// puffs that swell and thin as they rise.
  static void smoke(Canvas c, DragonHeadPose p) {
    p = _safe(p);
    if (p.smoke <= 0) return;
    // Puffs leave just above the nostril so they never smudge the snout.
    final from = point(p, nostril) + const Offset(.02, -.2);
    final puff = _paint(
      'smoke',
      () => DragonKit.radial(
        Offset.zero,
        1,
        [
          DragonPalette.smoke,
          DragonPalette.smoke.withValues(alpha: .38),
          DragonPalette.smoke.withValues(alpha: 0),
        ],
        const [0, .45, 1],
      ),
    );
    final body = p.smoke * (1 + p.alert * .4);
    for (var i = 0; i < 4; i++) {
      final life = p.time == 0 ? .2 + i * .2 : (p.time * .7 + i / 4) % 1;
      final drift = Offset(
        .1 * math.sin(life * 5 + i) + life * .5,
        -life * 1.05,
      );
      final r = (.11 + life * .26) * (.7 + body * .5);
      // Soft: never dense enough to read as a solid part of the dragon.
      final alpha = math.sin(life * math.pi) * math.min(.5 * body, .55);
      if (alpha <= .01) continue;
      c.save();
      c.translate(from.dx + drift.dx, from.dy + drift.dy);
      c.scale(r);
      c.drawCircle(
        Offset.zero,
        1,
        puff
          ..color = DragonPalette.white.withValues(
            alpha: alpha.clamp(0.0, 1.0),
          ),
      );
      c.restore();
    }
  }

  // -------------------------------------------------------------- helpers --

  /// The belly plates' colours, from the inner edge out: dim amber at rest
  /// (so the eye and the gold outrank them), lit up by the fire inside, and
  /// turned violet by the swarm call, which is cool where the breath is hot.
  static List<Color> _bellyStops(DragonTone tone, double call) {
    final heat = tone.heat.clamp(0.0, 1.0), cool = call.clamp(0.0, 1.0) * .8;
    Color mix(Color warm, Color violet) =>
        tone.lit(Color.lerp(warm, violet, cool)!);
    // At rest the band is a dim, dusky amber; the fire brings it up.
    final rim = Color.lerp(
      DragonPalette.bellyDeep,
      DragonPalette.bellyDark,
      .3,
    )!;
    final body = Color.lerp(DragonPalette.belly, DragonPalette.bellyDeep, .4)!;
    return [
      mix(
        Color.lerp(rim, DragonPalette.belly, heat * .7)!,
        DragonPalette.callDeep,
      ),
      mix(
        Color.lerp(body, DragonPalette.bellyLit, heat * .8)!,
        DragonPalette.call,
      ),
      mix(
        Color.lerp(rim, DragonPalette.belly, heat * .5)!,
        DragonPalette.callDeep,
      ),
    ];
  }

  /// A tapered thorn from [base] (across [width]) to [tip], bowed by [curl]
  /// of its length: horns, spines, fangs and claws all use it.
  static void _thorn(
    Path path,
    Offset base,
    Offset tip,
    double width, {
    double curl = 0,
    bool openBase = false,
  }) {
    final d = tip - base;
    final len = d.distance;
    final u = d / len;
    final n = Offset(-u.dy, u.dx);
    final mid = Offset.lerp(base, tip, .5)! + n * (curl * len);
    final a = base + n * (width / 2), b = base - n * (width / 2);
    final k = width * .22;
    path
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx + n.dx * k, mid.dy + n.dy * k, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx - n.dx * k, mid.dy - n.dy * k, b.dx, b.dy);
    if (!openBase) path.close();
  }

  /// [pts] pushed toward [toward] by [widths], for bands laid inside a
  /// contour.
  static List<Offset> _inset(
    List<Offset> pts,
    List<double> widths,
    Offset toward,
  ) {
    final out = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i == 0 ? 0 : i - 1],
          b = pts[i == pts.length - 1 ? i : i + 1];
      final t = DragonKit.unit(b - a);
      var n = Offset(-t.dy, t.dx);
      final to = toward - pts[i];
      if (to.dx * n.dx + to.dy * n.dy < 0) n = -n;
      out.add(pts[i] + n * widths[i]);
    }
    return out;
  }

  /// The strip between two polylines of equal length as one outline.
  static Path _ribbon(List<Offset> a, List<Offset> b) {
    final n = a.length;
    return DragonKit.spline(
      [...a, ...b.reversed],
      sharp: {0, n - 1, n, 2 * n - 1},
    );
  }
}
