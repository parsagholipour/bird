import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';

/// One wing fan, frozen for one frame: the tip of every blade in rig units
/// (before the body's lean), the pauldron, and the look.
///
/// The rig calls only [GargoyleWing.nearOf], [GargoyleWing.farOf] and
/// [GargoyleWingArt.paint]; [GargoyleWingArt.shedBlade] draws the blade in
/// flight after a shrug loosens a feather.
final class GargoyleWing {
  const GargoyleWing({
    required this.far,
    required this.tips,
    required this.tone,
    this.shed = 0,
    this.fury = 0,
    this.tailHeat = 0,
    this.strokes = const [],
    this.spread = 0,
    this.loose = 0,
    this.time = 0,
  });

  factory GargoyleWing.nearOf(GargoylePose pose) => GargoyleWing._of(pose, pose.nearFan, far: false);
  factory GargoyleWing.farOf(GargoylePose pose) => GargoyleWing._of(pose, pose.farFan, far: true);

  factory GargoyleWing._of(GargoylePose pose, GargoyleFanMotion fan, {required bool far}) => GargoyleWing(
    far: far,
    tips: [for (var i = 0; i < GargoyleLayout.fanBlades; i++) fan.tip(i, far: far)],
    tone: pose.tone,
    shed: fan.shed,
    fury: pose.fury,
    strokes: fan.strokes,
    spread: fan.spread,
    loose: far ? 0 : pose.dust,
    time: pose.time,
  );

  /// Far or near fan; the tip of blade 0 (top) .. 6 (lowest).
  final bool far;
  final List<Offset> tips;

  final GargoyleTone tone;

  /// How much of [GargoyleLayout.shedBlade] is gone (1 just left, regrowing
  /// to 0), the fury (blade tips heat amber) and the (unused here) tail heat.
  final double shed, fury, tailHeat;

  /// Each blade's stroke (-1 shrugged up .. 1 mantled) and the fan's opening:
  /// the pauldron rides the first blade's stroke and the flying blade starts
  /// from the flick's own pose.
  final List<double> strokes;
  final double spread;

  /// The telegraph of a feather about to come loose (0 .. 1, the pose's `dust`)
  /// and the clock it rattles on (0 under Reduced Motion: no rattle).
  final double loose, time;

  Offset get root => GargoyleLayout.fanRoot(far: far);
}

/// The two wing fans of the Searchlight Gargoyle: seven blades of brushed
/// stainless steel each, straight-flanked planks with a pointed tip, nested Deco
/// chevrons scored into them, rooted under a stepped limestone pauldron.
///
/// **The blade.** Every blade is authored in its own frame (x along it from the
/// pivot, y across) and painted by ONE cached gradient filled across it in hard
/// bands (lit facet, a specular streak, the ridge's groove, the shaded facet),
/// so a blade is its fill, its moon rim, its ink and its scoring: four ops, no
/// per-frame shader and no per-frame path (reusable scratch paths only). Tips
/// are always [GargoyleLayout.fanTip] (the envelope holds for any stroke, spread
/// and lag); blades are narrower than the layout's outlines, so everything is
/// inside them. The lit facet is the side the viewer sees; the moon's cool rim
/// runs inside the edge that faces it and hard white glints sit on the tips.
///
/// **The two fans are not clones.** The near fan has the ink outline, chevron
/// scoring, glints and a stepped pauldron with brass pivot pins and a steam
/// nozzle; the far fan is a plain chisel-tipped steel in the near fan's shadow,
/// dimmed as one wash, outlined in steel blue (a dark outline would vanish on
/// the night sky) and capped with a smaller darker shoulder behind the pauldron.
///
/// **Materials.** Steel is cool and a clear value under the limestone body
/// (median L* about 57 against 75; the far fan 38). The top blade of the near
/// fan is the stone feather: a steel frame and quill around limestone vanes, the
/// one blade a player will see leave. Brass is the pins and the nozzle; verdigris
/// weeps only from the pins. The hit flash bleaches every fill through the kit's
/// tone (a colour filter on the gradients, `tone.lit` on the flats) and never the
/// ink; fury heats the tips through a cached fade; the dormant stone greys it all.
///
/// **Motion** comes from the pose (per-blade strokes with their lag, the far fan
/// a tenth of a second behind) plus three small things drawn here: the pauldron
/// rides the first blade's stroke (up when shrugged, down when mantled), the
/// loosening feather rattles in its socket while the telegraph runs
/// ([GargoyleWing.loose], a motion channel: still under Reduced Motion), and the
/// feather leaves (see [shedBlade]).
abstract final class GargoyleWingArt {
  // ------------------------------------------------------------ paints --

