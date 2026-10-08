import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../l10n/l10n.dart';

import 'neferhoo_kit.dart';

/// Neferhoo's stagecraft: the props and effects of his arrival and his
/// defeat (design §5.6), and the small kit the rest of his presentation
/// shares (the HUD, the name card, the story).
///
///  * the arrival: the pyramid's sealed courier door (a turquoise glyph seal
///    that cracks and slides open on a shaft of light), the dust that pours
///    from it, the sand devil that carries a whirl of dead letters across the
///    dunes to his place, the veil of dust he waits behind, the reveal (a
///    flash, a ring of letters flung out, a shockwave along the ground, a
///    ring of glyph light), the mask catching the sun and HOO-POO-POO;
///  * the defeat: the linen strips that peel off him, the blizzard of dead
///    letters from his satchel, the golden mask popping off and tumbling onto
///    the dunes, the dead letter that lands on his head like a hat, the pop's
///    gold ring, and the lost letter that floats free and glows.
///
/// Ported from the approved design (`egypt-ws/iter5/test/egypt/
/// mummy_present_cine.dart`, `mummy_present_art.dart`): the design draws at a
/// 360-high screen in pixels; everything here takes the screen height [h] and
/// scales those pixels by `h / 360`.
///
/// Pure functions of their arguments (a clock the caller passes: the boss's
/// age or the seconds since the killing blow): no wall clock and no random
/// numbers, so paused, replayed and seeked frames repeat. Under Reduced Motion
/// the callers freeze the clocks that only animate (spins, sways, flutters)
/// and keep the ones that tell the story (what has appeared, what has gone).
/// Nothing here blurs. Gradients and the paths that only depend on the size
/// are built once ([once]); text is laid out once per string and size
/// ([text]).
abstract final class NeferhooStaging {
  // ------------------------------------------------------------ colours --

  /// Papyrus (the cards' writing surface).
  static const paperHi = NeferhooPalette.papyrusHi;
  static const paper = Color(0xfff7e8bb);
  static const paperShade = Color(0xffe6cb8f);
  static const paperEdge = Color(0xffc29650);
  static const paperStain = Color(0xffa97a3c);

  /// Windblown sand (the dust, the devil).
  static const sandHi = NeferhooPalette.papyrusHi;
  static const sandLit = NeferhooPalette.papyrus;
  static const sand = Color(0xffeac58b);
  static const sandShade = Color(0xffd3a468);
  static const sandDeep = Color(0xffa8764a);

  /// A glint's white, the night ink, and the cards' cream.
  static const glint = NeferhooPalette.linenHi;
  static const night = Color(0xff171c39);
  static const creamText = Color(0xfffff2c9);

  /// The keepsake stamp's lapis, the map shield's field (design §5.7).
  static const stamp = Color(0xff2f56d0);

  // ------------------------------------------------------------- curves --

  static double ramp(double v, double a, double b) =>
      v.isFinite ? ((v - a) / (b - a)).clamp(0.0, 1.0) : 0.0;

  static double smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double outBack(double t, [double s = 1.7]) {
    final x = t.clamp(0.0, 1.0) - 1;
    return 1 + x * x * ((s + 1) * x + s);
  }

  static double outCubic(double t) {
    final x = 1 - t.clamp(0.0, 1.0);
    return 1 - x * x * x;
  }

  /// A deterministic 0..1 value from an integer seed (no `Random`).
  static double hash(int n) {
    var x = (n * 0x9E3779B1) & 0x7fffffff;
    x ^= x >> 15;
    x = (x * 0x85EBCA6B) & 0x7fffffff;
    x ^= x >> 13;
    return (x & 0xffff) / 0xffff;
  }

  // ------------------------------------------------------------- paints --

  static double _a(double a) => a.isFinite ? a.clamp(0.0, 1.0) : 0.0;

  static Paint fill(Color c, [double a = 1]) =>
      Paint()..color = c.withValues(alpha: _a(c.a * a));

  static Paint line(Color c, double w, [double a = 1]) => Paint()
    ..color = c.withValues(alpha: _a(c.a * a))
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// A gradient paint whose shader is drawn at [a].
  static Paint grad(Shader s, [double a = 1]) => Paint()
    ..shader = s
    ..color = Color.fromRGBO(255, 255, 255, _a(a));

