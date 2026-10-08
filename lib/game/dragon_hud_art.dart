import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import '../l10n/l10n.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'dragon_kit.dart';

/// The Ember Dragon's health plate dressing: an obsidian plate rimmed in
/// gold, with swept horns on its ends and a row of scales, a medallion
/// holding the dragon's burning slit eye, a gauge of lava under a cracked
/// crust (the crust drifts with the flow and breaks into a jagged white-hot
/// edge at the current health), a gold fang on the fury mark that splits the
/// plate with a glowing crack when the fury begins, and a drain that cools
/// from white heat to cinders. While the breath lays the heart open a
/// flame-edged "HEART x2" banner hangs from the plate.
///
/// `BossHealthBarArt` keeps the layout, timeline and numbers; these are only
/// the dragon's brushstrokes. Everything is drawn from the values it is
/// given, so paused, replayed and captured frames repeat. Nothing here blurs,
/// opens a layer or lays out text per frame: the shapes that only depend on
/// the layout are built once, the gradients are cached, and the drifting
/// crust is one template drawn under a moving transform.
abstract final class DragonHudArt {
  static const ink = Color(0xff170d1c), cream = Color(0xfffff2c9);
  static const _obsidian = Color(0xff2c1a33), _obsidianLit = Color(0xff4a3052);
  static const _obsidianDeep = Color(0xff1d1022);
  static const _crust = Color(0xff2a121b), _crustDeep = Color(0xff160a12);
  static const _basalt = Color(0xff3b1620);

  /// How long the health bar's FURY tag shows after the fury begins.
  static const _furyTagSeconds = 2.2;

  /// Lava as [light, main, deep].
  static const lava = [Color(0xffffe27a), Color(0xffff8a34), Color(0xffc9303c)];

  /// The same lava in fury: white-hot on top, blood-dark at the bottom.
  static const furyLava = [
    Color(0xfffff6d2),
    Color(0xffffb23c),
    Color(0xffff5a26),
    Color(0xffb32a3a),
  ];

  // ------------------------------------------------------------- caches --

  // Laid-out text kept between frames (the banner's words change only with
  // the language, which empties it).
  static final Map<Object, TextPainter> _texts = L10n.cache({});

  static TextPainter _text(String value, double size, double spacing) {
    final key = (value, size, spacing);
    var p = _texts[key];
    if (p == null) {
      if (_texts.length >= 16) _texts.clear();
      p = _texts[key] = TextPainter(
        text: TextSpan(
          text: value,
          style: heading(size, color: cream).copyWith(
            letterSpacing: spacing,
            shadows: [Shadow(color: ink, offset: Offset(0, size * .1))],
          ),
        ),
        // Words run their language's way; the banner stays where it is.
        textDirection: L10n.textDirection,
      )..layout();
    }
    return p;
  }

  // ----------------------------------------------------- static geometry --

  // What only depends on the layout is built once per layout.
  static Rect? _stripFor, _barFor;
  static double _uFor = 0;
  static bool _stagedFor = false;
  static Path _scaleRow = Path(), _scaleLit = Path(), _rivets = Path();
  static Path _horns = Path(), _hornLight = Path();
  static Path _seams = Path(), _openSeams = Path(), _tagSeams = Path();
  static Path _flow = Path();
  static Path _teeth = Path(), _tipEdge = Path(), _split = Path();
  static Path _tongues = Path();

