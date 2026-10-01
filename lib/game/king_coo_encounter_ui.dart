import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart' show FlightSimulation;
import '../domain/sky_boss.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'king_coo_hud_art.dart';
import 'king_coo_kit.dart';
import 'king_coo_letterbox.dart';
import 'king_coo_layout.dart' show KingCooTimeline;

/// King Coo's cinematic set-pieces: the station name card that flips open on
/// his COO!, the shout's rings, the hit, the fury's siren flash, the chest's
/// POP, and the defeat (a pillow of feathers bursting, crumbs from the sack
/// raining, dizzy stars, his whistle tweeting off, then feather snow and the
/// badge floating up into a glow).
///
/// `BossEncounterArt` owns the staging and timing; these are only his
/// brushstrokes, in the manner of [DragonEncounterUi]. Everything derives from
/// the boss and death clocks, so paused, replayed and captured frames repeat
/// exactly, and under Reduced Motion each piece holds still and only fades.
/// Nothing here blurs or opens a layer; gradients are cached and unit-sized,
/// moved into place with the canvas transform, and the animated shapes are
/// rebuilt into scratch paths rather than allocated. A non-finite input
/// draws nothing.
abstract final class KingCooEncounterUi {
  static const _p = KingCooPalette.ink;
  static const _cream = Color(0xfffff2c9);

  /// His line on the card when the caller has none to give (the campaign's own
  /// quote arrives through `line:`, already in quotation marks).
  static const entranceLine = '“Nobody flies till the bread cart is found!”';

  /// The word on the card's ribbon, the same everywhere a guardian is named.
  static const ribbonWord = 'GUARDIAN';

  /// When the card lands: the arrival timeline's card beat, .2 s after the
  /// COO!.
  static const slamAt = KingCooTimeline.cardAt;

  /// The card's letters stamp in from [_stampFrom] s after the slam (3.2 s: the
  /// plate flips open on the COO! at 2.85 s with the name's stencil, and the
  /// letters wait until the shout's word has cleared the plate), one every
  /// [_stampStep] s.
  static const _stampFrom = .35, _stampStep = .05;

  static double _outCubic(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u * u;
  }

  static double _outBack(double t) {
    final u = t.clamp(0.0, 1.0) - 1;
    return 1 + u * u * (2.2 * u + 1.2);
  }

  static double _ramp(double v, double from, double to) =>
      BossMotion.ramp(v, from, to);

  static final Path _a = Path(), _b = Path(), _c = Path();

  // ---------------------------------------------------------- name card --

  /// The arrival name card. It is his own card at every moment of the arrival,
  /// so this always returns true: `BossEncounterArt` calls it instead of the
  /// shared card, which must not appear early, before the COO!.
  ///
  /// Nothing shows until [slamAt] (2.85 s: the COO! has been shouted at 2.65):
  /// then a navy station plate flips open about its middle (a little larger
  /// at first, landing with a siren flash), a **GUARDIAN** ribbon pinned over
  /// its top edge and a siren lamp flashing red and blue on its corner, and
  /// the name stamps in letter by letter, left to right, each landing from a
  /// little above and a little large; the last is down by 3.3 s. The title
  /// follows; the card holds to 4.2 s and folds shut by 4.6 s. [birdY]
  /// (screen heights) lets the plate turn see-through where the bird flies
  /// behind it. Under Reduced Motion the whole card just fades in and out.
  ///
  /// [line] is the campaign's story quote for this boss (it arrives already in
  /// quotation marks), set under the plate on its own soft shade, centred,
  /// cream on an ink edge and slanted: at most two lines, as wide as the
  /// plate, appearing just after the name has landed and leaving with the
  /// card. Without one he says [entranceLine]. The plate itself is exactly the
  /// same either way.
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
    final y0 = g.plate.top, wc = g.plate.width;
    final hc = g.plate.height;

    // How open the card is: it flips open and folds shut about its middle, or,
    // under Reduced Motion, just fades.
    final open = reduced ? 1.0 : _outBack(_ramp(t, 0, .2));
    final fold = reduced ? 0.0 : BossMotion.ease(gone);
    final fade = reduced
        ? (_ramp(t, 0, .25) * (1 - gone)).clamp(0.0, 1.0)
        : 1.0;
    final sy = math.max(0.0, open) * (1 - fold);
    if (sy <= .02 || fade <= 0) return true;

    // See-through where the bird's lane runs behind the card.
    final bird = Offset(FlightSimulation.birdX * h, birdY * h);
    final card = g.plate.inflate(h * .03);
    final gap = Offset(
      math.max(math.max(card.left - bird.dx, bird.dx - card.right), 0.0),
      math.max(math.max(card.top - bird.dy, bird.dy - card.bottom), 0.0),
    ).distance;
    final clear = math.max(0.0, gap - FlightSimulation.birdRadius * h);
    final seen = (.4 + .6 * _ramp(clear, h * .005, h * .05)) * fade;

    // The siren: red and blue in turn, steady under Reduced Motion.
    final siren = reduced
        ? 2
        : (t * KingCooTimeline.sirenHz).floor().isEven
        ? 1
        : 2;
    final lamp = _ramp(t, 0, .1) * (1 - _ramp(boss.age, 4.1, 4.5)) * fade;

    c.save();
    final slam = reduced ? 0.0 : 1 - _outCubic(_ramp(t, 0, .14));
    final pivot = g.plate.center;
    c.translate(pivot.dx - (reduced ? 0 : h * .02 * slam), pivot.dy);
    c.scale(1 + .1 * slam, sy);
    c.translate(-pivot.dx, -pivot.dy);

    // A soft shade round the plate (one radial fade, no edges to see).
    c.save();
    c.translate(pivot.dx + h * .04, pivot.dy + h * .012);
    c.scale(wc / 2 + h * .08, hc / 2 + h * .1);
    c.drawCircle(
      Offset.zero,
      1,
      KingCooHudFx.shaded(
        'cardShade',
        () => KingCooKit.radial(
          Offset.zero,
          1,
          [
            KingCooPalette.navyDeep.withValues(alpha: .5),
            KingCooPalette.navyDeep.withValues(alpha: .42),
            KingCooPalette.navyDeep.withValues(alpha: 0),
          ],
          const [0, .66, 1],
        ),
        seen,
      ),
    );
    c.restore();

