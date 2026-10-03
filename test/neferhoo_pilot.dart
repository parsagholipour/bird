import 'dart:math' as math;

import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart';
import 'gargoyle_pilot.dart' show frame;

/// Test pilots for Neferhoo (rules version 50, level 2-6): the design's fight
/// model (`egypt-ws/reports/01-egypt-guardian/proof/ttk.dart`, King Coo's
/// bots) ported onto the REAL simulation. A pilot reads what a player reads
/// (the mail lane and the ankh's loop are drawn from their locks), notices
/// each telegraph after its reaction time, taps no faster than its tap rate,
/// stays in a letter's lane to shoot it back with its return chance (or
/// leaves the band), keeps out of the ankh's two bands, and fires at the
/// boss's height or a coming letter at its shot rate, through the real
/// weapon (cooldown, the ten-shot reserve and its refill). Tap shots only:
/// a charged shot's bulk return makes a real fight shorter.
///
/// Everything it reads is rules state: every letter and ankh on
/// [SkyBoss.neferhoo], dealt or still to come, and in the tougher fight
/// (rules 52) every mummy bat that has left his hand ([NeferhooBat]): it
/// notices one after its reaction time, and either stays in the lane to
/// shoot it down (with its return chance, as for a letter) or keeps out of
/// its band. Without bats (rules 50) it draws exactly what it drew before,
/// so its rules 50 fights are unchanged (`frozen_rules50_test.dart`). It
/// never keys a dodge on one hazard existing (the staged system's lesson: a
/// warm-up without the ankh must not switch the letter dodging off), and
/// every loop is bounded by a frame count and stops when the flight ends.

const birdX = FlightSimulation.birdX, birdR = FlightSimulation.birdRadius;
const dt = 1 / 60;

/// A player's skill, as the design's fight model has it.
class NeferhooSkill {
  const NeferhooSkill(
    this.name, {
    required this.react,
    required this.jitter,
    required this.tapsPerSecond,
    required this.aimTol,
    required this.fireRate,
    required this.margin,
    required this.returnChance,
    this.noise = 0,
    this.shoots = true,
  });
  final String name;

  /// Seconds from a telegraph (a lock) to noticing it, ± uniform [jitter].
  final double react, jitter;
  final double tapsPerSecond;

  /// How far from a lane (or his height) it still fires, its shots a second
  /// when aimed (twice that at a letter coming at it), and the extra room it
  /// keeps from a band it dodges.
  final double aimTol, fireRate, margin;

  /// The chance it stays in a letter's lane to shoot it back.
  final double returnChance;

  /// How far off its sense of its own height is when it judges a shot.
  final double noise;
  final bool shoots;

  NeferhooSkill copyWith({String? name, double? returnChance}) => NeferhooSkill(
    name ?? this.name,
    react: react,
    jitter: jitter,
    tapsPerSecond: tapsPerSecond,
    aimTol: aimTol,
    fireRate: fireRate,
    margin: margin,
    returnChance: returnChance ?? this.returnChance,
    noise: noise,
    shoots: shoots,
  );
}

/// The design's bots: a first-timer, a family player, a practised one, a
/// learner who rarely returns a letter, and a coarse, dodge-only player
/// (1.5 taps a second, a slow reaction, never shoots: a push-up-paced
/// player).
const kid = NeferhooSkill(
  'kid',
  react: .80,
  jitter: .30,
  tapsPerSecond: 2.5,
  aimTol: .06,
  fireRate: 1.0,
  margin: .06,
  returnChance: .45,
  noise: .07,
);
const family = NeferhooSkill(
  'family',
  react: .55,
  jitter: .20,
  tapsPerSecond: 3.5,
  aimTol: .08,
  fireRate: 1.6,
  margin: .04,
  returnChance: .75,
  noise: .05,
);
const expert = NeferhooSkill(
  'expert',
  react: .30,
  jitter: .10,
  tapsPerSecond: 5,
  aimTol: .11,
  fireRate: 3.5,
  margin: .02,
  returnChance: .95,
  noise: .02,
);
const learner = NeferhooSkill(
  'learner',
  react: .80,
  jitter: .30,
  tapsPerSecond: 2.5,
  aimTol: .06,
  fireRate: 1.0,
  margin: .06,
  returnChance: .15,
  noise: .07,
);
const coarse = NeferhooSkill(
  'coarse',
  react: .95,
  jitter: .30,
  tapsPerSecond: 1.5,
  aimTol: .06,
  fireRate: 0,
  margin: .03,
  returnChance: 0,
  shoots: false,
);