  static void _buildStrip(Rect strip, double u) {
    if (_stripFor == strip && _uFor == u) return;
    _stripFor = strip;
    _uFor = u;
    final r = strip.height / 2;
    // Two rows of scales along the upper band, the lower one staggered.
    final row = Path(), lit = Path();
    for (var i = 0; i < 2; i++) {
      final y = strip.top + (2.9 + i * 1.9) * u;
      final shift = i * 2.5 * u;
      for (
        var x = strip.left + r * .7 + shift;
        x < strip.right - r * .7;
        x += 5 * u
      ) {
        row
          ..moveTo(x - 2.5 * u, y)
          ..quadraticBezierTo(x, y + 2.6 * u, x + 2.5 * u, y);
        lit
          ..moveTo(x - 2.3 * u, y - .7 * u)
          ..quadraticBezierTo(x, y + 1.7 * u, x + 2.3 * u, y - .7 * u);
      }
    }
    _scaleRow = row;
    _scaleLit = lit;
    // Studs that divide the plate into its crest, name, gauge and count.
    final studs = Path();
    for (final x in [strip.left + r * 2.05, strip.right - r * .92]) {
      studs.addOval(
        Rect.fromCircle(center: Offset(x, strip.top + 3.2 * u), radius: .8 * u),
      );
      studs.addOval(
        Rect.fromCircle(
          center: Offset(x, strip.bottom - 3.2 * u),
          radius: .8 * u,
        ),
      );
    }
    _rivets = studs;
    // Swept horns on both ends: a long one rising from each upper cap and a
    // shorter talon curling from each lower cap, so the plate looks gripped.
    final horns = Path(), light = Path();
    for (final out in [-1.0, 1.0]) {
      for (final up in [-1.0, 1.0]) {
        final e = out < 0 ? strip.left : strip.right;
        final edge = up < 0 ? strip.top : strip.bottom;
        final k = up < 0 ? 1.0 : .78;
        // [ox] runs beyond the end (negative: inside it), [oy] beyond the
        // edge (up for the horns, down for the talons).
        Offset pt(double ox, double oy) =>
            Offset(e + out * ox * u, edge + up * oy * u);
        final a = pt(-5.6, -1.4), d = pt(-1.6, -5.4);
        final b = pt(2 * k, 1.9 * k), tip = pt(7.4 * k, 3.9 * k);
        final c = pt(2.6 * k, -1);
        horns
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(b.dx, b.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(c.dx, c.dy, d.dx, d.dy)
          ..close();
        final l0 = pt(-2.8, -.1), l1 = pt(2 * k, 1.7 * k);
        final l2 = pt(6.2 * k, 3.3 * k);
        light
          ..moveTo(l0.dx, l0.dy)
          ..quadraticBezierTo(l1.dx, l1.dy, l2.dx, l2.dy);
      }
    }
    _horns = horns;
    _hornLight = light;
  }

  static void _buildBar(Rect bar, double u, {bool staged = false}) {
    if (_barFor == bar && _stagedFor == staged) return;
    _barFor = bar;
    _stagedFor = staged;
    final w = bar.width, h = bar.height;
    // The fury crack: a jagged fissure through the plate at the fury mark,
    // with two short branches, drawn top to bottom about the gauge's centre.
    final fx = bar.center.dx, fy = bar.center.dy;
    final crack = Path()
      ..moveTo(fx + .4 * u, fy - 11.4 * u)
      ..lineTo(fx - 1.3 * u, fy - 8 * u)
      ..lineTo(fx + .9 * u, fy - 5 * u)
      ..lineTo(fx - .8 * u, fy - 1.8 * u)
      ..lineTo(fx + 1.2 * u, fy + 1.6 * u)
      ..lineTo(fx - 1 * u, fy + 5.2 * u)
      ..lineTo(fx + .6 * u, fy + 8.2 * u)
      ..lineTo(fx - .3 * u, fy + 11.4 * u)
      ..moveTo(fx + .9 * u, fy - 5 * u)
      ..lineTo(fx + 3.4 * u, fy - 6.2 * u)
      ..moveTo(fx - .8 * u, fy - 1.8 * u)
      ..lineTo(fx - 3.6 * u, fy - 2.6 * u)
      ..moveTo(fx + 1.2 * u, fy + 1.6 * u)
      ..lineTo(fx + 3.8 * u, fy + 2.6 * u)
      ..moveTo(fx - 1 * u, fy + 5.2 * u)
      ..lineTo(fx - 3.2 * u, fy + 7 * u);
    _split = crack;
    // The crust's fissures: a bold crack on each quarter mark, where the
    // bar's own ticks are, and a short spur off each. Few and large, so the
    // gauge reads as four plates of crust at phone size, not as a pattern.
    // A [staged] gauge is cut in thirds by its marks: its cracks halve each
    // third instead, at the sixths where its ticks are.
    // Over the lava they are dark seams; over the empty channel they are the
    // ember-lit cracks in the crust.
    final seams = Path(), open = Path(), tag = Path();
    // Where the fury tag sits in the emptied track no seam crosses it.
    final tagFree = w > 100 * u ? bar.right - 36 * u : double.infinity;
    for (var k = 1; k <= 3; k++) {
      final x = bar.left + w * (staged ? (2 * k - 1) / 6 : k / 4);
      final lean =
          (k.isEven ? -1 : 1) * (1.4 + DragonHudFx.hash(k, 63) * 1.2) * u;
      final pts = [
        Offset(x - lean * .5, bar.top + .5 * u),
        Offset(x + lean * .45, bar.top + h * .36),
        Offset(x - lean * .45, bar.top + h * .66),
        Offset(x + lean * .5, bar.bottom - .5 * u),
      ];
      final spur = switch (k) {
        1 => Offset(pts[2].dx + 3.6 * u, bar.bottom - .5 * u),
        2 => Offset(pts[1].dx - 3.4 * u, bar.top + .5 * u),
        _ => Offset(pts[2].dx - 3.6 * u, bar.bottom - .5 * u),
      };
      final from = k == 2 ? pts[1] : pts[2];
      final into = x < tagFree ? [seams, open] : [seams, tag];
      for (final path in into) {
        path.moveTo(pts[0].dx, pts[0].dy);
        for (var i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        path
          ..moveTo(from.dx, from.dy)
          ..lineTo(spur.dx, spur.dy);
      }
    }
    _seams = seams;
    _openSeams = open;
    _tagSeams = tag;
    final flow = Path();
    // A few slow streaks of brighter flow along the middle.
    final mid = bar.top + h * .58;
    for (var s = 6 * u; s < w - 10 * u; s += 28 * u) {
      final from = bar.left + s,
          to = from + (8 + DragonHudFx.hash(s.floor(), 43) * 4) * u;
      flow
        ..moveTo(from, mid + 1.1 * u * math.sin(from / (6 * u)))
        ..quadraticBezierTo(
          (from + to) / 2,
          mid - 1.3 * u,
          to,
          mid + 1.1 * u * math.sin(to / (6 * u)),
        );
    }
    _flow = flow;
    // The lava's edge where the health ends: a jagged lip, drawn about its
    // own origin (x 0 = where the smooth lava stops) and moved into place.
    final teeth = Path()
      ..moveTo(0, bar.top)
      ..lineTo(1.5 * u, bar.top)
      ..lineTo(2.6 * u, bar.top + h * .16)
      ..lineTo(.9 * u, bar.top + h * .32)
      ..lineTo(2.8 * u, bar.top + h * .48)
      ..lineTo(1.1 * u, bar.top + h * .64)
      ..lineTo(2.4 * u, bar.top + h * .8)
      ..lineTo(1.3 * u, bar.bottom)
      ..lineTo(0, bar.bottom)
      ..close();
    _teeth = teeth;
    _tipEdge = Path()
      ..moveTo(1.5 * u, bar.top)
      ..lineTo(2.6 * u, bar.top + h * .16)
      ..lineTo(.9 * u, bar.top + h * .32)
      ..lineTo(2.8 * u, bar.top + h * .48)
      ..lineTo(1.1 * u, bar.top + h * .64)
      ..lineTo(2.4 * u, bar.top + h * .8)
      ..lineTo(1.3 * u, bar.bottom);
    // Ten flame tongues for a banner's lower edge, base along y = 0, tips
    // alternately tall and short.
    final t = Path();
    for (var i = 0; i < 10; i++) {
      final tall = i.isEven ? 1.0 : .68;
      t
        ..moveTo(i.toDouble(), 0)
        ..quadraticBezierTo(
          i + .1,
          -tall * .55,
          i + .5 + (i % 3 - 1) * .1,
          -tall,
        )
        ..quadraticBezierTo(i + .82, -tall * .45, i + 1.0, 0)
        ..close();
    }
    _tongues = t;
  }

  // -------------------------------------------------------------- plate --

  /// The plate: drop shadow, swept horns on its ends, ink edge, an obsidian
  /// body with two rows of scales, studs and an ember glow along the lower
  /// edge that flares in fury, and a gold rim that goes white-hot on a hit.
  static void frame(
    Canvas c,
    Rect strip,
    double u, {
    required bool fury,
    required bool defeated,
    required double wave,
    required double flash,
    double time = 0,
    bool reduced = false,
  }) {
    if (!strip.isFinite || !u.isFinite) return;
    _buildStrip(strip, u);
    final pill = RRect.fromRectAndRadius(
      strip,
      Radius.circular(strip.height / 2),
    );
    c.drawRRect(pill.shift(Offset(0, 1.5 * u)), DragonHudFx.solid(ink, .35));
    // The horns sit behind the plate, so only their swept tips show.
    final goldRamp = DragonHudFx.shader(
      ('gold', strip.top, strip.bottom),
      () => DragonKit.linear(
        Offset(0, strip.top - 4 * u),
        Offset(0, strip.bottom + 4 * u),
        const [
          DragonPalette.goldLit,
          DragonPalette.gold,
          DragonPalette.goldDeep,
        ],
        const [0, .45, 1],
      ).shader!,
    );
    c.drawPath(_horns, DragonHudFx.stroke(ink, 1.7 * u));
    c.drawPath(_horns, DragonHudFx.shaded(goldRamp));
    c.drawPath(
      _hornLight,
      DragonHudFx.stroke(DragonPalette.goldLit, .7 * u, .85),
    );
    c.drawRRect(pill, DragonHudFx.solid(ink));
    final body = pill.deflate(1.1 * u);
    c.save();
    c.clipRRect(body, doAntiAlias: false);
    c.drawRect(
      strip,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          ('plate', strip.top, strip.bottom),
          () => DragonKit.linear(
            Offset(0, strip.top),
            Offset(0, strip.bottom),
            const [_obsidianLit, _obsidian, _obsidianDeep],
            const [0, .45, 1],
          ).shader!,
        ),
      ),
    );
    c.drawPath(_scaleLit, DragonHudFx.stroke(_obsidianLit, .6 * u, .5));
    c.drawPath(_scaleRow, DragonHudFx.stroke(ink, .8 * u, .55));
    c.drawPath(_rivets, DragonHudFx.solid(DragonPalette.goldDeep, .9));
    // Ember light seeps up from below, and flares in fury.
    final heat = defeated ? .05 : (fury ? .34 + .2 * wave : .18);
    final glow = Rect.fromLTRB(
      strip.left,
      strip.bottom - strip.height * .5,
      strip.right,
      strip.bottom,
    );
    c.drawRect(
      glow,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          ('glow', glow.top, glow.bottom),
          () => DragonKit.linear(Offset(0, glow.bottom), Offset(0, glow.top), [
            DragonPalette.flame,
            DragonPalette.flame.withValues(alpha: 0),
          ]).shader!,
        ),
        heat,
      ),
    );
    c.restore();
    final rimBase = defeated
        ? const Color(0xffa8e8bc)
        : (fury
              ? Color.lerp(DragonPalette.flame, DragonPalette.flameGold, wave)!
              : null);
    if (rimBase == null) {
      c.drawRRect(
        body,
        DragonHudFx.shaded(goldRamp)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 * u,
      );
    } else {
      c.drawRRect(body, DragonHudFx.stroke(rimBase, 1.1 * u));
    }
    if (flash > 0) {
      c.drawRRect(
        body,
        DragonHudFx.stroke(cream, 1.1 * u, flash.clamp(0.0, 1.0)),
      );
    }
  }

  /// The shudder the plate takes on a hit, [since] seconds after it: about a
  /// pixel, gone in a tenth of a second. Still under Reduced Motion.
  static Offset jolt(double since, double u, {required bool reduced}) {
    if (reduced || !since.isFinite || !u.isFinite || since < 0 || since > .14) {
      return Offset.zero;
    }
    final k = 1 - since / .14;
    return Offset(
      math.sin(since * 150) * u * k,
      math.cos(since * 110) * .45 * u * k,
    );
  }

  // ----------------------------------------------------------- medallion --

  /// The medallion: a gold ring round a small gold circlet with a ruby in its
  /// band, the crown the dragon wears. In fury the socket glows red and the
  /// circlet heats toward flame.
  static void crest(
    Canvas c,
    Offset center,
    double r,
    double u, {
    required bool fury,
  }) {
    if (!center.isFinite || !r.isFinite || !u.isFinite) return;
    final disc = Rect.fromCircle(center: center, radius: r);
    final ring = DragonHudFx.shader(
      ('ring', center, r),
      () => DragonKit.linear(
        disc.topCenter,
        disc.bottomCenter,
        const [
          DragonPalette.goldLit,
          DragonPalette.gold,
          DragonPalette.goldDeep,
        ],
        const [0, .42, 1],
      ).shader!,
    );
    c.drawCircle(center, r + 1.2 * u, DragonHudFx.solid(ink));
    c.drawCircle(center, r, DragonHudFx.shaded(ring));
    // A bevel: the ring's inner shade and a highlight on its upper left.
    c.drawCircle(
      center,
      r * .8,
      DragonHudFx.stroke(DragonPalette.goldShade, .7 * u, .8),
    );
    c.drawArc(
      Rect.fromCircle(center: center, radius: r * .9),
      3.4,
      1.5,
      false,
      DragonHudFx.stroke(DragonPalette.goldLit, .8 * u, .9),
    );
    c.drawCircle(center, r * .7, DragonHudFx.solid(_obsidianDeep));
    if (fury) {
      c.drawCircle(
        center,
        r * .7,
        DragonHudFx.shaded(
          DragonHudFx.shader(
            ('socket', center, r),
            () => DragonKit.radial(center, r * .7, [
              DragonPalette.flameDark.withValues(alpha: .9),
              DragonPalette.flameDark.withValues(alpha: 0),
            ]).shader!,
          ),
        ),
      );
    }
    _buildCrown(center, r);
    c.drawPath(_circlet, DragonHudFx.stroke(ink, .75 * u));
    c.drawPath(
      _circlet,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          ('circlet', center, r, fury),
          () => DragonKit.linear(
            Offset(0, center.dy - r * .4),
            Offset(0, center.dy + r * .3),
            fury
                ? const [
                    DragonPalette.flameCore,
                    DragonPalette.flameGold,
                    DragonPalette.flame,
                  ]
                : const [
                    DragonPalette.goldLit,
                    DragonPalette.gold,
                    DragonPalette.goldDeep,
                  ],
            const [0, .45, 1],
          ).shader!,
        ),
      ),
    );
    // The jewels: a bead on each point and the ruby in the band.
    c.drawPath(_beads, DragonHudFx.solid(DragonPalette.goldLit));
    c.drawPath(
      _bandLine,
      DragonHudFx.stroke(DragonPalette.goldShade, .55 * u, .8),
    );
    final ruby = Offset(center.dx, center.dy + r * .27);
    c.drawCircle(ruby, r * .16, DragonHudFx.solid(ink));
    c.drawCircle(
      ruby,
      r * .12,
      DragonHudFx.solid(fury ? DragonPalette.rubyLit : DragonPalette.ruby),
    );
    c.drawCircle(
      ruby + Offset(-r * .035, -r * .04),
      r * .04,
      DragonHudFx.solid(DragonPalette.white, .9),
    );
  }

  // The circlet only depends on the medallion, so it is built once.
  static Offset? _crownAt;
  static double _crownR = 0;
  static Path _circlet = Path(), _beads = Path(), _bandLine = Path();

  static void _buildCrown(Offset center, double r) {
    if (_crownAt == center && _crownR == r) return;
    _crownAt = center;
    _crownR = r;
    Offset p(double x, double y) =>
        Offset(center.dx + x * r, center.dy + y * r);
    final tips = [p(-.44, -.3), p(0, -.5), p(.44, -.3)];
    final outline = Path()
      ..moveTo(p(-.5, .4).dx, p(-.5, .4).dy)
      ..lineTo(p(-.5, .12).dx, p(-.5, .12).dy)
      ..lineTo(tips[0].dx, tips[0].dy)
      ..lineTo(p(-.22, -.02).dx, p(-.22, -.02).dy)
      ..lineTo(tips[1].dx, tips[1].dy)
      ..lineTo(p(.22, -.02).dx, p(.22, -.02).dy)
      ..lineTo(tips[2].dx, tips[2].dy)
      ..lineTo(p(.5, .12).dx, p(.5, .12).dy)
      ..lineTo(p(.5, .4).dx, p(.5, .4).dy)
      ..close();
    _circlet = outline;
    final beads = Path();
    for (final t in tips) {
      beads.addOval(Rect.fromCircle(center: t, radius: r * .1));
    }
    _beads = beads;
    _bandLine = Path()
      ..moveTo(p(-.5, .13).dx, p(-.5, .13).dy)
      ..lineTo(p(.5, .13).dx, p(.5, .13).dy);
  }

  // --------------------------------------------------------------- gauge --

  /// The empty gauge: a cooled crust of lava in an ink channel, split by a
  /// fissure that still glows dimly (and burns in fury).
  static void track(
    Canvas c,
    Rect bar,
    double u, {
    bool fury = false,
    bool reduced = false,
    double time = 0,
    double furyAge = double.infinity,
    bool staged = false,
  }) {
    if (!bar.isFinite || !u.isFinite) return;
    _buildBar(bar, u, staged: staged);
    final radius = Radius.circular(bar.height / 2);
    final track = RRect.fromRectAndRadius(bar, radius);
    c.drawRRect(track.inflate(1.3 * u), DragonHudFx.solid(ink));
    c.drawRRect(track, DragonHudFx.solid(_crustDeep));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bar.left, bar.top + 1.6 * u, bar.right, bar.bottom),
        radius,
      ),
      DragonHudFx.solid(_crust),
    );
    final ember = fury ? .6 + (reduced ? 0 : .2 * math.sin(time * 5)) : .34;
    // The last stretch of the channel stays clear while the FURY tag shows.
    final tagged = fury && furyAge < _furyTagSeconds;
    final beyond = tagged
        ? 0.0
        : (fury ? ((furyAge - _furyTagSeconds) / .5).clamp(0.0, 1.0) : 1.0);
    for (final (seams, alpha) in [(_openSeams, 1.0), (_tagSeams, beyond)]) {
      if (alpha <= 0) continue;
      c.drawPath(seams, DragonHudFx.stroke(ink, 1.6 * u, .85 * alpha));
      c.drawPath(
        seams,
        DragonHudFx.stroke(
          fury ? DragonPalette.flame : DragonPalette.seam,
          .75 * u,
          ember * alpha,
        ),
      );
    }
  }

  /// The lava up to [right]: a banded body of heat, dark seams where the
  /// crust has cracked over it, streaks of brighter flow drifting along with
  /// [phase], ending in a jagged white-hot edge unless it is full. [surge] (0 to 1) is the
  /// gauge filling on the boss's entrance; it flares the edge.
  static void fill(
    Canvas c,
    Rect bar,
    double right,
    double u,
    List<Color> ramp, {
    required double glow,
    required double phase,
    required bool hotTip,
    bool fury = false,
    double surge = 0,
    bool staged = false,
  }) {
    if (!bar.isFinite || !right.isFinite || !u.isFinite) return;
    _buildBar(bar, u, staged: staged);
    final g = (glow * 6).round() / 6;
    final body = DragonHudFx.shader(('lava', bar.top, bar.bottom, fury, g), () {
      if (fury) {
        return DragonKit.linear(
          Offset(0, bar.top),
          Offset(0, bar.bottom),
          [
            Color.lerp(furyLava[0], DragonPalette.white, g)!,
            furyLava[1],
            furyLava[2],
            furyLava[3],
          ],
          const [0, .3, .68, 1],
        ).shader!;
      }
      return DragonKit.linear(
        Offset(0, bar.top),
        Offset(0, bar.bottom),
        [Color.lerp(lava[0], DragonPalette.white, g)!, lava[1], lava[2]],
        const [0, .5, 1],
      ).shader!;
    });
    // The smooth lava stops a lip short of [right]; the lip is the jagged
    // edge, so a full gauge (no lip) meets the channel's end cleanly.
    final lip = hotTip ? 2.8 * u : 0.0;
    final flat = math.max(bar.left, right - lip);
    final rect = Rect.fromLTRB(bar.left, bar.top, flat, bar.bottom);
    c.drawRect(rect, DragonHudFx.shaded(body));
    if (hotTip) {
      c.save();
      c.translate(flat, 0);
      c.drawPath(_teeth, DragonHudFx.shaded(body));
      c.restore();
    }
    c.save();
    c.clipRect(
      Rect.fromLTRB(
        bar.left,
        bar.top,
        right - (hotTip ? .4 * u : 0),
        bar.bottom,
      ),
    );
    // The flow streaks are one tile, wrapped, drifting with [phase]; the
    // crust's seams lie over them and stay put.
    final w = bar.width, flowAt = (phase * 5.5 * u) % w;
    for (final o in [flowAt, flowAt - w]) {
      c.save();
      c.translate(o, 0);
      c.drawPath(_flow, DragonHudFx.stroke(DragonPalette.flameCore, 1 * u, .4));
      c.restore();
    }
    c.drawPath(_seams, DragonHudFx.stroke(_basalt, 1.4 * u, fury ? .55 : .66));
    c.restore();
    // A glossy line along the top.
    c.drawRect(
      Rect.fromLTRB(
        bar.left + 2 * u,
        bar.top + 1.1 * u,
        math.max(bar.left + 2 * u, right - 2.5 * u),
        bar.top + 2.1 * u,
      ),
      DragonHudFx.solid(DragonPalette.white, fury ? .5 : .32),
    );
    if (hotTip) {
      c.save();
      c.translate(flat, 0);
      c.drawPath(
        _tipEdge,
        DragonHudFx.stroke(DragonPalette.flameCore, 1.3 * u),
      );
      c.restore();
      // The heat that leaks off the edge (wide while the gauge fills).
      final spread = (3.6 + 5 * surge) * u;
      c.drawRect(
        Rect.fromLTRB(
          math.max(bar.left, right - spread),
          bar.top,
          right,
          bar.bottom,
        ),
        DragonHudFx.shaded(
          DragonHudFx.shader(
            ('tip', right - spread, right),
            () =>
                DragonKit.linear(Offset(right - spread, 0), Offset(right, 0), [
                  DragonPalette.flameCore.withValues(alpha: 0),
                  DragonPalette.flameCore.withValues(alpha: 1),
                ]).shader!,
          ),
          .55 + .35 * surge,
        ),
      );
    }
  }

  /// Embers lifting off the lava's edge, out past the plate: a handful of
  /// motes on staggered climbs. Still under Reduced Motion.
  static void motes(
    Canvas c,
    Rect bar,
    double right,
    double u, {
    required double time,
    required bool fury,
    required bool reduced,
    double surge = 0,
  }) {
    if (!bar.isFinite || !right.isFinite || !u.isFinite || !time.isFinite) {
      return;
    }
    if (right <= bar.left + 2 * u) return;
    final count = fury ? 7 : 5;
    final near = Path(), far = Path();
    for (var i = 0; i < count; i++) {
      final life = reduced
          ? .2 + .6 * DragonHudFx.hash(i, 51)
          : (time * (.55 + DragonHudFx.hash(i, 53) * .35) +
                    DragonHudFx.hash(i, 55)) %
                1;
      final x =
          right -
          (DragonHudFx.hash(i, 57) * (surge > 0 ? 6 : 3) - .5) * u +
          (reduced ? 0 : math.sin(time * 3 + i * 2.1) * 1.4 * u) * life;
      final y =
          bar.center.dy - (1 + life * (10 + DragonHudFx.hash(i, 59) * 5)) * u;
      final r = (1.0 - life * .6) * (i.isEven ? 1.15 : .8) * u;
      (i.isEven ? near : far).addOval(
        Rect.fromCircle(center: Offset(x, y), radius: r),
      );
    }
    c.drawPath(near, DragonHudFx.solid(DragonPalette.flameYellow, .95));
    c.drawPath(far, DragonHudFx.solid(DragonPalette.flame, .9));
  }

  /// The damage drain: white heat cooling to cinders.
  static void chip(
    Canvas c,
    Rect area, {
    required double heat,
    required double alpha,
  }) {
    if (!area.isFinite) return;
    c.drawRect(
      area,
      Paint()
        ..color = Color.lerp(
          DragonPalette.flameDark,
          DragonPalette.flameCore,
          heat,
        )!.withValues(alpha: alpha),
    );
  }

  /// The half mark: a gold fang that pokes past the gauge until the fury.
  /// When the fury begins, [furyAge] seconds ago, the fang ignites and a
  /// crack races out of it through the plate: white-hot at first, cooling to
  /// a steady ember. A [staged] campaign dragon's fury mark stands at [share]
  /// (a third) instead of the middle.
  static void halfMark(
    Canvas c,
    Rect bar,
    double u, {
    required bool above,
    required bool fury,
    required double wave,
    double furyAge = double.infinity,
    bool reduced = false,
    double share = .5,
    bool staged = false,
  }) {
    if (!bar.isFinite || !u.isFinite) return;
    _buildBar(bar, u, staged: staged);
    final x = bar.left + bar.width * share;
    final top = bar.top - (above ? 3.2 : 1) * u;
    final fang = Path()
      ..moveTo(x - 2.2 * u, top)
      ..lineTo(x + 2.2 * u, top)
      ..quadraticBezierTo(
        x + 1 * u,
        bar.center.dy,
        x,
        bar.bottom + (above ? 1.5 : 0) * u,
      )
      ..quadraticBezierTo(x - 1 * u, bar.center.dy, x - 2.2 * u, top)
      ..close();
    if (fury && furyAge >= 0) {
      final grow = reduced ? 1.0 : (furyAge / .14).clamp(0.0, 1.0);
      final cool = reduced ? 1.0 : (furyAge / .45).clamp(0.0, 1.0);
      final hot = Color.lerp(
        DragonPalette.flameCore,
        DragonPalette.flame,
        cool,
      )!;
      final half = 11.5 * u * grow;
      c.save();
      c.clipRect(
        Rect.fromLTRB(
          x - 6 * u,
          bar.center.dy - half,
          x + 6 * u,
          bar.center.dy + half,
        ),
      );
      // (The crack is built about the gauge's middle.)
      c.translate(x - bar.center.dx, 0);
      c.drawPath(
        _split,
        DragonHudFx.stroke(
          DragonPalette.flameDark,
          2.6 * u,
          .55 * (1 - cool * .3),
        ),
      );
      c.drawPath(_split, DragonHudFx.stroke(hot, 1.1 * u));
      c.drawPath(
        _split,
        DragonHudFx.stroke(DragonPalette.flameCore, .45 * u, 1 - cool * .55),
      );
      c.restore();
    }
    c.drawPath(fang, DragonHudFx.stroke(ink, 1.2 * u));
    c.drawPath(
      fang,
      DragonHudFx.solid(
        above
            ? DragonPalette.gold
            : fury
            ? Color.lerp(DragonPalette.flame, DragonPalette.flameGold, wave)!
            : DragonPalette.goldDeep,
      ),
    );
    if (above) {
      c.drawLine(
        Offset(x - .9 * u, top + .7 * u),
        Offset(x - .3 * u, bar.center.dy - .6 * u),
        DragonHudFx.stroke(DragonPalette.goldLit, .6 * u, .9),
      );
    }
  }

  // -------------------------------------------------------------- banner --

  /// The gauge fill as the entrance shows it: it fills from empty in the
  /// 0.6 s that end the arrival (or, when the cutscene hides the plate, the
  /// 0.6 s after it), never past the boss's real health.
  static double gaugeHp(SkyBoss boss, {required bool reduced}) {
    if (boss.phase == BossPhase.defeated) return 0;
    final full = boss.maxHp.toDouble();
    // A timestamp gone bad reads as the start of the entrance.
    final age = boss.age.isFinite ? boss.age : 0.0;
    final start = boss.cinematic
        ? boss.arrivalDuration
        : boss.arrivalDuration - .6;
    final shown = reduced
        ? 1.0
        : BossMotion.ease(((age - start) / .6).clamp(0.0, 1.0));
    return boss.phase == BossPhase.arriving
        ? full * shown
        : math.min(boss.hp.toDouble(), full * shown);
  }

  /// 0 to 1 while the gauge fills on the entrance, else 0.
  static double surge(SkyBoss boss, {required bool reduced}) {
    if (reduced || !boss.age.isFinite) return 0;
    final start = boss.cinematic
        ? boss.arrivalDuration
        : boss.arrivalDuration - .6;
    final t = (boss.age - start) / .6;
    return t <= 0 || t >= 1 ? 0 : math.sin(t * math.pi);
  }

  /// The "HEART x2" banner: hangs from the plate's lower edge, edged in
  /// flame, for as long as the breath lays the heart open. It pops in with
  /// the inhale, burns faster as the blast nears, and drops away a moment
  /// after the flame gutters. Still (steady flames) under Reduced Motion.
  /// How much of the HEART x2 banner shows ([show], 0 to 1) and how far it
  /// has popped in ([into]): from the inhale to a quarter second after the
  /// flame. A staged dragon's warm-up does not breathe (its breath cycles
  /// before it grows stronger do not run), so its heart never lies open.
  static ({double show, double into}) heartBannerShow(
    SkyBoss boss, {
    required bool reduced,
  }) {
    const none = (show: 0.0, into: 0.0);
    if (boss.phase != BossPhase.attacking || !boss.age.isFinite) return none;
    final combat = boss.age - boss.arrivalDuration;
    if (!boss.signatureArmed((combat / DragonBreath.period).floor())) {
      return none;
    }
    final cycle = combat % DragonBreath.period;
    final open = cycle - DragonBreath.warnAt;
    final closed = cycle - DragonBreath.endAt;
    final into = open < 0
        ? 0.0
        : reduced
        ? 1.0
        : BossMotion.ease((open / .18).clamp(0.0, 1.0));
    final out = closed > 0 && closed < .25 ? 1 - closed / .25 : 1.0;
    return (show: open >= 0 && closed < .25 ? into * out : 0.0, into: into);
  }

  static void heartBanner(
    Canvas c,
    Rect strip,
    Rect bar,
    double u,
    SkyBoss boss, {
    required bool reduced,
  }) {
    if (!strip.isFinite || !bar.isFinite || !u.isFinite) return;
    final (:show, :into) = heartBannerShow(boss, reduced: reduced);
    if (show <= 0) return;
    _buildBar(bar, u, staged: boss.staged);
    final warn = boss.breathWarning;
    final rate = boss.breathing ? 6.0 : 2.0 + 4 * warn;
    final beat = reduced
        ? .5
        : .5 + .5 * math.sin(boss.age * rate * math.pi * 2);
    // Ten units of type (ten pixels at 640 x 360) beside a small ruby heart.
    final text = _text(L10n.strings.bossBarHeartDouble, 10 * u, .5 * u);
    final icon = 8 * u, gap = 3 * u;
    final w = icon + gap + text.width + 11 * u, h = 13.5 * u;
    final cx = bar.center.dx;
    final top = strip.bottom - 1.2 * u;
    final pop = reduced ? 1.0 : 1 + .16 * (1 - into) + .03 * beat;
    c.save();
    c.translate(cx, top);
    c.scale(pop * (.7 + .3 * show), pop * show);
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w / 2, 0, w, h),
      Radius.circular(2.2 * u),
    );
    // Two links tie it to the plate.
    for (final s in [-1.0, 1.0]) {
      c.drawRect(
        Rect.fromLTWH(s * (w / 2 - 3.6 * u) - .8 * u, -1.2 * u, 1.6 * u, 2 * u),
        DragonHudFx.solid(DragonPalette.goldDeep),
      );
    }
    // The flames lick from the lower edge, each on its own beat.
    final lick = (2.8 + 1.6 * beat + 1.2 * warn) * u;
    // Its glow spills onto the sky under the banner.
    c.save();
    c.translate(0, h + 1 * u);
    c.scale(w * .62, 5.5 * u);
    c.drawCircle(
      Offset.zero,
      1,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          'bannerGlow',
          () => DragonKit.radial(Offset.zero, 1, [
            DragonPalette.flame.withValues(alpha: .5),
            DragonPalette.flame.withValues(alpha: 0),
          ]).shader!,
        ),
        .55 + .45 * beat,
      ),
    );
    c.restore();
    c.save();
    c.translate(-w / 2 + .5 * u, h);
    c.scale((w - 1 * u) / 10, -lick);
    c.save();
    c.scale(1, 1.2);
    c.drawPath(_tongues, DragonHudFx.solid(DragonPalette.flameDark, .95));
    c.restore();
    c.drawPath(_tongues, DragonHudFx.solid(DragonPalette.flame, .98));
    c.scale(1, .6);
    c.drawPath(_tongues, DragonHudFx.solid(DragonPalette.flameYellow, .98));
    c.restore();
    c.drawRRect(box.inflate(.9 * u), DragonHudFx.solid(ink));
    c.drawRRect(
      box,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          ('banner', u),
          () => DragonKit.linear(
            Offset(0, 0),
            Offset(0, h),
            const [_obsidianLit, _obsidian, _obsidianDeep],
            const [0, .5, 1],
          ).shader!,
        ),
      ),
    );
    c.drawRRect(
      box,
      DragonHudFx.stroke(
        Color.lerp(DragonPalette.gold, DragonPalette.flameCore, beat * .6)!,
        .9 * u,
      ),
    );
    // The ruby heart at the left, the words to its right.
    final left = -w / 2 + 5.5 * u;
    c.save();
    c.translate(left + icon / 2, h / 2 + .2 * u);
    c.scale(u * .95);
    c.drawPath(_heart, DragonHudFx.stroke(ink, 1.5));
    c.drawPath(
      _heart,
      DragonHudFx.solid(
        Color.lerp(DragonPalette.ruby, DragonPalette.rubyLit, beat * .7)!,
      ),
    );
    c.drawOval(
      const Rect.fromLTWH(-2.9, -2.4, 2.2, 1.4),
      DragonHudFx.solid(DragonPalette.white, .85),
    );
    c.restore();
    text.paint(c, Offset(left + icon + gap, h / 2 - text.height / 2 + .3 * u));
    c.restore();
  }

  // A heart about 9 units wide, centred on the origin, for the banner.
  static final Path _heart = Path()
    ..moveTo(0, 3.6)
    ..cubicTo(-5.4, .6, -4.4, -3.6, -2, -3.5)
    ..cubicTo(-.9, -3.4, -.2, -2.7, 0, -1.9)
    ..cubicTo(.2, -2.7, .9, -3.4, 2, -3.5)
    ..cubicTo(4.4, -3.6, 5.4, .6, 0, 3.6)
    ..close();
}

