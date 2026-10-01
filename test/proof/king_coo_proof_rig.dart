// A placeholder King Coo built from nothing but KingCooLayout numbers and
// KingCooPose channels, in flat silhouette.
//
// It is NOT the art. It exists to prove, with the real pose channels, that the
// layout fits the envelope in every state and that the silhouette reads: it
// never changes when the part painters are replaced, so it guards the layout
// numbers and the pose maths on its own. Builders read it to see how the
// layout numbers combine; they never copy its shapes.
import 'dart:math' as math;
import 'dart:ui';

import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

final _body = KingCooKit.spline(KingCooLayout.bodyOutline);
final _sack = KingCooKit.spline(KingCooLayout.sackOutline);
final _skull = KingCooKit.spline(KingCooLayout.skullOutline);
final _wing = Path()
  ..moveTo(-.06, -.28)
  ..cubicTo(.40, -.58, 1.10, -.52, 1.90, -.04)
  ..lineTo(1.54, .24)
  ..lineTo(.80, .34)
  ..lineTo(-.10, .10)
  ..close();

void paintProofCoo(Canvas c, KingCooPose pose, {Color ink = const Color(0xff000000)}) {
  final fill = Paint()..color = ink;
  Paint line(double w) => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;
  c.save();
  c.translate(pose.bob.dx, pose.bob.dy);
  c.rotate(pose.roll + pose.pitch);
  c.scale(pose.scaleX, pose.scaleY);

  void wing(Offset shoulder, double angle, double stretch) {
    final sx = KingCooLayout.wingScale * stretch;
    final sy = KingCooLayout.wingScale * (stretch > 1 ? 1 + (stretch - 1) * .3 : 1);
    c.save();
    c.translate(shoulder.dx, shoulder.dy);
    c.rotate(angle);
    c.scale(sx, sy);
    c.drawPath(_wing, fill);
    c.restore();
  }

  wing(KingCooLayout.farShoulder, pose.wingFar, 1);
  // legs
  for (final (hip, phase) in [
    (KingCooLayout.farHip, pose.pedal + math.pi),
    (KingCooLayout.nearHip, pose.pedal),
  ]) {
    final sw = math.sin(phase);
    final foot = Offset(
      hip.dx - .18 + sw * KingCooLayout.footReach,
      KingCooLayout.footY - sw.abs() * KingCooLayout.footLift - pose.stomp * .30,
    );
    c.drawLine(hip, foot, line(.2));
    c.drawLine(foot, foot + const Offset(-.3, .05), line(.12));
  }
  // tail
  c.save();
  c.translate(KingCooLayout.tailRoot.dx, KingCooLayout.tailRoot.dy);
  c.rotate(pose.tailWag);
  final spread = .03 + .14 * pose.tailFan;
  for (var i = 0; i < 4; i++) {
    c.save();
    c.rotate(.02 + (i - 1.5) * spread + .10);
    c.drawLine(Offset.zero, Offset(KingCooLayout.tailLengths[i], 0), line(KingCooLayout.tailWidth * .8));
    c.restore();
  }
  c.restore();
  c.drawPath(_body, fill);
  c.save();
  c.translate(KingCooLayout.sackMouth.dx, KingCooLayout.sackMouth.dy);
  c.rotate(pose.sackSwing);
  c.translate(-KingCooLayout.sackMouth.dx, -KingCooLayout.sackMouth.dy);
  c.drawPath(_sack, fill);
  c.restore();
  c.drawCircle(Offset.zero, pose.chestRadius, fill);
  // head: a ruff, the skull, the beak, the cap with its siren, the whistle
  c.save();
  c.translate(pose.headCentre.dx, pose.headCentre.dy);
  c.rotate(pose.headTilt);
  c.drawCircle(Offset.zero, KingCooLayout.headRuffRadius + .1, fill);
  c.drawPath(_skull, fill);
  c.drawPath(
    Path()
      ..moveTo(-.4, -.12)
      ..lineTo(KingCooLayout.headBeakTip.dx, KingCooLayout.headBeakTip.dy)
      ..lineTo(-.4, .26)
      ..close(),
    fill,
  );
  c.restore();
  if (!pose.capOff) {
    c.save();
    c.translate(pose.headCentre.dx + pose.capLift.dx, pose.headCentre.dy + pose.capLift.dy);
    c.rotate(pose.headTilt);
    c.translate(KingCooLayout.headCapSeat.dx, KingCooLayout.headCapSeat.dy);
    c.rotate(pose.capTilt + pose.capSpin);
    c.translate(-KingCooLayout.headCapSeat.dx, -KingCooLayout.headCapSeat.dy);
    c.drawRRect(
      RRect.fromLTRBR(-.7, -.88, .7, -.30, const Radius.circular(.15)),
      fill,
    );
    c.drawRect(const Rect.fromLTRB(-.82, -.30, -.4, -.12), fill);
    c.drawCircle(const Offset(0, -.88), .11, fill);
    c.restore();
  }
  c.drawCircle(pose.whistleAt + const Offset(.05, 0), .25, fill);
  wing(KingCooLayout.nearShoulder, pose.wingNear, pose.wingStretch);
  if (pose.bombHeld > 0) {
    c.drawCircle(pose.handAt, KingCooLayout.bombRadius, fill);
  }
  c.restore();
}
