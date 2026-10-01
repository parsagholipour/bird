import 'dart:convert';

import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'endless_plan_baseline_test.dart' show FlightDigest;
import 'frozen_flights.dart' show FrozenResult, fnvHex, outcomeOf;
import 'ny_pilots.dart';
import 'recorded_flight.dart';

/// Helpers for the frozen rules 43 New York fixtures
/// (test/fixtures/frozen_ny43.json and test/fixtures/frozen_ny_tapes/): the
/// catalog's 3-1 to 3-4 as the New York level-data step shipped them, pinned
/// at rules version 43 in NEW files, beside the rules 41 fixtures of
/// chapters 1 and 2 (`frozen_flights.dart`, which this never touches).
///
/// Two kinds of flight are frozen. The bot flights are the repo's shared bot
/// (`rideTheSky`, the loop copied as in `frozen_flights.dart` so that later
/// edits to `campaign_flight.dart` cannot move a digest): a charged shot every
/// 1.8 s with tapped shots between, Sprint whenever ready. The guardian wins
/// and Steam Alley are SAVED TAPES recorded through the whole-level pilots of
/// `ny_pilots.dart` at the base weapon the campaign really gives: the tape
/// holds every input, so a later edit of a pilot cannot move what replays,
/// only a change of the rules can.

/// The rules version the fixtures were frozen at.
const frozenNyVersion = 43;

/// 3-1 to 3-4.
List<CampaignLevel> get nyLevels => [
  for (final number in [1, 2, 3, 4]) Campaign.level('3-$number')!,
];

