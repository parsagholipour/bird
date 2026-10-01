import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';

import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';

/// What the body needs from a [GargoylePose], frozen for one frame.
///
/// The rig calls only [GargoyleBodyPose.of] and the [GargoyleBodyArt] part
/// functions, each at its place in [GargoyleLayout.zOrder]. Every part sanitises
/// its pose first ([finite]), so a hand-built pose with a NaN or an
/// out-of-range channel still paints something harmless.
final class GargoyleBodyPose {
  const GargoyleBodyPose({
    required this.tone,
    this.lamp = 0,
    this.flare = .3,
    this.fury = 0,
    this.crack = 0,
    this.glance = 0,
    this.shatter = 0,
    this.steam = 0,
    this.grip = 0,
    this.tail = 0,
    this.chest = 0,
    this.hit = 0,
    this.damage = 0,
    this.vent = -1,
    this.time = 0,
    this.reduced = true,
  });

  factory GargoyleBodyPose.of(GargoylePose pose) => GargoyleBodyPose(
    tone: pose.tone,
    lamp: pose.lamp,
    flare: pose.flare,
    fury: pose.fury,
    crack: pose.crack,
    glance: pose.glance,
    shatter: pose.shatter,
    steam: pose.steam,
    grip: pose.grip,
    tail: pose.tail,
    chest: pose.chest,
    hit: pose.hit,
    damage: pose.damage,
    vent: _ventPhase(pose),
    time: pose.time,
    reduced: pose.reduced,
  );

  /// How far through the vent's steam pulse the boss is (0 at the first puff,
  /// 1 at the last), or -1 outside one: the steam's puffs are born and drift
  /// on it, so they rise instead of only swelling. The defeat's own pulse
  /// (.12 s to .80 s after the kill) is read from the death clock.
  static double _ventPhase(GargoylePose p) {
    if (p.steam <= 0) return -1;
    if (p.defeated) return ((p.death - .12) / .68).clamp(0.0, 1.0);
    final x = (p.age - GargoyleTimeline.arrivalSeconds) % GargoyleTimeline.period;
    return ((x - GargoyleTimeline.ventAt) / GargoyleTimeline.steamSeconds).clamp(0.0, 1.0);
  }

  final GargoyleTone tone;

  /// Louvres: 0 shuttered .. 1 open. The glance is a rock clinking off the
  /// shut louvres (a brass spark, and a rattle when [reduced] is false). The
  /// glass is shattered at [shatter] 1; a [hit] on the lamp flares it.
  final double lamp, glance, shatter, hit;

  /// Lens glow (feeds the warm fill), fury, the seam cracks, the steam pulse,
  /// the talons' clench, the tail's swing, the chest's swell.
  final double flare, fury, crack, steam, grip, tail, chest;

  /// The steam pulse's progress (see [GargoyleBodyPose.of]), -1 when none.
  final double vent;

  /// How much of his health is gone, 0 .. 1 (the pose's `damage`): hairline
  /// cracks open from the first hits and grow with it, long before the fury's
  /// seams.
  final double damage;

  /// Seconds on the boss clock (0 under Reduced Motion).
  final double time;
  final bool reduced;

  /// This pose with every channel finite and in range: NaN and infinity become
  /// the calm default, nothing leaves its range. Returns `this` when it already is.
  GargoyleBodyPose get finite {
    double u(double v, [double fallback = 0]) => v.isFinite ? v.clamp(0.0, 1.0) : fallback;
    double s(double v, double lo, double hi) => v.isFinite ? v.clamp(lo, hi) : 0.0;
    final ok =
        lamp == u(lamp) &&
        flare == u(flare, .3) &&
        fury == u(fury) &&
        crack == u(crack) &&
        glance == u(glance) &&
        shatter == u(shatter) &&
        hit == u(hit) &&
        damage == u(damage) &&
        steam == u(steam) &&
        grip == u(grip) &&
        tail == s(tail, -1, 1) &&
        chest == s(chest, -.05, .3) &&
        (vent == -1 || vent == u(vent)) &&
        time.isFinite;
    if (ok) return this;
    return GargoyleBodyPose(
      tone: tone,
      lamp: u(lamp),
      flare: u(flare, .3),
      fury: u(fury),
      crack: u(crack),
      glance: u(glance),
      shatter: u(shatter),
      hit: u(hit),
      damage: u(damage),
      steam: u(steam),
      grip: u(grip),
      tail: s(tail, -1, 1),
      chest: s(chest, -.05, .3),
      vent: vent.isFinite ? (vent <= -1 ? -1 : vent.clamp(0.0, 1.0)) : -1,
      time: time.isFinite ? time : 0,
      reduced: reduced,
    );
  }
}

/// One tail swing's paths, built once per quantised swing (see
/// [GargoyleBodyArt.tail]).
final class _TailPaths {
  _TailPaths(this.fill, this.ink, this.lit, this.shade, this.spec);
  final Path fill, ink, lit, shade, spec;
}

/// One lamp opening's louvre paths, built once per quantised opening and
/// shatter (see [GargoyleBodyArt.lamp]).
final class _Plates {
  _Plates(this.lit, this.shade, this.edge);
  final Path lit, shade, edge;
}

/// A foot's paths: the stone toes, the steel claws and both inked.
final class _Foot {
  _Foot(this.toes, this.claws, this.ink, this.knuckles);
  final Path toes, claws, ink, knuckles;
}

/// The Gargoyle's body: a stepped limestone chest with a lit, stepped frame
/// round an octagonal brass lamp medallion with eleven sunburst louvres, a
/// steel-collared ruff of stacked feathers, feathered thighs with hooked talons
/// planted on the ledge, a five-blade steel tail fan, fury's seam cracks and the
/// vent's steam. Authored in rig units, origin at the lamp; the rig has already
/// leaned the upper body about the lamp (the tail, the legs and the talons
/// stand on the ledge and do not lean).
///
/// **The lamp is the target.** Its glass is the hit circle (r 1.00) and every
/// plate ends inside it. Shuttered, eleven pleated steel louvres close it like
/// a Deco sunburst in a faceted brass bezel, and nothing glows; open, the
/// louvres narrow to dark spokes and the glass behind them blazes white-hot
/// (a Fresnel lens's rings show), a ring pings outward from the bezel and the
/// stone around it warms: the clearest thing on him at 120 px, and
/// unmistakably open or shut.
///
/// **Craft rules this file keeps** (the Ember Dragon's review lessons): the
/// lamp never reads as a hole (it sits in a lit, stepped stone frame with only
/// a hairline recess); every metal is glossy (hard white glints on each brass
/// and steel edge); every light is painted INSIDE the ink and before it, so no
/// glow hazes an outline; ornament has a hierarchy (the lamp, then the steel
/// bands, the tail and the talons, then the stone's treads, then weathering);
/// everything is batched by paint, so a whole frame is about 80 ops.
///
/// Budget: <= 100 ops, 4 shaders (limestone, steel, brass, glass), 0 clips,
/// no blur, no `saveLayer`. Pose-dependent paths (the tail, the louvres, the
/// feet, the cracks) are cached by a quantised key in small bounded maps, so a
/// frame never allocates a path and a pixel never depends on what was drawn
/// before.
abstract final class GargoyleBodyArt {
  static Offset _o(double x, double y) => Offset(x, y);
  static Offset _p(double r, double a) => Offset(math.cos(a) * r, math.sin(a) * r);
  static Offset _unit(Offset v) => v / v.distance;
  static const _deg = math.pi / 180;

  /// The stone's shade side: deeper and more violet than the palette's
  /// `limeShade` (#9a8b7c), so the moon's rim and the specular streaks read
  /// against it (art review D1).
  static const _shade = Color(0xff7a6f86);

  /// The shut louvres' limestone: the lit plane a little darker than the
  /// chest (they sit in the recess), the shaded plane in the deep shade.
  static final Color _louvreLit = Color.lerp(GargoylePalette.lime, GargoylePalette.limeShade, .3)!;
  static final Color _louvreShade = Color.lerp(GargoylePalette.limeShade, GargoylePalette.limeDeep, .4)!;

  // ----------------------------------------------------------- geometry --

