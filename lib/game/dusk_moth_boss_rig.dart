import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'dusk_moth_body_art.dart';
import 'dusk_moth_crown_art.dart';
import 'dusk_moth_head_art.dart';
import 'dusk_moth_kit.dart';
import 'dusk_moth_pose.dart';
import 'dusk_moth_wing_art.dart';

/// The Dusk Empress: an imperious moth-queen of the night court. Four velvet
/// rose wings with pearl scalloped hems and glowing moon eyespots spread
/// behind her like a royal cape; a layered ermine ruff frames a kohl-eyed,
/// predatory-elegant face under a lunar diadem and swept plumed antennae; a
/// banded abdomen, slim gold-tipped legs and three amber throat glands that
/// load her pollen complete her.
///
/// Authored in hit-radius units, facing left; the pollen port stays at
/// (-1.05, 0). The parts live in [DuskMothWingArt], [DuskMothBodyArt],
/// [DuskMothHeadArt] and [DuskMothCrownArt]; this file keeps the palette,
/// the draw order and the woven silk shield.
abstract final class DuskMothBossRig {
  static const coral = Color(0xffefaa91), plum = Color(0xff704663);
  static const pollen = Color(0xffffc96f), silk = Color(0xffffe3ba);
  static const veil = Color(0xffbdefff), ink = Color(0xff392e4b);

  /// Also shared with the small dusk moths so the queen reads as their elder.
  static const pearl = Color(0xfffff3da), rose = Color(0xffc2687f);
  static const wine = Color(0xff8c3f62), ember = Color(0xffff9a4a);

  /// The deep end of her velvet, and the heat of her fury.
  static const violet = Color(0xff4c3080), night = Color(0xff2f2360);
  static const flame = Color(0xffe0562f);
  static const eyeCenter = Offset(-.84, -.24);
  // The attachment is the head's crest, not the rear edge of its fur collar.
  static const crownAnchor = Offset(-.76, -.9);
  static const crownBounds = DuskMothCrownArt.bounds;

  /// Everything the queen can reach, poses included: the encounter's night
  /// silhouette layer is bounded to this.
  static const layerBounds = Rect.fromLTRB(-3, -3.1, 3.6, 2.7);
  // The silk shield keeps its original woven palette.
  static const _velvet = Color(0xff54304f), _pearl = pearl;

