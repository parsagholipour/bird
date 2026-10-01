import 'dart:math' as math;

import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'campaign_flight.dart';
import 'ny_plans.dart';

/// Shared by the King Coo rules tests (R2): a test-only 3-2, a flight stopped
/// as he begins to fight, precise stepping, a state snapshot, and a bot that
/// dodges his hazards and shoots his chest.

const birdX = FlightSimulation.birdX, birdRadius = FlightSimulation.birdRadius;

/// King Coo's anchor column on a screen [width] screen heights wide.
double bossColumn(double width) => math.max(birdX + .70, width - .55);

/// A simplified 3-2 (the catalog's real plan has the pigeon lineup and
/// flocks, see ny_campaign_data_test): a pigeon and bat
/// run-up, then King Coo. TEST ONLY.
LevelPlan cooPlan({
  double length = 30,
  List<EnemyKind> lineup = const [EnemyKind.simpleBat, EnemyKind.alleyPigeon],
}) => nyPlan(id: '3-2', length: length, lineup: lineup, boss: BossKind.kingCoo);

/// 3-2 as a campaign level, a guardian. TEST ONLY.
CampaignLevel cooLevel({LevelPlan? plan}) => CampaignLevel(
  name: 'Wheels in the Rain',
  delivery: const Delivery(
    'Umbrellas for the newsstand pigeons',
    from: 'Newsstand Nell',
    thanks: 'Thanks',
  ),
  bossLine: 'Nobody flies till the bread cart is found!',
  plan: plan ?? cooPlan(),
);

/// A flight of [plan] stopped as King Coo's arrival ends and the fight
/// begins (combat time 0 to 0.02 s).
FlightSimulation cooFight({
  LevelPlan? plan,
  double width = 2.2,
  int weaponDamage = 30,
}) {
  final sim = nyFlight(plan ?? cooPlan(), weaponDamage: weaponDamage);
  flyLevel(
    sim,
    viewportWidth: width,
    until: (sim) => sim.boss?.phase == BossPhase.attacking,
  );
  expectFighting(sim);
  // A bird at full health with a full reserve and its sprint ready: the
  // run-up's knocks, shots and sprints are not part of the fight under test.
  sim
    ..hearts = 3
    ..shield = true
    ..invulnerableUntil = 0
    ..ammo = 1
    ..chargeStartedAt = null
    ..lastShotAt = double.negativeInfinity
    ..lastSprintAt = double.negativeInfinity;
  return sim;
}

void expectFighting(FlightSimulation sim) {
  if (sim.boss?.phase != BossPhase.attacking) {
    throw StateError('King Coo is not fighting: ${sim.boss?.phase}');
  }
}

/// One tick of [dt] seconds with the bird tapping or not.
void tick(
  FlightSimulation sim, {
  double dt = 1 / 120,
  double width = 2.2,
  bool flap = false,
}) {
  final now = (sim.lastValidMs.isFinite ? sim.lastValidMs : 0.0) + dt * 1000;
  sim.apply(
    MovementInput(valid: true, height: .5, flap: flap),
    touchAt(now),
    now,
  );
  sim.tick(dt, now, viewportWidth: width);
}

/// Runs the fight [seconds] on in 1/120 s ticks. [hold] pins the bird at
/// that height with no speed (before every tick); [flap] says when it taps;
/// [protect] keeps it from being hurt at all; [each] sees the flight after
/// every tick and [until] stops early.
void run(
  FlightSimulation sim,
  double seconds, {
  double width = 2.2,
  double? hold,
  bool Function(FlightSimulation sim)? flap,
  bool protect = false,
  bool Function(FlightSimulation sim)? shootWhen,
  void Function(FlightSimulation sim)? each,
  bool Function(FlightSimulation sim)? until,
}) {
  final end = sim.elapsed + seconds;
  while (sim.elapsed < end - 1e-9 && sim.phase == RunPhase.playing) {
    if (until?.call(sim) ?? false) return;
    if (hold != null) {
      sim.birdY = hold;
      sim.velocity = 0;
    }
    if (protect) sim.invulnerableUntil = double.infinity;
    if (shootWhen?.call(sim) ?? false) sim.shoot();
    tick(sim, width: width, flap: flap?.call(sim) ?? false);
    each?.call(sim);
  }
}

/// Runs until the boss's combat clock reaches [t].
void runTo(
  FlightSimulation sim,
  double t, {
  double width = 2.2,
  double? hold,
  bool protect = false,
  bool Function(FlightSimulation sim)? flap,
  void Function(FlightSimulation sim)? each,
}) {
  run(
    sim,
    1000,
    width: width,
    hold: hold,
    protect: protect,
    flap: flap,
    each: each,
    until: (sim) => sim.boss!.combatTime >= t - 1e-9,
  );
}

