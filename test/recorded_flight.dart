import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

/// Flap toward the next gap or boss, on a lane that incoming shots miss.
/// On a rush path, fly the ring route: a ring sprint smashes the rubble.
/// Without one, weave around meteors and flocks and hop over lava plumes.
bool rideTheSky(FlightSimulation sim) {
  final ahead = sim.obstacles.where(
    (o) =>
        !o.scored &&
        !o.smashed &&
        !(o.rubble && sim.ramming) &&
        o.x + o.width > FlightSimulation.birdX - .05,
  );
  final ring = sim.sprintRings
      .where((r) => !r.collected && r.x > FlightSimulation.birdX - .03)
      .firstOrNull;
  final chaseRing =
      ring != null && (ahead.isEmpty || ring.x < ahead.first.x + .05);
  var preferred = .42;
  if (sim.boss != null) {
    preferred = sim.boss!.y;
  } else if (chaseRing) {
    // Flaps rise about .13 above the aim, so aim low to straddle the ring.
    preferred = ring.y + .05;
  } else if (ahead.isNotEmpty) {
    preferred = ahead.first.target;
  }

  final pace = sim.speed * sim.courseBoost;
  // Each danger is a height and how far to stay from it. Whatever arrives
  // after the next ring meets its sprint and is smashed instead.
  final meets = <(double, double)>[];
  final ringIn = chaseRing
      ? (ring.x - FlightSimulation.birdX) / pace
      : double.infinity;
  void consider(
    double x,
    double y,
    double vx,
    double vy, {
    double room = .24,
    bool smashable = false,
    double horizon = 1.25,
  }) {
    if (x < FlightSimulation.birdX - .02) return;
    final closing = -vx;
    if (closing < .05) return;
    final time = (x - FlightSimulation.birdX) / closing;
    if (time < 0 || time > horizon || (smashable && time > ringIn)) return;
    meets.add((y + vy * time, room));
  }

  for (final shot in sim.bossAmmo) {
    consider(shot.x, shot.y, shot.vx, shot.vy);
  }
  for (final shot in sim.enemyAmmo) {
    consider(shot.x, shot.y, shot.vx, shot.vy);
  }
  if (!sim.ramming) {
    for (final meteor in sim.meteors) {
      consider(
        meteor.x,
        meteor.y,
        meteor.vx - pace,
        meteor.vy,
        smashable: true,
      );
    }
    // Flocks thread the barrier openings, so dodge within the opening.
    for (final bat in sim.swarm) {
      consider(
        bat.x,
        bat.y,
        -pace - Rush.swarmSpeed,
        0,
        room: .13,
        smashable: true,
      );
    }
  }
  // Gale debris flies level, and a sprint gives no protection from it. Its
  // warning shows the lane before it is on screen, so look further ahead.
  for (final debris in sim.galeDebris) {
    if (debris.hitAt != null || debris.dodged) continue;
    consider(
      debris.x,
      debris.y,
      -pace - GaleDebris.speed,
      0,
      room: FlightSimulation.birdRadius + GaleDebris.radius + .06,
      horizon: 2,
    );
  }
  for (final enemy in sim.enemies) {
    if (sim.ramming || (chaseRing && ring.x < enemy.x)) continue;
    if (enemy.x >= FlightSimulation.birdX &&
        enemy.x <= FlightSimulation.birdX + .45) {
      meets.add((enemy.y, .24));
    }
  }
  // Hop over any plume standing when the bird reaches its vent, once
  // through the barrier before it.
  var ceiling = 1.0;
  for (final vent in sim.lavaVents) {
    final away = vent.x - FlightSimulation.birdX;
    if (away < -.09 || away > .8) continue;
    if (ahead.isNotEmpty && ahead.first.x < vent.x) continue;
    final at = vent.eruptedAt ?? vent.fuseEndsAt;
    final erupts = at == null
        ? (away - sim.speed * Rush.ventFuse) / pace + Rush.ventFuse
        : at - sim.elapsed;
    final enter = (away - .09) / pace, leave = (away + .09) / pace;
    if (leave < erupts || enter > erupts + Rush.plumeSeconds) continue;
    final clear = vent.top - FlightSimulation.birdRadius - .05;
    if (clear < ceiling) ceiling = clear;
  }

  double danger(double lane) {
    var cost = (lane - preferred).abs();
    for (final (y, room) in meets) {
      final gap = (lane - y).abs();
      if (gap < room) cost += (room - gap) * 8;
    }
    if (lane > ceiling) cost += 2 + (lane - ceiling) * 8;
    return cost;
  }

  var target = preferred;
  var best = danger(preferred);
  for (final lane in [
    .32,
    .42,
    .5,
    .58,
    .68,
    if (sim.rushPath != null) ...[preferred - .12, preferred + .12],
    if (sim.gale != null) ...[.24, .76],
    if (ceiling < 1) ceiling - .02,
  ]) {
    final cost = danger(lane);
    if (cost < best) {
      best = cost;
      target = lane;
    }
  }
  // A flap rises about .13 and only settles a little below the aim point.
  // Keep that whole arc inside the opening, and off an enemy in the lane.
  if (sim.boss == null &&
      !chaseRing &&
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
  // Only a plume's clearance can pull the aim higher.
  if (target > ceiling) target = ceiling - .02;
  final gale = sim.gale != null;
  target = target.clamp(
    ceiling < .32 ? ceiling - .02 : (gale ? .22 : .30),
    gale ? .78 : .72,
  );
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
