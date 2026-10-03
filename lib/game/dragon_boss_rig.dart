import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'dragon_body_art.dart';
import 'dragon_head_art.dart';
import 'dragon_hide_art.dart';
import 'dragon_kit.dart';
import 'dragon_layout.dart';
import 'dragon_pose.dart';
import 'dragon_wing_art.dart';

/// The Ember Dragon: an obsidian-scaled wyrm lit from within by molten
/// seams, with vast crimson wings, a horned head wearing a gold circlet on a
/// long spined neck, a banded amber belly, a heart-gem set in its chest, and
/// a tail ending in a bone blade.
///
/// Authored in hit-radius units around the hit circle, which is its heart,
/// facing left toward the bird. It fills the right of the screen; every pose
/// stays inside [DragonLayout.envelope] so nothing crops at 640x360 or
/// 800x360 in the worst bob.
///
/// The rig only assembles: it turns the whole figure by the pose's pitch and
/// shifts it by its bob, then paints the parts in [DragonLayout.zOrder]. Each
/// part builds its own pose object from the [DragonPose] with its `of`
/// factory, so a part can grow new channels without touching the rig.
abstract final class DragonBossRig {
  /// Everything the rig can reach in the layer that whitens, silhouettes or
  /// fades it (arrival swell, defeat pitch and fall included).
  static const bounds = DragonLayout.layerBounds;

  /// The rest pose's anchors, for the silhouette, the circlet and the jaws.
  static final _rest = DragonHeadPose.of(DragonPose.still);
  static Offset get eyeCenter =>
      DragonPose.still.toRig(DragonHeadArt.point(_rest, DragonHeadArt.eye));
  static Offset get crownAnchor => DragonPose.still.toRig(
    DragonHeadArt.point(_rest, DragonHeadArt.crownSeat),
  );
  static const crownBounds = DragonHeadArt.crownBounds;

  /// Where the jaws open for [pose], in rig units: exactly the rules' mouth
  /// at full charge.
  static Offset mouthAt(DragonPose pose) =>
      pose.toRig(DragonHeadArt.point(headOf(pose), DragonHeadArt.mouth));

  /// The lower jaw's tip for [pose], in rig units, swung open as the head
  /// draws it: with [mouthAt], the two lips the roar's fire pours between.
  static Offset chinAt(DragonPose pose) {
    final head = headOf(pose);
    return pose.toRig(
      DragonHeadArt.point(
        head,
        DragonHeadArt.jawFront(head.gape, openBy: DragonHeadArt.openFor(head)),
      ),
    );
  }

  /// Where the eye is for [pose], in rig units.
  static Offset eyeAt(DragonPose pose) =>
      pose.toRig(DragonHeadArt.point(headOf(pose), DragonHeadArt.eye));

  /// The head's pose for [pose].
  static DragonHeadPose headOf(DragonPose pose) => DragonHeadPose.of(pose);

  /// Where the circlet sits for [pose] (rig units) and the turn to draw it
  /// with (radians, clockwise positive), so the falling crown starts exactly
  /// on the head that lost it.
  static ({Offset at, double angle}) crownAt(DragonPose pose) => (
    at: pose.toRig(DragonHeadArt.point(headOf(pose), DragonHeadArt.crownSeat)),
    angle: pose.pitch - pose.head.angle + DragonLayout.headCrownTurn,
  );

  /// The circlet as the defeat knocks it loose, [death] seconds in.
  static ({Offset at, double angle}) crownDrop(
    double death, {
    bool reduced = false,
  }) => crownAt(DragonPose.atDeath(death, reduced: reduced));

