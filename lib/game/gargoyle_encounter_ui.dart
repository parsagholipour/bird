import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart' show FlightSimulation;
import '../domain/sky_boss.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';

/// The Searchlight Gargoyle's cinematic set-pieces: the entrance card that
/// lands on the roar, the stone waking (cracks, flakes, dust), the hit's
/// lamp-flash, the fury's sunburst, the beam's ring round the bird, and the
/// defeat: the statue crumbles to a pile of dust, a flock of pigeons bursts out
/// of it and his two lenses lie lit on the rubble.
///
/// `BossEncounterArt` (G8) owns the staging and the timing; these are only his
/// brushstrokes, one function per set-piece, each a pure function of a clock
/// the caller passes (boss age, seconds since the hit, the kill...). Paused,
/// replayed and captured frames repeat exactly, and under Reduced Motion each
/// piece holds still and only fades. Nothing here blurs, opens a layer or a
/// clip, or lays out text per frame: gradients are cached and unit-sized (moved
/// into place by the canvas transform), the animated shapes are rebuilt into
/// scratch paths, and the card's words are laid out once.
///
/// Geometry: [at] is the chest lamp (the hit circle) in screen pixels, [h] the
/// screen height, and the rig unit is `h * SkyBoss.radius` (the hit radius).
abstract final class GargoyleEncounterUi {
  /// The card's small gold word: GUARDIAN everywhere (the level card's ribbon,
  /// the result and this card), never MINI-BOSS or ENCOUNTER NN.
  static const tag = 'GUARDIAN', epithet = 'WATCHMAN OF THE TALLEST TOWER';

  /// The card's title, on two lines.
  static const titleSmall = 'THE SEARCHLIGHT', titleBig = 'GARGOYLE';

  /// His stage-actor entrance line (what the card shows when the campaign
  /// supplies none; the campaign's own is the same words, `bossLine`) and the
  /// captions.
  static const line = 'Hold still! Nobody ever stays in the light.';
  static const arrivalCaption = 'Something on the ledge is watching…';
  static const fightCaption = 'STAY OUT OF THE LIGHT · SHOOT THE LAMP WHEN IT OPENS';

  /// When the card lands: on the roar's hold (the roar strikes at 2.65 s; the
  /// card follows at 2.85 s), stays to [holdTo] and has folded away by
  /// [goneBy], the end of the entrance.
  static const slamAt = GargoyleTimeline.cardAt, holdTo = 4.2, goneBy = 4.6;

  /// The brush colours: ink, cream and the steel-blue GUARDIAN ribbon (the
  /// guardian's stamp colour on the map's shield and the level card's ribbon).
  static const _ink = GargoylePalette.ink;
  static const cream = Color(0xfffff2c9);
  static const ribbon = Color(0xff6f86a8);
  static const _cardSteel = [Color(0xff6683b3), Color(0xff38497a), Color(0xff222c52)];

  static double _outCubic(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u * u;
  }

  static double _outBack(double t) {
    final x = t.clamp(0.0, 1.0) - 1;
    return 1 + 2.4 * x * x * x + 1.4 * x * x;
  }

  static double _ramp(double v, double from, double to) => BossMotion.ramp(v, from, to);

  /// A well-mixed 0..1 value for slot [i] and [salt] (the kit's own hash is
  /// linear in the slot, so neighbouring slots would line up).
  static double hash(int i, [int salt = 0]) {
    var x = (i * 0x9E3779B1 + salt * 0x85EBCA6B + 0x27d4eb2f) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x ^= x >> 16;
    return x / 4294967296.0;
  }

  // ---------------------------------------------------------------- paints --

  static double _a(double alpha) => alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0;

  static Paint _solid(Color color, [double alpha = 1]) => GargoyleKit.fill(color, _a(alpha));

  static Paint _stroke(Color color, double width, [double alpha = 1]) => GargoyleKit.line(color, width, _a(alpha));

  /// A cached gradient shader, drawn at [alpha] through a fresh paint.
  static Paint _shaded(Object key, Paint Function() make, [double alpha = 1]) => Paint()
    ..shader = GargoyleKit.cached(key, make).shader
    ..color = Color.fromRGBO(255, 255, 255, _a(alpha));

  static final Path _p1 = Path(), _p2 = Path(), _p3 = Path(), _p4 = Path(), _p5 = Path();

  // ------------------------------------------------------------ text, once --

  static final Map<Object, TextPainter> _texts = {};

  /// How many laid-out text painters are kept (tests: bounded, nothing is laid
  /// out per frame).
  static int get textCacheSize => _texts.length;

