// Neferhoo's wings, tail and streamers (detail pass `r3-wings`; the joints are
// c2-joints: the wing is under the collar and its coverts, the tail grows from
// linen coverts that cross the body's outline and are tied with a knot that is
// the streamer's root, the far wing has an arm). Polish pass `f3-wings`:
//
//  * M5 the back half is three shapes, not one mass: the wing is the round fan,
//    the TAIL a hoopoe's long, black, nearly square-ended strip with ONE bold
//    white band (5 feathers, 30-40 % narrower spread, 15 % longer, tilted a
//    touch down), and the far wing is held up while the near wing deals, so sky
//    shows between the three at 120 px in every pose, the mail call included.
//  * M4 LOD parity: the same feathers, bars, coverts, cuffs, bow, colours and
//    streamer colours at play and full detail; the full level only adds
//    hairlines (on the white bars), covert shafts, strip shading, frayed
//    threads and a rim light. Nothing appears, disappears or changes tone at
//    60 px/unit (`mummy_f3_test.dart` "pop numbers").
//  * m2 the wrist cuffs are bandage, not label: wound DIAGONALLY across the arm
//    (two overlapping strips bowed with the bone), 25 % smaller, a smaller bow;
//    the far cuff is `linenDeep` at 60 % along the arm; the rim light stays
//    inside the wing and stops at the cuff.
//  * m3 one line language: ink between feathers; lilac hairlines only on white
//    bars (alpha .45, .012 u), never on the black plumage.
//  * m7 the cinnamon coverts are feathers, not fish scales: lobe depth by row
//    (x1.10 / x1.0 / x.90), chord and depth jitter per tip, apexes leaning
//    outward, seams only where the next row leaves them visible, and a short
//    two-line shaft on every tip of the leading row at the full level.
//
// References behind the drawing:
//  * Hoopoe (Upupa epops): broad, ROUNDED wings, black with white bars that
//    cross the feathers in rows: a cinnamon-buff shoulder (lesser coverts), a
//    thin cream bar (the greater coverts' tips), two white bars across the
//    secondaries, one broad white band across the primaries with black
//    fingertips; the tail is LONG, black and nearly square-ended with ONE broad
//    white band; the flight is a "giant butterfly": the wings half-close at the
//    end of each beat.
//  * Feather anatomy: ten primaries on the hand (outermost short, the next
//    longest, then stepping down), secondaries along the forearm with rounded
//    tips, rows of coverts in scallops over their bases, an alula (the
//    thumb-feather) on the leading edge at the wrist, pale shafts.
//  * Egyptian wings (Nekhbet, Isis, the ba-bird) are drawn in tiers: scale-like
//    coverts on top, then a row of covert feathers, then long parallel flight
//    feathers with rounded ends: the same tiers read here.
//  * Linen: wrapped strips overlap diagonally; a cut strip frays into parallel
//    warp threads at its end; a twisted strip shows its lit face, then a thin
//    pinch, then its shaded back.
//
// Everything is a pure function of the pose (`wing`, `reach`, `sweep`,
// `fury`, `hit`, `unwrap`, `phase`, `lean`, `glow`, `ribbons`). Static
// geometry is built once; per-frame paths are scratch `Path`s that are reset
// and refilled; no layers, no blurs, no clips, loops bounded by constants.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';
import 'neferhoo_rig.dart';


// ---------------------------------------------------------------------------
// local paint helpers (the rig's own are library-private)

