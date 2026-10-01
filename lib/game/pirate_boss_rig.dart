import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'pirate_captain_face_art.dart';
import 'pirate_captain_body_art.dart';
import 'pirate_hat_art.dart';
import 'pirate_parrot_art.dart';

/// The Pirate Captain: a barrel-chested buccaneer in a gold-trimmed crimson
/// coat and a plumed tricorn, with an eyepatch, a braided black beard, a
/// torch for his cannon's fuse, an iron hook, and a scarlet macaw riding his
/// shoulder.
///
/// Authored in hit-radius units around the hit circle, facing left toward
/// the bird. He stands on his ship's deck, so everything below [rail] is
/// hidden by the hull drawn in front of him.
abstract final class PirateBossRig {
  static const ink = Color(0xff2a1c28);
  static const crimson = Color(0xffc53b4d), gold = Color(0xffffcf5c);
  static const bone = Color(0xfffff4dd), sea = Color(0xff4fd1c5);
  static const flame = Color(0xffffa23a), flameCore = Color(0xfffff1b8);

  /// The visible eye, the far one beside the nose (the near one is
  /// patched); the silhouette reveal lights it alone.
  static const eyeCenter = Offset(-.57, -.48);

  /// Where the hat sits on the head, and what it covers.
  static const hatAnchor = Offset(-.16, -.82);
  static const hatBounds = PirateHatArt.bounds;

  /// The parrot's feet on the captain's far shoulder.
  static const parrotAnchor = Offset(.84, -.05);
  static const parrotBounds = Rect.fromLTRB(-1.1, -1.5, 1.3, .9);

  /// The deck rail in rig units: the hull hides everything below it.
  static const rail = SkyBoss.hullTop / SkyBoss.radius;

  /// Everything the rig can reach, poses and props included.
  static const bounds = Rect.fromLTRB(-2.1, -3.0, 2.1, 1.3);

  /// The captain in his current pose. [lookY] turns his eye toward the bird
  /// (-1 up, 1 down); [fuse] is the tip of the cannon's wick in rig units,
  /// where the torch dips while the charge builds.
  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    Offset fuse = const Offset(-.98, .66),
    bool parrot = true,
  }) {
    final p = _Pose(boss, m, lookY, fuse);
    final flash = m.defeated ? 0.0 : m.hit * (m.reducedMotion ? .3 : .5);
    if (flash > .01) {
      // A bounded layer blows the fills toward white while the ink holds,
      // so a struck captain never looks ghosted.
      c.saveLayer(bounds, Paint()..colorFilter = _flash(flash));
    }
    if (parrot) _parrotTail(c, p);
    _hookArm(c, p, back: true);
    _torso(c, p);
    _hookArm(c, p, back: false);
    _head(c, p);
    if (!m.defeated || m.death < .3) {
      c.save();
      c.translate(hatAnchor.dx, hatAnchor.dy - p.hatLift);
      c.rotate(p.hatTilt);
      hat(c, fury: p.fury > 0, sway: p.hatSway, glint: p.hatGlint);
      c.restore();
    }
    if (parrot) {
      c.save();
      c.translate(parrotAnchor.dx, parrotAnchor.dy + p.breath * .6);
      paintParrot(
        c,
        time: p.time,
        squawk: p.squawk,
        flap: p.flutter,
        ruffle: p.fury,
        dizzy: m.defeated,
        look: p.aim,
      );
      c.restore();
    }
    _hookClaw(c, p);
    _torchArm(c, p);
    if (flash > .01) c.restore();
  }

  static ColorFilter _flash(double w) {
    const k = 2.6, b = -60.0;
    final keep = 1 - w;
    return ColorFilter.matrix([
      keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b, //
      0, 0, 0, 1, 0,
    ]);
  }

  // ------------------------------------------------------------- torso --

  static void _torso(Canvas c, _Pose p) =>
      PirateCaptainBodyArt.torso(c, p.body);

  // -------------------------------------------------------------- head --

  /// The head and its whole face live in [PirateCaptainFaceArt]; this only moves
  /// and tilts the head frame and hands over the expression channels.
  static void _head(Canvas c, _Pose p) {
    c.save();
    c.translate(p.headShift.dx, p.headShift.dy);
    c.rotate(p.headTilt);
    PirateCaptainFaceArt.paint(
      c,
      PirateFaceState(
        time: p.time,
        aim: p.aim,
        charge: p.charge,
        recoil: p.shot,
        roar: p.roar,
        wince: p.wince,
        blink: p.blink,
        fury: p.fury,
        tide: p.tide,
        dizzy: p.dizzy,
        jiggle: p.jiggle,
        braid: p.braid,
        talk: p.talk,
        mood: p.mood,
      ),
    );
    c.restore();
  }

  // --------------------------------------------------------------- hat --

  /// The plumed tricorn, drawn around its seat on the head. It is also drawn
  /// on its own when it is knocked off in the defeat. [sway] swings the
  /// feathers about their pin and [glint] flashes the braid.
  static void hat(
    Canvas c, {
    bool fury = false,
    double sway = 0,
    double glint = 0,
    bool worn = true,
  }) => PirateHatArt.paint(
    c,
    fury: fury,
    sway: sway,
    glint: glint,
    worn: worn,
  );

  // -------------------------------------------------------------- arms --

  /// The torch arm, drawn last: its warm light first tints the captain
  /// beneath it, then the sleeve, fist, torch and flame go on top.
  static void _torchArm(Canvas c, _Pose p) {
    PirateCaptainBodyArt.torchLight(c, p.body);
    PirateCaptainBodyArt.torchArm(c, p.body);
  }

  static void _hookArm(Canvas c, _Pose p, {required bool back}) {
    // Raised high the far arm swings behind the body; otherwise it rests in
    // front at the hip.
    if (back != p.hookBehind) return;
    PirateCaptainBodyArt.hookSleeve(c, p.body);
  }

  /// The leather cup and the polished hook, over the hat and the parrot.
  static void _hookClaw(Canvas c, _Pose p) =>
      PirateCaptainBodyArt.hookClaw(c, p.body);

  // ------------------------------------------------------------ parrot --

  static void _parrotTail(Canvas c, _Pose p) {
    c.save();
    c.translate(parrotAnchor.dx, parrotAnchor.dy + p.breath * .6);
    PirateParrotArt.tail(
      c,
      time: p.time,
      squawk: p.squawk,
      ruffle: p.fury,
    );
    c.restore();
  }

  /// The captain's parrot, standing with its feet at the origin and facing
  /// left (drawn by [PirateParrotArt]). [flying] stretches it into the air,
  /// where [flap] is the wingbeat; perched, [flap] ruffles the wings out and
  /// [dizzy] is a wide-eyed shock.
  static void paintParrot(
    Canvas c, {
    double time = 0,
    double squawk = 0,
    double flap = 0,
    double ruffle = 0,
    double look = 0,
    bool dizzy = false,
    bool flying = false,
  }) => PirateParrotArt.paint(
    c,
    time: time,
    squawk: squawk,
    flap: flying ? 0 : flap,
    ruffle: ruffle,
    dizzy: dizzy,
    look: look,
    air: flying ? 1 : 0,
    stroke: flap,
  );
}

