import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import '../domain/sky_boss.dart';
import '../game/boss_motion.dart';
import '../game/boss_rig.dart';
import '../game/dragon_body_art.dart';
import '../game/dragon_head_art.dart';
import '../game/dragon_kit.dart';
import '../game/dragon_layout.dart';
import '../game/dragon_story_art.dart';
import '../game/dusk_moth_body_art.dart';
import '../game/dusk_moth_boss_rig.dart';
import '../game/dusk_moth_head_art.dart';
import '../game/dusk_moth_kit.dart';
import '../game/dusk_moth_pose.dart';
import '../game/dusk_moth_wing_art.dart';
import '../game/pirate_boss_rig.dart';
import '../game/pirate_captain_body_art.dart';
import '../game/pirate_captain_face_art.dart';
import '../game/pirate_parrot_art.dart';
import '../game/pirate_ship_art.dart';
import '../game/spitter_boss_rig.dart';

/// The five bosses as they stand in a story scene: each drawn by its own
/// flight rig, held still in a pose for the mood of its line.
///
/// A boss faces left, toward the courier, in its rig's units around its hit
/// circle. [portrait] says how big and where the stage draws it. [beaten]
/// is the look of the scene after its fall: the headwear is gone (the Dusk
/// Empress's has only slipped), the Spitter King's still is cracked, the
/// Pirate Captain is down to a barrel, and a plain line looks sheepish.
abstract final class StoryBossArt {
  /// How the stage fits [kind]: pixels per rig unit on a 360-high stage,
  /// where the rig's origin sits from the boss's place on the floor line,
  /// and everything the art can reach, in rig units.
  static ({double unit, Offset origin, Rect reach}) portrait(
    BossKind kind, {
    bool beaten = false,
  }) => switch (kind) {
    BossKind.baronBat => (
      unit: 60,
      origin: const Offset(0, -112),
      reach: const Rect.fromLTRB(-2.7, -2.4, 2.7, 1.6),
    ),
    BossKind.spitterBeetle => (
      unit: 68,
      origin: const Offset(-26, -118),
      reach: const Rect.fromLTRB(-2.2, -2.4, 2.6, 1.8),
    ),
    BossKind.duskMoth => (
      unit: 54,
      origin: const Offset(-52, -126),
      reach: const Rect.fromLTRB(-2.4, -3.2, 3.7, 2.8),
    ),
    BossKind.pirate => (
      unit: beaten ? 66 : 62,
      origin: beaten ? const Offset(-6, -98) : const Offset(-28, -76),
      reach: beaten
          ? const Rect.fromLTRB(-2.4, -2.2, 2.4, 3.4)
          : PirateShipArt.bounds,
    ),
    BossKind.dragon => (
      unit: 60,
      origin: const Offset(40, -28),
      reach: const Rect.fromLTRB(-2.7, -5.4, 5.4, 2.6),
    ),
  };

  /// Paints [kind] in rig units. [talk] (0 to 1) opens its mouth as the
  /// line is written out and [blink] (0 to 1) shuts its eyes.
  static void paint(
    Canvas c,
    BossKind kind,
    StoryMood mood, {
    bool beaten = false,
    double talk = 0,
    double blink = 0,
  }) {
    // A beaten boss with nothing to say for itself looks sheepish.
    final m = beaten && mood == StoryMood.plain ? StoryMood.sad : mood;
    switch (kind) {
      case BossKind.baronBat:
        _baron(c, m, beaten, talk, blink);
      case BossKind.spitterBeetle:
        _spitter(c, m, beaten, talk, blink);
      case BossKind.duskMoth:
        _moth(c, m, beaten, talk, blink);
      case BossKind.pirate:
        _pirate(c, m, beaten, talk, blink);
      case BossKind.dragon:
        _dragon(c, m, beaten, talk, blink);
    }
  }

