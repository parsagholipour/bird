// Neferhoo's head, refined (r1-head), polished (f1-crest) and given life and
// finish (iteration 5, i2-head): the burnished golden courier mask with its brow
// band, the striped nemes, the gold-sheathed hoopoe bill, the glassy eye, the
// hoopoe crest rooted along the crown, and the dusty old face under the mask.
//
// Iteration 5 (review 08): M3 the plate is a reflection map in amber (hot lobe,
// dark warm band, hot cheek band) and the bill's sheath carries the same dark
// band under its highlight; M2 the eyelid is the bright lid-gold (so a blink
// reads as a lid), the smile goes flat with `angry`; m3 the crest fan is graded
// and leans back with cinnamon chroma; m1 the bare head's scarf is thin, with a
// knot.
//
// Everything here is an `extension on NeferhooPainter`, so it uses only the
// painter's public `c`, `p`, `f`, `s`, `sh`, `part`, `fx`, `silhouette`, `sil`.
// The rig's _head/_nemes/_mask/_beak/_eye/_crest/_bareHead call into it.
//
// Rules this file keeps (see HANDOFF.md):
//  * static geometry and gradients are built ONCE (`_geo`, lazily), in rig
//    units and in the head's local frame, so a frame only issues draws;
//  * no saveLayer, no blur, at most two clipPaths in a frame (nemes, glint);
//  * the crest draws each of its 7 feathers in its own local frame through ONE
//    matrix call (fill + ink = 2 draws each), with the cinnamon, the narrow
//    cream band and the black tip baked into one gradient;
//  * parity (M4): no object appears or goes at a detail level, only texture
//    (specular lines, veins, hammering, hairlines) comes and goes;
//  * animation is a pure function of the pose (`phase` drives the crest
//    flutter and the travelling glint; no clocks, no randomness);
//  * detail levels read the canvas scale (px per unit): full detail at game
//    size and up, a quieter head on the HUD medallion and the 24 px keepsake.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_rig.dart';


/// The head's own colours (the shared palette `Mu` is not touched).
abstract final class NeferhooHeadInk {
  static const kohl = Color(0xff1a1a52); // lapis-black: the painted eye line
  static const kohlLit = Color(0xff2f46b8);
  static const goldCool = NeferhooPalette.goldCool; // gold's cool, violet-brown shade
  static const goldBounce = NeferhooPalette.goldBounce; // sand light bounced up under the mask
  static const goldPeak = Color(0xfffff7cf); // the mask's specular lobes (m6): lighter than goldHi, same hue
  // iter 5 (M3): the mask's own burnished-gold ramp. A real gold mask is not a
  // light yellow, it is a saturated amber with a hot, narrow highlight and a
  // dark, warm reflection band beside it (never grey, never black). These sit
  // between NeferhooPalette.gold and NeferhooPalette.goldShade in hue (40-42 deg) and are used only on the
  // face plate and the bill's sheath, so the shared palette is untouched.
  static const burnLit = Color(0xffffd24a); // the lit amber (L .82, S .71; NeferhooPalette.goldLit is S .57)
  static const burnMid = Color(0xfff2a826); // the body of the metal
  static const burnDark = Color(0xffb8741a); // the reflection band: burnt amber
  static const burnAmber = Color(0xffd4871a); // the cheek's fall into shade (between the body and the dark turn)
  static const burnHot = Color(0xffffe39a); // the highlight's body (the cream goldPeak is only its core)
  static const rimWarm = NeferhooPalette.rim; // the sun behind-right
  static const quartz = NeferhooPalette.linenHi;
  static const quartzShade = NeferhooPalette.linen;
  static const amber = Color(0xff9a6228);
  static const obsidian = NeferhooPalette.ink;
  static const horn = NeferhooPalette.barBlack;
  static const hornLit = Color(0xff6a5f80);
  static const plum = Color(0xffb8445e);
  static const tongue = Color(0xffffa6ae);
  static const dust = Color(0xffd9c9a8);
  static const creamCheek = Color(0xfffdd9a8);
  static const whiskerGrey = NeferhooPalette.linen;
}

// -----------------------------------------------------------------------------
// small helpers

Paint _fp(Color c, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
Paint _sp(Color c, double w, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0))
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
Paint _shp(ui.Shader s) => Paint()
  ..isAntiAlias = true
  ..shader = s;
Paint _shs(ui.Shader s, double w) => Paint()
  ..isAntiAlias = true
  ..shader = s
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
List<double>? _even(List<Color> cs, List<double>? st) => st ?? (cs.length <= 2 ? null : [for (var i = 0; i < cs.length; i++) i / (cs.length - 1)]);
ui.Shader _gl(Offset a, Offset b, List<Color> cs, [List<double>? st]) => ui.Gradient.linear(a, b, cs, _even(cs, st));
ui.Shader _gr(Offset c, double r, List<Color> cs, [List<double>? st]) => ui.Gradient.radial(c, r, cs, _even(cs, st));

Offset _cub(Offset a, Offset b, Offset c, Offset d, double t) {
  final u = 1 - t;
  return a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t);
}

Offset _cubD(Offset a, Offset b, Offset c, Offset d, double t) {
  final u = 1 - t;
  return (b - a) * (3 * u * u) + (c - b) * (6 * u * t) + (d - c) * (3 * t * t);
}

Offset _unit(Offset v) {
  final d = v.distance;
  return d == 0 ? Offset.zero : v / d;
}

Path _poly(List<Offset> pts, {bool close = true}) => Path()..addPolygon(pts, close);

// (the level of detail, 0 quiet .. 3 full, is `NeferhooPainter.lod`: the rig reads
// the canvas scale once per painter; 2 is the PLAY level of the game and story)

// -----------------------------------------------------------------------------
// the bill: one curve (the old silhouette's top edge), a gape line and an
// underside, sampled once

final class _Bill {
  _Bill([double k = 1]) {
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final pt = _cub(_p0, _p1, _p2, _p3, t);
      final d = _unit(_cubD(_p0, _p1, _p2, _p3, t));
      final nr = Offset(d.dy, -d.dx); // toward the underside
      final w = thick(t) * k;
      top.add(pt);
      nrm.add(nr);
      gape.add(pt + nr * (w * .54));
      low.add(pt + nr * w);
    }
  }
  static const n = 24;
  static const _p0 = Offset(-1.40, -1.50), _p1 = Offset(-2.22, -1.64), _p2 = Offset(-2.52, -1.10), _p3 = Offset(-3.10, -.58);
  static double thick(double t) => .40 * math.pow(1 - t, .75).toDouble() + .004;
  final top = <Offset>[], gape = <Offset>[], low = <Offset>[], nrm = <Offset>[];

  /// The lower mandible stops a little short of the tip.
  static const lowEnd = 22;
  static const hinge = Offset(-1.52, -1.20);

  List<Offset> upperPoly([int to = n]) => [...top.sublist(0, to + 1), ...gape.sublist(0, to + 1).reversed];
  List<Offset> lowerPoly(double ang, [int to = lowEnd]) {
    final pts = [...gape.sublist(0, to + 1), ...low.sublist(0, to + 1).reversed];
    return ang == 0 ? pts : [for (final q in pts) NeferhooKit.rot(q, -ang, hinge)];
  }

  /// The mouth between the gape line and the lowered jaw.
  /// It stops two thirds of the way out: beyond that the mandibles are two
  /// thin tips with the sky between them, not a long dark flag.
  List<Offset> mouthPoly(double ang) => [...gape.sublist(0, 16), ...[for (final q in gape.sublist(0, 16)) NeferhooKit.rot(q, -ang, hinge)].reversed];
}

/// Every path one jaw needs (outline, sheath, shade, rings, inlay...), built
/// from the bill's samples; the closed bill's sets are cached.
final class _Jaw {
  _Jaw(_Bill b, double ang, this.lower) {
    Offset r(Offset q) => lower && ang != 0 ? NeferhooKit.rot(q, -ang, _Bill.hinge) : q;
    final top = lower ? b.gape : b.top, bot = lower ? b.low : b.gape;
    final to = lower ? _Bill.lowEnd : _Bill.n;
    end = lower ? 18 : 20; // the sheath stops short of the horn tip
    poly = _poly([for (var i = 0; i <= to; i++) r(top[i]), for (var i = to; i >= 0; i--) r(bot[i])]);
    sheath = _poly([for (var i = 0; i <= end; i++) r(top[i]), for (var i = end; i >= 0; i--) r(bot[i])]);
    shade = _poly([for (var i = 0; i <= end; i++) r(Offset.lerp(top[i], bot[i], .52)!), for (var i = end; i >= 0; i--) r(bot[i])]);
    final rp = Path(), ip = Path();
    for (final t0 in const [7, 9, 11]) {
      rp.addPolygon([r(top[t0] - b.nrm[t0] * .02), r(top[t0 + 1] - b.nrm[t0 + 1] * .02), r(bot[t0 + 1] + b.nrm[t0 + 1] * .02), r(bot[t0] + b.nrm[t0] * .02)], true);
    }
    for (final t0 in const [8, 10]) {
      ip.addPolygon([r(top[t0 + 1]), r(top[t0]), r(bot[t0]), r(bot[t0 + 1])], true);
    }
    rings = rp;
    inlay = ip;
    final bp = 9;
    base = _poly([for (var i = 0; i <= bp; i++) r(top[i]), for (var i = bp; i >= 0; i--) r(bot[i])]);
    cutA = r(top[end]);
    cutZ = r(bot[end]);
    if (!lower) {
      hiGold = Path()..addPolygon([for (var i = 2; i <= 16; i++) top[i] + b.nrm[i] * (.028 * (1 - i / 24))], false);
      // M3 (iter 5): the sheath's dark reflection band, a tapered strip between 20 % and
      // ~38 % of the bill's thickness, just under the hot highlight line (the same
      // metal logic as the plate: a dark band beside a hot highlight)
      final a = <Offset>[], z = <Offset>[];
      for (var i = 1; i <= end - 1; i++) {
        final k = 1 - i / (end + 1);
        a.add(Offset.lerp(top[i], bot[i], .19)!);
        z.add(Offset.lerp(top[i], bot[i], .19 + .20 * (.45 + .55 * k))!);
      }
      refl = _poly([...a, ...z.reversed]);
      hiHorn = Path()..addPolygon([for (var i = 3; i <= 17; i++) top[i] + b.nrm[i] * (.025 * (1 - i / 24))], false);
      tipHi = Path()
        ..moveTo(top[end + 1].dx + b.nrm[end + 1].dx * .008, top[end + 1].dy + b.nrm[end + 1].dy * .008)
        ..lineTo(top[22].dx + b.nrm[22].dx * .006, top[22].dy + b.nrm[22].dy * .006);
      nostril = b.top[5] + b.nrm[5] * .05;
    }
  }
  final bool lower;
  late final int end;
  late final Path poly, sheath, shade, rings, inlay, base;
  late final Offset cutA, cutZ;
  Path? hiGold, hiHorn, tipHi, refl;
  Offset? nostril;
}