  /// [pts] with every convex right-angle corner cut by [d] (a 45 degree Deco
  /// chamfer); the extremes of the shape stay within [d] of where they were.
  static List<Offset> _chamfer(List<Offset> pts, double d) {
    final n = pts.length;
    var area = 0.0;
    for (var i = 0; i < n; i++) {
      final p = pts[i], q = pts[(i + 1) % n];
      area += p.dx * q.dy - q.dx * p.dy;
    }
    final sign = area >= 0 ? 1.0 : -1.0;
    final out = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = pts[(i + n - 1) % n], p = pts[i], b = pts[(i + 1) % n];
      final e1 = p - a, e2 = b - p;
      final right = (e1.dx * e2.dx + e1.dy * e2.dy).abs() < 1e-9;
      final cross = e1.dx * e2.dy - e1.dy * e2.dx;
      if (!right || cross * sign <= 0) {
        out.add(p);
        continue;
      }
      final k = math.min(d, math.min(e1.distance, e2.distance) / 2.2);
      out
        ..add(p - e1 / e1.distance * k)
        ..add(p + e2 / e2.distance * k);
    }
    return out;
  }

  /// The edges of [poly] that face [toward] (their outward normal within
  /// [minDot] of it), each pulled [inset] inside the outline and trimmed at
  /// the corners ([frac] of the edge's length at least: a glint, not an
  /// outline): the crescent of light on a stepped shape, as plain strokes (no
  /// clip), to be painted between the fill and the ink.
  static Path _rim(List<Offset> poly, Offset toward, {required double inset, double minDot = .35, double trim = .07, double frac = 0}) {
    final l = _unit(toward);
    final n = poly.length;
    var area = 0.0;
    for (var i = 0; i < n; i++) {
      final p = poly[i], q = poly[(i + 1) % n];
      area += p.dx * q.dy - q.dx * p.dy;
    }
    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = poly[i], q = poly[(i + 1) % n];
      final d = q - p;
      final len = d.distance;
      if (len < 1e-6) continue;
      final u = d / len;
      final out = area >= 0 ? Offset(u.dy, -u.dx) : Offset(-u.dy, u.dx);
      if (out.dx * l.dx + out.dy * l.dy < minDot) continue;
      final t = math.max(math.min(trim, len * .3), len * frac);
      final a = p + u * t - out * inset, b = q - u * t - out * inset;
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    return path;
  }

  /// The furthest [max] or nearest x of [poly] at height [y].
  static double _xAt(List<Offset> poly, double y, {required bool max}) {
    var best = max ? -1e9 : 1e9;
    for (var i = 0; i < poly.length; i++) {
      final p = poly[i], q = poly[(i + 1) % poly.length];
      if ((p.dy - y) * (q.dy - y) > 0 || p.dy == q.dy) continue;
      final x = p.dx + (q.dx - p.dx) * (y - p.dy) / (q.dy - p.dy);
      best = max ? math.max(best, x) : math.min(best, x);
    }
    return best;
  }

  static Path _lines(Iterable<(Offset, Offset)> segs) {
    final p = Path();
    for (final (a, b) in segs) {
      p
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    return p;
  }

  /// A row of pointed feathers hanging from [topY]: one polygon whose lower
  /// edge is a zigzag of [n] tips (at [tipY], [pitch] apart from [x0]) and
  /// notches (at [notchY]), plus the shade half of every feather (its right
  /// half) as a second path: stacked rows of these are the ruff.
  static (Path, Path) _feathers(double x0, int n, double pitch, double topY, double tipY, double notchY, {double round = .2}) {
    final left = x0 - pitch / 2, right = x0 + (n - .5) * pitch;
    final pts = <Offset>[_o(left + round, topY), _o(left, topY + round), _o(left, notchY)];
    final shade = Path();
    for (var k = 0; k < n; k++) {
      final x = x0 + k * pitch;
      pts
        ..add(_o(x, tipY))
        ..add(_o(x + pitch / 2, notchY));
      GargoyleKit.poly([_o(x, tipY), _o(x + pitch / 2, notchY), _o(x + pitch / 2, topY), _o(x, topY)], into: shade);
    }
    pts
      ..add(_o(right, topY + round))
      ..add(_o(right - round, topY));
    return (GargoyleKit.poly(pts), shade);
  }

  /// Light: the moon (upper right, cool, the key on his back and top edges),
  /// his own lamp (warm fill on the left and lower left faces).
  static const _toMoon = Offset(.55, -.83), _toLamp = Offset(-.9, .45);

  // --------------------------------------------------------- the torso --

  /// The stepped chest: Art Deco setbacks, every convex step chamfered. The
  /// extremes are the layout's (front -1.88, back 1.68, top -1.92, rump 2.84).
  static final List<Offset> _torsoPts = _chamfer(const [
    Offset(-1.10, -1.85), Offset(-1.10, -1.05), Offset(-1.50, -1.05), Offset(-1.50, -.55),
    Offset(-1.88, -.55), Offset(-1.88, .35), Offset(-1.64, .35), Offset(-1.64, 1.10),
    Offset(-1.28, 1.10), Offset(-1.28, 1.75), Offset(-.88, 1.75), Offset(-.88, 2.45),
    Offset(-.40, 2.80), Offset(.50, 2.84), Offset(1.15, 2.66), Offset(1.55, 2.10),
    Offset(1.55, 1.60), Offset(1.68, 1.60), Offset(1.68, .70), Offset(1.56, .70),
    Offset(1.56, -.20), Offset(1.18, -.20), Offset(1.18, -.85), Offset(.70, -.85),
    Offset(.70, -1.55), Offset(-.20, -1.92),
  ], .2);
  static final Path _torso = GargoyleKit.poly(_torsoPts);
  static final Path _torsoMoon = _rim(_torsoPts, _toMoon, inset: .095, minDot: .2);
  static final Path _torsoLamp = _rim(_torsoPts, _toLamp, inset: .095, minDot: .5);

  /// The chest's back flank in shade: a band along the stone's right edge, its
  /// outline sampled from the chest's own (so it follows every step and the
  /// rump's curve), which rounds the box.
  static final Path _backShade = () {
    final outer = <Offset>[], inner = <Offset>[];
    for (var y = -.12; y < 2.6; y += .12) {
      final x = _xAt(_torsoPts, y, max: true);
      if (x < -1e8) continue;
      outer.add(_o(x, y));
      inner.add(_o(x - .30 - (y > 1.9 ? (y - 1.9) * .2 : 0), y));
    }
    return GargoyleKit.poly([...outer, ...inner.reversed]);
  }();

  /// The lamp's warm light on the belly when it is open (a flat toon wash
  /// below the frame; the thigh and the ruff have their own).
  static final Path _bellyWash = GargoyleKit.poly(const [
    Offset(-.80, 1.50), Offset(1.20, 1.50), Offset(1.52, 1.95), Offset(1.46, 2.20),
    Offset(.20, 2.26), Offset(-.80, 2.20),
  ]);

  /// The two steel belly bands: rectangles across the belly whose right ends
  /// follow the stone's outline exactly (the ink covers the joint). Their left
  /// ends vanish behind the thigh.
  static const _bandRows = <(double, double)>[(1.63, 1.86), (2.30, 2.52)];
  static final List<List<Offset>> _bands = [
    for (final (y0, y1) in _bandRows)
      [
        _o(-.85, y0),
        _o(_xAt(_torsoPts, y0, max: true), y0),
        _o(_xAt(_torsoPts, y1, max: true), y1),
        _o(-.78, y1),
      ],
  ];
  static final Path _bandFill = () {
    final p = Path();
    for (final b in _bands) {
      GargoyleKit.poly(b, into: p);
    }
    return p;
  }();

  /// The lower third of each band (its shade), the chevron notches stamped in
  /// it, and the white streaks and rivets along it.
  static final Path _bandShade = () {
    final p = Path();
    for (final b in _bands) {
      final y0 = b[0].dy, y1 = b[3].dy, cut = y1 - (y1 - y0) * .32;
      GargoyleKit.poly([_o(b[3].dx, cut), _o(_xAt(_torsoPts, cut, max: true), cut), b[2], b[3]], into: p);
    }
    return p;
  }();
  static final Path _bandInk = () {
    final p = Path();
    for (final b in _bands) {
      final y0 = b[0].dy, y1 = b[3].dy, mid = (y0 + y1) / 2;
      GargoyleKit.poly(b, into: p);
      for (final x in const [.55, 1.0]) {
        p
          ..moveTo(x, mid - .07)
          ..lineTo(x + .09, mid)
          ..lineTo(x, mid + .07);
      }
    }
    return p;
  }();
  static final Path _bandSpec = () {
    // The belly bands' streaks, and the specular streaks of the chest's
    // stepped planes: a glint along the middle of every edge that faces the
    // upper left (a hard cream-white line inside the moon's rim).
    final p = _rim(_torsoPts, const Offset(-.6, -.8), inset: .17, minDot: .45, frac: .22);
    for (final b in _bands) {
      final y = b[0].dy + .055;
      p
        ..moveTo(.05, y)
        ..lineTo(.62, y)
        ..moveTo(.8, y)
        ..lineTo(.88, y);
    }
    return p;
  }();
  static final Path _rivets = () {
    final p = Path();
    for (final b in _bands) {
      final mid = (b[0].dy + b[3].dy) / 2;
      for (final x in const [-.05, .3, .75, 1.22]) {
        p.addOval(Rect.fromCircle(center: _o(x, mid), radius: .05));
      }
    }
    return p;
  }();

  /// Carved feather scoring in stepped chevrons on the belly between and under
  /// the bands (a dark cut with a light lip under it) and chisel hatching in the
  /// stone's mid-tone.
  static final Path _scoring = () {
    final p = Path();
    for (var k = 0; k < 3; k++) {
      final x = -.05 + k * .5;
      p
        ..moveTo(x, 1.93)
        ..lineTo(x + .25, 2.13)
        ..lineTo(x + .5, 1.93);
    }
    return p;
  }();
  static final Path _scoringLip = _scoring.shift(const Offset(0, .045));
  static final Path _hatch = () {
    final p = Path();
    void patch(double x, double y, int n) {
      for (var i = 0; i < n; i++) {
        p
          ..moveTo(x + i * .085, y)
          ..lineTo(x + i * .085 + .16, y + .16);
      }
    }

    patch(.25, 2.0, 4);
    patch(1.05, 2.04, 3);
    patch(.1, 2.6, 3);
    return p;
  }();

  /// Fluting on the chest's left flank: a pilaster of two carved grooves, each
  /// with a lit lip.
  static final Path _flutes = _lines(const [
    (Offset(-1.80, -.30), Offset(-1.80, .18)),
    (Offset(-1.66, -.30), Offset(-1.66, .18)),
  ]);
  static final Path _flutesLip = _flutes.shift(const Offset(.04, 0));

  /// The torso's carved grooves (scoring and flutes) and the light lips under
  /// them, each one path.
  static final Path _grooves = Path()
    ..addPath(_scoring, Offset.zero)
    ..addPath(_flutes, Offset.zero)
    ..addPath(_hatch, Offset.zero);
  static final Path _lips = Path()
    ..addPath(_scoringLip, Offset.zero)
    ..addPath(_flutesLip, Offset.zero);

  /// Verdigris: the brass's green weeping on the stone under the lamp (drips
  /// only ever start at the brass) and in the step crevices.
  static final Path _drips = _lines(const [
    (Offset(-.55, 1.25), Offset(-.55, 1.56)),
    (Offset(.12, 1.26), Offset(.12, 1.44)),
    (Offset(.62, 1.22), Offset(.62, 1.50)),
  ]);
  static final Path _dripTips = () {
    final p = Path();
    for (final (x, y, r) in const [(-.55, 1.59, .05), (.12, 1.47, .035), (.62, 1.53, .04)]) {
      p.addOval(Rect.fromCircle(center: _o(x, y), radius: r));
    }
    return p;
  }();
  static final Path _patina = () {
    final p = Path();
    void tri(Offset a, Offset b, Offset c) => GargoyleKit.poly([a, b, c], into: p);
    tri(_o(-1.64, .49), _o(-1.50, .49), _o(-1.64, .65));
    tri(_o(-1.28, 1.24), _o(-1.12, 1.24), _o(-1.28, 1.40));
    tri(_o(1.56, .84), _o(1.42, .84), _o(1.56, 1.0));
    return p;
  }();

  /// The verdigris's drip tips and the crevice patches, one fill.
  static final Path _patinaAll = Path()
    ..addPath(_dripTips, Offset.zero)
    ..addPath(_patina, Offset.zero);

  /// Specular streaks on the stone frame's upper-left bevels (drawn with the
  /// frame, not with the lamp part: the lamp's solid pixels stay inside its
  /// housing).
  static final Path _frameSpec = _lines([
    (_p(1.555, 207 * _deg), _p(1.555, 238 * _deg)),
    (_p(1.555, 172 * _deg), _p(1.555, 195 * _deg)),
    (_p(1.555, 252 * _deg), _p(1.555, 262 * _deg)),
  ]);

  // The lamp's stone frame: a stepped octagonal niche (a lit face, a shaded
  // lower bevel, a recess that is only a hairline ring round the brass).
  static const _frameR = 1.623, _recessR = 1.45;
  static Path _within(Path p) => Path.combine(PathOperation.intersect, p, _torso);
  static final Path _frame = _within(GargoyleKit.octagon(_frameR));
  static final Path _recess = _within(GargoyleKit.octagon(_recessR));
  static Path _facets(double ro, double ri, Iterable<int> ks, {bool inChest = false}) {
    final p = Path();
    for (final k in ks) {
      final a0 = (22.5 + 45 * k) * _deg, a1 = (22.5 + 45 * (k + 1)) * _deg;
      GargoyleKit.poly([_p(ro, a0), _p(ro, a1), _p(ri, a1), _p(ri, a0)], into: p);
    }
    return inChest ? _within(p) : p;
  }

  // Facet k is centred on 45 (k + 1) degrees (y down): 0 lower right, 1 bottom,
  // 2 lower left, 3 left, 4 upper left, 5 top, 6 upper right, 7 right.
  static final Path _frameLit = _facets(_frameR, _recessR, const [3, 4, 5, 6], inChest: true);
  static final Path _frameShade = _facets(_frameR, _recessR, const [0, 1, 2], inChest: true);
  static final Path _frameInk = Path()
    ..addPath(_frame, Offset.zero)
    ..addPath(_recess, Offset.zero);

  // ------------------------------------------------------------ paints --

  /// A cached gradient paint for this draw: the tone's colour filter set and
  /// the paint's own alpha, so a shared paint never leaks what the last draw
  /// set.
  static Paint _shader(String id, Paint Function() make, GargoyleTone t, [double alpha = 1]) {
    final paint = GargoyleKit.toned(GargoyleKit.cached(id, make), t);
    paint
      ..style = PaintingStyle.fill
      ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
    return paint;
  }

  /// The body's ONE limestone gradient (torso, thigh, ruff): pale on the lit
  /// upper left, warm in the middle, violet-grey in the lower right.
  static Paint _lime(GargoyleTone t) => _shader(
    'body.lime',
    () => GargoyleKit.linear(
      const Offset(-1.9, -2.0),
      const Offset(1.7, 2.9),
      const [GargoylePalette.limeSheen, GargoylePalette.limeLit, GargoylePalette.lime, _shade],
      const [0, .28, .62, 1],
    ),
    t,
  );

  /// The ONE brushed steel gradient (tail, belly bands, collar): pale on top,
  /// deep blue underneath.
  static Paint _steel(GargoyleTone t) => _shader(
    'body.steel',
    () => GargoyleKit.linear(
      const Offset(0, 1.5),
      const Offset(0, 3.3),
      const [GargoylePalette.steelLit, GargoylePalette.steel, GargoylePalette.steelMid, GargoylePalette.steelDeep],
      const [0, .3, .65, 1],
    ),
    t,
  );

  /// The ONE brass gradient, hard-edged like polished metal (the lamp's
  /// bezel ring).
  static Paint _brass(GargoyleTone t) => _shader(
    'body.brass',
    () => GargoyleKit.linear(
      const Offset(-1.0, -1.0),
      const Offset(1.0, 1.0),
      const [
        GargoylePalette.brassLit,
        GargoylePalette.brassLit,
        GargoylePalette.brass,
        GargoylePalette.brass,
        GargoylePalette.brassDeep,
        GargoylePalette.brassShade,
      ],
      const [0, .26, .30, .55, .58, 1],
    ),
    t,
  );

  /// The lamp's glass: a white-hot core, a warm body, an amber-to-orange rim.
  static Paint _glass(GargoyleTone t, double alpha) => _shader(
    'body.glass',
    () => GargoyleKit.radial(
      Offset.zero,
      GargoyleLayout.lampRadius,
      const [
        GargoylePalette.lampCore,
        GargoylePalette.lampCore,
        GargoylePalette.lampWarm,
        GargoylePalette.lampAmber,
        GargoylePalette.lampDeep,
      ],
      const [0, .38, .68, .92, 1],
    ),
    t,
    alpha,
  );

  /// Builds every static shape, the four shaders and the common cached paths
  /// once, off screen: the first paint of the body costs tens of milliseconds
  /// (measured 46 ms in the debug JIT), which would otherwise land inside the
  /// arrival's first frames. Call it while the arrival's storm plays.
  static void prewarm() {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    for (final b in const [
      GargoyleBodyPose(tone: GargoyleTone(), lamp: .5, crack: .6, steam: .5, vent: .5, glance: .5, hit: .5, shatter: .5, grip: .5, reduced: false, time: 1),
      GargoyleBodyPose(tone: GargoyleTone(), reduced: true),
    ]) {
      tail(c, b);
      farLeg(c, b);
      torso(c, b);
      thigh(c, b);
      ruff(c, b);
      lamp(c, b);
      cracks(c, b);
      steam(c, b);
    }
    rec.endRecording().dispose();
  }

  // -------------------------------------------------------- test access --

  /// The static shapes the tests hold the art to: the chest and thigh and
  /// ruff outlines, the strokes and fills laid inside the chest, the crack
  /// network and the louvres of one opening.
  @visibleForTesting
  static ({Path torso, Path thigh, Path ruffBack, Path ruffFront, Path frame}) get debugShapes =>
      (torso: _torso, thigh: _thigh, ruffBack: _ruffBack.$1, ruffFront: _ruffFront.$1, frame: _frame);

  /// Everything painted INSIDE the chest's outline (it must stay inside it).
  @visibleForTesting
  static Map<String, Path> get debugTorsoDetails => {
    'scoring': _scoring,
    'scoringLip': _scoringLip,
    'flutes': _flutes,
    'flutesLip': _flutesLip,
    'hatch': _hatch,
    'patina': _patina,
    'bandFill': _bandFill,
    'bandShade': _bandShade,
    'bandInk': _bandInk,
    'bandSpec': _bandSpec,
    'rivets': _rivets,
    'backShade': _backShade,
    'bellyWash': _bellyWash,
  };

  /// Every crack polyline with the levels it grows between.
  @visibleForTesting
  static List<(double, double, List<Offset>)> get debugCrackNet => _crackNet;

  /// The louvres for [open] and [shatter] as (lit, shade, edge) paths.
  @visibleForTesting
  static (Path, Path, Path) debugPlates(double open, [double shatter = 0]) {
    final p = _buildPlates(open, shatter);
    return (p.lit, p.shade, p.edge);
  }

  // ------------------------------------------------------------- caches --

  /// The bounded, least-recently-used caches of pose-dependent paths: a key is
  /// always a quantised pose value and its path a pure function of the key,
  /// so what is on screen never depends on what was drawn before.
  static const pathCacheCapacity = 40;
  static final Map<int, _TailPaths> _tails = {};
  static final Map<int, _Plates> _platesCache = {};
  static final Map<int, Path> _crackCache = {};
  static final Map<int, _Foot> _feet = {};

  /// How many cached paths the body holds now (tests: bounded).
  static int get cacheSize => _tails.length + _platesCache.length + _crackCache.length + _feet.length;

  /// Empties the path caches (tests only).
  static void clearCaches() {
    _tails.clear();
    _platesCache.clear();
    _crackCache.clear();
    _feet.clear();
  }

  static V _lru<K, V>(Map<K, V> cache, K key, V Function() make) {
    final hit = cache.remove(key);
    if (hit != null) return cache[key] = hit;
    if (cache.length >= pathCacheCapacity) cache.remove(cache.keys.first);
    return cache[key] = make();
  }

  // --------------------------------------------------------------- feet --

  /// A foot with heels at [heels], toes pointing left along the ledge lip and a
  /// hooked claw on each that drops over the lip (more by [curl]); [hind] adds
  /// the rear toe. Each toe is a stone finger with a knuckle ridge; the claw a
  /// steel fang.
  static _Foot _foot(List<double> heels, double curl, {bool hind = false, double scale = 1}) {
    const lip = GargoyleLayout.ledgeY;
    final toes = Path(), claws = Path(), knuckles = Path();
    for (final h in heels) {
      GargoyleKit.poly([
        _o(h, lip - .66 * scale),
        _o(h - .20, lip - .56 * scale),
        _o(h - .40, lip - .42 * scale),
        _o(h - .54, lip - .34 * scale),
        _o(h - .60, lip - .16 * scale),
        _o(h - .56, lip),
        _o(h, lip),
      ], into: toes);
      GargoyleKit.poly([
        _o(h - .46, lip - .38 * scale),
        _o(h - .70, lip - .33 * scale),
        _o(h - .84, lip - .14 * scale),
        _o(h - .86, lip + .06 * scale),
        _o(h - .81, lip + (.22 + curl) * scale),
        _o(h - .66, lip + (.34 + curl) * scale),
        _o(h - .71, lip + (.18 + curl * .6) * scale),
        _o(h - .68, lip + .02 * scale),
        _o(h - .58, lip - .08 * scale),
        _o(h - .47, lip - .14 * scale),
      ], into: claws);
      knuckles
        ..moveTo(h - .30, lip - .44 * scale)
        ..lineTo(h - .30, lip - .04)
        ..moveTo(h - .43, lip - .38 * scale)
        ..lineTo(h - .43, lip - .06);
    }
    if (hind) {
      final h = heels.last;
      GargoyleKit.poly([_o(h - .04, lip - .50), _o(h + .22, lip - .34), _o(h + .36, lip - .12), _o(h + .34, lip), _o(h - .04, lip)], into: toes);
      GargoyleKit.poly([
        _o(h + .22, lip - .32),
        _o(h + .44, lip - .20),
        _o(h + .52, lip + .06 + curl),
        _o(h + .42, lip + .26 + curl),
        _o(h + .38, lip + .08 + curl * .5),
        _o(h + .28, lip - .06),
      ], into: claws);
    }
    return _Foot(toes, claws, Path()..addPath(toes, Offset.zero)..addPath(claws, Offset.zero), knuckles);
  }

  static final _farFootRest = _foot(const [.74, 1.18, 1.62], 0, scale: .92);
  static final _nearFootRest = _foot(GargoyleLayout.talonHeels, 0, hind: true);

  // ---------------------------------------------------------- far leg --

  /// The far leg's feathered trouser (hem of three points), mostly behind the
  /// torso: the piece that shows is under the rump.
  static final List<Offset> _farLegPts = const [
    Offset(.80, 2.30), Offset(1.60, 2.16), Offset(1.68, 2.56), Offset(1.52, 2.80),
    Offset(1.38, 2.58), Offset(1.20, 2.82), Offset(1.04, 2.58), Offset(.88, 2.70),
  ];
  static final Path _farLeg = GargoyleKit.poly(_farLegPts);

  /// The far leg, behind the torso: a shaded feathered trouser and the claws of
  /// its foot on the lip, to the right of the near foot. Darker and cooler (it
  /// stands in the torso's shadow).
  static void farLeg(Canvas c, GargoyleBodyPose body) {
    final p = body.finite, t = p.tone;
    final q = (p.grip * 6).round();
    final foot = q == 0 ? _farFootRest : _lru(_feet, 100 + q, () => _foot(const [.74, 1.18, 1.62], q / 6 * .1, scale: .92));
    c.drawPath(foot.toes, GargoyleKit.fill(t.lit(_shade)));
    c.drawPath(foot.claws, GargoyleKit.fill(t.lit(GargoylePalette.steelDeep)));
    c.drawPath(foot.ink, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(_farLeg, GargoyleKit.fill(t.lit(GargoyleKit.shade(_shade, .9))));
    c.drawPath(_farLeg, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkMajor));
  }

  // ------------------------------------------------------------- tail --

  static const _tailRoot = GargoyleLayout.tailRoot;

  /// The tail's blade [i] outline: a stepped Deco feather with a swallowtail
  /// notch, pointing at [GargoyleLayout.tailTip]. The first nine points are the
  /// upper edge to the notch's lower prong, the rest the lower edge (hidden
  /// under the next blade, so only the last blade inks it).
  static List<Offset> _bladePts(int i, double swing) {
    final tip = GargoyleLayout.tailTip(i, swing: swing) - _tailRoot;
    final len = tip.distance;
    final d = tip / len, n = Offset(-d.dy, d.dx);
    Offset at(double u, double v) => _tailRoot + d * u + n * v;
    return [
      at(.40, -.13), at(.95, -.27), at(len - .85, -.30), at(len - .85, -.23), at(len - .32, -.21),
      at(len, -.13), at(len - .17, 0), at(len, .13), at(len - .32, .21),
      at(len - .85, .23), at(len - .85, .30), at(.95, .27), at(.40, .13),
    ];
  }

  static _TailPaths _buildTail(double swing) {
    final fill = Path(), ink = Path(), lit = Path(), shade = Path(), spec = Path();
    for (var i = 0; i < GargoyleLayout.tailBlades; i++) {
      final pts = _bladePts(i, swing);
      GargoyleKit.poly(pts, into: fill);
      ink.moveTo(pts[0].dx, pts[0].dy);
      final last = i == GargoyleLayout.tailBlades - 1;
      for (var k = 1; k < (last ? pts.length : 9); k++) {
        ink.lineTo(pts[k].dx, pts[k].dy);
      }
      if (last) ink.close();
      final tip = GargoyleLayout.tailTip(i, swing: swing) - _tailRoot;
      final len = tip.distance;
      final d = tip / len, n = Offset(-d.dy, d.dx);
      Offset at(double u, double v) => _tailRoot + d * u + n * v;
      lit
        ..moveTo(at(.95, -.17).dx, at(.95, -.17).dy)
        ..lineTo(at(len - .55, -.15).dx, at(len - .55, -.15).dy);
      spec
        ..moveTo(at(1.05, -.2).dx, at(1.05, -.2).dy)
        ..lineTo(at(1.6, -.2).dx, at(1.6, -.2).dy);
      if (i > 0) {
        shade
          ..moveTo(at(.95, -.36).dx, at(.95, -.36).dy)
          ..lineTo(at(len - .75, -.38).dx, at(len - .75, -.38).dy);
      }
    }
    return _TailPaths(fill, ink, lit, shade, spec);
  }

  /// The brass hub where the blades meet, peeking out behind the rump.
  static const _hub = Offset(1.84, 2.06);
  static final Path _hubInk = Path()
    ..addOval(Rect.fromCircle(center: _hub, radius: .22))
    ..addOval(Rect.fromCircle(center: _hub, radius: .12));

  /// The five-blade steel tail fan: a stepped Deco feather for each blade, one
  /// brushed steel fill for all of them, each blade marked out by the ink of
  /// its upper edge (the blade below lies over its lower half), a lit strip, a
  /// shade where it overlaps, a hard white glint, and a brass hub.
  static void tail(Canvas c, GargoyleBodyPose body) {
    final p = body.finite, t = p.tone;
    final key = (p.tail * 16).round();
    final w = _lru(_tails, key, () => _buildTail(key / 16));
    c.drawPath(w.fill, _steel(t));
    c.drawPath(w.lit, GargoyleKit.line(t.lit(GargoylePalette.steelLit), .10, .75));
    c.drawPath(w.shade, GargoyleKit.line(t.lit(GargoylePalette.steelCore), .12, .5));
    c.drawPath(w.ink, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkMajor));
    c.drawPath(w.spec, GargoyleKit.line(GargoylePalette.white, .04, .9));
    c.drawCircle(_hub, .22, GargoyleKit.fill(t.lit(GargoylePalette.brass)));
    c.drawPath(_hubInk, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawCircle(_hub + const Offset(-.06, -.07), .03, GargoyleKit.fill(GargoylePalette.white));
  }

  // ---------------------------------------------------------- the torso --

  /// Painted at the torso's frame: the stepped limestone chest (one gradient,
  /// treads lit by the moon, warm on the faces that look at his lamp), two
  /// steel belly bands with brass rivets and white glints, chevron scoring,
  /// chisel hatching, verdigris weeping from the brass, the lamp's stone frame
  /// and, in fury, darker stone. The chest swells with its `chest` channel
  /// (a few per cent about the belly); the frame stays centred on the lamp.
  static void torso(Canvas c, GargoyleBodyPose body) {
    final p = body.finite, t = p.tone;
    // the breath (the pose's chest is +-.03 at rest) shows: about 4% of the stone
    final swell = p.chest * .45 + p.chest.clamp(-.03, .03) * .8;
    c.save();
    if (swell != 0) {
      c.translate(0, 1.6);
      c.scale(1 + swell);
      c.translate(0, -1.6);
    }
    c.drawPath(_torso, _lime(t));
    c.drawPath(_backShade, GargoyleKit.fill(t.lit(_shade), .62));
    if (p.fury > 0) {
      c.drawPath(_torso, GargoyleKit.fill(t.lit(GargoylePalette.limeCore), .36 * p.fury));
    }
    final groove = t.lit(GargoylePalette.limeDeep);
    c.drawPath(_grooves, GargoyleKit.line(groove, .04, .5));
    c.drawPath(_lips, GargoyleKit.line(t.lit(GargoylePalette.limeSheen), .03, .65));
    // The steel belly bands.
    c.drawPath(_bandFill, _steel(t));
    c.drawPath(_bandShade, GargoyleKit.fill(t.lit(GargoylePalette.steelDeep), .6));
    c.drawPath(_bandInk, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(_rivets, GargoyleKit.fill(t.lit(GargoylePalette.brassLit)));
    c.drawPath(_bandSpec, GargoyleKit.line(GargoylePalette.white, .04, .9));
    if (p.lamp > .03) c.drawPath(_bellyWash, GargoyleKit.fill(t.lit(GargoylePalette.lampAmber), .20 * p.lamp));
    _lights(c, _torsoMoon, _torsoLamp, t, .07);
    GargoyleKit.inkHero(c, _torso);
    c.restore();
    _frameArt(c, p, t);
    c.drawPath(_drips, GargoyleKit.line(t.lit(GargoylePalette.vd), .055));
    c.drawPath(_patinaAll, GargoyleKit.fill(t.lit(GargoylePalette.vd), .9));
  }

  /// The moon's crescent and the lamp's warm fill along already-built rim
  /// paths (see [_rim]); both sit inside the ink.
  static void _lights(Canvas c, Path moon, Path warm, GargoyleTone t, double width) {
    final wide = 1 + t.dark * .5;
    // the moon's own cool white, brighter than the sky's tint: a rim that shows on cream
    if (t.moonRim > .02) c.drawPath(moon, GargoyleKit.line(t.lit(Color.lerp(t.sky, GargoylePalette.white, .35)!), width * wide, t.moonRim));
    if (t.lampFill > .02) c.drawPath(warm, GargoyleKit.line(t.lit(GargoylePalette.lampAmber), width * 1.1, t.lampFill * .55));
  }

  /// The lamp's stone frame (drawn at the lamp's own centre, never swelled with
  /// the chest): a lit face above, a shaded bevel below, a hairline recess
  /// round the brass, and a warm spill on the stone when the lamp is open.
  static void _frameArt(Canvas c, GargoyleBodyPose p, GargoyleTone t) {
    c.drawPath(_frameLit, GargoyleKit.fill(t.lit(GargoylePalette.limeSheen), .8));
    c.drawPath(_frameShade, GargoyleKit.fill(t.lit(_shade), .7));
    c.drawPath(_recess, GargoyleKit.fill(t.lit(GargoylePalette.limeDeep), .8));
    if (p.lamp > .03) {
      c.drawPath(_frame, GargoyleKit.fill(t.lit(GargoylePalette.lampAmber), .30 * p.lamp));
    }
    c.drawPath(_frameSpec, GargoyleKit.line(GargoylePalette.white, .06, .85));
    c.drawPath(_frameInk, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkDetail));
  }

  // -------------------------------------------------------------- thigh --

  /// The feathered thigh: an angular trouser whose hem is four points, hanging
  /// over the roots of the toes.
  static final List<Offset> _thighPts = const [
    Offset(-1.58, 1.62), Offset(-.85, 1.46), Offset(-.42, 1.56), Offset(-.10, 1.95),
    Offset(-.12, 2.30), Offset(-.24, 2.54), Offset(-.42, 2.38), Offset(-.62, 2.56),
    Offset(-.82, 2.38), Offset(-1.02, 2.56), Offset(-1.22, 2.38), Offset(-1.42, 2.54),
    Offset(-1.62, 2.26), Offset(-1.66, 1.95),
  ];
  static final Path _thigh = GargoyleKit.poly(_thighPts);
  static final Path _thighCast = _thigh.shift(const Offset(.07, .05));

  /// A hard crescent of polish on the thigh's rounded upper left (cream-white,
  /// half transparent): the roster's bosses are glossy.
  static final Path _thighGloss = GargoyleKit.poly(const [
    Offset(-1.52, 1.98), Offset(-1.50, 1.74), Offset(-1.34, 1.60), Offset(-1.10, 1.53), Offset(-.84, 1.52),
    Offset(-1.08, 1.60), Offset(-1.28, 1.72), Offset(-1.40, 1.90),
  ]);
  static final Path _thighMoon = _rim(_thighPts, _toMoon, inset: .075, minDot: .2);
  static final Path _thighLamp = _rim(_thighPts, _toLamp, inset: .075, minDot: .45);

  /// The thigh's planes: the lit upper front, the shade along its back and hem.
  static final Path _thighLit = GargoyleKit.poly(const [
    Offset(-1.50, 1.62), Offset(-.85, 1.52), Offset(-.72, 1.80), Offset(-1.56, 1.98),
  ]);
  static final Path _thighWash = GargoyleKit.poly(const [
    Offset(-1.56, 1.64), Offset(-.85, 1.48), Offset(-.42, 1.58), Offset(-.14, 1.95), Offset(-.30, 2.0), Offset(-1.60, 2.05),
  ]);
  static final Path _thighShade = GargoyleKit.poly(const [
    Offset(-.40, 1.60), Offset(-.10, 1.95), Offset(-.12, 2.30), Offset(-.24, 2.54), Offset(-.42, 2.38),
    Offset(-.62, 2.56), Offset(-.40, 2.26),
  ]);

  /// Feather scoring on the thigh: rows of chevrons, each lower row inset from
  /// the last, cut dark with a light lip.
  static final Path _thighScoring = () {
    final p = Path();
    for (var r = 0; r < 3; r++) {
      final y = 1.78 + r * .21;
      final x0 = -1.46 + (r.isOdd ? .18 : 0);
      for (var k = 0; k < 4; k++) {
        final x = x0 + k * .36;
        if (x + .36 > -.22) continue;
        p
          ..moveTo(x, y)
          ..lineTo(x + .18, y + .17)
          ..lineTo(x + .36, y);
      }
    }
    return p;
  }();
  static final Path _thighScoringLip = _thighScoring.shift(const Offset(0, .045));
  static final Path _shadowOnLedge = GargoyleKit.poly(const [
    Offset(-1.95, GargoyleLayout.ledgeY), Offset(.55, GargoyleLayout.ledgeY),
    Offset(.47, GargoyleLayout.ledgeY + .09), Offset(-1.85, GargoyleLayout.ledgeY + .09),
  ]);
  static final Path _clawGlints = () {
    // the thigh's specular streaks (along its upper-left edges and across its
    // lit plane) and a glint on every claw
    final p = _rim(_thighPts, const Offset(-.6, -.8), inset: .13, minDot: .5, frac: .22)
      ..moveTo(-1.40, 1.74)
      ..lineTo(-1.04, 1.64)
      ..moveTo(-.98, 1.62)
      ..lineTo(-.93, 1.61);
    for (final h in GargoyleLayout.talonHeels) {
      p
        ..moveTo(h - .78, GargoyleLayout.ledgeY - .20)
        ..lineTo(h - .82, GargoyleLayout.ledgeY + .02);
    }
    return p;
  }();

  /// The near thigh and its three hooked stone talons on the ledge lip. The
  /// talons grip: `grip` clenches the claws further over the lip; the contact
  /// shadow on the ledge's face says they are planted. The hem's points hang over
  /// the toes' roots.
  static void thigh(Canvas c, GargoyleBodyPose body) {
    final p = body.finite, t = p.tone;
    final q = (p.grip * 6).round();
    final foot = q == 0 ? _nearFootRest : _lru(_feet, q, () => _foot(GargoyleLayout.talonHeels, q / 6 * .12, hind: true));
    c.drawPath(_shadowOnLedge, GargoyleKit.fill(t.lit(GargoylePalette.limeCore), .55));
    c.drawPath(foot.toes, GargoyleKit.fill(t.lit(GargoylePalette.lime)));
    c.drawPath(foot.claws, GargoyleKit.fill(t.lit(GargoylePalette.steelMid)));
    c.drawPath(foot.ink, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(_thighCast, GargoyleKit.fill(t.lit(GargoylePalette.limeCore), .30));
    c.drawPath(_thigh, _lime(t));
    c.drawPath(_thighLit, GargoyleKit.fill(t.lit(GargoylePalette.limeSheen), .3));
    c.drawPath(_thighShade, GargoyleKit.fill(t.lit(_shade), .5));
    if (p.fury > 0) c.drawPath(_thigh, GargoyleKit.fill(t.lit(GargoylePalette.limeCore), .36 * p.fury));
    c.drawPath(_thighGloss, GargoyleKit.fill(t.lit(const Color(0xfffffbe8)), .85));
    if (p.lamp > .03) c.drawPath(_thighWash, GargoyleKit.fill(t.lit(GargoylePalette.lampAmber), .24 * p.lamp));
    c.drawPath(_thighScoring, GargoyleKit.line(t.lit(GargoylePalette.limeDeep), .045, .55));
    c.drawPath(_thighScoringLip, GargoyleKit.line(t.lit(GargoylePalette.limeSheen), .03, .6));
    _lights(c, _thighMoon, _thighLamp, t, .06);
    c.drawPath(_thigh, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkMajor));
    // Hard glints on the claws' outer edges.
    c.drawPath(_clawGlints, GargoyleKit.line(GargoylePalette.white, .035, .85));
  }

  // --------------------------------------------------------------- ruff --

  /// The ruff: two stacked rows of big pointed feathers over a steel collar,
  /// each row a polygon whose lower edge is a zigzag of tips (every feather
  /// pleated, its right half in shade), the front row offset half a step so its
  /// tips fall between the back row's. Mostly the neck between the head and the
  /// shoulder shows; the left tips hang over the chest.
  static final (Path, Path) _ruffBack = _feathers(-1.14, 4, .62, -1.94, -1.28, -1.62);
  static final (Path, Path) _ruffFront = _feathers(-.83, 3, .62, -1.94, -1.42, -1.74);
  static final List<Offset> _collarPts = const [
    Offset(-1.20, -1.62), Offset(-.90, -1.80), Offset(-.30, -1.94), Offset(.30, -1.90),
    Offset(.80, -1.76), Offset(.98, -1.60), Offset(.98, -1.46), Offset(.80, -1.62),
    Offset(.30, -1.76), Offset(-.30, -1.80), Offset(-.90, -1.66), Offset(-1.20, -1.48),
  ];
  static final Path _collar = GargoyleKit.poly(_collarPts);
  static final Path _collarMoon = _rim(_collarPts, _toMoon, inset: .05, minDot: .4, trim: .04)
    // and a streak down the lit half of each front feather
    ..addPath(_lines([for (var k = 0; k < 3; k++) (_o(-.83 + k * .62 - .24, -1.64), _o(-.83 + k * .62 - .12, -1.50))]), Offset.zero);
  /// The ruff, collar and feathers (left tips over the chest).
  static void ruff(Canvas c, GargoyleBodyPose body) {
    final p = body.finite, t = p.tone;
    final (backFill, backShade) = _ruffBack;
    final (frontFill, frontShade) = _ruffFront;
    c.drawPath(backFill, GargoyleKit.fill(t.lit(_shade)));
    c.drawPath(backShade, GargoyleKit.fill(t.lit(GargoylePalette.limeDeep), .5));
    c.drawPath(backFill, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(frontFill, _lime(t));
    c.drawPath(frontShade, GargoyleKit.fill(t.lit(_shade), .6));
    if (p.fury > 0) c.drawPath(backFill, GargoyleKit.fill(t.lit(GargoylePalette.limeCore), .36 * p.fury));
    c.drawPath(frontFill, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    c.drawPath(_collar, GargoyleKit.fill(t.lit(GargoylePalette.steel)));
    c.drawPath(_collarMoon, GargoyleKit.line(t.lit(GargoylePalette.white), .04, .85));
    c.drawPath(_collar, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
  }

  // --------------------------------------------------------------- lamp --

  static const _housing = GargoyleLayout.housingRadius;
  static const _inner = 1.18;
  static final Path _housingPath = GargoyleKit.octagon(_housing);
  static final Path _innerPath = GargoyleKit.octagon(_inner);

  /// The brass bezel's eight facets by how they face the light (top and upper
  /// left lit, the left and right in the mid-tone, the lower left deep, the
  /// bottom and lower right in shade), each tone one path.
  static final Path _facetLit = _facets(_housing, _inner, const [4, 5, 6]);
  static final Path _facetMid = _facets(_housing, _inner, const [3, 7]);
  static final Path _facetDeep = _facets(_housing, _inner, const [2]);
  static final Path _facetShade = _facets(_housing, _inner, const [0, 1]);
  static final Path _facetInk = () {
    final p = Path();
    for (var k = 0; k < 8; k++) {
      final a = (22.5 + 45 * k) * _deg;
      p
        ..moveTo(_p(_housing, a).dx, _p(_housing, a).dy)
        ..lineTo(_p(_inner, a).dx, _p(_inner, a).dy);
    }
    return p..addPath(_innerPath, Offset.zero);
  }();
  static final Path _rivetsLamp = () {
    final p = Path();
    for (var k = 0; k < 8; k++) {
      p.addOval(Rect.fromCircle(center: _p(1.135, (22.5 + 45 * k) * _deg), radius: .042));
    }
    return p;
  }();
  static final Path _glintLamp = () {
    final p = Path();
    // hard white glints on the lit facets' edges
    final a0 = 225 * _deg, a1 = 270 * _deg;
    p
      ..moveTo(_p(1.30, a0 + .10).dx, _p(1.30, a0 + .10).dy)
      ..lineTo(_p(1.30, a0 + .58).dx, _p(1.30, a0 + .58).dy)
      ..moveTo(_p(1.30, a1 + .12).dx, _p(1.30, a1 + .12).dy)
      ..lineTo(_p(1.30, a1 + .36).dx, _p(1.30, a1 + .36).dy);
    // a sparkle on the upper left corner of the housing: a cross of two hard lines
    const c = Offset(-.93, -.93);
    p
      ..moveTo(c.dx - .15, c.dy)
      ..lineTo(c.dx + .15, c.dy)
      ..moveTo(c.dx, c.dy - .15)
      ..lineTo(c.dx, c.dy + .15);
    // and the dot on the hub
    p
      ..moveTo(-.055, -.065)
      ..lineTo(-.04, -.05);
    return p;
  }();

  /// The hard crescent of light on the glass (the lens's reflection).
  static final Path _glassGlint = () {
    const outer = Rect.fromLTRB(-.92, -.92, .92, .92), inner = Rect.fromLTRB(-.76, -.76, .76, .76);
    return Path()
      ..arcTo(outer, 198 * _deg, 62 * _deg, true)
      ..arcTo(inner, 260 * _deg, -62 * _deg, false)
      ..close();
  }();

  /// A Fresnel lens's rings on the glass (seen between the open louvres).
  static final Path _fresnel = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: .40))
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: .70));

  /// The shut lamp's one amber slit: along the gap between louvres 8 and 9
  /// (188 degrees, toward the bird), from the hub's edge to the rim.
  static final Path _slit = _lines([(_p(.26, 188.2 * _deg), _p(.955, 188.2 * _deg))]);

  /// A star for the spark of a glance and the flare of a hit (unit size).
  static final Path _star = () {
    final p = Path();
    for (var k = 0; k < 16; k++) {
      final r = k.isEven ? 1.0 : .22;
      final a = k * math.pi / 8 - math.pi / 2;
      final o = _p(r, a);
      if (k == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    return p..close();
  }();

  /// The glass's broken lines: cracks from the point the last blow landed.
  static final Path _shards = _lines([
    (_o(-.30, -.18), _o(-.78, -.56)),
    (_o(-.78, -.56), _o(-.90, -.42)),
    (_o(-.30, -.18), _o(.10, -.80)),
    (_o(.10, -.80), _o(.42, -.88)),
    (_o(-.30, -.18), _o(.66, .02)),
    (_o(.66, .02), _o(.90, .30)),
    (_o(-.30, -.18), _o(-.12, .80)),
    (_o(-.12, .80), _o(.18, .92)),
    (_o(-.30, -.18), _o(-.84, .36)),
  ]);

  /// Louvres: eleven pleated plates that close the glass (closed) or narrow to
  /// dark spokes (open). Each plate folds along its radial axis into two
  /// planes, the one facing the light brighter. [open] and [shatter] are
  /// quantised (24 and 8 steps).
  static _Plates _buildPlates(double open, double shatter) {
    const n = GargoyleLayout.louvreCount;
    const pitch = 2 * math.pi / n;
    final lit = Path(), shade = Path(), edge = Path();
    const light = Offset(-.406, -.914);
    for (var i = 0; i < n; i++) {
      var a = -math.pi / 2 + i * pitch;
      var ro = .985;
      var half = pitch / 2 * (1 - open * .85) * .955;
      if (shatter > 0) {
        // The blow bends some plates and drops three.
        final h = GargoyleKit.hash(i, 7);
        a += (h - .5) * .55 * shatter;
        if (i == 2 || i == 6 || i == 9) {
          half *= 1 - shatter;
          ro = .985 - shatter * .35;
        } else {
          ro = .985 - h * .10 * shatter;
        }
      }
      if (half < .004) continue;
      const ri = .21;
      final aIn = half * .92;
      final left = [_p(ri, a - aIn), _p(ro, a - half), _p(ro, a), _p(ri, a)];
      final right = [_p(ri, a), _p(ro, a), _p(ro, a + half), _p(ri, a + aIn)];
      // The plane facing the light: the tangent at a is (-sin a, cos a); the
      // ridge's + side faces +tangent.
      final plus = -math.sin(a) * light.dx + math.cos(a) * light.dy > 0;
      GargoyleKit.poly(plus ? right : left, into: lit);
      GargoyleKit.poly(plus ? left : right, into: shade);
      GargoyleKit.poly([left[0], left[1], right[2], right[3]], into: edge);
    }
    return _Plates(lit, shade, edge);
  }

  /// The lamp: an octagonal brass medallion with eleven sunburst louvres over
  /// round glass (r 1.0, the hit circle), centred exactly on the origin in every
  /// pose. See the class doc for what open and shut look like.
  static void lamp(Canvas c, GargoyleBodyPose body) {
    final p = body.finite, t = p.tone;
    final open = p.lamp;
    // Brass housing: outer hero ink, eight facets, a recess, the bezel ring.
    c.drawPath(_facetLit, GargoyleKit.fill(t.lit(GargoylePalette.brassLit)));
    c.drawPath(_facetMid, GargoyleKit.fill(t.lit(GargoylePalette.brass)));
    c.drawPath(_facetDeep, GargoyleKit.fill(t.lit(GargoylePalette.brassDeep)));
    c.drawPath(_facetShade, GargoyleKit.fill(t.lit(GargoylePalette.brassShade)));
    c.drawPath(_innerPath, GargoyleKit.fill(t.lit(GargoylePalette.brassShade)));
    c.drawPath(_facetInk, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkDetail));
    c.drawPath(_housingPath, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkHero));
    c.drawCircle(Offset.zero, 1.04, _bezel(t));
    c.drawPath(_rivetsLamp, GargoyleKit.fill(t.lit(GargoylePalette.brassLit)));
    // The glass: dark when shut, white-hot when open; fury leaks light through
    // the shut louvres as white-hot slits.
    c.drawCircle(Offset.zero, GargoyleLayout.lampRadius, GargoyleKit.fill(t.lit(GargoylePalette.limeCore)));
    final eff = math.min(1.0, open + p.fury * .18 * (1 - open));
    // the glass comes up faster than the louvres narrow, so opening reads as lighting up
    final glow = math.min(1.0, open * 1.5 + (1 - open) * p.fury * .8);
    if (glow > .02) {
      c.drawCircle(Offset.zero, GargoyleLayout.lampRadius, _glass(t, glow));
      c.drawPath(_fresnel, GargoyleKit.line(t.lit(GargoylePalette.lampDeep), .03, .5 * glow));
    }
    // The louvres.
    final eq = (eff * 24).round(), sq = (p.shatter * 8).round();
    final plates = _lru(_platesCache, eq * 16 + sq, () => _buildPlates(eq / 24, sq / 8));
    final rattle = p.reduced ? 0.0 : math.sin(p.time * 70) * .03 * p.glance;
    if (rattle != 0) {
      c.save();
      c.translate(rattle, 0);
    }
    final warm = open.clamp(0.0, 1.0);
    Color plate(Color closed, Color opened) => t.lit(Color.lerp(closed, opened, warm * .92)!);
    c.drawPath(plates.lit, GargoyleKit.fill(plate(_louvreLit, GargoylePalette.brassShade)));
    c.drawPath(plates.shade, GargoyleKit.fill(plate(_louvreShade, GargoylePalette.limeCore)));
    c.drawPath(plates.edge, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkDetail));
    if (rattle != 0) c.restore();
    // The amber slit: shut, the lamp still burns behind its louvres, a hair of
    // light along the gap between two of them (on the side that faces the
    // bird): dim at rest, brighter as he charges, white-hot in fury; open, the
    // whole glass is the light and the slit is gone.
    final slit = (1 - open) * (.55 + .45 * math.max(p.flare, p.fury));
    if (slit > .02) {
      c.drawPath(_slit, GargoyleKit.line(t.lit(Color.lerp(GargoylePalette.lampAmber, GargoylePalette.arcCore, p.fury)!), .05, slit));
    }
    // The hub, with its hard glint.
    c.drawCircle(Offset.zero, GargoyleLayout.hubRadius + .03, GargoyleKit.fill(t.lit(Color.lerp(GargoylePalette.brass, GargoylePalette.lampCore, warm * .8 + p.fury * .3)!)));
    c.drawCircle(Offset.zero, GargoyleLayout.hubRadius + .03, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkPart));
    // Glints: hard white on the brass, a crescent on the glass.
    c.drawPath(_glintLamp, GargoyleKit.line(GargoylePalette.white, .05, .95));
    c.drawPath(_glassGlint, GargoyleKit.fill(GargoylePalette.white, .36 - open * .18));
    if (open > .04) _pingArt(c, p, t);
    if (p.hit > 0) {
      // the flare stays inside the housing (it re-fires with every hit: a
      // strobe if it spilled over the chest)
      c.save();
      c.scale(.55 + p.hit * .5);
      c.drawPath(_star, GargoyleKit.fill(GargoylePalette.lampCore, .7 * p.hit));
      c.restore();
    }
    if (p.glance > 0) _sparkArt(c, p);
    if (p.shatter > 0) {
      c.drawPath(_shards, GargoyleKit.line(GargoylePalette.ink, .09, p.shatter * .7));
      c.drawPath(_shards, GargoyleKit.line(GargoylePalette.lampCore, .045, p.shatter));
    }
  }

  static Paint _bezel(GargoyleTone t) {
    final paint = _brass(t);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = .09
      ..color = const Color(0xffffffff);
    return paint;
  }

  /// The open lamp's "shoot here": a ring of warm light that pings outward from
  /// the bezel, over and over while it is open (a still ring under Reduced
  /// Motion). Translucent, so it never reads as solid body.
  static void _pingArt(Canvas c, GargoyleBodyPose p, GargoyleTone t) {
    final ph = p.reduced ? .25 : (p.time * 1.25) % 1.0;
    final r = _housing + .10 + ph * .55;
    c.drawCircle(
      Offset.zero,
      r,
      GargoyleKit.line(t.lit(GargoylePalette.lampWarm), .09 * (1 - ph * .6), .66 * p.lamp * (1 - ph)),
    );
  }

  /// The brass spark where a rock clinked off the shut louvres.
  static void _sparkArt(Canvas c, GargoyleBodyPose p) {
    c.save();
    c.translate(-.52, -.40);
    c.scale(.12 + .42 * p.glance);
    c.drawPath(_star, GargoyleKit.fill(GargoylePalette.brassLit, p.glance));
    c.scale(.45);
    c.drawPath(_star, GargoyleKit.fill(GargoylePalette.white, p.glance));
    c.restore();
  }

  // -------------------------------------------------------------- cracks --

  /// A jagged line from [a] to [b] in [n] strokes, its joints pushed sideways
  /// by up to [amp] (a deterministic hash of [seed]): a crack, not a squiggle.
  static List<Offset> _jag(Offset a, Offset b, int n, double amp, int seed) {
    final d = b - a, u = d / d.distance, nrm = Offset(-u.dy, u.dx);
    return [
      a,
      for (var i = 1; i < n; i++)
        a + d * ((i + (GargoyleKit.hash(i, seed + 1) - .5) * .5) / n) + nrm * ((GargoyleKit.hash(i, seed) - .5) * 2 * amp),
      b,
    ];
  }

  /// The seam cracks as polylines with the crack level they start at and the
  /// level at which they reach full length (fury's .6 shows the first four
  /// whole; the defeat spreads the rest). They run on the stone only, never
  /// over the brass or the steel, and never off the body: from the layout's
  /// [GargoyleLayout.crackSeeds].
  static final List<(double, double, List<Offset>)> _crackNet = [
    (0.0, .30, _jag(_o(-1.55, -.22), _o(-1.84, .34), 4, .09, 3)),
    (0.08, .42, _jag(_o(-1.66, .14), _o(-1.44, 1.04), 5, .09, 5)),
    (0.10, .55, _jag(_o(1.52, .14), _o(1.40, .92), 4, .08, 9)),
    (0.06, .60, _jag(_o(-.60, 1.70), _o(-.46, 2.40), 5, .09, 12)),
    (.30, .60, _jag(_o(-.30, 1.90), _o(-.62, 2.12), 3, .07, 13)),
    (.45, .75, _jag(_o(-1.02, 1.36), _o(-1.16, 1.62), 3, .07, 15)),
    (.50, .8, _jag(_o(1.34, .90), _o(1.40, 1.36), 3, .08, 17)),
    (.58, .90, _jag(_o(.70, 1.90), _o(.52, 2.28), 3, .08, 21)),
    (.62, .95, _jag(_o(.30, 2.56), _o(.46, 2.78), 3, .06, 22)),
    (.65, .95, _jag(_o(-.90, -1.30), _o(-1.30, -.92), 3, .08, 23)),
    (.75, 1.0, _jag(_o(-.60, 1.70), _o(-.92, 1.96), 3, .07, 27)),
    (.8, 1.0, _jag(_o(1.10, 1.92), _o(1.34, 2.16), 3, .06, 29)),
    ..._radial,
  ];

  /// The frame splits at the lamp's corners: a crack from each brass corner
  /// across the stone bezel and out into the chest, as far as the stone goes
  /// (stopped short of the steel bands and the outline). Fury shows four, the
  /// defeat all of them.
  static final List<(double, double, List<Offset>)> _radial = () {
    final out = <(double, double, List<Offset>)>[];
    const order = [(3, .05, .5), (1, .12, .55), (6, .20, .6), (4, .25, .6), (0, .62, .85), (2, .68, .9), (5, .74, 1.0), (7, .8, 1.0)];
    for (final (k, from, to) in order) {
      final a = (22.5 + 45 * k) * _deg;
      final d = Offset(math.cos(a), math.sin(a));
      var r = 1.40;
      while (r < 2.05) {
        final pt = d * (r + .06);
        // stone only: inside the chest, above the first steel band
        if (!_torso.contains(pt + d * .08) || (pt.dy > 1.56 && pt.dx > -.85)) break;
        r += .05;
      }
      if (r < 1.58) continue;
      out.add((from, to, _jag(d * 1.40, d * r, math.max(2, ((r - 1.40) / .16).round()), .06, 31 + k)));
    }
    return out;
  }();

  static Path _crackPath(double level) {
    final p = Path();
    for (final (from, to, pts) in _crackNet) {
      final f = ((level - from) / (to - from)).clamp(0.0, 1.0);
      if (f <= 0) continue;
      var total = 0.0;
      for (var i = 1; i < pts.length; i++) {
        total += (pts[i] - pts[i - 1]).distance;
      }
      var left = total * f;
      p.moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < pts.length && left > 0; i++) {
        final d = (pts[i] - pts[i - 1]).distance;
        final k = math.min(1.0, left / d);
        final q = pts[i - 1] + (pts[i] - pts[i - 1]) * k;
        p.lineTo(q.dx, q.dy);
        left -= d;
      }
    }
    return p;
  }

  /// Fury's seam cracks: dark-edged, amber, arc-white at their core in fury,
  /// growing along their length with `crack` and spreading at the defeat.
  static void cracks(Canvas c, GargoyleBodyPose body) {
    final p = body.finite;
    final level = math.max(p.crack, p.damage * .45);
    if (level <= 0) return;
    final q = (level * 12).round();
    if (q == 0) return;
    final path = _lru(_crackCache, q, () => _crackPath(q / 12));
    final t = p.tone;
    GargoyleKit.crack(c, path, t, width: .06, alpha: (.6 + level).clamp(0.0, 1.0));
  }

  // --------------------------------------------------------------- steam --

  /// A puff: a cumulus of three overlapping circles (unit size), one fill.
  static final Path _cloud = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1))
    ..addOval(Rect.fromCircle(center: const Offset(-.62, .26), radius: .62))
    ..addOval(Rect.fromCircle(center: const Offset(.60, .20), radius: .56))
    ..addOval(Rect.fromCircle(center: const Offset(.08, -.50), radius: .52));

  static final Path _hoods = () {
    final p = Path();
    for (final port in GargoyleLayout.steamPorts) {
      GargoyleKit.poly([
        _o(port.dx - .17, port.dy + .05),
        _o(port.dx - .12, port.dy - .09),
        _o(port.dx + .12, port.dy - .09),
        _o(port.dx + .17, port.dy + .05),
      ], into: p);
    }
    return p;
  }();
  static final Path _hoodSlits = _lines([
    for (final port in GargoyleLayout.steamPorts) (_o(port.dx - .09, port.dy - .02), _o(port.dx + .09, port.dy - .02)),
  ]);

  /// The vent: two brass hoods with glowing slits, shown while the lamp is open
  /// or steaming, and soft puffs that are born one after another, rise, drift
  /// back and thin.
  static void steam(Canvas c, GargoyleBodyPose body) {
    final p = body.finite, t = p.tone;
    if (p.lamp <= .02 && p.steam <= 0) return;
    final hot = math.max(p.lamp, p.steam);
    c.drawPath(_hoods, GargoyleKit.fill(t.lit(GargoylePalette.brass)));
    c.drawPath(_hoods, GargoyleKit.line(GargoylePalette.ink, GargoyleLayout.inkDetail));
    c.drawPath(_hoodSlits, GargoyleKit.line(t.lit(GargoylePalette.lampCore), .05, hot));
    if (p.steam <= 0) return;
    final phase = p.vent < 0 ? .5 : p.vent;
    var j = 0;
    for (final port in GargoyleLayout.steamPorts) {
      for (var k = 0; k < 3 - j; k++) {
        final born = .03 + k * .22 + j * .08;
        final age = (phase - born) / .6;
        if (age <= 0 || age >= 1) continue;
        final rise = age * 1.7, drift = age * (.40 + .25 * j) + math.sin(age * 5 + j * 2 + k) * .06;
        final r = .20 + age * .38 + k * .04;
        final fade = math.min(1.0, age * 6) * (1 - age * age);
        // hot from the vent, cooling to a pale lilac as it rises
        final tint = Color.lerp(const Color(0xffffe2b0), Color.lerp(GargoylePalette.steam, t.sky, .25)!, math.min(1.0, age * 2.4))!;
        c.save();
        c.translate(port.dx + drift, port.dy - .12 - rise);
        c.scale(r);
        c.drawPath(_cloud, GargoyleKit.fill(t.lit(tint), .66 * fade));
        c.restore();
      }
      j++;
    }
  }
}
