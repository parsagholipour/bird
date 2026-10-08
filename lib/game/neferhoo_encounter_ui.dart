import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/campaign.dart';
import '../domain/game_rules.dart';
import '../l10n/l10n.dart';
import '../l10n/text/boss_text.dart';
import 'boss_motion.dart';
import 'neferhoo_hud_art.dart';
import 'neferhoo_kit.dart';
import 'neferhoo_staging_art.dart';

/// Neferhoo's cards (design §5.7): the entrance name card, a papyrus panel in
/// a lapis band with a gold-leaf rim and a hieroglyph border (ankh, wedjat,
/// water, feather), the GUARDIAN ribbon with his mask medallion, NEFERHOO,
/// ◆ KEEPER OF THE LOST LETTER ◆ and the level's line inked under it, the
/// Pharaoh's Post wax seal pinned on its corner; and the victory card on the
/// same plate, GUARDIAN DOWN! · THE LOST LETTER IS FOUND.
///
/// The name card slides in left of centre over the open sky after the
/// HOO-POO-POO (it lands at 2.85 s, the roar's last syllable has gone by
/// 2.95 s), never over his head; it overshoots, settles, a glint crosses its
/// rim, a puff of dust under it; it leaves 4.0 to 4.5 s, before control
/// returns at 4.6. In the campaign the ribbon carries the level's number
/// (GUARDIAN · 2-6) and the panel the level's line; outside it (a test
/// flight, no level) only GUARDIAN, the name and the epithet. Where the
/// bird flies behind the plate it turns see-through. Under Reduced Motion
/// it only fades in and out, still.
///
/// The plates are recorded once per size as pictures and replayed; a card
/// that is fading is drawn through one layer bounded to it. Text is laid
/// out once ([NeferhooStaging.text]). Pure functions of the boss clock.
abstract final class NeferhooEncounterUi {
  /// The ribbon's word: GUARDIAN everywhere a campaign guardian is named
  /// (`BossEncounterArt.nameCardEyebrow`), never MINI-BOSS.
  static String get ribbonWord => L10n.strings.bossGuardianEyebrow;
  static String get name =>
      L10n.upper(L10n.strings.bossName(BossKind.neferhoo));
  static String get epithet => L10n.strings.boss_neferhoo_title;

  /// His own entrance line (his level's, in quotation marks), the card's
  /// when the flight has no level.
  static String get line {
    final l = L10n.strings;
    return l.bossQuotedLine(
      l.guardianLine(BossKind.neferhoo) ?? '',
    );
  }

  /// The victory card's words.
  static String get victoryTitle => L10n.strings.bossGuardianDown;
  static String get victoryLine => L10n.strings.bossNeferhooFound;

  /// The card's clock (boss age): it lands from [landAt], holds, and has
  /// left by [goneBy].
  static const landAt = 2.85, leaveAt = 4.0, goneBy = 4.5;

  /// The victory card shows from [victoryAt] (the shared victory's beat)
  /// until 3.8 s after the killing blow.
  static const victoryAt = 1.55;

  /// The card plate in design units (1 = a pixel at 360 high).
  static const cardW = 292.0, cardH = 102.0;

  /// The level a campaign flight against him is: its id for the ribbon.
  static String? get levelId {
    for (final level in Campaign.levels) {
      if (level.boss == BossKind.neferhoo) return level.id;
    }
    return null;
  }

  /// The ribbon's words: with the level's number in the campaign.
  static String ribbon({required bool campaign}) {
    final id = levelId;
    return campaign && id != null ? '$ribbonWord · $id' : ribbonWord;
  }

  /// Where the name card's plate sits on a screen of [size] when it has
  /// landed (left of centre, high, over the open sky).
  static Rect cardRect(Size size) {
    final u = size.height / 360;
    final cx = math.max(150 * u, size.width * .312);
    return Rect.fromCenter(center: Offset(cx, 94 * u), width: cardW * u, height: cardH * u);
  }

