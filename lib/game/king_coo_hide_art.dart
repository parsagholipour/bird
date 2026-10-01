
import 'package:flutter/painting.dart';

import 'king_coo_body_art.dart';
import 'king_coo_head_art.dart';
import 'king_coo_kit.dart';
import 'king_coo_layout.dart';

/// King Coo's hide: the torso, the chest, the neck, the skull, the near thigh
/// and the tail painted as ONE creature instead of parts laid over each other.
///
/// The joints used to show. Every part had its own ink outline and its own
/// fill, so where the neck met the head, the chest, the thigh and the rump you
/// saw borders, and he read as assembled plush parts (the owner's words about
/// the dragon: "the part that connects the head to the body has a border and
/// it feels like they're separate"). Here the parts share ONE outline, ONE
/// skin and ONE light, in the two-pass method of the Ember Dragon's hide:
///
///  * **Outline.** The trunk (torso, chest, neck, skull, thigh) is laid in one
///    path (they all wind the same way, so it fills and clips as their union)
///    and stroked ONCE in ink, thick, BEFORE anything is filled; the skin is
///    painted over it afterwards and buries every stroke that lies inside the
///    union, so only the outer edge keeps its ink. The tail's feathers, a
///    path of their own (a finer weight: the tail is a secondary mass), are
///    stroked the same way before their skins. No `Path.combine` is ever run:
///    the painter's order does the merge. The strokes are shifted toward the
///    shade side (lower left, away from the moon), so the line is full weight
///    there and thinner on the lit side.
///  * **Skin and light.** One plumage gradient in figure space for the torso
///    and thigh, the head's own fills (`KingCooHeadArt.neckFill`, `skullFill`:
///    the iridescent gorget and the lilac skull) over its neck and skull, so
///    neighbours match wherever they meet. The moon's crescent and the
///    windows' bounce are made by clipping the ONE union again, carried toward
///    the shade and then toward the light (what each nested clip leaves
///    uncovered along the edges is the crescent): shifted copies of the same
///    union, so the light follows the TRUE outer silhouette across every joint
///    and never shows an inner border. Fury's flush and the hit's bleach are
///    washed over the plumage skin.
///  * **Detail.** Feather rows, the coverts, the chest's scallops and the
///    head's shingles and scallops are clipped to the union and run on across
///    the joints: the chest's scalloped rim overlaps the neck's iridescence,
///    the rump's coverts overlap the tail's roots, the thigh is cut from the
///    belly's own gradient. A pass of hard white glints sits over all of it
///    (the bosses are glossy).
///  * **Limbs.** The near leg's shank and foot are painted first, under the
///    skin; the thigh's tuft (a part of the skin) and its hem ink cover the
///    shank's top, so the coral comes out from under the feathers.
///
/// What the head must provide (K2's one-piece skin API): `neckOf(h).path`,
/// `ruffAt(h)` and `skullAt(h)` (clockwise), `under` (behind the skin),
/// `neckFill`, `neckDetails`, `ruffFill`, `skullFill`, `skullDetails` (on it),
/// and `face` (after it: the rig calls it, without the cap and whistle, which
/// have their own z-order places). The ruff, the collar over the joint, is in
/// the union too (K8): it was the one outline left between head and body, and
/// is painted where it sits in the z-order, after the chest and before the
/// skull.
///
/// Built once a frame from the body and (when he has one) the head pose. With
/// no head the hide paints the body's own joints only (the standalone tests).
final class KingCooHide {
  /// [ruff] false leaves the collar out of the skin (a rig asked to paint
  /// everything but the ruff).
  KingCooHide(KingCooBodyPose body, [KingCooHeadPose? head, bool ruff = true])
    : this._(body.finite, head, ruff);

