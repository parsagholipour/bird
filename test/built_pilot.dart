import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'recorded_flight.dart';

/// The rules a flight of [mode] starts with; [cycle] is a push-up or squat
/// player's calibrated movement.
GameMode builtRules(PlayMode mode, {double cycle = BuiltPlan.referenceCycle}) =>
    switch (mode) {
      PlayMode.pushUp => PushUpFlightMode(cycleSeconds: cycle),
      PlayMode.squat => SquatFlyMode(cycleSeconds: cycle),
      PlayMode.jump => JumpFlyMode(),
      PlayMode.touch => TapFlyMode(),
    };

/// A fresh scored flight of [plan], as the play screen starts one.
FlightSimulation builtFlight(
  BuiltPlan plan, {
  double cycle = BuiltPlan.referenceCycle,
  int version = FlightSimulation.currentRulesVersion,
  int weaponDamage = BirdRock.baseDamage,
  bool practice = false,
}) => FlightSimulation(
  rules: builtRules(plan.mode, cycle: cycle),
  practice: practice,
  course: FlightCourse.starTrail,
  rulesVersion: version,
  weaponDamage: weaponDamage,
  plan: plan,
);

/// A built-level pilot: Tap & Fly rides the sky as the campaign bot does;
/// a jump flaps under the next gate or pickup; a push-up or squat moves
/// toward it no faster than a player whose movement takes [cycle] seconds
/// (half a cycle from one end of the range to the other).
class BuiltPilot {
  BuiltPilot(this.mode, {this.cycle = BuiltPlan.referenceCycle});
  final PlayMode mode;
  final double cycle;
  double height = .5;
  int reps = 0;
  bool _up = true;

  /// The height the bird should be at for whatever it meets next.
  static double aim(FlightSimulation sim) {
    const bird = FlightSimulation.birdX;
    double? best, at;
    void consider(double x, double y, {double right = 0}) {
      if (x + right < bird - .02) return;
      if (best == null || x < best!) {
        best = x;
        at = y;
      }
    }

    // A gate holds the aim until the bird is through it.
    for (final o in sim.obstacles) {
      if (!o.scored) consider(o.x, o.target, right: o.width + .06);
    }
    for (final star in sim.stars) {
      if (!star.collected && !star.missed) consider(star.x, star.y);
    }
    for (final heart in sim.heartPickups) {
      consider(heart.x, heart.y);
    }
    return at ?? (sim.boss?.y ?? .5);
  }

  MovementInput next(FlightSimulation sim) {
    if (mode == PlayMode.touch) {
      return MovementInput(valid: true, height: .5, flap: rideTheSky(sim));
    }
    final target = aim(sim);
    if (mode == PlayMode.jump) {
      final flapAt = (target + .13).clamp(.15, .88);
      return MovementInput(
        valid: true,
        height: .5,
        flap: sim.birdY > flapAt && sim.velocity >= 0,
      );
    }
    final wanted = ((.85 - target) / .7).clamp(0.0, 1.0);
    final step = .02 * 2 / cycle;
    height += (wanted - height).clamp(-step, step);
    // A repetition is a full movement: down to the bottom and back up.
    if (_up && height < .1) _up = false;
    if (!_up && height > .9) {
      _up = true;
      reps++;
    }
    return MovementInput(valid: true, height: height, repetitions: reps);
  }
}

