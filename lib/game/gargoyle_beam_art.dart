import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart' show FlightEvent, FlightEventKind, FlightSimulation;
import '../domain/sky_boss.dart';
import '../l10n/l10n.dart';
import 'boss_motion.dart';
import 'gargoyle_boss_rig.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';

/// What a spotting cost the bird (the consequence the SPOTTED! moment shows).
enum GargoyleSpotCost {
  /// The bird's shield took it (shield up).
  shield,

  /// A heart went (no shield).
  heart,

  /// The run is over (Classic): nothing to show beyond the catch itself.
  run,
}

/// The Searchlight Gargoyle's beams: the warning that marks the sky they will
/// sweep, the beam itself, the moment it catches the bird, and the dust it
/// lights.
///
/// Everything here is FAIRNESS art: the rules hurt a bird whose circle touches
/// the lit band at its column, so what is drawn there is that band and no more
/// (`test/gargoyle_beam_test.dart` measures it in pixels, both ways, like the
/// Ember Dragon's fire edge).
///
/// **The beam** ([beam], [under]): per beam a cached unit wedge for the amber
/// body, a narrower hot core, ONE path holding both hard hairline edges, ONE
/// path of dust motes and rain glints, then (over the head, [over]) the lens
/// flare: at most 6 ops, no blur, no `saveLayer`. A beam is PLACED by one
/// affine transform ([GargoyleKit.beamFrame]) carrying the unit wedge onto the
/// triangle from the lens, through the rules' band at the bird's column, to
/// the left edge. Its edges are EXACTLY the rules' band at the column (within
/// a pixel, both ways); nothing is drawn beyond it (there is no outer haze: a
/// glow past the band would read as more hazard than there is). The hairlines
/// stop just past the column: the hazard is the band there.
///
/// **The warning** ([warning], 1.5 s before each sweep): the swept fan in
/// amber hatching, HAZARD TAPE along the edge that borders the safe side, and
/// the safe side itself darkened (a deep-blue veil the shape of the shadow the
/// sweep will never reach), with a cool dashed line on the boundary,
/// chevrons marching into the dark at a quickening beat and the dodge tag
/// (FLY LOW / FLY HIGH / SLIP BETWEEN THE BEAMS with its 3-pip gauge). The
/// fury slit darkens the CORRIDOR between the two fans instead. A ray through
/// the lens and the column point is the boundary in every case, so the tape,
/// the dashes and the hold position of the beam's own edge coincide.
///
/// **SPOTTED!** ([spotted], [spotOf]): the flash, the halo round the bird, the
/// call-out and what it cost.
///
/// **Not New York's searchlights**: see [GargoyleBeamLook] (hue, hard edges,
/// origin in his lenses, width, flare, dashed fan, glide) plus this art's own
/// signatures: dust and rain glints INSIDE the beam, the core that lights
/// scenery it crosses, the cool safe-side language.
///
/// Pure functions of the pose (`pose.time` is 0 under Reduced Motion, so the
/// motes, tape and beats hold still there); NaN/infinite inputs draw nothing.
abstract final class GargoyleBeamArt {
  /// `beam(layers:)` bit masks (diagnostics: the tests isolate one layer).
  static const layerBody = 1, layerCore = 2, layerEdges = 4, layerMotes = 8;
  static const layerAll = layerBody | layerCore | layerEdges | layerMotes;

  /// Layer alphas (calm, fury) and the most any layer is ever. The body
  /// (source-over) is what hides the sky behind it, so it is at most
  /// [maxHidden]; the core is ADDED light (plus), so scenery and stars show
  /// through it and bright windows go brighter.
  static const bodyAlpha = .40, furyBodyAlpha = .40;
  static const coreAlpha = .38, furyCoreAlpha = .40;
  static const maxHidden = .40;

  /// The beam's colours: a saturated amber body and a pale-gold core (calm),
  /// a gold body and an arc-white core (fury). Saturated on purpose: amber
  /// light over a violet night sky desaturates toward beige, and beige is what
  /// New York's own cream searchlights are.
  static const _body = Color(0xffffb02e), _core = Color(0xfffff0b8);
  static const _furyBody = Color(0xffffa32e), _furyCore = Color(0xfffffaf0);
  static const maxLayerAlpha = GargoyleBeamLook.maxAlpha;

  /// Screen heights from the column to the right edge of the safe-side veil,
  /// and how long the hairlines run past the column (px at 360 high).
  static const veilReach = .46, edgeOverrun = 12.0;

  /// How long the SPOTTED! moment lasts (the rules' recovery is 1.5 s).
  static const spotSeconds = 1.5;

  /// Dust motes and rain glints per beam (the vertex budget is
  /// [GargoyleBeamLook.maxVertices]: 2 wedges of 3, 2 edges and 2 rim lines of
  /// 2 each, 2 per mote or glint).
  static const motes = 9, glints = 3;

  /// Diagnostics only (tests read it, it never influences a pixel): the most
  /// path vertices any one beam emitted in the last [_draw].
  static int lastBeamVertices = 0;

  // ------------------------------------------------------------ shared --

  static bool _size(Size s) => s.width.isFinite && s.height.isFinite && s.width > 1 && s.height > 1;
  static bool _pt(Offset o) => o.dx.isFinite && o.dy.isFinite;
  static double _unit(double v) => v.isFinite ? v.clamp(0.0, 1.0) : 0.0;

  static final _tri = <double, Path>{};

  /// The unit wedge of half-width [k]: apex (0,0), far corners (1,+-k).
  static Path _wedge(double k) => _tri.putIfAbsent(
    k,
    () => Path()
      ..moveTo(0, 0)
      ..lineTo(1, -k)
      ..lineTo(1, k)
      ..close(),
  );

  static final _filters = <int, ColorFilter>{};

  /// A cached colour filter that tints a white shader to [c] (modulate).
  static ColorFilter _tint(Color c) => _filters.putIfAbsent(
    c.toARGB32(),
    () => ColorFilter.mode(Color(c.toARGB32() | 0xff000000), BlendMode.modulate),
  );