  KingCooHide._(this.body, this.head, bool ruff)
    : chestRadius = body.chestRadius,
      tail = KingCooBodyArt.tailUnion(body) {
    final taut = body.taut;
    chest = KingCooBodyArt.chestPath(chestRadius - _inkMid, taut);
    final trunkPath = Path()
      ..addPath(KingCooBodyArt.hideTorso, Offset.zero)
      ..addPath(chest, Offset.zero)
      ..addPath(KingCooBodyArt.nearThigh, Offset.zero);
    final h = head;
    if (h != null) {
      neckGeometry = KingCooHeadArt.neckOf(h);
      neck = neckGeometry!.path;
      skull = KingCooHeadArt.skullAt(h);
      trunkPath
        ..addPath(neck!, Offset.zero)
        ..addPath(skull!, Offset.zero);
    }
    // The trunk's ink is the hero stroke; the ruff is a secondary mass (the
    // contract's major weight), outlined on its own before any skin like the
    // tail, but filled and clipped with the rest.
    inkTrunk = trunkPath;
    if (h != null && ruff) {
      this.ruff = KingCooHeadArt.ruffAt(h);
      trunk = Path()
        ..addPath(trunkPath, Offset.zero)
        ..addPath(this.ruff!, Offset.zero);
    } else {
      trunk = trunkPath;
    }
  }

  final KingCooBodyPose body;
  final KingCooHeadPose? head;

  /// The chest's ink centre line (the hit circle when puffed).
  final double chestRadius;

  /// The chest's skin path (the ink's outer half reaches the centre line
  /// plus half a stroke), the four tail feathers laid as one path, and the
  /// neck and skull when there is a head.
  late final Path chest;
  final Path tail;
  Path? neck, skull, ruff;
  KingCooNeck? neckGeometry;

  /// The torso, chest, neck, ruff, skull and thigh laid together: filled and
  /// clipped, it is their union. [inkTrunk] is the same without the ruff (the
  /// ruff has its own, finer outline).
  late final Path trunk, inkTrunk;

  // --------------------------------------------------------------- ink --

  /// The ink stroke is centred on the trunk's edge but the skin covers its
  /// inner half, so the visible line is HALF this wide (hero .085), then
  /// shifted toward the lower left (the shade side): ~.063 on the lit edges to
  /// ~.107 on the shade ones. The tail's is a notch finer (.065).
  static const _inkHalf = .085, _tailInkHalf = .065, _ruffInkHalf = .05;

  /// The widths of the outline strokes (the tests look for exactly these).
  static const inkWidth = _inkHalf * 2, tailInkWidth = _tailInkHalf * 2;
  static const ruffInkWidth = _ruffInkHalf * 2;

  /// Half the visible ink: the chest's skin is inset by this so the ink's
  /// middle is the hit circle.
  static const _inkMid = _inkHalf / 2;
  static const _inkShift = Offset(-.014, .018);
  static final Paint _inkStroke = KingCooKit.line(KingCooPalette.ink, _inkHalf * 2);
  static final Paint _tailInk = KingCooKit.line(KingCooPalette.ink, _tailInkHalf * 2);
  static final Paint _ruffInk = KingCooKit.line(KingCooPalette.ink, _ruffInkHalf * 2);

  /// The figure's box with a margin: the skin fills no more than it must.
  static const _area = Rect.fromLTRB(-2.7, -2.9, 3.1, 1.7);

  // -------------------------------------------------------------- paint --