/// The screens the pilots fly, in screen heights: 576, 640, 800 and 864 px
/// wide at 360 tall (16:10, 16:9, 20:9 and 21.6:9).
const pilotWidths = [1.6, 640 / 360, 800 / 360, 2.4];

/// A pilot of [skill] for one fight; [seed] draws its reactions and shots.
class NeferhooPilot {
  NeferhooPilot(this.skill, {int seed = 1, this.careful = false})
    : _random = math.Random(seed);
  final NeferhooSkill skill;

  /// False (the default): the design model's policy to the letter, holes
  /// and all, so its tables compare. True: two holes closed (see [plan]): a
  /// bird a hair inside a band about to be swept leaves it by its nearer
  /// edge instead of crossing all of it, and a dodge picks a spot with room
  /// to hover (else the tightest free one) and never an aim that would bob
  /// the bird into a course edge.
  final bool careful;
  bool get model => !careful;
  final math.Random _random;
  final _noticed = <Object, double>{};
  final _engage = <NeferhooLetter, bool>{};
  final _engageBat = <NeferhooBat, bool>{};
  double _lastTap = double.negativeInfinity;
  double _lastShot = double.negativeInfinity;

  /// The height it aims for this frame, and the letters (and the lanes of
  /// the mummy bats) it is staying in the lane of (set by [plan]).
  double target = .5;
  List<NeferhooLetter> engaged = const [];
  List<double> engagedBats = const [];

  double _notice(Object hazard, double appears) => _noticed.putIfAbsent(
    hazard,
    () => appears + skill.react + (_random.nextDouble() * 2 - 1) * skill.jitter,
  );