final class _BillSet {
  _BillSet(this.b, this.ang)
      : lowerJaw = _Jaw(b, ang, true),
        upperJaw = _Jaw(b, ang, false) {
    if (ang > 0) {
      mouth = _poly(b.mouthPoly(ang));
      tongue = _poly([
        for (var i = 3; i <= 11; i++) NeferhooKit.rot(b.gape[i], -ang, _Bill.hinge),
        for (var i = 11; i >= 3; i--) NeferhooKit.rot(b.gape[i] - b.nrm[i] * .035, -ang, _Bill.hinge),
      ]);
    }
  }
  final _Bill b;
  final double ang;
  final _Jaw lowerJaw, upperJaw;
  Path? mouth, tongue;
}

// -----------------------------------------------------------------------------
// the static geometry and shaders of the head, built on first use

final class _Geo {
  // ---- the bill
  late final _Bill bill = _Bill(1.22);
  // at HUD sizes and in silhouette the bill is a little bolder, so it survives
  late final _Bill billBold = _Bill(1.34);
  late final _BillSet billClosed = _BillSet(bill, 0);
  late final _BillSet billClosedBold = _BillSet(billBold, 0);
  // the jaw's angle is quantised to 1/48 of its range (about half a pixel at
  // game size), so the sets of a speaking bill are built once and reused
  final _openSets = <int, _BillSet>{};
  _BillSet billAt(bool bold, double open) {
    final q = (open.clamp(0.0, 1.0) * 48).round();
    if (q == 0) return bold ? billClosedBold : billClosed;
    return _openSets.putIfAbsent(q + (bold ? 100 : 0), () => _BillSet(bold ? billBold : bill, q / 48 * .26));
  }

  // ---- the nemes: cap over the skull and the lappet falling to the collar
  late final Path nemes = Path()
    ..moveTo(-1.32, -2.00)
    ..cubicTo(-1.00, -2.16, -.52, -2.08, -.36, -1.76)
    ..cubicTo(-.26, -1.56, -.22, -1.30, -.25, -1.04)
    ..cubicTo(-.28, -.80, -.14, -.62, -.10, -.46)
    ..cubicTo(-.22, -.35, -.52, -.29, -.72, -.36)
    ..cubicTo(-.80, -.42, -.84, -.58, -.86, -.80)
    ..lineTo(-.90, -1.30)
    ..lineTo(-1.30, -1.60)
    ..close();
  late final Paint nemesGold = _shp(_gl(const Offset(-.3, -2.1), const Offset(-.6, -.3), [NeferhooPalette.goldHi, NeferhooPalette.goldLit, NeferhooPalette.gold, NeferhooPalette.goldShade], [0, .25, .6, 1]));
  late final Paint nemesShade = _shp(_gl(const Offset(-.1, -1.4), const Offset(-.95, -.35), [const Color(0x00000000), const Color(0x00000000), NeferhooHeadInk.goldCool.withValues(alpha: .55)], [0, .45, 1]));
  late final Paint nemesRim = _shs(_gl(const Offset(-.25, -2.0), const Offset(-.85, -.6), [NeferhooHeadInk.rimWarm.withValues(alpha: .85), NeferhooHeadInk.rimWarm.withValues(alpha: .35), NeferhooHeadInk.rimWarm.withValues(alpha: 0)], [0, .45, 1]), .17);
  late final Paint lapisFill = _shp(_gl(const Offset(-.6, -2.1), const Offset(-.4, -.3), [NeferhooPalette.lapisLit, NeferhooPalette.lapis, NeferhooPalette.lapisShade, NeferhooPalette.lapisDeep], [0, .3, .72, 1]));

  static const _k = 12;
  double _yk(int k, [int kk = _k]) {
    final t = k / kk;
    return -2.12 + 1.84 * (.88 * t + .12 * t * t);
  }

  List<Offset> _stripe(double y0, int k, double dy, [int kk = _k]) {
    final t = k / kk;
    final drop = .55 * math.pow(1 - t, 2.2).toDouble() + .09;
    final pw = 1.3 + .8 * math.pow(1 - t, 2).toDouble();
    final pts = <Offset>[];
    for (var i = 0; i <= 14; i++) {
      final u = i / 14;
      // a soft fold in the cloth: the stripes step as they cross the crease
      final x = -1.05 + 1.12 * u;
      final fold = .032 * _smooth((x + .62) / .09) * t;
      pts.add(Offset(x, y0 + dy + drop * math.pow(u, pw) + fold));
    }
    return pts;
  }

