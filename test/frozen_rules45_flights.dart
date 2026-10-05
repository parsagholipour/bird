import 'dart:convert';

import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'endless_plan_baseline_test.dart' show CountingRandom, stateOf;
import 'frozen_flights.dart' show FrozenResult, fnvHex, outcomeOf;
import 'ny_pilots.dart';
import 'recorded_flight.dart';
import 'retuned_levels.dart';

/// Helpers for the frozen rules 45 fixtures (test/fixtures/frozen_rules45.json
/// and test/fixtures/frozen_rules45_tapes/). The Egypt program (rules 50,
/// Neferhoo on a new level 2-6) recorded them from `egypt-int/base` (rules 45,
/// boss stages and the tougher King Coo) BEFORE its first change, to prove
/// that endless, co-op and duel flights, every level of chapters 1 to 3 that
/// was playable (the 16 of chapters 1 and 2 and New York's four, staged
/// bosses and guardians included) and tapes saved at 45 fly byte-identically
/// at 46.
///
/// Level ids are the ones the base used ([frozen45Levels]); Ancient Arabia
/// moved from 2-6..2-8 to 2-7..2-9 when 2-6 became Neferhoo's level, so a
/// frozen id is looked up through [currentIdOf]. A plan's `id` is the only
/// thing that renumbering changes: the catalog entry compares the plan JSON
/// with the frozen id written back in.
///
/// The bot loops are copied here (as in `frozen_flights.dart`) so that later
/// edits to `campaign_flight.dart` cannot move a digest. The New York pilot
/// flights are `ny_pilots.dart`'s (their digests also pin those pilots; the
/// tapes do not depend on them).

/// The rules version the fixtures were frozen at.
const frozen45Version = 45;

/// The 20 levels of chapters 1 to 3 that rules 45 could fly, by the ids the
/// base gave them.
const frozen45Levels = [
  '1-1', '1-2', '1-3', '1-4', '1-5', '1-6', '1-7', '1-8', //
  '2-1', '2-2', '2-3', '2-4', '2-5', '2-6', '2-7', '2-8', //
  '3-1', '3-2', '3-3', '3-4',
];

/// The catalog's id now for a level the base called [frozenId]: Ancient
/// Arabia's three levels moved up by one when Egypt gained its guardian
/// level (see `CampaignIds.renumbered`).
String currentIdOf(String frozenId) => CampaignIds.level(frozenId);

/// The level the base called [frozenId], as the catalog has it now (or as
/// recorded, when it was retuned since: see [asRecorded]).
CampaignLevel frozenLevel(String frozenId) =>
    asRecorded(Campaign.level(currentIdOf(frozenId))!);

String _n(double value) => value.toString();

