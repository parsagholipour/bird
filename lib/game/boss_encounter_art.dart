import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'boss_rig.dart';
import 'spitter_boss_rig.dart';
import 'dusk_moth_boss_rig.dart';
import 'boss_ammo_art.dart';
import 'sky_scenery.dart';

abstract final class BossEncounterArt {
  static const _night = Color(0xff171c39), _lilac = Color(0xffbea9f3);
  static const _gold = Color(0xffffd878), _ice = Color(0xffb4f6ea);
  static Color _tint(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => _lilac,
    BossKind.spitterBeetle => SpitterBossRig.acid,
    BossKind.duskMoth => DuskMothBossRig.coral,
  };
  static Color _ammoColor(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => BossRig.ember,
    BossKind.spitterBeetle => SpitterBossRig.acid,
    BossKind.duskMoth => DuskMothBossRig.pollen,
  };
  static Color _light(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => _gold,
    BossKind.spitterBeetle => SpitterBossRig.mint,
    BossKind.duskMoth => DuskMothBossRig.silk,
  };
  static Paint _fill(Color color, [double opacity = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));
  static Paint _line(Color color, double width, [double opacity = 1]) =>
      _fill(color, opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

  static void backdrop(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    final h = size.height, w = size.width;
    final tint = _tint(boss);
    final center = Offset(
      (boss.phase == BossPhase.arriving ? w / h - .72 : boss.x) * h,
      h * .48,
    );
    final storm = m.storm;
    c.drawRect(
      Offset.zero & size,
      _fill(_night, storm * (.22 + m.focus * .25)),
    );
    final halo = Rect.fromCircle(center: center, radius: h * .65);
    c.drawCircle(
      center,
      h * .65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            tint.withValues(alpha: .19 * storm),
            _night.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );
    // Orbiting cloud bands frame the silhouette without hiding the player's lane.
    for (var i = 0; i < 5; i++) {
      final radius = h * (.21 + i * .075);
      final angle =
          i * 1.2 + (m.reducedMotion ? 0 : boss.age * (.18 + i * .02));
      c.drawArc(
        Rect.fromCenter(
          center: center,
          width: radius * 2.1,
          height: radius * 1.65,
        ),
        angle,
        1.8,
        false,
        _line(tint, h * (.018 + i * .006), storm * .07),
      );
    }
    for (var i = 0; i < 22; i++) {
      final drift = m.reducedMotion ? 0.0 : boss.age * (.08 + (i % 4) * .018);
      final x = ((i * .173 + 1 - drift) % 1) * w;
      final y = (.14 + ((i * .273) % .74)) * h;
      c.drawLine(
        Offset(x, y),
        Offset(x + h * (.025 + i % 3 * .012), y - h * .003),
        _line(_ice, h * .0018, storm * .14),
      );
    }
    if (m.arriving && !m.reducedMotion) {
      final bolt = BossMotion.pulse(boss.age - 1.28, .38);
      if (bolt > 0) {
        final path = Path()
          ..moveTo(center.dx + h * .18, -h * .05)
          ..lineTo(center.dx + h * .05, h * .13)
          ..lineTo(center.dx + h * .11, h * .14)
          ..lineTo(center.dx - h * .04, h * .34);
        c.drawPath(path, _line(tint, h * .024, bolt * .18));
        c.drawPath(path, _line(_ice, h * .004, bolt * .75));
      }
    }
  }

  static void paint(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss, h = size.height;
    final ammoColor = _ammoColor(boss);
    final ammoLight = _light(boss);
    final center = Offset(boss.x * h, boss.y * h) + m.offset * h;
    for (final ammo in sim.bossAmmo) {
      final at = Offset(ammo.x * h, ammo.y * h);
      if (boss.isSpitter || boss.isMoth) {
        BossAmmoArt.paint(
          c,
          center: at,
          radius: BossAmmo.radius * h,
          direction: math.atan2(ammo.vy, ammo.vx),
          attack: boss.isSpitter ? EnemyAttack.aimed : EnemyAttack.fan,
          seconds: sim.elapsed,
          reducedMotion: m.reducedMotion,
        );
        continue;
      }
      final direction = Offset(ammo.vx, ammo.vy);
      final unit = direction / direction.distance;
      final r = BossAmmo.radius * h;
      for (var i = 4; i > 0; i--) {
        c.drawCircle(
          at - unit * (r * i * .8),
          r * (1 - i * .15),
          _fill(ammoColor, (1 - i * .16) * .45),
        );
      }
      c.drawCircle(at, r * 1.6, _fill(ammoColor, .16));
      c.drawCircle(at, r * 1.05, _fill(BossRig.ink));
      c.drawCircle(at, r * .88, _fill(ammoColor));
      c.drawPath(SkyScenery.star(at, r * .75), _fill(ammoLight));
      c.drawCircle(at, r * .32, _fill(BossRig.cream));
    }
    if (boss.charge > 0 && !m.defeated) {
      _charge(
        c,
        center + Offset(-boss.muzzleOffset * h, 0),
        h,
        boss,
        m,
        sim.elapsed,
      );
    }
    if (m.roar > 0 || m.rage > 0 || m.summon > 0) {
      final pulse = math.max(m.roar, math.max(m.rage, m.summon));
      c.drawOval(
        Rect.fromCenter(
          center: center,
          width: h * (.34 + pulse * .26),
          height: h * (.25 + pulse * .15),
        ),
        _line(boss.enraged ? BossRig.ember : _gold, h * .005, pulse * .45),
      );
    }
    if (m.opacity > 0) {
      c.save();
      c.translate(center.dx, center.dy);
      final scale = h * SkyBoss.radius * m.bodyScale;
      c.rotate(m.rotation);
      c.scale(scale * (1 + m.stretch), scale * (1 - m.stretch));
      // Bounded to the character, not a full-screen compositing layer.
      final layer = Paint()
        ..color = const Color(0xffffffff).withValues(alpha: m.opacity);
      if (m.silhouette > .01) {
        layer.colorFilter = ColorFilter.mode(
          _night.withValues(alpha: m.silhouette * .97),
          BlendMode.srcATop,
        );
      }
      c.saveLayer(const Rect.fromLTWH(-3, -2.3, 6, 4), layer);
      if (boss.isMoth) {
        DuskMothBossRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
      } else if (boss.isSpitter) {
        SpitterBossRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
      } else {
        BossRig.paint(c, boss, m);
      }
      c.restore();
      if (m.silhouette > .25) {
        final eyes = boss.isMoth
            ? [DuskMothBossRig.eyeCenter]
            : boss.isSpitter
            ? [SpitterBossRig.eyeCenter]
            : const [Offset(-.36, -.25), Offset(.36, -.25)];
        for (final eye in eyes) {
          c.drawOval(
            Rect.fromCenter(center: eye, width: .34, height: .1),
            _fill(_gold, m.silhouette),
          );
        }
      }
      c.restore();
    }
    if (boss.isMoth) {
      DuskMothBossRig.paintShield(
        c,
        Offset(boss.x * h, boss.y * h),
        SkyBoss.shieldRadius * h,
        boss,
        m,
      );
    }
    if (m.hit > 0 && !m.defeated) {
      final t = BossMotion.ramp(boss.age - boss.lastHitAt, 0, .32);
      _burst(c, center + Offset(-h * .08, 0), h, t, 9, .08, m.reducedMotion);
    }
    final shot = BossMotion.ramp(boss.age - boss.lastVolleyAt, 0, .3);
    if (shot > 0 && shot < 1 && !m.defeated) {
      c.drawCircle(
        center + Offset(-h * boss.muzzleOffset, 0),
        h * (.022 + shot * .075),
        _line(ammoLight, h * .004 * (1 - shot), 1 - shot),
      );
    }
    if (m.defeated) _death(c, center, h, m);
  }

  static void _charge(
    Canvas c,
    Offset at,
    double h,
    SkyBoss boss,
    BossMotion m,
    double seconds,
  ) {
    final charge = boss.charge;
    final color = _ammoColor(boss);
    final light = _light(boss);
    final r = h * (.017 + charge * .022);
    final angle = m.reducedMotion ? 0.0 : boss.age * 4;
    if (boss.isSpitter) {
      // Bubbles draw into the mouth as the brewer's tank pressurizes.
      for (var i = 0; i < 7; i++) {
        final phase = m.reducedMotion ? .5 : (boss.age * 1.9 + i / 7) % 1;
        final a = math.pi * (.55 + i / 7 * .9);
        final distance = h * (.018 + (1 - phase) * .09) * charge;
        final bubble = at + Offset(math.cos(a), math.sin(a)) * distance;
        final bubbleRadius = h * (.002 + i % 3 * .0015) * charge;
        c.drawCircle(bubble, bubbleRadius, _fill(light, .18 + phase * .25));
        c.drawCircle(bubble, bubbleRadius, _line(light, h * .0012, phase));
      }
    } else {
      c.drawCircle(
        at,
        r * 2.3,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: charge * .35),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: at, radius: r * 2.3)),
      );
      for (var i = 0; i < 6; i++) {
        final phase = m.reducedMotion ? .45 : (boss.age * 2 + i / 6) % 1;
        final a = angle + i * math.pi / 3;
        final distance = h * (.025 + (1 - phase) * .075) * charge;
        c.drawCircle(
          at + Offset(math.cos(a), math.sin(a)) * distance,
          h * .0035 * phase,
          _fill(light, phase),
        );
      }
      c.drawArc(
        Rect.fromCircle(center: at, radius: r * 1.55),
        angle,
        math.pi * 1.5,
        false,
        _line(light, h * .0025, charge),
      );
    }
    if (boss.isSpitter || boss.isMoth) {
      BossAmmoArt.paint(
        c,
        center: at,
        radius: boss.isSpitter ? r * (.85 + charge * .15) : r,
        direction: math.pi,
        attack: boss.isSpitter ? EnemyAttack.aimed : EnemyAttack.fan,
        seconds: seconds,
        reducedMotion: m.reducedMotion,
        showTrail: false,
      );
    } else {
      c.drawCircle(at, r, _fill(color));
      c.drawPath(SkyScenery.star(at, r * .8), _fill(light));
      c.drawCircle(at, r * .32, _fill(BossRig.cream));
    }
  }

  static void _death(Canvas c, Offset at, double h, BossMotion m) {
    final t = m.death;
    final tint = _tint(m.boss);
    if (t < SkyBoss.burstAt) {
      final gather = BossMotion.ramp(t, .2, SkyBoss.burstAt);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final direction = Offset(math.cos(a), math.sin(a));
        c.drawLine(
          at + direction * h * (.19 - gather * .09),
          at + direction * h * (.25 - gather * .12),
          _line(_gold, h * .004, gather * .7),
        );
      }
    }
    final burst = BossMotion.ramp(t, SkyBoss.burstAt, 2.3);
    if (t >= SkyBoss.burstAt && burst < 1) {
      final spread = m.reducedMotion ? .5 : math.pow(burst, .65).toDouble();
      for (var i = 0; i < 2; i++) {
        final radius = h * (.05 + spread * (.48 + i * .12));
        c.drawCircle(
          at,
          radius,
          _line(
            i == 0 ? _light(m.boss) : tint,
            h * .008 * (1 - burst),
            (1 - burst) * .75,
          ),
        );
      }
      for (var i = 0; i < 9; i++) {
        final angle = i * 2.399;
        final puff =
            at +
            Offset(math.cos(angle), math.sin(angle)) * h * (.04 + spread * .15);
        final r = h * (.045 + spread * .055);
        c.drawCircle(
          puff,
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [
                tint.withValues(alpha: (1 - burst) * .65),
                tint.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: puff, radius: r)),
        );
      }
      if (m.boss.isSpitter) {
        _acidBurst(c, at, h, burst, m.reducedMotion);
      } else {
        _burst(c, at, h, burst, 42, .46, m.reducedMotion);
      }
      final flash =
          1 - BossMotion.ramp(t, SkyBoss.burstAt, SkyBoss.burstAt + .19);
      if (flash > 0 && !m.reducedMotion) {
        final radius = h * (.06 + (1 - flash) * .10);
        c.drawCircle(
          at,
          radius * 1.8,
          Paint()
            ..shader = RadialGradient(
              colors: [
                _gold.withValues(alpha: flash * .8),
                _gold.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: at, radius: radius * 1.8)),
        );
        final impact = Path();
        for (var i = 0; i < 16; i++) {
          final angle = i * math.pi / 8;
          final r = radius * (i.isEven ? 1 : .24);
          final p = at + Offset(math.cos(angle), math.sin(angle)) * r;
          if (i == 0) {
            impact.moveTo(p.dx, p.dy);
          } else {
            impact.lineTo(p.dx, p.dy);
          }
        }
        impact.close();
        c.drawPath(impact, _fill(BossRig.cream, flash));
      }
    }
    // Each boss drops its own headwear during the defeat.
    if (t >= .3 && t < 2.7) {
      final flight = t - .3;
      final travel = m.reducedMotion ? .45 : flight;
      var anchor = m.boss.isMoth
          ? DuskMothBossRig.crownAnchor * h * SkyBoss.radius
          : m.boss.isSpitter
          ? SpitterBossRig.hatAnchor * h * SkyBoss.radius
          : Offset(0, -h * .13);
      var scale = .9, rotation = m.reducedMotion ? .25 : flight * 5.4;
      var stretch = 0.0;
      if (m.boss.isMoth) {
        // Release from the seated crown's actual body transform, then ease
        // into the free tumble without jumping in position, size or angle.
        final attached = m.reducedMotion
            ? 0.0
            : 1 - BossMotion.ease(BossMotion.ramp(flight, 0, .18));
        final fitted = Offset(
          anchor.dx * m.bodyScale * (1 + m.stretch),
          anchor.dy * m.bodyScale * (1 - m.stretch),
        );
        final turned = Offset(
          fitted.dx * math.cos(m.rotation) - fitted.dy * math.sin(m.rotation),
          fitted.dx * math.sin(m.rotation) + fitted.dy * math.cos(m.rotation),
        );
        anchor = Offset.lerp(anchor, turned, attached)!;
        scale = 1 + (m.bodyScale - 1) * attached;
        rotation += m.rotation * attached;
        stretch = m.stretch * attached;
      }
      c.save();
      c.translate(
        at.dx + anchor.dx + h * (.11 * travel),
        at.dy + anchor.dy + h * (-.31 * travel + .28 * travel * travel),
      );
      c.scale(h * SkyBoss.radius * scale);
      c.rotate(rotation);
      c.scale(1 + stretch, 1 - stretch);
      if (m.boss.kind == BossKind.baronBat) c.translate(0, 1.22);
      c.saveLayer(
        m.boss.isMoth
            ? DuskMothBossRig.crownBounds.inflate(.1)
            : m.boss.isSpitter
            ? SpitterBossRig.hatBounds.inflate(.1)
            : const Rect.fromLTWH(-1, -2, 2, 2),
        _fill(const Color(0xffffffff), 1 - BossMotion.ramp(t, 2.2, 2.7)),
      );
      if (m.boss.isMoth) {
        DuskMothBossRig.crown(c);
      } else if (m.boss.isSpitter) {
        SpitterBossRig.hat(c);
      } else {
        BossRig.crown(c);
      }
      c.restore();
      c.restore();
    }
  }

  static void _acidBurst(
    Canvas c,
    Offset at,
    double h,
    double t,
    bool reduced,
  ) {
    final travel = reduced ? .4 : t;
    // A pressure release sends droplets on arcs; the bubbles swell and pop.
    for (var i = 0; i < 18; i++) {
      final angle = i * 2.399963;
      final distance = h * (.025 + travel * (.16 + i % 4 * .055));
      final center =
          at +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + (reduced ? 0 : t * t * h * .2),
          );
      final radius = h * (.006 + i % 3 * .0025) * (1 - t * .6);
      final fade = (1 - t) * .85;
      c.drawCircle(center, radius, _fill(SpitterBossRig.acid, fade));
      c.drawCircle(
        center - Offset(radius * .25, radius * .3),
        radius * .3,
        _fill(SpitterBossRig.mint, fade),
      );
    }
    for (var i = 0; i < 6; i++) {
      final pop = (t * 1.3 - i * .045).clamp(0.0, 1.0);
      if (pop == 0 || pop == 1) continue;
      final a = i * math.pi / 3;
      final center =
          at +
          Offset(math.cos(a), math.sin(a)) *
              h *
              (reduced ? .15 : .04 + pop * .17);
      final radius = h * (reduced ? .025 : .009 + pop * .035);
      c.drawCircle(center, radius, _fill(SpitterBossRig.acid, (1 - pop) * .12));
      c.drawCircle(
        center,
        radius,
        _line(SpitterBossRig.mint, h * .002, 1 - pop),
      );
    }
  }

  static void _burst(
    Canvas c,
    Offset at,
    double h,
    double t,
    int count,
    double reach,
    bool reduced,
  ) {
    final travel = reduced ? .45 : math.pow(t, .65).toDouble();
    for (var i = 0; i < count; i++) {
      final a = i * 2.399963;
      final distance = h * (.025 + travel * reach * (.45 + (i % 7) / 12));
      final pos =
          at +
          Offset(
            math.cos(a) * distance,
            math.sin(a) * distance + (reduced ? 0 : t * t * h * .12),
          );
      final r = h * (.0035 + (i % 4) * .0015) * (1 - t * .7);
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(reduced ? a : a + t * 5);
      if (i % 3 == 0) {
        c.drawPath(SkyScenery.star(Offset.zero, r * 1.6), _fill(_gold, 1 - t));
      } else {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-r, -r * .4, r * 2, r * .8),
            Radius.circular(r * .2),
          ),
          _fill(i.isEven ? _ice : _lilac, 1 - t),
        );
      }
      c.restore();
    }
  }

  static void foreground(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
  ) {
    final h = size.height, w = size.width, boss = m.boss;
    if (m.focus > 0) {
      c.drawRect(
        Rect.fromLTWH(0, 0, w, h * .082 * m.focus),
        _fill(_night, .95),
      );
      c.drawRect(
        Rect.fromLTWH(0, h * (1 - .082 * m.focus), w, h * .082 * m.focus),
        _fill(_night, .95),
      );
      c.drawLine(
        Offset(0, h * .082 * m.focus),
        Offset(w, h * .082 * m.focus),
        _line(_gold, 1, .25 * m.focus),
      );
    }
    if (m.arriving) {
      if (boss.age < 1.55) {
        final fade =
            BossMotion.ease(BossMotion.ramp(boss.age, .15, .5)) *
            (1 - BossMotion.ramp(boss.age, 1.2, 1.55));
        _text(
          c,
          boss.isMoth
              ? 'TWILIGHT TAKES WING'
              : boss.isSpitter
              ? 'SOMETHING IS BREWING'
              : 'A SHADOW APPROACHES',
          Offset(w * .5, h * .31),
          h * .041,
          _gold,
          opacity: fade,
          centered: true,
          spacing: 2.5,
        );
        _text(
          c,
          boss.isMoth
              ? 'A silken veil gathers in the dusk…'
              : boss.isSpitter
              ? 'The air is starting to fizz…'
              : 'The sky belongs to someone else…',
          Offset(w * .5, h * .38),
          h * .026,
          BossRig.cream,
          opacity: fade,
          centered: true,
        );
      } else {
        final progress = BossMotion.ease(BossMotion.ramp(boss.age, 1.65, 2.25));
        final opacity = progress * (1 - BossMotion.ramp(boss.age, 3.9, 4.5));
        final x = w * .10 - (m.reducedMotion ? 0 : (1 - progress) * h * .09);
        c.drawLine(
          Offset(x, h * .22),
          Offset(x + w * .32, h * .22),
          _line(_gold, h * .003, opacity * .65),
        );
        _text(
          c,
          'ENCOUNTER ${boss.number.toString().padLeft(2, '0')}',
          Offset(x, h * .15),
          h * .03,
          _gold,
          opacity: opacity,
          spacing: 3,
        );
        _text(
          c,
          boss.name.toUpperCase(),
          Offset(x, h * .26),
          h * (boss.kind == BossKind.baronBat ? .091 : .075),
          BossRig.cream,
          opacity: opacity,
          shadow: true,
        );
        _text(
          c,
          boss.title,
          Offset(x + h * .003, h * .385),
          h * .026,
          _gold,
          opacity: opacity,
          spacing: 2,
        );
      }
      _text(
        c,
        boss.age > 3.5
            ? boss.isMoth
                  ? 'DODGE THE FANS  ·  FIRE WHEN THE VEIL DROPS'
                  : 'GET READY  ·  FLAP, DODGE, FIRE'
            : 'Your bird is coasting safely',
        Offset(w * .5, h * .84),
        h * .028,
        BossRig.cream,
        opacity: m.focus,
        centered: true,
        spacing: 1,
      );
    } else if (m.defeated && m.death > 1.55) {
      final show = BossMotion.ease(BossMotion.ramp(m.death, 1.55, 2.05));
      final fade = show * (1 - BossMotion.ramp(m.death, 3.3, 3.8));
      final y = h * (.3 + (m.reducedMotion ? 0 : (1 - show) * .025));
      _text(
        c,
        'SKY RECLAIMED',
        Offset(w * .5, y),
        h * .075,
        BossRig.cream,
        centered: true,
        opacity: fade,
        shadow: true,
      );
      c.drawLine(
        Offset(w * .34, y + h * .105),
        Offset(w * .66, y + h * .105),
        _line(_gold, h * .003, fade),
      );
      _text(
        c,
        sim.isTrail
            ? '+${FlightSimulation.bossBonus} POINTS   ·   SHIELD RESTORED'
            : '${boss.name.toUpperCase()} DEFEATED',
        Offset(w * .5, y + h * .135),
        h * .03,
        _gold,
        centered: true,
        opacity: fade,
        spacing: 1,
      );
      _text(
        c,
        'Back to the open sky',
        Offset(w * .5, h * .84),
        h * .028,
        _ice,
        centered: true,
        opacity: fade,
      );
    }
  }

  static void healthBar(Canvas c, Size size, SkyBoss boss) {
    if (boss.inCutscene) return;
    final h = size.height, w = math.min(size.width * .40, h * .88);
    final x = (size.width - w) / 2, y = h * .035;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - h * .025, y, w + h * .05, h * .14),
        Radius.circular(h * .024),
      ),
      _fill(_night, .93),
    );
    _text(
      c,
      boss.name.toUpperCase(),
      Offset(x, y + h * .015),
      h * .028,
      BossRig.cream,
      spacing: 1.2,
    );
    _text(
      c,
      '${boss.hp} / ${boss.maxHp}',
      Offset(x + w, y + h * .015),
      h * .028,
      _gold,
      rightAligned: true,
    );
    final track = Rect.fromLTWH(x, y + h * .064, w, h * .024);
    c.drawRRect(
      RRect.fromRectAndRadius(track, Radius.circular(h * .008)),
      _fill(plumTrack),
    );
    final lag =
        1 -
        BossMotion.ease(BossMotion.ramp(boss.age - boss.lastHitAt, .06, .45));
    c.drawRect(
      Rect.fromLTWH(
        x,
        track.top,
        w * ((boss.hp + boss.lastDamage * lag) / boss.maxHp).clamp(0, 1),
        track.height,
      ),
      _fill(BossRig.cream, .8),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, track.top, w * boss.hp / boss.maxHp, track.height),
        Radius.circular(h * .008),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: boss.shielded
              ? [DuskMothBossRig.veil, DuskMothBossRig.silk]
              : boss.enraged
              ? [BossRig.ember, const Color(0xffffb270)]
              : boss.isMoth
              ? [DuskMothBossRig.coral, DuskMothBossRig.pollen]
              : boss.isSpitter
              ? [SpitterBossRig.acid, SpitterBossRig.mint]
              : [_gold, const Color(0xffffecad)],
        ).createShader(track),
    );
    final segments = math.min(boss.maxHp, 24);
    for (var i = 1; i < segments; i++) {
      final tick = x + w * i / segments;
      c.drawLine(
        Offset(tick, track.top + 1),
        Offset(tick, track.bottom - 1),
        _line(_night, 1, .4),
      );
    }
    _text(
      c,
      boss.isMoth
          ? boss.shieldHint
          : boss.enraged
          ? (boss.isSpitter
                ? 'FURY  ·  Five-shot acid fans'
                : 'FURY  ·  Faster volleys')
          : boss.isSpitter
          ? 'Dodge the acid fans. Shoot the shell.'
          : 'Aim for the armor. Watch the charge.',
      Offset(size.width / 2, y + h * .106),
      h * .023,
      boss.isMoth && (boss.shielded || boss.shieldWarning > 0)
          ? DuskMothBossRig.veil
          : boss.enraged
          ? BossRig.ember
          : _ice,
      centered: true,
    );
  }

  static const plumTrack = Color(0xff48415d);

  static void _text(
    Canvas c,
    String value,
    Offset at,
    double size,
    Color color, {
    bool centered = false,
    bool rightAligned = false,
    bool shadow = false,
    double opacity = 1,
    double spacing = 0,
  }) {
    if (opacity <= 0) return;
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: heading(size, color: color.withValues(alpha: opacity)).copyWith(
          letterSpacing: spacing,
          shadows: shadow
              ? [
                  Shadow(
                    color: _night.withValues(alpha: opacity * .8),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      c,
      at -
          Offset(
            centered
                ? painter.width / 2
                : rightAligned
                ? painter.width
                : 0,
            0,
          ),
    );
  }
}