  static double _smooth(double v) {
    final x = v.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// Bold stripes: [n] lapis bands about half a pitch tall (6 for the HUD
  /// medallion and the 24 px keepsake, 7 for the play level: the concept's
  /// rhythm, readable at 40 px per unit).
  Path _boldStripes(int n) {
    final p = Path();
    for (var k = 0; k < n; k++) {
      final gap = _yk(k + 1, n) - _yk(k, n);
      final a = _stripe(_yk(k, n), k, gap * .06, n), b = _stripe(_yk(k, n), k, gap * .52, n);
      p.addPolygon([...a, ...b.reversed], true);
    }
    return p;
  }

  late final Path stripesBold = _boldStripes(6);
  late final Path stripesPlay = _boldStripes(7);
  // The close-up's texture lines follow the SAME seven bold bands as the play
  // level (f1-crest, M4): the stripes never change count or place at a switch.
  static const _nb = 7;
  late final Path stripeLit = () {
    final p = Path();
    for (var k = 0; k < _nb; k++) {
      final gap = _yk(k + 1, _nb) - _yk(k, _nb);
      p.addPolygon(_stripe(_yk(k, _nb), k, gap * .06 + .016, _nb).sublist(2), false);
    }
    return p;
  }();
  late final Path stripeDark = () {
    final p = Path();
    for (var k = 0; k < _nb; k++) {
      final gap = _yk(k + 1, _nb) - _yk(k, _nb);
      p.addPolygon(_stripe(_yk(k, _nb), k, gap * .52 - .014, _nb).sublist(2), false);
    }
    return p;
  }();
  late final Path stripeCast = () {
    // the lapis band's soft shadow on the gold under it
    final p = Path();
    for (var k = 0; k < _nb; k++) {
      final gap = _yk(k + 1, _nb) - _yk(k, _nb);
      final a = _stripe(_yk(k, _nb), k, gap * .52, _nb), b = _stripe(_yk(k, _nb), k, gap * .52 + .05, _nb);
      p.addPolygon([...a, ...b.reversed], true);
    }
    return p;
  }();
  late final Path foldShade = NeferhooKit.smoothPath(const [Offset(-.64, -1.2), Offset(-.55, -.95), Offset(-.50, -.6), Offset(-.50, -.3), Offset(-.58, -.3), Offset(-.60, -.62), Offset(-.66, -.95)]);
  late final Path foldLine = NeferhooKit.smoothPath(const [Offset(-.60, -1.2), Offset(-.52, -.95), Offset(-.47, -.6), Offset(-.47, -.3)], close: false);

  // ---- the face plate
  static const platePts = [
    Offset(-1.22, -2.03),
    Offset(-1.52, -1.98),
    Offset(-1.70, -1.80),
    Offset(-1.78, -1.58),
    Offset(-1.82, -1.40),
    Offset(-1.78, -1.18),
    Offset(-1.66, -.94),
    Offset(-1.44, -.76),
    Offset(-1.18, -.70),
    Offset(-.96, -.76),
    Offset(-.80, -.98),
    Offset(-.75, -1.30),
    Offset(-.77, -1.62),
    Offset(-.90, -1.90),
  ];
  late final Path plate = NeferhooKit.smoothPath(platePts);
  // the rear edge of the plate (the nemes' gold binding runs under it)
  late final Path plateRear = NeferhooKit.smoothPath(const [Offset(-.96, -.76), Offset(-.80, -.98), Offset(-.75, -1.30), Offset(-.77, -1.62), Offset(-.90, -1.90), Offset(-1.10, -2.02)], close: false);
  // M3 (iter 5): BURNISHED gold, not lemon plastic. The plate's gradient (forehead
  // top-left to chin bottom-right) is a reflection map, not a ramp: a hot lobe on
  // the forehead falling to saturated amber, a DARK warm reflection band across
  // the eye (t .45-.53: the socket's shadow, never grey or black), a hard step
  // (.025 of the length, a pixel at game size) into the hot cheek band, then an
  // amber fall-off, a narrow dark turn at the jaw and the sand light bounced under
  // it. The cheek probe window is t .69-.93 (it stays on the highlight: .81 / .78
  // / .73 at 1x; the hot band is widened a little toward the jaw, base .79 / .77 / .72); the forehead window (t .27-.47) stays on the lit tone
  // so the fury's forehead probe holds. Zero ops: only gradient stops.
  late final Paint plateFill = _shp(_gl(const Offset(-1.62, -2.04), const Offset(-1.12, -.66), _plateCols, _plateStops));
  static const _plateCols = [
    NeferhooPalette.goldHi, NeferhooHeadInk.goldPeak, NeferhooHeadInk.burnHot, NeferhooHeadInk.burnLit, NeferhooHeadInk.burnLit, NeferhooHeadInk.burnMid, // forehead: a hot lobe, lit amber
    NeferhooHeadInk.burnDark, NeferhooHeadInk.burnDark, // the dark reflection band through the eye (hard lower edge)
    NeferhooHeadInk.burnHot, NeferhooHeadInk.goldPeak, NeferhooHeadInk.burnHot, // the hot cheek band
    NeferhooHeadInk.burnLit, NeferhooHeadInk.burnMid, NeferhooHeadInk.burnAmber, // (closing round, N4) the cheek turns AMBER below the smile, not lemon: lit, body, deep
    NeferhooHeadInk.burnDark, NeferhooHeadInk.goldBounce, // the jaw's turn and the sand bounced under it
  ];
  static const _plateStops = [0.0, .05, .15, .27, .40, .45, .49, .535, .56, .71, .85, .895, .935, .957, .977, 1.0];
  // the eyelids (iter 5, M2): the mask's metal closing over the glass. A lid is a
  // raised, lit surface, so it is the BRIGHT amber (not the plate's dark reflection
  // band that sits behind the eye): a blink must read as a lid, not as a bruise
  late final Paint lidFill = _shp(_gl(const Offset(0, -1.70), const Offset(0, -1.12), [NeferhooHeadInk.burnHot, NeferhooHeadInk.burnLit, NeferhooHeadInk.burnMid], [0, .45, 1]));
  late final Paint bindingGold = _shs(_gl(const Offset(-.9, -2.0), const Offset(-.9, -.7), [NeferhooPalette.goldLit, NeferhooPalette.gold, NeferhooPalette.goldShade]), .24);

  /// Hammered dimples (a seeded scatter inside the plate): lit lower-left
  /// walls, shaded upper-right walls.
  late final (Path, Path) hammer = () {
    final lit = Path(), shade = Path();
    var seed = 20260930;
    double rnd() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    final pts = <Offset>[];
    var guard = 0;
    while (pts.length < 22 && guard++ < 600) {
      final q = Offset(-1.80 + rnd() * 1.0, -2.0 + rnd() * 1.3);
      if (!plate.contains(q)) continue;
      // keep clear of the eye, the brow, the rishi rows and the edges
      if ((q - NeferhooLayout.eye).distance < .42) continue;
      if (q.dy > -1.12 && q.dy < -.78) continue;
      if (q.dy < -1.68) continue;
      if (q.dx < -1.62 || q.dx > -.86) continue;
      if (pts.any((o) => (o - q).distance < .17)) continue;
      pts.add(q);
    }
    for (final q in pts) {
      final r = .035 + rnd() * .018;
      lit.addArc(Rect.fromCircle(center: q, radius: r), 1.9, 1.6);
      shade.addArc(Rect.fromCircle(center: q, radius: r), -1.25, 1.5);
    }
    return (lit, shade);
  }();

  /// Chased lines (dark groove) and their lit twin, the border dots.
  late final (Path, Path, Path) chased = () {
    final dark = Path();
    // the cheek: two chased lines following the jaw (the rishi scallops read as
    // fish scales above 2x, so the pattern was cut to its two strongest lines)
    dark.addPath(NeferhooKit.smoothPath(const [Offset(-1.60, -.98), Offset(-1.38, -.86), Offset(-1.14, -.84), Offset(-.98, -.92)], close: false), Offset.zero);
    dark.addPath(NeferhooKit.smoothPath(const [Offset(-1.52, -.88), Offset(-1.34, -.78), Offset(-1.14, -.76)], close: false), Offset.zero);
    // two chased lines on the forehead and one under the brow
    dark.addPath(NeferhooKit.smoothPath(const [Offset(-1.70, -1.70), Offset(-1.58, -1.83), Offset(-1.36, -1.90), Offset(-1.10, -1.88)], close: false), Offset.zero);
    dark.addPath(NeferhooKit.smoothPath(const [Offset(-1.66, -1.62), Offset(-1.54, -1.74), Offset(-1.34, -1.80), Offset(-1.10, -1.78)], close: false), Offset.zero);
    // the border: an inset line all round the plate
    final inset = Path();
    final m = plate.computeMetrics().first;
    final dots = Path();
    final len = m.length;
    const centre = Offset(-1.28, -1.36);
    final pts = <Offset>[];
    for (var d = 0.0; d < len; d += .045) {
      final tg = m.getTangentForOffset(d)!;
      final inward = _unit(centre - tg.position);
      pts.add(tg.position + inward * .065);
    }
    inset.addPolygon(pts, true);
    for (var d = .0; d < len; d += .11) {
      final tg = m.getTangentForOffset(d)!;
      dots.addOval(Rect.fromCircle(center: tg.position + _unit(centre - tg.position) * .115, radius: .0125));
    }
    dark.addPath(inset, Offset.zero);
    return (dark, dark.shift(const Offset(.014, -.014)), dots);
  }();

  // ---- the lapis brow (inlay) and the kohl wing
  late final Path brow = () {
    final top = <Offset>[], bot = <Offset>[];
    const p0 = Offset(-1.66, -1.60), p1 = Offset(-1.28, -1.93), p2 = Offset(-.80, -1.58);
    for (var i = 0; i <= 14; i++) {
      final u = i / 14;
      final v = 1 - u;
      final q = p0 * (v * v) + p1 * (2 * v * u) + p2 * (u * u);
      final th = .115 * math.pow(math.sin(math.pi * u), .7).toDouble() + .02;
      top.add(q);
      bot.add(q + Offset(0, th));
    }
    return Path()..addPolygon([...top, ...bot.reversed], true);
  }();
  late final Path browLit = NeferhooKit.smoothPath(const [Offset(-1.52, -1.74), Offset(-1.30, -1.84), Offset(-1.06, -1.80)], close: false);
  late final Path kohlWing = () {
    final e = NeferhooLayout.eye;
    return Path()
      ..moveTo(e.dx + .20, e.dy - .12)
      ..cubicTo(e.dx + .30, e.dy - .19, e.dx + .38, e.dy - .19, e.dx + .43, e.dy - .12)
      ..cubicTo(e.dx + .38, e.dy - .06, e.dx + .30, e.dy + .0, e.dx + .22, e.dy + .02)
      ..close();
  }();
  late final Path almond = () {
    final e = NeferhooLayout.eye;
    return Path()
      ..moveTo(e.dx - .27, e.dy + .02)
      ..cubicTo(e.dx - .19, e.dy - .27, e.dx + .12, e.dy - .29, e.dx + .26, e.dy - .03)
      ..cubicTo(e.dx + .12, e.dy + .22, e.dx - .19, e.dy + .24, e.dx - .27, e.dy + .02)
      ..close();
  }();
  late final Path caruncle = () {
    final e = NeferhooLayout.eye;
    return Path()
      ..moveTo(e.dx - .27, e.dy + .02)
      ..quadraticBezierTo(e.dx - .22, e.dy - .06, e.dx - .15, e.dy - .04)
      ..quadraticBezierTo(e.dx - .17, e.dy + .06, e.dx - .26, e.dy + .08)
      ..close();
  }();
  late final Paint sclera = _shp(_gl(const Offset(0, -1.6), const Offset(0, -1.22), [NeferhooHeadInk.quartzShade, NeferhooHeadInk.quartz, NeferhooHeadInk.quartz, const Color(0xfff2ece0)], [0, .3, .7, 1]));

  // ---- the ear rosette (gold, turquoise and carnelian)
  static const earAt = Offset(-.86, -1.16);

  // ---- the brow band (f1-crest): a short gold circlet on the mask's forehead,
  // BELOW and IN FRONT of the crest roots (they start behind its rear end),
  // with the courier's winged-letter badge. The same metal as the plate: one
  // gold, no bead rows. Parity: the band, the badge and its carnelian seal
  // exist at every level of detail; close-ups only add a specular line.
  static const _bandIn = .72, _bandOut = .88;
  static const bandFrom = -153.0, bandTo = -93.0;
  Offset _onBand(double deg, double r) {
    final a = deg * math.pi / 180;
    return NeferhooLayout.head + Offset(math.cos(a), math.sin(a)) * r;
  }

  late final Path band = () {
    final inner = <Offset>[], outer = <Offset>[];
    for (var d = bandFrom; d <= bandTo + .01; d += 3) {
      final e = math.min((d - bandFrom) / 12, (bandTo - d) / 12).clamp(0.0, 1.0);
      final taper = .42 + .58 * _smooth(e);
      final mid = (_bandIn + _bandOut) / 2, half = (_bandOut - _bandIn) / 2 * taper;
      inner.add(_onBand(d, mid - half));
      outer.add(_onBand(d, mid + half));
    }
    return Path()..addPolygon([...outer, ...inner.reversed], true);
  }();
  late final Paint bandFill = _shp(_gr(NeferhooLayout.head, .9, [NeferhooPalette.goldShade, NeferhooPalette.goldShade, NeferhooPalette.gold, NeferhooPalette.goldLit, NeferhooPalette.goldHi], [0, .77, .86, .93, .985]));
  late final Path bandHi = () {
    final pts = <Offset>[for (var d = bandFrom + 8; d <= bandTo - 4; d += 4) _onBand(d, _bandOut - .035)];
    return Path()..addPolygon(pts, false);
  }();

  late final Path insFlap = Path()
    ..moveTo(-.075, -.05)
    ..lineTo(0, .012)
    ..lineTo(.075, -.05);

  // ---- a linen chin wrap under the mask (the mummy peeks out) and its loose end
  late final Path chinWrap = NeferhooKit.smoothPath(const [Offset(-1.76, -1.04), Offset(-1.66, -.80), Offset(-1.42, -.62), Offset(-1.14, -.56), Offset(-.92, -.62), Offset(-.84, -.78), Offset(-.95, -.95), Offset(-1.30, -1.00), Offset(-1.70, -1.12)]);
  late final Path chinWrapLines = Path()
    ..moveTo(-1.58, -.74)
    ..lineTo(-1.50, -.66)
    ..moveTo(-1.36, -.66)
    ..lineTo(-1.30, -.60)
    ..moveTo(-1.14, -.62)
    ..lineTo(-1.10, -.58);
  late final Paint chinFill = _shp(_gl(const Offset(-1.3, -.8), const Offset(-1.1, -.52), [NeferhooPalette.linenLit, NeferhooPalette.linen, NeferhooPalette.linenShade]));
  // ---- the postal insignia: a winged sealed letter on a lapis panel
  static const insigniaDeg = -123.0;
  late final Path insWing = Path()
    ..moveTo(.07, .005)
    ..cubicTo(.12, -.07, .20, -.075, .27, -.045)
    ..cubicTo(.25, -.03, .24, -.025, .245, -.018)
    ..cubicTo(.23, .0, .22, .005, .22, .012)
    ..cubicTo(.20, .03, .18, .035, .17, .04)
    ..cubicTo(.13, .05, .09, .045, .07, .035)
    ..close();
  late final Path insWingLines = Path()
    ..moveTo(.10, .005)
    ..lineTo(.235, -.03)
    ..moveTo(.10, .02)
    ..lineTo(.205, .0)
    ..moveTo(.10, .035)
    ..lineTo(.165, .028);

  // ---- the crest feather in its own frame: root at 0, tip at 1 (f1-crest)
  // ONE rounded, slightly curled paddle, drawn seven times: the midline bends
  // toward +y (the back of the head, for an upright feather), the trailing
  // vane is a little wider than the leading one, the tip is blunt like a
  // real hoopoe's. Its colour bands are baked into one gradient: cinnamon
  // for three quarters of the length, a NARROW cream band, a black tip.
  static double _fm(double x) => .10 * x * x;
  static const _fx = [-.10, 0.0, .12, .30, .50, .68, .82, .92, .985, 1.035];
  static const _fh = [.030, .048, .092, .136, .154, .150, .128, .094, .050, 0.0];
  late final Path feather = () {
    final top = <Offset>[], bot = <Offset>[];
    for (var i = 0; i < _fx.length; i++) {
      top.add(Offset(_fx[i], _fm(_fx[i]) - _fh[i] * .92));
      if (i < _fx.length - 1) bot.add(Offset(_fx[i], _fm(_fx[i]) + _fh[i] * 1.10));
    }
    return NeferhooKit.smoothPath([...top, ...bot.reversed]);
  }();
  late final Paint featherA = _shp(_featherGradient(.73, .85, false));
  late final Paint featherB = _shp(_featherGradient(.69, .81, true));
  ui.Shader _featherGradient(double band, double tip, bool shade) {
    // a radial gradient centred far behind the root: its bands are arcs,
    // convex toward the tip, like a real feather's white bar and black tip.
    // Every other feather is a touch deeper (and its bands a touch lower), so
    // neighbours part without help from their outlines.
    const cx = -.95, r = 2.0;
    double at(double x) => (x - cx) / r;
    const cream = Color(0xfff2e3ca);
    // iter 5, m3: the cinnamon CHROMA is back in the body (#f08a4b mid, #ffb27a
    // lit; it had gone peach, #fab072 .. #ffd0a2), and the VALUE the squint view
    // needs comes from the lit zone starting early (the mid sits near the root,
    // most of the blade is the lit tone) and from the warm rim stroke on the sun
    // side. Every other feather is a touch deeper.
    // (iter 5, assembler: still peach at 1x with the lit zone starting at a third of the blade, so
    // the saturated orange now holds for two thirds of it and the light only arrives toward the
    // band: cinnamon-orange, not pastel; the sun-side rim and the cream band carry the value)
    final cs = shade
        ? const [Color(0xff93502f), Color(0xffdc743a), Color(0xffec8244), Color(0xfffa9a56), Color(0xffffaa68), Color(0xffffb77a)]
        : const [Color(0xff9c5834),Color(0xffe47e3e),Color(0xfff48c46),Color(0xffffa258), Color(0xffffb26c), Color(0xffffbf80)];
    return _gr(const Offset(cx, 0), r, [...cs, cream, cream, NeferhooPalette.barBlack, NeferhooPalette.barBlack], [0, at(.04), at(.13), at(.38), at(band - .10), at(band), at(band), at(tip), at(tip), 1]);
  }

  late final Path featherShaft = Path()
    ..moveTo(.02, 0)
    ..quadraticBezierTo(.45, _fm(.45) * 1.2, .80, _fm(.80));
  // the sun-facing edge of a feather (one local path per side)
  static double _hw(double x) {
    for (var i = 1; i < _fx.length; i++) {
      if (x <= _fx[i]) return _fh[i - 1] + (_fh[i] - _fh[i - 1]) * ((x - _fx[i - 1]) / (_fx[i] - _fx[i - 1]));
    }
    return 0;
  }

  late final Path featherRimPlus = NeferhooKit.smoothPath([for (final x in const [.08, .3, .5, .68, .82, .94]) Offset(x, _fm(x) + _hw(x) * 1.0)], close: false);
  late final Path featherRimMinus = NeferhooKit.smoothPath([for (final x in const [.08, .3, .5, .68, .82, .94]) Offset(x, _fm(x) - _hw(x) * .84)], close: false);

  // ---- the crest's layout: seven feathers, front (0) to rear (6) (f1-crest)
  static const crestN = 7;
  /// The raise at which the three key shapes meet: the fight's rest.
  static const restAt = .4;
  /// Where each root sits on the skull (degrees about the head centre, 0 =
  /// the back, -90 = the top): an arc along the crown from just behind the
  /// brow band to the nape, at this radius (hidden by the nemes).
  static const rootDeg = [-106.0, -95.0, -84.0, -73.0, -62.0, -51.0, -40.0];
  static const rootR = .70;
  // angles (radians, 0 = pointing back, -pi/2 = straight up)
  static const a0 = [-.60, -.50, -.42, -.34, -.26, -.18, -.10]; // flat on the head
  static const a1 = [-.98, -.90, -.82, -.75, -.68, -.62, -.56]; // the folded hammer
  // the fan, leaning back (iter 5, m3: +.14 rad = 8 degrees further back than before)
  static const a2 = [-1.66, -1.46, -1.26, -1.06, -.86, -.66, -.46];
  // lengths (rig units): the longest feathers sit at the back
  static const l0 = [.74, .90, 1.04, 1.16, 1.26, 1.32, 1.34];
  static const l1 = [.58, .76, .94, 1.10, 1.24, 1.34, 1.42];
  // the fan's lengths (iter 5, m3), already divided by lJit so the EFFECTIVE
  // lengths are [.97 1.15 1.34 1.38 1.35 1.18 1.00]: the centre three longest,
  // the front feather 70 % of the longest, the rear one a little longer
  static const l2 = [.97, 1.24, 1.26, 1.45, 1.26, 1.22, 1.09];
  // the irregularity: no two feathers alike (fixed, deterministic)
  static const aJit = [.03, -.05, .02, .04, -.03, .03, -.02];
  static const lJit = [1.0, .93, 1.06, .95, 1.07, .97, .92];
  static const wJit = [1.18, 1.30, 1.12, 1.26, 1.18, 1.28, 1.08];

  // ---- the skull: only the silhouette study paints it (in colour the body's
  // neck shows under the mask's chin)
  late final Path skull = Path()..addOval(Rect.fromCircle(center: NeferhooLayout.head, radius: NeferhooLayout.headR));

  // ---- cached strokes and fills the head reuses every frame
  late final Path specForehead = NeferhooKit.smoothPath(const [Offset(-1.64, -1.82), Offset(-1.74, -1.64), Offset(-1.77, -1.52)], close: false);
  late final Path specCheek = NeferhooKit.smoothPath(const [Offset(-1.58, -.98), Offset(-1.50, -.88)], close: false);
  late final Path plateRearRim = plateRear.shift(const Offset(-.045, 0));
  late final Path plateRearLine = plateRear.shift(const Offset(-.03, 0));
  late final Path crack = Path()
    ..moveTo(-1.16, -2.0)
    ..lineTo(-1.10, -1.86)
    ..lineTo(-1.21, -1.76)
    ..lineTo(-1.08, -1.66)
    ..lineTo(-1.16, -1.56)
    ..moveTo(-1.10, -1.86)
    ..lineTo(-.96, -1.82)
    ..lineTo(-.90, -1.74)
    ..moveTo(-1.21, -1.76)
    ..lineTo(-1.36, -1.80);
  late final Paint socketShade = _shp(_gr(NeferhooLayout.eye + const Offset(.05, .06), .62, [NeferhooPalette.goldDeep.withValues(alpha: .34), NeferhooPalette.goldDeep.withValues(alpha: .14), NeferhooPalette.goldDeep.withValues(alpha: 0)], [0, .55, 1]));
  late final Path frown = NeferhooKit.smoothPath(const [Offset(-1.52, -1.86), Offset(-1.36, -1.84), Offset(-1.20, -1.88)], close: false);
  late final Path earDots = () {
    final dots = Path();
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + .3;
      dots.addOval(Rect.fromCircle(center: earAt + Offset(math.cos(a), math.sin(a)) * .077, radius: .017));
    }
    return dots;
  }();
  late final Paint earFill = _shp(_gr(earAt + const Offset(-.03, -.03), .13, [NeferhooPalette.goldHi, NeferhooPalette.gold, NeferhooPalette.goldShade]));
  late final Paint browFill = _shp(_gl(const Offset(0, -1.95), const Offset(0, -1.55), [NeferhooPalette.lapisLit, NeferhooPalette.lapis, NeferhooPalette.lapisShade]));
  late final Paint panelFill = _shp(_gl(const Offset(0, -.1), const Offset(0, .1), [NeferhooPalette.lapisLit, NeferhooPalette.lapis, NeferhooPalette.lapisShade]));
  late final Paint scarfFill = _shp(_gl(const Offset(-1.0, -.95), const Offset(-.8, -.35), [NeferhooPalette.linenLit, NeferhooPalette.linen, NeferhooPalette.linenShade]));
  late final Paint scarfWrapFill = _shp(_gl(const Offset(-1.0, -.8), const Offset(-.8, -.45), [NeferhooPalette.linenLit, NeferhooPalette.linenShade]));
  late final Paint bareLidShade = _shp(_gl(NeferhooLayout.eye + const Offset(.03, -.18), NeferhooLayout.eye + const Offset(.03, .22), [NeferhooPalette.cinnShade.withValues(alpha: .0), NeferhooPalette.cinnShade.withValues(alpha: .55)]));
  // both insignia wings in one path (mirrored about the letter)
  late final Path insWings = Path()
    ..addPath(insWing, Offset.zero)
    ..addPath(insWing.transform(Float64List.fromList([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])), Offset.zero);
  late final Path insWingsLines = Path()
    ..addPath(insWingLines, Offset.zero)
    ..addPath(insWingLines.transform(Float64List.fromList([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])), Offset.zero);

