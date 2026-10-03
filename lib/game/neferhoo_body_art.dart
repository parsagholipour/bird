// The Mummy Courier's body art (r2-body detail pass): the linen wraps with
// their weave, patches, cut ends and cinnamon plumage glimpses; the faint
// turquoise address glyphs; the wesekh collar; the tooled-leather satchel
// with its lapis enamel badge and dead letters; the strap; the legs (c1-legs, the
// connection pass): a wrapped, feathered thigh that is part of the belly's own
// skin, a banded shin, a backward-bending ankle, a slate tarsus with a gold
// anklet and a bold three-toe foot.
//
// Polish round (f2-body): the far leg grows out of the belly like the near one (a
// second thigh bulge, the satchel lifted clear of it), the feet are King Coo's
// idiom (a stout tarsus, three short tapering toes in a tight Y, a short hind toe,
// small dark claws, ONE filled shape with ONE ink outline), the stamp pad and the
// target ring are the strongest mark on the chest, the wraps are one layout of
// layered strips of varied width, and EVERY object exists at both levels of detail
// (the play level only batches, thins and drops texture: M4).
//
// Iteration 5 (i3-body, the review's "life and finish"): m5 the wraps no longer read as
// pinstripes (the same 13 winds, but every third is turned 18 degrees so they cross, two are
// broad, the turned and broad ones are major winds with dark seams and the rest faint, two ends
// taper to a point: `_buildStrips`), M4 the stamp pad and ring answer the open-sky gag (`buff`:
// the pad flexes under the wingtip and a sparkle twinkles with every wipe; `glint`: a gleam runs
// along the ring), m1 the target (pad, ring, seal, inscription) is gone from a beaten old
// bird's belly (`_target`), m4 the bag's carnelian is ~10 % less chroma (`NeferhooBodyInk.bag*`), m6 the
// satchel badge is lapis enamel like the brow badge, so teal means only "magic".
//
// House technique (see the Ember Dragon's hide): everything static is built
// ONCE into a cached `ui.Picture` / `Path` (the wraps, the collar, the
// satchel's leather, the strap), everything pose-driven is a handful of
// paths drawn on top (glyph glow, the unwrap opening, loose strip ends, the
// satchel's flap and letters, the legs). No saveLayer, no blur, no random
// (a seeded hash), one clip per layer at most.
//
// Reference notes (see HANDOFF.md): wesekh = 2-15 rows of tubular beads in
// curved rows closed by a row of teardrop pendants, with falcon/lotus
// terminals; mummy linen = strips 8-20 cm wide wound from the extremities
// with crossing diagonals, resin-stiffened, herringbone/lozenge patterns in
// the late periods; hoopoe = cinnamon-pink head/breast/mantle fading to a
// whitish belly with dark streaks on the flanks, black-and-white barred
// wings/tail; Egyptian leatherwork = incised/tooled borders, red-dyed skins,
// stitched seams; faience = a glassy turquoise glaze that pools darker at
// edges and crazes in hairlines.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';
import 'neferhoo_rig.dart';


/// Colours the body needs beyond [Mu] (all in the same families).
abstract final class NeferhooBodyInk {
  static const linenWarmHi = Color(0xfffaf1e0);
  static const linenWarm = Color(0xffeadfca);
  static const linenWarmShade = Color(0xffc7b8a4);
  static const linenCoolHi = NeferhooPalette.linenLit;
  static const linenCool = NeferhooPalette.linen;
  static const linenCoolShade = NeferhooPalette.linenShade;
  static const linenLine = Color(0xff5f5680); // the shadow line under a strip (between linenDeep and ink)
  static const playCool = Color(0xffe3dcee); // the play level's cool and aged-warm strips (told apart by value at 1x)
  static const playWarm = Color(0xffeee2cb);
  static const lip = Color(0xfffffaf0); // a strip's lit top lip: warm white
  static const gapShade = Color(0xff9a90b6); // the shade under the cloth where a turned wind leaves a wedge open (m5)
  /// The wipe's rate (rad/s of `NeferhooPose.phase`) the pad's flex and sparkle follow while `buff` > 0.
  static const buffWipe = 2 * math.pi * 3.0; // = NeferhooWingArt.wipeHz (3 Hz): the pad flexes in step with the wingtip
  static const seam = Color(0xff453b66); // a MAJOR wind's seam: between linenLine and the ink (m5)
  static const thread = Color(0xfff6e4bd);
  static const threadDark = Color(0xffa98a5c);
  static const rim = NeferhooPalette.rim;
  // leather and the carnelian of the body (the bag, its flap, the straps, the collar's red row and
  // pendants). i3-body, m4: a ~10 % chroma cut of NeferhooPalette.carn* (the review's mock values: the bag's saturation
  // .62 -> .56 at 1x), so the bag stays the one warm accent without outshouting the face. It lives HERE and
  // not in NeferhooPalette.carn*, which the mail lane, the wax seals and the express border (props) also read: the lane is
  // a danger telegraph and went muddy with the cut (measured, HANDOFF).
  static const bagLit = Color(0xfff7a388);
  static const bag = Color(0xffd95f50);
  static const bagShade = Color(0xffa33d3b);
  static const bagDeep = Color(0xff6b262c);
  // (the same ~12 % cut for the flap's lit top and the worn edges, so they do not stay hot)
  static const leatherHi = Color(0xffe97c69);
  static const leatherWorn = Color(0xffeba992);
  static const leatherDark = Color(0xff8a303a);
  // brass
  static const brassHi = NeferhooPalette.goldHi;
  // legs
  static const legLit = Color(0xffa69dc0);
  static const leg = Color(0xff8a819f);
  static const legShade = Color(0xff463d60);
  static const legFar = Color(0xff6c6388);
  static const claw = NeferhooPalette.barBlack;
  // hoopoe belly
  static const creamBelly = Color(0xfff7e8d2);
  static const streak = Color(0xff7a4630);
}

Paint _fill(Color c, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
Paint _stroke(Color c, double w, [double a = 1, StrokeCap cap = StrokeCap.round]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0))
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = cap
  ..strokeJoin = StrokeJoin.round;
Paint _shade(ui.Shader s) => Paint()
  ..isAntiAlias = true
  ..shader = s;
List<double>? _even(int n) => n <= 2 ? null : [for (var i = 0; i < n; i++) i / (n - 1)];
ui.Shader _lg(Offset a, Offset b, List<Color> cs, [List<double>? st]) => ui.Gradient.linear(a, b, cs, st ?? _even(cs.length));
ui.Shader _rg(Offset c, double r, List<Color> cs, [List<double>? st]) => ui.Gradient.radial(c, r, cs, st ?? _even(cs.length));

