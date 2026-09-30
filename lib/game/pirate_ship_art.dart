import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'pirate_artillery_art.dart';
import 'pirate_hull_art.dart';
import 'pirate_rigging_art.dart';

/// The Pirate Captain's ship: a two-masted brigantine with patched sails, a
/// Jolly Roger, a gilded stern castle and a bronze mortar on the bow deck.
///
/// Authored in the captain's rig units (1 = [SkyBoss.radius]) around his
/// hit circle, but anchored to the sea: the waterline sits [waterline]
/// below the captain and the hull fills the armored box the rules test
/// (rail at [rail], bow at [bow], stern at [stern]). The ship rolls about
/// its waterline on its own, independent of the captain's character
/// motion, and the cannon is always drawn at its exact pivot so the barrel
/// points where the balls come out.
abstract final class PirateShipArt {
  static const waterline = SkyBoss.shipRide / SkyBoss.radius;
  static const rail = SkyBoss.hullTop / SkyBoss.radius;
  static const bow = SkyBoss.hullLeft / SkyBoss.radius;
  static const stern = SkyBoss.hullRight / SkyBoss.radius;
  static const keel = waterline + .62;
  static final pivot = Offset(
    SkyBoss.cannonPivot.$1 / SkyBoss.radius,
    SkyBoss.cannonPivot.$2 / SkyBoss.radius,
  );
  static const barrel = SkyBoss.cannonLength / SkyBoss.radius;

  /// Everything the ship can reach, masts, flag and bowsprit included.
  static const bounds = Rect.fromLTRB(-4.1, -5.1, 3.8, 2.6);

  static const ink = Color(0xff2a1a1e);
  static const _glow = Color(0xffffd36b), _windowHot = Color(0xffff8a4a);

  // ---------------------------------------------------------------- pose --

  /// The ship's roll about its waterline: a gentle swell, a lurch when the
  /// cannon fires, a pitch while it sails in and while the tide surges.
  static double roll(SkyBoss boss, BossMotion m) {
    if (m.reducedMotion) return 0;
    final t = boss.age;
    var roll = math.sin(t * 1.15) * .014 + math.sin(t * 2.7 + 1) * .005;
    roll -= m.recoil * .022;
    // A shot thumping the hull sets it shuddering: a quick damped wobble.
    final knock = t - boss.lastHullHitAt;
    if (knock >= 0 && knock < .9) {
      roll += math.sin(knock * 22) * .024 * math.exp(-knock * 5.5);
    }
    if (m.arriving) {
      final sailing = 1 - BossMotion.ramp(t, 2.4, 3.2);
      roll += math.sin(t * 2.6) * .03 * sailing;
    }
    // The bow lifts as a surge comes in under it and dips as it drains.
    final cycle = (t - boss.arrivalDuration) % SkyBoss.tidePeriod;
    if (boss.phase == BossPhase.attacking) {
      roll += BossMotion.pulse(cycle - SkyBoss.tideRiseAt, .9) * .035;
      roll -= BossMotion.pulse(cycle - SkyBoss.tideFallAt, 1.1) * .025;
    }
    return roll;
  }

  static void _rolled(Canvas c, double angle) {
    if (angle == 0) return;
    c.translate(0, waterline);
    c.rotate(angle);
    c.translate(0, -waterline);
  }

  /// How far below the sea the wreck has settled, in rig units.
  static double sunk(BossMotion m) {
    if (!m.defeated || m.reducedMotion) return 0;
    // The sea drains fast, so the wreck is dragged under while there is
    // still water on screen to swallow it.
    final k = BossMotion.ramp(
      m.death,
      SkyBoss.burstAt + .05,
      SkyBoss.burstAt + .7,
    );
    return k * k * 8;
  }

  /// The broken halves' tilt after the defeat: a sharp snap as the keel
  /// gives, then a slower list as they go down.
  static double _tilt(BossMotion m) {
    if (!m.defeated || m.reducedMotion) return 0;
    final k = m.death - SkyBoss.burstAt;
    return BossMotion.ease(BossMotion.ramp(k, 0, .32)) * .34 +
        BossMotion.ramp(k, .32, .9) * .16 +
        BossMotion.pulse(k, .2) * .06;
  }

  static bool _broken(BossMotion m) =>
      m.defeated && !m.reducedMotion && m.death >= SkyBoss.burstAt;

