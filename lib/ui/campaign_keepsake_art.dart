import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/sky_boss.dart' show BossKind;
import '../game/boss_rig.dart';
import '../game/dragon_boss_rig.dart';
import '../game/dusk_moth_boss_rig.dart';
import '../game/gargoyle_kit.dart' show GargoyleTone;
import '../game/gargoyle_story_art.dart';
import '../game/king_coo_boss_rig.dart';
import '../game/king_coo_staging_art.dart' show KingCooStaging;
import '../game/neferhoo_story_art.dart';
import '../game/pirate_boss_rig.dart';
import '../game/spitter_boss_rig.dart';
import '../game/star_art.dart';
import '../l10n/l10n.dart' show L10n;
import 'theme.dart';

// l10n-english-twin: the boss names in [CampaignHeadwear.name] are the twins
// of the ARB keys `boss_*_name`; screens show `l.bossName(kind)`.

/// Whether [text] is set right to left and its letters join (Arabic): such
/// words are shaped whole, never set one letter at a time.
bool _joinedScript(String text) => text.runes.any(
  (r) =>
      (r >= 0x0600 && r <= 0x06ff) ||
      (r >= 0x0750 && r <= 0x077f) ||
      (r >= 0x08a0 && r <= 0x08ff) ||
      (r >= 0xfb50 && r <= 0xfdff) ||
      (r >= 0xfe70 && r <= 0xfeff),
);

TextDirection _directionOf(String text) =>
    _joinedScript(text) ? TextDirection.rtl : TextDirection.ltr;

/// The headwear each boss loses in its defeat, drawn by the boss's own
/// painter and fitted into any box: a boss lair on the map, a postage stamp.
abstract final class CampaignHeadwear {
  /// How far each painter reaches around its origin, measured from renders.
  static Rect _reach(BossKind boss) => switch (boss) {
    BossKind.baronBat => const Rect.fromLTRB(-.84, -1.86, .9, -.6),
    BossKind.spitterBeetle => const Rect.fromLTRB(-.6, -.74, .6, .22),
    BossKind.duskMoth => const Rect.fromLTRB(-.8, -1.0, .56, .26),
    BossKind.pirate => const Rect.fromLTRB(-1.2, -1.4, 1.75, .22),
    BossKind.dragon => const Rect.fromLTRB(-.36, -.42, .36, .16),
    BossKind.kingCoo => KingCooStaging.capReach,
    // The Gargoyle's brow visor, about its seat (measured from the render).
    BossKind.searchlightGargoyle => GargoyleStoryArt.visorReach,
    // Neferhoo's golden mask.
    BossKind.neferhoo => NeferhooStoryArt.maskReach,
  };

  static void paint(Canvas canvas, Rect box, BossKind boss) {
    final reach = _reach(boss);
    final scale = math.min(box.width / reach.width, box.height / reach.height);
    canvas.save();
    canvas.translate(box.center.dx, box.center.dy);
    canvas.scale(scale);
    canvas.translate(-reach.center.dx, -reach.center.dy);
    switch (boss) {
      case BossKind.baronBat:
        BossRig.crown(canvas);
      case BossKind.spitterBeetle:
        SpitterBossRig.crown(canvas);
      case BossKind.duskMoth:
        DuskMothBossRig.crown(canvas);
      case BossKind.pirate:
        PirateBossRig.hat(canvas, worn: false);
      case BossKind.dragon:
        DragonBossRig.crownPaint(canvas);
      case BossKind.kingCoo:
        // The police cap he loses: the rig's own, band centre at the origin.
        KingCooBossRig.capPaint(canvas);
      case BossKind.searchlightGargoyle:
        // Under 34 px (the map shield, the card's ribbon, the route mark) the
        // emblem is the brass lens alone; larger, the lens under its hood.
        GargoyleStoryArt.visor(
          canvas,
          const GargoyleTone(),
          box.shortestSide < GargoyleStoryArt.lensOnlyBelow,
        );
      case BossKind.neferhoo:
        // The golden mask he loses: under 40 px (the map shield, the route
        // mark) the bold emblem, larger the rig's own mask.
        NeferhooStoryArt.mask(
          canvas,
          small: box.shortestSide < NeferhooStoryArt.emblemBelow,
        );
    }
    canvas.restore();
  }