  /// [kind] mid-fight and calm, or [furious]: past half health, its fury
  /// long settled.
  static SkyBoss _boss(BossKind kind, {bool furious = false}) {
    final boss = SkyBoss(
      number: kind.index + 1,
      x: 0,
      kind: kind,
      cinematic: true,
      debut: true,
    );
    boss
      ..age = boss.arrivalDuration + 1
      ..fireIn = 2;
    if (furious) {
      boss
        ..hp = boss.maxHp ~/ 2 - 1
        ..enragedAt = boss.age - 3;
    }
    return boss;
  }

  static const _ink = Color(0xff203b45);
  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ---------------------------------------------------------- Baron Bat --

  static void _baron(
    Canvas c,
    StoryMood mood,
    bool beaten,
    double talk,
    double blink,
  ) {
    final boss = _boss(BossKind.baronBat, furious: mood == StoryMood.angry);
    final (pose, look) = switch (mood) {
      StoryMood.plain => (
        _Pose(boss, stroke: -.1, fold: .1, mouth: talk * .6, blink: blink),
        0.0,
      ),
      StoryMood.happy => (
        _Pose(boss, stroke: -.7, mouth: .25 + talk * .5, blink: blink),
        -.3,
      ),
      StoryMood.surprised => (
        _Pose(
          boss,
          stroke: -1,
          mouth: .3 + talk * .35,
          blink: blink > .5 ? blink : -.16,
          crownLift: .3,
        ),
        -.6,
      ),
      StoryMood.angry => (
        _Pose(boss, stroke: -.45, mouth: .12 + talk * .8, blink: blink),
        0.0,
      ),
      StoryMood.sad => (
        _Pose(
          boss,
          stroke: .55,
          fold: .5,
          mouth: talk * .4,
          blink: math.max(blink, .34),
          wince: .45,
        ),
        1.0,
      ),
    };
    BossRig.paint(c, boss, beaten ? pose.bare() : pose, lookY: look);
    if (beaten) {
      _plaster(c, const Offset(-.3, -.66), .22, -.5);
      if (mood == StoryMood.sad) _sweat(c, const Offset(.7, -.62), .2);
    }
  }

  // ------------------------------------------------------- Spitter King --

  static void _spitter(
    Canvas c,
    StoryMood mood,
    bool beaten,
    double talk,
    double blink,
  ) {
    final boss = _boss(
      BossKind.spitterBeetle,
      furious: mood == StoryMood.angry && !beaten,
    );
    if (beaten) {
      // The rig's own defeat: crown gone, wings dropped, the vat cracked.
      // Its crossed-out eye is painted over with one that can still talk.
      boss.defeatedAt = boss.age - 1;
      SpitterBossRig.paint(c, boss, _Pose(boss, live: true, recoil: talk * .8));
      _spitterEye(c, mood, blink);
      return;
    }
    final (pose, look) = switch (mood) {
      StoryMood.plain => (
        _Pose(boss, live: true, recoil: talk * .8, blink: blink),
        0.0,
      ),
      StoryMood.happy => (
        _Pose(boss, live: true, recoil: talk * .8, summon: .8, blink: blink),
        -.7,
      ),
      StoryMood.surprised => (
        _Pose(boss, live: true, recoil: .25 + talk * .6, blink: blink),
        -1.0,
      ),
      StoryMood.angry => (
        _Pose(boss, live: true, recoil: talk * .9, blink: blink),
        0.0,
      ),
      StoryMood.sad => (
        _Pose(boss, live: true, recoil: talk * .6, blink: math.max(blink, .3)),
        1.0,
      ),
    };
    SpitterBossRig.paint(c, boss, pose, lookY: look);
  }

  static const _lens = Rect.fromLTRB(-.85, -.64, -.31, -.12);
  static const _lid = Color(0xff3f9c80), _deep = Color(0xff1c4d45);
  static const _cream = Color(0xffffefcb);
  static const _spitterInk = SpitterBossRig.ink;

