import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import 'king_coo_kit.dart';
import 'king_coo_layout.dart';
import 'king_coo_pose.dart';

/// What King Coo's body needs from the pose: the chest's swell, the tail's
/// fan and wag, the legs' phase, the sack's sway, the stomp, the tone.
///
/// Every channel is sanitised by [finite] before anything is drawn (a NaN
/// from a bad replay becomes the rest value), so no painter here can put a
/// non-finite number on the canvas.
final class KingCooBodyPose {
  const KingCooBodyPose({
    required this.puff,
    required this.tailFan,
    required this.tailWag,
    required this.pedal,
    required this.sackSwing,
    required this.stomp,
    required this.tone,
    this.windup = 0,
    this.follow = 0,
    this.bombHeld = 0,
    this.motion = true,
    this.damage = 0,
    this.time = 0,
  });

  factory KingCooBodyPose.of(KingCooPose pose) => KingCooBodyPose(
    puff: pose.puff,
    tailFan: pose.tailFan,
    tailWag: pose.tailWag,
    pedal: pose.pedal,
    sackSwing: pose.sackSwing,
    stomp: pose.stomp,
    tone: pose.tone,
    windup: pose.windup,
    follow: pose.follow,
    bombHeld: pose.bombHeld,
    motion: !pose.reduced,
    damage: pose.doubleDamage,
    time: pose.reduced ? 0 : pose.time,
  ).finite;

  final double puff, tailFan, tailWag, pedal, sackSwing, stomp;
  final KingCooTone tone;

  /// The throw the sack answers (the pose's own channels): [windup] 0..1
  /// through the wind-up and back down as the arm goes home, [follow] the
  /// swing's weight and, after the release, 1 falling to 0, [bombHeld] 1 from
  /// the dip's end until the release; [motion] false under Reduced Motion.
  final double windup, follow, bombHeld;
  final bool motion;

  /// The double-damage window (the pose's `doubleDamage`, 0..1: a state, kept
  /// under Reduced Motion) and the pose's clock (0 under Reduced Motion: the
  /// pulses hold their middle value, the feather ruffle holds still).
  final double damage, time;

  /// The 1.6 Hz beat of the puffed chest's gold: 0..1, .5 when still.
  double get beat => time == 0 ? .5 : .5 + .5 * math.sin(time * 2 * math.pi * 1.6);

  /// How far the sack has swung because of the throw, on top of its own sway
  /// ([sackSwing]): it sways toward the bird while the arm is back (a pose:
  /// kept under Reduced Motion), is slung back by the release and rocks as it
  /// settles (motion), and jolts with the stomp. Zero at rest, and continuous
  /// through every edge (the release starts the rocking from zero).
  double get sackKick {
    // After the release the bomb is gone (bombHeld 0) and the follow-through
    // weight is 1 falling to 0; before it, the weight is 0 until the swing.
    final released = bombHeld < .5 && follow > 0;
    final sway = released
        ? (motion ? -.28 * follow * math.sin(3 * math.pi * (1 - follow)) : 0.0)
        : .14 * math.sin(math.pi * windup.clamp(0.0, 1.0));
    return (sway + (motion ? .10 * stomp : 0.0)).clamp(-.5, .5);
  }

  /// The chest's outline radius for [puff]: .84 fluffed .. 1.0 puffed (more
  /// in the defeat's inflating). The INK's centre line: the honest circle.
  double get chestRadius => KingCooLayout.chestRadiusAt(puff);

  /// How far the puffed chest is taut (0 fluffed .. 1 smooth), the widest the
  /// scallops get and how lit the badge is.
  double get taut => puff.clamp(0.0, 1.0);

  /// This pose with every channel finite and in range; `this` when it
  /// already is (no allocation in the common case).
  KingCooBodyPose get finite {
    bool ok(double v, double lo, double hi) => v.isFinite && v >= lo && v <= hi;
    final t = tone;
    final toneOk =
        t.flash.isFinite &&
        t.fury.isFinite &&
        t.heat.isFinite &&
        t.dark.isFinite &&
        t.sirenGlow.isFinite;
    if (toneOk &&
        ok(puff, 0, 1.4) &&
        ok(tailFan, 0, 1) &&
        ok(tailWag, -.6, .6) &&
        pedal.isFinite &&
        ok(sackSwing, -.8, .8) &&
        ok(stomp, 0, 1) &&
        ok(windup, 0, 1) &&
        ok(follow, 0, 1) &&
        ok(bombHeld, 0, 1) &&
        ok(damage, 0, 1) &&
        time.isFinite) {
      return this;
    }
    double f(double v, double lo, double hi) =>
        v.isFinite ? v.clamp(lo, hi) : 0.0;
    return KingCooBodyPose(
      puff: f(puff, 0, 1.4),
      tailFan: f(tailFan, 0, 1),
      tailWag: f(tailWag, -.6, .6),
      pedal: pedal.isFinite ? pedal % (2 * math.pi) : 0,
      sackSwing: f(sackSwing, -.8, .8),
      stomp: f(stomp, 0, 1),
      windup: f(windup, 0, 1),
      follow: f(follow, 0, 1),
      bombHeld: f(bombHeld, 0, 1),
      motion: motion,
      damage: f(damage, 0, 1),
      time: time.isFinite ? time : 0,
      tone: toneOk
          ? t
          : KingCooTone(
              flash: f(t.flash, 0, 1),
              fury: f(t.fury, 0, 1),
              heat: f(t.heat, 0, 1),
              dark: f(t.dark, 0, 1),
              siren: t.siren,
              sirenGlow: f(t.sirenGlow, 0, 1),
              sky: t.sky,
            ),
    );
  }
}

/// King Coo's body: the chest (the hit circle), the teardrop torso behind it,
/// long coral legs, the narrow wedge tail and the crumb sack.
///
/// Two ways to paint it. Through [KingCooBossRig] with every part of the hide
/// present, `KingCooHide` (`king_coo_hide_art.dart`) lays the torso, chest,
/// tail, neck, skull and near thigh as ONE creature under one outline and
/// calls the building blocks below (`chestSkin`, `torsoDetail`, `tailSkin`,
/// `legUnder`). Painted alone (the `only:` tests, a part by itself), every
/// entry point (`farLeg tail torso sack nearLeg chest`) wears its own full
/// outline, as the contract's first cut did.
///
/// Nothing pose-independent is built per frame: every outline is a
/// `static final`, every gradient is `KingCooKit.cached` in figure space, the
/// chest's scallops come from `KingCooKit.scallop` (depth in 1/16 steps).
abstract final class KingCooBodyArt {
  // ---------------------------------------------------------------- frames --

  static final Float64List _m = Float64List(16);

