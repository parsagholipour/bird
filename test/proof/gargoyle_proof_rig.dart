// A placeholder Searchlight Gargoyle built from nothing but GargoyleLayout
// numbers and GargoylePose channels, as FLAT silhouettes (fill + ink stroke in
// one colour, so the extents include the ink).
//
// It is NOT the art. It exists to prove, with the real pose channels, that the
// layout fits the envelope in every state and animation phase and that the
// silhouette reads at 250 and 120 px, independent of whatever the part
// builders put in lib/game/gargoyle_*_art.dart. Builders read it to see how the
// layout numbers combine; they never copy its shapes.
import 'dart:ui';

import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

Paint _flat(Color c) => Paint()..color = c;
Paint _edge(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

void _shape(Canvas c, Path p, Color col, double w) {
  c.drawPath(p, _flat(col));
  c.drawPath(p, _edge(col, w));
}

/// Paints the proof silhouette of [pose] in [col] (the creature only unless
/// [plinth]; the ledge is staging and is painted in a lighter grey).
void paintProofGargoyle(
  Canvas c,
  GargoylePose pose, {
  Color col = const Color(0xff000000),
  bool plinth = false,
}) {
  if (pose.crumble >= 1) return;
  if (plinth) {
    final ledge = Path()
      ..addRect(const Rect.fromLTRB(-2.25, GargoyleLayout.ledgeY, 4.7, 3.32))
      ..addRect(const Rect.fromLTRB(-1.75, 3.32, 4.7, 3.75))
      ..addRect(const Rect.fromLTRB(-1.05, 3.75, 4.7, 4.2))
      ..addRect(const Rect.fromLTRB(3.55, -4.6, 4.7, 4.6));
    c.drawPath(ledge, _flat(const Color(0xff9a9a9a)));
  }
  c.save();
  c.rotate(GargoyleLayout.bodyTurn(pose.lean));

  // Fans (far first), each blade its own polygon.
  for (final (fan, far) in [(pose.farFan, true), (pose.nearFan, false)]) {
    final root = GargoyleLayout.fanRoot(far: far);
    for (var i = GargoyleLayout.fanBlades - 1; i >= 0; i--) {
      if (!far && i == GargoyleLayout.shedBlade && fan.shed >= .999) continue;
      final tip = fan.tip(i, far: far);
      _shape(c, GargoyleKit.poly(GargoyleLayout.bladeOutline(root, tip)), col, GargoyleLayout.inkMajor);
    }
    final hub = GargoyleKit.poly(GargoyleLayout.hubOutline).shift(root);
    _shape(c, hub, col, GargoyleLayout.inkMajor);
  }
  c.restore();
  // Tail fan and legs stay on the ledge.
  for (var i = 0; i < GargoyleLayout.tailBlades; i++) {
    final tip = GargoyleLayout.tailTip(i, swing: pose.tail);
    _shape(c, GargoyleKit.poly(GargoyleLayout.bladeOutline(GargoyleLayout.tailRoot, tip)), col, GargoyleLayout.inkMajor);
  }
  _shape(c, GargoyleKit.spline(GargoyleLayout.farLegOutline), col, GargoyleLayout.inkMajor);
  _shape(c, GargoyleKit.spline(GargoyleLayout.thighOutline), col, GargoyleLayout.inkMajor);
  final talons = Path();
  for (final heel in GargoyleLayout.talonHeels) {
    talons
      ..moveTo(heel, GargoyleLayout.ledgeY - .22)
      ..lineTo(heel - .55, GargoyleLayout.ledgeY - .18)
      ..lineTo(heel - .80, GargoyleLayout.ledgeY + .06)
      ..lineTo(heel - .55, GargoyleLayout.ledgeY + .20)
      ..lineTo(heel - .25, GargoyleLayout.ledgeY + .04)
      ..close();
  }
  _shape(c, talons, col, GargoyleLayout.inkPart);
  // The upper body again: torso, ruff, the lamp's housing.
  c.save();
  c.rotate(GargoyleLayout.bodyTurn(pose.lean));
  _shape(c, GargoyleKit.poly(GargoyleLayout.torsoOutline), col, GargoyleLayout.inkHero);
  _shape(c, GargoyleKit.poly(GargoyleLayout.ruffOutline), col, GargoyleLayout.inkMajor);
  _shape(c, GargoyleKit.octagon(GargoyleLayout.housingRadius), col, GargoyleLayout.inkHero);

  // Head, in its own frame.
  c.save();
  c.translate(pose.head.dx, pose.head.dy);
  c.translate(GargoyleLayout.headPivot.dx, GargoyleLayout.headPivot.dy);
  c.rotate(-pose.pitch);
  c.translate(-GargoyleLayout.headPivot.dx, -GargoyleLayout.headPivot.dy);
  c.translate(GargoyleLayout.headShift.dx, GargoyleLayout.headShift.dy);
  c.translate(GargoyleLayout.headPivot.dx, GargoyleLayout.headPivot.dy);
  c.scale(GargoyleLayout.headScale);
  c.translate(-GargoyleLayout.headPivot.dx, -GargoyleLayout.headPivot.dy);
  final crest = Path();
  for (var i = 0; i < GargoyleLayout.crestRoots.length; i++) {
    final r = GargoyleLayout.crestRoots[i], tip = GargoyleLayout.crestTips[i];
    crest
      ..moveTo(r - GargoyleLayout.crestHalfRoot, -2.85)
      ..lineTo(r + GargoyleLayout.crestHalfRoot, -2.98)
      ..lineTo(tip.dx, tip.dy)
      ..close();
  }
  _shape(c, crest, col, GargoyleLayout.inkPart);
  _shape(c, GargoyleKit.spline(GargoyleLayout.skullOutline), col, GargoyleLayout.inkHero);
  c.save();
  c.translate(GargoyleLayout.jawHinge.dx, GargoyleLayout.jawHinge.dy);
  c.rotate(-pose.gape * .5);
  c.translate(-GargoyleLayout.jawHinge.dx, -GargoyleLayout.jawHinge.dy);
  _shape(c, GargoyleKit.poly(GargoyleLayout.jawOutline), col, GargoyleLayout.inkPart);
  c.restore();
  _shape(c, GargoyleKit.spline(GargoyleLayout.beakOutline, sharp: const {0, 7, 12}), col, GargoyleLayout.inkPart);
  if (pose.visor > .5) {
    final drop = GargoyleLayout.visorDrop(pose.brow);
    c.save();
    c.translate(0, drop);
    _shape(c, GargoyleKit.poly(GargoyleLayout.visorNearOutline), col, GargoyleLayout.inkPart);
    c.restore();
    c.save();
    c.translate(0, drop * .7);
    _shape(c, GargoyleKit.poly(GargoyleLayout.visorFarOutline), col, GargoyleLayout.inkPart);
    c.restore();
  }
  c.restore();
  c.restore();
}
