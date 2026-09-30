// A placeholder Ember Dragon built from nothing but DragonLayout numbers and
// DragonPose channels.
//
// It is NOT the art. It exists to prove, with real pose channels, that the
// layout fits the envelope in every state and wing phase and that the
// silhouette reads at 250 and 120 px. Builders read it to see how the layout
// numbers combine; they never copy its shapes.
import 'dart:math' as math;
import 'dart:ui';

import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

Offset _o(double x, double y) => Offset(x, y);

// The head in its own frame (rig units, scale 1.0): the head critic's
// redesign, reduced to outlines.
final _skull = DragonKit.spline(
  const [
    Offset(.70, .20), Offset(.76, -.20), Offset(.58, -.66), Offset(.20, -.90),
    Offset(-.20, -.88), Offset(-.52, -.76), Offset(-.80, -.54),
    Offset(-.98, -.40), Offset(-1.20, -.44), Offset(-1.44, -.34),
    Offset(-1.58, -.14), Offset(-1.56, .08), Offset(-1.42, .16),
    Offset(-.90, .19), Offset(-.40, .22), Offset(.10, .28), Offset(.44, .44),
    Offset(.66, .42),
  ],
  sharp: {0, 12, 15},
);
final _jaw = DragonKit.spline(
  const [
    Offset(.34, .26), Offset(-.40, .23), Offset(-1.40, .17), Offset(-1.54, .26),
    Offset(-1.48, .52), Offset(-1.08, .74), Offset(-.58, .84),
    Offset(-.08, .80), Offset(.34, .68), Offset(.52, .46),
  ],
  sharp: {0, 2},
);
final _horn = DragonKit.tube(
  const [Offset(.36, -.68), Offset(.72, -.96), Offset(1.08, -1.06), Offset(1.38, -1.02), Offset(1.56, -.90)],
  const [.40, .32, .22, .12, .02],
);
final _cheek = DragonKit.tube(
  const [Offset(.52, .30), Offset(.86, .40), Offset(1.06, .62)],
  const [.26, .13, .02],
);
final _crown = () {
  final p = Path()
    ..moveTo(-.52, .16)
    ..quadraticBezierTo(0, -.06, .52, .14)
    ..lineTo(.50, -.06);
  const tips = [(.44, -.20), (.25, -.34), (.03, -.44), (-.19, -.34), (-.43, -.20)];
  const valleys = [(.36, -.08), (.14, -.10), (-.08, -.12), (-.30, -.10)];
  for (var i = 0; i < 5; i++) {
    p.lineTo(tips[i].$1, tips[i].$2);
    if (i < 4) p.lineTo(valleys[i].$1, valleys[i].$2);
  }
  return p
    ..lineTo(-.50, -.04)
    ..close();
}();
final _frill = () {
  final p = Path();
  const root = Offset(.58, .02);
  final tips = [
    for (final (a, l) in const [(-.80, .62), (-.28, .86), (.30, .74), (.78, .56)])
      root + DragonKit.heading(a) * l,
  ];
  p
    ..moveTo(root.dx, root.dy)
    ..lineTo(tips[0].dx, tips[0].dy);
  for (var i = 1; i < tips.length; i++) {
    final ctl = Offset.lerp(Offset.lerp(tips[i - 1], tips[i], .5)!, root, .2)!;
    p.quadraticBezierTo(ctl.dx, ctl.dy, tips[i].dx, tips[i].dy);
  }
  return p..close();
}();
final _torso = DragonKit.spline(DragonLayout.torsoOutline);
const _hindWidths = <double>[1.10, .58, .34, .26];
const _foreWidths = <double>[.85, .52, .34, .26];