  /// A blade is painted in its own frame: x along it from the pivot to the tip,
  /// y across it with the LIT side negative. The gradient runs across (y from
  /// -[_half] to +[_half]) in hard bands: the lit facet, one specular streak,
  /// the ridge's groove, the shaded facet.
  static const _half = .30;

  /// The lit facet: stainless steel a step under the streak, so the fan stays
  /// a clear value below the limestone body.
  static const _steelFace = Color(0xff6d8bb0);

  static Paint _across(Object key, List<(double, Color)> stops) => GargoyleKit.cached(
    key,
    () => GargoyleKit.linear(
      const Offset(0, -_half),
      const Offset(0, _half),
      [for (final s in stops) s.$2],
      [for (final s in stops) s.$1],
    ),
  );

  static Paint _steelNear() => _across('wing.steel.near', const [
    (0.00, _steelFace),
    (0.14, _steelFace),
    (0.14, GargoylePalette.steelLit),
    (0.21, GargoylePalette.steelLit),
    (0.21, _steelFace),
    (0.46, _steelFace),
    (0.46, GargoylePalette.steelCore),
    (0.53, GargoylePalette.steelCore),
    (0.53, GargoylePalette.steelMid),
    (1.00, GargoylePalette.steelDeep),
  ]);

  /// Heat at a blade's tip, in the tip's own frame (x runs back from the
  /// apex): white-hot, then the arc's warm body, then orange fading into the
  /// steel. The paint's alpha is the fury.
  static Paint _heatFade() => GargoyleKit.cached(
    'wing.heat',
    () => GargoyleKit.linear(
      Offset.zero,
      const Offset(-_heatLen, 0),
      const [GargoylePalette.arcCore, GargoylePalette.arcBody, GargoylePalette.arcEdge, Color(0x00ff9a4a)],
      const [0, .22, .55, 1],
    ),
  );
  static const _heatLen = .9;

  /// The stone feather: a steel frame and quill around limestone vanes.
  static Paint _feather() => _across('wing.feather', const [
    (0.00, GargoylePalette.steel),
    (0.11, GargoylePalette.steel),
    (0.11, GargoylePalette.limeLit),
    (0.19, GargoylePalette.limeLit),
    (0.19, GargoylePalette.limeSheen),
    (0.25, GargoylePalette.limeSheen),
    (0.25, GargoylePalette.limeLit),
    (0.44, GargoylePalette.limeLit),
    (0.44, GargoylePalette.steelLit),
    (0.50, GargoylePalette.steelLit),
    (0.50, GargoylePalette.steelMid),
    (0.56, GargoylePalette.steelMid),
    (0.56, GargoylePalette.limeShade),
    (0.90, GargoylePalette.limeShade),
    (0.90, GargoylePalette.steelDeep),
    (1.00, GargoylePalette.steelDeep),
  ]);

  // ------------------------------------------------------------ shapes --

  static final Path _outline = Path(),
      _rim = Path(),
      _glint = Path(),
      _chevron = Path(),
      _dim = Path(),
      _drips = Path(),
      _scratch = Path();

  static double _half0(bool far, bool short) => far ? (short ? .35 : .38) : (short ? .28 : .30);
  static double _tipAt(double len, bool far) => len - (far ? 1.05 : .62);