  // ---- the bare head
  static const bareR = NeferhooLayout.headR * .95;
  late final Path bareSkull = Path()..addOval(Rect.fromCircle(center: NeferhooLayout.head, radius: bareR));
  late final Paint bareFill = _shp(_gr(NeferhooLayout.head + const Offset(-.25, -.3), 1.0, [NeferhooPalette.cinnLit, NeferhooPalette.cinn, NeferhooPalette.cinnShade]));

  /// Rows of little feather scallops over the crown and the nape.
  late final Path scallops = () {
    final p = Path();
    final h = NeferhooLayout.head;
    for (var r = 0; r < 5; r++) {
      final y = -1.96 + r * .13;
      for (var k = 0; k < 9; k++) {
        final x = -1.52 + k * .14 + (r.isOdd ? .07 : 0);
        final q = Offset(x, y);
        final d = (q - h).distance;
        if (d < .22 || d > .6) continue;
        if ((q - NeferhooLayout.eye).distance < .42) continue;
        if (q.dx < -1.45) continue;
        if (q.dy > -1.5 && q.dx < -.72) continue;
        p.addArc(Rect.fromCircle(center: q, radius: .052), .15, math.pi - .3);
      }
    }
    return p;
  }();
  late final Path cheekPatch = Path()..addOval(Rect.fromCenter(center: const Offset(-1.28, -.93), width: .86, height: .5));
  late final Paint cheekFill = _shp(_gr(const Offset(-1.28, -.93), .46, [NeferhooHeadInk.creamCheek.withValues(alpha: .85), NeferhooHeadInk.creamCheek.withValues(alpha: .0)]));
  late final Path dustCap = () {
    final h = NeferhooLayout.head;
    final outer = <Offset>[], inner = <Offset>[];
    for (var d = -152.0; d <= -18; d += 5) {
      final a = d * math.pi / 180;
      final k = math.sin(d * .21) * .03 + math.sin(d * .53) * .02;
      outer.add(h + Offset(math.cos(a), math.sin(a)) * (_Geo.bareR - .005));
      inner.add(h + Offset(math.cos(a), math.sin(a)) * (_Geo.bareR - .075 - k - ((d + 85).abs() / 67) * .04));
    }
    return Path()..addPolygon([...outer, ...inner.reversed], true);
  }();
  late final Path dustSpecks = () {
    final p = Path();
    final h = NeferhooLayout.head;
    var seed = 4004;
    double rnd() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    for (var i = 0; i < 16; i++) {
      final a = (-165 + rnd() * 170) * math.pi / 180;
      final r = .15 + rnd() * .5;
      final q = h + Offset(math.cos(a), math.sin(a)) * r;
      if ((q - NeferhooLayout.eye).distance < .36) continue;
      p.addOval(Rect.fromCircle(center: q, radius: .008 + rnd() * .014));
    }
    return p;
  }();
  late final Path wisps = Path()
    ..moveTo(-1.02, -1.99)
    ..quadraticBezierTo(-1.00, -2.10, -.92, -2.13)
    ..moveTo(-.94, -1.99)
    ..quadraticBezierTo(-.90, -2.08, -.82, -2.09)
    ..moveTo(-1.10, -1.98)
    ..quadraticBezierTo(-1.14, -2.08, -1.22, -2.10);
  // bushy brow: four overlapping tufts, in a local frame at the brow's centre
  late final Path browTufts = () {
    final p = Path();
    // (x, y, angle, length, width): from the front end, each tuft sweeps back
    // and up, overlapping the next like a bushy old brow
    for (final (x, y, a, l, w) in const [(-.24, .06, -.14, .24, .095), (-.11, .02, -.24, .27, .10), (.02, -.02, -.36, .27, .10), (.15, -.05, -.50, .23, .09)]) {
      final dir = Offset(math.cos(a), math.sin(a));
      final nr = Offset(-dir.dy, dir.dx);
      final o = Offset(x, y);
      final tip = o + dir * l;
      p.moveTo(o.dx - nr.dx * w * .5, o.dy - nr.dy * w * .5);
      p.quadraticBezierTo(o.dx + dir.dx * l * .55 - nr.dx * w * .95, o.dy + dir.dy * l * .55 - nr.dy * w * .95, tip.dx, tip.dy);
      p.quadraticBezierTo(o.dx + dir.dx * l * .5 + nr.dx * w * 1.1, o.dy + dir.dy * l * .5 + nr.dy * w * 1.1, o.dx + nr.dx * w * .5, o.dy + nr.dy * w * .5);
      p.close();
    }
    return p;
  }();
  // m1 (iter 5): the old white roll was a .36 u thick lilac sausage (a neck
  // brace). Now a soft scarf: ~60 % of the thickness, tapering to the back, a
  // diagonal twist fold, and a real knot where the ends leave it.
  late final Path scarf = NeferhooKit.smoothPath(const [Offset(-1.50, -.88), Offset(-1.10, -.72), Offset(-.58, -.76), Offset(-.42, -.65), Offset(-.50, -.55), Offset(-1.02, -.52), Offset(-1.46, -.69)]);
  late final Path scarfWrap = NeferhooKit.smoothPath(const [Offset(-1.28, -.84), Offset(-.92, -.70), Offset(-.60, -.71), Offset(-.66, -.62), Offset(-1.02, -.60), Offset(-1.30, -.71)]);
  late final Path scarfLines = Path()
    ..moveTo(-1.42, -.76)
    ..quadraticBezierTo(-1.0, -.56, -.58, -.64)
    ..moveTo(-1.34, -.60)
    ..quadraticBezierTo(-1.0, -.55, -.62, -.57);
  /// The knot: a pinched bundle on the scarf's back end (two lobes round a cinch).
  late final Path scarfKnot = NeferhooKit.smoothPath(const [Offset(-.62, -.62), Offset(-.55, -.69), Offset(-.50, -.64), Offset(-.44, -.69), Offset(-.37, -.62), Offset(-.40, -.53), Offset(-.50, -.52), Offset(-.60, -.53)]);
  late final Path scarfKnotFolds = Path()
    ..moveTo(-.50, -.64)
    ..quadraticBezierTo(-.48, -.59, -.50, -.53)
    ..moveTo(-.57, -.64)
    ..quadraticBezierTo(-.53, -.61, -.55, -.56)
    ..moveTo(-.43, -.64)
    ..quadraticBezierTo(-.46, -.61, -.45, -.56);
  late final Path scarfEnds = Path()
    ..moveTo(-.58, -.58)
    ..lineTo(-.42, -.56)
    ..lineTo(-.38, -.24)
    ..lineTo(-.415, -.28)
    ..lineTo(-.44, -.21)
    ..lineTo(-.47, -.27)
    ..lineTo(-.52, -.20)
    ..lineTo(-.55, -.31)
    ..close();
}

