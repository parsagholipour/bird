import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';
import 'enemy_art.dart';
import 'enemy_designs/alley_pigeon.dart';
import 'king_coo_boss_rig.dart';
import 'king_coo_crumb_art.dart';
import 'king_coo_encounter_ui.dart';
import 'king_coo_head_art.dart';
import 'king_coo_kit.dart';
import 'king_coo_layout.dart';
import 'king_coo_letterbox.dart';
import 'king_coo_pose.dart';
import 'king_coo_squad_art.dart';
import 'regions/world_region.dart';

/// King Coo's stage: where `BossEncounterArt` puts him in the world and how he
/// arrives, fights and falls (K8, in the method of the Ember Dragon's
/// `_paintDragon`; the shared file only dispatches here).
///
/// WHERE HE STANDS. In combat the heart (the hit circle, the rig's origin) is
/// exactly the rules' `(boss.x, boss.y)`, and every motion of the figure (the
/// waddle, the bob, the swell of the COO!, the pop's squash) belongs to
/// [KingCooPose] alone: the generic mascot offset, rotation and stretch of
/// `BossMotion` are never applied (they would carry the cap past the screen
/// the parts were fitted to, and the stretch pops at every toss). The rig is
/// painted at `boss.x * h, boss.y * h` with one rig unit = `h *
/// SkyBoss.radius`.
///
/// THE ARRIVAL (boss age). The rules slide him in from the right on an arc;
/// only half of the arc is kept, so the cap stays under the letterbox. He is
/// a shadow (the pose's `silhouette`, 1 to 0) with one orange eye, and a
/// siren that strobes red and blue, until the flash at 1.9 s, when the world
/// blanches, the siren swings its light across him and the colour floods in
/// (0.12 s; 0.25 s and no flash under Reduced Motion). He rears and puffs at
/// 2.35 s, COOs at 2.65 s (K7's shout, the pose's swell) and his own card
/// slams at 2.85 s (the foreground, `KingCooEncounterUi.nameCard`).
///
/// THE DEFEAT (seconds since the killing blow). The pose freezes for the
/// hit-stop (0.12 s), he inflates, the cap leaves at 0.3 s from exactly
/// where it sat (no pop), and at 0.85 s he pops like a pillow: K7's burst and
/// feather snow, the badge floating up, the squadron deserting him in a
/// flurry of wings. The cap tumbles down, lands, hops, settles crooked with
/// its siren still blinking, and clears with the title.
///
/// Everything here is a pure function of the boss clock, the simulation clock
/// and the screen size; Reduced Motion drops the motion (the flash, the
/// jitter, the flight of the flock and the cap) and keeps every state.
abstract final class KingCooStaging {
  /// The halo behind him and the light of his effects: the moon-and-siren blue
  /// and the brass of his badge.
  static const tint = Color(0xffa4afde), light = KingCooPalette.gold;

  // ---------------------------------------------------------- the frame --

  /// How much of the rules' entrance arc is kept (the rest would carry the
  /// cap under the letterbox on its way in).
  static const arcKept = .5;

  /// Where the heart (his chest, the rig's origin) is, in pixels.
  static Offset heart(BossMotion m, double h) {
    final boss = m.boss;
    final y = m.arriving ? .5 + (boss.y - .5) * arcKept : boss.y;
    return Offset(boss.x * h, y * h);
  }

  /// Whether every number the staging reads is usable. A boss the clock has
  /// broken (a NaN age from a bad replay, an infinite place) draws nothing
  /// instead of throwing in a dozen of the parts.
  static bool sane(SkyBoss boss, BossMotion m, Size size) =>
      boss.age.isFinite &&
      boss.x.isFinite &&
      boss.y.isFinite &&
      size.isFinite &&
      size.height > 0 &&
      !(m.defeated && !m.death.isFinite);

  /// The pose of [boss] as lit by the region's own sky, looking at the bird
  /// from the head's height (until he is dead).
  static KingCooPose poseOf(FlightSimulation sim, BossMotion m, double h) {
    final sky = SkyPalette.at(sim.elapsed, held: sim.region);
    final light = KingCooSkyLight.fromSky(
      top: sky.top,
      horizon: sky.horizon,
      haze: sky.haze,
    );
    final at = heart(m, h);
    final look = sim.birdY.isFinite
        ? (sim.birdY - at.dy / h + .18) * 3
        : 0.0;
    return KingCooPose(
      m.boss,
      m,
      lookY: m.defeated ? 0 : look,
      light: light,
    );
  }