/// Everything the captain's pose derives from the boss clock.
class _Pose {
  _Pose(SkyBoss boss, BossMotion m, double lookY, Offset fuse)
    : time = m.reducedMotion || m.defeated ? 0.0 : boss.age,
      charge = m.defeated ? 0 : BossMotion.ease(boss.charge),
      recoil = m.reducedMotion ? 0 : m.recoil,
      wince = m.wince,
      roar = m.roar,
      dizzy = m.defeated,
      blink = m.blink,
      fury = boss.enraged && !m.defeated ? .8 + m.rage * .2 : 0,
      aim = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0,
      mood = m.mood {
    breath = math.sin(time * 2.4) * .02;
    final hit = m.reducedMotion ? 0.0 : m.hit;
    // The tide answers his hook: he raises it through the warning and holds
    // it while the sea surges.
    final call = _tideCall(boss) * (1 - roar);
    tide = call;
    shot = m.recoil;
    // A line's words, quiet while he bellows, fires or calls the tide.
    talk = m.voiced(
      0,
      rest: switch (mood) {
        StoryMood.surprised => .25,
        StoryMood.happy => .1,
        _ => 0,
      },
      range: mood == StoryMood.sad ? .55 : .8,
      busy: math.max(math.max(roar, m.recoil), math.max(charge, call)),
    );
    final furyShake = fury > 0 && time != 0 ? math.sin(time * 17) * .04 : 0.0;
    mouth = dizzy
        ? .35
        : math.max(
            roar,
            math.max(recoil * .9, math.max(charge * .3, call * .5)),
          );
    squawk = dizzy ? .2 : math.max(roar, math.max(recoil, hit));
    flutter = m.reducedMotion
        ? 0
        : math.max(hit, roar * .8) * (.6 + .4 * math.sin(boss.age * 30).abs());
    fringe = time == 0 ? 0 : math.sin(time * 2.4 + .6) * .02 + hit * .04;
    braid = time == 0 ? 0 : math.sin(time * 2.1) * .03 - recoil * .05;
    jiggle = time == 0 ? 0 : math.sin(time * 3.1) * .03 + hit * .05;
    headShift = Offset(recoil * .04 + hit * .03, -roar * .05 + breath);
    // Turned toward the bird, he dips his nose to look down at it.
    headTilt =
        -aim * .05 +
        (m.reducedMotion
            ? 0
            : recoil * .06 - roar * .05 + hit * .05 + charge * -.04);
    hatLift = m.reducedMotion ? 0 : hit * .22 + recoil * .09 + roar * .14;
    hatTilt = m.reducedMotion ? 0 : -hit * .17 - roar * .06 + recoil * .05;
    // The plume drifts in the wind, streams down as the hat pops up, and
    // flutters in fury; the braid glints in pulses.
    hatSway = time == 0
        ? 0
        : math.sin(time * 1.9) * .05 +
              hit * .22 +
              recoil * .12 +
              roar * .1 +
              (fury > 0 ? math.sin(time * 13) * .035 : 0);
    hatGlint = time == 0
        ? 0
        : math.pow((math.sin(time * 2.3) + 1) / 2, 10).toDouble();
    // The torch: held up by his face, swung out over the cannon and dipped
    // to the wick while the charge builds, thrust high with the roar and the
    // shot.
    final idleHand = Offset(-.94, .18 + breath);
    const idleAngle = -1.66;
    // The dip arcs out to the left, so the flame never crosses his face: the
    // torch points from an outstretched hand down at the wick.
    final wick = fuse - const Offset(-.96, -.24);
    final dipDir = wick / math.max(wick.distance, 1e-6);
    var dipAngle = math.atan2(dipDir.dy, dipDir.dx);
    if (dipAngle > idleAngle) dipAngle -= math.pi * 2;
    final dipHand = fuse - dipDir * PirateCaptainBodyArt.torchReach;
    final raisedHand = const Offset(-1.04, -.14);
    const raisedAngle = -1.9;
    final dip = BossMotion.ease(BossMotion.ramp(charge, 0, .35));
    final up = math.max(recoil, roar);
    torchHand = Offset.lerp(
      Offset.lerp(idleHand, dipHand, dip)!,
      raisedHand,
      up,
    )!;
    // The held torch sways a touch; a beaten captain lets it droop away.
    final sway = time == 0 ? 0.0 : math.sin(time * 1.7) * .035 * (1 - dip);
    final slump = m.defeated
        ? BossMotion.ease(BossMotion.ramp(m.death, 0, .4))
        : 0.0;
    torchAngle =
        _lerpAngle(idleAngle + (dipAngle - idleAngle) * dip, raisedAngle, up) +
        sway -
        slump * .7;
    // The hook: resting on the hip, raised to call the tide, shaken in fury,
    // flung up in the roar.
    final rest = Offset(1.04, .64 + breath);
    final raised = const Offset(1.28, -.42);
    // In fury the claw is kept half-raised and ready.
    final lift = math.max(math.max(call, roar), fury > 0 ? .16 : 0.0);
    hookHand =
        Offset.lerp(rest, raised, lift)! +
        Offset(furyShake * (1 - lift), furyShake * .5) +
        Offset(hit * .08, -hit * .06);
    hookBehind = false;
    hookTwist = -lift * 1.25 + hit * .3;
    // Shoulders hunch and tremble with the fury.
    final hunch =
        (fury > 0 ? .045 + (time == 0 ? 0 : math.sin(time * 17) * .01) : 0.0) +
        hit * .04 -
        slump * .06;
    body = CaptainBodyPose(
      time: time,
      breath: breath,
      hunch: hunch,
      fury: fury,
      roar: roar,
      charge: charge,
      recoil: recoil,
      fringe: fringe,
      torchHand: torchHand,
      torchAngle: torchAngle,
      torchUp: up,
      hookHand: hookHand,
      hookTwist: hookTwist,
      hookLift: lift,
      dizzy: dizzy,
    );
  }