final _Geo _geo = _Geo();

// -----------------------------------------------------------------------------

extension NeferhooHeadArt on NeferhooPainter {
  int get _lod => lod;

  // ===========================================================================
  // the masked head

  /// Skull linen (the wrap peeking under the chin), nemes, mask, diadem.
  void headMaskedArt() {
    final g = _geo;
    if (silhouette) {
      c.drawPath(g.skull, f(sil));
      c.drawPath(g.nemes, f(sil));
      c.drawPath(g.plate, f(sil));
      beakArt(gold: true);
      c.drawPath(g.band, f(sil));
      return;
    }
    // (the body's neck shows under the chin: no skull of its own is painted)
    nemesArt();
    maskArt();
    diademArt();
  }

  /// The striped nemes: crown and lappet, with shaded folds.
  void nemesArt() {
    final g = _geo;
    if (silhouette) {
      c.drawPath(g.nemes, f(sil));
      return;
    }
    final lod = _lod;
    c.drawPath(g.nemes, g.nemesGold);
    c.save();
    c.clipPath(g.nemes);
    if (lod <= 1) {
      c.drawPath(g.stripesBold, g.lapisFill);
    } else if (lod == 2) {
      // PLAY: seven bold lapis bands on gold, no fine lines (they fuse into
      // one dark column at 1x)
      c.drawPath(g.stripesPlay, g.lapisFill);
    } else {
      c.drawPath(g.stripeCast, _fp(NeferhooPalette.goldCool, .38));
      c.drawPath(g.stripesPlay, g.lapisFill);
      c.drawPath(g.stripeLit, _sp(NeferhooPalette.lapisLit, .02, .75));
      c.drawPath(g.stripeDark, _sp(NeferhooPalette.lapisDeep, .022, .8));
      c.drawPath(g.foldShade, _fp(const Color(0xff3a2060), .22));
      c.drawPath(g.foldLine, _sp(NeferhooPalette.rim, .02, .22));
    }
    if (lod >= 3) c.drawPath(g.nemes, g.nemesShade);
    c.drawPath(g.nemes, g.nemesRim);
    c.restore();
    // the gold binding under the plate's rear edge, then the cloth's outline
    c.drawPath(g.nemes, _sp(NeferhooPalette.ink, NeferhooLayout.major));
    c.drawPath(g.plateRear, _sp(NeferhooPalette.ink, .27));
    c.drawPath(g.plateRear, g.bindingGold);
    if (lod >= 3) c.drawPath(g.plateRearLine, _sp(NeferhooPalette.goldDeep, .02, .8));
  }

  /// The face plate with its beak, eye and ornaments.
  void maskArt() {
    final g = _geo;
    if (silhouette) {
      c.drawPath(g.plate, f(sil));
      beakArt(gold: true);
      return;
    }
    final lod = _lod;
    beakArt(gold: true);
    _chinWrap(lod);
    c.drawPath(g.plate, g.plateFill);
    // the goldwork (hammering, chased lines, the granulated border) is texture
    // below ~60 px per unit: it would darken the gold, so only close-ups get it
    if (lod >= 3) {
      c.drawPath(g.hammer.$1, _sp(NeferhooPalette.goldHi, .016, .55));
      c.drawPath(g.hammer.$2, _sp(NeferhooHeadInk.goldCool, .016, .5));
      c.drawPath(g.chased.$2, _sp(NeferhooPalette.goldHi, .02, .55));
      c.drawPath(g.chased.$1, _sp(NeferhooPalette.goldShade, .024, .85));
      c.drawPath(g.chased.$3, _fp(NeferhooPalette.goldShade, .8));
    }
    _plateLight();
    c.drawPath(g.plate, _sp(NeferhooPalette.ink, NeferhooLayout.hero * .9));
    _mouthCrease();
    earArt();
    eyeArt();
    _beakRing();
    _crackArt();
  }

  /// The mummy's linen under the mask: a wrap round the jaw.
  void _chinWrap(int lod) {
    final g = _geo;
    c.drawPath(g.chinWrap, g.chinFill);
    if (lod >= 3) c.drawPath(g.chinWrapLines, _sp(NeferhooPalette.linenBand, .028, .9));
    c.drawPath(g.chinWrap, _sp(NeferhooPalette.ink, .05));
  }

