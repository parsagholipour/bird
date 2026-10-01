import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import 'king_coo_kit.dart';
import 'king_coo_layout.dart';
import 'king_coo_pose.dart';

/// What King Coo's head, neck, ruff, cap, siren and whistle need from the pose.
///
/// Built once a frame by [KingCooHeadPose.of] and read by every function of
/// [KingCooHeadArt]. A part that reads a new channel adds a field here; the
/// rig only ever calls `KingCooHeadPose.of(pose)`.
final class KingCooHeadPose {
  const KingCooHeadPose({
    this.at = KingCooLayout.headRest,
    this.tilt = 0,
    this.beak = 0,
    this.cheek = 0,
    this.squint = 0,
    this.anger = 0,
    this.worry = 0,
    this.dizzy = 0,
    this.blink = 0,
    this.wince = 0,
    this.lookX = 0,
    this.lookY = 0,
    this.capTilt = -.05,
    this.capLift = Offset.zero,
    this.capSpin = 0,
    this.capOff = false,
    this.showCap = true,
    this.whistle = 0,
    this.whistleAt = KingCooLayout.whistleRest,
    this.blast = 0,
    this.siren = 0,
    this.sirenGlow = 0,
    this.steam = 0,
    this.time = 0,
    this.fury = 0,
    this.tone = KingCooTone.calm,
  });

  /// The head for [pose]. EVERY head implementation keeps this factory: the
  /// rig builds nothing but `KingCooHeadPose.of(pose)`. [cap] false leaves the
  /// cap out of [KingCooHeadArt.face] (the defeat's tumble paints it alone).
  factory KingCooHeadPose.of(KingCooPose pose, {bool cap = true}) =>
      KingCooHeadPose(
        at: pose.headCentre,
        tilt: pose.headTilt,
        beak: pose.beak,
        cheek: pose.cheek,
        squint: pose.squint,
        // The COO! is a bellow: the brow comes down with it.
        anger: math.max(pose.anger, .55 * pose.roar),
        worry: pose.worry,
        dizzy: pose.dizzy,
        blink: pose.blink,
        wince: pose.wince,
        lookX: pose.lookX,
        lookY: pose.lookY,
        capTilt: pose.capTilt,
        capLift: pose.capLift,
        capSpin: pose.capSpin,
        capOff: pose.capOff,
        showCap: cap,
        whistle: pose.whistle,
        whistleAt: pose.whistleAt,
        blast: pose.blast,
        siren: pose.siren,
        sirenGlow: pose.sirenGlow,
        steam: pose.steam,
        time: pose.time,
        fury: pose.fury,
        tone: pose.tone,
      );

  /// The skull's centre (figure frame) and its turn (positive: beak UP).
  final Offset at;
  final double tilt;

  /// The face: the gape (0 shut .. 1 wide), puffed cheeks, narrowed lids, the
  /// brow (anger: steeper and heavier; worry: raised and bent), X eyes above
  /// .5, a blink, the flinch, and where he looks (x: -1 toward where he is
  /// throwing; y: -1 up .. 1 down).
  final double beak, cheek, squint, anger, worry, dizzy, blink, wince;
  final double lookX, lookY;

  /// The cap: tilt about its band, hop, spin (the pop's flight), and whether
  /// it is OFF his head ([capOff]: the defeat, the beaten pose) or left out of
  /// [KingCooHeadArt.face] ([showCap]).
  final double capTilt, capSpin;
  final Offset capLift;
  final bool capOff, showCap;

  /// 0 hanging on its chain .. 1 in the beak, where the whistle is (figure
  /// frame) and the blast (1 at the blow).
  final double whistle, blast;
  final Offset whistleAt;

  /// 0 off, 1 red, 2 blue; its glow 0..1.
  final int siren;
  final double sirenGlow, steam, time, fury;
  final KingCooTone tone;

  /// [this] with every non-finite channel replaced by its rest value, so a
  /// stray NaN in the boss clock never reaches a quantiser, a lerp or a path.
  KingCooHeadPose get safe {
    final sum =
        at.dx +
        at.dy +
        tilt +
        beak +
        cheek +
        squint +
        anger +
        worry +
        dizzy +
        blink +
        wince +
        lookX +
        lookY +
        capTilt +
        capSpin +
        capLift.dx +
        capLift.dy +
        whistle +
        blast +
        whistleAt.dx +
        whistleAt.dy +
        sirenGlow +
        steam +
        time +
        fury +
        tone.flash +
        tone.fury +
        tone.heat +
        tone.dark +
        tone.sirenGlow;
    if (sum.isFinite) return this;
    double f(double v, [double or = 0]) => v.isFinite ? v : or;
    Offset o(Offset v, Offset or) => v.dx.isFinite && v.dy.isFinite ? v : or;
    return KingCooHeadPose(
      at: o(at, KingCooLayout.headRest),
      tilt: f(tilt),
      beak: f(beak),
      cheek: f(cheek),
      squint: f(squint),
      anger: f(anger),
      worry: f(worry),
      dizzy: f(dizzy),
      blink: f(blink),
      wince: f(wince),
      lookX: f(lookX),
      lookY: f(lookY),
      capTilt: f(capTilt, -.05),
      capLift: o(capLift, Offset.zero),
      capSpin: f(capSpin),
      capOff: capOff,
      showCap: showCap,
      whistle: f(whistle),
      whistleAt: o(whistleAt, KingCooLayout.whistleRest),
      blast: f(blast),
      siren: siren,
      sirenGlow: f(sirenGlow),
      steam: f(steam),
      time: f(time),
      fury: f(fury),
      tone: KingCooTone(
        flash: f(tone.flash),
        fury: f(tone.fury),
        heat: f(tone.heat),
        dark: f(tone.dark),
        siren: tone.siren,
        sirenGlow: f(tone.sirenGlow),
        sky: tone.sky,
      ),
    );
  }
}

/// The neck's geometry for one pose (see [KingCooHeadArt.neckOf]): a tube from
/// inside the chest to the skull, wound clockwise on screen like every outline
/// of the body, so a skin can lay it in one path with the torso and the skull
/// (they all fill and clip as their union).
final class KingCooNeck {
  KingCooNeck._(this.spine, this.left, this.right, this.path);

  /// Five samples from the base (inside the chest) to the top (under the
  /// skull), and the two edges at the same samples: [left] is the throat
  /// side, [right] the nape side. Figure frame.
  final List<Offset> spine, left, right;

  /// The tube as one closed outline.
  final Path path;

  /// A point [f] of the way across the tube at sample [u] (0 base .. 4 top):
  /// -1 the throat edge, +1 the nape edge.
  Offset at(double u, double f) {
    final i = u.floor().clamp(0, spine.length - 2);
    final t = (u - i).clamp(0.0, 1.0);
    final centre = Offset.lerp(spine[i], spine[i + 1], t)!;
    final l = Offset.lerp(left[i], left[i + 1], t)!;
    final r = Offset.lerp(right[i], right[i + 1], t)!;
    return f <= 0 ? Offset.lerp(centre, l, -f)! : Offset.lerp(centre, r, f)!;
  }
}

/// King Coo's neck, ruff, head, cap, siren and whistle, in rig units.
///
/// THE FACE of a funny, fierce-but-lovable pouter-pigeon commissioner: a
/// round lilac skull with a heavy brow, one big glossy amber eye with a hard
/// white glint, a long coral beak with a cere and a hinged lower mandible, a
/// scalloped iridescent ruff on a green-to-violet gorget, and a navy police
/// cap with a brass badge, a black patent visor and a little siren that
/// flashes. A silver whistle hangs on its chain until he puts it in his beak.
///
/// AUTHORING. The head is drawn in its own frame (origin the skull's centre,
/// the beak toward -x, rig units) and turned by the pose's tilt about the
/// centre; nothing pose-independent is built per frame (outlines are
/// `static final`, every gradient is `KingCooKit.cached` in unit space, so
/// pixels cannot depend on which frame came first). The tone is laid over
/// them: a fill that has a gradient gets `KingCooKit.wash` (two ops at most,
/// none when calm), a flat fill is `tone.lit(...)`. No clip is used: the rim
/// lights are strokes of hand-inset paths, the lids are exact circle segments.
///
/// TWO WAYS TO PAINT HIM. The rig calls [neck], [ruff], [head], [cap],
/// [whistle] and [steam] (each complete with its own ink). A skin that paints
/// the trunk as one creature instead takes the pieces: [skullAt], [neckOf]
/// (`.path`), their winding (clockwise, like the torso), then
/// [under] before the skin, [neckDetails] and [skullDetails] on it and [face]
/// after it (see `HANDOFF.md`).
abstract final class KingCooHeadArt {
  // ---------------------------------------------------------------- anchors