/// A seeded hash in [0, 1): all the "randomness" of the art.
double _hash(int n) {
  final x = math.sin(n * 12.9898 + 4.1414) * 43758.5453;
  return x - x.floorToDouble();
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// [src] cut into dashes: stitches, drawn with one stroke call.
Path _dashed(Path src, double dash, double gap, {double offset = 0}) {
  final out = Path();
  for (final m in src.computeMetrics()) {
    var d = offset;
    while (d < m.length) {
      final e = math.min(d + dash, m.length);
      if (e > d) out.addPath(m.extractPath(d, e), Offset.zero);
      d += dash + gap;
    }
  }
  return out;
}

/// A strip of cloth: a centre line with a half width at each sample.
class _Band {
  _Band(this.center, this.half);
  final List<Offset> center;
  final List<double> half;

  /// The line at [frac] across the width (-1 top edge .. 1 bottom edge).
  List<Offset> line(double frac) {
    final out = <Offset>[];
    final n = center.length;
    for (var i = 0; i < n; i++) {
      final a = center[math.max(0, i - 1)], b = center[math.min(n - 1, i + 1)];
      var d = b - a;
      final len = d.distance;
      d = len == 0 ? const Offset(1, 0) : d / len;
      out.add(center[i] + Offset(-d.dy, d.dx) * (half[i] * frac));
    }
    return out;
  }

  late final List<Offset> top = line(-1), bottom = line(1);

  Path get shape {
    final p = NeferhooKit.smoothPath(top, close: false);
    p.extendWithPath(NeferhooKit.smoothPath(bottom.reversed.toList(), close: false), Offset.zero);
    p.close();
    return p;
  }
}

/// The centre line of a wound strip: y = y0 + slope x + a sag.
double _windY(double x, double y0, double slope, double bow, double x0, double x1) {
  final xm = (x0 + x1) / 2, hw = (x1 - x0) / 2;
  final u = (x - xm) / hw;
  return y0 + slope * x + bow * (1 - u * u);
}

/// A band running left to right: narrowing where it turns away at the body's
/// edges (the foreshortening that makes it wrap).
_Band _wind({
  required double y0,
  required double slope,
  required double half,
  double bow = .1,
  double x0 = -1.9,
  double x1 = 2.0,
  int n = 32,
  double shift = 0,
  double shiftFrom = .3,
  double tilt = 0,
  double pivotX = _windPivot,
  double? spanFrom,
  double? spanTo,
  double taperL = 0,
  double taperR = 0,
}) {
  // [spanFrom, spanTo] is the run the bow is laid over (a cut or tucked wind keeps the line it would have
  // had if it ran the whole width: only its ends move)
  final sf = spanFrom ?? x0, st = spanTo ?? x1;
  final pts = <Offset>[], hs = <double>[];
  for (var i = 0; i <= n; i++) {
    final x = _lerp(x0, x1, i / n);
    var y = _windY(x, y0, slope, bow, sf, st);
    if (shift != 0 && x < shiftFrom) y += shift * NeferhooKit.smooth01((shiftFrom - x) / (shiftFrom + 1.4));
    pts.add(Offset(x, y));
    final f = math.sqrt(math.max(0, 1 - math.pow((x - .15) / 1.62, 2)));
    // a TAPERED end (m5): the cloth narrows to a point over the last [taperL] / [taperR] units, the way a strip
    // cut on the slant ends; it reads as an end at 1x where a square one is lost in the seam
    var tp = 1.0;
    if (taperL > 0) tp = math.min(tp, NeferhooKit.smooth01((x - x0) / taperL));
    if (taperR > 0) tp = math.min(tp, NeferhooKit.smooth01((x1 - x) / taperR));
    hs.add(half * (.5 + .5 * f) * (.06 + .94 * tp));
  }
  if (tilt != 0) {
    // the wind is turned about a point under the bag (hidden): its far end rides up over (or dives under)
    // its neighbour, so what shows of it is a different slope
    final pv = Offset(pivotX, _windY(pivotX, y0, slope, bow, sf, st));
    for (var i = 0; i < pts.length; i++) {
      pts[i] = NeferhooKit.rot(pts[i], tilt, pv);
    }
  }
  return _Band(pts, hs);
}

/// A frayed cloth end: teeth along the end of a band running along [dir].
Path _frayEnd(Offset at, double dir, double halfW, int seed) {
  final d = Offset(math.cos(dir), math.sin(dir));
  final nr = Offset(-d.dy, d.dx);
  final p = Path()..moveTo((at - nr * halfW).dx, (at - nr * halfW).dy);
  const teeth = 6;
  for (var k = 0; k < teeth; k++) {
    final t0 = k / teeth, t1 = (k + .5) / teeth, t2 = (k + 1) / teeth;
    final len = .05 + .09 * _hash(seed + k * 3);
    final a = at + nr * (_lerp(-halfW, halfW, t1));
    p.lineTo((at + nr * _lerp(-halfW, halfW, t0)).dx, (at + nr * _lerp(-halfW, halfW, t0)).dy);
    p.lineTo((a + d * len).dx, (a + d * len).dy);
    p.lineTo((at + nr * _lerp(-halfW, halfW, t2)).dx, (at + nr * _lerp(-halfW, halfW, t2)).dy);
  }
  return p;
}

/// A thigh "trouser" hanging from the belly at [hip]: a plump drumstick that
/// starts well inside the body (so a union with it has no seam), tapers toward
/// the shin and ends in a hem of three feather scallops. [s] scales it (the far
/// thigh is smaller). [drop] lowers the hem (the far thigh's fringe).
Path _thigh(Offset hip, double s, {double drop = 0, int n = 2, double half = .19}) {
  final hx = hip.dx, hy = hip.dy;
  final y0 = hy + (.18 + drop) * s;
  final w = half * s;
  // the flanks leave the belly's own contour TANGENTIALLY (they start well inside
  // the body and cross its outline at < 20 degrees, so the union has no cusp)
  final p = Path()
    ..moveTo(hx - .62 * s, hy - .14)
    ..cubicTo(hx - .40 * s, hy - .02, hx - .20 * s, hy + .05, hx - w, y0);
  // the hem: scallops, left to right (the feather tips hang down)
  for (var i = 0; i < n; i++) {
    final x0 = hx - w + i * (2 * w / n), x1 = x0 + 2 * w / n;
    p.quadraticBezierTo((x0 + x1) / 2, y0 + .18 * s, x1, y0);
  }
  return p
    ..cubicTo(hx + .20 * s, hy + .05, hx + .40 * s, hy - .02, hx + .62 * s, hy - .14)
    ..close();
}

/// The far thigh is a smaller copy of the near one (depth).
const _farS = .85;

/// Records [draw] once into a picture (the cached layers).
ui.Picture _capture(void Function(Canvas) draw) => NeferhooKit.record(draw);

/// Built-once geometry, pictures and shaders.
abstract final class _Geo {
  static const bodyPts = [
    Offset(-1.1, -.82),
    Offset(-.4, -1.16),
    Offset(.5, -1.05),
    Offset(1.25, -.55),
    Offset(1.62, .02),
    Offset(1.3, .5),
    Offset(.6, .9),
    Offset(-.35, 1.02),
    Offset(-1.1, .68),
    Offset(-1.36, -.08),
  ];
  static const neckPts = [
    Offset(-1.55, -1.25),
    Offset(-.95, -1.75),
    Offset(-.25, -1.45),
    Offset(-.05, -.75),
    Offset(-.75, -.45),
    Offset(-1.3, -.6),
  ];
  /// The belly WITH both thighs: one skin, one outline. Each thigh (the wrapped,
  /// feathered "trouser") is a bulge of the body's own contour that hangs below
  /// the belly with a scalloped hem, so the wraps, the shading and the hero
  /// outline run onto it with no seam (the dragon's and King Coo's technique).
  /// The far thigh is the same bulge at 85 % (f2-body: it used to be hidden
  /// behind the satchel's corner, which made the far shin look hung from the bag).
  static final Path body = Path.combine(ui.PathOperation.union, Path.combine(ui.PathOperation.union, NeferhooKit.smoothPath(bodyPts), _thigh(NeferhooLayout.hipNear, 1)), _thigh(NeferhooLayout.hipFar, _farS));
  static final Path neck = NeferhooKit.smoothPath(neckPts);

  // ---- the legs' pose-independent paths, built once
  /// Both thighs' own shapes (their shading at full detail).
  static final Path thighs = Path.combine(ui.PathOperation.union, _thigh(NeferhooLayout.hipNear, 1), _thigh(NeferhooLayout.hipFar, _farS));

  /// The cinnamon leg feathers peeking out under the hems (near and far thigh
  /// in one path), and their ribs.
  static final Path fringe = Path.combine(ui.PathOperation.union, _thigh(NeferhooLayout.hipNear, 1, drop: .12, n: 3, half: .22), _thigh(NeferhooLayout.hipFar, _farS, drop: .12, n: 3, half: .22));
  static final Path fringeRibs = () {
    const n = 3, half = .22;
    final q = Path();
    for (final (hip, s) in [(NeferhooLayout.hipNear, 1.0), (NeferhooLayout.hipFar, _farS)]) {
      final y0 = hip.dy + (.18 + .12) * s;
      for (var i = 0; i < n; i++) {
        final x = hip.dx - half * s + (i + .5) * (2 * half * s / n);
        q
          ..moveTo(x, y0 + .06)
          ..lineTo(x, y0 + .015);
      }
    }
    return q;
  }();

  /// Strip tones from -1 (cooler, lilac) to +1 (warmer, aged): top lip,
  /// middle, underside. All stay light: the strips are told apart by their
  /// lips and shadows, not by their colour.
  static List<Color> tone(double m) {
    final w = m.clamp(0.0, 1.0), k = (-m).clamp(0.0, 1.0);
    Color mix(Color base, Color warm, Color cool) => Color.lerp(Color.lerp(base, warm, w * .6)!, cool, k * .6)!;
    return [
      mix(NeferhooPalette.linenHi, NeferhooBodyInk.linenWarmHi, NeferhooBodyInk.linenCoolHi),
      mix(NeferhooPalette.linenLit, NeferhooBodyInk.linenWarm, NeferhooBodyInk.linenCool),
      mix(Color.lerp(NeferhooPalette.linen, NeferhooPalette.linenShade, .8)!, NeferhooBodyInk.linenWarmShade, NeferhooBodyInk.linenCoolShade),
    ];
  }

  static const rhythm = [0.0, .6, 0.0, -.5, 0.0, .5, -.3, 0.0, .6, 0.0, -.5, .3, 0.0, .5, -.4];

  static ui.Picture? _wraps, _finish, _neck, _collar, _bagBack, _bagFront, _flapFace, _straps, _pad, _padPlay;
  // the PLAY level (the game's 41 px per unit): the same parts in big shapes
  static ui.Picture? _wrapsPlay, _finishPlay, _collarPlay, _bagPlay, _bagFrontPlay, _flapPlay, _badgePlay, _strapsPlay;
  static ui.Picture get bagFrontPlay => _bagFrontPlay ??= _capture(_drawBagFrontPlay);
  static ui.Picture get wrapsPlay => _wrapsPlay ??= _capture(_drawWrapsPlay);
  /// The stamp pad in its own picture (m1 / M4: it fades with the target and flexes under the wingtip).
  static ui.Picture get pad => _pad ??= _capture((c) => _drawPad(c, full: true));
  static ui.Picture get padPlay => _padPlay ??= _capture((c) => _drawPad(c, full: false));
  static ui.Picture get finishPlay => _finishPlay ??= _capture(_drawFinishPlay);
  static ui.Picture get collarPlay => _collarPlay ??= _capture(_drawCollarPlay);
  static ui.Picture get bagPlay => _bagPlay ??= _capture(_drawBagPlay);
  static ui.Picture get flapPlay => _flapPlay ??= _capture(_drawFlapPlay);
  static ui.Picture get badgePlay => _badgePlay ??= _capture(_drawBadgePlay);
  static ui.Picture? _badge;
  static ui.Picture get badge => _badge ??= _capture(_drawBadge);
  static ui.Picture get strapsPlay => _strapsPlay ??= _capture(_drawStrapsPlay);
  static ui.Picture get wraps => _wraps ??= _capture(_drawWraps);
  static ui.Picture get finish => _finish ??= _capture(_drawFinish);
  static ui.Picture get neckPic => _neck ??= _capture(_drawNeck);
  static ui.Picture get collar => _collar ??= _capture(_drawCollar);
  static ui.Picture get bagBack => _bagBack ??= _capture(_drawBagBack);
  static ui.Picture get bagFront => _bagFront ??= _capture(_drawBagFront);
  static ui.Picture get flapFace => _flapFace ??= _capture((c) => _drawFlap(c, face: true));
  static ui.Picture get straps => _straps ??= _capture(_drawStraps);

  /// The strips of linen, ONE layout for both levels of detail (the play level
  /// batches them and leaves out the weave): (the long winds, bottom first, the
  /// cross winds and the hip strips, bottom first).
  static final (List<_Strip>, List<_Strip>) _layout = _buildStrips();
  static List<_Strip> get winds => _layout.$1;
  static List<_Strip> get crosses => _layout.$2;

  /// What a turned wind leaves open between itself and its neighbour (a wedge, widest at the
  /// ends): the shade UNDER the cloth, one path for all four, drawn before every wind.
  static final Path gapShade = () {
    final q = Path();
    for (final st in _layout.$1) {
      if (st.tilt == 0 && st.fullBand == null) continue;
      final b = st.fullBand ?? st.band;
      q.addPath(_Band(b.center, [for (final h in b.half) h + .34]).shape, Offset.zero);
    }
    return q;
  }();
  static final Path glyphPath = _buildGlyphs();

  /// The play level's winds as the painter's algorithm would leave them, built ONCE: the winds
  /// cross now, so the batched draw of one role (all fills, then all seams) is no longer the same as
  /// drawing the winds one by one (a lower wind's seam would show through the wind lying over it).
  /// Each wind's fill, cast shadow, lip and seam are cut against the winds above it (a path
  /// difference at build time), so every role can be ONE draw and nothing shows that is covered.
  static final _WindParts windParts = _WindParts(_layout.$1);
}

/// A major wind's cast shadow (offset in units, alpha), one copy for both levels of detail.
const _castMajor = Offset(-.03, .12);
const _castMajorAlpha = .6;

/// See [_Geo.windParts]. The winds are in painting order (the lowest first): a later wind lies over an earlier one.
class _WindParts {
  _WindParts(List<_Strip> winds) {
    final shapes = [for (final st in winds) st.band.shape];
    Path? above;
    Path minus(Path a, Path? b) => b == null ? a : Path.combine(ui.PathOperation.difference, a, b);
    Path edge(List<Offset> line, double half) => _Band(line, List.filled(line.length, half)).shape;
    for (var i = winds.length - 1; i >= 0; i--) {
      final st = winds[i], b = st.band;
      fill[st.tone > .25 ? 2 : (st.tone < -.25 ? 0 : 1)].addPath(minus(shapes[i], above), Offset.zero);
      // a major wind drops a deep shadow on what lies under it (its cloth and its neighbours below)
      if (st.major) shadow.addPath(minus(minus(shapes[i].shift(_castMajor), shapes[i]), above), Offset.zero);
      lip.addPath(minus(edge(b.top, .02), above), Offset.zero);
      (st.major ? seamMajor : seamMinor).addPath(minus(edge(b.bottom, st.major ? .045 : .02), above), Offset.zero);
      above = above == null ? shapes[i] : Path.combine(ui.PathOperation.union, above, shapes[i]);
    }
  }

  final fill = [Path(), Path(), Path()];
  final shadow = Path(), lip = Path(), seamMajor = Path(), seamMinor = Path();
}

// ===========================================================================
// the wraps

/// One strip of the wrapping.
class _Strip {
  _Strip(this.band, this.tone, {this.cut = false, this.hip = false, this.tilt = 0, this.fullBand});
  final _Band band;

  /// The wind was turned this many radians about the middle of the body (i3-body, m5):
  /// it crosses its neighbours, so the layout puts a shade under it where it leaves a gap.
  final double tilt;

  /// For a wind with a tapered (tucked) end: the same centre line run the whole width, so the shade under
  /// the cloth fills what lies beyond the point (a hole there would show the plumage at the close-up level
  /// and the linen at the play level: an LOD pop).
  final _Band? fullBand;

  /// A MAJOR wind (turned or broad): dark seam, deep cast shadow. The rest are minor winds whose
  /// seams are faint, so at 1x the 13 winds read as a few bands of cloth, not 13 pinstripes.
  bool major = false;

  /// -1 cool .. 1 warm (see `_Geo.tone`).
  final double tone;

  /// Its start is a CUT end lying inside the body (an ink edge, at full detail a
  /// frayed one): a wound strip ends somewhere.
  final bool cut;

  /// A hip strip: a narrow band across a thigh, running on into the shin's wraps.
  final bool hip;
}

/// The wrapping of the whole body: thirteen long winds that BOW round the belly (f2-body), two broad
/// cross winds (the "X" a mummy is known by), and a diagonal strip pair over each thigh that crosses
/// the hem at about 40 degrees: belly -> thigh -> shin.
///
/// i3-body, m5 (the wraps read as pinstripes at 1x). Only about six of the 13 winds ever show (the
/// collar covers the top three, the belly's curve hides the bottom four) in a ring round the stamp pad
/// that is 10-14 px wide at 1x, so what shows must be bold and unlike its neighbours: the winds are no
/// longer in step. The same 13 winds, no new object:
///  * every third wind (1, 4, 7, 10) is turned 18 degrees about x = 0 (under the strap), the two that
///    show (4 and 7) opposite ways, so each crosses its neighbours: it lies over one and leaves a wedge
///    of shade at the other;
///  * two are broad (5 and 9: +30 % on their old .19-.20, their neighbours trimmed so the stack keeps its
///    place); the turned and the broad winds are the MAJOR ones (dark seam, deep cast shadow), the others
///    minor (a faint seam): at 1x the 13 read as a few bands of cloth, not 13 pinstripes;
///  * a tucked end on each side: wind 5 (a broad one) ends in a point at x -1.0 (left flank, under the
///    collar's pendants), wind 4 at x .95 (right, between the straps: seen when the wing is up). The cloth
///    tapers to its end like a strip cut on the slant. (No loose flank strip: it read as a third leg.)
const _windHalves = [.16, .2, .15, .21, .17, .25, .14, .17, .14, .25, .16, .2, .18];
const _windTilt = {1: -.314, 4: -.314, 7: .314, 10: -.314}; // 18 degrees (the two visible ones, 4 and 7, turn opposite ways)
const _windBroad = {5, 9};
const _tuckLeftAt = {5: -1.0};
const _tuckRightAt = {4: .95};
const _windPivot = 0.0;
const _windTop = -1.62;
(List<_Strip>, List<_Strip>) _buildStrips() {
  final winds = <_Strip>[];
  var top = _windTop;
  for (var k = 0; k < _windHalves.length; k++) {
    final h = _windHalves[k];
    final bow = .22 + .07 * math.sin(k * 1.1 + .4);
    final slope = .19 + .05 * math.sin(k * .8 + 1.0);
    final cy = top + h; // the centre line at the middle of its run
    final x0 = _tuckLeftAt[k] ?? -1.9;
    final x1 = _tuckRightAt[k] ?? 2.0;
    final tucked = _tuckLeftAt.containsKey(k) || _tuckRightAt.containsKey(k);
    winds.add(_Strip(
      _wind(y0: cy - bow - slope * .05, slope: slope, half: h, bow: bow, x0: x0, x1: x1, n: 28, tilt: _windTilt[k] ?? 0, spanFrom: -1.9, spanTo: 2.0, taperL: _tuckLeftAt.containsKey(k) ? .6 : 0, taperR: _tuckRightAt.containsKey(k) ? .7 : 0),
      _Geo.rhythm[k],
      tilt: _windTilt[k] ?? 0,
      fullBand: tucked ? _wind(y0: cy - bow - slope * .05, slope: slope, half: h, bow: bow, n: 28, tilt: _windTilt[k] ?? 0) : null,
    )..major = _windTilt.containsKey(k) || _windBroad.contains(k));
    top += 2 * h - .07;
  }
  final crosses = <_Strip>[
    _Strip(_wind(y0: -.12, slope: -.52, half: .235, bow: .08, x0: -1.12, x1: 2.0, n: 28), .15, cut: true),
    _Strip(_wind(y0: .8, slope: -.5, half: .21, bow: .08, x0: -1.55, x1: 2.0, n: 28), 0.0),
  ];
  // the hip strips: two narrow diagonals across each thigh, rising to the right
  // (about 40 degrees, perpendicular to a trailing shin), the hem cuts them
  for (final (hip, s) in [(NeferhooLayout.hipNear, 1.0), (NeferhooLayout.hipFar, _farS)]) {
    for (var i = 0; i < 2; i++) {
      final a = Offset(hip.dx - .27 * s - i * .04, hip.dy + .26 * s + i * .13);
      final b = a + Offset(.42 * s, -.36 * s);
      final c = (a + b) / 2 + Offset(.03, .06);
      final pts = <Offset>[], hs = <double>[];
      for (var j = 0; j <= 10; j++) {
        final t = j / 10, u = 1 - t;
        pts.add(a * (u * u) + c * (2 * u * t) + b * (t * t));
        hs.add(.055 * (.65 + .35 * math.sin(math.pi * t)));
      }
      crosses.add(_Strip(_Band(pts, hs), .5, hip: true));
    }
  }
  return (winds.reversed.toList(), crosses);
}

/// The stamp pad: a round linen patch sewn on the chest, clean and bright, that
/// the strips pass BEHIND (the target the returned letters land on; the ring is
/// drawn over it).
const _padR = .40;

/// A touch off-round (a hand-sewn patch, not a vinyl disc): 14 points, radius .40 ± .012.
final Path _padPath = () {
  final pts = <Offset>[];
  for (var k = 0; k < 14; k++) {
    final a = k / 14 * math.pi * 2;
    final r = _padR + .012 * math.sin(k * 2.3 + 1) + .006 * math.sin(k * 5.1);
    pts.add(NeferhooLayout.postmark + Offset(math.cos(a) * r * 1.03, math.sin(a) * r));
  }
  return NeferhooKit.smoothPath(pts);
}();

/// One bandage strip: a crisp cast shadow, a light body, a lit top lip and a
/// darker underside line.
void _paintStrip(Canvas c, _Band b, double mix, {double castX = -.02, double castY = .045, double lip = 1, bool major = true}) {
  final shape = b.shape;
  final tone = _Geo.tone(mix);
  // (m5) a major wind lies proud: a deep cast shadow falls on what is under it (the same offset and
  // strength as the play level's, `_WindParts`)
  c.drawPath(shape.shift(major ? _castMajor : Offset(castX, castY)), _fill(NeferhooPalette.linenDeep, major ? _castMajorAlpha : .26));
  final mid = b.center[b.center.length ~/ 2];
  final h = b.half[b.half.length ~/ 2];
  c.drawPath(shape, _shade(_lg(Offset(0, mid.dy - h), Offset(0, mid.dy + h), tone, const [0, .55, 1])));
  c.drawPath(NeferhooKit.smoothPath(b.top, close: false), _stroke(const Color(0xffffffff), major ? .045 : .03, .95 * lip));
  c.drawPath(NeferhooKit.smoothPath(b.bottom, close: false), _stroke(NeferhooBodyInk.seam, major ? .09 : .04, major ? 1 : .4));
}

void _drawWraps(Canvas c) {
  final body = _Geo.body;
  c.save();
  c.clipPath(body);
  // the hoopoe under the linen: cinnamon, fading to cream at the belly, in
  // feather scallops; it shows in the gaps between strips
  c.drawPath(body, _shade(_lg(const Offset(0, -.7), const Offset(0, 1.05), [NeferhooPalette.cinnLit, NeferhooPalette.cinn, NeferhooBodyInk.creamBelly], const [0, .5, 1])));
  final scal = Path();
  for (var row = 0; row < 11; row++) {
    for (var k = -9; k < 10; k++) {
      final x = k * .2 + (row.isOdd ? .1 : 0) + .1;
      final y = -1.2 + row * .2;
      scal.addArc(Rect.fromLTWH(x - .1, y - .1, .2, .2), .15, math.pi - .3);
    }
  }
  c.drawPath(scal, _stroke(NeferhooPalette.cinnShade, .026, .6));
  // the wedges the turned winds leave open: the shade under the cloth (m5)
  c.drawPath(_Geo.gapShade, _fill(NeferhooBodyInk.gapShade));
  // the long winds, bottom first: each upper strip lies over the one below it
  // and drops its shadow on it
  final threads = Path(), ticks = Path();
  void addWeave(_Band b) {
    threads.addPath(NeferhooKit.smoothPath(b.line(-.45), close: false), Offset.zero);
    threads.addPath(NeferhooKit.smoothPath(b.line(.4), close: false), Offset.zero);
    final top = b.top, bot = b.bottom;
    for (var i = 1; i < b.center.length - 1; i++) {
      final f = (i.isEven ? .45 : .8) - (i % 3) * .06;
      final q = Offset.lerp(top[i], bot[i], f)!;
      final nr = bot[i] - top[i];
      final nl = nr.distance == 0 ? const Offset(0, 1) : nr / nr.distance;
      ticks.moveTo(q.dx - nl.dx * .035, q.dy - nl.dy * .035);
      ticks.lineTo(q.dx + nl.dx * .035, q.dy + nl.dy * .035);
    }
  }

  final ends = Path();
  for (final st in _Geo.winds) {
    _paintStrip(c, st.band, st.tone, major: st.major);
    addWeave(st.band);
  }
  c.drawPath(threads, _stroke(NeferhooPalette.linenDeep, .011, .12));
  c.drawPath(ticks, _stroke(NeferhooPalette.linenDeep, .013, .16, StrokeCap.butt));
  // the cross winds and the hip strips: laid over the long winds
  final threads2 = Path(), chev = Path();
  for (final st in _Geo.crosses) {
    final b = st.band;
    _paintStrip(c, b, st.tone, castX: -.035, castY: .055);
    if (st.hip) continue;
    threads2.addPath(NeferhooKit.smoothPath(b.line(-.45), close: false), Offset.zero);
    // herringbone: a row of small chevrons down the strip, like a twill
    final n = b.center.length;
    for (var i = 2; i < n - 1; i += 2) {
      final q = b.center[i], q2 = b.center[i + 1];
      final d = q2 - q;
      final dn = d / d.distance;
      final nn = Offset(-dn.dy, dn.dx);
      final tip = q + dn * .05;
      chev.moveTo((q - nn * .06).dx, (q - nn * .06).dy);
      chev.lineTo(tip.dx, tip.dy);
      chev.lineTo((q + nn * .06).dx, (q + nn * .06).dy);
    }
    if (st.cut) ends.addPath(_cutEnd(b), Offset.zero);
  }
  c.drawPath(threads2, _stroke(NeferhooPalette.linenDeep, .012, .16));
  c.drawPath(chev, _stroke(NeferhooPalette.linenDeep, .014, .26));
  // the cut ends: an ink edge, and at full detail a frayed rim
  c.drawPath(ends, _stroke(NeferhooBodyInk.seam, .036, 1, StrokeCap.butt));
  var seed = 3;
  for (final st in [..._Geo.winds, ..._Geo.crosses]) {
    if (!st.cut) continue;
    final b = st.band;
    final endAt = b.center.first;
    final dir = math.atan2((b.center[1] - b.center[0]).dy, (b.center[1] - b.center[0]).dx) + math.pi;
    final fray = _frayEnd(endAt, dir, b.half.first * .98, seed += 4);
    c.drawPath(fray, _shade(_lg(endAt + const Offset(0, -.2), endAt + const Offset(0, .2), [NeferhooPalette.linenHi, NeferhooPalette.linen])));
    c.drawPath(fray, _stroke(NeferhooPalette.linenDeep, .022, .7));
    for (var k = 0; k < 3; k++) {
      final a = dir + (k - 1) * .5;
      final s0 = endAt + Offset(math.cos(dir), math.sin(dir)) * .08;
      c.drawLine(s0, s0 + Offset(math.cos(a), math.sin(a)) * (.14 + .05 * _hash(k + 50 + seed)), _stroke(NeferhooPalette.linenShade, .02, .9));
    }
  }
  c.restore();
}

/// A straight cut across the band's start (its left end).
Path _cutEnd(_Band b) => Path()
  ..moveTo(b.top.first.dx, b.top.first.dy)
  ..lineTo(b.bottom.first.dx, b.bottom.first.dy);

/// The stamp pad: a linen patch (`linenHi` at .9, not a white disc), a touch off-round,
/// with a soft shadow and, at close-up, a stitched rim. The strips show through a
/// little (10 %), so it is cloth on cloth, not a sticker.
void _drawPad(Canvas c, {required bool full}) {
  const at = NeferhooLayout.postmark;
  c.drawPath(_padPath.shift(const Offset(-.02, .035)), _fill(NeferhooPalette.linenDeep, .34));
  c.drawPath(_padPath, full ? _shade(_rg(at + const Offset(-.1, -.12), _padR * 1.5, [NeferhooPalette.linenHi.withValues(alpha: .92), NeferhooBodyInk.linenWarmHi.withValues(alpha: .9), NeferhooPalette.linenLit.withValues(alpha: .9)])) : _fill(NeferhooPalette.linenHi, .9));
  if (full) c.drawPath(_dashed(Path()..addOval(Rect.fromCenter(center: at, width: (_padR - .045) * 2.06, height: (_padR - .045) * 2)), .05, .04), _stroke(NeferhooBodyInk.threadDark, .014, .75));
  c.drawPath(_padPath, _stroke(NeferhooBodyInk.linenLine, .028, .55));
}

/// Volume, shadows cast by the collar and the wing, the warm rim light and
/// the one hero outline.
void _drawFinish(Canvas c) {
  final body = _Geo.body;
  c.save();
  c.clipPath(body);
  // roundness: a little darker toward the back and the belly
  c.drawPath(body, _shade(_lg(const Offset(-1.2, -1.0), const Offset(1.4, 1.1), [NeferhooPalette.linenDeep.withValues(alpha: 0), NeferhooPalette.linenDeep.withValues(alpha: 0), NeferhooPalette.linenDeep.withValues(alpha: .62)], const [0, .32, 1]))); // (closing round, N5: the belly turns away from the sun earlier and deeper)
  c.drawPath(body, _shade(_lg(const Offset(0, .45), const Offset(0, 1.1), [NeferhooPalette.linenDeep.withValues(alpha: 0), NeferhooPalette.linenDeep.withValues(alpha: .34)])));
  // the collar and the near wing cast soft shadows on the wraps
  c.drawOval(Rect.fromCenter(center: const Offset(-.55, -.5), width: 1.9, height: .7), _shade(_rg(const Offset(-.55, -.5), .95, [NeferhooPalette.linenDeep.withValues(alpha: .26), NeferhooPalette.linenDeep.withValues(alpha: 0)])));
  c.drawOval(Rect.fromCenter(center: const Offset(.55, -.35), width: 1.3, height: 1.0), _shade(_rg(const Offset(.55, -.35), .65, [NeferhooPalette.linenDeep.withValues(alpha: .22), NeferhooPalette.linenDeep.withValues(alpha: 0)])));
  // warm rim light from the afternoon sun, upper right: a stroke of the
  // outline that fades out toward the lower left
  c.drawPath(body, Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = .2
    ..shader = _lg(const Offset(1.5, -1.1), const Offset(-.3, .3), [NeferhooBodyInk.rim.withValues(alpha: .8), NeferhooBodyInk.rim.withValues(alpha: .3), NeferhooBodyInk.rim.withValues(alpha: 0)], const [0, .5, 1]));
  c.restore();
  c.drawPath(body, _stroke(NeferhooPalette.ink, NeferhooLayout.hero, 1));
}

void _drawNeck(Canvas c) {
  final neck = _Geo.neck;
  c.drawPath(neck, _shade(_lg(const Offset(-1.3, -1.5), const Offset(-.3, -.4), [NeferhooPalette.linenLit, NeferhooPalette.linenShade])));
  c.drawPath(neck, _stroke(NeferhooPalette.ink, NeferhooLayout.part));
}

// ===========================================================================
// glyphs: the Pharaoh's Post address block (full detail only: texture)

/// The inscription: a short run of signs printed inside the postmark ring (the
/// Pharaoh's Post address), on a slight tilt.
Path _buildGlyphs() {
  final p = Path();
  Offset centre(double x) => Offset(x, NeferhooLayout.postmark.dy + .14 - .2 * (x - NeferhooLayout.postmark.dx));
  void sign(int idx, double x) {
    final c0 = centre(x);
    final t = centre(x + .01) - centre(x - .01);
    final ang = math.atan2(t.dy, t.dx);
    final ca = math.cos(ang), sa = math.sin(ang);
    Offset P(double u, double v) => c0 + Offset(u * ca - v * sa, u * sa + v * ca);
    void line(List<Offset> pts) {
      p.moveTo(pts.first.dx, pts.first.dy);
      for (final q in pts.skip(1)) {
        p.lineTo(q.dx, q.dy);
      }
    }

    void quad(Offset a, Offset c, Offset b) => p.quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
    switch (idx) {
      case 0: // an eye: lens, pupil, brow
        p.moveTo(P(-.065, 0).dx, P(-.065, 0).dy);
        quad(P(-.065, 0), P(0, -.07), P(.065, 0));
        quad(P(.065, 0), P(0, .07), P(-.065, 0));
        p.addOval(Rect.fromCircle(center: P(0, 0), radius: .018));
        line([P(-.06, -.1), P(0, -.12), P(.06, -.1)]);
      case 1: // a feather: leaf and quill
        p.moveTo(P(0, -.11).dx, P(0, -.11).dy);
        quad(P(0, -.11), P(.06, 0), P(0, .11));
        quad(P(0, .11), P(-.06, 0), P(0, -.11));
        line([P(0, -.09), P(0, .13)]);
      case 2: // a little bird
        p.moveTo(P(-.075, .02).dx, P(-.075, .02).dy);
        quad(P(-.075, .02), P(-.03, -.09), P(.04, -.04));
        line([P(.04, -.04), P(.09, -.02)]);
        line([P(-.075, .02), P(.03, .05), P(.04, -.04)]);
        line([P(-.01, .05), P(-.01, .11)]);
        line([P(.02, .05), P(.03, .11)]);
      case 3: // water
        for (var r = 0; r < 2; r++) {
          line([P(-.075, -.025 + r * .075), P(-.04, -.065 + r * .075), P(0, -.025 + r * .075), P(.04, -.065 + r * .075), P(.075, -.025 + r * .075)]);
        }
      case 4: // a reed with two leaves
        line([P(0, .11), P(0, -.1)]);
        p.moveTo(P(0, -.02).dx, P(0, -.02).dy);
        quad(P(0, -.02), P(.06, -.06), P(.075, -.12));
        p.moveTo(P(0, .04).dx, P(0, .04).dy);
        quad(P(0, .04), P(-.06, 0), P(-.075, -.06));
      default: // the cartouche's tie: two bars and a dot
        line([P(-.05, -.09), P(-.05, .09)]);
        line([P(.05, -.09), P(.05, .09)]);
        p.addOval(Rect.fromCircle(center: P(0, 0), radius: .018));
    }
  }

  const xs = [-.76, -.62, -.48, -.34];
  for (var i = 0; i < xs.length; i++) {
    sign(i, xs[i]);
  }
  return p;
}

// ===========================================================================
// the collar

/// The collar (a wesekh), ONE design at both levels of detail (f2-body, M4): the
/// same four bead rows, the same nine teardrop pendants, the same two lotus-bud
/// terminals; the close-up level only adds bead cells, lit lips, pendant gloss
/// and the buds' petals (texture, never objects).
const _collarCtr = Offset(-.6, -1.28);
const _collarA0 = .58, _collarA1 = 2.18;
const _collarRows = <(double, double, Color, Color, Color)>[
  // r0, r1, colour, lit, deep
  (.86, 1.05, NeferhooPalette.lapis, NeferhooPalette.lapisLit, NeferhooPalette.lapisDeep),
  (.71, .86, NeferhooBodyInk.bag, NeferhooBodyInk.bagLit, NeferhooBodyInk.bagDeep),
  (.61, .71, NeferhooPalette.turq, NeferhooPalette.turqLit, NeferhooPalette.turqShade),
  (.54, .61, NeferhooPalette.gold, NeferhooPalette.goldHi, NeferhooPalette.goldDeep),
];
const _pendRoot = .99, _pendLen = .16, _pendHalf = .055, _nPend = 11;

Offset _collarAt(double r, double a) => _collarCtr + Offset(math.cos(a), math.sin(a)) * r;
Path _collarArc(double r, [double s = _collarA0, double e = _collarA1]) => Path()..addArc(Rect.fromCircle(center: _collarCtr, radius: r), s, e - s);

/// The pendants, four colour groups (turquoise, carnelian, gold, carnelian): one
/// path each; [hi] collects a gloss line down each.
List<Path> _collarPendants(Path hi) {
  final pend = <Path>[Path(), Path(), Path(), Path()];
  for (var k = 0; k < _nPend; k++) {
    final a = _lerp(_collarA0 + .13, _collarA1 - .13, k / (_nPend - 1));
    final dir = Offset(math.cos(a), math.sin(a));
    final tn = Offset(-dir.dy, dir.dx);
    final root = _collarCtr + dir * _pendRoot;
    final tip = _collarCtr + dir * (_pendRoot + _pendLen);
    final mid = _pendLen * .7;
    pend[k % 4].addPath(
      Path()
        ..moveTo((root + tn * _pendHalf).dx, (root + tn * _pendHalf).dy)
        ..quadraticBezierTo((root + dir * mid + tn * (_pendHalf * 1.25)).dx, (root + dir * mid + tn * (_pendHalf * 1.25)).dy, tip.dx, tip.dy)
        ..quadraticBezierTo((root + dir * mid - tn * (_pendHalf * 1.25)).dx, (root + dir * mid - tn * (_pendHalf * 1.25)).dy, (root - tn * _pendHalf).dx, (root - tn * _pendHalf).dy)
        ..close(),
      Offset.zero,
    );
    hi.moveTo((root + dir * .03 - tn * .022).dx, (root + dir * .03 - tn * .022).dy);
    hi.lineTo((root + dir * .1 - tn * .022).dx, (root + dir * .1 - tn * .022).dy);
  }
  return pend;
}

/// The two terminals: a LOTUS BUD on the arc's tangent at each end of the rows (three
/// petals fanned from one base, the middle one longest), not a bar with a cap on it.
/// An ink line closes the rows' end. One path for both ends; in [petals] the close-up
/// level's centre ribs.
Path _collarBuds(Path petals) {
  final buds = Path();
  for (final (a, sgn) in [(_collarA0, -1.0), (_collarA1, 1.0)]) {
    final d = Offset(math.cos(a), math.sin(a));
    final tn = Offset(-d.dy, d.dx) * sgn; // the arc's tangent, away from the collar
    final base = _collarCtr + d * .79;
    // the rows' end: a line across them (the buds' ink goes with it)
    final p1 = base - d * .27, p2 = base + d * .27;
    buds
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy);
    final root = base + tn * .02;
    for (final (off, len, hw) in const [(-.66, .22, .075), (.66, .22, .075), (0.0, .33, .095)]) {
      final c0 = math.cos(off), s0 = math.sin(off);
      final dd = Offset(tn.dx * c0 - tn.dy * s0, tn.dx * s0 + tn.dy * c0);
      final nn = Offset(-dd.dy, dd.dx);
      final tip = root + dd * len;
      buds
        ..moveTo(root.dx, root.dy)
        ..cubicTo((root + dd * len * .15 + nn * hw * 1.5).dx, (root + dd * len * .15 + nn * hw * 1.5).dy, (tip - dd * len * .4 + nn * hw * 1.1).dx, (tip - dd * len * .4 + nn * hw * 1.1).dy, tip.dx, tip.dy)
        ..cubicTo((tip - dd * len * .4 - nn * hw * 1.1).dx, (tip - dd * len * .4 - nn * hw * 1.1).dy, (root + dd * len * .15 - nn * hw * 1.5).dx, (root + dd * len * .15 - nn * hw * 1.5).dy, root.dx, root.dy)
        ..close();
      if (off == 0.0) {
        petals
          ..moveTo((root + dd * len * .15).dx, (root + dd * len * .15).dy)
          ..lineTo((root + dd * len * .72).dx, (root + dd * len * .72).dy);
      }
    }
  }
  return buds;
}

