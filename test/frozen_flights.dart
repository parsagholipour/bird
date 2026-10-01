import 'dart:convert';

import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'endless_plan_baseline_test.dart' show FlightDigest, stateOf;
import 'recorded_flight.dart';

/// Helpers for the frozen rules 41 fixtures (test/fixtures/frozen_rules41.json
/// and test/fixtures/frozen_tapes/). Nothing here may change how a flight is
/// flown: a bot edit changes a digest exactly like a rules edit would. The
/// New York program froze them from the committed game before its first
/// change, to prove that endless flights and chapters 1 and 2 fly
/// byte-identically at rules versions 42 and 43 and that tapes recorded at 41
/// replay as before.
///
/// The bots are the repo's own: [rideTheSky] flaps, a charged shot goes off
/// every 1.8 s with tapped shots between, and Sprint fires whenever it is
/// ready. They are copied here rather than imported from campaign_flight.dart
/// so that later edits to that helper cannot move a frozen digest.

/// The rules version the fixtures were frozen at.
const frozenVersion = 41;

/// The 16 levels of chapters 1 and 2: the campaign as it was playable at 41.
List<CampaignLevel> get frozenLevels => [
  for (final level in Campaign.levels)
    if (level.chapter <= 2) level,
];

String fnvHex(String text) {
  var hash = 0xcbf29ce484222325;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

TrackingSample _touch(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// One scripted campaign flight of the frozen bot.
class FrozenFlight {
  const FrozenFlight(
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
  /// into gates and shots, loses hearts and may lose the flight.
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

  /// Flies the level as [version] and returns its digest.
  FrozenResult fly({int version = frozenVersion}) {
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

class FrozenResult {
  const FrozenResult({
    required this.summary,
    required this.outcome,
    required this.checkpoints,
  });
  final String summary, outcome;
  final List<String> checkpoints;

  Map<String, Object> toJson() => {
    'summary': summary,
    'outcome': outcome,
    'checkpoints': checkpoints,
  };
}

/// How a flight ended: finish line or boss, stars and level stars.
String outcomeOf(FlightSimulation sim) {
  final line = sim.finishLine;
  return 'end=${sim.endReason?.name} '
      'finish=${line == null
          ? 'none'
          : line.crossed
          ? 'crossed'
          : 'open'} '
      'bosses=${sim.bossesDefeated} '
      'stars=${sim.collectedStars}/${sim.starsLaid} '
      'levelStars=${sim.levelStars} score=${sim.score} '
      'hearts=${sim.hearts} route=${sim.routeSeconds.toStringAsFixed(3)}';
}

/// What a level lays, as data: the plan's saved JSON (so new keys must not
/// appear for an old plan) and the route's exact positions.
Map<String, Object> catalogEntry(CampaignLevel level) {
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: frozenVersion),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: frozenVersion,
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
  return {
    'plan': jsonEncode(level.plan.toJson()),
    'route': fnvHex(positions.toString()),
    'passages': route.passages.length,
    'routeStars': route.stars,
    'pieces': route.pieces.length,
    'marks': [level.marks.two, level.marks.three],
    'isBoss': level.isBoss,
    'boss': level.boss?.name ?? '',
  };
}

/// The flights frozen in the fixture: every level at the default width with
/// the upgraded weapon, and variations on the levels that carry the most
/// rules (rush paths, enemies, both bosses): narrow and wide screens, the
/// base weapon, and a mortal bird that can lose.
List<FrozenFlight> get frozenFlights => [
  for (final level in frozenLevels) FrozenFlight(level.id),
  for (final id in ['1-3', '1-5', '2-1', '2-3', '2-5', '2-7']) ...[
    FrozenFlight(id, width: 1.6),
    FrozenFlight(id, width: 2.4),
  ],
  for (final id in ['1-8', '2-8']) ...[
    FrozenFlight(id, width: 1.6),
    FrozenFlight(id, width: 2.4),
    FrozenFlight(id, damage: 10),
  ],
  for (final id in ['1-4', '2-2', '2-8']) FrozenFlight(id, keepAlive: false),
  // Flights that are hurt: hearts lost, runs ended, a boss fought badly.
  for (final id in ['1-3', '1-8', '2-1', '2-2', '2-3', '2-5', '2-8'])
    FrozenFlight(id, keepAlive: false, sloppy: true),
  FrozenFlight('2-7', width: 1.6, keepAlive: false, sloppy: true),
  FrozenFlight('2-8', width: 2.4, damage: 10, keepAlive: false, sloppy: true),
];

/// A saved tape the fixture pins: how to record it and where it lives.
class FrozenTape {
  const FrozenTape(
    this.name, {
    this.level,
    required this.seconds,
    required this.seed,
    this.bird = 1,
  });
  final String name;

  /// A campaign level's id, or null for an endless Star Trail.
  final String? level;

  /// Recording stops after this many seconds, or when the flight ends.
  final int seconds;
  final int seed, bird;
  String get file => 'test/fixtures/frozen_tapes/$name.json';

  /// Records the flight with the frozen bot at rules 41.
  ReplayTape record() {
    var now = 0.0;
    final plan = level == null ? null : Campaign.level(level!)!.plan;
    final tape = ReplayTape(
      mode: PlayMode.touch,
      practice: false,
      seed: seed,
      cycleSeconds: 3,
      bird: bird,
      reducedMotion: false,
      originMs: 0,
      course: FlightCourse.starTrail,
      recordedVersion: frozenVersion,
      weaponDamage: 30,
      plan: plan,
    );
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
      recorder.tick(.02, now, 2.2);
      if (sim.phase == RunPhase.ended) break;
    }
    if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
    return tape;
  }
}

const frozenTapes = [
  FrozenTape('endless-star-trail', seconds: 100, seed: 31),
  FrozenTape('campaign-2-3-wildfire', level: '2-3', seconds: 50, seed: 5),
  FrozenTape('campaign-2-8-spitter-king', level: '2-8', seconds: 200, seed: 6),
];

/// A replay's digest: the state after every simulated second, then a
/// backward seek that reruns the journal and the end, as the replay screen
/// scrubs.
FrozenResult replayFrozen(ReplayTape tape) {
  final player = ReplayPlayer(tape);
  final digest = FlightDigest();
  final seconds = (tape.durationMs / 1000).ceil();
  for (var second = 1; second <= seconds; second++) {
    player.seek(second * 1000.0);
    digest.sample(player.simulation, second);
  }
  player.seek(tape.durationMs / 2);
  digest.sample(player.simulation, 0);
  player.seek(tape.durationMs);
  digest.sample(player.simulation, -1);
  return FrozenResult(
    summary: digest.summary(player.simulation),
    outcome: outcomeOf(player.simulation),
    checkpoints: digest.checkpoints,
  );
}

/// The exact state at the end of [tape], for readable diffs.
String endState(ReplayTape tape) {
  final player = ReplayPlayer(tape)..seek(tape.durationMs);
  return stateOf(player.simulation);
}