  /// A steady specular streak, the rim light on the sun side, and the glint
  /// that travels across the gold with `phase` (a pure function of it).
  void _plateLight() {
    final g = _geo;
    final lod = _lod;
    c.drawPath(g.specForehead, _sp(const Color(0xffffffff), .06, .55));
    if (lod >= 3) c.drawPath(g.specCheek, _sp(const Color(0xffffffff), .05, .4));
    // warm rim along the rear/upper edge (the sun is behind-right)
    c.drawPath(g.plateRearRim, _sp(NeferhooHeadInk.rimWarm, .045, .6));
    if (lod < 1) return;
    // the glint: a pale diagonal sheen sweeping from the brow to the cheek
    // (an event gleam: `glint` 0..1 is the sheen's own position, and the idle
    // one is then silent; -1 = the idle sheen every ~3.3 s of phase)
    final ev = p.glint >= 0;
    final cyc = ev ? p.glint.clamp(0.0, 1.0) * .46 : (p.phase * .30) % 1.0;
    if (cyc >= .46) return;
    final u = cyc / .46;
    final k = math.sin(math.pi * u);
    final centre = Offset.lerp(const Offset(-1.72, -1.78), const Offset(-.86, -.86), u)!;
    c.save();
    c.clipPath(g.plate);
    c.translate(centre.dx, centre.dy);
    c.rotate(.62);
    c.drawRect(Rect.fromCenter(center: Offset.zero, width: .26, height: 2.4), _fp(const Color(0xffffffff), .18 * k));
    c.drawRect(Rect.fromCenter(center: Offset.zero, width: .075, height: 2.4), _fp(const Color(0xffffffff), .62 * k));
    c.restore();
    if (k > .72) {
      // the "ting": a four-point star on the brow ridge
      final s = Offset.lerp(const Offset(-1.64, -1.70), const Offset(-1.52, -1.12), u)! ;
      final r = .12 * (k - .5) * 2;
      c.drawPath(Path()
        ..moveTo(s.dx, s.dy - r)
        ..quadraticBezierTo(s.dx, s.dy, s.dx + r * .8, s.dy)
        ..quadraticBezierTo(s.dx, s.dy, s.dx, s.dy + r)
        ..quadraticBezierTo(s.dx, s.dy, s.dx - r * .8, s.dy)
        ..quadraticBezierTo(s.dx, s.dy, s.dx, s.dy - r)
        ..close(), _fp(const Color(0xffffffff), .95));
    }
  }

  /// The smile: ONE bold ink curve from the bill's root to the cheek, a friendly
  /// upturn at rest (the face the owner liked), deeper with `smile` and with a
  /// dimple at its end, inverted when sad. It is the mouth the mask does not have.
  void _mouthCrease() {
    final sad = _sad;
    final happy = p.smile.clamp(0.0, 1.0);
    final angry = (-p.brow).clamp(0.0, 1.0);
    // the curve: its left end under the bill's root, a shallow belly, the right
    // end lifting at the cheek
    // (iter 5, M2) a furious boss must not smirk: the lift goes flat with `angry`
    // (the mail call's brow -.4 keeps most of the fussy upturn)
    final up = .13 + happy * .14 - sad * .26 - angry * .14;
    final belly = .045 + happy * .05 - sad * .07 - angry * .02;
    final path = NeferhooKit.smoothPath([
      const Offset(-1.58, -1.08),
      Offset(-1.45, -1.08 + belly * .9),
      Offset(-1.30, -1.08 + belly),
      Offset(-1.17, -1.08 - up * .45),
      Offset(-1.08, -1.08 - up),
    ], close: false);
    // a bold curve at game size (.075 u = 3 px at 1x; it was a 2 px crease) with a lifted
    // cheek end and a small cheek dot, so the warm, smug old postman reads at 640x360
    final w = _lod >= 3 ? .046 : (_lod == 2 ? .075 : .06);
    c.drawPath(path, _sp(NeferhooPalette.ink, w));
    // the cheek dot of the smug upturn fades out as the mouth goes flat
    final dot = 1 - ((angry - .25) / .5).clamp(0.0, 1.0);
    if (_lod <= 2 && happy <= .5 && sad < .3 && dot > .02) {
      c.drawCircle(Offset(-1.06, -1.08 - up - .02), .034, _fp(NeferhooPalette.ink, dot));
    }
    if (happy > .5) {
      // the cheek dimple of a real grin
      c.drawArc(Rect.fromCircle(center: Offset(-1.07, -1.08 - up), radius: .05), -2.0, 2.0, false, _sp(NeferhooPalette.ink, .034, happy));
    }
  }

  /// The explicit `sad` channel (a sleepy or beaten hero is not a sad one).
  double get _sad => (p.sad * (1 - p.smile.clamp(0.0, 1.0)) * (p.brow >= 0 ? 1.0 : 0.0)).clamp(0.0, 1.0);

  /// A gold, turquoise and carnelian ear rosette with a pendant.
  void earArt() {
    final e = _Geo.earAt;
    c.drawCircle(e, .118, _geo.earFill);
    c.drawCircle(e, .118, _sp(NeferhooPalette.ink, .03));
    if (_lod == 0) return;
    if (_lod >= 3) c.drawPath(_geo.earDots, _fp(NeferhooPalette.carn));
    c.drawCircle(e, .05, _fp(NeferhooPalette.turq));
    // the pendant's turquoise bead is there at every level of detail; close-ups
    // add its link, its ink ring, a sway and the catchlight
    if (_lod < 3) {
      c.drawCircle(e + const Offset(0, .21), .045, _fp(NeferhooPalette.turq));
      return;
    }
    c.drawCircle(e + const Offset(-.016, -.016), .014, _fp(const Color(0xffffffff), .8));
    final bead = e + Offset(math.sin(p.phase * 2.2) * .008, .21);
    c.drawLine(e + const Offset(0, .12), bead + const Offset(0, -.04), _sp(NeferhooPalette.goldDeep, .03));
    c.drawCircle(bead, .045, _fp(NeferhooPalette.turq));
    c.drawCircle(bead, .045, _sp(NeferhooPalette.ink, .022));
  }

  /// The fury crack: a jagged line across the forehead with a turquoise core.
  void _crackArt() {
    if (p.cracked <= 0) return;
    final cr = _geo.crack;
    final a = p.cracked.clamp(0.0, 1.0);
    c.drawPath(cr, _sp(NeferhooPalette.ink, .05, a));
    c.drawPath(cr, _sp(NeferhooPalette.magic, .024, a * .95));
    if (p.glow > .2) c.drawCircle(const Offset(-1.12, -1.74), .16, _fp(NeferhooPalette.magic, .10 * p.glow));
  }

  // ===========================================================================
  // the beak

  /// The long gold-sheathed hoopoe bill (or, bare, the dusty horn bill).
  void beakArt({required bool gold}) {
    final g = _geo;
    final bold = silhouette || _lod == 0;
    final open = p.beak.clamp(0.0, 1.0);
    final set = g.billAt(bold, open);
    final ang = set.ang;
    if (silhouette) {
      c.drawPath(set.upperJaw.poly, f(sil));
      c.drawPath(set.lowerJaw.poly, f(sil));
      return;
    }
    final lod = _lod;
    if (set.mouth != null && ang > .03) {
      c.drawPath(set.mouth!, _fp(NeferhooHeadInk.plum));
      c.drawPath(set.tongue!, _fp(NeferhooHeadInk.tongue, .85));
    }
    final horn = gold ? NeferhooHeadInk.horn : const Color(0xff2f2638);
    // lower jaw first, then the upper over it
    for (final jaw in [set.lowerJaw, set.upperJaw]) {
      final lowerJaw = jaw.lower;
      c.drawPath(jaw.poly, _fp(horn));
      if (gold) {
        c.drawPath(jaw.sheath, _fp(lowerJaw ? NeferhooHeadInk.burnMid : NeferhooHeadInk.burnLit));
        c.drawPath(jaw.shade, _fp(lowerJaw ? NeferhooHeadInk.goldCool : NeferhooPalette.goldShade, .85));
        if (!lowerJaw) c.drawPath(jaw.refl!, _fp(NeferhooHeadInk.burnDark, .85));
        if (!lowerJaw && lod > 0) c.drawPath(jaw.hiGold!, _sp(NeferhooPalette.goldHi, .03, .95));
        // banding rings: raised gold bands with a lapis (turquoise, below) inlay between
        if (lod > 0) {
          c.drawPath(jaw.rings, _fp(lowerJaw ? NeferhooPalette.goldLit : NeferhooPalette.goldHi));
          c.drawPath(jaw.rings, _sp(NeferhooPalette.goldDeep, .022, .9));
          c.drawPath(jaw.inlay, _fp(lowerJaw ? NeferhooPalette.turq : NeferhooPalette.lapis));
        }
      } else {
        // the bare, dusty horn: a pale pinkish base fading to dark
        c.drawPath(jaw.sheath, _fp(const Color(0xff463a4e)));
        c.drawPath(jaw.base, _fp(const Color(0xffd0ae9f)));
        if (!lowerJaw) {
          c.drawCircle(jaw.nostril!, .016, _fp(NeferhooPalette.ink, .85));
          c.drawPath(jaw.hiHorn!, _sp(NeferhooHeadInk.hornLit, .028, .8));
        }
      }
      c.drawPath(jaw.poly, _sp(NeferhooPalette.ink, lowerJaw ? .036 : .042));
      // the end of the sheath: a crisp ink step before the horn tip
      c.drawLine(jaw.cutA, jaw.cutZ, _sp(NeferhooPalette.ink, .035));
      if (gold && lod > 0 && !lowerJaw) c.drawPath(jaw.tipHi!, _sp(NeferhooHeadInk.hornLit, .018, .9));
    }
  }

  /// The socket ring where the bill leaves the mask.
  void _beakRing() {
    final b = _lod == 0 ? _geo.billBold : _geo.bill;
    const i = 4;
    final q = [b.top[i] - b.nrm[i] * .03, b.top[i + 1] - b.nrm[i + 1] * .03, b.low[i + 1] + b.nrm[i + 1] * .03, b.low[i] + b.nrm[i] * .03];
    c.drawPath(_poly(q), _fp(NeferhooPalette.goldLit));
    c.drawPath(_poly(q), _sp(NeferhooPalette.ink, .035));
    c.drawLine(b.top[i + 1] + b.nrm[i + 1] * .04, b.top[i + 1] + b.nrm[i + 1] * .17, _sp(NeferhooPalette.goldHi, .02, .9));
  }

  // ===========================================================================
  // the eye