/// The bead each plate carries: a lapis stone.
Path _collarBeads() {
  final q = Path();
  for (final (a, sgn) in [(_collarA0, -1.0), (_collarA1, 1.0)]) {
    final d = Offset(math.cos(a), math.sin(a));
    final tn = Offset(-d.dy, d.dx) * sgn;
    q.addOval(Rect.fromCircle(center: _collarCtr + d * .79 + tn * .045, radius: .04));
  }
  return q;
}

void _drawCollar(Canvas c) {
  // soft shadow on the wraps below the pendants (inside the body only)
  c.save();
  c.clipPath(_Geo.body);
  c.drawPath(_collarArc(1.31), _stroke(NeferhooPalette.linenDeep, .3, .26));
  c.restore();
  final hi = Path();
  final pend = _collarPendants(hi);
  final pendCols = [NeferhooPalette.turq, NeferhooBodyInk.bag, NeferhooPalette.gold, NeferhooBodyInk.bag];
  for (var i = 0; i < 4; i++) {
    c.drawPath(pend[i], _fill(pendCols[i]));
  }
  c.drawPath(pend.fold(Path(), (acc, p) => acc..addPath(p, Offset.zero)), _stroke(NeferhooPalette.ink, .028));
  c.drawPath(hi, _stroke(const Color(0xffffffff), .022, .55));

  // the bead rows, outermost first: the colour, bead cells, a lit lip, a deep lip
  for (final (r0, r1, col, lit, deep) in _collarRows) {
    final rm = (r0 + r1) / 2;
    c.drawPath(_collarArc(rm), _stroke(deep, r1 - r0, 1, StrokeCap.butt));
    final n = ((_collarA1 - _collarA0) * rm / .105).round();
    final even = Path(), odd = Path();
    for (var k = 0; k < n; k++) {
      final a = _lerp(_collarA0 + .05, _collarA1 - .05, (k + .5) / n);
      final d = .042 / rm;
      final q = Path()
        ..moveTo(_collarAt(r0 + .012, a - d).dx, _collarAt(r0 + .012, a - d).dy)
        ..lineTo(_collarAt(r1 - .012, a - d).dx, _collarAt(r1 - .012, a - d).dy)
        ..lineTo(_collarAt(r1 - .012, a + d).dx, _collarAt(r1 - .012, a + d).dy)
        ..lineTo(_collarAt(r0 + .012, a + d).dx, _collarAt(r0 + .012, a + d).dy)
        ..close();
      (k.isEven ? even : odd).addPath(q, Offset.zero);
    }
    c.drawPath(even, _fill(col));
    c.drawPath(odd, _fill(Color.lerp(col, lit, .38)!));
    c.drawPath(_collarArc(r0 + .03), _stroke(const Color(0xffffffff), .02, .45));
    c.drawPath(_collarArc(r1 - .03), _stroke(deep, .018, .55));
  }
  // row dividers and the outline
  final lines = Path();
  for (final (r0, _, _, _, _) in _collarRows.skip(1)) {
    lines.addPath(_collarArc(r0 + .0), Offset.zero);
  }
  c.drawPath(lines, _stroke(NeferhooPalette.ink, .022, .6));
  c.drawPath(_collarArc(.54)..addPath(_collarArc(1.05), Offset.zero), _stroke(NeferhooPalette.ink, NeferhooLayout.part));

  // the terminals: gold lotus buds on the arc's tangent, a lapis bead on each
  final petals = Path();
  final buds = _collarBuds(petals);
  c.drawPath(buds, _shade(_lg(_collarAt(.8, _collarA0), _collarAt(1.1, _collarA0) + const Offset(.1, -.3), [NeferhooPalette.goldHi, NeferhooPalette.gold, NeferhooPalette.goldShade], const [0, .45, 1])));
  c.drawPath(petals, _stroke(NeferhooPalette.goldDeep, .018, .85));
  c.drawPath(buds, _stroke(NeferhooPalette.ink, .03));
  c.drawPath(_collarBeads(), _fill(NeferhooPalette.lapis));
}