  /// The blade outline in its own frame, for a blade [len] long from its pivot:
  /// a plank with a pointed tip (near: a kite point; far: a slanted chisel cut).
  static void _shape(Path p, double len, {required bool far, required bool short}) {
    p.reset();
    final wm = _half0(far, short);
    const x0 = .5;
    final tipAt = _tipAt(len, far);
    if (far) {
      p
        ..moveTo(x0, -.22)
        ..lineTo(1.1, -wm)
        ..lineTo(tipAt - .25, -wm)
        ..lineTo(len, 0)
        ..lineTo(tipAt + .35, wm)
        ..lineTo(1.1, wm)
        ..lineTo(x0, .22)
        ..close();
      return;
    }
    p
      ..moveTo(x0, -.22)
      ..lineTo(1.1, -wm)
      ..lineTo(tipAt, -wm)
      ..lineTo(len, 0)
      ..lineTo(tipAt, wm)
      ..lineTo(1.1, wm)
      ..lineTo(x0, .22)
      ..close();
  }

  /// Nested Deco chevrons pointing at the tip, scored into a near blade that is
  /// [len] long (as many as fit between the tip and the pauldron).
  static void _chevrons(Path p, double len) {
    p.reset();
    for (var k = 0; k < 4; k++) {
      final d = .26 + k * .40;
      if (len - d - .26 < .8) break;
      final hw = math.min(.25, .15 + k * .035);
      p
        ..moveTo(len - d - .26, -hw)
        ..lineTo(len - d, 0)
        ..lineTo(len - d - .26, hw);
    }
  }

  /// The hot tip of a long and of a short near blade, in the tip's frame,
  /// just inside the ink.
  static final Path _heatLong = _heatTip(.30), _heatShort = _heatTip(.28);
  static Path _heatTip(double wm) {
    final h = wm - .04;
    return GargoyleKit.poly([
      const Offset(-.05, 0),
      Offset(-.60, -h),
      Offset(-_heatLen, -h),
      Offset(-_heatLen, h),
      Offset(-.60, h),
    ]);
  }

  // The per-blade geometry the batched passes (rim, glints, heat) use after the
  // blades are painted: the pivot is the fan's root, [_ux], [_uy] the unit
  // direction and [_reach] the distance of the drawn tip.
  static final List<double> _ux = List.filled(GargoyleLayout.fanBlades, 0),
      _uy = List.filled(GargoyleLayout.fanBlades, 0),
      _reach = List.filled(GargoyleLayout.fanBlades, 0),
      _len = List.filled(GargoyleLayout.fanBlades, 0),
      _slide = List.filled(GargoyleLayout.fanBlades, 0);
  static final List<bool> _live = List.filled(GargoyleLayout.fanBlades, false);

  static const _opaque = Color(0xff000000);

  // ------------------------------------------------------------- paint --

  static bool _ok(Offset o) => o.dx.isFinite && o.dy.isFinite;
  static double _f(double v, [double lo = 0, double hi = 1]) => v.isFinite ? v.clamp(lo, hi) : lo;

