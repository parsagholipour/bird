import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_ammo_art.dart';
import 'boss_motion.dart';
import 'pirate_aim_art.dart';
import 'pirate_sea_water.dart';
import 'pirate_splash_art.dart';
import 'pirate_tide_art.dart';

/// The Pirate Captain's sea: a back swell behind the ship, the water in
/// front of the hull, the tide's warning, splashes, hull knocks and the
/// marks where each cannonball will cross the bird's flight line.
///
/// The drawn surface follows [SkyBoss.waterLevel] (the line the rules test
/// for the bird) within a few thousandths of the screen, so a dodge that
/// looks clean is clean. Waves travel with the course and every motion
/// follows the simulation clock, so pause and replay seeking stay exact.
abstract final class PirateSeaArt {
  static const foam = PirateSeaWater.foam;

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));
  static Paint _stroke(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  /// The wave height at screen x (screen heights), within ±.005 of the
  /// level: two swells riding the course and slowly rolling on their own.
  static double wave(double x, double distance, double t, {double swell = 1}) {
    final w = x + distance;
    return (.0031 * math.sin(w * 9.1 + t * 1.4) +
            .0019 * math.sin(w * 21.7 - t * 2.3 + 1.1)) *
        swell;
  }

  /// Where the sea is drawn: the rules' [SkyBoss.waterLevel], except that
  /// after the defeat it holds a moment so the wreck visibly goes under
  /// before the sea drains away. The cutscene never hurts the bird.
  static double? drawnLevel(SkyBoss boss, BossMotion m) {
    final level = boss.waterLevel;
    if (level == null || !m.defeated || m.reducedMotion) return level;
    final s = BossMotion.ease(
      BossMotion.ramp(m.death / (boss.departureDuration * .8), 0, 1),
    );
    if (s >= .95) return level;
    final from = (level - SkyBoss.seaHidden * s) / (1 - s);
    return from +
        (level - from) * BossMotion.ease(BossMotion.ramp(m.death, 1.1, 2.2));
  }

  static double _time(FlightSimulation sim, BossMotion m) =>
      m.reducedMotion ? 0.0 : sim.elapsed;

  /// How hard the sea churns: through each warning, the surge and on
  /// arrival.
  static double _churn(SkyBoss boss) {
    if (boss.phase == BossPhase.defeated) {
      final k = boss.age - boss.defeatedAt! - SkyBoss.burstAt;
      return BossMotion.ramp(k, 0, .3) * (1 - BossMotion.ramp(k, 1, 1.8));
    }
    if (boss.phase == BossPhase.arriving) {
      return 1 - BossMotion.ramp(boss.age, 2.2, 3);
    }
    if (boss.phase != BossPhase.attacking) return .4;
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    // A staged captain's warm-up cycles bring no surge to stir the sea.
    if (!boss.tideRuns) return boss.tideWarning * .8;
    return math.max(
      boss.tideWarning * .8,
      BossMotion.ramp(cycle, SkyBoss.tideRiseAt, SkyBoss.tideRiseAt + .2) *
          (1 - BossMotion.ramp(cycle, SkyBoss.tidePeakAt, SkyBoss.tideFallAt)),
    );
  }

  /// How much of the ship is still afloat: 1 until the defeat, then 0 as it
  /// breaks up (Reduced Motion fades it out instead).
  static double _shipAfloat(BossMotion m) => !m.defeated
      ? 1.0
      : m.reducedMotion
      ? 1 - BossMotion.ramp(m.death, .3, SkyBoss.burstAt)
      : 1 - BossMotion.ramp(m.death - SkyBoss.burstAt, 0, .4);

  /// The tide's motion, for the water's set pieces: [rush] as the surge
  /// sweeps up, [drip] as the retreat lets foam slide down the face of the
  /// water and [pour] while the deck sheds the sea it took aboard. Still
  /// under Reduced Motion, which keeps the sea's state readable by its level.
  static ({double rush, double drip, double pour}) _flow(
    SkyBoss boss,
    BossMotion m,
  ) {
    if (m.reducedMotion || boss.phase != BossPhase.attacking) {
      return (rush: 0.0, drip: 0.0, pour: 0.0);
    }
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    double ramp(double a, double b) => BossMotion.ramp(cycle, a, b);
    return (
      rush:
          ramp(SkyBoss.tideRiseAt, SkyBoss.tideRiseAt + .15) *
          (1 - ramp(SkyBoss.tidePeakAt, SkyBoss.tidePeakAt + .6)),
      drip:
          ramp(SkyBoss.tideFallAt - .1, SkyBoss.tideFallAt + .3) *
          (1 - ramp(SkyBoss.tideCalmAt - .2, SkyBoss.tideCalmAt + .9)),
      pour:
          ramp(SkyBoss.tideRiseAt + .5, SkyBoss.tideRiseAt + 1.1) *
          (1 - ramp(SkyBoss.tidePeakAt + .5, SkyBoss.tidePeakAt + 1.7)),
    );
  }

  /// After the defeat the sea heaves up over the broken ship and swallows
  /// it, then settles as it drains away. Art only: the cutscene never
  /// hurts, and the rules' surface stays where it was.
  static double Function(double x)? _gulp(SkyBoss boss, BossMotion m) {
    if (!m.defeated || m.reducedMotion) return null;
    final k = m.death - SkyBoss.burstAt;
    final rise = BossMotion.ease(BossMotion.ramp(k, .05, .4));
    final fall = BossMotion.ease(BossMotion.ramp(k, .85, 1.8));
    final amount = .24 * rise * (1 - fall);
    if (amount <= 0) return null;
    final center = boss.x + .02;
    return (x) {
      final u = (x - center) / .52;
      if (u.abs() >= 1) return 0;
      final bell = 1 - u * u;
      return amount * bell * bell;
    };
  }

  // ---------------------------------------------------------------- back --

  /// A darker swell just behind the ship, so the hull sits in the water
  /// rather than on a flat line.
  static void back(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) {
    final level = drawnLevel(boss, m);
    final heave = _gulp(boss, m);
    if (level == null || (level > 1.03 && heave == null)) return;
    final t = _time(sim, m);
    double top(double x) =>
        level -
        .003 -
        (heave?.call(x) ?? 0) +
        wave(x + .37, sim.distance * .8, t * .8);
    PirateSeaWater.back(
      c,
      size,
      level,
      top,
      SeaMoment(
        level: level,
        distance: sim.distance,
        t: t,
        churn: 0,
        rush: 0,
        drip: 0,
        pour: 0,
        surface: top,
        reduced: m.reducedMotion,
        bowX: 0,
        sternX: 0,
        railY: 0,
      ),
    );
  }

  // --------------------------------------------------------------- front --

  /// The sea in front of the hull, with its foam crest, glints and the
  /// churn of a surge. [bowX] and [sternX] are where the hull meets the
  /// water.
  static void front(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m, {
    required double bowX,
    required double sternX,
  }) {
    final level = drawnLevel(boss, m);
    final heave = _gulp(boss, m);
    if (level == null || (level > 1.03 && heave == null)) return;
    final h = size.height;
    final t = _time(sim, m);
    final churn = m.reducedMotion ? 0.0 : _churn(boss);
    final swell = 1 + churn * .25;
    final flow = _flow(boss, m);
    double surface(double x) =>
        level + wave(x, sim.distance, t, swell: swell) - (heave?.call(x) ?? 0);
    PirateSeaWater.front(
      c,
      size,
      SeaMoment(
        level: level,
        distance: sim.distance,
        t: t,
        churn: churn,
        rush: flow.rush,
        drip: flow.drip,
        pour: flow.pour,
        surface: surface,
        reduced: m.reducedMotion,
        bowX: bowX,
        sternX: sternX,
        railY: boss.y + SkyBoss.hullTop,
        heave: heave,
        lift: heave?.call(boss.x + .02) ?? 0,
        defeatK: m.defeated ? m.death - SkyBoss.burstAt : null,
        ship: _shipAfloat(m),
      ),
    );
    if (heave != null) {
      // White water tumbles down the face of the swell.
      final center = boss.x + .02;
      for (final (d, alpha, width) in const [
        (.012, .75, .007),
        (.03, .5, .0055),
        (.052, .3, .0045),
      ]) {
        final foamLine = Path();
        var open = false;
        for (var x = center - .52; x <= center + .52; x += .01) {
          final lift = heave(x);
          if (lift < d * 1.6) {
            open = false;
            continue;
          }
          final y =
              (level -
                  lift +
                  wave(x, sim.distance, t) +
                  d +
                  math.sin(x * 40 + t * 3) * .003) *
              h;
          if (open) {
            foamLine.lineTo(x * h, y);
          } else {
            foamLine.moveTo(x * h, y);
            open = true;
          }
        }
        c.drawPath(foamLine, _stroke(foam, h * width, alpha));
      }
      // The sea closes over the wreck with a crash of spray either side.
      final k = m.death - SkyBoss.burstAt;
      final crash = BossMotion.ramp(k, .15, .9);
      if (crash > 0 && crash < 1) {
        final burst = math.sin(crash * math.pi);
        for (final (side, big) in [(-1.0, 1.0), (1.0, .8)]) {
          final x = boss.x + .02 + side * .3;
          final top = level - heave(x) + wave(x, sim.distance, t);
          _crown(
            c,
            h,
            Offset(x * h, top * h),
            h * .05 * big,
            h * .07 * burst * big,
            7,
            1 - crash * crash,
          );
        }
      }
    }
  }

  // --------------------------------------------------------------- tide --

  /// The warning before each surge: the high-water line the sea will reach,
  /// a shadow of the water over everything it will cover, chevrons welling
  /// up toward the line and a tag spelling it out. It holds until the water
  /// arrives.
  static void tideWarning(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) {
    final t = _time(sim, m);
    PirateTideArt.warning(
      c,
      size,
      boss: boss,
      reduced: m.reducedMotion,
      distance: sim.distance,
      t: t,
      peak: (x) => SkyBoss.tidePeak + wave(x, sim.distance, t),
    );
  }

  // ------------------------------------------------------------ splashes --

  /// Where cannonballs and the bird met the sea: a tall heavy splash for a
  /// ball, a light and comic dunk for the bird. The water language itself
  /// lives in [PirateSplashArt]; here each one is set on the swell where it
  /// landed.
  static void splashes(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) {
    final level = drawnLevel(boss, m);
    if (level == null) return;
    final h = size.height;
    final t = _time(sim, m);
    final areas = <Rect>[];
    for (final splash in sim.seaSplashes) {
      final age = sim.elapsed - splash.at;
      if (age < 0 || age > 1.2) continue;
      final at = Offset(
        splash.x * h,
        (level + wave(splash.x, sim.distance, t)) * h,
      );
      final seed = (splash.at * 1000).round();
      if (splash.bird) {
        PirateSplashArt.bird(c, h, at, age, reduced: m.reducedMotion, seed: seed);
      } else {
        PirateSplashArt.ball(c, h, at, age, reduced: m.reducedMotion, seed: seed);
      }
      areas.add(
        Rect.fromLTRB(at.dx - h * .16, at.dy - h * .32, at.dx + h * .16, at.dy),
      );
    }
    _ballsOver(c, h, sim, boss, m, areas);
  }

  /// Cannonballs are the fight's hazard and must stay the clearest thing on
  /// screen, so one that passes through an effect is set back on top of it.
  static void _ballsOver(
    Canvas c,
    double h,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
    List<Rect> areas,
  ) {
    if (areas.isEmpty) return;
    for (final ball in sim.bossAmmo) {
      if (!ball.cannonball) continue;
      final at = Offset(ball.x * h, ball.y * h), r = ball.radius * h;
      if (!areas.any((area) => area.inflate(r).contains(at))) continue;
      BossAmmoArt.paint(
        c,
        center: at,
        radius: r,
        direction: math.atan2(ball.vy, ball.vx),
        attack: EnemyAttack.none,
        kind: boss.kind,
        enraged: boss.enraged,
        speed: math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy),
        seconds: sim.elapsed,
        reducedMotion: m.reducedMotion,
        showTrail: false,
      );
    }
  }

  /// A crown of water thrown up round the point of entry: [lobes] rounded
  /// tips, [width] across and [height] tall at the middle.
  static void _crown(
    Canvas c,
    double h,
    Offset at,
    double width,
    double height,
    int lobes,
    double fade,
  ) => PirateSplashArt.crown(c, h, at, width, height, lobes, fade);

  // ------------------------------------------------------- hull knocks --

  /// A shot that glanced off the armored hull rings off it: a flash and ward
  /// arc where it struck, sparks, splinters and dust, and a pale gouge that
  /// lingers a moment in the planking.
  static void hullKnocks(
    Canvas c,
    double h,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) {
    final level = (drawnLevel(boss, m) ?? SkyBoss.seaLevel) * h;
    final areas = <Rect>[];
    for (final rock in sim.rocks) {
      final age = rock.reboundAge;
      if (age == null || age > .75) continue;
      // Back out the rebound to the point of impact.
      final at = Offset(
        rock.x - rock.velocityX * age,
        rock.y - (-.18 * age + .9 * age * age),
      );
      if (at.dy < boss.y + SkyBoss.hullTop - .03) continue;
      PirateSplashArt.knock(
        c,
        h,
        at * h,
        age,
        reduced: m.reducedMotion,
        seed: (at.dy * 1000).round(),
        level: level,
        power: 1 + rock.charge * .5,
      );
      if (age < .2) areas.add(Rect.fromCircle(center: at * h, radius: h * .1));
    }
    _ballsOver(c, h, sim, boss, m, areas);
  }

  // ------------------------------------------------------------ aim marks --

  /// Where each cannonball will cross the bird's flight line: a treasure-map
  /// X in a closing ring, and a tag at the top edge for a lob that has
  /// climbed out of view. See [PirateAimArt].
  static void aimMarks(
    Canvas c,
    Size size,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) => PirateAimArt.paint(c, size, sim, boss, m);
}