  static TextPainter _text(
    Object key,
    String value,
    double size, {
    Color color = const Color(0xffe3b454),
    double spacing = 0,
    double? stroke,
    double alpha = 1,
    bool italic = false,
    double? width,
    int maxLines = 1,
    List<Shadow>? shadows,
  }) {
    final bucket = (_a(alpha) * 8).round();
    final id = (key, value, size, spacing, stroke, bucket, color.toARGB32(), italic, width, maxLines, shadows != null);
    var p = _texts[id];
    if (p == null) {
      if (_texts.length >= 512) _texts.clear();
      var style = heading(size, color: color.withValues(alpha: bucket / 8));
      if (italic) style = style.copyWith(fontStyle: FontStyle.italic);
      p = _texts[id] = TextPainter(
        text: TextSpan(
          text: value,
          style: stroke == null
              ? style.copyWith(letterSpacing: spacing, shadows: shadows)
              : style.copyWith(
                  letterSpacing: spacing,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = stroke
                    ..strokeJoin = StrokeJoin.round
                    ..color = _ink.withValues(alpha: bucket / 8),
                ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: width == null ? TextAlign.start : TextAlign.center,
        maxLines: maxLines,
        ellipsis: width == null ? null : '…',
      );
      if (width == null) {
        p.layout();
      } else {
        p.layout(minWidth: width, maxWidth: width);
      }
    }
    return p;
  }

  /// One letter of the name at heat [stage]: -1 cold steel, then white-hot,
  /// lamp-yellow, amber, warm cream, cream.
  static TextPainter _glyph(String ch, double size, int stage, double alpha) => _text(
    'glyph',
    ch,
    size,
    color: const [
      Color(0xff5a6d94),
      Color(0xffffffff),
      GargoylePalette.lampCore,
      GargoylePalette.lampWarm,
      Color(0xffffeec8),
      cream,
    ][stage + 1],
    spacing: 1,
    alpha: alpha,
  );

  // ------------------------------------------------------------- name card --

  /// The arrival's entrance card. During the whole entrance it is the
  /// Gargoyle's own card, so this returns true while he is arriving (the shared
  /// card must not appear early, before the roar) and false at any other time or
  /// for any other boss.
  ///
  /// Nothing shows until [slamAt]. Then a stepped steel plate in a brass rim
  /// unfolds from a line (a marquee opening) as the card lands from a little
  /// larger; his searchlight sweeps across it from his side, right to left,
  /// lighting the name's letters as it passes (white-hot, then amber, then
  /// cream) while the marquee's bulbs chase; the GUARDIAN ribbon (the level
  /// card's language: a swallow-tailed steel-blue ribbon with the guardian's
  /// shield pinned on) hangs over the plate's top edge, and THE SEARCHLIGHT,
  /// the epithet and the quote appear after. The card holds to [holdTo] and
  /// folds away by [goneBy]. [birdY] (screen heights) turns the plate
  /// see-through where the bird flies behind it. Under Reduced Motion the whole
  /// card just fades in and out, steady.
  ///
  /// [line] is the campaign's story quote for him (it arrives already in
  /// quotation marks); without one the card carries his own entrance line
  /// ([GargoyleEncounterUi.line]). It is set under the plate, on its own soft
  /// shade, centred, cream on an ink edge and slanted: at most two lines, as
  /// wide as the plate. The plate itself is exactly the same with or without it.
  static bool nameCard(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    double birdY = .5,
    String? line,
  }) {
    if (!boss.isGargoyle || boss.phase != BossPhase.arriving) return false;
    // The card is ours even when there is nothing trustworthy to draw. A
    // canvas under one pixel high has no room for it (at a height of 0 the
    // card's text layout asks for an impossible size and kills the process).
    if (!boss.age.isFinite ||
        !size.isFinite ||
        !(size.width >= 1) ||
        !(size.height >= 1) ||
        !birdY.isFinite) {
      return true;
    }
    final t = boss.age - slamAt;
    final gone = _ramp(boss.age, holdTo, goneBy);
    if (t < 0 || gone >= 1) return true;
    final reduced = m.reducedMotion;
    final h = size.height, k = h / 360;
    final text = (line == null || line.trim().isEmpty) ? '“${GargoyleEncounterUi.line}”' : line.trim();
    final g = _card(size, boss, text);
    final hf = h * g.f;
    final x0 = g.plate.left, y0 = g.plate.top, wc = g.plate.width, hc = g.plate.height;

    // How much of the card shows: it unfolds (a fade under Reduced Motion).
    final open = reduced ? 1.0 : _outBack(_ramp(t, 0, .2));
    // The contents leave first (by .4 of the fold), then the plate folds to a
    // line and goes.
    final fold = reduced ? 0.0 : BossMotion.ease(_ramp(gone, .25, 1));
    final fade = reduced ? (_ramp(t, 0, .25) * (1 - gone)).clamp(0.0, 1.0) : (1 - _ramp(gone, 0, .4));
    final plateFade = reduced ? fade : (1 - _ramp(gone, .7, 1));
    final reach = math.max(0.0, math.min(open, 1 - fold));
    if (reach <= 0 || plateFade <= 0) return true;

    // See-through where the bird's lane runs behind the card.
    final bird = Offset(FlightSimulation.birdX * h, birdY * h);
    final seen = (.22 + .78 * _clearance(bird, g.plate.inflate(h * .02), h)) * plateFade;
    final centreY = g.plate.center.dy;

    c.save();
    // The slam: the card lands from a little larger, about its middle.
    final slam = reduced || fold > 0 ? 0.0 : 1 - _outCubic(_ramp(t, 0, .12));
    if (slam > 0) {
      final pivot = g.plate.center;
      c.translate(pivot.dx, pivot.dy - h * .012 * slam);
      c.scale(1 + .08 * slam);
      c.translate(-pivot.dx, -pivot.dy);
    }
    // A soft shade round the plate (one radial fade, no edges to see).
    c.save();
    c.translate(g.plate.center.dx + h * .05, g.plate.center.dy + h * .01);
    c.scale(wc / 2 + h * .08, hc / 2 + h * .11);
    c.drawCircle(Offset.zero, 1, _shaded('card.shade', _shadeShader, seen * math.min(1.0, reach * 1.5) * .8));
    c.restore();

    // The plate, unfolding about its centre line.
    c.save();
    c.translate(0, centreY);
    c.scale(1, reach);
    c.translate(0, -centreY);
    c.drawPath(g.body, _stroke(_ink, k * 3.6 * g.f, seen));
    c.drawPath(
      g.body,
      _shaded(
        ('card.steel', g.plate),
        () => GargoyleKit.linear(g.plate.topCenter, g.plate.bottomCenter, _cardSteel, const [0, .46, 1]),
        .94 * seen,
      ),
    );
    c.drawLine(
      Offset(x0 + hf * .05, y0 + hf * .031),
      Offset(x0 + wc - hf * .05, y0 + hf * .031),
      _stroke(const Color(0xffe8f1fa), k * .8, .5 * seen),
    );
    // The rim in three flat bands: a shade, the brass, a lit top edge.
    c.save();
    c.translate(0, k * .9);
    c.drawPath(g.body, _stroke(GargoylePalette.brassDeep, k * 2.6 * g.f, seen));
    c.restore();
    c.drawPath(g.body, _stroke(GargoylePalette.brass, k * 1.7 * g.f, seen));
    c.drawPath(g.lit, _stroke(GargoylePalette.brassLit, k * .8, seen * .95));
    c.drawPath(g.inner, _stroke(GargoylePalette.brass, k * .7, .55 * seen));
    c.drawPath(g.studs, _solid(GargoylePalette.brassLit, seen));
    c.drawPath(g.frieze, _stroke(GargoylePalette.steelCore, k * .8, .5 * seen));
    c.restore();
    if ((open < .55 && !reduced) || fade <= 0) {
      c.restore();
      return true;
    }
    final inside = reduced ? 1.0 : _ramp(open, .55, 1);

    // The marquee's bulbs, chasing.
    final step = reduced ? 0 : (boss.age * 8).floor();
    final lit = _p1..reset(), dim = _p2..reset();
    for (var i = 0; i < g.bulbs.length; i++) {
      ((i + step).isEven ? lit : dim).addOval(Rect.fromCircle(center: g.bulbs[i], radius: g.bulbR));
    }
    c.drawPath(dim, _solid(GargoylePalette.brassDeep, .8 * seen * inside));
    c.drawPath(lit, _solid(GargoylePalette.lampCore, seen * inside));

    // Each line arrives a beat after the last (all at once under Reduced Motion,
    // which only fades the whole card).
    double stagger(double from, double to) => reduced ? 1.0 : _ramp(t, from, to);
    final cx = g.plate.center.dx;
    // The small title above the name.
    final small = g.small(fade * stagger(.2, .42) * inside);
    final smallTop = y0 + hf * .062;
    if (small != null) {
      small.paint(c, Offset(cx - small.width / 2, smallTop));
    }

    // The name: an ink shadow and outline, then each letter lit as his beam
    // passes it, right to left.
    final nameTop = y0 + hf * .108;
    final nameLeft = cx - g.nameW / 2;
    g.outline.paint(c, Offset(nameLeft, nameTop + k * 2.4 * g.f));
    g.outline.paint(c, Offset(nameLeft, nameTop));
    final beam = reduced ? 1.0 : _ramp(t, .1, .52);
    final rightEdge = x0 + wc + hf * .06, span = wc + hf * .12;
    final front = rightEdge - span * beam;
    var latest = -1, latestSince = 9.0;
    for (var i = 0; i < g.glyphs.length; i++) {
      if (g.glyphs[i].trim().isEmpty) continue;
      final mid = nameLeft + g.glyphX[i] + g.glyphW[i] / 2;
      // Seconds since the beam passed this letter (it sweeps right to left).
      final since = reduced ? 1.0 : t - (.1 + .42 * ((rightEdge - mid) / span));
      if (since < 0) {
        _glyph(g.glyphs[i], g.nameSize, -1, fade * inside).paint(c, Offset(nameLeft + g.glyphX[i], nameTop));
        continue;
      }
      final stage = since < .05
          ? 0
          : since < .12
          ? 1
          : since < .22
          ? 2
          : since < .34
          ? 3
          : 4;
      if (since < latestSince) {
        latestSince = since;
        latest = i;
      }
      _glyph(g.glyphs[i], g.nameSize, stage, fade).paint(c, Offset(nameLeft + g.glyphX[i], nameTop));
    }
    final hair = nameTop + g.nameH + hf * .008;
    c.drawLine(
      Offset(cx - wc * .36, hair),
      Offset(cx + wc * .36, hair),
      _stroke(GargoylePalette.brass, k * .9, .7 * seen * stagger(.3, .5)),
    );
    if (latest >= 0 && !reduced && latestSince < .3) {
      // The spark where the beam is.
      GargoyleKit.glow(c, Offset(front, nameTop + g.nameSize * .5), h * .055, GargoylePalette.lampCore, 1 - latestSince / .3);
    }

    // The epithet, between two diamonds.
    final epi = g.epithetPainter(fade * stagger(.34, .6) * inside);
    if (epi != null) {
      final ex = cx - epi.width / 2, ey = hair + hf * .012;
      epi.paint(c, Offset(ex, ey));
      final mid = ey + epi.height * .54;
      _p3.reset();
      for (final s in [-1.0, 1.0]) {
        final dx = cx + s * (epi.width / 2 + hf * .026), r = hf * .0105;
        _p3
          ..moveTo(dx, mid - r)
          ..lineTo(dx + r, mid)
          ..lineTo(dx, mid + r)
          ..lineTo(dx - r, mid)
          ..close();
      }
      c.drawPath(_p3, _solid(GargoylePalette.brass, seen * stagger(.34, .6) * inside));
    }

    // The searchlight crossing the card: a soft amber band from his side,
    // sheared by the canvas transform (so one unit gradient serves it).
    if (!reduced && beam > 0 && beam < 1) {
      final band = h * .1, lean = hc * .26, top = y0 - h * .02, tall = hc + h * .04;
      final fadeBeam = math.sin(beam * math.pi);
      c.save();
      c.transform(Float64List.fromList([band, 0, 0, 0, -lean, tall, 0, 0, 0, 0, 1, 0, front + lean, top, 0, 1]));
      c.drawRect(const Rect.fromLTWH(0, 0, 1, 1), _shaded('card.beam', _beamShader, .7 * fadeBeam));
      c.restore();
      c.drawLine(Offset(front + lean, top), Offset(front, top + tall), _stroke(GargoylePalette.lampAmber, k * 1.4, .5 * fadeBeam));
    }

    // The guardian ribbon hung over the top edge, its shield pinned on.
    final rb = _ramp(t, .04, .22);
    if (rb > 0 || reduced) {
      _ribbon(c, g, fade * (reduced ? 1 : rb), h, k);
    }
    // The slam's flash, gone in a tenth of a second.
    if (!reduced && t < .1) {
      c.drawPath(g.body, _solid(GargoylePalette.lampCore, .5 * (1 - t / .1)));
    }

    // The quote, under the plate on a shade of its own. Its see-through is
    // worked out from its own box, so the plate above does not change when
    // there is a line.
    final box = g.quoteBox;
    final qSeen = (.62 + .38 * _clearance(bird, box, h)) * (reduced ? fade : _ramp(t, .4, .64) * (1 - _ramp(gone, .2, .8)));
    if (qSeen > 0) {
      c.save();
      c.translate(box.center.dx, box.center.dy + h * .004);
      c.scale(box.width / 2 + h * .05, box.height / 2 + h * .045);
      c.drawCircle(Offset.zero, 1, _shaded('card.shade', _shadeShader, qSeen * .9));
      c.restore();
      final at = Offset(box.left, box.top);
      g.quoteEdge(qSeen).paint(c, at);
      g.quoteFill(qSeen).paint(c, at);
    }
    c.restore();
    return true;
  }

  static Paint _shadeShader() => GargoyleKit.radial(
    Offset.zero,
    1,
    const [Color(0xff0d1230), Color(0xff0d1230), Color(0x000d1230)],
    const [0, .66, 1],
  )..color = const Color(0xffffffff);

  static Paint _beamShader() => GargoyleKit.linear(
    const Offset(0, 0),
    const Offset(1, 0),
    const [Color(0x00ffb84a), Color(0xccffd36a), Color(0xe6fff3cf), Color(0xccffd36a), Color(0x00ffb84a)],
    const [0, .3, .5, .7, 1],
  );

  /// How far [point]'s lane runs from [box], 0 (behind it) to 1 (clear), as the
  /// card's see-through reads it.
  static double _clearance(Offset point, Rect box, double h) {
    final gap = Offset(
      math.max(math.max(box.left - point.dx, point.dx - box.right), 0.0),
      math.max(math.max(box.top - point.dy, point.dy - box.bottom), 0.0),
    ).distance;
    final clear = math.max(0.0, gap - FlightSimulation.birdRadius * h);
    return _ramp(clear, h * .005, h * .05);
  }

  /// The GUARDIAN ribbon of the level card, hung over the plate's top edge: a
  /// swallow-tailed ribbon in the guardian's steel-blue with the shield pinned
  /// on its left end (all its shapes are built once with the layout).
  static void _ribbon(Canvas c, _Card g, double alpha, double h, double k) {
    if (alpha <= 0) return;
    final r = g.ribbonRect;
    c.save();
    c.translate(0, k * 1.6);
    c.drawPath(g.ribbonShape, _solid(_ink, .35 * alpha));
    c.restore();
    c.drawPath(
      g.ribbonShape,
      _shaded(
        ('card.ribbon', r),
        () => GargoyleKit.linear(
          r.topCenter,
          r.bottomCenter,
          [Color.lerp(ribbon, const Color(0xffffffff), .3)!, ribbon, Color.lerp(ribbon, _ink, .14)!],
          const [0, .5, 1],
        ),
        alpha,
      ),
    );
    c.drawPath(g.ribbonShape, _stroke(_ink, k * 1.9, alpha));
    final word = g.ribbonWord(alpha);
    word.paint(c, Offset(r.left + g.shieldW + r.height * .26, r.center.dy - word.height / 2 + k * .4));
    // The shield, its rim steel and its field the guardian's colour, with his
    // lens for a charge.
    c.drawPath(g.shieldOuter, _solid(const Color(0xff9db0b9), alpha));
    c.save();
    c.translate(0, -k * .8);
    c.drawPath(g.shieldOuter, _solid(const Color(0xffe9f0f3), alpha));
    c.restore();
    c.drawPath(g.shieldOuter, _stroke(_ink, k * 1.9, alpha));
    c.drawPath(g.shieldInner, _solid(Color.lerp(ribbon, _ink, .12)!, alpha));
    final lens = g.shieldCentre, a = g.shieldW * .5, b = r.height * .66;
    final at = lens.translate(0, -b * .04);
    c.drawCircle(at, a * .38, _solid(GargoylePalette.brass, alpha));
    c.drawCircle(at, a * .27, _solid(GargoylePalette.lampAmber, alpha));
    c.drawCircle(at, a * .12, _solid(GargoylePalette.lampCore, alpha));
  }

  // The card's layout only depends on the viewport and the boss's words, so it
  // is measured, laid out and pathed once.
  static _Card? _cardBuilt;

  static _Card _card(Size size, SkyBoss boss, String quote) {
    final h = size.height, w = size.width;
    final left = math.max(h * .04, w * .075);
    // The plate must stop short of his head, whose beak and visor reach some
    // four and a quarter hit radii left of his lamp.
    final room = boss.x.isFinite ? boss.x * h - 4.3 * h * SkyBoss.radius - h * .016 - left : 1e6;
    final built = _cardBuilt;
    if (built != null && built.size == size && built.quote == quote && built.room == room.round()) return built;
    return _cardBuilt = _Card(size, quote, room);
  }

  /// The plate's rectangle for [boss] at [size] (the staging and the tests use
  /// it to keep the card clear of his head).
  static Rect cardRect(Size size, SkyBoss boss, {String? line}) =>
      _card(size, boss, (line == null || line.trim().isEmpty) ? '“${GargoyleEncounterUi.line}”' : line.trim()).plate;

  // ================================================================ bursts ==

  // Unit shapes -------------------------------------------------------------

  static const _flakeTemplate = [Offset(-1, .1), Offset(-.2, -.85), Offset(1, -.2), Offset(.5, .8), Offset(-.5, .7)];
  // Irregular limestone shards (never a regular polygon): a block, a wedge and
  // a slab.
  static const _shardA = [Offset(-1, .25), Offset(-.3, -.85), Offset(.9, -.4), Offset(.75, .7), Offset(-.55, .8)];
  static const _shardB = [Offset(-.9, .5), Offset(-.7, -.5), Offset(.2, -.85), Offset(1.05, .1), Offset(.35, .75)];
  static const _shardC = [Offset(-1.25, .2), Offset(-.9, -.5), Offset(.9, -.6), Offset(1.25, .15), Offset(.5, .6), Offset(-.6, .55)];
  static const _shards = [_shardA, _shardB, _shardC];
  static const _bladeTemplate = [Offset(-1.6, 0), Offset(-.2, -.34), Offset(1.5, -.16), Offset(1.15, .02), Offset(1.5, .2), Offset(-.2, .3)];

  static void _poly(Path path, List<Offset> pts, Offset at, double scale, double turn, [double flip = 1]) {
    final cs = math.cos(turn), sn = math.sin(turn);
    for (var i = 0; i < pts.length; i++) {
      final x = pts[i].dx * scale * flip, y = pts[i].dy * scale;
      final p = Offset(at.dx + x * cs - y * sn, at.dy + x * sn + y * cs);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
  }

  /// The lit facet of a shard: its upper-left three corners pulled in.
  static void _facet(Path path, List<Offset> pts, Offset at, double scale, double turn) {
    final cs = math.cos(turn), sn = math.sin(turn);
    Offset q(Offset v) {
      final x = v.dx * scale, y = v.dy * scale;
      return Offset(at.dx + x * cs - y * sn, at.dy + x * sn + y * cs);
    }

    final a = q(pts[0]), b = q(pts[1]), c = q(pts[2]), mid = q(const Offset(.05, .1));
    path
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(mid.dx, mid.dy)
      ..close();
  }

  static void _disc(Canvas c, Offset at, double radius, String id, List<Color> colors, List<double> stops, double alpha) {
    if (alpha <= 0 || radius <= 0 || !at.isFinite) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius);
    c.drawCircle(Offset.zero, 1, _shaded(id, () => GargoyleKit.radial(Offset.zero, 1, colors, stops), alpha));
    c.restore();
  }

  /// Billows of limestone dust: [count] puffs of three lobes in three flat
  /// layers (a violet shade, the dust, a lit lobe), their centres and radii
  /// from [place], airy ([thin] 0..1 of full strength).
  static void _puffs(Canvas c, int count, (Offset, double) Function(int i) place, double alpha, {int salt = 0, double thin = .78}) {
    if (alpha <= 0) return;
    final edge = _p4..reset(), shade = _p1..reset(), body = _p2..reset(), lit = _p3..reset();
    for (var i = 0; i < count; i++) {
      final (centre, r) = place(i);
      if (r <= 0 || !centre.isFinite) continue;
      for (var lobe = 0; lobe < 3; lobe++) {
        final a = lobe * 2.1 + i * 1.7 + salt;
        final o = Offset(math.cos(a), math.sin(a)) * r * .6;
        final lr = r * (lobe == 0 ? 1 : (lobe == 1 ? .66 : .48));
        // The cloud's ink edge is every lobe a little larger, drawn first: the
        // outline of their union, with no seams inside.
        edge.addOval(Rect.fromCircle(center: centre + o, radius: lr + math.max(1.3, r * .09)));
        shade.addOval(Rect.fromCircle(center: centre + o + Offset(r * .1, r * .16), radius: lr * 1.02));
        body.addOval(Rect.fromCircle(center: centre + o, radius: lr));
        lit.addOval(Rect.fromCircle(center: centre + o + Offset(-lr * .22, -lr * .28), radius: lr * .62));
      }
    }
    c.drawPath(edge, _solid(_ink, .75 * thin * alpha));
    c.drawPath(shade, _solid(GargoylePalette.limeDeep, .8 * thin * alpha));
    c.drawPath(body, _solid(GargoylePalette.dust, thin * alpha));
    c.drawPath(lit, _solid(GargoylePalette.limeSheen, .3 * alpha));
  }

  // ---------------------------------------------------------- the waking --

  /// The stone waking, [k] seconds after the lightning (boss age minus
  /// `SkyBoss.revealAt`, 0 to 1.3): amber cracks race out of the lamp across
  /// the body and fade, flakes of the grey shell spring off and fall, and dust
  /// lifts off his shoulders and head and drifts away (a veil: it never hides
  /// the stone turning to colour). Under Reduced Motion one still frame fades in
  /// and out.
  static void awaken(Canvas c, Offset at, double h, double k, {required bool reduced}) {
    if (!k.isFinite || !at.isFinite || !h.isFinite || k < 0 || k >= 1.3) return;
    final u = h * SkyBoss.radius;
    final kk = reduced ? .4 : k;
    final fade = reduced ? _ramp(k, 0, .15) * (1 - _ramp(k, .7, 1.2)) : 1.0;
    // The cracks: six jagged seams from the lamp's rim, bright at first.
    final crack = 1 - _ramp(kk, .1, .55);
    if (crack > 0) {
      final seams = _p1..reset();
      for (var i = 0; i < 6; i++) {
        final a = i * 2 * math.pi / 6 + .5;
        var p = at + Offset(math.cos(a), math.sin(a)) * u * 1.3;
        seams.moveTo(p.dx, p.dy);
        final reach = u * (1.1 + hash(i, 7) * 1.1) * _outCubic(_ramp(kk, 0, .14));
        for (var s = 1; s <= 4; s++) {
          final jitter = (hash(i * 4 + s, 9) - .5) * .7;
          final d = Offset(math.cos(a + jitter), math.sin(a + jitter));
          p = at + d * (u * 1.3 + reach * s / 4);
          seams.lineTo(p.dx, p.dy);
        }
      }
      c.drawPath(seams, _stroke(_ink, h * .011, crack * fade));
      c.drawPath(seams, _stroke(GargoylePalette.lampAmber, h * .006, crack * fade));
      c.drawPath(seams, _stroke(GargoylePalette.lampCore, h * .002, crack * fade));
    }
    // Flakes of the dormant shell: grey limestone that springs off and falls.
    final flakes = _p2..reset(), edge = _p3..reset();
    for (var i = 0; i < 14; i++) {
      final a = hash(i, 11) * math.pi * 2;
      final start = at + Offset(math.cos(a) * 1.9 * u * (.5 + hash(i, 13) * .5), math.sin(a) * 2.4 * u * (.5 + hash(i, 13) * .5));
      final delay = hash(i, 15) * .3;
      final tau = math.max(0.0, kk - delay);
      if (tau <= 0 && !reduced) continue;
      final v = (1.0 + hash(i, 17) * 2.2) * u;
      final p = start + Offset(math.cos(a) * v * tau * .9, math.sin(a) * v * tau * .7 - 1.4 * u * tau) + Offset(0, 7.5 * u * tau * tau);
      final spin = a + (reduced ? 0 : tau * (4 + hash(i, 19) * 6) * (i.isEven ? 1 : -1));
      final r = u * (.15 + hash(i, 21) * .16) * (1 - _ramp(kk, .8, 1.3) * .6);
      _poly(flakes, _flakeTemplate, p, r, spin);
      _poly(edge, _flakeTemplate, p, r, spin);
    }
    final fl = (1 - _ramp(kk, .75, 1.25)) * fade;
    c.drawPath(flakes, _solid(GargoylePalette.stoneGrey, fl));
    c.drawPath(edge, _stroke(_ink, h * .0035, fl));
    // Dust lifts off the shoulders, head and wings and drifts up and away.
    final rise = _ramp(kk, .0, .4);
    _puffs(
      c,
      6,
      (i) {
        const spots = [Offset(-1.6, -2.3), Offset(.6, -2.2), Offset(2.0, -1.6), Offset(-1.8, .4), Offset(1.8, .6), Offset(.4, -3.0)];
        final base = spots[i] * u;
        final drift = Offset((i.isEven ? -1 : 1) * u * 1.0 * _outCubic(rise), -u * 1.7 * _outCubic(_ramp(kk, .05, 1.3)));
        return (at + base + drift, u * (.28 + hash(i, 25) * .22) * (.5 + 1.0 * _outCubic(rise)));
      },
      (1 - _ramp(kk, .5, 1.3)) * fade * _ramp(kk, .0, .1),
      salt: 3,
      thin: .62,
    );
  }

  // ------------------------------------------------------------------ hit --

  /// A hit on the open lamp, [since] seconds after it (0 to .3): the lens
  /// flashes white-hot with an eight-point star, a ring leaves it, brass sparks
  /// fly and chips of limestone spring off. Under Reduced Motion the star holds
  /// and fades. [fury] turns the star's tips orange.
  static void hit(Canvas c, Offset at, double h, double since, {required bool reduced, bool fury = false}) {
    if (!since.isFinite || !at.isFinite || !h.isFinite || since < 0 || since >= .3) return;
    final t = since / .3, u = h * SkyBoss.radius;
    final size = u * (reduced ? .85 : (.62 + .38 * _outCubic(_ramp(t, 0, .3))) * (1 - t * .25));
    final fade = reduced ? 1 - t : 1 - t * t;
    GargoyleKit.glow(c, at, size * 2.4, GargoylePalette.lampCore, fade * .9);
    final star = _p1..reset();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + (reduced ? .2 : .2 + t * .4);
      final long = i % 4 == 0 ? 1.55 : 1.0;
      final r = size * (i.isEven ? long : .5);
      final p = at + Offset(math.cos(a) * r * (i % 4 == 0 ? 1.25 : 1), math.sin(a) * r);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c.drawPath(star, _stroke(_ink, h * .009, fade));
    c.drawPath(star, _solid(fury ? GargoylePalette.arcEdge : GargoylePalette.lampWarm, fade));
    c.drawCircle(at, size * .66, _solid(GargoylePalette.lampCore, fade));
    c.drawCircle(at, size * .32, _solid(GargoylePalette.white, fade));
    if (!reduced) {
      c.drawCircle(
        at,
        size * (1 + _outCubic(_ramp(t, 0, .7)) * 1.7),
        _stroke(fury ? GargoylePalette.arcEdge : GargoylePalette.lampAmber, h * .005 * (1 - t), (1 - t) * (1 - t) * .9),
      );
      final travel = _outCubic(t);
      final sparks = _p2..reset(), chips = _p3..reset();
      for (var i = 0; i < 9; i++) {
        final a = i * 2.399963 + .3;
        final d = u * (.9 + travel * (1.0 + hash(i, 3) * 1.2));
        final p = at + Offset(math.cos(a) * d, math.sin(a) * d + t * t * u * .7);
        sparks.addOval(Rect.fromCircle(center: p, radius: h * (.004 + hash(i, 5) * .004) * (1 - t * .6)));
      }
      for (var i = 0; i < 3; i++) {
        final a = i * 2.1 + .8;
        final d = u * (.9 + travel * 1.4);
        _poly(chips, _flakeTemplate, at + Offset(math.cos(a) * d, math.sin(a) * d + t * t * u * 1.1), h * .013, a + t * 6);
      }
      c.drawPath(sparks, _solid(GargoylePalette.brassLit, fade));
      c.drawPath(chips, _solid(GargoylePalette.limeLit, fade));
      c.drawPath(chips, _stroke(_ink, h * .003, fade));
    }
  }

  // ---------------------------------------------------------------- fury --

  /// Crossing into fury, [since] seconds after the blow that did it (0 to 1.1):
  /// a white-hot flash at the lamp, a Deco sunburst of twelve rays that
  /// swell and burn away, two rings of arc-light rolling out and sparks. Under
  /// Reduced Motion the burst hangs at half size and fades in place.
  static void furyOnset(Canvas c, Offset at, double h, double since, {required bool reduced}) {
    if (!since.isFinite || !at.isFinite || !h.isFinite || since < 0 || since >= 1.1) return;
    final t = since / 1.1, u = h * SkyBoss.radius;
    final fade = (1 - t) * (1 - t);
    if (!reduced && t < .4) {
      final f = 1 - t / .4;
      GargoyleKit.glow(c, at, u * (2.2 + 1.6 * (1 - f)), GargoylePalette.arcCore, f * f);
    }
    // The sunburst: tall tapered rays, long ones and short ones.
    final grow = reduced ? .6 : _outCubic(_ramp(t, 0, .35));
    final reach = u * 3.5 * grow * (1 - _ramp(t, .3, 1) * .75);
    final spin = reduced ? .1 : t * .35;
    final rays = _p1..reset(), core = _p2..reset();
    for (var i = 0; i < 12; i++) {
      final a = spin + i * math.pi / 6;
      final long = i.isEven ? 1.0 : .55;
      final r = reach * long, wd = u * (i.isEven ? .26 : .17);
      final dir = Offset(math.cos(a), math.sin(a)), perp = Offset(-dir.dy, dir.dx);
      rays
        ..moveTo(at.dx + dir.dx * u * 1.2 + perp.dx * wd, at.dy + dir.dy * u * 1.2 + perp.dy * wd)
        ..lineTo(at.dx + dir.dx * (u * 1.2 + r), at.dy + dir.dy * (u * 1.2 + r))
        ..lineTo(at.dx + dir.dx * u * 1.2 - perp.dx * wd, at.dy + dir.dy * u * 1.2 - perp.dy * wd)
        ..close();
      core
        ..moveTo(at.dx + dir.dx * u * 1.2 + perp.dx * wd * .4, at.dy + dir.dy * u * 1.2 + perp.dy * wd * .4)
        ..lineTo(at.dx + dir.dx * (u * 1.2 + r * .8), at.dy + dir.dy * (u * 1.2 + r * .8))
        ..lineTo(at.dx + dir.dx * u * 1.2 - perp.dx * wd * .4, at.dy + dir.dy * u * 1.2 - perp.dy * wd * .4)
        ..close();
    }
    c.drawPath(rays, _solid(GargoylePalette.arcEdge, .8 * fade));
    c.drawPath(core, _solid(GargoylePalette.arcCore, fade));
    for (var ring = 0; ring < 2; ring++) {
      final v = ring == 0 ? t : _ramp(t, .16, 1);
      if (v <= 0 || v >= 1) continue;
      final e = reduced ? .5 : _outCubic(v);
      final f2 = (1 - v) * (1 - v) * (ring == 0 ? 1 : .55);
      final r = u * (1.4 + e * (ring == 0 ? 3.2 : 2.6));
      c.drawCircle(at, r, _stroke(_ink, h * .011 * (1 - v * .5), f2 * .6));
      c.drawCircle(at, r, _stroke(ring == 0 ? GargoylePalette.arcEdge : GargoylePalette.arcCore, h * .006 * (1 - v * .5), f2));
    }
    if (!reduced) {
      final sparks = _p3..reset();
      final e = _outCubic(t);
      for (var i = 0; i < 12; i++) {
        final a = i * 2.399963 + .4;
        final d = u * (1.6 + e * (1.8 + hash(i, 3) * 2.0));
        sparks.addOval(Rect.fromCircle(center: at + Offset(math.cos(a) * d * 1.2, math.sin(a) * d), radius: h * .005 * (1 - t * .7)));
      }
      c.drawPath(sparks, _solid(GargoylePalette.arcCore, 1 - t));
    }
  }

  // ---------------------------------------------------------------- spot --

  /// The bird caught in his beam, [since] seconds ago (0 to .45): a white ring
  /// snaps shut round it like a lens iris, and a flash blinks.
  static void spotRing(Canvas c, Offset bird, double h, double since, {required bool reduced}) {
    if (!since.isFinite || !bird.isFinite || !h.isFinite || since < 0 || since >= .45) return;
    final t = since / .45;
    final r0 = FlightSimulation.birdRadius * h;
    final fade = 1 - t * t;
    final r = r0 * (reduced ? 1.7 : 1 + 2.2 * (1 - _outCubic(_ramp(t, 0, .5))));
    c.drawCircle(bird, r, _solid(GargoylePalette.lampCore, .28 * fade));
    c.drawCircle(bird, r, _stroke(_ink, h * .009, fade * .7));
    c.drawCircle(bird, r, _stroke(GargoylePalette.white, h * .005, fade));
    if (!reduced) {
      // Eight short iris blades turning in.
      final blades = _p1..reset();
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + t * 1.2;
        blades
          ..moveTo(bird.dx + math.cos(a) * r * 1.05, bird.dy + math.sin(a) * r * 1.05)
          ..lineTo(bird.dx + math.cos(a + .24) * r * 1.5, bird.dy + math.sin(a + .24) * r * 1.5);
      }
      c.drawPath(blades, _stroke(GargoylePalette.lampWarm, h * .004, fade));
    }
  }