  /// His own jolts, local to him and never the shared camera: the stamp of the
  /// fury's onset (up to 1.5 px) and the COO! (up to 2 px), at 27 Hz, 0.4 as
  /// much while the camera itself is shaking (the shared camera scales the
  /// world on its first and last shaking frame, and a local jolt on top would
  /// compound it). Pixels at a 360 px screen height.
  static Offset rumble(KingCooPose pose, BossMotion m, double h) {
    if (m.reducedMotion) return Offset.zero;
    final amount = math.max(pose.stomp * 1.5, pose.roar * 2.0);
    if (amount <= 0) return Offset.zero;
    final age = m.boss.age;
    final under = m.shake == Offset.zero ? 1.0 : .4;
    return Offset(
          math.sin(age * 2 * math.pi * 27) * .35,
          math.cos(age * 2 * math.pi * 23),
        ) *
        (amount * h / 360 * under);
  }

  /// The letterbox, 0 to 1, as his encounter draws it (see
  /// [KingCooStageMotion]).
  static double focus(BossMotion m) =>
      KingCooStageMotion(m.boss, reducedMotion: m.reducedMotion).focus;

  // --------------------------------------------------------------- paint --

  static bool _warm = false;

  /// Forgets that the caches are warm (tests that empty them, then expect the
  /// next arrival to prewarm again).
  @visibleForTesting
  static void forgetWarmth() => _warm = false;