  /// In the head's frame (origin the skull's centre, beak toward -x): what
  /// `KingCooLayout` tabulates.
  static const eye = KingCooLayout.headEye;
  static const beakTip = KingCooLayout.headBeakTip;
  static const mouth = KingCooLayout.headMouth;
  static const whistleMouth = KingCooLayout.headWhistle;
  static const capSeat = KingCooLayout.headCapSeat;
  static const siren = KingCooLayout.headSiren;

  /// The jaw's pivot (the same anchor), and how far each mandible swings at a
  /// full gape, in radians. The beak points toward -x, so a turn by +a lifts
  /// its tip and a turn by -a drops it: the lower mandible opens by
  /// [lowerSwing] `*` -1, the upper lifts by [upperSwing] (the contract text
  /// lists the magnitudes; the signs are the geometry's).
  static const hinge = KingCooLayout.headBeakHinge;
  static const lowerSwing = .72, upperSwing = .16;

  /// [local] (in the head's frame) as a point of the figure frame.
  static Offset point(KingCooHeadPose h, Offset local) =>
      h.at + KingCooKit.turn(local, h.tilt);

  // ------------------------------------------------------------- constants --

  static const _ink = KingCooPalette.ink;

  static double _clamp01(double v) => v.clamp(0.0, 1.0);

  /// The skull: the layout's outline with a little more cheek and jowl (the
  /// extremes, top -.54 / bottom .56 / front -.58 / back .56, are the
  /// layout's). Wound clockwise on screen.
  static const _skullPts = <Offset>[
    Offset(-.30, -.54),
    Offset(.14, -.55),
    Offset(.46, -.34),
    Offset(.57, .02),
    Offset(.50, .36),
    Offset(.22, .57),
    Offset(-.14, .58),
    Offset(-.42, .46),
    Offset(-.56, .22),
    Offset(-.58, -.08),
    Offset(-.50, -.38),
  ];
  static final Path _skull = KingCooKit.spline(_skullPts);

  /// The lower mandible, clockwise: the underside out to a round tip, then the
  /// bite line back to the hinge. Drawn at rest; the hinge swings it.
  static final Path _lower = Path()
    ..moveTo(-.44, .30)
    ..quadraticBezierTo(-.72, .295, -.97, .19)
    ..quadraticBezierTo(-1.03, .135, -.96, .10)
    ..lineTo(-.40, .10)
    ..close();
  static final Path _lowerInk = Path()
    ..moveTo(-.44, .30)
    ..quadraticBezierTo(-.72, .295, -.97, .19)
    ..quadraticBezierTo(-1.03, .135, -.96, .10)
    ..lineTo(-.50, .10);

  /// The upper mandible, clockwise from the hooked tip over the culmen to the
  /// base and back along the bite line. The ink leaves the base open (the
  /// cere and the skull take it).
  static Path _upperPath({required bool closed}) {
    final p = Path()
      ..moveTo(-1.11, .06)
      ..cubicTo(-1.12, -.07, -.95, -.17, -.72, -.20)
      ..cubicTo(-.62, -.215, -.52, -.21, -.42, -.185);
    if (closed) {
      p
        ..lineTo(-.42, .10)
        ..lineTo(-.92, .085)
        ..quadraticBezierTo(-1.03, .115, -1.11, .06)
        ..close();
    } else {
      p
        ..moveTo(-.44, .10)
        ..lineTo(-.92, .085)
        ..quadraticBezierTo(-1.03, .115, -1.11, .06)
        ..cubicTo(-1.12, -.07, -.95, -.17, -.72, -.20);
    }
    return p;
  }

  static final Path _upper = _upperPath(closed: true);
  static final Path _upperInk = _upperPath(closed: false);

  /// The hard white glint along the culmen.
  static final Path _culmen = Path()
    ..moveTo(-1.02, -.06)
    ..quadraticBezierTo(-.88, -.17, -.68, -.198);

  /// The cere (the soft bump over the beak's root) and the nostril.
  static const Rect _cere = Rect.fromLTRB(-.70, -.235, -.46, -.105);
  static final Path _nostril = Path()
    ..moveTo(-.66, -.17)
    ..quadraticBezierTo(-.60, -.21, -.52, -.145)
    ..quadraticBezierTo(-.58, -.155, -.66, -.17)
    ..close();

  /// Contour feathers over the cheek and the nape: staggered rows of soft
  /// scallops (the body's language, so the head is the same plumage), open
  /// toward the beak, one op.
  static final Path _flow = () {
    final p = Path();
    for (final (x, y) in const [
      (.16, .02),
      (.34, .02),
      (.06, .18),
      (.24, .18),
      (.42, .18),
      (.14, .34),
      (.32, .34),
      (.02, .48),
      (.20, .48),
    ]) {
      p
        ..moveTo(x - .085, y)
        ..quadraticBezierTo(x, y + .11, x + .085, y);
    }
    return p;
  }();