  // --------------------------------------------------------------- defeat --

  /// How many chunks the burst flings (limestone shards, every fourth a steel
  /// blade); each ends on the heap.
  static const chunkCount = 14;

  /// Seconds since the kill when the burst begins (the rules' `burstAt`), when
  /// the heap has finished piling up and when the lenses light.
  static const burstAt = SkyBoss.burstAt, heapDone = 2.1, lensesLight = 1.5;

  // The heap's height above the lip at x (rig units), as profile points.
  static const _profile = [
    Offset(-1.8, 0),
    Offset(-1.45, .26),
    Offset(-.9, .4),
    Offset(-.3, .36),
    Offset(.15, .72),
    Offset(.7, 1.28),
    Offset(1.3, 1.42),
    Offset(1.9, .9),
    Offset(2.45, 0),
  ];

  static double _heapHeight(double x) {
    if (x <= _profile.first.dx || x >= _profile.last.dx) return 0;
    for (var i = 1; i < _profile.length; i++) {
      if (x <= _profile[i].dx) {
        final a = _profile[i - 1], b = _profile[i];
        return a.dy + (b.dy - a.dy) * (x - a.dx) / (b.dx - a.dx);
      }
    }
    return 0;
  }

  /// Where chunk [i] comes to rest, in rig units about the lamp: on the heap,
  /// clear of the two lenses lying in front of it.
  static Offset chunkRest(int i) {
    final x = i < 3 ? -1.7 + i * .08 : .1 + ((i - 3) * .59 + hash(i, 31) * .2) % 2.1;
    return Offset(x, GargoyleLayout.ledgeY - _heapHeight(x) * .8 - .02);
  }