  /// The King's eye behind its monocle, in the rig's own colours, with a
  /// brow that can worry.
  static void _spitterEye(Canvas c, StoryMood mood, double blink) {
    final (lid, slant, gaze, iris, tilt) = switch (mood) {
      StoryMood.happy => (.2, 0.0, -.4, 1.0, -.1),
      StoryMood.surprised => (.04, 0.0, -.3, .78, -.3),
      StoryMood.angry => (.42, .1, 0.0, .9, .3),
      _ => (.46, -.12, .8, 1.0, -.42),
    };
    c.save();
    c.clipPath(Path()..addOval(_lens));
    c.drawOval(
      _lens,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cream, Color(0xffcdebc4)],
        ).createShader(_lens),
    );
    c.save();
    c.translate(-.67, -.38 + gaze * .1);
    c.scale(iris);
    const box = Rect.fromLTWH(-.15, -.18, .3, .36);
    c.drawOval(
      box,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffffc35a), Color(0xffe07a1d)],
        ).createShader(box),
    );
    c.drawOval(box, _line(_spitterInk, .025));
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: .12, height: .28),
      _fill(_spitterInk),
    );
    c.drawCircle(const Offset(-.06, -.09), .04, _fill(_cream));
    c.restore();
    final level =
        _lens.top + _lens.height * (lid + blink * (1 - lid)).clamp(0.0, 1.0);
    final dip = slant * _lens.height;
    c.drawPath(
      Path()
        ..moveTo(_lens.left - .05, _lens.top - .1)
        ..lineTo(_lens.right + .05, _lens.top - .1)
        ..lineTo(_lens.right + .05, level - dip)
        ..lineTo(_lens.left - .05, level + dip)
        ..close(),
      _fill(_lid),
    );
    c.drawLine(
      Offset(_lens.left - .05, level + dip),
      Offset(_lens.right + .05, level - dip),
      _line(_spitterInk, .05),
    );
    c.restore();
    c.drawArc(_lens.deflate(.03), 3.85, 1.4, false, _line(_cream, .03));
    // The brow ridge, tipped up at the front when he is sorry for himself.
    c.save();
    c.translate(-.6, -.7);
    c.rotate(tilt);
    final brow = Path()
      ..moveTo(-.3, .04)
      ..cubicTo(-.18, -.1, .1, -.12, .3, -.02)
      ..cubicTo(.1, -.02, -.12, .02, -.3, .04)
      ..close();
    c.drawPath(brow, _fill(_deep));
    c.drawPath(brow, _line(_spitterInk, .06));
    c.restore();
    _plaster(c, const Offset(-.3, -.86), .2, .5);
    if (mood == StoryMood.sad) _sweat(c, const Offset(-.04, -.62), .17);
  }

  // ------------------------------------------------------- Dusk Empress --

  static void _moth(
    Canvas c,
    StoryMood mood,
    bool beaten,
    double talk,
    double blink,
  ) {
    final boss = _boss(BossKind.duskMoth, furious: mood == StoryMood.angry);
    final (pose, look) = switch (mood) {
      StoryMood.plain => (
        _Pose(boss, roar: talk * .5, blink: blink, fold: .1),
        0.0,
      ),
      StoryMood.happy => (
        _Pose(boss, roar: .15 + talk * .45, blink: blink),
        -.5,
      ),
      StoryMood.surprised => (
        _Pose(boss, roar: .3 + talk * .3, blink: blink),
        -1.0,
      ),
      StoryMood.angry => (_Pose(boss, roar: talk * .7, blink: blink), 0.0),
      StoryMood.sad => (
        _Pose(boss, roar: talk * .35, blink: math.max(blink, .38), fold: .42),
        1.0,
      ),
    };
    final p = DuskMothPose(boss, pose, look);
    // The rig's own draw order, with the diadem placed by hand.
    DuskMothWingArt.paint(c, p, far: true);
    DuskMothWingArt.paint(c, p, far: false);
    DuskMothWingArt.motes(c, p);
    DuskMothBodyArt.abdomen(c, p);
    DuskMothBodyArt.legs(c, p, far: true);
    DuskMothBodyArt.thorax(c, p);
    DuskMothBodyArt.shoulders(c, p);
    DuskMothBodyArt.ruffBack(c, p);
    DuskMothHeadArt.plumes(c, p);
    DuskMothBodyArt.legs(c, p, far: false);
    DuskMothBodyArt.ruffFront(c, p);
    DuskMothBodyArt.glands(c, p);
    DuskMothHeadArt.head(c, p);
    DuskMothBodyArt.bib(c, p);
    DuskMothBodyArt.pollenLight(c, p);
    const seat = DuskMothBossRig.crownAnchor;
    if (p.fury > 0) {
      DuskMothKit.glow(
        c,
        seat + const Offset(-.1, -.3),
        .9,
        DuskMothBossRig.ember,
        p.fury * .5,
      );
    }
    c.save();
    c.translate(seat.dx, seat.dy);
    if (beaten) {
      // It has slipped: down over her brow, at a tilt she would never
      // choose.
      c.translate(-.2, .2);
      c.rotate(-.42);
    }
    DuskMothBossRig.crown(c, fury: p.fury);
    c.restore();
    if (beaten && mood == StoryMood.sad) {
      _sweat(c, const Offset(-.28, -.62), .19);
    }
  }

  // ----------------------------------------------------- Pirate Captain --

  static void _pirate(
    Canvas c,
    StoryMood mood,
    bool beaten,
    double talk,
    double blink,
  ) {
    final boss = _boss(
      BossKind.pirate,
      furious: mood == StoryMood.angry && !beaten,
    );
    final m = _Pose(boss);
    final fury = boss.enraged ? .8 : 0.0;
    // His look, his bellow, a flinch, and how high the hook is raised.
    final (aim, roar, wince, lift) = switch (mood) {
      StoryMood.plain => (0.0, talk * .55, 0.0, 0.0),
      StoryMood.happy => (-.3, .3 + talk * .45, 0.0, .8),
      StoryMood.surprised => (-1.0, .2 + talk * .4, .3, .35),
      StoryMood.angry => (0.0, talk * .75, 0.0, .3),
      StoryMood.sad => (1.0, talk * .4, .55, 0.0),
    };
    final body = CaptainBodyPose(
      fury: fury,
      roar: roar,
      hunch: fury > 0 ? .045 : (mood == StoryMood.sad ? -.04 : 0),
      torchHand: const Offset(-.94, .18),
      hookHand: Offset.lerp(
        const Offset(1.04, .64),
        const Offset(1.28, -.42),
        lift,
      )!,
      hookTwist: -lift * 1.25,
      hookLift: lift,
      dizzy: beaten,
    );
    if (!beaten) PirateShipArt.back(c, boss, m);
    c.saveLayer(PirateBossRig.bounds, Paint());
    const perch = PirateBossRig.parrotAnchor;
    c.save();
    c.translate(perch.dx, perch.dy);
    PirateParrotArt.tail(c, squawk: roar * .5, ruffle: fury);
    c.restore();
    PirateCaptainBodyArt.torso(c, body);
    PirateCaptainBodyArt.hookSleeve(c, body);
    c.save();
    c.translate(0, -roar * .05);
    c.rotate(-aim * .05);
    PirateCaptainFaceArt.paint(
      c,
      PirateFaceState(
        aim: aim,
        roar: roar,
        wince: wince,
        blink: blink,
        fury: fury,
      ),
    );
    c.restore();
    if (!beaten) {
      const seat = PirateBossRig.hatAnchor;
      c.save();
      c.translate(seat.dx, seat.dy);
      PirateBossRig.hat(c, fury: fury > 0);
      c.restore();
    }
    c.save();
    c.translate(perch.dx, perch.dy);
    PirateBossRig.paintParrot(c, squawk: roar * .5, ruffle: fury, look: aim);
    c.restore();
    PirateCaptainBodyArt.hookClaw(c, body);
    PirateCaptainBodyArt.torchLight(c, body);
    PirateCaptainBodyArt.torchArm(c, body);
    c.restore();
    if (beaten) {
      if (mood == StoryMood.sad) _sweat(c, const Offset(.2, -.92), .2);
      _barrel(c);
    } else {
      final barrel = boss.cannonShot(boss.x - 1.2, boss.y - .1).angle;
      PirateShipArt.front(c, boss, m, aim: barrel);
      PirateShipArt.lights(c, boss, m);
    }
  }

  static const _wood = Color(0xff8a5634), _woodLit = Color(0xffb47a4a);
  static const _woodDark = Color(0xff4f2f22), _iron = Color(0xff56627a);

  /// All that is left of his ship: a barrel, up to his belt.
  static void _barrel(Canvas c) {
    const ink = PirateBossRig.ink;
    const top = PirateBossRig.rail - .1;
    final staves = Path()
      ..moveTo(-1.34, top)
      ..cubicTo(-1.62, top + .8, -1.62, top + 1.7, -1.3, top + 2.5)
      ..lineTo(1.3, top + 2.5)
      ..cubicTo(1.62, top + 1.7, 1.62, top + .8, 1.34, top)
      ..close();
    c.drawPath(staves, _fill(_wood));
    c.save();
    c.clipPath(staves);
    c.drawRect(const Rect.fromLTRB(-1.7, top, -.5, top + 2.6), _fill(_woodLit));
    c.drawRect(const Rect.fromLTRB(.78, top, 1.7, top + 2.6), _fill(_woodDark));
    for (final x in const [-.92, -.5, 0.0, .42, .84]) {
      c.drawPath(
        Path()
          ..moveTo(x, top)
          ..quadraticBezierTo(x * 1.22, top + 1.25, x, top + 2.5),
        _line(ink.withValues(alpha: .55), .045),
      );
    }
    for (final y in const [.34, 1.5]) {
      final hoop = Path()
        ..moveTo(-1.7, top + y)
        ..quadraticBezierTo(0, top + y + .22, 1.7, top + y)
        ..lineTo(1.7, top + y + .26)
        ..quadraticBezierTo(0, top + y + .48, -1.7, top + y + .26)
        ..close();
      c.drawPath(hoop, _fill(_iron));
      c.drawPath(hoop, _line(ink, .07));
      c.drawPath(
        Path()
          ..moveTo(-1.1, top + y + .13)
          ..quadraticBezierTo(-.5, top + y + .24, .1, top + y + .25),
        _line(const Color(0xff9fb0c4), .05),
      );
    }
    c.restore();
    c.drawPath(staves, _line(ink, .1));
    // The rim he leans on.
    final rim = Rect.fromLTRB(-1.4, top - .18, 1.4, top + .2);
    c.drawOval(rim, _fill(_woodDark));
    c.drawArc(rim, 0, math.pi, false, _line(ink, .1));
    c.drawPath(
      Path()
        ..moveTo(-1.34, top)
        ..quadraticBezierTo(0, top + .34, 1.34, top),
      _line(_woodLit, .07),
    );
  }

  // ------------------------------------------------------- Ember Dragon --

  static void _dragon(
    Canvas c,
    StoryMood mood,
    bool beaten,
    double talk,
    double blink,
  ) {
    const rest = DragonLayout.headRest;
    final fury = mood == StoryMood.angry ? .9 : 0.0;
    final tone = DragonTone(fury: fury);
    // Where the head is carried, the wings, the sag, the heart's light.
    final (at, angle, stroke, fold, slump, heart) = switch (mood) {
      StoryMood.plain => (rest, .14, -.25, 0.0, 0.0, .2),
      StoryMood.happy => (
        rest + const Offset(-.06, -.12),
        .04,
        -.5,
        0.0,
        0.0,
        .9,
      ),
      StoryMood.surprised => (
        rest + const Offset(.24, -.16),
        -.12,
        -.85,
        0.0,
        0.0,
        .45,
      ),
      StoryMood.angry => (
        rest + const Offset(-.16, .06),
        .2,
        -.75,
        0.0,
        0.0,
        .45,
      ),
      StoryMood.sad => (rest + const Offset(.1, .5), .5, .35, .4, .28, .1),
    };
    final (gape, glare, look, lids, smoke) = switch (mood) {
      StoryMood.plain => (talk * .4, 0.0, 0.0, 0.0, .3),
      StoryMood.happy => (.14 + talk * .32, 0.0, -.3, 0.0, .25),
      StoryMood.surprised => (.24 + talk * .24, 0.0, -.6, 0.0, .2),
      StoryMood.angry => (.12 + talk * .55, 1.0, 0.0, 0.0, .8),
      StoryMood.sad => (talk * .3, 0.0, 1.0, .42, .12),
    };
    final body = DragonBodyPose(heart: heart, slump: slump, tone: tone);
    final head = DragonHeadPose(
      at: at,
      angle: angle,
      gape: gape,
      glare: glare,
      look: look,
      blink: math.max(blink, lids),
      smoke: smoke,
      crown: !beaten,
      tone: tone,
    );
    if (fury > 0) {
      DragonKit.glow(
        c,
        const Offset(.6, -.9),
        3.6,
        DragonPalette.flame,
        fury * .32,
      );
    }
    // The rig's own parts and order (see DragonStoryArt).
    DragonStoryArt.paint(
      c,
      body: body,
      head: head,
      tone: tone,
      stroke: stroke,
      fold: fold,
    );
  }

  // ------------------------------------------------------------- props --

  /// A bead of sweat at the temple: the sheepish look of the beaten.
  static void _sweat(Canvas c, Offset at, double size) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(size);
    final drop = Path()
      ..moveTo(0, -1)
      ..cubicTo(.75, 0, .6, .8, 0, .8)
      ..cubicTo(-.6, .8, -.75, 0, 0, -1)
      ..close();
    c.drawPath(drop, _fill(const Color(0xff9fe0f2)));
    c.drawPath(drop, _line(_ink, .24));
    c.drawLine(
      const Offset(-.2, .1),
      const Offset(-.2, .36),
      _line(const Color(0xffffffff), .17),
    );
    c.restore();
  }

  /// A sticking plaster: two crossed strips where the headwear sat.
  static void _plaster(Canvas c, Offset at, double size, double turn) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(size);
    for (final quarter in const [0.0, math.pi / 2]) {
      c.save();
      c.rotate(quarter);
      final strip = RRect.fromRectAndRadius(
        const Rect.fromLTRB(-1, -.3, 1, .3),
        const Radius.circular(.3),
      );
      c.drawRRect(strip, _fill(const Color(0xffffe2c4)));
      c.drawRRect(strip, _line(_ink, .16));
      c.restore();
    }
    c.drawRect(
      const Rect.fromLTRB(-.3, -.3, .3, .3),
      _fill(const Color(0xfffff6e6)),
    );
    c.restore();
  }
}

