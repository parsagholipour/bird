import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'boss_rig.dart';
import 'spitter_boss_rig.dart';
import 'dusk_moth_boss_rig.dart';
import 'pirate_boss_rig.dart';
import 'pirate_sea_art.dart';
import 'pirate_ship_art.dart';
import 'boss_ammo_art.dart';
import 'boss_health_bar_art.dart';
import 'sky_scenery.dart';

abstract final class BossEncounterArt {
  static const _night = Color(0xff171c39), _lilac = Color(0xffbea9f3);
  static const _gold = Color(0xffffd878), _ice = Color(0xffb4f6ea);
  static Color _tint(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => _lilac,
    BossKind.spitterBeetle => SpitterBossRig.acid,
    BossKind.duskMoth => DuskMothBossRig.coral,
    BossKind.pirate => PirateBossRig.sea,
  };
  static Color _ammoColor(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => BossRig.ember,
    BossKind.spitterBeetle => SpitterBossRig.acid,
    BossKind.duskMoth => DuskMothBossRig.pollen,
    BossKind.pirate => PirateBossRig.flame,
  };
  static Color _light(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => _gold,
    BossKind.spitterBeetle => SpitterBossRig.mint,
    BossKind.duskMoth => DuskMothBossRig.silk,
    BossKind.pirate => PirateBossRig.flameCore,
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
    if (boss.isPirate) {
      _seaMood(c, size, boss, m);
      return;
    }
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

  /// A moonlit sea haze for the pirate: mist banks rolling in low over the
  /// water, gulls wheeling far off and a storm flash as the ship arrives.
  static void _seaMood(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    final h = size.height, w = size.width;
    final storm = m.storm;
    final sea = boss.waterLevel ?? SkyBoss.seaHidden;
    final t = m.reducedMotion ? 0.0 : boss.age;
    // Mist banks drift left above the sea line.
    for (var i = 0; i < 6; i++) {
      final span = w + h;
      final x = ((i * .31 * span - t * h * (.02 + i % 3 * .008)) % span + span) % span - h * .5;
      final y = (math.min(sea, .92) - .06 - (i % 3) * .07) * h;
      final bank = Rect.fromCenter(
        center: Offset(x, y),
        width: h * (.9 + (i % 2) * .5),
        height: h * (.07 + (i % 3) * .02),
      );
      c.drawOval(
        bank,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _ice.withValues(alpha: storm * (.13 - (i % 3) * .025)),
              _ice.withValues(alpha: 0),
            ],
          ).createShader(bank),
      );
    }
    // Gulls glide far off over the swell.
    for (var i = 0; i < 4; i++) {
      final drift = t * h * (.03 + i * .006);
      final x = ((w * (.22 + i * .23) - drift) % (w + h * .2) + w + h * .2) %
              (w + h * .2) -
          h * .1;
      final y = h * (.2 + (i % 2) * .09 + math.sin(t * .7 + i) * .012);
      final flap = m.reducedMotion ? .5 : math.sin(t * (3.4 + i * .5) + i);
      final span = h * (.016 + (i % 2) * .005);
      final gull = Path()
        ..moveTo(x - span, y - span * .3 * flap)
        ..quadraticBezierTo(x - span * .45, y - span * (.5 + .2 * flap), x, y)
        ..quadraticBezierTo(x + span * .45, y - span * (.5 + .2 * flap), x + span, y - span * .3 * flap);
      c.drawPath(gull, _line(_night, h * .004, storm * .38));
    }
    if (m.arriving && !m.reducedMotion) {
      final bolt = BossMotion.pulse(boss.age - 1.28, .38);
      if (bolt > 0) {
        final x = (w / h - .5) * h;
        final path = Path()
          ..moveTo(x + h * .18, -h * .05)
          ..lineTo(x + h * .05, h * .13)
          ..lineTo(x + h * .11, h * .14)
          ..lineTo(x - h * .04, h * .34);
        c.drawPath(path, _line(_ice, h * .024, bolt * .18));
        c.drawPath(path, _line(BossRig.cream, h * .004, bolt * .75));
      }
    }
  }

  static void paint(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss, h = size.height;
    if (boss.isPirate) {
      _paintPirate(c, size, sim, m);
      return;
    }
    final ammoLight = _light(boss);
    final center = Offset(boss.x * h, boss.y * h) + m.offset * h;
    for (final ammo in sim.bossAmmo) {
      BossAmmoArt.shot(
        c,
        h,
        ammo,
        boss,
        seconds: sim.elapsed,
        reducedMotion: m.reducedMotion,
      );
    }
    if (m.roar > 0) _roar(c, center, h, m);
    final pulse = math.max(m.rage, m.summon);
    if (pulse > 0 && !m.defeated) {
      // Fury and summons: one clear ring that swells with the pulse.
      final color = m.rage > m.summon ? BossRig.ember : _gold;
      final rect = Rect.fromCenter(
        center: center,
        width: h * (.34 + pulse * .26),
        height: h * (.25 + pulse * .15),
      );
      c.drawOval(rect, _line(BossRig.ink, h * .011, pulse * .28));
      c.drawOval(rect, _line(color, h * .006, pulse * .8));
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
      } else if (m.defeated) {
        // The killing blow flashes white, then the body overloads with light
        // until it bursts, so the boss never simply fades out.
        final blow = 1 - BossMotion.ramp(m.death, .03, .12);
        final overload = BossMotion.ease(BossMotion.ramp(m.death, .4, .84));
        final white = math.max(blow, overload * .92);
        if (white > .01) layer.colorFilter = _whiten(white);
      }
      c.saveLayer(const Rect.fromLTWH(-3, -2.3, 6, 4), layer);
      if (boss.isMoth) {
        DuskMothBossRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
      } else if (boss.isSpitter) {
        SpitterBossRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
      } else {
        BossRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
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
    // In front of the rig: the Baron's wing would otherwise hide the orb.
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

  /// The Pirate Captain's stage: the swell behind his ship, the ship itself
  /// anchored to the sea, the captain on deck (the only part with character
  /// motion), the cannon aimed exactly along the next launch, then the sea
  /// in front of the hull and the tide's warning over everything.
  static void _paintPirate(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
  ) {
    final boss = m.boss, h = size.height;
    final unit = h * SkyBoss.radius;
    final ship = Offset(boss.x * h, boss.y * h);
    final center = ship + m.offset * h;
    final shot = boss.cannonShot(FlightSimulation.birdX, sim.birdY);
    final lookY = (sim.birdY - boss.y) * 3;
    PirateSeaArt.back(c, size, sim, boss, m);
    // Ship and captain sail in as one silhouette out of the dusk.
    final silhouette = m.silhouette > .01;
    if (silhouette) {
      c.saveLayer(
        Rect.fromLTRB(
          ship.dx + PirateShipArt.bounds.left * unit,
          ship.dy + PirateShipArt.bounds.top * unit,
          ship.dx + PirateShipArt.bounds.right * unit,
          ship.dy + PirateShipArt.bounds.bottom * unit,
        ),
        Paint()
          ..colorFilter = ColorFilter.mode(
            _night.withValues(alpha: m.silhouette * .97),
            BlendMode.srcATop,
          ),
      );
    }
    c.save();
    c.translate(ship.dx, ship.dy);
    c.scale(unit);
    PirateShipArt.back(c, boss, m);
    c.restore();
    final (_, fuse) = PirateShipArt.fuse(shot.angle);
    const deck = PirateShipArt.rail;
    void captainFrame() {
      // Planted on the deck: he leans, puffs up and squashes about his
      // feet, so the character motion never lifts him off the ship.
      final grow = 1 + (m.bodyScale - 1) * .45;
      c.translate(center.dx, center.dy);
      c.scale(unit);
      c.translate(0, deck);
      c.rotate(m.rotation * .5);
      c.scale(grow * (1 + m.stretch * .6), grow * (1 - m.stretch * .6));
      c.translate(0, -deck);
    }

    if (m.opacity > 0) {
      c.save();
      captainFrame();
      final layer = Paint()
        ..color = const Color(0xffffffff).withValues(alpha: m.opacity);
      if (m.defeated && !silhouette) {
        final blow = 1 - BossMotion.ramp(m.death, .03, .12);
        final overload = BossMotion.ease(BossMotion.ramp(m.death, .4, .84));
        final white = math.max(blow, overload * .92);
        if (white > .01) layer.colorFilter = _whiten(white);
      }
      c.saveLayer(PirateBossRig.bounds, layer);
      PirateBossRig.paint(
        c,
        boss,
        m,
        lookY: lookY,
        fuse: fuse - m.offset * h / unit,
        parrot: !m.defeated || m.death < .3,
      );
      c.restore();
      c.restore();
    }
    c.save();
    c.translate(ship.dx, ship.dy);
    c.scale(unit);
    PirateShipArt.front(c, boss, m, aim: shot.angle);
    c.restore();
    if (silhouette) c.restore();
    c.save();
    c.translate(ship.dx, ship.dy);
    c.scale(unit);
    PirateShipArt.lights(c, boss, m);
    c.restore();
    if (m.silhouette > .25) {
      // One eye glints out of the silhouette; the other is patched.
      c.save();
      captainFrame();
      c.drawOval(
        Rect.fromCenter(
          center: PirateBossRig.eyeCenter,
          width: .26,
          height: .09,
        ),
        _fill(_gold, m.silhouette),
      );
      c.restore();
    }
    PirateShipArt.blast(
      c,
      h,
      boss,
      m,
      muzzle: Offset(shot.x * h, shot.y * h),
      aim: shot.angle,
    );
    for (final ammo in sim.bossAmmo) {
      BossAmmoArt.shot(
        c,
        h,
        ammo,
        boss,
        seconds: sim.elapsed,
        reducedMotion: m.reducedMotion,
      );
    }
    PirateSeaArt.front(
      c,
      size,
      sim,
      boss,
      m,
      bowX: boss.x + (PirateShipArt.bow + .12) * SkyBoss.radius,
      sternX: boss.x + (PirateShipArt.stern - .22) * SkyBoss.radius,
    );
    PirateSeaArt.splashes(c, size, sim, boss, m);
    PirateSeaArt.hullKnocks(c, h, sim, boss, m);
    if (m.roar > 0) {
      _roar(c, center, h, m);
      _shout(c, center, h, m);
    }
    if (m.rage > 0 && !m.defeated) {
      final rect = Rect.fromCenter(
        center: center,
        width: h * (.34 + m.rage * .26),
        height: h * (.25 + m.rage * .15),
      );
      c.drawOval(rect, _line(BossRig.ink, h * .011, m.rage * .28));
      c.drawOval(rect, _line(BossRig.ember, h * .006, m.rage * .8));
    }
    if (m.hit > 0 && !m.defeated) {
      final t = BossMotion.ramp(boss.age - boss.lastHitAt, 0, .32);
      _burst(c, center + Offset(-h * .06, -h * .02), h, t, 9, .08, m.reducedMotion);
    }
    if (m.defeated) {
      _wreck(c, ship, h, m);
      _death(c, center, h, m);
      _parrotFlees(c, center, h, m);
    }
    PirateSeaArt.aimMarks(c, size, sim, boss, m);
    PirateSeaArt.tideWarning(c, size, sim, boss, m);
  }

  /// "ARRR!" bursts out of the captain in a jagged speech bubble.
  static void _shout(Canvas c, Offset center, double h, BossMotion m) {
    final pop = m.reducedMotion
        ? 1.0
        : _outBack(BossMotion.ramp(m.boss.age - SkyBoss.roarAt, 0, .22));
    final fade = BossMotion.ramp(m.roar, 0, .25);
    if (pop <= 0 || fade <= 0) return;
    final unit = h * SkyBoss.radius;
    final at = center + Offset(-unit * 1.9, -unit * 1.55);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(unit * pop);
    c.rotate(-.12);
    final bubble = Path();
    for (var i = 0; i < 18; i++) {
      final a = i * math.pi / 9;
      final r = i.isEven ? 1.0 : .8;
      final p = Offset(math.cos(a) * r * 1.02, math.sin(a) * r * .66);
      i == 0 ? bubble.moveTo(p.dx, p.dy) : bubble.lineTo(p.dx, p.dy);
    }
    bubble.close();
    final tail = Path()
      ..moveTo(.25, .45)
      ..lineTo(1.05, 1.15)
      ..lineTo(.62, .3)
      ..close();
    c.drawPath(tail, _line(BossRig.ink, .12, fade)..strokeJoin = StrokeJoin.round);
    c.drawPath(bubble, _line(BossRig.ink, .12, fade)..strokeJoin = StrokeJoin.round);
    c.drawPath(tail, _fill(BossRig.cream, fade));
    c.drawPath(bubble, _fill(BossRig.cream, fade));
    c.restore();
    _text(
      c,
      'ARRR!',
      at + Offset(0, unit * .02),
      unit * .62 * pop,
      const Color(0xffc53b4d),
      opacity: fade,
      centered: true,
      middle: true,
      outline: unit * .1 * pop,
    );
  }

  /// After the burst the hull splits and the wreck goes down with the sea:
  /// splinters fly from the break and bubbles rise where it sank.
  static void _wreck(Canvas c, Offset ship, double h, BossMotion m) {
    final k = m.death - SkyBoss.burstAt;
    if (k < 0) return;
    final unit = h * SkyBoss.radius;
    final seam = ship + Offset(.95 * unit, PirateShipArt.rail * unit);
    final t = BossMotion.ramp(k, 0, 1.1);
    if (t < 1) {
      for (var i = 0; i < 14; i++) {
        final a = -math.pi / 2 + (i - 6.5) * .3;
        final v = h * (.3 + (i % 4) * .08);
        final life = m.reducedMotion ? .3 : t * 1.1;
        final p = seam +
            Offset(math.cos(a) * v * life, math.sin(a) * v * life + h * .9 * life * life);
        final fade = 1 - t;
        c.save();
        c.translate(p.dx, p.dy);
        c.rotate(a + (m.reducedMotion ? 0 : life * (6 + i)));
        final plank = Rect.fromCenter(
          center: Offset.zero,
          width: h * (.018 + (i % 3) * .006),
          height: h * .0065,
        );
        c.drawRect(plank.inflate(h * .0018), _fill(const Color(0xff3f2119), fade));
        c.drawRect(plank, _fill(const Color(0xffa8683f), fade));
        c.restore();
      }
    }
    final level = m.boss.waterLevel;
    if (level == null || m.reducedMotion) return;
    // Bubbles boil up where the halves went under.
    for (var i = 0; i < 10; i++) {
      final life = (k * 1.4 + i / 10) % 1;
      final fade = BossMotion.ramp(k, .5, .9) * (1 - BossMotion.ramp(k, 2.2, 2.9));
      if (fade <= 0) continue;
      final x = ship.dx + ((i * .37) % 1 - .5) * unit * 4;
      final y = level * h + h * .12 * (1 - life);
      if (y < level * h) continue;
      c.drawCircle(
        Offset(x, y),
        h * (.004 + (i % 3) * .002),
        _line(PirateSeaArt.foam, h * .002, fade * (1 - life)),
      );
    }
  }

  /// The parrot has had enough: it takes off and flaps away up and out of
  /// the fight, squawking.
  static void _parrotFlees(Canvas c, Offset center, double h, BossMotion m) {
    final t = m.death - .3;
    if (t < 0) return;
    final unit = h * SkyBoss.radius;
    final fade = 1 - BossMotion.ramp(t, m.reducedMotion ? .6 : 1.6, m.reducedMotion ? 1 : 2.2);
    if (fade <= 0) return;
    final start = center + PirateBossRig.parrotAnchor * unit;
    final travel = m.reducedMotion ? .15 : t;
    final at = start +
        Offset(unit * (1.6 * travel + .4 * travel * travel), -unit * (2.4 * travel - .3 * math.sin(travel * 9)));
    final flap = m.reducedMotion ? .6 : .5 + .5 * math.sin(t * 24);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(unit);
    c.rotate(-.35);
    c.saveLayer(PirateBossRig.parrotBounds.inflate(.4), _fill(const Color(0xffffffff), fade));
    PirateBossRig.paintParrot(
      c,
      time: m.reducedMotion ? 0 : m.boss.age,
      squawk: .5 + .5 * math.sin(t * 7).abs(),
      flap: flap,
      flying: true,
    );
    c.restore();
    c.restore();
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
    BossAmmoArt.paint(
      c,
      center: at,
      radius: boss.isSpitter ? r * (.85 + charge * .15) : r,
      direction: math.pi,
      attack: EnemyAttack.none,
      kind: boss.kind,
      enraged: boss.enraged,
      seconds: seconds,
      reducedMotion: m.reducedMotion,
      showTrail: false,
    );
  }

  /// The roar: rings of breath and speed lines burst off the silhouette.
  static void _roar(Canvas c, Offset center, double h, BossMotion m) {
    final boss = m.boss;
    final light = _light(boss), tint = _tint(boss);
    if (m.reducedMotion) {
      c.drawOval(
        Rect.fromCenter(center: center, width: h * .62, height: h * .46),
        _line(light, h * .006, m.roar * .6),
      );
      return;
    }
    final k = boss.age - SkyBoss.roarAt;
    for (var i = 0; i < 3; i++) {
      final u = BossMotion.ramp(k, i * .13, .5 + i * .13);
      if (u <= 0 || u >= 1) continue;
      final e = _outCubic(u);
      final rect = Rect.fromCenter(
        center: center,
        width: h * (.32 + e * .5),
        height: h * (.24 + e * .38),
      );
      final fade = 1 - u;
      final width = h * .009 * (1 - u * .6);
      c.drawOval(rect, _line(_night, width * 1.9, fade * .22));
      c.drawOval(
        rect,
        _line(i.isEven ? BossRig.cream : light, width, fade * .85),
      );
    }
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7 + .2;
      final d = Offset(math.cos(a) * 1.25, math.sin(a));
      final from = h * (.25 + (i % 3) * .02 + m.roar * .05);
      final to = from + h * (.04 + (i % 2) * .03) * m.roar;
      c.drawLine(
        center + d * from,
        center + d * to,
        _line(Color.lerp(tint, BossRig.cream, .5)!, h * .005, m.roar * .8),
      );
    }
  }

  /// Converging light, a white-hot burst, a chunky smoke poof in the boss's
  /// colors, flung debris and twinkles, then the headwear tumbles free.
  static void _death(Canvas c, Offset at, double h, BossMotion m) {
    final t = m.death, boss = m.boss, reduced = m.reducedMotion;
    if (t < SkyBoss.burstAt) _overload(c, at, h, t, _light(boss), reduced);
    if (t >= SkyBoss.burstAt) {
      final k = t - SkyBoss.burstAt;
      if (!reduced) _shockwave(c, at, h, k, _light(boss), _tint(boss));
      _poof(c, at, h, k, boss.kind, reduced);
      if (boss.isSpitter) {
        _acidBurst(c, at, h, BossMotion.ramp(k, 0, 1.25), reduced);
      } else {
        _burst(
          c,
          at,
          h,
          BossMotion.ramp(k, 0, 1.3),
          boss.isMoth ? 22 : 26,
          .5,
          reduced,
          colors: boss.isMoth
              ? const [
                  DuskMothBossRig.coral,
                  DuskMothBossRig.pollen,
                  DuskMothBossRig.silk,
                ]
              : boss.isPirate
              ? const [PirateBossRig.gold, PirateBossRig.crimson, _gold]
              : const [BossRig.violet, _lilac, BossRig.plum],
          outlined: true,
          scales: boss.isMoth,
          coins: boss.isPirate,
        );
      }
      if (!reduced) _twinkles(c, at, h, k);
      _impact(c, at, h, k, reduced);
    }
    _headwear(c, at, h, m);
  }

  /// Before the burst: streaks of light rush into a brightening core.
  static void _overload(
    Canvas c,
    Offset at,
    double h,
    double t,
    Color light,
    bool reduced,
  ) {
    final gather = BossMotion.ramp(t, .22, SkyBoss.burstAt);
    if (gather <= 0) return;
    final pull = reduced ? .5 : BossMotion.ease(gather);
    final alpha = BossMotion.ease(BossMotion.ramp(t, .22, .45));
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 + .31;
      final d = Offset(math.cos(a), math.sin(a));
      final outer = h * (.33 - pull * .15 + (i % 2) * .03);
      final inner = outer - h * (.035 + (1 - pull) * .06);
      c.drawLine(
        at + d * outer,
        at + d * inner,
        _line(_night, h * .011, alpha * .3),
      );
      c.drawLine(
        at + d * outer,
        at + d * inner,
        _line(light, h * .0055, alpha),
      );
      c.drawLine(
        at + d * outer,
        at + d * inner,
        _line(BossRig.cream, h * .002, alpha),
      );
    }
    final core = h * (.05 + gather * .13);
    c.drawCircle(
      at,
      core,
      Paint()
        ..shader = RadialGradient(
          colors: [
            BossRig.cream.withValues(alpha: gather * .85),
            light.withValues(alpha: gather * .35),
            light.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: at, radius: core)),
    );
  }

  /// Two quick rings: gone before they can read as a portal.
  static void _shockwave(
    Canvas c,
    Offset at,
    double h,
    double k,
    Color light,
    Color tint,
  ) {
    for (var i = 0; i < 2; i++) {
      final u = BossMotion.ramp(k, i * .07, .42 + i * .12);
      if (u <= 0 || u >= 1) continue;
      final r = h * (.1 + _outCubic(u) * (.5 - i * .1));
      final fade = (1 - u) * (1 - u);
      c.drawCircle(
        at,
        r,
        _line(
          i == 0 ? BossRig.cream : light,
          h * (.026 - i * .01) * (1 - u),
          fade,
        ),
      );
      if (i == 0) {
        c.drawCircle(at, r * .93, _line(tint, h * .008 * (1 - u), fade * .8));
      }
    }
  }

  /// A hot cartoon starburst on the burst frame, matching small enemies.
  static void _impact(Canvas c, Offset at, double h, double k, bool reduced) {
    final u = k / (reduced ? .3 : .2);
    if (u >= 1) return;
    final size =
        h *
        (reduced
            ? .12 * (1 - u)
            : .15 *
                  (u < .3
                      ? 1 + .12 * math.sin(u / .3 * math.pi)
                      : 1 - _inQuad((u - .3) / .7)));
    if (size <= 0) return;
    final shape = Path();
    for (var i = 0; i < 20; i++) {
      final a = i * math.pi / 10 + .12;
      final r = size * (i.isEven ? 1 : (i % 4 == 1 ? .5 : .62));
      final p = at + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        shape.moveTo(p.dx, p.dy);
      } else {
        shape.lineTo(p.dx, p.dy);
      }
    }
    shape.close();
    c.drawPath(shape, _fill(SkyColors.yellow));
    c.drawPath(
      shape,
      _line(SkyColors.coralDeep, h * .006)..strokeJoin = StrokeJoin.round,
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(.58);
    c.translate(-at.dx, -at.dy);
    c.drawPath(shape, _fill(BossRig.cream));
    c.restore();
  }

  // Puff centers and radii in cloud units, shared with the small-enemy poof.
  static const _puffs = <(double, double, double)>[
    (0, 0, .64),
    (-.66, .06, .46),
    (-.4, -.46, .5),
    (.18, -.6, .5),
    (.7, -.22, .47),
    (.62, .4, .45),
    (.04, .54, .47),
    (-.52, .46, .4),
    (-.1, -.2, .52),
  ];

  static (Color, Color, Color) _smoke(BossKind kind) => switch (kind) {
    BossKind.baronBat => (
      const Color(0xff3b2d5e),
      const Color(0xffc5b2ee),
      const Color(0xfff6f0ff),
    ),
    BossKind.spitterBeetle => (
      const Color(0xff21453d),
      const Color(0xffa6e6c3),
      const Color(0xffecfff1),
    ),
    BossKind.duskMoth => (
      const Color(0xff5c3a56),
      const Color(0xffefc2b3),
      const Color(0xfffff2e7),
    ),
    // Gunpowder smoke.
    BossKind.pirate => (
      const Color(0xff2f3444),
      const Color(0xffb7bfcc),
      const Color(0xfff6f3ec),
    ),
  };

  /// Overlapping puffs share one outline: rims first, then shadowed bodies,
  /// then lit tops. They pop in with an overshoot, billow, rise and thin out.
  static void _poof(
    Canvas c,
    Offset at,
    double h,
    double k,
    BossKind kind,
    bool reduced,
  ) {
    if (k >= 1.5) return;
    final unit = h * SkyBoss.radius * 1.3;
    final (line, shade, light) = _smoke(kind);
    final count = _puffs.length;
    final centers = List.filled(count, Offset.zero);
    final radii = List.filled(count, 0.0);
    var evaporate = 0.0;
    for (var i = 0; i < count; i++) {
      final (px, py, pr) = _puffs[i];
      var grow = 1.0, fade = 0.0, billow = .5;
      if (!reduced) {
        final born = k - i * .014;
        if (born < 0) continue;
        grow = .35 + .65 * _outBack(born / .18);
        billow = _outQuad(k / 1.5);
        final start = .45 + .3 * ((i * .618) % 1);
        fade = BossMotion.ramp(k, start, 1.45);
      }
      final spread = (.55 + .45 * grow + .25 * billow) * (1 - .3 * fade);
      final float = _outQuad(fade);
      centers[i] =
          at +
          Offset(px, py) * unit * spread +
          Offset(((i * .37) % 1 - .5) * .6, -(.2 + .5 * ((i * .53) % 1))) *
              unit *
              float;
      radii[i] =
          pr * unit * grow * (1 + .1 * billow) * (1 - fade) * (1 + .35 * fade);
      evaporate = math.max(evaporate, fade);
    }
    // Reduced Motion: one settled cloud that only fades as a whole.
    final alpha = reduced ? 1 - BossMotion.ramp(k, .5, 1.45) : 1.0;
    if (alpha <= 0) return;
    if (reduced) {
      c.saveLayer(
        Rect.fromCircle(center: at, radius: unit * 2.2),
        _fill(const Color(0xffffffff), alpha),
      );
    }
    final rim = _fill(Color.lerp(line, shade, evaporate)!);
    final rimWidth = unit * .085 * (1 - .5 * evaporate);
    for (var i = 0; i < count; i++) {
      if (radii[i] > 1) c.drawCircle(centers[i], radii[i] + rimWidth, rim);
    }
    for (var i = 0; i < count; i++) {
      if (radii[i] > 1) c.drawCircle(centers[i], radii[i], _fill(shade));
    }
    for (var i = 0; i < count; i++) {
      final r = radii[i];
      if (r > 1) {
        c.drawCircle(
          centers[i] + Offset(-.15 * r, -.19 * r),
          r * .74,
          _fill(light),
        );
      }
    }
    if (reduced) c.restore();
  }

  /// Four-point glints pop around the cloud as it thins.
  static void _twinkles(Canvas c, Offset at, double h, double k) {
    for (var i = 0; i < 6; i++) {
      final u = BossMotion.ramp(k, .22 + i * .11, .55 + i * .11);
      if (u <= 0 || u >= 1) continue;
      final a = i * 2.2 + .6;
      final d = h * (.13 + (i % 3) * .045);
      _sparkle(
        c,
        at + Offset(math.cos(a), math.sin(a)) * d,
        h * (.018 + (i % 2) * .008) * math.sin(u * math.pi),
        1,
      );
    }
  }

  static void _sparkle(Canvas c, Offset at, double r, double alpha) {
    if (r <= 0 || alpha <= 0) return;
    final path = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx + r * .16, at.dy - r * .16, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx + r * .16, at.dy + r * .16, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx - r * .16, at.dy + r * .16, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx - r * .16, at.dy - r * .16, at.dx, at.dy - r)
      ..close();
    c.drawPath(
      path,
      _line(SkyColors.gold, r * .28, alpha)..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(path, _fill(SkyColors.yellow, alpha));
    c.drawCircle(at, r * .22, _fill(BossRig.cream, alpha));
  }

  // Each boss drops its own headwear during the defeat.
  static void _headwear(Canvas c, Offset at, double h, BossMotion m) {
    final t = m.death;
    if (t < .3 || t >= 2.7) return;
    final flight = t - .3;
    final travel = m.reducedMotion ? .45 : flight;
    final base = m.boss.isMoth
        ? DuskMothBossRig.crownAnchor * h * SkyBoss.radius
        : m.boss.isSpitter
        ? SpitterBossRig.hatAnchor * h * SkyBoss.radius
        : m.boss.isPirate
        ? PirateBossRig.hatAnchor * h * SkyBoss.radius
        : Offset(0, -h * .13);
    Offset path(double f) =>
        at + base + Offset(h * .11 * f, h * (-.31 * f + .28 * f * f));
    // Held still under Reduced Motion, the crown clears before the title.
    final fade = m.reducedMotion
        ? 1 - BossMotion.ramp(t, 1.2, 1.6)
        : 1 - BossMotion.ramp(t, 2.2, 2.7);
    if (fade <= 0) return;
    if (!m.reducedMotion && flight > .15) {
      // A short glint trail sells the arc of the tumble.
      for (var j = 1; j <= 3; j++) {
        final f = flight - j * .07;
        if (f <= .05) continue;
        _sparkle(c, path(f), h * (.014 - j * .003), fade * (1 - j * .26) * .9);
      }
    }
    var anchor = base;
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
    final origin = path(travel) - base + anchor;
    c.save();
    c.translate(origin.dx, origin.dy);
    c.scale(h * SkyBoss.radius * scale);
    c.rotate(rotation);
    c.scale(1 + stretch, 1 - stretch);
    if (m.boss.kind == BossKind.baronBat) c.translate(0, 1.22);
    c.saveLayer(
      m.boss.isMoth
          ? DuskMothBossRig.crownBounds.inflate(.1)
          : m.boss.isSpitter
          ? SpitterBossRig.hatBounds.inflate(.1)
          : m.boss.isPirate
          ? PirateBossRig.hatBounds.inflate(.1)
          : const Rect.fromLTWH(-1, -2, 2, 2),
      _fill(const Color(0xffffffff), fade),
    );
    if (m.boss.isMoth) {
      DuskMothBossRig.crown(c);
    } else if (m.boss.isSpitter) {
      SpitterBossRig.hat(c);
    } else if (m.boss.isPirate) {
      PirateBossRig.hat(c);
    } else {
      BossRig.crown(c);
    }
    c.restore();
    c.restore();
  }

  static void _acidBurst(
    Canvas c,
    Offset at,
    double h,
    double t,
    bool reduced,
  ) {
    if (t >= 1) return;
    final travel = reduced ? .4 : _outCubic(t);
    final fade = reduced ? 1 - t : 1 - _inQuad(t);
    // A pressure release sends droplets on arcs; the bubbles swell and pop.
    for (var i = 0; i < 18; i++) {
      final angle = i * 2.399963;
      final distance = h * (.05 + travel * (.17 + i % 4 * .055));
      final center =
          at +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + (reduced ? 0 : t * t * h * .22),
          );
      final radius = h * (.008 + i % 3 * .003) * (1 - t * .55);
      c.drawCircle(center, radius * 1.3, _fill(SpitterBossRig.ink, fade));
      c.drawCircle(center, radius, _fill(SpitterBossRig.acid, fade));
      c.drawCircle(
        center - Offset(radius * .3, radius * .3),
        radius * .34,
        _fill(SpitterBossRig.mint, fade),
      );
    }
    for (var i = 0; i < 6; i++) {
      final pop = (t * 1.3 - i * .045).clamp(0.0, 1.0);
      if (pop == 0 || pop == 1) continue;
      final a = i * math.pi / 3 + .4;
      final center =
          at +
          Offset(math.cos(a), math.sin(a)) *
              h *
              (reduced ? .17 : .08 + pop * .17);
      final radius = h * (reduced ? .025 : .012 + pop * .03);
      c.drawCircle(center, radius, _fill(SpitterBossRig.acid, (1 - pop) * .18));
      c.drawCircle(
        center,
        radius,
        _line(SpitterBossRig.mint, h * .003, 1 - pop),
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
    bool reduced, {
    List<Color> colors = const [_ice, _lilac],
    bool outlined = false,
    bool scales = false,
    bool coins = false,
  }) {
    if (t >= 1) return;
    final travel = reduced ? .45 : math.pow(t, .65).toDouble();
    final fade = outlined ? 1 - _inQuad(t) : 1 - t;
    final size = outlined ? 1.7 : 1.0;
    for (var i = 0; i < count; i++) {
      final a = i * 2.399963;
      final distance = h * (.025 + travel * reach * (.45 + (i % 7) / 12));
      // Wing scales drift and sway like leaves; heavier shards drop.
      final fall = reduced ? 0 : t * t * h * (scales ? .05 : .12);
      final sway = reduced || !scales ? 0 : math.sin(t * 9 + i) * h * .012;
      final pos =
          at +
          Offset(math.cos(a) * distance + sway, math.sin(a) * distance + fall);
      final r = h * (.0035 + (i % 4) * .0015) * (1 - t * .7) * size;
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(reduced ? a : a + t * (scales ? 3 : 5));
      final ink = _line(BossRig.ink, r * .45, fade)
        ..strokeJoin = StrokeJoin.round;
      if (i % 3 == 0) {
        final star = SkyScenery.star(Offset.zero, r * 1.6);
        if (outlined) c.drawPath(star, ink);
        c.drawPath(star, _fill(_gold, fade));
      } else {
        final color = colors[i % colors.length];
        if (coins) {
          // Spilled doubloons flip over as they fly.
          final coin = Rect.fromCenter(
            center: Offset.zero,
            width: r * 2.4 * (reduced ? .8 : .25 + .75 * math.cos(t * 14 + i).abs()),
            height: r * 2.4,
          );
          c.drawOval(coin.inflate(r * .3), ink);
          c.drawOval(coin, _fill(color, fade));
          c.drawOval(coin.deflate(r * .45), _line(const Color(0xffc9862b), r * .25, fade));
        } else if (scales) {
          final scale = Rect.fromCenter(
            center: Offset.zero,
            width: r * 2.6,
            height: r * 1.5,
          );
          c.drawOval(scale, ink);
          c.drawOval(scale, _fill(color, fade));
        } else {
          final shard = RRect.fromRectAndRadius(
            Rect.fromLTWH(-r, -r * .4, r * 2, r * .8),
            Radius.circular(r * .2),
          );
          if (outlined) c.drawRRect(shard, ink);
          c.drawRRect(shard, _fill(color, fade));
        }
      }
      c.restore();
    }
  }

  static double _outCubic(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u * u;
  }

  static double _outQuad(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u;
  }

  static double _inQuad(double t) {
    final u = t.clamp(0.0, 1.0);
    return u * u;
  }

  static double _outBack(double t) {
    final u = t.clamp(0.0, 1.0) - 1;
    return 1 + u * u * (2.7 * u + 1.7);
  }

  /// Fills blow out toward white while ink lines stay a readable grey.
  static ColorFilter _whiten(double w) {
    const k = 3.2, b = -90.0;
    final keep = 1 - w;
    return ColorFilter.matrix([
      keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b, //
      0, 0, 0, 1, 0,
    ]);
  }

  static void foreground(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
  ) {
    final h = size.height, w = size.width, boss = m.boss;
    if (m.defeated && !m.reducedMotion) {
      // One soft white frame on the burst; Reduced Motion skips the flash.
      final k = m.death - SkyBoss.burstAt;
      if (k >= 0 && k < .24) {
        final u = 1 - k / .24;
        c.drawRect(Offset.zero & size, _fill(BossRig.cream, .3 * u * u));
      }
    }
    final bar = h * .082 * m.focus;
    if (m.focus > 0) {
      c.drawRect(Rect.fromLTWH(0, 0, w, bar), _fill(_night, .95));
      c.drawRect(Rect.fromLTWH(0, h - bar, w, bar), _fill(_night, .95));
      for (final y in [bar, h - bar]) {
        c.drawLine(Offset(0, y), Offset(w, y), _line(_gold, 1, .28 * m.focus));
      }
    }
    String? caption;
    var captionColor = BossRig.cream;
    if (m.arriving) {
      if (boss.age < 1.55) {
        final fade =
            BossMotion.ease(BossMotion.ramp(boss.age, .15, .5)) *
            (1 - BossMotion.ramp(boss.age, 1.2, 1.55));
        _warning(c, size, boss, fade);
      } else {
        _nameCard(c, size, boss, m);
      }
      caption = boss.age > 3.5
          ? boss.isMoth
                ? 'DODGE THE FANS  ·  FIRE WHEN THE VEIL DROPS'
                : boss.isPirate
                ? 'DODGE THE CANNON  ·  STAY OUT OF THE WATER'
                : 'GET READY  ·  FLAP, DODGE, FIRE'
          : 'Your bird is coasting safely';
      if (boss.age > 3.5) captionColor = _gold;
    } else if (m.defeated && m.death > 1.55) {
      _victory(c, size, sim, m);
      caption = 'Back to the open sky';
      captionColor = _ice;
    }
    // Captions sit inside the letterbox like film subtitles, always legible.
    if (caption != null && bar > h * .045) {
      _text(
        c,
        caption,
        Offset(w * .5, h - bar / 2),
        h * .028,
        captionColor,
        opacity: m.focus,
        centered: true,
        middle: true,
        spacing: 1,
      );
    }
  }

  static void _warning(Canvas c, Size size, SkyBoss boss, double fade) {
    if (fade <= 0) return;
    final h = size.height, w = size.width;
    final band = Rect.fromLTWH(0, h * .265, w, h * .165);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _night.withValues(alpha: 0),
            _night.withValues(alpha: .6 * fade),
            _night.withValues(alpha: .6 * fade),
            _night.withValues(alpha: 0),
          ],
          stops: const [.08, .32, .68, .92],
        ).createShader(band),
    );
    final title = _text(
      c,
      boss.isMoth
          ? 'TWILIGHT TAKES WING'
          : boss.isSpitter
          ? 'SOMETHING IS BREWING'
          : boss.isPirate
          ? 'SAIL HO!'
          : 'A SHADOW APPROACHES',
      Offset(w * .5, h * .29),
      h * .045,
      _gold,
      opacity: fade,
      centered: true,
      spacing: 2.5,
    );
    // Flanking diamonds and hairlines frame the omen like a title card.
    final y = h * .29 + title.height / 2;
    for (final side in [-1.0, 1.0]) {
      final x = w * .5 + side * (title.width / 2 + h * .035);
      final d = h * .011;
      c.drawPath(
        Path()
          ..moveTo(x, y - d)
          ..lineTo(x + d, y)
          ..lineTo(x, y + d)
          ..lineTo(x - d, y)
          ..close(),
        _fill(_gold, fade),
      );
      c.drawLine(
        Offset(x + side * d * 2, y),
        Offset(x + side * h * .1, y),
        _line(_gold, h * .003, fade * .6),
      );
    }
    _text(
      c,
      boss.isMoth
          ? 'A silken veil gathers in the dusk…'
          : boss.isSpitter
          ? 'The air is starting to fizz…'
          : boss.isPirate
          ? 'The sea is rising under you…'
          : 'The sky belongs to someone else…',
      Offset(w * .5, h * .372),
      h * .028,
      BossRig.cream,
      opacity: fade,
      centered: true,
    );
  }

  static void _nameCard(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    final h = size.height, w = size.width;
    final progress = BossMotion.ease(BossMotion.ramp(boss.age, 1.65, 2.25));
    final opacity = progress * (1 - BossMotion.ramp(boss.age, 3.9, 4.5));
    if (opacity <= 0) return;
    final x = w * .10 - (m.reducedMotion ? 0 : (1 - progress) * h * .09);
    // A soft shade behind the card keeps it legible over any sky.
    final shade = Rect.fromLTRB(0, h * .1, w * .1 + h * .95, h * .385);
    c.drawRect(
      shade,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _night.withValues(alpha: .5 * opacity),
            _night.withValues(alpha: .34 * opacity),
            _night.withValues(alpha: 0),
          ],
          stops: const [0, .55, 1],
        ).createShader(shade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .03),
    );
    final top = h * .12;
    _text(
      c,
      'ENCOUNTER ${boss.number.toString().padLeft(2, '0')}',
      Offset(x, top),
      h * .03,
      _gold,
      opacity: opacity,
      spacing: 3,
    );
    c.drawLine(
      Offset(x, top + h * .065),
      Offset(
        x + h * .62 * (m.reducedMotion ? 1 : .4 + .6 * progress),
        top + h * .065,
      ),
      _line(_gold, h * .003, opacity * .65),
    );
    final name = _text(
      c,
      boss.name.toUpperCase(),
      Offset(x, top + h * .075),
      h * (boss.kind == BossKind.baronBat ? .091 : .08),
      BossRig.cream,
      opacity: opacity,
      shadow: true,
    );
    _text(
      c,
      boss.title,
      Offset(x + h * .003, top + h * .075 + name.height * .96),
      h * .026,
      _gold,
      opacity: opacity,
      spacing: 2,
    );
  }

  static void _victory(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
  ) {
    final h = size.height, w = size.width, boss = m.boss;
    final show = BossMotion.ease(BossMotion.ramp(m.death, 1.55, 2.05));
    final fade = show * (1 - BossMotion.ramp(m.death, 3.3, 3.8));
    if (fade <= 0) return;
    final y = h * (.27 + (m.reducedMotion ? 0 : (1 - show) * .025));
    final focus = Offset(w * .5, y + h * .06);
    // Warm rays open behind the title as the storm lifts.
    final turn = m.reducedMotion ? 0.0 : m.death * .12;
    final reach = h * (.3 + .22 * (m.reducedMotion ? 1 : show));
    final rays = Path();
    for (var i = 0; i < 16; i++) {
      final a = turn + i * math.pi / 8;
      final half = i.isEven ? .075 : .04;
      final r = reach * (i.isEven ? 1 : .72);
      rays
        ..moveTo(focus.dx, focus.dy)
        ..lineTo(
          focus.dx + math.cos(a - half) * r * 1.7,
          focus.dy + math.sin(a - half) * r,
        )
        ..lineTo(
          focus.dx + math.cos(a + half) * r * 1.7,
          focus.dy + math.sin(a + half) * r,
        )
        ..close();
    }
    final glow = Rect.fromCenter(
      center: focus,
      width: reach * 3.4,
      height: reach * 2,
    );
    c.drawPath(
      rays,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _gold.withValues(alpha: .26 * fade),
            _gold.withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    final title = _text(
      c,
      'SKY RECLAIMED',
      Offset(w * .5, y),
      h * .08,
      BossRig.cream,
      centered: true,
      opacity: fade,
      shadow: true,
      outline: h * .011,
    );
    for (var i = 0; i < 4; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final twinkle = m.reducedMotion
          ? 1.0
          : .55 + .45 * math.sin(m.death * 5 + i * 1.7);
      _sparkle(
        c,
        Offset(
          w * .5 + side * (title.width / 2 + h * (.035 + (i ~/ 2) * .03)),
          y + h * (i < 2 ? .02 : .075),
        ),
        h * (i < 2 ? .02 : .013) * twinkle,
        fade,
      );
    }
    final rule = y + title.height + h * .006;
    c.drawLine(
      Offset(w * .5 - title.width * .55, rule),
      Offset(w * .5 + title.width * .55, rule),
      _line(_gold, h * .003, fade),
    );
    _text(
      c,
      sim.isTrail
          ? '+${FlightSimulation.bossBonus} POINTS   ·   SHIELD RESTORED'
          : '${boss.name.toUpperCase()} DEFEATED',
      Offset(w * .5, rule + h * .025),
      h * .03,
      _gold,
      centered: true,
      opacity: fade,
      spacing: 1,
      outline: h * .008,
    );
  }

  /// The boss plate lives in BossHealthBarArt; kept here for callers that
  /// draw the cinematic encounter directly.
  static void healthBar(
    Canvas c,
    Size size,
    SkyBoss boss, {
    bool reducedMotion = false,
  }) => BossHealthBarArt.paint(c, size, boss, reducedMotion: reducedMotion);

  static const plumTrack = Color(0xff48415d);

  static Size _text(
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
    bool middle = false,
    double outline = 0,
  }) {
    if (opacity <= 0) return Size.zero;
    Offset place(TextPainter p) =>
        at -
        Offset(
          centered
              ? p.width / 2
              : rightAligned
              ? p.width
              : 0,
          middle ? p.height / 2 : 0,
        );
    if (outline > 0) {
      // A chunky ink outline keeps light titles legible over bright rays.
      final stroke = TextPainter(
        text: TextSpan(
          text: value,
          style: heading(size).copyWith(
            letterSpacing: spacing,
            foreground: _line(_night, outline, opacity * .9)
              ..strokeJoin = StrokeJoin.round,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      stroke.paint(c, place(stroke));
    }
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
    painter.paint(c, place(painter));
    return painter.size;
  }
}
