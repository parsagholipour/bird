import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';
import 'neferhoo_fight_art.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';
import 'neferhoo_rig.dart';

/// Neferhoo, the Mummy Courier, in flight: a hoopoe courier sealed in the
/// Great Pyramid with the one lost letter, wound in moon-pale linen under a
/// burnished golden courier mask, a striped nemes, a cinnamon-orange crest,
/// a wesekh collar and a carnelian satchel of dead letters.
///
/// Authored in rig units around the hit circle, which is his wrapped chest
/// (1 = [SkyBoss.radius]), facing left toward the bird; every combat pose
/// stays inside [envelope]. The encounter places him: translate to
/// (`boss.x`, `boss.y`) x the screen height, scale by height x
/// [SkyBoss.radius], then [paint].
///
/// Ported 1:1 from the approved design (`egypt-ws/iter5/test/egypt/`,
/// report `egypt-ws/reports/09-neferhoo-iteration.md`): the palette and
/// helpers (`neferhoo_kit.dart`), the anchors (`neferhoo_layout.dart`), the
/// channels (`neferhoo_pose.dart`), the painter and its draw order
/// (`neferhoo_rig.dart`), the parts (`neferhoo_head_art.dart`,
/// `neferhoo_body_art.dart`, `neferhoo_wing_art.dart`,
/// `neferhoo_props_art.dart`) and the fight's eased pose function
/// (`neferhoo_timeline.dart`), driven by the real fight state. Combat draws
/// no `saveLayer` and no blur; static art is cached once (paths, gradients,
/// pictures); everything is a pure function of the boss and [BossMotion].
abstract final class NeferhooBossRig {
  /// Everything the rig can reach in any combat pose, in rig units.
  static const envelope = NeferhooLayout.envelope;

  /// The bounds of the one compositing layer the arrival and defeat may use.
  static const layerBounds = NeferhooLayout.layerBounds;

  /// Paints him in rig units at the canvas origin. [lookY] is where the bird
  /// is relative to him (screen heights x 3, as the other rigs take it);
  /// [beaten] paints the kindly old hoopoe he is once his mask is off (the
  /// design's BEATEN pose).
  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    double lookY = 0,
    bool beaten = false,
  }) => paintPose(
    c,
    beaten ? beatenPose(boss.age - (boss.defeatedAt ?? boss.age), reduced: m.reducedMotion) : NeferhooPose.fight(boss, m, lookY: lookY),
  );

  /// Paints [pose]; [only] limits the drawing to the painter's named layers
  /// (`ribbons`, `farWing`, `tail`, `legs`, `body`, `strap`, `satchel`,
  /// `nearWing`, `collar`, `head`, `cards`, `props`), for tests.
  static void paintPose(Canvas c, NeferhooPose pose, {Set<String>? only}) =>
      NeferhooPainter(c, pose, layers: only).paint();

  /// The design's BEATEN key pose (a kindly old hoopoe: mask off, his
  /// spectacles on, the wraps loose, a smile), [seconds] into it.
  static NeferhooPose beatenPose(double seconds, {bool reduced = false}) => NeferhooPose(
    crest: .22,
    wing: .5,
    mask: false,
    specs: true,
    sleepy: .35,
    unwrap: .6,
    smile: .8,
    phase: seconds.isFinite ? seconds : 0,
    reduced: reduced,
  );

  /// Builds every cached path, gradient and picture the fight will ask for
  /// (each level of detail, calm and fury, the fan, the hovering ankh, the
  /// stamp, the letters, the telegraphs) into a picture nobody sees, so no
  /// frame of the fight records one. Call it once as the arrival begins; it
  /// is pure and safe to call again.
  static void prewarm() {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final poses = [
      NeferhooPose(crest: .4, wing: .2, phase: .3),
      NeferhooPose(crest: .42, wing: .45, cards: 2, satchelOpen: 1, reach: 1, wingRate: 0, sweep: .5, phase: .5, glint: .5),
      NeferhooPose(crest: 1, wing: -.9, wingRate: 0, ankh: 1, ankhSpin: 2, glow: .9, phase: .7),
      NeferhooPose(crest: .6, wing: -.8, hit: 1, stamp: 1, phase: .9, buff: 1, ringGlint: .5),
      NeferhooPose(crest: .6, wing: .45, fury: 1, unwrap: .8, cracked: 1, glow: 1, cards: 2, satchelOpen: 1, reach: 1, wingRate: 0, sweep: .6, phase: 1.1),
    ];
    for (final unit in [41.4, 50.0, 64.0]) {
      for (final p in poses) {
        c.save();
        c.scale(unit);
        NeferhooPainter(c, p).paint();
        c.restore();
      }
    }
    NeferhooFightArt.prewarm(c);
    recorder.endRecording().dispose();
  }
}
