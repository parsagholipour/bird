// Neferhoo's props and attack effects, refined (the r4-props pass): the
// papyrus letters (ammo and the player's weapon), their returned form and the
// payoff burst, the burnished-gold ankh, the telegraphs (mail lane, ankh loop,
// hint tags), the hand fan of letters, the lost letter and the postmark.
//
// References behind the look (see HANDOFF.md): ancient letters were a papyrus
// sheet folded to a thin rectangle, tied with a papyrus-pith string whose knot
// was covered by a stamped clay lump, the addressee written near the seal;
// Egyptian goldwork is cloisonne (gold cells filled with lapis, turquoise and
// carnelian) with a chased border; modern postal grammar (a perforated stamp,
// wavy cancel lines, a round date postmark, airmail's red/white/blue border,
// a boxed RETURN TO SENDER label) is what a child reads as "mail" at once.
//
// House technique: one skin and one ink outline per object, static art
// recorded ONCE into a cached [ui.Picture] (a drawPicture is one call), every
// motion a pure function of its arguments (no clocks, no randomness), no
// saveLayer in combat (a bounded one only when a caller fades a letter),
// no blur. Letters are drawn in "pixels at 360" and scaled by h / 360, so the
// envelope body is always exactly the rules rectangle (.090 x .064 h).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../ui/match_hud.dart' show MatchLayout;
import 'neferhoo_fx.dart';
import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_rig.dart';


// ---------------------------------------------------------------------------
// shared helpers

Paint _fp(Color c, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
Paint _sp(Color c, double w, [double a = 1, StrokeCap cap = StrokeCap.round]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0))
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = cap
  ..strokeJoin = StrokeJoin.round;
Paint _gp(ui.Shader s) => Paint()
  ..isAntiAlias = true
  ..shader = s;
List<double>? _even(int n) => n <= 2 ? null : [for (var i = 0; i < n; i++) i / (n - 1)];
ui.Shader _lg(Offset a, Offset b, List<Color> cs, [List<double>? st]) => ui.Gradient.linear(a, b, cs, st ?? _even(cs.length));
ui.Shader _rg(Offset c, double r, List<Color> cs, [List<double>? st]) => ui.Gradient.radial(c, r, cs, st ?? _even(cs.length));

ui.Picture _record(String name, void Function(Canvas) draw) => NeferhooKit.record(draw);

/// Neferhoo's props and attack effects, the public entry points (the design's
/// `paint*` functions of `mummy_props_art.dart`, ported 1:1). Letters and the
/// flying ankh take [h], the screen's height in px: they are drawn in "pixels
/// at 360" scaled by h / 360, so a letter's body is exactly the rules'
/// rectangle (`Neferhoo.letterHalfWidth` x `letterHalfHeight`) and the ankh's
/// solid body 2.3 x the rules' radius. Rig-unit props (the fan of letters,
/// the hovering ankh, the stamp, the lost letter in his wing) are painted by
/// `NeferhooPainter` (the extension `NeferhooPropsPaint`).
abstract final class NeferhooPropsArt {
  /// One envelope centred at [o] (px) on a screen [h] px high. [returned]
  /// 0..1 slams the RETURN TO SENDER label on and gilds it, [fury] is the
  /// express (turquoise-edged) letter, [flutter] > 0 marks it in flight;
  /// [alpha] < 1 fades it through one small bounded layer (cinematics only);
  /// [rock] scales its rocking (1 = the design's).
  static const letter = _paintLetter;

  /// The golden ankh centred at [o], [size] tall in the canvas's units, spun
  /// by [spin] radians (burnished gold, cloisonne inlay, chased border).
  static const ankh = _paintAnkh;

  /// The spinning golden ankh in flight at [p] (screen fractions of [h]): a
  /// tapered gold ribbon along its [trail] (screen fractions), a halo.
  static const flyingAnkh = _paintFlyingAnkh;

  /// The MAIL CALL telegraph: the address line the stream flies, locked at
  /// [laneY], from the hand at [fromX] to the screen's left edge (screen
  /// fractions); [t] 0..1 through the wind-up, [clock] marches the chevrons.
  static const mailLane = _paintMailLane;

  /// The ANKH telegraph: the whole loop (out along [yA], the turn behind the
  /// bird, back along `Neferhoo.backLane(yA)`), the crossing bands numbered.
  static const ankhTelegraph = _paintAnkhTelegraph;

  /// A returned letter homing back into his chest, from [from] to [to]
  /// (screen fractions), [k] 0..1 of its flight.
  static const returnedLetter = _paintReturnedLetter;

  /// The burst where a returned letter lands at [at] (px), [t] 0..1.
  static const returnBurst = _paintReturnBurst;

  /// The lost letter on its own, [width] px across (the defeat, the
  /// keepsake): a faint gold glow, drifting motes.
  static const lostLetter = _paintLostLetter;

  /// A hint tag (a lapis-and-gold plaque with an icon badge) at [at] (px).
  static const tag = _paintTag;

  /// The hint pill under his health strip (the design's `mummyHud(tag:)`:
  /// a lapis capsule in a gold rim, the words in pale gold), centred on
  /// [centre] (px; its top edge at [centre].dy - half its height) on a
  /// screen [h] high, at [alpha]. Returns its size.
  static Size hintPill(Canvas c, Offset centre, String words, double h, {double alpha = 1}) {
    final u = h / 360;
    final size = hintPillSize(words, h);
    if (alpha <= 0) return size;
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: centre, width: size.width, height: size.height), Radius.circular(size.height / 2));
    c.drawRRect(r.shift(Offset(0, 1.2 * u)), _fp(NeferhooPalette.ink, .3 * alpha));
    c.drawRRect(r, _fp(NeferhooPalette.lapisDeep, .94 * alpha));
    c.drawRRect(r, _sp(NeferhooPalette.gold, 1.2 * u, alpha));
    c.drawRRect(r.deflate(2 * u), _sp(NeferhooPalette.goldDeep, .5 * u, .6 * alpha));
    _text(c, words, Offset(centre.dx, centre.dy - 5.6 * u), 9 * u, NeferhooPalette.goldHi.withValues(alpha: alpha), center: true, spacing: .6 * u);
    return size;
  }

  /// The hint pill's size for [words] on a screen [h] high: the words at the
  /// design's 9 px (at 360) plus 9 px each side, 17 px high.
  static Size hintPillSize(String words, double h) {
    final u = h / 360;
    final key = '$words|${u.toStringAsFixed(4)}';
    final w = _pillWidths[key] ??= () {
      final tp = TextPainter(
        text: TextSpan(
          text: words,
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 9 * u, fontWeight: FontWeight.w600, letterSpacing: .6 * u),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = tp.width;
      tp.dispose();
      return width;
    }();
    return Size(w + 18 * u, 17 * u);
  }

  static final _pillWidths = <String, double>{};

  /// Where the lane's or the loop's tag ([title], [sub]) goes for a band
  /// [top]..[bottom] (px) on a screen of [size], and how big it is: clear
  /// of the band and of the HUD's hearts plate ([neferhooHudPlate]).
  static Rect tagRect(String title, String sub, double top, double bottom, Size size, {String? icon, List<Rect> clear = const []}) {
    final (_, s) = _TagArt.get(title, sub, NeferhooPalette.gold, icon);
    final tag = s * (size.height / 360);
    return _tagAt(top, bottom, size, tag, clear) & tag;
  }
}

/// Text in the design's two faces (Fredoka titles, Nunito body), top-left
/// at [at]; the laid-out painters are cached (a frame lays out nothing new).
Size _text(
  Canvas c,
  String s,
  Offset at,
  double size,
  Color color, {
  String font = 'Fredoka',
  FontWeight weight = FontWeight.w600,
  double spacing = 0,
  bool center = false,
  Color? outline,
  double outlineWidth = 0,
}) {
  // (alpha on a 1/32 ladder: a fade lays out at most 32 painters, then none)
  Color q(Color k) => k.withValues(alpha: (k.a * 32).round() / 32);
  color = q(color);
  if (outline != null) outline = q(outline);
  TextPainter tp(Paint? fg) {
    final key = '$s|$size|$font|${weight.value}|$spacing|${fg == null ? color.toARGB32() : '${fg.color.toARGB32()}/${fg.strokeWidth}'}';
    final hit = _textCache.remove(key);
    if (hit != null) {
      _textCache[key] = hit;
      return hit;
    }
    final made = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: font,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: fg == null ? color : null,
          foreground: fg,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _textCache[key] = made;
    if (_textCache.length > 48) _textCache.remove(_textCache.keys.first)?.dispose();
    return made;
  }

  final main = tp(null);
  var o = at;
  if (center) o = at - Offset(main.width / 2, 0);
  if (outline != null && outlineWidth > 0) {
    tp(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..strokeJoin = StrokeJoin.round
          ..color = outline)
        .paint(c, o);
  }
  main.paint(c, o);
  return Size(main.width, main.height);
}

final _textCache = <String, TextPainter>{};

/// The props' extra colours (the shared palette is `NeferhooPalette`).
abstract final class NeferhooPropInk {
  static const ochre = Color(0xff7a5a2a); // address glyphs
  static const tan = Color(0xffc9a45e); // fibre seams, dust
  static const cord = Color(0xffb9803f), cordDark = Color(0xff6f4620), cordLit = Color(0xffe3b26a);
  static const paper = NeferhooPalette.linenHi; // stamp paper, label plate
  static const stampRed = NeferhooPalette.stampInk; // the RETURN TO SENDER ink
  static const waxLit = NeferhooPalette.carnLit;
  static const agedLit = Color(0xffe8d094), aged = Color(0xffd2ad62), agedDark = Color(0xffa07a3a);
  static const lapisCord = Color(0xff4568c9);
}

/// 0..1 deterministic hash of an integer (so confetti and dust are seeded,
/// never random).
double _h01(int i) {
  var x = (i * 2654435761) & 0x7fffffff;
  x = ((x >> 13) ^ x) * 1274126177 & 0x7fffffff;
  return ((x >> 7) & 0xffff) / 65535.0;
}

// ---------------------------------------------------------------------------
// a tiny monoline block-letter font (no TextPainter, no font dependency):
// glyphs live in a 3 x 5 cell, y down

abstract final class _Font {
  static const _g = <String, List<List<double>>>{
    'R': [
      [0, 5, 0, 0, 2.1, 0, 3, .9, 3, 1.7, 2.1, 2.6, 0, 2.6],
      [1.7, 2.6, 3, 5],
    ],
    'E': [
      [3, 0, 0, 0, 0, 5, 3, 5],
      [0, 2.5, 2.3, 2.5],
    ],
    'T': [
      [0, 0, 3, 0],
      [1.5, 0, 1.5, 5],
    ],
    'U': [
      [0, 0, 0, 3.9, 1, 5, 2, 5, 3, 3.9, 3, 0],
    ],
    'N': [
      [0, 5, 0, 0, 3, 5, 3, 0],
    ],
    'O': [
      [1, 0, 2, 0, 3, 1, 3, 4, 2, 5, 1, 5, 0, 4, 0, 1, 1, 0],
    ],
    'S': [
      [3, .9, 2.2, 0, .9, 0, 0, .9, 0, 1.7, .9, 2.5, 2.1, 2.5, 3, 3.3, 3, 4.1, 2.1, 5, .8, 5, 0, 4.1],
    ],
    'D': [
      [0, 0, 0, 5, 1.9, 5, 3, 3.9, 3, 1.1, 1.9, 0, 0, 0],
    ],
    '1': [
      [.5, 1.3, 1.7, 0, 1.7, 5],
      [.4, 5, 3, 5],
    ],
    '2': [
      [0, 1, .9, 0, 2.1, 0, 3, .9, 3, 1.9, 0, 5, 3, 5],
    ],
  };
  static const adv = 4.3, space = 2.6;
  static final _cache = <String, Path>{};

  /// The strokes of [s] in cell units (x from 0, glyph height 5).
  static Path path(String s) => _cache.putIfAbsent(s, () {
    final p = Path();
    var x = 0.0;
    for (final ch in s.split('')) {
      if (ch == ' ') {
        x += space;
        continue;
      }
      for (final stroke in _g[ch] ?? const <List<double>>[]) {
        p.moveTo(x + stroke[0], stroke[1]);
        for (var i = 2; i < stroke.length; i += 2) {
          p.lineTo(x + stroke[i], stroke[i + 1]);
        }
      }
      x += adv;
    }
    return p;
  });

  static double width(String s) {
    var x = 0.0;
    for (final ch in s.split('')) {
      x += ch == ' ' ? space : adv;
    }
    return x - 1.3;
  }

  /// Draws [s] centred on [o], glyph height [h] px.
  static void draw(Canvas c, String s, Offset o, double h, Color col, double w, [double a = 1]) {
    final k = h / 5;
    c.save();
    c.translate(o.dx - width(s) * k / 2, o.dy - h / 2);
    c.scale(k);
    c.drawPath(path(s), _sp(col, w / k, a));
    c.restore();
  }
}

