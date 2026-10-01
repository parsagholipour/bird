import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'king_coo_body_art.dart';
import 'king_coo_crumb_art.dart';
import 'king_coo_head_art.dart';
import 'king_coo_hide_art.dart';
import 'king_coo_kit.dart';
import 'king_coo_layout.dart';
import 'king_coo_pose.dart';
import 'king_coo_wing_art.dart';

/// King Coo, Commissioner of the Curb: a huge grumpy pouter pigeon in a navy
/// police cap with a flashing siren, a silver whistle on a chain, a brass
/// badge on a chest he is proud of and a sack of stale crumbs.
///
/// Authored in hit-radius units around the hit circle, which is his chest,
/// facing left toward the bird. It fills the right of the screen; every combat
/// pose stays inside [KingCooLayout.envelope] so nothing crops at 640x360 or
/// 800x360 in the worst hover.
///
/// The rig only assembles: it turns the whole figure by the pose's roll and
/// pitch, squashes and swells it, shifts it by its bob, then paints the parts
/// in [KingCooLayout.zOrder]. Each part builds its own pose object from the
/// [KingCooPose] with its `of` factory (`KingCooHeadPose.of`,
/// `KingCooBodyPose.of`, `KingCooWing.nearOf/farOf`), so a part can grow new
/// channels without touching the rig. Every anchor below is a point of the
/// figure as painted this frame (through [KingCooPose.toRig]): hand them to
/// the effects and they land on the pixels.
abstract final class KingCooBossRig {
  /// Everything the rig can reach in the layer that whitens, silhouettes or
  /// fades it (arrival swell, defeat over-swell and squash included).
  static const bounds = KingCooLayout.layerBounds;

  // ----------------------------------------------------------------- anchors

  /// The chest's centre (the hit circle's centre) for [pose]: the bob.
  static Offset chestCenter(KingCooPose pose) => pose.toRig(Offset.zero);

  /// The brass badge: the aim point.
  static Offset badgeAt(KingCooPose pose) => pose.toRig(KingCooLayout.badge);

  /// The beak's tip, and where the beak opens (the COO!, the whistle's note).
  static Offset beakAt(KingCooPose pose) =>
      pose.toRig(pose.headPoint(KingCooLayout.headBeakTip));
  static Offset mouthAt(KingCooPose pose) =>
      pose.toRig(pose.headPoint(KingCooLayout.headMouth));

  /// The eye (the arrival's one orange glint, the eye that follows the bird).
  static Offset eyeAt(KingCooPose pose) =>
      pose.toRig(pose.headPoint(KingCooLayout.headEye));

  /// Where the cap sits for [pose] (rig units) and the turn to draw it with
  /// (radians, clockwise positive), so the falling cap starts exactly on the
  /// head that lost it.
  static ({Offset at, double angle}) capAt(KingCooPose pose) => (
    at: pose.toRig(pose.capPoint(KingCooLayout.headCapSeat)),
    angle: pose.roll + pose.pitch + pose.headTilt + pose.capTilt + pose.capSpin,
  );

  /// The cap as the killing blow knocks it loose ([death] seconds in; it
  /// leaves at 0.3 s): exact for any real defeat from 0.3 s on, because the
  /// pose he died in has settled into a canonical one by then.
  static ({Offset at, double angle}) capDrop(
    double death, {
    bool reduced = false,
  }) => capAt(KingCooPose.atDeath(death, reduced: reduced));

  /// The siren's dome (where its red and blue light throws from).
  static Offset sirenAt(KingCooPose pose) =>
      pose.toRig(pose.capPoint(KingCooLayout.headSiren));

  /// The whistle, wherever it is (hanging, in the beak, swinging).
  static Offset whistleAt(KingCooPose pose) => pose.toRig(pose.whistleAt);

  /// Where the bomb is held: the near wing's tip. At the release it is
  /// [KingCooLayout.lobRelease] (within [KingCooLayout.lobReleaseTolerance]),
  /// which is where the flying bomb starts: take the pose at the launch with
  /// `KingCooPose(boss, m, at: lob.launchAt)`.
  static Offset bombOrigin(KingCooPose pose) => pose.toRig(pose.handAt);

  /// The nominal release point for [pose] (the layout's anchor carried by the
  /// figure's hover), and the mouth of the sack the wing dips into.
  static Offset lobReleaseAt(KingCooPose pose) =>
      pose.toRig(KingCooLayout.lobRelease);
  static Offset sackAt(KingCooPose pose) =>
      pose.toRig(KingCooLayout.sackMouth);

  /// The rest pose's eye, for the silhouette and the story art.
  static final Offset eyeCenter = eyeAt(KingCooPose.still);

  // ------------------------------------------------------------------ paint

