import 'dart:convert';

import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'frozen_egypt50_test.dart' show egyptState;
import 'frozen_flights.dart' show FrozenResult, fnvHex, outcomeOf;
import 'frozen_rules49_flights.dart' show frozen49State;
import 'neferhoo_pilot.dart';
import 'recorded_flight.dart' show rideTheSky;

/// Helpers for the frozen rules 50 fixtures (test/fixtures/frozen_rules50.json
/// and test/fixtures/frozen_rules50_tapes/). The tougher-Neferhoo change
/// (rules 52: double health, faster letters, mummy bats) recorded them from
/// an untouched copy of the landed tree (`egypt-int/base2`, rules 50) BEFORE
/// changing anything, to prove that level 2-6 and Neferhoo's fight fly at 50
/// exactly as they did, under any later rules code, and that later rules
/// change nothing of 2-6 before he arrives. `frozen_rules51_test` flies the
/// same flights at 51 (main's all-rings bonus). (`frozen_rules49` keeps pinning
/// endless, co-op, duel and every other level at 49 and the current version;
/// `frozen_egypt50` is the landing's own 2-6 fixture.)
///
/// The bot loops are copied here (as in `frozen_flights.dart`) so that later
/// edits to `campaign_flight.dart` cannot move a digest. The pilot flights are
/// `neferhoo_pilot.dart`'s: their digests also pin that a pilot flies a rules
/// 50 fight exactly as it did (a later pilot may learn the mummy bats, but
/// must not change what it does without them).

/// The rules version the fixtures were frozen at.
const frozen50Version = 50;

/// The level frozen: Neferhoo's.
const frozen50Level = '2-6';

CampaignLevel get _level => Campaign.level(frozen50Level)!;

/// What the digests cover: [frozen49State] (everything the game had up to
/// 49) and every latch of Neferhoo's fight ([egyptState]).
String frozen50State(FlightSimulation sim) =>
    '${frozen49State(sim)}${egyptState(sim)}';

/// A running FNV hash of [frozen50State] after every simulated second,
/// checkpointed every ten seconds and at the end, and a second hash of the
/// seconds before any boss is on the scene (the run-up): rules 52 must leave
/// that part of 2-6 exactly as 50 flew it.
class Frozen50Digest {
  final List<String> checkpoints = [];
  int _hash = 0xcbf29ce484222325;
  int _runUp = 0xcbf29ce484222325;
  int runUpSeconds = 0;

  /// The flight second the boss first showed (as `t=…`), or null.
  String? bossAt;

  static int _mix(int hash, String text) {
    var h = hash;
    for (final unit in text.codeUnits) {
      h ^= unit;
      h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return h;
  }

  void sample(FlightSimulation sim, int second) {
    final state = frozen50State(sim);
    _hash = _mix(_hash, state);
    if (sim.boss == null && bossAt == null && second > 0) {
      _runUp = _mix(_runUp, state);
      runUpSeconds++;
    } else if (sim.boss != null) {
      bossAt ??= sim.elapsed.toStringAsFixed(2);
    }
    if (second % 10 == 0 || second < 0) {
      checkpoints.add(_hash.toRadixString(16));
    }
  }

  /// The run-up, as a fixture value: its seconds, its hash, and when the
  /// boss showed.
  String get runUp => '$runUpSeconds ${_runUp.toRadixString(16)} boss=$bossAt';

  static String summary(FlightSimulation sim) {
    final boss = sim.boss;
    final fight = boss != null && boss.isNeferhoo ? boss.neferhoo : null;
    return 't=${sim.elapsed.toStringAsFixed(2)} ${sim.phase.name} '
        '${sim.endReason?.name} score=${sim.score} gates=${sim.gates} '
        'stars=${sim.collectedStars} hearts=${sim.hearts} '
        'bosses=${sim.bossesDefeated} enemies=${sim.enemiesDefeated} '
        'shots=${sim.shots}'
        '${fight == null ? '' : ' hp=${boss!.hp}/${boss.maxHp} '
                  'dealt=${fight.lettersDealt} land=${fight.returnsLanded} '
                  'hits=${fight.letterHits}/${fight.ankhHits}'}';
  }

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

/// 2-6 as data: the plan's saved JSON, the route's exact positions, the
/// level's card data and the rules it needs.
Map<String, Object> catalog50Entry({int version = frozen50Version}) {
  final level = _level;
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: version),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: version,
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
    'plan': jsonEncode(level.plan.toJson()),
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
  };
}

