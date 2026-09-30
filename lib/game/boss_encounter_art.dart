import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../domain/campaign.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'baron_screech_art.dart';
import 'baron_storm_art.dart';
import 'baron_storm_pose.dart';
import 'boss_motion.dart';
import 'boss_rig.dart';
import 'spitter_boss_rig.dart';
import 'dusk_moth_boss_rig.dart';
import 'pirate_boss_rig.dart';
import 'dragon_boss_rig.dart';
import 'dragon_breath_art.dart';
import 'dragon_call_art.dart';
import 'dragon_encounter_ui.dart';
import 'dragon_fireball_art.dart';
import 'dragon_head_art.dart';
import 'dragon_kit.dart';
import 'dragon_layout.dart';
import 'dragon_pose.dart';
import 'pirate_encounter_ui.dart';
import 'pirate_mood_art.dart';
import 'pirate_parrot_art.dart';
import 'pirate_hull_art.dart';
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
    BossKind.dragon => DragonPalette.flame,
  };
  static Color _ammoColor(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => BossRig.ember,
    BossKind.spitterBeetle => SpitterBossRig.acid,
    BossKind.duskMoth => DuskMothBossRig.pollen,
    BossKind.pirate => PirateBossRig.flame,
    BossKind.dragon => DragonPalette.flame,
  };
  static Color _light(SkyBoss boss) => switch (boss.kind) {
    BossKind.baronBat => _gold,
    BossKind.spitterBeetle => SpitterBossRig.mint,
    BossKind.duskMoth => DuskMothBossRig.silk,
    BossKind.pirate => PirateBossRig.flameCore,
    BossKind.dragon => DragonPalette.flameGold,
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
    if (boss.isDragon) {
      // A smouldering sky: horizon glow, smoke banks and rising embers.
      // Every layer of it scales with the storm, which is in only after the
      // first tenth of a second: below that it is under a level of alpha and
      // the wash (a screen and a half of fill) is not worth its cost.
      if (m.storm >= .04) DragonEncounterUi.mood(c, size, boss, m);
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

  /// A moonlit sea haze for the pirate: a cool haze along the water, mist
  /// banks that gather with each surge, gulls wheeling far off, storm cloud
  /// along the top edge and the flash of a storm. See [PirateMoodArt].
  static void _seaMood(Canvas c, Size size, SkyBoss boss, BossMotion m) =>
      PirateMoodArt.paint(c, size, boss, m);

  static void paint(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss, h = size.height;
    if (boss.isPirate) {
      _paintPirate(c, size, sim, m);
      return;
    }
    if (boss.isDragon) {
      _paintDragon(c, size, sim, m);
      return;
    }
    final ammoLight = _light(boss);
    final center = Offset(boss.x * h, boss.y * h) + m.offset * h;
    // The upgraded Baron's screech warning and wall sit under everything.
    if (boss.screeches) BaronScreechArt.under(c, size, sim, m);
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
      c.saveLayer(
        // The queen's plumes, wings and tails reach farther than the others.
        boss.isMoth
            ? DuskMothBossRig.layerBounds
            : const Rect.fromLTWH(-3, -2.3, 6, 4),
        layer,
      );
      if (boss.isMoth) {
        DuskMothBossRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
      } else if (boss.isSpitter) {
        SpitterBossRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
      } else if (boss.screeches) {
        BaronStormRig.paint(c, boss, m, lookY: (sim.birdY - boss.y) * 3);
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
    // The upgraded Baron holds his fire for the screech.
    if (boss.charge > 0 && !m.defeated && !boss.screechQuiet) {
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
    if (boss.screeches) BaronScreechArt.over(c, size, sim, m);
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
    // Ship and captain sail in as one silhouette out of the dusk. Under
    // Reduced Motion the wreck fades where it would otherwise plunge.
    final silhouette = m.silhouette > .01;
    final fadeOut = m.defeated && m.reducedMotion
        ? 1 - BossMotion.ramp(m.death, .3, SkyBoss.burstAt)
        : 1.0;
    final veiled = silhouette || fadeOut < 1;
    if (veiled) {
      final layer = Paint()
        ..color = const Color(0xffffffff).withValues(alpha: fadeOut);
      if (silhouette) {
        layer.colorFilter = ColorFilter.mode(
          _night.withValues(alpha: m.silhouette * .97),
          BlendMode.srcATop,
        );
      }
      c.saveLayer(
        Rect.fromLTRB(
          ship.dx + PirateShipArt.bounds.left * unit,
          ship.dy + PirateShipArt.bounds.top * unit,
          ship.dx + PirateShipArt.bounds.right * unit,
          ship.dy + PirateShipArt.bounds.bottom * unit,
        ),
        layer,
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
    if (veiled) c.restore();
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
    // The warning sits under the cannonballs so they stay crisp in it.
    PirateSeaArt.tideWarning(c, size, sim, boss, m);
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
      PirateEncounterUi.shout(c, center, h, m);
    }
    if (m.rage > 0 && !m.defeated) PirateEncounterUi.rage(c, center, h, m);
    if (m.hit > 0 && !m.defeated) {
      final t = BossMotion.ramp(boss.age - boss.lastHitAt, 0, .32);
      PirateEncounterUi.hit(
        c,
        center + Offset(-h * .06, -h * .02),
        h,
        t,
        m.reducedMotion,
      );
    }
    if (m.defeated) {
      _wreck(c, ship, h, m);
      _death(c, center, h, m);
      _parrotFlees(c, center, h, m);
    }
    PirateSeaArt.aimMarks(c, size, sim, boss, m);
  }

  /// How the dragon is staged this frame: where its heart is, how its rig
  /// units (the hit radius) map to pixels, and how it is turned.
  ///
  /// In combat the heart is exactly the rules' (`boss.x`, `boss.y`), and the
  /// figure's own motion (bob, pitch, recoil, the sway of the beat) belongs
  /// to [DragonPose] alone: the generic mascot offset, rotation and stretch
  /// would carry its wings past the screen the parts were fitted to (and the
  /// stretch, which follows the rules' charge, pops at every launch). On
  /// arrival it looms past the
  /// camera as a silhouette and settles to its true size, level between the
  /// letterbox bars, as the lightning strikes (no blow lands during the
  /// arrival, so the rules' swoop-in is drawn out of it). In defeat it
  /// deflates instead of swelling, so its nose-down tail stays on screen.
  ///
  /// [nudge] is the body's own offset from the heart, for the dying dragon
  /// alone: pulled in from the screen's edge as its tail swings out, then
  /// rocked by the burst. The heart, and so every effect, stays put.
  static ({Offset heart, Offset nudge, double sx, double sy, double turn})
  dragonFrame(BossMotion m, double h) {
    final boss = m.boss, unit = h * SkyBoss.radius;
    var y = boss.y, grow = 1.0, turn = 0.0, nudge = Offset.zero;
    if (m.arriving) {
      // Between the bars it stands centred: the calm envelope (with the
      // roar's lift) reaches .075 units farther up than down.
      const centred = 0.075 * SkyBoss.radius;
      if (m.reducedMotion) {
        y = .5 + centred * dragonFocus(m);
      } else {
        const strike = DragonTimeline.arrivalFlashAt;
        final level = BossMotion.ease(BossMotion.ramp(boss.age, 1.35, strike));
        y = .5 + (boss.y - .5) * (1 - level) + centred * dragonFocus(m);
        grow =
            1 + .1 * math.sin(math.pi * BossMotion.ramp(boss.age, .95, strike));
        turn =
            -.11 *
            (1 - BossMotion.ease(BossMotion.ramp(boss.age, 1.2, strike)));
      }
    } else if (m.defeated) {
      // It deflates as it dies (never swells): the nose-down pitch swings the
      // tail toward the screen's edge, and this keeps it in.
      final sag = m.reducedMotion
          ? 1.0
          : BossMotion.ease(BossMotion.ramp(m.death, .05, .4));
      grow = math.min(1.0, 1 + (m.bodyScale - 1) * .35) * (1 - .06 * sag);
      turn = m.rotation * .4;
      final pull = m.reducedMotion
          ? .6
          : BossMotion.ease(BossMotion.ramp(m.death, .1, .5));
      nudge = Offset(-14 * h / 360 * pull, 0);
      final k = m.death - SkyBoss.burstAt;
      if (!m.reducedMotion && k >= 0) {
        // The burst rocks it: +-3 px at 3.5 Hz, dying away, and less while
        // the camera is shaking (the world pops with it).
        final a = 2 * math.pi * 3.5 * k;
        nudge +=
            Offset(math.sin(a), math.cos(a) * .7) *
            (3 * h / 360 * math.exp(-5 * k) * _underCamera(m));
      }
    }
    return (
      heart: Offset(boss.x * h, y * h),
      nudge: nudge,
      sx: unit * grow,
      sy: unit * grow,
      turn: turn,
    );
  }

  /// How much of its own shake the dragon shows: all of it, but only 0.4
  /// (its flashes 0.7) while the camera is shaking too. The shared camera scales the
  /// whole world by 1.018 on the first shaking frame and back on the last
  /// (`bird_game.dart`), so a local jolt on top would compound it. The breath's
  /// snap never meets it (the rules shake the camera for hits, fury, the roar
  /// and the burst only); a hit that lands in the same 0.3 s does.
  static double _underCamera(BossMotion m, [double shaken = .4]) =>
      m.shake == Offset.zero ? 1.0 : shaken;

  /// Where the dragon's rig origin is drawn: the heart, its own nudge and
  /// jolt, and 70% of any kick to the right taken back. The thump of the snap
  /// throws the body toward the screen's edge, where the tail already reaches
  /// at the ignite; this keeps the tail on screen (a pixel or two to spare)
  /// and the gem nearer the rules' heart, which the blow does not move.
  static Offset dragonBody(DragonPose pose, BossMotion m, double h) {
    final frame = dragonFrame(m, h);
    return frame.heart +
        frame.nudge +
        dragonRumble(pose, m, h) -
        Offset(math.max(0.0, pose.bob.dx) * .7 * frame.sx, 0);
  }

  /// The snap of the breath rocks the dragon itself (never the camera): about
  /// 3 px, mostly up and down (the tail already reaches the right edge at the
  /// ignite), at 27 Hz, dying with the pose's impact pulse. Pixels at the
  /// 360 px screen height.
  static Offset dragonRumble(DragonPose pose, BossMotion m, double h) {
    if (m.reducedMotion || pose.impact <= 0) return Offset.zero;
    final age = m.boss.age;
    return Offset(
          math.sin(age * 2 * math.pi * 27) * .35,
          math.cos(age * 2 * math.pi * 23),
        ) *
        (3 * h / 360 * pose.impact * _underCamera(m));
  }

  /// The arrival's silhouette on the dragon's own clock (1 is all shadow):
  /// it holds until the lightning strikes at [DragonTimeline.arrivalFlashAt],
  /// then the colour floods in over 0.12 s. Reduced Motion has no lightning
  /// to time it to: the reveal is a beat later and takes 0.25 s.
  static double dragonSilhouette(BossMotion m) {
    if (!m.arriving) return 0;
    final since =
        m.boss.age - DragonTimeline.arrivalFlashAt - (m.reducedMotion ? .1 : 0);
    final span = m.reducedMotion ? .25 : .12;
    return 1 - BossMotion.ease(BossMotion.ramp(since, 0, span));
  }

  /// The letterbox, 0 to 1, as the dragon's encounter draws it. The parts
  /// that read `focus` (the roar's plume, which climbs to the bars' edge) are
  /// handed this same clock.
  static double dragonFocus(BossMotion m) =>
      _DragonStageMotion(m.boss, reducedMotion: m.reducedMotion).focus;

  /// The circlet as the killing blow knocks it loose (0.3 s in), seen on
  /// screen in units of the dragon's radius: where the seat is from the
  /// heart, how it is turned and how large, all taken from the same pose and
  /// the same frame the dragon is drawn with, so the fall starts on the head.
  static ({Offset seat, double angle, double grow}) _crownDrop(bool reduced) {
    final boss = SkyBoss(
      number: 5,
      x: 0,
      kind: BossKind.dragon,
      cinematic: true,
    );
    boss.age = boss.arrivalDuration + 10;
    boss.defeatedAt = boss.age - .3;
    final frame = dragonFrame(
      BossMotion(boss, reducedMotion: reduced),
      1 / SkyBoss.radius,
    );
    final drop = DragonBossRig.crownDrop(.3, reduced: reduced);
    return (
      seat:
          DragonKit.turn(
            Offset(drop.at.dx * frame.sx, drop.at.dy * frame.sy),
            frame.turn,
          ) +
          frame.nudge,
      angle: drop.angle + frame.turn,
      grow: (frame.sx + frame.sy) / 2,
    );
  }

  static final _drops = (_crownDrop(false), _crownDrop(true));

  /// Whether the dragon has a title card of its own. Asked once, at the
  /// height of the hold; until it does, the shared card stands in.
  static final bool _ownCard = () {
    final boss = SkyBoss(
      number: 5,
      x: 0,
      kind: BossKind.dragon,
      cinematic: true,
    )..age = DragonTimeline.titleSlamAt + .5;
    final recorder = ui.PictureRecorder();
    final drew = DragonEncounterUi.nameCard(
      Canvas(recorder),
      const Size(800, 360),
      boss,
      BossMotion(boss, reducedMotion: false),
      birdY: .5,
    );
    recorder.endRecording().dispose();
    return drew;
  }();

  /// The lilac haze behind the arrival's silhouette on a dark sky: its alpha
  /// at night and how many radii of the dragon it spreads.
  static const _hazeAlpha = .65, _hazeReach = 6.5;

  /// The lightning that reveals the dragon: the world blanches (.45, fading
  /// over .25 s) behind the black silhouette, so the shape stands out at its
  /// starkest just before the colour floods in. Motion, so none under
  /// Reduced Motion, which cross-fades instead.
  static void _strike(Canvas c, Size size, BossMotion m) {
    if (m.reducedMotion || !m.arriving) return;
    const at = DragonTimeline.arrivalFlashAt;
    final since = m.boss.age - at;
    if (since < 0) return;
    final u = 1 - BossMotion.ramp(since, 0, .25);
    if (u > 0) {
      c.drawRect(
        Offset.zero & size,
        _fill(DragonPalette.flameCore, .45 * u * u),
      );
    }
  }

  /// The burst that ends it flashes the whole screen, over everything and
  /// under the letterbox: .55 fading over .18 s. Motion, so none under
  /// Reduced Motion.
  static void _burstFlash(Canvas c, Size size, BossMotion m) {
    if (m.reducedMotion || !m.defeated) return;
    final k = m.death - SkyBoss.burstAt;
    if (k < 0) return;
    final u = 1 - BossMotion.ramp(k, 0, .18);
    if (u > 0) {
      c.drawRect(
        Offset.zero & size,
        _fill(DragonPalette.flameCore, .55 * u * u),
      );
    }
  }

  /// The Ember Dragon's stage: the breath's warning under everything, the
  /// dragon itself (the arrival silhouette and the defeat's white-out are
  /// the only layers, bounded to it), the flame pouring from its jaws, the
  /// swarm call's cue, its fireballs and the one forming in its jaws, then
  /// the fire lines and tag over it all so the band's edge stays crisp.
  static void _paintDragon(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
  ) {
    final boss = m.boss, h = size.height;
    // A boss the clock has broken (NaN or infinite time or place) draws
    // nothing instead of throwing in a dozen of the parts.
    if (!boss.age.isFinite ||
        !boss.x.isFinite ||
        !boss.y.isFinite ||
        !size.isFinite ||
        (m.defeated && !m.death.isFinite)) {
      return;
    }
    final unit = h * SkyBoss.radius;
    final frame = dragonFrame(m, h);
    // The sky behind it lights it: its rim takes that region's bounce light
    // and works harder against a dark sky.
    final sky = SkyPalette.at(sim.elapsed);
    final light = DragonSkyLight.fromSky(
      top: sky.top,
      horizon: sky.horizon,
      haze: sky.haze,
    );
    // The eye follows the bird from the head's height (until it is dead,
    // when the circlet it drops starts from the head as the pose has it).
    final pose = DragonPose(
      boss,
      m,
      lookY: m.defeated ? 0 : (sim.birdY - frame.heart.dy / h + .22) * 3,
      light: light,
    );
    // Effects belong to the heart; the body (and what hangs on its jaws)
    // takes the nudges and the shakes.
    final center = frame.heart;
    final body = dragonBody(pose, m, h);
    Offset screen(Offset rig) =>
        body +
        DragonKit.turn(
          Offset(rig.dx * frame.sx, rig.dy * frame.sy),
          frame.turn,
        );
    final mouth = screen(DragonBossRig.mouthAt(pose));
    _strike(c, size, m);
    DragonBreathArt.warning(
      c,
      size,
      boss,
      m,
      mouth: mouth,
      seconds: sim.elapsed,
    );
    if (m.rage > 0 && !m.defeated) DragonEncounterUi.rage(c, center, h, m);
    // The dragon is gone by the burst (a tail still 70% there hung over the
    // supernova); under Reduced Motion it goes early, so the burst holds its
    // place.
    final opacity = !m.defeated
        ? m.opacity
        : m.reducedMotion
        ? math.min(m.opacity, 1 - BossMotion.ramp(m.death, .3, SkyBoss.burstAt))
        : math.min(m.opacity, 1 - BossMotion.ramp(m.death, .7, .86));
    if (opacity > 0) {
      final silhouette = dragonSilhouette(m);
      final night = BossMotion.ramp(light.dark, .2, .7);
      if (silhouette > .01 && night > 0) {
        // Against a violet or night sky the shadow needs an edge: a lilac
        // haze lifts the sky just behind it, most where the sky is darkest
        // (Cyberpunk, New York, and a little at Paris's dusk). It reaches
        // out past the far wing, which would otherwise melt into the city.
        DragonKit.glow(
          c,
          body + Offset(1.1 * frame.sx, -.5 * frame.sy),
          frame.sx * _hazeReach,
          _lilac,
          _hazeAlpha * silhouette * night,
        );
      }
      c.save();
      c.translate(body.dx, body.dy);
      c.rotate(frame.turn);
      c.scale(frame.sx, frame.sy);
      var white = 0.0;
      if (m.defeated) {
        final blow = 1 - BossMotion.ramp(m.death, .03, .12);
        final overload = BossMotion.ease(BossMotion.ramp(m.death, .4, .84));
        white = math.max(blow, overload * .92);
      }
      final layered = silhouette > .01 || white > .01 || opacity < 1;
      if (layered) {
        final layer = Paint()
          ..color = const Color(0xffffffff).withValues(alpha: opacity);
        if (silhouette > .01) {
          layer.colorFilter = ColorFilter.mode(
            _night.withValues(alpha: silhouette * .97),
            BlendMode.srcATop,
          );
        } else if (white > .01) {
          layer.colorFilter = _whiten(white);
        }
        c.saveLayer(DragonBossRig.bounds, layer);
      }
      DragonBossRig.paintPose(c, pose, crown: !m.defeated || m.death < .3);
      if (layered) c.restore();
      if (m.arriving) _kindle(c, pose, m, silhouette);
      c.restore();
    }
    DragonBreathArt.flame(c, size, boss, m, mouth: mouth, seconds: sim.elapsed);
    DragonBreathArt.inhale(c, h, boss, m, mouth: mouth);
    // The roar that calls the swarm: a cool cue over the dragon, under the
    // fireballs, the bats and the hint.
    if (pose.call > 0 && !m.defeated) {
      DragonCallArt.paint(
        c,
        mouth: mouth,
        center: center,
        h: h,
        call: pose.call,
        seconds: m.reducedMotion ? 0 : sim.elapsed,
        reducedMotion: m.reducedMotion,
        fury: boss.enraged,
        boss: boss,
        toward: Offset(size.width, sim.birdY * h),
      );
    }
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
    if (boss.charge > 0 && !m.defeated) {
      DragonFireballArt.charge(
        c,
        mouth: mouth,
        h: h,
        charge: boss.charge,
        seconds: sim.elapsed,
        reducedMotion: m.reducedMotion,
        fury: boss.enraged,
      );
    }
    final since = boss.age - boss.lastVolleyAt;
    if (since >= 0 && since < .4 && !m.defeated) {
      // Where the shot was born, not where the jaws have recoiled to, and
      // along the way it flies.
      DragonFireballArt.muzzle(
        c,
        mouth: Offset(boss.mouthX * h, boss.mouthY * h),
        h: h,
        tau: since,
        reducedMotion: m.reducedMotion,
        fury: boss.enraged,
        direction: sim.birdY.isFinite
            ? math.atan2(
                sim.birdY - boss.mouthY,
                FlightSimulation.birdX - boss.mouthX,
              )
            : math.pi,
      );
    }
    DragonBreathArt.marks(c, size, boss, m, mouth: mouth, seconds: sim.elapsed);
    if (m.roar > 0) {
      // The plume climbs to the underside of the letterbox: the one this
      // encounter draws, which opens for it.
      final stage = _DragonStageMotion(boss, reducedMotion: m.reducedMotion);
      DragonEncounterUi.roar(c, center, h, stage, mouth: mouth);
    }
    if (m.hit > 0 && !m.defeated) {
      final t = BossMotion.ramp(boss.age - boss.lastHitAt, 0, .36);
      DragonEncounterUi.hit(
        c,
        center + Offset(-h * .02, 0),
        h,
        t,
        reduced: m.reducedMotion,
        crit: boss.lastCoreHitAt == boss.lastHitAt,
      );
    }
    // White flashes on the dragon itself (the whole screen only ever flashes
    // for the lightning and the burst, see [_strike] and [_burstFlash]).
    final flash = dragonFlash(pose, m);
    if (flash > 0) {
      // A hot core over the body inside a wider bloom, so it reads at speed.
      DragonKit.glow(c, body, unit * 2.2, DragonPalette.flameCore, flash);
      DragonKit.glow(c, body, unit * 4.2, DragonPalette.flameCore, flash * .8);
    }
    if (m.defeated) _death(c, center, h, m);
  }

  /// The white glow over the dragon's body, 0 to 1: the snap of the breath
  /// (.35 for 0.06 s), the tipping into fury (.3 at 0.1 s) and the killing
  /// blow (the hit-stop, .55 to nothing in 0.12 s). Motion, so none under
  /// Reduced Motion.
  static double dragonFlash(DragonPose pose, BossMotion m) {
    if (m.reducedMotion) return 0;
    final boss = m.boss;
    // The snap: .35 for 0.06 s, from the pose's own impact pulse.
    var flash = .35 * BossMotion.ramp(pose.impact, math.exp(-9 * .06), 1);
    // Fury: a beat after the blow that tips it over, peaking at .1 s.
    final fury = boss.age - boss.enragedAt;
    if (!m.defeated && fury >= 0 && fury < .2) {
      flash = math.max(flash, .3 * (1 - (fury - .1).abs() / .1));
    }
    // The killing blow: the hit-stop, .55 down to nothing in 0.12 s.
    if (m.defeated) {
      flash = math.max(flash, .55 * (1 - BossMotion.ramp(m.death, 0, .12)));
    }
    // Less while the camera is shaking (the fury's roar, a hit).
    return flash * (m.defeated ? 1.0 : _underCamera(m, .7));
  }

  /// Out of the dark: one burning eye and the heart's glow. The eye wakes
  /// first, swelling from an ember to white-hot as the strike nears, and
  /// when the strike lands it flares (0.3 s) while the colour floods in
  /// around it.
  static void _kindle(
    Canvas c,
    DragonPose pose,
    BossMotion m,
    double silhouette,
  ) {
    final since = m.boss.age - DragonTimeline.arrivalFlashAt;
    final wake = m.reducedMotion
        ? 1.0
        : BossMotion.ease(BossMotion.ramp(since, -.35, 0));
    final eye = DragonBossRig.eyeAt(pose);
    final heart = pose.toRig(Offset.zero);
    if (silhouette > .25) {
      // It lights the dark around it as it wakes.
      DragonKit.glow(
        c,
        eye,
        .5 + .25 * wake,
        DragonPalette.flame,
        silhouette * wake * .45,
      );
      // A slit slanted like the brow it sits under.
      final width = .3 + .16 * wake;
      c.save();
      c.translate(eye.dx, eye.dy);
      c.rotate(-pose.head.angle - .24);
      final slit = Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: width * .34,
      );
      c.drawOval(
        slit,
        _fill(Color.lerp(DragonPalette.flame, _gold, wake)!, silhouette),
      );
      c.drawOval(
        slit.deflate(width * .07),
        _fill(DragonPalette.flameCore, silhouette * wake),
      );
      c.restore();
      DragonKit.glow(c, heart, .6, DragonPalette.flame, silhouette * .5);
      c.drawCircle(
        heart,
        .14,
        _fill(DragonPalette.flameYellow, silhouette * .9),
      );
    }
    if (!m.reducedMotion && since >= 0 && since < .3) {
      // The strike: a flare bursts from the eye with a streak through it.
      final u = since / .3;
      DragonKit.glow(
        c,
        eye,
        .35 + .9 * _outCubic(u),
        DragonPalette.flameCore,
        (1 - u) * (1 - u) * .8,
      );
      c.drawOval(
        Rect.fromCenter(
          center: eye,
          width: .5 + 2.6 * u,
          height: .05 * (1 - u),
        ),
        _fill(DragonPalette.flameCore, (1 - u) * .9),
      );
    }
  }

  /// After the burst the hull splits and the wreck goes down with the sea:
  /// spray, timbers, foam rings and bubbles where it sank (see
  /// [PirateHullArt.wreck]).
  static void _wreck(Canvas c, Offset ship, double h, BossMotion m) =>
      PirateHullArt.wreck(c, ship, h, m);

  /// The parrot has had enough: it crouches, throws out its wings, spins
  /// about and beats away up and out of the fight, squawking and shedding
  /// feathers (see [PirateParrotArt.flee]).
  static void _parrotFlees(Canvas c, Offset center, double h, BossMotion m) {
    final unit = h * SkyBoss.radius;
    PirateParrotArt.flee(
      c,
      from: center + PirateBossRig.parrotAnchor * unit,
      unit: unit,
      t: m.death - .3,
      reduced: m.reducedMotion,
    );
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
    if (m.boss.isPirate) {
      // Sea-spray shockwaves rolling off the captain like a ship's horn.
      PirateEncounterUi.roar(c, center, h, m);
      return;
    }
    final boss = m.boss;
    // The upgraded Baron's roar is his first screech.
    final light = boss.screeches ? BaronStormArt.sonic : _light(boss);
    final tint = boss.screeches ? BaronStormArt.sonic : _tint(boss);
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
      if (!reduced) {
        if (boss.isPirate) {
          PirateEncounterUi.shockwave(c, at, h, k);
        } else if (boss.isDragon) {
          DragonEncounterUi.shockwave(c, at, h, k);
        } else {
          _shockwave(c, at, h, k, _light(boss), _tint(boss));
        }
      }
      // The dragon's own burst (supernova, shards, ash) is all of it.
      if (!boss.isDragon) _poof(c, at, h, k, boss.kind, reduced);
      if (boss.isSpitter) {
        _acidBurst(c, at, h, BossMotion.ramp(k, 0, 1.25), reduced);
      } else if (boss.isDragon) {
        // Its fire escapes at once: burning scales, flame and embers, then
        // the ember snow that lingers.
        DragonEncounterUi.burst(c, at, h, BossMotion.ramp(k, 0, 1.3), reduced);
        DragonEncounterUi.emberSnow(c, at, h, k, reduced: reduced);
        // The heart-gem is freed, not destroyed: it pops loose, rises through
        // the smoke and ignites into a warm sun as the crown lands.
        DragonEncounterUi.victoryGem(c, at, h, k, reduced: reduced);
      } else if (boss.isPirate) {
        // The captain's hoard bursts: doubloons, silver, rubies and stars.
        PirateEncounterUi.treasure(
          c,
          at,
          h,
          BossMotion.ramp(k, 0, 1.3),
          reduced,
        );
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
              : const [BossRig.violet, _lilac, BossRig.plum],
          outlined: true,
          scales: boss.isMoth,
        );
      }
      if (!reduced && !boss.isDragon) _twinkles(c, at, h, k);
      if (!boss.isDragon) _impact(c, at, h, k, reduced);
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
      const Color(0xff2b2029),
      const Color(0xffa39aa6),
      const Color(0xfff3e9dd),
    ),
    // Ash and cinders.
    BossKind.dragon => (
      const Color(0xff2a1a2c),
      const Color(0xff8e7a8c),
      const Color(0xfff3e4dc),
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
    if (m.boss.isDragon) {
      _dragonCrown(c, at, h, m);
      return;
    }
    final t = m.death;
    if (t < .3 || t >= 2.7) return;
    final flight = t - .3;
    final travel = m.reducedMotion ? .45 : flight;
    final base = m.boss.isMoth
        ? DuskMothBossRig.crownAnchor * h * SkyBoss.radius
        : m.boss.isSpitter
        ? SpitterBossRig.crownAnchor * h * SkyBoss.radius
        : m.boss.isPirate
        ? PirateBossRig.hatAnchor * h * SkyBoss.radius
        : m.boss.isDragon
        ? DragonBossRig.crownAnchor * h * SkyBoss.radius
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
    var scale = m.boss.isDragon ? DragonHeadArt.scale : .9;
    var rotation = m.reducedMotion ? .25 : flight * 5.4;
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
          ? SpitterBossRig.crownBounds.inflate(.1)
          : m.boss.isPirate
          ? PirateBossRig.hatBounds.inflate(.1)
          : m.boss.isDragon
          ? DragonBossRig.crownBounds.inflate(.1)
          : m.boss.screeches
          ? BaronStormArt.crownBounds.inflate(.1)
          : const Rect.fromLTWH(-1, -2, 2, 2),
      _fill(const Color(0xffffffff), fade),
    );
    if (m.boss.isMoth) {
      DuskMothBossRig.crown(c);
    } else if (m.boss.isSpitter) {
      SpitterBossRig.crown(c);
    } else if (m.boss.isDragon) {
      DragonBossRig.crownPaint(c);
    } else if (m.boss.isPirate) {
      // The plume streams and flaps behind the tricorn as it spins away.
      PirateBossRig.hat(
        c,
        worn: false,
        sway: m.reducedMotion
            ? 0
            : math.sin(flight * 9) * .3 * BossMotion.ramp(flight, 0, .25),
        glint: m.reducedMotion
            ? 0
            : math.pow(math.sin(flight * 6).abs(), 8).toDouble(),
      );
    } else if (m.boss.screeches) {
      BaronStormArt.crown(c);
    } else {
      BossRig.crown(c);
    }
    c.restore();
    c.restore();
  }

  /// The circlet after the killing blow (0.3 s in): it leaves the slumped
  /// head from the seat, turn and size the head has, tumbles down, LANDS on
  /// the ground with a hop or two, settles a little askew and glints in the
  /// light of the victory sun rising over it, then clears with the title.
  /// Reduced Motion holds it near the head and clears it before the title.
  static void _dragonCrown(Canvas c, Offset at, double h, BossMotion m) {
    final t = m.death, reduced = m.reducedMotion;
    if (t < .3 || t >= (reduced ? 1.6 : 3.7)) return;
    final fade = reduced
        ? 1 - BossMotion.ramp(t, 1.2, 1.6)
        : 1 - BossMotion.ramp(t, 3.1, 3.6);
    if (fade <= 0) return;
    final drop = reduced ? _drops.$2 : _drops.$1;
    final unit = h * SkyBoss.radius;
    final seat = at + drop.seat * unit;
    final flight = t - .3;
    // Released from the seat the slumped head had: same place, turn and
    // size, then the tumble takes over.
    final attached = reduced
        ? 1.0
        : 1 - BossMotion.ease(BossMotion.ramp(flight, 0, .18));
    final scale = DragonHeadArt.scale * (1 + (drop.grow - 1) * attached);
    // Its rim rests on the ground; the origin is the band's centre.
    final ground = h * .865 - DragonHeadArt.crownBounds.bottom * unit * scale;
    const land = 1.25;
    // Thrown up and out as before, but heavy: gold falls faster than a bird.
    final gravity = (ground - seat.dy + .31 * h * land) / (land * land);
    final skid = h * .11 * land;
    Offset pos(double f) => f <= land
        ? seat + Offset(h * .11 * f, h * -.31 * f + gravity * f * f)
        : Offset(
            seat.dx + skid + h * .012 * (1 - math.exp(-5 * (f - land))),
            ground -
                h *
                    .028 *
                    math.exp(-7 * (f - land)) *
                    math.sin(2 * math.pi * 2.2 * (f - land)).abs(),
          );
    Offset origin;
    double rotation;
    if (reduced) {
      const f = .45;
      origin = seat + Offset(h * .11 * f, h * (-.31 * f + .28 * f * f));
      rotation = drop.angle + .25;
    } else {
      origin = pos(flight);
      // Spinning as it falls, it comes to rest tilted, upright-ish.
      const rest = .25;
      final turns = ((drop.angle + 5.4 * land - rest) / (2 * math.pi)).round();
      final target = rest + 2 * math.pi * turns;
      final blend = BossMotion.ease(BossMotion.ramp(flight, land - .45, land));
      final u = math.max(0.0, flight - land);
      rotation =
          (drop.angle + 5.4 * flight) * (1 - blend) +
          target * blend +
          .14 * math.exp(-8 * u) * math.sin(2 * math.pi * 3 * u);
      if (flight > .15 && flight < land) {
        // A short glint trail sells the arc of the tumble.
        for (var j = 1; j <= 3; j++) {
          final f = flight - j * .07;
          if (f <= .05) continue;
          _sparkle(c, pos(f), h * (.014 - j * .003), fade * (1 - j * .26) * .9);
        }
      }
      if (flight > land - .3) {
        // Its shadow finds the ground before it does.
        final near = BossMotion.ramp(flight, land - .3, land);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(origin.dx, h * .865 + unit * .05),
            width: unit * 1.5 * (.5 + .5 * near),
            height: unit * .2,
          ),
          _fill(DragonPalette.ink, .3 * near * fade),
        );
      }
    }
    if (!reduced && flight > land) {
      // The freed gem's light warms the gold where it lies.
      final u = flight - land;
      final warm =
          BossMotion.ramp(u, .3, .7) * (1 - BossMotion.ramp(u, 1.3, 1.8));
      DragonKit.glow(
        c,
        origin,
        unit * 1.8,
        DragonPalette.flameGold,
        .4 * warm * fade,
      );
    }
    c.save();
    c.translate(origin.dx, origin.dy);
    c.scale(unit * scale);
    c.rotate(rotation);
    c.saveLayer(
      DragonBossRig.crownBounds.inflate(.1),
      _fill(const Color(0xffffffff), fade),
    );
    DragonBossRig.crownPaint(c);
    c.restore();
    c.restore();
    if (!reduced && flight > land) {
      // Catching the light of the sun the freed gem lights (from 1.85 s, and
      // again as it dims): a twinkle at the ruby, twice.
      final u = flight - land;
      for (var i = 0; i < 2; i++) {
        final p = BossMotion.ramp(u, .3 + i * .7, .8 + i * .7);
        if (p <= 0 || p >= 1) continue;
        _sparkle(
          c,
          origin + Offset(unit * .05, -unit * .3),
          h * .022 * math.sin(p * math.pi),
          fade,
        );
      }
    }
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
        if (scales) {
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
    if (boss.isDragon) {
      if (!boss.age.isFinite || (m.defeated && !m.death.isFinite)) return;
      _burstFlash(c, size, m);
    } else if (m.defeated && !m.reducedMotion) {
      // One soft white frame on the burst; Reduced Motion skips the flash.
      final k = m.death - SkyBoss.burstAt;
      if (k >= 0 && k < .24) {
        final u = 1 - k / .24;
        c.drawRect(Offset.zero & size, _fill(BossRig.cream, .3 * u * u));
      }
    }
    final focus = boss.isDragon ? dragonFocus(m) : m.focus;
    final bar = h * .082 * focus;
    if (focus > 0) {
      c.drawRect(Rect.fromLTWH(0, 0, w, bar), _fill(_night, .95));
      c.drawRect(Rect.fromLTWH(0, h - bar, w, bar), _fill(_night, .95));
      for (final y in [bar, h - bar]) {
        c.drawLine(Offset(0, y), Offset(w, y), _line(_gold, 1, .28 * focus));
      }
    }
    String? caption;
    var captionColor = BossRig.cream;
    if (m.arriving) {
      if (boss.age < 1.55) {
        final fade =
            BossMotion.ease(BossMotion.ramp(boss.age, .15, .5)) *
            (1 - BossMotion.ramp(boss.age, 1.2, 1.55));
        if (boss.isPirate) {
          PirateEncounterUi.warning(c, size, boss, m, fade);
        } else {
          _warning(c, size, boss, fade);
        }
      } else if (boss.isPirate) {
        // A parchment scroll unrolls with the name and a crimson title
        // ribbon, turning see-through where the bird flies behind it.
        PirateEncounterUi.nameCard(
          c,
          size,
          boss,
          m,
          birdY: sim.birdY,
          line: bossLine(sim),
        );
      } else if (boss.isDragon) {
        // It slams in on the roar with a card of its own (which carries a
        // campaign level's story line). Until it has one the shared card
        // stands in, and never both.
        if (!DragonEncounterUi.nameCard(
              c,
              size,
              boss,
              m,
              birdY: sim.birdY,
              line: bossLine(sim),
            ) &&
            !_ownCard) {
          _nameCard(c, size, boss, m, line: bossLine(sim));
        }
      } else {
        _nameCard(c, size, boss, m, line: bossLine(sim));
      }
      caption = boss.age > 3.5
          ? boss.isMoth
                ? 'DODGE THE FANS  ·  FIRE WHEN THE VEIL DROPS'
                : boss.isPirate
                ? 'DODGE THE CANNON  ·  STAY OUT OF THE WATER'
                : boss.isDragon
                ? 'DODGE THE FIREBALLS  ·  ESCAPE THE BREATH'
                : boss.screeches
                ? 'WHEN HE SCREECHES  ·  FLY TO THE GAP'
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
        opacity: focus,
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
          : boss.isDragon
          ? 'THE SKY CATCHES FIRE'
          : boss.screeches
          ? 'THE BARON RETURNS'
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
          : boss.isDragon
          ? 'Great wings beat above the clouds…'
          : boss.screeches
          ? 'He is back, and he is much louder…'
          : 'The sky belongs to someone else…',
      Offset(w * .5, h * .372),
      h * .028,
      BossRig.cream,
      opacity: fade,
      centered: true,
    );
  }

  /// A campaign boss level's one line of story, in quotes, from its
  /// chapter. Null in endless, whose cards stay exactly as they were.
  static String? bossLine(FlightSimulation sim) {
    final boss = sim.boss;
    if (sim.levelId == null || boss == null) return null;
    for (final chapter in Campaign.chapters) {
      if (chapter.boss == boss.kind) return '“${chapter.bossLine}”';
    }
    return null;
  }

  /// [line] is a campaign boss's line, set under the epithet; the card
  /// fades it in and out with the rest.
  static void _nameCard(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    String? line,
  }) {
    final h = size.height, w = size.width;
    final progress = BossMotion.ease(BossMotion.ramp(boss.age, 1.65, 2.25));
    final opacity = progress * (1 - BossMotion.ramp(boss.age, 3.9, 4.5));
    if (opacity <= 0) return;
    final x = w * .10 - (m.reducedMotion ? 0 : (1 - progress) * h * .09);
    // A soft shade behind the card keeps it legible over any sky.
    final shade = Rect.fromLTRB(
      0,
      h * .1,
      w * .1 + h * .95,
      h * (line == null ? .385 : .47),
    );
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
    final titleTop = top + h * .075 + name.height * .96;
    final title = _text(
      c,
      boss.title,
      Offset(x + h * .003, titleTop),
      h * .026,
      _gold,
      opacity: opacity,
      spacing: 2,
    );
    if (line != null) {
      // Spoken, so mixed case; an ink edge holds it over the brightest sky.
      _text(
        c,
        line,
        Offset(x + h * .003, titleTop + title.height + h * .024),
        h * .037,
        BossRig.cream,
        opacity: opacity,
        outline: h * .0075,
      );
    }
  }

  static void _victory(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
  ) {
    if (m.boss.isPirate) {
      // A shower of doubloons over the reclaimed sky, the score on a ribbon.
      PirateEncounterUi.victory(c, size, sim, m);
      return;
    }
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

/// The letterbox of the Ember Dragon's encounter, as a [BossMotion] so the
/// parts that read [focus] see the bars as they are drawn.
///
/// It leaves 0.2 s earlier than the others' on the way out of the arrival,
/// so the title's exit is never cut by it. For the roar the frame opens to
/// give the plume room to climb, then closes again for the title and its
/// caption. After the killing blow it slides in behind the dying dragon
/// (0.4 to 1.1 s) instead of cutting across it.
final class _DragonStageMotion extends BossMotion {
  const _DragonStageMotion(super.boss, {required super.reducedMotion});

  @override
  double get focus {
    final age = boss.age;
    if (arriving) {
      final base =
          BossMotion.ease(BossMotion.ramp(age, 0, .65)) *
          (1 - BossMotion.ease(BossMotion.ramp(age, 3.8, 4.4)));
      // Widescreen for the roar (2.65 to 3.45), a still frame under Reduced
      // Motion.
      final open = reducedMotion
          ? 0.0
          : BossMotion.ease(BossMotion.ramp(age, 2.5, 2.75)) *
                (1 - BossMotion.ease(BossMotion.ramp(age, 3.2, 3.6)));
      return base * (1 - .7 * open);
    }
    if (defeated) {
      return BossMotion.ease(BossMotion.ramp(death, .4, 1.1)) * super.focus;
    }
    return super.focus;
  }
}