  void eyeArt() {
    if (!fx) return;
    final g = _geo;
    final e = NeferhooLayout.eye;
    final lod = _lod;
    final glow = p.glow.clamp(0.0, 1.0);
    final angry = (-p.brow).clamp(0.0, 1.0);
    final wide = p.brow.clamp(0.0, 1.0);
    final sad = _sad;
    final happy = p.smile.clamp(0.0, 1.0);
    if (glow > .02) {
      c.drawCircle(e, .42, _fp(NeferhooPalette.magic, .075 * glow));
      c.drawCircle(e, .31, _fp(NeferhooPalette.magic, .12 * glow));
    }
    // surprise: the whole eye opens wider
    final stretch = wide > .05;
    if (stretch) {
      c.save();
      c.translate(e.dx, e.dy);
      c.scale(1.0, 1 + .34 * wide);
      c.translate(-e.dx, -e.dy);
    }
    c.drawCircle(e + const Offset(.05, .06), .62, g.socketShade);
    // the painted eye line: a kohl frame and its long wing
    c.drawPath(g.kohlWing, _fp(NeferhooHeadInk.kohl));
    c.drawPath(g.kohlWing, _sp(NeferhooPalette.ink, .022));
    c.drawPath(g.almond, g.sclera);
    // iris, pupil, catchlights
    final look = p.look;
    final iris = e + const Offset(-.03, .0) + Offset(look.dx * .09, look.dy * .05);
    final ir = .155 - wide * .025;
    final irisCol = Color.lerp(NeferhooHeadInk.amber, NeferhooPalette.turqShade, glow)!;
    c.drawCircle(iris, ir, _fp(irisCol));
    c.drawCircle(iris, ir * .72, _fp(Color.lerp(NeferhooHeadInk.obsidian, NeferhooPalette.magic, glow * .85)!));
    c.drawCircle(iris, ir * .40 * (1 - glow * .15), _fp(glow > .5 ? NeferhooPalette.ink : const Color(0xff07040c)));
    c.drawCircle(iris + Offset(-ir * .38, -ir * .44), ir * .34, _fp(const Color(0xffffffff)));
    c.drawCircle(iris + Offset(ir * .40, ir * .38), ir * .14, _fp(const Color(0xffffffff), .85));
    if (lod >= 3) c.drawArc(Rect.fromCircle(center: iris, radius: ir * .86), .25, .9, false, _sp(const Color(0xffffffff), .016, .35));
    // the lids: gold, so the mask's metal closes over the glass
    final cover = math.max(math.max(p.lid, p.sleepy * .5), happy * .14).clamp(0.0, 1.0);
    final tilt = angry * .14 - sad * .15;
    if (cover > .01 || angry > .02 || sad > .02) {
      final top = <Offset>[], bot = <Offset>[];
      for (var i = 0; i <= 8; i++) {
        final u = i / 8;
        final x = e.dx - .27 + .53 * u;
        final y0 = _almondTop(u, e);
        final y1 = _almondBot(u, e);
        final lid = (y0 + (y1 - y0) * cover + tilt * (1 - u * 2) * .9 + angry * .03).clamp(y0, y1);
        top.add(Offset(x, y0 - .012));
        bot.add(Offset(x, lid));
      }
      c.drawPath(Path()..addPolygon([...top, ...bot.reversed], true), g.lidFill);
      c.drawPath(Path()..addPolygon(bot, false), _sp(NeferhooPalette.ink, cover > .6 ? .045 : .03, .9));
    }
    if (happy > .05) {
      // smiling eyes: the cheek pushes the lower lid up into a gold crescent
      final bot = <Offset>[], top = <Offset>[];
      for (var i = 0; i <= 8; i++) {
        final u = i / 8;
        final x = e.dx - .27 + .53 * u;
        final y1 = _almondBot(u, e);
        final y0 = _almondTop(u, e);
        bot.add(Offset(x, y1 + .012));
        top.add(Offset(x, (y1 - (y1 - y0) * .52 * happy * math.pow(math.sin(math.pi * u).clamp(.0, 1.0), .75)).clamp(y0, y1)));
      }
      c.drawPath(Path()..addPolygon([...top, ...bot.reversed], true), g.lidFill);
      c.drawPath(Path()..addPolygon(top, false), _sp(NeferhooPalette.ink, .04, .95));
    }
    if (lod >= 3) c.drawPath(g.caruncle, _fp(NeferhooPalette.carn));
    c.drawPath(g.almond, _sp(NeferhooHeadInk.kohl, lod >= 3 ? .058 : .04));
    c.drawPath(g.almond, _sp(NeferhooPalette.ink, .02, .9));
    c.drawCircle(e + const Offset(-.205, -.002), .012, _fp(const Color(0xffffffff), .85));
    if (stretch) c.restore();
    _browArt(angry: angry, wide: wide, sad: sad, happy: happy);
  }

  double _almondTop(double u, Offset e) => e.dy - .26 * math.sin(math.pi * u).clamp(0.0, 1.0) * (1 - .12 * (u - .5).abs()) + .02 - .03 * u;
  double _almondBot(double u, Offset e) => e.dy + .22 * math.sin(math.pi * u).clamp(0.0, 1.0) * (1 - .1 * (u - .5).abs()) + .02 - .02 * u;

  /// The lapis brow inlay: it tilts down toward the beak when angry, up when
  /// sad, arches when surprised.
  void _browArt({required double angry, required double wide, required double sad, required double happy}) {
    final g = _geo;
    final rotate = -angry * .46 + sad * .46 - happy * .06;
    final lift = wide * .2 + happy * .08 - angry * .03 + sad * .03;
    final moved = rotate.abs() > .005 || lift.abs() > .005;
    if (moved) {
      c.save();
      c.translate(-.85, -1.6 - lift);
      c.rotate(rotate);
      c.translate(.85, 1.6);
    }
    c.drawPath(g.brow, _sp(NeferhooPalette.goldDeep, .05, .9));
    c.drawPath(g.brow, g.browFill);
    c.drawPath(g.brow, _sp(NeferhooPalette.ink, .025));
    if (_lod >= 3) c.drawPath(g.browLit, _sp(const Color(0xffcfdcff), .02, .75));
    if (moved) c.restore();
    if (angry > .3) c.drawPath(g.frown, _sp(NeferhooPalette.goldDeep, .035, angry));
  }

  // ===========================================================================
  // the diadem

  /// The gold brow band with the courier's insignia (a winged sealed letter):
  /// part of the mask, in front of and below the crest.
  void diademArt() {
    final g = _geo;
    if (silhouette) return;
    final lod = _lod;
    c.drawPath(g.band, g.bandFill);
    c.drawPath(g.band, _sp(NeferhooPalette.ink, NeferhooLayout.part));
    if (lod >= 3) c.drawPath(g.bandHi, _sp(const Color(0xffffffff), .02, .6));
    _insignia(lod);
  }