    // The plate: ink edge, a navy body, a Sillitoe band on its lower edge, a
    // brass rim and a hairline inside it.
    c.drawRRect(g.body, KingCooHudFx.stroke(_p, k * 3.6, seen));
    c.drawRRect(
      g.body,
      KingCooHudFx.shaded(
        ('cardBody', g.plate),
        () => KingCooKit.linear(
          g.plate.topCenter,
          g.plate.bottomCenter,
          const [
            KingCooPalette.navyLit,
            KingCooPalette.navy,
            KingCooPalette.navyDeep,
          ],
          const [0, .45, 1],
        ),
        .96 * seen,
      ),
    );
    c.drawPath(g.checks, KingCooHudFx.solid(KingCooPalette.blueLit, .8 * seen));
    c.drawRRect(
      g.body,
      KingCooHudFx.shaded(
          ('cardRim', g.plate),
          () => KingCooKit.linear(
            g.plate.topCenter,
            g.plate.bottomCenter,
            const [
              KingCooPalette.brassLit,
              KingCooPalette.brass,
              KingCooPalette.brassDeep,
            ],
            const [0, .4, 1],
          ),
          seen,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 1.7
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawRRect(
      g.inner,
      KingCooHudFx.stroke(KingCooPalette.brass, k * .7, .45 * seen),
    );
    c.drawPath(g.studs, KingCooHudFx.stroke(_p, k * 1.4, seen));
    c.drawPath(g.studs, KingCooHudFx.solid(KingCooPalette.gold, seen));

    // The siren lamp on the plate's top-right edge, lit red or blue, and its
    // light washing over the plate.
    if (lamp > 0) {
      // (Under the letterbox: the light never leaks onto the film bar.)
      c.save();
      c.clipRect(
        Rect.fromLTRB(
          0,
          h * .082 * KingCooStageMotion(boss, reducedMotion: reduced).focus,
          size.width,
          h,
        ),
      );
      KingCooKit.glow(
        c,
        g.lampAt,
        g.lampR * 5.2,
        siren == 1 ? KingCooPalette.sirenRed : KingCooPalette.sirenBlue,
        .46 * lamp * seen,
      );
      c.restore();
    }
    KingCooHudArt.lamp(
      c,
      g.lampAt,
      g.lampR,
      siren: lamp > 0 ? siren : 0,
      glow: lamp * seen,
      u: k,
    );

    // The slam's flash, gone in a tenth of a second.
    if (!reduced && t < .1) {
      c.drawRRect(
        g.body,
        KingCooHudFx.solid(KingCooPalette.white, .5 * (1 - t / .1)),
      );
    }

    final cx = g.plate.center.dx;
    // The ribbon pinned over the top edge: GUARDIAN, a shield on its left end.
    _ribbon(c, g, seen, k);

    // The name: a stencil of it in ink first (the shadow the stamps land on),
    // then each letter stamped in turn.
    final nameTop = y0 + g.hf * .068;
    final nameLeft = cx - g.nameW / 2;
    if (!reduced) {
      g.outline.paint(c, Offset(nameLeft, nameTop + k * 2.4));
    }
    final glyphs = g.glyphs;
    final sparks = _a..reset();
    for (var i = 0; i < glyphs.length; i++) {
      if (glyphs[i].trim().isEmpty) continue;
      final d = reduced ? 1.0 : t - (_stampFrom + i * _stampStep);
      if (d < 0) continue;
      final p = _ramp(d, 0, .16);
      final scale = 1 + .5 * (1 - _outBack(p));
      final drop = -g.nameSize * .42 * (1 - _outCubic(p));
      final centre = Offset(
        nameLeft + g.glyphX[i] + g.glyphW[i] / 2,
        nameTop + g.nameH * .52,
      );
      final lit = reduced ? fade : _ramp(d, 0, .05) * fade;
      c.save();
      c.translate(centre.dx, centre.dy + drop);
      c.scale(scale);
      c.translate(-g.glyphW[i] / 2, -g.nameH * .52);
      g.outlineGlyph(i, lit).paint(c, Offset.zero);
      g.fillGlyph(i, lit).paint(c, Offset.zero);
      c.restore();
      // A twinkle where it lands.
      if (!reduced && d > .1 && d < .38) {
        final tw = 1 - (d - .1) / .28;
        _sparkle(
          sparks,
          Offset(
            nameLeft + g.glyphX[i] + g.glyphW[i] * .86,
            nameTop + g.nameH * .12,
          ),
          g.nameSize * .2 * tw,
          0,
        );
      }
    }
    c.drawPath(sparks, KingCooHudFx.solid(KingCooPalette.brassLit, .95 * seen));

    // The title, revealed after the name has landed, between two hairlines.
    final titleTop = nameTop + g.nameH + g.hf * .008;
    final subReach = reduced ? 1.0 : _ramp(t, .72, .98);
    if (subReach > 0) {
      final sub = g.subtitle(fade);
      final sx = cx - sub.width / 2, sy2 = titleTop + g.hf * .012;
      c.save();
      c.clipRect(
        Rect.fromLTRB(
          cx - wc / 2,
          titleTop - h * .01,
          cx - wc / 2 + wc * subReach,
          titleTop + h * .06,
        ),
      );
      final mid = sy2 + sub.height * .52;
      final line = _a..reset();
      for (final s in [-1.0, 1.0]) {
        final dx = cx + s * (sub.width / 2 + g.hf * .028);
        final r = g.hf * .0095;
        line
          ..moveTo(dx, mid - r)
          ..lineTo(dx + r, mid)
          ..lineTo(dx, mid + r)
          ..lineTo(dx - r, mid)
          ..close();
      }
      c.drawPath(line, KingCooHudFx.solid(KingCooPalette.brass, seen));
      sub.paint(c, Offset(sx, sy2));
      c.restore();
    }
    c.restore();

    // The story quote, under the plate on a shade of its own: its see-through
    // is worked out from its own box, so the plate does not change when there
    // is one.
    final text = (line == null || line.trim().isEmpty)
        ? entranceLine
        : line.trim();
    final box = g.quoteBox(text);
    final qGap = Offset(
      math.max(math.max(box.left - bird.dx, bird.dx - box.right), 0.0),
      math.max(math.max(box.top - bird.dy, bird.dy - box.bottom), 0.0),
    ).distance;
    final qClear = math.max(0.0, qGap - FlightSimulation.birdRadius * h);
    final qSeen =
        (.8 + .2 * _ramp(qClear, h * .005, h * .05)) *
        (reduced ? fade : _ramp(t, .3, .5) * (1 - fold));
    if (qSeen > 0) {
      // Under the plate only: its shade never touches the plate itself.
      c.save();
      c.clipRect(Rect.fromLTRB(0, g.plate.bottom + k * 2.2, size.width, h));
      // A plank of its own under the words (navy, brass hairline): the quote
      // reads over the skyline and over the bird's bubble (K8 fix round).
      final plank = RRect.fromRectAndRadius(
        box.inflate(h * .011),
        Radius.circular(h * .016),
      );
      c.drawRRect(
        plank.inflate(k * .8),
        KingCooHudFx.solid(_p, .55 * qSeen),
      );
      c.drawRRect(
        plank,
        KingCooHudFx.solid(KingCooPalette.navyDeep, .74 * qSeen),
      );
      c.drawRRect(
        plank,
        KingCooHudFx.stroke(KingCooPalette.brass, k * .8, .6 * qSeen),
      );
      c.translate(box.center.dx, box.center.dy + h * .004);
      c.scale(box.width / 2 + h * .05, box.height / 2 + h * .045);
      c.drawCircle(
        Offset.zero,
        1,
        KingCooHudFx.shaded(
          'quoteShade',
          () => KingCooKit.radial(
            Offset.zero,
            1,
            [
              KingCooPalette.navyDeep.withValues(alpha: .72),
              KingCooPalette.navyDeep.withValues(alpha: .6),
              KingCooPalette.navyDeep.withValues(alpha: 0),
            ],
            const [0, .62, 1],
          ),
          qSeen,
        ),
      );
      c.restore();
      final at = Offset(box.left, box.top);
      g.quoteEdge(text, qSeen).paint(c, at);
      g.quoteFill(text, qSeen).paint(c, at);
    }
    return true;
  }

  // The GUARDIAN ribbon: swallow-tailed, in the guardian's gold, lettered in
  // ink, with the badge's shield pinned on its left end (the map's and the
  // level card's language).
  static void _ribbon(Canvas c, _Card g, double seen, double k) {
    c.drawPath(
      g.ribbon.shift(Offset(0, k * 2)),
      KingCooHudFx.solid(_p, .3 * seen),
    );
    c.drawPath(
      g.ribbon,
      KingCooHudFx.shaded(
        ('ribbon', g.ribbonBox),
        () => KingCooKit.linear(
          g.ribbonBox.topCenter,
          g.ribbonBox.bottomCenter,
          [
            Color.lerp(_gold, KingCooPalette.white, .3)!,
            _gold,
            Color.lerp(_gold, _p, .14)!,
          ],
          const [0, .5, 1],
        ),
        seen,
      ),
    );
    c.drawPath(
      g.ribbon,
      KingCooHudFx.stroke(_p, k * 1.7, seen)..strokeJoin = StrokeJoin.round,
    );
    g.ribbonText.paint(c, g.ribbonTextAt);
    KingCooHudArt.crest(
      c,
      g.shieldAt,
      g.shieldR,
      k,
      fury: false,
      defeated: false,
    );
  }

  // The stamp field behind his cap on the map, the ribbon's colour.
  static const _gold = Color(0xffe0a93a);

  // The card's layout only depends on the viewport and the boss's words, so it
  // is measured, laid out and pathed once.
  static _Card? _cardBuilt;

  static _Card _card(Size size, SkyBoss boss) {
    // The plate must stop short of his beak, which juts some two and a half
    // hit-radii left of his chest when the head is thrown back for the COO!.
    final h = size.height;
    final left = math.max(h * .04, size.width * .075);
    final room = boss.x.isFinite
        ? boss.x * h - 2.62 * h * SkyBoss.radius - h * .016 - left
        : 1e6;
    final built = _cardBuilt;
    final name = boss.name.toUpperCase();
    if (built != null &&
        built.size == size &&
        built.room == room.round() &&
        built.word == name &&
        built.title == boss.title) {
      return built;
    }
    return _cardBuilt = _Card(size, room, name, boss.title);
  }

  // Laid-out text, kept between frames and bounded.
  static final Map<Object, TextPainter> _texts = {};

  static TextPainter _text(
    Object key,
    String value,
    double size, {
    Color color = KingCooPalette.gold,
    double spacing = 0,
    double? stroke,
    double alpha = 1,
    bool italic = false,
    double? width,
    int maxLines = 1,
    bool body = false,
    FontWeight? weight,
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
      body,
      weight,
    );
    var p = _texts[id];
    if (p == null) {
      if (_texts.length >= 96) _texts.clear();
      final base = body
          ? bodyText(
              size,
              color: color.withValues(alpha: bucket / 8),
              weight: weight ?? FontWeight.w900,
            )
          : heading(
              size,
              color: color.withValues(alpha: bucket / 8),
              weight: weight ?? FontWeight.w600,
            );
      var style = italic ? base.copyWith(fontStyle: FontStyle.italic) : base;
      style = stroke == null
          ? style.copyWith(letterSpacing: spacing)
          : style.copyWith(
              letterSpacing: spacing,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = stroke
                ..strokeJoin = StrokeJoin.round
                ..color = _p.withValues(alpha: bucket / 8),
            );
      p = _texts[id] = TextPainter(
        text: TextSpan(text: value, style: style),
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

  /// A four-pointed sparkle of [r] added to [into] (a slim diamond cross).
  static void _sparkle(Path into, Offset at, double r, double turn) {
    if (r <= 0) return;
    final cs = math.cos(turn), sn = math.sin(turn);
    Offset p(double x, double y) =>
        Offset(at.dx + (x * cs - y * sn) * r, at.dy + (x * sn + y * cs) * r);
    final pts = [
      p(0, -1),
      p(.2, -.2),
      p(1, 0),
      p(.2, .2),
      p(0, 1),
      p(-.2, .2),
      p(-1, 0),
      p(-.2, -.2),
    ];
    into.moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      into.lineTo(pts[i].dx, pts[i].dy);
    }
    into.close();
  }

  // ------------------------------------------------------- feather kit --

  // A feather about the origin, 2 long (x -1 to 1) and a little under 1 wide:
  // a leaf with a notch, its quill on the axis.
  static final Path _feather = Path()
    ..moveTo(-1, 0)
    ..quadraticBezierTo(-.35, -.62, .35, -.5)
    ..quadraticBezierTo(.85, -.36, 1, 0)
    ..quadraticBezierTo(.5, .1, 1, 0)
    ..quadraticBezierTo(.6, .46, -.3, .46)
    ..quadraticBezierTo(-.8, .3, -1, 0)
    ..close();
  static final Path _quill = Path()
    ..moveTo(-1, 0)
    ..lineTo(.8, -.02);
  static final Float64List _m = Float64List(16);

  /// Adds [shape] to [into], scaled by [sx] x [sy], turned by [angle] and moved
  /// to [at].
  static void _put(
    Path into,
    Path shape,
    Offset at,
    double sx,
    double sy,
    double angle,
  ) {
    final cs = math.cos(angle), sn = math.sin(angle);
    _m
      ..[0] = cs * sx
      ..[1] = sn * sx
      ..[2] = 0
      ..[3] = 0
      ..[4] = -sn * sy
      ..[5] = cs * sy
      ..[6] = 0
      ..[7] = 0
      ..[8] = 0
      ..[9] = 0
      ..[10] = 1
      ..[11] = 0
      ..[12] = at.dx
      ..[13] = at.dy
      ..[14] = 0
      ..[15] = 1;
    into.addPath(shape, Offset.zero, matrix4: _m);
  }

  // Crumbs: an uneven chip of bread.
  static final Path _crumb = Path()
    ..moveTo(-1, -.2)
    ..lineTo(-.2, -.8)
    ..lineTo(.9, -.4)
    ..lineTo(.7, .5)
    ..lineTo(-.4, .8)
    ..close();

  // A five-pointed star about the origin, radius 1.
  static final Path _star5 = () {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? 1.0 : .46;
      final o = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }();

  /// Feathers flung from [at]: [n] of them on arcs, tumbling, plumage and
  /// breast, an ink edge round each. [k] is seconds since they left; they
  /// speed off at up to [speed] screen heights a second, fall under
  /// [gravity] and go by [life].
  static void _feathers(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required int n,
    required double speed,
    required double size,
    required double life,
    required int salt,
    double gravity = .5,
    double spin = 7,
    double aim = 0,
    double spread = math.pi * 2,
    double start = 0,
    bool reduced = false,
    double alpha = 1,
  }) {
    if (k <= 0 || k >= life || alpha <= 0) return;
    final lilac = _a..reset(), cream = _b..reset(), quills = _c..reset();
    for (var i = 0; i < n; i++) {
      final a =
          aim +
          (i / n - .5) * spread +
          (KingCooHudFx.hash(i, salt) - .5) * (spread / n) * .9;
      final v = h * speed * (.55 + KingCooHudFx.hash(i, salt + 3) * .6);
      final drag = reduced ? k : (1 - math.exp(-k * 3.0)) / 3.0;
      final fall = reduced ? 0.0 : h * gravity * k * k;
      final p =
          at +
          Offset(math.cos(a) * 1.15, math.sin(a)) * (v * drag + h * start) +
          Offset(0, fall);
      final turn =
          a +
          (reduced ? 0 : k * spin * (KingCooHudFx.hash(i, salt + 5) - .5) * 2);
      final s = h * size * (.75 + KingCooHudFx.hash(i, salt + 7) * .5);
      final flat = reduced ? 1.0 : .55 + .45 * math.cos(k * 6 + i);
      _put(i.isEven ? lilac : cream, _feather, p, s, s * .6 * flat, turn);
      _put(quills, _quill, p, s, s * .6 * flat, turn);
    }
    final fade = (1 - _ramp(k, life * .55, life)) * _ramp(k, 0, .06) * alpha;
    c.drawPath(lilac, KingCooHudFx.stroke(_p, h * .0055, fade));
    c.drawPath(cream, KingCooHudFx.stroke(_p, h * .0055, fade));
    c.drawPath(lilac, KingCooHudFx.solid(KingCooPalette.feather, fade));
    c.drawPath(cream, KingCooHudFx.solid(KingCooPalette.breastLit, fade));
    c.drawPath(
      quills,
      KingCooHudFx.stroke(KingCooPalette.featherDeep, h * .0028, fade * .8),
    );
  }

  /// Crumbs from the sack: [n] chips of bread flung from [at], tumbling and
  /// falling.
  static void _crumbs(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required int n,
    required double speed,
    required double life,
    required int salt,
    double aim = -math.pi / 2,
    double spread = math.pi * 1.6,
    bool reduced = false,
    double alpha = 1,
  }) {
    if (k <= 0 || k >= life || alpha <= 0) return;
    final crust = _a..reset(), soft = _b..reset();
    for (var i = 0; i < n; i++) {
      final a =
          aim + (KingCooHudFx.hash(i, salt) - .5) * spread + (reduced ? 0 : 0);
      final v = h * speed * (.35 + KingCooHudFx.hash(i, salt + 2) * .75);
      final drag = reduced ? k : (1 - math.exp(-k * 2.4)) / 2.4;
      final p =
          at +
          Offset(math.cos(a) * 1.2, math.sin(a)) * v * drag +
          Offset(0, reduced ? 0 : h * .75 * k * k);
      final s = h * (.009 + KingCooHudFx.hash(i, salt + 4) * .007);
      final turn = reduced
          ? a
          : a + k * (4 + KingCooHudFx.hash(i, salt + 6) * 6);
      _put(crust, _crumb, p, s * 1.28, s * 1.28, turn);
      _put(soft, _crumb, p, s, s, turn);
    }
    final fade = (1 - _ramp(k, life * .5, life)) * alpha;
    c.drawPath(crust, KingCooHudFx.solid(KingCooPalette.crust, fade));
    c.drawPath(soft, KingCooHudFx.solid(KingCooPalette.crumbHi, fade));
  }

  /// Down: [n] small round tufts flung from [at] with a lilac shade under each,
  /// slowing as they go, gone by [life].
  static void _down(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required int n,
    required double speed,
    required double life,
    required int salt,
    bool reduced = false,
    double alpha = 1,
  }) {
    if (k <= 0 || k >= life || alpha <= 0) return;
    final shade = _a..reset(), tuft = _b..reset();
    for (var i = 0; i < n; i++) {
      final a = KingCooHudFx.hash(i, salt) * math.pi * 2;
      final v = h * speed * (.3 + KingCooHudFx.hash(i, salt + 2) * .8);
      final drag = reduced ? k : (1 - math.exp(-k * 3.4)) / 3.4;
      final p =
          at +
          Offset(math.cos(a) * 1.2, math.sin(a)) * v * drag +
          Offset(0, reduced ? 0 : h * .12 * k * k);
      final r = h * (.005 + KingCooHudFx.hash(i, salt + 4) * .007);
      shade.addOval(
        Rect.fromCircle(center: p + Offset(r * .15, r * .25), radius: r * 1.08),
      );
      tuft.addOval(Rect.fromCircle(center: p, radius: r));
    }
    final fade = (1 - _ramp(k, life * .55, life)) * alpha;
    c.drawPath(shade, KingCooHudFx.solid(const Color(0xffa9a2d8), fade));
    c.drawPath(tuft, KingCooHudFx.solid(const Color(0xfffbf6ff), fade));
  }