  /// The defeat's burst, [death] seconds after the killing blow (the burst is at
  /// [burstAt], .85 s; the call is silent before it): a white-hot flash at the
  /// lamp, a veil of limestone dust rolling up off the body and thinning, and
  /// shards of limestone and steel flung out of the body that fall to the
  /// heap and stay as part of the rubble. Draw it over [rubble] and under
  /// [lenses]. Under Reduced Motion one scattered frame holds and the shards
  /// are already at rest.
  static void crumble(Canvas c, Offset at, double h, double death, {required bool reduced}) {
    if (!death.isFinite || !at.isFinite || !h.isFinite) return;
    final t = death - burstAt;
    if (t < 0) return;
    final u = h * SkyBoss.radius;
    // The flash: a white-hot disc.
    final flash = reduced ? 0.0 : 1 - _ramp(t, .0, .3);
    if (flash > 0) {
      _disc(c, at, u * 4.4 * _outCubic(_ramp(t, 0, .16)), 'burst.nova', const [Color(0xffffffff), GargoylePalette.lampCore, GargoylePalette.lampWarm, Color(0x00ffb84a)], const [0, .25, .55, 1], flash);
    }
    // The dust: a veil rolling up off the body and thinning as it settles.
    final rise = _ramp(t, 0, .45);
    final dust = (1 - _ramp(t, .75, 1.7)) * (reduced ? _ramp(t, 0, .2) : 1);
    _puffs(
      c,
      8,
      (i) {
        final a = i * 2.399963 + .9;
        final reach = u * (.5 + hash(i, 41) * 1.4) * (reduced ? .8 : _outCubic(rise));
        final lift = reduced ? u * .6 : u * 1.6 * _outCubic(_ramp(t, .05, 1.7));
        return (
          at + Offset(math.cos(a) * reach * 1.25, .4 * u + math.sin(a) * reach * .9 - lift * (.3 + hash(i, 43))),
          u * (.4 + hash(i, 45) * .4) * (.5 + .8 * _outCubic(rise)),
        );
      },
      dust * _ramp(t, 0, .05),
      salt: 5,
      thin: .7,
    );
    // The shards: limestone and steel, flung out and falling to the heap.
    final stone = _p1..reset(), stoneLit = _p5..reset(), steel = _p3..reset(), edges = _p4..reset();
    final heapTop = at.dy + (GargoyleLayout.ledgeY - .6) * u;
    for (var i = 0; i < chunkCount; i++) {
      final a = -math.pi / 2 + (hash(i, 51) - .5) * 3.4;
      final speed = (2.2 + hash(i, 53) * 4.0) * u;
      final start = at + Offset((hash(i, 55) - .5) * 2.8 * u, (hash(i, 57) - .5) * 3.6 * u);
      final rest = at + chunkRest(i) * u;
      final size = u * (i % 5 == 0 ? .3 : .17 + hash(i, 59) * .13);
      final blade = i % 4 == 3;
      final shape = _shards[i % 3];
      Offset p;
      double spin;
      if (reduced || t > 2.2) {
        p = rest;
        spin = hash(i, 61) * 6;
      } else {
        final vx = math.cos(a) * speed * 1.1, vy = math.sin(a) * speed;
        final x = start.dx + vx * t, y = start.dy + vy * t + 9 * u * t * t;
        // Once below the heap's top the shard settles toward its resting place
        // (it is hidden in the dust meanwhile).
        if (y > heapTop) {
          final tl = (math.sqrt(vy * vy + 4 * 9 * u * (heapTop - start.dy)) + vy) / (2 * 9 * u);
          final land = tl.isFinite ? math.max(0.0, tl) : 0.0;
          final settle = _outCubic(_ramp(t, land, land + .45));
          p = Offset.lerp(Offset(start.dx + vx * land, heapTop), rest, settle)!;
          spin = hash(i, 61) * 6 + (1 - settle) * 3;
        } else {
          p = Offset(x, y);
          spin = a + t * (5 + hash(i, 63) * 6) * (i.isEven ? 1 : -1);
        }
      }
      if (blade) {
        _poly(steel, _bladeTemplate, p, size * 1.1, spin);
      } else {
        _poly(stone, shape, p, size, spin);
        _facet(stoneLit, shape, p, size, spin);
      }
      _poly(edges, blade ? _bladeTemplate : shape, p, blade ? size * 1.1 : size, spin);
    }
    c.drawPath(stone, _solid(GargoylePalette.limeShade));
    c.drawPath(stoneLit, _solid(GargoylePalette.lime));
    c.drawPath(steel, _solid(GargoylePalette.steel));
    c.drawPath(edges, _stroke(_ink, h * .0042));
  }

