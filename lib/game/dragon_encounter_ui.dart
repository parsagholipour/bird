import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

import '../domain/game_rules.dart' show FlightSimulation;
import '../domain/sky_boss.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'dragon_hud_art.dart' show DragonHudFx;
import 'dragon_kit.dart';

/// The Ember Dragon's cinematic set-pieces: the smouldering sky, the title
/// card that slams in on the roar, the roar's fire and shockwave, the fury
/// ring, hit and heart-strike bursts, and the defeat's supernova of embers,
/// scales and ash.
///
/// `BossEncounterArt` owns the staging and timing; these are only the
/// dragon's brushstrokes. Everything derives from the boss and death clocks,
/// so paused, replayed and captured frames repeat exactly, and under Reduced
/// Motion each piece holds still and only fades. Nothing here blurs or
/// opens a layer; gradients are cached and unit-sized, moved into place with
/// the canvas transform, and the animated shapes are rebuilt into scratch
/// paths rather than allocated.
abstract final class DragonEncounterUi {
  static const _p = DragonPalette.ink, _cream = Color(0xfffff2c9);
  static const _ash = DragonPalette.ash, _smoke = Color(0xff2a1a2c);
  static const _ashDeep = Color(0xff2a1a2b), _ashLit = Color(0xff7a5468);
  static const _plate = [
    Color(0xff2b1a3a),
    Color(0xff1a1027),
    Color(0xff0f0a19),
  ];

  static double _outCubic(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u * u;
  }

  static double _ramp(double v, double from, double to) =>
      BossMotion.ramp(v, from, to);

  static final Path _a = Path(), _b = Path(), _c = Path();
  static final Path _d = Path(), _e = Path();

  // ---------------------------------------------------------- name card --

  /// The arrival title card. It is the dragon's own card at every moment of
  /// the arrival, so this always returns true: `BossEncounterArt` calls
  /// `if (!DragonEncounterUi.nameCard(...)) _nameCard(...)` and the shared
  /// card must not appear early, before the roar.
  ///
  /// Nothing shows until the roar strikes, [slamAt] (`SkyBoss.roarAt` + .15
  /// s, 2.80 s: as the jaws open and the flames climb, before the roar's
  /// peak): then an obsidian plate wipes in behind a wavering heat line as
  /// the card slams down, and the name lights up letter by letter, left to
  /// right, each burning white-hot and cooling to cream while sparks fly
  /// off it; the last letter is lit by 3.13 s. The card holds to 4.2 s and
  /// folds away by 4.6 s. [birdY] (screen heights) lets the plate turn
  /// see-through where the bird flies behind it. Under Reduced Motion the
  /// whole card just fades in and out.
  ///
  /// [line] is the campaign's story quote for this boss (it arrives already
  /// in quotation marks). When there is one it is set under the plate, on its
  /// own soft shade, centred, cream on an ink edge and slanted: at most two
  /// lines, as wide as the plate, appearing just after the name has lit and
  /// leaving with the card. The plate itself is exactly the same with or
  /// without it.
  /// When the card lands: on the roar's strike.
  static const slamAt = SkyBoss.roarAt + .15;

  /// The name's letters light from [_igniteFrom] s after the slam, one every
  /// [_igniteStep] s.
  static const _igniteFrom = .04, _igniteStep = .026;