  /// The boss's name in English: the twin of `l.bossName(boss)`, which the
  /// screens show.
  static String name(BossKind boss) => switch (boss) {
    BossKind.baronBat => 'Baron Bat',
    BossKind.spitterBeetle => 'Spitter King',
    BossKind.duskMoth => 'Dusk Empress',
    BossKind.pirate => 'Pirate Captain',
    BossKind.dragon => 'Ember Dragon',
    BossKind.kingCoo => 'King Coo',
    BossKind.searchlightGargoyle => 'Searchlight Gargoyle',
    BossKind.neferhoo => 'Neferhoo',
  };

  /// Each chapter's stamp colour, chosen so the headwear stands out on it.
  static Color field(BossKind boss) => switch (boss) {
    BossKind.baronBat => const Color(0xff7d68c4),
    BossKind.spitterBeetle => SkyColors.coral,
    BossKind.duskMoth => const Color(0xff3a4478),
    BossKind.pirate => const Color(0xff3f9cc0),
    BossKind.dragon => const Color(0xffd24a3c),
    // The brass of his badge: the navy cap stands out on it.
    BossKind.kingCoo => const Color(0xffe0a93a),
    // Night indigo (L about 24): his brass lens and pale hood read on it, and
    // King Coo keeps the amber.
    BossKind.searchlightGargoyle => const Color(0xff2f3a6b),
    // Lapis: the gold mask reads on it at 72 and at 24 px (design §5.7).
    BossKind.neferhoo => NeferhooStoryArt.field,
  };
}

/// A perforated postage stamp with a boss's headwear on a sunburst field.
class CampaignStampPainter extends CustomPainter {
  const CampaignStampPainter(this.boss, {this.chapter = 1, this.label});
  final BossKind boss;
  final int chapter;