  static final Path _heap = () {
    // The heap in rig units about the lamp, standing on the lip (y 2.95): low
    // in front (where the lenses lie) and piling up to the right.
    const y = GargoyleLayout.ledgeY;
    final p = Path()..moveTo(_profile.first.dx, y);
    for (var i = 1; i < _profile.length - 1; i++) {
      final a = _profile[i], b = _profile[i + 1];
      p.quadraticBezierTo(a.dx, y - a.dy, (a.dx + b.dx) / 2, y - (a.dy + b.dy) / 2);
    }
    return p
      ..lineTo(_profile.last.dx, y)
      ..close();
  }();

  static final Path _heapLit = () {
    // Lit crests on the heap's two summits.
    const y = GargoyleLayout.ledgeY;
    return Path()
      ..moveTo(.3, y - .8)
      ..quadraticBezierTo(.7, y - 1.34, 1.1, y - 1.2)
      ..quadraticBezierTo(.75, y - 1.0, .3, y - .8)
      ..moveTo(1.2, y - 1.36)
      ..quadraticBezierTo(1.65, y - 1.38, 1.95, y - .92)
      ..quadraticBezierTo(1.55, y - 1.1, 1.2, y - 1.36)
      ..moveTo(-1.4, y - .32)
      ..quadraticBezierTo(-1.0, y - .5, -.5, y - .4)
      ..quadraticBezierTo(-1.0, y - .34, -1.4, y - .32);
  }();