/// A boss held in one pose: every channel a rig reads from its motion is
/// set by hand, so nothing moves unless the scene asks for another frame.
///
/// [live] lets a rig that only opens its mouth in motion (the Spitter King)
/// do so; the boss's clock never runs, so it still holds the frame.
class _Pose extends BossMotion {
  const _Pose(
    super.boss, {
    bool live = false,
    this.mouth = 0,
    this.recoil = 0,
    this.roar = 0,
    this.summon = 0,
    this.blink = 0,
    this.wince = 0,
    this.fold = 0,
    this.stroke = 0,
    this.crownLift = 0,
    this.crownless = false,
  }) : super(reducedMotion: !live);

  @override
  final double mouth, recoil, roar, summon, blink, wince, crownLift;

  /// Wings folded in (0 to 1), and the wingbeat's place in its stroke.
  final double fold, stroke;

  /// The headwear has been knocked off for good.
  final bool crownless;

  /// The same pose without its crown.
  _Pose bare() => _Pose(
    boss,
    live: !reducedMotion,
    mouth: mouth,
    recoil: recoil,
    roar: roar,
    summon: summon,
    blink: blink,
    wince: wince,
    fold: fold,
    stroke: stroke,
    crownless: true,
  );

  @override
  bool get arriving => false;
  @override
  double get death => defeated || crownless ? 1 : -1;
  @override
  double get hit => 0;
  @override
  double get rage => 0;
  @override
  double get folded => fold;
  @override
  double get wingStroke => stroke;
  @override
  double get wingBeat => 0;
  @override
  double get silhouette => 0;
  @override
  double get opacity => 1;
  @override
  double get bodyScale => 1;
  @override
  double get stretch => 0;
  @override
  double get rotation => 0;
  @override
  Offset get offset => Offset.zero;
  @override
  Offset get shake => Offset.zero;
}