// ===========================================================================
// the satchel and its straps

const _bagW = 1.18, _bagH = .86;
final _bagRect = RRect.fromRectAndCorners(
  Rect.fromCenter(center: Offset.zero, width: _bagW, height: _bagH),
  topLeft: const Radius.circular(.17),
  topRight: const Radius.circular(.17),
  bottomLeft: const Radius.circular(.36),
  bottomRight: const Radius.circular(.36),
);

/// The bag's back wall, its gusset and its dark mouth (behind the letters).
void _drawBagBack(Canvas c) {
  final back = _bagRect.shift(const Offset(.045, -.035));
  c.drawRRect(back, _shade(_lg(const Offset(0, -.5), const Offset(0, .45), [NeferhooBodyInk.leatherDark, NeferhooBodyInk.bagDeep])));
  c.drawRRect(back, _stroke(NeferhooPalette.ink, NeferhooLayout.part));
  // the mouth: a dark crescent along the top
  c.drawPath(Path()
    ..moveTo(-.55, -.4)
    ..quadraticBezierTo(0, -.58, .6, -.4)
    ..lineTo(.6, -.3)
    ..lineTo(-.55, -.3)
    ..close(), _fill(const Color(0xff3a1220)));
}

/// The bag's front panel: leather, tooled border, stitches, wear.
void _drawBagFront(Canvas c) {
  final bag = _bagRect;
  c.drawRRect(bag, _shade(_lg(const Offset(-.3, -.45), const Offset(.3, .45), [NeferhooBodyInk.bagLit, NeferhooBodyInk.bag, NeferhooBodyInk.bagShade], const [0, .45, 1])));
  c.save();
  c.clipRRect(bag);
  // leather grain: a few faint pits
  final grain = Path();
  for (var k = 0; k < 26; k++) {
    final x = -.55 + _hash(k * 2 + 100) * 1.1, y = -.35 + _hash(k * 2 + 101) * .78;
    grain.moveTo(x, y);
    grain.lineTo(x + .035, y + .008);
  }
  c.drawPath(grain, _stroke(NeferhooBodyInk.bagDeep, .014, .35));
  // worn corners and edges: the dye rubbed off to pale leather
  final wear = Path()
    ..moveTo(-.59, .0)
    ..quadraticBezierTo(-.58, .3, -.4, .42)
    ..moveTo(.59, .02)
    ..quadraticBezierTo(.58, .3, .4, .42)
    ..moveTo(-.28, .43)
    ..lineTo(.1, .43);
  c.drawPath(wear, _stroke(NeferhooBodyInk.leatherWorn, .05, .75));
  c.drawPath(Path()
    ..moveTo(-.5, .3)
    ..lineTo(-.44, .36)
    ..moveTo(.48, .32)
    ..lineTo(.42, .38)
    ..moveTo(.2, -.02)
    ..lineTo(.3, .06), _stroke(NeferhooBodyInk.leatherWorn, .02, .6));
  // a flex crease across the belly of the bag
  c.drawPath(Path()
    ..moveTo(-.5, .2)
    ..quadraticBezierTo(0, .27, .5, .2), _stroke(NeferhooBodyInk.bagDeep, .02, .5));
  c.restore();
  // tooled border: a grooved double line and a row of stitches inside it
  final groove = Path()..addRRect(bag.deflate(.085));
  c.drawPath(groove, _stroke(NeferhooBodyInk.bagDeep, .02, .75));
  c.drawPath(groove.shift(const Offset(.008, .008)), _stroke(NeferhooBodyInk.bagLit, .012, .5));
  c.drawPath(_dashed(Path()..addRRect(bag.deflate(.045)), .06, .04), _stroke(NeferhooBodyInk.thread, .02, .9));
  // an incised water zigzag along the lower panel, between two lines
  final zig = Path()..moveTo(-.36, .32);
  for (var k = 0; k < 12; k++) {
    zig.lineTo(-.36 + (k + .5) * .06, k.isEven ? .25 : .32);
  }
  c.drawPath(zig, _stroke(NeferhooBodyInk.bagDeep, .018, .6));
  c.drawRRect(bag, _stroke(NeferhooPalette.ink, NeferhooLayout.part + .01));
}

/// The flap, hinged on the bag's top edge (y = 0 here, hanging down +y): its
/// face (scalloped tip, stitched edge, brass buckle) or
/// its lining (seen from behind when it is swung open).
void _drawFlap(Canvas c, {required bool face}) {
  final flap = Path()
    ..moveTo(-.6, 0)
    ..lineTo(.6, 0)
    ..lineTo(.57, .3)
    ..quadraticBezierTo(.5, .5, .08, .55)
    ..quadraticBezierTo(0, .6, -.08, .55)
    ..quadraticBezierTo(-.5, .5, -.57, .3)
    ..close();
  if (!face) {
    c.drawPath(flap, _shade(_lg(const Offset(0, 0), const Offset(0, .55), [const Color(0xffdfae84), const Color(0xffbb805c)])));
    c.drawPath(_dashed(Path()..addPath(flap, Offset.zero), .06, .045), _stroke(NeferhooBodyInk.thread, .018, .7));
    c.drawPath(flap, _stroke(NeferhooPalette.ink, NeferhooLayout.part));
    return;
  }
  // shadow it throws on the bag
  c.drawPath(flap.shift(const Offset(-.02, .05)), _fill(const Color(0xff3a1220), .35));
  c.drawPath(flap, _shade(_lg(const Offset(0, 0), const Offset(0, .55), [NeferhooBodyInk.leatherHi, NeferhooBodyInk.bag, NeferhooBodyInk.bagShade], const [0, .4, 1])));
  c.save();
  c.clipPath(flap);
  // worn along the edge
  c.drawPath(Path()
    ..moveTo(-.57, .3)
    ..quadraticBezierTo(-.5, .5, -.1, .55)
    ..moveTo(.57, .3)
    ..quadraticBezierTo(.5, .5, .1, .55), _stroke(NeferhooBodyInk.leatherWorn, .05, .6));
  c.restore();
  // stitched edge and grooved line
  final edge = Path()
    ..moveTo(-.56, .02)
    ..lineTo(-.53, .3)
    ..quadraticBezierTo(-.46, .46, -.08, .5)
    ..quadraticBezierTo(0, .53, .08, .5)
    ..quadraticBezierTo(.46, .46, .53, .3)
    ..lineTo(.56, .02);
  c.drawPath(edge, _stroke(NeferhooBodyInk.bagDeep, .02, .7));
  c.drawPath(_dashed(edge.shift(const Offset(0, -.045)), .055, .04), _stroke(NeferhooBodyInk.thread, .02, .9));
  c.drawPath(flap, _stroke(NeferhooPalette.ink, NeferhooLayout.part + .01));
  // the lip of the flap, lit
  c.drawPath(Path()
    ..moveTo(-.55, .015)
    ..lineTo(.55, .015), _stroke(NeferhooBodyInk.leatherHi, .025, .8));

  // --- the brass buckle at the tip: a frame, a pin, a leather tab
  final tab = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, .46), width: .13, height: .17), const Radius.circular(.03));
  c.drawRRect(tab, _fill(NeferhooBodyInk.bagShade));
  c.drawRRect(tab, _stroke(NeferhooPalette.ink, .02));
  final buckle = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, .5), width: .22, height: .15), const Radius.circular(.04));
  c.drawRRect(buckle, _stroke(NeferhooPalette.ink, .066));
  c.drawRRect(buckle, _shade(_lg(const Offset(-.1, .42), const Offset(.1, .58), [NeferhooBodyInk.brassHi, NeferhooPalette.goldLit, NeferhooPalette.gold, NeferhooPalette.goldShade], const [0, .25, .65, 1])).. style = PaintingStyle.stroke..strokeWidth = .042);
  c.drawLine(const Offset(0, .43), const Offset(0, .57), _stroke(NeferhooPalette.goldDeep, .02));
}

/// The Pharaoh's Post badge: a lapis enamel oval in a gold rim with a winged letter,
/// centred on the origin. Pinned on the bag (over the flap) at BOTH levels of
/// detail, so it stays in view when the flap opens and never pops at an LOD switch.
void _drawBadge(Canvas c) {
  const bc = Offset.zero;
  final bo = Rect.fromCenter(center: bc, width: .48, height: .38);
  c.drawOval(bo.inflate(.035).shift(const Offset(-.01, .02)), _fill(const Color(0xff3a1220), .3));
  c.drawOval(bo.inflate(.03), _shade(_lg(bc + const Offset(-.2, -.18), bc + const Offset(.2, .18), [NeferhooPalette.goldHi, NeferhooPalette.gold, NeferhooPalette.goldShade, NeferhooPalette.goldDeep], const [0, .3, .7, 1])));
  c.drawOval(bo, _shade(_rg(bc + const Offset(-.08, -.07), .3, [NeferhooPalette.lapisLit, NeferhooPalette.lapis, NeferhooPalette.lapisShade], const [0, .42, 1])));
  // fine crazing in the enamel (m6: the badge is LAPIS enamel like the brow badge, so teal means only "magic")
  c.drawPath(Path()
    ..moveTo(bc.dx + .12, bc.dy - .15)
    ..lineTo(bc.dx + .09, bc.dy - .08)
    ..lineTo(bc.dx + .13, bc.dy - .03)
    ..moveTo(bc.dx - .17, bc.dy + .1)
    ..lineTo(bc.dx - .1, bc.dy + .12)
    ..lineTo(bc.dx - .08, bc.dy + .17), _stroke(NeferhooPalette.lapisDeep, .012, .6));
  // the winged envelope in gold
  final env = Rect.fromCenter(center: bc + const Offset(0, .005), width: .15, height: .1);
  for (final sgn in [-1.0, 1.0]) {
    final wing = Path()
      ..moveTo(bc.dx + sgn * .075, bc.dy - .015)
      ..quadraticBezierTo(bc.dx + sgn * .15, bc.dy - .1, bc.dx + sgn * .205, bc.dy - .05)
      ..quadraticBezierTo(bc.dx + sgn * .17, bc.dy - .035, bc.dx + sgn * .185, bc.dy - .005)
      ..quadraticBezierTo(bc.dx + sgn * .13, bc.dy + .0, bc.dx + sgn * .075, bc.dy + .03)
      ..close();
    c.drawPath(wing, _fill(NeferhooPalette.goldLit));
    c.drawPath(wing, _stroke(NeferhooPalette.goldDeep, .012, .8));
  }
  c.drawRect(env, _fill(NeferhooPalette.goldHi));
  c.drawRect(env, _stroke(NeferhooPalette.goldDeep, .014));
  c.drawPath(Path()
    ..moveTo(env.left, env.top)
    ..lineTo(env.center.dx, env.center.dy + .005)
    ..lineTo(env.right, env.top), _stroke(NeferhooPalette.goldDeep, .014));
  // glaze gloss
  c.drawPath(Path()
    ..moveTo(bc.dx - .17, bc.dy - .09)
    ..quadraticBezierTo(bc.dx - .12, bc.dy - .15, bc.dx - .03, bc.dy - .15), _stroke(const Color(0xffffffff), .028, .75));
  c.drawOval(bo, _stroke(NeferhooPalette.ink, .022, .85));
  c.drawOval(bo.inflate(.03), _stroke(NeferhooPalette.ink, .03));
  // rivets either side of the badge
  for (final sgn in [-1.0, 1.0]) {
    c.drawCircle(bc + Offset(sgn * .32, 0), .028, _fill(NeferhooPalette.gold));
    c.drawCircle(bc + Offset(sgn * .32, 0), .028, _stroke(NeferhooPalette.ink, .014));
  }
}

/// A thin ink arc on the belly's right edge, drawn AFTER the rump fan (it is part
/// of the straps' layer, which the rig paints right after the rump): where the fan's
/// roots fade into the wraps the body's outline is hidden, and without this the belly
/// smears into the tail at close-up scale (m5): the egg stays an egg.
Path _bellyArc() {
  final m = NeferhooKit.smoothPath(_Geo.bodyPts).computeMetrics().first;
  double nearest(Offset t) {
    var best = 1e9, at = 0.0;
    for (var d = 0.0; d < m.length; d += .01) {
      final q = m.getTangentForOffset(d)!.position;
      final dd = (q - t).distance;
      if (dd < best) {
        best = dd;
        at = d;
      }
    }
    return at;
  }

  final d0 = nearest(const Offset(1.6, -.12)), d1 = nearest(const Offset(1.0, .72));
  return m.extractPath(math.min(d0, d1), math.max(d0, d1));
}