  /// The club's name on the stamp's band; the current language's
  /// ("SKY CLUB") when null.
  final String? label;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paper = _perforated(Offset.zero & size, math.min(w, h) * .055);
    canvas.drawPath(
      paper.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .2),
    );
    canvas.drawPath(paper, Paint()..color = Colors.white);
    canvas.drawPath(
      paper,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final inset = math.min(w, h) * .13;
    final field = Rect.fromLTRB(inset, inset, w - inset, h - inset);
    final color = CampaignHeadwear.field(boss);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(field, const Radius.circular(3)));
    canvas.drawRect(
      field,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.1),
          radius: .9,
          colors: [
            Color.lerp(color, SkyColors.cream, .38)!,
            color,
            Color.lerp(color, SkyColors.ink, .22)!,
          ],
          stops: const [0, .62, 1],
        ).createShader(field),
    );
    // A slow sunburst behind the headwear, like an engraved stamp.
    final rays = Paint()..color = SkyColors.cream.withValues(alpha: .13);
    final hub = field.center.translate(0, -field.height * .06);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8, spread = math.pi / 26;
      final reach = field.longestSide;
      canvas.drawPath(
        Path()
          ..moveTo(hub.dx, hub.dy)
          ..lineTo(
            hub.dx + math.cos(a - spread) * reach,
            hub.dy + math.sin(a - spread) * reach,
          )
          ..lineTo(
            hub.dx + math.cos(a + spread) * reach,
            hub.dy + math.sin(a + spread) * reach,
          )
          ..close(),
        rays,
      );
    }
    final art = Rect.fromCenter(
      center: hub,
      width: field.width * .86,
      height: field.height * .56,
    );
    CampaignHeadwear.paint(canvas, art, boss);
    // The name band, so "SKY CLUB" reads on any field colour.
    final band = Rect.fromLTRB(
      field.left,
      field.bottom - field.height * .24,
      field.right,
      field.bottom,
    );
    canvas.drawRect(
      band,
      Paint()
        ..color = Color.lerp(color, SkyColors.ink, .55)!.withValues(alpha: .72),
    );
    canvas.drawLine(
      band.topLeft,
      band.topRight,
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .55)
        ..strokeWidth = 1,
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(field, const Radius.circular(3)),
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // A fine engraved frame just inside the field.
    canvas.drawRRect(
      RRect.fromRectAndRadius(field.deflate(3), const Radius.circular(2)),
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    // The value in the corner is the chapter, in stars.
    StarArt.mini(
      canvas,
      field.topLeft + Offset(field.width * .17, field.width * .17),
      field.width * .11,
      outline: 1,
    );
    // The number is inked around, so it reads on any field colour.
    final numeral =
        field.topLeft + Offset(field.width * .32, field.width * .05);
    final digit = field.width * .21;
    _text(
      canvas,
      '$chapter',
      numeral,
      heading(digit, weight: FontWeight.w700).copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = digit * .2
          ..color = SkyColors.ink.withValues(alpha: .75),
      ),
    );
    _text(
      canvas,
      '$chapter',
      numeral,
      heading(digit, color: SkyColors.cream, weight: FontWeight.w700),
    );
    _text(
      canvas,
      label ?? L10n.strings.campaignStampSkyClub,
      Offset(field.center.dx, band.center.dy - field.width * .075),
      bodyText(
        field.width * .15,
        color: SkyColors.cream,
        weight: FontWeight.w900,
      ).copyWith(letterSpacing: field.width * .012, height: 1),
      center: true,
      maxWidth: field.width * .94,
    );
  }

  /// Sets [text] at [at] (its top centre with [center]); a [maxWidth] it
  /// would run past squeezes it to that width about its centre.
  static void _text(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style, {
    bool center = false,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: _directionOf(text),
    )..layout();
    final origin = center ? at - Offset(painter.width / 2, 0) : at;
    if (maxWidth != null && painter.width > maxWidth) {
      final k = maxWidth / painter.width;
      final mid = origin + Offset(painter.width / 2, painter.height / 2);
      canvas.save();
      canvas.translate(mid.dx, mid.dy);
      canvas.scale(k);
      canvas.translate(-mid.dx, -mid.dy);
      painter.paint(canvas, origin);
      canvas.restore();
    } else {
      painter.paint(canvas, origin);
    }
    painter.dispose();
  }

  /// A rectangle whose edges are bitten by evenly spaced round perforations.
  static Path _perforated(Rect r, double radius) {
    final path = Path()..addRect(r);
    final holes = Path();
    void edge(Offset from, Offset to) {
      final length = (to - from).distance;
      final n = (length / (radius * 3.2)).round();
      for (var i = 0; i <= n; i++) {
        holes.addOval(
          Rect.fromCircle(
            center: Offset.lerp(from, to, i / n)!,
            radius: radius,
          ),
        );
      }
    }

    edge(r.topLeft, r.topRight);
    edge(r.bottomLeft, r.bottomRight);
    edge(r.topLeft, r.bottomLeft);
    edge(r.topRight, r.bottomRight);
    return Path.combine(PathOperation.difference, path, holes);
  }

  @override
  bool shouldRepaint(CampaignStampPainter old) =>
      old.boss != boss || old.chapter != chapter || old.label != label;
}

/// A round rubber postmark with wavy cancel lines, printed in soft indigo
/// ink that wears away in specks like a real rubber stamp. The ring sits at
/// the left of its box and the lines run to the right edge.
class CampaignPostmarkPainter extends CustomPainter {
  const CampaignPostmarkPainter({
    required this.top,
    required this.bottom,
    this.middle = '',
  });

  /// Lettering around the upper and lower rims, and across the middle.
  final String top, bottom, middle;

  static const _ink = Color(0xff35306b);