  /// Reads the fight and picks [target] (the design's bot, per frame).
  void plan(FlightSimulation sim) {
    final boss = sim.boss!;
    final fight = boss.neferhoo;
    final age = boss.age, handX = boss.handX, y = sim.birdY;
    final forbidden = <(double, double)>[];
    final urgent = <(double, double)>[];
    final staying = <NeferhooLetter>[];
    for (final letter in fight.letters) {
      if (letter.gone || letter.returned) continue;
      // As the model: each letter draws the eye a wind-up before it is
      // flicked (the first one at the lock, the others as they come up).
      final appears = letter.releaseAt - Neferhoo.windupSeconds;
      if (age < _notice(letter, appears)) continue;
      final x = letter.xAt(age, handX);
      if (x < birdX - .1) continue;
      final arrive = (x - birdX) / letter.speed;
      final engage = _engage.putIfAbsent(
        letter,
        () => skill.shoots && _random.nextDouble() < skill.returnChance,
      );
      // Bail out of the lane when it is close and still coming.
      final bail = .45 + skill.react * .5;
      if (engage && arrive > bail && age >= letter.releaseAt - 1.0) {
        staying.add(letter);
      } else if (arrive < 2.5) {
        const half = Neferhoo.letterHalfHeight + birdR;
        final band = (
          letter.lane - half - skill.margin,
          letter.lane + half + skill.margin,
        );
        forbidden.add(band);
        if (arrive < 1.0) urgent.add(band);
      }
    }
    // The tougher fight's mummy bats, as the letters: in the lane to shoot
    // them down, or out of their band. (None at rules 50: nothing drawn.)
    final batLanes = <double>[];
    final scroll = sim.speed * sim.courseBoost;
    for (final bat in fight.bats) {
      final enemy = bat.enemy;
      if (enemy == null) break;
      if (bat.goneAt != null || !sim.enemies.contains(enemy)) continue;
      if (age < _notice(bat, age - enemy.age)) continue;
      final x = enemy.x;
      if (x < birdX - .1) continue;
      final arrive = (x - birdX) / (scroll * enemy.drift);
      final engage = _engageBat.putIfAbsent(
        bat,
        () => skill.shoots && _random.nextDouble() < skill.returnChance,
      );
      final bail = .45 + skill.react * .5;
      if (engage && arrive > bail) {
        batLanes.add(bat.lane);
      } else if (arrive < 2.5) {
        const half = SkyEnemy.radius + birdR;
        final band = (
          bat.lane - half - skill.margin,
          bat.lane + half + skill.margin,
        );
        forbidden.add(band);
        if (arrive < 1.0) urgent.add(band);
      }
    }
    engagedBats = batLanes;
    final turnX = Neferhoo.turnX(birdX);
    for (final ankh in fight.ankhs) {
      if (ankh.caughtAt != null) continue;
      if (age < _notice(ankh, ankh.lockedAt)) continue;
      if (age > ankh.homeAt(handX: handX, turnX: turnX)) continue;
      final (out, back) = ankh.passes(
        handX: handX,
        turnX: turnX,
        column: birdX,
      );
      const half = Neferhoo.ankhRadius + birdR;
      final outBand = (
        ankh.laneA - half - skill.margin,
        ankh.laneA + half + skill.margin,
      );
      final backBand = (
        ankh.laneB - half - skill.margin,
        ankh.laneB + half + skill.margin,
      );
      if (age < out + .3) forbidden.add(outBand);
      if (age < back + .3) forbidden.add(backBand);
      if (age > out - 1.0 && age < out + .3) urgent.add(outBand);
      if (age > back - 1.0 && age < back + .3) urgent.add(backBand);
    }
    engaged = staying;
    final line = boss.y;
    var goal = staying.isNotEmpty
        ? staying.first.lane
        : batLanes.isNotEmpty
        ? batLanes.first
        : line;
    bool free(double yy) {
      for (final (a, b) in forbidden) {
        if (yy >= a && yy <= b) return false;
      }
      return yy >= .08 && yy <= .92;
    }

    // A band about to be swept is never crossed. The model lets a bird
    // inside one cross all of it; a careful pilot leaves by the nearer edge.
    bool crosses(double yy) {
      for (final (a, b) in urgent) {
        if (model) {
          final inside = y > a && y < b;
          if (!inside && math.min(y, yy) < b && math.max(y, yy) > a) {
            return true;
          }
          continue;
        }
        if (y > a && y < b) {
          final upper = y - a < b - y;
          if ((upper && yy > b) || (!upper && yy < a)) return true;
        } else if (math.min(y, yy) < b && math.max(y, yy) > a) {
          return true;
        }
      }
      return false;
    }

    // Room to hover: a tap-flying bird bobs from about .07 above its aim to
    // .065 below it, so a spot needs that much free sky round it, and an
    // aim nearer an edge than .12 would bob the bird into it.
    bool roomy(double yy) {
      for (var d = -7; d <= 7; d++) {
        if (!free(yy + d / 100)) return false;
      }
      return true;
    }

    final lo = model ? 8 : 12, hi = model ? 92 : 88;
    if (!free(goal) ||
        crosses(goal) ||
        (!model && staying.isEmpty && forbidden.isNotEmpty && !roomy(goal))) {
      // The cheapest spot with room to hover; else (a tight squeeze) the
      // cheapest free one; else stay the course.
      double? best, tight;
      var bestCost = double.infinity, tightCost = double.infinity;
      for (var i = lo; i <= hi; i++) {
        final yy = i / 100;
        if (!free(yy) || crosses(yy)) continue;
        final cost = (yy - goal).abs() + .3 * (yy - y).abs();
        final spacious = model ? _modelRoom(free, yy) : roomy(yy);
        if (spacious) {
          if (cost < bestCost) {
            bestCost = cost;
            best = yy;
          }
        } else if (!model && cost < tightCost) {
          tightCost = cost;
          tight = yy;
        }
      }
      goal = best ?? tight ?? goal;
    }
    target = goal;
  }

