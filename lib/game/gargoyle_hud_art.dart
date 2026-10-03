import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'gargoyle_kit.dart';

/// The Searchlight Gargoyle's health plate dressing: a stepped Art Deco plate
/// of brushed steel in a brass rim (the same stepped silhouette as his
/// ledge), a brass octagon medallion holding his searchlight lens (shuttered
/// by louvres until the lamp opens, white-hot in fury, with his second, smaller
/// lens beside it that only burns in fury), an amber gauge cut into brass
/// segments, a brass spool at the fury mark (it burns arc-white and splits the
/// plate with a crack when the second beam lights), and the tags that hang from
/// the plate: LAMP OPEN / SHOOT! while the vent window is open and a SPOTTED!
/// flash when a beam catches the bird.
///
/// `BossHealthBarArt` keeps the layout, timeline and numbers; these are only
/// his brushstrokes (the patch `ny-ws/patches/g7-hud.patch` calls them from
/// the gargoyle branches). Everything is drawn from the values it is given, so
/// paused, replayed and captured frames repeat. Nothing here blurs, opens a
/// layer or a clip, or lays out text per frame: the shapes that only depend on
/// the layout are built once, the four gradients are cached (steel, amber,
/// fury amber, lens), brass is flat bands (the palette's hard three stops) and
/// the tag's words are laid out once.
///
/// Budget (`test/gargoyle_hud_test.dart`): the bar plus its tags <= 60 ops, 4
/// shaders, 0 clips, 0 layers, no blur, in every state.
abstract final class GargoyleHudArt {
  static const ink = GargoylePalette.ink;
  static const cream = Color(0xfffff2c9);

  /// The name the bar shows: the full name overflows the 84 px field.
  static const label = 'GARGOYLE';

  /// The tags' words (the lamp's hint, laid out once).
  static const lampWords = 'LAMP OPEN', shootWords = ' · SHOOT!';
  static const spottedWords = 'SPOTTED!';

  /// How long the SPOTTED! tag shows after a beam catches the bird, and how
  /// long the fury mark's crack burns white-hot before it cools to an ember.
  static const spottedSeconds = 1.0, crackHeatSeconds = .45;

  /// How many brass segments the gauge is cut into.
  static const segments = 8;

  /// Steel plate, as [lit, main, shade, deep].
  static const _steel = [
    GargoylePalette.steelLit,
    GargoylePalette.steel,
    GargoylePalette.steelMid,
    GargoylePalette.steelDeep,
  ];
  static const _panel = Color(0xff1f2745);

  /// The gauge's colours as [light, main, deep]: brass to amber (fury: the
  /// arc's white-hot to orange).
  static List<Color> ramp({bool fury = false}) => fury
      ? const [
          GargoylePalette.arcCore,
          GargoylePalette.lampAmber,
          GargoylePalette.lampDeep,
        ]
      : const [
          GargoylePalette.brassLit,
          GargoylePalette.brass,
          GargoylePalette.brassDeep,
        ];

  // -------------------------------------------------------------- paints --

  static Paint _solid(Color color, [double alpha = 1]) =>
      GargoyleKit.fill(color, alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0);

  static Paint _stroke(Color color, double width, [double alpha = 1]) =>
      GargoyleKit.line(color, width, alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0);

  /// A cached gradient shader (layout-keyed: it only rebuilds on a resize),
  /// drawn at [alpha] through a fresh paint.
  static Paint _shaded(Object key, Paint Function() make, [double alpha = 1]) =>
      Paint()
        ..shader = GargoyleKit.cached(key, make).shader
        ..color = Color.fromRGBO(255, 255, 255, alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0);

  // ------------------------------------------------------ text, laid once --

  static final Map<Object, TextPainter> _texts = {};

  /// How many laid-out text painters are kept (tests: bounded, nothing is laid
  /// out per frame).
  static int get textCacheSize => _texts.length;