/// What a frozen flight gives: its digest and the run-up's.
typedef Frozen50Run = ({FrozenResult result, String runUp});

/// One scripted 2-6 flight of the shared bot (the frozen bots' loop).
class Frozen50Flight {
  const Frozen50Flight({
    this.width = 2.2,
    this.damage = BirdRock.baseDamage,
    this.keepAlive = true,
    this.sloppy = false,
    this.seconds = 300,
  });
  final double width;
  final int damage, seconds;
  final bool keepAlive, sloppy;

  String get name {
    final tags = [
      'w${width.toStringAsFixed(3)}',
      if (damage != BirdRock.baseDamage) 'dmg$damage',
      if (!keepAlive) 'mortal',
      if (sloppy) 'sloppy',
    ];
    return '$frozen50Level@${tags.join(',')}';
  }

  Frozen50Run fly({int version = frozen50Version}) {
    final sim = FlightSimulation(
      rules: TapFlyMode(rulesVersion: version),
      practice: false,
      course: FlightCourse.starTrail,
      rulesVersion: version,
      weaponDamage: damage,
      plan: _level.plan,
    );
    final digest = Frozen50Digest();
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
    return (result: digest.result(sim, outcomeOf(sim)), runUp: digest.runUp);
  }
}

const _w640 = 640 / 360, _w800 = 800 / 360, _w864 = 864 / 360;

/// The shared bot through 2-6 at 640, 800 and 864 px and 2.2 (main's
/// letterboxed sky) with the base weapon, at 2.2 with the upgraded one, and
/// mortal, sloppy flights at 640 and 2.2.
const frozen50Flights = [
  Frozen50Flight(width: _w640),
  Frozen50Flight(),
  Frozen50Flight(width: _w800),
  Frozen50Flight(width: _w864),
  Frozen50Flight(damage: 30),
  Frozen50Flight(width: _w640, keepAlive: false, sloppy: true),
  Frozen50Flight(damage: 30, keepAlive: false, sloppy: true),
];

/// One of R1's pilots (careful) fighting him from the fight's first frame.
class Frozen50Pilot {
  const Frozen50Pilot(
    this.skill,
    this.width,
    this.seed, {
    this.keepAlive = false,
    this.seconds = 240,
  });
  final NeferhooSkill skill;
  final double width;
  final int seed;
  final bool keepAlive;
  final double seconds;

  String get name =>
      '${skill.name}-${width.toStringAsFixed(3)}-s$seed'
      '${keepAlive ? '-kept' : ''}';

  FrozenResult fly({int version = frozen50Version}) {
    final sim = neferhooArena(width: width, version: version);
    final boss = sim.boss!;
    final digest = Frozen50Digest();
    final run = flyNeferhoo(
      sim,
      NeferhooPilot(skill, seed: seed, careful: true),
      width: width,
      seconds: seconds,
      keepAlive: keepAlive,
    );
    digest
      ..sample(sim, 1)
      ..sample(sim, -1);
    return digest.result(
      sim,
      '${outcomeOf(sim)} fight=${run.fight?.toStringAsFixed(3)} '
      'hits=${run.hits} returns=${run.returns} hp=${boss.hp} '
      'state=${fnvHex(egyptState(sim))}',
    );
  }
}

const frozen50Pilots = [
  Frozen50Pilot(family, _w640, 1),
  Frozen50Pilot(family, 2.2, 1),
  Frozen50Pilot(kid, _w640, 3),
  Frozen50Pilot(kid, 2.2, 3),
  Frozen50Pilot(expert, _w640, 5),
  Frozen50Pilot(learner, _w864, 9),
  Frozen50Pilot(coarse, 2.2, 7, keepAlive: true, seconds: 120),
];