// ---------------------------------------------------------------------------
// the wax seal (clay lump of the ancient letters, a red wax disc to a child)

abstract final class _Wax {
  static final blob = () {
    final pts = <Offset>[];
    for (var i = 0; i < 40; i++) {
      final a = i / 40 * math.pi * 2;
      final r = 1 + .075 * math.sin(a * 8 + .5) + .04 * math.sin(a * 3 + 1.2);
      pts.add(Offset(math.cos(a), math.sin(a)) * r);
    }
    return NeferhooKit.smoothPath(pts);
  }();

  /// The hoopoe sigil, facing left, in a radius-1 disc: a round head, a long
  /// curved beak and a three-feather crest swept up and back.
  static final sigil = () {
    final p = Path()..addOval(Rect.fromCircle(center: const Offset(.12, .2), radius: .34));
    // beak: a tapered curved wedge
    p.moveTo(-.16, .02);
    p.quadraticBezierTo(-.62, .0, -.9, .5);
    p.quadraticBezierTo(-.56, .26, -.14, .36);
    p.close();
    // crest: three pointed feathers
    for (final (tx, ty, bx) in const [(-.04, -.66, -.06), (.3, -.7, .16), (.62, -.5, .32)]) {
      p.moveTo(bx - .09, -.04);
      p.lineTo(tx, ty);
      p.lineTo(bx + .13, -.04);
      p.close();
    }
    return p;
  }();

  /// A scalloped wax disc of radius [r] at [o] (px), lit from the upper right.
  static void draw(Canvas c, Offset o, double r, {bool gold = false, double ink = .9}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(r);
    final lit = gold ? NeferhooPalette.goldHi : NeferhooPropInk.waxLit;
    final mid = gold ? NeferhooPalette.gold : NeferhooPalette.seal;
    final dark = gold ? NeferhooPalette.goldShade : NeferhooPalette.carnShade;
    final deep = gold ? NeferhooPalette.goldDeep : NeferhooPalette.carnDeep;
    c.drawPath(blob, _gp(_rg(const Offset(.34, -.38), 1.5, [lit, mid, dark, deep], const [0, .32, .74, 1])));
    c.drawPath(blob, _sp(NeferhooPalette.ink, ink / r));
    // the pressed rim and the stamped hoopoe (shadowed on its lit side)
    c.drawCircle(Offset.zero, .72, _sp(deep, .09, .5));
    c.drawArc(Rect.fromCircle(center: Offset.zero, radius: .72), -1.15, 1.0, false, _sp(lit, .1, .85));
    c.drawPath(sigil, _fp(deep, .92));
    c.drawCircle(const Offset(.0, .15), .07, _fp(lit));
    c.restore();
  }
}

// ---------------------------------------------------------------------------
// THE LETTER (ammo and the player's weapon)

const _lw = Neferhoo.letterHalfWidth * 2 * 360, _lh = Neferhoo.letterHalfHeight * 2 * 360; // 32.4 x 23.04 px at 360
const _lhw = _lw / 2, _lhh = _lh / 2;
const _tipY = 1.7; // the flap's tip, where the cord and the seal sit

abstract final class _LetterArt {
  // the ink line is 1.5 px: its outer edge must sit on the rules rectangle
  static const fitX = (_lhw - .72) / _lhw, fitY = (_lhh - .72) / _lhh;
  static final rect = Rect.fromLTRB(-_lhw, -_lhh, _lhw, _lhh);
  static final rr = RRect.fromRectAndRadius(rect, const Radius.circular(1.6));
  static final flap = Path()
    ..moveTo(-_lhw, -_lhh)
    ..lineTo(0, _tipY)
    ..lineTo(_lhw, -_lhh)
    ..close();
  static final flapEdge = Path()
    ..moveTo(-_lhw, -_lhh)
    ..lineTo(0, _tipY)
    ..lineTo(_lhw, -_lhh);
  static final flapEdgeRight = Path()
    ..moveTo(0, _tipY)
    ..lineTo(_lhw, -_lhh);

  // papyrus: horizontal strips laid over vertical ones, so faint seams and
  // short cross-fibres
  static final seams = () {
    final p = Path();
    const ys = [-7.2, -3.2, 5.4, 8.4];
    for (var k = 0; k < ys.length; k++) {
      final y = ys[k];
      final cut = -4.0 + k * 6.5;
      p.moveTo(-_lhw, y);
      p.lineTo(cut - 1.2, y + .15);
      p.moveTo(cut + 1.4, y + .15);
      p.lineTo(_lhw, y - .1);
    }
    return p;
  }();
  static final fibres = () {
    final p = Path();
    for (var i = 0; i < 26; i++) {
      final x = -_lhw + 1.5 + _h01(i * 3 + 1) * (_lw - 3);
      final y = -_lhh + 1.5 + _h01(i * 3 + 2) * (_lh - 3);
      final l = 1.0 + _h01(i * 3 + 3) * 1.8;
      p.moveTo(x, y);
      p.lineTo(x + .25, y + l);
    }
    return p;
  }();

  // the cord: twist ticks along a horizontal run through the seal
  static const cordY = _tipY + .15;
  static final twist = () {
    final p = Path();
    for (var x = -_lhw + 1.0; x < _lhw; x += 1.9) {
      p.moveTo(x - .35, cordY - .55);
      p.lineTo(x + .35, cordY + .55);
    }
    return p;
  }();

  // the pyramid postage stamp, top right: perforated paper, lapis sky, gold pyramid
  static const stampRect = Rect.fromLTRB(7.3, -11.2, 16.0, -1.2);
  static final perf = () {
    final p = Path();
    final r = stampRect;
    for (var x = r.left + 1.2; x < r.right; x += 1.6) {
      p.addOval(Rect.fromCircle(center: Offset(x, r.top), radius: .5));
      p.addOval(Rect.fromCircle(center: Offset(x, r.bottom), radius: .5));
    }
    for (var y = r.top + 1.2; y < r.bottom; y += 1.6) {
      p.addOval(Rect.fromCircle(center: Offset(r.left, y), radius: .5));
      p.addOval(Rect.fromCircle(center: Offset(r.right, y), radius: .5));
    }
    return p;
  }();
  static final pyramidLit = Path()
    ..moveTo(8.6, -2.5)
    ..lineTo(11.1, -6.6)
    ..lineTo(11.1, -2.5)
    ..close();
  static final pyramidShade = Path()
    ..moveTo(11.1, -6.6)
    ..lineTo(13.6, -2.5)
    ..lineTo(11.1, -2.5)
    ..close();
  static final cancel = () {
    // three wavy cancel lines running off the stamp across the paper
    final p = Path();
    for (var k = 0; k < 3; k++) {
      final y = -7.2 + k * 2.3;
      p.moveTo(2.4, y);
      for (var i = 0; i < 6; i++) {
        p.relativeQuadraticBezierTo(.9, i.isEven ? -1.1 : 1.1, 1.8, 0);
      }
    }
    return p;
  }();

  // the address: a cartouche of four glyphs, and two lines of hieratic scribble
  static final cartouche = RRect.fromLTRBR(-14.3, 4.3, -4.9, 10.0, const Radius.circular(2.9));
  static final glyphs = () {
    final p = Path();
    // eye
    p.addOval(Rect.fromCenter(center: const Offset(-12.6, 7.15), width: 2.3, height: 1.4));
    p.addOval(Rect.fromCenter(center: const Offset(-12.6, 7.15), width: .5, height: .5));
    // sun disc
    p.addOval(Rect.fromCenter(center: const Offset(-10.0, 7.15), width: 2.0, height: 2.0));
    p.addOval(Rect.fromCenter(center: const Offset(-10.0, 7.15), width: .5, height: .5));
    // water: three stacked ripples
    for (var k = 0; k < 3; k++) {
      final y = 6.0 + k * 1.15;
      p.moveTo(-8.4, y);
      p.relativeQuadraticBezierTo(.45, -.5, .9, 0);
      p.relativeQuadraticBezierTo(.45, .5, .9, 0);
    }
    // reed leaf
    p.addOval(Rect.fromCenter(center: const Offset(-5.9, 7.15), width: 1.0, height: 3.2));
    return p;
  }();
  static final scribble = () {
    final p = Path();
    for (var k = 0; k < 2; k++) {
      final y = 6.0 + k * 2.8;
      final x0 = 4.4, x1 = k == 0 ? 12.4 : 10.2;
      p.moveTo(x0, y);
      for (var x = x0 + .9; x <= x1; x += 1.8) {
        p.lineTo(x, y - .8);
        p.lineTo(x + .9, y + .6);
      }
    }
    return p;
  }();

  // the express border: a ring of turquoise / cream / carnelian diagonal stripes
  static final ring = Path.combine(PathOperation.difference, Path()..addRRect(rr), Path()..addRRect(rr.deflate(1.9)));
  static Path stripes(int phase) {
    final p = Path();
    for (var i = -24; i < 12; i += 3) {
      final x = i * 1.9 + phase * 1.9;
      p.moveTo(x, _lhh + 1);
      p.lineTo(x + 1.9, _lhh + 1);
      p.lineTo(x + 1.9 + _lh + 2, -_lhh - 1);
      p.lineTo(x + _lh + 2, -_lhh - 1);
      p.close();
    }
    return p;
  }

  static final stripesTurq = stripes(0), stripesRed = stripes(1);
  static final ringTurq = Path.combine(PathOperation.intersect, stripesTurq, ring), ringRed = Path.combine(PathOperation.intersect, stripesRed, ring);

  static ui.Picture? _normal, _fury, _normalLite, _furyLite;

  /// The face at game size is a 32 x 23 px object: the fibres, the stain, the
  /// cord's twist, the hieratic scribble and the stamp's perforations are
  /// texture there, so below [liteBelow] px wide a lighter face (about a third
  /// of the ops, no clip) is replayed. Hero shots, the story and close-ups
  /// (wider than that) get the full one.
  static const liteBelow = 46.0;
  static bool lite(Canvas c) {
    try {
      final m = c.getTransform();
      return 2 * _lhw * math.sqrt(m[0] * m[0] + m[1] * m[1]) < liteBelow;
    } catch (_) {
      return false;
    }
  }

  static ui.Picture picture({required bool fury, bool lite = false}) => lite
      ? (fury ? (_furyLite ??= _record('letter-fury-lite', (c) => face(c, fury: true, lite: true))) : (_normalLite ??= _record('letter-lite', (c) => face(c, fury: false, lite: true))))
      : (fury ? (_fury ??= _record('letter-fury', (c) => face(c, fury: true))) : (_normal ??= _record('letter', (c) => face(c, fury: false))));