  static final Path _heapHatch = () {
    const y = GargoyleLayout.ledgeY;
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final x = .1 + i * .4;
      p
        ..moveTo(x, y - .1 - (i % 3) * .1)
        ..lineTo(x + .22, y - .28 - (i % 3) * .12);
    }
    return p;
  }();

  /// The heap of dust the statue became, [death] seconds after the kill (call
  /// it from the burst on, under [crumble]): it piles up on the ledge until
  /// [heapDone]. Under Reduced Motion it is whole.
  static void rubble(Canvas c, Offset at, double h, double death, {required bool reduced}) {
    if (!death.isFinite || !at.isFinite || !h.isFinite || death < burstAt + .1) return;
    final u = h * SkyBoss.radius;
    final grow = reduced ? _ramp(death, burstAt, burstAt + .4) : BossMotion.ease(_ramp(death, burstAt + .15, heapDone));
    if (grow <= 0) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(u);
    // The heap grows from the lip.
    c.translate(0, GargoyleLayout.ledgeY);
    c.scale(1, grow);
    c.translate(0, -GargoyleLayout.ledgeY);
    c.drawPath(
      _heap,
      Paint()
        ..shader = GargoyleKit.cached(
          'rubble.heap',
          () => GargoyleKit.linear(
            const Offset(0, GargoyleLayout.ledgeY - 1.45),
            const Offset(0, GargoyleLayout.ledgeY),
            const [GargoylePalette.limeLit, GargoylePalette.dust, GargoylePalette.limeShade],
            const [0, .5, 1],
          ),
        ).shader
        ..color = const Color(0xffffffff),
    );
    c.drawPath(_heapLit, _solid(GargoylePalette.limeSheen, .8));
    c.drawPath(_heapHatch, _stroke(GargoylePalette.limeDeep, .045, .6));
    c.drawPath(_heap, _stroke(_ink, GargoyleLayout.inkMajor));
    c.restore();
  }

  /// His two lenses, lying lit on the rubble from [lensesLight] (seconds after
  /// the kill): dark glass that flickers awake, then glows steadily, breathing
  /// slowly, to the end, with the light they cast on the ledge. Draw it last
  /// (over [rubble] and [crumble]). Under Reduced Motion they are steady.
  static void lenses(Canvas c, Offset at, double h, double death, {required bool reduced}) {
    if (!death.isFinite || !at.isFinite || !h.isFinite || death < burstAt + .4) return;
    final u = h * SkyBoss.radius;
    final grown = reduced ? 1.0 : BossMotion.ease(_ramp(death, burstAt + .4, heapDone));
    final wake = reduced ? 1.0 : _ramp(death, lensesLight, lensesLight + .7);
    for (var i = 0; i < GargoyleLayout.rubbleLenses.length; i++) {
      final (rel, rad) = GargoyleLayout.rubbleLenses[i];
      // The lens lies on the heap, so it rises with it from the lip.
      final lift = (GargoyleLayout.ledgeY - rel.dy) * (1 - grown) * u;
      final p = at + rel * u + Offset(0, lift), r = rad * u;
      final seen = reduced ? 1.0 : _ramp(death, burstAt + .4, burstAt + .8);
      final flicker = reduced
          ? 1.0
          : (wake < 1 ? (math.sin(death * 55 + i * 2.0) > -.15 ? 1.0 : .2) : .88 + .12 * math.sin(death * 2.2 + i * 1.7));
      final lit = wake * flicker;
      final dark = seen;
      // The light they cast on the lip and the heap.
      if (lit > 0) {
        c.save();
        c.translate(p.dx, p.dy + r * .9);
        c.scale(r * 5.2, r * 1.5);
        c.drawCircle(
          Offset.zero,
          1,
          _shaded('lens.pool', () => GargoyleKit.radial(Offset.zero, 1, const [Color(0xb3ffb84a), Color(0x4dffb84a), Color(0x00ffb84a)], const [0, .5, 1]), lit * .8),
        );
        c.restore();
      }
      c.drawCircle(p, r * 1.2, _solid(_ink, dark));
      c.drawCircle(p, r * 1.07, _solid(GargoylePalette.brass, dark));
      c.drawCircle(p, r * .88, _solid(GargoylePalette.steelCore, dark));
      GargoyleKit.glow(c, p, r * 3.6, GargoylePalette.lampAmber, .7 * lit);
      c.drawCircle(p, r * .8, _solid(GargoylePalette.lampDeep, lit));
      c.drawCircle(p, r * .58, _solid(GargoylePalette.lampAmber, lit));
      c.drawCircle(p, r * .34, _solid(GargoylePalette.lampCore, lit));
      c.drawCircle(p + Offset(-r * .3, -r * .34), r * .14, _solid(GargoylePalette.white, .9 * lit.clamp(0.0, 1.0)));
    }
  }

  // ------------------------------------------------------------- pigeons --

  // A pigeon in unit space (body length 1, facing +x, centred), as paths the
  // flock batches: body with head and tail, beak, a wing raised and a wing
  // lowered.
  static final Path _pBody = Path()
    ..moveTo(-.46, .08)
    ..cubicTo(-.34, -.26, .16, -.36, .34, -.14)
    ..cubicTo(.42, -.04, .36, .2, .14, .26)
    ..cubicTo(-.1, .32, -.36, .24, -.46, .08)
    ..close()
    ..moveTo(-.4, .04)
    ..lineTo(-.76, -.06)
    ..lineTo(-.7, .16)
    ..close()
    ..addOval(Rect.fromCircle(center: const Offset(.36, -.24), radius: .17));
  static final Path _pBeak = Path()
    ..moveTo(.5, -.3)
    ..lineTo(.7, -.22)
    ..lineTo(.5, -.16)
    ..close();
  static final Path _pWingUp = Path()
    ..moveTo(.14, -.16)
    ..quadraticBezierTo(-.04, -.95, -.5, -.82)
    ..quadraticBezierTo(-.3, -.42, -.22, -.08)
    ..close();
  static final Path _pWingDown = Path()
    ..moveTo(.14, -.1)
    ..quadraticBezierTo(0, .62, -.52, .62)
    ..quadraticBezierTo(-.32, .26, -.22, 0)
    ..close();

  static final Float64List _m = Float64List(16);

  static void _place(Path into, Path unit, Offset at, double size, double turn, double flip) {
    final cs = math.cos(turn), sn = math.sin(turn);
    final sx = size * flip, sy = size;
    _m[0] = sx * cs;
    _m[1] = sx * sn;
    _m[4] = -sy * sn;
    _m[5] = sy * cs;
    _m[10] = 1;
    _m[12] = at.dx;
    _m[13] = at.dy;
    _m[15] = 1;
    into.addPath(unit, Offset.zero, matrix4: _m);
  }

  static const _pigeonBody = Color(0xffa9abc8), _pigeonWing = Color(0xff6c7199), _pigeonBeak = Color(0xffff8f63);

  /// Draws pigeons given as (position, size, tilt, facing, flap up?) in one
  /// batch of eight ops: ink and fill for the lowered wings, the bodies and the
  /// raised wings, then beaks and eyes.
  static void _flock(Canvas c, List<(Offset, double, double, double, bool)> flock, double h, double alpha) {
    if (flock.isEmpty || alpha <= 0) return;
    final bodies = _p1..reset(), wingsUp = _p2..reset(), wingsDown = _p3..reset(), beaks = _p4..reset(), eyes = _p5..reset();
    for (final (at, size, tilt, flip, up) in flock) {
      _place(bodies, _pBody, at, size, tilt, flip);
      _place(up ? wingsUp : wingsDown, up ? _pWingUp : _pWingDown, at, size, tilt, flip);
      _place(beaks, _pBeak, at, size, tilt, flip);
      final cs = math.cos(tilt), sn = math.sin(tilt);
      final e = Offset(.43 * flip * size, -.27 * size);
      eyes.addOval(Rect.fromCircle(center: at + Offset(e.dx * cs - e.dy * sn, e.dx * sn + e.dy * cs), radius: size * .04));
    }
    final width = h * .0048;
    c.drawPath(wingsDown, _stroke(_ink, width * 1.3, alpha));
    c.drawPath(wingsDown, _solid(_pigeonWing, alpha));
    c.drawPath(bodies, _stroke(_ink, width * 1.3, alpha));
    c.drawPath(bodies, _solid(_pigeonBody, alpha));
    c.drawPath(wingsUp, _stroke(_ink, width * 1.3, alpha));
    c.drawPath(wingsUp, _solid(_pigeonWing, alpha));
    c.drawPath(beaks, _solid(_pigeonBeak, alpha));
    c.drawPath(eyes, _solid(_ink, alpha));
  }

  /// The nine pigeons that nest in him, dozing on his shoulders before the stone
  /// wakes: each exactly where, how big, which way round and how tilted its
  /// [flush] begins, so the flock lifts off its perch with no pop. [age] is the
  /// boss's age; a pigeon is here until its own take-off (2.0 s plus .05 s
  /// each). Under Reduced Motion they sit still and are gone as the stone
  /// finishes waking (a .25 s fade from 2.0 s: they never fly).
  static void roost(Canvas c, Offset at, double h, double age, {required bool reduced}) {
    if (!age.isFinite || !at.isFinite || !h.isFinite) return;
    final u = h * SkyBoss.radius;
    final gone = reduced ? _ramp(age, 2.0, 2.25) : 0.0;
    final flock = <(Offset, double, double, double, bool)>[];
    for (var i = 0; i < 9; i++) {
      if (!reduced && age - 2.0 - i * .05 > 0) continue;
      final a = -math.pi / 2 + (-1.1 + 2.2 * i / 8) + (hash(i, 71) - .5) * .3;
      final from = at + Offset(.4 * u + (hash(i, 75) - .5) * 1.8 * u, -1.8 * u);
      // A doze: the head dips now and then (motion: none under Reduced Motion).
      final doze = reduced ? 0.0 : (math.sin(age * 2.1 + i * 1.7) > .93 ? h * .004 : 0.0);
      final size = h * (.07 + hash(i, 77) * .022) * .6;
      final left = math.cos(a) < 0;
      flock.add((from + Offset(0, doze), size, math.sin(a) * (left ? -.3 : .3), left ? -1.0 : 1.0, false));
    }
    _flock(c, flock, h, 1 - gone);
  }

  /// The pigeons that nested in him, flushed as the stone wakes: nine bolt out
  /// of the crest and shoulders and scatter up and away, [age] being the boss's
  /// age (they leave from 2.0 s and are gone by 3.5 s). Under Reduced Motion
  /// none (they are motion).
  static void flush(Canvas c, Offset at, double h, double age, {required bool reduced}) {
    if (reduced || !age.isFinite || !at.isFinite || !h.isFinite) return;
    final k = age - 2.0;
    if (k < 0 || k > 1.5) return;
    final u = h * SkyBoss.radius;
    final flock = <(Offset, double, double, double, bool)>[];
    for (var i = 0; i < 9; i++) {
      final tau = k - i * .05;
      if (tau <= 0) continue;
      final a = -math.pi / 2 + (-1.1 + 2.2 * i / 8) + (hash(i, 71) - .5) * .3;
      final v = h * (.6 + hash(i, 73) * .5);
      final from = at + Offset(.4 * u + (hash(i, 75) - .5) * 1.8 * u, -1.8 * u);
      final wobble = math.sin(tau * 9 + i) * h * .012;
      final p = from + Offset(math.cos(a) * v * tau, math.sin(a) * v * tau - h * .1 * tau * tau) + Offset(wobble, 0);
      final size = h * (.07 + hash(i, 77) * .022) * (.6 + .4 * _outCubic(_ramp(tau, 0, .3)));
      final left = math.cos(a) < 0;
      flock.add((p, size, math.sin(a) * (left ? -.3 : .3), left ? -1.0 : 1.0, math.sin(tau * 22 + i) > 0));
    }
    _flock(c, flock, h, 1 - _ramp(k, 1.2, 1.5));
  }

  /// The pigeons that burst out of the dust, [death] seconds after the kill (they
  /// leave from 1.0 s and are gone by 2.5 s, all but the ninth, which circles
  /// back and lands on the rubble by 2.6 s and stays, bobbing, to the end).
  /// Under Reduced Motion only the one that stays, still.
  static void pigeonsOut(Canvas c, Offset at, double h, double death, {required bool reduced}) {
    if (!death.isFinite || !at.isFinite || !h.isFinite || death < 1.0) return;
    final u = h * SkyBoss.radius;
    final k = death - 1.0;
    final perch = at + Offset(.95 * u, (GargoyleLayout.ledgeY - 1.12) * u);
    final flock = <(Offset, double, double, double, bool)>[];
    if (!reduced && k < 1.55) {
      for (var i = 0; i < 8; i++) {
        final tau = k - i * .06;
        if (tau <= 0) continue;
        final a = -math.pi / 2 + (hash(i, 81) - .5) * 3.1;
        final v = h * (.6 + hash(i, 83) * .6);
        final from = at + Offset((hash(i, 85) - .5) * 3 * u, (GargoyleLayout.ledgeY - 1.0) * u);
        final wobble = math.sin(tau * 8 + i * 1.7) * h * .014;
        final p = from + Offset(math.cos(a) * v * tau + wobble, math.sin(a) * v * tau - h * .12 * tau * tau);
        final size = h * (.07 + hash(i, 87) * .022) * (.55 + .45 * _outCubic(_ramp(tau, 0, .25)));
        final left = math.cos(a) < 0;
        flock.add((p, size, math.sin(a) * (left ? -.3 : .3), left ? -1.0 : 1.0, math.sin(tau * 22 + i) > 0));
      }
    }
    _flock(c, flock, h, 1 - _ramp(k, 1.25, 1.55));
    // The ninth: up and over, then back down onto the rubble.
    final size = h * .072;
    if (reduced) {
      if (death >= 2.6) _flock(c, [(perch, size, 0.0, -1.0, false)], h, _ramp(death, 2.6, 2.9));
      return;
    }
    final s = _ramp(death, 1.05, 2.6);
    if (s <= 0) return;
    final p0 = perch + Offset(0, u * .3), p2 = perch;
    final ctrl = at + Offset(-4.4 * u, -3.4 * u);
    final inv = 1 - s;
    final p = Offset(
      inv * inv * p0.dx + 2 * inv * s * ctrl.dx + s * s * p2.dx,
      inv * inv * p0.dy + 2 * inv * s * ctrl.dy + s * s * p2.dy,
    );
    final d = Offset(
      2 * inv * (ctrl.dx - p0.dx) + 2 * s * (p2.dx - ctrl.dx),
      2 * inv * (ctrl.dy - p0.dy) + 2 * s * (p2.dy - ctrl.dy),
    );
    final left = d.dx < 0;
    final landed = s >= 1;
    final bob = landed ? (math.sin(death * 3) > .96 ? -h * .004 : 0.0) : 0.0;
    _flock(
      c,
      [(p + Offset(0, bob), size, landed ? 0.0 : math.atan2(d.dy, d.dx.abs()) * .5, landed ? -1.0 : (left ? -1.0 : 1.0), !landed && math.sin(death * 22) > 0)],
      h,
      1,
    );
  }
}