/// A saved 2-6 tape the fixture pins: the shared bot through the whole level,
/// or the shared bot's run-up and then one of R1's pilots through the fight
/// (and the bot again on the coast to the line).
class Frozen50Tape {
  const Frozen50Tape(
    this.name, {
    this.skill,
    this.width = 2.2,
    required this.seed,
    this.damage = BirdRock.baseDamage,
    this.sloppy = false,
  });
  final String name;
  final NeferhooSkill? skill;
  final double width;
  final int seed, damage;
  final bool sloppy;
  String get file => 'test/fixtures/frozen_rules50_tapes/$name.json';

  /// Records the flight at [version] (the fixture's own at 50). [plan]
  /// replaces the catalog's: a re-recording flies the plan the tape holds.
  ReplayTape record({int version = frozen50Version, LevelPlan? plan}) {
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
      plan: plan ?? _level.plan,
    );
    var now = 0.0;
    final recorder = FlightRecorder(tape, () => now);
    final sim = recorder.simulation;
    final pilot = skill == null
        ? null
        : NeferhooPilot(skill!, seed: seed, careful: true);
    // The bot: the whole level, or the run-up and the coast for a pilot.
    var frame = 0;
    bool botFrame() {
      frame++;
      now += 20;
      recorder.apply(
        MovementInput(
          valid: true,
          height: .5,
          flap: rideTheSky(sim) && !(sloppy && (frame ~/ 40) % 7 == 6),
        ),
        _touch(now),
        now,
      );
      if (pilot == null && sim.canSprint) recorder.command('sprint');
      if (frame % 90 == 0) recorder.command('charge');
      if (frame % 90 == 30 || (frame % 9 == 0 && sim.canShoot)) {
        recorder.command('shoot');
      }
      recorder.tick(.02, now, width);
      return sim.phase != RunPhase.ended;
    }

    bool fighting() =>
        sim.boss?.phase == BossPhase.attacking && sim.boss!.isNeferhoo;
    while (frame < 300 * 50 && botFrame()) {
      if (pilot != null && fighting()) break;
    }
    if (pilot != null && fighting()) {
      for (var i = 0; i < 240 * 60; i++) {
        if (!fighting() || sim.phase == RunPhase.ended) break;
        pilot.plan(sim);
        final tap = pilot.flap(sim);
        if (pilot.shoot(sim)) recorder.command('shoot');
        now += 1000 / 60;
        recorder.apply(
          MovementInput(valid: true, height: .5, flap: tap),
          _touch(now),
          now,
        );
        recorder.tick(1 / 60, now, width);
      }
      for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
        if (!botFrame()) break;
      }
    }
    if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
    return tape;
  }
}

const frozen50Tapes = [
  Frozen50Tape('bot-2-6-w2.2', seed: 26),
  Frozen50Tape(
    'bot-2-6-640-dmg30-sloppy',
    width: _w640,
    seed: 62,
    damage: 30,
    sloppy: true,
  ),
  Frozen50Tape('family-2-6-640', skill: family, width: _w640, seed: 1),
  Frozen50Tape('kid-2-6-w2.2', skill: kid, seed: 3),
];

/// A replay's digest: the state after every simulated second, then a
/// backward seek that reruns the journal and the end, as the replay screen
/// scrubs.
Frozen50Run replay50(ReplayTape tape) {
  final player = ReplayPlayer(tape);
  final digest = Frozen50Digest();
  final seconds = (tape.durationMs / 1000).ceil();
  for (var second = 1; second <= seconds; second++) {
    player.seek(second * 1000.0);
    digest.sample(player.simulation, second);
  }
  final runUp = digest.runUp;
  player.seek(tape.durationMs / 2);
  digest.sample(player.simulation, 0);
  player.seek(tape.durationMs);
  digest.sample(player.simulation, -1);
  return (
    result: digest.result(player.simulation, outcomeOf(player.simulation)),
    runUp: runUp,
  );
}