TrackingSample builtSample(PlayMode mode, double now) => TrackingSample(
  mode: mode,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// Flies [sim] with a [BuiltPilot] until it ends or [seconds] pass.
/// [keepAlive] tops the hearts up; Tap & Fly shoots as the campaign bot
/// does when [shoot]. [watch] sees the flight after every frame.
void flyBuilt(
  FlightSimulation sim, {
  double cycle = BuiltPlan.referenceCycle,
  bool keepAlive = false,
  bool shoot = true,
  double seconds = 600,
  void Function(FlightSimulation sim)? watch,
}) {
  final pilot = BuiltPilot(sim.rules.mode, cycle: cycle);
  var now = sim.lastValidMs.isFinite ? sim.lastValidMs : 0.0;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    now += 20;
    if (keepAlive && sim.hearts < 2) sim.hearts = 3;
    sim.apply(pilot.next(sim), builtSample(sim.rules.mode, now), now);
    if (shoot && sim.offersShoot) {
      switch (frame % 90) {
        case 0:
          sim.startCharge();
        case 30:
          sim.shoot();
        default:
          if (frame % 9 == 0 && !sim.charging && sim.canShoot) sim.shoot();
      }
    }
    sim.tick(.02, now, viewportWidth: 2.2);
    watch?.call(sim);
    if (sim.phase == RunPhase.ended) return;
  }
}

/// The same pilot through a [FlightRecorder], so the flight can be
/// replayed.
({ReplayTape tape, FlightSimulation simulation}) recordBuilt(
  BuiltPlan plan, {
  double cycle = BuiltPlan.referenceCycle,
  int weaponDamage = 30,
  double seconds = 600,
}) {
  var now = 0.0;
  final tape = ReplayTape(
    mode: plan.mode,
    practice: false,
    seed: 11,
    cycleSeconds: cycle,
    bird: 1,
    reducedMotion: false,
    originMs: 0,
    course: FlightCourse.starTrail,
    weaponDamage: weaponDamage,
    built: plan,
  );
  final recorder = FlightRecorder(tape, () => now);
  final sim = recorder.simulation;
  final pilot = BuiltPilot(plan.mode, cycle: cycle);
  for (var frame = 1; frame <= seconds * 50; frame++) {
    now += 20;
    recorder.apply(pilot.next(sim), builtSample(plan.mode, now), now);
    if (sim.offersShoot) {
      if (frame % 90 == 0) recorder.command('charge');
      if (frame % 90 == 30 || (frame % 9 == 0 && sim.canShoot)) {
        recorder.command('shoot');
      }
    }
    recorder.tick(.02, now, 2.2);
    if (sim.phase == RunPhase.ended) break;
  }
  if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
  return (tape: tape, simulation: sim);
}

/// A small level for [mode]: [gates] gates [spacing] apart (thousandths)
/// with a trio of stars before each on its aiming line, and a heart
/// halfway. Height modes alternate lanes; free modes weave.
BuiltPlan sampleLevel(
  PlayMode mode, {
  String id = 'u-sample0001',
  int gates = 8,
  int? spacing,
  int gap = 460,
  ObstacleKind kind = ObstacleKind.garden,
  int amp = 0,
  BuiltPace pace = BuiltPace.relaxed,
  List<BuiltItem> extra = const [],
  BossKind? boss,
  WorldRegion region = WorldRegion.jungle,
}) {
  final step =
      spacing ??
      switch (mode) {
        PlayMode.touch => 1000,
        PlayMode.jump => 1300,
        PlayMode.pushUp || PlayMode.squat => 1200,
      };
  final items = <BuiltItem>[];
  var x = BuiltPlan.firstX + 600;
  for (var i = 0; i < gates; i++) {
    final y = mode.controlsHeight
        ? (i.isEven ? BuiltPlan.highLane : BuiltPlan.lowLane)
        : const [450, 550, 400, 600][i % 4];
    final aim = (BuiltPlan.laneTarget(mode, y / BuiltPlan.unit) * 1000).round();
    items
      ..add(BuiltTrio(x: x - 250, y: aim))
      ..add(BuiltGate(x: x, y: y, gap: gap, kind: kind, amp: amp));
    if (i == gates ~/ 2) items.add(BuiltHeart(x: x + 400, y: aim));
    x += step;
  }
  items.addAll(extra);
  final stars = 3 * gates;
  return BuiltPlan(
    id: id,
    name: 'Sample ${mode.name}',
    mode: mode,
    region: region,
    pace: pace,
    finish: x,
    marks: BuiltPlan.suggestMarks(stars),
    items: items,
    boss: boss,
  );
}