/// Paints and gradient shaders shared by the dragon's HUD and set-pieces.
///
/// KIT-REQUEST: hoist into `DragonKit` (a cache of shaders keyed by value,
/// paints whose alpha rides on the paint so one shader serves every fade).
abstract final class DragonHudFx {
  /// A well-mixed 0..1 value for slot [i] and [salt]. (The kit's hash is
  /// linear in [i], so neighbouring slots line up along straight lines.)
  static double hash(int i, [int salt = 0]) {
    var x = (i * 0x9E3779B1 + salt * 0x85EBCA6B + 0x27d4eb2f) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x ^= x >> 16;
    return x / 4294967296.0;
  }

  static final Map<Object, ui.Shader> _shaders = {};

  /// A gradient shader kept between frames under [key]. Alpha is applied by
  /// the paint that uses it, so one shader serves every fade. Bounded: the
  /// map clears itself at 96 entries.
  static ui.Shader shader(Object key, ui.Shader Function() make) {
    var s = _shaders[key];
    if (s == null) {
      if (_shaders.length >= 96) _shaders.clear();
      s = _shaders[key] = make();
    }
    return s;
  }

  // Alpha kept in 0..1; a non-finite value (a timestamp gone bad upstream)
  // draws nothing instead of throwing.
  static double _a(double alpha) =>
      alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0;

  /// A paint of [shader] at [alpha].
  static Paint shaded(ui.Shader shader, [double alpha = 1]) => Paint()
    ..shader = shader
    ..color = DragonPalette.white.withValues(alpha: _a(alpha));

  /// A flat fill of [color] at [alpha] (multiplied into the colour's own).
  static Paint solid(Color color, [double alpha = 1]) => Paint()
    ..color = alpha >= 1 ? color : color.withValues(alpha: _a(color.a * alpha));

  /// A round-capped, round-joined stroke.
  static Paint stroke(Color color, double width, [double alpha = 1]) =>
      solid(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
}