  /// The dragon in its current pose. [lookY] turns its eye toward the bird
  /// (-1 up, 1 down); [light] is the backdrop's light.
  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    bool crown = true,
    DragonSkyLight light = DragonSkyLight.neutral,
  }) => paintPose(
    c,
    DragonPose(boss, m, lookY: lookY, light: light),
    crown: crown && (!m.defeated || m.death < .3),
  );

  /// The parts the hide paints as one creature: torso (with the tail), the
  /// near hind leg, the neck and the head.
  static const _hideParts = {'torso', 'hindLeg', 'neck', 'head'};

  /// The dragon in [pose]; see [paint].
  ///
  /// The torso, tail, neck, head and near legs are painted as ONE hide under
  /// one outline (`DragonHide`), at the torso's place in [DragonLayout.zOrder]
  /// (the head with it, before the near wing: nothing of the head reaches the
  /// wing arms, which the head tests hold). [only] limits the drawing to the
  /// named parts and [trace] hears each part as it is painted (both for
  /// tests and previews: the envelope and budget tests use them to name the
  /// part that misbehaves; a game frame passes neither). Painted alone, or
  /// with only some of the hide's parts, a part wears its own full outline as
  /// it did before the hide. [hide] false paints every part that way (the
  /// timing probe compares the two).
  static void paintPose(
    Canvas c,
    DragonPose pose, {
    bool crown = true,
    Set<String>? only,
    void Function(String part)? trace,
    bool hide = true,
    bool warm = true,
  }) {
    final built = DragonKit.shadersBuilt;
    bool on(String part) {
      if (only != null && !only.contains(part)) return false;
      trace?.call(part);
      return true;
    }

    final joined = hide && (only == null || only.containsAll(_hideParts));
    final tone = pose.tone;
    // Firelight scatters in the smoke behind it, more so against dark skies:
    // the body reads as a dark shape in front of its own glow. Two cached
    // radials (flame, and flameGold as the heat rises) instead of a lerped
    // colour, so no shader is built per frame and no saveLayer is needed.
    if (on('bloom')) {
      final heat = math.max(pose.fury, math.max(pose.inhale, pose.blast) * .6);
      final bloom = (pose.light.dark * .5 + heat * .32).clamp(0.0, .7);
      // Below .06 it is invisible and costs the raster a 4-unit disc (the QA
      // review found the bloom the single biggest fill of the rig).
      if (bloom > .06) {
        const at = Offset(1.1, -.5);
        // Bounded to the rig's own layer (the screen ends at x 4.35 and
        // y +-3.74 from the heart: the rest of the disc was raster nobody
        // saw, the QA's "bloom" hot spot), a clip that costs no edge pixel.
        c.save();
        c.clipRect(DragonLayout.layerBounds);
        DragonKit.glow(c, at, _bloomRadius, DragonPalette.flame, bloom * (1 - heat));
        DragonKit.glow(c, at, _bloomRadius, DragonPalette.flameGold, bloom * heat);
        c.restore();
      }
    }
    final body = DragonBodyPose.of(pose);
    final raw = DragonHeadPose.of(pose, crown: crown);
    double q4(double v) => v.isFinite ? (v * 4).round() / 4 : 0;
    final head = DragonHeadPose(
      time: raw.time, at: raw.at, angle: raw.angle, gape: raw.gape,
      glare: raw.glare, look: raw.look, blink: raw.blink, wince: raw.wince,
      throat: q4(raw.throat), smoke: raw.smoke, roar: raw.roar,
      call: q4(raw.call), alert: raw.alert, drag: raw.drag, coil: raw.coil,
      dizzy: raw.dizzy, crown: raw.crown, tone: raw.tone,
    );
    c.save();
    c.translate(pose.bob.dx, pose.bob.dy);
    c.rotate(pose.pitch);
    if (on('farWing')) {
      DragonWingArt.paint(c, DragonWing.farOf(pose), tone, pose.time);
    }
    if (joined) {
      if (on('farLegs+tail')) DragonBodyArt.farLegs(c, body);
      // One creature: torso, tail, hind leg, neck and head, in that order.
      final skin = DragonHide(body, head);
      var painted = false;
      for (final part in const ['torso', 'hindLeg', 'neck', 'head']) {
        if (on(part) && !painted) {
          painted = true;
          skin.paint(c);
        }
      }
      if (on('nearWing')) {
        DragonWingArt.paint(c, DragonWing.nearOf(pose), tone, pose.time);
      }
      if (on('heart')) DragonBodyArt.heart(c, body);
      if (on('foreleg')) skin.paintForeleg(c);
    } else {
      if (on('farLegs+tail')) DragonBodyArt.back(c, body);
      if (on('torso')) DragonBodyArt.torsoPaint(c, body);
      if (on('hindLeg')) DragonBodyArt.front(c, body);
      if (on('neck')) DragonHeadArt.neck(c, head);
      if (on('nearWing')) {
        DragonWingArt.paint(c, DragonWing.nearOf(pose), tone, pose.time);
      }
      if (on('heart')) DragonBodyArt.heart(c, body);
      if (on('head')) DragonHeadArt.head(c, head);
      if (on('foreleg')) DragonBodyArt.foreleg(c, body);
    }
    if (on('smoke')) DragonHeadArt.smoke(c, head);
    c.restore();
    // A frame that built nothing new has time to spare: spend it on a look the
    // fight is about to need.
    if (warm && only == null && !_warming && !pose.defeated) {
      _prewarm(pose, quiet: DragonKit.shadersBuilt == built);
    }
  }

  // ---------------------------------------------------------- tone prewarm --
  //
  // The parts keep their gradients between frames, keyed by the tone
  // (`DragonTone.key`; the tone a part sees is always on the ladder of
  // `DragonTone.snapped`: flash, fury and heat in quarters, darkness in thirds). The first time the fight reaches a tone (each heat step of the
  // inhale, each step of the fury's blend, each darkness step of the sky, the
  // hit's flash) every part builds its set in that one frame: 5 to 30 shaders
  // at once. So each tone the fight reaches queues the ones it is about to
  // reach next (one step of heat, fury, flash and darkness either way), the
  // arrival queues the whole ladders, and a frame that built nothing paints
  // ONE queued tone into a picture nobody sees. Pixels never change (the
  // paints are the same whichever frame builds them); only when they are built.

  /// The bloom's radius, in rig units. The raster review measured it as the
  /// biggest single fill of the rig and asked for 3.6; but it is the lift of
  /// the backdrop around the silhouette on a dark sky (cyberpunk: the ring at
  /// 28.8 with it, 27.4 at radius 4.4 with the ink-invisible share doubling),
  /// so it stays 5.4 where it works and is skipped where it is invisible (below
  /// an alpha of .06: every bright sky at rest).
  static const _bloomRadius = 5.4;

  static bool _warming = false;

  /// Diagnostic only: the shaders the prewarm built (in pictures nobody sees),
  /// so a test can tell a frame's own builds from the prewarm's.
  static int warmedShaders = 0;
  static final Set<int> _known = <int>{};
  static final List<DragonTone> _queue = <DragonTone>[];

  static int _toneKey(DragonTone t) =>
      Object.hash(t.key, t.sky.toARGB32() & 0xfff8f8f8);

  static void _want(DragonTone t) {
    final key = _toneKey(t);
    if (_known.length > 4096) _known.clear();
    if (!_known.add(key) || _queue.length >= 96) return;
    _queue.add(t);
  }

  static void _prewarm(DragonPose pose, {required bool quiet}) {
    final tone = pose.tone;
    if (_known.add(_toneKey(tone))) {
      // A tone the fight has just reached: queue its neighbours (one step of
      // the ladder of darkness, heat and fury either way).
      for (final d in const [-1, 1]) {
        _want(tone.stepped(dark: d));
        _want(tone.stepped(heat: d));
      }
      _want(tone.stepped(fury: 1));
      // A hit's flash climbs from nothing to its peak in two frames, so every
      // calm tone queues the whole flash ladder over itself.
      if (tone.flash == 0) {
        for (var k = 1; k <= DragonTone.flashSteps; k++) {
          _want(tone.stepped(flash: k));
        }
      }
      if (pose.arriving) {
        // The arrival has four seconds to spare: the whole ladders at the
        // sky's own darkness.
        for (var k = 1; k <= DragonTone.furySteps; k++) {
          _want(DragonTone(heat: k / DragonTone.heatSteps, dark: tone.dark, sky: tone.sky));
          _want(DragonTone(fury: k / DragonTone.furySteps, dark: tone.dark, sky: tone.sky));
          _want(DragonTone(flash: k / DragonTone.flashSteps, dark: tone.dark, sky: tone.sky));
        }
      }
    }
    if (!quiet || _queue.isEmpty) return;
    final next = _queue.removeAt(0);
    _warming = true;
    final before = DragonKit.shadersBuilt;
    try {
      final rec = ui.PictureRecorder();
      paintPose(Canvas(rec), pose.withTone(next), warm: false);
      rec.endRecording().dispose();
    } finally {
      _warming = false;
      warmedShaders += DragonKit.shadersBuilt - before;
    }
  }

  /// The circlet on its own, seated at its anchor's origin.
  static void crownPaint(Canvas c) => DragonHeadArt.crown(c);
}
