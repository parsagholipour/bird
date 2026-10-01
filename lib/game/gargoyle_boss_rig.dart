
import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'gargoyle_body_art.dart';
import 'gargoyle_head_art.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';
import 'gargoyle_staging_art.dart';
import 'gargoyle_wing_art.dart';

/// The Searchlight Gargoyle: a limestone Art Deco eagle bolted to the tower's
/// ledge since 1931, two premiere searchlights for eyes, a brass lamp medallion
/// in his chest, seven-blade stainless fans for wings, hooked steel beak under
/// scowling steel visors.
///
/// Authored in hit-radius units around the hit circle, which is his chest lamp,
/// facing left toward the bird. Every combat pose stays inside
/// [GargoyleLayout.envelope], so nothing crops at 640x360 or 800x360. He does
/// not fly: the rig's origin is the rules' (`boss.x`, `.5`) always.
///
/// The rig only assembles: it leans the upper body about the hips by the
/// pose's `lean`, places the head ([GargoyleLayout.headPoint]), then paints the
/// parts in [GargoyleLayout.zOrder]. Each part builds its own small pose from
/// the [GargoylePose] with its `of` factory, so a part can grow new channels
/// without touching the rig. The beams, the warning, the feathers, the HUD and
/// the stage are NOT drawn here (see G5, G6, G7, G8 in HANDOFF.md).
abstract final class GargoyleBossRig {
  /// Everything the rig can reach in the layer that whitens, silhouettes or
  /// fades it (the arrival's flash, the defeat's white-out).
  static const bounds = GargoyleLayout.layerBounds;

  /// The hit circle's centre: the origin, and exactly where the lamp is drawn
  /// in EVERY pose. The upper body leans about the hips and the chest slides
  /// behind the brass medallion, which is painted outside the lean, so a rock
  /// that looks like it hit the lamp always counts (the rules' circle is the
  /// lamp's glass, r 1).
  static const lampCenter = Offset.zero;

  /// Where a lens is for [pose], in rig units: the beam's source.
  static Offset eyeAt(GargoylePose pose, {bool far = false}) =>
      pose.headPoint(far ? GargoyleLayout.eyeFar : GargoyleLayout.eyeNear);

  /// Both beam sources for [pose]: [near] fires the zone beam and the slit's
  /// lower beam, [far] the slit's upper beam.
  static ({Offset near, Offset far}) beamOrigins(GargoylePose pose) =>
      (near: eyeAt(pose), far: eyeAt(pose, far: true));

  /// The beak's most forward point (rig units).
  static Offset beakTipAt(GargoylePose pose) => pose.headPoint(GargoyleLayout.beakTip);

  /// The lens centres at rest (the still pose), for the silhouette and the
  /// anchor sheet.
  static Offset get eyeRest => eyeAt(GargoylePose.still);

  /// Where the blade a shrug loosens is when it leaves (the top blade's tip,
  /// rig units): the feather's presentation starts here and leaves upward;
  /// the rules' feather itself appears at the top edge ([featherSpawn]).
  static Offset featherLeaveAt(GargoylePose pose) =>
      pose.bodyPoint(pose.nearFan.tip(GargoyleLayout.shedBlade, far: false));

  /// Where the rules spawn a feather on a screen of [size] (px): the top
  /// edge, [SearchlightGargoyle.featherOffsetX] screen heights right of the
  /// bird's column. The dust that announces it falls here.
  static Offset featherSpawn(Size size) => Offset(
    (GargoyleLayout.birdColumn + SearchlightGargoyle.featherOffsetX) * size.height,
    SearchlightGargoyle.featherY * size.height,
  );

  /// Where the near brow visor sits for [pose] (rig units) and the turn and
  /// scale to paint it with, so the visor the defeat knocks loose starts
  /// exactly on the head that lost it.
  static ({Offset at, double angle, double scale}) visorAt(GargoylePose pose) => (
    at: pose.headPoint(GargoyleLayout.visorSeat),
    angle: pose.pitch - GargoyleLayout.bodyTurn(pose.lean),
    scale: GargoyleLayout.headScale,
  );

  /// The visor as the defeat knocks it loose, [death] seconds in.
  static ({Offset at, double angle, double scale}) visorDrop(double death, {bool reduced = false}) =>
      visorAt(GargoylePose.atDeath(death, reduced: reduced));