  /// The static face (about 50 ops, recorded once).
  static void face(Canvas c, {required bool fury, bool lite = false}) {
    // skin: light from the upper right, shade lower left
    c.drawRRect(rr, _gp(_lg(const Offset(-_lhw, _lhh), const Offset(_lhw, -_lhh), [NeferhooPalette.papyrusShade, NeferhooPalette.papyrus, NeferhooPalette.papyrusHi], const [0, .55, 1])));
    if (lite) {
      _liteFace(c, fury: fury);
      return;
    }
    c.save();
    c.clipRRect(rr);
    c.drawPath(seams, _sp(NeferhooPropInk.tan, .65, .75));
    c.drawPath(fibres, _sp(NeferhooPropInk.tan, .5, .55));
    // a faint tea stain, the age of a dead letter
    c.drawCircle(const Offset(8.8, 7.6), 4.6, _sp(NeferhooPropInk.tan, 1.2, .12));
    // the flap: thicker, a little deeper in tone, a shadow under its edge
    c.drawPath(flap, _gp(_lg(const Offset(0, -_lhh), const Offset(0, _tipY), [NeferhooPalette.papyrus, const Color(0xffe9cd8a)])));
    c.save();
    c.translate(0, 1.15);
    c.drawPath(flapEdge, _sp(NeferhooPropInk.ochre, 1.5, .28));
    c.restore();
    c.drawPath(flapEdge, _sp(const Color(0xff8c6a34), .95, .95));
    c.drawPath(flapEdgeRight.shift(const Offset(0, -.75)), _sp(NeferhooPalette.papyrusHi, .6, .75));
    // the cord: two strands twisted, a lit line along the top
    c.drawLine(const Offset(-_lhw, cordY), const Offset(_lhw, cordY), _sp(NeferhooPropInk.cordDark, 1.7));
    c.drawLine(const Offset(-_lhw, cordY), const Offset(_lhw, cordY), _sp(NeferhooPropInk.cord, 1.1));
    c.drawPath(twist, _sp(NeferhooPropInk.cordDark, .5, .6));
    c.drawLine(const Offset(-_lhw, cordY - .45), const Offset(_lhw, cordY - .45), _sp(NeferhooPropInk.cordLit, .4, .8));
    // the cord's two tails under the seal, frayed
    final t1 = Path()
      ..moveTo(-1.0, cordY + 2)
      ..quadraticBezierTo(-3.6, cordY + 4.5, -2.7, cordY + 8.0);
    final t2 = Path()
      ..moveTo(1.2, cordY + 2)
      ..quadraticBezierTo(3.0, cordY + 4.0, 2.6, cordY + 7.0);
    c.drawPath(t1, _sp(NeferhooPropInk.cordDark, 1.5));
    c.drawPath(t1, _sp(NeferhooPropInk.cord, .9));
    c.drawPath(t2, _sp(NeferhooPropInk.cordDark, 1.5));
    c.drawPath(t2, _sp(NeferhooPropInk.cord, .9));
    // address: cartouche + glyphs + scribble
    c.drawRRect(cartouche, _sp(NeferhooPropInk.ochre, .75, .9));
    c.drawLine(const Offset(-4.1, 4.5), const Offset(-4.1, 9.8), _sp(NeferhooPropInk.ochre, .75, .9));
    c.drawPath(glyphs, _sp(NeferhooPropInk.ochre, .6, .95));
    c.drawPath(scribble, _sp(NeferhooPropInk.ochre, .55, .7));
    // the seal (a wax drip first, then the disc)
    c.drawOval(Rect.fromCenter(center: const Offset(-2.7, cordY + 4.1), width: 2.6, height: 2.0), _fp(NeferhooPalette.carnShade));
    _Wax.draw(c, const Offset(0, cordY + .05), 4.3);
    // the stamp: perforated paper, lapis sky, a sun and a gold pyramid
    c.drawRect(stampRect, _fp(NeferhooPropInk.paper));
    c.drawPath(perf, _fp(NeferhooPalette.papyrus));
    final art = stampRect.deflate(1.25);
    c.drawRect(art, _gp(_lg(art.topCenter, art.bottomCenter, [NeferhooPalette.lapisLit, NeferhooPalette.lapis, NeferhooPalette.lapisShade])));
    c.drawCircle(const Offset(9.9, -7.4), 1.0, _fp(NeferhooPalette.goldHi));
    c.drawPath(pyramidLit, _fp(NeferhooPalette.goldLit));
    c.drawPath(pyramidShade, _fp(NeferhooPalette.goldShade));
    c.drawRect(art, _sp(NeferhooPalette.ink, .5, .8));
    c.drawRect(stampRect, _sp(NeferhooPropInk.ochre, .45, .55));
    // the cancel: wavy lines and part of a round postmark running over the stamp
    c.drawPath(cancel, _sp(NeferhooPalette.ink, .55, .5));
    c.drawCircle(const Offset(5.2, -4.6), 4.3, _sp(NeferhooPalette.ink, .5, .32));
    c.restore();
    if (fury) {
      // EXPRESS POST: an airmail border (turquoise / cream / carnelian)
      c.drawPath(ring, _fp(NeferhooPropInk.paper));
      c.save();
      c.clipPath(ring);
      c.drawPath(stripesTurq, _fp(NeferhooPalette.turq));
      c.drawPath(stripesRed, _fp(NeferhooPalette.carn));
      c.restore();
      c.drawRRect(rr.deflate(1.9), _sp(NeferhooPalette.ink, .5, .7));
    } else {
      // rim light on the top and right, shade on the lower left
      final lit = Path()
        ..moveTo(-_lhw + 1.2, -_lhh + .9)
        ..lineTo(_lhw - .9, -_lhh + .9)
        ..lineTo(_lhw - .9, _lhh - 1.2);
      final shade = Path()
        ..moveTo(-_lhw + .9, -_lhh + 1.2)
        ..lineTo(-_lhw + .9, _lhh - .9)
        ..lineTo(_lhw - 1.2, _lhh - .9);
      c.drawPath(lit, _sp(NeferhooPalette.papyrusHi, .8, .85));
      c.drawPath(shade, _sp(NeferhooPropInk.tan, 1.0, .55));
    }
    c.drawRRect(rr, _sp(NeferhooPalette.ink, 1.5));
  }

  /// What survives at 32 px: the flap with its shadow edge, the cord and the
  /// wax seal, the pyramid stamp as a lapis block with a gold peak, the
  /// cartouche as one ochre outline, the rim light or the express border.
  static void _liteFace(Canvas c, {required bool fury}) {
    c.drawPath(flap, _gp(_lg(const Offset(0, -_lhh), const Offset(0, _tipY), [NeferhooPalette.papyrus, const Color(0xffe9cd8a)])));
    c.drawPath(flapEdge, _sp(const Color(0xff8c6a34), 1.0, .95));
    c.drawLine(const Offset(-_lhw, cordY), const Offset(_lhw, cordY), _sp(NeferhooPropInk.cord, 1.5));
    c.drawRRect(cartouche, _sp(NeferhooPropInk.ochre, .9, .9));
    c.drawPath(glyphs, _sp(NeferhooPropInk.ochre, .9, .85));
    _Wax.draw(c, const Offset(0, cordY + .05), 4.3);
    c.drawRect(stampRect, _fp(NeferhooPropInk.paper));
    c.drawRect(stampRect.deflate(1.25), _fp(NeferhooPalette.lapis));
    c.drawPath(pyramidLit, _fp(NeferhooPalette.goldLit));
    c.drawRect(stampRect, _sp(NeferhooPalette.ink, .6, .7));
    if (fury) {
      // the stripes pre-cut to the border (no clip in the lite face)
      c.drawPath(ring, _fp(NeferhooPropInk.paper));
      c.drawPath(ringTurq, _fp(NeferhooPalette.turq));
      c.drawPath(ringRed, _fp(NeferhooPalette.carn));
      c.drawRRect(rr.deflate(1.9), _sp(NeferhooPalette.ink, .5, .7));
    } else {
      c.drawPath(
        Path()
          ..moveTo(-_lhw + 1.2, -_lhh + .9)
          ..lineTo(_lhw - .9, -_lhh + .9)
          ..lineTo(_lhw - .9, _lhh - 1.2),
        _sp(NeferhooPalette.papyrusHi, .8, .85),
      );
    }
    c.drawRRect(rr, _sp(NeferhooPalette.ink, 1.5));
  }

  // speed streaks trailing behind (to +x), as tapered whiskers
  static Path streaks(double len) {
    final p = Path();
    const ys = [-6.5, .8, 7.0];
    const ls = [.7, 1.0, .55];
    for (var k = 0; k < 3; k++) {
      final y = ys[k], l = len * ls[k];
      p.moveTo(_lhw + 1.2, y - 1.0);
      p.lineTo(_lhw + 1.2 + l, y);
      p.lineTo(_lhw + 1.2, y + 1.0);
      p.close();
    }
    return p;
  }

  // RETURN / TO SENDER: a boxed label (cream plate, red border and ink)
  static const labelW = 31.0, labelH = 13.6;
  static ui.Picture? _label;
  static ui.Picture get label => _label ??= _record('label', paintLabel);
  static ui.Picture? _labelBars;

  /// The label at game size: the plate, the red border and two bold bars where
  /// the words are (3.9 px glyphs are texture at 1x; the HUD tag carries the words).
  static ui.Picture get labelBars => _labelBars ??= _record('label-bars', (c) => paintLabel(c, 1, true));
  static void paintLabel(Canvas c, [double a = 1, bool bars = false]) {
    final r = Rect.fromCenter(center: Offset.zero, width: labelW, height: labelH);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(1.6));
    c.drawRRect(rr.shift(const Offset(.9, 1.2)), _fp(NeferhooPalette.ink, .3 * a));
    c.drawRRect(rr, _fp(NeferhooPropInk.paper, a));
    c.drawRRect(rr, _sp(NeferhooPropInk.stampRed, 1.5, a));
    c.drawRRect(rr.deflate(1.7), _sp(NeferhooPropInk.stampRed, .55, .85 * a));
    if (bars) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -2.4), width: 17, height: 2.9), const Radius.circular(.8)), _fp(NeferhooPropInk.stampRed, a));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 2.7), width: 22, height: 2.9), const Radius.circular(.8)), _fp(NeferhooPropInk.stampRed, a));
      return;
    }
    _Font.draw(c, 'RETURN', const Offset(0, -2.55), 3.9, NeferhooPropInk.stampRed, .85, a);
    _Font.draw(c, 'TO SENDER', const Offset(0, 2.65), 3.9, NeferhooPropInk.stampRed, .85, a);
  }
}

/// The full letter at [o]: [h] is the screen height in pixels (the body is
/// exactly .090 x .064 h), [tilt] the caller's rotation, [returned] 0..1 the
/// slam of the RETURN TO SENDER label, [fury] the express (turquoise-edged)
/// variant, [flutter] 0..1 the paper's flutter (> 0 means it is in flight:
/// a rock, a corner curl and speed whiskers follow it). [alpha] < 1 fades it
/// through one small bounded layer (cinematics only).
void _paintLetter(Canvas c, Offset o, double h, {double tilt = 0, double returned = 0, double alpha = 1, bool fury = false, double flutter = 0, double rock = 1}) {
  final flight = flutter > 0;
  c.save();
  c.translate(o.dx, o.dy);
  // ([rock] < 1 calms the paper's rocking: near the bird the fight art keeps the drawn
  // envelope within a pixel of the rules' rectangle)
  c.rotate((tilt + (flight ? (flutter - .5) * .14 : 0)) * rock);
  c.scale(h / 360);
  final a = alpha.clamp(0.0, 1.0);
  // behind the paper: whiskers, glow, shadow
  if (flight) {
    final len = (9 + 12 * flutter) * (fury ? 1.5 : 1);
    final w = _LetterArt.streaks(len);
    if (fury) {
      c.drawPath(w.shift(const Offset(0, .6)), _fp(NeferhooPalette.turqShade, .35 * a));
      c.drawPath(w, _fp(NeferhooPalette.turqLit, .8 * a));
    } else {
      c.drawPath(w.shift(const Offset(0, 1.1)), _fp(NeferhooPalette.inkSoft, .16 * a));
      c.drawPath(w, _fp(NeferhooPalette.papyrusHi, .62 * a));
    }
  }
  final rr = _LetterArt.rr;
  if (returned > 0) {
    c.drawRRect(rr.inflate(4.4), _fp(NeferhooPalette.goldLit, .2 * returned * a));
    c.drawRRect(rr.inflate(2.4), _fp(NeferhooPalette.goldLit, .55 * returned * a));
  } else if (fury) {
    c.drawRRect(rr.inflate(3.6), _fp(NeferhooPalette.magic, .16 * a));
    c.drawRRect(rr.inflate(1.9), _fp(NeferhooPalette.turq, .32 * a));
  } else {
    c.drawRRect(rr.inflate(1.3), _fp(NeferhooPalette.papyrusHi, .2 * a));
    c.drawRRect(rr.inflate(.6).shift(const Offset(0, 1.5)), _fp(NeferhooPalette.ink, .2 * a));
  }
  final pic = _LetterArt.picture(fury: fury, lite: _LetterArt.lite(c));
  // the face is drawn a hair smaller so the ink's OUTER edge is exactly the
  // rules rectangle (.090 x .064 h): a dodge that looks clean is clean
  c.save();
  c.scale(_LetterArt.fitX, _LetterArt.fitY);
  if (a >= .98) {
    c.drawPicture(pic);
  } else {
    c.saveLayer(_LetterArt.rect.inflate(6), Paint()..color = Color.fromRGBO(0, 0, 0, a));
    c.drawPicture(pic);
    c.restore();
  }
  if (flight) {
    // the flap lifts (a deeper shadow under its edge) and the corner curls
    c.drawPath(_LetterArt.flapEdge.shift(Offset(0, 1.6 + flutter * 1.4)), _sp(NeferhooPropInk.ochre, .9, .3 * a));
    final d = 1.6 + 3.6 * flutter;
    final curl = Path()
      ..moveTo(_lhw - d, _lhh)
      ..lineTo(_lhw, _lhh - d)
      ..lineTo(_lhw - d * .15, _lhh - d * .15)
      ..close();
    c.drawPath(curl, _gp(_lg(Offset(_lhw - d, _lhh), Offset(_lhw, _lhh - d), [NeferhooPalette.papyrusHi, NeferhooPalette.papyrus])));
    c.drawLine(Offset(_lhw - d, _lhh), Offset(_lhw, _lhh - d), _sp(NeferhooPropInk.ochre, .55, .8 * a));
  }
  c.restore();
  if (returned > 0) {
    // the label slams on from the camera: big, then home
    final e = NeferhooKit.smooth01(returned);
    final s = 1 + (1 - e) * 1.0;
    c.save();
    c.translate(1.5, 4.0);
    c.rotate(-.2 - (1 - e) * .25);
    c.scale(s);
    c.drawPicture(_LetterArt.lite(c) ? _LetterArt.labelBars : _LetterArt.label);
    c.restore();
    if (returned < .5) {
      // an impact ring as the label lands
      final k = returned / .5;
      c.drawCircle(const Offset(1.5, 4.0), 12 + 12 * k, _sp(NeferhooPalette.goldHi, 1.6 * (1 - k), (1 - k) * a));
    }
  }
  c.restore();
}

// ---------------------------------------------------------------------------
// THE ANKH: burnished gold, cloisonne inlay (lapis and turquoise cells, a
// carnelian cabochon where the arms cross), a chased border