  static bool nameCard(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    required double birdY,
    String? line,
  }) {
    // The card is ours even when there is nothing trustworthy to draw.
    if (!boss.age.isFinite || !size.isFinite || !birdY.isFinite) return true;
    final t = boss.age - slamAt;
    final gone = _ramp(boss.age, 4.2, 4.6);
    if (t < 0 || gone >= 1) return true;
    final reduced = m.reducedMotion;
    final h = size.height, k = h / 360;
    final g = _card(size, boss);
    final hf = h * g.f;
    final x0 = g.plate.left, y0 = g.plate.top, wc = g.plate.width;
    final hc = g.plate.height;

    // How much of the card shows: a wipe (or a fade under Reduced Motion).
    final wipe = reduced ? 1.0 : _outCubic(_ramp(t, 0, .26));
    final fold = reduced ? 0.0 : BossMotion.ease(gone);
    final fade = reduced
        ? (_ramp(t, 0, .25) * (1 - gone)).clamp(0.0, 1.0)
        : 1.0;
    final reach = math.min(wipe, 1 - fold);
    if (reach <= 0 || fade <= 0) return true;
    final front = x0 + wc * reach;

    // See-through where the bird's lane runs behind the card.
    final bird = Offset(FlightSimulation.birdX * h, birdY * h);
    final card = g.plate.inflate(h * .02);
    final gap = Offset(
      math.max(math.max(card.left - bird.dx, bird.dx - card.right), 0.0),
      math.max(math.max(card.top - bird.dy, bird.dy - card.bottom), 0.0),
    ).distance;
    final clear = math.max(0.0, gap - FlightSimulation.birdRadius * h);
    final seen = (.4 + .6 * _ramp(clear, h * .005, h * .05)) * fade;

    c.save();
    // The slam: the card lands from a little larger, about its middle.
    final slam = reduced || fold > 0 ? 0.0 : 1 - _outCubic(_ramp(t, 0, .12));
    if (slam > 0) {
      final pivot = g.plate.center;
      c.translate(pivot.dx, pivot.dy - h * .012 * slam);
      c.scale(1 + .1 * slam);
      c.translate(-pivot.dx, -pivot.dy);
    }
    // A soft shadow round the plate (one radial fade, no edges to see), laid
    // before the wipe so it is never cut by it.
    c.save();
    // (It spreads right, above and below; its left edge is the plate's own,
    // so under Reduced Motion the card's leftmost pixel never moves.)
    c.translate(g.plate.center.dx + h * .07, g.plate.center.dy + h * .008);
    c.scale(wc / 2 + h * .07, hc / 2 + h * .1);
    c.drawCircle(
      Offset.zero,
      1,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          'cardShade',
          () => DragonKit.radial(
            Offset.zero,
            1,
            [
              DragonPalette.scaleCore.withValues(alpha: .36),
              DragonPalette.scaleCore.withValues(alpha: .3),
              DragonPalette.scaleCore.withValues(alpha: 0),
            ],
            const [0, .66, 1],
          ).shader!,
        ),
        seen * math.min(1.0, reach * 1.5),
      ),
    );
    c.restore();
    final quote = line == null || line.trim().isEmpty ? null : line.trim();
    c.clipRect(
      Rect.fromLTRB(
        x0 - h * .12,
        y0 - h * .1,
        front,
        y0 + hc + h * (quote == null ? .14 : .3),
      ),
    );

    // The plate: obsidian, scaled, rimmed in gold, lit from below by embers.
    c.drawPath(
      g.body,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          ('cardBody', g.plate),
          () => DragonKit.linear(
            g.plate.topCenter,
            g.plate.bottomCenter,
            [_plate[0], _plate[1], _plate[2]],
            const [0, .5, 1],
          ).shader!,
        ),
        .93 * seen,
      ),
    );
    c.drawPath(
      g.scales,
      DragonHudFx.stroke(DragonPalette.scaleDeep, k * .9, .55 * seen),
    );
    final glow = Rect.fromLTRB(x0, y0 + hc * .55, x0 + wc, y0 + hc);
    final beat = reduced ? .5 : .5 + .5 * math.sin(boss.age * 5);
    c.drawRect(
      glow,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          ('cardGlow', glow),
          () => DragonKit.linear(glow.bottomCenter, glow.topCenter, [
            DragonPalette.flame.withValues(alpha: .55),
            DragonPalette.flame.withValues(alpha: 0),
          ]).shader!,
        ),
        (.5 + .18 * beat) * seen,
      ),
    );
    c.drawPath(g.body, DragonHudFx.stroke(_p, k * 3.4, seen));
    c.drawPath(
      g.body,
      DragonHudFx.shaded(
          DragonHudFx.shader(
            ('cardRim', g.plate),
            () => DragonKit.linear(
              g.plate.topCenter,
              g.plate.bottomCenter,
              const [
                DragonPalette.goldLit,
                DragonPalette.gold,
                DragonPalette.goldDeep,
              ],
              const [0, .4, 1],
            ).shader!,
          ),
          seen,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      g.inner,
      DragonHudFx.stroke(DragonPalette.gold, k * .7, .5 * seen),
    );
    c.drawPath(g.studs, DragonHudFx.solid(DragonPalette.goldLit, seen));

    // The slam's flash, gone in a tenth of a second.
    if (!reduced && t < .1) {
      c.drawPath(
        g.body,
        DragonHudFx.solid(DragonPalette.flameCore, .55 * (1 - t / .1)),
      );
    }

    final cx = g.plate.center.dx;
    // "ENCOUNTER 10" over a hairline with a small flame at its middle.
    final eyebrow = g.eyebrow(fade);
    eyebrow.paint(c, Offset(cx - eyebrow.width / 2, y0 + hf * .022));
    final dy = y0 + hf * .082;
    final gapW = hf * .03, span = math.min(wc * .3, hf * .2);
    c.drawLine(
      Offset(cx - gapW, dy),
      Offset(cx - gapW - span, dy),
      DragonHudFx.stroke(DragonPalette.gold, k * 1.1, .7 * seen),
    );
    c.drawLine(
      Offset(cx + gapW, dy),
      Offset(cx + gapW + span, dy),
      DragonHudFx.stroke(DragonPalette.gold, k * 1.1, .7 * seen),
    );
    _flame(c, Offset(cx, dy + hf * .002), hf * .05, boss.age, reduced, seen);

    // The name: an ink shadow and outline, then each letter lit in turn.
    final nameTop = y0 + hf * .094;
    final nameLeft = cx - g.nameW / 2;
    g.outline.paint(c, Offset(nameLeft, nameTop + k * 2.2));
    g.outline.paint(c, Offset(nameLeft, nameTop));
    final glyphs = g.glyphs;
    var latest = -1;
    for (var i = 0; i < glyphs.length; i++) {
      final d = reduced ? 1.0 : t - (_igniteFrom + i * _igniteStep);
      if (glyphs[i].trim().isEmpty) continue;
      if (d < 0) {
        // Not yet lit: cold iron in the outline.
        _glyph(
          glyphs[i],
          g.nameSize,
          -1,
          fade,
        ).paint(c, Offset(nameLeft + g.glyphX[i], nameTop));
        continue;
      }
      latest = i;
      final stage = d < .06
          ? 0
          : d < .14
          ? 1
          : d < .24
          ? 2
          : d < .36
          ? 3
          : 4;
      _glyph(
        glyphs[i],
        g.nameSize,
        stage,
        fade,
      ).paint(c, Offset(nameLeft + g.glyphX[i], nameTop));
    }
    if (!reduced && latest >= 0) {
      final d = t - (_igniteFrom + latest * _igniteStep);
      if (d < .3) {
        final at = Offset(
          nameLeft + g.glyphX[latest] + g.nameSize * .3,
          nameTop + g.nameSize * .55,
        );
        c.save();
        c.translate(at.dx, at.dy);
        c.scale(h * .07);
        c.drawCircle(
          Offset.zero,
          1,
          DragonHudFx.shaded(
            DragonHudFx.shader(
              'cardSpark',
              () => DragonKit.radial(
                Offset.zero,
                1,
                [
                  DragonPalette.flameCore.withValues(alpha: .9),
                  DragonPalette.flameGold.withValues(alpha: .35),
                  DragonPalette.flame.withValues(alpha: 0),
                ],
                const [0, .35, 1],
              ).shader!,
            ),
            1 - d / .3,
          ),
        );
        c.restore();
      }
      _sparks(c, g, nameLeft, nameTop, t, k);
    }

    // The title, revealed after the name has burned in.
    final titleTop = nameTop + g.nameH + hf * .012;
    final hair = titleTop - hf * .002;
    c.drawLine(
      Offset(cx - wc * .38, hair),
      Offset(cx + wc * .38, hair),
      DragonHudFx.stroke(DragonPalette.gold, k * .9, .5 * seen),
    );
    final subReach = reduced ? 1.0 : _ramp(t, .3, .6);
    if (subReach > 0) {
      c.save();
      c.clipRect(
        Rect.fromLTRB(
          cx - wc / 2 - h * .02,
          titleTop - h * .01,
          cx - wc / 2 + wc * subReach,
          titleTop + h * .06,
        ),
      );
      final sub = g.subtitle(fade);
      final sx = cx - sub.width / 2, sy = titleTop + hf * .012;
      sub.paint(c, Offset(sx, sy));
      final mid = sy + sub.height * .52;
      for (final s in [-1.0, 1.0]) {
        final dx = cx + s * (sub.width / 2 + hf * .026);
        final r = hf * .0095;
        c.drawPath(
          _a
            ..reset()
            ..moveTo(dx, mid - r)
            ..lineTo(dx + r, mid)
            ..lineTo(dx, mid + r)
            ..lineTo(dx - r, mid)
            ..close(),
          DragonHudFx.solid(DragonPalette.gold, seen),
        );
      }
      c.restore();
    }

    // The story quote, under the plate on a shade of its own. Its own
    // see-through is worked out from its own box, so the plate above does
    // not change when there is one.
    if (quote != null) {
      final box = g.quoteBox(quote);
      final qGap = Offset(
        math.max(math.max(box.left - bird.dx, bird.dx - box.right), 0.0),
        math.max(math.max(box.top - bird.dy, bird.dy - box.bottom), 0.0),
      ).distance;
      final qClear = math.max(0.0, qGap - FlightSimulation.birdRadius * h);
      final qSeen =
          (.62 + .38 * _ramp(qClear, h * .005, h * .05)) *
          (reduced ? fade : _ramp(t, .32, .5));
      if (qSeen > 0) {
        c.save();
        c.clipRect(
          Rect.fromLTRB(
            box.left - h * .1,
            g.plate.bottom,
            box.right + h * .1,
            box.bottom + h * .12,
          ),
        );
        c.save();
        c.translate(box.center.dx, box.center.dy + h * .004);
        c.scale(box.width / 2 + h * .05, box.height / 2 + h * .045);
        c.drawCircle(
          Offset.zero,
          1,
          DragonHudFx.shaded(
            DragonHudFx.shader(
              'quoteShade',
              () => DragonKit.radial(
                Offset.zero,
                1,
                [
                  DragonPalette.scaleCore.withValues(alpha: .66),
                  DragonPalette.scaleCore.withValues(alpha: .56),
                  DragonPalette.scaleCore.withValues(alpha: 0),
                ],
                const [0, .62, 1],
              ).shader!,
            ),
            qSeen,
          ),
        );
        c.restore();
        final at = Offset(box.left, box.top);
        g.quoteEdge(quote, qSeen).paint(c, at);
        g.quoteFill(quote, qSeen).paint(c, at);
        c.restore();
      }
    }

    // The heat line at the wipe's edge, wavering as it goes.
    if (!reduced && reach < 1) {
      final line = _a..reset();
      const steps = 10;
      for (var i = 0; i <= steps; i++) {
        final y = y0 - h * .03 + (hc + h * .06) * i / steps;
        final x = front - h * .004 + math.sin(y * .21 + t * 40) * h * .006;
        i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
      }
      c.drawPath(line, DragonHudFx.stroke(DragonPalette.flame, k * 4.5, .55));
      c.drawPath(line, DragonHudFx.stroke(DragonPalette.flameCore, k * 1.6));
    }
    c.restore();
    return true;
  }

  // The card's layout only depends on the viewport and the boss's words, so
  // it is measured, laid out and pathed once.
  static _Card? _cardBuilt;

  static _Card _card(Size size, SkyBoss boss) {
    // The plate must stop short of the dragon's muzzle, which juts some two
    // and a half hit-radii left of its heart when the head is up.
    final h = size.height;
    final left = math.max(h * .04, size.width * .075);
    final room = boss.x.isFinite
        ? boss.x * h - 2.65 * h * SkyBoss.radius * 1.04 - h * .016 - left
        : 1e6;
    final built = _cardBuilt;
    if (built != null &&
        built.size == size &&
        built.number == boss.number &&
        built.name == boss.name &&
        built.room == room.round()) {
      return built;
    }
    return _cardBuilt = _Card(size, boss, room);
  }

  // Laid-out text, kept between frames and bounded.
  static final Map<Object, TextPainter> _texts = {};

  static TextPainter _text(
    Object key,
    String value,
    double size, {
    Color color = DragonPalette.gold,
    double spacing = 0,
    double? stroke,
    double alpha = 1,
    bool italic = false,
    double? width,
    int maxLines = 1,
  }) {
    final bucket = (alpha.clamp(0.0, 1.0) * 8).round();
    final id = (
      key,
      value,
      size,
      spacing,
      stroke,
      bucket,
      color.toARGB32(),
      italic,
      width,
      maxLines,
    );
    var p = _texts[id];
    if (p == null) {
      if (_texts.length >= 96) _texts.clear();
      var style = heading(size, color: color.withValues(alpha: bucket / 8));
      if (italic) style = style.copyWith(fontStyle: FontStyle.italic);
      p = _texts[id] = TextPainter(
        text: TextSpan(
          text: value,
          style: stroke == null
              ? style.copyWith(letterSpacing: spacing)
              : style.copyWith(
                  letterSpacing: spacing,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = stroke
                    ..strokeJoin = StrokeJoin.round
                    ..color = _p.withValues(alpha: bucket / 8),
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

  /// One letter of the name at heat [stage]: -1 cold iron, then white-hot,
  /// yellow, gold, warm cream, cream.
  static TextPainter _glyph(String ch, double size, int stage, double alpha) =>
      _text(
        'glyph',
        ch,
        size,
        color: const [
          Color(0xff5a3548),
          Color(0xffffffff),
          DragonPalette.flameYellow,
          Color(0xffffcf70),
          Color(0xffffe6b4),
          _cream,
        ][stage + 1],
        spacing: 1,
        alpha: alpha,
      );

  static void _sparks(
    Canvas c,
    _Card g,
    double left,
    double top,
    double t,
    double k,
  ) {
    final young = _a..reset(), old = _b..reset();
    for (var i = 0; i < g.glyphs.length; i++) {
      final d = t - (_igniteFrom + i * _igniteStep);
      if (d <= 0 || d >= .5 || g.glyphs[i].trim().isEmpty) continue;
      for (var j = 0; j < 3; j++) {
        final s = i * 3 + j;
        final vx = (24 + DragonHudFx.hash(s, 81) * 70) * k;
        final vy = -(50 + DragonHudFx.hash(s, 83) * 80) * k;
        final p = Offset(
          left +
              g.glyphX[i] +
              g.nameSize * (.2 + DragonHudFx.hash(s, 85) * .5) +
              vx * d,
          top + g.nameSize * .3 + vy * d + 260 * k * d * d,
        );
        final r = (1.9 - d * 2.4) * k * (j == 0 ? 1.2 : .8);
        (d < .22 ? young : old).addOval(Rect.fromCircle(center: p, radius: r));
      }
    }
    c.drawPath(young, DragonHudFx.solid(DragonPalette.flameCore));
    c.drawPath(old, DragonHudFx.solid(DragonPalette.flame, .9));
  }

  /// A small flame glyph, three tongues deep, centred on [at].
  static void _flame(
    Canvas c,
    Offset at,
    double size,
    double age,
    bool reduced,
    double alpha,
  ) {
    final sway = reduced ? 0.0 : math.sin(age * 9) * size * .06;
    void tongue(double scale, Color color) {
      final s = size * scale;
      c.drawPath(
        _c
          ..reset()
          ..moveTo(at.dx, at.dy + s * .5)
          ..cubicTo(
            at.dx - s * .44,
            at.dy + s * .3,
            at.dx - s * .3,
            at.dy - s * .18,
            at.dx + sway,
            at.dy - s * .62,
          )
          ..cubicTo(
            at.dx + s * .26,
            at.dy - s * .2,
            at.dx + s * .46,
            at.dy + s * .3,
            at.dx,
            at.dy + s * .5,
          )
          ..close(),
        DragonHudFx.solid(color, alpha),
      );
    }

    tongue(1.12, _p);
    tongue(1, DragonPalette.flame);
    tongue(.66, DragonPalette.flameGold);
    tongue(.34, DragonPalette.flameCore);
  }

  // ----------------------------------------------------------------- sky --

  /// The sky smoulders: a warm glow along the horizon, smoke banks along the
  /// top, and embers rising through the air. It reddens as the dragon
  /// inhales, roars and rages, flashes warm as the dragon is revealed, and
  /// blushes blood-red once the fury begins.
  ///
  /// It is drawn as cheaply as a whole-sky wash can be: at most two gradient
  /// rects, one for the smoke and fury's blush overhead and one for the
  /// horizon's glow and the breath's heat below, each already blended into
  /// one cached gradient (so nothing is painted twice over the same pixels)
  /// and each only as tall as it visibly tints; the wisps are six ovals and
  /// the embers three batches of round points, none with a bounding box
  /// bigger than what it draws. A pass whose strongest alpha is under .015
  /// is skipped and one under .06 eases in, so nothing pops.
  static void mood(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!size.isFinite || !boss.age.isFinite) return;
    final h = size.height, w = size.width;
    final storm = m.storm;
    if (!storm.isFinite || storm <= 0) return;
    final age = boss.age;
    // The reveal's flash and the roar's swell lift the whole sky's heat.
    final surge = m.reducedMotion
        ? m.roar * .8
        : math.max(BossMotion.pulse(age - 1.9, .6), m.roar * .8);
    final heat = math
        .max(
          math.max(
            boss.breathWarning,
            boss.breathing ? 1.0 : (boss.enraged ? .45 : 0.0),
          ),
          surge,
        )
        .clamp(0.0, 1.0);
    // Fury: the sky blushes, deepest overhead.
    final rage = boss.enraged
        ? BossMotion.ease(_ramp(age - boss.enragedAt, 0, .6))
        : 0.0;

    // The horizon's glow and the heat on it, one gradient over the lower
    // half (above y = .5 h the horizon's tint is under 2%).
    // (Each gradient is blended once for its ratio of heat or fury, in 1/32
    // steps, and cached; the storm's fade rides on the paint's alpha, so it
    // is smooth and builds nothing.)
    final low = storm * _knee((.22 + .2 * heat) * storm);
    if (low > 0) {
      final r = (heat * 32).round();
      c.drawRect(
        Rect.fromLTRB(0, h * .5, w, h),
        DragonHudFx.shaded(
          DragonHudFx.shader(
            ('moodLow', h, r),
            () => _blend(
              h,
              const [
                .5,
                .56,
                .62,
                .68,
                .72,
                .76,
                .772,
                .78,
                .82,
                .88,
                .94,
                1.0,
              ],
              (y) => _over(_heat(y, r / 32), _horizon(y, 1)),
              first: 0,
            ),
          ),
          low,
        ),
      );
    }

    // The smoke along the top, and the fury's blush under it.
    final top = storm * _knee((.42 + .2 * rage) * storm);
    if (top > 0) {
      if (rage <= 0) {
        final haze = Rect.fromLTWH(0, 0, w, h * .22);
        c.drawRect(
          haze,
          DragonHudFx.shaded(
            DragonHudFx.shader(
              ('haze', size),
              () => DragonKit.linear(haze.topCenter, haze.bottomCenter, [
                _smoke.withValues(alpha: .42),
                _smoke.withValues(alpha: 0),
              ]).shader!,
            ),
            top,
          ),
        );
      } else {
        final r = (rage * 32).round();
        c.drawRect(
          Rect.fromLTRB(0, 0, w, h * .5),
          DragonHudFx.shaded(
            DragonHudFx.shader(
              ('moodTop', h, r),
              () => _blend(h, const [
                0,
                .05,
                .1,
                .15,
                .22,
                .3,
                .4,
                .5,
              ], (y) => _over(_haze(y, 1), _fury(y, r / 32))),
            ),
            top,
          ),
        );
      }
    }

    // Smoke hangs along the top edge in long, soft wisps.
    final wispA = .22 * storm;
    final wisp = _knee(wispA);
    if (wisp > 0) {
      final drift = m.reducedMotion ? 0.0 : age * h * .025;
      final paint = DragonKit.fill(_ash, wispA * wisp);
      for (var i = 0; i < 6; i++) {
        final span = w + h * 1.2;
        final x = ((i * .31 * w + drift * (1 + i % 3 * .25)) % span) - h * .6;
        final y = h * (.03 + DragonHudFx.hash(i, 5) * .09);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: h * (.5 + DragonHudFx.hash(i, 3) * .4),
            height: h * (.035 + DragonHudFx.hash(i, 7) * .025),
          ),
          paint,
        );
      }
    }

    // Embers rising on the heat: small gold ones and larger orange ones,
    // drawn as round points in three batches (one op each, and no bounding
    // box across the whole sky).
    final emberA = (.45 + heat * .35) * storm;
    final ember = _knee(emberA);
    if (ember > 0) {
      final small = _pts1..clear(), big = _pts2..clear(), warm = _pts3..clear();
      for (var i = 0; i < 28; i++) {
        final speed = .05 + DragonHudFx.hash(i, 7) * .06;
        final life = m.reducedMotion
            ? DragonHudFx.hash(i, 9)
            : (age * speed + DragonHudFx.hash(i, 9)) % 1;
        final x =
            DragonHudFx.hash(i, 11) * w +
            (m.reducedMotion ? 0 : math.sin(age * 1.3 + i) * h * .02);
        final y = h * (1.05 - life * 1.1);
        (i % 4 == 0
                ? warm
                : DragonHudFx.hash(i, 13) < .5
                ? small
                : big)
            .add(Offset(x, y));
      }
      void dots(List<Offset> pts, double radius, Color color, double alpha) {
        if (pts.isEmpty) return;
        c.drawPoints(
          ui.PointMode.points,
          pts,
          DragonKit.line(color, radius * 2, alpha),
        );
      }

      dots(small, h * .0041, DragonPalette.flameGold, emberA * ember);
      dots(big, h * .0061, DragonPalette.flameGold, emberA * ember);
      dots(
        warm,
        h * .0068,
        DragonPalette.flame,
        (.4 + heat * .3) * storm * ember,
      );
    }
  }

  static final List<Offset> _pts1 = [], _pts2 = [], _pts3 = [];

  /// How far a wash of peak alpha [peak] is drawn: 0 under .015 (a tint of
  /// four levels in 255, unseen), easing to 1 at .06. It eases, not cuts, so
  /// a fade never pops where the skip begins.
  static double _knee(double peak) => BossMotion.ease(_ramp(peak, .015, .06));

  // The sky washes as functions of height (in screen heights), each a colour
  // and an alpha, so they can be blended into one gradient.
  static (Color, double) _horizon(double y, double k) {
    final t = (y - .45) / .55;
    if (t <= 0) return (DragonPalette.flame, 0);
    if (t <= .6) return (DragonPalette.flame, k * .1 * t / .6);
    final s = (t - .6) / .4;
    return (
      Color.lerp(DragonPalette.flame, DragonPalette.flameDark, s)!,
      k * (.1 + .12 * s),
    );
  }

  static (Color, double) _heat(double y, double k) {
    final t = (y - .62) / .38;
    if (t <= 0) return (DragonPalette.flameGold, 0);
    if (t <= .4) return (DragonPalette.flameGold, k * .14 * t / .4);
    final s = (t - .4) / .6;
    return (
      Color.lerp(DragonPalette.flameGold, DragonPalette.flame, s)!,
      k * (.14 + .06 * s),
    );
  }

  static (Color, double) _fury(double y, double k) {
    final t = (y / .5).clamp(0.0, 1.0);
    return (
      Color.lerp(DragonPalette.flameDark, DragonPalette.flame, t)!,
      k * (.2 + (.03 - .2) * t),
    );
  }

  static (Color, double) _haze(double y, double k) =>
      (_smoke, y >= .22 ? 0.0 : k * .42 * (1 - y / .22));

  /// [top] laid over [bottom], both as (colour, alpha).
  static (Color, double) _over((Color, double) top, (Color, double) bottom) {
    final (ct, at) = top;
    final (cb, ab) = bottom;
    final a = at + ab * (1 - at);
    if (a <= 0) return (cb, 0);
    final wt = at / a, wb = ab * (1 - at) / a;
    return (
      Color.from(
        alpha: 1,
        red: ct.r * wt + cb.r * wb,
        green: ct.g * wt + cb.g * wb,
        blue: ct.b * wt + cb.b * wb,
      ),
      a,
    );
  }

  /// A vertical gradient over screen heights [ys] of [sample], for a screen
  /// [h] tall; [first] (if given) is the alpha the first stop is pinned to,
  /// so the wash starts from nothing.
  static ui.Shader _blend(
    double h,
    List<double> ys,
    (Color, double) Function(double y) sample, {
    double? first,
  }) {
    final colors = <Color>[];
    for (var i = 0; i < ys.length; i++) {
      final (color, alpha) = sample(ys[i]);
      colors.add(
        color.withValues(alpha: i == 0 && first != null ? first : alpha),
      );
    }
    return DragonKit.linear(
      Offset(0, ys.first * h),
      Offset(0, ys.last * h),
      colors,
      [for (final y in ys) (y - ys.first) / (ys.last - ys.first)],
    ).shader!;
  }

  // ---------------------------------------------------------------- roar --

  /// The roar: the head flung back looses a crown of flame from the jaws. It
  /// climbs until it meets the underside of the letterbox, then rolls along
  /// it instead of being cut off. A thick shockwave rolls out of the chest,
  /// speed lines and a shower of embers fly, and a pressure ring leaves the
  /// jaws. Under Reduced Motion one still frame of it fades in place.
  static void roar(
    Canvas c,
    Offset center,
    double h,
    BossMotion m, {
    required Offset mouth,
  }) {
    final boss = m.boss;
    if (!center.isFinite || !mouth.isFinite || !h.isFinite) return;
    if (!boss.age.isFinite) return;
    final k = boss.age - SkyBoss.roarAt;
    final reduced = m.reducedMotion;
    // The underside of the letterbox: nothing is drawn above it.
    final ceiling = h * .082 * m.focus + h * .018;
    final rise = reduced
        ? m.roar * .7
        : BossMotion.ease(_ramp(k, 0, .22)) *
              (1 - BossMotion.ease(_ramp(k, .5, .85)));
    final origin = Offset.lerp(center, mouth, .3)!;

    // The shockwave: one thick ring whose weight melts away as it grows.
    final u = reduced ? .55 : _ramp(k, 0, .5);
    if (reduced ? m.roar > 0 : (u > 0 && u < 1)) {
      final fade = reduced ? m.roar : 1 - u;
      final r = h * (reduced ? .34 : .9) * (reduced ? 1 : _outCubic(u));
      c.drawCircle(
        origin,
        r,
        DragonHudFx.stroke(
          DragonPalette.flame,
          h * .06 * (1 - u * .55),
          .25 * fade,
        ),
      );
      c.drawCircle(
        origin,
        r,
        DragonHudFx.stroke(DragonPalette.flameCore, h * .006, .55 * fade),
      );
    }
    if (!reduced) {
      // A tighter pressure ring leaves the jaws.
      final v = _ramp(k, 0, .38);
      if (v > 0 && v < 1) {
        c.drawOval(
          Rect.fromCenter(
            center: mouth,
            width: h * .7 * _outCubic(v),
            height: h * .48 * _outCubic(v),
          ),
          DragonHudFx.stroke(
            DragonPalette.flameGold,
            h * .005 * (1 - v * .5),
            .7 * (1 - v),
          ),
        );
      }
      // Sixteen speed lines fly off the chest.
      final w = _ramp(k, 0, .55);
      if (w > 0 && w < 1) {
        final lines = _a..reset();
        for (var i = 0; i < 16; i++) {
          final a = i * math.pi / 8 + .2 + DragonHudFx.hash(i, 91) * .18;
          final d = Offset(math.cos(a) * 1.25, math.sin(a));
          final from = h * (.3 + .38 * _outCubic(w));
          final to = from + h * (.05 + DragonHudFx.hash(i, 93) * .05);
          lines
            ..moveTo(origin.dx + d.dx * from, origin.dy + d.dy * from)
            ..lineTo(origin.dx + d.dx * to, origin.dy + d.dy * to);
        }
        c.drawPath(
          lines,
          DragonHudFx.stroke(DragonPalette.boneLit, h * .004, (1 - w) * .8),
        );
      }
    }

    if (rise > 0) _plume(c, mouth, h, boss.age, rise, ceiling);

    if (!reduced && k > 0 && k < 1.1) {
      // Forty embers thrown up out of the jaws.
      final gold = _a..reset(), warm = _b..reset();
      for (var i = 0; i < 40; i++) {
        final a = -math.pi / 2 + (DragonHudFx.hash(i, 95) - .5) * 2.5;
        final speed = h * (.3 + DragonHudFx.hash(i, 97) * .55);
        final tau = k / 1.1;
        final at =
            mouth +
            Offset(math.cos(a), math.sin(a)) * speed * k +
            Offset(0, h * .5 * k * k * .5);
        final s = h * (.0035 + DragonHudFx.hash(i, 99) * .004) * (1 - tau * .6);
        (i.isEven ? gold : warm).addOval(
          Rect.fromCircle(center: at, radius: s),
        );
      }
      final fade = 1 - (k / 1.1) * (k / 1.1);
      c.drawPath(gold, DragonHudFx.solid(DragonPalette.flameYellow, fade));
      c.drawPath(warm, DragonHudFx.solid(DragonPalette.flame, fade));
    }
  }

  // The crown of flame: five tongues fanning from the jaws. Each climbs
  // until it reaches [ceiling], then turns and splashes a short way along
  // it, so a tall plume in a short frame is folded rather than cropped.
  static void _plume(
    Canvas c,
    Offset mouth,
    double h,
    double age,
    double rise,
    double ceiling,
  ) {
    const fan = [
      (-1.05, .8),
      (-.62, 1.0),
      (-.22, .86),
      (.18, 1.0),
      (.58, .8),
      (1.0, .62),
    ];
    final tongues = <(List<Offset>, List<double>, double)>[];
    for (var j = 0; j < fan.length; j++) {
      final (a, reach) = fan[j];
      final dir = Offset(math.sin(a), -math.cos(a));
      final half = h * .041 * reach;
      final nominal = h * .29 * rise * reach;
      final yc = ceiling + half * 1.05;
      final room = dir.dy < -.1 ? (mouth.dy - yc) / -dir.dy : double.infinity;
      final len = math.max(h * .04, math.min(nominal, room));
      final wob = Offset(math.sin(age * 17 + j * 3) * h * .007, 0);
      final contact = mouth + dir * len;
      final turn = math.min(
        nominal > room ? (nominal - len) * .85 : 0.0,
        h * .07,
      );
      if (turn <= h * .01) {
        tongues.add((
          [
            mouth,
            mouth + dir * len * .35 + wob,
            mouth + dir * len * .7 - wob + Offset(0, -len * .05),
            contact,
          ],
          const [.5, 1, .7, 0],
          half,
        ));
      } else {
        final s = dir.dx >= 0 ? 1.0 : -1.0;
        tongues.add((
          [
            mouth,
            mouth + dir * len * .45 + wob,
            contact,
            contact + Offset(s * turn * .6, h * .008) - wob,
            contact + Offset(s * turn, h * .024),
          ],
          const [.5, 1, .9, .55, 0],
          half,
        ));
      }
    }
    // Firelight on the underside of the letterbox where the flames meet it:
    // a flat ellipse of warmth, its middle on the ceiling.
    c.save();
    c.translate(mouth.dx - h * .02, ceiling);
    c.scale(h * .36, h * .1);
    c.drawCircle(
      Offset.zero,
      1,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          'plumeGlow',
          () => DragonKit.radial(
            Offset.zero,
            1,
            [
              DragonPalette.flameGold.withValues(alpha: .65),
              DragonPalette.flame.withValues(alpha: .25),
              DragonPalette.flame.withValues(alpha: 0),
            ],
            const [0, .45, 1],
          ).shader!,
        ),
        math.min(1.0, rise * 1.4),
      ),
    );
    c.restore();
    for (final (color, width, depth) in const [
      (DragonPalette.flameDark, 1.0, 1.0),
      (DragonPalette.flame, .74, .93),
      (DragonPalette.flameYellow, .5, .82),
      (DragonPalette.flameCore, .26, .66),
    ]) {
      for (final (spine, widths, half) in tongues) {
        final pts = [for (final p in spine) mouth + (p - mouth) * depth];
        final ws = [for (final v in widths) v * half * 2 * width];
        c.drawPath(
          DragonKit.tube(pts, ws, into: _a..reset()),
          DragonKit.fill(color, .96),
        );
      }
    }
  }

  // ---------------------------------------------------------------- fury --

  /// Crossing into fury: a ring of fire rolls out from the dragon's heart,
  /// crowned with licking flame tongues, and burns away; a hot flash blooms
  /// at its heart and a second, fainter ring follows. Under Reduced Motion
  /// the ring hangs at half size and fades in place.
  static void rage(Canvas c, Offset center, double h, BossMotion m) {
    if (!center.isFinite || !h.isFinite) return;
    final u = BossMotion.ramp(m.boss.age - m.boss.enragedAt, 0, .9);
    if (!u.isFinite || u <= 0 || u >= 1) return;
    final reduced = m.reducedMotion;
    final time = reduced ? 0.0 : m.boss.age;
    if (!reduced && u < .35) {
      // The heart flares first.
      final f = 1 - u / .35;
      c.save();
      c.translate(center.dx, center.dy);
      c.scale(h * (.16 + .2 * (1 - f)));
      c.drawCircle(
        Offset.zero,
        1,
        DragonHudFx.shaded(
          DragonHudFx.shader(
            'rageCore',
            () => DragonKit.radial(
              Offset.zero,
              1,
              [
                DragonPalette.flameCore.withValues(alpha: .9),
                DragonPalette.flame.withValues(alpha: .45),
                DragonPalette.flameDark.withValues(alpha: 0),
              ],
              const [0, .4, 1],
            ).shader!,
          ),
          f * f,
        ),
      );
      c.restore();
    }
    for (var ring = 0; ring < 2; ring++) {
      final v = ring == 0 ? u : _ramp(u, .16, 1);
      if (v <= 0 || v >= 1) continue;
      final e = reduced ? .55 : _outCubic(v);
      final fade = (1 - v) * (1 - v) * (ring == 0 ? 1 : .55);
      final r = h * (.12 + e * (ring == 0 ? .36 : .3));
      final layers = ring == 0 ? 4 : 2;
      for (var layer = 0; layer < layers; layer++) {
        final color = const [
          DragonPalette.flameDark,
          DragonPalette.flame,
          DragonPalette.flameYellow,
          DragonPalette.flameCore,
        ][layer];
        final shrink = const [1.0, .78, .52, .3][layer];
        final path = _a..reset();
        _crown(path, center, r, 30, (1 - v * .5) * shrink, time);
        c.drawPath(path, DragonKit.fill(color, fade * .95));
        // The band the tongues grow from.
        c.drawOval(
          Rect.fromCenter(center: center, width: r * 2.6, height: r * 2),
          DragonKit.line(
            color,
            h * const [.036, .024, .014, .006][layer] * (1 - v * .5),
            fade,
          ),
        );
      }
    }
    if (!reduced) {
      // Ten embers fly off the ring.
      final sparks = _a..reset();
      final e = _outCubic(u);
      for (var i = 0; i < 10; i++) {
        final a = i * 2.399963 + .4;
        final d = h * (.16 + e * (.32 + DragonHudFx.hash(i, 3) * .2));
        final p = center + Offset(math.cos(a) * d * 1.3, math.sin(a) * d);
        sparks.addOval(
          Rect.fromCircle(center: p, radius: h * .005 * (1 - u * .7)),
        );
      }
      c.drawPath(sparks, DragonHudFx.solid(DragonPalette.flameYellow, 1 - u));
    }
  }

  // A ring of [n] flame tongues round [center] at radius [r] (wide by a
  // third: the dragon's ring is an ellipse). Each tongue is a closed, curved
  // lick that leans with the swirl and flickers on [time].
  static void _crown(
    Path path,
    Offset center,
    double r,
    int n,
    double length,
    double time,
  ) {
    Offset at(double angle, double radius) => Offset(
      center.dx + math.cos(angle) * radius * 1.3,
      center.dy + math.sin(angle) * radius,
    );
    final step = math.pi * 2 / n;
    for (var i = 0; i < n; i++) {
      final a0 = i * step;
      final flick = .5 + .5 * math.sin(a0 * 5 + time * 11);
      final len = r * (.16 + .2 * flick) * length;
      final lean = step * (.35 + .15 * math.sin(a0 * 3 + time * 7));
      final base0 = at(a0 - step * .05, r * .97);
      final base1 = at(a0 + step * 1.05, r * .97);
      final tip = at(a0 + step * .5 + lean, r + len);
      final c0 = at(a0 + step * .1, r + len * .55);
      final c1 = at(a0 + step * .95 + lean * .4, r + len * .45);
      path
        ..moveTo(base0.dx, base0.dy)
        ..quadraticBezierTo(c0.dx, c0.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(c1.dx, c1.dy, base1.dx, base1.dy)
        ..close();
    }
  }

  // ----------------------------------------------------------------- hit --

  /// A hit: a spiked flash of gold with a ring, a spray of embers and a
  /// chipped scale. A hit on the open heart flares white-hot with a bigger
  /// star, a second ring and a "×2" that pops so the reward reads. Under
  /// Reduced Motion the star holds still and fades.
  static void hit(
    Canvas c,
    Offset at,
    double h,
    double t, {
    required bool reduced,
    bool crit = false,
  }) {
    if (!t.isFinite || !at.isFinite || !h.isFinite || t >= 1) return;
    final base = h * (crit ? .1 : .062);
    final size =
        base *
        (reduced
            ? .85
            : (.6 + .4 * _outCubic(_ramp(t, 0, .22))) * (1 - t * .3));
    final fade = reduced ? 1 - t : 1 - t * t;
    // A white-hot flash under it all.
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(size * 1.7);
    c.drawCircle(
      Offset.zero,
      1,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          'hitFlash',
          () => DragonKit.radial(
            Offset.zero,
            1,
            [
              DragonPalette.white.withValues(alpha: .95),
              DragonPalette.flameCore.withValues(alpha: .5),
              DragonPalette.flameGold.withValues(alpha: 0),
            ],
            const [0, .3, 1],
          ).shader!,
        ),
        fade * (crit ? 1 : .8),
      ),
    );
    c.restore();
    final star = _a..reset();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + .2;
      final long = i % 4 == 0 ? 1.4 : 1.0;
      final r = size * (i.isEven ? long : .4);
      final p = at + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c.drawPath(star, DragonKit.line(_p, h * .008, fade));
    c.drawPath(
      star,
      DragonKit.fill(
        crit ? DragonPalette.flameCore : DragonPalette.flameGold,
        fade,
      ),
    );
    c.drawCircle(at, size * .3, DragonKit.fill(DragonPalette.white, fade));
    if (!reduced) {
      final ring = _outCubic(_ramp(t, 0, .6));
      c.drawCircle(
        at,
        size * (.9 + ring * (crit ? 2.6 : 1.7)),
        DragonKit.line(
          crit ? DragonPalette.flameCore : DragonPalette.flameGold,
          h * .005 * (1 - t),
          (1 - t) * (1 - t) * .9,
        ),
      );
      _embers(c, at, h, t, crit ? 12 : 7, h * (crit ? .16 : .1), true);
    }
    if (crit) {
      final pop = reduced ? 1.0 : 1 + .4 * (1 - _outCubic(_ramp(t, 0, .2)));
      final lift = reduced ? 0.0 : _outCubic(t) * h * .06;
      final size2 = h * .07;
      final fill = _text(
        'x2',
        '×2',
        size2,
        color: DragonPalette.flameCore,
        alpha: fade,
      );
      final line = _text('x2', '×2', size2, stroke: h * .011, alpha: fade);
      final at2 = at + Offset(0, -h * .1 - lift);
      c.save();
      c.translate(at2.dx, at2.dy);
      c.scale(pop);
      final corner = Offset(-fill.width / 2, -fill.height / 2);
      line.paint(c, corner);
      fill.paint(c, corner);
      c.restore();
    }
  }

  static void _embers(
    Canvas c,
    Offset at,
    double h,
    double t,
    int count,
    double reach,
    bool chips,
  ) {
    if (t <= 0 || t >= 1) return;
    final travel = _outCubic(t);
    final fade = 1 - t * t;
    final gold = _a..reset(), hot = _b..reset();
    for (var i = 0; i < count; i++) {
      final a = i * 2.399963 + .3;
      final d = reach * (.3 + travel * (.5 + DragonHudFx.hash(i, 3) * .5));
      final p = at + Offset(math.cos(a) * d, math.sin(a) * d + t * t * h * .08);
      final s = h * (.004 + DragonHudFx.hash(i, 5) * .005) * (1 - t * .6);
      (i.isEven ? gold : hot).addOval(Rect.fromCircle(center: p, radius: s));
    }
    c.drawPath(gold, DragonKit.fill(DragonPalette.flameYellow, fade));
    c.drawPath(hot, DragonKit.fill(DragonPalette.flame, fade));
    if (chips) {
      final scales = _a..reset();
      for (var i = 0; i < 3; i++) {
        final a = i * 2.1 + .8;
        final d = reach * (.4 + travel * .6);
        final p =
            at + Offset(math.cos(a) * d, math.sin(a) * d + t * t * h * .12);
        _poly(scales, _scaleTemplate, p, h * .011, a + t * 6);
      }
      c.drawPath(scales, DragonKit.fill(DragonPalette.scaleLit, fade));
      c.drawPath(scales, DragonKit.line(_p, h * .0035, fade));
    }
  }

  // -------------------------------------------------------------- defeat --

  // Shard outlines in unit space: a burnt scale, a shard of bone, a scrap of
  // wing membrane.
  static const _scaleTemplate = [
    Offset(-1, .05),
    Offset(-.15, -.8),
    Offset(1, -.1),
    Offset(.25, .75),
  ];
  static const _boneTemplate = [
    Offset(-1.3, 0),
    Offset(.6, -.32),
    Offset(1.5, .02),
    Offset(.7, .3),
  ];
  static const _scrapTemplate = [
    Offset(-1, -.5),
    Offset(-.45, -.62),
    Offset(.1, -1),
    Offset(.55, -.55),
    Offset(1.05, -.3),
    Offset(.7, .1),
    Offset(.95, .65),
    Offset(.25, .5),
    Offset(-.2, .95),
    Offset(-.55, .35),
    Offset(-1.05, .3),
  ];

  /// Adds the outline [pts] to [path], scaled by [scale] and turned by [turn]
  /// about [at]; [flip] squashes it across the turn's axis (a tumbling scrap).
  static void _poly(
    Path path,
    List<Offset> pts,
    Offset at,
    double scale,
    double turn, [
    double flip = 1,
  ]) {
    final cs = math.cos(turn), sn = math.sin(turn);
    for (var i = 0; i < pts.length; i++) {
      final x = pts[i].dx * scale * flip, y = pts[i].dy * scale;
      final p = Offset(at.dx + x * cs - y * sn, at.dy + x * sn + y * cs);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
  }

  /// The burst: the dragon's fire escapes all at once. [t] is 0 to 1 over the
  /// 1.3 s after `SkyBoss.burstAt`. A white-hot supernova swells to some 200
  /// pixels round and a flare of spikes stabs through it; sparks, scorched
  /// scales, bone shards and scraps of wing membrane are flung out on arcs;
  /// dark ash billows up with glowing cores that cool to cinders; and the
  /// first embers of the snow begin to fall (see [emberSnow] for the rest).
  /// Under Reduced Motion it holds one scattered frame and fades in place.
  static void burst(Canvas c, Offset at, double h, double t, bool reduced) {
    if (!t.isFinite || !at.isFinite || !h.isFinite || t >= 1) return;
    final k = reduced ? .55 : t * 1.3;
    // Reduced Motion fades the still burst in over a moment (no pop) and out.
    final fade = reduced ? (1 - t) * _ramp(t, 0, .15) : 1.0;

    // Afterglow: a red haze that lingers over the scorched sky.
    _disc(
      c,
      at,
      h * .62 * (.6 + .4 * _outCubic(_ramp(k, 0, .6))),
      'burstHaze',
      const [Color(0x00b32a3a), Color(0x55b32a3a), Color(0x00b32a3a)],
      const [0, .55, 1],
      (1 - _ramp(k, .5, 1.3)) * fade,
    );

    // The supernova: a white-hot disc, a rim of fire, and a flare of spikes.
    // Reduced Motion holds the fire at its brightest, then fades it.
    final kn = reduced ? .2 : k;
    final grow = _outCubic(_ramp(kn, 0, .35));
    final flash = (1 - _ramp(kn, .12, .6)) * fade;
    if (flash > 0) {
      _disc(
        c,
        at,
        h * .58 * grow,
        'burstNova',
        const [
          Color(0xffffffff),
          DragonPalette.flameCore,
          DragonPalette.flameYellow,
          DragonPalette.flame,
          Color(0x00b32a3a),
        ],
        const [0, .22, .48, .78, 1],
        flash,
      );
      final spikes = _a..reset();
      final reach = h * .7 * grow * (1 - _ramp(kn, .12, .5));
      if (reach > 0) {
        final turn = reduced ? .2 : kn * .5;
        for (var i = 0; i < 16; i++) {
          final a = turn + i * math.pi / 8;
          final r =
              reach *
              (i % 4 == 0
                  ? 1
                  : i.isEven
                  ? .62
                  : .3);
          final w = i % 4 == 0 ? h * .05 : h * .03;
          final l = Offset(math.cos(a - .1), math.sin(a - .1)) * w;
          final rr = Offset(math.cos(a + .1), math.sin(a + .1)) * w;
          spikes
            ..moveTo(at.dx + l.dx, at.dy + l.dy)
            ..lineTo(at.dx + math.cos(a) * r, at.dy + math.sin(a) * r)
            ..lineTo(at.dx + rr.dx, at.dy + rr.dy)
            ..close();
        }
        c.drawPath(spikes, DragonHudFx.solid(DragonPalette.white, .85 * flash));
      }
    }

    // The smoke climbs out of the fire: dark ash with ember cores, dark
    // enough to read on any sky.
    _billows(c, at, h, k, fade);

    // Sparks: fast streaks, gone in half a second.
    if (!reduced && k < .6) {
      final sparks = _a..reset();
      for (var i = 0; i < 26; i++) {
        final a = i * 2.399963 + DragonHudFx.hash(i, 101) * .5;
        final speed = h * (.9 + DragonHudFx.hash(i, 103) * 1.1);
        final d0 = speed * (1 - math.exp(-k * 3.2)) / 3.2;
        final d1 =
            speed * (1 - math.exp(-(k - .035).clamp(0.0, 9.0) * 3.2)) / 3.2;
        final dir = Offset(math.cos(a) * 1.15, math.sin(a));
        final fall = Offset(0, h * .45 * k * k);
        sparks
          ..moveTo(at.dx + dir.dx * d1 + fall.dx, at.dy + dir.dy * d1 + fall.dy)
          ..lineTo(
            at.dx + dir.dx * d0 + fall.dx,
            at.dy + dir.dy * d0 + fall.dy,
          );
      }
      c.drawPath(
        sparks,
        DragonHudFx.stroke(DragonPalette.flameCore, h * .0055, 1 - k / .6),
      );
    }

    // Molten drops: heavy flecks of liquid fire that arc out and fall.
    if (!reduced && k < .95) {
      final orange = _a..reset(), yellow = _b..reset();
      for (var i = 0; i < 22; i++) {
        final a = -math.pi / 2 + (DragonHudFx.hash(i, 141) - .5) * 4.4;
        final speed = h * (.35 + DragonHudFx.hash(i, 143) * .6);
        final drag = (1 - math.exp(-k * 2.2)) / 2.2;
        final p =
            at +
            Offset(math.cos(a) * 1.25, math.sin(a)) * speed * drag +
            Offset(0, h * .7 * k * k);
        final r = h * (.008 + DragonHudFx.hash(i, 145) * .009) * (1 - k * .5);
        orange.addOval(Rect.fromCircle(center: p, radius: r));
        yellow.addOval(Rect.fromCircle(center: p, radius: r * .5));
      }
      final drops = 1 - _ramp(k, .55, .95);
      c.drawPath(orange, DragonHudFx.solid(DragonPalette.flame, drops));
      c.drawPath(yellow, DragonHudFx.solid(DragonPalette.flameYellow, drops));
    }

    // Debris: ten scorched scales and bone shards, four scraps of membrane.
    final scales = _a..reset(), bones = _b..reset(), scraps = _c..reset();
    final inner = _d..reset();
    const shards = 14;
    for (var i = 0; i < shards; i++) {
      final a = i * 2.399963 + .35;
      final speed = h * (.55 + DragonHudFx.hash(i, 105) * .7);
      final drag = reduced ? k : (1 - math.exp(-k * 2.6)) / 2.6;
      final p =
          at +
          Offset(math.cos(a) * 1.2, math.sin(a)) * speed * drag +
          Offset(0, h * .55 * k * k * (reduced ? 0 : 1));
      final spin =
          a +
          (reduced
              ? 0
              : k * (5 + DragonHudFx.hash(i, 107) * 6) * (i.isEven ? 1 : -1));
      if (i < 4) {
        final size = h * (.05 + DragonHudFx.hash(i, 109) * .014);
        final flip = reduced ? 1.0 : math.cos(k * 7 + i);
        _poly(scraps, _scrapTemplate, p, size, spin, flip);
        _poly(inner, _scrapTemplate, p, size * .6, spin, flip);
      } else if (i.isEven) {
        _poly(
          scales,
          _scaleTemplate,
          p,
          h * (.03 + DragonHudFx.hash(i, 111) * .01),
          spin,
        );
      } else {
        _poly(
          bones,
          _boneTemplate,
          p,
          h * (.026 + DragonHudFx.hash(i, 113) * .008),
          spin,
        );
      }
    }
    if (!reduced && k < .5) {
      // A streak of fire behind each shard while it is still fast.
      final trails = _e..reset();
      for (var i = 0; i < shards; i++) {
        final a = i * 2.399963 + .35;
        final speed = h * (.55 + DragonHudFx.hash(i, 105) * .7);
        Offset at0(double kk) =>
            at +
            Offset(math.cos(a) * 1.2, math.sin(a)) *
                speed *
                ((1 - math.exp(-kk * 2.6)) / 2.6) +
            Offset(0, h * .55 * kk * kk);
        final from = at0(math.max(0.0, k - .06)), to = at0(k);
        trails
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);
      }
      c.drawPath(
        trails,
        DragonHudFx.stroke(DragonPalette.flameGold, h * .006, 1 - k / .5),
      );
    }
    final debris = (1 - _ramp(t, .55, 1)) * fade;
    c.drawPath(scraps, DragonHudFx.solid(DragonPalette.membraneDeep, debris));
    c.drawPath(scraps, DragonHudFx.stroke(_p, h * .0055, debris));
    c.drawPath(inner, DragonHudFx.solid(DragonPalette.membraneLit, debris));
    c.drawPath(scales, DragonHudFx.solid(DragonPalette.scale, debris));
    c.drawPath(scales, DragonHudFx.stroke(_p, h * .007, debris));
    c.drawPath(
      scales,
      DragonHudFx.stroke(DragonPalette.flame, h * .0035, debris),
    );
    c.drawPath(bones, DragonHudFx.solid(DragonPalette.bone, debris));
    c.drawPath(bones, DragonHudFx.stroke(_p, h * .0055, debris));

    if (!reduced) _snow(c, at, h, k);
  }

  // Dark ash billows: eight puffs of three lobes rise and spread from the
  // blast, each with a live ember at its core that cools to a cinder.
  static void _billows(Canvas c, Offset at, double h, double k, double fade) {
    final born = _ramp(k, .06, .55);
    if (born <= 0) return;
    final rise = _ramp(k, .1, .3);
    final dark = _a..reset(), mid = _b..reset(), lit = _c..reset();
    final core = _d..reset(), hot = _e..reset();
    for (var i = 0; i < 8; i++) {
      final a = i * 2.399963 + .9;
      final reach = h * (.1 + DragonHudFx.hash(i, 121) * .2) * _outCubic(born);
      final base =
          at +
          Offset(math.cos(a) * 1.25, math.sin(a) * .8) * reach +
          Offset(0, -h * .12 * _outCubic(_ramp(k, .1, 1.3)));
      final r =
          h *
          (.05 + DragonHudFx.hash(i, 123) * .035) *
          (.5 + 1.1 * _outCubic(born));
      for (var lobe = 0; lobe < 3; lobe++) {
        final la = lobe * 2.1 + i;
        final o = Offset(math.cos(la), math.sin(la)) * r * .55;
        final lr = r * (lobe == 0 ? 1 : .7);
        dark.addOval(
          Rect.fromCircle(
            center: base + o + Offset(r * .06, r * .12),
            radius: lr * 1.06,
          ),
        );
        mid.addOval(Rect.fromCircle(center: base + o, radius: lr));
        lit.addOval(
          Rect.fromCircle(
            center: base + o + Offset(-lr * .25, -lr * .3),
            radius: lr * .55,
          ),
        );
      }
      core.addOval(Rect.fromCircle(center: base, radius: r * .32));
      hot.addOval(Rect.fromCircle(center: base, radius: r * .16));
    }
    final live = (1 - _ramp(k, .55, 1.3)) * fade * rise;
    c.drawPath(dark, DragonHudFx.solid(_ashDeep, .95 * live));
    c.drawPath(mid, DragonHudFx.solid(_ash, .93 * live));
    c.drawPath(lit, DragonHudFx.solid(_ashLit, .45 * live));
    final glow = (1 - _ramp(k, .3, 1.0)) * fade * rise;
    c.drawPath(core, DragonHudFx.solid(DragonPalette.flame, .85 * glow));
    c.drawPath(hot, DragonHudFx.solid(DragonPalette.flameYellow, glow * glow));
  }

  static void _disc(
    Canvas c,
    Offset at,
    double radius,
    String id,
    List<Color> colors,
    List<double> stops,
    double alpha,
  ) {
    if (alpha <= 0 || radius <= 0) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius);
    c.drawCircle(
      Offset.zero,
      1,
      DragonHudFx.shaded(
        DragonHudFx.shader(
          id,
          () => DragonKit.radial(Offset.zero, 1, colors, stops).shader!,
        ),
        alpha,
      ),
    );
    c.restore();
  }

  /// The embers that linger after the burst: they drift down through the
  /// smoke and go out one by one. The burst draws the first of them; a caller
  /// that keeps calling with [k] seconds since the burst, past the burst's
  /// own 1.3 s, carries the snow to its end at 2.45 s. Under Reduced Motion
  /// there is none.
  static void emberSnow(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required bool reduced,
  }) {
    if (reduced || !k.isFinite || !at.isFinite || !h.isFinite || k <= 1.3) {
      return;
    }
    _snow(c, at, h, k);
  }

  // ------------------------------------------------------------ the gem --

  /// The defeat's signature: the dragon's heart-gem is not destroyed but
  /// freed. It pops loose out of the blast, is flung up, hangs, rises through
  /// the smoke on a trail of embers and, as the smoke thins, ignites into a
  /// warm, soft sun over the place the dragon was: fear, then awe, then
  /// triumph. [k] is seconds since the burst (`SkyBoss.burstAt`).
  ///
  /// Beats ([k], with the game's death clock = k + .85): the gem shows at
  /// .10 as the flash clears, flies to .45, rises to the sun's height by
  /// 1.10, melts into the sun over .98 to 1.32, and the sun holds to 1.55 and
  /// goes out by 2.15. The sun is small and high (it sits under the top
  /// letterbox, over the dragon's side of the sky) and dims before the
  /// victory title has finished settling, so the title's zone (the middle of
  /// the frame, from a fifth to a half of the height) is never covered: the
  /// title and its points line lie outside the sun's glow. [fade] (0 to 1)
  /// lets the game take the sun away sooner. Under Reduced Motion the gem
  /// hangs still where the sun will be, fading in, and the sun fades in and
  /// out with the same beats; nothing flies.
  ///
  /// Call it after [burst] with the same [at]:
  /// `DragonEncounterUi.victoryGem(c, at, h, k, reduced: reduced)`.
  static void victoryGem(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required bool reduced,
    double fade = 1,
  }) {
    if (!k.isFinite || !at.isFinite || !h.isFinite || !fade.isFinite) return;
    if (k <= .1 || k >= 2.15 || fade <= 0) return;
    final sunAt = Offset(at.dx + h * .16, math.max(h * .19, at.dy - h * .32));
    final flung = at + Offset(-h * .035, -h * .13);
    Offset gemAt(double kk) {
      if (reduced) return sunAt;
      final out = _outCubic(_ramp(kk, .1, .5));
      final rise = BossMotion.ease(_ramp(kk, .45, 1.1));
      final p = Offset.lerp(at, flung, out)!;
      final wobble = math.sin(kk * 9) * h * .005 * (1 - rise);
      return Offset.lerp(p, sunAt, rise)! + Offset(wobble, 0);
    }

    final gemA =
        (reduced ? _ramp(k, .1, .4) : _ramp(k, .1, .2)) *
        (1 - _ramp(k, .98, 1.32)) *
        fade;
    final sunA = _ramp(k, .95, 1.3) * (1 - _ramp(k, 1.55, 2.15)) * fade;
    final r = h * .05;

    if (gemA > 0) {
      final p = gemAt(k);
      // A trail of embers along the flight, thinning behind it.
      if (!reduced && k < 1.1) {
        final trail = _a..reset();
        for (var j = 1; j <= 9; j++) {
          final kk = k - j * .04;
          if (kk <= .1) break;
          final s =
              r * .2 * (1 - j / 10) * (.7 + .3 * DragonHudFx.hash(j, 151));
          final drift = Offset(
            (DragonHudFx.hash(j, 153) - .5) * r * .5,
            j * r * .06,
          );
          trail.addOval(Rect.fromCircle(center: gemAt(kk) + drift, radius: s));
        }
        c.drawPath(trail, DragonHudFx.solid(DragonPalette.flameGold, gemA));
      }
      // Its glow, then the stone.
      _disc(
        c,
        p,
        r * 3.1,
        'gemGlow',
        [
          DragonPalette.flameYellow.withValues(alpha: .7),
          DragonPalette.flame.withValues(alpha: .28),
          DragonPalette.flame.withValues(alpha: 0),
        ],
        const [0, .4, 1],
        gemA * (reduced ? .8 : .75 + .25 * math.sin(k * 10)),
      );
      final pop = reduced
          ? 1.0
          : 1 + .35 * math.sin(math.pi * _ramp(k, .1, .4));
      final melt = 1 - .4 * _ramp(k, .98, 1.32);
      _gem(
        c,
        p,
        r * pop * melt,
        reduced ? 1.0 : .74 + .26 * math.cos(k * 7),
        gemA,
        k,
        reduced,
      );
    }

    if (sunA > 0) {
      final grow = .7 + .3 * _outCubic(_ramp(k, .95, 1.5));
      final beat = reduced ? 1.0 : 1 + .03 * math.sin(k * 5);
      final radius = h * .19 * grow * beat;
      // Soft corona first, kept faint where the title will be.
      _disc(
        c,
        sunAt,
        radius * 1.9,
        'sunCorona',
        [
          DragonPalette.flameGold.withValues(alpha: .34),
          DragonPalette.flameGold.withValues(alpha: .14),
          DragonPalette.flame.withValues(alpha: 0),
        ],
        const [0, .5, 1],
        sunA,
      );
      if (!reduced) {
        final rays = _a..reset();
        final turn = k * .18;
        for (var i = 0; i < 12; i++) {
          final a = turn + i * math.pi / 6;
          final half = i.isEven ? .07 : .045;
          final len = radius * (i.isEven ? 1.75 : 1.35);
          rays
            ..moveTo(sunAt.dx, sunAt.dy)
            ..lineTo(
              sunAt.dx + math.cos(a - half) * len,
              sunAt.dy + math.sin(a - half) * len,
            )
            ..lineTo(
              sunAt.dx + math.cos(a + half) * len,
              sunAt.dy + math.sin(a + half) * len,
            )
            ..close();
        }
        c.drawPath(
          rays,
          DragonHudFx.solid(DragonPalette.flameGold, .17 * sunA),
        );
      }
      _disc(
        c,
        sunAt,
        radius,
        'sunCore',
        [
          const Color(0xffffffff).withValues(alpha: .95),
          DragonPalette.flameCore.withValues(alpha: .85),
          DragonPalette.flameGold.withValues(alpha: .5),
          DragonPalette.flame.withValues(alpha: .16),
          DragonPalette.flame.withValues(alpha: 0),
        ],
        const [0, .2, .5, .8, 1],
        sunA,
      );
    }
  }

  // The freed gem: a faceted stone in a gold setting, turning about its
  // vertical axis ([squash] is the width it shows), lit from the upper left.
  static void _gem(
    Canvas c,
    Offset at,
    double r,
    double squash,
    double alpha,
    double k,
    bool reduced,
  ) {
    Offset vertex(int i, double radius) {
      final a = (i + .5) * math.pi / 4;
      return Offset(
        at.dx + math.cos(a) * radius * squash,
        at.dy + math.sin(a) * radius * 1.1,
      );
    }

    // Setting: ink, then gold.
    final ring = _a..reset();
    for (var i = 0; i < 8; i++) {
      final v = vertex(i, r * 1.16);
      i == 0 ? ring.moveTo(v.dx, v.dy) : ring.lineTo(v.dx, v.dy);
    }
    ring.close();
    c.drawPath(ring, DragonHudFx.stroke(_p, r * .3, alpha));
    c.drawPath(ring, DragonHudFx.solid(DragonPalette.gold, alpha));
    // Facets, batched by how much light they take.
    final lit = _b..reset(), mid = _c..reset(), dark = _d..reset();
    for (var i = 0; i < 8; i++) {
      final outer0 = vertex(i, r), outer1 = vertex(i + 1, r);
      final inner0 = vertex(i, r * .48), inner1 = vertex(i + 1, r * .48);
      final a = (i + 1) * math.pi / 4;
      final light = .5 + .5 * math.cos(a - 3.93);
      (light > .66
            ? lit
            : light > .3
            ? mid
            : dark)
        ..moveTo(outer0.dx, outer0.dy)
        ..lineTo(outer1.dx, outer1.dy)
        ..lineTo(inner1.dx, inner1.dy)
        ..lineTo(inner0.dx, inner0.dy)
        ..close();
    }
    c.drawPath(dark, DragonHudFx.solid(DragonPalette.flameDark, alpha));
    c.drawPath(mid, DragonHudFx.solid(DragonPalette.flame, alpha));
    c.drawPath(lit, DragonHudFx.solid(DragonPalette.flameGold, alpha));
    final table = _e..reset();
    for (var i = 0; i < 8; i++) {
      final v = vertex(i, r * .48);
      i == 0 ? table.moveTo(v.dx, v.dy) : table.lineTo(v.dx, v.dy);
    }
    table.close();
    c.drawPath(table, DragonHudFx.solid(DragonPalette.flameCore, alpha));
    // A glint that crosses the stone as it turns.
    final glint = reduced ? .5 : .5 + .5 * math.sin(k * 6);
    final g = at + Offset(-r * .3, -r * .34);
    c.drawPath(
      _a
        ..reset()
        ..moveTo(g.dx, g.dy - r * (.42 + .16 * glint))
        ..lineTo(g.dx + r * .1, g.dy - r * .1)
        ..lineTo(g.dx + r * (.42 + .16 * glint), g.dy)
        ..lineTo(g.dx + r * .1, g.dy + r * .1)
        ..lineTo(g.dx, g.dy + r * (.42 + .16 * glint))
        ..lineTo(g.dx - r * .1, g.dy + r * .1)
        ..lineTo(g.dx - r * (.42 + .16 * glint), g.dy)
        ..lineTo(g.dx - r * .1, g.dy - r * .1)
        ..close(),
      DragonHudFx.solid(DragonPalette.white, alpha * .95),
    );
  }

  static void _snow(Canvas c, Offset at, double h, double k) {
    if (k <= .3 || k >= 2.5) return;
    final gold = _a..reset(), warm = _b..reset(), halo = _c..reset();
    for (var i = 0; i < 30; i++) {
      final born = .3 + DragonHudFx.hash(i, 131) * 1.3;
      final life = (k - born) / 1.1;
      if (life <= 0 || life >= 1) continue;
      final x =
          at.dx +
          (DragonHudFx.hash(i, 133) - .5) * h * .95 +
          math.sin(k * 2.2 + i) * h * .014;
      final y =
          at.dy -
          h * (.02 + DragonHudFx.hash(i, 135) * .26) +
          life * h * (.14 + DragonHudFx.hash(i, 137) * .14);
      final s = h * (.0038 + DragonHudFx.hash(i, 139) * .0034);
      // Each ember swells in, then gutters out.
      final glow = math.sin(life * math.pi);
      final center = Offset(x, y);
      (i % 3 == 0 ? warm : gold).addOval(
        Rect.fromCircle(center: center, radius: s * (.55 + glow * .9)),
      );
      halo.addOval(
        Rect.fromCircle(center: center, radius: s * (2.2 + glow * 2)),
      );
    }
    c.drawPath(halo, DragonHudFx.solid(DragonPalette.flame, .2));
    c.drawPath(gold, DragonHudFx.solid(DragonPalette.flameYellow, .95));
    c.drawPath(warm, DragonHudFx.solid(DragonPalette.flameGold, .95));
  }

  /// Three thick rings of fire roll out of the burst, [k] seconds after it:
  /// white-hot, gold and red, each weighty at first and thin as it grows to
  /// some one and a fifth of the screen's height.
  static void shockwave(Canvas c, Offset at, double h, double k) {
    if (!k.isFinite || !at.isFinite || !h.isFinite) return;
    // A ring of ash goes out with the fire, so the fire has something to
    // shine against on any sky.
    final scorch = _ramp(k, .04, .65);
    if (scorch > 0 && scorch < 1) {
      c.drawCircle(
        at,
        h * .78 * _outCubic(scorch),
        DragonHudFx.stroke(
          _ashDeep,
          h * .1 * (1 - scorch * .6),
          .4 * (1 - scorch),
        ),
      );
    }
    for (var i = 0; i < 3; i++) {
      final u = _ramp(k, i * .07, .55 + i * .1);
      if (u <= 0 || u >= 1) continue;
      final r = h * 1.2 * _outCubic(u) * (1 - i * .12);
      final fade = (1 - u) * (1 - u);
      final weight = h * (.07 - i * .017) * (1 - u * .8);
      c.drawCircle(
        at,
        r,
        DragonKit.line(DragonPalette.flameDark, weight * 1.5, fade * .32),
      );
      c.drawCircle(
        at,
        r,
        DragonKit.line(
          const [
            DragonPalette.flameCore,
            DragonPalette.flameGold,
            DragonPalette.flame,
          ][i],
          weight * .5,
          fade,
        ),
      );
    }
  }
}