  /// The one alpha ramp every light layer shares (white, along the beam's
  /// unit x: full at the lens, [GargoyleBeamLook.fadeMid] of it at
  /// [GargoyleBeamLook.fadeAt], none at the end). Body, core, the warning fan,
  /// for calm and fury, are this paint tinted by a cached colour filter:
  /// ONE shader for all of them. Every draw sets every property it uses.
  static Paint _ramp(Color tint, double alpha, [BlendMode mode = BlendMode.srcOver]) {
    final p = GargoyleKit.cached(
      'beam.ramp',
      () => GargoyleKit.linear(
        Offset.zero,
        const Offset(1, 0),
        const [Color(0xffffffff), Color(0xccffffff), Color(0x00ffffff)],
        const [0, GargoyleBeamLook.fadeAt, 1],
      ),
    );
    p
      ..colorFilter = _tint(tint)
      ..blendMode = mode
      ..color = Color.fromRGBO(0, 0, 0, _unit(alpha));
    return p;
  }

  /// The safe-side veil's shader: deep night blue, opaque from the screen's
  /// left edge to 55% of its width, none at the right end (unit x).
  static Paint _veil(double alpha) {
    final p = GargoyleKit.cached(
      'beam.veil',
      () => GargoyleKit.linear(
        Offset.zero,
        const Offset(1, 0),
        const [Color(0xff070b22), Color(0xff070b22), Color(0x00070b22)],
        const [0, .55, 1],
      ),
    );
    p
      ..colorFilter = null
      ..blendMode = BlendMode.srcOver
      ..color = Color.fromRGBO(0, 0, 0, _unit(alpha));
    return p;
  }

  /// The lens flare's shader: a white-hot core, pale gold, amber, nothing
  /// (unit radius).
  static Paint _flare(double alpha) {
    final p = GargoyleKit.cached(
      'beam.flare',
      () => GargoyleKit.radial(
        Offset.zero,
        1,
        const [Color(0xffffffff), Color(0xf2fff3cf), Color(0x73ffd36a), Color(0x26ffb84a), Color(0x00ffb84a)],
        const [0, .16, .38, .7, 1],
      ),
    );
    p
      ..colorFilter = null
      ..blendMode = BlendMode.srcOver
      ..color = Color.fromRGBO(0, 0, 0, _unit(alpha));
    return p;
  }

  /// A polyline of dashes along [a] to [b] (at most 70 of them), [phase] px
  /// along.
  static Path _dashes(Offset a, Offset b, double dash, double gap, [double phase = 0]) {
    final p = Path();
    final len = (b - a).distance;
    if (!len.isFinite || len < 1 || dash <= 0) return p;
    final d = (b - a) / len, step = dash + gap;
    var n = 0;
    for (var x = -(phase % step); x < len && n < 70; x += step, n++) {
      final x0 = math.max(0.0, x), x1 = math.min(len, x + dash);
      if (x1 > x0) {
        p
          ..moveTo(a.dx + d.dx * x0, a.dy + d.dy * x0)
          ..lineTo(a.dx + d.dx * x1, a.dy + d.dy * x1);
      }
    }
    return p;
  }