  /// A 4x4 matrix (column major) for `translate(tx, ty) rotate(angle)
  /// scale(sx, sy)`, in a scratch list that is reused by the next call: use it
  /// at once (`Path.addPath` copies it).
  static Float64List matrix(
    double tx,
    double ty, {
    double angle = 0,
    double sx = 1,
    double? sy,
  }) {
    final cs = math.cos(angle), sn = math.sin(angle), y = sy ?? sx;
    _m
      ..[0] = sx * cs
      ..[1] = sx * sn
      ..[2] = 0
      ..[3] = 0
      ..[4] = -y * sn
      ..[5] = y * cs
      ..[6] = 0
      ..[7] = 0
      ..[8] = 0
      ..[9] = 0
      ..[10] = 1
      ..[11] = 0
      ..[12] = tx
      ..[13] = ty
      ..[14] = 0
      ..[15] = 1;
    return _m;
  }

  // ------------------------------------------------------------- outlines --

  /// The layout's torso: the standalone part's outline.
  static final Path torsoShape = KingCooKit.spline(KingCooLayout.bodyOutline);

  /// The torso as the hide lays it: a slim cone that starts behind the chest
  /// globe and tapers to the rump, so the globe stands out above the back line
  /// and below the belly (a hunched, deep body read as a hen at 120 px). The
  /// front is pulled inside the fluffed chest so no rim of torso shows round
  /// it. The rump (x 2.44, y .22-.50), the tail root and the belly under the
  /// sack keep the layout's places.
  static const hideOutline = <Offset>[
    Offset(-.70, -.95),
    Offset(-.10, -.90),
    Offset(.55, -.76),
    Offset(1.20, -.64),
    Offset(1.85, -.38),
    Offset(2.26, -.06),
    Offset(2.44, .22),
    Offset(2.44, .50),
    Offset(2.15, .70),
    Offset(1.55, .84),
    Offset(.95, .90),
    Offset(.35, .94),
    Offset(-.30, .80),
    Offset(-.62, .38),
    Offset(-.68, -.38),
  ];
  static final Path hideTorso = KingCooKit.spline(hideOutline);

  /// The near thigh: a tuft of breast-coloured leg feathers under the belly
  /// with three scallops at its hem, where the coral shank comes out. It is a
  /// part of the skin (the hide fills it with the torso's own gradient), so
  /// the belly runs into the thigh with no line between them. [farThigh] is
  /// the far leg's, smaller, behind the near one.
  static Path _thigh(double cx, double cy, double s) {
    // Clockwise (down the right side, along the hem to the left, up the left
    // side) like every other part, so the union fills.
    final p = Path()
      ..moveTo(cx + .34 * s, cy - .18 * s)
      ..cubicTo(cx + .40 * s, cy - .02 * s, cx + .36 * s, cy + .18 * s, cx + .30 * s, cy + .27 * s);
    for (var i = 0; i < 3; i++) {
      final x0 = cx + .30 * s - i * .20 * s, x1 = x0 - .20 * s;
      p.quadraticBezierTo((x0 + x1) / 2, cy + .42 * s, x1, cy + .27 * s);
    }
    return p
      ..cubicTo(cx - .36 * s, cy + .18 * s, cx - .40 * s, cy - .02 * s, cx - .34 * s, cy - .18 * s)
      ..close();
  }

  static final Path nearThigh = _thigh(.25, 1.10, 1.0);
  static final Path farThigh = _thigh(.60, 1.02, .80);

  /// A tail feather along +x from its root: broad, with a rounded-square tip
  /// (a pigeon's tail, not a leaf). Length [l], full width [w].
  static Path _feather(double l, double w) {
    final h = w / 2;
    return Path()
      ..moveTo(0, -h * .10)
      ..cubicTo(l * .12, -h * 1.05, l * .30, -h, l * .62, -h * .98)
      ..cubicTo(l * .86, -h * .94, l * 1.03, -h * .55, l * 1.03, 0)
      ..cubicTo(l * 1.03, h * .55, l * .86, h * .94, l * .62, h * .98)
      ..cubicTo(l * .30, h, l * .12, h * 1.05, 0, h * .10)
      ..close();
  }

  static final List<Path> tailFeathers = [
    for (final l in KingCooLayout.tailLengths)
      _feather(l, KingCooLayout.tailWidth * .84),
  ];

  /// The angle of tail feather [i] (0 the top one) for [b]: a narrow wedge
  /// sloping down from the rump at rest, opening to a full fan with the fan
  /// channel.
  static double featherAngle(KingCooBodyPose b, int i) =>
      b.tailWag + .12 + (i - 1.5) * (.034 + .20 * b.tailFan);

  /// The four feathers laid from the tail root, as ONE path (they all wind
  /// the same way: it fills and strokes as their union).
  static Path tailUnion(KingCooBodyPose b) {
    final out = Path();
    for (var i = 0; i < 4; i++) {
      out.addPath(
        tailFeathers[i],
        Offset.zero,
        matrix4: matrix(
          KingCooLayout.tailRoot.dx,
          KingCooLayout.tailRoot.dy,
          angle: featherAngle(b, i),
        ),
      );
    }
    return out;
  }

  /// The chest as a figure-frame path of outline radius [r], [taut] 0..1
  /// flattening the scallops (15 bumps always, depth .07 -> .012).
  static Path chestPath(double r, double taut) {
    final step = (taut.clamp(0.0, 1.0) * 16).round() / 16;
    final depth =
        KingCooLayout.chestFluffDepth +
        (KingCooLayout.chestTautDepth - KingCooLayout.chestFluffDepth) * step;
    return KingCooKit.scallop(
      KingCooLayout.chestBumps,
      depth,
      turn: -.2,
    ).transform(matrix(0, 0, sx: r));
  }

  // ---------------------------------------------------------- torso detail --

  /// Back and flank feather rows: scallops in rows that follow the slope of
  /// the back, their pitch shrinking toward the tail (foreshortening), in one
  /// path.
  static final Path backRows = () {
    final path = Path();
    // Row k follows the back line dropped by `.26 (k+1)`; x runs from the
    // shoulder to the rump.
    double back(double x) => x < .1
        ? -1.0 + (x + .3) * .1
        : -1.03 + (x - .1) * (x - .1) * .10 + (x - .1) * .20;
    for (var k = 0; k < 4; k++) {
      var x = -.05 + (k.isOdd ? .14 : 0);
      while (x < 2.05 - k * .12) {
        final pitch = .30 - .12 * ((x + .05) / 2.1).clamp(0.0, 1.0);
        final y0 = back(x) + .30 * (k + 1) * (1 - .18 * x.clamp(0.0, 2.2) / 2.2);
        final y1 = back(x + pitch) + .30 * (k + 1) * (1 - .18 * (x + pitch).clamp(0.0, 2.2) / 2.2);
        path
          ..moveTo(x, y0)
          ..quadraticBezierTo(x + pitch / 2, (y0 + y1) / 2 + pitch * .62, x + pitch, y1);
        x += pitch;
      }
    }
    return path;
  }();