  /// The visor on its own, seated at its anchor's origin.
  static void visorPaint(Canvas c, [GargoyleTone tone = const GargoyleTone()]) =>
      GargoyleHeadArt.visorPaint(c, tone);

  /// The Gargoyle in its current pose. [lookY] turns his head a hair toward
  /// the bird (-1 up, 1 down); [light] is the backdrop's light; [gap] the
  /// distance from his lenses to the bird's column (screen heights; see
  /// [GargoylePose]).
  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    GargoyleSkyLight light = GargoyleSkyLight.neutral,
    double gap = GargoylePose.defaultGap,
    bool plinth = true,
  }) => paintPose(c, GargoylePose(boss, m, lookY: lookY, light: light, gap: gap), plinth: plinth);

  /// The Gargoyle in [pose]; see [paint]. [only] limits the drawing to the
  /// named parts ([GargoyleLayout.zOrder]) and [trace] hears each part as it is
  /// painted (both for tests and previews: the envelope and budget tests use
  /// them to name the part that misbehaves; a game frame passes neither).
  /// [plinth] false leaves out the ledge (silhouettes). Once the body has
  /// crumbled ([GargoylePose.crumble] at 1) only the ledge and the bloom
  /// remain (the staging draws the rubble).
  static void paintPose(
    Canvas c,
    GargoylePose pose, {
    Set<String>? only,
    void Function(String part)? trace,
    bool plinth = true,
  }) {
    bool on(String part) {
      if (only != null && !only.contains(part)) return false;
      trace?.call(part);
      return true;
    }

    final gone = pose.crumble >= 1;
    final lamp = pose.lamp;
    // The lamp's glow behind everything: the body reads as a dark shape in
    // front of its own light. Two cached radials, one op each.
    if (!gone && lamp > .02 && on('bloom')) {
      GargoyleKit.glow(c, Offset.zero, 3.2, GargoylePalette.lampWarm, .38 * lamp);
    }
    if (plinth && on('ledge')) GargoyleStagingArt.ledge(c, pose);
    if (gone) return;

    final body = GargoyleBodyPose.of(pose);
    final head = GargoyleHeadPose.of(pose);
    final near = GargoyleWing.nearOf(pose), far = GargoyleWing.farOf(pose);

    // The upper body leans about the lamp (so the hit circle never moves); the
    // tail and the legs stay on the ledge.
    void leaned(void Function() paint) {
      c.save();
      c.rotate(GargoyleLayout.bodyTurn(pose.lean));
      paint();
      c.restore();
    }

    if (on('farFan')) leaned(() => GargoyleWingArt.paint(c, far));
    if (on('tail')) GargoyleBodyArt.tail(c, body);
    if (on('farLeg')) GargoyleBodyArt.farLeg(c, body);
    if (on('torso')) leaned(() => GargoyleBodyArt.torso(c, body));
    if (on('thigh')) GargoyleBodyArt.thigh(c, body);
    if (on('ruff')) leaned(() => GargoyleBodyArt.ruff(c, body));
    if (on('nearFan')) leaned(() => GargoyleWingArt.paint(c, near));
    if (on('lamp')) {
      leaned(() => GargoyleBodyArt.lamp(c, body));
      if (lamp > .02) GargoyleKit.glow(c, Offset.zero, 1.25, GargoylePalette.lampWarm, .75 * lamp);
    }
    if (on('head')) {
      c.save();
      c.rotate(GargoyleLayout.bodyTurn(pose.lean));
      c.translate(pose.head.dx, pose.head.dy);
      c.translate(GargoyleLayout.headPivot.dx, GargoyleLayout.headPivot.dy);
      c.rotate(-pose.pitch);
      c.translate(-GargoyleLayout.headPivot.dx, -GargoyleLayout.headPivot.dy);
      c.translate(GargoyleLayout.headShift.dx, GargoyleLayout.headShift.dy);
      c.translate(GargoyleLayout.headPivot.dx, GargoyleLayout.headPivot.dy);
      c.scale(GargoyleLayout.headScale);
      c.translate(-GargoyleLayout.headPivot.dx, -GargoyleLayout.headPivot.dy);
      GargoyleHeadArt.paint(c, head);
      c.restore();
    }
    if (on('cracks')) leaned(() => GargoyleBodyArt.cracks(c, body));
    if (on('steam')) leaned(() => GargoyleBodyArt.steam(c, body));
    if (pose.shedTau >= 0 && on('shed')) leaned(() => GargoyleWingArt.shedBlade(c, near, pose.shedTau));
  }
}
