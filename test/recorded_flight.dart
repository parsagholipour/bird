import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

/// Flap toward the next gap or boss, on a lane that incoming shots miss.
bool rideTheSky(FlightSimulation sim) {
  final ahead = sim.obstacles.where(
    (o) => !o.scored && o.x + o.width > FlightSimulation.birdX - .05,
  );
  var preferred = .42;
  if (sim.boss != null) {
    preferred = sim.boss!.y;
  } else if (ahead.isNotEmpty) {
    preferred = ahead.first.target;
  }

  final meets = <double>[];
  void consider(double x, double y, double vx, double vy) {
    if (x < FlightSimulation.birdX - .02) return;
    final closing = -vx;
    if (closing < .05) return;
    final time = (x - FlightSimulation.birdX) / closing;
    if (time < 0 || time > 1.25) return;
    meets.add(y + vy * time);
  }

  for (final shot in sim.bossAmmo) {
    consider(shot.x, shot.y, shot.vx, shot.vy);
  }
  for (final shot in sim.enemyAmmo) {
    consider(shot.x, shot.y, shot.vx, shot.vy);
  }
  for (final enemy in sim.enemies) {
    if (enemy.x >= FlightSimulation.birdX &&
        enemy.x <= FlightSimulation.birdX + .45) {
      meets.add(enemy.y);
    }
  }

  double danger(double lane) {
    var cost = (lane - preferred).abs();
    for (final y in meets) {
      final gap = (lane - y).abs();
      if (gap < .24) cost += (.24 - gap) * 8;
    }
    return cost;
  }

  var target = preferred;
  var best = danger(preferred);
  for (final lane in const [.32, .42, .5, .58, .68]) {
    final cost = danger(lane);
    if (cost < best) {
      best = cost;
      target = lane;
    }
  }
  // A flap rises about .13 and only settles a little below the aim point.
  // Keep that whole arc inside the opening, and off an enemy in the lane.
  if (sim.boss == null &&
      ahead.isNotEmpty &&
      ahead.first.x < FlightSimulation.birdX + .9) {
    final gate = ahead.first;
    const rise = .14;
    var aim = gate.target + rise * .5;
    for (final enemy in sim.enemies) {
      if (enemy.x < gate.x - .15 || enemy.x > gate.x + gate.width + .05) {
        continue;
      }
      final above = gate.target - gate.top;
      final below = gate.bottom - gate.target;
      aim += below > above ? .06 : -.06;
      break;
    }
    final low = gate.top + FlightSimulation.birdRadius + rise;
    final high = gate.bottom - FlightSimulation.birdRadius - .04;
    target = high > low ? aim.clamp(low, high) : gate.target;
  }
  // Leave room for the flap arc so a dodge cannot strike the screen edge.
  target = target.clamp(.30, .72);
  return sim.birdY > target && sim.velocity > 0;
}

/// A followed practice flight long enough for replay and pose checks.
ReplayTape recordFlight(
  PlayMode mode, {
  double cycle = 3,
  int version = FlightSimulation.currentRulesVersion,
  FlightCourse course = FlightCourse.starTrail,
}) {
  double now = 0, height = 1;
  final tape = ReplayTape(
    mode: mode,
    practice: true,
    seed: 18,
    cycleSeconds: cycle,
    bird: 2,
    reducedMotion: true,
    originMs: 0,
    course: course,
    recordedVersion: version,
  );
  final recorder = FlightRecorder(tape, () => now);
  for (var i = 0; i < 6000; i++) {
    now += 20;
    final sim = recorder.simulation;
    final ahead = sim.obstacles.where((o) => !o.scored);
    final target = ahead.isEmpty ? .15 : ahead.first.target;
    // Center the larger jump arc around the target instead of boosting at its
    // center and spending the whole arc above the collectibles.
    final flapAt = (target + (mode == PlayMode.jump && version >= 8 ? .13 : 0))
        .clamp(.15, .88);
    height += ((.85 - target) / .7 - height).clamp(
      -.02 * 2 / cycle,
      .02 * 2 / cycle,
    );
    recorder.apply(
      MovementInput(
        valid: true,
        height: height,
        flap: mode == PlayMode.touch
            ? rideTheSky(sim)
            : !mode.controlsHeight && sim.birdY > flapAt && sim.velocity >= 0,
      ),
      TrackingSample(
        mode: mode,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    recorder.tick(.02, now, 2.2);
  }
  recorder.command('end', EndReason.quit);
  return tape;
}