  /// How much of the page's colour the ink lets through.
  static const _strength = .68;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final center = Offset(r, r);
    // The whole strike is drawn solid into one layer, worn with holes, then
    // laid on the card translucent, so overlaps never double the ink.
    canvas.saveLayer(
      (Offset.zero & size).inflate(4),
      Paint()..color = _ink.withValues(alpha: _strength),
    );
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r * .95, ink..strokeWidth = r * .075);
    canvas.drawCircle(center, r * .57, ink..strokeWidth = r * .05);
    final style = bodyText(
      r * .26,
      color: _ink,
      weight: FontWeight.w900,
    ).copyWith(letterSpacing: r * .03, height: 1);
    _arc(canvas, top, center, r * .765, style, upper: true);
    _arc(canvas, bottom, center, r * .765, style, upper: false);
    // A star on each side, where the two words meet.
    for (final side in [-1.0, 1.0]) {
      StarArt.sparkle(
        canvas,
        center + Offset(side * r * .765, 0),
        r * .085,
        _ink,
      );
    }
    // A date-box in the middle: the word between two rules.
    final rule = r * .2;
    ink.strokeWidth = r * .04;
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        center + Offset(-r * .42, side * rule),
        center + Offset(r * .42, side * rule),
        ink,
      );
      StarArt.sparkle(
        canvas,
        center + Offset(0, side * r * .375),
        r * .07,
        _ink,
      );
    }
    _centered(
      canvas,
      middle,
      center,
      bodyText(
        r * .175,
        color: _ink,
        weight: FontWeight.w900,
      ).copyWith(letterSpacing: r * .015, height: 1),
    );
    // Cancel lines run off to the right, from the ring across the stamp.
    final waves = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .065
      ..strokeCap = StrokeCap.round;
    for (var k = -2; k <= 2; k++) {
      final y = center.dy + k * r * .33;
      final reach = r * r * .9 - (y - r) * (y - r);
      final left = center.dx + math.sqrt(math.max(0, reach));
      final wave = Path()..moveTo(left - r * .04, y);
      for (var x = left; x < size.width - r * .5; x += r * .5) {
        wave.relativeQuadraticBezierTo(r * .125, -r * .13, r * .25, 0);
        wave.relativeQuadraticBezierTo(r * .125, r * .13, r * .25, 0);
      }
      canvas.drawPath(wave, waves);
    }
    // Wear: a few specks of bare paper, and scuffs across the ring.
    final rng = math.Random(top.codeUnits.fold<int>(7, (a, c) => a * 31 + c));
    final bare = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 22; i++) {
      final p = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      canvas.drawCircle(p, r * (.012 + rng.nextDouble() * .022), bare);
    }
    bare.strokeWidth = r * .045;
    for (var i = 0; i < 3; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * r * .9,
        center + dir * r * (1 + rng.nextDouble() * .1),
        bare,
      );
    }
    canvas.restore();
  }

  static void _centered(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style,
  ) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: _directionOf(text),
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
  }

  /// Letters set one by one along the rim, reading left to right on both
  /// the upper and the lower arc. Long words shrink to keep to their half of
  /// the ring, so the two never run into each other. Joined letters
  /// (Arabic) are shaped as one word and bent along the rim in thin
  /// slices instead ([_arcShaped]).
  static void _arc(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    TextStyle style, {
    required bool upper,
  }) {
    if (text.isEmpty) return;
    if (_joinedScript(text)) {
      return _arcShaped(canvas, text, center, radius, style, upper: upper);
    }
    List<TextPainter> lay(TextStyle s) => [
      for (final ch in text.characters)
        TextPainter(
          text: TextSpan(text: ch, style: s),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    var glyphs = lay(style);
    final total = glyphs.fold(0.0, (sum, g) => sum + g.width);
    const room = math.pi * .82;
    if (total / radius > room) {
      for (final g in glyphs) {
        g.dispose();
      }
      final k = room * radius / total;
      glyphs = lay(
        style.copyWith(
          fontSize: style.fontSize! * k,
          letterSpacing: style.letterSpacing! * k,
        ),
      );
    }
    final span = glyphs.fold(0.0, (sum, g) => sum + g.width);
    var angle = -span / radius / 2;
    for (final g in glyphs) {
      final half = g.width / 2 / radius;
      final a = angle + half;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      if (upper) {
        canvas.rotate(a);
        canvas.translate(-g.width / 2, -radius - g.height * .5);
      } else {
        canvas.rotate(-a);
        canvas.translate(-g.width / 2, radius - g.height * .5);
      }
      g.paint(canvas, Offset.zero);
      canvas.restore();
      angle += half * 2;
      g.dispose();
    }
  }

  /// [_arc] for words whose letters join: the word is shaped whole, then cut
  /// into thin upright slices, each turned to its place on the rim, so the
  /// joins survive the bend.
  static void _arcShaped(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    TextStyle style, {
    required bool upper,
  }) {
    TextPainter lay(TextStyle s) => TextPainter(
      text: TextSpan(text: text, style: s),
      textDirection: TextDirection.rtl,
    )..layout();
    var painter = lay(style);
    const room = math.pi * .82;
    if (painter.width / radius > room) {
      final k = room * radius / painter.width;
      painter.dispose();
      painter = lay(
        style.copyWith(
          fontSize: style.fontSize! * k,
          letterSpacing: style.letterSpacing! * k,
        ),
      );
    }
    final span = painter.width, height = painter.height;
    final slices = math.max(1, (span / (style.fontSize! * .3)).ceil());
    final slice = span / slices;
    for (var i = 0; i < slices; i++) {
      final x = i * slice;
      final a = (x + slice / 2 - span / 2) / radius;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      if (upper) {
        canvas.rotate(a);
        canvas.translate(-slice / 2, -radius - height * .5);
      } else {
        canvas.rotate(-a);
        canvas.translate(-slice / 2, radius - height * .5);
      }
      // A hair of overlap hides the seams between slices.
      canvas.clipRect(Rect.fromLTWH(-.3, 0, slice + .6, height));
      painter.paint(canvas, Offset(-x, 0));
      canvas.restore();
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(CampaignPostmarkPainter old) =>
      old.top != top || old.bottom != bottom || old.middle != middle;
}

/// Cheap procedural card stock, drawn from a fixed seed: edges and corners
/// toned by handling, faint fibres and specks. It never animates, so it
/// costs one paint.
class CampaignPaperPainter extends CustomPainter {
  const CampaignPaperPainter({this.seed = 1, this.radius = 12});
  final int seed;
  final double radius;

  static const _tan = Color(0xffc99e5c);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final card = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(card);
    // Handling tones the edge: a soft ring just inside the outline.
    canvas.drawRRect(
      card.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = _tan.withValues(alpha: .3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Corners take the most wear.
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(
        corner,
        30,
        Paint()
          ..shader = RadialGradient(
            colors: [_tan.withValues(alpha: .3), _tan.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: corner, radius: 30)),
      );
    }
    final rng = math.Random(seed * 7919 + 13);
    Offset any() =>
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
    // Fibres: short curved hairs, a few darker, a few pale.
    final fibre = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final from = any();
      final a = rng.nextDouble() * math.pi * 2;
      final len = 5 + rng.nextDouble() * 11;
      final bend = (rng.nextDouble() - .5) * len * .8;
      fibre.color = i.isEven
          ? _tan.withValues(alpha: .2)
          : Colors.white.withValues(alpha: .7);
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(
            from.dx + math.cos(a) * len / 2 - math.sin(a) * bend,
            from.dy + math.sin(a) * len / 2 + math.cos(a) * bend,
            from.dx + math.cos(a) * len,
            from.dy + math.sin(a) * len,
          ),
        fibre,
      );
    }
    // Specks of grit.
    final speck = Paint();
    for (var i = 0; i < 70; i++) {
      speck.color = (i % 3 == 0 ? SkyColors.muted : _tan).withValues(
        alpha: .08 + rng.nextDouble() * .12,
      );
      canvas.drawCircle(any(), .35 + rng.nextDouble() * .7, speck);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CampaignPaperPainter old) =>
      old.seed != seed || old.radius != radius;
}

/// The red-and-blue slanted border of air mail, as a band just inside a
/// rounded card's edge.
class CampaignAirmailPainter extends CustomPainter {
  const CampaignAirmailPainter({this.band = 6.5, this.radius = 12});
  final double band, radius;

  static final _blue = Color.lerp(SkyColors.skyDeep, SkyColors.ink, .16)!;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final inner = outer.deflate(band);
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(outer)
        ..addRRect(inner),
    );
    canvas.drawRect(Offset.zero & size, Paint()..color = SkyColors.cream);
    const period = 25.0, stripe = 8.5;
    final h = size.height;
    void slant(double x, Color color) => canvas.drawPath(
      Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripe, 0)
        ..lineTo(x + stripe + h, h)
        ..lineTo(x + h, h)
        ..close(),
      Paint()..color = color,
    );
    for (var x = -h; x < size.width; x += period) {
      slant(x, SkyColors.coral);
      slant(x + period / 2, _blue);
    }
    canvas.restore();
    canvas.drawRRect(
      inner,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(CampaignAirmailPainter old) =>
      old.band != band || old.radius != radius;
}

/// Big "Greetings from" postcard lettering: each letter a little off its
/// neighbours, yellow with an ink outline, a gold block of depth and a cream
/// halo, so the name reads against any scenery.
class CampaignLettering extends StatelessWidget {
  const CampaignLettering(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final painter = _LetteringPainter(L10n.upper(text));
    return CustomPaint(size: painter.size, painter: painter);
  }
}

/// Lettering set a letter at a time, each a little off its neighbours; a
/// word whose letters join (Arabic) is set whole, right to left.
class _LetteringPainter extends CustomPainter {
  _LetteringPainter(this.text)
    : fontSize = text.length > 10 ? 34.0 : 42.0,
      direction = _directionOf(text),
      glyphs = _joinedScript(text) ? [text] : text.characters.toList();

  final String text;
  final double fontSize;
  final TextDirection direction;
  final List<String> glyphs;

  double get _gap => fontSize * .03;
  double get _depth => fontSize * .12;

  TextPainter _lay(String ch, {Paint? foreground}) => TextPainter(
    text: TextSpan(
      text: ch,
      style: heading(fontSize, weight: FontWeight.w700).copyWith(
        height: 1,
        foreground: foreground ?? (Paint()..color = SkyColors.yellow),
      ),
    ),
    textDirection: direction,
  )..layout();

  /// The lettering's box, with room for its halo and depth.
  Size get size {
    var width = 0.0, height = 0.0;
    for (final ch in glyphs) {
      final p = _lay(ch);
      width += ch == ' ' ? fontSize * .3 : p.width + _gap;
      height = math.max(height, p.height);
      p.dispose();
    }
    return Size(width + fontSize * .3, height + _depth + fontSize * .2);
  }

  /// Each letter's small lift and lean, fixed by its place in the word.
  (double, double) _wobble(int i) =>
      (math.cos(i * 1.7) * fontSize * .045, math.sin(i * 2.3) * .06);

  @override
  void paint(Canvas canvas, Size size) {
    final pad = fontSize * .15;
    Paint stroke(double width, Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = color;
    // Every layer runs over the whole word, so a letter's depth never cuts
    // into the face of its neighbour.
    void layer(Paint Function(Size box) paint, [double dy = 0]) {
      var x = pad;
      for (var i = 0; i < glyphs.length; i++) {
        final ch = glyphs[i];
        if (ch == ' ') {
          x += fontSize * .3;
          continue;
        }
        final probe = _lay(ch);
        final box = Size(probe.width, probe.height);
        probe.dispose();
        final (lift, lean) = _wobble(i);
        final p = _lay(ch, foreground: paint(box));
        canvas.save();
        canvas.translate(x + box.width / 2, pad + box.height / 2 + lift);
        canvas.rotate(lean);
        canvas.translate(-box.width / 2, -box.height / 2 + dy);
        p.paint(canvas, Offset.zero);
        canvas.restore();
        p.dispose();
        x += box.width + _gap;
      }
    }

    final halo = stroke(fontSize * .3, SkyColors.cream.withValues(alpha: .72));
    layer((_) => halo);
    layer((_) => halo, _depth);
    // The block of depth: gold letters stacked down, each inked.
    final ink = stroke(fontSize * .17, SkyColors.ink);
    final gold = Paint()..color = SkyColors.gold;
    final steps = (_depth / 1.5).ceil();
    for (var s = steps; s >= 1; s--) {
      layer((_) => ink, _depth * s / steps);
      layer((_) => gold, _depth * s / steps);
    }
    layer((_) => ink);
    layer(
      (box) => Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(SkyColors.yellow, Colors.white, .5)!,
            SkyColors.yellow,
            Color.lerp(SkyColors.yellow, SkyColors.gold, .35)!,
          ],
          stops: const [0, .45, 1],
        ).createShader(Offset.zero & box),
    );
  }

  @override
  bool shouldRepaint(_LetteringPainter old) => old.text != text;
}