  final double time, charge, recoil, wince, roar, blink, fury, aim;
  final bool dizzy;
  final StoryMood? mood;
  late final double talk;
  late final double breath, mouth, squawk, flutter, fringe, braid, jiggle;
  // The tide call, for the face's smug bellow.
  late final double tide;
  // The shot's shout, an expression that still plays under Reduced Motion.
  late final double shot;
  late final double headTilt, hatLift, hatTilt, torchAngle, hookTwist;
  late final double hatSway, hatGlint;
  late final Offset headShift, torchHand, hookHand;
  late final bool hookBehind;
  late final CaptainBodyPose body;

  static double _tideCall(SkyBoss boss) {
    if (boss.phase != BossPhase.attacking) return 0;
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    final up = BossMotion.ramp(
      cycle,
      SkyBoss.tideWarnAt,
      SkyBoss.tideWarnAt + .35,
    );
    final down = BossMotion.ramp(
      cycle,
      SkyBoss.tidePeakAt + .2,
      SkyBoss.tidePeakAt + .8,
    );
    return BossMotion.ease(up) * (1 - BossMotion.ease(down));
  }

  static double _lerpAngle(double a, double b, double t) {
    var d = (b - a) % (math.pi * 2);
    if (d > math.pi) d -= math.pi * 2;
    if (d < -math.pi) d += math.pi * 2;
    return a + d * t;
  }
}
