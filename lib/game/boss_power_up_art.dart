import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import 'boss_encounter_art.dart';
import 'boss_motion.dart';
import 'gargoyle_encounter_art.dart';
import 'king_coo_kit.dart';
import 'king_coo_staging_art.dart';
import 'neferhoo_hud_art.dart';
import 'pirate_hud_art.dart';
import 'pirate_ship_art.dart';

/// A staged campaign boss growing stronger (rules version 44). For
/// [SkyBoss.stageRoar] after each step up, while it roars and holds its
/// fire, a swell of light in its own colour gathers behind it, two shock
/// rings break off it and chevrons climb either side of it: it just got
/// stronger. Into its fury the light runs ember.
///
/// One effect for all seven bosses, sized and centred on each figure (the
/// Pirate Captain on his deck, the Gargoyle on his ledge); no rig changes.
/// [under] goes beneath the boss's layer and [over] above it. A pure
/// function of the boss's clock, so paused, replayed and seeked frames
/// repeat. Reduced Motion keeps one still ring and still chevrons that fade
/// with the glow. Nothing flashes: the swell rises over a quarter second and
/// stays a soft glow around the figure, well under a tenth of the screen.
abstract final class BossPowerUpArt {
  /// The effect lasts the roar.
  static const seconds = SkyBoss.stageRoar;

  static const _ink = Color(0xff171c39), _ember = Color(0xffff775c);
  static const _emberLit = Color(0xffffd0a8);

  /// Each boss's own colour as (main, light): its plate's, or its signature
  /// light (King Coo's siren blue, the Gargoyle's lamp, the captain's gold).
  static (Color, Color) colors(BossKind kind) => switch (kind) {
    BossKind.baronBat => (const Color(0xffffcf5c), const Color(0xffffedb0)),
    BossKind.spitterBeetle => (
      const Color(0xff6fe3a4),
      const Color(0xffdcffc9),
    ),
    BossKind.duskMoth => (const Color(0xfff29cc6), const Color(0xffffdcee)),
    // The captain's doubloon gold: his plate's sea teal is lost on the sea.
    BossKind.pirate => (PirateHudArt.gold, PirateHudArt.goldLight),
    BossKind.dragon => (const Color(0xffff8a34), const Color(0xffffe27a)),
    BossKind.kingCoo => (KingCooPalette.sirenBlue, const Color(0xffd6ecff)),
    BossKind.searchlightGargoyle => (
      const Color(0xffffb84a),
      const Color(0xfffffbe8),
    ),
    BossKind.neferhoo => NeferhooHudArt.powerUp,
  };

  /// Seconds since [boss] last grew stronger while that is under [seconds],
  /// else null (and always null for a boss that fights in one stage, or
  /// once it is beaten).
  static double? age(SkyBoss? boss) {
    if (boss == null || !boss.staged || !boss.cinematic) return null;
    if (boss.phase != BossPhase.attacking) return null;
    final since = boss.age - boss.stageUpAt;
    return since.isFinite && since >= 0 && since < seconds ? since : null;
  }

  /// Where the effect centres and how far the figure reaches (px), on a
  /// screen [h] high.
  static ({Offset at, double reach}) frame(BossMotion m, double h) {
    final boss = m.boss, unit = h * SkyBoss.radius;
    return switch (boss.kind) {
      BossKind.dragon => (
        at: BossEncounterArt.dragonFrame(m, h).heart,
        reach: unit * 2.5,
      ),
      BossKind.kingCoo => (
        at: KingCooStaging.heart(m, h) + Offset(0, -.15 * unit),
        reach: unit * 2.3,
      ),
      BossKind.searchlightGargoyle => (
        at: GargoyleEncounterArt.frame(m, h).heart + Offset(0, -.3 * unit),
        reach: unit * 2.1,
      ),
      BossKind.neferhoo => NeferhooHudArt.powerUpFrame(m, h),
      // The captain on his deck, not the ship.
      BossKind.pirate => (
        at:
            Offset(boss.x * h, boss.y * h) +
            m.offset * h +
            Offset(0, (PirateShipArt.rail - .9) * unit),
        reach: unit * 1.7,
      ),
      BossKind.baronBat || BossKind.spitterBeetle || BossKind.duskMoth => (
        at: Offset(boss.x * h, boss.y * h) + m.offset * h,
        reach: unit * 1.9,
      ),
    };
  }

  /// The boss's colours for this step: its own, or ember into its fury.
  static (Color, Color) _tint(SkyBoss boss) {
    final (main, light) = colors(boss.kind);
    return boss.stageReached >= 2
        ? (Color.lerp(main, _ember, .75)!, Color.lerp(light, _emberLit, .6)!)
        : (main, light);
  }

  /// How strong the glow is, 0 to 1: up over a quarter second, held through
  /// the roar's peak, gone by its end.
  static double _swell(double t) =>
      BossMotion.ease(BossMotion.ramp(t, 0, .26)) *
      (1 - BossMotion.ease(BossMotion.ramp(t, .75, seconds)));