  static TextPainter _text(Object key, List<InlineSpan> spans, double size, {double spacing = 0}) {
    final id = (key, size, spacing);
    var p = _texts[id];
    if (p == null) {
      if (_texts.length >= 16) _texts.clear();
      p = _texts[id] = TextPainter(
        text: TextSpan(children: spans, style: heading(size, color: cream).copyWith(letterSpacing: spacing)),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return p;
  }

  static TextSpan _span(String text, Color color, double size, {List<Shadow>? shadows}) => TextSpan(
    text: text,
    style: heading(size, color: color).copyWith(shadows: shadows),
  );

  // ------------------------------------------------------ static geometry --

  // What only depends on the layout is built once per layout.
  static Rect? _stripFor, _barFor;
  static double _uFor = 0;
  static Path _silhouette = Path(), _body = Path(), _lit = Path(), _rim = Path();
  static Path _panels = Path(), _panelEdge = Path(), _studs = Path();
  static Path _crack = Path(), _spool = Path(), _spoolCore = Path(), _louvres = Path();
  static Rect _nameRect = Rect.zero, _countRect = Rect.zero;

  // The plate's two steps toward each end: how far in each starts and how much
  // shorter the plate is there (in u).
  static const _s1 = 3.2, _s2 = 6.4, _v1 = 6.4, _v2 = 3.2;

  /// The plate's outline: a stepped Art Deco bar, full height in the middle and
  /// stepping down twice toward each end.
  static Path _outline(Rect r, double u) {
    final s1 = _s1 * u, s2 = _s2 * u, v1 = _v1 * u, v2 = _v2 * u;
    final l = r.left, t = r.top, rt = r.right, b = r.bottom;
    return Path()
      ..moveTo(l + s2, t)
      ..lineTo(rt - s2, t)
      ..lineTo(rt - s2, t + v2)
      ..lineTo(rt - s1, t + v2)
      ..lineTo(rt - s1, t + v1)
      ..lineTo(rt, t + v1)
      ..lineTo(rt, b - v1)
      ..lineTo(rt - s1, b - v1)
      ..lineTo(rt - s1, b - v2)
      ..lineTo(rt - s2, b - v2)
      ..lineTo(rt - s2, b)
      ..lineTo(l + s2, b)
      ..lineTo(l + s2, b - v2)
      ..lineTo(l + s1, b - v2)
      ..lineTo(l + s1, b - v1)
      ..lineTo(l, b - v1)
      ..lineTo(l, t + v1)
      ..lineTo(l + s1, t + v1)
      ..lineTo(l + s1, t + v2)
      ..lineTo(l + s2, t + v2)
      ..close();
  }

  static void _buildStrip(Rect strip, double u, Rect bar) {
    if (_stripFor == strip && _uFor == u && _barFor == bar) return;
    _stripFor = strip;
    _barFor = bar;
    _uFor = u;
    _silhouette = _outline(strip, u);
    final inset = strip.deflate(1.2 * u);
    _body = _outline(inset, u);
    // The lit edges: the upper rim of every step, drawn lighter.
    final s1 = _s1 * u, s2 = _s2 * u, v1 = _v1 * u, v2 = _v2 * u;
    final l = inset.left, t = inset.top, rt = inset.right;
    _lit = Path()
      ..moveTo(l, t + v1 + u)
      ..lineTo(l, t + v1)
      ..lineTo(l + s1, t + v1)
      ..lineTo(l + s1, t + v2)
      ..lineTo(l + s2, t + v2)
      ..lineTo(l + s2, t)
      ..lineTo(rt - s2, t)
      ..lineTo(rt - s2, t + v2)
      ..lineTo(rt - s1, t + v2)
      ..lineTo(rt - s1, t + v1)
      ..lineTo(rt, t + v1)
      ..lineTo(rt, t + v1 + u);
    _rim = _body;
    // The recessed panels: the name's and the count's.
    final nameLeft = bar.left - 90 * u, hpRight = bar.right + 42 * u;
    _nameRect = Rect.fromLTRB(nameLeft - 2.4 * u, strip.top + 4.2 * u, bar.left - 5 * u, strip.bottom - 4.2 * u);
    _countRect = Rect.fromLTRB(hpRight - 36 * u, strip.top + 4.2 * u, hpRight + 3.2 * u, strip.bottom - 4.2 * u);
    final panels = Path(), edge = Path();
    for (final r in [_nameRect, _countRect]) {
      panels.addRRect(RRect.fromRectAndRadius(r, Radius.circular(1.6 * u)));
      edge
        ..moveTo(r.left + 1.2 * u, r.top + .4 * u)
        ..lineTo(r.right - 1.2 * u, r.top + .4 * u);
    }
    _panels = panels;
    _panelEdge = edge;
    // Brass studs where the steel pilasters between the panels stand.
    final studs = Path();
    for (final x in [(_nameRect.right + bar.left - 1.4 * u) / 2, (bar.right + 1.4 * u + _countRect.left) / 2]) {
      for (final y in [strip.top + 4.6 * u, strip.bottom - 4.6 * u]) {
        studs.addOval(Rect.fromCircle(center: Offset(x, y), radius: .85 * u));
      }
    }
    _studs = studs;
    // The louvre gauge at the name panel's right: four slats that open with
    // the lamp.
    final louvres = Path();
    for (var i = 0; i < 4; i++) {
      louvres.addRect(
        Rect.fromLTWH(_nameRect.right - 4.2 * u - (3 - i) * 3.3 * u - 1.9 * u, strip.center.dy - 4.2 * u, 1.9 * u, 8.4 * u),
      );
    }
    _louvres = louvres;
    // The fury crack: a jagged fissure through the plate at the gauge's
    // middle (where the spool is), with four short branches.
    final fx = bar.center.dx, fy = strip.center.dy;
    _crack = Path()
      ..moveTo(fx + .6 * u, strip.top - .3 * u)
      ..lineTo(fx - 2.2 * u, strip.top + 3.4 * u)
      ..lineTo(fx + 1.8 * u, fy - 5.6 * u)
      ..lineTo(fx - 1.4 * u, fy - 1.8 * u)
      ..lineTo(fx + 1.8 * u, fy + 1.9 * u)
      ..lineTo(fx - 1.8 * u, fy + 5.6 * u)
      ..lineTo(fx + 2.2 * u, strip.bottom - 3.2 * u)
      ..lineTo(fx - .6 * u, strip.bottom + .3 * u)
      ..moveTo(fx - 2.2 * u, strip.top + 3.4 * u)
      ..lineTo(fx - 6.4 * u, strip.top + 1.2 * u)
      ..moveTo(fx + 1.8 * u, fy - 5.6 * u)
      ..lineTo(fx + 6.2 * u, fy - 7.2 * u)
      ..moveTo(fx - 1.4 * u, fy - 1.8 * u)
      ..lineTo(fx - 5.4 * u, fy - 3 * u)
      ..moveTo(fx + 1.8 * u, fy + 1.9 * u)
      ..lineTo(fx + 5.6 * u, fy + 3.2 * u)
      ..moveTo(fx + 2.2 * u, strip.bottom - 3.2 * u)
      ..lineTo(fx + 6.6 * u, strip.bottom - 1.2 * u);
    // The spool (the fury mark): caps wider than its stem, drawn about the
    // gauge's middle, tall enough to stand past the gauge's ends.
    final half = bar.height / 2 + 3.6 * u;
    final cap = 3.1 * u, stem = 1.7 * u, step = 1.9 * u;
    _spool = Path()
      ..moveTo(fx - cap, fy - half)
      ..lineTo(fx + cap, fy - half)
      ..lineTo(fx + cap, fy - half + step)
      ..lineTo(fx + stem, fy - half + step)
      ..lineTo(fx + stem, fy + half - step)
      ..lineTo(fx + cap, fy + half - step)
      ..lineTo(fx + cap, fy + half)
      ..lineTo(fx - cap, fy + half)
      ..lineTo(fx - cap, fy + half - step)
      ..lineTo(fx - stem, fy + half - step)
      ..lineTo(fx - stem, fy - half + step)
      ..lineTo(fx - cap, fy - half + step)
      ..close();
    _spoolCore = Path()
      ..moveTo(fx, fy - half + 1.2 * u)
      ..lineTo(fx, fy + half - 1.2 * u);
  }

  // -------------------------------------------------------------- plate --

  /// The plate: drop shadow, ink edge, the steel body with its specular streak
  /// and two recessed panels, brass studs and chevrons, and the brass rim that
  /// goes arc-white on a hit, burns amber in fury and dulls when he is down.
  static void frame(
    Canvas c,
    Rect strip,
    Rect bar,
    double u, {
    required bool fury,
    required bool defeated,
    required double wave,
    required double flash,
    double lamp = 0,
    double time = 0,
    bool reduced = false,
  }) {
    if (!strip.isFinite || !bar.isFinite || !u.isFinite || u <= 0) return;
    _buildStrip(strip, u, bar);
    c.save();
    c.translate(0, 1.5 * u);
    c.drawPath(_silhouette, _solid(ink, .38));
    c.restore();
    c.drawPath(_silhouette, _solid(ink));
    c.drawPath(
      _body,
      _shaded(
        ('steel', strip.top, strip.bottom),
        () => GargoyleKit.linear(
          Offset(0, strip.top),
          Offset(0, strip.bottom),
          _steel,
          const [0, .3, .62, 1],
        ),
      ),
    );
    // The specular streak along the top, and the lamp's light spilling onto
    // the steel from below (it flares in fury).
    c.drawLine(
      Offset(strip.left + 7 * u, strip.top + 1.9 * u),
      Offset(strip.right - 7 * u, strip.top + 1.9 * u),
      _stroke(const Color(0xffe8f1fa), .7 * u, defeated ? .25 : .6),
    );
    c.drawPath(_panels, _solid(_panel));
    c.drawPath(_panelEdge, _stroke(const Color(0xff0f1430), .8 * u, .8));
    // The louvres: dark steel slats, lit amber from behind as the lamp opens.
    c.drawPath(_louvres, _solid(defeated ? GargoylePalette.steelCore : const Color(0xff39476f)));
    if (lamp > 0 && !defeated) {
      c.drawPath(_louvres, _solid(Color.lerp(GargoylePalette.lampDeep, GargoylePalette.lampCore, lamp)!, lamp.clamp(0.0, 1.0)));
    }
    c.drawPath(_studs, _solid(GargoylePalette.brass));
    // The brass rim, in three flat bands: a shade, the brass, a lit top edge.
    final rimTone = defeated
        ? GargoylePalette.brassShade
        : (fury ? Color.lerp(GargoylePalette.lampDeep, GargoylePalette.arcBody, wave * .6)! : GargoylePalette.brass);
    c.save();
    c.translate(0, .35 * u);
    c.drawPath(_rim, _stroke(defeated ? ink : GargoylePalette.brassDeep, 1.5 * u));
    c.restore();
    c.drawPath(_rim, _stroke(rimTone, 1.05 * u));
    if (!defeated) c.drawPath(_lit, _stroke(fury ? GargoylePalette.arcCore : GargoylePalette.brassLit, .55 * u, .95));
    if (flash > 0) {
      c.drawPath(_rim, _stroke(GargoylePalette.arcCore, 1.1 * u, flash.clamp(0.0, 1.0)));
    }
  }

  /// The shudder the plate takes on a hit, [since] seconds after it: about a
  /// pixel, gone in a tenth of a second. Still under Reduced Motion.
  static Offset jolt(double since, double u, {required bool reduced}) {
    if (reduced || !since.isFinite || !u.isFinite || since < 0 || since > .14) {
      return Offset.zero;
    }
    final k = 1 - since / .14;
    return Offset(math.sin(since * 150) * u * k, math.cos(since * 110) * .45 * u * k);
  }

  // ------------------------------------------------------------ medallion --

  /// The lens's one radial gradient (white-hot core, lamp yellow, amber, deep
  /// orange), in unit space: the medallion and the tag share it.
  static Paint _lensPaint() => GargoyleKit.cached(
    'hud.lens',
    () => GargoyleKit.radial(
      Offset.zero,
      1,
      const [GargoylePalette.lampCore, GargoylePalette.lampWarm, GargoylePalette.lampAmber, GargoylePalette.lampDeep],
      const [0, .34, .7, 1],
    ),
  );

  /// A lens disc of [radius] at [at], [alpha] bright.
  static void _lens(Canvas c, Offset at, double radius, double alpha) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = _lensPaint().shader
        ..color = Color.fromRGBO(255, 255, 255, alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0),
    );
    c.restore();
  }