  /// Siren sparkle: [n] four-pointed twinkles, red and blue in turn, with a
  /// white heart, flung out from [at] to about [reach] and gone by [life].
  static void _sparkles(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required int n,
    required double reach,
    required double life,
    required int salt,
    double size = .03,
    bool reduced = false,
    double alpha = 1,
  }) {
    if (k <= 0 || k >= life || alpha <= 0) return;
    final red = _a..reset(), blue = _b..reset(), white = _c..reset();
    for (var i = 0; i < n; i++) {
      final a = i * 2.399963 + KingCooHudFx.hash(i, salt) * .8;
      final d =
          reach *
          (.35 + .65 * _outCubic(_ramp(k, 0, life * .6))) *
          (.6 + KingCooHudFx.hash(i, salt + 2) * .5);
      final p = at + Offset(math.cos(a) * 1.15, math.sin(a)) * d;
      final blink = reduced ? 1.0 : .55 + .45 * math.sin(k * 22 + i * 1.9);
      final r = h * size * (.6 + KingCooHudFx.hash(i, salt + 4) * .6) * blink;
      _sparkle(i.isEven ? red : blue, p, r, reduced ? 0 : k * 3 + i);
      _sparkle(white, p, r * .45, reduced ? 0 : k * 3 + i);
    }
    final fade = (1 - _ramp(k, life * .6, life)) * alpha;
    c.drawPath(red, KingCooHudFx.solid(KingCooPalette.sirenRed, fade));
    c.drawPath(blue, KingCooHudFx.solid(KingCooPalette.sirenBlue, fade));
    c.drawPath(white, KingCooHudFx.solid(KingCooPalette.white, fade));
  }

  /// Dizzy stars: [n] gold stars that circle [at] on a wobbling ring and then
  /// fly off, an ink edge round each.
  static void _stars(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required int n,
    required double ring,
    required double life,
    bool reduced = false,
    double alpha = 1,
  }) {
    if (k <= 0 || k >= life || alpha <= 0) return;
    final stars = _a..reset();
    final out = _outCubic(_ramp(k, life * .35, life));
    for (var i = 0; i < n; i++) {
      final a = i * math.pi * 2 / n + (reduced ? .4 : k * 7);
      final reach = ring * (1 + 2.4 * out);
      final p =
          at +
          Offset(
            math.cos(a) * reach,
            math.sin(a) * reach * .55 - h * .02 * out,
          );
      final s = h * .016 * (1 - out * .4);
      _put(stars, _star5, p, s, s, reduced ? 0 : a + k * 5);
    }
    final fade = (1 - _ramp(k, life * .6, life)) * alpha;
    c.drawPath(stars, KingCooHudFx.stroke(_p, h * .0055, fade));
    c.drawPath(stars, KingCooHudFx.solid(KingCooPalette.gold, fade));
  }

  // ---------------------------------------------------------------- shout --

  /// His COO!: a ring or two out of the beak, the sound arcs fanning left of
  /// it, and the word itself popping beside it. [shock] (0 to 1 over the .5 s
  /// from 2.65 s) is the pose's own ring clock and [roar] (a pulse over .8 s)
  /// the swell; [mouth] is the beak's screen point (`KingCooBossRig.mouthAt`
  /// through the figure). Under Reduced Motion the arcs and word hold still
  /// and fade with [roar]; the rings do not expand.
  static void shout(
    Canvas c,
    Offset mouth,
    double h, {
    required double shock,
    required double roar,
    required bool reduced,
    Offset? chest,
  }) {
    if (!mouth.isFinite || !h.isFinite || !shock.isFinite || !roar.isFinite) {
      return;
    }
    if (roar <= 0 && shock <= 0) return;
    final k = reduced ? .4 : shock.clamp(0.0, 1.0);
    final show = reduced ? roar.clamp(0.0, 1.0) : 1.0;
    // Two rings: cream, then brass, expanding from the beak.
    for (var i = 0; i < 2; i++) {
      final u = reduced ? .5 : _ramp(k, i * .14, 1);
      if (u <= 0 || u >= 1) continue;
      final fade = (1 - u) * (1 - u) * show;
      c.drawCircle(
        mouth,
        h * (.05 + .46 * _outCubic(u)) * (1 - i * .18),
        KingCooHudFx.stroke(
          _p,
          h * (.014 - i * .004) * (1 - u * .6),
          fade * .5,
        ),
      );
      c.drawCircle(
        mouth,
        h * (.05 + .46 * _outCubic(u)) * (1 - i * .18),
        KingCooHudFx.stroke(
          i == 0 ? KingCooPalette.cream : KingCooPalette.brass,
          h * (.008 - i * .002) * (1 - u * .6),
          fade,
        ),
      );
    }
    // Feathers shaken off the chest as it swells (his chest, if given).
    if (chest != null && chest.isFinite && !reduced) {
      _feathers(
        c,
        chest,
        h,
        shock.clamp(0.0, 1.0) * .8,
        n: 8,
        speed: .42,
        size: .03,
        life: .8,
        salt: 281,
        gravity: .3,
        aim: -math.pi / 2,
        spread: math.pi * 1.7,
        start: .1,
      );
    }
    // Sound arcs fanning left of the beak.
    final arcs = _a..reset();
    final grow = reduced ? .6 : .55 + .45 * _outCubic(_ramp(k, 0, .5));
    for (var i = 0; i < 3; i++) {
      final r = h * (.075 + i * .05) * grow;
      final span = .5 - i * .06;
      arcs.addArc(
        Rect.fromCircle(center: mouth, radius: r),
        math.pi - span,
        span * 2,
      );
    }
    final aa = roar.clamp(0.0, 1.0) * (reduced ? 1.0 : 1 - _ramp(k, .6, 1));
    c.drawPath(arcs, KingCooHudFx.stroke(_p, h * .013, aa * .6));
    c.drawPath(arcs, KingCooHudFx.stroke(KingCooPalette.cream, h * .0075, aa));
    // The word, popping.
    final pop = reduced ? 1.0 : 1 + .45 * (1 - _outBack(_ramp(k, 0, .3)));
    final wordAlpha = roar.clamp(0.0, 1.0);
    if (wordAlpha > 0) {
      final fill = _text(
        'coo',
        'COO!',
        h * .085,
        color: KingCooPalette.gold,
        alpha: wordAlpha,
        spacing: h * .002,
        weight: FontWeight.w700,
      );
      final edge = _text(
        'cooEdge',
        'COO!',
        h * .085,
        stroke: h * .017,
        alpha: wordAlpha,
        spacing: h * .002,
        weight: FontWeight.w700,
      );
      c.save();
      c.translate(mouth.dx - h * .2, mouth.dy - h * .09);
      c.rotate(-.12);
      c.scale(pop);
      final corner = Offset(-fill.width / 2, -fill.height / 2);
      edge.paint(c, corner);
      fill.paint(c, corner);
      c.restore();
    }
  }

  // ------------------------------------------------------------------ hit --

  /// A hit on his chest: a spiked flash of cream and gold with a ring, a puff
  /// of feathers and a few crumbs from the sack. A hit on the taut chest
  /// ([puffed]: rocks count double) flares gold with a bigger star, a second
  /// ring, more feathers and a "x2" that pops so the reward reads. [t] is 0 to
  /// 1 over the .36 s after the hit. Under Reduced Motion the star holds still
  /// and fades.
  static void hit(
    Canvas c,
    Offset at,
    double h,
    double t, {
    required bool reduced,
    bool puffed = false,
  }) {
    if (!t.isFinite || !at.isFinite || !h.isFinite || t >= 1 || t < 0) return;
    final base = h * (puffed ? .1 : .06);
    final size =
        base *
        (reduced
            ? .85
            : (.6 + .4 * _outCubic(_ramp(t, 0, .22))) * (1 - t * .3));
    final fade = reduced ? 1 - t : 1 - t * t;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(size * 1.7);
    c.drawCircle(
      Offset.zero,
      1,
      KingCooHudFx.shaded(
        puffed ? 'hitFlashGold' : 'hitFlash',
        () => KingCooKit.radial(
          Offset.zero,
          1,
          [
            KingCooPalette.white.withValues(alpha: .95),
            (puffed ? KingCooPalette.gold : KingCooPalette.crumbHi).withValues(
              alpha: .5,
            ),
            KingCooPalette.gold.withValues(alpha: 0),
          ],
          const [0, .3, 1],
        ),
        fade * (puffed ? 1 : .8),
      ),
    );
    c.restore();
    final star = _a..reset();
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7 + .2;
      final long = i % 7 == 0 ? 1.35 : 1.0;
      final r = size * (i.isEven ? long : .42);
      final p = at + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c.drawPath(star, KingCooHudFx.stroke(_p, h * .008, fade));
    c.drawPath(
      star,
      KingCooHudFx.solid(
        puffed ? KingCooPalette.gold : KingCooPalette.cream,
        fade,
      ),
    );
    c.drawCircle(at, size * .3, KingCooHudFx.solid(KingCooPalette.white, fade));
    if (!reduced) {
      final ring = _outCubic(_ramp(t, 0, .6));
      c.drawCircle(
        at,
        size * (.9 + ring * (puffed ? 2.4 : 1.6)),
        KingCooHudFx.stroke(
          puffed ? KingCooPalette.brass : KingCooPalette.cream,
          h * .005 * (1 - t),
          (1 - t) * (1 - t) * .9,
        ),
      );
      _feathers(
        c,
        at,
        h,
        t * .6,
        n: puffed ? 7 : 5,
        speed: puffed ? .55 : .42,
        size: puffed ? .03 : .024,
        life: .6,
        salt: 211,
        gravity: .5,
        aim: -math.pi / 2,
        spread: math.pi * 1.5,
        start: puffed ? .07 : .05,
      );
      _crumbs(
        c,
        at,
        h,
        t * .6,
        n: puffed ? 7 : 4,
        speed: .5,
        life: .6,
        salt: 223,
        aim: -math.pi / 2,
        spread: math.pi * 1.6,
      );
    }
    if (puffed) {
      final pop = reduced ? 1.0 : 1 + .4 * (1 - _outCubic(_ramp(t, 0, .2)));
      final lift = reduced ? 0.0 : _outCubic(t) * h * .06;
      final fill = _text(
        'x2',
        '×2',
        h * .07,
        color: KingCooPalette.gold,
        alpha: fade,
        weight: FontWeight.w700,
      );
      final edge = _text(
        'x2Edge',
        '×2',
        h * .07,
        stroke: h * .012,
        alpha: fade,
        weight: FontWeight.w700,
      );
      c.save();
      c.translate(at.dx, at.dy - h * .1 - lift);
      c.scale(pop);
      final corner = Offset(-fill.width / 2, -fill.height / 2);
      edge.paint(c, corner);
      fill.paint(c, corner);
      c.restore();
    }
  }

  // ----------------------------------------------------------------- fury --

  /// The fury's onset, [t] 0 to 1 over the 1.1 s after he crosses half health
  /// (`BossMotion.rage`'s window): the siren goes off round his chest, a red
  /// and a blue ring rolling out of it, rays of red and blue light, a puff of
  /// feathers shaken loose by the stomp, and sparkles. Under Reduced Motion it
  /// holds one frame and fades.
  static void furyBurst(
    Canvas c,
    Offset at,
    double h,
    double t, {
    required bool reduced,
  }) {
    if (!t.isFinite || !at.isFinite || !h.isFinite || t >= 1 || t < 0) return;
    final k = reduced ? .35 : t;
    final fade = reduced ? (1 - t) * _ramp(t, 0, .15) : 1 - _ramp(t, .5, 1);
    if (fade <= 0) return;
    // A red haze under it all.
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(h * (.3 + .2 * _outCubic(_ramp(k, 0, .5))));
    c.drawCircle(
      Offset.zero,
      1,
      KingCooHudFx.shaded(
        'furyHaze',
        () => KingCooKit.radial(
          Offset.zero,
          1,
          [
            KingCooPalette.sirenRed.withValues(alpha: .45),
            KingCooPalette.sirenRed.withValues(alpha: .2),
            KingCooPalette.sirenRed.withValues(alpha: 0),
          ],
          const [0, .55, 1],
        ),
        fade,
      ),
    );
    c.restore();
    // Rays of siren light, red and blue, turning.
    final red = _a..reset(), blue = _b..reset();
    final reach = h * .5 * _outCubic(_ramp(k, 0, .4)) * (1 - _ramp(k, .45, 1));
    if (reach > 0) {
      final turn = reduced ? .2 : k * .9;
      for (var i = 0; i < 12; i++) {
        final a = turn + i * math.pi / 6;
        final r = reach * (i % 2 == 0 ? 1 : .62);
        final w = i % 2 == 0 ? h * .06 : h * .04;
        final l = Offset(math.cos(a - .1), math.sin(a - .1)) * w;
        final rr = Offset(math.cos(a + .1), math.sin(a + .1)) * w;
        (i % 4 < 2 ? red : blue)
          ..moveTo(at.dx + l.dx, at.dy + l.dy)
          ..lineTo(at.dx + math.cos(a) * r, at.dy + math.sin(a) * r)
          ..lineTo(at.dx + rr.dx, at.dy + rr.dy)
          ..close();
      }
      c.drawPath(red, KingCooHudFx.solid(KingCooPalette.sirenRed, .8 * fade));
      c.drawPath(blue, KingCooHudFx.solid(KingCooPalette.sirenBlue, .8 * fade));
    }
    if (!reduced) {
      for (var i = 0; i < 2; i++) {
        final u = _ramp(t, i * .1, .75);
        if (u <= 0 || u >= 1) continue;
        c.drawCircle(
          at,
          h * (.06 + .5 * _outCubic(u)),
          KingCooHudFx.stroke(
            i == 0 ? KingCooPalette.sirenRed : KingCooPalette.sirenBlue,
            h * .012 * (1 - u * .7),
            (1 - u) * .9,
          ),
        );
      }
      _feathers(
        c,
        at,
        h,
        t * 1.1,
        n: 9,
        speed: .5,
        size: .028,
        life: 1.1,
        salt: 241,
        gravity: .35,
        start: .06,
      );
    }
    _sparkles(
      c,
      at,
      h,
      reduced ? .3 : t * 1.1,
      n: 7,
      reach: h * .3,
      life: 1.1,
      salt: 251,
      reduced: reduced,
      alpha: reduced ? fade : 1,
    );
  }

  // ------------------------------------------------------------------ pop --

  /// The chest's POP in mid-fight (three puffed hits): a comic starburst with
  /// the word, feathers fanning off the burst chest, crumbs from the sack and
  /// dizzy stars. [t] is 0 to 1 over the .8 s after `SkyBoss.poppedAt`. Under
  /// Reduced Motion it holds one frame and fades.
  static void pop(
    Canvas c,
    Offset at,
    double h,
    double t, {
    required bool reduced,
  }) {
    if (!t.isFinite || !at.isFinite || !h.isFinite || t >= 1 || t < 0) return;
    final k = reduced ? .3 : t * .8;
    final fade = reduced ? (1 - t) * _ramp(t, 0, .12) : 1 - _ramp(t, .6, 1);
    if (fade <= 0) return;
    // The starburst: spikes in cream under spikes in gold, an ink edge.
    final grow = reduced
        ? .8
        : (.35 + .65 * _outBack(_ramp(k, 0, .16))) *
              (1 - _ramp(k, .3, .8) * .25);
    final spikes = _a..reset();
    final inner = _b..reset();
    const n = 14;
    for (var i = 0; i < n * 2; i++) {
      final a = i * math.pi / n + .1;
      final r = h * .12 * grow * (i.isEven ? (i % 4 == 0 ? 1.0 : .78) : .42);
      final p = at + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? spikes.moveTo(p.dx, p.dy) : spikes.lineTo(p.dx, p.dy);
      final q = at + Offset(math.cos(a), math.sin(a)) * r * .62;
      i == 0 ? inner.moveTo(q.dx, q.dy) : inner.lineTo(q.dx, q.dy);
    }
    spikes.close();
    inner.close();
    c.drawPath(spikes, KingCooHudFx.stroke(_p, h * .009, fade));
    c.drawPath(spikes, KingCooHudFx.solid(KingCooPalette.gold, fade));
    c.drawPath(inner, KingCooHudFx.solid(KingCooPalette.cream, fade));
    final word = _text(
      'pop',
      'POP!',
      h * .062,
      color: KingCooPalette.sirenRed,
      alpha: fade,
      weight: FontWeight.w700,
    );
    final edge = _text(
      'popEdge',
      'POP!',
      h * .062,
      stroke: h * .012,
      alpha: fade,
      weight: FontWeight.w700,
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(-.1);
    c.scale(reduced ? 1.0 : 1 + .3 * (1 - _outBack(_ramp(k, 0, .2))));
    final corner = Offset(-word.width / 2, -word.height / 2);
    edge.paint(c, corner);
    word.paint(c, corner);
    c.restore();
    if (!reduced) {
      _feathers(
        c,
        at,
        h,
        k,
        n: 12,
        speed: .75,
        size: .032,
        life: .8,
        salt: 263,
        gravity: .45,
        start: .07,
      );
      _crumbs(c, at, h, k, n: 9, speed: .6, life: .8, salt: 271);
    }
    _stars(
      c,
      at + Offset(0, -h * .1),
      h,
      reduced ? .2 : k,
      n: 4,
      ring: h * .05,
      life: .8,
      reduced: reduced,
      alpha: reduced ? fade : 1,
    );
  }

  // --------------------------------------------------------------- defeat --

  // The pillow of down that the chest bursts into: nine lobes about the
  // burst, three layers (shade, body, light) so it reads as a cloud, not a
  // disc.
  static void _poof(Canvas c, Offset at, double h, double k, double fade) {
    final born = _ramp(k, 0, .32);
    if (born <= 0 || fade <= 0) return;
    final shade = _a..reset(), body = _b..reset(), light = _c..reset();
    final grow = .5 + .5 * _outCubic(born);
    for (var i = 0; i < 9; i++) {
      final a = i * 2.399963 + .7;
      final reach = h * (.04 + KingCooHudFx.hash(i, 301) * .08) * grow;
      final r = h * (.06 + KingCooHudFx.hash(i, 303) * .04) * grow;
      final p = at + Offset(math.cos(a) * 1.2, math.sin(a) * .8) * reach;
      shade.addOval(
        Rect.fromCircle(center: p + Offset(r * .1, r * .16), radius: r * 1.06),
      );
      body.addOval(Rect.fromCircle(center: p, radius: r));
      light.addOval(
        Rect.fromCircle(center: p + Offset(-r * .28, -r * .32), radius: r * .5),
      );
    }
    shade.addOval(
      Rect.fromCircle(
        center: at + Offset(h * .005, h * .01),
        radius: h * .075 * grow,
      ),
    );
    body.addOval(Rect.fromCircle(center: at, radius: h * .07 * grow));
    c.drawPath(shade, KingCooHudFx.solid(const Color(0xffa9a2d8), .95 * fade));
    c.drawPath(body, KingCooHudFx.solid(const Color(0xfff8f2ff), .96 * fade));
    c.drawPath(light, KingCooHudFx.solid(KingCooPalette.white, .8 * fade));
  }

  /// The burst: the chest goes off all at once like a pillow. [t] is 0 to 1
  /// over the 1.3 s after `SkyBoss.burstAt`. A comic starburst flashes, a
  /// cloud of down swells, feathers (his plumage and his rosy breast) and
  /// crumbs from the sack are flung out on arcs, dizzy stars circle and
  /// scatter, siren sparkles twinkle red and blue, and his whistle spins off
  /// still tweeting. The snow that follows is [featherSnow], the badge
  /// [victoryBadge]. Under Reduced Motion it holds one scattered frame and
  /// fades in place.
  static void burst(Canvas c, Offset at, double h, double t, bool reduced) {
    if (!t.isFinite || !at.isFinite || !h.isFinite || t >= 1 || t < 0) return;
    final k = reduced ? .3 : t * 1.3;
    final fade = reduced ? (1 - t) * _ramp(t, 0, .15) : 1.0;

    // A warm afterglow over the place he was.
    _disc(
      c,
      at,
      h * .5 * (.6 + .4 * _outCubic(_ramp(k, 0, .5))),
      'burstHaze',
      const [Color(0x00ffd878), Color(0x55ffe9b0), Color(0x00ffd878)],
      const [0, .5, 1],
      (1 - _ramp(k, .45, 1.2)) * fade,
    );

    // The comic starburst, gone in a fifth of a second.
    final kn = k;
    final flash = reduced ? 0.0 : (1 - _ramp(kn, .06, .26));
    if (flash > 0) {
      final spikes = _a..reset();
      final reach = h * .42 * _outCubic(_ramp(kn, 0, .12));
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8 + .15;
        final r =
            reach *
            (i % 4 == 0
                ? 1.0
                : i.isEven
                ? .66
                : .34);
        final w = i % 4 == 0 ? h * .075 : h * .045;
        final l = Offset(math.cos(a - .14), math.sin(a - .14)) * w;
        final rr = Offset(math.cos(a + .14), math.sin(a + .14)) * w;
        spikes
          ..moveTo(at.dx + l.dx, at.dy + l.dy)
          ..lineTo(at.dx + math.cos(a) * r, at.dy + math.sin(a) * r)
          ..lineTo(at.dx + rr.dx, at.dy + rr.dy)
          ..close();
      }
      c.drawPath(spikes, KingCooHudFx.solid(KingCooPalette.white, .95 * flash));
      c.drawPath(
        spikes,
        KingCooHudFx.stroke(KingCooPalette.gold, h * .004, .8 * flash),
      );
    }

    // The word, as comics have it: POOF! pops over the burst and is gone by
    // half a second.
    if (!reduced && k > .03 && k < .6) {
      final life = 1 - _ramp(k, .36, .6);
      final fill = _text(
        'poof',
        'POOF!',
        h * .07,
        color: KingCooPalette.cream,
        alpha: life,
        weight: FontWeight.w700,
      );
      final edge = _text(
        'poofEdge',
        'POOF!',
        h * .07,
        stroke: h * .014,
        alpha: life,
        weight: FontWeight.w700,
      );
      c.save();
      c.translate(at.dx + h * .1, at.dy - h * .21 - h * .03 * _outCubic(_ramp(k, .03, .5)));
      c.rotate(-.1);
      c.scale(1 + .6 * (1 - _outBack(_ramp(k, .03, .2))));
      final corner = Offset(-fill.width / 2, -fill.height / 2);
      edge.paint(c, corner);
      fill.paint(c, corner);
      c.restore();
    }

    // The pillow of down.
    _poof(
      c,
      at,
      h,
      reduced ? .4 : k,
      (reduced ? 1.0 : 1 - _ramp(k, .5, 1.1)) * fade,
    );

    // Down, feathers and crumbs.
    _down(
      c,
      at,
      h,
      k,
      n: 34,
      speed: 1.0,
      life: 1.2,
      salt: 317,
      reduced: reduced,
      alpha: reduced ? fade : 1,
    );
    _feathers(
      c,
      at,
      h,
      k,
      n: 26,
      speed: .95,
      size: .046,
      life: 1.3,
      salt: 311,
      gravity: .5,
      spin: 5,
      reduced: reduced,
      alpha: reduced ? fade : 1,
    );
    _crumbs(
      c,
      at + Offset(h * .09, h * .05),
      h,
      k,
      n: 30,
      speed: .8,
      life: 1.3,
      salt: 331,
      aim: -math.pi / 2.6,
      spread: math.pi * 1.7,
      reduced: reduced,
      alpha: reduced ? fade : 1,
    );
    _sparkles(
      c,
      at,
      h,
      k,
      n: 8,
      reach: h * .36,
      life: 1.0,
      salt: 341,
      reduced: reduced,
      alpha: reduced ? fade : 1,
    );
    _stars(
      c,
      at + Offset(0, -h * .04),
      h,
      k,
      n: 5,
      ring: h * .07,
      life: 1.2,
      reduced: reduced,
      alpha: reduced ? fade : 1,
    );
    _whistleOff(c, at, h, k, reduced, reduced ? fade : 1);
  }

  // His silver whistle, knocked out by the burst: it arcs up and left spinning,
  // three tweet marks beside it, and drops away.
  static void _whistleOff(
    Canvas c,
    Offset at,
    double h,
    double k,
    bool reduced,
    double alpha,
  ) {
    if (k <= .04 || k >= 1.25 || alpha <= 0) return;
    final u = k - .04;
    final out = _outCubic(_ramp(u, 0, .5));
    final p =
        at +
        Offset(
          -h * .3 * out,
          -h * .34 * out +
              h * 1.0 * math.max(0.0, u - .45) * math.max(0.0, u - .45),
        );
    final turn = reduced ? -.5 : -u * 9;
    final fade = (1 - _ramp(k, .85, 1.25)) * alpha;
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(turn);
    c.scale(h * .03);
    c.drawPath(KingCooHudArt.whistleShape, KingCooHudFx.stroke(_p, .46, fade));
    c.drawPath(KingCooHudArt.whistleRing, KingCooHudFx.stroke(_p, .42, fade));
    c.drawPath(
      KingCooHudArt.whistleShape,
      KingCooHudFx.solid(KingCooPalette.steel, fade),
    );
    c.drawPath(
      KingCooHudArt.whistleRing,
      KingCooHudFx.stroke(KingCooPalette.steelLit, .17, fade),
    );
    c.restore();
    // Tweet marks: three short arcs that stay where he was when it left.
    if (!reduced && u < .7) {
      final marks = _a..reset();
      final q = at + Offset(-h * .3 * out, -h * .34 * out);
      for (var i = 0; i < 3; i++) {
        final a = -2.5 + i * .6;
        marks
          ..moveTo(q.dx + math.cos(a) * h * .045, q.dy + math.sin(a) * h * .045)
          ..lineTo(
            q.dx + math.cos(a) * h * .075,
            q.dy + math.sin(a) * h * .075,
          );
      }
      c.drawPath(
        marks,
        KingCooHudFx.stroke(
          KingCooPalette.cream,
          h * .006,
          fade * (1 - u / .7),
        ),
      );
    }
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
      KingCooHudFx.shaded(
        id,
        () => KingCooKit.radial(Offset.zero, 1, colors, stops),
        alpha,
      ),
    );
    c.restore();
  }

  /// The feathers that linger after the burst: they drift down and sway, plumage
  /// and breast, going one by one. The burst draws the first of them; a caller
  /// that keeps calling with [k] seconds since the burst, past the burst's
  /// own 1.3 s, carries the snow to its end at 2.6 s. Under Reduced Motion
  /// there is none.
  static void featherSnow(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required bool reduced,
  }) {
    if (reduced || !k.isFinite || !at.isFinite || !h.isFinite || k <= 1.3) {
      return;
    }
    if (k >= 2.7) return;
    final lilac = _a..reset(), cream = _b..reset();
    for (var i = 0; i < 24; i++) {
      final born = .3 + KingCooHudFx.hash(i, 351) * 1.3;
      final life = (k - born) / 1.2;
      if (life <= 0 || life >= 1) continue;
      final x =
          at.dx +
          (KingCooHudFx.hash(i, 353) - .5) * h * .95 +
          math.sin(k * 2.4 + i) * h * .02;
      final y =
          at.dy -
          h * (.02 + KingCooHudFx.hash(i, 355) * .24) +
          life * h * (.14 + KingCooHudFx.hash(i, 357) * .14);
      final s = h * (.02 + KingCooHudFx.hash(i, 359) * .01);
      final turn = math.sin(k * 2 + i * 1.7) * .9 + i;
      _put(
        i % 3 == 0 ? cream : lilac,
        _feather,
        Offset(x, y),
        s,
        s * .55,
        turn,
      );
    }
    final fade = 1 - _ramp(k, 2.3, 2.7);
    c.drawPath(lilac, KingCooHudFx.stroke(_p, h * .004, .85 * fade));
    c.drawPath(cream, KingCooHudFx.stroke(_p, h * .004, .85 * fade));
    c.drawPath(lilac, KingCooHudFx.solid(KingCooPalette.feather, .95 * fade));
    c.drawPath(cream, KingCooHudFx.solid(KingCooPalette.breastLit, .95 * fade));
  }

  /// A soft ring of down rolling out of the burst, [k] seconds after it: a
  /// cream ring and a thin lilac one, each heavy at first and thin as it grows
  /// to some one screen height. Gentler than a blast: this is a pillow.
  static void shockwave(Canvas c, Offset at, double h, double k) {
    if (!k.isFinite || !at.isFinite || !h.isFinite) return;
    for (var i = 0; i < 2; i++) {
      final u = _ramp(k, i * .08, .6 + i * .1);
      if (u <= 0 || u >= 1) continue;
      final r = h * .9 * _outCubic(u) * (1 - i * .15);
      final fade = (1 - u) * (1 - u);
      final weight = h * (.026 - i * .009) * (1 - u * .8);
      c.drawCircle(
        at,
        r,
        KingCooHudFx.stroke(
          KingCooPalette.featherDeep,
          weight * 1.4,
          fade * .22,
        ),
      );
      c.drawCircle(
        at,
        r,
        KingCooHudFx.stroke(
          i == 0 ? KingCooPalette.breastHi : KingCooPalette.featherLit,
          weight * .5,
          fade,
        ),
      );
    }
  }

  /// The payoff's shower (the fix round): crumbs and feathers rain down over the
  /// whole sky after the pop, thickest round the pop and across his side of the
  /// screen, falling and swaying to the ground line, from [k] = .1 to 3.1 s
  /// since the burst. One bell of density (a few at the start, a downpour at
  /// 1 to 2 s, a last few), at most 36 falling at once, three paths, no layer.
  /// Under Reduced Motion a still scatter fades in and out in place.
  /// [aroundX] is the burst's x in pixels.
  static void shower(
    Canvas c,
    Size size,
    double k,
    double aroundX, {
    required bool reduced,
  }) {
    if (!k.isFinite || !size.isFinite || !aroundX.isFinite) return;
    if (k <= .05 || k >= 3.3) return;
    final w = size.width, h = size.height;
    final crust = _a..reset(), soft = _b..reset();
    final lilac = _c..reset(), cream = _featherCream..reset();
    final quills = _quillsPath..reset();
    var any = false;
    for (var i = 0; i < _showerN; i++) {
      final delay = .1 + 1.9 * KingCooHudFx.hash(i, 401);
      final fall = 1.25 + 1.0 * KingCooHudFx.hash(i, 403);
      final feather = i % 5 < 2;
      final span = feather ? fall * 1.25 : fall;
      final t = (k - delay) / span;
      // Across his side of the sky, a third of them anywhere.
      final spread = i % 3 == 0 ? w : w * .55;
      final x0 =
          (aroundX + (KingCooHudFx.hash(i, 405) - .5) * spread).clamp(
            w * .04,
            w * .97,
          );
      var alpha = 1.0;
      Offset p;
      double turn;
      if (reduced) {
        // A still scatter: where each would be a third of the way down.
        final seen = _ramp(k, .3, .8) * (1 - _ramp(k, 2.2, 3.0));
        if (seen <= 0) continue;
        alpha = seen * .9;
        p = Offset(x0, h * (.12 + .7 * KingCooHudFx.hash(i, 407)));
        turn = KingCooHudFx.hash(i, 409) * 6.28;
      } else {
        if (t <= 0 || t >= 1) continue;
        final sway = math.sin(t * (feather ? 7 : 4.5) + i * 1.7);
        p = Offset(
          x0 + sway * h * (feather ? .05 : .025),
          h * (-.04 + 1.0 * (feather ? t * (2 - t) * .9 + t * .1 : t * t * .6 + t * .4)),
        );
        turn = (feather ? sway * .9 : t * (5 + 5 * KingCooHudFx.hash(i, 411))) + i;
        alpha = _ramp(t, 0, .08) * (1 - _ramp(t, .86, 1));
      }
      if (alpha <= 0) continue;
      any = true;
      if (feather) {
        final s = h * (.026 + .012 * KingCooHudFx.hash(i, 413));
        final flat = reduced ? 1.0 : .5 + .5 * math.cos(k * 5 + i);
        _put(i.isEven ? lilac : cream, _feather, p, s, s * .6 * flat, turn);
        _put(quills, _quill, p, s, s * .6 * flat, turn);
      } else {
        final s = h * (.0105 + .008 * KingCooHudFx.hash(i, 415));
        _put(crust, _crumb, p, s * 1.3, s * 1.3, turn);
        _put(soft, _crumb, p, s, s, turn);
      }
    }
    if (!any) return;
    final a = reduced
        ? 1.0
        : (_ramp(k, .05, .3) * (1 - _ramp(k, 3.0, 3.3))).clamp(0.0, 1.0);
    c.drawPath(lilac, KingCooHudFx.stroke(_p, h * .0048, .9 * a));
    c.drawPath(cream, KingCooHudFx.stroke(_p, h * .0048, .9 * a));
    c.drawPath(lilac, KingCooHudFx.solid(KingCooPalette.feather, .95 * a));
    c.drawPath(cream, KingCooHudFx.solid(KingCooPalette.breastLit, .95 * a));
    c.drawPath(
      quills,
      KingCooHudFx.stroke(KingCooPalette.featherDeep, h * .0024, .8 * a),
    );
    c.drawPath(crust, KingCooHudFx.solid(KingCooPalette.crust, a));
    c.drawPath(soft, KingCooHudFx.solid(KingCooPalette.crumbHi, a));
  }

  static const _showerN = 36;
  static final Path _featherCream = Path(), _quillsPath = Path();

  /// The feathers of the swell (the fix round): while his chest inflates, a
  /// few small feathers shake loose off its lower left on a beat, drift out and
  /// away in a curl and fade, so the swell reads as a puff of plumage and not
  /// only a bigger ball. [t] is the pose's clock (seconds), [swell] the chest's
  /// `puff` 0..1; they come only while it is swelling (not fluffed, not taut).
  /// Motion only: none under Reduced Motion (the ruffle on the chest itself and
  /// the gold ring keep the state).
  static void ruffle(
    Canvas c,
    Offset chest,
    double h,
    double t,
    double swell, {
    required bool reduced,
  }) {
    if (reduced || !t.isFinite || !chest.isFinite || !h.isFinite) return;
    if (swell <= .04 || swell >= .97) return;
    final lilac = _a..reset(), cream = _b..reset();
    const beat = .13, life = .8;
    final n = (t / beat).floor();
    var any = false;
    for (var j = 0; j < 6; j++) {
      final id = n - j;
      if (id < 0) break;
      final age = t - id * beat;
      if (age <= 0 || age >= life) continue;
      final u = age / life;
      final a = (112 + 130 * KingCooHudFx.hash(id, 421)) * math.pi / 180;
      final out = h * (.012 + .13 * (1 - math.exp(-u * 2.6)) / .93);
      final curl = (KingCooHudFx.hash(id, 423) - .5) * 1.4 * u;
      final dir = a + curl;
      final p =
          chest +
          Offset(math.cos(a), math.sin(a)) * h * .125 * (.9 + .3 * swell) +
          Offset(math.cos(dir), math.sin(dir)) * out +
          Offset(0, -h * .03 * u);
      final s = h * (.017 + .008 * KingCooHudFx.hash(id, 425)) * (1 - .35 * u);
      _put(id.isEven ? lilac : cream, _feather, p, s, s * .6, dir + u * 3);
      any = true;
    }
    if (!any) return;
    final fadeSwell = _ramp(swell, .04, .16) * (1 - _ramp(swell, .85, .97));
    c.drawPath(lilac, KingCooHudFx.stroke(_p, h * .0042, .9 * fadeSwell));
    c.drawPath(cream, KingCooHudFx.stroke(_p, h * .0042, .9 * fadeSwell));
    c.drawPath(lilac, KingCooHudFx.solid(KingCooPalette.feather, fadeSwell));
    c.drawPath(cream, KingCooHudFx.solid(KingCooPalette.breastLit, fadeSwell));
  }

  /// The defeat's keepsake: the brass badge off his chest is not lost but
  /// freed. It pops loose out of the burst, is flung up, hangs, rises on a
  /// trail of sparkles and, as the down settles, melts into a warm, soft glow
  /// over the place he was: surprise, then awe, then a laugh. [k] is seconds
  /// since the burst (`SkyBoss.burstAt`).
  ///
  /// Beats ([k], with the game's death clock = k + .85): the badge shows at
  /// .10 as the flash clears, flies to .45, rises to the glow's height by
  /// 1.10, melts into the glow over .98 to 1.32, and the glow holds to 1.55
  /// and goes out by 2.15. The glow is small and high (under the top
  /// letterbox, over his side of the sky) and dims before the victory title
  /// has finished settling, so the title's zone (the middle of the frame,
  /// from a fifth to a half of the height) is never covered. [fade] (0 to 1)
  /// lets the game take the glow away sooner. Under Reduced Motion the badge
  /// hangs still where the glow will be, fading in, and the glow fades in and
  /// out with the same beats; nothing flies.
  static void victoryBadge(
    Canvas c,
    Offset at,
    double h,
    double k, {
    required bool reduced,
    double fade = 1,
    Offset? restAt,
  }) {
    if (!k.isFinite || !at.isFinite || !h.isFinite || !fade.isFinite) return;
    if (k <= .1 || k >= (restAt == null ? 2.15 : 2.7) || fade <= 0) return;
    // Up and to his left: New York's moon hangs upper right.
    final sunAt = Offset(at.dx - h * .1, math.max(h * .2, at.dy - h * .34));
    final flung = at + Offset(-h * .035, -h * .13);
    // With a [restAt] (the fix round: the cap's landing) the badge does not melt
    // into the glow: it hangs in it, then glides down to float beside the cap
    // (1.55 to 2.2 s) until 2.45 s and fades by 2.7 s.
    final toRest = restAt == null ? 0.0 : BossMotion.ease(_ramp(k, 1.55, 2.2));
    Offset badgeAt(double kk) {
      if (reduced) {
        return restAt == null
            ? sunAt
            : Offset.lerp(sunAt, restAt, kk >= 1.55 ? 1.0 : 0.0)!;
      }
      final out = _outCubic(_ramp(kk, .1, .5));
      final rise = BossMotion.ease(_ramp(kk, .45, 1.1));
      final p = Offset.lerp(at, flung, out)!;
      final wobble = math.sin(kk * 9) * h * .005 * (1 - rise);
      final up = Offset.lerp(p, sunAt, rise)! + Offset(wobble, 0);
      if (restAt == null) return up;
      final bob = math.sin(kk * 3.2) * h * .006 * toRest;
      return Offset.lerp(up, restAt, BossMotion.ease(_ramp(kk, 1.55, 2.2)))! +
          Offset(0, bob);
    }

    final badgeA = restAt == null
        ? (reduced ? _ramp(k, .1, .4) : _ramp(k, .1, .2)) *
              (1 - _ramp(k, .98, 1.32)) *
              fade
        : (reduced ? _ramp(k, .1, .4) : _ramp(k, .1, .2)) *
              (1 - _ramp(k, 2.45, 2.7)) *
              fade;
    final sunA = _ramp(k, .95, 1.3) * (1 - _ramp(k, 1.55, 2.15)) * fade;
    final r = h * .05;

    if (badgeA > 0) {
      final p = badgeAt(k);
      // A trail of sparkles along the flight, thinning behind it.
      if (!reduced && k < 1.1) {
        final trail = _a..reset();
        for (var j = 1; j <= 8; j++) {
          final kk = k - j * .04;
          if (kk <= .1) break;
          final s =
              r * .34 * (1 - j / 9) * (.7 + .3 * KingCooHudFx.hash(j, 361));
          final drift = Offset(
            (KingCooHudFx.hash(j, 363) - .5) * r * .5,
            j * r * .06,
          );
          _sparkle(trail, badgeAt(kk) + drift, s, kk * 4);
        }
        c.drawPath(trail, KingCooHudFx.solid(KingCooPalette.gold, badgeA));
      }
      _disc(
        c,
        p,
        r * (3.1 + 1.0 * toRest),
        'badgeGlow',
        [
          KingCooPalette.gold.withValues(alpha: .7),
          KingCooPalette.brass.withValues(alpha: .28),
          KingCooPalette.brass.withValues(alpha: 0),
        ],
        const [0, .4, 1],
        badgeA * (reduced ? .8 : .75 + .25 * math.sin(k * 10)),
      );
      final pop = reduced
          ? 1.0
          : 1 + .35 * math.sin(math.pi * _ramp(k, .1, .4));
      final melt = restAt == null ? 1 - .4 * _ramp(k, .98, 1.32) : 1.0;
      final turn = reduced ? 1.0 : .74 + .26 * math.cos(k * 7);
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(turn, 1);
      c.translate(-p.dx, -p.dy);
      KingCooHudArt.badge(c, p, r * pop * melt, u: h * .004, alpha: badgeA);
      c.restore();
    }

    if (sunA > 0) {
      final grow = .7 + .3 * _outCubic(_ramp(k, .95, 1.5));
      final beat = reduced ? 1.0 : 1 + .03 * math.sin(k * 5);
      final radius = h * .19 * grow * beat;
      _disc(
        c,
        sunAt,
        radius * 1.9,
        'glowCorona',
        [
          KingCooPalette.gold.withValues(alpha: .34),
          KingCooPalette.gold.withValues(alpha: .14),
          KingCooPalette.brass.withValues(alpha: 0),
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
        c.drawPath(rays, KingCooHudFx.solid(KingCooPalette.gold, .17 * sunA));
      }
      _disc(
        c,
        sunAt,
        radius,
        'glowCore',
        [
          const Color(0xffffffff).withValues(alpha: .95),
          KingCooPalette.crumbHi.withValues(alpha: .85),
          KingCooPalette.gold.withValues(alpha: .5),
          KingCooPalette.brass.withValues(alpha: .16),
          KingCooPalette.brass.withValues(alpha: 0),
        ],
        const [0, .2, .5, .8, 1],
        sunA,
      );
      // A last sparkle of siren light in it, red and blue.
      if (!reduced) {
        final tw = _a..reset(), tb = _b..reset();
        _sparkle(
          tw,
          sunAt + Offset(-radius * .34, -radius * .2),
          h * .026 * sunA,
          k * 2,
        );
        _sparkle(
          tb,
          sunAt + Offset(radius * .3, radius * .1),
          h * .02 * sunA,
          -k * 2,
        );
        c.drawPath(tw, KingCooHudFx.solid(KingCooPalette.sirenRed, .9 * sunA));
        c.drawPath(tb, KingCooHudFx.solid(KingCooPalette.sirenBlue, .9 * sunA));
      }
    }
  }
}