  /// How clear the bird is of [r] (0 behind it, 1 well away).
  static double _clearance(Offset bird, Rect r, double h) {
    final dx = math.max(0.0, math.max(r.left - bird.dx, bird.dx - r.right));
    final dy = math.max(0.0, math.max(r.top - bird.dy, bird.dy - r.bottom));
    return (math.sqrt(dx * dx + dy * dy) / (h * .06)).clamp(0.0, 1.0);
  }

  // ------------------------------------------------------------ name card --

  /// The arrival's entrance card. While he is arriving the card is his, so
  /// this returns true (the shared card must never appear) and false at any
  /// other time or for any other boss. [line] is the campaign's story quote
  /// (already in quotation marks); null outside the campaign.
  static bool nameCard(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    required double birdY,
    String? line,
  }) {
    if (!boss.isNeferhoo || boss.phase != BossPhase.arriving) return false;
    if (!boss.age.isFinite || !size.isFinite || !(size.width >= 1) || !(size.height >= 1)) return true;
    final age = boss.age;
    if (age < landAt || age >= goneBy) return true;
    final campaign = line != null && line.trim().isNotEmpty;
    paintCard(
      c,
      size,
      t: NeferhooStaging.ramp(age, landAt, landAt + .45),
      age: age - landAt,
      exit: NeferhooStaging.ramp(age, leaveAt, goneBy),
      ribbon: ribbon(campaign: campaign),
      line: campaign ? line.trim() : null,
      birdY: birdY.isFinite ? birdY : .5,
      reduced: m.reducedMotion,
    );
    return true;
  }

  /// The card at [t] 0..1 of its slide-in, [age] seconds since it started
  /// (the glint, the dust) and [exit] 0..1 of its leaving.
  static void paintCard(
    Canvas c,
    Size size, {
    double t = 1,
    double age = 9,
    double exit = 0,
    String? ribbon,
    String? line,
    double birdY = .5,
    bool reduced = false,
  }) {
    final h = size.height, u = h / 360;
    if (t <= 0 || exit >= 1) return;
    ribbon ??= ribbonWord;
    final rest = cardRect(size);
    final cx = rest.center.dx, cy = rest.center.dy;
    // It lands: slides in from the left and above, overshoots, settles.
    final land = reduced ? 1.0 : NeferhooStaging.outBack(t, 1.5);
    final ex = reduced ? 0.0 : NeferhooStaging.outCubic(exit);
    final slideX = -(1 - land) * 150 * u - ex * 140 * u;
    final drop = -(1 - land) * 26 * u;
    final tilt = (1 - land) * -.09 + ex * -.07;
    final fadeIn = NeferhooStaging.smooth(NeferhooStaging.ramp(t, 0, .35));
    final fadeOut = 1 - NeferhooStaging.smooth(NeferhooStaging.ramp(exit, .25, 1));
    final bird = Offset(FlightSimulation.birdX * h, birdY * h);
    final seen = .22 + .78 * _clearance(bird, rest.inflate(h * .02), h);
    final a = (fadeIn * fadeOut * seen).clamp(0.0, 1.0);
    if (a <= 0) return;
    c.save();
    c.translate(cx + slideX, cy + drop);
    c.rotate(tilt);
    final card = Rect.fromCenter(center: Offset.zero, width: cardW * u, height: cardH * u);
    final layered = a < .995;
    if (layered) {
      c.saveLayer(card.inflate(34 * u), Paint()..color = Color.fromRGBO(255, 255, 255, a));
    }
    final words = ribbon;
    c.drawPicture(
      NeferhooStaging.picture(
        ('card-plate', (u * 100).round(), words),
        (p) => _plate(p, u, cardW, cardH, ribbon: words),
      ),
    );
    // The name, with a gold-leaf shadow under the lapis ink.
    NeferhooStaging.text(
      c,
      name,
      Offset(1.2 * u, card.top + 23.8 * u),
      28 * u,
      NeferhooPalette.goldShade.withValues(alpha: .7),
      center: true,
      spacing: 1.6 * u,
      fit: (cardW - 56) * u,
    );
    NeferhooStaging.text(
      c,
      name,
      Offset(0, card.top + 22.4 * u),
      28 * u,
      NeferhooPalette.lapisDeep,
      center: true,
      spacing: 1.6 * u,
      outline: const Color(0xff0e1748),
      outlineWidth: .6 * u,
      fit: (cardW - 56) * u,
    );
    final ep = NeferhooStaging.text(
      c,
      epithet,
      Offset(0, card.top + 54 * u),
      10.4 * u,
      const Color(0xff8f2f2f),
      center: true,
      spacing: 1.5 * u,
      // (the diamonds either side stay on the papyrus)
      fit: (cardW - 64) * u,
    );
    _diamonds(c, Offset(0, card.top + 60.4 * u), ep.width, u);
    // The gold's glint: a bright slash crosses the rim once, after landing.
    final g = NeferhooStaging.ramp(age, .25, .9);
    if (!reduced && g > 0 && g < 1) {
      final gx = card.left + 44 * u + g * (card.width - 88 * u);
      final fade = math.sin(g * math.pi);
      c.drawLine(
        Offset(gx - 22 * u, card.top + 2.3 * u),
        Offset(gx, card.top + 2.3 * u),
        Paint()
          ..shader = NeferhooStaging.lin(Offset(gx - 22 * u, 0), Offset(gx, 0), const [Color(0x00fffbe8), NeferhooStaging.glint])
          ..strokeWidth = 2.2 * u
          ..strokeCap = StrokeCap.round
          ..color = Color.fromRGBO(255, 255, 255, fade),
      );
      NeferhooStaging.star(c, Offset(gx, card.top + 2.3 * u), 9 * u * fade, alpha: .95);
      NeferhooStaging.star(c, Offset(card.right - 44 * u - g * (card.width - 88 * u), card.bottom - 2.3 * u), 5 * u * fade, alpha: .8);
    }
    // The line, inked on the papyrus under the epithet just after the name
    // lands (the campaign's only).
    if (line != null) {
      final la = NeferhooStaging.smooth(NeferhooStaging.ramp(t, .55, 1)) *
          (1 - NeferhooStaging.smooth(NeferhooStaging.ramp(exit, 0, .5)));
      if (la > 0) {
        NeferhooStaging.text(
          c,
          line,
          Offset(0, card.top + 69 * u),
          10.2 * u,
          const Color(0xff4a2a2a).withValues(alpha: la),
          center: true,
          italic: true,
          weight: FontWeight.w800,
          nunito: true,
          maxWidth: (cardW - 70) * u,
        );
      }
    }
    if (layered) c.restore();
    c.restore();
    // Landing dust: a puff under the plate, once.
    final dk = NeferhooStaging.ramp(age, 0, .5);
    if (!reduced && dk > 0 && dk < 1 && exit == 0) {
      for (var k = 0; k < 7; k++) {
        final dir = k.isEven ? -1.0 : 1.0;
        final r = (2.2 + 1.6 * NeferhooStaging.hash(k + 5)) * u;
        final o = Offset(
          cx + dir * (30 + k * 18) * u * dk,
          rest.bottom - u - 8 * u * dk * (1 - dk * .3) - (2 * k % 3) * u,
        );
        c.drawCircle(o, r * (1 + dk), NeferhooStaging.fill(NeferhooStaging.sandLit, .5 * (1 - dk) * seen));
      }
    }
  }

  static void _diamonds(Canvas c, Offset at, double width, double u) {
    for (final sx in const [-1.0, 1.0]) {
      final d = Offset(at.dx + sx * (width / 2 + 8 * u), at.dy);
      final p = NeferhooStaging.diamond(d, 3 * u);
      c.drawPath(
        p,
        NeferhooStaging.grad(
          NeferhooStaging.lin(d - Offset(3 * u, 3 * u), d + Offset(3 * u, 3 * u), const [
            NeferhooPalette.goldHi,
            NeferhooPalette.gold,
            NeferhooPalette.goldShade,
          ]),
        ),
      );
      c.drawPath(p, NeferhooStaging.line(NeferhooPalette.ink, .6 * u));
    }
  }

  // ---------------------------------------------------------- victory --

  /// The victory card, [death] seconds after the killing blow: it thunks
  /// down from a little larger at [victoryAt], a glint crosses its rim, and
  /// it fades 3.3 to 3.8 s. Under Reduced Motion it only fades.
  static void victory(Canvas c, Size size, BossMotion m) {
    final d = m.death;
    if (!d.isFinite || d < victoryAt || !size.isFinite || !(size.height >= 1)) return;
    final show = NeferhooStaging.smooth(NeferhooStaging.ramp(d, victoryAt, 1.9)) *
        (1 - NeferhooStaging.smooth(NeferhooStaging.ramp(d, 3.3, 3.8)));
    paintVictory(c, size, k: show, age: d - victoryAt, reduced: m.reducedMotion);
  }

  /// The victory card at visibility [k], [age] seconds after it appeared.
  static void paintVictory(Canvas c, Size size, {double k = 1, double age = 9, bool reduced = false}) {
    if (k <= 0) return;
    final u = size.height / 360;
    const w = 282.0, hgt = 80.0;
    final centre = Offset(size.width / 2 - 22 * u, 92 * u);
    final rect = Rect.fromCenter(center: Offset.zero, width: w * u, height: hgt * u);
    final land = reduced ? 1.0 : NeferhooStaging.outBack(NeferhooStaging.ramp(age, 0, .22), 2.2);
    final sc = 1 + (1 - land) * .22;
    c.save();
    c.translate(centre.dx, centre.dy);
    c.scale(sc);
    final layered = k < .995;
    if (layered) {
      c.saveLayer(rect.inflate(30 * u), Paint()..color = Color.fromRGBO(255, 255, 255, k.clamp(0.0, 1.0)));
    }
    c.drawPicture(
      NeferhooStaging.picture(
        ('victory-plate', (u * 100).round()),
        (p) => _plate(p, u, w, hgt, ribbon: null),
      ),
    );
    NeferhooStaging.text(
      c,
      victoryTitle,
      Offset(1.2 * u, rect.top + 18.9 * u),
      25 * u,
      NeferhooPalette.goldShade.withValues(alpha: .7),
      center: true,
      spacing: 1.2 * u,
      fit: (w - 36) * u,
    );
    NeferhooStaging.text(
      c,
      victoryTitle,
      Offset(0, rect.top + 17.5 * u),
      25 * u,
      NeferhooPalette.lapisDeep,
      center: true,
      spacing: 1.2 * u,
      outline: const Color(0xff0e1748),
      outlineWidth: .6 * u,
      fit: (w - 36) * u,
    );
    final sub = NeferhooStaging.text(
      c,
      victoryLine,
      Offset(0, rect.top + 47 * u),
      10.4 * u,
      const Color(0xff8f2f2f),
      center: true,
      spacing: 1.6 * u,
      fit: (w - 64) * u,
    );
    _diamonds(c, Offset(0, rect.top + 53.6 * u), sub.width, u);
    final g = NeferhooStaging.ramp(age, .25, .85);
    if (!reduced && g > 0 && g < 1) {
      final gx = rect.left + 50 * u + g * (rect.width - 100 * u);
      NeferhooStaging.star(c, Offset(gx, rect.top + 2.3 * u), 9 * u * math.sin(g * math.pi), alpha: .95);
    }
    if (layered) c.restore();
    c.restore();
  }

  // ------------------------------------------------------------ the plate --

  /// The hieroglyph border (ankh, wedjat eye, water, feather in turn) as one
  /// path along a straight run.
  static Path _border(double u, double left, double right, double y, double step) {
    final p = Path();
    var k = 0;
    for (var x = left; x <= right; x += step, k++) {
      switch (k % 4) {
        case 0: // ankh
          p
            ..addOval(Rect.fromCenter(center: Offset(x, y - 1.7 * u), width: 2.6 * u, height: 3.2 * u))
            ..moveTo(x, y - .1 * u)
            ..lineTo(x, y + 3.2 * u)
            ..moveTo(x - 1.9 * u, y + .7 * u)
            ..lineTo(x + 1.9 * u, y + .7 * u);
        case 1: // wedjat eye
          p
            ..moveTo(x - 2.6 * u, y)
            ..quadraticBezierTo(x, y - 2.8 * u, x + 2.6 * u, y)
            ..quadraticBezierTo(x, y + 1.8 * u, x - 2.6 * u, y)
            ..addOval(Rect.fromCircle(center: Offset(x, y - .2 * u), radius: .7 * u))
            ..moveTo(x + .5 * u, y + 1.2 * u)
            ..quadraticBezierTo(x + 1.4 * u, y + 3.2 * u, x + 3 * u, y + 3.1 * u);
        case 2: // water
          p
            ..moveTo(x - 3 * u, y - .6 * u)
            ..lineTo(x - 1.5 * u, y - 2 * u)
            ..lineTo(x, y - .6 * u)
            ..lineTo(x + 1.5 * u, y - 2 * u)
            ..lineTo(x + 3 * u, y - .6 * u)
            ..moveTo(x - 3 * u, y + 1.8 * u)
            ..lineTo(x - 1.5 * u, y + .4 * u)
            ..lineTo(x, y + 1.8 * u)
            ..lineTo(x + 1.5 * u, y + .4 * u)
            ..lineTo(x + 3 * u, y + 1.8 * u);
        default: // feather (Maat)
          p
            ..moveTo(x, y + 3.4 * u)
            ..quadraticBezierTo(x - 2.6 * u, y, x, y - 3.4 * u)
            ..quadraticBezierTo(x + 2.6 * u, y, x, y + 3.4 * u)
            ..moveTo(x, y + 3.4 * u)
            ..lineTo(x, y - 3.4 * u);
      }
    }
    return p;
  }

  /// Papyrus fibre: long horizontal strands and two vertical sheet seams.
  static Path _fibre(Rect r, double u) {
    final p = Path();
    for (var k = 0; k < 11; k++) {
      final y = r.top + r.height * (k + .5) / 11;
      final x0 = r.left + r.width * (.04 + .1 * NeferhooStaging.hash(k * 3 + 1));
      final x1 = r.right - r.width * (.04 + .1 * NeferhooStaging.hash(k * 3 + 2));
      p
        ..moveTo(x0, y)
        ..quadraticBezierTo(
          (x0 + x1) / 2,
          y + (NeferhooStaging.hash(k * 7 + 3) - .5) * 1.6 * u,
          x1,
          y + (NeferhooStaging.hash(k * 7 + 4) - .5) * .6 * u,
        );
    }
    for (final fx in const [.31, .69]) {
      p
        ..moveTo(r.left + r.width * fx, r.top + 2 * u)
        ..lineTo(r.left + r.width * fx + .8 * u, r.bottom - 2 * u);
    }
    return p;
  }

  /// The plate about the origin, [w] x [hgt] design units: a soft shadow, the
  /// gold-leaf rim with its craquelure, the lapis band with veining and the
  /// glyph border, the papyrus panel; then the [ribbon] (its words) with the
  /// medallion and the seal, or (the victory card, [ribbon] null) the
  /// medallion on the left end and the seal on the right.
  static void _plate(Canvas c, double u, double w, double hgt, {required String? ribbon}) {
    final ink = NeferhooPalette.ink;
    final rect = Rect.fromCenter(center: Offset.zero, width: w * u, height: hgt * u);
    final plate = RRect.fromRectAndRadius(rect, Radius.circular(hgt / 2 * u));
    for (var k = 3; k >= 1; k--) {
      c.drawRRect(plate.inflate(k * 1.4 * u).shift(Offset(0, 3.4 * u)), NeferhooStaging.fill(NeferhooStaging.night, .09));
    }
    c.drawRRect(
      plate,
      Paint()
        ..shader = NeferhooStaging.lin(rect.topLeft, rect.bottomRight, const [
          NeferhooPalette.goldHi,
          NeferhooPalette.goldLit,
          NeferhooPalette.gold,
          NeferhooPalette.goldShade,
          NeferhooPalette.gold,
          NeferhooPalette.goldLit,
        ], const [0, .16, .4, .7, .88, 1]),
    );
    c.drawRRect(plate, NeferhooStaging.line(ink, 1.3 * u, .95));
    // Gold-leaf craquelure: a few hairline cracks and flakes.
    final leaf = Path();
    for (var k = 0; k < 14; k++) {
      final a = NeferhooStaging.hash(k + 40) * 2 * math.pi;
      final x = math.cos(a) * (hgt / 2 - 2.4) * u +
          (k.isEven ? 1 : -1) * (w / 2 - hgt / 2) * u * (NeferhooStaging.hash(k + 9) * 2 - 1);
      final y = math.sin(a) * (hgt / 2 - 2.4) * u;
      leaf
        ..moveTo(x, y)
        ..relativeLineTo((NeferhooStaging.hash(k + 3) * 2.2 - 1.1) * u, (NeferhooStaging.hash(k + 5) * 2.2 - 1.1) * u);
    }
    c.drawPath(leaf, NeferhooStaging.line(NeferhooPalette.goldDeep, .5 * u, .6));
    // The lapis band, its veining and pyrite specks.
    final band = plate.deflate(4.4 * u);
    c.drawRRect(
      band,
      Paint()
        ..shader = NeferhooStaging.lin(rect.topCenter, rect.bottomCenter, const [
          Color(0xff4b73ef),
          NeferhooPalette.lapis,
          NeferhooPalette.lapisShade,
          NeferhooPalette.lapisDeep,
        ], const [0, .3, .7, 1]),
    );
    c.drawRRect(band, NeferhooStaging.line(ink, .9 * u, .8));
    final fleck = Path(), pyrite = Path();
    for (var k = 0; k < 26; k++) {
      final x = rect.left + 24 * u + NeferhooStaging.hash(k + 70) * (rect.width - 48 * u);
      final y = rect.top + 6 * u + NeferhooStaging.hash(k + 99) * (hgt - 12) * u;
      (k % 3 == 0 ? pyrite : fleck)
        ..moveTo(x, y)
        ..relativeLineTo(1.8 * u * NeferhooStaging.hash(k + 11), -.6 * u);
    }
    c.drawPath(fleck, NeferhooStaging.line(NeferhooPalette.lapisLit, .6 * u, .35));
    c.drawPath(pyrite, NeferhooStaging.line(NeferhooPalette.goldLit, .55 * u, .7));
    // The glyph border, gold inlay, along the top and bottom runs.
    final gl = rect.left + (hgt / 2 + 4) * u, gr = rect.right - (hgt / 2 + 4) * u;
    final yTop = rect.top + 9.7 * u, yBot = rect.bottom - 9.7 * u;
    for (final p in [_border(u, gl, gr, yTop, 15 * u), _border(u, gl + 7.5 * u, gr, yBot, 15 * u)]) {
      c.drawPath(p.shift(Offset(0, .7 * u)), NeferhooStaging.line(NeferhooPalette.lapisDeep, 1.3 * u, .8));
      c.drawPath(p, NeferhooStaging.line(NeferhooPalette.goldLit, .95 * u, .95));
    }
    // An inner gold hairline, then the papyrus panel.
    final inner = band.deflate(10.6 * u);
    c.drawRRect(inner.inflate(1.1 * u), NeferhooStaging.line(NeferhooPalette.goldLit, 1.5 * u));
    c.drawRRect(inner.inflate(1.1 * u), NeferhooStaging.line(NeferhooPalette.goldDeep, .5 * u, .8));
    final ir = inner.outerRect;
    c.drawRRect(
      inner,
      Paint()..shader = NeferhooStaging.lin(ir.topCenter, ir.bottomCenter, const [NeferhooStaging.paperHi, NeferhooStaging.paper, NeferhooStaging.paperShade]),
    );
    c.save();
    c.clipRRect(inner);
    // Stained edges, warm near the lamp; fibre; a faint water-stain ring.
    c.drawRRect(
      inner,
      Paint()
        ..shader = NeferhooStaging.rad(ir.center - Offset(18 * u, 4 * u), ir.width * .58, const [
          Color(0x00a97a3c),
          Color(0x00a97a3c),
          Color(0x55a97a3c),
        ], const [0, .62, 1]),
    );
    final fibre = _fibre(ir, u);
    c.drawPath(fibre, NeferhooStaging.line(NeferhooStaging.paperEdge, .55 * u, .38));
    c.drawPath(fibre.shift(Offset(0, .8 * u)), NeferhooStaging.line(NeferhooStaging.paperHi, .5 * u, .5));
    c.drawCircle(ir.center + Offset(70 * u, 6 * u), 22 * u, NeferhooStaging.line(NeferhooStaging.paperStain, .7 * u, .12));
    c.restore();
    c.drawRRect(inner, NeferhooStaging.line(NeferhooStaging.paperEdge, .9 * u, .9));
    c.drawRRect(inner.deflate(1.6 * u), NeferhooStaging.line(NeferhooPalette.goldDeep, .4 * u, .45));
    // A specular line along the gold rim, a lapis shine.
    c.drawArc(rect.deflate(1.4 * u), math.pi * 1.1, math.pi * .55, false, NeferhooStaging.line(const Color(0xffffffff), 1.1 * u, .55));
    c.drawArc(band.outerRect.deflate(3 * u), math.pi * 1.08, math.pi * .4, false, NeferhooStaging.line(const Color(0xffffffff), .8 * u, .22));
    if (ribbon != null) {
      _ribbon(c, u, rect, ribbon);
      _seal(c, Offset(rect.left + 34 * u, rect.bottom - 4 * u), u);
    } else {
      NeferhooHudArt.medallion(c, Offset(rect.left + 6 * u, 0), 15 * u);
      _seal(c, Offset(rect.right - 22 * u, rect.bottom - 3 * u), u);
    }
  }

  /// The GUARDIAN ribbon over the plate's top edge, swallow-tailed, lapis
  /// with gold hairlines, the medallion pinned on its left end; as wide as
  /// its [words] need.
  static void _ribbon(Canvas c, double u, Rect rect, String words) {
    final size = 10.5 * u, spacing = (words == ribbonWord ? 3 : 2) * u;
    final fonts = L10n.fonts;
    final probe = TextPainter(
      text: TextSpan(
        text: words,
        style: TextStyle(fontFamily: fonts.heading, fontFamilyFallback: fonts.headingFallback, fontSize: size, fontWeight: FontWeight.w600, letterSpacing: spacing),
      ),
      textDirection: L10n.textDirection,
    )..layout();
    final half = math.max(66.0 * u, probe.width / 2 + 24 * u);
    final cx = -6 * u, top = rect.top - 9 * u;
    final l = cx - half, r = cx + half, t = top, b = top + 17 * u;
    final rib = Path()
      ..moveTo(l + 5 * u, t)
      ..lineTo(r + 5 * u, t)
      ..lineTo(r - 1 * u, (t + b) / 2)
      ..lineTo(r + 5 * u, b)
      ..lineTo(l + 5 * u, b)
      ..close();
    c.drawPath(rib.shift(Offset(0, 1.6 * u)), NeferhooStaging.fill(NeferhooStaging.night, .35));
    c.drawPath(
      rib,
      Paint()..shader = NeferhooStaging.lin(Offset(0, t), Offset(0, b), const [Color(0xff7597ff), NeferhooPalette.lapis, NeferhooPalette.lapisShade]),
    );
    c.drawPath(rib, NeferhooStaging.line(NeferhooPalette.ink, 1.2 * u, .95));
    c.drawPath(
      Path()
        ..moveTo(l + 9 * u, t + 2.2 * u)
        ..lineTo(r - 1 * u, t + 2.2 * u)
        ..moveTo(l + 9 * u, b - 2.2 * u)
        ..lineTo(r - 1 * u, b - 2.2 * u),
      NeferhooStaging.line(NeferhooPalette.goldLit, .7 * u, .9),
    );
    final style = TextStyle(fontFamily: fonts.heading, fontFamilyFallback: fonts.headingFallback, fontSize: size, fontWeight: FontWeight.w600, letterSpacing: spacing);
    final edge = TextPainter(
      text: TextSpan(
        text: words,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * u
            ..strokeJoin = StrokeJoin.round
            ..color = NeferhooPalette.lapisDeep,
        ),
      ),
      textDirection: L10n.textDirection,
    )..layout();
    final word = TextPainter(
      text: TextSpan(text: words, style: style.copyWith(color: NeferhooStaging.creamText)),
      textDirection: L10n.textDirection,
    )..layout();
    final at = Offset(cx + 6 * u - word.width / 2, t + 2.6 * u);
    edge.paint(c, at);
    word.paint(c, at);
    NeferhooHudArt.medallion(c, Offset(l - 3 * u, (t + b) / 2 + 1 * u), 14.5 * u);
  }

  /// The Pharaoh's Post seal: carnelian wax with a scalloped edge, a gold
  /// winged envelope, two lapis ribbon tails.
  static void _seal(Canvas c, Offset o, double u) {
    final r = 11.5 * u;
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(.16);
    for (final s in const [-1.0, 1.0]) {
      final tail = Path()
        ..moveTo(s * 2 * u, 4 * u)
        ..lineTo(s * 8 * u, 16 * u)
        ..lineTo(s * 4.4 * u, 14.2 * u)
        ..lineTo(s * 2 * u, 17.4 * u)
        ..lineTo(s * -1 * u, 5 * u)
        ..close();
      c.drawPath(tail, Paint()..shader = NeferhooStaging.lin(Offset.zero, Offset(0, 17 * u), const [Color(0xff7597ff), NeferhooPalette.lapisShade]));
      c.drawPath(tail, NeferhooStaging.line(NeferhooPalette.ink, .9 * u, .9));
    }
    final wax = Path();
    for (var k = 0; k < 16; k++) {
      final a = k * math.pi / 8;
      final p = Offset(math.cos(a), math.sin(a)) * r * (k.isEven ? 1.0 : .9);
      if (k == 0) {
        wax.moveTo(p.dx, p.dy);
      } else {
        wax.lineTo(p.dx, p.dy);
      }
    }
    wax.close();
    c.drawPath(wax.shift(Offset(0, 1.2 * u)), NeferhooStaging.fill(NeferhooPalette.ink, .35));
    c.drawPath(
      wax,
      Paint()
        ..shader = NeferhooStaging.rad(Offset(-r * .3, -r * .35), r * 1.5, const [
          NeferhooPalette.carnLit,
          NeferhooPalette.carn,
          NeferhooPalette.carnShade,
          NeferhooPalette.carnDeep,
        ], const [0, .35, .75, 1]),
    );
    c.drawPath(wax, NeferhooStaging.line(NeferhooPalette.ink, 1.1 * u, .95));
    c.drawCircle(Offset.zero, r * .66, NeferhooStaging.line(NeferhooPalette.carnDeep, u, .8));
    c.drawCircle(Offset.zero, r * .66, NeferhooStaging.line(NeferhooPalette.carnLit, .5 * u, .5));
    final env = Rect.fromCenter(center: Offset(0, r * .08), width: r * .62, height: r * .42);
    c.drawRect(env, Paint()..shader = NeferhooStaging.lin(env.topLeft, env.bottomRight, const [NeferhooPalette.goldHi, NeferhooPalette.gold, NeferhooPalette.goldShade]));
    c.drawPath(
      Path()
        ..moveTo(env.left, env.top)
        ..lineTo(env.center.dx, env.center.dy)
        ..lineTo(env.right, env.top),
      NeferhooStaging.line(NeferhooPalette.goldDeep, .55 * u),
    );
    c.drawRect(env, NeferhooStaging.line(NeferhooPalette.carnDeep, .6 * u));
    for (final s in const [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(s * r * .3, r * .02)
          ..quadraticBezierTo(s * r * .62, -r * .34, s * r * .86, -r * .06)
          ..quadraticBezierTo(s * r * .6, -r * .1, s * r * .3, r * .12),
        NeferhooStaging.fill(NeferhooPalette.goldLit),
      );
    }
    c.drawCircle(Offset(-r * .34, -r * .38), r * .1, NeferhooStaging.fill(const Color(0xffffffff), .6));
    c.restore();
  }
}