  /// A regular octagon of circumradius [r], a flat side up, as a path about
  /// [at].
  static Path _octagon(Offset at, double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = (i + .5) * math.pi / 4 - math.pi / 2;
      final x = at.dx + math.cos(a) * r, y = at.dy + math.sin(a) * r;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    return p..close();
  }

  static Offset? _crestAt;
  static double _crestR = 0;
  static Path _bezel = Path(), _bezelEdge = Path(), _bezelLit = Path();
  static Path _crestSpokes = Path();

  static void _buildCrest(Offset at, double r) {
    if (_crestAt == at && _crestR == r) return;
    _crestAt = at;
    _crestR = r;
    final big = r * 1.13;
    _bezel = _octagon(at, big);
    _bezelEdge = _octagon(at, big + r * .16);
    // Lit upper-left edges and shaded lower-right edges of the bezel.
    final pts = [
      for (var i = 0; i < 8; i++)
        Offset(
          at.dx + math.cos((i + .5) * math.pi / 4 - math.pi / 2) * big * .92,
          at.dy + math.sin((i + .5) * math.pi / 4 - math.pi / 2) * big * .92,
        ),
    ];
    _bezelLit = Path()
      ..moveTo(pts[5].dx, pts[5].dy)
      ..lineTo(pts[6].dx, pts[6].dy)
      ..lineTo(pts[7].dx, pts[7].dy)
      ..lineTo(pts[0].dx, pts[0].dy);
    // The lens's Fresnel rings and spokes, one path.
    final lens = r * .7;
    final spokes = Path()..addOval(Rect.fromCircle(center: at, radius: lens * .62));
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + .26;
      spokes
        ..moveTo(at.dx + math.cos(a) * lens * .3, at.dy + math.sin(a) * lens * .3)
        ..lineTo(at.dx + math.cos(a) * lens * .98, at.dy + math.sin(a) * lens * .98);
    }
    _crestSpokes = spokes;
  }

  /// The medallion: a brass octagon (the lamp's own housing) round the
  /// searchlight lens, [glow] 0..1 its heat (0.3 shuttered, 1 open), with
  /// [shutter] 0..1 how closed the louvres are across it, and his second,
  /// smaller lens docked on its bezel that only lights in [fury]. [defeated]
  /// leaves both dark and cracked.
  static void crest(
    Canvas c,
    Offset center,
    double radius, {
    required bool fury,
    double glow = .3,
    double shutter = 0,
    bool defeated = false,
    double wave = .5,
  }) {
    if (!center.isFinite || !radius.isFinite || radius <= 0) return;
    final r = radius, u = r / 7.5;
    final g = glow.isFinite ? glow.clamp(0.0, 1.0) : .3;
    _buildCrest(center, r);
    c.drawPath(_bezelEdge, _solid(ink));
    c.drawPath(_bezel, _solid(defeated ? GargoylePalette.brassShade : GargoylePalette.brass));
    if (!defeated) {
      c.drawPath(_bezelLit, _stroke(GargoylePalette.brassLit, .75 * u));
    }
    c.drawCircle(center, r * .84, _solid(GargoylePalette.steelCore));
    final lens = r * .7;
    if (defeated) {
      c.drawCircle(center, lens, _solid(GargoylePalette.steelDeep));
      c.save();
      c.translate(center.dx, center.dy);
      c.scale(lens);
      c.drawPath(_lensCrack, _stroke(ink, .8 * u / lens));
      c.restore();
    } else {
      if (fury) GargoyleKit.glow(c, center, r * 2.0, GargoylePalette.lampAmber, .5 + .2 * wave);
      _lens(c, center, lens, .86 + .14 * g);
      c.drawPath(_crestSpokes, _stroke(GargoylePalette.lampDeep, .5 * u, .55));
      // The shutter: dark louvre slats across the lens, thinner as it opens.
      final closed = shutter.isFinite ? shutter.clamp(0.0, 1.0) : 0.0;
      if (closed > .04) {
        final slats = Path();
        for (var i = -2; i <= 2; i++) {
          final y = center.dy + i * lens * .4;
          final half = math.sqrt(math.max(0.0, lens * lens - (i * lens * .4) * (i * lens * .4)));
          slats.addRect(Rect.fromLTRB(center.dx - half, y - lens * .06 * closed, center.dx + half, y + lens * .06 * closed));
        }
        c.drawPath(slats, _solid(GargoylePalette.steelCore, .8));
      }
      final white = (fury ? .9 : .2 + .7 * g * (1 - closed * .6)).clamp(0.0, 1.0);
      c.drawCircle(center, lens * .3, _solid(GargoylePalette.lampCore, white));
      c.drawCircle(center + Offset(-lens * .34, -lens * .38), lens * .17, _solid(GargoylePalette.white, .9));
      if (fury) c.drawCircle(center, lens, _stroke(GargoylePalette.arcEdge, .9 * u));
    }
    // The second, smaller lens on the bezel's upper right: dark steel until
    // the fury lights it.
    final sat = center + Offset(r * .86, -r * .86);
    final sr = r * .3;
    c.drawCircle(sat, sr + .75 * u, _solid(ink));
    c.drawCircle(sat, sr, _solid(defeated ? GargoylePalette.brassShade : GargoylePalette.brass));
    final lit = fury && !defeated;
    c.drawCircle(
      sat,
      sr * .72,
      _solid(lit ? GargoylePalette.arcCore : GargoylePalette.steelCore),
    );
    if (lit) {
      c.drawCircle(sat, sr * .72, _stroke(GargoylePalette.arcEdge, .5 * u));
    } else if (!defeated) {
      c.drawCircle(sat + Offset(-sr * .22, -sr * .24), sr * .2, _solid(GargoylePalette.steelLit, .75));
    }
  }

  // --------------------------------------------------------------- gauge --

  // A staged gauge is cut in thirds by its marks: nine segments, the marks
  // standing where the third and the sixth dividers would.
  static List<double> _dividers(Rect bar, {bool staged = false}) => [
    for (var k = 1; k < (staged ? 9 : segments); k++)
      if (staged ? k % 3 != 0 : k * 2 != segments) bar.left + bar.width * k / (staged ? 9 : segments),
  ];

  /// The empty gauge: an ink channel inlaid with a brass hairline and cut into
  /// segments by brass dividers.
  static void track(
    Canvas c,
    Rect bar,
    double u, {
    bool fury = false,
    bool defeated = false,
  }) {
    if (!bar.isFinite || !u.isFinite) return;
    final radius = Radius.circular(bar.height / 2);
    final channel = RRect.fromRectAndRadius(bar, radius);
    c.drawRRect(channel.inflate(1.5 * u), _solid(ink));
    c.drawRRect(channel.inflate(.9 * u), _stroke(defeated ? GargoylePalette.brassShade : GargoylePalette.brassDeep, .9 * u));
    c.drawRRect(channel, _solid(GargoylePalette.steelCore));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(bar.left, bar.top + 1.5 * u, bar.right, bar.bottom), radius),
      _solid(_panel),
    );
  }

  /// The brass segments: a groove and a lit ridge at every eighth of the gauge
  /// (but the middle, where the spool stands), over the amber and the empty
  /// channel alike; at every ninth of a [staged] gauge (but its thirds, where
  /// its marks stand). Static shapes, two ops; draw it after [fill] and the
  /// chip.
  static void seams(Canvas c, Rect bar, double u, {bool defeated = false, bool staged = false}) {
    if (!bar.isFinite || !u.isFinite) return;
    if (_segFor != bar || _segU != u || _segStaged != staged) {
      _segFor = bar;
      _segU = u;
      _segStaged = staged;
      final groove = Path(), ridge = Path();
      for (final x in _dividers(bar, staged: staged)) {
        groove
          ..moveTo(x, bar.top + .5 * u)
          ..lineTo(x, bar.bottom - .5 * u);
        ridge
          ..moveTo(x + 1.1 * u, bar.top + 1.2 * u)
          ..lineTo(x + 1.1 * u, bar.bottom - 1.2 * u);
      }
      _grooves = groove;
      _ridges = ridge;
    }
    c.drawPath(_grooves, _stroke(defeated ? GargoylePalette.steelCore : GargoylePalette.brassShade, 1.3 * u, defeated ? .9 : .72));
    c.drawPath(_ridges, _stroke(defeated ? GargoylePalette.steelDeep : GargoylePalette.brass, .95 * u, defeated ? .7 : .95));
  }

  static Rect? _segFor;
  static double _segU = 0;
  static bool _segStaged = false;
  static Path _grooves = Path(), _ridges = Path();

  /// The amber up to [right]: a glossy body in the gauge's ramp, the brass
  /// segments' shade lines over it, a glint that crosses it now and then, and
  /// a lamp-white edge where the health ends. [glow] (0 to 1) lifts it toward
  /// white (the critical pulse); [surge] (0 to 1) is the gauge filling on the
  /// entrance and flares the edge.
  static void fill(
    Canvas c,
    Rect bar,
    double right,
    double u, {
    required double glow,
    required double phase,
    required bool edge,
    bool fury = false,
    double surge = 0,
    bool reduced = false,
  }) {
    if (!bar.isFinite || !right.isFinite || !u.isFinite || right <= bar.left) return;
    final g = (glow.isFinite ? glow.clamp(0.0, 1.0) : 0.0);
    final level = (g * 5).round() / 5;
    final flare = surge.isFinite ? surge.clamp(0.0, 1.0) : 0.0;
    final body = Paint()
      ..shader = GargoyleKit.cached(
        ('amber', bar.top, bar.bottom, fury),
        () {
          final ramp = GargoyleHudArt.ramp(fury: fury);
          return GargoyleKit.linear(
            Offset(0, bar.top),
            Offset(0, bar.bottom),
            fury
                ? [ramp[0], GargoylePalette.arcBody, ramp[1], ramp[2]]
                : [ramp[0], ramp[1], GargoylePalette.brassDeep, GargoylePalette.brassShade],
            fury ? const [0, .26, .62, 1] : const [0, .38, .8, 1],
          );
        },
      ).shader
      ..color = Color.fromRGBO(255, 255, 255, 1);
    final full = right >= bar.right - .5;
    final rect = Rect.fromLTRB(bar.left, bar.top, math.min(right, bar.right), bar.bottom);
    final round = Radius.circular(bar.height / 2);
    c.drawRRect(
      full
          ? RRect.fromRectAndRadius(rect, round)
          : RRect.fromRectAndCorners(rect, topLeft: round, bottomLeft: round),
      body,
    );
    if (level > 0) {
      c.drawRect(
        Rect.fromLTRB(bar.left + 1.5 * u, bar.top, rect.right, bar.top + bar.height * .5),
        _solid(GargoylePalette.arcCore, level * .5),
      );
    }
    // A glossy line along the top.
    c.drawLine(
      Offset(bar.left + 2.4 * u, bar.top + 1.4 * u),
      Offset(math.max(bar.left + 2.4 * u, rect.right - 2.2 * u), bar.top + 1.4 * u),
      _stroke(GargoylePalette.white, .9 * u, fury ? .6 : .42),
    );
    // The glint: a searchlight crossing the amber every four seconds.
    if (!reduced && phase.isFinite) {
      final t = ((phase % 4.2) / 1.1);
      if (t < 1) {
        final gx = bar.left + (rect.right - bar.left + 10 * u) * t - 5 * u;
        // (A nearly empty gauge is narrower than half the bar's height: the
        // glint then collapses to nothing instead of an inverted clamp.)
        final lo = bar.left + bar.height / 2, hi = math.max(lo, rect.right);
        double x(double v) => v.clamp(lo, hi);
        final skew = 3.2 * u;
        c.drawPath(
          Path()
            ..moveTo(x(gx + skew), bar.top + .8 * u)
            ..lineTo(x(gx + skew + 2.6 * u), bar.top + .8 * u)
            ..lineTo(x(gx + 2.6 * u), bar.bottom - .8 * u)
            ..lineTo(x(gx), bar.bottom - .8 * u)
            ..close(),
          _solid(GargoylePalette.white, .32 * math.sin(t * math.pi)),
        );
      }
    }
    if (edge) {
      // The lens-white edge, and (while the gauge fills on the entrance) the
      // light that leaks off it.
      final spread = (3.4 + 5.5 * flare) * u;
      if (flare > .02) {
        c.drawRect(
          Rect.fromLTRB(math.max(bar.left, right - spread), bar.top + .6 * u, right, bar.bottom - .6 * u),
          _solid(GargoylePalette.lampCore, .22 + .3 * flare),
        );
      }
      c.drawLine(Offset(right - .5 * u, bar.top), Offset(right - .5 * u, bar.bottom), _stroke(GargoylePalette.arcCore, 1.2 * u));
    }
  }

  /// The damage drain between [from] and [to] (x, the health after the hit and
  /// the health before it still draining): white heat cooling to cream, kept
  /// inside the channel's rounded ends (there is no clip).
  static void chip(
    Canvas c,
    Rect bar,
    double from,
    double to, {
    required double heat,
    required double alpha,
  }) {
    if (!bar.isFinite || !from.isFinite || !to.isFinite) return;
    final left = math.max(bar.left, from - bar.height), right = math.min(bar.right, to);
    if (right <= left) return;
    final round = Radius.circular(bar.height / 2);
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(left, bar.top, right, bar.bottom),
        topLeft: left <= bar.left + .5 ? round : Radius.zero,
        bottomLeft: left <= bar.left + .5 ? round : Radius.zero,
        topRight: right >= bar.right - .5 ? round : Radius.zero,
        bottomRight: right >= bar.right - .5 ? round : Radius.zero,
      ),
      _solid(
        Color.lerp(GargoylePalette.arcBody, GargoylePalette.arcCore, heat.isFinite ? heat.clamp(0.0, 1.0) : 0.0)!,
        alpha,
      ),
    );
  }

  /// The fury mark: a brass spool at the gauge's middle that stands past the
  /// gauge until the fury. When it begins, [furyAge] seconds ago, the second
  /// beam lights: the spool ignites arc-white and a crack races out of it
  /// through the plate, white-hot at first and cooling to a steady ember. A
  /// staged campaign Gargoyle's fury mark stands at [share] (a third) instead.
  static void notch(
    Canvas c,
    Rect strip,
    Rect bar,
    double u, {
    required bool above,
    required bool fury,
    required double wave,
    double furyAge = double.infinity,
    bool defeated = false,
    bool reduced = false,
    double share = .5,
  }) {
    // (Beaten, he has no fury mark: the plate's "DEFEATED" sits there.)
    if (!strip.isFinite || !bar.isFinite || !u.isFinite || defeated) return;
    _buildStrip(strip, u, bar);
    // (The spool and the crack are built about the gauge's middle.)
    final shift = bar.width * (share - .5);
    c.save();
    c.translate(shift, 0);
    if (fury && furyAge >= 0) {
      final grow = reduced ? 1.0 : (furyAge / .16).clamp(0.0, 1.0);
      final cool = reduced ? 1.0 : (furyAge / crackHeatSeconds).clamp(0.0, 1.0);
      final hot = Color.lerp(GargoylePalette.arcCore, GargoylePalette.lampAmber, cool)!;
      // The crack runs out of the middle: the whole fissure grown from the
      // plate's centre line (no clip needed).
      final fy = strip.center.dy;
      if (!reduced && cool < 1) {
        GargoyleKit.glow(c, Offset(bar.center.dx, strip.center.dy), strip.height * .8, GargoylePalette.arcCore, (1 - cool) * .85);
      }
      c.save();
      if (grow < 1) {
        c.translate(0, fy);
        c.scale(1, grow);
        c.translate(0, -fy);
      }
      c.drawPath(_crack, _stroke(ink, 2.9 * u, .7 * (1 - cool * .2)));
      c.drawPath(_crack, _stroke(hot, 1.5 * u));
      c.drawPath(_crack, _stroke(GargoylePalette.arcCore, .6 * u, 1 - cool * .5));
      c.restore();
    }
    // The spool: ink edge, brass (arc-white and orange when it burns).
    final lit = fury;
    c.drawPath(_spool, _stroke(ink, 1.5 * u));
    c.drawPath(
      _spool,
      _solid(
        lit
            ? Color.lerp(GargoylePalette.lampDeep, GargoylePalette.arcBody, wave)!
            : above
            ? GargoylePalette.brass
            : GargoylePalette.brassDeep,
      ),
    );
    c.drawPath(_spoolCore, _stroke(lit ? GargoylePalette.arcCore : GargoylePalette.brassLit, .8 * u, lit ? 1 : .9));
    c.restore();
  }

  // ------------------------------------------------------------- the gauge's
  // fill as the entrance shows it --------------------------------------------

  /// The gauge fill as the entrance shows it: it fills from empty in the 0.6 s
  /// that end the arrival (or, when the cutscene hides the plate, the 0.6 s
  /// after it), never past the boss's real health.
  static double gaugeHp(SkyBoss boss, {required bool reduced}) {
    if (boss.phase == BossPhase.defeated) return 0;
    final full = boss.maxHp.toDouble();
    // A timestamp gone bad reads as the start of the entrance.
    final age = boss.age.isFinite ? boss.age : 0.0;
    final start = boss.cinematic ? boss.arrivalDuration : boss.arrivalDuration - .6;
    final shown = reduced ? 1.0 : BossMotion.ease(((age - start) / .6).clamp(0.0, 1.0));
    return boss.phase == BossPhase.arriving ? full * shown : math.min(boss.hp.toDouble(), full * shown);
  }

  /// 0 to 1 while the gauge fills on the entrance, else 0.
  static double surge(SkyBoss boss, {required bool reduced}) {
    if (reduced || !boss.age.isFinite) return 0;
    final start = boss.cinematic ? boss.arrivalDuration : boss.arrivalDuration - .6;
    final t = (boss.age - start) / .6;
    return t <= 0 || t >= 1 ? 0 : math.sin(t * math.pi);
  }

  /// How closed the lamp's louvres look on the medallion, 0 (open) to 1.
  static double shutter(SkyBoss boss) => 1 - boss.lampOpenness.clamp(0.0, 1.0);

  // ----------------------------------------------------------------- tags --

  // The lamp tag's three rays, in u about its lens.
  static final Path _tagRays = Path()
    ..moveTo(5.6, -2.6)
    ..lineTo(7.2, -3.6)
    ..moveTo(5.9, 0)
    ..lineTo(7.9, 0)
    ..moveTo(5.6, 2.6)
    ..lineTo(7.2, 3.6);

  // The beaten lens's crack, in lens radii about its centre.
  static final Path _lensCrack = Path()
    ..moveTo(-.5, -.9)
    ..lineTo(.05, -.15)
    ..lineTo(-.3, .3)
    ..lineTo(.45, .95);

  /// The tag's height in u; the words are 10.5u (10.5 px at 640 x 360).
  static const tagHeight = 17.0, tagText = 10.5;

  /// How big the lamp tag is at [u]: the words, a lens at its left and a drain
  /// gauge along its foot.
  static Size lampTagSize(double u) {
    final words = _words(tagText * u);
    return Size(words.width + 26 * u, tagHeight * u);
  }

  static TextPainter _words(double size) => _text(
    'lamp',
    [
      _span(lampWords, GargoylePalette.lampWarm, size),
      _span(shootWords, GargoylePalette.white, size),
    ],
    size,
    spacing: size * .035,
  );

  /// The tag under the bar while the lamp is open ("LAMP OPEN · SHOOT!"):
  /// a dark steel tag in a brass rim with a lens that blazes, [pulse] 0..1 on
  /// its rim and rays, and [drain] 1..0 the window's time left along its foot.
  /// Ten-and-a-half pixel words (at 640 x 360) in lamp-white on dark steel.
  static void lampTag(Canvas c, Rect pill, {double pulse = 0, double drain = 1, double alpha = 1}) {
    if (!pill.isFinite || pill.isEmpty) return;
    final a = alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0;
    if (a <= 0) return;
    final u = pill.height / tagHeight;
    final p = pulse.isFinite ? pulse.clamp(0.0, 1.0) : 0.0;
    final body = RRect.fromRectAndRadius(pill, Radius.circular(3.2 * u));
    c.drawRRect(body.inflate(.8 * u), _solid(ink, a));
    c.drawRRect(body, _solid(_panel, a));
    c.drawRRect(
      body.deflate(.35 * u),
      _stroke(Color.lerp(GargoylePalette.brass, GargoylePalette.lampCore, p * .8)!, 1.2 * u, a),
    );
    // The lens at the left: an amber disc in a brass ring, blazing, with its
    // rays pointing at the words.
    final lens = Offset(pill.left + 8.4 * u, pill.center.dy - 1.4 * u);
    c.drawCircle(lens, 4.6 * u, _solid(GargoylePalette.brass, a));
    _lens(c, lens, 3.5 * u, a);
    c.save();
    c.translate(lens.dx, lens.dy);
    c.scale(u);
    c.drawPath(_tagRays, _stroke(GargoylePalette.lampWarm, .85, (.5 + .5 * p) * a));
    c.restore();
    final words = _words(tagText * u);
    words.paint(c, Offset(pill.left + 18 * u, pill.top + 1.5 * u));
    // The window's time left: an amber line draining right to left.
    final track = Rect.fromLTRB(pill.left + 5 * u, pill.bottom - 3.6 * u, pill.right - 5 * u, pill.bottom - 2.2 * u);
    c.drawRect(track, _solid(GargoylePalette.steelCore, a));
    final left = drain.isFinite ? drain.clamp(0.0, 1.0) : 0.0;
    if (left > 0) {
      c.drawRect(
        Rect.fromLTRB(track.left, track.top, track.left + track.width * left, track.bottom),
        _solid(GargoylePalette.lampAmber, a),
      );
    }
  }

  /// The SPOTTED! flash tag: the same tag turned hot, white-hot words on
  /// orange for [since] seconds after a beam caught the bird, popping in and
  /// shaking once (still under Reduced Motion).
  static void spottedTag(Canvas c, Rect pill, {required double since, bool reduced = false}) {
    if (!pill.isFinite || pill.isEmpty || !since.isFinite || since < 0 || since >= spottedSeconds) return;
    final u = pill.height / tagHeight;
    final t = since / spottedSeconds;
    final fade = 1 - BossMotion.ramp(t, .72, 1);
    final pop = reduced ? 1.0 : 1 + .22 * math.pow(1 - BossMotion.ramp(t, 0, .16), 2);
    final shake = reduced ? 0.0 : math.sin(since * 70) * 1.2 * u * (1 - BossMotion.ramp(t, 0, .3));
    final beat = reduced ? 1.0 : (since * 10).floor().isEven ? 1.0 : .55;
    c.save();
    c.translate(pill.center.dx + shake, pill.center.dy);
    c.scale(pop);
    c.translate(-pill.center.dx, -pill.center.dy);
    final body = RRect.fromRectAndRadius(pill, Radius.circular(3.2 * u));
    c.drawRRect(body.shift(Offset(0, 1.4 * u)), _solid(ink, .35 * fade));
    c.drawRRect(body.inflate(.9 * u), _solid(ink, fade));
    c.drawRRect(body, _solid(GargoylePalette.lampDeep, fade));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(pill.left, pill.top, pill.right, pill.center.dy), Radius.circular(3.2 * u)),
      _solid(GargoylePalette.lampAmber, .8 * fade),
    );
    c.drawRRect(body.deflate(.35 * u), _stroke(GargoylePalette.arcCore, 1.3 * u, (.55 + .45 * beat) * fade));
    final size = 11.5 * u;
    final words = _text(
      'spotted',
      [
        _span(
          spottedWords,
          GargoylePalette.white,
          size,
          shadows: [Shadow(color: ink, offset: Offset(0, size * .1)), Shadow(color: ink, offset: Offset(size * .06, size * .1))],
        ),
      ],
      size,
      spacing: size * .05,
    );
    words.paint(c, Offset(pill.center.dx - words.width / 2, pill.center.dy - words.height / 2 - .1 * u));
    c.restore();
  }

  /// How big the SPOTTED! tag is at [u].
  static Size spottedTagSize(double u) => Size(76 * u, tagHeight * u);

  /// The tags that hang from the plate under its left end (clear of his head,
  /// which rises under the gauge's right half), in the one slot: the SPOTTED!
  /// flash (after a beam caught the bird: [spotSince] seconds ago, from
  /// `SkyBoss.lastSpotAt`) over the lamp tag (while his lamp is open). Nothing
  /// during the entrance or after the defeat.
  static void tags(
    Canvas c,
    Rect strip,
    double u,
    SkyBoss boss, {
    required bool reduced,
    double spotSince = double.infinity,
  }) {
    if (!strip.isFinite || !u.isFinite || !boss.age.isFinite) return;
    if (boss.phase != BossPhase.attacking) return;
    final top = strip.bottom - .8 * u, left = strip.left + 9 * u;
    if (spotSince.isFinite && spotSince >= 0 && spotSince < spottedSeconds) {
      final size = spottedTagSize(u);
      spottedTag(c, Rect.fromLTWH(left, top, size.width, size.height), since: spotSince, reduced: reduced);
      return;
    }
    if (!boss.lampOpen) return;
    final size = lampTagSize(u);
    final open = boss.gargoyleCycle - SearchlightGargoyle.ventAt;
    final window = SearchlightGargoyle.period - SearchlightGargoyle.ventAt;
    final into = reduced ? 1.0 : BossMotion.ease((open / .16).clamp(0.0, 1.0));
    final out = 1 - BossMotion.ramp(open, window - .25, window);
    final beat = reduced ? .5 : .5 + .5 * math.sin(boss.age * 9);
    final pop = reduced ? 1.0 : 1 + .1 * (1 - into) + .02 * beat;
    c.save();
    c.translate(left + size.width / 2, top);
    c.scale(pop * (.85 + .15 * into), pop * into);
    c.translate(-size.width / 2, 0);
    lampTag(c, Offset.zero & size, pulse: beat, drain: 1 - open / window, alpha: into * out);
    c.restore();
  }
}
