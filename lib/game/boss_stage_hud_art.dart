import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/sky_boss.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'dragon_kit.dart';
import 'gargoyle_kit.dart';
import 'king_coo_kit.dart';
import 'neferhoo_hud_art.dart';
import 'pirate_hud_art.dart';

/// The boss plate's stages (rules version 44): a campaign boss's bar is cut
/// in three by two marks, the fury mark at a third (each boss keeps its own:
/// the ember notch, the doubloon, the fang, the whistle, the spool) and, at
/// two thirds, a stage gem in the plate's own metal. The gem sits on the
/// gauge's upper edge with a slot through the track until the boss loses its
/// first third; then it snaps in two and stays broken, and a **STRONGER!**
/// tag drops from it for as long as the FURY tag shows.
///
/// `BossHealthBarArt` keeps the layout and decides what shows; these are the
/// brushstrokes. Everything is a pure function of the boss clock, so paused,
/// replayed and seeked frames repeat, and Reduced Motion keeps it still.
abstract final class BossStageHudArt {
  /// The STRONGER! card hangs this long after the boss grows stronger, as
  /// long as the rules' stage hint names what the full fight brings,
  /// fading over the last 0.4 s. The boss's own tags (HEART x2, PUFFED x2,
  /// the Gargoyle's) push it aside the moment they come (see
  /// `BossHealthBarArt`).
  static const tagSeconds = SkyBoss.stageHintSeconds, _tagFade = .4;

  /// The bar's flare and the gem's snap after the boss grows stronger.
  static const flareSeconds = .6, snapSeconds = .4;

  static const _night = Color(0xff171c39), _cream = Color(0xfffff2c9);

  /// The metal of a boss's plate as (ink, deep, main, lit), and the face
  /// of its tags.
  static ({Color ink, Color deep, Color main, Color lit, Color face}) metal(
    BossKind kind,
  ) => switch (kind) {
    BossKind.pirate => (
      ink: PirateHudArt.ink,
      deep: PirateHudArt.goldDeep,
      main: PirateHudArt.gold,
      lit: PirateHudArt.goldLight,
      face: const Color(0xff3e2619),
    ),
    BossKind.dragon => (
      ink: DragonPalette.ink,
      deep: DragonPalette.goldDeep,
      main: DragonPalette.gold,
      lit: DragonPalette.goldLit,
      face: const Color(0xff2c1a33),
    ),
    BossKind.kingCoo => (
      ink: KingCooPalette.ink,
      deep: KingCooPalette.brassDeep,
      main: KingCooPalette.brass,
      lit: KingCooPalette.brassLit,
      face: KingCooPalette.navy,
    ),
    BossKind.searchlightGargoyle => (
      ink: GargoylePalette.ink,
      deep: GargoylePalette.brassDeep,
      main: GargoylePalette.brass,
      lit: GargoylePalette.brassLit,
      face: const Color(0xff1f2745),
    ),
    BossKind.neferhoo => NeferhooHudArt.stageMetal,
    BossKind.baronBat || BossKind.spitterBeetle || BossKind.duskMoth => (
      ink: const Color(0xff0f1330),
      deep: const Color(0xffd99a2e),
      main: const Color(0xffffd878),
      lit: _cream,
      face: _night,
    ),
  };

  /// Seconds since [boss] last grew stronger into its full fight (stage 1),
  /// or infinity: fury keeps its own onset.
  static double strongerAge(SkyBoss boss) {
    if (!boss.staged || boss.stageReached != 1) return double.infinity;
    final since = boss.age - boss.stageUpAt;
    return since.isFinite && since >= 0 ? since : double.infinity;
  }

  /// 1 to 0 over the bar's flare as the boss grows stronger (stage 1 only);
  /// none under Reduced Motion.
  static double flare(SkyBoss boss, {required bool reduced}) {
    final since = strongerAge(boss);
    return reduced || since >= flareSeconds ? 0 : 1 - since / flareSeconds;
  }