  static Paint _fill(Color color) => DuskMothKit.fill(color);
  static Paint _line(Color color, double width) =>
      DuskMothKit.line(color, width);
  static Path _crescent(Offset at, double r) => Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: at, radius: r)),
    Path()..addOval(
      Rect.fromCircle(center: at + Offset(r * .48, -r * .24), radius: r * .84),
    ),
  );

  static void paint(Canvas c, SkyBoss boss, BossMotion m, {double lookY = 0}) {
    final p = DuskMothPose(boss, m, lookY);
    // Four wings spread behind the body: the far pair first.
    DuskMothWingArt.paint(c, p, far: true);
    DuskMothWingArt.paint(c, p, far: false);
    DuskMothWingArt.motes(c, p);
    DuskMothBodyArt.abdomen(c, p);
    DuskMothBodyArt.legs(c, p, far: true);
    DuskMothBodyArt.thorax(c, p);
    DuskMothBodyArt.shoulders(c, p);
    DuskMothBodyArt.ruffBack(c, p);
    DuskMothHeadArt.plumes(c, p);
    DuskMothBodyArt.legs(c, p, far: false);
    DuskMothBodyArt.ruffFront(c, p);
    DuskMothBodyArt.glands(c, p);
    DuskMothHeadArt.head(c, p);
    DuskMothBodyArt.bib(c, p);
    DuskMothBodyArt.pollenLight(c, p);
    if (!m.defeated || m.death < .3) {
      // Her diadem burns with the windup and the fury. The halo sits behind
      // the crown, so the crown's own pixels stay the same in every pose.
      final heat = p.defeated ? 0.0 : math.max(p.fury * .5, p.charge * .32);
      if (heat > 0) {
        DuskMothKit.glow(
          c,
          crownAnchor + const Offset(-.1, -.3),
          .9,
          Color.lerp(pollen, ember, p.fury)!,
          heat,
        );
      }
      c.save();
      // The fitted rim shares the head's transform; lifting/tilting it alone
      // breaks contact during recoil and the arrival roar.
      c.translate(crownAnchor.dx, crownAnchor.dy);
      crown(c, moonlight: p.moonlight, fury: p.fury);
      c.restore();
      _twinkle(c, p);
    }
  }

  // A glint winks in the air above the crescent every few seconds. It floats
  // clear of the diadem, so the crown itself is the same in every pose.
  static void _twinkle(Canvas c, DuskMothPose p) {
    final t = p.twinkle;
    if (t <= 0) return;
    final at = crownAnchor + const Offset(-.72, -1.04);
    DuskMothKit.glow(c, at, .2 * t, pearl, .5 * t);
    c.drawPath(DuskMothKit.star(at, .13 * t, waist: .16), _fill(pearl));
  }

  /// The lunar diadem around its seat: also drawn on its own when it is
  /// knocked off in the defeat.
  static void crown(Canvas c, {double moonlight = 0, double fury = 0}) =>
      DuskMothCrownArt.paint(c, moonlight: moonlight, fury: fury);

  /// World-space silk is woven just inside the exact projectile-blocking rim.
  static void paintShield(
    Canvas c,
    Offset center,
    double radius,
    SkyBoss boss,
    BossMotion m,
  ) {
    if (!boss.shielded && boss.shieldWarning <= 0) return;
    final active = boss.shielded;
    final warning = BossMotion.ease(boss.shieldWarning);
    final hit = BossMotion.pulse(boss.age - boss.lastShieldHitAt, .3);
    final weave = m.reducedMotion ? 0.0 : boss.age * .12;
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(radius);
    const bounds = Rect.fromLTRB(-1, -1, 1, 1);
    if (active) {
      c.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = RadialGradient(
            colors: [
              veil.withValues(alpha: 0),
              veil.withValues(alpha: .015),
              veil.withValues(alpha: .19 + hit * .1),
            ],
            stops: const [0, .68, 1],
          ).createShader(bounds),
      );
      // The uninterrupted edge always describes the actual blocked area.
      c.drawCircle(Offset.zero, 1, _line(ink.withValues(alpha: .75), .04));
      c.drawCircle(Offset.zero, 1, _line(veil, .021));
      c.drawCircle(Offset.zero, .964, _line(silk.withValues(alpha: .64), .008));
      c.drawArc(bounds, math.pi * .88, .93, false, _line(_pearl, .029));
    }
    if (!active) {
      // A dashed, still-open ring: threads gathering, not yet a wall.
      c.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = RadialGradient(
            colors: [
              veil.withValues(alpha: 0),
              veil.withValues(alpha: 0),
              veil.withValues(alpha: warning * .1),
            ],
            stops: const [0, .78, 1],
          ).createShader(bounds),
      );
    }
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 + weave;
      final sweep = active ? math.pi / 6 : .06 + warning * .3;
      if (!active) {
        c.drawArc(
          bounds,
          angle,
          sweep,
          false,
          _line(ink.withValues(alpha: .18 + warning * .22), .036),
        );
      }
      c.drawArc(
        bounds,
        angle,
        sweep,
        false,
        _line(
          active
              ? silk.withValues(alpha: .84)
              : veil.withValues(alpha: .45 + warning * .5),
          active ? .009 : .016 + warning * .006,
        ),
      );
      // Crossing thread loops make a scalloped silk hem, keeping the face clear.
      if (active) {
        final start = _polar(angle, .975);
        final end = _polar(angle + sweep, .975);
        final loop = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(
            _polar(angle + sweep / 2, .77).dx,
            _polar(angle + sweep / 2, .77).dy,
            end.dx,
            end.dy,
          );
        c.drawPath(
          loop,
          _line(veil.withValues(alpha: active ? .52 : warning * .5), .009),
        );
        if (active) {
          final cross = Path()
            ..moveTo(_polar(angle + .12, .91).dx, _polar(angle + .12, .91).dy)
            ..quadraticBezierTo(
              _polar(angle + .33, .985).dx,
              _polar(angle + .33, .985).dy,
              _polar(angle + .64, .91).dx,
              _polar(angle + .64, .91).dy,
            );
          c.drawPath(cross, _line(silk.withValues(alpha: .42), .006));
        }
      }
      final at = _polar(angle, active ? .98 : 1);
      c.drawCircle(
        at,
        active ? .015 : .011 + warning * .005,
        _fill(active ? _pearl : veil.withValues(alpha: .5 + warning * .5)),
      );
    }
    // Fixed crescent clasps connect the lunar eyespots to the woven perimeter.
    for (final angle in const [-math.pi / 2, math.pi / 6, math.pi * 5 / 6]) {
      final at = _polar(angle, .935);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(angle + math.pi / 2);
      if (active) {
        c.drawCircle(Offset.zero, .078, _fill(_velvet.withValues(alpha: .84)));
        c.drawCircle(Offset.zero, .078, _line(veil, .012));
        c.drawPath(_crescent(Offset.zero, .046), _fill(_pearl));
      } else {
        c.drawPath(
          _crescent(Offset.zero, .035 + warning * .011),
          _fill(veil.withValues(alpha: .3 + warning * .55)),
        );
      }
      c.restore();
    }
    if (active && hit > 0) {
      c.drawArc(
        bounds,
        math.pi - .4,
        .8,
        false,
        _line(_pearl.withValues(alpha: hit), .055),
      );
      // A caught-shot rosette and short ripples stay at the incoming-shot edge.
      final spread = m.reducedMotion
          ? .5
          : BossMotion.ramp(boss.age - boss.lastShieldHitAt, 0, .3);
      for (var i = 0; i < 2; i++) {
        c.drawArc(
          Rect.fromCircle(
            center: const Offset(-1, 0),
            radius: .075 + i * .07 + spread * .09,
          ),
          -.9,
          1.8,
          false,
          _line(veil.withValues(alpha: hit * (1 - i * .25)), .014),
        );
      }
      final star = Path()
        ..moveTo(-1, -.085)
        ..quadraticBezierTo(-.984, -.015, -.925, 0)
        ..quadraticBezierTo(-.984, .015, -1, .085)
        ..quadraticBezierTo(-1.016, .015, -1.075, 0)
        ..quadraticBezierTo(-1.016, -.015, -1, -.085)
        ..close();
      c.drawPath(star, _fill(_pearl.withValues(alpha: hit)));
    }
    c.restore();
  }

  static Offset _polar(double angle, double radius) =>
      Offset(math.cos(angle), math.sin(angle)) * radius;
}