  /// The under-tail coverts: three big scallops across the rump, over the
  /// roots of the tail feathers. The hide and the standalone torso both draw
  /// them, so the tail grows out from under the rump's own feathers.
  static final Path coverts = () {
    final path = Path();
    const pts = [
      Offset(2.04, -.34),
      Offset(2.30, -.08),
      Offset(2.40, .24),
      Offset(2.30, .56),
    ];
    for (var i = 0; i < 3; i++) {
      final a = pts[i], b = pts[i + 1];
      final mid = Offset.lerp(a, b, .5)! + const Offset(.11, -.02);
      path
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    }
    return path;
  }();

  /// A second, shorter row of coverts a little further in.
  static final Path covertsInner = () {
    final path = Path();
    const pts = [
      Offset(1.80, -.28),
      Offset(2.02, .00),
      Offset(2.10, .30),
      Offset(2.02, .62),
    ];
    for (var i = 0; i < 3; i++) {
      final a = pts[i], b = pts[i + 1];
      final mid = Offset.lerp(a, b, .5)! + const Offset(.09, -.02);
      path
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    }
    return path;
  }();

  /// The thigh's leg feathers: short barbs at the hem of each tuft, in one path.
  static final Path thighRows = () {
    final p = Path();
    for (final (cx, cy, k) in const [(.25, 1.10, 1.0), (.60, 1.02, .8)]) {
      for (var i = 0; i < 3; i++) {
        final x = cx - .20 * k + i * .20 * k;
        p
          ..moveTo(x - .05 * k, cy + .02 * k)
          ..quadraticBezierTo(x, cy + .18 * k, x + .05 * k, cy + .02 * k);
      }
    }
    return p;
  }();

  /// The pale under-belly band (lit from the windows below): a stroke along
  /// the belly, inside the silhouette.
  static final Path bellyBand = KingCooKit.spline(const [
    Offset(.05, .86),
    Offset(.70, .90),
    Offset(1.35, .78),
    Offset(1.95, .52),
  ], closed: false);

  // ----------------------------------------------------------------- paints --

  /// The plumage skin in figure space: light at the head and shoulder, the
  /// lilac deepening down the flank and toward the tail. One gradient for the
  /// torso, neck and thigh, so they match wherever they meet.
  static Paint get skinPaint => KingCooKit.cached(
    'body.skin',
    () => KingCooKit.linear(const Offset(-.3, -2.05), const Offset(.9, 1.45), [
      Color.lerp(KingCooPalette.featherLit, KingCooPalette.feather, .34)!,
      KingCooPalette.feather,
      KingCooPalette.featherDeep,
      Color.lerp(KingCooPalette.featherDeep, KingCooPalette.featherDark, .55)!,
    ], const [0, .34, .72, 1]),
  );

  /// The under-belly's shade: the torso deepens toward the belly (the globe
  /// above it stays the brightest big shape).
  static Paint get _bellyShade => KingCooKit.cached(
    'body.belly.shade',
    () => KingCooKit.linear(const Offset(0, .10), const Offset(0, 1.15), [
      KingCooPalette.featherCore.withValues(alpha: 0),
      KingCooPalette.featherCore.withValues(alpha: .34),
    ]),
  );

  static Paint get _breastPaint => KingCooKit.cached(
    'body.breast',
    () => KingCooKit.radial(const Offset(.30, -.40), 1.32, [
      KingCooPalette.breastHi,
      KingCooPalette.breastLit,
      KingCooPalette.breast,
      KingCooPalette.breastDeep,
    ], const [0, .34, .74, 1]),
  );
  static Paint get _featherPaint => KingCooKit.cached(
    'body.tail',
    () {
      final band = Color.lerp(KingCooPalette.bar, KingCooPalette.featherDark, .7)!;
      return KingCooKit.linear(Offset.zero, const Offset(1.62, 0), [
        KingCooPalette.featherDeep,
        KingCooPalette.feather,
        Color.lerp(KingCooPalette.feather, KingCooPalette.featherLit, .35)!,
        Color.lerp(KingCooPalette.featherDeep, band, .5)!,
        band,
        band,
        Color.lerp(band, KingCooPalette.featherDeep, .5)!,
      ], const [0, .40, .62, .72, .78, .94, 1]);
    },
  );
  static Paint get _sackPaint => KingCooKit.cached(
    'body.sack',
    () => KingCooKit.radial(const Offset(1.45, .92), 1.15, [
      KingCooPalette.burlapLit,
      KingCooPalette.burlap,
      KingCooPalette.burlapDeep,
    ], const [0, .55, 1]),
  );
  static Paint get _shieldPaint => KingCooKit.cached(
    'body.badge',
    () => KingCooKit.linear(
      const Offset(0, -KingCooLayout.badgeSize),
      const Offset(0, KingCooLayout.badgeSize * 1.2),
      [KingCooPalette.brassLit, KingCooPalette.brass, KingCooPalette.brassDeep],
    ),
  );

  // ---------------------------------------------------------------- legs --

  /// A leg's three points: the hip, the heel (the shank bows back a little)
  /// and the foot, which swings .16 with the pedal, lifts a little and is
  /// stamped up by the stomp.
  static ({Offset hip, Offset heel, Offset foot, double swing}) legAt(
    KingCooBodyPose b,
    bool far,
  ) {
    final hip = far ? KingCooLayout.farHip : KingCooLayout.nearHip;
    final sw = math.sin(far ? b.pedal + math.pi : b.pedal);
    final foot = Offset(
      hip.dx - .18 + sw * KingCooLayout.footReach,
      KingCooLayout.footY -
          sw.abs() * KingCooLayout.footLift +
          (far ? .02 : 0) -
          b.stomp * .30,
    );
    final heel = Offset.lerp(hip, foot, .58)! + Offset(.07 - sw * .02, 0);
    return (hip: hip, heel: heel, foot: foot, swing: sw);
  }