/// Paints the placeholder dragon for [pose] (rig units, heart at the origin).
/// [flat] colours the parts; otherwise everything is one silhouette [ink].
void paintProofDragon(
  Canvas c,
  DragonPose pose, {
  bool flat = false,
  Color ink = const Color(0xff000000),
}) {
  Paint fill(Color col) => Paint()..color = flat ? col : ink;
  void shape(Path path, Color col, {double w = .07}) {
    c.drawPath(path, fill(col));
    if (flat) {
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xff101010)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  c.save();
  c.translate(pose.bob.dx, pose.bob.dy);
  c.rotate(pose.pitch);
  _wing(c, pose, far: true, flat: flat, ink: ink, shape: shape);
  _leg(c, pose, hind: true, far: true, shape: shape);
  _leg(c, pose, hind: false, far: true, shape: shape);
  _tail(c, pose, shape);
  c.save();
  c.scale(1 + pose.chest * .6, 1 + pose.chest);
  shape(_torso, const Color(0xff6a4a80));
  c.restore();
  _leg(c, pose, hind: true, far: false, shape: shape);
  _neck(c, pose, shape);
  _wing(c, pose, far: false, flat: flat, ink: ink, shape: shape);
  _head(c, pose, shape);
  _leg(c, pose, hind: false, far: false, shape: shape);
  c.restore();
}

void _neck(Canvas c, DragonPose p, void Function(Path, Color, {double w}) shape) {
  final joint = p.headPoint(DragonLayout.headNeckJoint);
  final spine = DragonLayout.neckSpine(
    joint,
    p.head.angle,
    drag: p.neckDrag,
    coil: p.neckCoil,
  );
  shape(DragonKit.tube(spine, DragonLayout.neckWidths), const Color(0xff7a5a90));
}

void _head(Canvas c, DragonPose p, void Function(Path, Color, {double w}) shape) {
  c.save();
  c.translate(p.head.at.dx, p.head.at.dy);
  c.rotate(-p.head.angle);
  shape(_horn, const Color(0xffd8c090));
  shape(_frill, const Color(0xffc04050));
  c.save();
  final hinge = DragonLayout.headJawHinge;
  c.translate(hinge.dx, hinge.dy);
  c.rotate(-p.gape * .68);
  c.translate(-hinge.dx, -hinge.dy);
  shape(_jaw, const Color(0xff5a4070));
  c.restore();
  shape(_skull, const Color(0xff7a5a90));
  shape(_cheek, const Color(0xff4a3060));
  c.save();
  c.translate(DragonLayout.headCrownSeat.dx, DragonLayout.headCrownSeat.dy);
  c.rotate(DragonLayout.headCrownTurn);
  shape(_crown, const Color(0xfff0c050), w: .05);
  c.restore();
  c.restore();
}

void _tail(Canvas c, DragonPose p, void Function(Path, Color, {double w}) shape) {
  const base = DragonLayout.tailSpine;
  final n = base.length;
  final spine = <Offset>[];
  for (var i = 0; i < n; i++) {
    spine.add(base[i] + _o(0, p.tailBend(i / (n - 1))));
  }
  shape(DragonKit.tube(spine, DragonLayout.tailWidths), const Color(0xff5a4070));
  final tip = spine.last;
  final d = DragonKit.unit(spine.last - spine[n - 2]);
  final nn = _o(-d.dy, d.dx);
  const len = DragonLayout.tailBladeLength, hw = DragonLayout.tailBladeHalfWidth;
  final blade = Path()
    ..moveTo(tip.dx + nn.dx * .18, tip.dy + nn.dy * .18)
    ..quadraticBezierTo(tip.dx + nn.dx * hw + d.dx * .3, tip.dy + nn.dy * hw + d.dy * .3, tip.dx + d.dx * len, tip.dy + d.dy * len)
    ..quadraticBezierTo(tip.dx - nn.dx * hw + d.dx * .3, tip.dy - nn.dy * hw + d.dy * .3, tip.dx - nn.dx * .18, tip.dy - nn.dy * .18)
    ..close();
  shape(blade, const Color(0xffc04050));
}

void _leg(
  Canvas c,
  DragonPose p, {
  required bool hind,
  required bool far,
  required void Function(Path, Color, {double w}) shape,
}) {
  final shift = far ? DragonLayout.farLegShift : Offset.zero;
  final limb = [
    for (final q in hind ? DragonLayout.hindLeg : DragonLayout.foreLeg) q + shift,
  ];
  if (hind) limb[2] += _o(.25 * p.legKick, -.08 * p.legKick.abs());
  final foot = limb.last + (hind ? DragonLayout.hindFoot : DragonLayout.foreFoot);
  // (The placeholder's own limb widths; the real art owns its own.)
  final w = hind ? _hindWidths : _foreWidths;
  shape(DragonKit.tube([...limb, foot], w), const Color(0xff4a3568));
  for (var i = 0; i < 3; i++) {
    final a = (hind ? .5 : 2.6) + (i - 1) * .4;
    final tip = foot + DragonKit.heading(a) * .34;
    final nn = _o(-math.sin(a), math.cos(a));
    shape(
      Path()
        ..moveTo(foot.dx + nn.dx * .07, foot.dy + nn.dy * .07)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(foot.dx - nn.dx * .07, foot.dy - nn.dy * .07)
        ..close(),
      const Color(0xffe8d8b0),
      w: .03,
    );
  }
}

void _wing(
  Canvas c,
  DragonPose p, {
  required bool far,
  required bool flat,
  required Color ink,
  required void Function(Path, Color, {double w}) shape,
}) {
  final m = far ? p.farWing : p.nearWing;
  var k = DragonLayout.wingAt(
    elbow: m.elbow,
    wrist: m.wrist,
    tips: m.tips,
    fold: m.fold,
  );
  // Flex turns each tip up about the wrist; spread fans the trailing fingers
  // down and back.
  final tips = <Offset>[];
  for (var i = 0; i < 4; i++) {
    var v = k.tips[i] - k.wrist;
    v = DragonKit.turn(v, -m.flex[i] + m.spread * .12 * i / 3);
    tips.add(k.wrist + v);
  }
  k = DragonWingKey(k.elbow, k.wrist, tips);
  var sh = DragonLayout.nearShoulder, rt = DragonLayout.nearRoot;
  if (far) {
    k = DragonLayout.farOf(k);
    sh = DragonLayout.farShoulder;
    rt = DragonLayout.farRoot;
  }
  final w = k.wrist;
  Offset hem(Offset a, Offset b, Offset toward, double depth) =>
      Offset.lerp(Offset.lerp(a, b, .5)!, toward, depth)!;
  final mem = Path()
    ..moveTo(sh.dx, sh.dy)
    ..lineTo(k.elbow.dx, k.elbow.dy)
    ..lineTo(w.dx, w.dy)
    ..lineTo(k.tips[0].dx, k.tips[0].dy);
  for (var i = 1; i < 4; i++) {
    final h = hem(k.tips[i - 1], k.tips[i], w, .5 + .1 * m.sag);
    mem.quadraticBezierTo(h.dx, h.dy, k.tips[i].dx, k.tips[i].dy);
  }
  final last = hem(k.tips.last, rt, k.elbow, .2);
  mem
    ..quadraticBezierTo(last.dx, last.dy, rt.dx, rt.dy)
    ..close();
  shape(mem, far ? const Color(0xff902838) : const Color(0xffe04050));
  final bone = Paint()
    ..color = flat ? const Color(0xff3a2a55) : ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .12
    ..strokeCap = StrokeCap.butt;
  for (final t in k.tips) {
    c.drawLine(w, t, bone);
    // The claw allowance beyond the bone tip.
    final d = DragonKit.unit(t - w);
    c.drawLine(t, t + d * DragonLayout.clawAllowance, bone..strokeWidth = .09);
    bone.strokeWidth = .12;
  }
  c.drawPath(
    Path()
      ..moveTo(sh.dx, sh.dy)
      ..lineTo(k.elbow.dx, k.elbow.dy)
      ..lineTo(w.dx, w.dy),
    Paint()
      ..color = bone.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}
