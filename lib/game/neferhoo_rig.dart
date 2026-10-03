import 'package:flutter/painting.dart';

import 'neferhoo_body_art.dart';
import 'neferhoo_head_art.dart';
import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';
import 'neferhoo_props_art.dart';
import 'neferhoo_wing_art.dart';

Paint _f(Color c, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
Paint _s(Color c, double w, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0))
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;





/// Paints Neferhoo, the Mummy Courier, in rig units ([NeferhooLayout]): the
/// design's `MummyPainter`, ported 1:1 (the draw ORDER is here; the parts
/// live in `neferhoo_head_art.dart`, `neferhoo_body_art.dart`,
/// `neferhoo_wing_art.dart` and `neferhoo_props_art.dart`, each an extension
/// of this painter). Animation is a pure function of the pose. [silhouette] paints every part
/// in one flat [sil] colour (the 120/250 px studies).
class NeferhooPainter {
  /// [pose] with `reduced` set is painted frozen (see [NeferhooPose.frozen]).
  /// [lod] overrides the level of detail the canvas's scale would give (a
  /// picture recorded at identity scale and replayed scaled, as the story
  /// stage does, passes the level of the scale it will be replayed at).
  NeferhooPainter(this.c, NeferhooPose pose, {this.silhouette = false, this.sil = NeferhooPalette.ink, this.layers, int? lod})
    : p = pose.reduced ? pose.frozen() : pose,
      // ignore: prefer_initializing_formals
      _lod = lod;
  final Canvas c;
  final NeferhooPose p;
  final bool silhouette;
  final Color sil;

  /// Test hook: paint only these layers (`nearWing`, `farWing`, `tail`, `body`,
  /// `strap`, `satchel`, `collar`, `legs`, `head`, `cards`, `props`,
  /// `ribbons`); null = everything. Used by the chest-visibility probe.
  final Set<String>? layers;
  bool _on(String layer) => layers == null || layers!.contains(layer);

  /// Level of detail from the canvas scale (px per rig unit): 0 quiet (HUD
  /// medallion, 24 px keepsake), 1 mid, 2 PLAY (the game's 41.4 px/unit, the
  /// story's 43 and the 52 of the pose sheet: big shapes and bold values, no
  /// sub-pixel texture), 3 full (close-ups, the hero: everything).
  late final int lod = _lod ?? NeferhooKit.lodOf(c);
  final int? _lod;
  bool get play => lod <= 2;

  Paint f(Color col, [double a = 1]) => silhouette ? _f(sil) : _f(col, a);
  Paint s(Color col, double w, [double a = 1]) => silhouette ? _s(sil, w) : _s(col, w, a);
  Paint sh(Shader shader) => silhouette ? _f(sil) : (Paint()..shader = shader..isAntiAlias = true);
  bool get fx => !silhouette;

  /// Where the fan of letters is held (the deal point, flicked forward and up
  /// with `sweep`): the near wing's fingertips and the cards share it.
  Offset get fanPoint => NeferhooLayout.dealPoint + Offset(.3 - p.sweep * .3, -.22 - p.sweep * .1);

  /// Fill [path] with [shader] and ink it.
  void part(Path path, Shader shader, {double ink = NeferhooLayout.part}) {
    c.drawPath(path, sh(shader));
    if (fx) c.drawPath(path, _s(NeferhooPalette.ink, ink));
  }

  /// The head alone (crest, skull, nemes, mask, beak), centred on the
  /// origin: the HUD medallion, the name card, the keepsake.
  void paintHeadOnly() {
    c.save();
    c.translate(-NeferhooLayout.head.dx, -NeferhooLayout.head.dy);
    _head();
    c.restore();
  }

  /// The golden mask alone (face plate, beak, eye), centred on the head's
  /// centre: the lost headwear, flying off in the defeat and on the keepsake.
  void paintMaskOnly() {
    c.save();
    c.translate(-NeferhooLayout.head.dx, -NeferhooLayout.head.dy);
    _nemes();
    _mask();
    _diadem();
    c.restore();
  }