/// The card's measured layout: everything that depends only on the viewport
/// and the boss's words.
class _Card {
  _Card(this.size, SkyBoss boss, double room)
    : number = boss.number,
      name = boss.name,
      room = room.round() {
    final h = size.height, w = size.width;
    final word = boss.name.toUpperCase();
    _eyebrow = 'ENCOUNTER ${boss.number.toString().padLeft(2, '0')}';
    _title = boss.title;
    // Lay it out at full size; if the plate would reach the dragon's muzzle,
    // lay it out again smaller.
    double wanted(double f) {
      final n = DragonEncounterUi._text(
        'name',
        word,
        h * .078 * f,
        color: DragonPalette.white,
        spacing: 1,
      );
      final sub = DragonEncounterUi._text(
        'title',
        _title,
        h * .0255 * f,
        spacing: 1.6,
      );
      return math.max(n.width + h * .1 * f, sub.width + h * .115 * f);
    }

    var fit = 1.0;
    final full = wanted(1);
    if (full > room && room > 0) fit = math.max(.6, room / full);
    f = fit;
    nameSize = h * .078 * f;
    final probe = DragonEncounterUi._text(
      'name',
      word,
      nameSize,
      color: DragonPalette.white,
      spacing: 1,
    );
    nameW = probe.width;
    nameH = probe.height;
    glyphs = [for (var i = 0; i < word.length; i++) word[i]];
    glyphX = [
      for (var i = 0; i < word.length; i++)
        probe
                .getBoxesForSelection(
                  TextSelection(baseOffset: i, extentOffset: i + 1),
                )
                .isEmpty
            ? 0.0
            : probe
                  .getBoxesForSelection(
                    TextSelection(baseOffset: i, extentOffset: i + 1),
                  )
                  .first
                  .left,
    ];
    outline = DragonEncounterUi._text(
      'outline',
      word,
      nameSize,
      spacing: 1,
      stroke: h * .011 * f,
    );
    final sub = subtitle(1);
    final wc = math.max(nameW + h * .1 * f, sub.width + h * .115 * f);
    final hc = h * .265 * f;
    final x0 = math.min(w * .075, w * .5 - wc);
    plate = Rect.fromLTWH(math.max(h * .04, x0), h * .108, wc, hc);
    final cut = h * .024;
    final r = plate;
    // A cut-cornered plate: chamfered top-left and bottom-right.
    body = Path()
      ..moveTo(r.left + cut, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.bottom - cut)
      ..lineTo(r.right - cut, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + cut)
      ..close();
    final ins = h * .014;
    final ri = r.deflate(ins);
    final cut2 = cut * .7;
    inner = Path()
      ..moveTo(ri.left + cut2, ri.top)
      ..lineTo(ri.right, ri.top)
      ..lineTo(ri.right, ri.bottom - cut2)
      ..lineTo(ri.right - cut2, ri.bottom)
      ..lineTo(ri.left, ri.bottom)
      ..lineTo(ri.left, ri.top + cut2)
      ..close();
    // Rows of overlapping scales, drawn as small arcs.
    final sc = Path();
    final pitch = h * .024, rowH = h * .017;
    var row = 0;
    for (var y = r.top + rowH; y < r.bottom - rowH * .5; y += rowH, row++) {
      for (
        var x = r.left + pitch * (row.isOdd ? 1 : .5);
        x < r.right - pitch * .3;
        x += pitch
      ) {
        sc
          ..moveTo(x - pitch * .5, y)
          ..quadraticBezierTo(x, y + rowH * .95, x + pitch * .5, y);
      }
    }
    scales = sc;
    // Diamond studs on the two corners the chamfers leave square.
    final st = Path();
    final d = h * .0085;
    for (final p in [
      Offset(r.right - ins, r.top + ins),
      Offset(r.left + ins, r.bottom - ins),
    ]) {
      st
        ..moveTo(p.dx, p.dy - d)
        ..lineTo(p.dx + d, p.dy)
        ..lineTo(p.dx, p.dy + d)
        ..lineTo(p.dx - d, p.dy)
        ..close();
    }
    studs = st;
  }