/// The two shoulder straps (over the near shoulder and round the back),
/// stitched, riveted, with a linen binding on one: all of it in body space.
void _drawStraps(Canvas c) {
  c.save();
  c.clipPath(_Geo.body);
  const w = .17;
  for (final (p0, p1, p2, p3, bound) in [
    (const Offset(.1, .26), const Offset(.0, -.1), const Offset(.12, -.5), const Offset(.4, -1.05), true),
    (const Offset(1.06, .26), const Offset(1.12, -.1), const Offset(.9, -.5), const Offset(.6, -1.05), false),
  ]) {
    final cl = <Offset>[], hs = <double>[];
    for (var i = 0; i <= 14; i++) {
      final t = i / 14, u = 1 - t;
      cl.add(p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t));
      hs.add(w / 2);
    }
    final band = _Band(cl, hs);
    final shape = band.shape;
    c.drawPath(shape.shift(const Offset(-.025, .03)), _fill(NeferhooPalette.linenDeep, .28));
    final bx = cl.map((e) => e.dx).reduce(math.min), bX = cl.map((e) => e.dx).reduce(math.max);
    c.drawPath(shape, _shade(_lg(Offset(bx - w / 2, 0), Offset(bX + w / 2, 0), [NeferhooBodyInk.leatherDark, NeferhooBodyInk.bagShade, NeferhooBodyInk.bag, NeferhooBodyInk.leatherHi], const [0, .35, .75, 1])));
    c.drawPath(NeferhooKit.smoothPath(band.line(.78), close: false), _stroke(NeferhooBodyInk.leatherHi, .02, .7));
    c.drawPath(_dashed(NeferhooKit.smoothPath(band.line(0), close: false), .05, .035), _stroke(NeferhooBodyInk.thread, .016, .85));
    c.drawPath(shape, _stroke(NeferhooPalette.ink, NeferhooLayout.detail * 1.1));
    if (bound) {
      // a linen binding wound round the repaired strap
      for (final t in [.52, .62, .72]) {
        final i = (t * 14).round();
        final q = cl[i];
        final d = cl[math.min(14, i + 1)] - cl[math.max(0, i - 1)];
        final ang = math.atan2(d.dy, d.dx) + 1.2;
        c.save();
        c.translate(q.dx, q.dy);
        c.rotate(ang);
        final wrap = RRect.fromRectAndRadius(const Rect.fromLTWH(-.13, -.045, .26, .09), const Radius.circular(.02));
        c.drawRRect(wrap, _shade(_lg(const Offset(0, -.045), const Offset(0, .045), [NeferhooPalette.linenHi, NeferhooPalette.linen, NeferhooPalette.linenShade])));
        c.drawRRect(wrap, _stroke(NeferhooPalette.ink, .018, .85));
        c.restore();
      }
    }
    // a gold rivet and its washer
    final rv = cl[4];
    c.drawCircle(rv, .052, _fill(NeferhooPalette.goldShade));
    c.drawCircle(rv, .04, _shade(_rg(rv - const Offset(.012, .012), .05, [NeferhooBodyInk.brassHi, NeferhooPalette.gold, NeferhooPalette.goldShade])));
    c.drawCircle(rv, .052, _stroke(NeferhooPalette.ink, .015));
  }
  c.restore();
  c.drawPath(_bellyArc(), _stroke(NeferhooPalette.ink, .04, .5));
}

/// Gradients of the pose-driven parts: built once, each in the local frame its
/// part draws in (so a frame builds no shader at all).
abstract final class _Sh {
  static const knotAt = Offset(-.48, -.4);
  /// The near thigh's roundness: the trouser darkens toward its hem.
  static final thighShade = _lg(Offset(0, NeferhooLayout.hipNear.dy + .08), Offset(0, NeferhooLayout.hipNear.dy + .27), [NeferhooPalette.linenDeep.withValues(alpha: 0), NeferhooPalette.linenDeep.withValues(alpha: .2)]);
  static final anklet = _lg(const Offset(0, -.04), const Offset(0, .04), [NeferhooPalette.goldHi, NeferhooPalette.gold, NeferhooPalette.goldDeep], const [0, .4, 1]);
  /// The near foot's volume, in the foot's own frame (origin the foot, +y down
  /// the tarsus): lighter at the ankle, a shade darker at the toe tips.
  /// The leg-feather fringe: cream at the hem's edge to cinnamon.
  static final fringe = _lg(Offset(0, NeferhooLayout.hipNear.dy + .2), Offset(0, NeferhooLayout.hipNear.dy + .45), [NeferhooPalette.cinn, NeferhooPalette.cinnLit]);
  static final rim = _lg(const Offset(0, -.5), const Offset(0, 1.0), [NeferhooPalette.linenHi, NeferhooPalette.linenLit, NeferhooPalette.linenShade]);
  static final plumage = _lg(const Offset(0, -.4), const Offset(0, 1.05), [NeferhooPalette.cinnShade, NeferhooPalette.cinn, NeferhooPalette.cinn, NeferhooPalette.cinnLit, NeferhooBodyInk.creamBelly], const [0, .22, .5, .78, 1]);
  static final knotLoop = _lg(knotAt + const Offset(0, -.09), knotAt + const Offset(0, .05), [NeferhooBodyInk.linenWarmHi, NeferhooBodyInk.linenWarm, NeferhooBodyInk.linenWarmShade], const [0, .5, 1]);
  static final knotBall = _rg(knotAt - const Offset(.008, .008), .04, [NeferhooBodyInk.linenWarmHi, NeferhooBodyInk.linenWarm, NeferhooBodyInk.linenWarmShade]);
  static final env = _lg(const Offset(-.17, -.12), const Offset(.17, .12), [NeferhooPalette.papyrusHi, NeferhooPalette.papyrus, NeferhooPalette.papyrusShade]);
  static final roll = _lg(const Offset(-.18, -.075), const Offset(-.18, .075), [NeferhooPalette.papyrusHi, NeferhooPalette.papyrus, NeferhooPalette.papyrusShade]);
  static final note = _lg(const Offset(-.15, -.13), const Offset(.15, .13), [NeferhooPalette.papyrusHi, NeferhooPalette.papyrus, NeferhooPalette.papyrusShade]);
}

// ===========================================================================
// PLAY level: what the body is at 41 px per unit. The concept's big light
// shapes (a white banded body, a bold collar, a plain red bag) with the new
// craft kept INSIDE them: no weave, no inscription, no stitching, no tooling.

/// The neck, the radial-lit body and the SAME strips as the close-up level (the
/// layout is shared), batched by role: the winds' fills (three tones), their
/// shadows, lit lips, plum under-lines and cut ends in ONE draw each; the two
/// cross winds one by one (they overlap); the hip strips batched; the stamp pad
/// and the darned patch; a light belly shade. About 28 ops.
void _drawWrapsPlay(Canvas c) {
  final neck = _Geo.neck;
  c.drawPath(neck, _shade(_lg(const Offset(-1.3, -1.5), const Offset(-.3, -.4), [NeferhooPalette.linenLit, NeferhooPalette.linenShade])));
  c.drawPath(neck, _stroke(NeferhooPalette.ink, NeferhooLayout.part));
  final body = _Geo.body;
  c.drawPath(body, _shade(_rg(const Offset(-.45, -.6), 2.4, [NeferhooPalette.linenHi, NeferhooPalette.linenLit, NeferhooPalette.linen, NeferhooPalette.linenShade], const [0, .22, .58, 1])));
  c.save();
  c.clipPath(body);
  c.drawPath(_Geo.gapShade, _fill(NeferhooBodyInk.gapShade));
  // the winds, one draw per role: the parts are cut against the winds lying over them at build time
  // (`_Geo.windParts`), so the crossing winds hide what they should
  final wp = _Geo.windParts;
  c.drawPath(wp.fill[0], _fill(NeferhooBodyInk.playCool));
  c.drawPath(wp.fill[1], _fill(NeferhooPalette.linenLit));
  c.drawPath(wp.fill[2], _fill(NeferhooBodyInk.playWarm));
  c.drawPath(wp.shadow, _fill(NeferhooPalette.linenDeep, _castMajorAlpha));
  c.drawPath(wp.lip, _fill(NeferhooBodyInk.lip));
  c.drawPath(wp.seamMinor, _fill(NeferhooBodyInk.linenLine, .4));
  c.drawPath(wp.seamMajor, _fill(NeferhooBodyInk.seam));
  final ends = Path();
  // the cross winds, then the hip strips (both batched by role), laid over. The two cross winds do
  // not touch each other, so one path per role does for both (i3-body: 9 draws -> 5)
  final hipFill = Path(), hipShade = Path(), hipLip = Path(), hipUnder = Path();
  final xShadow = Path(), xWarm = Path(), xCool = Path(), xLip = Path(), xUnder = Path();
  for (final st in _Geo.crosses) {
    final b = st.band;
    if (st.hip) {
      hipFill.addPath(b.shape, Offset.zero);
      hipShade.addPath(NeferhooKit.smoothPath(b.bottom, close: false), const Offset(-.01, .035));
      hipLip.addPath(NeferhooKit.smoothPath(b.top, close: false), Offset.zero);
      hipUnder.addPath(NeferhooKit.smoothPath(b.bottom, close: false), Offset.zero);
      continue;
    }
    xShadow.addPath(b.shape, const Offset(-.03, .055));
    (st.tone > .1 ? xWarm : xCool).addPath(b.shape, Offset.zero);
    xLip.addPath(NeferhooKit.smoothPath(b.top, close: false), Offset.zero);
    xUnder.addPath(NeferhooKit.smoothPath(b.bottom, close: false), Offset.zero);
    if (st.cut) ends.addPath(_cutEnd(b), Offset.zero);
  }
  c.drawPath(xShadow, _fill(NeferhooPalette.linenDeep, .42));
  c.drawPath(xWarm, _fill(NeferhooBodyInk.playWarm));
  c.drawPath(xCool, _fill(NeferhooPalette.linenLit));
  c.drawPath(xLip, _stroke(NeferhooBodyInk.lip, .05));
  c.drawPath(xUnder, _stroke(NeferhooBodyInk.seam, .075));
  c.drawPath(ends, _stroke(NeferhooBodyInk.seam, .042, 1, StrokeCap.butt));
  c.drawPath(hipFill, _fill(NeferhooBodyInk.playWarm));
  c.drawPath(hipShade, _stroke(NeferhooPalette.linenDeep, .08, .4, StrokeCap.butt));
  c.drawPath(hipLip, _stroke(NeferhooBodyInk.lip, .036));
  c.drawPath(hipUnder, _stroke(NeferhooBodyInk.linenLine, .048));
  // a little roundness: the back and the belly a shade darker
  c.drawPath(body, _shade(_lg(const Offset(-1.2, -1.0), const Offset(1.4, 1.1), [NeferhooPalette.linenDeep.withValues(alpha: 0), NeferhooPalette.linenDeep.withValues(alpha: 0), NeferhooPalette.linenDeep.withValues(alpha: .50)], const [0, .32, 1])));
  c.restore();
}

/// The warm rim on the sun side and the hero outline.
void _drawFinishPlay(Canvas c) {
  final body = _Geo.body;
  c.save();
  c.clipPath(body);
  c.drawPath(body, Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = .2
    ..shader = _lg(const Offset(1.5, -1.1), const Offset(-.3, .3), [NeferhooPalette.rim.withValues(alpha: .8), NeferhooPalette.rim.withValues(alpha: .3), NeferhooPalette.rim.withValues(alpha: 0)], const [0, .5, 1]));
  c.restore();
  c.drawPath(body, _stroke(NeferhooPalette.ink, NeferhooLayout.hero, 1));
}

/// The collar at the play level: the SAME rows, pendants and buds as the close-up
/// (`_drawCollar`), each row one stroke, the pendants one fill per colour and one
/// ink line, no bead cells. About 15 ops.
void _drawCollarPlay(Canvas c) {
  c.save();
  c.clipPath(_Geo.body);
  c.drawPath(_collarArc(1.31), _stroke(NeferhooPalette.linenDeep, .3, .26));
  c.restore();
  final pend = _collarPendants(Path());
  final pendCols = [NeferhooPalette.turq, NeferhooBodyInk.bag, NeferhooPalette.goldLit, NeferhooBodyInk.bag];
  for (var i = 0; i < 4; i++) {
    c.drawPath(pend[i], _fill(pendCols[i]));
  }
  c.drawPath(pend.fold(Path(), (acc, p) => acc..addPath(p, Offset.zero)), _stroke(NeferhooPalette.ink, .03));
  for (final (r0, r1, col, _, _) in _collarRows) {
    c.drawPath(_collarArc((r0 + r1) / 2), _stroke(col, r1 - r0, 1, StrokeCap.butt));
  }
  // a lit lip along the lapis row, the rows' dividers, the outline
  c.drawPath(_collarArc(.99), _stroke(NeferhooPalette.lapisLit, .03, .85, StrokeCap.butt));
  final lines = Path();
  for (final (r0, _, _, _, _) in _collarRows.skip(1)) {
    lines.addPath(_collarArc(r0), Offset.zero);
  }
  c.drawPath(lines, _stroke(NeferhooPalette.ink, .024, .7));
  c.drawPath(_collarArc(.54)..addPath(_collarArc(1.05), Offset.zero), _stroke(NeferhooPalette.ink, NeferhooLayout.part));
  // the lotus buds and their beads
  final buds = _collarBuds(Path());
  c.drawPath(buds, _fill(NeferhooPalette.goldLit));
  c.drawPath(buds, _stroke(NeferhooPalette.ink, .034));
  c.drawPath(_collarBeads(), _fill(NeferhooPalette.lapis));
}

/// The bag: back wall with its dark mouth, then the plain red front panel.
void _drawBagPlay(Canvas c) {
  final back = _bagRect.shift(const Offset(.045, -.035));
  c.drawRRect(back, _fill(NeferhooBodyInk.bagDeep));
  c.drawRRect(back, _stroke(NeferhooPalette.ink, NeferhooLayout.part));
  c.drawPath(Path()
    ..moveTo(-.55, -.4)
    ..quadraticBezierTo(0, -.58, .6, -.4)
    ..lineTo(.6, -.3)
    ..lineTo(-.55, -.3)
    ..close(), _fill(const Color(0xff3a1220)));
}

/// The front panel (drawn after the letters), its stitched border one line.
void _drawBagFrontPlay(Canvas c) {
  final bag = _bagRect;
  c.drawRRect(bag, _shade(_lg(const Offset(-.3, -.45), const Offset(.3, .45), [NeferhooBodyInk.bagLit, NeferhooBodyInk.bag, NeferhooBodyInk.bagShade], const [0, .45, 1])));
  c.drawPath(Path()..addRRect(bag.deflate(.07)), _stroke(NeferhooBodyInk.bagDeep, .02, .7));
  c.drawRRect(bag, _stroke(NeferhooPalette.ink, NeferhooLayout.part + .01));
}

/// The flap: a plain red tongue with a brass buckle.
void _drawFlapPlay(Canvas c) {
  final flap = Path()
    ..moveTo(-.6, 0)
    ..lineTo(.6, 0)
    ..lineTo(.57, .3)
    ..quadraticBezierTo(.5, .5, .08, .55)
    ..quadraticBezierTo(0, .6, -.08, .55)
    ..quadraticBezierTo(-.5, .5, -.57, .3)
    ..close();
  c.drawPath(flap.shift(const Offset(-.02, .05)), _fill(const Color(0xff3a1220), .35));
  c.drawPath(flap, _shade(_lg(const Offset(0, 0), const Offset(0, .55), [NeferhooBodyInk.leatherHi, NeferhooBodyInk.bag, NeferhooBodyInk.bagShade], const [0, .4, 1])));
  c.drawPath(flap, _stroke(NeferhooPalette.ink, NeferhooLayout.part + .01));
  c.drawPath(Path()
    ..moveTo(-.55, .015)
    ..lineTo(.55, .015), _stroke(NeferhooBodyInk.leatherHi, .03, .8));
  final buckle = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, .5), width: .22, height: .15), const Radius.circular(.04));
  c.drawRRect(buckle, _stroke(NeferhooPalette.ink, .066));
  c.drawRRect(buckle, _stroke(NeferhooPalette.goldLit, .036));
}

/// The Pharaoh's Post badge: a gold-rimmed lapis enamel disc and a winged letter.
/// Drawn on the bag, over the flap, so it stays in view when the flap opens.
void _drawBadgePlay(Canvas c) {
  const bc = Offset(0, 0);
  final bo = Rect.fromCenter(center: bc, width: .5, height: .4);
  c.drawOval(bo.inflate(.04).shift(const Offset(-.01, .02)), _fill(const Color(0xff3a1220), .3));
  c.drawOval(bo.inflate(.035), _fill(NeferhooPalette.goldLit));
  c.drawOval(bo, _shade(_rg(bc + const Offset(-.08, -.07), .3, [NeferhooPalette.lapisLit, NeferhooPalette.lapis, NeferhooPalette.lapisShade], const [0, .42, 1])));
  for (final sgn in [-1.0, 1.0]) {
    final wing = Path()
      ..moveTo(bc.dx + sgn * .075, bc.dy - .015)
      ..quadraticBezierTo(bc.dx + sgn * .15, bc.dy - .1, bc.dx + sgn * .205, bc.dy - .05)
      ..quadraticBezierTo(bc.dx + sgn * .13, bc.dy + .0, bc.dx + sgn * .075, bc.dy + .03)
      ..close();
    c.drawPath(wing, _fill(NeferhooPalette.goldLit));
  }
  final env = Rect.fromCenter(center: bc + const Offset(0, .005), width: .15, height: .1);
  c.drawRect(env, _fill(NeferhooPalette.goldHi));
  c.drawRect(env, _stroke(NeferhooPalette.goldDeep, .016));
  c.drawOval(bo, _stroke(NeferhooPalette.ink, .024, .9));
  c.drawOval(bo.inflate(.035), _stroke(NeferhooPalette.ink, .03));
}