/// Everything [stateOf] writes, plus what rules 43 to 45 added that it does
/// not: the staged boss's stage, the vanguard, King Coo's and the Gargoyle's
/// latches, the steam vents, the pigeon counters and a second bird.
String frozenState(FlightSimulation sim) {
  final b = StringBuffer(stateOf(sim));
  final boss = sim.boss;
  if (boss != null) {
    b
      ..write('stage ${boss.staged} ${boss.stage}/${boss.stageReached} ')
      ..write('up=${_n(boss.stageUpAt)} sig=${boss.signatureCycle} ')
      ..write('hit=${_n(boss.lastHitAt)}/${_n(boss.previousHitAt)} ')
      ..write('fury=${_n(boss.enragedAt)} def=${boss.defeatedAt}\n')
      ..write('coo lobs=${boss.lobs.length} cyc=${boss.lobCycle}/')
      ..write('${boss.lobsInCycle}/${boss.lobFury} puffs=${boss.puffsLatched} ')
      ..write('wh=${boss.whistlesLatched}/${boss.whistles} ')
      ..write('squad=${boss.squadReleased}/${boss.squadCalled}/')
      ..write('${boss.squad.length} pops=${boss.pops} ')
      ..write('pd=${boss.puffDamage} crumbs=${boss.crumbHits}\n')
      ..write('garg aimed=${boss.sweepsAimed} side=${boss.beamSide.name} ')
      ..write('slit=${boss.slitSweep} zone=${boss.sweepZone}/')
      ..write('${boss.sweepSlit} feathers=${boss.feathersLaunched} ')
      ..write('spots=${boss.spots} fury=${boss.furySweeps} ')
      ..write('fc=${boss.featherCycle}/${boss.featherSlot}\n');
  }
  final guard = sim.vanguard;
  if (guard != null) {
    b
      ..write('vanguard ${guard.boss.name} ${_n(guard.startedAt)} ')
      ..write('sent=${guard.wavesSent} members=${guard.members.length} ')
      ..write('gone=${guard.goneAt.length} down=${guard.downed} ')
      ..write('cleared=${guard.clearedAt} slots=${guard.returnSlots} ')
      ..write('strag=${guard.stragglers.length}/')
      ..write('${guard.stragglerDownedAt.length}\n');
  }
  for (final vent in sim.steamVents) {
    b
      ..write('steam ${_n(vent.x)} ${vent.hissCycle} ${vent.burstCycle} ')
      ..write('${vent.touched} ${vent.scalded} ${vent.rode} ${vent.passed} ')
      ..write('${_n(vent.lifted)}\n');
  }
  b
    ..write('pigeons ${sim.pigeonWarnings} ${sim.pigeonDives} ')
    ..write('${sim.starsSnatched} ${sim.starsFreed} ${sim.starsLost} ')
    ..write('${sim.pigeonsDefeated} steam ${sim.steamHisses} ')
    ..write('${sim.steamBursts} ${sim.steamRides} ${sim.steamScalds} ')
    ..write('${sim.steamClears}\n');
  for (final enemy in sim.enemies) {
    b.write('e+ ${enemy.squad} ${enemy.throwsCrumbs}\n');
  }
  if (sim.paired) {
    for (final bird in sim.flock) {
      b
        ..write('bird ${_n(bird.x)} ${_n(bird.y)} ${_n(bird.velocity)} ')
        ..write('${_n(bird.vx)} ${bird.flaps} ${bird.hearts} ${bird.shield} ')
        ..write('${_n(bird.invulnerableUntil)} ${bird.stars} ')
        ..write('${_n(bird.ammo)} ${bird.shots} ${bird.boxesOpened}\n');
    }
    b
      ..write('boxes ${sim.boxes.length} ${sim.boxesOpened} ')
      ..write('${sim.rivalStrikes} ropes ${sim.ropeSnaps}\n');
  }
  return b.toString();
}

/// A running FNV hash of [frozenState] after every simulated second,
/// checkpointed every ten seconds and at the end.
class FrozenDigest {
  final List<String> checkpoints = [];
  int _hash = 0xcbf29ce484222325;

  void sample(FlightSimulation sim, int second) {
    for (final unit in frozenState(sim).codeUnits) {
      _hash ^= unit;
      _hash = (_hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    if (second % 10 == 0 || second < 0) {
      checkpoints.add(_hash.toRadixString(16));
    }
  }

  static String summary(FlightSimulation sim) =>
      't=${sim.elapsed.toStringAsFixed(2)} ${sim.phase.name} '
      '${sim.endReason?.name} score=${sim.score} gates=${sim.gates} '
      'stars=${sim.collectedStars} hearts=${sim.hearts} '
      'bosses=${sim.bossesDefeated} enemies=${sim.enemiesDefeated} '
      'pigeons=${sim.pigeonsDefeated} steam=${sim.steamBursts}';

  FrozenResult result(FlightSimulation sim, String outcome) => FrozenResult(
    summary: summary(sim),
    outcome: outcome,
    checkpoints: checkpoints,
  );
}

TrackingSample _touch(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// The plan JSON of [level] with the frozen id written back: renumbering is
/// the one change a frozen plan may show.
String frozenPlanJson(String frozenId, LevelPlan plan) =>
    jsonEncode({...plan.toJson(), 'id': frozenId});

/// What a level lays, as data: the plan's saved JSON (frozen id), the
/// route's exact positions, its vents and the level's card data.
Map<String, Object> catalog45Entry(String frozenId) {
  final level = frozenLevel(frozenId);
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: frozen45Version),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: frozen45Version,
    plan: level.plan,
  );
  final route = sim.route!;
  final positions = StringBuffer()
    ..write('goal=${route.goal} boss=${route.boss}\n');
  for (final x in route.passages) {
    positions.write('p $x\n');
  }
  for (final x in route.due) {
    positions.write('d $x\n');
  }
  for (final p in route.pieces) {
    positions.write('s ${p.piece.kind.name} ${p.number} ${p.start} ${p.end}\n');
  }
  for (final g in route.geysers) {
    positions.write('g ${g.slot} ${g.kind.name} ${g.x} ${g.burstAt}\n');
  }
  return {
    'plan': frozenPlanJson(frozenId, level.plan),
    'route': fnvHex(positions.toString()),
    'passages': route.passages.length,
    'routeStars': route.stars,
    'marks': [level.marks.two, level.marks.three],
    'boss': level.boss?.name ?? '',
    'minRulesVersion': level.plan.minRulesVersion,
    'name': level.name,
    'cargo': level.delivery.cargo,
    'from': level.delivery.from,
    'thanks': level.delivery.thanks,
    'hint': level.hint ?? '',
    'bossLine': Campaign.bossLine(level) ?? '',
    'thiefBudget': sim.thiefBudget,
  };
}

/// One scripted campaign flight of the shared bot (the frozen rules 41 bot's
/// loop), keyed by the frozen id.
class Frozen45Flight {
  const Frozen45Flight(
    this.level, {
    this.width = 2.2,
    this.damage = 30,
    this.keepAlive = true,
    this.sloppy = false,
    this.seconds = 400,
  });
  final String level;
  final double width;
  final int damage, seconds;
  final bool keepAlive, sloppy;

