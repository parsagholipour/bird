import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'recorded_flight.dart';

/// A fresh flight of [level], as the play screen starts one.
FlightSimulation levelFlight(
  CampaignLevel level, {
  int weaponDamage = BirdRock.baseDamage,
  bool practice = false,
  int version = FlightSimulation.currentRulesVersion,
}) => FlightSimulation(
  rules: TapFlyMode(rulesVersion: version),
  practice: practice,
  course: FlightCourse.starTrail,
  rulesVersion: version,
  weaponDamage: weaponDamage,
  plan: level.plan,
);

/// A touch flight's tracking sample at [now].
TrackingSample touchAt(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// Flies [sim] with the shared sky-riding bot until it ends, [until] holds
/// or [seconds] pass, shooting when [shootWhen] allows (a charged shot
/// every 1.8 seconds, taps between) and sprinting when [sprintWhen] allows.
/// [keepAlive] tops the hearts up. [watch] sees the flight after every
/// frame.
void flyLevel(
  FlightSimulation sim, {
  double viewportWidth = 2.2,
  bool keepAlive = true,
  bool flap = true,
  bool Function(FlightSimulation sim)? shootWhen,
  bool Function(FlightSimulation sim, int frame)? sprintWhen,
  void Function(FlightSimulation sim)? watch,
  bool Function(FlightSimulation sim)? until,
  double seconds = 400,
}) {
  // Carries on from where an earlier call left the flight's clock.
  var now = sim.lastValidMs.isFinite ? sim.lastValidMs : 0.0;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    if (until?.call(sim) ?? false) return;
    now += 20;
    if (keepAlive && sim.hearts < 2) sim.hearts = 3;
    sim.apply(
      MovementInput(valid: true, height: .5, flap: flap && rideTheSky(sim)),
      touchAt(now),
      now,
    );
    if (sprintWhen?.call(sim, frame) ?? sim.canSprint) sim.sprint();
    if (shootWhen?.call(sim) ?? true) {
      switch (frame % 90) {
        case 0:
          sim.startCharge();
        case 30:
          sim.shoot();
        default:
          if (frame % 9 == 0 && !sim.charging && sim.canShoot) sim.shoot();
      }
    }
    sim.tick(.02, now, viewportWidth: viewportWidth);
    watch?.call(sim);
    if (sim.phase == RunPhase.ended) return;
  }
}

/// The same bot through a [FlightRecorder], so the flight can be replayed.
/// [tapWhen] replaces the bot's own choice of when to flap.
({ReplayTape tape, FlightSimulation simulation}) recordLevel(
  CampaignLevel level, {
  LevelPlan? plan,
  int weaponDamage = 30,
  double viewportWidth = 2.2,
  double seconds = 400,
  int version = FlightSimulation.currentRulesVersion,
  bool Function(FlightSimulation sim)? tapWhen,
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
    recordedVersion: version,
    weaponDamage: weaponDamage,
    plan: plan ?? level.plan,
  );
  final recorder = FlightRecorder(tape, () => now);
  final sim = recorder.simulation;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    now += 20;
    recorder.apply(
      MovementInput(
        valid: true,
        height: .5,
        flap: tapWhen?.call(sim) ?? rideTheSky(sim),
      ),
      touchAt(now),
      now,
    );
    if (sim.canSprint) recorder.command('sprint');
    if (frame % 90 == 0) recorder.command('charge');
    if (frame % 90 == 30 || (frame % 9 == 0 && sim.canShoot)) {
      recorder.command('shoot');
    }
    recorder.tick(.02, now, viewportWidth);
    if (sim.phase == RunPhase.ended) break;
  }
  if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
  return (tape: tape, simulation: sim);
}

/// What a laid obstacle is, apart from where its motion has reached: two
/// attempts lay the same route when these match in order.
String obstacleSignature(FlightSimulation sim, Obstacle o) =>
    '${o.kind.name} c=${o.baseCenter} g=${o.baseGap} '
    'a=${o.amplitude} ph=${o.phaseOffset} look=${o.appearance} '
    'door=${o.door != null} rubble=${o.rubble} '
    'world=${(sim.distance + o.x).toStringAsFixed(6)}';