  /// The model's room rule: .07 of free sky each way, except near an edge.
  static bool _modelRoom(bool Function(double) free, double yy) {
    if (yy < .14 || yy > .86) return true;
    for (var d = 0; d <= 12; d++) {
      if (!free(yy - d / 100) || !free(yy + d / 100)) return d >= 7;
    }
    return true;
  }

  /// Whether to tap this frame (after [plan]).
  bool flap(FlightSimulation sim) {
    if (sim.elapsed - _lastTap < 1 / skill.tapsPerSecond - 1e-9) return false;
    if (sim.birdY <= target + .06) return false;
    _lastTap = sim.elapsed;
    return true;
  }

  /// Whether to fire this frame (after [plan]): level with a letter it
  /// stays in the lane of (at twice its rate) or with his height.
  bool shoot(FlightSimulation sim) {
    if (!skill.shoots || !sim.canShoot) return false;
    if (sim.elapsed - _lastShot < FlightSimulation.shotCooldown) return false;
    final boss = sim.boss!;
    final sensed =
        sim.birdY +
        (_random.nextDouble() +
                _random.nextDouble() +
                _random.nextDouble() -
                1.5) *
            2 *
            skill.noise;
    final atLetter =
        engaged.any((letter) => (sensed - letter.lane).abs() <= skill.aimTol) ||
        engagedBats.any((lane) => (sensed - lane).abs() <= skill.aimTol);
    final aimed = atLetter || (sensed - boss.y).abs() <= skill.aimTol + .06;
    final rate = atLetter ? skill.fireRate * 2 : skill.fireRate;
    if (!aimed || _random.nextDouble() >= rate * dt) return false;
    _lastShot = sim.elapsed;
    return true;
  }
}

/// A flight of 2-6 stopped as Neferhoo begins to fight (combat time about
/// 0), the run-up flown by the shared bot with no sprint at [width] screen
/// heights. The bird sits at [startY] (mid-height) at rest with the shield
/// up, three hearts and a full reserve. [version] is the rules flown.
FlightSimulation neferhooArena({
  double width = 640 / 360,
  int weaponDamage = BirdRock.baseDamage,
  double startY = .5,
  int version = FlightSimulation.currentRulesVersion,
}) {
  final sim = levelFlight(
    Campaign.level('2-6')!,
    weaponDamage: weaponDamage,
    version: version,
  );
  flyLevel(
    sim,
    viewportWidth: width,
    sprintWhen: (sim, frame) => false,
    until: (sim) => sim.boss?.phase == BossPhase.attacking,
    seconds: 120,
  );
  final boss = sim.boss;
  if (boss == null || !boss.isNeferhoo || boss.phase != BossPhase.attacking) {
    throw StateError('the flight did not reach Neferhoo');
  }
  sim
    ..rocks.clear()
    ..birdY = startY
    ..velocity = 0
    ..hearts = 3
    ..shield = true
    ..ammo = 1
    ..invulnerableUntil = 0;
  return sim;
}

/// What one fight showed.
class NeferhooFightRun {
  NeferhooFightRun(this.sim, this.boss);
  final FlightSimulation sim;
  final SkyBoss boss;

  /// Combat seconds from control back to the killing blow, or null when he
  /// was not beaten (a knock-out, or the time ran out).
  double? fight;

  /// Combat seconds at which he grew stronger, and reached fury.
  double? fullAt, furyAt;

  /// Hurts the bird took (shield or heart), and of those by a letter, by an
  /// ankh and by a course edge.
  int hits = 0;
  int get letterHits => boss.neferhoo.letterHits;
  int get ankhHits => boss.neferhoo.ankhHits;