/// The card's measured layout: everything that depends only on the viewport,
/// the room his head leaves and the words.
class _Card {
  _Card(this.size, this.quote, double roomPx) : room = roomPx.round() {
    final h = size.height, w = size.width;
    final name = GargoyleEncounterUi.titleBig;
    // Lay it out at full size; if the plate would reach his head, lay it out
    // again smaller.
    double wanted(double f) {
      final n = GargoyleEncounterUi._text('name', name, h * .088 * f, color: const Color(0xffffffff), spacing: 1);
      final sub = GargoyleEncounterUi._text('epithet', GargoyleEncounterUi.epithet, h * .0255 * f, spacing: 1.1);
      final small = GargoyleEncounterUi._text('small', GargoyleEncounterUi.titleSmall, h * .03 * f, spacing: 3);
      return math.max(n.width + h * .1 * f, math.max(sub.width + h * .1 * f, small.width + h * .14 * f));
    }

    var fit = 1.0;
    final full = wanted(1);
    if (full > roomPx && roomPx > 0) fit = math.max(.6, roomPx / full);
    f = fit;
    final hf = h * f;
    nameSize = h * .088 * f;
    final probe = GargoyleEncounterUi._text('name', name, nameSize, color: const Color(0xffffffff), spacing: 1);
    nameW = probe.width;
    nameH = probe.height;
    glyphs = [for (var i = 0; i < name.length; i++) name[i]];
    glyphX = [];
    glyphW = [];
    for (var i = 0; i < name.length; i++) {
      final boxes = probe.getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1));
      glyphX.add(boxes.isEmpty ? 0.0 : boxes.first.left);
      glyphW.add(boxes.isEmpty ? 0.0 : boxes.first.right - boxes.first.left);
    }
    outline = GargoyleEncounterUi._text('outline', name, nameSize, spacing: 1, stroke: h * .012 * f);
    final wc = wanted(f);
    final hc = hf * .29;
    final x0 = math.max(h * .04, math.min(w * .075, w * .5 - wc));
    plate = Rect.fromLTWH(x0, h * .115, wc, hc);
    final st = hf * .0125;
    final r = plate;
    Path stepped(Rect q, double s) => Path()
      ..moveTo(q.left + 2 * s, q.top)
      ..lineTo(q.right - 2 * s, q.top)
      ..lineTo(q.right - 2 * s, q.top + s)
      ..lineTo(q.right - s, q.top + s)
      ..lineTo(q.right - s, q.top + 2 * s)
      ..lineTo(q.right, q.top + 2 * s)
      ..lineTo(q.right, q.bottom - 2 * s)
      ..lineTo(q.right - s, q.bottom - 2 * s)
      ..lineTo(q.right - s, q.bottom - s)
      ..lineTo(q.right - 2 * s, q.bottom - s)
      ..lineTo(q.right - 2 * s, q.bottom)
      ..lineTo(q.left + 2 * s, q.bottom)
      ..lineTo(q.left + 2 * s, q.bottom - s)
      ..lineTo(q.left + s, q.bottom - s)
      ..lineTo(q.left + s, q.bottom - 2 * s)
      ..lineTo(q.left, q.bottom - 2 * s)
      ..lineTo(q.left, q.top + 2 * s)
      ..lineTo(q.left + s, q.top + 2 * s)
      ..lineTo(q.left + s, q.top + s)
      ..lineTo(q.left + 2 * s, q.top + s)
      ..close();
    body = stepped(r, st);
    final ins = hf * .017;
    inner = stepped(r.deflate(ins), st * .6);
    // The upper edges of every step, lit.
    lit = Path()
      ..moveTo(r.left, r.top + 2 * st + hf * .01)
      ..lineTo(r.left, r.top + 2 * st)
      ..lineTo(r.left + st, r.top + 2 * st)
      ..lineTo(r.left + st, r.top + st)
      ..lineTo(r.left + 2 * st, r.top + st)
      ..lineTo(r.left + 2 * st, r.top)
      ..lineTo(r.right - 2 * st, r.top)
      ..lineTo(r.right - 2 * st, r.top + st)
      ..lineTo(r.right - st, r.top + st)
      ..lineTo(r.right - st, r.top + 2 * st)
      ..lineTo(r.right, r.top + 2 * st)
      ..lineTo(r.right, r.top + 2 * st + hf * .01);
    final studs = Path();
    final d = hf * .0085;
    for (final p in [Offset(r.right - ins * 1.4, r.center.dy), Offset(r.left + ins * 1.4, r.center.dy)]) {
      studs
        ..moveTo(p.dx, p.dy - d)
        ..lineTo(p.dx + d, p.dy)
        ..lineTo(p.dx, p.dy + d)
        ..lineTo(p.dx - d, p.dy)
        ..close();
    }
    this.studs = studs;
    // Chevrons engraved along the foot.
    final frieze = Path();
    final pitch = hf * .03;
    for (var x = r.left + hf * .09; x < r.right - hf * .09; x += pitch) {
      frieze
        ..moveTo(x, r.bottom - hf * .052)
        ..lineTo(x + pitch * .5, r.bottom - hf * .036)
        ..lineTo(x + pitch, r.bottom - hf * .052);
    }
    this.frieze = frieze;
    // The marquee's bulbs along the top and foot, inside the rim.
    bulbR = h * .0058 * f;
    final bpitch = hf * .036;
    final bulbList = <Offset>[];
    for (var x = r.left + hf * .075; x < r.right - hf * .06; x += bpitch) {
      bulbList.add(Offset(x, r.top + hf * .0155));
    }
    for (var x = r.left + hf * .075; x < r.right - hf * .06; x += bpitch) {
      bulbList.add(Offset(x, r.bottom - hf * .0155));
    }
    bulbs = bulbList;
    // The ribbon, over the top edge at the left.
    final k1 = h / 360;
    final rbH = hf * .066;
    final word = ribbonWord(1);
    shieldW = rbH * .98;
    ribbonRect = Rect.fromLTWH(r.left - hf * .018, r.top - rbH * .55, shieldW + rbH * .26 + word.width + rbH * .9, rbH);
    final rr = ribbonRect, tail = rr.height * .5;
    ribbonShape = Path()
      ..moveTo(rr.left + 2, rr.top)
      ..lineTo(rr.right, rr.top)
      ..lineTo(rr.right - tail, rr.center.dy)
      ..lineTo(rr.right, rr.bottom)
      ..lineTo(rr.left + 2, rr.bottom)
      ..quadraticBezierTo(rr.left, rr.bottom, rr.left, rr.bottom - 2)
      ..lineTo(rr.left, rr.top + 2)
      ..quadraticBezierTo(rr.left, rr.top, rr.left + 2, rr.top)
      ..close();
    Path shield(double sa, double sb, Offset o) => Path()
      ..moveTo(o.dx - sa, o.dy - sb * .76)
      ..quadraticBezierTo(o.dx, o.dy - sb, o.dx + sa, o.dy - sb * .76)
      ..lineTo(o.dx + sa, o.dy + sb * .04)
      ..cubicTo(o.dx + sa, o.dy + sb * .5, o.dx + sa * .5, o.dy + sb * .8, o.dx, o.dy + sb)
      ..cubicTo(o.dx - sa * .5, o.dy + sb * .8, o.dx - sa, o.dy + sb * .5, o.dx - sa, o.dy + sb * .04)
      ..close();
    final sa = shieldW * .5, sb = rr.height * .66;
    shieldCentre = Offset(rr.left + shieldW * .5 - k1 * 1.5, rr.center.dy + rr.height * .02);
    shieldOuter = shield(sa, sb, shieldCentre);
    shieldInner = shield(sa * .72, sb * .74, shieldCentre.translate(0, sb * .03));
    // The quote, centred under the plate.
    final qWidth = plate.width - hf * .05;
    quoteWidth = qWidth;
    quoteSize = h * .037 * f;
    final fill = GargoyleEncounterUi._text('quote', quote, quoteSize, color: GargoyleEncounterUi.cream, italic: true, width: qWidth, maxLines: 2);
    quoteBox = Rect.fromLTWH(plate.center.dx - qWidth / 2, plate.bottom + h * .03 * f, qWidth, fill.height);
  }

  final Size size;
  final String quote;
  final int room;

  /// How much smaller than full size the plate had to be to fit.
  late final double f;
  late final double nameSize, nameW, nameH, bulbR, shieldW, quoteWidth, quoteSize;
  late final List<String> glyphs;
  late final List<double> glyphX, glyphW;
  late final TextPainter outline;
  late final Rect plate, ribbonRect, quoteBox;
  late final Path body, inner, lit, frieze, ribbonShape, shieldOuter, shieldInner;
  late final Offset shieldCentre;
  late final Path studs;
  late final List<Offset> bulbs;

  TextPainter ribbonWord(double alpha) => GargoyleEncounterUi._text(
    'ribbon',
    GargoyleEncounterUi.tag,
    size.height * .027 * (f == 0 ? 1 : f),
    color: SkyColors.cream,
    spacing: 2.2,
    alpha: alpha,
  );

  TextPainter? small(double alpha) {
    if (alpha <= 0) return null;
    return GargoyleEncounterUi._text(
      'small',
      GargoyleEncounterUi.titleSmall,
      size.height * .03 * f,
      spacing: 3,
      color: GargoylePalette.brassLit,
      alpha: alpha,
    );
  }

  TextPainter? epithetPainter(double alpha) {
    if (alpha <= 0) return null;
    return GargoyleEncounterUi._text(
      'epithet',
      GargoyleEncounterUi.epithet,
      size.height * .0255 * f,
      spacing: 1.1,
      color: GargoylePalette.brassLit,
      alpha: alpha,
    );
  }

  TextPainter quoteFill(double alpha) => GargoyleEncounterUi._text(
    'quote',
    quote,
    quoteSize,
    color: GargoyleEncounterUi.cream,
    italic: true,
    width: quoteWidth,
    maxLines: 2,
    alpha: alpha,
  );

  TextPainter quoteEdge(double alpha) => GargoyleEncounterUi._text(
    'quoteEdge',
    quote,
    quoteSize,
    italic: true,
    width: quoteWidth,
    maxLines: 2,
    stroke: size.height * .0075 * f,
    alpha: alpha,
  );
}