Paint _fl(Color c, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
Paint _ln(Color c, double w, [double a = 1]) => Paint()
  ..isAntiAlias = true
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
Paint _sh(Shader s) => Paint()
  ..isAntiAlias = true
  ..shader = s;
Shader _lg(Offset a, Offset b, List<Color> cs, [List<double>? st]) => ui.Gradient.linear(a, b, cs, st);

/// The colours this pass adds (the rig's `Mu` is not mine to change). The
/// wing and tail plumage is drawn with the rig's own `NeferhooPalette.barWhite` bars and the
/// shared plum gradients below, at every size.
abstract final class NeferhooWingInk {
  // the greater coverts' tips: a cream, not the bars' white
  static const cream = NeferhooPalette.papyrus;
  // the lilac of the full level's hairlines (white bars only) and the sun's rim
  static const shaft = NeferhooPalette.linenBand;
  static const rim = NeferhooPalette.rim;
}

// ---------------------------------------------------------------------------
// the feather: a leaf along a (curved) centreline

const _sa = <double>[0, .1, .26, .48, .70, .85, .94, 1];
const _pfWing = <double>[.30, .66, .94, 1.0, .96, .84, .54, 0];
const _pfFinger = <double>[.30, .60, .86, .92, .84, .64, .40, 0];
const _pfTail = <double>[.55, .80, .97, 1.0, 1.0, .96, .74, 0];

double _pfAt(List<double> pf, double a) {
  for (var i = 1; i < _sa.length; i++) {
    if (a <= _sa[i]) {
      final t = (a - _sa[i - 1]) / (_sa[i] - _sa[i - 1]);
      return pf[i - 1] + (pf[i] - pf[i - 1]) * t;
    }
  }
  return pf.last;
}

Offset _ctr(Offset b, double ang, double len, double bow, double a) {
  final d = Offset(math.cos(ang), math.sin(ang));
  final n = Offset(-d.dy, d.dx);
  return b + d * (len * a) + n * (bow * len * a * a);
}

Offset _nor(double ang, double bow, double a) {
  final d = Offset(math.cos(ang), math.sin(ang));
  final n = Offset(-d.dy, d.dx);
  final t = d + n * (2 * bow * a);
  return Offset(-t.dy, t.dx) / t.distance;
}

/// Catmull-Rom through [q] as cubics (open).
void _spline(Path p, List<Offset> q, {bool move = true}) {
  if (move) p.moveTo(q[0].dx, q[0].dy);
  final n = q.length;
  for (var i = 0; i < n - 1; i++) {
    final p0 = q[i == 0 ? 0 : i - 1], p1 = q[i], p2 = q[i + 1], p3 = q[i + 2 >= n ? n - 1 : i + 2];
    final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
    p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
}

/// A feather (or the slice [a0]..[a1] of one: a bar) of width [w] on the
/// centreline from [b] along [ang] for [len], bowed by [bow] (a share of the
/// length at the tip), with the half-width profile [pf].
void _leaf(Path out, Offset b, double ang, double len, double w, double bow, List<double> pf, {double a0 = 0, double a1 = 1}) {
  final st = <double>[a0, for (final a in _sa) if (a > a0 + .03 && a < a1 - .03) a, a1];
  final l = <Offset>[], r = <Offset>[];
  for (final a in st) {
    final c = _ctr(b, ang, len, bow, a);
    final n = _nor(ang, bow, a);
    final hw = w / 2 * _pfAt(pf, a);
    l.add(c + n * hw);
    r.add(c - n * hw);
  }
  if (a1 >= .999) {
    _spline(out, [...l, ...r.reversed.skip(1)]);
    out.close();
  } else {
    _spline(out, l);
    final rr = r.reversed.toList();
    out.lineTo(rr[0].dx, rr[0].dy);
    _spline(out, rr, move: false);
    out.close();
  }
}

/// The bar [a0]..[a1] across a feather: its cuts are arcs that bulge toward
/// the tip by [bulge] (a share of the length), like the bars on real feathers
/// that follow the rounded tip.
void _bar(Path out, Offset b, double ang, double len, double w, double bow, List<double> pf, double a0, double a1, double bulge) {
  Offset at(double a, double v) => _ctr(b, ang, len, bow, a) + _nor(ang, bow, a) * (v * w / 2 * _pfAt(pf, a));
  List<Offset> cut(double ac) => [
    for (final v in const [-1.0, -.5, 0.0, .5, 1.0]) at((ac + bulge * (1 - v * v)).clamp(0.0, .985), v),
  ];
  final c0 = cut(a0), c1 = cut(a1);
  final inner = [for (final a in _sa) if (a > a0 + .03 && a < a1 - .03) a];
  final l = [c0.first, for (final a in inner) at(a, -1), c1.first];
  final r = [c1.last, for (final a in inner.reversed) at(a, 1), c0.last];
  _spline(out, l);
  _spline(out, c1, move: false);
  _spline(out, r, move: false);
  _spline(out, c0.reversed.toList(), move: false);
  out.close();
}

/// The visible edge of a shingled feather: the [side] (+1 = +n) from [a0]
/// to the tip, round the tip and back along the other side to [back].
void _edge(Path out, Offset b, double ang, double len, double w, double bow, List<double> pf, double side, {double a0 = .28, double back = .88}) {
  final pts = <Offset>[];
  Offset at(double a, double sd) => _ctr(b, ang, len, bow, a) + _nor(ang, bow, a) * (sd * w / 2 * _pfAt(pf, a));
  pts.add(at(a0, side));
  for (final a in _sa) {
    if (a > a0 + .03) pts.add(at(a, side));
  }
  for (var i = _sa.length - 2; i >= 0; i--) {
    if (_sa[i] >= back) pts.add(at(_sa[i], -side));
  }
  _spline(out, pts);
}

void _shaft(Path out, Offset b, double ang, double len, double bow, double a0, double a1) {
  final p0 = _ctr(b, ang, len, bow, a0), p1 = _ctr(b, ang, len, bow, a1);
  final d = Offset(math.cos(ang), math.sin(ang));
  final n = Offset(-d.dy, d.dx);
  final ctrl = p0 + (d * len + n * (2 * bow * len * a0)) * ((a1 - a0) / 2);
  out.moveTo(p0.dx, p0.dy);
  out.quadraticBezierTo(ctrl.dx, ctrl.dy, p1.dx, p1.dy);
}

Offset _lerpAt(List<Offset> l, double x) {
  final i = x.floor().clamp(0, l.length - 2);
  return Offset.lerp(l[i], l[i + 1], x - i)!;
}

/// The point at [t] (0..1) along the polyline [line].
Offset _alongLine(List<Offset> line, double t) {
  final x = t.clamp(0.0, 1.0) * (line.length - 1);
  final i = x.floor().clamp(0, line.length - 2);
  return Offset.lerp(line[i], line[i + 1], x - i)!;
}

/// [n] chord positions along a row (0..1), each chord +-14 % of an even share,
/// so no two covert tips are the same width (m7: fish scales are uniform).
List<double> _chordsAt(int n, int seed) {
  final w = [for (var i = 0; i < n; i++) 1 + .14 * math.sin(seed * 2.9 + i * 2.17 + i * i * .31)];
  final s = w.fold(0.0, (a, b) => a + b);
  var acc = 0.0;
  return [0.0, for (final x in w) acc += x / s];
}

/// A row of feather tips along [line]: round lobes bulging to +y by [amp]
/// (+-12 % per tip, apex leaning toward the wing tip), at the chord positions
/// [ts]. Records each junction and each lobe's apex.
void _scallops(Path p, List<Offset> line, List<double> ts, double amp, int seed, {bool move = true, double jit = .12, List<Offset>? junctions, List<Offset>? apexes}) {
  var prev = _alongLine(line, ts.first);
  if (move) p.moveTo(prev.dx, prev.dy);
  junctions?.add(prev);
  for (var i = 1; i < ts.length; i++) {
    final next = _alongLine(line, ts[i]);
    final ch = next - prev;
    var nn = Offset(-ch.dy, ch.dx) / ch.distance;
    if (nn.dy < 0) nn = -nn;
    final h = amp * (1 + jit * math.sin(seed * 1.7 + i * 3.1 + 1.0));
    final lean = jit == 0 ? 0.0 : .07 * math.sin(seed + i * 1.9);
    final c1 = prev + ch * (.10 + lean) + nn * (h * 4 / 3);
    final c2 = next - ch * (.10 - lean) + nn * (h * 4 / 3);
    p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, next.dx, next.dy);
    apexes?.add((prev + next) / 2 + nn * h + ch * lean * .5);
    junctions?.add(next);
    prev = next;
  }
}

/// The y of the lowest point of the (static) scalloped [hem] at wing-frame [x],
/// by sampling the path (null if the hem does not reach [x]).
double? _hemLow(Path hem, double x) {
  double? low;
  for (final m in hem.computeMetrics()) {
    for (var d = 0.0; d <= m.length; d += .012) {
      final q = m.getTangentForOffset(d)!.position;
      if ((q.dx - x).abs() < .014 && (low == null || q.dy > low)) low = q.dy;
    }
  }
  return low;
}

/// The slice [a0]..[a1] of a feather's visible edge on the [side] (+1 = +n):
/// the lilac hairline of a white bar (full detail only).
void _edgeSeg(Path out, Offset b, double ang, double len, double w, double bow, List<double> pf, double side, double a0, double a1) {
  Offset at(double a) => _ctr(b, ang, len, bow, a) + _nor(ang, bow, a) * (side * w / 2 * _pfAt(pf, a));
  final pts = <Offset>[at(a0), for (final a in _sa) if (a > a0 + .03 && a < a1 - .03) at(a), at(a1)];
  _spline(out, pts);
}

// ---------------------------------------------------------------------------
// the wing's layout (wing frame: root at the shoulder, +x outward, -y the
// leading edge; drawn under a .92 / .78 scale)

// primaries: outermost (leading edge) first. Bases step along the hand.
const _priB = <Offset>[Offset(1.58, -.46), Offset(1.48, -.46), Offset(1.38, -.47), Offset(1.28, -.48), Offset(1.18, -.50), Offset(1.08, -.50), Offset(.98, -.50)];
const _priT = <Offset>[Offset(2.08, -.52), Offset(2.28, -.27), Offset(2.36, .03), Offset(2.29, .33), Offset(2.11, .58), Offset(1.87, .73), Offset(1.59, .78)];
// secondaries: from the wrist inward
const _secB = <Offset>[Offset(.90, -.46), Offset(.76, -.42), Offset(.62, -.36), Offset(.48, -.28), Offset(.34, -.20), Offset(.20, -.12)];
const _secT = <Offset>[Offset(1.33, .77), Offset(1.06, .75), Offset(.80, .68), Offset(.57, .58), Offset(.36, .46), Offset(.16, .34)];

// the covert panel (leading edge, lesser/median coverts, greater coverts)
const _lead = <Offset>[Offset(-.06, -.05), Offset(.16, -.32), Offset(.50, -.52), Offset(.92, -.65), Offset(1.34, -.70), Offset(1.70, -.60)];
const _l1 = <Offset>[Offset(1.68, -.24), Offset(1.28, -.08), Offset(.90, .06), Offset(.54, .18), Offset(.24, .26), Offset(-.04, .28)];

/// The leading edge's height at wing-frame [x] (piecewise linear through [_lead]).
Offset _leadAt(double x) {
  for (var i = 0; i < _lead.length - 1; i++) {
    if (x <= _lead[i + 1].dx) {
      return Offset.lerp(_lead[i], _lead[i + 1], ((x - _lead[i].dx) / (_lead[i + 1].dx - _lead[i].dx)).clamp(0.0, 1.0))!;
    }
  }
  return _lead.last;
}

// the lesser coverts: three rows of cinnamon feather tips, listed wrist first;
// each row ends under the next and its root goes under the shoulder wrap
const _hem1 = <Offset>[Offset(.90, -.30), Offset(.70, -.18), Offset(.50, -.04), Offset(.32, .07), Offset(.14, .13), Offset(-.04, .17)];
const _hem2 = <Offset>[Offset(.84, -.43), Offset(.66, -.32), Offset(.48, -.18), Offset(.30, -.04), Offset(.12, .07), Offset(-.04, .10)];
const _hem3 = <Offset>[Offset(.78, -.56), Offset(.62, -.47), Offset(.46, -.35), Offset(.30, -.22), Offset(.14, -.10), Offset(-.04, -.04)];
// rows of 4, 5 and 4 round tips (the junctions of one row fall between the
// next row's, so they read as overlapping feathers). m7: the tips differ by
// row (lobe depth x1.10 next to the flight feathers, x1.0, x.90 on the leading
// edge) and by tip (chord +-14 %, depth +-12 %, apex leaning outward), so they
// are not a fish-scale pattern; the leading row gets a short two-line shaft on
// every tip at the full level.
const _rowN = <int>[4, 5, 4];
const _rowAmp = <double>[.115, .10, .09];

/// The covert rows' static drawing: fills, hems, seams, shafts.
class _Covert {
  _Covert._(this.cinn, this.hem, this.linesPlay, this.linesFull);
  final List<Path> cinn, hem;
  final Path linesPlay, linesFull;

  factory _Covert.build() {
    final hems = const [_hem1, _hem2, _hem3];
    final cinn = <Path>[], hem = <Path>[];
    final junc = <List<Offset>>[], apex = <List<Offset>>[];
    for (var r = 0; r < 3; r++) {
      final h = hems[r];
      final line = h.reversed.toList();
      final ts = _chordsAt(_rowN[r], 11 + r * 5);
      final j = <Offset>[], a = <Offset>[];
      final hp = Path();
      _scallops(hp, line, ts, _rowAmp[r], 3 + r, junctions: j, apexes: a);
      hem.add(hp);
      junc.add(j);
      apex.add(a);
      // the row's fill: the leading edge from the wrist back to the root, then the hem out again
      final wrist = h.first, root = h.last;
      final p = Path();
      final top = <Offset>[for (var x = wrist.dx; x > root.dx; x -= .12) _leadAt(x) + const Offset(0, .035), _leadAt(root.dx) + const Offset(0, .035)];
      p.moveTo(top.first.dx, top.first.dy);
      for (final q in top.skip(1)) {
        p.lineTo(q.dx, q.dy);
      }
      p.lineTo(root.dx, root.dy);
      _scallops(p, line, ts, _rowAmp[r], 3 + r, move: false);
      p.quadraticBezierTo(wrist.dx + .09, (wrist.dy + top.first.dy) / 2, top.first.dx, top.first.dy);
      p.close();
      cinn.add(p);
    }
    // hems + seams: ONE stroke. A seam rises from a junction only as far as the
    // next row's lobe leaves it visible (the stroke is drawn after every fill)
    final lp = Path();
    for (var r = 0; r < 3; r++) {
      lp.addPath(hem[r], Offset.zero);
      for (var i = 1; i < _rowN[r]; i++) {
        final q = junc[r][i];
        var len = r == 2 ? .10 : .085;
        if (r < 2) {
          final low = _hemLow(hem[r + 1], q.dx + .015);
          if (low != null) len = math.min(len, q.dy - low - .02);
        }
        if (len < .03) continue;
        lp.moveTo(q.dx, q.dy);
        lp.lineTo(q.dx + .03 * len / .11, q.dy - len);
      }
    }
    final lf = Path()..addPath(lp, Offset.zero);
    for (final a in apex[2]) {
      lf.moveTo(a.dx + .004, a.dy - .035);
      lf.lineTo(a.dx - .008, a.dy - .125);
      lf.moveTo(a.dx + .004, a.dy - .035);
      lf.lineTo(a.dx + .018, a.dy - .125);
    }
    return _Covert._(cinn, hem, lp, lf);
  }
}

// ---- the wrist bands (wing frame): a band across the arm, centre [c], half
// length [hl] along the wrap direction [dAng], half width [hw] along the bone
// [aAng], bowed [bow] toward the wing tip so its edges follow the arm ----

Offset _bandPt(Offset c, double dAng, double aAng, double hl, double hw, double bow, double u, double v) {
  final d = Offset(math.cos(dAng), math.sin(dAng)), a = Offset(math.cos(aAng), math.sin(aAng));
  return c + d * (u * hl) + a * (v * hw + bow * (1 - u * u));
}

/// One strip of a wound band: rounded, bowed with the arm, spanning [v0]..[v1]
/// along the bone and [u0]..[u1] across it.
Path _strip(Offset c, double dAng, double aAng, double hl, double hw, double bow, double v0, double v1, double u0, double u1) {
  Offset at(double u, double v) => _bandPt(c, dAng, aAng, hl, hw, bow, u, v);
  final um = (u0 + u1) / 2, vm = (v0 + v1) / 2;
  return NeferhooKit.smoothPath([
    at(u0, v1),
    at(um, v1),
    at(u1, v1),
    at(u1 + .06, vm),
    at(u1, v0),
    at(um, v0),
    at(u0, v0),
    at(u0 - .06, vm),
  ], k: 1 / 6);
}

double _lerpD(double a, double b, double t) => a + (b - a) * t;

/// Wings, tail and streamers, as methods of the rig's painter.
extension NeferhooWingArt on NeferhooPainter {
  // ---- cached geometry and shaders (built once) -------------------------

  static final List<double> _ts6 = _chordsAt(6, 9);
  static final Path _panelBlack = _mkPanel();
  static final Path _coverTips = _mkCoverTips();
  static final _Covert _cov = _Covert.build();
  static final Path _leadRim = _mkLeadRim();

  /// The covert panel, wound the same way as every feather (so overlapping
  /// fills never cancel under the non-zero rule): the lower scalloped edge
  /// from the root out to the wrist, then back along the leading edge.
  static Path _mkPanel() {
    final p = Path();
    _scallops(p, _l1.reversed.toList(), [for (final t in _ts6.reversed) 1 - t], .06, 9, jit: 0);
    p.lineTo(_lead.last.dx, _lead.last.dy);
    _spline(p, _lead.reversed.toList(), move: false);
    p.quadraticBezierTo(-.16, .02, _l1.last.dx, _l1.last.dy);
    p.close();
    return p;
  }

  static Path _mkCoverTips() {
    // the greater coverts' tips: a scalloped cream bar (chords vary, tips do not match)
    final p = Path();
    _scallops(p, _l1, _ts6, .06, 9, jit: 0);
    final up = [for (final q in _l1.reversed) q + const Offset(0, -.095)];
    p.lineTo(up[0].dx, up[0].dy);
    _scallops(p, up, [for (final t in _ts6.reversed) 1 - t], .05, 9, move: false, jit: 0);
    p.close();
    return p;
  }

  /// The sun's rim on the covert panel's leading edge, INSIDE the wing: from
  /// the root to the wrist cuff only (it used to run on over the cuff and the
  /// hand and float outside the feathers).
  static Path _mkLeadRim() {
    final p = Path();
    _spline(p, [for (final q in _lead.take(4)) q + const Offset(.01, .075)]);
    return p;
  }

  // PLAY and FULL share every colour (nothing changes tone at the switch):
  // lighter plum with PURE white bars; the far wing one step down so it stays a
  // wing and not a black paddle
  static final Shader _nearBlack = _lg(const Offset(.3, -.75), const Offset(.9, .85), const [Color(0xff6a5b8c), Color(0xff43375f), Color(0xff2e2543)], const [0, .45, 1]);
  static final Shader _farBlack = _lg(const Offset(.3, -.75), const Offset(.9, .85), const [Color(0xff54476f), Color(0xff382d52), Color(0xff271f3a)], const [0, .45, 1]);
  static final Shader _tailBlack = _lg(const Offset(1.4, -.8), const Offset(2.5, .9), const [Color(0xff74688f), Color(0xff55496f), Color(0xff40365a)], const [0, .5, 1]); // the tail's black lifted toward the plume's light (it was the loudest contrast on the figure)
  static final Path _panelFar = _panelBlack.transform(_squashY);
  static final Path _farCinn = _cov.cinn[1].transform(_squashY);
  static final Path _farHem = _cov.hem[1].transform(_squashY);
  static final Float64List _squashY = Float64List.fromList(const [1, 0, 0, 0, 0, .70, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

  // ---- the wrist bandage (wing frame): a band wound DIAGONALLY across the arm,
  // its edges following the bone's curve (not a label laid flat on it) ----
  // the bone runs along the leading edge (angle -.31); the wrap's edges are
  // about 30 degrees off the bone's perpendicular, curving with the arm
  static const _boneAng = -.31, _wrapAng = 2.0;
  // (three strips, each a little longer than the last, so the ends step like
  // a wound bandage; the union is the cuff)
  static final List<Path> _nearStrips = [
    _strip(const Offset(1.26, -.38), _wrapAng, _boneAng, .31, .170, .035, -1.0, .14, -.95, .80),
    _strip(const Offset(1.26, -.38), _wrapAng, _boneAng, .31, .170, .035, -.14, 1.0, -.80, .98),
  ];
  static final Path _nearBand = Path()..addPath(_nearStrips[0], Offset.zero)..addPath(_nearStrips[1], Offset.zero);
  static final Path _farBand = _strip(const Offset(1.24, -.27), _wrapAng, _boneAng, .225, .095, .03, -1.0, 1.0, -.97, .97);
  static const _bowAt = Offset(1.185, -.10);

  /// The near cuff's outline (wing frame), for the review harness (its area).
  static Path get cuffOutline => _nearBand; // the knot, under the band's lower end
  static final Shader _cuffShade = _lg(const Offset(1.4, -.7), const Offset(1.1, -.1), [NeferhooPalette.linenDeep.withValues(alpha: 0), NeferhooPalette.linenDeep.withValues(alpha: .45)], const [.2, 1]);
  static final Shader _halo = ui.Gradient.radial(Offset.zero, 1, [NeferhooPalette.magic.withValues(alpha: .55), NeferhooPalette.magic.withValues(alpha: .18), NeferhooPalette.magic.withValues(alpha: 0)], const [0, .45, 1]);

  // ---- scratch paths (reset and refilled every call) ---------------------

  // ---- the buff gag (review 08 M4; `p.buff`) ------------------------------
  //
  // The near wing swings to the chest postmark and folds its hand into one
  // narrow tip, which wipes the pad to and fro twice (`buff` is the weight of
  // the whole gag, 0..1; the wipe itself is `sin(2 pi wipeHz phase)`, so the body
  // can time the pad's squeak to it).

  /// Wipes per second of `phase` (two wipes = 2/3 s of full buff).
  static const wipeHz = 3.0;

  /// The pad's centre (rig units) the wingtip is aimed at, and how far a wipe
  /// carries it either side (horizontally).
  static const _buffPad = Offset(-.55, .34), _wipeSpan = .38;

  /// The folded hand's tip, in wing-frame units from the shoulder.
  static const _tipReach = 2.50;

  /// The direction the folded primaries and secondaries lie in (wing frame).
  static const _tuckAngP = .02, _tuckAngS = .10;

  /// The wipe's position, -1..1, at full buff (0 as the gag arrives and leaves).
  double buffWipe() => math.sin(2 * math.pi * wipeHz * p.phase) * NeferhooKit.smooth01((p.buff - .55) / .35);

  static final Path _swish = Path();

  /// The wipe's trail: two short arcs behind the wingtip, on the side it came
  /// from (one stroke, only while the wing is moving across the pad).
  void _buffSwish(Offset tip) {
    final speed = math.cos(2 * math.pi * wipeHz * p.phase) * NeferhooKit.smooth01((p.buff - .55) / .35);
    if (speed.abs() < .3) return;
    final back = speed > 0 ? -1.0 : 1.0; // (the wing moves toward +x while the wipe's velocity is positive)
    _swish.reset();
    for (final dy in const [-.13, .05]) {
      final a = tip + Offset(back * .22, dy), b = tip + Offset(back * .54, dy + .03);
      _swish
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, a.dy - .035, b.dx, b.dy);
    }
    c.drawPath(_swish, _ln(NeferhooPalette.ink, .034, .6 * speed.abs()));
  }

  /// The idle beat's phase-lagged wave `sin(theta - lag)` (theta the wingbeat's
  /// angle): the tail and the streamers wag with the wing. A pose that carries
  /// the wing's real velocity (`wingRate`, as the fight's timeline does) gets
  /// the same wave built from the wing channel's position and velocity, so the
  /// lag is continuous through every held pose, swing and whip; a pose without
  /// one follows the idle beat from `phase`.
  double _lagWave(double lag) {
    if (p.wingRate == null) return math.sin(p.phase * NeferhooPose.wingBeat - lag);
    final x = (p.wing / .55).clamp(-1.5, 1.5);
    return x * math.cos(lag) - p.stroke * math.sin(lag);
  }

  static final Path _black = Path(), _white = Path(), _edges = Path(), _hair = Path();
  static final Path _cuffP = Path(), _frays = Path(), _fraysMagic = Path();

  // =========================================================================
  // the wing

  /// One wing: [near] the lit one over the body, else the dark far one.
  /// [angle] is the rig's stroke angle for the near wing.
  ///
  /// PLAY and FULL are ONE drawing: the same feathers, bars, coverts, cuffs and
  /// colours at every size; the full level only adds hairlines (on the white
  /// bars), shafts on the leading covert row, strip shading and frayed threads.
  void wingArtWing({required bool near, required double angle}) {
    final root = near ? NeferhooLayout.shoulder : NeferhooLayout.farShoulder;
    final grip = near ? NeferhooKit.smooth01(p.reach) : 0.0;
    // buffing the pad (M4): the swing to the chest, the hand folded to a tip
    final gb = near ? NeferhooKit.smooth01(p.buff) * (1 - grip) : 0.0;
    // the far wing follows only a third of a flick; while the near wing deals
    // (reach) it is held UP, so the reaching hand, the far wing and the tail
    // are three shapes with sky between them (M5), not one lump
    final base = near ? angle : angle - .32 - _farLift * NeferhooKit.smooth01(p.reach);
    var rotA = base, roll = 1.0, buffScale = 0.0;
    if (grip > 0) {
      // reaching: the wing swings down and forward to the deal point and
      // ROLLS over its own axis on the way (edge-on at mid-swing), so its
      // leading edge is on top again when it holds the letters
      final fan = fanPoint;
      var t = math.atan2(fan.dy - NeferhooLayout.shoulder.dy, fan.dx - NeferhooLayout.shoulder.dx);
      // (which way round the swing goes is decided from the wing's own angle, not
      // from the flick on top of it: the flick fades while the hand comes home, and
      // the swing used to flip over the top mid-way)
      if (t - (base + (near ? p.sweep * .9 : 0)) > math.pi) t -= 2 * math.pi;
      rotA = base + (t - base) * grip;
      roll = math.cos(math.pi * grip);
      if (roll.abs() < .1) roll = roll < 0 ? -.1 : .1;
    } else if (gb > 0) {
      // the wingtip's path: from its rest to the pad, then to and fro across it
      final tgt = _buffPad + Offset(_wipeSpan * buffWipe(), 0);
      final d = tgt - NeferhooLayout.shoulder;
      final t = math.atan2(d.dy, d.dx);
      rotA = base + (t - base) * gb;
      buffScale = d.distance / _tipReach;
      roll = math.cos(math.pi * gb);
      if (roll.abs() < .1) roll = roll < 0 ? -.1 : .1;
    }
    // reaching, the near wing is a smaller hand (it must not bury the chest)
    final sc = near ? _lerpD(.92 * (1 - .36 * grip), buffScale, gb) : .78;

    final w = p.wing;
    final raise = (-w).clamp(0.0, 1.0);
    // the hoopoe's butterfly beat: the wing half-closes at the end of a stroke
    final fold = NeferhooKit.smooth01((w - .25) / .75) * .35;
    final splay = .92 + .20 * raise + .26 * p.fury + .30 * p.hit + .28 * p.sweep + .85 * grip - .45 * fold - .3 * gb;
    // tips trail the stroke: `stroke` is the wing's velocity (cos of the idle
    // beat unless the timeline holds the pose: wingRate 0)
    final lag = -p.stroke * .10 * (1 - math.max(grip, gb)) + p.sweep * .10;
    final tuck = .82 * gb; // the hand folds to one narrow tip while it buffs
    final flut = .016 * (1 + 2.2 * p.fury + p.hit);
    final pf = grip > .02 ? [for (var i = 0; i < 8; i++) _pfWing[i] + (_pfFinger[i] - _pfWing[i]) * grip] : _pfWing;

    _black.reset();
    _white.reset();
    _edges.reset();
    _hair.reset();
    final pl = play;
    // fewer, narrower feathers so the fingers read as separate tips with sky
    // between them (the approved notched silhouette); the same at every size
    final nP = near ? 6 : 5, nS = near ? 5 : 3;
    final pw = (near ? .34 : .40) * (1 - .18 * grip);
    final sw = near ? .36 : .44;
    // a white bar and, at the full level, its hairlines (lilac, only on white)
    void bar(Offset b, double ang, double len, double wd, double bow, List<double> pfx, double a0, double a1, double bulge) {
      _bar(_white, b, ang, len, wd, bow, pfx, a0, a1, bulge);
      if (!pl) {
        _shaft(_hair, b, ang, len, bow, a0 + .02, a1 - .02);
        _edgeSeg(_hair, b, ang, len, wd, bow, pfx, 1, a0, a1);
      }
    }

    for (var i = 0; i < nP; i++) {
      final fi = i * 6 / (nP - 1);
      final b = _lerpAt(_priB, fi), t = _lerpAt(_priT, fi);
      final d = t - b;
      final k = fi - 3;
      var ang = math.atan2(d.dy, d.dx) + k * (splay - 1) * .09 + math.sin(p.phase * 8.3 + fi * 1.7) * flut;
      if (tuck > 0) ang += (_tuckAngP + k * .035 - ang) * tuck;
      final len = d.distance * (1 - .06 * fold + .015 * raise);
      final bow = lag * (.35 + .65 * fi / 6) - grip * .30 * (.4 + .6 * fi / 6);
      _leaf(_black, b, ang, len, pw, bow, pf);
      if (fi > .5) {
        // two white bars across the long primaries, black between and at the tip
        bar(b, ang, len, pw, bow, pf, .29, .47, .05);
        bar(b, ang, len, pw, bow, pf, .57, .75, .05);
      }
      _edge(_edges, b, ang, len, pw, bow, pf, 1, a0: .5);
    }
    for (var j = 0; j < nS; j++) {
      final fj = j * 5 / (nS - 1);
      final b = _lerpAt(_secB, fj), t = _lerpAt(_secT, fj);
      final d = t - b;
      var ang = math.atan2(d.dy, d.dx) + (fj - 2.5) * (splay - 1) * .03 + math.sin(p.phase * 7.1 + fj * 2.3) * flut * .8;
      if (tuck > 0) ang += (_tuckAngS + (fj - 2.5) * .03 - ang) * tuck;
      final len = d.distance * (1 - .05 * fold);
      final bow = lag * .35 * (1 - fj / 8);
      _leaf(_black, b, ang, len, sw, bow, _pfWing);
      // two bold bars across the secondaries
      bar(b, ang, len, sw, bow, _pfWing, .21, .39, .045);
      bar(b, ang, len, sw, bow, _pfWing, .51, .69, .045);
      _edge(_edges, b, ang, len, sw, bow, _pfWing, 1, a0: .5);
    }
    if (near) {
      // the alula, the thumb-feather on the leading edge at the wrist: it
      // lifts a little in the wind and juts out when the wing grips
      final thumb = -.5 - .45 * grip - .05 * lag * 6;
      const tb = Offset(1.26, -.64);
      _leaf(_black, tb, thumb, .40, .15, 0, _pfWing);
      _leaf(_black, tb + const Offset(.04, .02), thumb + .28, .30, .13, 0, _pfWing);
      _edge(_edges, tb, thumb, .40, .15, 0, _pfWing, 1, a0: .2);
      _edge(_edges, tb + const Offset(.04, .02), thumb + .28, .30, .13, 0, _pfWing, 1, a0: .2);
    }
    // (the far wing has its arm too, slimmer: without it the hand's feathers float)
    _black.addPath(near ? _panelBlack : _panelFar, Offset.zero);

    c.save();
    c.translate(root.dx, root.dy);
    c.rotate(rotA);
    c.scale(sc, sc * roll);
    if (silhouette) {
      c.drawPath(_black, f(NeferhooPalette.ink));
      if (near) {
        _nearCuff(grip);
      } else {
        c.drawPath(_farBand, f(NeferhooPalette.ink));
      }
      c.restore();
      return;
    }
    c.drawPath(_black, _ln(NeferhooPalette.ink, near ? .15 : .11));
    c.drawPath(_black, _sh(near ? _nearBlack : _farBlack));
    c.drawPath(_white, _fl(NeferhooPalette.barWhite));
    if (near) {
      // dark separation lines along the feather tips (not lilac: that fogged the black)
      c.drawPath(_edges, _ln(NeferhooPalette.ink, .035, .85));
      if (!pl) c.drawPath(_hair, _ln(NeferhooWingInk.shaft, .012, .45));
      _coverts();
      if (!pl) c.drawPath(_leadRim, _ln(NeferhooWingInk.rim, .04, .5));
      _nearCuff(grip);
    } else {
      // the far wing's arm: one row of dark cinnamon coverts, its hem inked with the edges
      c.drawPath(_farCinn, _fl(const Color(0xffa05f3c)));
      _edges.addPath(_farHem, Offset.zero);
      c.drawPath(_edges, _ln(NeferhooPalette.ink, .035, .85));
      if (!pl) c.drawPath(_hair, _ln(NeferhooWingInk.shaft, .012, .45));
      _farCuff();
    }
    c.restore();
    if (gb > 0.5) _buffSwish(_buffPad + Offset(_wipeSpan * buffWipe(), 0));
  }

  /// The arm's coverts, in the wing frame: the cream greater-covert tips under
  /// three rows of cinnamon feather tips that run under the shoulder wrap. The
  /// hems and the seams are ONE stroke; the full level adds the leading row's
  /// shafts.
  void _coverts() {
    c.drawPath(_coverTips, _fl(NeferhooWingInk.cream));
    if (!play) c.drawPath(_coverTips, _ln(NeferhooPalette.ink, .022, .65));
    c.drawPath(_cov.cinn[0], _fl(Color.lerp(NeferhooPalette.cinn, NeferhooPalette.cinnShade, .45)!));
    c.drawPath(_cov.cinn[1], _fl(NeferhooPalette.cinn));
    c.drawPath(_cov.cinn[2], _fl(Color.lerp(NeferhooPalette.cinn, NeferhooPalette.cinnLit, .55)!));
    c.drawPath(play ? _cov.linesPlay : _cov.linesFull, _ln(NeferhooPalette.cinnShade, .026, .9));
  }

  // ---- the linen on the wing: wrist cuff, bow and loose ends ----

  /// The far wing's cuff: the same band in shade, rounded along the arm,
  /// `linenDeep` at 60 % so it sits on the plum as faded linen, not as a patch.
  void _farCuff() {
    c.drawPath(_farBand, _fl(NeferhooPalette.linenDeep, .6));
    if (play) return;
    c.drawPath(_farBand, _ln(NeferhooPalette.linenBand, .02, .45));
  }

  /// A loose strip: from [o] along [ang], [len] long, [w] wide at the root,
  /// rippling with [ph]; at the full level its end frays into threads.
  void _tailStrip(Path fill, Offset o, double ang, double len, double w, double ph, double sway) {
    final d = Offset(math.cos(ang), math.sin(ang));
    final nn = Offset(-d.dy, d.dx);
    final l = <Offset>[], r = <Offset>[];
    Offset centre(double t) => o + d * (len * t) + nn * (math.sin(t * 4.2 - ph) * sway * t + sway * 1.2 * t * t);
    for (var k = 0; k <= 6; k++) {
      final t = k / 6;
      final q = centre(t);
      final q2 = centre(math.min(1.0, t + .04)), q1 = centre(math.max(0.0, t - .04));
      final tg = q2 - q1;
      final nrm = Offset(-tg.dy, tg.dx) / tg.distance;
      final hw = w / 2 * (1 - .35 * t) * (.7 + .3 * math.cos(t * 5 - ph * .8).abs());
      l.add(q + nrm * hw);
      r.add(q - nrm * hw);
    }
    _spline(fill, l);
    final rr = r.reversed.toList();
    fill.lineTo(rr[0].dx, rr[0].dy);
    _spline(fill, rr, move: false);
    fill.close();
    if (play) return;
    // frayed end: parallel warp threads
    final e = centre(1.0);
    final tg = e - centre(.94);
    final td = tg / tg.distance;
    final tn = Offset(-td.dy, td.dx);
    for (var j = 0; j < 3; j++) {
      final off = (j - 1) * w * .22;
      final s0 = e + tn * off;
      final s1 = s0 + td * (.06 + .035 * ((j * 5) % 3)) + tn * (off * .5 + math.sin(ph + j) * .012);
      _frays.moveTo(s0.dx, s0.dy);
      _frays.lineTo(s1.dx, s1.dy);
      if (j == 1 && p.fury > .05) {
        _fraysMagic.moveTo(s0.dx, s0.dy);
        _fraysMagic.lineTo(s1.dx, s1.dy);
      }
    }
  }

  /// The near wing's wrist bandage: a band wound diagonally across the arm
  /// (20 % smaller than the old cuff, edges following the bone), a small bow
  /// and two loose ends that stream with the air. One fill, strip lines and
  /// one ink outline at every size; the full level adds the lit middle strip,
  /// the shade and the frayed threads.
  void _nearCuff(double grip) {
    _cuffP
      ..reset()
      ..addPath(_nearBand, Offset.zero);
    _frays.reset();
    _fraysMagic.reset();
    final ph = p.phase;
    // the bow: two small loops along the arm and the turn that ties them
    final bs = math.sin(ph * 2.9) * .06 * (1 + p.fury);
    _loop(_cuffP, _bowAt, _boneAng + .55 + bs, .115, .040);
    _loop(_cuffP, _bowAt, _boneAng + math.pi - .35 - bs, .095, .036);
    _cuffP.addOval(Rect.fromCircle(center: _bowAt, radius: .034));
    final loose = 1 + p.unwrap * .7;
    final fl = .045 * (1 + p.fury * 1.2 + p.hit) + grip * .02;
    _tailStrip(_cuffP, _bowAt + const Offset(.02, .025), 1.20 - p.sweep * .3 + math.sin(ph * 3.1) * .08, .34 * loose, .11, ph * 3.4, fl);
    _tailStrip(_cuffP, _bowAt + const Offset(-.015, .03), 1.90 + p.sweep * .3 + math.sin(ph * 2.7 + 1) * .08, .27 * loose, .10, ph * 3.0 + 1.3, fl);
    if (silhouette) {
      c.drawPath(_cuffP, f(NeferhooPalette.ink));
      return;
    }
    c.drawPath(_cuffP, _fl(NeferhooPalette.linenLit));
    if (play) {
      c.drawPath(_cuffP, _ln(NeferhooPalette.ink, .035, .95));
      return;
    }
    c.drawPath(_nearStrips[0], _fl(NeferhooPalette.linen));
    c.drawPath(_nearStrips[1], _fl(NeferhooPalette.linenHi));
    c.drawPath(_nearBand, _sh(_cuffShade));
    c.drawPath(_frays, _ln(NeferhooPalette.linenDeep, .02, .8));
    c.drawPath(_cuffP, _ln(NeferhooPalette.ink, .03, .95));
    if (p.fury > .05) c.drawPath(_fraysMagic, _ln(NeferhooPalette.magic, .028, .9 * p.fury));
  }

  // =========================================================================
  // the tail: a hoopoe's tail is LONG, black and nearly square-ended with ONE
  // bold white band: a strip, not a second fan (M5: the wing is the round fan,
  // the tail the long strip, and sky shows between them)

  /// The tail's layout: the middle feather's angle, the step between feathers
  /// (shared with the rump coverts, which lie over the quill bases) and the
  /// lateral scale of the rump fan (the tail is 30 % narrower than it was).
  static const _tailN = 5, _tailLen = 2.05, _tailW = .31, _tailRumpV = .72;
  static const _tailTilt = .02; // the tail trails a touch below the body's axis (the notch under the wings)
  static const _band0 = .56, _band1 = .767; // the white band's edges, shares of the tail's length
  static const _farLift = .26; // how far the far wing is held up while the near wing deals (rad)

  (double, double) _tailFan() {
    final step = .092 * (1 + p.fury * .25 + p.hit * .2);
    final aC = _tailTilt - p.wing * .06 + math.sin(p.phase * 1.6) * .03 + p.sweep * .03;
    return (aC, step);
  }

  void wingArtTail() {
    final root = NeferhooLayout.tailRoot;
    final pl = play;
    final (aC, step) = _tailFan();
    _black.reset();
    _white.reset();
    _edges.reset();
    _hair.reset();
    // outer feathers first, the middle one on top
    for (final i in const [0, 4, 1, 3, 2]) {
      final k = i - (_tailN - 1) ~/ 2;
      final a = aC + k * step + math.sin(p.phase * 3.3 + i * 1.15) * (.012 + .018 * p.fury);
      final dir = Offset(math.cos(a), math.sin(a));
      final nrm = Offset(-dir.dy, dir.dx);
      final b = root + nrm * (k * .028);
      // the ends differ by .16 only: a squared end, slightly rounded
      final len = _tailLen - k * k * .04;
      final bow = .05 * _lagWave(.8 - .4 * k.abs()) * (k == 0 ? .6 : 1) + k * .008 + .012;
      _leaf(_black, b, a, len, _tailW, bow, _pfTail);
      // the one broad band
      // the band's two edges are straight across the tail: each feather's cut
      // is where it crosses the line at D along the tail's axis, so the cuts of
      // neighbours meet; only the feather tips scallop them (a small bulge)
      final dth = a - aC;
      double cut(double d) => ((d + k * .028 * math.sin(dth)) / math.cos(dth) / len).clamp(0.0, .97);
      final a0 = cut(_band0 * _tailLen), a1 = cut(_band1 * _tailLen);
      _bar(_white, b, a, len, _tailW, bow, _pfTail, a0, a1, .03);
      // ink between the feathers (the edge each one shows over the next, never
      // the tail's own outline): it separates the feathers across the white band
      // at game size
      final side = i < 2 ? -1.0 : 1.0;
      if (i == 1 || i == 3) _edge(_edges, b, a, len, _tailW, bow, _pfTail, side, a0: .26, back: .9);
      if (i == 2) {
        _edge(_edges, b, a, len, _tailW, bow, _pfTail, -1, a0: .26, back: .9);
        _edge(_edges, b, a, len, _tailW, bow, _pfTail, 1, a0: .26, back: .9);
      }
      if (!pl) {
        // full level: lilac hairlines on the white band only
        _shaft(_hair, b, a, len, bow, a0 + .02, a1 - .02);
        if (i == 1 || i == 3) _edgeSeg(_hair, b, a, len, _tailW, bow, _pfTail, side, a0, a1);
        if (i == 2) {
          _edgeSeg(_hair, b, a, len, _tailW, bow, _pfTail, -1, a0, a1);
          _edgeSeg(_hair, b, a, len, _tailW, bow, _pfTail, 1, a0, a1);
        }
      }
    }
    if (silhouette) {
      c.drawPath(_black, f(NeferhooPalette.ink));
      return;
    }
    c.drawPath(_black, _ln(NeferhooPalette.ink, .14));
    c.drawPath(_black, _sh(_tailBlack));
    c.drawPath(_white, _fl(Color.lerp(NeferhooPalette.linenLit, NeferhooPalette.papyrus, .32)!)); // the band is warm linen, not the wings' pure white: the mask and the target lead
    c.drawPath(_edges, _ln(NeferhooPalette.ink, .03, .6));
    if (!pl) c.drawPath(_hair, _ln(NeferhooWingInk.shaft, .012, .45));
  }

  // ---- the rump: linen coverts grown out of the body over the quills' bases ----

  // the fade: everything the coverts draw is transparent inside the body and
  // opaque outside it (static shaders, in the rig frame)
  static Shader _fade(Color c) => _lg(const Offset(1.12, 0), const Offset(1.62, 0), [c.withValues(alpha: 0), c], const [0, 1]);
  static final Shader _rumpLitFade = _fade(NeferhooPalette.linenLit);
  static final Shader _rumpCastFade = _fade(NeferhooPalette.linenDeep.withValues(alpha: .42));
  static final Path _rCast = Path(), _rLit = Path(), _rInk = Path();

  Paint _fadeFill(Shader s) => Paint()
    ..isAntiAlias = true
    ..shader = s;

  /// The tail's root as one believable thing: five linen coverts that grow out
  /// of the body (their roots fade into the wraps), cross the body's outline and
  /// lie over the quills' bases, with a tie round them. Drawn AFTER the body.
  void wingArtRump() {
    final (aC, _) = _tailFan();
    final root = NeferhooLayout.tailRoot;
    final u = Offset(math.cos(aC), math.sin(aC)), v = Offset(-u.dy, u.dx);
    Offset at(double du, double dv) => root + u * du + v * dv;
    // ONE scalloped fan of coverts: its root fades into the wraps, five round
    // tips lie over the quills' bases (white on black, like a hoopoe's white rump
    // running into its black tail), four short seams between the tips
    _rCast.reset();
    _rLit.reset();
    _rInk.reset();
    final shape = Path();
    final up = at(-.40, -.58 * _tailRumpV);
    shape.moveTo(up.dx, up.dy);
    final j = <Offset>[for (var i = 0; i <= 5; i++) at(.52 + .05 * math.sin(i / 5 * math.pi), (-.52 + i * .208) * _tailRumpV)];
    shape.lineTo(j.first.dx, j.first.dy);
    for (var i = 0; i < 5; i++) {
      final m = (j[i] + j[i + 1]) / 2 + u * .27;
      shape.quadraticBezierTo(m.dx, m.dy, j[i + 1].dx, j[i + 1].dy);
      _rInk.moveTo(j[i].dx, j[i].dy);
      _rInk.quadraticBezierTo(m.dx, m.dy, j[i + 1].dx, j[i + 1].dy);
    }
    final low = at(-.40, .58 * _tailRumpV);
    shape.lineTo(low.dx, low.dy);
    shape.close();
    for (var i = 1; i < 5; i++) {
      _rInk.moveTo(j[i].dx, j[i].dy);
      final e = j[i] - u * .17;
      _rInk.lineTo(e.dx, e.dy);
    }
    _rCast.addPath(shape, const Offset(-.02, .05));
    _rLit.addPath(shape, Offset.zero);
    if (silhouette) {
      c.drawPath(_rLit, f(NeferhooPalette.ink));
      return;
    }
    c.drawPath(_rCast, _fadeFill(_rumpCastFade));
    c.drawPath(_rLit, _fadeFill(_rumpLitFade));
    _tie(); // (draws the seams with the tie's own line: one stroke)
  }

  /// Where the tail's tie is knotted: under the quills, so the streamer that
  /// hangs from it is in the open from its first inch.
  Offset tailKnot() {
    final (aC, _) = _tailFan();
    final u = Offset(math.cos(aC), math.sin(aC)), v = Offset(-u.dy, u.dx);
    return NeferhooLayout.tailRoot + u * .36 + v * .40;
  }

  static final Path _tFill = Path(), _tInk = Path();

  /// One loop of a bow: from [k] along [ang], [len] long, [wid] across at its
  /// round far end.
  void _loop(Path out, Offset k, double ang, double len, double wid) {
    final d = Offset(math.cos(ang), math.sin(ang));
    final n = Offset(-d.dy, d.dx);
    final tip = k + d * len;
    out
      ..moveTo(k.dx, k.dy)
      ..cubicTo((k + n * wid * .45 + d * len * .15).dx, (k + n * wid * .45 + d * len * .15).dy, (tip + n * wid * 1.15 - d * len * .32).dx, (tip + n * wid * 1.15 - d * len * .32).dy, tip.dx, tip.dy)
      ..cubicTo((tip - n * wid * 1.15 - d * len * .32).dx, (tip - n * wid * 1.15 - d * len * .32).dy, (k - n * wid * .45 + d * len * .15).dx, (k - n * wid * .45 + d * len * .15).dy, k.dx, k.dy);
  }

  /// The tie round the coverts (a band) and its knot with two loops (the
  /// streamer's root); three draws.
  void _tie() {
    final (aC, _) = _tailFan();
    final root = NeferhooLayout.tailRoot;
    final u = Offset(math.cos(aC), math.sin(aC)), v = Offset(-u.dy, u.dx);
    Offset at(double du, double dv) => root + u * du + v * dv;
    final k = tailKnot();
    // two bands wound round the bundle (the inner one first), the outer one tied
    // off at the knot
    _tFill.reset();
    _tInk.reset();
    for (final (du, wk) in const [(-.10, 1.0)]) {
      // one slim bandage, slanted like the wraps on the body, tied off at the knot
      final pts = [at(.12 + du, -.50 * _tailRumpV), at(.24 + du, -.26 * _tailRumpV), at(.31 + du, -.02), at(.36 + du, .22 * _tailRumpV), at(.42 + du, .46 * _tailRumpV)];
      final hs = [for (final h in const [.055, .068, .072, .068, .058]) h * wk];
      final l = <Offset>[], r = <Offset>[];
      for (var i = 0; i < pts.length; i++) {
        final a = pts[math.max(0, i - 1)], b = pts[math.min(pts.length - 1, i + 1)];
        final d = b - a;
        final nn = Offset(-d.dy, d.dx) / d.distance;
        l.add(pts[i] - nn * hs[i]);
        r.add(pts[i] + nn * hs[i]);
      }
      final band = Path();
      _spline(band, l);
      final rr = r.reversed.toList();
      band.lineTo(rr[0].dx, rr[0].dy);
      _spline(band, rr, move: false);
      band.close();
      _tFill.addPath(band, Offset.zero);
      _tInk.addPath(band, Offset.zero);
    }
    // the bow: two loops and the turn
    final sw = math.sin(p.phase * 2.7) * .08 * (1 + p.fury);
    for (final (ang, len) in [(.50 + sw, .30), (2.40 - sw, .26)]) {
      final loop = Path();
      _loop(loop, k, ang, len, .085);
      _tFill.addPath(loop, Offset.zero);
      _tInk.addPath(loop, Offset.zero);
    }
    final knot = Path()..addOval(Rect.fromCircle(center: k, radius: .07));
    _tFill.addPath(knot, Offset.zero);
    _tInk.addPath(knot, Offset.zero);
    if (silhouette) {
      c.drawPath(_tInk, f(NeferhooPalette.ink));
      return;
    }
    c.drawPath(_tFill, _fl(NeferhooPalette.linenLit));
    // the rump's tip seams are ink too (one language: ink on the pale linen,
    // never lilac on the black quills): one stroke with the band's outline
    _tInk.addPath(_rInk, Offset.zero);
    c.drawPath(_tInk, _ln(NeferhooPalette.ink, .03, .95));
  }

  // =========================================================================
  // the streamers: two loose bandage ends, tips aglow with his magic

  static const _rib = <(Offset, double, double, int)>[(Offset(-.35, -1.62), -.18, 2.35, 0), (Offset(1.45, .22), .12, 1.9, 1)];
  static final Path _lit = Path(), _shade = Path(), _washA = Path(), _inkR = Path(), _weave = Path(), _thr = Path(), _thrM = Path(), _mote = Path(), _tips = Path();

  /// The streamer of the headcloth: its knot sits on the back edge of the nemes,
  /// over the head (drawn in the front pass).
  void _headKnot() {
    if (!p.mask) return; // (the bare head has no headcloth to tie)
    final root = _rib[0].$1;
    final lean = p.lean;
    _tFill.reset();
    _tInk.reset();
    final k = root + const Offset(.02, .02);
    final sw = math.sin(p.phase * 3.0) * .1 * (1 + p.fury);
    for (final (ang, len) in [(-2.50 + sw, .30), (2.50 - sw, .26)]) {
      final loop = Path();
      _loop(loop, k, ang - lean * .5, len, .085);
      _tFill.addPath(loop, Offset.zero);
      _tInk.addPath(loop, Offset.zero);
    }
    final knot = Path()..addOval(Rect.fromCircle(center: k, radius: .075));
    _tFill.addPath(knot, Offset.zero);
    _tInk.addPath(knot, Offset.zero);
    if (silhouette) {
      c.drawPath(_tInk, f(NeferhooPalette.ink));
      return;
    }
    c.drawPath(_tFill, _fl(NeferhooPalette.linenLit));
    c.drawPath(_tInk, _ln(NeferhooPalette.ink, .03, .95));
  }

  void wingArtRibbons({required bool back}) {
    if (!back) {
      _headKnot();
      return;
    }
    // his magic: calm at rest, bright in fury (glow is the eyes' channel)
    // (one aqua tip at rest keeps the mystic read; it brightens in fury)
    final m = (.62 + .38 * math.max(p.fury, p.glow * .8)).clamp(0.0, 1.0);
    // both streamers are gathered into the same scratch paths and drawn ONCE
    // (they never overlap each other): ten draws for the pair, not twenty
    _lit.reset();
    _shade.reset();
    _washA.reset();
    _inkR.reset();
    _weave.reset();
    _thr.reset();
    _thrM.reset();
    _mote.reset();
    _tips.reset();
    final halos = <Offset>[];
    var nm = 0;
    for (var ri = 0; ri < 2; ri++) {
      var (root, dir0, baseLen, seed) = _rib[ri];
      if (ri == 1) {
        // the tail's streamer hangs from the knot of the tail's tie, below the quills
        root = tailKnot();
        dir0 = .21 + .12 * p.fury; // (in fury the fan splays wider, so it hangs a little lower)
        baseLen = 1.5; // (shorter: the knot is already .4 further back than the old root)
      }
      // (the head streamer rises: in fury it grows less, so the union stays under the HP strip)
      final len = baseLen * (.55 + .45 * math.min(p.ribbons, 1.15)) * (1 + p.fury * (ri == 0 ? .08 : .25)) * 1.2;
      final body = len * .93; // the frayed end makes up the rest
      // follow-through: the streamer trails the body's lean, is shoved back by
      // a hit and lifted by the stroke
      final dir = dir0 - p.lean * .5 + p.wing * .05 - p.hit * .25;
      final d = Offset(math.cos(dir), math.sin(dir));
      final nrm = Offset(-d.dy, d.dx);
      final amp = (.13 + p.fury * (ri == 0 ? .03 : .06)) * len * (1 + p.hit * .4) * (ri == 1 ? .8 : 1.0);
      final speed = 3.0 + p.fury * 3;
      final ph = p.phase * speed;
      const nSeg = 16;
      final pts = <Offset>[], wid = <double>[], face = <double>[];
      for (var k = 0; k <= nSeg; k++) {
        final t = k / nSeg;
        final tt = math.pow(t, 1.2).toDouble();
        final wave = (math.sin(t * 5.4 - ph + seed * 2.1) + .3 * math.sin(t * 10.8 - ph * 1.7 + seed * 3.3)) * amp * tt + .05 * len * math.pow(t, 1.4) * _lagWave(3.2 * t - seed);
        pts.add(root + d * (body * t) + nrm * wave);
        final theta = t * 4.8 - ph * .8 + seed * 1.9 + 1.2;
        final cs = math.cos(theta);
        face.add(cs);
        wid.add((.32 - .12 * t) * math.max(.14, cs.abs()) * (1 + .07 * math.sin(k * 2.9 + seed * 1.7)));
      }
      final left = <Offset>[], right = <Offset>[];
      for (var k = 0; k <= nSeg; k++) {
        final a = pts[math.max(0, k - 1)], b = pts[math.min(nSeg, k + 1)];
        final dd = b - a;
        final nn = Offset(-dd.dy, dd.dx) / dd.distance;
        left.add(pts[k] + nn * wid[k] / 2);
        right.add(pts[k] - nn * wid[k] / 2);
      }
      final tip = pts.last;
      final tdir = (tip - pts[nSeg - 1]) / (tip - pts[nSeg - 1]).distance;
      final tnrm = Offset(-tdir.dy, tdir.dx);

      for (var k = 0; k < nSeg; k++) {
        final t = (k + .5) / nSeg;
        final fc = (face[k] + face[k + 1]) / 2;
        final seg = Path()
          ..moveTo(left[k].dx, left[k].dy)
          ..lineTo(left[k + 1].dx, left[k + 1].dy)
          ..lineTo(right[k + 1].dx, right[k + 1].dy)
          ..lineTo(right[k].dx, right[k].dy)
          ..close();
        (fc >= .22 ? _lit : _shade).addPath(seg, Offset.zero);
        if (t > .54) _washA.addPath(seg, Offset.zero);
        // the weave: selvedge threads along the face-on stretches (full detail only)
        if (!play && fc.abs() > .45) {
          for (final v in const [-.55, .55]) {
            final a = Offset.lerp(right[k], left[k], (v + 1) / 2)!, b = Offset.lerp(right[k + 1], left[k + 1], (v + 1) / 2)!;
            _weave.moveTo(a.dx, a.dy);
            _weave.lineTo(b.dx, b.dy);
          }
        }
      }
      if (!silhouette) {
        halos.add(tip);
        _spline(_inkR, left);
        _inkR.lineTo(right.last.dx, right.last.dy);
        _spline(_inkR, right.reversed.toList(), move: false);
        _inkR.close();
      }
      // two loose threads pulled out of the edge
      for (final (kk, sd) in const [(7, 1.0), (11, -1.0)]) {
        if (face[kk].abs() < .5) continue;
        final e0 = sd > 0 ? left[kk] : right[kk];
        final dd = pts[kk + 1] - pts[kk - 1];
        final nn = Offset(-dd.dy, dd.dx) / dd.distance;
        final e1 = e0 + nn * (sd * .07) + dd / dd.distance * .05;
        _thr.moveTo(e0.dx, e0.dy);
        _thr.quadraticBezierTo((e0.dx + e1.dx) / 2 + nn.dx * sd * .02, (e0.dy + e1.dy) / 2 + nn.dy * sd * .02, e1.dx, e1.dy);
      }
      // the cut end frays into warp threads
      final wEnd = wid.last;
      for (var j = 0; j < 6; j++) {
        final u = (j - 2.5) / 2.5;
        final s0 = tip + tnrm * (u * wEnd * .45);
        final lj = const [.15, .24, .11, .21, .13, .18][j] * (len / 2.35);
        final curl = math.sin(ph * 1.3 + j * 1.1) * .035 + u * .05;
        final e = s0 + tdir * lj + tnrm * curl;
        final mid = (s0 + e) / 2 + tnrm * curl * .4;
        _thr.moveTo(s0.dx, s0.dy);
        _thr.quadraticBezierTo(mid.dx, mid.dy, e.dx, e.dy);
        final h = Offset.lerp(s0, e, .45)!;
        _thrM.moveTo(h.dx, h.dy);
        _thrM.quadraticBezierTo(Offset.lerp(mid, e, .5)!.dx, Offset.lerp(mid, e, .5)!.dy, e.dx, e.dy);
      }
      if (silhouette) continue;
      _tips.addOval(Rect.fromCircle(center: tip + tdir * .06, radius: .05));
      // a few glyph motes drifting off the frayed end: more in fury
      nm = p.reduced ? 0 : (p.fury > .5 ? 3 : (m > .5 ? 2 : 0));
      for (var k = 0; k < nm; k++) {
        final u = (p.phase * .55 + k * .37 + ri * .21) % 1.0;
        final life = math.sin(u * math.pi);
        final o = tip + tdir * (.14 + u * .5) + tnrm * (math.sin(u * 6.28 + k * 2.1) * .11) + Offset(0, -u * .14);
        final z = .055 * (.5 + .8 * life);
        switch ((k + ri) % 3) {
          case 0: // the eye
            _mote.addOval(Rect.fromCenter(center: o, width: z * 2.2, height: z));
            _mote.addOval(Rect.fromCenter(center: o, width: z * .3, height: z * .3));
          case 1: // the ankh: a LOOP on a T, never a bare cross (review 08 m2); a little larger
            // than its neighbours so the loop stays open at 1x
            final k = z * 1.3;
            _mote.addOval(Rect.fromCenter(center: o + Offset(0, -k * .58), width: k * .78, height: k * .84));
            _mote.moveTo(o.dx, o.dy - k * .16);
            _mote.lineTo(o.dx, o.dy + k);
            _mote.moveTo(o.dx - k * .6, o.dy - k * .08);
            _mote.lineTo(o.dx + k * .6, o.dy - k * .08);
          default: // the water zigzag
            _mote.moveTo(o.dx - z, o.dy);
            _mote.lineTo(o.dx - z * .4, o.dy - z * .5);
            _mote.lineTo(o.dx + z * .4, o.dy + z * .5);
            _mote.lineTo(o.dx + z, o.dy);
        }
      }
    }
    if (silhouette) {
      c.drawPath(_lit, f(NeferhooPalette.ink));
      c.drawPath(_shade, f(NeferhooPalette.ink));
      c.drawPath(_thr, s(NeferhooPalette.ink, .03));
      return;
    }
    // the soft halo of his magic at each tip (one cached gradient)
    final haloR = .34 + p.fury * .12;
    final haloPaint = _sh(_halo)..color = const Color(0xffffffff).withValues(alpha: m);
    for (final tip in halos) {
      c.save();
      c.translate(tip.dx, tip.dy);
      c.scale(haloR, haloR);
      c.drawCircle(Offset.zero, 1, haloPaint);
      c.restore();
    }
    c.drawPath(_shade, _fl(NeferhooPalette.linenShade));
    c.drawPath(_lit, _fl(NeferhooPalette.linenLit));
    c.drawPath(_washA, _fl(NeferhooPalette.turqLit, .8));
    c.drawPath(_inkR, _ln(NeferhooPalette.ink, NeferhooLayout.detail * .9));
    if (!play) c.drawPath(_weave, _ln(NeferhooPalette.linenDeep, .014, .5));
    c.drawPath(_thr, _ln(NeferhooPalette.linenShade, .022, .95));
    if (m > .5) c.drawPath(_thrM, _ln(NeferhooPalette.magic, .03, .55 + .45 * m));
    c.drawPath(_tips, _fl(const Color(0xffffffff), .6 + .4 * m));
    if (nm > 0) c.drawPath(_mote, _ln(NeferhooPalette.magic, .02, .35 + .55 * m));
  }
}
