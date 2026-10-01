import 'package:push_up_bird/domain/game_rules.dart';

import 'recorded_flight.dart' show rideTheSky;

/// A player who knows about steam, for the New York rules tests (the shared
/// bot [rideTheSky] is untouched and ignores vents).
///
/// They fly the gates the way [rideTheSky] does, tapping at most [taps] times
/// a second. When a hop vent's hiss has been on for [react] seconds they
/// climb to [clearance] above the plume's standing top and stay there until
/// the vent is behind them; falling back to the next gate is free.
bool steamTapper(
  FlightSimulation sim, {
  double react = .6,
  double taps = 3,
  double clearance = .10,
}) {
  final limited = sim.elapsed - sim.lastFlapAt >= 1 / taps;
  for (final vent in sim.steamVents) {
    if (vent.kind != SteamKind.hop) continue;
    final away = vent.x - FlightSimulation.birdX;
    if (away < -.12 || away > 1.3) continue;
    final since = sim.routeSeconds - vent.geyser.hissAt;
    if (since < react) break;
    // Rising toward the target: tap whenever the last flap's lift has mostly
    // gone; holding it: tap as the bird sinks past it.
    return limited && sim.birdY > vent.top - clearance && sim.velocity > -.25;
  }
  return limited && rideTheSky(sim);
}