  static List<double>? _even(int n) =>
      n <= 2 ? null : [for (var i = 0; i < n; i++) i / (n - 1)];

  static Shader lin(Offset a, Offset b, List<Color> colors, [List<double>? stops]) =>
      ui.Gradient.linear(a, b, colors, stops ?? _even(colors.length));

  static Shader rad(Offset c, double r, List<Color> colors, [List<double>? stops]) =>
      ui.Gradient.radial(c, r, colors, stops ?? _even(colors.length));

  // -------------------------------------------------------------- cache --

  static final Map<Object, Object> _memo = _forgetOnLanguage({});

  /// [cache], emptied (its pictures disposed) whenever the language
  /// changes: the cards' pictures and painters hold words and fonts.
  static Map<Object, V> _forgetOnLanguage<V>(Map<Object, V> cache) {
    L10n.language.addListener(() {
      for (final v in cache.values) {
        if (v is ui.Picture) v.dispose();
      }
      cache.clear();
    });
    return cache;
  }

  /// How many built things are kept (tests: bounded).
  static int get cacheSize => _memo.length;

  /// Build-once cache, bounded: cleared when it grows past [_keep] (only a
  /// window resize builds new keys).
  static T once<T extends Object>(Object key, T Function() make) {
    final hit = _memo[key];
    if (hit is T) return hit;
    if (_memo.length >= _keep) {
      for (final v in _memo.values) {
        if (v is ui.Picture) v.dispose();
      }
      _memo.clear();
    }
    final v = make();
    _memo[key] = v;
    return v;
  }

  static const _keep = 96;

  /// [draw] recorded once into a picture, keyed by [key].
  static ui.Picture picture(Object key, void Function(Canvas c) draw) =>
      once(key, () {
        final recorder = ui.PictureRecorder();
        draw(Canvas(recorder));
        return recorder.endRecording();
      });

  // --------------------------------------------------------------- text --

  static final Map<Object, (TextPainter, TextPainter?, double)> _texts =
      _forgetOnLanguage({});

  /// How many laid-out texts are kept (tests: bounded).
  static int get textCacheSize => _texts.length;