  String get name {
    final tags = [
      if (width != 2.2) 'w$width',
      if (damage != 30) 'dmg$damage',
      if (!keepAlive) 'mortal',
      if (sloppy) 'sloppy',
    ];
    return tags.isEmpty ? level : '$level@${tags.join(',')}';
  }

  FrozenResult fly({int version = frozen45Version}) {
    final sim = FlightSimulation(
      rules: TapFlyMode(rulesVersion: version),
      practice: false,
      course: FlightCourse.starTrail,
      rulesVersion: version,
      weaponDamage: damage,
      plan: frozenLevel(level).plan,
    );
    final digest = FrozenDigest();
    var now = 0.0;
    for (var frame = 1; frame <= seconds * 50; frame++) {
      now += 20;
      if (keepAlive && sim.hearts < 2) sim.hearts = 3;
      sim.apply(
        MovementInput(
          valid: true,
          height: .5,
          flap: rideTheSky(sim) && !(sloppy && (frame ~/ 40) % 7 == 6),
        ),
        _touch(now),
        now,
      );
      if (sim.canSprint) sim.sprint();
      switch (frame % 90) {
        case 0:
          sim.startCharge();
        case 30:
          sim.shoot();
        default:
          if (frame % 9 == 0 && !sim.charging && sim.canShoot) sim.shoot();
      }
      sim.tick(.02, now, viewportWidth: width);
      if (frame % 50 == 0) digest.sample(sim, frame ~/ 50);
      if (sim.phase == RunPhase.ended) break;
    }
    digest.sample(sim, -1);
    return digest.result(sim, outcomeOf(sim));
  }
}

/// Every level at the default width with the upgraded weapon; the boss and
/// guardian levels (and the set-piece and steam levels) at both other widths
/// and with the base weapon; mortal and sloppy pilots on the hardest.
List<Frozen45Flight> get frozen45Flights => [
  for (final id in frozen45Levels) Frozen45Flight(id),
  for (final id in ['1-8', '2-8', '3-2', '3-4', '2-3', '2-5', '3-3']) ...[
    Frozen45Flight(id, width: 1.6),
    Frozen45Flight(id, width: 2.4),
  ],
  for (final id in ['1-8', '2-8', '3-2', '3-4']) Frozen45Flight(id, damage: 10),
  for (final id in ['1-8', '2-7', '2-8', '3-2', '3-3', '3-4'])
    Frozen45Flight(id, keepAlive: false, sloppy: true),
  Frozen45Flight('2-8', width: 2.4, damage: 10, keepAlive: false),
  Frozen45Flight('3-4', width: 1.6, damage: 10, keepAlive: false),
];

/// One whole-level New York pilot flight (`ny_pilots.dart`, mortal, the base
/// weapon) of a guardian at the staged fight of rules 45.
class Frozen45PilotFlight {
  const Frozen45PilotFlight(
    this.level,
    this.skill,
    this.width, {
    this.keepAlive = true,
  });
  final String level;
  final Skill skill;
  final double width;