/// Four-point sparkle of radius [r] at [o] (long points r, short .4 r).
Path _star(Offset o, double r, [double rot = 0]) {
  final p = Path();
  for (var i = 0; i < 8; i++) {
    final a = rot + i * math.pi / 4 - math.pi / 2;
    final rr = i.isEven ? r : r * .32;
    final q = o + Offset(math.cos(a), math.sin(a)) * rr;
    i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
  }
  return p..close();
}

abstract final class _AnkhArt {
  // the shape, .94 tall (y -.47 .. .47) so the ink outline (.035 outside) makes
  // it exactly 1 unit; chunky enough to carry inlay at 37 px
  static const lc = Offset(0, -.265);
  static final loop = Path()..addOval(Rect.fromCenter(center: lc, width: .40, height: .42));
  static final hole = Path()..addOval(Rect.fromCenter(center: lc, width: .16, height: .21));
  static final bar = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -.01), width: .76, height: .15), const Radius.circular(.05)));
  static final stem = Path()
    ..moveTo(-.075, -.06)
    ..lineTo(.075, -.06)
    ..lineTo(.11, .44)
    ..quadraticBezierTo(.112, .47, .08, .47)
    ..lineTo(-.08, .47)
    ..quadraticBezierTo(-.112, .47, -.11, .44)
    ..close();
  static final shape = Path.combine(PathOperation.difference, Path.combine(PathOperation.union, Path.combine(PathOperation.union, loop, bar), stem), hole);

  static final ringArc = Rect.fromCenter(center: lc, width: .28, height: .315);
  static const _a0 = math.pi / 2 + .8, _sw = math.pi * 2 - 1.6;
  static final ringTicks = () {
    final p = Path();
    for (var i = 0; i < 9; i++) {
      final a = _a0 + i * _sw / 8;
      final cs = math.cos(a), sn = math.sin(a);
      p.moveTo(lc.dx + cs * .12, lc.dy + sn * .1375);
      p.lineTo(lc.dx + cs * .16, lc.dy + sn * .1775);
    }
    return p;
  }();
  // arms: cells outward from the cabochon; stem: four cells down
  static final barCells = [for (var i = 0; i < 6; i++) Rect.fromLTWH(-.3 + i * .1, -.04, .1, .06)];
  static final stemCells = [for (var i = 0; i < 4; i++) Rect.fromLTWH(-.03, .09 + i * .085, .06, .085)];
  static final barDiv = () {
    final p = Path();
    for (var i = 0; i <= 6; i++) {
      p.moveTo(-.3 + i * .1, -.042);
      p.lineTo(-.3 + i * .1, .022);
    }
    return p;
  }();
  static final stemDiv = () {
    final p = Path();
    for (var i = 0; i <= 4; i++) {
      p.moveTo(-.032, .09 + i * .085);
      p.lineTo(.032, .09 + i * .085);
    }
    return p;
  }();

  static final _pics = <int, ui.Picture>{};
  static ui.Picture picture(bool second) => _pics.putIfAbsent(second ? 1 : 0, () => _record(second ? 'ankh-second' : 'ankh', (c) => face(c, second)));

  static void face(Canvas c, bool second) {
    // ink first: only its outer half shows, so the gold keeps its full width
    c.drawPath(shape, _sp(NeferhooPalette.ink, .07));
    final main = _gp(_rg(const Offset(0, -.16), .6, [NeferhooPalette.goldHi, NeferhooPalette.goldLit, NeferhooPalette.gold, NeferhooPalette.goldShade], const [0, .28, .62, 1]));
    c.drawPath(shape, main);
    // chased border: a groove inset from the edge, a lit lip outside it
    c.save();
    c.clipPath(shape);
    c.drawPath(shape, _sp(NeferhooPalette.goldDeep, .088, .85));
    c.drawPath(shape, _gp(main.shader!)..style = PaintingStyle.stroke..strokeWidth = .064);
    c.drawPath(shape, _sp(NeferhooPalette.goldHi, .014, .6));
    c.restore();
    // the inlay (cloisonne cells)
    final base = second ? NeferhooPalette.turqShade : NeferhooPalette.lapis;
    final cell = second ? NeferhooPalette.turqLit : NeferhooPalette.turq;
    final cell2 = second ? NeferhooPalette.barWhite : NeferhooPalette.lapisLit;
    c.drawArc(ringArc, _a0, _sw, false, _sp(base, .042, 1, StrokeCap.butt));
    c.drawArc(ringArc, _a0, _sw, false, _sp(cell2, .01, .65, StrokeCap.butt));
    c.drawPath(ringTicks, _sp(NeferhooPalette.goldDeep, .011, .9));
    c.drawRect(const Rect.fromLTWH(-.3, -.04, .6, .06), _fp(base));
    c.drawRect(const Rect.fromLTWH(-.03, .09, .06, .34), _fp(base));
    for (var i = 0; i < 6; i++) {
      if (i == 2 || i == 3) continue; // under the cabochon
      c.drawRect(barCells[i].deflate(.0065), _fp(i == 1 || i == 4 ? cell : cell2, .96));
    }
    for (var i = 0; i < 4; i++) {
      c.drawRect(stemCells[i].deflate(.0055), _fp(i.isEven ? cell : cell2, .96));
    }
    c.drawPath(barDiv, _sp(NeferhooPalette.goldDeep, .011));
    c.drawPath(stemDiv, _sp(NeferhooPalette.goldDeep, .011));
    c.drawRect(const Rect.fromLTWH(-.3, -.04, .6, .06), _sp(NeferhooPalette.goldDeep, .011));
    c.drawRect(const Rect.fromLTWH(-.03, .09, .06, .34), _sp(NeferhooPalette.goldDeep, .011));
    // the cabochon where the arms cross
    c.drawCircle(const Offset(0, -.01), .066, _fp(NeferhooPalette.goldDeep));
    c.drawCircle(const Offset(0, -.01), .053, _gp(_rg(const Offset(.014, -.026), .07, [NeferhooPropInk.waxLit, NeferhooPalette.carn, NeferhooPalette.carnShade], const [0, .5, 1])));
    c.drawCircle(const Offset(.017, -.026), .013, _fp(const Color(0xffffffff), .9));
  }
}

/// The golden ankh (an object, the courier's homing charm), [size] tall in
/// whatever units the canvas is in, spun by [spin] radians. [second] is the
/// fury ankh (turquoise inlay), [smear] > 0 leaves rotation ghosts behind it
/// (the spin reads as a turn, never a blur), [glint] 0..1 sweeps a sparkle
/// down its length. [alpha] < 1 grows it in (no fade layer).
void _paintAnkh(Canvas c, Offset o, double size, double spin, {bool silhouette = false, Color sil = NeferhooPalette.ink, double alpha = 1, bool second = false, double smear = 0, double glint = -1}) {
  final k = alpha >= 1 ? 1.0 : NeferhooKit.smooth01(alpha * 1.3);
  if (k <= 0) return;
  c.save();
  c.translate(o.dx, o.dy);
  c.scale(size * k);
  if (silhouette) {
    c.rotate(spin);
    c.drawPath(_AnkhArt.shape, _fp(sil));
    c.restore();
    return;
  }
  if (smear > 0) {
    // rotation ghosts: flat gold shapes trailing the spin, no outline
    for (var i = 2; i >= 1; i--) {
      c.save();
      c.rotate(spin - smear * i * .5);
      c.drawPath(_AnkhArt.shape, _fp(second ? NeferhooPalette.turqLit : NeferhooPalette.goldLit, .3 / i));
      c.restore();
    }
  }
  c.save();
  c.rotate(spin);
  c.drawPicture(_AnkhArt.picture(second));
  c.restore();
  if (glint >= 0 && glint <= 1) {
    final g = math.sin(glint * math.pi);
    final at = Offset(.0, -.42 + .84 * glint);
    c.drawPath(_star(at, .11 * g), _fp(const Color(0xffffffff), .95 * g));
    c.drawCircle(at, .035 * g, _fp(NeferhooPalette.goldHi, .8 * g));
  }
  c.restore();
}