  /// Everything the hide paints: the near leg and what lies behind the skin,
  /// the outlines, the tail's feathers, the trunk's skin with its light and
  /// detail, the chest and its badge, and the glints.
  void paint(Canvas c) {
    final tone = body.tone;
    KingCooBodyArt.legUnder(c, body, far: false);
    final head = this.head;
    if (head != null) KingCooHeadArt.under(c, head);

    // One outline per mass, before any skin.
    c
      ..save()
      ..translate(_inkShift.dx, _inkShift.dy)
      ..drawPath(inkTrunk, _inkStroke)
      ..drawPath(tail, _tailInk)
      ..restore();
    // The collar's line is finer and does not take the shade-side shift: it
    // sits under the beak, where the throat notch must stay open at 120 px.
    if (ruff != null) c.drawPath(ruff!, _ruffInk);

    KingCooBodyArt.tailSkin(c, body, tail);

    // The skin and its light, then the detail: all inside the union. The
    // light is laid as the dragon's hide lays it: the crescent colours are
    // filled first (the sky's on the whole trunk, the windows' on all but its
    // upper right), then the trunk is clipped again, carried toward the shade
    // side, then toward the light: what each nested clip leaves uncovered along
    // the edges is the crescent. Because they are shifted copies of the ONE
    // union they follow the true outer silhouette across every joint and never
    // show an inner border.
    c.save();
    c.clipPath(trunk);
    c.drawRect(_area, KingCooKit.fill(_skyCrescent(tone)));
    c.save();
    c.translate(_skyShift.dx, _skyShift.dy);
    c.clipPath(trunk, doAntiAlias: false);
    c.translate(-_skyShift.dx, -_skyShift.dy);
    c.drawRect(_area, KingCooKit.fill(_warmCrescent(tone)));
    c.save();
    c.translate(_warmShift.dx, _warmShift.dy);
    c.clipPath(trunk, doAntiAlias: false);
    c.translate(-_warmShift.dx, -_warmShift.dy);

    c.drawRect(_area, KingCooBodyArt.skinPaint);
    // The plumage's flush and bleach go on the skin itself, before the head's
    // own fills (the gorget and the skull bring their own tone).
    _washRect(c, tone);
    final h = head;
    if (h != null) {
      KingCooHeadArt.neckFill(c, h, geometry: neckGeometry);
      KingCooHeadArt.neckDetails(c, h, geometry: neckGeometry);
    }
    KingCooBodyArt.torsoDetail(c, body);
    // The globe's shadow on the body behind it: a translucent copy of it,
    // shifted to the lower right (the moon is upper right), and its edge.
    c
      ..save()
      ..translate(.07, .06)
      ..drawPath(
        chest,
        KingCooKit.fill(KingCooPalette.featherCore, .30 * (1 - tone.washAlpha)),
      )
      ..restore();
    KingCooBodyArt.chestSkin(c, body, chestRadius - _inkMid, rim: false);
    c.drawPath(
      chest,
      KingCooKit.line(KingCooPalette.inkWarm, KingCooLayout.inkPart, .8),
    );
    // The collar over the chest's shoulder, then the skull over the collar:
    // the z-order (chest, ruff, head), now with no ink between them.
    if (h != null) {
      if (ruff != null) KingCooHeadArt.ruffFill(c, h, path: ruff);
      KingCooHeadArt.skullFill(c, h);
      KingCooHeadArt.skullDetails(c, h);
    }
    _glints(c, tone);
    c.restore();
    c.restore();
    c.restore();
    // Outside the skin's clip: the feathers standing up as the chest swells.
    KingCooBodyArt.chestRuffle(c, body);
    KingCooBodyArt.badge(c, body);
    KingCooBodyArt.doubleMark(c, body);
  }

  /// The fury's flush and the hit's bleach over the whole trunk: two fills.
  static void _washRect(Canvas c, KingCooTone tone) {
    if (tone.furyAlpha > 0) {
      c.drawRect(_area, KingCooKit.fill(KingCooPalette.furyTint, tone.furyAlpha));
    }
    if (tone.washAlpha > 0) {
      c.drawRect(_area, KingCooKit.fill(KingCooPalette.bleach, tone.washAlpha));
    }
  }

  // ------------------------------------------------------------ glints --

  /// Hard white specular glints on the torso, one op: a pill on the rump's
  /// curve and a dot on the thigh's tuft. (The globe's and the face's are the
  /// chest's and the head's own.) They fade under the hit's bleach.
  static final Path _torsoGlints = Path()
    ..moveTo(2.15, -.03)
    ..lineTo(2.24, .10)
    ..moveTo(.45, 1.02)
    ..lineTo(.451, 1.02);

  void _glints(Canvas c, KingCooTone tone) {
    final a = (.85 * (1 - tone.washAlpha * 1.6)).clamp(0.0, .85);
    if (a <= .02) return;
    c.drawPath(_torsoGlints, KingCooKit.line(KingCooPalette.white, .056, a));
  }

  /// How far the nested clips are carried: the first toward the lower left
  /// (leaving the moon's crescent along the upper-right edges), the second
  /// toward the upper right (leaving the windows' crescent along the lower-
  /// left ones).
  static const _skyShift = Offset(-.036, .046), _warmShift = Offset(.022, -.050);

  /// The crescents' flat colours: this sky's bounce over the mid plumage, the
  /// windows' amber over the deep one.
  static Color _skyCrescent(KingCooTone t) => Color.lerp(
    t.lit(KingCooPalette.feather),
    t.lit(t.sky),
    (t.skyRim * .9).clamp(0.0, 1.0),
  )!;
  static Color _warmCrescent(KingCooTone t) => Color.lerp(
    t.lit(KingCooPalette.featherDeep),
    t.lit(KingCooPalette.rimWarm),
    (t.warmRim * .85).clamp(0.0, 1.0),
  )!;
}