  /// The glow behind the figure.
  static void under(
    Canvas c,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final boss = sim.boss;
    final t = age(boss);
    if (t == null || !size.isFinite) return;
    final m = BossMotion(boss!, reducedMotion: reducedMotion);
    final f = frame(m, size.height);
    final (main, light) = _tint(boss);
    final swell = _swell(t);
    if (swell <= .001) return;
    // It swells as it rises and breathes as it holds (still, at its full
    // size, under Reduced Motion).
    final r = reducedMotion
        ? f.reach * 1.18
        : f.reach *
              (1.0 +
                  .18 * BossMotion.ease(BossMotion.ramp(t, 0, .4)) +
                  math.sin(t * math.pi * 2 * 1.6) * .05);
    c.drawCircle(
      f.at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            light.withValues(alpha: .34 * swell),
            main.withValues(alpha: .26 * swell),
            main.withValues(alpha: .1 * swell),
            main.withValues(alpha: 0),
          ],
          stops: const [0, .42, .75, 1],
        ).createShader(Rect.fromCircle(center: f.at, radius: r)),
    );
  }

  /// The rings, chevrons and motes over the figure.
  static void over(
    Canvas c,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final boss = sim.boss;
    final t = age(boss);
    if (t == null || !size.isFinite) return;
    final h = size.height;
    final m = BossMotion(boss!, reducedMotion: reducedMotion);
    final f = frame(m, h);
    final (main, light) = _tint(boss);
    final swell = _swell(t);
    final px = h / 360;

    // The colour swell: the figure itself lights up in its colour (a screen
    // glow, so it brightens without hiding the rig).
    if (swell > .001) {
      final r = f.reach * 1.05;
      c.drawCircle(
        f.at,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(
            colors: [
              light.withValues(alpha: .42 * swell),
              main.withValues(alpha: .3 * swell),
              main.withValues(alpha: 0),
            ],
            stops: const [0, .55, 1],
          ).createShader(Rect.fromCircle(center: f.at, radius: r)),
      );
    }

    // Shock rings: two break off the figure and spread out, an ink edge
    // under each so they read over any sky. Reduced Motion: one, still.
    if (reducedMotion) {
      c.drawCircle(f.at, f.reach * 1.2, _line(_ink, 4.5 * px, .25 * swell));
      c.drawCircle(f.at, f.reach * 1.2, _line(main, 2.6 * px, .8 * swell));
    } else {
      for (var i = 0; i < 2; i++) {
        final k = BossMotion.ramp(t, i * .16, .62 + i * .16);
        if (k <= 0 || k >= 1) continue;
        final e = 1 - math.pow(1 - k, 3).toDouble();
        final r = f.reach * (.75 + 1.05 * e);
        final fade = 1 - k;
        final width = (5.5 - 3.5 * k) * px;
        c.drawCircle(f.at, r, _line(_ink, width + 2.4 * px, .28 * fade));
        c.drawCircle(f.at, r, _line(i == 0 ? light : main, width, .95 * fade));
      }
    }

    // A burst of streaks off the first ring.
    if (!reducedMotion) {
      final k = BossMotion.ramp(t, .02, .42);
      if (k > 0 && k < 1) {
        final e = 1 - math.pow(1 - k, 2).toDouble();
        final streaks = Path();
        for (var i = 0; i < 16; i++) {
          final a = i * math.pi / 8 + .2;
          final d = Offset(math.cos(a), math.sin(a));
          final from = f.reach * (.95 + .5 * e);
          final to = from + f.reach * (i.isEven ? .32 : .2) * (1 - k);
          streaks
            ..moveTo(f.at.dx + d.dx * from, f.at.dy + d.dy * from)
            ..lineTo(f.at.dx + d.dx * to, f.at.dy + d.dy * to);
        }
        c.drawPath(streaks, _line(_ink, 4.6 * px, .22 * (1 - k)));
        c.drawPath(streaks, _line(light, 2.6 * px, .95 * (1 - k)));
      }
    }

    // Chevrons climb in threes either side of the figure.
    final chevron = f.reach * .32;
    for (final side in const [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final double rise, alpha;
        if (reducedMotion) {
          rise = .5 - i * .42;
          alpha = swell;
        } else {
          final k = BossMotion.ramp(t, .08 + i * .12, .78 + i * .12);
          if (k <= 0 || k >= 1) continue;
          rise = .55 - k * 1.1;
          alpha = math.sin(k * math.pi);
        }
        final at = f.at + Offset(side * f.reach * 1.3, f.reach * rise);
        final path = Path()
          ..moveTo(at.dx - chevron * .5, at.dy + chevron * .3)
          ..lineTo(at.dx, at.dy - chevron * .22)
          ..lineTo(at.dx + chevron * .5, at.dy + chevron * .3);
        c.drawPath(
          path,
          _line(_ink, chevron * .36, .35 * alpha)
            ..strokeJoin = StrokeJoin.round,
        );
        c.drawPath(
          path,
          _line(main, chevron * .22, alpha)..strokeJoin = StrokeJoin.round,
        );
        c.drawPath(
          path,
          _line(light, chevron * .08, alpha)..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // Motes of the boss's light drift up off it (none under Reduced Motion).
    if (reducedMotion) return;
    final mote = Paint()..color = light;
    for (var i = 0; i < 12; i++) {
      final start = _hash(i, 3) * .5;
      final k = BossMotion.ramp(t, start, start + .7 + _hash(i, 5) * .3);
      if (k <= 0 || k >= 1) continue;
      final a = _hash(i, 7) * math.pi * 2;
      final from = Offset(math.cos(a), math.sin(a) * .7) * f.reach * .85;
      final at = f.at + from + Offset(0, -f.reach * .7 * k);
      mote.color = light.withValues(alpha: math.sin(k * math.pi) * .9);
      c.drawCircle(at, (1.6 + _hash(i, 9) * 1.6) * px * (1 - k * .4), mote);
    }
  }

  static Paint _line(Color color, double width, [double alpha = 1]) => Paint()
    ..color = color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0))
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  /// A well-mixed 0..1 value for slot [i] and [salt].
  static double _hash(int i, int salt) {
    var x = (i * 0x9E3779B1 + salt * 0x85EBCA6B + 0x27d4eb2f) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x ^= x >> 16;
    return x / 4294967296.0;
  }
}