/// A tapered ribbon through [pts] (oldest first, last = head), [w] wide at
/// the head: a faint wide glow and a bright core, fading to nothing at the tail.
void _ribbon(Canvas c, List<Offset> pts, double w, Color glow, Color core, {double a = 1}) {
  if (pts.length < 2) return;
  final n = pts.length;
  Path strip(double width) {
    final l = <Offset>[], r = <Offset>[];
    for (var i = 0; i < n; i++) {
      final p0 = pts[math.max(0, i - 1)], p1 = pts[math.min(n - 1, i + 1)];
      var d = p1 - p0;
      final len = d.distance;
      d = len == 0 ? const Offset(1, 0) : d / len;
      final nrm = Offset(-d.dy, d.dx);
      final t = i / (n - 1);
      final ww = width * math.pow(t, 1.15) / 2;
      l.add(pts[i] + nrm * ww);
      r.add(pts[i] - nrm * ww);
    }
    final p = Path()..moveTo(l.first.dx, l.first.dy);
    for (final q in l.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    for (final q in r.reversed) {
      p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }
  c.drawPath(strip(w * 2.1), _gp(_lg(pts.first, pts.last, [glow.withValues(alpha: 0), glow.withValues(alpha: .34 * a)])));
  c.drawPath(strip(w * .9), _gp(_lg(pts.first, pts.last, [core.withValues(alpha: 0), core.withValues(alpha: .85 * a)])));
}

/// The ankh in flight at [p] (screen fractions), its [trail] (screen
/// fractions, oldest first). [h] is the screen height in pixels. The solid
/// body is 2.3 x the rules radius tall, as designed; the halo, ghosts and
/// ribbon are never solid.
void _paintFlyingAnkh(Canvas c, Offset p, double h, double spin, {List<Offset> trail = const [], bool second = false}) {
  final o = Offset(p.dx * h, p.dy * h);
  final pts = [for (final q in trail) Offset(q.dx * h, q.dy * h), o];
  _ribbon(c, pts, Neferhoo.ankhRadius * h * .9, second ? NeferhooPalette.magic : NeferhooPalette.goldLit, second ? NeferhooPalette.turqLit : NeferhooPalette.goldHi);
  // dust: three sparkles shed along the ribbon
  for (var i = 1; i <= 3 && i < pts.length - 1; i++) {
    final q = pts[(pts.length * i / 4).floor().clamp(0, pts.length - 2)];
    final j = Offset((_h01(i * 7) - .5) * h * .012, (_h01(i * 7 + 1) - .5) * h * .02);
    c.drawPath(_star(q + j, h * (.007 - i * .0012), math.pi / 4 * i), _fp(second ? NeferhooPalette.turqLit : NeferhooPalette.goldHi, .7 - i * .15));
  }
  c.drawCircle(o, Neferhoo.ankhRadius * h * 1.7, _gp(_rg(o, Neferhoo.ankhRadius * h * 1.7, [(second ? NeferhooPalette.magic : NeferhooPalette.goldLit).withValues(alpha: .42), (second ? NeferhooPalette.magic : NeferhooPalette.goldLit).withValues(alpha: .12), (second ? NeferhooPalette.magic : NeferhooPalette.goldLit).withValues(alpha: 0)], const [0, .55, 1])));
  _paintAnkh(c, o, Neferhoo.ankhRadius * 2.3 * h, spin, second: second, smear: 1, glint: ((spin / (math.pi * 2)) % 1.0 + 1.0) % 1.0);
}

// ---------------------------------------------------------------------------
// rig-unit props (1 unit = the boss hit radius): the hand fan of letters, the
// hovering ankh, the lost letter, the postmark imprint. Called from the
// owned methods of NeferhooPainter.

abstract final class _RigProps {
  static final auraPaint = _gp(_rg(Offset.zero, 1, [NeferhooPalette.magic.withValues(alpha: .42), NeferhooPalette.magic.withValues(alpha: .12), NeferhooPalette.magic.withValues(alpha: 0)], const [0, .5, 1]));
  static final sheenPaint = _gp(_rg(Offset.zero, 1, [NeferhooPalette.goldLit.withValues(alpha: .5), NeferhooPalette.goldLit.withValues(alpha: .16), NeferhooPalette.goldLit.withValues(alpha: 0)], const [0, .5, 1]));
  static final glowGold = _gp(_rg(Offset.zero, 1, [NeferhooPalette.goldLit.withValues(alpha: .6), NeferhooPalette.goldLit.withValues(alpha: .34), NeferhooPalette.goldLit.withValues(alpha: 0)], const [0, .55, 1]));

  // the fan card scale: a letter .72 u wide
  static const cardW = .72, cardS = cardW / _lw;
  static const cardH = _lh * cardS;
}

extension NeferhooPropsPaint on NeferhooPainter {
  /// The hand fan of letters in front of the chest, held in the near wing's
  /// splayed primaries (pivot at the deal point), a magic stream rising from
  /// the satchel's mouth. The cards are the same papyrus letter as in flight.
  void propCards() {
    if (p.cards <= 0) return;
    final o = fanPoint;
    if (fx) {
      final gc = o + const Offset(0, -.4);
      c.save();
      c.translate(gc.dx, gc.dy);
      c.scale(.95);
      c.drawCircle(Offset.zero, 1, _RigProps.auraPaint);
      c.restore();
      // sparks of magic lift the letters out of the satchel: halo dots and diamonds
      final from = NeferhooLayout.satchel + const Offset(-.35, -.45);
      final halos = Path(), dia = Path();
      for (var k = 1; k < 7; k++) {
        final t = k / 7;
        final q = Offset.lerp(from, o + const Offset(.2, -.2), t)! + Offset(0, -math.sin(t * math.pi) * .35);
        halos.addOval(Rect.fromCircle(center: q, radius: .1));
        final r = .05 + .018 * math.sin(p.phase * 6 + k);
        if (k.isOdd) {
          dia.addPolygon([q + Offset(0, -r * 1.5), q + Offset(r, 0), q + Offset(0, r * 1.5), q + Offset(-r, 0)], true);
        } else {
          dia.addOval(Rect.fromCircle(center: q, radius: r * .8));
        }
      }
      c.drawPath(halos, _fp(NeferhooPalette.magic, .18));
      c.drawPath(dia, _fp(NeferhooPalette.magic, .92));
    }
    for (var k = 0; k < p.cards; k++) {
      final flutter = fx ? math.sin(p.phase * 5 + k * 1.9) * .018 : 0.0;
      final a = (k - (p.cards - 1) / 2) * .32 * p.cardSpread - .2 + flutter;
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(a);
      c.translate(0, -_RigProps.cardH / 2 - .2);
      final r = Rect.fromCenter(center: Offset.zero, width: _RigProps.cardW, height: _RigProps.cardH);
      if (!fx) {
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(.04)), _fp(sil));
      } else {
        // a soft shadow on the card beneath, a faint magic rim, then the letter
        c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(-.035, .03)), const Radius.circular(.04)), _fp(NeferhooPalette.ink, .22));
        c.drawRRect(RRect.fromRectAndRadius(r.inflate(.035), const Radius.circular(.06)), _fp(NeferhooPalette.magic, .26));
        c.scale(_RigProps.cardS * _LetterArt.fitX, _RigProps.cardS * _LetterArt.fitY);
        c.drawPicture(_LetterArt.picture(fury: p.fury > .5, lite: _LetterArt.lite(c)));
      }
      c.restore();
    }
  }

  /// The hovering ankh: a golden sheen, light spokes, orbiting diamonds of
  /// his magic, the ankh itself bobbing and swaying, a glint down its length.
  void propAnkhHover() {
    if (p.ankh <= 0) return;
    final bob = fx ? math.sin(p.phase * 2.3) * .05 * p.ankh : 0.0;
    final o = NeferhooLayout.ankhHover + Offset(0, (1 - p.ankh) * .6 + bob);
    if (fx) {
      final k = p.ankh;
      c.save();
      c.translate(o.dx, o.dy);
      c.scale(.98);
      c.drawCircle(Offset.zero, 1, Paint()..shader = _RigProps.auraPaint.shader..color = Color.fromRGBO(0, 0, 0, k));
      c.restore();
      c.save();
      c.translate(o.dx, o.dy);
      c.scale(.7);
      c.drawCircle(Offset.zero, 1, _RigProps.sheenPaint);
      c.restore();
      final spokes = Path(), dia = Path();
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + p.phase * .8;
        final d = Offset(math.cos(a), math.sin(a));
        spokes.moveTo(o.dx + d.dx * .58, o.dy + d.dy * .58);
        spokes.lineTo(o.dx + d.dx * (.8 + .1 * math.sin(p.phase * 5 + i)), o.dy + d.dy * (.8 + .1 * math.sin(p.phase * 5 + i)));
        final b = -i * math.pi / 4 - p.phase * .55;
        final q = o + Offset(math.cos(b), math.sin(b)) * .98;
        final r = .045 * (.7 + .3 * math.sin(p.phase * 4 + i));
        dia.addPolygon([q + Offset(0, -r * 1.4), q + Offset(r, 0), q + Offset(0, r * 1.4), q + Offset(-r, 0)], true);
      }
      c.drawPath(spokes, _sp(NeferhooPalette.magic, .04, .6 * k));
      c.drawPath(dia, _fp(NeferhooPalette.magic, .85 * k));
    }
    final spin = p.ankhSpin + (fx ? math.sin(p.phase * 1.7) * .07 : 0);
    final fast = ((spin.abs() - .6) / 3).clamp(0.0, 1.0);
    _paintAnkh(c, o, 1.05, spin, silhouette: silhouette, sil: sil, alpha: p.ankh, smear: fast, glint: fx ? (p.phase * .45) % 1.0 : -1);
  }

  /// The lost letter (story prop): an old papyrus letter, a faded lapis cord
  /// tied in a bow, a gold wax seal, addressed to the Sphinx; a faint glow
  /// and a few motes of dust-gold.
  void propLostLetter() {
    final o = NeferhooLayout.dealPoint + const Offset(-.25, -.55);
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(-.18);
    if (!fx) {
      c.drawPath(_LostArt.outline, _fp(sil));
      c.restore();
      return;
    }
    final pulse = 1 + .05 * math.sin(p.phase * 2.2);
    c.save();
    c.scale(1.12 * pulse);
    c.drawCircle(Offset.zero, 1, _RigProps.glowGold);
    c.restore();
    c.drawPicture(_LostArt.picture);
    // dust-gold motes drifting up round it
    final motes = Path();
    for (var i = 0; i < 6; i++) {
      final t = ((p.phase * .22 + i / 6) % 1.0);
      final x = (_h01(i * 5) - .5) * 1.3 + math.sin(p.phase * 1.4 + i) * .06;
      final y = .3 - t * 1.0;
      motes.addOval(Rect.fromCircle(center: Offset(x, y), radius: .022 + .014 * _h01(i * 5 + 2)));
    }
    c.drawPath(motes, _fp(NeferhooPalette.goldHi, .8));
    c.restore();
  }

  /// His postmark: a round cancel stamped on the wraps by a returned letter
  /// (ring, date dots, a pyramid and sun, wavy cancel lines running off it).
  void propStamp() {
    if (p.stamp <= 0 || !fx) return;
    final e = NeferhooKit.smooth01(p.stamp * 1.6);
    final ink = NeferhooPropInk.stampRed;
    c.save();
    // it lands exactly on the printed postmark: the bare lower-left of the
    // chest (NeferhooLayout.postmark), the target the returned letter flew at
    c.translate(NeferhooLayout.postmark.dx, NeferhooLayout.postmark.dy);
    c.rotate(-.25);
    final k = (.8 + .2 * e) * (1 + (1 - NeferhooKit.smooth01(p.stamp)) * .55) * NeferhooLayout.postmarkR / .62;
    c.scale(k);
    final a = e * .95;
    // the old bold red target ring, with a dark keyline so it reads on linen
    c.drawCircle(Offset.zero, .62, _sp(NeferhooPalette.ink, .17, .5 * a));
    c.drawCircle(Offset.zero, .62, _sp(ink, .1, a));
    c.drawCircle(Offset.zero, .49, _sp(ink, .045, a * .9));
    c.drawCircle(Offset.zero, .07, _fp(NeferhooPalette.goldLit, a));
    if (play) {
      c.restore();
      return;
    }
    // close-ups: the date dots, the pyramid and sun, the cancel lines
    c.drawPath(_Postmark.dots, _fp(ink, .9 * a));
    c.drawPath(_Postmark.pyramid, _sp(ink, .05, a));
    c.drawCircle(const Offset(.17, -.16), .06, _fp(ink, a));
    c.drawLine(const Offset(-.3, .2), const Offset(.3, .2), _sp(ink, .04, a));
    c.drawPath(_Postmark.cancel, _sp(ink, .045, .9 * a));
    c.restore();
  }
}

abstract final class _Postmark {
  static final dots = () {
    final p = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      p.addOval(Rect.fromCircle(center: Offset(math.cos(a), math.sin(a)) * .56, radius: .018));
    }
    return p;
  }();
  static final pyramid = Path()
    ..moveTo(-.3, .2)
    ..lineTo(0, -.22)
    ..lineTo(.3, .2);
  static final cancel = () {
    final p = Path();
    for (var k = 0; k < 3; k++) {
      final y = -.28 + k * .26;
      p.moveTo(.58, y);
      for (var i = 0; i < 4; i++) {
        p.relativeQuadraticBezierTo(.1, i.isEven ? -.1 : .1, .2, 0);
      }
    }
    return p;
  }();
}

// the lost letter, drawn in rig units
abstract final class _LostArt {
  static final outline = NeferhooKit.smoothPath(const [
    Offset(-.52, -.36), Offset(-.26, -.375), Offset(0, -.365), Offset(.27, -.378), Offset(.52, -.36), //
    Offset(.545, -.18), Offset(.535, .05), Offset(.55, .2), Offset(.5, .29), Offset(.43, .27), Offset(.4, .372), //
    Offset(.18, .365), Offset(-.08, .378), Offset(-.3, .364), Offset(-.53, .37), Offset(-.545, .15), Offset(-.535, -.1),
  ], k: .1);
  static final seams = () {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final y = -.31 + i * .09 + (_h01(i) - .5) * .02;
      p.moveTo(-.55, y);
      p.lineTo(-.02 - _h01(i + 9) * .1, y + .004);
      p.moveTo(.1 + _h01(i + 3) * .1, y);
      p.lineTo(.55, y - .004);
    }
    return p;
  }();
  static final fibres = () {
    final p = Path();
    for (var i = 0; i < 34; i++) {
      final x = -.5 + _h01(i * 3 + 1) * 1.0;
      final y = -.33 + _h01(i * 3 + 2) * .66;
      p.moveTo(x, y);
      p.lineTo(x + .004, y + .03 + _h01(i * 3 + 3) * .05);
    }
    return p;
  }();
  static final bowL = Path()
    ..moveTo(0, 0)
    ..cubicTo(-.08, -.16, -.26, -.17, -.24, -.06)
    ..cubicTo(-.22, .03, -.08, .02, 0, 0)
    ..close();
  static final bowR = Path()
    ..moveTo(0, 0)
    ..cubicTo(.08, -.16, .26, -.17, .24, -.06)
    ..cubicTo(.22, .03, .08, .02, 0, 0)
    ..close();
  static final tailL = Path()
    ..moveTo(-.02, .06)
    ..quadraticBezierTo(-.1, .2, -.16, .3)
    ..lineTo(-.1, .32)
    ..quadraticBezierTo(-.06, .2, .01, .08)
    ..close();
  static final tailR = Path()
    ..moveTo(.02, .06)
    ..quadraticBezierTo(.1, .2, .13, .31)
    ..lineTo(.19, .28)
    ..quadraticBezierTo(.13, .18, .0, .08)
    ..close();
  static final cartouche = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(-.31, .1), width: .27, height: .14), const Radius.circular(.07));
  static final sphinx = () {
    // a tiny recumbent sphinx facing left
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(-.3, .115), width: .15, height: .045), const Radius.circular(.02)));
    p.addOval(Rect.fromCircle(center: const Offset(-.37, .075), radius: .026));
    p.moveTo(-.4, .09);
    p.lineTo(-.43, .12);
    p.lineTo(-.37, .125);
    p.moveTo(-.255, .095);
    p.quadraticBezierTo(-.225, .07, -.24, .115);
    return p;
  }();
  static final lines = () {
    final p = Path();
    for (var k = 0; k < 2; k++) {
      final y = -.19 + k * .09;
      p.moveTo(-.46, y);
      for (var x = -.43; x <= (k == 0 ? -.16 : -.22); x += .06) {
        p.lineTo(x, y - .022);
        p.lineTo(x + .03, y + .016);
      }
    }
    return p;
  }();

  static ui.Picture? _pic;
  static ui.Picture get picture => _pic ??= _record('lost-letter', face);

  static void face(Canvas c) {
    c.drawPath(outline, _gp(_lg(const Offset(-.5, .36), const Offset(.5, -.36), [NeferhooPropInk.agedDark, NeferhooPropInk.aged, NeferhooPropInk.agedLit], const [0, .5, 1])));
    c.save();
    c.clipPath(outline);
    // age: burnt edges, a stain, seams and fibres
    c.drawPath(outline, _sp(NeferhooPropInk.agedDark, .16, .4));
    c.drawPath(seams, _sp(NeferhooPropInk.agedDark, .014, .55));
    c.drawPath(fibres, _sp(NeferhooPropInk.agedDark, .012, .45));
    c.drawCircle(const Offset(.3, .19), .17, _fp(NeferhooPropInk.agedDark, .12));
    c.drawCircle(const Offset(.3, .19), .17, _sp(NeferhooPropInk.agedDark, .02, .3));
    // folded in thirds: a shadow and a lit lip at each crease
    for (final x in const [-.19, .19]) {
      c.drawLine(Offset(x, -.38), Offset(x, .38), _sp(NeferhooPropInk.agedDark, .022, .5));
      c.drawLine(Offset(x + .016, -.38), Offset(x + .016, .38), _sp(NeferhooPalette.papyrusHi, .012, .7));
    }
    // the address: hieroglyph lines and a cartouche holding the Sphinx
    c.drawPath(lines, _sp(NeferhooPropInk.ochre, .014, .8));
    c.drawRRect(cartouche, _sp(NeferhooPropInk.ochre, .018, .95));
    c.drawLine(const Offset(-.165, .04), const Offset(-.165, .16), _sp(NeferhooPropInk.ochre, .018, .95));
    c.drawPath(sphinx, _sp(NeferhooPropInk.ochre, .014, .95));
    // the faded lapis cord, tied in a bow over the seal
    c.drawRect(const Rect.fromLTRB(-.034, -.4, .034, .4), _fp(NeferhooPropInk.lapisCord));
    c.drawLine(const Offset(-.034, -.4), const Offset(-.034, .4), _sp(NeferhooPalette.ink, .012, .8));
    c.drawLine(const Offset(.034, -.4), const Offset(.034, .4), _sp(NeferhooPalette.ink, .012, .8));
    c.drawLine(const Offset(.012, -.4), const Offset(.012, .4), _sp(NeferhooPalette.lapisLit, .012, .7));
    c.restore();
    for (final b in [tailL, tailR, bowL, bowR]) {
      c.drawPath(b, _fp(NeferhooPropInk.lapisCord));
      c.drawPath(b, _sp(NeferhooPalette.ink, .02));
    }
    c.drawLine(const Offset(-.12, -.07), const Offset(-.2, -.07), _sp(NeferhooPalette.lapisLit, .012, .6));
    c.drawLine(const Offset(.12, -.07), const Offset(.2, -.07), _sp(NeferhooPalette.lapisLit, .012, .6));
    // the gold seal with the hoopoe
    _Wax.draw(c, const Offset(0, .02), .17, gold: true, ink: .02);
    c.drawPath(outline, _sp(NeferhooPalette.ink, .035));
    // dust of four thousand years
    for (var k = 0; k < 5; k++) {
      c.drawCircle(Offset(-.39 + k * .19, .3 - (k % 2) * .05), .018, _fp(const Color(0xffb89a6a), .7));
    }
  }
}