  static Path _poly(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  /// The pose's lens for a beam ([far]: the slit's upper beam), in px.
  static Offset _eye(GargoylePose pose, Offset bossCentre, double h, {required bool far}) {
    final o = GargoyleBossRig.beamOrigins(pose);
    return bossCentre + (far ? o.far : o.near) * (h * SkyBoss.radius);
  }

  /// The point at screen x [x] of the ray from [eye] through the bird's column
  /// at height [y] (px).
  static Offset _ray(Offset eye, double col, double y, double x) {
    final t = (eye.dx - x) / (eye.dx - col);
    return Offset(x, eye.dy + (y - eye.dy) * t);
  }

  // ------------------------------------------------------------- beams --

  /// One beam from [eye] (px) through the rules' band at [columnX] (px), to the
  /// left screen edge: body, core, hairline edges and motes. [layers] is a
  /// diagnostic mask ([layerBody] ...). [time] is the boss clock for the motes
  /// (0 holds them still). The lens flare is [over]'s.
  static void beam(
    Canvas c,
    Size size,
    GargoyleBeam b,
    Offset eye, {
    int layers = layerAll,
    double? columnX,
    double time = 0,
  }) {
    if (!_size(size) || !_pt(eye)) return;
    _draw(c, size, [(b, eye)], layers, columnX, time.isFinite ? time : 0);
  }

  /// Draws [beams] (one, or the slit's two) in order: each one's body and core,
  /// then ONE path for every hairline edge and ONE for every mote (and the pale
  /// rim lines just inside the edges, which share the motes' paint).
  static void _draw(
    Canvas c,
    Size size,
    List<(GargoyleBeam, Offset)> beams,
    int layers,
    double? columnX,
    double time,
  ) {
    final h = size.height, s = h / 360;
    final col = columnX ?? GargoyleLayout.birdColumn * h;
    final edges = Path(), pale = Path();
    var edgeAlpha = 0.0, fury = false, any = false, worst = 0;
    for (final (b, eye) in beams) {
      if (!b.centre.isFinite || !b.half.isFinite || !(b.intensity > 0)) continue;
      final frame = GargoyleKit.beamFrame(
        eye: eye,
        columnX: col,
        centre: b.centre * h,
        half: b.half * h,
        reachX: -h * .05,
      );
      if (frame == null) continue;
      final k = _unit(b.intensity);
      any = true;
      fury = b.fury;
      edgeAlpha = math.max(edgeAlpha, math.min(1.0, k / GargoyleBeamLook.igniteFloor));
      final body = b.fury ? _furyBody : _body;
      final core = b.fury ? _furyCore : _core;
      var vertices = 0;
      if (layers & (layerBody | layerCore) != 0) {
        c.save();
        c.transform(frame.matrix);
        if (layers & layerBody != 0) {
          c.drawPath(_wedge(1), _ramp(body, k * (b.fury ? furyBodyAlpha : bodyAlpha)));
          vertices += 3;
        }
        if (layers & layerCore != 0) {
          c.drawPath(_wedge(GargoyleBeamLook.coreGrow), _ramp(core, k * (b.fury ? furyCoreAlpha : coreAlpha), BlendMode.plus));
          vertices += 3;
        }
        c.restore();
      }
      if (layers & layerEdges != 0) {
        // The exact hazard: hairlines from the lens through the column (+12 px),
        // each laid INSIDE the band (its outer side on the rules' edge, so the
        // light never passes the band by even a hairline), and just inside
        // each a pale rim line.
        final dir = eye.dx - col, wpx = math.max(GargoyleBeamLook.edgeWidthPx, h * .0045);
        for (final (y, inward) in [((b.centre - b.half) * h, 1.0), ((b.centre + b.half) * h, -1.0)]) {
          final slope = (y - eye.dy) / (col - eye.dx), lean = math.sqrt(1 + slope * slope);
          for (final (path, inset) in [(edges, wpx / 2), (pale, wpx + .85 * math.max(1.0, s))]) {
            final through = Offset(col, y + inward * inset * lean);
            final from = eye + (through - eye) * (8 * s / (through - eye).distance);
            final end = eye + (through - eye) * (1 + edgeOverrun * s / dir);
            path
              ..moveTo(from.dx, from.dy)
              ..lineTo(end.dx, end.dy);
            vertices += 2;
          }
        }
      }
      if (layers & layerMotes != 0) vertices += _motes(pale, frame.reach, eye, col, b, h, time);
      worst = math.max(worst, vertices);
    }
    lastBeamVertices = worst;
    if (!any) return;
    if (layers & layerEdges != 0) {
      c.drawPath(
        edges,
        GargoyleKit.line(
          fury ? GargoyleBeamLook.furyEdge : GargoyleBeamLook.edge,
          math.max(GargoyleBeamLook.edgeWidthPx, h * .0045),
          math.min(1.0, (GargoyleBeamLook.edgeAlpha + .15) * edgeAlpha),
        ),
      );
    }
    if (layers & (layerMotes | layerEdges) != 0) {
      c.drawPath(pale, GargoyleKit.line(const Color(0xfffffaf0), 1.7 * math.max(1.0, s), .85));
    }
  }

  /// Dust and rain glints INSIDE a beam, into [into] (the paint is shared with
  /// the pale rim, so all of it is one op): [motes] specks drifting slowly down
  /// the beam and up to [glints] raindrops flashing as they cross the light, on
  /// the backdrop's own slant. Every point is placed in the beam's unit frame
  /// and kept inside `|v| <= .88` of the wedge at its place, so none is ever
  /// drawn outside the lit band. Returns the vertices it added.
  static int _motes(Path into, double reach, Offset eye, double col, GargoyleBeam b, double h, double t) {
    final s = h / 360;
    final axis = (Offset(col, b.centre * h) - eye) * reach; // a unit of u, along the beam
    final halfV = b.half * h * reach; // a unit of v*u, across it
    if (axis.dx.abs() < 1e-6 || halfV < 1e-6) return 0;
    Offset at(double u, double v) => eye + axis * u + Offset(0, halfV * v * u);
    // The unit cross-beam coordinate of a screen point, to keep glints inside.
    double vOf(Offset p) {
      final u = (p.dx - eye.dx) / axis.dx;
      if (u <= 0) return 9;
      return ((p.dy - eye.dy) - axis.dy * u) / (halfV * u);
    }

    var n = 0;
    final dir = axis / axis.distance;
    const uMin = .22, uMax = .97;
    for (var i = 0; i < motes; i++) {
      final speed = .03 + .035 * GargoyleKit.hash(i, 3);
      final u0 = (GargoyleKit.hash(i, 1) + speed * t / (uMax - uMin)) % 1;
      final u = uMin + (uMax - uMin) * u0;
      final wobble = .06 * math.sin(t * (.8 + .9 * GargoyleKit.hash(i, 4)) + 6.28 * GargoyleKit.hash(i, 5));
      final v = ((GargoyleKit.hash(i, 2) * 2 - 1) * .74 + wobble).clamp(-.8, .8);
      final p = at(u, v);
      final q = p + dir * (1.4 * s + 1.2 * s * GargoyleKit.hash(i, 6));
      into
        ..moveTo(p.dx, p.dy)
        ..lineTo(q.dx, q.dy);
      n += 2;
    }
    const rain = Offset(-.196, .98);
    for (var i = 0; i < glints; i++) {
      final period = .42 + .3 * GargoyleKit.hash(i, 11);
      final clock = t / period + GargoyleKit.hash(i, 12) * 7;
      final slot = clock.floor(), f = clock - slot;
      if (f >= .32) continue;
      final u = .3 + .65 * GargoyleKit.hash(slot * 5 + i, 13);
      final v = (GargoyleKit.hash(slot * 5 + i, 14) * 2 - 1) * .8;
      final len = (7 + 4 * GargoyleKit.hash(slot * 5 + i, 15)) * s;
      final p = at(u, v) + rain * (f / .32 * 14 * s), q = p + rain * len;
      if (vOf(p).abs() > .88 || vOf(q).abs() > .88) continue;
      into
        ..moveTo(p.dx, p.dy)
        ..lineTo(q.dx, q.dy);
      n += 2;
    }
    return n;
  }

  /// The warning and the beams, in the order they are painted under the rig
  /// (and under the bird, the stars and the feathers, when the staging calls
  /// it from the encounter's backdrop): the warning, the dashed line where the
  /// beam's edge will come to rest, then the beams.
  static void under(Canvas c, Size size, GargoylePose pose, Offset bossCentre) {
    if (!_size(size) || !_pt(bossCentre)) return;
    if (pose.warning > 0) {
      warning(c, size, pose, bossCentre);
    } else if (pose.warnRelease > 0 && pose.beams.isNotEmpty) {
      // The beam has ignited: the fan, veil and tag dissolve UNDER it (the
      // beam's body is already at 70% on its first frame), so the screen never
      // shows less danger than the frame before.
      warning(c, size, pose, bossCentre, progress: 1, release: pose.warnRelease);
    }
    if (pose.beams.isEmpty) return;
    final h = size.height;
    final list = [for (final b in pose.beams) (b, _eye(pose, bossCentre, h, far: b.far))];
    _corridor(c, size, pose, list);
    _restLine(c, size, pose, list);
    _draw(c, size, list, layerAll, null, pose.time);
  }

  /// Draws [veil] (a polygon in screen px) in the veil shader: deep blue,
  /// opaque to 55% of [xr], gone at [xr] (the shader's unit x is x / [xr]).
  static void _drawVeil(Canvas c, Path veil, double xr, double alpha) {
    if (!(xr > 10) || !(alpha > 0)) return;
    c.save();
    c.scale(xr, 1);
    c.drawPath(veil.transform(_scaleX(1 / xr)), _veil(alpha));
    c.restore();
  }

  /// During a slit sweep, the corridor between the two beams' inner edges is
  /// veiled like the warning's dark side: the gap the bird must hold reads as
  /// a dark lane between two bright blades, and it closes as they glide. One op.
  static void _corridor(Canvas c, Size size, GargoylePose pose, List<(GargoyleBeam, Offset)> list) {
    if (!pose.warnSlit || list.length != 2) return;
    final (upper, ue) = list[0];
    final (lower, le) = list[1];
    final h = size.height, col = GargoyleLayout.birdColumn * h;
    if (ue.dx - col < 1 || le.dx - col < 1 || !upper.half.isFinite || !lower.half.isFinite) return;
    final yu = (upper.centre + upper.half) * h, yl = (lower.centre - lower.half) * h;
    if (!(yl > yu)) return;
    final xl = -h * .05, xr = math.min(col + h * veilReach, le.dx - h * .06);
    final veil = _poly([_ray(ue, col, yu, xr), _ray(ue, col, yu, xl), _ray(le, col, yl, xl), _ray(le, col, yl, xr)]);
    _drawVeil(c, veil, xr, .30 * math.min(1.0, math.min(upper.intensity, lower.intensity) * 2));
  }

  /// The dashed cool line where the beam's hazard edge will come to rest (the
  /// inner extreme of the sweep): the dark side starts at it, and the glide
  /// ends on it. One op; alpha .5 with the beam's strength.
  static void _restLine(Canvas c, Size size, GargoylePose pose, List<(GargoyleBeam, Offset)> list) {
    final h = size.height, s = h / 360, col = GargoyleLayout.birdColumn * h;
    final path = Path();
    var k = 0.0;
    for (final (b, eye) in list) {
      if (eye.dx - col < 1 || !b.half.isFinite) continue;
      final double y;
      if (pose.warnSlit) {
        y = b.far ? (SearchlightGargoyle.slitUpper.$2 + b.half) * h : (SearchlightGargoyle.slitLower.$2 - b.half) * h;
      } else {
        y = pose.warnSide == BeamSide.low ? (SearchlightGargoyle.lowTo - b.half) * h : (SearchlightGargoyle.highTo + b.half) * h;
      }
      final from = _ray(eye, col, y, math.min(eye.dx - h * .10, col + h * .34));
      path.addPath(_dashes(from, _ray(eye, col, y, col - h * .34), 8 * s, 6 * s), Offset.zero);
      k = math.max(k, _unit(b.intensity));
    }
    if (k <= 0) return;
    c.drawPath(path, GargoyleKit.line(GargoylePalette.cool, math.max(1.8, 2 * s), .55 * math.min(1.0, k * 2)));
  }

  // ------------------------------------------------------------- flares --

  /// The lens flares over the head: a white-hot bloom at each firing lens; in
  /// the warning the same lens charging up behind its shutter.
  static void over(Canvas c, Size size, GargoylePose pose, Offset bossCentre) {
    if (!_size(size) || !_pt(bossCentre)) return;
    final h = size.height, s = h / 360;
    if (pose.beams.isNotEmpty) {
      for (final b in pose.beams) {
        final eye = _eye(pose, bossCentre, h, far: b.far);
        if (!_pt(eye) || !(b.intensity > 0)) continue;
        _lens(c, eye, (b.fury ? 27 : 24) * s, .95 * _unit(b.intensity));
      }
      return;
    }
    final g = pose.warning;
    if (!(g > 0) || pose.warnSide == null) return;
    // The warning: each lens the sweep will fire climbs toward the beam's
    // flare; the shutter (a bright slit across the lens) clacks open in the
    // first third of a second.
    for (final f in [false, if (pose.warnSlit) true]) {
      final eye = _eye(pose, bossCentre, h, far: f);
      if (!_pt(eye)) continue;
      final charge = _unit(g);
      final beat = pose.reduced ? 0.0 : .5 + .5 * math.cos((2 * g * SearchlightGargoyle.warnSeconds + math.pow(g * SearchlightGargoyle.warnSeconds, 2)) * 2 * math.pi);
      _lens(c, eye, (12 + 12 * charge + 3 * beat) * s, math.min(1.0, .3 + .6 * charge * charge + .12 * beat));
      // The shutter's clack: a bright slit of light across the lens at the
      // first beat of the warning, drawn out and gone by a quarter second.
      final clack = pose.reduced ? 0.0 : 1 - BossMotion.ramp(g, 0, .17);
      if (clack > 0) {
        final len = (22 + 26 * (1 - clack)) * s;
        c.drawLine(eye - Offset(len, 0), eye + Offset(len, 0), GargoyleKit.line(GargoylePalette.lampCore, math.max(1.8, 2.2 * s), .95 * clack));
      }
    }
  }

  static void _lens(Canvas c, Offset at, double radius, double alpha) {
    if (radius <= 0 || alpha <= 0) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius);
    c.drawCircle(Offset.zero, 1, _flare(alpha));
    c.restore();
  }