  final Size size;
  final int number, room;
  final String name;

  /// How much smaller than full size the plate had to be to fit.
  late final double f;
  late final double nameSize, nameW, nameH;
  late final List<String> glyphs;
  late final List<double> glyphX;
  late final TextPainter outline;
  late final String _eyebrow, _title;
  late final Rect plate;
  late final Path body, inner, scales, studs;

  // The story quote's type: a little under the epithet's size again, so it
  // reads as spoken.
  double get _quoteSize => size.height * .037 * f;
  double get _quoteWidth => plate.width - size.height * .06 * f;

  /// The quote's cream lettering at [alpha], and its ink edge; both lay out
  /// in the same box, which [quoteBox] measures.
  TextPainter quoteFill(String line, double alpha) => DragonEncounterUi._text(
    'quote',
    line,
    _quoteSize,
    color: DragonEncounterUi._cream,
    italic: true,
    width: _quoteWidth,
    maxLines: 2,
    alpha: alpha,
  );

  TextPainter quoteEdge(String line, double alpha) => DragonEncounterUi._text(
    'quoteEdge',
    line,
    _quoteSize,
    italic: true,
    width: _quoteWidth,
    maxLines: 2,
    stroke: size.height * .0075 * f,
    alpha: alpha,
  );

  /// Where the quote sits: centred under the plate.
  Rect quoteBox(String line) => Rect.fromLTWH(
    plate.center.dx - _quoteWidth / 2,
    plate.bottom + size.height * .03 * f,
    _quoteWidth,
    quoteFill(line, 1).height,
  );

  TextPainter eyebrow(double alpha) => DragonEncounterUi._text(
    'eyebrow',
    _eyebrow,
    size.height * .03 * f,
    spacing: 3,
    alpha: alpha,
  );

  TextPainter subtitle(double alpha) => DragonEncounterUi._text(
    'title',
    _title,
    size.height * .0255 * f,
    spacing: 1.6,
    alpha: alpha,
  );
}