  /// Hearts topped up, so the pilot fights the whole staged fight (at 45
  /// New York's pilots lose to the tougher King Coo when mortal).
  final bool keepAlive;

  String get name =>
      '$level ${skill.name} ${width < 2 ? '640' : '800'} '
      '${frozenLevel(level).boss?.name}${keepAlive ? '' : ' mortal'}';

  FrozenResult fly({int version = frozen45Version}) {
    final digest = FrozenDigest();
    var frame = 0;
    final run = flyNewYork(
      currentIdOf(level),
      skill: skill,
      width: width,
      version: version,
      keepAlive: keepAlive,
      watch: (sim) {
        frame++;
        if (frame % 60 == 0) digest.sample(sim, frame ~/ 60);
      },
    );
    digest.sample(run.sim, -1);
    return digest.result(
      run.sim,
      '${outcomeOf(run.sim)} fight=${run.fight?.toStringAsFixed(3) ?? '-'}',
    );
  }
}

const w640 = 640 / 360, w800 = 800 / 360;

List<Frozen45PilotFlight> get frozen45PilotFlights => [
  for (final id in ['3-2', '3-4'])
    for (final width in [w640, w800])
      for (final skill in [Skill.sharp, Skill.average])
        Frozen45PilotFlight(id, skill, width),
  for (final id in ['3-2', '3-4'])
    Frozen45PilotFlight(id, Skill.sharp, w640, keepAlive: false),
];

/// An endless flight at the version asked for: solo, roped co-op, free
/// co-op or a duel, flown by the shared bot (each bird of a pair by itself).
class Frozen45Endless {
  const Frozen45Endless(
    this.name, {
    this.width = 2.2,
    this.coop,
    this.seconds = 560,
    this.seed = 7,
  });
  final String name;
  final double width;
  final CoopMode? coop;
  final int seconds, seed;

  FrozenResult fly({int version = frozen45Version}) {
    final sim = FlightSimulation(
      rules: TapFlyMode(rulesVersion: version),
      practice: false,
      course: FlightCourse.starTrail,
      rulesVersion: version,
      weaponDamage: 30,
      coop: coop,
      random: CountingRandom(seed),
    );
    final digest = FrozenDigest();
    var now = 0.0;
    for (var frame = 1; frame <= seconds * 50; frame++) {
      now += 20;
      if (sim.paired) {
        for (final bird in sim.flock) {
          if (bird.hearts < 2) bird.hearts = 3;
        }
        sim.apply(const MovementInput(valid: true), _touch(now), now);
        for (final (i, bird) in sim.flock.indexed) {
          if (sim.viewing(bird, () => rideTheSky(sim))) sim.flap(i);
          if (sim.viewing(bird, () => sim.canSprint)) sim.sprint(player: i);
          if ((frame + i * 45) % 90 == 30) sim.shoot(player: i);
        }
      } else {
        if (sim.hearts < 2) sim.hearts = 3;
        sim.apply(
          MovementInput(valid: true, height: .5, flap: rideTheSky(sim)),
          _touch(now),
          now,
        );
        if (sim.canSprint) sim.sprint();
        switch (frame % 90) {
          case 0:
            sim.startCharge();
          case 30:
            sim.shoot();
          default:
            if (frame % 9 == 0 && !sim.charging && sim.canShoot) sim.shoot();
        }
      }
      sim.tick(.02, now, viewportWidth: width);
      if (frame % 50 == 0) digest.sample(sim, frame ~/ 50);
      if (sim.phase == RunPhase.ended) break;
    }
    digest.sample(sim, -1);
    return digest.result(sim, outcomeOf(sim));
  }
}

const frozen45Endless = [
  Frozen45Endless('endless-w1.6', width: 1.6),
  Frozen45Endless('endless-w2.2'),
  Frozen45Endless('endless-w2.4', width: 2.4),
  Frozen45Endless('coop-roped', coop: CoopMode.roped, seconds: 300),
  Frozen45Endless('coop-free', coop: CoopMode.free, seconds: 300, seed: 9),
  Frozen45Endless('duel', coop: CoopMode.duel, seconds: 240, seed: 11),
];

/// A saved tape the fixture pins: how to record it and where it lives.
class Frozen45Tape {
  const Frozen45Tape(
    this.name, {
    this.level,
    this.skill,
    this.width = 2.2,
    required this.seed,
    this.seconds = 300,
    this.damage = BirdRock.baseDamage,
  });
  final String name;