  /// King Coo in his current pose. [lookY] turns his eye toward the bird (-1
  /// up, 1 down); [light] is the backdrop's light; [cap] false leaves the cap
  /// off (the defeat's tumble draws it separately).
  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    bool cap = true,
    KingCooSkyLight light = KingCooSkyLight.neutral,
  }) => paintPose(
    c,
    KingCooPose(boss, m, lookY: lookY, light: light),
    cap: cap,
  );

  /// King Coo in [pose]; see [paint]. [only] limits the drawing to the named
  /// parts of [KingCooLayout.zOrder] and [trace] hears each part as it is
  /// painted (both for tests and previews: the envelope and budget tests use
  /// them to name the part that misbehaves; a game frame passes neither).
  static void paintPose(
    Canvas c,
    KingCooPose pose, {
    bool cap = true,
    Set<String>? only,
    void Function(String part)? trace,
    bool hide = true,
  }) {
    bool on(String part) {
      if (only != null && !only.contains(part)) return false;
      trace?.call(part);
      return true;
    }

    final body = KingCooBodyPose.of(pose);
    final head = KingCooHeadPose.of(pose);
    final joined = hide && (only == null || only.containsAll(_hideParts));
    c.save();
    c.translate(pose.bob.dx, pose.bob.dy);
    c.rotate(pose.roll + pose.pitch);
    c.scale(pose.scaleX, pose.scaleY);
    if (on('farWing')) KingCooWingArt.paint(c, KingCooWing.farOf(pose));
    if (on('farLeg')) KingCooBodyArt.farLeg(c, body);
    if (joined) {
      // One creature: tail, torso, neck, near leg, chest and the skull's skin
      // under one outline, at the first of their places in the z-order.
      final skin = KingCooHide(
        body,
        head,
        only == null || only.contains('ruff'),
      );
      var painted = false;
      void lay(String part) {
        if (on(part) && !painted) {
          painted = true;
          skin.paint(c);
        }
      }

      lay('tail');
      lay('torso');
      lay('neck');
      if (on('sack')) KingCooBodyArt.sack(c, body);
      lay('nearLeg');
      lay('chest');
      // The ruff is part of the hide (one outline); it is still announced in
      // its place so a trace hears every part in the z-order.
      on('ruff');
      if (on('head')) KingCooHeadArt.face(c, head, withCap: false, withWhistle: false);
    } else {
      if (on('tail')) KingCooBodyArt.tail(c, body);
      if (on('torso')) KingCooBodyArt.torso(c, body);
      if (on('neck')) KingCooHeadArt.neck(c, head);
      if (on('sack')) KingCooBodyArt.sack(c, body);
      if (on('nearLeg')) KingCooBodyArt.nearLeg(c, body);
      if (on('chest')) KingCooBodyArt.chest(c, body);
      if (on('ruff')) KingCooHeadArt.ruff(c, head);
      if (on('head')) KingCooHeadArt.head(c, head);
    }
    if (on('cap') && cap) KingCooHeadArt.cap(c, head);
    if (on('whistle')) KingCooHeadArt.whistle(c, head);
    if (on('nearWing')) KingCooWingArt.paint(c, KingCooWing.nearOf(pose));
    if (on('bomb') && pose.bombHeld > 0) {
      KingCooCrumbArt.bomb(
        c,
        pose.handAt,
        KingCooLayout.bombRadius,
        spin: pose.bombSpin,
      );
    }
    if (on('steam')) KingCooHeadArt.steam(c, head);
    c.restore();
  }

  /// The parts `KingCooHide` paints as one creature (torso with the tail, the
  /// near leg, the neck, the chest and the skull's skin); painted alone or with
  /// only some of them, a part wears its own full outline as it did before.
  static const _hideParts = {'tail', 'torso', 'neck', 'nearLeg', 'chest', 'head'};

  /// The cap on its own, its band centre at the origin (for the defeat's
  /// tumble, the keepsake and the health bar's badge).
  static void capPaint(Canvas c) => KingCooHeadArt.capOnly(c);

  /// Builds every gradient and outline the fight will ask for (each chest
  /// swell, both siren colours, the glows, the bomb) into a picture nobody
  /// sees, so that no frame of the fight builds a shader. Call it once as
  /// the arrival begins; it is pure and safe to call again.
  static void prewarm() {
    final boss = SkyBoss(
      number: 6,
      x: 0,
      kind: BossKind.kingCoo,
      cinematic: true,
    );
    boss.lobs.add(
      CrumbLob(lockedAt: 4.6 + .6, lockX: .47, lockY: .5),
    );
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    // Each swell of the chest (1/16 steps) with the siren red and blue, the
    // whistle up, the bomb in hand, fury's flush, the hit's bleach.
    for (var i = 0; i <= 16; i++) {
      boss.age = 4.6 + 7.6 + 1.6 * (i / 16);
      paintPose(c, KingCooPose(boss, BossMotion(boss, reducedMotion: false)));
    }
    for (final age in [4.6 + 1.2, 4.6 + 1.1, 4.6 + 9.3, 4.6 + 9.6, 4.6 + 12.0]) {
      boss.age = age;
      for (final reduced in [false, true]) {
        paintPose(c, KingCooPose(boss, BossMotion(boss, reducedMotion: reduced)));
      }
    }
    boss.age = 4.6 + 1.2;
    boss.lastHitAt = boss.age - .1;
    boss.hp = boss.maxHp ~/ 2;
    boss.enragedAt = boss.age - 5;
    paintPose(c, KingCooPose(boss, BossMotion(boss, reducedMotion: false)));
    for (final siren in [0, 1, 2]) {
      KingCooHeadArt.capOnly(c, siren: siren, sirenGlow: 1);
    }
    KingCooCrumbArt.bomb(c, Offset.zero, KingCooLayout.bombRadius, alpha: .5);
    recorder.endRecording().dispose();
  }
}