  /// A tapered crescent along [outline]'s edge between two angles (degrees,
  /// about [centre], 0 right, 90 down, -90 up): [outer] inside the ink, [width]
  /// wide at its middle and pointed at both ends. The outline is wound
  /// clockwise on screen. Cel-shaded lights and shadows are these: one filled
  /// op, no clip, and they can never leave the shape.
  static Path _crescent(
    Path outline,
    Offset centre,
    double fromDeg,
    double toDeg, {
    double outer = .035,
    double width = .09,
  }) {
    final metric = outline.computeMetrics().first;
    const n = 48;
    final a = <Offset>[], b = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final tan = metric.getTangentForOffset(metric.length * i / n)!;
      final rel = tan.position - centre;
      final deg = math.atan2(rel.dy, rel.dx) * 180 / math.pi;
      if (deg < fromDeg || deg > toDeg) continue;
      final t = (deg - fromDeg) / (toDeg - fromDeg);
      final w = width * math.pow(math.sin(math.pi * t), .8);
      final inward = Offset(-tan.vector.dy, tan.vector.dx);
      a.add(tan.position + inward * outer);
      b.add(tan.position + inward * (outer + w));
    }
    final path = KingCooKit.spline(a, closed: false);
    path.extendWithPath(
      KingCooKit.spline(b.reversed.toList(), closed: false),
      Offset.zero,
    );
    return path..close();
  }

  /// A hard white glint on the forehead's bulge, above the moon's rim.
  static final Path _skullGlint = Path()
    ..moveTo(.26, -.30)
    ..quadraticBezierTo(.40, -.24, .46, -.10);
  static final Path _rimSky = _crescent(
    _skull,
    Offset.zero,
    -108,
    8,
    width: .085,
  );

  /// The cel shadow under the cheek, and (with the cap on) the cap's contact
  /// shadow on the brow: one path, one op.
  static final Path _shade = _crescent(
    _skull,
    Offset.zero,
    12,
    172,
    outer: .02,
    width: .30,
  );
  static final Path _shadeCap = Path.from(_shade)
    ..moveTo(-.47, -.325)
    ..quadraticBezierTo(0, -.275, .47, -.325)
    ..lineTo(.47, -.225)
    ..quadraticBezierTo(0, -.175, -.47, -.225)
    ..close();

  /// The nape tufts: three feathers that stick out behind the head (under the
  /// skin), so the round skull has a cheeky, slightly dishevelled back.
  static final Path _tufts = () {
    final p = Path();
    for (final (y, len, lift) in const [(-.02, .17, -.09), (.15, .15, .03)]) {
      p
        ..moveTo(.44, y - .08)
        ..quadraticBezierTo(.44 + len * .6, y - .09 + lift, .44 + len, y + lift)
        ..quadraticBezierTo(.44 + len * .5, y + .05 + lift * .5, .44, y + .09)
        ..close();
    }
    return p;
  }();

  // ----------------------------------------------------------------- eye --

  static const _eyeR = .24;
  static const _eyeAt = KingCooLayout.headEye;
  static final Path _glints = () {
    final p = Path()
      ..addPath(
        _xf(
          Path()..addOval(
            Rect.fromCenter(center: Offset.zero, width: .15, height: .095),
          ),
          const Offset(.07, -.085),
          -.5,
        ),
        Offset.zero,
      )
      ..addOval(
        Rect.fromCircle(center: const Offset(-.085, .09), radius: .027),
      );
    return p;
  }();

  /// The warm bounce light along the iris's lower edge (a unit circle's
  /// crescent, scaled with the iris): depth for the glossy eye.
  static final Path _irisBounce = _crescent(
    KingCooKit.spline([
      for (var i = 0; i < 16; i++)
        Offset(math.cos(i * math.pi / 8), math.sin(i * math.pi / 8)),
    ]),
    Offset.zero,
    28,
    152,
    outer: .06,
    width: .2,
  );

  /// The brow: a tapered ridge, thick on the beak side, in a frame whose +x
  /// runs along the lid (toward the nape) and -y is up.
  static final Path _browShape = Path()
    ..moveTo(-.30, .04)
    ..cubicTo(-.29, -.09, -.14, -.155, .02, -.155)
    ..quadraticBezierTo(.12, -.16, .15, -.115)
    ..quadraticBezierTo(.21, -.165, .29, -.115)
    ..quadraticBezierTo(.35, -.135, .41, -.045)
    ..cubicTo(.26, -.065, .10, -.05, -.04, -.02)
    ..cubicTo(-.14, 0, -.24, .04, -.30, .04)
    ..close();

  /// The bag under the eye: a tired commissioner's crease.
  static final Path _bag = Path()
    ..moveTo(-.20, .285)
    ..quadraticBezierTo(-.04, .335, .14, .28);

  /// The anger mark: four brackets round a point (the classic burst), each a
  /// quarter circle centred on a diagonal and facing the middle.
  static final Path _vein = () {
    final p = Path();
    for (final (dx, dy, a) in const [
      (1.0, 1.0, math.pi),
      (-1.0, -1.0, 0.0),
      (1.0, -1.0, math.pi / 2),
      (-1.0, 1.0, -math.pi / 2),
    ]) {
      p.addArc(
        Rect.fromCircle(center: Offset(dx * .105, dy * .105), radius: .10),
        a,
        math.pi / 2,
      );
    }
    return p;
  }();

  /// The sweat drop of a worried, sheepish face: a teardrop at the temple.
  static final Path _sweat = Path()
    ..moveTo(0, -.11)
    ..cubicTo(.03, -.05, .075, .01, .075, .045)
    ..cubicTo(.075, .095, .04, .125, 0, .125)
    ..cubicTo(-.04, .125, -.075, .095, -.075, .045)
    ..cubicTo(-.075, .01, -.03, -.05, 0, -.11)
    ..close();

  /// A five-point star, for the dizzy ring.
  static Path _starPath(double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final v = Offset(math.cos(a), math.sin(a)) * (i.isEven ? r : r * .45);
      i == 0 ? p.moveTo(v.dx, v.dy) : p.lineTo(v.dx, v.dy);
    }
    return p..close();
  }

  static final Path _star = _starPath(.085);

  // ------------------------------------------------------------ the ruff --

  /// The ruff: four bold feather scallops round the lower half of the head
  /// (angles about the head's centre: 0 the nape, pi/2 under the chin, pi the
  /// throat), the inner edge hidden under the skull.
  static final Path _ruff = () {
    const n = 4;
    const a0 = .10, a1 = 2.72, r0 = .40, r1 = .70;
    final path = Path();
    final pts = <Offset>[
      for (var i = 0; i <= n; i++) KingCooKit.polar(a0 + (a1 - a0) * i / n, r1),
    ];
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < n; i++) {
      final a = a0 + (a1 - a0) * (i + .5) / n;
      final ctl = KingCooKit.polar(a, r1 + .29);
      path.quadraticBezierTo(ctl.dx, ctl.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    for (var i = n; i >= 0; i--) {
      final p = KingCooKit.polar(a0 + (a1 - a0) * i / n, r0);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();

  /// The glint on the lit shoulder of the collar.
  static final Path _ruffGlint = Path()
    ..addArc(Rect.fromCircle(center: Offset.zero, radius: .80), .22, .55);

  // ------------------------------------------------------------- the cap --

  /// The cap in the head's frame, band centre at [capSeat]: a peaked police
  /// cap pushed a little back. A band (slightly raked, high at the front) under
  /// a crown that flares out and up to a flat top, a short black patent visor
  /// over the brow, a brass badge at the front, the siren's dome on the top.
  /// Every outline is wound clockwise; the crown's top is the highest thing at
  /// -.97 (dome included), the visor stays short of -.82 so the beak leads.
  static final Path _band = Path()
    ..moveTo(-.56, -.53)
    ..quadraticBezierTo(.02, -.50, .60, -.47)
    ..lineTo(.58, -.29)
    ..quadraticBezierTo(.02, -.29, -.54, -.34)
    ..close();
  static final Path _crown = Path()
    ..moveTo(-.56, -.53)
    ..cubicTo(-.66, -.58, -.70, -.67, -.66, -.74)
    ..quadraticBezierTo(-.64, -.805, -.54, -.815)
    ..quadraticBezierTo(.06, -.855, .58, -.785)
    ..quadraticBezierTo(.70, -.775, .71, -.68)
    ..cubicTo(.72, -.59, .66, -.52, .60, -.47)
    ..quadraticBezierTo(.02, -.50, -.56, -.53)
    ..close();
  static final Path _visor = Path()
    ..moveTo(-.50, -.43)
    ..cubicTo(-.60, -.43, -.70, -.41, -.76, -.345)
    ..quadraticBezierTo(-.83, -.275, -.80, -.24)
    ..quadraticBezierTo(-.62, -.225, -.52, -.30)
    ..close();
  static final Path _capShape = Path()
    ..addPath(_band, Offset.zero)
    ..addPath(_crown, Offset.zero);
  static final Path _capAll = Path()
    ..addPath(_capShape, Offset.zero)
    ..addPath(_visor, Offset.zero);
  static final Path _capInk = _capShape;
  static final Path _piping = Path()
    ..moveTo(-.56, -.53)
    ..quadraticBezierTo(.02, -.50, .60, -.47);
  static final Path _crownRim = _crescent(
    _crown,
    const Offset(.04, -.68),
    -80,
    12,
    outer: .03,
    width: .075,
  );
  static final Path _capGlints = Path()
    ..moveTo(-.50, -.715)
    ..quadraticBezierTo(-.40, -.785, -.20, -.805)
    ..moveTo(-.77, -.315)
    ..quadraticBezierTo(-.66, -.355, -.56, -.37);

  /// A row of police checks along the band (a Battenburg band, one op): small
  /// lighter squares, every other cell, following the band's rake.
  static final Path _checks = () {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final x0 = -.50 + i * .112, x1 = x0 + .056;
      double top(double x) => -.515 + (x + .56) * .05;
      double bot(double x) => -.335 + (x + .54) * .045;
      final mid = (top(x0) + bot(x0)) / 2;
      final mid1 = (top(x1) + bot(x1)) / 2;
      if (i.isEven) {
        p
          ..moveTo(x0, top(x0) + .012)
          ..lineTo(x1, top(x1) + .012)
          ..lineTo(x1, mid1)
          ..lineTo(x0, mid)
          ..close();
      } else {
        p
          ..moveTo(x0, mid)
          ..lineTo(x1, mid1)
          ..lineTo(x1, bot(x1) - .012)
          ..lineTo(x0, bot(x0) - .012)
          ..close();
      }
    }
    return p;
  }();
  static final Path _badge = () {
    const b = .12, cx = -.27;
    return Path()
      ..moveTo(cx - b, -.50)
      ..lineTo(cx + b, -.50)
      ..lineTo(cx + b * .95, -.42)
      ..quadraticBezierTo(cx, -.26, cx - b * .95, -.42)
      ..close();
  }();
  static final Path _badgeStar = () {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final v =
          Offset(math.cos(a), math.sin(a)) * (i.isEven ? .058 : .026) +
          const Offset(-.27, -.415);
      i == 0 ? p.moveTo(v.dx, v.dy) : p.lineTo(v.dx, v.dy);
    }
    return p..close();
  }();

  /// The siren: a dome sitting in the crown's top (a thin steel ring at its
  /// foot).
  static final Path _dome = Path()
    ..moveTo(-.165, -.80)
    ..lineTo(-.15, -.835)
    ..cubicTo(-.155, -.92, -.07, -.957, 0, -.957)
    ..cubicTo(.07, -.957, .155, -.92, .15, -.835)
    ..lineTo(.165, -.80)
    ..close();
  static final Path _domeGlint = Path()
    ..moveTo(-.078, -.885)
    ..quadraticBezierTo(-.066, -.927, -.028, -.937);

  /// The siren's rays, round the dome (1 op): they leave it alternately.
  static Path _rays(double reach) {
    final p = Path();
    for (final a in const [-2.65, -2.1, -1.57, -1.04, -.49]) {
      final from = Offset(0, -.895) + KingCooKit.polar(a, .17);
      final to = Offset(0, -.895) + KingCooKit.polar(a, .17 + .13 * reach);
      p
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
    }
    return p;
  }

  // ---------------------------------------------------------- the whistle --

  /// The whistle, in its own frame: the origin is the mouthpiece's tip (where
  /// the beak holds it), +x runs to the chamber. One outline for the tube and
  /// the round chamber (the ink is stroked first, wide, and the fill buries
  /// its inner half, so no line shows where they meet).
  static final Path _whistleBody = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(0, -.055, .28, .055),
        const Radius.circular(.03),
      ),
    )
    ..addOval(Rect.fromCircle(center: const Offset(.33, .075), radius: .135))
    ..addOval(Rect.fromCircle(center: const Offset(.49, .05), radius: .045));
  static final Path _whistleHole = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(.17, -.075, .27, -.012),
        const Radius.circular(.02),
      ),
    );
  static final Path _whistleGlint = Path()
    ..moveTo(.06, -.028)
    ..lineTo(.22, -.028)
    ..moveTo(.27, .03)
    ..quadraticBezierTo(.33, -.02, .42, .02);
  static final Path _tweet = () {
    // Sound lines: from the chamber, down and back (away from the beak, so the
    // beak keeps leading the silhouette), in the whistle's frame.
    final p = Path();
    for (final a in const [-.25, .45, 1.15]) {
      final from = const Offset(.33, .075) + KingCooKit.polar(a, .21);
      final to = const Offset(.33, .075) + KingCooKit.polar(a, .37);
      p
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
    }
    return p;
  }();

  /// The steam puffs' unit circle is drawn under a transform.
  static const _puffs = 3;

  // -------------------------------------------------------------- paints --

  /// A cached shader's paint at [alpha] (the shader is shared; the paint is
  /// new, so a cached paint is never mutated).
  static Paint _shaded(Object key, Paint Function() make, [double alpha = 1]) {
    final base = KingCooKit.cached(key, make);
    if (alpha >= 1) return base;
    return Paint()
      ..shader = base.shader
      ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0));
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  /// How strongly the siren lights the rims (0 off .. 1), and the rim's colour
  /// then: the moon's bounce turns red or blue with it.
  static double _sirenAmount(KingCooTone tone) =>
      tone.siren == 0 ? 0 : tone.sirenGlow.clamp(0.0, 1.0);
  static Color _sirenTint(KingCooTone tone) {
    final k = _sirenAmount(tone);
    return k <= 0 ? tone.sky : _mix(tone.sky, tone.sirenColor, .8 * k);
  }

  static Paint get _skullPaint => _shaded(
    'k2.skull',
    () => KingCooKit.radial(
      const Offset(.18, -.20),
      .95,
      [
        _mix(KingCooPalette.featherLit, KingCooPalette.feather, .22),
        KingCooPalette.feather,
        _mix(KingCooPalette.feather, KingCooPalette.featherDeep, .7),
      ],
      const [0, .5, 1],
    ),
  );

  /// The gorget: green on the moonlit side through teal to violet and a
  /// magenta flash on the shade side (iridescence, in the figure's frame).
  static Paint get _neckPaint => _shaded(
    'k2.neck',
    () => KingCooKit.linear(
      const Offset(-.25, -1.50),
      const Offset(-1.35, -.50),
      [
        _mix(KingCooPalette.irisGreen, KingCooPalette.white, .10),
        KingCooPalette.irisGreen,
        KingCooPalette.irisTeal,
        _mix(KingCooPalette.irisViolet, KingCooPalette.irisTeal, .25),
        _mix(KingCooPalette.irisMagenta, KingCooPalette.irisViolet, .35),
      ],
      const [0, .18, .44, .74, 1],
    ),
  );
  static Paint get _ruffPaint => _shaded(
    'k2.ruff',
    () => KingCooKit.sweep(
      Offset.zero,
      [
        KingCooPalette.irisGreen,
        KingCooPalette.irisGreen,
        KingCooPalette.irisTeal,
        _mix(KingCooPalette.irisViolet, KingCooPalette.irisTeal, .15),
        _mix(KingCooPalette.irisMagenta, KingCooPalette.irisViolet, .55),
        KingCooPalette.irisViolet,
        KingCooPalette.irisViolet,
      ],
      const [0, .03, .12, .22, .33, .43, 1],
    ),
  );
  static Paint get _upperPaint => _shaded(
    'k2.beak',
    () => KingCooKit.linear(
      const Offset(0, -.26),
      const Offset(0, .12),
      [
        _mix(KingCooPalette.cere, KingCooPalette.beak, .55),
        _mix(KingCooPalette.beak, KingCooPalette.foot, .25),
        _mix(KingCooPalette.beak, KingCooPalette.foot, .8),
      ],
      const [0, .5, 1],
    ),
  );
  static Paint get _irisPaint => _shaded(
    'k2.iris',
    () => KingCooKit.radial(
      const Offset(.12, -.18),
      1.25,
      [
        const Color(0xffffeb9a),
        KingCooPalette.eyeCore,
        KingCooPalette.eyeRim,
        KingCooPalette.eyeDeep,
      ],
      const [0, .30, .68, 1],
    ),
  );
  static Paint get _capPaint => _shaded(
    'k2.cap',
    () => KingCooKit.linear(
      const Offset(0, -.875),
      const Offset(0, -.30),
      [KingCooPalette.navyLit, KingCooPalette.navy, KingCooPalette.navyDeep],
      const [0, .5, 1],
    ),
  );
  static Paint get _visorPaint => _shaded(
    'k2.visor',
    () => KingCooKit.linear(const Offset(-.9, -.38), const Offset(-.6, -.10), [
      _mix(KingCooPalette.navy, KingCooPalette.visor, .3),
      KingCooPalette.visor,
    ]),
  );
  static Paint get _brassPaint => _shaded(
    'k2.brass',
    () => KingCooKit.linear(
      const Offset(-.27, -.50),
      const Offset(-.27, -.27),
      [KingCooPalette.brassLit, KingCooPalette.brass, KingCooPalette.brassDeep],
      const [0, .45, 1],
    ),
  );
  static Paint _domePaint(int siren) => _shaded(('k2.dome', siren), () {
    final on = siren == 0
        ? KingCooPalette.sirenOff
        : (siren == 2 ? KingCooPalette.sirenBlue : KingCooPalette.sirenRed);
    return KingCooKit.radial(
      const Offset(-.03, -.915),
      .17,
      [
        KingCooPalette.white,
        on,
        _mix(on, KingCooPalette.sirenOffDeep, .7),
        KingCooPalette.steelDeep,
      ],
      const [0, .42, .85, 1],
    );
  });
  static Paint get _steelPaint => _shaded(
    'k2.steel',
    () => KingCooKit.linear(
      const Offset(0, -.06),
      const Offset(0, .21),
      [KingCooPalette.steelLit, KingCooPalette.steel, KingCooPalette.steelDeep],
      const [0, .42, 1],
    ),
  );
  static Paint _puffPaint(double alpha) => _shaded(
    'k2.puff',
    () => KingCooKit.radial(
      Offset.zero,
      1,
      [
        KingCooPalette.steam.withValues(alpha: 1),
        KingCooPalette.steam.withValues(alpha: .85),
        KingCooPalette.steam.withValues(alpha: 0),
      ],
      const [0, .55, 1],
    ),
    alpha,
  );

  // -------------------------------------------------------------- helpers --

  static Path _xf(Path p, Offset at, double angle) {
    final c = math.cos(angle), s = math.sin(angle);
    return p.transform(
      Float64List.fromList([
        c,
        s,
        0,
        0,
        -s,
        c,
        0,
        0,
        0,
        0,
        1,
        0,
        at.dx,
        at.dy,
        0,
        1,
      ]),
    );
  }

  static void _headFrame(Canvas c, KingCooHeadPose h) {
    c.translate(h.at.dx, h.at.dy);
    c.rotate(h.tilt);
  }

  static Offset _bez(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }

  // ------------------------------------------------------------ skin API --

  /// The skull in the figure frame for [h] (clockwise, like the torso).
  static Path skullAt(KingCooHeadPose h) {
    h = h.safe;
    return _xf(_skull, h.at, h.tilt);
  }

  /// The upper mandible, cere included, and the lower mandible swung open, in
  /// the figure frame.
  static Path beakAt(KingCooHeadPose h) {
    h = h.safe;
    final a = _clamp01(h.beak) * upperSwing;
    return _xf(_xf(_upper, Offset.zero, a), h.at, h.tilt);
  }

  static Path jawAt(KingCooHeadPose h) {
    h = h.safe;
    final a = _clamp01(h.beak) * -lowerSwing;
    // Turn about the hinge: move the hinge to the origin, turn, move it back.
    final p = _xf(_xf(_lower, -hinge, 0), Offset.zero, a).shift(hinge);
    return _xf(p, h.at, h.tilt);
  }

  /// The ruff for [h] in the figure frame (clockwise, like the skull and the
  /// neck): the same four scallops [ruff] paints, turned with the head and
  /// puffed by the fury. A one-piece skin adds it to its outline so the collar
  /// has no border of its own (K8: the last seam between head and body).
  static Path ruffAt(KingCooHeadPose h) {
    h = h.safe;
    final k = 1 + .125 * h.fury, a = h.tilt * .6;
    final cs = math.cos(a) * k, sn = math.sin(a) * k;
    final m = _ruffMatrix
      ..[0] = cs
      ..[1] = sn
      ..[4] = -sn
      ..[5] = cs
      ..[12] = h.at.dx
      ..[13] = h.at.dy;
    return _ruff.transform(m);
  }

  static final Float64List _ruffMatrix = Float64List.fromList([
    1, 0, 0, 0, //
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  ]);

  /// The ruff's colour over a skin (no ink): the iridescent sweep with the
  /// tone over it, and the glint on the lit shoulder. Paint it after the chest
  /// and before the skull, as [ruff] sits in the z-order. [path] is [ruffAt]
  /// for [h] if the caller has it.
  static void ruffFill(Canvas c, KingCooHeadPose h, {Path? path}) {
    h = h.safe;
    final p = path ?? ruffAt(h);
    c.save();
    c.translate(h.at.dx, h.at.dy);
    c.rotate(h.tilt * .6);
    final k = 1 + .125 * h.fury;
    c.scale(k);
    c.drawPath(_ruff, _ruffPaint);
    c.restore();
    KingCooKit.wash(c, p, h.tone, flush: false);
    c.save();
    c.translate(h.at.dx, h.at.dy);
    c.rotate(h.tilt * .6);
    c.scale(k);
    c.rotate(h.time == 0 ? 0 : .22 * math.sin(h.time * 1.4 + 1.0));
    c.drawPath(
      _ruffGlint,
      KingCooKit.line(
        KingCooPalette.white,
        .06 / k,
        .6 * (1 - h.tone.washAlpha),
      ),
    );
    c.restore();
  }

  /// The neck for [h]: a tube leaning out of the chest (an S: straight up,
  /// then forward to the head), widest at the base, tucked under the skull.
  /// Its base is inside the chest globe and its top under the skull, so both
  /// ends are always covered.
  static KingCooNeck neckOf(KingCooHeadPose h) {
    h = h.safe;
    const base = Offset(-.40, -.42);
    final top = point(h, const Offset(.14, .30));
    final c1 = base + const Offset(-.02, -.62);
    final c2 = top + const Offset(.16, .55);
    final spine = [for (var i = 0; i < 5; i++) _bez(base, c1, c2, top, i / 4)];
    const half = [.40, .36, .32, .30, .29];
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < 5; i++) {
      final a = spine[i == 0 ? 0 : i - 1], b = spine[i == 4 ? 4 : i + 1];
      final d = b - a;
      final len = math.max(1e-6, d.distance);
      final n = Offset(d.dy / len, -d.dx / len); // the throat side
      left.add(spine[i] + n * half[i]);
      right.add(spine[i] - n * half[i]);
    }
    return KingCooNeck._(
      spine,
      left,
      right,
      KingCooKit.spline([...left, ...right.reversed]),
    );
  }

  // ------------------------------------------------------------------ neck --

  /// The neck: an iridescent tube from behind the chest's upper left to the
  /// skull, so the head stands on a neck above the chest globe. It is painted
  /// BEFORE the chest (the crop bulges in front of its base) and follows the
  /// head wherever the pose moves it.
  static void neck(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    final g = neckOf(h);
    neckFill(c, h, geometry: g);
    neckDetails(c, h, geometry: g);
    KingCooKit.inkHero(c, g.path, KingCooLayout.inkHero * .9);
  }

  /// The gorget's own colour over a skin: the iridescent gradient (green on the
  /// moon side through teal to violet and magenta) with the tone over it. A
  /// skin that paints the trunk in one plumage colour lays this over the
  /// neck's region, then [neckDetails].
  static void neckFill(Canvas c, KingCooHeadPose h, {KingCooNeck? geometry}) {
    h = h.safe;
    final g = geometry ?? neckOf(h);
    c.drawPath(g.path, _neckPaint);
    KingCooKit.wash(c, g.path, h.tone, plumage: true, flush: false);
  }

  /// The neck's surface over a skin: shingled feather scallops, a shade along
  /// the throat side, the moon's green sheen down the nape side and the rim
  /// light. [geometry] is [neckOf] for [h] if the caller has it.
  static void neckDetails(
    Canvas c,
    KingCooHeadPose h, {
    KingCooNeck? geometry,
  }) {
    h = h.safe;
    final g = geometry ?? neckOf(h);
    final tone = h.tone;
    // Shingles: rows of small scallops pointing down the neck.
    final rows = Path();
    for (var k = 0; k < 4; k++) {
      final u = .55 + k * .9;
      for (final f in const [-.62, 0.0, .62]) {
        final a = g.at(u, f - .30), b = g.at(u, f + .30);
        final tip = g.at(u - .36, f);
        rows
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(tip.dx, tip.dy, b.dx, b.dy);
      }
    }
    c.drawPath(
      rows,
      KingCooKit.line(_mix(KingCooPalette.irisViolet, _ink, .45), .035, .5),
    );
    // The nape side lit by the moon: a pale green band, then the sky's rim.
    // (The sheen slides a little across the gorget on the clock: motion only.)
    final shimmer = h.time == 0 ? 0.0 : math.sin(h.time * 1.4);
    final sheen = KingCooKit.spline([
      for (final u in const [.7, 1.6, 2.6, 3.5]) g.at(u, .52 + .14 * shimmer),
    ], closed: false);
    c.drawPath(
      sheen,
      KingCooKit.line(
        _mix(KingCooPalette.irisGreen, KingCooPalette.white, .55),
        .055,
        .75 * (1 - tone.washAlpha),
      ),
    );
    if (tone.skyRim > .02) {
      final rim = KingCooKit.spline([
        for (final u in const [.5, 1.6, 2.6, 3.6]) g.at(u, .9),
      ], closed: false);
      c.drawPath(
        rim,
        KingCooKit.line(
          tone.lit(tone.sky),
          .06 * (1 + tone.dark * .5),
          tone.skyRim * .9,
        ),
      );
    }
  }

  // ------------------------------------------------------------------ ruff --

  /// The ruff: the iridescent collar under the skull, four bold scallops that
  /// follow the head's turn a little. Fury puffs it by an eighth.
  static void ruff(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    c.save();
    c.translate(h.at.dx, h.at.dy);
    c.rotate(h.tilt * .6);
    final k = 1 + .125 * h.fury;
    c.scale(k);
    c.drawPath(_ruff, _ruffPaint);
    KingCooKit.wash(c, _ruff, h.tone, flush: false);
    c.drawPath(_ruff, KingCooKit.line(_ink, KingCooLayout.inkMajor / k));
    c.save();
    c.rotate(h.time == 0 ? 0 : .22 * math.sin(h.time * 1.4 + 1.0));
    c.drawPath(
      _ruffGlint,
      KingCooKit.line(
        KingCooPalette.white,
        .06 / k,
        .6 * (1 - h.tone.washAlpha),
      ),
    );
    c.restore();
    c.restore();
  }

  // ------------------------------------------------------------------ head --

  /// The mouth's dark inside, the tongue and the lower mandible, in the head's
  /// frame: what lies BEHIND the skull (its cheek hides the jaw's root).
  static void _mouth(Canvas c, KingCooHeadPose h) {
    final tone = h.tone;
    final open = _clamp01(h.beak);
    final lo = -open * lowerSwing, up = open * upperSwing;
    if (open > .04) {
      final upTip =
          hinge + KingCooKit.turn(const Offset(-.92, .085) - hinge, up);
      final loTip =
          hinge + KingCooKit.turn(const Offset(-.94, .10) - hinge, lo);
      c.drawPath(
        Path()
          ..moveTo(hinge.dx - .03, hinge.dy - .07)
          ..lineTo(upTip.dx, upTip.dy)
          ..lineTo(loTip.dx, loTip.dy)
          ..lineTo(hinge.dx + .02, hinge.dy + .10)
          ..close(),
        KingCooKit.fill(
          _mix(KingCooPalette.mouth, KingCooPalette.sirenOffDeep, .0),
        ),
      );
    }
    c.save();
    c.translate(hinge.dx, hinge.dy);
    c.rotate(lo);
    c.translate(-hinge.dx, -hinge.dy);
    c.drawPath(
      _lower,
      KingCooKit.fill(
        tone.lit(_mix(KingCooPalette.beak, KingCooPalette.foot, .5)),
      ),
    );
    if (open > .3) {
      // The tongue lies on the lower mandible once the beak really opens.
      c.drawOval(
        Rect.fromLTRB(-.90, .03, -.50, .15),
        KingCooKit.fill(tone.lit(const Color(0xffff8f9c))),
      );
    }
    c.drawPath(_lowerInk, KingCooKit.line(_ink, KingCooLayout.inkPart));
    c.restore();
  }

  /// The skull's fill (with the tone's washes) in the head's frame.
  static void _skullFill(Canvas c, KingCooHeadPose h) {
    c.drawPath(_skull, _skullPaint);
    KingCooKit.wash(c, _skull, h.tone);
  }

  /// The skull's surface, in the head's frame: feather flow lines, a cel
  /// shadow under the cheek, the cap's contact shadow, the moon's rim, the
  /// windows' bounce, the siren's red or blue on its top, and the flush of
  /// fury on the cheek.
  static void _skullSurface(Canvas c, KingCooHeadPose h) {
    final tone = h.tone;
    final calm = 1 - tone.washAlpha;
    c.drawPath(
      h.showCap && !h.capOff ? _shadeCap : _shade,
      KingCooKit.fill(KingCooPalette.featherCore, .24 * calm),
    );
    c.drawPath(
      _flow,
      KingCooKit.line(
        KingCooPalette.inkCool,
        KingCooLayout.inkDetail,
        .34 * calm,
      ),
    );
    if (tone.skyRim > .02 || tone.sirenGlow > .05) {
      // The moon's rim on the lit edge; the siren flashes it red or blue.
      c.drawPath(
        _rimSky,
        KingCooKit.fill(
          tone.lit(_sirenTint(tone)),
          math.max(tone.skyRim, .8 * _sirenAmount(tone)),
        ),
      );
    }
    c.drawPath(
      _skullGlint,
      KingCooKit.line(KingCooPalette.white, .045, .8 * calm),
    );
    if (h.fury > .02) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(-.08, .25),
          width: .36,
          height: .22,
        ),
        KingCooKit.fill(KingCooPalette.furyBreast, .5 * h.fury),
      );
    }
  }

  static void _skullInk(Canvas c) =>
      KingCooKit.inkHero(c, _skull, KingCooLayout.inkHero * .9);

  /// The skull's own fill for a skin: the lilac gradient (lit on the moon
  /// side, deep under the cheek) with the tone over it, no ink. A skin lays it
  /// over [skullAt] instead of its own plumage colour.
  static void skullFill(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    c.save();
    _headFrame(c, h);
    _skullFill(c, h);
    c.restore();
  }

  /// The skull's surface for a skin that paints the trunk as one creature
  /// (no fill, no ink): see [skullAt].
  static void skullDetails(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    c.save();
    _headFrame(c, h);
    _skullSurface(c, h);
    c.restore();
  }

  /// What lies behind the skin: the nape tufts, the mouth's inside, the tongue
  /// and the lower mandible (the skin covers their roots).
  static void under(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    c.save();
    _headFrame(c, h);
    _tufts_(c, h);
    _mouth(c, h);
    c.restore();
  }

  static void _tufts_(Canvas c, KingCooHeadPose h) {
    final tone = h.tone;
    // They flick with the head's turn a little (the nape is the last to move).
    c.save();
    c.translate(.42, 0);
    c.rotate(-.25 * h.tilt + (h.fury > 0 ? -.10 * h.fury : 0));
    c.translate(-.42, 0);
    c.drawPath(
      _tufts,
      KingCooKit.fill(
        tone.plate(
          _mix(KingCooPalette.feather, KingCooPalette.featherDeep, .3),
        ),
      ),
    );
    c.drawPath(_tufts, KingCooKit.line(_ink, KingCooLayout.inkPart));
    c.restore();
  }

  /// The head, complete: the jaw, the skull with its ink, the cheek, the
  /// beak, the eye and the brow, in the head's frame at its centre, turned by
  /// the head's tilt.
  static void head(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    c.save();
    _headFrame(c, h);
    _tufts_(c, h);
    _mouth(c, h);
    _skullFill(c, h);
    _skullSurface(c, h);
    _skullInk(c);
    _features(c, h);
    c.restore();
  }

  /// What is painted over the skin: the puffed cheek, the beak with its cere,
  /// the eye and the brow, the anger mark and the dizzy stars, then (when
  /// [withCap]) the cap and (when [withWhistle]) the whistle.
  static void face(
    Canvas c,
    KingCooHeadPose h, {
    bool withCap = true,
    bool withWhistle = true,
  }) {
    h = h.safe;
    c.save();
    _headFrame(c, h);
    _features(c, h);
    c.restore();
    if (withCap && h.showCap) cap(c, h);
    if (withWhistle) whistle(c, h);
  }

  static void _features(Canvas c, KingCooHeadPose h) {
    final tone = h.tone;
    final open = _clamp01(h.beak);
    if (h.cheek > .02) _cheek(c, h);
    // The upper mandible lifts a little as the beak opens.
    c.save();
    c.translate(hinge.dx, hinge.dy);
    c.rotate(open * upperSwing);
    c.translate(-hinge.dx, -hinge.dy);
    c.drawPath(_upper, _upperPaint);
    KingCooKit.wash(c, _upper, tone, flush: false);
    c.drawPath(_upperInk, KingCooKit.line(_ink, KingCooLayout.inkPart * .9));
    c.drawPath(
      _culmen,
      KingCooKit.line(KingCooPalette.white, .04, .9 * (1 - tone.washAlpha)),
    );
    // The cere, with the nostril (it flares in a scowl).
    c.drawOval(
      _cere,
      KingCooKit.fill(
        tone.lit(_mix(KingCooPalette.cere, KingCooPalette.beak, .35)),
      ),
    );
    c.save();
    c.translate(-.59, -.155);
    c.scale(1 + .4 * h.anger);
    c.translate(.59, .155);
    c.drawPath(_nostril, KingCooKit.fill(KingCooPalette.inkWarm));
    c.restore();
    c.restore();
    _eye(c, h);
    if (h.fury > .05) {
      final pulse = h.time == 0 ? 1.0 : 1 + .14 * math.sin(h.time * 9);
      c.save();
      c.translate(.38, -.10);
      c.scale(pulse * (.7 + .3 * h.fury));
      c.drawPath(
        _vein,
        KingCooKit.line(KingCooPalette.sirenRed, .05, _clamp01(h.fury * 1.2))
          ..strokeCap = StrokeCap.butt,
      );
      c.restore();
    }
    if (h.dizzy > .5 && !h.capOff) _stars(c, h);
    if (h.worry > .35) {
      // A cold sweat at the temple (it swells in with the worry).
      final k = _clamp01((h.worry - .35) / .3);
      c.save();
      c.translate(.30, -.27 + .03 * k);
      c.scale(.8 + .4 * k);
      c.drawPath(_sweat, KingCooKit.line(_ink, .06));
      c.drawPath(_sweat, KingCooKit.fill(h.tone.lit(const Color(0xffbfe8ff))));
      c.restore();
    }
  }

  /// The cheeks puffed out (the whistle, the held bomb): a round, outlined
  /// bulge at the root of the lower mandible, in front of the skull.
  static void _cheek(Canvas c, KingCooHeadPose h) {
    final k = _clamp01(h.cheek);
    final r = .10 + .21 * k;
    final rect = Rect.fromCenter(
      center: Offset(-.25 - .02 * k, .27 + .03 * k),
      width: 2 * r,
      height: 2 * r * .92,
    );
    c.drawOval(
      rect,
      KingCooKit.fill(
        h.tone.lit(
          _mix(KingCooPalette.featherLit, KingCooPalette.feather, .55),
        ),
      ),
    );
    c.drawOval(rect, KingCooKit.line(_ink, KingCooLayout.inkPart * 1.1));
  }

  /// The dizzy ring: three stars circling the cap's band.
  static void _stars(Canvas c, KingCooHeadPose h) {
    final spin = h.time * 3.2;
    final p = Path();
    for (var i = 0; i < 3; i++) {
      final a = spin + i * 2 * math.pi / 3;
      p.addPath(_star, Offset(.86 * math.cos(a), -.62 + .20 * math.sin(a)));
    }
    c.drawPath(p, KingCooKit.fill(KingCooPalette.gold));
  }

  // ------------------------------------------------------------------- eye --

  /// The eye, in the head's frame: a big glossy amber iris under a heavy lid
  /// and a slanted brow, with a hard white glint. It sits a little below the
  /// layout's [eye] anchor (inside the iris, so `eyeAt` lands on it) to leave
  /// room for the brow under the cap. The lids are exact circle segments (no
  /// clip): the upper lid is cut by a chord that slants down toward the beak
  /// (the grump), steeper in anger, tilted up in worry; squinting raises the
  /// lower lid too; shut, the eye is a line.
  static void _eye(Canvas c, KingCooHeadPose h) {
    const r = _eyeR;
    final tone = h.tone;
    final anger = _clamp01(h.anger), worry = _clamp01(h.worry);
    final squint = _clamp01(h.squint), blink = _clamp01(h.blink);
    final surprise = ((h.beak - .18) * (1 - anger) * (1 - squint)).clamp(
      0.0,
      1.0,
    );

    // Lid coverage of the eye's height (0 bare .. 1 shut), the slant of the
    // chord (radians, positive: the beak side is lower) and the lower lid.
    // A squint with no anger, no worry and no flinch is a grin (the happy
    // story pose): the lower lid pushes up into a smiling eye.
    final flinch = _clamp01(h.wince * 4);
    final joy =
        ((squint - .3) / .15).clamp(0.0, 1.0) *
        (1 - anger) *
        (1 - worry) *
        (1 - flinch);
    final sq = squint * (1 - joy);
    var cover =
        .30 + .28 * sq + .02 * anger - .30 * worry - .30 * surprise - .18 * joy;
    var lower = .34 * sq + .14 * _clamp01(h.cheek) + .40 * joy;
    final open = (1 - cover.clamp(0.0, 1.0) - lower) * (1 - blink);
    cover = cover.clamp(0.0, .95);
    lower = lower.clamp(0.0, .6);
    final slant = .20 + .36 * anger - .62 * worry - .14 * surprise - .30 * joy;

    c.save();
    c.translate(_eyeAt.dx, _eyeAt.dy);

    if (h.dizzy > .5) {
      // X eyes: a pale disc and a fat ink cross.
      c.drawCircle(
        Offset.zero,
        r,
        KingCooKit.fill(tone.lit(KingCooPalette.cream)),
      );
      c.drawCircle(Offset.zero, r, KingCooKit.line(_ink, .055));
      c.drawPath(
        Path()
          ..moveTo(-.11, -.11)
          ..lineTo(.11, .11)
          ..moveTo(.11, -.11)
          ..lineTo(-.11, .11),
        KingCooKit.line(_ink, .075),
      );
      _browAt(c, r * .55, .12 - .7 * worry, worry);
      c.restore();
      return;
    }

    if (open < .2) {
      // Shut: a blink is a lid line (a smile upside down), a wince or a hard
      // squint a chevron pointing at the nape.
      final wince = squint > .6 && joy < .5;
      final p = Path();
      if (wince) {
        p
          ..moveTo(-.16, -.13)
          ..lineTo(.11, .0)
          ..lineTo(-.16, .13);
      } else {
        p
          ..moveTo(-.20, -.03)
          ..quadraticBezierTo(0, .13, .20, -.03);
      }
      c.drawPath(p, KingCooKit.line(_ink, .08));
      _browAt(c, wince ? .02 : .05, wince ? slant : slant * .6);
      c.restore();
      return;
    }

    // The iris, a big glossy amber disc.
    c.save();
    c.scale(r);
    c.drawCircle(Offset.zero, 1, _irisPaint);
    if (h.fury > .02) {
      c.drawCircle(
        Offset.zero,
        1,
        KingCooKit.fill(KingCooPalette.sirenRed, .42 * h.fury),
      );
    }
    c.drawPath(
      _irisBounce,
      KingCooKit.fill(const Color(0xffffd98a), .55 * (1 - tone.washAlpha)),
    );
    c.restore();

    // The pupil: big and soft-eyed at rest, a pinprick in fury, wide in worry.
    final pr = r * (.50 + .14 * worry + .10 * joy - .20 * anger);
    final shift = (cover - .30) * .10;
    final look = Offset(
      -.03 + .07 * h.lookX,
      .02 + .075 * h.lookY + .02 * worry + shift,
    );
    c.drawCircle(look, pr, KingCooKit.fill(_ink));

    // The glints: one hard pill and a pinpoint, riding down as the lid does.
    c.save();
    c.translate(0, cover * .10);
    c.drawPath(
      _glints,
      KingCooKit.fill(KingCooPalette.white, tone.flash > .3 ? .6 : 1),
    );
    c.restore();

    // The lids: the circle segment above a chord (the upper lid) and, in a
    // squint, the one under a flatter chord (the lower), in shaded skin, both
    // one fill; the ring and the lid lines are one ink stroke.
    final lidColor = tone.plate(
      _mix(KingCooPalette.feather, KingCooPalette.featherDeep, .5),
    );
    final t = r * (1 - 2 * cover); // the chord's offset from the centre, up
    final n = Offset(-math.sin(slant), -math.cos(slant)); // up, leaning
    final d = Offset(math.cos(slant), -math.sin(slant)); // along the chord
    const eyeRect = Rect.fromLTRB(-r, -r, r, r);
    final lids = Path();
    final ink = Path()..addOval(eyeRect);
    if (cover > .02) {
      final half = math.sqrt(math.max(0.0, r * r - t * t));
      final phi = math.atan2(n.dy, n.dx);
      final beta = math.acos((t / r).clamp(-1.0, 1.0));
      final from = KingCooKit.polar(phi - beta, r);
      lids
        ..moveTo(from.dx, from.dy)
        ..arcTo(eyeRect, phi - beta, 2 * beta, false)
        ..close();
      final a = n * t - d * (half + .03), b = n * t + d * (half + .03);
      ink
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    if (lower > .02) {
      final lt = r * (1 - 2 * lower);
      final beta = math.acos((lt / r).clamp(-1.0, 1.0));
      final from = KingCooKit.polar(math.pi / 2 - beta, r);
      lids
        ..moveTo(from.dx, from.dy)
        ..arcTo(eyeRect, math.pi / 2 - beta, 2 * beta, false)
        ..close();
      final half = math.sqrt(math.max(0.0, r * r - lt * lt));
      ink
        ..moveTo(-half, lt)
        ..lineTo(half, lt);
    }
    if (cover > .02 || lower > .02) c.drawPath(lids, KingCooKit.fill(lidColor));
    c.drawPath(ink, KingCooKit.line(_ink, .065));
    if (lower < .05) {
      c.drawPath(
        _bag,
        KingCooKit.line(
          KingCooPalette.inkCool,
          KingCooLayout.inkDetail,
          .5 * (1 - tone.washAlpha),
        ),
      );
    }

    // The brow rides the chord.
    _browAt(c, t, slant, worry);
    c.restore();
  }

  /// The brow: a tapered ridge over the eye, slanted with the lid, in the
  /// eye's frame (origin the eye's centre). [chordOffset] is how far above the
  /// centre (along the chord's normal) it rests.
  static void _browAt(
    Canvas c,
    double chordOffset,
    double slant, [
    double worry = 0,
  ]) {
    c.save();
    final n = Offset(-math.sin(slant), -math.cos(slant));
    final base = n * (chordOffset + .02);
    c.translate(base.dx, base.dy);
    c.rotate(-slant);
    if (worry > .05) c.scale(1 - .22 * worry, 1 - .3 * worry);
    c.drawPath(_browShape, KingCooKit.fill(_ink));
    c.restore();
  }

  // ------------------------------------------------------------------- cap --

  /// The cap, its band centred on the skull's seat: tilts about the band,
  /// hops with [KingCooHeadPose.capLift], flies with [capSpin], and carries
  /// the brass badge and the siren (with its glow).
  static void cap(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    if (h.capOff) return;
    c.save();
    c.translate(h.at.dx + h.capLift.dx, h.at.dy + h.capLift.dy);
    c.rotate(h.tilt);
    _capBody(c, h.tone, h.capTilt + h.capSpin, h.siren, h.sirenGlow, h.time);
    c.restore();
  }

  /// Only the cap, its band centre at the origin (for the defeat's tumble, the
  /// keepsake and the health bar's crest). The siren is [siren] (0 off, 1 red,
  /// 2 blue) at [sirenGlow]; [time] (the pose's clock, 0 under Reduced Motion
  /// and for a keepsake) runs the rain drops on the crown (K8: the falling cap
  /// carries on with the drops it wore).
  static void capOnly(
    Canvas c, {
    KingCooTone tone = KingCooTone.calm,
    int siren = 0,
    double sirenGlow = 0,
    double time = 0,
  }) {
    c.save();
    c.translate(-capSeat.dx, -capSeat.dy);
    _capBody(
      c,
      tone,
      0,
      sirenGlow.isFinite ? siren : 0,
      sirenGlow.isFinite ? sirenGlow : 0,
      time,
    );
    c.restore();
  }

  static void _capBody(
    Canvas c,
    KingCooTone tone,
    double tilt,
    int siren,
    double glow,
    double time,
  ) {
    if (!tilt.isFinite) tilt = 0;
    if (!time.isFinite) time = 0;
    final lit = glow > .02 && siren != 0;
    c.save();
    c.translate(capSeat.dx, capSeat.dy);
    c.rotate(tilt);
    c.translate(-capSeat.dx, -capSeat.dy);

    // The visor: a black patent plate pointing forward and down.
    c.drawPath(_visor, _visorPaint);
    c.drawPath(_visor, KingCooKit.line(_ink, KingCooLayout.inkPart));
    // The crown over the band: one fill, one gradient, the tone over all three
    // parts, police checks on the band, one ink, gold piping.
    c.drawPath(_capShape, _capPaint);
    if (tone.washAlpha > 0) {
      // The navy is the darkest mass: the hit bleaches it harder, so the whole
      // head flashes white (not lilac-grey) against any sky.
      c.drawPath(
        _capAll,
        KingCooKit.fill(
          KingCooPalette.bleach,
          (tone.washAlpha * 1.4).clamp(0.0, .84),
        ),
      );
    }
    c.drawPath(
      _checks,
      KingCooKit.fill(KingCooPalette.blueLit, .55 * (1 - tone.washAlpha)),
    );
    c.drawPath(_capInk, KingCooKit.line(_ink, KingCooLayout.inkPart * 1.2));
    c.drawPath(
      _piping,
      KingCooKit.line(
        tone.lit(KingCooPalette.brass),
        KingCooLayout.inkPart * .85,
      ),
    );
    if (tone.skyRim > .02 || tone.sirenGlow > .05) {
      c.drawPath(
        _crownRim,
        KingCooKit.fill(
          tone.lit(_sirenTint(tone)),
          math.max(tone.skyRim * .9, .85 * _sirenAmount(tone)),
        ),
      );
    }
    c.drawPath(
      _capGlints,
      KingCooKit.line(KingCooPalette.white, .04, .55 * (1 - tone.washAlpha)),
    );
    // The badge on the band.
    c.drawPath(_badge, _brassPaint);
    c.drawPath(_badgeStar, KingCooKit.fill(KingCooPalette.inkWarm));
    // The siren: a dome on a steel skirt, lit red or blue, with its glow.
    c.drawPath(_dome, _domePaint(lit ? siren : 0));
    c.drawPath(_dome, KingCooKit.line(_ink, .05));
    c.drawPath(_domeGlint, KingCooKit.line(KingCooPalette.white, .03, .9));
    if (lit) {
      final col = siren == 2
          ? KingCooPalette.sirenBlue
          : KingCooPalette.sirenRed;
      KingCooKit.glow(
        c,
        const Offset(0, -.895),
        .46 + .30 * glow,
        col,
        .5 * glow,
      );
      c.drawPath(
        _rays(_clamp01(glow)),
        KingCooKit.line(col, .05, (.46 * glow).clamp(0.0, .46)),
      );
    }
    c.restore();
    // Raindrops run down the crown (motion): none under Reduced Motion. One
    // path, each drop shrinking to nothing as it falls, so none ever pops.
    if (time > 0) {
      final drops = Path();
      for (var i = 0; i < 3; i++) {
        final fall = (time * .7 + KingCooKit.hash(i, 3)) % 1.0;
        drops.addOval(
          Rect.fromCircle(
            center: Offset(-.42 + i * .36, -.76 + .30 * fall),
            radius: .032 * (1 - fall),
          ),
        );
      }
      c.drawPath(drops, KingCooKit.fill(KingCooPalette.white, .7));
    }
  }

  // --------------------------------------------------------------- whistle --

  /// The whistle on its chain: hanging at the chest's edge until it is raised
  /// into the beak (then the chain fades and the whistle hangs from the beak,
  /// its chamber below it). It buzzes at the blast.
  static void whistle(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    final a = _clamp01(h.whistle);
    final at = h.whistleAt;
    final tone = h.tone;
    // Hanging: the chamber down. Held: it lies along the beak, the chamber
    // slung under it (the head's own turn counts).
    final angle = 1.15 * (1 - a) + (.55 + h.tilt) * a;
    if (a < .98) {
      // The chain: from the ring up to the neck, sagging.
      final ring = at + KingCooKit.turn(const Offset(.49, .05), angle);
      const to = KingCooLayout.chainAnchor;
      final mid = Offset.lerp(ring, to, .5)! + const Offset(.16, .14);
      c.drawPath(
        Path()
          ..moveTo(ring.dx, ring.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy),
        KingCooKit.line(KingCooPalette.steelDeep, KingCooLayout.hair, 1 - a),
      );
    }
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    c.drawPath(_whistleBody, KingCooKit.line(_ink, KingCooLayout.inkPart * 2));
    c.drawPath(_whistleBody, _steelPaint);
    KingCooKit.wash(c, _whistleBody, tone, flush: false);
    c.drawPath(_whistleHole, KingCooKit.fill(_ink));
    c.drawPath(
      _whistleGlint,
      KingCooKit.line(KingCooPalette.white, .03, .9 * (1 - tone.washAlpha)),
    );
    if (h.blast > .05) {
      c.drawPath(
        _tweet,
        KingCooKit.line(KingCooPalette.white, .045, _clamp01(h.blast)),
      );
    }
    c.restore();
  }

  // ----------------------------------------------------------------- steam --

  /// Fury's steam: three soft puffs rise from behind the cap (motion only; the
  /// pose's `steam` is 0 under Reduced Motion and while he is held still).
  static void steam(Canvas c, KingCooHeadPose h) {
    h = h.safe;
    if (h.steam <= 0) return;
    for (var i = 0; i < _puffs; i++) {
      final life = (h.time * .9 + i / _puffs) % 1.0;
      final at =
          h.at +
          Offset(
            .55 + .24 * i + .12 * math.sin(life * 6 + i),
            -.30 - .85 * life,
          );
      final alpha = h.steam * math.sin(life * math.pi) * .7;
      if (alpha <= .02) continue;
      final r = .20 + .26 * life;
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(r);
      c.drawCircle(Offset.zero, 1, _puffPaint(alpha.clamp(0.0, .7)));
      c.restore();
    }
  }
}