  // ----------------------------------------------------------- warning --

  /// One fan the warning announces: its lens, the heights (px) its extreme
  /// rays cross the bird's column, and which side of it is safe.
  static ({Offset eye, double y0, double y1, bool safeBelow}) _fan(Offset eye, double y0, double y1, bool safeBelow) =>
      (eye: eye, y0: y0, y1: y1, safeBelow: safeBelow);

  /// The telegraph: the fan the beam will sweep, the dark side, tape, chevrons
  /// and the tag. [GargoylePose.warning] is its progress (0..1).
  static void warning(Canvas c, Size size, GargoylePose pose, Offset bossCentre, {double? progress, double release = 1}) {
    if (!_size(size) || !_pt(bossCentre)) return;
    final side = pose.warnSide;
    final g = progress ?? pose.warning;
    if (side == null || !(g > 0)) return;
    final h = size.height, w = size.width, s = h / 360;
    final col = GargoyleLayout.birdColumn * h;
    final fury = pose.fury >= .5;
    final half = SearchlightGargoyle.half(enraged: fury) * h;
    final near = _eye(pose, bossCentre, h, far: false), far = _eye(pose, bossCentre, h, far: true);
    if (!_pt(near) || !_pt(far) || near.dx - col < 1) return;
    final reduced = pose.reduced;
    final secs = _unit(g) * SearchlightGargoyle.warnSeconds;
    // The beat quickens through the warning (the audio's ticks): 2 Hz to 5 Hz.
    final phase = reduced ? 0.0 : 2 * secs + secs * secs;
    final beat = reduced ? 1.0 : .5 + .5 * math.cos(phase * 2 * math.pi);
    final fade = BossMotion.ease(BossMotion.ramp(g, 0, .17)) * _unit(release);
    final fans = <({Offset eye, double y0, double y1, bool safeBelow})>[];
    if (pose.warnSlit) {
      fans
        ..add(_fan(far, SearchlightGargoyle.slitUpper.$1 * h - half, SearchlightGargoyle.slitUpper.$2 * h + half, true))
        ..add(_fan(near, SearchlightGargoyle.slitLower.$2 * h - half, SearchlightGargoyle.slitLower.$1 * h + half, false));
    } else if (side == BeamSide.high) {
      fans.add(_fan(near, SearchlightGargoyle.highFrom * h - half, SearchlightGargoyle.highTo * h + half, true));
    } else {
      fans.add(_fan(near, SearchlightGargoyle.lowTo * h - half, SearchlightGargoyle.lowFrom * h + half, false));
    }
    if (fans.any((f) => f.eye.dx - col < 1)) return;

    final xl = -h * .05;
    final xr = math.min(col + h * veilReach, near.dx - h * .06);

    // 1. The safe side, darkened: the shadow the sweep never reaches.
    final veil = Path();
    if (pose.warnSlit) {
      veil.addPath(
        _poly([
          _ray(fans[0].eye, col, fans[0].y1, xr),
          _ray(fans[0].eye, col, fans[0].y1, xl),
          _ray(fans[1].eye, col, fans[1].y0, xl),
          _ray(fans[1].eye, col, fans[1].y0, xr),
        ]),
        Offset.zero,
      );
    } else {
      final f = fans.first;
      final y = f.safeBelow ? f.y1 : f.y0;
      final edge = f.safeBelow ? h + 4 : -4.0;
      veil.addPath(_poly([_ray(f.eye, col, y, xr), _ray(f.eye, col, y, xl), Offset(xl, edge), Offset(xr, edge)]), Offset.zero);
    }
    _drawVeil(c, veil, xr, fade * (.68 + .06 * beat));

    // 2. The swept fans: amber, through the same wedge machinery as the beam
    // (so the fan's edges are the beam's edges), then hatched.
    final hatchClip = Path();
    for (final f in fans) {
      final frame = GargoyleKit.beamFrame(
        eye: f.eye,
        columnX: col,
        centre: (f.y0 + f.y1) / 2,
        half: (f.y1 - f.y0) / 2,
        reachX: xl,
      );
      if (frame == null) continue;
      c.save();
      c.transform(frame.matrix);
      c.drawPath(_wedge(1), _ramp(GargoylePalette.lampAmber, fade * (.16 + .16 * g + .05 * beat)));
      c.restore();
      hatchClip.addPath(_poly([f.eye, _ray(f.eye, col, f.y0, xl), _ray(f.eye, col, f.y1, xl)]), Offset.zero);
    }
    c.save();
    c.clipPath(hatchClip, doAntiAlias: false);
    final hatch = Path();
    for (var x = -h; x < w + h; x += h * .045) {
      hatch
        ..moveTo(x, 0)
        ..lineTo(x - h * .35, h);
    }
    c.drawPath(hatch, GargoyleKit.line(GargoylePalette.lampAmber, math.max(1.6, 2 * s), fade * (.16 + .12 * g)));
    c.restore();

    // 3. Hazard tape along each ray that borders the safe side, the cool
    // dashed line on it, the amber dashed outer edge of each fan.
    final ink = Path(), tape = Path(), safeLine = Path(), outer = Path(), ticks = Path();
    final tw = 8 * s, march = reduced ? 0.0 : secs * h * .22;
    for (final f in fans) {
      final yb = f.safeBelow ? f.y1 : f.y0, yo = f.safeBelow ? f.y0 : f.y1;
      final from = _ray(f.eye, col, yb, math.min(f.eye.dx - h * .10, col + h * .5)), to = _ray(f.eye, col, yb, xl);
      final len = (to - from).distance;
      if (len < 4) continue;
      final d = (to - from) / len;
      var n = f.safeBelow ? Offset(-d.dy, d.dx) : Offset(d.dy, -d.dx);
      if (f.safeBelow == (n.dy > 0)) n = -n;
      ink.addPath(_poly([from, to, to + n * tw, from + n * tw]), Offset.zero);
      final period = tw * 1.7, slant = d * (tw * .9);
      var count = 0;
      for (var x = -(march % period); x < len - tw && count < 44; x += period, count++) {
        if (x < 0) continue;
        final a = from + d * x, b = a + d * (tw * .85);
        tape.addPath(_poly([a, b, b + n * tw + slant, a + n * tw + slant]), Offset.zero);
      }
      safeLine.addPath(_dashes(from - n * (1.2 * s), to - n * (1.2 * s), 9 * s, 6 * s, march), Offset.zero);
      // Ticks into the dark from the line, one every 42 px: they pulse with the beat.
      for (var x = 21 * s - march % (42 * s); x < len; x += 42 * s) {
        if (x < 0) continue;
        final a = to.dx == from.dx ? from : from + d * x;
        ticks
          ..moveTo(a.dx - n.dx * 2.5 * s, a.dy - n.dy * 2.5 * s)
          ..lineTo(a.dx - n.dx * 11 * s, a.dy - n.dy * 11 * s);
      }
      outer.addPath(_dashes(_ray(f.eye, col, yo, math.min(f.eye.dx - h * .10, col + h * .5)), _ray(f.eye, col, yo, xl), 9 * s, 7 * s, march), Offset.zero);
    }
    c.drawPath(outer, GargoyleKit.line(GargoylePalette.lampAmber, math.max(1.5, 1.7 * s), fade * (.45 + .3 * g)));
    c.drawPath(ink, GargoyleKit.fill(GargoylePalette.ink, fade * .9));
    c.drawPath(tape, GargoyleKit.fill(GargoylePalette.lampAmber, fade));
    c.drawPath(safeLine, GargoyleKit.line(GargoylePalette.cool, math.max(2.0, 2.2 * s), fade));
    c.drawPath(ticks, GargoyleKit.line(GargoylePalette.cool, math.max(2.0, 2.2 * s), fade * (.3 + .7 * beat)));

    // 4. Chevrons marching into the dark, brightening in turn at the beat.
    // Straight up or down (the bird only moves that way), three rows from a
    // zone's boundary, two from each of a slit's (so they never meet in the
    // corridor), and only where the safe side is tall enough to hold them.
    final wave = (phase * .5) % 1;
    final rows = pose.warnSlit ? 2 : 3;
    for (var row = 0; row < rows; row++) {
      final d = ((wave - row / rows + .5) % 1 - .5).abs();
      final lit = reduced ? .85 : .3 + .7 * (1 - math.min(1.0, d * rows));
      final path = Path();
      for (final f in fans) {
        final yb = f.safeBelow ? f.y1 : f.y0;
        final safeN = f.safeBelow ? 1.0 : -1.0;
        for (final x in pose.warnSlit ? [col] : [col - h * .26, col]) {
          final p = _ray(f.eye, col, yb, x);
          final c0 = p + Offset(0, safeN * h * (.055 + row * .05));
          final wing = h * .032, depth = h * .02 * safeN;
          path
            ..moveTo(c0.dx - wing, c0.dy - depth)
            ..lineTo(c0.dx, c0.dy + depth)
            ..lineTo(c0.dx + wing, c0.dy - depth);
        }
      }
      c.drawPath(path, GargoyleKit.line(GargoylePalette.cool, math.max(2.2, 2.6 * s), fade * lit));
    }
    warningTag(c, size, pose, progress: g, release: release);
  }