/// The two shoulder straps: bold carnelian bands with a rivet and the linen
/// binding on the repaired one (the same binding as the close-up). The straps do
/// not overlap, so each role is ONE draw: shadows, fills, lit lines, inks, rivets.
void _drawStrapsPlay(Canvas c) {
  c.save();
  c.clipPath(_Geo.body);
  const w = .19;
  final shadow = Path(), fill = Path(), lit = Path(), ink = Path(), binding = Path(), rivet = Path();
  var first = true;
  for (final (p0, p1, p2, p3) in [
    (const Offset(.1, .26), const Offset(.0, -.1), const Offset(.12, -.5), const Offset(.4, -1.05)),
    (const Offset(1.06, .26), const Offset(1.12, -.1), const Offset(.9, -.5), const Offset(.6, -1.05)),
  ]) {
    final cl = <Offset>[], hs = <double>[];
    for (var i = 0; i <= 10; i++) {
      final t = i / 10, u = 1 - t;
      cl.add(p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t));
      hs.add(w / 2);
    }
    final band = _Band(cl, hs);
    final shape = band.shape;
    shadow.addPath(shape, const Offset(-.025, .03));
    fill.addPath(shape, Offset.zero);
    lit.addPath(NeferhooKit.smoothPath(band.line(.7), close: false), Offset.zero);
    ink.addPath(shape, Offset.zero);
    if (first) {
      for (final t in [.52, .62, .72]) {
        final i = (t * 10).round();
        final q = cl[i];
        final d = cl[math.min(10, i + 1)] - cl[math.max(0, i - 1)];
        final ang = math.atan2(d.dy, d.dx) + 1.2;
        final ca = math.cos(ang), sa = math.sin(ang);
        final tr = Float64List.fromList([ca, sa, 0, 0, -sa, ca, 0, 0, 0, 0, 1, 0, q.dx, q.dy, 0, 1]);
        binding.addPath((Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-.13, -.045, .26, .09), const Radius.circular(.02)))).transform(tr), Offset.zero);
      }
      first = false;
    }
    rivet.addOval(Rect.fromCircle(center: cl[3], radius: .05));
  }
  c.drawPath(shadow, _fill(NeferhooPalette.linenDeep, .3));
  c.drawPath(fill, _fill(NeferhooBodyInk.bag));
  c.drawPath(lit, _stroke(NeferhooBodyInk.leatherHi, .03, .8));
  c.drawPath(ink, _stroke(NeferhooPalette.ink, NeferhooLayout.detail * 1.2));
  // the linen binding wound round the repaired strap
  c.drawPath(binding, _fill(NeferhooPalette.linenLit));
  c.drawPath(binding, _stroke(NeferhooPalette.ink, .02, .85));
  c.drawPath(rivet, _fill(NeferhooPalette.goldLit));
  c.drawPath(rivet, _stroke(NeferhooPalette.ink, .02));
  c.restore();
  c.drawPath(_bellyArc(), _stroke(NeferhooPalette.ink, .04, .5));
}

// ===========================================================================
// the painter's extension

extension NeferhooBodyArt on NeferhooPainter {
  /// Every part of the body in the rig's own order: what `paint()` asks of the
  /// canvas for the owned layers (the budget test counts it).
  void paintBodyParts() {
    paintLeg(NeferhooLayout.hipFar, far: true);
    paintLeg(NeferhooLayout.hipNear, far: false);
    paintBodyBase();
    paintBodyGlyphs();
    paintBodyOpening();
    paintBodyFinish();
    paintLegOver();
    paintStraps();
    paintSatchel();
    paintCollar();
  }

  /// The cached layers by name, each as its drawing function: they are one
  /// draw call each per frame, but their ops still replay on the raster
  /// thread (the budget test counts them).
  static Map<String, void Function(Canvas)> get cachedLayers => {
    'neck': _drawNeck,
    'wraps': _drawWraps,
    'finish': _drawFinish,
    'straps': _drawStraps,
    'collar': _drawCollar,
    'bagBack': _drawBagBack,
    'bagFront': _drawBagFront,
    'badge': _drawBadge,
    'pad': (c) => _drawPad(c, full: true),
    'flap': (c) => _drawFlap(c, face: true),
  };

  Path get bodyOutline => _Geo.body;
  Path get neckOutline => _Geo.neck;

  // ------------------------------------------------------------- the wraps

  /// The neck and the wraps: the cinnamon plumage under the linen, the
  /// strips, the weave, the patches (cached).
  void paintBodyBase() {
    if (play) {
      c.drawPicture(_Geo.wrapsPlay);
    } else {
      c.drawPicture(_Geo.neckPic);
      c.drawPicture(_Geo.wraps);
    }
    // the stamp pad: its own picture, over the strips (they pass behind it); it is gone from a beaten
    // old bird's belly (m1) and gives a little under the wingtip's rubbing (M4)
    if (_target > .02) {
      final flexed = _beginFlex();
      c.drawPicture(play ? _Geo.padPlay : _Geo.pad);
      if (flexed) c.restore();
    }
  }

  /// m1: how much of the target (pad, ring, seal, inscription) is there, 0..1. The mask is on: all of it.
  /// The mask is off (the defeat, the story's beaten old bird): it goes as the wraps come away, and is gone
  /// by unwrap .6 (the story's beaten poses), so a kindly old hoopoe has no bull's-eye on his belly.
  double get _target => p.mask ? 1.0 : 1 - NeferhooKit.smooth01((p.unwrap - .3) / .3);

  /// M4 (the open-sky gag): the wingtip rubs the postmark. While `buff` > 0 the pad, ring and seal give a
  /// little under it: a squash along the stroke and a nudge with it, the stroke being `sin(phase * 12)`
  /// (`NeferhooBodyInk.buffWipe`; the timeline carries the wipe cycle in `phase`). Saves the canvas and returns true
  /// when it moved it; the caller restores.
  bool _beginFlex() {
    final b = p.buff.clamp(0.0, 1.0);
    if (b <= 0.001 || p.reduced) return false;
    final w = math.sin(p.phase * NeferhooBodyInk.buffWipe) * NeferhooKit.smooth01((p.buff - .55) / .35); // (the wing's own wipe weight)
    final k = b * (.4 + .6 * w.abs());
    c.save();
    c.translate(NeferhooLayout.postmark.dx + .05 * b * w, NeferhooLayout.postmark.dy + .01 * b * w.abs());
    c.scale(1 - .09 * k, 1 + .05 * k);
    c.translate(-NeferhooLayout.postmark.dx, -NeferhooLayout.postmark.dy);
    return true;
  }

  /// The postmark and the address block on the wraps: faint turquoise
  /// ink that wakes up with [NeferhooPose.glow] and [NeferhooPose.fury].
  void paintBodyGlyphs() {
    if (silhouette) return;
    // m1: a beaten old bird has no target on his belly
    final tgt = _target;
    if (tgt <= .02) return;
    final g = math.max(p.glow, p.fury * .9).clamp(0.0, 1.0);
    // a pulse that walks along the address when the glyphs are awake
    final flick = .85 + .15 * math.sin(p.phase * 7);
    // once the wraps have come away the faint ink fades with them, but awake
    // glyphs hover over the plumage like a magic seal
    final cover = p.unwrap.clamp(0.0, 1.0) * (1 - g);
    // the target: a rubber-stamp ring on the stamp pad, the HIGHEST-contrast mark on
    // the chest in every pose (the strips pass behind its pad; f2-body). At rest a
    // postal-red ring with a dark halo; while he deals (the mail call) it turns
    // teal and pulses ("return it HERE"): the halo stays dark so it never washes out.
    final dealing = math.max(p.satchelOpen, g).clamp(0.0, 1.0);
    final pulse = dealing * (.5 + .5 * math.sin(p.phase * 7));
    final ringCol = Color.lerp(NeferhooPalette.stampInk, const Color(0xff1c9d98), NeferhooKit.smooth01((dealing - .35) / .15))!; // red until he really deals: a short cross-fade, no muddy mid-colour
    final at = NeferhooLayout.postmark;
    final rest = (1 - cover * .8) * tgt;
    final flexed = _beginFlex();
    if (dealing > .02) {
      c.drawCircle(at, NeferhooLayout.postmarkR + .08 + .05 * pulse, _stroke(NeferhooPalette.magic, .1, .22 * dealing * tgt));
    }
    // awake (fury, glow): the seal glows. A pale light field under the ring keeps it the
    // brightest-against-darkest mark where the pad has torn away with the wraps
    if (g > .02) c.drawCircle(at, NeferhooLayout.postmarkR - .03, _fill(const Color(0xfffff6e2), .5 * g * tgt));
    // a rubber-stamp ring: a touch off-round (x 1.04) with two small ink drop-outs
    // (10 degrees each, at 1 and 7 o'clock), like a real postmark
    final ringRect = Rect.fromCenter(center: at, width: NeferhooLayout.postmarkR * 2.08, height: NeferhooLayout.postmarkR * 2);
    final ring = Path()
      ..addArc(ringRect, -55 * math.pi / 180, 170 * math.pi / 180)
      ..addArc(ringRect, 125 * math.pi / 180, 170 * math.pi / 180);
    c.drawPath(ring, _stroke(NeferhooPalette.ink, .125, (.56 + .26 * dealing) * rest));
    c.drawPath(ring, _stroke(ringCol, .07, .88 * rest));
    if (dealing > .1) c.drawCircle(at, NeferhooLayout.postmarkR - .13, _stroke(ringCol, .035, (.7 + .3 * pulse) * dealing * tgt));
    c.drawCircle(at, .075, _fill(NeferhooPalette.ink, .85 * rest));
    c.drawCircle(at, .052, _fill(NeferhooPalette.goldLit, rest));
    _ringShine(ringRect, dealing, tgt);
    if (flexed) c.restore();
    if (play) return;
    final ink = Color.lerp(NeferhooPalette.turqShade, NeferhooPalette.magic, g)!;
    if (g > 0.02) {
      c.drawPath(_Geo.glyphPath, _stroke(NeferhooPalette.magic, .085, .15 * g * flick * tgt));
    }
    final a = (.4 + .6 * g) * (g > .02 ? flick : 1) * (1 - cover * .9) * tgt;
    c.drawPath(_Geo.glyphPath, _stroke(ink, .026 + .01 * g, a));
  }

  /// M4: the ring's answers to the open-sky gag, drawn in the (flexed) postmark frame. One sparkle, a
  /// four-point star with an ink edge (it reads on the white pad as well as on the red ring), twinkles
  /// at the rim with every wipe while `buff` > 0 ("squeak, squeak"); then the `glint` channel
  /// (0..1 = where the gleam is on its sweep) runs a white gleam along the top of the ring with a star
  /// at its head. A glint while he deals (the mail lock, the ankh lock: the ring is teal and pulsing
  /// already, `dealing` > .12) is left to the mask. Nothing in a calm frame: 0 ops there; 3 in the gag.
  void _ringShine(Rect ringRect, double dealing, double tgt) {
    if (p.reduced) return;
    final at = NeferhooLayout.postmark;
    final quiet = (1 - NeferhooKit.smooth01(dealing / .12)) * tgt;
    // the gleam along the ring (glint 0..1): from the upper left over the top to the upper right
    if (p.ringGlint >= 0 && p.ringGlint <= 1 && quiet > .02) {
      // (the ring's OWN channel: the mask's `glint` at the locks never makes it gleam)
      final k = math.min(1.0, math.sin(p.ringGlint * math.pi) * 1.35) * quiet;
      final a = (200 + 140 * p.ringGlint) * math.pi / 180;
      c.drawArc(ringRect, a - .55, 1.1, false, _stroke(const Color(0xffffffff), .10, .95 * k));
      _star(Offset(ringRect.center.dx + math.cos(a) * ringRect.width / 2, ringRect.center.dy + math.sin(a) * ringRect.height / 2), .10 + .26 * k, k);
    } else if (p.buff > .02) {
      // a twinkle with every wipe: at the upper-left rim when the stroke goes right, at the left when it
      // comes back; strongest at the turn
      final w = math.sin(p.phase * NeferhooBodyInk.buffWipe) * NeferhooKit.smooth01((p.buff - .55) / .35);
      // the polish: one bright diagonal streak runs across the pad with the wingtip (it is what
      // tells the eye "he is rubbing it", at 1x as at 4x)
      if (p.buff > .3 && quiet > .1) {
        final x = at.dx + .30 * w;
        c.drawLine(Offset(x - .11, at.dy + .27), Offset(x + .11, at.dy - .27), _stroke(const Color(0xffffffff), .085, .85 * p.buff.clamp(0.0, 1.0) * quiet));
      }
      final k = p.buff.clamp(0.0, 1.0) * NeferhooKit.smooth01((w.abs() - .5) / .5) * quiet;
      if (k > .02) {
        final a = (w > 0 ? 218 : 168) * math.pi / 180;
        _star(at + Offset(math.cos(a) * NeferhooLayout.postmarkR * 1.04, math.sin(a) * NeferhooLayout.postmarkR), .09 + .20 * k, k);
      }
    }
  }

