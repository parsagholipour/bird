import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

/// Controlled scenes for the New York rules tests (pigeon raids, steam
/// vents): a level flight that is already under way, and a bird the test
/// holds wherever it likes. Nothing here changes how a flight is flown.

const birdX = FlightSimulation.birdX;

const _road = [
  ObstacleKind.garden,
  ObstacleKind.windLift,
  ObstacleKind.petalGate,
  ObstacleKind.switchback,
  ObstacleKind.lanternDrift,
  ObstacleKind.sunWheels,
];

/// A New York level plan with no stone panels (so every enemy-led passage
/// lays its enemy) unless told otherwise. The default lineup puts a pigeon on
/// passages 1, 5, 9 ... and a bat on 3, 7, 11 ...
LevelPlan rulesPlan({
  String id = '3-2',
  double length = 30,
  double start = 85,
  int seed = 3102,
  List<EnemyKind> lineup = const [EnemyKind.alleyPigeon, EnemyKind.simpleBat],
  int cadence = 2,
  List<int> flocks = const [],
  SteamPlan steam = SteamPlan.none,
  BossKind? boss,
  double panels = 0,
  int toughness = 2,
  StarMarks marks = const StarMarks(20, 30),
}) => LevelPlan(
  id: id,
  region: WorldRegion.newYork,
  length: length,
  start: start,
  seed: seed,
  families: _road,
  lineup: lineup,
  cadence: cadence,
  toughness: toughness,
  panels: panels,
  flocks: flocks,
  steam: steam,
  boss: boss,
  marks: marks,
);

/// A live flight of [plan]: playing, with the route laid as it is reached.
FlightSimulation arenaOf(
  LevelPlan plan, {
  int version = FlightSimulation.currentRulesVersion,
  int weaponDamage = 10,
}) =>
    FlightSimulation(
        rules: TapFlyMode(rulesVersion: version),
        practice: false,
        course: FlightCourse.starTrail,
        rulesVersion: version,
        weaponDamage: weaponDamage,
        plan: plan,
      )
      ..phase = RunPhase.playing
      ..started = true;