// ---------------------------------------------------------------------------
// HINT TAGS: a lapis-and-gold plaque with an icon badge, left of the bird's
// column (clear of the lane), sized to its text

Size _measure(String s, double size, String font, FontWeight w, double spacing) => _measured.putIfAbsent('$s|$size|$font|${w.value}|$spacing', () {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontFamily: font, fontSize: size, fontWeight: w, letterSpacing: spacing)),
    textDirection: TextDirection.ltr,
  )..layout();
  final measured = tp.size;
  tp.dispose();
  return measured;
});

final _measured = <String, Size>{};

abstract final class _TagArt {
  static final _cache = <String, (ui.Picture, Size)>{};

  /// The steady-state tag recorded once at u = 1 (its text laid out once).
  static (ui.Picture, Size) get(String title, String sub, Color accent, String? icon) => _cache.putIfAbsent('$title|$sub|${accent.toARGB32()}|$icon', () {
    late Size size;
    final pic = _record('tag', (c) => size = _paint(c, Offset.zero, title, sub, 360, accent, 1, icon));
    return (pic, size);
  });

  static Size _paint(Canvas c, Offset at, String title, String sub, double h, Color accent, double alpha, String? icon) {
    final u = h / 360;
    final tw = _measure(title, 10.5 * u, 'Fredoka', FontWeight.w600, .6 * u).width;
    final sw = _measure(sub, 9 * u, 'Nunito', FontWeight.w800, 0).width;
    final w = math.min(124 * u, 33 * u + math.max(tw, sw) + 8 * u), ph = 34 * u;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, w, ph), Radius.circular(10 * u));
    c.drawRRect(r.shift(Offset(0, 2 * u)), _fp(NeferhooPalette.ink, .32 * alpha));
    c.drawRRect(r, _gp(_lg(r.outerRect.topCenter, r.outerRect.bottomCenter, [Color.lerp(NeferhooPalette.lapisShade, const Color(0xff2b2f78), .5)!.withValues(alpha: .95 * alpha), const Color(0xf21b1740).withValues(alpha: .95 * alpha)])));
    c.drawRRect(r.deflate(1.2 * u), _sp(NeferhooPalette.goldLit, 1.4 * u, alpha));
    c.drawRRect(r, _sp(NeferhooPalette.ink, 1.1 * u, .8 * alpha));
    // the icon badge
    final bc = Offset(at.dx + 17.5 * u, at.dy + ph / 2);
    c.drawCircle(bc, 12.5 * u, _fp(NeferhooPalette.ink, .85 * alpha));
    c.drawCircle(bc, 11.5 * u, _gp(_rg(bc - Offset(3 * u, 3 * u), 16 * u, [Color.lerp(accent, const Color(0xffffffff), .35)!.withValues(alpha: alpha), accent.withValues(alpha: alpha), Color.lerp(accent, NeferhooPalette.ink, .35)!.withValues(alpha: alpha)], const [0, .55, 1])));
    c.drawCircle(bc, 11.5 * u, _sp(NeferhooPalette.goldHi, 1.2 * u, alpha));
    if (icon == 'mail') {
      final e = Rect.fromCenter(center: bc, width: 14 * u, height: 9.6 * u);
      c.drawRRect(RRect.fromRectAndRadius(e, Radius.circular(1.2 * u)), _fp(NeferhooPropInk.paper, alpha));
      final v = Path()
        ..moveTo(e.left + .6 * u, e.top + .8 * u)
        ..lineTo(e.center.dx, e.center.dy + 1.2 * u)
        ..lineTo(e.right - .6 * u, e.top + .8 * u);
      c.drawPath(v, _sp(NeferhooPalette.carnShade, 1.1 * u, alpha));
      c.drawCircle(Offset(e.center.dx, e.center.dy + 1.2 * u), 1.7 * u, _fp(NeferhooPalette.carnShade, alpha));
      c.drawRRect(RRect.fromRectAndRadius(e, Radius.circular(1.2 * u)), _sp(NeferhooPalette.ink, 1.0 * u, alpha));
    } else if (icon == 'ankh') {
      _paintAnkh(c, bc, 17 * u, 0);
    }
    _text(c, title, Offset(at.dx + 33 * u, at.dy + 3.5 * u), 10.5 * u, const Color(0xfffff2c9).withValues(alpha: alpha), spacing: .6 * u);
    _text(c, sub, Offset(at.dx + 33 * u, at.dy + 17.5 * u), 9 * u, Color.lerp(accent, const Color(0xffffffff), .6)!.withValues(alpha: alpha), font: 'Nunito', weight: FontWeight.w800);
    return Size(w, ph);
  }
}

/// Draws a hint tag with its top-left at [at]. [icon]: 'mail' or 'ankh'.
/// Steady state is ONE cached-picture call (no text layout); only the .3 s
/// fade-in is drawn directly. Returns the plaque's size.
Size _paintTag(Canvas c, Offset at, String title, String sub, double h, Color accent, {double alpha = 1, String? icon}) {
  final u = h / 360;
  if (alpha >= .98) {
    final (pic, size) = _TagArt.get(title, sub, accent, icon);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(u);
    c.drawPicture(pic);
    c.restore();
    return size * u;
  }
  return _TagArt._paint(c, at, title, sub, h, accent, alpha, icon);
}

/// Where a tag of size [tag] goes so it never covers the hazard it labels,
/// the band [top]..[bottom] (pixels), nor the play screen's HUD: the hearts
/// plate ([neferhooHudPlate] on a screen of [size]) and whatever else is in
/// [clear] (the boss's health strip). The design's place first (above the
/// band at the left edge, else below it), then the same right of the plate
/// (M1: in the real play screen a high lane put the tag under the plate).
Offset _tagAt(double top, double bottom, Size size, Size tag, List<Rect> clear) {
  final h = size.height, u = h / 360;
  // (a notch or a cutout on the left: the tag starts inside the safe area)
  final inset = NeferhooScreen.insets;
  final above = top - 6 * u - tag.height;
  final below = math.min(bottom + 6 * u, h - math.max(22 * u, inset.bottom + 6 * u) - tag.height);
  final plate = neferhooHudPlate(size);
  final left = inset.left + 14 * u, right = plate.right + 6 * u;
  final places = [
    if (above >= math.max(36 * u, inset.top + 4 * u)) Offset(left, above),
    Offset(left, below),
    if (above >= math.max(4 * u, inset.top + 4 * u)) Offset(right, above),
    Offset(right, below),
  ];
  bool free(Offset at) {
    final r = at & tag;
    if (r.overlaps(plate) || (r.bottom > top && r.top < bottom)) return false;
    for (final k in clear) {
      if (r.overlaps(k)) return false;
    }
    return true;
  }

  for (final at in places) {
    if (free(at)) return at;
  }
  return places.first;
}

/// The flight HUD's hearts-and-shield plate (`MatchHealth`) on a screen of
/// [size], in px, with its lip and outline: the play screen lays its HUD
/// out on a 1000 x 450 scene fitted into the screen's safe area
/// (`SceneLayout` sits in a `SafeArea`; [insets], by default the insets the
/// game last saw, [NeferhooScreen.insets]), the plate at
/// [MatchLayout.edge], 118 x 100 scene units (measured in the real play
/// screen at 640, 800 and 864 x 360, and with notch insets:
/// `neferhoo_real_flight_test`).
Rect neferhooHudPlate(Size size, [EdgeInsets? insets]) {
  final pad = insets ?? NeferhooScreen.insets;
  final w = math.max(0.0, size.width - pad.horizontal), h = math.max(0.0, size.height - pad.vertical);
  final s = math.min(w / 1000, h / 450);
  final ox = pad.left + (w - 1000 * s) / 2, oy = pad.top + (h - 450 * s) / 2;
  const e = MatchLayout.edge;
  return Rect.fromLTWH(ox + e * s, oy + e * s, 118 * s, 100 * s).inflate(4 * s);
}

/// The flight HUD's pause key (`MatchAction`, the top row's right end,
/// [MatchLayout.height] square at [MatchLayout.edge]) on a screen of [size],
/// in px, with its lip: placed as [neferhooHudPlate] places the plate.
Rect neferhooHudPause(Size size, [EdgeInsets? insets]) {
  final pad = insets ?? NeferhooScreen.insets;
  final w = math.max(0.0, size.width - pad.horizontal), h = math.max(0.0, size.height - pad.vertical);
  final s = math.min(w / 1000, h / 450);
  final ox = pad.left + (w - 1000 * s) / 2, oy = pad.top + (h - 450 * s) / 2;
  const e = MatchLayout.edge, side = MatchLayout.height;
  return Rect.fromLTWH(ox + (1000 - e - side) * s, oy, side * s, (e + side) * s).inflate(4 * s);
}

/// The screen the game is drawn on, as the art needs it: the safe-area
/// insets (a notch, a cutout, rounded corners) the play screen's HUD keeps
/// out of. `BirdGame` sets them every frame from its widget's `MediaQuery`;
/// zero elsewhere (tests, a picture of a frame).
abstract final class NeferhooScreen {
  static EdgeInsets insets = EdgeInsets.zero;
}

// ---------------------------------------------------------------------------
// THE MAIL LANE: the address line the stream will fly. An airmail-bordered
// corridor (carnelian / cream stripes, ink keylines) with marching chevrons.
// The corridor's height is the rules' hurt band (letter half-height + the
// bird's radius): its OUTER edge is the hurt boundary.

abstract final class _LaneArt {
  static const th = .0125; // edge stripe height, h units

  static Path _stripes(double period, int phase) {
    final p = Path();
    final w = period / (period > .025 ? 3 : 2);
    for (var x = -.3 + phase * w; x < 3.6; x += period) {
      p.moveTo(x, th);
      p.lineTo(x + w, th);
      p.lineTo(x + w + th, 0);
      p.lineTo(x + th, 0);
      p.close();
    }
    return p;
  }

  static final redN = _stripes(.02, 1);
  static final redF = _stripes(.03, 0);
  static final turqF = _stripes(.03, 1);

  // chevrons "<" pointing the way the letters travel (left)
  static Path chevrons(double spacing) {
    final p = Path();
    for (var x = -spacing; x < 3.6; x += spacing) {
      p.moveTo(x + .013, -.019);
      p.lineTo(x - .007, 0);
      p.lineTo(x + .013, .019);
    }
    return p;
  }

  static final chevN = chevrons(.16), chevF = chevrons(.115);
}