  /// Toes in the foot's frame (origin the ankle, forward is -x): three long
  /// toes that droop at the tip and a short hind toe, in one path, and the
  /// claws at their ends.
  static final Path _toes = Path()
    ..moveTo(.02, .00)
    ..quadraticBezierTo(-.20, -.10, -.33, -.02)
    ..moveTo(.02, .02)
    ..quadraticBezierTo(-.15, .06, -.26, .12)
    ..moveTo(.02, -.01)
    ..quadraticBezierTo(-.14, -.17, -.23, -.14)
    ..moveTo(.03, .02)
    ..lineTo(.14, .07);
  static final Path _claws = Path()
    ..moveTo(-.33, -.02)
    ..lineTo(-.39, .01)
    ..moveTo(-.26, .12)
    ..lineTo(-.30, .15)
    ..moveTo(-.23, -.14)
    ..lineTo(-.28, -.14)
    ..moveTo(.14, .07)
    ..lineTo(.18, .10);

  /// The shank's scales: short cross lines along it, in the leg's frame (the
  /// shank runs from the origin down +y for one unit).
  static final Path _scales = () {
    final p = Path();
    for (var i = 1; i <= 5; i++) {
      final y = i * .15;
      p
        ..moveTo(-.045, y)
        ..lineTo(.045, y + .025);
    }
    return p;
  }();