  /// A four-point sparkle: a white star with an ink edge (two ops).
  void _star(Offset at, double r, double alpha) {
    final q = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final rr = i.isEven ? r : r * .3;
      final pt = at + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? q.moveTo(pt.dx, pt.dy) : q.lineTo(pt.dx, pt.dy);
    }
    q.close();
    c.drawPath(q, _stroke(NeferhooPalette.ink, .03, .7 * alpha));
    c.drawPath(q, _fill(const Color(0xffffffff), (alpha * 1.25).clamp(0.0, 1.0)));
  }

  /// The unwrap opening (cinnamon breast through torn linen), the cracked
  /// tears, drawn between the wraps and the shading.
  void paintBodyOpening() {
    if (silhouette) return;
    final u = p.unwrap.clamp(0.0, 1.0);
    if (u > .01) {
      c.save();
      c.clipPath(_Geo.body);
      final cx = -.42, cy = .32 - u * .05;
      final a = .3 + .8 * u, b = .16 + .62 * u;
      // the torn linen rim: a jagged edge with frayed teeth
      final rim = Path();
      const n = 30;
      for (var k = 0; k < n; k++) {
        final t = k / n * math.pi * 2;
        final tooth = k.isEven ? 1.1 : .98;
        final jag = tooth + (_hash(k + 200) - .5) * .09;
        final q = Offset(cx + math.cos(t) * (a + .13) * jag, cy + math.sin(t) * (b + .12) * jag);
        k == 0 ? rim.moveTo(q.dx, q.dy) : rim.lineTo(q.dx, q.dy);
      }
      rim.close();
      c.drawPath(rim.shift(const Offset(-.025, .045)), _fill(NeferhooPalette.linenDeep, .4));
      c.drawPath(rim, _shade(_Sh.rim));
      c.drawPath(rim, _stroke(NeferhooPalette.ink, .034, .8));
      final inner = NeferhooKit.smoothPath([
        for (var k = 0; k < 12; k++)
          Offset(cx + math.cos(k / 12 * math.pi * 2) * a * (1 + (_hash(k + 230) - .5) * .06), cy + math.sin(k / 12 * math.pi * 2) * b * (1 + (_hash(k + 250) - .5) * .06)),
      ]);
      c.drawPath(inner, _shade(_Sh.plumage));
      if (play) {
        // PLAY: the warm breast through the torn linen, one shade at its edge
        c.drawPath(inner, _stroke(NeferhooPalette.cinnShade, .14, .5));
        c.drawPath(inner, _stroke(NeferhooPalette.ink, NeferhooLayout.detail));
        c.restore();
        if (p.cracked > 0) _tears();
        return;
      }
      c.save();
      c.clipPath(inner);
      final rows = Path();
      for (var row = 0; row < 9; row++) {
        for (var k = -6; k < 7; k++) {
          final x = cx + k * .2 + (row.isOdd ? .1 : 0);
          final y = cy - b + row * .2 + .1;
          rows.addArc(Rect.fromLTWH(x - .1, y - .1, .2, .2), .15, math.pi - .3);
        }
      }
      c.drawPath(rows, _stroke(NeferhooPalette.cinnShade, .03, .7));
      final streaks = Path();
      for (var k = 0; k < 14; k++) {
        final x = cx - a * .8 + _hash(k + 300) * a * 1.6, y = cy + b * (.1 + .6 * _hash(k + 330));
        streaks.moveTo(x, y);
        streaks.lineTo(x - .02, y + .09);
      }
      c.drawPath(streaks, _stroke(NeferhooBodyInk.streak, .026, .5));
      // the linen's edge shades the plumage
      c.drawPath(inner, _stroke(NeferhooPalette.cinnShade, .16, .55));
      c.restore();
      c.drawPath(inner, _stroke(NeferhooPalette.ink, NeferhooLayout.detail));
      c.restore();
    }
    if (p.cracked > 0) _tears();
  }

  /// Magic seeping out of tears in the wraps.
  void _tears() {
    final tear = Path()
      ..moveTo(-1.0, .22)
      ..lineTo(-.9, .3)
      ..lineTo(-.97, .38)
      ..lineTo(-.85, .46)
      ..moveTo(.3, .95)
      ..lineTo(.4, .88)
      ..lineTo(.35, .8);
    c.drawPath(tear, _stroke(NeferhooPalette.ink, .045, p.cracked));
    c.drawPath(tear, _stroke(NeferhooPalette.magic, .022, p.cracked * .95));
  }

  /// The warm light, shadows and the hero outline (cached), then the loose
  /// strips of linen that hang over it.
  void paintBodyFinish() {
    c.drawPicture(play ? _Geo.finishPlay : _Geo.finish);
  }

  /// (Removed in the polish round, M4: the one loose strip of linen that peeled from the
  /// unwrap opening existed at the close-up level only, an object that popped in at an
  /// LOD switch; the opening itself says "unwrapped". Kept as a no-op for the rig's
  /// silhouette path.)
  void paintBodyLoose() {}

  // --------------------------------------------------------------- collar

  void paintCollar() {
    if (silhouette) {
      const ctr = _collarCtr;
      final env = Path()
        ..addArc(Rect.fromCircle(center: ctr, radius: 1.19), _collarA0, _collarA1 - _collarA0)
        ..arcTo(Rect.fromCircle(center: ctr, radius: .54), _collarA1, -(_collarA1 - _collarA0), false)
        ..close();
      c.drawPath(env, f(NeferhooPalette.ink));
      return;
    }
    if (play) {
      c.drawPicture(_Geo.collarPlay);
      return;
    }
    c.drawPicture(_Geo.collar);
    // a glint travelling along the gold rows
    final t = (p.phase * .32) % 1.0;
    if (t < .5) {
      final a = .6 + t / .5 * 1.4;
      final k = math.sin(t / .5 * math.pi);
      const ctr = Offset(-.6, -1.28);
      for (final r in [1.02, .62]) {
        final q = ctr + Offset(math.cos(a), math.sin(a)) * r;
        c.drawCircle(q, .035 + .02 * k, _fill(NeferhooBodyInk.brassHi, .9 * k));
        c.drawLine(q - const Offset(.05, 0), q + const Offset(.05, 0), _stroke(const Color(0xffffffff), .014, .8 * k));
        c.drawLine(q - const Offset(0, .05), q + const Offset(0, .05), _stroke(const Color(0xffffffff), .014, .8 * k));
      }
    }
  }

  // --------------------------------------------------------------- satchel

  void paintStraps() {
    if (silhouette) return;
    c.drawPicture(play ? _Geo.strapsPlay : _Geo.straps);
  }

  void paintSatchel() {
    final o = NeferhooLayout.satchel;
    final open = p.satchelOpen.clamp(0.0, 1.0);
    // sway on the shoulder straps (and a flinch when hit)
    final sway = math.sin(p.phase * 2.2) * .045 + p.hit * .1 - p.legs * .03;
    c.save();
    c.translate(o.dx, o.dy);
    c.translate(0, -.43);
    c.rotate(sway);
    c.translate(0, .43);
    if (silhouette) {
      c.drawRRect(_bagRect, f(NeferhooPalette.ink));
      _letters(open);
      c.restore();
      return;
    }
    if (play) {
      _satchelPlay(open);
      c.restore();
      return;
    }
    c.drawPicture(_Geo.bagBack);
    // the flap swings up on its hinge like the play level's: its height shrinks with
    // cos and never past about 80 degrees, so it stays a strip over the bag's mouth
    // (the same object at every size; a lining slab appeared at 60 px/unit before)
    final k = math.max(.2, math.cos(open * 1.35));
    _letters(open);
    c.drawPicture(_Geo.bagFront);
    c.save();
    c.translate(0, -.43);
    c.scale(1, k);
    c.drawPicture(_Geo.flapFace);
    c.restore();
    // the badge is pinned on the bag at both levels of detail (it stays when the flap lifts)
    c.save();
    c.translate(0, -.23 + .06 * open);
    c.drawPicture(_Geo.badge);
    c.restore();
    // the linen-knotted strap end tied through the bag's top corner
    _knot(_Sh.knotAt);
    // glint on the badge rim
    final gt = (p.phase * .3 + .4) % 1.0;
    if (open < .3 && gt < .22) {
      final kk = math.sin(gt / .22 * math.pi);
      final q = Offset(-.18 + gt / .22 * .36, -.43 + .2 - .1);
      c.drawLine(q - const Offset(.05, 0), q + const Offset(.05, 0), _stroke(const Color(0xffffffff), .016, .85 * kk));
      c.drawLine(q - const Offset(0, .05), q + const Offset(0, .05), _stroke(const Color(0xffffffff), .016, .85 * kk));
    }
    c.restore();
  }

  /// The bag at the play level: back wall, the dead letters (the same ones as the
  /// close-up: their tops show above the rim at rest, more when it opens), the front
  /// panel, the flap (a thin lining strip once opened), the Pharaoh's Post badge
  /// pinned on the bag, and the linen bow on its top corner.
  void _satchelPlay(double open) {
    c.drawPicture(_Geo.bagPlay);
    _letters(open);
    c.drawPicture(_Geo.bagFrontPlay);
    // the flap: hinged on the top edge; past ~60 degrees it shows as a thin
    // strip (never a big slab) and the badge stays pinned on the bag
    final k = math.cos(open * 1.35);
    c.save();
    c.translate(0, -.43);
    c.scale(1, math.max(.2, k));
    c.drawPicture(_Geo.flapPlay);
    c.restore();
    c.save();
    c.translate(0, -.23 + .06 * open);
    c.drawPicture(_Geo.badgePlay);
    c.restore();
    _knot(_Sh.knotAt);
  }

  void _knot(Offset at) {
    // a linen bow tied through the bag's top corner (the same bow at both levels of
    // detail; the close-up adds the loops' gradients and the knot's gradient): two
    // teardrop loops that point out of the knot, two ribbon ends hanging from it
    final sw = math.sin(p.phase * 3.1) * .04;
    final ends = Path()
      ..moveTo(at.dx - .01, at.dy)
      ..quadraticBezierTo(at.dx - .045 + sw, at.dy + .08, at.dx - .06 + sw * 1.5, at.dy + .16)
      ..moveTo(at.dx + .01, at.dy)
      ..quadraticBezierTo(at.dx + .045 + sw, at.dy + .07, at.dx + .065 + sw * 1.5, at.dy + .14);
    c.drawPath(ends, _stroke(NeferhooPalette.ink, .075));
    c.drawPath(ends, _stroke(NeferhooBodyInk.linenWarm, .045));
    final loops = Path();
    for (final sgn in [-1.0, 1.0]) {
      loops
        ..moveTo(at.dx, at.dy)
        ..cubicTo(at.dx + sgn * .05, at.dy - .1, at.dx + sgn * .17, at.dy - .1, at.dx + sgn * .17, at.dy - .03)
        ..cubicTo(at.dx + sgn * .17, at.dy + .04, at.dx + sgn * .06, at.dy + .05, at.dx, at.dy)
        ..close();
    }
    if (play) {
      c.drawPath(loops, _fill(NeferhooBodyInk.linenWarmHi));
      c.drawPath(loops, _stroke(NeferhooPalette.ink, .026));
      c.drawCircle(at, .04, _fill(NeferhooBodyInk.linenWarm));
      c.drawCircle(at, .04, _stroke(NeferhooPalette.ink, .022));
      return;
    }
    c.drawPath(loops, _shade(_Sh.knotLoop));
    c.drawPath(loops, _stroke(NeferhooPalette.ink, .022, .95));
    c.drawCircle(at, .04, _shade(_Sh.knotBall));
    c.drawCircle(at, .04, _stroke(NeferhooPalette.ink, .022));
  }

  /// Dead letters stuffed in the bag's mouth: two at rest, three when open; each
  /// its own paper, seal and tilt. The same letters at both levels of detail (the
  /// play level leaves out the paper's gradient, folds and ink details).
  void _letters(double open) {
    final full = p.satchelFull.clamp(0.0, 1.0);
    final peek = (.1 + open * .27) * full;
    const kinds = [0, 1, 0, 2, 0, 1];
    // the defeat scatters them: an emptying bag shows fewer, lower letters
    final count = full < .05 ? 0 : math.max(1, ((2 + (open * 1.3).floor()) * full).ceil());
    final detail = fx && !play;
    for (var k = 0; k < count; k++) {
      final x = -.28 + k * .2 + (_hash(k + 400) - .5) * .04;
      final lift = peek + (k.isOdd ? .05 : 0) * (.4 + open) + (_hash(k + 420)) * .05;
      final ang = (k - 1) * .2 + (_hash(k + 440) - .5) * .12 + math.sin(p.phase * 1.7 + k) * .02 * open;
      c.save();
      c.translate(x, -.46 - lift + .12);
      c.rotate(ang);
      switch (kinds[k % kinds.length]) {
        case 0: // an envelope
          {
          final r = Rect.fromCenter(center: Offset.zero, width: .34, height: .24);
          c.drawRect(r, f(k.isEven ? NeferhooPalette.papyrus : NeferhooPalette.papyrusHi));
          if (fx) {
            if (detail) {
              c.drawRect(r, _shade(_Sh.env));
              c.drawPath(Path()
                ..moveTo(r.left, r.top)
                ..lineTo(0, .02)
                ..lineTo(r.right, r.top), _stroke(NeferhooPalette.papyrusShade, .018, .9));
            }
            c.drawCircle(const Offset(0, .03), .04, _fill(k == 2 ? NeferhooPalette.lapis : NeferhooPalette.seal));
            c.drawRect(r, _stroke(NeferhooPalette.ink, NeferhooLayout.detail));
            // a dog-eared corner
            if (detail) {
              c.drawPath(Path()
                ..moveTo(r.right - .05, r.bottom)
                ..lineTo(r.right, r.bottom - .05), _stroke(NeferhooPalette.papyrusShade, .016));
            }
          }
          }
        case 1: // a papyrus roll, tied with a cord
          {
          final r = Rect.fromCenter(center: Offset.zero, width: .36, height: .15);
          c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(.07)), f(NeferhooPalette.papyrusHi));
          if (fx) {
            if (detail) c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(.07)), _shade(_Sh.roll));
            c.drawLine(const Offset(-.03, -.07), const Offset(-.03, .07), _stroke(NeferhooPalette.seal, .03));
            if (detail) c.drawOval(Rect.fromCenter(center: Offset(-.18, 0), width: .06, height: .15), _stroke(NeferhooPalette.papyrusShade, .016));
            c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(.07)), _stroke(NeferhooPalette.ink, NeferhooLayout.detail));
          }
          }
        default: // a folded note with a gold seal
          {
          final r = Rect.fromCenter(center: Offset.zero, width: .3, height: .26);
          c.drawRect(r, f(NeferhooPalette.papyrus));
          if (fx) {
            if (detail) {
              c.drawRect(r, _shade(_Sh.note));
              c.drawLine(Offset(r.left, 0), Offset(r.right, 0), _stroke(NeferhooPalette.papyrusShade, .016));
              c.drawCircle(const Offset(0, 0), .04, _fill(NeferhooPalette.goldShade));
            }
            c.drawCircle(const Offset(0, 0), detail ? .027 : .04, _fill(NeferhooPalette.goldLit));
            c.drawRect(r, _stroke(NeferhooPalette.ink, NeferhooLayout.detail));
          }
          }
      }
      c.restore();
    }
  }

  // ------------------------------------------------------------------ legs
  //
  // Anatomy (a hoopoe's leg, a mummy's wraps). The THIGH is inside the body,
  // under the belly feathers; what shows is the feathered "trouser" (here a
  // wrapped bulge of the body's own skin with a hem of feather scallops: `_thigh`,
  // part of `_Geo.body` for BOTH legs, so wraps, light and outline run onto it),
  // then the wrapped tibiotarsus, the backward-bending ANKLE (the heel, what
  // people call the knee), the short bare slate TARSUS wearing a gold anklet,
  // and the foot. A hoopoe's foot is short and stout: three short toes forward
  // (the middle one a little longer, all joined at the base) and a short hind
  // toe, blunt dark claws; it is drawn here in King Coo's house idiom (a bold,
  // simple three-toe Y with a short hind toe, ONE filled shape with ONE ink
  // outline, small dark claws; no knuckle bumps, no finger-like spread, no web).
  // Both legs are painted BEHIND the body (the satchel hangs in front of them);
  // each shin starts under its hem and a fringe of cinnamon leg feathers peeks
  // out below the hems, so nothing is pegged on.
  //
  // `legs` (-.6 .. 1.4): -.35 a limp dangle, -.12 a loose dangle (idle, at
  // attention), 0 flight at rest (the Z of a trailing leg: the shin streams back,
  // the tarsus hangs under the heel), .5 the feet kicked back, 1 both legs
  // streamed straight back (the roar's stretch, the hit's recoil). `hit` flinches
  // (shins and feet snap back, toes curl), `fury` plants the talons (shins
  // forward, toes a little wider) and `phase` swings the legs a beat behind the
  // wing. The far leg trails further back than the near one (depth).

  /// A leg's skeleton in the pose: where the shin leaves the hem, the ankle,
  /// the foot, and the four toes as [root, joint, tip].
  _LegPose _legPose(Offset hip, {required bool far}) {
    final u = p.legs.clamp(-.6, 1.4);
    final h = p.hit.clamp(0.0, 1.0), fu = p.fury.clamp(0.0, 1.0);
    final ph = p.phase;
    // a pendulum a beat behind the wing's stroke, plus a lazy sway of its own
    final sway = math.sin(ph * NeferhooPose.wingBeat - 1.0) * .13 * (p.wingRate == 0 ? .3 : 1) + math.sin(ph * 1.9 + (far ? 1.7 : 0)) * .05;
    final a1 = (_curve(u, _kU, _kShin) + sway * (far ? 1.15 : 1) + (far ? .5 : 0) + h * .38 - fu * .15).clamp(-.2, far ? 1.55 : 1.38);
    final a2 = (_curve(u, _kU, _kTarsus) - sway * .7 + (far ? .62 + .25 * u.clamp(0.0, 1.0) : 0) + h * .45 - fu * .10).clamp(-.8, far ? 1.2 : .9);
    final hem = hip + Offset(0, (far ? .15 : .17));
    final ankle = hem + Offset(math.sin(a1), math.cos(a1)) * (_legShin - (far ? .04 : 0));
    final foot = ankle + Offset(math.sin(a2), math.cos(a2)) * _legTarsus;
    // THE FOOT (King Coo's idiom: no filled shape): three toes as curves radiating
    // from ONE point at the end of the tarsus, arched up and dropping at the tip, and
    // a short hind toe. In flight a relaxed bird foot is loosely curled (the tips
    // droop a little); a limp leg lets them hang; a leg kicked back trails them
    // straight; planted talons (fury) spread; a flinch (hit) curls them.
    final trail = u.clamp(0.0, 1.0);
    // the toes leave the tarsus at about 50 degrees from its line when it hangs
    // (forward and a little down), and swing in line with it when it trails
    final tarsusAng = math.pi / 2 - a2;
    final base = (tarsusAng + .88 - .62 * trail + .12 * fu - (far ? .30 : 0)).clamp(1.2, 3.0);
    // (the far fan is wider so its outer toes never touch the near foot's)
    final spread = .53 + .10 * fu + .08 * h - .08 * trail + (far ? .12 : 0);
    final droop = ((.12 + .55 * math.max(0.0, -u) - .10 * trail - .07 * fu + .16 * h) * (far ? .7 : 1)).clamp(0.0, .34);
    final arch = (.24 - .17 * trail) * (1 - .4 * fu);
    final toes = <List<Offset>>[];
    for (var i = 0; i < 4; i++) {
      final front = i < 3;
      final th = front ? base + (1 - i) * spread : (base - 2.45).clamp(.15, .85);
      final l = _toeLen[i];
      final d = Offset(math.cos(th), math.sin(th));
      var n = Offset(-d.dy, d.dx);
      if (front) {
        // ONE droop side for the three forward toes, taken from the fan's centre line:
        // toes either side of vertical used to droop opposite ways and curl shut into
        // an eye-shaped loop (limp, hit)
        n = Offset(-math.sin(base), math.cos(base));
      }
      if (n.dy < 0) n = -n; // toward the ground
      final tip = foot + d * (l * .96) + n * (l * (front ? droop : droop * .6));
      final ctrl = foot + d * (l * .52) - n * (l * (front ? arch : arch * .3));
      toes.add([foot, ctrl, tip]);
    }
    return _LegPose(hem, ankle, foot, toes, math.atan2(foot.dy - ankle.dy, foot.dx - ankle.dx));
  }

  /// What goes OVER the body at the hips (the legs themselves are behind it): the
  /// thighs' roundness at full detail. (The diagonal hip strips that cross the
  /// hems are part of the wraps' layout, `_buildStrips`.)
  void paintLegOver() {
    if (silhouette || play) return;
    c.drawPath(_Geo.thighs, _shade(_Sh.thighShade));
  }

  void paintLeg(Offset hip, {required bool far}) {
    final g = _legPose(hip, far: far);
    // the sleeve stops just short of the ankle, so the heel (the tarsus's round end)
    // knuckles out behind the cuff
    // (the far leg's sleeve runs on up into the belly: its trouser is hidden behind
    // the near thigh, so it needs no shape of its own)
    final up = (g.ankle - g.hem) / (g.ankle - g.hem).distance;
    final shin = _Limb(far ? g.hem - up * .24 : g.hem, g.ankle - up * .05, far ? .12 : .135, far ? .08 : .09, bow: far ? -.012 : -.018, hidden: far ? .24 : 0);
    if (silhouette) {
      c.drawPath(shin.outline(), f(NeferhooPalette.ink));
      c.drawPath(g.stick(), s(NeferhooPalette.ink, _toeW + .05));
      return;
    }
    // the cinnamon leg feathers under BOTH hems, once, behind both legs
    if (far) {
      c.drawPath(_Geo.fringe, play ? _fill(NeferhooPalette.cinn) : _shade(_Sh.fringe));
      if (!play) {
        c.drawPath(_Geo.fringe, _stroke(NeferhooPalette.ink, NeferhooLayout.detail));
        c.drawPath(_Geo.fringeRibs, _stroke(NeferhooPalette.cinnShade, .02, .9));
      }
    }
    if (play) {
      _legPlay(g, far, shin);
    } else {
      _legFull(g, far, shin);
    }
  }

  /// The foot, King Coo's way: NO filled shape. The tarsus and the toes are strokes,
  /// each drawn twice (a thick ink one, a thinner slate one on top); the three
  /// forward toes are curves that radiate from one point and droop at the tip, the
  /// hind toe is short, and the ink runs on past each tip as the dark claw. Ops: 4
  /// (ink tarsus, ink toes + claws, slate tarsus, slate toes); close-ups add a lit
  /// edge on the toes and scutes on the tarsus (texture only).
  void _foot(_LegPose g, bool far, {required bool full}) {
    final skin = far ? NeferhooBodyInk.legFar : NeferhooBodyInk.leg;
    final tarsus = g.tarsus();
    final toes = g.toePath();
    c.drawPath(tarsus, _stroke(NeferhooPalette.ink, _tarsusW + .07));
    c.drawPath(toes, _stroke(NeferhooPalette.ink, _toeW + .048));
    c.drawPath(tarsus, _stroke(skin, _tarsusW));
    c.drawPath(toes, _stroke(skin, _toeW));
    c.drawPath(g.clawPath(), _stroke(NeferhooBodyInk.claw, .05));
    if (full) {
      final lit = far ? NeferhooBodyInk.leg : NeferhooBodyInk.legLit;
      c.drawPath(g.litToes(), _stroke(lit, .018, far ? .6 : .95));
      c.drawPath(g.scutes(), _stroke(NeferhooBodyInk.legShade, .016, .9, StrokeCap.butt));
    }
  }

  /// PLAY level (41 px/unit): the leg in a handful of bold shapes. Ops per leg:
  /// near 8 (foot 3, sleeve 3, anklet, ink), far 8 + the fringe of both hems.
  void _legPlay(_LegPose g, bool far, _Limb shin) {
    _foot(g, far, full: false);
    // the shin: a wrapped sleeve with slanted bandages
    final sleeve = shin.outline();
    c.drawPath(sleeve, _fill(far ? NeferhooPalette.linen : NeferhooPalette.linenLit));
    final lip = Path(), under = Path();
    for (final t in const [.25, .5, .75]) {
      final a = shin.edge(shin.vis(t), 1), b = shin.edge(shin.vis(t + .2), -1);
      under.moveTo(a.dx, a.dy);
      under.lineTo(b.dx, b.dy);
      final a2 = shin.edge(shin.vis(t - .08), 1), b2 = shin.edge(shin.vis(t + .12), -1);
      lip.moveTo(a2.dx, a2.dy);
      lip.lineTo(b2.dx, b2.dy);
    }
    c.drawPath(lip, _stroke(const Color(0xffffffff), .05, 1, StrokeCap.butt));
    c.drawPath(under, _stroke(NeferhooBodyInk.linenLine, .042, far ? .85 : 1, StrokeCap.butt));
    // the gold anklet where the sleeve ends, no wider than the tarsus; its ink goes with the sleeve's
    final ring = g.anklet(_ringAt, _ringW, .075);
    c.drawPath(ring, _fill(NeferhooPalette.goldLit));
    c.drawPath(sleeve..addPath(ring, Offset.zero), _stroke(NeferhooPalette.ink, NeferhooLayout.part));
  }

  /// FULL level (close-ups, the hero): the same leg with its detail: the lit
  /// slate foot with scutes and scale ticks, a banded sleeve, a gold anklet with
  /// a turquoise bead.
  void _legFull(_LegPose g, bool far, _Limb shin) {
    _foot(g, far, full: true);
    // the shin: a banded sleeve
    final sleeve = shin.outline();
    c.drawPath(sleeve, _fill(far ? NeferhooPalette.linen : NeferhooPalette.linenLit));
    c.drawPath(shin.edgeLine(-.72), _stroke(far ? NeferhooPalette.linenDeep : NeferhooPalette.linenShade, .05, far ? .45 : .8));
    if (!far) c.drawPath(shin.edgeLine(.7), _stroke(const Color(0xffffffff), .024, .9));
    final cast = Path(), lip = Path(), under = Path(), thread = Path();
    const slant = .18;
    for (var k = 0; k < 4; k++) {
      final t = .12 + k * .2;
      Offset a(double tt) => shin.edge(shin.vis(tt), 1);
      Offset b(double tt) => shin.edge(shin.vis(tt + slant), -1);
      lip
        ..moveTo(a(t).dx, a(t).dy)
        ..lineTo(b(t).dx, b(t).dy);
      under
        ..moveTo(a(t + .045).dx, a(t + .045).dy)
        ..lineTo(b(t + .045).dx, b(t + .045).dy);
      cast
        ..moveTo(a(t + .075).dx, a(t + .075).dy)
        ..lineTo(b(t + .075).dx, b(t + .075).dy);
      for (final f2 in const [.08, .14]) {
        thread
          ..moveTo(a(t + f2).dx, a(t + f2).dy)
          ..lineTo(b(t + f2).dx, b(t + f2).dy);
      }
    }
    c.drawPath(cast, _stroke(NeferhooPalette.linenDeep, .05, far ? .25 : .3, StrokeCap.butt));
    c.drawPath(thread, _stroke(NeferhooPalette.linenDeep, .01, .3, StrokeCap.butt));
    if (!far) c.drawPath(lip, _stroke(const Color(0xffffffff), .035, 1, StrokeCap.butt));
    c.drawPath(under, _stroke(NeferhooBodyInk.linenLine, .04, far ? .6 : .95, StrokeCap.butt));
    c.drawPath(sleeve, _stroke(NeferhooPalette.ink, NeferhooLayout.part));
    // the gold anklet (the play level's ring, with its gradient) and a turquoise bead
    c.save();
    final ctr = Offset.lerp(g.ankle, g.foot, _ringAt)!;
    c.translate(ctr.dx, ctr.dy);
    c.rotate(g.frameAngle);
    final ring = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: _ringW, height: .075), const Radius.circular(.03));
    c.drawRRect(ring, _shade(_Sh.anklet));
    c.drawRRect(ring, _stroke(NeferhooPalette.ink, .03));
    if (!far) {
      c.drawCircle(const Offset(-.03, .0), .022, _fill(NeferhooPalette.turq));
      c.drawCircle(const Offset(-.03, .0), .022, _stroke(NeferhooPalette.ink, .012));
    }
    c.restore();
  }
}