/// The card's measured layout: everything that depends only on the viewport
/// and the boss's room.
class _Card {
  _Card(this.size, double room, this.word, this.title)
    : room = room.round() {
    final h = size.height, w = size.width;
    double wanted(double f) {
      final n = KingCooEncounterUi._text(
        'name',
        word,
        h * .078 * f,
        color: KingCooPalette.white,
        spacing: 1,
        weight: FontWeight.w700,
      );
      final sub = KingCooEncounterUi._text(
        'title',
        title,
        h * .0255 * f,
        spacing: 1.6,
      );
      return math.max(n.width + h * .1 * f, sub.width + h * .115 * f);
    }

    var fit = 1.0;
    final full = wanted(1);
    if (full > room && room > 0) fit = math.max(.6, room / full);
    f = fit;
    hf = h * f;
    nameSize = h * .078 * f;
    final probe = KingCooEncounterUi._text(
      'name',
      word,
      nameSize,
      color: KingCooPalette.white,
      spacing: 1,
      weight: FontWeight.w700,
    );
    nameW = probe.width;
    nameH = probe.height;
    glyphs = [for (var i = 0; i < word.length; i++) word[i]];
    final xs = <double>[], ws = <double>[];
    for (var i = 0; i < word.length; i++) {
      final boxes = probe.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      xs.add(boxes.isEmpty ? 0.0 : boxes.first.left);
      ws.add(boxes.isEmpty ? 0.0 : boxes.first.right - boxes.first.left);
    }
    glyphX = xs;
    glyphW = ws;
    outline = KingCooEncounterUi._text(
      'outline',
      word,
      nameSize,
      spacing: 1,
      stroke: h * .012 * f,
      weight: FontWeight.w700,
    );
    final sub = subtitle(1);
    final wc = math.max(nameW + h * .1 * f, sub.width + h * .115 * f);
    final hc = hf * .272;
    final x0 = math.min(w * .075, w * .5 - wc);
    plate = Rect.fromLTWH(math.max(h * .04, x0), h * .142, wc, hc);
    final r = Radius.circular(hf * .026);
    body = RRect.fromRectAndRadius(plate, r);
    final ins = hf * .014;
    inner = RRect.fromRectAndRadius(
      plate.deflate(ins),
      Radius.circular(hf * .016),
    );
    // The Sillitoe band along the lower edge: two rows of checks.
    final sq = hf * .0125;
    final top = plate.bottom - ins - 2 * sq;
    final ch = Path();
    for (var row = 0; row < 2; row++) {
      for (var i = row.isEven ? 0 : 1; ; i += 2) {
        final x = plate.left + ins + i * sq;
        if (x + sq > plate.right - ins) break;
        ch.addRect(Rect.fromLTWH(x, top + row * sq, sq, sq));
      }
    }
    checks = ch;
    // Brass stars on the four corners.
    final st = Path();
    final sr = hf * .0115;
    for (final p in [
      Offset(plate.left + ins * 1.9, plate.top + ins * 1.9),
      Offset(plate.right - ins * 1.9, plate.top + ins * 1.9),
      Offset(plate.left + ins * 1.9, top - ins * .8),
      Offset(plate.right - ins * 1.9, top - ins * .8),
    ]) {
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final rr = i.isEven ? sr : sr * .46;
        final o = Offset(p.dx + math.cos(a) * rr, p.dy + math.sin(a) * rr);
        i == 0 ? st.moveTo(o.dx, o.dy) : st.lineTo(o.dx, o.dy);
      }
      st.close();
    }
    studs = st;
    // The ribbon, centred on the plate's top edge.
    final ribbonSize = hf * .0285;
    ribbonText = KingCooEncounterUi._text(
      'ribbon',
      KingCooEncounterUi.ribbonWord,
      ribbonSize,
      color: KingCooPalette.ink,
      spacing: 1.2,
      body: true,
    );
    final ribH = ribbonText.height + hf * .016;
    shieldR = ribH * .78;
    final shieldRoom = shieldR * 1.45;
    final ribW = shieldRoom + ribbonText.width + hf * .05;
    final left = plate.center.dx - ribW / 2;
    ribbonBox = Rect.fromLTWH(left, plate.top - ribH / 2, ribW, ribH);
    final fork = hf * .022;
    ribbon = Path()
      ..moveTo(left + 3, ribbonBox.top)
      ..lineTo(ribbonBox.right, ribbonBox.top)
      ..lineTo(ribbonBox.right - fork, ribbonBox.center.dy)
      ..lineTo(ribbonBox.right, ribbonBox.bottom)
      ..lineTo(left + 3, ribbonBox.bottom)
      ..quadraticBezierTo(left, ribbonBox.bottom, left, ribbonBox.bottom - 3)
      ..lineTo(left, ribbonBox.top + 3)
      ..quadraticBezierTo(left, ribbonBox.top, left + 3, ribbonBox.top)
      ..close();
    ribbonTextAt = Offset(
      left + shieldRoom + hf * .006,
      ribbonBox.center.dy - ribbonText.height / 2,
    );
    shieldAt = Offset(left + shieldR * .5, ribbonBox.center.dy);
    // The siren lamp on the top-right corner, its base on the edge.
    lampR = hf * .064;
    lampAt = Offset(
      plate.right - hf * .085,
      plate.top - lampR * .17 - hf * .004,
    );
  }

  final Size size;
  final int room;
  final String word, title;

  /// How much smaller than full size the plate had to be to fit.
  late final double f, hf;
  late final double nameSize, nameW, nameH, shieldR, lampR;
  late final List<String> glyphs;
  late final List<double> glyphX, glyphW;
  late final TextPainter outline, ribbonText;
  late final Rect plate, ribbonBox;
  late final RRect body, inner;
  late final Path checks, studs, ribbon;
  late final Offset ribbonTextAt, shieldAt, lampAt;

  // One letter, ink-edged and filled, at [alpha] (cached by the text cache).
  TextPainter outlineGlyph(int i, double alpha) => KingCooEncounterUi._text(
    'glyphEdge',
    glyphs[i],
    nameSize,
    spacing: 1,
    stroke: size.height * .012 * f,
    alpha: alpha,
    weight: FontWeight.w700,
  );

  TextPainter fillGlyph(int i, double alpha) => KingCooEncounterUi._text(
    'glyph',
    glyphs[i],
    nameSize,
    color: KingCooEncounterUi._cream,
    spacing: 1,
    alpha: alpha,
    weight: FontWeight.w700,
  );

  // The story quote's type: a little under the epithet's size again, so it
  // reads as spoken.
  double get _quoteSize => size.height * .0445 * f;
  double get _quoteWidth => plate.width - size.height * .06 * f;

  TextPainter quoteFill(String line, double alpha) => KingCooEncounterUi._text(
    'quote',
    line,
    _quoteSize,
    color: KingCooEncounterUi._cream,
    italic: true,
    width: _quoteWidth,
    maxLines: 2,
    alpha: alpha,
  );

  TextPainter quoteEdge(String line, double alpha) => KingCooEncounterUi._text(
    'quoteEdge',
    line,
    _quoteSize,
    italic: true,
    width: _quoteWidth,
    maxLines: 2,
    stroke: size.height * .0105 * f,
    alpha: alpha,
  );

  /// Where the quote sits: centred under the plate.
  Rect quoteBox(String line) => Rect.fromLTWH(
    plate.center.dx - _quoteWidth / 2,
    plate.bottom + size.height * .03 * f,
    _quoteWidth,
    quoteFill(line, 1).height,
  );

  TextPainter subtitle(double alpha) => KingCooEncounterUi._text(
    'title',
    title,
    size.height * .0255 * f,
    spacing: 1.6,
    alpha: alpha,
  );
}