  /// A matrix (as a storage list) that scales x by [k].
  static Float64List _scaleX(double k) => Float64List.fromList([k, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

  // (laid out again in a new language's fonts)
  static final _labels = L10n.cache(<String, TextPainter>{});

  static TextPainter _label(String text, double px, {Color color = GargoylePalette.cool, double stroke = 0}) => _labels.putIfAbsent(
    '$text@${px.toStringAsFixed(1)}@${color.toARGB32()}@$stroke',
    () => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: L10n.fonts.heading,
          fontFamilyFallback: L10n.fonts.headingFallback,
          fontSize: px,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          height: 1.05,
          color: stroke > 0 ? null : color,
          foreground: stroke > 0
              ? (Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = stroke
                  ..strokeJoin = StrokeJoin.round
                  ..color = color)
              : null,
        ),
      ),
      textAlign: TextAlign.center,
      // Words run their language's way; the tag stays where it is.
      textDirection: L10n.textDirection,
    )..layout(),
  );

  /// The dodge tag at the left edge (FLY LOW / FLY HIGH / SLIP BETWEEN THE
  /// BEAMS, the last on two lines so it ends before the bird's column) with
  /// its 3-pip gauge. It never reaches the bird's column, at any height.
  static void warningTag(Canvas c, Size size, GargoylePose pose, {double? progress, double release = 1}) {
    final side = pose.warnSide;
    if (side == null || !_size(size)) return;
    final h = size.height;
    final g = _unit(progress ?? pose.warning);
    // Dissolving under the beam: its alpha in four steps (a laid-out word is
    // cached per step).
    final a = release >= 1 ? 1.0 : (_unit(release) * 4).ceil() / 4;
    if (a <= 0) return;
    final l = L10n.strings;
    final text = pose.warnSlit
        ? l.bossDodgeSlipBetween
        : side == BeamSide.high
        ? l.bossDodgeFlyLow
        : l.bossDodgeFlyHigh;
    final two = text.contains('\n');
    final cy = pose.warnSlit ? h * .5 : (side == BeamSide.high ? h * .80 : h * .20);
    final px = h * (two ? .030 : .034);
    var tp = _label(text, px, color: GargoylePalette.cool.withValues(alpha: a));
    // Clear of the bird's column, like the dragon's tag: a long label is set
    // smaller rather than run under the bird.
    final spare = (FlightSimulation.birdX - .085) * h - h * .03 - h * .095;
    if (tp.width > spare) {
      tp = _label(text, (px * spare / tp.width * 10).floorToDouble() / 10, color: GargoylePalette.cool.withValues(alpha: a));
    }
    final box = Rect.fromCenter(
      center: Offset(tp.width / 2 + h * .06, cy),
      width: tp.width + h * .07,
      height: h * (two ? .105 : .066),
    );
    final rr = RRect.fromRectAndRadius(box, Radius.circular(h * .033));
    c.drawRRect(rr, GargoyleKit.fill(const Color(0xff171c39), .88 * a));
    c.drawRRect(rr, GargoyleKit.line(GargoylePalette.cool, 1.6, a));
    tp.paint(c, Offset(box.left + h * .035, box.top + h * (two ? .012 : .014)));
    final lit = <Offset>[], dim = <Offset>[];
    for (var i = 0; i < 3; i++) {
      (g > (i + .5) / 3.4 ? lit : dim).add(Offset(box.left + h * .05 + i * h * .02, box.bottom - h * .011));
    }
    c.drawPoints(ui.PointMode.points, dim, GargoyleKit.line(const Color(0xff55607f), h * .012, a));
    c.drawPoints(ui.PointMode.points, lit, GargoyleKit.line(GargoylePalette.lampWarm, h * .012, a));
  }

  // ----------------------------------------------------------- spotted --

  /// The moment the bird is caught in a beam, [since] seconds after the rules
  /// hurt it (0 to [spotSeconds]; nothing is drawn outside that): a white
  /// flash and ring at the bird, a streak of light across the band, an amber
  /// halo that stays through the recovery, "SPOTTED!" popping above it and
  /// what it cost (a shield or a heart). [bird] is the bird's centre (px).
  /// Reduced Motion: no expanding ring, pop or flash; the halo, the words and
  /// the cost show still and fade out.
  static void spotted(
    Canvas c,
    Size size, {
    required Offset bird,
    required double since,
    GargoyleSpotCost cost = GargoyleSpotCost.heart,
    bool fury = false,
    bool reduced = false,
  }) {
    if (!_size(size) || !_pt(bird) || !since.isFinite || since < 0 || since > spotSeconds) return;
    final h = size.height, s = h / 360;
    final edge = fury ? GargoyleBeamLook.furyEdge : GargoyleBeamLook.edge;
    final hot = fury ? GargoyleBeamLook.furyCore : GargoyleBeamLook.core;
    final out = 1 - BossMotion.ramp(since, 1.15, spotSeconds);
    final r = h * .085;
    if (!reduced && since < .32) {
      final k = since / .32, e = 1 - (1 - k) * (1 - k);
      // The flash: a white-hot disc and a streak along the lit band.
      if (since < .14) {
        final f = 1 - since / .14;
        c.drawCircle(bird, r * (.7 + .5 * (1 - f)), GargoyleKit.fill(hot, .5 * f));
        c.drawLine(
          bird + Offset(-h * .34 * (1 - f * .3), 0),
          bird + Offset(h * .18, 0),
          GargoyleKit.line(const Color(0xffffffff), 3.2 * math.max(1.0, s), .85 * f),
        );
      }
      c.drawCircle(bird, r * (.9 + 1.3 * e), GargoyleKit.line(hot, 3 * math.max(1.0, s), .9 * (1 - k)));
    }
    // The halo: a spotlight ring with reticle ticks, steady through the recovery.
    final beat = reduced ? 1.0 : .5 + .5 * math.cos(since * 2 * math.pi * 3.3);
    final spin = reduced ? 0.0 : since * 1.4;
    c.drawCircle(bird, r, GargoyleKit.line(GargoylePalette.ink, 4.4 * math.max(1.0, s), .55 * out));
    c.drawCircle(bird, r, GargoyleKit.line(edge, 2.6 * math.max(1.0, s), (.65 + .3 * beat) * out));
    final ticks = Path();
    for (var i = 0; i < 4; i++) {
      final a = spin + i * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      ticks
        ..moveTo(bird.dx + d.dx * r * 1.1, bird.dy + d.dy * r * 1.1)
        ..lineTo(bird.dx + d.dx * r * 1.32, bird.dy + d.dy * r * 1.32);
    }
    c.drawPath(ticks, GargoyleKit.line(hot, 3 * math.max(1.0, s), .9 * out));

    // "SPOTTED!" above the bird (below it near the top), popping in.
    final above = bird.dy > h * .30;
    final pop = reduced ? 1.0 : 1 + .35 * math.sin(math.pi * BossMotion.ramp(since, 0, .2)) * (1 - BossMotion.ramp(since, .2, .4));
    final grow = reduced ? 1.0 : BossMotion.ease(BossMotion.ramp(since, 0, .1));
    final rise = reduced ? 0.0 : -6 * s * BossMotion.ease(BossMotion.ramp(since, 0, 1.2));
    final px = (h * .055).roundToDouble();
    final spotted = L10n.strings.bossSpotted;
    final fill = _label(spotted, px, color: hot);
    final line = _label(spotted, px, color: GargoylePalette.ink, stroke: px * .3);
    final cy = (above ? bird.dy - h * .215 : bird.dy + h * .215).clamp(h * .16, h * .94) + rise;
    c.save();
    c.translate(bird.dx, cy);
    c.scale(math.max(.01, pop * grow));
    line.paint(c, Offset(-line.width / 2, -line.height / 2));
    fill.paint(c, Offset(-fill.width / 2, -fill.height / 2));
    c.restore();

    // What it cost.
    if (cost != GargoyleSpotCost.run && (reduced || since >= .12)) {
      final k = (reduced ? 1.0 : BossMotion.ease(BossMotion.ramp(since, .12, .3))) * out;
      final shield = cost == GargoyleSpotCost.shield;
      final color = shield ? const Color(0xff7cf0e0) : const Color(0xffff6b6b);
      final l = L10n.strings;
      final label = _label(shield ? l.bossShieldLost : l.bossHeartLost, (h * .032).roundToDouble(), color: color);
      final cw = label.width + h * .07, ch = h * .058;
      final centre = Offset(bird.dx, cy + (above ? h * .07 : -h * .07));
      final box = Rect.fromCenter(center: centre, width: cw, height: ch);
      c.save();
      c.translate(centre.dx, centre.dy);
      c.scale(reduced ? 1.0 : .8 + .2 * k);
      c.translate(-centre.dx, -centre.dy);
      final rr = RRect.fromRectAndRadius(box, Radius.circular(ch / 2));
      c.drawRRect(rr, GargoyleKit.fill(const Color(0xff171c39), .9 * k));
      c.drawRRect(rr, GargoyleKit.line(color, 1.8, k));
      final gx = box.left + ch * .55, gy = centre.dy;
      c.drawPath(shield ? _shieldGlyph(Offset(gx, gy), ch * .3) : _heartGlyph(Offset(gx, gy), ch * .3), GargoyleKit.fill(color, k));
      c.drawPath(_crack(Offset(gx, gy), ch * .3), GargoyleKit.line(const Color(0xff171c39), 1.5, k));
      label.paint(c, Offset(gx + ch * .4, centre.dy - label.height / 2));
      c.restore();
    }
  }

  static Path _shieldGlyph(Offset c, double r) => Path()
    ..moveTo(c.dx - r, c.dy - r * .9)
    ..lineTo(c.dx + r, c.dy - r * .9)
    ..lineTo(c.dx + r, c.dy + r * .1)
    ..quadraticBezierTo(c.dx + r, c.dy + r * .8, c.dx, c.dy + r * 1.1)
    ..quadraticBezierTo(c.dx - r, c.dy + r * .8, c.dx - r, c.dy + r * .1)
    ..close();

  static Path _heartGlyph(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy + r)
    ..cubicTo(c.dx - r * 1.6, c.dy - r * .2, c.dx - r * .8, c.dy - r * 1.2, c.dx, c.dy - r * .4)
    ..cubicTo(c.dx + r * .8, c.dy - r * 1.2, c.dx + r * 1.6, c.dy - r * .2, c.dx, c.dy + r)
    ..close();

  static Path _crack(Offset c, double r) => Path()
    ..moveTo(c.dx + r * .1, c.dy - r * .9)
    ..lineTo(c.dx - r * .25, c.dy - r * .2)
    ..lineTo(c.dx + r * .2, c.dy + r * .2)
    ..lineTo(c.dx - r * .1, c.dy + r);

  /// What [sim]'s latest beam spotting is, or null: how long ago the rules
  /// hurt the bird in the Gargoyle's light ([FlightEventKind.hit] or
  /// [FlightEventKind.shieldUsed] while a beam burned at the bird's height),
  /// and what it cost. A pure reading of the event list and the boss clock, so
  /// a replay or a seek shows exactly what the live flight did.
  static ({double since, GargoyleSpotCost cost})? spotOf(FlightSimulation sim) {
    final boss = sim.boss;
    if (boss == null || !boss.isGargoyle || !boss.age.isFinite || !sim.elapsed.isFinite) return null;
    final events = sim.events;
    for (var i = events.length - 1; i >= 0; i--) {
      final FlightEvent e = events[i];
      final since = sim.elapsed - e.at;
      if (since > spotSeconds) break;
      if (since < 0 || (e.kind != FlightEventKind.hit && e.kind != FlightEventKind.shieldUsed)) continue;
      final combat = boss.combatTime - since;
      if (combat < 0) continue;
      final x = SearchlightGargoyle.cycleTime(combat);
      final lit = SearchlightGargoyle.centres(x, side: boss.beamSide, slit: boss.slitSweep, fury: boss.enraged).any(
        (centre) => SearchlightGargoyle.lit(centre, SearchlightGargoyle.half(enraged: boss.enraged) + .01, e.y, GargoyleLayout.birdRadius),
      );
      if (!lit) continue;
      return (since: since, cost: e.kind == FlightEventKind.shieldUsed ? GargoyleSpotCost.shield : GargoyleSpotCost.heart);
    }
    return null;
  }

  // -------------------------------------------------------- staging --

  /// Whether the Gargoyle has anything for [underBoss] or [overBoss] to draw:
  /// the warning, a burning beam, its .1 s fade, or the defeat's stutter.
  static bool active(SkyBoss boss, BossMotion m) {
    if (!boss.isGargoyle || !boss.age.isFinite) return false;
    if (m.defeated) return m.reducedMotion ? false : m.death >= 0 && m.death < .3;
    if (boss.phase != BossPhase.attacking) return false;
    final x = boss.gargoyleCycle;
    return x >= SearchlightGargoyle.warnAt && x < SearchlightGargoyle.ventAt + GargoyleBeamLook.fadeSeconds;
  }

  /// The pose the beams are drawn from, built the way the rig's is (`gap` per
  /// the contract: [GargoylePose.defaultGap] at 640, larger wider).
  static GargoylePose poseFor(SkyBoss boss, BossMotion m) =>
      GargoylePose(boss, m, gap: boss.x - .29 - GargoyleLayout.birdColumn);

  /// [under] for the staging's one-line hook: call it from the encounter's
  /// BACKDROP (under the obstacles, stars, feathers, the boss and the bird).
  static void underBoss(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!active(boss, m)) return;
    under(c, size, poseFor(boss, m), Offset(boss.x * size.height, SearchlightGargoyle.anchorY * size.height));
  }

  /// [over] for the staging's hook: call it right after the rig.
  static void overBoss(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!active(boss, m)) return;
    over(c, size, poseFor(boss, m), Offset(boss.x * size.height, SearchlightGargoyle.anchorY * size.height));
  }

  /// [spotted] for the staging's foreground hook: derives the moment from the
  /// simulation ([spotOf]) and draws it at the bird.
  static void spottedNow(Canvas c, Size size, FlightSimulation sim, {bool reducedMotion = false}) {
    final spot = spotOf(sim);
    if (spot == null || !_size(size)) return;
    spotted(
      c,
      size,
      bird: Offset(FlightSimulation.birdX * size.height, sim.birdY * size.height),
      since: spot.since,
      cost: spot.cost,
      fury: sim.boss?.enraged ?? false,
      reduced: reducedMotion,
    );
  }
}