  /// Builds every gradient and outline of the encounter (the rig's, the crumb
  /// effects', the squadron's and this stage's own glows) into a picture
  /// nobody sees, so no frame of the fight builds one. The stage calls it as
  /// the first frame; it is pure and safe to call again.
  static void prewarm() {
    _warm = true;
    KingCooBossRig.prewarm();
    KingCooCrumbArt.prewarm();
    KingCooSquadArt.prewarm();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final color in [
      tint,
      KingCooPalette.eyeRim,
      KingCooPalette.sirenRed,
      KingCooPalette.sirenBlue,
      KingCooPalette.bleach,
      KingCooPalette.gold,
      KingCooPalette.rimWarm,
    ]) {
      KingCooKit.glow(c, Offset.zero, 1, color, .5);
    }
    // His effects (K7): each once, at a few moments, in both motions.
    final boss = SkyBoss(number: 6, x: 1.6, kind: BossKind.kingCoo, cinematic: true)
      ..age = 3.2;
    const size = Size(800, 360);
    for (final reduced in [false, true]) {
      final m = BossMotion(boss, reducedMotion: reduced);
      KingCooEncounterUi.nameCard(c, size, boss, m, birdY: .5, line: '“…”');
      for (final t in const [.1, .4, .8]) {
        KingCooEncounterUi.shout(
          c,
          const Offset(300, 100),
          360,
          shock: t,
          roar: t,
          reduced: reduced,
          chest: const Offset(400, 180),
        );
        for (final puffed in [false, true]) {
          KingCooEncounterUi.hit(
            c,
            const Offset(400, 180),
            360,
            t,
            reduced: reduced,
            puffed: puffed,
          );
        }
        KingCooEncounterUi.furyBurst(
          c,
          const Offset(400, 180),
          360,
          t,
          reduced: reduced,
        );
        KingCooEncounterUi.pop(
          c,
          const Offset(400, 180),
          360,
          t,
          reduced: reduced,
        );
        KingCooEncounterUi.burst(
          c,
          const Offset(400, 180),
          360,
          t,
          reduced,
        );
      }
      for (final k in const [.2, .5, 1.0, 1.5, 2.0, 2.5]) {
        KingCooEncounterUi.shockwave(c, const Offset(400, 180), 360, k);
        KingCooEncounterUi.featherSnow(
          c,
          const Offset(400, 180),
          360,
          k + 1.3,
          reduced: reduced,
        );
        KingCooEncounterUi.victoryBadge(
          c,
          const Offset(400, 180),
          360,
          k,
          reduced: reduced,
        );
      }
    }
    rec.endRecording().dispose();
  }

  /// His stage: the arrival's blanching flash under him, the figure (the
  /// arrival's shadow and the defeat's fade are the only layers, bounded to
  /// the rig), the rolls leaving his wing, his shout, hit, fury and pop, then
  /// the defeat. The crumb ring, clouds and the squadron's lanes are the
  /// backdrop's (`BossEncounterArt.backdrop`: K5 `under`, K6 `paint`).
  static void paint(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
  ) {
    final boss = m.boss, h = size.height;
    if (!sane(boss, m, size)) return;
    // Every gradient and outline of the fight, built before the first frame
    // that needs one (the arrival's first frame, or a replay's that seeks
    // straight into the fight).
    if (!_warm) prewarm();
    final unit = h * SkyBoss.radius;
    final pose = poseOf(sim, m, h);
    final center = heart(m, h);
    final body = center + rumble(pose, m, h);
    Offset screen(Offset rig) => body + rig * unit;
    _strike(c, size, m);
    // The squadron pigeons still at his back come out from BEHIND him (the
    // rules bear them at his chest; K6's queue stands under the rig, and so do
    // they, until they have flown clear of the figure).
    _squadBehind(c, h, sim, m);
    // While his rocks count double a gold halo lights his chest from behind
    // (a soft glow, beating at 1.6 Hz: the globe's own edge is still exactly
    // the hit circle), so the weak point reads at a glance and at 120 px.
    if (pose.doubleDamage > .01 && !m.defeated) {
      final beat = m.reducedMotion
          ? .5
          : .5 + .5 * math.sin(pose.time * 2 * math.pi * 1.6);
      final heart = body + KingCooBossRig.chestCenter(pose) * unit;
      KingCooKit.glow(
        c,
        heart,
        unit * 1.9,
        KingCooPalette.gold,
        (.42 + .14 * beat) * pose.doubleDamage,
      );
      // Two ripples leave the globe's edge, one after the other, every 0.625 s
      // (the beat of its ring): outside the hit circle and never part of the
      // figure. They fade out as they grow; Reduced Motion keeps one still.
      for (var i = 0; i < 2; i++) {
        final phase = m.reducedMotion
            ? .35
            : (pose.time * 1.6 + i * .5) % 1.0;
        if (m.reducedMotion && i == 1) break;
        c.drawCircle(
          heart,
          unit * (1.04 + .6 * phase),
          KingCooKit.line(
            KingCooPalette.gold,
            unit * .075 * (1 - .55 * phase),
            .62 * (1 - phase) * pose.doubleDamage,
          ),
        );
      }
    }

    // The figure. He is gone by the pop (the layer fades him over the last
    // 0.29 s before it); under Reduced Motion he goes early, so the burst
    // holds its place.
    final opacity = !m.defeated
        ? 1.0
        : m.reducedMotion
        ? math.min(m.opacity, 1 - BossMotion.ramp(m.death, .45, SkyBoss.burstAt))
        : math.min(m.opacity, pose.opacity);
    if (opacity > 0) {
      final silhouette = pose.silhouette;
      final dark = pose.light.dark;
      if (silhouette > .01 && dark > 0) {
        // Against New York at night the shadow needs an edge: a haze lifts the
        // sky just behind him, most where the sky is darkest.
        KingCooKit.glow(
          c,
          body + Offset(.6 * unit, -.5 * unit),
          unit * _hazeReach,
          tint,
          _hazeAlpha * silhouette * BossMotion.ramp(dark, .2, .7),
        );
      }
      c.save();
      c.translate(body.dx, body.dy);
      c.scale(unit);
      final layered = silhouette > .01 || opacity < 1;
      if (layered) {
        final layer = Paint()
          ..color = const Color(0xffffffff).withValues(alpha: opacity);
        if (silhouette > .01) {
          layer.colorFilter = ColorFilter.mode(
            _night.withValues(alpha: silhouette * .97),
            BlendMode.srcATop,
          );
        }
        c.saveLayer(KingCooBossRig.bounds, layer);
      }
      KingCooBossRig.paintPose(c, pose, cap: !pose.capOff);
      if (layered) c.restore();
      if (m.arriving) _kindle(c, pose, m, silhouette);
      c.restore();
    }

    // The rolls that are leaving his wing fly over him (K5).
    KingCooCrumbArt.flight(c, size, boss, m);
    // Feathers shaking loose as the chest swells (the fix round).
    if (!m.defeated && pose.puff > .04 && pose.puff < .97 && pose.doubleDamage > 0) {
      KingCooEncounterUi.ruffle(
        c,
        body + KingCooBossRig.chestCenter(pose) * unit,
        h,
        pose.time,
        pose.puff,
        reduced: m.reducedMotion,
      );
    }

    final chest = screen(KingCooBossRig.badgeAt(pose));
    if (pose.roar > 0 || pose.shock > 0) {
      KingCooEncounterUi.shout(
        c,
        screen(KingCooBossRig.mouthAt(pose)),
        h,
        shock: pose.shock,
        roar: pose.roar,
        reduced: m.reducedMotion,
        chest: chest,
      );
    }
    if (m.hit > 0 && !m.defeated) {
      KingCooEncounterUi.hit(
        c,
        chest,
        h,
        BossMotion.ramp(boss.age - boss.lastHitAt, 0, .36),
        reduced: m.reducedMotion,
        puffed: boss.lastPuffHitAt == boss.lastHitAt,
      );
    }
    final fury = (boss.age - boss.enragedAt) / 1.1;
    if (!m.defeated && fury >= 0 && fury < 1) {
      KingCooEncounterUi.furyBurst(
        c,
        chest,
        h,
        fury,
        reduced: m.reducedMotion,
      );
    }
    final popped = boss.poppedAt;
    if (!m.defeated && popped != null) {
      final t = (boss.age - popped) / .8;
      if (t >= 0 && t < 1) {
        KingCooEncounterUi.pop(c, chest, h, t, reduced: m.reducedMotion);
      }
    }
    // A white bloom over the body on a hit and on the killing blow: local to
    // him, never the whole screen.
    final flash = _flash(pose, m);
    if (flash > 0) {
      KingCooKit.glow(c, body, unit * 2.6, KingCooPalette.bleach, flash * .7);
    }
    if (m.defeated) _defeat(c, size, sim, m, pose, center);
  }

  // ------------------------------------------------------- the squadron --

  /// How far in front of his chest (rig units, toward the bird) a squadron
  /// pigeon is still drawn under the figure: past his beak (-2.8) and the
  /// pigeon's own reach, so the hand-over to `CombatArt` happens where the
  /// two do not overlap and nothing pops.
  static const squadBehindReach = 3.8;

  /// Whether [enemy] is one of his squadron still at his back: the rules'
  /// pigeons are painted over everything by `CombatArt`, which skips the ones
  /// this returns true for ([paint] draws them under the rig instead).
  static bool squadBehind(SkyBoss? boss, SkyEnemy enemy, double h) =>
      boss != null &&
      boss.isKingCoo &&
      boss.phase != BossPhase.defeated &&
      enemy.squad &&
      boss.x.isFinite &&
      enemy.x.isFinite &&
      enemy.x * h > boss.x * h - squadBehindReach * h * SkyBoss.radius;

  static void _squadBehind(
    Canvas c,
    double h,
    FlightSimulation sim,
    BossMotion m,
  ) {
    for (final enemy in sim.enemies) {
      if (!squadBehind(m.boss, enemy, h)) continue;
      EnemyArt.paint(
        c,
        h,
        enemy,
        birdY: sim.birdY,
        reducedMotion: m.reducedMotion,
      );
      if (sim.supportsWeaponDamage) {
        EnemyArt.healthBar(c, h, enemy, reducedMotion: m.reducedMotion);
      }
    }
  }

  /// The haze behind the arrival's shadow on a dark sky: its alpha and how
  /// many rig units it spreads.
  static const _hazeAlpha = .55, _hazeReach = 6.0;
  static const _night = Color(0xff171c39);

  /// The white glow over his body, 0 to 1: the pose's own flash (a hit's
  /// bite and the killing blow's hit-stop). Motion, so none under Reduced
  /// Motion (which keeps the pose's wash at .3).
  static double _flash(KingCooPose pose, BossMotion m) =>
      m.reducedMotion ? 0 : pose.flash;

  // ------------------------------------------------------------- arrival --

  /// The flash that reveals him: the world blanches (.4, fading over .25 s)
  /// behind the black shadow so its shape stands out starkest just before the
  /// colour floods in, and the siren swings a red and a blue light across it.
  /// Motion, so none under Reduced Motion, which cross-fades instead.
  static void _strike(Canvas c, Size size, BossMotion m) {
    if (m.reducedMotion || !m.arriving) return;
    final since = m.boss.age - KingCooTimeline.flashAt;
    if (since < 0) return;
    final u = 1 - BossMotion.ramp(since, 0, .25);
    if (u <= 0) return;
    final box = Offset.zero & size;
    c.drawRect(box, KingCooKit.fill(KingCooPalette.bleach, .36 * u * u));
    // A light bar sweeping the screen: red from the left, blue from the
    // right, meeting in the middle with no seam.
    c.drawRect(
      box,
      Paint()
        ..shader = LinearGradient(
          colors: [
            KingCooPalette.sirenRed.withValues(alpha: .16 * u),
            KingCooPalette.sirenRed.withValues(alpha: 0),
            KingCooPalette.sirenBlue.withValues(alpha: 0),
            KingCooPalette.sirenBlue.withValues(alpha: .16 * u),
          ],
          stops: const [0, .35, .65, 1],
        ).createShader(box),
    );
  }

  /// Out of the dark: one burning eye and the siren's light. The eye wakes
  /// first, swelling from an ember to white-hot as the flash nears, and when
  /// it lands it flares (0.3 s) while the colour floods in around it; the
  /// siren's lamp strobes red and blue through the shadow. Painted in rig
  /// units, over the layer.
  static void _kindle(
    Canvas c,
    KingCooPose pose,
    BossMotion m,
    double silhouette,
  ) {
    final since = m.boss.age - KingCooTimeline.flashAt;
    final wake = m.reducedMotion
        ? 1.0
        : BossMotion.ease(BossMotion.ramp(since, -.4, 0));
    final eye = KingCooBossRig.eyeAt(pose);
    if (silhouette > .25) {
      KingCooKit.glow(
        c,
        eye,
        .46 + .22 * wake,
        KingCooPalette.eyeRim,
        silhouette * (.25 + .3 * wake) * pose.eyeGlint,
      );
      // A slit slanted like the brow it sits under.
      final width = .22 + .12 * wake;
      c.save();
      c.translate(eye.dx, eye.dy);
      c.rotate(pose.roll + pose.pitch + pose.headTilt - .22);
      final slit = Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: width * .62,
      );
      c.drawOval(
        slit.inflate(width * .12),
        KingCooKit.fill(KingCooPalette.eyeDeep, silhouette * .9),
      );
      c.drawOval(
        slit,
        KingCooKit.fill(
          Color.lerp(KingCooPalette.eyeRim, KingCooPalette.eyeCore, wake)!,
          silhouette,
        ),
      );
      c.drawOval(
        slit.deflate(width * .12),
        KingCooKit.fill(KingCooPalette.bleach, silhouette * wake),
      );
      c.restore();
      // The siren: a hot lamp in the shadow, red or blue as the pose has it.
      if (pose.siren != 0 && pose.sirenGlow > .02) {
        final lamp = KingCooBossRig.sirenAt(pose);
        final color = pose.siren == 1
            ? KingCooPalette.sirenRed
            : KingCooPalette.sirenBlue;
        KingCooKit.glow(c, lamp, .8, color, silhouette * pose.sirenGlow * .55);
        c.drawCircle(
          lamp,
          .13,
          KingCooKit.fill(color, silhouette * pose.sirenGlow),
        );
        c.drawCircle(
          lamp.translate(-.02, -.03),
          .055,
          KingCooKit.fill(KingCooPalette.white, silhouette * pose.sirenGlow),
        );
      }
    }
    if (!m.reducedMotion && since >= 0 && since < .3) {
      // The strike: a flare bursts from the eye with a streak through it.
      final u = since / .3;
      KingCooKit.glow(
        c,
        eye,
        .3 + .8 * _outCubic(u),
        KingCooPalette.bleach,
        (1 - u) * (1 - u) * .8,
      );
      c.drawOval(
        Rect.fromCenter(
          center: eye,
          width: .5 + 2.2 * u,
          height: .05 * (1 - u),
        ),
        KingCooKit.fill(KingCooPalette.bleach, (1 - u) * .9),
      );
    }
  }

  // -------------------------------------------------------------- defeat --

  /// The pop and what follows it, over the place he was: the feather-and-crumb
  /// burst, the soft shockwave, the snow, the squadron deserting him, the
  /// badge floating up (K7), and then the payoff (the fix round): a shower of
  /// crumbs and feathers over the whole sky, the cap tossed to the middle of
  /// the screen where it lands, spins like a coin and lies lit by its own
  /// siren with the brass badge floating beside it, and three of his pigeons
  /// dropping in to peck at the crumbs.
  static void _defeat(
    Canvas c,
    Size size,
    FlightSimulation sim,
    BossMotion m,
    KingCooPose pose,
    Offset center,
  ) {
    final h = size.height, reduced = m.reducedMotion;
    final k = m.death - SkyBoss.burstAt;
    final unit = h * SkyBoss.radius;
    final land = capLanding(size);
    if (k >= 0) {
      if (!reduced) KingCooEncounterUi.shockwave(c, center, h, k);
      KingCooEncounterUi.burst(
        c,
        center,
        h,
        BossMotion.ramp(k, 0, 1.3),
        reduced,
      );
      KingCooEncounterUi.featherSnow(c, center, h, k, reduced: reduced);
      KingCooEncounterUi.shower(c, size, k, center.dx, reduced: reduced);
      _desertion(c, center, h, k, reduced);
      KingCooEncounterUi.victoryBadge(
        c,
        center,
        h,
        k,
        reduced: reduced,
        restAt: Offset(land.dx + unit * 2.3, land.dy - unit * 2.3),
      );
    }
    _capFall(c, center, size, m, pose.light);
    _feast(c, size, m, land);
  }

  /// Where the cap comes to rest: the middle of the screen on the ground line
  /// (the cap's rim on it), under the victory title and in front of the lit
  /// river, not in a dark corner of the rooftops.
  static Offset capLanding(Size size) => Offset(
    size.width * .5,
    size.height * _groundAt -
        capRestBottom * size.height * SkyBoss.radius * capScale,
  );

  /// The cap's lowest point below its band centre when it lies at rest (tilted
  /// [_restTilt]): the rim of its reach box turned by the tilt, so the lowest
  /// corner, not the middle, is what touches the ground line.
  static final double capRestBottom = [
    for (final corner in [
      capReach.topLeft,
      capReach.topRight,
      capReach.bottomLeft,
      capReach.bottomRight,
    ])
      corner.dx * math.sin(_restTilt) + corner.dy * math.cos(_restTilt),
  ].reduce(math.max);

  static const _restTilt = .22;

  /// How large the fallen cap grows (1 on his head, 1.4 on the ground).
  static const capScale = 1.4;

  /// His squadron deserts him: five Alley Pigeons that were waiting behind his
  /// chest burst out of the cloud of down (once the figure itself is gone, so
  /// the frame stays inside the ops budget), startled, and scatter up and
  /// away, flapping as fast as they can. Motion, so none under Reduced Motion.
  static void _desertion(
    Canvas c,
    Offset at,
    double h,
    double k,
    bool reduced,
  ) {
    if (reduced || !k.isFinite || k < 0 || k > _flyOffSeconds) return;
    final unit = h * SkyBoss.radius;
    for (var i = 0; i < _deserters.length; i++) {
      final d = _deserters[i];
      final t = k - d.delay;
      if (t < 0) continue;
      // Out of the burst, fast, then easing to a steady climb.
      final run = 1 - math.exp(-3.2 * t);
      final from = at + Offset(d.dx, d.dy) * unit;
      final to = Offset(math.cos(d.angle), math.sin(d.angle)) * d.reach * h;
      final pos = from + to * run + Offset(0, -h * .05 * t * t);
      c.save();
      c.translate(pos.dx, pos.dy);
      // The painter looks left; the ones that flee to the right are mirrored.
      final right = to.dx > 0;
      if (right) c.scale(-1.0, 1.0);
      AlleyPigeonArt.paint(
        c,
        h * SkyEnemy.radius * d.size,
        seconds: t * 1.5 + i * .13,
        reducedMotion: false,
        pose: PigeonPose(
          stage: PigeonStage.flee,
          stageTime: t,
          // The nose lifts along the climb (in the painter's own frame).
          tilt: (-math.atan2(to.dy, to.dx.abs()) * .8).clamp(-.8, .8),
          startle:
              1 -
              BossMotion.ease(BossMotion.ramp(t, 0, PigeonPose.startleSeconds)),
          facingRight: right,
          coat: d.coat,
        ),
      );
      c.restore();
    }
  }

  static const _flyOffSeconds = 2.1;

  /// The five of the queue: where each stood from the chest (rig units), how
  /// long after the pop it bursts out, where it goes (screen angle and reach
  /// in screen heights), its size and its plumage.
  static const _deserters = <_Deserter>[
    _Deserter(1.5, -.9, .22, -2.15, 1.05, 1.0, 0),
    _Deserter(2.1, .2, .27, -.95, .95, .9, 1),
    _Deserter(1.2, -1.6, .31, -1.60, 1.20, 1.0, 2),
    _Deserter(2.4, -.5, .35, -2.75, 1.00, .85, 1),
    _Deserter(1.8, .7, .39, -.35, .85, .9, 0),
  ];

  // ------------------------------------------------------------- the feast --

  /// Three of his pigeons come back for the crumbs: they drop in beside the
  /// fallen cap (1.7 s on), stand with their feet on the ground line facing it
  /// and peck at what the shower left, one after the other, and flap away
  /// (3.15 s on) as the title goes. Each wears its own plumage and size. Under
  /// Reduced Motion they simply stand there, fading in and out, not pecking.
  static void _feast(Canvas c, Size size, BossMotion m, Offset land) {
    final t = m.death;
    if (!t.isFinite || t < 1.6 || t > 4.1) return;
    final h = size.height, unit = h * SkyBoss.radius, reduced = m.reducedMotion;
    final ground = h * _groundAt;
    for (var i = 0; i < _guests.length; i++) {
      final g = _guests[i];
      final r = h * SkyEnemy.radius * g.size;
      final stand = Offset(land.dx + g.dx * unit, ground - .92 * r);
      final arrive = 1.7 + .25 * i, down = arrive + .55;
      final leave = 3.15 + .1 * i, away = leave + .6;
      final facingRight = g.dx < 0;
      if (reduced) {
        final a = BossMotion.ramp(t, 2.0 + .1 * i, 2.3 + .1 * i) *
            (1 - BossMotion.ramp(t, 3.2, 3.6));
        if (a <= 0) continue;
        c.save();
        c.translate(stand.dx, stand.dy);
        if (facingRight) c.scale(-1.0, 1.0);
        c.saveLayer(
          Rect.fromCircle(center: Offset.zero, radius: r * 3),
          KingCooKit.fill(const Color(0xffffffff), a),
        );
        AlleyPigeonArt.paint(
          c,
          r,
          seconds: 0,
          reducedMotion: true,
          pose: PigeonPose(stage: PigeonStage.gloat, coat: g.coat),
        );
        c.restore();
        c.restore();
        continue;
      }
      if (t < arrive || t > away) continue;
      Offset pos;
      PigeonPose pose;
      var glide = false;
      if (t < down) {
        // Dropping in from above and the side, flapping, nose down, then the
        // tuck as the feet touch.
        final u = (t - arrive) / (down - arrive);
        final e = 1 - (1 - u) * (1 - u);
        final from = Offset(stand.dx + g.dx.sign * h * .35, -h * .1);
        pos = Offset.lerp(from, stand, e)!;
        glide = true;
        pose = PigeonPose(
          coat: g.coat,
          tilt: -.45 * (1 - u) + .3 * u * u,
        );
      } else if (t < leave) {
        // Standing and pecking: nose-down dips, a few to the second, each
        // pigeon on its own beat.
        final peck = math.pow(math.max(0.0, math.sin(2 * math.pi * (t * 1.9 + g.beat))), 3);
        pos = stand + Offset(0, r * .12 * peck);
        pose = PigeonPose(
          stage: PigeonStage.gloat,
          stageTime: t - down,
          coat: g.coat,
          tilt: -.5 * peck,
        );
      } else {
        // Startled off by the title: up and away, flapping.
        final u = (t - leave) / (away - leave);
        final to = Offset(stand.dx - g.dx.sign * h * .55, -h * .25);
        pos = Offset.lerp(stand, to, u * u)!;
        glide = true;
        pose = PigeonPose(coat: g.coat, tilt: .35 * u);
      }
      c.save();
      c.translate(pos.dx, pos.dy);
      if (facingRight) c.scale(-1.0, 1.0);
      AlleyPigeonArt.paint(
        c,
        r,
        seconds: t * 1.6 + i * .37,
        reducedMotion: false,
        glider: glide,
        pose: pose,
      );
      c.restore();
    }
  }

  /// The three guests: where each stands from the cap (rig units, left of it
  /// facing right, right of it facing left), its size, its plumage and the
  /// phase of its pecking.
  static const _guests = <_Guest>[
    _Guest(-3.2, 1.1, 1, .00),
    _Guest(3.0, 1.0, 2, .37),
    _Guest(5.2, 1.05, 0, .68),
  ];

  /// How visible the fallen cap is, 0 to 1: not at all until it leaves his
  /// head (0.3 s into the defeat), fully until the title is up, then it fades
  /// (3.1 to 3.6 s). Under Reduced Motion it is drawn on his head's seat until
  /// 1.4 s and on the ground from 1.3 s (a cross-fade, no flight).
  static double capFade(BossMotion m) {
    if (!m.defeated || !m.death.isFinite) return 0;
    final t = m.death;
    if (t < KingCooTimeline.capOffAt || t >= 3.7) return 0;
    return 1 - BossMotion.ramp(t, 3.1, 3.6);
  }

  /// The cap's fall, from the moment it leaves (0.3 s in): from exactly the
  /// seat, turn and size it had on his head (`KingCooBossRig.capDrop`: the pose
  /// he died in has settled into a canonical one by then, so this is exact for
  /// every real defeat), tossed up and across to the middle of the screen,
  /// growing to 1.4x as it tumbles, LANDING on the ground line with big hops,
  /// spinning like a coin once round as it settles, and lying there with its
  /// siren still blinking and lighting the ground until the title clears it.
  /// Reduced Motion holds it where it left his head and then shows it on the
  /// ground, cross-faded (nothing flies).
  static void _capFall(
    Canvas c,
    Offset heart,
    Size size,
    BossMotion m,
    KingCooSkyLight light,
  ) {
    final h = size.height;
    final t = m.death, reduced = m.reducedMotion;
    final fade = capFade(m);
    if (fade <= 0) return;
    final unit = h * SkyBoss.radius;
    // The pose he has at the instant the cap leaves (the same sky, the same
    // fury): the seat, turn, tone and siren it takes with it, so there is no
    // pop in place, angle, colour or light.
    final leave = KingCooPose(
      m.boss,
      m,
      light: light,
      at: m.boss.defeatedAt! + KingCooTimeline.capOffAt,
    );
    final drop = KingCooBossRig.capAt(leave);
    final seat = heart + drop.at * unit;
    final flight = t - KingCooTimeline.capOffAt;
    final land = capLanding(size);
    const landT = 1.15;
    const rest = _restTilt;
    final blink = (t * KingCooTimeline.sirenHz).floor().isEven ? 1 : 2;

    if (reduced) {
      // On his head's seat (the same pixels as the rig's) until 1.4 s, on the
      // ground from 1.3 s: a cross-fade.
      final held = 1 - BossMotion.ramp(t, 1.2, 1.4);
      final down = BossMotion.ramp(t, 1.3, 1.6);
      if (held > 0) {
        _paintCap(c, seat, drop.angle, unit, fade * held, leave.siren, leave.sirenGlow, leave.tone, 0);
      }
      if (down > 0) {
        _paintCap(c, land, rest, unit * capScale, fade * down, 1, .6, leave.tone, 0);
        KingCooKit.glow(
          c,
          land + Offset(0, -unit * .3),
          h * .17,
          KingCooPalette.sirenRed,
          .35 * fade * down,
        );
      }
      return;
    }

    final scale = 1 + (capScale - 1) * BossMotion.ease(BossMotion.ramp(flight, 0, .9));
    // Thrown up and across to the landing spot, then falling under its own
    // weight; the landing spot is where the origin ends up (its rim on the
    // ground), the arc's apex a hand above his head.
    final gravity = (land.dy - seat.dy + .30 * h * landT) / (landT * landT);
    final u = math.max(0.0, flight - landT);
    Offset pos;
    if (flight <= landT) {
      pos = Offset(
        seat.dx + (land.dx - seat.dx) * (1 - math.pow(1 - flight / landT, 2)),
        seat.dy + h * -.30 * flight + gravity * flight * flight,
      );
    } else {
      // Big hops that die away, the spin carrying it a little further.
      pos = Offset(
        land.dx + h * .012 * (1 - math.exp(-4 * u)),
        land.dy - h * .075 * math.exp(-3.6 * u) * math.sin(2 * math.pi * 1.7 * u).abs(),
      );
    }
    // Spinning as it falls it comes to rest tilted; on the ground it spins
    // once round like a coin as it settles (a whole turn, so it ends the same).
    final turns = ((drop.angle + 5.0 * landT - rest) / (2 * math.pi)).round();
    final target = rest + 2 * math.pi * turns;
    final blend = BossMotion.ease(BossMotion.ramp(flight, landT - .4, landT));
    final spin = 2 * math.pi * (1 - math.exp(-2.6 * u));
    final rotation =
        (drop.angle + 5.0 * flight) * (1 - blend) +
        target * blend +
        spin +
        .10 * math.exp(-7 * u) * math.sin(2 * math.pi * 3 * u);
    if (flight > landT - .3) {
      // Its shadow finds the ground before it does.
      final near = BossMotion.ramp(flight, landT - .3, landT);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(pos.dx, h * _groundAt + unit * .04),
          width: unit * capScale * 1.5 * (.5 + .5 * near),
          height: unit * .22,
        ),
        KingCooKit.fill(KingCooPalette.ink, .3 * near * fade),
      );
    }
    // The siren goes on blinking where it lies, red and blue at 3 Hz, lighting
    // the ground in a pool: from the light it had on his head as it left,
    // easing up as it falls.
    final siren = flight <= 0 ? leave.siren : blink;
    final target2 = .75 + .25 * BossMotion.ramp(flight, landT - .2, landT + .1);
    final sirenGlow =
        leave.sirenGlow +
        (target2 - leave.sirenGlow) * BossMotion.ease(BossMotion.ramp(flight, 0, .5));
    if (flight > landT * .8) {
      final pool = BossMotion.ramp(flight, landT * .8, landT + .2);
      KingCooKit.glow(
        c,
        Offset(land.dx, land.dy - unit * .3),
        h * .17,
        siren == 1 ? KingCooPalette.sirenRed : KingCooPalette.sirenBlue,
        .35 * fade * pool,
      );
    }
    _paintCap(c, pos, rotation, unit * scale, fade, siren, sirenGlow, leave.tone, leave.time + flight);
  }

  static void _paintCap(
    Canvas c,
    Offset origin,
    double rotation,
    double unit,
    double alpha,
    int siren,
    double glow,
    KingCooTone tone,
    double time,
  ) {
    c.save();
    c.translate(origin.dx, origin.dy);
    c.scale(unit);
    c.rotate(rotation);
    c.saveLayer(capLayer, KingCooKit.fill(const Color(0xffffffff), alpha));
    KingCooHeadArt.capOnly(
      c,
      tone: tone,
      siren: siren,
      sirenGlow: glow,
      time: time,
    );
    c.restore();
    c.restore();
  }

  /// Where the cap lands, in screen heights.
  static const _groundAt = .865;

  /// What the cap reaches around its band centre (rig units), measured from a
  /// render (the staging test pins it).
  static const capReach = Rect.fromLTRB(-.84, -.66, .78, .18);

  /// The layer the cap's fade is painted in: the cap and its siren's glow.
  static const capLayer = Rect.fromLTRB(-1.4, -1.5, 1.3, .7);

  static double _outCubic(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u * u;
  }
}

/// One of the three pigeons that come back for the crumbs: where it stands
/// from the cap ([dx], rig units), its [size], plumage and pecking [beat].
final class _Guest {
  const _Guest(this.dx, this.size, this.coat, this.beat);
  final double dx, size, beat;
  final int coat;
}

/// One of the five pigeons that desert him: where it stood from the chest
/// ([dx], [dy] in rig units), when it bursts out, where it goes ([angle] on
/// screen, [reach] in screen heights), its [size] and plumage.
final class _Deserter {
  const _Deserter(
    this.dx,
    this.dy,
    this.delay,
    this.angle,
    this.reach,
    this.size,
    this.coat,
  );
  final double dx, dy, delay, angle, reach, size;
  final int coat;
}