  /// Draws [s] with its top at [at] (left, centred or right-aligned on
  /// [at]); returns its size. Fredoka by default (the titles), Nunito for
  /// spoken lines. Laid out once per string, size, colour and alpha step.
  /// With [fit], one line set smaller when it is wider than [fit] (a long
  /// translation on a fixed plate; the fitted size is laid out once too).
  static Size text(
    Canvas c,
    String s,
    Offset at,
    double size,
    Color color, {
    bool nunito = false,
    FontWeight weight = FontWeight.w600,
    double spacing = 0,
    bool center = false,
    bool right = false,
    Color? outline,
    double outlineWidth = 0,
    bool italic = false,
    double? maxWidth,
    double? fit,
  }) {
    if (!size.isFinite || size <= 0 || !at.isFinite) return Size.zero;
    final alpha = (color.a * 16).round();
    if (alpha <= 0) return Size.zero;
    final key = (
      s,
      (size * 4).round(),
      color.withValues(alpha: 1).toARGB32(),
      alpha,
      nunito,
      weight.value,
      (spacing * 8).round(),
      outline?.withValues(alpha: 1).toARGB32(),
      (outlineWidth * 8).round(),
      italic,
      maxWidth?.round(),
      fit?.round(),
    );
    var pair = _texts[key];
    if (pair == null) {
      if (_texts.length >= 256) _texts.clear();
      final fonts = L10n.fonts;
      var points = size, spaced = spacing;
      TextPainter tp(Paint? fg) => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: nunito ? fonts.body : fonts.heading,
            fontFamilyFallback: nunito
                ? fonts.bodyFallback
                : fonts.headingFallback,
            fontSize: points,
            fontWeight: weight,
            letterSpacing: spaced,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            color: fg == null ? color.withValues(alpha: alpha / 16) : null,
            foreground: fg,
          ),
        ),
        // Words run their language's way; where they sit stays the
        // world's (left to right).
        textDirection: L10n.textDirection,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: fit == null ? 2 : 1,
      )..layout(maxWidth: maxWidth ?? double.infinity);
      // (a fitted line keeps the full size's middle)
      var drop = 0.0;
      if (fit != null && fit > 0) {
        final probe = tp(null);
        if (probe.width > fit) {
          final k = fit / probe.width;
          points = size * k;
          spaced = spacing * k;
          drop = probe.height * (1 - k) / 2;
        }
        probe.dispose();
      }
      pair = _texts[key] = (
        tp(null),
        outline != null && outlineWidth > 0
            ? tp(
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = outlineWidth
                  ..strokeJoin = StrokeJoin.round
                  ..color = outline.withValues(
                    alpha: outline.a * alpha / 16,
                  ),
              )
            : null,
        drop,
      );
    }
    final (main, edge, drop) = pair;
    var o = drop == 0 ? at : at + Offset(0, drop);
    if (center) o = at - Offset(main.width / 2, 0);
    if (right) o = at - Offset(main.width, 0);
    edge?.paint(c, o);
    main.paint(c, o);
    return main.size;
  }

  // -------------------------------------------------------------- small --

  /// A 4-point glint star: tapered rays with a hot core.
  static void star(
    Canvas c,
    Offset o,
    double r, {
    double alpha = 1,
    Color color = glint,
    double rot = 0,
    double thin = .14,
  }) {
    if (alpha <= 0 || !(r > 0) || !o.isFinite) return;
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot);
    c.scale(r);
    c.drawPath(once(('star', (thin * 100).round()), () => _star(thin)), fill(color, alpha));
    c.drawCircle(Offset.zero, .2, fill(const Color(0xffffffff), alpha));
    c.restore();
  }

  static Path _star(double thin) {
    final p = Path();
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      final long = k.isEven ? 1.0 : .62;
      final d = Offset(math.cos(a), math.sin(a)), n = Offset(-d.dy, d.dx);
      final m1 = d * long * .22 + n * thin * .5, m2 = d * long * .22 - n * thin * .5;
      p
        ..moveTo(n.dx * thin, n.dy * thin)
        ..quadraticBezierTo(m1.dx, m1.dy, d.dx * long, d.dy * long)
        ..quadraticBezierTo(m2.dx, m2.dy, -n.dx * thin, -n.dy * thin)
        ..close();
    }
    return p;
  }

  /// A small diamond (the cards' flanking marks), [r] its half-diagonal.
  static Path diamond(Offset d, double r) => Path()
    ..moveTo(d.dx, d.dy - r)
    ..lineTo(d.dx + r, d.dy)
    ..lineTo(d.dx, d.dy + r)
    ..lineTo(d.dx - r, d.dy)
    ..close();

  /// A cheap dead letter (5 draws): papyrus, a shade strip, the flap, a clay
  /// seal, the outline; [w] pixels wide.
  static void miniLetter(
    Canvas c,
    Offset o,
    double w, {
    double tilt = 0,
    double alpha = 1,
    double flap = 0,
    bool gold = false,
    double squash = 1,
  }) {
    if (alpha <= 0 || !(w > 0) || !o.isFinite) return;
    final hh = w * .7;
    c.save();
    c.translate(o.dx, o.dy);
    if (squash != 1) c.scale(1, squash);
    c.rotate(tilt);
    final r = Rect.fromCenter(center: Offset.zero, width: w, height: hh);
    final lw = math.max(.9, w * .07);
    c.drawRect(r, fill(NeferhooPalette.papyrus, alpha));
    c.drawRect(
      Rect.fromLTRB(r.left, r.bottom - hh * .3, r.right, r.bottom),
      fill(NeferhooPalette.papyrusShade, .7 * alpha),
    );
    final tip = Offset(0, -hh * .14 * (1 - flap) + hh * .12);
    c.drawPath(
      Path()
        ..moveTo(r.left, 0)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(r.right, 0),
      line(NeferhooPalette.papyrusShade, lw * .8, alpha),
    );
    c.drawCircle(
      Offset(0, hh * .12),
      w * .1,
      fill(gold ? NeferhooPalette.goldLit : NeferhooPalette.seal, alpha),
    );
    c.drawRect(r, line(NeferhooPalette.ink, lw, alpha));
    c.restore();
  }

  /// Soft dust: a shaded body under a lit cap (unit radial gradients built
  /// once, moved by the transform), so a puff has volume and no hard rim.
  /// Two draws.
  static void dustPuff(
    Canvas c,
    Offset o,
    double r,
    double a, {
    Color col = sandLit,
    double stretch = 1,
  }) {
    if (a <= 0 || !(r > 0) || !o.isFinite) return;
    final body = once<Shader>(
      ('puff', col.toARGB32()),
      () => rad(Offset.zero, 1, [
        Color.lerp(col, sandShade, .45)!.withValues(alpha: .95),
        Color.lerp(col, sandShade, .3)!.withValues(alpha: .6),
        col.withValues(alpha: 0),
      ], const [0, .55, 1]),
    );
    final cap = once<Shader>(
      'puff-cap',
      () => rad(Offset.zero, 1, [
        sandHi.withValues(alpha: .95),
        sandHi.withValues(alpha: .5),
        sandHi.withValues(alpha: 0),
      ], const [0, .5, 1]),
    );
    // A big puff gets a dimmer cap, so a far bank never glows like a ball.
    final capA = a * math.min(1.0, 26 / r);
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(r * stretch, r);
    c.drawCircle(const Offset(.04, .1), 1, grad(body, a * .85));
    c.translate(-.16, -.2);
    c.scale(.66);
    c.drawCircle(Offset.zero, 1, grad(cap, capA));
    c.restore();
  }

  // ---------------------------------------------------------- sand devil --

  /// The devil's ring radius (design px) at height share [kk].
  static double _ringR(double kk, double scale) =>
      scale * (13 + 112 * math.pow(kk, 1.05) - 14 * math.sin(kk * math.pi) * .6);

  /// The axis' sway and lean (design px) at height share [kk].
  static double _axisX(double kk, double t, double scale, double lean) =>
      scale * (math.sin(t * 1.9 + kk * 2.7) * 11 * kk + lean * kk * kk * 22);

  /// The parts of the angular dash [a0, a0 + sweep) on the near (lower) or
  /// far half of the ellipse, as (start, sweep).
  static List<(double, double)> _dashParts(double a0, double sweep, bool near) {
    final out = <(double, double)>[];
    final s = a0 % (2 * math.pi);
    final lo = near ? 0.0 : math.pi, hi = near ? math.pi : 2 * math.pi;
    for (final off in const [0.0, -2 * math.pi]) {
      final from = math.max(s + off, lo), to = math.min(s + off + sweep, hi);
      if (to > from) out.add((from, to - from));
    }
    return out;
  }

  static const _rings = 12;

  /// One twisting column of sand from [base] up, its far half ([near] false,
  /// behind him) or its near half. [scale] sizes it, [rise] 0..1 how much
  /// has risen, [strength] its opacity, [t] its spin clock.
  static void devil(
    Canvas c,
    Offset base,
    double h,
    double t, {
    required bool near,
    double scale = 1,
    double rise = 1,
    double strength = 1,
    double lean = 0,
  }) {
    if (strength <= 0 || rise <= 0) return;
    final k = h / 360;
    final height = 236.0 * scale * rise * k;
    final lit = line(near ? sandLit : sandShade, 1, (near ? .78 : .55) * strength);
    final hi = line(sandHi, 1, .75 * strength);
    for (var i = 0; i < _rings; i++) {
      final kk = i / (_rings - 1);
      final y = base.dy - kk * height;
      final r = _ringR(kk, scale) * k * (1 + .05 * math.sin(t * 3.1 + i));
      final cx = base.dx + _axisX(kk, t, scale, lean) * k;
      final rect = Rect.fromCenter(center: Offset(cx, y), width: r * 2, height: r * .48);
      final w = (5.2 - 3 * kk) * math.max(.5, scale) * k;
      lit.strokeWidth = w;
      hi.strokeWidth = w * .4;
      for (var j = 0; j < 2; j++) {
        final a0 = t * (3.4 - 1.5 * kk) + i * .93 + j * math.pi * 1.05;
        for (final (st, sw) in _dashParts(a0, 1.45 + .2 * math.sin(i.toDouble()), near)) {
          c.drawArc(rect, st, sw, false, lit);
          if (near) c.drawArc(rect.deflate(w * .5), st + .1, sw * .7, false, hi);
        }
      }
    }
  }

  /// The column's translucent body (one path): between the two halves and,
  /// fainter, over the figure as a veil.
  static void devilBody(
    Canvas c,
    Offset base,
    double h,
    double t, {
    double scale = 1,
    double rise = 1,
    double alpha = .2,
    double lean = 0,
  }) {
    if (alpha <= 0 || rise <= 0) return;
    final k = h / 360;
    final height = 236.0 * scale * rise * k;
    final p = Path();
    final right = <Offset>[];
    for (var i = 0; i < _rings; i++) {
      final kk = i / (_rings - 1);
      final y = base.dy - kk * height;
      final r = _ringR(kk, scale) * k;
      final cx = base.dx + _axisX(kk, t, scale, lean) * k;
      if (i == 0) {
        p.moveTo(cx - r, y);
      } else {
        p.lineTo(cx - r, y);
      }
      right.add(Offset(cx + r, y));
    }
    for (final q in right.reversed) {
      p.lineTo(q.dx, q.dy);
    }
    p.close();
    final top = base.dy - height - 10 * k;
    c.drawPath(
      p,
      grad(
        lin(Offset(0, top), Offset(0, base.dy), [sand.withValues(alpha: 0), sand, sandShade], const [0, .4, 1]),
        alpha * 2,
      ),
    );
  }

  /// [n] dead letters riding the devil (heights and phases hashed from their
  /// index): the far ones ([near] false) or the near ones.
  static void devilLetters(
    Canvas c,
    Offset base,
    double h,
    double t, {
    required bool near,
    required int n,
    double scale = 1,
    double rise = 1,
    double alpha = 1,
    double size = 25,
    double lean = 0,
  }) {
    if (alpha <= 0) return;
    final k = h / 360;
    final height = 236.0 * scale * rise * k;
    for (var i = 0; i < n; i++) {
      final kk = .12 + .78 * hash(i * 5 + 1);
      final a = t * (2.6 - 1.2 * kk) + i * 2.4;
      final front = math.sin(a) > 0;
      if (front != near) continue;
      final r = _ringR(kk, scale) * 1.02 * k;
      final y = base.dy - kk * height + math.sin(a) * r * .24;
      final x = base.dx + _axisX(kk, t, scale, lean) * k + math.cos(a) * r;
      // Letters turn edge-on as they swing round the far side.
      final side = math.cos(a).abs();
      miniLetter(
        c,
        Offset(x, y),
        size * k * scale.clamp(.55, 1.0) * (.78 + .22 * (front ? 1 : .8)),
        tilt: a * .8 + i,
        alpha: alpha * (.7 + .3 * side),
      );
    }
  }

  /// A swirl of dust puffs round [centre] that hides a figure (drawn over
  /// it): [a] its opacity, [spread] how far it has blown open.
  static void dustVeil(Canvas c, Offset centre, double h, double t, double a, {double spread = 1}) {
    if (a <= 0) return;
    final k = h / 360;
    for (var i = 0; i < 9; i++) {
      final ang = t * (1.5 - .3 * hash(i)) + i * .698;
      final rx = (62 + 44 * hash(i + 11)) * spread * k, ry = (34 + 26 * hash(i + 21)) * spread * k;
      final o = centre + Offset(math.cos(ang) * rx, math.sin(ang) * ry - 10 * spread * k);
      dustPuff(c, o, (40 + 20 * hash(i + 31)) * k, a * (.7 + .3 * hash(i + 41)));
    }
  }

  /// Wind-blown dust across the whole frame: three depths at three speeds,
  /// one path each.
  static void windStreaks(Canvas c, Size size, double t, double intensity) {
    if (intensity <= .01) return;
    final w = size.width, k = size.height / 360;
    const layers = [
      (9, 70.0, 12.0, 1.1, .14, 170.0, 280.0),
      (7, 150.0, 26.0, 1.7, .2, 200.0, 320.0),
      (5, 330.0, 56.0, 2.6, .28, 120.0, 350.0),
    ];
    for (var l = 0; l < layers.length; l++) {
      final (n, v, len, th, al, y0, y1) = layers[l];
      final p = Path();
      for (var i = 0; i < n; i++) {
        final id = l * 20 + i;
        final x = w + 60 * k - ((t * v * k + hash(id) * (w + 180 * k)) % (w + 180 * k));
        final y = (y0 + hash(id + 7) * (y1 - y0) + math.sin(t * 2 + i) * 3) * k;
        p
          ..moveTo(x, y)
          ..lineTo(x + len * k, y + len * k * .04);
      }
      c.drawPath(p, line(l == 2 ? sandHi : sandLit, th * k, al * intensity));
    }
  }

  // ----------------------------------------------------------- the door --

  /// The pyramid's sealed courier door, centred at [o] (screen px): a stone
  /// slab with a turquoise glyph seal that pulses twice, cracks, slides open
  /// on a spill of light and a shaft of turquoise, then closes. [t] is the
  /// arrival's clock; [still] (Reduced Motion) skips the pulses and the
  /// ripple and only fades.
  static void door(Canvas c, Offset o, double h, double t, {bool still = false}) {
    if (t > 3.2 || !o.isFinite) return;
    final k = h / 360;
    // The shaft over the open doorway: a signal seen from the bird's side.
    final shaft = smooth(ramp(t, .55, .95)) * (1 - smooth(ramp(t, 1.5, 2.4)));
    if (shaft > 0) {
      final top = o.dy - 150 * k;
      c.drawPath(
        Path()
          ..moveTo(o.dx - 3 * k, o.dy - 10 * k)
          ..lineTo(o.dx - (15 + 10 * shaft) * k, top)
          ..lineTo(o.dx + (15 + 10 * shaft) * k, top)
          ..lineTo(o.dx + 3 * k, o.dy - 10 * k)
          ..close(),
        grad(
          lin(Offset(0, o.dy - 10 * k), Offset(0, top), [
            NeferhooPalette.magic.withValues(alpha: .55),
            NeferhooPalette.turq.withValues(alpha: .22),
            const Color(0x0035cbb8),
          ], const [0, .45, 1]),
          shaft,
        ),
      );
    }
    final pulse = still
        ? 0.0
        : math.max(0.0, math.sin(((t - .06) / .26).clamp(0.0, 1.0) * math.pi)) +
              math.max(0.0, math.sin(((t - .3) / .22).clamp(0.0, 1.0) * math.pi));
    final open = smooth(ramp(t, .5, .95)) * (1 - smooth(ramp(t, 2.2, 3.0)));
    final lightOn = smooth(ramp(t, .42, .8)) * (1 - smooth(ramp(t, 2.0, 3.0)));
    // The doorway: a dressed-stone frame with a gold lintel.
    final frame = Rect.fromLTRB(o.dx - 6 * k, o.dy - 10 * k, o.dx + 6 * k, o.dy + 8 * k);
    c.drawRect(frame, fill(sandDeep, .85));
    c.drawRect(frame, line(NeferhooPalette.ink, k, .75));
    final hole = Rect.fromLTRB(o.dx - 4 * k, o.dy - 7.5 * k, o.dx + 4 * k, o.dy + 8 * k);
    c.drawRect(hole, fill(const Color(0xff3a2c3c), .95));
    if (open > 0) {
      c.drawRect(hole, fill(NeferhooPalette.turqLit, lightOn * .95));
      c.drawRect(
        Rect.fromLTRB(o.dx - (4 + 3 * open) * k, o.dy + 8 * k, o.dx + (4 + 3 * open) * k, o.dy + 11 * k),
        fill(NeferhooPalette.turqLit, lightOn * .55),
      );
    }
    // The slab, in two halves that slide apart along the crack.
    for (final side in const [-1.0, 1.0]) {
      final dx = side * open * 3.6 * k;
      final slab = Rect.fromLTRB(
        math.min(o.dx, o.dx + side * 4 * k) + dx,
        o.dy - 7.5 * k,
        math.max(o.dx, o.dx + side * 4 * k) + dx,
        o.dy + 8 * k,
      );
      c.drawRect(slab, fill(const Color(0xffa58a7a), 1 - open * .15));
      c.drawRect(slab, line(NeferhooPalette.ink, .9 * k, .8));
    }
    c.drawLine(
      Offset(o.dx - 6.5 * k, o.dy - 10.5 * k),
      Offset(o.dx + 6.5 * k, o.dy - 10.5 * k),
      line(NeferhooPalette.goldLit, 1.5 * k, .95),
    );
    // The glyph seal: a turquoise disc with an eye, pulsing.
    final seal = (1 - open) * (.5 + .5 * pulse);
    if (seal > 0 && open < 1) {
      final e = o + Offset(0, -.5 * k);
      c.drawCircle(e, (6.5 + 4 * pulse) * k, fill(NeferhooPalette.magic, .22 * (.4 + pulse)));
      c.drawCircle(e, 3.3 * k, fill(NeferhooPalette.turq, .95));
      c.drawCircle(e, 3.3 * k, line(NeferhooPalette.ink, .8 * k, .9));
      c.drawOval(Rect.fromCenter(center: e, width: 4.6 * k, height: 2.4 * k), line(NeferhooPalette.turqLit, .8 * k));
      c.drawCircle(e, .8 * k, fill(glint));
    }
    // The crack: a bright zigzag down the slab just before it opens.
    if (t > .36 && t < .6) {
      c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - 7.5 * k)
          ..lineTo(o.dx - 1.4 * k, o.dy - 3 * k)
          ..lineTo(o.dx + 1.2 * k, o.dy + k)
          ..lineTo(o.dx - k, o.dy + 4 * k)
          ..lineTo(o.dx, o.dy + 8 * k),
        line(glint, 1.3 * k, ramp(t, .36, .46)),
      );
    }
    // Light along the face: five short rays.
    if (t > .4 && t < 2.4) {
      final r = ramp(t, .4, .75) * (1 - smooth(ramp(t, 1.8, 2.4)));
      final rays = Path();
      for (var i = -2; i <= 2; i++) {
        rays
          ..moveTo(o.dx + i * 1.8 * k, o.dy - 10 * k)
          ..lineTo(o.dx + i * 8 * r * k, o.dy - (10 + 20 * r * (1 - i.abs() * .2)) * k);
      }
      c.drawPath(rays, line(NeferhooPalette.turqLit, k, .5 * r));
    }
    // A ripple of turquoise runs out along the plateau.
    final rk = ramp(t, .45, 1.35);
    if (!still && rk > 0 && rk < 1) {
      final at = Offset(o.dx, o.dy + 22 * k);
      c.drawOval(
        Rect.fromCenter(center: at, width: (18 + 190 * rk) * k, height: (4 + 22 * rk) * k),
        line(NeferhooPalette.turq, (2.2 * (1 - rk) + .5) * k, .55 * (1 - rk)),
      );
      c.drawOval(
        Rect.fromCenter(center: at, width: (10 + 120 * rk) * k, height: (2 + 14 * rk) * k),
        line(NeferhooPalette.turqLit, 1.1 * (1 - rk) * k, .5 * (1 - rk)),
      );
    }
  }

  // ------------------------------------------------------- linen strips --

  /// One curling strip of linen from [root] along [heading] (radians),
  /// [len] pixels long, curling by [curl]: a ribbon with a lit and a shaded
  /// half, an ink edge, wrap marks and frayed threads at its free end.
  static void linenStrip(
    Canvas c,
    Offset root,
    double heading,
    double len,
    double curl,
    double phase,
    double k, {
    double width = 9,
    double alpha = 1,
    int seg = 14,
  }) {
    if (len < 3 * k || alpha <= 0 || !root.isFinite) return;
    final pts = <Offset>[root];
    final ds = len / seg;
    var p = root;
    for (var j = 1; j <= seg; j++) {
      final s = j / seg;
      final ang = heading + curl * math.pow(s, 1.7) + (.3 + .5 * s) * math.sin(s * 8.5 - phase * 6);
      p = p + Offset(math.cos(ang), math.sin(ang)) * ds;
      pts.add(p);
    }
    final left = <Offset>[], right = <Offset>[];
    for (var j = 0; j < pts.length; j++) {
      final a = pts[math.max(0, j - 1)], b = pts[math.min(pts.length - 1, j + 1)];
      final d = b - a;
      final n = Offset(-d.dy, d.dx) / math.max(.001, d.distance);
      final s = j / seg;
      // The strip twists as it curls: its apparent width breathes.
      final w = width * k * (1 - .45 * s) * (.45 + .55 * math.cos(s * 7 + phase * 3 + curl).abs());
      left.add(pts[j] + n * w / 2);
      right.add(pts[j] - n * w / 2);
    }
    final body = Path()..moveTo(left.first.dx, left.first.dy);
    for (final q in left.skip(1)) {
      body.lineTo(q.dx, q.dy);
    }
    for (final q in right.reversed) {
      body.lineTo(q.dx, q.dy);
    }
    body.close();
    final shade = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      shade.lineTo(q.dx, q.dy);
    }
    for (final q in right.reversed) {
      shade.lineTo(q.dx, q.dy);
    }
    shade.close();
    c.drawPath(body, fill(NeferhooPalette.linenLit, alpha));
    c.drawPath(shade, fill(NeferhooPalette.linenShade, .55 * alpha));
    c.drawPath(body, line(NeferhooPalette.ink, 1.15 * k, .9 * alpha));
    // Wrap marks where it was wound, a lit edge, and frayed threads.
    final ticks = Path();
    for (var j = 2; j < seg; j += 3) {
      ticks
        ..moveTo(left[j].dx, left[j].dy)
        ..lineTo(right[j].dx, right[j].dy);
    }
    c.drawPath(ticks, line(NeferhooPalette.linenDeep, .8 * k, .5 * alpha));
    c.drawLine(left[1], left[seg ~/ 2], line(NeferhooPalette.linenHi, .9 * k, .8 * alpha));
    final tip = pts.last, dir = tip - pts[pts.length - 2];
    final base = math.atan2(dir.dy, dir.dx);
    final threads = Path();
    for (final a in const [-.6, -.1, .4]) {
      threads
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + math.cos(base + a) * 5 * k, tip.dy + math.sin(base + a) * 5 * k);
    }
    c.drawPath(threads, line(NeferhooPalette.linenShade, .9 * k, .9 * alpha));
  }

  // ---------------------------------------------------- the lost letter --

  /// The lost letter in the open (the defeat's "the lost letter is found"):
  /// the rig's own lost-letter prop [paper] (aged papyrus, the faded cord,
  /// the gold hoopoe seal) under a warm glow, ten rays and sparkles. [glow]
  /// 0..1, [t] the sparkles' clock (frozen under Reduced Motion).
  static void lostLetterGlow(
    Canvas c,
    Offset o,
    double w,
    void Function(Canvas c, Offset o, double w, double tilt, double alpha, double phase) paper, {
    double tilt = -.18,
    double glow = 1,
    double t = 0,
    double alpha = 1,
  }) {
    if (alpha <= 0 || !o.isFinite || !(w > 0)) return;
    if (glow > 0) {
      c.drawCircle(
        o,
        w * 1.9,
        grad(
          rad(o, w * 1.9, [
            const Color(0xfffffbe0).withValues(alpha: .85),
            NeferhooPalette.goldHi.withValues(alpha: .55),
            NeferhooPalette.goldLit.withValues(alpha: .2),
            const Color(0x00ffdc6e),
          ], const [0, .28, .6, 1]),
          glow * alpha,
        ),
      );
      final rays = Path();
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5 + t * .4;
        final long = (i.isEven ? .95 : .72) * w * (.85 + .15 * math.sin(t * 3 + i));
        final d = Offset(math.cos(a), math.sin(a));
        rays
          ..moveTo(o.dx + d.dx * w * .62, o.dy + d.dy * w * .62)
          ..lineTo(o.dx + d.dx * long * 1.35, o.dy + d.dy * long * 1.35);
      }
      c.drawPath(rays, line(NeferhooPalette.goldHi, math.max(1.4, w * .045), .6 * glow * alpha));
    }
    paper(c, o, w, tilt, alpha, t);
    if (glow > 0) {
      for (var i = 0; i < 5; i++) {
        final a = t * .9 + i * 1.26;
        final rr = w * (.82 + .18 * math.sin(t * 1.3 + i * 2));
        final p = o + Offset(math.cos(a) * rr, math.sin(a) * rr * .62 - w * .05);
        final tw = .5 + .5 * math.sin(t * 5 + i * 1.7);
        star(
          c,
          p,
          w * (.06 + .07 * tw),
          alpha: (.45 + .5 * tw) * glow * alpha,
          color: i.isEven ? NeferhooPalette.goldHi : NeferhooPalette.magic,
        );
      }
    }
  }
}