  /// A leg below the skin: the shank as a bowed line with its scales and a
  /// highlight, the foot with its toes and claws. [far] is the darker one.
  static void legUnder(Canvas c, KingCooBodyPose b, {required bool far}) {
    final l = legAt(b, far);
    final tone = b.tone;
    final coral = tone.lit(far ? KingCooPalette.footDeep : KingCooPalette.foot);
    final shank = Path()
      ..moveTo(l.hip.dx, l.hip.dy)
      ..quadraticBezierTo(
        l.heel.dx + .03,
        l.heel.dy,
        l.foot.dx,
        l.foot.dy,
      );
    c.drawPath(shank, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkMajor + .145));
    c.drawPath(shank, KingCooKit.line(coral, .105));
    // The shank's lit edge (the moon is up and to the right) and its scales.
    c.save();
    c.translate(.032, 0);
    c.drawPath(
      shank,
      KingCooKit.line(
        tone.lit(far ? KingCooPalette.foot : const Color(0xffffd2b0)),
        .028,
        (.85 * (1 - tone.washAlpha)),
      ),
    );
    c.restore();
    c.save();
    final dir = l.foot - l.hip;
    c.translate(l.hip.dx, l.hip.dy);
    c.rotate(math.atan2(dir.dx, dir.dy) * -1);
    c.scale(1, dir.distance);
    c.drawPath(
      _scales,
      KingCooKit.line(
        KingCooPalette.footDeep,
        KingCooLayout.hair / math.max(dir.distance, .5),
        far ? .4 : .7,
      ),
    );
    c.restore();
    // The foot.
    c.save();
    c.translate(l.foot.dx, l.foot.dy);
    c.rotate(.22 * l.swing);
    c.drawPath(_toes, KingCooKit.line(KingCooPalette.ink, .175));
    c.drawPath(_toes, KingCooKit.line(coral, .085));
    c.drawPath(_claws, KingCooKit.line(KingCooPalette.inkWarm, .07));
    c.restore();
  }

  /// A leg painted alone: the thigh tuft with its own outline, then the leg.
  static void _leg(Canvas c, KingCooBodyPose b, {required bool far}) {
    legUnder(c, b, far: far);
    final tuft = far ? farThigh : nearThigh;
    final tone = b.tone;
    c.drawPath(tuft, skinPaint);
    if (far) {
      c.drawPath(tuft, KingCooKit.fill(KingCooPalette.featherCore, .22));
    }
    KingCooKit.wash(c, tuft, tone);
    c.drawPath(tuft, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkMajor));
  }

  static void farLeg(Canvas c, KingCooBodyPose b) => _leg(c, b.finite, far: true);

  static void nearLeg(Canvas c, KingCooBodyPose b) => _leg(c, b.finite, far: false);

  // ---------------------------------------------------------------- tail --

  /// The tail's skin: the four feathers back to front (the lowest first, so
  /// the higher ones lie over it in the moon's light), each with its gradient
  /// (lilac to a dark terminal band), its outline and its shaft. The outer
  /// contour is the hide's (or [tail]'s own); these lines are the feathers'
  /// edges where they overlap.
  static void tailSkin(Canvas c, KingCooBodyPose b, [Path? union]) {
    final tone = b.tone;
    final root = KingCooLayout.tailRoot;
    for (var i = 3; i >= 0; i--) {
      c.save();
      c.translate(root.dx, root.dy);
      c.rotate(featherAngle(b, i));
      final f = tailFeathers[i];
      c.drawPath(f, _featherPaint);
      c.drawPath(f, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkDetail * 1.15, .78));
      c.restore();
    }
    // The fury's flush and the hit's bleach over the four at once (their
    // outer ink lies outside the path and holds).
    if (tone.furyAlpha > 0 || tone.washAlpha > 0) {
      KingCooKit.wash(c, union ?? tailUnion(b), tone);
    }
    // The shafts and the moon on the top feather.
    final shafts = Path();
    for (var i = 0; i < 4; i++) {
      final a = featherAngle(b, i);
      final cs = math.cos(a), sn = math.sin(a);
      final l = KingCooLayout.tailLengths[i];
      shafts
        ..moveTo(root.dx + cs * .35, root.dy + sn * .35)
        ..lineTo(root.dx + cs * l * .88, root.dy + sn * l * .88);
    }
    c.drawPath(
      shafts,
      KingCooKit.line(KingCooPalette.featherCore, KingCooLayout.hair, .35),
    );
    final a0 = featherAngle(b, 0), cs = math.cos(a0), sn = math.sin(a0);
    final top = Offset(-sn, cs) * -.17;
    c.drawLine(
      root + Offset(cs, sn) * .60 + top,
      root + Offset(cs, sn) * 1.12 + top,
      KingCooKit.line(tone.lit(Color.lerp(tone.sky, KingCooPalette.white, .6)!), .05, tone.skyRim * .85),
    );
  }

  /// The tail painted alone: its feathers under one thick outline of their
  /// union, the skin over it, the covert row across the root.
  static void tail(Canvas c, KingCooBodyPose b) {
    b = b.finite;
    final union = tailUnion(b);
    c.drawPath(union, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkMajor * 1.9));
    tailSkin(c, b, union);
    c.drawPath(coverts, KingCooKit.line(KingCooPalette.inkCool, KingCooLayout.inkDetail, .8));
  }

  // ---------------------------------------------------------------- body --

  /// The torso's detail, inside a clip of the torso (or the hide's trunk): the
  /// belly's pale band, the back's feather rows and the coverts across the
  /// rump, all in one vocabulary so they run on unbroken across every joint.
  static void torsoDetail(Canvas c, KingCooBodyPose b) {
    final tone = b.tone;
    c.drawRect(
      const Rect.fromLTRB(-1.2, .10, 3.1, 1.7),
      Paint()
        ..shader = _bellyShade.shader
        ..color = Color.fromRGBO(0, 0, 0, 1 - tone.washAlpha),
    );
    c.drawPath(
      bellyBand,
      KingCooKit.line(
        KingCooPalette.featherLit,
        .20,
        .22 * (1 - tone.washAlpha),
      ),
    );
    c.save();
    c.translate(0, -.03);
    c.drawPath(
      backRows,
      KingCooKit.line(tone.lit(KingCooPalette.featherLit), KingCooLayout.inkDetail, .30),
    );
    c.restore();
    c.drawPath(
      backRows,
      KingCooKit.line(KingCooPalette.featherCore, KingCooLayout.inkDetail, .38),
    );
    c.drawPath(
      covertsInner,
      KingCooKit.line(KingCooPalette.featherCore, KingCooLayout.inkDetail, .42),
    );
    c.drawPath(
      thighRows,
      KingCooKit.line(KingCooPalette.featherCore, KingCooLayout.inkDetail, .40),
    );
    // The last covert row covers the feathers' roots: a lit lip above the dark
    // line so it reads as a layer, not a scratch.
    c.save();
    c.translate(-.012, -.028);
    c.drawPath(
      coverts,
      KingCooKit.line(tone.lit(KingCooPalette.feather), KingCooLayout.inkPart, .8),
    );
    c.restore();
    c.drawPath(
      coverts,
      KingCooKit.line(KingCooPalette.inkCool, KingCooLayout.inkDetail * 1.15, .85),
    );
  }

  /// The torso painted alone, with its own outline.
  static void torso(Canvas c, KingCooBodyPose b) {
    b = b.finite;
    final tone = b.tone;
    c.drawPath(torsoShape, skinPaint);
    KingCooKit.wash(c, torsoShape, tone);
    c.save();
    c.clipPath(torsoShape, doAntiAlias: false);
    torsoDetail(c, b);
    KingCooKit.edgeIn(c, torsoShape, tone, width: .11, shift: .07, warm: .8);
    c.restore();
    KingCooKit.inkHero(c, torsoShape, KingCooLayout.inkHero);
  }

  // ---------------------------------------------------------------- sack --

  /// The sack's body: a soft burlap bag, widest low, pinched at the neck (its
  /// extremes inside the layout's `sackOutline`: x 1.02-2.24, y .56-1.68).
  static final Path _sack = Path()
    ..moveTo(1.44, .70)
    ..cubicTo(1.10, .86, .98, 1.16, 1.04, 1.40)
    ..cubicTo(1.10, 1.62, 1.34, 1.70, 1.62, 1.70)
    ..cubicTo(1.92, 1.70, 2.16, 1.60, 2.22, 1.38)
    ..cubicTo(2.28, 1.14, 2.14, .86, 1.80, .70)
    ..close();

  /// The gathered neck above the rope: five pleats fanned out.
  static final Path _frill = Path()
    ..moveTo(1.44, .73)
    ..lineTo(1.29, .53)
    ..quadraticBezierTo(1.38, .62, 1.46, .50)
    ..quadraticBezierTo(1.54, .60, 1.62, .47)
    ..quadraticBezierTo(1.70, .60, 1.78, .50)
    ..quadraticBezierTo(1.86, .62, 1.95, .53)
    ..lineTo(1.80, .73)
    ..close();
  static final Path _pleats = Path()
    ..moveTo(1.50, .73)
    ..lineTo(1.46, .55)
    ..moveTo(1.62, .73)
    ..lineTo(1.62, .52)
    ..moveTo(1.74, .73)
    ..lineTo(1.78, .55);

  static final Path _strap = Path()
    ..moveTo(KingCooLayout.strapFrom.dx, KingCooLayout.strapFrom.dy)
    ..quadraticBezierTo(
      KingCooLayout.strapControl.dx,
      KingCooLayout.strapControl.dy,
      KingCooLayout.strapTo.dx,
      KingCooLayout.strapTo.dy,
    );
  static final Path _stitches = () {
    final p = Path();
    for (var i = 1; i < 10; i++) {
      final t = i / 10;
      final a = _quad(KingCooLayout.strapFrom, KingCooLayout.strapControl, KingCooLayout.strapTo, t);
      final b = _quad(KingCooLayout.strapFrom, KingCooLayout.strapControl, KingCooLayout.strapTo, t + .028);
      p
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    return p;
  }();
  static Offset _quad(Offset a, Offset c, Offset b, double t) =>
      a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

  /// The buckle where the strap leaves the wing's shadow.
  static final Rect _buckle = Rect.fromCenter(
    center: _quad(KingCooLayout.strapFrom, KingCooLayout.strapControl, KingCooLayout.strapTo, .17),
    width: .17,
    height: .21,
  );

  /// The weave of the burlap, in one path: rows and columns.
  static final Path _weave = () {
    final p = Path();
    for (var i = 0; i < 9; i++) {
      final y = .80 + i * .105;
      p
        ..moveTo(.95, y)
        ..lineTo(2.40, y + .03);
    }
    for (var i = 0; i < 10; i++) {
      final x = 1.02 + i * .14;
      p
        ..moveTo(x, .68)
        ..lineTo(x + .02, 1.75);
    }
    return p;
  }();

  /// CRUMBS, stencilled across the bag in block letters (a path of polylines,
  /// each letter a box .12 x .13).
  static final Path _stencil = () {
    const letters = <List<List<double>>>[
      [[.12, 0], [0, 0], [0, .13], [.12, .13]], // C
      [[0, .13], [0, 0], [.11, 0], [.11, .065], [0, .065], [.04, .065], [.12, .13]], // R
      [[0, 0], [0, .13], [.12, .13], [.12, 0]], // U
      [[0, .13], [0, 0], [.06, .07], [.12, 0], [.12, .13]], // M
      [[0, 0], [0, .13], [.10, .13], [.12, .10], [.10, .065], [0, .065], [.10, .065], [.12, .03], [.10, 0], [0, 0]], // B
      [[.12, 0], [0, 0], [0, .065], [.12, .065], [.12, .13], [0, .13]], // S
    ];
    final p = Path();
    const x0 = 1.62 - (6 * .12 + 5 * .045) / 2, y0 = 1.28;
    for (var i = 0; i < 6; i++) {
      final dx = x0 + i * (.12 + .045);
      final pts = letters[i];
      p.moveTo(dx + pts[0][0], y0 + pts[0][1]);
      for (final q in pts.skip(1)) {
        p.lineTo(dx + q[0], y0 + q[1]);
      }
    }
    return p;
  }();

  /// The rope round the neck and its two dangling ends, in one path.
  static final Path _tie = Path()
    ..moveTo(1.40, .745)
    ..quadraticBezierTo(1.62, .81, 1.84, .745)
    ..moveTo(1.74, .79)
    ..quadraticBezierTo(1.86, .90, 1.82, 1.02)
    ..moveTo(1.74, .79)
    ..quadraticBezierTo(1.94, .86, 2.00, .98);

  // The stale roll and the heel of a baguette that poke out of the sack: a
  // dark baked crust over pale crumb, scored, with a torn end.
  static final Path _roll = Path()
    ..addOval(Rect.fromCenter(center: Offset.zero, width: .54, height: .40));
  static final Path _rollTop = Path()
    ..moveTo(-.25, -.02)
    ..quadraticBezierTo(-.22, -.19, 0, -.19)
    ..quadraticBezierTo(.22, -.19, .25, -.02)
    ..quadraticBezierTo(0, -.09, -.25, -.02)
    ..close();
  static final Path _rollScore = Path()
    ..moveTo(-.13, -.14)
    ..quadraticBezierTo(-.07, -.07, -.14, .0)
    ..moveTo(.02, -.16)
    ..quadraticBezierTo(.08, -.09, .01, -.01)
    ..moveTo(.16, -.13)
    ..quadraticBezierTo(.20, -.07, .13, -.01);
  static final RRect _heel = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: .70, height: .22),
    const Radius.circular(.10),
  );
  static final Path _heelTop = Path()
    ..moveTo(-.30, -.03)
    ..quadraticBezierTo(-.28, -.10, -.18, -.10)
    ..lineTo(.25, -.10)
    ..quadraticBezierTo(.34, -.10, .34, -.02)
    ..quadraticBezierTo(0, -.05, -.30, -.03)
    ..close();
  static final Path _heelScore = Path()
    ..moveTo(-.19, -.09)
    ..lineTo(-.12, .02)
    ..moveTo(.01, -.09)
    ..lineTo(.08, .02)
    ..moveTo(.21, -.09)
    ..lineTo(.27, .0);
  static final Path _crumbs = () {
    final p = Path();
    for (final (x, y, r) in const [
      (1.27, .64, .04),
      (1.98, .66, .045),
      (2.10, .74, .03),
      (1.36, .78, .028),
    ]) {
      p.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
    }
    return p;
  }();

  /// The crumb sack on its strap over the back: a burlap bag with a woven
  /// hatch, CRUMBS stencilled across it, a gathered neck tied with rope, a
  /// stale roll and the heel of a baguette poking out of the mouth. It sways
  /// about its mouth with the channel (and so swings back with the throw's
  /// wind-up).
  static void sack(Canvas c, KingCooBodyPose b) {
    b = b.finite;
    final tone = b.tone;
    // The strap over the shoulder and its buckle.
    c.drawPath(_strap, KingCooKit.line(KingCooPalette.ink, .215));
    c.drawPath(_strap, KingCooKit.line(tone.lit(KingCooPalette.burlapDeep), .125));
    c.drawPath(
      _stitches,
      KingCooKit.line(tone.lit(KingCooPalette.burlapLit), KingCooLayout.hair, .8),
    );
    final buckle = RRect.fromRectAndRadius(_buckle, const Radius.circular(.035));
    c.drawRRect(buckle, KingCooKit.fill(tone.lit(KingCooPalette.brass)));
    c.drawRRect(buckle, KingCooKit.line(KingCooPalette.inkWarm, KingCooLayout.inkDetail));
    c.save();
    c.translate(KingCooLayout.sackMouth.dx, KingCooLayout.sackMouth.dy);
    c.rotate((b.sackSwing + b.sackKick).clamp(-.8, .8));
    c.translate(-KingCooLayout.sackMouth.dx, -KingCooLayout.sackMouth.dy);
    // What sticks out of the mouth goes first (the frill is in front of it).
    final crust = tone.lit(KingCooPalette.crust);
    c.save();
    c.translate(1.49, .40);
    c.rotate(-.34);
    c.drawPath(_roll, KingCooKit.fill(tone.lit(KingCooPalette.crumb)));
    c.drawPath(_rollTop, KingCooKit.fill(crust));
    c.drawPath(_roll, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkPart));
    c.drawPath(_rollScore, KingCooKit.line(KingCooPalette.crustDeep, KingCooLayout.inkDetail, .9));
    c.restore();
    c.save();
    c.translate(1.90, .37);
    c.rotate(.52);
    c.drawRRect(_heel, KingCooKit.fill(tone.lit(KingCooPalette.crumb)));
    c.drawPath(_heelTop, KingCooKit.fill(crust));
    c.drawRRect(_heel, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkPart));
    c.drawPath(_heelScore, KingCooKit.line(KingCooPalette.crustDeep, KingCooLayout.inkDetail, .9));
    c.restore();
    c.drawPath(_frill, _sackPaint);
    c.drawPath(_frill, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkPart));
    c.drawPath(_pleats, KingCooKit.line(KingCooPalette.burlapDeep, KingCooLayout.inkDetail, .8));
    c.drawPath(_sack, _sackPaint);
    KingCooKit.wash(c, _sack, tone, flush: false);
    c.save();
    c.clipPath(_sack, doAntiAlias: false);
    c.drawPath(_weave, KingCooKit.line(KingCooPalette.burlapDeep, KingCooLayout.hair, .40));
    c.drawPath(_stencil, KingCooKit.line(KingCooPalette.inkWarm, KingCooLayout.inkDetail, .72));
    KingCooKit.edgeIn(c, _sack, tone, width: .08, shift: .05, sky: .5, warm: .9);
    c.restore();
    c.drawPath(_sack, KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkMajor));
    c.drawPath(_tie, KingCooKit.line(KingCooPalette.ink, .115));
    c.drawPath(_tie, KingCooKit.line(tone.lit(KingCooPalette.rope), .06));
    // The knot: a fat dot of ink with the rope's colour on it.
    c.drawCircle(const Offset(1.74, .785), .075, KingCooKit.fill(KingCooPalette.ink));
    c.drawCircle(const Offset(1.74, .785), .045, KingCooKit.fill(tone.lit(KingCooPalette.rope)));
    c.drawPath(_crumbs, KingCooKit.fill(tone.lit(KingCooPalette.crumb)));
    c.restore();
  }

  // --------------------------------------------------------------- chest --

  /// Rows of feather scallops on the globe (unit chest): smile-shaped like
  /// latitude lines on a ball, the pitch foreshortening toward the rim, every
  /// row inside .93 of the radius so none needs a clip.
  static final Path chestRows = () {
    final path = Path();
    for (var row = 0; row < 6; row++) {
      final y = -.70 + row * .28;
      final half = math.sqrt(math.max(0, .93 * .93 - y * y));
      if (half < .3) continue;
      final n = (2 * half / (.34 - .10 * y.abs())).round().clamp(2, 7);
      final pitch = 2 * half / n;
      final shift = row.isOdd ? pitch / 2 : 0.0;
      for (var i = 0; i < n; i++) {
        final x0 = -half + shift + i * pitch, x1 = x0 + pitch;
        if (x1 > half + 1e-6) continue;
        double bow(double x) => y + .13 * x * x;
        final ya = bow(x0), yb = bow(x1);
        path
          ..moveTo(x0, ya)
          ..quadraticBezierTo((x0 + x1) / 2, (ya + yb) / 2 + pitch * .55, x1, yb);
      }
    }
    return path;
  }();

  /// The rim of the globe as a pill: the moon's hard glint.
  static final Path _shield = () {
    const s = KingCooLayout.badgeSize;
    return Path()
      ..moveTo(-s, -s * .9)
      ..quadraticBezierTo(0, -s * 1.15, s, -s * .9)
      ..lineTo(s * .95, s * .2)
      ..quadraticBezierTo(s * .6, s * 1.0, 0, s * 1.25)
      ..quadraticBezierTo(-s * .6, s * 1.0, -s * .95, s * .2)
      ..close();
  }();
  static final Path _shieldInner = () {
    const s = KingCooLayout.badgeSize * .72;
    return Path()
      ..moveTo(-s, -s * .9)
      ..quadraticBezierTo(0, -s * 1.15, s, -s * .9)
      ..lineTo(s * .95, s * .2)
      ..quadraticBezierTo(s * .6, s * 1.0, 0, s * 1.25)
      ..quadraticBezierTo(-s * .6, s * 1.0, -s * .95, s * .2)
      ..close();
  }();
  static final Path _star = () {
    const s = KingCooLayout.badgeSize;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? s * .50 : s * .21;
      final p = Offset(math.cos(a), math.sin(a)) * r + const Offset(0, s * .12);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();

  /// The chest's skin, in the figure frame: the breast's gradient on the
  /// (scalloped) path of radius [rPath], the feather rows (they fade as the
  /// globe goes taut), the terminator shade, the moon's rim on the upper right
  /// and the windows' warm bounce on the lower left, the fury's hot pink, and
  /// the taut chest's gold ring. No outline: the caller inks it. The badge is
  /// [badge].
  static void chestSkin(Canvas c, KingCooBodyPose b, double rPath, {bool rim = true}) {
    final tone = b.tone;
    final taut = b.taut;
    final r = rPath;
    final step = (taut * 16).round() / 16;
    final depth =
        KingCooLayout.chestFluffDepth +
        (KingCooLayout.chestTautDepth - KingCooLayout.chestFluffDepth) * step;
    final unit = KingCooKit.scallop(KingCooLayout.chestBumps, depth, turn: -.2);
    c.save();
    c.scale(r);
    c.drawPath(unit, _breastPaint);
    if (tone.furyBreastAlpha > 0) {
      c.drawPath(unit, KingCooKit.fill(KingCooPalette.furyBreast, tone.furyBreastAlpha));
    }
    if (tone.washAlpha > 0) {
      c.drawPath(unit, KingCooKit.fill(KingCooPalette.bleach, tone.washAlpha));
    }
    // Taut and puffed it is the brightest thing on him: a warmer cream over
    // the breast and a warm glow in its heart (inside the circle: the edge is
    // still exactly the hit circle).
    final bright = taut * taut * taut * (1 - tone.washAlpha) * (.35 + .65 * b.damage);
    if (bright > .02) {
      KingCooKit.glow(
        c,
        Offset.zero,
        .97,
        KingCooPalette.rimWarm,
        (.30 + .20 * b.damage) * bright,
      );
    }
    // The feather rows: bold and scalloped when fluffed, a whisper when taut.
    c.drawPath(
      chestRows,
      KingCooKit.line(
        KingCooPalette.breastDeep,
        KingCooLayout.inkDetail / r,
        (.72 - .52 * taut).clamp(0.0, .72),
      ),
    );
    // The moon's rim on the upper right (a crisp arc inside the edge), the
    // windows' bounce on the lower left (only when the globe is alone: in the
    // hide the union's own warm rim is that edge).
    final moon = (tone.skyRim * (.55 + .4 * taut)).clamp(0.0, 1.0);
    if (moon > .02) {
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: .90),
        -1.22,
        .95,
        false,
        KingCooKit.line(tone.lit(KingCooPalette.rimMoon), .06 / r, moon * .9),
      );
    }
    final bounce = rim ? tone.warmRim : 0.0;
    if (bounce > .02) {
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: .90),
        1.85,
        .95,
        false,
        KingCooKit.line(KingCooPalette.rimWarm, .06 / r, bounce * .8),
      );
    }
    // A taut chest wears a bold gold ring on an ink edge, just inside the hit
    // circle (the target), and, while his rocks count double, a second ring
    // that beats at 1.6 Hz inside it: the honest "shoot here, x2".
    final ring = ((taut - .72) / .28).clamp(0.0, 1.0);
    if (ring > 0) {
      final keep = ring * (1 - tone.washAlpha);
      final emph = b.damage;
      // Outside the double-damage window (the arrival's rear, the defeat's
      // swell) the puffed chest keeps a thin gold ring; inside it the ring is
      // bold, in a deeper amber that holds against the cream.
      c.drawCircle(
        Offset.zero,
        .80 + .06 * emph,
        KingCooKit.line(
          Color.lerp(tone.lit(KingCooPalette.gold), _ringAmber, emph)!,
          (.03 + .04 * emph) / r,
          (.55 + .3 * emph + .15 * emph * b.beat) * keep,
        ),
      );
      if (b.damage > .02) {
        c.drawCircle(
          Offset.zero,
          .64,
          KingCooKit.line(
            tone.lit(KingCooPalette.gold),
            .034 / r,
            (.28 + .5 * b.beat) * b.damage * keep,
          ),
        );
      }
    }
    // A soft gloss crescent on the upper left of the globe: the ball is glossy.
    final gloss = (.22 + .28 * taut) * (1 - tone.washAlpha);
    if (gloss > .02) {
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: .82),
        -2.95,
        .75,
        false,
        KingCooKit.line(KingCooPalette.white, .11 / r, gloss),
      );
    }
    // The hard white glint on the globe's shoulder.
    final glint = (.9 * (1 - tone.washAlpha * 1.6)).clamp(0.0, .9);
    if (glint > .02) {
      c.drawPath(_chestGlint, KingCooKit.line(KingCooPalette.white, .058 / r, glint));
    }
    c.restore();
  }

  static const _ringAmber = Color(0xffe09a22);

  // ------------------------------------------------------ ruffle and mark --

  /// Feathers standing up round the chest as it swells, drawn OUTSIDE the
  /// hide's clip: ticks of down along the globe's lower left, longest halfway
  /// through the swell and gone when it is taut or fluffed (so the taut chest
  /// is exactly the hit circle again), fluttering a little (motion). One path,
  /// two ops.
  static void chestRuffle(Canvas c, KingCooBodyPose b) {
    final t = b.taut;
    if (t <= .03 || t >= .97 || b.puff > 1.02) return;
    final grow = math.pow(math.sin(math.pi * t), .8).toDouble();
    final base = b.chestRadius;
    final path = _ruffle..reset();
    for (var i = 0; i < _ruffleN; i++) {
      final a = (112 + i * (126 / (_ruffleN - 1))) * math.pi / 180;
      final seed = KingCooKit.hash(i, 71);
      final flutter = b.time == 0 ? 0.0 : .035 * math.sin(b.time * 15 + i * 1.7);
      final len = (.17 * (.7 + .3 * seed) + flutter) * grow;
      final lean = (seed - .5) * .5;
      final p0 = Offset(math.cos(a), math.sin(a)) * (base - .02);
      final dir = a + lean;
      final tip = p0 + Offset(math.cos(dir), math.sin(dir)) * len;
      final side = Offset(-math.sin(a), math.cos(a)) * .05;
      path
        ..moveTo(p0.dx - side.dx, p0.dy - side.dy)
        ..quadraticBezierTo(
          (p0.dx + tip.dx) / 2 - side.dx * .2,
          (p0.dy + tip.dy) / 2 - side.dy * .2,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (p0.dx + tip.dx) / 2 + side.dx * 1.2,
          (p0.dy + tip.dy) / 2 + side.dy * 1.2,
          p0.dx + side.dx,
          p0.dy + side.dy,
        )
        ..close();
    }
    final alpha = (1 - b.tone.washAlpha * .4);
    c.drawPath(path, KingCooKit.line(KingCooPalette.inkWarm, .055, alpha));
    c.drawPath(path, KingCooKit.fill(KingCooPalette.breastHi, alpha));
  }

  static const _ruffleN = 9;
  static final Path _ruffle = Path();

  /// The "x2" roundel pinned to the globe's lower left (toward the bird) while
  /// his rocks count double: it pops in with the window, beats at 1.6 Hz and
  /// pops out with it. A navy medal with a brass rim and a gold "x2", ink
  /// edged, readable at 41 px a unit (30 px across) and as a gold dot at 120
  /// px. Painted in the figure frame after the badge.
  static void doubleMark(Canvas c, KingCooBodyPose b) {
    final d = b.damage;
    if (d <= .02) return;
    // Overshoot in, a steady 4% beat.
    final u = d - 1;
    final pop = (1 + u * u * (2.4 * u + 1.4)).clamp(0.0, 1.25);
    final scale = pop * (1 + .04 * (b.beat - .5) * 2);
    c.save();
    c.translate(_markAt.dx, _markAt.dy);
    c.scale(.43 * scale);
    c.drawCircle(Offset.zero, 1.14, KingCooKit.fill(KingCooPalette.ink));
    c.drawCircle(Offset.zero, .92, KingCooKit.fill(KingCooPalette.navy));
    c.drawCircle(Offset.zero, .93, KingCooKit.line(KingCooPalette.brass, .15));
    c.drawPath(
      _mark,
      KingCooKit.line(
        Color.lerp(KingCooPalette.gold, KingCooPalette.brassLit, b.beat * .6)!,
        .22,
      ),
    );
    c.restore();
  }

  /// Where the roundel sits: on the globe's edge, lower left.
  static const _markAt = Offset(-.76, .66);

  /// "x2" in strokes, in a box about 1.3 wide and .8 tall.
  static final Path _mark = Path()
    // x
    ..moveTo(-.62, -.16)
    ..lineTo(-.22, .24)
    ..moveTo(-.22, -.16)
    ..lineTo(-.62, .24)
    // 2
    ..moveTo(.06, -.2)
    ..cubicTo(.06, -.5, .6, -.5, .6, -.18)
    ..cubicTo(.6, .02, .3, .12, .04, .42)
    ..lineTo(.64, .42);

  /// A pill and a dot on the globe's moonlit shoulder (unit chest).
  static final Path _chestGlint = Path()
    ..moveTo(math.cos(-2.02) * .72, math.sin(-2.02) * .72)
    ..lineTo(math.cos(-1.78) * .74, math.sin(-1.78) * .74)
    ..moveTo(math.cos(-1.56) * .74, math.sin(-1.56) * .74)
    ..lineTo(math.cos(-1.56) * .74 + .001, math.sin(-1.56) * .74);

  /// The brass shield on the chest: the aim point. It brightens and grows with
  /// the swell and glows when taut.
  static void badge(Canvas c, KingCooBodyPose b) {
    final tone = b.tone;
    final glow = b.taut;
    final at = KingCooLayout.badge;
    // While his rocks count double the glow beats at 1.6 Hz (alpha .5-.9).
    final pulse = b.damage > 0 ? .5 + .4 * b.beat : .62;
    KingCooKit.glow(
      c,
      at,
      .55 + .12 * tone.heat,
      KingCooPalette.brassLit,
      pulse * glow,
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(1 + .185 * glow);
    c.drawPath(_shield, _shieldPaint);
    KingCooKit.wash(c, _shield, tone, plumage: false, flush: false);
    c.drawPath(_shield, KingCooKit.line(KingCooPalette.inkWarm, KingCooLayout.inkPart));
    c.drawPath(
      _shieldInner,
      KingCooKit.line(tone.lit(KingCooPalette.brassLit), KingCooLayout.inkDetail * .8, .8),
    );
    c.drawPath(_star, KingCooKit.fill(KingCooPalette.navy));
    c.drawLine(
      const Offset(-KingCooLayout.badgeSize * .68, -KingCooLayout.badgeSize * .62),
      const Offset(-KingCooLayout.badgeSize * .30, -KingCooLayout.badgeSize * .80),
      KingCooKit.line(KingCooPalette.white, .05, .9 * (1 - tone.washAlpha)),
    );
    c.restore();
  }

  /// The chest painted alone: the globe with its own outline (its centre line
  /// is exactly the hit circle), its skin and the badge.
  static void chest(Canvas c, KingCooBodyPose b) {
    b = b.finite;
    final r = b.chestRadius;
    chestSkin(c, b, r);
    c.drawPath(chestPath(r, b.taut), KingCooKit.line(KingCooPalette.ink, KingCooLayout.inkHero));
    badge(c, b);
  }
}