  /// The stage gem at [x] on [bar]: whole and lit while the boss is above
  /// the mark (a glint crosses it now and then, at [time] on the boss's
  /// clock), snapped in two once it has [passed] it. [since] is how long
  /// ago it snapped (the halves part and a few sparks fly for
  /// [snapSeconds]; Reduced Motion shows the broken gem at once, and no
  /// glint).
  static void gem(
    Canvas c,
    Rect bar,
    double x,
    double u,
    BossKind kind, {
    required bool passed,
    double since = double.infinity,
    double time = 0,
    bool reduced = false,
  }) {
    if (!bar.isFinite || !x.isFinite || !u.isFinite) return;
    final m = metal(kind);
    final snap = passed && !reduced && since >= 0 && since < snapSeconds
        ? since / snapSeconds
        : 1.0;
    // The slot through the track: ink, with a metal hairline while whole.
    final slot = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, bar.center.dy),
        width: 2.1 * u,
        height: bar.height + 1.6 * u,
      ),
      Radius.circular(1.05 * u),
    );
    c.drawRRect(slot, _fill(m.ink));
    if (!passed || snap < 1) {
      c.drawLine(
        Offset(x, bar.top + 2.4 * u),
        Offset(x, bar.bottom - .6 * u),
        _line(passed ? m.lit : m.main, .8 * u, passed ? 1 - snap : 1),
      );
    }
    final at = Offset(x, bar.top - .9 * u);
    final w = 3.0 * u, h = 3.7 * u;
    if (!passed) {
      final diamond = Path()
        ..moveTo(at.dx, at.dy - h)
        ..lineTo(at.dx + w, at.dy)
        ..lineTo(at.dx, at.dy + h)
        ..lineTo(at.dx - w, at.dy)
        ..close();
      c.drawPath(diamond, _line(m.ink, 1.5 * u)..strokeJoin = StrokeJoin.round);
      c.drawPath(diamond, _fill(m.deep));
      // The lit upper facets and a glint.
      c.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - h)
          ..lineTo(at.dx + w, at.dy)
          ..lineTo(at.dx, at.dy + h * .1)
          ..lineTo(at.dx - w, at.dy)
          ..close(),
        _fill(m.main),
      );
      c.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - h * .82)
          ..lineTo(at.dx - w * .62, at.dy - h * .06)
          ..lineTo(at.dx - w * .2, at.dy - h * .06)
          ..close(),
        _fill(m.lit, .95),
      );
      // Every few seconds a glint: the warm-up is calm, not switched off.
      final k = time.isFinite && !reduced ? (time % 3.4) / .5 : 1.0;
      if (k >= 0 && k < 1) {
        final a = math.sin(k * math.pi);
        final at2 = at + Offset(-w * .3, -h * .38);
        final r = (1.2 + 1.6 * a) * u;
        c.drawPath(
          Path()
            ..moveTo(at2.dx, at2.dy - r)
            ..lineTo(at2.dx + r * .22, at2.dy - r * .22)
            ..lineTo(at2.dx + r, at2.dy)
            ..lineTo(at2.dx + r * .22, at2.dy + r * .22)
            ..lineTo(at2.dx, at2.dy + r)
            ..lineTo(at2.dx - r * .22, at2.dy + r * .22)
            ..lineTo(at2.dx - r, at2.dy)
            ..lineTo(at2.dx - r * .22, at2.dy - r * .22)
            ..close(),
          _fill(const Color(0xffffffff), a),
        );
      }
      return;
    }
    // Snapped: two dull halves either side of a jagged split, tipped apart.
    final part = BossMotion.ease(snap);
    for (final side in const [-1.0, 1.0]) {
      final half = Path()
        ..moveTo(at.dx + side * .15 * u, at.dy - h)
        ..lineTo(at.dx + side * w, at.dy)
        ..lineTo(at.dx + side * .15 * u, at.dy + h)
        ..lineTo(at.dx + side * .75 * u, at.dy + h * .3)
        ..lineTo(at.dx - side * .25 * u, at.dy - h * .1)
        ..lineTo(at.dx + side * .6 * u, at.dy - h * .5)
        ..close();
      c.save();
      c.translate(at.dx, at.dy + h);
      c.rotate(side * .22 * part);
      c.translate(-at.dx + side * .7 * u * part, -at.dy - h + .5 * u * part);
      c.drawPath(half, _line(m.ink, 1.3 * u)..strokeJoin = StrokeJoin.round);
      c.drawPath(
        half,
        _fill(Color.lerp(m.lit, Color.lerp(m.deep, m.ink, .12)!, part)!),
      );
      c.restore();
    }
    if (snap < 1) {
      // A few chips of light fly off the break.
      final fade = 1 - snap;
      final reach = (2.5 + 7 * math.sqrt(snap)) * u;
      final rays = Path();
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + (i - 2.5) * .55;
        final d = Offset(math.cos(a), math.sin(a));
        rays
          ..moveTo(at.dx + d.dx * reach * .55, at.dy + d.dy * reach * .55)
          ..lineTo(at.dx + d.dx * reach, at.dy + d.dy * reach);
      }
      c.drawPath(rays, _line(m.lit, 1.1 * u * fade + .3 * u, fade));
    }
  }

  /// A short sweep of light along the health that is left, as the boss
  /// grows stronger: from the bar's left end to [right] in the flare's
  /// first half. Never under Reduced Motion.
  static void sweep(
    Canvas c,
    Rect bar,
    double right,
    double u,
    SkyBoss boss, {
    required bool reduced,
  }) {
    if (reduced || !bar.isFinite || !right.isFinite) return;
    final t = strongerAge(boss) / (flareSeconds * .75);
    if (t >= 1 || right <= bar.left) return;
    final x = bar.left + (right - bar.left + 8 * u) * BossMotion.ease(t);
    final band = Rect.fromLTRB(
      math.max(bar.left, x - 9 * u),
      bar.top,
      math.min(right, x),
      bar.bottom,
    );
    if (band.width <= 0) return;
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _cream.withValues(alpha: 0),
            _cream.withValues(alpha: .55 * math.sin(t * math.pi)),
          ],
        ).createShader(Rect.fromLTRB(x - 9 * u, bar.top, x, bar.bottom)),
    );
  }

  static final Map<Object, TextPainter> _texts = {};

  static TextPainter _text(
    String value,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w700,
    double spacing = .08,
    double maxWidth = double.infinity,
  }) => _texts[(value, size, color, weight, maxWidth)] ??= TextPainter(
    text: TextSpan(
      text: value,
      style: heading(
        size,
        color: color,
        weight: weight,
      ).copyWith(letterSpacing: size * spacing),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);

  /// What the full fight brings, from the rules' stage hint ("STRONGER ·
  /// Triple shots, and his bats join in!"): the words after the dot, or
  /// null.
  static String? hintOf(SkyBoss boss) {
    final hint = boss.stageHint;
    if (hint == null) return null;
    final dot = hint.indexOf('·');
    final words = (dot < 0 ? hint : hint.substring(dot + 1)).trim();
    return words.isEmpty ? null : words;
  }

  /// Where the flight HUD's clock begins on a screen of [size]: the play
  /// screen lays its readouts out on a 1000 x 450 scene fitted inside the
  /// screen, and the clock's plate starts at x 778 (the pause button is
  /// right of it, the hearts at the far left).
  static double hudRight(Size size) {
    final scale = math.min(size.width / 1000, size.height / 450);
    return (size.width - 1000 * scale) / 2 + 778 * scale;
  }

  /// The STRONGER! card: a small plate in the boss's own metal with a
  /// double chevron and **STRONGER!**, and under it, in smaller type, what
  /// the full fight brings ([hintOf], on one line or two). It slides out
  /// from behind the strip under the broken gem at [x] (inside [room], a
  /// span of x) and hangs from the strip's lower edge on two links,
  /// [hang] further down when something of the plate's own falls there
  /// (King Coo's crumbs). It drops with a little bounce, hangs for
  /// [tagSeconds] after the boss grows stronger, then fades; [alpha] fades
  /// it sooner when the boss's own tags need the place. Still (no drop)
  /// under Reduced Motion. With [left] it hangs from [room]'s left end
  /// instead (the Searchlight Gargoyle's head rises under the gauge's right
  /// half). Returns the card's rect (for layout checks), or null.
  static Rect? strongerTag(
    Canvas c,
    Rect strip,
    double x,
    double u,
    SkyBoss boss, {
    required bool reduced,
    required ({double left, double right}) room,
    bool left = false,
    double hang = 0,
    double alpha = 1,
  }) {
    final since = strongerAge(boss);
    if (since >= tagSeconds || !strip.isFinite || !x.isFinite) return null;
    final fade =
        ((tagSeconds - since) / _tagFade).clamp(0.0, 1.0) *
        alpha.clamp(0.0, 1.0);
    if (fade <= 0) return null;
    final m = metal(boss.kind);
    final drop = reduced ? 1.0 : BossMotion.ease((since / .22).clamp(0.0, 1.0));
    final bounce = reduced || since < .22 || since > .5
        ? 0.0
        : math.sin((since - .22) / .28 * math.pi) * 1.6 * u;
    // (The fade is quantised so the few faded words are laid out once.)
    final a = (fade * 12).round() / 12;
    final pad = 5 * u, icon = 7.4 * u, gap = 2.8 * u;
    final title = _text('STRONGER!', 10 * u, _cream.withValues(alpha: a));
    final words = hintOf(boss);
    final hint = words == null
        ? null
        : _text(
            words,
            8.4 * u,
            _cream.withValues(alpha: .9 * a),
            weight: FontWeight.w600,
            spacing: .02,
            maxWidth: math.max(
              40 * u,
              math.min(190 * u, room.right - room.left - 2 * pad),
            ),
          );
    final titleW = icon + gap + title.width;
    final titleH = 14 * u;
    final w = math.max(titleW, hint?.width ?? 0) + 2 * pad;
    final h = titleH + (hint == null ? 0 : hint.height + 3.4 * u);
    final cx = left
        ? room.left + 3 * u + w / 2
        : x
              .clamp(
                math.min(room.left + w / 2, room.right - w / 2),
                room.right - w / 2,
              )
              .toDouble();
    final top = strip.bottom - 1.4 * u + hang;
    c.save();
    // It slides out from behind the strip.
    c.clipRect(
      Rect.fromLTRB(cx - w, strip.bottom - 2.8 * u, cx + w, top + h * 3),
    );
    c.translate(cx, top - (h + 1.4 * u + hang) * (1 - drop) + bounce);
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w / 2, 0, w, h),
      Radius.circular(3 * u),
    );
    // Two links tie it to the plate.
    for (final s in const [-1.0, 1.0]) {
      c.drawRect(
        Rect.fromLTWH(
          s * (w / 2 - 4 * u) - .8 * u,
          -1.4 * u - hang,
          1.6 * u,
          2.4 * u + hang,
        ),
        _fill(m.deep, fade),
      );
    }
    c.drawRRect(box.shift(Offset(0, 1.2 * u)), _fill(m.ink, .3 * fade));
    c.drawRRect(box.inflate(1 * u), _fill(m.ink, fade));
    c.drawRRect(box, _fill(m.face, fade));
    c.drawRRect(box.deflate(.6 * u), _line(m.main, 1.1 * u, fade));
    // The double chevron (grown stronger) and the word, centred.
    final ix = -titleW / 2 + icon / 2, iy = titleH / 2;
    final chevrons = Path();
    for (final dy in const [-1.0, 1.6]) {
      chevrons
        ..moveTo(ix - icon * .42, iy + dy * u + icon * .2)
        ..lineTo(ix, iy + dy * u - icon * .2)
        ..lineTo(ix + icon * .42, iy + dy * u + icon * .2);
    }
    c.drawPath(
      chevrons,
      _line(m.ink, 2.6 * u, fade)..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      chevrons,
      _line(m.main, 1.4 * u, fade)..strokeJoin = StrokeJoin.round,
    );
    title.paint(
      c,
      Offset(-titleW / 2 + icon + gap, (titleH - title.height) / 2 + .3 * u),
    );
    if (hint != null) {
      // A hairline of the metal, then what the full fight brings.
      c.drawLine(
        Offset(-w / 2 + pad, titleH),
        Offset(w / 2 - pad, titleH),
        _line(m.main, .7 * u, .45 * fade),
      );
      hint.paint(c, Offset(-hint.width / 2, titleH + 1.6 * u));
    }
    c.restore();
    return Rect.fromLTWH(
      cx - w / 2 - u,
      top - 1.4 * u - hang,
      w + 2 * u,
      h + 2.4 * u + hang,
    );
  }

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()..color = color.withValues(alpha: color.a * alpha.clamp(0, 1));

  static Paint _line(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
}