TrackingSample _touch(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// One scripted campaign flight of the shared bot.
class FrozenNyFlight {
  const FrozenNyFlight(
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

  /// Whether hearts are topped up so the flight always finishes.
  final bool keepAlive;

  /// A poor pilot that lets go for 0.8 s in every 5.6 s, so the bird sinks
  /// into gates, shots and vents, loses hearts and may lose the flight.
  final bool sloppy;

  String get name {
    final tags = [
      if (width != 2.2) 'w$width',
      if (damage != 30) 'dmg$damage',
      if (!keepAlive) 'mortal',
      if (sloppy) 'sloppy',
    ];
    return tags.isEmpty ? level : '$level@${tags.join(',')}';
  }

  FrozenResult fly({int version = frozenNyVersion}) {
    final plan = Campaign.level(level)!.plan;
    final sim = FlightSimulation(
      rules: TapFlyMode(rulesVersion: version),
      practice: false,
      course: FlightCourse.starTrail,
      rulesVersion: version,
      weaponDamage: damage,
      plan: plan,
    );
    final digest = FlightDigest();
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
    return FrozenResult(
      summary: digest.summary(sim),
      outcome: outcomeOf(sim),
      checkpoints: digest.checkpoints,
    );
  }
}

/// What a level lays, as data: the plan's saved JSON, the route's exact
/// positions, the steam vents' and the pigeons' budget.
Map<String, Object> catalogNyEntry(CampaignLevel level) {
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: frozenNyVersion),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: frozenNyVersion,
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
  final vents = StringBuffer();
  for (final g in route.geysers) {
    vents.write('${g.slot} ${g.kind.name} ${g.x} ${g.burstAt}\n');
  }
  return {
    'plan': jsonEncode(level.plan.toJson()),
    'route': fnvHex(positions.toString()),
    'vents': fnvHex(vents.toString()),
    'passages': route.passages.length,
    'routeStars': route.stars,
    'pieces': route.pieces.length,
    'geysers': route.geysers.length,
    'thiefBudget': sim.thiefBudget,
    'marks': [level.marks.two, level.marks.three],
    'isBoss': level.isBoss,
    'isGuardian': level.isGuardian,
    'boss': level.boss?.name ?? '',
    'minRulesVersion': level.plan.minRulesVersion,
    'bossLine': level.bossLine ?? '',
    'sprint': level.plan.sprint,
  };
}

/// The bot flights frozen in the fixture: every level at the default width
/// with the upgraded weapon, both other widths, the base weapon, mortal and
/// sloppy pilots (scalded by vents, robbed by pigeons, hurt by a guardian).
List<FrozenNyFlight> get frozenNyFlights => [
  for (final level in nyLevels) FrozenNyFlight(level.id),
  for (final level in nyLevels) ...[
    FrozenNyFlight(level.id, width: 1.6),
    FrozenNyFlight(level.id, width: 2.4),
    FrozenNyFlight(level.id, damage: 10),
  ],
  for (final id in ['3-1', '3-2', '3-3', '3-4'])
    FrozenNyFlight(id, keepAlive: false),
  // Flights that are hurt: hearts lost, runs ended, a guardian fought badly.
  for (final id in ['3-1', '3-2', '3-3', '3-4'])
    FrozenNyFlight(id, keepAlive: false, sloppy: true),
  FrozenNyFlight('3-3', width: 1.6, keepAlive: false, sloppy: true),
  FrozenNyFlight('3-2', width: 2.4, damage: 10, keepAlive: false),
  FrozenNyFlight('3-4', width: 2.4, damage: 10, keepAlive: false),
];

/// One flight of a whole-level pilot of `ny_pilots.dart` (mortal, the base
/// weapon), as a state digest: the guardian wins at both phone widths and at
/// every skill, Steam Alley, Moth Light. These digests also pin the pilots
/// (R2's `CooBot`, R3's `Pilot` and the shared bot they fly with); the saved
/// tapes below do not depend on them.
class FrozenNyPilotFlight {
  const FrozenNyPilotFlight(this.level, this.skill, this.width);
  final String level;
  final Skill skill;
  final double width;

  String get name =>
      '$level ${skill.name} ${width < 2 ? '640' : '800'} ${Campaign.level(level)!.boss?.name ?? 'finish'}';

  FrozenResult fly() {
    final digest = FlightDigest();
    var frame = 0;
    final run = flyNewYork(
      level,
      skill: skill,
      width: width,
      watch: (sim) {
        frame++;
        if (frame % 60 == 0) digest.sample(sim, frame ~/ 60);
      },
    );
    digest.sample(run.sim, -1);
    return FrozenResult(
      summary: digest.summary(run.sim),
      outcome:
          '${outcomeOf(run.sim)} fight=${run.fight?.toStringAsFixed(3) ?? '-'}',
      checkpoints: digest.checkpoints,
    );
  }
}

/// Both guardians at both widths and all three skills, Steam Alley at 640 and
/// 800 (sharp and average; a casual pilot only finishes it at 800) and Moth
/// Light.
List<FrozenNyPilotFlight> get frozenNyPilotFlights => [
  for (final id in ['3-2', '3-4'])
    for (final width in [w640, w800])
      for (final skill in Skill.values) FrozenNyPilotFlight(id, skill, width),
  for (final width in [w640, w800])
    for (final skill in [Skill.sharp, Skill.average])
      FrozenNyPilotFlight('3-3', skill, width),
  FrozenNyPilotFlight('3-1', Skill.sharp, w800),
];

/// A saved tape the fixture pins: how to record it and where it lives.
class FrozenNyTape {
  const FrozenNyTape(
    this.name, {
    required this.level,
    required this.skill,
    required this.width,
    required this.seed,
    this.bird = 2,
    this.plan,
    this.seconds = 400,
  });
  final String name;

  /// The plan the tape flies when it is not the catalog's (a LEGACY tape: a
  /// level as it was shipped before a retune), and the seconds it is cut
  /// after (a tape that is cut ends as a quit).
  final LevelPlan? plan;
  final double seconds;

  /// Whether the tape flies a plan the catalog no longer has.
  bool get legacy => plan != null;

  /// The campaign level's id.
  final String level;
  final Skill skill;

  /// Viewport width in screen heights: 640/360 or 800/360.
  final double width;
  final int seed, bird;
  String get file => 'test/fixtures/frozen_ny_tapes/$name.json';

  /// Records the flight with the New York pilot at rules 43 and the base
  /// weapon, through a [FlightRecorder].
  ReplayTape record() {
    final tape = ReplayTape(
      mode: PlayMode.touch,
      practice: false,
      seed: seed,
      cycleSeconds: 3,
      bird: bird,
      reducedMotion: false,
      originMs: 0,
      course: FlightCourse.starTrail,
      recordedVersion: frozenNyVersion,
      weaponDamage: BirdRock.baseDamage,
      plan: plan ?? Campaign.level(level)!.plan,
    );
    final driver = RecordingDriver(tape);
    flyNewYork(
      level,
      skill: skill,
      width: width,
      driver: driver,
      plan: plan,
      seconds: seconds,
    );
    final sim = driver.sim;
    if (sim.phase != RunPhase.ended) {
      driver.recorder.command('end', EndReason.quit);
    }
    return tape;
  }
}

const w640 = 640 / 360, w800 = 800 / 360;

/// Steam Alley as it was shipped before the fix round: 80 s, seed 3103, marks
/// 55 and 90 (the catalog's is 65 s, seed 3111, marks 45 and 70). Not in the
/// catalog any more, so a tape that flies it proves a retuned level still
/// replays the way it was flown.
const legacySteamAlley = LevelPlan(
  id: '3-3',
  region: WorldRegion.newYork,
  length: 80,
  start: 100,
  seed: 3103,
  families: [
    ObstacleKind.garden,
    ObstacleKind.windLift,
    ObstacleKind.petalGate,
    ObstacleKind.sunWheels,
  ],
  lineup: [
    EnemyKind.simpleBat,
    EnemyKind.alleyPigeon,
    EnemyKind.duskMoth,
    EnemyKind.spitterBeetle,
    EnemyKind.alleyPigeon,
    EnemyKind.caveBat,
  ],
  toughness: 2,
  panels: .25,
  flocks: [1, 2, 2, 2, 2, 2],
  steam: SteamPlan.steady,
  marks: StarMarks(55, 90),
);

/// King Coo beaten at 640 px, the Gargoyle beaten at 800 px and a whole
/// Steam Alley (the other guardian wins, at both widths and three skills, are
/// the pilot flights' digests above), and the LEGACY Steam Alley cut after 40
/// s (three vents, two formations).
const frozenNyTapes = [
  FrozenNyTape(
    'campaign-3-2-king-coo-640',
    level: '3-2',
    skill: Skill.sharp,
    width: w640,
    seed: 32,
  ),
  FrozenNyTape(
    'campaign-3-3-steam-alley-800',
    level: '3-3',
    skill: Skill.sharp,
    width: w800,
    seed: 33,
  ),
  FrozenNyTape(
    'campaign-3-4-gargoyle-800',
    level: '3-4',
    skill: Skill.sharp,
    width: w800,
    seed: 34,
  ),
  FrozenNyTape(
    'legacy-3-3-steam-alley-80s-seed3103',
    level: '3-3',
    skill: Skill.average,
    width: w640,
    seed: 35,
    plan: legacySteamAlley,
    seconds: 40,
  ),
];
