import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'boss_health_bar_art.dart';
import 'boss_motion.dart';
import 'boss_vanguard_art.dart';
import 'king_coo_kit.dart';

/// King Coo's stragglers (rules version 45): every vanguard pigeon that got
/// away is owed, and comes back in his fight until it is shot down.
///
/// One sign ties it together, the "comes back" arrow: a gold arrow curling
/// round a pigeon. It sits on the **owed tag** that hangs under the left end
/// of his plate while any are owed (the arrowed pigeon and "×N"), it is the
/// badge a returning straggler wears over its head, and it marks the
/// escaped pips of his vanguard's plate. The tag pops when one is caught,
/// its arrow turns once when one comes back, and **ALL CAUGHT!** shows when
/// the last is down.
///
/// Everything is read from the flight (the vanguard's records, the boss's
/// clock), so paused, replayed and seeked frames repeat. Reduced Motion
/// keeps every state and drops the pops and the turn.
abstract final class StragglerArt {
  static const _ink = KingCooPalette.ink, _cream = Color(0xfffff2c9);
  static const _gold = KingCooPalette.brass, _goldLit = KingCooPalette.brassLit;
  static const _mint = Color(0xffa8e8bc);

  /// A catch pops the tag this long; ALL CAUGHT! shows this long.
  static const popSeconds = .4, caughtSeconds = 2.4;

  /// When the last owed pigeon was caught (flight elapsed seconds), or null
  /// while any are owed or none ever got away.
  static double? caughtAt(BossVanguard guard) {
    if (guard.escaped <= 0 || guard.owed > 0) return null;
    return guard.stragglerDownedAt.values.fold<double?>(
      null,
      (last, t) => last == null || t > last ? t : last,
    );
  }

  /// Whether [enemy] is one of the vanguard's pigeons come back.
  static bool isStraggler(FlightSimulation sim, SkyEnemy enemy) =>
      sim.vanguard?.stragglers.contains(enemy) ?? false;

  /// Where the owed tag hangs on a screen of [size] (its widest, "×14"),
  /// for layout checks: under the plate's left end, under the crest and the
  /// name, left of where PUFFED x2 and the STRONGER! card hang.
  static Rect tagBounds(Size size, SkyBoss boss) {
    final u = BossHealthBarArt.unit(size);
    final strip = BossHealthBarArt.bounds(size, boss);
    return Rect.fromLTWH(
      strip.left + 9 * u,
      strip.bottom - 2.4 * u,
      _tagWidth(u, '×14'),
      17.2 * u,
    );
  }

  static double _tagWidth(double u, String count) =>
      4 * u + 15.5 * u + 2.5 * u + _text(count, 10.5 * u, _cream).width + 6 * u;