void _paintMailLane(Canvas c, Size size, double laneY, double fromX, {double t = 1, bool fury = false, double alpha = 1, bool tag = true, double clock = 0, List<Rect> clear = const []}) {
  final h = size.height;
  final y = laneY;
  final band = Neferhoo.letterHalfHeight + FlightSimulation.birdRadius; // the band in which a letter hurts the bird's centre
  final x1 = fromX;
  final reveal = NeferhooKit.smooth01(t);
  final x0 = x1 - (x1 + .03) * reveal;
  if (x1 - x0 < .01) return;
  final a = alpha;
  c.save();
  c.scale(h);
  // the corridor's wash: carnelian, darker toward the bird, so it reads on
  // sand, sky and dusk alike
  final wash = Rect.fromLTRB(x0, y - band, x1, y + band);
  c.drawRect(wash, _gp(_lg(Offset(x0, 0), Offset(x1, 0), [const Color(0xffb83a34).withValues(alpha: 0), const Color(0xffb83a34).withValues(alpha: .3 * a), const Color(0xff8e2a3c).withValues(alpha: .22 * a)], const [0, .22, 1])));
  // the march: both edge stripes and the chevrons slide toward the bird
  final period = fury ? .03 : .02;
  final march = (clock * (fury ? .22 : .16)) % (period * (fury ? 1 : 1));
  for (final top in [true, false]) {
    final yy = top ? y - band : y + band - _LaneArt.th;
    final strip = Rect.fromLTRB(x0, yy, x1, yy + _LaneArt.th);
    c.save();
    c.clipRect(strip);
    c.drawRect(strip, _fp(NeferhooPropInk.paper, .95 * a));
    c.translate(-march, yy);
    c.translate(0, 0);
    c.drawPath(fury ? _LaneArt.redF : _LaneArt.redN, _fp(NeferhooPalette.carn, a));
    if (fury) c.drawPath(_LaneArt.turqF, _fp(NeferhooPalette.turq, a));
    c.restore();
    final outer = top ? y - band : y + band;
    final inner = top ? y - band + _LaneArt.th : y + band - _LaneArt.th;
    c.drawLine(Offset(x0, outer), Offset(x1, outer), _sp(NeferhooPalette.ink, .0042, .75 * a, StrokeCap.butt));
    c.drawLine(Offset(x0, inner), Offset(x1, inner), _sp(NeferhooPalette.ink, .0022, .5 * a, StrokeCap.butt));
  }
  // chevrons marching toward the bird
  c.save();
  c.clipRect(Rect.fromLTRB(x0, y - band + _LaneArt.th, x1 - .02, y + band - _LaneArt.th));
  c.translate(-(clock * .18) % (fury ? .115 : .16) + 0, y);
  final ch = fury ? _LaneArt.chevF : _LaneArt.chevN;
  c.drawPath(ch, _sp(NeferhooPalette.ink, .0165, .62 * a));
  c.drawPath(ch, _sp(NeferhooPropInk.paper, .0085, .95 * a));
  c.drawPath(ch, _sp(NeferhooPalette.carn, .0028, .9 * a));
  c.restore();
  // the postal slot at his wingtip, where the letters come out
  if (reveal > .5) {
    final slot = RRect.fromRectAndRadius(Rect.fromLTRB(x1 - .006, y - band, x1 + .012, y + band), const Radius.circular(.007));
    c.drawRRect(slot, _fp(NeferhooPalette.carnShade, .95 * a));
    c.drawRRect(slot, _sp(NeferhooPalette.ink, .0042, .85 * a));
    c.drawLine(Offset(x1 + .003, y - band * .62), Offset(x1 + .003, y + band * .62), _sp(NeferhooPropInk.paper, .0055, .95 * a));
  }
  c.restore();
  if (tag && t > .3) {
    final label = fury ? 'EXPRESS POST' : 'MAIL CALL';
    final accent = fury ? NeferhooPalette.turq : NeferhooPalette.carn;
    final (_, ts) = _TagArt.get(label, 'Shoot them back!', accent, 'mail');
    _paintTag(c, _tagAt((y - band) * h, (y + band) * h, size, ts * (h / 360), clear), label, 'Shoot them back!', h, accent, alpha: alpha * NeferhooKit.ramp(t, .3, .6), icon: 'mail');
  }
}

// ---------------------------------------------------------------------------
// THE ANKH TELEGRAPH: the whole loop (out, the turn, back), the two passes at
// the bird's column numbered 1 and 2. The loop is rules geometry (ankhLoop);
// the bands are the ankh's hurt reach (ankh radius + the bird's radius).

class _Loop {
  _Loop(this.out, this.turn, this.back, this.l0, this.l1, this.total, this.arrows);
  final Path out, turn, back;
  final double l0, l1, total;
  final List<(Offset, double)> arrows;
}

abstract final class _LoopArt {
  static final _cache = <String, _Loop>{};

  /// The arrow at fraction [f] of the loop (.16 .5 .84 .3 .7 are cached).
  static (Offset, double) arrowAt(_Loop l, double f) => l.arrows[const [.16, .5, .84, .3, .7].indexOf(f)];

  static _Loop get(double fromX, double yA, double yB, {required bool dots}) {
    final key = '${fromX.toStringAsFixed(4)}|${yA.toStringAsFixed(4)}|${yB.toStringAsFixed(4)}|$dots';
    if (_cache.length > 12) _cache.clear();
    return _cache.putIfAbsent(key, () => _build(fromX, yA, yB, dots));
  }

  static _Loop _build(double fromX, double yA, double yB, bool dots) {
    const n = 360;
    final pts = NeferhooFx.ankhLoop(fromX, yA, yB, n: n);
    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
    }
    final total = cum.last;
    final turnX = FlightSimulation.birdX - Neferhoo.ankhBehind;
    final l0 = fromX - turnX, l1 = l0 + math.pi * (yB - yA).abs() / 2;
    Offset at(double s) {
      s = s.clamp(0.0, total);
      var lo = 0, hi = cum.length - 1;
      while (hi - lo > 1) {
        final m = (lo + hi) >> 1;
        if (cum[m] <= s) {
          lo = m;
        } else {
          hi = m;
        }
      }
      final span = cum[hi] - cum[lo];
      final k = span == 0 ? 0.0 : (s - cum[lo]) / span;
      return Offset.lerp(pts[lo], pts[hi], k)!;
    }
    final out = Path(), turn = Path(), back = Path();
    final dash = dots ? .0 : .02, gap = dots ? .02 : .0135;
    for (var s = .004; s < total - .01; s += dash + gap) {
      final sec = s < l0 ? out : (s < l1 ? turn : back);
      final p0 = at(s);
      sec.moveTo(p0.dx, p0.dy);
      if (dots) {
        sec.lineTo(p0.dx + .0001, p0.dy);
      } else {
        for (final q in [.33, .66, 1.0]) {
          final p = at(s + dash * q);
          sec.lineTo(p.dx, p.dy);
        }
      }
    }
    final arrows = <(Offset, double)>[];
    for (final f in const [.16, .5, .84, .3, .7]) {
      final s = total * f;
      final a = at(s - .008), b = at(s + .008);
      arrows.add((at(s), math.atan2((b - a).dy, (b - a).dx)));
    }
    return _Loop(out, turn, back, l0, l1, total, arrows);
  }
}

/// Strokes the revealed part of a cached loop: [f] arc length shown.
void _drawLoop(Canvas c, _Loop l, double fromX, double yA, double yB, double f, Paint ink, Paint paint) {
  final turnX = FlightSimulation.birdX - Neferhoo.ankhBehind;
  final r = (yB - yA).abs() / 2, sign = yB > yA ? 1.0 : -1.0;
  final cy = (yA + yB) / 2;
  void both(Path p) {
    c.drawPath(p, ink);
    c.drawPath(p, paint);
  }
  // out leg
  if (f > 0) {
    if (f >= l.l0) {
      both(l.out);
    } else {
      c.save();
      c.clipRect(Rect.fromLTRB(fromX - f, math.min(yA, yB) - .05, fromX + .02, math.max(yA, yB) + .05));
      both(l.out);
      c.restore();
    }
  }
  // the turn
  if (f > l.l0) {
    if (f >= l.l1) {
      both(l.turn);
    } else {
      final a = (f - l.l0) / r;
      final yc = cy - sign * r * math.cos(a);
      c.save();
      c.clipRect(Rect.fromLTRB(turnX - r - .05, math.min(yA, yc) - .02, turnX + .05, math.max(yA, yc) + .02));
      both(l.turn);
      c.restore();
    }
  }
  // back along the second lane
  if (f > l.l1) {
    if (f >= l.total) {
      both(l.back);
    } else {
      c.save();
      c.clipRect(Rect.fromLTRB(turnX - .02, math.min(yA, yB) - .05, turnX + (f - l.l1) + .005, math.max(yA, yB) + .05));
      both(l.back);
      c.restore();
    }
  }
}

void _plate(Canvas c, Offset bc, double rr, String n, bool turq, double a) {
  final lit = turq ? NeferhooPalette.turqLit : NeferhooPalette.goldHi, mid = turq ? NeferhooPalette.turq : NeferhooPalette.goldLit, dark = turq ? NeferhooPalette.turqShade : NeferhooPalette.gold;
  c.drawCircle(bc, rr * 1.12, _fp(NeferhooPalette.ink, .85 * a));
  c.drawCircle(bc, rr, _gp(_rg(bc - Offset(rr * .3, rr * .3), rr * 1.5, [lit.withValues(alpha: a), mid.withValues(alpha: a), dark.withValues(alpha: a)], const [0, .5, 1])));
  _Font.draw(c, n, bc, rr * 1.1, NeferhooPalette.ink, rr * .26, a);
}

void _paintAnkhTelegraph(Canvas c, Size size, double fromX, double yA, {double t = 1, double alpha = 1, bool fury = false, bool tag = true, double? yB, List<Rect> clear = const []}) {
  final h = size.height;
  final yBack = yB ?? Neferhoo.backLane(yA);
  final e = NeferhooKit.smooth01(t);
  final a = alpha;
  final loop1 = _LoopArt.get(fromX, yA, yBack, dots: false);
  final reach = Neferhoo.ankhRadius + FlightSimulation.birdRadius; // where the ankh can hurt the bird's centre
  c.save();
  c.scale(h);
  // the two crossing bands at the bird's column
  for (final (yy, k) in [(yA, 0), (yBack, 1)]) {
    final band = RRect.fromRectAndRadius(Rect.fromLTRB(FlightSimulation.birdX - .09, yy - reach, FlightSimulation.birdX + .09, yy + reach), Radius.circular(reach));
    c.drawRRect(band, _fp(NeferhooPalette.goldLit, (.2 + k * .03) * a * e));
    c.drawRRect(band, _sp(NeferhooPalette.ink, .0085, .6 * a * e));
    c.drawRRect(band, _sp(NeferhooPalette.goldHi, .0045, .95 * a * e));
  }
  // the loop: gold dashes with an ink keyline; fury adds a turquoise dotted twin
  final ink = _sp(NeferhooPalette.ink, .0158, .62 * a, StrokeCap.round);
  final gold = _sp(NeferhooPalette.goldHi, .0078, a);
  _drawLoop(c, loop1, fromX, yA, yBack, loop1.total * e, ink, gold);
  if (fury) {
    final loop2 = _LoopArt.get(fromX, yBack, yA, dots: true);
    _drawLoop(c, loop2, fromX, yBack, yA, loop2.total * e, _sp(NeferhooPalette.ink, .0145, .55 * a), _sp(NeferhooPalette.turqLit, .0095, a));
    // the second ankh runs the loop the other way round: its own arrows
    for (final f in const [.3, .7]) {
      if (loop2.total * e < loop2.total * f) continue;
      final (pos, ang) = _LoopArt.arrowAt(loop2, f);
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(ang);
      final p = Path()
        ..moveTo(.022, 0)
        ..lineTo(-.012, -.016)
        ..lineTo(-.005, 0)
        ..lineTo(-.012, .016)
        ..close();
      c.drawPath(p, _fp(NeferhooPalette.turqLit, a));
      c.drawPath(p, _sp(NeferhooPalette.ink, .005, a));
      c.restore();
    }
  }
  // direction arrows: out, the turn, back
  for (var i = 0; i < 3; i++) {
    final (pos, ang) = loop1.arrows[i];
    if (loop1.total * e < loop1.total * [.16, .5, .84][i]) continue;
    c.save();
    c.translate(pos.dx, pos.dy);
    c.rotate(ang);
    final p = Path()
      ..moveTo(.024, 0)
      ..lineTo(-.014, -.019)
      ..lineTo(-.006, 0)
      ..lineTo(-.014, .019)
      ..close();
    c.drawPath(p, _fp(NeferhooPalette.goldLit, a));
    c.drawPath(p, _sp(NeferhooPalette.ink, .0055, a));
    c.restore();
  }
  c.restore();
  // the pass numbers, on round plates beside the bands (fury: a turquoise
  // plate beside each for the second ankh, whose passes come in the other order)
  for (final (yy, k) in [(yA, 0), (yBack, 1)]) {
    _plate(c, Offset((FlightSimulation.birdX + .118) * h, yy * h), .026 * h, k == 0 ? '1' : '2', false, a * e);
    if (fury) _plate(c, Offset((FlightSimulation.birdX + .19) * h, yy * h), .021 * h, k == 0 ? '2' : '1', true, a * e);
  }
  if (tag && t > .3) {
    final label = fury ? 'TWO ANKHS' : 'THE ANKH';
    final (_, ts) = _TagArt.get(label, 'It comes back!', NeferhooPalette.gold, 'ankh');
    _paintTag(c, _tagAt(math.min(yA, yBack) * h - reach * h, math.max(yA, yBack) * h + reach * h, size, ts * (h / 360), clear), label, 'It comes back!', h, NeferhooPalette.gold, alpha: alpha * NeferhooKit.ramp(t, .3, .6), icon: 'ankh');
  }
}