  /// Seconds flown in the fight.
  double seconds = 0;
  bool get knockedOut => sim.endReason == EndReason.collision;
  int get returns => boss.neferhoo.returnsLanded;
}

/// Flies [sim] (from [neferhooArena]) with [pilot] until he falls, the bird
/// is knocked out, or [seconds] of fight pass. [phase] frames of idling
/// first (a player does not start on the level's beat). [keepAlive] tops
/// the hearts up (hits per minute of an immortal pilot); [stage] first takes
/// him to that stage with one blow (0: as he arrives).
NeferhooFightRun flyNeferhoo(
  FlightSimulation sim,
  NeferhooPilot pilot, {
  double width = 640 / 360,
  int phase = 0,
  double seconds = 300,
  bool keepAlive = false,
  int stage = 0,
}) {
  final boss = sim.boss!;
  if (stage > 0) {
    final share = stage == 1 ? 2 / 3 : 1 / 3;
    final to = (boss.maxHp * share).floor();
    if (boss.hp > to) boss.takeDamage(boss.hp - to);
  }
  final run = NeferhooFightRun(sim, boss);
  var hearts = sim.hearts;
  var shield = sim.shield;
  final start = sim.elapsed;
  final frames = (seconds / dt).round();
  for (var i = 0; i < frames; i++) {
    if (boss.phase != BossPhase.attacking) break;
    if (keepAlive && sim.hearts < 2) sim.hearts = 3;
    var tap = false;
    if (i >= phase % 30) {
      pilot.plan(sim);
      tap = pilot.flap(sim);
      if (pilot.shoot(sim)) sim.shoot();
    }
    hearts = sim.hearts;
    shield = sim.shield;
    frame(sim, flap: tap, width: width);
    if (sim.hearts < hearts || (shield && !sim.shield)) run.hits++;
    if (boss.stageReached >= 1) run.fullAt ??= boss.combatTime;
    if (boss.stageReached >= 2) run.furyAt ??= boss.combatTime;
    if (sim.phase == RunPhase.ended) break;
  }
  run.seconds = sim.elapsed - start;
  if (boss.defeatedAt case final at?) {
    run.fight = at - boss.arrivalDuration;
  }
  return run;
}

/// The p-quantile of [values] (sorted in place).
double quantile(List<double> values, double p) {
  values.sort();
  return values[(p * (values.length - 1)).round()];
}

/// A table row: median (p10 to p90) fight seconds of the beaten fights, the
/// knock-out share, hits a fight, returns a fight.
String row(String label, List<NeferhooFightRun> runs) {
  final won = [for (final r in runs) ?r.fight];
  final ko = runs.where((r) => r.knockedOut).length;
  final hits = runs.fold(0, (s, r) => s + r.hits) / runs.length;
  final returns = runs.fold(0, (s, r) => s + r.returns) / runs.length;
  final letters = runs.fold(0, (s, r) => s + r.letterHits) / runs.length;
  final ankhs = runs.fold(0, (s, r) => s + r.ankhHits) / runs.length;
  final fmt = won.isEmpty
      ? '   -'
      : '${quantile([...won], .5).toStringAsFixed(0).padLeft(4)} '
            '(${quantile([...won], .1).toStringAsFixed(0)}-'
            '${quantile([...won], .9).toStringAsFixed(0)})';
  return '${label.padRight(16)} fight $fmt s  won ${won.length}/${runs.length}'
      '  KO ${(ko * 100 / runs.length).toStringAsFixed(0)}%'
      '  hits ${hits.toStringAsFixed(2)} (letter ${letters.toStringAsFixed(2)},'
      ' ankh ${ankhs.toStringAsFixed(2)})  returns ${returns.toStringAsFixed(1)}';
}

/// The start height of fight [s] of a varied sample: .40 to .60, spread so
/// a sample never meets his clock from one place only (a single start
/// phase-locks a deterministic bot to his bob: the design's coarse figures
/// were one such phase).
double variedStart(int s) => .40 + .2 * ((s * 37) % 100) / 100;