/// A leg's pose: [hem] where the shin leaves the trouser, the [ankle] (heel),
/// the [foot], [toes] as [root, joint, tip] (three forward, one back).
class _LegPose {
  _LegPose(this.hem, this.ankle, this.foot, this.toes, this.tarsusDir);
  final Offset hem, ankle, foot;
  final List<List<Offset>> toes;
  final double tarsusDir;

  /// The foot's own frame: origin the foot, +y down the tarsus (the ankle is at
  /// (0, -tarsus length)); [frameAngle] is the canvas rotation that gets there.
  double get frameAngle => tarsusDir - math.pi / 2;
  Offset toLocal(Offset w) => NeferhooKit.rot(w - foot, -frameAngle);
  double get tarsusLen => (foot - ankle).distance;

  /// The tarsus: the ankle to the foot, one line.
  Path tarsus() => Path()
    ..moveTo(ankle.dx, ankle.dy)
    ..lineTo(foot.dx, foot.dy);

  /// The toes: [root, control, tip] as quadratic curves from the foot's one point.
  Path toePath() {
    final q = Path();
    for (final t in toes) {
      q
        ..moveTo(t[0].dx, t[0].dy)
        ..quadraticBezierTo(t[1].dx, t[1].dy, t[2].dx, t[2].dy);
    }
    return q;
  }

  /// The short dark claws: a stroke on from each toe's tip, hooked down.
  Path clawPath() {
    final q = Path();
    for (final t in toes) {
      final d = t[2] - t[1];
      final dn = d / d.distance;
      final e = t[2] + dn * .06 + const Offset(0, .035);
      q
        ..moveTo(t[2].dx - dn.dx * .01, t[2].dy - dn.dy * .01)
        ..lineTo(e.dx, e.dy);
    }
    return q;
  }

  /// Lit edges: each forward toe's curve shifted toward the light (upper right).
  Path litToes() {
    final q = Path();
    const lit = Offset(.014, -.02);
    for (var i = 0; i < 3; i++) {
      final t = toes[i];
      q
        ..moveTo(t[0].dx + lit.dx, t[0].dy + lit.dy)
        ..quadraticBezierTo(t[1].dx + lit.dx, t[1].dy + lit.dy, t[2].dx + lit.dx * .6, t[2].dy + lit.dy * .6);
    }
    return q;
  }

  /// Scutes: short crossing ticks along the tarsus.
  Path scutes() {
    final q = Path();
    final d = foot - ankle;
    final len = d.distance, dn = d / len, nr = Offset(-dn.dy, dn.dx);
    for (var i = 1; i * .05 < len - .05; i++) {
      final m = ankle + dn * (i * .05);
      q
        ..moveTo((m - nr * .032).dx, (m - nr * .032).dy)
        ..lineTo((m + nr * .032).dx, (m + nr * .032).dy);
    }
    return q;
  }

  /// The tarsus and the toes as one open path (the silhouette).
  Path stick() => tarsus()..addPath(toePath(), Offset.zero)..addPath(clawPath(), Offset.zero);

  /// A band around the tarsus at [at] (0 ankle .. 1 foot): [w] across, [h] long.
  Path anklet(double at, double w, double h) {
    final c = Offset.lerp(ankle, foot, at)!;
    final d = foot - ankle;
    final dn = d / d.distance;
    final nr = Offset(-dn.dy, dn.dx);
    return Path()
      ..moveTo((c - nr * w * .5 - dn * h * .5).dx, (c - nr * w * .5 - dn * h * .5).dy)
      ..lineTo((c + nr * w * .5 - dn * h * .5).dx, (c + nr * w * .5 - dn * h * .5).dy)
      ..lineTo((c + nr * w * .5 + dn * h * .5).dx, (c + nr * w * .5 + dn * h * .5).dy)
      ..lineTo((c - nr * w * .5 + dn * h * .5).dx, (c - nr * w * .5 + dn * h * .5).dy)
      ..close();
  }
}

/// A tapered limb from [a] to [b] (half width [wa] to [wb]), bowed by [bow],
/// ending in a rounded cuff: the wrapped shin.
class _Limb {
  _Limb(this.a, this.b, this.wa, this.wb, {this.bow = 0, this.hidden = 0}) {
    final d = b - a;
    len = d.distance;
    dir = d / len;
    nrm = Offset(-dir.dy, dir.dx);
  }
  final Offset a, b;
  final double wa, wb, bow;

  /// How much of the limb's top lies hidden behind the body (a length): the wraps
  /// are laid out over what shows.
  final double hidden;
  late final double len;
  late final Offset dir, nrm;

  /// [t] over the part that shows (0 where it leaves the body .. 1 the cuff).
  double vis(double t) {
    final v = hidden / len;
    return v + (1 - v) * t;
  }

  Offset mid(double t) => a + (b - a) * t + nrm * (bow * 4 * t * (1 - t));
  double half(double t) => wa + (wb - wa) * t;

  /// A point on the edge at [t] (0 top .. 1 cuff): [side] +1 the front, -1 the back.
  Offset edge(double t, double side) => mid(t) + nrm * (half(t) * side);

  /// A line down the sleeve at [side] (-1 back edge .. 1 front edge).
  Path edgeLine(double side) => NeferhooKit.smoothPath([for (var i = 0; i <= 6; i++) edge(.05 + .9 * i / 6, side)], close: false);

  Path outline() {
    final pts = <Offset>[
      for (var i = 0; i <= 3; i++) edge(i / 3, 1),
      mid(1) + dir * (wb * .95),
      for (var i = 3; i >= 0; i--) edge(i / 3, -1),
    ];
    return NeferhooKit.smoothPath(pts);
  }
}

const _kU = [-.6, -.2, 0.0, .5, 1.0, 1.4];
const _kShin = [.0, .28, .72, 1.0, 1.22, 1.32];
const _kTarsus = [-.10, -.25, -.55, -.05, .50, .75];
const _legShin = .40, _legTarsus = .28;
// the foot: toe lengths (outer, middle, outer, hind), stroke widths (the ink is the
// slate + .05..07, King Coo's .175 / .085 scaled to the unit), the anklet (no wider
// than the tarsus + 12 %)
const _toeLen = [.27, .31, .27, .14];
const _tarsusW = .085, _toeW = .072;
const _ringW = _tarsusW * 1.12, _ringAt = .2;

double _curve(double x, List<double> xs, List<double> ys) {
  if (x <= xs.first) return ys.first;
  for (var i = 1; i < xs.length; i++) {
    if (x <= xs[i]) return _lerp(ys[i - 1], ys[i], (x - xs[i - 1]) / (xs[i] - xs[i - 1]));
  }
  return ys.last;
}