  void _insignia(int lod) {
    final g = _geo;
    final at = g._onBand(_Geo.insigniaDeg, (_Geo._bandIn + _Geo._bandOut) / 2);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(_Geo.insigniaDeg * math.pi / 180 + math.pi / 2);
    c.scale(.78);
    // lapis panel in a gold bezel
    final panel = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: .54, height: .21), const Radius.circular(.09));
    c.drawRRect(panel.inflate(.022), _fp(NeferhooPalette.goldDeep));
    c.drawRRect(panel, g.panelFill);
    c.drawRRect(panel.inflate(.022), _sp(NeferhooPalette.ink, .022));
    // gold wings and the cream sealed letter
    c.drawPath(g.insWings, _fp(NeferhooPalette.goldLit));
    c.drawPath(g.insWings, _sp(NeferhooPalette.ink, .016));
    if (lod > 2) c.drawPath(g.insWingsLines, _sp(NeferhooPalette.goldDeep, .014, .9));
    final env = Rect.fromCenter(center: Offset.zero, width: .15, height: .10);
    c.drawRect(env, _fp(NeferhooPalette.papyrusHi));
    c.drawRect(env, _sp(NeferhooPalette.ink, .018));
    if (lod > 2) c.drawPath(g.insFlap, _sp(NeferhooPalette.goldShade, .014));
    c.drawCircle(const Offset(0, .014), .034, _fp(NeferhooPalette.carn));
    c.restore();
  }

  // ===========================================================================
  // the crest (f1-crest)

  /// A hoopoe crest, not a headdress: 7 cinnamon feathers rooted ALONG the
  /// crown (an arc from the forehead to the nape, hidden behind the nemes),
  /// each tipped in black with only a narrow cream band before it. It folds
  /// back into a pointed "hammer" (the fight's rest, `crest` ~ .4) and fans
  /// up and back only for the roar, the ankh and the fury beats (`crest` 1).
  /// No two feathers are alike (length, angle, width, band), the longest sit
  /// at the back, and nothing is symmetric about the vertical.
  void crestArt() {
    final g = _geo;
    const n = _Geo.crestN;
    final raise = p.crest.clamp(0.0, 1.0);
    final lod = _lod;
    final fury = p.fury;
    // the unmasked head hides less of the roots, so they start deeper in
    final rootIn = p.mask ? 0.0 : .07;
    // the flutter is a fan's: a folded crest barely stirs
    final stir = .35 + .65 * raise;

    // blend a feather's value between its three key shapes: flat (0), the
    // folded hammer (rest) and the fan (1)
    double key(double a0, double a1, double a2) {
      if (raise <= _Geo.restAt) return a0 + (a1 - a0) * _Geo._smooth(raise / _Geo.restAt);
      return a1 + (a2 - a1) * _Geo._smooth((raise - _Geo.restAt) / (1 - _Geo.restAt));
    }

    (Offset, double, double, double) feather(int i) {
      final deg = _Geo.rootDeg[i] * math.pi / 180;
      final dir0 = Offset(math.cos(deg), math.sin(deg));
      final root = NeferhooLayout.head + dir0 * _Geo.rootR;
      final wob = math.sin(p.phase * 2.4 + i * .9) * .025 * (1 + fury * 2.5) * stir;
      final a = key(_Geo.a0[i], _Geo.a1[i], _Geo.a2[i]) + _Geo.aJit[i] + wob;
      final len = key(_Geo.l0[i], _Geo.l1[i], _Geo.l2[i]) * _Geo.lJit[i] * (1 + .012 * stir * math.sin(p.phase * 3.1 + i * 1.3));
      final dir = Offset(math.cos(a), math.sin(a));
      return (root - dir * rootIn, a, len, _Geo.wJit[i]);
    }

    void place(Offset root, double a, double s, double w) {
      final ca = math.cos(a) * s, sa = math.sin(a) * s;
      c.transform(Float64List.fromList([ca, sa, 0, 0, -sa * w, ca * w, 0, 0, 0, 0, 1, 0, root.dx, root.dy, 0, 1]));
    }

    // the front feathers first: the long rear ones lie over them (a hammer's
    // smooth lower body and sharp tip)
    for (var i = 0; i < n; i++) {
      final (root, a, len, w) = feather(i);
      final s = len * 1.02;
      c.save();
      place(root, a, s, w);
      if (silhouette) {
        c.drawPath(g.feather, f(sil));
        c.restore();
        continue;
      }
      c.drawPath(g.feather, i.isEven ? g.featherA : g.featherB);
      if (lod >= 3) c.drawPath(g.featherShaft, _sp(const Color(0xff7a3f22), .02 / s, .6));
      // the warm rim on the sun side (up and to the right), at every size: it keeps the
      // crest's top edge bright against the sky
      final nrm = Offset(-math.sin(a), math.cos(a));
      final facing = nrm.dx * .6 - nrm.dy * .8;
      if (facing.abs() > .3) c.drawPath(facing > 0 ? g.featherRimPlus : g.featherRimMinus, _sp(NeferhooHeadInk.rimWarm, (lod >= 3 ? .045 : .07) / s, lod >= 3 ? .65 : .85));
      c.drawPath(g.feather, _sp(NeferhooPalette.ink, (lod >= 2 ? NeferhooLayout.detail * 1.15 : NeferhooLayout.detail * 1.3) / s));
      c.restore();
    }
  }

  // ===========================================================================
  // the bare head: an old, dusty, endearing hoopoe

  void bareHeadArt() {
    final g = _geo;
    if (silhouette) {
      beakArt(gold: false);
      c.drawPath(g.bareSkull, f(sil));
      c.drawPath(g.scarf, f(sil));
      return;
    }
    final lod = _lod;
    beakArt(gold: false);
    c.drawPath(g.bareSkull, g.bareFill);
    // a paler cheek and throat, little feather scallops, the dust of ages
    c.drawPath(g.cheekPatch, g.cheekFill);
    if (lod > 0) {
      c.drawPath(g.scallops, _sp(NeferhooPalette.cinnShade, .024, .5));
      c.drawPath(g.dustCap, _fp(NeferhooHeadInk.dust, .26));
      if (lod > 1) c.drawPath(g.dustSpecks, _fp(NeferhooHeadInk.dust, .55));
      c.drawPath(g.wisps, _sp(NeferhooHeadInk.whiskerGrey, .026, .95));
    }
    c.drawPath(g.bareSkull, _sp(NeferhooPalette.ink, NeferhooLayout.hero));
    // the ear: a darker hollow behind the eye
    if (lod > 0) {
      c.drawOval(Rect.fromCenter(center: const Offset(-.86, -1.14), width: .12, height: .18), _fp(NeferhooPalette.cinnShade, .85));
      c.drawArc(Rect.fromCenter(center: const Offset(-.86, -1.14), width: .12, height: .18), 2.2, 2.6, false, _sp(NeferhooPalette.ink, .022, .8));
    }
    _scarfArt();
    _bareCrease();
    _bareFace();
    if (p.specs) _specsArt();
    _bareBrow();
  }

  void _scarfArt() {
    final g = _geo;
    c.drawPath(g.scarfEnds, _fp(NeferhooPalette.linenLit));
    c.drawPath(g.scarfEnds, _sp(NeferhooPalette.ink, .03));
    c.drawPath(g.scarf, g.scarfFill);
    if (_lod > 0) c.drawPath(g.scarfLines, _sp(NeferhooPalette.linenBand, .03, .9));
    c.drawPath(g.scarf, _sp(NeferhooPalette.ink, .04));
    c.drawPath(g.scarfWrap, g.scarfWrapFill);
    c.drawPath(g.scarfWrap, _sp(NeferhooPalette.ink, .03));
    // the knot where the two ends leave the scarf (m1)
    c.drawPath(g.scarfKnot, _fp(NeferhooPalette.linenLit));
    c.drawPath(g.scarfKnot, _sp(NeferhooPalette.ink, .034));
    c.drawPath(g.scarfKnotFolds, _sp(NeferhooPalette.linenDeep, .026, .9));
  }

  /// The old eye: warm brown, heavy-lidded, with a catchlight.
  void _bareFace() {
    final e = NeferhooLayout.eye + const Offset(.03, .02);
    final shut = math.max(p.lid, p.sleepy).clamp(0.0, 1.0);
    final wide = p.brow.clamp(0.0, 1.0);
    final lod = _lod;
    // under-eye bag and the crow's feet at the outer corner
    if (lod > 0) {
      c.drawArc(Rect.fromCenter(center: e + const Offset(.0, .17), width: .56, height: .26), .35, 2.4, false, _sp(NeferhooPalette.cinnShade, .03, .75));
      for (final a in const [-.35, 0.0, .35]) {
        c.drawLine(e + Offset(math.cos(a) * .30, math.sin(a) * .25 + .02), e + Offset(math.cos(a) * .45, math.sin(a) * .36 + .02), _sp(NeferhooPalette.cinnShade, .022, .85));
      }
    }
    final r = .245 + wide * .025;
    c.drawCircle(e, r, _fp(const Color(0xfffff6e4)));
    final iris = e + Offset(p.look.dx * .05, p.look.dy * .03);
    final ir = .155 - wide * .025;
    c.drawCircle(iris, ir, _fp(NeferhooHeadInk.amber));
    c.drawCircle(iris, ir * .62, _fp(NeferhooHeadInk.obsidian));
    if (lod > 1) c.drawCircle(iris, ir + .006, _sp(const Color(0xffb8c8e0), .014, .5));
    c.drawCircle(iris + Offset(-ir * .40, -ir * .45), ir * .34, _fp(const Color(0xffffffff)));
    c.drawCircle(iris + Offset(ir * .38, ir * .36), ir * .14, _fp(const Color(0xffffffff), .8));
    // the heavy upper lid: a cinnamon crescent that closes with `lid`/`sleepy`
    final cover = (.18 + shut * .82).clamp(0.0, 1.0);
    final lidY = e.dy - r + cover * r * 2 * .98;
    final lid = Path()
      ..moveTo(e.dx - r - .012, e.dy)
      ..arcToPoint(Offset(e.dx + r + .012, e.dy), radius: Radius.circular(r + .012), clockwise: true)
      ..quadraticBezierTo(e.dx, lidY + (cover > .5 ? .0 : .02) + .05 * (1 - cover), e.dx - r - .012, e.dy)
      ..close();
    c.drawPath(lid, _fp(NeferhooPalette.cinn));
    c.drawPath(lid, _geo.bareLidShade);
    if (shut > .02) c.drawPath(Path()..moveTo(e.dx - r, e.dy)..quadraticBezierTo(e.dx, lidY + .06, e.dx + r, e.dy), _sp(NeferhooPalette.ink, .03, .9));
    c.drawCircle(e, r, _sp(NeferhooPalette.ink, .045));
    // a lid crease above the eye
    if (lod > 0) c.drawPath(NeferhooKit.smoothPath([e + const Offset(-.23, -.19), e + const Offset(.0, -.33), e + const Offset(.25, -.22)], close: false), _sp(NeferhooPalette.cinnShade, .028, .8));
  }

  /// A bushy grey brow: it slants down when angry, up when sad.
  void _bareBrow() {
    final e = NeferhooLayout.eye + const Offset(.03, .02);
    final angry = (-p.brow).clamp(0.0, 1.0);
    final wide = p.brow.clamp(0.0, 1.0);
    final sad = _sad;
    final rotate = -angry * .32 + sad * .26;
    final lift = wide * .1 + sad * .03;
    c.save();
    c.translate(e.dx, e.dy - (p.specs && p.specsUp < .5 ? .33 : .30) - lift + angry * .03);
    c.rotate(rotate);
    c.drawPath(_geo.browTufts, _fp(NeferhooHeadInk.whiskerGrey));
    c.drawPath(_geo.browTufts, _sp(NeferhooPalette.ink, .02, .9));
    c.restore();
  }

  void _bareCrease() {
    final smile = p.smile.clamp(0.0, 1.0);
    final sad = _sad;
    final lift = smile * .15 - sad * .06;
    c.drawPath(NeferhooKit.smoothPath([const Offset(-1.60, -1.04), Offset(-1.44, -.92 - lift * .3), Offset(-1.27, -.96 - lift)], close: false), _sp(NeferhooPalette.cinnShade, .04, .9));
    if (smile > .15) {
      c.drawArc(Rect.fromCircle(center: Offset(-1.26, -.99 - lift), radius: .05), -1.3, 2.6, false, _sp(NeferhooPalette.cinnShade, .03, smile));
      c.drawCircle(const Offset(-1.34, -.92), .13, _fp(NeferhooPalette.carnLit, .26 * smile));
    }
  }

  /// Round gold spectacles: lens, rim, bridge to the bill, arm to the ear.
  /// `specsUp` 0..1 pushes them up onto the forehead ("I can see!").
  void _specsArt() {
    final up = p.specsUp.clamp(0.0, 1.0);
    final e0 = NeferhooLayout.eye + const Offset(.03, .02);
    final e = e0 + Offset(.06 * up, -.66 * up);
    final lod = _lod;
    const rl = .335;
    // arm back to the ear, bridge forward to the bill (the bridge lets go of
    // the nose when the lens is up)
    final arm = NeferhooKit.smoothPath([e + const Offset(rl - .01, -.04), Offset.lerp(const Offset(-.80, -1.42), e + const Offset(.62, .05), up)!, Offset.lerp(const Offset(-.78, -1.24), e + const Offset(.7, .12), up)!], close: false);
    c.drawPath(arm, _sp(NeferhooPalette.ink, .06));
    c.drawPath(arm, _sp(NeferhooPalette.goldLit, .026));
    final bridge = NeferhooKit.smoothPath([e + const Offset(-rl + .01, -.06), e + Offset(-rl - .1, -.1 + .1 * up), Offset.lerp(const Offset(-1.64, -1.47), e + const Offset(-rl - .2, -.02), up)!], close: false);
    c.drawPath(bridge, _sp(NeferhooPalette.ink, .06));
    c.drawPath(bridge, _sp(NeferhooPalette.goldLit, .026));
    c.drawCircle(e, rl, _fp(const Color(0xffdff6ff), .22));
    c.drawCircle(e, rl, _sp(NeferhooPalette.ink, .08));
    c.drawCircle(e, rl, _sp(NeferhooPalette.goldLit, .042));
    c.drawArc(Rect.fromCircle(center: e, radius: rl), 3.5, 1.3, false, _sp(NeferhooPalette.goldHi, .02, .9));
    if (lod > 0) {
      // glass: a curved glare and a dot
      c.drawArc(Rect.fromCircle(center: e, radius: rl - .07), 3.7, .95, false, _sp(const Color(0xffffffff), .04, .8));
      c.drawCircle(e + const Offset(.17, -.17), .016, _fp(const Color(0xffffffff), .85));
    }
  }
}
