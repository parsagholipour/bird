import 'dart:ui';

import '../domain/game_rules.dart';

/// Neferhoo's rig layout: the anchors, the ink weights and the reach of the
/// figure, in rig units (1 = the boss hit radius, [SkyBoss.radius] = .115 of
/// the screen height, 41.4 px at 360; origin the hit circle's centre, the
/// wrapped chest; facing left, +y down). Ported 1:1 from the approved design
/// (`egypt-ws/iter5/test/egypt/mummy_rig.dart`, the `Mu` anchors); every
/// name is the design's.
abstract final class NeferhooLayout {
  // ---------------------------------------------------------- ink weights --

  /// Line weights (u): hero outline, major, part, detail.
  static const hero = .10, major = .075, part = .05, detail = .035;

  // ------------------------------------------------------------- anchors --

  /// The hit circle's centre, r 1: the rules' circle (`SkyBoss.radius`).
  static const chest = Offset(0, 0);
  static const head = Offset(-1.02, -1.30);
  static const headR = .74;
  static const eye = Offset(-1.27, -1.40);
  static const beakBase = Offset(-1.66, -1.30);
  static const beakTip = Offset(-3.1, -0.58);
  static const crestRoot = Offset(-0.95, -1.98);
  static const shoulder = Offset(.28, -.62);
  static const farShoulder = Offset(.62, -.80);
  static const tailRoot = Offset(1.30, .18);

  /// The satchel's centre (f2-body: lifted so its bottom clears the far thigh,
  /// moved right so the hit circle stays as visible as before).
  static const satchel = Offset(.75, .54);

  /// The postmark (the printed target a returned letter lands on): the bare
  /// lower-left of the chest, clear of the collar, the bag and the wing.
  static const postmark = Offset(-.55, .36);
  static const postmarkR = .38;

  /// Where the fan of letters is held.
  static const dealPoint = Offset(-1.55, .22);

  /// Where the ankh hovers over his far shoulder before the throw (and where
  /// the flying ankh leaves from: `NeferhooTimeline.ankhEase`).
  static const ankhHover = Offset(.55, -2.75);

  /// Where each thigh joins the belly (the trouser's centre, on the belly's
  /// underside): the near one is part of the body's skin, the far one hangs
  /// behind it. Both legs are painted BEHIND the body so the satchel hangs in
  /// front of them.
  static const hipNear = Offset(-.30, .94), hipFar = Offset(-.05, .96);

  // --------------------------------------------------------------- reach --

  /// Everything the rig can reach in any combat pose (design §5.2, the
  /// guaranteed envelope). The design measured -3.16 / -3.34 / 4.22 / 2.12
  /// over its timeline; the real fight adds a returned letter's full recoil
  /// on fury's raised crest (top -3.8) and the stamp, so the top is -3.85.
  /// Kept by `neferhoo_envelope_test` (every 1/10 s of calm and fury cycles,
  /// 560-960 px, hits, the roar, Reduced Motion).
  static const envelope = Rect.fromLTRB(-3.2, -3.85, 4.4, 2.25);

  /// The bounds of the one compositing layer the arrival and defeat may use
  /// (the envelope with room for the hit recoil and the arrival's swell).
  static const layerBounds = Rect.fromLTRB(-3.8, -4.2, 5.0, 2.6);

  /// Rig units per screen height.
  static const perScreen = 1 / SkyBoss.radius;
}