/// One frame of [dt] seconds, with a valid touch input (a tap if [flap]).
void frame(
  FlightSimulation sim, {
  double dt = 1 / 60,
  double width = 2.2,
  bool flap = false,
}) {
  final now = (sim.elapsed + dt) * 1000;
  sim.apply(
    MovementInput(valid: true, flap: flap),
    TrackingSample(
      mode: PlayMode.touch,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  sim.tick(dt, now, viewportWidth: width);
}

/// Runs [sim] until [until] holds, holding the bird at [holdY] (no flaps,
/// no falling) when it is given. Fails the test's premise after [seconds].
void runUntil(
  FlightSimulation sim,
  bool Function(FlightSimulation sim) until, {
  double width = 2.2,
  double dt = 1 / 60,
  double? holdY,
  double Function(FlightSimulation sim)? steer,
  bool immortal = false,
  bool allowEnd = false,
  double seconds = 120,
  void Function(FlightSimulation sim)? watch,
}) {
  final limit = sim.elapsed + seconds;
  while (!until(sim)) {
    if (allowEnd && sim.phase == RunPhase.ended) return;
    if (sim.elapsed > limit || sim.phase == RunPhase.ended) {
      throw StateError('never happened within $seconds s: ${sim.phase}');
    }
    if (holdY != null || steer != null) {
      sim.birdY = steer?.call(sim) ?? holdY!;
      sim.velocity = 0;
    }
    if (immortal) sim.invulnerableUntil = 1e9;
    frame(sim, width: width, dt: dt);
    watch?.call(sim);
  }
}

/// Where a perfect collector holds the bird: at the height of the next star
/// it can still take (not collected, missed or in a thief's beak). Teleports
/// the bird's height, so it is for scenes, not for fairness proofs.
double vacuumY(FlightSimulation sim) {
  SkyStar? next;
  for (final star in sim.stars) {
    if (star.collected || star.missed || star.carried) continue;
    if (star.x < birdX - .05) continue;
    if (next == null || star.x < next.x) next = star;
  }
  return next?.y ?? sim.birdY;
}

/// The pigeons of [sim] that belong to a formation, in the order laid.
List<SkyEnemy> raiders(FlightSimulation sim) => [
  for (final e in sim.enemies)
    if (e.pigeon?.laid ?? false) e,
];

/// A star's and a pigeon's state, for comparing two runs of one flight.
String pigeonSnapshot(FlightSimulation sim) {
  String n(double v) => v.toStringAsFixed(9);
  final buffer = StringBuffer()
    ..write('t=${n(sim.elapsed)} d=${n(sim.distance)} y=${n(sim.birdY)} ')
    ..write(
      'score=${sim.score} combo=${sim.combo} stars=${sim.collectedStars} ',
    )
    ..write('hearts=${sim.hearts} shield=${sim.shield} ')
    ..write(
      'pc=${sim.pigeonWarnings},${sim.pigeonDives},${sim.starsSnatched},'
      '${sim.starsFreed},${sim.starsLost},${sim.pigeonsDefeated} ',
    );
  for (final e in sim.enemies) {
    final r = e.pigeon;
    buffer.write('[${e.kind.index} ${n(e.x)} ${n(e.y)} hp${e.hp}');
    if (r != null) {
      buffer.write(
        ' ${r.phase.name} ${n(r.phaseAt)} ${r.prey != null} ${r.loot != null} '
        '${r.spooked} ${n(r.homeX)} ${n(r.homeY)}',
      );
    }
    buffer.write(']');
  }
  for (final s in sim.stars) {
    buffer.write(
      '(${n(s.x)} ${n(s.y)} ${s.collected ? 'c' : ''}${s.missed ? 'm' : ''}'
      '${s.carried ? 'k' : ''}${s.rescued ? 'r' : ''}${s.thief != null ? 't' : ''})',
    );
  }
  return buffer.toString();
}

/// A steam vent's and the counters' state.
String steamSnapshot(FlightSimulation sim) {
  String n(double v) => v.toStringAsFixed(9);
  final buffer = StringBuffer()
    ..write('t=${n(sim.elapsed)} rs=${n(sim.routeSeconds)} y=${n(sim.birdY)} ')
    ..write('score=${sim.score} hearts=${sim.hearts} shield=${sim.shield} ')
    ..write(
      'sc=${sim.steamHisses},${sim.steamBursts},${sim.steamRides},'
      '${sim.steamScalds},${sim.steamClears} ',
    );
  for (final v in sim.steamVents) {
    buffer.write(
      '<${v.geyser.slot} ${n(v.x)} ${n(v.top)} ${v.phaseAt(sim.routeSeconds).name} '
      '${v.touched} ${v.scalded} ${v.rode} ${v.passed} ${n(v.lifted)}>',
    );
  }
  return buffer.toString();
}

/// Records [plan] flown by the shared bot through a [FlightRecorder] and
/// returns the tape with the live flight's snapshot ([snap]) after every
/// 25th frame, keyed by the frame's time in milliseconds.
({ReplayTape tape, Map<double, String> live, FlightSimulation sim}) recordWith(
  LevelPlan plan,
  bool Function(FlightSimulation sim) tapWhen,
  String Function(FlightSimulation sim) snap, {
  double width = 2.2,
  double seconds = 120,
  int weaponDamage = 30,
  bool shoot = true,
  bool sprint = true,
}) {
  var now = 0.0;
  final tape = ReplayTape(
    mode: PlayMode.touch,
    practice: false,
    seed: 5,
    cycleSeconds: 3,
    bird: 2,
    reducedMotion: false,
    originMs: 0,
    course: FlightCourse.starTrail,
    weaponDamage: weaponDamage,
    plan: plan,
  );
  final recorder = FlightRecorder(tape, () => now);
  final sim = recorder.simulation;
  final live = <double, String>{};
  for (var i = 1; i <= seconds * 50; i++) {
    now += 20;
    recorder.apply(
      MovementInput(valid: true, height: .5, flap: tapWhen(sim)),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    if (sprint && sim.canSprint && i % 3 == 0) recorder.command('sprint');
    if (shoot && i % 90 == 0) recorder.command('charge');
    if (shoot && (i % 90 == 30 || (i % 9 == 0 && sim.canShoot))) {
      recorder.command('shoot');
    }
    recorder.tick(.02, now, width);
    if (i % 25 == 0) live[now] = snap(sim);
    if (sim.phase == RunPhase.ended) break;
  }
  if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
  return (tape: tape, live: live, sim: sim);
}