  void paint() {
    c.save();
    // hit recoil and the body lean
    c.translate(p.hit * .22, -p.hit * .05);
    c.rotate(p.lean + p.hit * .08);
    if (_on('ribbons')) _ribbons(back: true);
    if (_on('farWing')) _farWing();
    if (_on('tail')) _tail();
    if (_on('legs')) _leg(NeferhooLayout.hipFar, far: true);
    if (_on('legs')) _leg(NeferhooLayout.hipNear, far: false);
    if (_on('body')) _body();
    if (_on('legs')) _legOver(); // the two hip bandages that run belly -> thigh
    if (_on('tail')) _rump(); // the tail's linen coverts lie OVER the body's rump
    if (_on('strap')) _strap();
    // closed, the bag hangs behind the near wing; once it opens (the mail
    // call) the flap and the letters must show, so it is drawn over the wing
    final bagOver = p.satchelOpen > .001;
    if (!bagOver && _on('satchel')) _satchel();
    // the near wing grows from UNDER the collar (the collar's end plate and
    // lotus lie over its root); while it reaches for the letters (reach > .5,
    // edge-on at half reach, so the switch is invisible) it is in front
    final wingOver = p.reach > .5 || p.buff > .5; // (the buff gag: edge-on at .5 too)
    if (!wingOver && _on('nearWing')) _nearWing();
    if (_on('collar')) _collar();
    if (wingOver && _on('nearWing')) _nearWing();
    if (bagOver && _on('satchel')) _satchel();
    if (_on('head')) _head();
    if (_on('cards')) _cards();
    if (_on('props')) {
      _prop();
      _ankh();
    }
    if (_on('ribbons')) _ribbons(back: false);
    if (_on('props')) _stamp();
    c.restore();
  }

  // ---------------------------------------------------------------------------
  // ribbons, wings and the tail: the refined art lives in mummy_wing_art.dart
  // (r3-wings): feather-level wings, the zebra-barred tail, linen streamers

  void _ribbons({required bool back}) => wingArtRibbons(back: back);

  double get _wingAngle {
    // stroke -1 raised high, 0 level, +1 swept down; the throw sweeps it
    // forward (a dealer's flick)
    final a = -.95 + (p.wing + 1) / 2 * 1.45;
    return a - p.sweep * .9;
  }

  void _farWing() => wingArtWing(near: false, angle: _wingAngle + p.sweep * .6); // only a third of a flick
  void _nearWing() => wingArtWing(near: true, angle: _wingAngle);

  void _tail() => wingArtTail();

  /// c2-joints: the rump coverts and the tail wrap, drawn over the body's contour.
  void _rump() => wingArtRump();


  /// c1-legs (mummy_body_art.dart): the wrapped, feathered thigh, the banded shin,
  /// the ankle, the tarsus with its gold anklet and the anisodactyl foot. Painted
  /// BEHIND the body (the near thigh is part of the body's own skin and outline).
  void _leg(Offset hip, {required bool far}) => paintLeg(hip, far: far);

  /// c1-legs: the bandages wound over the near thigh, over the body.
  void _legOver() => paintLegOver();

  // ---------------------------------------------------------------------------
  // the body: a swaddled egg of moon-pale linen, partly unwrapped by fury

  Path _bodyShape() => bodyOutline;

  /// r2-body: the neck and wraps (cached), the unwrap opening and cracks, the
  /// glyph ink (faint on the wraps, a glowing seal when awake), then the light,
  /// the hero outline and the loose linen ends.
  void _body() {
    if (silhouette) {
      c.drawPath(_neckShape(), f(NeferhooPalette.ink));
      c.drawPath(_bodyShape(), f(NeferhooPalette.ink));
      paintBodyLoose();
      return;
    }
    paintBodyBase();
    paintBodyOpening();
    _glyphs();
    paintBodyFinish();
  }

  Path _neckShape() => neckOutline;

  void _glyphs() => paintBodyGlyphs();

  // ---------------------------------------------------------------------------
  // the satchel: the Pharaoh's Post bag, stuffed with dead letters

  void _strap() => paintStraps();

  void _satchel() => paintSatchel();

  // ---------------------------------------------------------------------------
  // the broad collar: turquoise, gold, lapis and carnelian beads

  void _collar() => paintCollar();

  // ---------------------------------------------------------------------------
  // the head: the golden courier mask, nemes, bill, eye and the hoopoe crest
  // live in mummy_head_art.dart (r1-head); these are the rig's entry points.

  void _head() {
    c.save();
    final h = NeferhooLayout.head;
    c.translate(h.dx, h.dy);
    c.rotate(p.headTilt + p.hit * -.12);
    c.translate(-h.dx, -h.dy);
    _crest();
    if (p.mask) {
      headMaskedArt();
    } else {
      _bareHead();
    }
    c.restore();
  }

  /// The striped headcloth: crown and lappet.
  void _nemes() => nemesArt();

  /// The golden face plate with its bill, eye and inlays.
  void _mask() => maskArt();

  /// The gold-and-lapis diadem with the postal insignia.
  void _diadem() => diademArt();

  // ignore: unused_element
  void _beak({required bool gold}) => beakArt(gold: gold);

  // ignore: unused_element
  void _eye() => eyeArt();

  void _crest() => crestArt();

  void _bareHead() => bareHeadArt();

  // ---------------------------------------------------------------------------
  // props: the fan of letters, the golden ankh, a RETURNED stamp

  void _cards() => propCards();

  void _prop() {
    if (p.prop != 'letter') return;
    propLostLetter();
  }

  void _ankh() => propAnkhHover();

  void _stamp() => propStamp();
}