  /// The frozen id of a campaign level, or null for an endless flight.
  final String? level;

  /// A New York pilot's skill: the guardian fights are recorded through
  /// `ny_pilots.dart`; null records the shared bot.
  final Skill? skill;
  final double width;
  final int seed, seconds, damage;
  String get file => 'test/fixtures/frozen_rules45_tapes/$name.json';

  /// Records the flight at [version] (the fixture's own at 45). [plan]
  /// replaces the catalog's: a re-recording flies the plan the tape holds.
  ReplayTape record({int version = frozen45Version, LevelPlan? plan}) {
    final tape = ReplayTape(
      mode: PlayMode.touch,
      practice: false,
      seed: seed,
      cycleSeconds: 3,
      bird: 2,
      reducedMotion: false,
      originMs: 0,
      course: FlightCourse.starTrail,
      recordedVersion: version,
      weaponDamage: damage,
      plan: level == null ? null : plan ?? frozenLevel(level!).plan,
    );
    if (skill != null) {
      final driver = RecordingDriver(tape);
      flyNewYork(
        currentIdOf(level!),
        skill: skill!,
        width: width,
        driver: driver,
        plan: tape.plan,
        version: version,
      );
      if (driver.sim.phase != RunPhase.ended) {
        driver.recorder.command('end', EndReason.quit);
      }
      return tape;
    }
    var now = 0.0;
    final recorder = FlightRecorder(tape, () => now);
    final sim = recorder.simulation;
    for (var frame = 1; frame <= seconds * 50; frame++) {
      now += 20;
      recorder.apply(
        MovementInput(valid: true, height: .5, flap: rideTheSky(sim)),
        _touch(now),
        now,
      );
      if (sim.canSprint) recorder.command('sprint');
      if (frame % 90 == 0) recorder.command('charge');
      if (frame % 90 == 30 || (frame % 9 == 0 && sim.canShoot)) {
        recorder.command('shoot');
      }
      recorder.tick(.02, now, width);
      if (sim.phase == RunPhase.ended) break;
    }
    if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
    return tape;
  }
}

const frozen45Tapes = [
  Frozen45Tape('endless-45', seconds: 240, seed: 45),
  Frozen45Tape(
    'campaign-1-8-baron-staged',
    level: '1-8',
    seed: 18,
    damage: 30,
  ),
  Frozen45Tape(
    'campaign-2-8-spitter-staged-w1.6',
    level: '2-8',
    width: 1.6,
    seed: 28,
    damage: 30,
  ),
  Frozen45Tape('campaign-2-6-lantern-bazaar', level: '2-6', seed: 26),
  Frozen45Tape(
    'campaign-3-2-king-coo-staged-640',
    level: '3-2',
    skill: Skill.sharp,
    width: w640,
    seed: 32,
    damage: 30,
  ),
  Frozen45Tape(
    'campaign-3-4-gargoyle-staged-800',
    level: '3-4',
    skill: Skill.sharp,
    width: w800,
    seed: 34,
  ),
];

/// A replay's digest: the state after every simulated second, then a
/// backward seek that reruns the journal and the end, as the replay screen
/// scrubs.
FrozenResult replay45(ReplayTape tape) {
  final player = ReplayPlayer(tape);
  final digest = FrozenDigest();
  final seconds = (tape.durationMs / 1000).ceil();
  for (var second = 1; second <= seconds; second++) {
    player.seek(second * 1000.0);
    digest.sample(player.simulation, second);
  }
  player.seek(tape.durationMs / 2);
  digest.sample(player.simulation, 0);
  player.seek(tape.durationMs);
  digest.sample(player.simulation, -1);
  return digest.result(player.simulation, outcomeOf(player.simulation));
}