/// Everything King Coo's fight can change, for determinism and seek checks.
Object cooSnapshot(FlightSimulation sim) {
  final boss = sim.boss;
  return [
    sim.elapsed,
    sim.phase,
    sim.score,
    sim.shots,
    sim.enemiesDefeated,
    sim.bossesDefeated,
    sim.birdY,
    sim.velocity,
    sim.hearts,
    sim.shield,
    sim.invulnerableUntil,
    sim.ammo,
    sim.rocks.map((r) => [r.x, r.y, r.damage]).toList(),
    sim.enemies
        .map((e) => [e.x, e.y, e.hp, e.squad, e.track?.lane, e.age])
        .toList(),
    sim.bossAmmo.length,
    if (boss != null)
      [
        boss.phase,
        boss.hp,
        boss.x,
        boss.y,
        boss.age,
        boss.defeatedAt,
        boss.lastHitAt,
        boss.lastPuffHitAt,
        boss.puffDamage,
        boss.poppedAt,
        boss.pops,
        boss.whistles,
        boss.puffs,
        boss.crumbHits,
        boss.lobCycle,
        boss.lobsInCycle,
        boss.lobFury,
        boss.puffsLatched,
        boss.whistlesLatched,
        boss.squadReleased,
        boss.squadCalled,
        boss.lobsLocked,
        boss.lobsLaunched,
        boss.lobBursts,
        boss.lobs.map((l) => [l.lockedAt, l.lockX, l.lockY, l.fury]).toList(),
        boss.squad
            .map(
              (p) => [
                p.shape,
                p.delay,
                p.gap,
                p.slots.map((s) => [s.behind, s.y]).toList(),
              ],
            )
            .toList(),
        boss.cooHint,
      ],
  ];
}

/// Squadron pigeons on screen.
List<SkyEnemy> squadOf(FlightSimulation sim) => [
  for (final e in sim.enemies)
    if (e.squad) e,
];

/// A danger to avoid: a circle (radius plus the bird's) at height [y] from
/// boss-age [from] to [to].
typedef Danger = ({double y, double reach, double from, double to});

/// What King Coo can hurt the bird with right now and next, read from the
/// boss's own state the way the screen telegraphs it: each cloud from its
/// ring (2.2 s ahead), each squadron lane from the puff (2.8 s ahead). A
/// bird that sees it after [react] seconds and only steers for a hazard once
/// it is within [cloudLook] of its burst or [squadLook] of its crossing
/// (the fairness proof's slack is 0.9 s and 1.3 s at least) keeps the
/// heights a hazard forbids free for the rest, and never crosses one
/// hazard to dodge another that is still far off.
List<Danger> dangersOf(
  FlightSimulation sim, {
  double react = 0,
  double cloudLook = 1.3,
  double squadLook = 1.6,
}) {
  final boss = sim.boss;
  if (boss == null || boss.phase != BossPhase.attacking) return const [];
  final out = <Danger>[];
  for (final lob in boss.lobs) {
    if (boss.age >= lob.cloudEndsAt) continue;
    for (final y in lob.cloudHeights) {
      out.add((
        y: y,
        reach: KingCoo.cloudRadius + birdRadius,
        from: math.max(lob.lockedAt + react, lob.burstAt - cloudLook),
        to: lob.cloudEndsAt,
      ));
    }
  }
  final cycle = boss.cooCycleNumber;
  final cycleStart = boss.arrivalDuration + cycle * KingCoo.period;
  for (final plan in boss.squad) {
    final releaseAt = cycleStart + KingCoo.whistleAt + plan.delay;
    for (final slot in plan.slots) {
      final track = SquadTrack(
        x0: boss.x + slot.behind,
        fromY: boss.y,
        lane: slot.y,
        bornAt: releaseAt,
      );
      final cross = track.crossesAt(birdX);
      if (boss.age > cross + .3) continue;
      out.add((
        y: slot.y,
        reach: SkyEnemy.radius + birdRadius,
        from: math.max(cycleStart + KingCoo.puffAt + react, cross - squadLook),
        to: cross + .3,
      ));
    }
  }
  return out;
}

/// A player who dodges King Coo's telegraphed hazards and trades shots with
/// his chest: it flies the firing line (his height) unless a hazard forbids
/// it, then the nearest lane that keeps [margin] from every hazard, tapping
/// at most [tapsPerSecond] times a second, shooting when its rock would
/// reach his chest.
class CooBot {
  CooBot({
    this.react = 0,
    this.margin = .03,
    this.tapsPerSecond = 5.0,
    this.aim = .09,
    this.gap = 0,
    this.line,
    this.cloudLook = 1.3,
    this.squadLook = 1.6,
    this.sequential = false,
  });

  /// How long before a bomb bursts, and before a squadron pigeon crosses,
  /// the bot starts steering clear of it ([dangersOf]); a huge [squadLook]
  /// makes it plan for the whole formation as soon as it has reacted.
  final double cloudLook, squadLook;