// ---------------------------------------------------------------------------
// THE RETURNED LETTER and the payoff burst

/// A returned letter homing into the boss's chest: from where it was struck
/// ([from]) to the chest ([to]) on the rules' quadratic curve, [k] 0..1 of its
/// flight. It turns a full circle (the label slams on at the catch and is
/// upright on arrival), trails a turquoise ribbon with gold dust and two
/// afterimages. Screen fractions in, [h] pixels tall.
void _paintReturnedLetter(Canvas c, Offset from, Offset to, double h, double k) {
  // (the rules' curve: NeferhooLetter.returnAt)
  final ctrl = Offset(from.dx + Neferhoo.returnControl.$1, from.dy + Neferhoo.returnControl.$2);
  Offset at(double t) => Offset(
    (1 - t) * (1 - t) * from.dx + 2 * (1 - t) * t * ctrl.dx + t * t * to.dx,
    (1 - t) * (1 - t) * from.dy + 2 * (1 - t) * t * ctrl.dy + t * t * to.dy,
  );
  Offset px(Offset q) => Offset(q.dx * h, q.dy * h);
  double tiltAt(double kk) => -math.pi * 2 * NeferhooKit.smooth01(kk / .85);
  // the catch: a ring where the rock met it, and a U-turn arrow (it turns round)
  if (k < .26) {
    final f = math.pow(k / .26, .8).toDouble(), q = px(from);
    c.drawCircle(q, h * (.02 + .06 * math.min(1.0, k / .15)), _sp(NeferhooPalette.ink, h * .008, .4 * (1 - f)));
    c.drawCircle(q, h * (.02 + .06 * math.min(1.0, k / .15)), _sp(NeferhooPalette.goldHi, h * .0045, (1 - f)));
    final r = h * .045;
    final arc = Rect.fromCircle(center: q + Offset(h * .01, -h * .045), radius: r);
    c.drawArc(arc, math.pi * .15, math.pi * 1.45, false, _sp(NeferhooPalette.ink, h * .011, .55 * (1 - f)));
    c.drawArc(arc, math.pi * .15, math.pi * 1.45, false, _sp(NeferhooPalette.goldHi, h * .0065, (1 - f)));
    final tip = arc.center + Offset(math.cos(math.pi * 1.6), math.sin(math.pi * 1.6)) * r;
    final head = Path()
      ..moveTo(tip.dx + h * .016, tip.dy + h * .004)
      ..lineTo(tip.dx - h * .012, tip.dy - h * .012)
      ..lineTo(tip.dx - h * .008, tip.dy + h * .014)
      ..close();
    c.drawPath(head, _fp(NeferhooPalette.goldHi, 1 - f));
    c.drawPath(head, _sp(NeferhooPalette.ink, h * .003, (1 - f) * .8));
  }
  // the ribbon: the last .45 of the curve
  final t0 = math.max(0.0, k - .45);
  final pts = [for (var i = 0; i <= 12; i++) px(at(t0 + (k - t0) * i / 12))];
  _ribbon(c, pts, h * .03, NeferhooPalette.magic, NeferhooPalette.turqLit);
  for (var i = 1; i <= 3 && pts.length > 4; i++) {
    final q = pts[(pts.length * i / 4.2).floor()];
    final j = Offset((_h01(i * 11) - .5) * h * .016, (_h01(i * 11 + 1) - .5) * h * .02);
    c.drawPath(_star(q + j, h * (.0095 - i * .0016), math.pi / 5 * i), _fp(NeferhooPalette.goldHi, .95 - i * .2));
  }
  // two afterimages: the letter's shape in turquoise
  for (var i = 2; i >= 1; i--) {
    final kk = k - i * .055;
    if (kk < 0) continue;
    c.save();
    final q = px(at(kk));
    c.translate(q.dx, q.dy);
    c.rotate(tiltAt(kk));
    c.scale(h / 360);
    c.drawRRect(_LetterArt.rr, _fp(NeferhooPalette.turqLit, .2 / i));
    c.restore();
  }
  final p = px(at(k));
  _paintLetter(c, p, h, tilt: tiltAt(k), returned: .08 + .92 * NeferhooKit.ramp(k, 0, .2));
}

/// The burst where a returned letter lands on the chest: a flash, two shock
/// rings, a boxed RETURN TO SENDER postmark slammed over it, paper confetti
/// (torn papyrus, wax chips, a perforated stamp), gold glints and the damage
/// number popping above. [t] 0..1 of its life (about .6 s); all seeded.
void _paintReturnBurst(Canvas c, Offset at, double h, double t, {int damage = 25, bool reduced = false}) {
  // (Reduced Motion: no flash, rings, confetti or glints; the postmark and
  // the damage simply show and fade)
  final o = Offset(at.dx * h, at.dy * h);
  final e = 1 - math.pow(1 - t, 3).toDouble();
  c.save();
  c.translate(o.dx, o.dy);
  c.scale(h / 360);
  // flash: a gold star and impact ticks, over in the first third
  if (!reduced && t < .32) {
    final k = t / .32;
    final f = 1 - k;
    c.drawPath(_star(Offset.zero, 44 + 34 * k, .35), _fp(NeferhooPalette.goldHi, .92 * f));
    c.drawPath(_star(Offset.zero, 26 + 20 * k, .35 + math.pi / 4), _fp(const Color(0xffffffff), .9 * f));
    final ticks = Path();
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + .2;
      final d = Offset(math.cos(a), math.sin(a));
      ticks.moveTo(d.dx * (22 + 22 * k), d.dy * (22 + 22 * k));
      ticks.lineTo(d.dx * (40 + 40 * k), d.dy * (40 + 40 * k));
    }
    c.drawPath(ticks, _sp(NeferhooPalette.ink, 5.4, .5 * f));
    c.drawPath(ticks, _sp(NeferhooPalette.goldHi, 3.2, .95 * f));
    c.drawCircle(Offset.zero, 14 * f + 3, _fp(const Color(0xffffffff), .95 * f));
  }
  // two shock rings (an ink keyline under the gold so it reads on cream)
  if (!reduced) {
    final r1 = 14 + 70 * e;
    c.drawCircle(Offset.zero, r1, _sp(NeferhooPalette.ink, 8 * (1 - e) + .8, .35 * (1 - e)));
    c.drawCircle(Offset.zero, r1, _sp(NeferhooPalette.goldLit, 6 * (1 - e) + .6, 1 - e));
    final e2 = 1 - math.pow(1 - math.min(1.0, t * 1.3), 2).toDouble();
    c.drawCircle(Offset.zero, 8 + 48 * e2, _sp(NeferhooPalette.magic, 3.6 * (1 - e2) + .4, .9 * (1 - e2)));
  }
  // the postmark slam: big, then home with a small bounce, then it fades
  {
    final slam = reduced ? 1.0 : (t < .12 ? 2.3 - 1.3 * NeferhooKit.smooth01(t / .12) : 1.0 + .08 * math.sin(math.pi * NeferhooKit.ramp(t, .12, .3)) * (1 - NeferhooKit.ramp(t, .12, .3)));
    final a = 1 - NeferhooKit.ramp(t, .7, 1);
    c.save();
    c.translate(17, 19);
    c.rotate(-.2);
    c.scale(slam * 1.4);
    _LetterArt.paintLabel(c, a * NeferhooKit.smooth01(t / .05));
    c.restore();
  }
  // confetti, in batched paths (papyrus light, papyrus shade, wax, stamp bits)
  final fade = 1 - NeferhooKit.ramp(t, .55, 1);
  if (!reduced && fade > 0) {
    final light = Path(), shade = Path(), wax = Path(), blue = Path();
    for (var i = 0; i < 8; i++) {
      final ang = ((i * .618034) % 1.0) * math.pi * 2 + .3;
      final spd = 58 + 52 * _h01(i + 40);
      final pos = Offset(math.cos(ang), math.sin(ang) * .82) * spd * e + Offset(0, 42 * t * t);
      final rot = ang + t * (3 + 5 * _h01(i + 70)) * (i.isEven ? 1 : -1);
      final cr = math.cos(rot), sr = math.sin(rot);
      final z = 1.0 + .35 * _h01(i + 99);
      Offset rp(double x, double y) => pos + Offset(x * cr - y * sr, x * sr + y * cr) * z;
      switch (i % 4) {
        case 0:
          light.addPolygon([rp(-3.8, -2.5), rp(3.8, -2.5), rp(3.8, 2.5), rp(-3.8, 2.5)], true);
        case 1:
          shade.addPolygon([rp(-4.0, 2.6), rp(0, -3.8), rp(3.6, 1.6)], true);
        case 2:
          wax.addOval(Rect.fromCircle(center: pos, radius: 2.4 * z));
        default:
          blue.addPolygon([rp(-2.4, -2.8), rp(2.4, -2.8), rp(2.4, 2.8), rp(-2.4, 2.8)], true);
      }
    }
    for (final pth in [light, shade, wax, blue]) {
      c.drawPath(pth, _sp(NeferhooPalette.ink, 2.0, .85 * fade));
    }
    c.drawPath(light, _fp(NeferhooPalette.papyrusHi, fade));
    c.drawPath(shade, _fp(NeferhooPalette.papyrusShade, fade));
    c.drawPath(wax, _fp(NeferhooPalette.carn, fade));
    c.drawPath(blue, _fp(NeferhooPalette.lapis, fade));
    // gold glints
    final glints = Path();
    for (var i = 0; i < 5; i++) {
      final ang = i * math.pi * 2 / 5 + .8;
      final r = 30 + 52 * e;
      glints.addPath(_star(Offset(math.cos(ang), math.sin(ang)) * r, 7 * (.5 + .5 * math.sin(t * 18 + i * 2).abs()), i * .4), Offset.zero);
    }
    c.drawPath(glints, _sp(NeferhooPalette.ink, 1.2, .5 * fade));
    c.drawPath(glints, _fp(NeferhooPalette.goldHi, fade));
  }
  // the damage: pops big, settles, rises a little, then fades
  final pop = reduced ? 1.0 : (t < .1 ? 1.45 * NeferhooKit.smooth01(t / .1) : 1.45 - .45 * NeferhooKit.smooth01((t - .1) / .16));
  final al = 1 - NeferhooKit.ramp(t, .72, 1);
  c.save();
  // over his wing (dark, so the gold number reads), never over his face
  c.translate(58, -42 - 14 * (reduced ? 0 : e));
  c.scale(pop);
  _text(c, '-$damage', const Offset(1.5, 2.5), 26, NeferhooPalette.ink.withValues(alpha: .45 * al), center: true, outline: NeferhooPalette.ink.withValues(alpha: .45 * al), outlineWidth: 7);
  _text(c, '-$damage', Offset.zero, 26, NeferhooPalette.goldHi.withValues(alpha: al), center: true, outline: NeferhooPalette.ink.withValues(alpha: al), outlineWidth: 7);
  c.restore();
  c.restore();
}


/// The lost letter on its own (for the defeat's "the lost letter is found"
/// and the keepsake): [width] px across, centred at [o], a faint gold glow of
/// strength [glow] 0..1 and drifting motes. [alpha] < 1 fades it through one
/// small bounded layer. Pure in its arguments; [phase] is seconds.
void _paintLostLetter(Canvas c, Offset o, double width, {double tilt = -.18, double glow = 1, double alpha = 1, double phase = 0}) {
  final s = width / 1.08;
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(tilt);
  c.scale(s);
  if (alpha < .98) c.saveLayer(const Rect.fromLTRB(-1.2, -1.2, 1.2, 1.2), Paint()..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0)));
  final pulse = 1 + .05 * math.sin(phase * 2.2);
  c.save();
  c.scale(1.12 * pulse);
  c.drawCircle(Offset.zero, 1, Paint()..shader = _RigProps.glowGold.shader..color = Color.fromRGBO(0, 0, 0, glow.clamp(0.0, 1.0)));
  c.restore();
  c.drawPicture(_LostArt.picture);
  final motes = Path();
  for (var i = 0; i < 6; i++) {
    final t = ((phase * .22 + i / 6) % 1.0);
    motes.addOval(Rect.fromCircle(center: Offset((_h01(i * 5) - .5) * 1.3 + math.sin(phase * 1.4 + i) * .06, .3 - t * 1.0), radius: .022 + .014 * _h01(i * 5 + 2)));
  }
  c.drawPath(motes, _fp(NeferhooPalette.goldHi, .8 * glow));
  if (alpha < .98) c.restore();
  c.restore();
}