  /// The owed tag, under King Coo's plate while his fight is on and any of
  /// his vanguard are owed; then ALL CAUGHT! for a moment.
  static void owedTag(
    Canvas c,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final guard = sim.vanguard, boss = sim.boss;
    if (guard == null || boss == null || !boss.isKingCoo) return;
    if (!BossVanguard.returnsOf(guard.boss) || guard.escaped <= 0) return;
    if (boss.inCutscene || !boss.age.isFinite || !sim.elapsed.isFinite) {
      return;
    }
    final u = BossHealthBarArt.unit(size);
    final strip = BossHealthBarArt.bounds(size, boss);
    // In with the plate after the arrival.
    final into = reducedMotion
        ? 1.0
        : BossMotion.ease(
            ((boss.age - boss.arrivalDuration) / .35).clamp(0.0, 1.0),
          );
    final caught = caughtAt(guard);
    final double since;
    final bool done;
    if (caught != null) {
      since = sim.elapsed - caught;
      if (since < 0 || since >= caughtSeconds) return;
      done = true;
    } else {
      final last = guard.stragglerDownedAt.values.fold(
        double.negativeInfinity,
        math.max,
      );
      since = sim.elapsed - last;
      done = false;
    }
    final fade = done ? ((caughtSeconds - since) / .5).clamp(0.0, 1.0) : 1.0;
    final pop = reducedMotion || !(since >= 0 && since < popSeconds)
        ? 0.0
        : math.sin(since / popSeconds * math.pi) * (1 - since / popSeconds);
    // The arrow turns once as a straggler comes back.
    final back = guard.stragglers.isEmpty
        ? double.infinity
        : guard.stragglers.last.age;
    final turn = reducedMotion || done || !(back >= 0 && back < .6)
        ? 0.0
        : BossMotion.ease(back / .6) * math.pi * 2;

    final a = into * fade;
    if (a <= 0) return;
    // (The fade is quantised so the few faded words are laid out once.)
    final q = (a * 12).round() / 12;
    final label = done
        ? _text(
            'ALL CAUGHT!',
            9.5 * u,
            _mint.withValues(alpha: q),
            spacing: .4 * u,
          )
        : _text('×${guard.owed}', 10.5 * u, _cream.withValues(alpha: q));
    final h = 16 * u, icon = 15.5 * u;
    final w = 4 * u + icon + 2.5 * u + label.width + 6 * u;
    final left = strip.left + 9 * u, top = strip.bottom - 1.2 * u;
    c.save();
    c.translate(left + w / 2, top);
    c.scale(1 + .22 * pop, (1 + .22 * pop) * (reducedMotion ? 1 : into));
    c.translate(-w / 2, 0);
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(3 * u),
    );
    // Two links tie it to the plate.
    for (final x in [5 * u, w - 6.6 * u]) {
      c.drawRect(
        Rect.fromLTWH(x, -1.4 * u, 1.6 * u, 2.4 * u),
        _fill(KingCooPalette.brassDeep, a),
      );
    }
    c.drawRRect(box.shift(Offset(0, 1.2 * u)), _fill(_ink, .3 * a));
    c.drawRRect(box.inflate(.9 * u), _fill(_ink, a));
    c.drawRRect(
      box,
      _fill(done ? const Color(0xff1f4a45) : KingCooPalette.navy, a),
    );
    c.drawRRect(box.deflate(.6 * u), _line(done ? _mint : _gold, 1 * u, a));
    final iconAt = Offset(4 * u + icon / 2, h / 2);
    if (done) {
      // A tick in place of the arrowed pigeon.
      c.drawPath(
        Path()
          ..moveTo(iconAt.dx - 4 * u, iconAt.dy)
          ..lineTo(iconAt.dx - 1.2 * u, iconAt.dy + 3 * u)
          ..lineTo(iconAt.dx + 4.4 * u, iconAt.dy - 3.6 * u),
        _line(_mint, 2.2 * u, a),
      );
    } else {
      badge(c, iconAt, icon / 2, a: a, turn: turn, pigeon: true);
    }
    label.paint(
      c,
      Offset(4 * u + icon + 2.5 * u, (h - label.height) / 2 + .3 * u),
    );
    if (pop > 0 && !done) {
      // A gold ring off the count as one is caught.
      final k = since / popSeconds;
      c.drawCircle(
        Offset(w - 4 * u - label.width / 2, h / 2),
        (5 + 9 * k) * u,
        _line(_goldLit, (1.6 - k) * u, (1 - k) * a),
      );
    }
    c.restore();
  }

  /// The "comes back" sign at [at], [r] its radius: a gold arrow curling
  /// most of the way round, ending in its head, turned by [turn]; with
  /// [pigeon] a little pigeon inside it (the owed tag), else on a navy disc
  /// (a straggler's badge).
  static void badge(
    Canvas c,
    Offset at,
    double r, {
    double a = 1,
    double turn = 0,
    bool pigeon = false,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    if (!pigeon) {
      c.drawCircle(Offset.zero, r * 1.08, _fill(_ink, a));
      c.drawCircle(Offset.zero, r * .9, _fill(KingCooPalette.navy, a));
    } else {
      c.save();
      c.translate(-r * .05, r * .08);
      c.scale(r * .52);
      c.drawPath(
        BossVanguardArt.glyph(EnemyKind.alleyPigeon),
        _fill(const Color(0xffe8edfb), a),
      );
      c.restore();
    }
    c.rotate(turn);
    final arc = pigeon ? r * .92 : r * .58;
    final width = pigeon ? r * .22 : r * .26;
    // A counter-clockwise arrow ("round again") from the bottom right over
    // the top to the left, its head pointing on round.
    const from = math.pi * .3, sweep = -math.pi * 1.5;
    final rect = Rect.fromCircle(center: Offset.zero, radius: arc);
    c.drawArc(rect, from, sweep, false, _line(_ink, width + r * .16, a));
    c.drawArc(rect, from, sweep, false, _line(_gold, width, a));
    final end = from + sweep;
    final tip = Offset(math.cos(end), math.sin(end)) * arc;
    // Tangent of the counter-clockwise sweep.
    final dir = Offset(math.sin(end), -math.cos(end));
    final side = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(tip.dx + dir.dx * width * 2.1, tip.dy + dir.dy * width * 2.1)
      ..lineTo(tip.dx + side.dx * width * 1.9, tip.dy + side.dy * width * 1.9)
      ..lineTo(tip.dx - side.dx * width * 1.9, tip.dy - side.dy * width * 1.9)
      ..close();
    c.drawPath(head, _line(_ink, r * .16, a)..strokeJoin = StrokeJoin.round);
    c.drawPath(head, _fill(_goldLit, a));
    c.restore();
  }

  /// The badge a returning straggler wears, over its head (screen space,
  /// so it does not turn with the bird): [radius] is the enemy's hit radius
  /// in px.
  static void strayBadge(Canvas c, Offset center, double radius) =>
      badge(c, center + Offset(-.35 * radius, -1.62 * radius), radius * .44);

  static final Map<Object, TextPainter> _texts = {};

  static TextPainter _text(
    String value,
    double size,
    Color color, {
    double spacing = 0,
  }) => _texts[(value, size, color, spacing)] ??= TextPainter(
    text: TextSpan(
      text: value,
      style: heading(
        size,
        color: color,
        weight: FontWeight.w700,
      ).copyWith(letterSpacing: spacing),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()..color = color.withValues(alpha: color.a * alpha.clamp(0, 1));

  static Paint _line(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
}