  /// Paints the fan: blades back to front (the top blade last, so the lower
  /// ones tuck under it), each with its own rim light, hot tip and scoring,
  /// then the batched glints (near) or the dimming and rim (far), then the
  /// shoulder over the roots.
  static void paint(Canvas c, GargoyleWing w) {
    final t = w.tone;
    final far = w.far;
    final root = w.root;
    if (!_ok(root)) return;
    final steel = GargoyleKit.toned(_steelNear(), t)..color = _opaque;
    final feather = far ? null : (GargoyleKit.toned(_feather(), t)..color = _opaque);
    // The far fan's linework is a steel blue, lighter than the near fan's ink:
    // a dark outline would vanish on the night sky and the far fan is meant to
    // sit back, not to disappear.
    final ink = GargoyleKit.line(far ? _farInk : GargoylePalette.ink, far ? .055 : .065);
    final score = far ? null : GargoyleKit.line(GargoylePalette.steelCore, .05, .9);
    final rim = far ? null : GargoyleKit.line(t.lit(t.sky), .06, t.moonRim.clamp(0.0, 1.0));
    final fury = _f(w.fury);
    final heat = !far && fury > .05 ? (GargoyleKit.toned(_heatFade(), t)..color = Color.fromRGBO(0, 0, 0, fury)) : null;
    final shed = _f(w.shed);
    var any = false;
    // The blades' geometry first: the fan shadow needs all of it.
    for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
      _live[i] = false;
      if (i >= w.tips.length) continue;
      final isShed = !far && i == GargoyleLayout.shedBlade;
      if (isShed && shed >= .999) continue;
      final tip = w.tips[i];
      if (!_ok(tip)) continue;
      final d = tip - root;
      final len = d.distance;
      if (len < 1.2) continue;
      any = true;
      final u = d / len;
      _ux[i] = u.dx;
      _uy[i] = u.dy;
      _len[i] = len;
      _slide[i] = isShed ? shed * (len - .35) : 0.0;
      _reach[i] = len - _slide[i];
      _live[i] = true;
    }
    if (any && !far) _fanShadow(c, w);
    for (var i = GargoyleLayout.fanBlades - 1; i >= 0; i--) {
      if (!_live[i]) continue;
      final isShed = !far && i == GargoyleLayout.shedBlade;
      final len = _len[i];
      // The lit facet is the one the viewer sees (the lower, right-hand side:
      // the upper one is tucked under the blade above), so the blade is painted
      // mirrored: its lit side is y < 0 in its own frame, below it on screen.
      var turn = math.atan2(_uy[i], _ux[i]);
      // A feather about to come loose rattles in its socket.
      if (isShed) turn += math.sin(w.time * 57) * .028 * _f(w.loose);
      c.save();
      c.translate(root.dx, root.dy);
      c.rotate(turn);
      c.scale(1, -1);
      c.translate(-_slide[i], 0);
      _shape(_outline, len, far: far, short: i.isOdd);
      c.drawPath(_outline, isShed ? feather! : steel);
      if (heat != null) {
        c.save();
        c.translate(len, 0);
        c.drawPath(i.isOdd ? _heatShort : _heatLong, heat);
        c.restore();
      }
      if (rim != null) {
        // The moon's rim runs just inside the edge that faces it: the right of
        // the two upper blades, the top of the others.
        final wm = _half0(false, i.isOdd), side = i < 2 ? -1.0 : 1.0;
        _rim
          ..reset()
          ..moveTo(len - 1.7, side * (wm - .075))
          ..lineTo(_tipAt(len, false), side * (wm - .075))
          ..lineTo(len - .14, side * .02);
        c.drawPath(_rim, rim);
      }
      c.drawPath(_outline, ink);
      if (score != null) {
        _chevrons(_chevron, len);
        c.drawPath(_chevron, score);
      }
      c.restore();
    }
    if (any) _batched(c, w);
    _hub(c, w);
    if (!far) _launchFlash(c, w);
  }

  /// The near fan's shadow on the far fan and the body: every live blade's
  /// outline, shifted down and right, in one dark wash.
  static void _fanShadow(Canvas c, GargoyleWing w) {
    final root = w.root;
    const dx = .05, dy = .07;
    _dim.reset();
    for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
      if (!_live[i]) continue;
      final len = _reach[i], wm = _half0(false, i.isOdd), tipAt = _tipAt(len, false);
      Offset at(double a, double v) => Offset(
        root.dx + dx + _ux[i] * a + _uy[i] * v,
        root.dy + dy + _uy[i] * a - _ux[i] * v,
      );
      final pts = [at(.5, -.22), at(1.1, -wm), at(tipAt, -wm), at(len, 0), at(tipAt, wm), at(1.1, wm), at(.5, .22)];
      _dim.moveTo(pts[0].dx, pts[0].dy);
      for (var k = 1; k < pts.length; k++) {
        _dim.lineTo(pts[k].dx, pts[k].dy);
      }
      _dim.close();
    }
    c.drawPath(_dim, GargoyleKit.fill(GargoylePalette.ink, .32));
  }

  /// The instant the top blade lets go: a four-point flash at its pivot pin;
  /// and while it slides back out of the pauldron a bright line of polished
  /// steel at the pauldron's edge.
  static void _launchFlash(Canvas c, GargoyleWing w) {
    final shed = _f(w.shed);
    if (shed <= .001 || w.tips.isEmpty) return;
    final d = w.tips[GargoyleLayout.shedBlade] - w.root;
    final len = d.distance;
    if (!_ok(d) || len < 1e-3) return;
    final u = d / len, n = Offset(-u.dy, u.dx);
    final pin = w.root + u * 1.04;
    final star = ((shed - .8) / .2).clamp(0.0, 1.0);
    if (star > 0) {
      Offset p(double a, double b) => pin + u * a + n * b;
      final path = GargoyleKit.poly([
        p(-.34 * star, 0), p(-.06, -.06), p(0, -.34 * star), p(.06, -.06), p(.34 * star, 0), p(.06, .06), p(0, .34 * star), p(-.06, .06),
      ], into: _scratch..reset());
      c.drawPath(path, GargoyleKit.fill(GargoylePalette.white, .95 * star));
    }
    if (shed < .97) {
      final a = pin + u * .16;
      c.drawLine(a - n * .27, a + n * .27, GargoyleKit.line(GargoylePalette.white, .06, .85 * math.sqrt(shed)));
    }
  }

  static const _farInk = Color(0xff263356);

  /// Hard white glints on the near blades' exposed tips (one op for the fan),
  /// or, for the far fan, the dimming of the whole fan (one wash over its
  /// blades' union, so overlaps never double) and the moon's rim on its tips.
  static void _batched(Canvas c, GargoyleWing w) {
    final t = w.tone;
    final root = w.root;
    // A point of blade [i]'s own frame on screen: the blade is painted mirrored,
    // so its y is the screen-side normal negated.
    Offset at(int i, double a, double v) => Offset(
      root.dx + _ux[i] * a + _uy[i] * v,
      root.dy + _uy[i] * a - _ux[i] * v,
    );
    if (!w.far) {
      _glint.reset();
      for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
        if (!_live[i]) continue;
        final len = _reach[i];
        final g0 = at(i, len - .96, -.2), g1 = at(i, len - .84, -.2);
        _glint
          ..moveTo(g0.dx, g0.dy)
          ..lineTo(g1.dx, g1.dy);
      }
      c.drawPath(_glint, GargoyleKit.line(GargoylePalette.white, .05, .95));
      return;
    }
    _rim.reset();
    _dim.reset();
    for (var i = 0; i < GargoyleLayout.fanBlades; i++) {
      if (!_live[i]) continue;
      final len = _reach[i];
      final wm = _half0(true, i.isOdd);
      final tipAt = _tipAt(len, true);
      // The whole far fan sits in the dusk of the near one's shadow.
      final shape = [at(i, .5, -.22), at(i, 1.1, -wm), at(i, tipAt - .25, -wm), at(i, len, 0), at(i, tipAt + .35, wm), at(i, 1.1, wm), at(i, .5, .22)];
      _dim.moveTo(shape[0].dx, shape[0].dy);
      for (var k = 1; k < shape.length; k++) {
        _dim.lineTo(shape[k].dx, shape[k].dy);
      }
      _dim.close();
      final side = i < 2 ? -1.0 : 1.0;
      final from = at(i, tipAt - .5, side * (wm - .07)), mid = at(i, tipAt - .25, side * (wm - .07)), end = at(i, len - .14, side * .02);
      _rim
        ..moveTo(from.dx, from.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);
    }
    c.drawPath(_dim, GargoyleKit.fill(GargoylePalette.steelCore, .5));
    c.drawPath(_rim, GargoyleKit.line(t.lit(t.sky), .06, (t.moonRim * .7).clamp(0.0, 1.0)));
  }

  // ---------------------------------------------------- hub and pauldron --

  /// The shoulder: the near fan's stepped limestone pauldron with a brass pivot
  /// pin at every blade's exit and brass steam nozzle; it rises with the wing's
  /// stroke (the statue shrugs). The far fan's smaller, darker cap sits behind
  /// it. Static paths in offsets from the fan's root.
  static void _hub(Canvas c, GargoyleWing w) {
    final t = w.tone;
    final root = w.root;
    final s0 = w.strokes.isEmpty ? 0.0 : _f(w.strokes.first, -1, 1);
    // The shoulder rides the stroke: up when the wing is shrugged, pressed down
    // when it is mantled.
    final lift = s0 < 0 ? s0 * .10 : s0 * .05;
    c.save();
    c.translate(root.dx, root.dy);
    if (w.far) {
      c.translate(0, lift);
      c.drawPath(_capBase, GargoyleKit.fill(t.lit(GargoylePalette.limeDeep)));
      c.drawPath(_capTreads, GargoyleKit.fill(t.lit(GargoylePalette.limeShade), .8));
      c.drawPath(_capRim, GargoyleKit.line(t.lit(t.sky), .045, t.moonRim * .5));
      c.drawPath(_capNozzle, GargoyleKit.fill(t.lit(GargoylePalette.brassDeep)));
      c.drawPath(_capBase, GargoyleKit.line(GargoylePalette.ink, .06));
      c.drawPath(_capNozzle, GargoyleKit.line(GargoylePalette.ink, .035));
      c.restore();
      return;
    }
    c.translate(0, lift);
    c.drawPath(_padBase, GargoyleKit.fill(t.lit(_padStone)));
    c.drawPath(_padShade, GargoyleKit.fill(t.lit(GargoylePalette.limeShade), .75));
    c.drawPath(_padLit, GargoyleKit.fill(t.lit(GargoylePalette.limeLit)));
    c.drawPath(_padRim, GargoyleKit.line(t.lit(t.sky), .05, t.moonRim));
    c.drawPath(_padGlint, GargoyleKit.line(GargoylePalette.white, .045, .9));
    c.drawPath(_padWarm, GargoyleKit.line(t.lit(GargoylePalette.lampAmber), .06, t.lampFill * .5));
    c.drawPath(_padHatch, GargoyleKit.line(GargoylePalette.limeDeep, .035, .6));
    c.drawPath(_nozzle, GargoyleKit.fill(t.lit(GargoylePalette.brass)));
    c.drawPath(_nozzle, GargoyleKit.line(GargoylePalette.ink, .035));
    c.drawPath(_padBase, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkMajor));
    c.translate(0, -lift);
    // A brass pivot pin where every blade leaves the pauldron, verdigris
    // weeping from the lowest three.
    _scratch.reset();
    _drips.reset();
    for (var i = 0; i < w.tips.length; i++) {
      final d = w.tips[i] - root;
      final len = d.distance;
      if (!_ok(d) || len < 1e-3) continue;
      final p = d / len * 1.04;
      _scratch.addOval(Rect.fromCircle(center: p, radius: .055));
      if (i >= w.tips.length - 3) {
        _drips
          ..moveTo(p.dx - .03, p.dy + .05)
          ..lineTo(p.dx + .03, p.dy + .05)
          ..lineTo(p.dx + .012, p.dy + .22 + (i - 4) * .05)
          ..lineTo(p.dx - .012, p.dy + .22 + (i - 4) * .05)
          ..close();
      }
    }
    c.drawPath(_drips, GargoyleKit.fill(GargoylePalette.vd));
    c.drawPath(_scratch, GargoyleKit.line(GargoylePalette.ink, .055));
    c.drawPath(_scratch, GargoyleKit.fill(t.lit(GargoylePalette.brassDeep)));
    c.restore();
  }

  static const _padStone = Color(0xffb7a785);

  static Path _pts(List<Offset> p, {bool closed = false}) => GargoyleKit.poly(p, closed: closed);

  static final Path _padBase = _pts(const [
    Offset(-.58, .36),
    Offset(-.58, -.30),
    Offset(-.40, -.30),
    Offset(-.40, -.62),
    Offset(-.12, -.62),
    Offset(-.12, -.84),
    Offset(.60, -.84),
    Offset(.60, -.62),
    Offset(.78, -.62),
    Offset(.78, -.38),
    Offset(.92, -.38),
    Offset(.92, -.12),
    Offset(1.04, -.12),
    Offset(1.04, .12),
    Offset(.92, .40),
    Offset(.52, .72),
    Offset(-.05, .78),
  ], closed: true);

  /// The shaded underside of the pauldron and the shadow each lit step casts on
  /// the step below (one flat wash).
  static final Path _padShade = _pts(const [
    Offset(-.05, .78),
    Offset(.52, .72),
    Offset(.92, .40),
    Offset(1.04, .12),
    Offset(.90, .10),
    Offset(.80, .30),
    Offset(.46, .52),
    Offset(-.05, .56),
    Offset(-.50, .26),
    Offset(-.58, .36),
  ], closed: true)
    ..addRect(const Rect.fromLTRB(-.58, -.17, -.40, -.09))
    ..addRect(const Rect.fromLTRB(-.40, -.49, -.12, -.41))
    ..addRect(const Rect.fromLTRB(-.12, -.69, .60, -.61))
    ..addRect(const Rect.fromLTRB(.60, -.49, .78, -.41))
    ..addRect(const Rect.fromLTRB(.78, -.25, .92, -.17));

  /// The lit top of every step.
  static final Path _padLit = Path()
    ..addRect(const Rect.fromLTRB(-.58, -.30, -.40, -.17))
    ..addRect(const Rect.fromLTRB(-.40, -.62, -.12, -.49))
    ..addRect(const Rect.fromLTRB(-.12, -.84, .60, -.69))
    ..addRect(const Rect.fromLTRB(.60, -.62, .78, -.49))
    ..addRect(const Rect.fromLTRB(.78, -.38, .92, -.25))
    ..addRect(const Rect.fromLTRB(.92, -.12, 1.04, .01));
  static final Path _padRim = _pts(const [
    Offset(-.52, -.25),
    Offset(-.45, -.25),
    Offset(-.45, -.57),
    Offset(-.17, -.57),
    Offset(-.17, -.79),
    Offset(.55, -.79),
    Offset(.55, -.57),
    Offset(.73, -.57),
    Offset(.73, -.33),
    Offset(.87, -.33),
    Offset(.87, -.07),
    Offset(.99, -.07),
    Offset(.99, .10),
  ]);
  static final Path _padGlint = Path()
    ..moveTo(.30, -.80)
    ..lineTo(.50, -.80)
    ..moveTo(.64, -.58)
    ..lineTo(.72, -.58);
  static final Path _padWarm = _pts(const [
    Offset(-.53, .30),
    Offset(-.53, -.18),
    Offset(-.35, -.18),
    Offset(-.35, -.50),
    Offset(-.17, -.50),
  ]);
  /// Chevron scoring cut into the pauldron's face, like the chest's.
  static final Path _padHatch = Path()
    ..moveTo(-.36, -.02)
    ..relativeLineTo(.19, .14)
    ..relativeLineTo(.19, -.14)
    ..moveTo(-.06, -.02)
    ..relativeLineTo(.19, .14)
    ..relativeLineTo(.19, -.14)
    ..moveTo(-.36, .26)
    ..relativeLineTo(.19, .14)
    ..relativeLineTo(.19, -.14)
    ..moveTo(-.06, .26)
    ..relativeLineTo(.19, .14)
    ..relativeLineTo(.19, -.14);
  static final Path _nozzle = Path()
    ..addRect(const Rect.fromLTRB(-.36, -.74, -.16, -.62))
    ..moveTo(-.30, -.72)
    ..lineTo(-.30, -.64)
    ..moveTo(-.22, -.72)
    ..lineTo(-.22, -.64);

  // The far fan's shoulder cap.
  static final Path _capBase = _pts(const [
    Offset(-.50, .35),
    Offset(-.50, -.25),
    Offset(-.32, -.25),
    Offset(-.32, -.52),
    Offset(-.05, -.52),
    Offset(-.05, -.72),
    Offset(.40, -.72),
    Offset(.40, -.45),
    Offset(.62, -.45),
    Offset(.62, -.15),
    Offset(.74, -.15),
    Offset(.74, .35),
  ], closed: true);
  static final Path _capTreads = Path()
    ..addRect(const Rect.fromLTRB(-.05, -.72, .40, -.65))
    ..addRect(const Rect.fromLTRB(-.32, -.52, -.05, -.45))
    ..addRect(const Rect.fromLTRB(.40, -.45, .62, -.38));
  static final Path _capRim = _pts(const [
    Offset(-.27, -.47),
    Offset(-.00, -.47),
    Offset(-.00, -.67),
    Offset(.35, -.67),
    Offset(.35, -.40),
    Offset(.57, -.40),
    Offset(.57, -.10),
  ]);
  static final Path _capNozzle = Path()..addRect(const Rect.fromLTRB(-.04, -.82, .18, -.72));

  // ------------------------------------------------------ the loose blade --

  /// The blade loosened by a shrug, in flight [tau] seconds after it left: it
  /// starts exactly where the fan's top blade stood at the flick and is
  /// flung up and out of the top of the screen.
  static void shedBlade(Canvas c, GargoyleWing w, double tau) {
    if (!tau.isFinite || tau < 0 || tau > .6) return;
    final root = GargoyleLayout.fanRoot(far: false);
    final tip = GargoyleLayout.fanTip(
      GargoyleLayout.shedBlade,
      far: false,
      stroke: -1,
      spread: w.fury > .4 ? .55 : .5,
    );
    final d = tip - root;
    final len = d.distance;
    if (len < 1.2) return;
    final u = d / len;
    final c0 = root + u * ((.5 + len) / 2);
    final s = tau * (.65 + 1.3 * tau);
    final at = c0 + GargoyleLayout.shedVelocity * s;
    c.save();
    // The blade's root end is still inside the pauldron when it lets go: only
    // what is above the pauldron's top shows.
    c.clipRect(Rect.fromLTRB(-99, -99, 99, root.dy - .96), doAntiAlias: false);
    c.translate(at.dx, at.dy);
    c.rotate(math.atan2(d.dy, d.dx) - 1.6 * tau);
    c.scale(1, -1);
    c.translate(-(.5 + len) / 2, 0);
    _shape(_outline, len, far: false, short: false);
    // The steel blazes for a moment as it lets go, then settles.
    final flash = math.max(w.tone.flash, .55 * (1 - tau / .12).clamp(0.0, 1.0));
    final look = GargoyleTone(
      flash: flash,
      fury: w.tone.fury,
      heat: w.tone.heat,
      dark: w.tone.dark,
      sky: w.tone.sky,
      stone: w.tone.stone,
    );
    c.drawPath(_outline, GargoyleKit.toned(_feather(), look)..color = _opaque);
    _chevrons(_chevron, len);
    _chevron.addPath(_outline, Offset.zero);
    c.drawPath(_chevron, GargoyleKit.line(GargoylePalette.ink, .065));
    c.restore();
  }

  /// The furthest a painted blade can reach, for tests: blade corners plus the
  /// ink's half width.
  static double reach(GargoyleWing w) {
    var r = 0.0;
    for (final tip in w.tips) {
      r = math.max(r, (tip - w.root).distance);
    }
    return r;
  }
}