  /// Whether it plans a squadron one formation at a time, the way a player
  /// reads it: as soon as it has reacted it steers clear of the whole of the
  /// formation that crosses first (every lane at once, not one pigeon at a
  /// time), and only when that has passed does it turn to the next (fury's
  /// picket comes 1.4 s after its V), choosing the corridor that lies nearer
  /// the next one's gap. The default (false) looks at every lane of every
  /// formation at once, each from [squadLook] before its crossing, which has
  /// no height to go to for fury's V and picket together: they are never
  /// over the bird at the same time, but their lanes together shade the
  /// whole sky.
  final bool sequential;

  /// Where it flies when nothing threatens: his height unless told otherwise
  /// (a bot that flies elsewhere misses, and so lengthens the fight).
  final double Function(FlightSimulation sim)? line;

  /// Seconds before a danger it sees it ([react]), the room it keeps from
  /// it ([margin]), its taps a second, how far off his chest's height it
  /// will still shoot ([aim]) and the least time between its shots ([gap],
  /// on top of the weapon's own cooldown and reserve).
  final double react, margin, tapsPerSecond, aim, gap;

  static const hoverUp = .08, hoverDown = .05;

  double target(FlightSimulation sim) {
    final boss = sim.boss!;
    final line = this.line?.call(sim) ?? boss.y;
    double? nextGap;
    final List<Danger> active;
    if (sequential) {
      (active, nextGap) = _sequentialDangers(sim);
    } else {
      active = [
        for (final d in dangersOf(
          sim,
          react: react,
          cloudLook: cloudLook,
          squadLook: squadLook,
        ))
          if (boss.age >= d.from && boss.age <= d.to) d,
      ];
    }
    // A tapping bird hovers: it climbs [hoverUp] above its goal and sinks
    // [hoverDown] below it, and that whole band must be clear of danger.
    bool free(double y) {
      final top = y - hoverUp, bottom = y + hoverDown;
      if (top < .07 || bottom > .93) return false;
      return active.every(
        (d) => bottom < d.y - d.reach - margin || top > d.y + d.reach + margin,
      );
    }

    if (free(line)) return line;
    var best = line, cost = double.infinity;
    for (var y = .1; y <= .9001; y += .01) {
      if (!free(y)) continue;
      final c =
          (y - line).abs() +
          .3 * (y - sim.birdY).abs() +
          (nextGap == null ? 0 : .3 * (y - nextGap).abs());
      if (c < cost) {
        cost = c;
        best = y;
      }
    }
    return best;
  }

  /// The dangers of [sequential] planning: the bombs as [dangersOf] sees
  /// them, and the lanes of the one formation that crosses first (once the
  /// bot has reacted to the puff), with the gap or tip of the next.
  (List<Danger>, double?) _sequentialDangers(FlightSimulation sim) {
    final boss = sim.boss!;
    final out = [
      for (final d in dangersOf(
        sim,
        react: react,
        cloudLook: cloudLook,
        squadLook: -double.maxFinite,
      ))
        if (boss.age >= d.from && boss.age <= d.to) d,
    ];
    final cycleStart =
        boss.arrivalDuration + boss.cooCycleNumber * KingCoo.period;
    var current = true;
    double? next;
    for (final plan in boss.squad) {
      final release = cycleStart + KingCoo.whistleAt + plan.delay;
      final last =
          [
            for (final slot in plan.slots)
              SquadTrack(
                x0: boss.x + slot.behind,
                fromY: boss.y,
                lane: slot.y,
                bornAt: release,
              ).crossesAt(birdX),
          ].reduce(math.max) +
          .3;
      if (boss.age > last) continue;
      if (current) {
        current = false;
        if (boss.age >= cycleStart + KingCoo.puffAt + react) {
          for (final slot in plan.slots) {
            out.add((
              y: slot.y,
              reach: SkyEnemy.radius + birdRadius,
              from: 0,
              to: double.maxFinite,
            ));
          }
        }
      } else {
        next ??= plan.gap ?? plan.slots.first.y;
      }
    }
    return (out, next);
  }

  bool flap(FlightSimulation sim) {
    if (sim.elapsed - sim.lastFlapAt < 1 / tapsPerSecond - 1e-9) return false;
    final goal = target(sim);
    return sim.birdY > goal + hoverDown && sim.velocity > -.25;
  }

  /// Fire when the bird is level with his chest.
  bool shoot(FlightSimulation sim) =>
      sim.canShoot &&
      sim.elapsed - sim.lastShotAt >= gap &&
      (sim.birdY - sim.boss!.y).abs() <= aim;
}

/// Flies King Coo's whole fight with [bot]: until he is beaten, the flight
/// ends or [seconds] pass. Returns the combat seconds it took.
double fightBot(
  FlightSimulation sim,
  CooBot bot, {
  double width = 2.2,
  double seconds = 240,
  bool protect = false,
  void Function(FlightSimulation sim)? each,
}) {
  final boss = sim.boss!;
  run(
    sim,
    seconds,
    width: width,
    protect: protect,
    flap: bot.flap,
    shootWhen: bot.shoot,
    each: each,
    until: (sim) => boss.phase == BossPhase.defeated,
  );
  return boss.combatTime;
}

double distance(double ax, double ay, double bx, double by) =>
    math.sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));