  /// Runs [draw] once, or once per broken half after the defeat.
  static void _pieces(
    Canvas c,
    SkyBoss boss,
    BossMotion m,
    void Function(Canvas c, {required bool bowHalf}) draw,
  ) {
    final sink = sunk(m);
    if (!_broken(m)) {
      c.save();
      c.translate(0, sink);
      _rolled(c, roll(boss, m));
      draw(c, bowHalf: true);
      c.restore();
      return;
    }
    final tilt = _tilt(m);
    // The snapping keel heaves both halves up for an instant before they
    // part and drop.
    final kick = BossMotion.pulse(m.death - SkyBoss.burstAt, .3);
    for (final left in [false, true]) {
      c.save();
      c.translate(left ? -tilt * .8 : tilt * .8, sink - kick * .22);
      c.translate(PirateHullArt.seamX, keel);
      c.rotate(left ? tilt * 1.15 : -tilt * .9);
      c.translate(-PirateHullArt.seamX, -keel);
      c.clipPath(PirateHullArt.half(left: left));
      draw(c, bowHalf: left);
      c.restore();
    }
  }

  // ---------------------------------------------------------------- back --

  /// Masts, sails, rigging and flags, drawn behind the captain.
  static void back(Canvas c, SkyBoss boss, BossMotion m) {
    _pieces(
      c,
      boss,
      m,
      (c, {required bowHalf}) => PirateRiggingArt.paint(c, boss, m),
    );
  }

  static double _time(SkyBoss boss, BossMotion m) =>
      m.reducedMotion ? 0.0 : boss.age;

  // --------------------------------------------------------------- front --

  /// The hull, bowsprit, stern castle and the cannon, drawn in front of the
  /// captain. [aim] is the barrel angle from [SkyBoss.cannonShot].
  static void front(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    required double aim,
  }) {
    _pieces(c, boss, m, (c, {required bowHalf}) {
      PirateHullArt.paint(
        c,
        boss,
        m,
        bowHalf: bowHalf,
        broken: _broken(m),
      );
      if (_broken(m) && bowHalf) {
        _cannon(c, boss, m, aim, carriageRoll: 0);
      }
    });
    if (!_broken(m)) {
      // Drawn unrolled at its exact pivot; only the carriage follows the roll.
      c.save();
      c.translate(0, sunk(m));
      _cannon(c, boss, m, aim, carriageRoll: roll(boss, m));
      c.restore();
    }
  }

  /// Warm light from the lanterns and stern windows, drawn over the ship
  /// (and over its silhouette as it sails in out of the dusk).
  static void lights(Canvas c, SkyBoss boss, BossMotion m, {double alpha = 1}) {
    if (alpha <= 0 || (m.defeated && m.death > SkyBoss.burstAt)) return;
    final fury = boss.enraged && !m.defeated;
    final t = _time(boss, m);
    final flicker = t == 0
        ? 0.0
        : math.sin(t * 9) * .06 + math.sin(t * 23) * .04;
    final color = fury ? _windowHot : _glow;
    c.save();
    c.translate(0, sunk(m));
    _rolled(c, roll(boss, m));
    for (final (at, r, a) in [
      (PirateHullArt.lamp(boss, m), .78, .44),
      for (final window in PirateHullArt.windows) (window, .4, .2),
    ]) {
      final glow = Rect.fromCircle(center: at, radius: r * (1 + flicker));
      c.drawCircle(
        at,
        glow.width / 2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: a * alpha),
              color.withValues(alpha: a * .35 * alpha),
              color.withValues(alpha: 0),
            ],
            stops: const [0, .35, 1],
          ).createShader(glow),
      );
    }
    c.restore();
  }

  // -------------------------------------------------------------- cannon --

  /// Where the wick meets the breech and where its tip curls, in rig
  /// units, for a barrel at [aim]. The gun itself, its fuse and its blast
  /// live in [PirateArtillery].
  static (Offset hole, Offset tip) fuse(double aim) =>
      PirateArtillery.fuse(aim);

  static void _cannon(
    Canvas c,
    SkyBoss boss,
    BossMotion m,
    double aim, {
    required double carriageRoll,
  }) => PirateArtillery.paint(c, boss, m, aim, carriageRoll: carriageRoll);

  /// The muzzle blast and a gunsmoke cloud after each shot, in screen
  /// pixels from the real muzzle.
  static void blast(
    Canvas c,
    double h,
    SkyBoss boss,
    BossMotion m, {
    required Offset muzzle,
    required double aim,
  }) => PirateArtillery.blast(c, h, boss, m, muzzle: muzzle, aim: aim);
}
